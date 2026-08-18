import path from "node:path";
import sharp from "sharp";

const [inputArg, outputArg] = process.argv.slice(2);

if (!inputArg || !outputArg) {
  console.error("Usage: node scripts/process-chroma-character.mjs <input.png> <output.png>");
  process.exit(2);
}

const inputPath = path.resolve(inputArg);
const outputPath = path.resolve(outputArg);
const targetSize = 384;
const subjectSize = 352;

function smoothstep(edge0, edge1, value) {
  const ratio = Math.max(0, Math.min(1, (value - edge0) / (edge1 - edge0)));
  return ratio * ratio * (3 - 2 * ratio);
}

function removeBorderKey(data, width, height) {
  const samplePoints = [
    [0, 0],
    [width - 1, 0],
    [0, height - 1],
    [width - 1, height - 1],
    [Math.floor(width / 2), 0],
    [Math.floor(width / 2), height - 1],
  ];
  const key = samplePoints.reduce(
    (sum, [x, y]) => {
      const offset = (y * width + x) * 4;
      sum.r += data[offset];
      sum.g += data[offset + 1];
      sum.b += data[offset + 2];
      return sum;
    },
    { r: 0, g: 0, b: 0 },
  );
  key.r = Math.round(key.r / samplePoints.length);
  key.g = Math.round(key.g / samplePoints.length);
  key.b = Math.round(key.b / samplePoints.length);
  const magentaKey = Math.min(key.r, key.b) - key.g > 80;
  const greenKey = key.g - Math.max(key.r, key.b) > 80;

  let transparentPixels = 0;
  let visiblePixels = 0;
  for (let offset = 0; offset < data.length; offset += 4) {
    const dr = data[offset] - key.r;
    const dg = data[offset + 1] - key.g;
    const db = data[offset + 2] - key.b;
    const distance = Math.sqrt(dr * dr + dg * dg + db * db);
    const distanceMatte = smoothstep(18, 165, distance);
    const chromaScore = magentaKey
      ? Math.min(data[offset], data[offset + 2]) - data[offset + 1]
      : greenKey
        ? data[offset + 1] - Math.max(data[offset], data[offset + 2])
        : 0;
    const chromaMatte = magentaKey || greenKey ? 1 - smoothstep(28, 105, chromaScore) : 1;
    const matte = Math.min(distanceMatte, chromaMatte);
    const originalAlpha = data[offset + 3] / 255;
    const alpha = originalAlpha * matte;

    if (alpha > 0.015 && alpha < 0.995) {
      data[offset] = Math.max(0, Math.min(255, Math.round((data[offset] - key.r * (1 - matte)) / matte)));
      data[offset + 1] = Math.max(0, Math.min(255, Math.round((data[offset + 1] - key.g * (1 - matte)) / matte)));
      data[offset + 2] = Math.max(0, Math.min(255, Math.round((data[offset + 2] - key.b * (1 - matte)) / matte)));
    }
    data[offset + 3] = Math.round(alpha * 255);
    if (data[offset + 3] < 4) {
      data[offset] = 0;
      data[offset + 1] = 0;
      data[offset + 2] = 0;
      data[offset + 3] = 0;
    }
    if (data[offset + 3] === 0) transparentPixels += 1;
    if (data[offset + 3] >= 128) visiblePixels += 1;
  }

  return { key, transparentPixels, visiblePixels };
}

async function main() {
  const extracted = await sharp(inputPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const keyed = Buffer.from(extracted.data);
  const stats = removeBorderKey(keyed, extracted.info.width, extracted.info.height);

  const trimmed = await sharp(keyed, { raw: extracted.info })
    .trim({ background: { r: 0, g: 0, b: 0, alpha: 0 }, threshold: 4 })
    .resize({ width: subjectSize, height: subjectSize, fit: "inside", withoutEnlargement: false })
    .png({ compressionLevel: 9 })
    .toBuffer({ resolveWithObject: true });

  const horizontal = targetSize - trimmed.info.width;
  const vertical = targetSize - trimmed.info.height;
  await sharp(trimmed.data)
    .extend({
      left: Math.floor(horizontal / 2),
      right: Math.ceil(horizontal / 2),
      top: Math.floor(vertical / 2),
      bottom: Math.ceil(vertical / 2),
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png({ compressionLevel: 9, palette: false })
    .toFile(outputPath);

  const total = extracted.info.width * extracted.info.height;
  const output = await sharp(outputPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const cornerAlpha = [
    output.data[3],
    output.data[(output.info.width - 1) * 4 + 3],
    output.data[((output.info.height - 1) * output.info.width) * 4 + 3],
    output.data[(output.info.width * output.info.height - 1) * 4 + 3],
  ];
  if (cornerAlpha.some((alpha) => alpha !== 0)) {
    throw new Error(`Transparent-corner validation failed: ${cornerAlpha.join(", ")}`);
  }
  const coverage = stats.visiblePixels / total;
  if (coverage < 0.08 || coverage > 0.72) {
    throw new Error(`Implausible foreground coverage: ${(coverage * 100).toFixed(1)}%`);
  }

  console.log(
    `${path.basename(outputPath)}: key rgb(${stats.key.r},${stats.key.g},${stats.key.b}), ` +
      `source coverage ${(coverage * 100).toFixed(1)}%, output ${output.info.width}x${output.info.height}, alpha corners OK`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
