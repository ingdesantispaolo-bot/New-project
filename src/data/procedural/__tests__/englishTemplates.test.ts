import { describe, expect, it } from "vitest";
import { englishTemplates } from "../englishTemplates";

describe("English templates are not guessable by option length", () => {
  it("no template's correct answer is the unique longest or unique shortest option", () => {
    const longest: string[] = [];
    const shortest: string[] = [];
    for (const template of englishTemplates) {
      const correctLen = template.correctLabel.length;
      const others = template.distractors.map((distractor) => distractor.label.length);
      if (others.every((len) => correctLen > len)) longest.push(template.id);
      if (others.every((len) => correctLen < len)) shortest.push(template.id);
    }
    // A student must not be able to pick the answer by "choose the longest" or
    // "choose the shortest": the correct label must never be the sole extreme.
    expect(longest, `correct is unique LONGEST in: ${longest.join(", ")}`).toEqual([]);
    expect(shortest, `correct is unique SHORTEST in: ${shortest.join(", ")}`).toEqual([]);
  });

  it("every distractor is distinct from the correct label and carries diagnostic feedback", () => {
    for (const template of englishTemplates) {
      const labels = [template.correctLabel, ...template.distractors.map((distractor) => distractor.label)];
      expect(new Set(labels).size, `duplicate option in ${template.id}`).toBe(labels.length);
      for (const distractor of template.distractors) {
        expect(distractor.feedback.length, `weak feedback in ${template.id}: ${distractor.label}`).toBeGreaterThanOrEqual(20);
      }
    }
  });
});
