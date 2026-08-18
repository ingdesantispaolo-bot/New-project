extends SceneTree

## Misura l'errore visivo introdotto dal ramo `identity_dominant`.
##
## Il ramo salta gli otto campionamenti dei bioma quando la tavola identitaria
## copre quasi tutto il colore: e' un'approssimazione deliberata, quindi va
## quantificata, non solo guardata. La sonda renderizza lo stesso mondo due
## volte — con il ramo attivo e con il percorso completo — e salva le due
## immagini per il confronto pixel a pixel.
##
##   Godot --path godot --rendering-driver opengl3 --script scripts/game/identity_branch_probe.gd

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
## Mondo 13 (Deserto delle Orbite): identity_strength 0.96, cioe' sopra soglia e
## rappresentativo del gruppo piu' numeroso.
const LEVEL := 13
const OUT_DIR := "user://identity_branch"

func _init() -> void:
	call_deferred("_run")

func _request() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 24
	initial["worlds"] = {"unlocked": range(1, 25), "current": LEVEL}
	var request := NativeWorldState.default_request("identity-branch-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = LEVEL
	return request

## Raccoglie i materiali del terreno, che sono quelli che portano l'uniform.
func _ground_materials(node: Node, found: Array) -> Array:
	var canvas := node as CanvasItem
	if canvas != null and canvas.material is ShaderMaterial:
		var shader_material := canvas.material as ShaderMaterial
		if shader_material.shader != null and shader_material.get_shader_parameter("identity_tex") != null:
			found.append(shader_material)
	for child in node.get_children():
		_ground_materials(child, found)
	return found

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, label]
	image.save_png(path)
	print("catturato %s -> %s" % [label, ProjectSettings.globalize_path(path)])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", _request())
	root.add_child(world)
	for _i in range(12):
		await process_frame

	var materials := _ground_materials(world, [])
	print("materiali terreno trovati: %d" % materials.size())
	var dominant := 0
	for material in materials:
		if bool(material.get_shader_parameter("identity_dominant")):
			dominant += 1
	print("con identity_dominant attivo: %d/%d" % [dominant, materials.size()])
	assert(dominant > 0, "il mondo %d dovrebbe attivare il ramo: soglia o valori cambiati" % LEVEL)

	await _capture("con-ramo")

	# Stesso frame, stessa camera: cambia solo il percorso dello shader.
	for material in materials:
		material.set_shader_parameter("identity_dominant", false)
	await _capture("senza-ramo")

	quit(0)
