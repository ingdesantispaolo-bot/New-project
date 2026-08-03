class_name ArtifactAtlasCatalog
extends RefCounted

## Catalogo runtime degli atlanti illustrati condivisi. I contenuti nominano
## soltanto asset e bersagli semantici; percorsi e coordinate restano qui.

const ATLASES := {
	"roman_artifacts": {
		"image": "res://assets/exercises/history-artifacts-atlas-v1.webp",
		"targets": {
			"aqueduct": Vector2(0.125, 0.50),
			"column": Vector2(0.375, 0.50),
			"amphora": Vector2(0.625, 0.50),
			"mosaic": Vector2(0.875, 0.50),
		},
	},
}

static func has_atlas(atlas_id: String) -> bool:
	return ATLASES.has(atlas_id)

static func atlas_data(atlas_id: String) -> Dictionary:
	return (ATLASES.get(atlas_id, {}) as Dictionary).duplicate(true)

static func has_target(atlas_id: String, target_id: String) -> bool:
	var atlas := ATLASES.get(atlas_id, {}) as Dictionary
	return (atlas.get("targets", {}) as Dictionary).has(target_id)
