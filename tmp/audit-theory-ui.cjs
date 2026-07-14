const fs = require("fs");
const path = require("path");
const puppeteer = require("puppeteer-core");

const chrome = "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe";
const outDir = path.resolve("tmp", "theory-ui-audit");
fs.mkdirSync(outDir, { recursive: true });

(async () => {
  const browser = await puppeteer.launch({
    executablePath: chrome,
    headless: "new",
    args: ["--no-sandbox", "--disable-gpu", "--window-size=1280,720"],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720, deviceScaleFactor: 1 });
  page.on("console", (msg) => console.log(`[browser:${msg.type()}] ${msg.text()}`));
  page.on("pageerror", (error) => console.log(`[pageerror] ${error.message}`));
  page.setDefaultNavigationTimeout(0);
  await page.goto("http://127.0.0.1:5174/", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("canvas", { timeout: 15000 });
  await new Promise((resolve) => setTimeout(resolve, 1600));

  await page.evaluate(async () => {
    const game = window.__ELI_QUEST_GAME__;
    if (!game) throw new Error("Dev game handle not available");
    for (const scene of game.scene.getScenes(true)) scene.scene.stop();
    if (!game.scene.getScene("MathStudyScene")) {
      const mod = await import("/src/scenes/MathStudyScene.ts");
      game.scene.add("MathStudyScene", mod.MathStudyScene, false);
    }
    game.scene.start("MathStudyScene", { subjectFilter: "tutte" });
  });
  await new Promise((resolve) => setTimeout(resolve, 2200));
  await page.screenshot({ path: path.join(outDir, "01-atlante-tutte.png") });

  // Click a couple of subject filters to check the denser list layout.
  await page.mouse.click(264, 142);
  await new Promise((resolve) => setTimeout(resolve, 900));
  await page.screenshot({ path: path.join(outDir, "02-filter-italiano.png") });

  await page.mouse.click(92, 142);
  await new Promise((resolve) => setTimeout(resolve, 900));
  await page.screenshot({ path: path.join(outDir, "03-filter-tutte.png") });

  const canvasSize = await page.$eval("canvas", (canvas) => ({
    width: canvas.width,
    height: canvas.height,
    clientWidth: canvas.clientWidth,
    clientHeight: canvas.clientHeight,
  }));
  console.log(JSON.stringify({ outDir, canvasSize }, null, 2));
  await browser.close();
})();
