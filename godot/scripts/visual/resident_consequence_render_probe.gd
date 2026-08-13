extends SceneTree

## Sei catture riproducibili dei due luoghi reali del mondo 1 ai tre stadi.
## La tavola isola gli edifici dal costo dello streaming: qui si giudicano
## gerarchia, leggibilità e continuità del cambiamento, non il paesaggio.

const BUILDING_ACTOR := preload("res://scripts/game/building_actor.gd")
const OUTPUT := "res://../artifacts/resident-consequences"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1024, 600)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var background := ColorRect.new()
	background.color = Color("315c55")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var specs := BuildingCatalog.for_world(1, WorldProfileCatalog.profile(1))
	for owner_data in ["w01-tobia", "w01-ersilia"]:
		var owner := str(owner_data)
		var spec: Dictionary = {}
		for candidate_data in specs:
			var candidate: Dictionary = candidate_data
			if str(candidate.get("residentOwner", "")) == owner:
				spec = candidate
				break
		assert(not spec.is_empty(), "luogo non trovato per %s" % owner)
		for stage in [0, 1, 2]:
			var building: Node2D = BUILDING_ACTOR.new()
			building.call("configure", spec, stage, false, true)
			building.position = Vector2(512, 300)
			building.scale = Vector2.ONE * 1.25
			root.add_child(building)
			await process_frame
			await process_frame
			var short_name: String = owner.trim_prefix("w01-")
			var path := ProjectSettings.globalize_path("%s/%s-stage-%d.png" % [OUTPUT, short_name, stage])
			var error := root.get_texture().get_image().save_png(path)
			assert(error == OK, "cattura fallita: %s" % path)
			building.free()
	await process_frame
	print("RESIDENT CONSEQUENCE render probe OK — 6 catture")
	quit(0)
