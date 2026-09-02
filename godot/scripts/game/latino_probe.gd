extends SceneTree

## Sonda usa e getta: stampa che cosa vede davvero un bambino al primo incontro
## con il latino — i nodi che il gioco costruisce ai livelli bassi e la scheda
## che NORA apre prima di chiedere.
##
## Uso: godot --headless --path godot --script res://scripts/game/latino_probe.gd

func _init() -> void:
	var gameplay := OutdoorGameplay.new()
	gameplay.content_manager = ContentManager.new()
	gameplay.game_save = GameSaveManager.new("user://latino-probe.json")
	for level in [1, 3, 7, 14]:
		print("\n================ LIVELLO %d ================" % level)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + level
		var sessione: Dictionary = gameplay.content_manager.build_varied_mission(
			"latino", level, 4, {}, rng, -1.0, {})
		sessione = gameplay._decorate_teaching_session(sessione, "latino")
		for nodo_data in Array(sessione.get("nodes", [])):
			var nodo: Dictionary = nodo_data
			print("\n--- [%s · d%d · %s]" % [
				str(nodo.get("topic", "")), int(nodo.get("difficulty", 0)),
				str(nodo.get("format", ""))])
			var lezione: Dictionary = nodo.get("teachingLesson", {})
			if not lezione.is_empty():
				print("  NORA: %s" % str(nodo.get("teachingLine", "")))
				print("  intro: %s" % str(lezione.get("intro", "")))
				print("  spiega: %s" % str(lezione.get("explanation", "")))
				var fatti := str(lezione.get("facts", ""))
				if fatti != "":
					print("  %s:" % str(lezione.get("factsTitle", "")))
					for riga in fatti.split("\n"):
						print("    %s" % riga)
				print("  metodo: %s" % str(lezione.get("strategy", "")))
			print("  DOMANDA: %s" % str(nodo.get("prompt", "")))
			for opzione in Array(nodo.get("options", [])):
				print("     - %s" % str(opzione))
			print("  risposta: %s" % str(nodo.get("answer", "")))
	quit(0)
