export type DialogueLine = {
  speaker: string;
  text: string;
};

export const dialogues: Record<string, DialogueLine[]> = {
  mission1Opening: [
    {
      speaker: "Accademia",
      text: "Accesso parziale concesso. Il Laboratorio Spento non risponde ai protocolli.",
    },
    {
      speaker: "Eli",
      text: "Perfetto. Un posto buio, una porta bloccata e nessuno che spiega troppo. Mi piace gia meno.",
    },
    {
      speaker: "NORA",
      text: "Io posso suggerire. Tu osservi, provi, correggi. Qui gli errori sono dati utili.",
    },
  ],
  circuitHint: [
    {
      speaker: "NORA",
      text: "Il LED non chiede coraggio. Chiede solo un percorso completo e stabile.",
    },
  ],
  doorOpened: [
    {
      speaker: "Accademia",
      text: "Condizione verificata: codice corretto, circuito chiuso, robot operativo. Porta sbloccata.",
    },
  ],
  mission2Opening: [
    {
      speaker: "Accademia",
      text: "La Serra Biologica resta in modalita conservazione. I sensori inviano dati incompleti.",
    },
    {
      speaker: "NORA",
      text: "Qui le risposte crescono lentamente. Prima osserviamo, poi tocchiamo i comandi.",
    },
  ],
  mission3Opening: [
    {
      speaker: "Accademia",
      text: "La Fabbrica dei Numeri e in blocco. I nuclei energetici entrano, ma le macchine li trasformano nel valore sbagliato.",
    },
    {
      speaker: "NORA",
      text: "Qui non stai facendo una scheda: stai configurando una linea industriale. Ogni operazione lascia una traccia.",
    },
  ],
  mission4Opening: [
    {
      speaker: "Accademia",
      text: "Archivio delle Parole in modalita frammentata. I messaggi corrotti impediscono di ricostruire gli eventi.",
    },
    {
      speaker: "NORA",
      text: "Qui le parole sono interruttori. Una frase imprecisa apre il cassetto sbagliato.",
    },
  ],
};
