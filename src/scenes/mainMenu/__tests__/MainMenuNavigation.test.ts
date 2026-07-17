import { describe, expect, it } from "vitest";
import { focusOptions, palestraFocusButtons, palestraShortcutButtons, rectsOverlap, type MenuRect } from "../MainMenuNavigation";

function rectAt<T extends MenuRect>(rects: T[], x: number, y: number): T | undefined {
  return rects.find((rect) => (
    x >= rect.x - rect.width / 2
    && x <= rect.x + rect.width / 2
    && y >= rect.y - rect.height / 2
    && y <= rect.y + rect.height / 2
  ));
}

describe("MainMenu palestra navigation hitboxes", () => {
  it("keeps every subject focus button distinct and in curriculum order", () => {
    expect(focusOptions.map((focus) => focus.id)).toEqual([
      "matematica",
      "italiano",
      "inglese",
      "elettronica",
      "coding",
      "musica",
      "fisica",
      "latino",
    ]);
    expect(new Set(palestraFocusButtons().map((button) => button.focus)).size).toBe(focusOptions.length);
  });

  it("does not overlap subject focus hitboxes or footer shortcuts", () => {
    const buttons = [...palestraFocusButtons(), ...palestraShortcutButtons()];
    buttons.forEach((button, index) => {
      buttons.slice(index + 1).forEach((other) => {
        expect(rectsOverlap(button, other, 2), `${button.id} overlaps ${other.id}`).toBe(false);
      });
    });
  });

  it("routes center taps to the intended subject, including coding and latino", () => {
    const focusButtons = palestraFocusButtons();
    const coding = focusButtons.find((button) => button.focus === "coding");
    const latino = focusButtons.find((button) => button.focus === "latino");

    expect(coding).toBeDefined();
    expect(latino).toBeDefined();
    expect(rectAt(focusButtons, coding!.x, coding!.y)?.focus).toBe("coding");
    expect(rectAt(focusButtons, latino!.x, latino!.y)?.focus).toBe("latino");
  });

  it("keeps footer shortcuts outside subject routing", () => {
    const focusButtons = palestraFocusButtons();
    palestraShortcutButtons().forEach((shortcut) => {
      expect(rectAt(focusButtons, shortcut.x, shortcut.y), `${shortcut.id} lands on a subject button`).toBeUndefined();
    });
  });
});
