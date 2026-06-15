import { difficultyModel } from "./DifficultyModel";
import { MissionGenerator } from "./MissionGenerator";
import type { DifficultyLevel, GeneratedMission } from "./ProceduralTypes";
import { Random } from "./Random";
import { seedManager } from "./SeedManager";

export class ProceduralDirector {
  private missionGenerator = new MissionGenerator();

  generateMission(seed: string, difficulty: DifficultyLevel, focus: string[] = []): GeneratedMission {
    const normalizedSeed = seedManager.normalize(seed);
    const random = new Random(normalizedSeed);
    const preset = difficultyModel.getPreset(difficulty);
    return this.missionGenerator.generate(normalizedSeed, random, preset, focus);
  }

  generateFreshMission(difficulty: DifficultyLevel, focus: string[] = []): GeneratedMission {
    const seed = seedManager.createDifficultySeed(difficulty, focus, "ELI-PROC");
    return this.generateMission(seed, difficulty, focus);
  }
}

export const proceduralDirector = new ProceduralDirector();
