import { missionEngine } from "./MissionEngine";
import { playerSystem } from "./PlayerSystem";
import { saveSystem } from "./SaveSystem";

const SEEN_KEY = "eliQuest.campaignSeenCompleted";

export type ChapterStatus = "complete" | "active" | "locked";

export type CampaignChapter = {
  number: number;
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
  "L'Accademia delle Missioni si è spenta.",
  "Una notte un guasto a catena — il Blackout — ha messo a tacere NORA, l'intelligenza che tiene viva l'Accademia, e ha sigillato le sue quattro ali.",
  "Eli, giovane cadetta, è l'unica rimasta sveglia quando le luci si sono abbassate. NORA, ridotta a un filo di voce, le affida una missione: riaccendere i quattro sistemi dell'Accademia — energia, vita, produzione e memoria.",
  "Ma più Eli ripara, più capisce una cosa: il Blackout non è stato un guasto. Qualcosa, o qualcuno, voleva spegnere NORA.",
].join(" ");

const CHAPTERS: ChapterDefinition[] = [
  {
    number: 1,
    missionId: "mission-01-laboratorio-spento",
    sceneKey: "LaboratoryScene",
    title: "Il Laboratorio Spento",
    location: "Ala Energia",
    synopsis: "Tutto comincia al buio: senza energia NORA non ha voce.",
    intro: "Capitolo 1 — Il Laboratorio Spento.\n\nLe luci sono morte. NORA sussurra da un nucleo quasi scarico: «Eli… riporta corrente, segnale e movimento in questo laboratorio. Senza di esso non posso nemmeno parlarti.» Tocca a te riaccendere la prima ala.",
    outro: "Il laboratorio ronza di nuovo. La voce di NORA torna più nitida: «Sento di nuovo l'Accademia. Ma un corridoio si è aperto da solo… verso la serra. E là dentro qualcosa sta morendo.»",
  },
  {
    number: 2,
    missionId: "mission-02-serra-biologica",
    sceneKey: "GreenhouseScene",
    title: "La Serra Biologica",
    location: "Ala Vita",
    synopsis: "Con l'energia torna il respiro: ma la serra sta soffocando.",
    intro: "Capitolo 2 — La Serra Biologica.\n\nL'energia ha risvegliato l'ala viva, e ha mostrato un disastro: tre piante stanno appassendo per cause diverse. NORA: «Non curarle a caso, Eli. Leggi i dati, regola una variabile alla volta, salva la vita prima che l'aria si guasti.»",
    outro: "La serra respira. Tra i sensori, NORA trova una traccia strana: «Questi guasti erano… coordinati. Qualcuno conosceva l'Accademia dall'interno. La Fabbrica dei Numeri si è accesa: andiamo.»",
  },
  {
    number: 3,
    missionId: "mission-03-fabbrica-numeri",
    sceneKey: "NumberFactoryScene",
    title: "La Fabbrica dei Numeri",
    location: "Ala Produzione",
    synopsis: "La memoria di NORA ha bisogno di nuclei energetici esatti.",
    intro: "Capitolo 3 — La Fabbrica dei Numeri.\n\nPer ricostruire i suoi ricordi NORA ha bisogno di nuclei perfetti, ma la fabbrica produce numeri sbagliati. «Rimetti in ordine la catena delle macchine, Eli: ogni nucleo deve raggiungere il valore giusto, senza sprechi.»",
    outro: "I nuclei escono perfetti e la memoria di NORA si ricarica. Ma con i ricordi torna anche una domanda: «C'è un'ala che non ho mai osato riaprire. L'Archivio. È lì che è cominciato tutto.»",
  },
  {
    number: 4,
    missionId: "mission-04-archivio-parole",
    sceneKey: "WordArchiveScene",
    title: "L'Archivio delle Parole",
    location: "Ala Memoria",
    synopsis: "L'ultima ala custodisce la verità sul Blackout.",
    intro: "Capitolo 4 — L'Archivio delle Parole.\n\nI messaggi che spiegano il Blackout sono corrotti: aprono cassetti sbagliati e cancellano le fonti. NORA: «Ripara i messaggi, scegli gli indizi veri e scrivimi un rapporto verificabile. Solo così potrò riaccendermi del tutto… e ricordare chi mi ha spenta.»",
    outro: "Il rapporto è chiaro, le fonti sono salde. NORA torna viva al cento per cento e, per la prima volta, ti chiama per nome con orgoglio: «Caso chiuso, agente Eli. L'Accademia è di nuovo nostra.»",
  },
];

export class CampaignSystem {
  getSynopsis(): string {
    return SYNOPSIS;
  }

  getChapters(): CampaignChapter[] {
    const completed = new Set(saveSystem.data.completedMissionIds ?? []);
    const activeId = missionEngine.getActiveMission().id;
    return CHAPTERS.map((chapter) => ({
      ...chapter,
      status: completed.has(chapter.missionId)
        ? "complete"
        : chapter.missionId === activeId
          ? "active"
          : "locked",
    }));
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
    const mission = missionEngine.getMission(missionId);
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
      return "Una nuova storia sta per cominciare: l'Accademia è al buio e NORA ha bisogno di te.";
    }
    if (done.length >= chapters.length) {
      return "Hai riacceso l'intera Accademia e svelato la verità sul Blackout. NORA è di nuovo viva grazie a te.";
    }
    const last = done[done.length - 1];
    const next = this.getActiveChapter();
    return `Finora: hai riportato in vita ${done.length} ${done.length === 1 ? "ala" : "ali"} dell'Accademia (ultima: ${last.title}). Ora ti aspetta ${next.title} — ${next.location}.`;
  }
}

export const campaignSystem = new CampaignSystem();
