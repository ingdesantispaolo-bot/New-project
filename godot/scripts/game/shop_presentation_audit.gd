extends SceneTree

## Audit mirato della Bottega del Relitto: verifica atlante, catalogo, dettaglio,
## filtri e fallback compatto senza dipendere dal resto della scena outdoor.

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
	assert((shop.get("_atlas_regions") as Dictionary).size() == RewardCatalog.CATALOG.size(), "atlante ricompense incompleto")
	assert(get_nodes_in_group("shop_item_card").size() == RewardCatalog.by_slot("bot").size(), "catalogo Bit incompleto")
	assert(get_nodes_in_group("shop_item_thumbnail").size() == RewardCatalog.by_slot("bot").size(), "illustrazioni Bit incomplete")
	var preview := shop.find_child("ShopDetailPreview", true, false) as TextureRect
	var action := shop.find_child("ShopDetailAction", true, false) as Button
	assert(preview != null and preview.texture != null, "anteprima selezionata assente")
	assert(action != null and not action.text.is_empty(), "azione di dettaglio assente")

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

	print("SHOP PRESENTATION audit OK - atlante %d premi, dettaglio e layout compatto" % RewardCatalog.CATALOG.size())
	quit(0)
