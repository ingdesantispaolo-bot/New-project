class_name MementoResonances
extends RefCounted

## Le ventiquattro risonanze autoriali dei Ricordi. Le due direzioni di ogni
## coppia condividono una grammatica visiva, ma compiono gesti opposti: il primo
## ciclo porta un metodo alla scala del secondo, il secondo lo riporta alle sue
## fondamenta. Sono letture facoltative, non esercizi e non ricompense.

const RESONANCES := {
	"accessory-scarf": {
		"source": 1, "target": 13, "pair": 1, "direction": 1,
		"motif": "groups_orbits", "action": "BATTI IL RAPPORTO",
		"prompt": "Dai alle tre pieghe della Sciarpa lo stesso ritmo delle tre orbite.",
		"line": "La Sciarpa ripete nel Deserto il ritmo imparato nella Radura: i gruppi uguali non sono scomparsi, sono diventati un rapporto fra orbite.",
		"trace": "Gruppi diventati orbite",
	},
	"memento-13-anello-rapporto": {
		"source": 13, "target": 1, "pair": 1, "direction": -1,
		"motif": "groups_orbits", "action": "RIDUCI L'ORBITA",
		"prompt": "Stringi le due orbite finché tornano due gruppi confrontabili.",
		"line": "L'Anello gira sopra le pietre della Radura: la proporzione del Deserto torna visibile come due gruppi che crescono insieme.",
		"trace": "Rapporto tornato gruppo",
	},
	"memento-02-foglia-sintassi": {
		"source": 2, "target": 14, "pair": 2, "direction": 1,
		"motif": "words_voices", "action": "APRI LE NERVATURE",
		"prompt": "Separa parola, funzione e voce lungo le tre nervature della Foglia.",
		"line": "Nell'Archivio la Foglia separava le parti della frase; fra le Voci mostra che la stessa struttura cambia senso quando cambia chi racconta.",
		"trace": "Sintassi con punto di vista",
	},
	"memento-14-conchiglia-legami": {
		"source": 14, "target": 2, "pair": 2, "direction": -1,
		"motif": "words_voices", "action": "DISTINGUI LE VOCI",
		"prompt": "Lascia parlare le voci una alla volta e trova che posto occupano nella frase.",
		"line": "La Conchiglia riporta le Voci nell'Archivio: prospettive diverse possono condividere le parole, ma soggetto e legami dicono chi sta parlando.",
		"trace": "Voci rimesse in frase",
	},
	"memento-03-gradino-ritorno": {
		"source": 3, "target": 15, "pair": 3, "direction": 1,
		"motif": "loops_networks", "action": "CHIUDI IL CICLO",
		"prompt": "Ripeti i tre gradini finché la sequenza diventa una funzione dell'automa.",
		"line": "Il Gradino porta nella Città il ciclo imparato al Cratere: una sequenza ripetuta diventa funzione, poi attraversa una rete senza perdere l'ordine.",
		"trace": "Ciclo diventato funzione",
	},
	"memento-15-nodo-quieto": {
		"source": 15, "target": 3, "pair": 3, "direction": -1,
		"motif": "loops_networks", "action": "RISALI IL GUASTO",
		"prompt": "Spegni tre diramazioni e conserva soltanto il passo che rompe la sequenza.",
		"line": "Il Nodo quieto riduce la rete della Città a un sentiero nel Cratere: fare debug significa tornare ai passi e trovare la prima decisione incoerente.",
		"trace": "Rete ridotta a sequenza",
	},
	"memento-04-boa-dei-tempi": {
		"source": 4, "target": 16, "pair": 4, "direction": 1,
		"motif": "signals_tenses", "action": "ACCORDA I TRE TEMPI",
		"prompt": "Fai lampeggiare prima, adesso e dopo oltre lo stesso valico.",
		"line": "La Boa porta alla Frontiera i segnali della Baia: prima, adesso e dopo diventano tempi verbali che permettono a un viaggio di essere raccontato.",
		"trace": "Segnale diventato racconto",
	},
	"memento-16-placca-varco": {
		"source": 16, "target": 4, "pair": 4, "direction": -1,
		"motif": "signals_tenses", "action": "RIDUCI IL RACCONTO",
		"prompt": "Ruota le finestre finché il racconto torna un messaggio breve e trasmissibile.",
		"line": "La Placca riporta alla Baia i tempi della Frontiera: anche un lungo viaggio deve tornare a chi c'era, che cosa aveva e quando è accaduto.",
		"trace": "Racconto tornato segnale",
	},
	"memento-05-giunto-misura": {
		"source": 5, "target": 17, "pair": 5, "direction": 1,
		"motif": "motion_pressure", "action": "DISTRIBUISCI LA SPINTA",
		"prompt": "Allarga il Giunto e osserva come la stessa forza cambia sulla superficie.",
		"line": "Il Giunto porta nell'Oceano la misura delle Officine: la spinta non cambia soltanto il moto, distribuita su un'area diventa pressione.",
		"trace": "Spinta distribuita in pressione",
	},
	"memento-17-ampolla-equilibrio": {
		"source": 17, "target": 5, "pair": 5, "direction": -1,
		"motif": "motion_pressure", "action": "RIPORTA LA PRESSIONE",
		"prompt": "Inclina le camere finché la pressione torna una spinta con direzione.",
		"line": "L'Ampolla riporta alle Officine l'equilibrio dell'Oceano: pressione e galleggiamento tornano forze, con verso, intensità e un punto in cui agire.",
		"trace": "Pressione tornata forza",
	},
	"memento-06-seme-risonante": {
		"source": 6, "target": 18, "pair": 6, "direction": 1,
		"motif": "rhythm_harmony", "action": "APRI L'ACCORDO",
		"prompt": "Lascia che il ritmo del Seme chiami due altezze e riempia la navata.",
		"line": "Il Seme porta nella Cattedrale il battito del Giardino: quando più note condividono ritmo, intensità e spazio, la risonanza diventa armonia.",
		"trace": "Ritmo aperto in armonia",
	},
	"memento-18-diapason-riverbero": {
		"source": 18, "target": 6, "pair": 6, "direction": -1,
		"motif": "rhythm_harmony", "action": "SEPARA IL RIVERBERO",
		"prompt": "Ferma l'eco e ascolta separatamente altezza, durata e intervallo.",
		"line": "Il Diapason riporta al Giardino il suono della Cattedrale: ogni armonia complessa può essere ascoltata di nuovo come altezza, durata e distanza fra note.",
		"trace": "Armonia separata in note",
	},
	"memento-07-tessera-indivisa": {
		"source": 7, "target": 19, "pair": 7, "direction": 1,
		"motif": "endings_roots", "action": "VOLTA LA TESSERA",
		"prompt": "Confronta il bordo che cambia funzione con l'incisione che resta comune.",
		"line": "Nelle Rovine il bordo della Tessera indicava la funzione; nella Necropoli l'incisione comune rivela la radice da cui forme diverse discendono.",
		"trace": "Desinenza ricondotta alla radice",
	},
	"memento-19-medaglione-radici": {
		"source": 19, "target": 7, "pair": 7, "direction": -1,
		"motif": "endings_roots", "action": "SEGUI LA RADICE",
		"prompt": "Porta la radice sotto l'Arco e guarda quale desinenza le dà una funzione.",
		"line": "Il Medaglione riporta le radici alle Rovine: conoscere l'origine non basta, perché è la desinenza a dire che cosa una parola sta facendo nella frase.",
		"trace": "Radice rimessa in funzione",
	},
	"memento-08-bobina-periodo": {
		"source": 8, "target": 20, "pair": 8, "direction": 1,
		"motif": "circuits_fields", "action": "RADDOPPIA IL PERCORSO",
		"prompt": "Apri una seconda via nella Bobina e confronta che cosa resta acceso.",
		"line": "La Bobina porta nella Tempesta il circuito chiuso del Delta: raddoppiare un percorso distingue serie e parallelo e rende diagnosticabile una rete instabile.",
		"trace": "Circuito aperto in rete",
	},
	"memento-20-fibbia-concordanza": {
		"source": 20, "target": 8, "pair": 8, "direction": -1,
		"motif": "circuits_fields", "action": "ISOLA LA SCARICA",
		"prompt": "Chiudi le due metà della Fibbia e riduci il campo a un solo percorso.",
		"line": "La Fibbia riporta al Delta la rete della Tempesta: isolati sensori e diramazioni, il guasto torna a essere un componente con una funzione precisa.",
		"trace": "Rete ricondotta al componente",
	},
	"memento-09-ago-cartografico": {
		"source": 9, "target": 21, "pair": 9, "direction": 1,
		"motif": "maps_systems", "action": "ALLARGA LA SCALA",
		"prompt": "Fissa l'origine con l'Ago e lascia che la carta mostri placche, climi e insediamenti.",
		"line": "L'Ago porta nell'Atlante le coordinate dell'Arcipelago: un punto diventa territorio quando scala, clima, rilievo e presenza umana vengono letti insieme.",
		"trace": "Coordinate aperte in sistema",
	},
	"memento-21-scheggia-scala": {
		"source": 21, "target": 9, "pair": 9, "direction": -1,
		"motif": "maps_systems", "action": "RICOMPONI LA CARTA",
		"prompt": "Sovrapponi le due scale e ritrova una rotta fra le isole.",
		"line": "La Scheggia riporta all'Arcipelago i sistemi dell'Atlante: dopo aver letto un territorio intero, servono ancora origine, scala e coordinate per attraversarlo.",
		"trace": "Sistema tornato rotta",
	},
	"memento-10-ampolla-accento": {
		"source": 10, "target": 22, "pair": 10, "direction": 1,
		"motif": "ecosystems_cells", "action": "INGRANDISCI IL CAMPIONE",
		"prompt": "Segui un granello di polline dalla Serra fino alla membrana di una cellula.",
		"line": "L'Ampolla porta nella Biosfera l'osservazione della Serra: una relazione fra viventi continua dentro la cellula, nei flussi di energia e negli adattamenti.",
		"trace": "Ecosistema visto nella cellula",
	},
	"memento-22-capsula-periodo": {
		"source": 22, "target": 10, "pair": 10, "direction": -1,
		"motif": "ecosystems_cells", "action": "TORNA ALL'ECOSISTEMA",
		"prompt": "Apri la Capsula e segui energia e materia fino alla cupola vivente.",
		"line": "La Capsula riporta alla Serra la vita profonda: cellule e adattamenti non vivono da soli, tornano catene, ambienti e relazioni da osservare cambiando una cosa per volta.",
		"trace": "Cellula restituita all'ecosistema",
	},
	"memento-11-sabbia-ordine": {
		"source": 11, "target": 23, "pair": 11, "direction": 1,
		"motif": "chronology_causes", "action": "LEGA CAUSA ED EPOCA",
		"prompt": "Lascia cadere ogni strato dopo la fonte che permette di interpretarlo.",
		"line": "La Sabbia porta nella Sala l'ordine della Soglia: una cronologia diventa storia quando fonti, cause e conseguenze spiegano perché un'epoca cambia.",
		"trace": "Cronologia diventata spiegazione",
	},
	"memento-23-quadrante-ere": {
		"source": 23, "target": 11, "pair": 11, "direction": -1,
		"motif": "chronology_causes", "action": "SEPARA LE FONTI",
		"prompt": "Ferma le quattro lancette e assegna a ogni epoca la traccia che la sostiene.",
		"line": "Il Quadrante riporta alla Soglia il racconto delle Ere: prima delle grandi cause vengono le tracce, da ordinare e distinguere in materiali, scritte e orali.",
		"trace": "Spiegazione restituita alle fonti",
	},
	"memento-12-chiave-regola": {
		"source": 12, "target": 24, "pair": 12, "direction": 1,
		"motif": "rules_synthesis", "action": "TRASFERISCI LA REGOLA",
		"prompt": "Prova la stessa configurazione su tre sistemi diversi del Cuore.",
		"line": "La Chiave porta nel Cuore la deduzione del Labirinto: una regola è davvero compresa quando può attraversare un altro sistema senza diventare una scorciatoia.",
		"trace": "Regola trasferita fra sistemi",
	},
	"memento-24-prisma-sintesi": {
		"source": 24, "target": 12, "pair": 12, "direction": -1,
		"motif": "rules_synthesis", "action": "SEPARA LA SINTESI",
		"prompt": "Dividi la luce del Prisma e ritrova le regole che la tengono insieme.",
		"line": "Il Prisma riporta al Labirinto la luce del Cuore: una sintesi non cancella i metodi che contiene, li rende separabili e nuovamente verificabili.",
		"trace": "Sintesi separata in regole",
	},
}

static func resonance(item_id: String) -> Dictionary:
	return Dictionary(RESONANCES.get(item_id, {})).duplicate(true)

static func ids() -> Array:
	return RESONANCES.keys().duplicate()

static func pair_members(pair_id: int) -> Array:
	var out: Array = []
	for item_id in RESONANCES:
		if int(Dictionary(RESONANCES[item_id]).get("pair", 0)) == pair_id:
			out.append(str(item_id))
	return out
