import { describe, expect, it, vi } from "vitest";

vi.mock("../../core/EventBus", () => ({
  EventBus: { emit: vi.fn(), on: vi.fn(), off: vi.fn() },
  GameEvents: {
    SettingsChanged: "settings:changed",
  },
}));
import { buildChapterExploreRun, buildChapterTrialRun, chapterExploreLevel, chapterTrialLevel } from "../../core/ChapterTrial";
import { proceduralRunRules } from "../../core/ProceduralRunRules";

const chapterId = "mission-01-laboratorio-spento";

describe("Chapter explore + trial flow", () => {
  it("builds exploration as a low-pressure preparation run", () => {
    const explore = buildChapterExploreRun(chapterId, 1);

    expect(explore.chapterExploreMissionId).toBe(chapterId);
    expect(explore.chapterMissionId).toBeUndefined();
    expect(explore.lives).toBeUndefined();
    expect(explore.timeLimitMs).toBeUndefined();
    expect(explore.difficulty).toBe(chapterExploreLevel(chapterId));
    expect(proceduralRunRules.pressureEnabledFor(explore)).toBe(false);
  });

  it("keeps the graded trial as the pressured chapter gate", () => {
    const trial = buildChapterTrialRun(chapterId, 1);

    expect(trial.chapterMissionId).toBe(chapterId);
    expect(trial.chapterExploreMissionId).toBeUndefined();
    expect(trial.lives).toBe(proceduralRunRules.maxLives);
    expect(trial.timeLimitMs).toBeGreaterThan(0);
    expect(trial.difficulty).toBe(chapterTrialLevel(chapterId));
    expect(proceduralRunRules.pressureEnabledFor(trial)).toBe(true);
  });
});
