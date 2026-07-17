import { describe, expect, it } from "vitest";
import { MAP_AREAS } from "../procedural/mapAreas";

const CLICK_MARGIN = 18;

type Rect = { left: number; right: number; top: number; bottom: number };

function hitRect(console: { x: number; y: number; w: number; h: number }): Rect {
  return {
    left: console.x - console.w / 2 - CLICK_MARGIN,
    right: console.x + console.w / 2 + CLICK_MARGIN,
    top: console.y - console.h / 2 - CLICK_MARGIN,
    bottom: console.y + console.h / 2 + CLICK_MARGIN,
  };
}

function overlaps(a: Rect, b: Rect): boolean {
  return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
}

function inside(rect: Rect, area: { worldW: number; worldH: number }): boolean {
  return rect.left >= 0 && rect.top >= 0 && rect.right <= area.worldW && rect.bottom <= area.worldH;
}

function pointInWall(x: number, y: number, wall: { x: number; y: number; w: number; h: number }): boolean {
  return x >= wall.x && x <= wall.x + wall.w && y >= wall.y && y <= wall.y + wall.h;
}

describe("map area console layout", () => {
  it("keeps click hitboxes separated so a tap cannot open the wrong console", () => {
    const collisions: string[] = [];

    Object.values(MAP_AREAS).forEach((area) => {
      area.consoles.forEach((a, index) => {
        area.consoles.slice(index + 1).forEach((b) => {
          if (overlaps(hitRect(a), hitRect(b))) {
            collisions.push(`${area.id}: ${a.id} overlaps ${b.id}`);
          }
        });
      });
    });

    expect(collisions).toEqual([]);
  });

  it("keeps every console hitbox inside its area bounds", () => {
    const outOfBounds: string[] = [];

    Object.values(MAP_AREAS).forEach((area) => {
      area.consoles.forEach((console) => {
        if (!inside(hitRect(console), area)) {
          outOfBounds.push(`${area.id}: ${console.id}`);
        }
      });
    });

    expect(outOfBounds).toEqual([]);
  });

  it("does not place console centers inside collision walls", () => {
    const blocked: string[] = [];

    Object.values(MAP_AREAS).forEach((area) => {
      area.consoles.forEach((console) => {
        if (area.walls.some((wall) => pointInWall(console.x, console.y, wall))) {
          blocked.push(`${area.id}: ${console.id}`);
        }
      });
    });

    expect(blocked).toEqual([]);
  });

  it("links navigation consoles only to existing map areas", () => {
    const missingTargets: string[] = [];
    const areaIds = new Set(Object.keys(MAP_AREAS));

    Object.values(MAP_AREAS).forEach((area) => {
      area.consoles.forEach((console) => {
        if (console.targetArea && !areaIds.has(console.targetArea)) {
          missingTargets.push(`${area.id}: ${console.id} -> ${console.targetArea}`);
        }
      });
    });

    expect(missingTargets).toEqual([]);
  });

  it("keeps non-room navigation consoles pointed at known scenes", () => {
    const allowedScenes = new Set(["CampaignScene", "OutdoorAdventureScene"]);
    const unknownScenes: string[] = [];

    Object.values(MAP_AREAS).forEach((area) => {
      area.consoles.forEach((console) => {
        if (console.targetScene && !allowedScenes.has(console.targetScene)) {
          unknownScenes.push(`${area.id}: ${console.id} -> ${console.targetScene}`);
        }
      });
    });

    expect(unknownScenes).toEqual([]);
  });

  it("exposes the outdoor map as a visible portal in the central world", () => {
    const lab = MAP_AREAS.laboratorio;
    const portal = lab.consoles.find((console) => console.id === "outdoor-gate");

    expect(portal).toMatchObject({
      label: "Varco Esterno",
      assetId: "portal",
      targetScene: "OutdoorAdventureScene",
    });
  });

  it("keeps explorable rooms visually distinct by background and accent", () => {
    const duplicateBackgrounds: string[] = [];
    const duplicateAccents: string[] = [];
    const backgrounds = new Map<string, string>();
    const accents = new Map<number, string>();

    Object.values(MAP_AREAS).forEach((area) => {
      const previousBackground = backgrounds.get(area.bgTexture);
      if (previousBackground) duplicateBackgrounds.push(`${previousBackground} / ${area.id}: ${area.bgTexture}`);
      backgrounds.set(area.bgTexture, area.id);

      const previousAccent = accents.get(area.accent);
      if (previousAccent) duplicateAccents.push(`${previousAccent} / ${area.id}: ${area.accent.toString(16)}`);
      accents.set(area.accent, area.id);
    });

    expect(duplicateBackgrounds).toEqual([]);
    expect(duplicateAccents).toEqual([]);
  });
});
