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

const NUMERIC_ORDERING_SUBJECTS := ["matematica", "logica"]

func build_minigame(subject: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var has_match := MATCHING.has(subject)
	var has_order := ORDERING.has(subject)
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
