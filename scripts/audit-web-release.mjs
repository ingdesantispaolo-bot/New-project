import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const publicRoot = path.join(root, "public");
const exportRoot = path.join(publicRoot, "godot", "outdoor");

const [manifestSource, workerSource, launcherSource, godotHtml, viteSource, compressionSource, pck, wasm] = await Promise.all([
  readFile(path.join(publicRoot, "build.json"), "utf8"),
  readFile(path.join(publicRoot, "sw.js"), "utf8"),
  readFile(path.join(root, "index.html"), "utf8"),
  readFile(path.join(exportRoot, "index.html"), "utf8"),
  readFile(path.join(root, "vite.config.mjs"), "utf8"),
  readFile(path.join(root, "scripts", "vite-godot-compression.mjs"), "utf8"),
  stat(path.join(exportRoot, "index.pck")),
  stat(path.join(exportRoot, "index.wasm")),
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
for (const [needle, label] of [
  ["GET_BUILD_ID", "handshake versione"],
  ["controllerchange", "attesa nuovo service worker"],
  ["build.json?check=", "controllo manifest senza cache"],
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
