import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const spriteDir = path.resolve("src/assets/sprites");
await fs.mkdir(spriteDir, { recursive: true });

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
