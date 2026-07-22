import { readdirSync, statSync, writeFileSync } from "node:fs";
import { basename, extname, join, relative } from "node:path";

const root = process.cwd();
const legacyRoot = join(root, "src", "assets", "images");
const godotRoot = join(root, "godot", "assets");
const output = join(root, "docs", "GODOT_ASSET_MANIFEST.json");
const visualExtensions = new Set([".png", ".webp", ".avif", ".jpg", ".jpeg", ".svg"]);

function walk(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

const godotFiles = walk(godotRoot).filter((path) => visualExtensions.has(extname(path).toLowerCase()));
const godotByStem = new Map(godotFiles.map((path) => [basename(path, extname(path)), relative(root, path).replaceAll("\\", "/")]));
const shipStems = new Set([
  "academy-action-room-bg", "area-bio-ponte-primi", "area-data-core-primi",
  "area-motore-risonanza-primi", "area-ponte-comando-primi", "area-reattore-primi",
  "area-sala-glifi-primi",
]);

const assets = walk(legacyRoot)
  .filter((path) => visualExtensions.has(extname(path).toLowerCase()))
  .sort()
  .map((path) => {
    const extension = extname(path).toLowerCase();
    const stem = basename(path, extension);
    const legacyPath = relative(root, path).replaceAll("\\", "/");
    let status = "review";
    let nativePath = godotByStem.get(stem) ?? null;
    let note = "Non referenziato dal runtime Godot; valutazione artistica ancora necessaria.";
    if (shipStems.has(stem) && extension === ".png") {
	  status = "replace-optimized";
	  nativePath = `godot/assets/ship/${stem}.webp`;
	  note = "Master PNG sostituito nel runtime dal WebP ottimizzato equivalente.";
    } else if (nativePath) {
      status = "reuse-native";
      note = "Asset presente nel runtime Godot.";
    } else if (/story|chapter|nora/i.test(stem)) {
      status = "retain-story-source";
      note = "Conservare come sorgente narrativa finché cutscene/dialoghi nativi non ne dichiarano la copertura.";
    } else if (/terrain|outdoor|academy|bosco|dorsale|cratere|enigma|mission|map/i.test(stem)) {
      status = "replaced-by-native-world";
      note = "Coperto dalla composizione outdoor, dagli atlanti o dagli enigmi nativi Godot; non copiare automaticamente.";
    }
    return { legacyPath, bytes: statSync(path).size, status, nativePath, note };
  });

const counts = Object.fromEntries([...new Set(assets.map((asset) => asset.status))].sort().map((status) => [status, assets.filter((asset) => asset.status === status).length]));
writeFileSync(output, `${JSON.stringify({ generatedAt: new Date().toISOString(), legacyVisualCount: assets.length, godotVisualCount: godotFiles.length, counts, assets }, null, 2)}\n`);
console.log(`Manifest scritto: ${relative(root, output)} (${assets.length} asset legacy, ${godotFiles.length} Godot)`);
