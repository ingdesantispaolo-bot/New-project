extends SceneTree

const WORLD := preload("res://scripts/outdoor_world.gd")

func _init() -> void:
	var world := WORLD.new()
	var label := Label.new()
	var button := Button.new()
	world.set("etichetta_cariche_impulso", label)
	world.set("pulse_button", button)
	world.set("runtime", {"pulseCharges": 2, "pulseChargeMax": 3})
	world.call("_aggiorna_cariche_impulso")
	assert(label.visible and label.text.contains("◆ ◆ ◇") and label.text.contains("2/3"),
		"cariche non rese accanto alla barra di potenza")
	assert(button.text == "IMPULSO\n2 CARICHE", "il pulsante mostra ancora un cronometro")
	world.set("runtime", {"pulseCharges": 0, "pulseChargeMax": 3})
	world.call("_aggiorna_cariche_impulso")
	assert(button.text == "IMPULSO\n0 CARICHE" and button.disabled,
		"stato senza cariche non leggibile")
	print("PULSE HUD audit OK - celle accanto alla potenza e conteggio sul pulsante")
	quit(0)
