extends SceneTree

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## Gate Opus (compito 2): distribuzione REALE dei formati nell'esperienza giocata,
## materia per materia. Non guarda i banchi né un singolo build: ricostruisce il
## mondo come lo gioca un bambino — gli eventi pianificati dal MissionEventDirector
## (missioni-tappa, enigmi, pratica) più l'esame finale della nave — e conta i
## formati dei nodi che l'ExercisePlayer riceverebbe davvero.
##
## Criteri didattici verificati per ogni materia:
##  - la scelta multipla non è dominante: ≤ 33% dei nodi giocati (target docenti);
##  - nessuna singola meccanica domina: nessun formato oltre il 40%;
##  - l'esperienza è varia: almeno 4 formati distinti nel mondo.
## Uso: godot --headless --path godot --script res://scripts/game/format_mix_audit.gd

const REPEATS := 8            # ripetizioni per mondo (la selezione è stocastica)
const MAX_MC_RATIO := 0.33    # scelta multipla non dominante
const MAX_ANY_RATIO := 0.40   # nessuna meccanica dominante
const MIN_DISTINCT := 4       # varietà minima di formati nel mondo

var _repeats: Dictionary = {}   # "materia L· tipo" -> numero di sessioni con una prova ripetuta

func _init() -> void:
	var content := ContentManager.new()
	var by_subject: Dictionary = {}   # subject -> {format: count}
	var by_level: Dictionary = {}     # level -> {format: count}
	var levels_of: Dictionary = {}    # subject -> Array[int]

	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var subject := str(profile["learningFocus"]["subject"])
		var events := MissionEventDirector.plan(profile, {}, "audit-format-mix-%d" % level)
		var counts: Dictionary = {}
		for repeat in range(REPEATS):
			var rng := RandomNumberGenerator.new()
			rng.seed = 9000 + level * 101 + repeat
			for event in events:
				var kind := str((event as Dictionary).get("kind", "mission"))
				var session: Dictionary = {}
				if kind == "enigma":
					session = content.build_enigma(subject, level, 4, {}, rng)
				elif kind == "practice":
					session = content.minigame_manager.build_minigame(subject, level, rng)
				else:
					session = content.build_varied_mission(subject, level, 3, {}, rng)
				_tally(counts, session)
				_check_repeats(session, subject, level, kind)
			# L'esame dell'apparato chiude il mondo: fa parte dell'esperienza giocata.
			var exam := content.build_final_exam(subject, level, 3, rng)
			_tally(counts, exam)
			_check_repeats(exam, subject, level, "esame")
		by_level[level] = counts
		_merge(by_subject, subject, counts)
		var seen: Array = levels_of.get(subject, [])
		seen.append(level)
		levels_of[subject] = seen

	# --- Report per materia -----------------------------------------------------
	print("Distribuzione dei formati nell'esperienza giocata (mondi completi, %d ripetizioni)" % REPEATS)
	print("MATERIA       MONDI    NODI |    MC  ABBIN  ORDIN  CLASS  GRAFI  CIRCU  DEBUG  NUMER | FORMATI  DOMINANTE")
	var failures: Array = []
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var counts: Dictionary = by_subject.get(s, {})
		var total := _total(counts)
		var mc := float(int(counts.get("multiple_choice", 0))) / float(maxi(1, total))
		var top := _dominant(counts)
		var top_ratio := float(int(counts.get(str(top), 0))) / float(maxi(1, total))
		var distinct := counts.size()
		print("%-13s %-7s %6d | %5s %6s %6s %6s %6s %6s %6s %6s | %5d    %s %.0f%%" % [
			s, _levels_label(levels_of.get(s, [])), total,
			_pct(counts, "multiple_choice", total), _pct(counts, "matching", total),
			_pct(counts, "ordering", total), _pct(counts, "classification", total),
			_pct(counts, "graph", total), _pct(counts, "circuit", total),
			_pct(counts, "code_debug", total), _pct(counts, "numeric_input", total),
			distinct, top, top_ratio * 100.0])
		if mc > MAX_MC_RATIO:
			failures.append("%s: scelta multipla al %.0f%% (max %.0f%%)" % [s, mc * 100.0, MAX_MC_RATIO * 100.0])
		if top_ratio > MAX_ANY_RATIO:
			failures.append("%s: meccanica dominante %s al %.0f%% (max %.0f%%)" % [s, top, top_ratio * 100.0, MAX_ANY_RATIO * 100.0])
		if distinct < MIN_DISTINCT:
			failures.append("%s: solo %d formati distinti (min %d)" % [s, distinct, MIN_DISTINCT])

	# --- Mondi con esperienza più povera (diagnosi, non fallimento) -------------
	var poorest: Array = []
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var counts: Dictionary = by_level[level]
		if counts.size() < MIN_DISTINCT:
			poorest.append("mondo %d (%d formati)" % [level, counts.size()])
	if not poorest.is_empty():
		failures.append("mondi poco vari: %s" % ", ".join(PackedStringArray(poorest)))

	# Nessuna sessione può proporre due volte la stessa prova: la ripetizione
	# immediata non insegna, annoia e falsa la misura di padronanza.
	if not _repeats.is_empty():
		var worst: Array = []
		for key in _repeats.keys():
			worst.append("%s ×%d" % [str(key), int(_repeats[key])])
		failures.append("prove ripetute nella stessa sessione: %s" % ", ".join(PackedStringArray(worst)))

	if not failures.is_empty():
		print("Format mix audit FALLITO — distribuzione fuori policy:")
		for f in failures:
			print("  - %s" % str(f))
		quit(1)
		return
	var all_counts: Dictionary = {}
	for s in by_subject.keys():
		for f in (by_subject[s] as Dictionary).keys():
			all_counts[f] = int(all_counts.get(f, 0)) + int(by_subject[s][f])
	var grand := _total(all_counts)
	print("Format mix audit OK — %d nodi giocati su 24 mondi · scelta multipla %s · dominante %s" % [
		grand, _pct(all_counts, "multiple_choice", grand), _dominant(all_counts)])
	quit(0)

# --- helper -------------------------------------------------------------------

func _tally(counts: Dictionary, session: Dictionary) -> void:
	for node in session.get("nodes", []):
		var fmt := ExerciseInteraction.format_of(node)
		counts[fmt] = int(counts.get(fmt, 0)) + 1

# Segnala le sessioni che propongono due volte la stessa prova (stesso prompt).
func _check_repeats(session: Dictionary, subject: String, level: int, kind: String) -> void:
	var seen: Dictionary = {}
	for node in session.get("nodes", []):
		var key := str((node as Dictionary).get("prompt", ""))
		if key == "":
			continue
		if seen.has(key):
			var label := "%s L%d %s" % [subject, level, kind]
			_repeats[label] = int(_repeats.get(label, 0)) + 1
			return
		seen[key] = true

func _merge(by_subject: Dictionary, subject: String, counts: Dictionary) -> void:
	var acc: Dictionary = by_subject.get(subject, {})
	for f in counts.keys():
		acc[f] = int(acc.get(f, 0)) + int(counts[f])
	by_subject[subject] = acc

func _total(counts: Dictionary) -> int:
	var n := 0
	for f in counts.keys():
		n += int(counts[f])
	return n

func _dominant(counts: Dictionary) -> String:
	var best := ""
	var best_n := -1
	for f in counts.keys():
		if int(counts[f]) > best_n:
			best_n = int(counts[f])
			best = str(f)
	return best

func _pct(counts: Dictionary, fmt: String, total: int) -> String:
	if total <= 0 or not counts.has(fmt):
		return "-"
	return "%.0f%%" % (float(int(counts[fmt])) / float(total) * 100.0)

func _levels_label(levels: Array) -> String:
	var parts: Array = []
	for l in levels:
		parts.append(str(int(l)))
	return "+".join(PackedStringArray(parts))
