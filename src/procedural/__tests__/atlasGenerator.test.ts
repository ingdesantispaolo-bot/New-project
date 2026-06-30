import { describe, expect, it } from "vitest";
import { AtlasGenerator } from "../generators/AtlasGenerator";
import { Random } from "../Random";
import { DIRECTION_VECTORS, OPPOSITE, type AtlasVariant, type Cardinal } from "../../data/atlas";

function raysThrough(variant: AtlasVariant, cx: number, cy: number): number {
  let count = 0;
  for (const bearing of variant.bearings) {
    const station = variant.coordinates.find((c) => c.id === bearing.id);
    if (!station) continue;
    const v = DIRECTION_VECTORS[bearing.answer];
    const dx = cx - station.x;
    const dy = cy - station.y;
    if (dx === 0 && dy === 0) continue;
    const collinear = dx * v.dy - dy * v.dx === 0;
    const forward = dx * v.dx + dy * v.dy > 0;
    if (collinear && forward) count += 1;
  }
  return count;
}

describe("AtlasGenerator (Mission 5 procedural puzzle)", () => {
  it("always produces a solvable puzzle with a unique convergence (500 seeds)", () => {
    for (let i = 0; i < 500; i += 1) {
      const variant = new AtlasGenerator(new Random(`atlas:${i}`)).generate();
      const { cols, rows } = variant.grid;

      expect(variant.bearings).toHaveLength(3);
      expect(variant.coordinates).toHaveLength(3);

      // Stations: on-grid, distinct, not on the source.
      const cells = new Set<string>();
      for (const c of variant.coordinates) {
        expect(c.x).toBeGreaterThanOrEqual(0);
        expect(c.x).toBeLessThan(cols);
        expect(c.y).toBeGreaterThanOrEqual(0);
        expect(c.y).toBeLessThan(rows);
        expect(c.x === variant.source.x && c.y === variant.source.y).toBe(false);
        cells.add(`${c.x},${c.y}`);
      }
      expect(cells.size).toBe(3);

      // Each bearing's declared direction actually points at the source.
      for (const bearing of variant.bearings) {
        const station = variant.coordinates.find((c) => c.id === bearing.id)!;
        const dx = variant.source.x - station.x;
        const dy = variant.source.y - station.y;
        const v = DIRECTION_VECTORS[bearing.answer];
        expect(dx * v.dy - dy * v.dx).toBe(0);
        expect(dx * v.dx + dy * v.dy).toBeGreaterThan(0);
      }

      // No opposite (collinear) bearings.
      const dirs = variant.bearings.map((b) => b.answer) as Cardinal[];
      expect(dirs.some((d) => dirs.includes(OPPOSITE[d]))).toBe(false);

      // The source is the unique cell crossed by all three bearings.
      expect(raysThrough(variant, variant.source.x, variant.source.y)).toBe(3);
      let triple = 0;
      for (let x = 0; x < cols; x += 1) {
        for (let y = 0; y < rows; y += 1) {
          if (raysThrough(variant, x, y) === 3) triple += 1;
        }
      }
      expect(triple).toBe(1);

      // Scale arithmetic is consistent.
      expect(variant.scale.answerKm).toBe(variant.scale.gridDistance * variant.scale.kmPerCell);
      expect(variant.scale.gridDistance).toBeGreaterThanOrEqual(3);
    }
  });
});
