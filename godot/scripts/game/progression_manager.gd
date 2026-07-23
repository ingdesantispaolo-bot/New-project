class_name ProgressionManager
extends RefCounted

## Logica di progressione: registra l'esito delle missioni (padronanza + evidenza
## cumulativa + energia), valuta la readiness del gate a 4 dimensioni
## (GateReadiness) e ripara l'apparato facendo salire di livello SENZA azzerare il
## lavoro svolto. Vedi docs/DESIGN_COMPLETO.md §1–2 e O-P0 in insieme.md.

var save  # GameSaveManager
var content  # ContentManager opzionale: serve alla dimensione COPERTURA (numero
             # di argomenti che la materia può proporre). Se null, la copertura
             # ripiega sul minimo assoluto (retro-compatibile con audit/probe).

func _init(save_manager, content_manager = null) -> void:
	save = save_manager
	content = content_manager

# Registra l'esito di una missione esterna. Aggiorna evidenza cumulativa (se
# superata), padronanza (media mobile verso l'accuratezza) ed energia. Il
# conteggio è CUMULATIVO e non viene mai azzerato: il progresso verso il gate è
# la differenza con quanto già consumato (vedi GameSaveManager).
func record_mission(subject: String, correct: int, total: int, energy_gained: int, session_passed: bool = true) -> void:
	var accuracy := float(correct) / float(maxi(total, 1))
	if session_passed and accuracy >= 0.5:
		save.add_mission(subject)
	save.set_mastery(subject, lerpf(save.mastery_of(subject), accuracy, 0.25))
	if energy_gained > 0:
		save.add_energy(energy_gained)

# PRATICA ripetibile (minigiochi): allena padronanza ed energia SENZA contare per
# il gate dell'apparato (nessun add_mission) — così la pratica è rigiocabile e
# non farma i requisiti di riparazione. La mastery per-topic si aggiorna a parte
# con record_topic_stats, come per le missioni.
func record_practice(subject: String, correct: int, total: int, energy_gained: int) -> void:
	var accuracy := float(correct) / float(maxi(total, 1))
	save.set_mastery(subject, lerpf(save.mastery_of(subject), accuracy, 0.25))
	if energy_gained > 0:
		save.add_energy(energy_gained)

# Aggiorna la padronanza PER-ARGOMENTO dagli esiti della sessione
# (`topic_stats` = {topic: {"seen", "correct"}}). Media mobile un po' più reattiva
# di quella per-materia (0.34 vs 0.25): i campioni per topic sono più radi. Al
# primo incontro (topic sconosciuto) la mastery parte dall'accuratezza osservata.
func record_topic_stats(subject: String, topic_stats: Dictionary) -> void:
	for topic in topic_stats.keys():
		var entry: Dictionary = topic_stats[topic]
		var seen := int(entry.get("seen", 0))
		if seen <= 0:
			continue
		var accuracy := float(int(entry.get("correct", 0))) / float(seen)
		var prev: float = float(save.topic_mastery_of(subject, str(topic)))
		var updated: float = accuracy if prev < 0.0 else lerpf(prev, accuracy, 0.34)
		save.set_topic_mastery(subject, str(topic), updated)

func current_gate() -> Dictionary:
	return ApparatusConfig.level_gate(save.level())

func is_complete() -> bool:
	return save.level() > ApparatusConfig.MAX_LEVEL

# Numero di argomenti che la materia corrente può proporre (dal banco), o -1 se
# non è disponibile un ContentManager. Alimenta la dimensione COPERTURA del gate.
func _total_topics(subject: String) -> int:
	if content == null:
		return -1
	return content.subject_topic_count(subject)

# Readiness completa del gate del livello corrente (4 dimensioni, GateReadiness).
func readiness() -> Dictionary:
	var gate := current_gate()
	return GateReadiness.evaluate(save, gate, _total_topics(str(gate["subject"])))

# Requisiti soddisfatti per riparare l'apparato del livello corrente?
func can_repair() -> bool:
	if is_complete():
		return false
	return bool(readiness()["ready"])

func repair_progress() -> Dictionary:
	# Utile all'HUD: quanto manca al prossimo apparato. Include le 4 dimensioni.
	var gate := current_gate()
	var subject := str(gate["subject"])
	var r := readiness()
	return {
		"subject": subject,
		"apparatus": str(gate["apparatus"]),
		"missionsDone": save.missions_toward_gate(subject),
		"missionsRequired": int(gate["missionsRequired"]),
		"mastery": save.mastery_of(subject),
		"masteryThreshold": float(gate["masteryThreshold"]),
		"ready": bool(r["ready"]),
		"complete": is_complete(),
		# Dimensioni del gate (lette da HUD/marker, non ricalcolate).
		"readiness": r,
	}

# Ripara l'apparato (esercizio finale superato) e avanza di livello. NON azzera il
# conteggio missioni: segna come consumate quelle correnti della materia, così il
# lavoro resta e la prossima ricomparsa della materia richiede missioni nuove.
func repair_and_advance(exam_passed: bool) -> bool:
	if not can_repair() or not exam_passed:
		return false
	var gate := current_gate()
	save.set_apparatus_repaired(str(gate["apparatus"]), save.level())
	save.consume_gate(str(gate["subject"]))
	save.set_level(save.level() + 1)
	save.add_energy(80)
	return true
