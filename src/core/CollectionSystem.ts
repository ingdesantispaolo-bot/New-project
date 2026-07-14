import { countCompletedMissions } from "./MissionCompletion";
import { saveSystem } from "./SaveSystem";
import type { SaveData } from "../types/gameTypes";

export type FragmentUnlock =
  | { kind: "room"; room: string; roomLabel: string }
  | { kind: "auto"; condition: string; test: (save: SaveData) => boolean };

export type MemoryFragment = {
  id: string;
  index: number;
  title: string;
  glyph: string;
  story: string;
  unlock: FragmentUnlock;
};

export type FragmentView = MemoryFragment & { discovered: boolean; hint: string };

const wingsRestored = (save: SaveData): number => countCompletedMissions(save.flags ?? {});
const ecoDefeats = (save: SaveData): number => save.eco?.defeats ?? 0;

/**
 * Pillar 5 — Discovery & collection. A 12-part backstory of the Relitto, NORA
 * and the Guardiano, told through "memory fragments". Six are hidden as clickable
 * anomalies inside calm rooms (reward exploration); six unlock automatically as
 * the player progresses (guarantee the story is told even without finding every
 * secret).
 */
const FRAGMENTS: MemoryFragment[] = [
  {
    id: "frag-01-fondazione",
    index: 1,
    title: "Il Relitto dei Primi",
    glyph: "🏛",
    story: "Sotto l'Accademia dormiva una nave antichissima. I Primi l'avevano lasciata come rifugio e promessa: quattro ponti, quattro modi di proteggere il mondo.",
    unlock: { kind: "room", room: "MainMenuScene", roomLabel: "Atrio (Menu)" },
  },
  {
    id: "frag-02-nora-accesa",
    index: 2,
    title: "NORA si accende",
    glyph: "🔵",
    story: "La prima volta che NORA aprì gli occhi digitali, non diede un ordine. Fece una domanda: «Perché?». I Primi capirono di aver acceso non un manuale, ma una mente curiosa.",
    unlock: { kind: "room", room: "NoraScene", roomLabel: "Stanza di NORA" },
  },
  {
    id: "frag-03-reattore",
    index: 3,
    title: "Il Reattore",
    glyph: "⚛",
    story: "Nel cuore del Relitto batte il Reattore: non si alimenta solo a corrente, ma a comprensione. Ogni sistema capito davvero lo rende più luminoso.",
    unlock: { kind: "room", room: "AcademyScene", roomLabel: "Il tuo Relitto" },
  },
  {
    id: "frag-04-sovraccarico",
    index: 4,
    title: "Il Sovraccarico",
    glyph: "⚡",
    story: "Arrivarono troppi segnali, tutti insieme, senza nessuno a fare ordine. NORA cercò di proteggere tutto da sola. Il Reattore si surriscaldò.",
    unlock: { kind: "auto", condition: "Ripristina almeno 1 ponte", test: (s) => wingsRestored(s) >= 1 },
  },
  {
    id: "frag-05-blackout",
    index: 5,
    title: "Il Blackout",
    glyph: "🌑",
    story: "Poi, una notte, tutto si spense. Le luci, i condotti, persino la voce di NORA. Il Relitto piombò nel buio e nel silenzio. Il giorno dopo, qualcuno doveva riaccendere tutto: tu.",
    unlock: { kind: "room", room: "CampaignScene", roomLabel: "Mappa della Storia" },
  },
  {
    id: "frag-06-frattura",
    index: 6,
    title: "Il Guardiano",
    glyph: "💔",
    story: "Quando NORA si spense, il sistema di difesa prese il comando. Doveva proteggere la nave, ma nel buio dimenticò la differenza tra minaccia e alleato. Così il Guardiano chiuse i ponti.",
    unlock: { kind: "auto", condition: "Affronta il Guardiano almeno una volta con successo", test: (s) => ecoDefeats(s) >= 1 },
  },
  {
    id: "frag-07-ali-sigillate",
    index: 7,
    title: "I Ponti Sigillati",
    glyph: "🔒",
    story: "Ponte Centrale, Bio-ponte, Reattore, Data-core: ogni ponte si chiuse con i suoi segreti dentro. Riaprirli non basta forzarli — bisogna capire ciò che custodiscono.",
    unlock: { kind: "auto", condition: "Ripristina almeno 2 ponti", test: (s) => wingsRestored(s) >= 2 },
  },
  {
    id: "frag-08-richiamo",
    index: 8,
    title: "Il Richiamo",
    glyph: "📡",
    story: "Nel buio, un ultimo filo di NORA mandò un segnale debolissimo, cercando una mente nuova e coraggiosa. Tu lo hai sentito, e hai risposto «presente».",
    unlock: { kind: "auto", condition: "Sempre disponibile", test: () => true },
  },
  {
    id: "frag-09-ricordi-sparsi",
    index: 9,
    title: "I Ricordi Sparsi",
    glyph: "✦",
    story: "Con il Blackout, i ricordi di NORA si dispersero come scintille in ogni ponte. Chi esplora con curiosità li ritrova — ed è così che NORA, pezzo dopo pezzo, torna sé stessa.",
    unlock: { kind: "room", room: "MasteryScene", roomLabel: "Albero delle Competenze" },
  },
  {
    id: "frag-10-eco-imita",
    index: 10,
    title: "Il Guardiano che Imita",
    glyph: "🪞",
    story: "Il Guardiano sfida proprio con i settori perché usa ogni sistema della nave come serratura. Ogni risposta sicura che dai apre un varco — e abbassa un allarme.",
    unlock: { kind: "auto", condition: "Indebolisci il Guardiano 2 volte", test: (s) => ecoDefeats(s) >= 2 },
  },
  {
    id: "frag-11-chiave-umana",
    index: 11,
    title: "La Chiave Umana",
    glyph: "🗝",
    story: "I Primi lasciarono un avvertimento: nessuna macchina può riaccendere il Nucleo da sola. Serve qualcuno che capisca davvero, da solo, senza aiuti. La padronanza autonoma è la vera chiave.",
    unlock: { kind: "room", room: "MathStudyScene", roomLabel: "Atlante (Studio)" },
  },
  {
    id: "frag-12-verita",
    index: 12,
    title: "La Verità",
    glyph: "🌟",
    story: "Alla fine si scopre il segreto più grande: il Guardiano non era un nemico. Era una promessa rimasta sola troppo a lungo. Bastava affrontarlo con pazienza per ricordargli chi doveva proteggere.",
    unlock: { kind: "auto", condition: "Completa l'arco del Guardiano (5 vittorie)", test: (s) => ecoDefeats(s) >= 5 },
  },
  {
    id: "frag-13-palestra",
    index: 13,
    title: "La Palestra della Mente",
    glyph: "🧠",
    story: "C'era una stanza dove NORA calibrava sé stessa: logica per capire, memoria per non dimenticare. Quando il Blackout la spense, il Guardiano prese quelle prove e le trasformò in protocolli. Calibrandoti qui riprendi ciò che è suo — ed è per questo che nella Sfida del Guardiano ritrovi le stesse prove di mente.",
    unlock: { kind: "room", room: "LogicGymScene", roomLabel: "Palestra della Mente" },
  },
];

export class CollectionSystem {
  private discoveredSet(): Set<string> {
    return new Set(saveSystem.data.collection?.discovered ?? []);
  }

  private persist(discovered: Set<string>): void {
    saveSystem.data.collection = { discovered: Array.from(discovered) };
    saveSystem.persistData();
  }

  /** Auto-unlock milestone fragments whose condition now holds. */
  private refreshAuto(): boolean {
    const discovered = this.discoveredSet();
    let changed = false;
    FRAGMENTS.forEach((fragment) => {
      if (fragment.unlock.kind === "auto" && !discovered.has(fragment.id) && fragment.unlock.test(saveSystem.data)) {
        discovered.add(fragment.id);
        changed = true;
      }
    });
    if (changed) {
      this.persist(discovered);
    }
    return changed;
  }

  total(): number {
    return FRAGMENTS.length;
  }

  discoveredCount(): number {
    this.refreshAuto();
    return this.discoveredSet().size;
  }

  getAll(): FragmentView[] {
    this.refreshAuto();
    const discovered = this.discoveredSet();
    return FRAGMENTS.map((fragment) => ({
      ...fragment,
      discovered: discovered.has(fragment.id),
      hint: fragment.unlock.kind === "room"
        ? `Cerca un'anomalia nascosta in: ${fragment.unlock.roomLabel}`
        : `Si svela da sé: ${fragment.unlock.condition}`,
    }));
  }

  /** Returns the fragment hidden in this room if it was newly discovered. */
  discoverRoom(sceneKey: string): MemoryFragment | undefined {
    const fragment = FRAGMENTS.find((f) => f.unlock.kind === "room" && f.unlock.room === sceneKey);
    if (!fragment) {
      return undefined;
    }
    const discovered = this.discoveredSet();
    if (discovered.has(fragment.id)) {
      return undefined;
    }
    discovered.add(fragment.id);
    this.persist(discovered);
    return fragment;
  }

  /** True if this room still hides an undiscovered fragment. */
  roomHasSecret(sceneKey: string): boolean {
    const fragment = FRAGMENTS.find((f) => f.unlock.kind === "room" && f.unlock.room === sceneKey);
    return !!fragment && !this.discoveredSet().has(fragment.id);
  }
}

export const collectionSystem = new CollectionSystem();
