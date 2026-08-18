extends SceneTree

## Le tre eco finali attraversano due regie diverse: Squadra chiude il
## confronto prima della sintesi; Meridiana e il Tredicesimo stanno fra la
## Cattedra e la restituzione del nome. Questo audit blocca proprio quell'ordine.

const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(900, 600)
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["worlds"] = {"unlocked": range(1, 25), "current": 24}
	StanceChoices.registra_risposta(initial, "squadra-quaderno", "ci-scrivo")
	StanceChoices.registra_risposta(initial, "meridiana-riga", "rispondo")
	StanceChoices.registra_risposta(initial, "tredicesimo-domanda", "aspetto")
	var hub := (load(HUB_SCENE) as PackedScene).instantiate()
	hub.set("launch_save_override", initial)
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame

	var save: GameSaveManager = hub.get("save")
	hub.call("_start_finale_confronto")
	var confrontation: Array = hub.get("finale_confronto_sequence")
	assert(not confrontation.is_empty()
		and str((confrontation[-1] as Dictionary).get("stance_echo", "")) == "squadra-quaderno",
		"l'eco di Squadra non segue il confronto con NORA")
	hub.call("_skip_finale_confronto")
	assert(StanceChoices.eco_pendente(save.data, "squadra-quaderno") == "",
		"saltare il confronto lascia l'eco di Squadra appesa")

	hub.call("_start_finale_epilogue")
	var sequence: Array = hub.get("finale_sequence")
	var cattedra_size := Array((FinaleCatalog.CATTEDRA as Dictionary).get("scena", [])).size()
	assert(str((sequence[cattedra_size] as Dictionary).get("stance_echo", "")) == "meridiana-riga",
		"Meridiana non torna subito dopo l'assegnazione della Cattedra")
	assert(str((sequence[cattedra_size + 1] as Dictionary).get("stance_echo", "")) == "tredicesimo-domanda",
		"la domanda del Tredicesimo non torna prima del suo nome")
	assert(int(hub.get("finale_cattedra_entries")) == cattedra_size + 2,
		"la restituzione del nome parte prima delle due eco")
	var dialogue: DialogueBox = hub.get("finale_dialogue_box")
	var safety := 0
	while dialogue.visible and safety < 32:
		dialogue.close_dialogue()
		await process_frame
		safety += 1
	assert(StanceChoices.eco_pendente(save.data, "meridiana-riga") == ""
		and StanceChoices.eco_pendente(save.data, "tredicesimo-domanda") == "",
		"un'eco del finale si ripeterebbe")
	assert(str(hub.get_meta("finale_epilogue_phase", "")) == "choice",
		"le eco impediscono di arrivare alla scelta finale")

	root.remove_child(hub)
	hub.queue_free()
	await process_frame
	print("Stance echo finale audit OK — Squadra dopo NORA, due eco fra Cattedra e nome")
	quit(0)
