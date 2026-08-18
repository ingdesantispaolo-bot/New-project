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
## La padronanza dopo una sessione.
##
## La media mobile parte da zero, e al PRIMO contatto con una materia questo
## dava un risultato falso: un bambino che risponde tre su tre veniva modellato
## come «competente al 25%», e servivano cinque sessioni perfette per arrivare a
## 0,70. Moltiplicato per dodici materie, era il costo del mondo 1 — misurato in
## 128 minuti contro i 33 del secondo.
##
## Alla prima sessione la padronanza vale quanto la prestazione, un po'
## prudenzialmente. Dalla seconda in poi la media mobile riprende come prima:
## serve a smorzare il caso, ed è giusta quando c'è già una storia da smorzare.
const PRUDENZA_PRIMO_CONTATTO := 0.85

# --- Decadimento per trascuratezza (6 agosto 2026) ----------------------------
#
# **Il difetto.** La padronanza non scendeva mai per il passare del tempo. Un
# bambino poteva portare una materia sopra soglia una volta e non toccarla più
# per venti mondi: il gate a dodici materie chiedeva lavoro la prima volta e mai
# più. Su indicazione del committente — «se il gioco è troppo facile non
# stimola» — quella rendita finisce.
#
# **Misurato in SESSIONI, non in giorni.** È la differenza che rende la penalità
# accettabile: colpisce la *scelta* di ignorare una materia mentre si continua a
# giocare, non l'*assenza* di chi torna dopo una settimana. Chi chiude il gioco
# per un mese ritrova esattamente quello che aveva.
#
# **Con una franchigia e un pavimento.** Le prime sessioni non tolgono niente
# (si può alternare senza essere puniti), e non si scende mai sotto metà del
# proprio massimo: una spirale da cui non si risale non è severità, è un vicolo
# cieco travestito.
const DECADIMENTO_FRANCHIGIA := 12    # sessioni di tolleranza prima di calare
const DECADIMENTO_PER_SESSIONE := 0.004
const DECADIMENTO_PAVIMENTO := 0.5    # frazione del picco sotto cui non si scende

func _padronanza_aggiornata(subject: String, accuracy: float) -> float:
	if save.mastery_never_set(subject):
		return clampf(accuracy * PRUDENZA_PRIMO_CONTATTO, 0.0, 1.0)
	return lerpf(save.mastery_of(subject), accuracy, 0.25)

func record_mission(subject: String, correct: int, total: int, energy_gained: int, session_passed: bool = true) -> void:
	var accuracy := float(correct) / float(maxi(total, 1))
	if session_passed and accuracy >= 0.5:
		save.add_mission(subject)
	save.set_mastery(subject, _padronanza_aggiornata(subject, accuracy))
	if energy_gained > 0:
		save.add_energy(energy_gained)
	_dopo_una_sessione(subject)

# PRATICA ripetibile (minigiochi): allena padronanza ed energia SENZA contare per
# il gate dell'apparato (nessun add_mission) — così la pratica è rigiocabile e
# non farma i requisiti di riparazione. La mastery per-topic si aggiorna a parte
# con record_topic_stats, come per le missioni.
func record_practice(subject: String, correct: int, total: int, energy_gained: int) -> void:
	var accuracy := float(correct) / float(maxi(total, 1))
	save.set_mastery(subject, _padronanza_aggiornata(subject, accuracy))
	if energy_gained > 0:
		save.add_energy(energy_gained)
	_dopo_una_sessione(subject)

## Chiusa una sessione: la materia giocata torna «fresca», le altre invecchiano.
##
## Sta qui, e non nei chiamanti, perché missioni e pratica sono i due soli modi
## di allenare una materia: agganciarlo altrove significherebbe che una delle due
## strade non fa invecchiare niente, e la strada dimenticata diventerebbe la
## scorciatoia.
func _dopo_una_sessione(subject: String) -> void:
	var orologio := int(SpacedRepetition.session_clock(save))
	save.touch_subject(subject, orologio)
	applica_decadimento(orologio)

## Fa calare la padronanza delle materie trascurate.
##
## Tre difese, e ognuna evita un modo di rendere la penalità stupida:
##
##   FRANCHIGIA   le prime dodici sessioni non tolgono niente. Alternare fra
##                materie è il comportamento che il gioco chiede; punirlo
##                sarebbe punire chi fa la cosa giusta;
##   PAVIMENTO    non si scende mai sotto metà del proprio massimo. Una spirale
##                da cui non si risale non è severità, è un vicolo cieco;
##   MAI TOCCATA  una materia che il bambino non ha ancora incontrato non
##                decade. Non è trascurata: non è cominciata, e l'ordine dei
##                mondi non lo decide lui.
##
## Il picco si conserva perché il pavimento sia stabile: senza, il pavimento
## scenderebbe insieme alla padronanza e il decadimento arriverebbe a zero un
## passo alla volta.
func applica_decadimento(orologio: int) -> void:
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var ritardo := int(save.sessions_since(subject, orologio))
		if ritardo < 0:
			continue   # mai praticata: non è trascuratezza
		var oltre := ritardo - DECADIMENTO_FRANCHIGIA
		if oltre <= 0:
			continue
		var attuale := float(save.mastery_of(subject))
		var picco := maxf(float(save.mastery_peak(subject)), attuale)
		save.set_mastery_peak(subject, picco)
		var pavimento := picco * DECADIMENTO_PAVIMENTO
		if attuale <= pavimento:
			continue
		# Si toglie solo l'ULTIMO passo, non tutto l'arretrato: questa funzione
		# gira a ogni sessione, e ricalcolare l'intero ritardo ogni volta
		# toglierebbe la stessa cosa molte volte.
		save.set_mastery(subject, maxf(pavimento, attuale - DECADIMENTO_PER_SESSIONE))

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

## **Registra le materie arrivate in linea a questo grado.**
##
## Da chiamare quando una sessione è stata registrata per intero — padronanza,
## copertura e ripasso spaziato — perché è l'unico momento in cui le tre
## dimensioni sono tutte aggiornate. Prima di allora si leggerebbe uno stato a
## metà e si stamperebbe un traguardo sbagliato (o si mancherebbe quello giusto).
##
## Scandisce tutte e dodici e non solo la materia giocata: chiudere un ripasso
## arretrato di una materia può portarne in linea un'altra, e un traguardo
## mancato per un giro è esattamente il difetto che questa funzione ripara.
##
## Idempotente e monotona: un traguardo non si toglie mai, e il grado conservato
## lo fa scadere da solo al livello successivo.
func aggiorna_traguardi_di_livello() -> void:
	var livello := int(save.level())
	for subject_data in GateReadiness.GATE_SUBJECTS:
		var subject := str(subject_data)
		if save.subject_cleared_level(subject) >= livello:
			continue
		# **Zero argomenti visti = non pronta, senza bisogno di contarli.**
		# (18 agosto 2026)
		#
		# `apparatus_readiness` chiede `reachable_topic_count`, che per contare
		# gli argomenti proponibili COSTRUISCE cinque missioni intere. Per dodici
		# materie sono sessanta missioni, e la cache non aiuta: `ContentManager`
		# nasce nuovo a ogni ingresso nel mondo. Da quando questo aggiornamento
		# gira anche all'ingresso — e non solo a fine sessione, dove il costo era
		# invisibile — quelle sessanta costruzioni erano diventate la voce più
		# grossa dell'avvio: centosessanta millisecondi su un budget di cinquecento.
		#
		# La copertura si conta da quando il livello è cominciato, e
		# `GateReadiness.coverage_target` non restituisce mai meno di uno: una
		# materia con zero argomenti visti in questo livello fallisce la copertura
		# qualunque sia il totale. Il conteggio caro non cambierebbe l'esito.
		#
		# Si controlla solo questo, e non anche padronanza e ripasso, per non
		# duplicare le soglie di `evaluate_subject` — che applica il bonus del
		# nucleo — e ritrovarsi con due punti del gioco che dissentono.
		if int(save.topics_seen_this_level(subject)) <= 0:
			continue
		# Senza `certified`: si guardano i numeri veri, che è il solo modo di
		# stabilire se il traguardo è stato raggiunto adesso.
		if bool(apparatus_readiness(subject)["ready"]):
			save.set_subject_cleared(subject, livello)

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
#
# **Una stanza accesa a questo livello non si riaccende.** Misurato il 15 agosto
# 2026: superato l'esame di matematica al livello 1, `can_repair_apparatus`
# continuava a dire di sì e `repair_apparatus` pagava altri 80 di energia a ogni
# ripetizione. Non era solo una perdita economica — era la stessa prova richiesta
# di nuovo a chi l'aveva appena passata, e con il premio più grosso del gioco
# appeso davanti perché la rifacesse.
#
# Al passaggio successivo della materia (mondi 13-24) il livello è cresciuto oltre
# `repairedLevel` e l'esame torna disponibile: lì è un grado nuovo, non una
# ripetizione.
## **Il diritto all'esame, una volta guadagnato, non si perde.** (16 agosto 2026)
##
## `apparatus_readiness` guarda i numeri veri, ed è giusto che lo faccia: è la
## misura, e serve a stabilire QUANDO il traguardo viene raggiunto. Ma leggerla
## qui direttamente rendeva la porta dell'esame intermittente — bastava una
## palestra di un'altra materia lungo la strada del ritorno alla nave perché un
## ripasso di questa tornasse dovuto e l'esame si richiudesse in faccia a chi
## l'aveva appena aperto. Lo stesso difetto che rimetteva le materie chiuse
## nell'elenco di quelle da fare, e con un effetto peggiore: lì confondeva, qui
## faceva attraversare il mondo per niente.
##
## Il blocco della stanza GIÀ ACCESA resta sopra e non passa dal traguardo: è
## un'altra domanda, e va risposta con l'apparato in mano.
func can_repair_apparatus(subject: String) -> bool:
	if apparatus_certified_now(subject):
		return false
	return materia_in_linea(subject)

## **Questa materia è a posto per questo grado?**
##
## È la domanda che si fa la PRESENTAZIONE — «devo ancora lavorare qui?» — ed è
## diversa da `apparatus_readiness`, che è la misura grezza e serve a stabilire
## quando il traguardo viene raggiunto. Tenerle separate è ciò che permette al
## gioco di dire il numero vero («hai 1 ripasso arretrato») senza per questo
## rimettere in discussione una materia già chiusa.
func materia_in_linea(subject: String) -> bool:
	if GateReadiness.in_linea_a_questo_livello(save, subject):
		return true
	return bool(apparatus_readiness(subject)["ready"])

## La materia è già stata certificata a QUESTO livello?
func apparatus_certified_now(subject: String) -> bool:
	return GateReadiness.certified_at_level(save, subject)

# Compatibilità: l'apparato del mondo corrente. Da preferire la forma esplicita
# `can_repair_apparatus(subject)`, che dice quale stanza si sta aprendo.
func can_repair() -> bool:
	if is_complete():
		return false
	return can_repair_apparatus(ApparatusConfig.world_subject(save.level()))

# Un apparato è acceso? (`repairedLevel > 0`)
func is_apparatus_repaired(subject: String) -> bool:
	return save.apparatus_repaired_level(ApparatusConfig.apparatus_of(subject)) > 0

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
