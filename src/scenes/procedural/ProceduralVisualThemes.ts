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

const focusVisuals: Record<ProceduralSpecialization, {
  label: string;
  marker: string;
  color: number;
  palette: ChromePalette;
  propTheme: ProceduralPropTheme;
  motif: LevelMotif;
  secondary: number;
}> = {
  libera: {
    label: "Percorso misto",
    marker: "tutti i sistemi",
    color: 0x6be7d6,
    palette: "academy",
    propTheme: "academy",
    motif: "core",
    secondary: 0xf7d37a,
  },
  matematica: {
    label: "Focus matematica",
    marker: "macchine numeriche",
    color: 0xf6c85f,
    palette: "factory",
    propTheme: "factory",
    motif: "factory",
    secondary: 0xffb36b,
  },
  italiano: {
    label: "Focus italiano",
    marker: "archivi linguistici",
    color: 0x9f8cff,
    palette: "archive",
    propTheme: "archive",
    motif: "archive",
    secondary: 0xf7d37a,
  },
  inglese: {
    label: "Focus inglese",
    marker: "terminali operativi",
    color: 0x4c7dff,
    palette: "academy",
    propTheme: "lab",
    motif: "map",
    secondary: 0x6be7d6,
  },
  elettronica: {
    label: "Focus elettronica",
    marker: "banchi circuito",
    color: 0x6be7d6,
    palette: "circuit",
    propTheme: "circuit",
    motif: "circuit",
    secondary: 0xffb36b,
  },
  coding: {
    label: "Focus coding",
    marker: "griglie robotiche",
    color: 0x70d68a,
    palette: "lab",
    propTheme: "academy",
    motif: "trace",
    secondary: 0xf6c85f,
  },
  musica: {
    label: "Focus musica",
    marker: "pentagrammi luminosi",
    color: 0xf7d37a,
    palette: "archive",
    propTheme: "academy",
    motif: "core",
    secondary: 0x9f8cff,
  },
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
    palette: training ? focusVisual.palette : base.palette,
    propTheme: training ? focusVisual.propTheme : base.propTheme,
    motif: training ? focusVisual.motif : base.motif,
    stageTitle: training ? `${base.stageTitle} - ${focusVisual.marker}` : base.stageTitle,
    subtitleTag: `${base.subtitleTag} | ${focusVisual.label}`,
    accent: training ? focusVisual.color : base.accent,
    secondary: training ? focusVisual.secondary : base.secondary,
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
  drawMissionSpecificBackdrop(scene, rect, theme, random.fork("mission-backdrop"), progress);
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

function drawMissionSpecificBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const imageVariant = random.fork("mission-image").integer(0, 1);
  drawMissionImageLayer(scene, rect, theme, progress, imageVariant);
  if (theme.focus === "matematica") {
    drawMathMissionBackdrop(scene, rect, theme, random, progress);
  } else if (theme.focus === "italiano") {
    drawItalianMissionBackdrop(scene, rect, theme, random, progress);
  } else if (theme.focus === "inglese") {
    drawEnglishMissionBackdrop(scene, rect, theme, random, progress);
  } else if (theme.focus === "elettronica") {
    drawElectronicsMissionBackdrop(scene, rect, theme, random, progress);
  } else if (theme.focus === "coding") {
    drawCodingMissionBackdrop(scene, rect, theme, random, progress);
  } else if (theme.focus === "musica") {
    drawMusicMissionBackdrop(scene, rect, theme, random, progress);
  } else {
    drawSynthesisMissionBackdrop(scene, rect, theme, random, progress);
  }
}

function drawMissionImageLayer(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  progress: number,
  imageVariant: number,
): void {
  const key = missionBackdropKey(theme.focus, imageVariant);
  if (!scene.textures.exists(key)) {
    const fallbackKey = fallbackMissionBackdropKey(theme.focus);
    if (!scene.textures.exists(fallbackKey)) return;
    drawMissionImage(scene, rect, theme, progress, fallbackKey);
    return;
  }
  drawMissionImage(scene, rect, theme, progress, key);
}

function drawMissionImage(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  progress: number,
  key: string,
): void {
  const image = scene.add.image(rect.x + rect.width / 2, rect.y + rect.height / 2 + 10, key)
    .setDisplaySize(rect.width - 56, rect.height - 102)
    .setAlpha(0.3 + progress * 0.08);
  scene.tweens.add({
    targets: image,
    scaleX: image.scaleX * 1.012,
    scaleY: image.scaleY * 1.012,
    alpha: { from: image.alpha * 0.86, to: Math.min(0.44, image.alpha * 1.15) },
    duration: 9000,
    yoyo: true,
    repeat: -1,
    ease: "Sine.easeInOut",
  });
  scene.add.rectangle(rect.x + rect.width / 2, rect.y + rect.height / 2 + 10, rect.width - 56, rect.height - 102, theme.dark, 0.22)
    .setStrokeStyle(1, theme.accent, 0.16);
}

function missionBackdropKey(focus: ProceduralSpecialization, variant: number): string {
  const variantKeys: Partial<Record<ProceduralSpecialization, [string, string]>> = {
    matematica: ["mission-math-factory-bg", "mission-math-grid-bg"],
    italiano: ["mission-italian-archive-bg", "mission-italian-library-bg"],
    inglese: ["mission-english-control-bg", "mission-english-radio-bg"],
    elettronica: ["mission-electronics-bench-bg", "mission-electronics-power-bg"],
    coding: ["mission-coding-robot-bg", "mission-coding-terminal-bg"],
    musica: ["mission-music-staff-bg", "mission-music-audio-bg"],
  };
  const keys = variantKeys[focus];
  if (keys) return keys[variant % keys.length];
  return fallbackMissionBackdropKey(focus);
}

function fallbackMissionBackdropKey(focus: ProceduralSpecialization): string {
  if (focus === "matematica") return "mission-bg-math";
  if (focus === "italiano") return "mission-bg-italian";
  if (focus === "inglese") return "mission-bg-english";
  if (focus === "elettronica") return "mission-bg-electronics";
  if (focus === "coding") return "mission-bg-coding";
  if (focus === "musica") return "mission-bg-music";
  return "mission-bg-synthesis";
}

function drawBackdropTitle(scene: Phaser.Scene, rect: ChromeRect, text: string, theme: ProceduralVisualTheme): void {
  scene.add.rectangle(rect.x + rect.width - 172, rect.y + 92, 206, 30, theme.dark, 0.52)
    .setStrokeStyle(1, theme.accent, 0.24);
  scene.add.text(rect.x + rect.width - 270, rect.y + 83, text.toUpperCase(), {
    fontFamily: "Inter, Arial",
    fontSize: "10px",
    color: "#f5fbff",
    fontStyle: "bold",
    align: "right",
    wordWrap: { width: 190 },
  }).setAlpha(0.78);
}

function drawMathMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  const left = rect.x + 76;
  const y = rect.y + rect.height * 0.5;
  const machineY = y - 34;
  drawBackdropTitle(scene, rect, ["officina numerica", "piano cartesiano", "laboratorio formule"][variant], theme);

  g.lineStyle(5, theme.secondary, 0.12 + progress * 0.05);
  g.lineBetween(left, y + 104, rect.x + rect.width - 76, y + 104);
  const operators = ["×", "+", "−", "÷", "="];
  operators.forEach((operator, index) => {
    const x = left + 72 + index * 94;
    g.fillStyle(index <= progress * operators.length ? theme.secondary : theme.accent, 0.09);
    g.fillRoundedRect(x - 36, machineY + (index % 2) * 38, 72, 64, 10);
    g.lineStyle(2, index % 2 ? theme.accent : theme.secondary, 0.28);
    g.strokeRoundedRect(x - 36, machineY + (index % 2) * 38, 72, 64, 10);
    scene.add.text(x - 11, machineY + 14 + (index % 2) * 38, operator, {
      fontFamily: "Inter, Arial",
      fontSize: "25px",
      color: index === operators.length - 1 ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setAlpha(0.74);
    if (index < operators.length - 1) {
      g.lineStyle(2, theme.accent, 0.18);
      g.lineBetween(x + 38, machineY + 32 + (index % 2) * 38, x + 58, machineY + 32 + ((index + 1) % 2) * 38);
    }
  });

  for (let row = 0; row < 4; row += 1) {
    for (let col = 0; col < 9; col += 1) {
      if (!random.bool(0.42)) continue;
      scene.add.text(rect.x + 90 + col * 52, rect.y + 128 + row * 46, `${random.integer(2, 99)}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
      }).setAlpha(0.16 + progress * 0.08);
    }
  }
  if (variant === 1) {
    const originX = rect.x + rect.width - 250;
    const originY = rect.y + 316;
    g.lineStyle(1, theme.accent, 0.13);
    for (let step = -3; step <= 3; step += 1) {
      g.lineBetween(originX - 126, originY + step * 26, originX + 126, originY + step * 26);
      g.lineBetween(originX + step * 34, originY - 96, originX + step * 34, originY + 96);
    }
    g.lineStyle(3, theme.secondary, 0.24 + progress * 0.08);
    g.beginPath();
    for (let t = -58; t <= 58; t += 4) {
      const x = originX + t * 2;
      const yy = originY - (0.026 * t * t - 42) * 1.2;
      if (t === -58) g.moveTo(x, yy);
      else g.lineTo(x, yy);
    }
    g.strokePath();
    scene.add.text(originX - 112, originY + 112, "y = ax² + bx + c", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setAlpha(0.34);
  } else if (variant === 2) {
    ["Δ", "√", "x", "∑", "≈"].forEach((symbol, index) => {
      scene.add.text(rect.x + rect.width - 270 + index * 45, rect.y + 138 + (index % 2) * 46, symbol, {
        fontFamily: "Georgia, 'Times New Roman', serif",
        fontSize: "32px",
        color: index % 2 ? "#9ff5e9" : "#f7d37a",
        fontStyle: "bold",
      }).setAlpha(0.18 + progress * 0.08);
    });
  }
}

function drawItalianMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  drawBackdropTitle(scene, rect, ["archivio linguistico", "laboratorio lessico", "sala fonti"][variant], theme);
  const shelves = 4;
  for (let shelf = 0; shelf < shelves; shelf += 1) {
    const y = rect.y + 128 + shelf * 74;
    g.lineStyle(2, theme.secondary, 0.1 + progress * 0.04);
    g.lineBetween(rect.x + 82, y + 48, rect.x + rect.width - 90, y + 48);
    for (let card = 0; card < 7; card += 1) {
      const x = rect.x + 94 + card * 70 + random.integer(-8, 8);
      const h = random.integer(30, 48);
      const tint = random.bool(0.35) ? theme.secondary : theme.accent;
      g.fillStyle(tint, 0.055 + progress * 0.018);
      g.fillRoundedRect(x, y + 48 - h, 42, h, 4);
      g.lineStyle(1, tint, 0.18);
      g.strokeRoundedRect(x, y + 48 - h, 42, h, 4);
      g.lineStyle(1, 0xffffff, 0.07);
      g.lineBetween(x + 7, y + 48 - h + 10, x + 34, y + 48 - h + 10);
      g.lineBetween(x + 7, y + 48 - h + 20, x + random.integer(24, 36), y + 48 - h + 20);
    }
  }
  const words = variant === 1
    ? ["ipotesi", "prova", "registro", "sintesi"]
    : variant === 2
      ? ["fonte", "tesi", "dato", "verifica"]
      : ["soggetto", "causa", "pronome", "coerenza"];
  words.forEach((word, index) => {
    const x = rect.x + 112 + index * 118;
    const y = rect.y + 358 + random.integer(-16, 18);
    scene.add.text(x, y, word, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: index % 2 ? "#f7d37a" : "#d9eaf1",
      fontStyle: "bold",
    }).setAlpha(0.22 + progress * 0.08);
  });
  if (variant === 1) {
    for (let index = 0; index < 6; index += 1) {
      const x = rect.x + rect.width - 260 + (index % 3) * 72;
      const y = rect.y + 138 + Math.floor(index / 3) * 64;
      g.fillStyle(index % 2 ? theme.secondary : theme.accent, 0.065 + progress * 0.02);
      g.fillRoundedRect(x, y, 58, 34, 8);
      g.lineStyle(1, index % 2 ? theme.secondary : theme.accent, 0.22);
      g.strokeRoundedRect(x, y, 58, 34, 8);
      scene.add.text(x + 10, y + 9, random.pick(["≠", "→", "?", "✓", "ne", "ma"]), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setAlpha(0.36);
    }
  } else if (variant === 2) {
    ["fonte A", "fonte B", "ipotesi", "prova"].forEach((label, index) => {
      const x = rect.x + rect.width - 288;
      const y = rect.y + 126 + index * 52;
      g.lineStyle(1, index < 2 ? theme.secondary : theme.accent, 0.24);
      g.strokeRoundedRect(x, y, 146, 30, 6);
      scene.add.text(x + 12, y + 8, label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        fontStyle: "bold",
      }).setAlpha(0.4);
    });
  }
}

function drawEnglishMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  drawBackdropTitle(scene, rect, ["control room", "radio bridge", "data terminal"][variant], theme);
  const terminalX = rect.x + 110;
  const terminalY = rect.y + 136;
  const terminalW = rect.width - 220;
  const terminalH = 194;
  g.fillStyle(0x071018, 0.48);
  g.fillRoundedRect(terminalX, terminalY, terminalW, terminalH, 12);
  g.lineStyle(2, theme.accent, 0.28);
  g.strokeRoundedRect(terminalX, terminalY, terminalW, terminalH, 12);
  const rows = variant === 1
    ? ["LISTEN", "CONFIRM", "REPEAT", "SOURCE", "REPORT"]
    : variant === 2
      ? ["BELOW", "ABOVE", "BETWEEN", "COMPARE", "DECIDE"]
      : ["READ", "CHECK", "PRESS", "TURN", "REPORT"];
  rows.forEach((word, index) => {
    const y = terminalY + 28 + index * 31;
    const active = index <= Math.floor(progress * rows.length);
    scene.add.text(terminalX + 24, y - 8, `${index + 1}. ${word}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: active ? "#f7d37a" : "#d9eaf1",
      fontStyle: "bold",
    }).setAlpha(active ? 0.6 : 0.28);
    g.lineStyle(1, active ? theme.secondary : theme.accent, active ? 0.28 : 0.12);
    g.lineBetween(terminalX + 118, y, terminalX + terminalW - random.integer(58, 108), y);
  });
  for (let index = 0; index < 5; index += 1) {
    const x = terminalX + 58 + index * 82;
    scene.add.rectangle(x, terminalY + terminalH + 52, 44, 28, index % 2 ? theme.secondary : theme.accent, 0.08)
      .setStrokeStyle(1, index % 2 ? theme.secondary : theme.accent, 0.2);
  }
  if (variant === 1) {
    const cx = terminalX + terminalW - 110;
    const cy = terminalY + terminalH + 80;
    g.lineStyle(2, theme.secondary, 0.12 + progress * 0.05);
    for (let ring = 0; ring < 4; ring += 1) g.strokeCircle(cx, cy, 22 + ring * 20);
    scene.add.text(cx - 40, cy - 7, "SIGNAL", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setAlpha(0.36);
  } else if (variant === 2) {
    for (let index = 0; index < 6; index += 1) {
      const h = 18 + random.integer(0, 64);
      g.fillStyle(index % 2 ? theme.secondary : theme.accent, 0.1 + progress * 0.04);
      g.fillRoundedRect(terminalX + terminalW - 190 + index * 22, terminalY + terminalH - 20 - h, 12, h, 4);
    }
  }
}

function drawElectronicsMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  drawBackdropTitle(scene, rect, ["banco circuiti", "rete alimentazione", "schema diagnostico"][variant], theme);
  const boardX = rect.x + 96;
  const boardY = rect.y + 122;
  const boardW = rect.width - 192;
  const boardH = 274;
  g.fillStyle(0x061019, 0.42);
  g.fillRoundedRect(boardX, boardY, boardW, boardH, 14);
  g.lineStyle(2, theme.accent, 0.24);
  g.strokeRoundedRect(boardX, boardY, boardW, boardH, 14);
  for (let index = 0; index < 8; index += 1) {
    const x = boardX + 34 + index * ((boardW - 68) / 7);
    const y = boardY + random.integer(42, boardH - 42);
    const color = index / 7 <= progress ? theme.secondary : theme.accent;
    g.lineStyle(2, color, 0.18 + progress * 0.04);
    g.lineBetween(x, boardY + 22, x, y);
    g.lineBetween(x, y, boardX + boardW - 32, y);
    g.strokeCircle(x, y, 10);
    if (index % 3 === 0) {
      g.strokeRoundedRect(x + 22, y - 12, 52, 24, 5);
    }
  }
  ["V", "Ω", "LED", "SENS"].forEach((label, index) => {
    scene.add.text(boardX + 34 + index * 108, boardY + boardH - 34, label, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setAlpha(0.34);
  });
  if (variant === 1) {
    const cx = boardX + boardW - 92;
    const cy = boardY + 72;
    g.lineStyle(2, theme.secondary, 0.18 + progress * 0.05);
    g.strokeCircle(cx, cy, 34);
    g.strokeCircle(cx, cy, 52);
    g.lineBetween(cx - 66, cy, cx + 66, cy);
    g.lineBetween(cx, cy - 66, cx, cy + 66);
    scene.add.text(cx - 19, cy - 8, "V", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f7d37a", fontStyle: "bold" }).setAlpha(0.46);
  } else if (variant === 2) {
    ["open", "short", "polarity"].forEach((label, index) => {
      scene.add.text(boardX + 56 + index * 122, boardY + 42 + index * 42, label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: index % 2 ? "#f7d37a" : "#9ff5e9",
        fontStyle: "bold",
      }).setAlpha(0.32);
    });
  }
}

function drawCodingMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  drawBackdropTitle(scene, rect, ["simulatore robot", "debug console", "tracciatore loop"][variant], theme);
  const gridX = rect.x + 118;
  const gridY = rect.y + 122;
  const cell = 42;
  g.lineStyle(1, theme.accent, 0.13);
  for (let col = 0; col <= 9; col += 1) {
    g.lineBetween(gridX + col * cell, gridY, gridX + col * cell, gridY + 6 * cell);
  }
  for (let row = 0; row <= 6; row += 1) {
    g.lineBetween(gridX, gridY + row * cell, gridX + 9 * cell, gridY + row * cell);
  }
  const route = [
    { x: gridX + cell * 0.5, y: gridY + cell * 5.5 },
    { x: gridX + cell * 2.5, y: gridY + cell * 5.5 },
    { x: gridX + cell * 2.5, y: gridY + cell * 2.5 },
    { x: gridX + cell * 5.5, y: gridY + cell * 2.5 },
    { x: gridX + cell * 7.5, y: gridY + cell * 0.5 },
  ];
  g.lineStyle(4, theme.secondary, 0.12 + progress * 0.12);
  route.slice(1).forEach((point, index) => {
    const previous = route[index];
    g.lineBetween(previous.x, previous.y, point.x, point.y);
  });
  route.forEach((point, index) => {
    g.fillStyle(index / Math.max(1, route.length - 1) <= progress ? theme.secondary : theme.accent, 0.32);
    g.fillCircle(point.x, point.y, index === 0 || index === route.length - 1 ? 9 : 6);
  });
  const labels = variant === 1 ? ["bug", "state", "trace", "fix"] : variant === 2 ? ["repeat", "while", "step", "exit"] : ["if", "else", "loop", "move"];
  labels.forEach((cmd, index) => {
    scene.add.text(rect.x + 110 + index * 108, rect.y + 390 + random.integer(-10, 8), cmd, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      fontStyle: "bold",
    }).setAlpha(0.22);
  });
  if (variant === 1) {
    for (let row = 0; row < 5; row += 1) {
      scene.add.text(rect.x + rect.width - 284, rect.y + 138 + row * 32, random.pick(["if sensor:", "  move()", "else:", "  wait()", "return ok"]), {
        fontFamily: "Consolas, monospace",
        fontSize: "12px",
        color: row % 2 ? "#f7d37a" : "#d9eaf1",
      }).setAlpha(0.32);
    }
  } else if (variant === 2) {
    const cx = rect.x + rect.width - 180;
    const cy = rect.y + 230;
    g.lineStyle(3, theme.secondary, 0.16 + progress * 0.08);
    g.strokeCircle(cx, cy, 54);
    g.lineBetween(cx + 38, cy - 36, cx + 68, cy - 58);
    g.fillStyle(theme.secondary, 0.22);
    g.fillTriangle(cx + 72, cy - 64, cx + 55, cy - 58, cx + 65, cy - 44);
  }
}

function drawMusicMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  drawBackdropTitle(scene, rect, ["sala armonica", "stanza ascolto", "tastiera luminosa"][variant], theme);
  const left = rect.x + 84;
  const right = rect.x + rect.width - 86;
  const cx = rect.x + rect.width / 2;
  const cy = rect.y + rect.height / 2 + 18;
  g.lineStyle(2, theme.secondary, 0.08 + progress * 0.05);
  for (let ring = 0; ring < 5; ring += 1) {
    g.strokeCircle(cx, cy, 72 + ring * 44);
  }
  g.lineStyle(2, theme.accent, 0.16 + progress * 0.07);
  g.beginPath();
  for (let step = 0; step <= 160; step += 1) {
    const x = left + (step / 160) * (right - left);
    const y = cy + Math.sin(step * 0.18) * 18 + Math.sin(step * 0.047 + progress * 3) * 34;
    if (step === 0) g.moveTo(x, y);
    else g.lineTo(x, y);
  }
  g.strokePath();
  for (let staff = 0; staff < 3; staff += 1) {
    const yBase = rect.y + 126 + staff * 88;
    g.lineStyle(1, theme.accent, 0.14 + progress * 0.04);
    for (let line = 0; line < 5; line += 1) {
      g.lineBetween(left, yBase + line * 10, right, yBase + line * 10);
    }
    for (let note = 0; note < 7; note += 1) {
      const x = left + 48 + note * 72 + random.integer(-12, 12);
      const y = yBase + random.integer(-10, 44);
      const color = note / 6 <= progress ? theme.secondary : theme.accent;
      g.fillStyle(color, 0.18);
      g.fillEllipse(x, y, 18, 12);
      g.lineStyle(2, color, 0.16);
      g.lineBetween(x + 8, y, x + 8, y - 34);
      if (random.bool(0.35)) g.lineBetween(x + 8, y - 34, x + 24, y - 28);
    }
  }
  const meterX = rect.x + rect.width - 238;
  for (let bar = 0; bar < 10; bar += 1) {
    const h = 18 + ((bar * 17) % 54) + progress * 16;
    g.fillStyle(bar % 2 ? theme.secondary : theme.accent, 0.12 + progress * 0.06);
    g.fillRoundedRect(meterX + bar * 16, rect.y + 374 - h, 8, h, 4);
  }
  scene.add.text(rect.x + 108, rect.y + 382, "nota  •  intervallo  •  ritmo  •  ascolto", {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#f7d37a",
    fontStyle: "bold",
  }).setAlpha(0.36);
  if (variant === 1) {
    const waveY = rect.y + rect.height - 156;
    g.lineStyle(2, theme.secondary, 0.18 + progress * 0.06);
    g.beginPath();
    for (let step = 0; step <= 120; step += 1) {
      const x = left + (step / 120) * (right - left);
      const y = waveY + Math.sin(step * 0.34) * (16 + 8 * Math.sin(step * 0.08));
      if (step === 0) g.moveTo(x, y);
      else g.lineTo(x, y);
    }
    g.strokePath();
  } else if (variant === 2) {
    const keyY = rect.y + rect.height - 168;
    for (let key = 0; key < 14; key += 1) {
      const x = left + key * 36;
      g.fillStyle(key % 7 === 1 || key % 7 === 3 || key % 7 === 6 ? theme.accent : 0xffffff, key % 7 === 1 || key % 7 === 3 || key % 7 === 6 ? 0.14 : 0.08);
      g.fillRoundedRect(x, keyY, 28, key % 7 === 1 || key % 7 === 3 || key % 7 === 6 ? 58 : 82, 4);
      g.lineStyle(1, theme.secondary, 0.14);
      g.strokeRoundedRect(x, keyY, 28, key % 7 === 1 || key % 7 === 3 || key % 7 === 6 ? 58 : 82, 4);
    }
  }
}

function drawSynthesisMissionBackdrop(
  scene: Phaser.Scene,
  rect: ChromeRect,
  theme: ProceduralVisualTheme,
  random: Random,
  progress: number,
): void {
  const g = scene.add.graphics();
  const variant = random.integer(0, 2);
  drawBackdropTitle(scene, rect, ["sintesi sistemi", "mappa decisionale", "nucleo prove"][variant], theme);
  const cx = rect.x + rect.width / 2;
  const cy = rect.y + rect.height / 2 + 12;
  const nodes = [
    { label: "123", color: 0xf6c85f, angle: -Math.PI * 0.82 },
    { label: "IT", color: 0x9f8cff, angle: -Math.PI * 0.48 },
    { label: "EN", color: 0x4c7dff, angle: -Math.PI * 0.16 },
    { label: "Ω", color: 0x6be7d6, angle: Math.PI * 0.16 },
    { label: "{ }", color: 0x70d68a, angle: Math.PI * 0.48 },
    { label: "♪", color: 0xf7d37a, angle: Math.PI * 0.82 },
  ];
  nodes.forEach((node, index) => {
    const radius = 160 + (index % 2) * 34;
    const x = cx + Math.cos(node.angle) * radius;
    const y = cy + Math.sin(node.angle) * 106;
    g.lineStyle(2, node.color, 0.12 + progress * 0.06);
    g.lineBetween(cx, cy, x, y);
    g.fillStyle(node.color, 0.13 + progress * 0.04);
    g.fillCircle(x, y, 24);
    g.lineStyle(1, node.color, 0.34);
    g.strokeCircle(x, y, 24);
    scene.add.text(x - 14, y - 8, node.label, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setAlpha(0.62);
  });
  g.fillStyle(theme.secondary, 0.1 + progress * 0.08);
  g.fillCircle(cx, cy, 46);
  g.lineStyle(2, theme.secondary, 0.28);
  g.strokeCircle(cx, cy, 62 + progress * 10);
  if (variant === 1) {
    ["osserva", "ipotesi", "verifica", "decidi"].forEach((label, index) => {
      const x = rect.x + 110 + index * 126;
      const y = rect.y + rect.height - 146 + (index % 2) * 26;
      g.lineStyle(1, theme.accent, 0.2);
      g.strokeRoundedRect(x, y, 96, 30, 8);
      scene.add.text(x + 12, y + 8, label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setAlpha(0.4);
    });
  } else if (variant === 2) {
    for (let index = 0; index < 8; index += 1) {
      const angle = (Math.PI * 2 * index) / 8;
      const x = cx + Math.cos(angle) * 230;
      const y = cy + Math.sin(angle) * 130;
      g.lineStyle(1, index % 2 ? theme.secondary : theme.accent, 0.18);
      g.strokeCircle(x, y, 12 + (index % 3) * 4);
      g.lineBetween(x, y, cx + Math.cos(angle) * 70, cy + Math.sin(angle) * 48);
    }
  }
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
