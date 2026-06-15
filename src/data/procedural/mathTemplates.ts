export type MathTemplate = {
  id: string;
  title: string;
  narrative: string;
  minComplexity: number;
  archetype:
    | "calcolo-diretto"
    | "ragionamento-inverso"
    | "sequenza"
    | "vincolo"
    | "diagnosi-errore"
    | "lettura-dati"
    | "proporzione"
    | "pre-algebra"
    | "frazioni"
    | "percentuali"
    | "geometria"
    | "statistica"
    | "probabilita"
    | "potenze-radici"
    | "funzione-lineare"
    | "sistemi-lineari"
    | "equazione-primo-grado"
    | "coordinate";
  competencies?: string[];
  curriculumTags?: string[];
  build: (a: number, b: number, c: number) => {
    prompt: string;
    answer: number;
    hints: string[];
    steps?: string[];
  };
};

export const mathTemplates: MathTemplate[] = [
  {
    id: "double-add-subtract",
    title: "Serratura a energia",
    narrative: "Il terminale misura un nucleo che va amplificato e poi raffreddato.",
    minComplexity: 1,
    archetype: "calcolo-diretto",
    build: (a, b, c) => ({
      prompt: `Il codice è il doppio di ${a}, più ${b}, meno ${c}.`,
      answer: a * 2 + b - c,
      hints: [
        `Prima raddoppia ${a}.`,
        `Aggiungi ${b} al risultato del raddoppio.`,
        `Solo alla fine sottrai ${c}.`,
      ],
      steps: [`${a} x 2 = ${a * 2}`, `${a * 2} + ${b} = ${a * 2 + b}`, `${a * 2 + b} - ${c} = ${a * 2 + b - c}`],
    }),
  },
  {
    id: "triple-minus-half",
    title: "Bilanciatore di carica",
    narrative: "La carica va triplicata, poi divisa in due camere solo dopo il raffreddamento.",
    minComplexity: 2,
    archetype: "calcolo-diretto",
    build: (a, b, c) => {
      const base = a * 3 - b;
      const adjusted = base % 2 === 0 ? base : base + 1;
      return {
        prompt: `Triplica ${a}, togli ${b}, poi usa metà del valore stabilizzato.`,
        answer: adjusted / 2,
        hints: [
          `Triplica ${a}: ottieni ${a * 3}.`,
          `Sottrai ${b}; se il valore non è pari, il terminale lo stabilizza al pari successivo.`,
          "La camera finale usa metà del valore stabilizzato.",
        ],
        steps: [`${a} x 3 = ${a * 3}`, `${a * 3} - ${b} = ${base}`, `valore stabilizzato = ${adjusted}`, `${adjusted} / 2 = ${adjusted / 2}`],
      };
    },
  },
  {
    id: "multiply-add-divide",
    title: "Codice del compressore",
    narrative: "Il compressore accetta solo risultati divisibili senza resto.",
    minComplexity: 3,
    archetype: "vincolo",
    build: (a, b, c) => {
      const dividend = a * b + c;
      const divisor = c % 2 === 0 ? 2 : 3;
      const correctedDividend = dividend + ((divisor - (dividend % divisor)) % divisor);
      return {
        prompt: `Moltiplica ${a} per ${b}, aggiungi ${c}, poi dividi il valore stabilizzato per ${divisor}.`,
        answer: correctedDividend / divisor,
        hints: [
          `Prima calcola ${a} x ${b}.`,
          `Poi aggiungi ${c}; il terminale stabilizza al primo valore divisibile per ${divisor}.`,
          `Dividi per ${divisor} solo alla fine.`,
        ],
        steps: [`${a} x ${b} = ${a * b}`, `${a * b} + ${c} = ${dividend}`, `stabilizzazione a ${correctedDividend}`, `${correctedDividend} / ${divisor} = ${correctedDividend / divisor}`],
      };
    },
  },
  {
    id: "reverse-output-lock",
    title: "Inversore di uscita",
    narrative: "La macchina mostra il valore finale, ma l'ingresso è stato cancellato dal log.",
    minComplexity: 4,
    archetype: "ragionamento-inverso",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(5, c));
      const target = (a + b) * multiplier;
      return {
        prompt: `Un valore sconosciuto entra, riceve +${b}, poi viene moltiplicato per ${multiplier}. L'uscita è ${target}. Qual era il valore iniziale?`,
        answer: a,
        hints: [
          `Lavora al contrario: prima annulla la moltiplicazione per ${multiplier}.`,
          `${target} / ${multiplier} = ${target / multiplier}.`,
          `Se prima era stato aggiunto ${b}, ora devi toglierlo.`,
        ],
        steps: [`${target} / ${multiplier} = ${target / multiplier}`, `${target / multiplier} - ${b} = ${a}`],
      };
    },
  },
  {
    id: "sequence-signal",
    title: "Sequenza del segnale",
    narrative: "Tre impulsi rivelano la regola del trasmettitore, il quarto apre il vano.",
    minComplexity: 4,
    archetype: "sequenza",
    build: (a, b, c) => {
      const step = Math.max(3, b);
      const first = a;
      const second = first + step;
      const third = second + step + c;
      const fourth = third + step + c * 2;
      return {
        prompt: `Impulsi registrati: ${first}, ${second}, ${third}, ?. Ogni salto aumenta di ${c}. Quale numero completa il quarto impulso?`,
        answer: fourth,
        hints: [
          `Il primo salto è ${second - first}.`,
          `Il secondo salto è ${third - second}: confrontalo con il primo.`,
          `Il terzo salto aumenta ancora di ${c}.`,
        ],
        steps: [`salto 1 = ${second - first}`, `salto 2 = ${third - second}`, `salto 3 = ${fourth - third}`, `${third} + ${fourth - third} = ${fourth}`],
      };
    },
  },
  {
    id: "divisibility-valve",
    title: "Valvola dei Vincoli",
    narrative: "La valvola non vuole il numero più grande: vuole il primo numero che rispetta due regole.",
    minComplexity: 5,
    archetype: "vincolo",
    build: (a, b, c) => {
      const divisor = c % 2 === 0 ? 3 : 4;
      const threshold = a + b;
      let candidate = threshold + 1;
      while (candidate % 2 !== 0 || candidate % divisor !== 0) candidate += 1;
      return {
        prompt: `Trova il più piccolo numero maggiore di ${threshold} che sia pari e divisibile per ${divisor}.`,
        answer: candidate,
        hints: [
          "Deve superare la soglia, quindi non provare numeri più piccoli.",
          "Deve essere pari: scarta tutti i dispari.",
          `Tra i pari rimasti, cerca il primo divisibile per ${divisor}.`,
        ],
        steps: [`soglia = ${threshold}`, `primi pari oltre soglia`, `${candidate} e divisibile per 2 e per ${divisor}`],
      };
    },
  },
  {
    id: "wrong-machine-log",
    title: "Log di errore",
    narrative: "La fabbrica ha scritto un risultato sbagliato: devi trovare il valore coerente, non fidarti del log.",
    minComplexity: 6,
    archetype: "diagnosi-errore",
    build: (a, b, c) => {
      const correct = (a - c) * 2 + b;
      const wrong = (a + c) * 2 + b;
      return {
        prompt: `Il log dice ${wrong}, ma la macchina corretta fa: togli ${c} da ${a}, raddoppia, poi aggiungi ${b}. Quale valore deve essere certificato?`,
        answer: correct,
        hints: [
          `Il log ha aggiunto ${c}, ma il comando dice togli.`,
          `Prima calcola ${a} - ${c}.`,
          "Solo dopo raddoppia e aggiungi l'ultimo valore.",
        ],
        steps: [`${a} - ${c} = ${a - c}`, `${a - c} x 2 = ${(a - c) * 2}`, `${(a - c) * 2} + ${b} = ${correct}`],
      };
    },
  },
  {
    id: "sensor-average-threshold",
    title: "Sensori in media",
    narrative: "Il terminale non chiede un numero isolato: vuole una lettura stabile da tre sensori.",
    minComplexity: 3,
    archetype: "lettura-dati",
    build: (a, b, c) => {
      const s1 = a + c;
      const s2 = a + b;
      const s3 = a + b + c;
      const average = Math.round((s1 + s2 + s3) / 3);
      const code = average + c;
      return {
        prompt: `Tre sensori leggono ${s1}, ${s2} e ${s3}. Il codice è la media arrotondata all'intero più vicino, poi +${c} per compensare la dispersione. Quale codice inserisci?`,
        answer: code,
        hints: [
          "Prima somma le tre letture: non scegliere il sensore più alto.",
          "Dividi la somma per 3 e arrotonda solo dopo aver diviso.",
          `La compensazione +${c} arriva alla fine.`,
        ],
        steps: [
          `${s1} + ${s2} + ${s3} = ${s1 + s2 + s3}`,
          `${s1 + s2 + s3} / 3 = ${(s1 + s2 + s3) / 3}`,
          `media arrotondata = ${average}`,
          `${average} + ${c} = ${code}`,
        ],
      };
    },
  },
  {
    id: "energy-budget-choice",
    title: "Budget di energia",
    narrative: "La porta apre solo se resta energia dopo aver alimentato due sottosistemi.",
    minComplexity: 5,
    archetype: "vincolo",
    build: (a, b, c) => {
      const reserve = a + b + c;
      const terminalCost = b * 2;
      const robotCost = a - c;
      const remaining = reserve - terminalCost - robotCost;
      const recharge = remaining < 10 ? 10 - remaining : 0;
      const answer = remaining + recharge;
      return {
        prompt: `La riserva è ${reserve}. Il terminale consuma ${terminalCost}, il robot consuma ${robotCost}. Se il residuo scende sotto 10, devi ricaricare fino a 10. Quale valore finale deve leggere il pannello?`,
        answer,
        hints: [
          "Calcola prima quanto resta dopo i due consumi.",
          "Confronta il residuo con la soglia 10.",
          "Se è sotto soglia, il valore finale non è il residuo: è la soglia minima.",
        ],
        steps: [
          `${reserve} - ${terminalCost} = ${reserve - terminalCost}`,
          `${reserve - terminalCost} - ${robotCost} = ${remaining}`,
          remaining < 10 ? `${remaining} e sotto 10, quindi ricarica fino a 10` : `${remaining} supera la soglia 10`,
          `valore finale = ${answer}`,
        ],
      };
    },
  },
  {
    id: "ratio-cooling-loop",
    title: "Proporzione del radiatore",
    narrative: "Il radiatore non scala a caso: ogni modulo acceso consuma la stessa quota d'acqua.",
    minComplexity: 6,
    archetype: "proporzione",
    build: (a, b, c) => {
      const modules = Math.max(3, c);
      const waterPerModule = Math.max(4, Math.floor(b / 2));
      const activeModules = modules + 2;
      const reserve = activeModules * waterPerModule + a;
      const remaining = reserve - modules * waterPerModule;
      return {
        prompt: `${modules} moduli usano ${modules * waterPerModule} unità d'acqua. Ora sono attivi ${activeModules} moduli e la riserva è ${reserve}. Dopo aver alimentato solo ${modules} moduli, quanta acqua resta?`,
        answer: remaining,
        hints: [
          "Trova prima quanta acqua usa un solo modulo.",
          `Se ${modules} moduli usano ${modules * waterPerModule}, ogni modulo usa ${waterPerModule}.`,
          `Per ${modules} moduli sottrai ${modules * waterPerModule} dalla riserva ${reserve}.`,
        ],
        steps: [
          `${modules * waterPerModule} / ${modules} = ${waterPerModule}`,
          `${modules} x ${waterPerModule} = ${modules * waterPerModule}`,
          `${reserve} - ${modules * waterPerModule} = ${remaining}`,
        ],
      };
    },
  },
  {
    id: "parentheses-power-gate",
    title: "Porta con parentesi",
    narrative: "La porta legge i blocchi in ordine: prima il gruppo interno, poi il moltiplicatore.",
    minComplexity: 6,
    archetype: "pre-algebra",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(5, c));
      const inside = a - b;
      const answer = inside * multiplier + c;
      return {
        prompt: `Il codice segue questa procedura: (${a} - ${b}) x ${multiplier} + ${c}. Quale valore stabilizza la porta?`,
        answer,
        hints: [
          "La parentesi è il primo blocco da risolvere.",
          `Dopo la parentesi moltiplica per ${multiplier}.`,
          `Il +${c} si applica solo alla fine.`,
        ],
        steps: [`${a} - ${b} = ${inside}`, `${inside} x ${multiplier} = ${inside * multiplier}`, `${inside * multiplier} + ${c} = ${answer}`],
      };
    },
  },
  {
    id: "hidden-input-equation",
    title: "Ingresso cancellato",
    narrative: "Il registro finale è leggibile, ma il numero iniziale è stato cancellato dalla macchina.",
    minComplexity: 7,
    archetype: "pre-algebra",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(5, c));
      const output = (a - b) * multiplier;
      return {
        prompt: `Un numero entra nella macchina. Prima viene diminuito di ${b}, poi moltiplicato per ${multiplier}. L'uscita è ${output}. Qual era il numero iniziale?`,
        answer: a,
        hints: [
          "Risolvi la macchina al contrario.",
          `Annulla la moltiplicazione: ${output} / ${multiplier}.`,
          `Se prima il numero era stato diminuito di ${b}, alla fine devi riaggiungerlo.`,
        ],
        steps: [`${output} / ${multiplier} = ${a - b}`, `${a - b} + ${b} = ${a}`],
      };
    },
  },
  {
    id: "signed-temperature-offset",
    title: "Camera criogenica",
    narrative: "La fabbrica usa anche numeri sotto zero: la temperatura è un segnale, non un errore.",
    minComplexity: 7,
    archetype: "vincolo",
    build: (a, b, c) => {
      const start = -Math.max(4, c + 2);
      const cooling = Math.max(3, Math.floor(a / 3));
      const heat = Math.max(7, b, Math.abs(start) + cooling + 2);
      const answer = start + heat - cooling;
      return {
        prompt: `La camera parte da ${start} gradi. Si riscalda di ${heat} gradi e poi si raffredda di ${cooling} gradi. Quale temperatura finale deve leggere il sensore?`,
        answer,
        hints: [
          "Partire sotto zero significa che devi muoverti sulla linea dei numeri.",
          `Aggiungi ${heat}: ti sposti verso destra.`,
          `Poi sottrai ${cooling}: ti sposti indietro.`,
        ],
        steps: [`${start} + ${heat} = ${start + heat}`, `${start + heat} - ${cooling} = ${answer}`],
      };
    },
  },
  {
    id: "error-control-two-logs",
    title: "Doppio log sospetto",
    narrative: "Due tecnici hanno registrato risultati diversi: solo uno rispetta l'ordine delle operazioni.",
    minComplexity: 8,
    archetype: "diagnosi-errore",
    build: (a, b, c) => {
      const multiplier = Math.max(2, Math.min(4, c));
      const correct = a + b * multiplier - c;
      const wrong = (a + b) * multiplier - c;
      return {
        prompt: `Il protocollo dice: ${a} + ${b} x ${multiplier} - ${c}. Il log A segna ${wrong}, il log B segna ${correct}. Quale valore va certificato?`,
        answer: correct,
        hints: [
          "Moltiplicazione prima di addizione, anche senza parentesi.",
          `Calcola ${b} x ${multiplier} prima di sommare ${a}.`,
          "Il log che somma prima sta cambiando la regola del protocollo.",
        ],
        steps: [`${b} x ${multiplier} = ${b * multiplier}`, `${a} + ${b * multiplier} = ${a + b * multiplier}`, `${a + b * multiplier} - ${c} = ${correct}`],
      };
    },
  },
  {
    id: "fraction-reserve-split",
    title: "Ripartitore di frazioni",
    narrative: "La riserva non va consumata a caso: due reparti prendono quote diverse dello stesso totale.",
    minComplexity: 3,
    archetype: "frazioni",
    competencies: ["matematica.frazioni", "matematica.calcolo", "matematica.logica"],
    curriculumTags: ["frazioni", "complemento all'intero", "problema a piu passaggi"],
    build: (a, b, c) => {
      const total = (a + b + c) * 6;
      const half = total / 2;
      const third = total / 3;
      const remaining = total - half - third;
      return {
        prompt: `La riserva ha ${total} unita. Il nucleo usa metà della riserva e il radiatore ne usa un terzo. Quante unita restano nel serbatoio?`,
        answer: remaining,
        hints: [
          "Metà e un terzo sono quote dello stesso totale, non del resto.",
          `${total} / 2 = ${half} e ${total} / 3 = ${third}.`,
          "Sottrai entrambe le quote dal totale iniziale.",
        ],
        steps: [`${total} / 2 = ${half}`, `${total} / 3 = ${third}`, `${total} - ${half} - ${third} = ${remaining}`],
      };
    },
  },
  {
    id: "ratio-crystal-mix",
    title: "Miscela in rapporto",
    narrative: "Il miscelatore lavora con rapporti: se cambi la scala, la relazione deve restare uguale.",
    minComplexity: 4,
    archetype: "proporzione",
    competencies: ["matematica.frazioni", "matematica.logica", "problemSolving"],
    curriculumTags: ["rapporti", "proporzioni", "scalare una ricetta"],
    build: (a, b, c) => {
      const blueParts = 2 + (c % 3);
      const goldParts = blueParts + 1;
      const factor = Math.max(3, Math.floor((a + b) / 6));
      const blue = blueParts * factor;
      const gold = goldParts * factor;
      const total = blue + gold;
      return {
        prompt: `La miscela richiede rapporto ${blueParts}:${goldParts} tra cristalli blu e oro. Il sistema ha ${blue} cristalli blu. Quanti cristalli totali avrà la miscela corretta?`,
        answer: total,
        hints: [
          `Se ${blueParts} parti blu diventano ${blue}, il fattore di scala è ${factor}.`,
          `Le parti oro sono ${goldParts}, quindi servono ${goldParts} x ${factor}.`,
          "Il totale è blu più oro.",
        ],
        steps: [`${blue} / ${blueParts} = ${factor}`, `${goldParts} x ${factor} = ${gold}`, `${blue} + ${gold} = ${total}`],
      };
    },
  },
  {
    id: "percent-energy-boost",
    title: "Percentuale di carica",
    narrative: "Il pannello mostra una carica che aumenta in percentuale, poi perde una quota fissa durante il trasferimento.",
    minComplexity: 4,
    archetype: "percentuali",
    competencies: ["matematica.percentuali", "matematica.calcolo", "matematica.controlloErrore"],
    curriculumTags: ["percentuali", "aumento percentuale", "sottrazione finale"],
    build: (a, b, c) => {
      const base = (a + b) * 20;
      const percent = c % 2 === 0 ? 25 : 20;
      const boosted = base + (base * percent) / 100;
      const transferLoss = c * 5;
      const answer = boosted - transferLoss;
      return {
        prompt: `La batteria contiene ${base} unita. Un amplificatore aggiunge il ${percent}%, poi il trasferimento consuma ${transferLoss} unita. Quale valore resta?`,
        answer,
        hints: [
          `Calcola prima il ${percent}% di ${base}.`,
          "Aggiungi la percentuale al valore iniziale.",
          `Solo dopo sottrai la perdita fissa di ${transferLoss}.`,
        ],
        steps: [`${percent}% di ${base} = ${(base * percent) / 100}`, `${base} + ${(base * percent) / 100} = ${boosted}`, `${boosted} - ${transferLoss} = ${answer}`],
      };
    },
  },
  {
    id: "rectangle-panel-code",
    title: "Pannello geometrico",
    narrative: "La porta misura una lastra: area e perimetro raccontano due proprietà diverse dello stesso oggetto.",
    minComplexity: 4,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.calcolo", "matematica.espressioni"],
    curriculumTags: ["rettangoli", "area", "perimetro"],
    build: (a, b, c) => {
      const width = Math.max(5, c + 4);
      const height = Math.max(6, Math.floor(b / 2) + 3);
      const area = width * height;
      const perimeter = 2 * (width + height);
      const answer = area + perimeter;
      return {
        prompt: `Una lastra rettangolare misura ${width} per ${height}. Il codice è area più perimetro. Quale codice inserisci?`,
        answer,
        hints: [
          "Area e perimetro non sono la stessa cosa.",
          `Area = ${width} x ${height}.`,
          `Perimetro = 2 x (${width} + ${height}).`,
        ],
        steps: [`area = ${width} x ${height} = ${area}`, `perimetro = 2 x (${width} + ${height}) = ${perimeter}`, `${area} + ${perimeter} = ${answer}`],
      };
    },
  },
  {
    id: "coordinate-manhattan-route",
    title: "Coordinate del drone",
    narrative: "Il drone non vola in diagonale: deve contare spostamenti orizzontali e verticali sulla griglia.",
    minComplexity: 5,
    archetype: "coordinate",
    competencies: ["matematica.geometria", "matematica.logica", "coding.sequenze"],
    curriculumTags: ["piano cartesiano", "coordinate", "distanza su griglia"],
    build: (a, b, c) => {
      const startX = c;
      const startY = Math.max(2, c - 1);
      const endX = startX + Math.max(3, Math.floor(b / 3));
      const endY = startY + Math.max(2, Math.floor(a / 5));
      const distance = Math.abs(endX - startX) + Math.abs(endY - startY);
      return {
        prompt: `Il drone parte da (${startX}, ${startY}) e deve arrivare a (${endX}, ${endY}) senza diagonali. Quanti passi minimi servono?`,
        answer: distance,
        hints: [
          "Conta separatamente spostamento orizzontale e verticale.",
          `Orizzontale: ${endX} - ${startX}.`,
          `Verticale: ${endY} - ${startY}.`,
        ],
        steps: [`dx = ${endX - startX}`, `dy = ${endY - startY}`, `${endX - startX} + ${endY - startY} = ${distance}`],
      };
    },
  },
  {
    id: "median-range-log",
    title: "Log statistico",
    narrative: "Il terminale non vuole il dato più vistoso: vuole una lettura stabile tra valori ordinati.",
    minComplexity: 5,
    archetype: "statistica",
    competencies: ["matematica.statistica", "matematica.grafici", "pensieroCritico"],
    curriculumTags: ["mediana", "range", "dati ordinati"],
    build: (a, b, c) => {
      const v1 = c + 4;
      const v2 = v1 + Math.max(2, Math.floor(b / 4));
      const v3 = v2 + Math.max(2, Math.floor(a / 6));
      const v4 = v3 + c;
      const v5 = v4 + 3;
      const median = v3;
      const range = v5 - v1;
      const answer = median + range;
      return {
        prompt: `I sensori ordinati leggono ${v1}, ${v2}, ${v3}, ${v4}, ${v5}. Il codice è mediana più intervallo massimo-minimo. Quale codice ottieni?`,
        answer,
        hints: [
          "Con cinque dati ordinati, la mediana è il valore centrale.",
          `L'intervallo è ${v5} - ${v1}.`,
          "Somma mediana e intervallo solo alla fine.",
        ],
        steps: [`mediana = ${median}`, `range = ${v5} - ${v1} = ${range}`, `${median} + ${range} = ${answer}`],
      };
    },
  },
  {
    id: "probability-capsule-forecast",
    title: "Previsione di capsule",
    narrative: "Il selettore usa probabilità sperimentale: da un rapporto previsto devi stimare quante capsule arriveranno.",
    minComplexity: 6,
    archetype: "probabilita",
    competencies: ["matematica.probabilita", "matematica.frazioni", "matematica.logica"],
    curriculumTags: ["probabilita", "frequenza attesa", "rapporto"],
    build: (a, b, c) => {
      const total = (c + 4) * 6;
      const favorable = total / 3;
      const inspected = Math.max(18, Math.floor((a + b) / 3) * 6);
      const expected = inspected / 3;
      return {
        prompt: `Nel selettore, ${favorable} capsule su ${total} sono blu. Se il robot controlla ${inspected} capsule con lo stesso rapporto, quante capsule blu si aspetta?`,
        answer: expected,
        hints: [
          `Il rapporto ${favorable}/${total} si semplifica a 1/3.`,
          `Devi trovare un terzo di ${inspected}.`,
          "Non serve contare capsule una per una: usa il rapporto.",
        ],
        steps: [`${favorable}/${total} = 1/3`, `${inspected} / 3 = ${expected}`],
      };
    },
  },
  {
    id: "square-root-door",
    title: "Radice della camera",
    narrative: "La stanza nasconde il lato di un quadrato dentro la sua area.",
    minComplexity: 6,
    archetype: "potenze-radici",
    competencies: ["matematica.potenzeRadici", "matematica.geometria", "matematica.algebra"],
    curriculumTags: ["quadrati perfetti", "radice quadrata", "area"],
    build: (a, b, c) => {
      const side = Math.max(6, c + 5);
      const area = side * side;
      const offset = Math.max(3, Math.floor(b / 3));
      const answer = side + offset;
      return {
        prompt: `Una camera quadrata ha area ${area}. Il codice è il lato della camera più ${offset}. Quale codice inserisci?`,
        answer,
        hints: [
          "Per un quadrato, lato x lato = area.",
          `La radice quadrata di ${area} è ${side}.`,
          `Dopo aver trovato il lato, aggiungi ${offset}.`,
        ],
        steps: [`radice di ${area} = ${side}`, `${side} + ${offset} = ${answer}`],
      };
    },
  },
  {
    id: "linear-function-terminal",
    title: "Funzione del terminale",
    narrative: "Il terminale trasforma ogni ingresso con la stessa regola lineare.",
    minComplexity: 6,
    archetype: "funzione-lineare",
    competencies: ["matematica.funzioni", "matematica.algebra", "matematica.espressioni"],
    curriculumTags: ["funzioni lineari", "sostituzione", "modello ingresso-uscita"],
    build: (a, b, c) => {
      const m = Math.max(2, Math.min(5, c));
      const x = Math.max(3, Math.floor(a / 4));
      const q = b;
      const y = m * x + q;
      return {
        prompt: `Il terminale usa la funzione y = ${m}x + ${q}. Se x = ${x}, quale uscita y viene generata?`,
        answer: y,
        hints: [
          `Sostituisci x con ${x}.`,
          `Prima calcola ${m} x ${x}.`,
          `Poi aggiungi ${q}.`,
        ],
        steps: [`${m} x ${x} = ${m * x}`, `${m * x} + ${q} = ${y}`],
      };
    },
  },
  {
    id: "two-drones-system",
    title: "Sistema dei due droni",
    narrative: "Due droni nascondono i propri carichi, ma il terminale conosce somma e differenza.",
    minComplexity: 7,
    archetype: "sistemi-lineari",
    competencies: ["matematica.algebra", "matematica.logica", "problemSolving"],
    curriculumTags: ["sistemi lineari", "somma e differenza", "incognite"],
    build: (a, b) => {
      const droneA = a + b;
      const droneB = a;
      const total = droneA + droneB;
      const difference = droneA - droneB;
      return {
        prompt: `Due droni trasportano carichi diversi. Insieme hanno ${total} unita; il primo ha ${difference} unita in più del secondo. Quante unita porta il primo drone?`,
        answer: droneA,
        hints: [
          "Se togli la differenza dalla somma, restano due carichi uguali al secondo drone.",
          `Calcola (${total} - ${difference}) / 2 per trovare il secondo drone.`,
          `Poi aggiungi la differenza ${difference}.`,
        ],
        steps: [`(${total} - ${difference}) / 2 = ${droneB}`, `${droneB} + ${difference} = ${droneA}`],
      };
    },
  },
  {
    id: "pythagorean-cable",
    title: "Cavo diagonale",
    narrative: "La manutenzione deve tendere un cavo diagonale: i due lati della griglia formano un triangolo rettangolo.",
    minComplexity: 8,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.potenzeRadici", "problemSolving"],
    curriculumTags: ["teorema di Pitagora", "triangolo rettangolo", "distanza"],
    build: (_a, _b, c) => {
      const scale = Math.max(2, Math.min(5, Math.floor(c / 2)));
      const sideA = 3 * scale;
      const sideB = 4 * scale;
      const hypotenuse = 5 * scale;
      return {
        prompt: `Due guide perpendicolari misurano ${sideA} e ${sideB}. Il cavo diagonale usa il triangolo 3-4-5 in scala. Quanto è lungo il cavo?`,
        answer: hypotenuse,
        hints: [
          "Riconosci una terna pitagorica scalata.",
          `${sideA}, ${sideB}, ? corrispondono a 3, 4, 5 moltiplicati per ${scale}.`,
          `La diagonale è 5 x ${scale}.`,
        ],
        steps: [`scala = ${scale}`, `diagonale = 5 x ${scale} = ${hypotenuse}`],
      };
    },
  },
  {
    id: "exponential-signal-doubling",
    title: "Segnale esponenziale",
    narrative: "Un segnale di test raddoppia a ogni ciclo: all'inizio sembra lento, poi cresce molto rapidamente.",
    minComplexity: 8,
    archetype: "potenze-radici",
    competencies: ["matematica.potenzeRadici", "matematica.funzioni", "pensieroCritico"],
    curriculumTags: ["potenze di 2", "crescita esponenziale", "modello discreto"],
    build: (_a, _b, c) => {
      const start = Math.max(2, Math.min(8, c));
      const cycles = c % 2 === 0 ? 4 : 3;
      const multiplier = 2 ** cycles;
      const answer = start * multiplier;
      return {
        prompt: `Il segnale parte da ${start} unita e raddoppia per ${cycles} cicli. Quale valore raggiunge alla fine?`,
        answer,
        hints: [
          `Raddoppiare per ${cycles} cicli significa moltiplicare per 2^${cycles}.`,
          `2^${cycles} = ${multiplier}.`,
          `Moltiplica ${start} per ${multiplier}.`,
        ],
        steps: [`2^${cycles} = ${multiplier}`, `${start} x ${multiplier} = ${answer}`],
      };
    },
  },
  {
    id: "scientific-notation-decoder",
    title: "Decodificatore scientifico",
    narrative: "L'archivio compatta numeri grandi con potenze di dieci: bisogna espanderli senza perdere zeri.",
    minComplexity: 8,
    archetype: "potenze-radici",
    competencies: ["matematica.potenzeRadici", "matematica.calcolo", "matematica.controlloErrore"],
    curriculumTags: ["potenze di dieci", "notazione scientifica", "ordine di grandezza"],
    build: (_a, _b, c) => {
      const mantissa = Math.max(2, Math.min(9, c));
      const exponent = c % 2 === 0 ? 3 : 2;
      const answer = mantissa * 10 ** exponent;
      return {
        prompt: `Il registro compresso mostra ${mantissa} x 10^${exponent}. Quale numero intero deve comparire nel terminale esteso?`,
        answer,
        hints: [
          `10^${exponent} sposta il valore di ${exponent} posizioni decimali.`,
          `10^${exponent} = ${10 ** exponent}.`,
          `Moltiplica ${mantissa} per ${10 ** exponent}.`,
        ],
        steps: [`10^${exponent} = ${10 ** exponent}`, `${mantissa} x ${10 ** exponent} = ${answer}`],
      };
    },
  },
  {
    id: "linear-equation-balance",
    title: "Bilancia a incognita",
    narrative: "La console mostra una bilancia energetica: i due lati devono restare equivalenti.",
    minComplexity: 4,
    archetype: "equazione-primo-grado",
    competencies: ["matematica.algebra", "matematica.logica", "matematica.controlloErrore"],
    curriculumTags: ["equazioni di primo grado", "operazioni inverse", "incognita"],
    build: (a, b, c) => {
      const x = Math.max(4, c + 3);
      const coefficient = 2 + (b % 4);
      const addend = Math.max(3, Math.floor(a / 3));
      const total = coefficient * x + addend;
      return {
        prompt: `La bilancia legge ${coefficient}x + ${addend} = ${total}. Quale valore di x mantiene il sistema in equilibrio?`,
        answer: x,
        hints: [
          `Prima togli ${addend} da entrambi i lati.`,
          `${total} - ${addend} = ${total - addend}.`,
          `Poi dividi per il coefficiente ${coefficient}.`,
        ],
        steps: [`${coefficient}x + ${addend} = ${total}`, `${coefficient}x = ${total - addend}`, `x = ${total - addend} / ${coefficient} = ${x}`],
      };
    },
  },
  {
    id: "equation-with-parentheses",
    title: "Equazione con parentesi",
    narrative: "Il portello usa un'equazione compatta: prima devi espandere il blocco tra parentesi.",
    minComplexity: 6,
    archetype: "equazione-primo-grado",
    competencies: ["matematica.algebra", "matematica.espressioni", "matematica.controlloErrore"],
    curriculumTags: ["equazioni di primo grado", "parentesi", "proprieta distributiva"],
    build: (a, b, c) => {
      const x = Math.max(5, c + 4);
      const multiplier = 2 + (c % 3);
      const shift = Math.max(2, Math.floor(b / 4));
      const right = multiplier * (x + shift);
      return {
        prompt: `Il portello registra ${multiplier}(x + ${shift}) = ${right}. Quale valore di x sblocca il registro?`,
        answer: x,
        hints: [
          `Dividi prima entrambi i lati per ${multiplier}.`,
          `${right} / ${multiplier} = ${x + shift}.`,
          `Se resta x + ${shift}, togli ${shift}.`,
        ],
        steps: [`${multiplier}(x + ${shift}) = ${right}`, `x + ${shift} = ${right / multiplier}`, `x = ${right / multiplier} - ${shift} = ${x}`],
      };
    },
  },
  {
    id: "composite-area-panel",
    title: "Lastra composta",
    narrative: "La porta non e un rettangolo solo: e fatta da due pannelli affiancati con misure diverse.",
    minComplexity: 5,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.espressioni", "problemSolving"],
    curriculumTags: ["geometria composta", "area", "scomposizione"],
    build: (a, b, c) => {
      const h = Math.max(5, c + 4);
      const w1 = Math.max(4, Math.floor(a / 4));
      const w2 = Math.max(3, Math.floor(b / 4));
      const area = h * w1 + h * w2;
      return {
        prompt: `La lastra e composta da due rettangoli alti ${h}. Il primo e largo ${w1}, il secondo e largo ${w2}. Qual e l'area totale?`,
        answer: area,
        hints: [
          "Scomponi la figura in due rettangoli.",
          `Area 1 = ${h} x ${w1}; area 2 = ${h} x ${w2}.`,
          "Somma le due aree solo alla fine.",
        ],
        steps: [`${h} x ${w1} = ${h * w1}`, `${h} x ${w2} = ${h * w2}`, `${h * w1} + ${h * w2} = ${area}`],
      };
    },
  },
  {
    id: "triangle-area-shield",
    title: "Scudo triangolare",
    narrative: "Uno scudo di emergenza ha forma triangolare: la base non basta, serve anche l'altezza.",
    minComplexity: 5,
    archetype: "geometria",
    competencies: ["matematica.geometria", "matematica.frazioni", "matematica.calcolo"],
    curriculumTags: ["triangoli", "area", "base e altezza"],
    build: (a, b, c) => {
      const base = 2 * Math.max(4, c + 2);
      const height = Math.max(5, Math.floor(b / 2));
      const area = (base * height) / 2;
      return {
        prompt: `Lo scudo triangolare ha base ${base} e altezza ${height}. Qual e la sua area?`,
        answer: area,
        hints: [
          "Per un triangolo non basta base x altezza: va diviso per 2.",
          `${base} x ${height} = ${base * height}.`,
          `Poi dividi per 2.`,
        ],
        steps: [`base x altezza = ${base} x ${height} = ${base * height}`, `${base * height} / 2 = ${area}`],
      };
    },
  },
  {
    id: "cartesian-midpoint-code",
    title: "Nodo medio cartesiano",
    narrative: "Due fari segnano gli estremi di un corridoio: il terminale vuole il punto centrale del tratto.",
    minComplexity: 5,
    archetype: "coordinate",
    competencies: ["matematica.geometria", "matematica.algebra", "problemSolving"],
    curriculumTags: ["piano cartesiano", "punto medio", "coordinate"],
    build: (a, b, c) => {
      const x1 = c;
      const y1 = Math.max(2, c - 1);
      const x2 = x1 + 2 * Math.max(2, Math.floor(a / 6));
      const y2 = y1 + 2 * Math.max(2, Math.floor(b / 6));
      const midX = (x1 + x2) / 2;
      const midY = (y1 + y2) / 2;
      const answer = midX + midY;
      return {
        prompt: `I fari sono in A(${x1}, ${y1}) e B(${x2}, ${y2}). Il codice e la somma delle coordinate del punto medio. Quale codice inserisci?`,
        answer,
        hints: [
          "Il punto medio fa la media delle x e la media delle y.",
          `x medio = (${x1} + ${x2}) / 2.`,
          `y medio = (${y1} + ${y2}) / 2; poi somma le due coordinate.`,
        ],
        steps: [`x medio = (${x1} + ${x2}) / 2 = ${midX}`, `y medio = (${y1} + ${y2}) / 2 = ${midY}`, `${midX} + ${midY} = ${answer}`],
      };
    },
  },
  {
    id: "cartesian-slope-ramp",
    title: "Pendenza della rampa",
    narrative: "Una rampa luminosa collega due nodi: il terminale misura quanto sale per ogni passo orizzontale.",
    minComplexity: 6,
    archetype: "coordinate",
    competencies: ["matematica.funzioni", "matematica.geometria", "matematica.logica"],
    curriculumTags: ["piano cartesiano", "pendenza", "variazione"],
    build: (a, b, c) => {
      const x1 = c;
      const y1 = Math.max(2, c + 1);
      const dx = Math.max(2, Math.min(5, Math.floor(b / 4)));
      const slope = Math.max(2, Math.min(5, Math.floor(a / 5)));
      const x2 = x1 + dx;
      const y2 = y1 + dx * slope;
      return {
        prompt: `La rampa va da A(${x1}, ${y1}) a B(${x2}, ${y2}). La pendenza e aumento verticale diviso aumento orizzontale. Quale pendenza legge il terminale?`,
        answer: slope,
        hints: [
          `Aumento orizzontale: ${x2} - ${x1}.`,
          `Aumento verticale: ${y2} - ${y1}.`,
          "Dividi aumento verticale per aumento orizzontale.",
        ],
        steps: [`dx = ${x2} - ${x1} = ${dx}`, `dy = ${y2} - ${y1} = ${dx * slope}`, `pendenza = ${dx * slope} / ${dx} = ${slope}`],
      };
    },
  },
  {
    id: "probability-complement",
    title: "Probabilita complementare",
    narrative: "Il selettore non chiede quante capsule funzionano: chiede quante potrebbero fallire.",
    minComplexity: 5,
    archetype: "probabilita",
    competencies: ["matematica.probabilita", "matematica.frazioni", "pensieroCritico"],
    curriculumTags: ["probabilita", "evento complementare", "frequenza attesa"],
    build: (a, b, c) => {
      const total = Math.max(24, (c + 6) * 6);
      const success = Math.floor(total * 2 / 3);
      const checked = Math.max(18, Math.floor((a + b) / 3) * 6);
      const failExpected = checked / 3;
      return {
        prompt: `Nel lotto, ${success} capsule su ${total} funzionano: le altre sono difettose. Se il robot controlla ${checked} capsule con lo stesso rapporto, quante difettose si aspetta?`,
        answer: failExpected,
        hints: [
          "Se 2/3 funzionano, il complemento difettoso e 1/3.",
          `Devi calcolare un terzo di ${checked}.`,
          "La domanda chiede le difettose, non quelle funzionanti.",
        ],
        steps: [`probabilita difettosa = 1 - 2/3 = 1/3`, `${checked} / 3 = ${failExpected}`],
      };
    },
  },
  {
    id: "probability-two-stage-selector",
    title: "Selettore a due stadi",
    narrative: "Un selettore controlla prima il colore e poi il simbolo: per passare servono entrambe le condizioni.",
    minComplexity: 7,
    archetype: "probabilita",
    competencies: ["matematica.probabilita", "matematica.frazioni", "matematica.logica"],
    curriculumTags: ["probabilita composta", "eventi indipendenti", "frazioni"],
    build: (a, b, c) => {
      const batch = Math.max(24, (c + 6) * 8);
      const colorDen = 4;
      const symbolDen = 2;
      const expected = batch / (colorDen * symbolDen);
      return {
        prompt: `In un lotto di ${batch} tessere, 1 su ${colorDen} ha il colore giusto. Tra quelle, 1 su ${symbolDen} ha anche il simbolo corretto. Quante tessere superano entrambi i controlli?`,
        answer: expected,
        hints: [
          "Servono entrambe le condizioni: non devi sommare le probabilita.",
          `1/${colorDen} e poi 1/${symbolDen} diventano 1/${colorDen * symbolDen}.`,
          `Calcola ${batch} / ${colorDen * symbolDen}.`,
        ],
        steps: [`1/${colorDen} x 1/${symbolDen} = 1/${colorDen * symbolDen}`, `${batch} / ${colorDen * symbolDen} = ${expected}`],
      };
    },
  },
];
