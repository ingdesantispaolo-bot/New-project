// Data for Mission 5 — "L'Atlante Perduto" (Stagione 2, Atto V).
// Eli triangulates the origin of an external signal using three listening
// stations: read each English radio bearing, plot the station coordinates,
// convert a map distance with the scale, then pick the cell where the three
// bearings converge. All numbers are authored to cross at the source cell.

export type Cardinal = "N" | "NE" | "E" | "SE" | "S" | "SW" | "W" | "NW";

export const atlasGrid = { cols: 10, rows: 8 };

/** The cell where the three bearings intersect — the signal source. */
export const atlasSourceCell = { x: 6, y: 6 };

export type AtlasBearing = {
  id: string;
  station: string;
  /** Short English radio transmission the player must understand. */
  radioEnglish: string;
  /** Italian gloss revealed as a hint after a wrong attempt. */
  italianGloss: string;
  answer: Cardinal;
  options: Cardinal[];
};

export const atlasBearings: AtlasBearing[] = [
  {
    id: "harbor",
    station: "Stazione Porto",
    radioEnglish: "Harbor station to Academy: the source lies to our south-east, beyond the bay.",
    italianGloss: "south-east = sud-est: in basso a destra rispetto alla stazione.",
    answer: "SE",
    options: ["SE", "NE", "SW", "S"],
  },
  {
    id: "ridge",
    station: "Stazione Cresta",
    radioEnglish: "Ridge station calling: the trace bears south-west from our tower.",
    italianGloss: "south-west = sud-ovest: in basso a sinistra rispetto alla stazione.",
    answer: "SW",
    options: ["SW", "SE", "NW", "W"],
  },
  {
    id: "bell",
    station: "Stazione Campana",
    radioEnglish: "Bell station here: the source is due south of us, straight down the line.",
    italianGloss: "due south = pieno sud: dritto verso il basso, stessa colonna.",
    answer: "S",
    options: ["S", "SE", "SW", "N"],
  },
];

export type AtlasCoordinate = {
  id: string;
  station: string;
  x: number;
  y: number;
  clue: string;
};

/** Where each listening station sits on the grid (player plots these). */
export const atlasCoordinates: AtlasCoordinate[] = [
  { id: "harbor", station: "Stazione Porto", x: 2, y: 2, clue: "Il Porto è registrato in (2, 2): seconda colonna, seconda riga." },
  { id: "ridge", station: "Stazione Cresta", x: 9, y: 3, clue: "La Cresta è in (9, 3): ultima colonna a destra, terza riga." },
  { id: "bell", station: "Stazione Campana", x: 6, y: 1, clue: "La Campana è in (6, 1): settima colonna, riga in alto." },
];

export type AtlasScaleProblem = {
  prompt: string;
  fromLabel: string;
  toLabel: string;
  gridDistance: number;
  kmPerCell: number;
  answerKm: number;
  options: number[];
  hint: string;
};

export const atlasScaleProblem: AtlasScaleProblem = {
  prompt: "Per raggiungere la sorgente devi sapere quanto è lontana davvero. Sull'atlante il Faro è in (2, 2) e il Porto Vecchio in (2, 6).",
  fromLabel: "Faro (2, 2)",
  toLabel: "Porto Vecchio (2, 6)",
  gridDistance: 4,
  kmPerCell: 15,
  answerKm: 60,
  options: [45, 60, 75, 90],
  hint: "Conta le celle lungo la colonna: da y=2 a y=6 sono 4 celle. Poi moltiplica per la scala (15 km a cella).",
};

export type AtlasSourceCandidate = {
  id: string;
  label: string;
  x: number;
  y: number;
  correct: boolean;
  reason: string;
};

/** Candidate origin cells: only the convergence of all three bearings is right. */
export const atlasSourceCandidates: AtlasSourceCandidate[] = [
  {
    id: "vega",
    label: "Avamposto Vega",
    x: 6,
    y: 6,
    correct: true,
    reason: "Sud-est dal Porto, sud-ovest dalla Cresta e pieno sud dalla Campana: tutte e tre le linee passano da qui.",
  },
  {
    id: "cardo",
    label: "Isola Cardo",
    x: 3,
    y: 6,
    correct: false,
    reason: "È a sud del Porto ma troppo a ovest: la Campana non punta lì e la Cresta nemmeno.",
  },
  {
    id: "cobalto",
    label: "Faro Cobalto",
    x: 6,
    y: 3,
    correct: false,
    reason: "È sulla colonna della Campana ma troppo in alto: dal Porto sarebbe quasi a est, non a sud-est.",
  },
  {
    id: "mauve",
    label: "Relitto Mauve",
    x: 9,
    y: 6,
    correct: false,
    reason: "È a sud-est da quasi tutto, ma dalla Cresta (9, 3) cadrebbe a pieno sud, non a sud-ovest.",
  },
];

export const cardinalLabels: Record<Cardinal, string> = {
  N: "Nord",
  NE: "Nord-Est",
  E: "Est",
  SE: "Sud-Est",
  S: "Sud",
  SW: "Sud-Ovest",
  W: "Ovest",
  NW: "Nord-Ovest",
};
