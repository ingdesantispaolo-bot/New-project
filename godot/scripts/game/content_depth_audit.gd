extends SceneTree

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")
const WorldLessonCatalog = preload("res://scripts/game/world_lesson.gd")

## Gate Opus (compito 3): PROFONDITÀ e QUALITÀ DEI DISTRATTORI ai livelli alti.
## Due misure, entrambe sull'esperienza reale:
##
## 1) Profondità giocata — ogni materia torna due volte (mondo i e mondo i+12).
##    La seconda comparsa deve essere davvero più impegnativa (difficoltà media
##    più alta e quota di prove difficili) e non più povera di argomenti: altrimenti
##    il secondo mondo è solo una ripetizione con un'altra scenografia.
##
## 2) Distrattori — la risposta corretta non deve essere riconoscibile dalla forma.
##    Se in una domanda a frasi la risposta è molto più lunga di ogni alternativa,
##    il bambino la indovina senza sapere il contenuto e la padronanza misurata
##    (da cui dipendono gate e riattivazione della nave) non vale nulla.
## Uso: godot --headless --path godot --script res://scripts/game/content_depth_audit.gd

const REPEATS := 6              # mondi simulati per livello
const MIN_TOPICS_PER_WORLD := 4 # argomenti distinti incontrati in un mondo
const MIN_HARD_SHARE := 0.50    # quota di prove d≥3 nei mondi alti (13–24)
const MIN_DIFFICULTY_STEP := 0.3  # scalino di difficoltà media tra le due comparse
const MIN_PROMISED_SHARE := 0.15  # quota minima di nodi DELLA MATERIA sugli argomenti della lezione
const MIN_FOCUS_SHARE := 0.30     # quota minima di nodi della materia del mondo
const CUE_RATIO := 1.3          # risposta "molto più lunga" di ogni distrattore
const MAX_CUE_SHARE := 0.08     # quota massima di item con quell'indizio

func _init() -> void:
	var content := ContentManager.new()
	var failures: Array = []

	# --- 1) Profondità giocata, materia per materia ------------------------------
	print("Profondità giocata (prima comparsa → seconda comparsa)")
	print("MATERIA       MONDI    DIFF.MEDIA   PROVE d>=3   ARGOMENTI")
	for index in ApparatusConfig.SUBJECT_CYCLE.size():
		var subject := str(ApparatusConfig.SUBJECT_CYCLE[index])
		var low := _world_stats(content, subject, index + 1)
		var high := _world_stats(content, subject, index + 13)
		print("%-13s %2d+%2d  %5.2f → %5.2f   %3.0f%% → %3.0f%%   %2d → %2d   lezione %2.0f%% → %2.0f%%   focus %2.0f%% → %2.0f%%" % [
			subject, index + 1, index + 13,
			low["difficulty"], high["difficulty"],
			low["hard"] * 100.0, high["hard"] * 100.0,
			int(low["topics"]), int(high["topics"]),
			float(low["promisedShare"]) * 100.0, float(high["promisedShare"]) * 100.0,
			float(low["focusShare"]) * 100.0, float(high["focusShare"]) * 100.0])
		if int(low["topics"]) < MIN_TOPICS_PER_WORLD:
			failures.append("%s L%d: solo %d argomenti nel mondo" % [subject, index + 1, int(low["topics"])])
		if int(high["topics"]) < MIN_TOPICS_PER_WORLD:
			failures.append("%s L%d: solo %d argomenti nel mondo" % [subject, index + 13, int(high["topics"])])
		if float(high["difficulty"]) < float(low["difficulty"]) + MIN_DIFFICULTY_STEP:
			failures.append("%s: la seconda comparsa (L%d) non è più difficile della prima (%.2f → %.2f)" % [
				subject, index + 13, low["difficulty"], high["difficulty"]])
		if float(high["hard"]) < MIN_HARD_SHARE:
			failures.append("%s L%d: solo il %.0f%% di prove difficili (min %.0f%%)" % [
				subject, index + 13, high["hard"] * 100.0, MIN_HARD_SHARE * 100.0])
		# Il mondo deve insegnare ciò che la sua lezione promette.
		for stats in [low, high]:
			var lvl := int(stats["level"])
			for missing in Array(stats["missingTopics"]):
				failures.append("L%d (%s): la lezione promette '%s' ma il mondo non lo serve mai" % [lvl, subject, str(missing)])
			if float(stats["promisedShare"]) < MIN_PROMISED_SHARE:
				failures.append("L%d (%s): solo il %.0f%% dei nodi DELLA MATERIA sugli argomenti promessi (min %.0f%%)" % [
					lvl, subject, float(stats["promisedShare"]) * 100.0, MIN_PROMISED_SHARE * 100.0])
			# Ogni mondo ospita tutte e dodici le materie, ma la sua deve restare
			# dominante: è ciò che regge lezione, landmark, gate e identità.
			if float(stats["focusShare"]) < MIN_FOCUS_SHARE:
				failures.append("L%d (%s): la materia del mondo è solo il %.0f%% dei nodi (min %.0f%%)" % [
					lvl, subject, float(stats["focusShare"]) * 100.0, MIN_FOCUS_SHARE * 100.0])

	# --- 2) Qualità dei distrattori nei banchi ------------------------------------
	print("Indizio di lunghezza nei banchi (risposta a frase più lunga di %.0f%% di ogni distrattore)" % ((CUE_RATIO - 1.0) * 100.0))
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var items := content._load_bank(s)
		var mc := 0
		var cued := 0
		for item in items:
			if not ExerciseInteraction.is_multiple_choice(item):
				continue
			mc += 1
			if _has_length_cue(item):
				cued += 1
		if mc == 0:
			continue
		var share := float(cued) / float(mc)
		if cued > 0:
			print("  %-13s %d/%d item (%.0f%%)" % [s, cued, mc, share * 100.0])
		if share > MAX_CUE_SHARE:
			failures.append("%s: %d item su %d hanno la risposta riconoscibile dalla lunghezza (%.0f%%, max %.0f%%)" % [
				s, cued, mc, share * 100.0, MAX_CUE_SHARE * 100.0])

	if not failures.is_empty():
		print("Content depth audit FALLITO:")
		for f in failures:
			print("  - %s" % str(f))
		quit(1)
		return
	print("Content depth audit OK — seconde comparse più difficili, argomenti sufficienti, distrattori senza indizio di lunghezza")
	quit(0)

# --- helper -------------------------------------------------------------------

# Statistiche dell'esperienza REALE del mondo: difficoltà media, quota di prove
# d≥3 e argomenti distinti incontrati (missioni, enigmi, pratica ed esame).
func _world_stats(content: ContentManager, subject: String, level: int) -> Dictionary:
	var profile := WorldProfileCatalog.profile(level)
	var events := MissionEventDirector.plan(profile, {}, "audit-depth-%d" % level)
	var topics: Dictionary = {}
	var topic_counts: Dictionary = {}
	var total := 0
	var focus_nodes := 0
	var hard := 0
	var difficulty_sum := 0.0
	for repeat in range(REPEATS):
		var rng := RandomNumberGenerator.new()
		rng.seed = 4200 + level * 37 + repeat
		var sessions: Array = []
		for event in events:
			var kind := str((event as Dictionary).get("kind", "mission"))
			# La materia è quella dell'EVENTO, non quella del mondo: da quando ogni
			# mondo ospita tutte e dodici le materie (decisione del 30 luglio), usare
			# sempre il focus misurava un'esperienza che non esiste — diciotto
			# sessioni della materia del mondo invece di sette.
			var event_subject := str((event as Dictionary).get("subject", subject))
			if kind == "enigma":
				sessions.append(content.build_enigma(event_subject, level, 4, {}, rng))
			elif kind == "practice":
				sessions.append(content.minigame_manager.build_minigame(event_subject, level, rng))
			else:
				sessions.append(content.build_varied_mission(event_subject, level, 3, {}, rng))
		sessions.append(content.build_final_exam(subject, level, 3, rng))
		for session in sessions:
			var session_subject := str((session as Dictionary).get("subject", subject))
			for node in (session as Dictionary).get("nodes", []):
				var n: Dictionary = node
				total += 1
				if session_subject == subject:
					focus_nodes += 1
				var d := int(n.get("difficulty", 1))
				difficulty_sum += float(d)
				if d >= 3:
					hard += 1
				var topic := str(n.get("topic", ""))
				if topic != "":
					topics[topic] = true
					topic_counts[topic] = int(topic_counts.get(topic, 0)) + 1
	# Argomenti promessi dalla lezione del mondo: quanti sono davvero serviti e con
	# che peso. Senza questo controllo un mondo può restare fedele solo nei testi
	# (è già successo: storia 11/23 serviva le stesse ere, il mondo 16 "viaggi"
	# proponeva il 2% di nodi sui propri argomenti).
	var promised: Array = WorldLessonCatalog.topics(level)
	var missing: Array = []
	var promised_nodes := 0
	for topic in promised:
		if topics.has(str(topic)):
			promised_nodes += int(topic_counts.get(str(topic), 0))
		else:
			missing.append(str(topic))
	return {
		"level": level,
		"difficulty": difficulty_sum / float(maxi(1, total)),
		"hard": float(hard) / float(maxi(1, total)),
		"topics": topics.size(),
		# La quota si misura sui nodi della materia DEL MONDO, non su tutti: gli
		# eventi di varietà sono per definizione di altre materie, e la promessa
		# della lezione riguarda la materia del mondo. Misurarla su tutto
		# significherebbe punire il mondo per essere vario, che è ciò che gli
		# abbiamo chiesto di essere.
		"promisedShare": float(promised_nodes) / float(maxi(1, focus_nodes)),
		# La materia del mondo deve restare DOMINANTE: "leggermente dominante" è
		# comunque dominante, ed è ciò che tiene in piedi lezione, landmark e gate.
		"focusShare": float(focus_nodes) / float(maxi(1, total)),
		"missingTopics": missing,
	}

# Vero se la risposta è una FRASE ed è molto più lunga di ogni alternativa.
func _has_length_cue(item: Dictionary) -> bool:
	var answer := str(item.get("answer", ""))
	if answer.length() < 14 or not answer.contains(" "):
		return false
	var longest_other := 0
	for opt in item.get("options", []):
		var o := str(opt)
		if o == answer:
			continue
		longest_other = maxi(longest_other, o.length())
	return float(answer.length()) > float(longest_other) * CUE_RATIO
