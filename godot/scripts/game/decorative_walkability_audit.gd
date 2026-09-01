extends SceneTree

## La scenografia puo' coprire Eli in y-sort, ma non puo' fermarla. Le sole
## collisioni fisiche del mondo devono comunicare una regola: costa, cancello,
## sbarramento, camera chiusa o nemico.

func _init() -> void:
	var composition := WorldCompositionData.new()
	composition.visual_theme = "archive"
	composition.biome_influences = [{
		"biome": "academy", "position": Vector2(448, 448), "radius": 1800.0,
	}]
	composition.identity_props = [{
		"kind": "archive_shelf", "position": Vector2(560, 520), "variant": 0.5,
	}]
	var chunk := {
		"id": "walkability-audit", "chunkX": 0, "chunkY": 0,
		"worldX": 0, "worldY": 0, "size": 896, "biome": "academy",
		"patch": {}, "pathPoints": [], "props": [], "treasures": [],
		"landmarks": [], "encounters": [],
		"obstacles": [{
			"id": "decorative-tree", "kind": "tree", "x": 300, "y": 360,
			"r": 42, "color": 0x426f4a,
		}],
	}
	var visual := OutdoorChunkVisual.new()
	root.add_child(visual)
	visual.configure(chunk, null, 0, composition)

	var decorative_bodies := visual.find_children("*", "StaticBody2D", true, false)
	assert(decorative_bodies.size() == 1,
		"la decorazione procedurale ha ancora corpi fisici inattesi: %d" % decorative_bodies.size())
	var identity_body := decorative_bodies[0] as StaticBody2D
	assert(identity_body.name == "PassThroughDecoration", "il corpo residuo non e' dichiarato scenografico")
	assert(identity_body.collision_layer == 0 and identity_body.collision_mask == 0,
		"un prop identitario puo' ancora urtare Eli")
	var collision := identity_body.get_child(0) as CollisionShape2D
	assert(collision.disabled, "l'impronta grafica del prop e' ancora attiva nella fisica")

	print("DECORATIVE WALKABILITY audit OK - alberi, rocce e prop attraversabili")
	quit()
