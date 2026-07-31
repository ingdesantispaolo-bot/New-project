// Esegue TUTTI gli audit Godot headless e riporta un verde onesto.
//
// Perché serve uno script: un `assert` fallito in uno script Godot lanciato con
// `--script` stampa `SCRIPT ERROR: Assertion failed: …`, interrompe la funzione
// in corso ma NON cambia l'exit code — se lo script arriva comunque a `quit(0)`
// l'audit sembra verde. Quattro audit sono rimasti rossi per settimane per questo
// motivo. Qui un audit è verde solo se: exit code 0, nessuna asserzione fallita e
// nessun errore di script. In più ogni audit gira con un save ISOLATO (roundtrip
// legge il save reale) e con un timeout, perché un assert può lasciare il
// processo appeso.
//
// Uso:
//   node scripts/run-godot-audits.mjs                 # tutti
//   node scripts/run-godot-audits.mjs content_depth   # solo quelli che combaciano
//   GODOT_BIN="C:\\percorso\\godot_console.exe" node scripts/run-godot-audits.mjs

import { spawn } from "node:child_process";
import { mkdtemp, readdir, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const projectPath = join(root, "godot");
const TIMEOUT_MS = Number(process.env.AUDIT_TIMEOUT_MS ?? 240_000);

const GODOT_BIN =
  process.env.GODOT_BIN ??
  "C:\\Users\\39351\\Godot\\Godot_v4.7.1-stable_win64.exe\\Godot_v4.7.1-stable_win64_console.exe";

// Righe che invalidano un audit anche con exit code 0.
const FAILURE_MARKERS = [/Assertion failed/, /SCRIPT ERROR/, /Parse Error/, /Can't load script/];

async function findAudits(dir) {
  const found = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) found.push(...(await findAudits(full)));
    else if (entry.name.endsWith("_audit.gd")) found.push(full);
  }
  return found.sort();
}

function runAudit(resPath, saveDir) {
  return new Promise((resolve) => {
    const child = spawn(
      GODOT_BIN,
      ["--headless", "--path", projectPath, "--script", resPath],
      { env: { ...process.env, APPDATA: saveDir, LOCALAPPDATA: saveDir } },
    );
    let output = "";
    const timer = setTimeout(() => {
      child.kill();
      resolve({ code: null, output: output + "\n[TIMEOUT]" });
    }, TIMEOUT_MS);
    child.stdout.on("data", (chunk) => (output += chunk));
    child.stderr.on("data", (chunk) => (output += chunk));
    child.on("close", (code) => {
      clearTimeout(timer);
      resolve({ code, output });
    });
  });
}

if (!existsSync(GODOT_BIN)) {
  console.error(`Eseguibile Godot non trovato: ${GODOT_BIN}\nImposta GODOT_BIN con il percorso della variante _console.exe.`);
  process.exit(2);
}

const filter = process.argv[2];
const audits = (await findAudits(join(projectPath, "scripts"))).filter(
  (file) => !filter || file.includes(filter),
);
if (audits.length === 0) {
  console.error(filter ? `Nessun audit combacia con "${filter}".` : "Nessun audit trovato.");
  process.exit(2);
}

const failed = [];
const started = Date.now();
for (const file of audits) {
  const name = relative(join(projectPath, "scripts"), file).replace(/\\/g, "/").replace(/\.gd$/, "");
  const resPath = `res://scripts/${name}.gd`;
  const saveDir = await mkdtemp(join(tmpdir(), "eli-audit-"));
  const { code, output } = await runAudit(resPath, saveDir);
  // La pulizia non deve poter far fallire la suite. Su Windows, quando un audit
  // va in timeout il processo viene ucciso ma l'handle su godot.log resta aperto
  // per qualche istante: l'unlink alza EBUSY e, non gestito, abortiva l'intera
  // esecuzione al PRIMO audit appeso — nascondendo tutti i risultati successivi.
  try {
    await rm(saveDir, { recursive: true, force: true });
  } catch (error) {
    console.log(`        (pulizia rinviata: ${error.code ?? error.message})`);
  }
  const problems = output
    .split(/\r?\n/)
    .filter((line) => FAILURE_MARKERS.some((marker) => marker.test(line)));
  const timedOut = output.endsWith("[TIMEOUT]");
  const ok = code === 0 && problems.length === 0 && !timedOut;
  if (!ok) {
    failed.push(name);
    console.log(`[${timedOut ? "TIMEOUT" : code === 0 ? "ROSSO" : `EXIT ${code}`}] ${name}`);
    for (const line of problems.slice(0, 4)) console.log(`        ${line.trim()}`);
  } else {
    console.log(`[verde] ${name}`);
  }
}

const seconds = Math.round((Date.now() - started) / 1000);
console.log(
  failed.length === 0
    ? `\nTutti verdi: ${audits.length}/${audits.length} in ${seconds}s.`
    : `\nNON verdi: ${failed.length}/${audits.length} in ${seconds}s → ${failed.join(", ")}`,
);
process.exit(failed.length === 0 ? 0 : 1);
