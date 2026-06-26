import { competencies as competencyDefs } from "../data/competencies";
import { saveSystem } from "./SaveSystem";

export type MasteryTier = 0 | 1 | 2 | 3;

export type MasteryNode = {
  id: string;
  label: string;
  score: number;
};

export type MasteryBranch = {
  id: string;
  label: string;
  color: number;
  score: number;
  autonomy: number;
  tier: MasteryTier;
  tierLabel: string;
  nodes: MasteryNode[];
  nextUnlock: string;
};

type BranchDef = { id: string; label: string; color: number; prefixes: string[]; exact?: string[] };

const TIER_LABELS = ["Novizio", "Apprendista", "Esperto", "Maestro"] as const;

// The 7 study branches + a transversal one. Each maps to competency ids.
const BRANCHES: BranchDef[] = [
  { id: "matematica", label: "Matematica", color: 0x6be7d6, prefixes: ["matematica."] },
  { id: "italiano", label: "Italiano", color: 0x9f8cff, prefixes: ["italiano."] },
  { id: "inglese", label: "Inglese", color: 0xf6c85f, prefixes: ["inglese."] },
  { id: "elettronica", label: "Circuiti", color: 0xff8f6b, prefixes: ["elettronica."] },
  { id: "coding", label: "Coding", color: 0x70d68a, prefixes: ["coding."] },
  { id: "musica", label: "Musica", color: 0xff9ad2, prefixes: ["musica."] },
  { id: "scienze", label: "Scienze", color: 0x8ad0ff, prefixes: ["scienze."] },
  { id: "trasversali", label: "Trasversali", color: 0xf7d37a, prefixes: ["trasversali."], exact: ["problemSolving", "pensieroCritico"] },
];

// Top tiers must be EARNED by autonomous solving (first try, no hints), not by
// exposure alone: high score with low autonomy is capped below "Esperto/Maestro".
function tierFor(score: number, autonomy: number): MasteryTier {
  if (score < 25) return 0;
  if (score < 50) return 1;
  if (score < 75) return autonomy >= 3 ? 2 : 1;
  return autonomy >= 8 ? 3 : autonomy >= 3 ? 2 : 1;
}

export class MasterySystem {
  getBranches(): MasteryBranch[] {
    const scores = saveSystem.data.competencies ?? {};
    const autonomyStore = saveSystem.data.masteryAutonomy ?? {};
    return BRANCHES.map((branch) => {
      const nodes: MasteryNode[] = competencyDefs
        .filter((def) => this.belongs(def.id, branch))
        .map((def) => ({ id: def.id, label: def.label, score: scores[def.id] ?? 0 }));
      const avg = nodes.length > 0 ? Math.round(nodes.reduce((sum, node) => sum + node.score, 0) / nodes.length) : 0;
      const autonomy = autonomyStore[branch.id] ?? 0;
      const tier = tierFor(avg, autonomy);
      return {
        id: branch.id,
        label: branch.label,
        color: branch.color,
        score: avg,
        autonomy,
        tier,
        tierLabel: TIER_LABELS[tier],
        nodes: nodes.sort((a, b) => b.score - a.score),
        nextUnlock: this.nextUnlock(avg, autonomy, tier),
      };
    });
  }

  private belongs(id: string, branch: BranchDef): boolean {
    if (branch.exact?.includes(id)) return true;
    return branch.prefixes.some((prefix) => id.startsWith(prefix));
  }

  private nextUnlock(score: number, autonomy: number, tier: MasteryTier): string {
    if (tier >= 3) return "Massima maestria raggiunta. Mantienila con soluzioni autonome.";
    if (tier === 2) {
      return autonomy >= 8 ? "Porta la media a 75 per diventare Maestro." : `Diventa Maestro: media 75 e ${Math.max(0, 8 - autonomy)} soluzioni autonome in più.`;
    }
    if (tier === 1) {
      if (score < 50) return "Diventa Esperto: porta la media a 50.";
      return `Diventa Esperto: ${Math.max(0, 3 - autonomy)} soluzioni autonome in più.`;
    }
    return "Diventa Apprendista: porta la media a 25.";
  }

  /** Academy rank from the sum of branch tiers (0..24). */
  getAcademyRank(): { title: string; stars: number; maxStars: number } {
    const branches = this.getBranches();
    const total = branches.reduce((sum, branch) => sum + branch.tier, 0);
    const maxStars = branches.length * 3;
    const ratio = total / maxStars;
    const title = ratio >= 0.85 ? "Accademica Leggendaria"
      : ratio >= 0.6 ? "Accademica Esperta"
      : ratio >= 0.35 ? "Cadetta Avanzata"
      : ratio >= 0.1 ? "Cadetta"
      : "Recluta";
    return { title, stars: total, maxStars };
  }

  branchForPuzzleKind(kind: string): string {
    if (kind === "math") return "matematica";
    if (kind === "language") return "italiano";
    if (kind === "english") return "inglese";
    if (kind === "circuit") return "elettronica";
    if (kind === "coding" || kind === "robot") return "coding";
    if (kind === "music") return "musica";
    return "scienze";
  }
}

export const masterySystem = new MasterySystem();
