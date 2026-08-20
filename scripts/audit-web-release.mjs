import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const publicRoot = path.join(root, "public");
const exportRoot = path.join(publicRoot, "godot", "outdoor");

const [manifestSource, workerSource, launcherSource, godotHtml, viteSource, presetsSource, fullscreenSource, webManifestSource, compressionSource, versionSource, pck, wasm, contentPck] = await Promise.all([
  readFile(path.join(publicRoot, "build.json"), "utf8"),
  readFile(path.join(publicRoot, "sw.js"), "utf8"),
  readFile(path.join(root, "index.html"), "utf8"),
  readFile(path.join(exportRoot, "index.html"), "utf8"),
  readFile(path.join(root, "vite.config.mjs"), "utf8"),
  readFile(path.join(root, "godot", "export_presets.cfg"), "utf8"),
  readFile(path.join(publicRoot, "tablet-fullscreen.js"), "utf8").catch(() => ""),
  readFile(path.join(publicRoot, "manifest.webmanifest"), "utf8"),
  readFile(path.join(root, "scripts", "vite-godot-compression.mjs"), "utf8"),
  readFile(path.join(root, "godot/scripts/game/build_version.gd"), "utf8"),
  stat(path.join(exportRoot, "index.pck")),
  stat(path.join(exportRoot, "index.wasm")),
  stat(path.join(exportRoot, "content.pck")),
]);

const manifest = JSON.parse(manifestSource);
const failures = [];

function requireMatch(source, expression, label) {
  const match = source.match(expression);
  if (!match) failures.push(`${label}: valore non trovato`);
  return match?.[1] ?? "";
}

const workerBuild = requireMatch(workerSource, /const BUILD_ID = "([^"]+)"/, "service worker buildId");
const workerCache = requireMatch(workerSource, /const CACHE_VERSION = "([^"]+)"/, "service worker cacheVersion");
const godotPck = Number(requireMatch(godotHtml, /"index\.pck":(\d+)/, "Godot index.pck"));
const godotWasm = Number(requireMatch(godotHtml, /"index\.wasm":(\d+)/, "Godot index.wasm"));

if (manifest.buildId !== workerBuild) {
  failures.push(`buildId disallineato: build.json=${manifest.buildId}, sw.js=${workerBuild}`);
}
if (manifest.cacheVersion !== workerCache) {
  failures.push(`cacheVersion disallineata: build.json=${manifest.cacheVersion}, sw.js=${workerCache}`);
}
if (manifest.pckBytes !== pck.size || godotPck !== pck.size) {
  failures.push(`index.pck disallineato: file=${pck.size}, build.json=${manifest.pckBytes}, Godot HTML=${godotPck}`);
}
if (manifest.wasmBytes !== wasm.size || godotWasm !== wasm.size) {
  failures.push(`index.wasm disallineato: file=${wasm.size}, build.json=${manifest.wasmBytes}, Godot HTML=${godotWasm}`);
}
// content.pck non compare nell'HTML di Godot: non lo carica il motore, lo chiede
// il gioco a runtime. Il confronto possibile e' quindi file contro manifesto.
if (manifest.contentPckBytes !== contentPck.size) {
  failures.push(`content.pck disallineato: file=${contentPck.size}, build.json=${manifest.contentPckBytes}`);
}
// --- La catena della versione, anello per anello -----------------------------
//
// Aggiunto il 7 agosto 2026 su richiesta: «all'avvio del programma online questo
// controlli se sta girando la versione aggiornata, se non e' cosi' va
// riscaricata». Il controllo che c'era verificava il *service worker*; questi
// verificano che la catena arrivi fino al gioco.
const stampedCommit = versionSource.match(/const COMMIT := "([0-9a-f]+)"/)?.[1] ?? "";
if (!manifest.commit) {
  failures.push("build.json non dichiara il commit: il gioco non puo' sapere se e' aggiornato");
} else if (manifest.commit !== stampedCommit) {
  failures.push(
    `commit disallineato: build.json=${manifest.commit}, pacchetto=${stampedCommit}. `
    + "Il gioco si direbbe vecchio a ogni avvio.",
  );
}
if (!workerSource.includes('cache: "reload"')) {
  failures.push(
    "service worker: un fallimento di cache rilegge dalla cache HTTP del browser, "
    + "quindi puo' riscaricare la copia vecchia dallo stesso indirizzo",
  );
}
if (!workerSource.includes('"PURGE"')) {
  failures.push("service worker: manca lo svuotamento su richiesta");
}
for (const [needle, label] of [
  ["GET_BUILD_ID", "handshake versione"],
  ["controllerchange", "attesa nuovo service worker"],
  ["build.json?check=", "controllo manifest senza cache"],
  ["purgeCaches", "svuotamento cache quando la build cambia"],
]) {
  if (!launcherSource.includes(needle)) failures.push(`launcher: manca ${label}`);
}
if (!workerSource.includes('requestUrl.pathname.endsWith("/build.json")')) {
  failures.push("service worker: build.json non usa network-first");
}
if (!viteSource.includes("godotWebCompression()")) {
  failures.push("Vite: plugin di compressione Godot non attivo");
}
if (!viteSource.includes('entries: ["index.html"]')) {
  failures.push("Vite: scansione dipendenze non limitata alla shell");
}
for (const [needle, label] of [
  ['"/godot/outdoor/index.wasm"', "WASM"],
  ['"/godot/outdoor/index.js"', "JavaScript Godot"],
  ["brotliCompress", "Brotli"],
  ["gzip", "Gzip"],
]) {
  if (!compressionSource.includes(needle)) failures.push(`compressione Vite: manca ${label}`);
}

// --- Lo schermo intero è sopravvissuto all'export? ---------------------------
//
// Il guscio HTML lo scrive Godot da zero a ogni export: l'unico modo di farci
// entrare qualcosa è `html/head_include` nel preset. È un aggancio che sparisce
// in silenzio — basta che qualcuno salvi il pannello di export con il campo
// vuoto — e sparirebbe senza rompere niente: il gioco parte lo stesso, solo con
// un quarto di schermo mangiato dalle barre del browser sul tablet. Nessun altro
// controllo se ne accorgerebbe.
if (!fullscreenSource) {
  failures.push("public/tablet-fullscreen.js manca: il guscio esportato lo carica e non lo troverà");
} else if (!fullscreenSource.includes("requestFullscreen")) {
  failures.push("public/tablet-fullscreen.js non chiede più lo schermo intero");
}
if (!presetsSource.includes("tablet-fullscreen.js")) {
  failures.push(
    "export_presets.cfg: `html/head_include` non aggancia più tablet-fullscreen.js — "
    + "il prossimo export uscirà senza schermo intero",
  );
}
if (!godotHtml.includes("tablet-fullscreen.js")) {
  failures.push(
    "guscio Godot esportato: manca lo script dello schermo intero. "
    + "Riesporta con `npm run export:web` dopo aver corretto il preset.",
  );
}
const webManifest = JSON.parse(webManifestSource);
if (webManifest.display !== "fullscreen") {
  failures.push(
    `manifest.webmanifest: display=${webManifest.display}. Installato dalla schermata Home `
    + "il gioco si riprenderebbe solo una parte dello schermo.",
  );
}

// --- L'export è più vecchio dei sorgenti? -------------------------------------
//
// Il 5 agosto 2026 quattro «build» di fila sono state dichiarate verdi mentre il
// PCK servito era fermo al giorno prima: l'export era finito in
// `public/godot/` invece che in `public/godot/outdoor/`, e nessuno se n'è
// accorto perché tutti e quattro i valori confrontati qui sopra combaciavano fra
// loro. Erano coerenti con l'artefatto SBAGLIATO.
//
// Il confronto mancante era con la realtà: se un file di gioco è più recente del
// PCK, quel PCK non contiene quel file. È l'unico controllo che distingue «ho
// esportato» da «ho detto di aver esportato».
const SORGENTI = [
  path.join(root, "godot", "scripts"),
  path.join(root, "godot", "data", "banks"),
  path.join(root, "godot", "scenes"),
];

async function piuRecente(dir) {
  let ultimo = { mtimeMs: 0, file: "" };
  let voci = [];
  try {
    voci = await readdir(dir, { withFileTypes: true });
  } catch {
    return ultimo;
  }
  for (const voce of voci) {
    const completo = path.join(dir, voce.name);
    if (voce.isDirectory()) {
      const dentro = await piuRecente(completo);
      if (dentro.mtimeMs > ultimo.mtimeMs) ultimo = dentro;
      continue;
    }
    // I `.uid` li riscrive Godot all'import: non sono contenuto di gioco e
    // farebbero scattare l'allarme senza che sia cambiato niente.
    if (voce.name.endsWith(".uid")) continue;
    const info = await stat(completo);
    if (info.mtimeMs > ultimo.mtimeMs) ultimo = { mtimeMs: info.mtimeMs, file: completo };
  }
  return ultimo;
}

let sorgentePiuRecente = { mtimeMs: 0, file: "" };
for (const dir of SORGENTI) {
  const trovato = await piuRecente(dir);
  if (trovato.mtimeMs > sorgentePiuRecente.mtimeMs) sorgentePiuRecente = trovato;
}
if (sorgentePiuRecente.mtimeMs > pck.mtimeMs) {
  failures.push(
    `export più vecchio dei sorgenti: ${path.relative(root, sorgentePiuRecente.file)} `
    + `è cambiato dopo l'ultimo PCK. Riesporta in public/godot/outdoor/ — `
    + `stai giudicando la build precedente.`,
  );
}

// --- La versione mostrata deve essere quella del codice esportato ----------
//
// Aggiunto il 7 agosto 2026 su richiesta: «assicuriamoci che facendo push la
// versione online sia aggiornata».
//
// Il difetto che intercetta e' reale ed era gia' successo: si marchia la
// versione con il commit corrente, si esporta, e poi si committa tutto — il
// commit nuovo contiene una build che dichiara il commit PRECEDENTE. Finche' fra
// i due non e' cambiato nessun sorgente, e' solo contabilita'. Se invece nel
// frattempo il codice e' cambiato, la build online mente su cosa sta eseguendo,
// ed e' esattamente il numero che serve quando arriva una segnalazione di gioco.
//
// Il controllo non pretende che il commit marchiato sia HEAD — impossibile,
// perche' il commit che porta la build non esiste ancora quando si marchia.
// Pretende che **fra il commit marchiato e HEAD non sia cambiato nessun
// sorgente del gioco**.
try {
  const versione = await readFile(path.join(root, "godot/scripts/game/build_version.gd"), "utf8");
  const sha = versione.match(/const COMMIT := "([0-9a-f]+)"/)?.[1] ?? "";
  if (sha === "") {
    failures.push(
      "godot/scripts/game/build_version.gd non dichiara nessun commit: "
      + "lancia `npm run version:stamp` prima di esportare.",
    );
  } else {
    const { execSync } = await import("node:child_process");
    // Niente redirezioni di shell: `execSync` usa cmd.exe su Windows, dove
    // `2>/dev/null` non esiste e fa fallire il comando con un messaggio che
    // non c'entra niente. Gli errori li prende il try/catch qui attorno.
    const cambiati = execSync(
      `git diff --name-only ${sha} HEAD -- godot/ scripts/`,
      { cwd: root, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
    )
      .split("\n")
      .map((r) => r.trim())
      // Il file della versione e il suo `.uid` non contano: cambiano PER
      // definizione fra il commit marchiato e quello che porta la build.
      // I `.uid` sono identificativi di risorsa generati dall'importazione:
      // deterministici dal file che accompagnano, e senza nessun effetto su cosa
      // il gioco esegue. Contarli faceva gridare al lupo proprio quando il lotto
      // era corretto — e un controllo che si sbaglia si impara a ignorare, che e'
      // il modo peggiore di perdere quello che serve davvero.
      .filter((r) => r !== "" && !r.includes("build_version.gd") && !r.endsWith(".uid"));
    if (cambiati.length > 0) {
      failures.push(
        `la versione mostrata (${sha}) non e' quella del codice: da allora sono `
        + `cambiati ${cambiati.length} file, fra cui ${cambiati[0]}. `
        + "Lancia `npm run version:stamp`, riesporta e risincronizza prima del push.",
      );
    }
  }
} catch (errore) {
  // Fuori da un repository git il controllo non si puo' fare, e non deve
  // bloccare una build: si dichiara invece di fallire in silenzio.
  console.log(`        (versione non verificata: ${errore.code ?? errore.message})`);
}

if (failures.length > 0) {
  console.error(`WEB RELEASE audit ROSSO\n- ${failures.join("\n- ")}`);
  process.exitCode = 1;
} else {
  const totalMiB = (pck.size + wasm.size) / 1048576;
  console.log(
    `WEB RELEASE audit OK — ${manifest.buildId}, PCK ${(pck.size / 1048576).toFixed(2)} MiB, `
    + `WASM ${(wasm.size / 1048576).toFixed(2)} MiB, core ${totalMiB.toFixed(2)} MiB`,
  );
}
