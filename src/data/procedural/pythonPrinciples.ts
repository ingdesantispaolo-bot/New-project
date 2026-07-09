/**
 * Principi di Python per l'area coding di Eli Quest.
 *
 * Ogni "seme" è un micro-esercizio su codice PYTHON REALE (non pseudocodice):
 * lo studente prevede l'output o riconosce il principio, e nella spiegazione
 * trova il PERCHÉ + uno spunto "Approfondisci" per andare oltre il programma.
 *
 * Obiettivi didattici (spiegare E valutare):
 *  - leggere codice riga per riga (tracing)
 *  - variabili, tipi, stringhe, liste, cicli, condizioni, funzioni
 *  - i principi "culturali" di Python: indentazione = struttura, leggibilità,
 *    lo Zen of Python.
 *
 * I semi qui sono authored (coprono i casi concettuali). Il generatore aggiunge
 * famiglie PARAMETRICHE (output di print, cicli, modulo, funzioni) per varietà
 * praticamente infinita.
 */

export type PythonPrincipleSeed = {
  /** Etichetta concettuale, diventa il "concept" del prompt. */
  principle: string;
  /** Livello minimo (1-8) in cui il seme può comparire. */
  minLevel: number;
  /** Codice Python reale, almeno 3 righe. */
  codeLines: string[];
  question: string;
  correct: string;
  distractors: string[];
  /** Perché la risposta è quella: il cuore didattico (>= 45 caratteri). */
  explanation: string;
  /** Spunto per approfondire ANCHE fuori dal programma. */
  explore: string;
  /** Curiosità giocosa opzionale. */
  funFact?: string;
};

export const pythonPrincipleSeeds: PythonPrincipleSeed[] = [
  {
    principle: "variabili come etichette",
    minLevel: 1,
    codeLines: ["punti = 3", "punti = punti + 4", "print(punti)"],
    question: "Che numero stampa questo programma Python?",
    correct: "7",
    distractors: ["3", "4", "34"],
    explanation:
      "In Python una variabile è un'etichetta attaccata a un valore: 'punti = punti + 4' prende il 3 di prima, aggiunge 4 e riattacca l'etichetta al 7.",
    explore: "Approfondisci: cerca 'assegnazione in Python' e prova a scambiare due variabili con a, b = b, a.",
    funFact: "In Python la variabile non 'contiene' il valore: gli punta. Come un'etichetta su una scatola.",
  },
  {
    principle: "stringhe: concatenazione",
    minLevel: 1,
    codeLines: ['nome = "Eli"', 'saluto = "Ciao " + nome', "print(saluto)"],
    question: "Cosa stampa il programma?",
    correct: "Ciao Eli",
    distractors: ["Ciao nome", "Ciao + Eli", 'Ciao " + nome'],
    explanation:
      "Il segno + tra due stringhe le unisce (concatenazione). 'Ciao ' ha uno spazio finale, quindi il risultato è 'Ciao Eli'.",
    explore: "Approfondisci: prova le f-string, il modo moderno: f\"Ciao {nome}\".",
  },
  {
    principle: "stringhe: len()",
    minLevel: 2,
    codeLines: ['parola = "robot"', "n = len(parola)", "print(n)"],
    question: "Quale valore stampa len(parola)?",
    correct: "5",
    distractors: ["4", "6", "robot"],
    explanation:
      "len() conta i caratteri di una stringa. 'robot' ha 5 lettere, quindi len vale 5. len funziona anche con le liste!",
    explore: "Approfondisci: prova len() su una lista e su una frase con spazi (contano anche gli spazi).",
  },
  {
    principle: "tipi di dato",
    minLevel: 2,
    codeLines: ["x = 7", 'y = "7"', "print(type(y).__name__)"],
    question: "Che tipo è y, che vale \"7\" tra virgolette?",
    correct: "str",
    distractors: ["int", "float", "bool"],
    explanation:
      "Le virgolette rendono 7 una stringa (str), non un numero (int). Per Python \"7\" è testo: non puoi sommarlo a 7 senza convertirlo.",
    explore: "Approfondisci: cerca int(\"7\") e str(7) — la conversione tra tipi si chiama casting.",
    funFact: "\"7\" + \"7\" in Python fa \"77\", non 14! Le stringhe si incollano, non si sommano.",
  },
  {
    principle: "liste: indice",
    minLevel: 2,
    codeLines: ["numeri = [10, 20, 30]", "print(numeri[0])"],
    question: "Cosa stampa numeri[0]?",
    correct: "10",
    distractors: ["20", "30", "1"],
    explanation:
      "Le liste in Python si contano da 0: l'indice 0 è il primo elemento. Quindi numeri[0] è 10 e numeri[2] sarebbe 30.",
    explore: "Approfondisci: cerca cosa fa numeri[-1] (l'ultimo elemento) — un trucco molto usato.",
    funFact: "Quasi tutti i linguaggi contano da 0, non da 1. È una scelta storica che confonde tutti all'inizio!",
  },
  {
    principle: "liste: append()",
    minLevel: 3,
    codeLines: ["squadra = [1, 2]", "squadra.append(3)", "print(len(squadra))"],
    question: "Quanti elementi ha la lista dopo append(3)?",
    correct: "3",
    distractors: ["2", "1", "6"],
    explanation:
      "append() aggiunge un elemento in fondo alla lista. Da 2 elementi si passa a 3, quindi len(squadra) vale 3.",
    explore: "Approfondisci: cerca la differenza tra append() (aggiunge 1 elemento) ed extend() (aggiunge più elementi).",
  },
  {
    principle: "ciclo for con range()",
    minLevel: 2,
    codeLines: ["for i in range(3):", "    print(i)"],
    question: "Quali numeri stampa, in ordine?",
    correct: "0 1 2",
    distractors: ["1 2 3", "0 1 2 3", "3"],
    explanation:
      "range(3) produce 0, 1, 2: parte da 0 e si ferma PRIMA del 3. Il for ripete il blocco indentato una volta per ciascun valore.",
    explore: "Approfondisci: prova range(1, 4) e range(0, 10, 2) — puoi scegliere inizio, fine e passo.",
  },
  {
    principle: "condizione if/else",
    minLevel: 2,
    codeLines: ["energia = 8", "if energia >= 10:", '    print("OK")', "else:", '    print("BASSA")'],
    question: "Cosa stampa se energia vale 8?",
    correct: "BASSA",
    distractors: ["OK", "8", "OK BASSA"],
    explanation:
      "8 >= 10 è falso, quindi Python salta il ramo if ed esegue il ramo else, stampando BASSA. Solo un ramo viene eseguito.",
    explore: "Approfondisci: aggiungi un elif energia >= 5 per avere tre livelli invece di due.",
  },
  {
    principle: "operatori booleani",
    minLevel: 3,
    codeLines: ["a = True", "b = False", "print(a and b)"],
    question: "Cosa stampa a and b, con a=True e b=False?",
    correct: "False",
    distractors: ["True", "0", "None"],
    explanation:
      "and è vero solo se ENTRAMBI sono veri. Qui b è False, quindi a and b è False. Con or basterebbe uno vero.",
    explore: "Approfondisci: cerca la 'tabella di verità' di and, or, not — la stessa logica dei circuiti elettronici!",
  },
  {
    principle: "modulo: pari o dispari",
    minLevel: 3,
    codeLines: ["numero = 7", "resto = numero % 2", "print(resto)"],
    question: "Quanto vale 7 % 2 (il resto della divisione)?",
    correct: "1",
    distractors: ["0", "3", "3.5"],
    explanation:
      "L'operatore % dà il RESTO della divisione: 7 diviso 2 fa 3 con resto 1. Se il resto è 0 il numero è pari, altrimenti dispari.",
    explore: "Approfondisci: l'operatore % è usato ovunque, per esempio per capire se un anno è bisestile.",
  },
  {
    principle: "divisione intera",
    minLevel: 4,
    codeLines: ["print(7 // 2)"],
    question: "Cosa stampa 7 // 2 in Python?",
    correct: "3",
    distractors: ["3.5", "4", "1"],
    explanation:
      "// è la divisione INTERA: butta via la parte decimale e tiene solo il quoziente. 7 / 2 farebbe 3.5, ma 7 // 2 fa 3.",
    explore: "Approfondisci: confronta 7 / 2, 7 // 2 e 7 % 2 — quoziente decimale, intero e resto.",
  },
  {
    principle: "potenza",
    minLevel: 4,
    codeLines: ["print(2 ** 5)"],
    question: "Cosa stampa 2 ** 5 in Python?",
    correct: "32",
    distractors: ["10", "25", "7"],
    explanation:
      "** è l'elevamento a potenza: 2 ** 5 vuol dire 2 moltiplicato per sé stesso 5 volte = 32. Non è la moltiplicazione 2×5.",
    explore: "Approfondisci: 2 ** 10 vale 1024, il perché i computer amano le potenze di 2.",
  },
  {
    principle: "funzioni: def e return",
    minLevel: 4,
    codeLines: ["def doppio(n):", "    return n * 2", "print(doppio(6))"],
    question: "Cosa stampa print(doppio(6))?",
    correct: "12",
    distractors: ["6", "26", "62"],
    explanation:
      "def crea una funzione: doppio(6) esegue return 6*2 e restituisce 12, che print mostra. Le funzioni evitano di ripetere il codice.",
    explore: "Approfondisci: aggiungi un secondo parametro, def somma(a, b), e chiamala con somma(3, 4).",
  },
  {
    principle: "indentazione = struttura",
    minLevel: 3,
    codeLines: ['if True:', 'print("ciao")'],
    question: "Perché questo codice Python dà errore?",
    correct: "manca l'indentazione dopo i due punti",
    distractors: ["manca un punto e virgola", "print è scritto male", "True va minuscolo"],
    explanation:
      "In Python gli spazi contano: dopo i due punti la riga dentro l'if DEVE essere indentata (spostata a destra). Senza rientro dà IndentationError.",
    explore: "Approfondisci: in molti linguaggi le { } definiscono i blocchi; Python usa invece l'indentazione. È la sua firma.",
    funFact: "Grazie all'indentazione obbligatoria, il codice Python di persone diverse si assomiglia: più facile da leggere!",
  },
  {
    principle: "commenti",
    minLevel: 1,
    codeLines: ["# questo è un commento", "punti = 5", "print(punti)  # stampa 5"],
    question: "Cosa fa Python con le righe che iniziano con #?",
    correct: "le ignora: sono commenti per gli umani",
    distractors: ["le stampa a schermo", "dà errore", "le esegue due volte"],
    explanation:
      "Tutto ciò che segue # è un commento: Python lo ignora completamente. Serve a spiegare il codice a chi lo legge, non alla macchina.",
    explore: "Approfondisci: i buoni commenti spiegano il PERCHÉ, non il COSA (che si vede già dal codice).",
  },
  {
    principle: "Zen of Python: leggibilità",
    minLevel: 5,
    codeLines: ["# Due modi di controllare se la lista è vuota", "numeri = []", "# quale riga è più 'pythonica'?"],
    question: "Qual è il modo più leggibile e pythonico?",
    correct: "if not numeri:",
    distractors: ["if len(numeri) == 0:", "if numeri == []:", "if numeri.size() == 0:"],
    explanation:
      "Una lista vuota in Python è già 'falsa', quindi 'if not numeri:' basta e si legge quasi come italiano. Lo Zen of Python dice: 'la leggibilità conta'.",
    explore: "Approfondisci: scrivi import this nell'interprete Python per leggere lo Zen of Python completo.",
    funFact: "Lo Zen of Python è un vero elenco di 19 regole di stile, nascosto dentro Python stesso!",
  },
  {
    principle: "input() e tipi",
    minLevel: 4,
    codeLines: ['eta = input("Quanti anni hai? ")', "print(type(eta).__name__)"],
    question: "Di che tipo è ciò che restituisce input()?",
    correct: "str",
    distractors: ["int", "float", "bool"],
    explanation:
      "input() restituisce SEMPRE una stringa (str), anche se digiti un numero. Per farci i conti devi convertirla con int(eta).",
    explore: "Approfondisci: cerca perché int(input()) è così comune e cosa succede se l'utente scrive lettere.",
  },
  {
    principle: "liste: ciclo e somma",
    minLevel: 5,
    codeLines: ["numeri = [2, 4, 6]", "totale = 0", "for n in numeri:", "    totale = totale + n", "print(totale)"],
    question: "Cosa stampa questo accumulatore?",
    correct: "12",
    distractors: ["6", "3", "246"],
    explanation:
      "Il for scorre la lista e somma ogni elemento in 'totale': 0+2+4+6 = 12. È il classico schema dell'accumulatore.",
    explore: "Approfondisci: Python ha già la funzione sum(numeri) che fa lo stesso in una riga.",
  },
  {
    principle: "confronto ==  vs  =",
    minLevel: 4,
    codeLines: ["x = 5", "print(x == 5)"],
    question: "Cosa stampa print(x == 5) quando x vale 5?",
    correct: "True",
    distractors: ["False", "5", "5 == 5"],
    explanation:
      "Un solo = ASSEGNA un valore; due == CONFRONTANO. Qui x vale 5, quindi x == 5 è vero e stampa True. Confondere = e == è un errore classico.",
    explore: "Approfondisci: prova anche !=, <=, >= — gli operatori di confronto danno sempre True o False.",
  },
  {
    principle: "range come conteggio",
    minLevel: 5,
    codeLines: ["conta = 0", "for i in range(5):", "    conta = conta + 1", "print(conta)"],
    question: "Quante volte gira il ciclo, cioè quanto vale conta?",
    correct: "5",
    distractors: ["4", "6", "0"],
    explanation:
      "range(5) produce 0,1,2,3,4: cinque valori, quindi il blocco gira 5 volte e conta arriva a 5. range(n) ripete esattamente n volte.",
    explore: "Approfondisci: cerca la funzione enumerate(), che ti dà indice E valore mentre scorri una lista.",
  },
];
