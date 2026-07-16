import { describe, expect, it } from "vitest";
import {
  hintButtonLabel,
  nextPedagogicHint,
  puzzleHintTexts,
} from "../../scenes/procedural/PuzzleHintRules";

describe("PuzzleHintRules", () => {
  it("prefers the pedagogic ladder over base hints", () => {
    const puzzle = {
      hints: ["base 1", "base 2"],
      pedagogy: { hintLadder: [{ text: "step 1" }, { text: "" }, { text: "step 2" }] },
    };

    expect(puzzleHintTexts(puzzle)).toEqual(["step 1", "step 2"]);
  });

  it("falls back to base hints when the ladder is empty", () => {
    expect(puzzleHintTexts({ hints: ["base"], pedagogy: { hintLadder: [{ text: "" }] } })).toEqual(["base"]);
  });

  it("selects the next hint and clamps to the last available hint", () => {
    const puzzle = { hints: ["first", "second"] };

    expect(nextPedagogicHint(puzzle, 0, "fallback")).toBe("first");
    expect(nextPedagogicHint(puzzle, 8, "fallback")).toBe("second");
    expect(nextPedagogicHint({ hints: [] }, 0, "fallback")).toBe("fallback");
  });

  it("builds button labels from remaining hints", () => {
    const puzzle = { hints: ["a", "b"] };

    expect(hintButtonLabel(puzzle, 0, "Indizio")).toBe("Indizio 1/2");
    expect(hintButtonLabel(puzzle, 1, "Indizio")).toBe("Indizio 2/2");
    expect(hintButtonLabel(puzzle, 2, "Indizio")).toBe("Indizi esauriti");
    expect(hintButtonLabel({ hints: [] }, 0, "Indizio")).toBe("Indizio");
  });
});
