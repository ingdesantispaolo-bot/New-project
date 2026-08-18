extends SceneTree

## **Un argomento "incontrato" non vuol dire un FATTO incontrato.** (16 agosto
## 2026)
##
## Nasce da una segnalazione diretta: «chiedere allo studente di mettere in
## ordine cronologico eventi storici che non conosce a cosa serve? Stessa cosa
## per elettronica. Serve prima una spiegazione nella quale lo studente possa
## apprendere prima di essere interrogato.»
##
## `teach_before_ask_audit.gd` garantisce che ogni ARGOMENTO nuovo porti una
## lezione. Non bastava: un ordinamento a insieme (`ExercisePool`) pesca ogni
## volta un sottoinsieme diverso da un banco che arriva a ventotto voci
## (`storia:cronologia`), e lo stato del topic diventa "incontrato" alla prima
## estrazione e resta così per tutta la campagna — mentre gli eventi pescati
## cambiano prova dopo prova. Questo audit controlla il livello sotto: il FATTO
## dentro il topic, non solo il topic.

const OK := "FACT LEVEL TEACHING audit VERDE"

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	if errori.size() < 40:
		errori.append(messaggio)

func _init() -> void:
	_registro_fatti_regge()
	_ordinamenti_a_insieme_insegnano_i_fatti_nuovi()
	_fatti_gia_noti_non_si_reinsegnano()
	if errori.is_empty():
		print(OK)
	else:
		printerr("FACT LEVEL TEACHING audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## L'API di base: marcare noti dei fatti li toglie da `unknown_facts`, e non
## tocca fatti di un altro argomento (l'isolamento per chiave "subject:topic").
func _registro_fatti_regge() -> void:
	var save := GameSaveManager.new("user://fact-level-teaching-audit-api.json")
	var drawn := [
		{"label": "Evento A", "value": 100.0},
		{"label": "Evento B", "value": 200.0},
		{"label": "Evento C", "value": 300.0},
	]
	var nuovi := KnowledgeCodex.unknown_facts(save, "storia", "cronologia", drawn)
	if nuovi.size() != 3:
		_fallisci("registro fatti: al primo incontro attesi 3 fatti nuovi, trovati %d" % nuovi.size())
	KnowledgeCodex.mark_facts_known(save, "storia", "cronologia", ["Evento A", "Evento B", "Evento C"])
	var dopo := KnowledgeCodex.unknown_facts(save, "storia", "cronologia", drawn)
	if not dopo.is_empty():
		_fallisci("registro fatti: dopo mark_facts_known restano %d fatti «nuovi»" % dopo.size())
	if KnowledgeCodex.fact_known(save, "elettronica", "cronologia", "Evento A"):
		_fallisci("registro fatti: una materia diversa non deve ereditare i fatti di un'altra")
	if not KnowledgeCodex.fact_known(save, "storia", "cronologia", "Evento B"):
		_fallisci("registro fatti: «Evento B» doveva risultare noto")

## Il percorso reale: generando sessioni di storia ed elettronica (i due casi
## della segnalazione), ogni nodo di ordinamento a insieme che pesca fatti mai
## visti deve portare la lista di quei fatti, leggibile, prima della domanda.
func _ordinamenti_a_insieme_insegnano_i_fatti_nuovi() -> void:
	var gameplay := OutdoorGameplay.new()
	gameplay.content_manager = ContentManager.new()
	gameplay.game_save = GameSaveManager.new("user://fact-level-teaching-audit-flow.json")
	var trovati_ordinamenti_a_insieme := 0
	var lezioni_con_fatti := 0
	for caso in [{"subject": "storia", "levels": [6, 14, 24]}, {"subject": "elettronica", "levels": [1, 8, 16]}]:
		var subject := str(caso["subject"])
		for level in Array(caso["levels"]):
			for _giro in range(20):
				var sessione: Dictionary = gameplay.content_manager.build_varied_mission(
					subject, level, 3, {}, null,
					gameplay.game_save.mastery_of(subject),
					gameplay.game_save.topic_masteries(subject))
				var nodi_prima: Array = Array(sessione.get("nodes", [])).duplicate(true)
				sessione = gameplay._decorate_teaching_session(sessione, subject)
				var nodi_dopo: Array = Array(sessione.get("nodes", []))
				for indice in nodi_prima.size():
					var nodo_prima: Dictionary = nodi_prima[indice]
					if str(nodo_prima.get("format", "")) != "ordering":
						continue
					var detail: Array = Array(nodo_prima.get("correctOrderDetail", []))
					if detail.is_empty():
						continue
					trovati_ordinamenti_a_insieme += 1
					var topic := str(nodo_prima.get("topic", ""))
					# **L'invariante vera non è «questo nodo elenca ogni suo
					# fatto»**: due ordinamenti sullo stesso argomento nella
					# stessa sessione possono dividersi i fatti nuovi fra loro
					# (il primo ne insegna alcuni, il secondo il resto — non
					# ripete quelli già coperti un attimo prima, che sarebbe il
					# difetto opposto). L'invariante vera è che, **dopo la
					# decorazione**, nessun fatto pescato resti sconosciuto: o
					# era già noto, o lo ha appena insegnato qualche lezione di
					# questa stessa sessione.
					for entry in detail:
						var label := str((entry as Dictionary).get("label", ""))
						if not KnowledgeCodex.fact_known(gameplay.game_save, subject, topic, label):
							_fallisci("%s livello %d: «%s» resta sconosciuto dopo la decorazione della sessione" % [
								subject, level, label])
					var nodo_dopo: Dictionary = nodi_dopo[indice]
					if nodo_dopo.has("teachingLesson") and not Dictionary(nodo_dopo["teachingLesson"]).is_empty():
						lezioni_con_fatti += 1
	if trovati_ordinamenti_a_insieme == 0:
		_fallisci("nessun ordinamento a insieme incontrato: il caso che l'audit deve coprire non è stato generato")
	if lezioni_con_fatti == 0:
		_fallisci("nessuna lezione di fatti nuovi è mai scattata: il meccanismo non si è mai attivato nella prova")

## Una volta insegnato, un fatto non deve tornare a occupare la scheda:
## altrimenti «una spiegazione prima di ogni domanda» degenera in un muro che
## si ripete a ogni prova, il difetto opposto a quello segnalato.
func _fatti_gia_noti_non_si_reinsegnano() -> void:
	var save := GameSaveManager.new("user://fact-level-teaching-audit-repeat.json")
	var drawn := [
		{"label": "Caduta dell'Impero Romano d'Occidente", "value": 476.0},
		{"label": "Prima crociata", "value": 1096.0},
	]
	var prima := KnowledgeCodex.unknown_facts(save, "storia", "cronologia", drawn)
	if prima.size() != 2:
		_fallisci("ripetizione: attesi 2 fatti nuovi al primo giro, trovati %d" % prima.size())
	var labels: Array = []
	for entry in prima:
		labels.append(str((entry as Dictionary).get("label", "")))
	KnowledgeCodex.mark_facts_known(save, "storia", "cronologia", labels)
	var seconda_volta := KnowledgeCodex.unknown_facts(save, "storia", "cronologia", drawn)
	if not seconda_volta.is_empty():
		_fallisci("ripetizione: gli stessi fatti risultano ancora «nuovi» al secondo giro (%d)" % seconda_volta.size())
	# Un pescato misto (un fatto noto, uno nuovo) deve insegnare solo quello nuovo.
	var misto := drawn.duplicate(true)
	misto.append({"label": "Trattati di Roma", "value": 1957.0})
	var solo_nuovo := KnowledgeCodex.unknown_facts(save, "storia", "cronologia", misto)
	if solo_nuovo.size() != 1 or str(solo_nuovo[0].get("label", "")) != "Trattati di Roma":
		_fallisci("pescato misto: attesa solo «Trattati di Roma» come fatto nuovo, trovato %s" % str(solo_nuovo))
