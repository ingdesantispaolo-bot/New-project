extends SceneTree

## C-G4: la scena disegna numeri pubblicati dal runtime, senza conoscere
## acquisti o regole. Verifica anche che i cinque moduli abbiano vere regioni
## nell'atlante premi e che i tre gia' in vendita non usino piu' il glifo di
## ripiego.

const PRESENTATION := preload("res://scripts/visual/expedition_module_presentation.gd")
const SHOP := preload("res://scripts/ui/outdoor_shop_panel.gd")
const MODULE_ART_IDS := [
	"module-tank",
	"module-coil",
	"module-stride",
	"module-radar",
	"module-torch",
]


func _treasure(host: Node2D, id: String, position: Vector2) -> Area2D:
	var area := Area2D.new()
	area.name = id
	area.position = position
	area.set_meta("kind", "treasure")
	area.set_meta("id", id)
	area.add_to_group("world_interactable")
	host.add_child(area)
	return area


func _init() -> void:
	var source := FileAccess.get_file_as_string(
		"res://scripts/visual/expedition_module_presentation.gd")
	assert(not source.contains("ExpeditionModules"),
		"la resa ricalcola gli effetti dei moduli invece di leggere il runtime")
	assert(not source.contains("RewardCatalog"),
		"la resa legge il catalogo invece del contratto runtime")
	assert(not source.contains("create_tween") and not source.contains("AnimationPlayer"),
		"radar o cono dipendono da animazioni non necessarie alla lettura")

	var shop := SHOP.new()
	shop.call("_load_atlas_regions")
	for id in MODULE_ART_IDS:
		var texture = shop.call("_item_texture", id)
		assert(texture is AtlasTexture, "illustrazione modulo fuori atlante: %s" % id)
		assert((texture as AtlasTexture).region.size == Vector2(128, 128),
			"regione atlante non valida: %s" % id)
	shop.free()

	var host := Node2D.new()
	root.add_child(host)
	var player := OutdoorPlayerController.new()
	player.name = "AuditPlayer"
	host.add_child(player)
	var near := _treasure(host, "chest-near", Vector2(120, 0))
	var far := _treasure(host, "chest-far", Vector2(280, 0))
	var presentation := PRESENTATION.new()
	host.add_child(presentation)
	presentation.setup(player)
	await process_frame

	# Contratto assente/zero: nessuna promessa visiva anticipa la semantica.
	presentation.apply_runtime({}, "tool-torch", [])
	var cone := player.get_node_or_null(PRESENTATION.TORCH_CONE_NAME) as PointLight2D
	assert(cone != null and cone.texture != null, "cono torcia non costruito")
	assert(not cone.visible, "cono visibile senza torchRadius pubblicato")
	var dormant_marker := near.get_node_or_null(PRESENTATION.MARKER_NAME) as Node2D
	assert(dormant_marker == null or not dormant_marker.visible,
		"radar visibile senza treasureRadarRadius pubblicato")

	# La scena applica esattamente i numeri ricevuti: uno dentro, uno fuori.
	presentation.apply_runtime({
		PRESENTATION.TREASURE_RADAR_KEY: 180.0,
		PRESENTATION.TORCH_RADIUS_KEY: 232.0,
	}, "tool-torch", [])
	assert((near.get_node(PRESENTATION.MARKER_NAME) as Node2D).visible,
		"cassa chiusa entro il raggio non segnalata sulla mappa")
	assert(not (far.get_node(PRESENTATION.MARKER_NAME) as Node2D).visible,
		"cassa fuori raggio segnalata dal radar")
	assert(cone.visible, "cono non visibile con torcia equipaggiata e raggio positivo")
	assert(is_equal_approx(cone.texture_scale, 232.0 / PRESENTATION.CONE_TEXTURE_RADIUS),
		"il cono non scala dal numero torchRadius")

	# Una cassa raccolta sparisce dal radar; disequipaggiare la torcia spegne solo
	# la luce e non altera nessun numero.
	presentation.apply_runtime({
		PRESENTATION.TREASURE_RADAR_KEY: 180.0,
		PRESENTATION.TORCH_RADIUS_KEY: 232.0,
	}, "", ["chest-near"])
	assert(not (near.get_node(PRESENTATION.MARKER_NAME) as Node2D).visible,
		"cassa gia' raccolta ancora segnalata")
	assert(not cone.visible, "cono acceso senza torcia equipaggiata")

	player.set("_facing_row", OutdoorPlayerController.FACING_LEFT_ROW)
	presentation.call("_update_torch_direction")
	assert(is_equal_approx(cone.rotation, PI), "cono non orientato con lo sguardo di Eli")

	print("EXPEDITION MODULE PRESENTATION audit VERDE - radar, cono e 5 illustrazioni runtime-only")
	quit(0)
