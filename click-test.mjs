import puppeteer from "puppeteer-core";
const CHROME = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe";
const browser = await puppeteer.launch({ executablePath: CHROME, headless: "new", args: ["--no-sandbox", "--window-size=1280,720"], defaultViewport: { width: 1280, height: 720 } });
const page = await browser.newPage();
await page.goto("http://localhost:5173/", { waitUntil: "domcontentloaded" });
await page.waitForFunction(() => !!window.__ELI_QUEST_GAME__, { timeout: 40000 });
await new Promise((r) => setTimeout(r, 6000));
await page.evaluate(async () => {
  const g = window.__ELI_QUEST_GAME__;
  if (!g.scene.keys["ExplorableRoomScene"]) { const mod = await import("/src/scenes/ExplorableRoomScene.ts"); g.scene.add("ExplorableRoomScene", mod.ExplorableRoomScene, false); }
  g.scene.getScenes(true).forEach((s) => { if (s.scene.key !== "ExplorableRoomScene") g.scene.stop(s.scene.key); });
  g.scene.start("ExplorableRoomScene", { returnScene: "MainMenuScene", areaId: "laboratorio" });
});
await new Promise((r) => setTimeout(r, 2600));
const before = await page.evaluate(() => {
  const g = window.__ELI_QUEST_GAME__;
  const cam = g.scene.getScene("ExplorableRoomScene").cameras.main;
  return { scrollX: Math.round(cam.scrollX), scrollY: Math.round(cam.scrollY), explActive: g.scene.isActive("ExplorableRoomScene"), menuActive: g.scene.isActive("MainMenuScene") };
});
// Click the "Indietro" button at screen (1180,40)
await page.mouse.click(1180, 40);
await new Promise((r) => setTimeout(r, 1200));
const after = await page.evaluate(() => {
  const g = window.__ELI_QUEST_GAME__;
  return { explActive: g.scene.isActive("ExplorableRoomScene"), menuActive: g.scene.isActive("MainMenuScene") };
});
console.log("before:", JSON.stringify(before));
console.log("after click Indietro:", JSON.stringify(after));
console.log(after.menuActive ? "CLICK WORKED" : "CLICK FAILED (button not clickable)");
setTimeout(() => process.exit(0), 300);
