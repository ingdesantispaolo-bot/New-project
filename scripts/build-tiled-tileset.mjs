import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const tileDir = path.resolve("src/assets/tiles");
const tileSize = 16;
const columns = 8;
const rows = 4;

await fs.mkdir(tileDir, { recursive: true });

const tiles = [
  tile("void", "#050b11"),
  tile("deep_floor", "#0a1720", [["line", "#17313d", 0.55, 0, 15, 16, 15]]),
  tile("academy_grid", "#0b1b26", [["line", "#315766", 0.45, 0, 15, 16, 12], ["line", "#315766", 0.25, 0, 0, 16, 0]]),
  tile("cyan_trace", "#0a1720", [["line", "#6be7d6", 0.78, 0, 8, 16, 8], ["circle", "#6be7d6", 0.35, 8, 8, 3]]),
  tile("gold_trace", "#0d1720", [["line", "#f6c85f", 0.72, 0, 8, 16, 8], ["circle", "#f6c85f", 0.32, 8, 8, 3]]),
  tile("glass_panel", "#102936", [["rect", "#6be7d6", 0.16, 2, 2, 12, 12], ["line", "#9ff5e9", 0.36, 2, 2, 14, 2]]),
  tile("green_glass", "#0b221f", [["rect", "#70d68a", 0.16, 2, 2, 12, 12], ["line", "#c9f7c9", 0.3, 2, 12, 14, 4]]),
  tile("leaf_mark", "#0b221f", [["ellipse", "#70d68a", 0.65, 8, 8, 10, 5], ["line", "#e6ffd5", 0.45, 4, 10, 12, 6]]),
  tile("factory_floor", "#171512", [["line", "#3a3124", 0.65, 0, 15, 16, 12], ["line", "#f6c85f", 0.18, 0, 0, 16, 0]]),
  tile("hazard", "#211d17", [["rect", "#f6c85f", 0.65, 0, 0, 5, 16], ["rect", "#111111", 0.7, 5, 0, 5, 16], ["rect", "#f6c85f", 0.65, 10, 0, 6, 16]]),
  tile("metal_panel", "#15202a", [["circle", "#8aa6b0", 0.5, 4, 4, 2], ["circle", "#8aa6b0", 0.35, 12, 12, 2], ["line", "#53636a", 0.45, 0, 15, 16, 15]]),
  tile("archive_shelf", "#171925", [["rect", "#9f8cff", 0.16, 0, 10, 16, 3], ["line", "#e3d9ff", 0.22, 0, 11, 16, 11]]),
  tile("book_blue", "#1b2030", [["rect", "#355c7d", 0.68, 4, 2, 8, 12], ["line", "#ffffff", 0.22, 7, 3, 7, 13]]),
  tile("book_purple", "#1b2030", [["rect", "#6c5b7b", 0.72, 3, 1, 10, 14], ["line", "#ffffff", 0.2, 6, 2, 6, 14]]),
  tile("cyan_light", "#061019", [["circle", "#6be7d6", 0.55, 8, 8, 7], ["circle", "#ffffff", 0.28, 8, 8, 2]]),
  tile("warm_light", "#10100c", [["circle", "#f6c85f", 0.55, 8, 8, 7], ["circle", "#ffffff", 0.22, 8, 8, 2]]),
  tile("wall_dark", "#0d1b26", [["line", "#213b4a", 0.46, 0, 15, 16, 15], ["line", "#213b4a", 0.24, 15, 0, 15, 16]]),
  tile("lab_wall", "#0b1a24", [["line", "#6be7d6", 0.16, 0, 12, 16, 12], ["line", "#315766", 0.32, 0, 0, 16, 0]]),
  tile("door_panel", "#111820", [["rect", "#4b6570", 0.5, 3, 1, 10, 14], ["circle", "#6be7d6", 0.28, 8, 8, 4]]),
  tile("terminal_tile", "#102839", [["rect", "#071018", 0.82, 2, 4, 12, 7], ["line", "#f6c85f", 0.38, 2, 12, 14, 12]]),
  tile("circuit_tile", "#142837", [["line", "#6be7d6", 0.45, 1, 8, 15, 8], ["circle", "#f6c85f", 0.55, 5, 8, 2], ["circle", "#6be7d6", 0.38, 11, 8, 2]]),
  tile("botanic_shadow", "#06130f", [["ellipse", "#70d68a", 0.18, 8, 11, 14, 5]]),
  tile("archive_glyph", "#0a0d18", [["text", "#9f8cff", 0.45, 5, 12, "a"]]),
  tile("blank", "#000000", [], 0),
];

while (tiles.length < columns * rows) {
  tiles.push(tile("empty", "#000000", [], 0));
}

const composites = tiles.map((entry, index) => ({
  input: Buffer.from(entry.svg),
  left: (index % columns) * tileSize,
  top: Math.floor(index / columns) * tileSize,
}));

await sharp({
  create: {
    width: columns * tileSize,
    height: rows * tileSize,
    channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  },
})
  .composite(composites)
  .png()
  .toFile(path.join(tileDir, "eli-production-tileset.png"));

console.log(`Generated ${path.join("src/assets/tiles", "eli-production-tileset.png")} (${tiles.length} tiles)`);

function tile(name, fill, shapes = [], opacity = 1) {
  const parts = [`<rect width="16" height="16" fill="${fill}" opacity="${opacity}"/>`];
  for (const shape of shapes) {
    const [kind, color, alpha, ...args] = shape;
    if (kind === "line") {
      const [x1, y1, x2, y2] = args;
      parts.push(`<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-opacity="${alpha}" stroke-width="1"/>`);
    } else if (kind === "rect") {
      const [x, y, width, height] = args;
      parts.push(`<rect x="${x}" y="${y}" width="${width}" height="${height}" fill="${color}" opacity="${alpha}"/>`);
    } else if (kind === "circle") {
      const [cx, cy, r] = args;
      parts.push(`<circle cx="${cx}" cy="${cy}" r="${r}" fill="${color}" opacity="${alpha}"/>`);
    } else if (kind === "ellipse") {
      const [cx, cy, rx, ry] = args;
      parts.push(`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${color}" opacity="${alpha}"/>`);
    } else if (kind === "text") {
      const [x, y, text] = args;
      parts.push(`<text x="${x}" y="${y}" fill="${color}" opacity="${alpha}" font-size="10" font-family="Georgia">${text}</text>`);
    }
  }
  return {
    name,
    svg: `<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">${parts.join("")}</svg>`,
  };
}
