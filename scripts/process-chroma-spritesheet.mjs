import sharp from "sharp";
import { resolve } from "node:path";

const [inputArg, outputArg, widthArg = "480", heightArg = "384"] = process.argv.slice(2);
if (!inputArg || !outputArg) {
  console.error("Uso: node scripts/process-chroma-spritesheet.mjs <input> <output> [width] [height]");
  process.exit(2);
}

const targetWidth = Number(widthArg);
const targetHeight = Number(heightArg);
const input = resolve(inputArg);
const output = resolve(outputArg);
const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const transparentDistance = 28;
const opaqueDistance = 160;

for (let i = 0; i < data.length; i += 4) {
  const r = data[i];
  const g = data[i + 1];
  const b = data[i + 2];
  const distance = Math.hypot(r - 255, g, b - 255);
  let matte = (distance - transparentDistance) / (opaqueDistance - transparentDistance);
  matte = Math.max(0, Math.min(1, matte));
  matte = matte * matte * (3 - 2 * matte);
  const oldAlpha = data[i + 3] / 255;
  let alpha = oldAlpha * matte;
  if (alpha > 0.02 && alpha < 0.995) {
    // Ricostruisce il colore di primo piano togliendo lo spill magenta.
    data[i] = Math.max(0, Math.min(255, Math.round((r - (1 - alpha) * 255) / alpha)));
    data[i + 1] = Math.max(0, Math.min(255, Math.round(g / alpha)));
    data[i + 2] = Math.max(0, Math.min(255, Math.round((b - (1 - alpha) * 255) / alpha)));
  }
  const magentaSpill = Math.max(0, Math.min(data[i], data[i + 2]) - data[i + 1]);
  if (magentaSpill > 8) {
    alpha *= Math.max(0, 1 - magentaSpill / 150);
    data[i] = Math.max(data[i + 1], Math.round(data[i] - magentaSpill * 0.72));
    data[i + 2] = Math.max(data[i + 1], Math.round(data[i + 2] - magentaSpill));
  }
  data[i + 3] = Math.round(alpha * 255);
}

const sourceAspect = info.width / info.height;
const targetAspect = targetWidth / targetHeight;
let extract = { left: 0, top: 0, width: info.width, height: info.height };
if (sourceAspect > targetAspect) {
  extract.width = Math.round(info.height * targetAspect);
  extract.left = Math.floor((info.width - extract.width) / 2);
} else if (sourceAspect < targetAspect) {
  extract.height = Math.round(info.width / targetAspect);
  extract.top = Math.floor((info.height - extract.height) / 2);
}

const resized = await sharp(data, { raw: info })
  .extract(extract)
  .resize(targetWidth, targetHeight, { fit: "fill", kernel: sharp.kernel.lanczos3 })
  .ensureAlpha()
  .raw()
  .toBuffer({ resolveWithObject: true });

// Lanczos può lasciare un alone alpha quasi invisibile sul bordo trasparente.
for (let i = 3; i < resized.data.length; i += 4) {
  if (resized.data[i] <= 56) resized.data[i] = 0;
}
await sharp(resized.data, { raw: resized.info })
  .png({ compressionLevel: 9, adaptiveFiltering: true })
  .toFile(output);

const check = await sharp(output).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const corners = [0, check.info.width - 1, (check.info.height - 1) * check.info.width, check.info.width * check.info.height - 1];
if (corners.some((pixel) => check.data[pixel * 4 + 3] > 4)) {
  throw new Error("Gli angoli non sono trasparenti dopo la rimozione del chroma-key");
}
console.log(`Spritesheet pronto: ${output} (${targetWidth}x${targetHeight}, alpha validato)`);
