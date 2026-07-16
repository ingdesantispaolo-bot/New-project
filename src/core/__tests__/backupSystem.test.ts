import { beforeEach, describe, expect, it, vi } from "vitest";

// PlayerSystem arriva a Phaser via SettingsSystem → EventBus; in node basta un
// EventEmitter minimo al posto dell'intera libreria.
vi.mock("phaser", () => ({
  default: {
    Events: {
      EventEmitter: class {
        on(): this { return this; }
        once(): this { return this; }
        off(): this { return this; }
        emit(): boolean { return true; }
        removeAllListeners(): this { return this; }
      },
    },
  },
}));

import { backupSystem } from "../BackupSystem";
import { playerSystem } from "../PlayerSystem";

/** localStorage in-memory completo: BackupSystem itera length/key(). */
function installIterableStorage(): Map<string, string> {
  const store = new Map<string, string>();
  (globalThis as unknown as { localStorage: Storage }).localStorage = {
    getItem: (key: string) => (store.has(key) ? store.get(key)! : null),
    setItem: (key: string, value: string) => { store.set(key, String(value)); },
    removeItem: (key: string) => { store.delete(key); },
    clear: () => store.clear(),
    key: (index: number) => Array.from(store.keys())[index] ?? null,
    get length() { return store.size; },
  } as unknown as Storage;
  return store;
}

describe("BackupSystem", () => {
  let store: Map<string, string>;

  beforeEach(() => {
    store = installIterableStorage();
  });

  it("conta solo le voci del gioco", () => {
    store.set("eli-quest-save-v1", "{}");
    store.set("eli-quest-settings-v1", "{}");
    store.set("altro-sito", "x");
    expect(backupSystem.entryCount()).toBe(2);
  });

  it("ripristina un backup valido sostituendo le chiavi correnti", () => {
    store.set("eli-quest-save-v1", "vecchio");
    store.set("eli-quest-profilo-morto", "da-eliminare");
    store.set("altro-sito", "intatto");
    const raw = JSON.stringify({
      format: "eli-quest-backup",
      version: 1,
      exportedAt: new Date().toISOString(),
      entries: {
        "eli-quest-save-v1": "nuovo",
        "eli-quest-players-v1": "{\"version\":1}",
        "chiave-estranea": "ignorata",
      },
    });

    const restored = backupSystem.restore(raw);

    expect(restored).toBe(2);
    expect(store.get("eli-quest-save-v1")).toBe("nuovo");
    expect(store.get("eli-quest-players-v1")).toBe("{\"version\":1}");
    // Le chiavi di gioco assenti dal backup non risorgono...
    expect(store.has("eli-quest-profilo-morto")).toBe(false);
    // ...le chiavi estranee (altri siti o fuori prefisso) restano intatte.
    expect(store.get("altro-sito")).toBe("intatto");
    expect(store.has("chiave-estranea")).toBe(false);
  });

  it("rifiuta JSON illeggibile, formato estraneo e backup vuoti", () => {
    expect(() => backupSystem.restore("{non-json")).toThrow(/JSON/);
    expect(() => backupSystem.restore(JSON.stringify({ format: "altro", entries: {} }))).toThrow(/Eli Quest/);
    expect(() => backupSystem.restore(JSON.stringify({
      format: "eli-quest-backup", version: 1, exportedAt: "", entries: { "fuori-prefisso": "x" },
    }))).toThrow(/non contiene dati/);
  });
});

describe("PlayerSystem.recentStruggles (Quaderno degli errori)", () => {
  beforeEach(() => {
    installIterableStorage();
  });

  function seedStore(results: Array<Record<string, unknown>>): void {
    const now = new Date().toISOString();
    localStorage.setItem("eli-quest-players-v1", JSON.stringify({
      version: 1,
      activePlayerId: "p-a",
      players: [
        { id: "p-a", name: "Eli", createdAt: now, lastActiveAt: now },
        { id: "p-b", name: "Marco", createdAt: now, lastActiveAt: now },
      ],
      results,
    }));
    playerSystem.load();
  }

  function exercise(overrides: Record<string, unknown>): Record<string, unknown> {
    return {
      id: `r-${Math.random()}`, sourceKey: `sk-${Math.random()}`, playerId: "p-a", playerName: "Eli",
      category: "exercise", key: "math", label: "Terminale matematico", difficulty: 3,
      score: 50, elapsedMs: 60_000, hintsUsed: 0, attempts: 0,
      completedAt: "2026-07-10T10:00:00.000Z", mode: "training", seed: "S", grade: 8,
      ...overrides,
    };
  }

  it("raccoglie solo gli esercizi con errori o voto basso del giocatore attivo", () => {
    seedStore([
      exercise({ attempts: 2, grade: 5 }),                                  // inciampo ✓
      exercise({ key: "language", attempts: 0, grade: 4 }),                 // voto basso ✓
      exercise({ key: "music", attempts: 0, grade: 9 }),                    // pulito ✗
      exercise({ key: "circuit", attempts: 3, playerId: "p-b", playerName: "Marco" }), // altro giocatore ✗
    ]);

    const struggles = playerSystem.recentStruggles(4);
    expect(struggles.map((item) => item.key).sort()).toEqual(["language", "math"]);
    expect(struggles.find((item) => item.key === "math")?.domain).toBe("matematica");
    expect(struggles.find((item) => item.key === "language")?.domain).toBe("italiano");
  });

  it("tiene solo l'inciampo più recente per tipo di esercizio", () => {
    seedStore([
      exercise({ attempts: 1, grade: 5, completedAt: "2026-07-01T10:00:00.000Z", difficulty: 2 }),
      exercise({ attempts: 2, grade: 4, completedAt: "2026-07-12T10:00:00.000Z", difficulty: 4 }),
    ]);

    const struggles = playerSystem.recentStruggles(4);
    expect(struggles).toHaveLength(1);
    expect(struggles[0]?.difficulty).toBe(4);
  });

  it("è vuoto per un profilo senza errori", () => {
    seedStore([exercise({ attempts: 0, grade: 9 })]);
    expect(playerSystem.recentStruggles()).toEqual([]);
  });
});
