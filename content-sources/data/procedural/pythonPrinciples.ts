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
  /** Perché ciascun distrattore è sbagliato, chiave = testo del distrattore. */
  distractorWhy?: Record<string, string>;
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
    distractorWhy: {
      "3": "Quello era il valore prima di sommare 4: la seconda riga lo aggiorna a 7.",
      "4": "4 è solo il numero aggiunto, non il risultato finale della somma.",
      "34": "+ fra numeri somma, non concatena come farebbe con il testo: 3+4 fa 7, non 34.",
    },
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
    distractorWhy: {
      "Ciao nome": "nome senza virgolette è la variabile: print ne mostra il valore 'Eli', non la parola «nome».",
      "Ciao + Eli": "+ concatena il testo: il segno + non viene stampato, scompare nel risultato.",
      'Ciao " + nome': "Le virgolette e il codice non vengono stampati letteralmente: Python li interpreta come istruzioni, non come testo.",
    },
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
    distractorWhy: {
      "4": "«robot» ha cinque lettere (r-o-b-o-t), non quattro.",
      "6": "«robot» ha cinque lettere, non sei.",
      "robot": "len() restituisce un numero che conta i caratteri, non la parola stessa.",
    },
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
    distractorWhy: {
      "int": "x = 7 è un int, ma qui si chiede il tipo di y, che ha le virgolette: è una stringa.",
      "float": "y non ha una parte decimale: ha le virgolette, quindi è una stringa, non un float.",
      "bool": "y non è né True né False: è testo fra virgolette.",
    },
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
    distractorWhy: {
      "20": "20 è all'indice 1, non 0.",
      "30": "30 è all'indice 2, non 0.",
      "1": "1 non è un valore della lista: è stato confuso con l'indice richiesto.",
    },
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
    distractorWhy: {
      "2": "Quello era il numero di elementi prima di append(3): dopo diventano 3.",
      "1": "append() aggiunge un elemento, non lo sostituisce: la lista non si riduce a un solo elemento.",
      "6": "append() aggiunge un solo elemento alla volta: la lista passa da 2 a 3, non salta a 6.",
    },
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
    distractorWhy: {
      "1 2 3": "range(3) parte da 0, non da 1: genera 0, 1, 2.",
      "0 1 2 3": "range(3) si ferma prima di 3: genera solo tre valori, 0, 1, 2, non quattro.",
      "3": "3 è il numero passato a range, non uno dei valori che produce: si ferma proprio prima di 3.",
    },
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
    explore: "Approfondisci: aggiungi un elif energia >= 5 per avere tre rami invece di due.",
    distractorWhy: {
      "OK": "8 >= 10 è falso: il ramo if non si esegue, si esegue else che stampa BASSA.",
      "8": "print stampa il testo del ramo eseguito, non il valore della variabile energia.",
      "OK BASSA": "Solo un ramo fra if ed else viene eseguito, mai entrambi insieme.",
    },
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
    distractorWhy: {
      "True": "and richiede che siano vere entrambe le parti: b è False, quindi il risultato è False.",
      "0": "and restituisce un valore booleano (False), non il numero 0.",
      "None": "and restituisce uno dei due valori booleani, non None.",
    },
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
    distractorWhy: {
      "0": "0 sarebbe il resto se 7 fosse divisibile esattamente per 2, ma non lo è: il resto è 1.",
      "3": "3 è il quoziente della divisione (7 // 2), non il resto.",
      "3.5": "3.5 è il risultato della divisione normale (7 / 2): % dà solo il resto intero, cioè 1.",
    },
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
    distractorWhy: {
      "3.5": "3.5 è il risultato della divisione normale (/): // tiene solo la parte intera, cioè 3.",
      "4": "4 sarebbe se si arrotondasse per eccesso, ma // tronca senza arrotondare: 7//2 fa 3.",
      "1": "1 sarebbe il resto (7 % 2), non il quoziente intero.",
    },
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
    distractorWhy: {
      "10": "10 sarebbe 2×5, ma ** non moltiplica: eleva a potenza, cioè 2 moltiplicato per sé stesso 5 volte.",
      "25": "25 sarebbe 5², ma qui la base è 2 e l'esponente è 5: 2⁵=32.",
      "7": "7 sarebbe 2+5, ma ** non somma: eleva a potenza.",
    },
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
    distractorWhy: {
      "6": "6 è il parametro n ricevuto, ma la funzione lo raddoppia prima di restituirlo: 6×2=12.",
      "26": "Non c'è nessuna concatenazione di cifre: n * 2 è una moltiplicazione, il risultato è 12.",
      "62": "Non c'è nessuna concatenazione di cifre: n * 2 è una moltiplicazione, il risultato è 12.",
    },
  },
  {
    principle: "indentazione = struttura",
    minLevel: 3,
    codeLines: ['if True:', 'print("ciao")'],
    question: "Perché questo codice Python dà errore?",
    correct: "manca l'indentazione dopo i due punti",
    distractors: ["manca un punto e virgola finale", "print è scritto in modo sbagliato", "True va scritto tutto minuscolo"],
    explanation:
      "In Python gli spazi contano: dopo i due punti la riga dentro l'if DEVE essere indentata (spostata a destra). Senza rientro dà IndentationError.",
    explore: "Approfondisci: in molti linguaggi le { } definiscono i blocchi; Python usa invece l'indentazione. È la sua firma.",
    funFact: "Grazie all'indentazione obbligatoria, il codice Python di persone diverse si assomiglia: più facile da leggere!",
    distractorWhy: {
      "manca un punto e virgola finale": "Python non richiede il punto e virgola a fine riga: il problema è l'indentazione mancante dopo i due punti.",
      "print è scritto in modo sbagliato": 'print("ciao") è scritto correttamente: il problema è che non è rientrato rispetto all\'if.',
      "True va scritto tutto minuscolo": "True con la maiuscola iniziale è corretto in Python: il problema è l'indentazione mancante.",
    },
  },
  {
    principle: "commenti",
    minLevel: 1,
    codeLines: ["# questo è un commento", "punti = 5", "print(punti)  # stampa 5"],
    question: "Cosa fa Python con le righe che iniziano con #?",
    correct: "le ignora: sono commenti per gli umani",
    distractors: ["le stampa a schermo come testo", "dà errore e ferma il programma", "le esegue due volte di seguito"],
    explanation:
      "Tutto ciò che segue # è un commento: Python lo ignora completamente. Serve a spiegare il codice a chi lo legge, non alla macchina.",
    explore: "Approfondisci: i buoni commenti spiegano il PERCHÉ, non il COSA (che si vede già dal codice).",
    distractorWhy: {
      "le stampa a schermo come testo": "I commenti non vengono mai stampati: l'interprete li ignora completamente.",
      "dà errore e ferma il programma": "I commenti sono sintassi valida: non causano nessun errore.",
      "le esegue due volte di seguito": "I commenti non vengono eseguiti nemmeno una volta: sono completamente ignorati.",
    },
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
    distractorWhy: {
      "if len(numeri) == 0:": "Funziona, ma è più lungo e meno diretto: «if not numeri:» sfrutta che una lista vuota è già considerata falsa.",
      "if numeri == []:": "Funziona, ma è meno pythonico: confrontare esplicitamente con una lista vuota è più verboso del necessario.",
      "if numeri.size() == 0:": "Le liste Python non hanno un metodo size(): quello è comune in altri linguaggi, non in Python.",
    },
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
    distractorWhy: {
      "int": "input() restituisce sempre testo, anche se l'utente digita solo cifre: mai automaticamente un int.",
      "float": "input() restituisce sempre testo, mai automaticamente un numero decimale.",
      "bool": "input() restituisce sempre una stringa, mai un valore booleano.",
    },
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
    distractorWhy: {
      "6": "6 è solo l'ultimo elemento della lista, non la somma di tutti e tre.",
      "3": "3 è il numero di elementi della lista, non la loro somma.",
      "246": "+ fra numeri somma, non concatena le cifre come farebbe con il testo: il risultato è 12.",
    },
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
    distractorWhy: {
      "False": "x vale proprio 5, quindi il confronto x == 5 è vero, non falso.",
      "5": "== restituisce un valore booleano, non uno dei numeri confrontati.",
      "5 == 5": "print calcola il confronto prima di stamparlo: mostra il risultato True, non l'espressione scritta così com'è.",
    },
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
    distractorWhy: {
      "4": "range(5) genera cinque valori (0,1,2,3,4): il ciclo gira 5 volte, non 4.",
      "6": "range(5) genera esattamente cinque valori, non sei.",
      "0": "conta parte da 0 ma viene incrementata a ogni giro: dopo cinque giri vale 5, non è rimasta a 0.",
    },
  },
];
