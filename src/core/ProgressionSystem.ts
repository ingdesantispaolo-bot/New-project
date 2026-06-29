import { missions } from "../data/missions";
import type { MissionDefinition, ObjectiveStatus } from "../types/missionTypes";
import { difficultyModel } from "../procedural/DifficultyModel";
import { isMissionComplete } from "./MissionCompletion";
import { missionEngine } from "./MissionEngine";
import { saveSystem } from "./SaveSystem";

export type ProgressionChapter = {
  index: number;
  act: string;
  missionId: string;
  title: string;
  domain: string;
  coreQuestion: string;
  unlockText: string;
};

export type MissionProgressSummary = {
  mission: MissionDefinition;
  chapter: ProgressionChapter;
  completedObjectives: number;
  totalObjectives: number;
  percent: number;
  activeObjectiveLabel: string;
  status: "locked" | "active" | "complete";
};

export type AcademyProgression = {
  rankTitle: string;
  rankDescription: string;
  completedMissions: number;
  totalMissions: number;
  active: MissionProgressSummary;
  chapters: MissionProgressSummary[];
  recommendedProceduralDifficulty: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8;
  proceduralDifficultyLabel: string;
  nextUnlock: string;
};

const chapters: ProgressionChapter[] = [
  {
    index: 1,
    act: "Atto I",
    missionId: "mission-01-laboratorio-spento",
    title: "Fondazioni",
    domain: "circuiti, logica, sequenze",
    coreQuestion: "Come capisco un sistema spento senza provare tutto?",
    unlockText: "Sblocca Serra Biologica",
  },
  {
    index: 2,
    act: "Atto II",
    missionId: "mission-02-serra-biologica",
    title: "Sistemi Vivi",
    domain: "dati, grafici, biologia",
    coreQuestion: "Come decido quando tre variabili cambiano insieme?",
    unlockText: "Sblocca Fabbrica dei Numeri",
  },
  {
    index: 3,
    act: "Atto III",
    missionId: "mission-03-fabbrica-numeri",
    title: "Macchine Astratte",
    domain: "operazioni, vincoli, controllo errore",
    coreQuestion: "Come progetto un percorso numerico invece di calcolare a caso?",
    unlockText: "Sblocca Archivio delle Parole",
  },
  {
    index: 4,
    act: "Atto IV",
    missionId: "mission-04-archivio-parole",
    title: "Prove e Linguaggio",
    domain: "testo, fonti, sintesi",
    coreQuestion: "Come distinguo un dettaglio vero da una prova utile?",
    unlockText: "Apre la Stagione 2",
  },
  {
    index: 5,
    act: "Atto V",
    missionId: "mission-05-atlante-perduto",
    title: "Rotte e Coordinate",
    domain: "orientamento, coordinate, scala",
    coreQuestion: "Come trovo un punto incrociando indizi indipendenti?",
    unlockText: "Sblocca Città Intelligente",
  },
  {
    index: 6,
    act: "Atto VI",
    missionId: "mission-06-citta-intelligente",
    title: "Città e Conseguenze",
    domain: "energia, logica condizionale, cittadinanza",
    coreQuestion: "Come scelgo regole quando ogni decisione ha conseguenze?",
    unlockText: "Percorso principale completo",
  },
];

export class ProgressionSystem {
  getProgression(): AcademyProgression {
    const completedMissions = missions.filter((mission) => isMissionComplete(mission.id)).length;
    const activeMission = missionEngine.getActiveMission();
    const chapterSummaries = missions.map((mission) => this.getMissionSummary(mission));
    const active = chapterSummaries.find((summary) => summary.mission.id === activeMission.id) ?? chapterSummaries[0];
    const difficulty = this.recommendedProceduralDifficulty(completedMissions, active.percent);
    return {
      rankTitle: this.rankTitle(completedMissions, active.percent),
      rankDescription: this.rankDescription(completedMissions, active.percent),
      completedMissions,
      totalMissions: missions.length,
      active,
      chapters: chapterSummaries,
      recommendedProceduralDifficulty: difficulty,
      proceduralDifficultyLabel: difficultyModel.describe(difficulty),
      nextUnlock: this.nextUnlock(active),
    };
  }

  getMissionSummary(mission: MissionDefinition): MissionProgressSummary {
    const chapter = chapters.find((candidate) => candidate.missionId === mission.id) ?? {
      index: missions.indexOf(mission) + 1,
      act: "Atto",
      missionId: mission.id,
      title: mission.title,
      domain: mission.competencies.slice(0, 3).join(", "),
      coreQuestion: "Quale sistema va compreso prima di agire?",
      unlockText: mission.nextMissionId ? "Sblocca la missione successiva" : "Percorso principale completo",
    };
    const statuses = mission.objectives.map((objective) => missionEngine.getObjectiveStatus(objective));
    const completedObjectives = statuses.filter((status) => status === "complete").length;
    const activeObjective = mission.objectives.find((objective) => missionEngine.getObjectiveStatus(objective) === "active");
    const complete = isMissionComplete(mission.id);
    const active = mission.id === saveSystem.data.activeMissionId;
    const status: ObjectiveStatus | "complete" = complete ? "complete" : active ? "active" : "locked";
    return {
      mission,
      chapter,
      completedObjectives,
      totalObjectives: mission.objectives.length,
      percent: Math.round((completedObjectives / Math.max(1, mission.objectives.length)) * 100),
      activeObjectiveLabel: activeObjective?.label ?? (complete ? "Missione completata" : "Sigillata"),
      status,
    };
  }

  private recommendedProceduralDifficulty(completedMissions: number, activePercent: number): 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 {
    const missionBase = completedMissions * 2 + 1;
    const pressure = activePercent >= 70 ? 1 : 0;
    return difficultyModel.normalize(missionBase + pressure);
  }

  private rankTitle(completedMissions: number, activePercent: number): string {
    if (completedMissions >= 4) return "Agente di Sistemi Complessi";
    if (completedMissions >= 3) return "Analista dell'Accademia";
    if (completedMissions >= 2) return "Progettista in Addestramento";
    if (completedMissions >= 1) return "Esploratrice Operativa";
    return activePercent > 0 ? "Recluta in Missione" : "Nuova Recluta";
  }

  private rankDescription(completedMissions: number, activePercent: number): string {
    if (completedMissions >= 4) return "Puoi affrontare missioni procedurali con vincoli multipli e pochi indizi.";
    if (completedMissions >= 3) return "Stai collegando calcolo, linguaggio e controllo delle prove.";
    if (completedMissions >= 2) return "Le sfide ora richiedono percorsi, non singole risposte.";
    if (completedMissions >= 1) return "Hai aperto il primo corridoio: ora contano dati e conseguenze.";
    if (activePercent > 0) return "Hai iniziato a leggere sistemi guasti prima di intervenire.";
    return "La prima missione serve a imparare il metodo: osserva, ipotizza, verifica.";
  }

  private nextUnlock(active: MissionProgressSummary): string {
    if (active.status === "complete") {
      return "Scegli una missione procedurale o consulta il diario.";
    }
    return `${active.chapter.unlockText}: completa ${active.totalObjectives - active.completedObjectives} sistemi.`;
  }
}

export const progressionSystem = new ProgressionSystem();
