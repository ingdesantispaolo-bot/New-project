/**
 * Atlante dei Linguaggi di Programmazione — storici e attuali.
 *
 * Schede brevi e giocose per l'area coding: anno di nascita, "personalità" del
 * linguaggio, un "ciao mondo", dove si usa oggi e una curiosità. Servono a far
 * capire allo studente che i linguaggi sono TANTI, nati in epoche diverse e per
 * scopi diversi — e a incuriosirlo ad approfondire.
 *
 * Il generatore usa queste schede per costruire quiz variati:
 *  - "in che anno nasce X?"
 *  - "di quale linguaggio è questo «ciao mondo»?"
 *  - "quale linguaggio è famoso per...?"
 *  - "chi è più vecchio tra X e Y?"
 *  - curiosità.
 */

export type LanguageCard = {
  name: string;
  /** Anno di nascita (approssimato per i più antichi). */
  year: number;
  /** Righe del "ciao mondo" in quel linguaggio (>= 1 riga). */
  helloWorld: string[];
  /** A cosa serve / per cosa è famoso, in parole semplici. */
  famousFor: string;
  /** Personalità in una frase. */
  personality: string;
  /** Dove lo incontri oggi. */
  stillUsed: string;
  /** Curiosità giocosa. */
  curiosity: string;
  /** Spunto per approfondire. */
  explore: string;
  /** Categoria temporale, per i quiz "storico vs attuale". */
  era: "storico" | "moderno";
};

export const languageCards: LanguageCard[] = [
  {
    name: "Python",
    year: 1991,
    helloWorld: ['print("ciao mondo")'],
    famousFor: "intelligenza artificiale, dati e primi passi nel coding",
    personality: "semplice e leggibile, quasi come scrivere in inglese",
    stillUsed: "AI, scienza, siti web, automazione — uno dei più usati oggi",
    curiosity: "prende il nome dai Monty Python, un gruppo comico inglese, non dal serpente!",
    explore: "Cerca 'perché Python si chiama così' e la storia di Guido van Rossum.",
    era: "moderno",
  },
  {
    name: "JavaScript",
    year: 1995,
    helloWorld: ['console.log("ciao mondo");'],
    famousFor: "far funzionare le pagine web nel browser",
    personality: "il linguaggio del web, ovunque ci sia un sito interattivo",
    stillUsed: "ogni sito web moderno, app e persino server",
    curiosity: "fu creato in soli 10 giorni, e NON è parente di Java nonostante il nome!",
    explore: "Cerca la differenza tra Java e JavaScript: sono due linguaggi diversi.",
    era: "moderno",
  },
  {
    name: "C",
    year: 1972,
    helloWorld: ['#include <stdio.h>', "int main() {", '    printf("ciao mondo");', "}"],
    famousFor: "sistemi operativi e programmi veloci vicini alla macchina",
    personality: "potente e veloce, ma esigente: ti fa gestire tutto a mano",
    stillUsed: "dentro Windows, Linux, macOS e in quasi ogni dispositivo",
    curiosity: "da lui derivano C++, Java, C# e in parte quasi tutti i linguaggi moderni.",
    explore: "Cerca perché C è chiamato 'la lingua madre' di tanti linguaggi.",
    era: "storico",
  },
  {
    name: "C++",
    year: 1985,
    helloWorld: ["#include <iostream>", "int main() {", '    std::cout << "ciao mondo";', "}"],
    famousFor: "videogiochi ad alte prestazioni e programmi complessi",
    personality: "il fratello 'muscoloso' di C, con superpoteri in più",
    stillUsed: "motori di videogiochi, browser, software professionale",
    curiosity: "il ++ nel nome è un piccolo scherzo: in C significa 'aggiungi 1'.",
    explore: "Cerca cosa sono le 'classi' e la 'programmazione a oggetti'.",
    era: "moderno",
  },
  {
    name: "Java",
    year: 1995,
    helloWorld: ["class Ciao {", "  public static void main(String[] a) {", '    System.out.println("ciao mondo");', "  }", "}"],
    famousFor: "app Android e grandi programmi aziendali",
    personality: "'scrivi una volta, gira ovunque': lo stesso codice su ogni macchina",
    stillUsed: "app Android, banche, grandi sistemi",
    curiosity: "il simbolo è una tazza di caffè, perché 'Java' è anche un tipo di caffè.",
    explore: "Cerca cos'è la 'macchina virtuale Java' che lo fa girare ovunque.",
    era: "moderno",
  },
  {
    name: "Scratch",
    year: 2007,
    helloWorld: ["quando si clicca 🏳", 'dì "ciao mondo"'],
    famousFor: "imparare a programmare con i blocchi colorati, senza scrivere",
    personality: "coding come costruzioni: trascini blocchi che si incastrano",
    stillUsed: "scuole di tutto il mondo per i primi passi nel coding",
    curiosity: "è stato creato al MIT apposta per i ragazzi, e il suo simbolo è un gatto.",
    explore: "Prova Scratch online e costruisci un mini-gioco trascinando i blocchi.",
    era: "moderno",
  },
  {
    name: "Assembly",
    year: 1949,
    helloWorld: ["MOV AH, 09h", "LEA DX, msg", "INT 21h"],
    famousFor: "parlare quasi direttamente alla CPU, comando per comando",
    personality: "il più 'vicino alla macchina': difficile ma velocissimo",
    stillUsed: "piccole parti critiche dove serve la massima velocità",
    curiosity: "ogni tipo di processore ha il suo Assembly diverso.",
    explore: "Cerca cos'è il 'linguaggio macchina' fatto solo di 0 e 1 sotto l'Assembly.",
    era: "storico",
  },
  {
    name: "Fortran",
    year: 1957,
    helloWorld: ["      PROGRAM CIAO", "      PRINT *, 'ciao mondo'", "      END"],
    famousFor: "calcoli scientifici e matematici pesanti",
    personality: "il nonno dei linguaggi 'ad alto livello', nato per la scienza",
    stillUsed: "ancora oggi in meteorologia e fisica per calcoli enormi",
    curiosity: "il nome viene da FORmula TRANslation: 'tradurre formule'.",
    explore: "Cerca perché i supercomputer usano Fortran ancora oggi, dopo 65 anni.",
    era: "storico",
  },
  {
    name: "COBOL",
    year: 1959,
    helloWorld: ["DISPLAY 'ciao mondo'."],
    famousFor: "banche, stipendi e grandi gestionali degli anni '60",
    personality: "verboso come un documento: le istruzioni sembrano frasi inglesi",
    stillUsed: "incredibilmente, ancora in molte banche e assicurazioni!",
    curiosity: "gran parte fu progettato da Grace Hopper, pioniera dell'informatica.",
    explore: "Cerca chi era Grace Hopper e cos'è un 'bug' (trovò un vero insetto!).",
    era: "storico",
  },
  {
    name: "BASIC",
    year: 1964,
    helloWorld: ['10 PRINT "CIAO MONDO"', "20 GOTO 10"],
    famousFor: "il primo linguaggio di tanti ragazzi negli anni '80",
    personality: "semplice e immediato, con le righe numerate",
    stillUsed: "poco oggi, ma ha insegnato a programmare a milioni di persone",
    curiosity: "il nome significa 'Beginner's All-purpose... Code': fatto apposta per principianti.",
    explore: "Cerca i vecchi home computer come il Commodore 64 che partivano in BASIC.",
    era: "storico",
  },
  {
    name: "Lisp",
    year: 1958,
    helloWorld: ['(print "ciao mondo")'],
    famousFor: "intelligenza artificiale delle origini, tutto fatto di parentesi",
    personality: "elegante e strano: il codice è fatto di liste tra parentesi",
    stillUsed: "in editor come Emacs e in alcune nicchie di ricerca",
    curiosity: "è il secondo linguaggio 'ad alto livello' più antico ancora usato.",
    explore: "Cerca perché si scherza dicendo che Lisp è fatto di 'Lost In Stupid Parentheses'.",
    era: "storico",
  },
  {
    name: "Pascal",
    year: 1970,
    helloWorld: ["begin", "  writeln('ciao mondo')", "end."],
    famousFor: "insegnare a programmare in modo ordinato",
    personality: "rigoroso e didattico, ti insegna il 'buon ordine'",
    stillUsed: "poco oggi, ma è stato un linguaggio-scuola per decenni",
    curiosity: "prende il nome da Blaise Pascal, matematico che costruì una calcolatrice nel 1642.",
    explore: "Cerca chi era Blaise Pascal e la sua macchina da calcolo 'Pascalina'.",
    era: "storico",
  },
  {
    name: "Ruby",
    year: 1995,
    helloWorld: ['puts "ciao mondo"'],
    famousFor: "creare siti web in modo elegante e piacevole",
    personality: "pensato per rendere felice il programmatore",
    stillUsed: "siti web e startup, spesso con Ruby on Rails",
    curiosity: "il suo creatore giapponese voleva un linguaggio 'divertente da usare'.",
    explore: "Cerca cos'è un 'framework' come Ruby on Rails.",
    era: "moderno",
  },
  {
    name: "Go",
    year: 2009,
    helloWorld: ["package main", 'import "fmt"', "func main() {", '    fmt.Println("ciao mondo")', "}"],
    famousFor: "programmi di rete veloci e servizi su internet",
    personality: "semplice e moderno, nato in Google per andare veloce",
    stillUsed: "servizi cloud, Docker, strumenti di internet",
    curiosity: "il suo simbolo è un piccolo roditore azzurro, il 'gopher'.",
    explore: "Cerca perché Go è nato per risolvere la lentezza dei grandi programmi.",
    era: "moderno",
  },
  {
    name: "Rust",
    year: 2010,
    helloWorld: ["fn main() {", '    println!("ciao mondo");', "}"],
    famousFor: "programmi velocissimi ma SICURI, senza certi bug pericolosi",
    personality: "severo ma protettivo: ti impedisce errori di memoria",
    stillUsed: "browser, sistemi operativi e software dove la sicurezza conta",
    curiosity: "per anni è stato votato il linguaggio 'più amato' dai programmatori.",
    explore: "Cerca cosa sono gli 'errori di memoria' che Rust vuole evitare.",
    era: "moderno",
  },
  {
    name: "SQL",
    year: 1974,
    helloWorld: ["SELECT 'ciao mondo';"],
    famousFor: "fare domande alle basi di dati (database)",
    personality: "non 'fa cose', ma CHIEDE dati: quasi come parlare inglese",
    stillUsed: "ovunque ci siano dati salvati: app, siti, negozi",
    curiosity: "non serve per fare giochi, ma per cercare tra milioni di dati in un lampo.",
    explore: "Cerca cos'è un database e prova SELECT * FROM per 'vedere tutto'.",
    era: "storico",
  },
  {
    name: "HTML",
    year: 1993,
    helloWorld: ["<p>ciao mondo</p>"],
    famousFor: "costruire la struttura delle pagine web",
    personality: "non è un vero linguaggio di programmazione: descrive, non calcola",
    stillUsed: "in ogni singola pagina web del mondo",
    curiosity: "usa le 'etichette' <come questa> per dire cos'è ogni pezzo di pagina.",
    explore: "Cerca la differenza tra HTML (struttura), CSS (stile) e JavaScript (azioni).",
    era: "moderno",
  },
  {
    name: "Swift",
    year: 2014,
    helloWorld: ['print("ciao mondo")'],
    famousFor: "creare app per iPhone e iPad",
    personality: "moderno e pulito, nato in Apple per sostituire un linguaggio più vecchio",
    stillUsed: "quasi tutte le nuove app per iPhone",
    curiosity: "'swift' in inglese significa 'veloce', ed è anche un uccellino.",
    explore: "Cerca con quale linguaggio erano fatte le app iPhone PRIMA di Swift.",
    era: "moderno",
  },
];
