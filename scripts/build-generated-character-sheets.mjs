import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const outputRoot = path.resolve("artifacts/generated-character-art");
const groups = [
  {
    name: "itineranti",
    columns: 6,
    files: ["nima", "vera", "orsolo", "sesto", "cinabro", "lucilla"].map((id) => ({
      id,
      file: path.resolve(id === "sesto"
        ? "godot/assets/npcs/world03/sesto-v1.png"
        : `godot/assets/itinerants/${id}-v1.png`),
    })),
  },
  {
    name: "custodi",
    columns: 6,
    files: ["dog", "cat", "rabbit", "spark", "comet", "orbit", "satellite", "prisma", "luma", "guardiano", "codex"]
      .map((id) => ({ id, file: path.resolve(`godot/assets/custodi/${id}-v1.png`) })),
  },
  {
    name: "guardiani",
    columns: 6,
    files: Array.from({ length: 24 }, (_, index) => {
      const level = String(index + 1).padStart(2, "0");
      return { id: `livello ${level}`, file: path.resolve(`godot/assets/guardians/level${level}-v1.png`) };
    }),
  },
];

const cell = 220;
const labelHeight = 30;

function labelSvg(label) {
  const safe = label.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
  return Buffer.from(`<svg width="${cell}" height="${labelHeight}" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#07181d" fill-opacity="0.96"/>
    <text x="${cell / 2}" y="20" text-anchor="middle" fill="#e9fffa"
      font-family="Arial, sans-serif" font-size="14" font-weight="700">${safe}</text>
  </svg>`);
}

async function build(group) {
  const rows = Math.ceil(group.files.length / group.columns);
  const composites = [];
  for (let index = 0; index < group.files.length; index += 1) {
    const { id, file } = group.files[index];
    const left = (index % group.columns) * cell;
    const top = Math.floor(index / group.columns) * cell;
    const image = await sharp(file)
      .resize({ width: cell - 18, height: cell - labelHeight - 10, fit: "contain" })
      .png()
      .toBuffer();
    composites.push({ input: image, left: left + 9, top: top + 3 });
    composites.push({ input: labelSvg(id), left, top: top + cell - labelHeight });
  }
  const destination = path.join(outputRoot, `${group.name}-v1.png`);
  await sharp({
    create: {
      width: group.columns * cell,
      height: rows * cell,
      channels: 4,
      background: "#10272d",
    },
  }).composite(composites).png({ compressionLevel: 9 }).toFile(destination);
  console.log(`${group.name}: ${group.files.length} -> ${destination}`);
}

await fs.mkdir(outputRoot, { recursive: true });
for (const group of groups) await build(group);
