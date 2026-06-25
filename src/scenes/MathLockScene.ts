import Phaser from "phaser";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { audioManager } from "../core/AudioManager";
import { exerciseVariantSystem } from "../core/ExerciseVariantSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { missionEngine } from "../core/MissionEngine";
import type { MathPuzzleDefinition } from "../types/puzzleTypes";
import { Button } from "../ui/Button";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

export class MathLockScene extends Phaser.Scene {
  preload(): void {
    queueSceneAssets(this, "lab");
  }
  private mathLockPuzzle: MathPuzzleDefinition = exerciseVariantSystem.getMathLockPuzzle();
  private value = "";
  private attempts = 0;
  private display?: Phaser.GameObjects.Text;
  private hintText?: Phaser.GameObjects.Text;
  private terminalPanel?: Phaser.GameObjects.Container;
  private terminalGlow?: Phaser.GameObjects.Image;

  constructor() {
    super("MathLockScene");
  }

  create(): void {
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "factory");
    VisualKit.cinematicDepth(this, "factory", 0.82);
    this.drawTerminal();
    this.createKeypad();
    VisualKit.vignette(this);
  }

  private drawTerminal(): void {
    this.add.text(90, 56, "Serratura numerica del terminale", {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(92, 112, this.mathLockPuzzle.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "21px",
      color: "#f6c85f",
      wordWrap: { width: 1100 },
    });

    this.terminalPanel = SceneChrome.consolePanel(this, 280, 166, 720, 440, "Console serratura", "factory");
    VisualKit.glowFrame(this, 270, 156, 740, 460, "factory");
    VisualKit.scanLine(this, 640, 390, 676, 390, "factory");
    this.terminalGlow = this.add.image(640, 240, "soft-glow").setTint(0xf6c85f).setAlpha(0.18).setScale(2.8);
    this.add.rectangle(640, 252, 410, 84, 0x081018, 0.72).setStrokeStyle(2, 0xf6c85f, 0.32);
    this.display = this.add.text(510, 192, "----", {
      fontFamily: "Inter, Arial",
      fontSize: "56px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.rectangle(640, 542, 520, 8, 0xf6c85f, 0.12);
    this.hintText = this.add.text(382, 580, "Il terminale registra i tentativi e restituisce indizi, non voti.", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#c9dce6",
      wordWrap: { width: 520 },
      lineSpacing: 5,
    });
  }

  private createKeypad(): void {
    const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"];
    keys.forEach((key, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      new Button(this, 510 + col * 130, 304 + row * 68, key, () => this.press(key), {
        width: 92,
        height: 52,
        fontSize: 22,
        fill: key === "OK" ? 0x1f4b46 : 0x142736,
      });
    });

    new Button(this, 132, 650, "Indietro", () => this.scene.start("LaboratoryScene"), {
      width: 160,
      height: 48,
      fill: 0x263743,
    });
  }

  private press(key: string): void {
    if (key === "C") {
      this.value = "";
      audioManager.play("click");
      this.refreshDisplay();
      return;
    }

    if (key === "OK") {
      this.submit();
      return;
    }

    if (this.value.length < 4) {
      this.value += key;
      audioManager.play("click");
      this.refreshDisplay();
    }
  }

  private submit(): void {
    if (this.value.length === 0) {
      this.hintText?.setColor("#f7d37a").setText("Il terminale non legge un codice vuoto: ricostruisci la traccia prima di inviare.");
      audioManager.play("error");
      this.reactToOutcome("warning");
      return;
    }

    const submitted = Number(this.value);
    this.attempts += 1;

    if (submitted === this.mathLockPuzzle.answer) {
      missionEngine.completeObjective("mathLockSolved", ["matematica.calcolo", "matematica.logica"], 18);
      audioManager.play("success");
      this.hintText?.setColor("#9ff5e9").setText("Codice accettato. Il terminale passa alla verifica operativa.");
      this.display?.setColor("#9ff5e9");
      this.terminalGlow?.setTint(0x6be7d6).setAlpha(0.36);
      this.reactToOutcome("success");
      this.playUnlockSurge();
      this.time.delayedCall(900, () => this.scene.start("LaboratoryScene"));
      return;
    }

    audioManager.play("error");
    const nearMiss = this.mathLockPuzzle.nearMisses?.find((item) => item.value === submitted);
    if (nearMiss) {
      feedbackSystem.publish(nearMiss.feedback, "hint");
    }
    const hint = this.mathLockPuzzle.hints[Math.min(this.attempts - 1, this.mathLockPuzzle.hints.length - 1)];
    this.hintText?.setColor("#f7d37a").setText(nearMiss ? `${nearMiss.feedback}\n${hint}` : hint);
    this.reactToOutcome(nearMiss ? "warning" : "error");
    this.value = "";
    this.refreshDisplay();
  }

  private refreshDisplay(): void {
    this.display?.setText(this.value.padEnd(4, "-"));
    if (this.display) {
      this.tweens.add({ targets: this.display, scale: 1.06, duration: 90, yoyo: true });
    }
  }

  /** Expanding ring + glow surge: the lock visibly releases on success. */
  private playUnlockSurge(): void {
    if (this.terminalGlow) {
      this.tweens.add({
        targets: this.terminalGlow,
        alpha: 0.6,
        scale: 3.6,
        duration: 380,
        yoyo: true,
        ease: "Sine.easeOut",
      });
    }
    if (settingsSystem.effectsReduced()) {
      return;
    }
    const ring = this.add.circle(640, 240, 30, 0x6be7d6, 0).setStrokeStyle(3, 0x6be7d6, 0.9);
    this.tweens.add({
      targets: ring,
      scale: 7,
      alpha: { from: 0.9, to: 0 },
      duration: 620,
      ease: "Sine.easeOut",
      onComplete: () => ring.destroy(),
    });
  }

  private reactToOutcome(tone: "success" | "error" | "warning"): void {
    const tint = tone === "success" ? 0x6be7d6 : tone === "warning" ? 0xf6c85f : 0xc94b55;
    this.display?.setColor(tone === "success" ? "#9ff5e9" : tone === "warning" ? "#f7d37a" : "#ff9b9b");
    this.terminalGlow?.setTint(tint).setAlpha(tone === "success" ? 0.42 : 0.3);
    VisualKit.outcomeFlash(this, tone, 640, 386, 760, 440);
    VisualKit.particleBurst(this, 640, 248, "factory", tone);
    if (tone !== "success" && this.terminalPanel) {
      VisualKit.shake(this, this.terminalPanel, tone === "warning" ? 5 : 9);
    }
  }
}
