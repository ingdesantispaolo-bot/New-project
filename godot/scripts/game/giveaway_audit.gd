extends SceneTree

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## Nessuna prova deve REGALARE la risposta con la sola presentazione. È la stessa
## famiglia di difetti dell'indizio di lunghezza nei distrattori: il bambino
## supera la prova senza sapere il contenuto, e la padronanza misurata — da cui
## dipendono gate e riattivazione della nave — diventa un numero falso.
##
## Quattro regole, tutte nate da difetti realmente trovati:
##   1. un ordinamento non arriva mai già ordinato (capitava a uno su ventuno,
##      anche dentro l'esame dell'apparato);
##   2. nella caccia all'errore la riga giusta non sta sempre nello stesso posto
##      (era la terza nel 56% dei casi, e in sei materie SEMPRE la terza);
##   3. la spiegazione indica la riga davvero sbagliata, anche dopo il rimescolio;
##   4. nei banchi la risposta corretta non predilige una posizione.
## Uso: godot --headless --path godot --script res://scripts/game/giveaway_audit.gd

const SEEDS := 24
const MAX_POSITION_SHARE := 0.35   # nessuna posizione oltre il 35% delle risposte

func _init() -> void:
	var failures: Array = []
	_check_ordinamenti(failures)
	_check_caccia_errore(failures)
	_check_posizione_risposte(failures)
	if not failures.is_empty():
		print("Giveaway audit FALLITO — prove che si risolvono da sole:")
		for f in failures:
			print("  - %s" % str(f))
		quit(1)
		return
	print("Giveaway audit OK — nessun ordinamento già risolto, riga d'errore mobile, posizioni delle risposte uniformi")
	quit(0)

# 1) Ordinamenti: gli elementi non arrivano mai nell'ordine giusto.
func _check_ordinamenti(failures: Array) -> void:
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var checked := 0
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		for level in [1, 4, 8, 13, 18, 24]:
			for seed_i in range(SEEDS):
				var rng := RandomNumberGenerator.new()
				rng.seed = level * 977 + seed_i
				var sessions: Array = [
					mg.build_minigame(s, level, rng),
					content.build_varied_mission(s, level, 3, {}, rng),
					content.build_enigma(s, level, 4, {}, rng),
					content.build_final_exam(s, level, 3, rng),
				]
				for session in sessions:
					for node in (session as Dictionary).get("nodes", []):
						var n: Dictionary = node
						if str(n.get("format", "")) != "ordering":
							continue
						checked += 1
						var items: Array = n.get("items", [])
						var correct: Array = n.get("correctOrder", [])
						if items == correct:
							failures.append("%s L%d: ordinamento già risolto in partenza (%s)" % [s, level, str(items)])
							return
	if checked < 100:
		failures.append("campione troppo piccolo per gli ordinamenti: %d" % checked)

# 2 e 3) Caccia all'errore: riga mobile e spiegazione coerente.
func _check_caccia_errore(failures: Array) -> void:
	var mg := MinigameManager.new()
	var positions: Dictionary = {}   # materia -> {riga: conteggio}
	var regex := RegEx.create_from_string("^Riga\\s+(\\d+)")
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		if not MinigameManager.CODE_DEBUG.has(s):
			continue
		for spec in Array(MinigameManager.CODE_DEBUG[s]):
			for seed_i in range(SEEDS):
				var rng := RandomNumberGenerator.new()
				rng.seed = 31 + seed_i
				var node := mg._code_debug_node(s, spec, 12, rng, 0)
				var line := int(node["answerLine"])
				var lines: Array = node["codeLines"]
				# La riga indicata deve esistere ed essere quella davvero sbagliata.
				if line < 1 or line > lines.size():
					failures.append("%s: riga della soluzione fuori dal codice (%d)" % [s, line])
					continue
				if str(lines[line - 1]) != str((spec["codeLines"] as Array)[int(spec["answerLine"]) - 1]):
					failures.append("%s: dopo il rimescolio la riga indicata non è quella sbagliata" % s)
				# La spiegazione non può puntare a una riga innocente.
				var m := regex.search(str(node["explanation"]))
				if m != null and int(m.get_string(1)) != line:
					failures.append("%s: la spiegazione cita la riga %s ma la soluzione è la %d" % [s, m.get_string(1), line])
				var by_line: Dictionary = positions.get(s, {})
				by_line[line] = int(by_line.get(line, 0)) + 1
				positions[s] = by_line
	# In ogni materia con più di uno spec la riga giusta deve poter cambiare.
	for s in positions.keys():
		var by_line: Dictionary = positions[s]
		var specs := Array(MinigameManager.CODE_DEBUG[str(s)]).size()
		if specs >= 3 and by_line.size() < 2:
			failures.append("%s: la riga sbagliata è sempre la stessa (%s) in %d prove" % [s, str(by_line.keys()), specs])

# 4) Banchi: la risposta corretta non predilige una posizione.
func _check_posizione_risposte(failures: Array) -> void:
	var content := ContentManager.new()
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var counts: Dictionary = {}
		var total := 0
		for item in content._load_bank(s):
			var options: Array = (item as Dictionary).get("options", [])
			if options.size() < 2:
				continue
			var idx := options.find(str((item as Dictionary).get("answer", "")))
			if idx < 0:
				continue
			counts[idx] = int(counts.get(idx, 0)) + 1
			total += 1
		if total < 20:
			continue
		for idx in counts.keys():
			var share := float(int(counts[idx])) / float(total)
			if share > MAX_POSITION_SHARE:
				failures.append("%s: la risposta è in posizione %d nel %.0f%% degli item (max %.0f%%)" % [
					s, int(idx) + 1, share * 100.0, MAX_POSITION_SHARE * 100.0])
