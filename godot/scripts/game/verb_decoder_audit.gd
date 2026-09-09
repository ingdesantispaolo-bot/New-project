extends SceneTree

## Vertical slice del Messaggio fuori tempo: progressione dai tempi
## dell'indicativo ai modi indefiniti e al periodo ipotetico, contratto valido e
## tre ghiere realmente giocabili nel renderer.
##
## **Due materie dal 9 settembre 2026.** Le tre ghiere sono la coniugazione di
## qualunque lingua, e in inglese erano il gesto mancante: la grammatica del
## banco si poteva solo crocettare. Il contratto e' lo stesso, quindi lo stesso
## audit vale per entrambe — e il `tier` di ogni caso, che e' la fascia 1..8,
## deve arrivare davvero fino in fondo alla scala.

## `fascia_max` e' la fascia piu' alta che i casi di quella materia raggiungono
## oggi, ed e' un cricchetto: puo' salire, non scendere. L'italiano si ferma alla
## quarta — i suoi mondi alti rigiocano quello che hanno gia' visto, ed e' un
## debito dichiarato, non una regola; l'inglese nasce con tutte e otto.
const MINIMI := {
	"italiano": {"casi": 12, "famiglie": 4, "fascia_max": 4},
	"inglese": {"casi": 12, "famiglie": 8, "fascia_max": 8},
}

func _init() -> void:
	var manager := MinigameManager.new()
	for subject_data in MINIMI.keys():
		_test_materia(manager, str(subject_data))
	_test_player(manager)
	quit(0)

func _test_materia(manager: MinigameManager, subject: String) -> void:
	var minimi: Dictionary = MINIMI[subject]
	var cases: Dictionary = {}
	var topics: Dictionary = {}
	var checked := 0
	for level in [1, 6, 13, 24]:
		for seed_value in range(64):
			var rng := RandomNumberGenerator.new()
			rng.seed = level * 4099 + seed_value + subject.hash()
			var node := manager._verb_decoder_node(subject, level, 0, rng, seed_value)
			var validation := ExerciseInteraction.validate(node)
			assert(bool(validation.get("ok", false)),
				"%s: messaggio non valido L%d seed%d: %s" % [subject, level, seed_value, str(validation.get("errors", []))])
			var result := ExerciseInteraction.evaluate_verb_decoder(node, node.get("solution", {}))
			assert(bool(result.get("correct", false)), "%s: la soluzione dichiarata non apre il messaggio" % subject)
			assert("_____" not in str(result.get("rendered", "")), "%s: la soluzione lascia il verbo vuoto" % subject)
			var id := str(node.get("id", ""))
			cases[id.get_slice("-", 3)] = true
			topics[str(node.get("topic", ""))] = true
			checked += 1
	assert(cases.size() >= int(minimi["casi"]),
		"%s: troppi pochi casi verbali incontrati: %s" % [subject, str(cases.keys())])
	assert(topics.size() >= int(minimi["famiglie"]),
		"%s: la progressione non copre abbastanza famiglie verbali: %s" % [subject, str(topics.keys())])
	# Ogni fascia deve avere almeno un caso: un formato che si ferma alla quarta
	# lascia i mondi alti a rigiocare quello che hanno gia' visto.
	var fasce: Dictionary = {}
	var casi := manager._verb_decoder_templates_inglese() if subject == "inglese" else MinigameManager._verb_decoder_templates(subject)
	for caso_data in casi:
		fasce[int((caso_data as Dictionary).get("tier", 1))] = true
	var fascia_alta := 0
	for fascia in fasce.keys():
		fascia_alta = maxi(fascia_alta, int(fascia))
	assert(fasce.has(1) and fascia_alta >= int(minimi["fascia_max"]),
		"%s: i casi arrivano alla fascia %d invece che alla %d: %s" % [
			subject, fascia_alta, int(minimi["fascia_max"]), str(fasce.keys())])
	print("VERB DECODER %s — %d casi validi, %d scene, %d famiglie verbali, %d fasce" % [
		subject, checked, cases.size(), topics.size(), fasce.size()])

func _test_player(manager: MinigameManager) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260810
	var node := manager._verb_decoder_node("italiano", 24, 0, rng, 0)
	var session := {
		"sessionId": "verb-decoder-audit", "kind": "minigame",
		"subject": "italiano", "level": 24, "nodes": [node], "shields": 3,
		"pace": "reasoning", "timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 0}},
	}
	var player := ExercisePlayer.new()
	root.add_child(player)
	player.start_session(session)
	assert(player.find_child("VerbEvidence", true, false) != null, "mancano gli indizi narrativi")
	assert(player.find_child("VerbMessagePreview", true, false) != null, "manca il messaggio da ricostruire")
	assert(player.find_child("VerbAxis_time", true, false) != null, "manca la ghiera del tempo")
	assert(player.find_child("VerbAxis_mood", true, false) != null, "manca la ghiera del modo")
	assert(player.find_child("VerbAxis_form", true, false) != null, "manca la ghiera della forma")
	var solution := node.get("solution", {}) as Dictionary
	for axis in ["time", "mood", "form"]:
		player._verb_select(axis, str(solution.get(axis, "")), node)
	var result := ExerciseInteraction.evaluate_verb_decoder(node, player._verb_selection)
	player._finish_verb_decode(node, result)
	assert(bool(player._answered), "il messaggio ricostruito non conclude la tappa")
	assert(int(player._correct) == 1, "il messaggio ricostruito non vale una riuscita")
	assert("INDIZIO RECUPERATO" in str(player._verb_preview.text), "la scoperta narrativa non appare")
	player.queue_free()
