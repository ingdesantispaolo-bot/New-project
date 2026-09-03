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
// Solo gli slot realmente esposti in bottega ricevono una cella nell'atlante.
// Gli strumenti di campo sono voci del catalogo perché il salvataggio li legge,
// ma vengono consegnati nel mondo: tenerne icone nel foglio premi sarebbe arte
// generata e mai vista.
const SHOP_SLOTS = new Set(["bot", "avatar", "accessory", "memento", "module", "pet", "emblem", "upgrade", "decor"]);


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
      motif: str("motif"),
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
    memento: "#c7b8ff",
    pet: "#9ff5e9",
    emblem: "#ffd75e",
    module: "#8ff6d2",
    upgrade: "#9f8cff",
    decor: "#7ad7ff",
  };
  return hex(item.color, accents[item.slot] ?? "#6be7d6");
}

function mementoBody(item, accent) {
  const motifs = {
    vine_book: `<path d="M30 43 Q48 33 64 47 Q80 33 98 43 V91 Q80 82 64 96 Q48 82 30 91Z" fill="#102a31" stroke="${accent}" stroke-width="4"/><path d="M64 48V94 M38 54Q50 47 59 54 M90 55Q77 48 69 57" fill="none" stroke="#f8fbff" stroke-opacity=".65" stroke-width="3"/><path d="M39 88Q29 72 42 62Q53 54 51 39" fill="none" stroke="#8ff6a4" stroke-width="4"/><ellipse cx="36" cy="69" rx="6" ry="3" fill="#8ff6a4" transform="rotate(-35 36 69)"/>`,
    step_stone: `<path d="M31 91H58V74H79V56H101V101H31Z" fill="#182832" stroke="${accent}" stroke-width="4" stroke-linejoin="round"/><path d="M39 84H57 M65 67H78 M86 49H99" stroke="#fff1b8" stroke-width="4" stroke-linecap="round"/><path d="M42 42L58 30L75 42L58 54Z" fill="${accent}" opacity=".55"/>`,
    signal_buoy: `<path d="M49 82L55 42H73L79 82Z" fill="#15313a" stroke="${accent}" stroke-width="4"/><path d="M42 82H86L78 100H50Z" fill="#0a1d26" stroke="#f8fbff" stroke-opacity=".55" stroke-width="3"/><circle cx="64" cy="36" r="8" fill="#ffd75e"/><circle cx="64" cy="57" r="5" fill="${accent}"/><path d="M28 101Q40 94 52 101T76 101T100 101" fill="none" stroke="${accent}" stroke-width="4"/>`,
    rail_caliper: `<path d="M25 84H103 M34 74V94 M94 74V94" stroke="#d7e1e5" stroke-width="7" stroke-linecap="round"/><path d="M42 40V72H58V57H86V72H94V40" fill="none" stroke="${accent}" stroke-width="5" stroke-linejoin="round"/><path d="M49 48H87" stroke="#ffd75e" stroke-width="4"/><circle cx="64" cy="57" r="5" fill="#07151d" stroke="#fff1b8" stroke-width="2"/>`,
    resonant_seed: `<path d="M64 31C88 46 91 73 64 96C37 73 40 46 64 31Z" fill="#142735" stroke="${accent}" stroke-width="4"/><path d="M64 42V84 M64 59Q48 55 44 46 M64 70Q80 66 86 53" fill="none" stroke="#fff1b8" stroke-width="3"/><path d="M29 54Q20 64 29 74 M99 54Q108 64 99 74 M21 44Q5 64 21 84 M107 44Q123 64 107 84" fill="none" stroke="${accent}" stroke-width="3" stroke-linecap="round"/>`,
    mosaic_tile: `<path d="M64 24L105 64L64 105L23 64Z" fill="#17252d" stroke="${accent}" stroke-width="4"/><path d="M64 24V105 M23 64H105 M35 36L93 93 M93 36L35 93" stroke="#f8fbff" stroke-opacity=".6" stroke-width="3"/><path d="M64 37L91 64L64 91L37 64Z" fill="${accent}" opacity=".35"/>`,
    circuit_coil: `<path d="M22 64H38C38 43 52 33 64 33C83 33 94 47 94 64C94 82 81 95 64 95C48 95 38 84 38 70C38 55 49 45 63 45C75 45 83 53 83 64C83 75 75 83 65 83C55 83 49 76 49 68C49 59 55 55 63 55" fill="none" stroke="${accent}" stroke-width="5" stroke-linecap="round"/><circle cx="22" cy="64" r="6" fill="#ffd75e"/><circle cx="106" cy="64" r="6" fill="#ffd75e"/>`,
    map_needle: `<circle cx="64" cy="64" r="38" fill="#0e2630" stroke="${accent}" stroke-width="4"/><path d="M64 20V108M20 64H108" stroke="#f8fbff" stroke-opacity=".42" stroke-width="3"/><path d="M64 34L76 68L64 94L52 60Z" fill="${accent}" stroke="#fff1b8" stroke-width="3"/><circle cx="64" cy="64" r="6" fill="#07151d"/>`,
    pollen_vial: `<path d="M49 30H79 M54 30V45L43 59V95Q64 105 85 95V59L74 45V30" fill="#102a31" stroke="${accent}" stroke-width="4" stroke-linejoin="round"/><path d="M46 73Q64 64 82 73V94Q64 101 46 94Z" fill="${accent}" opacity=".35"/><circle cx="57" cy="76" r="4" fill="#ffd75e"/><circle cx="69" cy="86" r="3" fill="#fff1b8"/><circle cx="74" cy="72" r="2.5" fill="#ffd75e"/>`,
    order_hourglass: `<path d="M38 28H90M38 100H90M45 31C45 48 55 54 64 64C55 74 45 80 45 97M83 31C83 48 73 54 64 64C73 74 83 80 83 97" fill="#122730" stroke="${accent}" stroke-width="4" stroke-linecap="round"/><path d="M51 87L64 70L77 87Z" fill="#f6c85f"/><path d="M58 49H70L64 59Z" fill="#f6c85f" opacity=".75"/>`,
    rule_key: `<circle cx="44" cy="54" r="18" fill="#10232c" stroke="${accent}" stroke-width="5"/><circle cx="44" cy="54" r="7" fill="#07151d" stroke="#fff1b8" stroke-width="3"/><path d="M58 66L94 102M72 79L84 67M83 90L96 78" stroke="${accent}" stroke-width="7" stroke-linecap="square"/><path d="M30 31H98" stroke="#ffd75e" stroke-width="3" stroke-dasharray="7 6"/>`,
    orbit_ring: `<ellipse cx="64" cy="64" rx="42" ry="22" fill="none" stroke="${accent}" stroke-width="4" transform="rotate(-24 64 64)"/><ellipse cx="64" cy="64" rx="42" ry="22" fill="none" stroke="#fff1b8" stroke-opacity=".7" stroke-width="3" transform="rotate(32 64 64)"/><circle cx="64" cy="64" r="12" fill="#102631" stroke="${accent}" stroke-width="4"/><circle cx="96" cy="42" r="6" fill="#ffd75e"/><circle cx="31" cy="77" r="5" fill="${accent}"/>`,
    chorus_shell: `<path d="M92 88C76 104 42 99 34 76C25 51 45 29 68 33C89 36 101 57 92 74C84 89 60 91 51 76C43 62 53 49 66 49C79 49 84 61 79 70C75 78 64 78 60 71" fill="#17262f" stroke="${accent}" stroke-width="5" stroke-linecap="round"/><path d="M36 89L25 102M46 94L40 110" stroke="#fff1b8" stroke-width="3"/>`,
    network_node: `<path d="M64 31V97M31 64H97M41 41L87 87M87 41L41 87" stroke="${accent}" stroke-width="4"/><circle cx="64" cy="64" r="18" fill="#0d252f" stroke="#fff1b8" stroke-width="4"/><circle cx="64" cy="28" r="7" fill="${accent}"/><circle cx="100" cy="64" r="7" fill="${accent}"/><circle cx="64" cy="100" r="7" fill="${accent}"/><circle cx="28" cy="64" r="7" fill="${accent}"/>`,
    verb_gate: `<path d="M29 96V37Q64 18 99 37V96" fill="#112833" stroke="${accent}" stroke-width="5"/><rect x="38" y="49" width="16" height="28" rx="4" fill="#07151d" stroke="#fff1b8" stroke-width="3"/><rect x="56" y="44" width="16" height="38" rx="4" fill="#07151d" stroke="#ffd75e" stroke-width="3"/><rect x="74" y="49" width="16" height="28" rx="4" fill="#07151d" stroke="#fff1b8" stroke-width="3"/><path d="M45 63H48M63 63H66M81 63H84" stroke="${accent}" stroke-width="4"/>`,
    pressure_ampoule: `<path d="M43 31V52C31 61 31 87 49 98C58 103 64 95 64 86V42C64 34 57 28 50 28Z" fill="#102a34" stroke="${accent}" stroke-width="4"/><path d="M85 31V52C97 61 97 87 79 98C70 103 64 95 64 86V42C64 34 71 28 78 28Z" fill="#102a34" stroke="#fff1b8" stroke-width="4"/><path d="M37 76H91" stroke="#69c8ff" stroke-width="5"/><circle cx="64" cy="76" r="5" fill="#07151d"/>`,
    echo_fork: `<path d="M43 29V62C43 80 52 88 64 88C76 88 85 80 85 62V29M64 88V105" fill="none" stroke="${accent}" stroke-width="7" stroke-linecap="round"/><path d="M31 40Q23 52 31 64M97 40Q105 52 97 64M23 31Q7 52 23 73M105 31Q121 52 105 73" fill="none" stroke="#fff1b8" stroke-opacity=".75" stroke-width="3"/>`,
    root_medallion: `<circle cx="64" cy="58" r="34" fill="#1d241f" stroke="${accent}" stroke-width="5"/><path d="M64 31V78M64 48L48 39M64 56L82 43M64 66L49 76M64 72L80 83M48 39L39 32M82 43L91 34" fill="none" stroke="#d8be79" stroke-width="4" stroke-linecap="round"/><path d="M50 92L43 108M78 92L85 108" stroke="${accent}" stroke-width="4"/>`,
    storm_clasp: `<path d="M28 43L57 34L64 55L51 64L64 77L56 97L28 86L43 64Z" fill="#102832" stroke="${accent}" stroke-width="4"/><path d="M100 43L71 34L64 55L77 64L64 77L72 97L100 86L85 64Z" fill="#17242e" stroke="#fff1b8" stroke-width="4"/><path d="M64 48L57 62L67 62L60 81" fill="none" stroke="#ffd75e" stroke-width="4" stroke-linecap="round"/>`,
    scale_shard: `<path d="M39 25L97 38L87 102L28 85Z" fill="#182831" stroke="${accent}" stroke-width="5" stroke-linejoin="round"/><path d="M43 41L84 51M39 56L80 66M35 71L76 81" stroke="#fff1b8" stroke-opacity=".65" stroke-width="3"/><path d="M55 37L48 46M70 41L62 52M84 45L76 57" stroke="#ffd75e" stroke-width="3"/><path d="M61 25L57 45L70 57L55 72L61 92" fill="none" stroke="#07151d" stroke-width="5"/>`,
    spore_capsule: `<path d="M64 24C88 24 101 44 96 67C91 91 79 105 64 105C49 105 37 91 32 67C27 44 40 24 64 24Z" fill="#102d2d" stroke="${accent}" stroke-width="5"/><path d="M39 67Q64 55 89 67" fill="none" stroke="#fff1b8" stroke-opacity=".6" stroke-width="3"/><circle cx="51" cy="57" r="6" fill="${accent}" opacity=".7"/><circle cx="69" cy="44" r="5" fill="#ffd75e"/><circle cx="77" cy="73" r="7" fill="${accent}" opacity=".45"/><circle cx="55" cy="83" r="4" fill="#fff1b8"/>`,
    era_dial: `<circle cx="64" cy="64" r="40" fill="#17252d" stroke="${accent}" stroke-width="5"/><path d="M64 27V38M64 90V101M27 64H38M90 64H101" stroke="#fff1b8" stroke-width="4"/><path d="M64 64L64 39M64 64L84 51M64 64L82 79M64 64L48 84" stroke="${accent}" stroke-width="4" stroke-linecap="round"/><circle cx="64" cy="64" r="7" fill="#ffd75e"/>`,
    synthesis_prism: `<path d="M64 22L101 48L87 94L41 105L23 62Z" fill="#151a30" stroke="${accent}" stroke-width="5" stroke-linejoin="round"/><path d="M64 22L64 73M101 48L64 73M87 94L64 73M41 105L64 73M23 62L64 73" stroke="#f8fbff" stroke-opacity=".6" stroke-width="3"/><path d="M64 37L86 53L78 80L51 87L40 61Z" fill="${accent}" opacity=".45"/><circle cx="64" cy="64" r="8" fill="#fff1b8"/>`,
  };
  return motifs[item.motif] ?? `<path d="M64 25L101 64L64 103L27 64Z" fill="#142630" stroke="${accent}" stroke-width="5"/>`;
}

function iconBody(item, accent) {
  const glyph = item.glyph ?? "";
  const commonGlyph = `<text x="64" y="78" text-anchor="middle" font-family="Arial, sans-serif" font-size="${glyph.length > 1 ? 28 : 36}" font-weight="700" fill="#f8fbff">${escapeXml(glyph)}</text>`;
  if (item.slot === "memento") {
    return mementoBody(item, accent);
  }
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
    if (item.id === "module-hush") {
      return `
      <path d="M31 82 C44 78 51 72 57 58 L66 35 L82 40 L74 65 C69 81 57 94 40 98 L26 95 Z" fill="#15343c" stroke="${accent}" stroke-width="4"/>
      <path d="M72 77 C84 75 95 80 102 90 L111 103 L93 106 L81 94 L62 93 Z" fill="#0b2732" stroke="#fff1b8" stroke-width="4"/>
      <path d="M45 50 Q57 45 68 51 M37 69 Q48 65 58 70" fill="none" stroke="#f6c85f" stroke-width="3" stroke-linecap="round"/>
      <path d="M94 48 C101 43 108 43 114 48 M98 58 C105 54 112 55 117 60" fill="none" stroke="${accent}" stroke-width="3" stroke-linecap="round" opacity=".8"/>`;
    }
    if (item.id === "module-ballast") {
      return `
      <path d="M31 48 H97 L91 86 H37 Z" fill="#18323b" stroke="${accent}" stroke-width="4"/>
      <path d="M42 48 V39 H86 V48 M47 86 L43 104 H61 L65 86 M82 86 L87 104 H104 L99 80" fill="none" stroke="#fff1b8" stroke-width="5" stroke-linejoin="round"/>
      <path d="M42 61 H86" stroke="#f6c85f" stroke-width="5" stroke-linecap="round"/>
      <circle cx="52" cy="75" r="7" fill="${accent}" opacity=".72"/><circle cx="76" cy="75" r="7" fill="${accent}" opacity=".72"/>`;
    }
    if (item.id === "module-stride") {
      return `
      <path d="M40 46 L64 40 L70 74 L86 82 L88 96 L44 96 L36 74 Z" fill="#3a2a17" stroke="${accent}" stroke-width="4" stroke-linejoin="round"/>
      <path d="M40 58 H68 M42 68 H70 M43 78 H74" stroke="#fff1b8" stroke-width="4" stroke-linecap="round"/>
      <path d="M96 44 H120 M92 60 H116 M98 76 H118" stroke="${accent}" stroke-width="4" stroke-linecap="round" opacity=".82"/>
      <circle cx="52" cy="42" r="6" fill="#ffd75e"/>`;
    }
    if (item.id === "module-lantern") {
      return `
      <path d="M30 40 Q18 64 30 88 L46 78 Q40 64 46 50 Z" fill="#2b2210" stroke="${accent}" stroke-width="4" stroke-linejoin="round"/>
      <circle cx="46" cy="64" r="11" fill="#fff4c2" stroke="#ffd75e" stroke-width="3"/>
      <path d="M56 64 L120 30 L120 98 Z" fill="${accent}" opacity=".34"/>
      <path d="M58 64 L116 42 M58 64 L116 86" stroke="#fff4c2" stroke-width="3" stroke-linecap="round" opacity=".85"/>`;
    }
    if (item.id === "module-divining") {
      return `
      <path d="M62 104 L62 68 M62 68 L36 34 M62 68 L88 34" fill="none" stroke="#7d6242" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M62 104 L62 68 M62 68 L36 34 M62 68 L88 34" fill="none" stroke="${accent}" stroke-width="3" stroke-linecap="round"/>
      <path d="M96 44 L112 58 L96 72 L80 58 Z" fill="#102f39" stroke="#fff1b8" stroke-width="3"/>
      <path d="M104 30 Q118 44 118 58 M108 84 Q120 72 120 60" fill="none" stroke="${accent}" stroke-width="3" stroke-linecap="round" opacity=".8"/>`;
    }
    if (item.id === "module-ledger") {
      return `
      <path d="M22 42 Q46 34 62 44 L62 96 Q46 86 22 94 Z" fill="#1a1730" stroke="${accent}" stroke-width="4" stroke-linejoin="round"/>
      <path d="M102 42 Q78 34 62 44 L62 96 Q78 86 102 94 Z" fill="#241f3d" stroke="${accent}" stroke-width="4" stroke-linejoin="round"/>
      <path d="M30 54 H52 M30 64 H50 M74 54 H94 M74 64 H92 M74 74 H88" stroke="#fff1b8" stroke-width="3" stroke-linecap="round" opacity=".8"/>
      <path d="M104 84 L114 92 L104 100 L94 92 Z" fill="#ffd75e" stroke="#fff4c2" stroke-width="3"/>`;
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

const items = parseCatalog(catalogText).filter((item) => SHOP_SLOTS.has(item.slot));
if (items.length === 0) {
  throw new Error("Il catalogo premi non ha prodotto nessuna voce.");
}

fs.mkdirSync(godotSpriteDir, { recursive: true });
await buildImages(items);
console.log(`Foglio premi Godot rigenerato: ${items.length} icone.`);
