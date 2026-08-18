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
var npc_art: Sprite2D
var deep_forgotten := false
var _activity_before_deep := ""
var _memory_return_flash := 0.0

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
	var generated_art := PORTRAIT.art_for(id)
	if generated_art != null and get_node_or_null("NpcArt") == null:
		npc_art = Sprite2D.new()
		npc_art.name = "NpcArt"
		npc_art.texture = generated_art
		npc_art.scale = Vector2(0.28, 0.28)
		npc_art.position = Vector2(0, -7)
		npc_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(npc_art)
		set_meta("usesGeneratedArt", true)
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
	# **Il fumetto nasce con la persona.** (16 agosto 2026)
	#
	# Prima veniva costruito dentro `set_activity`, che tocca soltanto chi ha un
	# arco: l'itinerante — l'unico volto ricorrente del viaggio — non aveva dove
	# scrivere, e `show_world_line` gli usciva a vuoto. Un personaggio muto per un
	# dettaglio di costruzione è il difetto peggiore: non lo vedi, lo scambi per
	# carattere.
	_ensure_speech_bubble()

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
	_ensure_speech_bubble()
	set_stream_active(true)
	queue_redraw()

func _ensure_speech_bubble() -> void:
	if get_node_or_null("WorldSpeech") != null:
		return
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

## Il caso profondo di «smemora» non cambia la posa né cancella il gesto di
## occupazione: sovrappone al lavoro un circuito che non arriva più al proprio
## oggetto. Si deve capire attraversando il mondo, prima di aprire una battuta.
func set_deep_forgotten(enabled: bool) -> void:
	if deep_forgotten == enabled:
		return
	deep_forgotten = enabled
	set_meta("deep_forgotten", enabled)
	set_meta("deep_visual_language", [
		"gesto-ripetuto",
		"percorso-di-lavoro-spezzato",
		"oggetto-non-raggiunto",
	] if enabled else [])
	var activity := get_node_or_null("NpcActivity") as Label
	if activity != null:
		if enabled:
			_activity_before_deep = activity.text
			activity.text = "ripete il gesto · non trova lo scopo"
			activity.visible = true
			activity.accessibility_name = "%s continua il gesto di lavoro, ma non ne trova più lo scopo" % display_name
			activity.add_theme_color_override("font_color", Color("ffd078"))
		else:
			activity.text = _activity_before_deep
			activity.visible = not _activity_before_deep.strip_edges().is_empty()
			activity.accessibility_name = "%s: %s" % [display_name, _activity_before_deep]
			activity.add_theme_color_override("font_color", Color("9fded8"))
	set_process(stream_active and (not reduced_motion or enabled))
	queue_redraw()

## Il ritorno ha un segno visuale proprio: il percorso spezzato si chiude per un
## istante prima di sparire. Anche con movimento ridotto resta un fotogramma
## statico leggibile, senza lampeggi.
func play_deep_memory_return() -> void:
	set_deep_forgotten(false)
	_memory_return_flash = 1.0
	set_meta("deep_memory_return_visible", true)
	set_process(stream_active)
	queue_redraw()
	if reduced_motion and is_inside_tree():
		get_tree().create_timer(1.1).timeout.connect(func():
			_memory_return_flash = 0.0
			set_meta("deep_memory_return_visible", false)
			set_process(false)
			queue_redraw()
		)

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
	set_process(active and (not reduced_motion or deep_forgotten or _memory_return_flash > 0.0))

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	set_process(stream_active and (not reduced_motion or deep_forgotten or _memory_return_flash > 0.0))
	if enabled:
		occupation_phase = 0.0
	_update_art_pose()
	queue_redraw()

func _process(delta: float) -> void:
	occupation_phase = fmod(occupation_phase + delta * 2.2, TAU)
	if _memory_return_flash > 0.0 and not reduced_motion:
		_memory_return_flash = maxf(0.0, _memory_return_flash - delta / 1.15)
		if _memory_return_flash <= 0.0:
			set_meta("deep_memory_return_visible", false)
	_update_art_pose()
	queue_redraw()
	if reduced_motion and not deep_forgotten and _memory_return_flash <= 0.0:
		set_process(false)

func _update_art_pose() -> void:
	if not is_instance_valid(npc_art):
		return
	var busy := 0.0 if reduced_motion else sin(occupation_phase) * 2.2
	npc_art.position.y = -7.0 + busy
	npc_art.rotation = 0.0 if reduced_motion else sin(occupation_phase * 0.72) * 0.012

func _draw() -> void:
	var busy := 0.0 if reduced_motion else sin(occupation_phase) * 3.0
	_draw_ground_ellipse(Vector2(0, 42), Vector2(29, 9), Color(0, 0, 0, 0.28))
	if is_instance_valid(npc_art):
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 32, Color(accent, 0.36), 2.0, true)
	else:
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
	if deep_forgotten:
		_draw_deep_forgotten_visual(busy)
	if _memory_return_flash > 0.0:
		_draw_memory_return_visual()

func _draw_deep_forgotten_visual(busy: float) -> void:
	var warning := Color("ffd078")
	var echo := Color(1.0, 0.55, 0.36, 0.46)
	# Lo stesso attrezzo compare due volte lungo lo stesso gesto: il corpo sa
	# ancora ripeterlo, ma la traiettoria gira su se stessa.
	var swing := 0.0 if reduced_motion else sin(occupation_phase * 1.7) * 6.0
	var hand := Vector2(-31, 18 + swing + busy)
	draw_line(hand, hand + Vector2(-18, -15), warning, 5.0, true)
	draw_circle(hand + Vector2(-20, -17), 5.0, Color(0.08, 0.16, 0.18), false, 2.5, true)
	draw_line(hand + Vector2(9, -8), hand + Vector2(-9, -23), echo, 4.0, true)
	# Anello di lavoro volutamente aperto: due frecce affrontate tornano indietro
	# prima dell'oggetto. Non è un'aura generica, è una procedura che non chiude.
	draw_arc(Vector2(0, 4), 59.0, -2.7, -0.35, 20, echo, 4.0, true)
	draw_arc(Vector2(0, 4), 59.0, 0.35, 2.7, 20, echo, 4.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(55, -13), Vector2(43, -18), Vector2(47, -6)]), warning)
	draw_colored_polygon(PackedVector2Array([
		Vector2(55, 21), Vector2(43, 26), Vector2(47, 14)]), warning)
	# Il bersaglio del lavoro resta intero, illuminato e irraggiunto sulla destra.
	draw_rect(Rect2(68, -2, 22, 22), Color(0.04, 0.14, 0.16, 0.92), true)
	draw_rect(Rect2(68, -2, 22, 22), warning, false, 3.0)
	draw_line(Vector2(61, 9), Vector2(67, 9), Color(warning, 0.25), 2.0, true)

func _draw_memory_return_visual() -> void:
	var strength := 1.0 if reduced_motion else _memory_return_flash
	var restored := Color(0.49, 1.0, 0.72, 0.85 * strength)
	draw_arc(Vector2(0, 4), 59.0, 0.0, TAU, 40, restored, 5.0, true)
	draw_line(Vector2(45, 9), Vector2(79, 9), restored, 5.0, true)
	draw_circle(Vector2(79, 9), 7.0, Color(restored, 0.22), true)

func _draw_ground_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
