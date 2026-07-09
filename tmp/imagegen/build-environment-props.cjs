const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const input =
  "C:/Users/39351/.codex/generated_images/019f17b6-2f0e-7822-8c2b-e800dc178193/ig_025c1e78b1d58df3016a4f6c7dda988191b27c5fd7de31d15e.png";
const outDir = "src/assets/sprites/environment-props";
const tmpDir = "tmp/imagegen";

const props = [
  ["env_wall_straight", "wall-straight", 0, 0, 264, 132],
  ["env_wall_corner", "wall-corner", 1, 0, 176, 176],
  ["env_wall_end", "wall-end", 2, 0, 96, 144],
  ["env_railing", "railing", 3, 0, 176, 88],
  ["env_pillar_square", "pillar-square", 0, 1, 96, 144],
  ["env_pillar_light", "pillar-light", 1, 1, 88, 144],
  ["env_floor_cable", "floor-cable", 2, 1, 176, 88],
  ["env_floor_vent", "floor-vent", 3, 1, 132, 88],
  ["env_planter", "planter", 0, 2, 176, 88],
  ["env_plant_pod", "plant-pod", 1, 2, 96, 144],
  ["env_terminal_wall", "terminal-wall", 2, 2, 104, 136],
  ["env_terminal_kiosk", "terminal-kiosk", 3, 2, 88, 136],
  ["env_robot_decor", "robot-decor", 0, 3, 104, 88],
  ["env_repair_drone", "repair-drone", 1, 3, 104, 88],
  ["env_crate_stack", "crate-stack", 2, 3, 132, 96],
  ["env_holo_beacon", "holo-beacon", 3, 3, 104, 144],
];

fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(tmpDir, { recursive: true });
fs.copyFileSync(input, path.join(tmpDir, "environment-props-source.png"));

function isKey(r, g, b) {
  return (r > 190 && b > 160 && g < 110) || (r > 120 && b > 120 && g < 70 && Math.abs(r - b) < 95);
}

async function cropGridCell(col, row) {
  const source = sharp(input).ensureAlpha();
  const meta = await source.metadata();
  const cellW = Math.floor(meta.width / 4);
  const cellH = Math.floor(meta.height / 4);
  const left = col * cellW;
  const top = row * cellH;
  const width = col === 3 ? meta.width - left : cellW;
  const height = row === 3 ? meta.height - top : cellH;
  const { data, info } = await source.extract({ left, top, width, height }).raw().toBuffer({ resolveWithObject: true });

  let minX = info.width;
  let minY = info.height;
  let maxX = 0;
  let maxY = 0;
  for (let y = 0; y < info.height; y++) {
    for (let x = 0; x < info.width; x++) {
      const i = (y * info.width + x) * info.channels;
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      if (isKey(r, g, b)) {
        data[i + 3] = 0;
      } else {
        if (r > 145 && b > 130 && g < 115) {
          data[i] = Math.min(r, 42);
          data[i + 2] = Math.min(b, 54);
        }
        data[i + 3] = 255;
        minX = Math.min(minX, x);
        minY = Math.min(minY, y);
        maxX = Math.max(maxX, x);
        maxY = Math.max(maxY, y);
      }
    }
  }

  return sharp(data, { raw: info })
    .extract({
      left: Math.max(0, minX - 2),
      top: Math.max(0, minY - 2),
      width: Math.min(info.width - Math.max(0, minX - 2), maxX - minX + 5),
      height: Math.min(info.height - Math.max(0, minY - 2), maxY - minY + 5),
    })
    .png()
    .toBuffer();
}

async function makeProp(prop, mult = 1) {
  const [, , col, row, w, h] = prop;
  const cropped = await cropGridCell(col, row);
  return sharp({
    create: { width: w * mult, height: h * mult, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  })
    .composite([
      {
        input: await sharp(cropped)
          .resize(w * mult, h * mult, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } })
          .png()
          .toBuffer(),
        left: 0,
        top: 0,
      },
    ])
    .png()
    .toBuffer();
}

function pack(mult) {
  const maxW = 1024 * mult;
  const pad = 8 * mult;
  let x = 0;
  let y = 0;
  let rowH = 0;
  const placements = [];

  for (const prop of props) {
    const [key, slug, , , w, h] = prop;
    const pw = w * mult;
    const ph = h * mult;
    if (x > 0 && x + pw > maxW) {
      x = 0;
      y += rowH + pad;
      rowH = 0;
    }
    placements.push({ key, slug, prop, x, y, w: pw, h: ph });
    x += pw + pad;
    rowH = Math.max(rowH, ph);
  }

  const sheetW = maxW;
  const sheetH = y + rowH;
  return { sheetW, sheetH, placements };
}

async function buildSheet(mult = 1) {
  const { sheetW, sheetH, placements } = pack(mult);
  const composites = [];
  const frames = {};

  for (const p of placements) {
    composites.push({ input: await makeProp(p.prop, mult), left: p.x, top: p.y });
    if (mult === 1) {
      frames[p.key] = {
        frame: { x: p.x, y: p.y, w: p.w, h: p.h },
        rotated: false,
        trimmed: false,
        spriteSourceSize: { x: 0, y: 0, w: p.w, h: p.h },
        sourceSize: { w: p.w, h: p.h },
      };
    }
  }

  const sheet = await sharp({
    create: { width: sheetW, height: sheetH, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  })
    .composite(composites)
    .png()
    .toBuffer();
  await fs.promises.writeFile(`src/assets/sprites/environment-props-sheet${mult === 2 ? "@2x" : ""}.png`, sheet);

  if (mult === 1) {
    const meta = {
      app: "codex-imagegen-sharp",
      image: "environment-props-sheet.png",
      format: "RGBA8888",
      size: { w: sheetW, h: sheetH },
      scale: "1",
      source: "environment-props-source.png",
      props: Object.fromEntries(props.map(([key, slug, , , w, h]) => [key, { slug, w, h }])),
    };
    await fs.promises.writeFile("src/assets/sprites/environment-props-sheet.json", JSON.stringify({ frames, meta }, null, 2));
  }
}

async function main() {
  for (const prop of props) {
    const [key, slug] = prop;
    await fs.promises.writeFile(path.join(outDir, `${slug}.png`), await makeProp(prop, 1));
    await fs.promises.writeFile(path.join(outDir, `${slug}@2x.png`), await makeProp(prop, 2));
  }
  await buildSheet(1);
  await buildSheet(2);
  console.log(`created ${props.length} environment props plus atlas sheets`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
