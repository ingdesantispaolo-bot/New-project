import { campaignSystem } from "./CampaignSystem";
import { isMissionComplete } from "./MissionCompletion";
import { masterySystem } from "./MasterySystem";
import { saveSystem } from "./SaveSystem";

export type NoraTone = "curiosa" | "coraggiosa" | "gentile";

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

const TONE_LABELS: Record<NoraTone, string> = {
  curiosa: "curiosa",
  coraggiosa: "coraggiosa",
  gentile: "gentile",
};

// NORA's personal subplot: fragments of her memory, recovered as the player
// progresses, that reveal the truth about the Blackout (the Archive is where
// she becomes whole again).
type MemoryDef = { id: string; title: string; text: string; unlock: () => boolean };

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

export class NoraCompanion {
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
      return ["È la prima volta che ci alleniamo davvero insieme. Sono curiosa di vedere dove arriverai."];
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

  /** Short greeting for the menu (no snapshot commit). */
  greetingShort(playerName: string): string {
    const bond = this.bond();
    const recovered = this.memories().filter((memory) => memory.unlocked).length;
    const total = this.memories().length;
    return `Bentornata, ${playerName}. ${bond.title}. Ho recuperato ${recovered}/${total} dei miei ricordi.`;
  }
}

export const noraCompanion = new NoraCompanion();
