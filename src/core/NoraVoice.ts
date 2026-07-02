// NORA's voice: short, in-character lines for the lab assistant. Warm,
// curious, lightly ironic, never judgemental — and always pointing back at the
// method (observe, hypothesise, try, check) rather than handing out answers.
// Used to give the mission a companion personality without spending art.

export type NoraBeat =
  | "enter"
  | "solve"
  | "streak"
  | "sabotage"
  | "bossDefeat"
  | "lifeLost"
  | "lowLife"
  | "victory"
  | "defeat"
  | "scaffold";

const LINES: Record<NoraBeat, string[]> = {
  enter: [
    "Bentornata, agente. Il laboratorio è instabile: osserviamo prima di toccare.",
    "Sistemi a singhiozzo. Una console alla volta e troviamo il filo del problema.",
    "Ci sono io con te. Leggi i sintomi, poi decidi: di solito basta.",
  ],
  solve: [
    "Console stabilizzata! Hai seguito il metodo, non la fortuna.",
    "Un sistema in più che respira. Ottima diagnosi.",
    "Sentito? È il rumore di qualcosa che torna a funzionare. Avanti.",
    "Pulito. Hai capito la causa, non solo l'effetto.",
  ],
  streak: [
    "Sei in serie! Stai leggendo i sistemi al volo, continua così.",
    "Tre di fila: non è fortuna, è metodo. Mi piace.",
    "Filotto! L'Accademia si sta risvegliando insieme a te.",
    "Che ritmo, agente. I sensori faticano a starti dietro.",
  ],
  sabotage: [
    "Il sabotatore ha guadagnato terreno! Recuperalo con la prossima mossa.",
    "Ci ha rubato secondi preziosi. Concentrati: una risposta pulita lo rallenta.",
    "Sta approfittando dell'errore. Respira e riprendi il controllo del sistema.",
  ],
  bossDefeat: [
    "Sabotatore respinto! Hai protetto il capitolo. Sapevo di poter contare su di te.",
    "Segnale nemico interrotto. Il duello è tuo, agente: capitolo al sicuro.",
  ],
  lifeLost: [
    "Tranquilla: un errore è un dato. Cosa ti dice il sintomo adesso?",
    "Capita. Cambia un solo passaggio e riprova: il resto andava bene.",
    "Niente panico. Riparto i sensori, tu ripensa alla causa.",
  ],
  lowLife: [
    "Ultimo margine. Respira: osserva il sintomo chiave e agisci una volta sola.",
    "Siamo al limite, ma tu hai il metodo. Una mossa pensata vale più di tre a caso.",
  ],
  victory: [
    "Laboratorio salvo! Hai rimesso in linea ogni sistema. Sei brava davvero.",
    "Tutte le console cantano. Missione tua, a pieno titolo.",
    "Energia stabile, porte aperte. Caso chiuso, agente.",
  ],
  defeat: [
    "Pausa, non sconfitta. Lo stesso seed ti aspetta: ora sai dove guardare.",
    "Il lab resiste, ma tu hai imparato la mappa dei guasti. Riproviamo.",
  ],
  scaffold: [
    "Ho già visto questo schema: ti apro subito il controllo utile.",
    "Conosco questo nodo: parto io dalla prima verifica, tu prosegui.",
  ],
};

class NoraVoice {
  private lastIndex = new Map<NoraBeat, number>();

  /** A line for the beat, avoiding immediate repetition of the same one. */
  line(beat: NoraBeat): string {
    const pool = LINES[beat];
    if (pool.length === 1) {
      return pool[0];
    }
    let index = Math.floor(Math.random() * pool.length);
    if (index === this.lastIndex.get(beat)) {
      index = (index + 1) % pool.length;
    }
    this.lastIndex.set(beat, index);
    return pool[index];
  }
}

export const noraVoice = new NoraVoice();
