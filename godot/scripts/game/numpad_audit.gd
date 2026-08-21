extends SceneTree

## Cricchetto del percorso numerico touch: la risposta deve poter essere composta
## senza tastiera fisica né tastiera virtuale del browser.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var export_preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert(export_preset.contains("html/experimental_virtual_keyboard=true"),
		"l'export Web non abilita il ponte verso la tastiera virtuale")
	var player := preload("res://scripts/game/exercise_player.gd").new()
	root.add_child(player)
	await process_frame
	player.start_session({
		"kind": "mission", "subject": "matematica", "shields": 3,
		"nodes": [{"format": "numeric_input", "prompt": "Quanto fa 6 × 8?", "answer": "48"}],
		"rewards": {"energyPerCorrect": 1, "onComplete": {}},
	})
	var numpad: GridContainer = player._numpad
	assert(numpad != null and numpad.visible, "il tastierino non compare su numeric_input")
	var keys: Array = []
	for child in numpad.get_children():
		var button := child as Button
		keys.append(button.text)
		assert(button.custom_minimum_size.y >= 44.0, "tasto numerico troppo piccolo per il touch")
	for expected in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "−", ",", "«", "C", "OK"]:
		assert(keys.has(expected), "tasto numerico assente: %s" % expected)
	assert(player._input != null and player._input.virtual_keyboard_type == LineEdit.KEYBOARD_TYPE_NUMBER,
		"il campo non richiede la tastiera numerica di sistema")
	player._input.text = ""
	for key in ["4", "2", "«", "8"]:
		player._numpad_press(key)
	assert(player._input.text == "48", "il tastierino non compone/cancella correttamente")
	player._numpad_press("−")
	player._numpad_press(",")
	player._numpad_press("5")
	assert(player._input.text == "-48,5", "segno o decimale non inseribile")
	assert(player._answer_is_numeric("-48,5") and player._answer_is_numeric("0.25"))
	assert(not player._answer_is_numeric("48 ghiande"), "il tastierino coprirebbe una risposta testuale")
	player.start_session({
		"kind": "mission", "subject": "italiano", "shields": 3,
		"nodes": [{"format": "text_input", "prompt": "Scrivi il soggetto.", "answer": "Nocciola"}],
		"rewards": {"energyPerCorrect": 1, "onComplete": {}},
	})
	assert(not player._numpad.visible, "il tastierino numerico copre una risposta testuale")
	assert(player._input.virtual_keyboard_type == LineEdit.KEYBOARD_TYPE_DEFAULT,
		"la risposta testuale riceve ancora la tastiera numerica")
	print("Numpad audit OK — risposta numerica touch indipendente dal browser")
	quit(0)
