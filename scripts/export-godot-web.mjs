// Esporta la build Web di Godot in `public/godot/outdoor/`.
//
// Perché esiste: fino a oggi l'export si faceva a mano sulla macchina di
// sviluppo e il risultato — 26 MB di `.pck` più 39 MB di `.wasm` — veniva
// COMMITTATO. Settantadue commit di questo tipo hanno portato `.git` a 1,4 GB, e
// soprattutto hanno reso impossibile garantire che la build pubblicata
// corrispondesse ai sorgenti: nessuno verificava che il `.pck` committato fosse
// stato esportato dagli script presenti nello stesso commit.
//
// Con questo script l'export diventa un passo riproducibile della pipeline, in
// locale e in CI, e i binari smettono di essere tracciati da git.
//
// Uso:
//   node scripts/export-godot-web.mjs
//   GODOT_BIN="C:\\percorso\\godot_console.exe" node scripts/export-godot-web.mjs

import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import process from "node:process";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const projectPath = join(root, "godot");
const exportRoot = join(root, "public", "godot", "outdoor");
const exportTarget = join(exportRoot, "index.html");
const contentTarget = join(exportRoot, "content.pck");
const PRESET = "Web";
const CONTENT_PRESET = "Web Content";

// Stesso ordine di ricerca di `run-godot-audits.mjs`: se un giorno cambia la
// posizione dell'eseguibile va cambiata in due punti, ma tenere i due script
// indipendenti evita che un errore nell'export blocchi gli audit.
const GODOT_CANDIDATES = [
  process.env.GODOT_BIN,
  process.env.USERPROFILE
    ? join(
        process.env.USERPROFILE,
        "Godot_v4.7.1-stable_win64.exe",
        "Godot_v4.7.1-stable_win64_console.exe",
      )
    : undefined,
  "C:\\Users\\39351\\Godot\\Godot_v4.7.1-stable_win64.exe\\Godot_v4.7.1-stable_win64_console.exe",
].filter(Boolean);

const GODOT_BIN = GODOT_CANDIDATES.find((candidate) => existsSync(candidate)) ?? "godot";

// Righe che invalidano un export anche con exit code 0. Godot esce 0 anche
// quando un `.gd` non compila: il `.pck` viene scritto lo stesso, con dentro uno
// script rotto. È esattamente il modo in cui una build sbagliata arriva sul
// tablet senza che nessuno se ne accorga.
const FAILURE_MARKERS = [/SCRIPT ERROR/, /Parse Error/, /Can't load script/, /ERROR: Project export/];

function run(args, label) {
  return new Promise((resolve, reject) => {
    const child = spawn(GODOT_BIN, args, { stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    child.stdout.on("data", (chunk) => {
      output += chunk;
      process.stdout.write(chunk);
    });
    child.stderr.on("data", (chunk) => {
      output += chunk;
      process.stderr.write(chunk);
    });
    child.on("error", reject);
    child.on("close", (code) => {
      const marker = FAILURE_MARKERS.find((pattern) => pattern.test(output));
      if (marker) {
        reject(new Error(`${label}: output contiene «${marker.source}» — export non affidabile`));
        return;
      }
      if (code !== 0) {
        reject(new Error(`${label}: exit code ${code}`));
        return;
      }
      resolve();
    });
  });
}

await mkdir(exportRoot, { recursive: true });

// L'import va forzato prima dell'export: in CI la cartella `godot/.godot` non
// esiste (è ignorata da git) e senza cache di import il `.pck` esce senza
// texture né audio.
console.log(`Godot: ${GODOT_BIN}`);
console.log("1/2 import risorse…");
await run(["--headless", "--path", projectPath, "--import"], "import");

console.log(`2/3 export preset «${PRESET}» → ${exportTarget}`);
await run(
  ["--headless", "--path", projectPath, "--export-release", PRESET, exportTarget],
  "export",
);

// Audio e ritratti viaggiano in un pacchetto a parte, chiesto dal gioco quando
// è già interattivo (`scripts/game/content_pack_loader.gd`). Sono 26 MB che
// prima si pagavano prima del primo fotogramma pur non servendo per entrare nel
// mondo. L'ordine conta: il pacchetto va prodotto dopo il `.pck` di boot, che è
// quello che ne definisce le esclusioni.
console.log(`3/3 export pacchetto contenuti «${CONTENT_PRESET}» → ${contentTarget}`);
await run(
  ["--headless", "--path", projectPath, "--export-pack", CONTENT_PRESET, contentTarget],
  "export-pack",
);

console.log("Export Web completato.");
