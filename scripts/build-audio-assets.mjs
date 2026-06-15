import fs from "node:fs";
import path from "node:path";

const outDir = path.join("src", "assets", "audio", "generated");
fs.mkdirSync(outDir, { recursive: true });

const sampleRate = 22050;

function writeWav(name, seconds, generator) {
  const sampleCount = Math.floor(sampleRate * seconds);
  const dataSize = sampleCount * 2;
  const buffer = Buffer.alloc(44 + dataSize);
  buffer.write("RIFF", 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write("WAVE", 8);
  buffer.write("fmt ", 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write("data", 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < sampleCount; i += 1) {
    const t = i / sampleRate;
    const value = Math.max(-1, Math.min(1, generator(t, i, sampleCount)));
    buffer.writeInt16LE(Math.round(value * 32767), 44 + i * 2);
  }
  fs.writeFileSync(path.join(outDir, name), buffer);
}

function envelope(t, seconds, attack = 0.01, release = 0.08) {
  const a = Math.min(1, t / attack);
  const r = Math.min(1, (seconds - t) / release);
  return Math.max(0, Math.min(a, r));
}

function tone(freq, t) {
  return Math.sin(Math.PI * 2 * freq * t);
}

writeWav("menuMusic.wav", 4.0, (t) => {
  const pad = tone(220, t) * 0.024 + tone(330, t + 0.17) * 0.014 + tone(440, t * 0.5) * 0.01;
  const pulse = Math.sin(Math.PI * 2 * 0.25 * t) * 0.006;
  return (pad + pulse) * envelope(t, 4.0, 0.4, 0.5);
});

writeWav("labAmbience.wav", 4.4, (t, i) => {
  const air = (Math.sin(i * 0.017) + Math.sin(i * 0.071)) * 0.0025;
  const distantPulse = Math.max(0, Math.sin(Math.PI * 2 * 0.18 * t)) * tone(392, t) * 0.01;
  const softChime = t > 2.7 && t < 3.15 ? tone(587, t) * 0.012 * envelope(t - 2.7, 0.45, 0.03, 0.22) : 0;
  return (air + distantPulse + softChime) * envelope(t, 4.4, 0.6, 0.8);
});

const sfx = [
  ["click.wav", 0.07, (t) => tone(820 - t * 1400, t) * 0.11 * envelope(t, 0.07, 0.002, 0.035)],
  ["scan.wav", 0.16, (t) => tone(520 + t * 520, t) * 0.08 * envelope(t, 0.16, 0.012, 0.08)],
  ["hint.wav", 0.24, (t) => (tone(392, t) + tone(588, t + 0.03)) * 0.055 * envelope(t, 0.24, 0.02, 0.12)],
  ["panelOpen.wav", 0.28, (t, i) => (tone(260 - t * 80, t) * 0.075 + Math.sin(i * 0.5) * 0.012) * envelope(t, 0.28, 0.008, 0.16)],
  ["footstep.wav", 0.1, (t, i) => (tone(130, t) * 0.045 + Math.sin(i * 1.4) * 0.012) * envelope(t, 0.1, 0.003, 0.05)],
  ["circuitOn.wav", 0.32, (t) => (tone(520 + t * 420, t) + tone(1040, t) * 0.25) * 0.08 * envelope(t, 0.32, 0.015, 0.14)],
  ["error.wav", 0.22, (t) => (tone(210 - t * 90, t) + tone(150, t) * 0.35) * 0.075 * envelope(t, 0.22, 0.005, 0.12)],
  ["success.wav", 0.36, (t) => (tone(523, t) + tone(t > 0.12 ? 784 : 659, t) * 0.55) * 0.075 * envelope(t, 0.36, 0.012, 0.16)],
  ["doorOpen.wav", 0.62, (t, i) => (tone(126 - t * 22, t) * 0.06 + Math.sin(i * 0.37) * 0.012) * envelope(t, 0.62, 0.03, 0.24)],
];

sfx.forEach(([name, seconds, generator]) => writeWav(name, seconds, generator));

console.log(`Generated ${2 + sfx.length} audio assets in ${outDir}`);
