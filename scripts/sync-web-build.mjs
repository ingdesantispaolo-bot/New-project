// Risincronizza il manifest della release Web dopo un export Godot.
//
// Perché serve: `audit:web` pretende che QUATTRO valori combacino — buildId e
// cacheVersion fra `public/build.json` e `public/sw.js`, e le dimensioni di
// `index.pck`/`index.wasm` fra il file reale, il manifest e l'HTML generato da
// Godot. Un export cambia le dimensioni e lascia indietro manifest e service
// worker: l'audit diventa rosso, e se lo si aggiusta a mano prima o poi si sbaglia
// un valore. Il modo in cui sbaglia è silenzioso e costoso — il tablet continua a
// servire il PCK vecchio dalla cache e si finisce per giudicare una build che non
// contiene il lavoro appena fatto.
//
// Il bump di versione NON è cosmetico: è ciò che fa scadere la cache PWA. Senza
// bump un tablet che ha già aperto il gioco non vedrà mai il nuovo export.
//
// Uso:
//   node scripts/sync-web-build.mjs                 # bump automatico
//   node scripts/sync-web-build.mjs --slug abitanti # cambia anche lo slug
//   node scripts/sync-web-build.mjs --check         # non scrive, dice solo se serve

import { readFile, writeFile, stat } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const publicRoot = path.join(root, "public");
const exportRoot = path.join(publicRoot, "godot", "outdoor");
const manifestPath = path.join(publicRoot, "build.json");
const workerPath = path.join(publicRoot, "sw.js");

const args = process.argv.slice(2);
const checkOnly = args.includes("--check");
const slugIndex = args.indexOf("--slug");
const requestedSlug = slugIndex >= 0 ? args[slugIndex + 1] : null;

const [manifestSource, workerSource, versionSource, pck, wasm, contentPck] = await Promise.all([
  readFile(manifestPath, "utf8"),
  readFile(workerPath, "utf8"),
  readFile(path.join(root, "godot/scripts/game/build_version.gd"), "utf8"),
  stat(path.join(exportRoot, "index.pck")),
  stat(path.join(exportRoot, "index.wasm")),
  // Il pacchetto differito sta nello stesso contratto degli altri due: ha un
  // indirizzo fisso, quindi senza un valore da confrontare un "content.pck"
  // stantio o mancante passerebbe senza che nessuno se ne accorga.
  stat(path.join(exportRoot, "content.pck")),
]);

// Il commit marchiato DENTRO il pacchetto esportato. Finisce nel manifesto
// perche' e' l'unico modo che il gioco ha di chiedersi «sto girando la versione
// giusta?»: confronta il proprio `BuildVersion.COMMIT` con questo. Il `buildId`
// non serviva allo scopo — dice quando e' stato costruito il *guscio*, non quale
// codice c'e' dentro.
const exportedCommit = versionSource.match(/const COMMIT := "([0-9a-f]+)"/)?.[1] ?? "";

const manifest = JSON.parse(manifestSource);

// Lo slug identifica il filone di lavoro: si conserva se non lo si cambia.
const currentSlug =
  requestedSlug ?? String(manifest.cacheVersion ?? "").replace(/^v\d+-/, "") ?? "web";

// cacheVersion: "v9-web-loader" -> "v10-web-loader" (o nuovo slug, contatore avanti).
const cacheNumber = Number(String(manifest.cacheVersion ?? "").match(/^v(\d+)/)?.[1] ?? 0) + 1;
const nextCacheVersion = `v${cacheNumber}-${currentSlug}`;

// buildId: "2026.07.30-web-loader-1". Stesso giorno e stesso slug -> avanza il
// contatore; altrimenti riparte da 1.
const today = new Date();
const stamp = [
  today.getFullYear(),
  String(today.getMonth() + 1).padStart(2, "0"),
  String(today.getDate()).padStart(2, "0"),
].join(".");
const previous = String(manifest.buildId ?? "");
const samePrefix = previous.startsWith(`${stamp}-${currentSlug}-`);
const buildCounter = samePrefix ? Number(previous.split("-").pop() ?? 0) + 1 : 1;
const nextBuildId = `${stamp}-${currentSlug}-${buildCounter}`;

const inSync =
  manifest.pckBytes === pck.size &&
  manifest.wasmBytes === wasm.size &&
  manifest.contentPckBytes === contentPck.size &&
  manifest.buildId === workerSource.match(/const BUILD_ID = "([^"]+)"/)?.[1] &&
  manifest.cacheVersion === workerSource.match(/const CACHE_VERSION = "([^"]+)"/)?.[1] &&
  manifest.commit === exportedCommit;

if (checkOnly) {
  if (inSync) {
    console.log("WEB BUILD sync: già allineato, nessun bump necessario.");
  } else {
    console.error(
      "WEB BUILD sync: DISALLINEATO — esegui `node scripts/sync-web-build.mjs` dopo l'export.",
    );
    process.exitCode = 1;
  }
} else {
  const nextManifest = {
    buildId: nextBuildId,
    cacheVersion: nextCacheVersion,
    commit: exportedCommit,
    pckBytes: pck.size,
    wasmBytes: wasm.size,
    contentPckBytes: contentPck.size,
  };

  const nextWorker = workerSource
    .replace(/const BUILD_ID = "[^"]+"/, `const BUILD_ID = "${nextBuildId}"`)
    .replace(/const CACHE_VERSION = "[^"]+"/, `const CACHE_VERSION = "${nextCacheVersion}"`);

  if (!/const BUILD_ID = "/.test(nextWorker) || !/const CACHE_VERSION = "/.test(nextWorker)) {
    console.error("WEB BUILD sync ROSSO — costanti di versione non trovate in public/sw.js");
    process.exitCode = 1;
  } else {
    await writeFile(manifestPath, `${JSON.stringify(nextManifest, null, 2)}\n`, "utf8");
    await writeFile(workerPath, nextWorker, "utf8");
    console.log(
      `WEB BUILD sync OK — ${nextBuildId} / ${nextCacheVersion}, `
      + `PCK ${(pck.size / 1048576).toFixed(2)} MiB, WASM ${(wasm.size / 1048576).toFixed(2)} MiB`,
    );
  }
}
