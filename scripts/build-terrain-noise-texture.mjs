// Cuoce i quattro campi di rumore del terreno in una sola texture RGBA.
//
// `painterly_ground.gdshader` valutava quattro `fbm()` per fragment, ognuno a
// 4 ottave di `value_noise`, cioe' ~64 chiamate a `hash21` per pixel a schermo
// pieno. Su GPU mobile quel costo ALU e' nell'ordine di grandezza dell'intero
// budget di frame. I quattro campi dipendono SOLO dalla posizione mondo, quindi
// sono precalcolabili: qui vengono campionati una volta su griglia e impacchettati
// in quattro canali, e lo shader li legge con un singolo `texture()`.
//
// L'aritmetica replica esattamente quella GLSL, `Math.fround` inclusa per
// emulare i float a 32 bit: senza, i double di JS divergerebbero dal risultato
// della GPU e il terreno cambierebbe aspetto.
//
//   node scripts/build-terrain-noise-texture.mjs [--check]

import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const OUTPUT = path.resolve("godot/assets/terrain-noise-fields-v1.png");

// Il mondo giocabile arriva a +-3584 unita' (chunk_manager: WORLD_MIN -4,
// WORLD_MAX 3, CHUNK_SIZE 896). Si cuoce a +-4096 per coprire anche il bleed dei
// chunk di bordo, cosi' il campionamento resta dentro la texture ovunque.
const WORLD_ORIGIN = -4096;
const WORLD_SIZE = 8192;
const RESOLUTION = 512; // 16 unita' mondo per texel

// Gli stessi quattro campi, con le stesse scale e gli stessi offset dello shader.
const FIELDS = [
  { name: "breakup", scale: 560.0, offset: [0.0, 0.0] },
  { name: "clearing", scale: 980.0, offset: [930.0, -410.0] },
  { name: "understory", scale: 610.0, offset: [-370.0, 720.0] },
  { name: "macro", scale: 1450.0, offset: [0.0, 0.0] },
];

const f = Math.fround;

function fract(x) {
  return f(x - Math.floor(x));
}

// float hash21(vec2 p)
function hash21(px, py) {
  let x = fract(f(px * 123.34));
  let y = fract(f(py * 456.21));
  const dot = f(f(x * f(x + 45.32)) + f(y * f(y + 45.32)));
  x = f(x + dot);
  y = f(y + dot);
  return fract(f(x * y));
}

// float value_noise(vec2 p)
function valueNoise(px, py) {
  const ix = Math.floor(px);
  const iy = Math.floor(py);
  const fx = f(px - ix);
  const fy = f(py - iy);
  const ux = f(f(fx * fx) * f(3.0 - f(2.0 * fx)));
  const uy = f(f(fy * fy) * f(3.0 - f(2.0 * fy)));
  const a = hash21(ix, iy);
  const b = hash21(ix + 1, iy);
  const c = hash21(ix, iy + 1);
  const d = hash21(ix + 1, iy + 1);
  const top = f(a + f(ux * f(b - a)));
  const bottom = f(c + f(ux * f(d - c)));
  return f(top + f(uy * f(bottom - top)));
}

// float fbm(vec2 p) — mat2 GLSL e' column-major: col0=(1.63,1.18), col1=(-1.18,1.63)
function fbm(px, py) {
  let x = px;
  let y = py;
  let result = 0.0;
  let amplitude = f(0.55);
  for (let i = 0; i < 4; i++) {
    result = f(result + f(valueNoise(x, y) * amplitude));
    const nx = f(f(1.63 * x) + f(-1.18 * y));
    const ny = f(f(1.18 * x) + f(1.63 * y));
    x = nx;
    y = ny;
    amplitude = f(amplitude * 0.48);
  }
  return result;
}

function bake() {
  const pixels = Buffer.alloc(RESOLUTION * RESOLUTION * 4);
  const step = WORLD_SIZE / RESOLUTION;
  let min = Infinity;
  let max = -Infinity;

  for (let ty = 0; ty < RESOLUTION; ty++) {
    // Centro del texel: allinea il bake al campionamento bilineare della GPU.
    const worldY = WORLD_ORIGIN + (ty + 0.5) * step;
    for (let tx = 0; tx < RESOLUTION; tx++) {
      const worldX = WORLD_ORIGIN + (tx + 0.5) * step;
      const base = (ty * RESOLUTION + tx) * 4;
      for (let c = 0; c < 4; c++) {
        const field = FIELDS[c];
        const value = fbm(
          f((worldX + field.offset[0]) / field.scale),
          f((worldY + field.offset[1]) / field.scale),
        );
        if (value < min) min = value;
        if (value > max) max = value;
        pixels[base + c] = Math.max(0, Math.min(255, Math.round(value * 255)));
      }
    }
  }
  return { pixels, min, max };
}

const { pixels, min, max } = bake();
console.log(`campi cotti: ${FIELDS.map((x) => x.name).join(", ")}`);
console.log(`  risoluzione ${RESOLUTION}x${RESOLUTION}, ${(WORLD_SIZE / RESOLUTION).toFixed(0)} unita' mondo per texel`);
console.log(`  intervallo fbm osservato: ${min.toFixed(4)} .. ${max.toFixed(4)}`);
if (max > 1.0) {
  console.warn(`  ATTENZIONE: valori oltre 1.0 verrebbero troncati dalla quantizzazione a 8 bit`);
}

const png = await sharp(pixels, {
  raw: { width: RESOLUTION, height: RESOLUTION, channels: 4 },
})
  .png({ compressionLevel: 9 })
  .toBuffer();

if (process.argv.includes("--check")) {
  const existing = await fs.readFile(OUTPUT).catch(() => null);
  if (existing == null || !existing.equals(png)) {
    console.error(`FUORI DATA: ${path.relative(process.cwd(), OUTPUT)} va rigenerato`);
    process.exit(1);
  }
  console.log("texture di rumore allineata alla sorgente");
} else {
  await fs.writeFile(OUTPUT, png);
  console.log(`scritto ${path.relative(process.cwd(), OUTPUT)} (${(png.length / 1024).toFixed(0)} KB)`);
}
