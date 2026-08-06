class_name ProgressionManager
extends RefCounted

const KnowledgeCodex = preload("res://scripts/game/knowledge_codex.gd")
const NoraState = preload("res://scripts/game/nora_state.gd")
const TopicEvidence = preload("res://scripts/game/topic_evidence.gd")

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
## Restituisce gli **avanzamenti nel Codex** prodotti da questa sessione:
## `[{topic, da, a}]`, in ordine di argomento.
##
## Prima restituiva `void` e l'avanzamento restava un fatto privato del save. Ma
## il Codex è l'unica ricompensa che la **pratica** produce — gli eventi di
## pratica non contano per il gate — e una ricompensa che il giocatore non vede
## non è una ricompensa: è una riga di JSON. Chi chiama può finalmente dire al
## bambino *cosa ha imparato*, con quelle parole.
func record_topic_stats(subject: String, topic_stats: Dictionary) -> Array:
	var advanced: Array = []
	for topic in topic_stats.keys():
		var entry: Dictionary = topic_stats[topic]
		var seen := int(entry.get("seen", 0))
		if seen <= 0:
			continue
		var accuracy := float(int(entry.get("correct", 0))) / float(seen)
		var prev: float = float(save.topic_mastery_of(subject, str(topic)))
		var updated: float = accuracy if prev < 0.0 else lerpf(prev, accuracy, 0.34)
		# `set_topic_mastery` registra anche la copertura di questo livello.
		save.set_topic_mastery(subject, str(topic), updated)
		var state_before := KnowledgeCodex.state_of(save, subject, str(topic))
		# Manuale NORA (O-P4): avanza lo stato di conoscenza dell'argomento e nutre
		# la fiducia sul MIGLIORAMENTO (non sulla singola risposta giusta).
		KnowledgeCodex.advance_state(save, subject, str(topic), "seen")
		if accuracy >= 0.5:
			KnowledgeCodex.advance_state(save, subject, str(topic), "correct")
			# Evidenza di ritenzione: una sessione risolta bene su questo argomento.
			# La chiave è la sessione, non la singola risposta, così tre risposte
			# nella stessa missione non valgono tre prove.
			TopicEvidence.record_correct(save, subject, str(topic), SpacedRepetition.session_clock(save))
		# CONSOLIDATO (decisione utente del 29 luglio 2026): tre sessioni corrette
		# distinte con almeno tre giorni tra la prima e l'ultima. Prima bastava una
		# padronanza alta, che si può raggiungere in una sera sola: non era
		# ritenzione, era una fotografia.
		if TopicEvidence.is_consolidated(save, subject, str(topic)):
			KnowledgeCodex.advance_state(save, subject, str(topic), "consolidated")
		if prev >= 0.0 and updated > prev + 0.05:
			NoraState.register(save, "improvement")
		var state_after := KnowledgeCodex.state_of(save, subject, str(topic))
		if state_after != state_before:
			advanced.append({
				"topic": str(topic),
				"da": state_before,
				"a": state_after,
			})
	advanced.sort_custom(func(a, b): return str(a["topic"]) < str(b["topic"]))
	return advanced

func current_gate() -> Dictionary:
	return ApparatusConfig.level_gate(save.level())

func is_complete() -> bool:
	return save.level() > ApparatusConfig.MAX_LEVEL

# Avanzamento della campagna per la presentazione (voce di menu del Secondo
# Viaggio, report): quanti mondi sono completati e se la rotta è aperta.
#
# Prodotto QUI e non nella UI: derivare la progressione da `level()` per conto
# proprio è esattamente il disallineamento che l'invariante «la presentazione non
# calcola» vieta (vedi insieme.md). Un mondo è completato quando il suo apparato
# è riparato, cioè quando il livello è avanzato oltre di esso: al livello L sono
# completati L-1 mondi. Il conteggio è limitato alla scala, così un livello oltre
# il massimo non produce "29/24".
func campaign_progress() -> Dictionary:
	return {
		"worldsCompleted": clampi(save.level() - 1, 0, ApparatusConfig.MAX_LEVEL),
		"worldsTotal": ApparatusConfig.MAX_LEVEL,
		"complete": is_complete(),
	}

# Argomenti RAGGIUNGIBILI a questo livello, non tutti quelli del banco: la
# copertura deve chiedere una fetta di ciò che il livello propone davvero.
# Contare tutto il banco rendeva il gate impossibile ai primi livelli.
func _total_topics(subject: String) -> int:
	if content == null:
		return -1
	return content.reachable_topic_count(subject, save.level())

# Argomenti proponibili per OGNI materia: dal 5 agosto 2026 il gate le chiede
# tutte, non solo le tre strumentali.
func _core_topic_counts() -> Dictionary:
	var out: Dictionary = {}
	for subject in GateReadiness.GATE_SUBJECTS:
		out[str(subject)] = _total_topics(str(subject))
	return out

# Prontezza del LIVELLO: accuratezza, copertura e ritenzione su italiano,
# matematica e inglese. Nessun conteggio di missioni (decisione del 30 luglio).
func readiness() -> Dictionary:
	return GateReadiness.evaluate_core(
		save, ApparatusConfig.mastery_threshold(save.level()), _core_topic_counts())

# Prontezza di un APPARATO: le stesse tre dimensioni sulla sua materia.
func apparatus_readiness(subject: String) -> Dictionary:
	return GateReadiness.evaluate_subject(
		save, subject, ApparatusConfig.mastery_threshold(save.level()), _total_topics(subject))

# Si può salire di livello?
func can_level_up() -> bool:
	if is_complete():
		return false
	return bool(readiness()["ready"])

# Si può riparare l'apparato di questa materia?
func can_repair_apparatus(subject: String) -> bool:
	return bool(apparatus_readiness(subject)["ready"])

# Compatibilità: l'apparato del mondo corrente. Da preferire la forma esplicita
# `can_repair_apparatus(subject)`, che dice quale stanza si sta aprendo.
func can_repair() -> bool:
	if is_complete():
		return false
	return can_repair_apparatus(ApparatusConfig.world_subject(save.level()))

# Un apparato è acceso? (`repairedLevel > 0`)
func is_apparatus_repaired(subject: String) -> bool:
	var apparatus := ApparatusConfig.apparatus_of(subject)
	return int(save.data.get("apparatus", {}).get(apparatus, {}).get("repairedLevel", 0)) > 0

# Quante delle dodici stanze sono accese. Il Cuore si apre con dodici, non con
# ventiquattro livelli: è la garanzia che tutte le competenze vengano acquisite.
func repaired_apparatus_count() -> int:
	var count := 0
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		if is_apparatus_repaired(str(subject)):
			count += 1
	return count

func all_apparatus_repaired() -> bool:
	return repaired_apparatus_count() >= ApparatusConfig.SUBJECT_CYCLE.size()

# Le materie la cui stanza è ancora spenta. Serve a DIRLO al giocatore, che è
# metà del rimedio: una porta chiusa senza spiegazione è un difetto.
func missing_apparatus_subjects() -> Array:
	var missing: Array = []
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		if not is_apparatus_repaired(str(subject)):
			missing.append(str(subject))
	return missing

## Il Cuore si apre con DODICI STANZE ACCESE, non con ventiquattro livelli.
##
## È la garanzia che tutte le competenze vengano acquisite, e chiude il vicolo
## cieco creato dalla decisione del 30 luglio: col livello gatato dal solo nucleo
## si poteva arrivare al 24 senza aver mai toccato latino e trovarsi davanti una
## prova a dodici sistemi impossibile. Ora la prova non si apre proprio, e il
## gioco dice quali stanze mancano.
func can_open_heart() -> bool:
	return save.level() >= ApparatusConfig.MAX_LEVEL and all_apparatus_repaired()

func repair_progress() -> Dictionary:
	# Contratto per l'HUD: quanto manca al prossimo livello, materia per materia.
	# La presentazione legge, non ricalcola.
	var r := readiness()
	var world := ApparatusConfig.world_subject(save.level())
	return {
		# Materia che ABITA il mondo corrente (identità, non gate).
		"worldSubject": world,
		"apparatus": ApparatusConfig.apparatus_of(world),
		"coreSubjects": Array(r["coreSubjects"]).duplicate(),
		"masteryThreshold": float(r["masteryThreshold"]),
		"progress": float(r["progress"]),
		"missing": Array(r["missing"]).duplicate(),
		"ready": bool(r["ready"]),
		"complete": is_complete(),
		"readiness": r,
		# Collezione delle stanze: è questa, non il livello, che apre il Cuore.
		"apparatusRepaired": repaired_apparatus_count(),
		"apparatusTotal": ApparatusConfig.SUBJECT_CYCLE.size(),
	}

# Ripara l'apparato di una materia (esame superato). **Non fa salire di livello**:
# accende una stanza. I tre del nucleo si accendono lungo la strada; i nove
# satelliti quando il giocatore vuole — ma servono tutti e dodici per il Cuore.
func repair_apparatus(subject: String, exam_passed: bool) -> bool:
	if not exam_passed or not can_repair_apparatus(subject):
		return false
	save.set_apparatus_repaired(ApparatusConfig.apparatus_of(subject), save.level())
	NoraState.sync_from_progress(save)
	save.consume_gate(subject)
	save.add_energy(80)
	return true

# Sale di livello quando il nucleo è pronto. Separato dalla riparazione: prima
# erano lo stesso atto, e finché lo sono stati non si poteva avere un livello
# gatato da tre materie e dodici apparati riparabili a piacere.
func advance_level() -> bool:
	if not can_level_up():
		return false
	# L'ultimo gradino chiude la campagna: si supera solo con le dodici stanze
	# accese. Senza questo, il nucleo da solo porterebbe oltre la scala lasciando
	# nove materie mai toccate.
	if save.level() >= ApparatusConfig.MAX_LEVEL and not all_apparatus_repaired():
		return false
	for subject in ApparatusConfig.CORE_SUBJECTS:
		save.consume_gate(str(subject))
	var next_level: int = int(save.level()) + 1
	save.set_level(next_level)
	# Il nuovo livello ricomincia a contare la copertura da qui: quello che si
	# sa resta, ma per il gate successivo servono argomenti NUOVI. È ciò che
	# impedisce che un livello superato apra da solo tutti quelli dopo.
	save.reset_coverage_this_level()
	if next_level <= ApparatusConfig.MAX_LEVEL:
		save.unlock_world(next_level)
		save.set_current_world(next_level)
	save.add_energy(80)
	NoraState.sync_from_progress(save)
	return true

# Compatibilità con i consumer storici: ripara l'apparato del mondo corrente e,
# se il nucleo è pronto, sale di livello. Le due cose non sono più legate, quindi
# può riuscirne una sola.
func repair_and_advance(exam_passed: bool) -> bool:
	var repaired := repair_apparatus(ApparatusConfig.world_subject(save.level()), exam_passed)
	var advanced := advance_level()
	return repaired or advanced
