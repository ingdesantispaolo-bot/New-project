import { italianStudyPages } from "./italianStudyPages";
import { mathStudyPages } from "./mathStudyPages";
import type { ProceduralPuzzleKind, ProceduralSpecialization } from "../procedural/ProceduralTypes";

export type TheorySubject = Exclude<ProceduralSpecialization, "libera">;

export type TheoryVisualKind =
  | "formula"
  | "timeline"
  | "text-map"
  | "circuit"
  | "code-trace"
  | "grid"
  | "staff"
  | "physics-diagram"
  | "latin-table";

export type TheoryExample = {
  prompt: string;
  steps: string[];
  answer: string;
};

export type TheoryTopic = {
  id: string;
  subject: TheorySubject;
  title: string;
  area: string;
  levelRange: [number, number];
  tags: string[];
  linkedPuzzleKinds: ProceduralPuzzleKind[];
  definition: string;
  coreRules: string[];
  method: string[];
  example: TheoryExample;
  watchOut: string[];
  noraExplanation: string;
  visualKind: TheoryVisualKind;
};

const subjectFromStudyPage = (subject?: "matematica" | "italiano"): TheorySubject =>
  subject === "italiano" ? "italiano" : "matematica";

const kindFromStudyPage = (subject: TheorySubject): ProceduralPuzzleKind =>
  subject === "italiano" ? "language" : "math";

const studyTopics: TheoryTopic[] = [...mathStudyPages, ...italianStudyPages].map((page) => {
  const subject = subjectFromStudyPage(page.subject);
  return {
    id: page.id,
    subject,
    title: page.title,
    area: page.area,
    levelRange: page.levelRange,
    tags: page.tags,
    linkedPuzzleKinds: [kindFromStudyPage(subject)],
    definition: page.definition,
    coreRules: page.formulas,
    method: page.rules,
    example: page.example,
    watchOut: page.watchOut,
    noraExplanation: `${page.definition} Prima riconosci il caso, poi applica una regola alla volta e verifica l'errore tipico.`,
    visualKind: subject === "italiano" ? "timeline" : "formula",
  };
});

const extraTopics: TheoryTopic[] = [
  {
    id: "inglese-comandi-operativi",
    subject: "inglese",
    title: "Comandi operativi e divieti",
    area: "Inglese operativo",
    levelRange: [1, 5],
    tags: ["imperative", "do not", "safety", "action"],
    linkedPuzzleKinds: ["english"],
    definition: "Un comando operativo in inglese dice quale azione fare, su quale oggetto, e spesso quale azione evitare.",
    coreRules: ["verbo base all'inizio: press, take, insert", "do not + verbo = divieto", "only limita l'azione permessa"],
    method: ["trova il verbo", "trova l'oggetto", "separa permesso e divieto"],
    example: {
      prompt: "Do not open the red valve. Press only the blue switch.",
      steps: ["azione vietata: open red valve", "azione permessa: press blue switch", "only esclude gli altri interruttori"],
      answer: "Premi solo l'interruttore blu.",
    },
    watchOut: ["Non tradurre parola per parola: estrai la procedura.", "Only cambia il perimetro dell'azione."],
    noraExplanation: "Io leggo questi comandi come protocolli: prima azione, poi oggetto, poi blocchi di sicurezza. Il divieto vale quanto il comando.",
    visualKind: "text-map",
  },
  {
    id: "inglese-sequenze-condizioni",
    subject: "inglese",
    title: "Sequenze e condizioni",
    area: "Inglese operativo",
    levelRange: [2, 8],
    tags: ["before", "after", "until", "unless", "if", "otherwise"],
    linkedPuzzleKinds: ["english"],
    definition: "Le parole di tempo e condizione stabiliscono quando un'azione e autorizzata.",
    coreRules: ["before = prima di", "after = dopo", "until = aspetta finche", "unless = tranne se / a meno che"],
    method: ["segna l'evento che deve avvenire prima", "controlla eccezioni", "scegli l'azione solo nel caso autorizzato"],
    example: {
      prompt: "Wait until the light is green, then reset the panel.",
      steps: ["prima: la luce deve diventare verde", "poi: reset del pannello", "se non e verde, aspetta"],
      answer: "Resetta solo dopo la luce verde.",
    },
    watchOut: ["Not until non autorizza subito: blocca fino alla condizione.", "Otherwise descrive il caso alternativo."],
    noraExplanation: "Quando vedo until o unless rallento: sono parole-porta. Aprono o chiudono l'azione in base a una condizione.",
    visualKind: "timeline",
  },
  {
    id: "circuito-chiuso-corrente",
    subject: "elettronica",
    title: "Circuito chiuso e corrente",
    area: "Circuiti",
    levelRange: [1, 4],
    tags: ["circuito chiuso", "corrente", "interruttore", "filo"],
    linkedPuzzleKinds: ["circuit"],
    definition: "Un circuito funziona quando la corrente ha un percorso completo dalla batteria al carico e ritorno.",
    coreRules: ["percorso aperto = corrente ferma", "interruttore chiuso = ponte attivo", "un filo mancante interrompe il ritorno"],
    method: ["parti dalla batteria", "segui ogni tratto", "fermati dove il percorso si interrompe"],
    example: {
      prompt: "Il LED non si accende e il tester dice 'interrotto' tra LED e ritorno.",
      steps: ["la batteria arriva al LED", "manca il ritorno", "serve chiudere il tratto interrotto"],
      answer: "Ripara il filo mancante.",
    },
    watchOut: ["Un componente presente ma scollegato non partecipa al circuito.", "Non cambiare pezzi a caso: segui il percorso."],
    noraExplanation: "Io immagino la corrente come una strada: se anche un solo ponte e alzato, il segnale non torna a casa.",
    visualKind: "circuit",
  },
  {
    id: "circuiti-polarita-protezione",
    subject: "elettronica",
    title: "Polarita e protezione del LED",
    area: "Circuiti",
    levelRange: [2, 6],
    tags: ["LED", "polarita", "resistenza", "protezione"],
    linkedPuzzleKinds: ["circuit"],
    definition: "Il LED lascia passare corrente in un verso e deve essere protetto da una resistenza adatta.",
    coreRules: ["LED invertito = luce spenta", "resistenza assente = corrente non sicura", "valore errato = sistema instabile"],
    method: ["controlla il verso del LED", "controlla se c'e resistenza", "valuta se il valore limita la corrente"],
    example: {
      prompt: "Il percorso e chiuso, ma il LED resta spento.",
      steps: ["se il giro e chiuso, il problema non e il filo", "controllo polarita", "LED invertito blocca il passaggio"],
      answer: "Gira il LED nel verso corretto.",
    },
    watchOut: ["Percorso chiuso non significa circuito sicuro.", "La resistenza non e decorativa: protegge il LED."],
    noraExplanation: "Quando il circuito e chiuso ma non risponde, guardo verso e protezione: il LED e un componente con regole precise.",
    visualKind: "circuit",
  },
  {
    id: "coding-tracing-variabili",
    subject: "coding",
    title: "Tracing di variabili",
    area: "Algoritmi",
    levelRange: [1, 5],
    tags: ["variabili", "assegnazione", "tracing", "output"],
    linkedPuzzleKinds: ["coding"],
    definition: "Fare tracing significa eseguire il codice a mano, aggiornando lo stato delle variabili riga per riga.",
    coreRules: ["= assegna un nuovo valore", "l'ultimo valore sostituisce il precedente", "print mostra il valore attuale"],
    method: ["scrivi una tabella variabili", "aggiorna solo la variabile a sinistra", "leggi l'output finale"],
    example: {
      prompt: "x = 3; x = x + 2; print(x)",
      steps: ["x parte da 3", "x + 2 diventa 5", "print legge x attuale"],
      answer: "5",
    },
    watchOut: ["Non leggere x = x + 2 come un'equazione matematica.", "Usa sempre l'ultimo valore salvato."],
    noraExplanation: "Il codice non ricorda intenzioni, ricorda stato. Io seguo una riga, aggiorno la memoria, poi passo alla successiva.",
    visualKind: "code-trace",
  },
  {
    id: "coding-cicli-condizioni",
    subject: "coding",
    title: "Cicli e condizioni",
    area: "Algoritmi",
    levelRange: [3, 8],
    tags: ["for", "range", "if", "else", "boolean"],
    linkedPuzzleKinds: ["coding", "robot"],
    definition: "Un ciclo ripete un blocco; una condizione decide quale ramo del programma viene eseguito.",
    coreRules: ["range(n) ripete n volte", "if esegue il ramo solo se la condizione e vera", "else copre il caso falso"],
    method: ["conta le ripetizioni", "aggiorna lo stato a ogni giro", "valuta la condizione prima del ramo"],
    example: {
      prompt: "for i in range(3): total = total + 2",
      steps: ["range(3) produce tre giri", "ogni giro aggiunge 2", "totale aggiunto = 6"],
      answer: "Il blocco aggiunge 6 in totale.",
    },
    watchOut: ["range(3) non arriva a 3: produce 0, 1, 2.", "AND richiede tutti veri; OR ne richiede almeno uno."],
    noraExplanation: "Nei cicli io non salto alla fine: faccio girare il blocco una volta, controllo lo stato, poi ripeto.",
    visualKind: "code-trace",
  },
  {
    id: "robot-griglia-coordinate",
    subject: "coding",
    title: "Robot, griglia e coordinate",
    area: "Robotica",
    levelRange: [1, 7],
    tags: ["robot", "coordinate", "direzione", "checkpoint"],
    linkedPuzzleKinds: ["robot"],
    definition: "Una rotta robotica combina posizione, direzione iniziale, ostacoli e obiettivi ordinati.",
    coreRules: ["girare cambia direzione, non posizione", "avanzare dipende dalla direzione attuale", "i checkpoint vanno rispettati in ordine"],
    method: ["segna partenza e uscita", "simula i primi comandi", "controlla ostacoli prima di avanzare"],
    example: {
      prompt: "Il robot guarda Est e deve salire di una casella.",
      steps: ["guardare Est non basta", "prima gira verso Nord", "poi avanza"],
      answer: "TURN_LEFT, MOVE_FORWARD",
    },
    watchOut: ["Non confondere destra dello schermo e destra del robot.", "Un comando avanti contro un muro interrompe il piano."],
    noraExplanation: "Io metto una freccia sul robot: senza quella freccia, la griglia mente. La direzione decide cosa significa avanti.",
    visualKind: "grid",
  },
  {
    id: "musica-pentagramma-chiavi",
    subject: "musica",
    title: "Pentagramma e chiavi",
    area: "Lettura musicale",
    levelRange: [1, 5],
    tags: ["pentagramma", "chiave di violino", "chiave di basso", "note"],
    linkedPuzzleKinds: ["music"],
    definition: "Il pentagramma usa righe e spazi per indicare l'altezza delle note; la chiave cambia il punto di riferimento.",
    coreRules: ["in chiave di violino il Sol e riferimento", "in chiave di basso il Fa e riferimento", "linee addizionali estendono il pentagramma"],
    method: ["leggi la chiave", "conta righe o spazi", "controlla se ci sono linee addizionali"],
    example: {
      prompt: "Nota nel secondo spazio in chiave di violino.",
      steps: ["chiave di violino", "gli spazi sono Fa-La-Do-Mi", "secondo spazio = La"],
      answer: "La",
    },
    watchOut: ["La stessa posizione cambia nome se cambia chiave.", "Non ignorare l'ottava nelle note fuori dal pentagramma."],
    noraExplanation: "Prima fisso la chiave, poi conto. Senza chiave, la nota e solo un punto nello spazio.",
    visualKind: "staff",
  },
  {
    id: "musica-ritmo-intervalli",
    subject: "musica",
    title: "Ritmo e intervalli",
    area: "Lettura musicale",
    levelRange: [3, 8],
    tags: ["ritmo", "durate", "intervalli", "scala"],
    linkedPuzzleKinds: ["music"],
    definition: "Il ritmo organizza la durata dei suoni; l'intervallo misura la distanza tra due note.",
    coreRules: ["semibreve = 4 battiti", "minima = 2", "semiminima = 1", "intervallo = conta i nomi di nota inclusi"],
    method: ["conta i battiti gia presenti", "trova i battiti mancanti", "per l'intervallo conta dalla nota di partenza a quella di arrivo"],
    example: {
      prompt: "In 4/4 ci sono due semiminime e una minima.",
      steps: ["1 + 1 + 2 = 4", "la battuta e completa"],
      answer: "Non manca nessun battito.",
    },
    watchOut: ["Una croma vale mezzo battito, non uno.", "Salire di nota non significa sempre stesso intervallo."],
    noraExplanation: "Il ritmo e un contenitore: se so quanto deve contenere, capisco quale tessera manca senza indovinare.",
    visualKind: "staff",
  },
  {
    id: "fisica-misure-unita",
    subject: "fisica",
    title: "Misure e unita",
    area: "Metodo fisico",
    levelRange: [1, 5],
    tags: ["unita", "conversioni", "grandezze", "misura"],
    linkedPuzzleKinds: ["physics"],
    definition: "Una misura collega un numero a un'unita; senza unita coerenti il confronto non e affidabile.",
    coreRules: ["cm -> m: dividi per 100", "g -> kg: dividi per 1000", "min -> s: moltiplica per 60"],
    method: ["riconosci la grandezza", "porta tutto nella stessa unita", "controlla se il valore e plausibile"],
    example: {
      prompt: "250 cm in metri.",
      steps: ["da cm a m sono due scalini", "250 / 100 = 2,5"],
      answer: "2,5 m",
    },
    watchOut: ["Non sommare grandezze con unita diverse.", "Le conversioni di area e volume non scalano come le lunghezze."],
    noraExplanation: "Io non confronto numeri nudi: prima do loro un'unita. Solo allora il dato diventa leggibile.",
    visualKind: "physics-diagram",
  },
  {
    id: "fisica-moto-forze-energia",
    subject: "fisica",
    title: "Moto, forze ed energia",
    area: "Modelli fisici",
    levelRange: [2, 8],
    tags: ["moto", "grafico", "forze", "energia", "equilibrio"],
    linkedPuzzleKinds: ["physics"],
    definition: "La fisica descrive i fenomeni con grandezze misurabili e modelli: grafici, forze, energia e trasformazioni.",
    coreRules: ["nel grafico posizione-tempo la pendenza indica velocita", "forze bilanciate = equilibrio", "l'energia si trasforma, non nasce dal nulla"],
    method: ["leggi quale grandezza cambia", "scegli il modello piu semplice", "verifica dati e unita"],
    example: {
      prompt: "Una linea posizione-tempo diventa piu ripida.",
      steps: ["la pendenza aumenta", "la velocita aumenta", "il moto e piu rapido"],
      answer: "Il corpo si muove piu velocemente.",
    },
    watchOut: ["Un grafico non e un disegno del percorso.", "Peso e massa non sono la stessa grandezza."],
    noraExplanation: "Quando guardo un fenomeno cerco cosa cambia davvero: posizione, forza, energia o temperatura. Il modello viene dopo.",
    visualKind: "physics-diagram",
  },
  {
    id: "fisica-onde-ottica",
    subject: "fisica",
    title: "Onde e ottica",
    area: "Modelli fisici",
    levelRange: [5, 8],
    tags: ["onde", "frequenza", "lunghezza d'onda", "ottica", "raggi"],
    linkedPuzzleKinds: ["physics"],
    definition: "Le onde trasportano energia; in ottica geometrica la luce si rappresenta con raggi e direzioni.",
    coreRules: ["v = lambda x f", "frequenza alta = oscillazioni piu fitte", "il raggio riflesso rispetta la normale"],
    method: ["identifica lunghezza d'onda o frequenza", "usa la relazione corretta", "per i raggi disegna normale e direzione"],
    example: {
      prompt: "Onda con lambda = 2 m e f = 3 Hz.",
      steps: ["v = lambda x f", "2 x 3 = 6"],
      answer: "6 m/s",
    },
    watchOut: ["Frequenza e periodo sono inversi.", "La normale non e lo specchio: e la linea perpendicolare."],
    noraExplanation: "Nelle onde conto spazio e tempo; nei raggi conto direzione. Se separo queste due letture, il fenomeno smette di confondersi.",
    visualKind: "physics-diagram",
  },
  {
    id: "latino-casi-declinazioni",
    subject: "latino",
    title: "Casi e declinazioni",
    area: "Morfologia latina",
    levelRange: [1, 6],
    tags: ["casi", "declinazioni", "desinenze", "funzione"],
    linkedPuzzleKinds: ["latin"],
    definition: "In latino la desinenza indica caso e numero; il caso suggerisce la funzione della parola nella frase.",
    coreRules: ["nominativo = spesso soggetto", "genitivo = specificazione", "accusativo = spesso oggetto", "ablativo = mezzo, causa, modo o stato"],
    method: ["trova la desinenza", "riconosci declinazione e numero", "assegna una funzione plausibile"],
    example: {
      prompt: "puella rosam videt",
      steps: ["puella = nominativo singolare", "rosam = accusativo singolare", "videt = vede"],
      answer: "La ragazza vede la rosa.",
    },
    watchOut: ["Non fidarti solo dell'ordine delle parole.", "La stessa desinenza puo avere piu casi: usa il contesto."],
    noraExplanation: "In latino l'ordine e meno rigido: io ascolto le desinenze. Sono loro a dirmi chi agisce e chi riceve l'azione.",
    visualKind: "latin-table",
  },
  {
    id: "latino-verbi-concordanza",
    subject: "latino",
    title: "Verbi e concordanza",
    area: "Morfologia latina",
    levelRange: [2, 8],
    tags: ["verbi", "coniugazioni", "persona", "tempo", "concordanza"],
    linkedPuzzleKinds: ["latin"],
    definition: "La voce verbale latina porta informazioni su persona, numero, tempo, modo e talvolta diatesi.",
    coreRules: ["la desinenza verbale indica persona e numero", "il tema aiuta a riconoscere tempo e coniugazione", "aggettivo e nome concordano in genere, numero e caso"],
    method: ["separa tema e desinenza", "riconosci tempo e persona", "controlla concordanza con il nome"],
    example: {
      prompt: "amant",
      steps: ["tema ama-", "desinenza -nt", "terza persona plurale presente"],
      answer: "essi amano",
    },
    watchOut: ["Una forma uguale puo appartenere a piu analisi: controlla frase e lessico.", "La concordanza non richiede sempre stessa declinazione."],
    noraExplanation: "Il verbo latino e compatto: porta molte informazioni in poche lettere. Io lo apro in tema e desinenza.",
    visualKind: "latin-table",
  },
];

export const theoryTopics: TheoryTopic[] = [...studyTopics, ...extraTopics];

export const theorySubjectLabels: Record<TheorySubject, string> = {
  matematica: "Matematica",
  italiano: "Italiano",
  inglese: "Inglese",
  elettronica: "Elettronica",
  coding: "Coding",
  musica: "Musica",
  fisica: "Fisica",
  latino: "Latino",
};

export const theorySubjectOrder: TheorySubject[] = [
  "matematica",
  "italiano",
  "inglese",
  "elettronica",
  "coding",
  "musica",
  "fisica",
  "latino",
];

