import { Howl, Howler } from "howler";
import circuitOnUrl from "../assets/audio/generated/circuitOn.wav?url";
import clickUrl from "../assets/audio/generated/click.wav?url";
import doorOpenUrl from "../assets/audio/generated/doorOpen.wav?url";
import errorUrl from "../assets/audio/generated/error.wav?url";
import footstepUrl from "../assets/audio/generated/footstep.wav?url";
import hintUrl from "../assets/audio/generated/hint.wav?url";
import labAmbienceUrl from "../assets/audio/generated/labAmbience.wav?url";
import panelOpenUrl from "../assets/audio/generated/panelOpen.wav?url";
import scanUrl from "../assets/audio/generated/scan.wav?url";
import successUrl from "../assets/audio/generated/success.wav?url";

type SoundKey =
  | "labAmbience"
  | "click"
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

export class AudioManager {
  private sounds = new Map<SoundKey, Howl>();
  private lastOutcomeAt = 0;
  private currentMusic?: "labAmbience";
  private unlockInstalled = false;
  private unlocked = false;

  private specs: Record<SoundKey, SoundSpec> = {
    labAmbience: { src: labAmbienceUrl, volume: 0.18, loop: true },
    click: { src: clickUrl, volume: 0.34 },
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

  preloadEssentialAudio(): void {
    this.preloadKeys(["click", "success", "error", "hint", "scan", "panelOpen"]);
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
    this.preloadKeys(["click", "success", "error", "hint", "scan"]);
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
