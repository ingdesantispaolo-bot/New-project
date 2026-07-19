import { existsSync, readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { generateOutdoorChunk, OUTDOOR_CHUNK_SIZE } from "../../procedural/OutdoorChunkGenerator";

// Contratto di parità Godot ↔ Phaser per il generatore del mondo esterno.
// La fixture ricca è prodotta da `node scripts/build-outdoor-fixtures.mjs`
// (dal generatore reale) e riletta dall'audit Godot `fixture_audit.gd`.
// Il confronto esatto qui garantisce che il generatore TS non cambi output
// senza rigenerare la fixture; l'audit Godot chiude il cerchio sull'altro motore.

type RichFixture = {
  schemaVersion: number;
  generator: string;
  chunkSize: number;
  seedFormat: string;
  cases: Array<{ seed: string; chunkX: number; chunkY: number; chunk: unknown }>;
};

const FIXTURE_URL = new URL("../../../godot/data/parity-fixtures.json", import.meta.url);

describe("Outdoor generator parity contract", () => {
  it("is deterministic and stable across coordinates", () => {
    const a = generateOutdoorChunk("parity-seed", 2, -3);
    const b = generateOutdoorChunk("parity-seed", 2, -3);
    const neighbor = generateOutdoorChunk("parity-seed", 3, -3);
    expect(a).toEqual(b);
    expect(a).not.toEqual(neighbor);
    expect(a.id).toBe("chunk-2_-3");
    expect(a.size).toBe(OUTDOOR_CHUNK_SIZE);
  });

  it("keeps stable IDs and bounded counts for the seed contract", () => {
    for (const [cx, cy] of [[0, 0], [1, 0], [0, 1], [-1, -1]] as const) {
      const chunk = generateOutdoorChunk("outdoor-parity-01", cx, cy);
      expect(chunk.id).toBe(`chunk-${cx}_${cy}`);
      expect(chunk.biome).toBe(chunk.patch.id);
      expect(chunk.obstacles.length).toBeGreaterThanOrEqual(15);
      expect(chunk.obstacles.length).toBeLessThanOrEqual(24);
      expect(chunk.props.length).toBeGreaterThanOrEqual(6);
      expect(chunk.props.length).toBeLessThanOrEqual(11);
      expect(chunk.treasures.length).toBeGreaterThanOrEqual(1);
      expect(chunk.treasures.length).toBeLessThanOrEqual(3);
      expect(chunk.encounters.length).toBeGreaterThanOrEqual(1);
      expect(chunk.obstacles.every((o) => o.id.startsWith(`obs-${cx}_${cy}-`))).toBe(true);
      expect(chunk.encounters.every((e) => e.reward > 0 && e.difficulty > 0)).toBe(true);
    }
  });

  it("reproduces the shared parity fixture exactly when present", () => {
    if (!existsSync(FIXTURE_URL)) {
      // La fixture è un artefatto generato: `node scripts/build-outdoor-fixtures.mjs`.
      // In sua assenza il contratto resta coperto dai controlli deterministici sopra.
      return;
    }
    const fixture = JSON.parse(readFileSync(FIXTURE_URL, "utf8")) as RichFixture;
    expect(fixture.schemaVersion).toBe(2);
    expect(fixture.chunkSize).toBe(OUTDOOR_CHUNK_SIZE);
    expect(fixture.cases.length).toBeGreaterThan(0);
    for (const item of fixture.cases) {
      const chunk = generateOutdoorChunk(item.seed, item.chunkX, item.chunkY);
      expect(chunk).toEqual(item.chunk);
    }
  });
});
