class_name TavoleRiferimento
extends RefCounted

## **Le tavole: dove il bambino può IMPARARE il fatto che gli verrà chiesto.**
## (1 settembre 2026)
##
## Richiesta del committente: «prepariamo delle slide per NORA a cui fare
## riferimento per cronologia e mappe. Dobbiamo evitare che lo studente si trovi
## a rispondere a domande che non può conoscere senza avere riferimenti didattici
## dove apprendere. Apprendere è lo scopo.»
##
## ### La misura che dà ragione alla segnalazione
##
## Misurato sui due banchi, contando le domande la cui risposta è un NOME (tre
## parole o meno, la stessa soglia di `KnowledgeCodex.RICHIAMO_MAX_PAROLE`):
##
##   storia      94 domande su 167 — il 56%
##   geografia  155 domande su 199 — il 78%
##
## Su `capitali` e `continenti`, 83 item, è il **100%**: «qual è la capitale
## della Norvegia?» non si ragiona, si sa o non si sa.
##
## Il gioco aveva già due strati di risposta, e nessuno dei due basta qui:
##
##   1. `NoraExplanations` spiega l'ARGOMENTO — «le capitali quasi mai sono al
##      centro geografico: stanno dove passavano i commerci». Vero, utile, e non
##      dice a nessuno che Oslo è la capitale della Norvegia.
##   2. `KnowledgeCodex.recall_lesson` (31 agosto) mette il NOME davanti alla
##      domanda: «Questo nome non te l'ha ancora detto nessuno: • Oslo». Meglio
##      di niente, ed è comunque un regalo — il nome arriva nudo un secondo
##      prima della domanda, senza un posto in cui stare.
##
## **Il pezzo che mancava è il posto.** Un fatto isolato si dimentica; un fatto
## con una coordinata — un punto sulla linea del tempo, un punto sulla carta —
## si ritrova da soli. È la differenza fra «Oslo» e «Oslo, in fondo a un fiordo,
## a nord, sull'Atlantico: la Norvegia è tutta costa».
##
## ### Che cos'è una tavola
##
## Una lavagna d'aula: un titolo, come si legge, e un elenco di voci ognuna con
## la sua **coordinata** e la sua **nota**. Tre famiglie, e il nome del campo
## della coordinata dice a quale famiglia appartiene la tavola:
##
##   `linea`   la cronologia — ogni voce ha un `quando` (e, quando è una data
##             precisa, un `anno` che permette di ordinarla e di generarci sopra
##             una prova);
##   `carta`   le mappe — ogni voce ha un `dove`, e se la carta muta del runtime
##             possiede quell'ancora anche un `target` (`MapGeometryCatalog`);
##   `scheda`  quello che non sta né su una linea né su una carta — i tipi di
##             fonte, il vocabolario della carta geografica: ogni voce ha un
##             `in_breve`.
##
## ### Il patto con il banco, ed è ciò che l'audit verifica
##
## Ogni voce dichiara in `risposte` le **stringhe esatte** che il banco accetta
## come risposta e che quella voce rende apprendibili. Non è ridondanza: è il
## legame verificabile fra ciò che si insegna e ciò che si chiede, ed è il solo
## modo di far fallire una build in cui qualcuno aggiunge una domanda su un fatto
## che nessuna tavola contiene. Vedi `tavole_riferimento_audit.gd`.
##
## Quando la risposta non è un fatto ma il risultato di una **regola** — «a quale
## secolo appartiene il 1789?» ha infinite risposte possibili e una regola sola —
## la voce dichiara `regola`, un'espressione regolare, e insegna la regola invece
## di elencare i casi.
##
## ### Perché le note sono scritte a mano e non raccolte dagli item
##
## Stesso motivo per cui `NoraExplanations` esiste: la spiegazione dell'item è la
## riformulazione della domanda («Roma è la capitale dell'Italia»). Qui serve la
## cosa che l'item non ha mai — il posto, il vicino, il perché sta lì.

const KIND_LINEA := "linea"
const KIND_CARTA := "carta"
const KIND_SCHEDA := "scheda"

## Il campo che porta la coordinata, per famiglia di tavola. Nomi diversi apposta:
## chi scrive una voce nuova si accorge di che cosa gli sta chiedendo la tavola.
const COORDINATA := {
	KIND_LINEA: "quando",
	KIND_CARTA: "dove",
	KIND_SCHEDA: "in_breve",
}

## Quante voci vicine accompagnano quella cercata dentro la scheda che NORA
## mostra. Due: la voce da sola resta un fatto isolato — cioè il difetto che
## queste tavole esistono per riparare — e cinque diventano un muro di testo
## davanti a una domanda sola.
const VICINI := 2

## Articoli e preposizioni che il banco mette davanti a una risposta e la tavola
## no: «Il Nilo» e «Nilo» sono lo stesso fatto, «Le Alpi» e «Alpi» pure.
const ARTICOLI := ["il ", "lo ", "la ", "i ", "gli ", "le ", "un ", "uno ", "una ", "l'", "un'"]

## --- STORIA: la linea del tempo, in sezioni --------------------------------
##
## Non una tavola per argomento a caso: **una linea sola, letta a pezzi**. La
## prima sezione insegna a leggerla (che cos'è un secolo, da che parte si conta),
## le altre sei sono tratti di quella stessa linea. È il motivo per cui ogni
## sezione dichiara `da` e `a`: chi guarda la sezione «Roma» deve poter dire dove
## sta rispetto alla sezione «Grecia», o la linea torna a essere un elenco.
const TAVOLE_STORIA := [
	{
		"id": "storia-come-si-conta-il-tempo",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["cronologia", "tempo", "ere", "epoca"],
		"titolo": "Come si legge la linea del tempo",
		"come_si_legge": "Il tempo scorre da sinistra a destra. Lo zero è la nascita di Cristo: a sinistra si conta all'indietro (a.C.), a destra in avanti (d.C.). Prima di Cristo il numero più GRANDE è l'anno più antico.",
		"voci": [
			{
				"label": "Il decennio",
				"quando": "10 anni",
				"risposte": ["decennio"],
				"nota": "Dieci anni. È l'unità più corta della storia, e si usa per i periodi vicini: quando un fatto è recente, dieci anni sono già una differenza che si vede.",
			},
			{
				"label": "Il secolo",
				"quando": "100 anni",
				"risposte": ["secolo", "Cento"],
				"nota": "Cento anni. I secoli si scrivono in numeri romani e cominciano dall'anno 1: dall'1 al 100 è il I secolo, dal 1901 al 2000 il XX.",
			},
			{
				"label": "Il millennio",
				"quando": "1000 anni, cioè 10 secoli",
				"risposte": ["millennio", "Mille", "10"],
				"nota": "Mille anni, cioè dieci secoli. Si usa per l'antichità e per la preistoria: là un secolo in più o in meno non cambia il racconto.",
			},
			{
				"label": "a.C. — prima di Cristo",
				"quando": "a sinistra dello zero",
				"risposte": ["a.C.", "prima di Cristo"],
				"nota": "«Avanti Cristo»: gli anni contati all'indietro a partire dalla nascita di Cristo. È l'unica numerazione della storia che va al contrario, ed è per questo che il 300 a.C. viene PRIMA del 100 a.C.",
			},
			{
				"label": "d.C. — dopo Cristo",
				"quando": "a destra dello zero",
				"risposte": ["d.C.", "dopo Cristo"],
				"nota": "«Dopo Cristo»: gli anni contati in avanti. Quando un anno non porta nessuna sigla si intende sempre d.C. — il 1492 è il 1492 d.C.",
			},
			{
				"label": "Da un anno al suo secolo",
				"quando": "una regola, non una data",
				"regola": "^[IVXLCDM]+ secolo$",
				"nota": "Si tolgono le ultime due cifre e si aggiunge uno: dal 1789 si ricava 17 + 1, cioè il XVIII secolo. L'eccezione sono gli anni tondi, che CHIUDONO il secolo invece di aprirlo: il 1900 è ancora XIX secolo, perché il XX comincia con il 1901.",
			},
			{
				"label": "Chi viene prima, fra due anni a.C.",
				"quando": "più grande = più antico",
				"risposte": ["300 a.C."],
				"nota": "Fra 300 a.C. e 100 a.C. viene prima il 300: si conta all'indietro, quindi il numero grande è l'anno lontano. È l'errore più frequente di tutta la cronologia.",
			},
			{
				"label": "Contare a cavallo dello zero",
				"quando": "da 50 a.C. a 50 d.C. sono 100 anni",
				"risposte": ["100"],
				"nota": "Quando un intervallo passa dallo zero i due tratti si SOMMANO invece di sottrarsi: cinquanta anni prima più cinquanta dopo fanno cento. Sottrarre 50 da 50 e rispondere zero è la trappola.",
			},
			{
				"label": "Nascita della scrittura",
				"quando": "3300 a.C. circa",
				"anno": -3300,
				"nota": "Il punto in cui la preistoria finisce e comincia la storia: da qui in poi gli uomini raccontano da soli quello che fanno, e non dobbiamo più indovinarlo dagli oggetti.",
			},
			{
				"label": "Primi Giochi olimpici",
				"quando": "776 a.C.",
				"anno": -776,
				"nota": "I Greci contavano gli anni a partire da qui, in gruppi di quattro. Ogni popolo sceglie un punto zero: il nostro è la nascita di Cristo, il loro era una gara.",
			},
			{
				"label": "Fondazione di Roma",
				"quando": "753 a.C.",
				"anno": -753,
				"risposte": ["753 a.C."],
				"nota": "La data della leggenda, non dello scavo: gli archeologi trovano capanne sul Palatino di quel periodo, e la città vera cresce lentamente. Resta il punto da cui i Romani contavano i propri anni.",
			},
			{
				"label": "Nascita di Cristo",
				"quando": "anno 0",
				"anno": 0,
				"nota": "Il punto da cui contiamo tutti gli altri anni. Non è l'anno in cui è successo di più: è l'anno che qualcuno, molto più tardi, ha scelto come origine della linea.",
			},
			{
				"label": "Caduta dell'Impero romano d'Occidente",
				"quando": "476 d.C.",
				"anno": 476,
				"risposte": ["476 d.C."],
				"nota": "L'evento con cui gli storici chiudono l'età antica e aprono il medioevo. Nessuno quella mattina si accorse di niente: le epoche si separano dopo, guardando indietro.",
			},
			{
				"label": "Incoronazione di Carlo Magno",
				"quando": "Natale dell'800",
				"anno": 800,
				"nota": "Trecento anni dopo la caduta di Roma qualcuno si fa incoronare imperatore di nuovo: è la misura di quanto a lungo l'idea di Roma sia sopravvissuta a Roma.",
			},
			{
				"label": "La scoperta dell'America",
				"quando": "1492",
				"anno": 1492,
				"risposte": ["La scoperta dell'America"],
				"nota": "L'evento con cui si chiude convenzionalmente il medioevo e comincia l'età moderna. «Convenzionalmente» vuol dire che è una scelta degli storici, comoda per orientarsi.",
			},
		],
	},
	{
		"id": "storia-preistoria",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["preistoria"],
		"titolo": "La linea del tempo · Preistoria",
		"come_si_legge": "Il tratto più lungo della linea, e il più povero di date: qui non ci sono anni precisi, ci sono passaggi. Ogni periodo prende il nome da quello che si sapeva FARE.",
		"da": -2500000,
		"a": -3300,
		"voci": [
			{
				"label": "Paleolitico",
				"quando": "fino a circa 10.000 anni fa",
				"risposte": ["paleolitico"],
				"nota": "«Pietra antica»: la pietra si SCHEGGIA, colpendola per ricavarne un filo tagliente. Si vive spostandosi, perché il cibo si trova dov'è.",
			},
			{
				"label": "La pietra scheggiata",
				"quando": "gli attrezzi del Paleolitico",
				"risposte": ["La pietra scheggiata"],
				"nota": "Una scheggia di selce taglia meglio di qualunque unghia o dente: è il primo attrezzo. Da come è lavorata la pietra gli archeologi capiscono in che periodo si trovano.",
			},
			{
				"label": "Caccia e raccolta",
				"quando": "come si mangiava nel Paleolitico",
				"risposte": ["Caccia e raccolta"],
				"nota": "Il cibo non si produce, si prende dove c'è: per questo si è nomadi. Finito il cibo in un posto ci si sposta, perché non c'è modo di farne crescere dell'altro.",
			},
			{
				"label": "Il fuoco",
				"quando": "circa 400.000 anni fa",
				"risposte": ["Il fuoco", "fuoco"],
				"nota": "Cuocere rende mangiabili cibi che crudi non lo sono, e il calore permette di vivere dove fa freddo. È la prima volta che l'uomo cambia l'ambiente invece di subirlo.",
			},
			{
				"label": "Neolitico",
				"quando": "da circa 10.000 anni fa",
				"risposte": ["neolitico"],
				"nota": "«Pietra nuova»: la pietra si LEVIGA, strofinandola fino a renderla liscia e regolare. È il tempo dell'agricoltura, degli animali allevati e dei primi villaggi.",
			},
			{
				"label": "L'agricoltura",
				"quando": "circa 10.000 anni fa, nel Neolitico",
				"risposte": ["L'agricoltura", "agricoltura"],
				"nota": "Chi semina deve tornare a raccogliere: coltivare vuol dire restare. Da qui nascono le case fisse, i villaggi e le scorte — e con le scorte, per la prima volta, chi le custodisce.",
			},
			{
				"label": "L'Età dei metalli",
				"quando": "dal 3500 a.C. circa",
				"risposte": ["Dal bronzo"],
				"nota": "Prima il rame, poi il bronzo (rame più stagno), poi il ferro. Ogni età porta il nome del metallo che si sapeva lavorare: l'Età del Bronzo si chiama così per il bronzo.",
			},
			{
				"label": "L'assenza della scrittura",
				"quando": "il confine fra preistoria e storia",
				"risposte": ["L'assenza della scrittura", "la scrittura"],
				"nota": "«Preistoria» vuol dire prima della storia scritta. Di quei millenni sappiamo soltanto quello che raccontano gli oggetti: nessuno ha lasciato scritto perché lo faceva.",
			},
		],
	},
	{
		"id": "storia-prime-civilta",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["civilta"],
		"titolo": "La linea del tempo · Le prime civiltà",
		"come_si_legge": "Tutte lungo un fiume, e tutte nello stesso tratto di linea. Non è una coincidenza: l'acqua permette l'agricoltura, l'agricoltura permette le città, le città producono la scrittura.",
		"da": -3500,
		"a": -800,
		"voci": [
			{
				"label": "Mesopotamia",
				"quando": "dal 3500 a.C.",
				"risposte": ["Mesopotamia"],
				"nota": "La terra fra il Tigri e l'Eufrate — è quello che il nome greco significa, «terra in mezzo ai fiumi». Qui nascono Sumeri e Babilonesi, e le prime città del mondo.",
			},
			{
				"label": "La scrittura",
				"quando": "3300 a.C. circa",
				"anno": -3300,
				"risposte": ["La scrittura"],
				"nota": "Nasce per contare, non per raccontare: le prime tavolette sono ricevute di sacchi di grano. È l'invenzione che segna il passaggio dalla preistoria alla storia.",
			},
			{
				"label": "La scrittura cuneiforme",
				"quando": "Sumeri, dal 3300 a.C.",
				"anno": -3300,
				"risposte": ["cuneiforme"],
				"nota": "Si incideva l'argilla fresca con una cannuccia dalla punta triangolare: i segni sembrano piccoli cunei, e da lì il nome. L'argilla poi seccava, ed è per questo che ne è arrivata fino a noi tantissima.",
			},
			{
				"label": "I Fenici",
				"quando": "dal 1200 a.C.",
				"anno": -1200,
				"risposte": ["Fenici"],
				"nota": "Mercanti delle coste del Libano. Portarono per il Mediterraneo un alfabeto di poche lettere, molto più maneggevole delle centinaia di segni cuneiformi: il nostro ne discende.",
			},
		],
	},
	{
		"id": "storia-egitto",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["egizi"],
		"titolo": "La linea del tempo · L'antico Egitto",
		"come_si_legge": "Tremila anni quasi uguali a sé stessi, ed è il fatto più sorprendente di questa sezione: l'Egitto dura più a lungo di tutto ciò che è venuto dopo. La ragione sta in una riga sola: il Nilo.",
		"da": -3100,
		"a": -30,
		"voci": [
			{
				"label": "Il Nilo",
				"quando": "tutta la storia egizia",
				"risposte": ["Il Nilo", "Nilo"],
				"nota": "Ogni anno il fiume straripava e lasciava sui campi il limo, una fanghiglia fertile. Senza quella piena l'Egitto sarebbe stato solo deserto: da lì dipendono il calendario, le tasse e perfino la religione.",
			},
			{
				"label": "I geroglifici",
				"quando": "dal 3200 a.C.",
				"anno": -3200,
				"risposte": ["Geroglifici", "geroglifici", "Geroglifica"],
				"nota": "La scrittura sacra degli Egizi, fatta di immagini: un occhio, un uccello, un'onda. Si incidevano nella pietra dei templi, e restarono illeggibili per secoli finché la stele di Rosetta non permise di decifrarli.",
			},
			{
				"label": "Il faraone",
				"quando": "dal 3100 a.C.",
				"anno": -3100,
				"risposte": ["Faraone"],
				"nota": "Il re dell'Egitto, considerato un dio in terra. Comandava l'acqua: decideva canali, magazzini e quanto grano tenere da parte — ed è per questo che il suo potere era così grande.",
			},
			{
				"label": "Il papiro",
				"quando": "dal 3000 a.C.",
				"anno": -3000,
				"risposte": ["Papiro", "papiro"],
				"nota": "Una pianta di palude del Nilo: si tagliava il fusto a strisce, si incrociavano due strati e si pressavano. Ne usciva un foglio leggero, molto più pratico dell'argilla — ed è da lì che viene la parola «carta» in tante lingue.",
			},
			{
				"label": "Le piramidi",
				"quando": "2600–2500 a.C.",
				"anno": -2600,
				"risposte": ["piramidi"],
				"nota": "Tombe monumentali a base quadrata per i faraoni. Stanno nel primo terzo della storia egizia: quando nasce Cleopatra le piramidi sono già antiche di duemilacinquecento anni.",
			},
			{
				"label": "Lo scriba",
				"quando": "tutta la storia egizia",
				"risposte": ["scriba"],
				"nota": "Il funzionario che sapeva leggere e scrivere e teneva i conti dei raccolti. Saper scrivere era un mestiere raro e un privilegio: lo scriba non pagava le tasse e non lavorava nei campi.",
			},
		],
	},
	{
		"id": "storia-grecia",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["grecia"],
		"titolo": "La linea del tempo · La Grecia antica",
		"come_si_legge": "Montagne e isole ovunque, nessuna pianura grande: per questo la Grecia non è mai stata un regno solo, ma centinaia di città indipendenti che parlavano la stessa lingua.",
		"da": -800,
		"a": -146,
		"voci": [
			{
				"label": "La pòlis",
				"quando": "dall'800 a.C.",
				"anno": -800,
				"risposte": ["Pòleis", "Una città-stato indipendente", "Una città-stato"],
				"nota": "Una città-stato indipendente: la città con la campagna intorno, con le sue leggi, le sue monete e il suo esercito. Al plurale si dice «pòleis». Erano centinaia, e si facevano guerra fra loro.",
			},
			{
				"label": "Le olimpiadi",
				"quando": "dal 776 a.C., ogni quattro anni",
				"anno": -776,
				"risposte": ["olimpiadi"],
				"nota": "Gare in onore di Zeus. Durante i giochi le guerre fra pòleis si fermavano: era l'unica cosa che tutti i Greci facessero insieme, e serviva a ricordarsi di essere un popolo solo.",
			},
			{
				"label": "Olimpia",
				"quando": "sede dei giochi, dal 776 a.C.",
				"risposte": ["A Olimpia"],
				"nota": "Il santuario nel Peloponneso dove si tenevano i Giochi. Non era una città potente: era un luogo sacro e neutrale, e per questo andava bene a tutti.",
			},
			{
				"label": "Sparta",
				"quando": "dal 700 a.C. circa",
				"anno": -700,
				"risposte": ["Sparta"],
				"nota": "La pòlis dell'addestramento militare: i bambini lasciavano casa a sette anni per la vita in comune e l'esercizio delle armi. Commercio, arte e scrittura contavano pochissimo.",
			},
			{
				"label": "Atene",
				"quando": "dal 508 a.C. la democrazia",
				"anno": -508,
				"risposte": ["Atene"],
				"nota": "La pòlis in cui nasce la democrazia: le decisioni si prendono in assemblea, votando. Votavano però solo i cittadini maschi adulti — non le donne, non gli stranieri, non gli schiavi.",
			},
			{
				"label": "Democrazia",
				"quando": "Atene, dal 508 a.C.",
				"risposte": ["Governo del popolo"],
				"nota": "Dal greco «demos» (popolo) e «kratos» (potere): governo del popolo. La parola dice esattamente la novità — prima decideva chi era nato per decidere.",
			},
			{
				"label": "L'agorà",
				"quando": "il centro di ogni pòlis",
				"risposte": ["agorà"],
				"nota": "La piazza principale: mercato al mattino, assemblea quando serviva. La democrazia nasce in un posto in cui la gente si trovava già ogni giorno per altri motivi.",
			},
		],
	},
	{
		"id": "storia-roma",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["roma"],
		"titolo": "La linea del tempo · Roma",
		"come_si_legge": "Tre forme di governo, una dopo l'altra e sempre in quest'ordine: prima i re, poi la repubblica, poi l'impero. Ogni passaggio nasce dalla crisi di quello prima.",
		"da": -753,
		"a": 476,
		"voci": [
			{
				"label": "Romolo e la fondazione",
				"quando": "753 a.C.",
				"anno": -753,
				"risposte": ["Romolo", "753 a.C."],
				"nota": "Secondo la leggenda Roma fu fondata da Romolo, il gemello allevato dalla lupa insieme a Remo. È il racconto che i Romani facevano di sé stessi: serviva a dire che la città era nata per volere degli dèi.",
			},
			{
				"label": "Roma sul Tevere",
				"quando": "dalla fondazione in poi",
				"risposte": ["Tevere", "Roma"],
				"nota": "La città nasce su sette colli accanto al Tevere, all'ultimo punto in cui il fiume si poteva guadare. Chi controlla il guado controlla chi passa: la posizione vale quanto la leggenda.",
			},
			{
				"label": "La monarchia",
				"quando": "753–509 a.C.",
				"anno": -753,
				"nota": "I primi due secoli e mezzo Roma ha dei re, sette secondo la tradizione. Finisce quando i Romani cacciano l'ultimo, Tarquinio il Superbo, e decidono di non averne più.",
			},
			{
				"label": "La repubblica",
				"quando": "509–27 a.C.",
				"anno": -509,
				"risposte": ["La repubblica"],
				"nota": "La forma di governo fra la monarchia e l'impero: nessun re, e le cariche durano un anno solo. «Res publica» vuol dire «cosa di tutti», ed è il contrario esatto di una cosa di uno.",
			},
			{
				"label": "I consoli",
				"quando": "durante la repubblica",
				"risposte": ["consoli"],
				"nota": "Due magistrati eletti ogni anno a capo della repubblica. Due, non uno, e per un anno solo: era il modo di impedire che qualcuno tornasse a comandare come un re.",
			},
			{
				"label": "Il senato",
				"quando": "dalla monarchia all'impero",
				"risposte": ["Il Senato", "senato"],
				"nota": "L'assemblea dei capifamiglia più autorevoli. Non votava le leggi da solo, ma consigliava — e a Roma il consiglio di chi aveva autorità pesava più di una regola scritta.",
			},
			{
				"label": "Le strade consolari",
				"quando": "dal 312 a.C. (via Appia)",
				"anno": -312,
				"risposte": ["strade consolari"],
				"nota": "Strade lastricate che collegavano Roma alle province, dritte e costruite a strati. Portavano le legioni in fretta, e dietro alle legioni arrivavano la lingua, le leggi e le città.",
			},
			{
				"label": "Augusto, primo imperatore",
				"quando": "27 a.C.",
				"anno": -27,
				"risposte": ["Augusto", "L'imperatore"],
				"nota": "Prese tutti i poteri lasciando in piedi le cariche della repubblica, e non si fece mai chiamare re. L'impero è guidato dall'imperatore, e comincia con lui.",
			},
			{
				"label": "Il latino",
				"quando": "tutta la storia romana",
				"risposte": ["Il latino"],
				"nota": "La lingua dei Romani, che seguì le strade e le legioni. Italiano, spagnolo, francese, portoghese e romeno sono latino che nessuno ha mai smesso di parlare.",
			},
			{
				"label": "La caduta dell'Impero d'Occidente",
				"quando": "476 d.C.",
				"anno": 476,
				"risposte": ["476 d.C."],
				"nota": "L'ultimo imperatore d'Occidente viene deposto. L'Impero d'Oriente, con capitale Costantinopoli, continua per altri mille anni: «cadde Roma» vuol dire che ne cadde metà.",
			},
		],
	},
	{
		"id": "storia-medioevo",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["medioevo"],
		"titolo": "La linea del tempo · Il medioevo",
		"come_si_legge": "Mille anni fra la caduta di Roma e la scoperta dell'America. Il filo che li tiene insieme è uno: senza uno Stato che protegge, ognuno cerca protezione da qualcuno più forte e in cambio gli deve qualcosa.",
		"da": 476,
		"a": 1492,
		"voci": [
			{
				"label": "I monasteri",
				"quando": "dal VI secolo",
				"anno": 529,
				"risposte": ["Nei monasteri"],
				"nota": "Nell'Alto Medioevo il sapere si conserva e si copia lì dentro. Non per caso: erano gli unici posti con muri sicuri, cibo garantito e gente che sapeva leggere.",
			},
			{
				"label": "I monaci amanuensi",
				"quando": "dal VI secolo",
				"anno": 529,
				"risposte": ["I monaci amanuensi"],
				"nota": "Copiavano i libri a mano, uno per volta. Se un testo antico è arrivato fino a noi è quasi sempre perché qualcuno lo ha ricopiato per secoli: ogni copia era l'unica assicurazione contro la perdita.",
			},
			{
				"label": "Lo scriptorium",
				"quando": "la stanza del monastero",
				"risposte": ["scriptorium"],
				"nota": "La sala in cui i monaci copiavano. Senza riscaldamento, per non tenere il fuoco vicino alle pergamene, e con le finestre esposte in modo da avere luce costante tutto il giorno.",
			},
			{
				"label": "Carlo Magno",
				"quando": "incoronato il 25 dicembre 800",
				"anno": 800,
				"risposte": ["Carlo Magno"],
				"nota": "Re dei Franchi, incoronato imperatore a Roma la notte di Natale dell'800. Riunì mezza Europa e volle scuole accanto alle chiese: dopo di lui l'impero si sfaldò di nuovo, ma l'idea rimase.",
			},
			{
				"label": "Il feudalesimo",
				"quando": "dal IX secolo",
				"anno": 800,
				"risposte": ["Feudalesimo", "feudalesimo"],
				"nota": "Il signore dà una terra — il feudo — e in cambio riceve fedeltà e servizio militare. È uno scambio, e quasi tutte le istituzioni medievali sono questo stesso scambio a livelli diversi.",
			},
			{
				"label": "I cavalieri",
				"quando": "dal IX secolo",
				"anno": 900,
				"risposte": ["Cavalieri"],
				"nota": "Guerrieri a cavallo al servizio di un signore. Armatura e cavallo costavano quanto un piccolo villaggio: per questo il signore doveva dare loro una terra, era il solo modo di mantenerli.",
			},
			{
				"label": "I comuni",
				"quando": "dall'XI secolo",
				"anno": 1100,
				"risposte": ["comuni"],
				"nota": "Città italiane che si diedero un governo autonomo. Rinascono dove ci sono commercio e mercato: chi produce ricchezza vuole decidere delle proprie regole.",
			},
			{
				"label": "La peste nera",
				"quando": "1347–1352",
				"anno": 1347,
				"risposte": ["peste nera"],
				"nota": "In cinque anni uccise circa un terzo degli europei. Arrivò con le navi mercantili dal Mar Nero: le stesse rotte che portavano ricchezza portarono il contagio.",
			},
		],
	},
	{
		"id": "storia-le-fonti",
		"subject": "storia",
		"kind": KIND_SCHEDA,
		"topics": ["fonti", "metodo"],
		"titolo": "Scheda · Come si sa quello che si sa",
		"come_si_legge": "La storia non si ricorda: si ricostruisce da quello che è rimasto. Questa scheda elenca i tipi di traccia e chi li studia — è il vocabolario con cui si risponde a «e tu come fai a saperlo?».",
		"voci": [
			{
				"label": "Fonte materiale",
				"in_breve": "oggetti, edifici, resti",
				"risposte": ["Materiale", "materiale", "fonti materiali"],
				"nota": "Un vaso, un muro, una piramide, un rifiuto sepolto. Non è stata prodotta per raccontare niente, e proprio per questo non mente: dice come si viveva, non come qualcuno voleva farlo sembrare.",
			},
			{
				"label": "Fonte scritta",
				"in_breve": "testi e documenti",
				"risposte": ["Scritta", "fonti scritte"],
				"nota": "Una lettera, un contratto, il diario di un soldato. Dice molto più di un oggetto, e ha un difetto in più: qualcuno l'ha scritta con uno scopo, e di quello scopo bisogna tenere conto.",
			},
			{
				"label": "Fonte orale",
				"in_breve": "testimonianze raccontate",
				"risposte": ["Orale"],
				"nota": "L'intervista a chi ha vissuto un fatto. Vale solo per il passato recente — nessuno può raccontarti il medioevo — e la memoria cambia i ricordi ogni volta che li ripete.",
			},
			{
				"label": "Fonte iconografica",
				"in_breve": "immagini",
				"risposte": ["Iconografica"],
				"nota": "Un affresco, un mosaico, una fotografia. Mostra cose che nessuno pensava di scrivere: com'erano vestiti, che attrezzi tenevano in mano, come si sedevano a tavola.",
			},
			{
				"label": "Fonte primaria e secondaria",
				"in_breve": "la traccia, oppure chi l'ha studiata",
				"risposte": ["Secondaria"],
				"nota": "Primaria è la traccia originale del passato; secondaria è chi la studia e la racconta — il tuo manuale di scuola, per esempio. Lo storico lavora sulle primarie e produce secondarie.",
			},
			{
				"label": "L'archeologia",
				"in_breve": "la scienza che scava",
				"risposte": ["archeologia"],
				"nota": "Studia il passato scavando nel terreno. Conta più DOVE si trova un oggetto che l'oggetto stesso: uno strato più profondo è più antico, e questo dà un'età a tutto ciò che contiene.",
			},
			{
				"label": "L'archeologo",
				"in_breve": "chi scava e interpreta",
				"risposte": ["Archeologo"],
				"nota": "Chi studia i resti sepolti nel terreno. Scava lentamente e annota tutto: un vaso estratto senza segnare da che strato veniva perde metà di quello che aveva da dire.",
			},
			{
				"label": "Lo storico",
				"in_breve": "chi ricostruisce dalle fonti",
				"risposte": ["Lo storico"],
				"nota": "Studia il passato usando le tracce che ha lasciato. Non racconta quello che è successo: racconta quello che le fonti permettono di sostenere — ed è una differenza, non una prudenza.",
			},
			{
				"label": "L'incrocio delle fonti",
				"in_breve": "il metodo",
				"risposte": ["incrocio delle fonti"],
				"nota": "Confrontare più fonti diverse per vedere se dicono la stessa cosa. Una fonte sola può sbagliare o mentire; due indipendenti che concordano sono molto più difficili da mettere in dubbio.",
			},
		],
	},
]

## --- GEOGRAFIA: le carte ----------------------------------------------------
##
## Stessa idea della linea del tempo, con l'altra coordinata. Una capitale
## imparata come parola è una parola; imparata come punto — nord, sull'Atlantico,
## in fondo a un fiordo — resta attaccata a un posto, e il posto si ritrova.
##
## Dove la carta muta del runtime possiede già l'ancora (`MapGeometryCatalog`),
## la voce la dichiara in `target`: è il filo che tiene insieme la tavola che
## insegna e il minigioco che chiede, e l'audit verifica che l'ancora esista.
const TAVOLE_GEOGRAFIA := [
	{
		"id": "geografia-carta-italia",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"mapId": "italy",
		"topics": ["geografia-italia", "italia", "italia-fisica", "geografia-fisica"],
		"titolo": "Carta dell'Italia",
		"come_si_legge": "Lunga e stretta, con il mare vicino ovunque e le montagne in mezzo: quasi tutto quello che si chiede sull'Italia si risponde guardando questa forma. Le Alpi chiudono a nord, gli Appennini scendono lungo tutta la penisola.",
		"voci": [
			{
				"label": "Le Alpi",
				"dove": "l'arco a nord, al confine con Francia, Svizzera e Austria",
				"target": "alps",
				"risposte": ["Le Alpi", "Alpi"],
				"nota": "Separano l'Italia dal resto d'Europa e la chiudono a nord. Sono le montagne più alte del continente, e i loro ghiacciai alimentano i fiumi della pianura padana.",
			},
			{
				"label": "Gli Appennini",
				"dove": "da nord a sud, lungo tutta la penisola",
				"target": "apennines",
				"risposte": ["Appennini"],
				"nota": "La «spina dorsale» d'Italia: percorrono la penisola per intero, dalla Liguria alla Calabria. È per colpa loro che le pianure italiane sono poche e piccole.",
			},
			{
				"label": "Il Po",
				"dove": "nord, attraversa la pianura da ovest a est",
				"target": "po",
				"risposte": ["Po"],
				"nota": "Il fiume più lungo d'Italia, 652 km. Nasce dal Monviso, raccoglie l'acqua di Alpi e Appennini e sfocia nell'Adriatico: la pianura in cui scorre l'ha costruita lui, con i detriti che ha depositato.",
			},
			{
				"label": "La pianura padana",
				"dove": "tutto il nord, fra Alpi e Appennini",
				"risposte": ["pianura padana"],
				"nota": "La pianura più estesa d'Italia. Prende il nome dal Po («padano» viene da Padus, il suo nome latino), ed è il posto in cui vive e lavora la maggior parte degli italiani.",
			},
			{
				"label": "La Sicilia",
				"dove": "a sud, oltre lo stretto di Messina",
				"target": "sicily",
				"risposte": ["Sicilia"],
				"nota": "L'isola più grande d'Italia e di tutto il Mediterraneo, ed è anche la regione italiana con la maggiore superficie. Dista dalla Calabria poco più di tre chilometri.",
			},
			{
				"label": "La Sardegna",
				"dove": "a ovest, in mezzo al Mar Tirreno",
				"target": "sardinia",
				"nota": "La seconda isola d'Italia e del Mediterraneo. È lontana dalla penisola molto più della Sicilia: per questo ha conservato una lingua e tradizioni proprie.",
			},
			{
				"label": "Le due isole maggiori",
				"dove": "Sicilia a sud, Sardegna a ovest",
				"risposte": ["Sicilia e Sardegna"],
				"nota": "Sono le due isole più grandi d'Italia e le prime due del Mediterraneo. Insieme fanno quasi un decimo del territorio italiano.",
			},
			{
				"label": "L'Etna",
				"dove": "Sicilia orientale, sopra Catania",
				"risposte": ["Etna"],
				"nota": "Il vulcano attivo più alto d'Europa, oltre 3300 metri, in eruzione quasi ogni anno. La terra vulcanica intorno è fertilissima: per questo ai suoi piedi si coltiva e si vive da sempre.",
			},
			{
				"label": "Il lago di Garda",
				"dove": "nord, fra Lombardia, Veneto e Trentino",
				"risposte": ["Lago di Garda"],
				"nota": "Il lago più esteso d'Italia. Come gli altri grandi laghi del nord è stato scavato da un ghiacciaio: la forma lunga e stretta è l'impronta che il ghiaccio ha lasciato scendendo.",
			},
			{
				"label": "Il mar Adriatico",
				"dove": "a est, fra la penisola e i Balcani",
				"target": "adriatic_sea",
				"risposte": ["Mar Adriatico", "Adriatico"],
				"nota": "Il mare della costa orientale, lungo e stretto. È poco profondo, soprattutto a nord: per questo è più caldo e le sue spiagge digradano piano.",
			},
			{
				"label": "Il mar Tirreno",
				"dove": "a ovest, fra la penisola, la Sardegna e la Sicilia",
				"target": "tyrrhenian_sea",
				"nota": "Il mare della costa occidentale, molto più profondo dell'Adriatico. Sotto di lui la crosta terrestre si muove ancora: da lì i vulcani delle Eolie, di Napoli e la stessa Etna.",
			},
			{
				"label": "Roma, capitale",
				"dove": "al centro, sul Tevere",
				"risposte": ["Roma"],
				"nota": "Capitale dal 1871, non dall'unità d'Italia: prima lo erano state Torino e Firenze. È l'unica capitale al mondo che ne contiene un'altra, lo Stato del Vaticano.",
			},
			{
				"label": "Le venti regioni",
				"dove": "tutta la carta",
				"risposte": ["20"],
				"nota": "L'Italia è divisa in venti regioni, cinque delle quali a statuto speciale. I confini seguono storie antiche: erano stati separati fino all'Ottocento, e ognuna ha conservato un'identità sua.",
			},
		],
	},
	{
		"id": "geografia-carta-europa",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"mapId": "europe",
		"topics": ["europa"],
		"titolo": "Carta dell'Europa",
		"come_si_legge": "Un continente piccolo e tutto frastagliato: penisole, isole, catene di monti. Sono quelle barriere ad averlo diviso in tanti Stati — dove c'è un confine, quasi sempre c'è prima una montagna o un mare.",
		"voci": [
			{
				"label": "L'Europa",
				"dove": "a ovest dell'Asia, oltre gli Urali",
				"risposte": ["Europa"],
				"nota": "Il secondo continente più piccolo, e l'unico che il mare non separa da quello accanto: verso l'Asia il confine è una convenzione decisa dagli uomini, non una costa.",
			},
			{
				"label": "I monti Urali",
				"dove": "a est, dentro la Russia, da nord a sud",
				"risposte": ["Monti Urali", "Urali"],
				"nota": "La catena scelta come confine fra Europa e Asia. Non separano davvero niente — si attraversano in auto senza accorgersene — ma servono a dare un limite a una divisione che il mare non fa.",
			},
			{
				"label": "Le Alpi",
				"dove": "al centro, fra Italia, Francia, Svizzera e Austria",
				"risposte": ["Alpi"],
				"nota": "La catena più alta d'Europa. Per secoli si sono attraversate solo ai valichi, e quei pochi passaggi hanno deciso dove passassero strade, commerci ed eserciti.",
			},
			{
				"label": "I Pirenei",
				"dove": "fra Francia e Spagna",
				"risposte": ["Pirenei"],
				"nota": "Chiudono la penisola iberica a nord. Sono una barriera più continua delle Alpi: la Spagna è rimasta a lungo un mondo a parte proprio perché da lì si passava male.",
			},
			{
				"label": "La penisola iberica",
				"dove": "a sud-ovest: Spagna e Portogallo",
				"target": "spain",
				"risposte": ["Penisola iberica", "penisola iberica"],
				"nota": "Bagnata dal Mediterraneo a est e dall'Atlantico a ovest, chiusa dai Pirenei a nord. Due mari e una montagna: è la ragione per cui da lì sono partite le prime navi per l'America.",
			},
			{
				"label": "Il Danubio",
				"dove": "da ovest a est, dalla Germania al Mar Nero",
				"risposte": ["Danubio"],
				"nota": "Attraversa dieci Paesi, più di ogni altro fiume al mondo, e passa per Vienna, Bratislava, Budapest e Belgrado. Un fiume navigabile è una strada che non serve costruire: per questo le capitali gli stanno addosso.",
			},
			{
				"label": "La Senna",
				"dove": "Francia del nord, attraversa Parigi",
				"target": "france",
				"risposte": ["Senna"],
				"nota": "Parigi è nata su un'isola in mezzo alla Senna: difendibile, e proprio dove il fiume si attraversava. La città si è allargata dopo, sulle due rive.",
			},
			{
				"label": "Il Volga",
				"dove": "Russia, scende verso il Mar Caspio",
				"risposte": ["Il Volga"],
				"nota": "Il fiume più lungo d'Europa, oltre 3500 km. Non sfocia in un oceano ma nel Caspio, che è un mare chiuso: è un fiume tutto interno, e la Russia lo ha usato come autostrada per secoli.",
			},
			{
				"label": "Il Mare del Nord",
				"dove": "a nord dell'Europa continentale",
				"risposte": ["Mare del Nord"],
				"nota": "Fra Regno Unito, Norvegia, Danimarca, Germania e Paesi Bassi. Poco profondo e pescosissimo, e sotto il fondale c'è petrolio: è uno dei mari più trafficati del pianeta.",
			},
			{
				"label": "Il mare Adriatico",
				"dove": "fra l'Italia e la penisola balcanica",
				"target": "balkans",
				"risposte": ["Adriatico"],
				"nota": "Un braccio lungo e stretto del Mediterraneo. Divide due coste molto diverse: bassa e sabbiosa a ovest, alta e rocciosa e piena di isole a est.",
			},
			{
				"label": "L'Ucraina",
				"dove": "a est, fra Polonia e Russia, sul Mar Nero",
				"target": "ukraine",
				"risposte": ["Ucraina"],
				"nota": "Lo Stato più esteso che sta interamente in Europa: la Russia è più grande, ma per la maggior parte sta in Asia. È fatta di pianure fertilissime, e la chiamavano il granaio d'Europa.",
			},
			{
				"label": "L'Unione Europea",
				"dove": "27 Stati del continente",
				"risposte": ["Unione Europea"],
				"nota": "Un'unione economica e politica: gli Stati che ne fanno parte hanno tolto i controlli ai confini e molti usano la stessa moneta, l'euro. Non è un Paese — ognuno resta sé stesso.",
			},
		],
	},
	{
		"id": "geografia-capitali-europa",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"mapId": "europe",
		"topics": ["capitali"],
		"titolo": "Atlante · Le capitali d'Europa",
		"come_si_legge": "Ogni riga è un Paese con la sua capitale e il posto in cui sta. Quasi tutte sorgono su un fiume o vicino al mare: le città nascono dove si può arrivare, e una capitale è prima di tutto un posto raggiungibile.",
		"voci": [
			{
				"label": "Italia · Roma",
				"dove": "al centro del Mediterraneo, sul Tevere",
				"target": "italy",
				"risposte": ["Roma", "Italia"],
				"nota": "Roma sorge sul Tevere, nell'Italia centrale. È l'unica capitale al mondo che ne contiene un'altra: lo Stato del Vaticano.",
			},
			{
				"label": "Francia · Parigi",
				"dove": "nord della Francia, sulla Senna",
				"target": "france",
				"risposte": ["Parigi", "Francia"],
				"nota": "Parigi è nata su un'isola in mezzo alla Senna, dove il fiume si poteva attraversare e difendere. Da lì la Francia è cresciuta tutta intorno, a raggiera.",
			},
			{
				"label": "Spagna · Madrid",
				"dove": "esattamente al centro della penisola iberica",
				"target": "spain",
				"risposte": ["Madrid", "Spagna"],
				"nota": "Una delle poche capitali davvero al centro geografico del proprio Paese, e non è un caso: fu scelta nel Cinquecento apposta perché non favorisse nessuna delle regioni già potenti.",
			},
			{
				"label": "Germania · Berlino",
				"dove": "nord-est della Germania, sulla Sprea",
				"target": "germany",
				"risposte": ["Berlino", "Germania"],
				"nota": "Berlino è rimasta divisa da un muro fino al 1989, e la capitale tedesca è stata per quarant'anni Bonn. È tornata capitale dopo la riunificazione.",
			},
			{
				"label": "Regno Unito · Londra",
				"dove": "sud-est dell'isola britannica, sul Tamigi",
				"target": "united_kingdom",
				"risposte": ["Londra", "Regno Unito"],
				"nota": "Londra è nata come porto romano sul Tamigi, abbastanza dentro terra da essere sicura e abbastanza vicina al mare da ricevere le navi. È ancora quello il motivo per cui sta lì.",
			},
			{
				"label": "Portogallo · Lisbona",
				"dove": "costa atlantica, alla foce del Tago",
				"risposte": ["Lisbona", "Portogallo"],
				"nota": "Un porto sull'Atlantico, rivolto verso l'oceano aperto invece che verso il Mediterraneo: da qui sono partite le navi che per prime hanno girato l'Africa.",
			},
			{
				"label": "Grecia · Atene",
				"dove": "sud-est della Grecia, vicino al mare Egeo",
				"target": "greece",
				"risposte": ["Atene", "Grecia"],
				"nota": "La stessa Atene della democrazia antica, a pochi chilometri dal suo porto, il Pireo. Poche capitali al mondo sono ancora nel posto in cui erano duemilacinquecento anni fa.",
			},
			{
				"label": "Austria · Vienna",
				"dove": "est dell'Austria, sul Danubio",
				"risposte": ["Vienna", "Austria"],
				"nota": "Sta sul Danubio, la grande via d'acqua che attraversa l'Europa: per secoli è stata la porta fra l'occidente e l'oriente del continente, e da lì si comandava un impero.",
			},
			{
				"label": "Belgio · Bruxelles",
				"dove": "centro del Belgio, nord-ovest d'Europa",
				"risposte": ["Bruxelles", "Belgio"],
				"nota": "È la sede delle principali istituzioni dell'Unione Europea: quando si dice «Bruxelles ha deciso» si intende quelle, non la città.",
			},
			{
				"label": "Paesi Bassi · Amsterdam",
				"dove": "nord-ovest, sul Mare del Nord",
				"risposte": ["Amsterdam", "Paesi Bassi"],
				"nota": "Costruita su pali piantati in una palude, attraversata da canali. Buona parte del Paese sta sotto il livello del mare, ed esiste solo perché è stata prosciugata e viene tenuta asciutta.",
			},
			{
				"label": "Polonia · Varsavia",
				"dove": "centro della Polonia, sulla Vistola",
				"target": "poland",
				"risposte": ["Varsavia", "Polonia"],
				"nota": "Distrutta quasi per intero nella Seconda guerra mondiale e ricostruita com'era, casa per casa, usando vecchi quadri e fotografie come progetto.",
			},
			{
				"label": "Svezia · Stoccolma",
				"dove": "costa orientale, sul Mar Baltico",
				"target": "sweden",
				"risposte": ["Stoccolma", "Svezia"],
				"nota": "È costruita su quattordici isole collegate da ponti, dove un lago incontra il Baltico. Il nome vuol dire «isola di pali»: anche qui si è costruito sull'acqua.",
			},
			{
				"label": "Norvegia · Oslo",
				"dove": "sud della Norvegia, in fondo a un fiordo",
				"target": "norway",
				"risposte": ["Oslo", "Norvegia"],
				"nota": "Sta in fondo a un lungo fiordo, cioè a una valle invasa dal mare. La Norvegia è quasi tutta costa e montagna: le città stanno dove il mare entra fra i monti.",
			},
			{
				"label": "Russia · Mosca",
				"dove": "parte europea della Russia, a ovest degli Urali",
				"risposte": ["Mosca", "Russia"],
				"nota": "La Russia si estende su due continenti, e la sua capitale sta nella parte europea — insieme alla gran parte dei suoi abitanti. La metà asiatica è enorme e quasi vuota.",
			},
			# Sei capitali che i banchi non chiedono e l'ABBINAMENTO sì, già al primo
			# mondo (`MinigameManager.MATCHING` · geografia · capitali). Stessa
			# famiglia, stessa promessa: se il gioco può chiederle, l'atlante deve
			# poterle insegnare.
			{
				"label": "Irlanda · Dublino",
				"dove": "isola a ovest della Gran Bretagna",
				"target": "ireland",
				"risposte": ["Dublino", "Irlanda"],
				"nota": "Un porto sulla costa orientale, quella rivolta verso la Gran Bretagna: è da quel lato che l'isola ha sempre commerciato con l'isola vicina e con il continente.",
			},
			{
				"label": "Danimarca · Copenaghen",
				"dove": "nord Europa, all'imbocco del Mar Baltico",
				"risposte": ["Copenaghen", "Danimarca"],
				"nota": "Sta su un'isola, proprio nello stretto per cui passano tutte le navi che entrano ed escono dal Baltico. Per secoli la Danimarca ha vissuto facendo pagare quel passaggio.",
			},
			{
				"label": "Finlandia · Helsinki",
				"dove": "nord-est, sul golfo di Finlandia",
				"target": "finland",
				"risposte": ["Helsinki", "Finlandia"],
				"nota": "La capitale più a nord dell'Unione Europea. La Finlandia è un Paese di laghi e foreste: gli abitanti stanno quasi tutti nella striscia meridionale, dove l'inverno è meno duro.",
			},
			{
				"label": "Ungheria · Budapest",
				"dove": "Europa centrale, sul Danubio",
				"risposte": ["Budapest", "Ungheria"],
				"nota": "Nasce da due città sulle due rive del Danubio, Buda e Pest, unite nell'Ottocento. Il nome tiene insieme tutte e due, ed è la storia della città scritta nel suo nome.",
			},
			{
				"label": "Croazia · Zagabria",
				"dove": "penisola balcanica, a est dell'Adriatico",
				"risposte": ["Zagabria", "Croazia"],
				"nota": "Sta nell'entroterra, non sulla costa che tutti conoscono: la Croazia è fatta di una parte continentale e di una lunghissima costa piena di isole, e il governo sta nella prima.",
			},
			{
				"label": "Repubblica Ceca · Praga",
				"dove": "Europa centrale, sulla Moldava",
				"risposte": ["Praga", "Repubblica Ceca"],
				"nota": "Nel cuore del continente, senza sbocco sul mare. È stata capitale d'impero e crocevia di strade: qui la posizione centrale ha contato più dell'accesso all'acqua.",
			},
			{
				"label": "Svizzera · Berna",
				"dove": "centro-ovest della Svizzera, sull'Aare",
				"risposte": ["Berna", "Svizzera"],
				"nota": "Non è la città più grande — lo sono Zurigo e Ginevra — ed è esattamente per questo che è stata scelta: una capitale piccola non dà il potere a nessuno dei cantoni maggiori.",
			},
		],
	},
	{
		"id": "geografia-capitali-mondo",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"topics": ["capitali"],
		"titolo": "Atlante · Le capitali del mondo",
		"come_si_legge": "Fuori dall'Europa la regola più utile è un'altra: la capitale quasi mai è la città più grande. Spesso è stata scelta, o costruita da zero, proprio per non dare il potere a una città già ricca.",
		"voci": [
			{
				"label": "Stati Uniti · Washington",
				"dove": "costa atlantica, a metà fra nord e sud",
				"risposte": ["Washington", "Stati Uniti"],
				"nota": "La città più grande è New York; la capitale è Washington, costruita apposta in un distretto che non appartiene a nessuno Stato, a metà strada fra il nord e il sud del Paese.",
			},
			{
				"label": "Canada · Ottawa",
				"dove": "sud-est del Canada, vicino al confine con gli Stati Uniti",
				"risposte": ["Ottawa", "Canada"],
				"nota": "Non è Toronto né Montréal, le due città grandi: fu scelta perché sta proprio sul confine fra la parte di lingua inglese e quella di lingua francese, e non favoriva nessuna delle due.",
			},
			{
				"label": "Messico · Città del Messico",
				"dove": "centro del Messico, su un altopiano a 2200 metri",
				"risposte": ["Città del Messico", "Messico"],
				"nota": "Sorge dov'era Tenochtitlán, la capitale azteca costruita su un lago. Il lago fu prosciugato, e la città oggi sprofonda lentamente perché poggia su quel fondo molle.",
			},
			{
				"label": "Brasile · Brasília",
				"dove": "interno del Paese, lontano dalla costa",
				"risposte": ["Brasília", "Brasile"],
				"nota": "Costruita da zero nel 1960 in mezzo al nulla, per spostare il centro del Paese lontano dalle città affollate della costa come Rio e San Paolo. È il caso più chiaro di capitale progettata a tavolino.",
			},
			{
				"label": "Argentina · Buenos Aires",
				"dove": "costa atlantica, sul Río de la Plata",
				"risposte": ["Buenos Aires", "Argentina"],
				"nota": "Un porto enorme sull'estuario del Río de la Plata. Da lì è passata quasi tutta l'emigrazione italiana verso l'Argentina, ed è per questo che il Paese ha tanti cognomi italiani.",
			},
			{
				"label": "Giappone · Tokyo",
				"dove": "costa orientale dell'isola principale",
				"risposte": ["Tokyo", "Giappone"],
				"nota": "La capitale storica era Kyoto: Tokyo lo è diventata nell'Ottocento, e il nome vuol dire «capitale dell'est». Oggi è la più grande area urbana del mondo.",
			},
			{
				"label": "Cina · Pechino",
				"dove": "nord-est della Cina",
				"risposte": ["Pechino", "Cina"],
				"nota": "Il nome vuol dire «capitale del nord», in coppia con Nanchino, «capitale del sud». Sta lontana dalla costa ricca e vicina al confine che per secoli era il pericolo: verso nord.",
			},
			{
				"label": "India · Nuova Delhi",
				"dove": "nord dell'India, nella pianura del Gange",
				"risposte": ["Nuova Delhi", "India"],
				"nota": "«Nuova» perché costruita accanto alla vecchia Delhi all'inizio del Novecento. La città più grande e più ricca è Mumbai, sulla costa: anche qui capitale e metropoli non coincidono.",
			},
			{
				"label": "Egitto · Il Cairo",
				"dove": "nord dell'Egitto, dove il Nilo si apre a delta",
				"risposte": ["Il Cairo", "Egitto"],
				"nota": "Sta esattamente dove il Nilo si divide per formare il delta, a due passi dalle piramidi di Giza. Tutto l'Egitto vive lungo il fiume: il resto è deserto.",
			},
			# Diciotto capitali che i banchi non chiedono e l'ABBINAMENTO sì, dal
			# mondo 12 in poi (`MinigameManager.MATCHING` · geografia · capitali).
			# Stessa promessa delle altre: se il gioco può chiederle, l'atlante
			# deve poterle insegnare — ed è ciò che l'audit verifica.
			{
				"label": "Thailandia · Bangkok",
				"dove": "sud-est asiatico, sul fiume Chao Phraya",
				"risposte": ["Bangkok", "Thailandia"],
				"nota": "Costruita su una pianura alluvionale attraversata da canali, poco sopra il livello del mare. La Thailandia è l'unico Paese del sud-est asiatico che non è mai stato colonia europea.",
			},
			{
				"label": "Vietnam · Hanoi",
				"dove": "nord del Vietnam, sul delta del fiume Rosso",
				"risposte": ["Hanoi", "Vietnam"],
				"nota": "Il nome vuol dire «dentro i fiumi». La città più grande è Ho Chi Minh, al sud: il Paese è lunghissimo e stretto, e capitale e metropoli stanno ai due capi opposti.",
			},
			{
				"label": "Corea del Sud · Seul",
				"dove": "nord-ovest della penisola coreana",
				"risposte": ["Seul", "Corea del Sud"],
				"nota": "A meno di cinquanta chilometri dal confine con la Corea del Nord: una capitale addossata alla frontiera, cosa rarissima, perché la divisione del Paese è arrivata dopo la città.",
			},
			{
				"label": "Indonesia · Giacarta",
				"dove": "isola di Giava, sud-est asiatico",
				"risposte": ["Giacarta", "Indonesia"],
				"nota": "L'Indonesia è fatta di più di diciassettemila isole, e la capitale sta su quella più popolosa. Sprofonda e si allaga: per questo il Paese ne sta costruendo una nuova nel Borneo.",
			},
			{
				"label": "Perù · Lima",
				"dove": "costa pacifica dell'America del Sud",
				"risposte": ["Lima", "Perù"],
				"nota": "Sul Pacifico, in una striscia desertica fra l'oceano e le Ande. Piove pochissimo — è una delle capitali più aride del mondo — perché una corrente marina fredda blocca le piogge.",
			},
			{
				"label": "Cile · Santiago",
				"dove": "centro del Cile, in una valle fra Ande e oceano",
				"risposte": ["Santiago", "Cile"],
				"nota": "Il Cile è lungo più di quattromila chilometri e largo in media duecento: la capitale sta nella parte centrale, l'unica con un clima mite fra il deserto a nord e i ghiacci a sud.",
			},
			{
				"label": "Colombia · Bogotà",
				"dove": "America del Sud, sulle Ande a 2600 metri",
				"risposte": ["Bogotà", "Colombia"],
				"nota": "Una delle capitali più alte del mondo, su un altopiano andino. Sta quasi sull'Equatore e non fa mai caldo: è l'altitudine a decidere la temperatura, non la latitudine.",
			},
			{
				"label": "Cuba · L'Avana",
				"dove": "isola dei Caraibi, a sud della Florida",
				"risposte": ["L'Avana", "Cuba"],
				"nota": "Un porto sul lato nord dell'isola, davanti agli Stati Uniti. Per secoli è stata la tappa obbligata delle flotte spagnole che tornavano in Europa cariche d'argento.",
			},
			{
				"label": "Nuova Zelanda · Wellington",
				"dove": "estremo sud dell'Isola del Nord, Oceania",
				"risposte": ["Wellington", "Nuova Zelanda"],
				"nota": "La capitale più a sud del mondo, e la più ventosa: sta nello stretto fra le due isole, dove il vento si incanala. La città più grande è Auckland, molto più a nord.",
			},
			{
				"label": "Turchia · Ankara",
				"dove": "centro della penisola anatolica, in Asia",
				"risposte": ["Ankara", "Turchia"],
				"nota": "La città più grande è Istanbul, l'unica al mondo a stare su due continenti: la capitale fu spostata ad Ankara, nell'entroterra, quando nacque la Turchia moderna.",
			},
			{
				"label": "Marocco · Rabat",
				"dove": "costa atlantica dell'Africa nord-occidentale",
				"risposte": ["Rabat", "Marocco"],
				"nota": "Un porto sull'Atlantico, non sul Mediterraneo: il Marocco si affaccia su due mari, separati dallo stretto di Gibilterra che lo divide dalla Spagna per soli 14 chilometri.",
			},
			{
				"label": "Ghana · Accra",
				"dove": "Africa occidentale, sul golfo di Guinea",
				"risposte": ["Accra", "Ghana"],
				"nota": "Sulla costa che gli europei chiamavano Costa d'Oro, per l'oro che vi si commerciava. Il Ghana fu il primo Paese dell'Africa nera a rendersi indipendente, nel 1957.",
			},
			{
				"label": "Nigeria · Abuja",
				"dove": "centro esatto della Nigeria, Africa occidentale",
				"risposte": ["Abuja", "Nigeria"],
				"nota": "Costruita apposta al centro del Paese nel 1991: la città più grande è Lagos, sulla costa, ma la capitale è stata messa in mezzo per non favorire nessuna delle regioni.",
			},
			{
				"label": "Kenya · Nairobi",
				"dove": "Africa orientale, su un altopiano vicino all'Equatore",
				"risposte": ["Nairobi", "Kenya"],
				"nota": "Sta a 1700 metri d'altezza, e per questo ha un clima mite pur essendo quasi sull'Equatore: salendo di quota la temperatura scende, e mille metri valgono come tanti gradi di latitudine.",
			},
			{
				"label": "Etiopia · Addis Abeba",
				"dove": "Africa orientale, sull'altopiano etiopico",
				"risposte": ["Addis Abeba", "Etiopia"],
				"nota": "A 2400 metri, una delle capitali più alte del mondo. L'Etiopia è l'unico Paese africano che non è mai stato colonizzato stabilmente, e ha un suo alfabeto e un suo calendario.",
			},
			{
				"label": "Arabia Saudita · Riad",
				"dove": "centro della penisola arabica, in pieno deserto",
				"risposte": ["Riad", "Arabia Saudita"],
				"nota": "Una grande città in mezzo al deserto, cresciuta con il petrolio. L'acqua arriva dal mare, dissalata e pompata per centinaia di chilometri: senza quella, lì non ci vivrebbe nessuno.",
			},
			{
				"label": "Iran · Teheran",
				"dove": "nord dell'Iran, ai piedi dei monti Elburz",
				"risposte": ["Teheran", "Iran"],
				"nota": "Ai piedi di una catena che supera i 5000 metri e la ripara dai venti del deserto. L'Iran è l'antica Persia: il nome del Paese è cambiato meno di un secolo fa.",
			},
			{
				"label": "Pakistan · Islamabad",
				"dove": "nord del Pakistan, ai piedi dell'Himalaya",
				"risposte": ["Islamabad", "Pakistan"],
				"nota": "Costruita da zero negli anni Sessanta: il nome vuol dire «città dell'Islam». La città più grande resta Karachi, sul mare, a più di mille chilometri di distanza.",
			},
			{
				"label": "Australia · Canberra",
				"dove": "sud-est, fra Sydney e Melbourne",
				"risposte": ["Canberra", "Australia"],
				"nota": "Costruita da zero a metà strada fra Sydney e Melbourne, che si contendevano il ruolo di capitale. Nessuna delle due l'ha spuntata: hanno fatto una città nuova in mezzo.",
			},
		],
	},
	{
		"id": "geografia-planisfero",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"topics": ["continenti", "mondo", "geografia-fisica"],
		"titolo": "Planisfero · Continenti, oceani e primati",
		"come_si_legge": "Sette continenti e cinque oceani, più i pochi posti che tengono un record: la vetta più alta, la fossa più profonda, il deserto più esteso. I primati si ricordano meglio degli elenchi, e servono da punti fermi per collocare tutto il resto.",
		"voci": [
			{
				"label": "I sette continenti",
				"dove": "tutta la carta",
				"risposte": ["7"],
				"nota": "Europa, Asia, Africa, America del Nord, America del Sud, Oceania, Antartide. Sono sette perché così li contiamo noi: alcuni Paesi ne insegnano sei, unendo le due Americhe.",
			},
			{
				"label": "Asia",
				"dove": "a est, il blocco più grande della carta",
				"risposte": ["Asia"],
				"nota": "Il continente più esteso e il più popoloso: qui stanno Cina, India, Giappone e la maggior parte degli esseri umani. Confina con l'Europa lungo gli Urali.",
			},
			{
				"label": "Africa",
				"dove": "a sud dell'Europa, oltre il Mediterraneo",
				"risposte": ["Africa"],
				"nota": "Attraversata dall'Equatore nel mezzo, e proprio per questo ha deserti caldissimi a nord e a sud e foresta pluviale al centro. Qui stanno il Sahara e l'Egitto.",
			},
			{
				"label": "Europa",
				"dove": "a nord-ovest, la penisola dell'Asia",
				"risposte": ["Europa"],
				"nota": "Il secondo continente più piccolo, e l'unico separato da quello accanto per convenzione e non dal mare. Qui stanno Italia, Francia, Spagna, Germania, Grecia e la parte abitata della Russia.",
			},
			{
				"label": "America del Nord",
				"dove": "a nord-ovest della carta, oltre l'Atlantico",
				"risposte": ["America del Nord"],
				"nota": "Canada, Stati Uniti e Messico. Si attacca all'America del Sud con una striscia sottilissima di terra, l'istmo di Panama, tagliato da un canale.",
			},
			{
				"label": "America del Sud",
				"dove": "a sud-ovest, sotto l'istmo di Panama",
				"risposte": ["America del Sud"],
				"nota": "Brasile, Argentina, Perù, Cile. Qui scorre il Rio delle Amazzoni, il fiume che porta più acqua al mondo, e corre la catena delle Ande lungo tutta la costa occidentale.",
			},
			{
				"label": "Oceania",
				"dove": "a sud-est, fra l'oceano Pacifico e l'Indiano",
				"risposte": ["Oceania"],
				"nota": "Australia, Nuova Zelanda e migliaia di isole sparse nel Pacifico. È il continente più piccolo, ed è fatto più di mare che di terra.",
			},
			{
				"label": "Antartide",
				"dove": "tutto il bordo inferiore della carta",
				"risposte": ["Antartide", "6"],
				"nota": "Il continente più freddo: coperto da ghiaccio spesso chilometri, senza abitanti stabili — ci vivono solo scienziati a turno. Per questo dei sette continenti quelli abitati stabilmente sono sei.",
			},
			{
				"label": "L'oceano Pacifico",
				"dove": "fra Asia e America, il più largo della carta",
				"risposte": ["Pacifico"],
				"nota": "L'oceano più esteso del pianeta: da solo copre un terzo della Terra, più di tutte le terre emerse messe insieme. Il nome gliel'ha dato Magellano, che lo trovò calmo.",
			},
			{
				"label": "L'oceano Atlantico",
				"dove": "fra Europa-Africa e le Americhe",
				"risposte": ["L'Oceano Atlantico"],
				"nota": "Separa l'Europa dall'America, ed è il secondo per estensione. È l'oceano che Colombo attraversò nel 1492, e quello su cui si affacciano quasi tutte le grandi capitali atlantiche.",
			},
			{
				"label": "La Fossa delle Marianne",
				"dove": "oceano Pacifico, a est delle Filippine",
				"risposte": ["Fossa delle Marianne"],
				"nota": "Il punto più profondo degli oceani: quasi 11.000 metri. Se ci si mettesse dentro l'Everest, sopra resterebbero ancora due chilometri d'acqua.",
			},
			{
				"label": "L'Everest",
				"dove": "Asia, sulla catena dell'Himalaya",
				"risposte": ["Everest"],
				"nota": "La montagna più alta della Terra: 8849 metri, fra Nepal e Cina. Cresce ancora di qualche millimetro all'anno, perché le due placche che l'hanno sollevata continuano a spingere.",
			},
			{
				"label": "L'Himalaya",
				"dove": "Asia, fra India e Cina",
				"risposte": ["Himalaya"],
				"nota": "La catena montuosa più alta del mondo, e la più giovane: è nata dallo scontro fra l'India e il resto dell'Asia, che continua tuttora.",
			},
			{
				"label": "Il Sahara",
				"dove": "Africa settentrionale, da ovest a est",
				"risposte": ["Sahara"],
				"nota": "Il deserto caldo più esteso del mondo, grande quasi quanto tutta l'Europa. Diecimila anni fa era verde e pieno di laghi: le pitture rupestri là dentro mostrano giraffe e coccodrilli.",
			},
			{
				"label": "Il Nilo",
				"dove": "Africa, dal centro verso il Mediterraneo",
				"risposte": ["Nilo"],
				"nota": "Il fiume più lungo dell'Africa, e uno dei due più lunghi del mondo insieme al Rio delle Amazzoni. Scorre verso NORD, che è la cosa che sorprende sempre guardando la carta.",
			},
			{
				"label": "L'equatore",
				"dove": "la linea orizzontale a metà carta",
				"risposte": ["equatore"],
				"nota": "La linea immaginaria che divide la Terra in due emisferi uguali. Sopra di essa il Sole arriva quasi a picco tutto l'anno: è per questo che lì fa caldo sempre.",
			},
			{
				"label": "La Russia, fra due continenti",
				"dove": "da est dell'Europa fino all'oceano Pacifico",
				"risposte": ["Russia", "Europa e Asia"],
				"nota": "Il Paese più grande del mondo per superficie, e l'unico che si estende su Europa e Asia insieme: il confine fra i due continenti, gli Urali, gli passa in mezzo.",
			},
			{
				"label": "L'India, il Paese più popoloso",
				"dove": "Asia meridionale, sotto l'Himalaya",
				"risposte": ["India"],
				"nota": "Dal 2023 è il Paese con più abitanti al mondo, davanti alla Cina: più di un miliardo e quattrocento milioni di persone in un territorio grande un decimo della Russia.",
			},
			{
				"label": "Il canale di Suez",
				"dove": "Egitto, fra Mediterraneo e Mar Rosso",
				"risposte": ["Canale di Suez"],
				"nota": "Un taglio artificiale di 193 km che evita alle navi di girare tutta l'Africa. Prima del 1869 da Genova a Bombay si facevano ottomila chilometri in più.",
			},
		],
	},
	{
		"id": "geografia-fasce-climatiche",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"topics": ["climi"],
		"titolo": "Planisfero · Le fasce del clima",
		"come_si_legge": "Le fasce sono orizzontali, e si leggono partendo dall'Equatore andando verso i poli: più ci si allontana dall'Equatore, meno luce arriva e più fa freddo. Poi corregge il mare, che smorza il caldo e il freddo di chi gli sta vicino.",
		"voci": [
			{
				"label": "Clima equatoriale",
				"dove": "la fascia sull'Equatore",
				"risposte": ["equatoriale", "Vicino all'Equatore"],
				"nota": "Caldo e piovoso tutti i mesi, senza stagioni: il Sole arriva quasi a picco tutto l'anno e non cambia mai abbastanza da fare inverno. È la zona in cui fa caldo dodici mesi su dodici.",
			},
			{
				"label": "La foresta pluviale",
				"dove": "sulla fascia equatoriale: Amazzonia, Congo, Indonesia",
				"risposte": ["Foresta pluviale"],
				"nota": "La grande foresta calda e piovosa dell'Equatore. Cresce lì perché ha insieme le due cose che servono a una pianta: caldo costante e acqua tutti i giorni.",
			},
			{
				"label": "Clima tropicale",
				"dove": "appena sopra e sotto la fascia equatoriale",
				"nota": "Caldo tutto l'anno ma con due stagioni nette, una secca e una delle piogge. È la fascia in cui stanno le savane, e più in là i grandi deserti caldi.",
			},
			{
				"label": "Il monsone",
				"dove": "Asia meridionale: India, sud-est asiatico",
				"risposte": ["monsone"],
				"nota": "Un vento che cambia direzione con le stagioni: d'estate soffia dal mare verso terra e porta piogge enormi, d'inverno al contrario e porta siccità. Da quel vento dipendono i raccolti di miliardi di persone.",
			},
			{
				"label": "Clima mediterraneo",
				"dove": "coste del Mediterraneo, Italia compresa",
				"risposte": ["Clima mediterraneo", "mediterraneo"],
				"nota": "Estati calde e secche, inverni miti e piovosi. È il mare a renderlo mite: l'acqua si scalda e si raffredda lentamente, e tiene la costa lontana dagli estremi.",
			},
			{
				"label": "Clima temperato",
				"dove": "fra i tropici e i circoli polari",
				"nota": "Quattro stagioni distinte. È la fascia in cui sta quasi tutta l'Europa, e non a caso è anche quella in cui vive la maggior parte degli esseri umani: né troppo caldo né troppo freddo per coltivare.",
			},
			{
				"label": "Clima polare",
				"dove": "attorno ai due poli",
				"risposte": ["polare"],
				"nota": "Freddissimo tutto l'anno, con il ghiaccio permanente. Il Sole arriva così inclinato che la sua luce si spalma su una superficie enorme e scalda pochissimo: è l'inclinazione, non la distanza.",
			},
		],
	},
	{
		"id": "geografia-vocabolario-della-carta",
		"subject": "geografia",
		"kind": KIND_SCHEDA,
		"topics": ["geografia-fisica", "geografia-umana"],
		"titolo": "Scheda · Le parole della carta",
		"come_si_legge": "Le parole che servono per leggere una carta e per descrivere chi ci abita. Non sono definizioni da imparare a memoria: sono i nomi delle cose che poi si cercano sulla carta.",
		"voci": [
			{
				"label": "Sorgente",
				"in_breve": "dove nasce un fiume",
				"risposte": ["sorgente"],
				"nota": "Il punto in cui l'acqua esce dal terreno e comincia a scorrere, quasi sempre in alto, in montagna. Da lì in poi il fiume può solo scendere: è la pendenza a decidere il suo percorso.",
			},
			{
				"label": "Foce",
				"in_breve": "dove un fiume finisce nel mare",
				"risposte": ["foce"],
				"nota": "Il punto in cui il fiume si getta nel mare o in un lago. Lì l'acqua rallenta e lascia cadere la terra che trasportava: se ne accumula tanta, si forma un delta.",
			},
			{
				"label": "Penisola",
				"in_breve": "terra circondata dal mare su tre lati",
				"risposte": ["penisola"],
				"nota": "Una lingua di terra col mare su tre lati e il quarto attaccato alla terraferma. Se il mare la circondasse tutta sarebbe un'isola: la differenza è quel lato che resta unito.",
			},
			{
				"label": "Stretto",
				"in_breve": "un braccio di mare fra due terre",
				"risposte": ["stretto"],
				"nota": "Il tratto di mare che separa due terre vicine e unisce due mari più grandi. Sono passaggi obbligati, ed è per questo che nella storia ci si è sempre combattuto: lo stretto di Messina, quello di Gibilterra.",
			},
			{
				"label": "La carta geografica",
				"in_breve": "la Terra ridotta su un foglio",
				"risposte": ["Carta geografica"],
				"nota": "Una rappresentazione ridotta e simbolica della realtà. «Ridotta» ha un prezzo: schiacciare una palla su un foglio deforma per forza qualcosa, e ogni carta sceglie che cosa sacrificare.",
			},
			{
				"label": "I punti cardinali",
				"in_breve": "nord, sud, est, ovest",
				"risposte": ["Est"],
				"nota": "Il Sole sorge a est e tramonta a ovest: è il modo più antico di orientarsi, e funziona ancora. Sulle carte il nord sta in alto per convenzione, non perché sia «sopra».",
			},
			{
				"label": "Densità di popolazione",
				"in_breve": "abitanti per chilometro quadrato",
				"risposte": ["densità di popolazione", "Bassa"],
				"nota": "Quante persone vivono in un chilometro quadrato. Un Paese enorme con pochi abitanti — la Russia, il Canada — ha densità bassa anche se in totale la gente è tanta: conta lo spazio, non il totale.",
			},
			{
				"label": "Migrazione",
				"in_breve": "spostarsi per andare a vivere altrove",
				"risposte": ["migrazione"],
				"nota": "Lo spostamento di persone da un paese a un altro per viverci. Si parte quasi sempre per gli stessi tre motivi: lavoro, guerra, o un ambiente diventato invivibile.",
			},
			{
				"label": "Urbanizzazione",
				"in_breve": "dalle campagne alle città",
				"risposte": ["urbanizzazione"],
				"nota": "Il passaggio di popolazione dalle campagne alle città. È cominciata con le fabbriche, che avevano bisogno di operai tutti nello stesso posto, e non si è più fermata.",
			},
		],
	},
]

# --- API ---------------------------------------------------------------------

static func tutte() -> Array:
	return TAVOLE_STORIA + TAVOLE_GEOGRAFIA

static func tavola_di_id(id: String) -> Dictionary:
	for tavola in tutte():
		if str((tavola as Dictionary).get("id", "")) == id:
			return tavola
	return {}

## Tutte le tavole che servono un argomento. Sono più di una apposta: le capitali
## stanno su due carte (Europa e resto del mondo), e la geografia fisica si
## incontra sia sulla carta d'Italia sia sul planisfero. Chi cerca un fatto le
## attraversa tutte; chi deve mostrarne una prende la prima.
static func tavole_per(subject: String, topic: String) -> Array:
	var out: Array = []
	for tavola_data in tutte():
		var tavola: Dictionary = tavola_data
		if str(tavola.get("subject", "")) != subject:
			continue
		if Array(tavola.get("topics", [])).has(topic):
			out.append(tavola)
	return out

static func ha_tavola(subject: String, topic: String) -> bool:
	return not tavole_per(subject, topic).is_empty()

## Il campo che porta la coordinata di questa voce, qualunque sia la famiglia
## della tavola: «753 a.C.», «nord, in fondo a un fiordo», «oggetti e resti».
static func coordinata_di(tavola: Dictionary, voce: Dictionary) -> String:
	var campo := str(COORDINATA.get(str(tavola.get("kind", "")), ""))
	return str(voce.get(campo, "")).strip_edges()

## **Confronto per forma, non per stringa.** Il banco scrive «Il Nilo» dove la
## tavola scrive «Nilo», «Le Alpi» dove la tavola scrive «Alpi», e «Brasília»
## con l'accento che altrove non c'è. Sono lo stesso fatto: minuscole, accenti
## via, articolo iniziale via, punteggiatura di contorno via.
##
## Gli accenti si tolgono per il confronto e MAI per la resa: sulla scheda il
## bambino legge «pòlis» e «agorà» come si scrivono.
static func normalizza(testo: String) -> String:
	var s := testo.strip_edges().to_lower()
	var accenti := {"à": "a", "á": "a", "â": "a", "è": "e", "é": "e", "ê": "e",
		"ì": "i", "í": "i", "î": "i", "ò": "o", "ó": "o", "ô": "o",
		"ù": "u", "ú": "u", "û": "u"}
	for chiave in accenti:
		s = s.replace(str(chiave), str(accenti[chiave]))
	for segno in ["«", "»", "\"", "…", "?", "!", ".", ",", ";", ":"]:
		# Il punto NON si toglie da «a.C.»: solo dai bordi della stringa.
		while s.begins_with(str(segno)):
			s = s.substr(str(segno).length())
		while s.ends_with(str(segno)) and not s.ends_with("a.c.") and not s.ends_with("d.c."):
			s = s.substr(0, s.length() - str(segno).length())
	s = s.strip_edges()
	for articolo in ARTICOLI:
		if s.begins_with(str(articolo)):
			s = s.substr(str(articolo).length()).strip_edges()
			break
	while s.contains("  "):
		s = s.replace("  ", " ")
	return s

## Le stringhe che una voce dichiara di rendere apprendibili: l'etichetta più
## tutto ciò che sta in `risposte`.
static func _chiavi_di(voce: Dictionary) -> Array:
	var out: Array = [normalizza(str(voce.get("label", "")))]
	for risposta in Array(voce.get("risposte", [])):
		out.append(normalizza(str(risposta)))
	return out

## La voce che insegna questa risposta, con la tavola che la contiene:
## `{"tavola": {...}, "voce": {...}, "indice": n}`. Vuoto se nessuna la copre —
## ed è esattamente il caso che `tavole_riferimento_audit.gd` fa fallire.
static func trova(subject: String, topic: String, risposta: String) -> Dictionary:
	var cercata := normalizza(risposta)
	if cercata == "":
		return {}
	for tavola_data in tavole_per(subject, topic):
		var tavola: Dictionary = tavola_data
		var voci: Array = tavola.get("voci", [])
		for indice in range(voci.size()):
			var voce: Dictionary = voci[indice]
			if _chiavi_di(voce).has(cercata):
				return {"tavola": tavola, "voce": voce, "indice": indice}
			var regola := str(voce.get("regola", ""))
			if regola != "":
				var re := RegEx.new()
				if re.compile(regola) == OK and re.search(str(risposta).strip_edges()) != null:
					return {"tavola": tavola, "voce": voce, "indice": indice}
	return {}

static func copre(subject: String, topic: String, risposta: String) -> bool:
	return not trova(subject, topic, risposta).is_empty()

## Serve agli ordinamenti a insieme: la tavola sostituisce l'elenco dei fatti
## nuovi solo se li contiene tutti, o il fatto rimasto fuori resterebbe muto.
static func copre_tutte(subject: String, topic: String, risposte: Array) -> bool:
	if risposte.is_empty():
		return false
	for risposta in risposte:
		if not copre(subject, topic, str(risposta)):
			return false
	return true

## --- La scheda che NORA mostra ----------------------------------------------

## Il metodo che accompagna una tavola, per famiglia. Non è la stessa frase per
## tutte: davanti a una linea del tempo si guardano le distanze, davanti a una
## carta si guarda la posizione, davanti a una scheda si guarda il criterio.
const METODO := {
	KIND_LINEA: "Cerca il punto sulla linea prima di rispondere: la data dice già chi viene prima e quanto lontano.",
	KIND_CARTA: "Cerca il posto sulla carta prima di rispondere: un nome attaccato a un punto si ritrova, un nome da solo si dimentica.",
	KIND_SCHEDA: "Chiediti a quale riga della scheda somiglia il caso che hai davanti: la riga porta il criterio, non solo il nome.",
}

const APERTURA := {
	KIND_LINEA: "Questo sta sulla linea del tempo: guardiamola prima che te lo chieda.",
	KIND_CARTA: "Questo sta sulla carta: guardiamola prima che te lo chieda.",
	KIND_SCHEDA: "Questo sta sulla scheda: leggiamola prima che te lo chieda.",
}

## Una riga di tavola: nome, coordinata, e sotto la nota.
static func riga_voce(tavola: Dictionary, voce: Dictionary, in_evidenza: bool) -> String:
	var coordinata := coordinata_di(tavola, voce)
	var testa := "%s %s" % ["•" if in_evidenza else "·", str(voce.get("label", ""))]
	if coordinata != "":
		testa += " — %s" % coordinata
	if not in_evidenza:
		return testa
	return "%s\n   %s" % [testa, str(voce.get("nota", ""))]

## **L'estratto: la voce cercata, dentro le sue vicine.** È il punto di tutto il
## file. Il nome da solo — «• Oslo» — è quello che il gioco faceva già, ed è un
## regalo: arriva un secondo prima della domanda e non lascia niente. Il nome con
## la sua coordinata e due righe accanto è un POSTO, e un posto si ritrova.
##
## Le vicine si prendono attorno alla voce, non dall'inizio della tavola: su una
## linea del tempo le righe accanto sono quello che è successo prima e dopo, e su
## una carta sono quello che sta lì vicino.
static func estratto(tavola: Dictionary, indici_in_evidenza: Array) -> String:
	var voci: Array = tavola.get("voci", [])
	if voci.is_empty():
		return ""
	var mostrati: Dictionary = {}
	for grezzo in indici_in_evidenza:
		var centro := int(grezzo)
		mostrati[centro] = true
		for scarto in range(1, VICINI + 1):
			if centro - scarto >= 0:
				mostrati[centro - scarto] = mostrati.get(centro - scarto, false)
			if centro + scarto < voci.size():
				mostrati[centro + scarto] = mostrati.get(centro + scarto, false)
	var ordinati: Array = mostrati.keys()
	ordinati.sort()
	var righe := PackedStringArray()
	righe.append(str(tavola.get("titolo", "")).to_upper())
	var precedente := -99
	for indice_data in ordinati:
		var indice := int(indice_data)
		if precedente >= 0 and indice > precedente + 1:
			righe.append("   …")
		righe.append(riga_voce(tavola, voci[indice], bool(mostrati[indice])))
		precedente = indice
	return "\n".join(righe)

## **La tavola dentro una lezione che esiste gia'.** (1 settembre 2026)
##
## Il caso che la sola `lezione()` non copre, e che e' il piu' frequente di
## tutti: il PRIMO incontro con un argomento. Li' `_decorate_teaching_session`
## costruisce la mini-lezione generale — «le capitali stanno dove passavano i
## commerci» — e con quella davanti il bambino si sente chiedere la capitale
## della Norvegia, che nessuno gli ha detto. La spiegazione c'era, il fatto no.
##
## Qui la tavola non apre una seconda scheda (due schede di fila non le legge
## nessuno): innesta il suo estratto dentro quella che sta gia' per aprirsi.
static func arricchisci(base: Dictionary, subject: String, topic: String, etichette: Array) -> Dictionary:
	if base.is_empty() or base.has("tavolaId"):
		return base
	var estratta := lezione(subject, topic, etichette, "")
	if estratta.is_empty():
		return base
	var out := base.duplicate(true)
	out["tavolaId"] = estratta["tavolaId"]
	out["facts"] = estratta["facts"]
	out["factsTitle"] = estratta["factsTitle"]
	var spiega := str(out.get("explanation", "")).strip_edges()
	var cornice := str(estratta.get("explanation", "")).strip_edges()
	if cornice != "" and not spiega.containsn(cornice):
		out["explanation"] = ("%s

%s" % [spiega, cornice]).strip_edges()
	return out

## La tavola per intero, per l'atlante consultabile (`KnowledgeCodexPanel`).
##
## Nella scheda che precede una domanda si mostra un estratto, perché lì la
## tavola serve a rispondere a QUELLA domanda. Nell'atlante no: lì il bambino è
## andato a cercarla, e quello che vuole è vederla tutta.
static func testo_completo(tavola: Dictionary) -> String:
	var righe := PackedStringArray()
	righe.append(str(tavola.get("come_si_legge", "")))
	righe.append("")
	for voce_data in Array(tavola.get("voci", [])):
		righe.append(riga_voce(tavola, voce_data, true))
	return "
".join(righe)

## Le tavole da mostrare nell'atlante per un argomento, già impaginate:
## `[{"titolo": ..., "testo": ...}]`.
static func pagine_per(subject: String, topic: String) -> Array:
	var out: Array = []
	for tavola_data in tavole_per(subject, topic):
		var tavola: Dictionary = tavola_data
		out.append({"titolo": str(tavola.get("titolo", "")), "testo": testo_completo(tavola)})
	return out

## La scheda pronta per `ExercisePlayer._show_teaching_overlay()`, nella stessa
## forma di `KnowledgeCodex.mini_lesson()` — così non serve un secondo layout.
##
## `etichette` sono le risposte che stanno per essere chieste. Restituisce {} se
## nessuna tavola le copre: chi chiama ricade sul comportamento di prima, che
## resta corretto anche se è più povero.
static func lezione(subject: String, topic: String, etichette: Array, spiegazione: String = "") -> Dictionary:
	var per_tavola: Dictionary = {}   # id tavola -> Array[int] indici
	var tavole: Dictionary = {}       # id tavola -> Dictionary
	for etichetta in etichette:
		var trovata := trova(subject, topic, str(etichetta))
		if trovata.is_empty():
			continue
		var tavola: Dictionary = trovata["tavola"]
		var id := str(tavola.get("id", ""))
		tavole[id] = tavola
		var indici: Array = per_tavola.get(id, [])
		if not indici.has(int(trovata["indice"])):
			indici.append(int(trovata["indice"]))
		per_tavola[id] = indici
	if per_tavola.is_empty():
		return {}
	# Una scheda sola per volta: due tavole diverse davanti alla stessa domanda
	# sono due lezioni, e la seconda non la legge nessuno. Vince quella che copre
	# più risposte di questa prova.
	var scelta := ""
	for id in per_tavola:
		if scelta == "" or Array(per_tavola[id]).size() > Array(per_tavola[scelta]).size():
			scelta = str(id)
	var tavola: Dictionary = tavole[scelta]
	var kind := str(tavola.get("kind", KIND_SCHEDA))
	var spiega := str(tavola.get("come_si_legge", "")).strip_edges()
	var dell_item := spiegazione.strip_edges()
	if dell_item != "" and not spiega.containsn(dell_item):
		spiega += "\n\n%s" % dell_item
	return {
		"subject": subject,
		"topic": topic,
		"tavolaId": scelta,
		"intro": str(APERTURA.get(kind, "")),
		"explanation": spiega,
		"facts": estratto(tavola, per_tavola[scelta]),
		"factsTitle": "DALLA TAVOLA DI NORA",
		"workedExample": {},
		"strategy": str(METODO.get(kind, "")),
		"watchOut": {},
	}
