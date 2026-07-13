import fs from "node:fs/promises";
import path from "node:path";
import puppeteer from "puppeteer-core";

const url = process.env.AUDIT_URL ?? process.argv.find((arg) => arg.startsWith("--url="))?.slice("--url=".length) ?? "http://127.0.0.1:5173/";
const chromePath = process.env.CHROME_PATH ?? "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe";
const outDir = path.resolve(".tmp-mission-layout-audit");
const auditDifficulty = Number(process.env.AUDIT_DIFFICULTY ?? process.argv.find((arg) => arg.startsWith("--difficulty="))?.slice("--difficulty=".length) ?? 8);
const auditAttempts = Number(process.env.AUDIT_ATTEMPTS ?? process.argv.find((arg) => arg.startsWith("--attempts="))?.slice("--attempts=".length) ?? 2);

const viewports = [
  { name: "desktop-1280x720", width: 1280, height: 720 },
  { name: "laptop-1366x768", width: 1366, height: 768 },
  { name: "tablet-1024x768", width: 1024, height: 768 },
  { name: "mobile-390x844", width: 390, height: 844 },
];

const waitMs = 45_000;
const protocolTimeoutMs = 120_000;

function failureScreenshotPath(viewport) {
  return path.join(outDir, `${viewport.name}-failure.png`);
}

function isRetryableFailure(failures) {
  return failures.some((failure) => /Runtime\.callFunctionOn timed out|ProtocolError|Navigation timeout|Waiting failed|Target closed/i.test(failure));
}

async function captureFailure(page, viewport) {
  const screenshotPath = failureScreenshotPath(viewport);
  try {
    await page.screenshot({ path: screenshotPath });
  } catch {
    return undefined;
  }
  return screenshotPath;
}

async function pageDiagnostics(page) {
  try {
    return await page.evaluate(() => {
      const game = window.__ELI_QUEST_GAME__;
      const scene = game?.scene?.keys?.ProceduralMissionScene;
      const canvas = document.querySelector("canvas");
      const texts = (scene?.children?.list ?? [])
        .filter((item) => item.type === "Text" && item.visible && item.alpha > 0)
        .map((item) => String(item.text ?? "").slice(0, 90));
      return {
        auditPhase: window.__ELI_AUDIT_PHASE__ ?? "unknown",
        gameReady: Boolean(game?.scene),
        sceneKnown: Boolean(scene),
        sceneActive: Boolean(scene?.sys?.isActive?.()),
        childCount: scene?.children?.list?.length ?? 0,
        textCount: texts.length,
        sampleTexts: texts.slice(0, 8),
        canvas: canvas ? { width: canvas.width, height: canvas.height, clientWidth: canvas.clientWidth, clientHeight: canvas.clientHeight } : null,
        objectiveText: scene?.objectiveText ? String(scene.objectiveText.text ?? "").slice(0, 140) : "",
        progressText: scene?.progressText ? String(scene.progressText.text ?? "").slice(0, 140) : "",
        hasExplorer: Boolean(scene?.explorer),
      };
    });
  } catch (error) {
    return { diagnosticError: error instanceof Error ? error.message : String(error) };
  }
}

async function main() {
  await fs.mkdir(outDir, { recursive: true });
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: chromePath,
    protocolTimeout: protocolTimeoutMs,
    args: ["--no-sandbox", "--disable-gpu"],
  });

  const results = [];
  try {
    for (const viewport of viewports) {
      let result;
      for (let attempt = 1; attempt <= auditAttempts; attempt += 1) {
        console.log(`Audit ${viewport.name}${auditAttempts > 1 ? ` (${attempt}/${auditAttempts})` : ""}...`);
        const page = await browser.newPage();
        const errors = [];
        page.setDefaultTimeout(waitMs);
        page.setDefaultNavigationTimeout(waitMs);
        page.on("pageerror", (error) => errors.push(error.message));
        page.on("console", (message) => {
          if (message.type() === "error") errors.push(message.text());
        });
        try {
          await page.setViewport({ width: viewport.width, height: viewport.height, deviceScaleFactor: 1 });
          await page.goto(url, { waitUntil: "domcontentloaded", timeout: waitMs });
          await page.waitForSelector("canvas", { timeout: waitMs });
          await page.waitForFunction(() => Boolean(window.__ELI_QUEST_GAME__?.scene), { timeout: waitMs });

          await page.evaluate(async ({ seed, difficulty }) => {
            window.__ELI_AUDIT_PHASE__ = "importing";
            const game = window.__ELI_QUEST_GAME__;
            const [{ proceduralDirector }, { saveSystem }, { settingsSystem }, { ProceduralMissionScene }] = await Promise.all([
              import("/src/procedural/ProceduralDirector.ts"),
              import("/src/core/SaveSystem.ts"),
              import("/src/core/SettingsSystem.ts"),
              import("/src/scenes/ProceduralMissionScene.ts"),
            ]);
            window.__ELI_AUDIT_PHASE__ = "configuring";
            settingsSystem.setReducedEffects(true);
            settingsSystem.setGraphicsQuality("comfort");
            window.__ELI_AUDIT_PHASE__ = "generating";
            const mission = proceduralDirector.generateMission(seed, difficulty, ["libera"]);
            const now = new Date().toISOString();
            window.__ELI_AUDIT_PHASE__ = "saving-run";
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
            window.__ELI_AUDIT_PHASE__ = "starting-scene";
            game.scene.start("ProceduralMissionScene");
            window.__ELI_AUDIT_PHASE__ = "scene-started";
          }, { seed: `LAYOUT-AUDIT-${viewport.name}`, difficulty: auditDifficulty });

          await page.waitForFunction(() => {
            const scene = window.__ELI_QUEST_GAME__?.scene?.keys?.ProceduralMissionScene;
            const objective = scene?.objectiveText;
            const progress = scene?.progressText;
            return Boolean(
              scene?.sys?.isActive?.()
              && objective?.visible
              && progress?.visible
              && String(objective.text ?? "").trim().length > 0
              && String(progress.text ?? "").trim().length > 0
            );
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
            const canvasWidth = canvas?.width ?? 1280;
            const canvasHeight = canvas?.height ?? 720;
            const overflows = texts.filter((item) => item.x < -2 || item.y < -2 || item.right > canvasWidth + 2 || item.bottom > canvasHeight + 2);
            const longPermanentTexts = texts.filter((item) => item.text.length > 420);
            const objectiveText = scene?.objectiveText ? String(scene.objectiveText.text ?? "") : "";
            const progressText = scene?.progressText ? String(scene.progressText.text ?? "") : "";
            return {
              canvas: canvas ? { width: canvas.width, height: canvas.height, clientWidth: canvas.clientWidth, clientHeight: canvas.clientHeight } : null,
              textCount: texts.length,
              overflows,
              objectiveText,
              progressText,
              hasObjectiveHud: objectiveText.trim().length > 0,
              hasProgressHud: progressText.trim().length > 0,
              hasExplorer: Boolean(scene?.explorer),
              longPermanentTexts: longPermanentTexts.map((item) => item.text.slice(0, 90)),
            };
          });

          const failures = [];
          if (errors.length > 0) failures.push(`console/page errors: ${errors.join(" | ")}`);
          if (!audit.canvas || audit.canvas.width !== 1280 || audit.canvas.height !== 720) failures.push("canvas 1280x720 non trovato");
          if (audit.overflows.length > 0) failures.push(`${audit.overflows.length} testi fuori canvas`);
          if (!audit.hasObjectiveHud) failures.push("HUD obiettivo non trovato o vuoto");
          if (!audit.hasProgressHud) failures.push("HUD progresso non trovato o vuoto");
          if (audit.longPermanentTexts.length > 0) failures.push(`testi permanenti troppo lunghi: ${audit.longPermanentTexts.join(" / ")}`);

          result = { viewport, screenshotPath, audit, errors, failures };
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          const screenshotPath = await captureFailure(page, viewport);
          const diagnostics = await pageDiagnostics(page);
          result = { viewport, screenshotPath, audit: diagnostics, errors, failures: [message] };
        } finally {
          await page.close();
        }

        if (result.failures.length === 0 || attempt === auditAttempts || !isRetryableFailure(result.failures)) {
          break;
        }
        console.log(`Retry ${viewport.name}: ${result.failures.join("; ")}`);
      }
      results.push(result);
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
