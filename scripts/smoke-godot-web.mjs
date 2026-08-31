import { spawn } from "node:child_process";
import { createReadStream } from "node:fs";
import { access, mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import process from "node:process";

const root = path.resolve(process.argv[2] ?? "public/godot/outdoor");
// Il guscio esportato carica `../../tablet-fullscreen.js`: in produzione quella
// e' la radice del sito, qui la radice servita e' la cartella dell'export. Senza
// questa deroga il file mancherebbe, e il rapporto elencherebbe un errore di
// console che in produzione non esiste — rumore che somiglia a una regressione.
const SITE_ROOT_FILES = new Map([
  ["/tablet-fullscreen.js", path.resolve("public/tablet-fullscreen.js")],
]);
const outputRoot = path.resolve(process.argv[3] ?? "artifacts/web-smoke-current");
const schoolProfile = process.argv.includes("--school-profile");
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
        const instrumented = source.replace(
          '"args":[]',
          '"args":["--eli-release-smoke"]',
        );
        const body = Buffer.from(instrumented, "utf8");
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

async function waitForScene(cdp, sessionId, scene, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const current = await evaluate(
      cdp,
      sessionId,
      "document.documentElement.dataset.eliScene || ''",
    );
    if (current === scene) return;
    await delay(250);
  }
  throw new Error(`La scena Web '${scene}' non è comparsa entro ${timeoutMs / 1000}s.`);
}

/// Attende che l'audio differito diventi attivo. Il ritorno e' lo stato letto,
/// cosi' il report continua a fotografare l'audio reale e non un'attesa riuscita.
async function waitForAudio(cdp, sessionId, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let last = null;
  while (Date.now() < deadline) {
    last = await evaluate(
      cdp,
      sessionId,
      "window.__eliAudioState ? JSON.parse(JSON.stringify(window.__eliAudioState)) : null",
    );
    if (last?.musicPlaying && last?.ambiencePlaying) return last;
    await delay(500);
  }
  const packState = await evaluate(cdp, sessionId, "window.__eliContentPack || 'assente'");
  throw new Error(
    `Audio non attivo entro ${timeoutMs / 1000}s. Pacchetto contenuti: ${packState}. Audio: ${JSON.stringify(last)}`,
  );
}

async function capture(cdp, sessionId, destination) {
  const screenshot = await cdp.call("Page.captureScreenshot", { format: "png" }, sessionId);
  await writeFile(destination, Buffer.from(screenshot.data, "base64"));
}

async function collectRuntimeProfile(cdp, sessionId, label) {
  const telemetry = await evaluate(
    cdp,
    sessionId,
    "window.__eliTelemetry ? JSON.parse(JSON.stringify(window.__eliTelemetry)) : null",
  );
  const performanceMetrics = await cdp.call("Performance.getMetrics", {}, sessionId);
  const heapUsage = await cdp.call("Runtime.getHeapUsage", {}, sessionId);
  const metricMap = Object.fromEntries(
    performanceMetrics.metrics.map(({ name, value }) => [name, value]),
  );
  const dom = await cdp.call("Memory.getDOMCounters", {}, sessionId);
  return {
    label,
    telemetry,
    browser: {
      jsHeapUsedMiB: Math.round((metricMap.JSHeapUsedSize ?? 0) / 104857.6) / 10,
      jsHeapTotalMiB: Math.round((metricMap.JSHeapTotalSize ?? 0) / 104857.6) / 10,
      embedderHeapUsedMiB: Math.round((heapUsage.embedderHeapUsedSize ?? 0) / 104857.6) / 10,
      backingStorageMiB: Math.round((heapUsage.backingStorageSize ?? 0) / 104857.6) / 10,
      documents: dom.documents,
      nodes: dom.nodes,
      eventListeners: dom.jsEventListeners,
    },
  };
}

await access(path.join(root, "index.html"));
await access(path.join(root, "index.pck"));
await access(path.join(root, "index.wasm"));
await mkdir(outputRoot, { recursive: true });

const chromePath = await firstExisting(chromeCandidates);
const server = await startStaticServer();
const address = server.address();
const port = typeof address === "object" && address ? address.port : 0;
const profileDir = await mkdtemp(path.join(os.tmpdir(), "eli-godot-web-smoke-"));
const browser = spawn(
  chromePath,
  [
    "--headless=new",
    "--enable-gpu",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-background-networking",
    "--disable-component-update",
    "--disable-sync",
    "--remote-debugging-port=0",
    `--user-data-dir=${profileDir}`,
    "--window-size=1280,720",
    "about:blank",
  ],
  { stdio: ["ignore", "pipe", "pipe"], windowsHide: true },
);

let socket;
try {
  const devToolsUrl = await waitForDevTools(profileDir);
  socket = await connectWebSocket(devToolsUrl);
  const cdp = new Cdp(socket);
  const { targetId } = await cdp.call("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await cdp.call("Target.attachToTarget", { targetId, flatten: true });

  const consoleMessages = [];
  const exceptions = [];
  cdp.on("Runtime.consoleAPICalled", (event) => {
    consoleMessages.push(event.args.map((arg) => arg.value ?? arg.description ?? "").join(" "));
  });
  cdp.on("Log.entryAdded", ({ entry }) => consoleMessages.push(`${entry.level}: ${entry.text}`));
  cdp.on("Runtime.exceptionThrown", ({ exceptionDetails }) => {
    exceptions.push(exceptionDetails.exception?.description ?? exceptionDetails.text);
  });

  await cdp.call("Page.enable", {}, sessionId);
  await cdp.call("Runtime.enable", {}, sessionId);
  await cdp.call("Log.enable", {}, sessionId);
  await cdp.call("Network.enable", {}, sessionId);
  await cdp.call("Performance.enable", {}, sessionId);
  await cdp.call("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 1 }, sessionId);
  if (schoolProfile) {
    await cdp.call("Emulation.setCPUThrottlingRate", { rate: 4 }, sessionId);
    await cdp.call("Network.emulateNetworkConditions", {
      offline: false,
      latency: 40,
      downloadThroughput: 2_500_000,
      uploadThroughput: 625_000,
      connectionType: "wifi",
    }, sessionId);
  }

  const startedAt = performance.now();
  const runtimeProfiles = [];
  await cdp.call("Page.navigate", { url: `http://127.0.0.1:${port}/index.html` }, sessionId);
  await waitForScene(cdp, sessionId, "boot", 60_000);
  const bootMs = Math.round(performance.now() - startedAt);
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-menu.png"));

  const canvas = await evaluate(
    cdp,
    sessionId,
    `(() => {
      const rect = document.querySelector("#canvas").getBoundingClientRect();
      return { left: rect.left, top: rect.top, width: rect.width, height: rect.height };
    })()`,
  );
  const x = canvas.left + canvas.width * 0.5;
  const tapRatios = [0.56, 0.60, 0.52];
  let enteredWorld = false;
  for (const ratio of tapRatios) {
    const y = canvas.top + canvas.height * ratio;
    await cdp.call("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [{ x, y, radiusX: 2, radiusY: 2, force: 1 }],
    }, sessionId);
    await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
    try {
      await waitForScene(cdp, sessionId, "world", 8_000);
      enteredWorld = true;
      break;
    } catch {
      // Ritenta su una quota vicina: il canvas può essere letterboxed.
    }
  }
  if (!enteredWorld) throw new Error("Il tap sul pulsante GIOCA non ha aperto il mondo.");

  // Un profilo Chrome nuovo vede correttamente la soglia didattica del primo
  // mondo. Lo smoke deve attraversarla come farebbe lo studente: lasciarla
  // aperta blocca la fisica di Eli e trasforma il successivo test della nave in
  // un falso timeout. Il pulsante ENTRA occupa tutta la larghezza utile e resta
  // ancorato a questa quota anche quando il canvas è letterboxed.
  await delay(500);
  const introY = canvas.top + canvas.height * 0.68;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x, y: introY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);

  const worldMs = Math.round(performance.now() - startedAt);
  await delay(2_000);
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-world.png"));
  runtimeProfiles.push(await collectRuntimeProfile(cdp, sessionId, "world"));
  const accessibility = await evaluate(
    cdp,
    sessionId,
    "window.__eliAccessibility ? JSON.parse(JSON.stringify(window.__eliAccessibility)) : null",
  );
  if (!accessibility?.highContrast || !accessibility?.reducedMotion) {
    throw new Error("Il profilo browser non ha applicato contrasto elevato e riduzione movimento.");
  }
  // L'audio non e' piu' nel `.pck` di boot: arriva con `content.pck`, chiesto a
  // mondo gia' interattivo. Quindi qui non si misura piu' «suona subito» — che
  // non e' piu' il contratto — ma «il pacchetto differito arriva e l'audio
  // riparte da solo». Se questa attesa scade, il pacchetto non si sta montando:
  // e' un guasto vero, non un ritardo.
  const audioAtWorld = await waitForAudio(cdp, sessionId, 60_000);

  // Esc ora mette in pausa (28 agosto 2026, vedi outdoor_world.gd ~6517): non è
  // più la scorciatoia verso la nave. Quella scorciatoia vive nel pulsante
  // missione in alto a destra, che diventa "RAGGIUNGI LA NAVE" da solo quando
  // l'esame è pronto e imposta la stessa rotta fisica di prima — attraversa
  // quindi davvero corridoio sicuro, collisioni e streaming, non cambia scena.
  const shipGuideX = canvas.left + canvas.width * 0.92;
  const shipGuideY = canvas.top + canvas.height * 0.055;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: shipGuideX, y: shipGuideY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await delay(6_000);

  const actionX = canvas.left + canvas.width * 0.5;
  const actionY = canvas.top + canvas.height * 0.79;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: actionX, y: actionY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);

  let shipEntry = "touch";
  try {
    await waitForScene(cdp, sessionId, "ship", 8_000);
  } catch {
    // Fallback diagnostico: se la quota del Control differisce per il browser,
    // Space usa la stessa azione contestuale e distingue un problema di layout.
    shipEntry = "keyboard-fallback";
    await cdp.call("Input.dispatchKeyEvent", {
      type: "rawKeyDown",
      key: " ",
      code: "Space",
      windowsVirtualKeyCode: 32,
    }, sessionId);
    await cdp.call("Input.dispatchKeyEvent", {
      type: "keyUp",
      key: " ",
      code: "Space",
      windowsVirtualKeyCode: 32,
    }, sessionId);
    await waitForScene(cdp, sessionId, "ship", 8_000);
  }
  const shipMs = Math.round(performance.now() - startedAt);
  await delay(1_500);
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-ship.png"));
  runtimeProfiles.push(await collectRuntimeProfile(cdp, sessionId, "ship"));

  const shipState = await evaluate(
    cdp,
    sessionId,
    "window.__eliShipState ? JSON.parse(JSON.stringify(window.__eliShipState)) : null",
  );
  if (!shipState?.examReady) throw new Error("La fixture Web non rende disponibile l’esame.");
  // Il Control vive in container annidati: Godot Web 4.7 può restituire un
  // get_global_rect() verticale pre-layout errato. Il banco resta ancorato al
  // fondo della scheda destra, quindi il rapporto di viewport è autoritativo.
  const repairX = canvas.left + canvas.width * 0.87;
  const repairY = canvas.top + canvas.height * 0.91;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: repairX, y: repairY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  const examOpenDeadline = Date.now() + 8_000;
  while (
    Date.now() < examOpenDeadline
    && await evaluate(cdp, sessionId, "document.documentElement.dataset.eliExam || ''") !== "open"
  ) {
    await delay(250);
  }
  if (await evaluate(cdp, sessionId, "document.documentElement.dataset.eliExam || ''") !== "open") {
    throw new Error(
      `Il touch sul banco nave non ha aperto l’esame: ${JSON.stringify({
        shipState,
        canvas,
        repairX,
        repairY,
      })}`,
    );
  }
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-exam.png"));
  const completeExamX = canvas.left + canvas.width * 0.5;
  const completeExamY = canvas.top + canvas.height * 0.95;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: completeExamX, y: completeExamY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  const examPassedDeadline = Date.now() + 15_000;
  while (
    Date.now() < examPassedDeadline
    && await evaluate(cdp, sessionId, "document.documentElement.dataset.eliExam || ''") !== "passed"
  ) {
    await delay(250);
  }
  if (await evaluate(cdp, sessionId, "document.documentElement.dataset.eliExam || ''") !== "passed") {
    throw new Error("L’esame di collaudo non ha completato la progressione.");
  }

  // Il pulsante TORNA AL MONDO occupa l'estremità destra della barra superiore.
  const backX = canvas.left + canvas.width * 0.92;
  const backY = canvas.top + canvas.height * 0.055;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: backX, y: backY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await waitForScene(cdp, sessionId, "world", 12_000);
  // Anche il mondo appena sbloccato presenta la propria soglia didattica una
  // volta sola. Attraversala prima di guidare Eli verso il POI: finché è aperta
  // la fisica è sospesa e il tap cadrebbe sul pannello, non sulla missione.
  await delay(500);
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x, y: introY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  const roundTripMs = Math.round(performance.now() - startedAt);
  await delay(1_500);
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-world-return.png"));
  runtimeProfiles.push(await collectRuntimeProfile(cdp, sessionId, "world-return"));
  const returnedState = await evaluate(
    cdp,
    sessionId,
    "window.__eliAccessibility ? JSON.parse(JSON.stringify(window.__eliAccessibility)) : null",
  );
  if (returnedState?.worldLevel !== 2 || returnedState?.saveMarker !== "web-release-save-v1") {
    throw new Error("Il ritorno post-esame non ha conservato mondo successivo e marcatore del save.");
  }
  // Segue il flusso reale di proprietà della missione: il residente la affida,
  // poi SEGUI LA MISSIONE conduce al suo POI. Puntare subito il POI aggirava la
  // richiesta e il gioco rispondeva correttamente «parla con Corinna» senza
  // aprire alcun esercizio.
  const guideX = canvas.left + canvas.width * 0.92;
  const guideY = canvas.top + canvas.height * 0.055;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: guideX, y: guideY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await delay(7_000);

  // Apre il dialogo di richiesta del residente.
  const contextualY = canvas.top + canvas.height * 0.79;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: actionX, y: contextualY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await delay(500);
  // Le richieste dei residenti hanno tre pagine; il profilo riduce le
  // animazioni, quindi ogni tocco avanza esattamente di una pagina.
  for (let page = 0; page < 3; page += 1) {
    await cdp.call("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [{ x: actionX, y: contextualY, radiusX: 2, radiusY: 2, force: 1 }],
    }, sessionId);
    await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
    await delay(250);
  }

  // Dal completamento dei giochi-personaggio (13 agosto 2026) chiudere il
  // dialogo apre anche il minigioco del residente. Lo smoke sta collaudando il
  // percorso missione, quindi usa la sua uscita volontaria: non può lasciare il
  // pannello sopra il mondo e poi concludere erroneamente che il POI non
  // risponde. Tutti i pannelli condividono il pulsante in fondo alla carta.
  const leaveCharacterGameY = canvas.top + canvas.height * 0.75;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: actionX, y: leaveCharacterGameY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await delay(500);

  // Ora la stessa guida punta all'evento appena accettato.
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: guideX, y: guideY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await delay(9_000);
  let exerciseFormat = "";
  for (const actionRatio of [0.79, 0.82, 0.76]) {
    const missionActionY = canvas.top + canvas.height * actionRatio;
    await cdp.call("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [{ x: actionX, y: missionActionY, radiusX: 2, radiusY: 2, force: 1 }],
    }, sessionId);
    await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
    const attemptDeadline = Date.now() + 3_000;
    while (Date.now() < attemptDeadline && exerciseFormat === "") {
      exerciseFormat = await evaluate(
        cdp,
        sessionId,
        "document.documentElement.dataset.eliExercise || ''",
      );
      if (exerciseFormat === "") await delay(250);
    }
    if (exerciseFormat !== "") break;
  }
  if (exerciseFormat === "") throw new Error("Il touch sul POI non ha aperto una missione variata.");
  await delay(2_000);

  // Il conteggio degli effetti si verifica QUI e non all'ingresso nel mondo: i
  // primi suoni d'interfaccia cadono mentre `content.pck` e' ancora in volo, ed
  // e' voluto. A questo punto il pacchetto e' montato da un pezzo e le decine di
  // tocchi fatti nel mezzo devono aver prodotto feedback.
  const audioAfterPlay = await evaluate(
    cdp,
    sessionId,
    "window.__eliAudioState ? JSON.parse(JSON.stringify(window.__eliAudioState)) : null",
  );
  if (!(audioAfterPlay?.playCount >= 1)) {
    throw new Error(
      `Nessun effetto audio riprodotto dopo il montaggio dei contenuti: ${JSON.stringify(audioAfterPlay)}`,
    );
  }

  await capture(cdp, sessionId, path.join(outputRoot, "smoke-exercise.png"));
  runtimeProfiles.push(await collectRuntimeProfile(cdp, sessionId, "exercise"));
  await cdp.call("Emulation.setDeviceMetricsOverride", {
    width: 1024,
    height: 600,
    deviceScaleFactor: 1,
    mobile: true,
    screenOrientation: { type: "landscapePrimary", angle: 90 },
  }, sessionId);
  await delay(700);
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-world-landscape.png"));
  await cdp.call("Emulation.setDeviceMetricsOverride", {
    width: 600,
    height: 900,
    deviceScaleFactor: 1,
    mobile: true,
    screenOrientation: { type: "portraitPrimary", angle: 0 },
  }, sessionId);
  await delay(700);
  await capture(cdp, sessionId, path.join(outputRoot, "smoke-world-portrait.png"));
  await cdp.call("Emulation.setDeviceMetricsOverride", {
    width: 1280,
    height: 720,
    deviceScaleFactor: 1,
    mobile: false,
    screenOrientation: { type: "landscapePrimary", angle: 90 },
  }, sessionId);
  await delay(700);

  const timings = await evaluate(
    cdp,
    sessionId,
    `performance.getEntriesByType("resource")
      .filter((entry) => /index\\.(pck|wasm|js)$/.test(entry.name))
      .map((entry) => ({
        file: entry.name.split("/").pop(),
        durationMs: Math.round(entry.duration),
        transferBytes: entry.transferSize,
        decodedBytes: entry.decodedBodySize
      }))`,
  );
  const engineStarted = consoleMessages.some((line) => line.includes("Godot Engine"));
  if (!engineStarted) throw new Error("Il log del browser non conferma l'avvio del motore Godot.");
  if (exceptions.length > 0) throw new Error(`Eccezioni JavaScript: ${exceptions.join(" | ")}`);

  await cdp.call("Page.reload", { ignoreCache: true }, sessionId);
  await waitForScene(cdp, sessionId, "boot", 60_000);
  const persistedSaveMarker = await evaluate(
    cdp,
    sessionId,
    "document.documentElement.dataset.eliSaveMarker || ''",
  );
  if (persistedSaveMarker !== "web-release-save-v1") {
    throw new Error("Il save Web non è sopravvissuto al reload completo della pagina.");
  }

  const report = {
    ok: true,
    profileMode: schoolProfile ? "school-simulated" : "native",
    cpuThrottle: schoolProfile ? 4 : 1,
    networkProfile: schoolProfile ? "20 Mbps down / 5 Mbps up / 40 ms" : "local",
    browser: chromePath,
    bootMs,
    worldMs,
    shipMs,
    roundTripMs,
    touchNavigation: "boot -> world -> ship -> exam -> world 2 -> exercise",
    shipEntry,
    exerciseFormat,
    accessibility,
    audioAtWorld,
    // Lo stato dell'audio a FINE giro, non solo all'ingresso nel mondo. Serve a
    // vedere il difetto che l'ingresso non puo' mostrare: una musica che parte e
    // poi muore a meta' sessione. In headless non si puo' misurare — il driver
    // dummy spegne qualunque player dopo un secondo, anche uno costruito a mano
    // fuori dal manager — quindi questo e' l'unico posto che lo direbbe.
    audioAfterPlay,
    persistedSaveMarker,
    resources: timings,
    runtimeProfiles,
    consoleErrors: consoleMessages.filter((line) => /^error:/i.test(line)),
  };
  await writeFile(path.join(outputRoot, "web-smoke-report.json"), `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report, null, 2));
} finally {
  if (socket?.readyState === WebSocket.OPEN) socket.close();
  browser.kill();
  server.closeAllConnections?.();
  await new Promise((resolve) => server.close(resolve));
  const tempRoot = path.resolve(os.tmpdir());
  const resolvedProfile = path.resolve(profileDir);
  if (
    resolvedProfile.startsWith(`${tempRoot}${path.sep}`) &&
    path.basename(resolvedProfile).startsWith("eli-godot-web-smoke-")
  ) {
    await rm(resolvedProfile, { recursive: true, force: true, maxRetries: 4, retryDelay: 150 });
  }
}
