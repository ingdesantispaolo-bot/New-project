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

function buildMotionGraphPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const speed = random.integer(2, difficulty.level >= 4 ? 8 : 5);
  const time = random.integer(3, difficulty.level >= 5 ? 9 : 6);
  const distance = speed * time;
  return basePuzzle(
    difficulty,
    "motion-graph",
    "Fisica: grafico del moto",
    "Un carrello si muove su una guida rettilinea. La console mostra posizione e tempo, non vuole una formula a memoria.",
    `Se la posizione cresce di ${speed} m ogni secondo per ${time} s, quale conclusione descrive correttamente il moto?`,
    shuffledOptions(random, `Moto uniforme: percorre ${distance} m in ${time} s`, [
      `Moto accelerato: ogni secondo avanza un po' di piu di prima`,
      `Moto rallentato: ogni secondo avanza un po' di meno di prima`,
      `Moto uniforme: percorre ${time} m in ${distance} s`,
    ]),
    `Moto uniforme: percorre ${distance} m in ${time} s`,
    `La posizione aumenta sempre della stessa quantita: ${speed} m ogni secondo. La distanza totale e velocita per tempo, quindi ${speed} x ${time} = ${distance} m.`,
    ["moto uniforme", "grafico posizione-tempo", "velocita"],
    ["controlla se la crescita e regolare", "leggi quanto aumenta ogni secondo", "moltiplica velocita per tempo"],
    {
      kind: "motion-graph",
      title: "posizione-tempo",
      labels: ["tempo (s)", "posizione (m)", "pendenza costante"],
      values: [0, speed, speed * 2, speed * 3, speed * 4],
      highlight: `${speed} m/s`,
    },
  );
}

function buildUnitCheckPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const distance = random.pick([120, 240, 360, 480, 600]);
  const meters = distance / 100;
  const mass = random.pick([250, 500, 750, 1500]);
  const gramsToKg = mass / 1000;
  const useLength = difficulty.level <= 3 || random.bool();
  const correct = useLength
    ? `${distance} cm = ${meters} m`
    : `${mass} g = ${gramsToKg} kg`;
  return basePuzzle(
    difficulty,
    "unit-check",
    "Fisica: unita di misura",
    "Nel registro del laboratorio una misura e scritta in unita non adatte al calcolo. Prima di ragionare serve convertirla.",
    useLength
      ? `Quale conversione e corretta per usare ${distance} cm in metri?`
      : `Quale conversione e corretta per usare ${mass} g in chilogrammi?`,
    shuffledOptions(random, correct, useLength
      ? [`${distance} cm = ${distance} m`, `${distance} cm = ${distance / 10} m`, `${distance} cm = ${meters / 10} m`]
      : [`${mass} g = ${mass} kg`, `${mass} g = ${mass / 100} kg`, `${mass} g = ${gramsToKg / 10} kg`]),
    correct,
    useLength
      ? "Da centimetri a metri si divide per 100: 100 cm formano 1 m."
      : "Da grammi a chilogrammi si divide per 1000: 1000 g formano 1 kg.",
    ["unita di misura", "conversioni", "stima"],
    ["identifica unita di partenza", "ricorda il fattore 100 o 1000", "controlla se il risultato e plausibile"],
    {
      kind: "unit-card",
      title: useLength ? "cm -> m" : "g -> kg",
      labels: useLength ? ["100 cm", "1 m", "dividi per 100"] : ["1000 g", "1 kg", "dividi per 1000"],
      values: useLength ? [distance, meters] : [mass, gramsToKg],
      highlight: correct,
    },
  );
}

function buildForceDiagramPuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  const weight = random.pick([4, 6, 8, 10, 12]);
  const table = random.bool(0.65);
  const support = table ? "reazione del tavolo" : "tensione del filo";
  const correct = `Peso verso il basso e ${support} verso l'alto, uguali perché l'oggetto resta fermo`;
  return basePuzzle(
    difficulty,
    "force-diagram",
    "Fisica: diagramma delle forze",
    table
      ? `Un blocco da ${weight} N e appoggiato su un tavolo e resta fermo.`
      : `Una massa da ${weight} N e appesa a un filo e resta ferma.`,
    "Quale diagramma descrive meglio le forze principali?",
    shuffledOptions(random, correct, [
      `Peso verso l'alto e ${support} verso il basso, uguali perché l'oggetto resta fermo`,
      `Peso verso il basso maggiore della ${support}, perché l'oggetto preme sul sostegno`,
      "Solo il peso verso il basso, perché su un oggetto fermo non agiscono altre forze",
    ]),
    correct,
    "Se un oggetto resta fermo, le forze verticali si bilanciano. Il peso tira verso il basso; il supporto o il filo esercita una forza uguale verso l'alto.",
    ["forze", "equilibrio", "peso", table ? "reazione vincolare" : "tensione"],
    ["disegna l'oggetto", "segna il peso verso il basso", "cerca il vincolo che sostiene l'oggetto"],
    {
      kind: "force-diagram",
      title: table ? "blocco su tavolo" : "massa appesa",
      labels: table ? ["N verso alto", "P verso basso", "equilibrio"] : ["T verso alto", "P verso basso", "equilibrio"],
      values: [weight, weight],
      highlight: "somma forze = 0",
    },
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
  ];
  const item = difficulty.level >= 3 ? random.pick(cases) : cases[0];
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
  const target = random.pick(["misurare la velocita media", "capire se una superficie frena di piu", "verificare se la massa cambia la caduta"]);
  const correct = target === "misurare la velocita media"
    ? "Misuro spazio e tempo, ripeto la prova, poi calcolo spazio diviso tempo"
    : target === "capire se una superficie frena di piu"
      ? "Cambio solo la superficie, tengo uguali massa e spinta, confronto la distanza percorsa"
      : "Cambio la massa, tengo uguali altezza e forma, confronto i tempi misurati";
  return basePuzzle(
    difficulty,
    "experiment-order",
    "Fisica: metodo sperimentale",
    `La classe deve ${target}. Il sistema accetta solo un piano con variabile controllata.`,
    "Quale procedura produce dati piu affidabili?",
    shuffledOptions(random, correct, [
      "Cambio piu variabili insieme per fare prima",
      "Faccio una sola prova molto attenta: se lo strumento e preciso ripetere non serve davvero",
      "Misuro solo alla fine e tengo il valore piu vicino a quello che mi aspettavo",
    ]),
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
  );
}

function buildDensityPressurePuzzle(random: Random, difficulty: DifficultyPreset): GeneratedPhysicsPuzzle {
  if (random.bool(0.55)) {
    const mass = random.pick([80, 120, 150, 200]);
    const volume = random.pick([40, 50, 75, 100]);
    const density = mass / volume;
    const correct = `Densita = ${density} g/cm3`;
    return basePuzzle(
      difficulty,
      "density-pressure",
      "Fisica: densita",
      `Un campione ha massa ${mass} g e volume ${volume} cm3.`,
      "Quale conclusione usa correttamente massa e volume?",
      shuffledOptions(random, correct, [
        `Densita = ${mass + volume} g/cm3`,
        `Densita = ${volume / mass} g/cm3`,
        "La densita dipende solo dalla massa",
      ]),
      correct,
      `La densita e massa divisa per volume: ${mass} / ${volume} = ${density} g/cm3.`,
      ["densita", "massa", "volume", "rapporto"],
      ["leggi massa", "leggi volume", "dividi massa per volume"],
      {
        kind: "fluid-column",
        title: "massa-volume",
        labels: ["massa", "volume", "densita"],
        values: [mass, volume, density],
        highlight: "m / V",
      },
    );
  }
  const depth = random.pick([1, 2, 3, 4]);
  return basePuzzle(
    difficulty,
    "density-pressure",
    "Fisica: pressione nei liquidi",
    `Due sensori sono nello stesso liquido: A a ${depth} m, B a ${depth + 2} m di profondita.`,
    "Quale sensore misura pressione maggiore?",
    shuffledOptions(random, "B, perche a maggiore profondita c'e piu liquido che preme sul sensore", [
      "A, perche vicino alla superficie l'aria spinge di piu sul liquido",
      "Misurano uguale, perche in uno stesso liquido la pressione non cambia mai",
      "A, perche piu si scende meno liquido resta sotto il sensore",
    ]),
    "B, perche a maggiore profondita c'e piu liquido che preme sul sensore",
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
