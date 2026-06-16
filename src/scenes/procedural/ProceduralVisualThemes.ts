import Phaser from "phaser";
import { proceduralRunRules } from "../../core/ProceduralRunRules";
import { Random } from "../../procedural/Random";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization } from "../../procedural/ProceduralTypes";
import type { ChromePalette, ChromeRect } from "../../ui/SceneChrome";
import { VisualKit } from "../../ui/VisualKit";

export type ProceduralPropTheme = "lab" | "greenhouse" | "factory" | "archive" | "academy" | "circuit";
type LevelMotif = "trace" | "circuit" | "bio" | "archive" | "factory" | "map" | "reactor" | "core";

export type ProceduralVisualTheme = {
  id:
    | "trace-room"
    | "circuit-workshop"
    | "glass-greenhouse"
    | "interference-archive"
    | "number-factory"
    | "cartography-room"
    | "logic-reactor"
    | "academy-core";
  level: DifficultyLevel;
  levelName: string;
  palette: ChromePalette;
  propTheme: ProceduralPropTheme;
  stageTitle: string;
  subtitleTag: string;
  sideNote: string;
  ruleTitle: string;
  ruleText: string;
  stageHint: string;
  accent: number;
  secondary: number;
  dark: number;
  focus: ProceduralSpecialization;
  motif: LevelMotif;
  density: number;
  depth: number;
  motion: number;
  atmosphereLabel: string;
};

const levelThemes: Record<DifficultyLevel, Omit<ProceduralVisualTheme, "level" | "focus">> = {
  1: {
    id: "trace-room",
    levelName: "Sala delle Tracce",
    palette: "lab",
    propTheme: "lab",
    stageTitle: "sala riconfigurabile",
    subtitleTag: "tracce luminose, dispositivi leggibili, pochi disturbi",
    sideNote: "Le linee sul pavimento mostrano relazioni semplici: osserva un sistema, capisci il sintomo, poi intervieni.",
    ruleTitle: "Regola della sala",
    ruleText: "Ogni console lascia un indizio visibile. Se segui le tracce, la stanza racconta l'ordine logico del problema.",
    stageHint: "Segui le connessioni luminose: non sono decorazione, sono una mappa del ragionamento.",
    accent: 0x6be7d6,
    secondary: 0xf6c85f,
    dark: 0x071018,
    motif: "trace",
    density: 1,
    depth: 1,
    motion: 1,
    atmosphereLabel: "Ingresso chiaro: poche tracce, dispositivi distanti, lettura guidata.",
  },
  2: {
    id: "circuit-workshop",
    levelName: "Officina dei Circuiti",
    palette: "circuit",
    propTheme: "circuit",
    stageTitle: "officina dei circuiti",
    subtitleTag: "pannelli aperti, tester, guasti controllati",
    sideNote: "La stanza espone cavi e pannelli: prima diagnostichi il difetto, poi scegli solo l'intervento necessario.",
    ruleTitle: "Diagnosi prima della riparazione",
    ruleText: "Un intervento inutile non aiuta: cerca il punto in cui energia, dato o comando smette di proseguire.",
    stageHint: "Cavi, tester e luci di stato indicano dove il segnale si interrompe.",
    accent: 0x6be7d6,
    secondary: 0xffb36b,
    dark: 0x061019,
    motif: "circuit",
    density: 2,
    depth: 2,
    motion: 2,
    atmosphereLabel: "Banco tecnico: piste, tester e componenti in vista.",
  },
  3: {
    id: "glass-greenhouse",
    levelName: "Serra di Vetro",
    palette: "greenhouse",
    propTheme: "greenhouse",
    stageTitle: "serra automatizzata",
    subtitleTag: "sensori, capsule vegetali, vapore leggero",
    sideNote: "Qui ogni scelta cambia un equilibrio: acqua, luce, temperatura e dati vanno letti insieme.",
    ruleTitle: "Sistema vivente",
    ruleText: "Non basta correggere un valore: controlla che l'intero sistema resti stabile dopo la tua decisione.",
    stageHint: "Le capsule verdi evidenziano dati e conseguenze: confronta prima di agire.",
    accent: 0x70d68a,
    secondary: 0xf7d37a,
    dark: 0x06130f,
    motif: "bio",
    density: 3,
    depth: 3,
    motion: 2,
    atmosphereLabel: "Ambiente vivo: dati e conseguenze cambiano insieme.",
  },
  4: {
    id: "interference-archive",
    levelName: "Archivio Interferente",
    palette: "archive",
    propTheme: "archive",
    stageTitle: "archivio interferente",
    subtitleTag: "frammenti testuali, scaffali olografici, segnali corrotti",
    sideNote: "Le informazioni utili sono mischiate a rumore: ripara il testo senza perdere il senso operativo.",
    ruleTitle: "Senso prima della forma",
    ruleText: "Una frase corretta deve anche servire alla missione. Cerca accordo, precisione e informazione utile.",
    stageHint: "I frammenti sospesi non sono tutti utili: separa segnale, rumore e comando.",
    accent: 0x9f8cff,
    secondary: 0xf7d37a,
    dark: 0x0a0d18,
    motif: "archive",
    density: 4,
    depth: 3,
    motion: 3,
    atmosphereLabel: "Rumore informativo: frammenti utili e falsi indizi convivono.",
  },
  5: {
    id: "number-factory",
    levelName: "Fabbrica Numerica",
    palette: "factory",
    propTheme: "factory",
    stageTitle: "linea di produzione numerica",
    subtitleTag: "macchine, nastri, vincoli e trasformazioni",
    sideNote: "La fabbrica non chiede calcoli isolati: ogni macchina trasforma il risultato e prepara il passo successivo.",
    ruleTitle: "Catena di trasformazione",
    ruleText: "Ogni errore produce un valore coerente ma sbagliato. Controlla i passaggi intermedi prima del risultato finale.",
    stageHint: "Segui il nastro: ingresso, trasformazione, filtro, uscita.",
    accent: 0xf6c85f,
    secondary: 0x8aa6b0,
    dark: 0x0b0f14,
    motif: "factory",
    density: 5,
    depth: 4,
    motion: 4,
    atmosphereLabel: "Produzione numerica: ogni macchina modifica il flusso.",
  },
  6: {
    id: "cartography-room",
    levelName: "Sala Cartografica",
    palette: "academy",
    propTheme: "academy",
    stageTitle: "sala cartografica",
    subtitleTag: "coordinate, assi, percorsi e modelli",
    sideNote: "La stanza proietta mappe e coordinate: la soluzione nasce da posizione, direzione e relazioni spaziali.",
    ruleTitle: "Modello spaziale",
    ruleText: "Traduci il problema in una mappa: punti, distanze, sequenze e coordinate riducono l'incertezza.",
    stageHint: "Assi e reticoli aiutano a vedere il problema invece di tenerlo tutto a mente.",
    accent: 0x4c7dff,
    secondary: 0x6be7d6,
    dark: 0x071018,
    motif: "map",
    density: 6,
    depth: 5,
    motion: 4,
    atmosphereLabel: "Spazio misurabile: assi, coordinate e percorsi diventano strumenti.",
  },
  7: {
    id: "logic-reactor",
    levelName: "Reattore Logico",
    palette: "circuit",
    propTheme: "factory",
    stageTitle: "reattore logico",
    subtitleTag: "energia instabile, vincoli multipli, diagnosi avanzata",
    sideNote: "I sistemi si influenzano a vicenda: una scelta veloce puo stabilizzare un modulo e destabilizzarne un altro.",
    ruleTitle: "Vincoli incrociati",
    ruleText: "Prima formula un'ipotesi, poi verifica l'effetto. Le soluzioni per tentativi rapidi hanno punteggio basso.",
    stageHint: "Gli anelli del reattore mostrano dipendenze: non isolare un sistema se il segnale passa altrove.",
    accent: 0x6be7d6,
    secondary: 0xc94b55,
    dark: 0x050b12,
    motif: "reactor",
    density: 7,
    depth: 6,
    motion: 5,
    atmosphereLabel: "Vincoli incrociati: il sistema reagisce a ogni scelta.",
  },
  8: {
    id: "academy-core",
    levelName: "Nucleo dell'Accademia",
    palette: "archive",
    propTheme: "archive",
    stageTitle: "nucleo dell'accademia",
    subtitleTag: "sintesi finale, sistemi sovrapposti, interfacce profonde",
    sideNote: "Il nucleo combina linguaggio, calcolo, circuito e comando: ogni soluzione deve essere precisa e motivata.",
    ruleTitle: "Sintesi",
    ruleText: "Non basta risolvere: devi capire perche la soluzione regge quando cambiano dati, vincoli e contesto.",
    stageHint: "Le colonne di luce collegano tutti i moduli: il livello misura padronanza, non memoria.",
    accent: 0xf7d37a,
    secondary: 0x9f8cff,
    dark: 0x0a0d18,
    motif: "core",
    density: 8,
    depth: 7,
    motion: 6,
    atmosphereLabel: "Sintesi finale: tutti i linguaggi della missione si sovrappongono.",
  },
};

const focusVisuals: Record<ProceduralSpecialization, { label: string; marker: string; color: number }> = {
  libera: { label: "Percorso misto", marker: "tutti i sistemi", color: 0x6be7d6 },
  matematica: { label: "Focus matematica", marker: "macchine numeriche", color: 0xf6c85f },
  italiano: { label: "Focus italiano", marker: "archivi linguistici", color: 0x9f8cff },
  inglese: { label: "Focus inglese", marker: "terminali operativi", color: 0x4c7dff },
  elettronica: { label: "Focus elettronica", marker: "banchi circuito", color: 0x6be7d6 },
  coding: { label: "Focus coding", marker: "griglie robotiche", color: 0x70d68a },
  musica: { label: "Focus musica", marker: "pentagrammi luminosi", color: 0xf7d37a },
};

export function proceduralVisualThemeFor(run: ProceduralRunSave): ProceduralVisualTheme {
  const base = levelThemes[run.difficulty] ?? levelThemes[8];
  const focus = proceduralRunRules.focusFor(run);
  const focusVisual = focusVisuals[focus];
  const training = proceduralRunRules.modeFor(run) === "training" && focus !== "libera";
  return {
    ...base,
    level: run.difficulty,
    focus,
    stageTitle: training ? `${base.stageTitle} - ${focusVisual.marker}` : base.stageTitle,
    subtitleTag: `${base.subtitleTag} | ${focusVisual.label}`,
    accent: training ? focusVisual.color : base.accent,
  };
}

export function drawProceduralStageAtmosphere(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  solvedCount: number,
  requiredCount: number,
  seed: string,
): void {
  const progress = requiredCount > 0 ? Phaser.Math.Clamp(solvedCount / requiredCount, 0, 1) : 0;
  const random = new Random(`${seed}:${theme.id}:${theme.focus}:visual`);
  drawStageBase(scene, rect, theme, progress);
  drawLevelDepthBackplate(scene, rect, theme, progress);
  drawLevelFloorMotif(scene, rect, theme, random.fork("floor"), progress);
  drawSeededWallArchitecture(scene, rect, theme, random.fork("architecture"), progress);
  drawSeededCableLoom(scene, rect, theme, random.fork("cables"), progress);
  drawSeededLightRig(scene, rect, theme, random.fork("lights"), progress);
  if (theme.id === "trace-room") drawTraceRoom(scene, rect, theme);
  if (theme.id === "circuit-workshop") drawCircuitWorkshop(scene, rect, theme);
  if (theme.id === "glass-greenhouse") drawGreenhouse(scene, rect, theme);
  if (theme.id === "interference-archive") drawArchive(scene, rect, theme);
  if (theme.id === "number-factory") drawFactory(scene, rect, theme);
  if (theme.id === "cartography-room") drawCartography(scene, rect, theme);
  if (theme.id === "logic-reactor") drawReactor(scene, rect, theme);
  if (theme.id === "academy-core") drawAcademyCore(scene, rect, theme);
  drawSeededFocusOverprint(scene, rect, theme, random.fork("focus"));
  drawSeededForegroundDepth(scene, rect, theme, random.fork("foreground"), progress);
  drawProgressionConstellation(scene, rect, theme, progress);
  drawLevelPlate(scene, rect, theme, progress);
}

function drawStageBase(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme, progress: number): void {
  const g = scene.add.graphics();
  g.fillStyle(theme.dark, 0.2);
  g.fillRoundedRect(rect.x + 34, rect.y + 56, rect.width - 68, rect.height - 96, 12);
  g.lineStyle(2, theme.accent, 0.13);
  g.strokeRoundedRect(rect.x + 34, rect.y + 56, rect.width - 68, rect.height - 96, 12);
  g.fillStyle(theme.accent, 0.05 + progress * 0.06);
  g.fillRoundedRect(rect.x + 52, rect.y + 72, (rect.width - 104) * Math.max(0.08, progress), 5, 3);
  g.fillStyle(theme.secondary, 0.28);
  g.fillRoundedRect(rect.x + 52, rect.y + 72, 54, 5, 3);
}

function drawLevelDepthBackplate(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme, progress: number): void {
  const g = scene.add.graphics();
  const cx = rect.x + rect.width / 2;
  const top = rect.y + 88;
  const bottom = rect.y + rect.height - 78;
  const nearInset = 44;
  const farWidth = rect.width * (0.22 + theme.depth * 0.018);
  const alpha = 0.012 + theme.depth * 0.004 + progress * 0.012;

  g.fillStyle(theme.accent, alpha);
  g.fillTriangle(cx, top, rect.x + nearInset, bottom, rect.x + rect.width - nearInset, bottom);
  g.lineStyle(1, theme.accent, 0.045 + theme.depth * 0.008);
  g.strokeTriangle(cx, top, rect.x + nearInset, bottom, rect.x + rect.width - nearInset, bottom);

  const corridorBands = 3 + Math.floor(theme.depth / 2);
  for (let index = 0; index < corridorBands; index += 1) {
    const t = (index + 1) / (corridorBands + 1);
    const y = Phaser.Math.Linear(top + 20, bottom - 18, t);
    const half = Phaser.Math.Linear(farWidth, rect.width / 2 - nearInset, t);
    g.lineStyle(1, index === theme.level % corridorBands ? theme.secondary : theme.accent, 0.04 + t * 0.05);
    g.lineBetween(cx - half, y, cx + half, y);
  }

  g.lineStyle(2, theme.secondary, 0.035 + progress * 0.02);
  g.lineBetween(rect.x + 54, bottom, cx - farWidth * 0.45, top + 18);
  g.lineBetween(rect.x + rect.width - 54, bottom, cx + farWidth * 0.45, top + 18);
}

function drawLevelFloorMotif(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const left = rect.x + 78;
  const right = rect.x + rect.width - 78;
  const top = rect.y + 112;
  const bottom = rect.y + rect.height - 98;
  const midY = rect.y + rect.height * 0.55;
  const motifAlpha = 0.11 + theme.density * 0.012 + progress * 0.035;

  g.lineStyle(1, theme.accent, motifAlpha);
  if (theme.motif === "trace") {
    const points = [
      { x: left + 12, y: bottom - 18 },
      { x: left + 150, y: midY + 42 },
      { x: rect.x + rect.width * 0.48, y: midY - 24 },
      { x: right - 124, y: top + 88 },
      { x: right - 12, y: top + 42 },
    ];
    points.slice(1).forEach((point, index) => {
      const prev = points[index];
      g.lineBetween(prev.x, prev.y, point.x, point.y);
    });
    points.forEach((point, index) => {
      g.fillStyle(index <= Math.ceil(progress * 4) ? theme.secondary : theme.accent, 0.18);
      g.fillCircle(point.x, point.y, 6 + index);
    });
  } else if (theme.motif === "circuit") {
    for (let index = 0; index < 6; index += 1) {
      const y = top + 28 + index * 42;
      const x1 = left + random.integer(0, 64);
      const x2 = right - random.integer(0, 82);
      g.lineBetween(x1, y, x2, y);
      g.strokeCircle(x1 + 84, y, 10);
      g.strokeRoundedRect(x2 - 70, y - 12, 46, 24, 5);
      if (index % 2 === 0) g.lineBetween(x2 - 24, y, x2 - 24, y + 32);
    }
  } else if (theme.motif === "bio") {
    for (let index = 0; index < 7; index += 1) {
      const x = left + index * ((right - left) / 6);
      g.strokeEllipse(x, midY + Math.sin(index) * 32, 42, 76);
      g.lineBetween(x, midY + 34, x + random.integer(-28, 28), midY - 40);
      g.fillStyle(index / 7 < progress ? theme.secondary : theme.accent, 0.09);
      g.fillEllipse(x, midY + Math.sin(index) * 32, 32, 54);
    }
  } else if (theme.motif === "archive") {
    for (let index = 0; index < 9; index += 1) {
      const x = left + random.integer(0, right - left - 74);
      const y = top + random.integer(0, bottom - top - 42);
      g.strokeRoundedRect(x, y, 62, 34, 4);
      g.lineBetween(x + 9, y + 11, x + 52, y + 11);
      g.lineBetween(x + 9, y + 21, x + random.integer(30, 55), y + 21);
    }
  } else if (theme.motif === "factory") {
    g.lineStyle(4, theme.secondary, 0.13 + progress * 0.04);
    g.lineBetween(left, midY + 90, right, midY + 90);
    for (let index = 0; index < 8; index += 1) {
      const x = left + index * ((right - left) / 7);
      g.lineStyle(2, theme.accent, motifAlpha);
      g.strokeCircle(x, midY + 90, 18 + (index % 3) * 4);
      g.lineBetween(x - 14, midY + 90, x + 14, midY + 90);
      g.lineBetween(x, midY + 76, x, midY + 104);
    }
  } else if (theme.motif === "map") {
    for (let x = left; x <= right; x += 52) g.lineBetween(x, top, x, bottom);
    for (let y = top; y <= bottom; y += 42) g.lineBetween(left, y, right, y);
    g.lineStyle(3, theme.secondary, 0.2);
    g.lineBetween(left + 40, bottom - 32, left + 188, bottom - 122);
    g.lineBetween(left + 188, bottom - 122, right - 148, top + 90);
    g.lineBetween(right - 148, top + 90, right - 28, top + 50);
  } else if (theme.motif === "reactor") {
    const cx = rect.x + rect.width / 2;
    const cy = rect.y + rect.height / 2 + 18;
    for (let index = 0; index < 6; index += 1) {
      g.lineStyle(2, index % 2 ? theme.secondary : theme.accent, 0.09 + index * 0.012);
      g.strokeCircle(cx, cy, 48 + index * 34);
    }
    for (let index = 0; index < 8; index += 1) {
      const angle = (Math.PI * 2 * index) / 8;
      g.lineBetween(cx, cy, cx + Math.cos(angle) * 240, cy + Math.sin(angle) * 180);
    }
  } else {
    const cx = rect.x + rect.width / 2;
    for (let index = 0; index < 6; index += 1) {
      const x = cx - 190 + index * 76;
      g.lineStyle(2, index % 2 ? theme.secondary : theme.accent, 0.11);
      g.lineBetween(x, top + 12, x + 18, bottom - 16);
      g.strokeRoundedRect(x - 22, top + 24 + (index % 2) * 34, 54, bottom - top - 70, 12);
    }
    g.fillStyle(theme.secondary, 0.075 + progress * 0.05);
    g.fillCircle(cx, midY, 78);
  }
}

function drawSeededWallArchitecture(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const panelCount = 5 + theme.level;
  for (let index = 0; index < panelCount; index += 1) {
    const w = random.integer(54, 132);
    const h = random.integer(42, 118);
    const x = rect.x + random.integer(64, Math.max(72, rect.width - 160));
    const y = rect.y + random.integer(88, Math.max(96, rect.height - 170));
    const alpha = 0.035 + progress * 0.018 + random.next() * 0.03;
    g.fillStyle(index % 3 === 0 ? theme.secondary : theme.accent, alpha);
    g.fillRoundedRect(x, y, w, h, random.integer(4, 12));
    g.lineStyle(1, index % 2 === 0 ? theme.accent : theme.secondary, 0.08 + progress * 0.05);
    g.strokeRoundedRect(x, y, w, h, 6);
    if (random.bool(0.45)) {
      g.lineStyle(1, 0xffffff, 0.05);
      g.lineBetween(x + 12, y + 16, x + w - 12, y + 16);
      g.lineBetween(x + 12, y + h - 14, x + w * random.next(), y + h - 14);
    }
  }

  const ribCount = 3 + Math.floor(theme.level / 2);
  g.lineStyle(2, theme.accent, 0.055 + progress * 0.06);
  for (let index = 0; index < ribCount; index += 1) {
    const x = rect.x + 70 + index * ((rect.width - 140) / Math.max(1, ribCount - 1));
    const skew = random.integer(-34, 34);
    g.lineBetween(x, rect.y + 78, x + skew, rect.y + rect.height - 72);
  }
}

function drawSeededCableLoom(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const cableCount = 3 + Math.min(7, theme.level);
  for (let index = 0; index < cableCount; index += 1) {
    const startX = rect.x + random.integer(58, rect.width - 58);
    const startY = rect.y + random.integer(90, rect.height - 96);
    const endX = rect.x + random.integer(58, rect.width - 58);
    const endY = rect.y + random.integer(90, rect.height - 96);
    const midX = (startX + endX) / 2 + random.integer(-80, 80);
    const midY = (startY + endY) / 2 + random.integer(-60, 60);
    const color = index % 4 === 0 ? theme.secondary : theme.accent;
    const alpha = 0.08 + progress * 0.08 + random.next() * 0.04;
    g.lineStyle(index % 3 === 0 ? 3 : 2, color, alpha);
    drawQuadraticSegments(g, startX, startY, midX, midY, endX, endY, 12);
    if (random.bool(0.6)) {
      scene.add.circle(endX, endY, random.integer(3, 6), color, 0.18 + progress * 0.2);
    }
  }
}

function drawQuadraticSegments(
  g: Phaser.GameObjects.Graphics,
  startX: number,
  startY: number,
  controlX: number,
  controlY: number,
  endX: number,
  endY: number,
  segments: number,
): void {
  let previousX = startX;
  let previousY = startY;
  for (let step = 1; step <= segments; step += 1) {
    const t = step / segments;
    const inverse = 1 - t;
    const x = inverse * inverse * startX + 2 * inverse * t * controlX + t * t * endX;
    const y = inverse * inverse * startY + 2 * inverse * t * controlY + t * t * endY;
    g.lineBetween(previousX, previousY, x, y);
    previousX = x;
    previousY = y;
  }
}

function drawSeededLightRig(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const glowCount = 4 + Math.floor(theme.level * 1.5);
  for (let index = 0; index < glowCount; index += 1) {
    const x = rect.x + random.integer(68, rect.width - 68);
    const y = rect.y + random.integer(74, rect.height - 76);
    const color = random.bool(0.32) ? theme.secondary : theme.accent;
    const glow = scene.add.image(x, y, "soft-glow")
      .setTint(color)
      .setAlpha(0.035 + progress * 0.045 + random.next() * 0.035)
      .setScale(random.integer(5, 18) / 10);
    scene.tweens.add({
      targets: glow,
      alpha: { from: glow.alpha * 0.58, to: glow.alpha * 1.55 },
      scale: glow.scale * (1 + random.next() * 0.12),
      duration: random.integer(1800, 5200),
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }

  const beamCount = theme.level >= 5 ? 3 : 2;
  for (let index = 0; index < beamCount; index += 1) {
    const beam = scene.add.rectangle(
      rect.x + random.integer(80, rect.width - 80),
      rect.y + rect.height / 2,
      random.integer(18, 42),
      rect.height - random.integer(86, 150),
      random.bool(0.5) ? theme.accent : theme.secondary,
      0.018 + progress * 0.025,
    ).setRotation(random.integer(-18, 18) / 100);
    scene.tweens.add({
      targets: beam,
      alpha: { from: 0.01, to: 0.045 + progress * 0.035 },
      duration: random.integer(2600, 6200),
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }
}

function drawSeededFocusOverprint(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme, random: Random): void {
  const g = scene.add.graphics();
  if (theme.focus === "matematica") {
    g.lineStyle(1, theme.accent, 0.12);
    for (let index = 0; index < 6; index += 1) {
      const x = rect.x + 84 + index * 82;
      g.strokeCircle(x, rect.y + 122 + random.integer(-12, 18), 16 + random.integer(0, 14));
      scene.add.text(x - 14, rect.y + 118 + random.integer(-8, 10), `${random.pick(["x", "n", "3", "%", "pi", "="])}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
      }).setAlpha(0.34);
    }
  } else if (theme.focus === "italiano") {
    for (let index = 0; index < 7; index += 1) {
      const line = scene.add.rectangle(
        rect.x + random.integer(78, rect.width - 78),
        rect.y + random.integer(110, rect.height - 112),
        random.integer(42, 118),
        3,
        theme.accent,
        0.14,
      );
      scene.tweens.add({ targets: line, alpha: { from: 0.06, to: 0.2 }, duration: random.integer(1200, 2600), yoyo: true, repeat: -1 });
    }
  } else if (theme.focus === "inglese") {
    ["PRESS", "OPEN", "TURN", "CHECK"].forEach((word, index) => {
      scene.add.text(rect.x + 78 + index * 116, rect.y + 100 + random.integer(-12, 22), word, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        fontStyle: "bold",
      }).setAlpha(0.24);
    });
  } else if (theme.focus === "coding") {
    g.lineStyle(1, theme.accent, 0.09);
    for (let x = rect.x + 76; x < rect.x + rect.width - 76; x += 44) {
      g.lineBetween(x, rect.y + 92, x, rect.y + rect.height - 86);
    }
    for (let y = rect.y + 98; y < rect.y + rect.height - 86; y += 44) {
      g.lineBetween(rect.x + 76, y, rect.x + rect.width - 76, y);
    }
  } else if (theme.focus === "elettronica") {
    g.lineStyle(2, theme.accent, 0.14);
    for (let index = 0; index < 5; index += 1) {
      const x = rect.x + 92 + index * 96;
      const y = rect.y + 106 + random.integer(-10, 16);
      g.lineBetween(x - 26, y, x + 26, y);
      g.strokeCircle(x, y, 9);
      g.lineBetween(x, y + 9, x, y + 30);
    }
  } else if (theme.focus === "musica") {
    const staffTop = rect.y + 104;
    const staffLeft = rect.x + 78;
    const staffRight = rect.x + rect.width - 92;
    g.lineStyle(1, theme.accent, 0.12);
    for (let staff = 0; staff < 2; staff += 1) {
      const yBase = staffTop + staff * 142;
      for (let line = 0; line < 5; line += 1) {
        g.lineBetween(staffLeft, yBase + line * 10, staffRight, yBase + line * 10);
      }
      for (let note = 0; note < 6; note += 1) {
        const x = staffLeft + 72 + note * 88 + random.integer(-14, 14);
        const y = yBase + random.integer(-10, 50);
        g.fillStyle(note % 2 ? theme.secondary : theme.accent, 0.16);
        g.fillEllipse(x, y, 18, 12);
        g.lineStyle(1, note % 2 ? theme.secondary : theme.accent, 0.16);
        g.lineBetween(x + 8, y, x + 8, y - 34);
      }
    }
  }
}

function drawSeededForegroundDepth(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  g.fillStyle(0x000000, 0.16);
  const leftWidth = random.integer(26, 76);
  const rightWidth = random.integer(30, 88);
  g.fillTriangle(rect.x + 6, rect.y + rect.height - 12, rect.x + leftWidth, rect.y + rect.height - 12, rect.x + 8, rect.y + rect.height - random.integer(92, 154));
  g.fillTriangle(rect.x + rect.width - 8, rect.y + rect.height - 12, rect.x + rect.width - rightWidth, rect.y + rect.height - 12, rect.x + rect.width - 18, rect.y + rect.height - random.integer(100, 174));
  g.fillStyle(theme.accent, 0.035 + progress * 0.018);
  g.fillRect(rect.x + 36, rect.y + rect.height - 24, rect.width - 72, 4);
}

function drawProgressionConstellation(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme, progress: number): void {
  const g = scene.add.graphics();
  const y = rect.y + rect.height - 46;
  const startX = rect.x + 92;
  const gap = (rect.width - 184) / 7;
  const activeLevel = theme.level;
  g.lineStyle(2, theme.accent, 0.1);
  g.lineBetween(startX, y, startX + gap * 7, y);
  for (let index = 1; index <= 8; index += 1) {
    const x = startX + (index - 1) * gap;
    const reached = index < activeLevel;
    const current = index === activeLevel;
    const color = reached || current ? theme.secondary : 0x6b7d84;
    const alpha = current ? 0.82 : reached ? 0.48 : 0.22;
    g.fillStyle(color, alpha);
    g.fillCircle(x, y, current ? 7 : 5);
    g.lineStyle(1, color, alpha + 0.1);
    g.strokeCircle(x, y, current ? 16 + progress * 8 : 10);
  }
  scene.add.text(startX - 16, y + 14, "1", {
    fontFamily: "Inter, Arial",
    fontSize: "9px",
    color: "#9aaab0",
  }).setAlpha(0.72);
  scene.add.text(startX + gap * 7 - 4, y + 14, "8", {
    fontFamily: "Inter, Arial",
    fontSize: "9px",
    color: "#9aaab0",
  }).setAlpha(0.72);
}

function drawLevelPlate(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme, progress: number): void {
  scene.add.text(rect.x + 26, rect.y + 44, `LIVELLO ${theme.level} - ${theme.levelName}`.toUpperCase(), {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#f5fbff",
    fontStyle: "bold",
  });
  scene.add.text(rect.x + rect.width - 168, rect.y + 44, `${Math.round(progress * 100)}% stabile`, {
    fontFamily: "Inter, Arial",
    fontSize: "11px",
    color: progress >= 1 ? "#f7d37a" : "#9aaab0",
    fontStyle: "bold",
  }).setOrigin(0, 0);
  scene.add.text(rect.x + 26, rect.y + 62, theme.atmosphereLabel, {
    fontFamily: "Inter, Arial",
    fontSize: "10px",
    color: "#9aaab0",
    wordWrap: { width: rect.width - 224 },
  }).setAlpha(0.82);
}

function drawTraceRoom(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  const g = scene.add.graphics();
  g.lineStyle(3, theme.accent, 0.18);
  const y = rect.y + rect.height * 0.52;
  g.lineBetween(rect.x + 86, y, rect.x + rect.width - 86, y - 34);
  g.lineStyle(2, theme.secondary, 0.16);
  g.lineBetween(rect.x + 140, y + 90, rect.x + rect.width - 120, y - 118);
  for (let i = 0; i < 5; i += 1) {
    VisualKit.statusLight(scene, rect.x + 118 + i * 102, rect.y + 132 + (i % 2) * 62, i % 2 ? theme.secondary : theme.accent, true)
      .setAlpha(0.42);
  }
}

function drawCircuitWorkshop(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  const g = scene.add.graphics();
  g.lineStyle(5, theme.secondary, 0.18);
  g.lineBetween(rect.x + 72, rect.y + 112, rect.x + rect.width - 70, rect.y + 112);
  g.lineStyle(3, theme.accent, 0.2);
  for (let i = 0; i < 5; i += 1) {
    const x = rect.x + 88 + i * 104;
    g.strokeRoundedRect(x, rect.y + 126 + (i % 2) * 72, 78, 42, 6);
    g.lineBetween(x + 78, rect.y + 147 + (i % 2) * 72, x + 118, rect.y + 147 + ((i + 1) % 2) * 72);
  }
  scene.add.rectangle(rect.x + rect.width - 92, rect.y + 88, 86, 26, 0xc94b55, 0.18)
    .setRotation(-0.08)
    .setStrokeStyle(1, theme.secondary, 0.34);
}

function drawGreenhouse(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  for (let i = 0; i < 5; i += 1) {
    const x = rect.x + 92 + i * 110;
    const pod = scene.add.ellipse(x, rect.y + 242 + (i % 2) * 34, 74, 122, theme.accent, 0.07)
      .setStrokeStyle(2, theme.accent, 0.22);
    scene.tweens.add({ targets: pod, alpha: { from: 0.04, to: 0.12 }, duration: 1800 + i * 260, yoyo: true, repeat: -1 });
    scene.add.arc(x, rect.y + 252 + (i % 2) * 34, 20, 210, 330, false, theme.accent, 0.24);
    scene.add.arc(x + 18, rect.y + 238 + (i % 2) * 34, 16, 120, 260, false, theme.secondary, 0.18);
  }
  const mist = scene.add.rectangle(rect.x + rect.width / 2, rect.y + 132, rect.width - 120, 34, 0xffffff, 0.035);
  scene.tweens.add({ targets: mist, x: mist.x + 26, alpha: { from: 0.018, to: 0.055 }, duration: 4200, yoyo: true, repeat: -1 });
}

function drawArchive(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  for (let i = 0; i < 6; i += 1) {
    const shard = VisualKit.hologramShard(scene, rect.x + 76 + i * 84, rect.y + 128 + (i % 3) * 82, 64, 46, "archive");
    shard.setAlpha(0.42);
  }
  const g = scene.add.graphics();
  g.lineStyle(1, theme.accent, 0.12);
  for (let i = 0; i < 8; i += 1) {
    g.lineBetween(rect.x + 78, rect.y + 96 + i * 42, rect.x + rect.width - 92, rect.y + 110 + i * 38);
  }
}

function drawFactory(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  const belt = scene.add.rectangle(rect.x + rect.width / 2, rect.y + 306, rect.width - 132, 54, 0x000000, 0.26)
    .setStrokeStyle(2, theme.secondary, 0.24);
  scene.tweens.add({ targets: belt, alpha: { from: 0.2, to: 0.36 }, duration: 1400, yoyo: true, repeat: -1 });
  const g = scene.add.graphics();
  g.lineStyle(2, theme.accent, 0.24);
  for (let i = 0; i < 7; i += 1) {
    const x = rect.x + 90 + i * 74;
    g.strokeCircle(x, rect.y + 306, 22 + (i % 2) * 8);
    g.lineBetween(x - 16, rect.y + 306, x + 16, rect.y + 306);
    g.lineBetween(x, rect.y + 290, x, rect.y + 322);
  }
  scene.add.text(rect.x + rect.width - 170, rect.y + 94, "IN -> + x / -> OUT", {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#f7d37a",
    fontStyle: "bold",
  });
}

function drawCartography(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  const g = scene.add.graphics();
  const originX = rect.x + 162;
  const originY = rect.y + 360;
  g.lineStyle(2, theme.accent, 0.34);
  g.lineBetween(originX, rect.y + 96, originX, rect.y + rect.height - 84);
  g.lineBetween(rect.x + 74, originY, rect.x + rect.width - 88, originY);
  g.lineStyle(1, theme.secondary, 0.14);
  for (let i = 1; i < 7; i += 1) {
    g.lineBetween(originX + i * 58, rect.y + 112, originX + i * 58, rect.y + rect.height - 96);
    g.lineBetween(rect.x + 88, originY - i * 34, rect.x + rect.width - 104, originY - i * 34);
  }
  scene.add.circle(originX + 232, originY - 102, 10, theme.secondary, 0.72);
  scene.add.circle(originX + 348, originY - 34, 8, theme.accent, 0.72);
}

function drawReactor(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  const x = rect.x + rect.width / 2;
  const y = rect.y + rect.height / 2 + 24;
  for (let i = 0; i < 4; i += 1) {
    const ring = scene.add.circle(x, y, 58 + i * 38, theme.accent, 0)
      .setStrokeStyle(2, i === 3 ? theme.secondary : theme.accent, 0.18 - i * 0.02);
    scene.tweens.add({ targets: ring, rotation: Math.PI * 2, scale: { from: 0.98, to: 1.03 }, duration: 2600 + i * 800, yoyo: true, repeat: -1 });
  }
  const g = scene.add.graphics();
  g.lineStyle(3, theme.secondary, 0.12);
  g.lineBetween(rect.x + 72, y, x - 82, y - 72);
  g.lineBetween(x + 82, y + 72, rect.x + rect.width - 72, y);
  g.lineBetween(x, rect.y + 88, x, y - 112);
}

function drawAcademyCore(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
  const core = scene.add.rectangle(rect.x + rect.width / 2, rect.y + rect.height / 2 + 4, 118, rect.height - 156, theme.accent, 0.07)
    .setStrokeStyle(2, theme.secondary, 0.24);
  scene.tweens.add({ targets: core, alpha: { from: 0.05, to: 0.14 }, duration: 2400, yoyo: true, repeat: -1 });
  for (let i = 0; i < 5; i += 1) {
    const shard = VisualKit.hologramShard(scene, rect.x + 120 + i * 94, rect.y + 124 + (i % 2) * 210, 72, 54, i % 2 ? "archive" : "academy");
    shard.setAlpha(0.46);
  }
  scene.add.circle(rect.x + rect.width / 2, rect.y + rect.height / 2 + 4, 44, theme.secondary, 0.1)
    .setStrokeStyle(2, theme.secondary, 0.32);
}
