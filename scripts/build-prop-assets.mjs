import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const outDir = path.resolve("src/assets/props");
await fs.mkdir(outDir, { recursive: true });

const palette = {
  shell: "#0c1a23",
  shell2: "#132b36",
  stroke: "#6be7d6",
  glow: "#9ff5e9",
  warm: "#f6c85f",
  red: "#c94b55",
  glass: "#173b46",
  shadow: "#02070b",
};

const props = {
  "prop-door-lab": doorSvg(),
  "prop-circuit-panel": circuitPanelSvg(),
  "prop-terminal": terminalSvg(),
  "prop-robot-dock": robotDockSvg(),
  "prop-message-console": messageConsoleSvg(),
  "prop-workbench": workbenchSvg(),
  "prop-journal": journalSvg(),
  "prop-nora-core": noraSvg(),
  "prop-window": windowSvg(),
  "prop-floor-trace": traceSvg(),
  "prop-greenhouse-pod": greenhousePodSvg(),
  "prop-factory-machine": factoryMachineSvg(),
  "prop-factory-core": factoryCoreSvg(),
  "prop-factory-conveyor": factoryConveyorSvg(),
  "prop-archive-shelf": archiveShelfSvg(),
  "prop-archive-card": archiveCardSvg(),
  "prop-archive-terminal": archiveTerminalSvg(),
};

for (const [name, svg] of Object.entries(props)) {
  const png = path.join(outDir, `${name}.png`);
  const webp = path.join(outDir, `${name}.webp`);
  const avif = path.join(outDir, `${name}.avif`);
  await sharp(Buffer.from(svg)).png().toFile(png);
  await sharp(png).webp({ quality: 86, effort: 5 }).toFile(webp);
  await sharp(png).avif({ quality: 54, effort: 5 }).toFile(avif);
  console.log(`Generated ${path.relative(process.cwd(), webp)}`);
}

function svg(content, w = 256, h = 256) {
  return `<svg width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <filter id="blur"><feGaussianBlur stdDeviation="5"/></filter>
      <linearGradient id="metal" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${palette.shell2}"/>
        <stop offset=".55" stop-color="${palette.shell}"/>
        <stop offset="1" stop-color="#050b10"/>
      </linearGradient>
      <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${palette.glass}" stop-opacity=".9"/>
        <stop offset="1" stop-color="#061019" stop-opacity=".94"/>
      </linearGradient>
    </defs>
    <rect width="${w}" height="${h}" fill="none"/>
    ${content}
  </svg>`;
}

function shadow(cx = 128, cy = 222, rx = 92, ry = 18) {
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${palette.shadow}" opacity=".42" filter="url(#blur)"/>`;
}

function doorSvg() {
  return svg(`${shadow(128, 226, 78, 18)}
    <rect x="62" y="26" width="132" height="188" rx="8" fill="#050a0f" opacity=".72"/>
    <rect x="76" y="38" width="104" height="166" rx="4" fill="url(#metal)" stroke="#4b6570" stroke-width="5"/>
    <rect x="92" y="60" width="72" height="126" rx="2" fill="#081018" opacity=".82" stroke="${palette.warm}" stroke-opacity=".34" stroke-width="3"/>
    <circle cx="128" cy="124" r="44" fill="none" stroke="${palette.stroke}" stroke-opacity=".36" stroke-width="5"/>
    <circle cx="128" cy="124" r="18" fill="none" stroke="${palette.glow}" stroke-opacity=".22" stroke-width="4"/>
    <circle cx="151" cy="124" r="5" fill="${palette.warm}" opacity=".62"/>
    <rect x="88" y="40" width="80" height="6" fill="${palette.stroke}" opacity=".28"/>
    <rect x="86" y="194" width="84" height="6" fill="${palette.shadow}" opacity=".55"/>`);
}

function circuitPanelSvg() {
  return svg(`${shadow(128, 222, 82, 16)}
    <rect x="38" y="58" width="180" height="126" rx="8" fill="url(#metal)" stroke="${palette.stroke}" stroke-opacity=".72" stroke-width="4"/>
    <rect x="58" y="78" width="140" height="74" rx="4" fill="url(#glass)" opacity=".9"/>
    <path d="M62 116 H94 L108 98 L130 134 L150 106 H194" fill="none" stroke="${palette.stroke}" stroke-opacity=".62" stroke-width="6" stroke-linecap="round"/>
    <circle cx="82" cy="154" r="9" fill="${palette.warm}"/>
    <circle cx="174" cy="154" r="9" fill="#8aa6b0"/>
    <path d="M74 92 H100 M156 92 H182" stroke="${palette.glow}" stroke-opacity=".26" stroke-width="4"/>
    <rect x="40" y="52" width="72" height="5" fill="${palette.warm}" opacity=".5"/>`);
}

function terminalSvg() {
  return svg(`${shadow(128, 224, 88, 18)}
    <rect x="42" y="58" width="172" height="118" rx="8" fill="url(#metal)" stroke="${palette.stroke}" stroke-opacity=".58" stroke-width="4"/>
    <rect x="62" y="78" width="132" height="70" rx="4" fill="#071018" stroke="${palette.glow}" stroke-opacity=".3" stroke-width="3"/>
    <path d="M82 114 H176 M82 130 H142" stroke="${palette.stroke}" stroke-opacity=".34" stroke-width="5"/>
    <rect x="102" y="176" width="52" height="12" fill="${palette.shell2}" stroke="${palette.stroke}" stroke-opacity=".4"/>
    <path d="M72 196 H184" stroke="#000" stroke-opacity=".48" stroke-width="8"/>
    <circle cx="176" cy="94" r="7" fill="${palette.warm}" opacity=".82"/>`);
}

function robotDockSvg() {
  return svg(`${shadow(128, 224, 88, 18)}
    <rect x="52" y="128" width="152" height="62" rx="8" fill="url(#metal)" stroke="${palette.stroke}" stroke-opacity=".42" stroke-width="4"/>
    <path d="M78 128 C86 92 104 74 128 74 C152 74 170 92 178 128" fill="#0b1720" stroke="${palette.stroke}" stroke-opacity=".48" stroke-width="5"/>
    <path d="M128 48 V72" stroke="${palette.stroke}" stroke-opacity=".48" stroke-width="5"/>
    <circle cx="128" cy="44" r="8" fill="${palette.warm}"/>
    <rect x="88" y="92" width="80" height="58" rx="12" fill="url(#glass)" stroke="${palette.stroke}" stroke-opacity=".68" stroke-width="4"/>
    <circle cx="110" cy="120" r="7" fill="${palette.glow}"/>
    <circle cx="146" cy="120" r="7" fill="${palette.glow}"/>
    <path d="M106 146 H150" stroke="${palette.warm}" stroke-opacity=".62" stroke-width="5" stroke-linecap="round"/>
    <path d="M82 190 L58 214 M174 190 L198 214" stroke="${palette.stroke}" stroke-opacity=".34" stroke-width="5"/>`);
}

function messageConsoleSvg() {
  return svg(`${shadow(128, 222, 88, 16)}
    <rect x="44" y="70" width="168" height="112" rx="8" fill="url(#metal)" stroke="${palette.stroke}" stroke-opacity=".56" stroke-width="4"/>
    <rect x="64" y="90" width="128" height="70" rx="4" fill="#09151d" stroke="${palette.warm}" stroke-opacity=".48" stroke-width="3"/>
    <path d="M82 112 H172 M82 130 H148 M82 148 H178" stroke="${palette.warm}" stroke-opacity=".58" stroke-width="5"/>
    <path d="M70 76 L94 76 M162 76 H188" stroke="${palette.glow}" stroke-opacity=".24" stroke-width="4"/>
    <circle cx="190" cy="174" r="8" fill="${palette.red}" opacity=".75"/>`);
}

function workbenchSvg() {
  return svg(`${shadow(128, 222, 98, 18)}
    <rect x="36" y="128" width="184" height="44" rx="4" fill="#3a2a22" stroke="${palette.warm}" stroke-opacity=".32" stroke-width="3"/>
    <rect x="48" y="94" width="160" height="42" rx="4" fill="url(#metal)" stroke="${palette.warm}" stroke-opacity=".42" stroke-width="3"/>
    <path d="M72 116 H136" stroke="${palette.warm}" stroke-opacity=".48" stroke-width="6"/>
    <path d="M150 78 L190 118 M184 78 L144 118" stroke="${palette.stroke}" stroke-opacity=".72" stroke-width="6" stroke-linecap="round"/>
    <circle cx="194" cy="74" r="10" fill="none" stroke="${palette.stroke}" stroke-width="5"/>
    <path d="M64 172 V214 M192 172 V214" stroke="#1a120d" stroke-width="8"/>`);
}

function journalSvg() {
  return svg(`${shadow(128, 222, 72, 14)}
    <rect x="72" y="50" width="112" height="152" rx="8" fill="#102533" stroke="${palette.warm}" stroke-opacity=".56" stroke-width="4"/>
    <rect x="88" y="68" width="80" height="116" rx="4" fill="#0a151d" stroke="${palette.stroke}" stroke-opacity=".38" stroke-width="3"/>
    <path d="M106 98 H150 M106 120 H150 M106 142 H138" stroke="${palette.glow}" stroke-opacity=".42" stroke-width="5"/>
    <path d="M82 52 V200" stroke="${palette.warm}" stroke-opacity=".32" stroke-width="6"/>
    <circle cx="158" cy="176" r="8" fill="${palette.stroke}" opacity=".62"/>`);
}

function noraSvg() {
  return svg(`${shadow(128, 224, 76, 14)}
    <circle cx="128" cy="126" r="72" fill="url(#metal)" stroke="${palette.stroke}" stroke-opacity=".48" stroke-width="4"/>
    <circle cx="128" cy="126" r="48" fill="#071018" stroke="${palette.stroke}" stroke-opacity=".48" stroke-width="5"/>
    <circle cx="128" cy="126" r="22" fill="${palette.stroke}" opacity=".16" stroke="${palette.glow}" stroke-opacity=".62" stroke-width="5"/>
    <circle cx="128" cy="126" r="7" fill="${palette.warm}" opacity=".82"/>
    <path d="M72 126 H46 M210 126 H184 M128 70 V44 M128 208 V182" stroke="${palette.stroke}" stroke-opacity=".22" stroke-width="5"/>`);
}

function windowSvg() {
  return svg(`${shadow(128, 222, 86, 13)}
    <rect x="46" y="60" width="164" height="112" rx="6" fill="#071018" opacity=".9" stroke="${palette.stroke}" stroke-opacity=".45" stroke-width="5"/>
    <rect x="66" y="78" width="124" height="76" fill="#0c2631" opacity=".55" stroke="${palette.glow}" stroke-opacity=".2" stroke-width="3"/>
    <path d="M128 78 V154 M66 116 H190" stroke="${palette.stroke}" stroke-opacity=".5" stroke-width="5"/>
    <circle cx="166" cy="100" r="24" fill="${palette.stroke}" opacity=".08"/>
    <path d="M76 164 H180" stroke="#000" stroke-opacity=".4" stroke-width="8"/>`);
}

function traceSvg() {
  return svg(`${shadow(128, 220, 82, 13)}
    <path d="M44 178 C78 132 94 184 122 126 C146 78 178 88 210 48" fill="none" stroke="${palette.stroke}" stroke-width="11" stroke-opacity=".26" stroke-linecap="round"/>
    <path d="M44 178 C78 132 94 184 122 126 C146 78 178 88 210 48" fill="none" stroke="${palette.glow}" stroke-width="4" stroke-opacity=".8" stroke-linecap="round"/>
    <circle cx="44" cy="178" r="10" fill="#071018" stroke="${palette.stroke}" stroke-width="5"/>
    <circle cx="122" cy="126" r="9" fill="#071018" stroke="${palette.warm}" stroke-width="5"/>
    <circle cx="210" cy="48" r="10" fill="#071018" stroke="${palette.stroke}" stroke-width="5"/>`);
}

function greenhousePodSvg() {
  return svg(`${shadow(128, 224, 92, 16)}
    <ellipse cx="128" cy="64" rx="74" ry="20" fill="${palette.warm}" opacity=".16" stroke="${palette.warm}" stroke-opacity=".42" stroke-width="4"/>
    <path d="M58 72 C68 128 62 174 82 206 H174 C194 174 188 128 198 72" fill="#0b221f" opacity=".42" stroke="#70d68a" stroke-opacity=".42" stroke-width="5"/>
    <path d="M86 78 C92 130 88 162 102 196 M170 78 C164 130 168 162 154 196" stroke="#c9f7c9" stroke-opacity=".18" stroke-width="4" fill="none"/>
    <ellipse cx="128" cy="202" rx="82" ry="18" fill="#06130f" stroke="#70d68a" stroke-opacity=".3" stroke-width="4"/>
    <path d="M128 70 L90 204 M128 70 L166 204" stroke="#f7d37a" stroke-opacity=".16" stroke-width="5"/>
    <circle cx="190" cy="96" r="8" fill="#70d68a" opacity=".72"/>`);
}

function factoryMachineSvg() {
  return svg(`${shadow(128, 224, 92, 16)}
    <rect x="42" y="72" width="172" height="118" rx="10" fill="url(#metal)" stroke="${palette.warm}" stroke-opacity=".56" stroke-width="4"/>
    <rect x="62" y="92" width="132" height="60" rx="6" fill="#0b1018" stroke="#8aa6b0" stroke-opacity=".34" stroke-width="3"/>
    <circle cx="82" cy="170" r="10" fill="#53636a" stroke="${palette.warm}" stroke-opacity=".32" stroke-width="3"/>
    <circle cx="174" cy="170" r="10" fill="#53636a" stroke="${palette.warm}" stroke-opacity=".32" stroke-width="3"/>
    <path d="M80 122 H176 M112 104 V140 M144 104 V140" stroke="${palette.warm}" stroke-opacity=".3" stroke-width="5"/>
    <rect x="54" y="68" width="70" height="5" fill="${palette.warm}" opacity=".48"/>
    <path d="M58 190 V214 M198 190 V214" stroke="#090b0f" stroke-width="8"/>`);
}

function factoryCoreSvg() {
  return svg(`${shadow(128, 224, 76, 14)}
    <circle cx="128" cy="126" r="76" fill="#211d17" opacity=".92" stroke="${palette.warm}" stroke-opacity=".52" stroke-width="5"/>
    <circle cx="128" cy="126" r="52" fill="#0b1018" stroke="${palette.warm}" stroke-opacity=".42" stroke-width="5"/>
    <circle cx="128" cy="126" r="24" fill="${palette.warm}" opacity=".18" stroke="#ffe0a3" stroke-opacity=".62" stroke-width="5"/>
    <path d="M128 48 V76 M128 176 V204 M50 126 H78 M178 126 H206" stroke="${palette.warm}" stroke-opacity=".28" stroke-width="6"/>
    <path d="M86 86 L106 106 M150 150 L170 170 M170 86 L150 106 M106 150 L86 170" stroke="#ffe0a3" stroke-opacity=".24" stroke-width="5"/>`);
}

function factoryConveyorSvg() {
  return svg(`${shadow(128, 220, 108, 12)}
    <rect x="28" y="94" width="200" height="68" rx="8" fill="#0b1018" stroke="#53636a" stroke-opacity=".78" stroke-width="5"/>
    <rect x="38" y="106" width="180" height="44" fill="#151920" opacity=".88"/>
    ${Array.from({ length: 7 }, (_, i) => `<circle cx="${52 + i * 26}" cy="128" r="9" fill="#53636a" stroke="${palette.warm}" stroke-opacity=".2" stroke-width="3"/>`).join("")}
    <path d="M44 106 L66 150 M82 106 L104 150 M120 106 L142 150 M158 106 L180 150 M196 106 L218 150" stroke="${palette.warm}" opacity=".18" stroke-width="4"/>`);
}

function archiveShelfSvg() {
  return svg(`${shadow(128, 224, 98, 14)}
    <rect x="36" y="44" width="184" height="160" rx="6" fill="#101521" stroke="#9f8cff" stroke-opacity=".38" stroke-width="4"/>
    ${[78, 118, 158].map((y) => `<rect x="50" y="${y}" width="156" height="10" fill="#1b2030" opacity=".86"/><path d="M50 ${y} H206" stroke="#e3d9ff" stroke-opacity=".18" stroke-width="2"/>`).join("")}
    ${Array.from({ length: 18 }, (_, i) => {
      const x = 58 + (i % 6) * 23;
      const y = 54 + Math.floor(i / 6) * 40;
      const col = ["#355c7d", "#6c5b7b", "#c06c84", "#4f6f52", "#8a6f3d", "#9f8cff"][i % 6];
      return `<rect x="${x}" y="${y}" width="13" height="28" fill="${col}" opacity=".72"/><path d="M${x + 4} ${y + 3} V${y + 24}" stroke="#fff" opacity=".16" stroke-width="1"/>`;
    }).join("")}`);
}

function archiveCardSvg() {
  return svg(`${shadow(128, 222, 82, 13)}
    <rect x="58" y="48" width="140" height="156" rx="8" fill="#241b2a" stroke="#9f8cff" stroke-opacity=".58" stroke-width="4"/>
    <rect x="78" y="72" width="100" height="108" rx="3" fill="#0a0d18" stroke="#e3d9ff" stroke-opacity=".2" stroke-width="3"/>
    <path d="M92 104 H164 M92 126 H150 M92 148 H170" stroke="#e3d9ff" opacity=".38" stroke-width="5"/>
    <rect x="72" y="56" width="46" height="4" fill="${palette.warm}" opacity=".62"/>
    <circle cx="178" cy="188" r="8" fill="#9f8cff" opacity=".68"/>`);
}

function archiveTerminalSvg() {
  return svg(`${shadow(128, 224, 94, 16)}
    <rect x="36" y="82" width="184" height="104" rx="10" fill="#0d1b26" stroke="#9f8cff" stroke-opacity=".5" stroke-width="4"/>
    <rect x="58" y="102" width="140" height="52" rx="4" fill="#0a0d18" stroke="#e3d9ff" stroke-opacity=".24" stroke-width="3"/>
    <path d="M80 126 H176 M80 142 H134" stroke="#9f8cff" opacity=".42" stroke-width="5"/>
    <rect x="92" y="186" width="72" height="12" fill="#171925" stroke="#9f8cff" stroke-opacity=".34"/>
    <path d="M70 206 H186" stroke="#000" stroke-opacity=".5" stroke-width="8"/>`);
}
