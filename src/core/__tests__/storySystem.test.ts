import { beforeEach, describe, expect, it } from "vitest";
import { storySystem, WONDER_DIARIO_REQUIRED } from "../StorySystem";
import type { PonteId } from "../StorySystem";

const ALL_PONTI: PonteId[] = [
  "reattore", "bio-ponte", "fabbricatore", "data-core", "glifi", "risonanza", "comando", "citta",
];

describe("StorySystem — Diario di Bordo & bivi", () => {
  let testId = 0;
  beforeEach(() => {
    const id = `test-${testId++}`;
    storySystem.setPlayerIdProvider(() => id);
    storySystem.reset();
  });

  it("starts with an empty Diario and no choices", () => {
    expect(storySystem.discoveredCount()).toBe(0);
    expect(storySystem.choices()).toEqual({});
    expect(storySystem.diario().every((fragment) => !fragment.unlocked)).toBe(true);
  });

  it("reveals a fragment only when its ponte is reactivated", () => {
    const locked = storySystem.diario().find((f) => f.id === "atto1-reattore-presente");
    expect(locked?.unlocked).toBe(false);

    const unlocked = storySystem.recordPonteComplete("reattore");
    expect(unlocked.map((f) => f.id)).toContain("atto1-reattore-presente");
    expect(storySystem.discoveredCount()).toBe(1);
  });

  it("recordPonteComplete is idempotent", () => {
    storySystem.recordPonteComplete("reattore");
    const again = storySystem.recordPonteComplete("reattore");
    expect(again).toHaveLength(0);
    expect(storySystem.discoveredCount()).toBe(1);
  });

  it("gates the choice-specific fragments (firstPower)", () => {
    storySystem.recordPonteComplete("bio-ponte");
    storySystem.recordPonteComplete("data-core");
    // Neither the bio garden nor the early-voice fragment yet: no choice made.
    const ids = () => storySystem.unlockedFragments().map((f) => f.id);
    expect(ids()).not.toContain("atto1-bio-passato");
    expect(ids()).not.toContain("atto1-data-presente");
    // Always-on data fragment is available regardless of choice.
    expect(ids()).toContain("atto1-data-passato");

    const revealed = storySystem.chooseFirstPower("bio");
    expect(revealed.map((f) => f.id)).toContain("atto1-bio-passato");
    expect(ids()).toContain("atto1-bio-passato");
    expect(ids()).not.toContain("atto1-data-presente");
  });

  it("persists choices and progress across a reload", () => {
    const pid = "persist-me";
    storySystem.setPlayerIdProvider(() => pid);
    storySystem.reset();
    storySystem.recordPonteComplete("reattore");
    storySystem.chooseGuardian("ally");

    // Simulate a fresh read of the same profile.
    storySystem.setPlayerIdProvider(() => pid);
    expect(storySystem.guardianIsAlly()).toBe(true);
    expect(storySystem.state().pontiComplete).toContain("reattore");
  });

  it("keeps profiles separate", () => {
    storySystem.setPlayerIdProvider(() => "alice");
    storySystem.reset();
    storySystem.recordPonteComplete("reattore");
    storySystem.setPlayerIdProvider(() => "bob");
    storySystem.reset();
    expect(storySystem.discoveredCount()).toBe(0);
    storySystem.setPlayerIdProvider(() => "alice");
    expect(storySystem.discoveredCount()).toBe(1);
  });

  it("only offers the Meraviglia ending when its conditions hold", () => {
    // No guardian, empty diario: only the two base endings.
    expect(storySystem.availableEndings({ masteredSubjects: 8 })).toEqual(["silence", "fire"]);

    ALL_PONTI.forEach((ponte) => storySystem.recordPonteComplete(ponte));
    storySystem.chooseFirstPower("bio"); // a real playthrough always makes this choice
    storySystem.chooseGuardian("ally");
    expect(storySystem.discoveredCount()).toBeGreaterThanOrEqual(WONDER_DIARIO_REQUIRED);

    expect(storySystem.canChooseWonder({ masteredSubjects: 4 })).toBe(true);
    expect(storySystem.availableEndings({ masteredSubjects: 4 })).toContain("wonder");
    // Too few mastered subjects → no wonder.
    expect(storySystem.canChooseWonder({ masteredSubjects: 3 })).toBe(false);
    // Hostile guardian → no wonder even with mastery.
    storySystem.chooseGuardian("hostile");
    expect(storySystem.canChooseWonder({ masteredSubjects: 8 })).toBe(false);
  });

  it("reveals the matching ending fragment once chosen", () => {
    storySystem.recordPonteComplete("citta");
    const ids = () => storySystem.unlockedFragments().map((f) => f.id);
    expect(ids()).not.toContain("atto3-finale-wonder");
    storySystem.chooseEnding("wonder");
    expect(ids()).toContain("atto3-finale-wonder");
    expect(ids()).not.toContain("atto3-finale-silence");
  });
});
