export type CompetencyDefinition = {
  id: string;
  label: string;
  description: string;
};

export const competencies: CompetencyDefinition[] = [
  {
    id: "matematica.calcolo",
    label: "Calcolo strategico",
    description: "Usare operazioni semplici dentro una situazione da risolvere.",
  },
  {
    id: "matematica.operazioni",
    label: "Proprieta delle operazioni",
    description: "Scegliere operazioni e ordine dei passaggi in base all'effetto previsto.",
  },
  {
    id: "matematica.logica",
    label: "Logica matematica",
    description: "Collegare condizioni, numeri e conseguenze.",
  },
  {
    id: "matematica.multipliDivisori",
    label: "Multipli e divisori",
    description: "Riconoscere quando un numero può attraversare filtri e divisioni senza resto.",
  },
  {
    id: "matematica.espressioni",
    label: "Prime espressioni",
    description: "Leggere una trasformazione composta rispettando l'ordine interno dei passaggi.",
  },
  {
    id: "matematica.controlloErrore",
    label: "Controllo dell'errore",
    description: "Usare vincoli e risultati intermedi per capire dove un percorso si rompe.",
  },
  {
    id: "matematica.grafici",
    label: "Lettura di grafici",
    description: "Interpretare andamenti semplici per capire se una scelta sta funzionando.",
  },
  {
    id: "matematica.frazioni",
    label: "Frazioni e rapporti",
    description: "Usare parti, rapporti e quote per interpretare risorse e misure.",
  },
  {
    id: "matematica.percentuali",
    label: "Percentuali",
    description: "Ragionare su aumenti, sconti, soglie e quote percentuali.",
  },
  {
    id: "matematica.geometria",
    label: "Geometria operativa",
    description: "Usare perimetri, aree, distanze e figure dentro problemi concreti.",
  },
  {
    id: "matematica.statistica",
    label: "Statistica semplice",
    description: "Leggere media, mediana, intervallo e dati anomali.",
  },
  {
    id: "matematica.probabilita",
    label: "Probabilita",
    description: "Stimare eventi possibili e usare rapporti per prevedere esiti.",
  },
  {
    id: "matematica.algebra",
    label: "Algebra iniziale",
    description: "Usare incognite, formule e relazioni per risalire a valori nascosti.",
  },
  {
    id: "matematica.funzioni",
    label: "Funzioni e modelli",
    description: "Leggere relazioni lineari e trasformazioni tra ingresso e uscita.",
  },
  {
    id: "matematica.potenzeRadici",
    label: "Potenze e radici",
    description: "Usare quadrati, potenze e radici in misure e codici.",
  },
  {
    id: "matematica.numeriRelativi",
    label: "Numeri relativi",
    description: "Usare valori positivi e negativi in variazioni, temperature e bilanci.",
  },
  {
    id: "matematica.proporzionalita",
    label: "Proporzionalita",
    description: "Riconoscere rapporti costanti, scale, velocita e trasformazioni proporzionali.",
  },
  {
    id: "matematica.misure",
    label: "Misure e unita",
    description: "Convertire e confrontare misure senza perdere il significato fisico.",
  },
  {
    id: "matematica.equazioni",
    label: "Equazioni e disequazioni",
    description: "Isolare incognite e trovare valori massimi o minimi compatibili con vincoli.",
  },
  {
    id: "matematica.geometria3D",
    label: "Geometria solida",
    description: "Usare volumi e dimensioni di solidi semplici in problemi concreti.",
  },
  {
    id: "coding.sequenze",
    label: "Sequenze di comandi",
    description: "Ordinare istruzioni per ottenere un comportamento previsto.",
  },
  {
    id: "coding.debugging",
    label: "Debugging",
    description: "Osservare un errore, capirne la causa e correggere.",
  },
  {
    id: "coding.orientamento",
    label: "Orientamento su griglia",
    description: "Tenere insieme posizione, direzione e rotazioni su una mappa.",
  },
  {
    id: "coding.decomposizione",
    label: "Decomposizione",
    description: "Dividere un problema di percorso in sotto-obiettivi verificabili.",
  },
  {
    id: "coding.efficienza",
    label: "Efficienza algoritmica",
    description: "Ridurre comandi inutili mantenendo il comportamento corretto.",
  },
  {
    id: "coding.testMentale",
    label: "Test mentale",
    description: "Simulare un programma prima di eseguirlo per prevenire errori.",
  },
  {
    id: "elettronica.circuitoChiuso",
    label: "Circuito chiuso",
    description: "Capire che la corrente ha bisogno di un percorso completo.",
  },
  {
    id: "italiano.comprensione",
    label: "Lettura di indizi",
    description: "Ricavare informazioni operative da testi brevi.",
  },
  {
    id: "italiano.grammatica",
    label: "Riparazione linguistica",
    description: "Riconoscere accordi e forme corrette in una frase.",
  },
  {
    id: "italiano.lessico",
    label: "Lessico in contesto",
    description: "Scegliere parole precise per distinguere oggetti, azioni e fonti.",
  },
  {
    id: "italiano.scritturaBreve",
    label: "Scrittura breve",
    description: "Sintetizzare informazioni utili in un rapporto chiaro e operativo.",
  },
  {
    id: "italiano.punteggiatura",
    label: "Punteggiatura funzionale",
    description: "Usare punteggiatura, accenti e apostrofi per rendere chiaro il significato.",
  },
  {
    id: "italiano.coesione",
    label: "Coesione del testo",
    description: "Collegare soggetti, pronomi, relative e subordinate senza ambiguità.",
  },
  {
    id: "italiano.argomentazione",
    label: "Tesi e prove",
    description: "Distinguere opinioni, ipotesi, prove e conclusioni proporzionate.",
  },
  {
    id: "inglese.istruzioni",
    label: "Inglese operativo",
    description: "Capire istruzioni brevi utili per agire.",
  },
  {
    id: "inglese.scientifico",
    label: "Inglese scientifico base",
    description: "Interpretare brevi note tecniche su condizioni naturali e osservazioni.",
  },
  {
    id: "inglese.bilingue",
    label: "Istruzioni bilingui",
    description: "Collegare comandi inglesi a decisioni operative in italiano.",
  },
  {
    id: "inglese.grammatica",
    label: "Grammatica inglese funzionale",
    description: "Usare tempi verbali, modali, pronomi e connettivi per capire una procedura.",
  },
  {
    id: "inglese.lessico",
    label: "Lessico inglese in contesto",
    description: "Capire parole tecniche e scolastiche dal contesto operativo.",
  },
  {
    id: "inglese.comprensione",
    label: "Comprensione inglese",
    description: "Selezionare informazioni utili da istruzioni, log e brevi testi in inglese.",
  },
  {
    id: "inglese.dati",
    label: "Dati e misure in inglese",
    description: "Interpretare soglie, quantità, confronti e misure scritte in inglese.",
  },
  {
    id: "scienze.osservazione",
    label: "Osservazione scientifica",
    description: "Leggere segnali naturali e dati semplici prima di intervenire.",
  },
  {
    id: "scienze.sistemi",
    label: "Sistemi viventi",
    description: "Capire relazioni tra luce, acqua, temperatura e organismi.",
  },
  {
    id: "scienze.dati",
    label: "Raccolta dati",
    description: "Usare sensori, tabelle e osservazioni per decidere un intervento.",
  },
  {
    id: "problemSolving",
    label: "Problem solving",
    description: "Scomporre un problema in passi osservabili.",
  },
  {
    id: "pensieroCritico",
    label: "Pensiero critico",
    description: "Verificare ipotesi prima di agire.",
  },
];
