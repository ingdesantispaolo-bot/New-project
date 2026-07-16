import type { CodingMinigamePrompt, EnglishMinigamePrompt } from "../../procedural/ProceduralTypes";
import type { CodingMinigameSession, EnglishMinigameSession } from "./ProceduralMissionDefs";

export function englishSelectionPanelTitle(prompt: EnglishMinigamePrompt): string {
  if (prompt.type === "sentence-build") return "2 · Build the sentence";
  if (prompt.type === "translation-match") return "2 · Riconosci la traduzione";
  if (prompt.type === "reading-detective") return "2 · Inferenza e prova";
  if (prompt.type === "error-diagnosis") return "2 · Correggi e diagnostica";
  if (prompt.type === "dialogue-response") return "2 · Risposta e motivo";
  if (prompt.requiredSelectionCount > 1) return "2 · Decodifica e prova";
  if (prompt.type === "vocab-lab") return "2 · Scegli il vocabolo";
  if (prompt.type === "grammar-fix") return "2 · Scegli la forma";
  return "2 · Scegli un'azione";
}

export function englishSelectionInstruction(prompt: EnglishMinigamePrompt): string {
  if (prompt.type === "sentence-build") {
    return "Tocca le parole nell'ordine giusto. Ritocca una parola per toglierla.";
  }
  if (prompt.type === "translation-match") {
    return "Leggi il termine inglese, scegli la traduzione italiana corretta e premi Conferma.";
  }
  if (prompt.type === "reading-detective") {
    return "Scegli 2 tessere: l'inferenza corretta e la frase del testo che la dimostra.";
  }
  if (prompt.type === "error-diagnosis") {
    return "Scegli 2 tessere: la frase riparata e il tipo di errore grammaticale.";
  }
  if (prompt.type === "dialogue-response") {
    return "Scegli 2 tessere: la risposta naturale e il motivo comunicativo.";
  }
  if (prompt.requiredSelectionCount > 1) {
    return `Scegli ${prompt.requiredSelectionCount} tessere: il significato operativo e la prova linguistica.`;
  }
  if (prompt.type === "vocab-lab") {
    return "Leggi il contesto, scegli UNA parola inglese precisa e premi Conferma.";
  }
  if (prompt.type === "grammar-fix") {
    return "Trova il segnale grammaticale, scegli UNA forma corretta e premi Conferma.";
  }
  return "Come si gioca: trova verbo, oggetto e vincolo; clicca UNA risposta e premi Conferma.";
}

export function englishSelectionRequirementText(prompt: EnglishMinigamePrompt): string {
  if (prompt.type === "reading-detective") return "Scegli 2 tessere: inferenza e prova testuale.";
  if (prompt.type === "error-diagnosis") return "Scegli 2 tessere: correzione e diagnosi.";
  if (prompt.type === "dialogue-response") return "Scegli 2 tessere: risposta naturale e motivo.";
  if (prompt.type === "action-relay") return "Scegli 2 tessere: azione e prova nel comando.";
  return `Scegli ${prompt.requiredSelectionCount} tessere coerenti.`;
}

export function englishMinigameMethodText(prompt: EnglishMinigamePrompt): string {
  if (prompt.type === "action-relay") {
    return "Method: find the action verb, then object, then not/only/neither. One small word can reverse the command.";
  }
  if (prompt.type === "sequence-switchboard") {
    return "Method: translate the time word first, then decide which event must happen before the safe action.";
  }
  if (prompt.type === "grammar-fix") {
    return "Metodo: trova il segnale (every day, now, yesterday, than, must, on, any) e scegli la forma grammaticale che lo rispetta.";
  }
  if (prompt.type === "sentence-build") {
    return "Metodo: soggetto + verbo + resto; nelle domande l'ausiliare (do/does/did) va prima del soggetto.";
  }
  if (prompt.type === "vocab-lab") {
    return "Metodo: usa il contesto italiano e scegli la parola inglese che rispetta significato, categoria e registro.";
  }
  if (prompt.type === "translation-match") {
    return "Metodo: traduci il termine inglese, poi scarta falsi amici e significati di categorie diverse.";
  }
  if (prompt.type === "reading-detective") {
    return "Metodo: scegli prima l'inferenza, poi la prova testuale esatta che la sostiene.";
  }
  if (prompt.type === "error-diagnosis") {
    return "Metodo: correggi la frase e nomina l'errore: tempo verbale, accordo, ordine, preposizione o condizione.";
  }
  if (prompt.type === "dialogue-response") {
    return "Metodo: identifica situazione, scopo e registro; poi scegli risposta naturale e motivo.";
  }
  return "Method: compare data with the threshold. Choose the action only after checking below, above, between or comparative.";
}

export function englishMinigameHint(prompt: EnglishMinigamePrompt): string {
  if (prompt.type === "action-relay") {
    return "Servono due scelte: una dice cosa fare, l'altra cita il vincolo inglese che lo dimostra.";
  }
  if (prompt.type === "sequence-switchboard") {
    return "Prima traduci la parola-tempo: before = prima, after = dopo, until = aspetta fino a, unless = salvo se.";
  }
  if (prompt.type === "grammar-fix") {
    return "Trova il segnale nella frase (every day, now, yesterday, than, must, on, any...) e scegli la forma che lo rispetta.";
  }
  if (prompt.type === "sentence-build") {
    return "Parti dal soggetto, poi il verbo; nelle domande l'ausiliare (do/does/did) va prima del soggetto.";
  }
  if (prompt.type === "vocab-lab") {
    return "Leggi il contesto: la parola giusta deve rispettare significato tecnico, registro e falsi amici.";
  }
  if (prompt.type === "translation-match") {
    return "Prima traduci mentalmente il termine inglese, poi elimina le opzioni italiane che sono falsi amici o categorie diverse.";
  }
  if (prompt.type === "reading-detective") {
    return "Prima rispondi alla domanda, poi scegli la frase del log che prova quella risposta.";
  }
  if (prompt.type === "error-diagnosis") {
    return "Servono due scelte: la frase corretta e il nome dell'errore. Cerca il segnale grammaticale.";
  }
  if (prompt.type === "dialogue-response") {
    return "Leggi chi parla e perché: la risposta deve essere utile, naturale e del registro giusto.";
  }
  return "Guarda la soglia: below è sotto, above è sopra, between è dentro l'intervallo.";
}

export function englishMinigameFeedback(session: EnglishMinigameSession): string {
  if (session.answered === 0) {
    return "No answers: start from action words and limiters, then choose.";
  }
  const accuracy = session.correct / session.answered;
  if (accuracy >= 0.9 && session.bestStreak >= 8) {
    return "Ottimo inglese operativo: hai letto comandi, limiti e dati senza anticipare.";
  }
  if (accuracy >= 0.72) {
    return "Buona base: aumenta la velocità solo dopo aver riconosciuto la parola chiave.";
  }
  if (session.wrong >= session.correct) {
    return "Troppi tentativi: prima nomina il vincolo inglese, poi scegli l'azione.";
  }
  return "Calibrazione utile: punta a serie pulite, non solo a risposte isolate.";
}

export function codingSelectionPanelTitle(prompt: CodingMinigamePrompt): string {
  return prompt.type === "algorithm-order" ? "2 · Ordina i passi" : "2 · Scegli il blocco mancante";
}

export function codingSelectionInstruction(prompt: CodingMinigamePrompt): string {
  if (prompt.type === "algorithm-order") {
    return "Tocca i passi nell'ordine giusto. Ritocca un passo per toglierlo.";
  }
  return "Come si gioca: segui il codice a sinistra, clicca UNA risposta e premi Conferma.";
}

export function codingMinigameMethodText(prompt: CodingMinigamePrompt): string {
  if (prompt.type === "sequence-builder") {
    return "Metodo: leggi obiettivo e stato attuale; scegli solo il blocco che avvicina al risultato senza effetti collaterali.";
  }
  if (prompt.type === "state-tracer") {
    return "Metodo: usa una tabella mentale. Ogni assegnazione cambia il valore a sinistra dell'uguale.";
  }
  if (prompt.type === "binary-bits") {
    return "Metodo: ogni bit da destra vale 1, 2, 4, 8, 16...; somma le potenze di 2 dove c'è un 1.";
  }
  if (prompt.type === "logic-gate") {
    return "Metodo: valuta una porta alla volta. AND vuole tutti veri, OR almeno uno vero, NOT inverte.";
  }
  if (prompt.type === "loop-output") {
    return "Metodo: esegui il ciclo a mano e scrivi il valore della variabile dopo ogni iterazione.";
  }
  if (prompt.type === "conditional-path") {
    return "Metodo: valuta le condizioni in ordine; si esegue il primo ramo che risulta vero.";
  }
  if (prompt.type === "algorithm-order") {
    return "Metodo: parti dall'obiettivo, scegli il primo passo necessario, poi concatena i passi in ordine.";
  }
  return "Metodo: calcola cosa dovrebbe succedere, poi trova la prima riga che rompe la regola.";
}

export function codingMinigameHint(prompt: CodingMinigamePrompt): string {
  if (prompt.type === "sequence-builder") {
    return "Chiediti quale istruzione cambia lo stato verso l'obiettivo senza alterare altre variabili.";
  }
  if (prompt.type === "state-tracer") {
    return "Fai una mini-tabella: dopo ogni riga scrivi solo i valori cambiati.";
  }
  if (prompt.type === "binary-bits") {
    return "Ogni bit, da destra, vale 1, 2, 4, 8, 16...: somma le potenze di 2 dove c'è un 1.";
  }
  if (prompt.type === "logic-gate") {
    return "AND vuole tutti veri; OR almeno uno vero; NOT inverte. Valuta una porta alla volta.";
  }
  if (prompt.type === "loop-output") {
    return "Esegui il ciclo a mano: scrivi il valore della variabile dopo ogni giro.";
  }
  if (prompt.type === "conditional-path") {
    return "Controlla le condizioni in ordine: si esegue il primo ramo che risulta vero.";
  }
  if (prompt.type === "algorithm-order") {
    return "Parti dall'obiettivo: qual è il primo passo indispensabile? Poi concatena in ordine.";
  }
  return "Nel debug non compensare l'errore: cerca la prima riga che viola il requisito.";
}

export function codingMinigameFeedback(session: CodingMinigameSession): string {
  if (session.answered === 0) {
    return "Nessuna risposta: nel coding devi simulare almeno un programma prima di decidere.";
  }
  const accuracy = session.correct / session.answered;
  if (accuracy >= 0.9 && session.bestStreak >= 8) {
    return "Ottimo controllo mentale: hai seguito stato, sequenza e bug senza tentativi ciechi.";
  }
  if (accuracy >= 0.72) {
    return "Buon tracing: ora prova ad anticipare il risultato usando tabelle più compatte.";
  }
  if (session.wrong >= session.correct) {
    return "Troppi tentativi: rallenta, simula una riga alla volta e scegli solo quando sai spiegare.";
  }
  return "Calibrazione utile: punta a serie pulite e correzioni minime.";
}
