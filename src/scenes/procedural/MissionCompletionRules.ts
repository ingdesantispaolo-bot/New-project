import type { ProceduralRunMode, ProceduralRunSave } from "../../procedural/ProceduralTypes";

type GhostChallenge = NonNullable<ProceduralRunSave["ghost"]>;

export interface StandardCompletionCopy {
  outcomeLabel: string;
  feedback: string;
  restartDelayMs: number;
}

export function doorMissingFeedback(missingLabels: string[]): string {
  return `La porta resta in attesa: manca ancora ${missingLabels.join(", ")}.`;
}

export function chapterExploreCompletionFeedback(energySummary: string): string {
  return `Fase Esplora completata: hai visto il metodo senza pressione. ${energySummary}. Ora la Prova del Capitolo è disponibile nella Storia.`;
}

export function chapterTrialCompletionFeedback(energySummary: string): string {
  return `Sabotatore respinto! Hai disattivato ogni nodo prima che il tempo scadesse. ${energySummary}. Capitolo sbloccato!`;
}

export function ghostVerdict(scoreTotal: number, ghost?: GhostChallenge): string {
  if (!ghost) {
    return "";
  }
  return scoreTotal > ghost.targetScore
    ? ` ⚔ Sfida fantasma vinta: ${scoreTotal} punti contro i ${ghost.targetScore} di ${ghost.playerName}!`
    : ` ⚔ Sfida fantasma: ${scoreTotal} punti, il record di ${ghost.playerName} (${ghost.targetScore}) resiste. Stesso seed, puoi ritentare dalla classifica.`;
}

export function ghostNoraLine(scoreTotal: number, ghost: GhostChallenge): string {
  return scoreTotal > ghost.targetScore
    ? `Record superato! ${ghost.playerName} dovrà riprendersi la stanza.`
    : `Il fantasma di ${ghost.playerName} resiste... per ora. La stanza resta lì, identica.`;
}

export function standardCompletionCopy(
  mode: ProceduralRunMode,
  energySummary: string,
  scoreTotal: number,
  ghost?: GhostChallenge,
): StandardCompletionCopy {
  const ghostText = ghostVerdict(scoreTotal, ghost);
  const training = mode === "training";
  return {
    outcomeLabel: training ? "Calibrazione registrata" : "Missione completata",
    feedback: training
      ? `Calibrazione completata. ${energySummary}.${ghostText} Il diario registra voto, miglior tempo e competenze del settore.`
      : `Missione completata. ${energySummary}.${ghostText} Il diario registra seed, competenze, tempo e vite rimaste.`,
    restartDelayMs: training ? 900 : 2600,
  };
}
