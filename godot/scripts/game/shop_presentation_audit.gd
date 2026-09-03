extends SceneTree

## Audit mirato della Bottega del Relitto: verifica atlante, catalogo, dettaglio,
## filtri e fallback compatto senza dipendere dal resto della scena outdoor.

const SHOP_SLOTS := ["bot", "avatar", "accessory", "memento", "module", "pet", "emblem", "upgrade", "decor"]

func _shop_items() -> Array:
	var items: Array = []
	for cosmetic in RewardCatalog.CATALOG:
		if str(cosmetic.get("slot", "")) in SHOP_SLOTS:
			items.append(cosmetic)
	return items

func _init() -> void:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	await process_frame
	gameplay.setup(NativeWorldState.default_request("shop-audit"), NativeWorldState.empty_result(), false)

	var host := Control.new()
	host.name = "ShopAuditHost"
	host.size = root.get_visible_rect().size
	root.add_child(host)
	var shop := OutdoorShopPanel.new()
	host.add_child(shop)
	await process_frame
	shop.setup(gameplay)
	shop.open_panel()
	await process_frame
	await process_frame

	assert(shop.visible, "la bottega non si apre")
	assert(shop.size.x > 0.0 and shop.size.y > 0.0, "pannello non dimensionato rispetto all'host HUD")
	var source := FileAccess.get_file_as_string("res://assets/shop/reward-items-sheet.json")
	var atlas: Dictionary = JSON.parse_string(source)
	var frames: Dictionary = atlas.get("frames", {})
	var shop_items := _shop_items()
	assert(frames.size() == shop_items.size(),
		"atlante ricompense non coincide con la vetrina: %d celle per %d articoli" % [frames.size(), shop_items.size()])
	var regions := {}
	for cosmetic in shop_items:
		var item_id := str(cosmetic.get("id", ""))
		assert(frames.has(item_id), "cella atlante assente per l'articolo esposto: %s" % item_id)
		assert(shop.call("_item_texture", item_id) != null,
			"illustrazione ricompensa assente: %s" % item_id)
		var frame: Dictionary = Dictionary(frames[item_id]).get("frame", {})
		var region_key := "%s:%s:%s:%s" % [frame.get("x", -1), frame.get("y", -1), frame.get("w", -1), frame.get("h", -1)]
		assert(not regions.has(region_key), "due articoli esposti condividono la stessa illustrazione: %s" % item_id)
		regions[region_key] = item_id
	for item_id in frames:
		var cosmetic := RewardCatalog.find(str(item_id))
		assert(not cosmetic.is_empty() and str(cosmetic.get("slot", "")) in SHOP_SLOTS,
			"arte generata senza articolo esposto: %s" % item_id)
	assert(not frames.has("tool-torch") and not frames.has("tool-scythe"),
		"gli strumenti consegnati dal mondo non devono occupare l'atlante della bottega")
	assert(get_nodes_in_group("shop_item_card").size() == RewardCatalog.by_slot("bot").size(), "catalogo Bit incompleto")
	assert(get_nodes_in_group("shop_item_thumbnail").size() == RewardCatalog.by_slot("bot").size(), "illustrazioni Bit incomplete")
	var preview := shop.find_child("ShopDetailPreview", true, false) as TextureRect
	var action := shop.find_child("ShopDetailAction", true, false) as Button
	assert(preview != null and preview.texture != null, "anteprima selezionata assente")
	assert(action != null and not action.text.is_empty(), "azione di dettaglio assente")
	shop.call("_select_slot", "tool")
	await process_frame
	assert(get_nodes_in_group("shop_item_card").size() == FieldTools.ids().size(),
		"la scheda strumenti non mostra tutti e cinque gli attrezzi")
	for tool_data in FieldTools.ids():
		var tool_id := str(tool_data)
		assert(shop.call("_item_texture", tool_id) != null,
			"lo strumento non ha un'illustrazione informativa: %s" % tool_id)
		assert(FieldTools.come_si_ottiene(tool_id).contains("mondo %d" % FieldTools.mondo_di(tool_id)),
			"la scheda non indica dove ottenere %s" % tool_id)
	var tool_action := shop.find_child("ShopDetailAction", true, false) as Button
	assert(tool_action != null and tool_action.disabled and tool_action.text.contains("MONDO"),
		"la bottega presenta ancora lo strumento come acquisto o non ne indica la provenienza")
	var state_with_no_fragments: Dictionary = gameplay.runtime_state()
	state_with_no_fragments["fragments"] = 0
	state_with_no_fragments["energy"] = 999999
	shop.set("_state", state_with_no_fragments)
	assert(shop.call("_requirement_color", RewardCatalog.find("bot-lime")) == Color("ef9a87"),
		"la bottega deve colorare il costo in base ai frammenti, non all'energia")

	shop.call("_select_slot", "conquest")
	await process_frame
	assert(get_nodes_in_group("shop_item_card").size() == 24,
		"la collezione non mostra un Ricordo per ciascun mondo")
	shop.call("_select_item", "memento-24-prisma-sintesi")
	await process_frame
	assert(str(shop.get("_selected_id")) == "memento-24-prisma-sintesi",
		"l'ultimo Ricordo non e' selezionabile")

	shop.call("_select_slot", "pet")
	await process_frame
	assert(get_nodes_in_group("shop_item_card").size() == RewardCatalog.by_slot("pet").size(), "filtro compagni incompleto")
	shop.call("_select_item", "pet-codex")
	await process_frame
	assert(str(shop.get("_selected_id")) == "pet-codex", "selezione premio non persistita")
	assert((preview.texture as AtlasTexture).region.size == Vector2(128, 128), "regione atlante non valida")

	root.size = Vector2i(900, 760)
	await process_frame
	host.size = root.get_visible_rect().size
	await process_frame
	shop.call("_apply_responsive_layout")
	assert((shop.get("_items") as GridContainer).columns == 1, "catalogo compatto non passa a una colonna")
	assert(not (shop.get("_detail_pane") as Control).visible, "dettaglio desktop visibile in modalita compatta")
	var panel := shop.find_child("ShopWindow", true, false) as Control
	assert(panel.size.x <= shop.size.x and panel.size.y <= shop.size.y, "finestra bottega oltre i limiti del viewport compatto")

	print("SHOP PRESENTATION audit OK - atlante %d premi, 5 strumenti informativi, dettaglio e layout compatto" % shop_items.size())
	quit(0)
