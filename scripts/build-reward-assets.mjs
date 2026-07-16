import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const root = process.cwd();
const catalogPath = path.join(root, "src/core/RewardCatalog.ts");
const imageDir = path.join(root, "src/assets/images");
const spriteDir = path.join(root, "src/assets/sprites");
const audioDir = path.join(root, "src/assets/audio/generated");

const catalogText = fs.readFileSync(catalogPath, "utf8");

function parseCatalog(text) {
  return [...text.matchAll(/\{ id: "([^"]+)", slot: "([^"]+)", name: "([^"]+)", description: "([^"]+)", cost: (\d+)([^}]*)\}/g)]
    .map((match) => {
      const tail = match[6];
      const color = tail.match(/color: (0x[0-9a-fA-F]+)/)?.[1];
      const glyph = tail.match(/glyph: "([^"]+)"/)?.[1];
      const minLevel = tail.match(/minLevel: (\d+)/)?.[1];
      return {
        id: match[1],
        slot: match[2],
        name: match[3],
        cost: Number(match[5]),
        color: color ? Number(color) : undefined,
        glyph,
        minLevel: minLevel ? Number(minLevel) : undefined,
      };
    });
}

function hex(color, fallback = "#6be7d6") {
  if (typeof color !== "number") return fallback;
  return `#${color.toString(16).padStart(6, "0")}`;
}

function slotAccent(item) {
  const accents = {
    bot: "#6be7d6",
    avatar: "#74f0c5",
    accessory: "#f6c85f",
    pet: "#9ff5e9",
    emblem: "#ffd75e",
    upgrade: "#9f8cff",
    decor: "#7ad7ff",
  };
  return hex(item.color, accents[item.slot] ?? "#6be7d6");
}

function iconBody(item, accent) {
  const glyph = item.glyph ?? "";
  const commonGlyph = `<text x="64" y="78" text-anchor="middle" font-family="Arial, sans-serif" font-size="${glyph.length > 1 ? 28 : 36}" font-weight="700" fill="#f8fbff">${escapeXml(glyph)}</text>`;
  if (item.slot === "bot") {
    return `
      <rect x="39" y="34" width="50" height="52" rx="16" fill="#0b2732" stroke="${accent}" stroke-width="4"/>
      <rect x="47" y="48" width="34" height="16" rx="8" fill="#041018" stroke="#d9ffff" stroke-opacity=".35"/>
      <circle cx="57" cy="56" r="4" fill="${accent}"/><circle cx="71" cy="56" r="4" fill="${accent}"/>
      <path d="M50 77 Q64 89 78 77" fill="none" stroke="#f6c85f" stroke-width="3" stroke-linecap="round"/>
      <circle cx="64" cy="28" r="7" fill="${accent}" opacity=".95"/>`;
  }
  if (item.slot === "avatar") {
    return `
      <path d="M44 44 Q64 28 84 44 L92 88 Q64 101 36 88 Z" fill="#123544" stroke="${accent}" stroke-width="4"/>
      <path d="M54 43 L64 62 L74 43" fill="none" stroke="#f6c85f" stroke-width="4" stroke-linecap="round"/>
      <circle cx="64" cy="34" r="13" fill="#09202b" stroke="${accent}" stroke-width="4"/>
      <rect x="56" y="31" width="22" height="9" rx="5" fill="#d9ffff" opacity=".75"/>`;
  }
  if (item.slot === "accessory") {
    return `
      <path d="M35 65 Q64 31 93 65 Q78 92 50 92 Q39 82 35 65Z" fill="#102631" stroke="${accent}" stroke-width="4"/>
      <circle cx="64" cy="64" r="20" fill="#05131b" stroke="#f6c85f" stroke-opacity=".65" stroke-width="3"/>
      ${commonGlyph}`;
  }
  if (item.slot === "pet") {
    return `
      <circle cx="64" cy="64" r="35" fill="${accent}" opacity=".12"/>
      <circle cx="64" cy="64" r="24" fill="#07151d" stroke="${accent}" stroke-width="4"/>
      <circle cx="77" cy="50" r="7" fill="#ffffff" opacity=".55"/>
      <path d="M34 61 C43 42 52 33 64 29 C76 33 85 42 94 61" fill="none" stroke="${accent}" stroke-width="3" stroke-linecap="round" opacity=".75"/>
      ${commonGlyph}`;
  }
  if (item.slot === "emblem") {
    return `
      <circle cx="64" cy="62" r="33" fill="#221b0b" stroke="${accent}" stroke-width="5"/>
      <circle cx="64" cy="62" r="22" fill="#0b1821" stroke="#f6c85f" stroke-width="2" opacity=".95"/>
      <path d="M45 94 L54 76 L64 84 L74 76 L83 94" fill="#34260e" stroke="${accent}" stroke-width="3"/>
      ${commonGlyph}`;
  }
  if (item.slot === "upgrade") {
    return `
      <path d="M64 24 L96 64 L64 104 L32 64 Z" fill="#15112d" stroke="${accent}" stroke-width="4"/>
      <circle cx="64" cy="64" r="19" fill="#07151d" stroke="#f6c85f" stroke-width="3"/>
      <path d="M64 36 L72 56 L92 64 L72 72 L64 92 L56 72 L36 64 L56 56 Z" fill="${accent}" opacity=".42"/>
      ${commonGlyph}`;
  }
  return `
    <rect x="34" y="38" width="60" height="54" rx="10" fill="#0d202a" stroke="${accent}" stroke-width="4"/>
    <path d="M42 76 H86 M46 58 H82 M54 42 V92 M74 42 V92" stroke="#f6c85f" stroke-width="3" opacity=".75"/>
    ${commonGlyph}`;
}

function iconSvg(item) {
  const accent = slotAccent(item);
  const level = item.minLevel ? `<text x="104" y="115" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#f6c85f">L${item.minLevel}</text>` : "";
  const rare = item.cost >= 1500 ? `<path d="M24 24 L35 20 L31 31 Z M102 28 L111 35 L99 39 Z" fill="#f6c85f" opacity=".9"/>` : "";
  return `
    <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
      <defs>
        <radialGradient id="bg" cx="50%" cy="38%" r="72%">
          <stop offset="0%" stop-color="${accent}" stop-opacity=".28"/>
          <stop offset="62%" stop-color="#0b2430" stop-opacity=".98"/>
          <stop offset="100%" stop-color="#041017"/>
        </radialGradient>
        <filter id="glow" x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="2.4" result="blur"/>
          <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
      </defs>
      <rect x="6" y="6" width="116" height="116" rx="18" fill="url(#bg)" stroke="${accent}" stroke-width="3"/>
      <path d="M20 28 C42 13 86 13 108 28" stroke="#ffffff" stroke-opacity=".13" stroke-width="6" fill="none" stroke-linecap="round"/>
      <g filter="url(#glow)">${iconBody(item, accent)}</g>
      ${rare}
      ${level}
    </svg>`;
}

function escapeXml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

async function buildImages(items) {
  const bgSource = path.join(imageDir, "reward-shop-bg-source.png");
  const bgOut = path.join(imageDir, "reward-shop-bg.webp");
  if (fs.existsSync(bgSource)) {
    await sharp(bgSource)
      .resize(1600, 900, { fit: "cover", position: "center" })
      .webp({ quality: 78, effort: 6 })
      .toFile(bgOut);
  }

  const cell = 128;
  const cols = 8;
  const rows = Math.ceil(items.length / cols);
  const sheetW = cols * cell;
  const sheetH = rows * cell;
  const composites = [];
  const frames = {};

  for (const [index, item] of items.entries()) {
    const x = (index % cols) * cell;
    const y = Math.floor(index / cols) * cell;
    const input = await sharp(Buffer.from(iconSvg(item))).png().toBuffer();
    composites.push({ input, left: x, top: y });
    frames[item.id] = {
      frame: { x, y, w: cell, h: cell },
      rotated: false,
      trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w: cell, h: cell },
      sourceSize: { w: cell, h: cell },
    };
  }

  await sharp({
    create: {
      width: sheetW,
      height: sheetH,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite(composites)
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(path.join(spriteDir, "reward-items-sheet.png"));

  fs.writeFileSync(
    path.join(spriteDir, "reward-items-sheet.json"),
    `${JSON.stringify({
      frames,
      meta: {
        app: "scripts/build-reward-assets.mjs",
        image: "reward-items-sheet.png",
        format: "RGBA8888",
        size: { w: sheetW, h: sheetH },
        scale: "1",
      },
    }, null, 2)}\n`,
  );
}

function writeWav(name, notes, volume = 0.35) {
  const sampleRate = 44100;
  const samples = [];
  const pushTone = ({ freq, ms, type = "sine" }) => {
    const total = Math.floor(sampleRate * ms / 1000);
    for (let i = 0; i < total; i += 1) {
      const t = i / sampleRate;
      const a = Math.min(1, i / (sampleRate * 0.012)) * Math.max(0, 1 - i / total);
      const wave = type === "tri"
        ? 2 * Math.abs(2 * ((freq * t) % 1) - 1) - 1
        : Math.sin(2 * Math.PI * freq * t);
      samples.push(Math.round(wave * a * volume * 32767));
    }
  };
  notes.forEach((note) => {
    if (note.freq <= 0) {
      const total = Math.floor(sampleRate * note.ms / 1000);
      for (let i = 0; i < total; i += 1) samples.push(0);
    } else {
      pushTone(note);
    }
  });
  const dataSize = samples.length * 2;
  const buffer = Buffer.alloc(44 + dataSize);
  buffer.write("RIFF", 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write("WAVEfmt ", 8);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write("data", 36);
  buffer.writeUInt32LE(dataSize, 40);
  samples.forEach((sample, index) => buffer.writeInt16LE(sample, 44 + index * 2));
  fs.writeFileSync(path.join(audioDir, `${name}.wav`), buffer);
}

function buildAudio() {
  writeWav("shopOpen", [
    { freq: 392, ms: 70, type: "tri" },
    { freq: 0, ms: 18 },
    { freq: 523.25, ms: 90, type: "tri" },
    { freq: 783.99, ms: 130 },
  ], 0.26);
  writeWav("shopPurchase", [
    { freq: 659.25, ms: 55, type: "tri" },
    { freq: 880, ms: 75, type: "tri" },
    { freq: 1174.66, ms: 140 },
  ], 0.34);
  writeWav("shopEquip", [
    { freq: 440, ms: 55, type: "tri" },
    { freq: 587.33, ms: 90 },
  ], 0.28);
  writeWav("shopLocked", [
    { freq: 196, ms: 90, type: "tri" },
    { freq: 164.81, ms: 120, type: "tri" },
  ], 0.25);
  writeWav("petEquip", [
    { freq: 783.99, ms: 60 },
    { freq: 987.77, ms: 70 },
    { freq: 1318.51, ms: 150 },
  ], 0.24);
}

const items = parseCatalog(catalogText);
if (items.length === 0) {
  throw new Error("Reward catalog parsing returned no items.");
}

await buildImages(items);
buildAudio();
console.log(`Generated reward shop bg, ${items.length} item icons and shop SFX.`);
