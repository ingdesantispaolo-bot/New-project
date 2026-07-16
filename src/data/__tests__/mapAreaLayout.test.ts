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
});
