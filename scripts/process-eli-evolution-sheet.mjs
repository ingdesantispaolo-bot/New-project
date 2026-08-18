import path from "node:path";
import sharp from "sharp";

const [inputArg, outputArg, backgroundArg = "dark"] = process.argv.slice(2);

if (!inputArg || !outputArg || !["dark", "light"].includes(backgroundArg)) {
  console.error("Usage: node scripts/process-eli-evolution-sheet.mjs <input.png> <output.png> <dark|light>");
  process.exit(2);
}

const inputPath = path.resolve(inputArg);
const outputPath = path.resolve(outputArg);

function smoothstep(edge0, edge1, value) {
  const ratio = Math.max(0, Math.min(1, (value - edge0) / (edge1 - edge0)));
  return ratio * ratio * (3 - 2 * ratio);
}

function foregroundAlpha(r, g, b) {
  if (backgroundArg === "dark") {
    // I tre fogli scuri hanno un fondale quasi nero uniforme. Una soglia corta
    // conserva capelli e contorni bruni, ma elimina il nero con antialias dolce.
    return smoothstep(3, 27, Math.sqrt(r * r + g * g + b * b));
  }

  // Aurora e' arrivata con una scacchiera chiara rasterizzata. La scacchiera e'
  // neutra; il personaggio e' piu' scuro oppure saturo. Combiniamo le due misure
  // per non bucare i riflessi ciano e viola dell'armatura.
  const maximum = Math.max(r, g, b);
  const minimum = Math.min(r, g, b);
  const saturation = maximum - minimum;
  const luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  const foregroundScore = Math.max(0, 236 - luminance) + saturation * 1.35;
  return smoothstep(8, 42, foregroundScore);
}

async function main() {
  const source = await sharp(inputPath).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const rgba = Buffer.alloc(source.info.width * source.info.height * 4);
  let visible = 0;

  for (let pixel = 0; pixel < source.info.width * source.info.height; pixel += 1) {
    const sourceOffset = pixel * 3;
    const targetOffset = pixel * 4;
    const r = source.data[sourceOffset];
    const g = source.data[sourceOffset + 1];
    const b = source.data[sourceOffset + 2];
    const alpha = foregroundAlpha(r, g, b);
    rgba[targetOffset] = r;
    rgba[targetOffset + 1] = g;
    rgba[targetOffset + 2] = b;
    rgba[targetOffset + 3] = Math.round(alpha * 255);
    if (alpha >= 0.5) visible += 1;
  }

  await sharp(rgba, {
    raw: { width: source.info.width, height: source.info.height, channels: 4 },
  })
    .resize(480, 384, { fit: "fill", kernel: sharp.kernel.lanczos3 })
    .png({ compressionLevel: 9, palette: false })
    .toFile(outputPath);

  const output = await sharp(outputPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const corners = [
    output.data[3],
    output.data[(output.info.width - 1) * 4 + 3],
    output.data[(output.info.height - 1) * output.info.width * 4 + 3],
    output.data[(output.info.width * output.info.height - 1) * 4 + 3],
  ];
  if (corners.some((alpha) => alpha > 8)) {
    throw new Error(`Transparent-corner validation failed: ${corners.join(", ")}`);
  }

  const coverage = visible / (source.info.width * source.info.height);
  if (coverage < 0.12 || coverage > 0.48) {
    throw new Error(`Implausible foreground coverage: ${(coverage * 100).toFixed(1)}%`);
  }

  console.log(
    `${path.basename(outputPath)}: ${source.info.width}x${source.info.height} -> 480x384, ` +
      `${backgroundArg} key, coverage ${(coverage * 100).toFixed(1)}%, alpha corners OK`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
