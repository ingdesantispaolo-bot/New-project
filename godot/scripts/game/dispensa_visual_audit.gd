extends SceneTree

const PLAYER = preload("res://scripts/game/exercise_player.gd")
const FIGURA = preload("res://scripts/game/nora_figura.gd")
const PARADIGMA = preload("res://scripts/ui/teaching_paradigm_grid.gd")
const ALTEZZA_SCHERMATA := 566.0
const MASSIMO_SENZA_FIGURA := 3.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array = []
	var holder := VBoxContainer.new()
	holder.custom_minimum_size = Vector2(820, 0)
	holder.position = Vector2(-2000, 0)
	root.add_child(holder)
	var labels: Dictionary = {}
	for id_data in Dispense.DISPENSE.keys():
		var id := str(id_data)
		var d: Dictionary = (Dispense.DISPENSE[id] as Dictionary).duplicate(true)
		d["id"] = id
		var spec := Dispense.figura_per(d)
		_check(not spec.is_empty(), "%s non dichiara una figura" % id, failures)
		if not spec.is_empty():
			var figure = FIGURA.new()
			figure.mostra(str(spec.get("tipo", "")), Dictionary(spec.get("dati", {})))
			_check(figure.descrizione().strip_edges() != "", "%s ha una figura senza descrizione" % id, failures)
			figure.free()
		var label := Label.new()
		label.text = Dispense.testo_completo(d)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(800, 0)
		holder.add_child(label)
		labels[id] = label
	await process_frame
	await process_frame
	var max_screens := 0.0
	var longest := ""
	for id_data in labels.keys():
		var id := str(id_data)
		var screens := (labels[id] as Label).get_combined_minimum_size().y / ALTEZZA_SCHERMATA
		if screens > max_screens:
			max_screens = screens
			longest = id
		var d: Dictionary = (Dispense.DISPENSE[id] as Dictionary).duplicate(true)
		d["id"] = id
		if screens > MASSIMO_SENZA_FIGURA:
			_check(not Dispense.figura_per(d).is_empty(), "%s occupa %.1f schermate senza figura" % [id, screens], failures)
	holder.queue_free()

	var expected := {
		"coding-condizioni-base":"rientro",
		"geografia-geografia-fisica-alta":"fascia_deserti",
		"geografia-geografia-italia-alta":"placche",
		"scienze-materia-base":"stati_materia",
		"scienze-ecosistema-alta":"piramide_ecologica",
	}
	for id_data in expected.keys():
		var id := str(id_data)
		var d: Dictionary = (Dispense.DISPENSE[id] as Dictionary).duplicate(true)
		d["id"] = id
		_check(str(Dispense.figura_per(d).get("tipo", "")) == str(expected[id]), "%s non usa la figura prevista" % id, failures)

	# C-R6: il legame e' per ID e ogni voce autorata produce esattamente una
	# casella visibile. Non si confronta con un numero globale.
	for dispensa_id_data in Dispense.TAVOLA_PER_DISPENSA.keys():
		var dispensa_id := str(dispensa_id_data)
		var table_id := str(Dispense.TAVOLA_PER_DISPENSA[dispensa_id])
		var table := TavoleRiferimento.tavola_di_id(table_id)
		_check(not table.is_empty(), "%s punta a una tavola inesistente: %s" % [dispensa_id, table_id], failures)
		if table.is_empty(): continue
		_check(str(table.get("kind", "")) == TavoleRiferimento.KIND_PARADIGMA, "%s non e' un paradigma" % table_id, failures)
		var grid = PARADIGMA.new()
		grid.mostra(table)
		var cells := 0
		for child in grid.get_children():
			if str(child.name).begins_with("ParadigmCell_"): cells += 1
		_check(cells == Array(table.get("voci", [])).size(), "%s disegna %d celle per %d voci" % [table_id, cells, Array(table.get("voci", [])).size()], failures)
		_check(grid.descrizione().strip_edges() != "", "%s non descrive la griglia" % table_id, failures)
		grid.free()

	# Percorso reale: la dispensa piu' lunga si apre come passi, mostra una sola
	# pagina alla volta e arriva al CTA solo sull'ultima.
	var lesson := Dispense.lezione("coding", "operatori", 2)
	var player = PLAYER.new()
	root.add_child(player)
	player.start_session({
		"sessionId":"dispensa-visual", "kind":"mission", "subject":"coding",
		"nodes":[{"id":"probe", "subject":"coding", "topic":"operatori", "difficulty":1,
			"format":"multiple_choice", "prompt":"Quanto vale 2 + 3?", "answer":"5", "options":["5","4","6","7"],
			"explanation":"Prima si applica l'operatore.", "teachingLesson":lesson, "teachingMoment":"pre_teach"}],
		"shields":3, "timed":false, "rewards":{"energyPerCorrect":0,"onComplete":{}},
	})
	await process_frame
	await process_frame
	var progress: Label = player.find_child("TeachingProgress", true, false)
	var back: Button = player.find_child("TeachingBackButton", true, false)
	var next: Button = player.find_child("TeachingNextButton", true, false)
	var begin: Button = player.find_child("TeachingStartButton", true, false)
	var teaching_figure: Control = player.find_child("TeachingFigure", true, false)
	_check(progress != null and back != null and next != null and begin != null, "la dispensa non costruisce navigazione e avanzamento", failures)
	_check(teaching_figure != null, "la dispensa reale non costruisce la figura", failures)
	if progress != null and next != null and begin != null:
		var total := int(progress.text.get_slice(" ", 3))
		_check(total >= 4, "la dispensa lunga non e' stata divisa in passi", failures)
		for _i in maxi(0, total - 1): next.pressed.emit()
		await process_frame
		_check(begin.visible and not next.visible, "l'ultima pagina non consegna il CTA finale", failures)
		_check(progress.text == "PASSO %d DI %d" % [total, total], "l'indicatore non raggiunge l'ultimo passo", failures)
	player.queue_free()

	if not failures.is_empty():
		printerr("DISPENSA VISUAL AUDIT ROSSO — %d problemi" % failures.size())
		for failure in failures: printerr("  - %s" % failure)
		quit(1)
		return
	print("Dispensa visual audit OK — %d dispense illustrate, massimo grezzo %.1f schermate (%s), passi e paradigmi per ID" % [Dispense.DISPENSE.size(), max_screens, longest])
	quit(0)

func _check(condition: bool, message: String, failures: Array) -> void:
	if not condition: failures.append(message)

