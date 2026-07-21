extends Node2D

## Nave · Sala Apparati (C-06). Scena funzionale: mostra l'apparato del livello,
## avvia l'esame finale reale (ExercisePlayer) quando il gate è pronto, ripara e
## sale di livello. La riparazione resta in ProgressionManager; la UI non concede
## nulla. La navigazione live mondo↔nave sul percorso Web dipende dalla rimozione
## del bridge (Fase 4): qui la scena è pienamente giocabile in autonomia.

const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")

var controller: HubController
var content: ContentManager
var save: GameSaveManager
var exercise_player: ExercisePlayer
var ui_layer: CanvasLayer
var title: Label
var status: Label
var repair_button: Button

func _ready() -> void:
	controller = HubController.new()
	add_child(controller)
	save = GameSaveManager.new()
	save.load_save()
	controller.setup(save)
	controller.state_changed.connect(_apply_state)
	controller.exam_requested.connect(_start_exam)
	content = ContentManager.new()
	_build_scene()
	_build_exercise_overlay()
	_apply_state(controller.state())

func _build_scene() -> void:
	add_child(OutdoorVisualFactory.build_ship_room_backdrop("academy", Color("6be7d6")))
	var apparatus := OutdoorVisualFactory.build_apparatus_terminal("broken", Color("6be7d6"), "APPARATO")
	apparatus.position = Vector2(0, 25)
	add_child(apparatus)
	var panel := PanelContainer.new()
	panel.position = Vector2(-230, -190)
	panel.custom_minimum_size = Vector2(460, 140)
	panel.add_theme_stylebox_override("panel", VisualAccessibility.outline_style(Color(0.02, 0.10, 0.12, 0.94), Color("6be7d6"), 2))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	title = Label.new()
	title.text = "NAVE · SALA APPARATI"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)
	repair_button = Button.new()
	repair_button.text = "Avvia esame finale"
	repair_button.pressed.connect(_request_exam)
	box.add_child(repair_button)
	var back_button := Button.new()
	back_button.text = "Torna al mondo"
	back_button.pressed.connect(_return_to_world)
	box.add_child(back_button)

func _build_exercise_overlay() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	exercise_player = EXERCISE_PLAYER_SCRIPT.new()
	exercise_player.name = "ExercisePlayer"
	exercise_player.visible = false
	exercise_player.session_finished.connect(_on_exam_finished)
	ui_layer.add_child(exercise_player)

func _apply_state(state: Dictionary) -> void:
	if not is_instance_valid(status):
		return
	status.text = "Livello %d · Materia %s\nApparato %s · %s" % [
		int(state.get("level", 1)), str(state.get("subject", "matematica")).capitalize(),
		str(state.get("apparatus", "nucleo")).replace("-", " ").capitalize(),
		"PRONTO alla riparazione" if bool(state.get("ready", false)) else "servono più missioni all'esterno"]
	repair_button.disabled = not bool(state.get("ready", false))

func _request_exam() -> void:
	controller.request_exam()  # emette exam_requested se il gate è pronto → _start_exam

func _start_exam() -> void:
	var gate := controller.progression.current_gate()
	var subject := str(gate.get("subject", "matematica"))
	var session := content.build_final_exam(subject, save.level())
	if Array(session.get("nodes", [])).is_empty():
		status.text += "\nBanco esame non disponibile per %s." % subject
		return
	exercise_player.visible = true
	exercise_player.start_session(session)

func _on_exam_finished(exam_result: Dictionary) -> void:
	exercise_player.visible = false
	if bool(exam_result.get("passed", false)):
		controller.progression.repair_and_advance(true)
		save.save()
	controller.refresh()

func _return_to_world() -> void:
	save.save()
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")
