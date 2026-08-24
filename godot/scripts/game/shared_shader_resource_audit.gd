extends SceneTree

## C-ART-12: gli shader di resa sono risorse riusabili, non stringhe nascoste
## nei consumer. Le varianti di colore e progresso restano uniform del runtime.

const SHADERS := [
	"res://shaders/painterly_ground.gdshader",
	"res://shaders/painterly_water.gdshader",
	"res://shaders/natural_wind.gdshader",
	"res://shaders/world_atmosphere.gdshader",
	"res://shaders/ship_room.gdshader",
	"res://shaders/hud_vignette.gdshader",
]
const HUB_SCENE := preload("res://scripts/hub_scene.gd")

func _init() -> void:
	for path in SHADERS:
		assert(ResourceLoader.exists(path), "shader condiviso assente: %s" % path)
		assert(load(path) is Shader, "risorsa non caricabile come Shader: %s" % path)
	var hub := HUB_SCENE.new()
	var room_material := hub.call("_room_shader_material") as ShaderMaterial
	assert(room_material != null and room_material.shader.resource_path == "res://shaders/ship_room.gdshader",
		"la nave non usa lo shader stanza condiviso")
	hub.free()
	var hub_source := FileAccess.get_file_as_string("res://scripts/hub_scene.gd")
	var world_source := FileAccess.get_file_as_string("res://scripts/outdoor_world.gd")
	assert(not hub_source.contains("shader.code ="), "la nave conserva uno shader inline")
	assert(not world_source.contains("vignette_material.shader = shader"), "la vignetta conserva uno shader inline")
	assert(world_source.contains("HUD_VIGNETTE_SHADER"), "l'HUD non precarica la vignetta condivisa")
	print("SHARED SHADER RESOURCE audit OK — sei shader condivisi, nessuna stringa runtime per nave o HUD")
	quit(0)
