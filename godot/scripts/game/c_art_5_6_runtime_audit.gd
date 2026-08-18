extends SceneTree

## C-ART-5/6: le scelte devono essere saltabili e ricordate; il caso profondo
## deve essere raro, eleggibile e soprattutto visibile prima del dialogo.

const DIRECTOR := preload("res://scripts/game/thirteenth.gd")
const ACTOR := preload("res://scripts/game/npc_actor.gd")
const PANEL := preload("res://scripts/ui/teaching_choice_panel.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_assert_skippable_choice_panel()
	_assert_deep_selection()
	await _assert_deep_visual()
	print("C-ART-5/6 runtime audit OK — scelta saltabile, caso profondo visibile e reversibile")
	quit(0)

func _assert_skippable_choice_panel() -> void:
	var panel: TeachingChoicePanel = PANEL.new()
	root.add_child(panel)
	panel.open_choice(
		"SQUADRA · IL FASCICOLO",
		"Che cosa fai?",
		StanceChoices.opzioni("squadra-quaderno"),
		true)
	assert(panel.visible, "la scelta di posizione non si apre")
	var skip := panel.find_child("SkipChoice", true, false) as Button
	assert(skip != null and skip.visible, "la scelta non è saltabile")
	assert(panel.choices.get_child_count() == StanceChoices.opzioni("squadra-quaderno").size() + 1,
		"il salto ha sostituito una delle posizioni")
	panel.queue_free()

func _assert_deep_selection() -> void:
	var early = DIRECTOR.new()
	early.setup(22, "c-art-audit", [], "residente-a")
	assert(early.choose_deep_forgotten_resident(
		["residente-a", "residente-b"], false) == "",
		"il caso profondo compare fuori dal gesto `smemora`")

	var deep = DIRECTOR.new()
	deep.setup(23, "c-art-audit", [], "residente-a")
	var selected := deep.choose_deep_forgotten_resident(
		["residente-a", "residente-b", "residente-c"], false)
	assert(selected in ["residente-b", "residente-c"],
		"il caso profondo ha scelto il proprietario della missione")
	var already_used = DIRECTOR.new()
	already_used.setup(23, "c-art-audit", [], "")
	assert(already_used.choose_deep_forgotten_resident(
		["residente-a", "residente-b"], true) == "",
		"il caso profondo si ripete nella stessa campagna")

func _assert_deep_visual() -> void:
	var actor: NpcActor = ACTOR.new()
	var resident := NpcCatalog.resident("w23-nives")
	if resident.is_empty():
		# L'identità conta meno del contratto visivo; questa fixture esiste dal
		# mondo 1 ed evita che un futuro cambio di nome nel 23 renda rosso l'audit.
		resident = NpcCatalog.resident("w01-tobia")
	actor.configure("w01-tobia", resident, true)
	root.add_child(actor)
	actor.set_activity("come ha sempre fatto")
	var art_position := actor.npc_art.position if is_instance_valid(actor.npc_art) else Vector2.ZERO
	actor.set_deep_forgotten(true)
	assert(bool(actor.get_meta("deep_forgotten", false)), "l'attore non espone il caso profondo")
	assert(Array(actor.get_meta("deep_visual_language", [])).size() == 3,
		"il segno visuale non dichiara gesto, percorso spezzato e oggetto")
	var activity := actor.get_node("NpcActivity") as Label
	assert(activity.visible and "gesto" in activity.text,
		"attraversando il mondo non si vede che il gesto continua")
	if is_instance_valid(actor.npc_art):
		assert(actor.npc_art.position == art_position,
			"smemora ha cambiato la posa invece di corrompere lo stesso gesto")
	# Parlare non è richiesto dal visuale e il ritorno deve rimettere la riga
	# precedente, con un segno visivo distinto prima di sparire.
	actor.play_deep_memory_return()
	assert(not bool(actor.get_meta("deep_forgotten", true)), "il caso non si ripristina")
	assert(bool(actor.get_meta("deep_memory_return_visible", false)),
		"il ritorno esiste solo nelle battute")
	assert(activity.text == "come ha sempre fatto", "il lavoro non torna dopo la prova")
	actor.queue_free()
	await process_frame
