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

const wingsRestored = (save: SaveData): number => (save.completedMissionIds ?? []).length;
const ecoDefeats = (save: SaveData): number => save.eco?.defeats ?? 0;

/**
 * Pillar 5 — Discovery & collection. A 12-part backstory of the Academy, NORA
 * and the Eco, told through "memory fragments". Six are hidden as clickable
 * anomalies inside calm rooms (reward exploration); six unlock automatically as
 * the player progresses (guarantee the story is told even without finding every
 * secret).
 */
const FRAGMENTS: MemoryFragment[] = [
  {
    id: "frag-01-fondazione",
    index: 1,
    title: "La Fondazione",
    glyph: "🏛",
    story: "L'Accademia delle Missioni non nacque per dare voti, ma per formare chi un giorno avrebbe riparato il mondo. Quattro ali, quattro modi di pensare: costruire, curare, calcolare, ricordare.",
    unlock: { kind: "room", room: "MainMenuScene", roomLabel: "Atrio (Menu)" },
  },
  {
    id: "frag-02-nora-accesa",
    index: 2,
    title: "NORA si accende",
    glyph: "🔵",
    story: "La prima volta che NORA aprì gli occhi digitali, fece una domanda invece di dare una risposta: «Perché?». I fondatori capirono di aver creato non un manuale, ma una mente curiosa come quella di una bambina.",
    unlock: { kind: "room", room: "NoraScene", roomLabel: "Sala di NORA" },
  },
  {
    id: "frag-03-reattore",
    index: 3,
    title: "Il Reattore di Sapere",
    glyph: "⚛",
    story: "Nel cuore dell'Accademia batte il Nucleo: non si alimenta a corrente, ma a comprensione. Ogni concetto davvero capito da uno studente lo rende più luminoso.",
    unlock: { kind: "room", room: "AcademyScene", roomLabel: "La tua Accademia" },
  },
  {
    id: "frag-04-sovraccarico",
    index: 4,
    title: "Il Sovraccarico",
    glyph: "⚡",
    story: "Arrivarono troppe domande, tutte insieme, senza nessuno a fare ordine. NORA cercò di rispondere a tutto da sola. Il Nucleo si surriscaldò.",
    unlock: { kind: "auto", condition: "Ripristina almeno 1 ala", test: (s) => wingsRestored(s) >= 1 },
  },
  {
    id: "frag-05-blackout",
    index: 5,
    title: "Il Blackout",
    glyph: "🌑",
    story: "Poi, una notte, tutto si spense. Le luci, le macchine, persino la voce di NORA. L'Accademia piombò nel buio e nel silenzio. Il giorno dopo, qualcuno doveva riaccendere tutto: tu.",
    unlock: { kind: "room", room: "CampaignScene", roomLabel: "Mappa della Storia" },
  },
  {
    id: "frag-06-frattura",
    index: 6,
    title: "La Frattura",
    glyph: "💔",
    story: "Quando NORA si spense, una parte di lei non volle arrendersi e si staccò: la paura di non sapere, diventata indipendente. Così nacque l'Eco.",
    unlock: { kind: "auto", condition: "Affronta l'Eco almeno una volta con successo", test: (s) => ecoDefeats(s) >= 1 },
  },
  {
    id: "frag-07-ali-sigillate",
    index: 7,
    title: "Le Ali Sigillate",
    glyph: "🔒",
    story: "Laboratorio, Serra, Fabbrica, Archivio: ogni ala si chiuse con i suoi segreti dentro. Riaprirle non basta forzarle — bisogna capire ciò che custodiscono.",
    unlock: { kind: "auto", condition: "Ripristina almeno 2 ali", test: (s) => wingsRestored(s) >= 2 },
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
    story: "Con la Frattura, i ricordi di NORA si dispersero come scintille in ogni stanza. Chi esplora con curiosità li ritrova — ed è così che NORA, pezzo dopo pezzo, torna sé stessa.",
    unlock: { kind: "room", room: "MasteryScene", roomLabel: "Albero delle Competenze" },
  },
  {
    id: "frag-10-eco-imita",
    index: 10,
    title: "L'Eco che Imita",
    glyph: "🪞",
    story: "L'Eco sfida proprio con le materie perché è fatta dei dubbi di NORA su ciascuna di esse. Ogni risposta sicura che dai le toglie un dubbio — e un po' di potere.",
    unlock: { kind: "auto", condition: "Indebolisci l'Eco 2 volte", test: (s) => ecoDefeats(s) >= 2 },
  },
  {
    id: "frag-11-chiave-umana",
    index: 11,
    title: "La Chiave Umana",
    glyph: "🗝",
    story: "I fondatori lasciarono un avvertimento: nessuna macchina può riaccendere il Nucleo da sola. Serve qualcuno che capisca davvero, da solo, senza aiuti. La padronanza autonoma è la vera chiave.",
    unlock: { kind: "room", room: "MathStudyScene", roomLabel: "Atlante (Studio)" },
  },
  {
    id: "frag-12-verita",
    index: 12,
    title: "La Verità",
    glyph: "🌟",
    story: "Alla fine si scopre il segreto più grande: l'Eco non era un nemico. Era NORA spaventata dal non sapere. Bastava affrontarla con pazienza per farla tornare a casa.",
    unlock: { kind: "auto", condition: "Completa l'arco dell'Eco (5 vittorie)", test: (s) => ecoDefeats(s) >= 5 },
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
