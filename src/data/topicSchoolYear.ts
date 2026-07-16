import type { SchoolYear } from "../core/schoolLevel";

// Anno di scuola media in cui il concetto viene tipicamente introdotto nel
// curricolo italiano. Serve a taggare le schede e a tenere un profilo giovane
// nella sua fascia di profondità (vedi maxDifficultyForSchoolYear).
export const topicSchoolYear: Record<string, SchoolYear> = {
  // Numeri
  "numeri-naturali": 1,
  "potenze-espressioni": 1,
  divisibilita: 1,
  frazioni: 1,
  decimali: 1,
  misure: 1,
  "radice-quadrata": 2,
  "rapporti-proporzioni": 2,
  percentuali: 2,
  proporzionalita: 2,
  "numeri-relativi": 3,
  // Geometria
  "angoli-rette": 1,
  triangoli: 1,
  quadrilateri: 1,
  "piano-cartesiano": 2,
  pitagora: 2,
  cerchio: 2,
  similitudine: 2,
  solidi: 3,
  // Relazioni e funzioni
  "calcolo-letterale": 3,
  equazioni: 3,
  "funzioni-retta": 3,
  // Dati e previsioni
  statistica: 1,
  probabilita: 3,
  // Italiano (verbi)
  "verbi-mappa-modi-tempi": 1,
  "indicativo-tempi": 1,
  "congiuntivo-condizionale": 2,
  "imperativo-infinito-participio-gerundio": 2,
  "concordanza-tempi-verbali": 3,
};
