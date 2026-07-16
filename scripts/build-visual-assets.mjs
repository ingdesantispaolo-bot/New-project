import fs from "node:fs/promises";
import path from "node:path";

const spriteDir = path.resolve("src/assets/sprites");
const toolCacheDir = path.resolve("node_modules/.cache");
process.env.XDG_CACHE_HOME ??= toolCacheDir;
await fs.mkdir(spriteDir, { recursive: true });
await fs.mkdir(path.join(process.env.XDG_CACHE_HOME, "fontconfig"), { recursive: true });
const { default: sharp } = await import("sharp");

const atlasSize = 512;
const frames = [
  {
    name: "particle-diamond",
    x: 0,
    y: 0,
    w: 64,
    h: 64,
    svg: `<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
      <defs><radialGradient id="g" cx="50%" cy="45%" r="55%"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#9ff5e9"/><stop offset="1" stop-color="#6be7d6" stop-opacity="0"/></radialGradient></defs>
      <path d="M32 4 L60 32 L32 60 L4 32 Z" fill="url(#g)"/>
      <path d="M32 10 L54 32 L32 54 L10 32 Z" fill="none" stroke="#ffffff" stroke-opacity=".42" stroke-width="2"/>
    </svg>`,
  },
  {
    name: "soft-flare",
    x: 64,
    y: 0,
    w: 128,
    h: 128,
    svg: `<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
      <defs><radialGradient id="g" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#ffffff" stop-opacity=".95"/><stop offset=".26" stop-color="#6be7d6" stop-opacity=".45"/><stop offset="1" stop-color="#6be7d6" stop-opacity="0"/></radialGradient></defs>
      <circle cx="64" cy="64" r="64" fill="url(#g)"/>
      <path d="M64 4 V124 M4 64 H124" stroke="#ffffff" stroke-opacity=".25" stroke-width="2"/>
    </svg>`,
  },
  {
    name: "lens-streak",
    x: 192,
    y: 0,
    w: 256,
    h: 64,
    svg: `<svg width="256" height="64" viewBox="0 0 256 64" xmlns="http://www.w3.org/2000/svg">
      <defs><linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="#6be7d6" stop-opacity="0"/><stop offset=".48" stop-color="#ffffff" stop-opacity=".32"/><stop offset="1" stop-color="#f6c85f" stop-opacity="0"/></linearGradient></defs>
      <rect width="256" height="64" fill="url(#g)"/>
      <rect x="42" y="30" width="170" height="3" fill="#ffffff" opacity=".26"/>
    </svg>`,
  },
  {
    name: "circuit-node",
    x: 0,
    y: 128,
    w: 96,
    h: 96,
    svg: `<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
      <circle cx="48" cy="48" r="38" fill="#102936" fill-opacity=".68" stroke="#6be7d6" stroke-width="3"/>
      <circle cx="48" cy="48" r="18" fill="#6be7d6" fill-opacity=".18" stroke="#9ff5e9" stroke-width="3"/>
      <circle cx="48" cy="48" r="5" fill="#f6c85f"/>
    </svg>`,
  },
  {
    name: "ui-corner",
    x: 96,
    y: 128,
    w: 96,
    h: 96,
    svg: `<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 84 V18 C12 14.7 14.7 12 18 12 H84" fill="none" stroke="#6be7d6" stroke-width="5" stroke-linecap="square"/>
      <path d="M23 73 V26 C23 24.3 24.3 23 26 23 H73" fill="none" stroke="#ffffff" stroke-opacity=".22" stroke-width="2"/>
      <path d="M12 40 H42 M40 12 V42" stroke="#f6c85f" stroke-opacity=".5" stroke-width="4"/>
    </svg>`,
  },
  {
    name: "leaf-glyph",
    x: 192,
    y: 128,
    w: 96,
    h: 96,
    svg: `<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
      <path d="M76 16 C40 18 18 38 20 76 C58 76 78 52 76 16Z" fill="#70d68a" fill-opacity=".72" stroke="#c9f7c9" stroke-width="3"/>
      <path d="M26 70 C40 52 52 38 72 20" stroke="#ffffff" stroke-opacity=".55" stroke-width="3" fill="none"/>
    </svg>`,
  },
  {
    name: "gear-glyph",
    x: 288,
    y: 128,
    w: 96,
    h: 96,
    svg: `<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
      <path d="M48 8 L56 20 L70 18 L78 32 L68 42 L70 56 L56 60 L48 88 L40 60 L26 56 L28 42 L18 32 L26 18 L40 20 Z" fill="#f6c85f" fill-opacity=".62" stroke="#ffe0a3" stroke-width="3"/>
      <circle cx="48" cy="48" r="15" fill="#0b0f14" stroke="#ffffff" stroke-opacity=".48" stroke-width="3"/>
    </svg>`,
  },
  {
    name: "archive-glyph",
    x: 384,
    y: 128,
    w: 96,
    h: 96,
    svg: `<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
      <path d="M24 14 H60 L76 30 V82 H24 Z" fill="#9f8cff" fill-opacity=".58" stroke="#e3d9ff" stroke-width="3"/>
      <path d="M60 14 V30 H76 M34 44 H66 M34 56 H62 M34 68 H54" stroke="#ffffff" stroke-opacity=".62" stroke-width="3"/>
    </svg>`,
  },
  {
    name: "robot-core",
    x: 0,
    y: 224,
    w: 96,
    h: 96,
    svg: `<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
      <path d="M48 10 L78 28 V66 L48 86 L18 66 V28 Z" fill="#173b46" stroke="#6be7d6" stroke-width="4"/>
      <circle cx="38" cy="44" r="6" fill="#9ff5e9"/><circle cx="58" cy="44" r="6" fill="#9ff5e9"/>
      <path d="M35 62 H61" stroke="#f6c85f" stroke-width="4" stroke-linecap="round"/>
    </svg>`,
  },
];

const composites = frames.map((frame) => ({
  input: Buffer.from(frame.svg),
  left: frame.x,
  top: frame.y,
}));

const atlasPng = path.join(spriteDir, "eli-quest-atlas.png");
const atlasWebp = path.join(spriteDir, "eli-quest-atlas.webp");
const atlasJson = path.join(spriteDir, "eli-quest-atlas.json");

await sharp({
  create: {
    width: atlasSize,
    height: atlasSize,
    channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  },
})
  .composite(composites)
  .png()
  .toFile(atlasPng);

await sharp(atlasPng)
  .webp({ quality: 86, effort: 5, lossless: false })
  .toFile(atlasWebp);

const texturePackerAtlas = {
  frames: Object.fromEntries(frames.map((frame) => [
    frame.name,
    {
      frame: { x: frame.x, y: frame.y, w: frame.w, h: frame.h },
      rotated: false,
      trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w: frame.w, h: frame.h },
      sourceSize: { w: frame.w, h: frame.h },
    },
  ])),
  meta: {
    app: "Eli Quest generated asset pipeline",
    version: "1.0",
    image: "eli-quest-atlas.webp",
    format: "RGBA8888",
    size: { w: atlasSize, h: atlasSize },
    scale: "1",
  },
};

await fs.writeFile(atlasJson, `${JSON.stringify(texturePackerAtlas, null, 2)}\n`);

console.log(`Generated ${path.relative(process.cwd(), atlasWebp)} and TexturePacker-compatible JSON.`);

const missionConsoleSubjects = [
  { id: "math", label: "matematica", color: "#6be7d6", dark: "#092634", symbol: "math" },
  { id: "italian", label: "italiano", color: "#b888ff", dark: "#221943", symbol: "pen" },
  { id: "english", label: "inglese", color: "#7cc7ff", dark: "#112b48", symbol: "globe" },
  { id: "coding", label: "coding", color: "#78f29a", dark: "#10331f", symbol: "code" },
  { id: "electronics", label: "elettronica", color: "#f6c85f", dark: "#342814", symbol: "bolt" },
  { id: "music", label: "musica", color: "#ff9f4a", dark: "#351d10", symbol: "music" },
  { id: "physics", label: "fisica", color: "#9ff5e9", dark: "#102d3a", symbol: "atom" },
  { id: "latin", label: "latino", color: "#d8a24a", dark: "#2e2110", symbol: "glyph" },
  { id: "story", label: "storia", color: "#f7d37a", dark: "#302416", symbol: "archive" },
  { id: "nora", label: "nora", color: "#9ff5e9", dark: "#102935", symbol: "core" },
  { id: "progressive", label: "scalata", color: "#ff8f6b", dark: "#321814", symbol: "spire" },
  { id: "exit", label: "porta-uscita", color: "#f6c85f", dark: "#302612", symbol: "door" },
];

function missionConsoleSymbol(symbol, color, resolved) {
  const alpha = resolved ? ".78" : ".95";
  const soft = resolved ? ".18" : ".28";
  const common = {
    math: `<path d="M42 56 H78 M42 76 H78 M36 112 H84" stroke="${color}" stroke-opacity="${alpha}" stroke-width="8" stroke-linecap="round"/><path d="M58 42 V90 M62 102 L82 122 M82 102 L62 122" stroke="#f5fbff" stroke-opacity=".42" stroke-width="5" stroke-linecap="round"/>`,
    pen: `<path d="M42 112 L52 80 L88 44 L104 60 L68 96 Z" fill="${color}" fill-opacity="${soft}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><path d="M84 48 L100 64 M50 100 L68 118" stroke="#f5fbff" stroke-opacity=".36" stroke-width="4" stroke-linecap="round"/>`,
    globe: `<circle cx="64" cy="78" r="34" fill="${color}" fill-opacity="${soft}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><path d="M30 78 H98 M64 44 C52 60 52 96 64 112 M64 44 C76 60 76 96 64 112" fill="none" stroke="#f5fbff" stroke-opacity=".34" stroke-width="3"/>`,
    code: `<path d="M48 58 L30 78 L48 98 M80 58 L98 78 L80 98" fill="none" stroke="${color}" stroke-opacity="${alpha}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/><path d="M70 50 L58 106" stroke="#f5fbff" stroke-opacity=".34" stroke-width="5" stroke-linecap="round"/>`,
    bolt: `<path d="M70 36 L38 86 H62 L50 122 L88 68 H64 Z" fill="${color}" fill-opacity=".68" stroke="#ffe6a0" stroke-opacity=".58" stroke-width="3"/>`,
    music: `<path d="M78 42 V100 C78 112 67 120 56 116 C46 113 42 104 48 96 C54 88 66 88 74 94 V52 L104 46 V74" fill="none" stroke="${color}" stroke-opacity="${alpha}" stroke-width="7" stroke-linecap="round"/><path d="M28 72 H56 M28 88 H56" stroke="#f5fbff" stroke-opacity=".24" stroke-width="3"/>`,
    atom: `<circle cx="64" cy="78" r="7" fill="${color}" fill-opacity=".92"/><ellipse cx="64" cy="78" rx="38" ry="15" fill="none" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><ellipse cx="64" cy="78" rx="38" ry="15" fill="none" stroke="#f5fbff" stroke-opacity=".26" stroke-width="3" transform="rotate(60 64 78)"/><ellipse cx="64" cy="78" rx="38" ry="15" fill="none" stroke="#f5fbff" stroke-opacity=".26" stroke-width="3" transform="rotate(-60 64 78)"/>`,
    glyph: `<path d="M34 110 C42 86 42 66 34 44 M94 110 C86 86 86 66 94 44 M48 56 H80 M48 78 H80 M48 100 H80" fill="none" stroke="${color}" stroke-opacity="${alpha}" stroke-width="6" stroke-linecap="round"/><path d="M64 42 V116" stroke="#f5fbff" stroke-opacity=".22" stroke-width="4"/>`,
    archive: `<path d="M42 38 H76 L94 56 V118 H42 Z" fill="${color}" fill-opacity="${soft}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><path d="M76 38 V56 H94 M54 72 H82 M54 88 H78 M54 104 H72" stroke="#f5fbff" stroke-opacity=".34" stroke-width="4" stroke-linecap="round"/>`,
    core: `<path d="M64 36 L94 54 V92 L64 112 L34 92 V54 Z" fill="${color}" fill-opacity="${soft}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><circle cx="54" cy="74" r="5" fill="#f5fbff" opacity=".62"/><circle cx="74" cy="74" r="5" fill="#f5fbff" opacity=".62"/><path d="M54 92 H74" stroke="#f6c85f" stroke-opacity=".66" stroke-width="5" stroke-linecap="round"/>`,
    spire: `<path d="M36 116 L64 40 L92 116 Z" fill="${color}" fill-opacity="${soft}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><path d="M50 92 H78 M56 74 H72 M62 56 H66" stroke="#f5fbff" stroke-opacity=".36" stroke-width="4" stroke-linecap="round"/><circle cx="64" cy="40" r="8" fill="#f6c85f" opacity=".75"/>`,
    door: `<path d="M42 34 H88 V120 H42 Z" fill="${color}" fill-opacity="${soft}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="4"/><path d="M56 48 H76 V120 H56 Z" fill="#061019" opacity=".58"/><circle cx="78" cy="82" r="4" fill="#f5fbff" opacity=".62"/>`,
  };
  return common[symbol] ?? common.core;
}

function missionConsoleSvg(subject, state) {
  const resolved = state === "resolved";
  const color = subject.color;
  const dark = subject.dark;
  const label = subject.label.toUpperCase();
  return `<svg width="120" height="150" viewBox="0 0 120 150" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="panel" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${resolved ? "#14362a" : dark}" stop-opacity=".98"/>
        <stop offset=".62" stop-color="#071018" stop-opacity=".98"/>
        <stop offset="1" stop-color="#02070b"/>
      </linearGradient>
      <radialGradient id="glow" cx="50%" cy="34%" r="62%">
        <stop offset="0" stop-color="${color}" stop-opacity="${resolved ? ".34" : ".28"}"/>
        <stop offset=".58" stop-color="${color}" stop-opacity=".08"/>
        <stop offset="1" stop-color="${color}" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <ellipse cx="60" cy="140" rx="50" ry="9" fill="#000" opacity=".35"/>
    <rect x="8" y="5" width="104" height="135" rx="12" fill="url(#panel)" stroke="${resolved ? "#7cf6a6" : color}" stroke-opacity="${resolved ? ".88" : ".74"}" stroke-width="3"/>
    <rect x="14" y="14" width="92" height="104" rx="8" fill="url(#glow)" stroke="#ffffff" stroke-opacity=".08"/>
    <rect x="18" y="18" width="84" height="10" rx="5" fill="${resolved ? "#7cf6a6" : color}" opacity=".52"/>
    <rect x="22" y="122" width="76" height="3" rx="2" fill="#f5fbff" opacity=".18"/>
    ${missionConsoleSymbol(subject.symbol, color, resolved)}
    ${resolved ? `<circle cx="96" cy="26" r="10" fill="#7cf6a6" opacity=".94"/><path d="M91 26 L95 30 L102 21" fill="none" stroke="#061019" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>` : `<circle cx="96" cy="26" r="9" fill="${color}" opacity=".82"/><circle cx="96" cy="26" r="4" fill="#f5fbff" opacity=".55"/>`}
    <text x="60" y="136" text-anchor="middle" font-family="Inter,Arial,sans-serif" font-size="8" font-weight="700" fill="#d9eaf1" opacity=".9">${label}</text>
  </svg>`;
}

async function buildMissionConsoleAtlas() {
  const cell = { w: 120, h: 150 };
  const columns = missionConsoleSubjects.length;
  const states = ["active", "resolved"];
  const sheetWidth = columns * cell.w;
  const sheetHeight = states.length * cell.h;
  const composites = [];
  const frames = {};
  missionConsoleSubjects.forEach((subject, col) => {
    states.forEach((state, row) => {
      const name = `console_${subject.id}_${state}`;
      const x = col * cell.w;
      const y = row * cell.h;
      composites.push({ input: Buffer.from(missionConsoleSvg(subject, state)), left: x, top: y });
      frames[name] = {
        frame: { x, y, w: cell.w, h: cell.h },
        rotated: false,
        trimmed: false,
        spriteSourceSize: { x: 0, y: 0, w: cell.w, h: cell.h },
        sourceSize: { w: cell.w, h: cell.h },
      };
    });
  });
  const png = path.join(spriteDir, "mission-console-sheet.png");
  const json = path.join(spriteDir, "mission-console-sheet.json");
  await sharp({
    create: {
      width: sheetWidth,
      height: sheetHeight,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite(composites)
    .png()
    .toFile(png);
  await fs.writeFile(json, `${JSON.stringify({
    frames,
    meta: {
      app: "Eli Quest generated asset pipeline",
      version: "1.1",
      image: "mission-console-sheet.png",
      format: "RGBA8888",
      size: { w: sheetWidth, h: sheetHeight },
      scale: "1",
      cell,
      rows: { 0: "active", 1: "resolved" },
      subjects: Object.fromEntries(missionConsoleSubjects.map((subject) => [
        subject.id,
        { label: subject.label, color: subject.color, symbol: subject.symbol },
      ])),
      states,
      animations: Object.fromEntries(missionConsoleSubjects.map((subject) => [
        subject.id,
        [`console_${subject.id}_active`, `console_${subject.id}_resolved`],
      ])),
    },
  }, null, 2)}\n`);
  console.log(`Generated ${path.relative(process.cwd(), png)} and TexturePacker-compatible JSON.`);
}

await buildMissionConsoleAtlas();

const robotGridFrames = [
  {
    name: "grid-cell",
    w: 64,
    h: 64,
    svg: robotGridSvg("cell"),
  },
  {
    name: "grid-start",
    w: 64,
    h: 64,
    svg: robotGridSvg("start"),
  },
  {
    name: "grid-obstacle",
    w: 64,
    h: 64,
    svg: robotGridSvg("obstacle"),
  },
  {
    name: "grid-key",
    w: 64,
    h: 64,
    svg: robotGridSvg("key"),
  },
  {
    name: "grid-exit",
    w: 64,
    h: 64,
    svg: robotGridSvg("exit"),
  },
  {
    name: "grid-checkpoint",
    w: 64,
    h: 64,
    svg: robotGridSvg("checkpoint"),
  },
  {
    name: "grid-sensor",
    w: 64,
    h: 64,
    svg: robotGridSvg("sensor"),
  },
  {
    name: "grid-trail",
    w: 64,
    h: 64,
    svg: robotGridSvg("trail"),
  },
  {
    name: "grid-energy",
    w: 64,
    h: 64,
    svg: robotGridSvg("energy"),
  },
  {
    name: "grid-warning",
    w: 64,
    h: 64,
    svg: robotGridSvg("warning"),
  },
];

function robotGridSvg(kind) {
  const palette = {
    cell: "#132835",
    line: "#315766",
    cyan: "#6be7d6",
    glow: "#9ff5e9",
    gold: "#f6c85f",
    purple: "#8a7cff",
    red: "#c94b55",
    green: "#7cf6a6",
  };
  const motifs = {
    cell: `<rect x="8" y="8" width="48" height="48" rx="8" fill="${palette.cell}" stroke="${palette.line}" stroke-opacity=".8" stroke-width="2"/><path d="M17 18 H47 M17 46 H47" stroke="${palette.cyan}" stroke-opacity=".08" stroke-width="3"/>`,
    start: `<rect x="8" y="8" width="48" height="48" rx="8" fill="${palette.cell}" stroke="${palette.cyan}" stroke-opacity=".72" stroke-width="3"/><circle cx="32" cy="32" r="16" fill="${palette.cyan}" fill-opacity=".12" stroke="${palette.cyan}" stroke-opacity=".6" stroke-width="2"/><path d="M32 18 L43 42 L32 36 L21 42 Z" fill="${palette.cyan}" opacity=".72"/>`,
    obstacle: `<rect x="8" y="8" width="48" height="48" rx="8" fill="#4c2b38" stroke="${palette.red}" stroke-opacity=".82" stroke-width="2"/><path d="M18 18 L46 46 M46 18 L18 46" stroke="#ff8a8a" stroke-opacity=".52" stroke-width="5" stroke-linecap="round"/><circle cx="32" cy="32" r="18" fill="none" stroke="#fff" stroke-opacity=".08" stroke-width="2"/>`,
    key: `<rect x="8" y="8" width="48" height="48" rx="8" fill="${palette.cell}" stroke="${palette.gold}" stroke-opacity=".46" stroke-width="2"/><path d="M32 12 L38 25 L52 26 L41 36 L44 50 L32 43 L20 50 L23 36 L12 26 L26 25 Z" fill="${palette.gold}" stroke="#ffe6a0" stroke-opacity=".72" stroke-width="2"/>`,
    exit: `<rect x="8" y="8" width="48" height="48" rx="8" fill="#173b36" stroke="${palette.glow}" stroke-opacity=".82" stroke-width="3"/><rect x="20" y="16" width="24" height="34" rx="3" fill="${palette.glow}" fill-opacity=".25" stroke="#f5fbff" stroke-opacity=".42" stroke-width="2"/><circle cx="38" cy="33" r="2.5" fill="#f5fbff" opacity=".82"/>`,
    checkpoint: `<rect x="8" y="8" width="48" height="48" rx="8" fill="${palette.cell}" stroke="${palette.purple}" stroke-opacity=".72" stroke-width="2"/><circle cx="32" cy="32" r="18" fill="${palette.purple}" fill-opacity=".45" stroke="#f5fbff" stroke-opacity=".42" stroke-width="2"/><path d="M22 32 H42 M32 22 V42" stroke="#f5fbff" stroke-opacity=".62" stroke-width="4" stroke-linecap="round"/>`,
    sensor: `<rect x="8" y="8" width="48" height="48" rx="8" fill="#17243d" stroke="${palette.purple}" stroke-opacity=".74" stroke-width="2"/><circle cx="32" cy="32" r="9" fill="${palette.purple}" fill-opacity=".62"/><circle cx="32" cy="32" r="20" fill="none" stroke="${palette.purple}" stroke-opacity=".32" stroke-width="3"/><path d="M18 18 L25 25 M46 18 L39 25 M18 46 L25 39 M46 46 L39 39" stroke="#f5fbff" stroke-opacity=".24" stroke-width="3"/>`,
    trail: `<rect x="8" y="8" width="48" height="48" rx="8" fill="${palette.cell}" fill-opacity=".42" stroke="${palette.cyan}" stroke-opacity=".22" stroke-width="2"/><path d="M16 34 C26 24 38 44 48 28" fill="none" stroke="${palette.cyan}" stroke-opacity=".56" stroke-width="6" stroke-linecap="round"/><circle cx="21" cy="37" r="4" fill="${palette.glow}" opacity=".58"/>`,
    energy: `<rect x="8" y="8" width="48" height="48" rx="8" fill="#243015" stroke="${palette.green}" stroke-opacity=".58" stroke-width="2"/><path d="M35 12 L21 35 H32 L27 52 L45 27 H34 Z" fill="${palette.green}" stroke="#d8ffd7" stroke-opacity=".55" stroke-width="2"/>`,
    warning: `<rect x="8" y="8" width="48" height="48" rx="8" fill="#3b1f1e" stroke="${palette.red}" stroke-opacity=".74" stroke-width="2"/><path d="M32 14 L52 50 H12 Z" fill="${palette.red}" fill-opacity=".42" stroke="#ffb3a3" stroke-opacity=".64" stroke-width="2"/><path d="M32 26 V38" stroke="#f5fbff" stroke-opacity=".76" stroke-width="4" stroke-linecap="round"/><circle cx="32" cy="44" r="2.5" fill="#f5fbff" opacity=".78"/>`,
  };
  return `<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">${motifs[kind]}</svg>`;
}

async function buildRobotGridAtlas() {
  const columns = robotGridFrames.length;
  const sheetWidth = columns * 64;
  const sheetHeight = 64;
  const composites = [];
  const frames = {};
  robotGridFrames.forEach((frame, index) => {
    const x = index * 64;
    composites.push({ input: Buffer.from(frame.svg), left: x, top: 0 });
    frames[frame.name] = {
      frame: { x, y: 0, w: frame.w, h: frame.h },
      rotated: false,
      trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w: frame.w, h: frame.h },
      sourceSize: { w: frame.w, h: frame.h },
    };
  });
  const png = path.join(spriteDir, "robot-grid-sheet.png");
  const json = path.join(spriteDir, "robot-grid-sheet.json");
  await sharp({
    create: {
      width: sheetWidth,
      height: sheetHeight,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite(composites)
    .png()
    .toFile(png);
  await fs.writeFile(json, `${JSON.stringify({
    frames,
    meta: {
      app: "Eli Quest generated asset pipeline",
      version: "1.0",
      image: "robot-grid-sheet.png",
      format: "RGBA8888",
      size: { w: sheetWidth, h: sheetHeight },
      scale: "1",
      frames: robotGridFrames.map((frame) => frame.name),
    },
  }, null, 2)}\n`);
  console.log(`Generated ${path.relative(process.cwd(), png)} and TexturePacker-compatible JSON.`);
}

await buildRobotGridAtlas();

const logicGymFrames = [
  { name: "gym-tables", color: "#f6c85f", symbol: "tables" },
  { name: "gym-mental", color: "#5ec8ff", symbol: "mental" },
  { name: "gym-geo", color: "#70d68a", symbol: "geo" },
  { name: "gym-geo-physical", color: "#9f8cff", symbol: "physical" },
  { name: "gym-simon", color: "#6be7d6", symbol: "simon" },
  { name: "gym-memory", color: "#ff9ad2", symbol: "memory" },
  { name: "gym-code", color: "#f6c85f", symbol: "lock" },
  { name: "gym-seq", color: "#70d68a", symbol: "sequence" },
  { name: "gym-balance", color: "#f6c85f", symbol: "balance" },
  { name: "gym-flash", color: "#6be7d6", symbol: "flash" },
  { name: "gym-firewall", color: "#5ec8ff", symbol: "firewall" },
  { name: "geo-pin", color: "#70d68a", symbol: "pin" },
  { name: "geo-river", color: "#5ec8ff", symbol: "river" },
  { name: "geo-mountain", color: "#9f8cff", symbol: "mountain" },
  { name: "geo-lake", color: "#6be7d6", symbol: "lake" },
  { name: "geo-desert", color: "#f6c85f", symbol: "desert" },
];

function logicGymIconSvg(spec) {
  const color = spec.color;
  const motifs = {
    tables: `<text x="64" y="74" text-anchor="middle" font-family="Inter,Arial,sans-serif" font-size="34" font-weight="800" fill="${color}">×</text><text x="64" y="101" text-anchor="middle" font-family="Inter,Arial,sans-serif" font-size="21" font-weight="800" fill="#f5fbff" opacity=".82">12</text>`,
    mental: `<path d="M30 70 H98 M64 36 V104 M40 48 L88 96 M88 48 L40 96" stroke="${color}" stroke-opacity=".8" stroke-width="8" stroke-linecap="round"/><circle cx="64" cy="70" r="14" fill="#f5fbff" opacity=".16"/>`,
    geo: `<circle cx="64" cy="68" r="34" fill="${color}" fill-opacity=".16" stroke="${color}" stroke-opacity=".76" stroke-width="5"/><path d="M30 68 H98 M64 34 C50 52 50 84 64 102 M64 34 C78 52 78 84 64 102" fill="none" stroke="#f5fbff" stroke-opacity=".34" stroke-width="4"/><circle cx="78" cy="54" r="6" fill="#f6c85f" opacity=".9"/>`,
    physical: `<path d="M22 96 L48 48 L66 82 L82 58 L106 96 Z" fill="${color}" fill-opacity=".28" stroke="${color}" stroke-opacity=".82" stroke-width="5" stroke-linejoin="round"/><path d="M44 56 L53 70 L62 82" stroke="#f5fbff" stroke-opacity=".44" stroke-width="4"/>`,
    simon: `${[0, 1, 2, 3].map((i) => `<circle cx="${44 + (i % 2) * 40}" cy="${50 + Math.floor(i / 2) * 40}" r="17" fill="${i === 0 ? "#ff5d7a" : i === 1 ? "#6be7d6" : i === 2 ? "#f6c85f" : "#70d68a"}" opacity=".8"/>`).join("")}`,
    memory: `<rect x="30" y="42" width="42" height="56" rx="7" fill="${color}" fill-opacity=".22" stroke="${color}" stroke-width="4"/><rect x="56" y="32" width="42" height="56" rx="7" fill="#f5fbff" fill-opacity=".12" stroke="${color}" stroke-opacity=".68" stroke-width="4"/><path d="M48 70 H82" stroke="#f5fbff" stroke-opacity=".42" stroke-width="5"/>`,
    lock: `<rect x="34" y="60" width="60" height="44" rx="8" fill="${color}" fill-opacity=".24" stroke="${color}" stroke-width="5"/><path d="M46 60 V48 C46 28 82 28 82 48 V60" fill="none" stroke="#f5fbff" stroke-opacity=".46" stroke-width="7" stroke-linecap="round"/><circle cx="64" cy="82" r="5" fill="#f5fbff" opacity=".8"/>`,
    sequence: `<path d="M28 44 H56 L44 70 H76 L62 98 H102" fill="none" stroke="${color}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/><circle cx="28" cy="44" r="7" fill="#f5fbff" opacity=".8"/><circle cx="102" cy="98" r="7" fill="#f6c85f" opacity=".9"/>`,
    balance: `<path d="M64 34 V102 M34 52 H94 M44 52 L28 88 H60 Z M84 52 L68 88 H100 Z" fill="none" stroke="${color}" stroke-width="6" stroke-linejoin="round"/><path d="M48 106 H80" stroke="#f5fbff" stroke-opacity=".42" stroke-width="6" stroke-linecap="round"/>`,
    flash: `<path d="M72 24 L34 74 H62 L52 110 L94 58 H66 Z" fill="${color}" fill-opacity=".78" stroke="#f5fbff" stroke-opacity=".35" stroke-width="3"/>`,
    firewall: `<path d="M32 42 L64 28 L96 42 V70 C96 92 82 104 64 110 C46 104 32 92 32 70 Z" fill="${color}" fill-opacity=".18" stroke="${color}" stroke-width="5"/><path d="M44 66 H84 M44 82 H84 M56 50 V98 M72 50 V98" stroke="#f5fbff" stroke-opacity=".34" stroke-width="4"/>`,
    pin: `<path d="M64 24 C48 24 36 36 36 52 C36 76 64 106 64 106 C64 106 92 76 92 52 C92 36 80 24 64 24Z" fill="${color}" fill-opacity=".64" stroke="#f5fbff" stroke-opacity=".4" stroke-width="4"/><circle cx="64" cy="52" r="10" fill="#071018" opacity=".8"/>`,
    river: `<path d="M28 36 C48 28 50 52 70 44 S88 60 100 52 M22 74 C42 66 50 90 70 80 S92 92 108 82" fill="none" stroke="${color}" stroke-width="8" stroke-linecap="round"/><circle cx="42" cy="36" r="5" fill="#f5fbff" opacity=".48"/>`,
    mountain: `<path d="M18 100 L48 42 L68 76 L82 54 L110 100 Z" fill="${color}" fill-opacity=".38" stroke="${color}" stroke-width="5" stroke-linejoin="round"/><path d="M48 42 L56 58 L42 58 M82 54 L88 68 L76 68" fill="#f5fbff" opacity=".42"/>`,
    lake: `<ellipse cx="64" cy="76" rx="42" ry="22" fill="${color}" fill-opacity=".42" stroke="${color}" stroke-width="5"/><path d="M35 74 C48 64 78 86 94 72" fill="none" stroke="#f5fbff" stroke-opacity=".38" stroke-width="4" stroke-linecap="round"/>`,
    desert: `<path d="M20 82 C44 54 80 100 108 72 V108 H20 Z" fill="${color}" fill-opacity=".38" stroke="${color}" stroke-opacity=".7" stroke-width="4"/><circle cx="86" cy="38" r="13" fill="${color}" opacity=".62"/><path d="M30 96 H54 M72 96 H98" stroke="#f5fbff" stroke-opacity=".26" stroke-width="4" stroke-linecap="round"/>`,
  };
  return `<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="bg" cx="50%" cy="46%" r="55%">
        <stop offset="0" stop-color="${color}" stop-opacity=".18"/>
        <stop offset=".62" stop-color="#102736" stop-opacity=".82"/>
        <stop offset="1" stop-color="#061019" stop-opacity=".98"/>
      </radialGradient>
    </defs>
    <rect x="8" y="8" width="112" height="112" rx="22" fill="url(#bg)" stroke="${color}" stroke-opacity=".52" stroke-width="3"/>
    <path d="M26 18 H102 M26 110 H102" stroke="#f5fbff" stroke-opacity=".08" stroke-width="3" stroke-linecap="round"/>
    ${motifs[spec.symbol]}
  </svg>`;
}

async function buildLogicGymAtlas() {
  const cell = 128;
  const columns = 8;
  const rows = Math.ceil(logicGymFrames.length / columns);
  const sheetWidth = columns * cell;
  const sheetHeight = rows * cell;
  const composites = [];
  const frames = {};
  logicGymFrames.forEach((frame, index) => {
    const x = (index % columns) * cell;
    const y = Math.floor(index / columns) * cell;
    composites.push({ input: Buffer.from(logicGymIconSvg(frame)), left: x, top: y });
    frames[frame.name] = {
      frame: { x, y, w: cell, h: cell },
      rotated: false,
      trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w: cell, h: cell },
      sourceSize: { w: cell, h: cell },
    };
  });
  const png = path.join(spriteDir, "logic-gym-sheet.png");
  const json = path.join(spriteDir, "logic-gym-sheet.json");
  await sharp({
    create: {
      width: sheetWidth,
      height: sheetHeight,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite(composites)
    .png()
    .toFile(png);
  await fs.writeFile(json, `${JSON.stringify({
    frames,
    meta: {
      app: "Eli Quest generated asset pipeline",
      version: "1.0",
      image: "logic-gym-sheet.png",
      format: "RGBA8888",
      size: { w: sheetWidth, h: sheetHeight },
      scale: "1",
      frames: logicGymFrames.map((frame) => frame.name),
    },
  }, null, 2)}\n`);
  console.log(`Generated ${path.relative(process.cwd(), png)} and TexturePacker-compatible JSON.`);
}

await buildLogicGymAtlas();

const imageDir = path.resolve("src/assets/images");
await fs.mkdir(imageDir, { recursive: true });

const missionVariantSpecs = [
  {
    source: "mission-italian-bg.webp",
    output: "mission-italian-archive-bg.webp",
    tint: "#2d2458",
    accent: "#9f8cff",
    secondary: "#f7d37a",
    title: "ARCHIVIO",
    motif: "archive",
  },
  {
    source: "mission-italian-bg.webp",
    output: "mission-italian-library-bg.webp",
    tint: "#18334a",
    accent: "#9f8cff",
    secondary: "#d8c28a",
    title: "BIBLIOTECA",
    motif: "library",
  },
  {
    source: "mission-english-bg.webp",
    output: "mission-english-control-bg.webp",
    tint: "#12304d",
    accent: "#4c7dff",
    secondary: "#6be7d6",
    title: "CONTROL",
    motif: "control",
  },
  {
    source: "mission-english-bg.webp",
    output: "mission-english-radio-bg.webp",
    tint: "#102a44",
    accent: "#6be7d6",
    secondary: "#f7d37a",
    title: "RADIO",
    motif: "radio",
  },
  {
    source: "mission-math-bg.webp",
    output: "mission-math-factory-bg.webp",
    tint: "#342716",
    accent: "#f6c85f",
    secondary: "#ffb36b",
    title: "FACTORY",
    motif: "factory",
  },
  {
    source: "mission-math-bg.webp",
    output: "mission-math-grid-bg.webp",
    tint: "#102d42",
    accent: "#6be7d6",
    secondary: "#f6c85f",
    title: "GRID",
    motif: "grid",
  },
  {
    source: "mission-coding-bg.webp",
    output: "mission-coding-robot-bg.webp",
    tint: "#113625",
    accent: "#70d68a",
    secondary: "#f6c85f",
    title: "ROBOT",
    motif: "robot",
  },
  {
    source: "mission-coding-bg.webp",
    output: "mission-coding-terminal-bg.webp",
    tint: "#0f3140",
    accent: "#6be7d6",
    secondary: "#70d68a",
    title: "TERMINAL",
    motif: "terminal",
  },
  {
    source: "mission-electronics-bg.webp",
    output: "mission-electronics-bench-bg.webp",
    tint: "#122b32",
    accent: "#6be7d6",
    secondary: "#ffb36b",
    title: "BENCH",
    motif: "bench",
  },
  {
    source: "mission-electronics-bg.webp",
    output: "mission-electronics-power-bg.webp",
    tint: "#30251a",
    accent: "#ffb36b",
    secondary: "#6be7d6",
    title: "POWER",
    motif: "power",
  },
  {
    source: "mission-music-bg.webp",
    output: "mission-music-staff-bg.webp",
    tint: "#281d45",
    accent: "#f7d37a",
    secondary: "#9f8cff",
    title: "STAFF",
    motif: "staff",
  },
  {
    source: "mission-music-bg.webp",
    output: "mission-music-audio-bg.webp",
    tint: "#102f44",
    accent: "#6be7d6",
    secondary: "#f7d37a",
    title: "AUDIO",
    motif: "audio",
  },
];

function missionVariantOverlay(spec, width = 1280, height = 720) {
  const common = `
    <defs>
      <radialGradient id="glow" cx="50%" cy="46%" r="55%">
        <stop offset="0" stop-color="${spec.accent}" stop-opacity=".18"/>
        <stop offset=".55" stop-color="${spec.tint}" stop-opacity=".18"/>
        <stop offset="1" stop-color="#02080d" stop-opacity=".62"/>
      </radialGradient>
      <linearGradient id="scan" x1="0" x2="1">
        <stop offset="0" stop-color="${spec.accent}" stop-opacity="0"/>
        <stop offset=".5" stop-color="${spec.accent}" stop-opacity=".18"/>
        <stop offset="1" stop-color="${spec.accent}" stop-opacity="0"/>
      </linearGradient>
      <pattern id="microgrid" width="48" height="48" patternUnits="userSpaceOnUse">
        <path d="M48 0H0V48" fill="none" stroke="${spec.accent}" stroke-opacity=".055" stroke-width="1"/>
      </pattern>
      <filter id="soft"><feGaussianBlur stdDeviation="3"/></filter>
    </defs>
    <rect width="${width}" height="${height}" fill="${spec.tint}" opacity=".32"/>
    <rect width="${width}" height="${height}" fill="url(#glow)"/>
    <rect width="${width}" height="${height}" fill="url(#microgrid)" opacity=".65"/>
    <rect x="70" y="70" width="${width - 140}" height="${height - 140}" rx="28" fill="none" stroke="${spec.accent}" stroke-opacity=".18" stroke-width="3"/>
    <rect x="96" y="95" width="250" height="38" rx="10" fill="#061019" opacity=".48" stroke="${spec.accent}" stroke-opacity=".26"/>
    <rect x="118" y="108" width="92" height="7" rx="4" fill="#f5fbff" opacity=".22"/>
    <rect x="118" y="121" width="150" height="5" rx="3" fill="${spec.accent}" opacity=".2"/>
    <path d="M0 585 C220 530 360 645 610 592 S1020 540 1280 595" fill="none" stroke="url(#scan)" stroke-width="10" opacity=".55"/>
  `;

  const motifs = {
    archive: `
      ${[0, 1, 2, 3, 4].map((i) => `<rect x="${720 + i * 74}" y="${154 + (i % 2) * 34}" width="50" height="${128 + i * 8}" rx="5" fill="${i % 2 ? spec.accent : spec.secondary}" opacity=".16" stroke="#ffffff" stroke-opacity=".12"/>`).join("")}
      <path d="M760 430 H1070 M760 472 H1015 M760 514 H1102" stroke="${spec.secondary}" stroke-opacity=".24" stroke-width="6" stroke-linecap="round"/>
      <path d="M766 382 H1010 M766 414 H954 M766 446 H1040" stroke="${spec.accent}" stroke-opacity=".18" stroke-width="8" stroke-linecap="round"/>
    `,
    library: `
      ${[0, 1, 2].map((row) => `<path d="M160 ${235 + row * 95} H1090" stroke="${spec.secondary}" stroke-opacity=".16" stroke-width="10"/>`).join("")}
      ${Array.from({ length: 18 }, (_, i) => `<rect x="${205 + i * 48}" y="${172 + (i % 3) * 88}" width="${20 + (i % 4) * 6}" height="${68 + (i % 5) * 8}" rx="4" fill="${i % 2 ? spec.accent : spec.secondary}" opacity=".14"/>`).join("")}
      <circle cx="965" cy="486" r="64" fill="none" stroke="${spec.accent}" stroke-opacity=".22" stroke-width="5"/>
      <path d="M930 486 H1000 M965 451 V521" stroke="${spec.accent}" stroke-opacity=".2" stroke-width="5"/>
    `,
    control: `
      <rect x="660" y="170" width="390" height="250" rx="18" fill="#061019" opacity=".44" stroke="${spec.accent}" stroke-opacity=".25" stroke-width="3"/>
      ${[0, 1, 2, 3, 4].map((i) => `<rect x="700" y="${205 + i * 38}" width="${170 + i * 28}" height="14" rx="7" fill="${i % 2 ? spec.accent : spec.secondary}" opacity=".22"/>`).join("")}
      ${[0, 1, 2].map((i) => `<circle cx="${770 + i * 95}" cy="365" r="24" fill="none" stroke="${i % 2 ? spec.secondary : spec.accent}" stroke-opacity=".22" stroke-width="5"/>`).join("")}
      <path d="M178 462 H352 M390 462 H575 M615 462 H760" stroke="${spec.accent}" stroke-opacity=".18" stroke-width="16" stroke-linecap="round"/>
    `,
    radio: `
      ${[0, 1, 2, 3, 4].map((i) => `<circle cx="905" cy="330" r="${58 + i * 48}" fill="none" stroke="${i % 2 ? spec.secondary : spec.accent}" stroke-opacity=".10" stroke-width="6"/>`).join("")}
      <path d="M250 495 C330 420 390 560 470 488 S610 428 690 496" fill="none" stroke="${spec.accent}" stroke-opacity=".28" stroke-width="8"/>
      <path d="M870 330 L715 520" stroke="${spec.secondary}" stroke-opacity=".28" stroke-width="8" stroke-linecap="round"/>
      <path d="M184 218 H360 M392 218 H590" stroke="${spec.secondary}" stroke-opacity=".22" stroke-width="14" stroke-linecap="round"/>
    `,
    factory: `
      <path d="M145 510 H1110" stroke="${spec.secondary}" stroke-opacity=".22" stroke-width="18"/>
      ${[0, 1, 2, 3].map((i) => `<rect x="${250 + i * 170}" y="${250 + (i % 2) * 45}" width="112" height="92" rx="14" fill="${i % 2 ? spec.accent : spec.secondary}" opacity=".12" stroke="#fff" stroke-opacity=".12"/>`).join("")}
      ${[0, 1, 2, 3].map((i) => `<circle cx="${306 + i * 170}" cy="${294 + (i % 2) * 45}" r="13" fill="#f5fbff" opacity=".2"/><path d="M${286 + i * 170} ${294 + (i % 2) * 45} H${326 + i * 170}" stroke="#f5fbff" stroke-opacity=".24" stroke-width="7" stroke-linecap="round"/>`).join("")}
      <circle cx="1010" cy="505" r="44" fill="none" stroke="${spec.accent}" stroke-opacity=".22" stroke-width="8"/>
    `,
    grid: `
      ${Array.from({ length: 12 }, (_, i) => `<path d="M${180 + i * 70} 135 V570" stroke="${spec.accent}" stroke-opacity=".085" stroke-width="2"/>`).join("")}
      ${Array.from({ length: 7 }, (_, i) => `<path d="M145 ${170 + i * 58} H1115" stroke="${spec.accent}" stroke-opacity=".085" stroke-width="2"/>`).join("")}
      <path d="M190 505 C330 420 422 205 560 270 S710 560 890 380 S1030 250 1115 300" fill="none" stroke="${spec.secondary}" stroke-opacity=".28" stroke-width="7"/>
      <path d="M770 186 H1045 M790 218 H982" stroke="${spec.secondary}" stroke-opacity=".22" stroke-width="9" stroke-linecap="round"/>
    `,
    robot: `
      <path d="M565 185 L680 250 V382 L565 455 L450 382 V250 Z" fill="${spec.accent}" opacity=".12" stroke="${spec.accent}" stroke-opacity=".3" stroke-width="6"/>
      <circle cx="525" cy="310" r="16" fill="${spec.secondary}" opacity=".35"/><circle cx="605" cy="310" r="16" fill="${spec.secondary}" opacity=".35"/>
      <path d="M515 370 H615" stroke="#f5fbff" stroke-opacity=".28" stroke-width="8" stroke-linecap="round"/>
      ${Array.from({ length: 6 }, (_, i) => `<rect x="${760 + i * 45}" y="${218 + (i % 2) * 50}" width="34" height="34" rx="6" fill="${i % 2 ? spec.secondary : spec.accent}" opacity=".16"/>`).join("")}
    `,
    terminal: `
      <rect x="700" y="150" width="400" height="315" rx="18" fill="#031016" opacity=".5" stroke="${spec.accent}" stroke-opacity=".28" stroke-width="3"/>
      ${[0, 1, 2, 3, 4].map((i) => `<rect x="${735 + (i % 2) * 30}" y="${190 + i * 43}" width="${210 - (i % 3) * 34}" height="13" rx="7" fill="${i % 2 ? spec.secondary : spec.accent}" opacity=".24"/>`).join("")}
      <path d="M250 520 H575 M575 520 V365 M575 365 H650" stroke="${spec.secondary}" stroke-opacity=".22" stroke-width="9" stroke-linecap="round"/>
    `,
    bench: `
      <rect x="210" y="190" width="750" height="300" rx="22" fill="#07181d" opacity=".36" stroke="${spec.accent}" stroke-opacity=".24" stroke-width="4"/>
      ${[0, 1, 2, 3, 4].map((i) => `<path d="M${270 + i * 135} 260 H${350 + i * 135} V${360 + (i % 2) * 45} H${430 + i * 88}" fill="none" stroke="${i % 2 ? spec.secondary : spec.accent}" stroke-opacity=".24" stroke-width="7" stroke-linecap="round"/>`).join("")}
      ${[0, 1, 2, 3].map((i) => `<circle cx="${335 + i * 155}" cy="${405 - (i % 2) * 85}" r="22" fill="${i % 2 ? spec.secondary : spec.accent}" opacity=".24"/>`).join("")}
    `,
    power: `
      <circle cx="770" cy="330" r="110" fill="none" stroke="${spec.secondary}" stroke-opacity=".26" stroke-width="9"/>
      <circle cx="770" cy="330" r="58" fill="${spec.secondary}" opacity=".12" stroke="${spec.accent}" stroke-opacity=".25" stroke-width="6"/>
      <path d="M770 165 V238 M770 422 V506 M605 330 H678 M862 330 H940" stroke="${spec.accent}" stroke-opacity=".3" stroke-width="8" stroke-linecap="round"/>
      <path d="M275 510 C390 370 488 548 620 430" fill="none" stroke="${spec.secondary}" stroke-opacity=".22" stroke-width="9"/>
      <path d="M744 314 L770 362 L796 314" fill="none" stroke="#f5fbff" stroke-opacity=".26" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
    `,
    staff: `
      ${[0, 1, 2, 3, 4].map((i) => `<path d="M160 ${225 + i * 32} H1115" stroke="${spec.secondary}" stroke-opacity=".18" stroke-width="5"/>`).join("")}
      ${[0, 1, 2, 3, 4, 5].map((i) => `<circle cx="${300 + i * 115}" cy="${257 + (i % 5) * 16}" r="18" fill="${i % 2 ? spec.accent : spec.secondary}" opacity=".26"/><path d="M${318 + i * 115} ${257 + (i % 5) * 16} V${175 + (i % 3) * 20}" stroke="${i % 2 ? spec.accent : spec.secondary}" stroke-opacity=".22" stroke-width="5"/>`).join("")}
      <path d="M190 485 H275 M315 485 H402 M442 485 H525 M565 485 H654 M694 485 H790" stroke="${spec.accent}" stroke-opacity=".16" stroke-width="12" stroke-linecap="round"/>
    `,
    audio: `
      ${[0, 1, 2, 3].map((i) => `<circle cx="870" cy="320" r="${50 + i * 48}" fill="none" stroke="${i % 2 ? spec.secondary : spec.accent}" stroke-opacity=".12" stroke-width="7"/>`).join("")}
      <path d="M170 450 C220 360 270 540 320 450 S420 360 470 450 S570 540 620 450 S720 360 770 450" fill="none" stroke="${spec.accent}" stroke-opacity=".3" stroke-width="9"/>
      ${Array.from({ length: 16 }, (_, i) => `<rect x="${185 + i * 42}" y="${535 - ((i * 37) % 112)}" width="22" height="${42 + ((i * 29) % 96)}" rx="8" fill="${i % 2 ? spec.secondary : spec.accent}" opacity=".16"/>`).join("")}
    `,
  };

  return `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">${common}${motifs[spec.motif] ?? ""}</svg>`;
}

for (const spec of missionVariantSpecs) {
  const source = path.join(imageDir, spec.source);
  const output = path.join(imageDir, spec.output);
  const overlay = Buffer.from(missionVariantOverlay(spec));
  await sharp(source)
    .resize(1280, 720, { fit: "cover", position: "center" })
    .modulate({ brightness: 0.92, saturation: 0.95 })
    .composite([{ input: overlay, blend: "over" }])
    .webp({ quality: 76, effort: 5 })
    .toFile(output);

  const outputSize = Math.round((await fs.stat(output)).size / 1024);
  console.log(`Generated ${path.relative(process.cwd(), output)} (${outputSize} KB).`);
}
