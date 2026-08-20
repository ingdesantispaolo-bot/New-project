extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const SHADER_PATH := "res://shaders/world_atmosphere.gdshader"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(ResourceLoader.exists(SHADER_PATH), "shader atmosfera condiviso assente")
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("atmosphere-shader-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	var material := world.get("atmosphere_material") as ShaderMaterial
	assert(material != null and material.shader.resource_path == SHADER_PATH,
		"il mondo non usa lo shader atmosfera condiviso")
	assert(is_zero_approx(float(material.get_shader_parameter("motion_factor"))),
		"riduzione movimento non congela la foschia shader")
	root.remove_child(world)
	world.queue_free()
	await process_frame
	print("ATMOSPHERE SHADER audit OK — shader condiviso e foschia statica con movimento ridotto")
	quit(0)
