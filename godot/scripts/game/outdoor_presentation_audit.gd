extends SceneTree

## Audit della parte Codex sui blocchi C-14/C-15: bottega presente e filtrabile,
## overlay chiudibile con ESC e ritratto NORA collegato al feedback.

func _init() -> void:
	var packed := load("res://scenes/outdoor_world.tscn") as PackedScene
	assert(packed != null, "scena outdoor assente")
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var shop: Control = scene.get("shop_panel")
	var portrait: Control = scene.get("nora_portrait")
	var feedback_panel: Control = scene.get("feedback_panel")
	var player: CharacterBody2D = scene.get("player")
	var gameplay: OutdoorGameplay = scene.get("gameplay")
	assert(shop != null and portrait != null and feedback_panel != null, "presentazione C-14/C-15 incompleta")
	assert(scene.find_child("OpenShopButton", true, false) != null, "pulsante bottega assente")
	scene.call("_open_shop")
	await process_frame
	assert(shop.visible, "la bottega non si apre")
	assert(get_nodes_in_group("shop_item_card").size() == RewardCatalog.by_slot("bot").size(), "catalogo bot non renderizzato")
	assert(gameplay.try_purchase_cosmetic("bot-lime"), "acquisto UI di prova fallito")
	await process_frame
	assert(str(gameplay.runtime_state()["cosmeticsEquipped"].get("bot", "")) == "bot-lime", "equip bot non applicato")
	assert((portrait.get("_accent") as Color).is_equal_approx(OutdoorVisualFactory.hex_color(0x7cf6a6)), "livrea NORA non aggiornata live")
	shop.call("_select_slot", "pet")
	await process_frame
	await process_frame
	assert(get_nodes_in_group("shop_item_card").size() == RewardCatalog.by_slot("pet").size(), "filtro pet incompleto")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	assert(not shop.visible, "ESC non chiude la bottega")
	assert(player.is_physics_processing(), "movimento non ripristinato dopo la bottega")
	scene.call("_set_feedback", "Metodo pronto: osserva, scegli, verifica.")
	await process_frame
	assert(feedback_panel.visible and portrait.visible, "NORA non accompagna la battuta")
	assert(portrait.get("_speech") > 0.0, "ritratto NORA non animato")
	print("OUTDOOR PRESENTATION audit OK - bottega C-14 e NORA C-15")
	quit(0)
