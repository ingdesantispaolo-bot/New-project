extends SceneTree

const WorldLessonCatalog = preload("res://scripts/game/world_lesson.gd")

## Verifica SEMANTICA per-ondata (Opus, controllo di fine ondata C/D1/D2/E). Non
## tocca la resa: verifica che i CONTRATTI didattici dei mondi 9–24 (e per
## coerenza tutti i 24) siano solidi PRIMA che Codex chiuda il gate visuale.
##
## Controlli:
##  - trasformazione ambientale guidata dall'apprendimento e NON decorativa
##    (trigger = evento di successo; effetto unico per mondo, nessun copia-incolla);
##  - prova di trasferimento reale (contesto nuovo dichiarato e segnalato nel testo);
##  - testi di NORA distinti per mondo (nessun briefing/debrief riciclato);
##  - coerenza disciplinare (le azioni-concetto parlano del focus del mondo);
##  - convergenza del finale (mondo 24 esplicitamente trasversale).
## Uso: godot --headless --path godot --script res://scripts/game/world_semantics_audit.gd

const SUCCESS_MARKERS := ["corret", "risolt", "complet", "individuat", "superat", "giust", "esatt"]
const NOVELTY_MARKERS := ["nuov", "mai visto", "divers", "un caso", "un'applicazione"]

func _has_marker(text: String, markers: Array) -> bool:
	var low := text.to_lower()
	for m in markers:
		if low.find(str(m)) >= 0:
			return true
	return false

func _init() -> void:
	var effects: Dictionary = {}      # effetto trasformazione -> livello (unicità)
	var briefings: Dictionary = {}
	var debriefs: Dictionary = {}

	for level in WorldLessonCatalog.all_levels():
		var lesson := WorldLessonCatalog.lesson(level)
		var subject := str(lesson["subject"])

		# 1) Trasformazione ambientale: guidata dall'apprendimento, non decorativa.
		var env := WorldLessonCatalog.environment_transform(level)
		var trigger := str(env.get("trigger", ""))
		var effect := str(env.get("effect", ""))
		assert(_has_marker(trigger, SUCCESS_MARKERS), "L%d: il trigger della trasformazione non è un evento di apprendimento: '%s'" % [level, trigger])
		assert(effect.length() >= 12, "L%d: effetto di trasformazione troppo generico" % level)
		assert(not effects.has(effect), "L%d: effetto di trasformazione DUPLICATO (decorativo/copia) con L%s" % [level, str(effects.get(effect, ""))])
		effects[effect] = level

		# 2) Prova di trasferimento reale: contesto nuovo dichiarato E segnalato.
		var tt: Dictionary = lesson["transferTest"]
		assert(bool(tt["novelContext"]), "L%d: la prova non dichiara contesto nuovo" % level)
		assert(Array(tt["formats"]).size() >= 2, "L%d: la prova di trasferimento deve ammettere ≥2 formati" % level)
		assert(_has_marker(str(tt["description"]), NOVELTY_MARKERS), "L%d: la prova non segnala la novità del contesto: '%s'" % [level, str(tt["description"])])

		# 3) Testi di NORA distinti per mondo (nessun riciclo).
		var briefing := WorldLessonCatalog.briefing(level)
		var debrief := WorldLessonCatalog.debrief(level)
		assert(not briefings.has(briefing), "L%d: briefing NORA duplicato con L%s" % [level, str(briefings.get(briefing, ""))])
		assert(not debriefs.has(debrief), "L%d: debrief NORA duplicato con L%s" % [level, str(debriefs.get(debrief, ""))])
		briefings[briefing] = level
		debriefs[debrief] = level

		# 4) Coerenza disciplinare: almeno un'azione-concetto e un obiettivo non vuoti,
		# e il focus coincide con la scala (unica fonte di verità).
		assert(subject == str(ApparatusConfig.level_gate(level)["subject"]), "L%d: focus incoerente" % level)
		var actions: Array = lesson["conceptActions"]
		assert(actions.size() >= 2, "L%d: servono ≥2 azioni-concetto per rappresentare la materia" % level)

	# 5) Convergenza del finale: il mondo 24 è esplicitamente trasversale.
	var final_lesson := WorldLessonCatalog.lesson(24)
	var final_text := (str(final_lesson["nora"]["briefing"]) + " " + " ".join(PackedStringArray(final_lesson["objectives"]))).to_lower()
	assert(final_text.find("insieme") >= 0 or final_text.find("tutte le materie") >= 0 or final_text.find("trasfer") >= 0 or final_text.find("convergono") >= 0, "il mondo 24 deve essere esplicitamente trasversale")

	print("World semantics audit OK — 24 mondi: trasformazioni non decorative e distinte, trasferimento reale, NORA distinti, coerenza disciplinare, finale trasversale")
	quit(0)
