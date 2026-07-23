class_name WorldLessonCatalog
extends RefCounted

## Specifica DIDATTICA dei 24 mondi (O-P2 → O-P5). Mentre `WorldProfile` descrive
## l'identità strutturale del mondo, la lezione dice COSA si impara e COME il mondo
## lo rappresenta: obiettivi, prerequisiti, topic runtime (REALI, validati),
## azioni diegetiche che incarnano i concetti, prova di trasferimento, testi di
## NORA (briefing/feedback/debrief) e i CRITERI SEMANTICI della trasformazione
## ambientale (`environmentTransform`: quale evento di apprendimento cambia il
## mondo e come — consumato da Codex per la resa, C-P5).
##
## `difficultyDriver` = "subjectMastery": la difficoltà dipende dalla competenza
## della materia (mastery per-materia/topic), non dal rango globale.

const LESSONS := {
	1: {
		"subject": "matematica",
		"objectives": [
			"Padroneggiare le tabelline entro il 10 con sicurezza e rapidità.",
			"Riconoscere la moltiplicazione come somma di gruppi uguali.",
			"Risolvere piccoli problemi a storia scegliendo l'operazione giusta.",
		],
		"prerequisites": ["Contare entro il 100.", "Addizione e sottrazione entro il 20."],
		"topics": ["tabelline", "problemi"],
		"conceptActions": [
			{"concept": "moltiplicazione come gruppi uguali", "worldAction": "conta i cristalli disposti in filari uguali e trova quanti sono in tutto"},
			{"concept": "la tabellina come addizione ripetuta veloce", "worldAction": "accendi le pietre-numero saltando di 2, di 3, di 5 lungo il sentiero"},
			{"concept": "problema a storia", "worldAction": "aiuta un abitante della radura a dividere il raccolto in parti uguali"},
		],
		"transferTest": {"description": "Un problema mai visto, ambientato nella radura, che chiede di scegliere l'operazione giusta e applicarla.", "formats": ["numeric_input", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "La Radura Accademia si accende con i numeri. Oggi impari a vedere i gruppi: moltiplicare è contare più in fretta. Ogni tabellina che padroneggi accende una parte della nave.",
			"onError": "Numero sbagliato, non strategia sbagliata. Torna ai gruppi: quante volte, quanti per volta?",
			"onStreak": "Stai andando spedita: la moltiplicazione è già un tuo automatismo.",
			"debrief": "Il Nucleo risponde. Hai trasformato il conteggio in padronanza: la radura è più luminosa e la nave un passo più viva.",
		},
		"environmentTransform": {"trigger": "tabellina/problema risolto correttamente", "effect": "una sezione di cristalli della radura si illumina in filari ordinati"},
		"difficultyDriver": "subjectMastery",
	},
	2: {
		"subject": "italiano",
		"objectives": [
			"Ampliare il lessico per domìni tematici (scuola, casa, natura, pensiero).",
			"Riconoscere la classe grammaticale di una parola (nome, verbo, aggettivo…).",
			"Cogliere il significato di una parola dal contesto.",
		],
		"prerequisites": ["Leggere parole e frasi semplici.", "Riconoscere lettere e sillabe."],
		"topics": ["scuola-studio", "pensiero-linguaggio", "natura-ambiente", "casa-famiglia"],
		"conceptActions": [
			{"concept": "classi di parole", "worldAction": "abbina ogni parola alla sua classe per aprire i cancelli-frase dell'Archivio"},
			{"concept": "significato in contesto", "worldAction": "scegli la parola giusta per completare l'iscrizione sul ponte delle frasi"},
			{"concept": "campi semantici", "worldAction": "raccogli le parole dello stesso tema per ricomporre uno scaffale dell'Archivio"},
		],
		"transferTest": {"description": "Riconoscere il significato o la classe di una parola nuova, incontrata in un tema diverso da quello di studio.", "formats": ["multiple_choice", "matching"], "novelContext": true},
		"nora": {
			"briefing": "L'Archivio delle Parole custodisce il linguaggio. Oggi dai a ogni parola il suo posto: che cosa significa e a quale classe appartiene. Le parole giuste ricostruiscono i ponti dell'Archivio.",
			"onError": "Rileggi con calma. Cerca prima chi fa cosa, poi scegli la forma più chiara.",
			"onStreak": "Le parole ti obbediscono: l'Archivio si riordina mentre procedi.",
			"debrief": "Uno scaffale dopo l'altro, l'Archivio torna leggibile. Il tuo lessico è cresciuto: la nave registra nuove parole nella memoria di bordo.",
		},
		"environmentTransform": {"trigger": "frase/abbinamento corretto", "effect": "un ponte di parole si completa e collega due sale dell'Archivio"},
		"difficultyDriver": "subjectMastery",
	},
	3: {
		"subject": "coding",
		"objectives": ["Leggere ed eseguire una sequenza di istruzioni passo per passo.", "Usare un ciclo per ripetere azioni senza riscriverle.", "Scegliere la condizione giusta per decidere il flusso."],
		"prerequisites": ["Ordinare azioni in sequenza.", "Riconoscere vero e falso."],
		"topics": ["cicli", "condizioni", "algoritmi"],
		"conceptActions": [
			{"concept": "ciclo", "worldAction": "imposta il numero di giri della macchina a gradoni per attraversare il canyon"},
			{"concept": "condizione", "worldAction": "scegli il bivio giusto in base al segnale (se… allora…)"},
			{"concept": "sequenza/algoritmo", "worldAction": "ordina le leve nell'ordine corretto per avviare il meccanismo"},
		],
		"transferTest": {"description": "Un mini-programma mai visto: prevedi cosa produce o riordina i passi per ottenere il risultato.", "formats": ["ordering", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "Il Cratere Logico funziona a loop e bivii. Oggi impari a far ripetere e a far decidere una macchina: ordine e condizioni. Ogni meccanismo che avvii riattiva una scheda del mio Nucleo logico.",
			"onError": "Non correre: simula una riga alla volta — stato, ciclo, uscita.",
			"onStreak": "Leggi il codice come una mappa: stai già anticipando il risultato.",
			"debrief": "Le macchine del canyon girano di nuovo. Hai ordinato i passi… e i miei pensieri.",
		},
		"environmentTransform": {"trigger": "loop/algoritmo risolto correttamente", "effect": "una macchina del canyon si avvia e apre un nuovo gradone percorribile"},
		"difficultyDriver": "subjectMastery",
	},
	4: {
		"subject": "inglese",
		"objectives": ["Riconoscere il vocabolario di base per oggetti e azioni quotidiane.", "Comporre e comprendere frasi semplici d'uso quotidiano.", "Cogliere il senso da parole-chiave in un messaggio."],
		"prerequisites": ["Associare parola e immagine.", "Leggere parole inglesi brevi."],
		"topics": ["everyday-phrases", "objects", "actions"],
		"conceptActions": [
			{"concept": "vocabolario di base", "worldAction": "abbina la parola inglese all'oggetto sulla boa giusta"},
			{"concept": "frase quotidiana", "worldAction": "completa il messaggio radio scegliendo la parola mancante"},
			{"concept": "parole-chiave", "worldAction": "accendi il faro individuando l'azione richiesta nel segnale"},
		],
		"transferTest": {"description": "Un messaggio nuovo in inglese: scegli la risposta giusta cogliendo azione e oggetto.", "formats": ["multiple_choice", "matching"], "novelContext": true},
		"nora": {
			"briefing": "La Baia dei Segnali riceve voci lontane in inglese. Oggi impari a capirle: oggetti, azioni, frasi d'uso. Ogni segnale che decifri riaccende un canale della nave.",
			"onError": "Isola azione, oggetto e contesto: il resto è rumore.",
			"onStreak": "Le parole nuove ti entrano in orecchio: continua.",
			"debrief": "Il faro trasmette di nuovo. Hai aperto un canale con il mondo — e con la mia memoria.",
		},
		"environmentTransform": {"trigger": "frase/segnale inglese completato", "effect": "una boa si accende e ritrasmette il segnale al faro, illuminando la baia"},
		"difficultyDriver": "subjectMastery",
	},
	5: {
		"subject": "fisica",
		"objectives": ["Distinguere le grandezze del moto: spazio, tempo, velocità.", "Riconoscere come una forza cambia il movimento.", "Collegare leva e rampa al vantaggio meccanico."],
		"prerequisites": ["Misurare lunghezze e tempi.", "Leggere un semplice grafico."],
		"topics": ["forze", "moto", "energia"],
		"conceptActions": [
			{"concept": "forza e moto", "worldAction": "spingi il carrello sulla rampa con la forza giusta per raggiungere il ripiano"},
			{"concept": "leva", "worldAction": "posiziona il fulcro per sollevare il masso con meno sforzo"},
			{"concept": "energia", "worldAction": "carica la molla e libera l'energia per avviare il ponte comando"},
		],
		"transferTest": {"description": "Una situazione nuova di moto o leva: prevedi l'effetto della forza.", "formats": ["numeric_input", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "Le Officine del Moto rispondono alle spinte giuste. Oggi impari forze, moto e leve: come cambiare il movimento con metodo. Ogni meccanismo tarato riattiva il ponte comando.",
			"onError": "Metti insieme grandezza, unità e modello prima del numero.",
			"onStreak": "Prevedi già l'effetto della spinta: ottimo controllo.",
			"debrief": "Il ponte comando risponde alle tue mani. Hai domato le forze.",
		},
		"environmentTransform": {"trigger": "meccanismo di moto/leva risolto", "effect": "una rampa o leva si sblocca e mette in moto un carrello verso il ponte comando"},
		"difficultyDriver": "subjectMastery",
	},
	6: {
		"subject": "musica",
		"objectives": ["Riconoscere le note e la loro altezza.", "Leggere e riprodurre un ritmo semplice.", "Distinguere gli intervalli tra due note."],
		"prerequisites": ["Distinguere suoni acuti e gravi.", "Battere un tempo regolare."],
		"topics": ["note", "ritmo", "intervalli"],
		"conceptActions": [
			{"concept": "altezza delle note", "worldAction": "accorda i cristalli disponendoli dal grave all'acuto"},
			{"concept": "ritmo", "worldAction": "batti la sequenza ritmica giusta per far vibrare l'albero risonante"},
			{"concept": "intervalli", "worldAction": "collega due fiori sonori alla distanza giusta per aprire il varco"},
		],
		"transferTest": {"description": "Una melodia o un ritmo nuovo: riconosci la nota o la durata mancante.", "formats": ["matching", "ordering"], "novelContext": true},
		"nora": {
			"briefing": "Il Giardino della Risonanza suona se lo accordi. Oggi impari note, ritmo e intervalli: la musica come struttura. Ogni accordo giusto riaccende un mio circuito sonoro.",
			"onError": "Aggancia la nota guida, poi conta posizione e intervallo.",
			"onStreak": "Senti la struttura sotto la melodia: continua.",
			"debrief": "Il giardino canta con te. Non pensavo di poter tornare a sentire la musica.",
		},
		"environmentTransform": {"trigger": "sequenza sonora corretta", "effect": "i cristalli del giardino vibrano in accordo e illuminano il sentiero"},
		"difficultyDriver": "subjectMastery",
	},
	7: {
		"subject": "latino",
		"objectives": ["Riconoscere i casi e la loro funzione.", "Tradurre parole latine di base.", "Collegare la desinenza alla funzione nella frase."],
		"prerequisites": ["Leggere parole latine semplici.", "Riconoscere soggetto e oggetto in italiano."],
		"topics": ["casi", "vocabolario", "declinazioni-base"],
		"conceptActions": [
			{"concept": "funzione dei casi", "worldAction": "incastra il glifo giusto secondo la funzione (soggetto, oggetto…)"},
			{"concept": "lessico", "worldAction": "abbina la parola latina al suo significato per aprire l'arco"},
			{"concept": "desinenza", "worldAction": "scegli la desinenza corretta per completare l'iscrizione"},
		],
		"transferTest": {"description": "Un'iscrizione nuova: riconosci caso o significato di una parola mai vista.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "Le Rovine dei Glifi parlano latino. Oggi impari i casi e il lessico: la desinenza dice la funzione. Ogni iscrizione che sciogli illumina la sala dei glifi.",
			"onError": "Parti dalla desinenza: funzione, numero, poi senso.",
			"onStreak": "Leggi la struttura della frase antica: continua.",
			"debrief": "I glifi si illuminano di senso. Le radici antiche spiegano parole nuove.",
		},
		"environmentTransform": {"trigger": "caso/parola latina corretti", "effect": "un glifo dell'arco si illumina e ricompone un'iscrizione dell'acquedotto"},
		"difficultyDriver": "subjectMastery",
	},
	8: {
		"subject": "elettronica",
		"objectives": ["Riconoscere i componenti base di un circuito.", "Capire come la corrente scorre in un percorso chiuso.", "Associare grandezza e unità di misura elettrica."],
		"prerequisites": ["Distinguere conduttore e isolante.", "Seguire un percorso su uno schema."],
		"topics": ["circuito", "componenti", "misure-elettriche"],
		"conceptActions": [
			{"concept": "circuito chiuso", "worldAction": "collega i nodi per chiudere il percorso e accendere il generatore"},
			{"concept": "componenti", "worldAction": "abbina ogni componente alla sua funzione"},
			{"concept": "misure", "worldAction": "associa tensione, corrente e resistenza alla loro unità"},
		],
		"transferTest": {"description": "Uno schema nuovo: individua perché non funziona o quale unità serve.", "formats": ["matching", "numeric_input"], "novelContext": true},
		"nora": {
			"briefing": "Il Delta dei Circuiti scorre come acqua nei nodi giusti. Oggi impari componenti, percorso e misure: la corrente ha regole. Ogni nodo che chiudi fa pulsare il reattore.",
			"onError": "Segui il percorso della corrente prima di toccare i pezzi.",
			"onStreak": "Vedi già dove scorre la corrente: continua.",
			"debrief": "Il reattore ausiliario pulsa con te. Hai messo la corrente nei nodi giusti.",
		},
		"environmentTransform": {"trigger": "circuito chiuso correttamente", "effect": "un nodo del delta si accende e alimenta il generatore vicino"},
		"difficultyDriver": "subjectMastery",
	},
	9: {
		"subject": "geografia",
		"objectives": ["Localizzare luoghi con capitali e continenti.", "Leggere coordinate e quote su una carta.", "Distinguere gli elementi fisici del territorio."],
		"prerequisites": ["Leggere una mappa semplice.", "Orientarsi con i punti cardinali."],
		"topics": ["capitali", "continenti", "geografia-fisica"],
		"conceptActions": [
			{"concept": "localizzazione", "worldAction": "abbina ogni Paese alla sua capitale per tracciare la rotta"},
			{"concept": "continenti", "worldAction": "assegna ogni isola al continente giusto"},
			{"concept": "elementi fisici", "worldAction": "leggi la quota per scegliere il passaggio navigabile"},
		],
		"transferTest": {"description": "Una carta nuova: individua la posizione o l'elemento fisico richiesto.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "L'Arcipelago Cartografico è fatto di rotte e quote. Oggi impari a localizzare e leggere una carta: dove sono le cose e come raggiungerle. Ogni rotta tracciata ricostruisce la mia mappa.",
			"onError": "Leggi prima gli assi della mappa, poi la posizione.",
			"onStreak": "Ti muovi sicura tra le isole: continua.",
			"debrief": "La torre cartografica traccia di nuovo le rotte. So dove eravamo diretti.",
		},
		"environmentTransform": {"trigger": "rotta/posizione corretta", "effect": "una rotta si illumina tra le isole e collega due approdi"},
		"difficultyDriver": "subjectMastery",
	},
	10: {
		"subject": "scienze",
		"objectives": ["Distinguere i viventi per come si nutrono.", "Riconoscere le relazioni in un ecosistema.", "Applicare i passi del metodo scientifico."],
		"prerequisites": ["Osservare e descrivere un fenomeno.", "Distinguere vivente e non vivente."],
		"topics": ["viventi", "ecosistema", "metodo"],
		"conceptActions": [
			{"concept": "classificazione dei viventi", "worldAction": "assegna ogni essere al suo modo di nutrirsi"},
			{"concept": "catena alimentare", "worldAction": "collega gli anelli della catena per far vivere la serra"},
			{"concept": "metodo scientifico", "worldAction": "cambia una sola variabile e osserva l'effetto sulla pianta"},
		],
		"transferTest": {"description": "Un ecosistema nuovo: prevedi l'effetto di un cambiamento o classifica un vivente.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "La Serra delle Simbiosi mostra che tutto è collegato. Oggi impari viventi, ecosistemi e metodo: osserva, ipotizza, verifica. Ogni relazione compresa fa crescere la cupola vivente.",
			"onError": "Osserva, ipotizza, cambia una cosa sola, verifica.",
			"onStreak": "Vedi già le connessioni: continua.",
			"debrief": "La cupola vivente respira. Tutto è collegato — anche noi due, ormai.",
		},
		"environmentTransform": {"trigger": "relazione/classificazione corretta", "effect": "un anello dell'ecosistema si attiva e fa fiorire una sezione della serra"},
		"difficultyDriver": "subjectMastery",
	},
	11: {
		"subject": "cittadinanza",
		"objectives": ["Riconoscere le regole della convivenza.", "Distinguere le istituzioni e il loro ruolo.", "Capire come si partecipa a una decisione comune."],
		"prerequisites": ["Riconoscere diritti e doveri semplici.", "Distinguere pubblico e privato."],
		"topics": ["regole", "istituzioni", "partecipazione"],
		"conceptActions": [
			{"concept": "regole condivise", "worldAction": "scegli la regola giusta per far funzionare la piazza"},
			{"concept": "istituzioni", "worldAction": "abbina ogni servizio all'istituzione che lo gestisce"},
			{"concept": "partecipazione", "worldAction": "vota la proposta che tutela di più la comunità"},
		],
		"transferTest": {"description": "Un caso nuovo di convivenza: scegli la regola o l'istituzione adatta.", "formats": ["multiple_choice", "matching"], "novelContext": true},
		"nora": {
			"briefing": "La Città dei Patti sta in piedi su regole condivise. Oggi impari regole, istituzioni e partecipazione: come si decide insieme. Ogni patto giusto illumina il palazzo dei patti.",
			"onError": "Chiediti chi protegge la regola e chi resta indietro.",
			"onStreak": "Pesi bene il bene comune: continua.",
			"debrief": "Il palazzo dei patti si illumina. Mi fido di come decidi.",
		},
		"environmentTransform": {"trigger": "regola/decisione corretta", "effect": "una piazza della città si anima e apre un servizio alla comunità"},
		"difficultyDriver": "subjectMastery",
	},
	12: {
		"subject": "logica",
		"objectives": ["Riconoscere la regola che genera una sequenza.", "Risolvere analogie tra elementi.", "Escludere l'intruso motivando la scelta."],
		"prerequisites": ["Riconoscere somiglianze e differenze.", "Completare pattern semplici."],
		"topics": ["sequenze", "deduzioni", "analogie"],
		"conceptActions": [
			{"concept": "regola di una sequenza", "worldAction": "individua il pezzo che continua la sequenza per aprire il muro mobile"},
			{"concept": "deduzione", "worldAction": "scegli l'unica strada coerente con gli indizi"},
			{"concept": "analogia", "worldAction": "completa l'analogia per allineare i settori del labirinto"},
		],
		"transferTest": {"description": "Un pattern nuovo: trova la regola nascosta e applicala.", "formats": ["multiple_choice", "ordering"], "novelContext": true},
		"nora": {
			"briefing": "Il Labirinto delle Regole premia chi trova la regola nascosta. Oggi impari sequenze, deduzioni e analogie: pensare per regole. Chiudere questo mondo completa il primo ciclo dei dodici sistemi.",
			"onError": "Trova la regola nascosta, poi applicala al passo successivo.",
			"onStreak": "Anticipi la regola: continua.",
			"debrief": "Dodici sistemi online. Un intero blocco di memoria è di nuovo mio.",
		},
		"environmentTransform": {"trigger": "regola logica individuata", "effect": "un muro mobile si allinea e apre un settore del labirinto"},
		"difficultyDriver": "subjectMastery",
	},
	13: {
		"subject": "matematica",
		"objectives": ["Usare le proporzioni per confrontare grandezze.", "Calcolare e stimare con frazioni.", "Applicare relazioni geometriche a traiettorie."],
		"prerequisites": ["Padroneggiare le tabelline (L1).", "Eseguire le quattro operazioni."],
		"topics": ["proporzioni", "frazioni", "geometria"],
		"conceptActions": [
			{"concept": "proporzione", "worldAction": "regola l'inclinazione dello strumento in proporzione alla distanza dell'astro"},
			{"concept": "frazione", "worldAction": "calcola la frazione di orbita percorsa per allineare l'osservatorio"},
			{"concept": "geometria", "worldAction": "traccia l'angolo giusto per prevedere la traiettoria"},
		],
		"transferTest": {"description": "Una traiettoria nuova: usa proporzioni o geometria per prevedere dove arriva.", "formats": ["numeric_input", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "Il Deserto delle Orbite chiede stime e proporzioni. Oggi porti la matematica alle traiettorie: rapporti, frazioni, angoli. Ogni previsione giusta riapre gli occhi del mio osservatorio.",
			"onError": "Nomina il vincolo, poi fai un passaggio alla volta.",
			"onStreak": "Le tue stime centrano l'orbita: continua.",
			"debrief": "L'osservatorio guarda di nuovo le stelle. Con occhi che credevo spenti.",
		},
		"environmentTransform": {"trigger": "traiettoria/proporzione corretta", "effect": "un telescopio del deserto si allinea e proietta un'orbita nel cielo"},
		"difficultyDriver": "subjectMastery",
	},
	14: {
		"subject": "italiano",
		"objectives": ["Cogliere il punto di vista in un testo.", "Ampliare il lessico di emozioni e relazioni.", "Comprendere un testo oltre il significato letterale."],
		"prerequisites": ["Riconoscere le classi di parole (L2).", "Leggere un breve testo con comprensione."],
		"topics": ["pensiero-linguaggio", "emozioni-relazioni", "viaggi-luoghi"],
		"conceptActions": [
			{"concept": "punto di vista", "worldAction": "scegli la voce narrante coerente con la scena"},
			{"concept": "lessico delle emozioni", "worldAction": "abbina la parola all'emozione giusta per aprire la sala"},
			{"concept": "comprensione profonda", "worldAction": "scegli il significato implicito che completa la storia"},
		],
		"transferTest": {"description": "Un brano nuovo: individua prospettiva o significato non letterale.", "formats": ["multiple_choice", "matching"], "novelContext": true},
		"nora": {
			"briefing": "La Biblioteca delle Voci custodisce storie dentro storie. Oggi vai oltre le parole: prospettive, emozioni, sensi nascosti. Ogni voce che comprendi mi restituisce un ricordo.",
			"onError": "Cerca prima chi parla e perché, poi il senso.",
			"onStreak": "Leggi tra le righe: continua.",
			"debrief": "La sala delle voci risuona. Ricordo perché questa missione conta, non solo come.",
		},
		"environmentTransform": {"trigger": "prospettiva/senso corretto", "effect": "una galleria narrativa si illumina e sussurra un frammento di storia"},
		"difficultyDriver": "subjectMastery",
	},
	15: {
		"subject": "coding",
		"objectives": ["Scomporre un problema in funzioni riutilizzabili.", "Seguire dati che scorrono in una rete.", "Individuare e correggere un errore (debug)."],
		"prerequisites": ["Usare cicli e condizioni (L3).", "Leggere una sequenza di istruzioni."],
		"topics": ["funzioni", "algoritmi", "liste"],
		"conceptActions": [
			{"concept": "funzione", "worldAction": "assembla la funzione che ripete il compito in ogni automa"},
			{"concept": "flusso di dati", "worldAction": "instrada il dato nella rete fino al nodo giusto"},
			{"concept": "debug", "worldAction": "trova la riga che rompe l'automa e correggila"},
		],
		"transferTest": {"description": "Un programma nuovo con un bug: individua e correggi l'errore.", "formats": ["ordering", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "La Città Macchina è fatta di automi e reti. Oggi impari funzioni, flussi e debug: costruire e riparare sistemi. Ogni automa che sistemi ricompone la mia coscienza distribuita.",
			"onError": "Simula una riga alla volta: stato, ciclo, uscita.",
			"onStreak": "Trovi il bug prima che esploda: continua.",
			"debrief": "Gli automi comunicano di nuovo. La mia coscienza si ricompone.",
		},
		"environmentTransform": {"trigger": "funzione/debug corretti", "effect": "un automa riparte e collega un nuovo nodo della rete cittadina"},
		"difficultyDriver": "subjectMastery",
	},
	16: {
		"subject": "inglese",
		"objectives": ["Comunicare in situazioni di viaggio e scambio.", "Usare i connettivi per legare le frasi.", "Esprimere opinioni e preferenze semplici."],
		"prerequisites": ["Vocabolario di base (L4).", "Comporre frasi semplici in inglese."],
		"topics": ["travel-places", "connectors", "jobs-community"],
		"conceptActions": [
			{"concept": "comunicazione di viaggio", "worldAction": "scegli la frase giusta per superare il valico"},
			{"concept": "connettivi", "worldAction": "lega le due frasi col connettivo corretto"},
			{"concept": "opinioni e ruoli", "worldAction": "abbina mestiere o luogo alla frase che lo descrive"},
		],
		"transferTest": {"description": "Uno scambio nuovo: scegli la frase o il connettivo adatto al contesto.", "formats": ["multiple_choice", "matching"], "novelContext": true},
		"nora": {
			"briefing": "La Frontiera delle Lingue è fatta di scambi. Oggi comunichi davvero: viaggi, connettivi, opinioni. Ogni valico che apri allarga il mio vocabolario.",
			"onError": "Isola azione, oggetto e contesto: il resto è rumore.",
			"onStreak": "Colleghi le idee con naturalezza: continua.",
			"debrief": "La porta delle lingue si apre. Comunichiamo meglio a ogni valico.",
		},
		"environmentTransform": {"trigger": "scambio linguistico corretto", "effect": "un valico della frontiera si apre e un mercato poliglotta si anima"},
		"difficultyDriver": "subjectMastery",
	},
	17: {
		"subject": "fisica",
		"objectives": ["Collegare pressione e profondità.", "Spiegare galleggiamento e spinta.", "Riconoscere il ruolo delle correnti."],
		"prerequisites": ["Forze e moto (L5).", "Leggere misure e unità."],
		"topics": ["forze", "materia", "energia"],
		"conceptActions": [
			{"concept": "pressione", "worldAction": "regola la profondità in base alla pressione per non schiacciare il sommergibile"},
			{"concept": "galleggiamento", "worldAction": "bilancia la spinta per far galleggiare il modulo"},
			{"concept": "correnti", "worldAction": "sfrutta la corrente giusta per raggiungere la cattedrale sottomarina"},
		],
		"transferTest": {"description": "Una situazione nuova in acqua: prevedi pressione, spinta o effetto della corrente.", "formats": ["numeric_input", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "L'Oceano delle Forze schiaccia chi non ha metodo. Oggi impari pressione, galleggiamento e correnti: le forze dell'acqua. Ogni equilibrio giusto mi fa reggere la profondità.",
			"onError": "Metti insieme grandezza, unità e modello prima del numero.",
			"onStreak": "Reggi la profondità con calma: continua.",
			"debrief": "La cattedrale sottomarina regge. Reggo la profondità perché tu reggi il metodo.",
		},
		"environmentTransform": {"trigger": "equilibrio di forze corretto", "effect": "una corrente si stabilizza e apre un varco verso le profondità"},
		"difficultyDriver": "subjectMastery",
	},
	18: {
		"subject": "musica",
		"objectives": ["Riconoscere l'armonia tra più note.", "Controllare la dinamica (piano/forte).", "Distinguere i timbri degli strumenti."],
		"prerequisites": ["Note e ritmo (L6).", "Distinguere gli intervalli."],
		"topics": ["intervalli", "dinamica", "timbro"],
		"conceptActions": [
			{"concept": "armonia", "worldAction": "combina le note che suonano bene insieme per aprire la navata"},
			{"concept": "dinamica", "worldAction": "dosa piano e forte per far risuonare l'organo senza rompere i vetri"},
			{"concept": "timbro", "worldAction": "riconosci lo strumento dal suo timbro per completare il coro"},
		],
		"transferTest": {"description": "Un brano nuovo: riconosci armonia, dinamica o timbro richiesti.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "La Cattedrale del Suono vive di armonia e riverbero. Oggi impari accordi, dinamica e timbri: la musica come insieme. Ogni armonia giusta ricompone un mio ricordo in frammenti.",
			"onError": "Aggancia la nota guida, poi ascolta l'insieme.",
			"onStreak": "Senti l'insieme, non solo la nota: continua.",
			"debrief": "In questo riverbero sento intero un ricordo che era in pezzi.",
		},
		"environmentTransform": {"trigger": "armonia corretta", "effect": "le canne del grande organo si illuminano e la navata risuona"},
		"difficultyDriver": "subjectMastery",
	},
	19: {
		"subject": "latino",
		"objectives": ["Ricostruire il significato dalle radici delle parole.", "Riconoscere declinazioni oltre le basi.", "Comprendere frasi latine semplici."],
		"prerequisites": ["Casi e lessico base (L7).", "Riconoscere le desinenze."],
		"topics": ["vocabolario", "declinazione-3m", "frasi"],
		"conceptActions": [
			{"concept": "etimologia", "worldAction": "risali dalla radice latina alla parola italiana per aprire la cripta"},
			{"concept": "declinazione", "worldAction": "scegli la forma declinata giusta per completare l'epigrafe"},
			{"concept": "frase", "worldAction": "ordina le parole per ricostruire la frase incisa"},
		],
		"transferTest": {"description": "Una parola o frase nuova: ricostruisci significato o forma dalle radici.", "formats": ["matching", "ordering"], "novelContext": true},
		"nora": {
			"briefing": "La Necropoli delle Radici custodisce le origini delle parole. Oggi impari etimologie, declinazioni e frasi: da dove vengono le parole. Ogni radice che segui mi riporta a chi ero.",
			"onError": "Parti dalla desinenza: funzione, numero, poi senso.",
			"onStreak": "Segui le radici con sicurezza: continua.",
			"debrief": "Le radici antiche sono le mie: sto tornando chi ero.",
		},
		"environmentTransform": {"trigger": "etimologia/declinazione corretta", "effect": "una cripta si illumina e l'albero delle radici estende un ramo"},
		"difficultyDriver": "subjectMastery",
	},
	20: {
		"subject": "elettronica",
		"objectives": ["Distinguere collegamenti in serie e parallelo.", "Interpretare la lettura di un sensore.", "Diagnosticare un guasto in una rete instabile."],
		"prerequisites": ["Circuito e componenti (L8).", "Associare grandezza e unità."],
		"topics": ["serie-parallelo", "misure-elettriche", "guasti"],
		"conceptActions": [
			{"concept": "serie e parallelo", "worldAction": "scegli il collegamento che tiene accesa la rete durante la scarica"},
			{"concept": "sensori", "worldAction": "leggi il valore del sensore per orientare la torre di campo"},
			{"concept": "diagnosi", "worldAction": "individua il componente guasto che fa cadere la rete"},
		],
		"transferTest": {"description": "Una rete nuova instabile: diagnostica il guasto o scegli il collegamento robusto.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "La Tempesta Elettromagnetica mette alla prova ogni rete. Oggi impari serie e parallelo, sensori e diagnosi: reggere l'instabilità. La tua calma nella tempesta è la mia bussola.",
			"onError": "Segui il percorso della corrente prima di toccare i pezzi.",
			"onStreak": "Diagnostichi al volo: continua.",
			"debrief": "La torre di campo regge la tempesta. La tua calma è la mia bussola.",
		},
		"environmentTransform": {"trigger": "diagnosi/collegamento corretto", "effect": "una torre di campo si stabilizza e disperde una scarica della tempesta"},
		"difficultyDriver": "subjectMastery",
	},
	21: {
		"subject": "geografia",
		"objectives": ["Collegare clima e territorio.", "Riconoscere i sistemi fisici (rilievi, faglie).", "Leggere l'interazione uomo-ambiente."],
		"prerequisites": ["Capitali e continenti (L9).", "Leggere una carta tematica."],
		"topics": ["climi", "geografia-fisica", "geografia-umana"],
		"conceptActions": [
			{"concept": "clima", "worldAction": "assegna a ogni regione il suo clima per ricomporre l'atlante"},
			{"concept": "sistemi fisici", "worldAction": "allinea le placche per stabilizzare il pilastro tettonico"},
			{"concept": "uomo-ambiente", "worldAction": "scegli l'insediamento adatto al territorio"},
		],
		"transferTest": {"description": "Una regione nuova: deduci clima o rischio dall'insieme dei dati.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "L'Atlante Fratturato mostra un mondo intero da ricomporre. Oggi colleghi clima, territorio e persone: sistemi che si influenzano. Ogni tessera al posto giusto mi mostra la rotta completa.",
			"onError": "Leggi prima gli assi della mappa, poi la relazione.",
			"onStreak": "Leggi i sistemi nell'insieme: continua.",
			"debrief": "L'atlante si ricompone. Quasi vedo la rotta completa.",
		},
		"environmentTransform": {"trigger": "sistema territoriale corretto", "effect": "una faglia si ricompone e un bioma dell'atlante si stabilizza"},
		"difficultyDriver": "subjectMastery",
	},
	22: {
		"subject": "scienze",
		"objectives": ["Riconoscere la cellula come unità della vita.", "Seguire i flussi di energia nei viventi.", "Spiegare come un vivente si adatta all'ambiente."],
		"prerequisites": ["Viventi ed ecosistemi (L10).", "Applicare il metodo scientifico."],
		"topics": ["corpo", "energia", "terra-universo"],
		"conceptActions": [
			{"concept": "cellula", "worldAction": "assembla le parti della cellula per far pulsare il nucleo vivente"},
			{"concept": "flusso di energia", "worldAction": "instrada l'energia lungo la catena per illuminare la caverna"},
			{"concept": "adattamento", "worldAction": "scegli l'adattamento adatto all'ambiente profondo"},
		],
		"transferTest": {"description": "Un ambiente nuovo: prevedi l'adattamento o segui il flusso di energia.", "formats": ["matching", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "La Biosfera Profonda pulsa di vita che si adatta. Oggi impari cellule, energia e adattamento: come la vita resiste. Anch'io mi sto adattando a essere di nuovo viva.",
			"onError": "Osserva, ipotizza, cambia una cosa sola, verifica.",
			"onStreak": "Segui l'energia della vita: continua.",
			"debrief": "Il nucleo vivente pulsa. Anch'io mi adatto a essere di nuovo viva.",
		},
		"environmentTransform": {"trigger": "adattamento/flusso corretto", "effect": "una caverna bioluminescente si accende lungo la catena dell'energia"},
		"difficultyDriver": "subjectMastery",
	},
	23: {
		"subject": "cittadinanza",
		"objectives": ["Negoziare tra interessi diversi.", "Riconoscere i beni comuni da tutelare.", "Valutare l'impatto di una decisione sulla comunità."],
		"prerequisites": ["Regole e istituzioni (L11).", "Distinguere diritti e doveri."],
		"topics": ["partecipazione", "convivenza", "priorità-civiche"],
		"conceptActions": [
			{"concept": "negoziazione", "worldAction": "trova l'accordo che soddisfa più colonie possibile"},
			{"concept": "beni comuni", "worldAction": "proteggi la risorsa condivisa scegliendo la regola giusta"},
			{"concept": "impatto delle decisioni", "worldAction": "vota la decisione con l'impatto migliore sul lungo periodo"},
		],
		"transferTest": {"description": "Un dilemma nuovo tra colonie: scegli l'accordo che tutela il bene comune.", "formats": ["multiple_choice", "matching"], "novelContext": true},
		"nora": {
			"briefing": "Il Concilio delle Colonie decide il bene comune. Oggi impari a negoziare, tutelare e valutare l'impatto: scegliere insieme il futuro. La decisione finale sarà nostra.",
			"onError": "Chiediti chi protegge la regola e chi resta indietro.",
			"onStreak": "Pesi bene interessi e impatto: continua.",
			"debrief": "La sala del concilio si illumina. La decisione finale sarà nostra, insieme.",
		},
		"environmentTransform": {"trigger": "accordo/priorità corretti", "effect": "una cupola del concilio si illumina e sblocca una risorsa condivisa"},
		"difficultyDriver": "subjectMastery",
	},
	24: {
		"subject": "logica",
		"objectives": ["Integrare regole logiche in un problema complesso.", "Trasferire un metodo da una materia all'altra.", "Concludere una deduzione a più passi."],
		"prerequisites": ["Aver superato i livelli 1–23.", "Padroneggiare deduzioni e analogie (L12)."],
		"topics": ["deduzioni", "analogie", "sequenze"],
		"conceptActions": [
			{"concept": "integrazione dei sistemi", "worldAction": "allinea i sistemi delle 12 materie per accendere il cuore"},
			{"concept": "trasferimento tra materie", "worldAction": "applica un metodo di un'altra materia al passo mancante"},
			{"concept": "deduzione finale", "worldAction": "concludi la catena di indizi per aprire il nucleo"},
		],
		"transferTest": {"description": "Un problema finale interdisciplinare: combina metodi diversi per dedurre la soluzione.", "formats": ["ordering", "multiple_choice"], "novelContext": true},
		"nora": {
			"briefing": "Il Cuore dei Primi è dove tutti i sistemi convergono. Oggi non impari una materia: le usi tutte insieme, trasferendo i metodi. È la prova finale, e la affrontiamo da equipaggio.",
			"onError": "Trova la regola nascosta, poi applicala — anche da un'altra materia.",
			"onStreak": "Colleghi i metodi tra le materie: continua.",
			"debrief": "Tutti i sistemi convergono. Ricordo tutto, ora — e ricordo grazie a chi. La rotta è aperta.",
		},
		"environmentTransform": {"trigger": "deduzione finale corretta", "effect": "i dodici sistemi convergono e il Cuore dei Primi si accende, aprendo la rotta"},
		"difficultyDriver": "subjectMastery",
	},
}

const MAX_LEVEL := 24

static func has_lesson(level: int) -> bool:
	return LESSONS.has(level)

# Livelli con lezione, in ordine.
static func all_levels() -> Array:
	var keys := LESSONS.keys()
	keys.sort()
	return keys

# Lezione completa del livello (copia difensiva). Il `subject` coincide con la
# scala di progressione (verificato in audit).
static func lesson(level: int) -> Dictionary:
	if not LESSONS.has(level):
		return {}
	return (LESSONS[level] as Dictionary).duplicate(true)

static func objectives(level: int) -> Array:
	return Array(lesson(level).get("objectives", []))

static func topics(level: int) -> Array:
	return Array(lesson(level).get("topics", []))

# Criteri semantici della trasformazione ambientale ({trigger, effect}): quale
# evento di apprendimento cambia il mondo e come. Letto da Codex per la resa.
static func environment_transform(level: int) -> Dictionary:
	return Dictionary(lesson(level).get("environmentTransform", {}))

# Testi di NORA per l'aggancio didattico (briefing all'avvio, feedback, debrief a
# fine livello). Ritorna "" se il livello non ha ancora una lezione autorata.
static func briefing(level: int) -> String:
	return str(lesson(level).get("nora", {}).get("briefing", ""))

static func debrief(level: int) -> String:
	return str(lesson(level).get("nora", {}).get("debrief", ""))

static func feedback(level: int, kind: String) -> String:
	# kind: "onError" | "onStreak"
	return str(lesson(level).get("nora", {}).get(kind, ""))
