extends SceneTree

## Audit strutturale e geometrico della nave. Controlla il contenuto realmente
## istanziato e impedisce regressioni con controlli fuori dal viewport.

const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load(HUB_SCENE)
	var hub := packed.instantiate()
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame

	var screen := hub.find_child("ShipScreen", true, false) as Control
	var background := hub.find_child("RoomBackground", true, false) as TextureRect
	var back := hub.find_child("BackToWorldButton", true, false) as Button
	var power := hub.find_child("ShipPowerOverlay", true, false) as Control
	var activation_bar := hub.find_child("ShipActivationProgress", true, false) as ProgressBar
	var activation_phase := hub.find_child("ActivationPhase", true, false) as Label
	assert(screen != null and screen.size == root.get_visible_rect().size,
		"la nave deve occupare l'intero viewport")
	assert(background != null and background.texture != null,
		"sfondo nave non caricato")
	assert(background.size == screen.size, "sfondo nave non fullscreen")
	assert(power != null and power.size == screen.size, "rete energetica nave non fullscreen")
	assert(activation_bar != null and activation_phase != null, "stato di riattivazione non esposto")
	_assert_visible_control(back, "Torna al mondo")

	var ids := ShipRoomCatalog.ids()
	assert(ids.size() == 7, "il catalogo nave deve contenere sette ponti")
	for room_id in ids:
		var id := str(room_id)
		var spec := ShipRoomCatalog.room(id)
		var texture_path := str(spec.get("texture", ""))
		assert(ResourceLoader.exists(texture_path), "asset nave assente: %s" % texture_path)
		var button := hub.find_child("RoomButton_%s" % id, true, false) as Button
		_assert_visible_control(button, "ponte %s" % id)
		assert(button.text.contains("%"), "il ponte %s non mostra la propria potenza" % id)
		hub.call("_select_room", id)
		await process_frame
		assert(background.texture != null and background.texture.resource_path == texture_path,
			"il ponte %s non applica il proprio WebP" % id)
		assert(hub.find_child("ApparatusTerminal", true, false) != null,
			"apparato visuale assente nel ponte %s" % id)

	var card := hub.find_child("ApparatusCard", true, false) as Control
	_assert_visible_control(card, "scheda apparato")
	print("SHIP PRESENTATION audit OK - 7 ponti WebP, rete energetica e potenza nel viewport")
	quit(0)

func _assert_visible_control(control: Control, label: String) -> void:
	assert(control != null, "%s assente" % label)
	var viewport_rect := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var visible_rect := control.get_global_rect().intersection(viewport_rect)
	assert(control.is_visible_in_tree() and visible_rect.has_area(),
		"%s non visibile nel viewport" % label)
	assert(visible_rect.size.x >= minf(control.size.x, 24.0) and visible_rect.size.y >= minf(control.size.y, 24.0),
		"%s ha un'area cliccabile insufficiente" % label)
