extends SceneTree

const BIOMES := {
	"ruins": "res://assets/rovine-natural-atlas-v1.png",
	"crystal": "res://assets/cristallo-natural-atlas-v1.png",
}

func _init() -> void:
	for biome in BIOMES:
		var path := str(BIOMES[biome])
		assert(ResourceLoader.exists(path), "atlante %s assente: %s" % [biome, path])
		for kind in ["tree", "bush", "mushroom", "ruin", "pillar", "crystal", "rock"]:
			var prop := OutdoorVisualFactory.build_obstacle(kind, 48.0, 0x8fe0a4, 0.5, biome)
			var sprite := prop.get_child(1) as Sprite2D
			assert(sprite != null and sprite.texture is AtlasTexture,
				"%s/%s senza sprite da atlante" % [biome, kind])
			var atlas := sprite.texture as AtlasTexture
			assert(atlas.atlas.resource_path == path,
				"%s/%s prende ancora un atlante in prestito" % [biome, kind])
			prop.free()
	print("NATURAL ATLAS audit OK — Rovine e Cristallo hanno vocabolari propri")
	quit(0)
