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
## **Perché quindici meccaniche e non quarantasei.** La prima idea era una
## dinamica nuova per ogni personaggio. È sbagliata due volte: quarantasei
## meccaniche a metà valgono meno di quindici finite, e soprattutto **le
## convinzioni non sono quarantasei**. Ortensia («se cambio tutto, prima o poi
## funziona»), Gru
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
const ARCHETIPO_ALTALENA := "altalena"    # riflessione · una previsione resta vera senza spettatori
const ARCHETIPO_RITMO := "ritmo"          # riflessione · una filastrocca può custodire una regola numerica
const ARCHETIPO_VIBRAZIONE := "vibrazione" # riflessione · la stessa musica attraversa sensi diversi
const ARCHETIPO_GLIFI := "glifi"          # velocità · copiare la forma non rivela la funzione
const ARCHETIPO_PARENTELA := "parentela"  # riflessione · un'ipotesi si sostiene con una famiglia di parole
const ARCHETIPO_PROVA := "prova"          # riflessione · una causa si isola, non si indovina
const ARCHETIPO_STIMA := "stima"          # velocità · stimare converge, indovinare no

## I minigiochi. **Uno per ciascuno dei quarantasei residenti**: specialista e
## testimone di tutti i ventitré mondi. I Bislacchi itineranti hanno incontri
## propri e non fanno parte di questo contratto.
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
	"w01-ersilia": {
		"archetipo": ARCHETIPO_RITMO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "La conta sotto il pane",
		"consegna": "Il forno apre solo se la conta non inciampa. Continua la fila di pagnotte sullo stesso battito.",
		"convinzioneBersaglio": "La mia conta è una canzone, mica un conto.",
		"vittoria": "Sette semi, sette passi: la canzone custodiva un conto da sessant'anni. Ersilia la canta più piano, per vederlo.",
		"sconfitta": "La strofa si è fermata, ma il pane resta sul banco. Ersilia ricomincia dal primo battito, senza fretta.",
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
	"w02-bruno": {
		"archetipo": ARCHETIPO_GLIFI,
		"forma": FORMA_VELOCITA,
		"titolo": "Friscoli in fuga",
		"consegna": "Le creaturine attraversano l'Archivio. Completa il loro nome e mandale alla porta in cui quel nome serve.",
		"convinzioneBersaglio": "Le parole che invento sono sbagliate, perché me lo dicono tutti.",
		"vittoria": "Ogni nome nuovo ha permesso di riconoscere una creatura. Bruno ne scrive uno nel catalogo: se serve, può diventare vero.",
		"sconfitta": "I friscoli sono scappati senza nome. Bruno conserva le radici: domani può combinarle di nuovo.",
		"porte": ["NOME DI COSA", "NOME DI CHI FA"],
		"guidaGlifi": "RADICE azzurra = idea di partenza   ·   FINE dorata: -O / -A = COSA   ·   -ORE / -ISTA = CHI FA",
		"successoGlifi": "Il nome apre la porta perché permette di capire che tipo di creatura è.",
		"correzione": "Il nome suona bene, ma non aiuta quella porta: guarda che cosa promette la fine dorata.",
		"glifi": [
			{"radice": "FRISC", "fine": "O", "funzione": 0},
			{"radice": "LUCCIC", "fine": "A", "funzione": 0},
			{"radice": "SALTA", "fine": "ORE", "funzione": 1},
			{"radice": "NUVOLA", "fine": "ISTA", "funzione": 1},
			{"radice": "TREMOL", "fine": "O", "funzione": 0},
			{"radice": "GIRA", "fine": "ORE", "funzione": 1},
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
	"w05-tilla": {
		"archetipo": ARCHETIPO_ALTALENA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "L'altalena delle prove",
		"consegna": "Sposta la cesta, prevedi che cosa succederà e prova a tenere l'asse in equilibrio.",
		"convinzioneBersaglio": "Se nessuno mi dà retta, vuol dire che ho torto.",
		"vittoria": "Tre equilibri, anche senza spettatori. Tilla aveva ragione prima che qualcuno guardasse.",
		"sconfitta": "L'altalena resta qui. Tilla rimette le ceste a terra e potete riprovare.",
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
	"w06-oreste": {
		"archetipo": ARCHETIPO_VIBRAZIONE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Corde sotto le dita",
		"consegna": "La tavola di Oreste conserva un tremito. Trova la corda che porta lo stesso gesto.",
		"convinzioneBersaglio": "La musica non è per me: io la tocco soltanto.",
		"vittoria": "Mano e corda hanno riconosciuto gli stessi quattro gesti. Oreste non era fuori dalla musica: ci entrava da un'altra porta.",
		"sconfitta": "Le corde restano sul banco. Oreste appoggia di nuovo il palmo: il tremito non ha fretta.",
	},
	# -- Mondo 7 · latino -------------------------------------------------------
	"w07-livia": {
		"archetipo": ARCHETIPO_GLIFI,
		"forma": FORMA_VELOCITA,
		"titolo": "Glifi vivi",
		"consegna": "L'inchiostro corre verso due porte. Leggi la fine di ogni parola e mandala alla sua funzione.",
		"convinzioneBersaglio": "Copiare bene è già capire.",
		"vittoria": "Ogni parola è entrata dalla sua porta. Copiarle non bastava: bisognava sapere che cosa facevano.",
		"sconfitta": "Le porte si sono chiuse con le parole di là. Livia ricomincia a ricopiare, bene.",
		"porte": ["CHI AGISCE", "CHI RICEVE"],
		"correzione": "La copia è identica, ma la funzione no: guarda la desinenza dorata.",
		# Stessa lunghezza, funzioni diverse: non si vince misurando la parola.
		# La radice è azzurra e la desinenza dorata nel renderer; i dati restano
		# testuali e accessibili a lettori di schermo.
		"glifi": [
			{"radice": "ROS", "fine": "A", "funzione": 0},
			{"radice": "SP", "fine": "EM", "funzione": 1},
			{"radice": "LUP", "fine": "US", "funzione": 0},
			{"radice": "LUP", "fine": "UM", "funzione": 1},
			{"radice": "PORT", "fine": "A", "funzione": 0},
			{"radice": "PORT", "fine": "AM", "funzione": 1},
			{"radice": "DOMIN", "fine": "US", "funzione": 0},
			{"radice": "DOMIN", "fine": "UM", "funzione": 1},
			{"radice": "REGIN", "fine": "A", "funzione": 0},
			{"radice": "REGIN", "fine": "AM", "funzione": 1},
			{"radice": "RE", "fine": "X", "funzione": 0},
			{"radice": "R", "fine": "EM", "funzione": 1},
			{"radice": "VIRT", "fine": "US", "funzione": 0},
			{"radice": "PAC", "fine": "EM", "funzione": 1},
		],
	},
	"w07-zeno": {
		"archetipo": ARCHETIPO_PARENTELA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Parenti nell'ombra",
		"consegna": "Fai un'ipotesi sulla parola antica, illumina i suoi parenti moderni e decidi se tenerla o cambiarla.",
		"convinzioneBersaglio": "Indovinare non vale: bisogna sapere.",
		"vittoria": "Le ipotesi hanno retto a famiglie diverse. Zeno non stava tirando a caso: stava usando le radici.",
		"sconfitta": "Le famiglie restano incise nella pietra. Zeno ricomincia da un ramo e prova un'altra parentela.",
		"famiglie": [
			{
				"antica": "AQUA", "significati": ["acqua", "luce", "strada"], "giusta": 0,
				"parenti": [
					{"parola": "ACQUEDOTTO", "indizio": "porta acqua da un luogo all'altro"},
					{"parola": "ACQUARIO", "indizio": "contiene acqua"},
				],
			},
			{
				"antica": "LUMEN", "significati": ["vento", "luce", "peso"], "giusta": 1,
				"parenti": [
					{"parola": "LUMINOSO", "indizio": "manda o riflette luce"},
					{"parola": "ILLUMINARE", "indizio": "dare luce"},
				],
			},
			{
				"antica": "AUDIRE", "significati": ["ascoltare", "costruire", "correre"], "giusta": 0,
				"parenti": [
					{"parola": "AUDIZIONE", "indizio": "prova in cui qualcuno viene ascoltato"},
					{"parola": "AUDIO", "indizio": "ciò che si può ascoltare"},
				],
			},
			{
				"antica": "SCRIBERE", "significati": ["dividere", "scrivere", "dormire"], "giusta": 1,
				"parenti": [
					{"parola": "SCRIBA", "indizio": "persona che scrive documenti"},
					{"parola": "ISCRIZIONE", "indizio": "testo scritto su una superficie"},
				],
			},
			{
				"antica": "PORTARE", "significati": ["nascondere", "portare", "misurare"], "giusta": 1,
				"parenti": [
					{"parola": "TRASPORTO", "indizio": "porta qualcosa da un luogo a un altro"},
					{"parola": "PORTATORE", "indizio": "chi porta qualcosa"},
				],
			},
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
	"w08-doria": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Chiuse di corrente",
		"consegna": "Acqua e corrente arrivano insieme. Manda ogni pezzo alla funzione che svolge, prima che le chiuse si blocchino.",
		"convinzioneBersaglio": "Quello che so dell'acqua non c'entra niente con l'elettricità.",
		"vittoria": "Cisterna e batteria, tubo e filo, valvola e interruttore: cambiava il materiale, non la funzione. Doria riconosce la stessa regola.",
		"sconfitta": "Le chiuse si sono fermate. Doria separa di nuovo acqua e corrente, ma i pezzi restano sul banco.",
		"destinazioni": ["FA PARTIRE", "FA PASSARE", "REGOLA IL FLUSSO"],
		"guida": "Chiediti che lavoro fa il pezzo, non di che materiale è fatto.",
		"correzione": "Quel materiale inganna: segui ciò che entra e ciò che esce.",
		"messaggi": [
			["La cisterna tiene l'acqua pronta a partire.", 0],
			["La batteria tiene la carica pronta a partire.", 0],
			["Il tubo collega la vasca alla ruota.", 1],
			["Il filo collega la pila alla lampada.", 1],
			["La valvola apre o chiude il passaggio.", 2],
			["L'interruttore apre o chiude il passaggio.", 2],
		],
	},
	# -- Mondo 9 · geografia ----------------------------------------------------
	"w09-alma": {
		"archetipo": ARCHETIPO_STIMA,
		"forma": FORMA_VELOCITA,
		"titolo": "Isole nel banco di nebbia",
		"consegna": "Il banco di nebbia cancella le coste. Regola la coordinata della boa e falla cadere sull'isola prima che passi oltre.",
		"convinzioneBersaglio": "I numeri non sono posti.",
		"vittoria": "La costa non c'era e ogni boa ha trovato l'isola. I numeri erano posti, e ci si arriva.",
		"sconfitta": "La nebbia ha preso tutto. Alma aspetta che si alzi, come fanno tutti qui.",
		"grandezza": "COORDINATA EST",
		"azione": "LANCIA LA BOA",
		"apertura": "Una nuova isola emerge nella nebbia.",
		"corto": "Troppo a ovest: la boa cade prima dell'isola.",
		"lungo": "Troppo a est: la boa supera la costa.",
		"centro": "Boa sull'isola.",
	},
	"w09-remo": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "La rotta che resta",
		"consegna": "La carta verrà ruotata quando salpa. Guarda la rotta adesso e riportala al faro quando il nord cambia.",
		"convinzioneBersaglio": "Una rotta si ricorda, non si scrive.",
		"vittoria": "La carta era girata e la rotta è rimasta leggibile. Remo incide la prima svolta prima di salpare.",
		"sconfitta": "Il nord è cambiato e la rotta si è persa. Remo aspetta che la carta torni come la ricordava.",
		"segnali": ["FARO", "EST 3", "BAIA", "NORD 2", "SCOGLIO", "OVEST 4", "PORTO"],
		"veloAzione": "RUOTA LA CARTA",
		"veloChiuso": "LA CARTA È RUOTATA",
		"veloParola": "C A R T A   R U O T A T A",
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
	"w10-mirta": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Diario-lampo",
		"consegna": "La serra cambia a ogni lampo. Salva sul diario soltanto ciò che la scena permette davvero di osservare.",
		"convinzioneBersaglio": "Io non faccio scienza, io guardo e basta.",
		"vittoria": "Il diario distingue cambiamenti, cose ferme e ipotesi. Mirta non ha soltanto guardato: ha costruito una traccia verificabile.",
		"sconfitta": "La crescita ha coperto la scena e il diario ha dei buchi. Mirta torna a guardare dal primo germoglio.",
		"destinazioni": ["È CAMBIATO", "È RIMASTO UGUALE", "È UN'IPOTESI"],
		"guida": "Registra ciò che puoi confrontare; tieni separate le spiegazioni.",
		"correzione": "Il diario deve distinguere quello che hai visto da quello che pensi sia successo.",
		"messaggi": [
			["Dopo la pioggia il fusto misura due tacche in più.", 0],
			["Il vaso è ancora sullo stesso ripiano.", 1],
			["Forse la pianta è cresciuta perché ha sentito la musica.", 2],
			["Tre foglie nuove sono comparse sul ramo alto.", 0],
			["Il colore del terriccio è identico alla scena prima.", 1],
			["Probabilmente il calore ha svegliato le radici.", 2],
		],
	},
	# -- Mondo 11 · storia ------------------------------------------------------
	"w11-danio": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "La piazza delle voci",
		"consegna": "Sul banco di Danio passano frasi che tutti ripetono. Timbra ciascuna con quello che è.",
		"convinzioneBersaglio": "Se lo dicono tutti, è vero.",
		"vittoria": "La piazza era piena e non contava niente. Danio guarda i timbri, non i numeri.",
		"sconfitta": "Il banco si è svuotato e le voci sono rimaste. Danio continua a contarle.",
		"scaffali": ["QUALCUNO L'HA VISTO", "L'HA SENTITO DIRE", "C'È UN OGGETTO"],
		"correzione": "Non è quello il timbro. Conta CHI lo dice, non quanti lo ripetono.",
		"destinazioni": ["TESTIMONE", "ECO", "REPERTO"],
		"guida": "Timbra la natura della fonte, non la sua popolarità.",
		"messaggi": [
			["«Nessuno sa chi costruì la Rovina.»", 1],
			["La campana del faro, esposta in piazza.", 2],
			["«Ero sul molo, e l'ho vista scendere.»", 0],
			["«Il ponte crollò di notte», ripetono tutti.", 1],
			["«L'ho aiutato a posare quella pietra.»", 0],
			["La lente bruciata del faro.", 2],
			["«C'ero, e faceva ancora giorno.»", 0],
			["Il registro dei transiti di quell'anno.", 2],
			["«Il faro si spense da solo», dice la piazza.", 1],
		],
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
	"w11-vesta": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Due cronache, una porta",
		"consegna": "Due cronache descrivono lo stesso giorno. Scegli il frammento che conserva accordi e differenze senza cancellarne una.",
		"convinzioneBersaglio": "Se due cronache si contraddicono, una delle due va bruciata.",
		"vittoria": "Proprio le differenze hanno aperto la porta. Vesta ripone entrambe le cronache nello stesso scaffale.",
		"sconfitta": "La porta resta chiusa. Le due cronache sono ancora integre: Vesta può rileggerle insieme.",
		"indizio": "CHE COSA POSSIAMO DIRE DAVVERO?",
		"guida": "Conserva il punto comune e nomina il disaccordo.",
		"correzione": "Quella conclusione cancella un dato: conserva l'accordo e lascia visibile la differenza.",
		"simboloScelta": "◊",
		"contatore": "Confronti",
		"turni": [
			{"richiesta": "A: il corteo partì all'alba. B: partì quando il sole era già alto.", "tipo": "L'ORA", "scelte": ["Partì di notte", "Partì, ma l'ora è controversa", "Una cronaca mente"], "giusta": 1},
			{"richiesta": "A: c'erano dodici carri. B: ricordo almeno dieci carri.", "tipo": "I CARRI", "scelte": ["C'erano almeno dieci carri", "Erano esattamente ventidue", "Non c'era nessun carro"], "giusta": 0},
			{"richiesta": "A: pioveva forte. B: la strada era asciutta quando arrivammo.", "tipo": "IL TEMPO", "scelte": ["Non possiamo ancora stabilirlo", "Pioveva e non pioveva nello stesso punto", "Bruciamo B"], "giusta": 0},
			{"richiesta": "A: la porta fu aperta dal fabbro. B: vidi la porta già aperta.", "tipo": "LA PORTA", "scelte": ["La porta rimase chiusa", "Il testimone B vide il fabbro", "La porta fu aperta; solo A nomina chi"], "giusta": 2},
		],
	},
	# -- Mondo 12 · logica ------------------------------------------------------
	"w12-quinto": {
		"archetipo": ARCHETIPO_GLIFI,
		"forma": FORMA_VELOCITA,
		"titolo": "Il labirinto mobile",
		"consegna": "I corridoi si spostano appena passi. Porta il passo dall'ingresso all'uscita, ogni volta che cambiano.",
		"convinzioneBersaglio": "Ricordare la strada è saperla.",
		"vittoria": "La strada era diversa tutte le volte e ci sei arrivato lo stesso. Quinto smette di contare i passi.",
		"sconfitta": "Il labirinto si è richiuso. Quinto rifà la strada di ieri, che oggi non c'è più.",
		"porte": ["SEGUE LA REGOLA", "VIOLA LA REGOLA"],
		"guidaGlifi": "FRECCIA azzurra = direzione attuale   ·   SEGNO dorato = regola del turno",
		"successoGlifi": "La decisione segue la regola di adesso, non la strada di ieri.",
		"correzione": "Il muro è cambiato: applica il segno dorato alla freccia che vedi ora.",
		"glifi": [
			{"radice": "^", "fine": "+90°", "funzione": 0},
			{"radice": "»", "fine": "DRITTO", "funzione": 0},
			{"radice": "v", "fine": "SINISTRA", "funzione": 1},
			{"radice": "«", "fine": "+180°", "funzione": 0},
			{"radice": "^", "fine": "INDIETRO", "funzione": 1},
			{"radice": "»", "fine": "-90°", "funzione": 0},
			{"radice": "«", "fine": "DRITTO", "funzione": 0},
			{"radice": "v", "fine": "+90°", "funzione": 1},
		],
	},
	"w12-isa": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il filo rosso",
		"consegna": "Isa ha inventato sette segni per il labirinto. Usali ora, poi verifica se portano fuori anche quando i muri spariscono.",
		"convinzioneBersaglio": "Se l'ho inventato io, allora non è un metodo vero.",
		"vittoria": "I segni hanno funzionato su un percorso che Isa non conosceva. Un metodo non diventa meno vero perché è nato qui.",
		"sconfitta": "Il filo si è interrotto, ma i segni possono cambiare. Isa ne sposta uno e prepara un'altra prova.",
		"segnali": ["ENTRA", "DESTRA", "PONTE", "SU", "SINISTRA", "ANELLO", "ESCI"],
		"veloAzione": "CHIUDI I MURI",
		"veloChiuso": "I MURI SONO CHIUSI",
		"veloParola": "M U R I   M O B I L I",
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
	"w13-duna": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Scuola delle distanze",
		"consegna": "Duna stima una traversata al primo sguardo. Lascia al drone riferimenti sufficienti per rifarla quando il paesaggio scompare.",
		"convinzioneBersaglio": "La mia è una dote, e le doti non si insegnano.",
		"vittoria": "Il drone ha rifatto la stima usando i riferimenti di Duna. Quello che sembrava una dote aveva passi che si potevano insegnare.",
		"sconfitta": "Il drone si è fermato senza riferimenti. Duna ripete il gesto più lentamente, cercando dove comincia davvero.",
		"segnali": ["OMBRA", "1 PASSO", "ALBERO", "3 PASSI", "TORRE", "MEZZO", "ARRIVO"],
		"veloAzione": "NASCONDI IL PAESAGGIO",
		"veloChiuso": "IL PAESAGGIO È NASCOSTO",
		"veloParola": "S E N Z A   P A E S A G G I O",
	},
	# -- Mondo 14 · italiano ----------------------------------------------------
	"w14-elmo": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Finale in fuga",
		"consegna": "La storia corre verso il finale. Salva ogni dettaglio nel punto di vista che poteva davvero raccoglierlo.",
		"convinzioneBersaglio": "Se so come finisce, ho capito.",
		"vittoria": "Il finale lo sapevi da subito, ma sono stati i punti di vista a spiegare come ci si è arrivati. Elmo rilegge la prima pagina.",
		"sconfitta": "Il montaggio non regge e la scena si sfalda. Elmo torna all'ultima pagina, che è quella che sa.",
		"destinazioni": ["CUOCA", "GIARDINIERE", "NIPOTE"],
		"guida": "Salva il dettaglio presso chi poteva vederlo o sentirlo.",
		"correzione": "Quella voce non era lì: segui posizione, vista e ascolto.",
		"messaggi": [
			["Dalla cucina si sentirono due voci e una porta.", 0],
			["Dalla vetrata si videro due sagome alzarsi.", 1],
			["All'arrivo la sedia era già rovesciata.", 2],
			["La pentola bolliva mentre in sala gridavano.", 0],
			["Sul sentiero c'erano impronte fresche verso il portone.", 1],
			["Sul tavolo restava una lettera aperta.", 2],
			["Il bicchiere cadde prima che la cucina si aprisse.", 0],
		],
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
	"w14-ottavia": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Tre voci, una stanza",
		"consegna": "Rimonta la stessa scena da tre punti della stanza. Scegli ogni volta ciò che quella voce poteva conoscere.",
		"convinzioneBersaglio": "Raccontare bene è un mestiere, non un modo di capire.",
		"vittoria": "Le tre voci insieme mostrano più di una sola. Ottavia rilegge il racconto come uno strumento per indagare.",
		"sconfitta": "Le voci si sono mescolate. Ottavia le separa di nuovo: nessuna ha ancora perso il proprio punto di vista.",
		"indizio": "CHI PUÒ SAPERLO?",
		"guida": "Segui posizione, vista e ascolto della voce.",
		"correzione": "Quella voce non poteva vedere o sentire quel dettaglio dalla sua posizione.",
		"simboloScelta": "•",
		"contatore": "Voci",
		"turni": [
			{"richiesta": "La cuoca è rimasta dietro la porta chiusa della cucina.", "tipo": "LA CUOCA", "scelte": ["Ho visto il mantello blu", "Ho sentito due voci e un bicchiere", "Ho contato i passi nel giardino"], "giusta": 1},
			{"richiesta": "Il giardiniere era fuori, davanti alla vetrata appannata.", "tipo": "IL GIARDINIERE", "scelte": ["Ho visto due sagome alzarsi", "Ho letto la lettera sul tavolo", "Ho sentito ogni parola"], "giusta": 0},
			{"richiesta": "Il nipote è arrivato dopo che tutti erano usciti.", "tipo": "IL NIPOTE", "scelte": ["Li ho visti litigare", "La sedia era rovesciata", "So chi ha gridato per primo"], "giusta": 1},
			{"richiesta": "La vicina ascoltava dal piano di sopra senza vedere la sala.", "tipo": "LA VICINA", "scelte": ["Il bicchiere era rosso", "Una voce giovane ha chiuso la porta", "La lettera era aperta"], "giusta": 1},
		],
	},
	# -- Mondo 15 · coding ------------------------------------------------------
	"w15-gru": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Guasto vivo",
		"consegna": "La macchina si riavvia da sola. Isola ogni segnale nel punto della catena in cui compare, prima che il registro si cancelli.",
		"convinzioneBersaglio": "L'errore è solo sfortuna.",
		"vittoria": "Il guasto si può rifare quando vuoi. Una cosa che si rifà a comando non è sfortuna.",
		"sconfitta": "Le prove sono finite e il guasto va e viene. Gru dà un colpo alla macchina, come sempre.",
		"destinazioni": ["PRIMA CAUSA", "CONSEGUENZA", "RUMORE"],
		"guida": "Cerca ciò che appare per primo e può spiegare ciò che segue.",
		"correzione": "Il segnale è reale, ma arriva dopo: non può essere l'inizio del guasto.",
		"messaggi": [
			["Il sensore di carico salta da 4 a 99.", 0],
			["Il nastro si ferma due istanti dopo.", 1],
			["Una spia decorativa lampeggia come sempre.", 2],
			["La memoria supera il limite prima del blocco.", 0],
			["Lo schermo diventa nero dopo l'arresto.", 1],
			["La ventola cambia tono col vento esterno.", 2],
			["Il contatore riceve due volte lo stesso pezzo.", 0],
			["L'allarme suona quando il nastro è già fermo.", 1],
		],
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
	"w15-pila": {
		"archetipo": ARCHETIPO_PROVA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il quaderno dei guasti",
		"consegna": "Il gioco si blocca in certe condizioni. Registra prove confrontabili e trova la condizione che ritorna.",
		"convinzioneBersaglio": "Scrivere le cose è da grandi, io gioco e basta.",
		"vittoria": "Il quaderno ha reso il guasto ripetibile. Pila non ha smesso di giocare: adesso sa anche spiegare perché si blocca.",
		"sconfitta": "Le prove sono finite e gli appunti si contraddicono. Pila apre una pagina pulita e cambia una regola alla volta.",
		"domanda": "QUALE CONDIZIONE BLOCCA IL GIOCO?",
		"successo": "Il gioco si blocca nello stesso punto.",
		"fallimento": "La corsa arriva al traguardo.",
		"fattori": [
			{"nome": "GIOCATORI", "valori": ["uno", "due"]},
			{"nome": "MAPPA", "valori": ["corta", "lunga"]},
			{"nome": "SALTO", "valori": ["normale", "doppio"]},
			{"nome": "SUONO", "valori": ["spento", "acceso"]},
			{"nome": "TURNO", "valori": ["primo", "secondo"]},
		],
	},
	# -- Mondo 16 · inglese -----------------------------------------------------
	"w16-talia": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Frontiera del contesto",
		"consegna": "Al valico ogni frase va letta per la scena che hai davanti. Scegli quella che passa.",
		"convinzioneBersaglio": "Ogni parola ha una sola traduzione.",
		"vittoria": "La stessa parola è passata più volte con significati diversi. Talia smette di cercarne uno solo.",
		"sconfitta": "Il valico si è chiuso. Talia riapre il quaderno alla pagina di sempre.",
		"destinazioni": ["AZIONE", "OGGETTO", "QUALITÀ"],
		"guida": "La scena decide che lavoro fa la parola in questa frase.",
		"correzione": "La traduzione esiste, ma non in questa scena: guarda che cosa succede attorno.",
		"messaggi": [
			["Please BOOK a room for two nights.", 0],
			["Put the BOOK on the desk.", 1],
			["Can you LIGHT the lamp?", 0],
			["This bag is very LIGHT.", 2],
			["Can you RUN the shop tomorrow?", 0],
			["That was a HARD climb.", 2],
			["The train is a FAST service.", 2],
			["They will FAST before the ceremony.", 0],
		],
		"indizio": "LA PAROLA CHE CAMBIA",
		"guidaMercato": "La parola è la stessa. La scena no.",
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
	"w16-marco": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il contratto delle cento parole",
		"consegna": "Al valico hai poche parole e richieste ambigue. Scegli la clausola precisa oppure domanda ciò che manca.",
		"convinzioneBersaglio": "Capirsi è questione di faccia tosta, non di parole.",
		"vittoria": "Il contratto regge perché quantità, tempo e condizioni sono espliciti. Marco conserva la faccia tosta e aggiunge le domande.",
		"sconfitta": "Il contratto lascia troppi varchi. Marco lo riprende: questa volta una domanda vale più di un sorriso.",
		"indizio": "CHE COSA MANCA?",
		"guida": "Se una frase ammette due azioni diverse, chiedi prima di firmare.",
		"correzione": "La clausola sembra sicura, ma lascia ancora due interpretazioni possibili.",
		"simboloScelta": "",
		"contatore": "Clausole",
		"turni": [
			{"richiesta": "Deliver the crates soon.", "tipo": "SOON", "scelte": ["Consegna quando puoi", "Chiedi giorno e ora", "Prometti domani"], "giusta": 1},
			{"richiesta": "Bring enough water.", "tipo": "ENOUGH", "scelte": ["Chiedi quanti litri e per quante persone", "Porta una bottiglia", "Porta tutto"], "giusta": 0},
			{"richiesta": "Use the good rope.", "tipo": "GOOD", "scelte": ["Scegli la più bella", "Chiedi carico e lunghezza richiesti", "Prendi la prima"], "giusta": 1},
			{"richiesta": "Wait near the gate.", "tipo": "NEAR", "scelte": ["Chiedi quale lato e quale distanza", "Aspetta dove capita", "Resta a casa"], "giusta": 0},
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
	"w17-coral": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il consiglio di risalire",
		"consegna": "I registri delle immersioni interrotte sono sparsi. Riponili per ciò che hanno insegnato alla prossima discesa.",
		"convinzioneBersaglio": "Chi ha smesso non ha più niente da insegnare.",
		"vittoria": "Ogni risalita anticipata ha lasciato un limite utile. Coral progetta la discesa riuscita con i dati di chi si è fermato.",
		"sconfitta": "I registri restano mescolati. Coral non li butta: una sosta e poi si rileggono.",
		"scaffali": ["LIMITE DEL CORPO", "LIMITE DEL MEZZO", "SEGNALE DELL'AMBIENTE"],
		"correzione": "Non conta quanto è durata: conta che cosa ha obbligato a risalire.",
		"parole": [
			["Fiato corto a quota 18", 0, "durata 100", 100],
			["Valvola dura a quota 14", 1, "durata 96", 96],
			["Corrente fredda da est", 2, "durata 92", 92],
			["Crampo alla gamba destra", 0, "durata 88", 88],
			["Vetro appannato", 1, "durata 84", 84],
			["Visibilità quasi nulla", 2, "durata 80", 80],
			["Capogiro alla svolta", 0, "durata 76", 76],
			["Cavo teso al limite", 1, "durata 72", 72],
			["Marea in risalita", 2, "durata 68", 68],
			["Mani senza sensibilità", 0, "durata 64", 64],
			["Luce di bordo spenta", 1, "durata 60", 60],
			["Fango sollevato dal fondo", 2, "durata 56", 56],
			["Battito troppo rapido", 0, "durata 52", 52],
			["Guarnizione allentata", 1, "durata 48", 48],
			["Banco di meduse", 2, "durata 44", 44],
			["Freddo alle spalle", 0, "durata 40", 40],
		],
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
	"w18-bea": {
		"archetipo": ARCHETIPO_VIBRAZIONE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Mappa dell'eco",
		"consegna": "Bea sente un percorso nella volta. Confronta il tremito dei nodi e consegna a un'altra cantante quello che hai trovato.",
		"convinzioneBersaglio": "Quello che faccio è un trucco, non musica.",
		"vittoria": "Un'altra voce ha seguito la stessa mappa. Il trucco di Bea aveva ritmo, ripetizione e un modo per essere condiviso.",
		"sconfitta": "L'eco non coincide ancora. Bea ripete il nodo lentamente: un trucco può diventare tecnica anche domani.",
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
	"w19-fiorina": {
		"archetipo": ARCHETIPO_PARENTELA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Erbario delle radici",
		"consegna": "Fiorina ha dato nomi alle piante da bambina. Formula un significato, illumina i parenti e verifica se la famiglia regge.",
		"convinzioneBersaglio": "I nomi che uso me li sono inventati da bambina.",
		"vittoria": "Le famiglie hanno previsto anche piante nuove. Fiorina aveva inventato nomi, ma non a caso: aveva visto una struttura.",
		"sconfitta": "L'erbario resta aperto. Fiorina stacca una sola foglia e ricomincia dagli indizi che si possono vedere.",
		"famiglie": [
			{"antica": "RUBRA", "significati": ["rossa", "amara", "alta"], "giusta": 0, "parenti": [{"parola": "RUBINO", "indizio": "pietra di colore rosso"}, {"parola": "RUBEDINE", "indizio": "rossore della pelle"}]},
			{"antica": "SPINA", "significati": ["liscia", "spinosa", "azzurra"], "giusta": 1, "parenti": [{"parola": "SPINETO", "indizio": "luogo pieno di spine"}, {"parola": "SPINOSO", "indizio": "coperto di spine"}]},
			{"antica": "ALBA", "significati": ["chiara", "curva", "salata"], "giusta": 0, "parenti": [{"parola": "ALBINO", "indizio": "con pigmento molto chiaro"}, {"parola": "ALBORE", "indizio": "prima luce chiara"}]},
			{"antica": "ODOR", "significati": ["odore", "radice", "seme"], "giusta": 0, "parenti": [{"parola": "ODOROSO", "indizio": "che emana un odore"}, {"parola": "DEODORARE", "indizio": "togliere un odore"}]},
			{"antica": "FOLIA", "significati": ["fiore", "foglia", "frutto"], "giusta": 1, "parenti": [{"parola": "FOGLIAME", "indizio": "insieme delle foglie"}, {"parola": "SFOGLIARE", "indizio": "togliere o voltare foglie"}]},
		],
	},
	# -- Mondo 20 · elettronica -------------------------------------------------
	"w20-sferza": {
		"archetipo": ARCHETIPO_STIMA,
		"forma": FORMA_VELOCITA,
		"titolo": "Sensore nella tempesta",
		"consegna": "La tempesta cambia il fondo del segnale. Regola la soglia finché il sensore legge il lampo senza amplificare il rumore.",
		"convinzioneBersaglio": "Se non legge, spingi di più.",
		"vittoria": "Non era la potenza. Sferza guarda la manopola che non aveva mai toccato.",
		"sconfitta": "Le prove sono finite e il sensore è ancora cieco. Sferza alza la potenza al massimo.",
		"grandezza": "SOGLIA",
		"azione": "CAMPIONA",
		"apertura": "Una nuova scarica attraversa il sensore.",
		"corto": "Soglia bassa: passa anche il rumore.",
		"lungo": "Soglia alta: il lampo viene tagliato.",
		"centro": "Lampo pulito.",
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
	"w20-quieto": {
		"archetipo": ARCHETIPO_PROVA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Prevedi il lampo",
		"consegna": "Quieto riconosce il lampo prima che arrivi. Metti alla prova i segnali e trova quello che permette anche al drone di prevederlo.",
		"convinzioneBersaglio": "Quello che faccio non si può insegnare: si è fatto da sé, guardando.",
		"vittoria": "Il drone ha previsto il lampo con lo stesso segnale. Quieto non ha perso il suo intuito: gli ha trovato un passo insegnabile.",
		"sconfitta": "I segnali sono ancora mescolati. Quieto li osserva di nuovo, uno per volta, insieme al drone.",
		"domanda": "QUALE SEGNALE PREVEDE IL LAMPO?",
		"successo": "Il drone chiude le ali prima del lampo.",
		"fallimento": "Il lampo arriva senza preavviso.",
		"fattori": [
			{"nome": "PRESSIONE", "valori": ["stabile", "in calo"]},
			{"nome": "VENTO", "valori": ["da sud", "da nord"]},
			{"nome": "RUMORE", "valori": ["basso", "alto"]},
			{"nome": "LUCE", "valori": ["chiara", "violacea"]},
			{"nome": "UMIDITÀ", "valori": ["ferma", "in salita"]},
		],
	},
	# -- Mondo 21 · geografia ---------------------------------------------------
	"w21-terza": {
		"archetipo": ARCHETIPO_CICLO,
		"forma": FORMA_VELOCITA,
		"titolo": "Atlante a catena",
		"consegna": "Gli eventi climatici arrivano a catena più in fretta di quanto Terza li sistemi. Prepara una volta la sequenza che li stabilizza.",
		"convinzioneBersaglio": "Ogni posto fa storia a sé.",
		"vittoria": "Nessuna regione era da sola: quello che passava di là arrivava di qua. Terza ridisegna l'atlante.",
		"sconfitta": "La catena si è spezzata a metà. Terza torna a guardare una regione per volta.",
		"comandi": ["OSSERVA", "COLLEGA", "STABILIZZA"],
		"pezzo": "evento climatico",
	},
	"w21-mino": {
		"archetipo": ARCHETIPO_PROVA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il calendario che prevede",
		"consegna": "Il calendario di Mino promette pioggia. Confronta i suoi segni con giornate diverse e trova quale rende la previsione verificabile.",
		"convinzioneBersaglio": "Il calendario è una tradizione, non una previsione.",
		"vittoria": "Una regola del calendario ha retto ai confronti e può essere aggiornata. La tradizione di Mino è diventata un modello.",
		"sconfitta": "Le giornate non distinguono ancora i segni. Mino conserva il calendario e aggiunge una colonna per la prossima stagione.",
		"domanda": "QUALE SEGNO ANTICIPA LA PIOGGIA?",
		"successo": "La pioggia arriva entro sera.",
		"fallimento": "La sera resta asciutta.",
		"fattori": [
			{"nome": "ALONE LUNARE", "valori": ["assente", "visibile"]},
			{"nome": "RONDINI", "valori": ["alte", "basse"]},
			{"nome": "MUSCHIO", "valori": ["asciutto", "umido"]},
			{"nome": "VENTO", "valori": ["da terra", "dal mare"]},
			{"nome": "CAMPANA", "valori": ["chiara", "ovattata"]},
		],
	},
	# -- Mondo 22 · scienze -----------------------------------------------------
	"w22-vesca": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Rete delle nicchie",
		"consegna": "La rete di Vesca si sta svuotando. Manda ogni specie alla nicchia in cui può mantenere vivo il resto della rete.",
		"convinzioneBersaglio": "Vince sempre il più forte.",
		"vittoria": "La rete regge, e non è piena dei più forti. Vesca conta le nicchie invece delle vittorie.",
		"sconfitta": "La rete si è svuotata. Vesca rimette in cima i più forti, che è quello che ha sempre fatto.",
		"scaffali": ["ACQUA BASSA", "SCOGLIERA", "MARE APERTO"],
		"correzione": "Lì non regge. Conta DOVE riesce a vivere, non quanto è forte.",
		"destinazioni": ["ACQUA BASSA", "SCOGLIERA", "MARE APERTO"],
		"guida": "La forza non decide la casa: guarda corpo, cibo e riparo.",
		"messaggi": [
			["Il capodoglio segue branchi nel mare aperto.", 2],
			["La murena caccia nelle fessure della scogliera.", 1],
			["Il ghiozzo resiste nelle pozze d'acqua bassa.", 0],
			["Il plancton viaggia sospeso al largo.", 2],
			["La patella aderisce alla roccia battuta dalle onde.", 1],
			["La passera si nasconde nella sabbia poco profonda.", 0],
			["Il tonno migra lontano dalla costa.", 2],
			["La cozza si ancora alla scogliera.", 1],
			["Il gambero cerca detriti nella risacca.", 0],
		],
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
	"w22-fondo": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "La guida che resta",
		"consegna": "Fondo mostra il passaggio una volta sola. Trasforma i suoi gesti in segni che un esploratore possa usare quando lui non c'è.",
		"convinzioneBersaglio": "Certe cose si mostrano, non si dicono.",
		"vittoria": "L'esploratore è arrivato senza Fondo. Il gesto non è stato sostituito: è diventato una guida che resta.",
		"sconfitta": "La guida si interrompe a metà. Fondo rifà il gesto; stavolta ogni svolta può lasciare un segno.",
		"segnali": ["BASSO", "FESSURA", "DESTRA", "CORDA", "SALI", "LUCE", "USCITA"],
		"veloAzione": "MANDA L'ESPLORATORE",
		"veloChiuso": "FONDO NON È CON LUI",
		"veloParola": "S E N Z A   G U I D A",
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
	"w23-ovidio": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Restauro clandestino",
		"consegna": "Le copie nascoste sono a pezzi. Restituisci a ciascun frammento autore, provenienza o traccia materiale.",
		"convinzioneBersaglio": "Quello che ho fatto è una disobbedienza, non un lavoro.",
		"vittoria": "Ogni frammento ha di nuovo un contesto verificabile. Ovidio non ha solo disobbedito: ha conservato e documentato.",
		"sconfitta": "I frammenti restano protetti, ma senza contesto. Ovidio prepara tre cartelle e ricomincia da ciò che si può provare.",
		"scaffali": ["AUTORE", "PROVENIENZA", "TRACCIA MATERIALE"],
		"correzione": "Non basta che il frammento sia importante: chiedi quale informazione porta davvero.",
		"parole": [
			["Firma abbreviata di L. Corvo", 0, "leggibile 100%", 100],
			["Timbro dell'Archivio del Nord", 1, "leggibile 96%", 96],
			["Carta con fibre di canapa blu", 2, "leggibile 92%", 92],
			["Iniziali O.V. sul margine", 0, "leggibile 88%", 88],
			["Numero di cassa del Porto Vecchio", 1, "leggibile 84%", 84],
			["Cera della candela del chiostro", 2, "leggibile 80%", 80],
			["Nota firmata dalla copista Ada", 0, "leggibile 76%", 76],
			["Sigillo della Torre Occidentale", 1, "leggibile 72%", 72],
			["Bruciatura da lampada a olio", 2, "leggibile 68%", 68],
			["Monogramma del maestro Elio", 0, "leggibile 64%", 64],
			["Etichetta del deposito sommerso", 1, "leggibile 60%", 60],
			["Cucitura con filo di rame", 2, "leggibile 56%", 56],
			["Correzione nella mano di Vesta", 0, "leggibile 52%", 52],
			["Mappa piegata verso la Radura", 1, "leggibile 48%", 48],
			["Polvere rossa del Cratere", 2, "leggibile 44%", 44],
			["Dedica firmata da Ovidio", 0, "leggibile 40%", 40],
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
			# convinzione di Tobia sarebbe uscita confermata.
			#
			# **Ritarato il 4 settembre 2026, e stavolta contro tre giocatori.**
			# Le tarature precedenti guardavano due strategie — uno per uno e a
			# gruppi — e ne mancava una terza che è quella che vinceva davvero:
			# **chi tocca a caso.** `minigiochi_cieco_probe` lo dava al 100% con
			# quindici tocchi, esattamente quanti ne faceva chi aveva capito.
			#
			# Adesso i tre numeri stanno separati, misurati al ritmo umano di due
			# tocchi al secondo:
			#
			#   uno per uno   63 tocchi   ~28 s   perde di larghezza
			#   a caso        ~23 tocchi  ~10,5 s perde
			#   a gruppi      12 tocchi   ~5,4 s  vince con oltre 3 s di margine
			#
			# Il tempo cresce meno della quantità (×1,98 contro ×2,10 dal mondo 1
			# al 24), così la strategia vecchia diventa sempre meno sufficiente.
			var pezzi := 60 + livello * 3
			return {
				"pezzi": pezzi,
				"secondi": 8.235 + float(livello) * 0.365,
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
		ARCHETIPO_ALTALENA:
			return {
				"prove": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5),
				"errori": 5,
				"distanze": 4,
				"secondi": 0.0,
			}
		ARCHETIPO_RITMO:
			# La conta è un gioco di scoperta: niente cronometro. Crescono le
			# strofe su cui riconoscere lo stesso salto, mentre annulla ed errori
			# restano disponibili anche nei replay avanzati.
			return {
				"strofe": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5),
				"errori": 4,
				"secondi": 0.0,
			}
		ARCHETIPO_VIBRAZIONE:
			# Nessun cronometro: confrontare due rappresentazioni dello stesso
			# ritmo deve premiare l'osservazione, non la velocità. Salendo di mondo
			# crescono le alternative e i confronti, mai la fretta o la precisione
			# richiesta al dito.
			return {
				"prove": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5),
				"corde": clampi(3 + int(floor(float(livello - 1) / 12.0)), 3, 4),
				"errori": 5,
				"secondi": 0.0,
			}
		ARCHETIPO_GLIFI:
			# Il testo non accelera: cresce il numero di pergamene. Ogni parola
			# resta ferma e leggibile per almeno sei secondi; movimento ridotto
			# applica poi il consueto +50% nel pannello.
			return {
				"glifi": clampi(6 + int(floor(float(livello - 1) / 4.0)), 6, 11),
				"secondi": maxf(6.0, 7.2 - float(livello) * 0.04),
				"errori": 3,
			}
		ARCHETIPO_PARENTELA:
			# Crescono le famiglie da ricostruire, non la fretta. Due parenti per
			# parola consentono di distinguere una somiglianza isolata da un
			# pattern; l'ipotesi resta sempre modificabile prima della conferma.
			return {
				"famiglie": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5),
				"indizi": 2,
				"errori": 5,
				"secondi": 0.0,
			}
		ARCHETIPO_PROVA:
			# Le prove concesse sono **esattamente quante ne servono cambiando una
			# cosa per volta**, più una. Non è avarizia: è l'unico modo perché il
			# metodo si veda. Con prove abbondanti anche il disordine arriva in
			# fondo, e allora il gioco non direbbe niente su come ci si arriva.
			var fattori := clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5)
			# **Un errore, non due.** (21 agosto 2026) Con tre fattori e due errori
			# concessi i tentativi di nome erano tre: si nominavano **tutti**, e la
			# prova controllata si vinceva senza fare un esperimento.
			# `minigiochi_cieco_probe` lo ha misurato — il 68% delle partite vinte
			# toccando a caso — ed e' esattamente cio' che questo archetipo dice di
			# smontare: la convinzione che la causa si trovi per forza bruta.
			#
			# Uno resta, e resta apposta: chi ha fatto gli esperimenti giusti e
			# legge male un esito ha diritto a ricredersi. Due erano l'intero
			# spazio delle risposte.
			return {
				"fattori": fattori,
				"prove": fattori + 1,
				"errori": 1,
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
