// Grafo dei prerequisiti tra concetti (DAG). "A → [B, C]" significa: per capire A
// conviene aver già incontrato B e C. Serve a due cose:
//  1) un test di coerenza (il grafo è aciclico, i riferimenti esistono, e un
//     prerequisito si incontra a una profondità ≤ del concetto che lo usa);
//  2) mostrare allo studente "su cosa si appoggia" un concetto nuovo.
// Nota: qui contano i prerequisiti del PRIMO incontro. Per esempio le frazioni,
// come operatore ("1/2 di 10"), servono solo divisione; l'mcm entra in gioco più
// avanti, con la somma tra frazioni — perciò non è un prerequisito d'ingresso.
export const topicPrerequisites: Record<string, string[]> = {
  // Numeri
  "numeri-naturali": [],
  "potenze-espressioni": ["numeri-naturali"],
  divisibilita: ["numeri-naturali"],
  frazioni: ["numeri-naturali"],
  decimali: ["numeri-naturali"],
  "radice-quadrata": ["potenze-espressioni"],
  "numeri-relativi": ["numeri-naturali"],
  "rapporti-proporzioni": ["frazioni"],
  percentuali: ["frazioni"],
  proporzionalita: ["rapporti-proporzioni"],
  misure: ["numeri-naturali"],
  // Geometria
  "angoli-rette": [],
  triangoli: ["angoli-rette"],
  quadrilateri: ["angoli-rette"],
  pitagora: ["triangoli", "radice-quadrata", "potenze-espressioni"],
  cerchio: ["quadrilateri"],
  similitudine: ["rapporti-proporzioni", "triangoli"],
  solidi: ["quadrilateri"],
  "piano-cartesiano": ["numeri-naturali"],
  // Relazioni e funzioni
  "calcolo-letterale": ["potenze-espressioni"],
  equazioni: ["calcolo-letterale"],
  "funzioni-retta": ["piano-cartesiano", "equazioni"],
  // Dati e previsioni
  statistica: ["decimali"],
  probabilita: ["frazioni"],
  // Italiano (verbi)
  "verbi-mappa-modi-tempi": [],
  "indicativo-tempi": ["verbi-mappa-modi-tempi"],
  "congiuntivo-condizionale": ["indicativo-tempi"],
  "imperativo-infinito-participio-gerundio": ["verbi-mappa-modi-tempi"],
  "concordanza-tempi-verbali": ["congiuntivo-condizionale", "indicativo-tempi"],
};
