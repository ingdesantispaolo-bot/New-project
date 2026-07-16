import { describe, expect, it } from "vitest";
import {
  chapterExploreCompletionFeedback,
  chapterTrialCompletionFeedback,
  doorMissingFeedback,
  ghostNoraLine,
  ghostVerdict,
  standardCompletionCopy,
} from "../../scenes/procedural/MissionCompletionRules";

describe("MissionCompletionRules", () => {
  it("builds the blocked-door and chapter completion messages", () => {
    expect(doorMissingFeedback(["matematica", "coding"])).toBe("La porta resta in attesa: manca ancora matematica, coding.");
    expect(chapterExploreCompletionFeedback("Energia 3/5")).toContain("Prova del Capitolo");
    expect(chapterTrialCompletionFeedback("Energia 5/5")).toContain("Sabotatore respinto");
  });

  it("summarizes ghost challenge outcomes", () => {
    const ghost = { playerName: "Ada", targetScore: 120 };

    expect(ghostVerdict(140, ghost)).toContain("Sfida fantasma vinta");
    expect(ghostVerdict(100, ghost)).toContain("record di Ada");
    expect(ghostVerdict(100)).toBe("");
    expect(ghostNoraLine(140, ghost)).toContain("Record superato");
    expect(ghostNoraLine(100, ghost)).toContain("resiste");
  });

  it("builds standard completion copy for training and mission runs", () => {
    const training = standardCompletionCopy("training", "Energia stabile", 80);
    const mission = standardCompletionCopy("mission", "Energia piena", 140, { playerName: "Ada", targetScore: 120 });

    expect(training.outcomeLabel).toBe("Calibrazione registrata");
    expect(training.feedback).toContain("voto");
    expect(training.restartDelayMs).toBe(900);
    expect(mission.outcomeLabel).toBe("Missione completata");
    expect(mission.feedback).toContain("Sfida fantasma vinta");
    expect(mission.restartDelayMs).toBe(2600);
  });
});
