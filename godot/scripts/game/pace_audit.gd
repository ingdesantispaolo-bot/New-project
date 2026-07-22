extends SceneTree

## Audit didattico · ritmo cognitivo e limite di tempo.
## Regola: le materie di RAGIONAMENTO non hanno mai limite di tempo. Solo la
## matematica (tabelline) è "fluency". Nessuna sessione è cronometrata oggi
## (l'ExercisePlayer è turn-based): l'audit blocca una regressione futura che
## introduca tempo su una materia di ragionamento.
## Uso: godot --headless --path godot --script res://scripts/game/pace_audit.gd

const REASONING := [
	"italiano", "inglese", "coding", "fisica", "musica", "latino", "elettronica",
	"geografia", "scienze", "cittadinanza", "logica",
]

func _init() -> void:
	var content := ContentManager.new()

	# La matematica è l'unica "fluency"; tutte le altre sono ragionamento.
	assert(ContentManager.subject_pace("matematica") == ContentManager.PACE_FLUENCY, "matematica deve essere fluency")
	assert(not ContentManager.is_untimed("matematica"), "matematica è l'unica candidabile a un tempo")

	for subject in REASONING:
		assert(ContentManager.subject_pace(subject) == ContentManager.PACE_REASONING, "%s deve essere ragionamento" % subject)
		assert(ContentManager.is_untimed(subject), "%s non deve mai avere limite di tempo" % subject)
		# Ogni tipo di sessione porta pace + timed=false per il ragionamento.
		var mission := content.build_mission(subject, 3, 3)
		assert(str(mission.get("pace", "")) == ContentManager.PACE_REASONING, "pace missione errato: %s" % subject)
		assert(not bool(mission.get("timed", true)), "missione cronometrata: %s" % subject)
		var enigma := content.build_enigma(subject, 3, 4)
		assert(not bool(enigma.get("timed", true)), "enigma cronometrato: %s" % subject)
		var exam := content.build_final_exam(subject, 3, 3)
		assert(not bool(exam.get("timed", true)), "esame cronometrato: %s" % subject)

	# Materia sconosciuta: default prudente = ragionamento, mai cronometrata.
	assert(ContentManager.is_untimed("materia-nuova-ipotetica"), "il default deve essere non cronometrato")

	print("Pace audit OK — ragionamento senza limite di tempo; matematica unica fluency")
	quit(0)
