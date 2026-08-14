extends SceneTree

const LAYOUT := preload("res://scripts/ui/minigame_panel_layout.gd")
const PANELS := [
	"circuit", "controlled_trial", "cycle", "estimate", "glyph", "kinship",
	"lever", "market", "pile", "radio", "rhythm_count", "seesaw", "shelf",
	"trace", "vibration",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Il comportamento condiviso morde davvero in portrait.
	root.size = Vector2i(720, 1080)
	var owner := Control.new()
	var card := Control.new()
	card.size = Vector2(120, 80)
	owner.add_child(card)
	root.add_child(owner)
	await LAYOUT.adapt_vertical(owner, card, 1.6)
	assert(card.pivot_offset == Vector2(60, 40), "pivot portrait non centrato")
	assert(card.scale.is_equal_approx(Vector2.ONE * 1.6), "scala portrait non applicata")

	# Tutti i pannelli, inclusi radio e mercato, passano dall'unico helper.
	for panel_name in PANELS:
		var path := "res://scripts/ui/%s_minigame_panel.gd" % panel_name
		if panel_name == "rhythm_count":
			path = "res://scripts/ui/rhythm_count_panel.gd"
		var file := FileAccess.open(path, FileAccess.READ)
		assert(file != null, "pannello mancante: %s" % path)
		var source := file.get_as_text()
		assert("MinigamePanelLayout.adapt_vertical" in source,
			"%s non usa l'adattamento condiviso" % panel_name)
		assert("func _adatta_verticale" not in source,
			"%s mantiene una copia locale dell'adattamento" % panel_name)

	print("MINIGAME VERTICAL LAYOUT audit OK - 15 pannelli, una funzione condivisa")
	quit(0)
