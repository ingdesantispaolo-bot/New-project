import type { CommonMistake, GridCommand } from "../procedural/ProceduralTypes";

type RobotFailure =
  | { kind: "wall"; commandIndex: number }
  | { kind: "premature-pickup"; commandIndex: number }
  | { kind: "missing-key" }
  | { kind: "not-exited" }
  | { kind: "too-long"; commandCount: number; ideal: number };

export class MistakeAnalyzer {
  circuitMistakes(): CommonMistake[] {
    return [
      {
        id: "circuit-open-path",
        pattern: "test senza continuita",
        feedback: "Il LED non puo accendersi se la corrente non riesce a tornare alla batteria.",
        repairPrompt: "Cerca il primo punto in cui il tester smette di leggere continuita.",
      },
      {
        id: "circuit-led-polarity",
        pattern: "corrente presente ma LED spento",
        feedback: "Il LED lascia passare corrente in un verso privilegiato: se e invertito resta spento.",
        repairPrompt: "Confronta il lato positivo della batteria con il verso del LED.",
      },
      {
        id: "circuit-missing-resistor",
        pattern: "luce instabile",
        feedback: "La resistenza non serve a far passare corrente: serve a limitarla e proteggere il LED.",
        repairPrompt: "Inserisci la resistenza in serie, prima del LED.",
      },
    ];
  }

  robotFailureMessage(failure: RobotFailure, commands: GridCommand[]): string {
    if (failure.kind === "wall") {
      const command = commands[failure.commandIndex] ?? "MOVE_FORWARD";
      return `Il comando ${failure.commandIndex + 1} (${command}) porta contro un ostacolo o fuori griglia. Controlla direzione e casella prima di avanzare.`;
    }
    if (failure.kind === "premature-pickup") {
      return `Il comando ${failure.commandIndex + 1} prova a raccogliere, ma la chiave non e sotto il robot. Prima porta N-7 sulla stella.`;
    }
    if (failure.kind === "too-long") {
      return `La sequenza funziona quasi, ma usa ${failure.commandCount} comandi: il budget ragionato e ${failure.ideal}. Cerca una svolta o un corridoio piu efficiente.`;
    }
    if (failure.kind === "missing-key") {
      return "Il robot ha eseguito il programma, ma non ha raccolto la chiave: serve un comando Raccogli quando si trova sulla stella.";
    }
    return "Il robot ha la chiave, ma non ha completato l'uscita: raggiungi il quadrato finale e usa Esci.";
  }
}

export const mistakeAnalyzer = new MistakeAnalyzer();
