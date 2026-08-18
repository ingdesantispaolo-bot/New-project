// Curriculum di Latino per il biennio del liceo scientifico (1°-2° anno).
// Le forme sono senza macron (convenzione scolastica italiana). La correttezza
// è garantita da desinenze-per-declinazione + radice, con nominativo singolare
// esplicito per la 3ª declinazione (nom. irregolare). tier 1 = primo anno,
// tier 2 = secondo anno.

export type LatinTier = 1 | 2;
export type LatinCase = "nominativo" | "genitivo" | "dativo" | "accusativo" | "ablativo" | "vocativo";
export type LatinNumber = "singolare" | "plurale";
export const LATIN_CASES: LatinCase[] = ["nominativo", "genitivo", "dativo", "accusativo", "ablativo", "vocativo"];

/** Chiave di paradigma: declinazione (+ genere per 2ª/3ª). */
type DeclType = "1" | "2m" | "2n" | "3m" | "3n" | "4" | "5";

// Desinenze in ordine [nom, gen, dat, acc, abl, voc]. `null` = usa il nom. sg.
const ENDINGS: Record<DeclType, { sg: (string | null)[]; pl: string[] }> = {
  "1": { sg: ["a", "ae", "ae", "am", "a", "a"], pl: ["ae", "arum", "is", "as", "is", "ae"] },
  "2m": { sg: ["us", "i", "o", "um", "o", "e"], pl: ["i", "orum", "is", "os", "is", "i"] },
  "2n": { sg: ["um", "i", "o", "um", "o", "um"], pl: ["a", "orum", "is", "a", "is", "a"] },
  "3m": { sg: [null, "is", "i", "em", "e", null], pl: ["es", "um", "ibus", "es", "ibus", "es"] },
  "3n": { sg: [null, "is", "i", null, "e", null], pl: ["a", "um", "ibus", "a", "ibus", "a"] },
  "4": { sg: ["us", "us", "ui", "um", "u", "us"], pl: ["us", "uum", "ibus", "us", "ibus", "us"] },
  "5": { sg: ["es", "ei", "ei", "em", "e", "es"], pl: ["es", "erum", "ebus", "es", "ebus", "es"] },
};

export type LatinNoun = {
  nomSg: string;
  /** Radice a cui si aggiungono le desinenze (per la 3ª = genitivo meno -is). */
  stem: string;
  type: DeclType;
  gender: "m" | "f" | "n";
  it: string;
  tier: LatinTier;
};

export const latinNouns: LatinNoun[] = [
  // 1ª declinazione (tema in -a)
  { nomSg: "rosa", stem: "ros", type: "1", gender: "f", it: "la rosa", tier: 1 },
  { nomSg: "puella", stem: "puell", type: "1", gender: "f", it: "la fanciulla", tier: 1 },
  { nomSg: "aqua", stem: "aqu", type: "1", gender: "f", it: "l'acqua", tier: 1 },
  { nomSg: "terra", stem: "terr", type: "1", gender: "f", it: "la terra", tier: 1 },
  { nomSg: "patria", stem: "patri", type: "1", gender: "f", it: "la patria", tier: 1 },
  { nomSg: "silva", stem: "silv", type: "1", gender: "f", it: "il bosco", tier: 1 },
  // 2ª maschile (-us)
  { nomSg: "dominus", stem: "domin", type: "2m", gender: "m", it: "il signore/padrone", tier: 1 },
  { nomSg: "servus", stem: "serv", type: "2m", gender: "m", it: "lo schiavo", tier: 1 },
  { nomSg: "amicus", stem: "amic", type: "2m", gender: "m", it: "l'amico", tier: 1 },
  { nomSg: "populus", stem: "popul", type: "2m", gender: "m", it: "il popolo", tier: 1 },
  // 2ª neutro (-um)
  { nomSg: "bellum", stem: "bell", type: "2n", gender: "n", it: "la guerra", tier: 1 },
  { nomSg: "templum", stem: "templ", type: "2n", gender: "n", it: "il tempio", tier: 1 },
  { nomSg: "donum", stem: "don", type: "2n", gender: "n", it: "il dono", tier: 1 },
  // 3ª maschile/femminile (tema consonantico)
  { nomSg: "rex", stem: "reg", type: "3m", gender: "m", it: "il re", tier: 1 },
  { nomSg: "consul", stem: "consul", type: "3m", gender: "m", it: "il console", tier: 1 },
  { nomSg: "miles", stem: "milit", type: "3m", gender: "m", it: "il soldato", tier: 1 },
  { nomSg: "virtus", stem: "virtut", type: "3m", gender: "f", it: "la virtù", tier: 2 },
  { nomSg: "lex", stem: "leg", type: "3m", gender: "f", it: "la legge", tier: 2 },
  // 3ª neutro
  { nomSg: "corpus", stem: "corpor", type: "3n", gender: "n", it: "il corpo", tier: 2 },
  { nomSg: "tempus", stem: "tempor", type: "3n", gender: "n", it: "il tempo", tier: 2 },
  // 4ª (-us)
  { nomSg: "manus", stem: "man", type: "4", gender: "f", it: "la mano", tier: 2 },
  { nomSg: "exercitus", stem: "exercit", type: "4", gender: "m", it: "l'esercito", tier: 2 },
  // 5ª (-es)
  { nomSg: "res", stem: "r", type: "5", gender: "f", it: "la cosa", tier: 2 },
  { nomSg: "dies", stem: "di", type: "5", gender: "m", it: "il giorno", tier: 2 },
];

const CASE_INDEX: Record<LatinCase, number> = { nominativo: 0, genitivo: 1, dativo: 2, accusativo: 3, ablativo: 4, vocativo: 5 };

/** Forma corretta di un sostantivo per caso e numero. */
export function latinNounForm(noun: LatinNoun, kase: LatinCase, number: LatinNumber): string {
  const index = CASE_INDEX[kase];
  if (number === "plurale") return noun.stem + ENDINGS[noun.type].pl[index];
  const ending = ENDINGS[noun.type].sg[index];
  return ending === null ? noun.nomSg : noun.stem + ending;
}

/**
 * Casi "distintivi" per un tipo: forme non ambigue (evitiamo il nom./abl.
 * singolare della 1ª, i pareggi nom./acc. dei neutri, ecc.) così le domande
 * "che caso è?" hanno una sola risposta corretta.
 */
export function distinctiveCases(noun: LatinNoun): Array<{ kase: LatinCase; number: LatinNumber }> {
  const all: Array<{ kase: LatinCase; number: LatinNumber }> = [];
  for (const number of ["singolare", "plurale"] as LatinNumber[]) {
    for (const kase of LATIN_CASES) {
      if (kase === "vocativo") continue; // spesso uguale al nominativo
      all.push({ kase, number });
    }
  }
  // Escludi forme che collidono con un'altra forma dello stesso sostantivo.
  return all.filter(({ kase, number }) => {
    const form = latinNounForm(noun, kase, number);
    const clashes = all.some((other) =>
      (other.kase !== kase || other.number !== number) && latinNounForm(noun, other.kase, other.number) === form);
    return !clashes;
  });
}

// ---- Aggettivi (concordanza) ----
export type LatinAdjective = {
  base: string; // maschile nom. sg.
  it: string;
  clazz: "1-2" | "3";
  tier: LatinTier;
};
export const latinAdjectives: LatinAdjective[] = [
  { base: "bonus", it: "buono", clazz: "1-2", tier: 1 },
  { base: "magnus", it: "grande", clazz: "1-2", tier: 1 },
  { base: "altus", it: "alto/profondo", clazz: "1-2", tier: 1 },
  { base: "malus", it: "cattivo", clazz: "1-2", tier: 1 },
  { base: "fortis", it: "forte/coraggioso", clazz: "3", tier: 2 },
  { base: "omnis", it: "ogni/tutto", clazz: "3", tier: 2 },
];

/** Forma dell'aggettivo di 1ª-2ª classe (bonus, -a, -um) per genere/caso/numero. */
export function latinAdjective12(base: string, gender: "m" | "f" | "n", kase: LatinCase, number: LatinNumber): string {
  const stem = base.replace(/us$/, "");
  const type: DeclType = gender === "m" ? "2m" : gender === "f" ? "1" : "2n";
  const index = CASE_INDEX[kase];
  if (number === "plurale") return stem + ENDINGS[type].pl[index];
  const ending = ENDINGS[type].sg[index];
  return ending === null ? base : stem + ending;
}

// ---- Verbi (paradigmi precalcolati per correttezza) ----
export type LatinTense = "presente" | "imperfetto" | "futuro" | "perfetto" | "congiuntivo-presente" | "presente-passivo";
export const LATIN_PERSONS = ["io", "tu", "egli/ella", "noi", "voi", "essi/esse"] as const;

export type LatinVerb = {
  lemma: string;      // 1ª pers. sg. presente (voce di paradigma)
  conjugation: 1 | 2 | 3 | 4 | 0; // 0 = sum (irregolare)
  it: string;
  tiers: Partial<Record<LatinTense, LatinTier>>;
  forms: Partial<Record<LatinTense, [string, string, string, string, string, string]>>;
};

export const latinVerbs: LatinVerb[] = [
  {
    lemma: "amo", conjugation: 1, it: "amare",
    tiers: { presente: 1, imperfetto: 1, futuro: 1, perfetto: 2, "presente-passivo": 2, "congiuntivo-presente": 2 },
    forms: {
      presente: ["amo", "amas", "amat", "amamus", "amatis", "amant"],
      imperfetto: ["amabam", "amabas", "amabat", "amabamus", "amabatis", "amabant"],
      futuro: ["amabo", "amabis", "amabit", "amabimus", "amabitis", "amabunt"],
      perfetto: ["amavi", "amavisti", "amavit", "amavimus", "amavistis", "amaverunt"],
      "presente-passivo": ["amor", "amaris", "amatur", "amamur", "amamini", "amantur"],
      "congiuntivo-presente": ["amem", "ames", "amet", "amemus", "ametis", "ament"],
    },
  },
  {
    lemma: "moneo", conjugation: 2, it: "avvisare",
    tiers: { presente: 1, imperfetto: 1, futuro: 1, perfetto: 2, "presente-passivo": 2, "congiuntivo-presente": 2 },
    forms: {
      presente: ["moneo", "mones", "monet", "monemus", "monetis", "monent"],
      imperfetto: ["monebam", "monebas", "monebat", "monebamus", "monebatis", "monebant"],
      futuro: ["monebo", "monebis", "monebit", "monebimus", "monebitis", "monebunt"],
      perfetto: ["monui", "monuisti", "monuit", "monuimus", "monuistis", "monuerunt"],
      "presente-passivo": ["moneor", "moneris", "monetur", "monemur", "monemini", "monentur"],
      "congiuntivo-presente": ["moneam", "moneas", "moneat", "moneamus", "moneatis", "moneant"],
    },
  },
  {
    lemma: "rego", conjugation: 3, it: "governare",
    tiers: { presente: 1, imperfetto: 1, futuro: 1, perfetto: 2, "presente-passivo": 2, "congiuntivo-presente": 2 },
    forms: {
      presente: ["rego", "regis", "regit", "regimus", "regitis", "regunt"],
      imperfetto: ["regebam", "regebas", "regebat", "regebamus", "regebatis", "regebant"],
      futuro: ["regam", "reges", "reget", "regemus", "regetis", "regent"],
      perfetto: ["rexi", "rexisti", "rexit", "reximus", "rexistis", "rexerunt"],
      "presente-passivo": ["regor", "regeris", "regitur", "regimur", "regimini", "reguntur"],
      "congiuntivo-presente": ["regam", "regas", "regat", "regamus", "regatis", "regant"],
    },
  },
  {
    lemma: "audio", conjugation: 4, it: "ascoltare",
    tiers: { presente: 1, imperfetto: 1, futuro: 1, perfetto: 2, "presente-passivo": 2, "congiuntivo-presente": 2 },
    forms: {
      presente: ["audio", "audis", "audit", "audimus", "auditis", "audiunt"],
      imperfetto: ["audiebam", "audiebas", "audiebat", "audiebamus", "audiebatis", "audiebant"],
      futuro: ["audiam", "audies", "audiet", "audiemus", "audietis", "audient"],
      perfetto: ["audivi", "audivisti", "audivit", "audivimus", "audivistis", "audiverunt"],
      "presente-passivo": ["audior", "audiris", "auditur", "audimur", "audimini", "audiuntur"],
      "congiuntivo-presente": ["audiam", "audias", "audiat", "audiamus", "audiatis", "audiant"],
    },
  },
  {
    lemma: "sum", conjugation: 0, it: "essere",
    tiers: { presente: 1, imperfetto: 1, futuro: 1, perfetto: 2, "congiuntivo-presente": 2 },
    forms: {
      presente: ["sum", "es", "est", "sumus", "estis", "sunt"],
      imperfetto: ["eram", "eras", "erat", "eramus", "eratis", "erant"],
      futuro: ["ero", "eris", "erit", "erimus", "eritis", "erunt"],
      perfetto: ["fui", "fuisti", "fuit", "fuimus", "fuistis", "fuerunt"],
      "congiuntivo-presente": ["sim", "sis", "sit", "simus", "sitis", "sint"],
    },
  },
];

// ---- Lessico ad alta frequenza ----
export type LatinWord = { la: string; it: string; tier: LatinTier };
export const latinVocab: LatinWord[] = [
  { la: "puer", it: "il bambino/ragazzo", tier: 1 },
  { la: "vir", it: "l'uomo", tier: 1 },
  { la: "femina", it: "la donna", tier: 1 },
  { la: "deus", it: "il dio", tier: 1 },
  { la: "vita", it: "la vita", tier: 1 },
  { la: "aqua", it: "l'acqua", tier: 1 },
  { la: "magnus", it: "grande", tier: 1 },
  { la: "parvus", it: "piccolo", tier: 1 },
  { la: "bonus", it: "buono", tier: 1 },
  { la: "video", it: "vedere", tier: 1 },
  { la: "amo", it: "amare", tier: 1 },
  { la: "laudo", it: "lodare", tier: 1 },
  { la: "porto", it: "portare", tier: 1 },
  { la: "et", it: "e", tier: 1 },
  { la: "non", it: "non", tier: 1 },
  { la: "sed", it: "ma", tier: 1 },
  { la: "cum", it: "con", tier: 1 },
  { la: "in", it: "in/su", tier: 1 },
  { la: "ad", it: "verso/presso", tier: 1 },
  { la: "bellum", it: "la guerra", tier: 1 },
  { la: "hostis", it: "il nemico", tier: 2 },
  { la: "urbs", it: "la città", tier: 2 },
  { la: "civis", it: "il cittadino", tier: 2 },
  { la: "virtus", it: "il valore/la virtù", tier: 2 },
  { la: "libertas", it: "la libertà", tier: 2 },
  { la: "quod", it: "poiché/perché", tier: 2 },
  { la: "ut", it: "affinché/che", tier: 2 },
  { la: "dum", it: "mentre", tier: 2 },
];

// ---- Funzioni dei casi (complementi) ----
export type LatinCaseFunction = {
  kase: LatinCase;
  funzione: string;      // etichetta del complemento
  domanda: string;       // a che domanda risponde
  tier: LatinTier;
};
export const latinCaseFunctions: LatinCaseFunction[] = [
  { kase: "nominativo", funzione: "soggetto", domanda: "chi/che cosa compie l'azione?", tier: 1 },
  { kase: "genitivo", funzione: "complemento di specificazione", domanda: "di chi? di che cosa?", tier: 1 },
  { kase: "dativo", funzione: "complemento di termine", domanda: "a chi? a che cosa?", tier: 1 },
  { kase: "accusativo", funzione: "complemento oggetto", domanda: "chi? che cosa? (oggetto diretto)", tier: 1 },
  { kase: "ablativo", funzione: "complemento di mezzo/modo/causa", domanda: "con che cosa? in che modo?", tier: 1 },
  { kase: "vocativo", funzione: "complemento di vocazione", domanda: "chi si chiama/interpella?", tier: 1 },
];

// ---- Sintassi del periodo (2° anno) ----
export type LatinClause = {
  la: string;        // esempio latino
  it: string;        // traduzione
  tipo: string;      // tipo di proposizione
  spia: string;      // parola-spia
};
export const latinClauses: LatinClause[] = [
  { la: "... ut patriam defenderent", it: "... affinché difendessero la patria", tipo: "finale", spia: "ut + congiuntivo" },
  { la: "... cum Roma caperetur", it: "... quando/poiché Roma veniva presa", tipo: "cum narrativo", spia: "cum + congiuntivo" },
  { la: "... quod hostes aderant", it: "... poiché i nemici erano presenti", tipo: "causale", spia: "quod + indicativo" },
  { la: "... dum milites pugnant", it: "... mentre i soldati combattono", tipo: "temporale", spia: "dum + indicativo" },
  { la: "urbe capta", it: "presa la città", tipo: "ablativo assoluto", spia: "participio + ablativo" },
  { la: "... se vincere posse", it: "... di poter vincere", tipo: "infinitiva", spia: "accusativo + infinito" },
];

// ---- Brevi frasi per la traduzione ----
export type LatinSentence = { la: string; it: string; tier: LatinTier; distrattori: string[] };
export const latinSentences: LatinSentence[] = [
  { la: "Puella rosam amat.", it: "La fanciulla ama la rosa.", tier: 1, distrattori: ["La rosa ama la fanciulla.", "La fanciulla vede la rosa.", "Le fanciulle amano le rose."] },
  { la: "Dominus servos vocat.", it: "Il padrone chiama gli schiavi.", tier: 1, distrattori: ["Gli schiavi chiamano il padrone.", "Il padrone chiama lo schiavo.", "Il padrone loda gli schiavi."] },
  { la: "Milites patriam defendunt.", it: "I soldati difendono la patria.", tier: 1, distrattori: ["Il soldato difende la patria.", "La patria difende i soldati.", "I soldati amano la patria."] },
  { la: "Poeta bellum narrat.", it: "Il poeta racconta la guerra.", tier: 1, distrattori: ["La guerra racconta il poeta.", "Il poeta ascolta la guerra.", "I poeti raccontano le guerre."] },
  { la: "Romani leges servant.", it: "I Romani osservano le leggi.", tier: 2, distrattori: ["La legge governa i Romani.", "I Romani scrivono le leggi.", "Il Romano osserva la legge."] },
  { la: "Consul urbem regebat.", it: "Il console governava la città.", tier: 2, distrattori: ["Il console governa la città.", "La città governava il console.", "I consoli governavano le città."] },
];

export function latinItemsForTier(maxTier: LatinTier) {
  return {
    nouns: latinNouns.filter((noun) => noun.tier <= maxTier),
    adjectives: latinAdjectives.filter((adjective) => adjective.tier <= maxTier),
    verbs: latinVerbs,
    vocab: latinVocab.filter((word) => word.tier <= maxTier),
    caseFunctions: latinCaseFunctions.filter((cf) => cf.tier <= maxTier),
    clauses: latinClauses,
    sentences: latinSentences.filter((sentence) => sentence.tier <= maxTier),
  };
}
