const fs = require("fs");
const path = require("path");
const puppeteer = require("puppeteer-core");

const chrome = "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe";
const outDir = path.resolve("tmp", "circuit-repro");
fs.mkdirSync(outDir, { recursive: true });

(async () => {
  const browser = await puppeteer.launch({
    executablePath: chrome,
    headless: "new",
    args: ["--no-sandbox", "--disable-gpu", "--window-size=1280,720"],
  });
  const page = await browser.newPage();
  const logs = [];
  await page.setViewport({ width: 1280, height: 720, deviceScaleFactor: 1 });
  page.on("console", (msg) => {
    const line = `[browser:${msg.type()}] ${msg.text()}`;
    logs.push(line);
    console.log(line);
  });
  page.on("pageerror", (error) => {
    const line = `[pageerror] ${error.stack || error.message}`;
    logs.push(line);
    console.log(line);
  });
  page.setDefaultNavigationTimeout(0);
  await page.goto("http://127.0.0.1:5174/", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("canvas", { timeout: 15000 });
  await new Promise((resolve) => setTimeout(resolve, 1200));
  await page.evaluate(async () => {
    const game = window.__ELI_QUEST_GAME__;
    if (!game) throw new Error("Dev game handle not available");
    const { proceduralDirector } = await import("/src/procedural/ProceduralDirector.ts");
    const { saveSystem } = await import("/src/core/SaveSystem.ts");
    const { ProceduralMissionScene } = await import("/src/scenes/ProceduralMissionScene.ts");
    const mission = proceduralDirector.generateFreshMission(1, ["elettronica"]);
    const run = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["elettronica"],
      mode: "training",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      startedAt: new Date().toISOString(),
    };
    saveSystem.setProceduralRun(run);
    for (const scene of game.scene.getScenes(true)) scene.scene.stop();
    if (!game.scene.getScene("ProceduralMissionScene")) {
      game.scene.add("ProceduralMissionScene", ProceduralMissionScene, false);
    }
    game.scene.start("ProceduralMissionScene", { autoOpenPuzzle: "circuit" });
  });
  await new Promise((resolve) => setTimeout(resolve, 2500));
  await page.screenshot({ path: path.join(outDir, "01-ready.png") });
  await page.mouse.click(640, 439);
  await new Promise((resolve) => setTimeout(resolve, 2200));
  await page.screenshot({ path: path.join(outDir, "02-circuit-open.png") });
  fs.writeFileSync(path.join(outDir, "console.log"), logs.join("\n"), "utf8");
  await browser.close();
})();
