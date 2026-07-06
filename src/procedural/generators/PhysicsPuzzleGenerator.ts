import type {
  DifficultyPreset,
  GeneratedPhysicsPuzzle,
  PhysicsExerciseType,
  PhysicsVisualData,
} from "../ProceduralTypes";
import { Random } from "../Random";

type PhysicsTemplate = {
  type: PhysicsExerciseType;
  minLevel: number;
  build: (random: Random, difficulty: DifficultyPreset) => GeneratedPhysicsPuzzle;
};

export class PhysicsPuzzleGenerator {
  generate(random: Random, difficulty: DifficultyPreset, preferredTypes?: PhysicsExerciseType[]): GeneratedPhysicsPuzzle {
    const available = physicsTemplates.filter((template) =>
      template.minLevel <= difficulty.level
      && (!preferredTypes || preferredTypes.includes(template.type)));
    const pool = available.length > 0
      ? available
      : physicsTemplates.filter((template) => template.minLevel <= difficulty.level);
    const template = random.pick(pool.length > 0 ? pool : physicsTemplates);
    return template.build(random.fork(template.type), difficulty);
  }

  fallback(random = new Random("physics-fallback"), difficulty?: DifficultyPreset): GeneratedPhysicsPuzzle {
    return buildMotionGraphPuzzle(random, difficulty ?? fallbackDifficulty());
  }
}

function fallbackDifficulty(): DifficultyPreset {
  return {
    level: 1,
    roomCount: 1,
    puzzleCount: 5,
    mathComplexity: 1,
    robotGrid: { cols: 5, rows: 4 },
    robotObstacleCount: 2,
    circuitComplexity: 1,
    availableHints: 5,
    maxAttemptsBeforeExplanation: 4,
    distractorCount: 1,
    noiseDataCount: 0,
    requiredReasoningSteps: 1,
    pedagogicalFocus: ["osservazione"],
  };
}

function basePuzzle(
  difficulty: DifficultyPreset,
  type: PhysicsExerciseType,
  title: string,
  scenario: string,
  prompt: string,
  options: string[],
  correctOption: string,
  explanation: string,
  conceptTags: string[],
  methodSteps: string[],
  visual: PhysicsVisualData,
  optionFeedback?: Record<string, string>,
): GeneratedPhysicsPuzzle {
  return {
    id: `physics-${type}-${visual.title.replace(/\W+/g, "-").toLowerCase()}`,
    title,
    exerciseType: type,
    difficultyLabel: `Livello ${difficulty.level}/8 - ${difficulty.level <= 2 ? "osservazione guidata" : difficulty.level <= 5 ? "modello semplice" : "lettura dati e vincoli"}`,
    scenario,
    prompt,
    options,
    correctOption,
    explanation,
    optionFeedback,
    conceptTags,
    methodSteps,
    visual,
    learningPurpose: learningPurposeFor(type),
    hints: hintsFor(type),
    competencies: competenciesFor(type),
  };
}

function formatNumber(value: number): string {
  return Number.isInteger(value) ? String(value) : Number(value.toFixed(2)).toString();
}

function feedbackMap(distractors: string[], feedbacks: string[]): Record<string, string> {
  return Object.fromEntries(distractors.map((distractor, index) => [distractor, feedbacks[index] ?? "Questa scelta non rispetta il modello fisico richiesto."]));
}

function buildMotionGraphPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const mode = difficulty.level >= 4 ? random.pick(["uniform", "accelerating", "at-rest"] as const) : "uniform";
  const time = random.integer(3, difficulty.level >= 5 ? 9 : 6);
  const speed = random.integer(2, difficulty.level >= 4 ? 8 : 5);
  const acceleration = random.integer(1, 3);
  const distance = speed * time;
  const values = mode === "accelerating"
    ? [0, acceleration, acceleration * 3, acceleration * 6, acceleration * 10]
    : mode === "at-rest"
      ? [speed * 2, speed * 2, speed * 2, speed * 2, speed * 2]
      : [0, speed, speed * 2, speed * 3, speed * 4];
  const correct = mode === "accelerating"
    ? `Moto accelerato: in intervalli uguali percorre distanze sempre maggiori`
    : mode === "at-rest"
      ? `Corpo fermo: la posizione resta costante nel tempo`
      : `Moto uniforme: percorre ${distance} m in ${time} s`;
  const distractors = mode === "accelerating"
    ? [
      "Moto uniforme: la posizione aumenta sempre dello stesso passo",
      "Corpo fermo: la posizione non cambia nel tempo",
      "Moto rallentato: ogni secondo percorre meno spazio del precedente",
    ]
    : mode === "at-rest"
      ? [
        "Moto uniforme: percorre sempre la stessa distanza a ogni secondo",
        "Moto accelerato: ogni secondo avanza un po' di piu di prima",
        "Moto rallentato: ogni secondo avanza un po' di meno di prima",
      ]
      : [
        `Moto accelerato: ogni secondo avanza un po' di piu di prima`,
        `Moto rallentato: ogni secondo avanza un po' di meno di prima`,
        `Moto uniforme: percorre ${time} m in ${distance} s`,
      ];
  const distractorFeedback = mode === "accelerating"
    ? [
      "Nel moto uniforme gli incrementi sarebbero uguali; qui crescono, quindi la velocita aumenta.",
      "Un corpo fermo avrebbe posizione costante; qui la posizione cambia.",
      "Nel moto rallentato gli incrementi diminuirebbero; qui diventano piu grandi.",
    ]
    : mode === "at-rest"
      ? [
        "Per parlare di moto uniforme la posizione deve cambiare di passi uguali; qui resta sempre la stessa.",
        "Nel moto accelerato la posizione cambierebbe sempre di piu; qui non cambia.",
        "Nel moto rallentato la posizione cambierebbe ancora, anche se sempre meno; qui resta costante.",
      ]
      : [
        "Accelerato significa incrementi crescenti; qui ogni secondo l'aumento e sempre lo stesso.",
        "Rallentato significa incrementi decrescenti; qui il passo resta costante.",
        "Hai scambiato spazio e tempo: percorre distanza in un tempo, non tempo in una distanza.",
      ];
  return basePuzzle(
    difficulty,
    "motion-graph",
    "Fisica: grafico del moto",
    "Un carrello si muove su una guida rettilinea. La console mostra posizione e tempo, non vuole una formula a memoria.",
    mode === "uniform"
      ? `Se la posizione cresce di ${speed} m ogni secondo per ${time} s, quale conclusione descrive correttamente il moto?`
      : mode === "accelerating"
        ? `Il grafico posizione-tempo ha incrementi ${acceleration}, ${acceleration * 2}, ${acceleration * 3}, ${acceleration * 4} m in tempi uguali. Quale conclusione e coerente?`
        : "Il grafico posizione-tempo mostra sempre la stessa posizione in istanti diversi. Quale conclusione e coerente?",
    shuffledOptions(random, correct, distractors),
    correct,
    mode === "uniform"
      ? `La posizione aumenta sempre della stessa quantita: ${speed} m ogni secondo. La distanza totale e velocita per tempo, quindi ${speed} x ${time} = ${distance} m.`
      : mode === "accelerating"
        ? "Gli incrementi di posizione non sono uguali: diventano piu grandi a parita di tempo. Questo indica velocita crescente, quindi moto accelerato."
        : "Se la posizione non cambia mentre il tempo passa, il corpo e fermo rispetto al riferimento scelto.",
    ["moto uniforme", "grafico posizione-tempo", "velocita"],
    mode === "uniform"
      ? ["controlla se la crescita e regolare", "leggi quanto aumenta ogni secondo", "moltiplica velocita per tempo"]
      : ["leggi due posizioni consecutive", "confronta gli incrementi", "classifica il moto dal tipo di variazione"],
    {
      kind: "motion-graph",
      title: "posizione-tempo",
      labels: ["tempo (s)", "posizione (m)", "pendenza costante"],
      values,
      highlight: mode === "uniform" ? `${speed} m/s` : mode === "accelerating" ? "pendenza cresce" : "posizione costante",
    },
    feedbackMap(distractors, distractorFeedback),
  );
}

function buildUnitCheckPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const mode = difficulty.level >= 5
    ? random.pick(["length", "mass", "time", "speed"] as const)
    : difficulty.level >= 3
      ? random.pick(["length", "mass", "time"] as const)
      : "length";
  const distance = random.pick([120, 240, 360, 480, 600]);
  const meters = distance / 100;
  const mass = random.pick([250, 500, 750, 1500]);
  const gramsToKg = mass / 1000;
  const minutes = random.pick([2, 3, 4, 5]);
  const seconds = minutes * 60;
  const kmh = random.pick([18, 36, 54, 72]);
  const ms = kmh / 3.6;
  const correct = mode === "length"
    ? `${distance} cm = ${formatNumber(meters)} m`
    : mode === "mass"
      ? `${mass} g = ${formatNumber(gramsToKg)} kg`
      : mode === "time"
        ? `${minutes} min = ${seconds} s`
        : `${kmh} km/h = ${formatNumber(ms)} m/s`;
  const distractors = mode === "length"
    ? [`${distance} cm = ${distance} m`, `${distance} cm = ${distance / 10} m`, `${distance} cm = ${formatNumber(meters / 10)} m`]
    : mode === "mass"
      ? [`${mass} g = ${mass} kg`, `${mass} g = ${mass / 100} kg`, `${mass} g = ${formatNumber(gramsToKg / 10)} kg`]
      : mode === "time"
        ? [`${minutes} min = ${minutes} s`, `${minutes} min = ${minutes * 100} s`, `${minutes} min = ${formatNumber(minutes / 60)} s`]
        : [`${kmh} km/h = ${kmh} m/s`, `${kmh} km/h = ${formatNumber(kmh / 3600)} m/s`, `${kmh} km/h = ${formatNumber(kmh * 3.6)} m/s`];
  const distractorFeedback = mode === "length"
    ? [
      "Hai lasciato invariato il numero: da centimetri a metri bisogna dividere per 100.",
      "Hai diviso per 10: quello porta ai decimetri, non ai metri.",
      "Hai diviso una volta di troppo: controlla che 100 cm formino 1 m.",
    ]
    : mode === "mass"
      ? [
        "Hai lasciato invariato il numero: da grammi a chilogrammi bisogna dividere per 1000.",
        "Hai diviso per 100: manca ancora un fattore 10 per arrivare ai chilogrammi.",
        "Hai diviso una volta di troppo: 1000 g corrispondono a 1 kg.",
      ]
      : mode === "time"
        ? [
          "Hai trattato minuti e secondi come se avessero lo stesso valore numerico: 1 min vale 60 s.",
          "Hai usato il fattore 100, ma il tempo si converte con 60 secondi per minuto.",
          "Hai diviso invece di moltiplicare: passando da minuti a secondi il numero aumenta.",
        ]
        : [
          "Hai copiato il valore numerico: km/h e m/s non hanno lo stesso passo.",
          "Hai diviso per 3600 senza convertire anche i chilometri in metri: il fattore corretto complessivo e 3,6.",
          "Hai moltiplicato per 3,6: per passare da km/h a m/s bisogna dividere per 3,6.",
        ];
  return basePuzzle(
    difficulty,
    "unit-check",
    "Fisica: unita di misura",
    "Nel registro del laboratorio una misura e scritta in unita non adatte al calcolo. Prima di ragionare serve convertirla.",
    mode === "length"
      ? `Quale conversione e corretta per usare ${distance} cm in metri?`
      : mode === "mass"
        ? `Quale conversione e corretta per usare ${mass} g in chilogrammi?`
        : mode === "time"
          ? `Quale conversione e corretta per usare ${minutes} minuti in secondi?`
          : `Quale conversione e corretta per usare ${kmh} km/h in m/s?`,
    shuffledOptions(random, correct, distractors),
    correct,
    mode === "length"
      ? "Da centimetri a metri si divide per 100: 100 cm formano 1 m."
      : mode === "mass"
        ? "Da grammi a chilogrammi si divide per 1000: 1000 g formano 1 kg."
        : mode === "time"
          ? `Da minuti a secondi si moltiplica per 60: ${minutes} x 60 = ${seconds} s.`
          : `Per passare da km/h a m/s si divide per 3,6: ${kmh} / 3,6 = ${formatNumber(ms)} m/s.`,
    ["unita di misura", "conversioni", "stima"],
    ["identifica unita di partenza", "scegli il fattore di conversione", "controlla se il risultato e plausibile"],
    {
      kind: "unit-card",
      title: mode === "length" ? "cm -> m" : mode === "mass" ? "g -> kg" : mode === "time" ? "min -> s" : "km/h -> m/s",
      labels: mode === "length"
        ? ["100 cm", "1 m", "dividi per 100"]
        : mode === "mass"
          ? ["1000 g", "1 kg", "dividi per 1000"]
          : mode === "time"
            ? ["1 min", "60 s", "moltiplica per 60"]
            : ["3,6 km/h", "1 m/s", "dividi per 3,6"],
      values: mode === "length" ? [distance, meters] : mode === "mass" ? [mass, gramsToKg] : mode === "time" ? [minutes, seconds] : [kmh, ms],
      highlight: correct,
    },
    feedbackMap(distractors, distractorFeedback),
  );
}

function buildForceDiagramPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const weight = random.pick([4, 6, 8, 10, 12]);
  const mode = difficulty.level >= 5 ? random.pick(["table", "hanging", "push"] as const) : random.bool(0.65) ? "table" : "hanging";
  const support = mode === "table" ? "reazione del tavolo" : mode === "hanging" ? "tensione del filo" : "forza di attrito statico";
  const correct = mode === "push"
    ? `Peso e reazione si bilanciano in verticale; spinta e attrito statico si bilanciano in orizzontale`
    : `Peso verso il basso e ${support} verso l'alto, uguali perché l'oggetto resta fermo`;
  const distractors = mode === "push"
    ? [
      "Solo la spinta orizzontale, perché il blocco non si muove ma viene spinto",
      "Peso e spinta sono uguali perché entrambe agiscono sullo stesso oggetto",
      "La reazione del tavolo e maggiore del peso, perché deve anche annullare la spinta",
    ]
    : [
      `Peso verso l'alto e ${support} verso il basso, uguali perché l'oggetto resta fermo`,
      `Peso verso il basso maggiore della ${support}, perché l'oggetto preme sul sostegno`,
      "Solo il peso verso il basso, perché su un oggetto fermo non agiscono altre forze",
    ];
  const distractorFeedback = mode === "push"
    ? [
      "Anche se il blocco non si muove, peso e reazione verticale continuano ad agire.",
      "Peso e spinta hanno direzioni diverse: non si bilanciano tra loro.",
      "La spinta orizzontale e bilanciata dall'attrito statico; la reazione verticale bilancia il peso.",
    ]
    : [
      "Hai invertito i versi: il peso e verso il basso, il vincolo sostiene verso l'alto.",
      "Se l'oggetto resta fermo, la risultante verticale e zero: peso e sostegno hanno lo stesso modulo.",
      "Fermo non significa senza forze: significa forze bilanciate.",
    ];
  return basePuzzle(
    difficulty,
    "force-diagram",
    "Fisica: diagramma delle forze",
    mode === "table"
      ? `Un blocco da ${weight} N e appoggiato su un tavolo e resta fermo.`
      : mode === "hanging"
        ? `Una massa da ${weight} N e appesa a un filo e resta ferma.`
        : `Un blocco da ${weight} N resta fermo su un tavolo mentre una mano lo spinge lateralmente senza farlo partire.`,
    "Quale diagramma descrive meglio le forze principali?",
    shuffledOptions(random, correct, distractors),
    correct,
    mode === "push"
      ? "Un oggetto fermo ha risultante nulla in ogni direzione: in verticale peso e reazione si bilanciano, in orizzontale spinta e attrito statico si bilanciano."
      : "Se un oggetto resta fermo, le forze verticali si bilanciano. Il peso tira verso il basso; il supporto o il filo esercita una forza uguale verso l'alto.",
    ["forze", "equilibrio", "peso", mode === "table" ? "reazione vincolare" : mode === "hanging" ? "tensione" : "attrito statico"],
    ["disegna l'oggetto", "segna il peso verso il basso", "cerca il vincolo che sostiene l'oggetto"],
    {
      kind: "force-diagram",
      title: mode === "table" ? "blocco su tavolo" : mode === "hanging" ? "massa appesa" : "blocco spinto",
      labels: mode === "table" ? ["N verso alto", "P verso basso", "equilibrio"] : mode === "hanging" ? ["T verso alto", "P verso basso", "equilibrio"] : ["N/P", "spinta/attrito", "equilibrio"],
      values: [weight, weight, mode === "push" ? Math.round(weight / 2) : weight],
      highlight: "somma forze = 0",
    },
    feedbackMap(distractors, distractorFeedback),
  );
}

function buildEnergyTransferPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const cases = [
    {
      scenario: "Una pallina scende lungo una rampa liscia.",
      correct: "Energia potenziale gravitazionale diminuisce e diventa energia cinetica",
      distractors: ["L'energia potenziale aumenta mentre la pallina scende", "L'energia meccanica della pallina si consuma e sparisce gradualmente mentre scende lungo tutta la rampa", "La velocita diminuisce perche l'energia si trasforma"],
      distractorFeedback: [
        "Al contrario: scendendo l'altezza cala, quindi l'energia potenziale diminuisce e diventa cinetica.",
        "L'energia non sparisce: si trasforma. Quella potenziale diventa cinetica e la pallina accelera.",
        "Scendendo la velocita aumenta, non diminuisce: l'energia cambia forma ma la somma si conserva.",
      ],
      labels: ["altezza", "velocita", "energia si trasforma"],
    },
    {
      scenario: "Una pila alimenta un piccolo LED.",
      correct: "Energia chimica della pila diventa energia elettrica e poi luce",
      distractors: ["Il LED trasforma la luce in energia chimica dentro la pila", "La luce del LED si accende senza consumare energia dalla pila", "L'energia chimica diventa luce senza passare dall'energia elettrica"],
      distractorFeedback: [
        "La catena va nell'altro verso: la pila (chimica) da energia elettrica, che il LED trasforma in luce.",
        "La pila si consuma: fornisce l'energia elettrica che il LED trasforma in luce, non e gratis.",
        "Manca un passaggio: prima l'energia chimica diventa elettrica, poi il LED la trasforma in luce.",
      ],
      labels: ["pila", "corrente", "luce"],
    },
    {
      scenario: "Un freno rallenta una ruota di laboratorio mentre il disco si scalda al contatto.",
      correct: "Parte dell'energia cinetica si trasforma in calore per attrito",
      distractors: ["L'attrito fa accelerare la ruota e la raffredda mentre gira", "L'energia cinetica sparisce del tutto quando la ruota rallenta", "Il calore prodotto torna nella ruota e la rimette in movimento"],
      distractorFeedback: [
        "Al contrario: l'attrito frena la ruota e scalda il disco. Il moto diventa calore.",
        "L'energia non sparisce: quella cinetica del moto si trasforma in calore per attrito.",
        "Il calore non torna indietro a rimettere in moto la ruota: la trasformazione va in un solo verso.",
      ],
      labels: ["moto", "attrito", "calore"],
    },
    {
      scenario: "Una molla compressa spinge un carrellino su una rotaia quasi senza attrito.",
      correct: "Energia elastica della molla si trasforma in energia cinetica del carrellino",
      distractors: ["Energia cinetica del carrellino diventa energia elastica prima che parta", "La molla crea energia nuova quando viene lasciata", "Il carrellino si muove perche l'energia elastica diventa massa"],
      distractorFeedback: [
        "Prima della partenza l'energia e immagazzinata nella molla compressa; poi diventa moto del carrellino.",
        "La molla non crea energia: restituisce energia elastica gia immagazzinata dalla compressione.",
        "L'energia non diventa massa in questo fenomeno: diventa energia cinetica, cioe moto.",
      ],
      labels: ["molla", "spinta", "moto"],
    },
    {
      scenario: "Un pannello solare alimenta una piccola ventola.",
      correct: "Energia luminosa diventa energia elettrica e poi movimento della ventola",
      distractors: ["La ventola produce luce che torna nel pannello", "L'energia luminosa sparisce quando tocca il pannello", "Il pannello trasforma direttamente la luce in freddo"],
      distractorFeedback: [
        "La catena e opposta: la luce arriva al pannello, il pannello produce energia elettrica e la ventola gira.",
        "L'energia non sparisce: viene convertita in energia elettrica e poi in movimento.",
        "Il pannello non produce freddo in questa situazione: alimenta elettricamente la ventola.",
      ],
      labels: ["luce", "corrente", "movimento"],
    },
  ];
  const pool = difficulty.level >= 5 ? cases : difficulty.level >= 3 ? cases.slice(0, 3) : cases.slice(0, 1);
  const item = random.pick(pool);
  return basePuzzle(
    difficulty,
    "energy-transfer",
    "Fisica: trasformazioni di energia",
    item.scenario,
    "Quale descrizione rispetta meglio la conservazione dell'energia?",
    shuffledOptions(random, item.correct, item.distractors),
    item.correct,
    "In fisica l'energia non viene creata dal nulla: cambia forma o passa da un sistema a un altro. La risposta corretta nomina forma iniziale, trasformazione e forma finale.",
    ["energia", "trasformazioni", "conservazione"],
    ["trova la forma iniziale", "trova cosa cambia nel sistema", "nomina la forma finale"],
    {
      kind: "energy-flow",
      title: "catena energetica",
      labels: item.labels,
      highlight: "prima -> dopo",
    },
    Object.fromEntries(item.distractors.map((distractor, i) => [distractor, item.distractorFeedback[i]])),
  );
}

function buildExperimentOrderPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const target = random.pick([
    "misurare la velocita media",
    "capire se una superficie frena di piu",
    "verificare se la massa cambia la caduta",
    "stimare se una molla piu compressa spinge piu lontano",
    "capire se la lunghezza di un pendolo cambia il periodo",
  ]);
  const correct = target === "misurare la velocita media"
    ? "Misuro spazio e tempo, ripeto la prova, poi calcolo spazio diviso tempo"
    : target === "capire se una superficie frena di piu"
      ? "Cambio solo la superficie, tengo uguali massa e spinta, confronto la distanza percorsa"
      : target === "verificare se la massa cambia la caduta"
        ? "Cambio la massa, tengo uguali altezza e forma, confronto i tempi misurati"
        : target === "stimare se una molla piu compressa spinge piu lontano"
          ? "Cambio solo la compressione della molla, tengo uguali carrello e rotaia, misuro la distanza"
          : "Cambio solo la lunghezza del filo, tengo uguali massa e ampiezza iniziale, misuro il periodo";
  const distractors = [
    "Cambio piu variabili insieme per fare prima",
    "Faccio una sola prova molto attenta: se lo strumento e preciso ripetere non serve davvero",
    "Misuro solo alla fine e tengo il valore piu vicino a quello che mi aspettavo",
  ];
  const distractorFeedback = [
    "Se cambi piu variabili insieme non sai quale abbia causato il risultato.",
    "Una singola misura puo contenere errore casuale: ripetere rende il confronto piu affidabile.",
    "Scegliere il dato piu atteso introduce bias: bisogna registrare i dati misurati e confrontarli.",
  ];
  return basePuzzle(
    difficulty,
    "experiment-order",
    "Fisica: metodo sperimentale",
    `La classe deve ${target}. Il sistema accetta solo un piano con variabile controllata.`,
    "Quale procedura produce dati piu affidabili?",
    shuffledOptions(random, correct, distractors),
    correct,
    "Un esperimento utile cambia una variabile alla volta, misura con strumenti, ripete la prova e confronta dati omogenei.",
    ["metodo sperimentale", "variabili", "dati"],
    ["definisci cosa vuoi verificare", "cambia una sola variabile", "misura e ripeti prima di concludere"],
    {
      kind: "experiment-steps",
      title: "procedura controllata",
      labels: ["ipotesi", "misura", "ripeti", "confronta"],
      highlight: "una variabile alla volta",
    },
    feedbackMap(distractors, distractorFeedback),
  );
}

function buildDensityPressurePuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const mode = difficulty.level >= 6 ? random.pick(["density", "pressure", "float"] as const) : random.bool(0.55) ? "density" : "pressure";
  if (mode === "density") {
    const mass = random.pick([80, 120, 150, 200]);
    const volume = random.pick([40, 50, 75, 100]);
    const density = mass / volume;
    const correct = `Densita = ${formatNumber(density)} g/cm3`;
    const distractors = [
      `Densita = ${mass + volume} g/cm3`,
      `Densita = ${formatNumber(volume / mass)} g/cm3`,
      "La densita dipende solo dalla massa",
    ];
    const distractorFeedback = [
      "Hai sommato massa e volume, ma la densita e un rapporto: massa divisa per volume.",
      "Hai invertito il rapporto: volume/massa non e densita in g/cm3.",
      "Due oggetti con la stessa massa possono avere volumi diversi: serve anche il volume.",
    ];
    return basePuzzle(
      difficulty,
      "density-pressure",
      "Fisica: densita",
      `Un campione ha massa ${mass} g e volume ${volume} cm3.`,
      "Quale conclusione usa correttamente massa e volume?",
      shuffledOptions(random, correct, distractors),
      correct,
      `La densita e massa divisa per volume: ${mass} / ${volume} = ${formatNumber(density)} g/cm3.`,
      ["densita", "massa", "volume", "rapporto"],
      ["leggi massa", "leggi volume", "dividi massa per volume"],
      {
        kind: "fluid-column",
        title: "massa-volume",
        labels: ["massa", "volume", "densita"],
        values: [mass, volume, density],
        highlight: "m / V",
      },
      feedbackMap(distractors, distractorFeedback),
    );
  }
  if (mode === "float") {
    const objectDensity = random.pick([0.7, 0.8, 1.2, 1.5]);
    const correct = objectDensity < 1
      ? "Galleggia, perche la sua densita e minore di quella dell'acqua"
      : "Affonda, perche la sua densita e maggiore di quella dell'acqua";
    const distractors = objectDensity < 1
      ? [
        "Affonda, perche ogni corpo solido va sotto la superficie",
        "Galleggia solo se ha massa nulla",
        "Resta sempre sospeso a meta, perche acqua e oggetto si bilanciano automaticamente",
      ]
      : [
        "Galleggia, perche ogni oggetto piccolo resta in superficie",
        "Affonda solo se la sua massa supera 1 kg",
        "Resta sempre sospeso a meta, perche acqua e oggetto si bilanciano automaticamente",
      ];
    const distractorFeedback = objectDensity < 1
      ? [
        "Non tutti i solidi affondano: conta la densita media rispetto al liquido.",
        "Un corpo puo galleggiare anche con massa non nulla se distribuita su volume sufficiente.",
        "La sospensione richiede densita uguale a quella del liquido; qui e minore.",
      ]
      : [
        "La dimensione da sola non basta: se la densita e maggiore dell'acqua, tende ad affondare.",
        "La massa totale non decide da sola: serve il rapporto massa/volume, cioe la densita.",
        "La sospensione richiede densita uguale a quella del liquido; qui e maggiore.",
      ];
    return basePuzzle(
      difficulty,
      "density-pressure",
      "Fisica: galleggiamento",
      `Un oggetto ha densita ${formatNumber(objectDensity)} g/cm3. L'acqua ha densita circa 1 g/cm3.`,
      "Quale previsione e coerente con il confronto delle densita?",
      shuffledOptions(random, correct, distractors),
      correct,
      `Si confronta la densita dell'oggetto con quella dell'acqua: ${formatNumber(objectDensity)} g/cm3 ${objectDensity < 1 ? "e minore" : "e maggiore"} di 1 g/cm3, quindi l'oggetto ${objectDensity < 1 ? "galleggia" : "affonda"}.`,
      ["densita", "galleggiamento", "confronto"],
      ["leggi la densita dell'oggetto", "confrontala con quella dell'acqua", "prevedi galleggiamento o affondamento"],
      {
        kind: "fluid-column",
        title: "densita-acqua",
        labels: ["oggetto", "acqua", objectDensity < 1 ? "galleggia" : "affonda"],
        values: [objectDensity, 1],
        highlight: "confronta densita",
      },
      feedbackMap(distractors, distractorFeedback),
    );
  }
  const depth = random.pick([1, 2, 3, 4]);
  const correct = "B, perche a maggiore profondita c'e piu liquido che preme sul sensore";
  const distractors = [
    "A, perche vicino alla superficie l'aria spinge di piu sul liquido",
    "Misurano uguale, perche in uno stesso liquido la pressione non cambia mai",
    "A, perche piu si scende meno liquido resta sotto il sensore",
  ];
  const distractorFeedback = [
    "L'aria esterna non annulla l'effetto della colonna di liquido: piu profondita significa piu pressione.",
    "In uno stesso liquido la pressione cambia con la profondita.",
    "Conta il liquido sopra il sensore, non quello sotto: B ha piu colonna sopra.",
  ];
  return basePuzzle(
    difficulty,
    "density-pressure",
    "Fisica: pressione nei liquidi",
    `Due sensori sono nello stesso liquido: A a ${depth} m, B a ${depth + 2} m di profondita.`,
    "Quale sensore misura pressione maggiore?",
    shuffledOptions(random, correct, distractors),
    correct,
    "In uno stesso liquido la pressione aumenta con la profondita: piu colonna di liquido sta sopra al sensore, maggiore e la pressione.",
    ["pressione", "liquidi", "profondita"],
    ["controlla se il liquido e lo stesso", "confronta la profondita", "scegli il punto piu profondo"],
    {
      kind: "fluid-column",
      title: "pressione-profondita",
      labels: ["sensore A", "sensore B", "B piu profondo"],
      values: [depth, depth + 2],
      highlight: "pressione cresce",
    },
    feedbackMap(distractors, distractorFeedback),
  );
}

function buildHeatTemperaturePuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const start = random.pick([15, 18, 20, 22]);
  const end = start + random.pick([10, 15, 20, 25]);
  return basePuzzle(
    difficulty,
    "heat-temperature",
    "Fisica: calore e temperatura",
    `Un becher d'acqua passa da ${start} C a ${end} C mentre riceve energia da una piastra.`,
    "Quale affermazione distingue meglio calore e temperatura?",
    shuffledOptions(random, "Il calore e energia trasferita; la temperatura indica quanto e caldo il corpo", [
      "Calore e temperatura sono la stessa cosa",
      "La temperatura e l'energia che la piastra trasferisce all'acqua del becher",
      "Piu alta e la temperatura dell'acqua nel becher, piu calore e sempre contenuto al suo interno mentre si scalda",
    ]),
    "Il calore e energia trasferita; la temperatura indica quanto e caldo il corpo",
    "La piastra trasferisce energia: questo e calore. Il termometro misura lo stato termico dell'acqua, cioe la temperatura.",
    ["calore", "temperatura", "energia termica"],
    ["se c'e trasferimento parla di calore", "se c'e termometro parla di temperatura", "non confondere processo e grandezza"],
    {
      kind: "thermal-scale",
      title: "scala termica",
      labels: [`${start} C`, `${end} C`, "energia trasferita"],
      values: [start, end],
      highlight: "calore != temperatura",
    },
  );
}

function buildWaveReadingPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const crests = random.pick([3, 4, 5]);
  const length = crests * random.pick([2, 3, 4]);
  const wavelength = length / crests;
  return basePuzzle(
    difficulty,
    "wave-reading",
    "Fisica: onde",
    `In un disegno ci sono ${crests} lunghezze d'onda complete distribuite in ${length} m.`,
    "Quale valore descrive la lunghezza d'onda?",
    shuffledOptions(random, `${wavelength} m`, [`${length + crests} m`, `${wavelength + 1} m`, `${length * crests} m`]),
    `${wavelength} m`,
    `La lunghezza d'onda e la distanza di un ciclo completo. Se ${length} m contengono ${crests} cicli, ogni ciclo misura ${length} / ${crests} = ${wavelength} m.`,
    ["onde", "lunghezza d'onda", "lettura grafica"],
    ["conta i cicli completi", "leggi la distanza totale", "dividi distanza per numero di cicli"],
    {
      kind: "wave",
      title: "onda-periodica",
      labels: ["cresta", "valle", "lambda"],
      values: [crests, length, wavelength],
      highlight: "lambda",
    },
  );
}

function buildOpticsRayPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const item = random.pick([
    {
      scenario: "Un raggio di luce colpisce uno specchio piano.",
      correct: "L'angolo di riflessione e uguale all'angolo di incidenza",
      distractors: ["Il raggio riflesso torna sempre sulla stessa linea da cui e arrivato", "La luce rimbalza ad angolo retto", "L'angolo di riflessione e maggiore dell'angolo di incidenza"],
      distractorFeedback: [
        "Solo se il raggio arriva perpendicolare torna indietro: in generale riflessione e incidenza sono uguali rispetto alla normale.",
        "Non e fisso a 90 gradi: l'angolo di riflessione dipende da come arriva il raggio, ed e uguale a quello di incidenza.",
        "I due angoli sono uguali, non uno maggiore dell'altro: riflessione = incidenza rispetto alla normale.",
      ],
      labels: ["incidenza", "normale", "riflessione"],
    },
    {
      scenario: "Una lente convergente riceve raggi paralleli all'asse principale.",
      correct: "Dopo la lente i raggi tendono a incontrarsi nel fuoco",
      distractors: ["Dopo la lente i raggi si allontanano invece di avvicinarsi tra loro nello spazio", "I raggi restano paralleli", "La lente non cambia mai la direzione dei raggi di luce"],
      distractorFeedback: [
        "Quella e una lente divergente: la convergente invece avvicina i raggi e li porta al fuoco.",
        "Una lente convergente piega i raggi paralleli: non restano paralleli, si incontrano nel fuoco.",
        "La lente cambia eccome la direzione: e la sua funzione, portare i raggi paralleli verso il fuoco.",
      ],
      labels: ["raggi paralleli", "lente", "fuoco"],
    },
  ]);
  return basePuzzle(
    difficulty,
    "optics-ray",
    "Fisica: raggi di luce",
    item.scenario,
    "Quale previsione e coerente con il modello dei raggi?",
    shuffledOptions(random, item.correct, item.distractors),
    item.correct,
    "Il modello dei raggi permette di prevedere la direzione della luce con una regola geometrica: per lo specchio gli angoli si conservano, per la lente convergente i raggi paralleli vanno verso il fuoco.",
    ["ottica", "raggi", "geometria"],
    ["disegna il raggio iniziale", "segna normale o asse", "applica la regola geometrica"],
    {
      kind: "ray",
      title: "raggio-luce",
      labels: item.labels,
      highlight: "direzione prevista",
    },
    Object.fromEntries(item.distractors.map((distractor, i) => [distractor, item.distractorFeedback[i]])),
  );
}

function shuffledOptions(random: Random, correct: string, distractors: string[]): string[] {
  const unique = distractors.filter((item, index, all) => item !== correct && all.indexOf(item) === index).slice(0, 3);
  return random.shuffle([correct, ...unique]);
}

function learningPurposeFor(type: PhysicsExerciseType): string {
  return {
    "motion-graph": "Leggere il moto da una rappresentazione: distinguere posizione, tempo, velocita e andamento del grafico.",
    "unit-check": "Usare correttamente le unita prima dei calcoli, con stima di plausibilita del risultato.",
    "force-diagram": "Tradurre una situazione reale in un diagramma delle forze e riconoscere equilibrio semplice.",
    "energy-transfer": "Descrivere trasformazioni di energia senza idea di energia creata o distrutta.",
    "experiment-order": "Progettare prove controllate: una variabile alla volta, misure, ripetizioni, conclusione proporzionata.",
    "density-pressure": "Interpretare rapporti fisici e relazioni qualitative tra profondita, pressione, massa e volume.",
    "heat-temperature": "Distinguere energia trasferita e temperatura misurata.",
    "wave-reading": "Leggere grandezze ondulatorie da un disegno o grafico semplice.",
    "optics-ray": "Prevedere il percorso della luce con regole geometriche semplici.",
  }[type];
}

function hintsFor(type: PhysicsExerciseType): string[] {
  return {
    "motion-graph": ["Se il grafico cresce sempre dello stesso passo, il moto e uniforme.", "La velocita e pendenza: aumento di posizione diviso tempo."],
    "unit-check": ["Prima converti, poi calcola.", "Controlla l'ordine di grandezza: 100 cm non possono diventare 10000 m."],
    "force-diagram": ["Un oggetto fermo non significa assenza di forze.", "Cerca sempre peso e vincolo che lo sostiene."],
    "energy-transfer": ["Nomina forma iniziale e forma finale.", "Scarta risposte che creano energia dal nulla."],
    "experiment-order": ["Cambia una sola variabile alla volta.", "Una misura sola e fragile: ripeti e confronta."],
    "density-pressure": ["Densita e massa divisa volume.", "In uno stesso liquido piu profondita significa piu pressione."],
    "heat-temperature": ["Calore e trasferimento di energia.", "Temperatura e cio che misura il termometro."],
    "wave-reading": ["Conta cicli completi.", "Una lunghezza d'onda e un ciclo completo."],
    "optics-ray": ["Usa normale o asse come riferimento.", "La luce segue una regola geometrica, non una preferenza visiva."],
  }[type];
}

function competenciesFor(type: PhysicsExerciseType): string[] {
  const base = ["fisica.modelli", "fisica.osservazione", "problemSolving", "pensieroCritico"];
  if (type === "motion-graph") return [...base, "fisica.moto", "matematica.grafici"];
  if (type === "unit-check") return [...base, "fisica.misure", "matematica.proporzioni"];
  if (type === "force-diagram") return [...base, "fisica.forze", "fisica.equilibrio"];
  if (type === "energy-transfer") return [...base, "fisica.energia", "scienze.sistemi"];
  if (type === "experiment-order") return [...base, "fisica.metodoSperimentale", "controlloErrore"];
  if (type === "density-pressure") return [...base, "fisica.materia", "matematica.rapporti"];
  if (type === "heat-temperature") return [...base, "fisica.termologia", "scienze.energia"];
  if (type === "wave-reading") return [...base, "fisica.onde", "matematica.grafici"];
  return [...base, "fisica.ottica", "geometria"];
}

const physicsTemplates: PhysicsTemplate[] = [
  { type: "motion-graph", minLevel: 1, build: buildMotionGraphPuzzle },
  { type: "unit-check", minLevel: 1, build: buildUnitCheckPuzzle },
  { type: "force-diagram", minLevel: 2, build: buildForceDiagramPuzzle },
  { type: "energy-transfer", minLevel: 2, build: buildEnergyTransferPuzzle },
  { type: "experiment-order", minLevel: 3, build: buildExperimentOrderPuzzle },
  { type: "density-pressure", minLevel: 4, build: buildDensityPressurePuzzle },
  { type: "heat-temperature", minLevel: 4, build: buildHeatTemperaturePuzzle },
  { type: "wave-reading", minLevel: 5, build: buildWaveReadingPuzzle },
  { type: "optics-ray", minLevel: 5, build: buildOpticsRayPuzzle },
];
