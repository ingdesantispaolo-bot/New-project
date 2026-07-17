import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const root = process.cwd();
const spriteDir = path.join(root, "src/assets/sprites");
await fs.promises.mkdir(spriteDir, { recursive: true });

const frames = [
  { id: "out_tree_round", w: 132, h: 132, svg: roundTreeSvg },
  { id: "out_tree_pine", w: 120, h: 148, svg: pineTreeSvg },
  { id: "out_bush_bloom", w: 124, h: 92, svg: bushSvg },
  { id: "out_flower_patch", w: 132, h: 88, svg: flowerPatchSvg },
  { id: "out_rock_moss", w: 116, h: 76, svg: rockSvg },
  { id: "out_crystal_cluster", w: 132, h: 132, svg: crystalSvg },
  { id: "out_ruin_column", w: 108, h: 148, svg: ruinColumnSvg },
  { id: "out_lamp_post", w: 96, h: 152, svg: lampPostSvg },
  { id: "out_bridge_plank", w: 156, h: 72, svg: bridgeSvg },
  { id: "out_geo_pond", w: 164, h: 104, svg: pondSvg },
  { id: "out_bench_cozy", w: 132, h: 86, svg: benchSvg },
  { id: "out_hazard_sun", w: 104, h: 104, svg: hazardSunSvg },
  { id: "out_hazard_dust", w: 118, h: 92, svg: hazardDustSvg },
  { id: "out_hazard_wisp", w: 104, h: 116, svg: hazardWispSvg },
  { id: "out_hazard_shadow", w: 126, h: 86, svg: hazardShadowSvg },
  { id: "out_marker_beacon", w: 112, h: 128, svg: markerBeaconSvg },
];

const padding = 8;
const sheetWidth = 1024;
let x = 0;
let y = 0;
let rowH = 0;
const composites = [];
const atlasFrames = {};

for (const frame of frames) {
  if (x + frame.w > sheetWidth) {
    x = 0;
    y += rowH + padding;
    rowH = 0;
  }
  const buffer = await sharp(Buffer.from(frame.svg(frame.w, frame.h))).png().toBuffer();
  composites.push({ input: buffer, left: x, top: y });
  atlasFrames[frame.id] = {
    frame: { x, y, w: frame.w, h: frame.h },
    rotated: false,
    trimmed: false,
    spriteSourceSize: { x: 0, y: 0, w: frame.w, h: frame.h },
    sourceSize: { w: frame.w, h: frame.h },
  };
  x += frame.w + padding;
  rowH = Math.max(rowH, frame.h);
}

const sheetHeight = y + rowH;
const png = path.join(spriteDir, "outdoor-world-sheet.png");
const json = path.join(spriteDir, "outdoor-world-sheet.json");

await sharp({
  create: {
    width: sheetWidth,
    height: sheetHeight,
    channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  },
})
  .composite(composites)
  .png()
  .toFile(png);

await fs.promises.writeFile(json, JSON.stringify({
  frames: atlasFrames,
  meta: {
    app: "codex-outdoor-sharp",
    image: "outdoor-world-sheet.png",
    format: "RGBA8888",
    size: { w: sheetWidth, h: sheetHeight },
    scale: "1",
  },
}, null, 2));

console.log(`Generated ${path.relative(root, png)} (${sheetWidth}x${sheetHeight})`);
console.log(`Generated ${path.relative(root, json)} (${frames.length} frames)`);

function svg(width, height, body) {
  return `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <filter id="soft"><feGaussianBlur stdDeviation="3"/></filter>
      <filter id="glow"><feGaussianBlur stdDeviation="5"/></filter>
      <linearGradient id="leaf" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#74f0c5"/><stop offset=".58" stop-color="#2f8a72"/><stop offset="1" stop-color="#173b36"/>
      </linearGradient>
      <linearGradient id="pine" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#8fe0a4"/><stop offset=".72" stop-color="#287345"/><stop offset="1" stop-color="#14382b"/>
      </linearGradient>
      <linearGradient id="metal" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#203849"/><stop offset=".56" stop-color="#10242d"/><stop offset="1" stop-color="#061019"/>
      </linearGradient>
      <linearGradient id="crystal" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#f5fbff"/><stop offset=".35" stop-color="#9ff5e9"/><stop offset=".74" stop-color="#7ad7ff"/><stop offset="1" stop-color="#9f8cff"/>
      </linearGradient>
    </defs>
    <rect width="${width}" height="${height}" fill="none"/>
    ${body}
  </svg>`;
}

function shadow(cx, cy, rx, ry, opacity = 0.28) {
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#02070b" opacity="${opacity}" filter="url(#soft)"/>`;
}

function roundTreeSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 18, 46, 10)}
    <rect x="${w / 2 - 8}" y="${h - 54}" width="16" height="38" rx="5" fill="#6a4428"/>
    <circle cx="${w / 2 - 28}" cy="${h - 70}" r="30" fill="url(#leaf)" stroke="#f5fbff" stroke-opacity=".12" stroke-width="3"/>
    <circle cx="${w / 2 + 3}" cy="${h - 86}" r="36" fill="url(#leaf)" stroke="#f5fbff" stroke-opacity=".16" stroke-width="3"/>
    <circle cx="${w / 2 + 31}" cy="${h - 68}" r="27" fill="#2b6c45" opacity=".96"/>
    <circle cx="${w / 2 - 20}" cy="${h - 84}" r="7" fill="#f6c85f" opacity=".74"/>
    <circle cx="${w / 2 + 21}" cy="${h - 93}" r="6" fill="#ff8f6b" opacity=".7"/>
    <path d="M${w / 2 - 24} ${h - 50} C${w / 2} ${h - 62} ${w / 2 + 22} ${h - 52} ${w / 2 + 38} ${h - 68}" fill="none" stroke="#9ff5e9" stroke-opacity=".18" stroke-width="4"/>`);
}

function pineTreeSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 15, 42, 10)}
    <rect x="${w / 2 - 7}" y="${h - 54}" width="14" height="40" rx="5" fill="#5a3a22"/>
    <path d="M${w / 2} 16 L${w / 2 - 40} ${h - 42} H${w / 2 + 40} Z" fill="url(#pine)" stroke="#9ff5e9" stroke-opacity=".18" stroke-width="3"/>
    <path d="M${w / 2} 48 L${w / 2 - 48} ${h - 28} H${w / 2 + 48} Z" fill="#235b3a" opacity=".92" stroke="#8fe0a4" stroke-opacity=".14" stroke-width="3"/>
    <path d="M${w / 2} 86 L${w / 2 - 36} ${h - 18} H${w / 2 + 36} Z" fill="#1c7d51" opacity=".84"/>
    <path d="M${w / 2 - 18} 58 L${w / 2 + 18} 72 M${w / 2 - 22} 94 L${w / 2 + 25} 108" stroke="#f5fbff" stroke-opacity=".12" stroke-width="4"/>`);
}

function bushSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 15, 48, 9)}
    <circle cx="38" cy="50" r="25" fill="#287345"/><circle cx="65" cy="38" r="31" fill="#2f8a72"/><circle cx="92" cy="52" r="26" fill="#235b3a"/>
    <circle cx="45" cy="39" r="5" fill="#f6c85f"/><circle cx="75" cy="30" r="5" fill="#ff8f6b"/><circle cx="92" cy="44" r="4" fill="#9ff5e9"/>
    <path d="M26 59 C54 42 78 70 108 50" fill="none" stroke="#9ff5e9" stroke-opacity=".18" stroke-width="4"/>`);
}

function flowerPatchSvg(w, h) {
  const flowers = Array.from({ length: 12 }, (_, i) => {
    const x = 24 + (i % 6) * 17;
    const y = 46 + Math.floor(i / 6) * 15 + (i % 2) * 4;
    const c = ["#f6c85f", "#ff8f6b", "#9ff5e9", "#c7b8ff"][i % 4];
    return `<path d="M${x} ${y + 10} V${y - 4}" stroke="#8fe0a4" stroke-opacity=".5" stroke-width="2"/><circle cx="${x}" cy="${y - 5}" r="5" fill="${c}"/><circle cx="${x}" cy="${y - 5}" r="2" fill="#f5fbff" opacity=".76"/>`;
  }).join("");
  return svg(w, h, `${shadow(w / 2, h - 18, 52, 8)}
    <ellipse cx="${w / 2}" cy="${h - 26}" rx="56" ry="20" fill="#14382b" opacity=".72" stroke="#8fe0a4" stroke-opacity=".2" stroke-width="3"/>
    ${flowers}`);
}

function rockSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 14, 42, 8)}
    <path d="M22 52 L40 24 L78 18 L102 48 L88 66 H34 Z" fill="#6c6575" stroke="#dde9ef" stroke-opacity=".18" stroke-width="3"/>
    <path d="M40 24 L54 50 L78 18 M54 50 L88 66" stroke="#dde9ef" stroke-opacity=".16" stroke-width="3"/>
    <ellipse cx="42" cy="44" rx="15" ry="6" fill="#8fe0a4" opacity=".28"/>
    <circle cx="72" cy="34" r="5" fill="#9ff5e9" opacity=".2"/>`);
}

function crystalSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 18, 48, 10)}
    <ellipse cx="${w / 2}" cy="${h - 34}" rx="48" ry="11" fill="#7ad7ff" opacity=".16"/>
    <path d="M35 ${h - 30} L51 42 L67 ${h - 30} Z" fill="url(#crystal)" opacity=".82" stroke="#f5fbff" stroke-opacity=".35" stroke-width="3"/>
    <path d="M60 ${h - 28} L78 18 L97 ${h - 28} Z" fill="url(#crystal)" opacity=".94" stroke="#f5fbff" stroke-opacity=".4" stroke-width="3"/>
    <path d="M84 ${h - 29} L100 54 L116 ${h - 29} Z" fill="#c7b8ff" opacity=".68" stroke="#f5fbff" stroke-opacity=".24" stroke-width="3"/>
    <path d="M78 20 L78 ${h - 30} M51 42 L56 ${h - 31} M100 54 L103 ${h - 30}" stroke="#ffffff" stroke-opacity=".2" stroke-width="2"/>
    <circle cx="${w / 2}" cy="${h / 2}" r="42" fill="#9ff5e9" opacity=".09" filter="url(#glow)"/>`);
}

function ruinColumnSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 16, 38, 10)}
    <rect x="28" y="22" width="52" height="14" fill="#6c6575" stroke="#ff8f6b" stroke-opacity=".28" stroke-width="2"/>
    <path d="M34 36 H74 L68 ${h - 26} H42 Z" fill="#4b4252" stroke="#dde9ef" stroke-opacity=".14" stroke-width="3"/>
    <path d="M42 48 H68 M40 76 H70 M39 104 H69" stroke="#ff8f6b" stroke-opacity=".18" stroke-width="3"/>
    <rect x="22" y="${h - 28}" width="66" height="15" fill="#5b5260" stroke="#ff8f6b" stroke-opacity=".24" stroke-width="2"/>
    <path d="M69 37 L88 68" stroke="#ff8f6b" stroke-opacity=".24" stroke-width="5" stroke-linecap="round"/>`);
}

function lampPostSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 14, 27, 8)}
    <rect x="${w / 2 - 5}" y="46" width="10" height="${h - 64}" rx="4" fill="url(#metal)" stroke="#6be7d6" stroke-opacity=".28" stroke-width="2"/>
    <circle cx="${w / 2}" cy="38" r="22" fill="#f6c85f" opacity=".13" filter="url(#glow)"/>
    <rect x="${w / 2 - 16}" y="22" width="32" height="31" rx="8" fill="#10242d" stroke="#f6c85f" stroke-opacity=".62" stroke-width="3"/>
    <circle cx="${w / 2}" cy="37" r="8" fill="#f6c85f" opacity=".82"/>
    <path d="M${w / 2 - 22} 54 H${w / 2 + 22}" stroke="#9ff5e9" stroke-opacity=".25" stroke-width="4"/>`);
}

function bridgeSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 16, 64, 8)}
    <path d="M18 36 H138" stroke="#6a4428" stroke-width="22" stroke-linecap="round"/>
    <path d="M18 26 H138 M18 46 H138" stroke="#f1c27a" stroke-opacity=".72" stroke-width="6" stroke-linecap="round"/>
    ${Array.from({ length: 6 }, (_, i) => `<path d="M${30 + i * 18} 18 V55" stroke="#4a321d" stroke-opacity=".48" stroke-width="5"/>`).join("")}
    <path d="M15 20 C48 0 104 0 141 20" fill="none" stroke="#9ff5e9" stroke-opacity=".16" stroke-width="4"/>`);
}

function pondSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 18, 64, 8)}
    <ellipse cx="${w / 2}" cy="${h / 2}" rx="70" ry="33" fill="#123246" stroke="#7ad7ff" stroke-opacity=".42" stroke-width="4"/>
    <ellipse cx="${w / 2 - 12}" cy="${h / 2 - 5}" rx="48" ry="16" fill="#2d9bbf" opacity=".32"/>
    <ellipse cx="${w / 2 + 28}" cy="${h / 2 + 10}" rx="26" ry="8" fill="#9ff5e9" opacity=".2"/>
    <path d="M32 44 C60 58 88 34 126 50" fill="none" stroke="#f5fbff" stroke-opacity=".16" stroke-width="4"/>
    <ellipse cx="42" cy="76" rx="13" ry="7" fill="#6c6575"/><ellipse cx="122" cy="74" rx="15" ry="7" fill="#7f8790"/>`);
}

function benchSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 13, 52, 8)}
    <rect x="20" y="24" width="92" height="12" rx="4" fill="#d9a15f" stroke="#4a321d" stroke-opacity=".25" stroke-width="2"/>
    <rect x="16" y="44" width="100" height="13" rx="4" fill="#f1c27a" stroke="#4a321d" stroke-opacity=".22" stroke-width="2"/>
    <rect x="30" y="56" width="8" height="24" rx="3" fill="#4a321d"/><rect x="94" y="56" width="8" height="24" rx="3" fill="#4a321d"/>
    <path d="M26 37 H106" stroke="#f5fbff" stroke-opacity=".16" stroke-width="3"/>`);
}

function hazardSunSvg(w, h) {
  const rays = Array.from({ length: 10 }, (_, i) => {
    const a = (Math.PI * 2 * i) / 10;
    const cx = w / 2;
    const cy = h / 2;
    return `<path d="M${cx + Math.cos(a) * 27} ${cy + Math.sin(a) * 27} L${cx + Math.cos(a) * 42} ${cy + Math.sin(a) * 42}" stroke="#f6c85f" stroke-opacity=".72" stroke-width="5" stroke-linecap="round"/>`;
  }).join("");
  return svg(w, h, `${shadow(w / 2, h - 14, 30, 7)}
    <circle cx="${w / 2}" cy="${h / 2}" r="39" fill="#f6c85f" opacity=".12" filter="url(#glow)"/>
    ${rays}<circle cx="${w / 2}" cy="${h / 2}" r="22" fill="#f6c85f" stroke="#f5fbff" stroke-opacity=".38" stroke-width="4"/>
    <circle cx="${w / 2}" cy="${h / 2}" r="8" fill="#fff1ad" opacity=".86"/>`);
}

function hazardDustSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 14, 38, 8)}
    <path d="M22 56 C42 28 76 78 100 38" fill="none" stroke="#f6c85f" stroke-opacity=".54" stroke-width="8" stroke-linecap="round"/>
    <path d="M25 72 C56 44 82 83 110 58" fill="none" stroke="#c7b8ff" stroke-opacity=".34" stroke-width="6" stroke-linecap="round"/>
    <circle cx="34" cy="40" r="5" fill="#f6c85f" opacity=".62"/><circle cx="96" cy="72" r="4" fill="#f5fbff" opacity=".42"/>`);
}

function hazardWispSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 13, 30, 8)}
    <circle cx="${w / 2}" cy="54" r="34" fill="#9f8cff" opacity=".16" filter="url(#glow)"/>
    <path d="M${w / 2} 18 C25 52 40 77 ${w / 2} 100 C69 78 86 54 ${w / 2} 18Z" fill="#132451" stroke="#c7b8ff" stroke-opacity=".7" stroke-width="4"/>
    <path d="M${w / 2} 30 C43 55 51 70 ${w / 2} 86 C66 67 70 52 ${w / 2} 30Z" fill="#9f8cff" opacity=".55"/>
    <circle cx="${w / 2 - 8}" cy="55" r="4" fill="#f5fbff"/><circle cx="${w / 2 + 9}" cy="52" r="3" fill="#f5fbff" opacity=".78"/>`);
}

function hazardShadowSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 14, 48, 9)}
    <ellipse cx="${w / 2}" cy="${h / 2}" rx="50" ry="28" fill="#02070b" stroke="#9f8cff" stroke-opacity=".54" stroke-width="4"/>
    <ellipse cx="${w / 2}" cy="${h / 2 - 1}" rx="28" ry="11" fill="#45133d" opacity=".76"/>
    <circle cx="${w / 2}" cy="${h / 2}" r="5" fill="#f5fbff"/>
    <path d="M22 50 C42 21 83 18 104 48" fill="none" stroke="#c7b8ff" stroke-opacity=".18" stroke-width="5"/>`);
}

function markerBeaconSvg(w, h) {
  return svg(w, h, `${shadow(w / 2, h - 15, 34, 8)}
    <rect x="${w / 2 - 13}" y="48" width="26" height="54" rx="8" fill="url(#metal)" stroke="#6be7d6" stroke-opacity=".45" stroke-width="3"/>
    <circle cx="${w / 2}" cy="38" r="31" fill="#6be7d6" opacity=".11" filter="url(#glow)"/>
    <path d="M${w / 2} 12 L${w / 2 - 25} 58 H${w / 2 + 25} Z" fill="#6be7d6" opacity=".28" stroke="#f5fbff" stroke-opacity=".28" stroke-width="3"/>
    <circle cx="${w / 2}" cy="72" r="8" fill="#f6c85f"/><path d="M${w / 2 - 22} 103 H${w / 2 + 22}" stroke="#9ff5e9" stroke-opacity=".38" stroke-width="5"/>`);
}
