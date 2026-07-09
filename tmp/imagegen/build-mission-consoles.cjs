const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const input =
  "C:/Users/39351/.codex/generated_images/019f17b6-2f0e-7822-8c2b-e800dc178193/ig_08064dba5c395d94016a4f68c33b6081919f4251331fcb365a.png";
const outDir = "src/assets/sprites/mission-consoles";
const tmpDir = "tmp/imagegen";
const W = 120;
const H = 150;

const subjects = [
  ["math", "matematica", "#6be7d6", "divide"],
  ["italian", "italiano", "#b888ff", "pen"],
  ["english", "inglese", "#7cc7ff", "globe"],
  ["coding", "coding", "#78f29a", "computer"],
  ["electronics", "elettronica", "#f6c85f", "bolt"],
  ["music", "musica", "#ff9f4a", "music"],
  ["exit", "porta-uscita", "#f6c85f", "door"],
];

fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(tmpDir, { recursive: true });
fs.copyFileSync(input, path.join(tmpDir, "console-machine-base-source.png"));

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

function rgbToHex(values) {
  return `#${values.map((v) => v.toString(16).padStart(2, "0")).join("")}`;
}

function lighten(hex, amount) {
  const c = hexToRgb(hex);
  return rgbToHex([c.r, c.g, c.b].map((v) => Math.round(v + (255 - v) * amount)));
}

function darken(hex, amount) {
  const c = hexToRgb(hex);
  return rgbToHex([c.r, c.g, c.b].map((v) => Math.round(v * (1 - amount))));
}

function iconSvg(kind, color, state) {
  const glow = state === "resolved" ? "#7cff9b" : color;
  const pale = lighten(glow, 0.35);
  const common = `stroke="${pale}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"`;

  if (kind === "divide") {
    return `<circle cx="60" cy="54" r="4" fill="${pale}"/><line x1="42" y1="68" x2="78" y2="68" ${common}/><circle cx="60" cy="82" r="4" fill="${pale}"/>`;
  }
  if (kind === "pen") {
    return `<path d="M43 90 L55 48 L77 70 L35 82 Z" fill="${darken(color, 0.35)}" stroke="${pale}" stroke-width="3" stroke-linejoin="round"/><path d="M55 48 L66 37 L88 59 L77 70" ${common}/><circle cx="57" cy="68" r="4" fill="${pale}"/>`;
  }
  if (kind === "globe") {
    return `<circle cx="60" cy="68" r="25" ${common}/><path d="M35 68 H85 M60 43 C48 55 48 81 60 93 M60 43 C72 55 72 81 60 93" ${common}/>`;
  }
  if (kind === "computer") {
    return `<rect x="36" y="48" width="48" height="34" rx="3" ${common}/><path d="M51 91 H69 M60 82 V91 M47 65 L56 57 M47 65 L56 73 M73 65 H64" ${common}/>`;
  }
  if (kind === "bolt") {
    return `<path d="M66 34 L43 71 H59 L53 101 L79 61 H63 Z" fill="${pale}" stroke="${darken(color, 0.45)}" stroke-width="2" stroke-linejoin="round"/>`;
  }
  if (kind === "music") {
    return `<path d="M72 42 V80 M72 42 L47 49 V87" ${common}/><ellipse cx="39" cy="88" rx="9" ry="7" fill="${pale}"/><ellipse cx="64" cy="81" rx="9" ry="7" fill="${pale}"/>`;
  }
  return `<path d="M43 98 V42 H77 V98 Z" ${common}/><path d="M50 49 H77 M77 49 L88 57 V106 H52 L43 98" ${common}/><circle cx="69" cy="70" r="3" fill="${pale}"/>`;
}

function overlaySvg(subject, state) {
  const [, , color, kind] = subject;
  const resolved = state === "resolved";
  const accent = resolved ? "#7cff9b" : color;
  const top = lighten(accent, 0.2);
  const screenFill = resolved ? "rgba(12,64,42,.70)" : "rgba(6,18,25,.78)";
  const border = resolved ? "#95ffad" : top;
  const pulse = resolved ? "#a6ffbb" : lighten(accent, 0.48);
  const iconOpacity = resolved ? "1" : ".94";
  const scanOpacity = resolved ? ".26" : ".16";
  const lowerOpacity = resolved ? ".95" : ".55";
  const ledOpacity = resolved ? ".95" : ".65";
  const check = resolved
    ? `<path d="M35 28 L41 34 L53 22" stroke="#b8ffc5" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" filter="url(#glow)"/>`
    : "";

  return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg">
<defs>
  <filter id="glow" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="2.2" result="b"/>
    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <linearGradient id="scan" x1="0" x2="0" y1="0" y2="1">
    <stop offset="0" stop-color="${lighten(accent, 0.3)}" stop-opacity=".95"/>
    <stop offset=".48" stop-color="${accent}" stop-opacity=".45"/>
    <stop offset="1" stop-color="${darken(accent, 0.45)}" stop-opacity=".70"/>
  </linearGradient>
</defs>
<ellipse cx="60" cy="142" rx="42" ry="7" fill="rgba(0,0,0,.28)"/>
<rect x="39" y="18" width="42" height="5" rx="2.5" fill="${top}" filter="url(#glow)"/>
<rect x="28" y="38" width="64" height="73" rx="7" fill="${screenFill}" stroke="${border}" stroke-width="2.2"/>
<rect x="34" y="44" width="52" height="61" rx="4" fill="url(#scan)" opacity="${scanOpacity}"/>
<g filter="url(#glow)" opacity="${iconOpacity}">${iconSvg(kind, accent, state)}</g>
<rect x="21" y="121" width="78" height="5" rx="2.5" fill="${accent}" opacity="${lowerOpacity}" filter="url(#glow)"/>
<circle cx="96" cy="34" r="4" fill="${pulse}" opacity="${ledOpacity}" filter="url(#glow)"/>
${check}
</svg>`;
}

async function cutBase() {
  const img = sharp(input).ensureAlpha();
  const meta = await img.metadata();
  const raw = await img.raw().toBuffer();
  const w = meta.width;
  const h = meta.height;
  let minX = w;
  let minY = h;
  let maxX = 0;
  let maxY = 0;

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      const r = raw[i];
      const g = raw[i + 1];
      const b = raw[i + 2];
      const key = r > 210 && b > 190 && g < 80;
      if (key) {
        raw[i + 3] = 0;
      } else {
        if (r > 150 && b > 140 && g < 110) {
          raw[i] = Math.min(r, 45);
          raw[i + 2] = Math.min(b, 58);
        }
        raw[i + 3] = 255;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  return sharp(raw, { raw: { width: w, height: h, channels: 4 } })
    .extract({ left: minX, top: minY, width: maxX - minX + 1, height: maxY - minY + 1 })
    .resize({ width: 116, height: 146, fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
}

async function makeCell(base, subject, state, mult = 1) {
  const scaledBase = await sharp(base)
    .resize(W * mult, H * mult, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  const overlay = await sharp(Buffer.from(overlaySvg(subject, state)))
    .resize(W * mult, H * mult)
    .png()
    .toBuffer();

  return sharp({
    create: { width: W * mult, height: H * mult, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  })
    .composite([{ input: scaledBase }, { input: overlay }])
    .png()
    .toBuffer();
}

async function main() {
  const base = await cutBase();
  await fs.promises.writeFile(path.join(tmpDir, "console-machine-base-cut.png"), base);

  for (const subject of subjects) {
    for (const state of ["active", "resolved"]) {
      const id = subject[0];
      await fs.promises.writeFile(path.join(outDir, `console-${id}-${state}.png`), await makeCell(base, subject, state, 1));
      await fs.promises.writeFile(path.join(outDir, `console-${id}-${state}@2x.png`), await makeCell(base, subject, state, 2));
    }
  }

  for (const mult of [1, 2]) {
    const sheetW = W * subjects.length * mult;
    const sheetH = H * 2 * mult;
    const composites = [];
    const frames = {};

    for (let row = 0; row < 2; row++) {
      const state = row === 0 ? "active" : "resolved";
      for (let col = 0; col < subjects.length; col++) {
        const subject = subjects[col];
        const id = subject[0];
        composites.push({ input: await makeCell(base, subject, state, mult), left: col * W * mult, top: row * H * mult });
        if (mult === 1) {
          frames[`console_${id}_${state}`] = {
            frame: { x: col * W, y: row * H, w: W, h: H },
            rotated: false,
            trimmed: false,
            spriteSourceSize: { x: 0, y: 0, w: W, h: H },
            sourceSize: { w: W, h: H },
          };
        }
      }
    }

    const sheet = await sharp({
      create: { width: sheetW, height: sheetH, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
    })
      .composite(composites)
      .png()
      .toBuffer();
    await fs.promises.writeFile(`src/assets/sprites/mission-console-sheet${mult === 2 ? "@2x" : ""}.png`, sheet);

    if (mult === 1) {
      const animations = {};
      for (const [id] of subjects) animations[id] = [`console_${id}_active`, `console_${id}_resolved`];
      const meta = {
        app: "codex-imagegen-sharp",
        image: "mission-console-sheet.png",
        format: "RGBA8888",
        size: { w: W * subjects.length, h: H * 2 },
        scale: "1",
        cell: { w: W, h: H },
        rows: { 0: "active", 1: "resolved" },
        subjects: Object.fromEntries(subjects.map((s) => [s[0], { label: s[1], color: s[2], symbol: s[3] }])),
        states: ["active", "resolved"],
        animations,
      };
      await fs.promises.writeFile("src/assets/sprites/mission-console-sheet.json", JSON.stringify({ frames, meta }, null, 2));
    }
  }

  console.log(`created ${subjects.length * 2} mission console sprites plus sheet`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
