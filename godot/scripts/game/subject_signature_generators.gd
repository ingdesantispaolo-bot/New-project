class_name SubjectSignatureGenerators
extends RefCounted

## Famiglie procedurali delle cinque firme disciplinari. Ogni estrazione cambia
## dati didattici (componenti, durate, eventi, percorso o luoghi), non soltanto
## l'ordine dei pulsanti.

const HISTORY_CHAINS := [
	[["scrittura", "Nasce la scrittura", -3200], ["archivi", "Si conservano registri", -3000], ["leggi", "Le leggi vengono fissate", -1750]],
	[["polis", "Crescono le poleis", -800], ["colonie", "Si fondano colonie greche", -750], ["scambi", "Aumentano gli scambi mediterranei", -600]],
	[["crisi_roma", "Roma attraversa guerre civili", -49], ["augusto", "Augusto concentra il potere", -27], ["impero", "Inizia il principato", -27]],
	[["strade", "Roma costruisce una rete di strade", 100], ["commerci", "Le merci viaggiano piu' lontano", 150], ["citta", "Le citta' imperiali crescono", 180]],
	[["crisi", "L'Impero perde stabilita'", 250], ["divisione", "L'Impero viene diviso", 395], ["occidente", "Cade l'Impero d'Occidente", 476]],
	[["incursioni", "Aumentano le incursioni", 850], ["castelli", "Si fortificano i territori", 900], ["feudi", "Si consolida il sistema feudale", 1000]],
	[["raccolti", "Migliorano gli strumenti agricoli", 1050], ["eccedenze", "Crescono le eccedenze", 1100], ["mercati", "Rinascono fiere e mercati", 1150]],
	[["comuni", "Le citta' chiedono autonomia", 1100], ["statuti", "I comuni scrivono statuti", 1150], ["corporazioni", "Nascono molte corporazioni", 1200]],
	[["stampa", "Si diffonde la stampa", 1450], ["libri", "I libri costano meno", 1480], ["lettori", "Aumentano i lettori", 1520]],
	[["rotte", "Si cercano nuove rotte oceaniche", 1480], ["viaggio", "Colombo attraversa l'Atlantico", 1492], ["scambi_globali", "Gli scambi diventano globali", 1550]],
	[["vapore", "Si perfeziona la macchina a vapore", 1769], ["fabbriche", "Le fabbriche si meccanizzano", 1800], ["urbanizzazione", "Molti lavoratori si spostano in citta'", 1850]],
	[["illuminismo", "Si diffondono idee illuministe", 1750], ["diritti", "Si discutono nuovi diritti", 1780], ["rivoluzione", "Scoppia la Rivoluzione francese", 1789]],
	[["ferrovie", "Si estendono le ferrovie", 1840], ["trasporti", "I trasporti diventano piu' rapidi", 1870], ["mercato", "I mercati nazionali si collegano", 1900]],
	[["alleanze", "L'Europa si divide in alleanze", 1907], ["attentato", "Avviene l'attentato di Sarajevo", 1914], ["guerra", "Inizia la Prima guerra mondiale", 1914]],
	[["crisi29", "Crolla la borsa di New York", 1929], ["disoccupazione", "Aumenta la disoccupazione", 1930], ["tensioni", "Crescono le tensioni politiche", 1933]],
	[["carbone", "Aumenta l'uso del carbone", 1800], ["emissioni", "Crescono le emissioni industriali", 1900], ["riscaldamento", "Sale la temperatura media", 2000]],
	[["magna_carta", "Il re concede la Magna Carta", 1215], ["parlamento", "Il Parlamento limita nuovi tributi", 1295], ["monarchia_limitata", "Il potere regio incontra nuovi limiti", 1300]],
	[["caduta_costantinopoli", "Costantinopoli cade agli Ottomani", 1453], ["studiosi", "Studiosi greci raggiungono l'Italia", 1460], ["umanesimo", "Circolano nuovi testi classici", 1480]],
	[["riforma", "Lutero pubblica le novantacinque tesi", 1517], ["confessioni", "Si diffondono nuove confessioni", 1530], ["concilio", "Si apre il Concilio di Trento", 1545]],
	[["vaccino", "Jenner sperimenta il vaccino antivaioloso", 1796], ["vaccinazioni", "Le vaccinazioni si diffondono", 1850], ["vaiolo", "Il vaiolo viene eradicato", 1980]],
	[["telegrafo", "Il telegrafo collega citta' lontane", 1844], ["notizie", "Le notizie viaggiano piu' rapidamente", 1870], ["agenzie", "Crescono le agenzie di stampa", 1900]],
	[["suffragio", "Si organizzano movimenti per il voto", 1890], ["riforme_voto", "Molti Stati ampliano il suffragio", 1918], ["partecipazione", "Aumenta la partecipazione politica", 1950]],
	[["ceca", "Nasce la Comunita' del carbone e dell'acciaio", 1951], ["cee", "Sei Paesi fondano la CEE", 1957], ["ue", "Nasce l'Unione europea", 1993]],
	[["arpanet", "ARPANET collega i primi nodi", 1969], ["web", "Nasce il World Wide Web", 1989], ["rete_globale", "Internet diventa una rete globale", 2000]],
]

static func build(fmt: String, subject: String, level: int, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	match fmt:
		"breadboard": return _breadboard(subject, level, difficulty, rng, idx)
		"rhythm_fill": return _rhythm(subject, level, difficulty, rng, idx)
		"causal_chain": return _causal(subject, level, difficulty, rng, idx)
		"robot_grid": return _robot(subject, level, difficulty, rng, idx)
		"blank_map": return _blank_map(subject, level, difficulty, rng, idx)
	return {}

static func depth(fmt: String, subject: String) -> int:
	match fmt:
		"breadboard": return 16 if subject == "elettronica" else 0
		"rhythm_fill": return 96 if subject == "musica" else 0
		"causal_chain": return HISTORY_CHAINS.size() if subject == "storia" else 0
		"robot_grid": return 32 if subject == "coding" else 0
		"blank_map": return 168 if subject == "geografia" else 0
	return 0

static func _breadboard(subject: String, level: int, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var loads := [["led", "LED", "LED"], ["lamp", "Lampadina", "LAMP"], ["motor", "Motorino", "M"], ["buzzer", "Cicalino", "BZ"]]
	var controls := [["switch", "Interruttore chiuso", "I"], ["fuse", "Fusibile integro", "F"], ["resistor", "Resistore", "R"], ["diode", "Diodo nel verso giusto", "D"]]
	var variant := rng.randi_range(0, 15)
	var load: Array = loads[posmod(variant, loads.size())]
	var control: Array = controls[posmod(int(variant / loads.size()), controls.size())]
	return {
		"id": "signature-breadboard-%d-%d-%d" % [level, idx, rng.randi_range(0, 9999)], "subject": subject,
		"topic": "guasti" if level >= 20 else "circuito", "difficulty": difficulty, "format": "breadboard", "title": "Banco di prova",
		"prompt": "Monta un percorso chiuso che alimenti %s e includa %s. Ci sono due rami possibili." % [str(load[1]), str(control[1])],
		"componenti": [
			{"id": str(load[0]), "label": str(load[1]), "simbolo": str(load[2]), "tipo": "carico"},
			{"id": str(control[0]), "label": str(control[1]), "simbolo": str(control[2]), "tipo": "conduttore"},
			{"id": "wire", "label": "Ponticello", "simbolo": "-", "tipo": "conduttore"},
			{"id": "open", "label": "Interruttore aperto", "simbolo": "OPEN", "tipo": "aperto"},
		],
		"zoccoli": [
			{"id":"alto_1", "da":"+", "a":"A"}, {"id":"alto_2", "da":"A", "a":"-"},
			{"id":"basso_1", "da":"+", "a":"B"}, {"id":"basso_2", "da":"B", "a":"-"},
			{"id":"ponte", "da":"A", "a":"B"},
		],
		"obiettivo": {"da":"+", "a":"-", "deveIncludere":[str(load[0]), str(control[0])]},
		"soluzioni": [
			{"alto_1":str(control[0]), "alto_2":str(load[0])},
			{"basso_1":str(load[0]), "basso_2":str(control[0])},
		],
		"explanation": "Per alimentare %s la corrente deve andare dal polo positivo al negativo passando anche da %s, senza nodi aperti. In serie, scambiare l'ordine dei due componenti non apre la maglia." % [str(load[1]), str(control[1])],
	}

static func _rhythm(subject: String, level: int, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var meters := [4, 6, 8]
	var variant := rng.randi_range(0, 53)
	var meter: int = meters[posmod(variant, meters.size())]
	var fixed := 1 + posmod(int(variant / meters.size()), mini(3, meter - 1))
	var remaining := meter - fixed
	var solutions: Array = []
	if remaining >= 4: solutions = [["whole"] + _repeated("quarter", remaining - 4), ["half", "half"] + _repeated("quarter", remaining - 4)]
	elif remaining == 3: solutions = [["dotted"], ["half", "quarter"]]
	elif remaining == 2: solutions = [["half"], ["quarter", "quarter"]]
	else: solutions = [["quarter"], ["quarter_rest"]]
	var fixed_beats: Array = []
	var partition := posmod(int(variant / 9), 3)
	var instruments := ["tamburo", "campana", "marimba", "battito di mani"]
	var instrument := str(instruments[posmod(int(variant / 6), instruments.size())])
	if fixed == 1 and partition == 1: fixed_beats = [{"id":"fixed_rest","label":"pausa iniziale","simbolo":"P1","valore":1}]
	elif fixed == 3 and partition == 1: fixed_beats = [{"id":"fixed_a","label":"nota","simbolo":"1","valore":1},{"id":"fixed_b","label":"nota lunga","simbolo":"2","valore":2}]
	elif fixed == 3 and partition == 2: fixed_beats = [{"id":"fixed_a","label":"nota lunga","simbolo":"2","valore":2},{"id":"fixed_b","label":"nota","simbolo":"1","valore":1}]
	elif fixed == 2 and partition == 1: fixed_beats = [{"id":"fixed_a","label":"nota","simbolo":"1","valore":1},{"id":"fixed_b","label":"nota","simbolo":"1","valore":1}]
	else: fixed_beats = [{"id":"fixed","label":"suono iniziale","simbolo":str(fixed),"valore":fixed}]
	return {
		"id":"signature-rhythm-%d-%d-%d" % [level, idx, rng.randi_range(0, 9999)], "subject":subject,
		"topic":"intervalli" if level >= 18 else "ritmo", "difficulty":difficulty, "format":"rhythm_fill", "title":"Battuta da riempire",
		"prompt":"Completa la battuta di %s da %d pulsazioni. Sono gia' occupate %d pulsazioni: puoi trovare piu' di un riempimento." % [instrument, meter, fixed],
		"metro":meter, "metroLabel":"%d/4" % meter,
		"battuta":fixed_beats,
		"disponibili":[
			{"id":"quarter", "label":"1 pulsazione", "simbolo":"1", "valore":1},
			{"id":"quarter_rest", "label":"pausa di 1", "simbolo":"P1", "valore":1},
			{"id":"half", "label":"2 pulsazioni", "simbolo":"2", "valore":2},
			{"id":"dotted", "label":"3 pulsazioni", "simbolo":"3", "valore":3},
			{"id":"whole", "label":"4 pulsazioni", "simbolo":"4", "valore":4},
		], "soluzioni":solutions,
		"explanation":"Nella battuta di %s il metro vale %d pulsazioni e la parte scritta ne occupa %d: le durate aggiunte devono quindi sommare %d. Figure e pause diverse possono occupare lo stesso tempo totale." % [instrument, meter, fixed, remaining],
	}

static func _causal(subject: String, level: int, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var chain: Array = HISTORY_CHAINS[rng.randi_range(0, HISTORY_CHAINS.size() - 1)]
	var events: Array = []
	for event_data in chain:
		var event: Array = event_data
		events.append({"id":str(event[0]), "testo":str(event[1]), "anno":int(event[2])})
	var first := str((events[0] as Dictionary).get("id", ""))
	var second := str((events[1] as Dictionary).get("id", ""))
	var third := str((events[2] as Dictionary).get("id", ""))
	return {
		"id":"signature-cause-%d-%d-%d" % [level, idx, rng.randi_range(0, 9999)], "subject":subject,
		"topic":"cronologia", "difficulty":difficulty, "format":"causal_chain", "title":"Catena causale",
		"prompt":"Ricostruisci i due nessi sostenuti dalla cronologia. Una data puo' smascherare subito una freccia impossibile.",
		"eventi":events, "nessi":[{"da":first,"a":second},{"da":second,"a":third}],
		"nessiFalsi":[
			{"da":third,"a":first,"perche":"%s viene dopo %s: una conseguenza non puo' precedere la propria causa." % [str((events[2] as Dictionary).get("testo", "")), str((events[0] as Dictionary).get("testo", ""))]},
			{"da":first,"a":third,"perche":"Manca il passaggio intermedio: la fonte sostiene due nessi consecutivi, non un salto diretto."},
		],
		"explanation":"%s precede %s, che a sua volta precede %s. Le date fissano la direzione possibile; le fonti sostengono i due passaggi senza trasformare ogni successione in una causa." % [str((events[0] as Dictionary)["testo"]), str((events[1] as Dictionary)["testo"]), str((events[2] as Dictionary)["testo"])],
	}

static func _robot(subject: String, level: int, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var variant := rng.randi_range(0, 31)
	var first := 1 + posmod(variant, 2)
	var second := 1 + posmod(int(variant / 2), 2)
	var turn_right := posmod(int(variant / 4), 2) == 0
	var start_direction := posmod(int(variant / 8), 4)
	var direction := start_direction
	var program: Array = []
	for count in first: program.append("forward")
	program.append("right" if turn_right else "left")
	for count in second: program.append("forward")
	var directions := [Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
	var goal: Vector2i = Vector2i(3,3) + (directions[direction] as Vector2i) * first
	direction = posmod(direction + (1 if turn_right else -1), 4)
	goal += (directions[direction] as Vector2i) * second
	return {
		"id":"signature-robot-%d-%d-%d" % [level, idx, rng.randi_range(0, 9999)], "subject":subject,
		"topic":"algoritmi", "difficulty":difficulty, "format":"robot_grid", "title":"Robot nella griglia",
		"prompt":"Componi un programma e poi eseguilo: il robot deve raggiungere il faro. Conta il risultato prima del numero di passi.",
		"griglia":{"larghezza":7,"altezza":7,"ostacoli":[{"x":0,"y":0},{"x":6,"y":6},{"x":0,"y":6}]},
		"partenza":{"x":3,"y":3,"direzione":start_direction},
		"obiettivo":{"x":goal.x,"y":goal.y},
		"istruzioni":[{"id":"forward","label":"AVANTI","op":"forward"},{"id":"left","label":"GIRA A SINISTRA","op":"left"},{"id":"right","label":"GIRA A DESTRA","op":"right"}],
		"maxPassi":program.size() + 2, "soluzione":program,
		"explanation":"Da questa partenza servono %d passi avanti, una svolta a %s e altri %d passi avanti. Le rotazioni cambiano la direzione, AVANTI cambia la casella: arrivare e' il verdetto, farlo in meno passi e' una misura secondaria." % [first, "destra" if turn_right else "sinistra", second],
	}

static func _blank_map(subject: String, level: int, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var variant := rng.randi_range(0, 167)
	var map_id := "italy" if posmod(variant, 2) == 0 else "europe"
	var pool := ["po","sicily","sardinia","alps","apennines","tyrrhenian_sea","adriatic_sea","ionian_sea"] if map_id == "italy" else ["italy","france","spain","germany","poland","greece","united_kingdom","norway","sweden","finland","mediterranean"]
	var combinations: Array = []
	for a in range(pool.size() - 2):
		for b in range(a + 1, pool.size() - 1):
			for c in range(b + 1, pool.size()): combinations.append([pool[a], pool[b], pool[c]])
	var chosen: Array = combinations[posmod(int(variant / 2), combinations.size())].duplicate()
	_shuffle(chosen, rng)
	var labels: Array = []
	var anchors: Array = []
	for anchor_data in chosen:
		var anchor := str(anchor_data)
		labels.append({"id":"label_%s" % anchor, "testo":anchor.replace("_", " ").capitalize(), "ancora":anchor})
		anchors.append({"id":anchor, "label":"Punto %s" % str(anchors.size() + 1)})
	var route_mode := posmod(variant, 3) == 0
	return {
		"id":"signature-map-%d-%d-%d" % [level, idx, rng.randi_range(0, 9999)], "subject":subject,
		"topic":"geografia-fisica", "difficulty":difficulty, "format":"blank_map", "title":"Carta muta",
		"prompt":"%s" % ("Traccia una rotta che tocchi i tre luoghi nell'ordine indicato." if route_mode else "Posa ogni etichetta sulla sua ancora geografica."),
		"mapId":map_id, "etichette":labels, "ancore":anchors, "tolleranza":0.08,
		"modalita":"percorso" if route_mode else "etichette", "percorso":chosen if route_mode else [],
		"explanation":"Questa carta collega %s. Le etichette devono cadere vicino alle ancore reali; se si traccia una rotta, conta anche l'ordine dei tre luoghi attraversati." % ", ".join(PackedStringArray(chosen)),
	}

static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var temp = values[index]
		values[index] = values[other]
		values[other] = temp

static func _repeated(value: String, count: int) -> Array:
	var out: Array = []
	for index in count: out.append(value)
	return out
