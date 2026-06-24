import { Howl, Howler } from "howler";
import { EventBus, GameEvents } from "./EventBus";
import { settingsSystem } from "./SettingsSystem";
import circuitOnUrl from "../assets/audio/generated/circuitOn.wav?url";
import cancelUrl from "../assets/audio/generated/cancel.wav?url";
import clickUrl from "../assets/audio/generated/click.wav?url";
import confirmUrl from "../assets/audio/generated/confirm.wav?url";
import contextCodingUrl from "../assets/audio/generated/contextCoding.wav?url";
import contextElectronicsUrl from "../assets/audio/generated/contextElectronics.wav?url";
import contextEnglishUrl from "../assets/audio/generated/contextEnglish.wav?url";
import contextLanguageUrl from "../assets/audio/generated/contextLanguage.wav?url";
import contextMathUrl from "../assets/audio/generated/contextMath.wav?url";
import contextMusicUrl from "../assets/audio/generated/contextMusic.wav?url";
import doorOpenUrl from "../assets/audio/generated/doorOpen.wav?url";
import errorUrl from "../assets/audio/generated/error.wav?url";
import focusSelectUrl from "../assets/audio/generated/focusSelect.wav?url";
import footstepUrl from "../assets/audio/generated/footstep.wav?url";
import hintUrl from "../assets/audio/generated/hint.wav?url";
import labAmbienceUrl from "../assets/audio/generated/labAmbience.wav?url";
import levelSelectUrl from "../assets/audio/generated/levelSelect.wav?url";
import mathKeyUrl from "../assets/audio/generated/mathKey.wav?url";
import missionStartUrl from "../assets/audio/generated/missionStart.wav?url";
import panelOpenUrl from "../assets/audio/generated/panelOpen.wav?url";
import progressiveStepUrl from "../assets/audio/generated/progressiveStep.wav?url";
import resetUrl from "../assets/audio/generated/reset.wav?url";
import scanUrl from "../assets/audio/generated/scan.wav?url";
import successUrl from "../assets/audio/generated/success.wav?url";
import uiSelectUrl from "../assets/audio/generated/uiSelect.wav?url";

export type SoundKey =
  | "labAmbience"
  | "click"
  | "uiSelect"
  | "confirm"
  | "cancel"
  | "reset"
  | "levelSelect"
  | "missionStart"
  | "focusSelect"
  | "progressiveStep"
  | "mathKey"
  | "contextMath"
  | "contextLanguage"
  | "contextEnglish"
  | "contextElectronics"
  | "contextCoding"
  | "contextMusic"
  | "scan"
  | "hint"
  | "panelOpen"
  | "footstep"
  | "circuitOn"
  | "error"
  | "success"
  | "doorOpen";

type SoundSpec = {
  src: string;
  volume: number;
  loop?: boolean;
};

type OutcomeSound = "correct" | "wrong" | "hint" | "complete" | "neutral";
type ContextSound = "math" | "language" | "english" | "electronics" | "coding" | "music";

export class AudioManager {
  private sounds = new Map<SoundKey, Howl>();
  private lastOutcomeAt = 0;
  private currentMusic?: "labAmbience";
  private unlockInstalled = false;
  private unlocked = false;
  private settingsBound = false;

  private specs: Record<SoundKey, SoundSpec> = {
    labAmbience: { src: labAmbienceUrl, volume: 0.18, loop: true },
    click: { src: clickUrl, volume: 0.34 },
    uiSelect: { src: uiSelectUrl, volume: 0.28 },
    confirm: { src: confirmUrl, volume: 0.36 },
    cancel: { src: cancelUrl, volume: 0.28 },
    reset: { src: resetUrl, volume: 0.34 },
    levelSelect: { src: levelSelectUrl, volume: 0.34 },
    missionStart: { src: missionStartUrl, volume: 0.34 },
    focusSelect: { src: focusSelectUrl, volume: 0.32 },
    progressiveStep: { src: progressiveStepUrl, volume: 0.34 },
    mathKey: { src: mathKeyUrl, volume: 0.22 },
    contextMath: { src: contextMathUrl, volume: 0.34 },
    contextLanguage: { src: contextLanguageUrl, volume: 0.32 },
    contextEnglish: { src: contextEnglishUrl, volume: 0.32 },
    contextElectronics: { src: contextElectronicsUrl, volume: 0.34 },
    contextCoding: { src: contextCodingUrl, volume: 0.32 },
    contextMusic: { src: contextMusicUrl, volume: 0.34 },
    scan: { src: scanUrl, volume: 0.3 },
    hint: { src: hintUrl, volume: 0.32 },
    panelOpen: { src: panelOpenUrl, volume: 0.32 },
    footstep: { src: footstepUrl, volume: 0.22 },
    circuitOn: { src: circuitOnUrl, volume: 0.42 },
    error: { src: errorUrl, volume: 0.32 },
    success: { src: successUrl, volume: 0.45 },
    doorOpen: { src: doorOpenUrl, volume: 0.44 },
  };

  setMuted(muted: boolean): void {
    Howler.mute(muted);
  }

  /**
   * Applies the persisted master volume + mute and keeps the audio engine in
   * sync with later setting changes. Safe to call more than once.
   */
  bindSettings(): void {
    this.applySettings();
    if (this.settingsBound) {
      return;
    }
    this.settingsBound = true;
    EventBus.on(GameEvents.SettingsChanged, () => this.applySettings());
  }

  private applySettings(): void {
    const settings = settingsSystem.get();
    Howler.volume(settings.volume);
    Howler.mute(settings.muted);
  }

  preloadEssentialAudio(): void {
    this.preloadKeys(["uiSelect", "confirm", "cancel", "levelSelect", "missionStart", "success", "error", "hint", "scan", "panelOpen"]);
  }

  preloadAmbientAudio(): void {
    this.preloadKeys(["labAmbience"]);
  }

  installUnlockListeners(): void {
    if (this.unlockInstalled || typeof window === "undefined") {
      return;
    }
    this.unlockInstalled = true;
    const unlock = (): void => {
      this.unlock();
      window.setTimeout(() => this.preloadResponsiveSfx(), 0);
      window.removeEventListener("pointerdown", unlock);
      window.removeEventListener("touchend", unlock);
      window.removeEventListener("keydown", unlock);
    };
    window.addEventListener("pointerdown", unlock, { passive: true });
    window.addEventListener("touchend", unlock, { passive: true });
    window.addEventListener("keydown", unlock);
  }

  unlock(): void {
    if (this.unlocked) {
      return;
    }
    this.unlocked = true;
    const context = (Howler as unknown as { ctx?: AudioContext }).ctx;
    if (context?.state === "suspended") {
      void context.resume();
    }
    if (this.currentMusic) {
      const music = this.getSound(this.currentMusic);
      if (!music.playing()) {
        music.play();
      }
    }
  }

  play(key: SoundKey): void {
    try {
      const sound = this.getSound(key);
      sound.play();
    } catch {
      // Audio must never block input responsiveness.
    }
  }

  playOutcome(outcome: OutcomeSound): void {
    const now = Date.now();
    if (now - this.lastOutcomeAt < 90) {
      return;
    }
    this.lastOutcomeAt = now;
    const outcomeSounds: Record<OutcomeSound, SoundKey> = {
      correct: "success",
      wrong: "error",
      hint: "hint",
      complete: "doorOpen",
      neutral: "scan",
    };
    this.play(outcomeSounds[outcome]);
  }

  playContext(context: ContextSound): void {
    const contextSounds: Record<ContextSound, SoundKey> = {
      math: "contextMath",
      language: "contextLanguage",
      english: "contextEnglish",
      electronics: "contextElectronics",
      coding: "contextCoding",
      music: "contextMusic",
    };
    this.play(contextSounds[context]);
  }

  playToneSequence(steps: Array<{ frequency: number; durationMs: number }>): void {
    try {
      this.unlock();
      const audio = Howler as unknown as { ctx?: AudioContext; masterGain?: GainNode };
      const context = audio.ctx;
      if (!context) return;
      const destination = audio.masterGain ?? context.destination;
      let cursor = context.currentTime + 0.03;
      steps.forEach((step) => {
        const duration = Math.max(0.06, step.durationMs / 1000);
        if (step.frequency > 0) {
          const oscillator = context.createOscillator();
          const gain = context.createGain();
          oscillator.type = "sine";
          oscillator.frequency.setValueAtTime(step.frequency, cursor);
          gain.gain.setValueAtTime(0.0001, cursor);
          gain.gain.exponentialRampToValueAtTime(0.13, cursor + 0.018);
          gain.gain.exponentialRampToValueAtTime(0.0001, cursor + duration);
          oscillator.connect(gain);
          gain.connect(destination);
          oscillator.start(cursor);
          oscillator.stop(cursor + duration + 0.02);
        }
        cursor += duration + 0.07;
      });
    } catch {
      // Musical previews are optional and must never block the exercise.
    }
  }

  playMusic(key: "labAmbience"): void {
    const current = this.currentMusic ? this.sounds.get(this.currentMusic) : undefined;
    if (this.currentMusic === key && current?.playing()) {
      return;
    }
    this.stopMusic();
    this.getSound(key).play();
    this.currentMusic = key;
  }

  stopMusic(): void {
    this.sounds.forEach((sound, key) => {
      if (key === "labAmbience") {
        sound.stop();
      }
    });
    this.currentMusic = undefined;
  }

  private getSound(key: SoundKey): Howl {
    const existing = this.sounds.get(key);
    if (existing) {
      return existing;
    }

    const spec = this.specs[key];
    const sound = new Howl({
      src: [spec.src],
      volume: spec.volume,
      loop: spec.loop ?? false,
    });
    this.sounds.set(key, sound);
    return sound;
  }

  private preloadResponsiveSfx(): void {
    this.preloadKeys([
      "uiSelect",
      "confirm",
      "cancel",
      "reset",
      "levelSelect",
      "missionStart",
      "focusSelect",
      "progressiveStep",
      "mathKey",
      "contextMath",
      "contextLanguage",
      "contextEnglish",
      "contextElectronics",
      "contextCoding",
      "contextMusic",
      "success",
      "error",
      "hint",
      "scan",
    ]);
  }

  private preloadKeys(keys: SoundKey[]): void {
    keys.forEach((key) => {
      try {
        this.getSound(key).load();
      } catch {
        // Preload is opportunistic.
      }
    });
  }
}

export const audioManager = new AudioManager();
