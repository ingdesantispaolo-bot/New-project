import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const outputDir = path.resolve("src/assets/painted/props");

const sheets = [
  {
    sourcePath: path.resolve("src/assets/painted/lab-prop-sheet-source.png"),
    cols: 4,
    rows: 2,
    props: [
      { name: "painted-door-lab", col: 0, row: 0 },
      { name: "painted-circuit-panel", col: 1, row: 0 },
      { name: "painted-terminal", col: 2, row: 0 },
      { name: "painted-robot-dock", col: 3, row: 0 },
      { name: "painted-message-console", col: 0, row: 1 },
      { name: "painted-workbench", col: 1, row: 1 },
      { name: "painted-journal", col: 2, row: 1 },
      { name: "painted-nora-core", col: 3, row: 1 },
    ],
  },
  {
    sourcePath: path.resolve("src/assets/painted/mission-prop-sheet-source.png"),
    cols: 3,
    rows: 3,
    props: [
      { name: "painted-greenhouse-pod", col: 0, row: 0 },
      { name: "painted-greenhouse-sensor", col: 1, row: 0 },
      { name: "painted-greenhouse-valve", col: 2, row: 0 },
      { name: "painted-factory-machine", col: 0, row: 1 },
      { name: "painted-factory-conveyor", col: 1, row: 1 },
      { name: "painted-factory-core", col: 2, row: 1 },
      { name: "painted-archive-shelf", col: 0, row: 2 },
      { name: "painted-archive-terminal", col: 1, row: 2 },
      { name: "painted-archive-desk", col: 2, row: 2 },
    ],
  },
];

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

function removeMagentaKey(buffer) {
  for (let i = 0; i < buffer.length; i += 4) {
    const r = buffer[i];
    const g = buffer[i + 1];
    const b = buffer[i + 2];
    const magentaScore = Math.min(r, b) - g;
    const chromaEdge = r > 70 && b > 70 && g < 125 && r > g * 1.35 && b > g * 1.35 && Math.abs(r - b) < 110;
    const chromaCore = r > 145 && b > 145 && magentaScore > 55;
    if (chromaCore || chromaEdge) {
      const edge = Math.max(0.75, Math.min(1, (magentaScore - 40) / 92));
      buffer[i + 3] = Math.round(buffer[i + 3] * (1 - edge));
      buffer[i] = Math.round(r * (1 - edge));
      buffer[i + 1] = Math.round(g * (1 - edge));
      buffer[i + 2] = Math.round(b * (1 - edge));
    }
  }
  return buffer;
}

async function processCell(sourcePath, metadata, prop, cellWidth, cellHeight) {
  const left = prop.col * cellWidth;
  const top = prop.row * cellHeight;
  const width = prop.lastCol ? metadata.width - left : cellWidth;
  const height = prop.lastRow ? metadata.height - top : cellHeight;
  const extracted = await sharp(sourcePath)
    .extract({ left, top, width, height })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const keyed = removeMagentaKey(Buffer.from(extracted.data));
  const image = sharp(keyed, { raw: extracted.info })
    .trim({ background: { r: 0, g: 0, b: 0, alpha: 0 }, threshold: 8 })
    .resize({ width: 520, height: 520, fit: "inside", withoutEnlargement: true });

  await image.png({ compressionLevel: 9 }).toFile(path.join(outputDir, `${prop.name}.png`));
  await image.webp({ quality: 88, alphaQuality: 88, effort: 6 }).toFile(path.join(outputDir, `${prop.name}.webp`));
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  let processed = 0;
  for (const sheet of sheets) {
    if (!(await exists(sheet.sourcePath))) {
      console.log(`Painted prop source not found, skipped: ${sheet.sourcePath}`);
      continue;
    }

    const metadata = await sharp(sheet.sourcePath).metadata();
    if (!metadata.width || !metadata.height) {
      throw new Error(`Invalid painted prop sheet: ${sheet.sourcePath}`);
    }

    const cellWidth = Math.floor(metadata.width / sheet.cols);
    const cellHeight = Math.floor(metadata.height / sheet.rows);
    const props = sheet.props.map((prop) => ({
      ...prop,
      lastCol: prop.col === sheet.cols - 1,
      lastRow: prop.row === sheet.rows - 1,
    }));
    await Promise.all(props.map((prop) => processCell(sheet.sourcePath, metadata, prop, cellWidth, cellHeight)));
    processed += props.length;
  }
  console.log(`Processed ${processed} painted props in ${outputDir}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
