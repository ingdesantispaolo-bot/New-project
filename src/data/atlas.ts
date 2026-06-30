// Types + shared geometry for Mission 5 — "L'Atlante Perduto" (Stagione 2, Atto V).
// The concrete puzzle is generated procedurally (see AtlasGenerator); this file
// only holds the stable contract the scene and the generator agree on.

export type Cardinal = "N" | "NE" | "E" | "SE" | "S" | "SW" | "W" | "NW";

export const atlasGrid = { cols: 10, rows: 8 };

/** Screen unit vectors per cardinal (y grows downward, like the grid rows). */
export const DIRECTION_VECTORS: Record<Cardinal, { dx: number; dy: number }> = {
  N: { dx: 0, dy: -1 },
  NE: { dx: 1, dy: -1 },
  E: { dx: 1, dy: 0 },
  SE: { dx: 1, dy: 1 },
  S: { dx: 0, dy: 1 },
  SW: { dx: -1, dy: 1 },
  W: { dx: -1, dy: 0 },
  NW: { dx: -1, dy: -1 },
};

/** Opposite (collinear) directions — never used together, to keep bearings distinct. */
export const OPPOSITE: Record<Cardinal, Cardinal> = {
  N: "S", S: "N", E: "W", W: "E", NE: "SW", SW: "NE", NW: "SE", SE: "NW",
};

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

/** Compact compass labels used on the 8-way selector (Italian). */
export const compassLabels: Record<Cardinal, string> = {
  N: "N", NE: "NE", E: "E", SE: "SE", S: "S", SW: "SO", W: "O", NW: "NO",
};

export type AtlasBearing = {
  id: string;
  station: string;
  /** Short English radio transmission the player must understand. */
  radioEnglish: string;
  /** Italian gloss revealed as a hint after a wrong attempt. */
  italianGloss: string;
  answer: Cardinal;
};

export type AtlasCoordinate = {
  id: string;
  station: string;
  x: number;
  y: number;
  clue: string;
};

export type AtlasScaleProblem = {
  prompt: string;
  fromLabel: string;
  toLabel: string;
  gridDistance: number;
  kmPerCell: number;
  answerKm: number;
  hint: string;
};

/** One procedurally generated, fully solvable Atlas puzzle. */
export type AtlasVariant = {
  grid: { cols: number; rows: number };
  source: { x: number; y: number };
  bearings: AtlasBearing[];
  coordinates: AtlasCoordinate[];
  scale: AtlasScaleProblem;
};
