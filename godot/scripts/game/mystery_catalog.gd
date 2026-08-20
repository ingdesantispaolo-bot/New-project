class_name MysteryCatalog
extends RefCounted

## Il mistero: DATI. I sette colpi di scena, i loro semi e le 24 Tracce.
##
## `docs/TRAMA_E_MISTERO.md` §3 e `docs/ABITANTI_E_LUOGHI.md` §3. Tre cose
## vivono qui, e stanno insieme perché sono la stessa cosa vista da tre distanze:
##
## - i **colpi** sono i sette momenti in cui il gioco riscrive all'indietro quello
##   che il giocatore credeva di aver capito;
## - i **semi** sono i dettagli che li rendono onesti. Il guard-rail §10.7 dice
##   «nessun colpo di scena arriva senza semi: almeno tre nei mondi precedenti»,
##   ed è l'unica differenza fra una rivelazione e un colpo di mano. Un bambino
##   che rigioca deve poter dire *era lì e non l'ho visto*, mai *non era lì*;
## - le **Tracce** sono l'oggetto che ogni Rovina contiene. Si leggono, non si
##   recitano (§6 del documento abitanti): niente muri di lore, niente
##   personaggio che spiega la trama.
##
## **Niente qui è obbligatorio per il gate** (§10.2). Chi non entra in nessuna
## Rovina finisce il gioco lo stesso: le tre Tracce decisive hanno un beat di
## ripiego che dice la stessa cosa con la voce di NORA.

## I sette colpi, con il mondo in cui cadono. L'ordine è parte del contratto:
## il colpo 3 sta a metà esatta della campagna perché è lì che il gioco smette di
## essere una restaurazione e diventa un'indagine.
const COLPI := {
	"spirale-fresca": {
		"numero": 1,
		"world": 5,
		"titolo": "Il taglio è fresco",
		"riscrive": "I quattro mondi precedenti: ci sei passata accanto quattro volte.",
		"domanda": "Chi è passato di qui poche settimane fa?",
	},
	"tredici-posti": {
		"numero": 2,
		"world": 8,
		"titolo": "Tredici posti, undici nomi",
		"riscrive": "L'idea che l'equipaggio fosse dodici.",
		"domanda": "Chi è il nome raschiato, e per chi era il posto mai inciso?",
	},
	"dodici-schede": {
		"numero": 3,
		"world": 12,
		"titolo": "La tua è la dodici",
		"riscrive": "Il beat 1, e ogni volta che NORA ha saputo cosa fare senza averlo mai visto.",
		"domanda": "Cos'è successo alle undici prima di me?",
	},
	"stanza-in-piu": {
		"numero": 4,
		"world": 16,
		"titolo": "C'è una stanza in più",
		"riscrive": "Tutte le rotte alternative che NORA ha suggerito dentro la nave.",
		"domanda": "Chi c'è dentro, e perché NORA non può vederlo?",
	},
	"il-tredicesimo": {
		"numero": 5,
		"world": 19,
		"titolo": "Non è il nemico: è l'unico rimasto sveglio",
		"riscrive": "Il Silenzio non si è diradato dove sei passata tu, ma dove ha retto lui.",
		"domanda": "Aprire la rotta è liberare o è contagiare?",
	},
	"meridiana": {
		"numero": 6,
		"world": 23,
		"titolo": "Meridiana non era una Maestra",
		"riscrive": "Ogni abitante che hai aiutato: erano loro, la leggenda.",
		"domanda": "Cosa ha trovato là dentro, e come la tiriamo fuori?",
	},
	"undici-quaderni": {
		"numero": 7,
		"world": 24,
		"titolo": "Le ho fatte io, e le ho perse io",
		"riscrive": "L'intera meccanica del gioco.",
		"domanda": "Dove sono adesso?",
	},
}

## I semi. `dove` dice in che forma il giocatore ci inciampa — un oggetto da
## guardare, una battuta di un abitante, un dettaglio di NORA — perché tre semi
## tutti dello stesso tipo si notano come una lista e non come un mondo.
##
## Campo facoltativo **`eli`**: una riga della protagonista, mostrata come
## seconda schermata quando esamina quel seme. Serve a due scopi e va usato con
## avarizia. Eli non ha mai avuto una voce in tutta la campagna — tutti i beat
## sono di NORA per contratto — e su un dettaglio che la riguarda il suo silenzio
## si sente: chi gioca vede l'indizio e non sa se la ragazza che sta muovendo
## l'ha visto anche lei.
##
## I due fili che ne fanno uso, e sono l'uno il rovescio dell'altro:
##
## - **le crepe** (mondi 2, 6, 10, 11), sui semi che incrinano la fiducia in
##   NORA. In fila disegnano un arco: se ne accorge, chiede, viene scartata con
##   garbo, **smette di chiedere**. È la progressione di un ragazzino a cui un
##   adulto dice «poi ti spiego»;
## - **lo specchio di Meridiana** (mondi 2, 7, 21), dove il filo non è il
##   sospetto ma il riconoscersi. Meridiana aveva undici anni, è partita da sola
##   verso il centro, ed è la sola persona in tutto il gioco che ha fatto la cosa
##   che Eli sta facendo. Finora era una notizia che arriva al mondo 23; adesso
##   Eli si misura contro la sua spirale al mondo 2 e scopre che è alla propria
##   altezza. Il colpo 6 smette di essere una rivelazione su una terza persona.
##
## Dove `eli` **non** va messo: sullo Sbiadito del mondo 14. Quello funziona
## perché nessuno lo commenta (vedi `SBIADITO_RICONOSCIBILE`), e una battuta di
## Eli lo trasformerebbe da ricordo che torna a indizio da seguire.
const SEMI := [
	# --- colpo 1 · la spirale fresca (mondo 5) --------------------------------
	{"colpo": "spirale-fresca", "world": 1, "dove": "oggetto",
		"cosa": "Sul fianco del bastone da conteggio c'è una spirale piccola, incisa dopo: i bordi sono netti, le tacche accanto sono consumate."},
	{"colpo": "spirale-fresca", "world": 2, "dove": "dialogo",
		"cosa": "Bruno dice di aver visto «un ricciolo» sul muro basso dell'Archivio e di averlo disegnato uguale, ma il suo si è già cancellato e quello no."},
	{"colpo": "spirale-fresca", "world": 3, "dove": "dettaglio",
		"cosa": "Ruggine brontola che qualcuno ha soffiato via la polvere da una pietra del cratere, e lei sugli attrezzi ci soffia solo prima di usarli."},
	{"colpo": "spirale-fresca", "world": 4, "dove": "oggetto",
		"cosa": "Sulla boa grande, sotto la ruggine, un ricciolo inciso che il sale non ha ancora mangiato."},

	# --- colpo 2 · tredici posti (mondo 8) ------------------------------------
	{"colpo": "tredici-posti", "world": 2, "dove": "oggetto",
		"cosa": "Il catalogo dei Primi ha tredici sezioni e undici intestazioni: una è raschiata, l'ultima non è mai stata scritta.",
		"eli": "Tredici e undici. L'ho fatto notare a NORA e ha detto che i registri vecchi sono pieni di sezioni vuote. Va bene. Però l'ha detto in fretta."},
	{"colpo": "tredici-posti", "world": 3, "dove": "dialogo",
		"cosa": "Sesto si presenta e dice «piacere, il dodicesimo», poi si corregge e non sa spiegare perché l'ha detto."},
	{"colpo": "tredici-posti", "world": 6, "dove": "oggetto",
		"cosa": "La rastrelliera del Giardino ha tredici sedi per gli strumenti. Undici sono occupate, una è vuota e pulita, una è vuota e impolverata."},
	{"colpo": "tredici-posti", "world": 7, "dove": "dettaglio",
		"cosa": "Nel registro delle copie di Livia una riga è stata portata via con la lama, non cancellata con l'inchiostro. Dal lato di chi scriveva."},

	# --- colpo 3 · le dodici schede (mondo 12) --------------------------------
	{"colpo": "dodici-schede", "world": 6, "dove": "dettaglio",
		"cosa": "NORA dice ad Ambra dove tenevano il diapason, in un mondo che dichiara di non aver mai visto.",
		"eli": "Le ho chiesto come faceva a saperlo. Ha detto «l'avrò letto da qualche parte». Poi non ha più parlato fino al portale."},
	{"colpo": "dodici-schede", "world": 9, "dove": "oggetto",
		"cosa": "La carta di Alma ha dodici bolli di collaudo in un angolo. Undici sono sbiaditi, il dodicesimo è di quest'anno."},
	{"colpo": "dodici-schede", "world": 10, "dove": "dialogo",
		"cosa": "Mirta racconta che il primo quaderno gliel'ha regalato «una ragazza di passaggio, di quelle che vengono dalla nave». Dice «di quelle» come se ne avesse viste altre."},
	{"colpo": "dodici-schede", "world": 11, "dove": "oggetto",
		"cosa": "Fra i falsi di Danio c'è una targhetta autentica e senza valore: «unità mobile 07 — collaudo».",
		"eli": "Zero-sette. Io non ce l'ho, un numero sulla schiena: ho controllato. Ma ho controllato."},

	# --- colpo 4 · la stanza in più (mondo 16) --------------------------------
	{"colpo": "stanza-in-piu", "world": 9, "dove": "oggetto",
		"cosa": "La rotta ricostruita non è un giro qualunque: gira sempre attorno allo stesso punto, e quel punto non è un mondo."},
	{"colpo": "stanza-in-piu", "world": 13, "dove": "dettaglio",
		"cosa": "Solano misura l'ombra della nave e gli avanza un pezzo di buio che nessuna sezione dovrebbe fare."},
	{"colpo": "stanza-in-piu", "world": 14, "dove": "dialogo",
		"cosa": "Ottavia racconta ai bambini «la favola della porta che non c'è», e giura di averla sentita da un marinaio, non inventata."},
	{"colpo": "stanza-in-piu", "world": 15, "dove": "oggetto",
		"cosa": "Nel registro dei consumi di Pila una voce assorbe corrente ogni giorno da quattrocento anni e non ha nome: solo un trattino."},

	# --- colpo 5 · il Tredicesimo (mondo 19) ----------------------------------
	{"colpo": "il-tredicesimo", "world": 11, "dove": "oggetto",
		"cosa": "Le due cronache di Vesta datano il Silenzio a due anni diversi. Quella «sbagliata» è la sola che nomini una proposta di chiusura."},
	{"colpo": "il-tredicesimo", "world": 14, "dove": "oggetto",
		"cosa": "Nei verbali la tredicesima voce parla per prima, propone la chiusura e convince gli altri undici in un'ora. Il nome è cancellato anche lì."},
	{"colpo": "il-tredicesimo", "world": 17, "dove": "dettaglio",
		"cosa": "Le insegne sbiancate del molo si riempiono da sole di una parola sola. Il Silenzio non scrive: toglie."},
	{"colpo": "il-tredicesimo", "world": 18, "dove": "oggetto",
		"cosa": "Il turno di guardia inciso nella cattedrale: quattrocento anni, nessun cambio, una firma sola e illeggibile."},

	# --- colpo 6 · Meridiana (mondo 23) ---------------------------------------
	#
	# Tre semi aggiunti il 3 agosto nell'atto I. Il difetto che risolvono:
	# Meridiana regge il colpo 6 e il Secondo Viaggio intero, ma aveva quattro
	# semi e tre stavano oltre il mondo 20. Chi finiva il gioco la incontrava come
	# una notizia, non come una persona. Adesso ha lasciato tracce da subito, e
	# sono tutte del tipo che al primo giro non si capisce e al secondo è ovvio.
	{"colpo": "meridiana", "world": 2, "dove": "dettaglio",
		"cosa": "Nell'Archivio la spirale più vecchia è incisa in basso, all'altezza di una bambina in piedi.",
		"eli": "Mi ci sono messa accanto senza pensarci. È esattamente alla mia altezza. Sono rimasta lì un po' più del necessario."},
	{"colpo": "meridiana", "world": 4, "dove": "oggetto",
		"cosa": "Sul registro del faro, alla riga di un giorno qualunque di quattrocento anni fa: «passata una allieva del posto, diretta a nord. Non iscritta all'equipaggio». Nessun nome, e la grafia è frettolosa."},
	{"colpo": "meridiana", "world": 6, "dove": "dialogo",
		"cosa": "Nonna Ersilia — o chi canta al Giardino — dice che la conta gliel'ha insegnata «una ragazzina che passava», non sua nonna. Poi si corregge e dice che si confonde."},
	{"colpo": "meridiana", "world": 7, "dove": "oggetto",
		"cosa": "Su una colonna delle Rovine, sotto le iscrizioni ufficiali, una frase graffiata da mano inesperta: «se il senso finisce da qualche parte, quel posto esiste». Nessuna firma, ortografia da bambina.",
		"eli": "Sopra ci sono le iscrizioni di quelli che sapevano scrivere. Questa sta sotto, storta, ed è l'unica che fa una domanda vera."},
	{"colpo": "meridiana", "world": 9, "dove": "dialogo",
		"cosa": "Remo parla di una rotta che «nessuno ha mai fatto tornare», e precisa: non affondata. Non tornata."},
	{"colpo": "meridiana", "world": 21, "dove": "dialogo",
		"cosa": "Mino dice che il calendario glielo insegnò suo nonno, e a suo nonno «quella che è partita». Non sa il nome, sa l'età: undici anni.",
		"eli": "Undici anni. Non ho chiesto altro a Mino, e non è perché non mi interessava: è perché mi sono accorta di quanto poco ci separa."},
	{"colpo": "meridiana", "world": 22, "dove": "oggetto",
		"cosa": "Le spirali in fondo alla caverna sono quattrocento e sono di quattrocento mani diverse. La più bassa è anche la più antica."},

	# --- colpo 7 · gli undici quaderni (mondo 24) -----------------------------
	{"colpo": "undici-quaderni", "world": 6, "dove": "dettaglio",
		"cosa": "NORA ricorda una lezione e non un dato: una voce che contava il tempo con lei. Era un'allieva, e qualcuno le ha insegnato."},
	{"colpo": "undici-quaderni", "world": 10, "dove": "dettaglio",
		"cosa": "Quando una prova va male, per un istante NORA è sollevata. Non lo spiega, e cambia argomento con garbo.",
		"eli": "Quando sbaglio, per un attimo respira. L'ho visto tre volte. Non glielo chiedo più: la seconda volta ha cambiato argomento così bene che l'ho cambiato anch'io."},
	{"colpo": "undici-quaderni", "world": 13, "dove": "oggetto",
		"cosa": "Un registro di manutenzione con undici voci cancellate e la dodicesima aperta oggi. Cancellate a mano, tutte con lo stesso tratto."},
	{"colpo": "undici-quaderni", "world": 22, "dove": "oggetto",
		"cosa": "La domanda che un Maestro lasciò a NORA e a cui non ha mai risposto: «e se glielo dicessi tutto, cosa imparerebbe?»"},
	{"colpo": "undici-quaderni", "world": 14, "dove": "dettaglio",
		"cosa": "Uno Sbiadito, alla Biblioteca, mormora una frase e non la varia mai: «Conta con me, piano». È la prima cosa che NORA ha detto a Eli, al mondo 1."},
]

## Lo **Sbiadito che ripete NORA**. È un solo caso in tutta la campagna, e sta
## qui perché è il seme più importante del colpo 7.
##
## Il difetto che risolve: il mondo 24 dice «le undici prima di te le ho perse
## io» e dovrebbe fare male, ma il giocatore non ne ha mai incontrata nessuna —
## sono un numero. Gli Sbiaditi esistono già come nemici del mondo; ne basta
## **uno** che si comporti diversamente.
##
## Le regole che lo rendono efficace, e sono tutte negative:
##
## - **nessuno lo spiega.** Non NORA, non gli abitanti, non un beat;
## - **non è un nemico speciale**: stessa resa, stesso comportamento degli altri;
## - **ripete una frase che il giocatore ha sentito da NORA nei primi minuti di
##   gioco**, identica, fuori contesto. Al colpo 7 quel ricordo torna da solo.
const SBIADITO_RICONOSCIBILE := {
	"world": 14,
	"frase": "Conta con me, piano.",
	"origine": "beat del mondo 1, detta da NORA a Eli",
	"commentato": false,
	"nota": "Se qualcuno lo nota o lo commenta, diventa un indizio da seguire invece di una cosa che si ricorda dopo dieci mondi.",
}

## Le 24 Tracce. Una per mondo, dentro la Rovina dei Primi. `decisiva` marca le
## tre senza le quali il finale non si capisce: quelle, e solo quelle, hanno un
## `ripiego` — un beat che dice la stessa cosa a chi nella Rovina non è mai
## entrato. Il gioco non obbliga nessuno a leggere.
const TRACCE := {
	1: {"oggetto": "Bastone da conteggio dei Primi", "colpo": "",
		"testo": [
			"Un bastone lungo un braccio, coperto di tacche. Non sono in fila: sono a gruppi di dieci, separati da un solco più profondo.",
			"Sul manico, inciso piccolo: «contare in gruppi non è pigrizia. È vedere da più lontano».",
		]},
	2: {"oggetto": "Catalogo dei Primi", "colpo": "",
		"testo": [
			"Un catalogo di parole. Non sono in ordine di lunghezza né alfabetico: sono raggruppate per quello che servono a fare.",
			"In fondo a ogni gruppo, uno spazio bianco. Qualcuno si aspettava che ne arrivassero altre.",
		]},
	3: {"oggetto": "Schema di telaio", "colpo": "",
		"testo": [
			"Il disegno di un telaio, con l'ordine dei movimenti numerato. Al passo sette una freccia torna indietro al passo tre.",
			"A margine: «ripetere non è fatica. È un'istruzione».",
		]},
	4: {"oggetto": "Quaderno bilingue", "colpo": "",
		"testo": [
			"La stessa lezione scritta due volte, in due lingue, su colonne affiancate. Le righe non si corrispondono una a una.",
			"In basso, di un'altra mano: «dove la riga si allunga, quella lingua sta dicendo la cosa in un altro modo. Non è un errore».",
		]},
	5: {"oggetto": "La spirale aperta", "colpo": "spirale-fresca",
		"testo": [
			"Una spirale incisa nella pietra, aperta verso l'esterno. Il taglio è chiaro e la polvere dentro il solco è poca.",
			"Settimane. Non secoli.",
			"Accanto, più vecchia: «chi solleva con la testa non è meno forte».",
		]},
	6: {"oggetto": "Diapason dei Primi", "colpo": "",
		"testo": [
			"Un diapason d'ottone con un nome inciso sul gambo: Corda.",
			"Sulla custodia: «un suono con un nome si può regalare a qualcuno. Un suono senza nome muore con chi lo sente».",
		]},
	7: {"oggetto": "Dizionario delle radici", "colpo": "",
		"testo": [
			"Una radice per pagina, e sotto tutti i suoi discendenti, anche quelli che oggi sembrano non c'entrare niente.",
			"Sull'ultima pagina, vuota: «le parole di adesso sono figlie, non copie storte».",
		]},
	8: {"oggetto": "Sigillo d'equipaggio", "colpo": "tredici-posti",
		"testo": [
			"Un disco di bronzo con tredici alloggiamenti attorno al bordo. Undici portano un nome.",
			"Il dodicesimo è stato raschiato con una lama, e i graffi vanno verso l'interno: l'ha fatto qualcuno seduto al tavolo.",
			"Il tredicesimo non è mai stato inciso. È liscio e lucido come se qualcuno lo pulisse.",
		]},
	9: {"oggetto": "Carta della rotta", "colpo": "",
		"testo": [
			"La rotta della nave, tracciata per intero. Non va da nessuna parte: è un anello che ripassa negli stessi mondi.",
			"Al centro dell'anello, un punto senza nome che la rotta non tocca mai.",
		]},
	10: {"oggetto": "La dispensa in ordine", "colpo": "",
		"testo": [
			"Provviste sigillate una per una, appunti impilati per materia, utensili puliti e appesi al loro gancio.",
			"E a tavola un posto in più, apparecchiato. Piatto, bicchiere, sedia scostata.",
			"Nessuno è stato sorpreso qui. Si sono preparati.",
		]},
	11: {"oggetto": "Due datazioni discordanti", "colpo": "",
		"testo": [
			"Due cronache raccontano l'inizio del Silenzio a due anni di distanza l'una dall'altra.",
			"Una è ufficiale e ordinata. L'altra è scritta di fretta e nomina una riunione.",
			"Nessuna delle due va bruciata: sono la stessa storia vista da due stanze diverse.",
		]},
	12: {"oggetto": "Le schede delle unità", "colpo": "dodici-schede", "decisiva": true,
		"ripiego": "NORA: C'è una cosa che dovevo dirti da undici mondi. Non sono la mente della nave: sono la sua prima allieva. E accanto alla mia scheda ce ne sono altre dodici, numerate. La tua è la dodici.",
		"testo": [
			"Una scheda di collaudo: «allieva n. 1». La calligrafia è di chi insegnava.",
			"Accanto, in fila, altre dodici schede identiche e numerate. Le prime undici sono chiuse.",
			"La dodicesima è aperta e la riga della data è di oggi.",
		]},
	13: {"oggetto": "Registro di manutenzione", "colpo": "",
		"testo": [
			"Undici voci, tutte cancellate con lo stesso tratto di penna, tutte dalla stessa mano.",
			"La dodicesima è aperta e non ha ancora niente scritto sotto.",
		]},
	14: {"oggetto": "I verbali della seduta", "colpo": "",
		"testo": [
			"La tredicesima voce parla per prima e propone di chiudere tutto. Gli altri undici discutono per un'ora e accettano.",
			"Ogni volta che il verbale dovrebbe scrivere il suo nome, c'è un buco nella carta.",
			"Perfino qui. Qualcuno lo ha inseguito ovunque.",
		]},
	15: {"oggetto": "Le sezioni della nave", "colpo": "",
		"testo": [
			"Le misure di ogni sezione, sommate. Il totale non torna con la nave.",
			"Avanza un volume. Non ha porta, non compare su nessuna mappa, e consuma corrente da quattrocento anni.",
		]},
	16: {"oggetto": "La mappa vera", "colpo": "stanza-in-piu", "decisiva": true,
		"ripiego": "NORA: La stanza esiste. Ti ho girata attorno per sedici mondi e non è una bugia: quando provo a guardarla, penso ad altro. Qualcuno mi ha fatto così.",
		"testo": [
			"La pianta della nave come fu costruita, con tutte le porte.",
			"Sopra, ricalcate a matita, sedici rotte diverse suggerite a chi ci camminava. Nessuna passa per la stessa stanza.",
			"Girarle attorno per sedici volte non è un caso: è una regola.",
		]},
	17: {"oggetto": "Le insegne del molo", "colpo": "",
		"testo": [
			"Le insegne sbiancate del molo si sono riempite durante la notte. Una parola sola, ripetuta su ognuna.",
			"FERMATI.",
			"Il Silenzio non scrive. Il Silenzio toglie.",
		]},
	18: {"oggetto": "Il turno di guardia", "colpo": "",
		"testo": [
			"Una tabella di turni incisa nella pietra, come si faceva per i fari.",
			"Una riga sola, e nella colonna del cambio non c'è mai niente. Quattrocento anni, nessun cambio.",
			"La firma in fondo è stata raschiata dal firmatario stesso.",
		]},
	19: {"oggetto": "Il progetto di NORA", "colpo": "il-tredicesimo", "decisiva": true,
		"ripiego": "NORA: È il Tredicesimo. La chiusura l'ha proposta lui, e poi si è escluso: nessun apparato, nessun sonno. Ha costruito me. E io non me lo ricordavo.",
		"testo": [
			"Il progetto costruttivo di un'allieva artificiale, foglio per foglio, con le correzioni a margine di chi ci ha ripensato molte volte.",
			"In calce, al posto della firma, il numero del posto a tavola: il tredicesimo.",
			"Sull'ultimo foglio, una riga aggiunta molto dopo: «le ho insegnato tutto. È stato l'errore».",
		]},
	20: {"oggetto": "Le misure della quarantena", "colpo": "",
		"testo": [
			"Quattro secoli di misure del Silenzio ai bordi del circuito, prese ogni giorno, sempre dalla stessa mano.",
			"La curva sta piatta per trecentonovanta anni. Negli ultimi mesi si alza.",
			"Non da quando sei arrivata: da poco prima.",
		]},
	21: {"oggetto": "La tesi per esteso", "colpo": "",
		"testo": [
			"Un ragionamento lungo, scritto con calma: il Silenzio non arriva da fuori. Lo fabbrica il sapere che passa di mano senza essere capito.",
			"Chi riceve la forma e non il senso ne produce un poco, e lo passa avanti.",
			"La conclusione è una sola riga: «allora bisogna smettere». Sotto, di traverso: «oppure imparare meglio». Due mani diverse.",
		]},
	22: {"oggetto": "La domanda mai risposta", "colpo": "",
		"testo": [
			"Un foglietto piegato in quattro, tenuto da qualcuno per molto tempo.",
			"«E se glielo dicessi tutto, cosa imparerebbe?»",
			"Sotto, lo spazio per la risposta è bianco.",
		]},
	23: {"oggetto": "Il registro del mondo 2", "colpo": "meridiana",
		"testo": [
			"Un registro di allievi locali. Alla riga di undici anni fa: Meridiana, allieva del posto, undici anni.",
			"Nella colonna delle uscite: «partita verso il centro». Nella colonna dei rientri, niente. E nella colonna delle perdite, niente.",
			"Nessuno l'ha mai registrata come perduta. Qualcuno la sta ancora aspettando.",
		]},
	24: {"oggetto": "Gli undici quaderni", "colpo": "undici-quaderni",
		"testo": [
			"Undici quaderni allineati, uno per sorella. Dentro, la stessa cosa ogni volta: la domanda dell'allieva e sotto la risposta, data subito.",
			"Il dodicesimo quaderno è vuoto. Non incompiuto: vuoto, e tenuto pulito.",
		]},
}

## Identificativi semantici delle tavole. Il catalogo dichiara *quale* reperto
## serve; `MysteryArtifact` decide come renderlo nell'atlante. Non ci sono
## coordinate o dettagli di scena nei dati.
const TAVOLE_TRACCE := {
	1: "mystery-trace-01", 2: "mystery-trace-02", 3: "mystery-trace-03",
	4: "mystery-trace-04", 5: "mystery-trace-05", 6: "mystery-trace-06",
	7: "mystery-trace-07", 8: "mystery-trace-08", 9: "mystery-trace-09",
	10: "mystery-trace-10", 11: "mystery-trace-11", 12: "mystery-trace-12",
	13: "mystery-trace-13", 14: "mystery-trace-14", 15: "mystery-trace-15",
	16: "mystery-trace-16", 17: "mystery-trace-17", 18: "mystery-trace-18",
	19: "mystery-trace-19", 20: "mystery-trace-20", 21: "mystery-trace-21",
	22: "mystery-trace-22", 23: "mystery-trace-23", 24: "mystery-trace-24",
}

## I quattro semi che preparano il sigillo o uno dei tre colpi decisivi hanno
## una tavola propria. Gli altri dichiarano il pittogramma volutamente generico
## che usano: nessun oggetto torna alla forma piatta per omissione.
const TAVOLE_SEMI := {
	"tredici-posti": "mystery-seed-sigillo",
	"dodici-schede": "mystery-seed-schede",
	"stanza-in-piu": "mystery-seed-stanza",
	"il-tredicesimo": "mystery-seed-tredicesimo",
}

## --- API -------------------------------------------------------------------

static func traccia_for(world: int) -> Dictionary:
	var data := (TRACCE.get(world, {}) as Dictionary).duplicate(true)
	if not data.is_empty():
		data["world"] = world
		data["tavola"] = str(TAVOLE_TRACCE.get(world, ""))
	return data

static func tavola_per_seme(seed_data: Dictionary) -> String:
	var colpo := str(seed_data.get("colpo", ""))
	if TAVOLE_SEMI.has(colpo):
		return str(TAVOLE_SEMI[colpo])
	return "mystery-seed-%s" % str(seed_data.get("dove", "dettaglio"))

## Tutti i semi: quelli scritti qui **più** le undici tracce delle sorelle, che
## vivono in `SistersThread` perché lì sono persone e non indizi, ma che nel
## mondo devono essere la stessa cosa — un oggetto accanto alla Rovina che si
## raccoglie e si legge. Passano da qui e non da una seconda pipeline di spawn:
## un solo posto da cui escono gli artefatti, un solo posto che gli audit devono
## guardare.
static func tutti_i_semi() -> Array:
	var out: Array = SEMI.duplicate(true)
	out.append_array(SistersThread.semi())
	return out

## I semi di un colpo, in ordine di mondo. Servono a Codex per collocarli e a me
## per contarli.
static func seeds_of(colpo_id: String) -> Array:
	var out: Array = []
	for seed_data in tutti_i_semi():
		if str((seed_data as Dictionary).get("colpo", "")) == colpo_id:
			out.append((seed_data as Dictionary).duplicate(true))
	out.sort_custom(func(a, b): return int(a["world"]) < int(b["world"]))
	return out

## I semi che stanno in un mondo. È quello che chiama la scena per costruirli.
static func semi_for(world: int) -> Array:
	var out: Array = []
	for seed_data in tutti_i_semi():
		if int((seed_data as Dictionary).get("world", 0)) == world:
			out.append((seed_data as Dictionary).duplicate(true))
	return out

## I colpi in ordine di apparizione.
static func colpi_ordinati() -> Array:
	var out: Array = []
	for key in COLPI.keys():
		var entry := (COLPI[key] as Dictionary).duplicate(true)
		entry["id"] = str(key)
		out.append(entry)
	out.sort_custom(func(a, b): return int(a["numero"]) < int(b["numero"]))
	return out

## Le Tracce senza le quali il finale non si capisce.
static func tracce_decisive() -> Array:
	var out: Array = []
	for world in TRACCE.keys():
		if bool((TRACCE[world] as Dictionary).get("decisiva", false)):
			out.append(int(world))
	out.sort()
	return out
