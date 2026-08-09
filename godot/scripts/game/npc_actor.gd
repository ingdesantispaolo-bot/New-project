class_name NpcActor
extends Area2D

## Presenza visuale leggera. Testi e carattere arrivano da NpcCatalog; questo
## nodo conosce soltanto identità, collisione e animazione di occupazione.

const PORTRAIT := preload("res://scripts/ui/npc_portrait.gd")

var npc_id := ""
var display_name := ""
var role := ""
var reduced_motion := false
var stream_active := true
var occupation_phase := 0.0
var accent := Color("6be7d6")

func configure(id: String, data: Dictionary, use_reduced_motion: bool = false) -> void:
	npc_id = id
	display_name = str(data.get("nome", id))
	role = str(data.get("ruolo", "abitante"))
	reduced_motion = use_reduced_motion
	accent = PORTRAIT._accent_for(id)
	name = "Npc_%s" % id.replace("-", "_")
	set_meta("kind", "npc")
	set_meta("id", id)
	set_meta("payload", {"label": display_name, "role": role})
	add_to_group("world_interactable")
	add_to_group("npc_actor")
	if get_node_or_null("NpcCollision") == null:
		var collision := CollisionShape2D.new()
		collision.name = "NpcCollision"
		var circle := CircleShape2D.new()
		circle.radius = 54.0
		collision.shape = circle
		add_child(collision)
	if get_node_or_null("NpcName") == null:
		var label := Label.new()
		label.name = "NpcName"
		label.text = display_name
		label.position = Vector2(-82, 48)
		label.size = Vector2(164, 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("e9fffa"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.accessibility_name = "%s, %s" % [display_name, role]
		add_child(label)
	# **Che cosa sta facendo**, sotto il nome. (8 agosto 2026)
	#
	# Finora il cambiamento di un personaggio si leggeva solo parlandoci:
	# attraversando il mondo, chi aveva capito e chi non aveva capito erano
	# identici. Tre parole bastano a farlo vedere da lontano — e la scelta di
	# quali tre sta in `NpcArc.ATTIVITA`, dove c'e' anche il motivo per cui sono
	# generiche.
	if get_node_or_null("NpcActivity") == null:
		var attivita := Label.new()
		attivita.name = "NpcActivity"
		attivita.text = ""
		attivita.position = Vector2(-82, 70)
		attivita.size = Vector2(164, 22)
		attivita.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attivita.add_theme_font_size_override("font_size", 11)
		attivita.add_theme_color_override("font_color", Color("9fded8"))
		attivita.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		attivita.add_theme_constant_override("shadow_offset_x", 2)
		attivita.add_theme_constant_override("shadow_offset_y", 2)
		add_child(attivita)

## Che cosa il bambino vede fare a questo personaggio, adesso. Vuoto = niente da
## dire, e allora non si scrive niente: una riga vuota sotto il nome sarebbe
## rumore, non informazione.
func set_activity(testo: String) -> void:
	var riga := get_node_or_null("NpcActivity") as Label
	if riga == null:
		return
	riga.text = testo
	riga.visible = not testo.strip_edges().is_empty()
	if riga.visible:
		riga.accessibility_name = "%s: %s" % [display_name, testo]
	if get_node_or_null("WorldSpeech") == null:
		var bubble := Label.new()
		bubble.name = "WorldSpeech"
		bubble.position = Vector2(-145, -132)
		bubble.size = Vector2(290, 76)
		bubble.visible = false
		bubble.z_index = 12
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bubble.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bubble.add_theme_font_size_override("font_size", 15)
		bubble.add_theme_color_override("font_color", Color("effffc"))
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color(0.025, 0.105, 0.12, 0.94)
		panel.border_color = Color(accent, 0.9)
		panel.set_border_width_all(2)
		panel.set_corner_radius_all(12)
		panel.content_margin_left = 10
		panel.content_margin_right = 10
		panel.content_margin_top = 7
		panel.content_margin_bottom = 7
		bubble.add_theme_stylebox_override("normal", panel)
		add_child(bubble)
	set_stream_active(true)
	queue_redraw()

func show_world_line(text: String) -> void:
	var bubble := get_node_or_null("WorldSpeech") as Label
	if bubble == null:
		return
	bubble.text = text
	bubble.accessibility_name = "%s dice: %s" % [display_name, text]
	bubble.visible = true

func hide_world_line() -> void:
	var bubble := get_node_or_null("WorldSpeech") as Label
	if bubble != null:
		bubble.visible = false

func set_high_contrast(enabled: bool) -> void:
	var bubble := get_node_or_null("WorldSpeech") as Label
	var label := get_node_or_null("NpcName") as Label
	if label != null:
		label.add_theme_color_override("font_color", Color.WHITE if enabled else Color("e9fffa"))
	if bubble == null:
		return
	var panel := bubble.get_theme_stylebox("normal") as StyleBoxFlat
	if panel != null:
		panel.bg_color = Color(0, 0, 0, 0.98) if enabled else Color(0.025, 0.105, 0.12, 0.94)
		panel.border_color = Color.WHITE if enabled else Color(accent, 0.9)

func set_stream_active(active: bool) -> void:
	stream_active = active
	visible = active
	monitoring = active
	monitorable = active
	set_process(active and not reduced_motion)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	set_process(stream_active and not reduced_motion)
	if enabled:
		occupation_phase = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	occupation_phase = fmod(occupation_phase + delta * 2.2, TAU)
	queue_redraw()

func _draw() -> void:
	var busy := 0.0 if reduced_motion else sin(occupation_phase) * 3.0
	_draw_ground_ellipse(Vector2(0, 42), Vector2(29, 9), Color(0, 0, 0, 0.28))
	draw_circle(Vector2(0, 10 + busy), 28.0, Color(accent, 0.88))
	draw_circle(Vector2(0, -24 + busy), 21.0, Color("f2c6a0"))
	draw_arc(Vector2(0, -25 + busy), 20.0, PI, TAU, 20, accent.darkened(0.5), 8.0, true)
	draw_circle(Vector2(-7, -26 + busy), 2.6, Color("10272b"))
	draw_circle(Vector2(7, -26 + busy), 2.6, Color("10272b"))
	# Piccolo gesto di occupazione: le mani lavorano, senza spostare il target.
	var hand_swing := 0.0 if reduced_motion else sin(occupation_phase * 1.7) * 7.0
	draw_line(Vector2(-18, 6 + busy), Vector2(-31, 22 + hand_swing), Color("f2c6a0"), 7.0, true)
	draw_line(Vector2(18, 6 + busy), Vector2(31, 22 - hand_swing), Color("f2c6a0"), 7.0, true)
	draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 32, Color(accent, 0.42), 2.0, true)

func _draw_ground_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
