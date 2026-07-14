/**
 * StorySystem — "Il Relitto dei Primi".
 *
 * Sorgente unica dello stato narrativo v2: il Diario di Bordo (testo rivelato in
 * modo progressivo, un ponte alla volta) e le tre scelte maggiori che ramificano
 * il finale. È volutamente AUTONOMO: non tocca SaveSystem/gameTypes (che sono in
 * lavorazione) e persiste su una propria chiave localStorage, con fallback in
 * memoria per i test in ambiente node. Nessun import di Phaser: sicuro fuori dal
 * browser.
 */

export type PonteId =
  | "reattore"
  | "bio-ponte"
  | "fabbricatore"
  | "data-core"
  | "glifi"
  | "risonanza"
  | "comando"
  | "citta";

export type StoryAct = 1 | 2 | 3;

/** Bivio 1 — a quale sistema mandare la poca energia del reattore per prima. */
export type FirstPowerChoice = "bio" | "data";
/** Bivio 2 — come trattare il Guardiano (l'Eco riconvertita a difesa della nave). */
export type GuardianChoice = "ally" | "hostile";
/** Bivio 3 — la Scelta della Chiave: come finisce la storia. */
export type EndingChoice = "silence" | "fire" | "wonder";

export type StoryChoices = {
  firstPower?: FirstPowerChoice;
  guardian?: GuardianChoice;
  ending?: EndingChoice;
};

export type StoryState = {
  choices: StoryChoices;
  /** Ponti completati (id), sorgente di verità per lo sblocco del Diario. */
  pontiComplete: string[];
};

export type DiarioKind = "passato" | "presente";

export type DiarioFragment = {
  id: string;
  act: StoryAct;
  /** Ponte che, completato, sblocca il frammento. Assente = sempre disponibile. */
  ponte?: PonteId;
  kind: DiarioKind;
  title: string;
  text: string;
  /** Sblocco condizionato da una scelta (es. frammento extra se firstPower="data"). */
  requires?: (state: StoryState) => boolean;
};

export type DiarioView = DiarioFragment & { unlocked: boolean; hint: string };

/** Soglie del finale "La Meraviglia" (la via vera). */
export const WONDER_MASTERY_REQUIRED = 4;
export const WONDER_DIARIO_REQUIRED = 8;

// --- Il Diario di Bordo: il canone v2, rivelato ponte per ponte -------------
const FRAGMENTS: DiarioFragment[] = [
  {
    id: "atto1-reattore-presente",
    act: 1,
    ponte: "reattore",
    kind: "presente",
    title: "Un piede di porco nel buio",
    text: "Il reattore non si era spento da solo: è stato forzato dall'alto, di corsa, come chi scava senza sapere cosa tocca. «Qualcuno ci ha svegliati con la forza», mormora NORA. «E non era un archeologo gentile.»",
  },
  {
    id: "atto1-bio-passato",
    act: 1,
    ponte: "bio-ponte",
    kind: "passato",
    title: "Il giardino sospeso",
    requires: (s) => s.choices.firstPower === "bio",
    text: "Salvando il bio-ponte, Eli trova semi che nessun libro conosce: il giardino con cui i Primi respiravano tra le stelle. Alcune di quelle piante sono di nuovo vive. «Custodiscile», dice NORA. «Sono l'unica cosa gentile che ci hanno lasciato.»",
  },
  {
    id: "atto1-data-presente",
    act: 1,
    ponte: "data-core",
    kind: "presente",
    title: "Una voce di troppo",
    requires: (s) => s.choices.firstPower === "data",
    text: "Riaccendendo prima la memoria, il Data-core intercetta un sussurro dalla superficie prima del previsto: non sono soli. Qualcuno, lassù, sta aspettando che la nave si accenda. E non pronuncia mai la parola «capire».",
  },
  {
    id: "atto1-data-passato",
    act: 1,
    ponte: "data-core",
    kind: "passato",
    title: "Non è caduta: si è sepolta",
    text: "I messaggi riparati rivelano il nome della civiltà — i Primi — e una cosa che gela: la nave non è precipitata. Si è sepolta apposta, spegnendo tutto tranne un sistema di guardia. Qualcosa, laggiù, non ha mai smesso di sorvegliare.",
  },
  {
    id: "atto2-glifi-passato",
    act: 2,
    ponte: "glifi",
    kind: "passato",
    title: "Perché i Primi caddero",
    text: "La lingua dei Primi racconta la loro fine: divennero così sapienti da smettere di stupirsi, pretendendo risposte invece di capirle. La mente delle loro navi si spezzò sotto il peso di troppe domande senza meraviglia. Per questo la nave attese, per millenni, una mente che sapesse ancora meravigliarsi. Per questo attese lei.",
  },
  {
    id: "atto2-risonanza-presente",
    act: 2,
    ponte: "risonanza",
    kind: "presente",
    title: "Il Guardiano si sveglia",
    text: "La risonanza del motore risveglia il sistema di difesa. Non attacca: giudica. «Un'altra mano che tocca la nave», dice con la voce di NORA, ma più dura. «Dimostrami che vuoi capire, non rubare — o ti chiudo fuori per sempre.»",
  },
  {
    id: "atto2-risonanza-rivale",
    act: 2,
    ponte: "risonanza",
    kind: "presente",
    title: "La voce dall'alto",
    text: "Un messaggio filtra dalla superficie: «Estrarre. Spegnere le difese. Prima che la ragazzina arrivi al ponte di comando.» Il rivale non vuole capire la nave. La vuole smontare.",
  },
  {
    id: "atto3-comando-presente",
    act: 3,
    ponte: "comando",
    kind: "presente",
    title: "Chi è la Mano",
    text: "Le carte stellari rivelano che il relitto era già stato trovato una volta, di recente, e richiuso in fretta da chi non riuscì a farlo funzionare. Il rivale non è un estraneo: conosce l'Accademia dall'interno, e ha aspettato che fosse una mente-Chiave a fare il lavoro sporco.",
  },
  {
    id: "atto3-comando-passato",
    act: 3,
    ponte: "comando",
    kind: "passato",
    title: "La rotta sepolta",
    text: "Sul ponte di comando si accende un cielo vecchio di millenni. Eli legge da dove venne la nave — e dove, se lo volesse, potrebbe tornare. Per un istante tiene in mano il volante di una civiltà intera.",
  },
  {
    id: "atto3-finale-silence",
    act: 3,
    ponte: "citta",
    kind: "presente",
    title: "Finale · Il Silenzio",
    requires: (s) => s.choices.ending === "silence",
    text: "Eli richiude la nave e la protegge dal rivale. Sicuro, saggio. Ma nel buio ritrovato resta il pensiero di tutto ciò che non ha svegliato — e la promessa di tornare, un giorno, con più risposte.",
  },
  {
    id: "atto3-finale-fire",
    act: 3,
    ponte: "citta",
    kind: "presente",
    title: "Finale · Il Fuoco",
    requires: (s) => s.choices.ending === "fire",
    text: "Eli accende la nave del tutto. Potenza immensa, subito, e la città salva. Ma senza aver capito abbastanza, sente sotto i piedi lo stesso peso che spezzò i Primi. Alcune porte, una volta aperte, non si richiudono.",
  },
  {
    id: "atto3-finale-wonder",
    act: 3,
    ponte: "citta",
    kind: "presente",
    title: "Finale · La Meraviglia",
    requires: (s) => s.choices.ending === "wonder",
    text: "NORA e il Guardiano tornano una mente sola, e la nave si affida a Eli. Non padrona: custode. Il rivale resta a mani vuote davanti a una cosa che non si può rubare — solo capire. «Non eravamo l'unica nave», sussurra NORA. «Ma sei la prima Chiave che sceglie di aspettare.»",
  },
];

class StorySystem {
  private playerIdProvider: () => string = () => "default";
  private mem: Record<string, string> = {};

  /** Wire the active player so the Diario is per-profile. Safe to call late. */
  setPlayerIdProvider(fn: () => string): void {
    this.playerIdProvider = fn;
  }

  private storageKey(): string {
    return `eliQuest.story:${this.playerIdProvider()}`;
  }

  private empty(): StoryState {
    return { choices: {}, pontiComplete: [] };
  }

  /** Reads persisted state (localStorage in-browser, in-memory in tests/node). */
  state(): StoryState {
    let raw: string | null = null;
    try {
      raw = typeof localStorage !== "undefined" ? localStorage.getItem(this.storageKey()) : this.mem[this.storageKey()] ?? null;
    } catch {
      raw = this.mem[this.storageKey()] ?? null;
    }
    if (!raw) return this.empty();
    try {
      const parsed = JSON.parse(raw) as Partial<StoryState>;
      return {
        choices: parsed.choices ?? {},
        pontiComplete: Array.isArray(parsed.pontiComplete) ? parsed.pontiComplete : [],
      };
    } catch {
      return this.empty();
    }
  }

  private persist(state: StoryState): void {
    const raw = JSON.stringify(state);
    try {
      if (typeof localStorage !== "undefined") {
        localStorage.setItem(this.storageKey(), raw);
        return;
      }
    } catch {
      // fall through to in-memory
    }
    this.mem[this.storageKey()] = raw;
  }

  private isUnlocked(fragment: DiarioFragment, state: StoryState): boolean {
    if (fragment.ponte && !state.pontiComplete.includes(fragment.ponte)) return false;
    if (fragment.requires && !fragment.requires(state)) return false;
    return true;
  }

  /** All fragments with their unlocked flag, in canonical (reading) order. */
  diario(): DiarioView[] {
    const state = this.state();
    return FRAGMENTS.map((fragment) => ({
      ...fragment,
      unlocked: this.isUnlocked(fragment, state),
      hint: fragment.ponte ? `Si svela riattivando: ${ponteLabel(fragment.ponte)}` : "Sempre disponibile",
    }));
  }

  unlockedFragments(): DiarioFragment[] {
    const state = this.state();
    return FRAGMENTS.filter((fragment) => this.isUnlocked(fragment, state));
  }

  discoveredCount(): number {
    return this.unlockedFragments().length;
  }

  total(): number {
    return FRAGMENTS.length;
  }

  /**
   * Marks a ponte as reactivated and returns the fragments unlocked *by this
   * action* (for a "nuovo frammento nel Diario" toast). Idempotent.
   */
  recordPonteComplete(ponte: PonteId): DiarioFragment[] {
    const before = new Set(this.unlockedFragments().map((fragment) => fragment.id));
    const state = this.state();
    if (!state.pontiComplete.includes(ponte)) {
      state.pontiComplete = [...state.pontiComplete, ponte];
      this.persist(state);
    }
    return this.unlockedFragments().filter((fragment) => !before.has(fragment.id));
  }

  choices(): StoryChoices {
    return this.state().choices;
  }

  private setChoice<K extends keyof StoryChoices>(key: K, value: StoryChoices[K]): DiarioFragment[] {
    const before = new Set(this.unlockedFragments().map((fragment) => fragment.id));
    const state = this.state();
    state.choices = { ...state.choices, [key]: value };
    this.persist(state);
    return this.unlockedFragments().filter((fragment) => !before.has(fragment.id));
  }

  chooseFirstPower(choice: FirstPowerChoice): DiarioFragment[] {
    return this.setChoice("firstPower", choice);
  }

  chooseGuardian(choice: GuardianChoice): DiarioFragment[] {
    return this.setChoice("guardian", choice);
  }

  chooseEnding(choice: EndingChoice): DiarioFragment[] {
    return this.setChoice("ending", choice);
  }

  /** Is the Guardian an ally (opens the command bridge, helps in the finale)? */
  guardianIsAlly(): boolean {
    return this.state().choices.guardian === "ally";
  }

  /**
   * The "Meraviglia" ending is the true path: it requires the Guardian as an
   * ally, enough mastered subjects, and a substantially recovered Diario.
   */
  canChooseWonder(context: { masteredSubjects: number }): boolean {
    return (
      this.guardianIsAlly()
      && context.masteredSubjects >= WONDER_MASTERY_REQUIRED
      && this.discoveredCount() >= WONDER_DIARIO_REQUIRED
    );
  }

  /** Which endings the player may currently pick. */
  availableEndings(context: { masteredSubjects: number }): EndingChoice[] {
    const endings: EndingChoice[] = ["silence", "fire"];
    if (this.canChooseWonder(context)) endings.push("wonder");
    return endings;
  }

  /** Full reset (a new game / profile wipe). */
  reset(): void {
    this.persist(this.empty());
  }
}

const PONTE_LABELS: Record<PonteId, string> = {
  reattore: "il Reattore",
  "bio-ponte": "il Bio-ponte",
  fabbricatore: "il Fabbricatore",
  "data-core": "il Data-core",
  glifi: "la Sala dei Glifi",
  risonanza: "il Motore a Risonanza",
  comando: "il Ponte di Comando",
  citta: "la Città",
};

export function ponteLabel(ponte: PonteId): string {
  return PONTE_LABELS[ponte];
}

export const storySystem = new StorySystem();
