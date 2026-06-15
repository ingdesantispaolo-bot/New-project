import type { DifficultyLevel } from "./ProceduralTypes";
import { Random } from "./Random";

export class SeedManager {
  createRandomSeed(prefix = "ELI"): string {
    const bytes = new Uint32Array(2);
    if (globalThis.crypto?.getRandomValues) {
      globalThis.crypto.getRandomValues(bytes);
    } else {
      bytes[0] = Date.now() >>> 0;
      bytes[1] = (performance.now() * 1000) >>> 0;
    }
    return this.normalize(`${prefix}-${bytes[0].toString(36)}-${bytes[1].toString(36)}`);
  }

  createDateSeed(date = new Date(), prefix = "ELI-DAY"): string {
    const isoDay = date.toISOString().slice(0, 10).replaceAll("-", "");
    return this.normalize(`${prefix}-${isoDay}`);
  }

  createDifficultySeed(difficulty: DifficultyLevel, focus: string[] = [], prefix = "ELI-DIFF"): string {
    return this.normalize(`${prefix}-${difficulty}-${focus.join("-")}-${Date.now().toString(36)}`);
  }

  normalize(seed: string): string {
    return seed
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9-]+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
  }

  toNumber(seed: string): number {
    return Random.hash(this.normalize(seed));
  }
}

export const seedManager = new SeedManager();
