export type ArchiveClue = {
  id: string;
  text: string;
  useful: boolean;
};

export type ArchiveRepairCase = {
  corrupted: string;
  repaired: string;
  requiredKeywords: string[];
  clues: ArchiveClue[];
};

export type ArchiveEvaluation = {
  validRepair: boolean;
  selectedUsefulClues: number;
  selectedNoiseClues: number;
  reportComplete: boolean;
  feedback: string;
};

export class ArchiveInvestigationSimulator {
  evaluate(caseFile: ArchiveRepairCase, repaired: string, selectedClueIds: string[], report: string): ArchiveEvaluation {
    const selected = caseFile.clues.filter((clue) => selectedClueIds.includes(clue.id));
    const useful = selected.filter((clue) => clue.useful).length;
    const noise = selected.length - useful;
    const normalizedRepair = repaired.trim().toLocaleLowerCase("it-IT");
    const validRepair = normalizedRepair === caseFile.repaired.toLocaleLowerCase("it-IT");
    const reportText = report.toLocaleLowerCase("it-IT");
    const reportComplete = caseFile.requiredKeywords.every((keyword) => reportText.includes(keyword.toLocaleLowerCase("it-IT")));
    const feedback = !validRepair
      ? "Il messaggio non è ancora eseguibile: controlla accordi e parole operative."
      : noise > 1
        ? "Hai incluso troppi dettagli irrilevanti: separa prove da rumore."
        : reportComplete
          ? "Rapporto chiaro: correzione, prove e decisione sono allineate."
          : "Il rapporto è plausibile, ma manca almeno una parola chiave operativa.";
    return { validRepair, selectedUsefulClues: useful, selectedNoiseClues: noise, reportComplete, feedback };
  }
}
