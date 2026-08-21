import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const root = process.cwd();
// Il catalogo autorevole è quello GDScript. Nasceva come trascrizione di
// `src/core/RewardCatalog.ts` — lo dice il suo stesso commento — ma è andato
// avanti da solo: al momento del passaggio aveva 58 voci contro le 53 del
// TypeScript. Il foglio premi veniva quindi generato da una copia vecchia di
// cinque cosmetici, che nel gioco esistevano senza illustrazione.
const catalogPath = path.join(root, "godot/scripts/game/reward_catalog.gd");
const godotSpriteDir = path.join(root, "godot/assets/shop");

// Presentazioni native Godot gia' approvate o in attesa del loro contratto
// semantico. Non duplicano prezzi o regole: servono solo a riservare nel foglio
// premi le illustrazioni C-G4. Se una voce entra anche nel catalogo TS, il merge
// in fondo evita automaticamente il doppione.
// **Nessuna illustrazione riservata.** (21 agosto 2026) Qui stavano radar e
// torcia, tenuti in caldo per C-G4. Ritirati: chiedono una resa che non esiste —
// un segnale sulla cassa e un cono luminoso — ed e' esattamente il difetto del
// 6 agosto, vendere potenziamenti che non fanno niente. Il foglio premi si
// genera dal solo catalogo, che e' la sola fonte di verita'.
const expeditionModuleArt = [];


const catalogText = fs.readFileSync(catalogPath, "utf8");

// Le voci GDScript stanno una per riga e non hanno un ordine fisso delle chiavi
// (`mondo` compare a volte fra `id` e `slot`): si legge per chiave, non per
// posizione, altrimenti basta riordinare un campo per perdere silenziosamente
// metà catalogo.
function parseCatalog(text) {
  return [...text.matchAll(/\{"id":[^\n]*\}/g)].map(([line]) => {
    const str = (key) => line.match(new RegExp(`"${key}": *"([^"]*)"`))?.[1];
    const num = (key) => {
      const raw = line.match(new RegExp(`"${key}": *(0x[0-9a-fA-F]+|\\d+)`))?.[1];
      return raw === undefined ? undefined : Number(raw);
    };
    return {
      id: str("id"),
      slot: str("slot"),
      name: str("name"),
      cost: num("cost"),
      color: num("color"),
      glyph: str("glyph"),
      minLevel: num("minLevel"),
    };
  });
}

function hex(color, fallback = "#6be7d6") {
  if (typeof color !== "number") return fallback;
  return `#${color.toString(16).padStart(6, "0")}`;
}

function slotAccent(item) {
  const accents = {
    bot: "#6be7d6",
    avatar: "#74f0c5",
    accessory: "#f6c85f",
    pet: "#9ff5e9",
    emblem: "#ffd75e",
    module: "#8ff6d2",
    upgrade: "#9f8cff",
    decor: "#7ad7ff",
  };
  return hex(item.color, accents[item.slot] ?? "#6be7d6");
}

function iconBody(item, accent) {
  const glyph = item.glyph ?? "";
  const commonGlyph = `<text x="64" y="78" text-anchor="middle" font-family="Arial, sans-serif" font-size="${glyph.length > 1 ? 28 : 36}" font-weight="700" fill="#f8fbff">${escapeXml(glyph)}</text>`;
  if (item.slot === "bot") {
    return `
      <rect x="39" y="34" width="50" height="52" rx="16" fill="#0b2732" stroke="${accent}" stroke-width="4"/>
      <rect x="47" y="48" width="34" height="16" rx="8" fill="#041018" stroke="#d9ffff" stroke-opacity=".35"/>
      <circle cx="57" cy="56" r="4" fill="${accent}"/><circle cx="71" cy="56" r="4" fill="${accent}"/>
      <path d="M50 77 Q64 89 78 77" fill="none" stroke="#f6c85f" stroke-width="3" stroke-linecap="round"/>
      <circle cx="64" cy="28" r="7" fill="${accent}" opacity=".95"/>`;
  }
  if (item.slot === "avatar") {
    return `
      <path d="M44 44 Q64 28 84 44 L92 88 Q64 101 36 88 Z" fill="#123544" stroke="${accent}" stroke-width="4"/>
      <path d="M54 43 L64 62 L74 43" fill="none" stroke="#f6c85f" stroke-width="4" stroke-linecap="round"/>
      <circle cx="64" cy="34" r="13" fill="#09202b" stroke="${accent}" stroke-width="4"/>
      <rect x="56" y="31" width="22" height="9" rx="5" fill="#d9ffff" opacity=".75"/>`;
  }
  if (item.slot === "accessory") {
    return `
      <path d="M35 65 Q64 31 93 65 Q78 92 50 92 Q39 82 35 65Z" fill="#102631" stroke="${accent}" stroke-width="4"/>
      <circle cx="64" cy="64" r="20" fill="#05131b" stroke="#f6c85f" stroke-opacity=".65" stroke-width="3"/>
      ${commonGlyph}`;
  }
  if (item.slot === "pet") {
    if (item.id === "pet-dog") {
      return `
      <ellipse cx="64" cy="76" rx="31" ry="20" fill="#d9a15f" stroke="${accent}" stroke-width="3"/>
      <circle cx="64" cy="52" r="21" fill="#e7b46f" stroke="#fff0d6" stroke-opacity=".35" stroke-width="2"/>
      <ellipse cx="46" cy="48" rx="9" ry="18" fill="#8b5a32"/>
      <ellipse cx="82" cy="48" rx="9" ry="18" fill="#8b5a32"/>
      <circle cx="56" cy="49" r="3" fill="#1b120c"/><circle cx="72" cy="49" r="3" fill="#1b120c"/>
      <circle cx="64" cy="58" r="4" fill="#1b120c"/>
      <path d="M84 76 Q104 59 109 76" fill="none" stroke="${accent}" stroke-width="6" stroke-linecap="round"/>
      <path d="M55 65 Q64 72 73 65" fill="none" stroke="#fff0d6" stroke-width="3" stroke-linecap="round"/>`;
    }
    if (item.id === "pet-cat") {
      return `
      <ellipse cx="64" cy="76" rx="28" ry="20" fill="${accent}" opacity=".9" stroke="#f8fbff" stroke-opacity=".28" stroke-width="2"/>
      <circle cx="64" cy="53" r="22" fill="${accent}" stroke="#07151d" stroke-opacity=".28" stroke-width="2"/>
      <path d="M45 40 L53 17 L64 41 Z M83 40 L75 17 L64 41 Z" fill="${accent}" stroke="#f8fbff" stroke-opacity=".28" stroke-width="2"/>
      <circle cx="56" cy="51" r="3" fill="#07151d"/><circle cx="72" cy="51" r="3" fill="#07151d"/>
      <path d="M55 62 H32 M55 66 H34 M73 62 H96 M73 66 H94" stroke="#f8fbff" stroke-width="2" stroke-linecap="round" opacity=".7"/>
      <path d="M85 78 Q107 80 99 57" fill="none" stroke="${accent}" stroke-width="7" stroke-linecap="round"/>`;
    }
    if (item.id === "pet-rabbit") {
      return `
      <ellipse cx="64" cy="80" rx="30" ry="19" fill="#f2f7ff" stroke="${accent}" stroke-width="3"/>
      <circle cx="64" cy="55" r="20" fill="#ffffff" stroke="#cfdbea" stroke-width="2"/>
      <rect x="49" y="16" width="10" height="33" rx="5" fill="#f2f7ff" stroke="#cfdbea" stroke-width="2"/>
      <rect x="69" y="15" width="10" height="34" rx="5" fill="#f2f7ff" stroke="#cfdbea" stroke-width="2"/>
      <rect x="53" y="22" width="3" height="22" rx="2" fill="${accent}" opacity=".35"/>
      <rect x="73" y="21" width="3" height="23" rx="2" fill="${accent}" opacity=".35"/>
      <circle cx="57" cy="54" r="3" fill="#07151d"/><circle cx="72" cy="54" r="3" fill="#07151d"/>
      <circle cx="65" cy="62" r="3" fill="#ff9ad2"/>
      <circle cx="92" cy="82" r="8" fill="#ffffff" opacity=".88"/>`;
    }
    return `
      <circle cx="64" cy="64" r="35" fill="${accent}" opacity=".12"/>
      <circle cx="64" cy="64" r="24" fill="#07151d" stroke="${accent}" stroke-width="4"/>
      <circle cx="77" cy="50" r="7" fill="#ffffff" opacity=".55"/>
      <path d="M34 61 C43 42 52 33 64 29 C76 33 85 42 94 61" fill="none" stroke="${accent}" stroke-width="3" stroke-linecap="round" opacity=".75"/>
      ${commonGlyph}`;
  }
  if (item.slot === "emblem") {
    return `
      <circle cx="64" cy="62" r="33" fill="#221b0b" stroke="${accent}" stroke-width="5"/>
      <circle cx="64" cy="62" r="22" fill="#0b1821" stroke="#f6c85f" stroke-width="2" opacity=".95"/>
      <path d="M45 94 L54 76 L64 84 L74 76 L83 94" fill="#34260e" stroke="${accent}" stroke-width="3"/>
      ${commonGlyph}`;
  }
  if (item.slot === "module") {
    if (item.id === "module-tank") {
      return `
      <path d="M43 35 H82 L91 48 V91 L82 101 H43 L34 91 V48 Z" fill="#0a2831" stroke="${accent}" stroke-width="4"/>
      <rect x="49" y="25" width="28" height="13" rx="5" fill="#183f48" stroke="#d9ffff" stroke-width="3"/>
      <path d="M47 82 V57 Q47 48 56 48 H69 Q79 48 79 57 V82" fill="#133b43" stroke="#f6c85f" stroke-width="3"/>
      <path d="M63 55 V75 M53 65 H73" stroke="#fff1b8" stroke-width="5" stroke-linecap="round"/>`;
    }
    if (item.id === "module-coil") {
      return `
      <circle cx="64" cy="64" r="34" fill="#071b24" stroke="${accent}" stroke-width="5"/>
      <circle cx="64" cy="64" r="25" fill="none" stroke="#f6c85f" stroke-width="4"/>
      <circle cx="64" cy="64" r="15" fill="#102f39" stroke="${accent}" stroke-width="4"/>
      <circle cx="64" cy="64" r="5" fill="#fff1b8"/>
      <path d="M28 48 H17 V80 H28 M100 48 H111 V80 H100" fill="none" stroke="#d9ffff" stroke-width="5" stroke-linecap="round"/>`;
    }
    if (item.id === "module-stride") {
      return `
      <path d="M34 39 H59 L63 69 L52 95 H25 L38 75 Z" fill="#15343c" stroke="${accent}" stroke-width="4"/>
      <path d="M66 32 H91 L95 62 L84 88 H57 L70 68 Z" fill="#0b2732" stroke="#ffd778" stroke-width="4"/>
      <path d="M29 103 H60 M67 96 H99" stroke="#d9ffff" stroke-width="5" stroke-linecap="round"/>
      <path d="M18 58 H31 M13 70 H28 M98 45 H113" stroke="${accent}" stroke-width="4" stroke-linecap="round" opacity=".8"/>`;
    }
    if (item.id === "module-radar") {
      return `
      <path d="M31 82 H92 L86 104 H38 Z" fill="#16343d" stroke="#fff1b8" stroke-width="4"/>
      <rect x="39" y="68" width="45" height="20" rx="5" fill="#0b2732" stroke="${accent}" stroke-width="4"/>
      <circle cx="64" cy="70" r="6" fill="#ffd75e"/>
      <path d="M64 59 V47 M52 52 Q64 39 76 52 M43 43 Q64 20 85 43" fill="none" stroke="${accent}" stroke-width="4" stroke-linecap="round"/>`;
    }
    return `
      <path d="M30 72 L57 54 L69 70 L41 88 Z" fill="#5a3824" stroke="#fff1b8" stroke-width="4"/>
      <path d="M58 52 L72 43 L82 57 L68 68 Z" fill="#ffd75e" stroke="#fff1b8" stroke-width="3"/>
      <path d="M80 49 L113 25 L105 61 L118 75 L84 61 Z" fill="${accent}" opacity=".42"/>
      <path d="M83 51 L111 36 M85 58 L110 64" stroke="#fff4c2" stroke-width="3" stroke-linecap="round"/>`;
  }
  if (item.slot === "upgrade") {
    return `
      <path d="M64 24 L96 64 L64 104 L32 64 Z" fill="#15112d" stroke="${accent}" stroke-width="4"/>
      <circle cx="64" cy="64" r="19" fill="#07151d" stroke="#f6c85f" stroke-width="3"/>
      <path d="M64 36 L72 56 L92 64 L72 72 L64 92 L56 72 L36 64 L56 56 Z" fill="${accent}" opacity=".42"/>
      ${commonGlyph}`;
  }
  return `
    <rect x="34" y="38" width="60" height="54" rx="10" fill="#0d202a" stroke="${accent}" stroke-width="4"/>
    <path d="M42 76 H86 M46 58 H82 M54 42 V92 M74 42 V92" stroke="#f6c85f" stroke-width="3" opacity=".75"/>
    ${commonGlyph}`;
}

function iconSvg(item) {
  const accent = slotAccent(item);
  const level = item.minLevel ? `<text x="104" y="115" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#f6c85f">L${item.minLevel}</text>` : "";
  const rare = item.cost >= 1500 ? `<path d="M24 24 L35 20 L31 31 Z M102 28 L111 35 L99 39 Z" fill="#f6c85f" opacity=".9"/>` : "";
  return `
    <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
      <defs>
        <radialGradient id="bg" cx="50%" cy="38%" r="72%">
          <stop offset="0%" stop-color="${accent}" stop-opacity=".28"/>
          <stop offset="62%" stop-color="#0b2430" stop-opacity=".98"/>
          <stop offset="100%" stop-color="#041017"/>
        </radialGradient>
        <filter id="glow" x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="2.4" result="blur"/>
          <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
      </defs>
      <rect x="6" y="6" width="116" height="116" rx="18" fill="url(#bg)" stroke="${accent}" stroke-width="3"/>
      <path d="M20 28 C42 13 86 13 108 28" stroke="#ffffff" stroke-opacity=".13" stroke-width="6" fill="none" stroke-linecap="round"/>
      <g filter="url(#glow)">${iconBody(item, accent)}</g>
      ${rare}
      ${level}
    </svg>`;
}

function escapeXml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

async function buildImages(items) {
  const cell = 128;
  const cols = 8;
  const rows = Math.ceil(items.length / cols);
  const sheetW = cols * cell;
  const sheetH = rows * cell;
  const composites = [];
  const frames = {};

  for (const [index, item] of items.entries()) {
    const x = (index % cols) * cell;
    const y = Math.floor(index / cols) * cell;
    const input = await sharp(Buffer.from(iconSvg(item))).png().toBuffer();
    composites.push({ input, left: x, top: y });
    frames[item.id] = {
      frame: { x, y, w: cell, h: cell },
      rotated: false,
      trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w: cell, h: cell },
      sourceSize: { w: cell, h: cell },
    };
  }

  await sharp({
    create: {
      width: sheetW,
      height: sheetH,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite(composites)
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(path.join(godotSpriteDir, "reward-items-sheet.png"));

  const atlasJson = `${JSON.stringify({
      frames,
      meta: {
        app: "scripts/build-reward-assets.mjs",
        image: "reward-items-sheet.png",
        format: "RGBA8888",
        size: { w: sheetW, h: sheetH },
        scale: "1",
      },
    }, null, 2)}\n`;
  fs.writeFileSync(path.join(godotSpriteDir, "reward-items-sheet.json"), atlasJson);
}

const catalogItems = parseCatalog(catalogText);
const catalogIds = new Set(catalogItems.map((item) => item.id));
const items = [
  ...catalogItems,
  ...expeditionModuleArt.filter((item) => !catalogIds.has(item.id)),
];
if (items.length === 0) {
  throw new Error("Il catalogo premi non ha prodotto nessuna voce.");
}

fs.mkdirSync(godotSpriteDir, { recursive: true });
await buildImages(items);
console.log(`Foglio premi Godot rigenerato: ${items.length} icone.`);
