import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outputDir = path.join(root, "godot", "assets", "audio");
const legacyDir = path.join(root, "src", "assets", "audio", "generated");
const sampleRate = 32000;
const loopSeconds = 16;
const checkOnly = process.argv.includes("--check");

const TAU = Math.PI * 2;
const clamp = (value, min = -1, max = 1) => Math.max(min, Math.min(max, value));
const midi = (note) => 440 * (2 ** ((note - 69) / 12));
const smooth = (value) => {
  const x = clamp(value, 0, 1);
  return x * x * (3 - 2 * x);
};

function createBuffer(seconds) {
  return {
    seconds,
    frames: Math.floor(sampleRate * seconds),
    samples: new Float32Array(Math.floor(sampleRate * seconds) * 2),
  };
}

function mixSample(buffer, frame, value, pan = 0) {
  if (frame < 0 || frame >= buffer.frames) return;
  const angle = (clamp(pan, -1, 1) + 1) * Math.PI * 0.25;
  buffer.samples[frame * 2] += value * Math.cos(angle);
  buffer.samples[frame * 2 + 1] += value * Math.sin(angle);
}

function noteEnvelope(time, duration, attack, release) {
  if (time < 0 || time >= duration) return 0;
  return smooth(time / attack) * smooth((duration - time) / release);
}

function voiceSample(kind, frequency, time) {
  const phase = TAU * frequency * time;
  if (kind === "pad") {
    return Math.sin(phase) * 0.72
      + Math.sin(phase * 2 + 0.18) * 0.18
      + Math.sin(phase * 0.5 + 0.7) * 0.1;
  }
  if (kind === "pluck") {
    const triangle = 2 * Math.abs(2 * ((frequency * time) % 1) - 1) - 1;
    return triangle * 0.62 + Math.sin(phase * 2) * 0.25 + Math.sin(phase * 3) * 0.08;
  }
  if (kind === "bell") {
    return Math.sin(phase) * 0.66
      + Math.sin(phase * 2.01) * 0.2
      + Math.sin(phase * 3.98) * 0.1;
  }
  return Math.sin(phase);
}

function addNote(buffer, { start, duration, note, frequency, amplitude, pan = 0, voice = "pad", attack, release }) {
  const freq = frequency ?? midi(note);
  const first = Math.max(0, Math.floor(start * sampleRate));
  const last = Math.min(buffer.frames, Math.ceil((start + duration) * sampleRate));
  const noteAttack = attack ?? (voice === "pad" ? 0.55 : 0.012);
  const noteRelease = release ?? (voice === "pad" ? 0.75 : Math.min(0.28, duration * 0.55));
  for (let frame = first; frame < last; frame += 1) {
    const localTime = frame / sampleRate - start;
    const envelope = noteEnvelope(localTime, duration, noteAttack, noteRelease);
    const decay = voice === "bell" ? Math.exp(-localTime * 2.1) : voice === "pluck" ? Math.exp(-localTime * 3.4) : 1;
    mixSample(buffer, frame, voiceSample(voice, freq, localTime) * envelope * decay * amplitude, pan);
  }
}

function addSweep(buffer, { start, duration, from, to, amplitude, pan = 0 }) {
  const first = Math.max(0, Math.floor(start * sampleRate));
  const last = Math.min(buffer.frames, Math.ceil((start + duration) * sampleRate));
  let phase = 0;
  for (let frame = first; frame < last; frame += 1) {
    const localTime = frame / sampleRate - start;
    const progress = localTime / duration;
    const frequency = from + (to - from) * smooth(progress);
    phase += TAU * frequency / sampleRate;
    const envelope = noteEnvelope(localTime, duration, 0.025, Math.min(0.35, duration * 0.4));
    mixSample(buffer, frame, Math.sin(phase) * envelope * amplitude, pan);
  }
}

function periodicAir(time, seconds, seed = 0) {
  let value = 0;
  for (let index = 0; index < 7; index += 1) {
    const cycles = 2 + index * 3 + seed;
    const phase = (index * 1.73 + seed * 0.91) % TAU;
    value += Math.sin(TAU * cycles * time / seconds + phase) / (index + 2);
  }
  return value * 0.22;
}

function addPeriodicAmbience(buffer, amplitude, seed, panDrift = 0.35) {
  for (let frame = 0; frame < buffer.frames; frame += 1) {
    const time = frame / sampleRate;
    const air = periodicAir(time, buffer.seconds, seed);
    const shimmer = periodicAir(time, buffer.seconds, seed + 5) * 0.35;
    const pan = Math.sin(TAU * time / buffer.seconds * 2 + seed) * panDrift;
    mixSample(buffer, frame, (air + shimmer) * amplitude, pan);
  }
}

function finish(buffer, targetPeak) {
  let leftMean = 0;
  let rightMean = 0;
  for (let frame = 0; frame < buffer.frames; frame += 1) {
    leftMean += buffer.samples[frame * 2];
    rightMean += buffer.samples[frame * 2 + 1];
  }
  leftMean /= buffer.frames;
  rightMean /= buffer.frames;
  let peak = 0;
  for (let frame = 0; frame < buffer.frames; frame += 1) {
    buffer.samples[frame * 2] -= leftMean;
    buffer.samples[frame * 2 + 1] -= rightMean;
    peak = Math.max(peak, Math.abs(buffer.samples[frame * 2]), Math.abs(buffer.samples[frame * 2 + 1]));
  }
  const gain = peak > 0 ? targetPeak / peak : 1;
  for (let index = 0; index < buffer.samples.length; index += 1) {
    buffer.samples[index] = Math.tanh(buffer.samples[index] * gain * 1.08) / Math.tanh(1.08);
  }
  return buffer;
}

function writeWav(filename, buffer) {
  const channels = 2;
  const bytesPerSample = 2;
  const dataSize = buffer.frames * channels * bytesPerSample;
  const wav = Buffer.alloc(44 + dataSize);
  wav.write("RIFF", 0);
  wav.writeUInt32LE(36 + dataSize, 4);
  wav.write("WAVE", 8);
  wav.write("fmt ", 12);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(channels, 22);
  wav.writeUInt32LE(sampleRate, 24);
  wav.writeUInt32LE(sampleRate * channels * bytesPerSample, 28);
  wav.writeUInt16LE(channels * bytesPerSample, 32);
  wav.writeUInt16LE(16, 34);
  wav.write("data", 36);
  wav.writeUInt32LE(dataSize, 40);
  for (let index = 0; index < buffer.samples.length; index += 1) {
    wav.writeInt16LE(Math.round(clamp(buffer.samples[index]) * 32767), 44 + index * 2);
  }
  fs.writeFileSync(path.join(outputDir, filename), wav);
}

function buildDayMusic() {
  const buffer = createBuffer(loopSeconds);
  const chords = [
    [48, 60, 64, 67, 71],
    [45, 57, 60, 64, 67],
    [41, 53, 57, 60, 64],
    [43, 55, 60, 62, 67],
  ];
  const patterns = [[60, 64, 67, 71, 67, 64, 67, 64], [57, 60, 64, 67, 64, 60, 64, 60], [53, 57, 60, 64, 60, 57, 60, 57], [55, 60, 62, 67, 62, 60, 62, 60]];
  chords.forEach((chord, chordIndex) => {
    const start = chordIndex * 4;
    chord.forEach((note, index) => addNote(buffer, {
      start,
      duration: 3.98,
      note,
      amplitude: index === 0 ? 0.045 : 0.026,
      pan: (index - 2) * 0.19,
      voice: "pad",
      attack: 0.7,
      release: 0.85,
    }));
    patterns[chordIndex].forEach((note, step) => addNote(buffer, {
      start: start + step * 0.5,
      duration: 0.47,
      note: note + 12,
      amplitude: 0.07,
      pan: step % 2 === 0 ? -0.28 : 0.28,
      voice: "pluck",
    }));
  });
  [3.18, 7.18, 11.18, 15.05].forEach((start, index) => addNote(buffer, {
    start,
    duration: 0.72,
    note: [79, 76, 81, 79][index],
    amplitude: 0.055,
    pan: index % 2 === 0 ? 0.5 : -0.5,
    voice: "bell",
  }));
  return finish(buffer, 0.72);
}

function buildNightMusic() {
  const buffer = createBuffer(loopSeconds);
  const chords = [[48, 55, 59, 64], [52, 55, 59, 64], [45, 52, 57, 60], [43, 50, 55, 59]];
  chords.forEach((chord, chordIndex) => {
    const start = chordIndex * 4;
    chord.forEach((note, index) => addNote(buffer, {
      start,
      duration: 3.98,
      note,
      amplitude: index === 0 ? 0.036 : 0.022,
      pan: (index - 1.5) * 0.24,
      voice: "pad",
      attack: 1.05,
      release: 1.1,
    }));
    [0.65, 2.55].forEach((offset, noteIndex) => addNote(buffer, {
      start: start + offset,
      duration: 1.05,
      note: chord[1 + noteIndex] + 24,
      amplitude: 0.052,
      pan: noteIndex === 0 ? -0.48 : 0.48,
      voice: "bell",
      release: 0.8,
    }));
  });
  return finish(buffer, 0.64);
}

function buildFocusLayer() {
  const buffer = createBuffer(loopSeconds);
  const notes = [72, 76, 79, 83, 69, 72, 76, 79, 65, 69, 72, 76, 67, 72, 74, 79];
  for (let bar = 0; bar < 4; bar += 1) {
    for (let step = 0; step < 16; step += 1) {
      addNote(buffer, {
        start: bar * 4 + step * 0.25,
        duration: 0.22,
        note: notes[bar * 4 + (step % 4)],
        amplitude: step % 4 === 0 ? 0.07 : 0.043,
        pan: Math.sin(step * 1.7) * 0.58,
        voice: "pluck",
        release: 0.13,
      });
    }
  }
  return finish(buffer, 0.56);
}

function buildDayAmbience() {
  const buffer = createBuffer(loopSeconds);
  addPeriodicAmbience(buffer, 0.11, 2, 0.45);
  [2.1, 5.85, 9.35, 13.25].forEach((start, index) => {
    addSweep(buffer, { start, duration: 0.34, from: 1450 + index * 80, to: 2380 + index * 120, amplitude: 0.038, pan: index % 2 ? 0.62 : -0.62 });
    addSweep(buffer, { start: start + 0.16, duration: 0.28, from: 1780, to: 1280, amplitude: 0.026, pan: index % 2 ? 0.56 : -0.56 });
  });
  [4.2, 11.8].forEach((start, index) => addNote(buffer, { start, duration: 1.2, note: 88 - index * 5, amplitude: 0.025, pan: index ? -0.7 : 0.7, voice: "bell", release: 0.95 }));
  return finish(buffer, 0.48);
}

function buildNightAmbience() {
  const buffer = createBuffer(loopSeconds);
  addPeriodicAmbience(buffer, 0.13, 7, 0.5);
  for (let group = 0; group < 7; group += 1) {
    const start = 1.0 + group * 2.05;
    for (let pulse = 0; pulse < 4; pulse += 1) {
      addNote(buffer, {
        start: start + pulse * 0.095,
        duration: 0.055,
        frequency: 2850 + (group % 3) * 170,
        amplitude: 0.022,
        pan: group % 2 ? 0.72 : -0.72,
        voice: "sine",
        attack: 0.006,
        release: 0.038,
      });
    }
  }
  [5.15, 12.6].forEach((start, index) => addSweep(buffer, { start, duration: 0.9, from: 420, to: 285, amplitude: 0.022, pan: index ? 0.45 : -0.45 }));
  return finish(buffer, 0.44);
}

function buildCue(kind) {
  const buffer = createBuffer(kind === "complete" ? 2.2 : kind === "setback" ? 1.25 : 0.9);
  if (kind === "geography") {
    addSweep(buffer, { start: 0.02, duration: 0.52, from: 310, to: 620, amplitude: 0.09, pan: -0.35 });
    [67, 74, 79].forEach((note, index) => addNote(buffer, { start: 0.12 + index * 0.16, duration: 0.48, note, amplitude: 0.13, pan: -0.35 + index * 0.35, voice: "bell" }));
  } else if (kind === "science") {
    [84, 88, 91].forEach((note, index) => addNote(buffer, { start: 0.05 + index * 0.2, duration: 0.36, note, amplitude: 0.13, pan: [-0.45, 0.38, 0][index], voice: "bell" }));
    addSweep(buffer, { start: 0.28, duration: 0.52, from: 460, to: 760, amplitude: 0.065, pan: 0.1 });
  } else if (kind === "civics") {
    [62, 67, 71].forEach((note, index) => addNote(buffer, { start: 0.04 + index * 0.13, duration: 0.55, note, amplitude: 0.12, pan: [-0.72, 0.72, 0][index], voice: "pluck" }));
    addNote(buffer, { start: 0.44, duration: 0.44, note: 74, amplitude: 0.13, pan: 0, voice: "bell" });
  } else if (kind === "logic") {
    [72, 76, 74, 79].forEach((note, index) => addNote(buffer, { start: 0.03 + index * 0.12, duration: 0.2, note, amplitude: 0.13, pan: index % 2 ? 0.35 : -0.35, voice: "pluck", release: 0.1 }));
    addNote(buffer, { start: 0.5, duration: 0.38, note: 84, amplitude: 0.12, pan: 0, voice: "bell" });
  } else if (kind === "nora") {
    [76, 81, 79].forEach((note, index) => addNote(buffer, { start: 0.04 + index * 0.16, duration: 0.42, note, amplitude: 0.11, pan: [-0.2, 0.2, 0][index], voice: "bell" }));
  } else if (kind === "complete") {
    [60, 64, 67, 72].forEach((note, index) => addNote(buffer, { start: index * 0.18, duration: 1.3, note, amplitude: 0.11, pan: (index - 1.5) * 0.28, voice: index < 2 ? "pluck" : "bell", release: 0.8 }));
    [72, 76, 79].forEach((note, index) => addNote(buffer, { start: 0.8, duration: 1.35, note, amplitude: 0.09, pan: (index - 1) * 0.36, voice: "pad", attack: 0.16, release: 0.8 }));
  } else if (kind === "setback") {
    [55, 52, 48].forEach((note, index) => addNote(buffer, { start: index * 0.19, duration: 0.65, note, amplitude: 0.1, pan: 0, voice: "pad", attack: 0.025, release: 0.42 }));
  }
  return finish(buffer, kind === "complete" ? 0.78 : 0.65);
}

const legacyAssets = {
  "ui-select.wav": "uiSelect.wav",
  "ui-confirm.wav": "confirm.wav",
  "ui-cancel.wav": "cancel.wav",
  "panel-open.wav": "panelOpen.wav",
  "shop-open.wav": "shopOpen.wav",
  "shop-purchase.wav": "shopPurchase.wav",
  "shop-equip.wav": "shopEquip.wav",
  "shop-locked.wav": "shopLocked.wav",
  "pet-equip.wav": "petEquip.wav",
  "mission-start.wav": "missionStart.wav",
  "enigma-step.wav": "progressiveStep.wav",
  "answer-correct.wav": "success.wav",
  "answer-wrong.wav": "error.wav",
  "hint.wav": "hint.wav",
  "scan.wav": "scan.wav",
  "portal-open.wav": "doorOpen.wav",
  "footstep.wav": "footstep.wav",
  "circuit-on.wav": "circuitOn.wav",
  "context-math.wav": "contextMath.wav",
  "context-language.wav": "contextLanguage.wav",
  "context-english.wav": "contextEnglish.wav",
  "context-electronics.wav": "contextElectronics.wav",
  "context-coding.wav": "contextCoding.wav",
  "context-music.wav": "contextMusic.wav",
};

const generatedAssets = {
  "music-day.wav": () => buildDayMusic(),
  "music-night.wav": () => buildNightMusic(),
  "music-focus.wav": () => buildFocusLayer(),
  "ambience-day.wav": () => buildDayAmbience(),
  "ambience-night.wav": () => buildNightAmbience(),
  "context-geography.wav": () => buildCue("geography"),
  "context-science.wav": () => buildCue("science"),
  "context-civics.wav": () => buildCue("civics"),
  "context-logic.wav": () => buildCue("logic"),
  "nora-cue.wav": () => buildCue("nora"),
  "completion-stinger.wav": () => buildCue("complete"),
  "setback-stinger.wav": () => buildCue("setback"),
};

function asset(pathname, bus, volumeDb, extra = {}) {
  return { path: `res://assets/audio/${pathname}`, bus, volumeDb, ...extra };
}

const manifest = {
  version: 1,
  generatedBy: "scripts/build-godot-audio-assets.mjs",
  buses: [
    { name: "Music", parent: "Master", defaultVolumeDb: -6 },
    { name: "Ambience", parent: "Master", defaultVolumeDb: -8 },
    { name: "SFX", parent: "Master", defaultVolumeDb: -3 },
    { name: "UI", parent: "SFX", defaultVolumeDb: -2 },
  ],
  adaptive: {
    day: ["music.day", "ambience.day"],
    night: ["music.night", "ambience.night"],
    focusLayer: "music.focus",
    crossfadeSeconds: 2.2,
  },
  subjects: {
    matematica: "context.math",
    italiano: "context.language",
    inglese: "context.english",
    latino: "context.language",
    coding: "context.coding",
    elettronica: "context.electronics",
    fisica: "context.electronics",
    musica: "context.music",
    geografia: "context.geography",
    scienze: "context.science",
    cittadinanza: "context.civics",
    logica: "context.logic",
  },
  events: {
    sessionStarted: "mission.start",
    enigmaProgress: "enigma.step",
    answerCorrect: "answer.correct",
    answerWrong: "answer.wrong",
    hintShown: "hint",
    enigmaCompleted: "outcome.complete",
    sessionDefeated: "outcome.setback",
    noraSpoke: "nora.cue",
    portalOpened: "portal.open",
  },
  assets: {
    "music.day": asset("music-day.wav", "Music", -12, { loop: true, role: "base" }),
    "music.night": asset("music-night.wav", "Music", -13, { loop: true, role: "base" }),
    "music.focus": asset("music-focus.wav", "Music", -17, { loop: true, role: "layer" }),
    "ambience.day": asset("ambience-day.wav", "Ambience", -11, { loop: true }),
    "ambience.night": asset("ambience-night.wav", "Ambience", -12, { loop: true }),
    "ui.select": asset("ui-select.wav", "UI", -8, { polyphony: 3 }),
    "ui.confirm": asset("ui-confirm.wav", "UI", -7),
    "ui.cancel": asset("ui-cancel.wav", "UI", -9),
    "panel.open": asset("panel-open.wav", "UI", -9),
    "shop.open": asset("shop-open.wav", "UI", -8),
    "shop.purchase": asset("shop-purchase.wav", "UI", -6),
    "shop.equip": asset("shop-equip.wav", "UI", -7),
    "shop.locked": asset("shop-locked.wav", "UI", -9),
    "pet.equip": asset("pet-equip.wav", "SFX", -8),
    "mission.start": asset("mission-start.wav", "SFX", -7),
    "enigma.step": asset("enigma-step.wav", "SFX", -8, { pitchByStage: [0.92, 1.0, 1.08, 1.18] }),
    "answer.correct": asset("answer-correct.wav", "SFX", -7, { cooldownMs: 90 }),
    "answer.wrong": asset("answer-wrong.wav", "SFX", -9, { cooldownMs: 90 }),
    hint: asset("hint.wav", "SFX", -8),
    scan: asset("scan.wav", "SFX", -10),
    "portal.open": asset("portal-open.wav", "SFX", -6),
    footstep: asset("footstep.wav", "SFX", -15, { polyphony: 2 }),
    "circuit.on": asset("circuit-on.wav", "SFX", -7),
    "nora.cue": asset("nora-cue.wav", "SFX", -10),
    "outcome.complete": asset("completion-stinger.wav", "SFX", -4),
    "outcome.setback": asset("setback-stinger.wav", "SFX", -7),
    "context.math": asset("context-math.wav", "SFX", -9),
    "context.language": asset("context-language.wav", "SFX", -9),
    "context.english": asset("context-english.wav", "SFX", -9),
    "context.electronics": asset("context-electronics.wav", "SFX", -8),
    "context.coding": asset("context-coding.wav", "SFX", -9),
    "context.music": asset("context-music.wav", "SFX", -8),
    "context.geography": asset("context-geography.wav", "SFX", -8),
    "context.science": asset("context-science.wav", "SFX", -8),
    "context.civics": asset("context-civics.wav", "SFX", -8),
    "context.logic": asset("context-logic.wav", "SFX", -8),
  },
};

function readWav(filePath) {
  const wav = fs.readFileSync(filePath);
  if (wav.toString("ascii", 0, 4) !== "RIFF" || wav.toString("ascii", 8, 12) !== "WAVE") {
    throw new Error(`${filePath}: intestazione WAV non valida`);
  }
  const channels = wav.readUInt16LE(22);
  const rate = wav.readUInt32LE(24);
  const bits = wav.readUInt16LE(34);
  const dataSize = wav.readUInt32LE(40);
  const sampleCount = dataSize / (bits / 8);
  let sum = 0;
  let peak = 0;
  for (let offset = 44; offset < 44 + dataSize; offset += 2) {
    const value = wav.readInt16LE(offset) / 32768;
    sum += value * value;
    peak = Math.max(peak, Math.abs(value));
  }
  return {
    channels,
    rate,
    bits,
    seconds: sampleCount / channels / rate,
    rms: Math.sqrt(sum / sampleCount),
    peak,
    firstLeft: wav.readInt16LE(44) / 32768,
    lastLeft: wav.readInt16LE(44 + dataSize - channels * 2) / 32768,
  };
}

function audit() {
  const issues = [];
  const loopPaths = new Set(Object.values(manifest.assets).filter((spec) => spec.loop).map((spec) => spec.path));
  for (const [key, spec] of Object.entries(manifest.assets)) {
    const filePath = path.join(root, "godot", spec.path.replace("res://", ""));
    if (!fs.existsSync(filePath)) {
      issues.push(`${key}: file assente ${spec.path}`);
      continue;
    }
    const info = readWav(filePath);
    if (info.bits !== 16 || ![22050, 32000, 44100].includes(info.rate)) issues.push(`${key}: formato inatteso`);
    if (info.rms < 0.002 || info.peak < 0.015) issues.push(`${key}: segnale troppo debole`);
    if (info.peak > 0.985) issues.push(`${key}: rischio clipping`);
    if (loopPaths.has(spec.path)) {
      if (Math.abs(info.seconds - loopSeconds) > 0.001) issues.push(`${key}: loop non lungo ${loopSeconds}s`);
      if (Math.abs(info.firstLeft - info.lastLeft) > 0.035) issues.push(`${key}: discontinuità al loop`);
    }
  }
  for (const [subject, key] of Object.entries(manifest.subjects)) {
    if (!manifest.assets[key]) issues.push(`${subject}: cue materia sconosciuto ${key}`);
  }
  for (const [event, key] of Object.entries(manifest.events)) {
    if (!manifest.assets[key]) issues.push(`${event}: cue evento sconosciuto ${key}`);
  }
  if (issues.length > 0) throw new Error(`Audio audit fallito:\n- ${issues.join("\n- ")}`);
  console.log(`GODOT AUDIO audit OK - ${Object.keys(manifest.assets).length} asset, 12 materie, 5 loop adattivi`);
}

if (!checkOnly) {
  fs.mkdirSync(outputDir, { recursive: true });
  for (const [filename, source] of Object.entries(legacyAssets)) {
    fs.copyFileSync(path.join(legacyDir, source), path.join(outputDir, filename));
  }
  for (const [filename, build] of Object.entries(generatedAssets)) writeWav(filename, build());
  fs.writeFileSync(path.join(outputDir, "audio-manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(`Generated ${Object.keys(generatedAssets).length} new and copied ${Object.keys(legacyAssets).length} proven audio assets.`);
}

audit();
