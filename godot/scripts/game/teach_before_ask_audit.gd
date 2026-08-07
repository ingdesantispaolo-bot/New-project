extends SceneTree

## **Insegnare prima di chiedere.** (7 agosto 2026)
##
## Nasce da una segnalazione del committente che è, di fatto, un richiamo alla
## promessa del prodotto: «lo scopo del programma è didattico, non interrogatorio
## su argomenti mai visti. Ripeto: dobbiamo insegnare e non testare competenze
## che il bambino non ha mai visto».
##
## **La misura che ha dato ragione alla segnalazione.** Su 1440 nodi generati in
## dodici materie, il **60,6%** arrivava su un argomento mai spiegato in quella
## sessione. Non era un difetto di fisica o di elettronica — era uniforme su
## tutte e dodici. La causa: `_decorate_teaching_session` leggeva il topic del
## **primo** nodo e si fermava lì, mentre una sessione ne ha tre.
##
## Questo audit impedisce che torni, e controlla due cose distinte:
##
##   1. **il percorso**: nessun nodo su un argomento sconosciuto può essere
##      presentato senza la sua spiegazione davanti;
##   2. **il materiale**: ogni argomento che i banchi possono estrarre deve
##      AVERE una spiegazione da mostrare. Il punto 1 senza il punto 2 sarebbe
##      una promessa che il contenuto non può mantenere — e infatti la prima
##      misura dopo la correzione lasciava due nodi scoperti, che erano
##      esattamente argomenti senza voce nel manuale.

const OK := "TEACH BEFORE ASK audit VERDE"
## Quante sessioni per materia. Trenta bastano a incrociare gli argomenti di un
## livello più volte; il costo resta sotto il secondo.
const SESSIONI := 30

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	if errori.size() < 40:
		errori.append(messaggio)

func _init() -> void:
	_ogni_argomento_ha_una_lezione()
	_nessuna_domanda_senza_lezione()
	if errori.is_empty():
		print(OK)
	else:
		printerr("TEACH BEFORE ASK audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Il materiale: ogni argomento estraibile deve avere una mini-lezione con
## dentro qualcosa di vero — spiegazione, esempio svolto e metodo.
func _ogni_argomento_ha_una_lezione() -> void:
	var content := ContentManager.new()
	var codex := KnowledgeCodex.new(content)
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for topic_data in content.bank_topics(subject):
			var topic := str(topic_data)
			var lesson := codex.mini_lesson(subject, topic)
			if lesson.is_empty():
				_fallisci("%s · «%s»: nessuna lezione da mostrare prima della domanda" % [subject, topic])
				continue
			if str(lesson.get("explanation", "")).strip_edges().length() < 20:
				_fallisci("%s · «%s»: la spiegazione è troppo corta per spiegare qualcosa" % [subject, topic])
			var esempio: Dictionary = lesson.get("workedExample", {})
			if str(esempio.get("prompt", "")).strip_edges().is_empty():
				_fallisci("%s · «%s»: nessun esempio svolto" % [subject, topic])
			if str(lesson.get("strategy", "")).strip_edges().is_empty():
				_fallisci("%s · «%s»: nessun metodo, solo la definizione" % [subject, topic])

## Il percorso: si generano sessioni vere e si controlla che ogni nodo su un
## argomento ancora sconosciuto porti la propria lezione.
func _nessuna_domanda_senza_lezione() -> void:
	var gameplay := OutdoorGameplay.new()
	gameplay.content_manager = ContentManager.new()
	gameplay.game_save = GameSaveManager.new("user://teach-before-ask-audit.json")
	var scoperti := 0
	var totale := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var subject := str(ApparatusConfig.world_subject(level))
		for _giro in range(SESSIONI):
			var sessione: Dictionary = gameplay.content_manager.build_varied_mission(
				subject, level, 3, {}, null,
				gameplay.game_save.mastery_of(subject),
				gameplay.game_save.topic_masteries(subject))
			var nodi: Array = sessione.get("nodes", [])
			if nodi.is_empty():
				continue
			# Gli stati PRIMA della decorazione: dopo, la decorazione stessa li ha
			# gia' portati a «visto», e il controllo non troverebbe piu' niente.
			var prima: Dictionary = {}
			for raw in nodi:
				var t := str(Dictionary(raw).get("topic", ""))
				prima[t] = KnowledgeCodex.state_of(gameplay.game_save, subject, t)
			sessione = gameplay._decorate_teaching_session(sessione, subject)
			# **Coperto per ARGOMENTO, non per nodo.** Due domande sullo stesso
			# argomento nella stessa sessione portano una sola scheda, sul primo
			# nodo: contare per nodo faceva risultare scoperta la seconda, che e'
			# invece il comportamento giusto — la stessa spiegazione due volte di
			# fila si chiude senza leggerla.
			var spiegati: Dictionary = {}
			for raw_l in Array(sessione.get("nodes", [])):
				if Dictionary(raw_l).has("teachingLesson"):
					spiegati[str(Dictionary(raw_l).get("topic", ""))] = true
			for raw2 in Array(sessione.get("nodes", [])):
				var nodo: Dictionary = raw2
				totale += 1
				var topic := str(nodo.get("topic", ""))
				if spiegati.has(topic):
					continue
				if str(prima.get(topic, "")) == KnowledgeCodex.STATE_UNKNOWN:
					scoperti += 1
					_fallisci("%s livello %d · «%s»: domanda su un argomento mai spiegato" % [
						subject, level, topic])
	if totale > 0 and scoperti > 0:
		_fallisci("in totale %d nodi su %d (%.1f%%) arrivano senza spiegazione" % [
			scoperti, totale, 100.0 * float(scoperti) / float(totale)])
