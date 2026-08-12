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

// Distrattori PLAUSIBILI, non soltanto diversi. Due criteri didattici:
//  - lunghezza confrontabile con la risposta: se la risposta corretta è sempre
//    l'opzione più lunga, il bambino la indovina senza sapere il contenuto e la
//    padronanza misurata non vale nulla (indizio "test-wise" classico);
//  - varietà: tra i candidati di lunghezza simile si sceglie a caso, così due
//    item con risposte simili non ricevono sempre gli stessi distrattori.
const LENGTH_WINDOW = 4; // candidati per distrattore tra cui sorteggiare
function pickDistractors(pool, exclude, count, rand) {
  const unique = [...new Set(pool.filter((v) => v !== exclude))];
  if (unique.length <= count) return shuffle(unique, rand);
  const target = String(exclude).length;
  // La rosa di candidati resta comunque più stretta del pool, altrimenti su pool
  // piccoli la preferenza di lunghezza non avrebbe alcun effetto.
  const window = Math.max(count + 1, Math.min(count * LENGTH_WINDOW, Math.ceil(unique.length / 2)));
  const shortlist = shuffle(unique, rand)
    .sort((a, b) => Math.abs(String(a).length - target) - Math.abs(String(b).length - target))
    .slice(0, window);
  return shuffle(shortlist, rand).slice(0, count);
}

// Posizione della risposta: a ROTAZIONE, non a caso. Con un mescolamento puro i
// banchi piccoli finiscono sbilanciati per solo effetto del caso (misurato: la
// risposta di logica cadeva in terza posizione nel 45% degli item, quella di
// scienze in seconda nel 42%) e un bambino che ne fa molti può accorgersene. La
// rotazione per materia rende la posizione esattamente uniforme; i distrattori
// restano mescolati tra loro, quindi le alternative non si ripetono in ordine fisso.
const answerSlotBySubject = new Map();

function multipleChoiceItem({ id, subject, topic, difficulty, prompt, answer, distractors, explanation }, rand) {
  const options = shuffle(distractors, rand);
  const slots = options.length + 1;
  const slot = (answerSlotBySubject.get(subject) ?? 0) % slots;
  answerSlotBySubject.set(subject, slot + 1);
  options.splice(slot, 0, answer);
  return { id, subject, topic, difficulty, format: "multiple_choice", prompt, options, answer, explanation };
}

// ---------------------------------------------------------------------------
// Matematica: generatore locale di tabelline (invariato, vedi nota in testa).
// ---------------------------------------------------------------------------

const RANGES = { 1: [2, 5], 2: [2, 10], 3: [3, 12], 4: [6, 12] };

// Come RICOSTRUIRE il risultato, non come rileggerlo.
//
// «2 × 2 = 4.» era la spiegazione di tutte e 284 le tabelline: ripete la domanda
// e la risposta e non lascia niente in mano a chi ha sbagliato. Qui la
// spiegazione dà la scorciatoia — e la sceglie sul fattore che ce l'ha più
// corta, non sul primo dei due: per 7 × 8 conviene ragionare sull'8 (raddoppia
// tre volte) o sul 7 (× 5 più × 2), non contare otto volte sette.
const TIMES_SHORTCUT = {
  1: (n) => `moltiplicare per 1 lascia il numero com'è, quindi resta ${n}`,
  10: (n) => `per 10 basta aggiungere uno zero: ${n} diventa ${n * 10}`,
  5: (n) => `per 5 fai la metà di ${n} × 10, cioè la metà di ${n * 10}: fa ${n * 5}`,
  2: (n) => `per 2 basta il doppio: ${n} + ${n} fa ${n * 2}`,
  9: (n) => `per 9 fai ${n} × 10 meno ${n}: ${n * 10} − ${n} fa ${n * 9}`,
  11: (n) => (n < 10
    ? `per 11 con una cifra sola basta ripeterla: ${n} diventa ${n}${n}`
    : `per 11 fai ${n} × 10 più ${n}: ${n * 10} + ${n} fa ${n * 11}`),
  4: (n) => `per 4 raddoppi due volte: ${n} → ${n * 2} → ${n * 4}`,
  3: (n) => `per 3 fai il doppio più il numero: ${n * 2} + ${n} fa ${n * 3}`,
  12: (n) => `per 12 fai ${n} × 10 più ${n} × 2: ${n * 10} + ${n * 2} fa ${n * 12}`,
  6: (n) => `per 6 fai ${n} × 5 più ${n}: ${n * 5} + ${n} fa ${n * 6}`,
  8: (n) => `per 8 raddoppi tre volte: ${n} → ${n * 2} → ${n * 4} → ${n * 8}`,
  7: (n) => `per 7 fai ${n} × 5 più ${n} × 2: ${n * 5} + ${n * 2} fa ${n * 7}`,
};

// Dal più comodo al meno comodo: è l'ordine in cui un bambino trova la strada
// più in fretta, non l'ordine dei numeri.
const SHORTCUT_RANK = [10, 5, 2, 9, 11, 4, 3, 12, 6, 8, 7, 1];

function timesExplanation(a, b) {
  const easier = SHORTCUT_RANK.indexOf(a) <= SHORTCUT_RANK.indexOf(b) ? a : b;
  const other = easier === a ? b : a;
  const trick = TIMES_SHORTCUT[easier](other);
  if (a === b) {
    return `${a} × ${a} fa ${a * b}: è il quadrato di ${a}. Se non lo ricordi, ${trick}.`;
  }
  return `Se non ricordi ${a} × ${b}, ${trick}. E ${b} × ${a} dà lo stesso risultato: cambiare l'ordine non cambia il prodotto.`;
}

function timesItem(a, b, difficulty, rand) {
  const answer = a * b;
  const useNumeric = rand() < 0.25;
  const explanation = timesExplanation(a, b);
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
// Due parole dello stesso gruppo, diverse dalla voce stessa. Deterministiche:
// dipendono dall'ordine della tabella, non dal generatore casuale, così due
// bake danno lo stesso banco.
function vocabularyExplanation(entry, defField, neighbours) {
  const base = `"${entry.term}": ${entry[defField]}.`;
  // Le vicine RUOTANO con la posizione della voce nel gruppo. Prendendo sempre
  // le prime due, in un gruppo di ottanta parole la stessa coda comparirebbe
  // ottanta volte: dopo la terza smette di essere informazione e diventa
  // rumore. Ruotando, ogni item mostra una coppia diversa e nell'arco del
  // gruppo si vede tutto il campo semantico.
  const gruppo = neighbours.get(`${entry.wordClass}::${entry.category}`) ?? [];
  const mia = gruppo.findIndex((altra) => altra.id === entry.id);
  const vicine = gruppo.length < 3
    ? gruppo.filter((altra) => altra.id !== entry.id).slice(0, 2)
    : [gruppo[(mia + 1) % gruppo.length], gruppo[(mia + 2) % gruppo.length]];
  if (vicine.length < 2) return base;
  const elenco = vicine.map((v) => `${v.term} = ${v[defField]}`).join(", ");
  return `${base} Stesso gruppo: ${elenco}.`;
}

function vocabularyBank(subject, entries, { fields, defField, promptFor }) {
  // Vicine per (classe grammaticale + area di significato): lo stesso criterio
  // con cui si scelgono i distrattori, perché è lo stesso il campo semantico.
  const neighbours = new Map();
  for (const entry of entries) {
    const chiave = `${entry.wordClass}::${entry.category}`;
    neighbours.set(chiave, [...(neighbours.get(chiave) ?? []), entry]);
  }
  const rand = rng(subject === "italiano" ? 20260721 : 20260722);
  // Due pool per campo: uno per (classe grammaticale + AREA di significato) e uno
  // per sola classe grammaticale. I distrattori migliori vengono dalla stessa area
  // ("premessa" contro "ipotesi/conclusione", non contro "pranzo"): così l'item
  // chiede davvero di distinguere il significato, non il campo semantico.
  const pools = new Map(); // field -> {byTopic: Map, byClass: Map}
  for (const field of fields) {
    const byTopic = new Map();
    const byClass = new Map();
    for (const entry of entries) {
      const topicKey = `${entry.wordClass}::${entry.category}`;
      byTopic.set(topicKey, [...(byTopic.get(topicKey) ?? []), entry[field]]);
      byClass.set(entry.wordClass, [...(byClass.get(entry.wordClass) ?? []), entry[field]]);
    }
    pools.set(field, { byTopic, byClass });
  }
  const items = [];
  entries.forEach((entry, index) => {
    const { prompt, answer, field } = promptFor(entry, index);
    const fieldPools = pools.get(field);
    // Ripiego sulla sola classe grammaticale solo se l'area non ha abbastanza
    // parole: mai distrattori fittizi, mai item senza tre alternative.
    const sameTopic = fieldPools.byTopic.get(`${entry.wordClass}::${entry.category}`) ?? [];
    const pool = new Set(sameTopic.filter((v) => v !== answer)).size >= 3
      ? sameTopic
      : fieldPools.byClass.get(entry.wordClass) ?? [];
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
          // Quando la voce porta una `note` autorata, quella vince: è il caso
          // dei falsi amici, dove ripetere la coppia è addirittura dannoso
          // («library: biblioteca» non avverte che NON è la libreria).
          //
          // Altrimenti alla coppia si aggiungono due parole vicine dello stesso
          // campo. Fino al 5 agosto 2026 la spiegazione era la sola coppia —
          // «"check": controllare» dopo la domanda «come si dice controllare?»
          // — cioè la ripetizione di quello che il bambino aveva appena
          // risposto: 968 item su 1109 non insegnavano niente. Le vicine invece
          // sono informazione nuova, cambiano per ogni item, e il lessico si
          // fissa per campi di significato, non parola per parola isolata.
          explanation: entry.note ?? vocabularyExplanation(entry, defField, neighbours),
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

const DECL_NAME = {
  "2m": "seconda declinazione",
  "3m": "terza declinazione",
  "3n": "terza declinazione (neutri)",
  "4": "quarta declinazione",
};

// Nominativo e vocativo singolare della terza non hanno una desinenza fissa
// (ENDINGS["3m"|"3n"].sg[0] e [5] sono null in latinCurriculum.ts): la forma è
// il nomSg imparato a memoria, non stem+desinenza. Ogni altra combinazione
// invece esce con una desinenza regolare, ed è quella desinenza — non
// un'etichetta della funzione già data dalla risposta — a spiegare perché la
// parola è quel caso.
const NOM_VOC_IRREGOLARE = new Set(["3m", "3n"]);

function declensionExplanation(noun, combo, form) {
  if (combo.number === "singolare" && (combo.kase === "nominativo" || combo.kase === "vocativo")
      && NOM_VOC_IRREGOLARE.has(noun.type)) {
    return `Nella terza declinazione il nominativo singolare non segue una desinenza fissa: si impara insieme al genitivo, che qui è «${noun.stem}is».`;
  }
  const desinenza = form.startsWith(noun.stem) ? form.slice(noun.stem.length) : "";
  if (!desinenza) {
    return `${CASE_LABEL[combo.kase]}, ${combo.number}.`;
  }
  return `«${form}» è ${CASE_LABEL[combo.kase]}, ${combo.number}: la desinenza «-${desinenza}» lo segnala nella ${DECL_NAME[noun.type] ?? noun.type}.`;
}

// Nucleo curato di latino: oltre al riconoscimento di caso/numero (generato),
// dà basi, funzione dei casi, declinazioni, vocabolario, verbo "sum" e frasi.
const LATINO_EXTRA = [
  { topic: "declinazioni-base", difficulty: 2, prompt: "A quale declinazione appartiene «rosa, rosae»?", answer: "Prima", distractors: ["Seconda","Terza","Quarta"], explanation: "Il genitivo in -ae è il segno della prima declinazione, quasi tutta femminile." },
  { topic: "declinazioni-base", difficulty: 2, prompt: "A quale declinazione appartiene «dominus, domini»?", answer: "Seconda", distractors: ["Prima","Terza","Quinta"], explanation: "Il genitivo in -i indica la seconda declinazione, in gran parte maschile e neutra." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "Qual è il nominativo plurale di «rosa»?", answer: "rosae", distractors: ["rosas","rosis","rosam"], explanation: "Nella prima declinazione il nominativo plurale esce in -ae, come il genitivo singolare: solo il contesto li distingue." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "Qual è l'accusativo singolare di «rosa»?", answer: "rosam", distractors: ["rosae","rosa","rosas"], explanation: "La -m finale è il segno tipico dell'accusativo singolare in quasi tutte le declinazioni." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "Qual è l'accusativo plurale di «rosa»?", answer: "rosas", distractors: ["rosae","rosarum","rosis"], explanation: "L'accusativo plurale della prima declinazione esce in -as." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "Qual è il genitivo singolare di «dominus»?", answer: "domini", distractors: ["domino","dominum","dominis"], explanation: "Il genitivo indica di solito il possesso: «domini» significa «del padrone»." },
  { topic: "declinazioni-base", difficulty: 4, prompt: "Qual è il nominativo plurale di «dominus»?", answer: "domini", distractors: ["dominos","dominorum","dominis"], explanation: "Attenzione: «domini» è sia genitivo singolare sia nominativo plurale. È il verbo a chiarire quale sia." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "Come si riconosce la declinazione di un nome sul vocabolario?", answer: "Dalla desinenza del genitivo singolare", distractors: ["Dalla lettera con cui comincia","Dal genere maschile o femminile","Dalla lunghezza della parola"], explanation: "Il vocabolario riporta sempre due forme: nominativo e genitivo. La seconda dice il gruppo." },
  { topic: "declinazioni-base", difficulty: 4, prompt: "Che cosa hanno in comune tutti i nomi neutri in latino?", answer: "Nominativo e accusativo sono sempre uguali", distractors: ["Finiscono sempre in -um al singolare","Non hanno mai il plurale","Appartengono solo alla seconda"], explanation: "È una regola che vale per tutte le declinazioni: nei neutri il soggetto e l'oggetto hanno la stessa forma." },
  { topic: "declinazioni-base", difficulty: 4, prompt: "Nei neutri plurali, in che lettera escono nominativo e accusativo?", answer: "In -a", distractors: ["In -es","In -os","In -is"], explanation: "«Templa», «bella», «maria»: la -a finale dei neutri plurali è entrata anche in italiano, in parole come «le braccia»." },
  { topic: "declinazioni-base", difficulty: 2, format: "numeric_input", prompt: "Quanti numeri distingue la declinazione latina?", answer: "2", explanation: "Singolare e plurale. Il duale esisteva in greco, non in latino classico." },
  { topic: "verbo-sum", difficulty: 2, prompt: "Che cosa significa «sum»?", answer: "Io sono", distractors: ["Io ho","Io vado","Io faccio"], explanation: "«Sum» è la prima persona singolare del presente indicativo del verbo essere." },
  { topic: "verbo-sum", difficulty: 2, prompt: "Che cosa significa «es»?", answer: "Tu sei", distractors: ["Io sono","Egli è","Noi siamo"], explanation: "La seconda persona singolare: sum, es, est." },
  { topic: "verbo-sum", difficulty: 2, prompt: "Che cosa significa «sumus»?", answer: "Noi siamo", distractors: ["Voi siete","Essi sono","Tu sei"], explanation: "Prima persona plurale: sumus, estis, sunt." },
  { topic: "verbo-sum", difficulty: 3, prompt: "Che cosa significa «estis»?", answer: "Voi siete", distractors: ["Noi siamo","Essi sono","Egli è"], explanation: "La desinenza -tis segnala la seconda persona plurale in tutti i verbi latini." },
  { topic: "verbo-sum", difficulty: 3, prompt: "Che cosa significa «sunt»?", answer: "Essi sono", distractors: ["Noi siamo","Voi siete","Egli è"], explanation: "La desinenza -nt indica la terza persona plurale: sunt, amant, legunt." },
  { topic: "verbo-sum", difficulty: 3, prompt: "Che cosa significa «erat»?", answer: "Egli era", distractors: ["Egli è","Egli sarà","Egli fu"], explanation: "È l'imperfetto: descrive uno stato che durava nel passato." },
  { topic: "verbo-sum", difficulty: 4, prompt: "Che cosa significa «erit»?", answer: "Egli sarà", distractors: ["Egli era","Egli è","Egli fu"], explanation: "Futuro semplice del verbo sum: ero, eris, erit." },
  { topic: "verbo-sum", difficulty: 3, prompt: "Qual è l'infinito del verbo essere in latino?", answer: "esse", distractors: ["sum","est","erat"], explanation: "Da «esse» vengono essenza ed essere: l'infinito è la forma che dà il nome al verbo." },
  { topic: "verbo-sum", difficulty: 4, prompt: "Perché «sum» si dice verbo irregolare?", answer: "Perché le sue forme non seguono uno schema costante", distractors: ["Perché si usa soltanto al presente","Perché non ha mai un soggetto espresso","Perché non appartiene a nessuna coniugazione"], explanation: "Sum, es, est, sumus, estis, sunt: la radice cambia. Succede in tutte le lingue ai verbi più usati." },
  { topic: "verbo-sum", difficulty: 4, prompt: "In «Roma magna est», che funzione ha «est»?", answer: "Copula, collega soggetto e predicato nominale", distractors: ["Predicato verbale che esprime un'azione","Complemento oggetto della frase","Ausiliare di un tempo composto"], explanation: "Non dice un'azione: unisce «Roma» a «magna». Il predicato nominale è la coppia copula più nome o aggettivo." },
  { topic: "casi", difficulty: 3, prompt: "Quale caso esprime di solito il possesso?", answer: "Genitivo", distractors: ["Dativo","Accusativo","Ablativo"], explanation: "«Liber Marci» è il libro di Marco: il genitivo risponde a «di chi?»." },
  { topic: "casi", difficulty: 3, prompt: "Quale caso esprime il complemento di termine?", answer: "Dativo", distractors: ["Genitivo","Accusativo","Vocativo"], explanation: "Risponde a «a chi?»: «Marco do librum», do il libro a Marco." },
  { topic: "casi", difficulty: 4, prompt: "Quale caso si usa con molte preposizioni di stato in luogo?", answer: "Ablativo", distractors: ["Nominativo","Dativo","Vocativo"], explanation: "«In Italia sum»: con «in» e stato in luogo si usa l'ablativo. Con il moto a luogo si usa l'accusativo." },
  { topic: "casi", difficulty: 4, prompt: "In «in Italiam eo», perché «Italiam» è accusativo?", answer: "Perché indica un movimento verso un luogo", distractors: ["Perché è il soggetto della frase","Perché segue sempre la preposizione in","Perché è un nome di città"], explanation: "La stessa preposizione «in» regge l'ablativo per lo stato e l'accusativo per il moto: il caso cambia il senso." },
  { topic: "casi", difficulty: 3, prompt: "Quale caso useresti per tradurre «o Marco!»?", answer: "Vocativo", distractors: ["Nominativo","Dativo","Accusativo"], explanation: "Il vocativo serve solo a chiamare. Nella seconda declinazione ha una forma propria: «Marce!»." },
  { topic: "casi", difficulty: 4, prompt: "Perché in latino non servono preposizioni come «di» e «a»?", answer: "Perché ci pensano le desinenze dei casi", distractors: ["Perché le preposizioni sono sottintese","Perché il latino non ha complementi","Perché si usa solo il nominativo"], explanation: "Il genitivo dice «di», il dativo dice «a»: l'informazione è nella parola stessa, non in una parolina davanti." },
  { topic: "casi", difficulty: 4, format: "numeric_input", prompt: "Quanti casi ha una declinazione latina completa?", answer: "6", explanation: "Nominativo, genitivo, dativo, accusativo, vocativo e ablativo, al singolare e al plurale." },
  { topic: "casi", difficulty: 3, prompt: "Che cosa succede se sbagli il caso in una traduzione dal latino?", answer: "Cambia chi fa l'azione o su chi ricade", distractors: ["Cambia soltanto il tempo del verbo","La frase resta uguale nel significato","Il verbo va tradotto al plurale"], explanation: "«Marcus Iuliam amat» e «Marcum Iulia amat» hanno le stesse parole e significati opposti." },
  { topic: "declinazione-3n", difficulty: 3, prompt: "Come si riconosce un nome della terza declinazione?", answer: "Dal genitivo singolare in -is", distractors: ["Dal nominativo che finisce in -e","Dal genere sempre neutro","Dalla lunghezza della parola"], explanation: "Il nominativo della terza è imprevedibile: è il genitivo in -is a identificarla con certezza." },
  { topic: "declinazione-3n", difficulty: 3, prompt: "Nei neutri della terza declinazione, nominativo e accusativo…", answer: "Sono sempre uguali fra loro", distractors: ["Differiscono solo al plurale","Non esistono al singolare","Escono sempre in -um"], explanation: "Vale per tutti i neutri latini: «tempus» è sia soggetto sia oggetto, senza cambiare forma." },
  { topic: "declinazione-3n", difficulty: 4, prompt: "Qual è il nominativo plurale di un neutro della terza, come «tempus»?", answer: "tempora", distractors: ["tempi","tempores","temporum"], explanation: "I neutri plurali escono in -a: «tempora». «Temporum» è il genitivo plurale." },
  { topic: "declinazione-3n", difficulty: 4, prompt: "Qual è il genitivo singolare di «corpus»?", answer: "corporis", distractors: ["corpi","corpus","corporum"], explanation: "Da «corporis» viene «corporeo»: la radice vera si vede nel genitivo, non nel nominativo." },
  { topic: "declinazione-3n", difficulty: 4, prompt: "Perché il nominativo della terza declinazione va imparato a memoria?", answer: "Perché non segue una forma prevedibile", distractors: ["Perché cambia da regione a regione","Perché è uguale al genitivo","Perché non esiste nei vocabolari"], explanation: "Rex, corpus, mare, civis: il nominativo può finire in molti modi. La regolarità comincia dal genitivo." },
  { topic: "declinazione-3n", difficulty: 3, prompt: "Da «corpus, corporis» quale parola italiana deriva?", answer: "Corporeo", distractors: ["Copioso","Cooperare","Coprire"], explanation: "L'italiano eredita spesso la radice del genitivo: corpor- dà corporeo, incorporare, corporatura." },
  { topic: "declinazione-3n", difficulty: 4, prompt: "Da «tempus, temporis» quale parola italiana deriva?", answer: "Temporale", distractors: ["Tempestivo soltanto","Tempio","Tentativo"], explanation: "Dalla radice tempor- vengono temporale, contemporaneo, temporeggiare." },
  { topic: "declinazione-4", difficulty: 3, prompt: "Come si riconosce un nome della quarta declinazione?", answer: "Dal genitivo singolare in -us", distractors: ["Dal nominativo in -a","Dal genitivo in -ei","Dal nominativo in -er"], explanation: "Nominativo e genitivo si somigliano molto: «manus, manus». È il contesto a distinguerli." },
  { topic: "declinazione-4", difficulty: 4, prompt: "Perché «manus, manus» crea confusione ai principianti?", answer: "Perché nominativo e genitivo si scrivono uguali", distractors: ["Perché è un nome neutro irregolare","Perché non ha il plurale","Perché appartiene a due declinazioni"], explanation: "Solo la funzione nella frase, e spesso il verbo, dicono quale dei due casi sia." },
  { topic: "declinazione-4", difficulty: 3, prompt: "Che cosa significa «manus»?", answer: "Mano", distractors: ["Monte","Muro","Mondo"], explanation: "Da «manus» vengono manuale, manutenzione, manoscritto, manovra." },
  { topic: "declinazione-4", difficulty: 4, prompt: "Che cosa significa «exercitus»?", answer: "Esercito", distractors: ["Esercizio scolastico","Esperimento","Esperienza"], explanation: "Da «exercere» (esercitare): l'esercito è ciò che viene addestrato. Anche «esercizio» viene dalla stessa radice." },
  { topic: "declinazione-4", difficulty: 4, prompt: "Che cosa significa «senatus»?", answer: "Senato", distractors: ["Sentenza","Sentimento","Sentiero"], explanation: "Da «senex» (vecchio): il senato era l'assemblea degli anziani. Da lì anche «senile» e «senatore»." },
  { topic: "declinazione-4", difficulty: 3, prompt: "Quale genere hanno la maggior parte dei nomi della quarta declinazione?", answer: "Maschile", distractors: ["Femminile","Neutro","Non hanno genere"], explanation: "Ci sono eccezioni importanti come «manus», che è femminile pur finendo in -us." },
  { topic: "declinazione-4", difficulty: 4, format: "numeric_input", prompt: "Quante declinazioni bisogna conoscere per leggere un testo latino?", answer: "5", explanation: "Cinque, ma le prime tre coprono la stragrande maggioranza dei nomi che si incontrano." },
  { topic: "frasi", difficulty: 2, prompt: "Come si traduce «Puella cantat»?", answer: "La bambina canta", distractors: ["Le bambine cantano","La bambina cantava","La bambina non canta"], explanation: "«Puella» è nominativo singolare (soggetto) e «cantat» è terza persona singolare del presente." },
  { topic: "frasi", difficulty: 2, prompt: "Come si traduce «Rosa pulchra est»?", answer: "La rosa è bella", distractors: ["Le rose sono belle","La rosa era bella","La bella rosa"], explanation: "«Est» è la terza persona singolare di «sum»: «pulchra» è il predicato nominale riferito a «rosa»." },
  { topic: "frasi", difficulty: 3, prompt: "In «Marcus librum legit», chi compie l'azione?", answer: "Marcus", distractors: ["Librum","Legit","Nessuno, è passiva"], explanation: "«Marcus» è al nominativo, quindi soggetto; «librum» è accusativo, cioè complemento oggetto." },
  { topic: "frasi", difficulty: 3, prompt: "In «Marcus librum legit», che cos'è «librum»?", answer: "Complemento oggetto", distractors: ["Soggetto della frase","Complemento di termine","Complemento di luogo"], explanation: "La desinenza -um dell'accusativo segnala l'oggetto diretto: Marco legge il libro." },
  { topic: "frasi", difficulty: 3, prompt: "«Librum Marcus legit» significa la stessa cosa di «Marcus librum legit». Perché?", answer: "Perché sono i casi a dire chi fa che cosa", distractors: ["Perché il latino ammette qualsiasi ordine","Perché il verbo va comunque letto per primo","Perché le due frasi hanno parole diverse"], explanation: "«Marcus librum legit» e «librum Marcus legit» significano lo stesso: è il caso, non la posizione, a dire chi fa cosa." },
  { topic: "frasi", difficulty: 4, prompt: "Come si traduce «Magister discipulos laudat»?", answer: "Il maestro loda gli allievi", distractors: ["Gli allievi lodano il maestro","Il maestro lodava gli allievi","I maestri lodano l'allievo"], explanation: "«Magister» è nominativo singolare, «discipulos» accusativo plurale: chi loda è il maestro." },
  { topic: "frasi", difficulty: 4, prompt: "Come si traduce «Discipuli magistrum laudant»?", answer: "Gli allievi lodano il maestro", distractors: ["Il maestro loda gli allievi","Gli allievi lodavano il maestro","L'allievo loda i maestri"], explanation: "Qui i casi sono invertiti rispetto alla frase precedente: cambia chi fa l'azione, non le parole." },
  { topic: "frasi", difficulty: 2, prompt: "In latino il verbo essere alla terza persona singolare è…", answer: "est", distractors: ["sunt","esse","erat"], explanation: "«Sunt» è plurale, «erat» imperfetto, «esse» l'infinito." },
  { topic: "frasi", difficulty: 3, prompt: "Come si traduce «Roma in Italia est»?", answer: "Roma è in Italia", distractors: ["Roma va in Italia","Roma era in Italia","L'Italia è a Roma"], explanation: "«In» con l'ablativo indica stato in luogo: si sta, non ci si muove." },
  { topic: "frasi", difficulty: 4, prompt: "In «Puellae rosas amant», quante bambine ci sono?", answer: "Più di una", distractors: ["Una sola","Nessuna","Non si può sapere"], explanation: "«Amant» è plurale e «puellae» qui è nominativo plurale: il verbo conferma quale caso è." },
  { topic: "frasi", difficulty: 3, prompt: "Perché in latino non serve tradurre «il» e «la»?", answer: "Perché il latino non ha articoli", distractors: ["Perché sono sempre sottintesi nel verbo","Perché si usano solo nelle frasi lunghe","Perché li sostituiscono i pronomi"], explanation: "Gli articoli italiani nascono dopo, dai dimostrativi latini: «illa rosa» diventa «la rosa»." },
  { topic: "frasi", difficulty: 4, prompt: "Come si traduce «Agricola terram arat»?", answer: "Il contadino ara la terra", distractors: ["La terra ara il contadino","I contadini arano le terre","Il contadino arava la terra"], explanation: "«Agricola» finisce in -a ma è maschile e nominativo: il caso, non la vocale finale, dice la funzione." },
  { topic: "frasi", difficulty: 2, prompt: "Che cosa indica la desinenza -t alla fine di un verbo latino?", answer: "Terza persona singolare", distractors: ["Prima persona singolare","Terza persona plurale","Il tempo passato"], explanation: "Cantat, legit, amat: la -t finale dice «lui/lei» senza bisogno del pronome." },
  { topic: "etimologia", difficulty: 2, prompt: "Da quale parola latina viene «acqua»?", answer: "aqua", distractors: ["aer","ager","arbor"], explanation: "Da «aqua» vengono anche acquedotto, acquario e acquerello." },
  { topic: "etimologia", difficulty: 2, prompt: "Da quale parola latina viene «terra»?", answer: "terra", distractors: ["tempus","turris","tectum"], explanation: "La stessa radice dà territorio, terrestre, sotterraneo, interrare." },
  { topic: "etimologia", difficulty: 3, prompt: "Da quale verbo latino viene «visione»?", answer: "videre", distractors: ["vincere","venire","vivere"], explanation: "Da «videre» (vedere) nascono visione, evidente, provvedere e perfino televisione." },
  { topic: "etimologia", difficulty: 3, prompt: "Che cosa significa il prefisso latino «trans-»?", answer: "Attraverso, oltre", distractors: ["Sotto, al di sotto","Prima, in anticipo","Contro, in opposizione"], explanation: "Transatlantico attraversa l'Atlantico, trasparente si lascia attraversare dalla luce." },
  { topic: "etimologia", difficulty: 3, prompt: "Che cosa significa il prefisso latino «sub-»?", answer: "Sotto", distractors: ["Sopra","Prima","Dopo"], explanation: "Sottomarino sta sotto il mare, subacqueo sotto l'acqua, suburbano sotto (cioè attorno) alla città." },
  { topic: "etimologia", difficulty: 4, prompt: "Da quale parola latina viene «manuale»?", answer: "manus", distractors: ["mens","mare","malum"], explanation: "Da «manus» (mano): manuale, manutenzione, manoscritto, manovra." },
  { topic: "etimologia", difficulty: 3, prompt: "Da quale parola latina viene «popolare»?", answer: "populus", distractors: ["pons","porta","potestas"], explanation: "Da «populus» (popolo) vengono popolare, popolazione, popoloso." },
  { topic: "etimologia", difficulty: 4, prompt: "Che cosa significa «ante-» in «anteprima»?", answer: "Prima", distractors: ["Dopo","Contro","Insieme"], explanation: "Da «ante» (prima): anteprima, antefatto, antenato. «Post-» significa invece dopo." },
  { topic: "etimologia", difficulty: 3, prompt: "Da quale parola latina viene «scrivere»?", answer: "scribere", distractors: ["sedere","sentire","servare"], explanation: "Da «scribere»: scrittura, descrivere, manoscritto, iscrizione." },
  { topic: "etimologia", difficulty: 4, prompt: "Perché «biblioteca» e «bibliografia» sono parenti?", answer: "Condividono la radice che significa libro", distractors: ["Perché parlano entrambe di scuola","Perché sono parole molto lunghe","Perché finiscono in modo simile"], explanation: "La radice «biblio-» viene dal greco ma è entrata in latino: significa libro." },
  { topic: "etimologia", difficulty: 3, prompt: "Che cosa significa il prefisso «re-» in «rifare»?", answer: "Di nuovo, indietro", distractors: ["Molto, moltissimo","Insieme, con altri","Male, in modo sbagliato"], explanation: "Rifare, rivedere, ritornare: indica ripetizione o ritorno." },
  { topic: "etimologia", difficulty: 4, prompt: "Da quale parola latina viene «capitale»?", answer: "caput", distractors: ["campus","carmen","civis"], explanation: "Da «caput» (testa): capitale è la città a capo, capitolo è la testa di un discorso, capitano è chi sta in testa." },
  { topic: "etimologia", difficulty: 3, prompt: "Perché conoscere il latino aiuta a capire parole italiane nuove?", answer: "Perché molte parole nascono dalle stesse radici", distractors: ["Perché il latino si parla ancora oggi","Perché le parole nuove sono tutte latine","Perché la grammatica è identica"], explanation: "Riconosciuta la radice, il significato di una parola mai vista si intuisce: è un metodo, non una memoria." },
  { topic: "basi", difficulty: 1, format: "numeric_input", prompt: "Quanti casi ha la declinazione latina?", answer: "6", explanation: "Nominativo, genitivo, dativo, accusativo, vocativo, ablativo." },
  { topic: "basi", difficulty: 2, prompt: "Che cos'è un caso in latino?", answer: "La forma che indica la funzione di un nome", distractors: ["Il genere maschile o femminile","Il numero singolare o plurale","Il tempo in cui avviene l'azione"], explanation: "Cambiando la desinenza cambia il ruolo nella frase: soggetto, oggetto, complemento." },
  { topic: "basi", difficulty: 2, format: "numeric_input", prompt: "Quante declinazioni ha il latino?", answer: "5", explanation: "Cinque gruppi di nomi, ciascuno con le sue desinenze: si riconoscono dal genitivo singolare." },
  { topic: "basi", difficulty: 3, prompt: "In che lingua è scritta la maggior parte delle iscrizioni romane?", answer: "Latino", distractors: ["Greco antico","Etrusco","Italiano antico"], explanation: "Il latino era la lingua ufficiale dell'impero: le iscrizioni pubbliche lo usavano quasi sempre." },
  { topic: "basi", difficulty: 2, prompt: "Che cosa si intende per «lingua flessiva»?", answer: "Una lingua in cui le parole cambiano desinenza", distractors: ["Una lingua che si adatta ai dialetti","Una lingua senza regole fisse","Una lingua che si scrive senza vocali"], explanation: "Latino, greco e tedesco sono flessivi: la fine della parola porta l'informazione grammaticale." },
  { topic: "basi", difficulty: 3, prompt: "Perché il latino si dice «lingua madre» dell'italiano?", answer: "Perché l'italiano deriva direttamente da esso", distractors: ["Perché si insegna prima dell'italiano","Perché è più antico di tutte le lingue","Perché era parlato dalle madri romane"], explanation: "Italiano, spagnolo, francese, portoghese e rumeno nascono dal latino parlato: sono le lingue romanze." },
  { topic: "basi", difficulty: 3, prompt: "Quale caso indica normalmente il soggetto?", answer: "Nominativo", distractors: ["Accusativo","Genitivo","Ablativo"], explanation: "Il nominativo «nomina» chi compie l'azione: è la forma che si trova sul vocabolario." },
  { topic: "basi", difficulty: 3, prompt: "Quale caso indica normalmente il complemento oggetto?", answer: "Accusativo", distractors: ["Nominativo","Dativo","Vocativo"], explanation: "L'accusativo risponde a «chi? che cosa?» senza preposizione." },
  { topic: "basi", difficulty: 4, prompt: "Quale caso si usa per chiamare qualcuno?", answer: "Vocativo", distractors: ["Dativo","Genitivo","Ablativo"], explanation: "«Brute!» è vocativo: serve solo a rivolgersi direttamente a una persona." },
  { topic: "basi", difficulty: 3, prompt: "Come si trova a quale declinazione appartiene un nome?", answer: "Guardando la desinenza del genitivo singolare", distractors: ["Guardando la lettera iniziale","Contando le sillabe della parola","Guardando se è maschile o femminile"], explanation: "Rosa, rosae è prima; dominus, domini è seconda. Il vocabolario riporta sempre nominativo e genitivo." },
  { topic: "basi", difficulty: 2, prompt: "In latino esistono gli articoli «il», «la», «un»?", answer: "No, il latino non ha articoli", distractors: ["Sì, sono uguali all'italiano","Sì, ma solo al singolare","Sì, ma si scrivono attaccati"], explanation: "«Rosa» può significare «rosa», «la rosa» o «una rosa»: lo decide il contesto." },
  { topic: "basi", difficulty: 4, prompt: "Perché due nomi latini con la stessa desinenza possono avere funzioni diverse?", answer: "Perché la stessa desinenza appare in casi diversi", distractors: ["Perché il latino ammette gli errori","Perché dipende da chi scrive la frase","Perché le desinenze cambiano ogni secolo"], explanation: "«Rosae» può essere genitivo, dativo o nominativo plurale: solo il contesto e il verbo lo chiariscono." },
  { topic: "vocabolario", difficulty: 1, prompt: "Che cosa significa «aqua»?", answer: "Acqua", distractors: ["Aria","Terra","Fuoco"], explanation: "Da «aqua» vengono acquedotto e acquario." },
  { topic: "vocabolario", difficulty: 1, prompt: "Che cosa significa «puella»?", answer: "Bambina", distractors: ["Bambino","Donna anziana","Sorella"], explanation: "«Puer» è il bambino, «puella» la bambina: è un nome della prima declinazione." },
  { topic: "vocabolario", difficulty: 2, prompt: "Che cosa significa «liber»?", answer: "Libro", distractors: ["Libero","Lettera","Lingua"], explanation: "Da «liber» vengono libro, libreria, libraio. L'aggettivo «liber» che significa libero si scrive uguale ma ha altra origine." },
  { topic: "vocabolario", difficulty: 2, prompt: "Che cosa significa «magister»?", answer: "Maestro", distractors: ["Allievo","Padre","Comandante"], explanation: "Da «magister» vengono maestro, magistrale, magistrato." },
  { topic: "vocabolario", difficulty: 2, prompt: "Che cosa significa «amicus»?", answer: "Amico", distractors: ["Nemico","Vicino","Parente"], explanation: "Da «amare» (amare) viene «amicus»: chi si ama, l'amico." },
  { topic: "vocabolario", difficulty: 3, prompt: "Che cosa significa «bellum»?", answer: "Guerra", distractors: ["Bello","Campo","Città"], explanation: "Attenzione al falso amico: «bellum» significa guerra, mentre «bellus» significa bello." },
  { topic: "vocabolario", difficulty: 3, prompt: "Che cosa significa «urbs»?", answer: "Città", distractors: ["Campagna","Strada","Muro"], explanation: "Da «urbs» vengono urbano, suburbano, urbanistica. Per i Romani «Urbs» senza altro significava Roma." },
  { topic: "vocabolario", difficulty: 3, prompt: "Che cosa significa «tempus»?", answer: "Tempo", distractors: ["Tempio","Tempesta","Testa"], explanation: "Da «tempus» vengono temporale, contemporaneo, temporeggiare. «Templum» è invece il tempio." },
  { topic: "vocabolario", difficulty: 3, prompt: "Che cosa significa «via»?", answer: "Strada", distractors: ["Vita","Voce","Vino"], explanation: "Da «via» vengono viaggio, viadotto, deviare, ovvio (che sta sulla via, davanti agli occhi)." },
  { topic: "vocabolario", difficulty: 4, prompt: "Che cosa significa «virtus»?", answer: "Valore, coraggio", distractors: ["Virtù religiosa soltanto","Forza fisica soltanto","Ricchezza personale"], explanation: "Da «vir» (uomo): per i Romani era il valore, soprattutto militare. Il senso morale è più tardo." },
  { topic: "vocabolario", difficulty: 4, prompt: "Che cosa significa «schola»?", answer: "Tempo libero dedicato allo studio", distractors: ["Edificio con molte aule","Gruppo di allievi","Lezione del maestro"], explanation: "Dal greco «scholé», che significava proprio ozio, tempo libero: studiare era ciò che si faceva quando non si lavorava." },
  { topic: "vocabolario", difficulty: 3, prompt: "Che cosa significa «rex»?", answer: "Re", distractors: ["Regola","Regno","Console"], explanation: "Da «rex, regis» vengono regale, reggia, e anche «regola», perché il re è chi dirige." },
  // Basi e storia
  { topic: "basi", difficulty: 1, prompt: "Il latino era la lingua di quale antico popolo?", answer: "I Romani", distractors: ["I Greci", "Gli Egizi", "I Celti"], explanation: "Nata nel Lazio, si diffuse con l'impero: da lì vengono italiano, spagnolo, francese, portoghese e rumeno." },
  { topic: "basi", difficulty: 1, prompt: "Da quale lingua derivano soprattutto l'italiano, lo spagnolo e il francese?", answer: "Il latino", distractors: ["Il greco", "L'inglese", "L'arabo"], explanation: "Sono lingue 'romanze', nate dal latino." },
  { topic: "basi", difficulty: 2, prompt: "Cosa significa l'espressione latina 'Carpe diem'?", answer: "Cogli l'attimo", distractors: ["Vivi a lungo", "Sii coraggioso", "Studia ogni giorno"], explanation: "Invita a vivere e apprezzare il presente." },
  // Funzione dei casi
  { topic: "casi", difficulty: 2, prompt: "In latino, il caso del soggetto è il…", answer: "Nominativo", distractors: ["Accusativo", "Genitivo", "Ablativo"], explanation: "Il nominativo indica il soggetto della frase." },
  { topic: "casi", difficulty: 2, prompt: "Il complemento oggetto in latino si esprime con l'…", answer: "Accusativo", distractors: ["Nominativo", "Dativo", "Vocativo"], explanation: "Risponde alla domanda «chi? che cosa?» dopo il verbo, e in latino lo segnala la desinenza, non la posizione." },
  { topic: "casi", difficulty: 3, prompt: "Il complemento di specificazione (il 'di chi, di cosa') usa il…", answer: "Genitivo", distractors: ["Dativo", "Ablativo", "Accusativo"], explanation: "Il genitivo indica la specificazione (es. il libro di Marco)." },
  { topic: "casi", difficulty: 3, prompt: "Il complemento di termine (a chi, per chi) usa il…", answer: "Dativo", distractors: ["Genitivo", "Accusativo", "Nominativo"], explanation: "Il dativo indica il termine (es. dono a Giulia)." },
  { topic: "casi", difficulty: 4, prompt: "Quale caso serve per chiamare o invocare qualcuno?", answer: "Vocativo", distractors: ["Nominativo", "Dativo", "Ablativo"], explanation: "Il vocativo si usa per rivolgersi direttamente a qualcuno." },
  // Declinazioni
  { topic: "declinazioni-base", difficulty: 2, prompt: "Quante sono le declinazioni del latino?", answer: "5", distractors: ["3", "4", "6"], explanation: "I nomi latini si dividono in cinque declinazioni." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "I nomi come 'rosa, rosae' appartengono alla…", answer: "Prima declinazione", distractors: ["Seconda declinazione", "Terza declinazione", "Quinta declinazione"], explanation: "La prima declinazione ha genitivo singolare in -ae." },
  { topic: "declinazioni-base", difficulty: 3, prompt: "I nomi come 'lupus, lupi' appartengono alla…", answer: "Seconda declinazione", distractors: ["Prima declinazione", "Terza declinazione", "Quarta declinazione"], explanation: "La seconda declinazione ha genitivo singolare in -i." },
  // Vocabolario
  { topic: "vocabolario", difficulty: 1, prompt: "Cosa significa 'aqua' in italiano?", answer: "Acqua", distractors: ["Aria", "Fuoco", "Terra"], explanation: "Prima declinazione. Da questa radice l'italiano ha acquedotto, acquario e acquerello." },
  { topic: "vocabolario", difficulty: 1, prompt: "Cosa significa 'puella' in italiano?", answer: "Fanciulla, ragazza", distractors: ["Ragazzo", "Casa", "Cane"], explanation: "Prima declinazione, come rosa e silva: il femminile in -a è il gruppo più regolare del latino." },
  { topic: "vocabolario", difficulty: 2, prompt: "Cosa significa 'silva' in italiano?", answer: "Bosco, selva", distractors: ["Città", "Fiume", "Strada"], explanation: "'Silva' è il bosco (da cui 'selva')." },
  // Verbo essere (sum)
  { topic: "verbo-sum", difficulty: 3, prompt: "Come si dice 'io sono' in latino?", answer: "Sum", distractors: ["Est", "Sunt", "Es"], explanation: "'Sum' = io sono; 'es' = tu sei; 'est' = egli è." },
  { topic: "verbo-sum", difficulty: 3, prompt: "Il verbo 'est' significa…", answer: "(egli/ella) è", distractors: ["(io) sono", "(loro) sono", "(tu) sei"], explanation: "'Est' è la terza persona singolare di 'sum'." },
  { topic: "verbo-sum", difficulty: 4, prompt: "'Sunt' significa…", answer: "(loro) sono", distractors: ["(egli) è", "(io) sono", "(noi) siamo"], explanation: "'Sunt' è la terza persona plurale di 'sum'." },
  // Frasi
  { topic: "frasi", difficulty: 4, prompt: "'Puella rosam amat' significa…", answer: "La fanciulla ama la rosa", distractors: ["La rosa ama la fanciulla", "Le fanciulle amano le rose", "La fanciulla guarda la rosa"], explanation: "'Rosam' è accusativo (oggetto): la fanciulla (soggetto) ama la rosa (oggetto)." },
  { topic: "declinazioni-base", difficulty: 1, format: "short_answer", prompt: "Come si dice in latino «la rosa», al nominativo singolare?", answer: "rosa", explanation: "Prima declinazione: il nominativo singolare esce in -a." },
  { topic: "declinazioni-base", difficulty: 2, format: "short_answer", prompt: "Qual è il genitivo singolare di «rosa»?", answer: "rosae", explanation: "Il genitivo in -ae è la firma della prima declinazione." },
  { topic: "declinazione-2m", difficulty: 2, format: "short_answer", prompt: "Qual è il nominativo plurale di «dominus»?", answer: "domini", explanation: "Seconda declinazione maschile: -us al singolare, -i al plurale." },
  { topic: "declinazione-2m", difficulty: 2, format: "short_answer", prompt: "Qual è l'accusativo singolare di «dominus»?", answer: "dominum", explanation: "L'accusativo singolare della seconda esce in -um." },
  { topic: "declinazione-2m", difficulty: 3, format: "short_answer", prompt: "Qual è il dativo plurale di «dominus»?", answer: "dominis", explanation: "Dativo e ablativo plurale della seconda coincidono: -is." },
  { topic: "declinazione-3m", difficulty: 2, format: "short_answer", prompt: "Qual è il genitivo singolare di «consul»?", answer: "consulis", explanation: "Il genitivo in -is dice che il nome è di terza declinazione." },
  { topic: "declinazione-3m", difficulty: 3, format: "short_answer", prompt: "Qual è il nominativo plurale di «consul»?", answer: "consules", explanation: "Terza declinazione maschile: il nominativo plurale esce in -es." },
  { topic: "declinazione-3m", difficulty: 3, format: "short_answer", prompt: "Qual è l'accusativo plurale di «consul»?", answer: "consules", explanation: "Nella terza, maschili e femminili hanno nominativo e accusativo plurale uguali." },
  { topic: "declinazione-3n", difficulty: 3, format: "short_answer", prompt: "Qual è il nominativo plurale di «corpus»?", answer: "corpora", explanation: "Nei neutri della terza il plurale esce in -a: qui il tema è corpor-." },
  { topic: "declinazione-3n", difficulty: 3, format: "short_answer", prompt: "Qual è il genitivo singolare di «corpus»?", answer: "corporis", explanation: "Il genitivo svela il tema vero: corpor-, non corpus-." },
  { topic: "declinazione-4", difficulty: 3, format: "short_answer", prompt: "Qual è il genitivo singolare di «manus»?", answer: "manus", explanation: "Quarta declinazione: nominativo e genitivo singolare si scrivono uguali." },
  { topic: "declinazione-4", difficulty: 3, format: "short_answer", prompt: "Qual è il nominativo plurale di «manus»?", answer: "manus", explanation: "Anche il nominativo plurale è manus: è il contesto a distinguerli." },
  { topic: "verbo-sum", difficulty: 1, format: "short_answer", prompt: "Come si dice in latino «io sono»?", answer: "sum", explanation: "Prima persona singolare del presente indicativo di sum." },
  { topic: "verbo-sum", difficulty: 2, format: "short_answer", prompt: "Come si dice in latino «noi siamo»?", answer: "sumus", explanation: "La desinenza -mus segna sempre il «noi»: sum diventa sumus, come amo diventa amamus." },
  { topic: "verbo-sum", difficulty: 2, format: "short_answer", prompt: "Come si dice in latino «essi sono»?", answer: "sunt", explanation: "La desinenza -nt segna sempre il «essi»: sum diventa sunt, come amo diventa amant." },
  { topic: "verbo-sum", difficulty: 3, format: "short_answer", prompt: "Come si dice in latino «io ero»?", answer: "eram", explanation: "Imperfetto di sum: eram, eras, erat." },
  { topic: "casi", difficulty: 2, format: "short_answer", prompt: "Quale caso latino si usa per il soggetto della frase?", answer: "nominativo", explanation: "Il nominativo indica chi compie l'azione o di chi si dice qualcosa." },
  { topic: "casi", difficulty: 2, format: "short_answer", prompt: "Quale caso latino si usa per il complemento oggetto?", answer: "accusativo", explanation: "Risponde a «chi? che cosa?» dopo un verbo transitivo." },
  { topic: "casi", difficulty: 2, format: "short_answer", prompt: "Quale caso latino si usa per chiamare qualcuno?", answer: "vocativo", explanation: "È il caso del richiamo: quasi sempre uguale al nominativo." },
  { topic: "casi", difficulty: 3, format: "short_answer", prompt: "Quale caso latino esprime di solito il possesso?", answer: "genitivo", explanation: "«Il libro del maestro»: magistri, genitivo." },
  { topic: "etimologia", difficulty: 2, format: "short_answer", prompt: "Da quale parola latina viene l'italiano «aqua-» in «acquedotto»?", answer: "aqua", explanation: "Aqua vuol dire acqua; il dotto è il condotto che la porta." },
  { topic: "etimologia", difficulty: 2, format: "short_answer", prompt: "Da quale parola latina viene l'italiano «terrestre»?", answer: "terra", explanation: "Terra dà terrestre, terreno, terrazzo, sotterraneo." },
  { topic: "etimologia", difficulty: 3, format: "short_answer", prompt: "Da quale parola latina viene l'italiano «manuale»?", answer: "manus", explanation: "Manus è la mano: manuale è ciò che si fa con le mani." },
  { topic: "etimologia", difficulty: 3, format: "short_answer", prompt: "Da quale parola latina viene l'italiano «vitale»?", answer: "vita", explanation: "Vita dà vitale, vitamina, vitalità." },
  { topic: "vocabolario", difficulty: 1, format: "short_answer", prompt: "Che cosa significa in italiano il latino «puella»?", answer: "ragazza", accept: ["fanciulla", "bambina"], explanation: "Puella, prima declinazione: la ragazza, la fanciulla." },
  { topic: "vocabolario", difficulty: 1, format: "short_answer", prompt: "Che cosa significa in italiano il latino «liber»?", answer: "libro", explanation: "Liber, seconda declinazione: il libro." },
  { topic: "vocabolario", difficulty: 2, format: "short_answer", prompt: "Che cosa significa in italiano il latino «rex»?", answer: "re", explanation: "Rex, terza declinazione, genitivo regis: da lì regale e regno." },
  { topic: "vocabolario", difficulty: 2, format: "short_answer", prompt: "Che cosa significa in italiano il latino «bellum»?", answer: "guerra", accept: ["la guerra"], explanation: "Bellum è la guerra, non il bello: da lì bellicoso." },
  { topic: "vocabolario", difficulty: 2, format: "short_answer", prompt: "Che cosa significa in italiano il latino «magister»?", answer: "maestro", explanation: "Magister è il maestro; da lì magistrale e magistrato." },
  { topic: "basi", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'insieme delle terminazioni che un nome latino assume nei vari casi?", answer: "declinazione", explanation: "Cinque declinazioni, riconoscibili dal genitivo singolare." },
  { topic: "frasi", difficulty: 3, format: "short_answer", prompt: "Come si traduce il latino «Roma caput mundi»?", answer: "Roma capitale del mondo", accept: ["Roma è la capitale del mondo"], explanation: "Caput è la testa, e per estensione la capitale." },
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
            explanation: declensionExplanation(noun, combo, form),
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
  { topic: "sicurezza-elettrica", difficulty: 2, prompt: "Perché non si toccano prese o fili con le mani bagnate?", answer: "Perché l'acqua conduce la corrente verso il corpo", distractors: ["Perché l'acqua rovina i contatti di metallo","Perché le mani bagnate scivolano sulla presa","Perché l'acqua fa arrugginire l'impianto"], explanation: "L'acqua, soprattutto con i sali della pelle, offre una strada facile alla corrente: e quella strada passa da te." },
  { topic: "sicurezza-elettrica", difficulty: 2, prompt: "A che cosa serve la messa a terra?", answer: "A dare alla corrente una via sicura verso il suolo", distractors: ["A far funzionare meglio tutti gli apparecchi di casa","A ridurre il consumo di elettricità della famiglia","A tenere fermi i cavi dentro il muro"], explanation: "Se un guasto porta tensione sulla carcassa metallica, la corrente scarica a terra invece di passare da chi tocca." },
  { topic: "sicurezza-elettrica", difficulty: 3, prompt: "Che cosa fa un fusibile?", answer: "Si interrompe se passa troppa corrente", distractors: ["Aumenta la corrente quando serve","Trasforma la corrente in calore utile","Misura quanta corrente sta passando"], explanation: "È un anello debole messo apposta: si sacrifica lui per non far bruciare il resto del circuito." },
  { topic: "sicurezza-elettrica", difficulty: 3, prompt: "Perché è pericoloso collegare molti apparecchi a una sola presa?", answer: "Perché i fili si scaldano oltre il loro limite", distractors: ["Perché la corrente diventa più lenta","Perché la tensione si abbassa troppo","Perché gli apparecchi si rovinano fra loro"], explanation: "Ogni filo sopporta una corrente massima: superarla lo fa scaldare, e il calore può incendiare l'isolante." },
  { topic: "sicurezza-elettrica", difficulty: 4, prompt: "Perché gli uccelli sui fili dell'alta tensione non si fulminano?", answer: "Perché toccano un solo filo e la corrente non ha dove andare", distractors: ["Perché le zampe degli uccelli isolano per natura","Perché quei fili sono coperti di plastica spessa","Perché gli uccelli sono troppo leggeri per la corrente"], explanation: "Serve una differenza di potenziale fra due punti: toccando un solo conduttore non si chiude nessun circuito." },
  { topic: "sicurezza-elettrica", difficulty: 3, prompt: "Che cosa si fa PRIMA di riparare qualcosa in un impianto elettrico?", answer: "Si toglie la corrente dall'interruttore generale", distractors: ["Si indossano guanti di lana molto spessi","Si bagnano le mani per fare meglio contatto","Si accende la luce della stanza per vedere bene"], explanation: "Non si lavora mai su un circuito in tensione: si stacca, e si verifica che sia davvero staccato." },
  { topic: "sicurezza-elettrica", difficulty: 2, prompt: "Perché i cavi elettrici sono ricoperti di plastica?", answer: "Perché la plastica isola e impedisce contatti", distractors: ["Perché la plastica conduce meglio del rame","Perché rende i cavi più leggeri da tirare","Perché serve a colorare i cavi diversi"], explanation: "Il rame dentro conduce, la plastica fuori impedisce che la corrente esca dove non deve." },
  { topic: "sicurezza-elettrica", difficulty: 4, prompt: "Perché una pila da 1,5 V non è pericolosa e la presa di casa sì?", answer: "Perché la tensione della presa è molto più alta", distractors: ["Perché la pila contiene meno metallo","Perché la presa è collegata alla terra","Perché la pila si scarica troppo in fretta"], explanation: "Con 1,5 volt la corrente che attraverserebbe il corpo è minima; con 230 volt diventa abbastanza da fermare il cuore." },
  { topic: "sicurezza-elettrica", difficulty: 3, prompt: "Che cosa indica il simbolo di un fulmine su un quadro elettrico?", answer: "Pericolo di scossa elettrica", distractors: ["Presenza di un temporale in corso","Necessità di ricaricare la batteria","Zona da illuminare meglio"], explanation: "È un avviso standard: dietro quello sportello ci sono parti in tensione." },
  { topic: "sicurezza-elettrica", difficulty: 4, prompt: "Perché il salvavita è più sensibile di un fusibile?", answer: "Perché rileva anche piccole correnti che si disperdono", distractors: ["Perché scatta più lentamente del fusibile","Perché misura la tensione invece della corrente","Perché funziona solo con apparecchi grandi"], explanation: "Il fusibile aspetta il sovraccarico; il salvavita confronta corrente in entrata e in uscita e scatta per pochi milliampere di differenza." },
  { topic: "sicurezza-elettrica", difficulty: 2, prompt: "Che cosa NON si deve mai infilare in una presa?", answer: "Oggetti metallici come forbici o chiodi", distractors: ["La spina di un apparecchio funzionante","Un adattatore certificato per quella presa","Il cavo di ricarica del telefono"], explanation: "Un metallo chiude il circuito attraverso il corpo: è la causa più comune di folgorazione domestica." },
  { topic: "sicurezza-elettrica", difficulty: 3, prompt: "Perché un apparecchio con il cavo scoperto va spento subito?", answer: "Perché il conduttore nudo può dare la scossa", distractors: ["Perché consuma molta più corrente","Perché il cavo si spezzerà comunque","Perché disturba gli altri apparecchi"], explanation: "L'isolante è l'unica cosa che separa il rame dalle mani: rotto quello, non c'è più protezione." },
  { topic: "serie-parallelo", difficulty: 2, prompt: "In un circuito in serie, la corrente che passa in ogni componente è…", answer: "La stessa in tutti", distractors: ["Diversa in ognuno di essi","Maggiore nel primo componente","Minore nell'ultimo componente"], explanation: "La corrente ha una strada sola: quello che entra da una parte esce dall'altra, senza dividersi." },
  { topic: "serie-parallelo", difficulty: 3, prompt: "In un circuito in parallelo, la tensione ai capi di ogni ramo è…", answer: "La stessa per tutti i rami", distractors: ["Divisa fra i rami in parti uguali","Maggiore nel ramo più corto","Minore nel ramo con più resistenza"], explanation: "Tutti i rami sono collegati agli stessi due punti: la differenza di potenziale è per forza identica." },
  { topic: "serie-parallelo", difficulty: 3, prompt: "Due resistenze uguali in serie danno una resistenza totale…", answer: "Doppia di una sola", distractors: ["Uguale a una sola","La metà di una sola","Quattro volte una sola"], explanation: "In serie le resistenze si sommano: la corrente deve attraversarle entrambe una dopo l'altra." },
  { topic: "serie-parallelo", difficulty: 4, prompt: "Due resistenze uguali in parallelo danno una resistenza totale…", answer: "La metà di una sola", distractors: ["Doppia di una sola","Uguale a una sola","Quattro volte una sola"], explanation: "Due strade sono più facili di una: la resistenza complessiva scende." },
  { topic: "serie-parallelo", difficulty: 3, prompt: "Perché le luci di casa non si spengono tutte insieme quando una si fulmina?", answer: "Perché sono collegate in parallelo", distractors: ["Perché sono collegate in serie","Perché hanno ognuna il suo fusibile","Perché consumano poca corrente"], explanation: "In parallelo ogni lampadina ha la sua strada verso la corrente: interromperne una non tocca le altre." },
  { topic: "serie-parallelo", difficulty: 4, prompt: "Tre lampadine identiche in serie brillano rispetto a una sola…", answer: "Meno", distractors: ["Di più","Uguale","Il triplo"], explanation: "La resistenza totale triplica, la corrente si riduce a un terzo e ogni lampadina riceve meno potenza." },
  { topic: "serie-parallelo", difficulty: 2, prompt: "Come si riconosce un collegamento in serie?", answer: "I componenti sono uno dopo l'altro su un unico anello", distractors: ["I componenti sono affiancati fra due nodi","I componenti hanno ciascuno un interruttore","I componenti sono tutti dello stesso tipo"], explanation: "Se puoi seguire il filo passando per tutti i componenti senza mai scegliere una strada, è una serie." },
  { topic: "serie-parallelo", difficulty: 3, prompt: "In serie, se apri l'interruttore in un punto qualsiasi…", answer: "Tutto il circuito si spegne", distractors: ["Si spegne solo ciò che viene dopo","Si spegne solo ciò che viene prima","Non cambia niente nel circuito"], explanation: "Interrompere l'unico anello ferma la corrente ovunque, non solo a valle." },
  { topic: "serie-parallelo", difficulty: 4, prompt: "Perché le vecchie ghirlande natalizie si spegnevano tutte per una lampadina rotta?", answer: "Perché erano collegate in serie", distractors: ["Perché il fusibile era troppo debole","Perché la corrente era alternata","Perché mancava la messa a terra"], explanation: "Bastava un filamento interrotto per aprire l'unico anello: oggi si usa il parallelo, o serie con cortocircuito automatico." },
  { topic: "serie-parallelo", difficulty: 3, prompt: "Aggiungendo un ramo in parallelo, la corrente totale erogata dalla pila…", answer: "Aumenta", distractors: ["Diminuisce","Resta identica","Si annulla"], explanation: "Ogni ramo nuovo assorbe la sua corrente: la pila deve fornirne di più, e si scarica prima." },
  { topic: "serie-parallelo", difficulty: 4, prompt: "Perché in serie le tensioni si sommano?", answer: "Perché ogni componente ne consuma una parte", distractors: ["Perché la corrente aumenta a ogni passaggio","Perché la pila lavora di più con la serie","Perché i fili sono più lunghi in serie"], explanation: "La tensione della pila si distribuisce fra i componenti: sommando le cadute si ritrova il valore di partenza." },
  { topic: "misure-elettriche", difficulty: 2, prompt: "In quale unità si misura la corrente elettrica?", answer: "Ampere", distractors: ["Volt, come la tensione","Ohm, come la resistenza","Watt, come la potenza"], explanation: "Il volt misura la tensione, l'ohm la resistenza, il watt la potenza." },
  { topic: "misure-elettriche", difficulty: 2, prompt: "In quale unità si misura la tensione?", answer: "Volt", distractors: ["Ampere","Ohm","Joule"], explanation: "La tensione è la differenza di potenziale fra due punti, e si misura in volt." },
  { topic: "misure-elettriche", difficulty: 2, prompt: "In quale unità si misura la resistenza?", answer: "Ohm", distractors: ["Volt","Ampere","Watt"], explanation: "Il simbolo è la lettera greca omega, e il nome viene dallo scienziato che formulò la legge." },
  { topic: "misure-elettriche", difficulty: 3, prompt: "Con quale strumento si misura la tensione?", answer: "Voltmetro, collegato in parallelo", distractors: ["Amperometro, collegato in serie","Ohmmetro, sul circuito acceso","Wattmetro, ai capi della pila"], explanation: "La tensione è una differenza fra due punti: bisogna toccarli entrambi, quindi in parallelo." },
  { topic: "misure-elettriche", difficulty: 3, prompt: "Con quale strumento si misura la corrente?", answer: "Amperometro, collegato in serie", distractors: ["Voltmetro, collegato in parallelo","Ohmmetro, ai capi del componente","Termometro, sul filo che scalda"], explanation: "Deve essere attraversato dalla stessa corrente che vuole misurare: va inserito lungo il percorso." },
  { topic: "misure-elettriche", difficulty: 4, format: "numeric_input", prompt: "Con 12 volt e una resistenza di 4 ohm, quanti ampere passano?", answer: "3", explanation: "Corrente = tensione diviso resistenza: 12 diviso 4 fa 3 ampere." },
  { topic: "misure-elettriche", difficulty: 4, format: "numeric_input", prompt: "Con 9 volt e una resistenza di 3 ohm, quanti ampere passano?", answer: "3", explanation: "9 diviso 3 fa 3: è la legge di Ohm applicata direttamente." },
  { topic: "misure-elettriche", difficulty: 3, prompt: "Perché l'ohmmetro va usato su un circuito spento?", answer: "Perché manda lui una piccola corrente di prova", distractors: ["Perché altrimenti si consuma la batteria","Perché la corrente fa scaldare i cavi","Perché il circuito acceso è più difficile"], explanation: "Se il circuito è alimentato, le due correnti si sommano e la misura è falsa — o lo strumento si rovina." },
  { topic: "misure-elettriche", difficulty: 4, prompt: "In quale unità si misura la potenza elettrica?", answer: "Watt", distractors: ["Volt","Ampere","Ohm"], explanation: "La potenza è tensione per corrente: una lampadina da 60 W consuma 60 joule ogni secondo." },
  { topic: "misure-elettriche", difficulty: 4, format: "numeric_input", prompt: "Un apparecchio a 10 volt che assorbe 2 ampere, quanti watt consuma?", answer: "20", explanation: "Potenza = tensione × corrente: 10 × 2 fa 20 watt." },
  { topic: "misure-elettriche", difficulty: 3, prompt: "Che cosa misura il contatore di casa?", answer: "L'energia consumata nel tempo", distractors: ["La tensione della rete elettrica","La resistenza dell'impianto","Il numero di apparecchi accesi"], explanation: "Si paga l'energia, cioè potenza per tempo: si misura in chilowattora." },
  { topic: "circuito", difficulty: 2, prompt: "Che cosa serve perché la corrente scorra in un circuito?", answer: "Un percorso chiuso e una sorgente di tensione", distractors: ["Soltanto una pila abbastanza carica","Soltanto un filo di rame molto lungo","Un interruttore aperto sul percorso"], explanation: "Servono entrambe le cose: la pila spinge, ma senza anello chiuso la corrente non ha dove andare." },
  { topic: "circuito", difficulty: 3, prompt: "Che cos'è un circuito aperto?", answer: "Un circuito interrotto in cui non passa corrente", distractors: ["Un circuito senza la copertura isolante sui fili","Un circuito con troppi componenti collegati","Un circuito costruito all'aria aperta"], explanation: "Aperto significa spezzato: l'interruttore spento crea proprio un'interruzione voluta." },
  { topic: "circuito", difficulty: 3, prompt: "Che cos'è un cortocircuito?", answer: "Un collegamento diretto che salta i componenti", distractors: ["Un circuito costruito con fili troppo corti","Un circuito con la pila ormai scarica","Un circuito privo di qualsiasi interruttore"], explanation: "La corrente trova una scorciatoia senza resistenza: ne passa moltissima, e tutto si scalda pericolosamente." },
  { topic: "circuito", difficulty: 3, prompt: "In che verso si considera convenzionalmente la corrente?", answer: "Dal polo positivo al negativo", distractors: ["Dal polo negativo al positivo","In entrambi i versi insieme","Sempre verso la terra"], explanation: "È una convenzione storica: gli elettroni si muovono in realtà al contrario, ma i calcoli restano validi." },
  { topic: "circuito", difficulty: 4, prompt: "Che cos'è un nodo in un circuito?", answer: "Un punto in cui si incontrano tre o più fili", distractors: ["Un punto in cui il filo è annodato","Il collegamento fra pila e interruttore","Un componente che blocca la corrente"], explanation: "Nei nodi la corrente si divide o si ricongiunge: quello che entra è uguale a quello che esce." },
  { topic: "circuito", difficulty: 2, prompt: "A che cosa serve un interruttore?", answer: "Ad aprire e chiudere il percorso della corrente", distractors: ["Ad aumentare la corrente disponibile nel circuito","A trasformare la corrente in luce visibile","A misurare quanta corrente sta passando"], explanation: "Non produce e non consuma: decide soltanto se il circuito è chiuso o interrotto." },
  { topic: "circuito", difficulty: 4, prompt: "Perché uno schema elettrico usa simboli invece di disegni?", answer: "Perché così il circuito si legge subito e ovunque", distractors: ["Perché i disegni sarebbero troppo grandi","Perché i simboli si colorano meglio","Perché è vietato disegnare i componenti"], explanation: "I simboli sono uno standard internazionale: conta come sono collegati i componenti, non come sono fatti." },
  { topic: "circuito", difficulty: 3, prompt: "Che cosa succede se inverti i poli di una pila in un circuito con un LED?", answer: "Il LED non si accende", distractors: ["Il LED si accende più forte","Il LED cambia colore","Il LED si brucia subito"], explanation: "Il LED è un diodo: lascia passare la corrente in un verso solo. Al contrario, semplicemente non conduce." },
  { topic: "circuito", difficulty: 4, prompt: "Perché conviene disegnare lo schema prima di montare un circuito?", answer: "Perché gli errori si trovano sulla carta invece che sui componenti", distractors: ["Perché lo schema è richiesto dalle norme di sicurezza","Perché così il montaggio diventa molto più veloce","Perché in questo modo i componenti costano meno"], explanation: "Un collegamento sbagliato su carta si cancella; sul banco può bruciare un componente." },
  { topic: "conduttori", difficulty: 2, prompt: "Quale materiale conduce meglio la corrente?", answer: "Rame", distractors: ["Vetro","Gomma","Legno asciutto"], explanation: "I metalli hanno elettroni liberi di muoversi; vetro, gomma e legno secco no." },
  { topic: "conduttori", difficulty: 2, prompt: "Che cos'è un isolante?", answer: "Un materiale che non lascia passare la corrente", distractors: ["Un materiale che conduce lentamente","Un materiale che accumula corrente","Un materiale che si scalda facilmente"], explanation: "Plastica, vetro, gomma: si usano proprio per impedire che la corrente vada dove non deve." },
  { topic: "conduttori", difficulty: 3, prompt: "Perché i metalli conducono bene la corrente?", answer: "Perché hanno elettroni liberi di spostarsi", distractors: ["Perché sono duri e resistenti","Perché sono lucidi in superficie","Perché si scaldano molto in fretta"], explanation: "Nel reticolo metallico gli elettroni esterni non appartengono a un atomo solo: basta una spinta e si muovono." },
  { topic: "conduttori", difficulty: 3, prompt: "Un filo più grosso, a parità di lunghezza, ha una resistenza…", answer: "Minore", distractors: ["Maggiore","Identica","Doppia"], explanation: "Più spazio per passare significa meno ostacolo: come un tubo largo che lascia scorrere più acqua." },
  { topic: "conduttori", difficulty: 4, prompt: "Perché i cavi dell'alta tensione sono spesso di alluminio e non di rame?", answer: "Perché a parità di conduzione pesa molto meno", distractors: ["Perché l'alluminio conduce meglio del rame","Perché l'alluminio non si scalda mai","Perché il rame è vietato all'aperto"], explanation: "Il rame conduce meglio, ma pesa il triplo: su chilometri sospesi fra tralicci il peso decide." },
  { topic: "conduttori", difficulty: 3, prompt: "L'acqua pura conduce bene la corrente?", answer: "No, quasi per niente", distractors: ["Sì, meglio del rame","Sì, come tutti i liquidi","Sì, ma solo se è fredda"], explanation: "È l'acqua con sali disciolti a condurre: sono gli ioni a trasportare la carica, non l'acqua in sé." },
  { topic: "conduttori", difficulty: 4, prompt: "Che cos'è un semiconduttore?", answer: "Un materiale che conduce solo in certe condizioni", distractors: ["Un materiale che conduce a metà velocità","Un conduttore tagliato a metà","Un isolante che si è rovinato"], explanation: "Il silicio conduce o no a seconda di come lo si tratta: su questa proprietà è costruita tutta l'elettronica moderna." },
  { topic: "conduttori", difficulty: 3, prompt: "Perché la grafite della matita conduce la corrente?", answer: "Perché è una forma di carbonio con elettroni mobili", distractors: ["Perché contiene piccole parti di metallo","Perché è nera e assorbe l'energia","Perché è più morbida degli altri materiali"], explanation: "È l'unico non metallo di uso comune che conduce: la sua struttura a strati lascia liberi alcuni elettroni." },
  { topic: "conduttori", difficulty: 4, prompt: "Perché la resistenza di un filo aumenta quando si scalda?", answer: "Perché gli atomi vibrano e ostacolano gli elettroni", distractors: ["Perché il filo si allunga per la dilatazione","Perché il filo perde una parte degli elettroni liberi","Perché l'isolante che lo copre comincia a sciogliersi"], explanation: "Il calore agita il reticolo: gli elettroni urtano più spesso e fanno più fatica a passare." },
  { topic: "elettricita-base", difficulty: 2, prompt: "Che cos'è la corrente elettrica?", answer: "Un movimento ordinato di cariche elettriche", distractors: ["Un accumulo di cariche in un punto","Il calore prodotto da un filo","La luce emessa da una lampadina"], explanation: "Senza movimento non c'è corrente: le cariche ferme danno elettricità statica, non corrente." },
  { topic: "elettricita-base", difficulty: 3, prompt: "Che cos'è la tensione elettrica?", answer: "La differenza di potenziale che spinge le cariche", distractors: ["La quantità di cariche che si stanno muovendo","L'ostacolo che le cariche incontrano nel filo","Il calore prodotto dal passaggio della corrente"], explanation: "È come il dislivello per l'acqua: senza differenza fra i due punti, niente si muove." },
  { topic: "elettricita-base", difficulty: 3, prompt: "Che cos'è la resistenza elettrica?", answer: "L'ostacolo che il materiale oppone alla corrente", distractors: ["La spinta che il materiale dà alle cariche","La quantità di corrente che passa","L'energia immagazzinata nel filo"], explanation: "Più resistenza, meno corrente a parità di tensione: è il freno del circuito." },
  { topic: "elettricita-base", difficulty: 3, prompt: "Che cos'è l'elettricità statica?", answer: "Cariche accumulate e ferme su un corpo", distractors: ["Corrente che scorre molto lentamente","Corrente che cambia verso di continuo","Elettricità prodotta senza pila"], explanation: "Strofinando una penna sui capelli si accumulano cariche: restano lì finché non trovano una via di scarico." },
  { topic: "elettricita-base", difficulty: 4, prompt: "Che differenza c'è fra corrente continua e alternata?", answer: "La continua scorre sempre nello stesso verso", distractors: ["La continua è più forte dell'alternata","L'alternata funziona solo con le pile","La continua non produce calore"], explanation: "Le pile danno corrente continua; la rete di casa dà corrente alternata, che inverte il verso molte volte al secondo." },
  { topic: "elettricita-base", difficulty: 4, prompt: "Perché una pila si scarica?", answer: "Perché finisce l'energia chimica al suo interno", distractors: ["Perché perde elettroni nell'aria","Perché il metallo si consuma per attrito","Perché la corrente la raffredda troppo"], explanation: "Dentro la pila avviene una reazione chimica: quando i reagenti si esauriscono, non c'è più nulla che spinga le cariche." },
  { topic: "elettricita-base", difficulty: 3, prompt: "Che cosa fa la corrente attraversando un filo sottile?", answer: "Lo scalda", distractors: ["Lo raffredda","Lo allunga in modo permanente","Non produce alcun effetto"], explanation: "È l'effetto Joule: si usa apposta nei fornelli e negli asciugacapelli, e si teme nei cavi sottodimensionati." },
  { topic: "elettricita-base", difficulty: 4, prompt: "Se raddoppi la resistenza e raddoppi la tensione, la corrente…", answer: "Resta uguale", distractors: ["Raddoppia","Si dimezza","Diventa quattro volte"], explanation: "Corrente = tensione diviso resistenza: raddoppiando entrambe, il rapporto non cambia." },
  { topic: "guasti", difficulty: 3, prompt: "Una lampadina non si accende ma le altre del circuito sì. Dove cercare?", answer: "Nella lampadina o nel suo collegamento", distractors: ["Nella pila che alimenta tutto","Nell'interruttore generale","Nel filo principale di ritorno"], explanation: "Se il guasto fosse a monte si spegnerebbe tutto: quando ne resta una sola, il problema è locale." },
  { topic: "guasti", difficulty: 4, prompt: "Qual è il modo più efficiente di cercare un guasto in un circuito lungo?", answer: "Provare a metà e capire da che parte sta", distractors: ["Controllare tutti i componenti in ordine","Sostituire subito il componente più caro","Rifare il circuito da capo"], explanation: "Ogni prova a metà dimezza la zona da controllare: è la ricerca binaria applicata a un guasto." },
  // Basi dell'elettricità
  { topic: "elettricita-base", difficulty: 1, prompt: "Cosa fa accendere una lampadina in un circuito?", answer: "La corrente elettrica", distractors: ["Il rumore del vento", "La luce del Sole", "Il soffio dell'aria"], explanation: "La corrente che scorre nel filo accende la lampadina." },
  { topic: "elettricita-base", difficulty: 2, prompt: "Come si chiama il flusso di cariche elettriche in un filo?", answer: "Corrente elettrica", distractors: ["Tensione statica", "Calore", "Magnetismo"], explanation: "La corrente è il movimento delle cariche nel conduttore." },
  { topic: "elettricita-base", difficulty: 3, prompt: "La 'spinta' che mette in movimento la corrente si chiama…", answer: "Tensione (voltaggio)", distractors: ["Resistenza (in ohm)", "Massa (in chili)", "Frequenza (in hertz)"], explanation: "La tensione (in volt) spinge la corrente nel circuito." },
  // Il circuito
  { topic: "circuito", difficulty: 1, prompt: "Perché una lampadina si accenda, il circuito deve essere…", answer: "Chiuso", distractors: ["Aperto", "Rotto", "Bagnato"], explanation: "Solo con il circuito chiuso la corrente può fare un giro completo." },
  { topic: "circuito", difficulty: 2, prompt: "A cosa serve un interruttore in un circuito?", answer: "Ad aprire o chiudere il passaggio di corrente", distractors: ["A produrre da solo la luce del circuito", "A misurare il tempo che passa", "A scaldare l'acqua del bicchiere"], explanation: "L'interruttore apre (spegne) o chiude (accende) il circuito." },
  { topic: "circuito", difficulty: 2, prompt: "In una torcia, cosa fornisce l'energia elettrica?", answer: "La pila (batteria)", distractors: ["L'interruttore", "Il filo", "La lampadina"], explanation: "La pila è il generatore che alimenta il circuito." },
  // Conduttori e isolanti
  { topic: "conduttori", difficulty: 2, prompt: "Quale materiale conduce bene l'elettricità?", answer: "Il rame (un metallo)", distractors: ["La gomma dura", "La plastica dura", "Il legno ben secco"], explanation: "I metalli come il rame sono buoni conduttori." },
  { topic: "conduttori", difficulty: 3, prompt: "Come si chiama un materiale che NON lascia passare la corrente?", answer: "Isolante", distractors: ["Conduttore", "Magnete", "Generatore"], explanation: "Gomma e plastica sono isolanti: proteggono dai contatti." },
  // Serie e parallelo
  { topic: "serie-parallelo", difficulty: 3, prompt: "In un collegamento in SERIE, se una lampadina si brucia, le altre…", answer: "Si spengono", distractors: ["Restano accese", "Si accendono di più", "Cambiano colore"], explanation: "In serie la corrente ha un unico percorso: si interrompe per tutte." },
  { topic: "serie-parallelo", difficulty: 4, prompt: "In un collegamento in PARALLELO, se una lampadina si brucia, le altre…", answer: "Restano accese", distractors: ["Si spengono tutte", "Si spengono a metà", "Esplodono"], explanation: "In parallelo ogni lampadina ha il suo percorso indipendente." },
  // Sicurezza
  { topic: "sicurezza-elettrica", difficulty: 1, prompt: "Perché non si toccano le prese con le mani bagnate?", answer: "L'acqua conduce e si rischia la scossa", distractors: ["Si sporca la presa di corrente", "Fa rumore e disturba gli altri", "Si consuma molta più energia"], explanation: "L'acqua rende il corpo conduttore: pericolo di scossa." },
  { topic: "sicurezza-elettrica", difficulty: 2, prompt: "Cosa NON bisogna mai infilare in una presa di corrente?", answer: "Oggetti metallici o le dita", distractors: ["La spina di un apparecchio", "Un copripresa di sicurezza", "Niente, è sempre sicuro"], explanation: "I metalli conducono: infilarli nella presa è pericolosissimo." },
  // Componenti (stesso topic dei generati)
  { topic: "componenti", difficulty: 2, prompt: "A cosa serve un resistore in un circuito?", answer: "A limitare la corrente", distractors: ["A produrre corrente", "A spegnere il computer", "A illuminare sempre"], explanation: "Il resistore riduce la corrente, proteggendo gli altri componenti." },
  { topic: "componenti", difficulty: 2, prompt: "Un LED si accende solo se collegato…", answer: "Nel verso giusto (ha una polarità)", distractors: ["In qualsiasi verso, non importa", "Solo al buio completo", "Solo con l'acqua vicino"], explanation: "È fatto di due materiali diversi uniti insieme: la corrente passa da uno all'altro come per una valvola, ma non torna indietro." },
  // Misure elettriche
  { topic: "misure-elettriche", difficulty: 3, prompt: "Con quale unità si misura la tensione?", answer: "Volt", distractors: ["Watt", "Metri", "Gradi"], explanation: "Il volt misura la differenza fra due punti: per questo si parla di tensione FRA due punti, mai in uno solo." },
  { topic: "misure-elettriche", difficulty: 3, prompt: "Con quale unità si misura la corrente elettrica?", answer: "Ampere", distractors: ["Volt", "Litri", "Secondi"], explanation: "Un ampere è una quantità di carica che passa ogni secondo: la corrente è un flusso, non una quantità ferma." },
  { topic: "elettricita-base", difficulty: 1, format: "short_answer", prompt: "Qual è l'unità di misura della tensione elettrica?", answer: "volt", explanation: "Si misura fra due punti, mai in un punto solo." },
  { topic: "elettricita-base", difficulty: 1, format: "short_answer", prompt: "Qual è l'unità di misura della corrente elettrica?", answer: "ampere", explanation: "Dice quanta carica passa in un secondo." },
  { topic: "elettricita-base", difficulty: 2, format: "short_answer", prompt: "Qual è l'unità di misura della resistenza elettrica?", answer: "ohm", explanation: "Il simbolo è la lettera greca omega." },
  { topic: "elettricita-base", difficulty: 2, format: "short_answer", prompt: "Qual è l'unità di misura della potenza elettrica?", answer: "watt", explanation: "Tensione per corrente: dice quanta energia si consuma ogni secondo." },
  { topic: "componenti", difficulty: 1, format: "short_answer", prompt: "Come si chiama il componente che si oppone al passaggio della corrente?", answer: "resistore", accept: ["resistenza"], explanation: "Il valore si legge dalle fasce colorate." },
  { topic: "componenti", difficulty: 2, format: "short_answer", prompt: "Come si chiama il componente che accumula carica fra due armature?", answer: "condensatore", explanation: "Si carica e si scarica: per questo serve nei filtri e nei temporizzatori." },
  { topic: "componenti", difficulty: 2, format: "short_answer", prompt: "Come si chiama il componente che lascia passare la corrente in un verso solo?", answer: "diodo", explanation: "Montato al contrario blocca tutto: il verso è indicato da una fascetta." },
  { topic: "componenti", difficulty: 2, format: "short_answer", prompt: "Come si chiama il diodo che emette luce quando è attraversato dalla corrente?", answer: "LED", accept: ["led", "diodo led"], explanation: "Va sempre alimentato con una resistenza in serie, altrimenti si brucia." },
  { topic: "componenti", difficulty: 3, format: "short_answer", prompt: "Come si chiama il componente a tre terminali che amplifica o commuta un segnale?", answer: "transistor", accept: ["transistore"], explanation: "Con una corrente piccola comanda una corrente grande: è la base dell'elettronica digitale." },
  { topic: "componenti", difficulty: 2, format: "short_answer", prompt: "Come si chiama il componente che apre e chiude un circuito a comando?", answer: "interruttore", explanation: "Aperto interrompe il giro: senza giro chiuso non passa corrente." },
  { topic: "circuito", difficulty: 1, format: "short_answer", prompt: "Come si chiama il percorso chiuso in cui scorre la corrente?", answer: "circuito", explanation: "Se il percorso si interrompe in un punto solo, tutto si ferma." },
  { topic: "circuito", difficulty: 2, format: "short_answer", prompt: "Come si chiama il collegamento diretto fra i due poli senza carico, che fa passare troppa corrente?", answer: "cortocircuito", explanation: "La corrente sceglie la via senza resistenza: scalda e brucia." },
  { topic: "circuito", difficulty: 2, format: "short_answer", prompt: "Come si chiama il componente che fornisce energia al circuito?", answer: "generatore", accept: ["pila", "batteria"], explanation: "Pila, alimentatore, dinamo: cambia la forma, non il ruolo." },
  { topic: "serie-parallelo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il collegamento in cui la corrente ha un solo percorso possibile?", answer: "serie", explanation: "Un componente che si guasta apre il circuito e spegne tutti gli altri." },
  { topic: "serie-parallelo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il collegamento in cui ogni componente ha la stessa tensione ai capi?", answer: "parallelo", explanation: "Le lampadine di casa sono in parallelo: se una si fulmina, le altre restano accese." },
  { topic: "misure-elettriche", difficulty: 1, format: "short_answer", prompt: "Come si chiama lo strumento che misura la tensione?", answer: "voltmetro", explanation: "Si collega in parallelo, ai capi del componente da misurare." },
  { topic: "misure-elettriche", difficulty: 2, format: "short_answer", prompt: "Come si chiama lo strumento che misura la corrente?", answer: "amperometro", explanation: "Si collega in serie: la corrente deve attraversarlo." },
  { topic: "misure-elettriche", difficulty: 2, format: "short_answer", prompt: "Come si chiama lo strumento che misura tensione, corrente e resistenza?", answer: "multimetro", explanation: "Una manopola sceglie la grandezza: sbagliare portata è l'errore più comune." },
  { topic: "misure-elettriche", difficulty: 3, format: "short_answer", prompt: "Come si chiama la legge che lega tensione, corrente e resistenza?", answer: "legge di Ohm", accept: ["Ohm", "legge di ohm"], explanation: "V uguale R per I: da lì si ricava qualunque delle tre." },
  { topic: "conduttori", difficulty: 1, format: "short_answer", prompt: "Come si chiama un materiale che lascia passare bene la corrente?", answer: "conduttore", explanation: "I metalli conducono perché hanno elettroni liberi di muoversi." },
  { topic: "conduttori", difficulty: 1, format: "short_answer", prompt: "Come si chiama un materiale che non lascia passare la corrente?", answer: "isolante", explanation: "La plastica intorno ai fili è isolante: serve a tenere la corrente dentro il rame." },
  { topic: "conduttori", difficulty: 2, format: "short_answer", prompt: "Qual è il metallo più usato per i fili elettrici nelle case?", answer: "rame", explanation: "Conduce bene, si piega senza rompersi e costa meno dell'argento." },
  { topic: "conduttori", difficulty: 3, format: "short_answer", prompt: "Come si chiama un materiale che conduce solo in certe condizioni, come il silicio?", answer: "semiconduttore", explanation: "Su questa proprietà si costruiscono diodi e transistor." },
  { topic: "sicurezza-elettrica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il collegamento che porta a terra le correnti pericolose?", answer: "messa a terra", accept: ["terra"], explanation: "Offre alla corrente una strada che non passa per le persone." },
  { topic: "sicurezza-elettrica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il dispositivo che si apre da solo quando passa troppa corrente?", answer: "interruttore magnetotermico", accept: ["magnetotermico", "salvavita"], explanation: "Protegge i fili dal surriscaldamento." },
  { topic: "sicurezza-elettrica", difficulty: 1, format: "short_answer", prompt: "Come si chiama il filo sottile che si fonde e interrompe il circuito in caso di sovracorrente?", answer: "fusibile", explanation: "Si sacrifica lui al posto dell'impianto: va sostituito con uno dello stesso valore." },
  { topic: "sicurezza-elettrica", difficulty: 3, format: "short_answer", prompt: "Quale liquido rende molto più pericoloso il contatto con la corrente?", answer: "acqua", accept: ["l'acqua"], explanation: "Con la pelle bagnata la resistenza del corpo crolla e passa più corrente." },
  { topic: "guasti", difficulty: 2, format: "short_answer", prompt: "Come si chiama un'interruzione del percorso che impedisce alla corrente di scorrere?", answer: "circuito aperto", accept: ["interruzione"], explanation: "Un filo staccato basta: la corrente non salta il vuoto." },
  { topic: "guasti", difficulty: 3, format: "short_answer", prompt: "Qual è il primo controllo da fare quando un circuito a pila non funziona affatto?", answer: "la pila", accept: ["pila", "l'alimentazione", "alimentazione"], explanation: "Prima di smontare tutto si verifica l'alimentazione: è il guasto più frequente." },
];

// Come si CONTROLLA un guasto, una volta sospettato. Identificarlo è metà del
// lavoro: l'altra metà è sapere dove mettere le mani, e nessun indizio la dice.
const VERIFICA_GUASTO = {
  "missing-wire": "Si segue il giro con il dito partendo dal positivo: dove il dito si ferma, manca il collegamento.",
  "open-switch": "Si prova a ponticellare i due morsetti dell'interruttore: se il circuito riparte, era lui aperto.",
  "missing-resistor": "Senza resistore il LED riceve tutta la tensione della pila: si accende fortissimo per un istante e poi resta spento per sempre.",
  "reversed-led": "Il catodo va al negativo e si riconosce dal piedino più corto o dalla smussatura sul bordo. Basta girarlo.",
  "wrong-resistor-value": "Si rileggono le fasce colorate e si confronta il valore con quello previsto: troppo alto spegne, troppo basso brucia.",
  "disconnected-component": "Essere sulla basetta non basta: si controlla che i piedini siano nella stessa fila di contatti del resto del giro.",
  "sensor-unpowered": "Si misura la tensione fra i due pin di alimentazione del sensore: se è zero, il sensore non sta nemmeno lavorando.",
  "parallel-branch-open": "Si prova un ramo per volta scollegando l'altro: quello che resta spento da solo è il ramo interrotto.",
  "capacitor-discharged": "Si misura la tensione ai suoi capi mentre il circuito lavora: se resta a zero, non si sta caricando.",
  "short-circuit": "Si stacca l'alimentazione e si misura la resistenza fra i due poli: vicino a zero significa che c'è una scorciatoia.",
  "loose-ground": "Si muove piano il collegamento di massa a circuito acceso: se l'anomalia va e viene, il contatto non è stabile.",
  "relay-not-armed": "Si ascolta lo scatto: senza il «click» la bobina non è alimentata, e il carico non può partire.",
};

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
          // NON `fault.hint`: quello è già citato dentro la domanda, e come
          // spiegazione faceva rileggere al bambino la stessa identica frase.
          // Qui serve il passo dopo — come si verifica quel guasto sul banco.
          explanation: VERIFICA_GUASTO[fault.type] ?? fault.hint,
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
  { topic: "variabili", difficulty: 1, prompt: "Quale di questi è un nome di variabile valido in Python?", answer: "punti_totali", distractors: ["2punti","punti totali","punti-totali"], explanation: "Un nome può avere lettere, cifre e underscore, ma non può iniziare con una cifra né contenere spazi o trattini." },
  { topic: "variabili", difficulty: 2, format: "numeric_input", prompt: "a = 3\nb = a\na = 10\nprint(b)\n\nCosa stampa?", answer: "3", explanation: "b ha copiato il valore di a nel momento dell'assegnazione: cambiare a dopo non tocca b." },
  { topic: "variabili", difficulty: 2, prompt: "In Python, il simbolo = serve a…", answer: "Mettere un valore dentro una variabile", distractors: ["Verificare se due valori sono uguali","Stampare un valore","Definire una funzione"], explanation: "= assegna, cioè scrive un valore nella variabile a sinistra. Per confrontare serve ==." },
  { topic: "variabili", difficulty: 3, format: "numeric_input", prompt: "punti = 0\npunti = punti + 5\npunti = punti + 5\nprint(punti)\n\nCosa stampa?", answer: "10", explanation: "Ogni riga rilegge il valore attuale e ne scrive uno nuovo: 0, poi 5, poi 10." },
  { topic: "variabili", difficulty: 3, prompt: "Quale scrittura è più breve per punti = punti + 1?", answer: "punti += 1", distractors: ["punti ++","punti = ++1","punti =+ 1"], explanation: "+= aggiunge al valore esistente. Python non ha l'operatore ++ di altri linguaggi." },
  { topic: "variabili", difficulty: 2, prompt: "Perché conviene chiamare una variabile punti_vita invece di p?", answer: "Perché rileggendo il codice si capisce cosa contiene", distractors: ["Perché i nomi lunghi rendono il programma più veloce", "Perché in Python i nomi di una lettera sola sono vietati", "Perché un nome corto fa occupare meno memoria"], explanation: "Il codice si legge molte più volte di quante si scriva: un nome che spiega sé stesso fa risparmiare tempo dopo." },
  { topic: "variabili", difficulty: 3, prompt: "x = 5\nprint(y)\n\nPerché questo programma si ferma?", answer: "y non è mai stata definita", distractors: ["print accetta solo testo","x e y devono avere lo stesso valore","manca il punto e virgola"], explanation: "Una variabile esiste solo dopo che le si è assegnato qualcosa: prima Python non sa cosa sia y." },
  { topic: "variabili", difficulty: 4, format: "numeric_input", prompt: "a = 2\nb = 5\na, b = b, a\nprint(a)\n\nCosa stampa?", answer: "5", explanation: "Python valuta prima la destra e poi assegna: i due valori si scambiano in una riga sola." },
  { topic: "variabili", difficulty: 2, prompt: "In Python, PUNTI e punti sono…", answer: "Due variabili diverse", distractors: ["La stessa variabile","Un errore di sintassi","Sinonimi automatici"], explanation: "Python distingue maiuscole e minuscole: sono due nomi diversi, ed è una fonte di errori molto comune." },
  { topic: "variabili", difficulty: 3, prompt: "Che cosa contiene una variabile subito dopo nome = 'Eli'?", answer: "La stringa Eli", distractors: ["La lettera n","Il numero 3","Niente, va assegnata due volte"], explanation: "L'assegnazione è immediata: da quel momento la variabile nome vale 'Eli'." },
  { topic: "variabili", difficulty: 4, format: "numeric_input", prompt: "totale = 0\nfor n in [2, 3, 5]:\n    totale += n\nprint(totale)\n\nCosa stampa?", answer: "10", explanation: "La variabile accumula: 0+2=2, poi +3=5, poi +5=10. È lo schema dell'accumulatore." },
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è il valore True?", answer: "Booleano", distractors: ["Stringa","Numero intero","Lista"], explanation: "True e False sono i due valori booleani: rappresentano vero e falso, e si scrivono con la maiuscola." },
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è il valore 3.5?", answer: "Numero con la virgola (float)", distractors: ["Numero intero senza decimali (int)", "Stringa di testo fra virgolette", "Booleano, cioè vero o falso"], explanation: "Un numero con la parte decimale è un float. In Python il separatore è il punto, non la virgola." },
  { topic: "tipi", difficulty: 3, prompt: "Qual è la differenza fra 7 e '7'?", answer: "Il primo è un numero, il secondo è testo", distractors: ["Nessuna: Python li tratta allo stesso modo","Sono entrambi numeri, scritti in due modi","Il secondo non è una scrittura valida"], explanation: "Le virgolette cambiano il tipo: con 7 si può fare aritmetica, con '7' si può solo unire ad altro testo." },
  { topic: "tipi", difficulty: 3, format: "numeric_input", prompt: "Cosa restituisce int('12')?", answer: "12", explanation: "int() converte una stringa che contiene cifre nel numero corrispondente." },
  { topic: "tipi", difficulty: 4, prompt: "Cosa succede con int('ciao')?", answer: "Un errore: non è un numero", distractors: ["Restituisce 0","Restituisce 'ciao'","Restituisce la lunghezza"], explanation: "int() converte solo stringhe che rappresentano un numero: su un testo qualsiasi si ferma." },
  { topic: "tipi", difficulty: 3, prompt: "Quale funzione dice di che tipo è un valore?", answer: "type()", distractors: ["kind()","typeof()","class()"], explanation: "type(x) restituisce il tipo di x: utile quando un programma si comporta in modo inatteso." },
  { topic: "tipi", difficulty: 3, prompt: "Cosa restituisce str(9)?", answer: "La stringa '9'", distractors: ["Il numero 9","Il booleano True","Un errore"], explanation: "str() trasforma un valore in testo: serve quando si vuole unirlo ad altre stringhe." },
  { topic: "tipi", difficulty: 4, format: "numeric_input", prompt: "Cosa restituisce int(7.9)?", answer: "7", explanation: "int() taglia la parte decimale, non arrotonda: 7.9 diventa 7. Per arrotondare serve round()." },
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è [1, 2, 3]?", answer: "Lista", distractors: ["Stringa","Numero","Booleano"], explanation: "Le parentesi quadre con valori separati da virgole formano una lista." },
  { topic: "tipi", difficulty: 4, prompt: "Cosa stampa: print(3 + 2.0)?", answer: "5.0", distractors: ["5","32.0","errore"], explanation: "Mescolando int e float Python usa il tipo più «largo»: il risultato è un float." },
  { topic: "tipi", difficulty: 3, prompt: "Perché serve convertire il risultato di input() prima di fare calcoli?", answer: "Perché input() restituisce sempre testo", distractors: ["Perché input() restituisce sempre un float","Perché i calcoli vanno fatti a fine programma","Perché altrimenti il programma è lento"], explanation: "Anche quando l'utente scrive 42, il programma riceve la stringa '42': senza conversione i calcoli non funzionano." },
  { topic: "booleani", difficulty: 2, prompt: "Quali sono i due soli valori booleani in Python?", answer: "True e False", distractors: ["Vero e Falso, in italiano", "Soltanto i numeri 1 e 0", "Le parole Sì e No"], explanation: "Si scrivono in inglese e con l'iniziale maiuscola: true minuscolo darebbe errore." },
  { topic: "booleani", difficulty: 2, prompt: "Quanto vale 5 > 3?", answer: "True", distractors: ["False","5","'True'"], explanation: "Un confronto non restituisce un numero: restituisce vero o falso." },
  { topic: "booleani", difficulty: 3, prompt: "Quanto vale (4 > 2) and (1 > 5)?", answer: "False", distractors: ["True","Errore","4"], explanation: "and è vero solo se lo sono entrambe le parti: la seconda è falsa, quindi tutto è falso." },
  { topic: "booleani", difficulty: 3, prompt: "Quanto vale (4 > 2) or (1 > 5)?", answer: "True", distractors: ["False","Errore","2"], explanation: "or basta che una parte sia vera: la prima lo è." },
  { topic: "booleani", difficulty: 3, prompt: "Quanto vale not True?", answer: "False", distractors: ["True","0","Errore"], explanation: "not capovolge il valore: rende falso ciò che è vero e viceversa." },
  { topic: "booleani", difficulty: 4, prompt: "Quanto vale 3 == 3.0?", answer: "True", distractors: ["False","Errore","3"], explanation: "== confronta i valori, non i tipi: tre intero e tre virgola zero valgono lo stesso." },
  { topic: "booleani", difficulty: 3, prompt: "Quale operatore verifica che due valori siano DIVERSI?", answer: "!=", distractors: ["=/=","<>","not ="], explanation: "!= si legge «diverso da» e restituisce True quando i due valori non coincidono." },
  { topic: "booleani", difficulty: 4, prompt: "eta = 12\nprint(10 <= eta <= 14)\n\nCosa stampa?", answer: "True", distractors: ["False","12","Errore"], explanation: "Python permette di concatenare i confronti: legge «eta è fra 10 e 14, estremi compresi»." },
  { topic: "booleani", difficulty: 2, prompt: "A cosa serve un valore booleano in un programma?", answer: "A decidere quale strada prendere", distractors: ["A contare gli elementi","A stampare a schermo","A dare un nome alle variabili"], explanation: "if e while lavorano su valori booleani: sono loro a decidere se un blocco si esegue o si ripete." },
  { topic: "booleani", difficulty: 4, prompt: "Perché if x = 5: dà errore mentre if x == 5: funziona?", answer: "Il primo assegna invece di confrontare", distractors: ["Il primo confronta troppo lentamente","Il secondo funziona solo con i numeri","Nessuna differenza, sono uguali"], explanation: "Un solo uguale scrive nella variabile; il doppio uguale fa una domanda. È l'errore più comune di chi comincia." },
  { topic: "booleani", difficulty: 3, prompt: "Quanto vale not (2 > 5)?", answer: "True", distractors: ["False","2","Errore"], explanation: "2 > 5 è falso; not lo capovolge e restituisce vero." },
  { topic: "funzioni", difficulty: 2, prompt: "A che cosa serve definire una funzione?", answer: "A dare un nome a un pezzo di codice riutilizzabile", distractors: ["A rendere il programma più veloce da eseguire", "A creare nuove variabili senza assegnarle", "A stampare più cose insieme in una riga"], explanation: "Scritta una volta, si richiama quante volte serve: meno codice ripetuto significa meno posti dove sbagliare." },
  { topic: "funzioni", difficulty: 3, prompt: "def saluta(nome):\n    print('Ciao', nome)\n\nCome si chiama la funzione con il nome Eli?", answer: "saluta('Eli')", distractors: ["saluta Eli","def saluta('Eli')","print(saluta, 'Eli')"], explanation: "Si scrive il nome della funzione e fra parentesi i valori da passarle." },
  { topic: "funzioni", difficulty: 3, prompt: "In def somma(a, b):, come si chiamano a e b?", answer: "Parametri", distractors: ["Variabili globali","Risultati","Condizioni"], explanation: "I parametri sono i posti vuoti che la funzione riempie con i valori ricevuti a ogni chiamata." },
  { topic: "funzioni", difficulty: 3, prompt: "Quale parola restituisce un valore al codice che ha chiamato la funzione?", answer: "return", distractors: ["print","def","give"], explanation: "print mostra a schermo; return consegna il valore a chi ha chiamato, che può usarlo o metterlo in una variabile." },
  { topic: "funzioni", difficulty: 4, format: "numeric_input", prompt: "def doppio(n):\n    return n * 2\nprint(doppio(6))\n\nCosa stampa?", answer: "12", explanation: "La funzione riceve 6, restituisce 12, e print stampa il valore restituito." },
  { topic: "funzioni", difficulty: 4, prompt: "def doppio(n):\n    print(n * 2)\nx = doppio(4)\nprint(x)\n\nCosa stampa la seconda print?", answer: "None", distractors: ["8","4","Errore"], explanation: "La funzione stampa ma non restituisce niente: senza return, x riceve None." },
  { topic: "funzioni", difficulty: 2, prompt: "Quale parola introduce la definizione di una funzione?", answer: "def", distractors: ["function","fun","define"], explanation: "def sta per «define»: dopo di essa vengono il nome, i parametri fra parentesi e i due punti." },
  { topic: "funzioni", difficulty: 3, prompt: "Che cosa segna il corpo di una funzione in Python?", answer: "L'indentazione, cioè lo spazio a sinistra", distractors: ["Le parentesi graffe attorno al blocco", "Il punto e virgola a fine riga", "La parola end alla fine del blocco"], explanation: "In Python il rientro non è estetica: è la sintassi che dice quali righe appartengono alla funzione." },
  { topic: "funzioni", difficulty: 4, format: "numeric_input", prompt: "def somma(a, b):\n    return a + b\nprint(somma(3, 4) + somma(1, 1))\n\nCosa stampa?", answer: "9", explanation: "Le due chiamate restituiscono 7 e 2, e i due valori si sommano: 9." },
  { topic: "funzioni", difficulty: 3, prompt: "Perché una funzione dovrebbe fare una cosa sola?", answer: "Perché è più facile capirla e correggerla", distractors: ["Perché Python rifiuta le funzioni troppo lunghe", "Perché una funzione corta viene eseguita prima", "Perché così il programma occupa meno memoria"], explanation: "Una funzione che fa cinque cose si può riusare solo quando servono tutte e cinque, e quando sbaglia non si sa quale delle cinque." },
  { topic: "funzioni", difficulty: 4, format: "numeric_input", prompt: "Quante volte viene eseguito il corpo di una funzione che nessuno chiama?", answer: "0", explanation: "def non esegue niente: definisce soltanto. Il corpo gira solo alla chiamata." },
  { topic: "stile", difficulty: 2, prompt: "A che cosa serve un commento nel codice?", answer: "A spiegare a chi legge perché il codice fa così", distractors: ["A far andare il programma un po' più veloce", "A nascondere le righe che danno errore", "A dare un nome alle variabili usate sotto"], explanation: "Il computer li ignora; servono alle persone, compreso te fra sei mesi." },
  { topic: "stile", difficulty: 2, prompt: "Con quale simbolo comincia un commento in Python?", answer: "#", distractors: ["//","/*","--"], explanation: "Tutto ciò che segue # sulla stessa riga viene ignorato dall'interprete." },
  { topic: "stile", difficulty: 3, prompt: "Qual è il commento più utile?", answer: "# arrotondo per difetto: i punti sono sempre interi", distractors: ["# qui metto la variabile x uguale a cinque", "# questa riga dichiara una nuova variabile", "# da qui comincia il programma principale"], explanation: "Un buon commento dice il PERCHÉ, non ripete quello che il codice già dice da solo." },
  { topic: "stile", difficulty: 3, prompt: "Perché l'indentazione in Python non è solo questione di ordine?", answer: "Perché decide quali righe stanno dentro un blocco", distractors: ["Perché rende il file da salvare più piccolo", "Perché il rientro serve solo dentro i commenti", "Perché è l'editor di testo a richiederlo"], explanation: "In altri linguaggi si usano le graffe; in Python il rientro È la struttura, e sbagliarlo cambia il programma." },
  { topic: "stile", difficulty: 3, prompt: "Quale nome di variabile è scritto nello stile di Python?", answer: "punti_vita", distractors: ["PuntiVita","puntiVita","PUNTIVITA"], explanation: "In Python le variabili si scrivono minuscole con l'underscore fra le parole: si chiama snake_case." },
  { topic: "stile", difficulty: 4, prompt: "Un programma funziona ma nessuno riesce a modificarlo. È un buon programma?", answer: "No: il codice si legge più di quanto si scriva", distractors: ["Sì: l'unica cosa che conta è che funzioni", "Sì, purché venga eseguito abbastanza in fretta", "Dipende solo da quanto è lungo il programma"], explanation: "Un programma vive anni e viene modificato molte volte: se non si capisce, ogni modifica è un rischio." },
  { topic: "stile", difficulty: 2, prompt: "Che cosa succede se in Python indenti una riga in più per sbaglio?", answer: "Il programma può cambiare comportamento o dare errore", distractors: ["Niente: in Python gli spazi vengono ignorati", "Il codice viene eseguito un po' più in fretta", "Python se ne accorge e corregge da solo"], explanation: "Il rientro determina i blocchi: una riga rientrata di troppo finisce dentro un if o un ciclo a cui non apparteneva." },
  { topic: "stile", difficulty: 3, prompt: "Meglio una riga lunghissima o tre righe brevi che fanno lo stesso?", answer: "Tre righe brevi, se si leggono meglio", distractors: ["Sempre la riga lunga, è più efficiente","Sempre la riga lunga, è più elegante","È indifferente"], explanation: "La velocità non cambia; la comprensibilità sì, ed è quella a costare tempo quando qualcosa va storto." },
  { topic: "stile", difficulty: 4, prompt: "Hai lo stesso blocco di cinque righe copiato in tre punti. Cosa conviene fare?", answer: "Metterlo in una funzione e chiamarla tre volte", distractors: ["Lasciarlo così, funziona","Copiarlo una quarta volta per sicurezza","Cancellarne due"], explanation: "Codice duplicato significa correzioni duplicate: se scopri un errore devi ricordarti di sistemarlo in tutti e tre i punti." },
  { topic: "stile", difficulty: 3, prompt: "Perché è utile scrivere righe vuote fra parti diverse del programma?", answer: "Perché separano visivamente i blocchi di ragionamento", distractors: ["Perché Python le richiede fra un blocco e l'altro", "Perché servono a rendere il file più leggibile al computer", "Perché velocizzano l'esecuzione del programma"], explanation: "Come i paragrafi in un testo: aiutano l'occhio a capire dove finisce un'idea e ne comincia un'altra." },
  { topic: "stile", difficulty: 4, prompt: "Un nome come x va bene…", answer: "Per un contatore breve dentro un ciclo", distractors: ["Sempre, i nomi corti sono migliori","Mai, va sempre evitato","Solo per le stringhe"], explanation: "Dove la variabile vive due righe e il suo ruolo è ovvio, un nome corto è chiaro. Per un valore che attraversa il programma, no." },
  { topic: "cicli", difficulty: 2, format: "numeric_input", prompt: "Quante volte gira: for i in range(5)?", answer: "5", explanation: "range(5) produce 0, 1, 2, 3, 4: cinque valori, cinque giri." },
  { topic: "cicli", difficulty: 3, format: "numeric_input", prompt: "Qual è il primo valore prodotto da range(4)?", answer: "0", explanation: "range parte da zero se non gli si dice altrimenti: 0, 1, 2, 3." },
  { topic: "cicli", difficulty: 3, format: "numeric_input", prompt: "Quante volte gira: for i in range(2, 6)?", answer: "4", explanation: "Da 2 fino a 6 escluso: 2, 3, 4, 5. L'estremo finale non è mai compreso." },
  { topic: "cicli", difficulty: 3, prompt: "Quando si usa while invece di for?", answer: "Quando non si sa in anticipo quante ripetizioni servono", distractors: ["Quando le ripetizioni da fare sono più di dieci", "Quando si deve lavorare con stringhe invece che numeri", "Quando dentro il ciclo serve chiamare una funzione"], explanation: "for scorre una sequenza nota; while continua finché una condizione resta vera, anche senza sapere per quanto." },
  { topic: "cicli", difficulty: 4, format: "numeric_input", prompt: "totale = 0\nfor i in range(1, 5):\n    totale += i\nprint(totale)\n\nCosa stampa?", answer: "10", explanation: "Somma 1+2+3+4: il 5 non entra perché range si ferma prima dell'estremo." },
  { topic: "cicli", difficulty: 4, prompt: "Che cosa succede se in un while la condizione non diventa mai falsa?", answer: "Il programma non finisce più", distractors: ["Python lo interrompe da solo dopo poco","Il ciclo gira una volta sola","Viene segnalato un errore di sintassi"], explanation: "È il ciclo infinito: bisogna assicurarsi che dentro il corpo qualcosa avvicini la condizione al falso." },
  { topic: "cicli", difficulty: 3, prompt: "Quale parola interrompe subito un ciclo?", answer: "break", distractors: ["stop","exit","return"], explanation: "break esce dal ciclo immediatamente, senza completare i giri rimanenti." },
  { topic: "cicli", difficulty: 4, prompt: "Quale parola salta al giro successivo senza eseguire il resto del corpo?", answer: "continue", distractors: ["skip", "next", "resume"], explanation: "continue abbandona il giro corrente e riparte dal successivo; break invece esce dal ciclo del tutto." },
  { topic: "cicli", difficulty: 4, format: "numeric_input", prompt: "for i in range(3):\n    for j in range(2):\n        print('x')\n\nQuante x stampa?", answer: "6", explanation: "Il ciclo interno gira due volte per ognuno dei tre giri esterni: 3 × 2 = 6." },
  { topic: "cicli", difficulty: 2, prompt: "for lettera in 'ciao':\n\nSu che cosa sta girando questo ciclo?", answer: "Sui caratteri della stringa", distractors: ["Sui numeri da 0 a 4","Sulle parole della frase","Sulle righe del file"], explanation: "Un for può scorrere qualsiasi sequenza: una stringa viene percorsa un carattere alla volta." },
  { topic: "liste", difficulty: 2, format: "numeric_input", prompt: "numeri = [4, 8, 15]\nprint(numeri[0])\n\nCosa stampa?", answer: "4", explanation: "Gli indici partono da zero: il primo elemento è numeri[0]." },
  { topic: "liste", difficulty: 3, format: "numeric_input", prompt: "numeri = [4, 8, 15]\nprint(len(numeri))\n\nCosa stampa?", answer: "3", explanation: "len() conta gli elementi, non i caratteri: la lista ne contiene tre." },
  { topic: "liste", difficulty: 3, prompt: "Quale metodo aggiunge un elemento in fondo a una lista?", answer: "append()", distractors: ["add()","insert_end()","push()"], explanation: "lista.append(x) mette x come ultimo elemento, allungando la lista di uno." },
  { topic: "liste", difficulty: 4, format: "numeric_input", prompt: "numeri = [1, 2]\nnumeri.append(3)\nprint(len(numeri))\n\nCosa stampa?", answer: "3", explanation: "append aggiunge un elemento: da due si passa a tre." },
  { topic: "liste", difficulty: 3, prompt: "Come si prende l'ultimo elemento di una lista senza sapere quanti sono?", answer: "lista[-1]", distractors: ["lista[fine]","lista[len]","lista[ultimo]"], explanation: "Gli indici negativi contano dal fondo: -1 è l'ultimo, -2 il penultimo." },
  { topic: "liste", difficulty: 4, prompt: "Cosa succede con numeri = [1, 2, 3] e poi print(numeri[3])?", answer: "Errore: l'indice è fuori dalla lista", distractors: ["Stampa 3, cioè l'ultimo elemento", "Stampa None perché la posizione è vuota", "Stampa una lista vuota senza errori"], explanation: "Con tre elementi gli indici validi sono 0, 1 e 2: il 3 non esiste." },
  { topic: "liste", difficulty: 3, prompt: "In una lista si possono mettere valori di tipo diverso?", answer: "Sì, per esempio numeri e stringhe insieme", distractors: ["No, devono essere tutti dello stesso tipo","Solo se sono tutti numeri","Solo se la lista è vuota"], explanation: "Python non lo vieta. Spesso però una lista omogenea è più facile da usare senza sbagliare." },
  { topic: "liste", difficulty: 4, format: "numeric_input", prompt: "voti = [6, 7, 8]\nprint(sum(voti))\n\nCosa stampa?", answer: "21", explanation: "sum() somma tutti gli elementi numerici della lista: 6+7+8." },
  { topic: "liste", difficulty: 4, prompt: "Come si scorre una lista senza usare gli indici?", answer: "for elemento in lista:", distractors: ["for i in len(lista):","while lista:","for lista in elemento:"], explanation: "Il for su una lista dà direttamente ogni elemento: più corto e senza il rischio di sbagliare gli indici." },
  { topic: "condizioni", difficulty: 2, prompt: "Che cosa deve esserci alla fine della riga di un if?", answer: "I due punti", distractors: ["Il punto e virgola","Una parentesi graffa","Niente"], explanation: "I due punti annunciano il blocco che segue, e il blocco va rientrato." },
  { topic: "condizioni", difficulty: 3, prompt: "Quale parola indica cosa fare quando la condizione è falsa?", answer: "else", distractors: ["otherwise","elif","not"], explanation: "else copre tutti i casi in cui l'if non è verificato; elif serve a porre un'altra domanda." },
  { topic: "condizioni", difficulty: 3, prompt: "A che cosa serve elif?", answer: "A porre una seconda domanda se la prima è falsa", distractors: ["A ripetere il blocco finché è vero", "A chiudere il programma dopo il controllo", "A definire una funzione dentro l'if"], explanation: "elif significa «else if»: si usa quando i casi possibili sono più di due." },
  { topic: "condizioni", difficulty: 4, prompt: "x = 7\nif x > 10:\n    print('a')\nelif x > 5:\n    print('b')\nelse:\n    print('c')\n\nCosa stampa?", answer: "b", distractors: ["a","c","ab"], explanation: "La prima condizione è falsa, la seconda vera: si esegue quel ramo e si salta tutto il resto." },
  { topic: "condizioni", difficulty: 4, format: "numeric_input", prompt: "In una catena if / elif / else, quanti rami vengono eseguiti?", answer: "1", explanation: "Appena una condizione risulta vera si esegue quel ramo e la catena finisce lì." },
  { topic: "condizioni", difficulty: 3, prompt: "Come si scrive «x è fra 1 e 10»?", answer: "if 1 <= x <= 10:", distractors: ["if 1 <= x or x <= 10:","if x >= 1 and 10:","if x fra 1 e 10:"], explanation: "Python permette il confronto concatenato; l'alternativa corretta sarebbe x >= 1 and x <= 10." },
  { topic: "condizioni", difficulty: 4, prompt: "if punti > 100:\n    print('bravo')\nprint('fine')\n\nCon punti = 3, cosa stampa?", answer: "fine", distractors: ["bravo","bravo fine","niente"], explanation: "print('fine') non è rientrata: sta fuori dall'if e viene eseguita sempre." },
  { topic: "condizioni", difficulty: 2, prompt: "Che cosa valuta un if?", answer: "Una condizione vera o falsa", distractors: ["Un numero qualsiasi","Il nome di una variabile","Una stringa di testo"], explanation: "L'if decide in base a un valore booleano: se è vero esegue il blocco, altrimenti lo salta." },
  { topic: "condizioni", difficulty: 4, prompt: "Perché conviene mettere per prima la condizione più restrittiva in una catena if/elif?", answer: "Perché altrimenti un caso più generale la intercetta prima", distractors: ["Perché la catena viene eseguita più in fretta", "Perché Python richiede quest'ordine preciso", "Perché in quest'ordine si usa meno memoria"], explanation: "Se metti prima «x > 5», il caso «x > 10» non verrà mai raggiunto: l'ordine dei rami cambia il risultato." },
  { topic: "operatori", difficulty: 2, format: "numeric_input", prompt: "Quanto fa 7 // 2 in Python?", answer: "3", explanation: "// è la divisione intera: tiene la parte intera e scarta il resto." },
  { topic: "operatori", difficulty: 3, format: "numeric_input", prompt: "Quanto fa 7 % 2 in Python?", answer: "1", explanation: "% dà il resto: 7 diviso 2 fa 3 con resto 1. Serve spessissimo a capire se un numero è pari." },
  { topic: "operatori", difficulty: 3, prompt: "Come si verifica che un numero n sia pari?", answer: "n % 2 == 0", distractors: ["n / 2 == 0","n // 2 == 0","n * 2 == 0"], explanation: "Un numero è pari quando il resto della divisione per due è zero." },
  { topic: "operatori", difficulty: 4, format: "numeric_input", prompt: "Quanto fa 2 + 3 * 4 in Python?", answer: "14", explanation: "La moltiplicazione viene prima della somma, come in matematica: 3×4=12, poi +2." },
  { topic: "operatori", difficulty: 4, format: "numeric_input", prompt: "Quanto fa (2 + 3) * 4?", answer: "20", explanation: "Le parentesi cambiano l'ordine: prima la somma, poi la moltiplicazione." },
  { topic: "operatori", difficulty: 3, prompt: "Quale operatore unisce due stringhe?", answer: "+", distractors: ["&","*","."], explanation: "Fra stringhe + concatena. Fra numeri lo stesso simbolo somma: il significato dipende dai tipi." },
  { topic: "operatori", difficulty: 4, prompt: "Quanto fa 9 / 2 in Python?", answer: "4.5", distractors: ["4","5","4,5"], explanation: "/ restituisce sempre un float. Per la divisione intera si usa //." },
  { topic: "operatori", difficulty: 3, format: "numeric_input", prompt: "punti = 10\npunti -= 3\nprint(punti)\n\nCosa stampa?", answer: "7", explanation: "-= toglie al valore esistente, come += aggiunge: 10 − 3 = 7." },
  // --- densita': verso i 15 item per argomento (3 agosto 2026) ---
  { topic: "input", difficulty: 1, prompt: "Quale istruzione chiede un dato a chi usa il programma?", answer: "input()", distractors: ["print()","ask()","read()"], explanation: "input() ferma il programma, aspetta che l'utente scriva e restituisce quello che ha scritto." },
  { topic: "input", difficulty: 2, prompt: "nome = input('Come ti chiami? ')\n\nDove finisce quello che l'utente scrive?", answer: "Nella variabile nome", distractors: ["Direttamente a schermo","In un file sul disco","Da nessuna parte, va perso"], explanation: "input() restituisce un valore, e l'assegnazione lo mette dentro la variabile a sinistra dell'uguale." },
  { topic: "input", difficulty: 2, prompt: "Il testo scritto dentro input('...') a cosa serve?", answer: "A mostrare una domanda prima di leggere", distractors: ["A dare un nome alla variabile","A limitare quanto si può scrivere","A decidere il tipo del dato"], explanation: "È il messaggio che appare all'utente: senza, il programma sembrerebbe bloccato senza motivo." },
  { topic: "input", difficulty: 3, prompt: "n = input('Numero: ')\nprint(n + 1)\n\nCosa succede se l'utente scrive 5?", answer: "Un errore: non si somma testo e numero", distractors: ["Stampa 6, cioè cinque più uno", "Stampa 51, mettendo il testo in fila", "Stampa 5, ignorando la somma"], explanation: "input() restituisce sempre una stringa: '5' + 1 mette insieme testo e numero, e Python si ferma." },
  { topic: "input", difficulty: 3, prompt: "Come si trasforma in numero intero ciò che restituisce input()?", answer: "int(input('...'))", distractors: ["str(input('...'))","num(input('...'))","input(int('...'))"], explanation: "int() converte la stringa in numero intero. Va messo attorno a input(), non dentro." },
  { topic: "input", difficulty: 3, format: "numeric_input", prompt: "n = int(input('Numero: '))\nprint(n * 2)\n\nSe l'utente scrive 7, cosa stampa?", answer: "14", explanation: "int() trasforma '7' nel numero 7, e 7 × 2 fa 14. Senza int() avresti ottenuto '77'." },
  { topic: "input", difficulty: 2, format: "numeric_input", prompt: "a = input('Primo: ')\nb = input('Secondo: ')\n\nQuante volte il programma si ferma ad aspettare?", answer: "2", explanation: "Ogni input() aspetta una risposta: due input() significano due attese, una dopo l'altra." },
  { topic: "input", difficulty: 4, prompt: "Vuoi leggere un prezzo con la virgola, come 3.50. Quale conversione usi?", answer: "float(input('...'))", distractors: ["int(input('...'))","str(input('...'))","bool(input('...'))"], explanation: "int() accetta solo interi e su '3.50' darebbe errore; float() gestisce i numeri con la parte decimale." },
  { topic: "input", difficulty: 3, prompt: "eta = input('Età: ')\nif eta > 10:\n    print('grande')\n\nPerché questo programma dà errore?", answer: "Confronta una stringa con un numero", distractors: ["if non si usa con le variabili","Manca la parentesi in print","eta non è un nome valido"], explanation: "eta è testo, 10 è un numero: Python non sa dire se un testo è maggiore di un numero. Serve int()." },
  { topic: "input", difficulty: 4, format: "numeric_input", prompt: "Un programma chiede tre voti e ne fa la media. Quanti int(input()) servono?", answer: "3", explanation: "Un input per ogni voto, ciascuno convertito in numero: tre letture e poi la media." },
  { topic: "input", difficulty: 2, prompt: "risposta = input('Continuare? ')\n\nSe l'utente preme Invio senza scrivere niente, cosa contiene risposta?", answer: "Una stringa vuota", distractors: ["Il valore None","Uno zero","Un errore"], explanation: "Non aver scritto niente è comunque una risposta: input() restituisce '' (stringa vuota)." },
  { topic: "input", difficulty: 3, prompt: "Perché è meglio scrivere input('Nome: ') invece di input()?", answer: "Perché l'utente capisce cosa deve scrivere", distractors: ["Perché altrimenti Python dà errore","Perché il programma è più veloce","Perché la variabile prende un nome"], explanation: "Funzionano entrambi, ma senza messaggio l'utente vede un cursore che lampeggia e non sa cosa fare." },
  { topic: "input", difficulty: 4, format: "numeric_input", prompt: "n = int(input())\nprint(n + n)\n\nL'utente scrive 12. Cosa stampa?", answer: "24", explanation: "int() rende 12 un numero, quindi n + n è una somma: 24. Con le stringhe sarebbe stato '1212'." },
  { topic: "input", difficulty: 2, prompt: "In che ordine avvengono le cose in nome = input('Chi sei? ')?", answer: "Mostra la domanda, aspetta, poi assegna", distractors: ["Assegna, poi mostra la domanda","Mostra la domanda e assegna insieme","Aspetta, poi mostra la domanda"], explanation: "Prima appare il messaggio, poi il programma si ferma; solo quando l'utente ha scritto il valore finisce nella variabile." },
  { topic: "output", difficulty: 1, format: "numeric_input", prompt: "print('ciao')\nprint('mondo')\n\nSu quante righe appare il risultato?", answer: "2", explanation: "Ogni print() va a capo da solo: due print, due righe." },
  { topic: "output", difficulty: 2, prompt: "Cosa stampa: print('ciao', 'mondo')?", answer: "ciao mondo", distractors: ["ciaomondo","'ciao' 'mondo'","ciao,mondo"], explanation: "Separando con la virgola, print() mette automaticamente uno spazio fra i due valori." },
  { topic: "output", difficulty: 2, format: "numeric_input", prompt: "Cosa stampa: print(2 * 3)?", answer: "6", explanation: "Senza virgolette Python calcola prima e stampa il risultato: 2 × 3 = 6." },
  { topic: "output", difficulty: 2, prompt: "Cosa stampa: print('2 * 3')?", answer: "2 * 3", distractors: ["6","'2 * 3'","errore"], explanation: "Tra virgolette è testo: Python non calcola niente e stampa i caratteri così come sono." },
  { topic: "output", difficulty: 3, prompt: "x = 4\nprint('x')\n\nCosa stampa?", answer: "x", distractors: ["4","'x'","errore"], explanation: "'x' fra virgolette è la lettera x, non la variabile. Senza virgolette avrebbe stampato 4." },
  { topic: "output", difficulty: 3, prompt: "eta = 11\nprint('Ho', eta, 'anni')\n\nCosa stampa?", answer: "Ho 11 anni", distractors: ["Ho eta anni","Ho, 11, anni","Ho11anni"], explanation: "Le virgole separano i pezzi e print() li unisce con uno spazio, sostituendo il valore della variabile." },
  { topic: "output", difficulty: 3, prompt: "Cosa stampa: print(10 / 2)?", answer: "5.0", distractors: ["5","'5'","10/2"], explanation: "In Python la divisione / dà sempre un numero con la virgola, anche quando il risultato è esatto." },
  { topic: "output", difficulty: 4, format: "numeric_input", prompt: "Cosa stampa: print(10 // 3)?", answer: "3", explanation: "// è la divisione intera: tiene solo la parte intera del risultato e butta il resto." },
  { topic: "output", difficulty: 2, prompt: "Quale simbolo racchiude il testo da stampare?", answer: "Le virgolette", distractors: ["Le parentesi quadre","Le graffe","I due punti"], explanation: "Le virgolette (singole o doppie) dicono a Python che quello è testo e non un nome di variabile." },
  { topic: "output", difficulty: 3, prompt: "print('somma:', 3 + 4)\n\nCosa stampa?", answer: "somma: 7", distractors: ["somma: 3 + 4","somma:7","somma: 34"], explanation: "Il testo resta testo, ma 3 + 4 è fuori dalle virgolette: Python lo calcola prima di stampare." },
  { topic: "output", difficulty: 4, format: "numeric_input", prompt: "print('a')\nprint('b', end='')\nprint('c')\n\nQuante righe escono?", answer: "2", explanation: "end='' toglie l'a capo dopo 'b', quindi b e c finiscono sulla stessa riga: due righe in tutto." },
  { topic: "output", difficulty: 3, prompt: "Perché print(x) e print('x') danno risultati diversi?", answer: "Il primo stampa il valore, il secondo la lettera", distractors: ["Sono identici: cambia soltanto lo stile di scrittura", "Il secondo modo dà sempre un errore di sintassi", "Il primo modo funziona soltanto con i numeri"], explanation: "Le virgolette trasformano tutto in testo: senza, Python cerca una variabile con quel nome." },
  { topic: "stringhe", difficulty: 2, format: "numeric_input", prompt: "Quanti caratteri ha la stringa 'ciao'?", answer: "4", explanation: "len('ciao') vale 4: si contano tutte le lettere, spazi compresi quando ci sono." },
  { topic: "stringhe", difficulty: 2, prompt: "Quale funzione dice quanto è lunga una stringa?", answer: "len()", distractors: ["size()","count()","length()"], explanation: "len() restituisce il numero di caratteri. Funziona anche con le liste." },
  { topic: "stringhe", difficulty: 3, prompt: "s = 'python'\nprint(s[0])\n\nCosa stampa?", answer: "p", distractors: ["y","python","errore"], explanation: "Gli indici partono da zero: s[0] è il primo carattere, non il secondo." },
  { topic: "stringhe", difficulty: 3, prompt: "s = 'ciao'\nCon quale indice si prende l'ultima lettera?", answer: "s[-1]", distractors: ["s[4]","s[fine]","s[ultimo]"], explanation: "Gli indici negativi contano dalla fine: -1 è l'ultimo. s[4] darebbe errore, perché gli indici vanno da 0 a 3." },
  { topic: "stringhe", difficulty: 3, prompt: "Cosa stampa: print('ab' * 3)?", answer: "ababab", distractors: ["ab3","abababab","errore"], explanation: "Con una stringa e un numero, * ripete: 'ab' tre volte di fila." },
  { topic: "stringhe", difficulty: 2, prompt: "Cosa fa .upper() su una stringa?", answer: "La rende tutta maiuscola", distractors: ["La rende tutta minuscola","Ne conta i caratteri","La mette al contrario"], explanation: "'ciao'.upper() dà 'CIAO'. La stringa originale non cambia: .upper() ne restituisce una nuova." },
  { topic: "stringhe", difficulty: 4, prompt: "s = 'ciao'\ns.upper()\nprint(s)\n\nCosa stampa?", answer: "ciao", distractors: ["CIAO","Ciao","errore"], explanation: "Le stringhe non si modificano: .upper() restituisce una nuova stringa, e senza assegnarla il risultato si perde." },
  { topic: "stringhe", difficulty: 3, prompt: "Come si unisce nome = 'Eli' con ' Quest'?", answer: "nome + ' Quest'", distractors: ["nome & ' Quest'","nome . ' Quest'","nome, ' Quest'"], explanation: "Con le stringhe l'operatore + concatena, cioè attacca la seconda in coda alla prima." },
  { topic: "stringhe", difficulty: 4, format: "numeric_input", prompt: "Cosa stampa: print(len('Eli Quest'))?", answer: "9", explanation: "Si contano anche gli spazi: 3 + 1 + 5 fa 9 caratteri." },
  { topic: "stringhe", difficulty: 3, prompt: "Perché print('5' + '5') dà 55 e non 10?", answer: "Perché sono stringhe e + le unisce", distractors: ["Perché Python sbaglia le somme","Perché mancano le parentesi","Perché 5 non è un numero valido"], explanation: "Le virgolette rendono i due 5 testo: con il testo + significa «attacca», non «somma»." },
  { topic: "stringhe", difficulty: 4, prompt: "s = 'ciao'\nprint(s[1:3])\n\nCosa stampa?", answer: "ia", distractors: ["cia","iao","ci"], explanation: "s[1:3] prende dall'indice 1 fino a 3 escluso: i caratteri 1 e 2, cioè 'ia'." },
  { topic: "stringhe", difficulty: 2, prompt: "Quale scrittura è una stringa valida?", answer: "'ciao'", distractors: ["ciao","(ciao)","[ciao]"], explanation: "Serve una coppia di virgolette. Senza, Python cerca una variabile di nome ciao." },
  { topic: "algoritmi", difficulty: 1, prompt: "Perché una ricetta di cucina somiglia a un algoritmo?", answer: "Perché è una sequenza di passi precisi in ordine", distractors: ["Perché elenca gli ingredienti da usare", "Perché è stata scritta da una persona", "Perché seguendola ci si può sbagliare"], explanation: "Un algoritmo è fatto della stessa sostanza: passi definiti, in un ordine che conta, che portano a un risultato prevedibile." },
  { topic: "algoritmi", difficulty: 2, prompt: "In un algoritmo, cambiare l'ordine dei passi…", answer: "Può cambiare il risultato", distractors: ["Non cambia mai niente","Fa sempre errore","Rende il programma più veloce"], explanation: "Prima si versa il latte o prima i cereali? L'ordine conta: è il primo motivo per cui un programma non funziona." },
  { topic: "algoritmi", difficulty: 3, prompt: "Per trovare il numero più grande in una lista, quale idea funziona?", answer: "Tenere da parte il maggiore visto finora", distractors: ["Prendere sempre l'ultimo della lista", "Sommare tutti i numeri della lista", "Contare quanti numeri ci sono in tutto"], explanation: "Si scorre la lista una volta sola confrontando ogni numero con il record: alla fine il record è il massimo." },
  { topic: "algoritmi", difficulty: 3, prompt: "Cercare una parola in un dizionario di carta aprendo a metà è un esempio di…", answer: "Ricerca binaria", distractors: ["Ricerca a caso","Ordinamento","Conteggio"], explanation: "Ogni apertura scarta metà del dizionario: bastano pochi passi anche con migliaia di pagine." },
  { topic: "algoritmi", difficulty: 4, format: "numeric_input", prompt: "Con la ricerca binaria, quante volte si può dimezzare 16 prima di arrivare a 1?", answer: "4", explanation: "16 → 8 → 4 → 2 → 1: quattro dimezzamenti. È per questo che la ricerca binaria è così veloce." },
  { topic: "algoritmi", difficulty: 2, prompt: "Un algoritmo deve avere una fine. Come si chiama un ciclo che non finisce mai?", answer: "Ciclo infinito", distractors: ["Ciclo perfetto","Ciclo annidato","Ciclo vuoto"], explanation: "Se la condizione non diventa mai falsa il programma resta bloccato: è uno degli errori più comuni." },
  { topic: "algoritmi", difficulty: 3, prompt: "Che cosa vuol dire scomporre un problema?", answer: "Dividerlo in problemi più piccoli", distractors: ["Cancellarlo e ricominciare","Renderlo più difficile","Risolverlo a caso"], explanation: "Un problema grande diventa affrontabile quando si spezza in pezzi che si risolvono uno alla volta." },
  { topic: "algoritmi", difficulty: 3, prompt: "Per ordinare 5 carte in mano, l'idea più semplice è…", answer: "Inserire ogni carta al posto giusto fra quelle già ordinate", distractors: ["Mescolarle di nuovo finché non risultano in ordine", "Guardare soltanto la prima e l'ultima della mano", "Contare quante carte si hanno prima di cominciare"], explanation: "È l'ordinamento per inserimento: lo facciamo tutti con le carte senza sapere che ha un nome." },
  { topic: "algoritmi", difficulty: 4, format: "numeric_input", prompt: "Un algoritmo scorre una lista di 100 elementi una volta sola. Quanti confronti fa, all'incirca?", answer: "100", explanation: "Una passata sola significa un confronto per elemento: cento. Un algoritmo che confrontasse tutti con tutti ne farebbe diecimila." },
  { topic: "algoritmi", difficulty: 2, prompt: "Che cos'è lo pseudocodice?", answer: "Un algoritmo scritto in italiano, prima del codice vero", distractors: ["Un linguaggio inventato che nessun computer esegue", "Un programma pieno di errori da correggere", "Il codice scritto in modo disordinato e confuso"], explanation: "Serve a ragionare sui passi senza preoccuparsi della grammatica del linguaggio: si traduce dopo." },
  { topic: "algoritmi", difficulty: 3, prompt: "Due algoritmi risolvono lo stesso problema. Come si sceglie il migliore?", answer: "Si guarda quanti passi fa al crescere dei dati", distractors: ["Si sceglie quello più corto da scrivere","Si sceglie quello con più variabili","Sono sempre equivalenti"], explanation: "Con dieci dati la differenza non si vede; con un milione uno finisce in un secondo e l'altro non finisce." },
  { topic: "algoritmi", difficulty: 4, prompt: "Perché un algoritmo deve essere preciso e senza ambiguità?", answer: "Perché il computer non può intuire cosa intendevi", distractors: ["Perché altrimenti viene eseguito più lentamente", "Perché un algoritmo vago occupa più memoria", "Perché è il linguaggio Python a richiederlo"], explanation: "Una persona capisce «aggiungi un po' di sale»; un computer no. Ogni passo deve avere un solo significato possibile." },
  // Output
  { topic: "output", difficulty: 1, prompt: "In Python, quale istruzione mostra un messaggio a schermo?", answer: "print()", distractors: ["show()", "echo()", "display()"], explanation: "print() stampa a schermo ciò che gli passi." },
  { topic: "output", difficulty: 2, prompt: "Cosa stampa: print(3 + 4)?", answer: "7", distractors: ["34", "3 + 4", "'7'"], explanation: "Con i numeri, + è la somma: 3 + 4 = 7." },
  { topic: "output", difficulty: 3, prompt: "Cosa stampa: print('3' + '4')?", answer: "34", distractors: ["7", "'34'", "errore"], explanation: "Con le stringhe, + le unisce (concatenazione): '3'+'4' = '34'." },
  // Variabili
  { topic: "variabili", difficulty: 1, prompt: "In x = 5, che cos'è x?", answer: "Una variabile che vale 5", distractors: ["Una funzione senza nome", "Un errore di scrittura", "Un testo fisso tra virgolette"], explanation: "Una variabile è un contenitore con un nome e un valore." },
  { topic: "variabili", difficulty: 2, prompt: "Dopo x = 5 e poi x = x + 1, quanto vale x?", answer: "6", distractors: ["5", "51", "errore"], explanation: "x + 1 = 5 + 1 = 6, e viene rimesso in x." },
  // Tipi di dato
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è il valore 'ciao'?", answer: "Stringa (testo)", distractors: ["Numero intero", "Booleano", "Lista"], explanation: "Il testo tra virgolette è una stringa." },
  { topic: "tipi", difficulty: 2, prompt: "Di che tipo è il valore 7?", answer: "Numero intero (int)", distractors: ["Stringa di testo", "Booleano (vero/falso)", "Lista di valori"], explanation: "7 senza virgolette è un numero intero." },
  // Operatori
  { topic: "operatori", difficulty: 2, prompt: "Cosa calcola 10 % 3 in Python (operatore modulo)?", answer: "1 (il resto)", distractors: ["3 (il quoziente)", "30 (il prodotto)", "3.33 (la divisione)"], explanation: "% dà il resto della divisione: 10 = 3×3 + 1." },
  { topic: "operatori", difficulty: 3, prompt: "Cosa calcola 2 ** 3 in Python?", answer: "8", distractors: ["6", "9", "5"], explanation: "** è l'elevamento a potenza: 2 alla 3 = 8." },
  // Condizioni
  { topic: "condizioni", difficulty: 2, prompt: "Quale parola introduce una condizione in Python?", answer: "if", distractors: ["for", "while", "def"], explanation: "if verifica una condizione ed esegue il blocco se è vera." },
  { topic: "condizioni", difficulty: 3, prompt: "Con x = 4, cosa stampa: if x > 3: print('grande')?", answer: "grande", distractors: ["4", "niente", "errore"], explanation: "4 > 3 è vero, quindi esegue print('grande')." },
  { topic: "condizioni", difficulty: 3, prompt: "Quale operatore verifica se due valori sono uguali?", answer: "==", distractors: ["=", "=>", "><"], explanation: "= assegna un valore; == confronta due valori." },
  // Cicli
  { topic: "cicli", difficulty: 2, prompt: "Quale istruzione ripete del codice più volte?", answer: "for (oppure while)", distractors: ["if (oppure else)", "def (oppure return)", "print (oppure input)"], explanation: "I cicli for e while ripetono un blocco di istruzioni." },
  { topic: "cicli", difficulty: 3, prompt: "Quante volte stampa: for i in range(3): print(i)?", answer: "3 volte (0, 1, 2)", distractors: ["1 volta", "3 volte (1, 2, 3)", "4 volte"], explanation: "range(3) genera 0, 1, 2: tre ripetizioni." },
  // Liste
  { topic: "liste", difficulty: 2, prompt: "Come si scrive in Python una lista con tre numeri?", answer: "[1, 2, 3]", distractors: ["(1 2 3)", "{1;2;3}", "<1,2,3>"], explanation: "Le liste si scrivono tra parentesi quadre, con virgole." },
  { topic: "liste", difficulty: 3, prompt: "Data lista = [10, 20, 30], cosa vale lista[0]?", answer: "10", distractors: ["20", "30", "1"], explanation: "Gli indici partono da 0: lista[0] è il primo elemento." },
  // Funzioni
  { topic: "funzioni", difficulty: 3, prompt: "Quale parola chiave definisce una funzione in Python?", answer: "def", distractors: ["func", "function", "let"], explanation: "def introduce la definizione di una funzione." },
  { topic: "funzioni", difficulty: 4, prompt: "A cosa serve soprattutto una funzione?", answer: "A riusare un blocco di codice dandogli un nome", distractors: ["A colorare il testo del programma", "A spegnere il computer da solo", "A creare di proposito errori nel codice"], explanation: "Le funzioni evitano di ripetere lo stesso codice." },
  // Booleani
  { topic: "booleani", difficulty: 2, prompt: "Quali sono i due valori booleani in Python?", answer: "True e False", distractors: ["1 e 2", "Sì e No", "On e Off"], explanation: "Un booleano può essere solo True (vero) o False (falso)." },
  { topic: "booleani", difficulty: 3, prompt: "Cosa vale l'espressione 5 > 3 in Python?", answer: "True", distractors: ["False", "5", "errore"], explanation: "5 è maggiore di 3, quindi il confronto è True." },
  // Pensiero computazionale
  { topic: "algoritmi", difficulty: 1, prompt: "Che cos'è un algoritmo?", answer: "Una sequenza di passi per risolvere un problema", distractors: ["Un tipo di computer molto potente", "Un linguaggio di programmazione nuovo", "Un errore che blocca il programma"], explanation: "L'algoritmo descrive i passi, come una ricetta." },
  { topic: "algoritmi", difficulty: 2, prompt: "Cosa significa 'bug' in programmazione?", answer: "Un errore nel programma", distractors: ["Un tipo di dato nuovo", "Un comando molto utile", "Una funzione di sistema"], explanation: "Un bug è un difetto che fa comportare male il programma." },
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
    example: { prompt: "Onda con lambda = 2 m e f = 3 Hz.", why: "La velocità di un'onda è quanto è lunga ogni oscillazione per quante ne passano ogni secondo.", steps: ["v = lambda x f", "2 x 3 = 6"], answer: "6 m/s" },
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
    example: { prompt: "Massa 200 g, volume 100 cm3. Trova la densità.", why: "La densità dice quanta materia sta in ogni centimetro cubo, e non cambia se tagli l'oggetto a metà.", steps: ["densità = massa / volume", "200 / 100", "2 g/cm3"], answer: "2 g/cm3" },
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

// Distrattori della teoria: prima quelli della STESSA area (quasi-corretti, il
// bambino deve distinguere calore da temperatura, non fisica da musica), poi —
// solo se l'area non ne offre tre — il resto della materia. Con il pool globale
// le alternative venivano da argomenti lontani ("2 g/cm3" sotto una domanda di
// equilibrio) e si escludevano a colpo d'occhio, senza sapere la risposta.
function nearestFirst(all, sameArea, answer, rand) {
  const near = sameArea.filter((v) => v !== answer);
  return new Set(near).size >= 3 ? pickDistractors(near, answer, 3, rand) : pickDistractors(all, answer, 3, rand);
}

// Parole troppo comuni per identificare un argomento: non devono far scartare un
// distrattore altrimenti resteremmo senza.
const TOPIC_STOPWORDS = new Set([
  "della", "delle", "degli", "dello", "dalla", "dalle", "nella", "nelle", "alla", "alle", "agli",
  "come", "sono", "essere", "ogni", "quando", "perche", "anche", "questo", "questa", "quello",
  "quella", "altro", "altra", "cioe", "oltre", "senza", "sopra", "sotto", "dentro", "fuori",
  "prima", "dopo", "molto", "tutto", "tutti", "tutte", "cosa", "deve", "indica", "usare",
]);

// Radice grossolana di quattro lettere: basta a far combaciare intervalli con
// intervallo, durate con durata, forze con forza — che è tutto ciò che serve qui.
const DEACCENT = { "à": "a", "è": "e", "é": "e", "ì": "i", "ò": "o", "ù": "u" };

const topicStems = (text) =>
  new Set(
    String(text)
      .toLowerCase()
      .replace(/[àèéìòù]/g, (c) => DEACCENT[c])
      .split(/[^a-z]+/)
      .filter((w) => w.length >= 4 && !TOPIC_STOPWORDS.has(w))
      .map((w) => w.slice(0, 4)),
  );

/**
 * Distrattori che NON parlano dell'argomento chiesto.
 *
 * `nearestFirst` fa l'opposto: pesca dagli argomenti più VICINI. Per un esempio
 * concreto è giusto — costringe a distinguere davvero. Per una definizione è il
 * modo più veloce di costruire una domanda con due risposte giuste: al 3 agosto
 * 2026 «Qual è la definizione corretta di *Ritmo e intervalli*?» aveva fra i
 * distrattori «Un intervallo è la distanza tra due note…», che è vero e parla
 * proprio di intervalli. Stessa cosa per *Intervalli e scale*.
 *
 * Qui un candidato viene scartato se condivide anche una sola radice con il
 * titolo chiesto. Se così restano meno di tre distrattori, l'item non si
 * costruisce: vuol dire che quell'argomento si sovrappone troppo agli altri per
 * essere chiesto in questa forma, ed è meglio una domanda in meno che una
 * domanda con due risposte.
 */
/**
 * Due testi che dicono la stessa cosa con parole quasi uguali.
 *
 * Il catalogo di teoria contiene avvertenze ripetute quasi alla lettera fra
 * argomenti diversi: «Una croma vale mezzo battito, non uno» e «La croma vale
 * mezzo battito, non uno» differiscono per l'articolo. Come distrattore l'una
 * dell'altra sono due risposte giuste, e la differenza è invisibile a un
 * bambino perché non c'è.
 *
 * Confronto sulle radici e non sulle stringhe, altrimenti l'articolo basta a
 * far passare il duplicato.
 *
 * Soglie tarate su un falso positivo vero: «biglietto di andata e ritorno» e
 * «biglietto di sola andata» condividono due radici su tre, ma sono l'opposto
 * l'una dell'altra e sono anzi un'ottima coppia di distrattori. Servono quindi
 * almeno QUATTRO radici — sotto è una locuzione, non una frase — e una
 * sovrapposizione quasi totale.
 */
function tooSimilar(a, b) {
  const sa = topicStems(a);
  const sb = topicStems(b);
  if (sa.size < 4 || sb.size < 4) return false;
  const shared = [...sa].filter((stem) => sb.has(stem)).length;
  return shared / Math.max(sa.size, sb.size) >= 0.8;
}

function otherTopicDistractors(candidates, title, answer, rand) {
  const asked = topicStems(title);
  const overlaps = (text) => [...topicStems(text)].some((stem) => asked.has(stem));
  const pool = candidates
    // Due filtri, non uno. Il testo del candidato non deve nominare il concetto
    // chiesto — ma non basta: l'errore «Conta includendo la nota di partenza,
    // non da zero» non contiene la parola *intervallo* e resta comunque la
    // risposta giusta per «Ritmo e intervalli», perché appartiene ad «Intervalli
    // e scale». Quindi si scarta anche in base al TITOLO dell'argomento a cui il
    // candidato appartiene: è la sovrapposizione fra argomenti a creare due
    // risposte giuste, non la ripetizione di una parola.
    .filter(
      ({ value, owner }) =>
        value !== answer && !tooSimilar(value, answer) && !overlaps(value) && !overlaps(owner),
    )
    .map(({ value }) => value);
  return pickDistractors(pool, answer, 3, rand);
}

function curatedTheoryBank(subject, topics, seed) {
  const rand = rng(seed);
  const areaOf = (t) => THEORY_TOPIC[t.id] ?? t.area;
  const exampleAnswers = topics.map((t) => t.example.answer);
  // Ogni candidato porta con sé l'argomento da cui viene: serve a scartare i
  // distrattori che appartengono a un argomento sovrapposto a quello chiesto.
  const definitionCandidates = topics.map((t) => ({ value: t.definition, owner: t.title }));
  const watchOutCandidates = topics.map((t) => ({ value: t.watchOut[0], owner: t.title }));
  const items = [];
  for (const topic of topics) {
    const canonTopic = areaOf(topic);
    const sameArea = topics.filter((t) => areaOf(t) === canonTopic);
    const difficulty = Math.min(4, Math.max(1, Math.round(((topic.levelRange[0] + topic.levelRange[1]) / 2) / 2)));
    // La domanda nomina il CONCETTO, non il titolo del capitolo. «Qual è la
    // definizione corretta di "Calore e temperatura"?» non è una domanda di
    // fisica: è ricordarsi quale paragrafo portava quale intestazione, e un
    // bambino non ha modo di ragionarci. «Quale affermazione descrive
    // correttamente il calore e la temperatura?» sì.
    const defDistractors = otherTopicDistractors(definitionCandidates, topic.title, topic.definition, rand);
    if (defDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `${topic.id}-definizione`,
            subject,
            topic: canonTopic,
            difficulty,
            prompt: `Quale affermazione descrive correttamente «${topic.title.toLocaleLowerCase("it")}»?`,
            answer: topic.definition,
            distractors: defDistractors,
            // Ripetere la definizione non spiega niente a chi ha sbagliato. La
            // cosa utile è dirgli DOVE stava la trappola: le altre affermazioni
            // sono vere, ma parlano d'altro.
            explanation: `${topic.definition} Le altre affermazioni sono vere, ma descrivono un altro argomento.`,
          },
          rand,
        ),
      );
    }
    const exDistractors = nearestFirst(exampleAnswers, sameArea.map((t) => t.example.answer), topic.example.answer, rand);
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
            // I passi soli mostrano il calcolo e tacciono la regola: chi non
            // sapeva la formula rilegge dei numeri. `why`, quando c'è, dice a
            // parole che cosa lega le grandezze — ed è la parte che resta
            // quando i numeri dell'esercizio sono cambiati.
            explanation: (topic.example.why ? topic.example.why + " " : "")
              + topic.example.steps.join(" → ") + ".",
          },
          rand,
        ),
      );
    }
    const watchDistractors = otherTopicDistractors(watchOutCandidates, topic.title, topic.watchOut[0], rand);
    if (watchDistractors.length === 3) {
      items.push(
        multipleChoiceItem(
          {
            id: `${topic.id}-attenzione`,
            subject,
            topic: canonTopic,
            difficulty: Math.min(4, difficulty + 1),
            prompt: `Lavorando su «${topic.title.toLocaleLowerCase("it")}», quale errore bisogna evitare?`,
            answer: topic.watchOut[0],
            distractors: watchDistractors,
            // Tutte e quattro le opzioni sono errori VERI: la prova è capire a
            // quale argomento appartiene ciascuno. Ripetere la risposta non
            // aiuterebbe chi ha sbagliato proprio quello.
            explanation: `${topic.watchOut[0]} Anche le altre sono avvertenze giuste, ma riguardano un altro argomento.`,
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
// Un item autorato. Con `format: "numeric_input"` diventa a risposta libera
// invece che a scelta multipla: serve alla decisione del 3 agosto (ogni banco al
// 20-30% di non-scelta-multipla), perche' una domanda a quattro opzioni si
// risolve per esclusione senza sapere niente. La risposta libera e' digitabile
// anche su tablet da quando esiste il tastierino numerico.
function authoredMcItems(subject, questions, rand) {
  return questions.map((q, i) => {
    const id = `${subject}-${q.topic}-${i}`;
    if (q.format === "short_answer") {
      // Risposta libera a testo. `accept` elenca le forme che valgono quanto
      // la risposta principale: senza, un bambino che scrive «to check»
      // invece di «check» viene segnato sbagliato pur avendo capito.
      return { id, subject, topic: q.topic, difficulty: q.difficulty,
        format: "short_answer", prompt: q.prompt, options: [],
        answer: String(q.answer), accept: q.accept ?? [],
        explanation: q.explanation };
    }
    if (q.format === "numeric_input") {
      return {
        id,
        subject,
        topic: q.topic,
        difficulty: q.difficulty,
        format: "numeric_input",
        prompt: q.prompt,
        options: [],
        answer: String(q.answer),
        explanation: q.explanation,
      };
    }
    return multipleChoiceItem({ id, subject, topic: q.topic, difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand);
  });
}

const FISICA_EXTRA = [
  { topic: "misure", difficulty: 3, format: "numeric_input", prompt: "Quanti millimetri sono 3 centimetri?", answer: "30", explanation: "Un centimetro vale dieci millimetri: 3 × 10 fa 30." },
  { topic: "misure", difficulty: 3, prompt: "Con quale strumento si misura un intervallo di tempo breve?", answer: "Il cronometro", distractors: ["Il termometro da parete","La bilancia da cucina","Il metro a nastro"], explanation: "Il cronometro misura durate; l'orologio dice che ora è, che è una cosa diversa." },
  { topic: "misure", difficulty: 4, prompt: "Perché si scrive «12,4 cm» e non «12,4372 cm» con un righello?", answer: "Perché lo strumento non arriva a quella precisione", distractors: ["Perché i numeri lunghi sono scomodi","Perché i decimali non si usano in fisica","Perché il righello misura solo interi"], explanation: "Scrivere più cifre di quelle che lo strumento può garantire non aggiunge precisione: la finge." },
  { topic: "moto", difficulty: 3, format: "numeric_input", prompt: "Un ciclista percorre 20 km in 1 ora. Qual è la sua velocità media?", answer: "20", explanation: "Velocità media = spazio diviso tempo: 20 km in 1 ora fanno 20 km/h." },
  { topic: "moto", difficulty: 4, prompt: "Che cosa significa che un corpo accelera?", answer: "Che la sua velocità sta cambiando", distractors: ["Che si muove molto velocemente","Che percorre una lunga distanza","Che si muove sempre in avanti"], explanation: "Anche frenare è accelerare, in fisica: l'accelerazione è qualsiasi variazione di velocità, in più o in meno." },
  { topic: "moto", difficulty: 4, prompt: "Un'auto che curva a velocità costante sta accelerando?", answer: "Sì, perché cambia direzione", distractors: ["No, perché la velocità non cambia","No, perché non preme sul gas","Sì, ma solo se aumenta il motore"], explanation: "La velocità in fisica ha un valore e una direzione: cambiarne una sola basta a parlare di accelerazione." },
  { topic: "forze", difficulty: 3, prompt: "In quale unità si misura una forza?", answer: "Newton", distractors: ["Joule","Watt","Pascal"], explanation: "Il joule misura l'energia, il watt la potenza, il pascal la pressione." },
  { topic: "forze", difficulty: 4, prompt: "Che cosa succede a un corpo su cui non agisce nessuna forza?", answer: "Resta fermo o continua a muoversi uguale", distractors: ["Si ferma sempre dopo un poco di tempo","Comincia lentamente a cadere verso il basso","Cambia direzione da solo senza motivo"], explanation: "È il principio d'inerzia: senza forze non c'è motivo di cambiare. Sulla Terra però l'attrito c'è quasi sempre." },
  { topic: "forze", difficulty: 3, prompt: "Che cos'è la pressione?", answer: "La forza distribuita su una superficie", distractors: ["La forza totale applicata a un corpo","Il peso di un oggetto molto pesante","La spinta esercitata da un liquido"], explanation: "La stessa forza su una punta o su un palmo dà pressioni diversissime: per questo un ago buca e un dito no." },
  { topic: "forze", difficulty: 4, prompt: "Perché camminando sulla neve con le racchette non si sprofonda?", answer: "Perché il peso si distribuisce su più superficie", distractors: ["Perché le racchette pesano meno degli scarponi","Perché la neve si indurisce sotto le racchette","Perché con le racchette si cammina più lentamente"], explanation: "Il peso resta lo stesso, ma la pressione cala: forza uguale distribuita su un'area maggiore." },
  { topic: "forze", difficulty: 3, prompt: "Due forze uguali e opposte applicate a un corpo fermo…", answer: "Si bilanciano e il corpo resta fermo", distractors: ["Lo fanno muovere in avanti","Lo fanno girare su sé stesso","Raddoppiano il suo peso"], explanation: "La somma delle forze è zero: è quello che succede a un libro appoggiato sul tavolo." },
  { topic: "metodo", difficulty: 2, prompt: "Che cos'è una grandezza fisica?", answer: "Qualcosa che si può misurare con un numero", distractors: ["Qualsiasi proprietà di un oggetto","La dimensione di un corpo solido","Un fenomeno che si può osservare"], explanation: "La bellezza non è una grandezza fisica; la lunghezza sì, perché si può associare a un numero e a un'unità." },
  { topic: "metodo", difficulty: 3, prompt: "Che cos'è un'unità di misura?", answer: "Una quantità di riferimento con cui si confronta", distractors: ["Lo strumento con cui si esegue la misura","Il numero che esce dalla misurazione fatta","La precisione dello strumento che si è usato"], explanation: "Dire «lungo 3» non significa niente: serve dire 3 di che cosa, cioè rispetto a quale campione." },
  { topic: "metodo", difficulty: 3, prompt: "Perché una misura ha sempre un'incertezza?", answer: "Perché nessuno strumento è infinitamente preciso", distractors: ["Perché chi misura è quasi sempre distratto","Perché le grandezze cambiano valore da sole","Perché i calcoli finali sono approssimati"], explanation: "Anche lo strumento migliore ha una risoluzione: sotto quella soglia non può dire niente." },
  { topic: "metodo", difficulty: 3, prompt: "Che cos'è la sensibilità di uno strumento?", answer: "La più piccola variazione che riesce a rilevare", distractors: ["Il valore massimo che lo strumento può misurare","La velocità con cui restituisce il risultato","La cura con cui lo strumento va maneggiato"], explanation: "Un righello con tacche al millimetro non può distinguere due lunghezze che differiscono di un decimo." },
  { topic: "metodo", difficulty: 4, prompt: "Che differenza c'è fra errore casuale e errore sistematico?", answer: "Il casuale varia, il sistematico è sempre nello stesso verso", distractors: ["L'errore casuale è sempre più grande di quello sistematico","L'errore sistematico si corregge ripetendo più volte la misura","L'errore casuale dipende soltanto dallo strumento usato"], explanation: "Ripetere le misure riduce gli errori casuali ma non tocca quelli sistematici: una bilancia tarata male sbaglia sempre uguale." },
  { topic: "metodo", difficulty: 3, prompt: "Perché in fisica si usa il Sistema Internazionale?", answer: "Perché tutti misurino con gli stessi riferimenti", distractors: ["Perché è il sistema di misura più antico","Perché permette di usare numeri più piccoli","Perché è reso obbligatorio da una legge"], explanation: "Senza unità condivise i risultati non si possono confrontare: una sonda spaziale si è persa proprio per questo." },
  { topic: "metodo", difficulty: 2, prompt: "Qual è l'unità di misura della lunghezza nel Sistema Internazionale?", answer: "Il metro", distractors: ["Il centimetro","Il chilometro","Il pollice"], explanation: "Centimetro e chilometro sono multipli e sottomultipli del metro, che è l'unità fondamentale." },
  { topic: "metodo", difficulty: 3, prompt: "Che cos'è un modello in fisica?", answer: "Una rappresentazione semplificata della realtà", distractors: ["Un esperimento riuscito perfettamente","Un oggetto costruito in scala ridotta","Una legge dimostrata definitivamente"], explanation: "Si trascurano i dettagli irrilevanti per capire l'essenziale: un modello utile non è un modello completo." },
  { topic: "metodo", difficulty: 4, prompt: "Perché in fisica si dice che una teoria non è mai «dimostrata per sempre»?", answer: "Perché un nuovo esperimento potrebbe smentirla", distractors: ["Perché i fisici non sono mai d'accordo","Perché le teorie sono solo opinioni","Perché mancano sempre gli strumenti"], explanation: "Le teorie si tengono finché reggono alle prove: la meccanica di Newton funziona benissimo, ma non alle alte velocità." },
  { topic: "metodo", difficulty: 4, format: "numeric_input", prompt: "Misuri un tavolo tre volte: 120,1 · 120,3 · 120,2 cm. Qual è la stima migliore?", answer: "120,2", explanation: "La media delle tre misure: (120,1 + 120,3 + 120,2) diviso 3 fa 120,2 cm." },
  { topic: "onde-luce", difficulty: 2, prompt: "Che cosa serve al suono per propagarsi?", answer: "Un mezzo materiale come l'aria", distractors: ["Soltanto una fonte abbastanza forte","Il vuoto assoluto senza ostacoli","Una superficie che rifletta bene"], explanation: "Nel vuoto il suono non viaggia: servono particelle che si urtino trasmettendo la vibrazione." },
  { topic: "onde-luce", difficulty: 3, prompt: "La luce può viaggiare nel vuoto?", answer: "Sì, non le serve un mezzo materiale", distractors: ["No, le serve sempre l'aria","Solo se è molto intensa","Solo se proviene da una stella"], explanation: "È un'onda elettromagnetica: per questo la luce del Sole arriva fin qui attraversando lo spazio vuoto." },
  { topic: "onde-luce", difficulty: 3, prompt: "Perché un bastone immerso nell'acqua sembra spezzato?", answer: "Perché la luce cambia direzione passando fra aria e acqua", distractors: ["Perché l'acqua ingrandisce gli oggetti immersi","Perché il bastone si piega davvero nell'acqua","Perché l'acqua riflette la luce verso l'alto"], explanation: "È la rifrazione: la luce rallenta entrando nell'acqua e devia, e i nostri occhi la interpretano come una linea spezzata." },
  { topic: "onde-luce", difficulty: 3, prompt: "Che cos'è l'eco?", answer: "Il suono che torna dopo essersi riflesso", distractors: ["Un suono che si ripete da solo","Un suono più acuto dell'originale","Il rumore prodotto dal vento"], explanation: "Serve una superficie abbastanza lontana: se torna troppo presto il nostro orecchio non lo distingue dal suono diretto." },
  { topic: "onde-luce", difficulty: 4, prompt: "Perché vediamo un oggetto rosso?", answer: "Perché riflette il rosso e assorbe gli altri colori", distractors: ["Perché produce luce rossa per conto proprio","Perché assorbe il rosso e riflette il resto","Perché è fatto di un materiale rosso dentro"], explanation: "Il colore non sta nell'oggetto: sta in quali lunghezze d'onda rimanda ai nostri occhi." },
  { topic: "onde-luce", difficulty: 3, prompt: "Che cos'è un'ombra?", answer: "La zona dove la luce non arriva perché bloccata", distractors: ["Una macchia scura disegnata sul terreno","Il riflesso scuro proiettato da un oggetto","Una zona in cui l'aria è più fredda"], explanation: "La luce viaggia in linea retta: un corpo opaco le impedisce di raggiungere ciò che sta dietro." },
  { topic: "onde-luce", difficulty: 4, prompt: "Perché un prisma scompone la luce bianca nei colori?", answer: "Perché ogni colore devia in modo un po' diverso", distractors: ["Perché il vetro aggiunge dei colori alla luce","Perché la luce si scalda mentre attraversa il vetro","Perché il prisma riflette la luce molte volte"], explanation: "La luce bianca è la somma di tutti i colori, e ciascuno viene rifratto con un angolo leggermente diverso." },
  { topic: "onde-luce", difficulty: 3, prompt: "Che cosa determina se un suono è acuto o grave?", answer: "La frequenza della vibrazione", distractors: ["L'intensità della vibrazione","La distanza dalla sorgente","Il materiale che vibra"], explanation: "Più vibrazioni al secondo, più il suono è acuto. L'intensità decide invece se è forte o debole." },
  { topic: "onde-luce", difficulty: 4, format: "numeric_input", prompt: "Un lampo si vede subito e il tuono arriva dopo 3 secondi. Quanti chilometri circa?", answer: "1", explanation: "Il suono percorre circa 340 metri al secondo: in 3 secondi fa poco più di un chilometro." },
  { topic: "energia", difficulty: 3, prompt: "Che cos'è il lavoro in fisica?", answer: "L'effetto di una forza che sposta qualcosa", distractors: ["Lo sforzo compiuto da una persona","Il tempo impiegato a fare una cosa","La fatica percepita durante lo sforzo"], explanation: "Se spingi un muro e non si muove, in fisica non hai compiuto lavoro, per quanto tu sia stanco." },
  { topic: "energia", difficulty: 3, prompt: "Che cos'è la potenza?", answer: "L'energia impiegata in un certo tempo", distractors: ["La forza applicata a un oggetto","L'energia totale disponibile","La velocità di un corpo in moto"], explanation: "Fare lo stesso lavoro in metà tempo richiede il doppio della potenza." },
  { topic: "energia", difficulty: 3, prompt: "Da che cosa dipende l'energia potenziale di un corpo sollevato?", answer: "Dalla sua massa e dall'altezza", distractors: ["Dalla sua velocità e dalla forma","Dal materiale di cui è fatto","Dal tempo che resta sollevato"], explanation: "Più è pesante e più è in alto, più energia restituirà cadendo." },
  { topic: "energia", difficulty: 4, prompt: "Perché una macchina a moto perpetuo è impossibile?", answer: "Perché parte dell'energia si disperde sempre", distractors: ["Perché nessuno l'ha ancora costruita","Perché servirebbero materiali troppo cari","Perché la gravità la fermerebbe"], explanation: "Attriti e resistenze trasformano energia utile in calore disperso: la macchina rallenta e si ferma." },
  { topic: "energia", difficulty: 3, prompt: "In quale unità si misura l'energia?", answer: "Joule", distractors: ["Newton","Watt","Pascal"], explanation: "Il newton misura le forze, il watt la potenza, il pascal la pressione." },
  { topic: "energia", difficulty: 4, prompt: "Un'altalena che oscilla trasforma continuamente…", answer: "Energia potenziale in cinetica e viceversa", distractors: ["Energia chimica in energia elettrica","Energia termica in energia luminosa","Energia cinetica in energia sonora"], explanation: "In alto è ferma e ha il massimo di potenziale; in basso è velocissima e ha il massimo di cinetica." },
  { topic: "energia", difficulty: 3, prompt: "Perché serve energia per far muovere un'auto a velocità costante?", answer: "Per vincere attriti e resistenza dell'aria", distractors: ["Perché la velocità costante consuma di più","Perché l'auto deve accelerare di continuo","Perché la gravità la rallenta sempre"], explanation: "Senza attriti basterebbe una spinta iniziale: il motore serve a compensare ciò che si perde." },
  { topic: "energia", difficulty: 4, prompt: "Che cosa significa che un'energia è «rinnovabile»?", answer: "La fonte si rigenera in tempi brevi", distractors: ["L'energia non si consuma mai","L'energia si può riutilizzare due volte","La fonte non costa niente"], explanation: "Non è l'energia a rinnovarsi — quella si degrada comunque — ma la fonte da cui si preleva." },
  { topic: "energia", difficulty: 4, prompt: "Un corpo di 2 kg sollevato a 5 metri: se raddoppi l'altezza, l'energia potenziale…", answer: "Raddoppia", distractors: ["Resta uguale","Si dimezza","Diventa quattro volte"], explanation: "L'energia potenziale è proporzionale all'altezza: raddoppiando una, raddoppia l'altra." },
  { topic: "materia", difficulty: 3, prompt: "Che cos'è la massa di un corpo?", answer: "La quantità di materia che contiene", distractors: ["La forza con cui viene attratto","Lo spazio che occupa","Il suo peso sulla Terra"], explanation: "La massa non cambia spostandosi sulla Luna; il peso sì, perché dipende dalla gravità del luogo." },
  { topic: "materia", difficulty: 3, prompt: "Qual è la differenza fra massa e peso?", answer: "Il peso è la forza con cui la gravità attrae la massa", distractors: ["Sono sinonimi, cambia solo l'unità","La massa si misura solo con la bilancia","Il peso non cambia mai da un luogo all'altro"], explanation: "La massa si misura in chilogrammi, il peso in newton: sulla Luna la massa resta, il peso diventa un sesto." },
  { topic: "materia", difficulty: 3, prompt: "Che cos'è la densità?", answer: "La massa contenuta in un certo volume", distractors: ["Il peso totale di un oggetto","La durezza del materiale","Lo spessore di un corpo solido"], explanation: "Il ferro è più denso del legno: a parità di volume contiene più materia, quindi pesa di più." },
  { topic: "materia", difficulty: 4, prompt: "Perché una nave d'acciaio galleggia mentre un chiodo affonda?", answer: "Perché la nave contiene molta aria e la sua densità media è bassa", distractors: ["Perché la nave è molto più grande del chiodo","Perché l'acciaio della nave è di un tipo diverso","Perché l'acqua del mare è più salata del previsto"], explanation: "Conta la densità media del corpo intero, non del materiale: una nave è per lo più aria." },
  { topic: "materia", difficulty: 3, prompt: "Che cos'è il volume di un corpo?", answer: "Lo spazio che occupa", distractors: ["La quantità di materia che contiene","Il suo peso in chilogrammi","La sua altezza massima"], explanation: "Due corpi possono avere lo stesso volume e masse molto diverse: dipende da che cosa sono fatti." },
  { topic: "materia", difficulty: 4, prompt: "Che cosa succede al volume di un gas se lo comprimi?", answer: "Diminuisce, perché le particelle si avvicinano", distractors: ["Resta uguale, il gas non si comprime","Aumenta, perché il gas si scalda","Si annulla completamente"], explanation: "Nei gas le particelle sono molto distanti: c'è spazio per avvicinarle. Nei liquidi e nei solidi quasi no." },
  { topic: "materia", difficulty: 4, prompt: "Perché l'olio galleggia sull'acqua?", answer: "Perché è meno denso dell'acqua", distractors: ["Perché è più leggero in assoluto","Perché non si mescola con l'acqua","Perché è più caldo dell'acqua"], explanation: "Il non mescolarsi spiega perché restano separati, ma è la densità minore a decidere chi sta sopra." },
  { topic: "materia", difficulty: 3, format: "numeric_input", prompt: "Un litro d'acqua ha una massa di circa…", answer: "1", explanation: "Un litro d'acqua pesa circa un chilogrammo: è la definizione da cui nasce l'unità." },
  { topic: "materia", difficulty: 3, prompt: "Che cos'è una sostanza pura?", answer: "Una sostanza formata da un solo tipo di materia", distractors: ["Una sostanza priva di qualsiasi sporcizia","Una sostanza completamente trasparente alla luce","Una sostanza naturale che non è stata lavorata"], explanation: "L'acqua distillata è pura; l'acqua di mare è un miscuglio di acqua e sali." },
  { topic: "calore", difficulty: 3, prompt: "Qual è la differenza fra calore e temperatura?", answer: "Il calore è energia che passa, la temperatura è uno stato", distractors: ["Sono esattamente la stessa cosa con due nomi diversi","Il calore si misura in gradi centigradi come la temperatura","La temperatura si trasferisce da un corpo all'altro"], explanation: "Una tazza e una piscina possono avere la stessa temperatura, ma la piscina contiene molta più energia termica." },
  { topic: "calore", difficulty: 3, prompt: "In quale verso passa spontaneamente il calore?", answer: "Dal corpo più caldo a quello più freddo", distractors: ["Dal corpo più freddo a quello più caldo","Sempre verso il basso","Sempre verso il corpo più grande"], explanation: "Mai il contrario, da solo: per raffreddare qualcosa sotto la temperatura dell'ambiente serve una macchina." },
  { topic: "calore", difficulty: 3, prompt: "Come si chiama il passaggio di calore attraverso un corpo solido?", answer: "Conduzione", distractors: ["Convezione","Irraggiamento","Evaporazione"], explanation: "Il manico del cucchiaio si scalda per conduzione: le vibrazioni si trasmettono da un atomo al vicino." },
  { topic: "calore", difficulty: 4, prompt: "Come arriva il calore del Sole fino a noi?", answer: "Per irraggiamento", distractors: ["Per conduzione attraverso l'aria","Per convezione delle correnti","Per contatto diretto"], explanation: "Fra Sole e Terra c'è il vuoto: solo l'irraggiamento può attraversarlo, perché non ha bisogno di materia." },
  { topic: "calore", difficulty: 3, prompt: "Perché l'acqua che bolle in pentola si muove?", answer: "Per convezione: la parte calda sale e quella fredda scende", distractors: ["Perché le bolle spingono l'acqua tutto intorno","Perché il fuoco fa vibrare il fondo della pentola","Perché l'acqua cerca di uscire dal recipiente"], explanation: "L'acqua calda è meno densa e sale; quella fredda scende a prendere il suo posto: nasce un movimento circolare." },
  { topic: "calore", difficulty: 4, prompt: "Perché un cucchiaio di legno nella minestra non scotta?", answer: "Perché il legno conduce male il calore", distractors: ["Perché il legno resta sempre freddo","Perché il legno assorbe la minestra","Perché il legno è più leggero"], explanation: "Il calore fatica ad attraversarlo: si ferma vicino alla punta invece di arrivare alla mano." },
  { topic: "calore", difficulty: 3, format: "numeric_input", prompt: "A quale temperatura bolle l'acqua a livello del mare?", answer: "100", explanation: "Cento gradi centigradi. In montagna bolle a temperatura più bassa, perché la pressione è minore." },
  { topic: "calore", difficulty: 4, prompt: "Perché in montagna la pasta cuoce peggio?", answer: "Perché l'acqua bolle a temperatura più bassa", distractors: ["Perché l'aria è troppo fredda","Perché l'acqua evapora più in fretta","Perché il fuoco scalda di meno"], explanation: "Meno pressione significa ebollizione a temperatura minore: l'acqua bolle, ma è meno calda di quella al mare." },
  { topic: "calore", difficulty: 3, prompt: "Che cosa succede a un metallo quando si scalda?", answer: "Si dilata, cioè aumenta di volume", distractors: ["Si contrae, cioè si restringe","Cambia colore in modo permanente","Diventa più leggero"], explanation: "Per questo i binari e i ponti hanno giunti di dilatazione: senza, d'estate si deformerebbero." },
  // Misure
  { topic: "misure", difficulty: 1, prompt: "Con quale strumento misuri la lunghezza di un banco?", answer: "Il metro (righello)", distractors: ["La bilancia da cucina", "Il termometro", "L'orologio da polso"], explanation: "Il metro misura le lunghezze; la bilancia le masse." },
  { topic: "misure", difficulty: 2, prompt: "Quanti centimetri sono 1 metro?", answer: "100", distractors: ["10", "1000", "50"], explanation: "Il prefisso «centi-» vale un centesimo: vale per tutte le unità, non solo per il metro." },
  { topic: "misure", difficulty: 3, prompt: "Per misurare quanto pesi useresti…", answer: "Una bilancia", distractors: ["Un metro", "Un termometro", "Un cronometro"], explanation: "La bilancia misura la massa/peso; il termometro la temperatura." },
  // Moto
  { topic: "moto", difficulty: 1, prompt: "Un oggetto che non cambia posizione è…", answer: "Fermo", distractors: ["Veloce", "Lento", "In caduta"], explanation: "Fermo rispetto a che cosa, però: chi siede in treno è fermo rispetto al vagone e in corsa rispetto alla banchina." },
  { topic: "moto", difficulty: 2, prompt: "Se un'auto percorre più strada nello stesso tempo, è…", answer: "Più veloce", distractors: ["Più lenta", "Ferma", "Più pesante"], explanation: "Più spazio nello stesso tempo significa maggiore velocità." },
  { topic: "moto", difficulty: 3, prompt: "In un grafico spazio-tempo, una linea più ripida indica…", answer: "Una velocità maggiore", distractors: ["Un oggetto fermo", "Una salita reale in collina", "Un peso maggiore"], explanation: "La pendenza del grafico rappresenta la velocità, non un percorso in salita." },
  // Forze
  { topic: "forze", difficulty: 1, prompt: "Quale forza fa cadere gli oggetti verso il basso?", answer: "La forza di gravità", distractors: ["Il vento leggero", "La luce del Sole", "Il suono forte"], explanation: "La gravità attira gli oggetti verso il centro della Terra." },
  { topic: "forze", difficulty: 2, prompt: "Cosa rallenta una palla che rotola sul pavimento?", answer: "L'attrito", distractors: ["La gravità verso l'alto", "La luce", "Il colore della palla"], explanation: "L'attrito tra palla e pavimento la frena a poco a poco." },
  { topic: "forze", difficulty: 3, prompt: "Su un libro fermo sul tavolo, le forze…", answer: "Si bilanciano", distractors: ["Spingono solo in basso", "Spingono solo in alto", "Non esistono"], explanation: "Il peso verso il basso e la spinta del tavolo verso l'alto si equilibrano." },
  { topic: "forze", difficulty: 4, prompt: "Massa e peso: quale frase è corretta?", answer: "La massa è la quantità di materia; il peso è la forza di gravità su di essa", distractors: ["Massa e peso sono esattamente la stessa grandezza, con lo stesso nome", "Il peso resta identico ovunque, anche sulla Luna e su Marte", "La massa si misura sempre in newton, esattamente come il peso"], explanation: "La massa non cambia; il peso dipende dalla gravità (sulla Luna pesi meno)." },
  // Energia
  { topic: "energia", difficulty: 2, prompt: "Una palla ferma in cima a uno scivolo ha soprattutto energia…", answer: "Potenziale", distractors: ["Cinetica", "Sonora", "Luminosa"], explanation: "In alto e ferma ha energia potenziale (di posizione)." },
  { topic: "energia", difficulty: 3, prompt: "Mentre la palla scende lungo lo scivolo, l'energia potenziale si trasforma in…", answer: "Energia cinetica (di movimento)", distractors: ["Ancora più energia potenziale", "Energia sonora (rumore)", "Nulla: l'energia sparisce"], explanation: "Scendendo, l'energia di posizione diventa energia di movimento." },
  // Calore
  { topic: "calore", difficulty: 2, prompt: "Il calore passa sempre…", answer: "Dal corpo più caldo a quello più freddo", distractors: ["Dal corpo più freddo a quello più caldo", "Dal corpo più piccolo a quello più grande", "In nessuna direzione precisa"], explanation: "Il calore fluisce dal caldo al freddo finché non si equilibrano." },
  { topic: "calore", difficulty: 3, prompt: "Temperatura e calore: quale è vero?", answer: "La temperatura dice quanto è caldo; il calore è l'energia che si trasferisce", distractors: ["Temperatura e calore sono la stessa identica grandezza fisica", "Il calore si misura in gradi, esattamente come la temperatura", "La temperatura è un tipo di energia che passa fra i corpi"], explanation: "Sono grandezze diverse: gradi per la temperatura, energia per il calore." },
  // Onde e luce
  { topic: "onde-luce", difficulty: 2, prompt: "In aria limpida, la luce viaggia…", answer: "In linea retta", distractors: ["A zig-zag sempre", "Solo di notte", "Più lenta del suono"], explanation: "La luce si propaga in linea retta finché non incontra ostacoli." },
  { topic: "onde-luce", difficulty: 3, prompt: "Perché durante un temporale vediamo il lampo prima di sentire il tuono?", answer: "La luce è molto più veloce del suono", distractors: ["Il suono è più veloce", "Sono simultanei", "Il tuono parte dopo il lampo"], explanation: "La luce arriva quasi subito; il suono, più lento, arriva dopo." },
  { topic: "misure", difficulty: 1, format: "short_answer", prompt: "Come si chiama lo strumento con cui si misura la temperatura?", answer: "termometro", explanation: "Non misura il calore ma la temperatura: sono due grandezze diverse." },
  { topic: "misure", difficulty: 1, format: "short_answer", prompt: "Qual è l'unità di misura della massa nel Sistema Internazionale?", answer: "chilogrammo", accept: ["kilogrammo", "kg"], explanation: "È l'unica unità di base il cui nome contiene già un prefisso." },
  { topic: "misure", difficulty: 1, format: "short_answer", prompt: "Qual è l'unità di misura del tempo nel Sistema Internazionale?", answer: "secondo", explanation: "Minuti e ore sono comode, ma l'unità di base resta il secondo." },
  { topic: "moto", difficulty: 2, format: "short_answer", prompt: "Come si chiama il rapporto fra lo spazio percorso e il tempo impiegato?", answer: "velocità", accept: ["velocita"], explanation: "Stessa strada in metà tempo significa velocità doppia." },
  { topic: "moto", difficulty: 3, format: "short_answer", prompt: "Come si chiama la variazione della velocità nel tempo?", answer: "accelerazione", explanation: "Se la velocità cambia, anche solo di direzione, c'è accelerazione." },
  { topic: "moto", difficulty: 2, format: "short_answer", prompt: "Qual è l'unità di misura della velocità nel Sistema Internazionale?", answer: "metri al secondo", accept: ["m/s", "metro al secondo"], explanation: "Si ottiene dividendo l'unità di lunghezza per quella di tempo." },
  { topic: "onde-luce", difficulty: 2, format: "short_answer", prompt: "Come si chiama il rimbalzo della luce su uno specchio?", answer: "riflessione", explanation: "Il raggio torna indietro con lo stesso angolo con cui è arrivato." },
  { topic: "onde-luce", difficulty: 3, format: "short_answer", prompt: "Come si chiama la deviazione della luce quando passa dall'aria all'acqua?", answer: "rifrazione", explanation: "Cambiando mezzo la luce cambia velocità, e quindi piega: per questo il bastone nell'acqua sembra spezzato." },
  { topic: "onde-luce", difficulty: 3, format: "short_answer", prompt: "Come si chiama la distanza fra due creste successive di un'onda?", answer: "lunghezza d'onda", explanation: "È la lunghezza di un'oscillazione completa." },
  { topic: "forze", difficulty: 1, format: "short_answer", prompt: "Qual è l'unità di misura della forza nel Sistema Internazionale?", answer: "newton", explanation: "Un newton è la forza che dà a un chilogrammo un'accelerazione di un metro al secondo per secondo." },
  { topic: "forze", difficulty: 2, format: "short_answer", prompt: "Come si chiama la forza che si oppone allo scivolamento fra due superfici a contatto?", answer: "attrito", explanation: "Senza attrito non si cammina: è lui che dà presa alla scarpa." },
  { topic: "forze", difficulty: 2, format: "short_answer", prompt: "Come si chiama lo strumento che misura una forza allungando una molla?", answer: "dinamometro", explanation: "Più la molla si allunga, più forte è la forza: la scala è già tarata in newton." },
  { topic: "forze", difficulty: 3, format: "short_answer", prompt: "Come si chiama la spinta verso l'alto che riceve un corpo immerso in un liquido?", answer: "spinta di Archimede", accept: ["Archimede", "spinta idrostatica"], explanation: "Vale quanto il peso del liquido spostato: per questo una nave d'acciaio galleggia." },
  { topic: "energia", difficulty: 1, format: "short_answer", prompt: "Qual è l'unità di misura dell'energia nel Sistema Internazionale?", answer: "joule", explanation: "La stessa unità vale per il lavoro e per il calore: sono forme della stessa cosa." },
  { topic: "energia", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'energia che un corpo possiede perché è in movimento?", answer: "cinetica", accept: ["energia cinetica"], explanation: "Dipende dalla massa e dalla velocità: raddoppiando la velocità diventa quattro volte tanto." },
  { topic: "energia", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'energia che un corpo possiede per il fatto di trovarsi in alto?", answer: "potenziale", accept: ["energia potenziale"], explanation: "È l'energia messa da parte alzando il corpo: torna disponibile quando scende." },
  { topic: "metodo", difficulty: 2, format: "short_answer", prompt: "Come si chiama la spiegazione provvisoria che un esperimento deve mettere alla prova?", answer: "ipotesi", explanation: "Un'ipotesi vale solo se si può immaginare un risultato che la smentisce." },
  { topic: "metodo", difficulty: 3, format: "short_answer", prompt: "Come si chiama la grandezza che lo sperimentatore cambia di proposito?", answer: "variabile indipendente", accept: ["indipendente"], explanation: "Si cambia una cosa sola per volta, altrimenti non si sa a chi attribuire l'effetto." },
  { topic: "materia", difficulty: 2, format: "short_answer", prompt: "Come si chiama il passaggio dallo stato liquido a quello gassoso?", answer: "evaporazione", accept: ["vaporizzazione"], explanation: "Avviene anche sotto la temperatura di ebollizione, solo più lentamente." },
  { topic: "materia", difficulty: 1, format: "short_answer", prompt: "Come si chiama il passaggio dallo stato solido a quello liquido?", answer: "fusione", explanation: "Il ghiaccio che diventa acqua sta fondendo, non sciogliendosi in qualcos'altro." },
  { topic: "materia", difficulty: 3, format: "short_answer", prompt: "Come si chiama il rapporto fra la massa di un corpo e il suo volume?", answer: "densità", accept: ["densita"], explanation: "È la ragione per cui un chilo di piombo occupa molto meno spazio di un chilo di piume." },
  { topic: "calore", difficulty: 2, format: "short_answer", prompt: "Qual è l'unità di misura della temperatura nel Sistema Internazionale?", answer: "kelvin", explanation: "Parte dallo zero assoluto: sotto non si può scendere." },
  { topic: "calore", difficulty: 3, format: "short_answer", prompt: "Come si chiama il passaggio di calore per contatto diretto fra due corpi?", answer: "conduzione", explanation: "Il cucchiaino di metallo nel tè scotta per conduzione." },
  { topic: "misure", difficulty: 1, format: "short_answer", prompt: "Come si chiama lo strumento con cui si misura la massa di un oggetto?", answer: "bilancia", accept: ["la bilancia"], explanation: "Misura la massa confrontandola con masse note." },
  { topic: "moto", difficulty: 1, format: "short_answer", prompt: "Come si chiama il percorso seguito da un corpo che si muove?", answer: "traiettoria", accept: ["la traiettoria"], explanation: "Rettilinea, curva, circolare: dipende dalle forze in gioco." },
  { topic: "onde-luce", difficulty: 1, format: "short_answer", prompt: "Come si chiama l'ombra che si forma dietro un oggetto colpito dalla luce?", answer: "ombra", accept: ["l'ombra"], explanation: "Si forma perché la luce viaggia in linea retta e l'oggetto la ferma." },
  { topic: "calore", difficulty: 1, format: "short_answer", prompt: "Come si chiama il passaggio di calore attraverso il movimento di un liquido o di un gas?", answer: "convezione", explanation: "L'acqua calda sale, la fredda scende: la pentola si scalda tutta così." },
  { topic: "misure", difficulty: 1, prompt: "Perché in fisica una misura si scrive sempre con l'unità accanto al numero?", answer: "Perché senza unità il numero non dice quanto vale la grandezza", distractors: ["Perché è una regola di scrittura senza vere conseguenze pratiche", "Perché il numero da solo risulterebbe troppo corto da leggere", "Perché così si riconosce subito chi ha svolto la misurazione"], explanation: "«3» non vuol dire niente: tre metri, tre secondi e tre chili sono cose diversissime." },
  { topic: "moto", difficulty: 1, prompt: "Un corpo fermo rispetto alla strada può essere in movimento rispetto a che cosa?", answer: "Rispetto a un altro corpo che si sta muovendo", distractors: ["Rispetto a se stesso in un istante successivo del moto", "Rispetto alla strada, se la si osserva con più attenzione", "Rispetto al proprio peso, che cambia continuamente"], explanation: "Il moto è sempre relativo: chi è fermo in treno si muove rispetto alla banchina." },
  { topic: "energia", difficulty: 1, prompt: "Che cosa succede all'energia quando una palla che rotola si ferma per l'attrito?", answer: "Si trasforma in calore, non sparisce", distractors: ["Sparisce del tutto nel momento esatto in cui la palla si ferma", "Torna dentro la palla e resta lì immagazzinata per sempre", "Viene assorbita dall'aria e poi restituita alla palla dopo"], explanation: "L'energia non si crea e non si distrugge: cambia forma. La strada e la palla si scaldano un po'." },
  { topic: "materia", difficulty: 1, prompt: "Perché un palloncino gonfio schiacciato cambia forma ma torna com'era?", answer: "Perché il gas dentro si comprime e poi si riespande", distractors: ["Perché la gomma ricorda la forma che aveva prima di essere gonfiata", "Perché l'aria fuori dal palloncino lo spinge sempre verso l'alto", "Perché il gas dentro si trasforma per un attimo in liquido"], explanation: "I gas si comprimono facilmente: è quello che rende un palloncino elastico." },
  { topic: "forze", difficulty: 1, prompt: "Perché una cassa pesante è più difficile da spingere di una leggera?", answer: "Perché serve più forza per cambiare la velocità di una massa maggiore", distractors: ["Perché una cassa pesante è quasi sempre anche più grande da afferrare", "Perché la cassa leggera contiene più aria e quindi scivola meglio", "Perché il pavimento sotto una cassa pesante diventa più ruvido"], explanation: "Più massa, più inerzia: più resistenza a mettersi in moto." },
  { topic: "metodo", difficulty: 1, prompt: "Perché un esperimento va ripetuto più volte prima di trarre conclusioni?", answer: "Perché una volta sola può andare bene o male per caso", distractors: ["Perché la prima misura di uno strumento è sempre sbagliata di principio", "Perché ripetere serve soprattutto a fare pratica con lo strumento", "Perché le regole della scuola chiedono almeno tre prove scritte"], explanation: "Ripetere serve a distinguere l'effetto vero dal caso." },
  { topic: "calore", difficulty: 1, format: "short_answer", prompt: "Come si chiama il materiale che lascia passare poco calore, come il polistirolo?", answer: "isolante", accept: ["isolante termico"], explanation: "Tiene il caldo dentro o fuori: per questo si usa nelle borse frigo." },
  { topic: "energia",  difficulty: 1, format: "short_answer", prompt: "Come si chiama la macchina che trasforma il movimento in energia elettrica?", answer: "dinamo", accept: ["la dinamo", "generatore"], explanation: "Quella della bicicletta accende il fanale finché la ruota gira." },
  { topic: "materia", difficulty: 1, prompt: "Perché l'acqua versata prende la forma del bicchiere?", answer: "Perché un liquido non ha forma propria ma ha volume proprio", distractors: ["Perché il vetro attira il liquido contro le sue pareti interne", "Perché l'acqua si trasforma in un solido appena tocca il vetro", "Perché l'aria dentro il bicchiere spinge il liquido verso i bordi"], explanation: "Il volume resta lo stesso: mezzo litro resta mezzo litro in qualunque recipiente." },
  { topic: "onde-luce", difficulty: 1, prompt: "Perché di notte in una stanza chiusa non si vede niente?", answer: "Perché senza luce che arriva agli occhi non c'è visione", distractors: ["Perché gli occhi di notte smettono di funzionare del tutto", "Perché il buio è una sostanza che copre gli oggetti nella stanza", "Perché gli oggetti al buio perdono per qualche ora il loro colore"], explanation: "Vediamo la luce che gli oggetti rimandano: senza sorgente non c'è niente da rimandare." },
];

const MUSICA_EXTRA = [
  { topic: "lettura", difficulty: 3, prompt: "Che cosa indica una linea aggiunta sopra il pentagramma?", answer: "Una nota più acuta di quelle che ci stanno", distractors: ["Che il brano finisce a quel punto", "Che si deve suonare più forte", "Che la nota va tenuta più a lungo"], explanation: "Il pentagramma ha cinque righe: per le note che escono dall'alto o dal basso si aggiungono trattini corti, uno per grado." },
  { topic: "ritmo", difficulty: 3, prompt: "Che cos'è un punto di valore messo dopo una nota?", answer: "Allunga la nota della metà del suo valore", distractors: ["Raddoppia esattamente la durata", "Indica di suonare quella nota staccata", "Segnala che la nota va ripetuta"], explanation: "Una minima vale due movimenti; con il punto ne vale tre, cioè due più la metà di due." },
  { topic: "tempo", difficulty: 1, prompt: "Che cos'è il tempo in musica?", answer: "La pulsazione regolare che scandisce il brano", distractors: ["La durata totale della canzone","Il momento in cui entra il cantante","La velocità con cui si legge lo spartito"], explanation: "È il battito costante sotto la musica: quello che ti fa battere il piede senza pensarci." },
  { topic: "tempo", difficulty: 2, format: "numeric_input", prompt: "In un tempo di 4/4, quanti movimenti ci sono in una battuta?", answer: "4", explanation: "Il numero in alto dice quanti movimenti stanno in ogni battuta: quattro." },
  { topic: "tempo", difficulty: 2, format: "numeric_input", prompt: "In un tempo di 3/4, quanti movimenti ci sono in una battuta?", answer: "3", explanation: "Tre movimenti per battuta: è il tempo del valzer, un-due-tre, un-due-tre." },
  { topic: "tempo", difficulty: 3, prompt: "Che cosa indica il numero in basso di un tempo come 4/4?", answer: "Quale figura vale un movimento", distractors: ["Quante battute ha il brano","Quanto forte si deve suonare","Quanti strumenti servono"], explanation: "Il 4 in basso significa che la semiminima (un quarto) vale un movimento." },
  { topic: "tempo", difficulty: 2, prompt: "Che cos'è una battuta?", answer: "Il gruppo di movimenti fra due stanghette", distractors: ["Un colpo secco dato sul tamburo","La nota più forte di tutto il brano","L'inizio di una nuova strofa cantata"], explanation: "Le stanghette verticali dividono lo spartito in battute, tutte con lo stesso numero di movimenti." },
  { topic: "tempo", difficulty: 3, prompt: "Che cosa fa un metronomo?", answer: "Batte una pulsazione costante e regolabile", distractors: ["Misura quanto è acuto un suono","Conta le battute già suonate","Indica quale nota si sta suonando"], explanation: "Serve a tenere il tempo mentre si studia: si imposta quanti battiti al minuto e lui non sbaglia mai." },
  { topic: "tempo", difficulty: 3, prompt: "Un brano a 120 battiti al minuto rispetto a uno a 60 è…", answer: "Il doppio più veloce", distractors: ["Il doppio più lento","Della stessa velocità","Un quarto più veloce"], explanation: "Il doppio dei battiti nello stesso minuto significa che ogni battito dura la metà." },
  { topic: "tempo", difficulty: 2, prompt: "Che cosa significa «andante» su uno spartito?", answer: "Un'andatura moderata, come camminando", distractors: ["Un'andatura molto veloce e concitata","Un'andatura molto lenta e distesa","Un volume che cresce di continuo"], explanation: "Le indicazioni italiane di tempo si usano in tutto il mondo: adagio è lento, allegro veloce, andante sta a metà." },
  { topic: "tempo", difficulty: 3, prompt: "Che cosa significa «allegro»?", answer: "Veloce e vivace", distractors: ["Lento e solenne","Con volume crescente","Con volume calante"], explanation: "Indica la velocità, non l'umore: un brano allegro può anche essere in tonalità minore e suonare triste." },
  { topic: "tempo", difficulty: 4, format: "numeric_input", prompt: "In 4/4, quante semiminime riempiono una battuta?", answer: "4", explanation: "In 4/4 la semiminima vale un movimento, e i movimenti sono quattro." },
  { topic: "tempo", difficulty: 4, format: "numeric_input", prompt: "In 4/4, quante minime riempiono una battuta?", answer: "2", explanation: "La minima vale due movimenti: due minime fanno quattro movimenti, cioè una battuta piena." },
  { topic: "tempo", difficulty: 3, prompt: "Che cos'è il levare (o anacrusi)?", answer: "Una o più note prima della prima battuta piena", distractors: ["L'ultima nota che chiude tutto il brano","Una pausa messa all'inizio della battuta","Il momento esatto in cui si accelera"], explanation: "Molte canzoni cominciano prima del tempo forte: «Tan-ti au-GU-ri» parte in levare." },
  { topic: "tempo", difficulty: 4, prompt: "Che cosa fa un rallentando?", answer: "Il tempo diventa progressivamente più lento", distractors: ["Il volume diventa via via più debole","Le note diventano via via più gravi","Il brano si interrompe improvvisamente"], explanation: "Riguarda la velocità, non l'intensità: si usa spesso per preparare la fine di un brano." },
  { topic: "tempo", difficulty: 2, format: "numeric_input", prompt: "Nel tempo di 4/4, su quale movimento cade di solito l'accento più forte?", answer: "1", explanation: "Il primo movimento della battuta è il tempo forte: è quello che ti fa capire dove sei nella musica." },
  { topic: "timbro", difficulty: 2, prompt: "Che cos'è il timbro di un suono?", answer: "Il colore che distingue uno strumento da un altro", distractors: ["Quanto è acuto oppure grave un certo suono","Quanto è forte oppure debole un certo suono","Quanto a lungo dura una singola nota scritta"], explanation: "Un la del violino e un la del flauto hanno la stessa altezza e la stessa durata, ma non si confondono: è il timbro." },
  { topic: "timbro", difficulty: 3, prompt: "Due strumenti suonano la stessa nota alla stessa intensità. Cosa li distingue?", answer: "Il timbro", distractors: ["L'altezza del suono","La durata della nota","Il tempo del brano"], explanation: "Tolte altezza, durata e intensità, quello che resta è la qualità del suono: il timbro." },
  { topic: "timbro", difficulty: 3, prompt: "Perché la stessa canzone cantata da due persone suona diversa?", answer: "Perché ogni voce ha il suo timbro", distractors: ["Perché cambiano le note della melodia","Perché cambia il tempo dell'esecuzione","Perché cambia il volume della voce"], explanation: "La voce è uno strumento, e come ogni strumento ha un colore che dipende dal corpo che la produce." },
  { topic: "timbro", difficulty: 3, prompt: "Da che cosa dipende soprattutto il timbro di uno strumento?", answer: "Dal materiale e dalla forma del corpo", distractors: ["Dalla bravura di chi lo suona","Dal numero di note che può fare","Dal prezzo dello strumento"], explanation: "Legno o metallo, cassa grande o piccola: il corpo dello strumento colora il suono in modo caratteristico." },
  { topic: "timbro", difficulty: 4, prompt: "Perché una chitarra acustica e una elettrica suonano diverse anche sulla stessa nota?", answer: "Perché il suono viene amplificato in modi diversi", distractors: ["Perché hanno un numero diverso di corde","Perché l'elettrica suona sempre più forte","Perché usano note completamente diverse"], explanation: "Nell'acustica risuona la cassa di legno; nell'elettrica il segnale passa da magneti e altoparlante, e il colore cambia." },
  { topic: "timbro", difficulty: 2, prompt: "Riconosci un pianoforte da una tromba anche a occhi chiusi. Grazie a cosa?", answer: "Al timbro dei due strumenti", distractors: ["Al volume più alto della tromba","Alla maggiore velocità del piano","Alla diversa altezza delle note"], explanation: "Il timbro è la carta d'identità sonora: permette di riconoscere una fonte senza vederla." },
  { topic: "timbro", difficulty: 3, prompt: "In un'orchestra, che cosa permette di distinguere i violini dai fiati?", answer: "Il timbro delle due famiglie", distractors: ["Il numero di musicisti","La posizione sul palco","L'altezza delle note suonate"], explanation: "Anche suonando la stessa melodia all'unisono, archi e fiati restano riconoscibili." },
  { topic: "timbro", difficulty: 4, prompt: "Che cosa succede al timbro se copri una tromba con una sordina?", answer: "Cambia colore e diventa più nasale", distractors: ["Diventa soltanto più debole","Le note diventano più acute","Il tempo del brano rallenta"], explanation: "La sordina non abbassa solo il volume: modifica quali componenti del suono passano, cioè il timbro." },
  { topic: "timbro", difficulty: 3, prompt: "Uno stesso pianoforte suona diverso in una chiesa e in una stanza piccola. Perché?", answer: "Perché l'ambiente aggiunge il suo riverbero", distractors: ["Perché le note cambiano la loro altezza","Perché lo strumento si scorda con l'umidità","Perché cambia il tempo con cui si suona"], explanation: "Il suono che arriva all'orecchio è quello dello strumento più quello che l'ambiente gli restituisce." },
  { topic: "timbro", difficulty: 2, prompt: "Quale coppia di strumenti ha il timbro più simile?", answer: "Violino e viola", distractors: ["Violino e tamburo","Flauto e pianoforte","Tromba e arpa"], explanation: "Appartengono alla stessa famiglia e producono il suono allo stesso modo: corde sfregate da un archetto." },
  { topic: "timbro", difficulty: 4, prompt: "Perché la voce di una persona raffreddata cambia?", answer: "Perché cambiano le cavità che risuonano", distractors: ["Perché le corde vocali si accorciano","Perché si parla sempre più piano","Perché si sbagliano le note"], explanation: "Naso e gola fanno da cassa di risonanza: se sono ostruiti, il colore del suono cambia." },
  { topic: "timbro", difficulty: 3, prompt: "Che cosa NON dipende dal timbro?", answer: "Se una nota è acuta o grave", distractors: ["Il riconoscere uno strumento","La differenza fra due voci","Il colore di un suono"], explanation: "Acuto e grave sono l'altezza, che è un'altra caratteristica del suono: il timbro riguarda il colore." },
  { topic: "strumenti", difficulty: 2, prompt: "A quale famiglia appartiene il violoncello?", answer: "Archi", distractors: ["Fiati","Percussioni","Tastiere"], explanation: "Il suono nasce sfregando le corde con l'archetto: è la famiglia degli archi." },
  { topic: "strumenti", difficulty: 2, prompt: "A quale famiglia appartiene il clarinetto?", answer: "Fiati", distractors: ["Archi","Percussioni","Corde pizzicate"], explanation: "Il suono nasce dall'aria soffiata che fa vibrare un'ancia: è un fiato." },
  { topic: "strumenti", difficulty: 3, prompt: "Perché il pianoforte è considerato anche uno strumento a corde?", answer: "Perché i tasti fanno battere martelletti sulle corde", distractors: ["Perché tiene le corde soltanto per decorazione","Perché si accorda esattamente come una chitarra","Perché si suona usando tutte e due le mani"], explanation: "Premendo un tasto un martelletto colpisce una corda: c'è una tastiera, ma il suono lo fanno le corde." },
  { topic: "strumenti", difficulty: 3, prompt: "Quale strumento produce il suono percuotendo una pelle tesa?", answer: "Il tamburo", distractors: ["Il flauto","La chitarra","Il violino"], explanation: "Nelle percussioni a membrana il suono nasce dalla vibrazione di una pelle colpita." },
  { topic: "strumenti", difficulty: 3, prompt: "Che differenza c'è fra chitarra e violino nel produrre il suono?", answer: "La chitarra si pizzica, il violino si sfrega", distractors: ["La chitarra ha più corde del violino","Il violino è sempre più acuto","La chitarra non ha cassa di risonanza"], explanation: "Pizzicare dà un suono che decade subito; l'archetto può tenerlo lungo quanto si vuole." },
  { topic: "strumenti", difficulty: 4, prompt: "Perché un contrabbasso suona più grave di un violino?", answer: "Perché le corde sono più lunghe e grosse", distractors: ["Perché ha più corde del violino","Perché si suona stando in piedi","Perché è fatto di un legno diverso"], explanation: "Corde più lunghe e pesanti vibrano più lentamente, e una vibrazione lenta dà un suono grave." },
  { topic: "strumenti", difficulty: 3, prompt: "Quale gruppo di strumenti apre di solito l'orchestra sinfonica?", answer: "Gli archi, davanti al direttore", distractors: ["Le percussioni, in prima fila","Gli ottoni, al centro del palco","Le tastiere, davanti a tutti"], explanation: "Gli archi sono i più numerosi e stanno davanti; fiati e percussioni si dispongono dietro, in ordine di potenza sonora." },
  { topic: "strumenti", difficulty: 4, prompt: "Che cosa hanno in comune organo, fisarmonica e flauto?", answer: "Il suono nasce dall'aria in movimento", distractors: ["Si suonano tutti con una tastiera","Hanno tutti corde da far vibrare","Si portano tutti a tracolla"], explanation: "In tutti e tre è una colonna d'aria a vibrare, anche se il modo di metterla in moto è molto diverso." },
  { topic: "strumenti", difficulty: 2, prompt: "Quale strumento non appartiene alla famiglia degli archi?", answer: "Tromba", distractors: ["Violino","Viola","Contrabbasso"], explanation: "La tromba è un ottone: il suono nasce dalle labbra che vibrano nel bocchino, non da una corda." },
  { topic: "dinamica", difficulty: 2, prompt: "Che cosa indica la dinamica in musica?", answer: "Quanto forte o piano si suona", distractors: ["Quanto veloce si suona","Quali note si devono suonare","Quanto dura ogni nota"], explanation: "È l'intensità del suono, indipendente dalla velocità e dall'altezza delle note." },
  { topic: "dinamica", difficulty: 2, prompt: "Che cosa significa il segno «p» su uno spartito?", answer: "Piano, cioè debole", distractors: ["Presto, cioè veloce","Pausa, cioè silenzio","Pieno, cioè con tutti gli strumenti"], explanation: "Piano e forte sono i due estremi di base; da lì nascono pianissimo e fortissimo." },
  { topic: "dinamica", difficulty: 3, prompt: "Che cosa fa un crescendo?", answer: "Il volume aumenta a poco a poco", distractors: ["Il tempo accelera a poco a poco","Le note diventano sempre più acute","Entrano sempre più strumenti"], explanation: "Riguarda l'intensità: un crescendo può avvenire anche restando alla stessa velocità e sulle stesse note." },
  { topic: "dinamica", difficulty: 3, prompt: "Che cosa fa un diminuendo?", answer: "Il volume cala a poco a poco", distractors: ["Il tempo rallenta a poco a poco","Le note diventano sempre più gravi","Le battute diventano più corte"], explanation: "È l'opposto del crescendo: si scende di intensità gradualmente, non di colpo." },
  { topic: "dinamica", difficulty: 4, prompt: "Perché la dinamica rende una musica espressiva?", answer: "Perché il contrasto fra piano e forte crea tensione", distractors: ["Perché rende il brano molto più lungo","Perché aiuta i musicisti a ricordare le note","Perché fa suonare tutti quanti insieme"], explanation: "Una musica sempre allo stesso volume stanca: sono i cambi a far respirare e a colpire." },
  { topic: "dinamica", difficulty: 3, prompt: "Fra «pp» e «p», quale è più debole?", answer: "pp", distractors: ["p","Sono uguali","Dipende dallo strumento"], explanation: "Raddoppiare la lettera intensifica: pp è pianissimo, ff è fortissimo." },
  { topic: "dinamica", difficulty: 4, prompt: "Un'orchestra intera suona «pianissimo». Che cosa vuol dire?", answer: "Tutti suonano molto piano insieme", distractors: ["Suona un solo strumento alla volta","Metà orchestra resta in silenzio","Si suona molto lentamente"], explanation: "La dinamica riguarda l'intensità di chi suona, non quanti suonano: cento musicisti possono fare pianissimo." },
  { topic: "dinamica", difficulty: 3, prompt: "Che cosa NON cambia durante un crescendo?", answer: "L'altezza delle note", distractors: ["L'intensità del suono","L'energia dell'esecuzione","La percezione di tensione"], explanation: "Le note restano le stesse: cresce solo quanto forte vengono suonate." },
  { topic: "intervalli", difficulty: 2, prompt: "Che cos'è un intervallo musicale?", answer: "La distanza fra due note", distractors: ["La pausa fra due brani","Il tempo fra due battute","Il volume fra due suoni"], explanation: "Si misura contando i gradi da una nota all'altra, estremi compresi." },
  { topic: "intervalli", difficulty: 3, format: "numeric_input", prompt: "Quanti gradi ci sono nell'intervallo da do a sol?", answer: "5", explanation: "Do, re, mi, fa, sol: si contano tutte e cinque le note, compresa quella di partenza. È una quinta." },
  { topic: "intervalli", difficulty: 3, prompt: "Come si chiama l'intervallo fra do e do successivo?", answer: "Ottava", distractors: ["Quinta","Terza","Settima"], explanation: "Si contano otto gradi: do, re, mi, fa, sol, la, si, do. Le due note hanno lo stesso nome e suonano «uguali ma più alte»." },
  { topic: "intervalli", difficulty: 4, format: "numeric_input", prompt: "Quanti gradi ci sono nell'intervallo da do a mi?", answer: "3", explanation: "Do, re, mi: tre gradi. È una terza, l'intervallo che dà il carattere maggiore o minore a un accordo." },
  { topic: "intervalli", difficulty: 3, prompt: "Due note suonate insieme a distanza di ottava…", answer: "Si fondono e sembrano quasi la stessa nota", distractors: ["Creano una forte dissonanza","Suonano come note lontanissime","Non possono essere suonate insieme"], explanation: "L'ottava è l'intervallo più consonante che esista dopo l'unisono: per questo uomini e bambini possono cantare «la stessa» melodia." },
  { topic: "intervalli", difficulty: 4, prompt: "Perché la quinta è considerata un intervallo molto stabile?", answer: "Perché le due frequenze si accordano semplicemente", distractors: ["Perché è l'intervallo più ampio possibile","Perché usa sempre e solo le note bianche","Perché si suona soltanto sulle note basse"], explanation: "Il rapporto fra le due frequenze è semplice, e l'orecchio percepisce come consonante ciò che è semplice." },
  { topic: "note", difficulty: 2, format: "numeric_input", prompt: "Quante sono le note musicali di base?", answer: "7", explanation: "Do, re, mi, fa, sol, la, si: sette, e poi si ricomincia un'ottava sopra." },
  { topic: "note", difficulty: 2, prompt: "Quale nota viene subito dopo il sol?", answer: "La", distractors: ["Mi","Re","Si"], explanation: "L'ordine è do, re, mi, fa, sol, la, si: dopo sol viene la." },
  { topic: "note", difficulty: 3, prompt: "Che cosa distingue una nota acuta da una grave?", answer: "La frequenza con cui vibra il suono", distractors: ["L'intensità con cui si suona","La durata della nota scritta","Lo strumento che la produce"], explanation: "Più veloce è la vibrazione, più il suono è acuto. Il timbro e il volume sono altre caratteristiche." },
  { topic: "note", difficulty: 3, format: "numeric_input", prompt: "Su quante righe si scrivono le note nel pentagramma?", answer: "5", explanation: "«Penta» significa cinque: cinque righe e quattro spazi, più eventuali linee aggiunte sopra e sotto." },
  { topic: "note", difficulty: 4, prompt: "Perché due note con lo stesso nome, a un'ottava di distanza, suonano «la stessa»?", answer: "Perché una vibra al doppio della velocità dell'altra", distractors: ["Perché si scrivono esattamente nello stesso punto","Perché hanno sempre lo stesso identico timbro","Perché durano tutte e due lo stesso tempo"], explanation: "Il rapporto esatto di 2 a 1 fra le frequenze è ciò che il nostro orecchio riconosce come «stessa nota, più alta»." },
  { topic: "note", difficulty: 3, prompt: "Che cosa indica la chiave all'inizio del pentagramma?", answer: "Quale nota corrisponde a quale riga", distractors: ["Quanto forte si deve suonare","Con quale velocità si comincia","Quanti strumenti devono suonare"], explanation: "Senza chiave le righe non hanno un nome: la chiave di violino fissa il sol sulla seconda riga, e tutto il resto ne discende." },
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
  { topic: "dinamica", difficulty: 2, prompt: "In musica 'forte' e 'piano' indicano…", answer: "L'intensità del suono (il volume)", distractors: ["La velocità con cui si suona", "L'altezza (acuto o grave)", "La durata di ogni nota scritta"], explanation: "Le dinamiche dicono quanto suonare forte o piano." },
  { topic: "dinamica", difficulty: 3, prompt: "Il termine che indica quanto è veloce un brano è il…", answer: "Tempo (andamento)", distractors: ["Timbro (colore)", "Volume (intensità)", "Silenzio (pausa)"], explanation: "Il tempo indica la velocità: da lento (adagio) a veloce (allegro)." },
  { topic: "lettura", difficulty: 1, format: "short_answer", prompt: "Come si chiama il gruppo di cinque righe su cui si scrive la musica?", answer: "pentagramma", explanation: "Cinque righe e quattro spazi: penta vuol dire cinque." },
  { topic: "lettura", difficulty: 2, format: "short_answer", prompt: "Come si chiama il segno messo all'inizio del pentagramma che fissa l'altezza delle note?", answer: "chiave", explanation: "Senza la chiave le stesse righe direbbero note diverse: è lei a dare il punto di riferimento." },
  { topic: "note", difficulty: 1, format: "short_answer", prompt: "Qual è la nota che viene subito prima del do?", answer: "si", explanation: "Le sette note girano in cerchio: dopo il si si ricomincia dal do, quindi prima del do c'è il si." },
  { topic: "note", difficulty: 3, format: "short_answer", prompt: "Come si chiama la distanza fra un do e il do successivo, più acuto?", answer: "ottava", explanation: "Si contano i gradi da un do all'altro e vengono otto: do re mi fa sol la si do." },
  { topic: "ritmo", difficulty: 2, format: "short_answer", prompt: "Come si chiama la linea verticale che divide il pentagramma in battute?", answer: "stanghetta", explanation: "Ogni stanghetta chiude una battuta: è il modo di scrivere che il tempo torna a contare da uno." },
  { topic: "ritmo", difficulty: 1, format: "short_answer", prompt: "Come si chiama il segno che indica un silenzio nella musica?", answer: "pausa", explanation: "Il silenzio si scrive come una nota: ha una durata precisa e va contato." },
  { topic: "intervalli", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'intervallo fra il do e il sol?", answer: "quinta", explanation: "Si contano i gradi partendo dal do: do re mi fa sol, cinque." },
  { topic: "intervalli", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'intervallo fra il do e il mi?", answer: "terza", explanation: "Do re mi: tre gradi, quindi terza." },
  { topic: "dinamica", difficulty: 1, format: "short_answer", prompt: "Come si legge per esteso il segno «f» scritto sotto il pentagramma?", answer: "forte", explanation: "La f sta per forte, la p per piano: la dinamica si scrive con le iniziali delle parole italiane." },
  { topic: "timbro", difficulty: 2, format: "short_answer", prompt: "Come si chiama la qualità del suono che fa riconoscere un violino da un flauto anche sulla stessa nota?", answer: "timbro", explanation: "Stessa altezza, stessa intensità: quello che resta a distinguerli è il timbro." },
  { topic: "strumenti", difficulty: 1, format: "short_answer", prompt: "Come si chiama chi guida un'orchestra dal podio?", answer: "direttore", explanation: "Non suona: tiene insieme il tempo e l'equilibrio fra le sezioni." },
  { topic: "tempo", difficulty: 2, format: "short_answer", prompt: "Come si chiama lo strumento che batte il tempo regolare per esercitarsi?", answer: "metronomo", explanation: "Batte una pulsazione uguale a se stessa: serve a non accelerare nei punti facili." },
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
// Ogni riga porta anche un AGGANCIO sulla capitale e la collocazione del
// Paese: senza, le spiegazioni si limitavano a ripetere la domanda («La
// capitale di Italia è Roma»), che a chi ha sbagliato non lascia niente.
// L'articolo davanti al nome di uno Stato non si ricava da una regola: «il
// Canada» convive con «l'Argentina» e con «gli Stati Uniti». Tabella, quindi.
const GEO_ARTICLE = {
  "Italia": ["dell'Italia", "l'Italia", "L'Italia", "si trova"],
  "Francia": ["della Francia", "la Francia", "La Francia", "si trova"],
  "Spagna": ["della Spagna", "la Spagna", "La Spagna", "si trova"],
  "Germania": ["della Germania", "la Germania", "La Germania", "si trova"],
  "Regno Unito": ["del Regno Unito", "il Regno Unito", "Il Regno Unito", "si trova"],
  "Portogallo": ["del Portogallo", "il Portogallo", "Il Portogallo", "si trova"],
  "Grecia": ["della Grecia", "la Grecia", "La Grecia", "si trova"],
  "Austria": ["dell'Austria", "l'Austria", "L'Austria", "si trova"],
  "Belgio": ["del Belgio", "il Belgio", "Il Belgio", "si trova"],
  "Paesi Bassi": ["dei Paesi Bassi", "i Paesi Bassi", "I Paesi Bassi", "si trovano"],
  "Polonia": ["della Polonia", "la Polonia", "La Polonia", "si trova"],
  "Svezia": ["della Svezia", "la Svezia", "La Svezia", "si trova"],
  "Norvegia": ["della Norvegia", "la Norvegia", "La Norvegia", "si trova"],
  "Russia": ["della Russia", "la Russia", "La Russia", "si trova"],
  "Stati Uniti": ["degli Stati Uniti", "gli Stati Uniti", "Gli Stati Uniti", "si trovano"],
  "Canada": ["del Canada", "il Canada", "Il Canada", "si trova"],
  "Messico": ["del Messico", "il Messico", "Il Messico", "si trova"],
  "Brasile": ["del Brasile", "il Brasile", "Il Brasile", "si trova"],
  "Argentina": ["dell'Argentina", "l'Argentina", "L'Argentina", "si trova"],
  "Giappone": ["del Giappone", "il Giappone", "Il Giappone", "si trova"],
  "Cina": ["della Cina", "la Cina", "La Cina", "si trova"],
  "India": ["dell'India", "l'India", "L'India", "si trova"],
  "Egitto": ["dell'Egitto", "l'Egitto", "L'Egitto", "si trova"],
  "Australia": ["dell'Australia", "l'Australia", "L'Australia", "si trova"],
};

const GEO_COUNTRIES = [
  ["Italia", "Roma", "Europa", 1, "Roma sorge sul Tevere ed è l'unica capitale al mondo che ne contiene un'altra: lo Stato del Vaticano.",
    "è la penisola a forma di stivale allungata nel Mediterraneo"],
  ["Francia", "Parigi", "Europa", 1, "Parigi è attraversata dalla Senna, e la torre Eiffel fu costruita per l'Esposizione del 1889.",
    "si affaccia sia sull'Atlantico sia sul Mediterraneo"],
  ["Spagna", "Madrid", "Europa", 1, "Madrid è la capitale più alta d'Europa: sta a quasi 700 metri sul livello del mare.",
    "occupa quasi tutta la penisola iberica"],
  ["Germania", "Berlino", "Europa", 1, "Berlino è rimasta divisa da un muro fino al 1989.",
    "confina con nove Paesi, più di ogni altro Stato europeo"],
  ["Regno Unito", "Londra", "Europa", 1, "Londra sorge sul Tamigi ed è stata la prima città al mondo ad avere una metropolitana.",
    "è un'isola a nord-ovest dell'Europa continentale"],
  ["Portogallo", "Lisbona", "Europa", 2, "Lisbona guarda l'Atlantico ed è costruita su sette colline.",
    "è la punta occidentale dell'Europa continentale"],
  ["Grecia", "Atene", "Europa", 2, "Atene prende il nome dalla dea Atena, ed è la città dove è nata la democrazia.",
    "è fatta di una penisola e di migliaia di isole nel Mediterraneo"],
  ["Austria", "Vienna", "Europa", 3, "Vienna sorge sul Danubio ed è la città di Mozart e Beethoven.",
    "è uno Stato alpino, senza alcuno sbocco sul mare"],
  ["Belgio", "Bruxelles", "Europa", 3, "A Bruxelles hanno sede le principali istituzioni dell'Unione Europea.",
    "è un piccolo Stato affacciato sul Mare del Nord"],
  ["Paesi Bassi", "Amsterdam", "Europa", 3, "Amsterdam è attraversata da più di cento canali.",
    "stanno in gran parte sotto il livello del mare, protetti dalle dighe"],
  ["Polonia", "Varsavia", "Europa", 3, "Varsavia fu ricostruita quasi da zero dopo la seconda guerra mondiale.",
    "sta nell'Europa centro-orientale, affacciata sul Mar Baltico"],
  ["Svezia", "Stoccolma", "Europa", 3, "Stoccolma è costruita su quattordici isole collegate da ponti.",
    "occupa gran parte della penisola scandinava"],
  ["Norvegia", "Oslo", "Europa", 4, "Oslo sta in fondo a un lungo fiordo.",
    "ha una costa frastagliata di fiordi lunga migliaia di chilometri"],
  ["Russia", "Mosca", "Europa", 2, "Mosca è la città più popolosa d'Europa, e la Piazza Rossa ne è il centro.",
    "è lo Stato più esteso del mondo e si allunga fra Europa e Asia"],
  ["Stati Uniti", "Washington", "America del Nord", 2, "Washington non appartiene a nessuno Stato: è un distretto a sé.",
    "si estendono da un oceano all'altro"],
  ["Canada", "Ottawa", "America del Nord", 3, "Ottawa fu scelta come capitale perché sta a metà strada fra le città di lingua inglese e quelle di lingua francese.",
    "è il secondo Stato più esteso del mondo"],
  ["Messico", "Città del Messico", "America del Nord", 3, "Città del Messico è costruita sul letto di un lago prosciugato, e per questo sprofonda di qualche centimetro l'anno.",
    "fa da ponte fra l'America del Nord e quella centrale"],
  ["Brasile", "Brasília", "America del Sud", 2, "Brasília fu costruita dal nulla nel 1960, con la pianta a forma di aeroplano.",
    "è il Paese più grande dell'America del Sud e ospita gran parte dell'Amazzonia"],
  ["Argentina", "Buenos Aires", "America del Sud", 3, "Buenos Aires si affaccia sul Río de la Plata, il grande estuario che sembra un mare.",
    "si allunga verso sud fin quasi all'Antartide"],
  ["Giappone", "Tokyo", "Asia", 1, "Tokyo è l'area urbana più popolosa del mondo.",
    "è un arcipelago di isole al largo dell'Asia orientale"],
  ["Cina", "Pechino", "Asia", 2, "A Pechino si trova la Città Proibita, il palazzo dove vivevano gli imperatori.",
    "occupa gran parte dell'Asia orientale"],
  ["India", "Nuova Delhi", "Asia", 3, "Nuova Delhi fu costruita accanto all'antica città di Delhi, che esiste ancora.",
    "è un grande subcontinente che si spinge nell'Oceano Indiano"],
  ["Egitto", "Il Cairo", "Africa", 2, "Il Cairo sorge sul Nilo, a pochi chilometri dalle piramidi di Giza.",
    "sta nell'angolo nord-orientale dell'Africa, a cavallo del Nilo"],
  ["Australia", "Canberra", "Oceania", 4, "Canberra fu costruita apposta per fare da capitale, perché Sydney e Melbourne se la contendevano.",
    "è insieme uno Stato e un continente"],
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
  { topic: "geografia-italia", difficulty: 1, prompt: "Qual è la capitale d'Italia?", answer: "Roma", distractors: ["Milano", "Napoli", "Torino"], explanation: "Roma non lo è sempre stata: l'Italia unita nacque nel 1861 con capitale Torino, poi Firenze; Roma lo diventò solo nel 1871." },
  { topic: "geografia-italia", difficulty: 1, prompt: "Qual è il fiume più lungo d'Italia?", answer: "Po", distractors: ["Tevere", "Arno", "Adige"], explanation: "Il Po, che attraversa la Pianura Padana, è il fiume più lungo d'Italia." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Quali sono le due isole più grandi d'Italia?", answer: "Sicilia e Sardegna", distractors: ["Sicilia ed Elba", "Sardegna e Capri", "Elba e Ischia"], explanation: "La Sicilia supera la Sardegna di poco. Sono anche le due isole più grandi di tutto il Mediterraneo." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Qual è il vulcano attivo più grande d'Europa, in Sicilia?", answer: "Etna", distractors: ["Vesuvio", "Stromboli", "Vulcano"], explanation: "Erutta più spesso di quasi ogni altro vulcano al mondo perché sta proprio dove la placca africana spinge contro quella euroasiatica." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Qual è il lago più grande d'Italia?", answer: "Lago di Garda", distractors: ["Lago di Como", "Lago Maggiore", "Lago Trasimeno"], explanation: "Il Lago di Garda è il maggiore lago italiano per superficie." },
  { topic: "geografia-italia", difficulty: 3, prompt: "Quale catena montuosa percorre l'Italia da nord a sud?", answer: "Appennini", distractors: ["Alpi", "Pirenei", "Dolomiti"], explanation: "Gli Appennini attraversano la penisola; le Alpi chiudono l'Italia a nord." },
  { topic: "geografia-italia", difficulty: 3, prompt: "Quale mare bagna la costa orientale dell'Italia?", answer: "Mar Adriatico", distractors: ["Mar Tirreno", "Mar Ionio", "Mar Ligure"], explanation: "L'Adriatico è a est, tra Italia e penisola balcanica." },
  { topic: "geografia-italia", difficulty: 4, prompt: "Quale regione italiana ha la maggiore superficie?", answer: "Sicilia", distractors: ["Piemonte", "Sardegna", "Lombardia"], explanation: "La Sicilia è la regione italiana più estesa, seguita dal Piemonte." },
  // --- Climi e ambienti ---
  { topic: "climi", difficulty: 2, prompt: "In quale zona della Terra fa caldo tutto l'anno?", answer: "Vicino all'Equatore", distractors: ["Vicino ai Poli", "In cima alle montagne", "Nelle grotte"], explanation: "Vicino all'Equatore i raggi del Sole arrivano più diretti e riscaldano di più." },
  { topic: "climi", difficulty: 3, prompt: "Come si chiama il clima con estati calde e secche e inverni miti, tipico dell'Italia?", answer: "Clima mediterraneo", distractors: ["Clima polare", "Clima desertico", "Clima equatoriale"], explanation: "Il mare vicino smorza gli sbalzi di temperatura, e d'estate un'alta pressione stabile tiene lontane le piogge: qui, al contrario del resto d'Europa, l'estate è la stagione più secca." },
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
  { topic: "mondo", difficulty: 4, prompt: "Attraverso quale canale le navi passano tra Mar Mediterraneo e Mar Rosso?", answer: "Canale di Suez", distractors: ["Canale di Panama", "Stretto di Gibilterra", "Canale della Manica"], explanation: "Scavato nell'Ottocento per non dover circumnavigare tutta l'Africa: da allora una nave fra Europa e Asia risparmia settimane di viaggio." },
  // --- Strumenti del geografo ---
  { topic: "geografia-umana", difficulty: 1, prompt: "Da quale punto cardinale sorge il Sole?", answer: "Est", distractors: ["Ovest", "Nord", "Sud"], explanation: "Il Sole sorge a est e tramonta a ovest." },
  { topic: "geografia-umana", difficulty: 2, prompt: "Come si chiama la rappresentazione ridotta della Terra disegnata su un foglio?", answer: "Carta geografica", distractors: ["Fotografia", "Calendario", "Diario"], explanation: "La carta geografica riduce la realtà mantenendo le proporzioni." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Su una carta geografica, che cosa indica la scala?", answer: "Di quanto è stata ridotta la realtà", distractors: ["Il colore del mare", "La temperatura", "Il nome delle vie"], explanation: "La scala dice quante volte le distanze reali sono state rimpicciolite." },
];

// Nucleo autorato di geografia: il banco generato copre bene capitali e stati,
// e lascia magri gli argomenti che chiedono di ragionare sul territorio.
const GEOGRAFIA_EXTRA = [
  { topic: "mondo", difficulty: 2, format: "numeric_input", prompt: "Quanti sono i continenti abitati?", answer: "5", explanation: "Europa, Asia, Africa, America e Oceania. L'Antartide non ha popolazione stabile." },
  { topic: "mondo", difficulty: 2, prompt: "Qual è l'oceano più esteso del pianeta?", answer: "Pacifico", distractors: ["Atlantico","Indiano","Artico"], explanation: "Da solo copre circa un terzo della superficie terrestre: più di tutte le terre emerse messe insieme." },
  { topic: "mondo", difficulty: 3, prompt: "Che cos'è l'equatore?", answer: "La linea che divide la Terra in due emisferi", distractors: ["Il punto più caldo di tutto il pianeta","Il confine naturale fra due continenti","La linea lungo cui cambiano i fusi orari"], explanation: "È il parallelo di latitudine zero: da lì si contano i gradi verso nord e verso sud." },
  { topic: "mondo", difficulty: 3, prompt: "Che cos'è un meridiano?", answer: "Una linea che va da polo a polo", distractors: ["Una linea parallela all'equatore","Il confine fra due Stati vicini","La linea che segna il livello del mare"], explanation: "I meridiani misurano la longitudine; i paralleli, che girano attorno alla Terra, misurano la latitudine." },
  { topic: "mondo", difficulty: 3, prompt: "Perché esistono i fusi orari?", answer: "Perché la Terra ruota e non è giorno ovunque insieme", distractors: ["Perché i Paesi hanno leggi diverse","Perché le stagioni cambiano da luogo a luogo","Perché la Terra non è perfettamente sferica"], explanation: "Ruotando, ogni longitudine incontra il Sole in un momento diverso: servono ore diverse per tenere il mezzogiorno a mezzogiorno." },
  { topic: "mondo", difficulty: 3, prompt: "Qual è il continente più esteso?", answer: "Asia", distractors: ["Africa","America","Antartide"], explanation: "L'Asia copre circa un terzo delle terre emerse e ospita più della metà della popolazione mondiale." },
  { topic: "mondo", difficulty: 4, prompt: "Che cos'è la latitudine?", answer: "La distanza in gradi dall'equatore", distractors: ["La distanza in gradi dal meridiano zero","L'altezza sul livello del mare","La distanza dal Polo Nord in chilometri"], explanation: "Va da 0° all'equatore a 90° ai poli, verso nord o verso sud." },
  { topic: "mondo", difficulty: 4, prompt: "Che cos'è la longitudine?", answer: "La distanza in gradi dal meridiano di Greenwich", distractors: ["La distanza in gradi dall'equatore","La lunghezza di un Paese da nord a sud","La distanza fra due paralleli"], explanation: "Il meridiano fondamentale passa per Greenwich, a Londra: da lì si contano i gradi verso est e verso ovest." },
  { topic: "mondo", difficulty: 2, prompt: "Qual è il deserto caldo più esteso del mondo?", answer: "Sahara", distractors: ["Gobi","Atacama","Kalahari"], explanation: "Copre gran parte del Nord Africa: da solo è grande quasi quanto tutta l'Europa." },
  { topic: "mondo", difficulty: 3, prompt: "Su quale continente si trova la foresta amazzonica?", answer: "America meridionale", distractors: ["Africa centrale","Asia sudorientale","Oceania"], explanation: "Attraversa nove Paesi ed è la più grande foresta pluviale del pianeta." },
  { topic: "mondo", difficulty: 4, prompt: "Qual è la catena montuosa più alta del mondo?", answer: "Himalaya", distractors: ["Ande","Alpi","Montagne Rocciose"], explanation: "Vi si trova l'Everest, e nasce dallo scontro fra la placca indiana e quella eurasiatica: cresce ancora." },
  { topic: "geografia-umana", difficulty: 2, prompt: "Un Paese enorme con pochi abitanti ha densità di popolazione…", answer: "Bassa", distractors: ["Alta","Media","Non calcolabile"], explanation: "Un Paese può avere molti abitanti e bassa densità, se è molto esteso: Canada e Bangladesh sono i due estremi." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Che cos'è l'urbanizzazione?", answer: "Lo spostamento della popolazione verso le città", distractors: ["La costruzione di nuovi quartieri residenziali","L'aumento generale della popolazione mondiale","La creazione di nuovi parchi dentro le città"], explanation: "Oggi più di metà dell'umanità vive in città: due secoli fa era meno di un decimo." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Perché le città nascono spesso vicino a fiumi o coste?", answer: "Perché acqua e trasporti facilitano gli scambi", distractors: ["Perché il clima è più mite là","Perché il terreno è più pianeggiante","Perché ci sono più materiali da costruzione"], explanation: "Acqua da bere, terra fertile e una via di comunicazione: sono le tre cose che una città non può inventarsi." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Che cosa si intende per «migrazione»?", answer: "Lo spostamento stabile di persone da un luogo a un altro", distractors: ["Un viaggio di vacanza fatto in un altro Paese","Il trasferimento di merci da uno Stato all'altro","Lo spostamento stagionale di alcune specie animali"], explanation: "Può essere interna, dentro lo stesso Paese, o internazionale, e ha sempre cause economiche, ambientali o politiche." },
  { topic: "geografia-umana", difficulty: 4, prompt: "Che cos'è il settore primario?", answer: "Le attività che ricavano risorse dalla natura", distractors: ["Le attività che trasformano le materie prime","I servizi come scuola e commercio","Le attività più importanti di un Paese"], explanation: "Agricoltura, pesca, allevamento, estrazione. Il secondario trasforma, il terziario fornisce servizi." },
  { topic: "geografia-umana", difficulty: 4, prompt: "Che cos'è il settore terziario?", answer: "L'insieme dei servizi come scuola, sanità, commercio", distractors: ["L'agricoltura, la pesca e l'allevamento","L'industria pesante e l'artigianato","Il terzo Paese più ricco di tutto il mondo"], explanation: "Nei Paesi più sviluppati occupa la maggioranza dei lavoratori: non produce oggetti, fornisce prestazioni." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Che cos'è una metropoli?", answer: "Una città molto grande e influente", distractors: ["La capitale di uno Stato","Una città con più di mille abitanti","Una città costruita di recente"], explanation: "Non conta solo la dimensione: una metropoli attira lavoro, servizi e persone da un'area vastissima." },
  { topic: "geografia-umana", difficulty: 4, prompt: "Perché la popolazione mondiale non è distribuita uniformemente?", answer: "Perché clima, acqua e risorse cambiano da luogo a luogo", distractors: ["Perché alcuni Paesi lo vietano con apposite leggi","Perché le persone preferiscono vivere a nord","Perché i confini fra Stati sono stati tracciati male"], explanation: "Deserti, ghiacci e alta montagna ospitano pochissimi abitanti: la gente si concentra dove si può vivere e coltivare." },
  { topic: "geografia-umana", difficulty: 3, prompt: "Che cos'è un confine?", answer: "La linea che separa due territori", distractors: ["La costa di uno Stato sul mare","Il centro geografico di un Paese","La zona più lontana dalla capitale"], explanation: "Può seguire elementi naturali come fiumi e montagne, oppure essere tracciato per accordo: molti confini sono linee dritte disegnate a tavolino." },
  { topic: "geografia-umana", difficulty: 4, prompt: "Che cos'è la globalizzazione?", answer: "La crescente connessione fra economie e culture del mondo", distractors: ["L'aumento costante della popolazione mondiale","L'uso di una sola lingua in tutti i Paesi","La creazione di un unico governo per il pianeta"], explanation: "Merci, informazioni e persone si spostano più facilmente: crea opportunità e disuguaglianze insieme." },
  { topic: "geografia-umana", difficulty: 2, prompt: "Che cos'è una capitale?", answer: "La città sede del governo di uno Stato", distractors: ["La città più grande di uno Stato","La città più antica di uno Stato","La città più ricca di uno Stato"], explanation: "Non è sempre la più popolosa: Washington, Canberra e Brasilia sono capitali ma non le città maggiori." },
  { topic: "europa", difficulty: 2, prompt: "Quale grande fiume europeo attraversa dieci Paesi diversi?", answer: "Danubio", distractors: ["Il Volga, in Russia","Il Reno, in Germania","La Senna, in Francia"], explanation: "Scorre interamente in Russia e sfocia nel Mar Caspio: il Danubio è il secondo e attraversa dieci Paesi." },
  { topic: "europa", difficulty: 3, prompt: "Quale catena montuosa separa l'Europa dall'Asia?", answer: "Urali", distractors: ["Alpi","Carpazi","Pirenei"], explanation: "Il confine fra i due continenti è convenzionale e segue gli Urali, il fiume Ural e il Caucaso." },
  { topic: "europa", difficulty: 2, prompt: "Quale mare bagna l'Italia a est?", answer: "Adriatico", distractors: ["Tirreno","Ionio","Ligure"], explanation: "L'Adriatico separa l'Italia dai Balcani; il Tirreno sta a ovest." },
  { topic: "europa", difficulty: 3, prompt: "Che cos'è l'Unione Europea?", answer: "Un'unione politica ed economica di Stati europei", distractors: ["L'insieme di tutti i Paesi del continente europeo","Un'alleanza militare fra gli Stati membri","Un accordo che riguarda solo la moneta unica"], explanation: "Non tutti gli Stati europei ne fanno parte, e non tutti i membri usano l'euro." },
  { topic: "europa", difficulty: 3, prompt: "Quale penisola europea è bagnata da Mediterraneo e Atlantico?", answer: "Penisola iberica", distractors: ["Penisola italiana","Penisola balcanica","Penisola scandinava"], explanation: "Spagna e Portogallo si affacciano sui due mari: è la posizione che ne ha fatto la base delle esplorazioni oceaniche." },
  { topic: "europa", difficulty: 4, prompt: "Perché il clima dell'Europa occidentale è più mite di quello atteso alla sua latitudine?", answer: "Per l'influenza della Corrente del Golfo", distractors: ["Perché le montagne fermano i venti freddi","Perché ci sono molte foreste","Perché è vicina al deserto africano"], explanation: "Una corrente calda dall'Atlantico porta calore fino alle coste britanniche e norvegesi: alla stessa latitudine, il Canada gela." },
  { topic: "europa", difficulty: 3, prompt: "Qual è lo Stato più esteso interamente in Europa?", answer: "Ucraina", distractors: ["Francia","Spagna","Germania"], explanation: "La Russia è più grande ma si estende soprattutto in Asia: fra quelli interamente europei l'Ucraina è il maggiore." },
  { topic: "europa", difficulty: 3, prompt: "Quale catena montuosa separa Francia e Spagna?", answer: "Pirenei", distractors: ["Alpi","Appennini","Carpazi"], explanation: "Corrono da un mare all'altro e hanno reso storicamente difficile il passaggio fra i due Paesi." },
  { topic: "europa", difficulty: 4, prompt: "Perché la Scandinavia ha molti fiordi?", answer: "Perché antichi ghiacciai hanno scavato valli poi invase dal mare", distractors: ["Perché il mare ha eroso quella costa per secoli","Perché i fiumi vi hanno scavato gole profondissime","Perché il terreno si è spaccato durante i terremoti"], explanation: "I ghiacciai scavano valli a U molto profonde: quando il ghiaccio si ritira, il mare entra e resta." },
  { topic: "europa", difficulty: 2, prompt: "Quale mare si trova a nord dell'Europa continentale?", answer: "Mare del Nord", distractors: ["Mar Nero","Mar Mediterraneo","Mar Caspio"], explanation: "Bagna Regno Unito, Norvegia, Danimarca, Germania e Paesi Bassi." },
  { topic: "climi", difficulty: 2, prompt: "Qual è la differenza fra tempo meteorologico e clima?", answer: "Il tempo è di oggi, il clima è la media di molti anni", distractors: ["Sono la stessa cosa detta in due modi","Il clima riguarda solo l'estate","Il tempo si misura solo con il termometro"], explanation: "Un giorno freddo d'estate non smentisce il clima: servono decenni di dati per parlare di clima." },
  { topic: "climi", difficulty: 3, prompt: "Che cosa caratterizza il clima mediterraneo?", answer: "Estati calde e secche, inverni miti e piovosi", distractors: ["Piogge abbondanti tutto l'anno","Inverni molto rigidi e nevosi","Temperature costanti in ogni stagione"], explanation: "È tipico delle coste del Mediterraneo, ma si trova anche in California e in Cile centrale." },
  { topic: "climi", difficulty: 3, prompt: "Perché in montagna fa più freddo?", answer: "Perché l'aria si raffredda salendo di quota", distractors: ["Perché in quota si è più lontani dal Sole","Perché in montagna c'è sempre molto più vento","Perché la neve sul terreno raffredda l'aria"], explanation: "Circa mezzo grado ogni cento metri: l'aria che sale si espande e si raffredda." },
  { topic: "climi", difficulty: 3, prompt: "Che cos'è un climogramma?", answer: "Un grafico con temperature e piogge mese per mese", distractors: ["Una mappa che mostra i climi del mondo","Uno strumento che serve a misurare il clima","Un elenco degli eventi meteorologici passati"], explanation: "Combina due informazioni in un grafico solo: le colonne per le piogge, la linea per le temperature." },
  { topic: "climi", difficulty: 4, prompt: "Perché le zone vicine all'equatore sono più calde?", answer: "Perché i raggi del Sole arrivano più perpendicolari", distractors: ["Perché quelle zone sono più vicine al Sole","Perché sopra di esse c'è meno atmosfera","Perché in quelle zone non ci sono mai nuvole"], explanation: "Gli stessi raggi si distribuiscono su una superficie minore: più energia per metro quadrato." },
  { topic: "climi", difficulty: 3, prompt: "Che effetto ha il mare sul clima delle coste?", answer: "Lo rende più mite, con meno sbalzi", distractors: ["Lo rende più freddo tutto l'anno","Lo rende più caldo tutto l'anno","Non ha alcun effetto sul clima"], explanation: "L'acqua si scalda e si raffredda lentamente: fa da volano termico e smorza gli estremi." },
  { topic: "climi", difficulty: 4, prompt: "Perché i deserti si trovano spesso attorno ai tropici?", answer: "Perché lì l'aria scende secca dopo aver perso l'umidità", distractors: ["Perché ai tropici il Sole è sempre perpendicolare","Perché in quelle zone il terreno è già sabbioso","Perché i venti vi soffiano molto più forte"], explanation: "L'aria salita e piovuta all'equatore ridiscende ai tropici ormai asciutta: nasce così la fascia dei grandi deserti." },
  { topic: "climi", difficulty: 3, prompt: "Che cos'è il clima continentale?", answer: "Un clima con inverni freddi ed estati calde, lontano dal mare", distractors: ["Il clima che si trova in tutti i grandi continenti","Un clima che resta sempre umido e piovoso","Il clima tipico delle zone di alta montagna"], explanation: "Senza l'effetto mitigante del mare, la differenza fra inverno ed estate diventa molto ampia." },
  { topic: "climi", difficulty: 4, prompt: "Perché il cambiamento climatico non si dimostra con una singola estate calda?", answer: "Perché il clima si misura su decenni, non su un anno", distractors: ["Perché le estati sono sempre state calde","Perché i termometri sbagliano spesso","Perché conta solo l'inverno"], explanation: "Servono serie storiche lunghe: è la tendenza di fondo a dire qualcosa, non il singolo dato." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Quale fiume attraversa la pianura padana da ovest a est?", answer: "Po", distractors: ["Tevere","Adige","Arno"], explanation: "Attraversa la pianura padana da ovest a est per oltre 650 chilometri." },
  { topic: "geografia-italia", difficulty: 3, prompt: "Qual è il lago più esteso d'Italia?", answer: "Lago di Garda", distractors: ["Lago Maggiore","Lago di Como","Lago Trasimeno"], explanation: "Si trova fra Lombardia, Veneto e Trentino: è di origine glaciale, come gli altri grandi laghi del nord." },
  { topic: "geografia-italia", difficulty: 3, format: "numeric_input", prompt: "Quante regioni ha l'Italia?", answer: "20", explanation: "Venti regioni, di cui cinque a statuto speciale: Sicilia, Sardegna, Trentino-Alto Adige, Friuli-Venezia Giulia e Valle d'Aosta." },
  { topic: "geografia-italia", difficulty: 3, prompt: "Quale vulcano si trova in Sicilia?", answer: "Etna", distractors: ["Vesuvio","Stromboli","Vulture"], explanation: "È il vulcano attivo più alto d'Europa. Lo Stromboli è siciliano ma sta nelle Eolie, il Vesuvio è in Campania." },
  { topic: "geografia-italia", difficulty: 4, prompt: "Perché la pianura padana è così fertile?", answer: "Perché i fiumi vi hanno depositato sedimenti per millenni", distractors: ["Perché è la zona più calda di tutta l'Italia","Perché riceve più pioggia di ogni altra zona","Perché si trova vicina al mare Adriatico"], explanation: "Le Alpi e gli Appennini si erodono, i fiumi trasportano il materiale a valle e lo depositano: la pianura è nata così." },
  { topic: "geografia-italia", difficulty: 2, prompt: "Quale catena è chiamata la «spina dorsale» della penisola italiana?", answer: "Appennini", distractors: ["Alpi","Dolomiti","Pirenei"], explanation: "Gli Appennini sono la spina dorsale della penisola; le Alpi la chiudono a nord." },
  { topic: "geografia-fisica", difficulty: 3, prompt: "Che cos'è un delta?", answer: "L'area dove un fiume si divide sfociando in mare", distractors: ["Il punto preciso in cui nasce un fiume","Il tratto più stretto del corso di un fiume","Il lago che si forma lungo il corso di un fiume"], explanation: "Il fiume rallenta, deposita i sedimenti e si divide in più rami: il nome viene dalla lettera greca triangolare." },
  { topic: "geografia-fisica", difficulty: 3, prompt: "Che cos'è un altopiano?", answer: "Una zona elevata ma pianeggiante", distractors: ["Una montagna con la cima piatta","Una pianura in riva al mare","Una valle molto larga fra due monti"], explanation: "Sta in quota come una montagna, ma la superficie è piana: si può coltivare e abitare." },
  { topic: "geografia-fisica", difficulty: 4, prompt: "Come nascono le catene montuose?", answer: "Dallo scontro fra placche della crosta terrestre", distractors: ["Dall'accumulo di sabbia nel tempo","Dall'erosione delle pianure circostanti","Dalla caduta di grandi meteoriti"], explanation: "Quando due placche si spingono, la crosta si corruga e si solleva: le Alpi e l'Himalaya nascono così, e crescono ancora." },
  { topic: "geografia-fisica", difficulty: 3, prompt: "Che cos'è un ghiacciaio?", answer: "Una massa di ghiaccio che si muove lentamente", distractors: ["Un lago che ghiaccia del tutto in inverno","Una zona che resta sempre coperta di neve","Un fiume che gela completamente ogni anno"], explanation: "Si forma dove la neve non si scioglie mai del tutto: compressa negli anni diventa ghiaccio, e sotto il proprio peso scivola a valle." },
  { topic: "geografia-fisica", difficulty: 4, prompt: "Perché l'erosione modifica il paesaggio?", answer: "Perché acqua, vento e ghiaccio asportano materiale", distractors: ["Perché il terreno si consuma lentamente da solo","Perché le rocce si sciolgono al calore del Sole","Perché le radici delle piante spaccano il terreno"], explanation: "È un lavoro lentissimo e continuo: il Grand Canyon è stato scavato da un fiume, un granello alla volta." },
  { topic: "continenti", difficulty: 1, format: "short_answer", prompt: "Qual è il continente più grande per superficie?", answer: "Asia", accept: ["l'Asia"], explanation: "Copre da sola circa un terzo delle terre emerse." },
  { topic: "continenti", difficulty: 2, format: "short_answer", prompt: "Qual è il continente più freddo?", answer: "Antartide", accept: ["l'Antartide"], explanation: "È coperto da una calotta di ghiaccio spessa chilometri." },
  { topic: "continenti", difficulty: 2, format: "short_answer", prompt: "In quale continente si trova il deserto del Sahara?", answer: "Africa", accept: ["l'Africa"], explanation: "Occupa tutta la fascia settentrionale del continente." },
  { topic: "continenti", difficulty: 1, format: "short_answer", prompt: "In quale continente si trova l'Italia?", answer: "Europa", accept: ["l'Europa"], explanation: "Sporge nel Mediterraneo dalla parte meridionale del continente." },
  { topic: "capitali", difficulty: 1, format: "short_answer", prompt: "Qual è la capitale della Francia?", answer: "Parigi", explanation: "Sorge sulla Senna." },
  { topic: "capitali", difficulty: 1, format: "short_answer", prompt: "Qual è la capitale della Spagna?", answer: "Madrid", explanation: "Sta quasi al centro esatto della penisola iberica." },
  { topic: "capitali", difficulty: 1, format: "short_answer", prompt: "Qual è la capitale della Germania?", answer: "Berlino", explanation: "È stata divisa da un muro fino al 1989." },
  { topic: "capitali", difficulty: 2, format: "short_answer", prompt: "Qual è la capitale del Portogallo?", answer: "Lisbona", explanation: "Si affaccia sull'oceano Atlantico, alla foce del Tago." },
  { topic: "capitali", difficulty: 2, format: "short_answer", prompt: "Qual è la capitale della Grecia?", answer: "Atene", explanation: "Sull'Acropoli si trova il Partenone." },
  { topic: "capitali", difficulty: 2, format: "short_answer", prompt: "Qual è la capitale dell'Austria?", answer: "Vienna", explanation: "Sta sul Danubio, all'incrocio fra l'Europa occidentale e quella orientale." },
  { topic: "capitali", difficulty: 2, format: "short_answer", prompt: "Qual è la capitale della Polonia?", answer: "Varsavia", explanation: "Ricostruita quasi da zero dopo la seconda guerra mondiale." },
  { topic: "capitali", difficulty: 3, format: "short_answer", prompt: "Qual è la capitale della Svizzera?", answer: "Berna", explanation: "Non è la città più grande: Zurigo lo è, ma la capitale è Berna." },
  { topic: "geografia-italia", difficulty: 1, format: "short_answer", prompt: "Qual è il fiume più lungo d'Italia?", answer: "Po", accept: ["il Po"], explanation: "Attraversa la pianura padana da ovest a est." },
  { topic: "geografia-italia", difficulty: 2, format: "short_answer", prompt: "Come si chiama il mare che bagna la costa orientale dell'Italia?", answer: "Adriatico", accept: ["mare Adriatico", "l'Adriatico"], explanation: "Stretto e poco profondo, chiuso fra l'Italia e la penisola balcanica." },
  { topic: "geografia-italia", difficulty: 1, format: "short_answer", prompt: "Qual è l'isola più grande d'Italia?", answer: "Sicilia", accept: ["la Sicilia"], explanation: "Poco più estesa della Sardegna." },
  { topic: "geografia-italia", difficulty: 2, format: "short_answer", prompt: "Come si chiama la catena montuosa che percorre l'Italia da nord a sud?", answer: "Appennini", accept: ["gli Appennini", "Appennino"], explanation: "Fa da spina dorsale alla penisola." },
  { topic: "geografia-italia", difficulty: 2, format: "short_answer", prompt: "Come si chiama il vulcano attivo che sovrasta Catania?", answer: "Etna", accept: ["l'Etna"], explanation: "È il vulcano attivo più alto d'Europa." },
  { topic: "geografia-fisica", difficulty: 2, format: "short_answer", prompt: "Come si chiama la pianura più estesa d'Italia?", answer: "pianura padana", accept: ["padana", "Pianura Padana"], explanation: "La costruisce il Po con i detriti che deposita da millenni." },
  { topic: "geografia-fisica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il punto in cui un fiume si getta nel mare?", answer: "foce", explanation: "Se il fiume deposita molti detriti si forma un delta." },
  { topic: "geografia-fisica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il punto in cui un fiume nasce?", answer: "sorgente", explanation: "Da lì in poi il fiume raccoglie l'acqua di tutto il bacino." },
  { topic: "geografia-fisica", difficulty: 3, format: "short_answer", prompt: "Come si chiama una lingua di terra circondata dal mare su tre lati?", answer: "penisola", explanation: "L'Italia ne è l'esempio più noto." },
  { topic: "geografia-fisica", difficulty: 3, format: "short_answer", prompt: "Come si chiama il braccio di mare stretto fra due terre?", answer: "stretto", explanation: "Lo stretto di Messina separa la Sicilia dalla Calabria." },
  { topic: "europa", difficulty: 1, format: "short_answer", prompt: "Qual è il fiume che attraversa Parigi?", answer: "Senna", accept: ["la Senna"], explanation: "Divide la città in riva destra e riva sinistra." },
  { topic: "europa", difficulty: 2, format: "short_answer", prompt: "Come si chiama la catena montuosa che separa l'Italia dalla Francia e dall'Austria?", answer: "Alpi", accept: ["le Alpi"], explanation: "Fa da confine naturale a nord." },
  { topic: "europa", difficulty: 2, format: "short_answer", prompt: "Qual è la penisola su cui si trovano Spagna e Portogallo?", answer: "penisola iberica", accept: ["iberica"], explanation: "Separata dal resto d'Europa dai Pirenei." },
  { topic: "europa", difficulty: 3, format: "short_answer", prompt: "Qual è il fiume che attraversa Vienna e Budapest?", answer: "Danubio", accept: ["il Danubio"], explanation: "Nasce in Germania e sfocia nel mar Nero dopo aver toccato dieci Paesi." },
  { topic: "mondo", difficulty: 1, format: "short_answer", prompt: "Qual è l'oceano più esteso?", answer: "Pacifico", accept: ["oceano Pacifico", "il Pacifico"], explanation: "Da solo copre circa un terzo della superficie del pianeta." },
  { topic: "mondo", difficulty: 2, format: "short_answer", prompt: "Qual è la montagna più alta del mondo?", answer: "Everest", accept: ["Monte Everest", "l'Everest"], explanation: "Ottomilaottocentoquarantanove metri, sulla catena dell'Himalaya." },
  { topic: "mondo", difficulty: 2, format: "short_answer", prompt: "Qual è il fiume più lungo dell'Africa?", answer: "Nilo", accept: ["il Nilo"], explanation: "Scorre da sud a nord e sfocia nel Mediterraneo." },
  { topic: "mondo", difficulty: 3, format: "short_answer", prompt: "Come si chiama la linea immaginaria che divide la Terra in due emisferi uguali?", answer: "equatore", accept: ["l'equatore"], explanation: "È il parallelo di latitudine zero." },
  { topic: "climi", difficulty: 2, format: "short_answer", prompt: "Come si chiama il clima mite con estati secche e inverni piovosi tipico delle coste italiane?", answer: "mediterraneo", accept: ["clima mediterraneo"], explanation: "Lo rendono possibile il mare e la latitudine." },
  { topic: "climi", difficulty: 2, format: "short_answer", prompt: "Come si chiama il clima caldo e umido tutto l'anno tipico della fascia equatoriale?", answer: "equatoriale", accept: ["clima equatoriale"], explanation: "Piove quasi ogni giorno e le temperature non cambiano quasi mai." },
  { topic: "climi", difficulty: 3, format: "short_answer", prompt: "Come si chiama la fascia di clima freddissimo attorno ai poli?", answer: "polare", accept: ["clima polare"], explanation: "Le temperature restano sotto zero per gran parte dell'anno." },
  { topic: "climi", difficulty: 3, format: "short_answer", prompt: "Come si chiama il vento stagionale che porta grandi piogge nel sud-est asiatico?", answer: "monsone", accept: ["il monsone", "monsoni"], explanation: "Cambia direzione fra estate e inverno." },
  { topic: "geografia-umana", difficulty: 2, format: "short_answer", prompt: "Come si chiama il numero di abitanti per chilometro quadrato?", answer: "densità di popolazione", accept: ["densita di popolazione", "densità"], explanation: "Dice quanto è affollato un territorio, non quanto è grande." },
  { topic: "geografia-umana", difficulty: 3, format: "short_answer", prompt: "Come si chiama lo spostamento di persone da un paese a un altro per viverci?", answer: "migrazione", explanation: "Si parla di emigrazione da chi parte e di immigrazione da chi accoglie." },
  { topic: "geografia-umana", difficulty: 3, format: "short_answer", prompt: "Come si chiama il passaggio di popolazione dalle campagne alle città?", answer: "urbanizzazione", explanation: "È il fenomeno che ha fatto crescere le città nell'ultimo secolo." },
];

function geografiaBank() {
  const rand = rng(20260728);
  const items = [];
  const capitals = GEO_COUNTRIES.map((c) => c[1]);
  const countries = GEO_COUNTRIES.map((c) => c[0]);
  for (const [country, capital, continent, difficulty, hook, where] of GEO_COUNTRIES) {
    const [di, subj, subjCap, verb] = GEO_ARTICLE[country];
    const capD = pickDistractors(capitals, capital, 3, rand);
    if (capD.length === 3) {
      items.push(multipleChoiceItem({ id: `geografia-cap-${capital}`, subject: "geografia", topic: "capitali", difficulty, prompt: `Qual è la capitale ${di}?`, answer: capital, distractors: capD, explanation: `${capital} è la capitale ${di}. ${hook}` }, rand));
    }
    const couD = pickDistractors(countries, country, 3, rand);
    if (couD.length === 3) {
      items.push(multipleChoiceItem({ id: `geografia-stato-${capital}`, subject: "geografia", topic: "capitali", difficulty: Math.min(4, difficulty + 1), prompt: `Di quale Stato è capitale ${capital}?`, answer: country, distractors: couD, explanation: `${capital} è la capitale ${di}, che ${where}. ${hook}` }, rand));
    }
    const conD = pickDistractors(CONTINENTS, continent, 3, rand);
    if (conD.length === 3) {
      items.push(multipleChoiceItem({ id: `geografia-cont-${country}`, subject: "geografia", topic: "continenti", difficulty, prompt: `In quale continente ${verb} ${subj}?`, answer: continent, distractors: conD, explanation: `${subjCap} ${verb} in ${continent}: ${where}.` }, rand));
    }
  }
  for (const fact of GEO_FACTS) {
    items.push(multipleChoiceItem({ id: `geografia-${fact.topic}-${items.length}`, subject: "geografia", topic: fact.topic, difficulty: fact.difficulty, prompt: fact.prompt, answer: fact.answer, distractors: fact.distractors, explanation: fact.explanation }, rand));
  }
  items.push(...authoredMcItems("geografia", GEOGRAFIA_EXTRA, rand));
  return { schemaVersion: 1, subject: "geografia", generator: "geografia-authored-v1", items };
}

// ---------------------------------------------------------------------------
// Scienze (materia nuova). Fatti derivati da src/data/greenhouse.ts (bisogni
// reali delle piante) + nucleo curato di metodo/materia/viventi. Autorato,
// non inventato a caso: i valori piante vengono dal simulatore Phaser.
// ---------------------------------------------------------------------------

const SCIENZE_CORE = [
  { topic: "ambiente", difficulty: 2, prompt: "Che cos'è la biodiversità?", answer: "La varietà di specie viventi in un ambiente", distractors: ["Il numero totale di animali presenti","La quantità di piante di una specie","La superficie occupata da un bosco"], explanation: "Non conta quanti individui ci sono, ma quante specie diverse: un ambiente vario resiste meglio ai cambiamenti." },
  { topic: "ambiente", difficulty: 2, prompt: "Perché gli alberi sono importanti per l'aria che respiriamo?", answer: "Perché assorbono anidride carbonica e liberano ossigeno", distractors: ["Perché filtrano la pioggia prima che tocchi il suolo","Perché abbassano di molto la temperatura dell'aria","Perché fermano il vento quando soffia troppo forte"], explanation: "Con la fotosintesi prendono CO₂ e restituiscono ossigeno: sono il polmone di ogni ecosistema terrestre." },
  { topic: "ambiente", difficulty: 3, prompt: "Che cosa succede a un ecosistema se sparisce una specie chiave?", answer: "Può cambiare l'equilibrio di molte altre specie", distractors: ["Non cambia nulla per le altre specie","Le altre specie diventano più numerose","L'ambiente si ricostruisce in pochi giorni"], explanation: "Le specie sono collegate: togliere un predatore fa esplodere le sue prede, che a loro volta consumano più piante." },
  { topic: "ambiente", difficulty: 3, prompt: "Perché la plastica dispersa è un problema per il mare?", answer: "Perché impiega secoli a degradarsi", distractors: ["Perché rende l'acqua più salata","Perché fa aumentare la temperatura","Perché toglie ossigeno ai pesci"], explanation: "Si spezza in pezzi sempre più piccoli senza sparire: le microplastiche entrano nella catena alimentare." },
  { topic: "ambiente", difficulty: 3, prompt: "Che cos'è una fonte di energia rinnovabile?", answer: "Una fonte che si rigenera in tempi brevi", distractors: ["Una fonte che non costa niente","Una fonte che non produce energia","Una fonte che si trova sottoterra"], explanation: "Sole, vento e acqua si rinnovano di continuo; carbone e petrolio hanno impiegato milioni di anni a formarsi." },
  { topic: "ambiente", difficulty: 2, prompt: "Quale di queste è una fonte di energia rinnovabile?", answer: "Il vento", distractors: ["Il carbone","Il petrolio","Il gas naturale"], explanation: "Il vento soffia di continuo e non si esaurisce; le altre tre sono riserve fossili che finiscono." },
  { topic: "ambiente", difficulty: 4, prompt: "Perché fare la raccolta differenziata riduce l'uso di materie prime?", answer: "Perché il materiale riciclato sostituisce quello nuovo", distractors: ["Perché i rifiuti pesano complessivamente meno","Perché le discariche diventano più ordinate","Perché si producono meno rifiuti in totale"], explanation: "Una lattina riciclata risparmia l'alluminio che si sarebbe dovuto estrarre, e insieme l'energia per estrarlo." },
  { topic: "ambiente", difficulty: 3, prompt: "Che cos'è l'effetto serra?", answer: "Alcuni gas trattengono il calore vicino alla Terra", distractors: ["Il Sole scalda di più in certe stagioni","Le serre agricole riscaldano l'atmosfera","L'aria si riscalda salendo verso l'alto"], explanation: "Senza effetto serra la Terra sarebbe gelida: il problema nasce quando quei gas aumentano troppo e il calore trattenuto cresce." },
  { topic: "ambiente", difficulty: 4, prompt: "Perché il consumo di suolo preoccupa gli scienziati?", answer: "Perché il terreno fertile impiega secoli a formarsi", distractors: ["Perché il terreno cementificato costa di più","Perché le città diventano troppo affollate","Perché il suolo si sposta con il vento"], explanation: "Servono centinaia di anni per formare pochi centimetri di suolo fertile, e coprirlo di cemento lo rende irrecuperabile." },
  { topic: "ambiente", difficulty: 2, prompt: "Che cosa significa «specie a rischio di estinzione»?", answer: "Una specie che rischia di sparire per sempre", distractors: ["Una specie che vive in pochi luoghi","Una specie che si sposta ogni anno","Una specie che si riproduce lentamente"], explanation: "Estinzione significa che non ne resta più nessun individuo: è una perdita che non si può annullare." },
  { topic: "ambiente", difficulty: 3, prompt: "Perché l'acqua dolce è una risorsa preziosa?", answer: "Perché è una piccolissima parte dell'acqua terrestre", distractors: ["Perché è più pesante e densa dell'acqua salata","Perché si trova soltanto dentro i ghiacciai polari","Perché evapora molto più lentamente di quella salata"], explanation: "Quasi tutta l'acqua del pianeta è salata; di quella dolce, gran parte è ghiacciata: ne resta pochissima disponibile." },
  { topic: "ambiente", difficulty: 4, prompt: "Che cos'è una specie invasiva?", answer: "Una specie portata altrove che danneggia l'ambiente", distractors: ["Una specie che si riproduce molto in fretta","Una specie che caccia di notte in gruppo","Una specie che vive in ambienti diversi"], explanation: "Fuori dal suo ambiente d'origine può non avere predatori: si moltiplica senza freni e soffoca le specie locali." },
  { topic: "metodo", difficulty: 2, prompt: "Che cos'è un'ipotesi scientifica?", answer: "Una risposta possibile ancora da verificare", distractors: ["Una conclusione già dimostrata","Un'opinione personale del ricercatore","Una domanda a cui non si può rispondere"], explanation: "L'ipotesi si formula prima dell'esperimento, e l'esperimento serve proprio a metterla alla prova." },
  { topic: "metodo", difficulty: 3, prompt: "Perché in un esperimento si cambia una sola variabile per volta?", answer: "Per sapere quale ha causato il risultato", distractors: ["Per fare l'esperimento più in fretta","Per risparmiare materiale da laboratorio","Perché due variabili non si possono misurare"], explanation: "Se cambi tre cose insieme e qualcosa succede, non sai a quale delle tre attribuirlo." },
  { topic: "metodo", difficulty: 3, prompt: "A che cosa serve il gruppo di controllo?", answer: "A confrontare con ciò che accade senza intervento", distractors: ["A ripetere lo stesso esperimento due volte","A misurare gli strumenti prima dell'uso","A verificare i calcoli fatti alla fine"], explanation: "Senza un termine di paragone non sai se il cambiamento sarebbe avvenuto comunque." },
  { topic: "metodo", difficulty: 3, prompt: "Perché un esperimento va ripetuto più volte?", answer: "Perché un risultato singolo può essere un caso", distractors: ["Perché la prima volta si sbaglia sempre","Perché così si consuma meno materiale","Perché lo richiedono i regolamenti"], explanation: "La ripetizione distingue un effetto reale da una coincidenza: se succede una volta sola, non prova niente." },
  { topic: "metodo", difficulty: 4, prompt: "Un'ipotesi che non si può smentire in nessun modo è…", answer: "Inutile dal punto di vista scientifico", distractors: ["La più solida di tutte le ipotesi","Vera fino a prova contraria","Difficile ma comunque verificabile"], explanation: "Se nessun risultato possibile potrebbe contraddirla, l'esperimento non aggiunge nulla: non è un'ipotesi scientifica." },
  { topic: "metodo", difficulty: 3, prompt: "Che differenza c'è fra osservare e interpretare?", answer: "L'osservazione registra, l'interpretazione spiega", distractors: ["L'osservazione è più lenta da eseguire","L'interpretazione si fa con gli strumenti","Non c'è differenza fra le due cose"], explanation: "«La pianta è gialla» è un'osservazione; «le manca acqua» è un'interpretazione, e va verificata." },
  { topic: "metodo", difficulty: 4, prompt: "Perché gli scienziati pubblicano i loro dati?", answer: "Perché altri possano ripetere e controllare", distractors: ["Perché così diventano più famosi","Perché lo impongono le università","Perché i dati occupano troppo spazio"], explanation: "Un risultato che nessuno può verificare non entra nella conoscenza condivisa: la controllabilità è il cuore del metodo." },
  { topic: "metodo", difficulty: 2, prompt: "Che cos'è una variabile in un esperimento?", answer: "Un fattore che può cambiare e influenzare il risultato", distractors: ["Un errore commesso durante una misurazione","Uno strumento che si usa dentro il laboratorio","Un risultato che cambia a ogni ripetizione"], explanation: "Luce, acqua, temperatura: sono variabili. Sapere quali controllare è metà del lavoro." },
  { topic: "metodo", difficulty: 3, prompt: "Un esperimento smentisce l'ipotesi. Che cosa hai imparato?", answer: "Che quell'ipotesi non funziona, ed è un risultato", distractors: ["Niente: l'esperimento è tutto da rifare","Che gli strumenti usati erano sbagliati","Che la domanda di partenza era mal posta"], explanation: "Escludere una spiegazione restringe il campo: è progresso, anche se non è la risposta che si sperava." },
  { topic: "metodo", difficulty: 4, prompt: "Perché la misura di un solo studente vale meno di dieci misure?", answer: "Perché più misure riducono l'effetto degli errori", distractors: ["Perché uno studente misura più lentamente","Perché servono dieci strumenti diversi","Perché una misura sola non è mai leggibile"], explanation: "Ogni misura porta un piccolo errore casuale: mediando molte misure gli errori tendono a compensarsi." },
  { topic: "ecosistema", difficulty: 2, prompt: "Che cos'è un ecosistema?", answer: "L'insieme dei viventi e dell'ambiente in cui stanno", distractors: ["Il gruppo di animali di una stessa specie","La zona protetta di un parco naturale","L'insieme delle piante di una regione"], explanation: "Comprende sia gli esseri viventi sia l'acqua, il suolo, il clima: tutto ciò che interagisce in quel luogo." },
  { topic: "ecosistema", difficulty: 2, prompt: "In una catena alimentare, chi sono i produttori?", answer: "Le piante, che si fabbricano il nutrimento", distractors: ["Gli animali che cacciano le prede","I funghi che decompongono i resti","Gli animali che mangiano le piante"], explanation: "I produttori usano la luce del Sole per costruire sostanze nutritive: tutta l'energia della catena comincia da loro." },
  { topic: "ecosistema", difficulty: 3, prompt: "Che ruolo hanno i decompositori?", answer: "Trasformano i resti in sostanze riutilizzabili", distractors: ["Cacciano gli animali più deboli","Producono nutrimento con la luce","Trasportano i semi da un luogo all'altro"], explanation: "Funghi e batteri chiudono il ciclo: senza di loro le sostanze resterebbero bloccate nei resti e il suolo si esaurirebbe." },
  { topic: "ecosistema", difficulty: 3, prompt: "Perché in una catena alimentare i predatori sono meno numerosi delle prede?", answer: "Perché a ogni passaggio si perde molta energia", distractors: ["Perché i predatori sono animali più grandi","Perché le prede si riproducono in fretta","Perché i predatori vivono più a lungo"], explanation: "Solo una piccola parte dell'energia passa da un anello all'altro: in cima ne resta poca, e sostiene pochi individui." },
  { topic: "ecosistema", difficulty: 3, prompt: "Che cos'è una rete alimentare?", answer: "Più catene alimentari collegate fra loro", distractors: ["Una catena alimentare molto lunga","L'insieme dei soli animali carnivori","Il percorso che il cibo fa nel corpo"], explanation: "Nella realtà un animale mangia più cose e viene mangiato da più predatori: le catene si intrecciano in una rete." },
  { topic: "ecosistema", difficulty: 4, prompt: "Che cos'è la simbiosi?", answer: "Una convivenza stretta fra due specie diverse", distractors: ["La competizione fra due specie simili","La caccia praticata in gruppo","La migrazione stagionale di una specie"], explanation: "Può giovare a entrambi, come per le api e i fiori, oppure a uno solo: l'importante è che la convivenza sia stabile." },
  { topic: "ecosistema", difficulty: 3, prompt: "Che cos'è l'habitat di una specie?", answer: "Il luogo con le condizioni adatte a viverci", distractors: ["Il territorio che difende dai rivali","Il periodo dell'anno in cui si riproduce","Il gruppo con cui si sposta di solito"], explanation: "È l'indirizzo di casa: temperatura, cibo e riparo devono essere quelli che quella specie tollera." },
  { topic: "ecosistema", difficulty: 4, prompt: "Perché due specie che mangiano la stessa cosa raramente convivono a lungo?", answer: "Perché competono e una prevale sull'altra", distractors: ["Perché non riescono a comunicare fra loro","Perché si accoppiano fra specie diverse","Perché consumano l'ambiente troppo in fretta"], explanation: "Se la risorsa è la stessa e limitata, la specie che la sfrutta meglio finisce per escludere l'altra, o la costringe a cambiare abitudini." },
  { topic: "ecosistema", difficulty: 2, prompt: "Un animale che mangia solo piante si chiama…", answer: "Erbivoro", distractors: ["Carnivoro","Onnivoro","Decompositore"], explanation: "Erbivoro mangia vegetali, carnivoro carne, onnivoro entrambi. I decompositori si nutrono di resti." },
  { topic: "ecosistema", difficulty: 4, format: "numeric_input", prompt: "In una catena erba → cavalletta → rana → serpente, quanti passaggi di energia ci sono?", answer: "3", explanation: "Ogni freccia è un passaggio: erba-cavalletta, cavalletta-rana, rana-serpente. A ogni passaggio si perde energia." },
  { topic: "energia", difficulty: 2, prompt: "Che cosa dice il principio di conservazione dell'energia?", answer: "L'energia non si crea né si distrugge, si trasforma", distractors: ["L'energia diminuisce un poco a ogni passaggio","L'energia si può creare usando certe macchine","L'energia si conserva soltanto alle basse temperature"], explanation: "Cambia forma continuamente — movimento, calore, luce — ma la quantità totale resta la stessa." },
  { topic: "energia", difficulty: 3, prompt: "Quando accendi una lampadina, l'energia elettrica diventa…", answer: "Luce e calore", distractors: ["Solo luce, senza altro","Solo calore, senza luce","Movimento e suono"], explanation: "Nessuna trasformazione è perfetta: una parte dell'energia finisce sempre in calore, anche quando non serve." },
  { topic: "energia", difficulty: 3, prompt: "Che cos'è l'energia potenziale?", answer: "L'energia che un corpo ha per la sua posizione", distractors: ["L'energia che un corpo ha per il movimento","L'energia che si produce con il calore","L'energia che un corpo può ancora creare"], explanation: "Un sasso in cima a una collina ha energia proprio perché sta in alto: appena può, la trasforma in movimento." },
  { topic: "energia", difficulty: 3, prompt: "Da dove viene quasi tutta l'energia che usiamo sulla Terra?", answer: "Dal Sole, direttamente o indirettamente", distractors: ["Dal calore interno del pianeta","Dal movimento delle maree","Dalle centrali costruite dall'uomo"], explanation: "Il vento nasce dal Sole che scalda l'aria; il petrolio da piante antiche cresciute grazie al Sole. Perfino il cibo." },
  { topic: "energia", difficulty: 4, prompt: "Perché nessuna macchina può funzionare all'infinito da sola?", answer: "Perché parte dell'energia si disperde in calore", distractors: ["Perché i materiali si consumano subito","Perché manca sempre qualcuno che la accenda","Perché l'energia si crea troppo lentamente"], explanation: "Attriti e resistenze trasformano energia utile in calore disperso: non torna indietro, e la macchina si ferma." },
  { topic: "energia", difficulty: 2, prompt: "Che cos'è l'energia cinetica?", answer: "L'energia che ha un corpo perché si muove", distractors: ["L'energia che ha un corpo perché è in alto","L'energia che un corpo emette come calore","L'energia contenuta negli alimenti"], explanation: "Più un corpo è veloce e pesante, più energia cinetica ha: è per questo che un'auto veloce frena in più spazio." },
  { topic: "energia", difficulty: 4, prompt: "In una centrale idroelettrica, quale trasformazione avviene per prima?", answer: "L'acqua in alto diventa acqua in movimento", distractors: ["L'acqua diventa direttamente elettricità","Il calore dell'acqua diventa movimento","Il movimento diventa energia chimica"], explanation: "L'acqua cade e acquista velocità, poi fa girare la turbina, e solo alla fine l'alternatore produce elettricità." },
  { topic: "energia", difficulty: 3, prompt: "Che tipo di energia contiene il cibo che mangi?", answer: "Energia chimica", distractors: ["Energia cinetica","Energia elettrica","Energia luminosa"], explanation: "È immagazzinata nei legami fra le molecole: il corpo li spezza e ne ricava movimento e calore." },
  { topic: "energia", difficulty: 3, prompt: "Perché una pallina che rimbalza non torna mai all'altezza di partenza?", answer: "Perché parte dell'energia si disperde a ogni urto", distractors: ["Perché la gravità aumenta a ogni rimbalzo","Perché la pallina diventa più leggera","Perché l'aria la spinge verso il basso"], explanation: "A ogni rimbalzo un po' di energia diventa calore e suono: quella che resta non basta a risalire fino in cima." },
  { topic: "energia", difficulty: 4, format: "numeric_input", prompt: "Quante trasformazioni di energia ci sono in «pila → lampadina accesa»?", answer: "2", explanation: "Chimica in elettrica dentro la pila, elettrica in luce e calore nella lampadina: due passaggi." },
  { topic: "terra-universo", difficulty: 2, format: "numeric_input", prompt: "Quanto tempo impiega la Terra a girare su sé stessa?", answer: "24", explanation: "Ventiquattro ore: è la rotazione, e produce il giorno e la notte." },
  { topic: "terra-universo", difficulty: 2, prompt: "Che cosa causa l'alternarsi del giorno e della notte?", answer: "La rotazione della Terra su sé stessa", distractors: ["Il movimento della Terra attorno al Sole","Lo spostamento della Luna nel cielo","L'inclinazione dell'asse terrestre"], explanation: "Il Sole non si sposta: siamo noi a girare, e ogni punto passa alternativamente in luce e in ombra." },
  { topic: "terra-universo", difficulty: 3, prompt: "Che cosa causa le stagioni?", answer: "L'inclinazione dell'asse terrestre", distractors: ["La distanza variabile dal Sole","La rotazione della Terra su sé stessa","Il passaggio della Luna davanti al Sole"], explanation: "L'asse inclinato fa arrivare i raggi più o meno obliqui secondo il periodo: non è la distanza dal Sole a decidere." },
  { topic: "terra-universo", difficulty: 3, prompt: "Perché vediamo la Luna cambiare forma?", answer: "Perché ne vediamo illuminata una parte diversa", distractors: ["Perché la Luna cambia davvero forma","Perché a volte è coperta dalle nuvole","Perché si allontana e si avvicina"], explanation: "La Luna è sempre una sfera per metà illuminata: cambia solo quanta di quella metà è rivolta verso di noi." },
  { topic: "terra-universo", difficulty: 3, prompt: "Che cos'è una galassia?", answer: "Un enorme insieme di stelle, gas e polveri", distractors: ["Un gruppo di pianeti attorno a una stella","Una stella molto più grande delle altre","Lo spazio vuoto fra due sistemi solari"], explanation: "La nostra si chiama Via Lattea e contiene centinaia di miliardi di stelle: il Sole è una di quelle." },
  { topic: "terra-universo", difficulty: 4, prompt: "Perché di giorno non vediamo le stelle?", answer: "Perché la luce del Sole diffusa nell'aria le copre", distractors: ["Perché le stelle si spengono di giorno","Perché si spostano dietro il Sole","Perché la Terra le nasconde con l'ombra"], explanation: "Le stelle ci sono anche di giorno: è l'atmosfera illuminata a diventare troppo luminosa perché si vedano." },
  { topic: "terra-universo", difficulty: 3, prompt: "Quale pianeta è il più vicino al Sole?", answer: "Mercurio", distractors: ["Venere","Nettuno","Saturno"], explanation: "L'ordine è Mercurio, Venere, Terra, Marte: Mercurio è il primo e compie il giro più breve." },
  { topic: "terra-universo", difficulty: 4, prompt: "Che cos'è un'eclissi di Sole?", answer: "La Luna si mette fra la Terra e il Sole", distractors: ["L'ombra della Terra cade sopra la Luna piena","Il Sole si spegne del tutto per qualche minuto","Una nube molto densa copre il Sole per un istante"], explanation: "L'ombra della Luna cade sulla Terra: dove passa, il Sole appare coperto. Nell'eclissi di Luna è la Terra a fare ombra." },
  { topic: "terra-universo", difficulty: 2, format: "numeric_input", prompt: "Quanti pianeti ci sono nel Sistema Solare?", answer: "8", explanation: "Otto: Mercurio, Venere, Terra, Marte, Giove, Saturno, Urano, Nettuno. Plutone dal 2006 è un pianeta nano." },
  { topic: "materia", difficulty: 2, prompt: "In quale stato la materia ha forma e volume propri?", answer: "Solido", distractors: ["Liquido","Gassoso","Nessuno dei tre"], explanation: "Il solido tiene la sua forma; il liquido prende quella del recipiente; il gas riempie tutto lo spazio disponibile." },
  { topic: "materia", difficulty: 3, prompt: "Come si chiama il passaggio da liquido a gassoso?", answer: "Evaporazione", distractors: ["Condensazione","Solidificazione","Fusione"], explanation: "La condensazione fa il contrario; la fusione è da solido a liquido." },
  { topic: "materia", difficulty: 3, prompt: "Che cosa succede alle particelle quando un solido si scalda e fonde?", answer: "Si muovono di più e perdono la posizione fissa", distractors: ["Diventano più grandi e pesanti","Si moltiplicano formando altra materia","Si fermano completamente sul posto"], explanation: "Il calore aumenta il movimento: superata una certa soglia le particelle non restano più al loro posto e il solido diventa liquido." },
  { topic: "materia", difficulty: 3, prompt: "Che cos'è un miscuglio?", answer: "Più sostanze mescolate ma non combinate", distractors: ["Una sostanza pura molto fine","Due sostanze legate chimicamente","Un liquido che contiene solo acqua"], explanation: "Nel miscuglio le sostanze restano quelle di prima e spesso si possono separare: sabbia e sale, per esempio." },
  { topic: "materia", difficulty: 4, prompt: "Perché l'acqua ghiacciata occupa più spazio dell'acqua liquida?", answer: "Perché le molecole si dispongono più distanziate", distractors: ["Perché il freddo aggiunge nuova materia","Perché il ghiaccio pesa più dell'acqua","Perché entra aria fra le molecole"], explanation: "Congelandosi le molecole formano una struttura ordinata e più aperta: stessa materia, più volume. Per questo il ghiaccio galleggia." },
  { topic: "materia", difficulty: 4, prompt: "Come si può separare il sale dall'acqua salata?", answer: "Facendo evaporare l'acqua", distractors: ["Filtrando con un panno fitto","Raffreddando fino a congelare","Mescolando molto energicamente"], explanation: "Il sale è sciolto, quindi il filtro non lo trattiene: bisogna far andare via l'acqua e lasciarlo depositato." },
  { topic: "materia", difficulty: 3, prompt: "Che cos'è la densità di un materiale?", answer: "Quanta massa c'è in un certo volume", distractors: ["Quanto pesa un oggetto in totale","Quanto è duro un materiale al tatto","Quanto spazio occupa un oggetto"], explanation: "Un chilo di piombo e uno di piume pesano uguale, ma il piombo sta in molto meno spazio: ha densità maggiore." },
  { topic: "materia", difficulty: 2, prompt: "In quale stato le particelle sono più libere di muoversi?", answer: "Gassoso", distractors: ["Solido","Liquido","Sono uguali in tutti"], explanation: "Nel gas le particelle sono lontane e veloci: per questo un gas riempie tutto lo spazio disponibile." },
  { topic: "corpo", difficulty: 2, prompt: "Che cosa trasporta l'ossigeno dai polmoni al resto del corpo?", answer: "Il sangue", distractors: ["I nervi","I muscoli","La linfa"], explanation: "L'ossigeno passa negli alveoli, entra nel sangue e viaggia nelle arterie fino a ogni cellula." },
  { topic: "corpo", difficulty: 2, prompt: "A che cosa servono i polmoni?", answer: "A scambiare ossigeno e anidride carbonica", distractors: ["A filtrare il sangue dalle scorie","A digerire il cibo che mangiamo","A produrre le cellule del sangue"], explanation: "Nell'inspirazione entra ossigeno e nell'espirazione esce anidride carbonica: lo scambio avviene negli alveoli." },
  { topic: "corpo", difficulty: 3, prompt: "Dove comincia la digestione?", answer: "In bocca, con la masticazione e la saliva", distractors: ["Nello stomaco, con i succhi gastrici","Nell'intestino, con l'assorbimento","Nell'esofago, durante la deglutizione"], explanation: "La saliva contiene già sostanze che cominciano a smontare gli amidi: masticare bene aiuta tutto il resto." },
  { topic: "corpo", difficulty: 3, prompt: "Che cosa fa lo scheletro oltre a sostenere il corpo?", answer: "Protegge gli organi e produce cellule del sangue", distractors: ["Digerisce le sostanze più dure del cibo","Regola la temperatura di tutto il corpo","Trasporta i segnali nervosi al cervello"], explanation: "Cranio e costole fanno da armatura, e dentro le ossa lunghe il midollo produce le cellule del sangue." },
  { topic: "corpo", difficulty: 3, prompt: "Come si muovono le ossa?", answer: "Grazie ai muscoli che le tirano", distractors: ["Perché si allungano da sole","Grazie al sangue che le spinge","Perché le articolazioni si gonfiano"], explanation: "I muscoli si accorciano e tirano il tendine attaccato all'osso: le ossa da sole non possono muoversi." },
  { topic: "corpo", difficulty: 4, prompt: "Perché quando corri il respiro accelera?", answer: "Perché i muscoli chiedono più ossigeno", distractors: ["Perché il cuore diventa più grande","Perché aumenta la temperatura esterna","Perché i polmoni si riempiono d'acqua"], explanation: "Lavorando, i muscoli consumano più ossigeno e producono più anidride carbonica: respiro e battito aumentano per stare al passo." },
  { topic: "corpo", difficulty: 3, prompt: "Qual è il compito dei reni?", answer: "Filtrare il sangue e produrre l'urina", distractors: ["Pompare il sangue nelle arterie","Assorbire i nutrienti dal cibo","Immagazzinare le riserve di zucchero"], explanation: "Ripuliscono il sangue dalle sostanze di scarto, che vengono eliminate con l'urina." },
  { topic: "corpo", difficulty: 4, prompt: "Perché è importante dormire abbastanza?", answer: "Perché durante il sonno il corpo si ripara e consolida la memoria", distractors: ["Perché durante la notte si consuma molto meno cibo","Perché il cuore si ferma qualche istante per riposare","Perché i muscoli riescono a crescere soltanto al buio"], explanation: "Nel sonno avvengono riparazioni dei tessuti e il cervello riorganizza ciò che ha imparato durante il giorno." },
  { topic: "viventi", difficulty: 2, prompt: "Che cos'hanno in comune tutti gli esseri viventi?", answer: "Nascono, crescono, si riproducono e muoiono", distractors: ["Si muovono da un posto all'altro","Hanno tutti bisogno di luce solare","Sono formati da molte cellule"], explanation: "Anche una pianta, che non si sposta, compie il ciclo vitale. È quello a definire un vivente." },
  { topic: "viventi", difficulty: 3, prompt: "Qual è l'unità di base di tutti gli esseri viventi?", answer: "La cellula", distractors: ["L'organo","Il tessuto","La molecola"], explanation: "Ogni vivente è fatto di cellule: alcuni ne hanno una sola, altri miliardi." },
  { topic: "viventi", difficulty: 3, prompt: "Che differenza c'è fra un vertebrato e un invertebrato?", answer: "Il vertebrato ha una colonna vertebrale", distractors: ["Il vertebrato è sempre più grande","L'invertebrato vive soltanto in acqua","L'invertebrato non ha organi interni"], explanation: "La colonna vertebrale è lo scheletro interno: la maggior parte degli animali, in realtà, ne è priva." },
  { topic: "viventi", difficulty: 4, prompt: "Che cos'è un adattamento?", answer: "Una caratteristica che aiuta a vivere in un ambiente", distractors: ["Un cambiamento deciso dall'animale stesso","Una malattia che si trasmette ai figli","Uno spostamento verso un clima migliore"], explanation: "Il collo lungo della giraffa o le foglie a spina del cactus: caratteristiche selezionate perché in quell'ambiente funzionano." },
  { topic: "viventi", difficulty: 3, prompt: "Perché i funghi non sono considerati piante?", answer: "Perché non fanno la fotosintesi", distractors: ["Perché crescono soltanto all'ombra","Perché non hanno bisogno di acqua","Perché si spostano lentamente nel suolo"], explanation: "Le piante si costruiscono il nutrimento con la luce; i funghi lo assorbono da materia già esistente, viva o morta." },
  // --- Metodo scientifico (dal fare al ragionare sul perché) ---
  { topic: "metodo", difficulty: 1, prompt: "In un esperimento controllato, quante variabili cambi per volta?", answer: "Una sola", distractors: ["Tutte insieme", "Almeno tre", "Nessuna"], explanation: "Cambiando una sola variabile capisci quale causa l'effetto." },
  { topic: "metodo", difficulty: 2, prompt: "Cosa distingue un'ipotesi da una conclusione?", answer: "L'ipotesi è una previsione da verificare", distractors: ["Sono la stessa cosa", "L'ipotesi arriva dopo i dati", "La conclusione precede l'esperimento"], explanation: "Prima l'ipotesi (previsione), poi i dati, infine la conclusione." },
  { topic: "metodo", difficulty: 3, prompt: "A cosa serve un 'gruppo di controllo' in un esperimento?", answer: "A confrontare con qualcosa che non è stato cambiato", distractors: ["A rendere l'esperimento molto più lungo del solito", "A cambiare più cose insieme e vedere", "A saltare qualche misura per fare prima"], explanation: "Il gruppo di controllo mostra cosa succede senza la variabile che stai studiando." },
  { topic: "metodo", difficulty: 4, prompt: "Cambi luce E acqua insieme e la pianta cresce di più. Cosa puoi concludere?", answer: "Non sai quale delle due abbia agito", distractors: ["È stata solo la luce", "È stata solo l'acqua", "Sono state entrambe di sicuro"], explanation: "Cambiando due variabili insieme non puoi isolare la causa: vanno provate separatamente." },
  // --- Materia e stati (aggiungere un passaggio di stato alla volta) ---
  { topic: "materia", difficulty: 1, prompt: "Quali sono i tre stati principali della materia?", answer: "Solido, liquido, gassoso", distractors: ["Caldo, freddo, tiepido", "Duro, molle, liquido", "Pieno, vuoto, misto"], explanation: "Sono le stesse particelle, legate in modo diverso: ferme e strette nel solido, vicine ma libere di scorrere nel liquido, lontane e indipendenti nel gassoso." },
  { topic: "materia", difficulty: 1, prompt: "Come si chiama l'acqua allo stato solido?", answer: "Ghiaccio", distractors: ["Vapore", "Rugiada", "Nuvola"], explanation: "L'acqua solida è il ghiaccio; allo stato gassoso è vapore." },
  { topic: "materia", difficulty: 2, prompt: "Come si chiama il passaggio dell'acqua da liquido a vapore?", answer: "Evaporazione", distractors: ["Fusione", "Solidificazione", "Condensazione"], explanation: "Nell'evaporazione il liquido diventa gas; nella condensazione avviene il contrario." },
  { topic: "materia", difficulty: 2, prompt: "Come si chiama il passaggio da gas (vapore) a liquido?", answer: "Condensazione", distractors: ["Evaporazione", "Fusione", "Sublimazione"], explanation: "La condensazione forma le goccioline: è il contrario dell'evaporazione." },
  { topic: "materia", difficulty: 3, prompt: "Come si chiama il passaggio da solido a liquido?", answer: "Fusione", distractors: ["Evaporazione", "Sublimazione", "Solidificazione"], explanation: "Il ghiaccio che diventa acqua è fusione." },
  { topic: "materia", difficulty: 4, prompt: "Come si chiama il passaggio diretto da solido a gas, senza passare per il liquido?", answer: "Sublimazione", distractors: ["Fusione", "Evaporazione", "Condensazione"], explanation: "Nella sublimazione un solido diventa gas direttamente (es. la neve che 'sparisce' senza sciogliersi)." },
  // --- Esseri viventi ---
  { topic: "viventi", difficulty: 1, prompt: "Quale parte della pianta assorbe l'acqua dal terreno?", answer: "Le radici", distractors: ["I fiori", "Le foglie", "I frutti"], explanation: "Le radici assorbono acqua e sali minerali dal suolo." },
  { topic: "viventi", difficulty: 1, prompt: "Di cosa hanno bisogno le piante per fare la fotosintesi?", answer: "Luce, acqua e anidride carbonica", distractors: ["Soltanto acqua abbondante", "Buio completo e freddo", "Soltanto terra da giardino"], explanation: "Con luce, acqua e CO2 la pianta produce nutrimento e ossigeno." },
  { topic: "viventi", difficulty: 2, prompt: "Quale gas rilasciano le piante durante la fotosintesi?", answer: "Ossigeno", distractors: ["Anidride carbonica", "Azoto", "Idrogeno"], explanation: "Le piante assorbono CO2 e liberano ossigeno." },
  { topic: "viventi", difficulty: 2, prompt: "Come si chiamano gli animali che si nutrono solo di piante?", answer: "Erbivori", distractors: ["Carnivori", "Onnivori", "Predatori"], explanation: "Gli erbivori mangiano vegetali; i carnivori altri animali." },
  { topic: "viventi", difficulty: 3, prompt: "Come si chiamano gli animali che mangiano sia piante sia altri animali?", answer: "Onnivori", distractors: ["Erbivori", "Carnivori", "Decompositori"], explanation: "Gli onnivori (come l'orso o l'uomo) si nutrono di tutto." },
  { topic: "viventi", difficulty: 4, prompt: "Come si chiama il processo con cui gli esseri viventi ricavano energia usando l'ossigeno?", answer: "Respirazione cellulare", distractors: ["Fotosintesi", "Digestione lenta", "Evaporazione rapida"], explanation: "La respirazione cellulare libera l'energia del cibo; la fotosintesi invece la immagazzina nelle piante." },
  // --- Ecosistema ---
  { topic: "ecosistema", difficulty: 2, prompt: "In una catena alimentare, chi mangia gli erbivori?", answer: "I carnivori", distractors: ["Le piante", "Il Sole", "I produttori"], explanation: "I carnivori si nutrono di altri animali, come gli erbivori." },
  { topic: "ecosistema", difficulty: 3, prompt: "In una catena alimentare, chi produce il proprio nutrimento?", answer: "Le piante (produttori)", distractors: ["I predatori (carnivori)", "I decompositori", "Gli erbivori"], explanation: "Le piante sono i produttori: creano nutrimento con la fotosintesi." },
  { topic: "ecosistema", difficulty: 3, prompt: "Come si chiamano gli organismi (funghi, batteri) che decompongono i resti dei viventi?", answer: "Decompositori", distractors: ["Produttori", "Predatori", "Erbivori"], explanation: "I decompositori riciclano la materia, restituendo sostanze utili al terreno." },
  { topic: "ecosistema", difficulty: 4, prompt: "Se in un bosco sparissero tutte le piante, cosa accadrebbe agli erbivori?", answer: "Diminuirebbero per mancanza di cibo", distractors: ["Aumenterebbero di numero", "Non cambierebbe proprio nulla", "Diventerebbero tutti carnivori"], explanation: "Senza produttori manca la base della catena alimentare: tutti gli altri ne risentono." },
  // --- Corpo umano ---
  { topic: "corpo", difficulty: 1, prompt: "Quale organo ci permette di pensare e comandare il corpo?", answer: "Il cervello", distractors: ["Il cuore", "Lo stomaco", "I muscoli"], explanation: "Riceve i segnali dai sensi e manda ordini ai muscoli in continuo: lavora anche mentre dormi." },
  { topic: "corpo", difficulty: 2, prompt: "A cosa serve lo scheletro?", answer: "A sostenere e proteggere il corpo", distractors: ["A digerire il cibo più in fretta", "A respirare più a lungo", "A vedere meglio i colori"], explanation: "Le ossa sostengono il corpo e proteggono gli organi (il cranio protegge il cervello)." },
  { topic: "corpo", difficulty: 2, prompt: "Quale organo pompa il sangue nel corpo?", answer: "Il cuore", distractors: ["I polmoni", "Il fegato", "Lo stomaco"], explanation: "È un muscolo che si contrae da solo, circa centomila volte al giorno, senza che tu debba pensarci." },
  { topic: "corpo", difficulty: 3, prompt: "In quale organo avviene lo scambio di ossigeno con il sangue?", answer: "I polmoni", distractors: ["Il cuore", "I reni", "L'intestino"], explanation: "Nei polmoni il sangue prende ossigeno e cede anidride carbonica." },
  { topic: "corpo", difficulty: 4, prompt: "In quale organo il cibo digerito viene assorbito nel sangue?", answer: "L'intestino", distractors: ["I polmoni", "Il cuore", "I reni"], explanation: "Nell'intestino le sostanze nutritive passano nel sangue." },
  // --- Energia (nuovo topic) ---
  { topic: "energia", difficulty: 2, prompt: "Da dove arriva quasi tutta l'energia che riscalda la Terra?", answer: "Dal Sole", distractors: ["Dalla Luna", "Dal vento", "Dalle stelle lontane"], explanation: "Il Sole è la fonte principale di luce e calore per la Terra." },
  { topic: "energia", difficulty: 3, prompt: "Come si chiama l'energia prodotta dal vento che fa girare le pale?", answer: "Energia eolica", distractors: ["Energia idroelettrica", "Energia solare", "Energia nucleare"], explanation: "L'energia eolica sfrutta il vento; quella idroelettrica l'acqua che scorre." },
  { topic: "energia", difficulty: 3, prompt: "L'energia dell'acqua che scorre e fa girare le turbine si chiama…", answer: "Energia idroelettrica", distractors: ["Energia eolica", "Energia solare", "Energia geotermica"], explanation: "Le dighe sfruttano l'acqua in movimento per produrre elettricità." },
  { topic: "energia", difficulty: 4, prompt: "Quali fonti di energia non si esauriscono e inquinano poco?", answer: "Sole, vento e acqua (rinnovabili)", distractors: ["Carbone e petrolio estratti", "Gas e benzina dei motori", "Plastica bruciata negli inceneritori"], explanation: "Le fonti rinnovabili si rigenerano e sono più pulite dei combustibili fossili." },
  // --- Terra e universo (nuovo topic) ---
  { topic: "terra-universo", difficulty: 1, prompt: "Attorno a cosa gira la Terra?", answer: "Il Sole", distractors: ["La Luna", "Marte", "Una cometa"], explanation: "La Terra orbita intorno al Sole in circa un anno." },
  { topic: "terra-universo", difficulty: 2, prompt: "Come si chiama il satellite naturale della Terra?", answer: "La Luna", distractors: ["Marte", "Il Sole", "Venere"], explanation: "Le mostra sempre la stessa faccia, perché impiega lo stesso tempo a girare su di sé e attorno a noi." },
  { topic: "terra-universo", difficulty: 2, prompt: "Cosa provoca l'alternarsi del giorno e della notte?", answer: "La rotazione della Terra su se stessa", distractors: ["La Terra che gira intorno al Sole", "Le nuvole", "La Luna che si sposta"], explanation: "Ruotando su se stessa, ogni punto della Terra si affaccia al Sole e poi all'ombra." },
  { topic: "terra-universo", difficulty: 4, prompt: "Cosa provoca soprattutto l'alternarsi delle stagioni?", answer: "L'inclinazione della Terra mentre gira intorno al Sole", distractors: ["La distanza che cambia dalla Luna", "Il vento che soffia da nord per tutto l'anno", "Le maree provocate dalla Luna"], explanation: "L'asse inclinato fa arrivare i raggi del Sole più o meno diretti nei vari periodi dell'anno." },
  // --- Ambiente (nuovo topic) ---
  { topic: "ambiente", difficulty: 1, prompt: "Cosa dovremmo fare con carta, plastica e vetro per aiutare l'ambiente?", answer: "Fare la raccolta differenziata", distractors: ["Buttarli tutti nello stesso sacco", "Bruciarli nel cortile di casa", "Lasciarli per terra dove capita"], explanation: "Separare i rifiuti permette di riciclarli e sprecare meno risorse." },
  { topic: "ambiente", difficulty: 2, prompt: "Perché è importante non sprecare l'acqua?", answer: "È una risorsa preziosa e limitata", distractors: ["Perché è pesante da trasportare", "Perché è di colore trasparente", "Non è importante, ce n'è tanta"], explanation: "L'acqua dolce pulita è limitata: va usata con attenzione." },
  { topic: "ambiente", difficulty: 3, prompt: "Come si chiama l'aumento della temperatura del pianeta legato anche ai gas prodotti dall'uomo?", answer: "Riscaldamento globale", distractors: ["Effetto arcobaleno", "Effetto marea", "Effetto eco"], explanation: "L'eccesso di gas serra trattiene più calore e riscalda il pianeta." },
  { topic: "ambiente", difficulty: 2, format: "short_answer", prompt: "Come si chiama la trasformazione dei rifiuti in materiali di nuovo utilizzabili?", answer: "riciclo", accept: ["riciclaggio"], explanation: "Ridurre viene prima di riciclare: quello che non si produce non va nemmeno trattato." },
  { topic: "ambiente", difficulty: 3, format: "short_answer", prompt: "Come si chiama una sostanza che sporca e danneggia aria, acqua o suolo?", answer: "inquinante", explanation: "Molti inquinanti non si vedono: si misurano." },
  { topic: "ecosistema", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'insieme degli esseri viventi e dell'ambiente in cui vivono, considerati insieme?", answer: "ecosistema", explanation: "Le due parti non si studiano separate: cambiando l'ambiente cambiano i viventi, e viceversa." },
  { topic: "ecosistema", difficulty: 2, format: "short_answer", prompt: "Come si chiamano gli organismi che si nutrono di altri esseri viventi?", answer: "consumatori", explanation: "Non producono il proprio cibo: lo prendono da chi lo ha fabbricato o da chi lo ha già mangiato." },
  { topic: "ecosistema", difficulty: 3, format: "short_answer", prompt: "Come si chiamano gli organismi che trasformano i resti in sostanze minerali?", answer: "decompositori", explanation: "Senza di loro le sostanze resterebbero bloccate nei resti e il ciclo si fermerebbe." },
  { topic: "ecosistema", difficulty: 2, format: "short_answer", prompt: "Come si chiama la catena che collega chi mangia e chi è mangiato?", answer: "catena alimentare", accept: ["catena trofica"], explanation: "Ogni anello passa al successivo solo una parte dell'energia ricevuta." },
  { topic: "metodo", difficulty: 2, format: "short_answer", prompt: "Come si chiama la supposizione che l'esperimento deve verificare?", answer: "ipotesi", explanation: "Si formula prima di guardare i risultati, altrimenti si finisce per confermarsi da soli." },
  { topic: "metodo", difficulty: 3, format: "short_answer", prompt: "Come si chiama la prova di confronto in cui non si cambia niente?", answer: "controllo", accept: ["gruppo di controllo"], explanation: "Senza il confronto non si sa se l'effetto viene dalla causa studiata o sarebbe successo comunque." },
  { topic: "metodo", difficulty: 1, format: "short_answer", prompt: "Come si chiama lo strumento che ingrandisce ciò che l'occhio non riesce a vedere?", answer: "microscopio", explanation: "Ha aperto un mondo intero: le cellule si sono scoperte così." },
  { topic: "energia", difficulty: 2, format: "short_answer", prompt: "Come si chiama una fonte di energia che non si esaurisce, come il vento o il sole?", answer: "rinnovabile", accept: ["fonte rinnovabile"], explanation: "Rinnovabile non vuol dire senza impatto: vuol dire che la fonte si ricostituisce." },
  { topic: "energia", difficulty: 3, format: "short_answer", prompt: "Come si chiama il processo con cui le piante usano la luce per fabbricare zuccheri?", answer: "fotosintesi", accept: ["fotosintesi clorofilliana"], explanation: "Prendono anidride carbonica e acqua e restituiscono ossigeno: è l'inizio di quasi tutte le catene alimentari." },
  { topic: "terra-universo", difficulty: 1, format: "short_answer", prompt: "Come si chiama il movimento della Terra attorno al proprio asse?", answer: "rotazione", explanation: "Dura ventiquattro ore e produce il giorno e la notte." },
  { topic: "terra-universo", difficulty: 1, format: "short_answer", prompt: "Come si chiama il movimento della Terra attorno al Sole?", answer: "rivoluzione", explanation: "Dura un anno; insieme all'inclinazione dell'asse produce le stagioni." },
  { topic: "terra-universo", difficulty: 1, format: "short_answer", prompt: "Come si chiama la stella attorno a cui gira la Terra?", answer: "Sole", explanation: "È una stella come tante altre: ci sembra enorme solo perché è vicinissima." },
  { topic: "terra-universo", difficulty: 2, format: "short_answer", prompt: "Come si chiama lo strato di aria che avvolge la Terra?", answer: "atmosfera", explanation: "Trattiene calore e ferma gran parte delle radiazioni: senza, la vita in superficie non ci sarebbe." },
  { topic: "materia", difficulty: 2, format: "short_answer", prompt: "Come si chiama il passaggio dallo stato gassoso a quello liquido?", answer: "condensazione", explanation: "Le gocce sul vetro freddo si formano così: il vapore dell'aria si raffredda e condensa." },
  { topic: "materia", difficulty: 3, format: "short_answer", prompt: "Come si chiama il miscuglio in cui una sostanza si scioglie completamente in un'altra?", answer: "soluzione", explanation: "Se dopo aver mescolato non distingui più le parti, è una soluzione." },
  { topic: "materia", difficulty: 3, format: "short_answer", prompt: "Come si chiama la più piccola parte di una sostanza che ne conserva le proprietà?", answer: "molecola", explanation: "Spezzando ancora si ottengono atomi, ma la sostanza non è più quella." },
  { topic: "corpo", difficulty: 1, format: "short_answer", prompt: "Come si chiama l'organo che pompa il sangue in tutto il corpo?", answer: "cuore", explanation: "Batte senza che tu debba pensarci, circa centomila volte al giorno." },
  { topic: "corpo", difficulty: 1, format: "short_answer", prompt: "Come si chiamano gli organi in cui il sangue prende ossigeno dall'aria?", answer: "polmoni", explanation: "Lo scambio avviene negli alveoli, minuscole sacche con una superficie enorme." },
  { topic: "corpo", difficulty: 1, format: "short_answer", prompt: "Come si chiama l'organo che comanda i movimenti e il pensiero?", answer: "cervello", explanation: "Riceve informazioni dai sensi e manda ordini ai muscoli, in continuo." },
  { topic: "corpo", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'insieme delle ossa che sostiene il corpo?", answer: "scheletro", explanation: "Sostiene, protegge gli organi e dà ai muscoli un punto su cui fare forza." },
  { topic: "viventi", difficulty: 1, format: "short_answer", prompt: "Come si chiama la parte della pianta che assorbe acqua dal terreno?", answer: "radice", accept: ["radici"], explanation: "Assorbe e insieme ancora la pianta al suolo." },
  { topic: "viventi", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'unità più piccola di cui sono fatti tutti gli esseri viventi?", answer: "cellula", explanation: "Alcuni esseri viventi ne hanno una sola; noi qualche decina di migliaia di miliardi." },
  { topic: "viventi", difficulty: 1, format: "short_answer", prompt: "Come si chiamano gli animali che allattano i propri piccoli?", answer: "mammiferi", explanation: "Allattano, hanno peli e temperatura costante: anche la balena è un mammifero." },
  { topic: "ambiente", difficulty: 1, format: "short_answer", prompt: "Come si chiama il contenitore in cui si buttano carta e cartone separati dal resto?", answer: "carta", accept: ["bidone della carta", "contenitore della carta"], explanation: "Ogni materiale ha il suo contenitore: mescolarli manda tutto in discarica." },
  { topic: "viventi", difficulty: 1, format: "short_answer", prompt: "Come si chiama la parte colorata del fiore che attira gli insetti?", answer: "petalo", accept: ["petali", "i petali"], explanation: "Colore e profumo servono a farsi trovare da chi trasporta il polline." },
  { topic: "corpo", difficulty: 1, format: "short_answer", prompt: "Come si chiama l'organo con cui si sente il suono?", answer: "orecchio", accept: ["orecchie", "l'orecchio"], explanation: "Raccoglie le vibrazioni dell'aria e le trasforma in segnali per il cervello." },
  { topic: "terra-universo", difficulty: 1, format: "short_answer", prompt: "Come si chiamano i corpi celesti che girano attorno al Sole, come la Terra?", answer: "pianeti", accept: ["pianeta", "i pianeti"], explanation: "Non brillano di luce propria: riflettono quella del Sole." },
  { topic: "ambiente", difficulty: 1, prompt: "Perché ridurre i rifiuti conta più che riciclarli?", answer: "Perché un rifiuto che non nasce non va nemmeno trattato", distractors: ["Perché il riciclo funziona bene soltanto con la carta e il vetro", "Perché i rifiuti riciclati costano di più di quelli nuovi", "Perché riciclare è vietato per la maggior parte dei materiali"], explanation: "Riciclare consuma energia e acqua: meglio non produrre l'oggetto inutile." },
  { topic: "viventi", difficulty: 1, prompt: "Che cosa distingue un essere vivente da un sasso?", answer: "Si nutre, cresce e può riprodursi", distractors: ["Si muove da solo da un posto all'altro durante il giorno", "Ha una forma che resta uguale per tutta la sua esistenza", "È fatto di materia, mentre il sasso non lo è affatto"], explanation: "Le piante non camminano e certi organismi non respirano ossigeno: il resto vale per tutti." },
  { topic: "corpo", difficulty: 1, prompt: "Perché è importante lavarsi le mani prima di mangiare?", answer: "Perché sulle mani restano microbi che finirebbero nel cibo", distractors: ["Perché le mani sporche rendono il cibo più difficile da masticare", "Perché l'acqua fredda sulle mani aiuta lo stomaco a digerire", "Perché è una regola di buona educazione senza effetti sulla salute"], explanation: "Gran parte delle infezioni intestinali passa proprio dalle mani." },
  { topic: "ecosistema", difficulty: 1, prompt: "Che cosa succede a un ecosistema se sparisce una sola specie?", answer: "Cambiano anche le specie collegate a quella", distractors: ["Non cambia niente, perché ogni specie vive per conto suo", "Sparisce subito tutto l'ecosistema nel giro di pochi giorni", "Le altre specie diventano automaticamente più numerose e forti"], explanation: "Gli anelli sono legati: togliendone uno la catena si riorganizza, a volte male." },
  { topic: "energia", difficulty: 1, prompt: "Perché il Sole è la fonte di quasi tutta l'energia sulla Terra?", answer: "Perché le piante ne catturano la luce e la passano a tutti gli altri", distractors: ["Perché scalda direttamente il corpo di ogni animale del pianeta", "Perché è l'unico corpo celeste visibile durante tutto il giorno", "Perché la sua luce si trasforma da sola in elettricità nell'aria"], explanation: "Anche il carbone e il petrolio sono luce solare immagazzinata milioni di anni fa." },
  { topic: "materia", difficulty: 1, prompt: "Perché lo zucchero sparisce alla vista quando lo sciogli nell'acqua?", answer: "Perché si divide in parti troppo piccole da vedere, ma resta lì", distractors: ["Perché si trasforma in acqua e smette del tutto di esistere", "Perché evapora subito appena entra in contatto con il liquido", "Perché scende sul fondo e si nasconde sotto lo strato d'acqua"], explanation: "L'acqua diventa dolce: la prova che lo zucchero c'è ancora." },
];

function scienzeBank(greenhousePlants) {
  const rand = rng(20260729);
  // Via `authoredMcItems`: cosi' anche scienze puo' avere item a risposta libera.
  const items = authoredMcItems("scienze", SCIENZE_CORE, rand);
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
// Storia (materia del Data-core, ex cittadinanza). Nucleo curato: metodo e fonti,
// cronologia, preistoria, Egizi, Grecia, Roma e Medioevo. La progressione per ERA
// è governata a runtime da ContentManager.ERA_GATED_TOPICS (roma/medioevo dal
// livello 18): il mondo 11 resta sulle prime civiltà, il 23 tratta Roma e Medioevo.
// ---------------------------------------------------------------------------

const STORIA_CORE = [
  // --- densita': 15 item per argomento (3 agosto 2026) ---
  { topic: "fonti", difficulty: 1, prompt: "Che cos'è una fonte storica?", answer: "Qualsiasi traccia che ci dice qualcosa del passato", distractors: ["Soltanto un libro scritto dagli storici","Il racconto di chi ha studiato la storia","Una data importante da ricordare"], explanation: "Una moneta, un muro, una lettera, un rifiuto sepolto: tutto ciò che è arrivato fino a noi può parlare del passato." },
  { topic: "fonti", difficulty: 2, prompt: "Un vaso trovato in uno scavo è una fonte…", answer: "Materiale", distractors: ["Scritta","Orale","Iconografica"], explanation: "Le fonti materiali sono oggetti: si studiano guardandoli e misurandoli, non leggendoli." },
  { topic: "fonti", difficulty: 2, prompt: "Il diario di un soldato è una fonte…", answer: "Scritta", distractors: ["Materiale","Orale","Archeologica"], explanation: "Le fonti scritte si leggono, e portano con sé anche il punto di vista di chi ha scritto." },
  { topic: "fonti", difficulty: 3, prompt: "Che cos'è una fonte primaria?", answer: "Un documento prodotto nell'epoca studiata", distractors: ["Il libro di storia più importante","La fonte scoperta per prima in ordine","Un documento sempre vero e affidabile"], explanation: "Primaria significa «di prima mano»: nasce nel periodo di cui parla, non secoli dopo." },
  { topic: "fonti", difficulty: 3, prompt: "Il manuale che usi a scuola è una fonte…", answer: "Secondaria", distractors: ["Primaria","Materiale","Orale"], explanation: "È secondaria perché racconta il passato basandosi su fonti primarie studiate da altri." },
  { topic: "fonti", difficulty: 3, prompt: "Perché una fonte scritta va sempre datata e attribuita?", answer: "Perché chi scrive e quando cambia ciò che dice", distractors: ["Perché altrimenti non si può conservare","Perché lo richiede la legge sugli archivi","Perché le fonti antiche valgono di più"], explanation: "La stessa battaglia raccontata dal vincitore o dallo sconfitto, subito o cent'anni dopo, non è la stessa battaglia." },
  { topic: "fonti", difficulty: 4, prompt: "Due fonti primarie dello stesso evento si contraddicono. Cosa fa uno storico?", answer: "Le confronta e cerca perché differiscono", distractors: ["Sceglie quella scritta in modo più chiaro","Scarta la più recente e tiene l'antica","Ne fa una media e passa oltre"], explanation: "La contraddizione non è un fastidio: è un indizio. Dice che qualcuno aveva un interesse, o una prospettiva diversa." },
  { topic: "fonti", difficulty: 3, prompt: "Un'intervista a chi ha vissuto un evento è una fonte…", answer: "Orale", distractors: ["Materiale","Iconografica","Secondaria"], explanation: "Le fonti orali raccolgono ricordi. Sono preziose e fragili: la memoria cambia con il tempo." },
  { topic: "fonti", difficulty: 4, prompt: "Perché anche una fonte falsa può essere utile allo storico?", answer: "Perché dice cosa qualcuno voleva far credere", distractors: ["Perché contiene comunque dati esatti","Perché è più antica delle altre fonti","Perché è più facile da conservare"], explanation: "Un falso non racconta il fatto, ma racconta il falsario: chi l'ha fatto, quando, e a chi giovava." },
  { topic: "fonti", difficulty: 2, prompt: "Un affresco che mostra una scena di caccia è una fonte…", answer: "Iconografica", distractors: ["Scritta e narrativa","Orale e indiretta","Numerica e statistica"], explanation: "Le fonti iconografiche sono immagini: dipinti, mosaici, incisioni. Si «leggono» guardandole." },
  { topic: "fonti", difficulty: 4, prompt: "Di un evento non resta nessuna fonte. Cosa può dire lo storico?", answer: "Poco o niente, e deve ammetterlo", distractors: ["Può ricostruirlo per analogia","Può dedurlo dai secoli vicini","Può darlo per non avvenuto"], explanation: "Il silenzio delle fonti non è una prova. Dire «non lo sappiamo» è una risposta storica legittima." },
  { topic: "fonti", difficulty: 3, prompt: "Che cos'è un archivio?", answer: "Il luogo dove si conservano i documenti", distractors: ["Il museo che espone gli oggetti antichi","Il libro che raccoglie le date importanti","Lo scavo dove si trovano i reperti"], explanation: "Negli archivi finiscono registri, lettere e atti: la materia prima con cui si scrive la storia." },
  { topic: "fonti", difficulty: 4, prompt: "Perché gli scarti e i rifiuti antichi interessano gli archeologi?", answer: "Perché raccontano la vita di tutti i giorni", distractors: ["Perché contengono oggetti di valore","Perché sono i resti meglio conservati","Perché sono più facili da datare"], explanation: "Nessuno decide come farsi ricordare buttando l'immondizia: per questo dice la verità sul cibo, sui mestieri, sulla povertà." },
  { topic: "fonti", difficulty: 2, prompt: "Una moneta antica dice allo storico soprattutto…", answer: "Chi comandava e cosa voleva mostrare", distractors: ["Quanto era ricca quella popolazione","Quante persone vivevano in città","Che lingua parlava la gente comune"], explanation: "Sulle monete si mettevano il volto del sovrano e i simboli del potere: erano il manifesto più diffuso che esistesse." },
  { topic: "civilta", difficulty: 1, prompt: "Che cosa hanno in comune le prime grandi civiltà?", answer: "Sono nate vicino a grandi fiumi", distractors: ["Sono nate in cima alle montagne","Sono nate lontano dall'acqua","Sono nate tutte nello stesso anno"], explanation: "Nilo, Tigri, Eufrate, Indo, Fiume Giallo: l'acqua permetteva di coltivare e di spostarsi." },
  { topic: "civilta", difficulty: 2, prompt: "Quale invenzione segna il passaggio dalla preistoria alla storia?", answer: "La scrittura", distractors: ["La ruota","Il fuoco","L'agricoltura"], explanation: "Con la scrittura gli uomini cominciano a lasciare documenti: da lì possiamo leggere il loro racconto." },
  { topic: "civilta", difficulty: 2, prompt: "In quale zona nacquero Sumeri e Babilonesi?", answer: "Mesopotamia", distractors: ["Valle del Nilo","Penisola italiana","Isola di Creta"], explanation: "Mesopotamia significa «terra fra i fiumi»: Tigri ed Eufrate, l'attuale Iraq." },
  { topic: "civilta", difficulty: 3, prompt: "Perché la nascita dell'agricoltura cambiò tutto?", answer: "Perché permise di restare fermi in un luogo", distractors: ["Perché rese il cibo molto più saporito","Perché portò a scoprire i primi metalli","Perché richiedeva molte meno persone"], explanation: "Chi coltiva resta: nascono i villaggi, le case stabili, le proprietà e i primi conflitti su di esse." },
  { topic: "civilta", difficulty: 3, prompt: "A cosa servivano i primi segni di scrittura in Mesopotamia?", answer: "A registrare merci e magazzini", distractors: ["A scrivere poesie e canzoni","A raccontare le guerre vinte","A insegnare ai bambini a leggere"], explanation: "La scrittura nasce come contabilità: quante pecore, quanto grano, di chi. La letteratura arriva molto dopo." },
  { topic: "civilta", difficulty: 3, prompt: "Che cos'era il codice di Hammurabi?", answer: "Una raccolta di leggi scritte", distractors: ["Un manuale di costruzione","Un elenco di divinità babilonesi","Un trattato di pace fra regni"], explanation: "Scrivere le leggi significa renderle uguali per tutti e non modificabili a piacere: è un passo enorme." },
  { topic: "civilta", difficulty: 4, prompt: "Perché la ruota fu importante quanto l'aratro?", answer: "Perché permise di trasportare pesi lontano", distractors: ["Perché rese più belle le città","Perché serviva a costruire i templi","Perché sostituì la forza animale"], explanation: "Coltivare di più serve a poco se non puoi spostare il raccolto: produzione e trasporto crescono insieme." },
  { topic: "civilta", difficulty: 2, prompt: "Quale civiltà antica si sviluppò lungo il fiume Indo?", answer: "La civiltà della valle dell'Indo", distractors: ["La civiltà cinese degli Shang","La civiltà egizia del Nilo","La civiltà minoica di Creta"], explanation: "Città come Mohenjo-daro avevano strade regolari e fognature: erano pianificate, non cresciute a caso." },
  { topic: "civilta", difficulty: 4, prompt: "Che cos'è una civiltà, in senso storico?", answer: "Una società con città, scrittura e organizzazione", distractors: ["Un popolo che vive in modo educato","Un gruppo che possiede molte ricchezze","Una popolazione numerosa e in crescita"], explanation: "Non è un giudizio di valore: è un insieme di caratteristiche osservabili, come vivere in città e amministrare per iscritto." },
  { topic: "civilta", difficulty: 3, prompt: "Perché le prime città avevano bisogno di magazzini?", answer: "Per conservare il cibo e superare le carestie", distractors: ["Per esporre gli oggetti più preziosi","Per ospitare i viaggiatori di passaggio","Per tenerci gli strumenti dei contadini"], explanation: "Un raccolto abbondante serve a poco se marcisce: chi sa conservare sopravvive agli anni cattivi." },
  { topic: "civilta", difficulty: 4, prompt: "Perché nelle prime civiltà nacquero classi sociali diverse?", answer: "Perché non tutti dovevano più produrre cibo", distractors: ["Perché alcuni erano più intelligenti","Perché lo imponevano le divinità","Perché il territorio era troppo grande"], explanation: "Con un surplus agricolo qualcuno può fare altro: il sacerdote, lo scriba, il soldato. Da lì nascono le differenze." },
  { topic: "civilta", difficulty: 2, prompt: "Che cosa sono le ziggurat mesopotamiche?", answer: "Templi a gradoni dedicati alle divinità", distractors: ["Tombe reali sotterranee","Mura di difesa delle città","Magazzini per conservare il grano"], explanation: "Salivano verso il cielo perché lì si pensava abitassero gli dèi: la religione era al centro della città." },
  { topic: "civilta", difficulty: 3, prompt: "Perché il bronzo cambiò la vita delle prime civiltà?", answer: "Perché diede attrezzi e armi più resistenti", distractors: ["Perché era più bello da guardare dell'oro","Perché si trovava dappertutto in natura","Perché era leggerissimo da trasportare"], explanation: "Il bronzo è più duro del rame puro. E poiché serve lo stagno, spesso lontano, nascono le grandi rotte commerciali." },
  { topic: "civilta", difficulty: 4, prompt: "Perché la scrittura cuneiforme si chiama così?", answer: "Perché i segni hanno forma di cuneo", distractors: ["Perché veniva incisa sui cunei di legno","Perché la inventò un popolo detto cuneo","Perché si leggeva partendo da un angolo"], explanation: "Si imprimeva su tavolette d'argilla morbida con uno stilo a punta triangolare: ogni segno resta a forma di chiodo." },
  { topic: "egizi", difficulty: 2, prompt: "Perché il Nilo era essenziale per gli Egizi?", answer: "Perché le sue piene rendevano fertile la terra", distractors: ["Perché conteneva molti pesci pregiati","Perché segnava il confine con i nemici","Perché era l'unica via per il deserto"], explanation: "Ogni anno la piena depositava limo: senza quel fango il deserto sarebbe arrivato fino alle case." },
  { topic: "egizi", difficulty: 2, prompt: "Come si chiamava la scrittura sacra degli Egizi?", answer: "Geroglifica", distractors: ["Cuneiforme","Alfabetica","Ideografica cinese"], explanation: "Geroglifico significa «incisione sacra»: si usava sui monumenti e nei testi religiosi." },
  { topic: "egizi", difficulty: 3, prompt: "A che cosa servivano le piramidi?", answer: "Erano tombe monumentali dei faraoni", distractors: ["Erano templi per le cerimonie","Erano magazzini per il grano","Erano fortezze contro i nemici"], explanation: "Servivano a proteggere il corpo e il corredo del faraone per la vita dopo la morte." },
  { topic: "egizi", difficulty: 3, prompt: "Perché gli Egizi praticavano la mummificazione?", answer: "Per conservare il corpo per l'aldilà", distractors: ["Per evitare il diffondersi di malattie","Per riconoscere i defunti importanti","Per risparmiare spazio nelle tombe"], explanation: "Credevano che l'anima avesse bisogno del corpo per continuare a esistere: conservarlo era un atto religioso." },
  { topic: "egizi", difficulty: 4, prompt: "Che cos'è la stele di Rosetta?", answer: "Una pietra con lo stesso testo in tre scritture", distractors: ["Il primo calendario egizio conosciuto","Una lastra con le leggi del faraone","La mappa del corso completo del Nilo"], explanation: "Avendo lo stesso testo in greco e in egizio, permise finalmente di decifrare i geroglifici." },
  { topic: "egizi", difficulty: 3, prompt: "Chi era il faraone per gli antichi Egizi?", answer: "Un sovrano considerato anche divino", distractors: ["Il capo dell'esercito eletto ogni anno","Il sacerdote più anziano del tempio","Il proprietario di tutte le terre coltivate"], explanation: "Non era solo un re: era il legame fra gli dèi e gli uomini, e questo giustificava il suo potere assoluto." },
  { topic: "egizi", difficulty: 4, prompt: "Perché gli Egizi svilupparono la geometria?", answer: "Per ridisegnare i campi dopo ogni piena", distractors: ["Per decorare meglio i loro templi","Per contare le tasse dei mercanti","Per orientare le navi sul fiume"], explanation: "La piena cancellava i confini dei terreni ogni anno: bisognava misurarli di nuovo, e da lì nasce la «misura della terra»." },
  { topic: "egizi", difficulty: 2, prompt: "Su quale materiale scrivevano principalmente gli Egizi?", answer: "Papiro", distractors: ["Tavolette d'argilla","Pergamena di pelle","Tavolette di cera"], explanation: "Il papiro si ricavava da una pianta che cresceva lungo il Nilo: leggero, arrotolabile, ed è la radice della parola «carta»." },
  { topic: "metodo", difficulty: 3, prompt: "Che cosa vuol dire contestualizzare una fonte?", answer: "Capire in che epoca e situazione è nata", distractors: ["Tradurla nella lingua di oggi","Riassumerla nei suoi punti chiave","Confrontarla con il libro di testo"], explanation: "Una frase può cambiare senso a seconda di chi la dice, quando e a chi: senza contesto si legge male." },
  { topic: "metodo", difficulty: 4, prompt: "Uno storico trova un solo documento su un fatto. Cosa può concludere?", answer: "Una ricostruzione provvisoria, da verificare", distractors: ["Una verità certa, perché è scritta","Che il fatto non è mai avvenuto","Che il documento è sicuramente falso"], explanation: "Una fonte sola può bastare a formulare un'ipotesi, non a chiuderla: serve incrocio con altre testimonianze." },
  { topic: "metodo", difficulty: 3, prompt: "Perché si dice che la storia si riscrive?", answer: "Perché nuove fonti cambiano le ricostruzioni", distractors: ["Perché ogni epoca inventa il suo passato","Perché gli storici non sono mai d'accordo","Perché i libri vanno aggiornati per legge"], explanation: "Non cambiano i fatti: cambia quello che sappiamo. Uno scavo nuovo può ribaltare una certezza di cent'anni." },
  { topic: "metodo", difficulty: 4, prompt: "Che cos'è un anacronismo?", answer: "Attribuire a un'epoca qualcosa che non aveva", distractors: ["Confondere due date molto vicine","Raccontare i fatti in ordine sbagliato","Usare una fonte non affidabile"], explanation: "Un romano con l'orologio da polso è un anacronismo evidente; giudicarne le scelte con la nostra morale è un anacronismo più sottile." },
  { topic: "metodo", difficulty: 3, prompt: "Perché lo storico deve dichiarare le proprie fonti?", answer: "Perché altri possano controllare il lavoro", distractors: ["Perché è una regola di cortesia fra studiosi","Perché così il testo risulta più lungo","Perché lo impongono i regolamenti degli archivi"], explanation: "Una ricostruzione senza fonti dichiarate non è verificabile, e ciò che non si può controllare non si può correggere." },
  { topic: "metodo", difficulty: 4, prompt: "Che differenza c'è fra un fatto e un'interpretazione?", answer: "Il fatto è accaduto, l'interpretazione lo spiega", distractors: ["Il fatto è antico, l'interpretazione recente","Il fatto è scritto, l'interpretazione è orale","Non c'è differenza, sono sinonimi"], explanation: "Che Roma sia caduta nel 476 è un fatto; perché sia caduta è interpretazione, e su quella gli storici discutono ancora." },
  { topic: "metodo", difficulty: 3, prompt: "Perché è utile studiare anche la storia della gente comune?", answer: "Perché racconta come si viveva davvero", distractors: ["Perché è più facile da ricostruire","Perché ci sono più fonti disponibili","Perché i re non lasciano documenti"], explanation: "La storia dei soli sovrani spiega le decisioni, non la vita: il cibo, il lavoro e le case dicono il resto." },
  { topic: "preistoria", difficulty: 2, prompt: "Perché il periodo prima della scrittura si chiama preistoria?", answer: "Perché mancano documenti scritti da studiare", distractors: ["Perché gli uomini non pensavano ancora","Perché non era ancora nata l'agricoltura","Perché non esistevano ancora le città"], explanation: "Lo studiamo solo con le fonti materiali: ossa, strumenti, pitture. Nessuno ci ha lasciato il proprio racconto." },
  { topic: "preistoria", difficulty: 2, prompt: "Quale scoperta permise all'uomo preistorico di cuocere e riscaldarsi?", answer: "Il fuoco", distractors: ["La ruota","L'arco","Il bronzo"], explanation: "Il fuoco allunga la giornata, rende il cibo digeribile e tiene lontani gli animali: cambia tutto." },
  { topic: "preistoria", difficulty: 3, prompt: "Che cosa distingue il Paleolitico dal Neolitico?", answer: "Nel Neolitico nascono agricoltura e allevamento", distractors: ["Nel Neolitico si scopre l'uso del fuoco","Nel Paleolitico si vive già nelle città","Nel Paleolitico si lavora già il ferro"], explanation: "Paleolitico significa «pietra antica»: si caccia e si raccoglie. Nel Neolitico si produce il cibo, e si diventa stanziali." },
  { topic: "preistoria", difficulty: 3, prompt: "Perché gli uomini del Paleolitico erano nomadi?", answer: "Perché seguivano gli animali e le stagioni", distractors: ["Perché temevano le altre tribù","Perché cercavano metalli preziosi","Perché il clima era sempre uguale"], explanation: "Chi vive di caccia e raccolta deve spostarsi dove c'è cibo: restare fermi diventa possibile solo coltivando." },
  { topic: "preistoria", difficulty: 4, prompt: "A che cosa servivano probabilmente le pitture rupestri?", answer: "Avevano un valore rituale e simbolico", distractors: ["A decorare le pareti delle case","A insegnare a disegnare ai bambini","A segnare i confini fra i gruppi"], explanation: "Stanno spesso in grotte profonde e scomode, non nei luoghi in cui si viveva: la spiegazione decorativa non basta." },
  { topic: "preistoria", difficulty: 3, prompt: "Che cos'è un menhir?", answer: "Una grande pietra piantata verticalmente", distractors: ["Una capanna di pietra e paglia","Una tomba scavata nella roccia","Un utensile per lavorare la pelle"], explanation: "Erigerlo richiedeva molte persone coordinate: dice che quei gruppi sapevano organizzarsi per uno scopo comune." },
  { topic: "preistoria", difficulty: 4, prompt: "Perché la lavorazione dei metalli segna una svolta?", answer: "Perché dà strumenti migliori e nuovi scambi", distractors: ["Perché rende inutile l'agricoltura","Perché fa nascere subito la scrittura","Perché elimina le guerre fra gruppi"], explanation: "Gli attrezzi di metallo durano e tagliano meglio; e poiché i minerali sono in pochi luoghi, nascono commerci a lunga distanza." },
  { topic: "grecia", difficulty: 2, prompt: "Che cos'era una polis greca?", answer: "Una città-stato indipendente", distractors: ["Una piazza per il mercato","Un tempio dedicato agli dèi","Un'assemblea di soli anziani"], explanation: "Ogni polis aveva leggi, monete ed esercito propri: la Grecia era un insieme di città, non uno Stato unico." },
  { topic: "grecia", difficulty: 3, prompt: "In quale città nacque la democrazia antica?", answer: "Atene", distractors: ["Sparta","Corinto","Tebe"], explanation: "Ad Atene i cittadini decidevano in assemblea. «Cittadini» però escludeva donne, schiavi e stranieri." },
  { topic: "grecia", difficulty: 3, prompt: "Che cosa significa la parola «democrazia»?", answer: "Governo del popolo", distractors: ["Governo dei più ricchi","Governo di uno solo","Governo dei sacerdoti"], explanation: "Da «demos» (popolo) e «kratos» (potere). Il nome dice il principio: le decisioni spettano ai cittadini." },
  { topic: "grecia", difficulty: 3, prompt: "Per che cosa era famosa Sparta?", answer: "Per l'educazione militare durissima", distractors: ["Per i suoi teatri e le sue commedie","Per i commerci con tutto il Mediterraneo","Per le scuole di filosofia e matematica"], explanation: "A Sparta il cittadino era prima di tutto un soldato: l'addestramento cominciava da bambini e durava tutta la vita." },
  { topic: "grecia", difficulty: 4, prompt: "Perché i Greci fondarono colonie nel Mediterraneo?", answer: "Perché la terra coltivabile in patria era poca", distractors: ["Perché volevano conquistare Roma","Perché fuggivano da un'epidemia","Perché cercavano nuovi dèi da adorare"], explanation: "Il territorio greco è montuoso e povero: chi non aveva terra partiva. Così nacque anche la Magna Grecia in Italia." },
  { topic: "grecia", difficulty: 3, prompt: "Che cosa erano i Giochi olimpici antichi?", answer: "Gare sportive in onore di Zeus", distractors: ["Battaglie simulate fra due città","Feste per il raccolto dell'anno","Prove per scegliere i governanti"], explanation: "Si tenevano a Olimpia ogni quattro anni, e durante i giochi le guerre fra le poleis venivano sospese." },
  { topic: "grecia", difficulty: 4, prompt: "Perché il teatro era importante nella Grecia antica?", answer: "Perché faceva discutere la città sui suoi problemi", distractors: ["Perché serviva solo a far divertire","Perché era riservato ai sacerdoti","Perché sostituiva le assemblee politiche"], explanation: "Le tragedie mettevano in scena giustizia, potere e destino davanti a migliaia di cittadini: era spettacolo e riflessione pubblica." },
  { topic: "cronologia", difficulty: 3, prompt: "A quale secolo appartiene l'anno 1789?", answer: "XVIII secolo", distractors: ["XVII secolo","XIX secolo","XVI secolo"], explanation: "Gli anni dal 1701 al 1800 formano il XVIII secolo: si prendono le centinaia e si aggiunge uno." },
  { topic: "cronologia", difficulty: 3, prompt: "Quale anno viene prima: 300 a.C. o 100 a.C.?", answer: "300 a.C.", distractors: ["100 a.C.","Sono contemporanei","Non è determinabile"], explanation: "Prima di Cristo si conta all'indietro: più il numero è grande, più l'anno è lontano nel passato." },
  { topic: "cronologia", difficulty: 4, format: "numeric_input", prompt: "Quanti anni passano fra il 50 a.C. e il 50 d.C.?", answer: "100", explanation: "Cinquanta prima e cinquanta dopo, senza anno zero fra i due sistemi: un secolo esatto." },
  { topic: "cronologia", difficulty: 2, format: "numeric_input", prompt: "Quanti secoli ci sono in un millennio?", answer: "10", explanation: "Mille anni divisi in secoli da cento: dieci secoli fanno un millennio." },
  { topic: "cronologia", difficulty: 4, prompt: "In quale secolo si colloca l'anno 1900?", answer: "XIX secolo", distractors: ["XX secolo","XVIII secolo","XXI secolo"], explanation: "Il 1900 chiude il XIX secolo: il XX comincia con il 1901, perché si conta da 1 e non da 0." },
  { topic: "cronologia", difficulty: 3, prompt: "Che cos'è una linea del tempo?", answer: "Uno schema che mette gli eventi in ordine", distractors: ["L'elenco delle date più importanti","Il racconto di un secolo intero","La durata di una singola epoca"], explanation: "Serve a vedere la successione e le distanze: quali fatti sono vicini, quali lontani, cosa è avvenuto insieme." },
  { topic: "roma", difficulty: 3, prompt: "Chi poteva votare nella Roma repubblicana?", answer: "Solo i cittadini maschi liberi", distractors: ["Tutti gli abitanti della città","Soltanto i senatori e i loro figli","Chiunque avesse prestato servizio"], explanation: "Donne, schiavi e stranieri restavano fuori. E il voto pesava di più per i cittadini più ricchi." },
  { topic: "roma", difficulty: 3, prompt: "A che cosa serviva una via consolare romana?", answer: "A spostare rapidamente eserciti e merci", distractors: ["A segnare i confini dell'impero","A collegare i templi principali","A far defluire l'acqua piovana"], explanation: "Strade dritte e lastricate significano legioni che arrivano prima: l'impero si teneva insieme anche così." },
  { topic: "roma", difficulty: 4, prompt: "Perché la cittadinanza romana era così ambita?", answer: "Perché dava diritti e protezione legale", distractors: ["Perché esentava da qualsiasi tassa","Perché permetteva di non fare il soldato","Perché consentiva di possedere schiavi"], explanation: "Un cittadino non poteva essere condannato senza processo e poteva appellarsi: era una garanzia enorme per l'epoca." },
  { topic: "roma", difficulty: 3, prompt: "Che cos'erano le terme romane?", answer: "Bagni pubblici e luogo di incontro", distractors: ["Palestre riservate ai soldati","Templi dedicati alle divinità dell'acqua","Magazzini per conservare le derrate"], explanation: "Ci si lavava, ma soprattutto si parlava d'affari e di politica: erano il centro della vita sociale." },
  { topic: "roma", difficulty: 4, prompt: "Perché l'impero romano riuscì a durare secoli?", answer: "Per l'organizzazione di leggi, strade ed esercito", distractors: ["Perché non ebbe mai nemici veri","Perché tutti parlavano la stessa lingua","Perché il territorio era piccolo"], explanation: "Non bastava conquistare: servivano un diritto comune, vie di comunicazione e un esercito stabile per tenere insieme il tutto." },
  { topic: "medioevo", difficulty: 3, prompt: "Chi lavorava la terra del feudo?", answer: "I contadini, in gran parte servi della gleba", distractors: ["I soldati del signore quando non combattevano","I monaci che vivevano nei monasteri vicini","Gli abitanti liberi delle città vicine"], explanation: "I servi della gleba erano legati alla terra: non potevano lasciarla, e passavano al signore successivo insieme al campo." },
  { topic: "medioevo", difficulty: 3, prompt: "Che cosa facevano i monaci amanuensi?", answer: "Copiavano a mano i libri antichi", distractors: ["Insegnavano nelle scuole cittadine","Costruivano le grandi cattedrali","Curavano i malati negli ospedali"], explanation: "Prima della stampa ogni copia era scritta a mano: senza quel lavoro paziente molti testi antichi sarebbero andati perduti." },
  { topic: "medioevo", difficulty: 4, prompt: "Perché nel Basso Medioevo rinascono le città?", answer: "Perché ripartono commerci e artigianato", distractors: ["Perché i castelli vengono abbandonati","Perché la popolazione smette di crescere","Perché i signori le fanno costruire"], explanation: "Con più scambi servono luoghi dove vendere e produrre: nascono i mercati, le corporazioni e i Comuni." },
  { topic: "medioevo", difficulty: 3, prompt: "Che cos'era un Comune medievale italiano?", answer: "Una città che si governava da sé", distractors: ["Un villaggio di contadini liberi","Un accordo fra due signori vicini","Un territorio dato alla Chiesa"], explanation: "I cittadini si organizzavano per decidere da soli, spesso in conflitto con l'imperatore o con il vescovo." },
  { topic: "medioevo", difficulty: 4, prompt: "Quale invenzione della metà del Quattrocento cambiò la diffusione del sapere?", answer: "La stampa a caratteri mobili", distractors: ["La bussola per la navigazione","L'orologio meccanico da torre","Gli occhiali da lettura"], explanation: "Copiare un libro richiedeva mesi; stamparne centinaia diventa questione di giorni. Le idee cominciano a viaggiare." },
  // --- metodo ---
  { topic: "metodo", difficulty: 1, prompt: "Chi studia il passato usando le tracce che ci ha lasciato?", answer: "Lo storico", distractors: ["Il meteorologo", "Il geologo", "L'astronomo"], explanation: "Lo storico ricostruisce il passato interpretando le fonti." },
  { topic: "metodo", difficulty: 2, prompt: "Che cosa sono le fonti storiche?", answer: "Le tracce che ci parlano del passato", distractors: ["Le sorgenti d'acqua di montagna", "Soltanto i libri stampati oggi", "Le previsioni sul futuro lontano"], explanation: "Documenti, oggetti, resti e racconti sono fonti: ci fanno conoscere il passato." },
  { topic: "metodo", difficulty: 3, prompt: "Una piramide egizia è un esempio di fonte…", answer: "materiale", distractors: ["scritta", "orale", "immaginaria"], explanation: "Le fonti materiali sono oggetti e costruzioni; quelle scritte sono i testi." },
  // --- cronologia ---
  { topic: "cronologia", difficulty: 1, prompt: "Quanti anni dura un secolo?", answer: "Cento", distractors: ["Dieci", "Mille", "Cinquanta"], explanation: "Attenzione al conto: il Novecento è il ventesimo secolo, perché il primo comprende gli anni dall'1 al 100." },
  { topic: "cronologia", difficulty: 2, prompt: "Come si indicano gli anni prima della nascita di Cristo?", answer: "a.C.", distractors: ["d.C.", "km", "d.o.c."], explanation: "a.C. significa 'avanti Cristo'; d.C. significa 'dopo Cristo'." },
  { topic: "cronologia", difficulty: 3, prompt: "A quale secolo appartiene l'anno 1492?", answer: "XV secolo", distractors: ["XIV secolo", "XVI secolo", "XIII secolo"], explanation: "Gli anni dal 1401 al 1500 formano il XV secolo (il '400)." },
  // --- preistoria ---
  { topic: "preistoria", difficulty: 2, prompt: "Che cosa distingue la Preistoria dalla Storia?", answer: "L'assenza della scrittura", distractors: ["L'assenza del fuoco", "L'assenza degli animali", "L'assenza del Sole"], explanation: "La Storia inizia con l'invenzione della scrittura; prima c'è la Preistoria." },
  { topic: "preistoria", difficulty: 2, prompt: "Di che cosa viveva soprattutto l'uomo del Paleolitico?", answer: "Caccia e raccolta", distractors: ["Agricoltura intensiva", "Commercio con l'estero", "Allevamento in stalla"], explanation: "Nel Paleolitico l'uomo era nomade e viveva di caccia, pesca e raccolta." },
  { topic: "preistoria", difficulty: 3, prompt: "Quale grande scoperta segnò il passaggio al Neolitico?", answer: "L'agricoltura", distractors: ["La ruota a motore", "L'elettricità", "La stampa"], explanation: "Con l'agricoltura l'uomo diventò sedentario e nacquero i primi villaggi." },
  { topic: "preistoria", difficulty: 3, prompt: "Da quale metallo prende il nome l'Età del Bronzo?", answer: "Dal bronzo", distractors: ["Dal ferro", "Dall'oro", "Dall'argento"], explanation: "Il bronzo è una lega di rame e stagno: diede il nome a quell'età." },
  // --- egizi ---
  { topic: "egizi", difficulty: 1, prompt: "Come si chiamava il re dell'antico Egitto?", answer: "Faraone", distractors: ["Console", "Imperatore", "Doge"], explanation: "Il faraone era il sovrano dell'Egitto, considerato quasi un dio." },
  { topic: "egizi", difficulty: 2, prompt: "Lungo quale fiume nacque la civiltà egizia?", answer: "Il Nilo", distractors: ["Il Tevere", "Il Po", "Il Danubio"], explanation: "La civiltà egizia fiorì lungo le rive del Nilo." },
  { topic: "egizi", difficulty: 3, prompt: "Perché il Nilo era fondamentale per gli Egizi?", answer: "Perché con le piene rendeva fertili i campi", distractors: ["Perché era sempre gelato tutto l'anno", "Perché non aveva mai una goccia d'acqua", "Perché era pieno di pepite d'oro"], explanation: "Le piene del Nilo lasciavano fango fertile: permettevano l'agricoltura." },
  { topic: "egizi", difficulty: 2, prompt: "Come si chiamava la scrittura degli antichi Egizi?", answer: "Geroglifici", distractors: ["Alfabeto latino", "Numeri romani", "Braille"], explanation: "Gli Egizi scrivevano con i geroglifici, piccoli disegni-simbolo." },
  // --- grecia ---
  { topic: "grecia", difficulty: 2, prompt: "Quale città greca era famosa per i suoi guerrieri e la disciplina?", answer: "Sparta", distractors: ["Atene", "Corinto", "Tebe"], explanation: "A Sparta l'educazione era tutta rivolta alla vita militare." },
  { topic: "grecia", difficulty: 3, prompt: "In quale città greca nacque la democrazia?", answer: "Atene", distractors: ["Sparta", "Olimpia", "Micene"], explanation: "Ad Atene i cittadini partecipavano alle decisioni: nacque la democrazia." },
  { topic: "grecia", difficulty: 3, prompt: "Come si chiamavano le città-stato indipendenti della Grecia antica?", answer: "Pòleis", distractors: ["Province", "Regioni", "Contee"], explanation: "Montagne e mare separavano le comunità greche, che restarono indipendenti invece di unirsi in un regno unico: ogni pòlis aveva le sue leggi e il suo esercito." },
  { topic: "grecia", difficulty: 2, prompt: "In quale luogo si tenevano gli antichi Giochi Olimpici?", answer: "A Olimpia", distractors: ["A Roma", "Ad Alessandria", "A Cartagine"], explanation: "I Giochi si svolgevano a Olimpia, in onore del dio Zeus." },
  // --- roma ---
  { topic: "roma", difficulty: 1, prompt: "Quale lingua parlavano gli antichi Romani?", answer: "Il latino", distractors: ["Il greco", "L'italiano", "L'inglese"], explanation: "I Romani parlavano latino, da cui deriva anche l'italiano." },
  { topic: "roma", difficulty: 2, prompt: "Secondo la leggenda, chi fondò Roma?", answer: "Romolo", distractors: ["Enea", "Cesare", "Annibale"], explanation: "La leggenda narra che Roma fu fondata da Romolo, con il fratello Remo." },
  { topic: "roma", difficulty: 3, prompt: "In quale anno la tradizione colloca la fondazione di Roma?", answer: "753 a.C.", distractors: ["1492 d.C.", "476 d.C.", "100 d.C."], explanation: "È una data di leggenda, non di scavo: serviva ai Romani per darsi un inizio preciso da cui contare gli anni." },
  { topic: "roma", difficulty: 3, prompt: "Dopo la monarchia, quale forma di governo ebbe Roma?", answer: "La repubblica", distractors: ["L'anarchia", "Il feudalesimo", "La democrazia diretta"], explanation: "Cacciato l'ultimo re, Roma diventò una repubblica guidata dai consoli." },
  { topic: "roma", difficulty: 3, prompt: "Come si chiamava l'assemblea dei senatori a Roma?", answer: "Il Senato", distractors: ["Il Colosseo", "Il Foro", "La Curia dei re"], explanation: "Il Senato riuniva i patrizi e consigliava chi governava Roma." },
  { topic: "roma", difficulty: 2, prompt: "Chi guidava l'Impero Romano?", answer: "L'imperatore", distractors: ["Il faraone", "Il doge", "Il presidente"], explanation: "Dopo la repubblica, Roma fu guidata da un imperatore, il primo fu Augusto." },
  // --- medioevo ---
  { topic: "medioevo", difficulty: 3, prompt: "Quale evento segna l'inizio del Medioevo?", answer: "La caduta dell'Impero Romano d'Occidente", distractors: ["La fondazione della città di Roma", "La scoperta dell'America nel 1492", "L'unità d'Italia con i Savoia"], explanation: "Il Medioevo inizia nel 476 d.C., con la caduta dell'Impero Romano d'Occidente." },
  { topic: "medioevo", difficulty: 4, prompt: "Come si chiamava il sistema in cui il signore dava terre in cambio di fedeltà?", answer: "Feudalesimo", distractors: ["Democrazia", "Repubblica", "Impero"], explanation: "Nel feudalesimo il signore concedeva un feudo in cambio di fedeltà e aiuto militare." },
  { topic: "medioevo", difficulty: 2, prompt: "A che cosa serviva soprattutto un castello medievale?", answer: "A difendersi dagli attacchi", distractors: ["A coltivare il grano nei campi", "A fare gare sportive fra nobili", "A conservare l'acqua piovana"], explanation: "Il castello, con mura e torri, proteggeva il signore e gli abitanti." },
  { topic: "medioevo", difficulty: 3, prompt: "Chi copiava a mano i libri nei monasteri medievali?", answer: "I monaci amanuensi", distractors: ["I cavalieri armati", "I mercanti stranieri", "I contadini del feudo"], explanation: "I monaci amanuensi ricopiavano a mano i testi, custodendo il sapere." },
  { topic: "medioevo", difficulty: 2, prompt: "Come si chiamavano i guerrieri a cavallo al servizio di un signore?", answer: "Cavalieri", distractors: ["Faraoni", "Consoli", "Legionari"], explanation: "I cavalieri combattevano a cavallo e giuravano fedeltà al loro signore." },
  { topic: "medioevo", difficulty: 3, prompt: "Dove si conservava e si copiava il sapere nell'Alto Medioevo?", answer: "Nei monasteri", distractors: ["Nei supermercati", "Nelle fabbriche", "Nei porti"], explanation: "I monasteri furono centri di cultura: vi si custodivano e copiavano i libri." },
  { topic: "preistoria", difficulty: 1, format: "short_answer", prompt: "Come si chiama il periodo della preistoria in cui la pietra veniva solo scheggiata?", answer: "paleolitico", explanation: "Paleo vuol dire antico: pietra antica." },
  { topic: "preistoria", difficulty: 2, format: "short_answer", prompt: "Come si chiama il periodo della preistoria in cui la pietra veniva levigata?", answer: "neolitico", explanation: "Nello stesso periodo nascono agricoltura e allevamento." },
  { topic: "preistoria", difficulty: 2, format: "short_answer", prompt: "Come si chiama la scoperta che permise all'uomo di cuocere il cibo e scaldarsi?", answer: "fuoco", accept: ["il fuoco"], explanation: "Cambiò alimentazione, difesa e vita notturna insieme." },
  { topic: "preistoria", difficulty: 3, format: "short_answer", prompt: "Come si chiama l'attività con cui l'uomo iniziò a coltivare la terra?", answer: "agricoltura", accept: ["l'agricoltura"], explanation: "Da nomade l'uomo diventa stanziale: nascono i villaggi." },
  { topic: "fonti", difficulty: 2, format: "short_answer", prompt: "Come si chiamano le fonti costituite da oggetti, edifici e resti?", answer: "fonti materiali", accept: ["materiali"], explanation: "Non raccontano a parole: vanno interpretate." },
  { topic: "fonti", difficulty: 2, format: "short_answer", prompt: "Come si chiamano le fonti costituite da testi e documenti?", answer: "fonti scritte", accept: ["scritte"], explanation: "Sono le più esplicite, ma anche le più facili da falsificare." },
  { topic: "fonti", difficulty: 3, format: "short_answer", prompt: "Come si chiama la scienza che studia il passato scavando nel terreno?", answer: "archeologia", accept: ["l'archeologia"], explanation: "Scava per strati: sotto sta sempre il più antico." },
  { topic: "cronologia", difficulty: 1, format: "short_answer", prompt: "Come si chiama un periodo di cento anni?", answer: "secolo", explanation: "Il Novecento è il ventesimo secolo." },
  { topic: "cronologia", difficulty: 2, format: "short_answer", prompt: "Come si chiama un periodo di mille anni?", answer: "millennio", explanation: "Mille anni: la storia scritta ne conta poco più di cinque." },
  { topic: "cronologia", difficulty: 2, format: "short_answer", prompt: "Come si chiama un periodo di dieci anni?", answer: "decennio", explanation: "Dieci anni: l'unità con cui si raccontano i cambiamenti recenti." },
  { topic: "civilta", difficulty: 2, format: "short_answer", prompt: "In quale regione fra i fiumi Tigri ed Eufrate nacquero le prime città?", answer: "Mesopotamia", accept: ["la Mesopotamia"], explanation: "Il nome greco vuol dire proprio «terra fra i fiumi»." },
  { topic: "civilta", difficulty: 3, format: "short_answer", prompt: "Come si chiama la scrittura a segni triangolari incisi sull'argilla dai Sumeri?", answer: "cuneiforme", accept: ["scrittura cuneiforme"], explanation: "I segni si facevano con un calamo a punta triangolare, il cuneo." },
  { topic: "civilta", difficulty: 3, format: "short_answer", prompt: "Come si chiama il popolo che diffuse l'alfabeto nel Mediterraneo con i suoi commerci?", answer: "Fenici", accept: ["i Fenici"], explanation: "Un alfabeto di poche lettere, molto più facile da imparare." },
  { topic: "egizi", difficulty: 1, format: "short_answer", prompt: "Come si chiamava il funzionario egizio che sapeva leggere e scrivere e teneva i conti?", answer: "scriba", accept: ["lo scriba"], explanation: "Saper scrivere era un mestiere raro: dava potere e lo esentava dai lavori pesanti." },
  { topic: "egizi", difficulty: 1, format: "short_answer", prompt: "Quale fiume rendeva fertile l'Egitto con le sue piene?", answer: "Nilo", accept: ["il Nilo"], explanation: "Senza le piene l'Egitto sarebbe stato solo deserto." },
  { topic: "egizi", difficulty: 2, format: "short_answer", prompt: "Come si chiama la scrittura a immagini degli antichi Egizi?", answer: "geroglifici", accept: ["geroglifico", "scrittura geroglifica"], explanation: "Si decifrarono grazie alla stele di Rosetta." },
  { topic: "egizi", difficulty: 2, format: "short_answer", prompt: "Come si chiamano le tombe monumentali a base quadrata dei faraoni?", answer: "piramidi", accept: ["piramide"], explanation: "La più grande è quella di Cheope, a Giza." },
  { topic: "egizi", difficulty: 3, format: "short_answer", prompt: "Come si chiama la pianta con cui gli Egizi fabbricavano fogli su cui scrivere?", answer: "papiro", accept: ["il papiro"], explanation: "Cresceva sulle rive del Nilo: da lì la parola «carta» in molte lingue." },
  { topic: "grecia", difficulty: 1, format: "short_answer", prompt: "Come si chiamava la piazza principale della città greca, dove si discuteva e si commerciava?", answer: "agorà", accept: ["agora", "l'agorà"], explanation: "Mercato e assemblea nello stesso luogo: a Roma sarà il foro." },
  { topic: "grecia", difficulty: 2, format: "short_answer", prompt: "Quale città greca era famosa per l'addestramento militare dei suoi cittadini?", answer: "Sparta", explanation: "L'educazione del cittadino era soprattutto militare." },
  { topic: "grecia", difficulty: 2, format: "short_answer", prompt: "In quale città greca nacque la democrazia?", answer: "Atene", explanation: "Decidevano insieme i cittadini maschi adulti: non tutti gli abitanti." },
  { topic: "grecia", difficulty: 3, format: "short_answer", prompt: "Come si chiamavano i giochi che si tenevano ogni quattro anni in onore di Zeus?", answer: "olimpiadi", accept: ["giochi olimpici", "le olimpiadi"], explanation: "Durante i giochi le guerre si sospendevano." },
  { topic: "roma", difficulty: 1, format: "short_answer", prompt: "Su quale fiume sorge Roma?", answer: "Tevere", accept: ["il Tevere"], explanation: "Un guado sul Tevere: da lì è nata la città." },
  { topic: "roma", difficulty: 2, format: "short_answer", prompt: "Come si chiamava l'assemblea dei capifamiglia più autorevoli della Roma repubblicana?", answer: "senato", accept: ["il senato"], explanation: "Consigliava i magistrati e di fatto guidava la politica." },
  { topic: "roma", difficulty: 2, format: "short_answer", prompt: "Come si chiamavano i due magistrati eletti ogni anno a capo della repubblica romana?", answer: "consoli", accept: ["console", "i consoli"], explanation: "Erano due, e duravano un anno solo: due freni contro il potere personale." },
  { topic: "roma", difficulty: 3, format: "short_answer", prompt: "Chi fu il primo imperatore di Roma?", answer: "Augusto", accept: ["Ottaviano", "Ottaviano Augusto"], explanation: "Ottaviano prese il titolo di Augusto nel 27 avanti Cristo." },
  { topic: "roma", difficulty: 3, format: "short_answer", prompt: "Come si chiamavano le strade lastricate che collegavano Roma alle province?", answer: "strade consolari", accept: ["consolari", "vie consolari"], explanation: "Servivano prima all'esercito, poi ai commerci." },
  { topic: "medioevo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il sistema in cui il re concedeva terre in cambio di fedeltà e servizio militare?", answer: "feudalesimo", accept: ["sistema feudale"], explanation: "La terra si dava in feudo: da lì il nome." },
  { topic: "medioevo", difficulty: 2, format: "short_answer", prompt: "Come si chiamavano i monasteri in cui i monaci copiavano a mano i libri antichi?", answer: "scriptorium", accept: ["scriptoria", "lo scriptorium"], explanation: "Senza quelle copie molti testi antichi sarebbero andati perduti." },
  { topic: "medioevo", difficulty: 3, format: "short_answer", prompt: "Come si chiamavano le città italiane che nel Medioevo si diedero un governo autonomo?", answer: "comuni", accept: ["comune", "i comuni"], explanation: "Si reggevano da sé, spesso contro l'imperatore." },
  { topic: "medioevo", difficulty: 3, format: "short_answer", prompt: "Come si chiama la peste che nel Trecento uccise circa un terzo degli europei?", answer: "peste nera", accept: ["la peste nera", "morte nera"], explanation: "Arrivò dal mar Nero sulle navi mercantili." },
  { topic: "metodo", difficulty: 3, format: "short_answer", prompt: "Come si chiama il confronto fra più fonti per verificare se un fatto è attendibile?", answer: "incrocio delle fonti", accept: ["incrociare le fonti", "confronto delle fonti"], explanation: "Una fonte sola non basta mai: potrebbe avere interesse a raccontarla così." },
];

function storiaBank() {
  const rand = rng(20260734);
  return {
    schemaVersion: 1,
    subject: "storia",
    generator: "storia-authored-v1",
    // Via `authoredMcItems` e non a mano: cosi' anche storia puo' avere item a
    // risposta libera (`format: "numeric_input"`). Gli id restano gli stessi.
    items: authoredMcItems("storia", STORIA_CORE, rand),
  };
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

// Nucleo autorato di logica. Il banco generato copre bene le sequenze (26 item)
// e lascia quasi vuoti gli argomenti che chiedono di ragionare a parole:
// insiemi e verita' avevano UN item ciascuno. Sono proprio quelli che servono
// al mondo 24, dove il nodo di sintesi chiede di tenere insieme dodici metodi.
const LOGICA_EXTRA = [
  { topic: "insiemi", difficulty: 1, prompt: "Tutti i cani sono mammiferi. Allora l'insieme dei cani…", answer: "È contenuto in quello dei mammiferi", distractors: ["Contiene quello dei mammiferi","Non ha punti in comune con esso","Coincide con quello dei mammiferi"], explanation: "Ogni cane è un mammifero, ma non ogni mammifero è un cane: il gruppo più piccolo sta dentro quello più grande." },
  { topic: "insiemi", difficulty: 2, prompt: "Quali animali stanno sia nell'insieme «vola» sia in «ha le piume»?", answer: "Gli uccelli che volano", distractors: ["I pipistrelli e le farfalle","Tutti gli animali con le ali","I pinguini e gli struzzi"], explanation: "L'intersezione contiene solo ciò che soddisfa entrambe le condizioni: i pipistrelli volano ma non hanno piume." },
  { topic: "insiemi", difficulty: 2, prompt: "Che cosa contiene l'unione di due insiemi?", answer: "Tutti gli elementi dell'uno e dell'altro", distractors: ["Solo gli elementi comuni ai due","Solo gli elementi del primo insieme","Solo gli elementi che stanno in uno solo"], explanation: "L'unione mette insieme tutto; l'intersezione tiene solo quello che appartiene a entrambi." },
  { topic: "insiemi", difficulty: 3, prompt: "Che cosa contiene l'intersezione di «numeri pari» e «numeri maggiori di 10»?", answer: "12, 14, 16 e così via", distractors: ["Tutti i numeri pari esistenti","Tutti i numeri maggiori di dieci","Nessun numero, è vuota"], explanation: "Servono entrambe le proprietà insieme: pari E sopra il dieci. Il 12 le ha tutte e due, l'11 no e l'8 nemmeno." },
  { topic: "insiemi", difficulty: 3, prompt: "L'insieme dei quadrati è contenuto in quello dei rettangoli. Perché?", answer: "Perché ogni quadrato ha quattro angoli retti", distractors: ["Perché ogni rettangolo ha i lati uguali","Perché hanno sempre la stessa area","Perché entrambi hanno quattro lati"], explanation: "Un rettangolo è un quadrilatero con quattro angoli retti: il quadrato lo è, e in più ha i lati uguali." },
  { topic: "insiemi", difficulty: 2, prompt: "Che cos'è un insieme vuoto?", answer: "Un insieme che non contiene alcun elemento", distractors: ["Un insieme con un solo elemento","Un insieme di cui non si sa il contenuto","Un insieme uguale a tutti gli altri"], explanation: "Per esempio «i numeri pari dispari»: la condizione non può essere soddisfatta da nessuno." },
  { topic: "insiemi", difficulty: 4, prompt: "Due insiemi non hanno nessun elemento in comune. Come si dicono?", answer: "Disgiunti", distractors: ["Coincidenti","Contenuti","Complementari"], explanation: "Insiemi disgiunti hanno intersezione vuota: per esempio i numeri pari e i numeri dispari." },
  { topic: "insiemi", difficulty: 3, prompt: "Nel gruppo degli strumenti musicali, quello degli archi è…", answer: "Un sottoinsieme", distractors: ["Un insieme più grande","Un insieme disgiunto","L'insieme complementare"], explanation: "Ogni arco è uno strumento, ma esistono strumenti che non sono archi: la parte sta dentro il tutto." },
  { topic: "insiemi", difficulty: 4, format: "numeric_input", prompt: "In una classe, 12 fanno nuoto, 8 fanno musica, 3 fanno entrambe. Quanti ragazzi in tutto fanno almeno una delle due?", answer: "17", explanation: "12 + 8 fa 20, ma i 3 che fanno entrambe sono stati contati due volte: 20 − 3 = 17." },
  { topic: "insiemi", difficulty: 3, prompt: "Se A è contenuto in B e B è contenuto in C, allora…", answer: "A è contenuto in C", distractors: ["C è contenuto in A","A e C sono disgiunti","A e C sono lo stesso insieme"], explanation: "L'inclusione si trasmette: se ogni A è un B e ogni B è un C, allora ogni A è un C." },
  { topic: "insiemi", difficulty: 2, prompt: "Quale gruppo contiene tutti gli altri: cani, mammiferi, animali, vertebrati?", answer: "Animali", distractors: ["Vertebrati e mammiferi","Mammiferi soltanto","Cani e vertebrati"], explanation: "La scala va dal più ampio al più stretto: animali, vertebrati, mammiferi, cani." },
  { topic: "insiemi", difficulty: 4, prompt: "Che cos'è il complementare di un insieme?", answer: "Tutto ciò che sta fuori da quell'insieme", distractors: ["L'insieme che gli assomiglia di più","La metà mancante dell'insieme","L'insieme con gli stessi elementi"], explanation: "Dentro un gruppo di riferimento: il complementare dei pari, fra i numeri interi, sono i dispari." },
  { topic: "insiemi", difficulty: 3, prompt: "«Alcuni musicisti sono chitarristi» descrive due insiemi che…", answer: "Si sovrappongono in parte", distractors: ["Sono completamente separati","Coincidono perfettamente","Non hanno alcun elemento"], explanation: "Una parte dei musicisti suona la chitarra, un'altra no: gli insiemi si intersecano senza contenersi." },
  { topic: "insiemi", difficulty: 4, format: "numeric_input", prompt: "In un gruppo di 20 persone, 15 hanno il cane. Quante NON hanno il cane?", answer: "5", explanation: "È il complementare dentro il gruppo: 20 − 15 = 5." },
  { topic: "verita", difficulty: 2, prompt: "«Piove E fa freddo» è vera quando…", answer: "Piove e fa freddo insieme", distractors: ["Piove, anche se non fa freddo","Fa freddo, anche se non piove","Almeno una delle due è vera"], explanation: "La E richiede entrambe: basta che una sia falsa e tutta l'affermazione è falsa." },
  { topic: "verita", difficulty: 2, prompt: "«Piove O fa freddo» è falsa quando…", answer: "Non piove e non fa freddo", distractors: ["Piove ma non fa freddo","Fa freddo ma non piove","Piove e fa freddo insieme"], explanation: "La O si accontenta di una: perché sia falsa devono essere false tutte e due." },
  { topic: "verita", difficulty: 2, prompt: "Se «tutti i gatti dormono» è falsa, che cosa è sicuramente vero?", answer: "Almeno un gatto non dorme", distractors: ["Nessun gatto dorme","Tutti i gatti sono svegli","Metà dei gatti dorme"], explanation: "Per smentire un «tutti» basta un solo controesempio: non serve che sia vero il contrario di tutti." },
  { topic: "verita", difficulty: 3, prompt: "Qual è la negazione di «nessuno è arrivato»?", answer: "Almeno uno è arrivato", distractors: ["Tutti sono arrivati","Nessuno è partito","Molti sono arrivati"], explanation: "Negare un «nessuno» significa dire che ce n'è almeno uno, non che ci sono tutti." },
  { topic: "verita", difficulty: 3, prompt: "«Se piove, prendo l'ombrello.» Non ho preso l'ombrello. Cosa si conclude?", answer: "Non pioveva", distractors: ["Pioveva comunque","Ho dimenticato l'ombrello","Non si può concludere niente"], explanation: "Se l'effetto manca, manca anche la causa che lo garantiva: è la forma corretta del ragionamento." },
  { topic: "verita", difficulty: 4, prompt: "«Se piove, prendo l'ombrello.» Ho preso l'ombrello. Cosa si conclude?", answer: "Niente di certo: poteva esserci un altro motivo", distractors: ["Che sicuramente stava piovendo in quel momento","Che sicuramente non stava piovendo per niente","Che pioverà sicuramente nel corso della giornata"], explanation: "L'ombrello si può prendere anche per il sole o per abitudine: la regola non dice che sia l'unica ragione possibile." },
  { topic: "verita", difficulty: 3, prompt: "Qual è la negazione di «tutti i cigni sono bianchi»?", answer: "Esiste almeno un cigno non bianco", distractors: ["Nessun cigno è bianco","Tutti i cigni sono neri","Quasi tutti i cigni sono bianchi"], explanation: "Un'affermazione universale cade con un solo caso contrario: basta un cigno nero." },
  { topic: "verita", difficulty: 2, prompt: "«Non è vero che non piove» significa…", answer: "Piove", distractors: ["Non piove","Forse piove","Ha smesso di piovere"], explanation: "Due negazioni si annullano: negare la negazione riporta all'affermazione di partenza." },
  { topic: "verita", difficulty: 4, prompt: "«Tutti gli abitanti hanno un cane o un gatto.» Marco non ha cani. Cosa si conclude?", answer: "Marco ha un gatto", distractors: ["Marco non ha animali","Marco ha anche un cane","Non si può dire niente"], explanation: "La O richiede almeno una delle due: se una è esclusa, l'altra deve valere." },
  { topic: "verita", difficulty: 3, prompt: "Un'affermazione e la sua negazione possono essere entrambe vere?", answer: "No, mai", distractors: ["Sì, se sono complicate","Sì, in certi casi particolari","Dipende da chi le dice"], explanation: "È il principio di non contraddizione: se una è vera l'altra è falsa, senza eccezioni." },
  { topic: "verita", difficulty: 4, prompt: "«Se studio, passo l'esame.» Ho studiato ma non ho passato. Che cosa è falso?", answer: "La regola di partenza", distractors: ["Il fatto di aver studiato","Il risultato dell'esame","Nessuna delle due cose"], explanation: "Un solo caso in cui la premessa è vera e la conclusione falsa basta a smentire la regola." },
  { topic: "verita", difficulty: 2, format: "numeric_input", prompt: "Quante possibilità ci sono per il valore di verità di un'affermazione?", answer: "2", explanation: "Vero o falso: in logica classica non esistono vie di mezzo." },
  { topic: "verita", difficulty: 3, prompt: "«Ho preso il gelato E la torta» è falsa. Cosa si conclude?", answer: "Almeno una delle due non l'ho presa", distractors: ["Non ho preso nessuna delle due","Ho preso solo il gelato","Ho preso solo la torta"], explanation: "Per far cadere una E basta che uno dei due pezzi sia falso: non serve che lo siano entrambi." },
  { topic: "verita", difficulty: 4, prompt: "Perché «questa frase è falsa» crea un problema?", answer: "Perché se è vera è falsa, e viceversa", distractors: ["Perché è scritta in modo scorretto","Perché parla di sé stessa senza dati","Perché manca il soggetto della frase"], explanation: "È il paradosso del mentitore: una frase che parla della propria verità può non avere alcun valore coerente." },
  { topic: "quantificatori", difficulty: 2, prompt: "Quale parola indica che vale per ogni singolo caso?", answer: "Tutti", distractors: ["Alcuni","Molti","Quasi tutti"], explanation: "«Tutti» non ammette eccezioni: basta un caso contrario per renderlo falso." },
  { topic: "quantificatori", difficulty: 2, prompt: "«Alcuni uccelli non volano» significa che…", answer: "Almeno uno non vola", distractors: ["Nessun uccello vola","La maggior parte non vola","Tutti gli uccelli volano"], explanation: "In logica «alcuni» significa «almeno uno», anche se nel parlare comune suggerisce «parecchi»." },
  { topic: "quantificatori", difficulty: 3, prompt: "Da «tutti i cani abbaiano» si può dedurre che…", answer: "Almeno un cane abbaia, se i cani esistono", distractors: ["Soltanto i cani sanno abbaiare","Alcuni cani non abbaiano affatto","Chiunque abbaia dev'essere un cane"], explanation: "Da un «tutti» si scende ad «alcuni», ma non si può girare la frase: altri animali potrebbero abbaiare." },
  { topic: "quantificatori", difficulty: 3, prompt: "«Nessuno studente è arrivato in ritardo» è smentita da…", answer: "Un solo studente in ritardo", distractors: ["Metà degli studenti in ritardo","Tutti gli studenti in ritardo","Nessun controesempio possibile"], explanation: "Le affermazioni universali, positive o negative, cadono con un unico controesempio." },
  { topic: "quantificatori", difficulty: 4, prompt: "«Tutti i quadrati sono rettangoli» permette di dire che…", answer: "Alcuni rettangoli sono quadrati", distractors: ["Tutti i rettangoli sono quadrati","Nessun rettangolo è un quadrato","I due gruppi sono separati"], explanation: "Girando un «tutti» si ottiene solo un «alcuni»: l'inclusione vale in una direzione sola." },
  { topic: "quantificatori", difficulty: 2, prompt: "Qual è il contrario di «tutti»?", answer: "Non tutti", distractors: ["Nessuno","Pochi","Quasi nessuno"], explanation: "«Nessuno» è molto più forte: negare «tutti» richiede solo che ce ne sia uno fuori." },
  { topic: "quantificatori", difficulty: 3, prompt: "«Ogni chiave apre una porta» e «una porta è aperta da ogni chiave» dicono…", answer: "Due cose diverse", distractors: ["La stessa cosa in due modi","Due cose sempre false","Due cose sempre vere"], explanation: "Nella prima ogni chiave ha la sua porta; nella seconda esiste una porta che tutte le chiavi aprono. L'ordine dei quantificatori conta." },
  { topic: "quantificatori", difficulty: 4, prompt: "«Almeno due studenti hanno preso 10» è vera se ne hanno preso 10…", answer: "Due o più studenti", distractors: ["Esattamente due studenti","Meno di due studenti","Tutti gli studenti"], explanation: "«Almeno» fissa un minimo, non un numero esatto: tre, quattro o venti la rendono ugualmente vera." },
  { topic: "quantificatori", difficulty: 3, prompt: "Da «alcuni gatti sono neri» si può dedurre «tutti i gatti sono neri»?", answer: "No, in nessun caso", distractors: ["Sì, se i gatti sono pochi","Sì, se non ci sono controesempi","Dipende da quanti gatti sono neri"], explanation: "Da un caso particolare non si sale a una regola generale: è il salto che rende sbagliati molti ragionamenti." },
  { topic: "quantificatori", difficulty: 2, prompt: "«Nessun pesce vola» e «tutti i pesci non volano»…", answer: "Dicono la stessa cosa", distractors: ["Dicono cose opposte","La prima è più debole","La seconda è sempre falsa"], explanation: "Sono due modi di esprimere la stessa negazione universale." },
  { topic: "quantificatori", difficulty: 4, format: "numeric_input", prompt: "Per dimostrare che «tutti i numeri pari sono divisibili per 2», quanti esempi bastano?", answer: "0", explanation: "Nessun numero di esempi dimostra un «tutti»: serve una dimostrazione generale. Gli esempi possono solo smentirlo." },
  { topic: "quantificatori", difficulty: 3, prompt: "«Qualche volta il treno è in ritardo» equivale a…", answer: "Non sempre il treno è puntuale", distractors: ["Il treno è sempre in ritardo","Il treno non è mai puntuale","Il treno è quasi sempre in ritardo"], explanation: "«Qualche volta» nega il «sempre» senza affermare nulla sulla frequenza." },
  { topic: "quantificatori", difficulty: 4, prompt: "In una scatola ci sono solo palline rosse. È vero che «tutte le palline blu nella scatola sono grandi»?", answer: "Sì, perché non ce ne sono", distractors: ["No, perché non ce ne sono","Non si può stabilire","Solo se sono davvero grandi"], explanation: "Un'affermazione su un insieme vuoto non ha controesempi possibili, quindi è considerata vera. Si dice vera «a vuoto»." },
  { topic: "analogie", difficulty: 2, prompt: "Penna sta a scrivere come forbici sta a…", answer: "Tagliare", distractors: ["Cucire","Incollare","Misurare"], explanation: "La relazione è «strumento → azione che compie»: si cerca la stessa relazione, non una parola simile." },
  { topic: "analogie", difficulty: 3, prompt: "Medico sta a ospedale come insegnante sta a…", answer: "Scuola", distractors: ["Libro","Studente","Lezione"], explanation: "La relazione è «chi lavora → luogo di lavoro»: lo studente è una persona, la lezione un'attività." },
  { topic: "analogie", difficulty: 3, prompt: "Freddo sta a caldo come buio sta a…", answer: "Luce", distractors: ["Notte","Nero","Paura"], explanation: "La relazione è di opposizione. «Notte» è associata al buio ma non è il suo contrario." },
  { topic: "analogie", difficulty: 4, prompt: "Chilometro sta a distanza come chilogrammo sta a…", answer: "Massa", distractors: ["Bilancia","Peso di una persona","Grandezza"], explanation: "La relazione è «unità → grandezza misurata». La bilancia è lo strumento, non la grandezza." },
  { topic: "analogie", difficulty: 3, prompt: "Cucciolo sta a cane come puledro sta a…", answer: "Cavallo", distractors: ["Stalla","Corsa","Fieno"], explanation: "La relazione è «piccolo → animale adulto della stessa specie»." },
  { topic: "analogie", difficulty: 4, prompt: "Pagina sta a libro come fotogramma sta a…", answer: "Film", distractors: ["Cinema","Macchina fotografica","Attore"], explanation: "La relazione è «parte → intero di cui fa parte». Il cinema è il luogo, non l'opera." },
  { topic: "deduzioni", difficulty: 3, prompt: "Tutti i musicisti leggono le note. Sara legge le note. Sara è musicista?", answer: "Non necessariamente", distractors: ["Sì, sicuramente","No, di certo non lo è","Solo se suona uno strumento"], explanation: "La regola dice che i musicisti leggono le note, non che solo loro lo fanno: girarla è un errore classico." },
  { topic: "deduzioni", difficulty: 3, prompt: "Nessun rettile ha le piume. Kiwi ha le piume. Kiwi è un rettile?", answer: "No, di sicuro", distractors: ["Sì, potrebbe esserlo","Non si può stabilire","Solo se non vola"], explanation: "Se nessun rettile ha piume e Kiwi le ha, Kiwi sta fuori dall'insieme dei rettili." },
  { topic: "deduzioni", difficulty: 4, prompt: "Se A è più alto di B e B è più alto di C, allora…", answer: "A è più alto di C", distractors: ["C è più alto di A","A e C sono uguali","Non si può stabilire"], explanation: "«Più alto di» è una relazione transitiva: si trasmette lungo la catena." },
  { topic: "deduzioni", difficulty: 4, prompt: "Marta è più giovane di Luca. Luca è più giovane di Sara. Chi è il più vecchio?", answer: "Sara", distractors: ["Luca","Marta","Non si può dire"], explanation: "Mettendo in fila: Marta, Luca, Sara. L'ultima della catena è la più grande." },
  { topic: "deduzioni", difficulty: 3, prompt: "«Se il semaforo è verde, si passa.» Il semaforo è rosso. Si passa?", answer: "La regola non dice niente su questo caso", distractors: ["No, la regola lo vieta esplicitamente","Sì, la regola lo permette comunque","Solo se non arrivano altre auto"], explanation: "La regola copre il caso «verde»: sul rosso non si pronuncia. Serve un'altra regola per saperlo." },
  { topic: "esclusioni", difficulty: 3, prompt: "Quale non appartiene al gruppo: violino, viola, violoncello, flauto?", answer: "Flauto", distractors: ["Violino","Viola","Violoncello"], explanation: "Gli altri tre sono strumenti ad arco; il flauto è a fiato. Non conta la somiglianza del nome." },
  { topic: "esclusioni", difficulty: 3, prompt: "Quale non appartiene al gruppo: Roma, Parigi, Berlino, Sicilia?", answer: "Sicilia", distractors: ["Roma","Parigi","Berlino"], explanation: "Le altre tre sono capitali; la Sicilia è un'isola, non una città." },
  { topic: "esclusioni", difficulty: 4, prompt: "Quale non appartiene al gruppo: 2, 3, 5, 9?", answer: "9", distractors: ["2","3","5"], explanation: "Gli altri sono numeri primi; 9 si divide anche per 3. Non basta guardare se sono dispari." },
  { topic: "esclusioni", difficulty: 4, prompt: "Quale non appartiene al gruppo: quadrato, cerchio, triangolo, rettangolo?", answer: "Cerchio", distractors: ["Quadrato","Triangolo","Rettangolo"], explanation: "Gli altri sono poligoni, cioè figure con i lati dritti; il cerchio è delimitato da una curva." },
  { topic: "sequenze", difficulty: 1, prompt: "Quale figura continua la serie: cerchio, quadrato, cerchio, quadrato, ?", answer: "cerchio", distractors: ["quadrato", "triangolo", "nessuna delle due"], explanation: "La serie alterna due figure: dopo il quadrato tocca di nuovo al cerchio. Una regola che si ripete a coppie si scopre guardando due passi, non uno." },
  { topic: "sequenze", difficulty: 1, prompt: "Quale numero continua la serie: 2, 4, 6, 8, ?", answer: "10", distractors: ["9", "12", "16"], explanation: "Fra un numero e il successivo ci sono sempre due: la regola è «+2», e vale anche fra 8 e il termine dopo." },
  { topic: "sequenze", difficulty: 1, prompt: "Quale numero continua la serie: 10, 9, 8, 7, ?", answer: "6", distractors: ["8", "5", "11"], explanation: "Qui la serie scende di uno per volta: le regole possono anche togliere, non solo aggiungere." },
  { topic: "sequenze", difficulty: 2, prompt: "Quale numero continua la serie: 1, 2, 4, 8, ?", answer: "16", distractors: ["10", "12", "9"], explanation: "Ogni numero è il doppio del precedente. Quando i salti crescono in fretta conviene provare a moltiplicare, non ad aggiungere." },
  { topic: "sequenze", difficulty: 2, prompt: "Quale lettera continua la serie: A, C, E, G, ?", answer: "I", distractors: ["H", "F", "L"], explanation: "Si salta una lettera ogni volta: A, (B), C, (D), E… Dopo la G si salta la H e si arriva alla I." },
  { topic: "esclusioni", difficulty: 1, prompt: "Quale non appartiene al gruppo: cane, gatto, cavallo, sedia?", answer: "sedia", distractors: ["cane", "gatto", "cavallo"], explanation: "Tre sono animali e uno è un oggetto. Per trovare l'intruso si cerca la proprietà che hanno TUTTI gli altri, non quella che manca a uno solo." },
  { topic: "esclusioni", difficulty: 1, prompt: "Quale non appartiene al gruppo: lunedì, martedì, gennaio, giovedì?", answer: "gennaio", distractors: ["lunedì", "martedì", "giovedì"], explanation: "Tre sono giorni della settimana, gennaio è un mese: appartengono a due scale di tempo diverse." },
  { topic: "esclusioni", difficulty: 2, prompt: "Quale non appartiene al gruppo: 2, 4, 7, 8?", answer: "7", distractors: ["2", "4", "8"], explanation: "Tre sono pari e il 7 è dispari. Con i numeri l'intruso si cerca fra le proprietà — pari, dispari, primo — non fra le cifre." },
  { topic: "esclusioni", difficulty: 2, prompt: "Quale non appartiene al gruppo: martello, cacciavite, pinza, mela?", answer: "mela", distractors: ["martello", "cacciavite", "pinza"], explanation: "Tre servono a lavorare, la mela si mangia: la categoria è l'uso, non la forma." },
  { topic: "analogie", difficulty: 1, prompt: "Caldo sta a freddo come alto sta a…?", answer: "basso", distractors: ["grande", "lungo", "veloce"], explanation: "La relazione è «il contrario di». Trovata la relazione nella prima coppia, si applica identica alla seconda." },
  { topic: "analogie", difficulty: 1, prompt: "Uccello sta a volare come pesce sta a…?", answer: "nuotare", distractors: ["camminare", "correre", "saltare"], explanation: "La relazione è «come si sposta»: ogni animale va con il movimento del suo ambiente." },
  { topic: "analogie", difficulty: 2, prompt: "Libro sta a leggere come cibo sta a…?", answer: "mangiare", distractors: ["cucinare", "comprare", "servire"], explanation: "La relazione è «che cosa se ne fa»: del libro si legge, del cibo si mangia. Cucinare viene prima, non è l'uso finale." },
  { topic: "analogie", difficulty: 2, prompt: "Medico sta a ospedale come insegnante sta a…?", answer: "scuola", distractors: ["libro", "lavagna", "studente"], explanation: "La relazione è «dove lavora». Lavagna e studente stanno nella scuola, ma non sono il luogo." },
  { topic: "insiemi", difficulty: 1, prompt: "Tutti i quadrati sono rettangoli. Allora un quadrato è anche…", answer: "un rettangolo", distractors: ["un triangolo", "un cerchio", "nessuna delle due"], explanation: "Se un insieme è dentro un altro, tutto ciò che sta nel piccolo sta anche nel grande. Non vale al contrario: non tutti i rettangoli sono quadrati." },
  { topic: "insiemi", difficulty: 2, prompt: "In una classe tutti giocano a calcio o a pallavolo. Marco non gioca a calcio. Allora…", answer: "gioca a pallavolo", distractors: ["non gioca a niente", "gioca a entrambi", "non si può sapere"], explanation: "«O l'uno o l'altro» copre tutti: escluso il primo resta per forza il secondo. Funziona solo perché la frase dice TUTTI." },
  { topic: "verita", difficulty: 1, prompt: "«Tutti i gatti hanno quattro zampe.» Per smentirla basta…", answer: "trovare un gatto senza quattro zampe", distractors: ["contare molti gatti con quattro zampe", "chiedere a un veterinario", "guardare anche i cani"], explanation: "Una frase con «tutti» cade con un solo controesempio. Trovare mille casi favorevoli non la dimostra; trovarne uno contrario la abbatte." },
  { topic: "verita", difficulty: 2, prompt: "«Qualche uccello non vola.» Per dimostrarla basta…", answer: "trovare un uccello che non vola", distractors: ["trovare molti uccelli che volano", "dimostrare che nessuno vola", "contare tutti gli uccelli"], explanation: "«Qualche» chiede un solo caso: il pinguino basta. È il rovescio di «tutti», che invece un solo caso lo distrugge." },
  { topic: "quantificatori", difficulty: 1, prompt: "Qual è il contrario di «tutti i cani abbaiano»?", answer: "almeno un cane non abbaia", distractors: ["nessun cane abbaia", "tutti i cani tacciono", "qualche cane abbaia"], explanation: "Negare «tutti» non dà «nessuno»: dà «almeno uno no». Sono due frasi molto diverse, e scambiarle è l'errore più comune." },
  { topic: "quantificatori", difficulty: 2, prompt: "«Nessuno studente è arrivato in ritardo.» Se ne trovi uno in ritardo, la frase è…", answer: "falsa", distractors: ["ancora vera", "vera a metà", "non si può dire"], explanation: "«Nessuno» non ammette eccezioni: un solo caso contrario la rende falsa, senza vie di mezzo." },
  { topic: "deduzioni", difficulty: 2, prompt: "Tutti i cuochi sanno cucinare. Anna è una cuoca. Quindi Anna…", answer: "sa cucinare", distractors: ["non sa cucinare", "forse sa cucinare", "cucina solo dolci"], explanation: "Se la regola vale per tutti e Anna sta nel gruppo, la conclusione è obbligata: non è probabile, è certa." },
];

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
    { difficulty: 4, prompt: "Marco è più alto di Sara. Sara è più alta di Ugo. Chi è il più basso?", answer: "Ugo", distractors: ["Marco", "Sara", "Sono uguali"], explanation: "Due confronti si incatenano quando hanno un termine in comune: qui è Sara. Messa in fila la catena, il più basso sta all'ultimo posto." },
    { difficulty: 4, prompt: "Nella scatola ci sono solo palline rosse e blu. Ne peschi una e NON è rossa. Allora è…", answer: "blu", distractors: ["rossa", "verde", "non si può sapere"], explanation: "Ci sono solo rosse e blu: se non è rossa, per forza è blu." },
  ];
  for (const q of deduzioni) {
    items.push(multipleChoiceItem({ id: `logica-deduzione-${q.prompt.length}-${q.answer}`, subject: "logica", topic: "deduzioni", difficulty: q.difficulty, prompt: q.prompt, answer: q.answer, distractors: q.distractors, explanation: q.explanation }, rand));
  }
  items.push(...authoredMcItems("logica", LOGICA_EXTRA, rand));
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
      // Un duplicato non deve essere identico per essere un duplicato: due
      // opzioni che dicono la stessa cosa con l'articolo diverso sono due
      // risposte giuste, e il confronto fra stringhe non le vede.
      for (let a = 0; a < item.options.length; a += 1) {
        for (let b = a + 1; b < item.options.length; b += 1) {
          if (tooSimilar(item.options[a], item.options[b])) {
            problems.push(`opzioni quasi identiche: "${item.options[a]}" / "${item.options[b]}"`);
          }
        }
      }
    }
    if (problems.length > 0) {
      throw new Error(`Banco '${name}' item '${item.id}': ${problems.join(", ")}`);
    }
  }

  // AMBIGUITÀ: due item con la STESSA domanda e risposte diverse.
  //
  // Non è un difetto teorico. Il 3 agosto 2026 il banco di inglese ne aveva
  // cinque: «Cosa significa in italiano "report"?» valeva sia «riferire» sia
  // «relazione», «Come si dice in inglese "sotto"?» sia below sia under.
  // Qualunque risposta desse il bambino, una volta su due era segnata
  // sbagliata — e nessun controllo se ne accorgeva, perché ogni item preso da
  // solo era formalmente perfetto.
  //
  // Nasce sempre allo stesso modo: due voci di categorie diverse che
  // condividono il termine o il significato. Si corregge nella SORGENTE
  // dicendo quale senso si intende, non qui.
  const byPrompt = new Map();
  for (const item of bank.items) {
    byPrompt.set(item.prompt, (byPrompt.get(item.prompt) ?? new Set()).add(item.answer));
  }
  const ambiguous = [...byPrompt].filter(([, answers]) => answers.size > 1);
  if (ambiguous.length > 0) {
    const detail = ambiguous
      .slice(0, 5)
      .map(([prompt, answers]) => `  ${prompt} → ${[...answers].join(" | ")}`)
      .join("\n");
    throw new Error(
      `Banco '${name}': ${ambiguous.length} domande con due risposte ugualmente giuste.\n${detail}`,
    );
  }
}

// ---------------------------------------------------------------------------
// Bake
// ---------------------------------------------------------------------------

const tsUrl = (...parts) => pathToFileURL(join(root, "src", "data", "procedural", ...parts)).href;
const dataUrl = (...parts) => pathToFileURL(join(root, "src", "data", ...parts)).href;
const [italianMod, englishMod, latinMod, circuitMod, pythonMod, greenhouseMod] = await Promise.all([
  import(tsUrl("italianVocabularyBank.ts")),
  import(tsUrl("englishVocabularyBank.ts")),
  import(tsUrl("latinCurriculum.ts")),
  import(tsUrl("circuitTemplates.ts")),
  import(tsUrl("pythonPrinciples.ts")),
  import(dataUrl("greenhouse.ts")),
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
  "storia-base": storiaBank(),
  "logica-base": logicaBank(),
};

// ---------------------------------------------------------------------------
// Item curati, appesi in coda al banco generato
// ---------------------------------------------------------------------------
//
// Nascono dalla Fase 4 del piano profondità («bande vuote dei banchi»): musica e
// fisica avevano tre item a difficoltà 1, coding uno a difficoltà 4. Sono scritti
// a mano perché riempiono buchi precisi di (argomento, difficoltà) che nessun
// generatore copre.
//
// Fino al 3 agosto 2026 vivevano SOLO dentro `godot/data/banks/*.json`, che è un
// prodotto di questo script: chiunque avesse rieseguito il bake li avrebbe
// cancellati tutti e ottantanove senza un solo errore a schermo. È successo, ed
// è per questo che ora stanno qui.
//
// Le opzioni sono riportate nell'ordine originale, non rimescolate: la posizione
// della risposta è già distribuita sulle quattro caselle e `giveaway_audit`
// verifica che resti così.
const CURATED_TAIL = {
  "coding-base": [
    {
      "id": "coding-algoritmi-che-cosa-distingue-un-algoritmo-da-un-elenco-di-",
      "subject": "coding",
      "topic": "algoritmi",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa distingue un algoritmo da un elenco di istruzioni qualsiasi?",
      "options": [
        "Termina sempre dopo passi finiti",
        "È scritto in un solo linguaggio",
        "Usa sempre almeno un ciclo",
        "Contiene almeno una funzione"
      ],
      "answer": "Termina sempre dopo passi finiti",
      "explanation": "Un algoritmo deve essere finito: deve arrivare a una fine."
    },
    {
      "id": "coding-cicli-quante-volte-esegue-il-corpo-il-ciclo-for-i-in-r",
      "subject": "coding",
      "topic": "cicli",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Quante volte esegue il corpo il ciclo «for i in range(2, 10, 3)»?",
      "options": [
        "Quattro volte",
        "Tre volte",
        "Otto volte",
        "Dieci volte"
      ],
      "answer": "Tre volte",
      "explanation": "I valori sono 2, 5 e 8: si ferma prima di 10, quindi tre giri."
    },
    {
      "id": "coding-liste-che-cosa-restituisce-len-1-2-3-4",
      "subject": "coding",
      "topic": "liste",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa restituisce «len([1, [2, 3], 4])»?",
      "options": [
        "4",
        "2",
        "3",
        "5"
      ],
      "answer": "3",
      "explanation": "La lista ha tre elementi: un numero, una lista annidata e un numero."
    },
    {
      "id": "coding-stringhe-che-cosa-stampa-print-abc-1",
      "subject": "coding",
      "topic": "stringhe",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa stampa «print('abc'[1])»?",
      "options": [
        "a",
        "c",
        "bc",
        "b"
      ],
      "answer": "b",
      "explanation": "Gli indici partono da zero, quindi la posizione 1 è la lettera b."
    },
    {
      "id": "coding-funzioni-una-funzione-senza-return-esplicito-restituisce",
      "subject": "coding",
      "topic": "funzioni",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Una funzione senza «return» esplicito restituisce...",
      "options": [
        "None",
        "Zero",
        "Una stringa vuota",
        "L'ultimo valore calcolato"
      ],
      "answer": "None",
      "explanation": "In Python una funzione che non ritorna nulla restituisce None."
    },
    {
      "id": "coding-booleani-che-valore-ha-not-true-and-false",
      "subject": "coding",
      "topic": "booleani",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che valore ha «not (True and False)»?",
      "options": [
        "False",
        "True",
        "None",
        "Zero"
      ],
      "answer": "True",
      "explanation": "True and False dà False, e la negazione di False è True."
    },
    {
      "id": "coding-operatori-che-cosa-restituisce-17-5",
      "subject": "coding",
      "topic": "operatori",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa restituisce «17 % 5»?",
      "options": [
        "3",
        "12",
        "2",
        "85"
      ],
      "answer": "2",
      "explanation": "L'operatore % dà il resto: 17 diviso 5 fa 3 con resto 2."
    },
    {
      "id": "coding-operatori-che-cosa-restituisce-17-5-2",
      "subject": "coding",
      "topic": "operatori",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa restituisce «17 // 5»?",
      "options": [
        "2",
        "3.4",
        "85",
        "3"
      ],
      "answer": "3",
      "explanation": "La doppia barra dà il quoziente intero, scartando il resto."
    },
    {
      "id": "coding-condizioni-in-un-if-elif-else-quanti-rami-vengono-eseguiti",
      "subject": "coding",
      "topic": "condizioni",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "In un «if / elif / else», quanti rami vengono eseguiti?",
      "options": [
        "Esattamente uno",
        "Tutti quelli veri",
        "Sempre almeno due",
        "Nessuno se manca else"
      ],
      "answer": "Esattamente uno",
      "explanation": "La catena si ferma al primo ramo vero: ne esegue uno solo."
    },
    {
      "id": "coding-variabili-dopo-a-3-e-b-a-e-a-7-quanto-vale-b",
      "subject": "coding",
      "topic": "variabili",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Dopo «a = 3» e «b = a» e «a = 7», quanto vale b?",
      "options": [
        "7",
        "3",
        "10",
        "None"
      ],
      "answer": "3",
      "explanation": "b ha copiato il valore 3 prima che a cambiasse."
    },
    {
      "id": "coding-tipi-che-tipo-restituisce-10-2-in-python-3",
      "subject": "coding",
      "topic": "tipi",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che tipo restituisce «10 / 2» in Python 3?",
      "options": [
        "Un numero intero",
        "Una stringa di testo",
        "Un numero con la virgola",
        "Un valore booleano"
      ],
      "answer": "Un numero con la virgola",
      "explanation": "La divisione con una barra sola dà sempre un float: 5.0."
    },
    {
      "id": "coding-stile-perche-conviene-dare-nomi-parlanti-alle-variabil",
      "subject": "coding",
      "topic": "stile",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Perché conviene dare nomi parlanti alle variabili?",
      "options": [
        "Rende il programma più veloce",
        "Riduce la memoria occupata",
        "Evita di dover usare i cicli",
        "Rende il codice comprensibile"
      ],
      "answer": "Rende il codice comprensibile",
      "explanation": "Il nome giusto spiega il codice senza bisogno di commenti."
    }
  ],
  "elettronica-base": [
    {
      "id": "elettronica-elettricita-base-che-cosa-fornisce-l-energia-in-un-circuito-con-l",
      "subject": "elettronica",
      "topic": "elettricita-base",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa fornisce l'energia in un circuito con la lampadina?",
      "options": [
        "La pila",
        "Il filo",
        "L'interruttore",
        "La lampadina"
      ],
      "answer": "La pila",
      "explanation": "La pila è la sorgente: spinge la corrente nel circuito."
    },
    {
      "id": "elettronica-elettricita-base-a-che-cosa-serve-l-interruttore-in-un-circuito",
      "subject": "elettronica",
      "topic": "elettricita-base",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "A che cosa serve l'interruttore in un circuito?",
      "options": [
        "Aumenta la tensione",
        "Apre e chiude il passaggio",
        "Produce la corrente",
        "Illumina la stanza"
      ],
      "answer": "Apre e chiude il passaggio",
      "explanation": "L'interruttore interrompe o ristabilisce il percorso della corrente."
    },
    {
      "id": "elettronica-conduttori-quale-di-questi-materiali-conduce-la-corrente",
      "subject": "elettronica",
      "topic": "conduttori",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale di questi materiali conduce la corrente?",
      "options": [
        "La plastica",
        "Il legno",
        "Il rame",
        "La gomma"
      ],
      "answer": "Il rame",
      "explanation": "I metalli come il rame lasciano passare facilmente la corrente."
    },
    {
      "id": "elettronica-conduttori-quale-di-questi-materiali-non-conduce-la-corrent",
      "subject": "elettronica",
      "topic": "conduttori",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale di questi materiali NON conduce la corrente?",
      "options": [
        "Il rame",
        "Il ferro",
        "L'alluminio",
        "La gomma"
      ],
      "answer": "La gomma",
      "explanation": "La gomma è un isolante: per questo riveste i cavi elettrici."
    },
    {
      "id": "elettronica-circuito-perche-una-lampadina-non-si-accende-se-il-circui",
      "subject": "elettronica",
      "topic": "circuito",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Perché una lampadina non si accende se il circuito è aperto?",
      "options": [
        "La corrente non può passare",
        "La pila è sempre scarica",
        "Il filo è troppo corto",
        "La lampadina è troppo grande"
      ],
      "answer": "La corrente non può passare",
      "explanation": "Serve un percorso chiuso perché la corrente possa circolare."
    }
  ],
  "fisica-base": [
    {
      "id": "fisica-misure-con-quale-strumento-si-misura-la-lunghezza",
      "subject": "fisica",
      "topic": "misure",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Con quale strumento si misura la lunghezza?",
      "options": [
        "Il righello",
        "La bilancia",
        "Il termometro",
        "Il cronometro"
      ],
      "answer": "Il righello",
      "explanation": "Il righello confronta l'oggetto con una scala di centimetri."
    },
    {
      "id": "fisica-misure-con-quale-strumento-si-misura-la-massa",
      "subject": "fisica",
      "topic": "misure",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Con quale strumento si misura la massa?",
      "options": [
        "Il righello",
        "La bilancia",
        "Il cronometro",
        "Il termometro"
      ],
      "answer": "La bilancia",
      "explanation": "La bilancia confronta la massa con dei pesi noti."
    },
    {
      "id": "fisica-misure-con-quale-strumento-si-misura-la-temperatura",
      "subject": "fisica",
      "topic": "misure",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Con quale strumento si misura la temperatura?",
      "options": [
        "La bilancia",
        "Il righello",
        "Il termometro",
        "Il cronometro"
      ],
      "answer": "Il termometro",
      "explanation": "Nel termometro il liquido si dilata quando fa più caldo."
    },
    {
      "id": "fisica-misure-qual-e-l-unita-di-misura-del-tempo",
      "subject": "fisica",
      "topic": "misure",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Qual è l'unità di misura del tempo?",
      "options": [
        "Il metro",
        "Il grammo",
        "Il grado",
        "Il secondo"
      ],
      "answer": "Il secondo",
      "explanation": "Nel sistema internazionale il tempo si misura in secondi."
    },
    {
      "id": "fisica-moto-un-oggetto-fermo-che-comincia-a-muoversi-ha-rice",
      "subject": "fisica",
      "topic": "moto",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Un oggetto fermo che comincia a muoversi ha ricevuto...",
      "options": [
        "una forza",
        "un colore",
        "una massa",
        "un suono"
      ],
      "answer": "una forza",
      "explanation": "Serve una forza per cambiare il moto di un corpo."
    },
    {
      "id": "fisica-moto-chi-va-piu-veloce-fra-questi",
      "subject": "fisica",
      "topic": "moto",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Chi va più veloce fra questi?",
      "options": [
        "Una lumaca",
        "Un'automobile",
        "Una persona a piedi",
        "Una tartaruga"
      ],
      "answer": "Un'automobile",
      "explanation": "L'automobile percorre molta più strada nello stesso tempo."
    },
    {
      "id": "fisica-forze-che-cosa-fa-cadere-gli-oggetti-verso-il-basso",
      "subject": "fisica",
      "topic": "forze",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa fa cadere gli oggetti verso il basso?",
      "options": [
        "La forza magnetica",
        "La spinta del vento",
        "La forza di gravità",
        "L'attrito dell'aria"
      ],
      "answer": "La forza di gravità",
      "explanation": "La gravità attira ogni corpo verso il centro della Terra."
    },
    {
      "id": "fisica-forze-che-cosa-rallenta-una-palla-che-rotola-sul-pavim",
      "subject": "fisica",
      "topic": "forze",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa rallenta una palla che rotola sul pavimento?",
      "options": [
        "La gravità",
        "Il magnetismo",
        "La luce",
        "L'attrito"
      ],
      "answer": "L'attrito",
      "explanation": "L'attrito fra palla e pavimento consuma il movimento."
    },
    {
      "id": "fisica-materia-l-acqua-a-temperatura-ambiente-si-trova-allo-sta",
      "subject": "fisica",
      "topic": "materia",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "L'acqua a temperatura ambiente si trova allo stato...",
      "options": [
        "liquido",
        "solido",
        "gassoso",
        "acceso"
      ],
      "answer": "liquido",
      "explanation": "A temperatura ambiente l'acqua scorre: è liquida."
    },
    {
      "id": "fisica-materia-il-ghiaccio-e-acqua-allo-stato",
      "subject": "fisica",
      "topic": "materia",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Il ghiaccio è acqua allo stato...",
      "options": [
        "liquido",
        "solido",
        "gassoso",
        "invisibile"
      ],
      "answer": "solido",
      "explanation": "Sotto lo zero l'acqua si solidifica e diventa ghiaccio."
    }
  ],
  "logica-base": [
    {
      "id": "logica-esclusioni-quale-elemento-non-appartiene-al-gruppo-cane-gat",
      "subject": "logica",
      "topic": "esclusioni",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale elemento non appartiene al gruppo: cane, gatto, cavallo, sedia?",
      "options": [
        "Sedia",
        "Cane",
        "Gatto",
        "Cavallo"
      ],
      "answer": "Sedia",
      "explanation": "Gli altri tre sono animali, la sedia è un oggetto."
    },
    {
      "id": "logica-esclusioni-quale-elemento-non-appartiene-al-gruppo-rosso-bl",
      "subject": "logica",
      "topic": "esclusioni",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale elemento non appartiene al gruppo: rosso, blu, verde, tavolo?",
      "options": [
        "Rosso",
        "Tavolo",
        "Blu",
        "Verde"
      ],
      "answer": "Tavolo",
      "explanation": "Gli altri tre sono colori, il tavolo è un mobile."
    },
    {
      "id": "logica-esclusioni-quale-elemento-non-appartiene-al-gruppo-mela-per",
      "subject": "logica",
      "topic": "esclusioni",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale elemento non appartiene al gruppo: mela, pera, banana, martello?",
      "options": [
        "Mela",
        "Pera",
        "Martello",
        "Banana"
      ],
      "answer": "Martello",
      "explanation": "Gli altri tre sono frutti, il martello è un attrezzo."
    },
    {
      "id": "logica-sequenze-quale-numero-continua-la-sequenza-2-4-6-8",
      "subject": "logica",
      "topic": "sequenze",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale numero continua la sequenza: 2, 4, 6, 8, ...?",
      "options": [
        "9",
        "12",
        "16",
        "10"
      ],
      "answer": "10",
      "explanation": "Ogni termine aumenta di due: dopo l'8 viene il 10."
    },
    {
      "id": "logica-sequenze-quale-numero-continua-la-sequenza-5-10-15-20",
      "subject": "logica",
      "topic": "sequenze",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale numero continua la sequenza: 5, 10, 15, 20, ...?",
      "options": [
        "25",
        "30",
        "22",
        "40"
      ],
      "answer": "25",
      "explanation": "Ogni termine aumenta di cinque: dopo il 20 viene il 25."
    },
    {
      "id": "logica-sequenze-quale-numero-continua-la-sequenza-10-9-8-7",
      "subject": "logica",
      "topic": "sequenze",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale numero continua la sequenza: 10, 9, 8, 7, ...?",
      "options": [
        "5",
        "6",
        "8",
        "11"
      ],
      "answer": "6",
      "explanation": "Ogni termine diminuisce di uno: dopo il 7 viene il 6."
    },
    {
      "id": "logica-analogie-il-cane-sta-alla-cuccia-come-l-uccello-sta-al",
      "subject": "logica",
      "topic": "analogie",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Il cane sta alla cuccia come l'uccello sta al...",
      "options": [
        "cielo",
        "becco",
        "nido",
        "volo"
      ],
      "answer": "nido",
      "explanation": "In entrambi i casi si tratta del posto in cui l'animale abita."
    },
    {
      "id": "logica-analogie-la-penna-sta-allo-scrivere-come-le-forbici-stann",
      "subject": "logica",
      "topic": "analogie",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "La penna sta allo scrivere come le forbici stanno al...",
      "options": [
        "cucire",
        "misurare",
        "disegnare",
        "tagliare"
      ],
      "answer": "tagliare",
      "explanation": "In entrambi i casi si tratta di ciò per cui l'oggetto serve."
    },
    {
      "id": "logica-deduzioni-tutti-i-gatti-sono-felini-micio-e-un-gatto-che-c",
      "subject": "logica",
      "topic": "deduzioni",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Tutti i gatti sono felini. Micio è un gatto. Che cosa segue con certezza?",
      "options": [
        "Micio è un felino",
        "Ogni felino è un gatto",
        "Micio è un mammifero raro",
        "Alcuni felini non sono gatti"
      ],
      "answer": "Micio è un felino",
      "explanation": "La conclusione deve stare dentro le premesse: gatto implica felino."
    },
    {
      "id": "logica-deduzioni-se-piove-allora-la-strada-e-bagnata-e-la-strada-",
      "subject": "logica",
      "topic": "deduzioni",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Se «piove, allora la strada è bagnata» e la strada è bagnata, che cosa segue?",
      "options": [
        "Sta piovendo di sicuro",
        "Nulla di certo",
        "Non sta piovendo",
        "Pioverà domani"
      ],
      "answer": "Nulla di certo",
      "explanation": "La strada può essere bagnata per altri motivi: la regola non si inverte."
    },
    {
      "id": "logica-deduzioni-se-piove-allora-la-strada-e-bagnata-e-la-strada--2",
      "subject": "logica",
      "topic": "deduzioni",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Se «piove, allora la strada è bagnata» e la strada è asciutta, che cosa segue?",
      "options": [
        "Sta piovendo",
        "Nulla di certo",
        "Non sta piovendo",
        "Pioverà fra poco"
      ],
      "answer": "Non sta piovendo",
      "explanation": "Se piovesse la strada sarebbe bagnata: quindi non piove."
    },
    {
      "id": "logica-sequenze-quale-numero-continua-la-sequenza-3-6-5-10-9",
      "subject": "logica",
      "topic": "sequenze",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Quale numero continua la sequenza: 3, 6, 5, 10, 9, ...?",
      "options": [
        "12",
        "11",
        "8",
        "18"
      ],
      "answer": "18",
      "explanation": "La regola alterna: si raddoppia, poi si toglie uno, poi si raddoppia."
    }
  ],
  "musica-base": [
    {
      "id": "musica-note-quante-note-ha-la-scala-musicale-di-base",
      "subject": "musica",
      "topic": "note",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quante note ha la scala musicale di base?",
      "options": [
        "Sette",
        "Cinque",
        "Nove",
        "Dodici"
      ],
      "answer": "Sette",
      "explanation": "Do, re, mi, fa, sol, la, si: sette note che poi ricominciano."
    },
    {
      "id": "musica-note-quale-nota-viene-subito-dopo-il-mi",
      "subject": "musica",
      "topic": "note",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale nota viene subito dopo il MI?",
      "options": [
        "Re",
        "Fa",
        "Sol",
        "La"
      ],
      "answer": "Fa",
      "explanation": "L'ordine è do, re, mi, fa, sol, la, si: dopo il mi viene il fa."
    },
    {
      "id": "musica-note-quale-nota-viene-subito-prima-del-do",
      "subject": "musica",
      "topic": "note",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale nota viene subito prima del DO?",
      "options": [
        "Re",
        "La",
        "Si",
        "Fa"
      ],
      "answer": "Si",
      "explanation": "La scala si chiude con il si e poi ricomincia dal do."
    },
    {
      "id": "musica-strumenti-la-chitarra-fa-parte-della-famiglia-degli-strume",
      "subject": "musica",
      "topic": "strumenti",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "La chitarra fa parte della famiglia degli strumenti...",
      "options": [
        "a fiato",
        "a percussione",
        "a tastiera",
        "a corda"
      ],
      "answer": "a corda",
      "explanation": "Il suono della chitarra nasce dalle corde che vibrano."
    },
    {
      "id": "musica-strumenti-il-tamburo-fa-parte-della-famiglia-degli-strumen",
      "subject": "musica",
      "topic": "strumenti",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Il tamburo fa parte della famiglia degli strumenti...",
      "options": [
        "a percussione",
        "a corda",
        "a fiato",
        "a tastiera"
      ],
      "answer": "a percussione",
      "explanation": "Il tamburo suona quando viene percosso: è una percussione."
    },
    {
      "id": "musica-strumenti-il-flauto-fa-parte-della-famiglia-degli-strument",
      "subject": "musica",
      "topic": "strumenti",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Il flauto fa parte della famiglia degli strumenti...",
      "options": [
        "a corda",
        "a fiato",
        "a percussione",
        "a tastiera"
      ],
      "answer": "a fiato",
      "explanation": "Nel flauto è l'aria soffiata a produrre il suono."
    },
    {
      "id": "musica-ritmo-che-cosa-indica-il-ritmo-di-un-brano",
      "subject": "musica",
      "topic": "ritmo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa indica il ritmo di un brano?",
      "options": [
        "Il colore del suono",
        "L'altezza dei suoni",
        "La durata dei suoni",
        "Il volume dei suoni"
      ],
      "answer": "La durata dei suoni",
      "explanation": "Il ritmo organizza quanto dura ogni suono e ogni silenzio."
    },
    {
      "id": "musica-ritmo-una-pausa-in-musica-serve-a-indicare",
      "subject": "musica",
      "topic": "ritmo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Una pausa in musica serve a indicare...",
      "options": [
        "una nota acuta",
        "una nota grave",
        "un suono forte",
        "un silenzio"
      ],
      "answer": "un silenzio",
      "explanation": "La pausa dice per quanto tempo non si suona: è silenzio scritto."
    },
    {
      "id": "musica-dinamica-il-segno-piano-p-chiede-di-suonare",
      "subject": "musica",
      "topic": "dinamica",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Il segno «piano» (p) chiede di suonare...",
      "options": [
        "a volume basso",
        "a volume alto",
        "molto veloce",
        "molto lento"
      ],
      "answer": "a volume basso",
      "explanation": "Piano riguarda l'intensità: si suona a volume basso."
    },
    {
      "id": "musica-dinamica-il-segno-forte-f-chiede-di-suonare",
      "subject": "musica",
      "topic": "dinamica",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Il segno «forte» (f) chiede di suonare...",
      "options": [
        "a volume basso",
        "a volume alto",
        "molto lento",
        "molto veloce"
      ],
      "answer": "a volume alto",
      "explanation": "Forte riguarda l'intensità: si suona a volume alto."
    },
    {
      "id": "musica-lettura-in-un-tempo-di-3-4-quante-semiminime-stanno-in-u",
      "subject": "musica",
      "topic": "lettura",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "In un tempo di 3/4, quante semiminime stanno in una battuta?",
      "options": [
        "Quattro",
        "Due",
        "Tre",
        "Sei"
      ],
      "answer": "Tre",
      "explanation": "Il 3/4 indica tre movimenti da un quarto: tre semiminime per battuta."
    },
    {
      "id": "musica-lettura-il-punto-dopo-una-nota-ne-aumenta-la-durata-di",
      "subject": "musica",
      "topic": "lettura",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Il punto dopo una nota ne aumenta la durata di...",
      "options": [
        "un quarto del valore",
        "il doppio del valore",
        "un ottavo del valore",
        "metà del suo valore"
      ],
      "answer": "metà del suo valore",
      "explanation": "Una minima puntata dura due battiti più uno: tre in tutto."
    },
    {
      "id": "musica-lettura-la-chiave-di-violino-fissa-il-sol-sulla",
      "subject": "musica",
      "topic": "lettura",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "La chiave di violino fissa il SOL sulla...",
      "options": [
        "seconda riga",
        "prima riga",
        "terza riga",
        "quarta riga"
      ],
      "answer": "seconda riga",
      "explanation": "La chiave di violino avvolge la seconda riga, che diventa il sol."
    },
    {
      "id": "musica-intervalli-l-intervallo-fra-do-e-sol-contando-le-note-compr",
      "subject": "musica",
      "topic": "intervalli",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "L'intervallo fra DO e SOL, contando le note comprese, è una...",
      "options": [
        "quarta",
        "quinta",
        "sesta",
        "terza"
      ],
      "answer": "quinta",
      "explanation": "Do-re-mi-fa-sol: cinque note contate, quindi una quinta."
    },
    {
      "id": "musica-intervalli-l-intervallo-fra-do-e-fa-contando-le-note-compre",
      "subject": "musica",
      "topic": "intervalli",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "L'intervallo fra DO e FA, contando le note comprese, è una...",
      "options": [
        "quinta",
        "terza",
        "quarta",
        "sesta"
      ],
      "answer": "quarta",
      "explanation": "Do-re-mi-fa: quattro note contate, quindi una quarta."
    },
    {
      "id": "musica-intervalli-due-note-con-lo-stesso-nome-ma-a-distanza-di-ott",
      "subject": "musica",
      "topic": "intervalli",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Due note con lo stesso nome ma a distanza di otto gradi formano un'...",
      "options": [
        "unisono",
        "settima",
        "sesta",
        "ottava"
      ],
      "answer": "ottava",
      "explanation": "Otto gradi separano le due note: è l'intervallo di ottava."
    },
    {
      "id": "musica-ritmo-in-4-4-una-minima-e-due-semiminime-riempiono",
      "subject": "musica",
      "topic": "ritmo",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "In 4/4, una minima e due semiminime riempiono...",
      "options": [
        "una battuta intera",
        "mezza battuta",
        "due battute",
        "un quarto di battuta"
      ],
      "answer": "una battuta intera",
      "explanation": "Due più uno più uno fa quattro quarti: la battuta è piena."
    },
    {
      "id": "musica-timbro-che-cosa-distingue-il-timbro-di-due-strumenti-ch",
      "subject": "musica",
      "topic": "timbro",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa distingue il timbro di due strumenti che suonano la stessa nota?",
      "options": [
        "L'altezza del suono",
        "Il colore del suono",
        "La durata del suono",
        "Il volume del suono"
      ],
      "answer": "Il colore del suono",
      "explanation": "Il timbro è ciò che fa riconoscere il violino dal flauto."
    },
    {
      "id": "musica-dinamica-il-segno-crescendo-chiede-di",
      "subject": "musica",
      "topic": "dinamica",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Il segno «crescendo» chiede di...",
      "options": [
        "diminuire di colpo",
        "accelerare il tempo",
        "aumentare gradualmente",
        "rallentare il tempo"
      ],
      "answer": "aumentare gradualmente",
      "explanation": "Crescendo riguarda l'intensità, che sale poco a poco."
    },
    {
      "id": "musica-note-un-alterazione-diesis-davanti-a-una-nota-la-fa-s",
      "subject": "musica",
      "topic": "note",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Un'alterazione «diesis» davanti a una nota la fa salire di...",
      "options": [
        "un tono intero",
        "una terza",
        "un'ottava",
        "un semitono"
      ],
      "answer": "un semitono",
      "explanation": "Il diesis alza la nota del più piccolo passo: un semitono."
    }
  ],
  "scienze-base": [
    {
      "id": "scienze-metodo-qual-e-il-primo-passo-del-metodo-scientifico",
      "subject": "scienze",
      "topic": "metodo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Qual è il primo passo del metodo scientifico?",
      "options": [
        "Farsi una domanda",
        "Scrivere la conclusione",
        "Ripetere l'esperimento",
        "Pubblicare i risultati"
      ],
      "answer": "Farsi una domanda",
      "explanation": "Tutto comincia da una domanda su qualcosa che si è osservato."
    },
    {
      "id": "scienze-viventi-che-cosa-hanno-in-comune-tutti-gli-esseri-vivent",
      "subject": "scienze",
      "topic": "viventi",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa hanno in comune tutti gli esseri viventi?",
      "options": [
        "Hanno quattro zampe",
        "Nascono e crescono",
        "Vivono nell'acqua",
        "Sono di colore verde"
      ],
      "answer": "Nascono e crescono",
      "explanation": "Nascere, crescere, riprodursi e morire vale per ogni vivente."
    },
    {
      "id": "scienze-viventi-un-animale-che-mangia-solo-piante-si-dice",
      "subject": "scienze",
      "topic": "viventi",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Un animale che mangia solo piante si dice...",
      "options": [
        "carnivoro",
        "onnivoro",
        "erbivoro",
        "decompositore"
      ],
      "answer": "erbivoro",
      "explanation": "Erbivoro significa proprio che si nutre di erbe e vegetali."
    },
    {
      "id": "scienze-corpo-quale-organo-pompa-il-sangue-nel-corpo",
      "subject": "scienze",
      "topic": "corpo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quale organo pompa il sangue nel corpo?",
      "options": [
        "I polmoni",
        "Lo stomaco",
        "Il fegato",
        "Il cuore"
      ],
      "answer": "Il cuore",
      "explanation": "Il cuore è un muscolo che spinge il sangue in tutto il corpo."
    },
    {
      "id": "scienze-corpo-con-quale-organo-respiriamo",
      "subject": "scienze",
      "topic": "corpo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Con quale organo respiriamo?",
      "options": [
        "I polmoni",
        "Il cuore",
        "Lo stomaco",
        "I reni"
      ],
      "answer": "I polmoni",
      "explanation": "Nei polmoni l'aria cede ossigeno al sangue."
    },
    {
      "id": "scienze-terra-universo-perche-sulla-terra-si-alternano-le-stagioni",
      "subject": "scienze",
      "topic": "terra-universo",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Perché sulla Terra si alternano le stagioni?",
      "options": [
        "La Terra rallenta d'inverno",
        "L'asse terrestre è inclinato",
        "Il Sole cambia temperatura",
        "La Luna copre il Sole"
      ],
      "answer": "L'asse terrestre è inclinato",
      "explanation": "L'inclinazione fa arrivare i raggi più obliqui in una metà dell'anno."
    },
    {
      "id": "scienze-terra-universo-quanto-impiega-la-terra-a-compiere-un-giro-su-se",
      "subject": "scienze",
      "topic": "terra-universo",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Quanto impiega la Terra a compiere un giro su sé stessa?",
      "options": [
        "Circa 365 giorni",
        "Circa 28 giorni",
        "Circa 24 ore",
        "Circa 12 ore"
      ],
      "answer": "Circa 24 ore",
      "explanation": "La rotazione dura un giorno e produce il dì e la notte."
    },
    {
      "id": "scienze-materia-come-si-chiama-il-passaggio-da-gas-a-liquido",
      "subject": "scienze",
      "topic": "materia",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Come si chiama il passaggio da gas a liquido?",
      "options": [
        "Evaporazione",
        "Fusione",
        "Solidificazione",
        "Condensazione"
      ],
      "answer": "Condensazione",
      "explanation": "Il vapore che si raffredda torna liquido: è la condensazione."
    },
    {
      "id": "scienze-ecosistema-in-una-catena-alimentare-i-funghi-svolgono-il-ru",
      "subject": "scienze",
      "topic": "ecosistema",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "In una catena alimentare i funghi svolgono il ruolo di...",
      "options": [
        "decompositori",
        "produttori",
        "consumatori",
        "predatori"
      ],
      "answer": "decompositori",
      "explanation": "I funghi smontano i resti e restituiscono sostanze al terreno."
    },
    {
      "id": "scienze-energia-una-palla-ferma-in-cima-a-una-rampa-possiede-ene",
      "subject": "scienze",
      "topic": "energia",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Una palla ferma in cima a una rampa possiede energia...",
      "options": [
        "cinetica",
        "potenziale",
        "luminosa",
        "sonora"
      ],
      "answer": "potenziale",
      "explanation": "L'energia è immagazzinata nella posizione: è potenziale."
    }
  ],
  "storia-base": [
    {
      "id": "storia-metodo-che-cosa-studia-la-storia",
      "subject": "storia",
      "topic": "metodo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa studia la storia?",
      "options": [
        "I fatti del passato",
        "Le forme dei terreni",
        "I numeri e le figure",
        "Le lingue straniere"
      ],
      "answer": "I fatti del passato",
      "explanation": "La storia ricostruisce che cosa è successo prima di noi."
    },
    {
      "id": "storia-metodo-come-si-chiama-chi-studia-i-resti-sepolti-nel-te",
      "subject": "storia",
      "topic": "metodo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Come si chiama chi studia i resti sepolti nel terreno?",
      "options": [
        "Geologo",
        "Archeologo",
        "Astronomo",
        "Biologo"
      ],
      "answer": "Archeologo",
      "explanation": "L'archeologo scava e studia gli oggetti lasciati dagli antichi."
    },
    {
      "id": "storia-metodo-un-vaso-antico-ritrovato-in-uno-scavo-e-una-font",
      "subject": "storia",
      "topic": "metodo",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Un vaso antico ritrovato in uno scavo è una fonte...",
      "options": [
        "orale",
        "scritta",
        "materiale",
        "immaginaria"
      ],
      "answer": "materiale",
      "explanation": "Si tocca e si osserva: è una fonte materiale."
    },
    {
      "id": "storia-cronologia-quanti-anni-ci-sono-in-un-secolo",
      "subject": "storia",
      "topic": "cronologia",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quanti anni ci sono in un secolo?",
      "options": [
        "Dieci",
        "Mille",
        "Cinquanta",
        "Cento"
      ],
      "answer": "Cento",
      "explanation": "Secolo viene dal latino e indica cento anni."
    },
    {
      "id": "storia-cronologia-quanti-anni-ci-sono-in-un-millennio",
      "subject": "storia",
      "topic": "cronologia",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Quanti anni ci sono in un millennio?",
      "options": [
        "Mille",
        "Cento",
        "Diecimila",
        "Cinquecento"
      ],
      "answer": "Mille",
      "explanation": "Millennio indica mille anni, dieci secoli."
    },
    {
      "id": "storia-cronologia-gli-eventi-a-c-sono-avvenuti",
      "subject": "storia",
      "topic": "cronologia",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Gli eventi «a.C.» sono avvenuti...",
      "options": [
        "dopo di Cristo",
        "prima di Cristo",
        "nel Medioevo",
        "in epoca moderna"
      ],
      "answer": "prima di Cristo",
      "explanation": "La sigla a.C. significa avanti Cristo: prima dell'anno zero."
    },
    {
      "id": "storia-preistoria-nella-preistoria-gli-uomini-non-conoscevano-anco",
      "subject": "storia",
      "topic": "preistoria",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Nella preistoria gli uomini non conoscevano ancora...",
      "options": [
        "il fuoco",
        "la caccia",
        "la scrittura",
        "la pietra"
      ],
      "answer": "la scrittura",
      "explanation": "La preistoria è il tempo prima che la scrittura fosse inventata."
    },
    {
      "id": "storia-preistoria-che-cosa-usavano-gli-uomini-del-paleolitico-per-",
      "subject": "storia",
      "topic": "preistoria",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Che cosa usavano gli uomini del Paleolitico per gli attrezzi?",
      "options": [
        "Il ferro fuso",
        "La plastica",
        "Il vetro soffiato",
        "La pietra scheggiata"
      ],
      "answer": "La pietra scheggiata",
      "explanation": "Paleolitico significa età della pietra antica: si scheggiava la selce."
    },
    {
      "id": "storia-roma-in-quale-citta-nacque-la-civilta-romana",
      "subject": "storia",
      "topic": "roma",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "In quale città nacque la civiltà romana?",
      "options": [
        "Roma",
        "Atene",
        "Il Cairo",
        "Babilonia"
      ],
      "answer": "Roma",
      "explanation": "I Romani presero il nome dalla città che fondarono: Roma."
    },
    {
      "id": "storia-egizi-lungo-quale-fiume-viveva-la-civilta-egizia",
      "subject": "storia",
      "topic": "egizi",
      "difficulty": 1,
      "format": "multiple_choice",
      "prompt": "Lungo quale fiume viveva la civiltà egizia?",
      "options": [
        "Il Tevere",
        "Il Nilo",
        "Il Danubio",
        "Il Gange"
      ],
      "answer": "Il Nilo",
      "explanation": "Le piene del Nilo rendevano fertile la terra degli Egizi."
    },
    {
      "id": "storia-roma-quale-forma-di-governo-ebbe-roma-fra-la-monarchi",
      "subject": "storia",
      "topic": "roma",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Quale forma di governo ebbe Roma fra la monarchia e l'impero?",
      "options": [
        "La tirannide",
        "La democrazia diretta",
        "La repubblica",
        "L'oligarchia militare"
      ],
      "answer": "La repubblica",
      "explanation": "Cacciati i re, Roma fu una repubblica retta da magistrati eletti."
    },
    {
      "id": "storia-roma-chi-fu-il-primo-imperatore-di-roma",
      "subject": "storia",
      "topic": "roma",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Chi fu il primo imperatore di Roma?",
      "options": [
        "Giulio Cesare",
        "Nerone",
        "Traiano",
        "Augusto"
      ],
      "answer": "Augusto",
      "explanation": "Ottaviano prese il titolo di Augusto e inaugurò l'impero."
    },
    {
      "id": "storia-grecia-in-quale-citta-greca-nacque-la-democrazia",
      "subject": "storia",
      "topic": "grecia",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "In quale città greca nacque la democrazia?",
      "options": [
        "Atene",
        "Sparta",
        "Corinto",
        "Tebe"
      ],
      "answer": "Atene",
      "explanation": "Ad Atene i cittadini decidevano insieme nell'assemblea."
    },
    {
      "id": "storia-grecia-che-cosa-era-la-polis-nel-mondo-greco",
      "subject": "storia",
      "topic": "grecia",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa era la polis nel mondo greco?",
      "options": [
        "Un tempio sacro",
        "Una città-stato",
        "Una nave da guerra",
        "Una moneta d'oro"
      ],
      "answer": "Una città-stato",
      "explanation": "Ogni polis aveva leggi, esercito e divinità proprie."
    },
    {
      "id": "storia-medioevo-nel-sistema-feudale-il-signore-concedeva-al-vass",
      "subject": "storia",
      "topic": "medioevo",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Nel sistema feudale il signore concedeva al vassallo...",
      "options": [
        "una nave da comandare",
        "una moneta da coniare",
        "una terra da amministrare",
        "una legge da scrivere"
      ],
      "answer": "una terra da amministrare",
      "explanation": "Il feudo era la terra data in cambio di fedeltà e servizio armato."
    },
    {
      "id": "storia-medioevo-chi-fu-incoronato-imperatore-la-notte-di-natale-",
      "subject": "storia",
      "topic": "medioevo",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Chi fu incoronato imperatore la notte di Natale dell'800?",
      "options": [
        "Federico Barbarossa",
        "Ottone I",
        "Giustiniano",
        "Carlo Magno"
      ],
      "answer": "Carlo Magno",
      "explanation": "Papa Leone III incoronò Carlo Magno imperatore dei Romani."
    },
    {
      "id": "storia-cronologia-quale-evento-segna-convenzionalmente-la-fine-del",
      "subject": "storia",
      "topic": "cronologia",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Quale evento segna convenzionalmente la fine del Medioevo?",
      "options": [
        "La scoperta dell'America",
        "La caduta di Roma",
        "La prima crociata",
        "La peste nera"
      ],
      "answer": "La scoperta dell'America",
      "explanation": "Il 1492 chiude il Medioevo e apre l'età moderna."
    },
    {
      "id": "storia-cronologia-quale-evento-segna-convenzionalmente-l-inizio-de",
      "subject": "storia",
      "topic": "cronologia",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Quale evento segna convenzionalmente l'inizio del Medioevo?",
      "options": [
        "La nascita di Cristo",
        "La caduta di Roma d'Occidente",
        "La fondazione di Roma",
        "La scoperta dell'America"
      ],
      "answer": "La caduta di Roma d'Occidente",
      "explanation": "Il 476 d.C. chiude l'antichità e apre il Medioevo."
    },
    {
      "id": "storia-egizi-a-che-cosa-serviva-la-mummificazione-presso-gli-",
      "subject": "storia",
      "topic": "egizi",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "A che cosa serviva la mummificazione presso gli Egizi?",
      "options": [
        "A curare le malattie dei vivi",
        "A misurare il tempo dell'anno",
        "A conservare il corpo per l'aldilà",
        "A segnare i confini dei campi"
      ],
      "answer": "A conservare il corpo per l'aldilà",
      "explanation": "Gli Egizi credevano che il defunto avesse bisogno del proprio corpo."
    },
    {
      "id": "storia-preistoria-che-cosa-cambio-nel-neolitico-rispetto-al-paleol",
      "subject": "storia",
      "topic": "preistoria",
      "difficulty": 4,
      "format": "multiple_choice",
      "prompt": "Che cosa cambiò nel Neolitico rispetto al Paleolitico?",
      "options": [
        "Si spense l'uso del fuoco",
        "Sparirono gli utensili di pietra",
        "Comparve la scrittura alfabetica",
        "Nacquero agricoltura e allevamento"
      ],
      "answer": "Nacquero agricoltura e allevamento",
      "explanation": "Dal Neolitico l'uomo coltiva e alleva, e smette di spostarsi sempre."
    }
  ]
};

for (const [name, extra] of Object.entries(CURATED_TAIL)) {
  BANKS[name].items.push(...extra);
}

// ---------------------------------------------------------------------------
// Banda 4 — gli ultimi sei mondi
// ---------------------------------------------------------------------------
//
// `target_difficulty` manda i mondi 19-24 tutti a difficoltà 4, quindi la banda
// alta copre un quarto della campagna. Il 3 agosto 2026 era la più magra di
// tutte: storia aveva 11 item spalmati su sei argomenti — ogni secchio sotto i
// tre — e soprattutto ITALIANO ne aveva 18 ma su due soli argomenti, inglese 31
// su tre. Negli ultimi mondi la scelta multipla girava sempre intorno alle
// stesse cose.
//
// Qui si allarga il ventaglio degli argomenti, non solo il conteggio: è la
// differenza fra avere più esercizi e avere più materia. Ogni voce dichiara la
// propria difficoltà, perché serve anche alla banda 2 di musica, ferma a sette.
const BAND_EXTRA = {
  "elettronica": [
    { difficulty: 4, topic: "elettricita-base", prompt: "A parità di resistenza, se raddoppi la tensione la corrente che passa…", answer: "raddoppia",
      distractors: ["resta uguale", "si dimezza", "si annulla"],
      explanation: "Corrente = tensione diviso resistenza. Se la resistenza non cambia e la tensione raddoppia, anche la corrente raddoppia." },
    { difficulty: 4, topic: "elettricita-base", prompt: "A parità di tensione, se la resistenza diventa il triplo la corrente…", answer: "si riduce a un terzo",
      distractors: ["diventa il triplo", "resta la stessa", "si riduce a metà"],
      explanation: "Corrente = tensione diviso resistenza: se il divisore triplica, il risultato vale un terzo." },
    { difficulty: 4, topic: "circuito", prompt: "Due lampadine uguali sono in serie e una si fulmina. L'altra che cosa fa?", answer: "si spegne anche lei",
      distractors: ["resta accesa uguale", "diventa più luminosa", "si accende a intermittenza"],
      explanation: "In serie la corrente ha una strada sola: se si interrompe in un punto, non passa più da nessuna parte." },
    { difficulty: 4, topic: "circuito", prompt: "Colleghi i due poli di una pila con un filo e basta, senza lampadina. Che cosa succede?", answer: "passa moltissima corrente e la pila si scalda",
      distractors: ["non passa nessuna corrente perché manca la lampadina", "la pila si ricarica invertendo il verso della corrente", "il filo si comporta da isolante e blocca tutto"],
      explanation: "È un cortocircuito: senza nulla che limiti la corrente, ne passa tantissima e l'energia si trasforma in calore. Per questo non si fa." },
    { difficulty: 4, topic: "serie-parallelo", prompt: "Due lampadine uguali in parallelo su una pila, invece di una sola: la corrente che esce dalla pila…", answer: "raddoppia",
      distractors: ["si dimezza", "resta uguale", "si annulla"],
      explanation: "In parallelo ogni lampadina ha la sua strada e prende la stessa corrente di prima: la pila ne deve fornire il doppio." },
    { difficulty: 4, topic: "serie-parallelo", prompt: "Perché nelle case gli apparecchi sono collegati in parallelo e non in serie?", answer: "così ognuno funziona da solo e si può spegnere senza fermare gli altri",
      distractors: ["perché collegati in serie consumerebbero molta più corrente", "perché il parallelo richiede molti meno fili dentro i muri", "perché in serie i fili si scalderebbero fino a bruciarsi"],
      explanation: "In parallelo ogni apparecchio ha la sua strada: spegnerne uno non interrompe gli altri. In serie basterebbe una lampadina fulminata per lasciare al buio la casa." },
    { difficulty: 4, topic: "conduttori", prompt: "Un filo di rame lungo il doppio, con lo stesso spessore, ha una resistenza…", answer: "doppia",
      distractors: ["uguale", "la metà", "quattro volte più grande"],
      explanation: "Più strada deve fare la corrente dentro il filo, più incontra ostacoli: la resistenza cresce insieme alla lunghezza." },
    { difficulty: 4, topic: "conduttori", prompt: "Perché l'acqua salata conduce la corrente e quella distillata quasi per niente?", answer: "perché nell'acqua salata ci sono particelle cariche libere di muoversi",
      distractors: ["perché l'acqua salata è più densa e pesante di quella distillata", "perché il sale è un metallo e i metalli conducono la corrente", "perché l'acqua distillata è troppo pura per lasciar passare qualcosa"],
      explanation: "Il sale sciolto libera particelle con carica elettrica che possono spostarsi: sono loro a trasportare la corrente. Nell'acqua distillata non ce ne sono quasi." },
    { difficulty: 4, topic: "misure-elettriche", prompt: "Per misurare la corrente che attraversa una lampadina, come si collega l'amperometro?", answer: "in serie, nel filo che porta alla lampadina",
      distractors: ["in parallelo alla lampadina", "ai due poli della pila", "fra la lampadina e l'interruttore aperto"],
      explanation: "L'amperometro deve essere attraversato dalla stessa corrente che vuoi misurare, quindi va messo lungo la strada. Il voltmetro invece si mette in parallelo." },
    { difficulty: 4, topic: "misure-elettriche", prompt: "Per misurare la tensione ai capi di una lampadina, come si collega il voltmetro?", answer: "in parallelo, uno ai capi dell'altra",
      distractors: ["in serie con la lampadina", "al posto della lampadina", "solo al polo positivo della pila"],
      explanation: "La tensione è una differenza fra due punti: per misurarla bisogna toccarli tutti e due. Per questo il voltmetro si mette in parallelo." },
    { difficulty: 4, topic: "sicurezza-elettrica", prompt: "Perché il salvavita scatta anche quando la corrente che passa è piccola?", answer: "perché confronta la corrente che entra con quella che esce, e le vuole uguali",
      distractors: ["perché misura quanta corrente sta consumando la casa in quel momento", "perché controlla che la tensione non salga sopra il valore di sicurezza", "perché conta quanti apparecchi sono accesi insieme sulla stessa presa"],
      explanation: "Se la corrente che torna è meno di quella andata, una parte sta passando da un'altra strada — magari attraverso una persona. Basta pochissimo per far scattare la protezione." },
    { difficulty: 4, topic: "componenti", prompt: "A che cosa serve la resistenza che si mette in serie a un LED?", answer: "a limitare la corrente, così il LED non si brucia",
      distractors: ["ad aumentare la luce che il LED riesce a produrre", "a cambiare il colore con cui il LED si accende", "a far durare di più la pila che alimenta il circuito"],
      explanation: "Un LED da solo lascerebbe passare troppa corrente e si rovinerebbe subito. La resistenza fa da freno." },
    { difficulty: 4, topic: "guasti", prompt: "In una ghirlanda di luci collegate in parallelo una lampadina si fulmina. Le altre?", answer: "restano accese",
      distractors: ["si spengono tutte", "diventano più deboli", "si accendono a intermittenza"],
      explanation: "In parallelo ogni lampadina ha la sua strada verso la pila: se una si interrompe, le altre continuano ad avere la loro." },
  ],
  "fisica": [
    { difficulty: 4, topic: "misure", prompt: "Misuri lo stesso oggetto cinque volte e trovi valori un po' diversi. Qual è la cosa più corretta da fare?", answer: "calcolare la media delle cinque misure",
      distractors: ["tenere la misura più grande", "tenere la prima misura", "tenere quella che ti aspettavi"],
      explanation: "Ogni misura porta un piccolo errore casuale, in più o in meno. La media li compensa e si avvicina al valore vero." },
    { difficulty: 4, topic: "misure", prompt: "Un righello ha le tacche ogni millimetro. Come ha senso scrivere una lunghezza misurata con quel righello?", answer: "al millimetro, per esempio 12,4 cm",
      distractors: ["al centesimo di millimetro", "sempre in numeri interi di centimetri", "con tutte le cifre che dà la calcolatrice"],
      explanation: "Uno strumento non può dire più di quanto è fine: scrivere cifre in più non aggiunge precisione, la finge." },
    { difficulty: 4, topic: "metodo", prompt: "Vuoi scoprire se una pianta cresce di più con più luce. Fra i due vasi che cosa cambi?", answer: "solo la luce, tenendo uguale tutto il resto",
      distractors: ["luce, acqua e terra insieme", "la specie della pianta", "il momento in cui li osservi"],
      explanation: "Se cambi più cose insieme e qualcosa succede, non sai quale l'ha causato. Una variabile per volta." },
    { difficulty: 4, topic: "metodo", prompt: "L'esperimento dà un risultato che non conferma la tua ipotesi. Che cosa fai?", answer: "annoti il risultato e cambi l'ipotesi",
      distractors: ["ripeti finché non viene quello che pensavi", "butti via la misura sbagliata", "cambi la domanda di partenza"],
      explanation: "Un risultato che smentisce è un risultato utile: dice qualcosa di vero sul mondo. Tenere solo le prove che ti danno ragione non è più un esperimento." },
    { difficulty: 4, topic: "moto", prompt: "Un'auto percorre 90 km in un'ora e mezza. Qual è la sua velocità media?", answer: "60 km/h",
      distractors: ["90 km/h", "45 km/h", "135 km/h"],
      explanation: "Velocità media = spazio diviso tempo: 90 km diviso 1,5 ore fa 60 km/h." },
    { difficulty: 4, topic: "moto", prompt: "Sei seduto su un treno che viaggia liscio a velocità costante. Rispetto al vagone, tu…", answer: "sei fermo",
      distractors: ["ti muovi a 100 km/h", "ti muovi all'indietro", "acceleri di continuo"],
      explanation: "Il movimento è sempre rispetto a qualcosa: rispetto al vagone non ti sposti, rispetto ai binari corri con il treno." },
    { difficulty: 4, topic: "forze", prompt: "Su un'asse con il fulcro al centro devi sollevare un peso. Se ti allontani al doppio della distanza dal fulcro, la forza che ti serve…", answer: "si dimezza",
      distractors: ["raddoppia", "resta la stessa", "diventa quattro volte più grande"],
      explanation: "Su una leva conta forza per distanza dal fulcro: raddoppiando la distanza basta metà forza per fare lo stesso effetto." },
    { difficulty: 4, topic: "energia", prompt: "Una palla cade da un tavolo. Mentre scende, l'energia che aveva per la sua altezza…", answer: "diventa energia di movimento",
      distractors: ["sparisce", "si trasforma tutta in calore", "aumenta insieme all'altezza"],
      explanation: "L'energia non sparisce, cambia forma: quella dovuta all'altezza diventa energia di movimento, e la palla arriva in basso veloce." },
    { difficulty: 4, topic: "calore", prompt: "Perché il manico di metallo di una pentola scotta e quello di legno no?", answer: "perché il metallo conduce bene il calore e il legno male",
      distractors: ["perché il metallo è più pesante", "perché il legno è più freddo di partenza", "perché il metallo è più vicino al fuoco"],
      explanation: "Il calore si sposta facilmente dentro i metalli e fatica ad attraversare il legno: per questo i manici si fanno di legno o di plastica." },
    { difficulty: 4, topic: "onde-luce", prompt: "Durante un temporale vedi il lampo e solo dopo senti il tuono. Perché?", answer: "perché la luce viaggia molto più veloce del suono",
      distractors: ["perché il lampo avviene prima del tuono", "perché il suono parte da più lontano", "perché l'aria ferma il suono e non la luce"],
      explanation: "Lampo e tuono nascono insieme, ma la luce arriva quasi subito mentre il suono impiega circa tre secondi per ogni chilometro." },
    { difficulty: 4, topic: "materia", prompt: "Perché un cubetto di ghiaccio galleggia nell'acqua?", answer: "perché il ghiaccio è meno denso dell'acqua liquida",
      distractors: ["perché il ghiaccio è più leggero di qualsiasi cosa", "perché è più freddo dell'acqua", "perché contiene aria al suo interno"],
      explanation: "Congelandosi l'acqua occupa più spazio a parità di materia: il ghiaccio pesa meno dell'acqua che sposta, e galleggia. È un caso raro in natura." },
  ],
  "storia": [
    { difficulty: 4, topic: "cronologia", prompt: "A quale secolo appartiene l'anno 1215?", answer: "XIII secolo",
      distractors: ["XII secolo", "XIV secolo", "XI secolo"],
      explanation: "Gli anni dal 1201 al 1300 formano il XIII secolo: si prendono le centinaia e si aggiunge uno." },
    { difficulty: 4, topic: "metodo", prompt: "Due fonti raccontano lo stesso fatto in modo diverso. Che cosa fa uno storico?", answer: "Le confronta e ne cerca altre",
      distractors: ["Sceglie la più antica e basta", "Sceglie la più lunga", "Le scarta tutte e due"],
      explanation: "Il confronto fra fonti è il mestiere dello storico: una fonte sola non basta mai." },
    { difficulty: 4, topic: "metodo", prompt: "Che cosa vuol dire che una fonte è «di parte»?", answer: "Racconta i fatti dal punto di vista di chi la scrive",
      distractors: ["Contiene almeno un errore di data o di nome", "È stata scritta molti secoli dopo i fatti", "Racconta soltanto le battaglie e le guerre"],
      explanation: "Una fonte di parte non è per forza falsa: va letta sapendo chi l'ha scritta e perché." },
    { difficulty: 4, topic: "fonti", prompt: "Perché un'iscrizione su pietra arriva fino a noi più spesso di un papiro?", answer: "La pietra resiste all'acqua, al fuoco e al tempo",
      distractors: ["Sulla pietra si scriveva con più attenzione", "I papiri venivano distrutti apposta dai nemici", "Le iscrizioni venivano copiate in molte copie"],
      explanation: "Il materiale decide che cosa sopravvive: per questo conosciamo meglio i popoli che scrivevano sulla pietra." },
    { difficulty: 4, topic: "roma", prompt: "In che anno cadde l'Impero Romano d'Occidente?", answer: "476 d.C.",
      distractors: ["753 a.C.", "800 d.C.", "1492"],
      explanation: "Il 476 d.C. chiude l'età antica e apre il Medioevo." },
    { difficulty: 4, topic: "grecia", prompt: "Che cos'era la polis greca?", answer: "Una città-stato indipendente",
      distractors: ["Una grande piazza del mercato", "Un tempio dedicato a Zeus", "Una nave da guerra"],
      explanation: "Ogni polis aveva leggi e governo propri: Atene e Sparta erano due polis molto diverse fra loro." },
    { difficulty: 4, topic: "grecia", prompt: "Che cosa distingueva Sparta da Atene?", answer: "Sparta puntava tutto sull'esercito, Atene sul commercio e sulla politica",
      distractors: ["Sparta viveva di commercio marittimo, Atene di agricoltura", "Sparta era governata dal popolo intero, Atene da un solo re", "Sparta sorgeva sul mare, Atene in mezzo alle montagne dell'interno"],
      explanation: "Due modi opposti di stare al mondo: a Sparta si cresceva per combattere, ad Atene per discutere in assemblea." },
    { difficulty: 4, topic: "medioevo", prompt: "Che cos'era il feudo?", answer: "Una terra concessa da un signore in cambio di fedeltà",
      distractors: ["Una tassa che i contadini pagavano sul sale", "Un castello costruito in cima a una collina", "Una moneta d'oro coniata dall'imperatore stesso"],
      explanation: "Il sistema feudale legava terra e fedeltà: chi riceveva il feudo doveva servizio militare al signore." },
    { difficulty: 4, topic: "medioevo", prompt: "Che cosa furono i Comuni in Italia?", answer: "Città che si diedero un governo proprio",
      distractors: ["Eserciti di soldati pagati dai signori", "Monasteri costruiti fuori dalle mura", "Porti concessi in uso dall'imperatore"],
      explanation: "Fra XI e XII secolo molte città italiane si organizzarono da sole, staccandosi dai signori feudali." },
    { difficulty: 4, topic: "egizi", prompt: "A che cosa serviva la mummificazione per gli Egizi?", answer: "A conservare il corpo per la vita dopo la morte",
      distractors: ["A curare le malattie con le erbe del Nilo", "A trasportare i corpi fino alle piramidi", "A misurare il tempo con le stagioni del Nilo"],
      explanation: "Gli Egizi credevano che l'anima avesse bisogno del corpo anche dopo la morte." },
    { difficulty: 4, topic: "preistoria", prompt: "Che cosa cambia con la nascita dell'agricoltura nel Neolitico?", answer: "Gli uomini smettono di spostarsi e nascono i villaggi",
      distractors: ["Si impara a fondere il ferro e a forgiare le armi", "Nascono i primi imperi con un re e un esercito", "Gli uomini imparano ad accendere il fuoco"],
      explanation: "Coltivare obbliga a restare: da nomadi si diventa stanziali, ed è da lì che nascono i villaggi." },
    { difficulty: 4, topic: "civilta", prompt: "Perché le prime civiltà nacquero lungo i grandi fiumi?", answer: "L'acqua permetteva di coltivare e di spostarsi",
      distractors: ["I fiumi erano più facili da difendere", "Vicino ai fiumi non pioveva mai", "I fiumi segnavano i confini"],
      explanation: "Nilo, Tigri, Eufrate e Indo davano acqua per i campi e una strada per i commerci." },
  ],
  "musica": [
    { difficulty: 4, topic: "intervalli", prompt: "Quanti semitoni ci sono in una quinta giusta?", answer: "7",
      distractors: ["5", "6", "8"],
      explanation: "Do–Sol è una quinta giusta: contando i semitoni sono sette." },
    { difficulty: 4, topic: "intervalli", prompt: "Come si chiama l'intervallo di sei semitoni?", answer: "Tritono",
      distractors: ["Quarta giusta", "Quinta giusta", "Sesta minore"],
      explanation: "Sei semitoni stanno esattamente fra la quarta giusta (5) e la quinta giusta (7): è il tritono." },
    { difficulty: 4, topic: "note", prompt: "Quanti semitoni ci sono in un'ottava?", answer: "12",
      distractors: ["7", "8", "10"],
      explanation: "Sette note ma dodici semitoni: fra Mi–Fa e fra Si–Do c'è un semitono e non un tono." },
    { difficulty: 4, topic: "lettura", prompt: "Che cosa indica il diesis davanti a una nota?", answer: "La alza di un semitono",
      distractors: ["La abbassa di un semitono", "La allunga del doppio", "La rende più forte"],
      explanation: "Il diesis alza di un semitono, il bemolle abbassa di un semitono." },
    { difficulty: 4, topic: "lettura", prompt: "In chiave di violino, quale nota sta sulla prima riga in basso?", answer: "Mi",
      distractors: ["Do", "Sol", "Fa"],
      explanation: "Le note sulle righe, dal basso: Mi, Sol, Si, Re, Fa." },
    { difficulty: 4, topic: "ritmo", prompt: "In 3/4, quante semiminime stanno in una battuta?", answer: "3",
      distractors: ["4", "2", "6"],
      explanation: "Il numero di sopra dice quante unità, quello di sotto quale figura: 3/4 vuol dire tre quarti per battuta." },
    { difficulty: 4, topic: "ritmo", prompt: "In 4/4, quanti battiti vale una minima puntata?", answer: "3",
      distractors: ["2", "4", "1"],
      explanation: "Il punto aggiunge la metà del valore: la minima vale 2 battiti, più 1 fa 3." },
    { difficulty: 4, topic: "dinamica", prompt: "Che cosa indica il segno «crescendo»?", answer: "Il volume aumenta poco a poco",
      distractors: ["Il tempo accelera", "Le note salgono di altezza", "La frase si ripete"],
      explanation: "Il crescendo riguarda il volume, non l'altezza delle note né la velocità." },
    { difficulty: 4, topic: "tempo", prompt: "Che cosa misura il metronomo?", answer: "Quanti battiti al minuto",
      distractors: ["Quanto è forte il suono", "Quanto è acuta la nota", "Quante note ci sono"],
      explanation: "60 BPM vuol dire un battito al secondo: il metronomo misura la velocità, non il volume." },
    { difficulty: 4, topic: "timbro", prompt: "Perché un violino e un flauto che suonano la stessa nota si riconoscono lo stesso?", answer: "Hanno un timbro diverso",
      distractors: ["Suonano altezze diverse", "Suonano a volumi diversi", "Suonano a velocità diverse"],
      explanation: "Il timbro è il «colore» del suono e dipende da come vibra lo strumento: l'altezza invece è la stessa." },
    { difficulty: 2, topic: "note", prompt: "Quale nota viene subito prima del Do?", answer: "Si",
      distractors: ["La", "Re", "Sol"],
      explanation: "L'ordine è La, Si, Do: dopo il Si si ricomincia da capo." },
    { difficulty: 2, topic: "strumenti", prompt: "Come si produce il suono in una chitarra?", answer: "Pizzicando le corde",
      distractors: ["Soffiando in un tubo", "Percuotendo una pelle", "Premendo un mantice"],
      explanation: "Le corde vibrano e la cassa amplifica il suono." },
    { difficulty: 2, topic: "ritmo", prompt: "Che cosa segna la stanghetta verticale sul pentagramma?", answer: "La fine di una battuta",
      distractors: ["Una pausa lunga", "Un cambio di strumento", "La fine del brano"],
      explanation: "Le stanghette dividono la musica in battute che durano tutte uguale." },
    { difficulty: 2, topic: "dinamica", prompt: "Che cosa vuol dire «forte» in musica?", answer: "Suonare a volume alto",
      distractors: ["Suonare veloce", "Suonare acuto", "Suonare a lungo"],
      explanation: "Piano e forte indicano il volume; presto e lento la velocità." },
    { difficulty: 2, topic: "lettura", prompt: "Che cos'è una pausa?", answer: "Un silenzio che dura un tempo preciso",
      distractors: ["Una nota molto lunga", "La fine del brano", "Un errore da correggere"],
      explanation: "Anche il silenzio ha una durata scritta: le pause si contano esattamente come le note." },
  ],
  "latino": [
    { difficulty: 4, topic: "verbo-sum", prompt: "Come si dice «noi siamo» in latino?", answer: "Sumus",
      distractors: ["Estis", "Sunt", "Es"],
      explanation: "sum, es, est, sumus, estis, sunt." },
    { difficulty: 4, topic: "verbo-sum", prompt: "«Estis» significa…", answer: "(voi) siete",
      distractors: ["(noi) siamo", "(loro) sono", "(tu) sei"],
      explanation: "«Estis» è la seconda persona plurale di sum." },
    { difficulty: 4, topic: "frasi", prompt: "«Magister discipulos laudat» significa…", answer: "Il maestro loda gli allievi",
      distractors: ["Gli allievi lodano il maestro", "Il maestro chiama gli allievi", "Gli allievi ascoltano il maestro"],
      explanation: "«Magister» è nominativo (soggetto), «discipulos» accusativo plurale (oggetto): a decidere chi fa l'azione è il caso, non la posizione." },
    { difficulty: 4, topic: "casi", prompt: "Perché in latino l'ordine delle parole conta meno che in italiano?", answer: "Perché il caso dice già la funzione di ogni parola",
      distractors: ["Perché il verbo sta sempre alla fine", "Perché non esistono gli articoli", "Perché le frasi sono più corte"],
      explanation: "«Rosam puella amat» e «Puella rosam amat» dicono la stessa cosa: in tutte e due -am segna l'oggetto." },
    { difficulty: 4, topic: "casi", prompt: "Quale caso useresti per dire «con la spada», cioè il mezzo?", answer: "Ablativo",
      distractors: ["Accusativo", "Dativo", "Genitivo"],
      explanation: "L'ablativo esprime mezzo, causa, modo e stato in luogo: «gladio» vuol dire con la spada." },
    { difficulty: 4, topic: "etimologia", prompt: "Da quale verbo latino vengono «scrivere», «scriba» e «manoscritto»?", answer: "scribere",
      distractors: ["legere", "dicere", "ducere"],
      explanation: "«Scribere» è scrivere: la stessa radice sta in descrizione, iscrizione e sottoscrivere." },
    { difficulty: 4, topic: "etimologia", prompt: "«Manuale», «manovra» e «manutenzione» vengono tutte da…", answer: "manus, la mano",
      distractors: ["mens, la mente", "munus, il dono", "mons, il monte"],
      explanation: "Un lavoro manuale si fa con le mani, e la manutenzione è ciò che le tiene in efficienza." },
    { difficulty: 4, topic: "declinazioni-base", prompt: "Il genitivo singolare dice a quale declinazione appartiene un nome. «Civis, civis» è di…", answer: "terza declinazione",
      distractors: ["prima declinazione", "seconda declinazione", "quarta declinazione"],
      explanation: "Genitivo in -is: terza declinazione. In -ae è la prima, in -i la seconda." },
  ],
  "logica": [
    { difficulty: 4, topic: "quantificatori", prompt: "«Non tutti i gatti sono neri» vuol dire…", answer: "Almeno un gatto non è nero",
      distractors: ["Nessun gatto è nero", "Tutti i gatti sono di un altro colore", "Esattamente metà dei gatti è nera"],
      explanation: "La negazione di «tutti» non è «nessuno»: basta un solo controesempio per smentire un «tutti»." },
    { difficulty: 4, topic: "quantificatori", prompt: "Qual è la negazione di «alcuni studenti sono in ritardo»?", answer: "Nessuno studente è in ritardo",
      distractors: ["Tutti gli studenti sono in ritardo", "Alcuni studenti non sono in ritardo", "Non tutti gli studenti sono in ritardo"],
      explanation: "«Alcuni» vuol dire almeno uno: negarlo significa dire zero, cioè nessuno." },
    { difficulty: 4, topic: "insiemi", prompt: "Ogni quadrato è un rombo e ogni rombo è un parallelogramma. Allora…", answer: "Ogni quadrato è un parallelogramma",
      distractors: ["Ogni parallelogramma è un quadrato", "Nessun rombo è un quadrato", "Rombo e quadrato sono la stessa figura"],
      explanation: "La relazione «è un» si trasmette in avanti lungo la catena, mai all'indietro." },
    { difficulty: 4, topic: "deduzioni", prompt: "«Se studio, passo l'esame.» Ho passato l'esame. Che cosa segue?", answer: "Non si può dire se ho studiato",
      distractors: ["Ho studiato di sicuro", "Non ho studiato", "L'esame era facile"],
      explanation: "Dall'effetto non si risale alla causa: l'esame potrei averlo passato anche senza studiare." },
    { difficulty: 4, topic: "deduzioni", prompt: "«Se studio, passo l'esame.» Non ho passato l'esame. Che cosa segue?", answer: "Non ho studiato",
      distractors: ["Ho studiato lo stesso", "Non si può dire niente", "L'esame era troppo difficile"],
      explanation: "Questa volta il passaggio è valido: se manca l'effetto garantito, manca anche la causa che lo garantiva." },
    { difficulty: 4, topic: "verita", prompt: "Un'affermazione e la sua negazione possono essere vere tutte e due?", answer: "No, mai",
      distractors: ["Sì, sempre", "Sì, se parlano di cose diverse", "Solo in matematica"],
      explanation: "È il principio di non contraddizione: se «piove» è vera, «non piove» è falsa. Non c'è via di mezzo." },
    { difficulty: 4, topic: "analogie", prompt: "Orologio sta a tempo come termometro sta a…", answer: "temperatura",
      distractors: ["calore", "acqua", "altezza"],
      explanation: "La relazione è «strumento → grandezza che misura». Il calore e la temperatura non sono la stessa cosa." },
    { difficulty: 4, topic: "analogie", prompt: "Ape sta ad alveare come formica sta a…", answer: "formicaio",
      distractors: ["favo", "nido", "tana"],
      explanation: "La relazione è «animale → la sua casa». Il favo sta dentro l'alveare, non è la casa della formica." },
    { difficulty: 4, topic: "esclusioni", prompt: "Quale non appartiene al gruppo: quadrato, rombo, cerchio, trapezio?", answer: "cerchio",
      distractors: ["quadrato", "rombo", "trapezio"],
      explanation: "Gli altri tre sono poligoni, cioè hanno i lati dritti. Il cerchio non ne ha nessuno." },
    { difficulty: 4, topic: "sequenze", prompt: "Quale numero continua la serie: 2, 6, 12, 20, 30, ?", answer: "42",
      distractors: ["36", "40", "44"],
      explanation: "Le differenze crescono di due in due: +4, +6, +8, +10 e poi +12, quindi 30 + 12 = 42." },
  ],
  "geografia": [
    { difficulty: 4, topic: "climi", prompt: "Perché all'equatore fa più caldo che ai poli?", answer: "I raggi del Sole arrivano più diritti",
      distractors: ["L'equatore è molto più vicino al Sole", "Ai poli soffia sempre il vento", "All'equatore non ci sono mai nuvole"],
      explanation: "Non è questione di distanza ma di inclinazione: ai poli gli stessi raggi si spalmano su molta più superficie." },
    { difficulty: 4, topic: "climi", prompt: "Che cos'è il clima mediterraneo?", answer: "Estati calde e secche, inverni miti e piovosi",
      distractors: ["Estati fresche e piovose, inverni gelidi", "Caldo e pioggia tutto l'anno", "Freddo e secco tutto l'anno"],
      explanation: "È il clima delle coste del Mediterraneo, e per questo ci crescono ulivo, vite e agrumi." },
    { difficulty: 4, topic: "geografia-fisica", prompt: "Che cosa sono i meridiani?", answer: "Le linee che uniscono i due poli",
      distractors: ["I cerchi paralleli all'equatore", "I confini fra gli Stati", "Le rotte seguite dalle navi"],
      explanation: "I meridiani vanno da polo a polo; i paralleli sono invece i cerchi paralleli all'equatore." },
    { difficulty: 4, topic: "geografia-fisica", prompt: "Che cosa distingue un golfo da una penisola?", answer: "Il golfo è mare che entra nella terra, la penisola è terra che entra nel mare",
      distractors: ["Sono la stessa cosa vista da lontano", "Il golfo è d'acqua dolce", "La penisola è sempre un'isola"],
      explanation: "Sono due forme opposte della stessa costa: uno rientra, l'altra sporge." },
    { difficulty: 4, topic: "geografia-umana", prompt: "Che cos'è la densità di popolazione?", answer: "Quanti abitanti ci sono per chilometro quadrato",
      distractors: ["Quanti abitanti ha in tutto uno Stato", "Quanto è grande una città", "Quante case ci sono in un quartiere"],
      explanation: "Due Paesi con la stessa popolazione hanno densità molto diverse se uno è più esteso dell'altro." },
    { difficulty: 4, topic: "europa", prompt: "Qual è il fiume più lungo d'Europa?", answer: "Il Volga",
      distractors: ["Il Danubio", "Il Reno", "Il Po"],
      explanation: "Il Volga scorre in Russia per oltre 3500 km; il Danubio è il secondo." },
    { difficulty: 4, topic: "mondo", prompt: "Quale oceano separa l'Europa dall'America?", answer: "L'Oceano Atlantico",
      distractors: ["L'Oceano Pacifico", "L'Oceano Indiano", "L'Oceano Artico"],
      explanation: "L'Atlantico sta fra Europa-Africa e le Americhe; il Pacifico sta dall'altra parte del mondo." },
    { difficulty: 4, topic: "geografia-italia", prompt: "Quale catena montuosa separa l'Italia dal resto d'Europa?", answer: "Le Alpi",
      distractors: ["Gli Appennini", "I Pirenei", "I Carpazi"],
      explanation: "Le Alpi chiudono l'Italia a nord; gli Appennini invece la percorrono da nord a sud." },
  ],
  "italiano": [
    { difficulty: 1, topic: "ortografia", prompt: "Come si scrive correttamente «una amica»?", answer: "un'amica", distractors: ["un amica","un'amico","una amica"], explanation: "L'apostrofo serve davanti a parola femminile che comincia per vocale: «una amica» diventa «un'amica». Al maschile si scrive «un amico», senza apostrofo." },
    { difficulty: 2, topic: "ortografia", prompt: "Si scrive «qual è» o «qual'è»?", answer: "qual è", distractors: ["qual'è","quale è","qualè"], explanation: "«Qual» è una forma tronca, non elisa: non vuole l'apostrofo. È una delle regole più tradite in assoluto." },
    { difficulty: 2, topic: "ortografia", prompt: "Come si scrive il plurale di «camicia»?", answer: "camicie", distractors: ["camice","camicee","camici"], explanation: "Quando la «cia» è preceduta da vocale il plurale tiene la i: camicia→camicie, ciliegia→ciliegie." },
    { difficulty: 3, topic: "ortografia", prompt: "Come si scrive il plurale di «arancia»?", answer: "arance", distractors: ["arancie","arancee","aranci"], explanation: "Qui la «cia» è preceduta da consonante, quindi la i cade: arancia→arance, pioggia→piogge." },
    { difficulty: 2, topic: "ortografia", prompt: "Si scrive «ho fatto» o «o fatto»?", answer: "ho fatto", distractors: ["o fatto","hò fatto","ó fatto"], explanation: "«Ho» è voce del verbo avere e vuole l'acca; «o» senza acca è la congiunzione: «pane o pasta»." },
    { difficulty: 3, topic: "ortografia", prompt: "Quale frase è scritta correttamente?", answer: "Non so se ne ha parlato", distractors: ["Non so se n'è parlato lui","Non sò se ne ha parlato","Non so se nè ha parlato"], explanation: "«So» non vuole accento; «ne» pronome non vuole accento; «né» con accento significa «e non»." },
    { difficulty: 2, topic: "ortografia", prompt: "Si scrive «un po'» o «un pò»?", answer: "un po'", distractors: ["un pò","un pó","un po"], explanation: "«Po'» è l'abbreviazione di «poco»: vuole l'apostrofo perché è un troncamento, non un accento." },
    { difficulty: 3, topic: "ortografia", prompt: "Quale coppia è scritta correttamente?", answer: "dà (verbo) e da (preposizione)", distractors: ["da (verbo) e dà (preposizione)","dà (verbo) e dà (preposizione)","da (verbo) e da (preposizione)"], explanation: "L'accento distingue il verbo dare dalla preposizione: «mi dà un libro» e «vengo da Roma»." },
    { difficulty: 3, topic: "ortografia", prompt: "Come si scrive correttamente?", answer: "l'ho visto", distractors: ["lo visto","l'o visto","loh visto"], explanation: "«L'ho» è «lo» + «ho»: il pronome si elide e il verbo tiene l'acca." },
    { difficulty: 4, topic: "ortografia", prompt: "Si scrive «efficiente» o «efficente»?", answer: "efficiente", distractors: ["efficente","eficiente","efficiente e"], explanation: "Si scrive con la i: efficiente, sufficiente, deficiente. Segue la regola dei participi in -ente da verbi in -ire." },
    { difficulty: 2, topic: "ortografia", prompt: "Quale parola è scritta correttamente?", answer: "coscienza", distractors: ["conoscienza","coscenza","cosciensa"], explanation: "«Coscienza» e «conoscenza» sono due parole diverse: la prima con la i, la seconda senza." },
    { difficulty: 3, topic: "ortografia", prompt: "Come si scrive il plurale di «farmacia»?", answer: "farmacie", distractors: ["farmace","farmacee","farmaci"], explanation: "Qui la i è accentata e si sente: farmacìa→farmacie. La regola cade quando la i è tonica." },
    { difficulty: 2, topic: "ortografia", prompt: "Il pronome «se» riflessivo vuole l'accento?", answer: "sé stesso", distractors: ["se stesso senza accento mai","sè stesso","sé stessó"], explanation: "Il pronome «sé» vuole l'accento acuto. Davanti a «stesso» oggi è ammessa anche la forma senza, ma con accento è sempre corretta." },
    { difficulty: 4, topic: "ortografia", prompt: "Quale frase contiene un errore?", answer: "Qual'è il tuo nome?", distractors: ["Qual è il tuo nome?","Che cosa hai fatto?","Non lo so ancora"], explanation: "«Qual è» non vuole apostrofo: è l'errore ortografico più diffuso in italiano." },
    { difficulty: 1, topic: "punteggiatura", prompt: "Quale segno chiude una domanda?", answer: "Il punto interrogativo", distractors: ["Il punto esclamativo","I due punti","Il punto e virgola"], explanation: "Il punto interrogativo segnala una domanda diretta: «Dove vai?». Nelle domande indirette non si mette." },
    { difficulty: 2, topic: "punteggiatura", prompt: "In «Ho comprato tutto: pane, latte e uova», che cosa annunciano i due punti?", answer: "Un elenco che spiega quel «tutto»", distractors: ["Una pausa più lunga della virgola","La chiusura di un discorso diretto","Un cambio di argomento nel testo"], explanation: "Annunciano quello che viene dopo: «Ho comprato tutto: pane, latte e uova»." },
    { difficulty: 3, topic: "punteggiatura", prompt: "Quale frase usa correttamente la virgola?", answer: "Marco, vieni qui un momento.", distractors: ["Marco vieni, qui un momento.","Marco vieni qui, un momento.","Marco, vieni, qui un momento."], explanation: "La virgola isola il vocativo, cioè la persona a cui ci si rivolge. Separare il verbo dal suo oggetto è invece un errore." },
    { difficulty: 3, topic: "punteggiatura", prompt: "Perché non si mette mai la virgola fra soggetto e verbo?", answer: "Perché spezza il legame fondamentale della frase", distractors: ["Perché la virgola serve solo agli elenchi","Perché il soggetto va sempre per ultimo","Perché il verbo non ammette pause vicine"], explanation: "«Il cane, abbaia» è sbagliato: soggetto e verbo formano il nucleo della frase e non vanno separati." },
    { difficulty: 2, topic: "punteggiatura", prompt: "Quale segno introduce di solito il discorso diretto?", answer: "I due punti seguiti dalle virgolette", distractors: ["Il punto e virgola con la parentesi","La virgola seguita dal trattino","Il punto esclamativo con le virgolette"], explanation: "«Disse: “Arrivo subito”». I due punti annunciano che si sta per riportare una voce." },
    { difficulty: 3, topic: "punteggiatura", prompt: "A che cosa serve il punto e virgola?", answer: "A separare parti collegate ma abbastanza autonome", distractors: ["A chiudere in modo definitivo un periodo","A introdurre sempre e solo un elenco puntato","A segnalare che nella frase manca una parola"], explanation: "È una pausa più forte della virgola e più debole del punto: tiene insieme due frasi che si parlano." },
    { difficulty: 4, topic: "punteggiatura", prompt: "Quale frase è punteggiata correttamente?", answer: "Se piove, resto a casa.", distractors: ["Se, piove resto a casa.","Se piove resto, a casa.","Se piove, resto, a casa."], explanation: "La virgola separa la subordinata anticipata dalla principale: quando la condizione viene prima, la virgola aiuta a leggere." },
    { difficulty: 2, topic: "punteggiatura", prompt: "Che cosa segnalano i puntini di sospensione?", answer: "Una frase lasciata in sospeso", distractors: ["La fine definitiva del testo","Un elenco che continua a lungo","Un errore di battitura"], explanation: "Sono sempre tre e indicano un pensiero interrotto o una reticenza: «Non so se…»." },
    { difficulty: 3, topic: "punteggiatura", prompt: "A che cosa servono le parentesi?", answer: "A inserire un'informazione accessoria", distractors: ["A segnalare un errore nel testo","A introdurre un discorso diretto","A chiudere un elenco lungo"], explanation: "Quello che sta fra parentesi si può togliere senza rompere la frase: è un inciso." },
    { difficulty: 4, topic: "punteggiatura", prompt: "«Non lo faccio, però ci penso» — che rapporto segnala la virgola?", answer: "Un'opposizione fra le due parti", distractors: ["Un elenco di due azioni","Una causa e il suo effetto","Una successione nel tempo"], explanation: "La virgola prepara il «però»: le due parti si contrappongono invece di sommarsi." },
    { difficulty: 3, topic: "punteggiatura", prompt: "Quale frase usa correttamente il punto esclamativo?", answer: "Che bella giornata!", distractors: ["Dove sei andato!","Non lo so proprio!?","Forse verrò domani!"], explanation: "Segnala sorpresa, gioia o comando. Una domanda vuole il punto interrogativo, anche se detta con enfasi." },
    { difficulty: 4, topic: "punteggiatura", prompt: "In un elenco «pane, latte e uova», perché prima di «e» non c'è la virgola?", answer: "Perché la congiunzione sostituisce la virgola", distractors: ["Perché l'ultimo elemento è più corto","Perché le uova sono un plurale","Perché l'elenco ha solo tre voci"], explanation: "In italiano la virgola prima della «e» conclusiva di solito non si mette: la congiunzione fa già il lavoro." },
    { difficulty: 2, topic: "punteggiatura", prompt: "Che cosa chiude un periodo?", answer: "Il punto fermo", distractors: ["La virgola","I due punti","Il trattino"], explanation: "Il punto fermo segna la fine di un pensiero compiuto; dopo si ricomincia con la maiuscola." },
    { difficulty: 3, topic: "punteggiatura", prompt: "«Luca, che è mio cugino, arriva domani» — che cosa isolano le virgole?", answer: "Un inciso che si può togliere", distractors: ["Il soggetto della frase","Il complemento oggetto","Il verbo principale"], explanation: "Togliendo l'inciso resta «Luca arriva domani»: la frase regge, quindi quella parte era accessoria." },
    { difficulty: 1, topic: "verbo", prompt: "Quale di queste è una voce del verbo essere?", answer: "sono", distractors: ["hanno","vado","faccio"], explanation: "Essere e avere sono i due verbi ausiliari: «sono» è la prima persona del presente di essere." },
    { difficulty: 2, topic: "verbo", prompt: "«Mangiavo» a quale tempo è coniugato?", answer: "Imperfetto", distractors: ["Passato remoto","Presente","Futuro semplice"], explanation: "L'imperfetto descrive un'azione che durava nel passato: «mentre mangiavo, suonò il telefono»." },
    { difficulty: 2, topic: "verbo", prompt: "«Andrò» a quale tempo è coniugato?", answer: "Futuro semplice", distractors: ["Presente","Passato prossimo","Condizionale"], explanation: "Il futuro semplice indica un'azione che deve ancora avvenire." },
    { difficulty: 3, topic: "verbo", prompt: "Qual è il participio passato di «vedere»?", answer: "visto", distractors: ["vedeva","vedendo","vedere"], explanation: "«Vedendo» è il gerundio, «vedeva» l'imperfetto: il participio passato serve a formare i tempi composti, «ho visto»." },
    { difficulty: 3, topic: "verbo", prompt: "In «ho mangiato», qual è l'ausiliare?", answer: "ho", distractors: ["mangiato","ho mangiato","nessuno dei due"], explanation: "L'ausiliare è il verbo che aiuta a formare il tempo composto; il participio porta il significato." },
    { difficulty: 3, topic: "verbo", prompt: "Quale frase usa correttamente il congiuntivo?", answer: "Penso che sia giusto", distractors: ["Penso che è giusto","Penso che era giusto","Penso che sarà giusto"], explanation: "I verbi di opinione reggono il congiuntivo: penso, credo, ritengo vogliono «che sia», non «che è»." },
    { difficulty: 4, topic: "verbo", prompt: "«Se avessi tempo, verrei» — che modo è «verrei»?", answer: "Condizionale", distractors: ["Congiuntivo","Indicativo","Imperativo"], explanation: "Nel periodo ipotetico la condizione va al congiuntivo («avessi») e la conseguenza al condizionale («verrei»)." },
    { difficulty: 2, topic: "verbo", prompt: "Quale forma è all'imperativo?", answer: "Vieni qui!", distractors: ["Vieni domani?","Verresti qui?","Sei venuto qui"], explanation: "L'imperativo dà un ordine o un invito diretto: non ha la prima persona singolare." },
    { difficulty: 3, topic: "verbo", prompt: "Che differenza c'è fra verbo transitivo e intransitivo?", answer: "Il transitivo può reggere un complemento oggetto", distractors: ["Il transitivo si usa solo al passato","L'intransitivo non ha mai un soggetto","L'intransitivo si coniuga in modo diverso"], explanation: "«Mangio la mela» è transitivo; «vado a casa» è intransitivo, perché «a casa» non è un oggetto diretto." },
    { difficulty: 4, topic: "verbo", prompt: "«La mela è mangiata da Luca» — in quale forma è il verbo?", answer: "Passiva", distractors: ["Attiva","Riflessiva","Impersonale"], explanation: "Nella passiva il soggetto subisce l'azione; chi la compie diventa complemento d'agente, «da Luca»." },
    { difficulty: 3, topic: "verbo", prompt: "«Mi lavo le mani» — che tipo di verbo è «lavarsi»?", answer: "Riflessivo", distractors: ["Passivo","Impersonale","Servile"], explanation: "L'azione ricade su chi la compie: il pronome «mi» rimanda al soggetto." },
    { difficulty: 4, topic: "verbo", prompt: "Quali sono le tre coniugazioni dei verbi italiani?", answer: "-are, -ere, -ire", distractors: ["-are, -ire, -ure","-ere, -ire, -ore","-are, -ere, -ore"], explanation: "Si riconoscono dall'infinito: parlare, credere, dormire. I verbi in -urre come «condurre» derivano dalla seconda." },
    { difficulty: 2, topic: "verbo", prompt: "Quale voce è al passato prossimo?", answer: "Ho parlato", distractors: ["Parlavo","Parlerò","Parlerei"], explanation: "Il passato prossimo è composto: ausiliare al presente più participio passato." },
    { difficulty: 4, topic: "verbo", prompt: "«Bisogna partire presto» — che tipo di costruzione è?", answer: "Impersonale", distractors: ["Riflessiva","Passiva","Interrogativa"], explanation: "Non c'è un soggetto determinato: nessuno in particolare compie l'azione. Come «piove» o «si dice»." },
    { difficulty: 1, topic: "analisi-grammaticale", prompt: "Che parte del discorso è «bello»?", answer: "Aggettivo qualificativo", distractors: ["Nome comune di cosa","Verbo transitivo","Avverbio di modo"], explanation: "L'aggettivo qualificativo dice com'è il nome a cui si riferisce e ne segue genere e numero." },
    { difficulty: 2, topic: "analisi-grammaticale", prompt: "Che parte del discorso sono le parole che finiscono in -mente, come «lentamente»?", answer: "Avverbi", distractors: ["Aggettivi","Nomi astratti","Preposizioni"], explanation: "Gli avverbi in -mente modificano il verbo e restano invariabili: non cambiano al plurale." },
    { difficulty: 2, topic: "analisi-grammaticale", prompt: "Che parte del discorso è «sopra»?", answer: "Preposizione (o avverbio)", distractors: ["Congiunzione coordinante","Aggettivo qualificativo","Pronome dimostrativo"], explanation: "Introduce un complemento: «sopra il tavolo». Usata da sola («sta sopra») funziona da avverbio." },
    { difficulty: 3, topic: "analisi-grammaticale", prompt: "In «il mio libro», che cos'è «mio»?", answer: "Aggettivo possessivo", distractors: ["Pronome possessivo","Articolo determinativo","Aggettivo dimostrativo"], explanation: "Accompagna il nome, quindi è aggettivo. Sarebbe pronome in «il mio è rosso», dove sostituisce il nome." },
    { difficulty: 3, topic: "analisi-grammaticale", prompt: "In «questo è mio», che cos'è «questo»?", answer: "Pronome dimostrativo", distractors: ["Aggettivo dimostrativo","Articolo indeterminativo","Congiunzione"], explanation: "Sta al posto del nome invece di accompagnarlo: la stessa parola cambia categoria secondo l'uso." },
    { difficulty: 2, topic: "analisi-grammaticale", prompt: "Quanti sono gli articoli determinativi italiani?", answer: "7", format: "numeric_input", explanation: "il, lo, la, i, gli, le, l' — sette forme fra singolari e plurali, maschili e femminili." },
    { difficulty: 3, topic: "analisi-grammaticale", prompt: "Che parte del discorso è «e» in «pane e latte»?", answer: "Congiunzione", distractors: ["Preposizione","Avverbio","Interiezione"], explanation: "Le congiunzioni collegano parole o frasi: «e» somma, «ma» oppone, «perché» spiega." },
    { difficulty: 3, topic: "analisi-grammaticale", prompt: "Che tipo di nome è «coraggio»?", answer: "Nome astratto", distractors: ["Nome concreto","Nome collettivo","Nome proprio"], explanation: "Indica qualcosa che non si tocca né si vede: si oppone ai nomi concreti come «tavolo»." },
    { difficulty: 3, topic: "analisi-grammaticale", prompt: "Che tipo di nome è «gregge»?", answer: "Nome collettivo", distractors: ["Nome astratto","Nome proprio","Nome alterato"], explanation: "È singolare ma indica un insieme di individui: come «folla», «sciame», «squadra»." },
    { difficulty: 4, topic: "analisi-grammaticale", prompt: "In «gli parlo domani», che cos'è «gli»?", answer: "Pronome personale complemento", distractors: ["Articolo determinativo plurale","Aggettivo possessivo","Preposizione articolata"], explanation: "Qui sostituisce «a lui». La stessa forma è articolo in «gli amici»: conta la funzione, non la grafia." },
    { difficulty: 4, topic: "analisi-grammaticale", prompt: "Che cos'è «nella» in «nella scatola»?", answer: "Preposizione articolata", distractors: ["Preposizione semplice","Articolo determinativo","Avverbio di luogo"], explanation: "È «in» + «la» fuse insieme: preposizione più articolo in una parola sola." },
    { difficulty: 2, topic: "analisi-grammaticale", prompt: "Che parte del discorso è «tre»?", answer: "Aggettivo numerale", distractors: ["Nome comune","Avverbio di quantità","Articolo partitivo"], explanation: "I numerali cardinali accompagnano il nome indicandone la quantità esatta." },
    { difficulty: 4, topic: "analisi-grammaticale", prompt: "Quale parola è un'interiezione?", answer: "Ahi!", distractors: ["Anche","Poiché","Presto"], explanation: "Le interiezioni esprimono un'emozione improvvisa e stanno da sole: ahi, oh, ehi." },
    { difficulty: 3, topic: "analisi-grammaticale", prompt: "In «un po' di pane», che cos'è «di»?", answer: "Preposizione semplice", distractors: ["Congiunzione","Avverbio di quantità","Articolo partitivo"], explanation: "Le preposizioni semplici sono nove: di, a, da, in, con, su, per, tra, fra." },
    { difficulty: 2, topic: "analisi-logica", prompt: "In «Luca legge un libro», qual è il soggetto?", answer: "Luca", distractors: ["un libro","legge","legge un libro"], explanation: "Il soggetto compie l'azione: si trova chiedendo «chi legge?»." },
    { difficulty: 2, topic: "analisi-logica", prompt: "In «Luca legge un libro», che cos'è «un libro»?", answer: "Complemento oggetto", distractors: ["Soggetto","Complemento di termine","Predicato nominale"], explanation: "Risponde a «che cosa?» senza preposizione: è l'oggetto diretto dell'azione." },
    { difficulty: 3, topic: "analisi-logica", prompt: "In «Do il libro a Marco», che cos'è «a Marco»?", answer: "Complemento di termine", distractors: ["Complemento oggetto","Complemento di luogo","Complemento d'agente"], explanation: "Risponde a «a chi?»: indica il destinatario dell'azione, e si riconosce dalla preposizione «a»." },
    { difficulty: 3, topic: "analisi-logica", prompt: "In «Il quadro è dipinto da Sara», che cos'è «da Sara»?", answer: "Complemento d'agente", distractors: ["Complemento di causa","Complemento di mezzo","Complemento di luogo"], explanation: "Nelle frasi passive indica chi compie l'azione. Se non è una persona si chiama complemento di causa efficiente." },
    { difficulty: 3, topic: "analisi-logica", prompt: "In «Scrivo con la penna», che cos'è «con la penna»?", answer: "Complemento di mezzo", distractors: ["Complemento di modo","Complemento di compagnia","Complemento di causa"], explanation: "Risponde a «con che cosa?». Sarebbe di compagnia se fosse una persona: «esco con Marco»." },
    { difficulty: 3, topic: "analisi-logica", prompt: "In «Cammino lentamente», che cos'è «lentamente»?", answer: "Complemento di modo", distractors: ["Complemento di tempo","Complemento di mezzo","Complemento di luogo"], explanation: "Risponde a «come?»: descrive il modo in cui si svolge l'azione." },
    { difficulty: 2, topic: "analisi-logica", prompt: "Che cos'è il predicato verbale?", answer: "Il verbo che esprime l'azione del soggetto", distractors: ["Il nome che accompagna il soggetto","L'aggettivo riferito al soggetto","La parte che completa il nome"], explanation: "«Marco corre»: corre è predicato verbale. Con essere più un nome o aggettivo si ha il predicato nominale." },
    { difficulty: 4, topic: "analisi-logica", prompt: "In «Marco è simpatico», che cos'è «è simpatico»?", answer: "Predicato nominale", distractors: ["Predicato verbale","Complemento oggetto","Apposizione"], explanation: "Il verbo essere fa da copula e «simpatico» è la parte nominale: insieme dicono com'è il soggetto." },
    { difficulty: 3, topic: "analisi-logica", prompt: "In «Torno a settembre», che cos'è «a settembre»?", answer: "Complemento di tempo", distractors: ["Complemento di luogo","Complemento di termine","Complemento di fine"], explanation: "Risponde a «quando?». La stessa preposizione «a» introduce complementi diversi: conta la domanda a cui risponde." },
    { difficulty: 4, topic: "analisi-logica", prompt: "In «Studio per l'esame», che cos'è «per l'esame»?", answer: "Complemento di fine o scopo", distractors: ["Complemento di causa","Complemento di termine","Complemento di mezzo"], explanation: "Risponde a «per quale scopo?». Sarebbe di causa se rispondesse a «perché?»: «tremo per il freddo»." },
    { difficulty: 3, topic: "analisi-logica", prompt: "In «Vengo da Roma», che cos'è «da Roma»?", answer: "Complemento di moto da luogo", distractors: ["Complemento di stato in luogo","Complemento di moto a luogo","Complemento d'agente"], explanation: "Indica il punto di partenza. «Vado a Roma» sarebbe moto a luogo, «sto a Roma» stato in luogo." },
    { difficulty: 4, topic: "analisi-logica", prompt: "In «Giulia, la mia amica, arriva oggi», che cos'è «la mia amica»?", answer: "Apposizione", distractors: ["Complemento oggetto","Predicato nominale","Attributo"], explanation: "L'apposizione è un nome che precisa un altro nome. L'attributo invece è un aggettivo: «Giulia simpatica»." },
    { difficulty: 2, topic: "analisi-logica", prompt: "Come si trova il soggetto di una frase?", answer: "Chiedendo «chi compie l'azione?»", distractors: ["Cercando la parola più lunga","Prendendo sempre la prima parola","Guardando quale nome è al plurale"], explanation: "Il soggetto non è per forza all'inizio: «Arriva Marco» ha il soggetto in fondo." },
    { difficulty: 4, topic: "analisi-logica", prompt: "Una frase può avere il soggetto sottinteso?", answer: "Sì, quando si capisce dal verbo", distractors: ["No, il soggetto è sempre scritto","Solo nelle frasi interrogative","Solo con i verbi al passato"], explanation: "«Mangio una mela»: il soggetto «io» non è scritto ma la desinenza del verbo lo dice già." },
    { difficulty: 2, topic: "sintassi", prompt: "Che cos'è una proposizione principale?", answer: "Una frase che sta in piedi da sola", distractors: ["La frase più lunga del periodo","La prima frase di ogni periodo","La frase che contiene il soggetto"], explanation: "Non dipende da nessun'altra: «Esco» è principale anche se seguita da «perché piove»." },
    { difficulty: 3, topic: "sintassi", prompt: "In «Esco perché piove», che cos'è «perché piove»?", answer: "Proposizione subordinata causale", distractors: ["Proposizione principale autonoma","Proposizione coordinata alla prima","Proposizione subordinata finale"], explanation: "Dipende dalla principale e ne spiega il motivo: risponde a «perché?»." },
    { difficulty: 3, topic: "sintassi", prompt: "In «Mangio e bevo», che rapporto c'è fra le due frasi?", answer: "Sono coordinate", distractors: ["La seconda è subordinata","La prima è subordinata","Non c'è alcun rapporto"], explanation: "Le coordinate stanno sullo stesso piano, unite da una congiunzione: nessuna dipende dall'altra." },
    { difficulty: 3, topic: "sintassi", prompt: "Che cos'è un periodo?", answer: "Un insieme di frasi legate fino al punto fermo", distractors: ["Una frase che contiene un solo verbo","Un paragrafo intero di un testo lungo","Una frase priva di proposizioni subordinate"], explanation: "Il periodo può contenere una sola proposizione o dieci: si chiude con il punto." },
    { difficulty: 4, topic: "sintassi", prompt: "In «Spero che tu venga», che tipo di subordinata è?", answer: "Oggettiva", distractors: ["Soggettiva","Causale","Temporale"], explanation: "Fa da complemento oggetto della principale: spero che cosa? Che tu venga." },
    { difficulty: 4, topic: "sintassi", prompt: "In «Il libro che ho letto è bello», che tipo di subordinata è «che ho letto»?", answer: "Relativa", distractors: ["Oggettiva","Causale","Consecutiva"], explanation: "Le relative sono introdotte da un pronome relativo e precisano un nome della principale." },
    { difficulty: 3, topic: "sintassi", prompt: "In «Quando arrivi, chiamami», che cos'è «quando arrivi»?", answer: "Subordinata temporale", distractors: ["Subordinata causale","Subordinata finale","Proposizione principale"], explanation: "Colloca nel tempo l'azione della principale: risponde a «quando?»." },
    { difficulty: 4, topic: "sintassi", prompt: "In «Studio per passare l'esame», che cos'è «per passare l'esame»?", answer: "Subordinata finale", distractors: ["Subordinata causale","Subordinata consecutiva","Subordinata temporale"], explanation: "Indica lo scopo dell'azione principale: risponde a «per fare che cosa?»." },
    { difficulty: 4, topic: "sintassi", prompt: "In «Era così stanco che si addormentò», che cos'è la seconda frase?", answer: "Subordinata consecutiva", distractors: ["Subordinata causale","Subordinata finale","Proposizione coordinata"], explanation: "Esprime la conseguenza di quanto detto prima: «così… che» è la coppia tipica." },
    { difficulty: 3, topic: "sintassi", prompt: "Che cosa distingue una frase semplice da un periodo?", answer: "La frase semplice ha un solo predicato", distractors: ["La frase semplice è sempre più corta","Il periodo non ha mai il soggetto","La frase semplice non ha complementi"], explanation: "Si contano i verbi: un predicato, una proposizione. Due predicati fanno già un periodo." },
    { difficulty: 2, topic: "sintassi", prompt: "Quanti predicati ha la frase «Marco corre e Anna legge»?", answer: "2", format: "numeric_input", explanation: "Corre e legge: due predicati, quindi due proposizioni coordinate." },
    { difficulty: 4, topic: "sintassi", prompt: "In «Se studi, passerai», che tipo di periodo è?", answer: "Ipotetico", distractors: ["Interrogativo","Esclamativo","Comparativo"], explanation: "Un periodo ipotetico ha una condizione (protasi) e la sua conseguenza (apodosi)." },
    { difficulty: 3, topic: "sintassi", prompt: "Che cos'è una subordinata di primo grado?", answer: "Una frase che dipende direttamente dalla principale", distractors: ["La prima subordinata che si incontra","La subordinata più importante del periodo","Una subordinata con un solo verbo"], explanation: "Se una subordinata dipende a sua volta da un'altra subordinata, è di secondo grado." },
    { difficulty: 4, topic: "sintassi", prompt: "Perché l'ordine delle parole conta in italiano?", answer: "Perché può cambiare il significato o l'enfasi", distractors: ["Perché la grammatica lo impone sempre","Perché altrimenti la frase è più lunga","Perché i verbi vanno sempre in fondo"], explanation: "«Solo io l'ho detto» e «io l'ho detto solo» dicono cose diverse: la posizione sposta il fuoco." },
    { difficulty: 2, topic: "figure-retoriche", prompt: "«Sei veloce come il vento» è una…", answer: "Similitudine", distractors: ["Metafora","Personificazione","Iperbole"], explanation: "La similitudine dichiara il paragone con «come»; la metafora lo fa senza dirlo: «sei un fulmine»." },
    { difficulty: 2, topic: "figure-retoriche", prompt: "«Quel ragazzo è un leone» è una…", answer: "Metafora", distractors: ["Similitudine","Onomatopea","Anafora"], explanation: "Si sostituisce un termine con un altro senza «come»: il paragone resta implicito." },
    { difficulty: 3, topic: "figure-retoriche", prompt: "«Te l'ho detto un milione di volte» è una…", answer: "Iperbole", distractors: ["Litote","Metafora","Similitudine"], explanation: "L'iperbole esagera di proposito per dare forza: nessuno conta davvero un milione di volte." },
    { difficulty: 3, topic: "figure-retoriche", prompt: "«Din don dan» è un esempio di…", answer: "Onomatopea", distractors: ["Allitterazione","Anafora","Metafora"], explanation: "L'onomatopea imita un suono reale con le parole: tic tac, bum, fruscio." },
    { difficulty: 4, topic: "figure-retoriche", prompt: "«Non è male» detto di una cosa ottima è una…", answer: "Litote", distractors: ["Iperbole","Metafora","Ossimoro"], explanation: "La litote afferma negando il contrario: dice meno per far capire di più." },
    { difficulty: 4, topic: "figure-retoriche", prompt: "«Ghiaccio bollente» è un…", answer: "Ossimoro", distractors: ["Iperbole","Onomatopea","Climax"], explanation: "L'ossimoro accosta due termini che si contraddicono, creando un'immagine forte." },
    { difficulty: 3, topic: "figure-retoriche", prompt: "«Sempre caro mi fu quell'ermo colle» — perché l'ordine è insolito?", answer: "Le parole sono spostate per effetto poetico", distractors: ["È un errore di scrittura dell'autore","È un dialetto antico ormai scomparso","Le parole sono state tradotte male"], explanation: "Si chiama anastrofe o iperbato: cambiare l'ordine consueto crea ritmo e mette in rilievo certe parole." },
    { difficulty: 3, topic: "figure-retoriche", prompt: "Ripetere la stessa parola all'inizio di più versi si chiama…", answer: "Anafora", distractors: ["Allitterazione","Onomatopea","Similitudine"], explanation: "L'anafora martella un concetto ripetendolo in apertura: crea insistenza e ritmo." },
    { difficulty: 4, topic: "figure-retoriche", prompt: "«Fresche le mie parole ne la sera» — la ripetizione dei suoni si chiama…", answer: "Allitterazione", distractors: ["Anafora","Assonanza finale","Onomatopea"], explanation: "L'allitterazione ripete gli stessi suoni consonantici in parole vicine, dando musicalità al verso." },
    { difficulty: 3, topic: "figure-retoriche", prompt: "«Il vento urla fra i rami» attribuisce al vento…", answer: "Una qualità umana", distractors: ["Un suono più forte","Una posizione precisa","Un colore vivace"], explanation: "È la personificazione: si attribuiscono a cose o fenomeni comportamenti da esseri viventi." },
    { difficulty: 4, topic: "figure-retoriche", prompt: "Perché uno scrittore usa le figure retoriche?", answer: "Per rendere più vivo ed efficace il messaggio", distractors: ["Per allungare il testo di più","Per rendere il testo più difficile","Per rispettare le regole di grammatica"], explanation: "Non sono ornamenti: una metafora giusta fa capire in tre parole ciò che richiederebbe un paragrafo." },
    { difficulty: 2, topic: "figure-retoriche", prompt: "Quale frase contiene una similitudine?", answer: "Dorme come un ghiro", distractors: ["È un vero ghiro","Ghiro dormiglione!","Dorme moltissimo"], explanation: "La presenza di «come» segnala il paragone esplicito. Senza «come» sarebbe una metafora." },
    { difficulty: 4, topic: "figure-retoriche", prompt: "Una serie di termini di intensità crescente si chiama…", answer: "Climax", distractors: ["Anafora","Ossimoro","Litote"], explanation: "«Arrivò, vide, vinse» sale di intensità. Se scende si chiama anticlimax." },
    { difficulty: 3, topic: "figure-retoriche", prompt: "«La città dorme» è una…", answer: "Personificazione", distractors: ["Similitudine","Onomatopea","Allitterazione"], explanation: "Alla città, che non è viva, si attribuisce un'azione umana." },
    { difficulty: 2, topic: "testo-narrativo", prompt: "Che cos'è la trama di un racconto?", answer: "La successione dei fatti narrati", distractors: ["Il luogo in cui si svolge","L'insieme dei personaggi","Il messaggio dell'autore"], explanation: "La trama è cosa succede; l'ambientazione è dove, e i personaggi sono chi." },
    { difficulty: 2, topic: "testo-narrativo", prompt: "Chi è il protagonista di un racconto?", answer: "Il personaggio principale della vicenda", distractors: ["Il personaggio più simpatico","Chi racconta la storia","Il primo personaggio che appare"], explanation: "Chi racconta è il narratore, che può anche non essere un personaggio della storia." },
    { difficulty: 3, topic: "testo-narrativo", prompt: "Che cos'è l'antagonista?", answer: "Il personaggio che si oppone al protagonista", distractors: ["Il personaggio cattivo per definizione","Il narratore che giudica i fatti","Il personaggio che appare per ultimo"], explanation: "Non deve essere malvagio: può essere una persona in buona fede con un obiettivo incompatibile." },
    { difficulty: 3, topic: "testo-narrativo", prompt: "Un narratore che dice «io» e partecipa ai fatti si chiama…", answer: "Narratore interno", distractors: ["Narratore onnisciente","Narratore esterno","Narratore assente"], explanation: "Vede solo quello che il personaggio vede: è un punto di vista limitato, e per questo interessante." },
    { difficulty: 4, topic: "testo-narrativo", prompt: "Che cos'è un narratore onnisciente?", answer: "Un narratore che conosce pensieri e futuro di tutti", distractors: ["Un narratore che appare come personaggio","Un narratore che racconta solo i dialoghi","Un narratore che non prende posizione"], explanation: "Sa più dei personaggi: può dire cosa pensano tutti e anticipare quello che accadrà." },
    { difficulty: 3, topic: "testo-narrativo", prompt: "Che cos'è un flashback?", answer: "Un salto indietro nel tempo del racconto", distractors: ["Un salto in avanti nel futuro","Un sogno di un personaggio","La fine anticipata della storia"], explanation: "Interrompe l'ordine cronologico per mostrare un fatto passato che spiega il presente." },
    { difficulty: 3, topic: "testo-narrativo", prompt: "Che cos'è l'ambientazione?", answer: "Il tempo e il luogo in cui si svolge la storia", distractors: ["L'atmosfera emotiva che pervade il racconto","La descrizione dell'aspetto dei personaggi","La parte iniziale di un testo narrativo"], explanation: "Dove e quando: una stessa vicenda ambientata oggi o nel Medioevo diventa un'altra storia." },
    { difficulty: 4, topic: "testo-narrativo", prompt: "In quale parte del racconto si scioglie la tensione?", answer: "Nello scioglimento, dopo il culmine", distractors: ["Nell'esposizione iniziale","Nel momento di massima tensione","Nella descrizione dei luoghi"], explanation: "La curva tipica sale dall'esposizione al climax e poi scende verso la conclusione." },
    { difficulty: 2, topic: "testo-narrativo", prompt: "Come si chiama il momento di massima tensione?", answer: "Climax", distractors: ["Esposizione","Scioglimento","Epilogo"], explanation: "È il punto in cui il conflitto arriva al massimo e qualcosa deve cambiare." },
    { difficulty: 4, topic: "testo-narrativo", prompt: "Perché la stessa storia raccontata da due personaggi cambia?", answer: "Perché ognuno sa e sente cose diverse", distractors: ["Perché uno dei due ricorda male","Perché cambiano i fatti accaduti","Perché uno racconta più in fretta"], explanation: "I fatti restano, cambia il punto di vista: cosa sa chi racconta, e cosa gli importa." },
    { difficulty: 3, topic: "testo-narrativo", prompt: "Che cos'è il discorso diretto?", answer: "Le parole del personaggio riportate esattamente", distractors: ["Il riassunto di quello che ha detto","Il pensiero che non viene espresso a voce","La descrizione del tono con cui parla"], explanation: "Si segnala con virgolette o trattini: «Vieni qui», disse. Nel discorso indiretto: disse di venire." },
    { difficulty: 3, topic: "testo-narrativo", prompt: "Che cos'è un personaggio secondario?", answer: "Un personaggio che ha un ruolo minore nella vicenda", distractors: ["Un personaggio che appare una sola volta","Un personaggio inventato dal protagonista","Un personaggio senza nome proprio"], explanation: "Può essere importantissimo pur non essendo al centro: aiuta, ostacola o rivela qualcosa del protagonista." },
    { difficulty: 4, topic: "testo-narrativo", prompt: "Che cos'è il conflitto in una storia?", answer: "L'ostacolo fra il protagonista e ciò che vuole", distractors: ["Un litigio acceso fra due personaggi","La parte più violenta di tutto il racconto","Il disaccordo fra l'autore e il lettore"], explanation: "Senza conflitto non c'è storia: può essere una persona, una circostanza o un dubbio interiore." },
    { difficulty: 2, topic: "testo-narrativo", prompt: "Come si chiama la parte iniziale che presenta la situazione?", answer: "Esposizione", distractors: ["Climax","Scioglimento","Conflitto"], explanation: "Presenta con calma personaggi e luogo, prima che i problemi comincino." },
    { difficulty: 2, topic: "lessico", prompt: "Che cosa sono i sinonimi?", answer: "Parole di significato simile", distractors: ["Parole di significato opposto","Parole che si scrivono uguali","Parole della stessa famiglia"], explanation: "«Casa» e «abitazione» sono sinonimi, ma non sempre intercambiabili: cambia il registro." },
    { difficulty: 2, topic: "lessico", prompt: "Che cosa sono i contrari?", answer: "Parole di significato opposto", distractors: ["Parole di significato simile","Parole che suonano uguali","Parole di origine straniera"], explanation: "Alto e basso, entrare e uscire: il contrario dipende sempre dal contesto." },
    { difficulty: 3, topic: "lessico", prompt: "Che cosa sono gli omonimi?", answer: "Parole uguali con significati diversi", distractors: ["Parole simili con lo stesso senso","Parole della stessa famiglia","Parole di origine latina"], explanation: "«Riso» può essere il cereale o l'atto di ridere: stessa forma, due significati senza parentela." },
    { difficulty: 3, topic: "lessico", prompt: "Qual è il contrario di «generoso»?", answer: "Avaro", distractors: ["Gentile","Sincero","Prudente"], explanation: "Il contrario si oppone sulla stessa dimensione: qui il dare o il trattenere." },
    { difficulty: 3, topic: "lessico", prompt: "Che cos'è un prefisso?", answer: "Una parte che si aggiunge prima della radice", distractors: ["Una parte che si aggiunge alla fine","La parte centrale di una parola","Un segno che indica il plurale"], explanation: "In «rifare», «ri-» è il prefisso e indica ripetizione. In fondo si mettono i suffissi." },
    { difficulty: 3, topic: "lessico", prompt: "In «giardiniere», qual è il suffisso?", answer: "-iere", distractors: ["giardin-","-ino","-are"], explanation: "Il suffisso «-iere» forma nomi di mestiere: giardiniere, cassiere, portiere." },
    { difficulty: 4, topic: "lessico", prompt: "Che cos'è un campo semantico?", answer: "L'insieme di parole legate a uno stesso tema", distractors: ["L'insieme delle parole di una lingua","Le parole con la stessa radice","Le parole che si scrivono uguali"], explanation: "Mare, onda, barca, scoglio appartengono allo stesso campo: non sono parenti, parlano della stessa cosa." },
    { difficulty: 4, topic: "lessico", prompt: "Che cos'è una famiglia di parole?", answer: "Parole che condividono la stessa radice", distractors: ["Parole che parlano dello stesso tema","Parole di significato simile","Parole con la stessa lunghezza"], explanation: "Fiore, fioraio, fiorire, infiorata: la radice è la stessa, ed è una parentela di forma prima che di senso." },
    { difficulty: 3, topic: "lessico", prompt: "Che cos'è un diminutivo?", answer: "Una forma alterata che indica piccolezza", distractors: ["Una parola più corta della normale","Un sinonimo poco usato","Un contrario attenuato"], explanation: "Casa→casetta, libro→libretto. Esistono anche accrescitivi, vezzeggiativi e dispregiativi." },
    { difficulty: 4, topic: "lessico", prompt: "Che differenza c'è fra significato letterale e figurato?", answer: "Il figurato usa la parola oltre il suo senso proprio", distractors: ["Il senso figurato è sempre più antico","Il senso letterale si usa solo in poesia","Il senso figurato vale solo per i verbi"], explanation: "«Ha il cuore di pietra» non parla di minerali: il senso figurato nasce da un'immagine." },
    { difficulty: 2, topic: "lessico", prompt: "Qual è un sinonimo di «veloce»?", answer: "Rapido", distractors: ["Lento","Pesante","Silenzioso"], explanation: "Sinonimo significa vicino di significato: rapido e veloce si sostituiscono quasi sempre." },
    { difficulty: 4, topic: "lessico", prompt: "Che cos'è un termine specialistico?", answer: "Una parola usata soprattutto in un certo ambito", distractors: ["Una parola difficile da pronunciare bene","Una parola presa da una lingua straniera","Una parola che ormai non si usa più"], explanation: "«Battuta» in musica significa una cosa precisa: fuori da lì significa altro. Ogni disciplina ha il suo lessico." },
    { difficulty: 3, topic: "lessico", prompt: "Perché conoscere più sinonimi aiuta a scrivere?", answer: "Perché si evitano ripetizioni e si sceglie la sfumatura giusta", distractors: ["Perché il testo che si scrive diventa molto più lungo","Perché si possono usare parole più difficili e ricercate","Perché la grammatica italiana lo richiede espressamente"], explanation: "Non è questione di eleganza: fra «casa», «dimora» e «tugurio» cambia quello che il lettore immagina." },
    { difficulty: 4, topic: "analisi-logica", prompt: "Nella frase «Il gatto dorme sul divano», «sul divano» è complemento di…", answer: "luogo",
      distractors: ["tempo", "mezzo", "modo"],
      explanation: "Risponde alla domanda «dove?», quindi è complemento di luogo." },
    { difficulty: 4, topic: "analisi-grammaticale", prompt: "Che parte del discorso è «velocemente»?", answer: "Avverbio",
      distractors: ["Aggettivo", "Nome", "Verbo"],
      explanation: "Gli avverbi in -mente nascono dagli aggettivi e dicono come avviene l'azione: veloce → velocemente." },
    { difficulty: 4, topic: "verbo", prompt: "In «Se avessi studiato, avrei passato l'esame», che modo è «avessi studiato»?", answer: "Congiuntivo",
      distractors: ["Indicativo", "Condizionale", "Imperativo"],
      explanation: "Il congiuntivo regge l'ipotesi; «avrei passato» è invece il condizionale, che regge la conseguenza." },
    { difficulty: 4, topic: "sintassi", prompt: "Che cos'è una proposizione subordinata?", answer: "Una frase che dipende da un'altra",
      distractors: ["Una frase che sta in piedi da sola", "Una frase senza verbo", "Una frase scritta fra virgolette"],
      explanation: "La principale regge da sola; la subordinata ha bisogno di lei per avere senso compiuto." },
    { difficulty: 4, topic: "figure-retoriche", prompt: "«Il vento urla fra i rami» è una…", answer: "personificazione",
      distractors: ["similitudine", "iperbole", "metonimia"],
      explanation: "Al vento è attribuita un'azione umana, urlare: è una personificazione." },
    { difficulty: 4, topic: "lessico", prompt: "Che cosa vuol dire «effimero»?", answer: "Che dura pochissimo",
      distractors: ["Che costa molto", "Che è difficile da capire", "Che si ripete spesso"],
      explanation: "Un successo effimero passa in fretta: il contrario è duraturo." },
    { difficulty: 4, topic: "lessico", prompt: "Che cosa vuol dire «tacito»?", answer: "Non detto, sottinteso",
      distractors: ["Detto ad alta voce", "Scritto a mano", "Ripetuto due volte"],
      explanation: "Un accordo tacito non è né scritto né pronunciato: si dà per inteso." },
    { difficulty: 4, topic: "ortografia", prompt: "Quale forma è corretta?", answer: "Un'amica",
      distractors: ["Un amica", "Una amica", "Un'amico"],
      explanation: "L'apostrofo va davanti a un nome femminile che comincia per vocale. Al maschile si scrive «un amico», senza apostrofo." },
    { difficulty: 4, topic: "testo-narrativo", prompt: "Che cos'è un narratore in prima persona?", answer: "Chi racconta è dentro la storia e dice «io»",
      distractors: ["Chi racconta sa tutto di tutti", "Chi racconta parla solo al presente", "Chi racconta è l'autore del libro"],
      explanation: "Il narratore in prima persona vede solo quello che vede il personaggio: è un limite che l'autore sceglie apposta." },
    { difficulty: 4, topic: "punteggiatura", prompt: "A che cosa servono i due punti?", answer: "Ad annunciare una spiegazione o un elenco",
      distractors: ["A separare due frasi senza legame", "A chiudere il discorso diretto", "A indicare una domanda"],
      explanation: "I due punti aprono qualcosa: una spiegazione, un elenco o le parole di qualcuno." },
    { topic: "ortografia", difficulty: 1, format: "short_answer", prompt: "Come si scrive il plurale di «amico»?", answer: "amici", explanation: "Davanti alla i il c resta duro: amici si legge con la c di casa." },
    { topic: "ortografia", difficulty: 2, format: "short_answer", prompt: "Come si scrive il plurale di «valigia»?", answer: "valigie", explanation: "La i si conserva perché prima della g c'è una vocale." },
    { topic: "ortografia", difficulty: 2, format: "short_answer", prompt: "Come si scrive il plurale di «spiaggia»?", answer: "spiagge", explanation: "Prima della g c'è una consonante: la i cade." },
    { topic: "ortografia", difficulty: 2, format: "short_answer", prompt: "Come si scrive il plurale di «buccia»?", answer: "bucce", explanation: "Consonante prima della c: la i non serve più." },
    { topic: "ortografia", difficulty: 3, format: "short_answer", prompt: "Come si scrive il plurale di «ciliegia»?", answer: "ciliegie", accept: ["ciliege"], explanation: "Vocale prima della g: la i resta." },
    { topic: "ortografia", difficulty: 1, format: "short_answer", prompt: "Qual è il contrario di «regolare» ottenuto aggiungendo un prefisso?", answer: "irregolare", explanation: "Davanti a r il prefisso in- diventa ir-." },
    { topic: "punteggiatura", difficulty: 1, format: "short_answer", prompt: "Come si chiama il segno che chiude una domanda?", answer: "punto interrogativo", accept: ["punto di domanda"], explanation: "Dopo di lui la frase è finita: si ricomincia con la maiuscola." },
    { topic: "punteggiatura", difficulty: 2, format: "short_answer", prompt: "Come si chiama il segno che introduce un elenco o una spiegazione?", answer: "due punti", accept: ["i due punti"], explanation: "Aprono: quello che segue spiega quello che precede." },
    { topic: "punteggiatura", difficulty: 2, format: "short_answer", prompt: "Come si chiama il segno che separa parti collegate ma abbastanza autonome?", answer: "punto e virgola", explanation: "Più della virgola, meno del punto." },
    { topic: "punteggiatura", difficulty: 3, format: "short_answer", prompt: "Come si chiamano i segni che racchiudono le parole dette da un personaggio?", answer: "virgolette", explanation: "Aprono e chiudono il discorso diretto." },
    { topic: "punteggiatura", difficulty: 2, format: "short_answer", prompt: "Come si chiama il segno che indica una pausa breve dentro la frase?", answer: "virgola", accept: ["la virgola"], explanation: "Non si mette mai fra soggetto e verbo: spezzerebbe il legame principale." },
    { topic: "verbo", difficulty: 1, format: "short_answer", prompt: "Qual è l'infinito del verbo nella frase «io corro»?", answer: "correre", explanation: "L'infinito è la forma con cui il verbo si cerca nel vocabolario." },
    { topic: "verbo", difficulty: 2, format: "short_answer", prompt: "A quale modo del verbo appartiene la forma «correndo»?", answer: "gerundio", explanation: "Il gerundio esprime un'azione contemporanea a un'altra." },
    { topic: "verbo", difficulty: 2, format: "short_answer", prompt: "A quale modo appartiene la forma «corri!» rivolta a qualcuno?", answer: "imperativo", explanation: "È il modo dell'ordine, dell'invito e della richiesta." },
    { topic: "verbo", difficulty: 2, format: "short_answer", prompt: "A quale tempo dell'indicativo appartiene «correvo»?", answer: "imperfetto", explanation: "Racconta un'azione che durava o si ripeteva nel passato." },
    { topic: "verbo", difficulty: 3, format: "short_answer", prompt: "A quale modo appartiene «se io corressi»?", answer: "congiuntivo", explanation: "Il congiuntivo esprime possibilità, dubbio, desiderio." },
    { topic: "verbo", difficulty: 3, format: "short_answer", prompt: "Come si chiama la parte del verbo che resta uguale in tutte le voci?", answer: "radice", explanation: "Alla radice si attaccano le desinenze: cant-o, cant-avo, cant-erò." },
    { topic: "verbo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il verbo che regge un complemento oggetto?", answer: "transitivo", explanation: "L'azione passa dal soggetto all'oggetto: transitivo vuol dire che «passa»." },
    { topic: "analisi-grammaticale", difficulty: 1, format: "short_answer", prompt: "Come si chiama la parte del discorso che indica un'azione o uno stato?", answer: "verbo", explanation: "È il cuore della frase: senza verbo non c'è frase." },
    { topic: "analisi-grammaticale", difficulty: 1, format: "short_answer", prompt: "Come si chiama la parte del discorso che indica una qualità del nome?", answer: "aggettivo", explanation: "Si accorda con il nome in genere e numero." },
    { topic: "analisi-grammaticale", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parte del discorso che sostituisce un nome?", answer: "pronome", explanation: "Pro-nome: al posto del nome." },
    { topic: "analisi-grammaticale", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parte del discorso che precisa un verbo, come «lentamente»?", answer: "avverbio", explanation: "Precisa come, quando, quanto, dove." },
    { topic: "analisi-grammaticale", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parolina che collega due elementi, come «e» o «ma»?", answer: "congiunzione", explanation: "Unisce parole o intere proposizioni." },
    { topic: "analisi-grammaticale", difficulty: 3, format: "short_answer", prompt: "Come si chiama la parte invariabile che introduce un complemento, come «di» o «con»?", answer: "preposizione", explanation: "Da sola non dice niente: serve a legare." },
    { topic: "analisi-grammaticale", difficulty: 1, format: "short_answer", prompt: "Come si chiama la parola che accompagna il nome, come «il» o «una»?", answer: "articolo", explanation: "Determinativo se la cosa è nota, indeterminativo se è generica." },
    { topic: "analisi-logica", difficulty: 1, format: "short_answer", prompt: "Come si chiama chi compie l'azione nella frase?", answer: "soggetto", explanation: "Risponde a «chi? che cosa?» prima del verbo." },
    { topic: "analisi-logica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il complemento che risponde a «chi? che cosa?» dopo il verbo?", answer: "complemento oggetto", accept: ["oggetto"], explanation: "Lo reggono solo i verbi transitivi." },
    { topic: "analisi-logica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il complemento che risponde a «a chi? a che cosa?»?", answer: "complemento di termine", accept: ["termine"], explanation: "È il destinatario dell'azione: «do il libro a Luca»." },
    { topic: "analisi-logica", difficulty: 2, format: "short_answer", prompt: "Come si chiama il complemento che indica dove si svolge l'azione?", answer: "complemento di luogo", accept: ["luogo"], explanation: "Stato in luogo, moto a luogo, moto da luogo, moto per luogo." },
    { topic: "analisi-logica", difficulty: 3, format: "short_answer", prompt: "Come si chiama il complemento che indica il mezzo con cui si compie l'azione?", answer: "complemento di mezzo", accept: ["mezzo"], explanation: "«Scrivo con la penna»: la penna è il mezzo." },
    { topic: "analisi-logica", difficulty: 3, format: "short_answer", prompt: "Come si chiama il complemento che indica chi subisce, introdotto da «da» in una frase passiva?", answer: "complemento d'agente", accept: ["agente"], explanation: "«La lettera è scritta da Luca»: Luca è l'agente." },
    { topic: "sintassi", difficulty: 2, format: "short_answer", prompt: "Come si chiama la proposizione che regge da sola e non dipende da nessun'altra?", answer: "principale", accept: ["proposizione principale"], explanation: "Sta in piedi anche se togli tutto il resto." },
    { topic: "sintassi", difficulty: 2, format: "short_answer", prompt: "Come si chiama la proposizione che dipende da un'altra?", answer: "subordinata", accept: ["proposizione subordinata"], explanation: "Da sola non ha senso compiuto." },
    { topic: "sintassi", difficulty: 3, format: "short_answer", prompt: "Come si chiama il legame fra due proposizioni dello stesso livello unite da «e» o «ma»?", answer: "coordinazione", accept: ["coordinate"], explanation: "Nessuna delle due dipende dall'altra." },
    { topic: "sintassi", difficulty: 3, format: "short_answer", prompt: "Come si chiama la subordinata introdotta da «perché» che spiega il motivo?", answer: "causale", accept: ["proposizione causale"], explanation: "Dice perché avviene quello che dice la principale." },
    { topic: "sintassi", difficulty: 3, format: "short_answer", prompt: "Come si chiama la subordinata introdotta da «se»?", answer: "ipotetica", accept: ["condizionale"], explanation: "Pone una condizione: se succede questo, allora quello." },
    { topic: "figure-retoriche", difficulty: 2, format: "short_answer", prompt: "Come si chiama il paragone fatto senza «come», dicendo che una cosa è un'altra?", answer: "metafora", explanation: "«Sei un leone» non usa il come: è metafora." },
    { topic: "figure-retoriche", difficulty: 2, format: "short_answer", prompt: "Come si chiama il paragone esplicito introdotto da «come»?", answer: "similitudine", explanation: "«Forte come un leone»: il paragone è dichiarato." },
    { topic: "figure-retoriche", difficulty: 2, format: "short_answer", prompt: "Come si chiama la figura che attribuisce qualità umane a cose o animali?", answer: "personificazione", explanation: "«Il vento sussurra»: il vento non parla, ma noi lo sentiamo così." },
    { topic: "figure-retoriche", difficulty: 3, format: "short_answer", prompt: "Come si chiama l'esagerazione voluta, come «te l'ho detto mille volte»?", answer: "iperbole", explanation: "Non mente: esagera per farsi sentire." },
    { topic: "figure-retoriche", difficulty: 3, format: "short_answer", prompt: "Come si chiama la ripetizione della stessa parola all'inizio di più versi?", answer: "anafora", explanation: "Batte come un tamburo e tiene insieme il testo." },
    { topic: "figure-retoriche", difficulty: 3, format: "short_answer", prompt: "Come si chiama la parola che imita un suono, come «tic tac»?", answer: "onomatopea", explanation: "Il suono della parola è già il suo significato." },
    { topic: "testo-narrativo", difficulty: 1, format: "short_answer", prompt: "Come si chiama chi racconta la storia?", answer: "narratore", explanation: "Può essere un personaggio o una voce esterna." },
    { topic: "testo-narrativo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il personaggio principale di una storia?", answer: "protagonista", explanation: "È quello che vuole qualcosa e si muove per ottenerlo." },
    { topic: "testo-narrativo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il personaggio che si oppone al protagonista?", answer: "antagonista", explanation: "Senza opposizione non c'è racconto, solo cronaca." },
    { topic: "testo-narrativo", difficulty: 3, format: "short_answer", prompt: "Come si chiama il momento di massima tensione di una storia?", answer: "climax", explanation: "Da lì in poi la vicenda si scioglie." },
    { topic: "testo-narrativo", difficulty: 3, format: "short_answer", prompt: "Come si chiama la parte finale in cui i nodi si sciolgono?", answer: "scioglimento", accept: ["epilogo"], explanation: "Risponde alle domande che il racconto aveva aperto." },
    { topic: "testo-narrativo", difficulty: 2, format: "short_answer", prompt: "Come si chiama il momento in cui la situazione iniziale viene rotta da un fatto nuovo?", answer: "esordio", explanation: "È la scintilla che mette in moto la storia." },
    { topic: "lessico", difficulty: 1, format: "short_answer", prompt: "Come si chiama una parola che ha lo stesso significato di un'altra?", answer: "sinonimo", explanation: "Casa e abitazione dicono quasi la stessa cosa, con toni diversi." },
    { topic: "lessico", difficulty: 1, format: "short_answer", prompt: "Come si chiama una parola di significato opposto a un'altra?", answer: "contrario", accept: ["antonimo"], explanation: "Alto e basso, chiaro e scuro." },
    { topic: "lessico", difficulty: 2, format: "short_answer", prompt: "Come si chiamano due parole che si scrivono uguali ma hanno significati diversi?", answer: "omonimi", accept: ["omonimo"], explanation: "«Riso» è un cereale e anche una risata." },
    { topic: "lessico", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parte iniziale che si aggiunge a una parola per cambiarne il senso?", answer: "prefisso", explanation: "In-, s-, ri-: piccole aggiunte che ribaltano il significato." },
    { topic: "lessico", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parte finale che si aggiunge a una radice per formare una parola nuova?", answer: "suffisso", explanation: "Da libro a libreria, da fiore a fiorista." },
    { topic: "lessico", difficulty: 3, format: "short_answer", prompt: "Come si chiama il significato non letterale di una parola, come «avere le mani bucate»?", answer: "figurato", accept: ["senso figurato", "significato figurato"], explanation: "Le mani non sono bucate davvero: si spende troppo." },
    { topic: "pensiero-linguaggio", difficulty: 2, format: "short_answer", prompt: "Come si chiama il riassunto in poche righe di un testo lungo?", answer: "sintesi", accept: ["riassunto"], explanation: "Tiene solo quello senza cui il testo non si capirebbe." },
    { topic: "pensiero-linguaggio", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'idea principale attorno a cui ruota un testo?", answer: "tema", explanation: "Tutto il resto serve a sostenerla o a chiarirla." },
    { topic: "pensiero-linguaggio", difficulty: 3, format: "short_answer", prompt: "Come si chiama la ragione portata per sostenere una tesi?", answer: "argomento", accept: ["argomentazione"], explanation: "Una tesi senza argomenti è solo un'opinione detta a voce alta." },
    { topic: "pensiero-linguaggio", difficulty: 3, format: "short_answer", prompt: "Come si chiama l'affermazione che si vuole dimostrare in un testo argomentativo?", answer: "tesi", explanation: "Va enunciata chiaramente, altrimenti non si capisce cosa si sta difendendo." },
    { topic: "pensiero-linguaggio", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parola che collega due frasi indicando una conseguenza, come «quindi»?", answer: "connettivo", explanation: "I connettivi fanno vedere il ragionamento, non solo le frasi." },
    { topic: "pensiero-linguaggio", difficulty: 3, format: "short_answer", prompt: "Come si chiama il ragionamento che parte da casi particolari per arrivare a una regola generale?", answer: "induzione", explanation: "È il ragionamento dello scienziato che osserva molti casi." },
    { topic: "pensiero-linguaggio", difficulty: 3, format: "short_answer", prompt: "Come si chiama il ragionamento che parte da una regola generale per arrivare a un caso particolare?", answer: "deduzione", explanation: "Se la regola è vera, la conclusione è obbligata." },
    { topic: "pensiero-linguaggio", difficulty: 2, format: "short_answer", prompt: "Come si chiama il paragrafo che apre un testo e ne annuncia il contenuto?", answer: "introduzione", explanation: "Dice al lettore dove sta per andare." },
    { topic: "pensiero-linguaggio", difficulty: 2, format: "short_answer", prompt: "Come si chiama il paragrafo che chiude un testo tirando le somme?", answer: "conclusione", explanation: "Non aggiunge idee nuove: chiude quelle aperte." },
    { topic: "casa-famiglia", difficulty: 1, format: "short_answer", prompt: "Come si chiama la stanza in cui si prepara da mangiare?", answer: "cucina", accept: ["la cucina"], explanation: "La stanza prende il nome dall'attività che ci si svolge." },
    { topic: "casa-famiglia", difficulty: 1, format: "short_answer", prompt: "Come si chiama la stanza in cui si dorme?", answer: "camera", accept: ["camera da letto", "la camera"], explanation: "Camera da letto, per esteso." },
    { topic: "casa-famiglia", difficulty: 2, format: "short_answer", prompt: "Come si chiama il fratello del padre o della madre?", answer: "zio", accept: ["lo zio"], explanation: "Zio da parte di padre o di madre: il nome è lo stesso." },
    { topic: "casa-famiglia", difficulty: 2, format: "short_answer", prompt: "Come si chiama il figlio del figlio?", answer: "nipote", accept: ["il nipote"], explanation: "In italiano nipote vale sia per il figlio del figlio sia per il figlio del fratello." },
    { topic: "casa-famiglia", difficulty: 2, format: "short_answer", prompt: "Come si chiama la parte esterna della casa, aperta e sporgente dal muro?", answer: "balcone", accept: ["il balcone"], explanation: "Se è a livello del terreno si chiama terrazza o giardino." },
    { topic: "casa-famiglia", difficulty: 3, format: "short_answer", prompt: "Come si chiama l'insieme dei mobili e degli oggetti che arredano una stanza?", answer: "arredamento", explanation: "Dalla stessa radice: arredare, arredo." },
    { topic: "scuola-studio", difficulty: 1, format: "short_answer", prompt: "Come si chiama la prova scritta che verifica quello che hai studiato?", answer: "verifica", accept: ["compito", "prova"], explanation: "Verifica, compito in classe: la sostanza è la stessa." },
    { topic: "scuola-studio", difficulty: 1, format: "short_answer", prompt: "Come si chiama il quaderno in cui l'insegnante annota voti e presenze?", answer: "registro", accept: ["il registro"], explanation: "Oggi quasi sempre elettronico." },
    { topic: "scuola-studio", difficulty: 2, format: "short_answer", prompt: "Come si chiama il periodo di pausa fra due ore di lezione?", answer: "intervallo", accept: ["ricreazione"], explanation: "Serve a staccare: la testa non regge cinque ore di fila." },
    { topic: "scuola-studio", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'elenco delle materie ora per ora nella settimana?", answer: "orario", accept: ["l'orario"], explanation: "Dice cosa ti serve nello zaino ogni giorno." },
    { topic: "scuola-studio", difficulty: 2, format: "short_answer", prompt: "Come si chiama chi frequenta una scuola per imparare?", answer: "studente", accept: ["alunno", "lo studente"], explanation: "Alunno e studente sono quasi sinonimi." },
    { topic: "scuola-studio", difficulty: 3, format: "short_answer", prompt: "Come si chiama il documento che raccoglie i voti alla fine del quadrimestre?", answer: "pagella", accept: ["la pagella"], explanation: "Non racconta tutto, ma resta il resoconto ufficiale." },
    { topic: "cibo-spesa", difficulty: 1, format: "short_answer", prompt: "Come si chiama il negozio in cui si compra il pane?", answer: "panetteria", accept: ["panificio", "forno"], explanation: "Dal nome del prodotto principale." },
    { topic: "cibo-spesa", difficulty: 1, format: "short_answer", prompt: "Come si chiama il negozio in cui si compra la carne?", answer: "macelleria", accept: ["la macelleria"], explanation: "Chi ci lavora è il macellaio." },
    { topic: "cibo-spesa", difficulty: 2, format: "short_answer", prompt: "Come si chiama il foglietto che elenca quello che devi comprare?", answer: "lista", accept: ["lista della spesa"], explanation: "Lista della spesa: si scrive prima di uscire, non al supermercato." },
    { topic: "cibo-spesa", difficulty: 2, format: "short_answer", prompt: "Come si chiama il foglio che il negozio ti dà a prova del pagamento?", answer: "scontrino", accept: ["lo scontrino"], explanation: "Serve anche per cambiare la merce." },
    { topic: "cibo-spesa", difficulty: 2, format: "short_answer", prompt: "Come si chiama il pasto che si fa a metà giornata?", answer: "pranzo", accept: ["il pranzo"], explanation: "Fra colazione e cena." },
    { topic: "cibo-spesa", difficulty: 3, format: "short_answer", prompt: "Come si chiama la data oltre la quale un alimento non va più consumato?", answer: "scadenza", accept: ["data di scadenza"], explanation: "«Da consumarsi entro»: sulla confezione è sempre scritta." },
    { topic: "tempo-meteo", difficulty: 1, format: "short_answer", prompt: "Come si chiama l'acqua che cade dalle nuvole?", answer: "pioggia", accept: ["la pioggia"], explanation: "Se cade ghiacciata si chiama grandine." },
    { topic: "tempo-meteo", difficulty: 1, format: "short_answer", prompt: "Come si chiama la neve che cade sotto forma di chicchi di ghiaccio?", answer: "grandine", accept: ["la grandine"], explanation: "Si forma quando le correnti portano le gocce su e giù nella nuvola." },
    { topic: "tempo-meteo", difficulty: 2, format: "short_answer", prompt: "Come si chiama lo strumento che misura la temperatura dell'aria?", answer: "termometro", explanation: "Va tenuto all'ombra, altrimenti misura il sole e non l'aria." },
    { topic: "tempo-meteo", difficulty: 2, format: "short_answer", prompt: "Come si chiama la nebbia bassa che si forma nelle notti fredde e serene?", answer: "brina", accept: ["la brina"], explanation: "Si deposita come una polvere bianca sull'erba." },
    { topic: "tempo-meteo", difficulty: 2, format: "short_answer", prompt: "Come si chiama la previsione del tempo per i giorni successivi?", answer: "previsione", accept: ["previsioni", "previsioni del tempo"], explanation: "Non è una certezza: è una probabilità." },
    { topic: "tempo-meteo", difficulty: 3, format: "short_answer", prompt: "Come si chiamano le quattro parti in cui si divide l'anno secondo il clima?", answer: "stagioni", accept: ["le stagioni"], explanation: "Nascono dall'inclinazione dell'asse terrestre." },
    { topic: "viaggi-luoghi", difficulty: 1, format: "short_answer", prompt: "Come si chiama il luogo da cui partono e arrivano i treni?", answer: "stazione", accept: ["la stazione"], explanation: "Stazione ferroviaria, per esteso." },
    { topic: "viaggi-luoghi", difficulty: 1, format: "short_answer", prompt: "Come si chiama il luogo da cui partono e arrivano gli aerei?", answer: "aeroporto", accept: ["l'aeroporto"], explanation: "Dal greco aer, aria." },
    { topic: "viaggi-luoghi", difficulty: 2, format: "short_answer", prompt: "Come si chiama il documento che serve per viaggiare all'estero?", answer: "passaporto", accept: ["il passaporto"], explanation: "Certifica chi sei davanti a uno stato che non è il tuo." },
    { topic: "viaggi-luoghi", difficulty: 2, format: "short_answer", prompt: "Come si chiama il foglio che ti dà diritto a salire su un treno?", answer: "biglietto", accept: ["il biglietto"], explanation: "Va convalidato prima di salire." },
    { topic: "viaggi-luoghi", difficulty: 2, format: "short_answer", prompt: "Come si chiama la borsa rigida in cui si mettono i vestiti per un viaggio?", answer: "valigia", accept: ["la valigia"], explanation: "Al plurale fa valigie: la i resta." },
    { topic: "viaggi-luoghi", difficulty: 3, format: "short_answer", prompt: "Come si chiama il percorso previsto di un viaggio, tappa per tappa?", answer: "itinerario", accept: ["l'itinerario"], explanation: "Si decide prima, ma si cambia strada facendo." },
    { topic: "corpo-salute", difficulty: 1, format: "short_answer", prompt: "Come si chiama il medico che cura i denti?", answer: "dentista", accept: ["il dentista", "odontoiatra"], explanation: "Odontoiatra è il nome tecnico." },
    { topic: "corpo-salute", difficulty: 1, format: "short_answer", prompt: "Come si chiama il luogo in cui si comprano le medicine?", answer: "farmacia", accept: ["la farmacia"], explanation: "Molte medicine richiedono la ricetta del medico." },
    { topic: "corpo-salute", difficulty: 2, format: "short_answer", prompt: "Come si chiama il foglio con cui il medico ti prescrive una medicina?", answer: "ricetta", accept: ["la ricetta"], explanation: "Senza, certe medicine non si possono comprare." },
    { topic: "corpo-salute", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'aumento della temperatura del corpo quando si è malati?", answer: "febbre", accept: ["la febbre"], explanation: "È una difesa: il corpo si scalda per combattere l'infezione." },
    { topic: "corpo-salute", difficulty: 2, format: "short_answer", prompt: "Come si chiama la visita in cui il medico ti controlla?", answer: "visita", accept: ["visita medica", "controllo"], explanation: "Il medico controlla anche quando non c'è niente che non va: si chiama visita di controllo, e serve proprio a non aspettare i sintomi." },
    { topic: "corpo-salute", difficulty: 3, format: "short_answer", prompt: "Come si chiama la sostanza che si inietta per rendere il corpo capace di difendersi da una malattia?", answer: "vaccino", accept: ["il vaccino"], explanation: "Insegna al corpo a riconoscere il nemico prima di incontrarlo." },
    { topic: "emozioni-relazioni", difficulty: 1, format: "short_answer", prompt: "Come si chiama il sentimento che provi quando qualcosa ti spaventa?", answer: "paura", accept: ["la paura"], explanation: "Serve: avvisa che qualcosa non va." },
    { topic: "emozioni-relazioni", difficulty: 2, format: "short_answer", prompt: "Come si chiama la capacità di capire quello che sente un altro?", answer: "empatia", explanation: "Non è essere d'accordo: è capire da dentro." },
    { topic: "emozioni-relazioni", difficulty: 2, format: "short_answer", prompt: "Come si chiama il sentimento di dispiacere per un torto che hai fatto?", answer: "rimorso", accept: ["il rimorso"], explanation: "Diverso dal rimpianto, che riguarda quello che non hai fatto." },
    { topic: "emozioni-relazioni", difficulty: 2, format: "short_answer", prompt: "Come si chiama il legame fra due persone che si vogliono bene e si fidano?", answer: "amicizia", accept: ["l'amicizia"], explanation: "Si costruisce nel tempo, non si dichiara." },
    { topic: "emozioni-relazioni", difficulty: 3, format: "short_answer", prompt: "Come si chiama la capacità di aspettare senza arrabbiarsi?", answer: "pazienza", accept: ["la pazienza"], explanation: "Serve soprattutto quando non arriva nessun risultato." },
    { topic: "emozioni-relazioni", difficulty: 3, format: "short_answer", prompt: "Come si chiama il gesto con cui si rinuncia a punire chi ci ha fatto un torto?", answer: "perdono", accept: ["il perdono"], explanation: "Non cancella il torto: scioglie il rancore." },
    { topic: "digitale-media", difficulty: 1, format: "short_answer", prompt: "Come si chiama la parola segreta che protegge un account?", answer: "password", accept: ["la password", "parola d'ordine"], explanation: "Non si condivide, nemmeno con gli amici." },
    { topic: "digitale-media", difficulty: 2, format: "short_answer", prompt: "Come si chiama il messaggio ingannevole che cerca di rubarti le credenziali?", answer: "phishing", accept: ["il phishing"], explanation: "Finge di essere la banca o la scuola: pesca con l'esca." },
    { topic: "digitale-media", difficulty: 2, format: "short_answer", prompt: "Come si chiama il programma che naviga fra i siti internet?", answer: "browser", accept: ["il browser"], explanation: "Chiede la pagina al server e la mostra." },
    { topic: "digitale-media", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'indirizzo che identifica una pagina web?", answer: "URL", accept: ["url", "indirizzo web"], explanation: "È l'indirizzo esatto della risorsa, non solo del sito." },
    { topic: "digitale-media", difficulty: 3, format: "short_answer", prompt: "Come si chiama la copia di sicurezza dei propri dati?", answer: "backup", accept: ["il backup", "copia di sicurezza"], explanation: "Un file esiste davvero solo se ne esistono due copie." },
    { topic: "digitale-media", difficulty: 3, format: "short_answer", prompt: "Come si chiama il comportamento aggressivo ripetuto contro qualcuno online?", answer: "cyberbullismo", accept: ["il cyberbullismo"], explanation: "Si combatte segnalando e salvando le prove, non rispondendo." },
    { topic: "lavoro-comunita", difficulty: 1, format: "short_answer", prompt: "Come si chiama chi guida un autobus?", answer: "autista", accept: ["l'autista", "conducente"], explanation: "Dal francese: chi conduce il mezzo." },
    { topic: "lavoro-comunita", difficulty: 1, format: "short_answer", prompt: "Come si chiama chi spegne gli incendi?", answer: "pompiere", accept: ["vigile del fuoco", "il pompiere"], explanation: "Vigile del fuoco è il nome ufficiale." },
    { topic: "lavoro-comunita", difficulty: 2, format: "short_answer", prompt: "Come si chiama chi è a capo di un comune?", answer: "sindaco", accept: ["il sindaco"], explanation: "Lo eleggono i cittadini del comune." },
    { topic: "lavoro-comunita", difficulty: 2, format: "short_answer", prompt: "Come si chiama il denaro che si versa allo stato per pagare i servizi pubblici?", answer: "tasse", accept: ["le tasse", "imposte"], explanation: "Con quelle si pagano scuola, ospedali e strade." },
    { topic: "lavoro-comunita", difficulty: 3, format: "short_answer", prompt: "Come si chiama il lavoro fatto gratuitamente per gli altri?", answer: "volontariato", accept: ["il volontariato"], explanation: "Nessun compenso, e proprio per questo vale." },
    { topic: "sport-tempo-libero", difficulty: 1, format: "short_answer", prompt: "Come si chiama chi fa rispettare le regole durante una partita?", answer: "arbitro", accept: ["l'arbitro"], explanation: "Le sue decisioni si discutono dopo, non durante." },
    { topic: "sport-tempo-libero", difficulty: 1, format: "short_answer", prompt: "Come si chiama lo sport che si gioca in cinque per squadra con un canestro?", answer: "pallacanestro", accept: ["basket", "la pallacanestro"], explanation: "Basket è il nome inglese." },
    { topic: "sport-tempo-libero", difficulty: 2, format: "short_answer", prompt: "Come si chiama la sessione in cui si prova e si migliora prima della gara?", answer: "allenamento", accept: ["l'allenamento"], explanation: "Il risultato si costruisce lì, non il giorno della gara." },
    { topic: "sport-tempo-libero", difficulty: 2, format: "short_answer", prompt: "Come si chiama chi guida e prepara una squadra?", answer: "allenatore", accept: ["l'allenatore"], explanation: "Sceglie la formazione e la strategia." },
    { topic: "sport-tempo-libero", difficulty: 3, format: "short_answer", prompt: "Come si chiama il risultato di una partita finita in parità?", answer: "pareggio", accept: ["il pareggio"], explanation: "Nessuna delle due squadre vince." },
    { topic: "natura-ambiente", difficulty: 1, format: "short_answer", prompt: "Come si chiama un grande bosco fitto di alberi?", answer: "foresta", accept: ["la foresta"], explanation: "Più estesa e fitta di un bosco." },
    { topic: "natura-ambiente", difficulty: 2, format: "short_answer", prompt: "Come si chiama la separazione dei rifiuti per tipo di materiale?", answer: "raccolta differenziata", accept: ["differenziata"], explanation: "Senza separare, riciclare è quasi impossibile." },
    { topic: "natura-ambiente", difficulty: 2, format: "short_answer", prompt: "Come si chiama l'aumento della temperatura media del pianeta?", answer: "riscaldamento globale", accept: ["riscaldamento"], explanation: "Lo causano soprattutto i gas serra prodotti bruciando combustibili." },
    { topic: "natura-ambiente", difficulty: 3, format: "short_answer", prompt: "Come si chiama la varietà di specie viventi in un ambiente?", answer: "biodiversità", accept: ["biodiversita", "la biodiversità"], explanation: "Più è alta, più l'ambiente regge gli imprevisti." },
    { topic: "natura-ambiente", difficulty: 3, format: "short_answer", prompt: "Come si chiama il taglio massiccio degli alberi di una foresta?", answer: "deforestazione", accept: ["la deforestazione"], explanation: "Toglie insieme ossigeno, suolo e habitat." },
  ],
  "inglese": [
    { difficulty: 4, topic: "false-friends", prompt: "Che cosa significa «actually»?", answer: "In realtà",
      distractors: ["Attualmente", "Con attenzione", "In azione"],
      explanation: "Falso amico classico: «attualmente» si dice currently." },
    { difficulty: 4, topic: "false-friends", prompt: "Che cosa significa «library»?", answer: "Biblioteca",
      distractors: ["Libreria, il negozio di libri", "Libretto", "Libertà"],
      explanation: "La libreria dove si comprano i libri è bookshop." },
    { difficulty: 4, topic: "false-friends", prompt: "Che cosa significa «sensible»?", answer: "Ragionevole, di buon senso",
      distractors: ["Sensibile ai sentimenti", "Percepibile", "Delicato"],
      explanation: "«Sensibile» nel senso delle emozioni si dice sensitive." },
    { difficulty: 4, topic: "false-friends", prompt: "Che cosa significa «eventually»?", answer: "Alla fine, prima o poi",
      distractors: ["Eventualmente, forse", "Improvvisamente", "Regolarmente"],
      explanation: "«Eventualmente» si dice possibly: eventually indica che alla fine succede davvero." },
    { difficulty: 4, topic: "connectors", prompt: "Quando si usa «since» al posto di «for»?", answer: "Quando si indica il momento di inizio",
      distractors: ["Quando si indica quanto è durato", "Quando la frase è negativa", "Quando si parla del futuro"],
      explanation: "for + durata (for three years), since + momento (since 2020)." },
    { difficulty: 4, topic: "connectors", prompt: "Che cosa significa «however»?", answer: "Tuttavia",
      distractors: ["Inoltre", "Perciò", "Comunque vada"],
      explanation: "however introduce un contrasto con quanto appena detto, come «tuttavia»." },
    { difficulty: 4, topic: "digital-media", prompt: "Che cosa significa «to download»?", answer: "Scaricare",
      distractors: ["Caricare", "Cancellare", "Condividere"],
      explanation: "upload è caricare verso la rete, download è scaricare da essa." },
    { difficulty: 4, topic: "school-communication", prompt: "Che cosa significa «deadline»?", answer: "La scadenza entro cui consegnare",
      distractors: ["La linea di fondo del campo", "Una riga cancellata", "La fine della lezione"],
      explanation: "Oltre la deadline il lavoro è in ritardo: è il termine ultimo." },
  ],
};

for (const [subject, extra] of Object.entries(BAND_EXTRA)) {
  const bank = BANKS[`${subject}-base`];
  const rand = rng(20260803);
  extra.forEach((q, index) => {
    const id = `${subject}-banda-${q.topic}-${index}`;
    // Anche qui la risposta libera: senza, un item con `format: "numeric_input"`
    // arriverebbe a `multipleChoiceItem` senza distrattori e romperebbe il bake.
    if (q.format === "short_answer") {
      // Risposta libera a testo. `accept` elenca le forme che valgono quanto
      // la risposta principale: senza, un bambino che scrive «to check»
      // invece di «check» viene segnato sbagliato pur avendo capito.
      bank.items.push({
        id,
        subject,
        topic: q.topic,
        difficulty: q.difficulty,
        format: "short_answer",
        prompt: q.prompt,
        options: [],
        answer: String(q.answer),
        accept: q.accept ?? [],
        explanation: q.explanation,
      });
      return;
    }
    if (q.format === "numeric_input") {
      bank.items.push({
        id,
        subject,
        topic: q.topic,
        difficulty: q.difficulty,
        format: "numeric_input",
        prompt: q.prompt,
        options: [],
        answer: String(q.answer),
        explanation: q.explanation,
      });
      return;
    }
    bank.items.push(
      multipleChoiceItem(
        {
          id,
          subject,
          topic: q.topic,
          difficulty: q.difficulty,
          prompt: q.prompt,
          answer: q.answer,
          distractors: q.distractors,
          explanation: q.explanation,
        },
        rand,
      ),
    );
  });
}

const QUOTA_RISPOSTA_LIBERA = 0.3;

// --- Risposta libera: conversione dei quesiti a risposta di parola ----------
//
// Solo domande la cui formulazione determina UNA risposta sola. «Come si dice
// in inglese: controllare?» ha una risposta e basta; «Quale parola corrisponde
// a famiglia?» ne ha dieci, e senza le opzioni sarebbe una trappola: la
// risposta libera deve misurare quello che il bambino sa, non indovinare la
// parola che avevo in mente io.
const PROMPT_A_PAROLA = {
  inglese: [/^Come si dice in inglese/i, /^Cosa significa in italiano/i],
  latino: [
    /^Qual è il nominativo plurale di/i, /^Qual è il genitivo singolare di/i,
    /^Qual è l.accusativo/i, /^Qual è il dativo/i, /^Qual è l.ablativo/i,
  ],
  italiano: [/^Come si scrive il plurale di/i],
};

for (const [name, bank] of Object.entries(BANKS)) {
  const materia = name.split("-")[0];
  const schemi = PROMPT_A_PAROLA[materia];
  if (!schemi) continue;
  const totale = bank.items.length;
  const gia = bank.items.filter((i) => i.format !== "multiple_choice").length;
  let mancanti = Math.floor(totale * QUOTA_RISPOSTA_LIBERA) - gia;
  if (mancanti <= 0) continue;
  const candidati = bank.items
    .filter((i) =>
      i.format === "multiple_choice" &&
      schemi.some((r) => r.test(i.prompt)) &&
      !/\s/.test(String(i.answer).trim()) &&
      String(i.answer).length <= 20)
    .sort((a, b) => String(a.id).localeCompare(String(b.id)));
  if (!candidati.length) continue;
  const passo = Math.max(1, Math.floor(candidati.length / mancanti));
  for (let k = 0; k < candidati.length && mancanti > 0; k += passo) {
    const item = candidati[k];
    item.format = "short_answer";
    // L'infinito inglese si scrive in due modi: valgono entrambi.
    if (materia === "inglese" && /^Come si dice in inglese/i.test(item.prompt)) {
      item.accept = ["to " + item.answer];
    }
    item.options = [];
    mancanti--;
  }
}

// --- Risposta libera: conversione dei quesiti a risposta numerica ------------
//
// Decisione vincolante del 3 agosto: ogni banco al 20-30% di risposta NON a
// scelta multipla. Una domanda a quattro opzioni si risolve per esclusione
// senza sapere niente; scrivere il numero no.
//
// Non serve riscrivere gli item: quelli la cui risposta e' gia' un numero
// diventano `numeric_input` togliendo le opzioni. La scelta e' deterministica
// (ordinamento per id e passo costante), cosi' due bake danno lo stesso banco.
const NUMERICA = /^-?\d+([.,]\d+)?$/;

for (const [name, bank] of Object.entries(BANKS)) {
  const totale = bank.items.length;
  const gia = bank.items.filter((i) => i.format !== "multiple_choice").length;
  const bersaglio = Math.floor(totale * QUOTA_RISPOSTA_LIBERA);
  let mancanti = bersaglio - gia;
  if (mancanti <= 0) continue;
  const candidati = bank.items
    .filter((i) => i.format === "multiple_choice" && NUMERICA.test(String(i.answer).trim()))
    .sort((a, b) => String(a.id).localeCompare(String(b.id)));
  if (!candidati.length) continue;
  // Passo costante sull'elenco ordinato: se i candidati sono piu' del
  // necessario si prendono distribuiti, non i primi in fila — cosi' non si
  // svuota di scelta multipla un solo argomento.
  const passo = Math.max(1, Math.floor(candidati.length / mancanti));
  for (let k = 0; k < candidati.length && mancanti > 0; k += passo) {
    const item = candidati[k];
    item.format = "numeric_input";
    item.options = [];
    mancanti--;
  }
}

await mkdir(outDir, { recursive: true });
for (const [name, bank] of Object.entries(BANKS)) {
  validate(name, bank);
  const file = join(outDir, `${name}.json`);
  await writeFile(file, JSON.stringify(bank, null, "\t") + "\n", "utf8");
  console.log(`Banco '${name}': ${bank.items.length} item → ${file}`);
}
