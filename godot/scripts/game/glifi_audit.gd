extends SceneTree

## La bottega non disegna caratteri Unicode: ogni articolo passa dall'atlante
## illustrato. Questo cricchetto copre Web e tablet, dove il ripiego di sistema
## che in sviluppo mascherava i glifi mancanti non esiste.

const ATLAS_DATA := "res://assets/shop/reward-items-sheet.json"

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_DATA))
	assert(typeof(parsed) == TYPE_DICTIONARY, "atlante bottega non leggibile")
	var frames: Dictionary = (parsed as Dictionary).get("frames", {})
	for entry_data in RewardCatalog.CATALOG:
		var entry: Dictionary = entry_data
		var item_id := str(entry.get("id", ""))
		assert(frames.has(item_id), "articolo senza insegna illustrata: %s" % item_id)
	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/outdoor_shop_panel.gd")
	assert(not panel_source.contains("return _tool_fallback_texture"),
		"la bottega non deve ricadere sul glifo di sistema")
	print("GLIFI audit OK - %d articoli disegnati dall'atlante, nessun fallback Unicode" % RewardCatalog.CATALOG.size())
	quit(0)
