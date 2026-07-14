import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { storySystem, type StoryChoicePrompt } from "../core/StorySystem";
import { Button } from "../ui/Button";

type Options = {
  /** Called after the player picks (and the choice is persisted). */
  onChosen?: (optionId: string) => void;
  /** Called when the whole overlay closes (after the confirmation card). */
  onClose?: () => void;
  /**
   * For the "ending" bivio: called instead of the confirmation card, so the
   * caller can hand off to the full-screen finale cutscene.
   */
  onEnding?: (endingId: string) => void;
};

/**
 * Full-screen narrative bivio for "Il Relitto dei Primi". Renders the cutscene
 * art, the prompt and 2–3 option cards (locked ones show why); on pick it
 * persists the choice via {@link storySystem} and shows a confirmation card with
 * the Diario page it revealed. Callers on a scrolling camera must route the
 * returned container to their UI camera (markUi).
 */
export function showStoryChoice(scene: Phaser.Scene, prompt: StoryChoicePrompt, options: Options = {}): Phaser.GameObjects.Container {
  const root = scene.add.container(0, 0).setDepth(2000);

  // Dimmed cutscene backdrop.
  root.add(scene.add.rectangle(640, 360, 1280, 720, 0x02060a, 0.95).setInteractive());
  if (prompt.art && scene.textures.exists(prompt.art)) {
    const bg = scene.add.image(640, 300, prompt.art).setAlpha(0.4);
    const scale = Math.max(1280 / bg.width, 620 / bg.height);
    bg.setScale(scale);
    root.add(bg);
    root.add(scene.add.rectangle(640, 360, 1280, 720, 0x030a12, 0.45));
  }

  root.add(scene.add.text(640, 96, prompt.eyebrow.toUpperCase(), {
    fontFamily: "Inter, Arial", fontSize: "13px", color: "#ff9d5c", fontStyle: "bold",
  }).setOrigin(0.5));
  root.add(scene.add.text(640, 134, prompt.title, {
    fontFamily: "Inter, Arial", fontSize: "34px", color: "#f5fbff", fontStyle: "bold", align: "center", wordWrap: { width: 900 },
  }).setOrigin(0.5));
  root.add(scene.add.text(640, 188, prompt.body, {
    fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", align: "center", wordWrap: { width: 760 }, lineSpacing: 4,
  }).setOrigin(0.5));

  const n = prompt.options.length;
  const cardW = n >= 3 ? 372 : 400;
  const gap = 24;
  const totalW = n * cardW + (n - 1) * gap;
  const startX = 640 - totalW / 2 + cardW / 2;
  const cardY = 420;
  const cardH = 300;

  prompt.options.forEach((option, index) => {
    const cx = startX + index * (cardW + gap);
    const locked = option.locked === true;
    const stroke = locked ? 0x4a5760 : index === 0 ? 0x6be7d6 : index === 1 ? 0xf6c85f : 0xab99ff;
    const card = scene.add.container(cx, cardY);
    root.add(card);

    const panel = scene.add.rectangle(0, 0, cardW, cardH, 0x07151d, 0.97).setStrokeStyle(2, stroke, locked ? 0.4 : 0.9);
    card.add(panel);
    if (option.art && scene.textures.exists(option.art)) {
      const thumb = scene.add.image(0, -78, option.art).setAlpha(locked ? 0.25 : 0.85);
      const s = Math.max((cardW - 24) / thumb.width, 116 / thumb.height);
      thumb.setScale(s);
      const mask = scene.add.graphics().fillRect(cx - (cardW - 24) / 2, cardY - 78 - 58, cardW - 24, 116);
      thumb.setMask(mask.createGeometryMask());
      card.add(thumb);
    }
    card.add(scene.add.text(0, 8, option.label, {
      fontFamily: "Inter, Arial", fontSize: "19px", color: locked ? "#8aa0ab" : "#f5fbff", fontStyle: "bold", align: "center", wordWrap: { width: cardW - 36 },
    }).setOrigin(0.5));
    card.add(scene.add.text(0, 58, locked ? (option.lockHint ?? "Non ancora disponibile.") : option.consequence, {
      fontFamily: "Inter, Arial", fontSize: "12.5px", color: locked ? "#7d93a0" : "#9ff5e9", align: "center", wordWrap: { width: cardW - 40 }, lineSpacing: 3,
    }).setOrigin(0.5));

    if (locked) {
      card.add(scene.add.text(0, cardH / 2 - 26, "🔒 bloccato", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#7d93a0", fontStyle: "bold" }).setOrigin(0.5));
    } else {
      const btn = new Button(scene, 0, cardH / 2 - 30, "Scegli", () => {
        pick(option.id);
      }, { width: cardW - 60, height: 40, fontSize: 14, fill: 0x143a2f, stroke });
      card.add(btn);
    }
  });

  function pick(optionId: string): void {
    audioManager.play("missionStart");
    const revealed = storySystem.applyChoice(prompt.kind, optionId);
    options.onChosen?.(optionId);
    // The finale hands off to its own full-screen cutscene.
    if (prompt.kind === "ending" && options.onEnding) {
      root.destroy(true);
      options.onEnding(optionId);
      return;
    }
    showConfirmation(revealed[0]?.title, revealed[0]?.text);
  }

  function showConfirmation(pageTitle?: string, pageText?: string): void {
    root.removeAll(true);
    root.add(scene.add.rectangle(640, 360, 1280, 720, 0x02060a, 0.96).setInteractive());
    root.add(scene.add.text(640, 214, "SCELTA REGISTRATA", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#ff9d5c", fontStyle: "bold" }).setOrigin(0.5));
    if (pageTitle) {
      root.add(scene.add.rectangle(640, 360, 720, 220, 0x07151d, 0.98).setStrokeStyle(2, 0xf6c85f, 0.6));
      root.add(scene.add.text(640, 288, "✦ Nuova pagina nel Diario di Bordo", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
      root.add(scene.add.text(640, 318, pageTitle, { fontFamily: "Inter, Arial", fontSize: "22px", color: "#f5fbff", fontStyle: "bold", align: "center", wordWrap: { width: 660 } }).setOrigin(0.5));
      root.add(scene.add.text(640, 372, pageText ?? "", { fontFamily: "Inter, Arial", fontSize: "13.5px", color: "#dce9ef", align: "center", wordWrap: { width: 640 }, lineSpacing: 5 }).setOrigin(0.5));
    } else {
      root.add(scene.add.text(640, 340, "La tua decisione cambierà il seguito della storia.", { fontFamily: "Inter, Arial", fontSize: "17px", color: "#c7dce7" }).setOrigin(0.5));
    }
    root.add(new Button(scene, 640, 500, "Continua", () => {
      root.destroy(true);
      options.onClose?.();
    }, { width: 220, height: 46, fill: 0x1f5a51, stroke: 0xf6c85f, fontSize: 15 }));
  }

  audioManager.play("panelOpen");
  return root;
}
