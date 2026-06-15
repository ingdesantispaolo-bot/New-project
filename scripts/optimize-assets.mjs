import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const imageDir = path.resolve("src/assets/images");
const backgrounds = [
  "academy-painted-bg",
  "archive-painted-bg",
  "factory-painted-bg",
  "greenhouse-painted-bg",
  "lab-painted-bg",
];

const formats = [
  { extension: "webp", options: { quality: 78, effort: 5 } },
  { extension: "avif", options: { quality: 48, effort: 5 } },
];

await fs.mkdir(imageDir, { recursive: true });

for (const name of backgrounds) {
  const source = path.join(imageDir, `${name}.png`);
  for (const format of formats) {
    const output = path.join(imageDir, `${name}.${format.extension}`);
    await sharp(source)
      .resize(1280, 720, { fit: "cover", position: "center" })
      .toFormat(format.extension, format.options)
      .toFile(output);

    const sourceSize = (await fs.stat(source)).size;
    const outputSize = (await fs.stat(output)).size;
    const saved = Math.round((1 - outputSize / sourceSize) * 100);
    console.log(`${path.basename(output)} ${Math.round(outputSize / 1024)} KB (${saved}% smaller than PNG)`);
  }
}
