import { describe, expect, it } from "vitest";
import { competencies, canonicalCompetencyId, isKnownCompetency } from "../competencies";
import { proceduralDirector } from "../../procedural/ProceduralDirector";
import { TRAINABLE_BRANCHES } from "../../core/weakFocus";
import type { DifficultyLevel } from "../../procedural/ProceduralTypes";

// Competenze assegnate dalle missioni narrative fisse (Atlante, Città Intelligente,
// Serra, Fabbrica): fuori dal sistema procedurale ma devono comunque essere
// tracciabili e ora visibili nell'Accademia (rami geografia/cittadinanza/scienze).
const FIXED_MISSION_COMPETENCIES = [
  "geografia.orientamento", "geografia.scale",
  "cittadinanza.tecnologica",
  "scienze.dati", "scienze.osservazione", "scienze.sistemi", "scienze.energia",
];

// Le 28 competenze che, prima dell'allineamento, gli esercizi assegnavano ma il
// registro scartava in silenzio (fisica.* intero, ritmo/intervalli musicali,
// nomi matematici disallineati, ecc.). Devono ora tutte risultare tracciabili.
const PREVIOUSLY_DROPPED = [
  "fisica.energia", "fisica.equilibrio", "fisica.forze", "fisica.materia",
  "fisica.metodoSperimentale", "fisica.misure", "fisica.modelli", "fisica.moto",
  "fisica.onde", "fisica.osservazione", "fisica.ottica", "fisica.termologia",
  "musica.ascoltoVisivo", "musica.durate", "musica.intervalli", "musica.ritmo", "musica.scale",
  "matematica.equivalenze", "matematica.letturaDati", "matematica.pitagora",
  "matematica.proporzioni", "matematica.rapporti", "matematica.unitaMisura",
  "coding.controlloErrore", "coding.culturaInformatica", "coding.linguaggiProgrammazione",
  "inglese.scritturaBreve", "scienze.energia",
];

describe("Copertura competenze esercitate", () => {
  it("rende tracciabile ogni competenza prima scartata (registrata o aliasata)", () => {
    const stillDropped = PREVIOUSLY_DROPPED.filter((id) => !isKnownCompetency(id));
    expect(stillDropped, `ancora scartate: ${stillDropped.join(", ")}`).toEqual([]);
  });

  it("accende il ramo Fisica: esistono competenze fisica.* registrate", () => {
    expect(competencies.some((c) => c.id.startsWith("fisica."))).toBe(true);
  });

  it("gli alias puntano a competenze realmente registrate (nessun alias rotto)", () => {
    for (const id of PREVIOUSLY_DROPPED) {
      const canonical = canonicalCompetencyId(id);
      expect(competencies.some((c) => c.id === canonical), `${id} → ${canonical} inesistente`).toBe(true);
    }
  });

  it("nessun esercizio generato assegna una competenza non tracciabile", () => {
    // Guardia dinamica: genera missioni su molti seed/livelli e verifica che ogni
    // competenza dichiarata dai puzzle sia registrata o aliasata. Se un generatore
    // introdurrà un nuovo id senza registrarlo, questo test fallirà.
    const kinds = ["math", "circuit", "coding", "robot", "language", "english", "music", "physics", "latin"] as const;
    const offenders = new Set<string>();
    for (let seed = 0; seed < 12; seed += 1) {
      for (let level = 1 as DifficultyLevel; level <= 8; level = (level + 1) as DifficultyLevel) {
        const mission = proceduralDirector.generateMission(`COMP-${seed}`, level, []);
        for (const kind of kinds) {
          const puzzle = mission.puzzles[kind] as { competencies?: string[] } | undefined;
          for (const id of puzzle?.competencies ?? []) {
            if (!isKnownCompetency(id)) offenders.add(id);
          }
        }
      }
    }
    expect([...offenders], `competenze non tracciabili: ${[...offenders].join(", ")}`).toEqual([]);
  });

  it("rende tracciabili anche le competenze delle missioni fisse", () => {
    const untracked = FIXED_MISSION_COMPETENCIES.filter((id) => !isKnownCompetency(id));
    expect(untracked, `non tracciate: ${untracked.join(", ")}`).toEqual([]);
  });

  it("tiene geografia e cittadinanza fuori dai focus allenabili (nessun allenamento inesistente)", () => {
    // Hanno un ramo di maestria (visibilità) ma nessuna pratica procedurale:
    // non devono mai essere proposte come focus di allenamento.
    expect(TRAINABLE_BRANCHES.has("geografia")).toBe(false);
    expect(TRAINABLE_BRANCHES.has("cittadinanza")).toBe(false);
  });
});
