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
##             `in_breve`;
##   `paradigma` le tabelle di una lingua a casi — le declinazioni latine, le
##             persone e i tempi del verbo: ogni voce è una CASELLA della tabella
##             e ha una `forma`, cioè come si scrive la parola quando fa quel
##             mestiere. (2 settembre 2026, vedi `TAVOLE_LATINO`.)
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
const KIND_PARADIGMA := "paradigma"

## Il campo che porta la coordinata, per famiglia di tavola. Nomi diversi apposta:
## chi scrive una voce nuova si accorge di che cosa gli sta chiedendo la tavola.
const COORDINATA := {
	KIND_LINEA: "quando",
	KIND_CARTA: "dove",
	KIND_SCHEDA: "in_breve",
	KIND_PARADIGMA: "forma",
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
				"risposte": ["Anno 0"],
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
				"risposte": ["La scoperta dell'America", "1492", "Colombo arriva in America"],
				"nota": "L'evento con cui si chiude convenzionalmente il medioevo e comincia l'età moderna. «Convenzionalmente» vuol dire che è una scelta degli storici, comoda per orientarsi.",
			},
		],
	},
	{
		"id": "storia-preistoria",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["preistoria", "cronologia"],
		"titolo": "La linea del tempo · Preistoria",
		"come_si_legge": "Il tratto più lungo della linea, e il più povero di date: qui non ci sono anni precisi, ci sono passaggi. Ogni periodo prende il nome da quello che si sapeva FARE.",
		"da": -2500000,
		"a": -3300,
		"voci": [
			{
				"label": "Paleolitico",
				"quando": "fino a circa 10.000 anni fa",
				"risposte": ["paleolitico", "Pietra antica", "Gli uomini vivevano nelle caverne", "Prime pitture rupestri"],
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
				"risposte": ["neolitico", "Pietra nuova"],
				"nota": "«Pietra nuova»: la pietra si LEVIGA, strofinandola fino a renderla liscia e regolare. È il tempo dell'agricoltura, degli animali allevati e dei primi villaggi.",
			},
			{
				"label": "L'agricoltura",
				"quando": "circa 10.000 anni fa, nel Neolitico",
				"risposte": ["L'agricoltura", "agricoltura", "Nascita dell'agricoltura", "Nascono l'agricoltura e i primi villaggi"],
				"nota": "Chi semina deve tornare a raccogliere: coltivare vuol dire restare. Da qui nascono le case fisse, i villaggi e le scorte — e con le scorte, per la prima volta, chi le custodisce.",
			},
			{
				"label": "L'Età dei metalli",
				"quando": "dal 3500 a.C. circa",
				"risposte": ["Dal bronzo", "Eta' del rame", "Eta' del bronzo", "Eta' del ferro"],
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
		"topics": ["civilta", "cronologia"],
		"titolo": "La linea del tempo · Le prime civiltà",
		"come_si_legge": "Tutte lungo un fiume, e tutte nello stesso tratto di linea. Non è una coincidenza: l'acqua permette l'agricoltura, l'agricoltura permette le città, le città producono la scrittura.",
		"da": -3500,
		"a": -800,
		"voci": [
			{
				"label": "Mesopotamia",
				"quando": "dal 3500 a.C.",
				"risposte": ["Mesopotamia", "Prime città sumere"],
				"nota": "La terra fra il Tigri e l'Eufrate — è quello che il nome greco significa, «terra in mezzo ai fiumi». Qui nascono Sumeri e Babilonesi, e le prime città del mondo.",
			},
			{
				"label": "La scrittura",
				"quando": "3300 a.C. circa",
				"anno": -3300,
				"risposte": ["La scrittura", "Invenzione della scrittura"],
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
				"label": "Il codice di Hammurabi",
				"quando": "1750 a.C. circa",
				"anno": -1750,
				"risposte": ["Codice di Hammurabi", "1750 a.C."],
				"nota": "Il primo grande codice di leggi scritte della storia, inciso su una stele di pietra nera perché tutti potessero vederlo. Prima le leggi si tramandavano a voce, e cambiavano da un giudice all'altro.",
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
		"topics": ["egizi", "cronologia"],
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
				"risposte": ["piramidi", "Costruzione delle piramidi di Giza", "Vengono costruite le piramidi d'Egitto"],
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
		"topics": ["grecia", "cronologia"],
		"titolo": "La linea del tempo · La Grecia antica",
		"come_si_legge": "Montagne e isole ovunque, nessuna pianura grande: per questo la Grecia non è mai stata un regno solo, ma centinaia di città indipendenti che parlavano la stessa lingua.",
		"da": -1200,
		"a": -146,
		"voci": [
			{
				"label": "La guerra di Troia",
				"quando": "1200 a.C. circa (tradizione)",
				"anno": -1200,
				"risposte": ["Guerra di Troia (tradizione)"],
				"nota": "Il racconto più antico della cultura greca, narrato secoli dopo da Omero: probabilmente nasce da uno scontro vero fra città sulla costa dell'Asia Minore, ingigantito dalla leggenda.",
			},
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
				"risposte": ["olimpiadi", "Si disputano i primi Giochi olimpici", "776 a.C."],
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
				"risposte": ["Governo del popolo", "Democrazia ad Atene", "Nascita della democrazia ad Atene", "Ad Atene nasce la democrazia", "508 a.C."],
				"nota": "Dal greco «demos» (popolo) e «kratos» (potere): governo del popolo. La parola dice esattamente la novità — prima decideva chi era nato per decidere.",
			},
			{
				"label": "Il Partenone",
				"quando": "447–438 a.C.",
				"anno": -447,
				"risposte": ["Costruzione del Partenone", "Partenone", "447 a.C."],
				"nota": "Il tempio della dea Atena sull'Acropoli, costruito nel momento di massima ricchezza di Atene: si finanziò anche con i tributi delle altre città alleate, che avrebbero dovuto servire alla guerra comune.",
			},
			{
				"label": "L'impero di Alessandro Magno",
				"quando": "336–323 a.C.",
				"anno": -330,
				"risposte": ["Impero di Alessandro Magno"],
				"nota": "In tredici anni conquistò tutto l'impero persiano, arrivando fino all'India. Dopo di lui la cultura greca — lingua, arte, città — si sparse in un territorio enorme: è l'età che si chiama ellenistica.",
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
		"topics": ["roma", "cronologia"],
		"titolo": "La linea del tempo · Roma",
		"come_si_legge": "Tre forme di governo, una dopo l'altra e sempre in quest'ordine: prima i re, poi la repubblica, poi l'impero. Ogni passaggio nasce dalla crisi di quello prima.",
		"da": -753,
		"a": 476,
		"voci": [
			{
				"label": "Romolo e la fondazione",
				"quando": "753 a.C.",
				"anno": -753,
				"risposte": ["Romolo", "753 a.C.", "Fondazione di Roma (tradizione)", "Viene fondata Roma"],
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
				"label": "Cesare conquista la Gallia",
				"quando": "58–52 a.C.",
				"anno": -52,
				"risposte": ["Cesare in Gallia", "Cesare conquista la Gallia", "Giulio Cesare conquista la Gallia", "52 a.C."],
				"nota": "Otto anni di campagna militare raccontati da lui stesso, nel «De bello Gallico»: la vittoria gli diede un esercito fedele e una fama enorme, ed è quello che gli permise poi di prendere il potere a Roma.",
			},
			{
				"label": "Augusto, primo imperatore",
				"quando": "27 a.C.",
				"anno": -27,
				"risposte": ["Augusto", "L'imperatore", "Augusto imperatore", "Augusto primo imperatore", "Impero", "27 a.C."],
				"nota": "Prese tutti i poteri lasciando in piedi le cariche della repubblica, e non si fece mai chiamare re. L'impero è guidato dall'imperatore, e comincia con lui.",
			},
			{
				"label": "Il latino",
				"quando": "tutta la storia romana",
				"risposte": ["Il latino"],
				"nota": "La lingua dei Romani, che seguì le strade e le legioni. Italiano, spagnolo, francese, portoghese e romeno sono latino che nessuno ha mai smesso di parlare.",
			},
			{
				"label": "L'eruzione del Vesuvio",
				"quando": "79 d.C.",
				"anno": 79,
				"risposte": ["Eruzione di Pompei", "Eruzione che seppellisce Pompei", "Il Vesuvio seppellisce Pompei", "79 d.C."],
				"nota": "Il Vesuvio seppellì Pompei ed Ercolano sotto metri di cenere in poche ore. È una disgrazia che ha conservato tutto: case, cibo, scritte sui muri — la fotografia più dettagliata che abbiamo di una città romana.",
			},
			{
				"label": "L'inaugurazione del Colosseo",
				"quando": "80 d.C.",
				"anno": 80,
				"risposte": ["Inaugurazione del Colosseo"],
				"nota": "Il più grande anfiteatro dell'impero, aperto con cento giorni di giochi. Poteva riempirsi e svuotarsi in pochi minuti grazie a decine di ingressi numerati: la stessa idea degli stadi di oggi.",
			},
			{
				"label": "La caduta dell'Impero d'Occidente",
				"quando": "476 d.C.",
				"anno": 476,
				"risposte": ["476 d.C.", "Caduta dell'Impero Romano d'Occidente", "Caduta di Roma d'Occidente", "Cade l'Impero Romano d'Occidente"],
				"nota": "L'ultimo imperatore d'Occidente viene deposto. L'Impero d'Oriente, con capitale Costantinopoli, continua per altri mille anni: «cadde Roma» vuol dire che ne cadde metà.",
			},
		],
	},
	{
		"id": "storia-medioevo",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["medioevo", "cronologia"],
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
				"risposte": ["Carlo Magno", "Incoronazione di Carlo Magno", "800 d.C."],
				"nota": "Re dei Franchi, incoronato imperatore a Roma la notte di Natale dell'800. Riunì mezza Europa e volle scuole accanto alle chiese: dopo di lui l'impero si sfaldò di nuovo, ma l'idea rimase.",
			},
			{
				"label": "Il feudalesimo",
				"quando": "dal IX secolo",
				"anno": 800,
				"risposte": ["Feudalesimo", "feudalesimo", "Si costruiscono i castelli e le cattedrali"],
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
				"label": "La prima crociata",
				"quando": "1096–1099",
				"anno": 1096,
				"risposte": ["Prima crociata", "1096"],
				"nota": "Migliaia di cavalieri partirono verso Gerusalemme rispondendo all'appello del papa: religione, avventura e la ricerca di terre nuove viaggiavano insieme, ed è difficile separarle nelle motivazioni di chi partì.",
			},
			{
				"label": "I comuni",
				"quando": "dall'XI secolo",
				"anno": 1100,
				"risposte": ["comuni"],
				"nota": "Città italiane che si diedero un governo autonomo. Rinascono dove ci sono commercio e mercato: chi produce ricchezza vuole decidere delle proprie regole.",
			},
			{
				"label": "Il viaggio di Marco Polo",
				"quando": "1271–1295",
				"anno": 1271,
				"risposte": ["Viaggio di Marco Polo", "Viaggio di Marco Polo in Cina", "Marco Polo arriva in Cina", "1271"],
				"nota": "Un mercante veneziano attraversò l'Asia fino alla Cina di Kublai Khan e ci restò diciassette anni. Il libro che raccontò il viaggio fece scoprire all'Europa un mondo di cui non sapeva quasi nulla.",
			},
			{
				"label": "La peste nera",
				"quando": "1347–1352",
				"anno": 1347,
				"risposte": ["peste nera", "La peste nera in Europa", "1347"],
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
	{
		"id": "storia-popoli-antichi",
		"subject": "storia",
		"kind": KIND_CARTA,
		"topics": ["civilta"],
		"titolo": "Atlante · I popoli antichi e dove vivevano",
		"come_si_legge": "Ogni civiltà nasce in un posto preciso, e quel posto spiega quasi tutto il resto: che cosa mangiava, come si spostava, con chi commerciava o faceva guerra. Il popolo e il luogo sono la stessa domanda.",
		"voci": [
			{
				"label": "Egizi",
				"dove": "lungo il Nilo, nell'Africa nord-orientale",
				"risposte": ["Egizi", "lungo il Nilo", "Nilo", "Piramidi"],
				"nota": "Una striscia strettissima di terra fertile intorno a un fiume, con il deserto su entrambi i lati: l'Egitto è nato lì e non altrove perché il Nilo era l'unica acqua per centinaia di chilometri.",
			},
			{
				"label": "Sumeri",
				"dove": "fra i fiumi Tigri ed Eufrate, in Mesopotamia",
				"risposte": ["Sumeri", "fra Tigri ed Eufrate", "Tigri ed Eufrate", "Ziggurat"],
				"nota": "I due fiumi della Mesopotamia si comportavano peggio del Nilo, con piene improvvise e irregolari: per governarle i Sumeri costruirono i primi canali, e con i canali le prime città.",
			},
			{
				"label": "Fenici",
				"dove": "sulle coste del Libano, sul Mediterraneo orientale",
				"risposte": ["Fenici", "sulle coste del Libano", "coste del Libano"],
				"nota": "Una striscia di costa stretta fra il mare e le montagne, senza grandi pianure da coltivare: per vivere i Fenici si voltarono verso il mare, e diventarono i migliori navigatori e mercanti del Mediterraneo.",
			},
			{
				"label": "Etruschi",
				"dove": "in Toscana e nel Lazio settentrionale",
				"risposte": ["Etruschi", "in Toscana", "Toscana"],
				"nota": "Una terra ricca di metalli — ferro e rame — che gli Etruschi lavoravano e vendevano in cambio di ceramiche e vino greco. Da loro i Romani presero l'arco, le fogne e persino l'alfabeto.",
			},
			{
				"label": "Vichinghi",
				"dove": "in Scandinavia",
				"risposte": ["Vichinghi", "in Scandinavia"],
				"nota": "Terra fredda, poca da coltivare, ma con fiordi profondi che davano riparo alle navi. I Vichinghi costruirono imbarcazioni capaci di risalire i fiumi e di attraversare l'oceano, ed è per questo che arrivarono così lontano.",
			},
			{
				"label": "Inca",
				"dove": "sulle Ande, in America del Sud",
				"risposte": ["Inca", "sulle Ande", "Ande"],
				"nota": "Un impero costruito lungo una catena di montagne altissime: per tenerlo insieme gli Inca costruirono migliaia di chilometri di strade di pietra, che ancora oggi in parte si percorrono.",
			},
			{
				"label": "Aztechi",
				"dove": "sull'altopiano del Messico",
				"risposte": ["Aztechi", "in Messico", "altopiano del Messico"],
				"nota": "Costruirono la loro capitale, Tenochtitlán, su un'isola in mezzo a un lago: per avere terra da coltivare inventarono gli orti galleggianti, zattere di canne coperte di terra fertile.",
			},
			{
				"label": "Cinesi antichi",
				"dove": "lungo il Fiume Giallo, in Asia orientale",
				"risposte": ["Cinesi", "Cinesi antichi", "lungo il Fiume Giallo", "Fiume Giallo"],
				"nota": "Il Fiume Giallo prende il nome dal limo giallastro che trasporta e deposita: quel limo rende fertilissima la pianura intorno, ma il fiume esonda spesso ed è per questo chiamato anche «il dolore della Cina».",
			},
			{
				"label": "Celti",
				"dove": "in Gallia, l'attuale Francia",
				"risposte": ["Celti", "in Gallia"],
				"nota": "Un insieme di popoli imparentati, non un regno unico, sparsi su gran parte dell'Europa centrale e occidentale. Erano famosi come fabbri del ferro, e da loro viene la tecnica della ruota cerchiata di metallo.",
			},
			{
				"label": "Romani",
				"dove": "nel Lazio, sul fiume Tevere",
				"risposte": ["Romani", "nel Lazio", "Colosseo", "Tevere"],
				"nota": "Una città di collina in mezzo a due popoli più avanzati, Etruschi a nord e Greci a sud: Roma crebbe imparando da entrambi, e finì per conquistarli tutti e due.",
			},
			{
				"label": "Cartaginesi",
				"dove": "sulle coste del Nord Africa, vicino alla Tunisia",
				"risposte": ["Cartaginesi", "sulle coste del Nord Africa", "coste della Tunisia"],
				"nota": "Fondata da coloni fenici su una penisola facile da difendere e vicina alle rotte del Mediterraneo occidentale. Diventò così ricca di commerci da sfidare Roma per il controllo del mare.",
			},
			{
				"label": "Greci",
				"dove": "intorno al Mar Egeo",
				"risposte": ["Greci", "intorno al Mar Egeo", "mar Egeo", "Partenone"],
				"nota": "Migliaia di isole e coste frastagliate intorno a un mare piccolo e navigabile: per questo i Greci furono sempre più marinai che contadini, e le loro città-stato restarono sempre separate.",
			},
			{
				"label": "La civiltà dell'Indo",
				"dove": "lungo il fiume Indo, in Asia meridionale",
				"risposte": ["civiltà dell'Indo", "Indo"],
				"nota": "Città costruite con un piano preciso — strade dritte, fogne coperte, mattoni tutti della stessa misura — già quattromila anni fa. Non si è ancora riusciti a leggere la loro scrittura.",
			},
			{
				"label": "Maya",
				"dove": "nella penisola dello Yucatán, America centrale",
				"risposte": ["Maya", "Yucatán"],
				"nota": "Costruirono grandi città di pietra nella foresta tropicale, senza animali da soma e senza la ruota per i trasporti. Il loro calendario era più preciso di quello europeo dello stesso periodo.",
			},
		],
	},
	{
		"id": "storia-invenzioni-antiche",
		"subject": "storia",
		"kind": KIND_SCHEDA,
		"topics": ["invenzioni"],
		"titolo": "Scheda · Un popolo, una cosa che ha reso comune",
		"come_si_legge": "Non chi ha inventato una cosa per primo, ma chi l'ha resa comune e l'ha diffusa: la ruota esisteva già prima dei Sumeri, ma è alla scrittura sumera che si lega perché con loro diventa uno strumento di uso quotidiano.",
		"voci": [
			{
				"label": "Egizi",
				"in_breve": "le piramidi",
				"risposte": ["Egizi", "le piramidi"],
				"nota": "Tombe monumentali costruite per durare in eterno, come il potere del faraone che dovevano custodire. Muovere blocchi da due tonnellate senza macchine richiese organizzare decine di migliaia di lavoratori.",
			},
			{
				"label": "Romani",
				"in_breve": "gli acquedotti",
				"risposte": ["Romani", "gli acquedotti"],
				"nota": "Portavano l'acqua da lontano sfruttando una pendenza minima e costante: gli archi servivano solo a mantenere quella pendenza mentre il terreno saliva e scendeva sotto di loro.",
			},
			{
				"label": "Greci",
				"in_breve": "la democrazia",
				"risposte": ["Greci", "la democrazia"],
				"nota": "Nata ad Atene: le decisioni si prendevano in assemblea, votando, invece che per volontà di un solo capo. Un'idea che per secoli restò un'eccezione, prima di tornare a diffondersi molto più tardi.",
			},
			{
				"label": "Fenici",
				"in_breve": "l'alfabeto",
				"risposte": ["Fenici", "l'alfabeto"],
				"nota": "Poche decine di segni, ognuno per un suono: molto più semplice dei geroglifici o del cuneiforme, che ne usavano centinaia. Un mercante lo imparava in giorni, non in anni: per questo si diffuse così in fretta.",
			},
			{
				"label": "Sumeri",
				"in_breve": "la scrittura cuneiforme",
				"risposte": ["Sumeri", "la scrittura cuneiforme"],
				"nota": "Segni a forma di cuneo incisi sull'argilla fresca con una cannuccia appuntita. Nacque per tenere i conti dei magazzini, e solo dopo cominciò a raccontare leggi, storie e preghiere.",
			},
			{
				"label": "Cinesi",
				"in_breve": "la carta",
				"risposte": ["Cinesi", "la carta"],
				"nota": "Fatta impastando fibre vegetali e stendendole in fogli sottili: molto più leggera ed economica della seta o del bambù su cui si scriveva prima, e per questo cambiò chi poteva permettersi di leggere e scrivere.",
			},
			{
				"label": "Vichinghi",
				"in_breve": "le navi drakkar",
				"risposte": ["Vichinghi", "le navi drakkar"],
				"nota": "Lunghe, strette e con pochissimo pescaggio: potevano attraversare l'oceano aperto e anche risalire un fiume fin dentro terra, cosa che nessun'altra nave d'Europa sapeva fare allo stesso modo.",
			},
			{
				"label": "Inca",
				"in_breve": "le strade sulle Ande",
				"risposte": ["Inca", "le strade sulle Ande"],
				"nota": "Migliaia di chilometri di sentieri lastricati, con ponti sospesi sui burroni e scalinate scavate nella roccia: tenevano insieme un impero lungo la catena montuosa più difficile del mondo.",
			},
			{
				"label": "Aztechi",
				"in_breve": "gli orti galleggianti",
				"risposte": ["Aztechi", "gli orti galleggianti"],
				"nota": "Zattere di canne intrecciate coperte di terra fertile, ancorate al fondo del lago con radici di salice: un modo per avere campi coltivabili dove non c'era terraferma.",
			},
			{
				"label": "Babilonesi",
				"in_breve": "le prime leggi scritte",
				"risposte": ["Babilonesi", "le prime leggi scritte"],
				"nota": "Il codice di Hammurabi, inciso su una stele perché tutti potessero vederlo: prima le leggi si tramandavano a voce e cambiavano da un giudice all'altro. Scritte, diventano uguali per chiunque le legga.",
			},
			{
				"label": "Arabi",
				"in_breve": "i numeri che usiamo oggi",
				"risposte": ["Arabi", "i numeri che usiamo oggi"],
				"nota": "Dieci cifre, compreso lo zero, che si combinano per scrivere qualunque numero: molto più pratiche dei numeri romani, con cui fare un calcolo scritto è quasi impossibile. Vennero dall'India, e gli arabi le diffusero in Europa.",
			},
			{
				"label": "Etruschi",
				"in_breve": "le tombe dipinte",
				"risposte": ["Etruschi", "le tombe dipinte"],
				"nota": "Camere sotterranee affrescate con banchetti, danze e musica: quasi tutto quello che sappiamo sulla vita quotidiana etrusca viene da lì, perché i loro testi scritti sono quasi tutti andati perduti.",
			},
			{
				"label": "Persiani",
				"in_breve": "la strada reale",
				"risposte": ["Persiani", "la strada reale"],
				"nota": "Duemilaquattrocento chilometri fra Susa e Sardi, con stazioni di posta a cavalli freschi: un messaggio che a piedi avrebbe impiegato tre mesi arrivava in una settimana.",
			},
			{
				"label": "Assiri",
				"in_breve": "i carri da guerra",
				"risposte": ["Assiri", "i carri da guerra"],
				"nota": "Carri leggeri trainati da cavalli, con arcieri a bordo: davano velocità e potenza di fuoco che la fanteria a piedi non poteva avere, ed è uno dei motivi per cui l'esercito assiro fu temuto per secoli.",
			},
			{
				"label": "Ittiti",
				"in_breve": "la lavorazione del ferro",
				"risposte": ["Ittiti", "la lavorazione del ferro"],
				"nota": "Il ferro fonde a una temperatura più alta del bronzo, ed è più difficile da lavorare bene — ma una volta padroneggiato dà armi e attrezzi più duri e più economici, perché il minerale di ferro è molto più comune di rame e stagno insieme.",
			},
			{
				"label": "Micenei",
				"in_breve": "le maschere d'oro",
				"risposte": ["Micenei", "le maschere d'oro"],
				"nota": "Maschere funerarie battute a mano su lamine d'oro sottile, per coprire il volto dei re nelle tombe. Sono uno dei pochi resti materiali di una civiltà che conosciamo soprattutto dai miti greci nati dopo di lei.",
			},
			{
				"label": "Bizantini",
				"in_breve": "i mosaici dorati",
				"risposte": ["Bizantini", "i mosaici dorati"],
				"nota": "Tessere di vetro con una sottile lamina d'oro dentro, posate con una leggera inclinazione per catturare la luce delle candele: le chiese bizantine sembravano brillare di luce propria.",
			},
			{
				"label": "Longobardi",
				"in_breve": "i ducati",
				"risposte": ["Longobardi", "i ducati"],
				"nota": "Territori governati da un duca, spesso lontani e indipendenti dal re: i Longobardi non riuscirono mai a unificare del tutto l'Italia che avevano invaso, e quella divisione durò per secoli dopo di loro.",
			},
			{
				"label": "Maya",
				"in_breve": "il calendario di pietra",
				"risposte": ["Maya", "il calendario di pietra"],
				"nota": "Più di un calendario in realtà, incrociati fra loro per contare cicli religiosi, agricoli e astronomici allo stesso tempo: era più preciso di quello europeo del medesimo periodo.",
			},
			{
				"label": "Cretesi",
				"in_breve": "il palazzo di Cnosso",
				"risposte": ["Cretesi", "il palazzo di Cnosso"],
				"nota": "Un edificio enorme con centinaia di stanze, cortili e magazzini, senza mura difensive intorno: la civiltà minoica di Creta si fidava della propria flotta per proteggersi, non di un muro.",
			},
			{
				"label": "Ebrei",
				"in_breve": "la Bibbia ebraica",
				"risposte": ["Ebrei", "la Bibbia ebraica"],
				"nota": "Una raccolta di testi religiosi, storici e di leggi messa per iscritto in un momento in cui pochissimi popoli scrivevano ancora la propria storia: è diventata il testo sacro di tre religioni diverse.",
			},
			{
				"label": "Cartaginesi",
				"in_breve": "il porto circolare",
				"risposte": ["Cartaginesi", "il porto circolare"],
				"nota": "Un bacino tondo con al centro un'isola per il comando della flotta, capace di nascondere e proteggere decine di navi da guerra: il segreto militare più custodito di tutto il Mediterraneo occidentale.",
			},
			{
				"label": "Mongoli",
				"in_breve": "l'arco da cavallo",
				"risposte": ["Mongoli", "l'arco da cavallo"],
				"nota": "Un arco corto e potentissimo, costruito con strati di legno, corno e tendini incollati: si poteva tirare al galoppo, e questo diede ai Mongoli un esercito capace di colpire e ritirarsi più veloce di chiunque altro.",
			},
			{
				"label": "Normanni",
				"in_breve": "i castelli in pietra",
				"risposte": ["Normanni", "i castelli in pietra"],
				"nota": "Prima i castelli erano perlopiù legno e terra, veloci da costruire ma facili da bruciare. I Normanni li rifecero in pietra ovunque conquistavano: più lenti da costruire, quasi impossibili da distruggere.",
			},
		],
	},
	{
		"id": "storia-personaggi",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["personaggi"],
		"titolo": "La linea del tempo · I personaggi",
		"come_si_legge": "Ventiquattro nomi lungo tremila anni di storia: da un faraone bambino all'unità d'Italia. Ognuno si ricorda per un fatto solo — è quel fatto a fissarlo nella memoria, non tutta la sua biografia.",
		"da": -1323,
		"a": 1860,
		"voci": [
			{
				"label": "Tutankhamon",
				"quando": "circa 1323 a.C. (morte)",
				"anno": -1323,
				"risposte": ["Tutankhamon", "Fu sepolto in una tomba intatta"],
				"nota": "Un faraone bambino, morto giovanissimo, che non avrebbe lasciato grande traccia nella storia se la sua tomba non fosse stata trovata intatta nel 1922 — quasi tutte le altre erano già state svaligiate nell'antichità.",
			},
			{
				"label": "Romolo",
				"quando": "753 a.C. (leggenda)",
				"anno": -753,
				"risposte": ["Romolo", "Fondò Roma secondo la leggenda"],
				"nota": "Il gemello allevato da una lupa, fondatore leggendario di Roma. Il racconto serviva ai Romani a dire che la loro città era nata per volere degli dèi, non per caso.",
			},
			{
				"label": "Solone",
				"quando": "594 a.C.",
				"anno": -594,
				"risposte": ["Solone", "Diede ad Atene le prime leggi scritte"],
				"nota": "Prima di lui le leggi ad Atene si tramandavano a voce e le decideva chi era già potente. Scriverle e renderle uguali per tutti fu uno dei primi passi verso la democrazia che sarebbe arrivata un secolo dopo.",
			},
			{
				"label": "Erodoto",
				"quando": "circa 450 a.C.",
				"anno": -450,
				"risposte": ["Erodoto", "È detto il padre della storia"],
				"nota": "Il primo a raccogliere e confrontare testimonianze sul passato invece di limitarsi a raccontare miti: per questo è chiamato il padre della storia, anche se molte delle cose che scrive non le ha verificate.",
			},
			{
				"label": "Pericle",
				"quando": "461–429 a.C.",
				"anno": -450,
				"risposte": ["Pericle", "Guidò Atene nella sua età d'oro"],
				"nota": "Sotto la sua guida Atene costruì il Partenone e la democrazia raggiunse il momento di massima forza. Fu eletto stratego per più di trent'anni di fila, un caso più unico che raro in una città che temeva i tiranni.",
			},
			{
				"label": "Alessandro Magno",
				"quando": "336–323 a.C.",
				"anno": -331,
				"risposte": ["Alessandro Magno", "Conquistò l'impero persiano"],
				"nota": "In tredici anni portò il suo esercito dalla Grecia fino all'India, conquistando l'intero impero persiano. Morì a trentadue anni, e il suo impero si spezzò subito dopo fra i suoi generali.",
			},
			{
				"label": "Archimede",
				"quando": "circa 287–212 a.C.",
				"anno": -250,
				"risposte": ["Archimede", "Scoprì la spinta idrostatica"],
				"nota": "Capì perché un oggetto immerso nell'acqua sembra pesare meno — la spinta idrostatica — mentre studiava se una corona fosse davvero d'oro puro. La leggenda vuole che l'abbia capito facendo il bagno.",
			},
			{
				"label": "Annibale",
				"quando": "218 a.C.",
				"anno": -218,
				"risposte": ["Annibale", "Attraversò le Alpi con gli elefanti"],
				"nota": "Portò il suo esercito, elefanti compresi, attraverso le Alpi per attaccare Roma da dove nessuno se lo aspettava. Vinse battaglie enormi in Italia, ma alla fine non riuscì a piegare la città.",
			},
			{
				"label": "Giulio Cesare",
				"quando": "58–52 a.C.",
				"anno": -52,
				"risposte": ["Giulio Cesare", "Conquistò la Gallia"],
				"nota": "Conquistò la Gallia in otto anni di campagna e ne scrisse lui stesso il racconto. La fama e l'esercito fedele che ne ricavò furono ciò che gli permise poi di prendere il potere a Roma.",
			},
			{
				"label": "Cleopatra",
				"quando": "51–30 a.C.",
				"anno": -30,
				"risposte": ["Cleopatra", "Fu l'ultima regina d'Egitto"],
				"nota": "L'ultima regina dell'Egitto indipendente prima che diventasse una provincia romana. Parlava molte lingue, comprese quella egizia — cosa rara per i suoi antenati greci, che spesso non se ne curavano.",
			},
			{
				"label": "Augusto",
				"quando": "27 a.C.",
				"anno": -27,
				"risposte": ["Augusto", "Fu il primo imperatore romano"],
				"nota": "Prese tutti i poteri lasciando in piedi le cariche della repubblica, e non si fece mai chiamare re. L'impero romano comincia con lui.",
			},
			{
				"label": "Traiano",
				"quando": "98–117 d.C.",
				"anno": 117,
				"risposte": ["Traiano", "Portò Roma alla massima estensione"],
				"nota": "Sotto di lui l'impero romano toccò la sua massima estensione territoriale, dalla Britannia alla Mesopotamia. Dopo di lui nessun imperatore riuscì più ad allargarlo, solo a difenderlo.",
			},
			{
				"label": "Costantino",
				"quando": "313 d.C.",
				"anno": 313,
				"risposte": ["Costantino", "Rese lecito il cristianesimo"],
				"nota": "Con l'editto di Milano rese legale professare il cristianesimo, prima perseguitato. Spostò anche la capitale dell'impero a Costantinopoli, che porta ancora il suo nome.",
			},
			{
				"label": "Ipazia",
				"quando": "circa 415 d.C.",
				"anno": 415,
				"risposte": ["Ipazia", "Insegnò matematica ad Alessandria"],
				"nota": "Insegnò matematica e astronomia ad Alessandria d'Egitto, in un'epoca in cui quasi nessuna donna aveva accesso a quel sapere. Fu uccisa da una folla durante scontri religiosi e politici della città.",
			},
			{
				"label": "Attila",
				"quando": "circa 451 d.C.",
				"anno": 451,
				"risposte": ["Attila", "Guidò gli Unni in Europa"],
				"nota": "Guidò gli Unni, un popolo di cavalieri delle steppe asiatiche, in devastanti incursioni in Europa. Fu chiamato «il flagello di Dio», e la sua fama di terrore sopravvisse per secoli dopo la sua morte.",
			},
			{
				"label": "Carlo Magno",
				"quando": "800 d.C.",
				"anno": 800,
				"risposte": ["Carlo Magno", "Fu incoronato imperatore nell'800"],
				"nota": "Re dei Franchi, incoronato imperatore a Roma la notte di Natale dell'800. Riunì mezza Europa e volle scuole accanto alle chiese: dopo di lui l'impero si sfaldò di nuovo, ma l'idea rimase.",
			},
			{
				"label": "Marco Polo",
				"quando": "1271–1295",
				"anno": 1271,
				"risposte": ["Marco Polo", "Viaggiò fino alla Cina"],
				"nota": "Un mercante veneziano che attraversò l'Asia fino alla Cina di Kublai Khan e ci restò diciassette anni. Il libro del suo viaggio fece scoprire all'Europa un mondo di cui non sapeva quasi nulla.",
			},
			{
				"label": "Gutenberg",
				"quando": "1455",
				"anno": 1455,
				"risposte": ["Gutenberg", "Inventò la stampa a caratteri mobili"],
				"nota": "Mise a punto caratteri di metallo riutilizzabili e un torchio per stamparli in serie: un libro che prima richiedeva mesi di copiatura a mano si poteva ora riprodurre in centinaia di copie identiche.",
			},
			{
				"label": "Cristoforo Colombo",
				"quando": "1492",
				"anno": 1492,
				"risposte": ["Cristoforo Colombo", "Arrivò in America nel 1492"],
				"nota": "Cercava una rotta verso l'Asia navigando verso ovest e trovò invece un continente che gli europei non sapevano esistesse. Morì convinto di essere arrivato in Asia.",
			},
			{
				"label": "Amerigo Vespucci",
				"quando": "1499–1502",
				"anno": 1502,
				"risposte": ["Amerigo Vespucci", "Diede il nome all'America"],
				"nota": "Fu tra i primi a capire che le terre scoperte da Colombo non erano l'Asia ma un continente nuovo. Un cartografo tedesco, leggendo i suoi resoconti, chiamò quel continente «America» in suo onore.",
			},
			{
				"label": "Leonardo da Vinci",
				"quando": "1503 circa",
				"anno": 1503,
				"risposte": ["Leonardo da Vinci", "Dipinse la Gioconda"],
				"nota": "Pittore, ingegnere e studioso di anatomia, disegnò macchine volanti secoli prima che potessero funzionare. La Gioconda è il suo dipinto più famoso, ma solo una piccola parte di ciò che ha lasciato.",
			},
			{
				"label": "Ferdinando Magellano",
				"quando": "1519–1522",
				"anno": 1519,
				"risposte": ["Ferdinando Magellano", "Organizzò il primo giro del mondo"],
				"nota": "Organizzò la spedizione che per prima circumnavigò il globo, dimostrando concretamente che la Terra è rotonda. Morì durante il viaggio, nelle Filippine: fu la sua nave, non lui, a completare il giro.",
			},
			{
				"label": "Galileo Galilei",
				"quando": "1609–1610",
				"anno": 1609,
				"risposte": ["Galileo Galilei", "Puntò il telescopio sui pianeti"],
				"nota": "Puntò per primo un telescopio verso il cielo e vide i crateri della Luna e le lune di Giove: prove concrete che non tutto ruota intorno alla Terra, come si credeva da secoli.",
			},
			{
				"label": "Giuseppe Garibaldi",
				"quando": "1860",
				"anno": 1860,
				"risposte": ["Giuseppe Garibaldi", "Guidò la spedizione dei Mille"],
				"nota": "Guidò circa mille volontari nella conquista del Regno delle Due Sicilie, un passo decisivo verso l'Unità d'Italia. Le camicie rosse dei suoi uomini sono diventate il simbolo di quella impresa.",
			},
		],
	},
	{
		"id": "storia-le-cinque-eta",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["ere"],
		"titolo": "La linea del tempo · Le cinque grandi età",
		"come_si_legge": "Cinque tratti che coprono tutta la storia, di lunghezza molto diversa fra loro: la preistoria dura milioni di anni, l'età contemporanea poco più di due secoli. Ogni età comincia con un evento preciso che gli storici hanno scelto come confine.",
		"da": -2500000,
		"a": 1789,
		"voci": [
			{
				"label": "Preistoria",
				"quando": "fino al 3300 a.C. circa",
				"anno": -2500000,
				"risposte": ["Preistoria"],
				"nota": "Il tratto più lungo di tutti, perché finisce solo quando comincia la scrittura. Di questo periodo sappiamo soltanto quello che raccontano gli oggetti: nessuno ha lasciato scritto perché lo faceva.",
			},
			{
				"label": "Età antica",
				"quando": "dal 3300 a.C. al 476 d.C.",
				"anno": -3300,
				"risposte": ["Età antica"],
				"nota": "Comincia con la scrittura e finisce con la caduta dell'Impero Romano d'Occidente. Dentro ci stanno Egizi, Sumeri, Greci e Romani: quasi quattromila anni di storia scritta.",
			},
			{
				"label": "Medioevo",
				"quando": "dal 476 al 1492",
				"anno": 476,
				"risposte": ["Medioevo"],
				"nota": "Mille anni fra la caduta di Roma e la scoperta dell'America. Il filo che li tiene insieme: senza uno Stato che protegge, ognuno cerca protezione da qualcuno più forte, e in cambio gli deve qualcosa.",
			},
			{
				"label": "Età moderna",
				"quando": "dal 1492 al 1789",
				"anno": 1492,
				"risposte": ["Età moderna"],
				"nota": "Comincia con la scoperta dell'America e finisce con la Rivoluzione francese: tre secoli in cui l'Europa esplora il mondo, stampa libri in serie e comincia a mettere in dubbio il potere dei re.",
			},
			{
				"label": "Età contemporanea",
				"quando": "dal 1789 a oggi",
				"anno": 1789,
				"risposte": ["Età contemporanea"],
				"nota": "Comincia con la Rivoluzione francese, che per la prima volta rovescia un re in nome del popolo. Il tratto più corto delle cinque età, ed è quello in cui succede la maggior parte delle cose che studi come «storia recente».",
			},
		],
	},
	{
		"id": "storia-eta-moderna-e-contemporanea",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["cronologia"],
		"titolo": "La linea del tempo · Dalla Rivoluzione francese a oggi",
		"come_si_legge": "Due secoli fittissimi, il tratto più corto della linea e quello con più eventi vicini fra loro. È anche il tratto in cui la velocità dei cambiamenti accelera di continuo: fra un evento e il successivo passa sempre meno tempo.",
		"da": 1789,
		"a": 1993,
		"voci": [
			{
				"label": "La Rivoluzione francese",
				"quando": "1789",
				"anno": 1789,
				"risposte": ["Rivoluzione francese", "1789"],
				"nota": "Il popolo di Parigi rovescia la monarchia in nome della libertà e dell'uguaglianza. È la data con cui si apre convenzionalmente l'età contemporanea: per la prima volta un re cade per volontà popolare.",
			},
			{
				"label": "L'Unità d'Italia",
				"quando": "1861",
				"anno": 1861,
				"risposte": ["Unità d'Italia", "Nasce il Regno d'Italia", "1861"],
				"nota": "Gli stati in cui era divisa la penisola da secoli si uniscono in un solo regno. L'Italia esiste come Paese unico solo da questa data: prima erano tanti piccoli Stati con lingue e monete diverse.",
			},
			{
				"label": "Le prime automobili",
				"quando": "1890 circa",
				"anno": 1890,
				"risposte": ["Si costruiscono le prime automobili"],
				"nota": "Le prime auto a motore, costruite pochi anni dopo il brevetto di Benz del 1886: rumorose, lentissime rispetto a oggi e riservate a pochissimi, ma l'inizio di un cambiamento che avrebbe rifatto le città.",
			},
			{
				"label": "La prima guerra mondiale",
				"quando": "1914–1918",
				"anno": 1914,
				"risposte": ["Prima guerra mondiale", "Inizia la prima guerra mondiale", "Scoppia la Prima guerra mondiale", "1914"],
				"nota": "La prima guerra a coinvolgere quasi tutto il mondo insieme, combattuta per anni da eserciti bloccati in trincee. Le nuove armi — mitragliatrici, gas, carri armati — la resero molto più letale di ogni guerra precedente.",
			},
			{
				"label": "La rivoluzione russa",
				"quando": "1917",
				"anno": 1917,
				"risposte": ["Rivoluzione russa"],
				"nota": "Rovescia lo zar e porta al potere i comunisti guidati da Lenin: nasce il primo Stato al mondo governato senza un re, un imperatore o un parlamento eletto nel senso tradizionale.",
			},
			{
				"label": "La marcia su Roma",
				"quando": "1922",
				"anno": 1922,
				"risposte": ["Marcia su Roma"],
				"nota": "Migliaia di fascisti guidati da Mussolini marciano verso Roma, e il re gli affida il governo per evitare uno scontro. È l'inizio del regime fascista in Italia, durato più di vent'anni.",
			},
			{
				"label": "Il crollo di Wall Street",
				"quando": "1929",
				"anno": 1929,
				"risposte": ["Crollo della borsa di Wall Street"],
				"nota": "Il crollo della borsa di New York fa perdere valore a migliaia di aziende in pochi giorni: la crisi si diffonde in tutto il mondo, lascia milioni senza lavoro e prepara il terreno per la guerra successiva.",
			},
			{
				"label": "La seconda guerra mondiale",
				"quando": "1939–1945",
				"anno": 1939,
				"risposte": ["Inizia la seconda guerra mondiale"],
				"nota": "La guerra più distruttiva della storia, che coinvolge quasi ogni Paese del mondo e uccide decine di milioni di persone, in gran parte civili. Comincia con l'invasione della Polonia da parte della Germania nazista.",
			},
			{
				"label": "L'attacco a Pearl Harbor",
				"quando": "1941",
				"anno": 1941,
				"risposte": ["Attacco a Pearl Harbor"],
				"nota": "Il Giappone attacca a sorpresa la base navale statunitense delle Hawaii, distruggendo gran parte della flotta americana in poche ore. Il giorno dopo gli Stati Uniti entrano nella Seconda guerra mondiale.",
			},
			{
				"label": "Lo sbarco in Normandia",
				"quando": "1944",
				"anno": 1944,
				"risposte": ["Sbarco in Normandia"],
				"nota": "Le truppe alleate sbarcano sulle spiagge della Francia occupata, la più grande operazione militare via mare mai realizzata: apre il fronte occidentale che porterà alla sconfitta della Germania nazista un anno dopo.",
			},
			{
				"label": "La bomba atomica su Hiroshima",
				"quando": "1945",
				"anno": 1945,
				"risposte": ["Bomba atomica su Hiroshima"],
				"nota": "Gli Stati Uniti sganciano la prima bomba atomica mai usata in guerra su una città giapponese: distrugge Hiroshima in un istante. Pochi giorni dopo il Giappone si arrende, e la Seconda guerra mondiale finisce.",
			},
			{
				"label": "L'Italia diventa una repubblica",
				"quando": "1946",
				"anno": 1946,
				"risposte": ["L'Italia diventa una repubblica"],
				"nota": "Un referendum popolare, il primo a cui votano anche le donne italiane, sceglie la repubblica al posto della monarchia: la famiglia reale lascia il Paese.",
			},
			{
				"label": "La Costituzione italiana",
				"quando": "1948",
				"anno": 1948,
				"risposte": ["Entra in vigore la Costituzione italiana"],
				"nota": "Entra in vigore la legge fondamentale della Repubblica, scritta subito dopo la guerra e il fascismo: stabilisce i diritti dei cittadini e i limiti del potere dello Stato, e nessuna legge ordinaria può contraddirla.",
			},
			{
				"label": "I trattati di Roma",
				"quando": "1957",
				"anno": 1957,
				"risposte": ["Trattati di Roma"],
				"nota": "Sei Paesi europei, fra cui l'Italia, firmano l'atto che fonda la Comunità Economica Europea: il primo passo, dopo due guerre mondiali fra loro, verso l'Unione Europea di oggi.",
			},
			{
				"label": "Il muro di Berlino",
				"quando": "costruito nel 1961",
				"anno": 1961,
				"risposte": ["Viene costruito il muro di Berlino"],
				"nota": "La Germania comunista dell'est costruisce un muro che taglia Berlino in due, per fermare la fuga dei suoi cittadini verso l'ovest. Diventa il simbolo della divisione dell'Europa durante la Guerra fredda.",
			},
			{
				"label": "Il primo uomo sulla Luna",
				"quando": "1969",
				"anno": 1969,
				"risposte": ["Sbarco sulla Luna", "Primo uomo sulla Luna", "L'uomo cammina sulla Luna", "1969"],
				"nota": "L'astronauta americano Neil Armstrong è il primo essere umano a mettere piede su un altro corpo celeste. Fu il traguardo di una gara tecnologica fra Stati Uniti e Unione Sovietica durata più di un decennio.",
			},
			{
				"label": "Cade il muro di Berlino",
				"quando": "1989",
				"anno": 1989,
				"risposte": ["Cade il muro di Berlino"],
				"nota": "I cittadini di Berlino Est ed Ovest abbattono insieme il muro che li divideva da ventotto anni. È il simbolo della fine della Guerra fredda e dell'inizio della riunificazione della Germania.",
			},
			{
				"label": "Si scioglie l'Unione Sovietica",
				"quando": "1991",
				"anno": 1991,
				"risposte": ["Si scioglie l'Unione Sovietica"],
				"nota": "Il grande Stato comunista nato dalla rivoluzione del 1917 si divide in quindici Paesi indipendenti, fra cui la Russia. Chiude un'epoca durata più di settant'anni.",
			},
			{
				"label": "Nasce l'Unione Europea",
				"quando": "1993",
				"anno": 1993,
				"risposte": ["Nasce l'Unione Europea"],
				"nota": "Il trattato di Maastricht trasforma la vecchia comunità economica in un'unione politica vera e propria, con una cittadinanza europea in più rispetto a quella nazionale di ciascuno Stato.",
			},
		],
	},
	{
		"id": "storia-invenzioni-tecnologiche",
		"subject": "storia",
		"kind": KIND_LINEA,
		"topics": ["cronologia"],
		"titolo": "La linea del tempo · Le invenzioni, dalla stampa a Internet",
		"come_si_legge": "Ogni invenzione poggia su quelle venute prima: il telescopio ha bisogno delle lenti, la macchina a vapore della metallurgia, Internet dell'elettronica. Guardando le distanze sulla linea si vede anche un'altra cosa: il ritmo accelera sempre di più.",
		"da": 1455,
		"a": 1989,
		"voci": [
			{
				"label": "La stampa a caratteri mobili",
				"quando": "1455",
				"anno": 1455,
				"risposte": ["Stampa a caratteri mobili", "Stampa a caratteri mobili di Gutenberg", "Stampa di Gutenberg", "1455"],
				"nota": "Caratteri di metallo riutilizzabili, montati su un torchio: un libro che prima richiedeva mesi di copiatura a mano si poteva ora riprodurre in centinaia di copie identiche.",
			},
			{
				"label": "Il telescopio",
				"quando": "1608",
				"anno": 1608,
				"risposte": ["Telescopio"],
				"nota": "Due lenti allineate in un tubo, inventate in Olanda e perfezionate subito dopo da Galileo, che lo puntò per primo verso il cielo. Mostrò crateri sulla Luna e lune intorno a Giove: prove che non tutto gira intorno alla Terra.",
			},
			{
				"label": "La macchina a vapore",
				"quando": "1712",
				"anno": 1712,
				"risposte": ["Macchina a vapore"],
				"nota": "Trasforma il calore del vapore in movimento meccanico: prima serviva a pompare acqua fuori dalle miniere, poi mosse fabbriche, treni e navi. È la macchina che dà il via alla rivoluzione industriale.",
			},
			{
				"label": "Il vaccino",
				"quando": "1796",
				"anno": 1796,
				"risposte": ["Vaccino"],
				"nota": "Jenner scoprì che chi era stato contagiato dal vaiolo delle mucche, malattia lieve, diventava immune al vaiolo umano, mortale: fu la prima vaccinazione della storia, e da lì viene il nome «vaccino».",
			},
			{
				"label": "Il treno a vapore",
				"quando": "1825",
				"anno": 1825,
				"risposte": ["Treno a vapore"],
				"nota": "La prima linea ferroviaria pubblica al mondo, trainata da una locomotiva a vapore: per la prima volta merci e persone potevano spostarsi via terra più veloci di un cavallo al galoppo, e per ore di fila.",
			},
			{
				"label": "La fotografia",
				"quando": "1826",
				"anno": 1826,
				"risposte": ["Fotografia"],
				"nota": "La prima immagine fissata in modo permanente su una lastra, dopo ore di esposizione alla luce. Prima di allora l'unico modo di conservare un volto o un paesaggio era disegnarlo o dipingerlo a mano.",
			},
			{
				"label": "Il telefono",
				"quando": "1876",
				"anno": 1876,
				"risposte": ["Telefono"],
				"nota": "Trasforma la voce in un segnale elettrico che viaggia lungo un filo e torna voce dall'altra parte: per la prima volta si poteva parlare con qualcuno lontano senza scrivere né aspettare.",
			},
			{
				"label": "La lampadina",
				"quando": "1879",
				"anno": 1879,
				"risposte": ["Lampadina"],
				"nota": "Un filamento che si scalda al passaggio della corrente fino a diventare incandescente, chiuso in un vetro senza aria perché non bruci subito. Cambiò gli orari delle città, che per la prima volta potevano restare illuminate a lungo dopo il tramonto.",
			},
			{
				"label": "L'automobile",
				"quando": "1886",
				"anno": 1886,
				"risposte": ["Automobile"],
				"nota": "Il primo veicolo mosso da un motore a scoppio invece che da un cavallo: rumoroso, costosissimo e riservato a pochi, ma l'inizio di un cambiamento che avrebbe rifatto le città e le strade di tutto il mondo.",
			},
			{
				"label": "La radio",
				"quando": "1895",
				"anno": 1895,
				"risposte": ["Radio"],
				"nota": "Manda un segnale attraverso l'aria, senza fili, usando onde elettromagnetiche: per la prima volta un messaggio poteva arrivare a chiunque avesse un ricevitore, senza bisogno di un cavo che li collegasse.",
			},
			{
				"label": "L'aeroplano",
				"quando": "1903",
				"anno": 1903,
				"risposte": ["Aeroplano"],
				"nota": "Il primo volo a motore controllato della storia durò dodici secondi e coprì trentasei metri. Sembra poco, ma fu la prova che un oggetto più pesante dell'aria poteva sollevarsi e restare in volo governato da chi lo pilotava.",
			},
			{
				"label": "La televisione",
				"quando": "1926",
				"anno": 1926,
				"risposte": ["Televisione"],
				"nota": "Trasmette immagini in movimento a distanza, scomponendole in righe e ricomponendole sullo schermo molte volte al secondo. Per decenni fu il modo in cui intere famiglie guardavano insieme lo stesso evento nello stesso momento.",
			},
			{
				"label": "La penicillina",
				"quando": "1928",
				"anno": 1928,
				"risposte": ["Penicillina"],
				"nota": "Fleming notò per caso che una muffa cresciuta su una delle sue colture uccideva i batteri intorno a sé: fu il primo antibiotico, e rese curabili infezioni che prima erano quasi sempre mortali.",
			},
			{
				"label": "Il computer elettronico",
				"quando": "1946",
				"anno": 1946,
				"risposte": ["Computer elettronico"],
				"nota": "I primi calcolatori elettronici riempivano intere stanze e usavano valvole che si scaldavano e si bruciavano di continuo. Facevano in secondi calcoli che a mano avrebbero richiesto settimane.",
			},
			{
				"label": "Il satellite artificiale",
				"quando": "1957",
				"anno": 1957,
				"risposte": ["Satellite artificiale"],
				"nota": "Lo Sputnik sovietico fu il primo oggetto costruito dall'uomo a orbitare intorno alla Terra: pesava meno di novanta chili ma diede il via alla corsa allo spazio fra Stati Uniti e Unione Sovietica.",
			},
			{
				"label": "Internet",
				"quando": "1969",
				"anno": 1969,
				"risposte": ["Internet"],
				"nota": "Nasce come rete militare e universitaria per collegare pochi computer fra loro anche se una parte della rete fosse stata distrutta: quella robustezza contro i guasti è ancora oggi il principio su cui si basa.",
			},
			{
				"label": "Il telefono cellulare",
				"quando": "1973",
				"anno": 1973,
				"risposte": ["Telefono cellulare"],
				"nota": "La prima telefonata da un telefono portatile, pesante quasi un chilo e con un'autonomia di appena mezz'ora. Per la prima volta il telefono si staccava da un filo e da una stanza precisa.",
			},
			{
				"label": "Il World Wide Web",
				"quando": "1989",
				"anno": 1989,
				"risposte": ["World Wide Web"],
				"nota": "Berners-Lee inventò un modo di collegare documenti fra loro con dei link, consultabili da chiunque avesse un browser: è il sistema di pagine collegate che oggi chiamiamo semplicemente «il web».",
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
				"risposte": ["Le Alpi", "Alpi", "Catena montuosa"],
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
				"risposte": ["Po", "Fiume"],
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
				"risposte": ["Etna", "Vulcano"],
				"nota": "Il vulcano attivo più alto d'Europa, oltre 3300 metri, in eruzione quasi ogni anno. La terra vulcanica intorno è fertilissima: per questo ai suoi piedi si coltiva e si vive da sempre.",
			},
			{
				"label": "Il lago di Garda",
				"dove": "nord, fra Lombardia, Veneto e Trentino",
				"risposte": ["Lago di Garda", "Garda", "Lago"],
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
		"topics": ["capitali", "geografia-umana"],
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
		"topics": ["capitali", "geografia-umana"],
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
				"label": "Algeria · Algeri",
				"dove": "costa mediterranea dell'Africa nord-occidentale",
				"risposte": ["Algeri", "Algeria"],
				"nota": "L'Algeria è il Paese più esteso dell'Africa, ma quasi disabitato nell'interno: il Sahara ne copre più dei quattro quinti, e per questo quasi tutti vivono in una stretta fascia costiera dove sta anche la capitale.",
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
				"risposte": ["Asia", "Giappone"],
				"nota": "Il continente più esteso e il più popoloso: qui stanno Cina, India, Giappone e la maggior parte degli esseri umani. Confina con l'Europa lungo gli Urali.",
			},
			{
				"label": "Africa",
				"dove": "a sud dell'Europa, oltre il Mediterraneo",
				"risposte": ["Africa", "Egitto"],
				"nota": "Attraversata dall'Equatore nel mezzo, e proprio per questo ha deserti caldissimi a nord e a sud e foresta pluviale al centro. Qui stanno il Sahara e l'Egitto.",
			},
			{
				"label": "Europa",
				"dove": "a nord-ovest, la penisola dell'Asia",
				"risposte": ["Europa", "Italia"],
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
				"risposte": ["America del Sud", "Brasile"],
				"nota": "Brasile, Argentina, Perù, Cile. Qui scorre il Rio delle Amazzoni, il fiume che porta più acqua al mondo, e corre la catena delle Ande lungo tutta la costa occidentale.",
			},
			{
				"label": "Oceania",
				"dove": "a sud-est, fra l'oceano Pacifico e l'Indiano",
				"risposte": ["Oceania", "Australia"],
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
		"topics": ["geografia-fisica", "geografia-umana", "geografia-italia"],
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
			{
				"label": "Torrente",
				"in_breve": "un fiume giovane, in montagna",
				"risposte": ["Torrente", "Fiume"],
				"nota": "Il tratto in cui l'acqua scende veloce e a scosse, subito dopo la sorgente: il letto è pieno di sassi che il torrente stesso ha smosso. Scendendo di quota rallenta e diventa un fiume vero e proprio.",
			},
			{
				"label": "Le divisioni amministrative",
				"in_breve": "comune, provincia, regione, stato",
				"risposte": ["Comune", "Provincia", "Regione", "Stato"],
				"nota": "Stanno una dentro l'altra come scatole cinesi: più comuni fanno una provincia, più province una regione, più regioni uno Stato. Ogni livello contiene per intero tutti quelli più piccoli.",
			},
			{
				"label": "Via, quartiere, città",
				"in_breve": "dal più piccolo al più grande",
				"risposte": ["Via", "Quartiere", "Città", "Continente", "Paese", "Nazione"],
				"nota": "Anche gli spazi in cui viviamo stanno uno dentro l'altro: una via sta in un quartiere, un quartiere in una città, e allargando ancora Paese, Nazione e Continente sono la stessa scala applicata a territori sempre più grandi.",
			},
		],
	},
	{
		"id": "geografia-regioni-italia",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"mapId": "italy",
		"topics": ["geografia-italia", "italia-fisica"],
		"titolo": "Atlante · Le venti regioni e i loro capoluoghi",
		"come_si_legge": "Il capoluogo è la città dove sta l'amministrazione della regione: non sempre è la più famosa, e in Italia quasi mai la più centrale. Lega ogni regione al mare che la bagna, o alla sua assenza, e la ricorderai meglio.",
		"voci": [
			{
				"label": "Lombardia · Milano",
				"dove": "nord, senza sbocco sul mare",
				"risposte": ["Lombardia", "Milano"],
				"nota": "La regione più popolosa d'Italia e la sua capitale economica, anche se non è mai stata capitale del Paese. Non tocca il mare: confina però con i grandi laghi prealpini, Como e Garda.",
			},
			{
				"label": "Veneto · Venezia",
				"dove": "nord-est, sul mar Adriatico",
				"risposte": ["Veneto", "Venezia"],
				"nota": "Venezia è costruita su oltre cento isolette in mezzo a una laguna: le sue «strade» sono canali perché quando fu fondata, in fuga dalle invasioni, l'acqua era la difesa migliore.",
			},
			{
				"label": "Piemonte · Torino",
				"dove": "nord-ovest, ai piedi delle Alpi",
				"risposte": ["Piemonte", "Torino"],
				"nota": "Il nome vuol dire proprio «ai piedi dei monti»: la regione sta incassata contro l'arco alpino occidentale. Torino fu la prima capitale dell'Italia unita, nel 1861.",
			},
			{
				"label": "Liguria · Genova",
				"dove": "nord-ovest, una striscia di costa sul Mar Ligure",
				"risposte": ["Liguria", "Genova"],
				"nota": "Una striscia di terra strettissima fra il mare e le montagne, con poca pianura: per questo i liguri guardarono sempre al mare, e Genova fu per secoli una potenza marinara.",
			},
			{
				"label": "Toscana · Firenze",
				"dove": "centro-nord, sul Mar Tirreno",
				"risposte": ["Toscana", "Firenze"],
				"nota": "Firenze sorge sull'Arno, nel punto più stretto in cui il fiume si poteva attraversare. Fu qui che nacque il Rinascimento, l'arte e la cultura che cambiarono il modo di vedere l'Europa intera.",
			},
			{
				"label": "Lazio · Roma",
				"dove": "centro, sul Mar Tirreno",
				"risposte": ["Lazio", "Roma"],
				"nota": "Roma è anche la capitale d'Italia, ma lo è diventata solo nel 1871: prima furono capitali Torino e Firenze. È l'unica capitale al mondo che ne contiene un'altra, lo Stato del Vaticano.",
			},
			{
				"label": "Campania · Napoli",
				"dove": "sud, sul Mar Tirreno",
				"risposte": ["Campania", "Napoli"],
				"nota": "Napoli si affaccia su un golfo dominato dal Vesuvio, il vulcano che nel 79 d.C. seppellì Pompei ed Ercolano. È ancora attivo, ed è il vulcano più sorvegliato d'Europa.",
			},
			{
				"label": "Sicilia · Palermo",
				"dove": "sud, la grande isola",
				"risposte": ["Sicilia", "Palermo"],
				"nota": "La regione con la maggiore superficie d'Italia, separata dalla Calabria da uno stretto di poco più di tre chilometri. Palermo fu per secoli capitale di un regno proprio, prima di entrare a far parte dell'Italia unita.",
			},
			{
				"label": "Sardegna · Cagliari",
				"dove": "ovest, in mezzo al Mar Tirreno",
				"risposte": ["Sardegna", "Cagliari"],
				"nota": "La seconda isola d'Italia, molto più lontana dalla penisola della Sicilia: per questo ha conservato una lingua propria, il sardo, diversa dall'italiano quanto lo spagnolo.",
			},
			{
				"label": "Puglia · Bari",
				"dove": "sud-est, il «tacco» dello stivale",
				"risposte": ["Puglia", "Bari"],
				"nota": "La regione più pianeggiante del sud, con coste bagnate sia dall'Adriatico che dallo Ionio. È il principale produttore di olio d'oliva d'Italia.",
			},
			{
				"label": "Calabria · Catanzaro",
				"dove": "sud, la «punta» dello stivale",
				"risposte": ["Calabria", "Catanzaro", "Cosenza"],
				"nota": "La regione più stretta d'Italia: in alcuni punti si vedono insieme il mar Tirreno e il mar Ionio dalla stessa montagna. Catanzaro è capoluogo pur non essendo la città calabrese più grande.",
			},
			{
				"label": "Emilia-Romagna · Bologna",
				"dove": "nord-est, sulla pianura padana",
				"risposte": ["Emilia-Romagna", "Bologna"],
				"nota": "Prende il nome dalla via Emilia, la strada romana dritta che ancora oggi attraversa la regione collegando le sue città principali. Bologna ospita l'università più antica del mondo occidentale ancora attiva.",
			},
			{
				"label": "Marche · Ancona",
				"dove": "centro-est, sul mar Adriatico",
				"risposte": ["Marche", "Ancona"],
				"nota": "È l'unica regione italiana il cui nome è al plurale: nasceva da più «marche», territori di confine governati da un marchese. Ancona sorge su un promontorio a gomito sul mare.",
			},
			{
				"label": "Umbria · Perugia",
				"dove": "centro, senza sbocco sul mare",
				"risposte": ["Umbria", "Perugia"],
				"nota": "L'unica regione dell'Italia peninsulare senza nessuna costa: è chiamata il «cuore verde d'Italia» per le sue colline. Perugia sta su un colle che domina la valle del Tevere.",
			},
			{
				"label": "Abruzzo · L'Aquila",
				"dove": "centro-est, fra Appennini e mar Adriatico",
				"risposte": ["Abruzzo", "L'Aquila"],
				"nota": "La regione più montuosa dell'Italia peninsulare: qui sta il Gran Sasso, il punto più alto degli Appennini. L'Aquila fu ricostruita più volte dopo terremoti, l'ultimo nel 2009.",
			},
			{
				"label": "Molise · Campobasso",
				"dove": "centro-sud, fra Abruzzo e Puglia",
				"risposte": ["Molise", "Campobasso"],
				"nota": "La seconda regione più piccola d'Italia, nata nel 1963 staccandosi dall'Abruzzo: prima le due formavano una sola regione, «Abruzzi e Molise».",
			},
			{
				"label": "Basilicata · Potenza",
				"dove": "sud, fra due mari, Tirreno e Ionio",
				"risposte": ["Basilicata", "Potenza"],
				"nota": "Una delle regioni meno popolate d'Italia, con solo due piccoli tratti di costa. Potenza è il capoluogo di regione più alto d'Italia, a oltre 800 metri.",
			},
			{
				"label": "Friuli-Venezia Giulia · Trieste",
				"dove": "nord-est, al confine con Slovenia e Austria",
				"risposte": ["Friuli-Venezia Giulia", "Trieste"],
				"nota": "Trieste è rimasta a lungo una città di confine conteso, appartenuta all'Impero austro-ungarico fino al 1918. Il suo porto naturale, profondo e riparato, la rese per secoli lo sbocco al mare di Vienna.",
			},
			{
				"label": "Trentino-Alto Adige · Trento",
				"dove": "nord, fra le Alpi, senza sbocco sul mare",
				"risposte": ["Trentino-Alto Adige", "Trento", "Bolzano"],
				"nota": "L'Alto Adige, la parte a nord, appartenne all'Austria fino al 1918: ancora oggi lì si parla soprattutto tedesco. È una regione a statuto speciale proprio per tutelare questa doppia identità linguistica.",
			},
			{
				"label": "Valle d'Aosta · Aosta",
				"dove": "nord-ovest, fra Monte Bianco e Monte Rosa",
				"risposte": ["Valle d'Aosta", "Aosta"],
				"nota": "La regione più piccola e meno popolata d'Italia, chiusa fra le montagne più alte delle Alpi. Qui si parla anche francese: è bilingue per legge, ed è a statuto speciale.",
			},
		],
	},
	{
		"id": "geografia-montagne-e-fiumi-ditalia",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"topics": ["italia-fisica", "geografia-fisica"],
		"titolo": "Atlante · Le vette e i fiumi d'Italia, in ordine di altezza e lunghezza",
		"come_si_legge": "Ogni cima e ogni fiume porta un numero — i metri della vetta, i chilometri del corso — ed è quel numero a stabilire l'ordine, non la fama. Una montagna nota può essere più bassa di una che nessuno conosce.",
		"voci": [
			{
				"label": "Monte Bianco",
				"dove": "Alpi, confine con Francia — 4808 m, la vetta più alta d'Italia e d'Europa occidentale",
				"risposte": ["Monte Bianco"],
				"nota": "La cima più alta delle Alpi e dell'Europa occidentale. Il confine esatto sulla vetta fra Italia e Francia è ancora oggetto di discussione fra i due Paesi, perché i ghiacciai si spostano.",
			},
			{
				"label": "Monte Rosa",
				"dove": "Alpi Pennine, confine con Svizzera — 4634 m",
				"risposte": ["Monte Rosa", "Alpi Pennine"],
				"nota": "Non è un'unica cima ma un massiccio con più punte oltre i 4000 metri. Il nome non ha nulla a che fare con il colore: viene da un termine locale che significa «ghiacciaio».",
			},
			{
				"label": "Cervino",
				"dove": "Alpi Pennine, confine con Svizzera — 4478 m",
				"risposte": ["Cervino"],
				"nota": "Una piramide di roccia quasi perfetta, riconoscibile da ogni lato: fu una delle ultime grandi cime alpine a essere scalata, nel 1865, perché le sue pareti sono ripidissime su tutti i versanti.",
			},
			{
				"label": "Gran Paradiso",
				"dove": "Alpi Graie, Valle d'Aosta e Piemonte — 4061 m",
				"risposte": ["Gran Paradiso"],
				"nota": "La montagna più alta interamente italiana, senza confine con nessun altro Paese sulla vetta. Attorno sorge il primo parco nazionale d'Italia, istituito nel 1922 per proteggere lo stambecco.",
			},
			{
				"label": "Ortles",
				"dove": "Alpi Retiche, Trentino-Alto Adige — 3905 m",
				"risposte": ["Ortles"],
				"nota": "La vetta più alta del Trentino-Alto Adige, coperta da uno dei ghiacciai più estesi delle Alpi orientali. Fu teatro di combattimenti in alta quota durante la Prima guerra mondiale.",
			},
			{
				"label": "Etna",
				"dove": "Sicilia orientale — 3357 m, vulcano attivo",
				"risposte": ["Etna", "Sicilia"],
				"nota": "Il vulcano attivo più alto d'Europa, in eruzione quasi ogni anno. La terra intorno è fertilissima proprio grazie alla lava e alla cenere accumulate nei millenni.",
			},
			{
				"label": "Marmolada",
				"dove": "Dolomiti, Veneto e Trentino — 3343 m",
				"risposte": ["Marmolada"],
				"nota": "La cima più alta delle Dolomiti, chiamata la «regina» di quelle montagne. Il suo ghiacciaio, uno dei più grandi delle Dolomiti, si sta ritirando rapidamente.",
			},
			{
				"label": "Gran Sasso",
				"dove": "Appennino abruzzese — 2912 m, il tetto degli Appennini",
				"risposte": ["Gran Sasso", "Appennini"],
				"nota": "Il punto più alto di tutta la catena appenninica, con il ghiacciaio più a sud d'Europa proprio sotto la sua vetta. Domina la città dell'Aquila, che sta ai suoi piedi.",
			},
			{
				"label": "Monte Velino",
				"dove": "Appennino abruzzese, Lazio-Abruzzo — 2487 m",
				"risposte": ["Monte Velino"],
				"nota": "Una delle cime più isolate e selvagge dell'Appennino centrale, al centro di una riserva naturale che protegge il camoscio appenninico, tornato dopo essere quasi scomparso.",
			},
			{
				"label": "Monte Pollino",
				"dove": "Appennino calabro-lucano — 2248 m",
				"risposte": ["Monte Pollino"],
				"nota": "La vetta più alta del più grande parco nazionale d'Italia, il Pollino, al confine fra Basilicata e Calabria. Ospita i pini loricati, alberi che possono vivere più di mille anni.",
			},
			{
				"label": "Monte Baldo",
				"dove": "Prealpi venete, sopra il lago di Garda — 2218 m",
				"risposte": ["Monte Baldo"],
				"nota": "Chiamato il «giardino d'Europa» perché la sua posizione, fra le Alpi e il clima mite del lago di Garda, ospita insieme piante alpine e mediterranee che altrove non crescerebbero mai vicine.",
			},
			{
				"label": "Monte Terminillo",
				"dove": "Appennino laziale, vicino a Rieti — 2217 m",
				"risposte": ["Monte Terminillo"],
				"nota": "Chiamato «la montagna di Roma»: è la meta sciistica più vicina alla capitale, raggiungibile in circa un'ora e mezza di strada.",
			},
			{
				"label": "Monte Cimone",
				"dove": "Appennino tosco-emiliano — 2165 m",
				"risposte": ["Monte Cimone"],
				"nota": "La cima più alta dell'Appennino settentrionale. Sulla vetta si trova un osservatorio meteorologico e ambientale attivo da decenni, uno dei punti di misura più importanti d'Europa per l'aria pulita.",
			},
			{
				"label": "Punta La Marmora",
				"dove": "Gennargentu, Sardegna — 1834 m",
				"risposte": ["Punta La Marmora"],
				"nota": "La vetta più alta della Sardegna, nel massiccio del Gennargentu. Essendo un'isola, la Sardegna non ha montagne che si avvicinano lontanamente alle Alpi o agli Appennini più alti.",
			},
			{
				"label": "Monte Grappa",
				"dove": "Prealpi venete, fra Veneto e Trentino — 1775 m",
				"risposte": ["Monte Grappa"],
				"nota": "Fu uno dei fronti più duri della Prima guerra mondiale: sulla sua cima e sui suoi fianchi si combatté per anni, e oggi un grande sacrario militare ne ricorda le vittime.",
			},
			{
				"label": "Monte Amiata",
				"dove": "Toscana meridionale — 1738 m, antico vulcano spento",
				"risposte": ["Monte Amiata"],
				"nota": "Un vulcano spento da centinaia di migliaia di anni, isolato in mezzo alle colline toscane: da lontano si riconosce subito perché è l'unica vera montagna in un paesaggio di dolci ondulazioni.",
			},
			{
				"label": "Vesuvio",
				"dove": "Campania, sul golfo di Napoli — 1281 m, vulcano attivo",
				"risposte": ["Vesuvio", "Campania"],
				"nota": "Il vulcano che nel 79 d.C. seppellì Pompei ed Ercolano sotto metri di cenere in poche ore: una disgrazia che ha conservato tutto, dalle case al pane nei forni.",
			},
			{
				"label": "Vulture",
				"dove": "Basilicata settentrionale — 1326 m, antico vulcano spento",
				"risposte": ["Vulture"],
				"nota": "Un vulcano spento da centinaia di migliaia di anni: il suo cratere ospita oggi due piccoli laghi, i laghi di Monticchio, formatisi dopo che l'attività vulcanica è cessata.",
			},
			{
				"label": "Monte Titano",
				"dove": "San Marino — 749 m",
				"risposte": ["Monte Titano"],
				"nota": "Non è nemmeno in Italia: sta interamente nella Repubblica di San Marino, uno dei più piccoli Stati del mondo, chiuso dentro il territorio italiano. Sulle sue tre cime sorgono le torri simbolo del Paese.",
			},
			{
				"label": "Colli Euganei",
				"dove": "Veneto, vicino a Padova — 601 m il punto più alto",
				"risposte": ["Colli Euganei"],
				"nota": "Un gruppo di colline di origine vulcanica che spuntano isolate in mezzo alla pianura padana, ben visibili da lontano proprio perché intorno non c'è altro rilievo.",
			},
			{
				"label": "Il Po",
				"dove": "652 km, il fiume più lungo d'Italia",
				"risposte": ["Po"],
				"nota": "Nasce dal Monviso e attraversa tutta la pianura padana da ovest a est fino all'Adriatico. Nessun altro fiume italiano si avvicina alla sua lunghezza.",
			},
			{
				"label": "L'Adige",
				"dove": "410 km, secondo fiume più lungo d'Italia",
				"risposte": ["Adige"],
				"nota": "Scende dalle Alpi trentine fino all'Adriatico, parallelo al Po ma molto più a est. Attraversa Trento e Verona prima di sfociare vicino a dove un tempo sfociava anche il Po.",
			},
			{
				"label": "Il Tevere",
				"dove": "405 km, il fiume di Roma",
				"risposte": ["Tevere"],
				"nota": "Il terzo fiume italiano per lunghezza, e il più famoso perché attraversa Roma. La città nacque proprio nel punto in cui il fiume si poteva guadare più facilmente.",
			},
			{
				"label": "L'Arno",
				"dove": "241 km, il fiume di Firenze e Pisa",
				"risposte": ["Arno"],
				"nota": "Attraversa Firenze, dove nel 1966 un'alluvione devastante danneggiò migliaia di opere d'arte: da quell'emergenza nacque una nuova generazione di tecniche per il restauro.",
			},
			{
				"label": "Il Ticino",
				"dove": "248 km, esce dal lago Maggiore",
				"risposte": ["Ticino"],
				"nota": "Esce dal lago Maggiore e scende fino al Po, attraversando anche la Svizzera nel suo tratto più alto — dove dà il nome all'omonimo Cantone.",
			},
			{
				"label": "Il Piave",
				"dove": "220 km, «fiume sacro alla Patria»",
				"risposte": ["Piave"],
				"nota": "Fu la linea difensiva decisiva dell'esercito italiano nella Prima guerra mondiale dopo la disfatta di Caporetto: da lì il soprannome «fiume sacro alla Patria» che porta ancora oggi.",
			},
		],
	},
	{
		"id": "geografia-montagne-e-fiumi-del-mondo",
		"subject": "geografia",
		"kind": KIND_CARTA,
		"topics": ["geografia-fisica"],
		"titolo": "Atlante · Montagne e fiumi del mondo",
		"come_si_legge": "Ogni catena e ogni fiume del mondo hanno un continente e spesso un primato: il più alto, il più lungo, il più a nord. I primati si ricordano meglio dei numeri esatti, e bastano a mettere in ordine quasi tutto.",
		"voci": [
			{
				"label": "Aconcagua",
				"dove": "Ande, Argentina — la vetta più alta d'America",
				"risposte": ["Aconcagua", "Ande"],
				"nota": "La montagna più alta dell'intero continente americano, quasi 7000 metri. È anche la più alta del mondo fuori dall'Asia, ed è per questo una delle mete più ambite degli alpinisti.",
			},
			{
				"label": "Elbrus",
				"dove": "monti del Caucaso, Russia",
				"risposte": ["Elbrus", "Caucaso"],
				"nota": "La vetta più alta d'Europa, se si considera il Caucaso come confine orientale del continente: supera il Monte Bianco di quasi mille metri, ma è molto meno conosciuta.",
			},
			{
				"label": "Kilimangiaro",
				"dove": "Tanzania, Africa orientale",
				"risposte": ["Kilimangiaro", "Tanzania"],
				"nota": "La montagna più alta dell'Africa, quasi 5900 metri, e uno dei pochi punti quasi sull'Equatore a essere coperto di neve in cima: più si sale, più la temperatura scende, anche vicinissimo all'Equatore.",
			},
			{
				"label": "Denali",
				"dove": "Alaska, Stati Uniti",
				"risposte": ["Denali", "Alaska"],
				"nota": "La montagna più alta dell'America del Nord, oltre 6000 metri. Il nome significa «il grande» nella lingua degli abitanti originari dell'Alaska, e sostituì ufficialmente il vecchio nome americano nel 2015.",
			},
			{
				"label": "Teide",
				"dove": "isole Canarie, Spagna",
				"risposte": ["Teide", "Canarie"],
				"nota": "Un vulcano che sale dritto dall'oceano Atlantico: è la vetta più alta della Spagna, anche se le Canarie sono isole spagnole al largo delle coste africane, non vicino alla penisola iberica.",
			},
			{
				"label": "Monte Fuji",
				"dove": "Giappone, vicino a Tokyo",
				"risposte": ["Monte Fuji", "Giappone"],
				"nota": "Un vulcano dalla forma perfettamente conica, sacro nella cultura giapponese e raffigurato in migliaia di opere d'arte. È ancora considerato attivo, anche se la sua ultima eruzione risale al 1707.",
			},
			{
				"label": "Il Danubio",
				"dove": "2860 km, attraversa dieci Paesi europei",
				"risposte": ["Danubio"],
				"nota": "Il fiume che attraversa più Paesi al mondo: nasce in Germania e sfocia nel Mar Nero, passando per Vienna, Bratislava, Budapest e Belgrado.",
			},
			{
				"label": "Il Volga",
				"dove": "3530 km, il fiume più lungo d'Europa",
				"risposte": ["Volga"],
				"nota": "Non sfocia in un oceano ma nel Mar Caspio, che è un mare chiuso: è un fiume tutto interno alla Russia, ed è stato per secoli la sua principale via di trasporto.",
			},
			{
				"label": "La Senna",
				"dove": "777 km, attraversa Parigi",
				"risposte": ["Senna"],
				"nota": "Parigi nacque su un'isola in mezzo alla Senna, nel punto in cui il fiume si poteva attraversare e difendere più facilmente.",
			},
			{
				"label": "Il Tamigi",
				"dove": "346 km, attraversa Londra",
				"risposte": ["Tamigi"],
				"nota": "Londra nacque come porto romano su questo fiume, abbastanza dentro terra da essere sicura e abbastanza vicina al mare da ricevere le navi.",
			},
			{
				"label": "Il Reno",
				"dove": "1233 km, attraversa Germania e Paesi Bassi",
				"risposte": ["Reno (europeo)"],
				"nota": "Una delle vie fluviali più trafficate al mondo per il trasporto merci: collega il cuore industriale della Germania al Mare del Nord.",
			},
			{
				"label": "L'Elba",
				"dove": "1091 km, Germania e Repubblica Ceca",
				"risposte": ["Elba"],
				"nota": "Nasce in Repubblica Ceca e attraversa la Germania fino al Mare del Nord: per decenni, durante la divisione della Germania, segnò in parte anche il confine fra est e ovest.",
			},
			{
				"label": "Il Gange",
				"dove": "2525 km, India e Bangladesh",
				"risposte": ["Gange"],
				"nota": "Il fiume più sacro dell'induismo, lungo il quale milioni di persone vivono e si purificano ogni anno. Nasce dai ghiacciai dell'Himalaya e sfocia nel golfo del Bengala.",
			},
			{
				"label": "L'Indo",
				"dove": "3180 km, Pakistan",
				"risposte": ["Indo"],
				"nota": "Dà il nome all'India e al subcontinente indiano, anche se oggi scorre soprattutto in Pakistan. Lungo le sue rive nacque una delle prime grandi civiltà urbane della storia.",
			},
			{
				"label": "Il Mekong",
				"dove": "4350 km, sud-est asiatico",
				"risposte": ["Mekong"],
				"nota": "Attraversa sei Paesi del sud-est asiatico ed è la principale fonte di pesce d'acqua dolce del mondo: decine di milioni di persone vivono di quello che dà questo fiume.",
			},
			{
				"label": "Lo Yangtze",
				"dove": "6300 km, il fiume più lungo dell'Asia",
				"risposte": ["Yangtze"],
				"nota": "Il fiume più lungo dell'Asia e il terzo al mondo. Attraversa la Cina da ovest a est, e lungo il suo corso si trova la più grande diga idroelettrica del pianeta.",
			},
			{
				"label": "Il Rio delle Amazzoni",
				"dove": "6400 km, America del Sud",
				"risposte": ["Rio delle Amazzoni"],
				"nota": "Il fiume che porta più acqua al mondo, di gran lunga: da solo scarica nell'oceano più acqua dei successivi sette fiumi più grandi messi insieme.",
			},
			{
				"label": "Il Mississippi",
				"dove": "3770 km, Stati Uniti",
				"risposte": ["Mississippi"],
				"nota": "Attraversa gli Stati Uniti da nord a sud ed è stato per secoli la principale via di trasporto merci del Paese, prima che arrivassero le ferrovie e le autostrade.",
			},
			{
				"label": "Il Congo",
				"dove": "4700 km, Africa centrale",
				"risposte": ["Congo"],
				"nota": "Il fiume più profondo del mondo, con tratti che superano i 200 metri: attraversa la grande foresta pluviale dell'Africa centrale ed è l'unico grande fiume ad attraversare l'Equatore due volte.",
			},
		],
	},
	{
		"id": "geografia-monete-del-mondo",
		"subject": "geografia",
		"kind": KIND_SCHEDA,
		"topics": ["monete"],
		"titolo": "Scheda · Le monete del mondo",
		"come_si_legge": "Ogni Paese, o gruppo di Paesi, batte la propria moneta: chi la controlla controlla anche i prezzi e gli scambi con l'estero. Poche monete sono condivise da più Stati insieme, ed è sempre una scelta politica, non un caso.",
		"voci": [
			{
				"label": "Italia · Euro",
				"in_breve": "moneta condivisa da venti Paesi europei",
				"risposte": ["Italia", "Euro"],
				"nota": "L'euro è entrato in circolazione nel 2002 al posto della lira, e con esso l'Italia condivide la moneta con altri diciannove Paesi europei: un prezzo si confronta subito, senza dover cambiare valuta.",
			},
			{
				"label": "Stati Uniti · Dollaro",
				"in_breve": "la moneta più usata negli scambi internazionali",
				"risposte": ["Stati Uniti", "Dollaro"],
				"nota": "Il dollaro americano è la moneta più usata al mondo per gli scambi fra Paesi diversi, anche quando nessuno dei due è americano: è diventato una specie di lingua comune del commercio internazionale.",
			},
			{
				"label": "Giappone · Yen",
				"in_breve": "una delle monete più scambiate al mondo",
				"risposte": ["Giappone", "Yen"],
				"nota": "Lo yen giapponese è fra le monete più scambiate al mondo insieme a dollaro ed euro, riflesso della grande forza dell'economia giapponese, in particolare nell'industria e nella tecnologia.",
			},
			{
				"label": "Regno Unito · Sterlina",
				"in_breve": "moneta più antica ancora in uso",
				"risposte": ["Regno Unito", "Sterlina"],
				"nota": "La sterlina è fra le monete più antiche ancora in circolazione, con un nome che risale a mille anni fa. Il Regno Unito ha scelto di non adottare l'euro pur facendo parte per decenni dell'Unione Europea.",
			},
		],
	},
	{
		"id": "geografia-monumenti-del-mondo",
		"subject": "geografia",
		"kind": KIND_SCHEDA,
		"topics": ["monumenti"],
		"titolo": "Scheda · I monumenti del mondo e chi li ha costruiti",
		"come_si_legge": "Un monumento non è solo bello da vedere: segna un popolo, un'epoca o una fede che chi l'ha costruito voleva ricordare per sempre. Riconoscerlo vuol dire riconoscere chi lo ha fatto e perché.",
		"voci": [
			{
				"label": "Colosseo",
				"in_breve": "Italia, Roma",
				"risposte": ["Colosseo", "Italia"],
				"nota": "Il più grande anfiteatro dell'impero romano, capace di riempirsi e svuotarsi in pochi minuti grazie a decine di ingressi numerati — la stessa idea con cui sono costruiti gli stadi di oggi.",
			},
			{
				"label": "Torre di Pisa",
				"in_breve": "Italia, Pisa",
				"risposte": ["Torre di Pisa"],
				"nota": "Comincia a pendere già durante la costruzione, nel Duecento, perché il terreno sotto una parte delle fondamenta era troppo morbido. La pendenza che doveva essere un difetto l'ha resa famosa in tutto il mondo.",
			},
			{
				"label": "Tour Eiffel",
				"in_breve": "Francia, Parigi",
				"risposte": ["Tour Eiffel", "Francia"],
				"nota": "Costruita per l'Esposizione universale del 1889, doveva restare in piedi solo vent'anni: fu salvata perché si scoprì utile come antenna per le trasmissioni radio, appena inventate.",
			},
			{
				"label": "Piramidi di Giza",
				"in_breve": "Egitto",
				"risposte": ["Piramidi di Giza", "Egitto"],
				"nota": "Tombe monumentali dei faraoni, costruite per durare in eterno. La grande piramide restò l'edificio più alto del mondo per quasi quattromila anni, un record che nessun'altra costruzione ha mai avvicinato.",
			},
			{
				"label": "Statua della Libertà",
				"in_breve": "Stati Uniti, New York",
				"risposte": ["Statua della Libertà", "Stati Uniti"],
				"nota": "Un regalo della Francia agli Stati Uniti nel 1886, per celebrare l'amicizia fra i due Paesi. Fu il primo simbolo che vedevano i milioni di emigranti in arrivo via nave nel porto di New York.",
			},
			{
				"label": "Big Ben",
				"in_breve": "Regno Unito, Londra",
				"risposte": ["Big Ben", "Regno Unito"],
				"nota": "In realtà è il nome della grande campana dentro la torre, non della torre stessa: ma con il tempo tutti hanno cominciato a chiamare così l'intero edificio del Parlamento britannico.",
			},
			{
				"label": "Sagrada Família",
				"in_breve": "Spagna, Barcellona",
				"risposte": ["Sagrada Família", "Spagna"],
				"nota": "L'architetto Gaudí la iniziò nel 1882 e non l'ha mai vista finita: i lavori continuano ancora oggi, più di cent'anni dopo la sua morte, finanziati solo dai biglietti dei visitatori.",
			},
			{
				"label": "Partenone",
				"in_breve": "Grecia, Atene",
				"risposte": ["Partenone", "Grecia"],
				"nota": "Il tempio della dea Atena sull'Acropoli, costruito nel momento di massima ricchezza della città. Le sue colonne non sono perfettamente dritte: si curvano leggermente per sembrare più regolari all'occhio umano.",
			},
			{
				"label": "Muraglia cinese",
				"in_breve": "Cina",
				"risposte": ["Muraglia cinese", "Cina"],
				"nota": "Non è un muro unico e continuo ma tanti tratti costruiti in epoche diverse e poi collegati, per fermare gli attacchi dei popoli delle steppe da nord. È lunga più di ventimila chilometri, contando tutti i rami.",
			},
			{
				"label": "Taj Mahal",
				"in_breve": "India, Agra",
				"risposte": ["Taj Mahal", "India"],
				"nota": "Un mausoleo di marmo bianco fatto costruire da un imperatore in memoria della moglie amata, morta di parto. Cambia colore con la luce del giorno: rosato all'alba, bianco a mezzogiorno, dorato al tramonto.",
			},
			{
				"label": "Cristo Redentore",
				"in_breve": "Brasile, Rio de Janeiro",
				"risposte": ["Cristo Redentore", "Brasile"],
				"nota": "Una statua alta trenta metri in cima a un monte che domina Rio de Janeiro, con le braccia aperte come ad abbracciare la città. È colpita dai fulmini più volte all'anno.",
			},
			{
				"label": "Machu Picchu",
				"in_breve": "Perù, sulle Ande",
				"risposte": ["Machu Picchu", "Perù"],
				"nota": "Una città Inca costruita in cima a una montagna, così nascosta che i conquistatori spagnoli non la trovarono mai. Fu riscoperta dal mondo esterno solo nel 1911.",
			},
			{
				"label": "Monte Fuji",
				"in_breve": "Giappone",
				"risposte": ["Monte Fuji", "Giappone"],
				"nota": "Un vulcano dalla forma perfettamente conica, sacro nella cultura giapponese e raffigurato in migliaia di opere d'arte. È ancora considerato attivo, anche se non erutta dal 1707.",
			},
			{
				"label": "Opera House",
				"in_breve": "Australia, Sydney",
				"risposte": ["Opera House", "Australia"],
				"nota": "Il teatro dell'opera di Sydney, con i tetti a forma di vele o di conchiglie affacciati sulla baia. Fu così difficile da costruire con quella forma che i lavori durarono quattordici anni, il triplo del previsto.",
			},
			{
				"label": "Petra",
				"in_breve": "Giordania",
				"risposte": ["Petra", "Giordania"],
				"nota": "Un'intera città scavata direttamente nella roccia rosa del deserto, raggiungibile solo attraverso uno stretto canyon. Rimase quasi dimenticata per secoli, finché un esploratore europeo non la ritrovò nel 1812.",
			},
			{
				"label": "Stonehenge",
				"in_breve": "Inghilterra",
				"risposte": ["Stonehenge", "Inghilterra"],
				"nota": "Un cerchio di enormi pietre erette più di quattromila anni fa, alcune trasportate per centinaia di chilometri senza ruote né animali da traino. Nessuno sa con certezza a cosa servisse davvero.",
			},
			{
				"label": "Mulini di Kinderdijk",
				"in_breve": "Paesi Bassi",
				"risposte": ["Mulini di Kinderdijk", "Paesi Bassi"],
				"nota": "Diciannove mulini a vento del Settecento, costruiti per pompare fuori l'acqua da un terreno che sta sotto il livello del mare: senza quel lavoro costante, quella terra tornerebbe sommersa.",
			},
			{
				"label": "Castello di Neuschwanstein",
				"in_breve": "Germania, Baviera",
				"risposte": ["Castello di Neuschwanstein", "Germania"],
				"nota": "Fatto costruire nell'Ottocento da un re bavarese che amava le leggende medievali, non è affatto antico come sembra. È il castello a cui si sono ispirati i disegnatori del castello Disney.",
			},
			{
				"label": "Cattedrale di San Basilio",
				"in_breve": "Russia, Mosca",
				"risposte": ["Cattedrale di San Basilio", "Russia"],
				"nota": "Le sue cupole a forma di cipolla, colorate come caramelle, dominano la Piazza Rossa di Mosca da quasi cinquecento anni. Ogni cupola ha un colore e un disegno diversi dalle altre.",
			},
			{
				"label": "Chichén Itzá",
				"in_breve": "Messico, Yucatán",
				"risposte": ["Chichén Itzá", "Messico"],
				"nota": "Una grande città Maya con al centro una piramide a gradoni costruita seguendo il calendario: ha 365 scalini in tutto, uno per ogni giorno dell'anno.",
			},
			{
				"label": "Angkor Wat",
				"in_breve": "Cambogia",
				"risposte": ["Angkor Wat", "Cambogia"],
				"nota": "Il più grande edificio religioso mai costruito, immerso nella foresta cambogiana. Fu costruito come tempio induista e poi diventò buddista, senza che nessuno lo demolisse: cambiò semplicemente fede insieme al popolo che lo usava.",
			},
			{
				"label": "Fiordi di Geiranger",
				"in_breve": "Norvegia",
				"risposte": ["Fiordi di Geiranger", "Norvegia"],
				"nota": "Valli scavate da antichi ghiacciai e poi invase dal mare, con pareti che si alzano quasi verticali per centinaia di metri. Sono il motivo per cui le città norvegesi stanno quasi tutte in fondo a insenature strette.",
			},
			{
				"label": "Cascate Vittoria",
				"in_breve": "Zambia e Zimbabwe",
				"risposte": ["Cascate Vittoria", "Zambia"],
				"nota": "Sul fiume Zambesi, in Africa: la cortina d'acqua che cade è così larga e così alta insieme che gli abitanti locali la chiamavano «il fumo che tuona», per lo spruzzo visibile a chilometri di distanza.",
			},
			{
				"label": "Colosso di Rodi",
				"in_breve": "Grecia, isola di Rodi (rovine)",
				"risposte": ["Colosso di Rodi (rovine)"],
				"nota": "Un'enorme statua di bronzo alta più di trenta metri, una delle sette meraviglie del mondo antico. Crollò in un terremoto meno di un secolo dopo essere stata costruita, e oggi non ne resta nulla in piedi.",
			},
		],
	},
]

# --- API ---------------------------------------------------------------------

## --- LATINO: i paradigmi, cioè la lavagna che nessuno aveva mai messo in aula -
##
## Richiesta del committente, 2 settembre 2026: «dobbiamo spiegare prima di
## chiedere, e dobbiamo spiegare bene. Un bambino di 10-11 anni non ha mai visto
## il latino».
##
## Storia e geografia avevano il difetto della domanda di NOME; il latino ha il
## difetto opposto e più grave. Qui la domanda non chiede un nome ma una FORMA —
## «che caso è *dominorum*?», «quale forma useresti per dire *della rosa*?» — e
## la forma non si può dedurre da niente: sta su una tabella, e o quella tabella
## qualcuno te l'ha mostrata, o la domanda è un sorteggio. Ogni libro di latino
## del mondo comincia stampando quella tabella nella prima pagina. Questo gioco
## la chiedeva senza averla mai stampata.
##
## ### La famiglia nuova: `paradigma`
##
## Una linea del tempo ha per coordinata un ANNO, una carta un LUOGO. Un
## paradigma ha per coordinata la **forma**: la parola come si scrive quando fa
## quel mestiere. È il terzo modo in cui un fatto può avere un posto, e il campo
## si chiama `forma` proprio perché chi scrive una voce nuova se ne accorga.
##
## Le voci di un paradigma non sono i nomi latini: sono le **caselle** della
## tabella — «genitivo singolare», «accusativo plurale» — e ciascuna vale per
## tutte le parole del suo gruppo insieme. Per questo molte dichiarano `regola`
## invece di `risposte`: la regola è l'elenco delle radici del gruppo più la
## desinenza della casella, cioè esattamente ciò che la casella insegna. Una
## sola riga di espressione regolare copre le sei parole della prima
## declinazione, e resta vera anche quando se ne aggiunge una settima.
##
## E le caselle stanno **nell'ordine del paradigma**, non in ordine alfabetico:
## le vicine che `estratto()` mostra attorno a quella cercata sono le righe
## sopra e sotto della tabella vera, come sul libro.
const TAVOLE_LATINO := [
	{
		"id": "latino-i-casi",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["casi", "basi"],
		"titolo": "I sei casi: a che domanda risponde ciascuno",
		"come_si_legge": "In italiano capisci chi fa e chi subisce dal POSTO delle parole. In latino lo dice la fine della parola: ogni «caso» è una coda diversa, e ogni coda risponde a una domanda precisa. Impara la domanda, non il nome: il nome viene dopo da solo.",
		"voci": [
			{
				"label": "Il nominativo",
				"in_breve": "chi? che cosa? — chi compie l'azione",
				"risposte": ["Nominativo", "nominativo", "soggetto"],
				"nota": "È la forma con cui la parola sta sul vocabolario, ed è quella di chi agisce: in «Dominus servum vocat» è «dominus», il padrone che chiama.",
			},
			{
				"label": "Il genitivo",
				"in_breve": "di chi? di che cosa?",
				"risposte": ["Genitivo", "genitivo", "specificazione"],
				"nota": "Dice a chi appartiene una cosa, o di che cosa si parla: «rosae» è «della rosa». È anche la forma che il vocabolario stampa per seconda, perché dice a quale gruppo appartiene la parola.",
			},
			{
				"label": "Il dativo",
				"in_breve": "a chi? a che cosa?",
				"risposte": ["Dativo", "dativo", "termine"],
				"nota": "Dice a chi si dà, si dice o si porta qualcosa: «rosae» come «alla rosa», «domino» come «al padrone». In italiano lo diciamo con la paroletta «a», in latino con la coda.",
			},
			{
				"label": "L'accusativo",
				"in_breve": "chi? che cosa? — chi subisce l'azione",
				"risposte": ["Accusativo", "accusativo", "Complemento oggetto", "oggetto"],
				"nota": "È il caso di chi riceve l'azione, ed è quello che in italiano non si vede: «la rosa» soggetto e «la rosa» oggetto si scrivono uguali, il latino no. Al singolare finisce quasi sempre in -m: rosam, dominum, regem.",
			},
			{
				"label": "L'ablativo",
				"in_breve": "con che cosa? in che modo? da dove?",
				"risposte": ["Ablativo", "ablativo", "mezzo"],
				"nota": "È il caso del mezzo, del modo e del luogo da cui si viene: «gladio» vuol dire «con la spada». È il più largo dei sei, ed è per questo che spesso si accompagna a una preposizione che ne precisa il senso.",
			},
			{
				"label": "Il vocativo",
				"in_breve": "chi si sta chiamando?",
				"risposte": ["Vocativo", "vocativo", "invocazione"],
				"nota": "Serve solo a chiamare qualcuno per nome: «Marce!» invece di «Marcus». È il caso più facile perché quasi sempre è identico al nominativo, tranne per i nomi in -us della seconda.",
			},
			{
				"label": "Quanti sono i casi",
				"in_breve": "sei, per due numeri: dodici caselle in tutto",
				"risposte": ["6", "sei", "Sei"],
				"nota": "Sei casi al singolare e gli stessi sei al plurale: una tabella di dodici caselle per ogni parola. Sembrano tante, ma molte caselle si scrivono uguali fra loro, quindi le forme davvero diverse da imparare sono sempre meno di dodici.",
			},
			{
				"label": "La desinenza",
				"in_breve": "il pezzetto finale che cambia",
				"risposte": ["desinenza", "la desinenza", "coda"],
				"nota": "È il pezzo di parola che cambia da caso a caso mentre la prima parte resta ferma: ros-a, ros-ae, ros-am. La parte ferma si chiama radice e porta il significato; la desinenza porta il mestiere che la parola fa nella frase.",
			},
			{
				"label": "La declinazione",
				"in_breve": "tutte le dodici caselle di una parola",
				"risposte": ["declinazione", "la declinazione", "declinazioni"],
				"nota": "«Declinare» un nome vuol dire dire tutte le sue forme in fila. La declinazione è insieme l'elenco di quelle forme e il gruppo a cui la parola appartiene: i gruppi sono cinque, e ciascuno ha le sue code.",
			},
			{
				"label": "La coda di chi subisce",
				"in_breve": "-am, -um, -em al singolare",
				"regola": "^(agn|aqu|bell|discipul|don|leg|libr|poet|puer|reg|serv|stell|domin|amic|milit|consul|puell|ros|terr|patri|silv|templ|man|exercit)(am|um|em)$",
				"nota": "Al singolare la parola che subisce l'azione finisce quasi sempre in -m: rosam, servum, regem. È la coda più utile di tutte, perché è quella che distingue chi fa da chi riceve — cioè la cosa che in italiano fa il posto nella frase.",
			},
		],
	},
	{
		"id": "latino-che-cose-il-latino",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["basi"],
		"titolo": "Da dove viene, e dove è finito",
		"come_si_legge": "Il latino non è una lingua lontana da imparare da zero: è la lingua da cui è nato l'italiano. Queste righe dicono chi lo parlava, che fine ha fatto e perché continuiamo a incontrarlo.",
		"voci": [
			{
				"label": "I Romani",
				"in_breve": "il popolo che lo parlava",
				"risposte": ["I Romani", "Romani"],
				"nota": "Nato nel Lazio, la regione di Roma, si è diffuso in tutto l'impero insieme alle strade e ai soldati. Le iscrizioni ufficiali sui monumenti sono quasi tutte in latino, ed è per questo che si leggono ancora oggi.",
			},
			{
				"label": "Il latino",
				"in_breve": "la lingua madre di cinque lingue vive",
				"risposte": ["Il latino", "latino", "Latino"],
				"nota": "Italiano, spagnolo, francese, portoghese e rumeno vengono tutti da qui: si chiamano lingue romanze, cioè «di Roma». Non è morto di colpo — è cambiato lentamente, finché quello che si parlava non era più latino.",
			},
			{
				"label": "Le parole di ogni giorno",
				"in_breve": "circa metà dell'italiano",
				"risposte": ["Perché molte parole nascono dalle stesse radici"],
				"nota": "Acqua, terra, madre, libro, scrivere, vedere: sono parole latine appena cambiate. Riconoscere la radice serve a capire parole italiane che non hai mai sentito, ed è il motivo pratico per cui il latino si studia ancora.",
			},
			{
				"label": "Carpe diem",
				"in_breve": "«cogli il giorno»",
				"risposte": ["Cogli l'attimo"],
				"nota": "La frase di un poeta latino, Orazio: invita a prendere quello che offre oggi invece di rimandare. Si cita ancora intera, in latino, perché in tre parole dice quello che a noi ne costa venti.",
			},
			{
				"label": "Una lingua flessiva",
				"in_breve": "le parole cambiano la fine",
				"risposte": ["Una lingua in cui le parole cambiano desinenza"],
				"nota": "Si dice «flessiva» una lingua in cui le parole si piegano — cambiano la coda — per dire che mestiere fanno nella frase. L'italiano lo fa pochissimo (amico/amici); il latino lo fa sempre, ed è la sua differenza principale.",
			},
		],
	},
	{
		"id": "latino-i-cinque-gruppi",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["declinazioni-base", "basi"],
		"titolo": "I cinque gruppi, e come si riconoscono",
		"come_si_legge": "Ogni nome latino appartiene a uno di cinque gruppi, e ogni gruppo ha le sue code. A dire di quale gruppo si tratta NON è la prima forma ma la seconda, quella del «di»: è l'unica che non si ripete fra gruppi diversi. Per questo il vocabolario le stampa sempre in coppia.",
		"voci": [
			{
				"label": "La prima declinazione",
				"in_breve": "rosa, rosae — «di» in -ae",
				"risposte": ["Prima", "prima declinazione", "In -a", "rosa", "rosae", "rosam", "rosas", "rosarum", "rosis"],
				"nota": "Nomi che finiscono in -a, quasi tutti femminili: rosa, puella, aqua, terra. Le eccezioni maschili sono poche e si imparano a memoria — nauta il marinaio, agricola il contadino, poeta il poeta.",
			},
			{
				"label": "La seconda declinazione",
				"in_breve": "dominus, domini — «di» in -i",
				"risposte": ["Seconda", "Seconda declinazione", "domini", "dominus"],
				"nota": "Nomi in -us quasi tutti maschili (dominus, servus, amicus) e nomi in -um tutti neutri (bellum, templum, donum). Da questo gruppo vengono la maggior parte dei nomi italiani che finiscono in -o.",
			},
			{
				"label": "La terza declinazione",
				"in_breve": "rex, regis — «di» in -is",
				"risposte": ["terza declinazione", "Terza", "rex", "regis"],
				"nota": "Il gruppo più grande e più disordinato: la prima forma è imprevedibile (rex, consul, miles, corpus) e va imparata a memoria, ma dalla seconda in poi tutto torna regolare.",
			},
			{
				"label": "La quarta declinazione",
				"in_breve": "manus, manus — «di» in -us",
				"risposte": ["Quarta", "quarta declinazione"],
				"nota": "Piccola ma piena di parole d'uso quotidiano: manus la mano, exercitus l'esercito, senatus il senato. Si confonde con la seconda perché anche lì la prima forma finisce in -us: a distinguerle è la seconda.",
			},
			{
				"label": "La quinta declinazione",
				"in_breve": "res, rei — «di» in -ei",
				"risposte": ["Quinta declinazione", "Quinta", "quinta declinazione"],
				"nota": "La più piccola di tutte, ma dentro ci sono «res» (la cosa) e «dies» (il giorno), che si usano di continuo. Da res viene «reale», da dies vengono «diario» e «meridiana».",
			},
			{
				"label": "Quante declinazioni ci sono",
				"in_breve": "cinque gruppi",
				"risposte": ["5", "cinque"],
				"nota": "Cinque, ma non si equivalgono: le prime tre coprono la stragrande maggioranza dei nomi che si incontrano leggendo, e la quarta e la quinta insieme sono poche decine di parole.",
			},
			{
				"label": "I tre generi",
				"in_breve": "maschile, femminile, neutro",
				"risposte": ["3", "tre"],
				"nota": "Il latino ha un genere in più dell'italiano: il neutro, che serve per le cose. L'italiano l'ha perso, ma ne restano le tracce nei plurali strani come «le braccia» e «le uova», che vengono da neutri latini.",
			},
			{
				"label": "I due numeri",
				"in_breve": "singolare e plurale",
				"risposte": ["2", "due"],
				"nota": "Solo due, come in italiano: uno e più di uno. Il greco antico aveva anche il duale, una forma apposta per le coppie, ma il latino classico non ce l'ha.",
			},
		],
	},
	{
		"id": "latino-prima-declinazione",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["declinazione-1"],
		"titolo": "Prima declinazione · rosa, puella, aqua, terra, patria, silva",
		"come_si_legge": "La radice resta ferma (ros-, puell-, aqu-) e cambia solo la coda. Leggi la tabella dall'alto in basso: prima le sei caselle del singolare, poi le sei del plurale. Le caselle che si scrivono uguali sono scritte insieme apposta: è la difficoltà vera di questa declinazione.",
		"voci": [
			{
				"label": "Nominativo singolare",
				"forma": "-a · rosa, puella, aqua",
				"regola": "^(ros|puell|aqu|terr|patri|silv)a$",
				"risposte": ["nominativo singolare"],
				"nota": "La forma del vocabolario, quella di chi agisce. È anche identica all'ablativo singolare: due caselle, una scrittura sola, e a distinguerle è soltanto il resto della frase.",
			},
			{
				"label": "Genitivo e dativo singolare",
				"forma": "-ae · rosae («della rosa», «alla rosa»)",
				"regola": "^(ros|puell|aqu|terr|patri|silv)ae$",
				"risposte": ["genitivo singolare", "dativo singolare"],
				"nota": "Una scrittura per due mestieri diversi: «di» e «a». E per di più è uguale anche al nominativo plurale, tre righe più sotto: «rosae» è la forma più ambigua di tutta la declinazione, e si scioglie solo leggendo la frase intera.",
			},
			{
				"label": "Accusativo singolare",
				"forma": "-am · rosam (la rosa che subisce)",
				"regola": "^(ros|puell|aqu|terr|patri|silv)am$",
				"risposte": ["accusativo singolare"],
				"nota": "La coda in -m di chi riceve l'azione, e non si confonde con nessun'altra casella: è la forma più riconoscibile della prima declinazione, ed è quella che serve per capire chi fa e chi subisce.",
			},
			{
				"label": "Ablativo singolare",
				"forma": "-a · rosa («con la rosa»)",
				"risposte": ["ablativo singolare"],
				"nota": "Si scrive esattamente come il nominativo. Nei libri antichi si segnava con un trattino sopra la vocale, perché in origine si pronunciava più lunga: quel trattino oggi si stampa solo nei manuali per principianti.",
			},
			{
				"label": "Nominativo plurale",
				"forma": "-ae · rosae (le rose che agiscono)",
				"risposte": ["nominativo plurale"],
				"nota": "Uguale al genitivo e al dativo singolare. È il motivo per cui davanti a «rosae» non si può rispondere subito: bisogna guardare il verbo, e vedere se è al singolare o al plurale.",
			},
			{
				"label": "Genitivo plurale",
				"forma": "-arum · rosarum («delle rose»)",
				"regola": "^(ros|puell|aqu|terr|patri|silv)arum$",
				"risposte": ["genitivo plurale"],
				"nota": "Lunga e inconfondibile: nessun'altra casella di nessuna declinazione finisce in -arum. Quando la vedi hai finito di ragionare, ed è la casella che regala più punti in una traduzione.",
			},
			{
				"label": "Dativo e ablativo plurale",
				"forma": "-is · rosis («alle rose», «con le rose»)",
				"regola": "^(ros|puell|aqu|terr|patri|silv)is$",
				"risposte": ["dativo plurale", "ablativo plurale", "rosis"],
				"nota": "Due mestieri e una scrittura sola, come al singolare accadeva a «-ae». Al plurale il latino ha smesso di distinguere «a» da «con»: succede in tutte e cinque le declinazioni, e per questo si impara una volta per tutte.",
			},
			{
				"label": "Accusativo plurale",
				"forma": "-as · rosas (le rose che subiscono)",
				"regola": "^(ros|puell|aqu|terr|patri|silv)as$",
				"risposte": ["accusativo plurale"],
				"nota": "La coda -as segna chi riceve l'azione quando sono più di uno. Attenzione a non confonderla con «-ae»: la differenza di una lettera qui rovescia il senso della frase.",
			},
		],
	},
	{
		"id": "latino-seconda-declinazione",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["declinazione-2m", "declinazione-2n"],
		"titolo": "Seconda declinazione · dominus (maschile) e templum (neutro)",
		"come_si_legge": "Due colonne nella stessa tabella: i maschili in -us (dominus, servus, amicus, populus) e i neutri in -um (bellum, templum, donum). Dalla seconda casella in giù sono identici — cambiano solo dove si distingue chi agisce da chi subisce, e nei neutri quella distinzione non esiste.",
		"voci": [
			{
				"label": "Nominativo singolare",
				"forma": "-us · dominus | -um · templum",
				"regola": "^(domin|serv|amic|popul)us$|^(bell|templ|don)um$",
				"risposte": ["nominativo singolare"],
				"nota": "La forma del vocabolario. Nei maschili è -us, nei neutri -um: è l'unica casella in cui le due colonne partono davvero diverse, e da qui si capisce subito con quale delle due si ha a che fare.",
			},
			{
				"label": "Genitivo singolare",
				"forma": "-i · domini, templi («del padrone», «del tempio»)",
				"regola": "^(domin|serv|amic|popul|bell|templ|don)i$",
				"risposte": ["genitivo singolare"],
				"nota": "Uguale per maschili e neutri, ed è la casella che dice a quale gruppo appartiene la parola: la -i è il marchio della seconda declinazione, e nessun altro gruppo ce l'ha.",
			},
			{
				"label": "Dativo e ablativo singolare",
				"forma": "-o · domino, templo («al padrone», «col tempio»)",
				"regola": "^(domin|serv|amic|popul|bell|templ|don)o$",
				"risposte": ["dativo singolare", "ablativo singolare"],
				"nota": "Una scrittura per due mestieri: «a» e «con». Da questa casella viene la -o finale di tantissimi avverbi e nomi italiani, che il latino usava come ablativo: «subito», «raro», «vero».",
			},
			{
				"label": "Accusativo singolare",
				"forma": "-um · dominum | -um · templum",
				"regola": "^(domin|serv|amic|popul|bell|templ|don)um$",
				"risposte": ["accusativo singolare"],
				"nota": "Nei maschili è diversa dal nominativo (dominus/dominum) e quindi dice chiaramente chi subisce; nei neutri è identica al nominativo (templum/templum), e lì a dirlo deve essere il resto della frase.",
			},
			{
				"label": "Nominativo plurale",
				"forma": "-i · domini | -a · templa",
				"regola": "^(bell|templ|don)a$",
				"risposte": ["nominativo plurale"],
				"nota": "I maschili fanno -i, i neutri fanno -a. Quel plurale neutro in -a è sopravvissuto in italiano nei plurali strani: «le braccia», «le uova», «le dita» sono neutri latini che si comportano ancora da neutri.",
			},
			{
				"label": "Genitivo plurale",
				"forma": "-orum · dominorum, templorum",
				"regola": "^(domin|serv|amic|popul|bell|templ|don)orum$",
				"risposte": ["genitivo plurale"],
				"nota": "Lunga e inconfondibile, come «-arum» nella prima: quando la vedi sai già che significa «di» ed è plurale, senza bisogno di guardare altro.",
			},
			{
				"label": "Dativo e ablativo plurale",
				"forma": "-is · dominis, templis",
				"regola": "^(domin|serv|amic|popul|bell|templ|don)is$",
				"risposte": ["dativo plurale", "ablativo plurale"],
				"nota": "La stessa coda -is della prima declinazione: al plurale il latino usa una forma sola per «a» e per «con» in tutti i gruppi. È una delle poche semplificazioni che questa lingua concede.",
			},
			{
				"label": "Accusativo plurale",
				"forma": "-os · dominos | -a · templa",
				"regola": "^(domin|serv|amic|popul)os$",
				"risposte": ["accusativo plurale"],
				"nota": "Nei maschili la coda -os segna chi subisce quando sono più di uno; nei neutri torna la -a, identica al nominativo plurale, per lo stesso motivo di sempre: una cosa non compie azioni.",
			},
			{
				"label": "Che cosa vogliono dire i neutri",
				"forma": "bellum la guerra · templum il tempio · donum il dono",
				"risposte": ["Guerra", "tempio", "il tempio", "Donare e donazione"],
				"nota": "«Bellum» è il falso amico più famoso del latino: sembra «bello» e vuol dire guerra, e da lì vengono bellico e belligerante. Da «templum» viene tempio, da «donum» vengono donare, donazione e perdonare.",
			},
			{
				"label": "Il plurale neutro sopravvissuto in italiano",
				"forma": "-a · le uova, le braccia, le dita, le ginocchia",
				"risposte": ["Le uova"],
				"nota": "L'italiano ha perso il neutro, ma non del tutto: «uovo» fa «le uova» e non «gli uovi» perché in latino era il neutro «ovum, ova». Sono le ultime tracce vive di un genere che non usiamo più.",
			},
		],
	},
	{
		"id": "latino-terza-declinazione",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["declinazione-3m", "declinazione-3n"],
		"titolo": "Terza declinazione · rex (maschile) e tempus (neutro)",
		"come_si_legge": "Questa tabella si legge partendo dalla SECONDA riga, non dalla prima: la prima forma è imprevedibile (rex, consul, miles, lex, virtus, corpus, tempus) e va imparata a memoria insieme al significato. Dalla seconda in poi tutto è regolare, e la radice che vedi lì — reg-, milit-, corpor- — è quella vera.",
		"voci": [
			{
				"label": "Nominativo singolare",
				"forma": "imprevedibile · rex, consul, miles, lex, virtus, corpus, tempus",
				"risposte": ["nominativo singolare", "rex", "consul", "miles", "lex", "virtus", "corpus", "tempus", "Perché non segue una forma prevedibile"],
				"nota": "Non c'è nessuna coda fissa: queste parole sono così antiche e così usate che si sono consumate, come uno scalino calpestato per secoli. È il motivo per cui il vocabolario stampa sempre due forme invece di una.",
			},
			{
				"label": "Genitivo singolare",
				"forma": "-is · regis, militis, corporis",
				"regola": "^(reg|consul|milit|virtut|leg|corpor|tempor)is$",
				"risposte": ["genitivo singolare", "Dal genitivo singolare in -is"],
				"nota": "La casella più importante di tutta la declinazione: dice a quale gruppo appartiene la parola (la -is è il marchio della terza) e mostra la radice vera, che nella prima forma era nascosta. «Rex» diventa «reg-», «miles» diventa «milit-».",
			},
			{
				"label": "Dativo singolare",
				"forma": "-i · regi, militi, corpori",
				"regola": "^(reg|consul|milit|virtut|leg|corpor|tempor)i$",
				"risposte": ["dativo singolare"],
				"nota": "Una -i secca attaccata alla radice: «regi» è «al re». Da non confondere con il genitivo della seconda declinazione, che ha la stessa lettera ma si attacca a una radice di tipo diverso.",
			},
			{
				"label": "Accusativo singolare",
				"forma": "-em · regem, militem | uguale al nominativo nei neutri",
				"regola": "^(reg|consul|milit|virtut|leg)em$",
				"risposte": ["accusativo singolare"],
				"nota": "La coda -em segna chi subisce. Nei neutri (corpus, tempus) questa casella non esiste come forma a parte: si scrive come il nominativo, perché una cosa non agisce e il latino non ha mai avuto bisogno di distinguerle.",
			},
			{
				"label": "Ablativo singolare",
				"forma": "-e · rege, milite, corpore",
				"regola": "^(reg|consul|milit|virtut|leg|corpor|tempor)e$",
				"risposte": ["ablativo singolare"],
				"nota": "Una -e sola: «corpore» è «col corpo». È la casella da cui vengono moltissimi avverbi italiani in -e, e la si distingue dal dativo per una lettera sola.",
			},
			{
				"label": "Nominativo e accusativo plurale",
				"forma": "-es · reges, milites | -a · corpora, tempora",
				"regola": "^(reg|consul|milit|virtut|leg)es$|^(corpor|tempor)a$",
				"risposte": ["nominativo plurale", "accusativo plurale"],
				"nota": "Nei maschili e femminili le due caselle si scrivono uguali (-es), e questo è raro e va ricordato; nei neutri fanno tutte e due -a, come in ogni neutro latino. Da «corpora» e «tempora» vengono «corporeo» e «temporale».",
			},
			{
				"label": "Genitivo plurale",
				"forma": "-um · regum, militum, corporum",
				"regola": "^(reg|consul|milit|virtut|leg|corpor|tempor)um$",
				"risposte": ["genitivo plurale"],
				"nota": "Corta, appena -um: è la più insidiosa del gruppo, perché somiglia all'accusativo singolare della seconda declinazione (dominum). Guarda sempre la radice prima di decidere.",
			},
			{
				"label": "Dativo e ablativo plurale",
				"forma": "-ibus · regibus, militibus, corporibus",
				"regola": "^(reg|consul|milit|virtut|leg|corpor|tempor)ibus$",
				"risposte": ["dativo plurale", "ablativo plurale"],
				"nota": "La coda -ibus è lunga e appartiene solo alla terza e alla quarta declinazione: quando la vedi hai già ristretto il campo a due gruppi su cinque.",
			},
			{
				"label": "Le parole italiane che ne vengono",
				"forma": "da corpus corporeo · da tempus temporale",
				"risposte": ["Corporeo", "Temporale"],
				"nota": "Le parole italiane non nascono dalla prima forma latina ma dalla RADICE, quella che si vede nel genitivo: da «corpor-» viene corporeo, da «tempor-» temporale e temporaneo. È un altro motivo per imparare sempre la seconda forma.",
			},
		],
	},
	{
		"id": "latino-quarta-declinazione",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["declinazione-4"],
		"titolo": "Quarta declinazione · manus, exercitus, senatus",
		"come_si_legge": "Il gruppo più piccolo dopo la quinta, e il più insidioso: tre caselle diverse si scrivono tutte «manus». Leggi la tabella sapendo che qui la forma da sola non basta quasi mai — serve il resto della frase.",
		"voci": [
			{
				"label": "Nominativo singolare",
				"forma": "-us · manus, exercitus, senatus",
				"regola": "^(man|exercit|senat)us$",
				"risposte": ["nominativo singolare", "manus"],
				"nota": "Finisce in -us come la seconda declinazione, e qui nasce la confusione: «dominus» e «manus» sembrano lo stesso gruppo e non lo sono. A distinguerli è la casella dopo.",
			},
			{
				"label": "Genitivo singolare",
				"forma": "-us · manus (identico al nominativo)",
				"risposte": ["genitivo singolare", "Dal genitivo singolare in -us", "Perché nominativo e genitivo si scrivono uguali"],
				"nota": "Anche questa fa -us, e proprio questo è il marchio della quarta: la seconda declinazione qui farebbe -i (domini). Due caselle identiche nella stessa parola sono la difficoltà di questo gruppo, non un errore di stampa.",
			},
			{
				"label": "Dativo singolare",
				"forma": "-ui · manui, exercitui",
				"regola": "^(man|exercit|senat)ui$",
				"risposte": ["dativo singolare"],
				"nota": "La coda -ui non appartiene a nessun altro gruppo: quando la vedi sei certo di essere nella quarta declinazione, ed è l'unica casella che lo dice senza ambiguità.",
			},
			{
				"label": "Accusativo singolare",
				"forma": "-um · manum, exercitum",
				"regola": "^(man|exercit|senat)um$",
				"risposte": ["accusativo singolare"],
				"nota": "La solita coda -m di chi subisce, uguale a quella della seconda declinazione. È una delle poche caselle della quarta che non si confonde con un'altra della stessa parola.",
			},
			{
				"label": "Ablativo singolare",
				"forma": "-u · manu («con la mano»)",
				"regola": "^(man|exercit|senat)u$",
				"risposte": ["ablativo singolare"],
				"nota": "Una -u sola. «Manu» compare ancora in italiano dentro «manuale» e nelle espressioni giuridiche, ed è un buon modo per ricordarsela.",
			},
			{
				"label": "Nominativo e accusativo plurale",
				"forma": "-us · manus (di nuovo!)",
				"risposte": ["nominativo plurale", "accusativo plurale"],
				"nota": "La terza e la quarta casella che si scrivono «manus»: singolare che agisce, singolare che possiede, plurale che agisce e plurale che subisce. Quattro mestieri, una parola sola, e a scegliere è sempre la frase.",
			},
			{
				"label": "Genitivo plurale",
				"forma": "-uum · manuum, exercituum",
				"regola": "^(man|exercit|senat)uum$",
				"risposte": ["genitivo plurale"],
				"nota": "Due u di fila: è la forma più strana di tutto il latino a vedersi, e proprio per questo non si dimentica. Significa «delle mani», «degli eserciti».",
			},
			{
				"label": "Dativo e ablativo plurale",
				"forma": "-ibus · manibus, exercitibus",
				"regola": "^(man|exercit|senat)ibus$",
				"risposte": ["dativo plurale", "ablativo plurale"],
				"nota": "La stessa coda -ibus della terza declinazione. «Manibus» è la parola che si legge sulle tombe romane nella formula «Dis Manibus», e da lì è arrivata fino a noi.",
			},
			{
				"label": "Le parole della quarta",
				"forma": "manus, exercitus, senatus, domus",
				"risposte": ["Mano", "Esercito", "Senato"],
				"nota": "Poche parole, ma di quelle che tornano in ogni pagina: la mano, l'esercito, il senato, la casa. Da «manus» viene manuale, manovra e manutenzione; da «exercitus» viene esercitazione, perché l'esercito è ciò che si esercita.",
			},
			{
				"label": "Il genere della quarta",
				"forma": "quasi tutti maschili, tranne manus",
				"risposte": ["Maschile"],
				"nota": "Quasi tutte le parole di questo gruppo sono maschili — exercitus, senatus, portus — e le eccezioni femminili si contano sulle dita: manus, la mano, è la più importante e la più usata.",
			},
		],
	},
	{
		"id": "latino-quinta-declinazione",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["declinazione-5"],
		"titolo": "Quinta declinazione · res, dies",
		"come_si_legge": "Il gruppo più piccolo: poche parole, ma due di uso continuo — «res», la cosa, e «dies», il giorno. La radice è cortissima (r-, di-) e quasi tutto il lavoro lo fanno le code.",
		"voci": [
			{
				"label": "Nominativo singolare",
				"forma": "-es · res, dies",
				"regola": "^(r|di)es$",
				"risposte": ["nominativo singolare"],
				"nota": "La forma del vocabolario. «Res» vuol dire «cosa» in senso larghissimo — un fatto, un affare, una faccenda — e da lì viene l'italiano «reale», cioè che riguarda le cose vere.",
			},
			{
				"label": "Genitivo e dativo singolare",
				"forma": "-ei · rei, diei",
				"regola": "^(r|di)ei$",
				"risposte": ["genitivo singolare", "dativo singolare"],
				"nota": "La coda -ei è il marchio di questo gruppo e non appartiene a nessun altro: quando la vedi hai riconosciuto la quinta declinazione senza altre verifiche.",
			},
			{
				"label": "Accusativo singolare",
				"forma": "-em · rem, diem",
				"regola": "^(r|di)em$",
				"risposte": ["accusativo singolare"],
				"nota": "La solita coda -m di chi subisce. «Diem» è la parola che sta dentro «carpe diem», cogli il giorno: il giorno è ciò che viene colto, quindi subisce l'azione.",
			},
			{
				"label": "Ablativo singolare",
				"forma": "-e · re, die",
				"regola": "^(r|di)e$",
				"risposte": ["ablativo singolare"],
				"nota": "Una -e sola, come nella terza declinazione. «Re» in italiano è rimasta dentro parole giuridiche e dentro «meridiana», l'orologio a sole, da «medius dies», mezzogiorno.",
			},
			{
				"label": "Nominativo e accusativo plurale",
				"forma": "-es · res, dies (uguali al singolare)",
				"risposte": ["nominativo plurale", "accusativo plurale"],
				"nota": "Identiche al nominativo singolare: «res» può voler dire «la cosa» o «le cose», e a deciderlo è il verbo che l'accompagna. È la stessa ambiguità della quarta declinazione, in un gruppo diverso.",
			},
			{
				"label": "Genitivo plurale",
				"forma": "-erum · rerum, dierum",
				"regola": "^(r|di)erum$",
				"risposte": ["genitivo plurale"],
				"nota": "«Rerum» vuol dire «delle cose», e si legge ancora sui titoli dei libri antichi: «De rerum natura», sulla natura delle cose, è il poema di Lucrezio.",
			},
			{
				"label": "Dativo e ablativo plurale",
				"forma": "-ebus · rebus, diebus",
				"regola": "^(r|di)ebus$",
				"risposte": ["dativo plurale", "ablativo plurale"],
				"nota": "Somiglia al -ibus della terza e della quarta, con la e al posto della i: le tre declinazioni grandi condividono questa terminazione perché al plurale il latino ha smesso di distinguere «a» da «con».",
			},
			{
				"label": "Le due parole che contano",
				"forma": "res la cosa · dies il giorno",
				"risposte": ["La cosa", "Il giorno"],
				"nota": "«Res» è la parola più generica del latino — una cosa, un fatto, una faccenda — e proprio per questo entra in decine di espressioni. «Dies» è il giorno inteso come luce e come data.",
			},
			{
				"label": "Res publica",
				"forma": "«la cosa pubblica», cioè repubblica",
				"risposte": ["La cosa pubblica"],
				"nota": "La repubblica è alla lettera la cosa che appartiene a tutti e non a un padrone: i Romani la fondarono cacciando il re, e la parola italiana è quell'espressione latina saldata in una parola sola.",
			},
			{
				"label": "Le parole italiane da dies",
				"forma": "diario · meridiana · quotidiano",
				"risposte": ["Diario"],
				"nota": "Il diario è il quaderno dei giorni, il quotidiano è ciò che torna ogni giorno, e la meridiana viene da «medius dies», mezzogiorno: è l'orologio che segna il mezzo del giorno.",
			},
		],
	},
	{
		"id": "latino-il-verbo",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["verbi"],
		"titolo": "Il verbo: la coda dice CHI, il pezzetto in mezzo dice QUANDO",
		"come_si_legge": "Una parola sola porta tre informazioni: che azione è, chi la compie e quando succede. Si legge dalla fine: prima la coda, che dice chi; poi si guarda in mezzo, dove si trova il tempo. Per questo il latino non ha quasi bisogno dei pronomi.",
		"voci": [
			{
				"label": "Io",
				"forma": "-o · amo, moneo, rego, audio",
				"risposte": ["Io"],
				"nota": "La coda -o dice «io» in ogni verbo latino, ed è la forma con cui il vocabolario elenca il verbo: dove noi diciamo «amare», il latino dice «amo». All'imperfetto e al futuro diventa -m: amabam, «io amavo».",
			},
			{
				"label": "Tu",
				"forma": "-s · amas, mones, regis, audis",
				"risposte": ["Tu"],
				"nota": "La coda -s dice sempre «tu». È sopravvissuta in italiano: «tu ami», «tu leggi» — quella -i finale nostra è la stessa idea, un pezzetto che indica la persona a cui si parla.",
			},
			{
				"label": "Lui/lei",
				"forma": "-t · amat, monet, regit, audit",
				"risposte": ["Lui/lei", "Lui o lei", "Terza persona singolare"],
				"nota": "La coda -t dice «lui» o «lei», ed è la forma più frequente di tutte perché è quella con cui si racconta. Il latino non distingue il maschile dal femminile nel verbo: a dirlo è il soggetto, se c'è.",
			},
			{
				"label": "Noi",
				"forma": "-mus · amamus, monemus, regimus",
				"risposte": ["Noi"],
				"nota": "La coda -mus dice «noi», e si sente ancora nell'italiano «amiamo», «leggiamo»: quella -mo finale è il resto consumato di -mus, arrivato fino a oggi.",
			},
			{
				"label": "Voi",
				"forma": "-tis · amatis, monetis, regitis",
				"risposte": ["Voi"],
				"nota": "La coda -tis dice «voi». In italiano è diventata -te: «amate», «leggete». Fra tutte le code è quella che si riconosce meglio, perché nessun'altra ha due lettere così.",
			},
			{
				"label": "Loro",
				"forma": "-nt · amant, monent, regunt, audiunt",
				"risposte": ["Loro", "Più di una", "Più di uno"],
				"nota": "La coda -nt dice «loro», sempre e in ogni tempo. È la coda che risolve mezza traduzione: se il verbo finisce in -nt, chi agisce è più di uno, e allora anche il soggetto va cercato al plurale.",
			},
			{
				"label": "Adesso",
				"forma": "niente in mezzo · amat («ama»)",
				"risposte": ["Adesso"],
				"nota": "Nel presente la coda si attacca diretta alla radice, senza nessun pezzetto in mezzo. È il tempo da usare come termine di paragone: si guarda il presente e si vede che cosa è stato infilato dentro.",
			},
			{
				"label": "Nel passato",
				"forma": "-ba- in mezzo · amabat («amava»)",
				"risposte": ["Nel passato"],
				"nota": "Il pezzetto -ba- infilato prima della coda porta il passato, e l'italiano fa la stessa cosa nello stesso posto con -va-: amabat/amava, videbat/vedeva. È la parentela fra le due lingue vista a occhio nudo.",
			},
			{
				"label": "Nel futuro",
				"forma": "-bi- in mezzo · amabit («amerà»)",
				"risposte": ["Nel futuro"],
				"nota": "Alla prima e alla seconda coniugazione il futuro ha il pezzetto -bi- (o -bo, -bu-): amabit, monebit. Alla terza e alla quarta no: lì cambia solo la vocale prima della coda — reget, audiet — e bisogna guardare quella.",
			},
		],
	},
	{
		"id": "latino-verbo-sum",
		"subject": "latino",
		"kind": KIND_PARADIGMA,
		"topics": ["verbo-sum"],
		"titolo": "Il verbo essere · sum",
		"come_si_legge": "Questo è l'unico verbo che non segue nessuna regola, e va imparato a memoria come in italiano si impara «sono, sei, è». In cambio torna in quasi ogni frase latina che leggerai, quindi è memoria ben spesa.",
		"voci": [
			{
				"label": "Io sono",
				"forma": "sum",
				"risposte": ["Sum", "sum", "Io sono"],
				"nota": "È anche il nome del verbo: dove noi diciamo «essere», il latino dice «sum». La parola è così antica che se ne ritrovano parenti in greco, in sanscrito e in tedesco.",
			},
			{
				"label": "Tu sei",
				"forma": "es",
				"risposte": ["Es", "Tu sei"],
				"nota": "Due lettere sole. Da non confondere con «est», che ha una -t in più ed è la terza persona: quella -t è la stessa coda che segna «lui» in tutti i verbi latini.",
			},
			{
				"label": "Egli è",
				"forma": "est",
				"risposte": ["est", "Est", "(egli/ella) è", "Egli è"],
				"nota": "La forma più frequente del verbo più frequente. Si ritrova quasi identica in francese («est»), in spagnolo («es») e nell'inglese «is»: è una delle parole più stabili delle lingue europee.",
			},
			{
				"label": "Noi siamo",
				"forma": "sumus",
				"risposte": ["Sumus", "sumus", "Noi siamo"],
				"nota": "Qui torna la solita coda -mus del «noi»: anche il verbo più irregolare del latino conserva le code delle persone, perché quelle non si consumano mai del tutto.",
			},
			{
				"label": "Voi siete",
				"forma": "estis",
				"risposte": ["Estis", "estis", "Voi siete"],
				"nota": "La coda -tis del «voi» attaccata alla stessa radice di «est». È la forma che rende evidente la regola: cambia la radice, ma le code restano quelle di sempre.",
			},
			{
				"label": "Essi sono",
				"forma": "sunt",
				"risposte": ["Sunt", "sunt", "Essi sono", "(loro) sono"],
				"nota": "La coda -nt del plurale. «Sunt» è la parola che apre moltissime iscrizioni e formule latine, e la si riconosce a colpo d'occhio proprio per quella coda.",
			},
			{
				"label": "Io ero",
				"forma": "eram (imperfetto)",
				"risposte": ["eram", "Eram", "Io ero"],
				"nota": "All'imperfetto la radice cambia del tutto: da «su-» si passa a «er-». Succede perché dentro questo verbo si sono fusi due verbi antichi diversi, e ciascuno ha lasciato i suoi tempi.",
			},
			{
				"label": "Egli era",
				"forma": "erat",
				"risposte": ["Egli era", "erat"],
				"nota": "Attenzione: qui non c'è nessun -ba-, il segno normale dell'imperfetto latino. «Sum» è irregolare anche in questo, e «erat» va riconosciuto a memoria, non ricavato da una regola.",
			},
			{
				"label": "Essi erano",
				"forma": "erant",
				"risposte": ["erant", "Erant", "Essi erano"],
				"nota": "La stessa radice «er-» dell'imperfetto più la coda -nt del plurale: eram, eras, erat, eramus, eratis, erant. Le code sono sempre quelle, cambia solo ciò che sta davanti.",
			},
			{
				"label": "Egli sarà",
				"forma": "erit (futuro)",
				"risposte": ["Egli sarà", "erit"],
				"nota": "Il futuro tiene la radice «er-» dell'imperfetto e cambia solo la vocale: erat era, erit sarà. Una lettera separa il passato dal futuro, ed è l'errore più facile da fare traducendo di fretta.",
			},
			{
				"label": "Egli fu",
				"forma": "fuit (perfetto)",
				"risposte": ["Perfetto: «egli fu»", "fuit", "Egli fu"],
				"nota": "Al perfetto la radice cambia una terza volta, in «fu-»: fui, fuisti, fuit. È il resto di un altro verbo antichissimo che significava «crescere, diventare», e da lì viene l'italiano «fu».",
			},
			{
				"label": "L'infinito",
				"forma": "esse",
				"risposte": ["esse", "Esse"],
				"nota": "«Esse» è la forma che dà il nome al verbo, come il nostro «essere», e da lì vengono le parole italiane «essenza» ed «essenziale»: ciò che una cosa è davvero.",
			},
		],
	},
	{
		"id": "latino-le-parole",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["vocabolario"],
		"titolo": "Le parole che tornano più spesso",
		"come_si_legge": "A sinistra la parola latina, accanto il significato. Quasi tutte hanno lasciato una parente in italiano: impararle in coppia con quella parente costa la metà, perché si fissano in due punti invece che in uno.",
		"voci": [
			{"label": "aqua", "in_breve": "l'acqua", "risposte": ["Acqua"],
				"nota": "Da qui vengono acquedotto (che conduce l'acqua), acquario (il posto dell'acqua) e acquerello, il colore che si stende con l'acqua."},
			{"label": "terra", "in_breve": "la terra", "risposte": ["Terra"],
				"nota": "Uguale in italiano, e dentro decine di parole: territorio, terrestre, sotterraneo, atterrare. La radice è rimasta intatta perché la cosa che nomina non è mai cambiata."},
			{"label": "puella", "in_breve": "la bambina, la fanciulla", "risposte": ["Bambina", "ragazza", "la ragazza", "fanciulla"],
				"nota": "Il femminile di «puer», il bambino. In italiano non è arrivata, ma è arrivata la sua parente «puerile», che significa «da bambino»."},
			{"label": "liber", "in_breve": "il libro", "risposte": ["Libro", "libro", "il libro"],
				"nota": "In origine indicava la corteccia interna dell'albero, su cui si scriveva prima della carta. Da lì libro, libreria, libretto — e non c'entra niente con «libero», che è un'altra parola."},
			{"label": "pax", "in_breve": "la pace", "risposte": ["Pace"],
				"nota": "Da «pax, pacis» vengono pace, pacifico e pacificare. La «Pax Romana» era il lungo periodo senza guerre dentro i confini dell'impero, ed è una delle espressioni latine più citate."},
			{"label": "ignis", "in_breve": "il fuoco", "risposte": ["Fuoco"],
				"nota": "Non è arrivata in italiano come parola comune — noi diciamo «fuoco», da «focus», il focolare — ma è rimasta in «igneo» e «ignifugo», ciò che mette in fuga il fuoco."},
			{"label": "bellum", "in_breve": "la guerra", "risposte": ["Guerra"],
				"nota": "È il falso amico più famoso del latino: sembra «bello» e significa il contrario. Da qui vengono bellico e belligerante, mentre «bello» viene da «bellus», che è un'altra parola."},
			{"label": "urbs", "in_breve": "la città", "risposte": ["Città"],
				"nota": "«Urbs» con la maiuscola voleva dire Roma e basta: era LA città. Da qui vengono urbano, suburbano e urbanistica."},
			{"label": "via", "in_breve": "la strada", "risposte": ["Strada"],
				"nota": "Le strade romane portavano il nome al femminile perché «via» è femminile: via Appia, via Aurelia. La parola è arrivata intatta fino a noi, e con lei viadotto e deviare."},
			{"label": "rex", "in_breve": "il re", "risposte": ["Re"],
				"nota": "Da «rex, regis» vengono regale, regno e regia. La radice «reg-» significa «tenere dritto, guidare»: è la stessa di «regola» e di «rigido»."},
			{"label": "magister", "in_breve": "il maestro", "risposte": ["Maestro"],
				"nota": "Viene da «magis», «di più»: il maestro è chi ne sa di più. Il suo contrario è «minister», da «minus»: chi sta sotto e serve — ed è da lì che viene «ministro»."},
			{"label": "amicus", "in_breve": "l'amico", "risposte": ["Amico"],
				"nota": "Dalla stessa radice di «amo», amare: l'amico è, alla lettera, colui che si ama. Il contrario è «inimicus», il non-amico, da cui l'italiano «nemico»."},
			{"label": "silva", "in_breve": "il bosco, la selva", "risposte": ["Bosco, selva", "Bosco", "selva"],
				"nota": "È rimasta in «selva» e in «silvestre», ciò che appartiene al bosco. Anche il nome proprio Silvia viene da qui: significa «della selva»."},
			{"label": "tempus", "in_breve": "il tempo", "risposte": ["Tempo"],
				"nota": "Attenzione a non confonderlo con «templum», il tempio: si somigliano ma non sono parenti. Da «tempus» vengono temporale, temporaneo e contemporaneo."},
			{"label": "virtus", "in_breve": "il valore, il coraggio", "risposte": ["Valore, coraggio", "Valore", "coraggio"],
				"nota": "Viene da «vir», l'uomo: per i Romani la «virtus» era prima di tutto il coraggio in battaglia. Il senso morale di «virtù» che usiamo oggi è arrivato molto dopo, con il cristianesimo."},
			{"label": "mater", "in_breve": "la madre", "risposte": ["madre", "la madre", "Madre"],
				"nota": "Da «mater, matris» vengono materno, matrimonio, matrice e perfino «materia», che in origine era il legno del tronco: la parte da cui l'albero genera."},
			{"label": "pater", "in_breve": "il padre", "risposte": ["padre", "il padre", "Padre"],
				"nota": "Da qui paterno, patrono, patrimonio — ciò che si eredita dal padre — e «patria», che è la terra dei padri."},
			{"label": "nauta", "in_breve": "il marinaio", "risposte": ["marinaio", "il marinaio", "navigante"],
				"nota": "Finisce in -a come «rosa» ed è di prima declinazione, ma è maschile: come «agricola», il contadino, e «poeta». La coda non decide il genere, e queste parole servono a ricordarlo."},
			{"label": "schola", "in_breve": "il tempo libero, poi la lezione", "risposte": ["Tempo libero"],
				"nota": "Viene dal greco «scholé», che significava ozio, il tempo che non si passava a lavorare: studiare era ciò che si faceva quando si era liberi. Solo dopo la parola è arrivata a indicare la lezione e l'edificio."},
			{"label": "puer", "in_breve": "il bambino, il ragazzo", "risposte": ["Bambino", "ragazzo"],
				"nota": "Il maschile di «puella». Da qui «puerizia», l'età dei bambini, e «puericultura», la cura dei più piccoli."},
		],
	},
	{
		"id": "latino-le-radici",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["etimologia"],
		"titolo": "Le radici e i prefissi che tornano nell'italiano",
		"come_si_legge": "Una radice latina non produce una parola italiana: ne produce una famiglia. Riconosciuta la radice, il significato di una parola che non hai mai visto si intuisce — ed è una scorciatoia che vale per tutta la vita, non solo per un esercizio.",
		"voci": [
			{"label": "aqua", "in_breve": "acqua", "risposte": ["aqua"],
				"nota": "Acquedotto è «aqua» più «ducere», condurre: ciò che conduce l'acqua. Acquario è il posto dell'acqua, acquerello il colore che si stende con l'acqua."},
			{"label": "terra", "in_breve": "terra, suolo", "risposte": ["terra"],
				"nota": "Territorio, terrestre, atterrare, sotterraneo, interrare: cinque parole diverse, una radice sola. «Sotterraneo» è alla lettera «sotto terra»."},
			{"label": "videre", "in_breve": "vedere", "risposte": ["videre"],
				"nota": "Da qui visione, evidente (ciò che si vede senza spiegazioni), provvedere (vedere prima), e perfino televisione: «vedere lontano», con il greco «tele» davanti."},
			{"label": "manus", "in_breve": "mano", "risposte": ["manus", "manus, la mano"],
				"nota": "Manuale è ciò che si fa con la mano, manutenzione è tenerlo in mano, manoscritto è scritto a mano, manovra è «manu opera», lavoro di mano."},
			{"label": "scribere", "in_breve": "scrivere", "risposte": ["scribere"],
				"nota": "Scrittura, descrivere, iscrizione, manoscritto, scriba. In origine «scribere» voleva dire incidere con una punta: si scriveva graffiando, non tracciando."},
			{"label": "populus", "in_breve": "popolo", "risposte": ["populus"],
				"nota": "Popolare, popolazione, popoloso, e anche «pubblico», che viene dalla stessa famiglia: ciò che riguarda il popolo intero e non il singolo."},
			{"label": "caput", "in_breve": "testa", "risposte": ["caput"],
				"nota": "La capitale è la città a capo di uno Stato, il capitolo è la testa di una parte di libro, il capitano è chi sta in testa, e il capitale è la somma «di testa», quella principale."},
			{"label": "cor", "in_breve": "cuore", "risposte": ["cor"],
				"nota": "Cordiale è ciò che viene dal cuore, ricordare è riportare al cuore (per i Romani la memoria stava lì, non nella testa), e coraggio è la forza del cuore."},
			{"label": "vita", "in_breve": "vita", "risposte": ["vita"],
				"nota": "Vitale, vitamina, vitalità, e anche «vivace» e «convivere», dalla stessa famiglia di «vivere». La radice è la stessa che l'italiano ha ereditato senza cambiarla."},
			{"label": "cetera", "in_breve": "le altre cose", "risposte": ["cetera"],
				"nota": "L'abbreviazione «ecc.» sta per «et cetera», cioè «e le altre cose». Si scrive spesso anche «etc.», che è la stessa cosa lasciata in latino."},
			{"label": "trans-", "in_breve": "attraverso, oltre", "risposte": ["Attraverso, oltre", "Attraverso"],
				"nota": "Il transatlantico attraversa l'Atlantico, il trasparente si lascia attraversare dalla luce, trasferire è portare oltre, e il transito è il passaggio attraverso."},
			{"label": "sub-", "in_breve": "sotto", "risposte": ["Sotto"],
				"nota": "Il sottomarino sta sotto il mare, il subacqueo sotto l'acqua, il suburbano sotto (cioè attorno) alla città. Davanti a certe lettere diventa «suc-», «suf-», «sup-»: succedere, sufficiente, supporto."},
			{"label": "ante-", "in_breve": "prima", "risposte": ["Prima"],
				"nota": "L'anteprima è ciò che si vede prima di tutti, l'antenato è chi è nato prima, l'anticamera è la stanza in cui si aspetta prima di entrare."},
			{"label": "re-", "in_breve": "di nuovo, indietro", "risposte": ["Di nuovo, indietro", "Di nuovo"],
				"nota": "Rifare è fare di nuovo, ripetere è chiedere di nuovo, e ritornare è tornare indietro. È il prefisso più produttivo dell'italiano: si può attaccare a quasi ogni verbo e la parola nuova si capisce subito."},
		],
	},
	{
		"id": "latino-leggere-una-frase",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["frasi"],
		"titolo": "Come si legge una frase latina",
		"come_si_legge": "Non si legge da sinistra a destra come l'italiano: si cerca prima il verbo, poi chi lo compie, poi chi lo subisce. L'ordine delle parole in latino serve a dare enfasi, non a dire chi fa che cosa — a quello pensano le code.",
		"voci": [
			{
				"label": "Prima si cerca il verbo",
				"in_breve": "sta quasi sempre in fondo",
				"risposte": ["Perché sono i casi a dire chi fa che cosa"],
				"nota": "L'ordine tipico è soggetto, oggetto, verbo: «Puella rosam amat». Trovare il verbo per primo dà l'azione e, dalla sua coda, anche il numero di chi la compie — e da lì il resto si incastra."},
			{
				"label": "Poi chi compie l'azione",
				"in_breve": "la parola senza la coda -m",
				"risposte": ["Marcus"],
				"nota": "In «Marcus librum legit» è «Marcus»: non ha la coda di chi subisce, quindi è lui a leggere. Non conta che stia per primo — «librum Marcus legit» significherebbe esattamente la stessa cosa."},
			{
				"label": "Poi chi la subisce",
				"in_breve": "la parola con la coda -m",
				"risposte": ["Complemento oggetto"],
				"nota": "In «Marcus librum legit» è «librum», il libro che viene letto: si chiama complemento oggetto, ed è la parola su cui l'azione ricade. La -m finale è il segnale, al singolare."},
			{
				"label": "La coda -t del verbo",
				"in_breve": "chi agisce è uno solo",
				"risposte": ["Terza persona singolare", "est"],
				"nota": "Cantat, legit, amat, est: la -t finale dice «lui» o «lei» senza bisogno di nessun pronome davanti. È il primo controllo da fare, perché restringe subito chi può essere il soggetto."},
			{
				"label": "La coda -nt del verbo",
				"in_breve": "chi agisce è più di uno",
				"risposte": ["Più di una", "Più di uno"],
				"nota": "In «Puellae rosas amant» il verbo finisce in -nt, quindi le bambine sono più di una — e infatti «puellae» qui è nominativo plurale, non genitivo singolare. È il verbo a sciogliere l'ambiguità della parola."},
			{
				"label": "Una frase di due parole",
				"in_breve": "«Puella cantat»",
				"risposte": ["La bambina canta"],
				"nota": "Bastano due parole a fare una frase latina completa: chi agisce e l'azione. Non servono articoli, perché il latino non ne ha, e non serve il pronome, perché la coda del verbo lo dice già."},
			{
				"label": "L'ordine libero",
				"in_breve": "sposta l'enfasi, non il senso",
				"risposte": ["Perché il caso dice già la funzione di ogni parola"],
				"nota": "«Marcus librum legit» e «librum Marcus legit» dicono la stessa cosa: cambia solo che cosa si vuole mettere in risalto. In italiano invertire le parole cambierebbe chi fa l'azione, in latino no."},
		],
	},
	{
		"id": "latino-numeri-romani",
		"subject": "latino",
		"kind": KIND_SCHEDA,
		"topics": ["numeri"],
		"titolo": "I numeri romani",
		"come_si_legge": "Si legge da sinistra a destra sommando, con una sola eccezione: se un simbolo più piccolo sta PRIMA di uno più grande, invece di sommarlo lo si sottrae. IV è cinque meno uno, VI è cinque più uno.",
		"voci": [
			{"label": "I", "in_breve": "1", "risposte": ["1", "uno"],
				"nota": "Il segno più semplice, ed è nato da una tacca incisa su un bastone per contare. Ripetuto fa II e III, ma mai quattro volte di fila: da lì in poi si passa alla sottrazione."},
			{"label": "V", "in_breve": "5", "risposte": ["5", "cinque"],
				"nota": "Cinque come le dita di una mano aperta: si pensa che il segno sia proprio il disegno della mano, con il pollice da una parte e le altre quattro dita dall'altra."},
			{"label": "X", "in_breve": "10", "risposte": ["10", "dieci"],
				"nota": "Dieci come due mani, cioè due V una sopra l'altra. IX è dieci meno uno, XI è dieci più uno: la posizione del simbolo piccolo cambia tutto."},
			{"label": "L", "in_breve": "50", "risposte": ["50", "cinquanta"],
				"nota": "Cinquanta. XL è cinquanta meno dieci, cioè quaranta; LX è cinquanta più dieci, cioè sessanta. Si sottrae sempre un simbolo solo per volta, mai due."},
			{"label": "C", "in_breve": "100", "risposte": ["100", "cento"],
				"nota": "Cento, dall'iniziale di «centum» che vuol dire proprio cento. XC è novanta, CX è centodieci: la stessa regola di prima, un gradino più su."},
			{"label": "D", "in_breve": "500", "risposte": ["500", "cinquecento"],
				"nota": "Cinquecento. CD è quattrocento, DC è seicento. È il simbolo che si incontra meno di tutti, e per questo va guardato con attenzione."},
			{"label": "M", "in_breve": "1000", "risposte": ["1000", "mille"],
				"nota": "Mille, dall'iniziale di «mille». CM è novecento, MC è millecento. I secoli si scrivono così: il XX secolo è il ventesimo, dal 1901 al 2000."},
		],
	},
]

static func tutte() -> Array:
	return TAVOLE_STORIA + TAVOLE_GEOGRAFIA + TAVOLE_LATINO

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
	KIND_PARADIGMA: "Cerca la casella nella tabella prima di rispondere: guarda la coda della parola, non il suo posto nella frase.",
}

const APERTURA := {
	KIND_LINEA: "Questo sta sulla linea del tempo: guardiamola prima che te lo chieda.",
	KIND_CARTA: "Questo sta sulla carta: guardiamola prima che te lo chieda.",
	KIND_SCHEDA: "Questo sta sulla scheda: leggiamola prima che te lo chieda.",
	KIND_PARADIGMA: "Questo sta sulla tabella delle forme: guardiamola prima che te lo chieda, perché una forma non si indovina.",
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
