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

## Sessioni che ripropongono lo stesso ARGOMENTO nello stesso formato. Non è la
## stessa prova (quella è un fallimento secco, sotto): è la stessa competenza
## chiesta due volte nello stesso modo a pochi minuti di distanza.
##
## L'avevo attribuito a insiemi poveri. Sbagliato: era la SELEZIONE. Con gli
## insiemi profondi il numero era anzi SALITO, perché due estrazioni diverse non
## venivano più scartate come duplicati.
##
## Sceso a ZERO nella Fase 4: da 184 al picco a nessuna sessione. Non è stato il
## contenuto a portarlo lì ma la SELEZIONE — la tavolozza dei minigiochi tiene un
## nodo per (formato, argomento) e il banco preferisce argomenti non ancora usati
## nella sessione. Da qui in poi il cricchetto è assoluto: una sola sessione che
## chiede due volte lo stesso argomento fa fallire l'audit.
const MAX_SAME_TOPIC_SESSIONS := 0

var _repeats: Dictionary = {}      # "materia L· tipo" -> sessioni con la STESSA prova due volte
var _same_topic := 0               # sessioni con lo stesso (formato, argomento) due volte
var _same_topic_examples: Array = [] # diagnosi: quali sessioni e quale coppia
var _sessions := 0                 # sessioni totali ricostruite, per dare la scala al numero sopra

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
	print("MATERIA       MONDI    NODI |    MC  ABBIN  ORDIN  CLASS  GRAFI  CIRCU  CICLO  DEBUG  NUMER | FORMATI  DOMINANTE")
	var failures: Array = []
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var counts: Dictionary = by_subject.get(s, {})
		var total := _total(counts)
		var mc := float(int(counts.get("multiple_choice", 0))) / float(maxi(1, total))
		var top := _dominant(counts)
		var top_ratio := float(int(counts.get(str(top), 0))) / float(maxi(1, total))
		var distinct := counts.size()
		print("%-13s %-7s %6d | %5s %6s %6s %6s %6s %6s %6s %6s %6s | %5d    %s %.0f%%" % [
			s, _levels_label(levels_of.get(s, [])), total,
			_pct(counts, "multiple_choice", total), _pct(counts, "matching", total),
			_pct(counts, "ordering", total), _pct(counts, "classification", total),
			_pct(counts, "graph", total), _pct(counts, "circuit", total),
			_pct(counts, "cycle", total),
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

	print("sessioni con lo stesso argomento nello stesso formato: %d su %d (%.1f%%, max %d)" % [
		_same_topic, _sessions, float(_same_topic) / float(maxi(1, _sessions)) * 100.0,
		MAX_SAME_TOPIC_SESSIONS])
	if _same_topic > MAX_SAME_TOPIC_SESSIONS:
		failures.append(
			"%d sessioni chiedono due volte lo stesso argomento nello stesso formato (max %d): %s" % [
				_same_topic, MAX_SAME_TOPIC_SESSIONS,
				", ".join(PackedStringArray(_same_topic_examples))])

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

# Segnala le sessioni che propongono due volte la stessa prova.
#
# La chiave è l'identità di contenuto condivisa (`ExerciseSignature`), non più il
# solo testo della consegna. Il testo non basta in nessuna delle due direzioni:
# tutti gli abbinamenti condividono la stessa consegna generica («Abbina ogni
# elemento alla sua coppia»), quindi due abbinamenti con coppie completamente
# diverse risultavano «la stessa prova»; e viceversa la stessa caccia all'errore
# con le righe rimescolate cambia numero di riga ma non consegna.
#
# Accanto resta la misura più severa che il testo intendeva catturare: lo stesso
# ARGOMENTO nello stesso formato due volte nella stessa sessione.
func _check_repeats(session: Dictionary, subject: String, level: int, kind: String) -> void:
	_sessions += 1
	var seen: Dictionary = {}
	var topics: Dictionary = {}
	var flagged_topic := false
	for node_data in session.get("nodes", []):
		var node := node_data as Dictionary
		var key := ExerciseSignature.of(node)
		if seen.has(key):
			var label := "%s L%d %s" % [subject, level, kind]
			_repeats[label] = int(_repeats.get(label, 0)) + 1
			return
		seen[key] = true
		var topic_key := "%s|%s" % [str(node.get("format", "")), str(node.get("topic", ""))]
		if topics.has(topic_key) and not flagged_topic:
			flagged_topic = true
			_same_topic += 1
			if _same_topic_examples.size() < 10:
				_same_topic_examples.append("%s L%d %s → %s" % [subject, level, kind, topic_key])
		topics[topic_key] = true

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
