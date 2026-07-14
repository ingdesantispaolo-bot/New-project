import { missions } from "../data/missions";
import { isMissionComplete, isMissionExplored } from "./MissionCompletion";
import { missionEngine } from "./MissionEngine";
import { playerSystem } from "./PlayerSystem";

const SEEN_KEY = "eliQuest.campaignSeenCompleted";

export type ChapterStatus = "complete" | "active" | "locked";

export type CampaignChapter = {
  number: number;
  /** 1 = main story (Atti I-IV), 2 = "Stagione 2" (Atti V-VI) unlocked after the Season 1 finale. */
  season: number;
  missionId: string;
  sceneKey: string;
  title: string;
  location: string;
  /** Where this chapter sits in the overarching plot. */
  synopsis: string;
  /** Narrative card shown when entering the chapter. */
  intro: string;
  /** Narrative card shown when the chapter is completed. */
  outro: string;
  status: ChapterStatus;
};

export type CampaignDay = {
  index: number;
  label: string;
  task: string;
  status: ChapterStatus;
};

type ChapterDefinition = Omit<CampaignChapter, "status">;

// --- The frame story (authored) ---------------------------------------------

const SYNOPSIS = [
  "Sotto l'Accademia dorme il Relitto dei Primi.",
  "Una notte il Blackout ha raggiunto lo scafo sepolto, ha messo a tacere NORA — la mente della nave — e ha sigillato i suoi ponti.",
  "Eli è l'unica rimasta sveglia quando il pavimento ha cominciato a vibrare. NORA, ridotta a un filo di voce, le affida una missione: riaccendere energia, vita, memoria e rotta della nave.",
  "Ma più Eli ripara, più capisce una cosa: il Relitto non è una rovina morta. Qualcosa lo protegge ancora.",
].join(" ");

const CHAPTERS: ChapterDefinition[] = [
  {
    number: 1,
    season: 1,
    missionId: "mission-01-laboratorio-spento",
    sceneKey: "LaboratoryScene",
    title: "Il Ponte Centrale",
    location: "Nucleo Nave",
    synopsis: "Tutto comincia al buio: senza energia NORA non ha voce.",
    intro: "Capitolo 1 — Il Ponte Centrale.\n\nLe luci sono morte sotto l'Accademia. NORA sussurra dal nucleo quasi scarico: «Eli… riporta corrente, segnale e movimento nel Relitto. Senza energia non posso nemmeno parlarti.» Tocca a te riaccendere il primo ponte.",
    outro: "Il nucleo ronza di nuovo. La voce di NORA torna più nitida: «Sento lo scafo. Ma un corridoio si è aperto da solo… verso il Bio-ponte. E là dentro qualcosa sta soffocando.»",
  },
  {
    number: 2,
    season: 1,
    missionId: "mission-02-serra-biologica",
    sceneKey: "GreenhouseScene",
    title: "Il Bio-ponte",
    location: "Ponte Vita",
    synopsis: "Con l'energia torna il respiro: ma il giardino dei Primi sta soffocando.",
    intro: "Capitolo 2 — Il Bio-ponte.\n\nL'energia ha risvegliato il giardino sospeso della nave, e ha mostrato un disastro: tre organismi stanno cedendo per cause diverse. NORA: «Non curarli a caso, Eli. Leggi i dati, regola una variabile alla volta, salva la vita prima che l'aria si guasti.»",
    outro: "Il Bio-ponte respira. Tra i sensori, NORA trova una traccia strana: «Questi blocchi erano… coordinati. Qualcuno conosceva il Relitto dall'interno. Il Reattore si è acceso: andiamo.»",
  },
  {
    number: 3,
    season: 1,
    missionId: "mission-03-fabbrica-numeri",
    sceneKey: "NumberFactoryScene",
    title: "Il Reattore",
    location: "Cuore Energia",
    synopsis: "La memoria di NORA ha bisogno di nuclei energetici esatti.",
    intro: "Capitolo 3 — Il Reattore.\n\nPer ricostruire i suoi ricordi NORA ha bisogno di nuclei energetici perfetti, ma il cuore-nave produce valori sbagliati. «Rimetti in ordine la catena dei condotti, Eli: ogni nucleo deve raggiungere il valore giusto, senza sprechi.»",
    outro: "I nuclei tornano esatti e la memoria di NORA si ricarica. Ma con i ricordi torna anche una domanda: «C'è un ponte che non ho mai osato riaprire. Il Data-core. È lì che è cominciato tutto.»",
  },
  {
    number: 4,
    season: 1,
    missionId: "mission-04-archivio-parole",
    sceneKey: "WordArchiveScene",
    title: "Il Data-core",
    location: "Ponte Memoria",
    synopsis: "Il Data-core custodisce la verità sul Blackout.",
    intro: "Capitolo 4 — Il Data-core.\n\nI registri che spiegano il Blackout sono corrotti: aprono archivi sbagliati e cancellano le fonti. NORA: «Ripara i messaggi, scegli gli indizi veri e scrivimi un rapporto verificabile. Solo così potrò riaccendermi del tutto… e ricordare chi mi ha spenta.»",
    outro: "Il rapporto è chiaro, le fonti sono salde. NORA torna viva al cento per cento e, per la prima volta, ti chiama per nome con orgoglio: «Caso chiuso, agente Eli. Il Relitto è di nuovo con noi.»",
  },
  {
    number: 5,
    season: 2,
    missionId: "mission-05-atlante-perduto",
    sceneKey: "AtlasScene",
    title: "Il Ponte di Comando",
    location: "Carte dei Primi",
    synopsis: "Il caso era chiuso. Poi è arrivato un segnale da fuori rotta.",
    intro: "Stagione 2, Capitolo 5 — Il Ponte di Comando.\n\nDue settimane dopo, NORA ti sveglia nel cuore della notte: «Eli, intercetto un segnale che ripete il codice del Blackout. Ma non viene da dentro: viene da fuori. Qualcuno ci osservava. Sul Ponte di Comando ci sono carte stellari dei Primi: servono a triangolare l'origine. Leggi i rilevamenti, traccia le coordinate, usa la scala. Trova chi ci ha spenti.»",
    outro: "I tre rilevamenti si incrociano su un solo punto della mappa. NORA resta in silenzio un istante: «Il segnale parte da un avamposto che i Primi avevano dimenticato… e tra noi e quel posto c'è la Città. Se ci hanno spenti una volta, possono spegnere lei. Dobbiamo arrivare prima noi.»",
  },
  {
    number: 6,
    season: 2,
    missionId: "mission-06-citta-intelligente",
    sceneKey: "SmartCityScene",
    title: "La Città Intelligente",
    location: "Distretto Urbano",
    synopsis: "Il sabotatore colpisce la città: energia, traffico e servizi vacillano.",
    intro: "Stagione 2, Capitolo 6 — La Città Intelligente.\n\nL'avamposto era una trappola: mentre lo raggiungevi, il sabotatore ha colpito la Città che il Relitto proteggeva in segreto. NORA: «La rete urbana sta cedendo, Eli. Leggi i sensori, imposta le regole giuste, distribuisci l'energia e, quando non basterà per tutti, scegli chi proteggere per primo. La città conta su di te.»",
    outro: "La rete regge, i soccorsi passano, l'acqua scorre. Il segnale del sabotatore si spegne: senza la città da colpire, ha perso. NORA, piano: «Hai imparato la cosa più difficile, Eli: non far funzionare una macchina, ma decidere per le persone. Ora il Relitto non protegge più solo se stesso. Protegge tutti.»",
  },
];

export class CampaignSystem {
  getSynopsis(): string {
    return SYNOPSIS;
  }

  /** True when this chapter's authoritative completion flag is set. */
  isChapterComplete(missionId: string): boolean {
    return isMissionComplete(missionId);
  }

  /** True after the low-pressure chapter exploration has been completed. */
  isChapterExplored(missionId: string): boolean {
    return this.isChapterComplete(missionId) || isMissionExplored(missionId);
  }

  getChapters(): CampaignChapter[] {
    // A chapter is active when it's the first one not yet completed whose
    // predecessor is complete; everything after it stays locked. This makes the
    // Season 1 finale gate the unlock of the "Atto 2" chapters.
    let previousComplete = true;
    return CHAPTERS.map((chapter) => {
      const complete = this.isChapterComplete(chapter.missionId);
      const status: ChapterStatus = complete
        ? "complete"
        : previousComplete
          ? "active"
          : "locked";
      previousComplete = previousComplete && complete;
      return { ...chapter, status };
    });
  }

  getActiveChapter(): CampaignChapter {
    const chapters = this.getChapters();
    return chapters.find((chapter) => chapter.status === "active")
      ?? chapters.find((chapter) => chapter.status !== "complete")
      ?? chapters[chapters.length - 1];
  }

  /** Chapters completed / total — for the "multi-day adventure" progress feel. */
  getProgress(): { completed: number; total: number } {
    const chapters = this.getChapters();
    return { completed: chapters.filter((chapter) => chapter.status === "complete").length, total: chapters.length };
  }

  isCampaignComplete(): boolean {
    return this.getChapters().every((chapter) => chapter.status === "complete");
  }

  /** The chapter's internal "giornate", mapped to mission objectives. */
  getChapterDays(missionId: string): CampaignDay[] {
    const mission = missions.find((entry) => entry.id === missionId);
    if (!mission) {
      return [];
    }
    return mission.objectives.map((objective, index) => ({
      index: index + 1,
      label: `Giornata ${index + 1}`,
      task: objective.label,
      status: missionEngine.getObjectiveStatus(objective),
    }));
  }

  /**
   * Returns the chapter whose outro should play now (a chapter completed since
   * the last visit to the Story), updating the seen counter. Used to show the
   * narrative payoff when the player returns to "La Storia" after a chapter.
   */
  consumePendingOutro(): CampaignChapter | undefined {
    const chapters = this.getChapters();
    const completed = chapters.filter((chapter) => chapter.status === "complete");
    const seen = this.readSeenCount();
    if (completed.length <= seen) {
      // Keep the counter in sync even if it somehow ran ahead (e.g. reset).
      if (completed.length !== seen) {
        this.writeSeenCount(completed.length);
      }
      return undefined;
    }
    this.writeSeenCount(completed.length);
    return completed[completed.length - 1];
  }

  private seenStorageKey(): string {
    return `${SEEN_KEY}:${playerSystem.getActivePlayer().id}`;
  }

  private readSeenCount(): number {
    try {
      const raw = typeof localStorage !== "undefined" ? localStorage.getItem(this.seenStorageKey()) : null;
      const parsed = Number(raw);
      return Number.isFinite(parsed) && parsed >= 0 ? parsed : 0;
    } catch {
      return 0;
    }
  }

  private writeSeenCount(value: number): void {
    try {
      if (typeof localStorage !== "undefined") {
        localStorage.setItem(this.seenStorageKey(), String(value));
      }
    } catch {
      // Best-effort: the outro just won't be suppressed next time.
    }
  }

  /** A short "previously on…" recap based on completed chapters. */
  getRecap(): string {
    const chapters = this.getChapters();
    const done = chapters.filter((chapter) => chapter.status === "complete");
    if (done.length === 0) {
      return "Una nuova storia sta per cominciare: il Relitto dei Primi è al buio e NORA ha bisogno di te.";
    }
    if (done.length >= chapters.length) {
      return "Hai riacceso il Relitto dei Primi e svelato la verità sul Blackout. NORA è di nuovo viva grazie a te.";
    }
    const last = done[done.length - 1];
    const next = this.getActiveChapter();
    return `Finora: hai riportato in vita ${done.length} ${done.length === 1 ? "ponte" : "ponti"} del Relitto (ultimo: ${last.title}). Ora ti aspetta ${next.title} — ${next.location}.`;
  }
}

export const campaignSystem = new CampaignSystem();
