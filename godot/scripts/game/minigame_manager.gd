class_name MinigameManager
extends RefCounted

## Costruisce sessioni-MINIGIOCO risolte con le competenze delle materie. Due
## formati interattivi (resi da ExercisePlayer): "matching" (abbina le coppie) e
## "ordering" (metti in ordine). Riusa il contratto di sessione di ContentManager
## (nodi con topic/difficoltà) così mastery per-topic, energia e adattività
## restano identici. I contenuti sono curati per correttezza; l'ordinamento
## numerico è generato e tarato sul livello.

# Coppie da abbinare, per materia → gruppi tematici (topic + lista [sinistra, destra]).
const MATCHING := {
	"inglese": [
		{"topic": "vocabolario", "pairs": [["dog", "cane"], ["cat", "gatto"], ["sun", "sole"], ["house", "casa"], ["water", "acqua"], ["book", "libro"], ["tree", "albero"], ["red", "rosso"]]},
		{"topic": "vocabolario", "pairs": [["one", "uno"], ["two", "due"], ["three", "tre"], ["four", "quattro"], ["five", "cinque"], ["ten", "dieci"]]},
	],
	"geografia": [
		{"topic": "capitali", "pairs": [["Italia", "Roma"], ["Francia", "Parigi"], ["Spagna", "Madrid"], ["Germania", "Berlino"], ["Portogallo", "Lisbona"], ["Grecia", "Atene"]]},
		{"topic": "continenti", "pairs": [["Egitto", "Africa"], ["Brasile", "America del Sud"], ["Giappone", "Asia"], ["Italia", "Europa"], ["Australia", "Oceania"]]},
	],
	"scienze": [
		{"topic": "corpo", "pairs": [["Cuore", "Pompa il sangue"], ["Polmoni", "Respirazione"], ["Cervello", "Comanda il corpo"], ["Stomaco", "Digestione"], ["Occhi", "Vista"]]},
		{"topic": "viventi", "pairs": [["Erbivoro", "Mangia piante"], ["Carnivoro", "Mangia animali"], ["Onnivoro", "Mangia tutto"], ["Decompositore", "Ricicla i resti"]]},
	],
	"latino": [
		{"topic": "casi", "pairs": [["Nominativo", "Soggetto"], ["Accusativo", "Oggetto"], ["Genitivo", "Specificazione"], ["Dativo", "Termine"], ["Vocativo", "Invocazione"]]},
		{"topic": "vocabolario", "pairs": [["aqua", "acqua"], ["silva", "bosco"], ["puella", "fanciulla"], ["lupus", "lupo"], ["terra", "terra"]]},
	],
	"musica": [
		{"topic": "ritmo", "pairs": [["Semibreve", "4 battiti"], ["Minima", "2 battiti"], ["Semiminima", "1 battito"], ["Croma", "mezzo battito"]]},
		{"topic": "strumenti", "pairs": [["Chitarra", "Corde"], ["Flauto", "Fiato"], ["Tamburo", "Percussione"], ["Pianoforte", "Tastiera"]]},
	],
	"italiano": [
		{"topic": "contrari", "pairs": [["alto", "basso"], ["grande", "piccolo"], ["giorno", "notte"], ["caldo", "freddo"], ["veloce", "lento"]]},
		{"topic": "categorie", "pairs": [["correre", "verbo"], ["gatto", "nome"], ["rosso", "aggettivo"], ["velocemente", "avverbio"]]},
	],
	"cittadinanza": [
		{"topic": "istituzioni", "pairs": [["Sindaco", "Comune"], ["Parlamento", "Fa le leggi"], ["Costituzione", "Legge fondamentale"], ["Voto", "Scelta dei rappresentanti"]]},
		{"topic": "diritti-doveri", "pairs": [["Studiare", "Diritto e dovere"], ["Curarsi", "Diritto"], ["Rispettare l'ambiente", "Dovere"]]},
	],
	"coding": [
		{"topic": "tipi", "pairs": [["7", "intero"], ["'ciao'", "stringa"], ["True", "booleano"], ["[1, 2, 3]", "lista"]]},
		{"topic": "operatori", "pairs": [["+", "somma"], ["*", "moltiplicazione"], ["%", "resto"], ["**", "potenza"]]},
	],
	"elettronica": [
		{"topic": "componenti", "pairs": [["Pila", "Fornisce energia"], ["Interruttore", "Apre e chiude"], ["Resistore", "Limita la corrente"], ["LED", "Emette luce"]]},
		{"topic": "misure-elettriche", "pairs": [["Tensione", "Volt"], ["Corrente", "Ampere"], ["Resistenza", "Ohm"]]},
	],
	"fisica": [
		{"topic": "misure", "pairs": [["Lunghezza", "Metro"], ["Massa", "Chilogrammo"], ["Tempo", "Secondo"], ["Temperatura", "Grado"]]},
		{"topic": "energia", "pairs": [["Palla in alto", "Energia potenziale"], ["Palla che cade", "Energia cinetica"], ["Cibo", "Energia chimica"], ["Lampadina accesa", "Energia luminosa"]]},
	],
	"matematica": [
		{"topic": "tabelline", "pairs": [["3 × 4", "12"], ["6 × 7", "42"], ["8 × 5", "40"], ["9 × 3", "27"]]},
	],
}

# Sequenze da ordinare, per materia (l'ordine dato è quello CORRETTO).
const ORDERING := {
	"scienze": [
		{"topic": "viventi", "prompt": "Metti in ordine le fasi della farfalla", "correctOrder": ["Uovo", "Bruco", "Crisalide", "Farfalla"]},
		{"topic": "materia", "prompt": "Ordina per temperatura crescente", "correctOrder": ["Ghiaccio", "Acqua fredda", "Acqua calda", "Vapore"]},
	],
	"geografia": [
		{"topic": "geografia-umana", "prompt": "Ordina dal più piccolo al più grande", "correctOrder": ["Paese", "Regione", "Nazione", "Continente"]},
	],
	"musica": [
		{"topic": "note", "prompt": "Metti in ordine le note dopo il Do", "correctOrder": ["Re", "Mi", "Fa", "Sol"]},
		{"topic": "ritmo", "prompt": "Ordina dalla durata più breve alla più lunga", "correctOrder": ["Croma", "Semiminima", "Minima", "Semibreve"]},
	],
	"italiano": [
		{"topic": "ortografia", "prompt": "Metti in ordine alfabetico", "correctOrder": ["albero", "casa", "fiore", "sole"]},
	],
}

# Smistamento in categorie (drag-to-sort), per materia. Ogni item ha UNA categoria
# corretta (`assignments`); il renderer classification li fa trascinare nei bidoni.
# Formato testuale ad alto coinvolgimento, senza asset (playthrough #11).
const CLASSIFICATION := {
	"italiano": [
		{"topic": "categorie", "prompt": "Smista ogni parola nella sua classe grammaticale.",
			"categories": ["nome", "verbo", "aggettivo", "avverbio"],
			"assignments": {"gatto": "nome", "casa": "nome", "correre": "verbo", "saltare": "verbo", "rosso": "aggettivo", "felice": "aggettivo", "velocemente": "avverbio", "lentamente": "avverbio"}},
	],
	"scienze": [
		{"topic": "viventi", "prompt": "Smista ogni animale per come si nutre.",
			"categories": ["erbivoro", "carnivoro", "onnivoro"],
			"assignments": {"Mucca": "erbivoro", "Coniglio": "erbivoro", "Leone": "carnivoro", "Lupo": "carnivoro", "Orso": "onnivoro", "Maiale": "onnivoro"}},
	],
	"coding": [
		{"topic": "tipi", "prompt": "Smista ogni valore nel suo tipo di dato.",
			"categories": ["intero", "stringa", "booleano", "lista"],
			"assignments": {"7": "intero", "42": "intero", "'ciao'": "stringa", "'sole'": "stringa", "True": "booleano", "False": "booleano", "[1, 2]": "lista", "[3, 4, 5]": "lista"}},
	],
	"cittadinanza": [
		{"topic": "diritti-doveri", "prompt": "Smista ciascuna azione: diritto o dovere?",
			"categories": ["diritto", "dovere"],
			"assignments": {"Curarsi": "diritto", "Esprimere la propria opinione": "diritto", "Essere istruiti": "diritto", "Pagare le tasse": "dovere", "Rispettare l'ambiente": "dovere", "Rispettare le regole": "dovere"}},
	],
	"geografia": [
		{"topic": "continenti", "prompt": "Smista ogni Paese nel suo continente.",
			"categories": ["Africa", "Europa", "Asia", "America"],
			"assignments": {"Egitto": "Africa", "Kenya": "Africa", "Italia": "Europa", "Francia": "Europa", "Giappone": "Asia", "Cina": "Asia", "Brasile": "America", "Canada": "America"}},
	],
	"matematica": [
		{"topic": "numeri", "prompt": "Smista i numeri in pari e dispari.",
			"categories": ["pari", "dispari"],
			"assignments": {"4": "pari", "8": "pari", "12": "pari", "7": "dispari", "15": "dispari", "21": "dispari"}},
	],
	"fisica": [
		{"topic": "energia", "prompt": "Smista ogni situazione per l'energia prevalente.",
			"categories": ["potenziale", "cinetica"],
			"assignments": {"Palla in cima a una rampa": "potenziale", "Molla compressa": "potenziale", "Palla che rotola": "cinetica", "Auto in corsa": "cinetica"}},
	],
	"musica": [
		{"topic": "strumenti", "prompt": "Smista ogni strumento nella sua famiglia.",
			"categories": ["corde", "fiati", "percussioni"],
			"assignments": {"Chitarra": "corde", "Violino": "corde", "Flauto": "fiati", "Tromba": "fiati", "Tamburo": "percussioni", "Timpani": "percussioni"}},
	],
	"elettronica": [
		{"topic": "conduttori", "prompt": "Smista ogni materiale.",
			"categories": ["conduttore", "isolante"],
			"assignments": {"Rame": "conduttore", "Ferro": "conduttore", "Alluminio": "conduttore", "Plastica": "isolante", "Legno": "isolante", "Gomma": "isolante"}},
	],
	"inglese": [
		{"topic": "categorie", "prompt": "Sort each word into its category.",
			"categories": ["animals", "food", "colours", "actions"],
			"assignments": {"dog": "animals", "cat": "animals", "apple": "food", "bread": "food", "red": "colours", "blue": "colours", "run": "actions", "jump": "actions"}},
	],
}

# Lettura di GRAFICO (assi + curva disegnati proceduralmente): scegli il punto
# richiesto. Nessun asset immagine. `points` in coordinate normalizzate 0..1.
const GRAPH := {
	"fisica": [
		{"topic": "moto", "xLabel": "tempo", "yLabel": "velocità", "answer": "C",
			"prompt": "Il grafico mostra la velocità nel tempo: in quale punto è massima?",
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.50, "label": "D"}],
			"explanation": "La velocità è massima dove la curva è più in alto: il punto C."},
	],
	"matematica": [
		{"topic": "coordinate", "xLabel": "x", "yLabel": "y", "answer": "Q",
			"prompt": "Quale punto si trova più in alto (ordinata y maggiore)?",
			"points": [{"id": "P", "x": 0.20, "y": 0.35, "label": "P"}, {"id": "Q", "x": 0.50, "y": 0.85, "label": "Q"}, {"id": "R", "x": 0.80, "y": 0.55, "label": "R"}],
			"explanation": "Il punto Q ha l'ordinata (y) più grande."},
	],
	"scienze": [
		{"topic": "metodo", "xLabel": "giorni", "yLabel": "altezza", "answer": "D",
			"prompt": "La pianta cresce nel tempo: in quale punto è più alta?",
			"points": [{"id": "A", "x": 0.10, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.70, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.95, "label": "D"}],
			"explanation": "La curva sale sempre: l'ultimo punto D è il più alto."},
	],
}

# CIRCUITO (schema + collegamenti disegnati proceduralmente): scegli il componente
# richiesto. `components` in coordinate 0..1, `connections` come coppie di id.
const CIRCUIT := {
	"elettronica": [
		{"topic": "circuito", "answer": "interruttore",
			"prompt": "Quale componente apre e chiude il passaggio della corrente?",
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.50, "y": 0.22, "label": "Interruttore"}, {"id": "resistore", "x": 0.80, "y": 0.50, "label": "Resistore"}, {"id": "led", "x": 0.50, "y": 0.78, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "resistore"], ["resistore", "led"], ["led", "pila"]],
			"explanation": "L'interruttore apre e chiude il circuito: accende o spegne il LED."},
		{"topic": "componenti", "answer": "led",
			"prompt": "Quale componente emette luce quando la corrente lo attraversa?",
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "resistore", "x": 0.50, "y": 0.24, "label": "Resistore"}, {"id": "led", "x": 0.80, "y": 0.50, "label": "LED"}, {"id": "filo", "x": 0.50, "y": 0.78, "label": "Filo"}],
			"connections": [["pila", "resistore"], ["resistore", "led"], ["led", "filo"], ["filo", "pila"]],
			"explanation": "Il LED emette luce quando è attraversato dalla corrente."},
	],
}

# CODE-DEBUG (righe numerate selezionabili): trova la riga con l'errore. Testo puro.
const CODE_DEBUG := {
	"coding": [
		{"topic": "cicli", "answerLine": 2,
			"prompt": "Dovrebbe stampare 1, 2, 3. Quale riga contiene l'errore?",
			"codeLines": ["for i in [1, 2, 3]:", "    print(i + 1)", "# atteso: 1, 2, 3"],
			"explanation": "La riga 2 stampa i+1 (2, 3, 4): va corretta in print(i)."},
		{"topic": "condizioni", "answerLine": 1,
			"prompt": "Vogliamo salutare solo se il nome NON è vuoto. Quale riga sbaglia?",
			"codeLines": ["if nome == \"\":", "    print('Ciao ' + nome)", "# salutare solo se c'è un nome"],
			"explanation": "La riga 1 controlla se il nome È vuoto: la condizione va invertita (nome != '')."},
	],
	"logica": [
		{"topic": "deduzioni", "answerLine": 3,
			"prompt": "Segui la deduzione: quale passo è sbagliato?",
			"codeLines": ["Tutti i gatti sono felini.", "Alcuni felini sono neri.", "Quindi tutti i gatti sono neri.", "# dove si rompe il ragionamento?"],
			"explanation": "La riga 3 generalizza indebitamente: da 'alcuni felini neri' non segue 'tutti i gatti neri'."},
	],
}

const NUMERIC_ORDERING_SUBJECTS := ["matematica", "logica"]

func build_minigame(subject: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var has_match := MATCHING.has(subject)
	var has_order := ORDERING.has(subject)
	var has_classify := CLASSIFICATION.has(subject)
	var numeric := NUMERIC_ORDERING_SUBJECTS.has(subject)
	var nodes: Array = []
	# Primo nodo: preferisci un abbinamento (più ricco); ripiega su ordinamento.
	if has_match:
		nodes.append(_matching_node(subject, _pick(MATCHING[subject], generator), level, generator, 0))
	elif numeric:
		nodes.append(_numeric_ordering_node(subject, level, generator, 0))
	elif has_order:
		nodes.append(_ordering_node(subject, _pick(ORDERING[subject], generator), level, generator, 0))
	# Secondo nodo: preferisci un formato DIVERSO per varietà.
	if numeric:
		nodes.append(_numeric_ordering_node(subject, level, generator, 1))
	elif has_order:
		nodes.append(_ordering_node(subject, _pick(ORDERING[subject], generator), level, generator, 1))
	elif has_match:
		nodes.append(_matching_node(subject, _pick(MATCHING[subject], generator), level, generator, 1))
	# Terzo nodo (se disponibile): smistamento drag-to-sort — il formato più
	# distante da abbinamento/ordinamento, per esercizi davvero vari (#11).
	if has_classify:
		nodes.append(_classification_node(subject, _pick(CLASSIFICATION[subject], generator), level, generator, 2))
	# Quarto nodo (formato SPECIALISTA): grafico/circuito/code-debug se la materia
	# ne ha — leggere dati, schemi o codice: la competenza come sfida visuale.
	if GRAPH.has(subject):
		nodes.append(_graph_node(subject, _pick(GRAPH[subject], generator), level, generator, 3))
	elif CIRCUIT.has(subject):
		nodes.append(_circuit_node(subject, _pick(CIRCUIT[subject], generator), level, generator, 3))
	elif CODE_DEBUG.has(subject):
		nodes.append(_code_debug_node(subject, _pick(CODE_DEBUG[subject], generator), level, generator, 3))
	if nodes.is_empty():
		# Fallback generico: un abbinamento numerico sempre valido.
		nodes.append(_numeric_ordering_node(subject, level, generator, 0))
	return {
		"sessionId": "minigame-%s-lvl%d" % [subject, level],
		"kind": "minigame",
		"subject": subject,
		"level": level,
		"nodes": nodes,
		"shields": 3,
		"pace": ContentManager.subject_pace(subject),
		"timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 30, "fragments": 2}},
	}

func _pick(list: Array, rng: RandomNumberGenerator) -> Dictionary:
	return list[rng.randi_range(0, list.size() - 1)]

func _matching_node(subject: String, group: Dictionary, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var all: Array = (group["pairs"] as Array).duplicate()
	_shuffle(all, rng)
	var take := clampi(3 + int(level / 8.0), 3, mini(5, all.size()))
	var pairs: Array = []
	for i in take:
		var p: Array = all[i]
		pairs.append({"left": str(p[0]), "right": str(p[1])})
	return {
		"id": "minigame-match-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(group["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "matching",
		"prompt": "Abbina ogni elemento alla sua coppia.",
		"pairs": pairs,
		"explanation": "Collega ogni elemento a sinistra con quello giusto a destra.",
	}

func _classification_node(subject: String, spec: Dictionary, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var assignments: Dictionary = spec["assignments"]
	var items: Array = assignments.keys()
	_shuffle(items, rng)
	return {
		"id": "minigame-classify-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "classification",
		"prompt": str(spec["prompt"]),
		"items": items,
		"categories": Array(spec["categories"]).duplicate(),
		"assignments": assignments.duplicate(true),
		"explanation": "Ogni tessera va nel gruppo giusto secondo la sua proprietà.",
	}

func _graph_node(subject: String, spec: Dictionary, level: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-graph-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "graph",
		"prompt": str(spec["prompt"]),
		"points": (spec["points"] as Array).duplicate(true),
		"xLabel": str(spec.get("xLabel", "x")),
		"yLabel": str(spec.get("yLabel", "y")),
		"answer": str(spec["answer"]),
		"explanation": str(spec["explanation"]),
	}

func _circuit_node(subject: String, spec: Dictionary, level: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-circuit-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "circuit",
		"prompt": str(spec["prompt"]),
		"components": (spec["components"] as Array).duplicate(true),
		"connections": (spec["connections"] as Array).duplicate(true),
		"answer": str(spec["answer"]),
		"explanation": str(spec["explanation"]),
	}

func _code_debug_node(subject: String, spec: Dictionary, level: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-code-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "code_debug",
		"prompt": str(spec["prompt"]),
		"codeLines": (spec["codeLines"] as Array).duplicate(),
		"answerLine": int(spec["answerLine"]),
		"answer": str(spec["answerLine"]),
		"explanation": str(spec["explanation"]),
	}

func _ordering_node(subject: String, spec: Dictionary, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var correct: Array = (spec["correctOrder"] as Array).duplicate()
	var items := correct.duplicate()
	_shuffle(items, rng)
	return {
		"id": "minigame-order-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "ordering",
		"prompt": str(spec["prompt"]),
		"items": items,
		"correctOrder": correct,
		"explanation": "Ordine giusto: %s." % ", ".join(PackedStringArray(correct)),
	}

func _numeric_ordering_node(subject: String, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var count := clampi(3 + int(level / 6.0), 3, 5)
	var span := 5 + level * 2
	var values: Array = []
	while values.size() < count:
		var v := rng.randi_range(1, span)
		if not values.has(v):
			values.append(v)
	var ascending := rng.randf() < 0.5
	var ordered := values.duplicate()
	ordered.sort()
	if not ascending:
		ordered.reverse()
	var correct: Array = []
	for v in ordered:
		correct.append(str(v))
	var items := correct.duplicate()
	_shuffle(items, rng)
	return {
		"id": "minigame-numorder-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": "sequenze",
		"difficulty": ContentManager.target_difficulty(level),
		"format": "ordering",
		"prompt": "Metti i numeri in ordine %s." % ("crescente" if ascending else "decrescente"),
		"items": items,
		"correctOrder": correct,
		"explanation": "Ordine giusto: %s." % ", ".join(PackedStringArray(correct)),
	}

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = values[i]
		values[i] = values[j]
		values[j] = tmp
