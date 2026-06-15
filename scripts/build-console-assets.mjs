import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const imageDir = path.resolve("src/assets/images");
await fs.mkdir(imageDir, { recursive: true });

const palettes = {
  greenhouse: { bg: "#071815", mid: "#0f3028", accent: "#70d68a", glow: "#c9f7c9", warm: "#f7d37a" },
  factory: { bg: "#0d1015", mid: "#211d17", accent: "#f6c85f", glow: "#ffe0a3", warm: "#ffb36b" },
  archive: { bg: "#0b0d18", mid: "#171925", accent: "#9f8cff", glow: "#e3d9ff", warm: "#f7d37a" },
  lab: { bg: "#071018", mid: "#0d1b26", accent: "#6be7d6", glow: "#9ff5e9", warm: "#f6c85f" },
};

function consoleSvg(name, palette) {
  const motif = {
    greenhouse: `
      <path d="M315 72 C284 78 262 104 258 142 C302 137 328 112 331 76Z" fill="${palette.accent}" opacity=".16"/>
      <path d="M266 138 C286 114 305 95 329 76" stroke="${palette.glow}" opacity=".22" stroke-width="3" fill="none"/>
      <circle cx="332" cy="354" r="54" fill="${palette.accent}" opacity=".08"/>
      <path d="M328 310 V378 M306 338 C325 334 338 320 344 304 M350 344 C332 344 318 354 312 374" stroke="${palette.glow}" opacity=".25" stroke-width="4" fill="none"/>`,
    factory: `
      <circle cx="312" cy="108" r="42" fill="${palette.accent}" opacity=".13"/>
      <path d="M312 52 V74 M312 142 V164 M256 108 H278 M346 108 H368 M272 68 L286 82 M338 134 L352 148 M352 68 L338 82 M286 134 L272 148" stroke="${palette.glow}" opacity=".22" stroke-width="6"/>
      <rect x="42" y="356" width="316" height="22" fill="#05080c" opacity=".42"/>
      <path d="M52 356 L66 378 M92 356 L106 378 M132 356 L146 378 M172 356 L186 378 M212 356 L226 378 M252 356 L266 378 M292 356 L306 378" stroke="${palette.accent}" opacity=".24" stroke-width="3"/>`,
    archive: `
      <path d="M286 62 H330 L354 86 V168 H286Z" fill="${palette.accent}" opacity=".12" stroke="${palette.glow}" stroke-opacity=".24" stroke-width="3"/>
      <path d="M330 62 V86 H354 M302 112 H338 M302 130 H332 M302 148 H322" stroke="${palette.glow}" opacity=".22" stroke-width="3"/>
      <path d="M42 350 C122 330 188 378 262 346 C304 328 340 330 378 346" stroke="${palette.accent}" opacity=".14" stroke-width="5" fill="none"/>`,
    lab: `
      <circle cx="322" cy="94" r="48" fill="${palette.accent}" opacity=".1" stroke="${palette.glow}" stroke-opacity=".18" stroke-width="3"/>
      <circle cx="322" cy="94" r="20" fill="none" stroke="${palette.accent}" stroke-opacity=".22" stroke-width="4"/>
      <path d="M48 350 H152 V318 H248 V350 H354" stroke="${palette.accent}" opacity=".16" stroke-width="5" fill="none"/>
      <circle cx="152" cy="318" r="8" fill="${palette.warm}" opacity=".42"/><circle cx="248" cy="350" r="8" fill="${palette.accent}" opacity=".42"/>`,
  }[name];

  return `<svg width="420" height="420" viewBox="0 0 420 420" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="panel" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${palette.mid}" stop-opacity=".96"/>
        <stop offset=".52" stop-color="${palette.bg}" stop-opacity=".94"/>
        <stop offset="1" stop-color="#02070b" stop-opacity=".98"/>
      </linearGradient>
      <radialGradient id="glow" cx="72%" cy="18%" r="62%">
        <stop offset="0" stop-color="${palette.accent}" stop-opacity=".28"/>
        <stop offset=".38" stop-color="${palette.accent}" stop-opacity=".08"/>
        <stop offset="1" stop-color="${palette.accent}" stop-opacity="0"/>
      </radialGradient>
      <filter id="soft">
        <feGaussianBlur stdDeviation="6"/>
      </filter>
    </defs>
    <rect x="14" y="18" width="392" height="384" rx="18" fill="#000" opacity=".35"/>
    <rect x="8" y="8" width="396" height="396" rx="16" fill="url(#panel)" stroke="${palette.accent}" stroke-opacity=".58" stroke-width="2"/>
    <rect x="8" y="8" width="396" height="396" rx="16" fill="url(#glow)"/>
    <rect x="22" y="48" width="376" height="1.5" fill="#fff" opacity=".08"/>
    <rect x="8" y="8" width="396" height="5" fill="${palette.accent}" opacity=".68"/>
    <rect x="26" y="26" width="78" height="3" fill="${palette.warm}" opacity=".54"/>
    <rect x="300" y="389" width="74" height="3" fill="${palette.accent}" opacity=".38"/>
    <path d="M24 92 H10 V24 H92 M328 10 H396 V92 M396 328 V396 H328 M92 396 H10 V328" fill="none" stroke="${palette.glow}" stroke-opacity=".18" stroke-width="3"/>
    <g opacity=".9">${motif}</g>
    <g opacity=".08">
      ${Array.from({ length: 8 }, (_, i) => `<path d="M${30 + i * 54} 70 L${-20 + i * 54} 390" stroke="${palette.accent}" stroke-width="1"/>`).join("")}
      ${Array.from({ length: 5 }, (_, i) => `<path d="M28 ${104 + i * 58} H392" stroke="${palette.glow}" stroke-width="1"/>`).join("")}
    </g>
    <circle cx="374" cy="34" r="18" fill="${palette.accent}" opacity=".14" filter="url(#soft)"/>
  </svg>`;
}

for (const [name, palette] of Object.entries(palettes)) {
  const png = path.join(imageDir, `console-${name}.png`);
  const webp = path.join(imageDir, `console-${name}.webp`);
  const avif = path.join(imageDir, `console-${name}.avif`);
  await sharp(Buffer.from(consoleSvg(name, palette))).png().toFile(png);
  await sharp(png).webp({ quality: 82, effort: 5 }).toFile(webp);
  await sharp(png).avif({ quality: 50, effort: 5 }).toFile(avif);
  console.log(`Generated ${path.relative(process.cwd(), webp)} and AVIF companion.`);
}
