extends SceneTree

const FACTORY := preload("res://scripts/visual_factory.gd")
const WORLD_LIGHT := preload("res://scripts/game/world_light.gd")
const SHEETS: Array[Texture2D] = [
	preload("res://assets/player/eli-scintilla-v1.png"),
	preload("res://assets/player/eli-lampada-v1.png"),
	preload("res://assets/player/eli-faro-v1.png"),
	preload("res://assets/player/eli-aurora-v1.png"),
	preload("res://assets/player/eli-meridiana-v1.png"),
	preload("res://assets/player/eli-grade5-v1.png"),
	preload("res://assets/player/eli-grade6-v1.png"),
	preload("res://assets/player/eli-grade7-v1.png"),
	preload("res://assets/player/eli-grade8-v1.png"),
]

func _init() -> void:
	assert(SHEETS.size() == 9, "Eli deve avere nove forme: base + otto gradi")
	assert(WORLD_LIGHT.SOGLIE.size() <= SHEETS.size(),
		"ogni grado di potenza attivo deve avere uno spritesheet")
	for tier in range(SHEETS.size()):
		var texture := SHEETS[tier]
		assert(texture != null, "spritesheet Eli mancante al grado %d" % tier)
		assert(texture.get_size() == Vector2(480, 384),
			"spritesheet Eli %d non conforme alla griglia 5x4: %s" % [tier, texture.get_size()])
		var sprite := FACTORY.player_sprite(Vector2(84, 84), tier)
		assert(sprite.name == "EliSprite", "il controller non trovera' EliSprite")
		assert(sprite.texture is AtlasTexture, "l'animazione richiede AtlasTexture")
		assert((sprite.texture as AtlasTexture).region == Rect2(0, 0, 96, 96),
			"la cella di animazione deve restare 96x96")
	var base := FACTORY.build_player(Color("6be7d6"), 0)
	var finale := FACTORY.build_player(Color("fff0ae"), 8)
	assert(base.find_child("EliCoreGlow", true, false) != null, "nucleo energia assente")
	assert(finale.find_child("EliCoreGlow", true, false) != null, "nucleo finale assente")
	var marks := FACTORY.build_upgrade_marks([
		"nora-lens", "nora-reserve", "nora-shield", "nora-prismatic-core"])
	assert(marks.get_child_count() == 8, "i quattro potenziamenti devono avere segno e bagliore")
	base.free()
	finale.free()
	marks.free()
	print("ELI_EVOLUTION_AUDIT_OK: 9 forme, griglia 5x4, nucleo energia")
	quit()
