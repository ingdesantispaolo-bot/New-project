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
