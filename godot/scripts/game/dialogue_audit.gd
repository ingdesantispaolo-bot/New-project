extends SceneTree

## A1: il dialogo resta volontario, leggibile e accessibile; gli NPC sono
## presenze leggere del mondo e tutti i testi arrivano da NpcCatalog.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const DIALOGUE_BOX := preload("res://scripts/ui/dialogue_box.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_dialogue_contract()
	_test_dialogue_memory()
	await _test_world_one_fixture()
	print("DIALOGUE audit OK — memoria persistente, gia' ascoltato grigio, guida contestuale e cast mondo 1")
	quit(0)

func _test_dialogue_contract() -> void:
	var box: Control = DIALOGUE_BOX.new()
	root.add_child(box)
	await process_frame
	box.call("configure_accessibility", false, false)
	box.call("show_dialogue", "test", "Tobia", "Contatore", [
		"Questa frase è abbastanza lunga da non completarsi in un solo fotogramma.",
		"Seconda schermata.",
	])
	var body := box.get("body_label") as Label
	assert(box.visible and box.mouse_filter == Control.MOUSE_FILTER_STOP,
		"dialogo non intercetta il tocco su tutta la schermata")
	assert(body.visible_characters >= 0 and body.visible_characters < body.text.length(),
		"macchina da scrivere non avviata")
	var original_screen := int(box.get("screen_index"))
	box.call("advance")
	assert(int(box.get("screen_index")) == original_screen and body.visible_characters == -1,
		"il primo tocco deve completare il testo senza cambiare schermata")
	box.call("advance")
	assert(int(box.get("screen_index")) == 1 and box.visible,
		"il secondo tocco deve avanzare alla schermata successiva")
	await create_timer(0.08).timeout
	assert(box.visible, "un dialogo non può chiudersi a tempo")
	box.call("configure_accessibility", true, true)
	assert(body.visible_characters == -1 and not box.is_processing(),
		"riduzione movimento deve disattivare la macchina da scrivere")
	box.call("advance")
	assert(not box.visible, "l'ultimo tocco deve chiudere il dialogo")
	box.call("show_dialogue", "test", "Tobia", "Contatore", ["Battuta gia' sentita."], 0, true,
		"Raggiungi il filare est; poi torna da Tobia.")
	var heard_badge := box.get("heard_label") as Label
	var guidance := box.get("guidance_panel") as PanelContainer
	assert(heard_badge.visible and heard_badge.text.contains("ASCOLTATO"),
		"una battuta gia' ascoltata non e' dichiarata come ripasso")
	assert(guidance.visible and str((box.get("guidance_label") as Label).text).contains("filare est"),
		"il dialogo non espone il prossimo passo contestuale")
	var heard_color := body.get_theme_color("font_color")
	assert(heard_color.r < 0.85 and heard_color.g < 0.85 and heard_color.b < 0.85,
		"il testo gia' ascoltato non e' grigio")
	box.call("advance")
	box.queue_free()
	await process_frame

func _test_dialogue_memory() -> void:
	var save := GameSaveManager.new("user://dialogue-memory-audit.json")
	var key := "w01-tobia:prova"
	assert(not save.dialogue_heard(key), "una battuta nuova nasce gia' ascoltata")
	assert(save.remember_dialogue(key, "w01-tobia"), "il primo ascolto non viene registrato")
	assert(save.dialogue_heard(key), "la memoria non riconosce la battuta registrata")
	assert(not save.remember_dialogue(key, "w01-tobia"), "lo stesso ascolto viene contato due volte")
	var memory: Dictionary = save.game_narrative().get("dialogueMemory", {})
	assert(int(memory.get("exchanges", 0)) == 1 and str(memory.get("lastNpc", "")) == "w01-tobia",
		"riepilogo conversazionale incoerente")

func _test_world_one_fixture() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("dialogue-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": true, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame

	var actors := get_nodes_in_group("npc_actor")
	assert(actors.size() == 4,
		"mondo 1: attesi tre abitanti e un itinerante, mai più di quattro NPC")
	var expected := ["w01-ersilia", "w01-puccio", "w01-tobia"]
	var found: Array = []
	var chunks := world.get("chunks") as OutdoorChunkManager
	for node in actors:
		var actor := node as Area2D
		found.append(str(actor.get_meta("id", "")))
		assert(actor.is_in_group("world_interactable") and actor.get_node_or_null("NpcCollision") != null,
			"NPC senza area d'interazione")
		assert(not actor.is_processing(), "NPC animato nonostante riduzione movimento")
		assert(not chunks.composition.is_protected(actor.position, 60.0),
			"NPC dentro nave, percorso sicuro o POI protetto")
		assert(chunks.composition.raw_water_weight(actor.position) < 0.28,
			"NPC collocato in acqua")
	found.sort()
	for npc_id in expected:
		assert(found.has(npc_id), "cast mondo 1 incompleto: manca %s" % npc_id)
		var illustrated := actors.filter(func(actor): return str(actor.get_meta("id", "")) == npc_id)[0] as Area2D
		assert(illustrated.get_node_or_null("NpcArt") != null and bool(illustrated.get_meta("usesGeneratedArt", false)),
			"pilot grafico assente per %s" % npc_id)
	var itinerants := found.filter(func(npc_id): return str(npc_id).begins_with("itin-"))
	assert(itinerants.size() == 1, "mondo 1: atteso un solo itinerante, trovati %s" % str(itinerants))

	var player := world.get("player") as OutdoorPlayerController
	# Il contratto qui è la chiusura di un dialogo semplice. I residenti aprono
	# legittimamente il proprio minigioco subito dopo: usarne uno renderebbe
	# l'assert sul movimento una verifica falsa. L'itinerante non ha quel seguito.
	var target := actors.filter(
		func(actor): return str(actor.get_meta("id", "")).begins_with("itin-"))[0] as Area2D
	target.global_position = player.global_position + Vector2(50, 0)
	world.call("on_interactable_entered", target, player)
	world.call("_interact")
	await process_frame
	var box := world.get("dialogue_box") as Control
	assert(box != null and box.visible, "interagire con un NPC non apre il dialogo")
	assert(not player.is_physics_processing(), "Eli continua a muoversi durante il dialogo")
	assert((box.get("guidance_panel") as PanelContainer).visible,
		"un personaggio fuori rotta non indica il referente della missione")
	var spoken_guidance := str((box.get("guidance_label") as Label).text)
	assert(spoken_guidance.contains("Radura Accademia") and spoken_guidance.contains("Matematica"),
		"la guida del personaggio non descrive luogo e materia reali")
	var pages: Array = box.get("screens")
	for _page in pages.size():
		box.call("advance")
	assert(not box.visible and player.is_physics_processing(),
		"chiusura dialogo non ripristina il movimento")
	var memory_key := str(world.get("active_dialogue_memory_key"))
	assert(memory_key.is_empty(), "la chiave del dialogo resta attiva dopo la chiusura")
	var save := world.get("game_save") as GameSaveManager
	var dialogue_memory: Dictionary = save.game_narrative().get("dialogueMemory", {})
	assert(int(dialogue_memory.get("exchanges", 0)) == 1,
		"la chiusura del dialogo non aggiorna la memoria del profilo")
	# La rotazione deve consumare entrambe le battute nuove prima di mostrare in
	# grigio una ripetizione, anche se il cursore locale riparte da zero.
	var sample_lines := [["Prima battuta nuova."], ["Seconda battuta nuova."]]
	var first: Dictionary = world.call("_select_npc_dialogue", "test-npc", "test-pool", sample_lines)
	assert(not bool(first.get("heard", true)), "la prima battuta del pool nasce gia' grigia")
	save.remember_dialogue(str(first.get("key", "")), "test-npc")
	var second: Dictionary = world.call("_select_npc_dialogue", "test-npc", "test-pool", sample_lines)
	assert(not bool(second.get("heard", true)) and first.get("pages") != second.get("pages"),
		"la scelta non privilegia la seconda battuta ancora inedita")
	save.remember_dialogue(str(second.get("key", "")), "test-npc")
	var repeated: Dictionary = world.call("_select_npc_dialogue", "test-npc", "test-pool", sample_lines)
	assert(bool(repeated.get("heard", false)),
		"un pool esaurito non segnala la ripetizione da mostrare in grigio")

	world.queue_free()
	await process_frame
