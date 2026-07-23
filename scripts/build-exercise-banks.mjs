// Bake dei banchi di esercizi → godot/data/banks/*.json
//
// Fase 1 del full-Godot (vedi docs/ARCHITETTURA_FULL_GODOT.md, strategia "bake
// prima, port poi"): produce banchi JSON di ExerciseItem che Godot carica
// on-demand. C-12: ogni materia riusa il generatore/dato REALE di src/, non
// liste scritte a mano — così il contenuto è quello già validato per il
// prototipo Phaser, non un doppione.
//
// Fonti per materia:
//  - matematica: generatore locale (ora superato dal nativo
//    godot/scripts/game/math_exercise_generator.gd — bank tenuto per fallback)
//  - italiano/inglese: src/data/procedural/{italian,english}VocabularyBank.ts
//  - latino: src/data/procedural/latinCurriculum.ts (declinazioni, con
//    distinctiveCases() per evitare forme ambigue)
//  - elettronica: src/data/procedural/circuitTemplates.ts (componenti/guasti)
//  - coding: src/data/procedural/pythonPrinciples.ts (già item-shaped)
//  - fisica/musica: nessun generatore in Phaser (solo teoria) → curate a mano
//    da src/data/theoryCatalog.ts (definition/example/watchOut reali, non
//    inventati). Node non risolve gli import relativi senza estensione di
//    theoryCatalog.ts, quindi qui sono trascritti letteralmente dalla fonte.
//
// Uso: node scripts/build-exercise-banks.mjs

import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";
import { mkdir, writeFile } from "node:fs/promises";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const outDir = join(root, "godot", "data", "banks");

const shuffle = (arr, rand) => {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

// PRNG deterministico (mulberry32) così il banco è stabile tra build.
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a += 0x6d2b79f5;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pickDistractors(pool, exclude, count, rand) {
  const candidates = pool.filter((v) => v !== exclude);
  const unique = [...new Set(candidates)];
  return shuffle(unique, rand).slice(0, count);
}

function multipleChoiceItem({ id, subject, topic, difficulty, prompt, answer, distractors, explanation }, rand) {
  const options = shuffle([answer, ...distractors], rand);
  return { id, subject, topic, difficulty, format: "multiple_choice", prompt, options, answer, explanation };
}

// ---------------------------------------------------------------------------
// Matematica: generatore locale di tabelline (invariato, vedi nota in testa).
// ---------------------------------------------------------------------------

const RANGES = { 1: [2, 5], 2: [2, 10], 3: [3, 12], 4: [6, 12] };

function timesItem(a, b, difficulty, rand) {
  const answer = a * b;
  const useNumeric = rand() < 0.25;
  const explanation = `${a} × ${b} = ${answer}.`;
  const base = {
    id: `math-times-${a}x${b}-d${difficulty}`,
    subject: "matematica",
    topic: "tabelline",
    difficulty,
    prompt: `Quanto fa ${a} × ${b}?`,
    answer: String(answer),
    explanation,
  };
  if (useNumeric) return { ...base, format: "numeric_input", options: [] };
  const distractors = new Set();
  const candidates = [answer + a, answer - a, answer + b, answer - b, answer + 1, answer - 1, a * (b + 1), (a + 1) * b];
  for (const c of candidates) {
    if (c > 0 && c !== answer) distractors.add(c);
    if (distractors.size >= 3) break;
  }
  const options = shuffle([answer, ...[...distractors].slice(0, 3)], rand).map(String);
  return { ...base, format: "multiple_choice", options };
}

function tabellineBank() {
  const rand = rng(20260720);
  const items = [];
  for (const difficulty of [1, 2, 3, 4]) {
    const [lo, hi] = RANGES[difficulty];
    for (let a = lo; a <= hi; a += 1) {
      for (let b = 2; b <= hi; b += 1) {
        items.push(timesItem(a, b, difficulty, rand));
      }
    }
  }
  return { schemaVersion: 1, subject: "matematica", topic: "tabelline", generator: "tabelline-v1", items };
}

// ---------------------------------------------------------------------------
// Italiano / Inglese: vocabolari reali (term/clue|meaning, wordClass, level).
// ---------------------------------------------------------------------------

function levelToDifficulty(level) {
  return Math.min(4, Math.max(1, Math.ceil(level / 2)));
}

// I distrattori DEVONO essere nella stessa lingua/campo della risposta: se la
// domanda chiede la traduzione italiana, le opzioni sbagliate devono essere altre
// parole italiane (della stessa classe grammaticale), non parole inglesi — altrimenti
// la risposta è l'unica nella lingua giusta e diventa banale. `promptFor` indica con
// `field` da quale campo pescare i distrattori; qui costruiamo un pool per campo.
function vocabularyBank(subject, entries, { fields, defField, promptFor }) {
  const rand = rng(subject === "italiano" ? 20260721 : 20260722);
  const pools = new Map(); // field -> Map(wordClass -> valori[])
  for (const field of fields) {
    const byClass = new Map();
    for (const entry of entries) {
      const list = byClass.get(entry.wordClass) ?? [];
      list.push(entry[field]);
      byClass.set(entry.wordClass, list);
    }
    pools.set(field, byClass);
  }
  const items = [];
  entries.forEach((entry, index) => {
    const { prompt, answer, field } = promptFor(entry, index);
    const pool = pools.get(field).get(entry.wordClass) ?? [];
    const distractors = pickDistractors(pool, answer, 3, rand);
    if (distractors.length < 3) return; // classe troppo piccola, salta (nessun distrattore fittizio)
    items.push(
      multipleChoiceItem(
        {
          id: `${subject}-${entry.id}`,
          subject,
          topic: entry.category,
          difficulty: levelToDifficulty(entry.level),
          prompt,
          answer,
          distractors,
          explanation: `"${entry.term}": ${entry[defField]}.`,
        },
        rand,
      ),
    );
  });
  return { schemaVersion: 1, subject, generator: "vocabulary-bank-v2", items };
}

function italianoBank(entries) {
  return vocabularyBank("italiano", entries, {
    fields: ["term"],
    defField: "clue",
    // risposta = parola italiana; distrattori = altre parole italiane (campo "term").
    promptFor: (entry) => ({ prompt: `Quale parola corrisponde a: "${entry.clue}"?`, answer: entry.term, field: "term" }),
  });
}

function ingleseBank(entries) {
  return vocabularyBank("inglese", entries, {
    fields: ["term", "meaning"],
    defField: "meaning",
    // Alterna le due direzioni; i distrattori vengono SEMPRE dal campo della risposta:
    //  - "come si dice in inglese?" → risposta inglese, distrattori inglesi (term)
    //  - "cosa significa in italiano?" → risposta italiana, distrattori italiani (meaning)
    promptFor: (entry, index) =>
      index % 2 === 0
        ? { prompt: `Come si dice in inglese: "${entry.meaning}"?`, answer: entry.term, field: "term" }
        : { prompt: `Cosa significa in italiano "${entry.term}"?`, answer: entry.meaning, field: "meaning" },
  });
}

// ---------------------------------------------------------------------------
// Latino: declinazioni reali via latinNounForm/distinctiveCases (nessuna forma
// ambigua, perché distinctiveCases() esclude i casi che collidono per quel nome).
// ---------------------------------------------------------------------------

// Funzione sintattica del caso: stessa regola di docs/theoryCatalog.ts
// (topic "latino-casi-declinazioni", coreRules) — non è un'invenzione qui.
const CASE_LABEL = {
  nominativo: "nominativo (spesso soggetto)",
  genitivo: "genitivo (specificazione)",
  dativo: "dativo (termine)",
  accusativo: "accusativo (spesso oggetto)",
  ablativo: "ablativo (mezzo, causa, modo o stato)",
  vocativo: "vocativo (invocazione)",
};

// Nucleo curato di latino: oltre al riconoscimento di caso/numero (generato),
// dà basi, funzione dei casi, declinazioni, vocabolario, verbo "sum" e frasi.
const LATINO_EXTRA = [
  // Basi e storia
  { topic: "basi", difficulty: 1, prompt: "Il latino era la lingua di quale antico popolo?", answer: "I Romani", distractors: ["I Greci", "Gli Egizi", "I Celti"], explanation: "Il latino era la lingua degli antichi Romani." },
  { topic: "basi", difficulty: 1, prompt: "Da quale lingua derivano soprattutto l'italiano, lo spagnolo e il francese?", answer: "Il latino", distractors: ["Il greco", "L'inglese", "L'arabo"], explanation: "Sono lingue 'romanze', nate dal latino." },
  { topic: "basi", difficulty: 2, prompt: "Cosa significa l'espressione latina 'Carpe diem'?", answer: "Cogli l'attimo", distractors: ["Vivi a lungo", "Sii coraggioso", "Studia ogni giorno"], explanation: "Invita a vivere e apprezzare il presente." },
  // Funzione dei casi
  { topic: "casi", difficulty: 2, prompt: "In latino, il caso del soggetto è il…", answer: "Nominativo", distractors: ["Accusativo", "Genitivo", "Ablativo"], explanation: "Il nominativo indica il soggetto della frase." },
  { topic: "casi", difficulty: 2, prompt: "Il complemento oggetto in latino si esprime con l'…", answer: "Accusativo", distractors: ["Nominativo", "Dativo", "Vocativo"], explanation: "L'accusativo indica di solito il complemento oggetto." },
  { topic: "casi", difficulty: 3, prompt: "Il complemento di specificazione (il 'di chi, di cosa') usa il…", answer: "Genitivo", distractors: ["Dativo", "Ablativo", "Accusativo"], explanation: "Il genitivo indica la specificazione (es. il libro di Marco)." },
  { topic: "casi", difficulty: 3, prompt: "Il complemento di termine (a chi, per chi) usa il…", answer: "Dativo", distractors: ["Genitivo", "Accusativo", "Nominativo"], explanation: "Il dativo indica il termine (es. dono a Giulia)." },
  { topic: "casi", difficulty: 4, prompt: "Quale caso serve per chiamare o invocare qualcuno?", answer: "Vocativo", distractors: ["Nominativo", "Dativo", "Ablativo"], explanation: "Il vocativo si usa per rivolgersi direttamente a qualcuno." },
  // Declinazioni
  { topic: "declinazioni-base", difficulty: 2, prompt: "Quante sono le declinazioni del latino?", answer: "5", distractors: ["3", "4", "6"], explanation: "I nomi latini si dividono in cinque declinazioni." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "I nomi come 'rosa, rosae' appartengono alla…", answer: "Prima declinazione", distractors: ["Seconda declinazione", "Terza declinazione", "Quinta declinazione"], explanation: "La prima declinazione ha genitivo singolare in -ae." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "I nomi come 'lupus, lupi' appartengono alla…", answer: "Seconda declinazione", distractors: ["Prima declinazione", "Terza declinazione", "Quarta declinazione"], explanation: "La seconda declinazione ha genitivo singolare in -i." },
  // Vocabolario
  { topic: "vocabolario", difficulty: 1, prompt: "Cosa significa 'aqua' in italiano?", answer: "Acqua", distractors: ["Aria", "Fuoco", "Terra"], explanation: "'Aqua' significa acqua." },
  { topic: "vocabolario", difficulty: 1, prompt: "Cosa significa 'puella' in italiano?", answer: "Fanciulla, ragazza", distractors: ["Ragazzo", "Casa", "Cane"], explanation: "'Puella' è la fanciulla." },
  { topic: "vocabolario", difficulty: 2, prompt: "Cosa significa 'silva' in italiano?", answer: "Bosco, selva", distractors: ["Città", "Fiume", "Strada"], explanation: "'Silva' è il bosco (da cui 'selva')." },
  // Verbo essere (sum)
  { topic: "verbo-sum", difficulty: 3, prompt: "Come si dice 'io sono' in latino?", answer: "Sum", distractors: ["Est", "Sunt", "Es"], explanation: "'Sum' = io sono; 'es' = tu sei; 'est' = egli è." },
  { topic: "verbo-sum", difficulty: 3, prompt: "Il verbo 'est' significa…", answer: "(egli/ella) è", distractors: ["(io) sono", "(loro) sono", "(tu) sei"], explanation: "'Est' è la terza persona singolare di 'sum'." },
  { topic: "verbo-sum", difficulty: 4, prompt: "'Sunt' significa…", answer: "(loro) sono", distractors: ["(egli) è", "(io) sono", "(noi) siamo"], explanation: "'Sunt' è la terza persona plurale di 'sum'." },
  // Frasi
  { topic: "frasi", difficulty: 4, prompt: "'Puella rosam amat' significa…", answer: "La fanciulla ama la rosa", distractors: ["La rosa ama la fanciulla", "Le fanciulle amano le rose", "La fanciulla guarda la rosa"], explanation: "'Rosam' è accusativo (oggetto): la fanciulla (soggetto) ama la rosa (oggetto)." },
];

function latinoBank(latinNouns, latinNounForm, distinctiveCases) {
  const rand = rng(20260723);
  const items = [];
  latinNouns.forEach((noun, nounIndex) => {
    const combos = distinctiveCases(noun); // [{kase, number}], già senza collisioni
    const labels = combos.map((c) => `${c.kase} ${c.number}`);
    combos.forEach((combo, comboIndex) => {
      const form = latinNounForm(noun, combo.kase, combo.number);
      const answer = `${combo.kase} ${combo.number}`;
      const distractors = pickDistractors(labels, answer, 3, rand);
      if (distractors.length < 3) return;
      const difficulty = noun.tier === 1 ? (comboIndex % 2 === 0 ? 1 : 2) : (comboIndex % 2 === 0 ? 3 : 4);
      items.push(
        multipleChoiceItem(
          {
            id: `latino-${noun.nomSg}-${combo.kase}-${combo.number}`,
            subject: "latino",
            topic: `declinazione-${noun.type}`,
            difficulty,
            prompt: `Che caso e numero ha "${form}" (da "${noun.nomSg}", ${noun.it})?`,
            answer,
            distractors,
            explanation: `${CASE_LABEL[combo.kase]}, ${combo.number}.`,
          },
          rand,
        ),
      );
    });
  });
  items.push(...authoredMcItems("latino", LATINO_EXTRA, rand));
  return { schemaVersion: 1, subject: "latino", generator: "latin-declension-v2", items };
}

// ---------------------------------------------------------------------------
// Elettronica: componenti e guasti reali (circuitTemplates.ts).
// ---------------------------------------------------------------------------

const COMPONENT_DIFFICULTY = {
  battery: 1, switch: 1, resistor: 2, led: 2, return: 1,
  sensor: 3, capacitor: 3, relay: 4, motor: 3, ground: 2, branchLed: 4,
};

// Nucleo curato di elettronica: le BASI dell'elettricità (oltre a componenti e
// guasti generati dai template): corrente/tensione, circuito, conduttori,
// serie/parallelo, sicurezza e misure, con scala di difficoltà per topic.
const ELETTRONICA_EXTRA = [
  // Basi dell'elettricità
  { topic: "elettricita-base", difficulty: 1, prompt: "Cosa fa accendere una lampadina in un circuito?", answer: "La corrente elettrica", distractors: ["Il suono", "La luce del Sole", "Il vento"], explanation: "La corrente che scorre nel filo accende la lampadina." },
  { topic: "elettricita-base", difficulty: 2, prompt: "Come si chiama il flusso di cariche elettriche in un filo?", answer: "Corrente elettrica", distractors: ["Tensione statica", "Calore", "Magnetismo"], explanation: "La corrente è il movimento delle cariche nel conduttore." },
  { topic: "elettricita-base", difficulty: 3, prompt: "La 'spinta' che mette in movimento la corrente si chiama…", answer: "Tensione (voltaggio)", distractors: ["Resistenza", "Massa", "Frequenza"], explanation: "La tensione (in volt) spinge la corrente nel circuito." },
  // Il circuito
  { topic: "circuito", difficulty: 1, prompt: "Perché una lampadina si accenda, il circuito deve essere…", answer: "Chiuso", distractors: ["Aperto", "Rotto", "Bagnato"], explanation: "Solo con il circuito chiuso la corrente può fare un giro completo." },
  { topic: "circuito", difficulty: 2, prompt: "A cosa serve un interruttore in un circuito?", answer: "Ad aprire o chiudere il passaggio di corrente", distractors: ["A produrre luce", "A misurare il tempo", "A scaldare l'acqua"], explanation: "L'interruttore apre (spegne) o chiude (accende) il circuito." },
  { topic: "circuito", difficulty: 2, prompt: "In una torcia, cosa fornisce l'energia elettrica?", answer: "La pila (batteria)", distractors: ["L'interruttore", "Il filo", "La lampadina"], explanation: "La pila è il generatore che alimenta il circuito." },
  // Conduttori e isolanti
  { topic: "conduttori", difficulty: 2, prompt: "Quale materiale conduce bene l'elettricità?", answer: "Il rame (un metallo)", distractors: ["La gomma", "La plastica", "Il legno secco"], explanation: "I metalli come il rame sono buoni conduttori." },
  { topic: "conduttori", difficulty: 3, prompt: "Come si chiama un materiale che NON lascia passare la corrente?", answer: "Isolante", distractors: ["Conduttore", "Magnete", "Generatore"], explanation: "Gomma e plastica sono isolanti: proteggono dai contatti." },
  // Serie e parallelo
  { topic: "serie-parallelo", difficulty: 3, prompt: "In un collegamento in SERIE, se una lampadina si brucia, le altre…", answer: "Si spengono", distractors: ["Restano accese", "Si accendono di più", "Cambiano colore"], explanation: "In serie la corrente ha un unico percorso: si interrompe per tutte." },
  { topic: "serie-parallelo", difficulty: 4, prompt: "In un collegamento in PARALLELO, se una lampadina si brucia, le altre…", answer: "Restano accese", distractors: ["Si spengono tutte", "Si spengono a metà", "Esplodono"], explanation: "In parallelo ogni lampadina ha il suo percorso indipendente." },
  // Sicurezza
  { topic: "sicurezza-elettrica", difficulty: 1, prompt: "Perché non si toccano le prese con le mani bagnate?", answer: "L'acqua conduce e si rischia la scossa", distractors: ["Si sporca la presa", "Fa rumore", "Consuma più energia"], explanation: "L'acqua rende il corpo conduttore: pericolo di scossa." },
  { topic: "sicurezza-elettrica", difficulty: 2, prompt: "Cosa NON bisogna mai infilare in una presa di corrente?", answer: "Oggetti metallici o le dita", distractors: ["La spina di un apparecchio", "Un copripresa di sicurezza", "Niente, è sempre sicuro"], explanation: "I metalli conducono: infilarli nella presa è pericolosissimo." },
  // Componenti (stesso topic dei generati)
  { topic: "componenti", difficulty: 2, prompt: "A cosa serve un resistore in un circuito?", answer: "A limitare la corrente", distractors: ["A produrre corrente", "A spegnere il computer", "A illuminare sempre"], explanation: "Il resistore riduce la corrente, proteggendo gli altri componenti." },
  { topic: "componenti", difficulty: 2, prompt: "Un LED si accende solo se collegato…", answer: "Nel verso giusto (ha una polarità)", distractors: ["In qualsiasi verso", "Solo al buio", "Solo con l'acqua"], explanation: "Il LED conduce in un solo verso: va rispettata la polarità." },
  // Misure elettriche
  { topic: "misure-elettriche", difficulty: 3, prompt: "Con quale unità si misura la tensione?", answer: "Volt", distractors: ["Watt", "Metri", "Gradi"], explanation: "La tensione si misura in volt (V)." },
  { topic: "misure-elettriche", difficulty: 3, prompt: "Con quale unità si misura la corrente elettrica?", answer: "Ampere", distractors: ["Volt", "Litri", "Secondi"], explanation: "La corrente si misura in ampere (A)." },
];

function elettronicaBank(circuitComponentGuide, circuitFaultTemplates) {
  const rand = rng(20260724);
  const items = [];
  const functionPool = circuitComponentGuide.map((c) => c.functionSummary);
  const confusionPool = circuitComponentGuide.map((c) => c.commonConfusion);
  for (const component of circuitComponentGuide) {
    const funcDistractors = pickDistractors(functionPool, component.functionSummary, 3, rand);
    if (funcDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `elettronica-funzione-${component.id}`,
            subject: "elettronica",
            topic: "componenti",
            difficulty: COMPONENT_DIFFICULTY[component.id] ?? 2,
            prompt: `Qual è la funzione del componente "${component.label}"?`,
            answer: component.functionSummary,
            distractors: funcDistractors,
            explanation: `${component.label}: ${component.role}.`,
          },
          rand,
        ),
      );
    }
    const confusionDistractors = pickDistractors(confusionPool, component.commonConfusion, 3, rand);
    if (confusionDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `elettronica-attenzione-${component.id}`,
            subject: "elettronica",
            topic: "componenti",
            difficulty: Math.min(4, (COMPONENT_DIFFICULTY[component.id] ?? 2) + 1),
            prompt: `Quale attenzione vale per il componente "${component.label}"?`,
            answer: component.commonConfusion,
            distractors: confusionDistractors,
            explanation: `${component.label}: ${component.check}.`,
          },
          rand,
        ),
      );
    }
  }
  const faultLabels = circuitFaultTemplates.map((f) => f.label);
  for (const fault of circuitFaultTemplates) {
    const distractors = pickDistractors(faultLabels, fault.label, 3, rand);
    if (distractors.length < 3) continue;
    items.push(
      multipleChoiceItem(
        {
          id: `elettronica-guasto-${fault.type}`,
          subject: "elettronica",
          topic: "guasti",
          difficulty: Math.min(4, Math.max(1, Math.ceil((fault.minComplexity ?? 1) / 2))),
          prompt: `Quale guasto corrisponde a questo indizio: "${fault.hint}"?`,
          answer: fault.label,
          distractors,
          explanation: fault.hint,
        },
        rand,
      ),
    );
  }
  items.push(...authoredMcItems("elettronica", ELETTRONICA_EXTRA, rand));
  return { schemaVersion: 1, subject: "elettronica", generator: "circuit-templates-v2", items };
}

// ---------------------------------------------------------------------------
// Coding: semi Python già "item-shaped" (question/correct/distractors/explanation).
// ---------------------------------------------------------------------------

// Nucleo curato di coding: concetti concreti di Python/pensiero computazionale,
// organizzati in topic con scala di difficoltà (i semi TS coprono principi sparsi).
const CODING_EXTRA = [
  // Output
  { topic: "output", difficulty: 1, prompt: "In Python, quale istruzione mostra un messaggio a schermo?", answer: "print()", distractors: ["show()", "echo()", "display()"], explanation: "print() stampa a schermo ciò che gli passi." },
  { topic: "output", difficulty: 2, prompt: "Cosa stampa: print(3 + 4)?", answer: "7", distractors: ["34", "3 + 4", "'7'"], explanation: "Con i numeri, + è la somma: 3 + 4 = 7." },
  { topic: "output", difficulty: 3, prompt: "Cosa stampa: print('3' + '4')?", answer: "34", distractors: ["7", "'34'", "errore"], explanation: "Con le stringhe, + le unisce (concatenazione): '3'+'4' = '34'." },
  // Variabili
  { topic: "variabili", difficulty: 1, prompt: "In x = 5, che cos'è x?", answer: "Una variabile che vale 5", distractors: ["Una funzione", "Un errore", "Un testo fisso"], explanation: "Una variabile è un contenitore con un nome e un valore." },
  { topic: "variabili", difficulty: 2, prompt: "Dopo x = 5 e poi x = x + 1, quanto vale x?", answer: "6", distractors: ["5", "51", "errore"], explanation: "x + 1 = 5 + 1 = 6, e viene rimesso in x." },
  // Tipi di dato
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è il valore 'ciao'?", answer: "Stringa (testo)", distractors: ["Numero intero", "Booleano", "Lista"], explanation: "Il testo tra virgolette è una stringa." },
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è il valore 7?", answer: "Numero intero (int)", distractors: ["Stringa", "Booleano", "Lista"], explanation: "7 senza virgolette è un numero intero." },
  // Operatori
  { topic: "operatori", difficulty: 2, prompt: "Cosa calcola 10 % 3 in Python (operatore modulo)?", answer: "1 (il resto)", distractors: ["3", "30", "3.33"], explanation: "% dà il resto della divisione: 10 = 3×3 + 1." },
  { topic: "operatori", difficulty: 3, prompt: "Cosa calcola 2 ** 3 in Python?", answer: "8", distractors: ["6", "9", "5"], explanation: "** è l'elevamento a potenza: 2 alla 3 = 8." },
  // Condizioni
  { topic: "condizioni", difficulty: 2, prompt: "Quale parola introduce una condizione in Python?", answer: "if", distractors: ["for", "while", "def"], explanation: "if verifica una condizione ed esegue il blocco se è vera." },
  { topic: "condizioni", difficulty: 3, prompt: "Con x = 4, cosa stampa: if x > 3: print('grande')?", answer: "grande", distractors: ["4", "niente", "errore"], explanation: "4 > 3 è vero, quindi esegue print('grande')." },
  { topic: "condizioni", difficulty: 3, prompt: "Quale operatore verifica se due valori sono uguali?", answer: "==", distractors: ["=", "=>", "><"], explanation: "= assegna un valore; == confronta due valori." },
  // Cicli
  { topic: "cicli", difficulty: 2, prompt: "Quale istruzione ripete del codice più volte?", answer: "for (oppure while)", distractors: ["if", "def", "print"], explanation: "I cicli for e while ripetono un blocco di istruzioni." },
  { topic: "cicli", difficulty: 3, prompt: "Quante volte stampa: for i in range(3): print(i)?", answer: "3 volte (0, 1, 2)", distractors: ["1 volta", "3 volte (1, 2, 3)", "4 volte"], explanation: "range(3) genera 0, 1, 2: tre ripetizioni." },
  // Liste
  { topic: "liste", difficulty: 2, prompt: "Come si scrive in Python una lista con tre numeri?", answer: "[1, 2, 3]", distractors: ["(1 2 3)", "{1;2;3}", "<1,2,3>"], explanation: "Le liste si scrivono tra parentesi quadre, con virgole." },
  { topic: "liste", difficulty: 3, prompt: "Data lista = [10, 20, 30], cosa vale lista[0]?", answer: "10", distractors: ["20", "30", "1"], explanation: "Gli indici partono da 0: lista[0] è il primo elemento." },
  // Funzioni
  { topic: "funzioni", difficulty: 3, prompt: "Quale parola chiave definisce una funzione in Python?", answer: "def", distractors: ["func", "function", "let"], explanation: "def introduce la definizione di una funzione." },
  { topic: "funzioni", difficulty: 4, prompt: "A cosa serve soprattutto una funzione?", answer: "A riusare un blocco di codice dandogli un nome", distractors: ["A colorare il testo", "A spegnere il computer", "A creare errori"], explanation: "Le funzioni evitano di ripetere lo stesso codice." },
  // Booleani
  { topic: "booleani", difficulty: 2, prompt: "Quali sono i due valori booleani in Python?", answer: "True e False", distractors: ["1 e 2", "Sì e No", "On e Off"], explanation: "Un booleano può essere solo True (vero) o False (falso)." },
  { topic: "booleani", difficulty: 3, prompt: "Cosa vale l'espressione 5 > 3 in Python?", answer: "True", distractors: ["False", "5", "errore"], explanation: "5 è maggiore di 3, quindi il confronto è True." },
  // Pensiero computazionale
  { topic: "algoritmi", difficulty: 1, prompt: "Che cos'è un algoritmo?", answer: "Una sequenza di passi per risolvere un problema", distractors: ["Un tipo di computer", "Un linguaggio di programmazione", "Un errore"], explanation: "L'algoritmo descrive i passi, come una ricetta." },
  { topic: "algoritmi", difficulty: 2, prompt: "Cosa significa 'bug' in programmazione?", answer: "Un errore nel programma", distractors: ["Un tipo di dato", "Un comando utile", "Una funzione"], explanation: "Un bug è un difetto che fa comportare male il programma." },
];

// Normalizza i topic verbosi dei semi Python sui topic canonici puliti, così la
// mastery per-topic non frammenta lo stesso concetto (es. "stringhe: len()" e
// "stringhe: concatenazione" → "stringhe").
const CODING_TOPIC_MAP = {
  "variabili come etichette": "variabili",
  "stringhe: concatenazione": "stringhe",
  "stringhe: len()": "stringhe",
  "tipi di dato": "tipi",
  "liste: indice": "liste",
  "liste: append()": "liste",
  "liste: ciclo e somma": "liste",
  "ciclo for con range()": "cicli",
  "range come conteggio": "cicli",
  "condizione if/else": "condizioni",
  "confronto ==  vs  =": "condizioni",
  "operatori booleani": "booleani",
  "modulo: pari o dispari": "operatori",
  "divisione intera": "operatori",
  "potenza": "operatori",
  "funzioni: def e return": "funzioni",
  "indentazione = struttura": "stile",
  "commenti": "stile",
  "Zen of Python: leggibilità": "stile",
  "input() e tipi": "input",
};

function codingBank(pythonPrincipleSeeds) {
  const rand = rng(20260725);
  const items = pythonPrincipleSeeds.map((seed) => {
    const prompt = `${seed.codeLines.join("\n")}\n\n${seed.question}`;
    const explanation = seed.funFact ? `${seed.explanation} ${seed.funFact}` : seed.explanation;
    return multipleChoiceItem(
      {
        id: `coding-${seed.principle.replace(/[^a-z0-9]+/gi, "-")}`,
        subject: "coding",
        topic: CODING_TOPIC_MAP[seed.principle] ?? seed.principle,
        difficulty: Math.min(4, Math.max(1, Math.ceil(seed.minLevel / 2))),
        prompt,
        answer: seed.correct,
        distractors: seed.distractors,
        explanation,
      },
      rand,
    );
  });
  items.push(...authoredMcItems("coding", CODING_EXTRA, rand));
  return { schemaVersion: 1, subject: "coding", generator: "python-principles-v2", items };
}

// ---------------------------------------------------------------------------
// Fisica / Musica: nessun generatore in Phaser. Contenuto trascritto
// letteralmente da src/data/theoryCatalog.ts (definition/example/watchOut),
// non inventato — per questo il banco è più piccolo (curato) che generato.
// ---------------------------------------------------------------------------

const FISICA_TOPICS = [
  { id: "fisica-misure-unita", title: "Misure e unità", area: "Metodo fisico", levelRange: [1, 5],
    definition: "Una misura collega un numero a un'unità; senza unità coerenti il confronto non è affidabile.",
    example: { prompt: "250 cm in metri.", steps: ["da cm a m sono due scalini", "250 / 100 = 2,5"], answer: "2,5 m" },
    watchOut: ["Non sommare grandezze con unità diverse.", "Le conversioni di area e volume non scalano come le lunghezze."] },
  { id: "fisica-moto-forze-energia", title: "Moto, forze ed energia", area: "Modelli fisici", levelRange: [2, 8],
    definition: "La fisica descrive i fenomeni con grandezze misurabili e modelli: grafici, forze, energia e trasformazioni.",
    example: { prompt: "Una linea posizione-tempo diventa più ripida.", steps: ["la pendenza aumenta", "la velocità aumenta", "il moto è più rapido"], answer: "Il corpo si muove più velocemente." },
    watchOut: ["Un grafico non è un disegno del percorso.", "Peso e massa non sono la stessa grandezza."] },
  { id: "fisica-onde-ottica", title: "Onde e ottica", area: "Modelli fisici", levelRange: [5, 8],
    definition: "Le onde trasportano energia; in ottica geometrica la luce si rappresenta con raggi e direzioni.",
    example: { prompt: "Onda con lambda = 2 m e f = 3 Hz.", steps: ["v = lambda x f", "2 x 3 = 6"], answer: "6 m/s" },
    watchOut: ["Frequenza e periodo sono inversi.", "La normale non è lo specchio: è la linea perpendicolare."] },
  { id: "fisica-moto-grafici", title: "Moto e grafici", area: "Cinematica", levelRange: [3, 8],
    definition: "Un grafico posizione-tempo racconta il moto: la pendenza indica la velocità, non il percorso.",
    example: { prompt: "Una linea posizione-tempo è piatta per un tratto.", steps: ["pendenza zero", "posizione non cambia", "il corpo è fermo"], answer: "Nel tratto piatto il corpo è fermo." },
    watchOut: ["Un grafico posizione-tempo non è la mappa del percorso.", "Salita ripida significa veloce, non 'in alto'."] },
  { id: "fisica-forze-equilibrio", title: "Forze ed equilibrio", area: "Dinamica", levelRange: [3, 8],
    definition: "Una forza ha intensità e direzione; se le forze si bilanciano, il corpo è in equilibrio.",
    example: { prompt: "Un libro fermo su un tavolo.", steps: ["peso verso il basso", "reazione del tavolo verso l'alto", "forze uguali: equilibrio"], answer: "È in equilibrio: peso e reazione si bilanciano." },
    watchOut: ["Peso e massa non sono la stessa grandezza.", "Fermo non vuol dire senza forze: vuol dire forze bilanciate."] },
  { id: "fisica-energia-trasformazioni", title: "Energia e trasformazioni", area: "Energia", levelRange: [3, 8],
    definition: "L'energia non si crea né si distrugge: si trasforma da una forma all'altra.",
    example: { prompt: "Una palla cade da un tavolo.", steps: ["in alto: energia potenziale", "cadendo: diventa cinetica", "l'energia si trasforma, non sparisce"], answer: "La potenziale si trasforma in cinetica." },
    watchOut: ["L'energia non nasce dal nulla: cerca sempre la forma di partenza.", "Una parte va sempre persa come calore o attrito."] },
  { id: "fisica-esperimento-metodo", title: "Esperimento e metodo", area: "Metodo fisico", levelRange: [2, 7],
    definition: "Un esperimento controllato cambia una variabile alla volta per capire cosa influenza cosa.",
    example: { prompt: "Vuoi vedere se più luce fa crescere le piante.", steps: ["cambio solo la luce", "acqua e terreno restano uguali", "confronto la crescita"], answer: "Vario solo la luce, tengo fisso il resto." },
    watchOut: ["Cambiare due cose insieme rende il risultato inutile.", "Un'ipotesi non è ancora una conclusione: servono i dati."] },
  { id: "fisica-densita-pressione", title: "Densità e pressione", area: "Fluidi e materia", levelRange: [4, 8],
    definition: "La densità è massa per volume; la pressione è forza per area.",
    example: { prompt: "Massa 200 g, volume 100 cm3. Trova la densità.", steps: ["densità = massa / volume", "200 / 100", "2 g/cm3"], answer: "2 g/cm3" },
    watchOut: ["Non confondere densità e pressione: hanno formule diverse.", "Ridurre l'area aumenta la pressione a parità di forza."] },
  { id: "fisica-calore-temperatura", title: "Calore e temperatura", area: "Termologia", levelRange: [4, 8],
    definition: "La temperatura misura quanto è caldo un corpo; il calore è l'energia che passa dal caldo al freddo.",
    example: { prompt: "Un cubetto di ghiaccio in acqua tiepida.", steps: ["l'acqua è più calda", "il calore passa all'acqua verso il ghiaccio", "tendono a una temperatura comune"], answer: "Il calore passa dall'acqua al ghiaccio fino all'equilibrio." },
    watchOut: ["Temperatura alta non significa più calore totale: conta anche la massa.", "Il calore non passa mai dal freddo al caldo da solo."] },
];

const MUSICA_TOPICS = [
  { id: "musica-pentagramma-chiavi", title: "Pentagramma e chiavi", area: "Lettura musicale", levelRange: [1, 5],
    definition: "Il pentagramma usa righe e spazi per indicare l'altezza delle note; la chiave cambia il punto di riferimento.",
    example: { prompt: "Nota nel secondo spazio in chiave di violino.", steps: ["chiave di violino", "gli spazi sono Fa-La-Do-Mi", "secondo spazio = La"], answer: "La" },
    watchOut: ["La stessa posizione cambia nome se cambia chiave.", "Non ignorare l'ottava nelle note fuori dal pentagramma."] },
  { id: "musica-ritmo-intervalli", title: "Ritmo e intervalli", area: "Lettura musicale", levelRange: [3, 8],
    definition: "Il ritmo organizza la durata dei suoni; l'intervallo misura la distanza tra due note.",
    example: { prompt: "In 4/4 ci sono due semiminime e una minima.", steps: ["1 + 1 + 2 = 4", "la battuta è completa"], answer: "Non manca nessun battito." },
    watchOut: ["Una croma vale mezzo battito, non uno.", "Salire di nota non significa sempre stesso intervallo."] },
  { id: "musica-linee-ottava", title: "Linee addizionali e ottava", area: "Lettura musicale", levelRange: [3, 7],
    definition: "Le linee addizionali estendono il pentagramma oltre le cinque righe e possono cambiare l'ottava della nota.",
    example: { prompt: "Nota due linee sopra il pentagramma in chiave di violino.", steps: ["dall'ultima riga salgo di due linee", "conto righe e spazi in ordine", "ottengo il La acuto"], answer: "La (ottava alta)." },
    watchOut: ["Non saltare le linee: vanno contate una per volta.", "Stesso nome nota, ottava diversa: l'altezza cambia."] },
  { id: "musica-intervalli-scale", title: "Intervalli e scale", area: "Lettura musicale", levelRange: [4, 8],
    definition: "Un intervallo è la distanza tra due note; si conta includendo la nota di partenza e quella di arrivo.",
    example: { prompt: "Intervallo da Do a Sol.", steps: ["Do, Re, Mi, Fa, Sol", "conto cinque nomi", "è una quinta"], answer: "Quinta." },
    watchOut: ["Conta includendo la nota di partenza, non da zero.", "Salire di posizione non è sempre lo stesso intervallo."] },
  { id: "musica-durate-tempo", title: "Durate e tempo", area: "Ritmo", levelRange: [3, 8],
    definition: "Ogni figura ha una durata in battiti; la battuta deve contenere esattamente i battiti indicati dal tempo.",
    example: { prompt: "In 4/4 ci sono una minima e una semiminima. Cosa manca?", steps: ["minima 2 + semiminima 1 = 3", "servono 4", "manca 1 battito"], answer: "Manca una semiminima." },
    watchOut: ["La croma vale mezzo battito, non uno.", "La battuta non può superare i battiti del tempo."] },
];

// Topic canonici (puliti) per gli item del catalogo-teoria, mappati per id: così
// fisica/musica non hanno più etichette-area lunghe accanto agli slug autorati.
const THEORY_TOPIC = {
  // fisica
  "fisica-misure-unita": "misure",
  "fisica-moto-forze-energia": "moto",
  "fisica-onde-ottica": "onde-luce",
  "fisica-moto-grafici": "moto",
  "fisica-forze-equilibrio": "forze",
  "fisica-energia-trasformazioni": "energia",
  "fisica-esperimento-metodo": "metodo",
  "fisica-densita-pressione": "materia",
  "fisica-calore-temperatura": "calore",
  // musica
  "musica-pentagramma-chiavi": "lettura",
  "musica-ritmo-intervalli": "ritmo",
  "musica-linee-ottava": "lettura",
  "musica-intervalli-scale": "intervalli",
  "musica-durate-tempo": "ritmo",
};

function curatedTheoryBank(subject, topics, seed) {
  const rand = rng(seed);
  const definitions = topics.map((t) => t.definition);
  const exampleAnswers = topics.map((t) => t.example.answer);
  const firstWatchOuts = topics.map((t) => t.watchOut[0]);
  const items = [];
  for (const topic of topics) {
    const canonTopic = THEORY_TOPIC[topic.id] ?? topic.area;
    const difficulty = Math.min(4, Math.max(1, Math.round(((topic.levelRange[0] + topic.levelRange[1]) / 2) / 2)));
    const defDistractors = pickDistractors(definitions, topic.definition, 3, rand);
    if (defDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `${topic.id}-definizione`,
            subject,
            topic: canonTopic,
            difficulty,
            prompt: `Qual è la definizione corretta di "${topic.title}"?`,
            answer: topic.definition,
            distractors: defDistractors,
            explanation: topic.definition,
          },
          rand,
        ),
      );
    }
    const exDistractors = pickDistractors(exampleAnswers, topic.example.answer, 3, rand);
    if (exDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `${topic.id}-esempio`,
            subject,
            topic: canonTopic,
            difficulty,
            prompt: topic.example.prompt,
            answer: topic.example.answer,
            distractors: exDistractors,
            explanation: topic.example.steps.join(" → ") + ".",
          },
          rand,
        ),
      );
    }
    const watchDistractors = pickDistractors(firstWatchOuts, topic.watchOut[0], 3, rand);
    if (watchDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `${topic.id}-attenzione`,
            subject,
            topic: canonTopic,
            difficulty: Math.min(4, difficulty + 1),
            prompt: `Quale errore comune bisogna evitare in "${topic.title}"?`,
            answer: topic.watchOut[0],
            distractors: watchDistractors,
            explanation: topic.watchOut[0],
          },
          rand,
        ),
      );
    }
  }
  return { schemaVersion: 1, subject, generator: "theory-catalog-curated-v1", items };
}

// Domande concrete e variate per fisica/musica (oltre alla teoria astratta):
// ancorano i concetti a esempi quotidiani, con scala di difficoltà per topic.
function authoredMcItems(subject, questions, rand) {
  return questions.map((q, i) =>
    multipleChoiceItem({ id: `${subject}-${q.topic}-${i}`, subject, topic: q.topic, difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand),
  );
}

const FISICA_EXTRA = [
  // Misure
  { topic: "misure", difficulty: 1, prompt: "Con quale strumento misuri la lunghezza di un banco?", answer: "Il metro (righello)", distractors: ["La bilancia", "Il termometro", "L'orologio"], explanation: "Il metro misura le lunghezze; la bilancia le masse." },
  { topic: "misure", difficulty: 2, prompt: "Quanti centimetri sono 1 metro?", answer: "100", distractors: ["10", "1000", "50"], explanation: "1 metro = 100 centimetri." },
  { topic: "misure", difficulty: 3, prompt: "Per misurare quanto pesi useresti…", answer: "Una bilancia", distractors: ["Un metro", "Un termometro", "Un cronometro"], explanation: "La bilancia misura la massa/peso; il termometro la temperatura." },
  // Moto
  { topic: "moto", difficulty: 1, prompt: "Un oggetto che non cambia posizione è…", answer: "Fermo", distractors: ["Veloce", "Lento", "In caduta"], explanation: "Se la posizione non cambia, l'oggetto è fermo." },
  { topic: "moto", difficulty: 2, prompt: "Se un'auto percorre più strada nello stesso tempo, è…", answer: "Più veloce", distractors: ["Più lenta", "Ferma", "Più pesante"], explanation: "Più spazio nello stesso tempo significa maggiore velocità." },
  { topic: "moto", difficulty: 3, prompt: "In un grafico spazio-tempo, una linea più ripida indica…", answer: "Una velocità maggiore", distractors: ["Un oggetto fermo", "Una salita reale in collina", "Un peso maggiore"], explanation: "La pendenza del grafico rappresenta la velocità, non un percorso in salita." },
  // Forze
  { topic: "forze", difficulty: 1, prompt: "Quale forza fa cadere gli oggetti verso il basso?", answer: "La forza di gravità", distractors: ["Il vento", "La luce", "Il suono"], explanation: "La gravità attira gli oggetti verso il centro della Terra." },
  { topic: "forze", difficulty: 2, prompt: "Cosa rallenta una palla che rotola sul pavimento?", answer: "L'attrito", distractors: ["La gravità verso l'alto", "La luce", "Il colore della palla"], explanation: "L'attrito tra palla e pavimento la frena a poco a poco." },
  { topic: "forze", difficulty: 3, prompt: "Su un libro fermo sul tavolo, le forze…", answer: "Si bilanciano", distractors: ["Spingono solo in basso", "Spingono solo in alto", "Non esistono"], explanation: "Il peso verso il basso e la spinta del tavolo verso l'alto si equilibrano." },
  { topic: "forze", difficulty: 4, prompt: "Massa e peso: quale frase è corretta?", answer: "La massa è la quantità di materia; il peso è la forza di gravità su di essa", distractors: ["Sono esattamente la stessa cosa", "Il peso non cambia mai, ovunque", "La massa si misura sempre in newton"], explanation: "La massa non cambia; il peso dipende dalla gravità (sulla Luna pesi meno)." },
  // Energia
  { topic: "energia", difficulty: 2, prompt: "Una palla ferma in cima a uno scivolo ha soprattutto energia…", answer: "Potenziale", distractors: ["Cinetica", "Sonora", "Luminosa"], explanation: "In alto e ferma ha energia potenziale (di posizione)." },
  { topic: "energia", difficulty: 3, prompt: "Mentre la palla scende lungo lo scivolo, l'energia potenziale si trasforma in…", answer: "Energia cinetica (di movimento)", distractors: ["Più energia potenziale", "Suono", "Nulla, sparisce"], explanation: "Scendendo, l'energia di posizione diventa energia di movimento." },
  // Calore
  { topic: "calore", difficulty: 2, prompt: "Il calore passa sempre…", answer: "Dal corpo più caldo a quello più freddo", distractors: ["Dal freddo al caldo", "Dal piccolo al grande", "In nessuna direzione"], explanation: "Il calore fluisce dal caldo al freddo finché non si equilibrano." },
  { topic: "calore", difficulty: 3, prompt: "Temperatura e calore: quale è vero?", answer: "La temperatura dice quanto è caldo; il calore è l'energia che si trasferisce", distractors: ["Sono la stessa cosa", "Il calore si misura in gradi", "La temperatura è un tipo di energia"], explanation: "Sono grandezze diverse: gradi per la temperatura, energia per il calore." },
  // Onde e luce
  { topic: "onde-luce", difficulty: 2, prompt: "In aria limpida, la luce viaggia…", answer: "In linea retta", distractors: ["A zig-zag sempre", "Solo di notte", "Più lenta del suono"], explanation: "La luce si propaga in linea retta finché non incontra ostacoli." },
  { topic: "onde-luce", difficulty: 3, prompt: "Perché durante un temporale vediamo il lampo prima di sentire il tuono?", answer: "La luce è molto più veloce del suono", distractors: ["Il suono è più veloce", "Sono simultanei", "Il tuono parte dopo il lampo"], explanation: "La luce arriva quasi subito; il suono, più lento, arriva dopo." },
];

const MUSICA_EXTRA = [
  // Note e lettura
  { topic: "note", difficulty: 1, prompt: "Quante sono le note musicali principali (do, re, mi, …)?", answer: "7", distractors: ["5", "8", "10"], explanation: "Do, Re, Mi, Fa, Sol, La, Si: sette note." },
  { topic: "note", difficulty: 1, prompt: "Quale nota viene subito dopo il Do?", answer: "Re", distractors: ["Mi", "Si", "Fa"], explanation: "L'ordine è Do, Re, Mi, Fa, Sol, La, Si." },
  { topic: "note", difficulty: 2, prompt: "Dopo il Sol, quale nota viene?", answer: "La", distractors: ["Fa", "Do", "Mi"], explanation: "…Sol, La, Si, poi si ricomincia da Do." },
  { topic: "lettura", difficulty: 2, prompt: "Su cosa si scrivono le note musicali?", answer: "Sul pentagramma", distractors: ["Su un foglio a quadretti", "Sulla tastiera del pc", "Su un foglio bianco"], explanation: "Il pentagramma ha 5 righe e 4 spazi." },
  { topic: "lettura", difficulty: 3, prompt: "Quante righe ha il pentagramma?", answer: "5", distractors: ["4", "6", "7"], explanation: "Penta- significa cinque: cinque righe." },
  // Ritmo e durate
  { topic: "ritmo", difficulty: 2, prompt: "Quale figura musicale dura di più?", answer: "La semibreve", distractors: ["La croma", "La semiminima", "La minima"], explanation: "La semibreve vale 4 battiti: più di minima, semiminima e croma." },
  { topic: "ritmo", difficulty: 3, prompt: "In 4/4, quanti battiti ci sono in una battuta?", answer: "4", distractors: ["2", "3", "8"], explanation: "Il 4 in alto indica quattro battiti per battuta." },
  { topic: "ritmo", difficulty: 3, prompt: "Una minima dura, rispetto a una semiminima…", answer: "Il doppio", distractors: ["La metà", "Uguale", "Il triplo"], explanation: "La minima vale 2 battiti, la semiminima 1: il doppio." },
  // Intervalli
  { topic: "intervalli", difficulty: 3, prompt: "L'intervallo da Do a Sol (contando le note) è una…", answer: "Quinta", distractors: ["Terza", "Quarta", "Ottava"], explanation: "Do-Re-Mi-Fa-Sol: cinque note, quindi una quinta." },
  // Strumenti e timbro
  { topic: "strumenti", difficulty: 1, prompt: "Quale di questi è uno strumento a corde?", answer: "La chitarra", distractors: ["Il flauto", "La tromba", "Il tamburo"], explanation: "La chitarra produce suono con le corde." },
  { topic: "strumenti", difficulty: 2, prompt: "Il flauto è uno strumento a…", answer: "Fiato", distractors: ["Corde", "Percussione", "Tastiera"], explanation: "Il flauto suona soffiando aria: è uno strumento a fiato." },
  { topic: "timbro", difficulty: 3, prompt: "Cosa ci fa distinguere un pianoforte da una chitarra sulla stessa nota?", answer: "Il timbro", distractors: ["Il volume", "La durata", "Il tempo"], explanation: "Il timbro è il 'colore' del suono, diverso per ogni strumento." },
  // Dinamica e tempo
  { topic: "dinamica", difficulty: 2, prompt: "In musica 'forte' e 'piano' indicano…", answer: "L'intensità del suono (il volume)", distractors: ["La velocità del brano", "L'altezza della nota", "La durata"], explanation: "Le dinamiche dicono quanto suonare forte o piano." },
  { topic: "dinamica", difficulty: 3, prompt: "Il termine che indica quanto è veloce un brano è il…", answer: "Tempo (andamento)", distractors: ["Timbro", "Volume", "Silenzio"], explanation: "Il tempo indica la velocità: da lento (adagio) a veloce (allegro)." },
];

function fisicaBank(rand) {
  const theory = curatedTheoryBank("fisica", FISICA_TOPICS, 20260726);
  theory.items.push(...authoredMcItems("fisica", FISICA_EXTRA, rand));
  return theory;
}

function musicaBank(rand) {
  const theory = curatedTheoryBank("musica", MUSICA_TOPICS, 20260727);
  theory.items.push(...authoredMcItems("musica", MUSICA_EXTRA, rand));
  return theory;
}

// ---------------------------------------------------------------------------
// Geografia (materia nuova). Nessun dato statico in src/ (le capitali erano
// generate in LogicGym): contenuto AUTORATO qui, fatti mainstream e non ambigui.
// Difficoltà per notorietà. Genera 3 domande per riga (capitale? / di chi è? /
// quale continente?) pescando i distrattori dalla stessa categoria.
// ---------------------------------------------------------------------------

// [Stato, capitale, continente, difficoltà]
const GEO_COUNTRIES = [
  ["Italia", "Roma", "Europa", 1],
  ["Francia", "Parigi", "Europa", 1],
  ["Spagna", "Madrid", "Europa", 1],
  ["Germania", "Berlino", "Europa", 1],
  ["Regno Unito", "Londra", "Europa", 1],
  ["Portogallo", "Lisbona", "Europa", 2],
  ["Grecia", "Atene", "Europa", 2],
  ["Austria", "Vienna", "Europa", 3],
  ["Belgio", "Bruxelles", "Europa", 3],
  ["Paesi Bassi", "Amsterdam", "Europa", 3],
  ["Polonia", "Varsavia", "Europa", 3],
  ["Svezia", "Stoccolma", "Europa", 3],
  ["Norvegia", "Oslo", "Europa", 4],
  ["Russia", "Mosca", "Europa", 2],
  ["Stati Uniti", "Washington", "America del Nord", 2],
  ["Canada", "Ottawa", "America del Nord", 3],
  ["Messico", "Città del Messico", "America del Nord", 3],
  ["Brasile", "Brasília", "America del Sud", 2],
  ["Argentina", "Buenos Aires", "America del Sud", 3],
  ["Giappone", "Tokyo", "Asia", 1],
  ["Cina", "Pechino", "Asia", 2],
  ["India", "Nuova Delhi", "Asia", 3],
  ["Egitto", "Il Cairo", "Africa", 2],
  ["Australia", "Canberra", "Oceania", 4],
];

const CONTINENTS = ["Europa", "Asia", "Africa", "America del Nord", "America del Sud", "Oceania", "Antartide"];

// Geografia fisica, Italia, climi, Europa, mondo e strumenti: fatti autorati e
// stabili, ciascun topic con una scala di difficoltà 1→4 (percorso didattico).
const GEO_FACTS = [
  // --- Geografia fisica (dal riconoscere al ragionare) ---
  { topic: "geografia-fisica", difficulty: 1, prompt: "In quale continente si trova il deserto del Sahara?", answer: "Africa", distractors: ["Asia", "Oceania", "Europa"], explanation: "Il Sahara è il grande deserto caldo dell'Africa settentrionale." },
  { topic: "geografia-fisica", difficulty: 1, prompt: "Come si chiama la linea immaginaria che divide la Terra in due metà uguali?", answer: "Equatore", distractors: ["Meridiano", "Tropico", "Polo"], explanation: "L'Equatore divide la Terra in emisfero nord e sud." },
  { topic: "geografia-fisica", difficulty: 2, prompt: "Qual è l'oceano più grande della Terra?", answer: "Oceano Pacifico", distractors: ["Oceano Atlantico", "Oceano Indiano", "Oceano Artico"], explanation: "Il Pacifico è il più esteso e profondo degli oceani." },
  { topic: "geografia-fisica", difficulty: 2, prompt: "Qual è la montagna più alta della Terra?", answer: "Everest", distractors: ["Monte Bianco", "Kilimangiaro", "Aconcagua"], explanation: "L'Everest, in Asia, supera gli 8800 metri." },
  { topic: "geografia-fisica", difficulty: 2, prompt: "Quanti sono i continenti della Terra?", answer: "7", distractors: ["5", "6", "8"], explanation: "Europa, Asia, Africa, America del Nord, America del Sud, Oceania e Antartide." },
  { topic: "geografia-fisica", difficulty: 3, prompt: "In quale continente scorre il Rio delle Amazzoni?", answer: "America del Sud", distractors: ["Africa", "Asia", "America del Nord"], explanation: "L'Amazzonia e il suo fiume si trovano in America del Sud." },
  { topic: "geografia-fisica", difficulty: 3, prompt: "Come si chiamano le grandi masse di ghiaccio che scivolano lentamente verso valle?", answer: "Ghiacciai", distractors: ["Iceberg", "Cascate", "Sorgenti"], explanation: "I ghiacciai sono fiumi di ghiaccio che scendono dai monti; gli iceberg galleggiano nel mare." },
  { topic: "geografia-fisica", difficulty: 4, prompt: "Come si chiama il punto più profondo degli oceani, nel Pacifico?", answer: "Fossa delle Marianne", distractors: ["Mar dei Sargassi", "Golfo del Bengala", "Fossa di Giava"], explanation: "La Fossa delle Marianne supera gli 11 000 metri di profondità." },
  // --- Geografia dell'Italia ---
  { topic: "geografia-italia", difficulty: 1, prompt: "Qual è la capitale d'Italia?", answer: "Roma", distractors: ["Milano", "Napoli", "Torino"], explanation: "Roma è la capitale della Repubblica Italiana." },
  { topic: "geografia-italia", difficulty: 1, prompt: "Qual è il fiume più lungo d'Italia?", answer: "Po", distractors: ["Tevere", "Arno", "Adige"], explanation: "Il Po, che attraversa la Pianura Padana, è il fiume più lungo d'Italia." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Quali sono le due isole più grandi d'Italia?", answer: "Sicilia e Sardegna", distractors: ["Sicilia ed Elba", "Sardegna e Capri", "Elba e Ischia"], explanation: "Sicilia e Sardegna sono le due isole maggiori italiane." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Qual è il vulcano attivo più grande d'Europa, in Sicilia?", answer: "Etna", distractors: ["Vesuvio", "Stromboli", "Vulcano"], explanation: "L'Etna, in Sicilia, è il maggiore vulcano attivo europeo." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Qual è il lago più grande d'Italia?", answer: "Lago di Garda", distractors: ["Lago di Como", "Lago Maggiore", "Lago Trasimeno"], explanation: "Il Lago di Garda è il maggiore lago italiano per superficie." },
  { topic: "geografia-italia", difficulty: 3, prompt: "Quale catena montuosa percorre l'Italia da nord a sud?", answer: "Appennini", distractors: ["Alpi", "Pirenei", "Dolomiti"], explanation: "Gli Appennini attraversano la penisola; le Alpi chiudono l'Italia a nord." },
  { topic: "geografia-italia", difficulty: 3, prompt: "Quale mare bagna la costa orientale dell'Italia?", answer: "Mar Adriatico", distractors: ["Mar Tirreno", "Mar Ionio", "Mar Ligure"], explanation: "L'Adriatico è a est, tra Italia e penisola balcanica." },
  { topic: "geografia-italia", difficulty: 4, prompt: "Quale regione italiana ha la maggiore superficie?", answer: "Sicilia", distractors: ["Piemonte", "Sardegna", "Lombardia"], explanation: "La Sicilia è la regione italiana più estesa, seguita dal Piemonte." },
  // --- Climi e ambienti ---
  { topic: "climi", difficulty: 2, prompt: "In quale zona della Terra fa caldo tutto l'anno?", answer: "Vicino all'Equatore", distractors: ["Vicino ai Poli", "In cima alle montagne", "Nelle grotte"], explanation: "Vicino all'Equatore i raggi del Sole arrivano più diretti e riscaldano di più." },
  { topic: "climi", difficulty: 3, prompt: "Come si chiama il clima con estati calde e secche e inverni miti, tipico dell'Italia?", answer: "Clima mediterraneo", distractors: ["Clima polare", "Clima desertico", "Clima equatoriale"], explanation: "Il clima mediterraneo ha estati asciutte e inverni miti e piovosi." },
  { topic: "climi", difficulty: 3, prompt: "Salendo in montagna, la temperatura di solito…", answer: "Diminuisce", distractors: ["Aumenta", "Resta uguale", "Raddoppia"], explanation: "Più si sale in quota, più l'aria è fredda." },
  { topic: "climi", difficulty: 4, prompt: "Come si chiama la grande foresta calda e piovosa vicino all'Equatore?", answer: "Foresta pluviale", distractors: ["Tundra", "Savana", "Taiga"], explanation: "La foresta pluviale è calda e umida tutto l'anno; la tundra invece è fredda." },
  // --- Europa ---
  { topic: "europa", difficulty: 1, prompt: "In quale continente si trova l'Italia?", answer: "Europa", distractors: ["Asia", "Africa", "America"], explanation: "L'Italia è uno Stato dell'Europa meridionale." },
  { topic: "europa", difficulty: 2, prompt: "Quale fiume attraversa la città di Parigi?", answer: "Senna", distractors: ["Tamigi", "Reno", "Danubio"], explanation: "La Senna attraversa Parigi; il Tamigi passa per Londra." },
  { topic: "europa", difficulty: 3, prompt: "Quale catena di monti segna il confine tra Europa e Asia?", answer: "Monti Urali", distractors: ["Alpi", "Pirenei", "Carpazi"], explanation: "Gli Urali, in Russia, dividono convenzionalmente Europa e Asia." },
  { topic: "europa", difficulty: 4, prompt: "Come si chiama l'unione economica e politica di molti Stati europei?", answer: "Unione Europea", distractors: ["Nazioni Unite", "Commonwealth", "NATO"], explanation: "L'Unione Europea riunisce numerosi Stati del continente." },
  // --- Il mondo ---
  { topic: "mondo", difficulty: 2, prompt: "Qual è il Paese più grande del mondo per superficie?", answer: "Russia", distractors: ["Canada", "Cina", "Stati Uniti"], explanation: "La Russia è lo Stato più esteso, tra Europa e Asia." },
  { topic: "mondo", difficulty: 3, prompt: "Qual è oggi il Paese più popoloso del mondo?", answer: "India", distractors: ["Cina", "Stati Uniti", "Indonesia"], explanation: "L'India ha superato la Cina come Paese con più abitanti." },
  { topic: "mondo", difficulty: 4, prompt: "Attraverso quale canale le navi passano tra Mar Mediterraneo e Mar Rosso?", answer: "Canale di Suez", distractors: ["Canale di Panama", "Stretto di Gibilterra", "Canale della Manica"], explanation: "Il Canale di Suez, in Egitto, collega Mediterraneo e Mar Rosso." },
  // --- Strumenti del geografo ---
  { topic: "geografia-umana", difficulty: 1, prompt: "Da quale punto cardinale sorge il Sole?", answer: "Est", distractors: ["Ovest", "Nord", "Sud"], explanation: "Il Sole sorge a est e tramonta a ovest." },
  { topic: "geografia-umana", difficulty: 2, prompt: "Come si chiama la rappresentazione ridotta della Terra disegnata su un foglio?", answer: "Carta geografica", distractors: ["Fotografia", "Calendario", "Diario"], explanation: "La carta geografica riduce la realtà mantenendo le proporzioni." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Su una carta geografica, che cosa indica la scala?", answer: "Di quanto è stata ridotta la realtà", distractors: ["Il colore del mare", "La temperatura", "Il nome delle vie"], explanation: "La scala dice quante volte le distanze reali sono state rimpicciolite." },
];

function geografiaBank() {
  const rand = rng(20260728);
  const items = [];
  const capitals = GEO_COUNTRIES.map((c) => c[1]);
  const countries = GEO_COUNTRIES.map((c) => c[0]);
  for (const [country, capital, continent, difficulty] of GEO_COUNTRIES) {
    const capD = pickDistractors(capitals, capital, 3, rand);
    if (capD.length === 3) {
      items.push(multipleChoiceItem({ id: `geografia-cap-${capital}`, subject: "geografia", topic: "capitali", difficulty, prompt: `Qual è la capitale di ${country}?`, answer: capital, distractors: capD, explanation: `La capitale di ${country} è ${capital}.` }, rand));
    }
    const couD = pickDistractors(countries, country, 3, rand);
    if (couD.length === 3) {
      items.push(multipleChoiceItem({ id: `geografia-stato-${capital}`, subject: "geografia", topic: "capitali", difficulty: Math.min(4, difficulty + 1), prompt: `Di quale Stato è capitale ${capital}?`, answer: country, distractors: couD, explanation: `${capital} è la capitale di ${country}.` }, rand));
    }
    const conD = pickDistractors(CONTINENTS, continent, 3, rand);
    if (conD.length === 3) {
      items.push(multipleChoiceItem({ id: `geografia-cont-${country}`, subject: "geografia", topic: "continenti", difficulty, prompt: `In quale continente si trova ${country}?`, answer: continent, distractors: conD, explanation: `${country} si trova in ${continent}.` }, rand));
    }
  }
  for (const fact of GEO_FACTS) {
    items.push(multipleChoiceItem({ id: `geografia-${fact.topic}-${items.length}`, subject: "geografia", topic: fact.topic, difficulty: fact.difficulty, prompt: fact.prompt, answer: fact.answer, distractors: fact.distractors, explanation: fact.explanation }, rand));
  }
  return { schemaVersion: 1, subject: "geografia", generator: "geografia-authored-v1", items };
}

// ---------------------------------------------------------------------------
// Scienze (materia nuova). Fatti derivati da src/data/greenhouse.ts (bisogni
// reali delle piante) + nucleo curato di metodo/materia/viventi. Autorato,
// non inventato a caso: i valori piante vengono dal simulatore Phaser.
// ---------------------------------------------------------------------------

const SCIENZE_CORE = [
  // --- Metodo scientifico (dal fare al ragionare sul perché) ---
  { topic: "metodo", difficulty: 1, prompt: "In un esperimento controllato, quante variabili cambi per volta?", answer: "Una sola", distractors: ["Tutte insieme", "Almeno tre", "Nessuna"], explanation: "Cambiando una sola variabile capisci quale causa l'effetto." },
  { topic: "metodo", difficulty: 2, prompt: "Cosa distingue un'ipotesi da una conclusione?", answer: "L'ipotesi è una previsione da verificare", distractors: ["Sono la stessa cosa", "L'ipotesi arriva dopo i dati", "La conclusione precede l'esperimento"], explanation: "Prima l'ipotesi (previsione), poi i dati, infine la conclusione." },
  { topic: "metodo", difficulty: 3, prompt: "A cosa serve un 'gruppo di controllo' in un esperimento?", answer: "A confrontare con qualcosa che non è stato cambiato", distractors: ["A rendere l'esperimento più lungo", "A cambiare più cose insieme", "A saltare le misure"], explanation: "Il gruppo di controllo mostra cosa succede senza la variabile che stai studiando." },
  { topic: "metodo", difficulty: 4, prompt: "Cambi luce E acqua insieme e la pianta cresce di più. Cosa puoi concludere?", answer: "Non sai quale delle due abbia agito", distractors: ["È stata solo la luce", "È stata solo l'acqua", "Sono state entrambe di sicuro"], explanation: "Cambiando due variabili insieme non puoi isolare la causa: vanno provate separatamente." },
  // --- Materia e stati (aggiungere un passaggio di stato alla volta) ---
  { topic: "materia", difficulty: 1, prompt: "Quali sono i tre stati principali della materia?", answer: "Solido, liquido, gassoso", distractors: ["Caldo, freddo, tiepido", "Duro, molle, liquido", "Pieno, vuoto, misto"], explanation: "Solido, liquido e gassoso sono i tre stati fondamentali." },
  { topic: "materia", difficulty: 1, prompt: "Come si chiama l'acqua allo stato solido?", answer: "Ghiaccio", distractors: ["Vapore", "Rugiada", "Nuvola"], explanation: "L'acqua solida è il ghiaccio; allo stato gassoso è vapore." },
  { topic: "materia", difficulty: 2, prompt: "Come si chiama il passaggio dell'acqua da liquido a vapore?", answer: "Evaporazione", distractors: ["Fusione", "Solidificazione", "Condensazione"], explanation: "Nell'evaporazione il liquido diventa gas; nella condensazione avviene il contrario." },
  { topic: "materia", difficulty: 2, prompt: "Come si chiama il passaggio da gas (vapore) a liquido?", answer: "Condensazione", distractors: ["Evaporazione", "Fusione", "Sublimazione"], explanation: "La condensazione forma le goccioline: è il contrario dell'evaporazione." },
  { topic: "materia", difficulty: 3, prompt: "Come si chiama il passaggio da solido a liquido?", answer: "Fusione", distractors: ["Evaporazione", "Sublimazione", "Solidificazione"], explanation: "Il ghiaccio che diventa acqua è fusione." },
  { topic: "materia", difficulty: 4, prompt: "Come si chiama il passaggio diretto da solido a gas, senza passare per il liquido?", answer: "Sublimazione", distractors: ["Fusione", "Evaporazione", "Condensazione"], explanation: "Nella sublimazione un solido diventa gas direttamente (es. la neve che 'sparisce' senza sciogliersi)." },
  // --- Esseri viventi ---
  { topic: "viventi", difficulty: 1, prompt: "Quale parte della pianta assorbe l'acqua dal terreno?", answer: "Le radici", distractors: ["I fiori", "Le foglie", "I frutti"], explanation: "Le radici assorbono acqua e sali minerali dal suolo." },
  { topic: "viventi", difficulty: 1, prompt: "Di cosa hanno bisogno le piante per fare la fotosintesi?", answer: "Luce, acqua e anidride carbonica", distractors: ["Solo acqua", "Buio e freddo", "Solo terra"], explanation: "Con luce, acqua e CO2 la pianta produce nutrimento e ossigeno." },
  { topic: "viventi", difficulty: 2, prompt: "Quale gas rilasciano le piante durante la fotosintesi?", answer: "Ossigeno", distractors: ["Anidride carbonica", "Azoto", "Idrogeno"], explanation: "Le piante assorbono CO2 e liberano ossigeno." },
  { topic: "viventi", difficulty: 2, prompt: "Come si chiamano gli animali che si nutrono solo di piante?", answer: "Erbivori", distractors: ["Carnivori", "Onnivori", "Predatori"], explanation: "Gli erbivori mangiano vegetali; i carnivori altri animali." },
  { topic: "viventi", difficulty: 3, prompt: "Come si chiamano gli animali che mangiano sia piante sia altri animali?", answer: "Onnivori", distractors: ["Erbivori", "Carnivori", "Decompositori"], explanation: "Gli onnivori (come l'orso o l'uomo) si nutrono di tutto." },
  { topic: "viventi", difficulty: 4, prompt: "Come si chiama il processo con cui gli esseri viventi ricavano energia usando l'ossigeno?", answer: "Respirazione cellulare", distractors: ["Fotosintesi", "Digestione", "Evaporazione"], explanation: "La respirazione cellulare libera l'energia del cibo; la fotosintesi invece la immagazzina nelle piante." },
  // --- Ecosistema ---
  { topic: "ecosistema", difficulty: 2, prompt: "In una catena alimentare, chi mangia gli erbivori?", answer: "I carnivori", distractors: ["Le piante", "Il Sole", "I produttori"], explanation: "I carnivori si nutrono di altri animali, come gli erbivori." },
  { topic: "ecosistema", difficulty: 3, prompt: "In una catena alimentare, chi produce il proprio nutrimento?", answer: "Le piante (produttori)", distractors: ["I predatori", "I decompositori", "Gli erbivori"], explanation: "Le piante sono i produttori: creano nutrimento con la fotosintesi." },
  { topic: "ecosistema", difficulty: 3, prompt: "Come si chiamano gli organismi (funghi, batteri) che decompongono i resti dei viventi?", answer: "Decompositori", distractors: ["Produttori", "Predatori", "Erbivori"], explanation: "I decompositori riciclano la materia, restituendo sostanze utili al terreno." },
  { topic: "ecosistema", difficulty: 4, prompt: "Se in un bosco sparissero tutte le piante, cosa accadrebbe agli erbivori?", answer: "Diminuirebbero per mancanza di cibo", distractors: ["Aumenterebbero", "Non cambierebbe nulla", "Diventerebbero carnivori"], explanation: "Senza produttori manca la base della catena alimentare: tutti gli altri ne risentono." },
  // --- Corpo umano ---
  { topic: "corpo", difficulty: 1, prompt: "Quale organo ci permette di pensare e comandare il corpo?", answer: "Il cervello", distractors: ["Il cuore", "Lo stomaco", "I muscoli"], explanation: "Il cervello dirige il corpo e ci fa pensare." },
  { topic: "corpo", difficulty: 2, prompt: "A cosa serve lo scheletro?", answer: "A sostenere e proteggere il corpo", distractors: ["A digerire il cibo", "A respirare", "A vedere"], explanation: "Le ossa sostengono il corpo e proteggono gli organi (il cranio protegge il cervello)." },
  { topic: "corpo", difficulty: 2, prompt: "Quale organo pompa il sangue nel corpo?", answer: "Il cuore", distractors: ["I polmoni", "Il fegato", "Lo stomaco"], explanation: "Il cuore spinge il sangue in tutto il corpo." },
  { topic: "corpo", difficulty: 3, prompt: "In quale organo avviene lo scambio di ossigeno con il sangue?", answer: "I polmoni", distractors: ["Il cuore", "I reni", "L'intestino"], explanation: "Nei polmoni il sangue prende ossigeno e cede anidride carbonica." },
  { topic: "corpo", difficulty: 4, prompt: "In quale organo il cibo digerito viene assorbito nel sangue?", answer: "L'intestino", distractors: ["I polmoni", "Il cuore", "I reni"], explanation: "Nell'intestino le sostanze nutritive passano nel sangue." },
  // --- Energia (nuovo topic) ---
  { topic: "energia", difficulty: 2, prompt: "Da dove arriva quasi tutta l'energia che riscalda la Terra?", answer: "Dal Sole", distractors: ["Dalla Luna", "Dal vento", "Dalle stelle lontane"], explanation: "Il Sole è la fonte principale di luce e calore per la Terra." },
  { topic: "energia", difficulty: 3, prompt: "Come si chiama l'energia prodotta dal vento che fa girare le pale?", answer: "Energia eolica", distractors: ["Energia idroelettrica", "Energia solare", "Energia nucleare"], explanation: "L'energia eolica sfrutta il vento; quella idroelettrica l'acqua che scorre." },
  { topic: "energia", difficulty: 3, prompt: "L'energia dell'acqua che scorre e fa girare le turbine si chiama…", answer: "Energia idroelettrica", distractors: ["Energia eolica", "Energia solare", "Energia geotermica"], explanation: "Le dighe sfruttano l'acqua in movimento per produrre elettricità." },
  { topic: "energia", difficulty: 4, prompt: "Quali fonti di energia non si esauriscono e inquinano poco?", answer: "Sole, vento e acqua (rinnovabili)", distractors: ["Carbone e petrolio", "Gas e benzina", "Plastica bruciata"], explanation: "Le fonti rinnovabili si rigenerano e sono più pulite dei combustibili fossili." },
  // --- Terra e universo (nuovo topic) ---
  { topic: "terra-universo", difficulty: 1, prompt: "Attorno a cosa gira la Terra?", answer: "Il Sole", distractors: ["La Luna", "Marte", "Una cometa"], explanation: "La Terra orbita intorno al Sole in circa un anno." },
  { topic: "terra-universo", difficulty: 2, prompt: "Come si chiama il satellite naturale della Terra?", answer: "La Luna", distractors: ["Marte", "Il Sole", "Venere"], explanation: "La Luna gira intorno alla Terra." },
  { topic: "terra-universo", difficulty: 2, prompt: "Cosa provoca l'alternarsi del giorno e della notte?", answer: "La rotazione della Terra su se stessa", distractors: ["La Terra che gira intorno al Sole", "Le nuvole", "La Luna che si sposta"], explanation: "Ruotando su se stessa, ogni punto della Terra si affaccia al Sole e poi all'ombra." },
  { topic: "terra-universo", difficulty: 4, prompt: "Cosa provoca soprattutto l'alternarsi delle stagioni?", answer: "L'inclinazione della Terra mentre gira intorno al Sole", distractors: ["La distanza dalla Luna", "Il vento", "Le maree"], explanation: "L'asse inclinato fa arrivare i raggi del Sole più o meno diretti nei vari periodi dell'anno." },
  // --- Ambiente (nuovo topic) ---
  { topic: "ambiente", difficulty: 1, prompt: "Cosa dovremmo fare con carta, plastica e vetro per aiutare l'ambiente?", answer: "Fare la raccolta differenziata", distractors: ["Buttarli tutti insieme", "Bruciarli in casa", "Lasciarli a terra"], explanation: "Separare i rifiuti permette di riciclarli e sprecare meno risorse." },
  { topic: "ambiente", difficulty: 2, prompt: "Perché è importante non sprecare l'acqua?", answer: "È una risorsa preziosa e limitata", distractors: ["Perché è pesante", "Perché è colorata", "Non è importante"], explanation: "L'acqua dolce pulita è limitata: va usata con attenzione." },
  { topic: "ambiente", difficulty: 3, prompt: "Come si chiama l'aumento della temperatura del pianeta legato anche ai gas prodotti dall'uomo?", answer: "Riscaldamento globale", distractors: ["Effetto arcobaleno", "Effetto marea", "Effetto eco"], explanation: "L'eccesso di gas serra trattiene più calore e riscalda il pianeta." },
];

function scienzeBank(greenhousePlants) {
  const rand = rng(20260729);
  const items = SCIENZE_CORE.map((q, i) =>
    multipleChoiceItem({ id: `scienze-${q.topic}-${i}`, subject: "scienze", topic: q.topic, difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand),
  );
  // Derivati dal simulatore serra: confronto luce ideale tra piante reali.
  const byLight = [...greenhousePlants].sort((a, b) => a.idealValues.light - b.idealValues.light);
  if (byLight.length >= 3) {
    const brightest = byLight[byLight.length - 1];
    const dimmest = byLight[0];
    items.push(multipleChoiceItem({ id: "scienze-serra-luce", subject: "scienze", topic: "viventi", difficulty: 3, prompt: `Nella serra, quale pianta ha bisogno di più luce?`, answer: brightest.name, distractors: byLight.slice(0, byLight.length - 1).map((p) => p.name), explanation: `${brightest.name}: ${brightest.scientificHint}` }, rand));
    items.push(multipleChoiceItem({ id: "scienze-serra-ombra", subject: "scienze", topic: "viventi", difficulty: 3, prompt: `Nella serra, quale pianta preferisce la luce più morbida?`, answer: dimmest.name, distractors: byLight.slice(1).map((p) => p.name), explanation: `${dimmest.name}: ${dimmest.scientificHint}` }, rand));
  }
  return { schemaVersion: 1, subject: "scienze", generator: "scienze-authored-v1", items };
}

// ---------------------------------------------------------------------------
// Cittadinanza (materia nuova). Regole civiche e dilemma da src/data/smartCity.ts
// (contenuto reale del prototipo) + nucleo curato di educazione civica. Valori,
// non politica di parte.
// ---------------------------------------------------------------------------

const CITTADINANZA_CORE = [
  // --- Regole ---
  { topic: "regole", difficulty: 1, prompt: "A cosa servono le regole in una comunità?", answer: "A vivere insieme in modo giusto e sicuro", distractors: ["A punire per divertimento", "A far comandare i più forti", "A non fare nulla"], explanation: "Le regole servono a proteggere tutti e a rendere possibile la convivenza." },
  { topic: "regole", difficulty: 2, prompt: "Se una regola è giusta e vale per tutti, deve valere anche…", answer: "Per chi l'ha proposta", distractors: ["Solo per i bambini", "Solo per i più deboli", "Per nessuno in realtà"], explanation: "Una regola giusta vale allo stesso modo per tutti, senza eccezioni di comodo." },
  { topic: "regole", difficulty: 3, prompt: "Cosa succede a un gioco se ognuno cambia le regole a suo piacere?", answer: "Diventa ingiusto e si litiga", distractors: ["Diventa più bello", "Non cambia nulla", "Finisce sempre in parità"], explanation: "Le regole condivise permettono di giocare (e vivere) senza litigare." },
  // --- Diritti e doveri ---
  { topic: "diritti-doveri", difficulty: 1, prompt: "Ricevere cure quando si è malati è un…", answer: "Diritto", distractors: ["Favore", "Premio", "Lusso"], explanation: "La salute è un diritto garantito a ogni persona." },
  { topic: "diritti-doveri", difficulty: 2, prompt: "Andare a scuola per un bambino è soprattutto…", answer: "Un diritto (e insieme un dovere)", distractors: ["Solo una punizione", "Una scelta senza importanza", "Un favore agli insegnanti"], explanation: "L'istruzione è un diritto garantito e un dovere verso se stessi." },
  { topic: "diritti-doveri", difficulty: 3, prompt: "Rispettare l'ambiente pulendo dove si sporca è…", answer: "Un dovere di ogni cittadino", distractors: ["Compito solo del Comune", "Inutile", "Un obbligo solo per gli adulti"], explanation: "Prendersi cura dei beni comuni è responsabilità di tutti." },
  { topic: "diritti-doveri", difficulty: 4, prompt: "La libertà di una persona di solito finisce dove…", answer: "Comincia il diritto di un'altra", distractors: ["Comincia il suo capriccio", "Lei vuole", "Nessuno la vede"], explanation: "La mia libertà non può calpestare i diritti degli altri: è il limite della convivenza." },
  // --- Partecipazione ---
  { topic: "partecipazione", difficulty: 1, prompt: "In classe, per decidere insieme dove andare in gita, conviene…", answer: "Parlarne e poi votare", distractors: ["Decide il più alto", "Non andare da nessuna parte", "Sceglie chi urla di più"], explanation: "Parlare e votare permette una scelta condivisa." },
  { topic: "partecipazione", difficulty: 2, prompt: "In una decisione di gruppo, il modo più giusto per scegliere è…", answer: "Ascoltare tutti e poi votare", distractors: ["Decide solo il più rumoroso", "Non decidere mai", "Sceglie chi è arrivato prima"], explanation: "Ascolto e voto permettono una scelta condivisa e rispettosa." },
  { topic: "partecipazione", difficulty: 3, prompt: "Cosa vuol dire rispettare il risultato di un voto?", answer: "Accettare la scelta della maggioranza", distractors: ["Fare comunque di testa propria", "Rifare il voto finché vinci tu", "Arrabbiarsi con chi ha vinto"], explanation: "In una scelta democratica si accetta la decisione della maggioranza, nel rispetto delle minoranze." },
  // --- Istituzioni ---
  { topic: "istituzioni", difficulty: 2, prompt: "Chi guida un Comune ed è eletto dai cittadini?", answer: "Il sindaco", distractors: ["Il preside", "Il giudice", "Il medico"], explanation: "Il sindaco è a capo del Comune, scelto col voto dei cittadini." },
  { topic: "istituzioni", difficulty: 3, prompt: "Come si chiama la legge fondamentale dello Stato italiano?", answer: "La Costituzione", distractors: ["Il regolamento", "Il decreto", "Lo statuto comunale"], explanation: "La Costituzione è la legge più importante, base di tutte le altre." },
  { topic: "istituzioni", difficulty: 3, prompt: "A cosa serve soprattutto il Parlamento?", answer: "A fare le leggi", distractors: ["A costruire le strade", "A insegnare a scuola", "A curare i malati"], explanation: "Il Parlamento discute e approva le leggi dello Stato." },
  { topic: "istituzioni", difficulty: 4, prompt: "Come si chiama il diritto dei cittadini adulti di scegliere chi li governa?", answer: "Il diritto di voto", distractors: ["Il diritto d'autore", "Il diritto di sciopero", "Il diritto di replica"], explanation: "Con il voto i cittadini scelgono i propri rappresentanti." },
  // --- Convivenza ---
  { topic: "convivenza", difficulty: 1, prompt: "Se qualcuno la pensa diversamente da te, la cosa giusta è…", answer: "Ascoltarlo con rispetto", distractors: ["Ignorarlo", "Prenderlo in giro", "Costringerlo a cambiare"], explanation: "Il rispetto delle idee altrui è alla base della convivenza civile." },
  { topic: "convivenza", difficulty: 2, prompt: "Se vedi un compagno preso in giro dagli altri, la cosa civile è…", answer: "Difenderlo o avvisare un adulto", distractors: ["Ridere con gli altri", "Fare finta di niente", "Filmarlo per gioco"], explanation: "Non restare indifferenti aiuta chi è in difficoltà." },
  { topic: "convivenza", difficulty: 3, prompt: "Cosa significa 'tolleranza'?", answer: "Rispettare chi è diverso da noi", distractors: ["Fare sempre come dico io", "Ignorare tutti", "Comandare gli altri"], explanation: "La tolleranza accetta le differenze come una ricchezza." },
  // --- Sicurezza (nuovo topic) ---
  { topic: "sicurezza", difficulty: 1, prompt: "Quando attraversi la strada, devi farlo…", answer: "Sulle strisce, guardando bene", distractors: ["Di corsa dove capita", "Col cellulare in mano", "A occhi chiusi"], explanation: "Le strisce pedonali e l'attenzione ti proteggono." },
  { topic: "sicurezza", difficulty: 2, prompt: "In bicicletta, cosa è bene indossare per proteggere la testa?", answer: "Il casco", distractors: ["Le cuffie", "Un cappello di lana", "Niente"], explanation: "Il casco protegge in caso di caduta." },
  { topic: "sicurezza", difficulty: 3, prompt: "Se scopri un pericolo (fuga di gas, un principio d'incendio), la cosa giusta è…", answer: "Avvisare subito un adulto o i soccorsi", distractors: ["Nasconderti e tacere", "Affrontarlo da solo", "Aspettare che passi"], explanation: "Chiedere aiuto in fretta è la scelta più sicura." },
  // --- Cittadinanza digitale (nuovo topic) ---
  { topic: "digitale", difficulty: 2, prompt: "Un compagno ti chiede la password del tuo account. Cosa fai?", answer: "Non la dai: le password restano segrete", distractors: ["Gliela dici subito", "La scrivi sul banco", "La pubblichi in chat"], explanation: "Le password sono personali: condividerle mette a rischio i tuoi dati." },
  { topic: "digitale", difficulty: 3, prompt: "Se online qualcuno ti tratta male (cyberbullismo), conviene…", answer: "Non rispondere e dirlo a un adulto di fiducia", distractors: ["Rispondere con insulti", "Tenerlo segreto per sempre", "Vendicarti online"], explanation: "Parlarne con un adulto aiuta a fermare il problema; rispondere lo peggiora." },
  { topic: "digitale", difficulty: 4, prompt: "Prima di credere e condividere una notizia trovata sui social, è giusto…", answer: "Verificarla su fonti affidabili", distractors: ["Condividerla subito", "Crederci perché ha molti like", "Ignorare da chi viene"], explanation: "Controllare le fonti evita di diffondere notizie false." },
  // --- Denaro ed economia civica (nuovo topic) ---
  { topic: "denaro", difficulty: 1, prompt: "Cosa vuol dire 'risparmiare'?", answer: "Mettere da parte invece di spendere tutto", distractors: ["Spendere il doppio", "Prestare a tutti", "Buttare i soldi"], explanation: "Risparmiare significa conservare una parte per il futuro." },
  { topic: "denaro", difficulty: 2, prompt: "A cosa servono soprattutto le tasse pagate dai cittadini?", answer: "A pagare servizi comuni: scuole, strade, ospedali", distractors: ["A fare regali a chi governa", "A niente di utile", "A far sparire i soldi"], explanation: "Le tasse finanziano i servizi che usiamo tutti." },
  { topic: "denaro", difficulty: 3, prompt: "Comprare una cosa che non ti serve solo perché è in offerta è…", answer: "Spesso uno spreco", distractors: ["Sempre un affare", "Un dovere", "Un risparmio sicuro"], explanation: "Lo sconto conviene solo se ti serve davvero: altrimenti è denaro sprecato." },
];

function cittadinanzaBank(cityRules, civicDilemma, energyPlans) {
  const rand = rng(20260730);
  const items = CITTADINANZA_CORE.map((q, i) =>
    multipleChoiceItem({ id: `cittadinanza-${q.topic}-${i}`, subject: "cittadinanza", topic: q.topic, difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand),
  );
  // Regole civiche della Città Intelligente (logica condizionale + priorità).
  for (const rule of cityRules) {
    const distractors = rule.options.filter((o) => o !== rule.answer);
    if (distractors.length >= 3) distractors.length = 3;
    if (distractors.length === (rule.options.length - 1) && distractors.length >= 2) {
      // riempi a 3 se servono, con opzioni di altre regole
      const extra = cityRules.flatMap((r) => r.options).filter((o) => o !== rule.answer && !distractors.includes(o));
      while (distractors.length < 3 && extra.length) distractors.push(extra.shift());
    }
    if (distractors.length === 3) {
      items.push(multipleChoiceItem({ id: `cittadinanza-regola-${rule.id}`, subject: "cittadinanza", topic: "servizi-pubblici", difficulty: 3, prompt: `${rule.condition} …qual è la scelta giusta?`, answer: rule.answer, distractors, explanation: rule.hint }, rand));
    }
  }
  // Dilemma civico: la vita e la salute vengono prima.
  const correct = civicDilemma.options.find((o) => o.correct);
  const wrong = civicDilemma.options.filter((o) => !o.correct).map((o) => o.label);
  if (correct && wrong.length >= 2) {
    const distractors = wrong.slice(0, 2);
    // servono 3 distrattori: aggiungi un'opzione neutra plausibile
    distractors.push("Illuminazione decorativa + insegne");
    items.push(multipleChoiceItem({ id: "cittadinanza-dilemma", subject: "cittadinanza", topic: "priorità-civiche", difficulty: 4, prompt: civicDilemma.prompt, answer: correct.label, distractors: distractors.slice(0, 3), explanation: correct.reason }, rand));
  }
  return { schemaVersion: 1, subject: "cittadinanza", generator: "cittadinanza-authored-v1", items };
}

// ---------------------------------------------------------------------------
// Logica (materia nuova). Generatore DETERMINISTICO: sequenze numeriche, regole
// di serie, esclusioni. Zero rischio fattuale (la risposta si dimostra). NB: la
// "memoria" (Simon, griglia lampo) è meccanica interattiva a tempo e NON entra
// qui: non è rappresentabile come item a scelta multipla — decisione a parte.
// ---------------------------------------------------------------------------

function numericDistractors(answer, rand) {
  const set = new Set();
  const deltas = [1, -1, 2, -2, 3, answer + 1, -3];
  for (const d of deltas) {
    const candidate = Math.abs(d) > answer ? answer + Math.abs(d) : answer + d;
    if (candidate !== answer && candidate > 0) set.add(candidate);
    if (set.size >= 3) break;
  }
  let bump = 4;
  while (set.size < 3) { if (answer + bump !== answer) set.add(answer + bump); bump += 1; }
  return shuffle([...set], rand).slice(0, 3).map(String);
}

function logicaBank() {
  const rand = rng(20260731);
  const items = [];
  // Sequenze aritmetiche (+k): difficoltà 1-2.
  const arithmetic = [
    { start: 2, step: 2, difficulty: 1 }, { start: 1, step: 2, difficulty: 1 },
    { start: 3, step: 3, difficulty: 1 }, { start: 5, step: 5, difficulty: 1 },
    { start: 4, step: 3, difficulty: 2 }, { start: 7, step: 4, difficulty: 2 },
    { start: 10, step: 10, difficulty: 1 }, { start: 6, step: 6, difficulty: 2 },
    { start: 2, step: 4, difficulty: 2 }, { start: 9, step: 3, difficulty: 2 },
  ];
  for (const { start, step, difficulty } of arithmetic) {
    const seq = [start, start + step, start + 2 * step, start + 3 * step];
    const answer = start + 4 * step;
    items.push(multipleChoiceItem({ id: `logica-arit-${start}-${step}`, subject: "logica", topic: "sequenze", difficulty, prompt: `Quale numero continua la serie: ${seq.join(", ")}, ?`, answer: String(answer), distractors: numericDistractors(answer, rand), explanation: `Si aggiunge ${step} ogni volta: ${seq[3]} + ${step} = ${answer}.` }, rand));
  }
  // Sequenze geometriche (×k): difficoltà 3.
  const geometric = [
    { start: 1, ratio: 2 }, { start: 1, ratio: 3 }, { start: 2, ratio: 2 }, { start: 3, ratio: 2 }, { start: 1, ratio: 4 },
  ];
  for (const { start, ratio } of geometric) {
    const seq = [start, start * ratio, start * ratio * ratio, start * ratio ** 3];
    const answer = start * ratio ** 4;
    items.push(multipleChoiceItem({ id: `logica-geom-${start}-${ratio}`, subject: "logica", topic: "sequenze", difficulty: 3, prompt: `Quale numero continua la serie: ${seq.join(", ")}, ?`, answer: String(answer), distractors: numericDistractors(answer, rand), explanation: `Si moltiplica per ${ratio} ogni volta: ${seq[3]} × ${ratio} = ${answer}.` }, rand));
  }
  // Quadrati e serie a due passi: difficoltà 4.
  const squares = [1, 4, 9, 16];
  items.push(multipleChoiceItem({ id: "logica-quadrati", subject: "logica", topic: "sequenze", difficulty: 4, prompt: `Quale numero continua la serie: ${squares.join(", ")}, ?`, answer: "25", distractors: numericDistractors(25, rand), explanation: "Sono i quadrati: 1, 4, 9, 16, 25 (5×5)." }, rand));
  const alternating = [{ start: 2, a: 2, b: 3 }, { start: 1, a: 3, b: 1 }, { start: 5, a: 1, b: 4 }];
  for (const { start, a, b } of alternating) {
    const seq = [start, start + a, start + a + b, start + 2 * a + b];
    const answer = start + 2 * a + 2 * b;
    items.push(multipleChoiceItem({ id: `logica-alt-${start}-${a}-${b}`, subject: "logica", topic: "sequenze", difficulty: 4, prompt: `Quale numero continua la serie: ${seq.join(", ")}, ?`, answer: String(answer), distractors: numericDistractors(answer, rand), explanation: `La serie alterna +${a} e +${b}: ${seq[3]} + ${b} = ${answer}.` }, rand));
  }
  // Esclusioni logiche (odd-one-out): difficoltà 2-3.
  const oddOneOut = [
    { set: ["2", "4", "6", "7"], answer: "7", topic: "esclusioni", difficulty: 2, explanation: "7 è dispari; gli altri sono pari." },
    { set: ["3", "5", "9", "7"], answer: "9", topic: "esclusioni", difficulty: 3, explanation: "9 non è primo (3×3); gli altri sono numeri primi." },
    { set: ["10", "20", "25", "30"], answer: "25", topic: "esclusioni", difficulty: 2, explanation: "25 non è un multiplo di 10; gli altri sì." },
  ];
  for (const q of oddOneOut) {
    const distractors = q.set.filter((n) => n !== q.answer);
    items.push(multipleChoiceItem({ id: `logica-odd-${q.set.join("")}`, subject: "logica", topic: q.topic, difficulty: q.difficulty, prompt: `Quale numero non appartiene al gruppo: ${q.set.join(", ")}?`, answer: q.answer, distractors, explanation: q.explanation }, rand));
  }
  // Sequenze speciali: decrescente (difficoltà 2) e Fibonacci (difficoltà 4).
  {
    const dec = [20, 17, 14, 11];
    items.push(multipleChoiceItem({ id: "logica-dec-20-3", subject: "logica", topic: "sequenze", difficulty: 2, prompt: `Quale numero continua la serie: ${dec.join(", ")}, ?`, answer: "8", distractors: numericDistractors(8, rand), explanation: "Si toglie 3 ogni volta: 11 − 3 = 8." }, rand));
    const fib = [1, 1, 2, 3];
    items.push(multipleChoiceItem({ id: "logica-fib", subject: "logica", topic: "sequenze", difficulty: 4, prompt: `Quale numero continua la serie: ${fib.join(", ")}, ?`, answer: "5", distractors: numericDistractors(5, rand), explanation: "Ogni numero è la somma dei due precedenti: 2 + 3 = 5." }, rand));
  }
  // Esclusioni per categoria (odd-one-out verbale): difficoltà 2-3.
  const wordOddOneOut = [
    { set: ["cane", "mela", "gatto", "cavallo"], answer: "mela", difficulty: 2, explanation: "La mela è un frutto; gli altri sono animali." },
    { set: ["rosa", "tulipano", "quercia", "margherita"], answer: "quercia", difficulty: 3, explanation: "La quercia è un albero; gli altri sono fiori." },
    { set: ["rosso", "verde", "tavolo", "blu"], answer: "tavolo", difficulty: 2, explanation: "Il tavolo non è un colore." },
    { set: ["lunedì", "marzo", "giovedì", "domenica"], answer: "marzo", difficulty: 3, explanation: "Marzo è un mese; gli altri sono giorni della settimana." },
  ];
  for (const q of wordOddOneOut) {
    const distractors = q.set.filter((w) => w !== q.answer);
    items.push(multipleChoiceItem({ id: `logica-wodd-${q.answer}`, subject: "logica", topic: "esclusioni", difficulty: q.difficulty, prompt: `Quale parola non appartiene al gruppo: ${q.set.join(", ")}?`, answer: q.answer, distractors, explanation: q.explanation }, rand));
  }
  // Analogie (relazioni tra coppie): difficoltà 2-4.
  const analogie = [
    { difficulty: 2, prompt: "Grande sta a piccolo come alto sta a…?", answer: "basso", distractors: ["lungo", "largo", "veloce"], explanation: "Sono coppie di contrari: grande/piccolo, alto/basso." },
    { difficulty: 2, prompt: "Cane sta a cucciolo come gatto sta a…?", answer: "gattino", distractors: ["cavallo", "pulcino", "agnello"], explanation: "Il piccolo del gatto è il gattino." },
    { difficulty: 3, prompt: "Mano sta a guanto come piede sta a…?", answer: "scarpa", distractors: ["cappello", "sciarpa", "cintura"], explanation: "Il guanto veste la mano, la scarpa il piede." },
    { difficulty: 3, prompt: "Giorno sta a Sole come notte sta a…?", answer: "Luna", distractors: ["lampada", "buio totale", "stella cadente"], explanation: "Di giorno splende il Sole, di notte la Luna." },
    { difficulty: 4, prompt: "Libro sta a leggere come musica sta a…?", answer: "ascoltare", distractors: ["guardare", "scrivere", "annusare"], explanation: "Un libro si legge, la musica si ascolta." },
  ];
  for (const q of analogie) {
    items.push(multipleChoiceItem({ id: `logica-analogia-${q.answer}`, subject: "logica", topic: "analogie", difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand));
  }
  // Deduzioni (inferenze semplici, sempre dimostrabili): difficoltà 3-4.
  const deduzioni = [
    { difficulty: 3, prompt: "Tutti i gatti hanno la coda. Fufi è un gatto. Allora Fufi…", answer: "ha la coda", distractors: ["non ha la coda", "forse ha la coda", "è un cane"], explanation: "Se vale per tutti i gatti e Fufi è un gatto, vale anche per Fufi." },
    { difficulty: 3, prompt: "Nessun pesce vola. Nemo è un pesce. Quindi Nemo…", answer: "non vola", distractors: ["vola", "forse vola", "è un uccello"], explanation: "Se nessun pesce vola e Nemo è un pesce, allora Nemo non vola." },
    { difficulty: 4, prompt: "Se piove, Lea prende l'ombrello. Oggi Lea NON ha l'ombrello. Allora…", answer: "non sta piovendo", distractors: ["sta piovendo", "ha perso l'ombrello", "fa molto caldo"], explanation: "Se piovesse avrebbe l'ombrello; non ce l'ha, quindi non piove." },
    { difficulty: 4, prompt: "Marco è più alto di Sara. Sara è più alta di Ugo. Chi è il più basso?", answer: "Ugo", distractors: ["Marco", "Sara", "Sono uguali"], explanation: "Marco > Sara > Ugo: il più basso è Ugo." },
    { difficulty: 4, prompt: "Nella scatola ci sono solo palline rosse e blu. Ne peschi una e NON è rossa. Allora è…", answer: "blu", distractors: ["rossa", "verde", "non si può sapere"], explanation: "Ci sono solo rosse e blu: se non è rossa, per forza è blu." },
  ];
  for (const q of deduzioni) {
    items.push(multipleChoiceItem({ id: `logica-deduzione-${q.prompt.length}-${q.answer}`, subject: "logica", topic: "deduzioni", difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand));
  }
  return { schemaVersion: 1, subject: "logica", generator: "logica-generated-v2", items };
}

// ---------------------------------------------------------------------------
// Validazione: risposta sempre tra le opzioni, difficoltà 1-4, campi non vuoti.
// ---------------------------------------------------------------------------

function validate(name, bank) {
  for (const item of bank.items) {
    const problems = [];
    if (!item.prompt) problems.push("prompt vuoto");
    if (!item.topic) problems.push("topic vuoto");
    if (!(item.difficulty >= 1 && item.difficulty <= 4)) problems.push(`difficulty fuori range: ${item.difficulty}`);
    if (!item.explanation) problems.push("explanation vuota");
    if (item.format === "multiple_choice") {
      if (!item.options.includes(item.answer)) problems.push("answer non tra le opzioni");
      if (new Set(item.options).size !== item.options.length) problems.push("opzioni duplicate");
    }
    if (problems.length > 0) {
      throw new Error(`Banco '${name}' item '${item.id}': ${problems.join(", ")}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Bake
// ---------------------------------------------------------------------------

const tsUrl = (...parts) => pathToFileURL(join(root, "src", "data", "procedural", ...parts)).href;
const dataUrl = (...parts) => pathToFileURL(join(root, "src", "data", ...parts)).href;
const [italianMod, englishMod, latinMod, circuitMod, pythonMod, greenhouseMod, smartCityMod] = await Promise.all([
  import(tsUrl("italianVocabularyBank.ts")),
  import(tsUrl("englishVocabularyBank.ts")),
  import(tsUrl("latinCurriculum.ts")),
  import(tsUrl("circuitTemplates.ts")),
  import(tsUrl("pythonPrinciples.ts")),
  import(dataUrl("greenhouse.ts")),
  import(dataUrl("smartCity.ts")),
]);

const BANKS = {
  "matematica-tabelline": tabellineBank(),
  "italiano-base": italianoBank(italianMod.italianVocabularyEntries),
  "inglese-base": ingleseBank(englishMod.englishVocabularyEntries),
  "latino-base": latinoBank(latinMod.latinNouns, latinMod.latinNounForm, latinMod.distinctiveCases),
  "elettronica-base": elettronicaBank(circuitMod.circuitComponentGuide, circuitMod.circuitFaultTemplates),
  "coding-base": codingBank(pythonMod.pythonPrincipleSeeds),
  "fisica-base": fisicaBank(rng(20260732)),
  "musica-base": musicaBank(rng(20260733)),
  // Materie nuove (scope ampliato 2026-07-21):
  "geografia-base": geografiaBank(),
  "scienze-base": scienzeBank(greenhouseMod.greenhousePlants),
  "cittadinanza-base": cittadinanzaBank(smartCityMod.cityRules, smartCityMod.civicDilemma, smartCityMod.energyPlans),
  "logica-base": logicaBank(),
};

await mkdir(outDir, { recursive: true });
for (const [name, bank] of Object.entries(BANKS)) {
  validate(name, bank);
  const file = join(outDir, `${name}.json`);
  await writeFile(file, JSON.stringify(bank, null, "\t") + "\n", "utf8");
  console.log(`Banco '${name}': ${bank.items.length} item → ${file}`);
}
