import { beforeEach, describe, expect, it } from "vitest";
import { proceduralDirector } from "../ProceduralDirector";
import { progressiveMissionBuilder } from "../ProgressiveMissionBuilder";
import type { DifficultyLevel, GeneratedMission } from "../ProceduralTypes";
import { installMemoryStorage } from "./testStorage";

type Kind = "language" | "circuit" | "math" | "english" | "coding" | "music";

const norm = (text: string): string => text.replace(/\s+/g, " ").trim();

/** Substance signature — mirrors ProgressiveMissionBuilder.signatureFor. */
function signature(mission: GeneratedMission, kind: Kind): string {
  const p = mission.puzzles;
  switch (kind) {
    case "math": {
      const m = p.math;
      const gw = m.graphWorkshop
        ? `|gw:${m.graphWorkshop.parameters.map((x) => `${x.key}=${x.target}`).join(",")};${m.graphWorkshop.targetPoints.map((pt) => `${pt.x}:${pt.y}`).join("|")}`
        : "";
      const lab = m.equationLab ? `|eq:${m.equationLab.roots.join(",")}` : "";
      return `math|${m.archetype ?? "base"}|${m.answer}|${norm(m.prompt)}${gw}${lab}`;
    }
    case "language":
      return `language|${p.language.id}|${p.language.repaired}|${p.language.learningPurpose ?? ""}`;
    case "english":
      return `english|${p.english.id}|${norm(p.english.instruction)}|${p.english.choices.find((c) => c.isCorrect)?.label ?? ""}`;
    case "coding":
      return `coding|${p.coding.challengeType}|${norm(p.coding.question)}|${p.coding.correctOption}`;
    case "circuit":
      return `circuit|${p.circuit.scenarioType ?? ""}|${norm(p.circuit.symptom)}|${p.circuit.requiredRepairs.join(",")}`;
    case "music":
      return `music|${p.music.clef}|${p.music.noteName}|${p.music.octave}|${p.music.challengeMode}`;
  }
}

const KNOWN_KINDS: Kind[] = ["language", "circuit", "math", "english", "coding", "music"];

function selectedKinds(mission: GeneratedMission): Kind[] {
  // Only the disciplines this test models; new domains (e.g. physics) get
  // their own coverage and are skipped here so this test stays focused.
  return mission.map.hotspots
    .filter((h) => h.id !== "door" && h.puzzleKind && KNOWN_KINDS.includes(h.puzzleKind as Kind))
    .map((h) => h.puzzleKind as Kind);
}

function buildClimb(): Array<{ level: DifficultyLevel; mission: GeneratedMission }> {
  const levels: Array<{ level: DifficultyLevel; mission: GeneratedMission }> = [];
  for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
    const focus = progressiveMissionBuilder.focusForLevel(level);
    const base = proceduralDirector.generateFreshMission(level, [focus]);
    levels.push({ level, mission: progressiveMissionBuilder.buildLevelMission(base, level) });
  }
  return levels;
}

describe("Scalata exercise variety", () => {
  beforeEach(() => installMemoryStorage());

  it("never repeats the exact same exercise within a climb (30 climbs)", () => {
    for (let climb = 0; climb < 30; climb += 1) {
      installMemoryStorage();
      const seen = new Map<string, string>();
      for (const { level, mission } of buildClimb()) {
        for (const kind of selectedKinds(mission)) {
          const sig = signature(mission, kind);
          expect(seen.has(sig), `duplicate ${kind} at L${level} (also at ${seen.get(sig)})`).toBe(false);
          seen.set(sig, `${kind}@L${level}`);
        }
      }
    }
  });

  it("varies math form across a climb (not all graph workshop)", () => {
    const forms = new Set<string>();
    let mathOccurrences = 0;
    for (const { mission } of buildClimb()) {
      if (selectedKinds(mission).includes("math")) {
        mathOccurrences += 1;
        forms.add(mission.puzzles.math.graphWorkshop ? "graph-workshop" : (mission.puzzles.math.archetype ?? "?"));
      }
    }
    expect(mathOccurrences).toBeGreaterThan(3);
    expect(forms.size).toBeGreaterThan(2);
  });
});
