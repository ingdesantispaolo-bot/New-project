extends SceneTree

## Sonda visuale manuale. Salva viste reali della UI in artifacts/ per la
## revisione di composizione, leggibilita e comportamento responsive.

const OUTPUT_DIR := "res://../artifacts/shop"

func _init() -> void:
	root.size = Vector2i(1440, 900)
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	await process_frame
	gameplay.setup(NativeWorldState.default_request("shop-render"), NativeWorldState.empty_result(), false)

	var host := Control.new()
	host.name = "ShopRenderHost"
	host.size = root.get_visible_rect().size
	root.add_child(host)
	var shop := OutdoorShopPanel.new()
	host.add_child(shop)
	await process_frame
	shop.setup(gameplay)
	shop.open_panel()
	await _settle()
	print("SHOP RENDER wide sizes root=%s shop=%s panel=%s" % [root.size, shop.size, shop.find_child("ShopWindow", true, false).size])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if await _capture("bottega-bit-wide.png") != OK:
		push_error("SHOP RENDER probe: renderer grafico non disponibile")
		quit(2)
		return

	shop.call("_select_slot", "decor")
	shop.call("_select_item", "decor-biblioteca-classica")
	await _settle()
	if await _capture("bottega-restauri-wide.png") != OK:
		quit(2)
		return

	root.size = Vector2i(900, 760)
	await process_frame
	host.size = root.get_visible_rect().size
	shop.call("_select_slot", "pet")
	shop.call("_apply_responsive_layout")
	await _settle()
	print("SHOP RENDER compact sizes root=%s shop=%s panel=%s" % [root.size, shop.size, shop.find_child("ShopWindow", true, false).size])
	if await _capture("bottega-compagni-compact.png") != OK:
		quit(2)
		return
	print("SHOP RENDER probe OK - artifacts/shop")
	quit(0)


func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.12).timeout


func _capture(file_name: String) -> Error:
	# `frame_post_draw` non viene emesso in modo affidabile dal renderer
	# headless; un frame di SceneTree e sufficiente dopo `_settle`, come nel
	# probe del terreno gia usato dalla pipeline.
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		return ERR_UNAVAILABLE
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name])
	return image.save_png(path)
