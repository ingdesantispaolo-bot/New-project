import { isMissionComplete } from "./MissionCompletion";
import { masterySystem } from "./MasterySystem";
import { saveSystem } from "./SaveSystem";

export type AcademyWing = {
  id: string;
  label: string;
  system: string;
  missionId: string;
  restored: boolean;
  stability: number;
  color: number;
};

export type AcademyTrophy = {
  id: string;
  label: string;
  kind: "ala" | "maestria" | "esperto";
};

export type AcademyEmblem = {
  id: string;
  label: string;
  glyph: string;
  unlocked: boolean;
};

type WingDef = { id: string; label: string; system: string; missionId: string; branches: string[]; color: number };

const WINGS: WingDef[] = [
  { id: "energia", label: "Ala Energia", system: "Laboratorio", missionId: "mission-01-laboratorio-spento", branches: ["elettronica", "coding"], color: 0x6be7d6 },
  { id: "vita", label: "Ala Vita", system: "Serra", missionId: "mission-02-serra-biologica", branches: ["scienze"], color: 0x70d68a },
  { id: "produzione", label: "Ala Produzione", system: "Fabbrica", missionId: "mission-03-fabbrica-numeri", branches: ["matematica"], color: 0xf6c85f },
  { id: "memoria", label: "Ala Memoria", system: "Archivio", missionId: "mission-04-archivio-parole", branches: ["italiano", "inglese"], color: 0x9f8cff },
];

const EMBLEMS: Array<{ id: string; label: string; glyph: string; stars: number }> = [
  { id: "scintilla", label: "Scintilla", glyph: "✦", stars: 0 },
  { id: "ingranaggio", label: "Ingranaggio", glyph: "⚙", stars: 6 },
  { id: "foglia", label: "Foglia", glyph: "❀", stars: 10 },
  { id: "stella", label: "Stella", glyph: "★", stars: 16 },
  { id: "corona", label: "Corona", glyph: "♛", stars: 22 },
];

export class AcademySystem {
  getName(): string {
    return saveSystem.data.academy?.name?.trim() || "Accademia delle Missioni";
  }

  setName(name: string): void {
    const clean = name.trim().slice(0, 28);
    saveSystem.data.academy = { ...(saveSystem.data.academy ?? {}), name: clean };
    saveSystem.persistData();
  }

  getEmblem(): AcademyEmblem {
    const id = saveSystem.data.academy?.emblem ?? "scintilla";
    const found = EMBLEMS.find((emblem) => emblem.id === id) ?? EMBLEMS[0];
    return { id: found.id, label: found.label, glyph: found.glyph, unlocked: true };
  }

  setEmblem(id: string): void {
    if (!this.getEmblems().some((emblem) => emblem.id === id && emblem.unlocked)) {
      return;
    }
    saveSystem.data.academy = { ...(saveSystem.data.academy ?? {}), emblem: id };
    saveSystem.persistData();
  }

  getEmblems(): AcademyEmblem[] {
    const stars = masterySystem.getAcademyRank().stars;
    return EMBLEMS.map((emblem) => ({ id: emblem.id, label: emblem.label, glyph: emblem.glyph, unlocked: stars >= emblem.stars }));
  }

  getWings(): AcademyWing[] {
    const branches = masterySystem.getBranches();
    const scoreOf = (id: string): number => branches.find((branch) => branch.id === id)?.score ?? 0;
    return WINGS.map((wing) => {
      const stability = wing.branches.length > 0
        ? Math.round(wing.branches.reduce((sum, id) => sum + scoreOf(id), 0) / wing.branches.length)
        : 0;
      return {
        id: wing.id,
        label: wing.label,
        system: wing.system,
        missionId: wing.missionId,
        restored: isMissionComplete(wing.missionId),
        stability,
        color: wing.color,
      };
    });
  }

  /** NORA's Core grows with the academy rank (1..7). */
  getCore(): { level: number; maxLevel: number; brightness: number } {
    const rank = masterySystem.getAcademyRank();
    const brightness = rank.stars / Math.max(1, rank.maxStars);
    return { level: 1 + Math.floor((rank.stars / Math.max(1, rank.maxStars)) * 6), maxLevel: 7, brightness };
  }

  getTrophies(): AcademyTrophy[] {
    const trophies: AcademyTrophy[] = [];
    this.getWings().forEach((wing) => {
      if (wing.restored) {
        trophies.push({ id: `ala-${wing.id}`, label: `${wing.label} ripristinata`, kind: "ala" });
      }
    });
    masterySystem.getBranches().forEach((branch) => {
      if (branch.tier >= 3) {
        trophies.push({ id: `maestria-${branch.id}`, label: `Maestria: ${branch.label}`, kind: "maestria" });
      } else if (branch.tier === 2) {
        trophies.push({ id: `esperto-${branch.id}`, label: `Esperta: ${branch.label}`, kind: "esperto" });
      }
    });
    return trophies;
  }

  getNextGoal(): string {
    const wings = this.getWings();
    const sealed = wings.find((wing) => !wing.restored);
    if (sealed) {
      return `Ripristina la ${sealed.label} completando il capitolo ${sealed.system} nella Storia.`;
    }
    const branches = masterySystem.getBranches();
    const notMaster = branches.filter((branch) => branch.tier < 3).sort((a, b) => b.score - a.score)[0];
    if (notMaster) {
      return `Tutte le ali sono attive! Ora punta alla Maestria in ${notMaster.label}.`;
    }
    return "Hai ripristinato e portato alla maestria tutta l'Accademia. Sei leggendaria.";
  }
}

export const academySystem = new AcademySystem();
