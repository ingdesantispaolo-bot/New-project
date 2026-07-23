class_name WorldLearningReaction
extends Node2D

## Trasformazione ambientale collegata a un evento didattico. Riceve soltanto
## avanzamento/correttezza dal consumer visuale: non calcola mastery, ricompense
## o completamenti.

var active_parts: Array[CanvasItem] = []
var completed := false
var transform_semantics: Dictionary = {}

func setup(
	theme: String,
	event_kind: String,
	accent: Color,
	semantics: Dictionary = {}
) -> void:
	name = "LearningReaction"
	z_index = -1
	transform_semantics = semantics.duplicate(true)
	set_meta("transform_trigger", str(transform_semantics.get("trigger", "")))
	set_meta("transform_effect", str(transform_semantics.get("effect", "")))
	var base := OutdoorVisualFactory.make_ring(49, Color(accent.darkened(0.45), 0.48), 2.0, 28)
	base.scale = Vector2(1.0, 0.42)
	base.position = Vector2(0, 10)
	add_child(base)
	match theme:
		"archive":
			_build_archive(event_kind, accent)
		"crater":
			_build_crater(event_kind, accent)
		"signal_bay":
			_build_signal_bay(event_kind, accent)
		"motion_forge":
			_build_motion_forge(event_kind, accent)
		"resonance_garden":
			_build_resonance_garden(event_kind, accent)
		"glyph_ruins":
			_build_glyph_ruins(event_kind, accent)
		"circuit_delta":
			_build_circuit_delta(event_kind, accent)
		_:
			_build_radure(event_kind, accent)
	set_progress(0, active_parts.size(), false)

func _build_radure(event_kind: String, accent: Color) -> void:
	for index in range(5):
		var angle := lerpf(-2.72, -0.42, float(index) / 4.0)
		var part := Node2D.new()
		part.position = Vector2(cos(angle) * 46.0, sin(angle) * 19.0 + 6.0)
		var stem := Line2D.new()
		stem.points = PackedVector2Array([Vector2(0, 8), Vector2(0, -10)])
		stem.width = 2.4
		stem.default_color = Color("7fd98a")
		part.add_child(stem)
		part.add_child(OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(0, -14), Vector2(9, -6), Vector2(0, 1), Vector2(-9, -6)]),
			accent.lightened(0.16)))
		var glow := OutdoorVisualFactory.make_glow(15, accent, 0.66)
		glow.position = Vector2(0, -8)
		glow.add_to_group("night_glow")
		part.add_child(glow)
		OutdoorVisualFactory.attach_anim(glow, "pulse", 0.75 + float(index) * 0.13, 0.55)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.10

func _build_archive(event_kind: String, accent: Color) -> void:
	# Le risposte ricompongono una breve passerella di pagine, leggibile anche
	# senza testo e distinta dalla vegetazione della Radura.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-42.0 + float(index) * 21.0, 5.0 + sin(float(index) * 1.7) * 5.0)
		var page := OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(-9, -7), Vector2(9, -6), Vector2(8, 7), Vector2(-9, 6)]),
			Color("e8dfc5"))
		page.rotation = (float(index) - 2.0) * 0.055
		part.add_child(page)
		var ink := Line2D.new()
		ink.points = PackedVector2Array([Vector2(-5, -2), Vector2(4, -2), Vector2(1, 2)])
		ink.width = 1.4
		ink.default_color = Color(accent, 0.82)
		part.add_child(ink)
		var glow := OutdoorVisualFactory.make_glow(14, accent, 0.52)
		glow.add_to_group("night_glow")
		part.add_child(glow)
		OutdoorVisualFactory.attach_anim(glow, "pulse", 0.82 + float(index) * 0.10, 0.50)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.12

func _build_crater(event_kind: String, accent: Color) -> void:
	# Ogni passaggio corretto chiude un nodo del circuito: una sequenza visiva
	# leggibile, coerente con il tema coding, senza dipendere da testo o colore.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-44.0 + float(index) * 22.0, 8.0 + float(index % 2) * 6.0)
		if index > 0:
			var trace := Line2D.new()
			trace.points = PackedVector2Array([Vector2(-22, -float(index % 2) * 6.0), Vector2.ZERO])
			trace.width = 3.0
			trace.default_color = Color(accent, 0.78)
			part.add_child(trace)
		var socket := OutdoorVisualFactory.make_ring(9.0, Color("c4866c"), 2.5, 16)
		socket.scale.y = 0.70
		part.add_child(socket)
		var node_glow := OutdoorVisualFactory.make_glow(13, accent, 0.82)
		node_glow.add_to_group("night_glow")
		part.add_child(node_glow)
		OutdoorVisualFactory.attach_anim(node_glow, "pulse", 0.72 + float(index) * 0.12, 0.64)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.14

func _build_signal_bay(event_kind: String, accent: Color) -> void:
	# Le risposte accendono una catena di boe/messaggi e propagano il segnale.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-45.0 + float(index) * 22.5, 7.0 + sin(float(index) * 1.25) * 5.0)
		var buoy := OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(-6, 5), Vector2(-4, -7), Vector2(0, -12), Vector2(4, -7), Vector2(6, 5)]),
			Color("d47b66"))
		part.add_child(buoy)
		var lamp := OutdoorVisualFactory.make_glow(12, accent.lightened(0.16), 0.86)
		lamp.position = Vector2(0, -12)
		lamp.add_to_group("night_glow")
		part.add_child(lamp)
		var wave := OutdoorVisualFactory.make_ring(15, Color(accent, 0.45), 1.6, 20)
		wave.scale.y = 0.38
		wave.position = Vector2(0, -10)
		part.add_child(wave)
		OutdoorVisualFactory.attach_anim(wave, "pulse", 0.66 + float(index) * 0.11, 0.52)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.14

func _build_motion_forge(event_kind: String, accent: Color) -> void:
	# Ogni esito sposta un carrello lungo una rampa: il moto diventa una
	# conseguenza ambientale osservabile, non una semplice spia colorata.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-45.0 + float(index) * 22.5, 9.0 - float(index) * 3.0)
		var rail := Line2D.new()
		rail.points = PackedVector2Array([Vector2(-11, 5), Vector2(11, -1)])
		rail.width = 3.0
		rail.default_color = Color("9b7652")
		part.add_child(rail)
		var cart := OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(-8, -9), Vector2(8, -9), Vector2(7, 1), Vector2(-7, 1)]),
			Color("c66f48"))
		part.add_child(cart)
		var force_glow := OutdoorVisualFactory.make_glow(12, accent, 0.76)
		force_glow.position = Vector2(0, -8)
		force_glow.add_to_group("night_glow")
		part.add_child(force_glow)
		OutdoorVisualFactory.attach_anim(force_glow, "pulse", 0.74 + float(index) * 0.11, 0.62)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.14

func _build_resonance_garden(event_kind: String, accent: Color) -> void:
	# I boccioli si accordano progressivamente e propagano cerchi sonori.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-44.0 + float(index) * 22.0, 7.0 + sin(float(index) * 1.5) * 5.0)
		for petal_index in range(4):
			var angle := TAU * float(petal_index) / 4.0
			var petal := OutdoorVisualFactory.make_polygon(
				OutdoorVisualFactory.ellipse_polygon(7, 3.5, 12),
				accent.lightened(0.10),
				Vector2(cos(angle) * 7, sin(angle) * 5 - 7))
			petal.rotation = angle
			part.add_child(petal)
		var wave := OutdoorVisualFactory.make_ring(15, Color(accent, 0.42), 1.8, 22)
		wave.scale.y = 0.36
		wave.position = Vector2(0, -7)
		part.add_child(wave)
		OutdoorVisualFactory.attach_anim(wave, "pulse", 0.68 + float(index) * 0.12, 0.58)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.14

func _build_glyph_ruins(event_kind: String, accent: Color) -> void:
	# Le tessere ricompongono un fregio astratto, senza simulare testo latino.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-44.0 + float(index) * 22.0, 7.0)
		var tile := OutdoorVisualFactory.make_polygon(
			PackedVector2Array([Vector2(-9, -10), Vector2(9, -10), Vector2(8, 8), Vector2(-8, 8)]),
			Color("b78b5d"))
		part.add_child(tile)
		var mark := Line2D.new()
		mark.points = PackedVector2Array([
			Vector2(-5, -4), Vector2(4, -6), Vector2(-1, 0), Vector2(5, 4),
		])
		mark.width = 2.0
		mark.default_color = Color(accent, 0.92)
		part.add_child(mark)
		var glyph_glow := OutdoorVisualFactory.make_glow(13, accent, 0.48)
		glyph_glow.add_to_group("night_glow")
		part.add_child(glyph_glow)
		OutdoorVisualFactory.attach_anim(glyph_glow, "pulse", 0.80 + float(index) * 0.10, 0.52)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.14

func _build_circuit_delta(event_kind: String, accent: Color) -> void:
	# Ogni nodo chiude un ramo del circuito, con alternanza forma/altezza utile
	# anche in assenza di colore.
	for index in range(5):
		var part := Node2D.new()
		part.position = Vector2(-44.0 + float(index) * 22.0, 7.0 + float(index % 2) * 7.0)
		if index > 0:
			var trace := Line2D.new()
			trace.points = PackedVector2Array([Vector2(-22, -float(index % 2) * 7.0), Vector2.ZERO])
			trace.width = 3.0
			trace.default_color = Color("bc7b48")
			part.add_child(trace)
		var socket := OutdoorVisualFactory.make_ring(9.5, Color("50c9c4"), 2.7, 16)
		socket.scale.y = 0.62
		part.add_child(socket)
		var charge := OutdoorVisualFactory.make_glow(13, accent.lightened(0.14), 0.86)
		charge.add_to_group("night_glow")
		part.add_child(charge)
		OutdoorVisualFactory.attach_anim(charge, "pulse", 0.70 + float(index) * 0.13, 0.66)
		active_parts.append(part)
		add_child(part)
	if event_kind == "enigma":
		scale = Vector2.ONE * 1.14

func set_progress(value: int, total: int, animate: bool = true) -> void:
	var ratio := clampf(float(value) / maxf(float(total), 1.0), 0.0, 1.0)
	var visible_count := ceili(ratio * float(active_parts.size()))
	for index in range(active_parts.size()):
		var part := active_parts[index]
		var should_show := index < visible_count
		if should_show and not part.visible and animate:
			part.visible = true
			part.modulate = Color(1, 1, 1, 0)
			part.scale = Vector2.ONE * 0.35
			var tween := create_tween().set_parallel(true)
			tween.tween_property(part, "modulate:a", 1.0, 0.28)
			tween.tween_property(part, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			part.visible = should_show
	completed = ratio >= 0.999

func set_complete(value: bool, animate: bool = false) -> void:
	set_progress(active_parts.size() if value else 0, active_parts.size(), animate)
