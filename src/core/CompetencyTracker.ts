import { competencies, canonicalCompetencyId, isKnownCompetency } from "../data/competencies";
import { saveSystem } from "./SaveSystem";

export class CompetencyTracker {
  award(ids: string[], amount = 12): void {
    ids.forEach((rawId) => {
      const id = canonicalCompetencyId(rawId);
      if (isKnownCompetency(id)) {
        saveSystem.updateCompetency(id, amount);
      }
    });
  }

  getScore(id: string): number {
    return saveSystem.data.competencies[id] ?? 0;
  }

  getKnownCompetencies(): Array<{ id: string; label: string; score: number }> {
    return competencies.map((competency) => ({
      id: competency.id,
      label: competency.label,
      score: this.getScore(competency.id),
    }));
  }
}

export const competencyTracker = new CompetencyTracker();
