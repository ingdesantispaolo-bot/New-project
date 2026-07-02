import fs from "node:fs/promises";
import path from "node:path";
import puppeteer from "puppeteer-core";

const url = process.env.AUDIT_URL ?? process.argv.find((arg) => arg.startsWith("--url="))?.slice("--url=".length) ?? "http://127.0.0.1:5173/";
const chromePath = process.env.CHROME_PATH ?? "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe";
const outDir = path.resolve(".tmp-mission-layout-audit");

const viewports = [
  { name: "desktop-1280x720", width: 1280, height: 720 },
  { name: "laptop-1366x768", width: 1366, height: 768 },
  { name: "tablet-1024x768", width: 1024, height: 768 },
  { name: "mobile-390x844", width: 390, height: 844 },
];

const waitMs = 30_000;

async function main() {
  await fs.mkdir(outDir, { recursive: true });
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: chromePath,
    args: ["--no-sandbox", "--disable-gpu"],
  });

  const results = [];
  try {
    for (const viewport of viewports) {
      console.log(`Audit ${viewport.name}...`);
      const page = await browser.newPage();
      const errors = [];
      page.on("pageerror", (error) => errors.push(error.message));
      page.on("console", (message) => {
        if (message.type() === "error") errors.push(message.text());
      });
      try {
        await page.setViewport({ width: viewport.width, height: viewport.height, deviceScaleFactor: 1 });
        await page.goto(url, { waitUntil: "domcontentloaded", timeout: waitMs });
        await page.waitForSelector("canvas", { timeout: waitMs });
        await page.waitForFunction(() => Boolean(window.__ELI_QUEST_GAME__?.scene), { timeout: waitMs });

        await page.evaluate(async ({ seed }) => {
          const game = window.__ELI_QUEST_GAME__;
          const [{ proceduralDirector }, { saveSystem }, { settingsSystem }, { ProceduralMissionScene }] = await Promise.all([
            import("/src/procedural/ProceduralDirector.ts"),
            import("/src/core/SaveSystem.ts"),
            import("/src/core/SettingsSystem.ts"),
            import("/src/scenes/ProceduralMissionScene.ts"),
          ]);
          settingsSystem.setReducedEffects(true);
          settingsSystem.setGraphicsQuality("comfort");
          const mission = proceduralDirector.generateMission(seed, 8, ["libera"]);
          const now = new Date().toISOString();
          saveSystem.load();
          saveSystem.pauseActiveProceduralRun();
          saveSystem.setProceduralRun({
            seed: mission.seed,
            difficulty: mission.difficulty,
            focus: ["libera"],
            mode: "mission",
            mission,
            hintsUsed: 0,
            solvedPuzzleIds: [],
            score: { total: 0, byPuzzle: {}, byDomain: {} },
            puzzleStats: {},
            timerState: "running",
            createdAt: now,
            activeElapsedMs: 0,
            startedAt: now,
          });
          if (!game.scene.keys.ProceduralMissionScene) {
            game.scene.add("ProceduralMissionScene", ProceduralMissionScene, false);
          }
          game.scene.start("ProceduralMissionScene");
        }, { seed: `LAYOUT-AUDIT-${viewport.name}` });

        await page.waitForFunction(() => {
          const scene = window.__ELI_QUEST_GAME__?.scene?.keys?.ProceduralMissionScene;
          return Boolean(scene?.sys?.isActive?.() && scene.children?.list?.some((item) => item.type === "Text" && String(item.text).includes("AZIONE")));
        }, { timeout: waitMs });
        await new Promise((resolve) => setTimeout(resolve, 900));

        const screenshotPath = path.join(outDir, `${viewport.name}.png`);
        await page.screenshot({ path: screenshotPath });
        const audit = await page.evaluate(() => {
          const scene = window.__ELI_QUEST_GAME__?.scene?.keys?.ProceduralMissionScene;
          const canvas = document.querySelector("canvas");
          const texts = (scene?.children?.list ?? [])
            .filter((item) => item.type === "Text" && item.visible && item.alpha > 0 && typeof item.getBounds === "function")
            .map((item) => {
              const bounds = item.getBounds();
              return {
                text: String(item.text ?? ""),
                x: Math.round(bounds.x),
                y: Math.round(bounds.y),
                right: Math.round(bounds.right),
                bottom: Math.round(bounds.bottom),
              };
            });
          const overflows = texts.filter((item) => item.x < -2 || item.y < -2 || item.right > 1282 || item.bottom > 722);
          const objectivePanels = texts.filter((item) => item.text.includes("ORA") && item.text.includes("AZIONE"));
          const longPermanentTexts = texts.filter((item) => item.text.length > 420);
          return {
            canvas: canvas ? { width: canvas.width, height: canvas.height, clientWidth: canvas.clientWidth, clientHeight: canvas.clientHeight } : null,
            textCount: texts.length,
            overflows,
            objectivePanelCount: objectivePanels.length,
            longPermanentTexts: longPermanentTexts.map((item) => item.text.slice(0, 90)),
          };
        });

        const failures = [];
        if (errors.length > 0) failures.push(`console/page errors: ${errors.join(" | ")}`);
        if (!audit.canvas || audit.canvas.width !== 1280 || audit.canvas.height !== 720) failures.push("canvas 1280x720 non trovato");
        if (audit.overflows.length > 0) failures.push(`${audit.overflows.length} testi fuori canvas`);
        if (audit.objectivePanelCount !== 1) failures.push(`pannelli obiettivo attesi 1, trovati ${audit.objectivePanelCount}`);
        if (audit.longPermanentTexts.length > 0) failures.push(`testi permanenti troppo lunghi: ${audit.longPermanentTexts.join(" / ")}`);

        results.push({ viewport, screenshotPath, audit, errors, failures });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        results.push({ viewport, screenshotPath: undefined, audit: undefined, errors, failures: [message] });
      } finally {
        await page.close();
      }
    }
  } finally {
    await fs.writeFile(path.join(outDir, "report.json"), JSON.stringify(results, null, 2));
    const failed = results.filter((result) => result.failures.length > 0);
    for (const result of results) {
      console.log(`${result.viewport.name}: ${result.failures.length === 0 ? "OK" : result.failures.join("; ")} (${result.screenshotPath ?? "nessuno screenshot"})`);
    }
    await closeBrowser(browser);
    if (failed.length > 0) {
      process.exitCode = 1;
    }
  }
}

async function closeBrowser(browser) {
  const closed = await Promise.race([
    browser.close().then(() => true).catch(() => false),
    new Promise((resolve) => setTimeout(() => resolve(false), 5_000)),
  ]);
  if (!closed) {
    browser.process()?.kill("SIGKILL");
  }
}

await main();
