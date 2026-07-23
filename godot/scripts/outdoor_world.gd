extends Node2D

const PORTAL_POSITION := Vector2(448, 300)
const INTERACTION_DISTANCE := 88.0
const TOUCH_POI_RADIUS := 104.0
const TOUCH_APPROACH_DISTANCE := 58.0
const DAY_LENGTH := 120.0
const PORTAL_VISUAL := preload("res://scripts/portal_visual.gd")
const EXERCISE_ENERGY_COST := 3
const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")
const ENIGMA_STRUCTURE := preload("res://scripts/visual/enigma_structure.gd")
const LEARNING_REACTION_SCRIPT := preload("res://scripts/visual/world_learning_reaction.gd")
const SHOP_PANEL_SCRIPT := preload("res://scripts/ui/outdoor_shop_panel.gd")
const NORA_PORTRAIT_SCRIPT := preload("res://scripts/ui/nora_portrait.gd")
const WORLD_LESSON_CATALOG := preload("res://scripts/game/world_lesson.gd")
const KNOWLEDGE_CODEX_PANEL_SCRIPT := preload("res://scripts/ui/knowledge_codex_panel.gd")

const PLAYER_ACCENT := Color("6be7d6")
const NIGHT_TINT := Color(0.46, 0.51, 0.70)
const DAWN_TINT := Color(1.0, 0.84, 0.72)

var request: Dictionary
var result: Dictionary
## Override usato da audit/render probe prima dell'ingresso nell'albero. Nel
## gioco normale resta vuoto e viene usata NativeWorldState.default_request().
var launch_request_override: Dictionary = {}
## Riduzione controllata del raggio per audit/capture Web. Nel gioco resta -1 e
## viene applicato il budget del WorldProfile.
var launch_stream_radius_override := -1
var world_profile: Dictionary = {}
var world_level := 1
var world_seed := ""
var mission_events: Array = []
var chunks: OutdoorChunkManager
var player: OutdoorPlayerController
var world_layer: Node2D
var day_light: CanvasModulate
var atmosphere_layer: CanvasLayer
var atmosphere_rect: ColorRect
var atmosphere_material: ShaderMaterial
var ui_layer: CanvasLayer
var feedback_label: Label
var feedback_source_label: Label
var feedback_panel: PanelContainer
var nora_portrait: Control
var phase_label: Label
var biome_label: Label
var objective_label: Label
var world_title_label: Label
var ship_navigation_label: Label
var guide_button: Button
var interaction_button: Button
var portal: Node2D
var camera: Camera2D
var fireflies: CPUParticles2D
var pet_companion: OutdoorPetCompanion
var player_presentation: Node2D
var nearby: Array = []
var day_clock := 0.0
var current_audio_phase := ""
var current_biome_chunk := ""
var energy_label: Label
var fragment_label: Label
var reward_name_label: Label
var reward_bar: ProgressBar
var reward_remaining_label: Label
var exercise_player: ExercisePlayer
var knowledge_codex_panel: KnowledgeCodexPanel
var shop_panel: Control
var reward_cost := 0
var reward_name := ""
var gameplay: OutdoorGameplay
var runtime: Dictionary = {}
# Alias di compatibilità per audit/scene legacy; la proprietà resta di
# OutdoorGameplay e non viene duplicata.
var game_save: GameSaveManager
var progression_manager: ProgressionManager
var content_manager: ContentManager
var gain_popup_pool: Array[Label] = []
var applied_cosmetic_signature := ""
var pending_touch_interaction: Area2D
var world_weather_particles: CPUParticles2D
var profile_night_tint := NIGHT_TINT
var profile_dawn_tint := DAWN_TINT
var profile_day_tint := Color.WHITE

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.eliScene = 'world';")
	request = launch_request_override.duplicate(true) if not launch_request_override.is_empty() else NativeWorldState.default_request()
	result = NativeWorldState.result_for(request)
	gameplay = OutdoorGameplay.new()
	gameplay.name = "OutdoorGameplay"
	add_child(gameplay)
	gameplay.runtime_state_changed.connect(_on_runtime_state)
	gameplay.session_requested.connect(_on_gameplay_session_requested)
	gameplay.feedback_presented.connect(_present_feedback)
	gameplay.enigma_progress.connect(_on_enigma_progress)
	gameplay.setup(request, result, bool(request.get("loadLocalSave", true)))
	game_save = gameplay.game_save
	progression_manager = gameplay.progression_manager
	content_manager = gameplay.content_manager
	_configure_world_profile()
	world_layer = Node2D.new()
	world_layer.name = "WorldLayer"
	world_layer.y_sort_enabled = true
	add_child(world_layer)
	day_light = CanvasModulate.new()
	day_light.name = "DayNight"
	day_light.color = Color("ffffff")
	world_layer.add_child(day_light)
	chunks = OutdoorChunkManager.new()
	chunks.name = "ChunkManager"
	world_layer.add_child(chunks)
	var reserved_positions: Array = []
	for event in mission_events:
		reserved_positions.append(event["position"])
	reserved_positions.append(_hero_landmark_position())
	chunks.configure(world_seed, self, world_profile, reserved_positions)
	if launch_stream_radius_override >= 0:
		chunks.active_radius = launch_stream_radius_override
	_create_player()
	_apply_resume()
	_create_portal()
	_create_profile_landmark()
	_create_profile_events()
	_create_profile_weather()
	_create_atmosphere()
	_create_hud()
	_create_exercise_player()
	if is_instance_valid(knowledge_codex_panel):
		var lesson := WORLD_LESSON_CATALOG.lesson(world_level)
		knowledge_codex_panel.mark_encountered(str(lesson.get("subject", _world_subject())), Array(lesson.get("topics", [])))
	chunks.update_stream(player.position)
	var lesson_briefing := WORLD_LESSON_CATALOG.briefing(world_level)
	_set_nora_feedback(lesson_briefing if lesson_briefing != "" else str(gameplay.runtime_state().get("narrative", "")))
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_environment", "day")
		audio.call("configure_world_soundscape", str(world_profile.get("soundscape", "")))
		audio.call("play_subject", _world_subject())

func _configure_world_profile() -> void:
	var frontier := clampi(game_save.level(), 1, WorldProfileCatalog.MAX_LEVEL)
	world_level = clampi(int(request.get("worldLevel", game_save.current_world())), 1, WorldProfileCatalog.MAX_LEVEL)
	if not game_save.is_world_unlocked(world_level):
		world_level = frontier
		game_save.unlock_world(world_level)
	game_save.set_current_world(world_level)
	var raw_profile := WorldProfileCatalog.profile(world_level)
	var validation := WorldProfileCatalog.validate(raw_profile)
	if not bool(validation.get("ok", false)):
		push_error("WorldProfile %d non valido: %s" % [world_level, str(validation.get("errors", []))])
		raw_profile = WorldProfileCatalog.profile(1)
		world_level = 1
	world_profile = _profile_in_scene_coordinates(raw_profile)
	world_seed = "%s::%s" % [str(request.get("worldSeed", "outdoor-dev-1")), str(world_profile.get("id", "world-01-radura"))]
	mission_events = _planned_world_events()
	_configure_profile_palette()

func _profile_in_scene_coordinates(profile: Dictionary) -> Dictionary:
	var mapped := profile.duplicate(true)
	var source_ship: Vector2 = profile.get("shipEntrance", {}).get("position", Vector2.ZERO)
	var offset := PORTAL_POSITION - source_ship
	var ship: Dictionary = mapped["shipEntrance"]
	ship["position"] = source_ship + offset
	mapped["shipEntrance"] = ship
	mapped["spawn"] = (profile.get("spawn", Vector2.ZERO) as Vector2) + offset
	var route: Array = []
	for point in profile.get("safeRoute", []):
		route.append((point as Vector2) + offset)
	mapped["safeRoute"] = route
	return mapped

func _planned_world_events() -> Array:
	var subject := _world_subject()
	var due_topics: Array = []
	for key in SpacedRepetition.due_map(game_save).keys():
		var prefix := "%s:" % subject
		if str(key).begins_with(prefix):
			due_topics.append(str(key).trim_prefix(prefix))
	var weak_topics: Array = []
	for topic in game_save.topic_masteries(subject).keys():
		if float(game_save.topic_masteries(subject).get(topic, 1.0)) < ContentManager.WEAK_TOPIC_THRESHOLD:
			weak_topics.append(str(topic))
	var context := {
		"missionsRequired": int(ApparatusConfig.level_gate(world_level).get("missionsRequired", 5)),
		"weakTopics": weak_topics,
		"dueTopics": due_topics,
		"recentFormats": [],
	}
	var planned := MissionEventDirector.plan(world_profile, context, world_seed)
	var budget := _profile_performance_budget()
	var maximum := maxi(int(context["missionsRequired"]) + MissionEventDirector.GATE_SURPLUS, int(budget.get("maxActivePois", 14)))
	if planned.size() > maximum:
		planned = planned.slice(0, maximum)
	return planned

func _profile_performance_budget() -> Dictionary:
	var budgets: Dictionary = world_profile.get("performanceBudget", {})
	var tier := "mobile" if OS.has_feature("mobile") else "web" if OS.has_feature("web") else "desktop"
	return Dictionary(budgets.get(tier, budgets.get("web", {})))

func _world_subject() -> String:
	return str(world_profile.get("learningFocus", {}).get("subject", "matematica"))

func _configure_profile_palette() -> void:
	var subject := _world_subject()
	var subject_colors := {
		"matematica": Color("6be7d6"), "italiano": Color("e9a86d"),
		"coding": Color("8fa7ff"), "inglese": Color("72c9ff"),
		"fisica": Color("a2d8ff"), "musica": Color("d7a0ff"),
		"latino": Color("d4b17a"), "elettronica": Color("79e7ff"),
		"geografia": Color("7fd19b"), "scienze": Color("91dc72"),
		"cittadinanza": Color("f2c96d"), "logica": Color("b7a2ff"),
	}
	var accent: Color = subject_colors.get(subject, PLAYER_ACCENT)
	profile_night_tint = NIGHT_TINT.lerp(accent.darkened(0.58), 0.28)
	profile_dawn_tint = DAWN_TINT.lerp(accent.lightened(0.12), 0.30)
	profile_day_tint = Color.WHITE.lerp(accent.lightened(0.42), 0.08)
	if world_level == 3:
		# Basalto freddo, rame e circuiti: il Cratere resta tecnico anche in pieno giorno.
		profile_night_tint = Color("26314c")
		profile_dawn_tint = Color("8f6b72")
		profile_day_tint = Color("d9e2f1")
	elif world_level == 4:
		# Teal marino e tramonto corallo separano la Baia da ogni bioma terrestre.
		profile_night_tint = Color("173d49")
		profile_dawn_tint = Color("e89b83")
		profile_day_tint = Color("d9f0ea")
	if not request.has("resume"):
		var lighting := str(world_profile.get("lighting", "")).to_lower()
		if "notte" in lighting or "penombra" in lighting:
			day_clock = 0.0
		elif "tramonto" in lighting or "crepuscolo" in lighting:
			day_clock = DAY_LENGTH * 0.76
		elif "mattino" in lighting:
			day_clock = DAY_LENGTH * 0.36
		else:
			day_clock = DAY_LENGTH * 0.52

func _apply_resume() -> void:
	var resume: Dictionary = request.get("resume", {})
	if resume.is_empty():
		resume = game_save.world_resume(str(world_level))
	if resume.is_empty():
		return
	var resumed := Vector2(float(resume.get("playerX", player.position.x)), float(resume.get("playerY", player.position.y)))
	player.position = chunks.clamp_to_world(resumed)
	day_clock = float(resume.get("dayClock", 0.0))
	if is_instance_valid(camera):
		camera.position = player.position

func _on_runtime_state(state: Dictionary) -> void:
	runtime = state.duplicate(true)
	_update_objective()
	_update_ship_navigation()
	_refresh_economy()
	_apply_cosmetic_presentation()
	if is_instance_valid(portal) and portal.has_method("set_gate_state"):
		portal.call("set_gate_state", bool(runtime.get("ready", false)), str(runtime.get("apparatus", "nucleo")), bool(runtime.get("complete", false)))

func _on_gameplay_session_requested(session: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(interaction_button):
		interaction_button.visible = false
	_set_feedback("")
	if is_instance_valid(player):
		player.set_physics_process(false)
	exercise_player.visible = true
	exercise_player.start_session(session)

func _process(delta: float) -> void:
	day_clock = fmod(day_clock + delta, DAY_LENGTH)
	var daylight := (sin(day_clock / DAY_LENGTH * TAU - PI / 2.0) + 1.0) * 0.5
	var phase_id := "giorno" if daylight > 0.72 else "alba" if daylight > 0.42 else "notte"
	if is_instance_valid(day_light):
		# notte → giorno con transizione calda (alba/tramonto) a metà corsa
		var base := profile_night_tint.lerp(profile_day_tint, daylight)
		var dawn_mix := clampf(1.0 - absf(daylight - 0.5) * 2.2, 0.0, 1.0)
		day_light.color = base.lerp(profile_dawn_tint, dawn_mix * 0.35)
		if is_instance_valid(phase_label):
			phase_label.text = "%s · %s" % [
				phase_id.capitalize(),
				str(world_profile.get("weather", "sereno")).replace("-", " ").capitalize()]
	if is_instance_valid(gameplay):
		gameplay.update_phase(phase_id)
	if current_audio_phase != phase_id:
		current_audio_phase = phase_id
		var audio := get_node_or_null("/root/NativeAudio")
		if audio != null:
			audio.call("play_environment", "night" if phase_id == "notte" else "day")
			audio.call("configure_world_soundscape", str(world_profile.get("soundscape", "")))
	if is_instance_valid(atmosphere_material):
		atmosphere_material.set_shader_parameter("daylight", daylight)
		atmosphere_material.set_shader_parameter("clock", day_clock / DAY_LENGTH)
	_update_night_glow(daylight)
	if is_instance_valid(player):
		chunks.update_stream(player.position)
		if is_instance_valid(camera):
			camera.position = player.position
		if is_instance_valid(fireflies):
			fireflies.emitting = daylight < 0.45
		if is_instance_valid(world_weather_particles):
			world_weather_particles.position = player.position
		_update_biome_hud()
		_update_ship_navigation()
		_update_pending_touch_interaction()

func _create_atmosphere() -> void:
	# Layer screen-space tra mondo e HUD: aggiunge profondità cromatica senza
	# modificare collisioni, z-sort o la semantica del salvataggio.
	atmosphere_layer = CanvasLayer.new()
	atmosphere_layer.name = "AtmosphereLayer"
	atmosphere_layer.layer = 1
	add_child(atmosphere_layer)
	atmosphere_rect = ColorRect.new()
	atmosphere_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	atmosphere_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float daylight = 0.75;
uniform float clock = 0.0;
uniform vec3 biome_tint = vec3(0.42, 0.90, 0.84);

void fragment() {
    vec2 uv = UV;
    vec2 centered = uv - vec2(0.5);
    float edge = smoothstep(0.38, 0.92, length(centered * vec2(1.0, 0.82)));
    float night = 1.0 - daylight;
    float dawn = clamp(1.0 - abs(daylight - 0.5) * 2.4, 0.0, 1.0);
    float horizon = smoothstep(0.15, 0.9, uv.y) * (1.0 - smoothstep(0.72, 1.0, uv.y));
    float mist_wave = 0.5 + 0.5 * sin((uv.x * 9.0) + (clock * 6.283) + sin(uv.y * 5.0));
    float mist = horizon * mist_wave * (0.018 + dawn * 0.035);
    vec3 night_tint = vec3(0.08, 0.13, 0.28);
    vec3 dawn_tint = vec3(1.0, 0.58, 0.28);
    vec3 tint = mix(night_tint, dawn_tint, dawn * 0.72);
    tint = mix(tint, biome_tint, 0.16);
    float alpha = (night * 0.045) + (dawn * 0.028) + (edge * 0.050) + mist;
    COLOR = vec4(tint, clamp(alpha, 0.0, 0.16));
}
"""
	atmosphere_material = ShaderMaterial.new()
	atmosphere_material.shader = shader
	atmosphere_rect.material = atmosphere_material
	atmosphere_layer.add_child(atmosphere_rect)

func _update_night_glow(daylight: float) -> void:
	# I bagliori (lampade, cristalli, fari…) si accendono al calare della luce.
	var alpha := clampf(0.15 + (1.0 - daylight) * 0.95, 0.15, 1.0)
	for node in get_tree().get_nodes_in_group("night_glow"):
		var canvas := node as CanvasItem
		if canvas != null:
			canvas.modulate.a = alpha

func _update_biome_hud() -> void:
	if not is_instance_valid(biome_label):
		return
	var cx := floori(player.position.x / OutdoorChunkManager.CHUNK_SIZE)
	var cy := floori(player.position.y / OutdoorChunkManager.CHUNK_SIZE)
	var id := "chunk-%d_%d" % [cx, cy]
	if id == current_biome_chunk or not chunks.loaded.has(id):
		return
	current_biome_chunk = id
	if chunks.composition != null:
		var biome := chunks.composition.dominant_biome(player.position)
		var profile := BiomeProfile.get_profile(biome)
		biome_label.text = "%s · %s" % [
			str(world_profile.get("terrainFamily", "territorio")).replace("-", " ").capitalize(),
			str(profile["label"])]
		var accent: Color = chunks.composition.blended_accent(player.position)
		biome_label.add_theme_color_override("font_color", accent)
		if is_instance_valid(atmosphere_material):
			atmosphere_material.set_shader_parameter("biome_tint", Vector3(accent.r, accent.g, accent.b))
		return
	var data: Dictionary = chunks.loaded[id]["data"]
	var patch: Dictionary = data.get("patch", {})
	biome_label.text = str(patch.get("label", ""))
	biome_label.add_theme_color_override("font_color", OutdoorVisualFactory.hex_color(int(patch.get("accent", 0x6be7d6))))

func _create_player() -> void:
	player = OutdoorPlayerController.new()
	player.name = "Eli"
	player.position = world_profile.get("spawn", PORTAL_POSITION + Vector2(0, 1180))
	player.add_to_group("player")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	player.add_child(shape)
	var visual_data := _resolved_avatar_visual()
	var livery := _avatar_color(visual_data.get("bodyColor", -1), PLAYER_ACCENT)
	player_presentation = OutdoorVisualFactory.build_player(livery)
	player_presentation.name = "PlayerPresentation"
	player.add_child(player_presentation)
	player.visual = player_presentation.get_node("Visual")
	_apply_accessory(player.visual, visual_data)
	_apply_emblem(player.visual, visual_data)
	_add_player_night_light()
	fireflies = OutdoorVisualFactory.make_sparkles(Color(1.0, 0.93, 0.62, 0.85), 560.0, 24)
	fireflies.lifetime = 5.0
	fireflies.preprocess = 3.0
	fireflies.scale_amount_min = 0.04
	fireflies.scale_amount_max = 0.08
	fireflies.add_to_group("night_glow")
	player.add_child(fireflies)
	world_layer.add_child(player)
	_spawn_pet(visual_data)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = player.position
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	applied_cosmetic_signature = _cosmetic_signature()

func _resolved_avatar_visual() -> Dictionary:
	var visual_data: Dictionary = Dictionary(request.get("avatarVisual", {})).duplicate(true)
	var equipped: Dictionary = runtime.get("cosmeticsEquipped", {})
	var avatar_id := str(equipped.get("avatar", ""))
	var avatar_item := RewardCatalog.find(avatar_id)
	if not avatar_item.is_empty():
		visual_data["bodyColor"] = int(avatar_item.get("color", 0x6be7d6))
	var accessory_id := str(equipped.get("accessory", ""))
	var accessory_item := RewardCatalog.find(accessory_id)
	if not accessory_item.is_empty():
		visual_data["accessory"] = {"id": accessory_id, "color": int(accessory_item.get("color", 0x9ff5e9))}
	var pet_id := str(equipped.get("pet", ""))
	var pet_item := RewardCatalog.find(pet_id)
	if not pet_item.is_empty():
		visual_data["pet"] = {"id": pet_id, "kind": pet_id.trim_prefix("pet-"), "color": int(pet_item.get("color", 0xf6c85f))}
	var emblem_id := str(equipped.get("emblem", ""))
	var emblem_item := RewardCatalog.find(emblem_id)
	if not emblem_item.is_empty():
		visual_data["emblem"] = {
			"id": emblem_id,
			"glyph": str(emblem_item.get("glyph", "◆")),
			"color": int(emblem_item.get("color", 0xf6c85f)),
		}
	return visual_data

func _cosmetic_signature() -> String:
	return JSON.stringify(runtime.get("cosmeticsEquipped", {}))

func _apply_cosmetic_presentation() -> void:
	if not is_instance_valid(player) or not is_instance_valid(world_layer):
		return
	var signature := _cosmetic_signature()
	if signature == applied_cosmetic_signature:
		return
	applied_cosmetic_signature = signature
	var visual_data := _resolved_avatar_visual()
	var livery := _avatar_color(visual_data.get("bodyColor", -1), PLAYER_ACCENT)
	if is_instance_valid(player_presentation):
		player.remove_child(player_presentation)
		player_presentation.queue_free()
	player_presentation = OutdoorVisualFactory.build_player(livery)
	player_presentation.name = "PlayerPresentation"
	player.add_child(player_presentation)
	player.visual = player_presentation.get_node("Visual")
	_apply_accessory(player.visual, visual_data)
	_apply_emblem(player.visual, visual_data)
	if is_instance_valid(pet_companion):
		world_layer.remove_child(pet_companion)
		pet_companion.queue_free()
		pet_companion = null
	_spawn_pet(visual_data)
	var bot_id := str(Dictionary(runtime.get("cosmeticsEquipped", {})).get("bot", ""))
	var bot_item := RewardCatalog.find(bot_id)
	if not bot_item.is_empty() and is_instance_valid(nora_portrait):
		nora_portrait.set_livery(OutdoorVisualFactory.hex_color(int(bot_item.get("color", 0x6be7d6))))

func _add_player_night_light() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 0.88, 0.58, 0.34), Color(0.32, 0.72, 0.82, 0.12), Color(0, 0, 0, 0)])
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 192
	texture.height = 192
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var light := PointLight2D.new()
	light.name = "PlayerNightLight"
	light.texture = texture
	light.energy = 0.46
	light.texture_scale = 2.0
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	player.add_child(light)

func _avatar_color(value, fallback: Color) -> Color:
	if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and int(value) >= 0:
		return OutdoorVisualFactory.hex_color(int(value))
	return fallback

func _apply_accessory(visual_node: Node2D, visual_data: Dictionary) -> void:
	var accessory = visual_data.get("accessory", null)
	if typeof(accessory) != TYPE_DICTIONARY:
		return
	var color := OutdoorVisualFactory.hex_color(int(accessory.get("color", 0x9ff5e9)))
	visual_node.add_child(OutdoorVisualFactory.build_accessory(str(accessory.get("id", "")), color))

func _apply_emblem(visual_node: Node2D, visual_data: Dictionary) -> void:
	var emblem = visual_data.get("emblem", null)
	if typeof(emblem) != TYPE_DICTIONARY:
		return
	var badge := Label.new()
	badge.name = "EquippedEmblem"
	badge.text = str(emblem.get("glyph", "◆"))
	badge.position = Vector2(22, -61)
	badge.add_theme_font_size_override("font_size", 17)
	badge.add_theme_constant_override("outline_size", 5)
	badge.add_theme_color_override("font_color", OutdoorVisualFactory.hex_color(int(emblem.get("color", 0xf6c85f))))
	badge.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.06, 0.92))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_node.add_child(badge)

func _spawn_pet(visual_data: Dictionary) -> void:
	var pet_data = visual_data.get("pet", null)
	if typeof(pet_data) != TYPE_DICTIONARY:
		return
	var color := OutdoorVisualFactory.hex_color(int(pet_data.get("color", 0xf6c85f)))
	pet_companion = OutdoorPetCompanion.new()
	world_layer.add_child(pet_companion)
	pet_companion.setup(str(pet_data.get("kind", "spark")), color, player)

func _create_portal() -> void:
	portal = PORTAL_VISUAL.new()
	portal.name = "ExitPortal"
	portal.position = PORTAL_POSITION
	portal.z_index = 18
	world_layer.add_child(portal)
	if portal.has_method("set_gate_state"):
		portal.call("set_gate_state", bool(runtime.get("ready", false)), str(runtime.get("apparatus", "nucleo")), bool(runtime.get("complete", false)))
	var area := Area2D.new()
	area.add_to_group("world_interactable")
	area.set_meta("kind", "portal")
	area.set_meta("id", "portal")
	area.set_meta("payload", {})
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_DISTANCE
	shape.shape = circle
	area.add_child(shape)
	portal.add_child(area)
	area.body_entered.connect(func(body): on_interactable_entered(area, body))
	area.body_exited.connect(func(body): on_interactable_exited(area, body))
	_create_profile_portal_dressing()

func _hero_landmark_position() -> Vector2:
	if world_level == 3:
		return PORTAL_POSITION + Vector2(0, 1280)
	if world_level == 4:
		return PORTAL_POSITION + Vector2(1320, 1280)
	return PORTAL_POSITION + Vector2(690, -210)

func _create_profile_portal_dressing() -> void:
	var specs: Array[Dictionary] = []
	if world_level == 3:
		specs = [
			{"kind": "sequence_pylon", "offset": Vector2(-142, 34), "variant": 0.22},
			{"kind": "sequence_pylon", "offset": Vector2(142, 34), "variant": 0.78},
		]
	elif world_level == 4:
		specs = [
			{"kind": "radio_mast", "offset": Vector2(-158, 42), "variant": 0.28},
			{"kind": "signal_buoy", "offset": Vector2(158, 42), "variant": 0.74},
		]
	for spec in specs:
		var dressing := OutdoorVisualFactory.build_identity_prop(
			str(spec["kind"]), "ship_entrance", float(spec["variant"]))
		dressing.name = "ShipEntrance_%s" % str(spec["kind"])
		dressing.position = PORTAL_POSITION + (spec["offset"] as Vector2)
		dressing.z_index = 14
		world_layer.add_child(dressing)

func _create_profile_landmark() -> void:
	var names: Array = world_profile.get("heroLandmarks", [])
	if names.is_empty():
		return
	var subject := _world_subject()
	var kinds := {
		"matematica": "skyTree", "italiano": "ancientCore",
		"coding": "logicSpire", "inglese": "atlasGate",
		"fisica": "forge", "musica": "crystalNest",
		"latino": "ancientCore", "elettronica": "logicSpire",
		"geografia": "atlasGate", "scienze": "skyTree",
		"cittadinanza": "forge", "logica": "logicSpire",
	}
	var landmark_kind := (
		"cycleMachine" if world_level == 3 else
		"signalLighthouse" if world_level == 4 else
		str(kinds.get(subject, "skyTree"))
	)
	var label := str(names[0]).replace("-", " ").capitalize()
	var landmark := OutdoorVisualFactory.build_landmark(
		landmark_kind, label, _profile_accent_rgb())
	landmark.name = "ProfileHeroLandmark"
	landmark.set_meta("landmark_kind", landmark_kind)
	landmark.position = _hero_landmark_position()
	landmark.scale = Vector2.ONE * (1.52 if world_level in [3, 4] else 1.32)
	world_layer.add_child(landmark)

func _create_profile_events() -> void:
	for event_data in mission_events:
		var event: Dictionary = event_data
		var director_kind := str(event.get("kind", "mission"))
		var scene_kind := "encounter" if director_kind == "mission" else "minigame" if director_kind == "practice" else "enigma"
		var area := Area2D.new()
		area.name = "MissionEvent_%s" % str(event.get("id", "event")).replace("-", "_")
		area.position = event.get("position", Vector2.ZERO)
		area.add_to_group("world_interactable")
		if bool(event.get("countsForGate", false)):
			area.add_to_group("mission_poi")
		if director_kind == "enigma":
			area.add_to_group("enigma_poi")
		elif director_kind == "practice":
			area.add_to_group("minigame_poi")
		area.set_meta("kind", scene_kind)
		area.set_meta("id", str(event.get("id", "")))
		area.set_meta("directorEvent", event.duplicate(true))
		var payload := {
			"subject": str(event.get("subject", _world_subject())),
			"label": _event_label(event),
			"format": str(event.get("format", "multiple_choice")),
			"topicHint": str(event.get("topicHint", "")),
			"countsForGate": bool(event.get("countsForGate", false)),
			"directorKind": director_kind,
		}
		area.set_meta("payload", payload)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = INTERACTION_DISTANCE
		shape.shape = circle
		area.add_child(shape)
		if director_kind == "enigma":
			var visual := ENIGMA_STRUCTURE.new()
			visual.name = "EnigmaStructureVisual"
			visual.setup(ContentManager.enigma_theme(str(payload["subject"])), str(payload["label"]))
			var complete := Array(result.get("completedEncounterIds", [])).has(str(event.get("id", "")))
			visual.set_stage(4 if complete else 0, 4)
			area.add_child(visual)
		elif director_kind == "practice":
			area.add_child(_make_minigame_marker())
		else:
			area.add_child(OutdoorVisualFactory.build_encounter(
				_event_visual_kind(str(payload["subject"])), clampi(floori(float(world_level) / 4.0) + 1, 1, 7)))
		var reaction := LEARNING_REACTION_SCRIPT.new()
		reaction.setup(
			"archive" if world_level == 2 else "crater" if world_level == 3 else "signal_bay" if world_level == 4 else "radura",
			director_kind,
			OutdoorVisualFactory.hex_color(_profile_accent_rgb()))
		reaction.position = Vector2(0, 28)
		reaction.set_complete(Array(result.get("completedEncounterIds", [])).has(str(event.get("id", ""))))
		area.add_child(reaction)
		area.add_child(_make_event_caption(director_kind, str(payload["subject"])))
		world_layer.add_child(area)
		area.body_entered.connect(func(body): on_interactable_entered(area, body))
		area.body_exited.connect(func(body): on_interactable_exited(area, body))

func _event_label(event: Dictionary) -> String:
	var subject := str(event.get("subject", _world_subject())).capitalize()
	match str(event.get("kind", "mission")):
		"enigma":
			return "enigma di %s" % subject
		"practice":
			return "evento di pratica · %s" % subject
	return "tappa di missione · %s" % subject

func _event_visual_kind(subject: String) -> String:
	if subject in ["matematica", "fisica"]:
		return "times"
	if subject in ["geografia", "inglese"]:
		return "capital"
	if subject in ["coding", "elettronica", "logica"]:
		return "guardian"
	if subject in ["scienze", "cittadinanza"]:
		return "physicalGeo"
	return "mental"

func _make_event_caption(kind: String, subject: String) -> Label:
	var label := Label.new()
	label.position = Vector2(-72, -86)
	label.custom_minimum_size = Vector2(144, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = ("%s · %s" % [
		"PRATICA" if kind == "practice" else "ENIGMA" if kind == "enigma" else "MISSIONE",
		subject.to_upper()])
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_color", Color("f6c85f") if kind != "practice" else PLAYER_ACCENT)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.035, 0.04, 0.92))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _profile_accent_rgb() -> int:
	var colors := {
		"matematica": 0x6be7d6, "italiano": 0xe9a86d, "coding": 0x8fa7ff,
		"inglese": 0x72c9ff, "fisica": 0xa2d8ff, "musica": 0xd7a0ff,
		"latino": 0xd4b17a, "elettronica": 0x79e7ff, "geografia": 0x7fd19b,
		"scienze": 0x91dc72, "cittadinanza": 0xf2c96d, "logica": 0xb7a2ff,
	}
	return int(colors.get(_world_subject(), 0x6be7d6))

func _create_profile_weather() -> void:
	var weather := str(world_profile.get("weather", "sereno")).to_lower()
	if world_level not in [3, 4] and weather in ["sereno", "quiete", "controllato", "sereno-secco"]:
		return
	world_weather_particles = CPUParticles2D.new()
	world_weather_particles.name = "WorldProfileWeather"
	world_weather_particles.position = world_profile.get("spawn", PORTAL_POSITION)
	world_weather_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	world_weather_particles.emission_rect_extents = Vector2(680, 430)
	world_weather_particles.local_coords = false
	world_weather_particles.lifetime = 2.8
	world_weather_particles.preprocess = 2.0
	world_weather_particles.scale_amount_min = 0.05
	world_weather_particles.scale_amount_max = 0.13
	world_weather_particles.z_index = 42
	if world_level == 3:
		world_weather_particles.amount = 30
		world_weather_particles.direction = Vector2(0.18, -1.0)
		world_weather_particles.gravity = Vector2(5, -12)
		world_weather_particles.initial_velocity_min = 10.0
		world_weather_particles.initial_velocity_max = 28.0
		world_weather_particles.color = Color(0.48, 0.88, 1.0, 0.34)
	elif world_level == 4:
		world_weather_particles.amount = 42
		world_weather_particles.direction = Vector2(1.0, -0.10)
		world_weather_particles.gravity = Vector2(22, -3)
		world_weather_particles.initial_velocity_min = 22.0
		world_weather_particles.initial_velocity_max = 52.0
		world_weather_particles.color = Color(0.74, 0.96, 0.91, 0.28)
	elif "pioggia" in weather or "tempesta" in weather:
		world_weather_particles.amount = 110 if "tempesta" in weather else 64
		world_weather_particles.direction = Vector2(0.18, 1.0)
		world_weather_particles.gravity = Vector2(34, 520)
		world_weather_particles.initial_velocity_min = 120.0
		world_weather_particles.initial_velocity_max = 210.0
		world_weather_particles.color = Color(0.62, 0.82, 1.0, 0.58)
	else:
		world_weather_particles.amount = 32
		world_weather_particles.direction = Vector2(1.0, -0.08)
		world_weather_particles.gravity = Vector2(18, -4)
		world_weather_particles.initial_velocity_min = 18.0
		world_weather_particles.initial_velocity_max = 48.0
		world_weather_particles.color = Color(profile_dawn_tint, 0.32)
	world_layer.add_child(world_weather_particles)

func _make_minigame_marker() -> Node2D:
	var marker := Node2D.new()
	marker.name = "MinigameMarker"
	var disc := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 30.0)
	disc.polygon = pts
	disc.color = Color(0.10, 0.42, 0.46, 0.92)
	marker.add_child(disc)
	var label := Label.new()
	label.text = "★"
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color("f6c85f"))
	label.position = Vector2(-9, -20)
	marker.add_child(label)
	return marker

func _create_exercise_player() -> void:
	exercise_player = EXERCISE_PLAYER_SCRIPT.new()
	exercise_player.name = "ExercisePlayer"
	exercise_player.visible = false
	exercise_player.session_finished.connect(_on_exercise_finished)
	exercise_player.concept_help_requested.connect(_open_contextual_codex)
	exercise_player.learning_signal.connect(_on_nora_learning_signal)
	# La costruzione dell'enigma avanza in tempo reale: inoltro il progresso alla
	# logica, che rilancia `enigma_progress` (con tema) per la resa di Codex.
	exercise_player.progress_changed.connect(_on_exercise_progress)
	ui_layer.add_child(exercise_player)
	knowledge_codex_panel = KNOWLEDGE_CODEX_PANEL_SCRIPT.new()
	knowledge_codex_panel.setup(game_save, content_manager)
	knowledge_codex_panel.panel_closed.connect(_on_codex_closed)
	ui_layer.add_child(knowledge_codex_panel)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.09, 0.12, 0.72)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.42, 0.9, 0.84, 0.25)
	return style

func _touch_action_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(16)
	style.set_content_margin_all(14)
	style.set_border_width_all(2)
	style.border_color = border
	style.shadow_color = Color(0.0, 0.02, 0.03, 0.62)
	style.shadow_size = 8
	return style

func _create_hud() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)

	# vignetta soft ai bordi dello schermo (sotto i pannelli HUD)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.55;
	float v = smoothstep(0.62, 1.28, d);
	COLOR = vec4(0.008, 0.02, 0.035, v * 0.42);
}
"""
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = shader
	vignette.material = vignette_material
	root.add_child(vignette)

	var info_panel := PanelContainer.new()
	info_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_panel.position = Vector2(16, 16)
	info_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(info_panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info_panel.add_child(info)
	world_title_label = Label.new()
	world_title_label.name = "WorldProfileTitle"
	world_title_label.text = "ELI QUEST  ·  %s" % str(world_profile.get("title", "Radura Accademia")).to_upper()
	world_title_label.add_theme_color_override("font_color", Color("e7fff8"))
	world_title_label.add_theme_font_size_override("font_size", 19)
	info.add_child(world_title_label)
	biome_label = Label.new()
	biome_label.text = ""
	biome_label.add_theme_font_size_override("font_size", 14)
	biome_label.add_theme_color_override("font_color", PLAYER_ACCENT)
	info.add_child(biome_label)
	phase_label = Label.new()
	phase_label.text = "Giorno · %s" % str(world_profile.get("weather", "sereno")).replace("-", " ").capitalize()
	phase_label.add_theme_color_override("font_color", Color("f6c85f"))
	phase_label.add_theme_font_size_override("font_size", 14)
	info.add_child(phase_label)
	objective_label = Label.new()
	objective_label.name = "CurrentObjective"
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(300, 0)
	objective_label.add_theme_color_override("font_color", Color("f6c85f"))
	objective_label.add_theme_font_size_override("font_size", 13)
	info.add_child(objective_label)
	_update_objective()
	ship_navigation_label = Label.new()
	ship_navigation_label.name = "ShipNavigation"
	ship_navigation_label.add_theme_font_size_override("font_size", 12)
	ship_navigation_label.add_theme_color_override("font_color", Color("9fc4bb"))
	info.add_child(ship_navigation_label)
	_update_ship_navigation()
	var hint := Label.new()
	hint.text = "TOCCA UN POI o INTERAGISCI  ·  Tastiera: WASD / E  ·  SHIFT: scatto"
	hint.add_theme_color_override("font_color", Color("9fc4bb"))
	hint.add_theme_font_size_override("font_size", 12)
	info.add_child(hint)

	guide_button = Button.new()
	guide_button.name = "GuideToShipButton"
	guide_button.text = "TROVA UNA MISSIONE"
	guide_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	guide_button.pressed.connect(_guide_to_objective)
	root.add_child(guide_button)

	# Azione primaria touch: compare soltanto vicino a un POI e offre un bersaglio
	# da almeno 64 px, comodo per tablet. È disponibile anche con mouse/gamepad
	# come alternativa accessibile al tasto E.
	interaction_button = Button.new()
	interaction_button.name = "ContextInteractButton"
	interaction_button.visible = false
	interaction_button.anchor_left = 0.5
	interaction_button.anchor_right = 0.5
	interaction_button.anchor_top = 1.0
	interaction_button.anchor_bottom = 1.0
	interaction_button.offset_left = -160.0
	interaction_button.offset_right = 160.0
	interaction_button.offset_top = -96.0
	interaction_button.offset_bottom = -28.0
	interaction_button.custom_minimum_size = Vector2(320, 68)
	interaction_button.add_theme_font_size_override("font_size", 18)
	interaction_button.add_theme_color_override("font_color", Color("06272a"))
	interaction_button.add_theme_color_override("font_hover_color", Color("031d20"))
	interaction_button.add_theme_stylebox_override("normal", _touch_action_style(Color("6be7d6"), Color("d8fff8")))
	interaction_button.add_theme_stylebox_override("hover", _touch_action_style(Color("83f4df"), Color.WHITE))
	interaction_button.add_theme_stylebox_override("pressed", _touch_action_style(Color("f6c85f"), Color("fff1b8")))
	interaction_button.pressed.connect(_interact)
	root.add_child(interaction_button)
	var shop_button := Button.new()
	shop_button.name = "OpenShopButton"
	shop_button.text = "BOTTEGA"
	shop_button.anchor_left = 1.0
	shop_button.anchor_right = 1.0
	shop_button.offset_left = -132.0
	shop_button.offset_right = -16.0
	shop_button.offset_top = 58.0
	shop_button.offset_bottom = 96.0
	shop_button.add_theme_color_override("font_color", Color("f6c85f"))
	shop_button.pressed.connect(_open_shop)
	root.add_child(shop_button)
	var manual_button := Button.new()
	manual_button.name = "OpenKnowledgeCodexButton"
	manual_button.text = "MANUALE NORA"
	manual_button.anchor_left = 1.0
	manual_button.anchor_right = 1.0
	manual_button.offset_left = -164.0
	manual_button.offset_right = -16.0
	manual_button.offset_top = 104.0
	manual_button.offset_bottom = 150.0
	manual_button.custom_minimum_size.y = 46
	manual_button.add_theme_color_override("font_color", Color("6be7d6"))
	manual_button.pressed.connect(_open_codex)
	root.add_child(manual_button)

	feedback_panel = PanelContainer.new()
	feedback_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	feedback_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	feedback_panel.add_theme_stylebox_override("panel", _panel_style())
	feedback_panel.visible = false
	root.add_child(feedback_panel)
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 10)
	feedback_panel.add_child(feedback_row)
	var nora_column := VBoxContainer.new()
	nora_column.custom_minimum_size = Vector2(82, 0)
	feedback_row.add_child(nora_column)
	feedback_source_label = Label.new()
	feedback_source_label.name = "FeedbackSource"
	feedback_source_label.text = "NORA"
	feedback_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_source_label.add_theme_font_size_override("font_size", 11)
	feedback_source_label.add_theme_color_override("font_color", Color("6be7d6"))
	nora_column.add_child(feedback_source_label)
	nora_portrait = NORA_PORTRAIT_SCRIPT.new()
	nora_column.add_child(nora_portrait)
	var equipped_bot := str(Dictionary(runtime.get("cosmeticsEquipped", {})).get("bot", ""))
	var equipped_bot_item := RewardCatalog.find(equipped_bot)
	if not equipped_bot_item.is_empty():
		nora_portrait.set_livery(OutdoorVisualFactory.hex_color(int(equipped_bot_item.get("color", 0x6be7d6))))
	if nora_portrait.has_method("set_integrity"):
		nora_portrait.call("set_integrity", _nora_integrity_ratio(), false, NoraState.trust(game_save))
	feedback_label = Label.new()
	feedback_label.add_theme_color_override("font_color", Color("ffffff"))
	feedback_label.add_theme_font_size_override("font_size", 15)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(340, 0)
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_row.add_child(feedback_label)

	_create_economy_panel(root)
	_create_shop_panel(root)

func _create_shop_panel(root: Control) -> void:
	shop_panel = SHOP_PANEL_SCRIPT.new()
	root.add_child(shop_panel)
	shop_panel.setup(gameplay)
	shop_panel.closed.connect(_on_shop_closed)

func _open_shop() -> void:
	if not is_instance_valid(shop_panel):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(interaction_button):
		interaction_button.visible = false
	if is_instance_valid(player):
		player.set_physics_process(false)
	shop_panel.open_panel()

func _on_shop_closed() -> void:
	if is_instance_valid(player) and not (is_instance_valid(exercise_player) and exercise_player.visible) and not (is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible):
		player.set_physics_process(true)
	_refresh_prompt()

func _open_codex() -> void:
	_open_contextual_codex(_world_subject(), "")

func _open_contextual_codex(subject: String, topic: String) -> void:
	if not is_instance_valid(knowledge_codex_panel):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(interaction_button):
		interaction_button.visible = false
	if is_instance_valid(player):
		player.set_physics_process(false)
	var use_context := str(exercise_player.session.get("kind", "practice")) if is_instance_valid(exercise_player) and exercise_player.visible else "world"
	if topic != "" and is_instance_valid(exercise_player) and exercise_player.visible:
		NoraState.register(game_save, "help_request")
		game_save.save()
	knowledge_codex_panel.open_codex(subject, topic, use_context)

func _on_codex_closed() -> void:
	if is_instance_valid(player) and not (is_instance_valid(exercise_player) and exercise_player.visible) and not (is_instance_valid(shop_panel) and shop_panel.visible):
		player.set_physics_process(true)
	_refresh_prompt()

func _on_nora_learning_signal(signal_name: String) -> void:
	if not is_instance_valid(game_save):
		return
	NoraState.register(game_save, signal_name)
	game_save.save()

func _nora_integrity_ratio() -> float:
	if not is_instance_valid(game_save):
		return 0.0
	NoraState.sync_from_progress(game_save)
	return NoraState.integrity(game_save)

func _create_economy_panel(root: Control) -> void:
	var next_reward = request.get("nextReward", null)
	if typeof(next_reward) == TYPE_DICTIONARY:
		reward_name = str(next_reward.get("name", ""))
		reward_cost = int(next_reward.get("cost", 0))

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(210, 0)
	panel.add_child(box)

	energy_label = Label.new()
	energy_label.add_theme_color_override("font_color", Color("f6c85f"))
	energy_label.add_theme_font_size_override("font_size", 16)
	box.add_child(energy_label)
	fragment_label = Label.new()
	fragment_label.add_theme_color_override("font_color", Color("c7b8ff"))
	fragment_label.add_theme_font_size_override("font_size", 14)
	box.add_child(fragment_label)
	var economy_hint := Label.new()
	economy_hint.text = "Tesori: solo frammenti · Esercizio: -%d energia (gratis sotto soglia)" % EXERCISE_ENERGY_COST
	economy_hint.add_theme_color_override("font_color", Color("9fc4bb"))
	economy_hint.add_theme_font_size_override("font_size", 11)
	economy_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	economy_hint.custom_minimum_size = Vector2(210, 0)
	box.add_child(economy_hint)

	if reward_cost > 0:
		var sep := HSeparator.new()
		box.add_child(sep)
		reward_name_label = Label.new()
		reward_name_label.add_theme_color_override("font_color", Color("e7fff8"))
		reward_name_label.add_theme_font_size_override("font_size", 13)
		reward_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_name_label.custom_minimum_size = Vector2(210, 0)
		box.add_child(reward_name_label)
		reward_bar = ProgressBar.new()
		reward_bar.show_percentage = false
		reward_bar.max_value = 100.0
		reward_bar.custom_minimum_size = Vector2(210, 12)
		box.add_child(reward_bar)
		reward_remaining_label = Label.new()
		reward_remaining_label.add_theme_color_override("font_color", Color("9fc4bb"))
		reward_remaining_label.add_theme_font_size_override("font_size", 12)
		box.add_child(reward_remaining_label)

	_refresh_economy()

func _refresh_economy() -> void:
	if runtime.is_empty():
		return
	var current := int(runtime.get("energy", 0))
	if is_instance_valid(energy_label):
		energy_label.text = "Energia %d" % current
	if is_instance_valid(fragment_label):
		fragment_label.text = "Frammenti %d" % int(runtime.get("fragments", 0))
	if reward_cost > 0 and is_instance_valid(reward_bar):
		reward_name_label.text = "Prossimo: %s" % reward_name
		reward_bar.value = clampf(float(current) / float(reward_cost) * 100.0, 0.0, 100.0)
		var remaining := maxi(0, reward_cost - current)
		reward_remaining_label.text = ("Ti manca %d energia" % remaining) if remaining > 0 else "Puoi comprarlo!"

func _spawn_gain_popup(text: String, color: Color) -> void:
	if not is_instance_valid(player):
		return
	var label := _acquire_gain_popup()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.z_index = 70
	label.position = player.position + Vector2(-24, -50)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 44.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.set_parallel(false)
	tween.tween_callback(_release_gain_popup.bind(label))

func _acquire_gain_popup() -> Label:
	for label in gain_popup_pool:
		if is_instance_valid(label) and not label.visible:
			label.visible = true
			label.modulate = Color.WHITE
			return label
	var label := Label.new()
	label.visible = true
	gain_popup_pool.append(label)
	world_layer.add_child(label)
	return label

func _release_gain_popup(label: Label) -> void:
	if not is_instance_valid(label):
		return
	label.visible = false
	label.text = ""
	label.modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	# Le azioni di gameplay devono arrivare prima dei Control dell'HUD. In Web
	# un Control visibile/focalizzato puo consumare il tasto e impedire a
	# `_unhandled_input` di riceverlo: era il motivo per cui E non avviava i POI.
	# Durante un esercizio lasciamo invece tutto l'input alla sua UI.
	if is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible:
		return
	if is_instance_valid(exercise_player) and exercise_player.visible:
		return
	if is_instance_valid(shop_panel) and shop_panel.visible:
		if event.is_action_pressed("leave_portal") and not event.is_echo():
			shop_panel.close_panel()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("leave_portal") and not event.is_echo():
		_guide_to_ship()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_world_tap(_to_world(event.position))
	elif event is InputEventScreenDrag:
		_cancel_pending_touch_interaction()
		player.set_touch_target(_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_world_tap(_to_world(event.position))
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_cancel_pending_touch_interaction()
		player.set_touch_target(_to_world(event.position))

func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _spawn_touch_ping(world_pos: Vector2) -> void:
	var ping := Node2D.new()
	ping.position = world_pos
	ping.z_index = 60
	ping.add_child(OutdoorVisualFactory.make_ring(16, Color(PLAYER_ACCENT, 0.9), 2.5, 22))
	OutdoorVisualFactory.attach_anim(ping, "ping", 1.0, 1.0)
	world_layer.add_child(ping)

func _handle_world_tap(world_pos: Vector2) -> void:
	if not is_instance_valid(player):
		return
	var target := _interactable_at(world_pos)
	if target == null:
		_cancel_pending_touch_interaction()
		player.set_touch_target(world_pos)
		_spawn_touch_ping(world_pos)
		return
	pending_touch_interaction = target
	var approach := _touch_approach_position(target)
	player.set_touch_target(approach)
	_spawn_touch_ping(target.global_position)
	if player.global_position.distance_to(target.global_position) <= INTERACTION_DISTANCE:
		_update_pending_touch_interaction()
	else:
		_set_feedback("Eli si avvicina · %s" % _interaction_action_text(target).to_lower())

func _interactable_at(world_pos: Vector2) -> Area2D:
	var best: Area2D = null
	var best_distance := TOUCH_POI_RADIUS * TOUCH_POI_RADIUS
	for node in get_tree().get_nodes_in_group("world_interactable"):
		if not node is Area2D or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var area := node as Area2D
		var distance := world_pos.distance_squared_to(area.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = area
	return best

func _touch_approach_position(target: Area2D) -> Vector2:
	var away := target.global_position.direction_to(player.global_position)
	if away.is_zero_approx():
		away = Vector2.DOWN
	return chunks.clamp_to_world(target.global_position + away * TOUCH_APPROACH_DISTANCE)

func _update_pending_touch_interaction() -> void:
	if pending_touch_interaction == null:
		return
	if not is_instance_valid(pending_touch_interaction) or pending_touch_interaction.is_queued_for_deletion():
		pending_touch_interaction = null
		return
	var distance := player.global_position.distance_to(pending_touch_interaction.global_position)
	if distance <= INTERACTION_DISTANCE:
		var target := pending_touch_interaction
		pending_touch_interaction = null
		if not nearby.has(target):
			nearby.append(target)
		_refresh_prompt()
		_interact()
	elif player.touch_target == Vector2.INF:
		# Movimento manuale o arrivo impossibile: niente interazioni ritardate a
		# sorpresa. Il pulsante contestuale resta disponibile se Eli è vicino.
		pending_touch_interaction = null

func _cancel_pending_touch_interaction() -> void:
	pending_touch_interaction = null

func on_interactable_entered(area: Area2D, body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not nearby.has(area):
		nearby.append(area)
	_refresh_prompt()

func on_interactable_exited(area: Area2D, body: Node) -> void:
	if not body.is_in_group("player"):
		return
	nearby.erase(area)
	_refresh_prompt()

func _nearest() -> Area2D:
	var valid: Array = []
	var best: Area2D = null
	var best_distance := INF
	for area in nearby:
		if not is_instance_valid(area):
			continue
		valid.append(area)
		var distance := player.global_position.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	nearby = valid
	return best

func _refresh_prompt() -> void:
	var target := _nearest()
	_refresh_interaction_button(target)
	if target == null:
		_set_feedback("")
		return
	var kind := str(target.get_meta("kind"))
	var id := str(target.get_meta("id"))
	if kind == "portal":
		_set_feedback(_ship_entry_prompt())
	elif kind == "enigma":
		var payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s è già ricostruito" % str(payload.get("label", "L'enigma")).capitalize())
		else:
			_set_feedback("Interagisci per ricostruire %s con gli esercizi" % str(payload.get("label", "il ponte")))
	elif kind == "minigame":
		var mg_payload: Dictionary = target.get_meta("payload")
		_set_feedback("Interagisci · %s: minigioco di %s" % [str(mg_payload.get("label", "Palestra")), str(mg_payload.get("subject", "matematica")).capitalize()])
	elif kind == "treasure":
		if result["collectedTreasureIds"].has(id):
			_set_feedback("Tesoro già raccolto")
		else:
			_set_feedback("Interagisci per raccogliere il tesoro")
	elif kind == "encounter":
		var payload := _mission_payload_for(target)
		if result["completedEncounterIds"].has(id):
			_set_feedback("Incontro già completato")
		else:
			_set_feedback("Interagisci · missione di %s: %s" % [
				str(payload.get("subject", "matematica")).capitalize(),
				str(payload.get("label", "incontro"))])

func _refresh_interaction_button(target: Area2D) -> void:
	if not is_instance_valid(interaction_button):
		return
	var blocked := target == null or (is_instance_valid(exercise_player) and exercise_player.visible) or (is_instance_valid(shop_panel) and shop_panel.visible) or (is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible)
	interaction_button.visible = not blocked
	if blocked:
		return
	var completed := _interaction_is_completed(target)
	interaction_button.disabled = completed
	interaction_button.text = "✓ GIÀ COMPLETATO" if completed else _interaction_action_text(target)
	interaction_button.tooltip_text = "Azione contestuale disponibile con tocco, click o tastiera"

func _interaction_action_text(target: Area2D) -> String:
	if target == null:
		return "INTERAGISCI"
	match str(target.get_meta("kind", "")):
		"portal":
			return "ENTRA NELLA NAVE"
		"enigma":
			return "RICOSTRUISCI"
		"minigame":
			return "ALLENATI"
		"treasure":
			return "RACCOGLI"
		"encounter":
			return "AVVIA MISSIONE"
	return "INTERAGISCI"

func _interaction_is_completed(target: Area2D) -> bool:
	var kind := str(target.get_meta("kind", ""))
	var id := str(target.get_meta("id", ""))
	if kind == "treasure":
		return Array(result.get("collectedTreasureIds", [])).has(id)
	if kind == "encounter" or kind == "enigma":
		return Array(result.get("completedEncounterIds", [])).has(id)
	return false

func _interact() -> void:
	var target := _nearest()
	if target == null:
		_set_feedback("Avvicinati a un tesoro, a un incontro o al portale.")
		return
	var kind := str(target.get_meta("kind"))
	var id := str(target.get_meta("id"))
	var completed: Array = result["completedEncounterIds"]
	if kind == "portal":
		_set_feedback("Ingresso nave attivo: salvataggio in corso…")
		_leave_world()
		return
	if kind == "enigma":
		var enigma_payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s è già ricostruito." % str(enigma_payload.get("label", "L'enigma")).capitalize())
			return
		gameplay.try_start_enigma(enigma_payload, id)
		return
	if kind == "minigame":
		# Pratica ripetibile sulla materia dominante del bioma (nessun lock).
		gameplay.try_start_minigame(target.get_meta("payload"), id)
		return
	if kind == "treasure":
		var payload: Dictionary = target.get_meta("payload")
		var collected: Array = result["collectedTreasureIds"]
		if collected.has(id):
			_set_feedback("Questa cassa è già stata raccolta.")
		else:
			collected.append(id)
			gameplay.collect_treasure(payload, id)
			_update_objective()
			_set_feedback("Tesoro raccolto: +%d frammenti. L'energia si guadagna solo con gli esercizi." % int(payload["rewardFragments"]))
			_refresh_economy()
			_spawn_gain_popup("+%d frammenti" % int(payload["rewardFragments"]), Color("c7b8ff"))
			if is_instance_valid(pet_companion):
				pet_companion.react()
			nearby.erase(target)
			var owner_node := target.get_parent()
			if is_instance_valid(owner_node):
				owner_node.queue_free()
			_refresh_prompt()
		return
	if kind == "encounter":
		var mission_payload := _mission_payload_for(target)
		if result["completedEncounterIds"].has(id):
			_set_feedback("Incontro già completato.")
			return
		gameplay.try_start_mission(mission_payload, id)
		return


func _on_exercise_finished(exercise_result: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	exercise_player.visible = false
	if is_instance_valid(player):
		player.set_physics_process(true)
	if is_instance_valid(gameplay):
		var context := gameplay.active_session_context.duplicate(true)
		gameplay.resolve_session(exercise_result)
		if bool(exercise_result.get("passed", false)) and str(context.get("kind", "")) in ["mission", "enigma"]:
			_complete_learning_reaction(str(context.get("encounterId", "")))
	_refresh_economy()
	_refresh_prompt()

func _on_exercise_progress(correct: int, total: int) -> void:
	if not is_instance_valid(gameplay):
		return
	gameplay.notify_progress(correct, total)
	var encounter_id := str(gameplay.active_session_context.get("encounterId", ""))
	if encounter_id == "":
		return
	for node in get_tree().get_nodes_in_group("world_interactable"):
		if node is Area2D and str(node.get_meta("id", "")) == encounter_id:
			var reaction := node.get_node_or_null("LearningReaction")
			if reaction != null and reaction.has_method("set_progress"):
				reaction.call("set_progress", correct, total, true)
			break

func _complete_learning_reaction(encounter_id: String) -> void:
	if encounter_id == "":
		return
	for node in get_tree().get_nodes_in_group("world_interactable"):
		if node is Area2D and str(node.get_meta("id", "")) == encounter_id:
			var reaction := node.get_node_or_null("LearningReaction")
			if reaction != null and reaction.has_method("set_complete"):
				reaction.call("set_complete", true, true)
			break

# Progresso dell'enigma: feedback testuale + popup a ogni campata (gameplay-only).
# Aggiorna SOLO il POI il cui meta "id" combacia con l'encounter_id attivo (più
# enigmi condividono il gruppo "enigma_poi": senza questo filtro, rispondere
# all'enigma di coding farebbe "costruire" anche il ponte di matematica). Se
# Codex non ha ancora attaccato un visual con `set_stage` a quel POI, resta un
# no-op sicuro e vale solo il riscontro testuale.
func _on_enigma_progress(built: int, total: int, theme: String, encounter_id: String) -> void:
	for area in get_tree().get_nodes_in_group("enigma_poi"):
		if area is Area2D and str(area.get_meta("id", "")) == encounter_id:
			for child in area.get_children():
				if child.has_method("set_stage"):
					child.set_stage(built, total)
	if built <= 0:
		_set_feedback("Enigma avviato: costruisci %s rispondendo (%d campate)" % [theme, total])
		return
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "enigmaProgress", lerpf(0.9, 1.12, float(built) / maxf(float(total), 1.0)))
	_set_feedback("%s: %d/%d campate costruite" % [theme.capitalize(), built, total])
	_spawn_gain_popup("+1 campata", Color("8ff6c0"))

func _leave_world() -> void:
	if is_instance_valid(gameplay):
		if is_instance_valid(player):
			gameplay.game_save.set_world_resume(str(world_level), player.global_position, day_clock)
		gameplay.game_save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "portalOpened")
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _guide_to_ship() -> void:
	if not is_instance_valid(player):
		return
	player.set_touch_target(PORTAL_POSITION)
	var apparatus := str(runtime.get("apparatus", "nucleo")).replace("-", " ").capitalize()
	var message := "Ingresso nave evidenziato. Raggiungi il portale."
	if bool(runtime.get("ready", false)):
		message = "%s pronto: torna alla nave per l'esame finale." % apparatus
	_set_feedback(message)
	_spawn_touch_ping(PORTAL_POSITION)

func _guide_to_objective() -> void:
	if bool(runtime.get("ready", false)) or bool(runtime.get("complete", false)):
		_guide_to_ship()
		return
	var mission := _nearest_available_mission()
	if mission == null:
		_set_feedback("Nessuna missione disponibile nei settori vicini. Esplora il sentiero.")
		return
	player.set_touch_target(mission.global_position)
	var payload := _mission_payload_for(mission)
	_set_feedback("Rotta impostata: missione di %s · %s" % [
		str(payload.get("subject", "matematica")).capitalize(),
		str(payload.get("label", "incontro"))])
	_spawn_touch_ping(mission.global_position)

func _ship_entry_prompt() -> String:
	var apparatus := str(runtime.get("apparatus", "nucleo")).replace("-", " ").capitalize()
	if bool(runtime.get("complete", false)):
		return "Interagisci per entrare nella nave completamente riattivata"
	if bool(runtime.get("ready", false)):
		return "Interagisci per entrare nella nave · esame %s pronto" % apparatus
	return "Interagisci per entrare nella nave · %s ancora in preparazione" % apparatus

func _update_ship_navigation() -> void:
	if not is_instance_valid(ship_navigation_label) or not is_instance_valid(player):
		return
	var target_position := PORTAL_POSITION
	var prefix := "ESAME PRONTO" if bool(runtime.get("ready", false)) else "INGRESSO NAVE"
	var mission: Area2D = null
	if not bool(runtime.get("ready", false)) and not bool(runtime.get("complete", false)):
		mission = _nearest_available_mission()
		if mission != null:
			target_position = mission.global_position
			prefix = "MISSIONE %s" % str(_mission_payload_for(mission).get("subject", _world_subject())).to_upper()
	if bool(runtime.get("complete", false)):
		prefix = "NAVE RIATTIVATA"
	var delta := target_position - player.global_position
	var steps := maxi(0, int(round(delta.length() / 32.0)))
	var arrow := _direction_arrow(delta)
	ship_navigation_label.text = "%s  %s  ·  %d passi" % [prefix, arrow, steps]
	ship_navigation_label.add_theme_color_override(
		"font_color",
		Color("f6c85f") if bool(runtime.get("ready", false)) or bool(runtime.get("complete", false)) else PLAYER_ACCENT
	)
	if is_instance_valid(guide_button):
		guide_button.text = "RAGGIUNGI LA NAVE" if bool(runtime.get("ready", false)) or bool(runtime.get("complete", false)) else "TROVA UNA MISSIONE"

func _nearest_available_mission() -> Area2D:
	if not is_instance_valid(player):
		return null
	var completed: Array = result.get("completedEncounterIds", [])
	var best: Area2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("mission_poi"):
		if not node is Area2D or not is_instance_valid(node):
			continue
		var area := node as Area2D
		if completed.has(str(area.get_meta("id", ""))):
			continue
		var distance := player.global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	return best

func _mission_payload_for(area: Area2D) -> Dictionary:
	if area == null:
		return {}
	var payload: Dictionary = Dictionary(area.get_meta("payload", {})).duplicate(true)
	# Compatibilità difensiva per POI non-director; gli eventi O-P1 dichiarano
	# sempre la materia e restano autoritativi.
	if str(payload.get("subject", "")).strip_edges() == "":
		payload["subject"] = _world_subject()
	return payload

func _direction_arrow(delta: Vector2) -> String:
	if delta.length() < INTERACTION_DISTANCE:
		return "◎"
	var angle := fposmod(delta.angle() + PI / 8.0, TAU)
	var index := int(floor(angle / (PI / 4.0))) % 8
	var arrows := PackedStringArray(["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"])
	return arrows[index]

func _set_feedback(message: String) -> void:
	_present_feedback(message, "system")

func _set_nora_feedback(message: String) -> void:
	_present_feedback(message, "nora")

func _present_feedback(message: String, source: String = "system") -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = message
	if is_instance_valid(feedback_panel):
		feedback_panel.visible = message != ""
	if is_instance_valid(feedback_source_label):
		feedback_source_label.text = "NORA" if source == "nora" else "SISTEMA"
		feedback_source_label.add_theme_color_override("font_color", Color("6be7d6") if source == "nora" else Color("9fc4bb"))
	if message != "" and source == "nora" and is_instance_valid(nora_portrait):
		nora_portrait.speak(message)

func _update_objective() -> void:
	if not is_instance_valid(objective_label) or runtime.is_empty():
		return
	var subject := str(runtime.get("focusSubject", "matematica")).capitalize()
	var profile_subject := _world_subject().capitalize()
	var apparatus := str(runtime.get("apparatus", "nucleo")).replace("-", " ").capitalize()
	if bool(runtime.get("complete", false)):
		objective_label.text = "NAVE COMPLETAMENTE RIATTIVATA\nTutti i 24 sistemi sono online"
	elif bool(runtime.get("ready", false)):
		objective_label.text = "LIVELLO %d · %s\n%s PRONTO\nRaggiungi la nave per l’esame finale" % [
			int(runtime.get("level", 1)), subject, apparatus.to_upper()]
	elif world_level != int(runtime.get("level", 1)):
		objective_label.text = "MONDO %d · %s · RIVISITA\nFocus locale: %s · Frontiera: livello %d, %s\nLe missioni qui allenano %s; usa la nave per cambiare rotta" % [
			world_level, str(world_profile.get("title", "")), profile_subject,
			int(runtime.get("level", 1)), subject, profile_subject]
	else:
		objective_label.text = "Livello %d · Materia %s\nApparato: %s\nMissioni %d/%d · Padronanza %.0f%%/%.0f%%" % [
			int(runtime.get("level", 1)), subject, apparatus,
			int(runtime.get("missionsDone", 0)), int(runtime.get("missionsRequired", 0)),
			float(runtime.get("mastery", 0.0)) * 100.0, float(runtime.get("masteryThreshold", 0.0)) * 100.0]
