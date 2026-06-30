import { describe, expect, it } from "vitest";
import { selectWeakestFocus } from "../weakFocus";

describe("selectWeakestFocus", () => {
  it("returns the lowest-scoring practised trainable subject", () => {
    expect(selectWeakestFocus([
      { id: "matematica", score: 8 },
      { id: "italiano", score: 90 },
      { id: "inglese", score: 55 },
    ])).toBe("matematica");
  });

  it("ignores non-trainable branches (scienze/trasversali)", () => {
    expect(selectWeakestFocus([
      { id: "scienze", score: 2 },
      { id: "trasversali", score: 1 },
      { id: "inglese", score: 30 },
      { id: "coding", score: 70 },
    ])).toBe("inglese");
  });

  it("ignores subjects with no practice (score 0)", () => {
    expect(selectWeakestFocus([
      { id: "matematica", score: 0 },
      { id: "italiano", score: 40 },
      { id: "coding", score: 65 },
    ])).toBe("italiano");
  });

  it("returns undefined with fewer than two practised subjects", () => {
    expect(selectWeakestFocus([
      { id: "matematica", score: 40 },
      { id: "italiano", score: 0 },
    ])).toBeUndefined();
  });

  it("returns undefined for a brand-new player", () => {
    expect(selectWeakestFocus([
      { id: "matematica", score: 0 },
      { id: "italiano", score: 0 },
    ])).toBeUndefined();
  });
});
