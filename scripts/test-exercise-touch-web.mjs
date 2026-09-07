import { spawn } from "node:child_process";
import { createReadStream } from "node:fs";
import { access, copyFile, mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import process from "node:process";

const root = path.resolve("artifacts/exercise-touch-web/build");
// Il guscio esportato carica `../../tablet-fullscreen.js`: in produzione quella
// e' la radice del sito, qui la radice servita e' la cartella dell'export. Senza
// questa deroga il file mancherebbe, e il rapporto elencherebbe un errore di
// console che in produzione non esiste — rumore che somiglia a una regressione.
const SITE_ROOT_FILES = new Map([
  ["/tablet-fullscreen.js", path.resolve("public/tablet-fullscreen.js")],
  ["/content.pck", path.resolve("public/godot/outdoor/content.pck")],
]);
const outputRoot = path.resolve("artifacts/exercise-touch-web/results");

const chromeCandidates = [
  process.env.ELI_CHROME,
  "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
].filter(Boolean);

const mimeTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".png", "image/png"],
  [".json", "application/json; charset=utf-8"],
]);

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function firstExisting(paths) {
  for (const candidate of paths) {
    try {
      await access(candidate);
      return candidate;
    } catch {
      // Prova il percorso successivo.
    }
  }
  throw new Error("Chrome/Edge non trovato. Imposta ELI_CHROME con il percorso dell'eseguibile.");
}

function startStaticServer() {
  const server = http.createServer(async (request, response) => {
    try {
      const url = new URL(request.url ?? "/", "http://127.0.0.1");
      const relative = decodeURIComponent(url.pathname === "/" ? "/index.html" : url.pathname);
      const fromSiteRoot = SITE_ROOT_FILES.get(relative);
      const requestedPath = fromSiteRoot ?? path.resolve(root, `.${relative}`);
      const insideRoot = requestedPath === root || requestedPath.startsWith(`${root}${path.sep}`);
      if (!fromSiteRoot && !insideRoot) {
        response.writeHead(403).end("Forbidden");
        return;
      }

      const info = await stat(requestedPath);
      if (!info.isFile()) {
        response.writeHead(404).end("Not found");
        return;
      }
      if (path.basename(requestedPath) === "index.html") {
        const source = await readFile(requestedPath, "utf8");
        const body = Buffer.from(source, "utf8");
        response.writeHead(200, {
          "Cache-Control": "no-store",
          "Content-Length": String(body.length),
          "Content-Type": "text/html; charset=utf-8",
        });
        response.end(body);
        return;
      }

      const range = request.headers.range?.match(/^bytes=(\d+)-(\d*)$/);
      let start = 0;
      let end = info.size - 1;
      let status = 200;
      if (range) {
        start = Number(range[1]);
        end = range[2] === "" ? end : Math.min(Number(range[2]), end);
        if (start > end || start >= info.size) {
          response.writeHead(416, { "Content-Range": `bytes */${info.size}` }).end();
          return;
        }
        status = 206;
      }

      const headers = {
        "Accept-Ranges": "bytes",
        "Cache-Control": "no-store",
        "Content-Length": String(end - start + 1),
        "Content-Type": mimeTypes.get(path.extname(requestedPath)) ?? "application/octet-stream",
      };
      if (status === 206) {
        headers["Content-Range"] = `bytes ${start}-${end}/${info.size}`;
      }
      response.writeHead(status, headers);
      if (request.method === "HEAD") {
        response.end();
        return;
      }
      createReadStream(requestedPath, { start, end }).pipe(response);
    } catch {
      // Il nome del file mancante, non solo il numero: il rapporto elenca i 404
      // visti dal browser, e senza questa riga capire QUALE risorsa manchi
      // costava una corsa intera del test.
      console.warn(`404: ${request.url}`);
      response.writeHead(404).end("Not found");
    }
  });
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => resolve(server));
  });
}

class Cdp {
  constructor(socket) {
    this.socket = socket;
    this.serial = 0;
    this.pending = new Map();
    this.listeners = new Map();
    socket.addEventListener("message", (event) => {
      const message = JSON.parse(String(event.data));
      if (message.id) {
        const waiter = this.pending.get(message.id);
        if (!waiter) return;
        this.pending.delete(message.id);
        clearTimeout(waiter.timeoutId);
        if (message.error) waiter.reject(new Error(message.error.message));
        else waiter.resolve(message.result);
        return;
      }
      for (const listener of this.listeners.get(message.method) ?? []) listener(message.params);
    });
  }

  call(method, params = {}, sessionId = undefined) {
    const id = ++this.serial;
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`DevTools non ha risposto a ${method} entro 30 secondi.`));
      }, 30_000);
      this.pending.set(id, { resolve, reject, timeoutId });
      this.socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    });
  }

  on(method, listener) {
    const listeners = this.listeners.get(method) ?? [];
    listeners.push(listener);
    this.listeners.set(method, listeners);
  }
}

async function connectWebSocket(url) {
  const socket = new WebSocket(url);
  await new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve, { once: true });
    socket.addEventListener("error", reject, { once: true });
  });
  return socket;
}

async function waitForDevTools(profileDir, timeoutMs = 15_000) {
  const marker = path.join(profileDir, "DevToolsActivePort");
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const [port, endpoint] = (await readFile(marker, "utf8")).trim().split(/\r?\n/);
      if (port && endpoint) return `ws://127.0.0.1:${port}${endpoint}`;
    } catch {
      // Chrome non ha ancora pubblicato la porta.
    }
    await delay(100);
  }
  throw new Error("Chrome non ha aperto DevTools entro 15 secondi.");
}

async function evaluate(cdp, sessionId, expression) {
  const result = await cdp.call(
    "Runtime.evaluate",
    { expression, returnByValue: true, awaitPromise: true },
    sessionId,
  );
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
  return result.result.value;
}

async function capture(cdp, sessionId, destination) {
  const screenshot = await cdp.call("Page.captureScreenshot", { format: "png" }, sessionId);
  await writeFile(destination, Buffer.from(screenshot.data, "base64"));
}

// Export an isolated test scene, then restore the project even when export
// fails. The fixture lives outside godot/ and never enters a production build.
// Do not run this alongside another Godot export.
async function exportFixture() {
  const project = path.resolve("godot/project.godot");
  const script = path.resolve("godot/scripts/game/exercise_input_harness.gd");
  const scene = path.resolve("godot/scenes/exercise_input_harness.tscn");
  for (const reserved of [script, scene, `${script}.uid`]) {
    try { await access(reserved); } catch { continue; }
    throw new Error(`Test path already exists: ${reserved}`);
  }
  const original = await readFile(project);
  const patched = original.toString("utf8").replace("res://scenes/boot_menu.tscn", "res://scenes/exercise_input_harness.tscn");
  if (patched === original.toString("utf8")) throw new Error("Unexpected main scene");
  const godot = process.env.GODOT_BIN ?? path.join(process.env.USERPROFILE, "Godot_v4.7.1-stable_win64.exe", "Godot_v4.7.1-stable_win64_console.exe");
  await mkdir(root, {recursive: true});
  try {
    await copyFile("scripts/fixtures/exercise-input-harness.gd", script);
    await copyFile("scripts/fixtures/exercise-input-harness.gd.uid", `${script}.uid`);
    await copyFile("scripts/fixtures/exercise-input-harness.tscn", scene);
    await writeFile(project, patched);
    const output = await new Promise((resolve, reject) => {
      const child = spawn(godot, ["--headless", "--path", path.resolve("godot"), "--export-debug", "Web", path.join(root, "index.html")], {windowsHide: true});
      let log = "";
      const timeout = setTimeout(() => { child.kill(); reject(new Error("Godot export timed out")); }, 120_000);
      child.stdout.on("data", chunk => log += chunk);
      child.stderr.on("data", chunk => log += chunk);
      child.on("error", error => { clearTimeout(timeout); reject(error); });
      child.on("close", code => {
        clearTimeout(timeout);
        if (code !== 0 || /SCRIPT ERROR|Parse Error|ERROR:/.test(log)) reject(new Error(log));
        else resolve(log);
      });
    });
    await writeFile(path.join(outputRoot, "export.log"), output);
  } finally {
    await writeFile(project, original);
    for (const temporary of [script, scene, `${script}.uid`]) await rm(temporary, {force: true});
  }
}

await mkdir(outputRoot, { recursive: true });
await exportFixture();
const server = await startStaticServer();
const profileDir = await mkdtemp(path.join(os.tmpdir(), "eli-input-web-"));
const browser = spawn(await firstExisting(chromeCandidates), ["--headless=new", "--no-first-run", "--no-default-browser-check", "--remote-debugging-port=0", `--user-data-dir=${profileDir}`, "about:blank"], {windowsHide: true, stdio: "ignore"});
let socket;
const messages = [];
try {
  socket = await connectWebSocket(await waitForDevTools(profileDir));
  const cdp = new Cdp(socket);
  const {targetId} = await cdp.call("Target.createTarget", {url: "about:blank"});
  const {sessionId} = await cdp.call("Target.attachToTarget", {targetId, flatten: true});
  cdp.on("Runtime.consoleAPICalled", e => { const line = e.args.map(a=>a.value ?? a.description ?? "").join(" "); messages.push(line); console.log(line); });
  cdp.on("Runtime.exceptionThrown", e => { messages.push(`EXCEPTION ${JSON.stringify(e)}`); console.log("EXCEPTION", e); });
  await cdp.call("Runtime.enable", {}, sessionId);
  await cdp.call("Page.enable", {}, sessionId);
  await cdp.call("Emulation.setDeviceMetricsOverride", {width: 390, height: 684, deviceScaleFactor: 1, mobile: true}, sessionId);
  await cdp.call("Emulation.setTouchEmulationEnabled", {enabled: true, maxTouchPoints: 1}, sessionId);
  await cdp.call("Page.navigate", {url: `http://127.0.0.1:${server.address().port}/index.html`}, sessionId);
  const state = () => evaluate(cdp, sessionId, "window.__exerciseInputTest || null");
  for(let n=0;n<30 && !(await state());n++) await delay(500);
  if (!(await state())) {
    console.log("DOM", await evaluate(cdp,sessionId,"({data:{...document.documentElement.dataset},text:document.body.innerText,config:GODOT_CONFIG})"));
    await capture(cdp,sessionId,path.join(outputRoot,"input-failed.png"));
    throw new Error("Harness not started");
  }
  await delay(1000);
  await capture(cdp, sessionId, path.join(outputRoot, "input-before.png"));
  async function tap(name) {
    const s = await state();
    const canvas = await evaluate(cdp,sessionId,`(() => {const r=document.querySelector('#canvas').getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}})()`);
    const button = s.buttons[name];
    const x = canvas.x + button.x * canvas.w / s.viewport[0];
    const y = canvas.y + button.y * canvas.h / s.viewport[1];
    if (!button.visible || button.disabled || x < 0 || x > canvas.w || y < 0 || y > canvas.h) {
      await capture(cdp,sessionId,path.join(outputRoot,"input-unreachable.png"));
      throw new Error(`${name} is not reachable: ${JSON.stringify({state:s,canvas,x,y})}`);
    }
    if (name !== "Numpad_6" && button.height * canvas.h / s.viewport[1] < 47.5) throw new Error(`${name} is smaller than 48 CSS pixels`);
    await cdp.call("Input.dispatchMouseEvent", {type:"mouseMoved",x,y},sessionId);
    await delay(100);
    await cdp.call("Input.dispatchTouchEvent", {type:"touchStart",touchPoints:[{x,y,radiusX:2,radiusY:2,force:1}]},sessionId);
    await delay(60);
    if(name === "ExerciseNextButton") {
      const buttonCssHeight = button.height * canvas.h / s.viewport[1];
      // Il rilascio termina volutamente oltre il bordo inferiore. `pressed`
      // viene annullato in questo caso; AVANTI usa `button_up`, perche' il gesto
      // e' iniziato senza ambiguita' dentro il comando.
      await cdp.call("Input.dispatchTouchEvent", {type:"touchMove",touchPoints:[{x,y:y+buttonCssHeight/2+9,radiusX:2,radiusY:2,force:1}]},sessionId);
      await delay(60);
    }
    await cdp.call("Input.dispatchTouchEvent", {type:"touchEnd",touchPoints:[]},sessionId);
    await delay(800);
  }
  async function tapCenter(name) {
    const s = await state();
    const canvas = await evaluate(cdp,sessionId,`(() => {const r=document.querySelector('#canvas').getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}})()`);
    const button = s.buttons[name];
    const x = canvas.x + button.x * canvas.w / s.viewport[0];
    const y = canvas.y + button.y * canvas.h / s.viewport[1];
    await cdp.call("Input.dispatchTouchEvent", {type:"touchStart",touchPoints:[{x,y,radiusX:2,radiusY:2,force:1}]},sessionId);
    await delay(60);
    await cdp.call("Input.dispatchTouchEvent", {type:"touchEnd",touchPoints:[]},sessionId);
    await delay(800);
  }
  for(let i=0;i<3;i++) {
    await tap("Numpad_6");
    if (i > 0) {
      // Retina portrait followed by rotation: size must follow CSS pixels,
      // independently of backing-store resolution and orientation.
      await cdp.call("Emulation.setDeviceMetricsOverride", {width: i === 1 ? 390 : 844, height: i === 1 ? 684 : 390, deviceScaleFactor: 3, mobile: true}, sessionId);
      await delay(800);
    }
    await tap("TextAnswerSubmit");
    await capture(cdp,sessionId,path.join(outputRoot,`input-answered-${i}.png`));
    await tap("ExerciseNextButton");
    const current = await state();
    if(current.index!==i+1) throw new Error("Touch did not advance");
    console.log(`Node ${i + 1}/3 advanced with release beyond the button edge`);
  }
  await capture(cdp,sessionId,path.join(outputRoot,"input-finished.png"));
  const numericState = await state();
  const results = numericState.results;
  if (results.length !== 1 || results[0].correct !== 3 || !results[0].passed || results[0].energyGained !== 73) throw new Error("Incorrect or duplicate completion");
  if(numericState.phase === "numeric" || numericState.phase === "numeric_done" && numericState.visible) throw new Error("Numeric exercise remains open");

  // Riproduzione della segnalazione reale: mondo 1, minimissione Riaccendere,
  // tre risposte corrette e ultimo Avanti che deve chiudere il pannello e
  // consegnare la torcia. Torniamo alla viewport verticale già verificata
  // all'avvio; le risposte le esegue l'autoplay Godot, i tre Avanti restano
  // input reali del browser.
  await cdp.call("Emulation.setDeviceMetricsOverride", {width:390,height:684,deviceScaleFactor:1,mobile:true},sessionId);
  await delay(800);
  for(let n=0;n<50 && (await state()).phase!=="torch";n++) await delay(100);
  if((await state()).phase!=="torch") throw new Error(`Torch minimission did not start: ${JSON.stringify(await state())}`);
  for(let i=0;i<3;i++) {
    for(let n=0;n<20;n++) {
      const current = await state();
      if(current.answered && current.buttons.ExerciseNextButton.visible) break;
      await delay(100);
    }
    const before = await state();
    if(!before.answered || !before.buttons.ExerciseNextButton.visible) throw new Error(`Torch step ${i + 1} was not solved: ${JSON.stringify(before)}`);
    await tapCenter("ExerciseNextButton");
    const current = await state();
    if(current.index!==i+1) throw new Error(`Torch step ${i + 1} did not advance: ${JSON.stringify(current)}`);
    console.log(`Torch minimission ${i + 1}/3 advanced`);
  }
  await capture(cdp,sessionId,path.join(outputRoot,"torch-finished.png"));
  const finalState = await state();
  if(finalState.visible || finalState.results.length!==2 || !finalState.torchOwned || !finalState.torchMissionCompleted) {
    throw new Error(`Torch minimission did not close and deliver the tool: ${JSON.stringify(finalState)}`);
  }
  if (messages.some(line => /SCRIPT ERROR|ERROR:|EXCEPTION|RuntimeError/.test(line))) throw new Error("Browser runtime errors");
  await writeFile(path.join(outputRoot, "result.json"), JSON.stringify(await state(), null, 2));
  console.log("WEB INPUT PASS");
} finally {
  await writeFile(path.join(outputRoot,"input-console.json"),JSON.stringify(messages,null,2));
  socket?.close();
  browser.kill();
  server.close();
  if (path.dirname(path.resolve(profileDir)) !== path.resolve(os.tmpdir()) || !path.basename(profileDir).startsWith("eli-input-web-")) throw new Error("Unexpected browser profile path");
  await rm(profileDir, {recursive: true, force: true, maxRetries: 8, retryDelay: 250});
}
