// Il lotto delle sessioni lunghe — 10 settembre 2026.
//
// ## Perché questo file esiste
//
// Le fasce di priorità sono passate da 3+3+6 materie con sessioni 6/5/1 a
// 4+4+4 con sessioni **6/4/2**: nessuna materia si liquida più in un esercizio
// solo. Il conto delle quote torna (24/16/8 = 50,0% / 33,3% / 16,7%), ma
// allungare una sessione divide il numero di sessioni distinte che il banco
// regge, e `pozzo_per_fascia_audit` ne pretende quindici per ogni fascia di
// difficoltà.
//
// Sei materie sono finite sotto quel pavimento, sempre agli **estremi** della
// scala — fascia 2 e fascia 8 — che è dove il ponte euristico 4→8 aveva
// lasciato il materiale più magro:
//
//   coding       fascia 2: −15 item   fascia 8: −15    (passa a 6 per sessione)
//   storia       fascia 2: −10 item   fascia 8: −15    (passa a 4)
//   latino       fascia 2:  −1 item   fascia 8:  −3    (passa a 4)
//   logica       fascia 2:  −8 item                    (passa a 2)
//   musica       fascia 2:  −7 item                    (passa a 2)
//   elettronica                       fascia 8:  −6    (passa a 2)
//
// ## Perché sono quasi tutti da toccare e non da scegliere
//
// Fino a oggi i dodici banchi contenevano **tre formati soli**: scelta
// multipla, numero da digitare, parola da digitare. Non perché gli altri non
// esistano — `ExerciseInteraction.IMPLEMENTED` ne elenca venticinque e
// l'`ExercisePlayer` li disegna tutti — ma perché il costruttore dei banchi
// sapeva fare quei tre. I formati manipolativi arrivavano solo dalle ricette
// dei minigiochi, cioè da un altro sistema, che il pozzo non conta.
//
// Da questo lotto il banco può portare **ordering**, **matching** e
// **classification**: si trascina, si abbina, si smista. È il gesto che
// `gesto_audit` chiama MANIPOLA, ed è quello in cui la competenza sta nel
// gesto e non nel riconoscere l'etichetta giusta fra quattro.
//
// Restano a scelta multipla e a risposta libera solo dove servono davvero:
//
//  - **elettronica**, perché `build_final_exam` accetta dai suoi nodi soltanto
//    `multiple_choice` e `short_answer` — nel mondo si impara facendo, e
//    all'esame la sua prova misura il richiamo;
//  - la quota di **risposta libera** che ogni banco deve tenere fra il 20% e il
//    30% (Decisione 10, `free_answer_audit`). Un lotto tutto manipolativo la
//    farebbe scendere sotto il minimo, perché gli item manipolativi contano nel
//    totale e non fra i liberi. Storia, musica ed elettronica ne portano
//    apposta la loro parte.
//
// ## Le regole, uguali a quelle degli altri lotti
//
//  1. **La fascia è dichiarata**: ogni riga porta `difficulty8: true` e la sua
//     fascia 1..8. Da oggi il flag viene letto anche per i formati non a scelta
//     multipla, cosa che prima non succedeva.
//  2. **Ordinamento**: `items` è la presentazione, e non deve mai coincidere con
//     `correctOrder`, o la prova si risolve premendo in fila.
//  3. **Abbinamento**: almeno tre coppie, nessun lato ripetuto, e nessuna coppia
//     che possa reggere anche con l'altro lato.
//  4. **Smistamento**: ogni elemento in una categoria sola, e categorie che si
//     escludono davvero.
//  5. **Ogni prova ha la sua spiegazione**, ed è la spiegazione a dire il
//     *perché*, non a ripetere la risposta: è il testo che NORA legge quando il
//     bambino sbaglia.

// ---------------------------------------------------------------------------
// CODING — 15 alla fascia 2, 15 alla fascia 8
// ---------------------------------------------------------------------------
//
// La fascia 2 sono i mondi 4-6. Le prove chiedono di far succedere qualcosa
// nell'ordine giusto, non di sapere come si chiama: l'ordine è la prima idea
// vera della programmazione, e si può capire senza aver mai scritto una riga.
//
// La fascia 8 sono i mondi 22-24, e qui il salto è di natura: non «che cosa fa
// questa riga» ma «che cosa costa», «in che ordine vanno i controlli», «che
// cosa resta vero mentre il ciclo gira».

const CODING = [
  // ------------------------------------------------------------- fascia 2
  { topic: "algoritmi", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Il braccio meccanico deve annaffiare la pianta della serra. Metti le istruzioni nell'ordine in cui vanno eseguite.",
    items: ["versa l'acqua sulla terra", "riempi l'annaffiatoio", "prendi l'annaffiatoio", "vai davanti alla pianta"],
    correctOrder: ["prendi l'annaffiatoio", "riempi l'annaffiatoio", "vai davanti alla pianta", "versa l'acqua sulla terra"],
    explanation: "Una macchina non indovina l'ordine: esegue le istruzioni una dopo l'altra, esattamente come le trova. Versare prima di riempire non dà errore — dà una pianta asciutta, ed è il tipo di guasto più difficile da trovare, perché il programma sembra funzionare." },

  { topic: "variabili", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Il computer incontra la riga «punti = punti + 10». Metti in ordine le tre cose che fa.",
    items: ["scrive il risultato dentro punti", "somma 10 a quel valore", "legge il valore che punti ha adesso"],
    correctOrder: ["legge il valore che punti ha adesso", "somma 10 a quel valore", "scrive il risultato dentro punti"],
    explanation: "L'uguale non è quello della matematica: qui vuol dire «metti dentro». Prima si calcola tutto quello che sta a destra, e solo alla fine il risultato entra nella variabile a sinistra. Per questo «punti = punti + 10» non è un'equazione impossibile ma un aggiornamento." },

  { topic: "tipi", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Smista ogni valore nella sua famiglia.",
    items: ["7", "\"7\"", "3.5", "\"ciao\"", "True"],
    categories: ["numero", "testo", "vero o falso"],
    assignments: { "7": "numero", "\"7\"": "testo", "3.5": "numero", "\"ciao\"": "testo", "True": "vero o falso" },
    explanation: "Le virgolette cambiano tutto: 7 è una quantità con cui si fanno i conti, \"7\" è un carattere scritto. 7 + 1 fa 8; \"7\" + \"1\" fa \"71\", perché due testi si attaccano invece di sommarsi. È l'errore che ogni programmatore fa almeno una volta con quello che arriva dalla tastiera." },

  { topic: "operatori", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni simbolo a quello che fa davvero.",
    pairs: [
      { left: "=", right: "mette un valore dentro una variabile" },
      { left: "==", right: "controlla se due valori sono uguali" },
      { left: "+", right: "somma due numeri" },
      { left: "!=", right: "controlla se due valori sono diversi" },
    ],
    explanation: "Un uguale comanda, due uguali domandano. Scambiarli è il refuso più comune del mondo: «if voto = 6» non chiede niente, prova a scriverci dentro, e il programma o si ferma o fa una cosa che non avevi chiesto." },

  { topic: "cicli", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Il programma è «for i in range(3): print(i)». Metti in ordine le righe che compaiono sullo schermo.",
    items: ["2", "0", "1"],
    correctOrder: ["0", "1", "2"],
    explanation: "range(3) non conta fino a tre: conta tre volte partendo da zero, quindi 0, 1, 2. Il tre non compare mai, ed è il motivo per cui il conteggio dei programmatori comincia da zero anche quando sembra scomodo." },

  { topic: "condizioni", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "La variabile eta vale 12. Quali controlli sono veri e quali falsi?",
    items: ["eta > 10", "eta == 12", "eta < 5", "eta != 12"],
    categories: ["vero", "falso"],
    assignments: { "eta > 10": "vero", "eta == 12": "vero", "eta < 5": "falso", "eta != 12": "falso" },
    explanation: "Una condizione non è una domanda a cui rispondere a sentimento: è un conto che dà sempre vero o falso. Sostituisci il valore al posto del nome e leggi — 12 > 10 è vero, 12 < 5 è falso — e non resta niente da indovinare." },

  { topic: "input", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni comando a quello che succede quando il programma ci arriva.",
    pairs: [
      { left: "input()", right: "il programma si ferma e aspetta che tu scriva" },
      { left: "print()", right: "compare una riga sullo schermo" },
      { left: "int()", right: "un testo diventa un numero" },
      { left: "len()", right: "si ottiene quanti elementi ci sono" },
    ],
    explanation: "input() restituisce sempre testo, anche quando scrivi un numero: per questo va quasi sempre insieme a int(). Senza, «12» + 1 non fa tredici — dà errore, perché stai chiedendo di sommare uno a una parola." },

  { topic: "stringhe", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Il programma deve stampare CIAO in maiuscolo. Metti in ordine i tre passaggi.",
    items: ["stampa quello che hai ottenuto", "metti la parola ciao in una variabile", "trasforma la variabile in maiuscolo"],
    correctOrder: ["metti la parola ciao in una variabile", "trasforma la variabile in maiuscolo", "stampa quello che hai ottenuto"],
    explanation: "Ogni passaggio lavora su quello che il precedente ha prodotto. Stampare prima di trasformare non è un errore di sintassi: stampa la parola minuscola, e il programma sembra sbagliato quando invece è solo in disordine." },

  { topic: "liste", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Quali di queste operazioni cambiano la lista, e quali la lasciano com'è?",
    items: ["append(4)", "len(lista)", "sort()", "lista[0]"],
    categories: ["cambia la lista", "la lascia com'è"],
    assignments: { "append(4)": "cambia la lista", "len(lista)": "la lascia com'è", "sort()": "cambia la lista", "lista[0]": "la lascia com'è" },
    explanation: "Alcune operazioni chiedono, altre modificano. La differenza conta quando la stessa lista è usata in due punti del programma: chi legge non disturba nessuno, chi modifica cambia il mondo anche per l'altro pezzo di codice." },

  { topic: "stile", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni nome di variabile alla cosa che dovrebbe contenere.",
    pairs: [
      { left: "eta", right: "quanti anni ha una persona" },
      { left: "prezzo", right: "quanto costa un oggetto" },
      { left: "nomi", right: "un elenco di parole" },
      { left: "acceso", right: "vero oppure falso" },
    ],
    explanation: "Il nome di una variabile è il commento più letto del programma, perché compare a ogni riga. Un nome che dice che cosa contiene fa risparmiare la spiegazione; una x costringe a risalire indietro ogni volta per ricordarsi che cos'era." },

  { topic: "output", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Il programma è: «for parola in [\"sole\", \"luna\"]: print(parola)» e poi «print(\"fine\")». Metti in ordine quello che compare.",
    items: ["fine", "luna", "sole"],
    correctOrder: ["sole", "luna", "fine"],
    explanation: "Il ciclo finisce tutti i suoi giri prima che il programma prosegua: le due parole escono nell'ordine in cui stanno nella lista, e solo dopo arriva la riga che sta fuori dal ciclo. Se «fine» comparisse in mezzo, vorrebbe dire che quella riga è rientrata di quattro spazi." },

  { topic: "booleani", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Vero o falso? Smista ogni espressione.",
    items: ["3 > 2 and 2 > 1", "3 > 2 or 1 > 5", "not (2 == 2)", "5 != 5"],
    categories: ["vero", "falso"],
    assignments: { "3 > 2 and 2 > 1": "vero", "3 > 2 or 1 > 5": "vero", "not (2 == 2)": "falso", "5 != 5": "falso" },
    explanation: "«and» pretende che siano vere tutte e due, «or» si accontenta di una, «not» rovescia. Con «or» basta il primo pezzo vero e il secondo non conta più: è la ragione per cui a volte si mette a sinistra il controllo più facile." },

  { topic: "funzioni", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni parola al suo ruolo dentro una funzione.",
    pairs: [
      { left: "def", right: "annuncia che sta per nascere una funzione" },
      { left: "return", right: "manda un risultato a chi l'ha chiamata" },
      { left: "parametro", right: "il valore che la funzione riceve da fuori" },
      { left: "chiamata", right: "il momento in cui la funzione parte" },
    ],
    explanation: "Definire e chiamare sono due momenti diversi: «def» scrive la ricetta, la chiamata la cucina. Una funzione definita e mai chiamata non fa assolutamente niente, e il programma non se ne lamenta." },

  { topic: "input", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Il programma chiede la tua età e stampa in che anno sei nato. Metti in ordine i quattro passaggi.",
    items: ["stampa il risultato", "sottrai l'età a 2026", "chiedi l'età a chi gioca", "trasforma la risposta in numero"],
    correctOrder: ["chiedi l'età a chi gioca", "trasforma la risposta in numero", "sottrai l'età a 2026", "stampa il risultato"],
    explanation: "La trasformazione in numero deve stare fra la domanda e il conto: quello che arriva dalla tastiera è testo, e 2026 meno un testo non si può fare. Spostarla anche solo di un posto rompe il programma." },

  { topic: "cicli", difficulty: 2, difficulty8: true, format: "numeric_input",
    prompt: "Quante righe compaiono sullo schermo con questo programma?\nfor i in range(4):\n    print(\"ciao\")",
    answer: "4",
    explanation: "Il corpo del ciclo viene eseguito una volta per ogni giro, e range(4) fa quattro giri: 0, 1, 2, 3. La parola stampata è sempre la stessa, ma le righe sono quattro — è il numero di giri a decidere, non quello che c'è dentro." },

  // ------------------------------------------------------------- fascia 8
  { topic: "algoritmi", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Ordinamento per selezione: metti in ordine i passi di un singolo giro.",
    items: ["ricomincia dalla posizione successiva", "scambialo con il primo elemento non ancora sistemato", "cerca il più piccolo fra gli elementi non ancora sistemati"],
    correctOrder: ["cerca il più piccolo fra gli elementi non ancora sistemati", "scambialo con il primo elemento non ancora sistemato", "ricomincia dalla posizione successiva"],
    explanation: "Ogni giro sistema definitivamente una posizione, e la parte già ordinata cresce di uno. È lento — su mille elementi fa quasi un milione di confronti — ma ha una proprietà preziosa: dopo k giri i primi k elementi sono quelli giusti, e non si toccheranno più." },

  { topic: "algoritmi", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "La lista raddoppia di lunghezza. Smista ogni operazione secondo quanto cresce il tempo che impiega.",
    items: ["scorrere tutta la lista", "leggere lista[0]", "ricerca binaria su una lista ordinata", "confrontare ogni elemento con ogni altro"],
    categories: ["raddoppia anche il tempo", "il tempo cresce molto di più", "il tempo resta quasi lo stesso"],
    assignments: {
      "scorrere tutta la lista": "raddoppia anche il tempo",
      "leggere lista[0]": "il tempo resta quasi lo stesso",
      "ricerca binaria su una lista ordinata": "il tempo resta quasi lo stesso",
      "confrontare ogni elemento con ogni altro": "il tempo cresce molto di più",
    },
    explanation: "Non conta quanto è veloce il computer: conta come il lavoro cresce con i dati. Confrontare tutte le coppie quadruplica quando i dati raddoppiano, e su liste grandi diventa impraticabile su qualunque macchina. La ricerca binaria, raddoppiando la lista, aggiunge un solo passo." },

  { topic: "cicli", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni comando all'effetto che ha sul ciclo.",
    pairs: [
      { left: "break", right: "esce subito, senza finire i giri rimasti" },
      { left: "continue", right: "salta il resto del giro e passa al successivo" },
      { left: "while True", right: "gira finché qualcosa dentro non lo ferma" },
      { left: "range(0, 10, 2)", right: "fa cinque giri saltando di due in due" },
    ],
    explanation: "break e continue sembrano parenti e fanno cose opposte: uno abbandona il ciclo, l'altro abbandona solo il giro. Confonderli produce un programma che funziona sui casi facili e sbaglia esattamente nel caso in cui la condizione scatta." },

  { topic: "funzioni", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Una funzione ricorsiva calcola il fattoriale di 3. Metti in ordine i risultati man mano che le chiamate si richiudono.",
    items: ["3 × 2 = 6", "2 × 1 = 2", "1"],
    correctOrder: ["1", "2 × 1 = 2", "3 × 2 = 6"],
    explanation: "La ricorsione scende fino al caso più semplice e poi risale moltiplicando. Il primo valore vero non è quello di partenza ma quello del fondo: senza un caso base che restituisca 1, la discesa non finisce e il programma si ferma con la pila piena." },

  { topic: "tipi", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni tipo secondo la possibilità di modificarlo dopo averlo creato.",
    items: ["lista", "tupla", "stringa", "dizionario"],
    categories: ["si può modificare", "non si può modificare"],
    assignments: { "lista": "si può modificare", "tupla": "non si può modificare", "stringa": "non si può modificare", "dizionario": "si può modificare" },
    explanation: "Quando una stringa sembra cambiare, in realtà ne è nata una nuova e il vecchio nome punta altrove. La differenza si vede quando due nomi condividono lo stesso oggetto: modificare una lista si vede da entrambi, «modificare» una stringa no." },

  { topic: "liste", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni scrittura al pezzo di lista che produce.",
    pairs: [
      { left: "lista[1:3]", right: "gli elementi in posizione 1 e 2" },
      { left: "lista[::-1]", right: "tutta la lista al contrario" },
      { left: "lista[-1]", right: "l'ultimo elemento" },
      { left: "lista[:]", right: "una copia nuova con gli stessi elementi" },
    ],
    explanation: "Nelle sezioni l'estremo destro è escluso: 1:3 prende due elementi, non tre. È la stessa convenzione del range, e serve a far tornare i conti — la lunghezza di una fetta è sempre la differenza fra i due numeri." },

  { topic: "condizioni", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Un programma assegna il giudizio a un voto con if / elif / elif. Metti i tre controlli nell'ordine in cui devono comparire perché il giudizio sia giusto.",
    items: ["voto >= 6", "voto >= 8", "voto >= 9"],
    correctOrder: ["voto >= 9", "voto >= 8", "voto >= 6"],
    explanation: "In una catena di elif vince il primo controllo vero, quindi vanno messi dal più esigente al meno esigente. Con «voto >= 6» in cima, un nove entrerebbe lì dentro e non arriverebbe mai agli altri due: il programma non dà errore, dà il giudizio sbagliato a tutti i bravi." },

  { topic: "booleani", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni espressione secondo il significato che ha davvero.",
    items: ["not (a and b)", "not a or not b", "not (a or b)", "not a and not b"],
    categories: ["vuol dire «non tutti e due»", "vuol dire «né l'uno né l'altro»"],
    assignments: {
      "not (a and b)": "vuol dire «non tutti e due»",
      "not a or not b": "vuol dire «non tutti e due»",
      "not (a or b)": "vuol dire «né l'uno né l'altro»",
      "not a and not b": "vuol dire «né l'uno né l'altro»",
    },
    explanation: "Negare una congiunzione la trasforma in disgiunzione, e viceversa: è la regola di De Morgan. Serve tutte le volte che si semplifica una condizione, ed è anche l'errore più subdolo, perché «non a e non b» e «non (a e b)» si leggono quasi uguali e dicono cose diverse." },

  { topic: "stringhe", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni metodo al lavoro che fa su una frase.",
    pairs: [
      { left: "split()", right: "spezza la frase in un elenco di parole" },
      { left: "join()", right: "unisce un elenco di parole in una frase" },
      { left: "strip()", right: "toglie gli spazi all'inizio e alla fine" },
      { left: "replace()", right: "sostituisce una parte con un'altra" },
    ],
    explanation: "split e join sono l'uno l'inverso dell'altro, e insieme risolvono quasi tutto quello che si fa col testo: si spezza, si lavora sui pezzi, si riunisce. strip serve prima di ogni confronto, perché uno spazio invisibile in fondo rende due parole diverse." },

  { topic: "stile", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Hai trovato lo stesso blocco di codice copiato in tre punti e vuoi metterlo in una funzione. Metti in ordine i passi da fare.",
    items: ["cancella le altre due copie e chiama la funzione", "controlla che il programma faccia ancora la stessa cosa", "sposta una delle tre copie dentro una funzione", "sostituisci quella copia con la chiamata"],
    correctOrder: ["sposta una delle tre copie dentro una funzione", "sostituisci quella copia con la chiamata", "controlla che il programma faccia ancora la stessa cosa", "cancella le altre due copie e chiama la funzione"],
    explanation: "Si verifica dopo il primo cambio, non alla fine: se qualcosa si rompe, sai quale passo l'ha rotto. Cancellare tutte e tre le copie prima di aver provato che la funzione funziona è il modo più veloce per non sapere più dove cercare." },

  { topic: "input", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Il programma chiede un numero all'utente. Smista ogni risposta secondo quello che succede con int(input()).",
    items: ["12", "  12  ", "dodici", "12.5"],
    categories: ["diventa un numero", "il programma si ferma con un errore"],
    assignments: { "12": "diventa un numero", "  12  ": "diventa un numero", "dodici": "il programma si ferma con un errore", "12.5": "il programma si ferma con un errore" },
    explanation: "int() tollera gli spazi ai bordi ma non le parole e nemmeno la virgola decimale: «12.5» è un numero per un essere umano e non un intero per il programma. È il motivo per cui l'input di un utente va sempre controllato prima di usarlo, e non dopo che ha fatto cadere tutto." },

  { topic: "variabili", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni variabile a dove è possibile leggerla.",
    pairs: [
      { left: "una variabile creata dentro una funzione", right: "solo dentro quella funzione" },
      { left: "un parametro", right: "dentro la funzione, dal momento della chiamata" },
      { left: "una variabile creata fuori da tutte le funzioni", right: "in tutto il programma" },
      { left: "il valore di un return", right: "dove la funzione è stata chiamata" },
    ],
    explanation: "Una variabile locale sparisce quando la funzione finisce, ed è un bene: significa che due funzioni possono usare lo stesso nome senza pestarsi i piedi. L'unico modo che ha una funzione per far uscire qualcosa è restituirlo." },

  { topic: "output", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Il programma definisce una funzione che stampa «dentro», poi stampa «prima», poi chiama la funzione, poi stampa «dopo». Metti in ordine quello che compare sullo schermo.",
    items: ["dentro", "dopo", "prima"],
    correctOrder: ["prima", "dentro", "dopo"],
    explanation: "La definizione non stampa niente: il corpo della funzione viene eseguito solo alla chiamata, quindi «dentro» compare fra le altre due anche se nel testo del programma è scritto per primo. L'ordine del file e l'ordine dell'esecuzione sono due cose diverse." },

  { topic: "operatori", difficulty: 8, difficulty8: true, format: "numeric_input",
    prompt: "Quanto vale 17 % 5 + 17 // 5?",
    answer: "5",
    explanation: "// è la divisione intera e % è il resto: 17 diviso 5 fa 3 con il resto di 2, quindi 2 + 3 = 5. I due operatori insieme scompongono ogni divisione, ed è così che si estraggono le cifre di un numero una alla volta." },

  { topic: "algoritmi", difficulty: 8, difficulty8: true, format: "numeric_input",
    prompt: "Una ricerca binaria su una lista ordinata di 64 elementi: quante volte deve dimezzare, al massimo, per restare con un elemento solo?",
    answer: "6",
    explanation: "Ogni passo dimezza: 64, 32, 16, 8, 4, 2, 1 — sei dimezzamenti. È il motivo per cui la ricerca binaria è così potente: raddoppiando la lista a 128 elementi i passi diventano sette, uno solo in più." },
];

// ---------------------------------------------------------------------------
// STORIA — 10 alla fascia 2, 15 alla fascia 8
// ---------------------------------------------------------------------------
//
// Vale il vincolo già scritto in `storia-programma.mjs`: nessuna domanda di
// nome o di data senza una tavola su cui impararla. Le prove qui sotto chiedono
// **successione**, **causa** e **metodo** — cose che si ragionano — e le date
// precise restano dove il banco è già ricco.
//
// L'ordinamento è il formato naturale di questa materia: la linea del tempo è
// letteralmente un ordinamento, e trascinare quattro eventi al posto giusto è
// esattamente la competenza, non un modo carino di chiederla.

const STORIA = [
  // ------------------------------------------------------------- fascia 2
  { topic: "preistoria", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Smista ogni abitudine secondo chi la aveva.",
    items: ["seguire le mandrie che si spostano", "seminare e aspettare mesi il raccolto", "dormire in ripari usati per pochi giorni", "costruire granai per conservare il grano"],
    categories: ["cacciatori-raccoglitori", "agricoltori"],
    assignments: {
      "seguire le mandrie che si spostano": "cacciatori-raccoglitori",
      "seminare e aspettare mesi il raccolto": "agricoltori",
      "dormire in ripari usati per pochi giorni": "cacciatori-raccoglitori",
      "costruire granai per conservare il grano": "agricoltori",
    },
    explanation: "Non cambia solo il modo di procurarsi il cibo: cambia il rapporto col tempo e col luogo. Chi semina deve restare e aspettare, e da quell'attesa nascono le case solide, i magazzini e infine la necessità di scrivere quanto grano c'è dentro." },

  { topic: "cronologia", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti questi anni in ordine, dal più lontano nel passato al più vicino a noi.",
    items: ["50 a.C.", "50 d.C.", "200 a.C.", "10 a.C."],
    correctOrder: ["200 a.C.", "50 a.C.", "10 a.C.", "50 d.C."],
    explanation: "Prima di Cristo i numeri grandi sono i più antichi: si contano all'indietro verso lo zero, come i gradini scendendo. Dopo Cristo si torna a contare in avanti, ed è l'unico punto della linea del tempo dove il verso si rovescia." },

  { topic: "preistoria", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i materiali con cui si costruivano gli attrezzi, dal più antico.",
    items: ["il ferro", "la pietra scheggiata", "il bronzo", "la pietra levigata"],
    correctOrder: ["la pietra scheggiata", "la pietra levigata", "il bronzo", "il ferro"],
    explanation: "L'ordine non è casuale: ogni materiale chiede più calore del precedente. Il bronzo si fonde a temperature che una fossa non raggiunge, il ferro ancora di più — sono i forni a decidere la sequenza, non l'ingegno." },

  { topic: "fonti", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Smista ogni reperto secondo il tipo di fonte che è.",
    items: ["un'anfora rotta", "una lettera su papiro", "un'impronta di piede nel fango indurito", "una lapide con un nome inciso"],
    categories: ["fonte scritta", "fonte materiale"],
    assignments: { "un'anfora rotta": "fonte materiale", "una lettera su papiro": "fonte scritta", "un'impronta di piede nel fango indurito": "fonte materiale", "una lapide con un nome inciso": "fonte scritta" },
    explanation: "Conta se ci sono parole, non di che materiale è fatta: una lapide di pietra è una fonte scritta, un vaso di terracotta no. Le fonti materiali sono spesso le uniche che restano di chi non sapeva scrivere, cioè della grandissima maggioranza delle persone vissute." },

  { topic: "preistoria", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni invenzione al cambiamento che ha reso possibile.",
    pairs: [
      { left: "il fuoco", right: "cuocere il cibo e resistere al freddo" },
      { left: "l'aratro", right: "coltivare campi più grandi" },
      { left: "la ruota", right: "trasportare pesi senza sollevarli" },
      { left: "i vasi di terracotta", right: "conservare le provviste da un raccolto all'altro" },
    ],
    explanation: "Nessuna di queste è solo un oggetto: ognuna cambia quanta gente un territorio può nutrire. Conservare il cibo, in particolare, è ciò che permette di restare fermi in un posto — e da lì nascono i villaggi." },

  { topic: "metodo", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Uno scavo ha trovato una tomba. Smista ogni frase secondo che cosa è.",
    items: ["nella tomba c'erano ventidue vasi", "chi fu sepolto lì era una persona importante", "i vasi erano di ceramica dipinta", "quella comunità commerciava con il mare"],
    categories: ["quello che la fonte mostra", "quello che lo storico deduce"],
    assignments: {
      "nella tomba c'erano ventidue vasi": "quello che la fonte mostra",
      "chi fu sepolto lì era una persona importante": "quello che lo storico deduce",
      "i vasi erano di ceramica dipinta": "quello che la fonte mostra",
      "quella comunità commerciava con il mare": "quello che lo storico deduce",
    },
    explanation: "Contare i vasi e riconoscerne il materiale è osservare; dire che il morto era importante è già un ragionamento, che può essere buono ma va difeso. Confondere le due cose è il modo in cui una supposizione diventa, dopo qualche libro, un fatto che nessuno controlla più." },

  { topic: "egizi", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni elemento dell'antico Egitto a quello che era.",
    pairs: [
      { left: "il Nilo", right: "la piena che rendeva fertile la terra" },
      { left: "la piramide", right: "la tomba monumentale di un faraone" },
      { left: "i geroglifici", right: "la scrittura fatta di segni e figure" },
      { left: "il papiro", right: "il foglio su cui si scriveva" },
    ],
    explanation: "Tutto in Egitto ruota attorno alla piena: arriva ogni anno, lascia il limo, e su quel fango cresce il grano che nutre chi costruisce le piramidi. Senza quel ritmo regolare non ci sarebbero né i cantieri né gli scribi che ne tengono i conti." },

  { topic: "civilta", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passaggi che portano da un gruppo di cacciatori a una città.",
    items: ["nascono mestieri diversi dal coltivare", "si coltiva la terra e si allevano animali", "si costruisce un villaggio stabile", "avanza cibo oltre a quello che serve"],
    correctOrder: ["si coltiva la terra e si allevano animali", "si costruisce un villaggio stabile", "avanza cibo oltre a quello che serve", "nascono mestieri diversi dal coltivare"],
    explanation: "Il passaggio decisivo è l'avanzo: finché tutto il cibo prodotto serve a sopravvivere, nessuno può fare il vasaio o il fabbro a tempo pieno. I mestieri nascono dal surplus, e le città nascono dai mestieri." },

  { topic: "cronologia", difficulty: 2, difficulty8: true, format: "numeric_input",
    prompt: "Quanti anni passano fra il 200 a.C. e il 100 d.C.?",
    answer: "300",
    explanation: "Si sommano i due tratti, perché stanno da parti opposte dello zero: 200 anni per arrivare all'anno 1 e altri 100 in avanti. È l'errore classico sottrarre invece di sommare, e viene sempre dal dimenticare che i numeri a.C. corrono all'indietro." },

  { topic: "preistoria", difficulty: 2, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il periodo in cui gli esseri umani cominciarono a coltivare la terra e ad allevare animali?",
    answer: "neolitico", accept: ["il neolitico", "età neolitica", "neolitica"],
    explanation: "Neolitico vuol dire «pietra nuova», dalla pietra levigata invece che scheggiata. Ma il nome parla dell'attrezzo e la vera novità è un'altra: si smette di seguire il cibo e si comincia a produrlo." },

  // ------------------------------------------------------------- fascia 8
  { topic: "medioevo", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine questi passaggi della storia medievale europea.",
    items: ["nascono i Comuni nell'Italia settentrionale", "cade l'Impero romano d'Occidente", "Carlo Magno viene incoronato imperatore", "si diffonde il sistema feudale"],
    correctOrder: ["cade l'Impero romano d'Occidente", "si diffonde il sistema feudale", "Carlo Magno viene incoronato imperatore", "nascono i Comuni nell'Italia settentrionale"],
    explanation: "Il feudalesimo è la risposta al vuoto lasciato dallo Stato romano: senza un potere centrale che protegga, ci si affida a chi ha le armi in cambio di terra e servizi. I Comuni arrivano dopo, quando le città tornano a contare e i mercanti non hanno più bisogno di quel patto." },

  { topic: "medioevo", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni figura del mondo feudale al suo ruolo.",
    pairs: [
      { left: "il vassallo", right: "riceve terra in cambio di fedeltà e servizio armato" },
      { left: "il signore", right: "concede la terra e deve protezione a chi la riceve" },
      { left: "il servo della gleba", right: "lavora la terra e non può lasciarla" },
      { left: "il monastero", right: "conserva e ricopia i testi antichi" },
    ],
    explanation: "Il feudo non è una proprietà ma un patto: chi lo riceve non lo compra, lo tiene finché rispetta gli obblighi. Quando quel patto diventa ereditario il potere del re si sgretola, perché i suoi vassalli non dipendono più da lui per restare dove sono." },

  { topic: "medioevo", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni fatto secondo il suo effetto sulla popolazione europea del Medioevo.",
    items: ["l'aratro pesante e la rotazione dei campi", "la peste nera del Trecento", "il mulino ad acqua", "le carestie del primo Trecento"],
    categories: ["fa crescere la popolazione", "la fa crollare"],
    assignments: {
      "l'aratro pesante e la rotazione dei campi": "fa crescere la popolazione",
      "la peste nera del Trecento": "la fa crollare",
      "il mulino ad acqua": "fa crescere la popolazione",
      "le carestie del primo Trecento": "la fa crollare",
    },
    explanation: "Tutto passa dal cibo: gli strumenti che aumentano il raccolto fanno crescere la gente, e ciò che lo toglie o uccide la fa crollare. Le carestie precedono la peste di pochi decenni, e una popolazione già denutrita è la ragione per cui l'epidemia fu così devastante." },

  { topic: "roma", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine le forme che il potere assunse a Roma.",
    items: ["la Repubblica con consoli e Senato", "l'Impero con un solo principe", "la monarchia dei re", "le guerre civili fra generali"],
    correctOrder: ["la monarchia dei re", "la Repubblica con consoli e Senato", "le guerre civili fra generali", "l'Impero con un solo principe"],
    explanation: "L'Impero non nasce da un colpo di scena ma dall'esaurimento della Repubblica: eserciti fedeli al comandante invece che allo Stato rendono la guerra civile inevitabile, e alla fine il vincitore tiene tutto il potere lasciando in piedi le forme antiche." },

  { topic: "roma", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni istituzione romana alla sua funzione.",
    pairs: [
      { left: "i consoli", right: "guidano lo Stato per un anno, in due" },
      { left: "il Senato", right: "consiglia e decide la politica estera" },
      { left: "i tribuni della plebe", right: "possono bloccare una decisione che danneggia il popolo" },
      { left: "i comizi", right: "assemblee in cui i cittadini votano" },
    ],
    explanation: "Quasi tutte queste cariche sono costruite per impedire che uno solo comandi: due consoli che si controllano, mandati di un anno, un veto in mano ai tribuni. È un sistema pensato contro la tirannia, e regge finché gli eserciti obbediscono allo Stato." },

  { topic: "fonti", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Uno storico studia una rivolta del 1378. Smista ogni fonte secondo che cosa è.",
    items: ["il verbale del processo ai rivoltosi", "un romanzo storico scritto nel 1850", "una cronaca di un mercante che c'era", "un saggio universitario del 1990"],
    categories: ["fonte diretta", "ricostruzione fatta dopo"],
    assignments: {
      "il verbale del processo ai rivoltosi": "fonte diretta",
      "un romanzo storico scritto nel 1850": "ricostruzione fatta dopo",
      "una cronaca di un mercante che c'era": "fonte diretta",
      "un saggio universitario del 1990": "ricostruzione fatta dopo",
    },
    explanation: "Diretta non vuol dire vera: il verbale di un processo è scritto da chi accusa, e la cronaca del mercante da chi aveva interessi. Vuol dire che viene da quel tempo, e che va interrogata; le ricostruzioni si giudicano invece dalle fonti su cui si appoggiano." },

  { topic: "metodo", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passi con cui uno storico arriva a un'affermazione difendibile.",
    items: ["confronta le fonti fra loro e cerca le contraddizioni", "raccoglie le fonti disponibili sul fatto", "formula una spiegazione e dice su che cosa si regge", "chiede di ciascuna chi l'ha prodotta e perché"],
    correctOrder: ["raccoglie le fonti disponibili sul fatto", "chiede di ciascuna chi l'ha prodotta e perché", "confronta le fonti fra loro e cerca le contraddizioni", "formula una spiegazione e dice su che cosa si regge"],
    explanation: "La spiegazione viene per ultima, e questo è tutto il metodo. Partire dalla tesi e cercare le fonti che la confermano dà sempre un risultato — anche quando la tesi è falsa — perché fra migliaia di documenti qualcosa che sembra darti ragione si trova sempre." },

  { topic: "grecia", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni idea greca a ciò che ha reso possibile.",
    pairs: [
      { left: "la democrazia ateniese", right: "i cittadini decidono votando in assemblea" },
      { left: "la filosofia", right: "cercare spiegazioni senza ricorrere ai miti" },
      { left: "il teatro", right: "mettere in scena i conflitti della città" },
      { left: "la polis", right: "una città che è anche uno Stato indipendente" },
    ],
    explanation: "Le quattro cose stanno insieme: una città piccola in cui i cittadini si conoscono rende pensabile che decidano insieme, e una comunità che discute in pubblico produce sia la filosofia sia il teatro. La democrazia ateniese però escludeva donne, stranieri e schiavi — cioè la maggioranza." },

  { topic: "civilta", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni condizione secondo che cosa favorisce nella storia di un popolo.",
    items: ["un grande fiume che allaga regolarmente", "una costa piena di porti naturali", "montagne che isolano le valli", "una pianura aperta senza barriere"],
    categories: ["favorisce agricoltura e Stati centralizzati", "favorisce commercio e contatti", "favorisce l'indipendenza dei piccoli gruppi"],
    assignments: {
      "un grande fiume che allaga regolarmente": "favorisce agricoltura e Stati centralizzati",
      "una costa piena di porti naturali": "favorisce commercio e contatti",
      "montagne che isolano le valli": "favorisce l'indipendenza dei piccoli gruppi",
      "una pianura aperta senza barriere": "favorisce commercio e contatti",
    },
    explanation: "La geografia non decide la storia, ma rende alcune cose più facili di altre: irrigare un grande fiume richiede molte braccia coordinate, e da quel bisogno nasce un potere centrale. Le valli chiuse producono l'opposto — tante comunità che restano diverse." },

  { topic: "medioevo", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il patto con cui un signore concedeva terra in cambio di fedeltà e servizio armato?",
    answer: "feudo", accept: ["il feudo", "feudalesimo", "rapporto feudale"],
    explanation: "Dal feudo prende nome tutto il sistema. La parola indica la terra concessa, non il contratto: ma è la terra a tenere in piedi il legame, e quando diventa ereditaria il legame si allenta." },

  { topic: "roma", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiamava il diritto con cui un tribuno della plebe poteva bloccare una decisione?",
    answer: "veto", accept: ["il veto", "intercessio", "diritto di veto"],
    explanation: "«Veto» in latino vuol dire semplicemente «vieto», alla prima persona. Una sola parola pronunciata da un magistrato fermava l'atto: è la prima volta nella storia in cui il potere di dire no viene scritto nelle regole." },

  { topic: "metodo", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il metodo che data un reperto misurando quanto carbonio radioattivo gli è rimasto?",
    answer: "carbonio 14", accept: ["radiocarbonio", "datazione al carbonio 14", "carbonio-14", "c14"],
    explanation: "Il carbonio 14 decade a ritmo costante, quindi quanto ne resta dice quanto tempo è passato dalla morte dell'organismo. Funziona solo su materiali che sono stati vivi — legno, ossa, stoffa — e non su pietra o metallo: per quelli servono altri metodi." },

  { topic: "grecia", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine questi momenti della storia greca.",
    items: ["l'impero di Alessandro Magno", "le guerre persiane", "la guerra del Peloponneso", "la nascita delle poleis"],
    correctOrder: ["la nascita delle poleis", "le guerre persiane", "la guerra del Peloponneso", "l'impero di Alessandro Magno"],
    explanation: "La sequenza racconta una parabola: le città nascono divise, si uniscono davanti al pericolo persiano, si distruggono fra loro nella guerra del Peloponneso e proprio per questo diventano facili da conquistare per la Macedonia." },

  { topic: "civilta", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni novità del basso Medioevo al suo effetto sulle città.",
    pairs: [
      { left: "le fiere e le rotte commerciali", right: "arriva ricchezza a chi non possiede terra" },
      { left: "le corporazioni di mestiere", right: "gli artigiani si organizzano e contano di più" },
      { left: "le università", right: "si studia fuori dai monasteri" },
      { left: "la moneta usata di nuovo ovunque", right: "si può comprare senza scambiare merci" },
    ],
    explanation: "Sono quattro facce dello stesso movimento: quando la ricchezza smette di essere solo terra, il potere smette di essere solo dei signori. I Comuni sono la conseguenza politica di questo spostamento economico." },

  { topic: "civilta", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine queste invenzioni della scrittura e della memoria, dalla più antica.",
    items: ["la stampa a caratteri mobili", "i gettoni d'argilla per contare le merci", "l'alfabeto con poche lettere", "la scrittura cuneiforme"],
    correctOrder: ["i gettoni d'argilla per contare le merci", "la scrittura cuneiforme", "l'alfabeto con poche lettere", "la stampa a caratteri mobili"],
    explanation: "La scrittura nasce dalla contabilità, non dalla poesia: prima si conta, poi si registra, e solo dopo si racconta. Ogni passo riduce quanto bisogna imparare per usarla — dai mille segni cuneiformi alle ventiquattro lettere — e allarga chi può scrivere." },

  // Le ultime due della fascia 8 non sono un ripensamento: il pozzo misurato
  // dopo il bake si e' fermato a cinquantanove item invece di sessanta, e una
  // delle due e' a risposta libera per tenere il banco sopra il 20%.
  { topic: "metodo", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni affermazione sul Medioevo secondo che cosa è.",
    items: ["la popolazione europea crollò dopo il 1348", "il Medioevo fu un'epoca buia e senza pensiero", "nacquero le prime università in Europa", "nessuno in quei secoli sapeva che la Terra fosse rotonda"],
    categories: ["quello che le fonti sostengono", "un luogo comune smentito"],
    assignments: {
      "la popolazione europea crollò dopo il 1348": "quello che le fonti sostengono",
      "il Medioevo fu un'epoca buia e senza pensiero": "un luogo comune smentito",
      "nacquero le prime università in Europa": "quello che le fonti sostengono",
      "nessuno in quei secoli sapeva che la Terra fosse rotonda": "un luogo comune smentito",
    },
    explanation: "L'idea di un Medioevo buio l'hanno inventata gli umanisti per dare risalto alla propria epoca, e la scuola l'ha ripetuta per secoli. La sfericità della Terra non fu mai in discussione fra le persone istruite: era già nei testi greci che i monasteri copiavano." },

  { topic: "grecia", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiamava la città-stato greca, comunità di cittadini e territorio insieme?",
    answer: "polis", accept: ["la polis", "poleis", "città-stato"],
    explanation: "Polis non vuol dire soltanto «città»: comprende le mura, le campagne attorno e soprattutto i cittadini che ne fanno parte. Da questa parola vengono politica, polizia e metropoli — tutte cose che riguardano il vivere insieme." },
];

// ---------------------------------------------------------------------------
// LOGICA — 8 alla fascia 2
// ---------------------------------------------------------------------------
//
// La fascia 2 di logica aveva dieci item in tutto, e la materia passa a due
// esercizi per sessione. Le prove qui sotto sono tutte da toccare: in logica
// più che altrove il gesto **è** il ragionamento — smistare è categorizzare,
// ordinare è dedurre una sequenza.

const LOGICA = [
  { topic: "sequenze", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti questi numeri in ordine crescente e vedrai la regola che li lega.",
    items: ["8", "2", "16", "4"],
    correctOrder: ["2", "4", "8", "16"],
    explanation: "Ogni numero è il doppio del precedente: non cresce di una quantità fissa ma si raddoppia, e per questo la distanza fra due numeri vicini aumenta ogni volta. Riconoscere se una sequenza somma o moltiplica è la prima domanda da farsi sempre." },

  { topic: "esclusioni", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Tre amici hanno un animale diverso: cane, gatto, pesce. Anna non ha il pesce. Bruno ha il cane. Smista ogni frase.",
    items: ["Bruno ha il cane", "Anna ha il gatto", "Carla ha il pesce", "Anna ha il pesce"],
    categories: ["si può concludere", "non si può concludere"],
    assignments: {
      "Bruno ha il cane": "si può concludere",
      "Anna ha il gatto": "si può concludere",
      "Carla ha il pesce": "si può concludere",
      "Anna ha il pesce": "non si può concludere",
    },
    explanation: "Bruno prende il cane, quindi ad Anna restano gatto e pesce; ma il pesce le è vietato, quindi ha il gatto, e a Carla resta il pesce. Ogni esclusione ne libera un'altra: è per questo che conviene partire dall'informazione più stretta, non dalla prima che si legge." },

  { topic: "insiemi", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Smista ogni animale secondo dove sta rispetto a «vola» e «ha le piume».",
    items: ["il passero", "il pipistrello", "la gallina", "il gatto"],
    categories: ["vola e ha le piume", "vola ma non ha le piume", "ha le piume ma non vola", "né l'uno né l'altro"],
    assignments: {
      "il passero": "vola e ha le piume",
      "il pipistrello": "vola ma non ha le piume",
      "la gallina": "ha le piume ma non vola",
      "il gatto": "né l'uno né l'altro",
    },
    explanation: "Due caratteristiche fanno quattro caselle, e servono tutte e quattro: se ne bastassero due, «vola» e «ha le piume» sarebbero la stessa cosa. Il pipistrello e la gallina sono lì apposta — sono i casi che impediscono di confondere due insiemi che si sovrappongono soltanto in parte." },

  { topic: "deduzioni", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Regola: «tutti i quadrati rossi sono grandi». Smista le figure secondo che cosa se ne può dire.",
    items: ["un quadrato rosso", "un quadrato piccolo", "un cerchio rosso piccolo", "un quadrato grande"],
    categories: ["la regola dice qualcosa", "la regola non dice niente"],
    assignments: {
      "un quadrato rosso": "la regola dice qualcosa",
      "un quadrato piccolo": "la regola dice qualcosa",
      "un cerchio rosso piccolo": "la regola non dice niente",
      "un quadrato grande": "la regola non dice niente",
    },
    explanation: "La regola vale solo per i quadrati rossi: sul cerchio non ha voce. Sul quadrato piccolo però dice eccome — se fosse rosso sarebbe grande, quindi rosso non è. Una regola parla anche al contrario, e questo è il passo che quasi tutti saltano." },

  { topic: "sequenze", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni figura al numero di lati che ha: è il numero nascosto che ordina la sequenza.",
    pairs: [
      { left: "il triangolo", right: "tre lati" },
      { left: "il quadrato", right: "quattro lati" },
      { left: "il pentagono", right: "cinque lati" },
      { left: "l'esagono", right: "sei lati" },
    ],
    explanation: "La regola non sta nella forma ma in un numero nascosto dentro la forma. Le sequenze visive quasi sempre funzionano così: c'è una quantità che cambia in modo regolare, e trovarla vuol dire aver finito." },

  { topic: "esclusioni", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Tre scatole, tre colori. La rossa non contiene la palla. La verde contiene il cubo. Abbina ogni scatola al suo contenuto.",
    pairs: [
      { left: "la scatola verde", right: "il cubo" },
      { left: "la scatola rossa", right: "l'anello" },
      { left: "la scatola blu", right: "la palla" },
    ],
    explanation: "Si parte sempre dalla certezza: il cubo è nella verde, quindi non è altrove. Alla rossa restano palla e anello, ma la palla è esclusa, quindi ha l'anello — e alla blu non resta che la palla. Nessun passo richiede di indovinare." },

  { topic: "insiemi", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti questi gruppi in ordine dal più piccolo al più grande, sapendo che ognuno è contenuto nel successivo.",
    items: ["gli animali", "i gatti", "i mammiferi", "i gatti siamesi"],
    correctOrder: ["i gatti siamesi", "i gatti", "i mammiferi", "gli animali"],
    explanation: "Ogni gruppo sta dentro il successivo: più una categoria è precisa, meno individui contiene. È la ragione per cui aggiungere una parola a una descrizione la rende sempre più piccola, mai più grande." },

  { topic: "deduzioni", difficulty: 2, difficulty8: true, format: "numeric_input",
    prompt: "In una stanza ci sono cani e galline: 7 teste e 20 zampe in tutto. Quanti sono i cani?",
    answer: "3",
    explanation: "Se fossero tutte galline le zampe sarebbero 14; ce ne sono 6 in più, e ogni cane ne aggiunge 2 rispetto a una gallina, quindi i cani sono 3. Partire dal caso estremo e correggere è un metodo che funziona ogni volta che due cose si mescolano." },


  // ---------------------------------------------------------------- fascia 1
  //
  // **Otto prove aggiunte dopo la misura, non prima.** Con i soli item di fascia
  // 2 il mondo 1 di logica restava al 20% di ripetizioni contro un tetto del
  // 17%: il pozzo bastava (`pozzo_per_fascia_audit` verde) ma le prove DISTINTE
  // no, perche' alla fascia 1 la materia aveva due argomenti soli, `sequenze` ed
  // `esclusioni`. Queste otto aprono `deduzioni`, `insiemi`, `verita` e
  // `quantificatori` fin dal primo mondo, ognuna su una coppia (formato,
  // argomento) che non esisteva.
  { topic: "quantificatori", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Nella scatola ci sono quattro palline: tre rosse e una blu. Smista ogni frase.",
    items: ["tutte le palline sono rosse", "alcune palline sono rosse", "nessuna pallina è verde", "tutte le palline sono blu"],
    categories: ["vera", "falsa"],
    assignments: {
      "tutte le palline sono rosse": "falsa",
      "alcune palline sono rosse": "vera",
      "nessuna pallina è verde": "vera",
      "tutte le palline sono blu": "falsa",
    },
    explanation: "«Tutte» cade appena c'è una sola eccezione, e la pallina blu basta. «Alcune» invece regge con una sola: non vuol dire «non tutte», vuol dire «almeno una». Sono le due parole che rovinano piu' ragionamenti di qualunque altra." },

  { topic: "quantificatori", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni parola a quanti casi le bastano per essere vera.",
    pairs: [
      { left: "tutti", right: "nessuna eccezione, neanche una" },
      { left: "alcuni", right: "almeno uno, e possono essere anche tutti" },
      { left: "nessuno", right: "zero casi, neanche uno" },
      { left: "non tutti", right: "almeno un'eccezione" },
    ],
    explanation: "«Alcuni» è quello che inganna: in logica non esclude il «tutti», dice solo che ce n'è almeno uno. Per negare «tutti» non serve «nessuno» — basta «non tutti», cioè una sola eccezione." },

  { topic: "verita", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni frase secondo che cosa è.",
    items: ["due più due fa quattro", "il gelato è buono", "oggi piove oppure non piove", "questa scatola è rossa e non rossa"],
    categories: ["sempre vera", "sempre falsa", "dipende dai gusti"],
    assignments: {
      "due più due fa quattro": "sempre vera",
      "il gelato è buono": "dipende dai gusti",
      "oggi piove oppure non piove": "sempre vera",
      "questa scatola è rossa e non rossa": "sempre falsa",
    },
    explanation: "Alcune frasi sono vere per come sono fatte, prima ancora di guardare il mondo: «piove o non piove» è vera anche senza affacciarsi. Altre si contraddicono da sole. E altre ancora non sono né vere né false: sono opinioni, e discuterne è un'altra cosa." },

  { topic: "verita", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni frase alla sua negazione esatta.",
    pairs: [
      { left: "il gatto è nero", right: "il gatto non è nero" },
      { left: "tutti dormono", right: "almeno uno è sveglio" },
      { left: "nessuno è arrivato", right: "almeno uno è arrivato" },
      { left: "piove e fa freddo", right: "non piove oppure non fa freddo" },
    ],
    explanation: "Negare non vuol dire dire il contrario: il contrario di «tutti dormono» non è «tutti sono svegli», basta uno sveglio. E negare due cose unite da «e» le separa con «oppure», perche' per far cadere la coppia basta che cada un pezzo." },

  { topic: "insiemi", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni gruppo a un esempio che ne fa parte.",
    pairs: [
      { left: "gli strumenti a corda", right: "il violino" },
      { left: "i numeri pari", right: "il dodici" },
      { left: "i mesi con trenta giorni", right: "aprile" },
      { left: "gli animali che volano", right: "il pipistrello" },
    ],
    explanation: "Per dire che una cosa sta in un gruppo bisogna guardare la regola del gruppo, non l'abitudine: il pipistrello vola pur non essendo un uccello. Un solo esempio giusto non dimostra la regola, ma un solo esempio sbagliato la fa cadere." },

  { topic: "deduzioni", difficulty: 1, difficulty8: true, format: "matching",
    prompt: "Abbina ogni indizio a quello che se ne può concludere con certezza.",
    pairs: [
      { left: "il pavimento all'ingresso è bagnato", right: "qualcosa di bagnato è passato di lì" },
      { left: "la scatola dei biscotti è vuota", right: "i biscotti non sono più dentro" },
      { left: "la bici non è nel cortile", right: "la bici è da qualche altra parte" },
      { left: "la luce della cucina è accesa", right: "qualcuno l'ha accesa" },
    ],
    explanation: "Ogni conclusione qui dice **meno** dell'indizio, non di piu': non «ha piovuto», ma «qualcosa di bagnato è passato». È la differenza fra dedurre e indovinare, e si riconosce così — una deduzione non aggiunge mai informazione che non c'era." },

  { topic: "deduzioni", difficulty: 1, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passi per scoprire chi ha spento la luce, senza tirare a indovinare.",
    items: ["concludi chi può essere stato", "guarda chi era in casa a quell'ora", "scopri quando la luce si è spenta", "togli chi era in un'altra stanza"],
    correctOrder: ["scopri quando la luce si è spenta", "guarda chi era in casa a quell'ora", "togli chi era in un'altra stanza", "concludi chi può essere stato"],
    explanation: "La conclusione sta in fondo, sempre. Chi comincia dal sospettato cerca poi gli indizi che gli danno ragione, e ne trova — se ne trovano per chiunque: è il modo piu' comune di sbagliare restando convinti di aver ragionato." },

  { topic: "sequenze", difficulty: 1, difficulty8: true, format: "classification",
    prompt: "Smista ogni sequenza secondo come va avanti.",
    items: ["2, 4, 6, 8", "rosso, blu, rosso, blu", "1, 2, 4, 8", "cerchio, triangolo, cerchio, triangolo"],
    categories: ["cresce ogni volta", "si ripete uguale"],
    assignments: {
      "2, 4, 6, 8": "cresce ogni volta",
      "rosso, blu, rosso, blu": "si ripete uguale",
      "1, 2, 4, 8": "cresce ogni volta",
      "cerchio, triangolo, cerchio, triangolo": "si ripete uguale",
    },
    explanation: "Le sequenze fanno due mestieri diversi: alcune vanno da qualche parte, altre girano in tondo. Prima di cercare «il numero dopo» conviene capire quale delle due si ha davanti, perche' le domande da farsi sono opposte." },
];

// ---------------------------------------------------------------------------
// MUSICA — 7 alla fascia 2
// ---------------------------------------------------------------------------
//
// Musica è materia di terza fascia e passa da uno a due esercizi: il suo pozzo
// alla fascia 2 era di ventitré item. Ordinare le dinamiche dal più piano al
// più forte, o smistare gli strumenti per famiglia, è quello che si fa davvero
// leggendo uno spartito — molto più che riconoscere una definizione.

const MUSICA = [
  { topic: "dinamica", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti le indicazioni di dinamica in ordine, dalla più piano alla più forte.",
    items: ["forte", "pianissimo", "mezzoforte", "piano"],
    correctOrder: ["pianissimo", "piano", "mezzoforte", "forte"],
    explanation: "«Mezzo» sta sempre in mezzo e il raddoppio della vocale spinge all'estremo: pianissimo è più piano di piano, fortissimo più forte di forte. Sono indicazioni relative, non misure — dicono più o meno dell'altra, non quanti decibel." },

  { topic: "note", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti le note in ordine, dalla più grave alla più acuta, dentro la stessa ottava.",
    items: ["mi", "do", "sol", "re"],
    correctOrder: ["do", "re", "mi", "sol"],
    explanation: "La scala sale sempre nello stesso ordine — do re mi fa sol la si — e ogni passo avanti è un suono più acuto. Sul pentagramma questo si vede: più la nota è in alto, più è acuta, e non c'è nessun caso in cui la regola si rovesci." },

  { topic: "ritmo", difficulty: 2, difficulty8: true, format: "ordering",
    prompt: "Metti le figure musicali in ordine, dalla più lunga alla più breve.",
    items: ["la croma", "la semibreve", "la semiminima", "la minima"],
    correctOrder: ["la semibreve", "la minima", "la semiminima", "la croma"],
    explanation: "Ogni figura dura la metà della precedente: quattro semiminime stanno in una semibreve. Il ritmo si legge così, per rapporti — quanto dura una nota rispetto all'altra — e non in secondi, che dipendono dalla velocità scelta." },

  { topic: "strumenti", difficulty: 2, difficulty8: true, format: "classification",
    prompt: "Smista ogni strumento nella sua famiglia.",
    items: ["il violino", "il flauto", "il tamburo", "la chitarra"],
    categories: ["corde", "fiati", "percussioni"],
    assignments: { "il violino": "corde", "il flauto": "fiati", "il tamburo": "percussioni", "la chitarra": "corde" },
    explanation: "La famiglia dice da dove nasce il suono: una corda che vibra, una colonna d'aria, una pelle o un corpo colpito. È la stessa cosa che decide il timbro, cioè perché due strumenti che suonano la stessa nota non si confondono." },

  { topic: "tempo", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni indicazione di tempo alla velocità che chiede.",
    pairs: [
      { left: "adagio", right: "lento, con calma" },
      { left: "andante", right: "come un passo tranquillo" },
      { left: "allegro", right: "veloce e vivace" },
      { left: "presto", right: "molto veloce" },
    ],
    explanation: "Sono parole italiane, e non per caso: la musica scritta ha preso il vocabolario da dove era nata la stampa musicale. «Andante» conserva ancora il suo senso letterale — la velocità di uno che cammina — ed è il modo migliore per ricordarla." },

  { topic: "note", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni segno al suo effetto sulla nota.",
    pairs: [
      { left: "il diesis", right: "alza la nota di un semitono" },
      { left: "il bemolle", right: "abbassa la nota di un semitono" },
      { left: "il bequadro", right: "riporta la nota com'era" },
      { left: "il punto di valore", right: "allunga la nota di metà" },
    ],
    explanation: "I primi tre agiscono sull'altezza, il quarto sulla durata: sono due cose diverse che il pentagramma scrive nello stesso posto. Il bequadro serve proprio perché diesis e bemolle valgono per tutta la battuta, non per la nota singola." },

  { topic: "ritmo", difficulty: 2, difficulty8: true, format: "numeric_input",
    prompt: "In una battuta di 4/4, quante crome ci stanno?",
    answer: "8",
    explanation: "Il 4/4 dice quattro movimenti da un quarto, cioè quattro semiminime; ogni semiminima vale due crome, quindi otto. Il numero sotto dice quale figura conta come un movimento, quello sopra quanti movimenti ha la battuta." },
];

// ---------------------------------------------------------------------------
// ELETTRONICA — 12 fra le fasce 5 e 8, tutte su «elettricita-base»
// ---------------------------------------------------------------------------
//
// Due buchi in uno.
//
// Il primo è il pozzo: la fascia 8 reggeva dodici sessioni invece di quindici.
//
// Il secondo è più grave e l'ha scoperto `difficulty_bands_audit` mentre il
// lotto veniva preparato: l'argomento `elettricita-base` esisteva **solo** fino
// alla fascia 4. Al mondo 17 l'esame lo pescava lo stesso e, non trovando
// niente nella finestra, ripiegava su un item di fascia 1 — una domanda da
// mondo 1 dentro l'esame del mondo 17. Non era un difetto della progressione:
// era un argomento che finiva a metà scala.
//
// Qui i formati restano scelta multipla e risposta libera, e non per pigrizia:
// `build_final_exam` scarta i nodi di elettronica che non siano `multiple_choice`
// o `short_answer`, perché nel mondo questa materia si impara montando e
// all'esame la sua prova misura il richiamo.

const ELETTRONICA = [
  // ------------------------------------------------------------- fascia 5
  { topic: "elettricita-base", difficulty: 5, difficulty8: true,
    prompt: "In un circuito la corrente è la stessa in ogni punto della maglia. Che cosa vuol dire per una lampadina messa in fila con un'altra?",
    answer: "riceve la stessa corrente dell'altra", distractors: ["riceve la metà della corrente dell'altra", "riceve corrente solo se è la prima", "riceve il doppio della corrente dell'altra"],
    explanation: "In serie la carica non ha strade alternative: quello che passa da una passa per forza anche dall'altra. A dividersi non è la corrente ma la tensione, ed è per questo che due lampadine in serie fanno meno luce ciascuna.",
    distractorWhy: {
      "riceve la metà della corrente dell'altra": "Si dimezzerebbe se ci fossero due strade, ma in serie la strada è una sola.",
      "riceve corrente solo se è la prima": "Nel circuito non c'è un ordine di precedenza: la corrente scorre tutta insieme.",
      "riceve il doppio della corrente dell'altra": "Non c'è nessun modo di far crescere la corrente lungo la maglia.",
    } },

  { topic: "elettricita-base", difficulty: 5, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama la grandezza che si misura in ampere?",
    answer: "corrente", accept: ["la corrente", "intensità di corrente", "corrente elettrica"],
    explanation: "L'ampere conta quanta carica passa in un secondo attraverso una sezione del filo. È un conteggio di quantità al secondo, come i litri al minuto di un rubinetto: per questo si parla di corrente che «scorre»." },

  // ------------------------------------------------------------- fascia 6
  { topic: "elettricita-base", difficulty: 6, difficulty8: true,
    prompt: "Una pila da 9 V alimenta un resistore da 3 ohm. Quanta corrente scorre?",
    answer: "3 A", distractors: ["27 A", "0,3 A", "6 A"],
    explanation: "La legge di Ohm lega le tre grandezze: la corrente è la tensione divisa per la resistenza, cioè 9 diviso 3. È la relazione che permette di prevedere un circuito prima di montarlo, invece di scoprirlo bruciando un componente.",
    distractorWhy: {
      "27 A": "È il prodotto invece del quoziente: moltiplicare darebbe una corrente enorme e priva di senso.",
      "0,3 A": "Sarebbe il risultato con una resistenza di 30 ohm, non di 3.",
      "6 A": "È la differenza fra 9 e 3: la legge di Ohm non sottrae, divide.",
    } },

  { topic: "elettricita-base", difficulty: 6, difficulty8: true,
    prompt: "Perché un filo molto sottile si scalda più di un filo grosso, a parità di corrente?",
    answer: "perché oppone più resistenza al passaggio", distractors: ["perché contiene più cariche libere al suo interno", "perché la tensione della pila aumenta da sola", "perché la corrente rallenta e si accumula in fondo"],
    explanation: "Meno sezione significa più resistenza, e la potenza dissipata in calore cresce con la resistenza a parità di corrente. È esattamente il principio del fusibile: un tratto volutamente sottile che si scioglie prima che bruci il resto dell'impianto.",
    distractorWhy: {
      "perché contiene più cariche libere al suo interno": "Un filo sottile ne contiene meno, non di più: è proprio questo a renderlo resistente.",
      "perché la tensione della pila aumenta da sola": "La pila non cambia da sé: la tensione ai suoi capi resta quella.",
      "perché la corrente rallenta e si accumula in fondo": "La carica non si accumula da nessuna parte: quello che entra esce.",
    } },

  // ------------------------------------------------------------- fascia 7
  { topic: "elettricita-base", difficulty: 7, difficulty8: true,
    prompt: "Due resistori uguali da 4 ohm sono in parallelo. Quanto vale la resistenza complessiva?",
    answer: "2 ohm", distractors: ["8 ohm", "4 ohm", "16 ohm"],
    explanation: "Aggiungere una strada in parallelo rende il passaggio più facile, non più difficile: con due vie identiche la resistenza si dimezza. È il motivo per cui attaccare troppi apparecchi alla stessa presa fa crescere la corrente totale invece di ridurla.",
    distractorWhy: {
      "8 ohm": "È la somma, che vale in serie: in parallelo la resistenza scende sempre.",
      "4 ohm": "Resterebbe uguale solo se il secondo resistore non fosse collegato.",
      "16 ohm": "È il prodotto dei due valori, che è solo un pezzo della formula del parallelo.",
    } },

  { topic: "elettricita-base", difficulty: 7, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama il componente che protegge un impianto interrompendosi quando la corrente supera un limite?",
    answer: "fusibile", accept: ["il fusibile", "fusibile di protezione"],
    explanation: "È un tratto di filo studiato per fondere prima degli altri: sacrifica sé stesso per salvare il resto. Sostituirlo con uno più «robusto» toglie esattamente la protezione per cui esiste, ed è il modo classico di causare un incendio." },

  { topic: "elettricita-base", difficulty: 7, difficulty8: true,
    prompt: "Un apparecchio consuma 2 A a 12 V. Quanta potenza assorbe?",
    answer: "24 W", distractors: ["6 W", "14 W", "10 W"],
    explanation: "La potenza è tensione per corrente. Questo prodotto dice quanta energia l'apparecchio consuma ogni secondo, ed è il numero che serve per scegliere l'alimentatore: non basta che la tensione sia giusta, deve reggere anche la corrente richiesta.",
    distractorWhy: {
      "6 W": "È 12 diviso 2: la potenza si ottiene moltiplicando, non dividendo.",
      "14 W": "È la somma dei due numeri, che non ha significato fisico.",
      "10 W": "È la differenza fra i due numeri, che non è una grandezza del circuito.",
    } },

  // ------------------------------------------------------------- fascia 8
  { topic: "elettricita-base", difficulty: 8, difficulty8: true,
    prompt: "Perché l'energia elettrica viaggia su lunghe distanze ad altissima tensione?",
    answer: "perché a parità di potenza serve meno corrente", distractors: ["perché l'alta tensione elimina del tutto la resistenza dei cavi", "perché i cavi lunghi funzionano solo sopra una tensione minima", "perché la corrente alta è vietata dalle leggi della fisica"],
    explanation: "Le perdite nei cavi dipendono dal quadrato della corrente, non dalla tensione. Alzando la tensione si può trasportare la stessa potenza con una corrente molto più bassa, e le perdite crollano: per questo esistono i trasformatori alle due estremità della linea.",
    distractorWhy: {
      "perché l'alta tensione elimina del tutto la resistenza dei cavi": "La resistenza del rame resta quella: cambia solo quanta corrente ci passa.",
      "perché i cavi lunghi funzionano solo sopra una tensione minima": "Funzionerebbero a qualunque tensione: sarebbero solo enormemente più dispersivi.",
      "perché la corrente alta è vietata dalle leggi della fisica": "Non è vietata: è costosa, perché scalda i cavi invece di arrivare a destinazione.",
    } },

  { topic: "elettricita-base", difficulty: 8, difficulty8: true,
    prompt: "In un circuito in serie una delle tre lampadine si fulmina. Che cosa succede alle altre due?",
    answer: "si spengono entrambe", distractors: ["restano accese con la stessa luce di prima", "restano accese ma più deboli di prima", "diventano più luminose di prima"],
    explanation: "In serie la corrente ha una strada sola: interrompere un punto qualsiasi interrompe tutto. È il difetto che ha fatto abbandonare le vecchie catene di luci in serie, dove una lampadina bruciata spegneva l'albero intero e bisognava provarle a una a una.",
    distractorWhy: {
      "restano accese con la stessa luce di prima": "Sarebbe vero in parallelo, dove ogni ramo è indipendente.",
      "restano accese ma più deboli di prima": "Non c'è nessuna corrente residua: il circuito è aperto.",
      "diventano più luminose di prima": "Succederebbe se la resistenza calasse, ma qui il passaggio si interrompe del tutto.",
    } },

  { topic: "elettricita-base", difficulty: 8, difficulty8: true, format: "short_answer",
    prompt: "Come si chiama la macchina che alza o abbassa la tensione alternata senza cambiare quasi nulla della potenza?",
    answer: "trasformatore", accept: ["il trasformatore", "trasformatore elettrico"],
    explanation: "Due avvolgimenti su uno stesso nucleo: il rapporto fra le spire decide il rapporto fra le tensioni, e la corrente cambia al contrario. Funziona solo in corrente alternata, ed è la ragione tecnica per cui la rete elettrica non è in continua." },

  { topic: "elettricita-base", difficulty: 8, difficulty8: true,
    prompt: "Perché toccare un filo scoperto è pericoloso soprattutto se hai le mani bagnate?",
    answer: "perché l'acqua abbassa la resistenza del corpo", distractors: ["perché l'acqua aumenta la tensione della rete elettrica", "perché l'acqua produce corrente per conto proprio", "perché l'acqua trattiene la carica sulla pelle senza lasciarla uscire"],
    explanation: "La pelle asciutta è un pessimo conduttore e limita la corrente che attraversa il corpo; bagnata, quella barriera cade e la stessa tensione fa passare molta più corrente. Il danno lo fa la corrente attraverso il corpo, non la tensione in sé.",
    distractorWhy: {
      "perché l'acqua aumenta la tensione della rete elettrica": "La tensione della rete è fissa: l'acqua non può cambiarla.",
      "perché l'acqua produce corrente per conto proprio": "L'acqua non è una sorgente: al massimo conduce quella che c'è.",
      "perché l'acqua trattiene la carica sulla pelle senza lasciarla uscire": "È il contrario: facilita il passaggio attraverso il corpo invece di trattenerlo.",
    } },

  { topic: "elettricita-base", difficulty: 8, difficulty8: true,
    prompt: "Una resistenza da 6 ohm e una da 3 ohm sono in serie su una pila da 18 V. Quanta tensione cade sulla resistenza da 6 ohm?",
    answer: "12 V", distractors: ["9 V", "6 V", "18 V"],
    explanation: "In serie la corrente è unica — 18 diviso 9 fa 2 A — e la tensione si divide in proporzione alla resistenza: 2 A per 6 ohm dà 12 V. È il partitore di tensione, il modo più semplice per ricavare da una pila una tensione più bassa.",
    distractorWhy: {
      "9 V": "Sarebbe la metà esatta, cioè il caso in cui le due resistenze fossero uguali.",
      "6 V": "È la tensione che cade sull'altra resistenza, quella da 3 ohm.",
      "18 V": "È tutta la tensione della pila: cadrebbe lì solo se l'altra resistenza non ci fosse.",
    } },
];

// ---------------------------------------------------------------------------
// LATINO — 1 alla fascia 2, 3 alla fascia 8
// ---------------------------------------------------------------------------
//
// Il latino era quasi in regola: mancavano un item alla fascia 2 e tre alla
// fascia 8. Restano dentro il vincolo già scritto per questa materia — nessuna
// domanda di FORMA senza una tavola di paradigma su cui impararla — quindi
// chiedono funzione e ragionamento, non desinenze da ricordare a vuoto.

const LATINO = [
  { topic: "casi", difficulty: 2, difficulty8: true, format: "matching",
    prompt: "Abbina ogni caso latino alla funzione che svolge nella frase.",
    pairs: [
      { left: "nominativo", right: "chi compie l'azione" },
      { left: "accusativo", right: "chi o che cosa subisce l'azione" },
      { left: "genitivo", right: "di chi o di che cosa" },
      { left: "vocativo", right: "chi viene chiamato" },
    ],
    explanation: "In latino la funzione non la decide la posizione nella frase ma la desinenza: per questo l'ordine delle parole può cambiare senza che cambi il senso. È il contrario dell'italiano, dove «il cane morde l'uomo» e «l'uomo morde il cane» differiscono solo per l'ordine." },

  { topic: "frasi", difficulty: 8, difficulty8: true, format: "ordering",
    prompt: "Metti in ordine i passi per tradurre una frase latina senza andare a intuito.",
    items: ["cerca il verbo e guarda persona e numero", "collega gli altri casi al loro ruolo", "cerca il soggetto al nominativo, che concorda col verbo", "trova il complemento oggetto all'accusativo"],
    correctOrder: ["cerca il verbo e guarda persona e numero", "cerca il soggetto al nominativo, che concorda col verbo", "trova il complemento oggetto all'accusativo", "collega gli altri casi al loro ruolo"],
    explanation: "Si parte sempre dal verbo perché è lui a dire quante persone servono e di che tipo: un verbo transitivo pretende un accusativo, uno intransitivo no. Cominciare dalla prima parola della frase è l'errore che fa tradurre a caso, perché in latino la prima parola può essere qualunque cosa." },

  { topic: "declinazione-5", difficulty: 8, difficulty8: true, format: "matching",
    prompt: "Abbina ogni declinazione al genitivo singolare che la riconosce.",
    pairs: [
      { left: "prima declinazione", right: "esce in -ae" },
      { left: "seconda declinazione", right: "esce in -i" },
      { left: "terza declinazione", right: "esce in -is" },
      { left: "quinta declinazione", right: "esce in -ei" },
    ],
    explanation: "Il genitivo singolare è la carta d'identità del nome: il vocabolario lo mette apposta accanto al nominativo, perché è l'unica forma che distingue con certezza le cinque declinazioni. Il nominativo da solo può ingannare — «manus» e «dominus» finiscono uguali e non sono della stessa." },

  { topic: "declinazione-4", difficulty: 8, difficulty8: true, format: "classification",
    prompt: "Smista ogni nome secondo la declinazione a cui appartiene, guardando il genitivo indicato.",
    items: ["rosa, rosae", "dominus, domini", "consul, consulis", "manus, manus"],
    categories: ["prima", "seconda", "terza", "quarta"],
    assignments: { "rosa, rosae": "prima", "dominus, domini": "seconda", "consul, consulis": "terza", "manus, manus": "quarta" },
    explanation: "Si guarda solo la seconda forma: -ae, -i, -is, -us. «Manus, manus» è il caso che mette alla prova — nominativo e genitivo identici — e proprio quella coincidenza è il segno della quarta declinazione, non un errore di stampa." },
];

export const SESSIONI_LUNGHE = {
  coding: CODING,
  storia: STORIA,
  logica: LOGICA,
  musica: MUSICA,
  elettronica: ELETTRONICA,
  latino: LATINO,
};
