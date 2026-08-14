class_name ExpeditionModulePresentation
extends Node

## Resa dei moduli di spedizione che hanno bisogno della scena outdoor.
##
## Questo nodo non conosce inventario, prezzi o potenziamenti. Consuma soltanto
## due numeri gia' risolti dal contratto runtime: un raggio radar e la lunghezza
## del cono della torcia. Zero significa "nessuna resa" e mantiene entrambi i
## consumer dormienti finche' la semantica non pubblica il relativo effetto.

const TREASURE_RADAR_KEY := "treasureRadarRadius"
const TORCH_RADIUS_KEY := "torchRadius"
const TORCH_TOOL_ID := "tool-torch"
const MARKER_NAME := "TreasureRadarMarker"
const TORCH_CONE_NAME := "PlayerTorchCone"
const RADAR_REFRESH_SECONDS := 0.25
const CONE_TEXTURE_RADIUS := 116.0

var _player: OutdoorPlayerController
var _radar_radius := 0.0
var _torch_radius := 0.0
var _torch_equipped := false
var _radar_elapsed := 0.0
var _collected_treasure_ids: Array = []
var _torch_cone: PointLight2D


func setup(player: OutdoorPlayerController) -> void:
	_player = player
	_build_torch_cone()
	_apply_torch_cone()


func apply_runtime(state: Dictionary, equipped_tool: String, collected_ids: Array = []) -> void:
	_radar_radius = maxf(0.0, float(state.get(TREASURE_RADAR_KEY, 0.0)))
	_torch_radius = maxf(0.0, float(state.get(TORCH_RADIUS_KEY, 0.0)))
	_torch_equipped = equipped_tool == TORCH_TOOL_ID
	_collected_treasure_ids = collected_ids.duplicate()
	_apply_torch_cone()
	refresh_treasure_markers()


func _process(delta: float) -> void:
	_update_torch_direction()
	_radar_elapsed += delta
	if _radar_elapsed >= RADAR_REFRESH_SECONDS:
		_radar_elapsed = 0.0
		refresh_treasure_markers()


func refresh_treasure_markers() -> void:
	if not is_instance_valid(_player) or not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("world_interactable"):
		if not (node is Area2D) or str(node.get_meta("kind", "")) != "treasure":
			continue
		var treasure := node as Area2D
		if _radar_radius <= 0.0:
			var dormant := treasure.get_node_or_null(MARKER_NAME) as Node2D
			if dormant != null:
				dormant.visible = false
			continue
		var marker := _ensure_treasure_marker(treasure)
		var treasure_id := str(treasure.get_meta("id", ""))
		marker.visible = (
			not _collected_treasure_ids.has(treasure_id)
			and _player.global_position.distance_to(treasure.global_position) <= _radar_radius
		)


func _ensure_treasure_marker(treasure: Area2D) -> Node2D:
	var existing := treasure.get_node_or_null(MARKER_NAME) as Node2D
	if existing != null:
		return existing
	var marker := Node2D.new()
	marker.name = MARKER_NAME
	marker.position = Vector2(0, -54)
	marker.z_index = 95
	marker.add_to_group("treasure_radar_marker")
	marker.visible = false

	var diamond := Polygon2D.new()
	diamond.name = "SignalDiamond"
	diamond.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(13, 0), Vector2(0, 13), Vector2(-13, 0),
	])
	diamond.color = Color("102f39")
	marker.add_child(diamond)

	var outline := Line2D.new()
	outline.name = "SignalOutline"
	outline.width = 3.0
	outline.default_color = Color("8ff6d2")
	outline.closed = true
	outline.points = PackedVector2Array([
		Vector2(0, -13), Vector2(13, 0), Vector2(0, 13), Vector2(-13, 0),
	])
	marker.add_child(outline)

	var core := Polygon2D.new()
	core.name = "SignalCore"
	core.polygon = PackedVector2Array([
		Vector2(-3, -4), Vector2(4, 0), Vector2(-3, 4),
	])
	core.color = Color("fff1b8")
	marker.add_child(core)

	for spec in [
		{"points": [Vector2(-20, -11), Vector2(-25, 0), Vector2(-20, 11)], "alpha": 0.82},
		{"points": [Vector2(20, -11), Vector2(25, 0), Vector2(20, 11)], "alpha": 0.82},
	]:
		var wave := Line2D.new()
		wave.width = 2.5
		wave.default_color = Color(0.56, 0.96, 0.82, float(spec["alpha"]))
		wave.points = PackedVector2Array(spec["points"])
		marker.add_child(wave)

	treasure.add_child(marker)
	return marker


func _build_torch_cone() -> void:
	if not is_instance_valid(_player) or is_instance_valid(_torch_cone):
		return
	var image := Image.new()
	var svg := """
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
<defs>
  <radialGradient id="beam" cx="128" cy="128" r="116" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#fff4c2" stop-opacity="0.92"/>
    <stop offset="0.52" stop-color="#ffd778" stop-opacity="0.48"/>
    <stop offset="1" stop-color="#9bdff2" stop-opacity="0"/>
  </radialGradient>
</defs>
<path d="M128 128 L238 69 Q250 128 238 187 Z" fill="url(#beam)"/>
</svg>
"""
	if image.load_svg_from_string(svg, 1.0) != OK:
		push_error("Cono torcia non costruibile")
		return
	_torch_cone = PointLight2D.new()
	_torch_cone.name = TORCH_CONE_NAME
	_torch_cone.texture = ImageTexture.create_from_image(image)
	_torch_cone.energy = 0.92
	_torch_cone.blend_mode = PointLight2D.BLEND_MODE_ADD
	_torch_cone.shadow_enabled = false
	_torch_cone.visible = false
	_player.add_child(_torch_cone)


func _apply_torch_cone() -> void:
	if not is_instance_valid(_torch_cone):
		return
	_torch_cone.visible = _torch_equipped and _torch_radius > 0.0
	_torch_cone.texture_scale = _torch_radius / CONE_TEXTURE_RADIUS if _torch_radius > 0.0 else 0.01
	_update_torch_direction()


func _update_torch_direction() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_torch_cone):
		return
	match int(_player.get("_facing_row")):
		OutdoorPlayerController.FACING_UP_ROW:
			_torch_cone.rotation = -PI / 2.0
		OutdoorPlayerController.FACING_RIGHT_ROW:
			_torch_cone.rotation = 0.0
		OutdoorPlayerController.FACING_LEFT_ROW:
			_torch_cone.rotation = PI
		_:
			_torch_cone.rotation = PI / 2.0
