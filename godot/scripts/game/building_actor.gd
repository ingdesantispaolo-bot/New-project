class_name BuildingActor
extends Node2D

const RESIDENT_CONSEQUENCE_VISUAL := preload("res://scripts/visual/resident_consequence_visual.gd")

var building_id := ""
var role := ""
var stage := 0
var high_contrast := false
var reduced_motion := false
var visual: Node2D
var window_glows: Array[CanvasItem] = []
var resident_owner := ""
var resident_consequence: Node2D
var generated_art := false

## Quanto largo e' l'ingresso di un edificio. Piu' generoso di un POI (88): un
## edificio e' grande, e doverne cercare il punto esatto trasforma un luogo in
## un bersaglio.
const RAGGIO_INGRESSO := 120.0

## **Gli edifici diventano luoghi.** (6 agosto 2026)
##
## Fino a oggi erano scenografia: `building_actor` impostava i metadati ma non
## entrava mai nel gruppo `world_interactable` e non aveva un'area di
## collisione. I settantadue nomi propri scritti poche ore prima si potevano
## leggere e basta.
##
## Ogni ruolo ha adesso una funzione, e non e' decorativa:
##
##   work_home    la casa del mestiere: il minigioco della materia del mondo, a
##                costo d'energia RIDOTTO. Allenarsi dove si lavora costa meno
##                che in mezzo al campo, ed e' anche il modo di dire a un
##                bambino a che cosa serve quell'edificio;
##   ritrovo      dove la gente si incontra: le conversazioni degli abitanti e
##                la BOTTEGA. Si compra in piazza, non da un menu;
##   first_ruin   cio' che i Primi hanno lasciato: un frammento di trama, non un
##                esercizio. Le ventiquattro rovine messe in fila raccontano che
##                qualcuno e' passato di qui prima.
func _rendi_luogo(spec: Dictionary) -> void:
	var area := Area2D.new()
	area.name = "BuildingDoor"
	area.set_meta("kind", "building")
	area.set_meta("id", building_id)
	area.set_meta("building_role", role)
	area.set_meta("label", str(spec.get("label", "")))
	area.set_meta("activity_tags", Array(spec.get("activityTags", [])).duplicate())
	area.set_meta("payload", {
		"role": role,
		"label": str(spec.get("label", "")),
		"world": int(spec.get("world", 1)),
	})
	var forma := CollisionShape2D.new()
	forma.name = "BuildingCollision"
	var cerchio := CircleShape2D.new()
	cerchio.radius = RAGGIO_INGRESSO
	forma.shape = cerchio
	area.add_child(forma)
	area.add_to_group("world_interactable")
	add_child(area)

func configure(spec: Dictionary, world_stage: int, use_high_contrast: bool, use_reduced_motion: bool) -> void:
	building_id = str(spec.get("id", "building"))
	role = str(spec.get("role", "work_home"))
	resident_owner = str(spec.get("residentOwner", ""))
	high_contrast = use_high_contrast
	reduced_motion = use_reduced_motion
	name = "Building_%s" % building_id.replace("-", "_")
	set_meta("building_id", building_id)
	set_meta("building_role", role)
	set_meta("resident_owner", resident_owner)
	set_meta("artKit", str(spec.get("artKit", "")))
	set_meta("activity_tags", Array(spec.get("activityTags", [])).duplicate())
	add_to_group("world_building")
	_rendi_luogo(spec)

	if role == "first_ruin":
		visual = Node2D.new()
		visual.name = "FirstRuinVisual"
		add_child(visual)
		_build_ruin_visual(visual)
	elif _build_generated_visual(spec):
		generated_art = true
		set_meta("generated_art", true)
	else:
		visual = OutdoorVisualFactory.build_academy_pavilion()
		visual.name = "PavilionVisual"
		visual.scale = Vector2.ONE * (1.12 if role == "ritrovo" else 1.0)
		add_child(visual)
		if role == "ritrovo":
			var fountain := OutdoorVisualFactory.build_academy_fountain()
			fountain.name = "RitrovoFountain"
			fountain.position = Vector2(0, 72)
			visual.add_child(fountain)

	var label := Label.new()
	label.name = "BuildingLabel"
	label.text = str(spec.get("label", "Edificio"))
	label.position = Vector2(-120, 88 if role == "ritrovo" else 34 if generated_art else 50)
	label.size = Vector2(240, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE if high_contrast else Color("ffe7a0"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.accessibility_name = label.text
	add_child(label)

	_collect_window_glows(self)
	if RESIDENT_CONSEQUENCE_VISUAL.supports(resident_owner):
		resident_consequence = RESIDENT_CONSEQUENCE_VISUAL.new()
		resident_consequence.position = Vector2(154, 28) if role == "work_home" else Vector2(-154, 32)
		resident_consequence.call("configure", resident_owner, world_stage, high_contrast, reduced_motion)
		add_child(resident_consequence)
	set_stage(world_stage)

## Asset illustrati e logica restano separati: l'immagine decide silhouette e
## atmosfera; porta, hit-area, materia, costo e sessione continuano a essere
## nodi Godot. Se un file manca, `false` riattiva il padiglione vettoriale senza
## rendere il mondo non giocabile.
func _build_generated_visual(spec: Dictionary) -> bool:
	var art_path := str(spec.get("artPath", ""))
	if art_path.is_empty() or not ResourceLoader.exists(art_path):
		return false
	var texture := ResourceLoader.load(art_path, "Texture2D") as Texture2D
	if texture == null:
		return false
	visual = Node2D.new()
	visual.name = "GeneratedBuildingVisual"
	var sprite := Sprite2D.new()
	sprite.name = "GeneratedBuildingArt"
	sprite.texture = texture
	sprite.scale = Vector2.ONE * float(spec.get("artScale", 0.16))
	sprite.position = Vector2(0, float(spec.get("artBaseline", -82.0)))
	visual.add_child(sprite)
	add_child(visual)

	var prop_path := str(spec.get("activityPropPath", ""))
	if not prop_path.is_empty() and ResourceLoader.exists(prop_path):
		var prop_texture := ResourceLoader.load(prop_path, "Texture2D") as Texture2D
		if prop_texture != null:
			var prop := Sprite2D.new()
			prop.name = "GeneratedActivityProp"
			prop.texture = prop_texture
			prop.scale = Vector2.ONE * float(spec.get("activityPropScale", 0.11))
			prop.position = spec.get("activityPropOffset", Vector2(150, -18))
			visual.add_child(prop)
	return true

func set_stage(value: int) -> void:
	stage = clampi(value, 0, 3)
	for index in window_glows.size():
		window_glows[index].visible = stage >= 2 or (stage >= 1 and index == 0)
	if is_instance_valid(visual):
		# Lo stato iniziale è un luogo normale, non un edificio spento dato in
		# punizione. Gli stadi successivi aggiungono calore e luce senza fare del
		# punto zero una versione peggiore del mondo.
		visual.modulate = Color(0.88, 0.90, 0.92) if stage == 0 else Color(0.96, 0.97, 0.98) if stage == 1 else Color.WHITE
	if is_instance_valid(resident_consequence):
		resident_consequence.call("set_stage", stage)
	queue_redraw()

func _collect_window_glows(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem and child.is_in_group("night_glow"):
			window_glows.append(child as CanvasItem)
		_collect_window_glows(child)

func _build_ruin_visual(root: Node2D) -> void:
	root.add_child(OutdoorVisualFactory.make_shadow(82, 20, 0.30, 10))
	for data in [
		{"p": Vector2(-48, 12), "s": Vector2(24, 58), "r": -0.12},
		{"p": Vector2(0, -2), "s": Vector2(28, 82), "r": 0.05},
		{"p": Vector2(47, 16), "s": Vector2(22, 50), "r": 0.16},
	]:
		var stone := Polygon2D.new()
		var size: Vector2 = data["s"]
		stone.polygon = PackedVector2Array([
			Vector2(-size.x * 0.5, size.y * 0.5), Vector2(-size.x * 0.42, -size.y * 0.5),
			Vector2(size.x * 0.38, -size.y * 0.46), Vector2(size.x * 0.5, size.y * 0.5),
		])
		stone.color = Color("77817b")
		stone.position = data["p"]
		stone.rotation = float(data["r"])
		root.add_child(stone)
	var glow := OutdoorVisualFactory.make_glow(36, Color("8ff6c0"), 0.34)
	glow.name = "RuinWindowGlow"
	glow.position = Vector2(0, -34)
	glow.add_to_group("night_glow")
	root.add_child(glow)
