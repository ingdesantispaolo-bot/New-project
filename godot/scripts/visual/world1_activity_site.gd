class_name World1ActivitySite
extends Node2D

## Apparato illustrato delle missioni matematiche della Radura. L'immagine
## comunica la funzione del luogo; stato, progresso e completamento restano
## costruiti in Godot, quindi non dipendono da dettagli numerici generati.

const ASSETS := {
	"measure": "res://assets/radura-bilancia-quantita-v1.png",
	"sequence": "res://assets/radura-sentiero-sequenze-v1.png",
	"matching": "res://assets/radura-giardino-abbinamenti-v1.png",
}

var family := "matching"
var completed := false
var reduced_motion := false
var accent := Color("6be7d6")
var apparatus: Sprite2D
var progress_parts: Array[CanvasItem] = []
var completion_halo: Node2D

static func family_for_format(format: String) -> String:
	match format:
		"numeric_input", "graph":
			return "measure"
		"ordering", "code_debug", "cycle":
			return "sequence"
		_:
			return "matching"

static func asset_path_for_format(format: String) -> String:
	return str(ASSETS[family_for_format(format)])

func setup(
	format: String, is_completed: bool, color: Color, use_reduced_motion: bool
) -> void:
	name = "World1ActivitySite"
	family = family_for_format(format)
	completed = is_completed
	accent = color
	reduced_motion = use_reduced_motion
	set_meta("site_family", family)
	set_meta("format", format)
	set_meta("state", "restored" if completed else "waiting")
	add_to_group("world1_activity_site")
	z_index = -2

	var shadow := OutdoorVisualFactory.make_shadow(74, 22, 0.34, 7)
	shadow.name = "SiteShadow"
	shadow.position = Vector2(0, 12)
	add_child(shadow)

	var art_path := str(ASSETS[family])
	var texture := ResourceLoader.load(art_path, "Texture2D") as Texture2D
	if texture != null:
		apparatus = Sprite2D.new()
		apparatus.name = "GeneratedSiteArt"
		apparatus.texture = texture
		apparatus.position = Vector2(0, -48)
		apparatus.scale = Vector2.ONE * 0.115
		add_child(apparatus)
	else:
		# Il luogo resta leggibile e giocabile anche durante un'import incompleto.
		var fallback := OutdoorVisualFactory.build_identity_prop("number_stone", "radura", 0.5)
		fallback.name = "GeneratedSiteFallback"
		fallback.position = Vector2(0, -18)
		fallback.scale = Vector2.ONE * 1.25
		add_child(fallback)

	_build_progress_crystals()
	_build_completion_halo()
	set_progress(5 if completed else 0, 5, false)
	set_complete(completed, false)

func _build_progress_crystals() -> void:
	for index in range(5):
		var part := Node2D.new()
		part.name = "ProgressCrystal%d" % index
		part.position = Vector2(-44.0 + float(index) * 22.0, 30.0)
		part.add_child(OutdoorVisualFactory.make_polygon(
			PackedVector2Array([
				Vector2(0, -9), Vector2(7, -2), Vector2(4, 7),
				Vector2(-4, 7), Vector2(-7, -2),
			]), accent.lightened(0.14)))
		var glow := OutdoorVisualFactory.make_glow(13, accent, 0.68)
		glow.position = Vector2(0, -1)
		glow.add_to_group("night_glow")
		part.add_child(glow)
		progress_parts.append(part)
		add_child(part)

func _build_completion_halo() -> void:
	completion_halo = Node2D.new()
	completion_halo.name = "CompletionHalo"
	completion_halo.position = Vector2(0, 11)
	var ring := OutdoorVisualFactory.make_ring(82, Color(accent, 0.68), 3.0, 34)
	ring.scale = Vector2(1.0, 0.34)
	completion_halo.add_child(ring)
	for side in [-1.0, 1.0]:
		var pennant := OutdoorVisualFactory.make_polygon(PackedVector2Array([
			Vector2(0, -18), Vector2(10.0 * side, -8), Vector2(0, 2),
		]), Color("f6cf65"))
		pennant.position = Vector2(68.0 * side, -7)
		completion_halo.add_child(pennant)
	add_child(completion_halo)

func set_progress(correct: int, total: int, animate: bool = true) -> void:
	var ratio := clampf(float(correct) / maxf(1.0, float(total)), 0.0, 1.0)
	var lit := clampi(roundi(ratio * float(progress_parts.size())), 0, progress_parts.size())
	for index in range(progress_parts.size()):
		progress_parts[index].visible = index < lit
	if apparatus == null or completed:
		return
	var target := Color("b9c8c4").lerp(Color.WHITE, ratio)
	if animate and not reduced_motion and is_inside_tree():
		create_tween().tween_property(apparatus, "modulate", target, 0.22)
	else:
		apparatus.modulate = target

func set_complete(value: bool, animate: bool = true) -> void:
	completed = value
	set_meta("state", "restored" if completed else "waiting")
	if completion_halo != null:
		completion_halo.visible = completed
	if completed:
		for part in progress_parts:
			part.visible = true
	if apparatus == null:
		return
	var base_scale := Vector2.ONE * 0.115
	var target_color := Color.WHITE if completed else Color("b9c8c4")
	if animate and not reduced_motion and is_inside_tree():
		var tween := create_tween().set_parallel(true)
		tween.tween_property(apparatus, "modulate", target_color, 0.34)
		tween.tween_property(apparatus, "scale", base_scale * 1.08, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(apparatus, "scale", base_scale, 0.20)
	else:
		apparatus.modulate = target_color
		apparatus.scale = base_scale
