extends SceneTree

## Catture riproducibili dei pilot personaggio. Non decide se sono belli: rende
## però possibile giudicare gerarchia, ingombri e leggibilità senza attraversare
## otto mondi a ogni iterazione.

const OUTPUT := "res://../artifacts/character-minigames"

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _cattura("tobia-tablet-landscape.png", PileMinigamePanel.new(), "w01-tobia", Vector2i(1024, 600))
	await _cattura("tobia-tablet-portrait.png", PileMinigamePanel.new(), "w01-tobia", Vector2i(600, 900))
	await _cattura("ersilia-tablet-landscape.png", preload("res://scripts/ui/rhythm_count_panel.gd").new(), "w01-ersilia", Vector2i(1024, 600))
	await _cattura("ersilia-tablet-portrait.png", preload("res://scripts/ui/rhythm_count_panel.gd").new(), "w01-ersilia", Vector2i(600, 900))
	await _cattura("corinna-tablet-landscape.png", ShelfMinigamePanel.new(), "w02-corinna", Vector2i(1024, 600))
	await _cattura("corinna-tablet-portrait.png", ShelfMinigamePanel.new(), "w02-corinna", Vector2i(600, 900))
	await _cattura("ciro-tablet-landscape.png", CircuitMinigamePanel.new(), "w08-ciro", Vector2i(1024, 600), true)
	await _cattura("ciro-tablet-portrait.png", CircuitMinigamePanel.new(), "w08-ciro", Vector2i(600, 900), true)
	await _cattura("gerbo-tablet-landscape.png", LeverMinigamePanel.new(), "w05-gerbo", Vector2i(1024, 600))
	await _cattura("gerbo-tablet-portrait.png", LeverMinigamePanel.new(), "w05-gerbo", Vector2i(600, 900))
	await _cattura("oreste-tablet-landscape.png", preload("res://scripts/ui/vibration_minigame_panel.gd").new(), "w06-oreste", Vector2i(1024, 600))
	await _cattura("oreste-tablet-portrait.png", preload("res://scripts/ui/vibration_minigame_panel.gd").new(), "w06-oreste", Vector2i(600, 900))
	await _cattura("livia-tablet-landscape.png", preload("res://scripts/ui/glyph_minigame_panel.gd").new(), "w07-livia", Vector2i(1024, 600))
	await _cattura("livia-tablet-portrait.png", preload("res://scripts/ui/glyph_minigame_panel.gd").new(), "w07-livia", Vector2i(600, 900))
	await _cattura("zeno-tablet-landscape.png", preload("res://scripts/ui/kinship_minigame_panel.gd").new(), "w07-zeno", Vector2i(1024, 600))
	await _cattura("zeno-tablet-portrait.png", preload("res://scripts/ui/kinship_minigame_panel.gd").new(), "w07-zeno", Vector2i(600, 900))
	# Campioni della copertura completa: non basta che il renderer base stia in
	# pagina; anche titoli, consegne e materiali dei testimoni devono entrarci.
	await _cattura("bruno-tablet-portrait.png", preload("res://scripts/ui/glyph_minigame_panel.gd").new(), "w02-bruno", Vector2i(600, 900))
	await _cattura("doria-tablet-portrait.png", RadioMinigamePanel.new(), "w08-doria", Vector2i(600, 900))
	await _cattura("remo-tablet-portrait.png", preload("res://scripts/ui/trace_minigame_panel.gd").new(), "w09-remo", Vector2i(600, 900))
	await _cattura("vesta-tablet-portrait.png", MarketMinigamePanel.new(), "w11-vesta", Vector2i(600, 900))
	await _cattura("pila-tablet-portrait.png", ControlledTrialMinigamePanel.new(), "w15-pila", Vector2i(600, 900))
	await _cattura("coral-tablet-portrait.png", ShelfMinigamePanel.new(), "w17-coral", Vector2i(600, 900))
	await _cattura("bea-tablet-portrait.png", preload("res://scripts/ui/vibration_minigame_panel.gd").new(), "w18-bea", Vector2i(600, 900))
	await _cattura("fiorina-tablet-portrait.png", preload("res://scripts/ui/kinship_minigame_panel.gd").new(), "w19-fiorina", Vector2i(600, 900))
	print("CHARACTER MINIGAME render probe OK")
	quit()

func _cattura(file_name: String, pannello: Control, npc_id: String, viewport_size: Vector2i, avanza: bool = false) -> void:
	root.size = viewport_size
	root.add_child(pannello)
	pannello.avvia(CharacterMinigameCatalog.scheda(npc_id), false)
	await process_frame
	await process_frame
	if avanza:
		var quadro := pannello.find_child("CircuitBoard", true, false) as CircuitMinigameBoard
		if is_instance_valid(quadro):
			var primo := quadro.find_child("CircuitSwitch_0_%d" % quadro.riga_corretta(0), true, false) as Button
			if is_instance_valid(primo):
				primo.pressed.emit()
				await process_frame
	var immagine := root.get_texture().get_image()
	var errore := immagine.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT, file_name]))
	assert(errore == OK, "impossibile salvare %s" % file_name)
	pannello.queue_free()
	await process_frame
