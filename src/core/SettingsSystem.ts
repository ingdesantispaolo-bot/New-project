import { EventBus, GameEvents } from "./EventBus";

export type GameSettings = {
  /** Master volume 0..1. */
  volume: number;
  muted: boolean;
  /** Reduces decorative motion/particles for comfort and low-end tablets. */
  reducedEffects: boolean;
  /** UI text scale multiplier (1 = default). */
  textScale: number;
};

const SETTINGS_KEY = "eli-quest-settings-v1";

const DEFAULT_SETTINGS: GameSettings = {
  volume: 0.8,
  muted: false,
  reducedEffects: false,
  textScale: 1,
};

const TEXT_SCALE_STEPS = [0.9, 1, 1.15, 1.3] as const;

function clamp01(value: number): number {
  if (Number.isNaN(value)) return 0;
  return Math.min(1, Math.max(0, value));
}

/**
 * Global, persisted player preferences (audio, motion, readability).
 * Systems subscribe via EventBus.SettingsChanged and read the current values.
 */
export class SettingsSystem {
  private settings: GameSettings = { ...DEFAULT_SETTINGS };
  private loaded = false;
  private prefersReducedMotion = false;

  load(): GameSettings {
    if (this.loaded) {
      return this.settings;
    }
    this.loaded = true;
    this.prefersReducedMotion =
      typeof window !== "undefined" &&
      (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false);

    try {
      const raw = typeof localStorage !== "undefined" ? localStorage.getItem(SETTINGS_KEY) : null;
      if (raw) {
        const parsed = JSON.parse(raw) as Partial<GameSettings>;
        this.settings = {
          volume: clamp01(parsed.volume ?? DEFAULT_SETTINGS.volume),
          muted: Boolean(parsed.muted ?? DEFAULT_SETTINGS.muted),
          reducedEffects: Boolean(parsed.reducedEffects ?? DEFAULT_SETTINGS.reducedEffects),
          textScale: TEXT_SCALE_STEPS.includes((parsed.textScale ?? 1) as never)
            ? (parsed.textScale as number)
            : DEFAULT_SETTINGS.textScale,
        };
      }
    } catch {
      this.settings = { ...DEFAULT_SETTINGS };
    }
    return this.settings;
  }

  get(): GameSettings {
    if (!this.loaded) {
      this.load();
    }
    return this.settings;
  }

  /** True when either the user opted in or the OS requests reduced motion. */
  effectsReduced(): boolean {
    return this.get().reducedEffects || this.prefersReducedMotion;
  }

  getVolume(): number {
    return this.get().volume;
  }

  isMuted(): boolean {
    return this.get().muted;
  }

  getTextScale(): number {
    return this.get().textScale;
  }

  setVolume(volume: number): void {
    this.update({ volume: clamp01(volume) });
  }

  setMuted(muted: boolean): void {
    this.update({ muted });
  }

  toggleMuted(): void {
    this.update({ muted: !this.get().muted });
  }

  setReducedEffects(reducedEffects: boolean): void {
    this.update({ reducedEffects });
  }

  toggleReducedEffects(): void {
    this.update({ reducedEffects: !this.get().reducedEffects });
  }

  /** Cycles through the discrete readable text scales. */
  cycleTextScale(): number {
    const current = this.get().textScale;
    const index = TEXT_SCALE_STEPS.indexOf(current as never);
    const next = TEXT_SCALE_STEPS[(index + 1) % TEXT_SCALE_STEPS.length];
    this.update({ textScale: next });
    return next;
  }

  private update(patch: Partial<GameSettings>): void {
    this.settings = { ...this.get(), ...patch };
    this.persist();
    EventBus.emit(GameEvents.SettingsChanged, this.settings);
  }

  private persist(): void {
    try {
      if (typeof localStorage !== "undefined") {
        localStorage.setItem(SETTINGS_KEY, JSON.stringify(this.settings));
      }
    } catch {
      // Settings persistence is best-effort.
    }
  }
}

export const settingsSystem = new SettingsSystem();
