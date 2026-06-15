import type { ExerciseExplanation } from "../procedural/ProceduralTypes";

export class ExplanationBuilder {
  math(operationSummary: string, workedExample: string, principle = "Un codice numerico affidabile nasce dall'ordine delle operazioni: ogni macchina trasforma il valore precedente."): ExerciseExplanation {
    return {
      principle,
      workedExample,
      transferPrompt: `La prossima volta cerca prima la catena di trasformazioni: ${operationSummary}.`,
    };
  }

  robot(requiredConcepts: string[], optimalLength: number): ExerciseExplanation {
    return {
      principle: "Un programma non è una lista di tentativi: è un piano che tiene insieme posizione, direzione e obiettivo.",
      workedExample: `La soluzione validata usa ${optimalLength} comandi e richiede: ${requiredConcepts.join(", ")}.`,
      transferPrompt: "Prima di premere Esegui, simula mentalmente i primi tre comandi e controlla dove punta il robot.",
    };
  }

  circuit(faultSummary: string): ExerciseExplanation {
    return {
      principle: "Un circuito funziona solo se il percorso della corrente è chiuso, orientato e protetto.",
      workedExample: faultSummary,
      transferPrompt: "Quando un LED non si accende, separa tre domande: il percorso è chiuso, il verso è giusto, la corrente è limitata?",
    };
  }
}

export const explanationBuilder = new ExplanationBuilder();
