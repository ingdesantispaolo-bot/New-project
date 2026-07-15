const { spawn } = require("node:child_process");
const { mkdirSync, writeFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join, resolve } = require("node:path");

const chromePath = "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe";
const outDir = resolve("tmp", "mental-gym-audit");
const cdpPort = 9333;
mkdirSync(outDir, { recursive: true });
console.log(`audit out: ${outDir}`);

const sleep = (ms) => new Promise((resolveSleep) => setTimeout(resolveSleep, ms));

async function getJson(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText} for ${url}`);
  return response.json();
}

async function waitForChrome() {
  for (let i = 0; i < 60; i += 1) {
    try {
      return await getJson(`http://127.0.0.1:${cdpPort}/json/version`);
    } catch {
      await sleep(250);
    }
  }
  throw new Error("Chrome CDP did not start");
}

function connect(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  const events = [];
  ws.addEventListener("message", (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      if (msg.error) reject(new Error(JSON.stringify(msg.error)));
      else resolve(msg.result);
      return;
    }
    events.push(msg);
  });
  return new Promise((resolve, reject) => {
    ws.addEventListener("open", () => {
      resolve({
        events,
        send(method, params = {}) {
          id += 1;
          ws.send(JSON.stringify({ id, method, params }));
          return new Promise((sendResolve, sendReject) => pending.set(id, { resolve: sendResolve, reject: sendReject }));
        },
        close() {
          ws.close();
        },
      });
    });
    ws.addEventListener("error", reject);
  });
}

async function main() {
  const keepAlive = setInterval(() => {}, 1000);
  console.log("starting chrome");
  const chrome = spawn(chromePath, [
    "--headless=new",
    "--disable-gpu",
    "--no-first-run",
    "--no-default-browser-check",
    "--window-size=1280,720",
    `--remote-debugging-port=${cdpPort}`,
    `--user-data-dir=${resolve(tmpdir(), "eli-quest-chrome-mental-audit-9333")}`,
    "about:blank",
  ], { stdio: "ignore" });

  const consoleLines = [];
  try {
    console.log("waiting cdp");
    await waitForChrome();
    console.log("creating target");
    let target;
    for (let i = 0; i < 10; i += 1) {
      try {
        target = await getJson(`http://127.0.0.1:${cdpPort}/json/new?http://127.0.0.1:5174/`, { method: "PUT" });
        break;
      } catch (error) {
        if (i === 9) throw error;
        await sleep(250);
      }
    }
    console.log("connecting ws");
    const cdp = await connect(target.webSocketDebuggerUrl);
    console.log("connected");
    await cdp.send("Runtime.enable");
    await cdp.send("Page.enable");
    await cdp.send("Log.enable");
    await cdp.send("Emulation.setDeviceMetricsOverride", {
      width: 1280,
      height: 720,
      deviceScaleFactor: 1,
      mobile: false,
    });

    const start = Date.now();
    while (Date.now() - start < 10_000) {
      const ready = await cdp.send("Runtime.evaluate", {
        expression: "Boolean(window.__ELI_QUEST_GAME__)",
        returnByValue: true,
      });
      if (ready.result.value) break;
      await sleep(250);
    }
    await sleep(1800);

    await cdp.send("Runtime.evaluate", {
      awaitPromise: true,
      expression: `
        (async () => {
          const game = window.__ELI_QUEST_GAME__;
          const mod = await import('/src/scenes/LogicGymScene.ts');
          if (!game.scene.getScene('LogicGymScene')) {
            game.scene.add('LogicGymScene', mod.LogicGymScene, true);
          } else {
            game.scene.start('LogicGymScene');
          }
          return true;
        })()
      `,
      returnByValue: true,
    });
    await sleep(900);

    const hub = await cdp.send("Page.captureScreenshot", { format: "png" });
    if (!hub.data) throw new Error("Missing hub screenshot data");
    const hubPath = join(outDir, "01-hub.png");
    writeFileSync(hubPath, Buffer.from(hub.data, "base64"));
    console.log(`wrote ${hubPath}`);

    await cdp.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: 754, y: 246 });
    await cdp.send("Input.dispatchMouseEvent", { type: "mousePressed", x: 754, y: 246, button: "left", clickCount: 1 });
    await cdp.send("Input.dispatchMouseEvent", { type: "mouseReleased", x: 754, y: 246, button: "left", clickCount: 1 });
    await sleep(900);

    const round = await cdp.send("Page.captureScreenshot", { format: "png" });
    if (!round.data) throw new Error("Missing round screenshot data");
    const roundPath = join(outDir, "02-mental-round.png");
    writeFileSync(roundPath, Buffer.from(round.data, "base64"));
    console.log(`wrote ${roundPath}`);

    for (const event of cdp.events) {
      if (event.method === "Runtime.consoleAPICalled") {
        consoleLines.push(`console.${event.params.type}: ${event.params.args.map((arg) => arg.value ?? arg.description ?? "").join(" ")}`);
      }
      if (event.method === "Runtime.exceptionThrown") {
        consoleLines.push(`exception: ${event.params.exceptionDetails.text}`);
      }
      if (event.method === "Log.entryAdded") {
        consoleLines.push(`${event.params.entry.level}: ${event.params.entry.text}`);
      }
    }
    const consolePath = join(outDir, "console.log");
    writeFileSync(consolePath, consoleLines.join("\n"));
    console.log(`wrote ${consolePath}`);
    cdp.close();
    if (consoleLines.some((line) => /error|exception/i.test(line))) {
      throw new Error(consoleLines.join("\n"));
    }
  } finally {
    clearInterval(keepAlive);
    chrome.kill();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
