import { spawn } from "node:child_process";
import { createReadStream } from "node:fs";
import { access, mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import process from "node:process";

const root = path.resolve(process.argv[2] ?? "artifacts/web-smoke-optimized");
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
      const requestedPath = path.resolve(root, `.${relative}`);
      const insideRoot = requestedPath === root || requestedPath.startsWith(`${root}${path.sep}`);
      if (!insideRoot) {
        response.writeHead(403).end("Forbidden");
        return;
      }

      const info = await stat(requestedPath);
      if (!info.isFile()) {
        response.writeHead(404).end("Not found");
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
        if (message.error) waiter.reject(new Error(message.error.message));
        else waiter.resolve(message.result);
        return;
      }
      for (const listener of this.listeners.get(message.method) ?? []) listener(message.params);
    });
  }

  call(method, params = {}, sessionId = undefined) {
    const id = ++this.serial;
    this.socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    return new Promise((resolve, reject) => this.pending.set(id, { resolve, reject }));
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

async function capture(cdp, sessionId, destination) {
  const screenshot = await cdp.call("Page.captureScreenshot", { format: "png" }, sessionId);
  await writeFile(destination, Buffer.from(screenshot.data, "base64"));
}

await access(path.join(root, "index.html"));
await access(path.join(root, "index.pck"));
await access(path.join(root, "index.wasm"));

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
  await cdp.call("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 1 }, sessionId);

  const startedAt = performance.now();
  await cdp.call("Page.navigate", { url: `http://127.0.0.1:${port}/index.html` }, sessionId);
  await waitForScene(cdp, sessionId, "boot", 60_000);
  const bootMs = Math.round(performance.now() - startedAt);
  await capture(cdp, sessionId, path.join(root, "smoke-menu.png"));

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

  const worldMs = Math.round(performance.now() - startedAt);
  await delay(2_000);
  await capture(cdp, sessionId, path.join(root, "smoke-world.png"));

  // Nel runtime live Esc imposta una rotta fisica verso la nave: non cambia
  // scena e attraversa quindi davvero corridoio sicuro, collisioni e streaming.
  await cdp.call("Input.dispatchKeyEvent", {
    type: "rawKeyDown",
    key: "Escape",
    code: "Escape",
    windowsVirtualKeyCode: 27,
  }, sessionId);
  await cdp.call("Input.dispatchKeyEvent", {
    type: "keyUp",
    key: "Escape",
    code: "Escape",
    windowsVirtualKeyCode: 27,
  }, sessionId);
  await delay(6_000);

  const actionX = canvas.left + canvas.width * 0.5;
  const actionY = canvas.top + canvas.height * 0.91;
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
  await capture(cdp, sessionId, path.join(root, "smoke-ship.png"));

  // Il pulsante TORNA AL MONDO occupa l'estremità destra della barra superiore.
  const backX = canvas.left + canvas.width * 0.92;
  const backY = canvas.top + canvas.height * 0.055;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: backX, y: backY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await waitForScene(cdp, sessionId, "world", 12_000);
  const roundTripMs = Math.round(performance.now() - startedAt);
  await delay(1_500);
  await capture(cdp, sessionId, path.join(root, "smoke-world-return.png"));

  // Dal ritorno presso il portale, il comando in alto a destra guida alla
  // missione più vicina. Il secondo tap usa il grande pulsante contestuale.
  const guideX = canvas.left + canvas.width * 0.92;
  const guideY = canvas.top + canvas.height * 0.04;
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: guideX, y: guideY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  await delay(6_000);
  await cdp.call("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: actionX, y: actionY, radiusX: 2, radiusY: 2, force: 1 }],
  }, sessionId);
  await cdp.call("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] }, sessionId);
  const exerciseDeadline = Date.now() + 10_000;
  let exerciseFormat = "";
  while (Date.now() < exerciseDeadline && exerciseFormat === "") {
    exerciseFormat = await evaluate(
      cdp,
      sessionId,
      "document.documentElement.dataset.eliExercise || ''",
    );
    if (exerciseFormat === "") await delay(250);
  }
  if (exerciseFormat === "") throw new Error("Il touch sul POI non ha aperto una missione variata.");
  await delay(800);
  await capture(cdp, sessionId, path.join(root, "smoke-exercise.png"));

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

  const report = {
    ok: true,
    browser: chromePath,
    bootMs,
    worldMs,
    shipMs,
    roundTripMs,
    touchNavigation: "boot -> world -> ship -> world",
    shipEntry,
    exerciseFormat,
    resources: timings,
    consoleErrors: consoleMessages.filter((line) => /^error:/i.test(line)),
  };
  await writeFile(path.join(root, "web-smoke-report.json"), `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report, null, 2));
} finally {
  if (socket?.readyState === WebSocket.OPEN) socket.close();
  browser.kill();
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
