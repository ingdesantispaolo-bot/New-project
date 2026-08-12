class_name CharacterMinigameCatalog
extends RefCounted

## **Un minigioco per personaggio, in tutti i mondi.** (12 agosto 2026)
##
## Richiesta del committente: minigiochi originali e divertenti, uno per
## personaggio, con difficoltà adatta al mondo e coerenza col personaggio e con
## la storia. Alcuni di **velocità**, altri di **riflessione**. E devono esserci
## **in tutti i mondi**.
##
## **La regola che decide se un minigioco è buono, e vale più di tutto il
## resto.** Il minigioco deve far fallire la **convinzione** del personaggio, non
## interrogare il bambino.
##
## Tobia crede che «contare in fretta è barare». Il suo minigioco non chiede
## quanto fa 6×7: mette davanti un mucchio che **non si riesce a contare uno per
## uno nel tempo dato**, e lascia scoprire che a gruppi di dieci il conto torna.
## La didattica non è nascosta perché travestita — è nascosta perché **è la
## meccanica**. Chi gioca non sta rispondendo, sta risolvendo.
##
## **Perché dieci meccaniche e non venticinque.** La prima idea era una dinamica
## nuova per ogni personaggio. È sbagliata due volte: venticinque meccaniche a
## metà valgono meno di dieci finite, e soprattutto **le convinzioni non sono
## venticinque**. Ortensia («se cambio tutto, prima o poi funziona»), Gru
## («l'errore è solo sfortuna») e Sferza («se non legge, spingi di più») credono
## la stessa cosa in tre mestieri diversi: che la causa si trovi per forza bruta.
## Una meccanica sola le smonta tutte e tre, e il fatto che ritorni è un pregio —
## il bambino riconosce il metodo e lo vede funzionare **fuori dal posto dove
## l'aveva imparato**, che è l'unica prova seria di averlo capito.
##
## Quello che **non** si ripete è il materiale: parole, segnali, manopole,
## grandezze e trappole arrivano dalla scheda, e sono di quel personaggio e di
## quella materia. Il renderer è condiviso, il gioco no.
##
## **Perché due famiglie.** La velocità e la riflessione allenano cose diverse e,
## soprattutto, **premiano bambini diversi**. Un gioco tutto di velocità esclude
## chi pensa piano — che spesso è chi pensa meglio; uno tutto di riflessione
## annoia chi ha bisogno di muovere le mani. Non è un compromesso: è la
## condizione perché nessuno dei due si senta escluso dalla storia, e
## `character_minigame_audit` la protegge.
##
## **La difficoltà viene dal mondo, non dal catalogo.** Scriverla a mano voce per
## voce vorrebbe dire venticinque tarature da tenere allineate: al primo ritocco
## della curva sarebbero venticinque posti da toccare. Qui c'è una funzione sola,
## e il catalogo dice solo *chi*, *cosa* e *con quale materiale*.

const FORMA_VELOCITA := "velocita"
const FORMA_RIFLESSIONE := "riflessione"

## Gli archetipi. Ognuno è una **trappola**, non una scenografia: la scenografia
## è il materiale della scheda, la trappola è ciò che fa cadere la convinzione.
const ARCHETIPO_MUCCHIO := "mucchio"      # velocità · raggruppare batte contare
const ARCHETIPO_SCAFFALE := "scaffale"    # riflessione · l'ordine che si vede non è quello che conta
const ARCHETIPO_CICLO := "ciclo"          # velocità · quello che si fa a mano non scala
const ARCHETIPO_TRACCIA := "traccia"      # riflessione · la memoria da sola non regge
const ARCHETIPO_RADIO := "radio"          # velocità · le parole cambiano, il bisogno no
const ARCHETIPO_MERCATO := "mercato"      # riflessione · richieste quasi uguali, un dettaglio decide
const ARCHETIPO_CIRCUITO := "circuito"    # riflessione · segui il flusso, non la fotografia
const ARCHETIPO_LEVA := "leva"            # velocità · la forza è fissa, il punto d'appoggio no
const ARCHETIPO_PROVA := "prova"          # riflessione · una causa si isola, non si indovina
const ARCHETIPO_STIMA := "stima"          # velocità · stimare converge, indovinare no

## I minigiochi. **Uno per ciascuno dei ventitré mondi abitati**, più i due
## testimoni dei mondi 3 e 4 che erano già stati scritti come pilot.
##
## L'ordine è quello dei mondi, perché è l'ordine in cui un bambino li incontra.
const GIOCHI := {
	# -- Mondo 1 · matematica ---------------------------------------------------
	"w01-tobia": {
		"archetipo": ARCHETIPO_MUCCHIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Il mucchio che non finisce",
		# La consegna non dice MAI la strategia: scoprirla è il gioco. Dire
		# «raggruppa per dieci» trasformerebbe la scoperta in un'istruzione da
		# eseguire, che è esattamente ciò che questo lotto evita.
		"consegna": "Tobia deve consegnare il conto prima che chiuda il deposito. Quanti cristalli ci sono?",
		"convinzioneBersaglio": "Contare in fretta è barare.",
		"vittoria": "Il conto torna, e ci è voluto meno tempo. Tobia guarda le tue mani, non il numero.",
		"sconfitta": "Il deposito ha chiuso. Tobia ricomincia da capo, e uno.",
	},
	# -- Mondo 2 · italiano -----------------------------------------------------
	"w02-corinna": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Lo scaffale che non si vede",
		"consegna": "Corinna ha svuotato uno scaffale e non sa più dove va ogni parola. Rimettile a posto.",
		"convinzioneBersaglio": "L'ordine giusto è quello che si vede.",
		"vittoria": "Lo scaffale sta in piedi, e nessuna parola è al posto per via di quanto è lunga.",
		"sconfitta": "Lo scaffale è di nuovo un mucchio. Corinna le rimette in fila per lunghezza, per intanto.",
		# **Le parole arrivano ordinate per LUNGHEZZA**, che è l'ordine di
		# Corinna: è l'esca. Chi la segue sbaglia, perché la lunghezza non dice
		# niente sulla funzione — ed è esattamente la cosa da capire.
		"scaffali": ["COSE", "AZIONI"],
		"correzione": "Non è il suo scaffale. Guarda che cosa FA la parola, non quanto è lunga.",
		"parole": [
			["re", 0], ["va", 1], ["sole", 0], ["corre", 1], ["porta", 0],
			["salta", 1], ["nave", 0], ["scrive", 1], ["albero", 0], ["dormire", 1],
			["finestra", 0], ["cantare", 1], ["montagna", 0], ["ascoltare", 1],
			["biblioteca", 0], ["costruire", 1],
		],
	},
	# -- Mondo 3 · coding -------------------------------------------------------
	"w03-ruggine": {
		"archetipo": ARCHETIPO_CICLO,
		"forma": FORMA_VELOCITA,
		"titolo": "Cento giri, tre mosse",
		"consegna": "Il nastro di Ruggine non si ferma e i pezzi continuano ad arrivare. Sgombralo prima della fine del turno.",
		"convinzioneBersaglio": "I cicli sono per i pigri.",
		"vittoria": "Il nastro è vuoto e le tue mani sono ferme. Ruggine guarda il braccio e non dice pigrizia.",
		"sconfitta": "Il nastro ha vinto. Ruggine ricomincia a mano, come tutti i giorni.",
		"comandi": ["PRENDI", "GIRA", "POSA"],
		"pezzo": "pezzo",
	},
	"w03-sesto": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "La traccia fuori dalla testa",
		"consegna": "Sesto ha una stanza in cui ricorda tutto, e fra poco non ci sarà più. Guarda il percorso, poi rifallo.",
		"convinzioneBersaglio": "Se non me lo ricordo, vuol dire che non l'ho mai saputo.",
		"vittoria": "Il percorso è arrivato in fondo senza la stanza. Non era sparito: gli mancava un posto dove stare.",
		"sconfitta": "La nebbia ha coperto tutto. Sesto si ripresenta da capo, e non è una tragedia.",
		"segnali": ["PONTE", "CHIAVE", "LENTE", "CAMPANA", "RUOTA", "MORSA", "PERNO"],
	},
	# -- Mondo 4 · inglese ------------------------------------------------------
	"w04-marea": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Radio di burrasca",
		"consegna": "La radio è disturbata. Invia ogni messaggio alla luce che gli serve.",
		"convinzioneBersaglio": "Capire è tradurre parola per parola.",
		"vittoria": "Le parole erano diverse, ma le luci hanno capito tutte. Marea ascolta il senso.",
		"sconfitta": "La burrasca ha inghiottito l'ultima chiamata. Marea riaccende la radio e potete riprovare.",
	},
	"w04-lino": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il mercato delle venti parole",
		"consegna": "I clienti parlano quasi uguale. Dai a ciascuno quello che ha chiesto.",
		"convinzioneBersaglio": "Per farsi capire bastano venti parole.",
		"vittoria": "Ogni richiesta aveva un dettaglio che cambiava tutto. Lino prende nota, captain.",
		"sconfitta": "Il banco resta aperto. Lino rimette in ordine le cassette e potete riprovare.",
		# Dichiara che richiesta e cassette stanno in **due lingue diverse**, e che
		# quindi nessuna parola può comparire in tutt'e due: è la regola che
		# impedisce di vincere accoppiando le lettere senza sapere l'inglese.
		# Vedi `market_minigame_audit`.
		"senzaRicalco": true,
	},
	# -- Mondo 5 · fisica -------------------------------------------------------
	"w05-gerbo": {
		"archetipo": ARCHETIPO_LEVA,
		"forma": FORMA_VELOCITA,
		"titolo": "Fulcro!",
		"consegna": "I massi bloccano il passo e Gerbo ha una trave. Tirali su prima che finisca il tempo.",
		"convinzioneBersaglio": "Le leve sono trucchi da deboli.",
		"vittoria": "Su tutti, e senza spingere più forte di prima. Gerbo guarda il cuneo e sta zitto.",
		"sconfitta": "I massi sono ancora lì. Gerbo si sputa sulle mani e ci riprova.",
	},
	# -- Mondo 6 · musica -------------------------------------------------------
	"w06-ambra": {
		"archetipo": ARCHETIPO_CICLO,
		"forma": FORMA_VELOCITA,
		"titolo": "Staffetta delle note",
		"consegna": "Le lanterne lontane aspettano il motivo, e continuano ad accendersene di nuove. Falle arrivare tutte.",
		"convinzioneBersaglio": "Dare un nome alla musica la rovina.",
		"vittoria": "La staffetta è arrivata in fondo. Il nome non ha rovinato niente: l'ha fatta viaggiare.",
		"sconfitta": "Le lanterne si sono spente in attesa. Ambra le riaccende una per una, come sempre.",
		"comandi": ["ASCOLTA", "NOMINA", "MANDA"],
		"pezzo": "intervallo",
	},
	# -- Mondo 7 · latino -------------------------------------------------------
	"w07-livia": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Glifi vivi",
		"consegna": "Le copie di Livia sono perfette e stanno andando alle porte sbagliate. Mandale dove devono.",
		"convinzioneBersaglio": "Copiare bene è già capire.",
		"vittoria": "Ogni parola è entrata dalla sua porta. Copiarle non bastava: bisognava sapere che cosa facevano.",
		"sconfitta": "Le porte si sono chiuse con le parole di là. Livia ricomincia a ricopiare, bene.",
		"scaffali": ["CHI FA L'AZIONE", "CHI LA SUBISCE"],
		"correzione": "Non è la sua porta. Guarda come FINISCE la parola, non quanto è lunga.",
		# **A ogni lunghezza ci sono parole di tutt'e due le porte**, ed è
		# costruito così apposta. La prima stesura usava solo prima e seconda
		# declinazione: lì l'accusativo è sempre il nominativo più una lettera,
		# quindi le parole corte erano quasi tutte soggetti e le lunghe quasi
		# tutti complementi — **l'ordine che si vede indovinava due volte su
		# tre**, e Livia aveva ragione: copiare bastava. Mescolando terza e
		# quinta declinazione (`rex`/`regem`, `res`/`rem`) la lunghezza torna a
		# non dire niente, che è l'unica condizione perché il gioco insegni.
		"parole": [
			["rex", 0], ["rem", 1],
			["rosa", 0], ["spem", 1], ["aqua", 0], ["diem", 1],
			["regem", 1], ["lupus", 0], ["pacem", 1], ["pater", 0],
			["servus", 0], ["matrem", 1], ["patrem", 1], ["virtus", 0],
			["dominus", 0], ["reginam", 1],
		],
	},
	# -- Mondo 8 · elettronica --------------------------------------------------
	"w08-ciro": {
		"archetipo": ARCHETIPO_CIRCUITO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il circuito mutante",
		"consegna": "Il Delta ha spostato tutti i nodi. Accendi la lampada ogni volta che lo schema si ricompone.",
		"convinzioneBersaglio": "Basta ricordare lo schema giusto.",
		"vittoria": "Tre schemi diversi, la stessa corrente. Ciro smette di contare i nodi e segue il lampo.",
		"sconfitta": "Il Delta si spegne senza danni. Ciro ridisegna i collegamenti: adesso sapete dove non passa.",
	},
	# -- Mondo 9 · geografia ----------------------------------------------------
	"w09-alma": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Isole nel banco di nebbia",
		"consegna": "Il banco di nebbia sta arrivando sulle isole. Guarda la rotta, poi rifalla quando la costa non si vede più.",
		"convinzioneBersaglio": "I numeri non sono posti.",
		"vittoria": "La costa non c'era e la rotta è arrivata lo stesso. I numeri erano posti, e ci si arriva.",
		"sconfitta": "La nebbia ha preso tutto. Alma aspetta che si alzi, come fanno tutti qui.",
		"segnali": ["3 EST", "7 NORD", "2 SUD", "9 OVEST", "5 EST", "4 NORD", "8 SUD"],
	},
	# -- Mondo 10 · scienze -----------------------------------------------------
	"w10-ortensia": {
		"archetipo": ARCHETIPO_PROVA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Una cosa per volta",
		"consegna": "La pianta di Ortensia non attecchisce. Hai poche prove: scopri che cosa la salva.",
		"convinzioneBersaglio": "Se cambio tutto, prima o poi funziona.",
		"vittoria": "Sai quale delle cose era, e lo sai perché l'hai isolata. Ortensia se lo segna.",
		"sconfitta": "Le prove sono finite e la pianta è ancora lì. Ortensia ricomincia, e stavolta guarda.",
		"domanda": "QUALE DELLE MANOPOLE TIENE VIVA LA PIANTA?",
		"successo": "La pianta si è ripresa.",
		"fallimento": "La pianta resta appassita.",
		"fattori": [
			{"nome": "LUCE", "valori": ["all'ombra", "al sole"]},
			{"nome": "ACQUA", "valori": ["poca", "molta"]},
			{"nome": "TERRENO", "valori": ["sabbia", "terra scura"]},
			{"nome": "VASO", "valori": ["stretto", "largo"]},
			{"nome": "VENTO", "valori": ["riparata", "esposta"]},
		],
	},
	# -- Mondo 11 · storia ------------------------------------------------------
	"w11-danio": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "La piazza delle voci",
		"consegna": "Sul banco di Danio passano frasi che tutti ripetono. Timbra ciascuna con quello che è.",
		"convinzioneBersaglio": "Se lo dicono tutti, è vero.",
		"vittoria": "La piazza era piena e non contava niente. Danio guarda i timbri, non i numeri.",
		"sconfitta": "Il banco si è svuotato e le voci sono rimaste. Danio continua a contarle.",
		"scaffali": ["QUALCUNO L'HA VISTO", "L'HA SENTITO DIRE", "C'È UN OGGETTO"],
		"correzione": "Non è quello il timbro. Conta CHI lo dice, non quanti lo ripetono.",
		# **L'esca è la popolarità**, e le frasi arrivano ordinate dalla più
		# ripetuta: è la convinzione di Danio messa in cima alla pila. Il numero
		# non predice il timbro — ci sono frasi ripetute da migliaia che nessuno
		# ha visto, e oggetti che stanno in un cassetto e non nomina nessuno.
		# **Ci sono oggetti famosissimi e testimoni celebri**, non solo dicerie
		# popolari e reperti dimenticati. Con la prima stesura le voci più
		# ripetute erano tutte «sentito dire» e le meno ripetute tutti oggetti:
		# seguire il numero grande **funzionava**, e il gioco dava ragione a
		# Danio invece di smentirlo. Adesso il numero non dice niente, e
		# `character_minigame_audit` misura che continui a non dirlo.
		"parole": [
			["«Nessuno sa chi costruì la Rovina»", 1, "lo ripetono in 4000", 4000],
			["La campana del faro, esposta in piazza", 2, "la nominano in 3100", 3100],
			["«Ero sul molo, e l'ho vista scendere»", 0, "lo ripetono in 2600", 2600],
			["«Il ponte crollò di notte»", 1, "lo ripetono in 2400", 2400],
			["«La regina non venne mai qui»", 1, "lo ripetono in 1800", 1800],
			["«L'ho aiutato a posarla, quella pietra»", 0, "lo ripetono in 1500", 1500],
			["La lente bruciata del faro", 2, "la nominano in 900", 900],
			["«Il faro si spense da solo»", 1, "lo ripetono in 12", 12],
			["«C'ero, e faceva ancora giorno»", 0, "lo ripetono in 3", 3],
			["Il registro dei transiti di quell'anno", 2, "lo nomina 1 persona", 1],
			["«Ero di turno quella notte»", 0, "lo ripetono in 1", 1],
			["Una trave del ponte, spezzata", 2, "la nomina 1 persona", 1],
		],
	},
	# -- Mondo 12 · logica ------------------------------------------------------
	"w12-quinto": {
		"archetipo": ARCHETIPO_CIRCUITO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il labirinto mobile",
		"consegna": "I corridoi si spostano appena passi. Porta il passo dall'ingresso all'uscita, ogni volta che cambiano.",
		"convinzioneBersaglio": "Ricordare la strada è saperla.",
		"vittoria": "La strada era diversa tutte le volte e ci sei arrivato lo stesso. Quinto smette di contare i passi.",
		"sconfitta": "Il labirinto si è richiuso. Quinto rifà la strada di ieri, che oggi non c'è più.",
	},
	# -- Mondo 13 · matematica --------------------------------------------------
	"w13-solano": {
		"archetipo": ARCHETIPO_STIMA,
		"forma": FORMA_VELOCITA,
		"titolo": "Orbita a occhio",
		"consegna": "La finestra si chiude presto e lo strumento buono non arriverà. Manda i carichi in orbita.",
		"convinzioneBersaglio": "Stimare è tirare a indovinare.",
		"vittoria": "Ogni tiro era più vicino del precedente. Non stavi indovinando: stavi stringendo.",
		"sconfitta": "La finestra si è chiusa. Solano aspetta la prossima, e lo strumento perfetto.",
		"grandezza": "SPINTA",
		"azione": "LANCIA",
		"apertura": "Un carico nuovo sulla rampa.",
		"corto": "Troppo corto: è ricaduto prima.",
		"lungo": "Troppo lungo: l'ha superata.",
		"centro": "In orbita.",
	},
	# -- Mondo 14 · italiano ----------------------------------------------------
	"w14-elmo": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Tre voci, una stanza",
		"consegna": "Elmo conosce il finale e vuole rimontare la scena. Scegli la versione che quel personaggio poteva raccontare.",
		"convinzioneBersaglio": "Se so come finisce, ho capito.",
		"vittoria": "Il finale lo sapevi da subito, e non bastava. Elmo rilegge la prima pagina.",
		"sconfitta": "Il montaggio non regge e la scena si sfalda. Elmo torna all'ultima pagina, che è quella che sa.",
		"indizio": "CHI STA RACCONTANDO",
		"guida": "Scegli la versione che quella persona poteva davvero raccontare.",
		# Qui richiesta e scelte sono nella stessa lingua e il dettaglio decisivo
		# **è** una parola: la regola del non ricalco (vedi Lino) non si applica,
		# e infatti questa scheda non la dichiara.
		"turni": [
			{
				"richiesta": "La cuoca è rimasta in cucina tutta la sera e non ha mai attraversato la sala.",
				"tipo": "LA CUOCA",
				"scelte": [
					"«Ho visto il vecchio litigare col nipote accanto al camino.»",
					"«Ho sentito gridare di là: due voci, e poi una porta.»",
					"«Il nipote è uscito piangendo dal portone sul giardino.»",
				],
				"giusta": 1,
			},
			{
				"richiesta": "Il giardiniere era fuori sotto la pioggia, e dalla vetrata si vede solo la sala.",
				"tipo": "IL GIARDINIERE",
				"scelte": [
					"«In sala si sono alzati in due, e uno ha rovesciato la sedia.»",
					"«In cucina la pentola bolliva da un'ora, l'ho vista io.»",
					"«Hanno detto una cosa terribile, l'ho sentita parola per parola.»",
				],
				"giusta": 0,
			},
			{
				"richiesta": "Il nipote è arrivato che era già tutto finito, ed è entrato dal portone.",
				"tipo": "IL NIPOTE",
				"scelte": [
					"«Ho visto mio nonno alzarsi e gridare, e sapevo perché.»",
					"«La sedia era rovesciata e non c'era più nessuno.»",
					"«La cuoca ha smesso di cucinare appena hanno cominciato.»",
				],
				"giusta": 1,
			},
			{
				"richiesta": "Il vecchio non si è mosso dalla poltrona e dà le spalle alla porta della cucina.",
				"tipo": "IL VECCHIO",
				"scelte": [
					"«Ho visto la cuoca sporgersi dalla porta a guardarci.»",
					"«È entrato qualcuno dal portone: l'ho visto in faccia.»",
					"«È entrato qualcuno: ho sentito la pioggia farsi più forte.»",
				],
				"giusta": 2,
			},
		],
	},
	# -- Mondo 15 · coding ------------------------------------------------------
	"w15-gru": {
		"archetipo": ARCHETIPO_PROVA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Guasto vivo",
		"consegna": "La macchina di Gru si pianta, ma non sempre. Hai poche prove: scopri quando succede.",
		"convinzioneBersaglio": "L'errore è solo sfortuna.",
		"vittoria": "Il guasto si può rifare quando vuoi. Una cosa che si rifà a comando non è sfortuna.",
		"sconfitta": "Le prove sono finite e il guasto va e viene. Gru dà un colpo alla macchina, come sempre.",
		"domanda": "QUALE CONDIZIONE FA PIANTARE LA MACCHINA?",
		"successo": "La macchina si è piantata.",
		"fallimento": "La macchina ha girato liscia.",
		"fattori": [
			{"nome": "CARICO", "valori": ["un pezzo", "pila piena"]},
			{"nome": "AVVIO", "valori": ["a freddo", "a caldo"]},
			{"nome": "NASTRO", "valori": ["lento", "veloce"]},
			{"nome": "TURNO", "valori": ["di giorno", "di notte"]},
			{"nome": "PORTELLO", "valori": ["chiuso", "aperto"]},
		],
	},
	# -- Mondo 16 · inglese -----------------------------------------------------
	"w16-talia": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Frontiera del contesto",
		"consegna": "Al valico ogni frase va letta per la scena che hai davanti. Scegli quella che passa.",
		"convinzioneBersaglio": "Ogni parola ha una sola traduzione.",
		"vittoria": "La stessa parola è passata più volte con significati diversi. Talia smette di cercarne uno solo.",
		"sconfitta": "Il valico si è chiuso. Talia riapre il quaderno alla pagina di sempre.",
		"indizio": "LA PAROLA CHE CAMBIA",
		"guida": "La parola è la stessa. La scena no.",
		"senzaRicalco": true,
		"turni": [
			{
				"richiesta": "Can you RUN the shop tomorrow?",
				"tipo": "RUN",
				"scelte": ["correre veloce", "mandare avanti il negozio", "scappare via"],
				"giusta": 1,
			},
			{
				"richiesta": "The water is very LIGHT here.",
				"tipo": "LIGHT",
				"scelte": ["chiara e trasparente", "accesa come una lampada", "che pesa poco"],
				"giusta": 0,
			},
			{
				"richiesta": "Please BOOK a room for two nights.",
				"tipo": "BOOK",
				"scelte": ["un volume da leggere", "prenotare", "scrivere su un quaderno"],
				"giusta": 1,
			},
			{
				"richiesta": "It's getting HARD to breathe up here.",
				"tipo": "HARD",
				"scelte": ["duro come la pietra", "a voce alta", "difficile"],
				"giusta": 2,
			},
		],
	},
	# -- Mondo 17 · fisica ------------------------------------------------------
	"w17-nerea": {
		"archetipo": ARCHETIPO_STIMA,
		"forma": FORMA_VELOCITA,
		"titolo": "Immersione sicura",
		"consegna": "Nerea scende a sensazione. Trova la quota a cui la campana regge, prima che il turno finisca.",
		"convinzioneBersaglio": "Il corpo sa da solo quanto reggere.",
		"vittoria": "La quota buona non era quella che sentivi. Nerea guarda lo strumento e non se ne vergogna.",
		"sconfitta": "Il turno è finito con la campana ancora su. Nerea dice che domani lo sente meglio.",
		"grandezza": "QUOTA",
		"azione": "SCENDI",
		"apertura": "Una campana nuova da calare.",
		"corto": "Troppo alta: la campana non arriva.",
		"lungo": "Troppo bassa: lo scafo protesta.",
		"centro": "Tiene.",
	},
	# -- Mondo 18 · musica ------------------------------------------------------
	"w18-silo": {
		"archetipo": ARCHETIPO_STIMA,
		"forma": FORMA_VELOCITA,
		"titolo": "Eco piano",
		"consegna": "La volta rimanda il suono solo entro una certa forza. Fai arrivare le note in fondo alla sala.",
		"convinzioneBersaglio": "Il piano qui non si sente.",
		"vittoria": "In fondo si sentiva, e non stavi suonando forte. Silo abbassa la mano e ascolta.",
		"sconfitta": "La sala è rimasta muta, o satura. Silo torna a suonare più forte che può.",
		"grandezza": "FIATO",
		"azione": "SUONA",
		"apertura": "Un'altra nota da mandare in fondo.",
		"corto": "Troppo piano: si spegne a metà sala.",
		"lungo": "Troppo forte: la volta satura e torna rumore.",
		"centro": "Arriva in fondo, pulita.",
	},
	# -- Mondo 19 · latino ------------------------------------------------------
	"w19-numa": {
		"archetipo": ARCHETIPO_CICLO,
		"forma": FORMA_VELOCITA,
		"titolo": "Parole in marcia",
		"consegna": "I vocaboli antichi arrivano più in fretta di quanto Numa li trascriva. Portali tutti fino a oggi.",
		"convinzioneBersaglio": "La lingua di prima era quella giusta: le parole di oggi sono corrotte.",
		"vittoria": "Sono arrivate tutte, e sono ancora loro. Numa smette di chiamarle corrotte: le chiama vive.",
		"sconfitta": "I vocaboli si sono accumulati e sono rimasti nell'epoca antica. Lì restano, e lì finiscono.",
		"comandi": ["RADICE", "MUTA", "SCRIVI"],
		"pezzo": "vocabolo",
	},
	# -- Mondo 20 · elettronica -------------------------------------------------
	"w20-sferza": {
		"archetipo": ARCHETIPO_PROVA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Sensore nella tempesta",
		"consegna": "Il sensore di Sferza non legge. Hai poche prove: scopri che cosa lo fa leggere.",
		"convinzioneBersaglio": "Se non legge, spingi di più.",
		"vittoria": "Non era la potenza. Sferza guarda la manopola che non aveva mai toccato.",
		"sconfitta": "Le prove sono finite e il sensore è ancora cieco. Sferza alza la potenza al massimo.",
		"domanda": "QUALE MANOPOLA FA LEGGERE IL SENSORE?",
		"successo": "Il sensore legge pulito.",
		"fallimento": "Sullo schermo resta solo neve.",
		"fattori": [
			{"nome": "POTENZA", "valori": ["a metà", "al massimo"]},
			{"nome": "FILTRO", "valori": ["escluso", "inserito"]},
			{"nome": "SCHERMO", "valori": ["nudo", "a massa"]},
			{"nome": "ANTENNA", "valori": ["corta", "lunga"]},
			{"nome": "TERRA", "valori": ["asciutta", "bagnata"]},
		],
	},
	# -- Mondo 21 · geografia ---------------------------------------------------
	"w21-terza": {
		"archetipo": ARCHETIPO_CIRCUITO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Atlante a catena",
		"consegna": "Le correnti passano da una regione all'altra e cambiano strada a ogni stagione. Portale fino alla costa.",
		"convinzioneBersaglio": "Ogni posto fa storia a sé.",
		"vittoria": "Nessuna regione era da sola: quello che passava di là arrivava di qua. Terza ridisegna l'atlante.",
		"sconfitta": "La catena si è spezzata a metà. Terza torna a guardare una regione per volta.",
	},
	# -- Mondo 22 · scienze -----------------------------------------------------
	"w22-vesca": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Rete delle nicchie",
		"consegna": "La rete di Vesca si sta svuotando. Rimetti ogni specie dove riesce a vivere.",
		"convinzioneBersaglio": "Vince sempre il più forte.",
		"vittoria": "La rete regge, e non è piena dei più forti. Vesca conta le nicchie invece delle vittorie.",
		"sconfitta": "La rete si è svuotata. Vesca rimette in cima i più forti, che è quello che ha sempre fatto.",
		"scaffali": ["ACQUA BASSA", "SCOGLIERA", "MARE APERTO"],
		"correzione": "Lì non regge. Conta DOVE riesce a vivere, non quanto è forte.",
		# **L'esca è la forza**, e le specie arrivano ordinate dalla più forte: è
		# la convinzione di Vesca messa in cima alla pila. La forza non predice la
		# nicchia — al largo ci stanno il tonno e il plancton, e nell'acqua bassa
		# vivono cose che altrove morirebbero in un'ora.
		"parole": [
			["Capodoglio", 2, "forza 100", 100],
			["Squalo bruno", 2, "forza 98", 98],
			["Murena", 1, "forza 92", 92],
			["Tonno migratore", 2, "forza 88", 88],
			["Granchio corazzato", 1, "forza 71", 71],
			["Cernia", 1, "forza 64", 64],
			["Anguilla di fango", 0, "forza 40", 40],
			["Passera di sabbia", 0, "forza 22", 22],
			["Cozza", 1, "forza 15", 15],
			["Patella", 1, "forza 12", 12],
			["Gambero di risacca", 0, "forza 9", 9],
			["Medusa d'altura", 2, "forza 6", 6],
			["Vongola", 0, "forza 4", 4],
			["Plancton", 2, "forza 1", 1],
			["Ghiozzo di pozza", 0, "forza 7", 7],
			["Riccio di scoglio", 1, "forza 18", 18],
		],
	},
	# -- Mondo 23 · storia ------------------------------------------------------
	"w23-cronia": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Archivio sotto pressione",
		"consegna": "Gli scaffali si stanno chiudendo. Manda ogni fonte al deposito che le spetta, prima che si serri.",
		"convinzioneBersaglio": "Le fonti scomode confondono: si conserva la versione ufficiale.",
		"vittoria": "Sono salvate tutte, anche quelle che si contraddicono. È da lì che si capisce l'ordine dei fatti.",
		"sconfitta": "Gli scaffali si sono chiusi e restano dei buchi. Cronia li riempie con la versione ufficiale.",
		"destinazioni": ["QUALCUNO\nL'HA VISTO", "QUALCUNO\nL'HA SCRITTO", "È RIMASTO\nUN OGGETTO"],
		"guida": "Guarda che cos'è la fonte, non se ti conviene.",
		"correzione": "Quel deposito non è il suo. Anche la fonte scomoda va salvata.",
		"messaggi": [
			["«Ero sul molo, e la nave non arrivò mai.»", 0],
			["Il registro del porto, alla data di quel giorno.", 1],
			["Una cima tagliata, ripescata sotto la banchina.", 2],
			["«Mio padre la vide partire, e non tornò a dirlo.»", 0],
			["La lettera del capitano, mai spedita.", 1],
			["Un remo con lo stemma, incastrato negli scogli.", 2],
			["«C'ero anch'io, e non è andata come dicono.»", 0],
			["Il verbale ufficiale, firmato tre mesi dopo.", 1],
			["La campana della nave, appesa in una casa privata.", 2],
		],
	},
}

## I parametri di un archetipo a un dato mondo: **è qui che vive la difficoltà**.
##
## Ogni ramo ha lo stesso impegno: quello che cresce deve rendere la strategia
## vecchia **sempre meno sufficiente**, mai rendere i bersagli più piccoli o il
## testo più veloce da leggere.
static func parametri(archetipo: String, world: int) -> Dictionary:
	var livello := clampi(world, 1, 24)
	match archetipo:
		ARCHETIPO_MUCCHIO:
			# **Il mucchio parte già grande.** Con trenta pezzi e tredici secondi
			# — la prima taratura — contare uno per uno costava 13,5 s contro 13,4
			# concessi: un bambino svelto ce la faceva **col metodo vecchio**, e la
			# convinzione di Tobia sarebbe uscita confermata. Il margine adesso è
			# del 47%, e `character_minigame_audit` non lo lascia scendere.
			var pezzi := 36 + livello * 6
			return {
				"pezzi": pezzi,
				"secondi": 12.0 + float(livello) * 0.9,
				# Quanti pezzi entrano in un gruppo. Dieci sempre: è la base del
				# sistema numerico, e cambiarla da un mondo all'altro insegnerebbe
				# che è una convenzione arbitraria del gioco.
				"gruppo": 10,
			}
		ARCHETIPO_SCAFFALE:
			# Nessun cronometro: è un gioco di riflessione, e mettere fretta a chi
			# deve capire una regola invisibile misurerebbe l'ansia, non l'idea.
			#
			# Gli errori concessi calano salendo di mondo, ma non scendono mai a
			# zero: una prova in cui il primo tocco decide tutto non si gioca, si
			# subisce.
			return {
				"parole": clampi(6 + int(floor(float(livello) / 3.0)) * 2, 6, 16),
				"errori": clampi(4 - int(floor(float(livello) / 8.0)), 2, 4),
				"secondi": 0.0,
			}
		ARCHETIPO_CICLO:
			# **La mano ha un tetto, ed è il perno di tutto.** Con `cooldown`
			# secondi fra un gesto e il successivo, il ritmo massimo della mano è
			# 1/(3·cooldown) pezzi al secondo: un numero, non una questione di
			# dita. I pezzi arrivano a 1/arrivo, e la differenza è quanto la mano
			# guadagna davvero. L'audit verifica che con quel guadagno il turno non
			# basti, e che col braccio invece avanzi.
			return {
				"pezzi": 10 + livello,
				"capienza": 26 + livello,
				"arrivo": maxf(1.15, 1.45 - float(livello) * 0.01),
				"cooldown": 0.34,
				"secondi": 26.0 + float(livello) * 0.4,
			}
		ARCHETIPO_TRACCIA:
			# Quanti segnali bisogna riprodurre a stanza chiusa. Quattro si
			# ricordano ancora; sette no, ed è il punto. Nessun cronometro: la
			# nebbia cala quando decide il bambino.
			return {
				"segnali": clampi(4 + int(floor(float(livello - 1) / 4.0)), 4, 7),
				"errori": clampi(4 - int(floor(float(livello) / 10.0)), 2, 4),
				"secondi": 0.0,
			}
		ARCHETIPO_RADIO:
			return {
				"messaggi": clampi(5 + int(floor(float(livello - 1) / 5.0)), 5, 9),
				"secondi": 4.8 + float(livello) * 0.15,
				"errori": 2,
			}
		ARCHETIPO_MERCATO:
			return {
				"richieste": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5),
				"errori": 3,
				"secondi": 0.0,
			}
		ARCHETIPO_CIRCUITO:
			# Due grandezze indipendenti: quante volte lo schema muta e quanti
			# interruttori vanno letti in ciascuno. Nessuna delle due restringe i
			# bersagli e nessuna introduce un cronometro.
			return {
				"schemi": clampi(2 + int(floor(float(livello - 1) / 6.0)), 2, 5),
				"passaggi": clampi(2 + int(floor(float(livello - 1) / 5.0)), 2, 6),
				"errori": clampi(5 - int(floor(float(livello - 1) / 8.0)), 3, 5),
				"secondi": 0.0,
			}
		ARCHETIPO_LEVA:
			# **La forza della mano non compare qui**, ed è deliberato: è una
			# costante del pannello, uguale in tutti i mondi. Cresce solo il peso,
			# quindi l'appoggio buono si stringe salendo — al mondo 24 ce n'è uno
			# solo. Se crescesse anche la forza, spingere tornerebbe una strategia
			# e Gerbo avrebbe ragione per sempre.
			return {
				"peso": 14.0 + float(livello) * 2.0,
				"massi": 3 + int(floor(float(livello) / 6.0)),
				"secondi": 20.0 + float(livello) * 0.5,
				"penalita": 1.6,
			}
		ARCHETIPO_PROVA:
			# Le prove concesse sono **esattamente quante ne servono cambiando una
			# cosa per volta**, più una. Non è avarizia: è l'unico modo perché il
			# metodo si veda. Con prove abbondanti anche il disordine arriva in
			# fondo, e allora il gioco non direbbe niente su come ci si arriva.
			var fattori := clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5)
			return {
				"fattori": fattori,
				"prove": fattori + 1,
				"errori": 2,
				"secondi": 0.0,
			}
		ARCHETIPO_STIMA:
			# L'intervallo cresce e la tolleranza si stringe: le «caselle» in cui
			# può stare il bersaglio si moltiplicano, e i tiri concessi restano
			# sette. La ricerca guidata dal riscontro dimezza ogni volta e ci sta;
			# quella cieca dovrebbe provarne decine. L'audit lo verifica mondo per
			# mondo, ed è la differenza fra stimare e indovinare messa in numeri.
			#
			# L'intervallo parte da 90 e non da 60, e il perché è una misura:
			# con 60 le caselle al mondo 1 erano cinque e mezza contro sette tiri
			# concessi, cioè **si vinceva provandole tutte**, che è precisamente
			# tirare a indovinare. La stima di Solano vive al mondo 13, ma il
			# Tavolo giochi la riproporrà ovunque, e una taratura che regge solo
			# dove è nata non è una taratura.
			return {
				"intervallo": 90 + livello * 6,
				"tolleranza": clampi(6 - int(floor(float(livello) / 6.0)), 2, 6),
				"tiri": 7,
				"bersagli": clampi(3 + int(floor(float(livello) / 12.0)), 3, 4),
				"secondi": 32.0 + float(livello),
			}
	return {}

static func ha_gioco(npc_id: String) -> bool:
	return GIOCHI.has(npc_id)

## La scheda completa di un minigioco: testo autoriale, materiale e parametri del
## mondo.
static func scheda(npc_id: String) -> Dictionary:
	if not GIOCHI.has(npc_id):
		return {}
	var voce: Dictionary = Dictionary(GIOCHI[npc_id]).duplicate(true)
	var dati := NpcCatalog.resident(npc_id)
	var world := int(dati.get("world", 1))
	voce["npc"] = npc_id
	voce["nome"] = str(dati.get("nome", npc_id))
	voce["world"] = world
	voce["materia"] = ApparatusConfig.world_subject(world)
	voce["parametri"] = parametri(str(voce["archetipo"]), world)
	return voce

## Quanti giochi per famiglia. Serve all'audit: velocità e riflessione devono
## esserci tutt'e due, perché premiano bambini diversi.
static func conteggio_forme() -> Dictionary:
	var out := {FORMA_VELOCITA: 0, FORMA_RIFLESSIONE: 0}
	for npc_id in GIOCHI.keys():
		var forma := str(Dictionary(GIOCHI[npc_id])["forma"])
		out[forma] = int(out.get(forma, 0)) + 1
	return out

## In quali mondi c'è almeno un minigioco. Serve all'audit della copertura: la
## richiesta del committente è **tutti i mondi**, e un mondo scoperto è un mondo
## dove i personaggi tornano a essere gente che parla e basta.
static func mondi_coperti() -> Array:
	var mondi := {}
	for npc_id in GIOCHI.keys():
		var dati := NpcCatalog.resident(str(npc_id))
		if not dati.is_empty():
			mondi[int(dati.get("world", 0))] = true
	var elenco := mondi.keys()
	elenco.sort()
	return elenco

## I giochi di un archetipo. Serve agli audit che devono verificare il materiale
## di **tutte** le riverniciature, non solo di quella scritta per prima.
static func giochi_con_archetipo(archetipo: String) -> Array:
	var elenco: Array = []
	for npc_id in GIOCHI.keys():
		if str(Dictionary(GIOCHI[npc_id]).get("archetipo", "")) == archetipo:
			elenco.append(str(npc_id))
	elenco.sort()
	return elenco
