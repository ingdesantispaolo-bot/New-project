class_name EquipmentGate
extends Node2D

## Segnaletica e barriera fisica per deviazioni opzionali legate agli strumenti.
## La falce rimuove l'anello d'erba; la torcia rivela il POI senza introdurre
## collisioni invisibili. La scena aggiorna tutti i gate al cambio equip.

var required_tool := ""
var equipped_tool := ""
var blocker: StaticBody2D
var label: Label

func configure(required: String, equipped: String = "") -> void:
	required_tool = required
	equipped_tool = equipped
	add_to_group("equipment_gate")
	if required_tool == "tool-scythe":
		_build_grass_blocker()
	_build_label()
	_apply_state()
	queue_redraw()

func set_equipped_tool(value: String) -> void:
	equipped_tool = value
	_apply_state()
	queue_redraw()

func is_open() -> bool:
	return required_tool == "" or required_tool == equipped_tool

func _build_grass_blocker() -> void:
	blocker = StaticBody2D.new()
	blocker.name = "TallGrassBlocker"
	for index in range(10):
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		shape.position = Vector2.RIGHT.rotated(TAU * float(index) / 10.0) * 50.0
		blocker.add_child(shape)
	add_child(blocker)

func _build_label() -> void:
	label = Label.new()
	label.name = "EquipmentRequirement"
	label.position = Vector2(-46, 48)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override(
		"font_color",
		Color("ffc76b") if required_tool == "tool-torch" else Color("b9f58b"))
	add_child(label)

func _apply_state() -> void:
	var open := is_open()
	if is_instance_valid(blocker):
		for child in blocker.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", open)
	if is_instance_valid(label):
		label.text = (
			"PASSAGGIO APERTO"
			if open
			else "SERVE TORCIA" if required_tool == "tool-torch"
			else "SERVE FALCE"
		)
		label.modulate.a = 0.58 if open else 1.0

func _draw() -> void:
	var open := is_open()
	if required_tool == "tool-torch":
		draw_circle(Vector2.ZERO, 74.0, Color(0.025, 0.035, 0.075, 0.16 if open else 0.72))
		draw_arc(Vector2.ZERO, 64.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.42, 0.72), 3.0, true)
		for index in range(6):
			var point := Vector2.RIGHT.rotated(TAU * float(index) / 6.0) * 55.0
			draw_circle(point, 3.0, Color(1.0, 0.75, 0.34, 0.86 if open else 0.38))
		return
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		var radius := 49.0 + sin(float(index) * 2.17) * 6.0
		var base := Vector2.RIGHT.rotated(angle) * radius
		var height := 7.0 if open else 25.0 + float(index % 4) * 3.0
		var color := Color(0.45, 0.72, 0.28, 0.38 if open else 0.95)
		draw_line(base, base + Vector2(0, -height), color, 4.0, true)
