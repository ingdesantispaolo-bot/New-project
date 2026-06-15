import { difficultyPresets } from "../data/procedural/difficultyPresets";
import type { DifficultyLevel, DifficultyPreset } from "./ProceduralTypes";

export class DifficultyModel {
  getPreset(level: DifficultyLevel | number): DifficultyPreset {
    const normalized = this.normalize(level);
    return difficultyPresets.find((preset) => preset.level === normalized) ?? difficultyPresets[0];
  }

  normalize(level: DifficultyLevel | number): DifficultyLevel {
    return Math.min(8, Math.max(1, Math.round(level))) as DifficultyLevel;
  }

  describe(level: DifficultyLevel | number): string {
    const preset = this.getPreset(level);
    if (preset.level <= 2) return "osservazione guidata";
    if (preset.level <= 4) return "diagnosi con vincoli";
    if (preset.level <= 6) return "strategia multi-passaggio";
    return "sistema integrato con controllo dell'errore";
  }
}

export const difficultyModel = new DifficultyModel();
