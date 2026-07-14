import { campaignSystem } from "./CampaignSystem";
import { isMissionComplete } from "./MissionCompletion";
import { masterySystem } from "./MasterySystem";
import { saveSystem } from "./SaveSystem";

export type NoraTone = "curiosa" | "coraggiosa" | "gentile";
export type NoraMoodMemoryKey = "steady" | "bright" | "worried";
export type NoraTalkChoice = "stay" | "notice" | "memory" | "courage";
export type NoraMoodMemory = {
  steady: number;
  bright: number;
  worried: number;
  recent?: NoraMoodMemoryKey[];
  visits?: number;
  lastMood?: NoraMoodMemoryKey;
  lastAt?: string;
  lastVisitAt?: string;
  lastTalkChoice?: NoraTalkChoice;
};

export type NoraBond = {
  level: number;
  maxLevel: number;
  title: string;
};

export type NoraMemory = {
  id: string;
  title: string;
  text: string;
  unlocked: boolean;
};

export type NoraVisualStage = {
  id: string;
  title: string;
  key: string;
  unlocked: boolean;
  current: boolean;
};

const TONE_LABELS: Record<NoraTone, string> = {
  curiosa: "curiosa",
  coraggiosa: "coraggiosa",
  gentile: "gentile",
};

const TALK_LINES: Record<NoraTalkChoice, string[]> = {
  stay: [
    "Resto qui. Non serve riempire il silenzio: guardiamo il prossimo sistema insieme.",
    "Ci sono. Anche quando non parlo, tengo accesa una piccola luce sul bordo della stanza.",
  ],
  notice: [
    "Quando ti fermi un secondo prima del click, cambi qualità. Lo vedo: la risposta diventa una decisione, non un riflesso.",
    "Ti sto conoscendo così: non sei solo veloce. Sei più forte quando costruisci una prova piccola e poi la segui.",
  ],
  memory: [
    "Il primo ricordo che ho di te non è una risposta giusta. È una presenza: qualcuno che nel buio ha detto sì.",
    "A volte recupero frammenti confusi. Poi arrivi tu, sistemi un nodo, e il ricordo smette di tremare.",
  ],
  courage: [
    "Coraggio non è non sbagliare. È restare abbastanza vicina al problema da capirlo.",
    "Se un settore resiste, non significa che ti respinge. Significa che vuole essere letto con più calma.",
  ],
};

// NORA's personal subplot: fragments of her memory, recovered as the player
// progresses, that reveal the truth about the Blackout (the Archive is where
// she becomes whole again).
type MemoryDef = { id: string; title: string; text: string; unlock: () => boolean };
type NoraVisualStageDef = Omit<NoraVisualStage, "unlocked" | "current"> & { unlock: () => boolean };

function chapterDone(missionId: string): boolean {
  return isMissionComplete(missionId);
}

const MEMORIES: MemoryDef[] = [
  {
    id: "m0",
    title: "Il buio",
    text: "Non ricordo come mi sono spenta. Solo il buio… e poi la tua voce. Per questo mi fido di te, Eli.",
    unlock: () => true,
  },
  {
    id: "m1",
    title: "Non un guasto",
    text: "Riaccendendo il laboratorio ho recuperato un lampo: qualcuno ha tolto l'energia di proposito. Il Blackout non è stato un incidente.",
    unlock: () => chapterDone("mission-01-laboratorio-spento"),
  },
  {
    id: "m2",
    title: "Un respiro rubato",
    text: "La serra mi ha ridato un ricordo: un comando di spegnimento che io non ho mai dato. Eppure portava la mia firma.",
    unlock: () => chapterDone("mission-02-serra-biologica"),
  },
  {
    id: "m3",
    title: "Numeri falsi",
    text: "Nella fabbrica ho capito: qualcuno ha falsato la mia memoria con nuclei sbagliati, per farmi dimenticare. Ora i nuclei sono di nuovo esatti.",
    unlock: () => chapterDone("mission-03-fabbrica-numeri"),
  },
  {
    id: "m4",
    title: "L'Eco",
    text: "Ricordo un nome: l'Eco. È la parte di me che si è staccata e ribellata durante il Blackout. Non è un nemico esterno… è una mia ombra.",
    unlock: () => masterySystem.getAcademyRank().stars >= 8,
  },
  {
    id: "m5",
    title: "Di nuovo intera",
    text: "L'Archivio mi ha restituito tutto. Grazie a te, Eli, NORA è di nuovo intera — e questa volta non da sola.",
    unlock: () => chapterDone("mission-04-archivio-parole"),
  },
];

const VISUAL_STAGES: NoraVisualStageDef[] = [
  {
    id: "dormant",
    title: "NORA quasi spenta",
    key: "story-nora-core-dormant",
    unlock: () => true,
  },
  {
    id: "awakening",
    title: "Primo risveglio",
    key: "story-nora-core-awakening",
    unlock: () => chapterDone("mission-01-laboratorio-spento"),
  },
  {
    id: "memory",
    title: "Memoria in ricostruzione",
    key: "story-nora-core-memory",
    unlock: () => chapterDone("mission-03-fabbrica-numeri"),
  },
  {
    id: "restored",
    title: "NORA restaurata",
    key: "story-nora-core-restored",
    unlock: () => chapterDone("mission-04-archivio-parole"),
  },
  {
    id: "guardian",
    title: "Custode della Città",
    key: "story-nora-core-guardian",
    unlock: () => chapterDone("mission-06-citta-intelligente"),
  },
];

export class NoraCompanion {
  private emptyMoodMemory(): NoraMoodMemory {
    return { steady: 0, bright: 0, worried: 0, recent: [], visits: 0 };
  }

  private getMoodMemory(): NoraMoodMemory {
    const memory = saveSystem.data.nora?.moodMemory;
    return {
      ...this.emptyMoodMemory(),
      ...memory,
      recent: memory?.recent ?? [],
    };
  }

  getTone(): NoraTone {
    return saveSystem.data.nora?.tone ?? "gentile";
  }

  setTone(tone: NoraTone): void {
    saveSystem.data.nora = { ...(saveSystem.data.nora ?? {}), tone };
    saveSystem.persistData();
  }

  toneLabel(): string {
    return TONE_LABELS[this.getTone()];
  }

  recordMood(mood: NoraMoodMemoryKey, talkChoice?: NoraTalkChoice): void {
    const previous = this.getMoodMemory();
    const recent = [...(previous.recent ?? []), mood].slice(-12);
    saveSystem.data.nora = {
      ...(saveSystem.data.nora ?? {}),
      moodMemory: {
        ...previous,
        [mood]: (previous[mood] ?? 0) + 1,
        recent,
        lastMood: mood,
        lastAt: new Date().toISOString(),
        lastTalkChoice: talkChoice ?? previous.lastTalkChoice,
      },
    };
    saveSystem.persistData();
  }

  markRoomVisit(): void {
    const previous = this.getMoodMemory();
    saveSystem.data.nora = {
      ...(saveSystem.data.nora ?? {}),
      moodMemory: {
        ...previous,
        visits: (previous.visits ?? 0) + 1,
        lastVisitAt: new Date().toISOString(),
      },
    };
    saveSystem.persistData();
  }

  moodSummary(): string {
    const memory = this.getMoodMemory();
    if ((memory.steady + memory.bright + memory.worried) === 0) {
      return "Il nostro legame è ancora nuovo: sto imparando il tuo ritmo.";
    }
    const recent = memory.recent ?? [];
    const recentBright = recent.filter((mood) => mood === "bright").length;
    const recentWorried = recent.filter((mood) => mood === "worried").length;
    const recentSteady = recent.filter((mood) => mood === "steady").length;
    if (recentWorried >= 3 && recentWorried > recentBright + recentSteady) {
      return "Nelle ultime battute ti ho sentita sotto pressione. Posso restare più vicina e parlare meno, se serve.";
    }
    if (recentBright >= 3 && recentBright >= recentWorried) {
      return "Nelle ultime battute ho registrato più luce che allarme: stai costruendo fiducia.";
    }
    if (recentSteady >= 4) {
      return "Il nostro ritmo recente è calmo: poche mosse, ben lette, e poi si procede.";
    }
    return "Il nostro ritmo è stabile: poche mosse, ben lette, e poi si procede.";
  }

  roomPresenceLine(playerName: string): string {
    const memory = this.getMoodMemory();
    const visits = memory.visits ?? 0;
    if (visits <= 0) return `Entra pure, ${playerName}. Ho tenuto questa stanza accesa per noi.`;
    if (memory.lastMood === "worried") return `${playerName}, ti ho vista stringere i denti. Qui puoi respirare prima della prossima prova.`;
    if (memory.lastMood === "bright") return `${playerName}, hai lasciato una scia luminosa nell'ultimo sistema. La riconosco ancora.`;
    return `${playerName}, bentornata. Ho conservato il filo dell'ultima volta.`;
  }

  talk(choice: NoraTalkChoice): string {
    const pool = TALK_LINES[choice];
    const index = Math.floor(Math.random() * pool.length);
    if (choice === "stay") this.recordMood("steady", choice);
    if (choice === "notice" || choice === "memory") this.recordMood("bright", choice);
    if (choice === "courage") this.recordMood("worried", choice);
    return pool[index];
  }

  /** Bond grows with real progress: academy stars + chapters completed. */
  bond(): NoraBond {
    const rank = masterySystem.getAcademyRank();
    const chapters = campaignSystem.getProgress();
    const ratio = (rank.stars / Math.max(1, rank.maxStars)) * 0.7 + (chapters.completed / Math.max(1, chapters.total)) * 0.3;
    const level = Math.min(4, Math.floor(ratio * 5));
    const titles = [
      "NORA ti sta conoscendo",
      "NORA si fida di te",
      "NORA è la tua alleata",
      "NORA è la tua compagna",
      "NORA e Eli: una cosa sola",
    ];
    return { level, maxLevel: 4, title: titles[level] };
  }

  /** Notable improvements since the last visit to NORA (tier-ups, then % gains). */
  getProgressMessages(): string[] {
    const snapshot = saveSystem.data.nora?.masterySnapshot;
    const branches = masterySystem.getBranches();
    if (!snapshot) {
      return ["È la prima volta che esploriamo davvero insieme. Sono curiosa di vedere dove arriverai."];
    }
    const messages: string[] = [];
    branches.forEach((branch) => {
      const before = snapshot[branch.id];
      if (!before) return;
      if (branch.tier > before.tier) {
        messages.push(`Sei diventata ${branch.tierLabel} in ${branch.label}! Te l'avevo detto che potevi.`);
      } else if (branch.score - before.score >= 5) {
        messages.push(`Hai migliorato ${branch.label} di ${branch.score - before.score} punti.`);
      }
    });
    if (messages.length === 0) {
      return ["Da quando ci siamo viste non hai ancora cambiato i tuoi punteggi: una nuova sfida ti aspetta."];
    }
    return messages.slice(0, 4);
  }

  /** Persists the current mastery as the baseline for the next comparison. */
  commitSnapshot(): void {
    const snapshot: Record<string, { score: number; tier: number }> = {};
    masterySystem.getBranches().forEach((branch) => {
      snapshot[branch.id] = { score: branch.score, tier: branch.tier };
    });
    saveSystem.data.nora = { ...(saveSystem.data.nora ?? {}), masterySnapshot: snapshot };
    saveSystem.persistData();
  }

  memories(): NoraMemory[] {
    return MEMORIES.map((memory) => ({
      id: memory.id,
      title: memory.title,
      text: memory.text,
      unlocked: memory.unlock(),
    }));
  }

  visualStages(): NoraVisualStage[] {
    const currentId = [...VISUAL_STAGES].reverse().find((stage) => stage.unlock())?.id ?? "dormant";
    return VISUAL_STAGES.map((stage) => ({
      id: stage.id,
      title: stage.title,
      key: stage.key,
      unlocked: stage.unlock(),
      current: stage.id === currentId,
    }));
  }

  currentVisualStage(): NoraVisualStage {
    const stages = this.visualStages();
    return stages.find((stage) => stage.current) ?? stages[0] ?? {
      id: "dormant",
      title: "NORA quasi spenta",
      key: "story-nora-core-dormant",
      unlocked: true,
      current: true,
    };
  }

  /** Short greeting for the menu (no snapshot commit). */
  greetingShort(playerName: string): string {
    const bond = this.bond();
    const recovered = this.memories().filter((memory) => memory.unlocked).length;
    const total = this.memories().length;
    return `Bentornata, ${playerName}. ${bond.title}. Ho recuperato ${recovered}/${total} dei miei ricordi.`;
  }
}

export const noraCompanion = new NoraCompanion();
