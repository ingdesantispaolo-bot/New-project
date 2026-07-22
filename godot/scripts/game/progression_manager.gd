class_name ProgressionManager
extends RefCounted

## Logica di progressione: registra l'esito delle missioni (padronanza + conteggio
## + energia), verifica il gate del livello e ripara l'apparato facendo salire di
## livello. Vedi docs/DESIGN_COMPLETO.md §1–2.

var save  # GameSaveManager

func _init(save_manager) -> void:
	save = save_manager

# Registra l'esito di una missione esterna. Aggiorna conteggio (se superata),
# padronanza (media mobile verso l'accuratezza) ed energia.
func record_mission(subject: String, correct: int, total: int, energy_gained: int, session_passed: bool = true) -> void:
	var accuracy := float(correct) / float(maxi(total, 1))
	if session_passed and accuracy >= 0.5:
		save.add_mission(subject)
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

# Requisiti soddisfatti per riparare l'apparato del livello corrente?
func can_repair() -> bool:
	var gate := current_gate()
	var subject := str(gate["subject"])
	return save.missions_of(subject) >= int(gate["missionsRequired"]) \
		and save.mastery_of(subject) >= float(gate["masteryThreshold"])

func repair_progress() -> Dictionary:
	# Utile all'HUD: quanto manca al prossimo apparato.
	var gate := current_gate()
	var subject := str(gate["subject"])
	return {
		"subject": subject,
		"apparatus": str(gate["apparatus"]),
		"missionsDone": save.missions_of(subject),
		"missionsRequired": int(gate["missionsRequired"]),
		"mastery": save.mastery_of(subject),
		"masteryThreshold": float(gate["masteryThreshold"]),
		"ready": can_repair(),
	}

# Ripara l'apparato (esercizio finale superato) e avanza di livello.
func repair_and_advance(exam_passed: bool) -> bool:
	if not can_repair() or not exam_passed:
		return false
	var gate := current_gate()
	save.set_apparatus_repaired(str(gate["apparatus"]), save.level())
	save.set_level(save.level() + 1)
	save.reset_missions()
	save.add_energy(80)
	return true
