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
const PET_FACE_WIDGET_SCRIPT := preload("res://scripts/ui/pet_face_widget.gd")
const PET_SCREEN_SCRIPT := preload("res://scripts/ui/pet_screen.gd")
const EQUIPMENT_GATE_SCRIPT := preload("res://scripts/visual/equipment_gate.gd")
const WORLD_ENEMY_SCRIPT := preload("res://scripts/world_enemy.gd")
const NPC_ACTOR_SCRIPT := preload("res://scripts/game/npc_actor.gd")
const NPC_CATALOG := preload("res://scripts/game/npc_catalog.gd")
const ITINERANT_CATALOG := preload("res://scripts/game/itinerant_catalog.gd")
const FINALE_CATALOG := preload("res://scripts/game/finale_catalog.gd")
const MAESTRI_CATALOG := preload("res://scripts/game/maestri_catalog.gd")
const TEACHING_CATALOG := preload("res://scripts/game/teaching_catalog.gd")
const MISSION_OWNERSHIP_FLOW_SCRIPT := preload("res://scripts/game/mission_ownership_flow.gd")
const BUILDING_CATALOG := preload("res://scripts/game/building_catalog.gd")
const BUILDING_ACTOR_SCRIPT := preload("res://scripts/game/building_actor.gd")
const WORLD_LIFE_SCRIPT := preload("res://scripts/game/world_life.gd")
const THIRTEENTH_DIRECTOR_SCRIPT := preload("res://scripts/game/thirteenth.gd")
const MYSTERY_CATALOG := preload("res://scripts/game/mystery_catalog.gd")
const MYSTERY_ARTIFACT_SCRIPT := preload("res://scripts/game/mystery_artifact.gd")
const DIALOGUE_BOX_SCRIPT := preload("res://scripts/ui/dialogue_box.gd")
const TEACHING_CHOICE_PANEL_SCRIPT := preload("res://scripts/ui/teaching_choice_panel.gd")

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
var pet_face: PetFaceWidget
var pet_screen: Control
var pet_naming_panel: PanelContainer
var _pet_cuddles_this_session := 0
var _pet_gift_rng: RandomNumberGenerator = null
var _pet_greeted: Dictionary = {}
var _pet_antic_count := 0
var _pet_antic_line_cursor := 0
var _pet_silent_antic := false
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
var utility_menu_button: Button
var shop_button: Button
var manual_button: Button
var interaction_button: Button
var pulse_button: Button
var touch_controls_button: Button
var touch_controls_panel: PanelContainer
var touch_side_button: Button
var touch_size_button: Button
var touch_opacity_button: Button
var high_contrast_button: Button
var reduced_motion_button: Button
var touch_controls_settings := {
	"side": "right",
	"size": "large",
	"opacity": 1.0,
}
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
var interaction_countdown_second := -1
var world_weather_particles: CPUParticles2D
var profile_night_tint := NIGHT_TINT
var profile_dawn_tint := DAWN_TINT
var profile_day_tint := Color.WHITE
var environment_transform: Dictionary = {}
var profile_hero_landmark: Node2D
var profile_environment_reaction: WorldLearningReaction
var last_traversable_position := Vector2.ZERO
var water_block_feedback_msec := 0
var pulse_ready_msec := 0
var high_contrast := false
var reduced_motion := false
var dialogue_box: Control
var npc_actors: Array[Area2D] = []
var npc_dialogue_cursors: Dictionary = {}
var mission_ownership_flow
var world_buildings: Array[Node2D] = []
var world_life
var thirteenth_director
var thirteenth_forgotten_npc := ""
var teaching_choice_panel: Control
var vera_teaching_pending := false
var vera_teaching_used := false
var vera_topic_key := ""
var ersilia_count_pending := false
var finale_convergence_wave := 0
var finale_wave_heard: Array[String] = []

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
document.documentElement.dataset.eliScene = 'world';
delete document.documentElement.dataset.eliExercise;
delete document.documentElement.dataset.eliExam;
""")
	if not launch_request_override.is_empty():
		request = launch_request_override.duplicate(true)
	else:
		var staged_request := NativeWorldState.take_launch_request()
		request = staged_request if not staged_request.is_empty() else NativeWorldState.default_request()
	var accessibility: Dictionary = request.get("accessibility", {})
	high_contrast = bool(accessibility.get("highContrast", false))
	reduced_motion = bool(accessibility.get("reducedMotion", false))
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
	var saved_accessibility: Dictionary = game_save.data.get("accessibility", {})
	if not bool(request.get("accessibilityExplicit", false)) and bool(request.get("loadLocalSave", true)):
		high_contrast = bool(saved_accessibility.get("highContrast", false))
		reduced_motion = bool(saved_accessibility.get("reducedMotion", false))
	progression_manager = gameplay.progression_manager
	content_manager = gameplay.content_manager
	_configure_world_profile()
	mission_ownership_flow = MISSION_OWNERSHIP_FLOW_SCRIPT.new()
	mission_ownership_flow.setup(
		world_level, mission_events, Array(result.get("completedEncounterIds", [])))
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
	_bind_water_crossing_events()
	if launch_stream_radius_override >= 0:
		chunks.active_radius = launch_stream_radius_override
	_create_player()
	_apply_resume()
	if _water_blocks_position(player.position):
		player.position = world_profile.get("spawn", PORTAL_POSITION + Vector2(0, 1180))
	last_traversable_position = player.position
	_create_portal()
	_create_profile_landmark()
	_create_profile_events()
	_create_world_buildings()
	_create_mystery_artifacts()
	_create_world_npcs()
	_create_world_life()
	_create_world_enemies()
	_sync_profile_environment_transform(false)
	_create_profile_weather()
	_create_atmosphere()
	_create_hud()
	_create_dialogue_box()
	_create_exercise_player()
	if is_instance_valid(knowledge_codex_panel):
		var lesson := WORLD_LESSON_CATALOG.lesson(world_level)
		knowledge_codex_panel.mark_encountered(str(lesson.get("subject", _world_subject())), Array(lesson.get("topics", [])))
	chunks.update_stream(player.position)
	var lesson_briefing := WORLD_LESSON_CATALOG.briefing(world_level)
	_set_nora_feedback(lesson_briefing if lesson_briefing != "" else str(gameplay.runtime_state().get("narrative", "")))
	_create_thirteenth_presence()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_environment", "day")
		audio.call("configure_world_soundscape", str(world_profile.get("soundscape", "")))
		audio.call("play_subject", _world_subject())
	_publish_web_accessibility_state()

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
	environment_transform = WORLD_LESSON_CATALOG.environment_transform(world_level)
	world_seed = "%s::%s" % [str(request.get("worldSeed", "outdoor-dev-1")), str(world_profile.get("id", "world-01-radura"))]
	mission_events = _planned_world_events()
	_align_enigma_to_water_crossing()
	_configure_profile_palette()

func _align_enigma_to_water_crossing() -> void:
	var preview := WorldCompositionGenerator.generate(world_seed, world_profile)
	if preview == null or preview.crossings.is_empty():
		return
	var crossing: Dictionary = preview.crossings[0]
	for index in range(mission_events.size()):
		var event: Dictionary = mission_events[index]
		if str(event.get("kind", "")) != "enigma":
			continue
		event["position"] = crossing.get("approach", event.get("position", Vector2.ZERO))
		event["crossingId"] = str(crossing.get("id", ""))
		event["bridgeCenter"] = crossing.get("position", event["position"])
		event["bridgeNormal"] = crossing.get("normal", Vector2.RIGHT)
		mission_events[index] = event
		return

func _bind_water_crossing_events() -> void:
	if chunks == null or chunks.composition == null:
		return
	for crossing_data in chunks.composition.crossings:
		var crossing: Dictionary = crossing_data
		for event_data in mission_events:
			var event: Dictionary = event_data
			if str(event.get("crossingId", "")) == str(crossing.get("id", "")):
				crossing["eventId"] = str(event.get("id", ""))
				break

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
	# Argomenti deboli e in scadenza per OGNI materia, non solo per quella del
	# mondo: gli eventi di varietà sono di altre materie, e un suggerimento filtrato
	# sul solo focus li lascerebbe senza priorità di ripasso — che è metà del motivo
	# per cui esistono.
	var due_by_subject: Dictionary = {}
	for key in SpacedRepetition.due_map(game_save).keys():
		var parts := str(key).split(":", true, 1)
		if parts.size() == 2:
			var bucket: Array = due_by_subject.get(parts[0], [])
			bucket.append(parts[1])
			due_by_subject[parts[0]] = bucket
	var weak_by_subject: Dictionary = {}
	for candidate in ApparatusConfig.SUBJECT_CYCLE:
		var masteries := game_save.topic_masteries(str(candidate))
		var weak: Array = []
		for topic in masteries.keys():
			if float(masteries.get(topic, 1.0)) < ContentManager.WEAK_TOPIC_THRESHOLD:
				weak.append(str(topic))
		if not weak.is_empty():
			weak_by_subject[str(candidate)] = weak
	var context := {
		# Quanti POI della materia ospite: presenza nel mondo, non requisito del gate.
		"missionsRequired": MissionEventDirector.HOST_EVENTS,
		# Compatibilità con i consumer che leggono ancora il solo focus.
		"weakTopics": Array(weak_by_subject.get(subject, [])),
		"dueTopics": Array(due_by_subject.get(subject, [])),
		"weakBySubject": weak_by_subject,
		"dueBySubject": due_by_subject,
		# Argomenti che la lezione del mondo promette: gli eventi del focus ci
		# restano sopra quando non c'è ripasso in sospeso.
		"lessonTopics": WORLD_LESSON_CATALOG.topics(world_level),
		"recentFormats": [],
	}
	var planned := MissionEventDirector.plan(world_profile, context, world_seed)
	# Il tetto deve lasciar passare TUTTE le materie: troncare qui farebbe sparire
	# sempre le ultime della rotazione, e alcune materie non comparirebbero mai in
	# nessun mondo. Gli eventi sono distribuiti su tutta l'area giocabile, quindi
	# quanti ne sono *attivi insieme* lo decide lo streaming, non questo elenco.
	var minimum := int(context["missionsRequired"]) + MissionEventDirector.GATE_SURPLUS \
		+ MissionEventDirector.other_subjects(subject).size()
	var budget := _profile_performance_budget()
	var maximum := maxi(minimum, int(budget.get("maxActivePois", 14)))
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
		"storia": Color("f2c96d"), "logica": Color("b7a2ff"),
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
	elif world_level == 5:
		profile_night_tint = Color("28252b")
		profile_dawn_tint = Color("b06f4f")
		profile_day_tint = Color("e3d5c7")
	elif world_level == 6:
		profile_night_tint = Color("56416e")
		profile_dawn_tint = Color("9e75bd")
		profile_day_tint = Color("dcd4ef")
	elif world_level == 7:
		profile_night_tint = Color("3f3029")
		profile_dawn_tint = Color("ca8d62")
		profile_day_tint = Color("ead9bf")
	elif world_level == 8:
		# Notte elettrica leggibile anche su tablet: il fondo è già scuro, quindi
		# la tinta deve preservare i mezzitoni anziché moltiplicarli fino al nero.
		profile_night_tint = Color("638f98")
		profile_dawn_tint = Color("246b72")
		profile_day_tint = Color("b9d9d7")
	elif world_level == 9:
		profile_night_tint = Color("365d73")
		profile_dawn_tint = Color("89b6c4")
		profile_day_tint = Color("e0f1ed")
	elif world_level == 10:
		profile_night_tint = Color("426b51")
		profile_dawn_tint = Color("91ba86")
		profile_day_tint = Color("dff0d7")
	elif world_level == 11:
		profile_night_tint = Color("5f4a3c")
		profile_dawn_tint = Color("d69a6e")
		profile_day_tint = Color("f0dfc5")
	elif world_level == 12:
		profile_night_tint = Color("4b607a")
		profile_dawn_tint = Color("7188a5")
		profile_day_tint = Color("d5deea")
	elif world_level == 13:
		# Notte desertica: sabbia e strumenti restano leggibili senza perdere il
		# cielo blu profondo richiesto dal profilo.
		profile_night_tint = Color("b8a4ac")
		profile_dawn_tint = Color("c88365")
		profile_day_tint = Color("ead0a2")
	elif world_level == 14:
		profile_night_tint = Color("664b62")
		profile_dawn_tint = Color("d39a72")
		profile_day_tint = Color("ead7bd")
	elif world_level == 15:
		# Neon controllato: preserva mezzitoni e contrasto sui pannelli tablet.
		profile_night_tint = Color("4f7183")
		profile_dawn_tint = Color("416b79")
		profile_day_tint = Color("b5d6da")
	elif world_level == 16:
		profile_night_tint = Color("5f5144")
		profile_dawn_tint = Color("e2a26b")
		profile_day_tint = Color("f0ddbc")
	elif world_level == 17:
		profile_night_tint = Color("4f7f91")
		profile_dawn_tint = Color("3e8190")
		profile_day_tint = Color("b8e2e6")
	elif world_level == 18:
		profile_night_tint = Color("765f83")
		profile_dawn_tint = Color("b77fa0")
		profile_day_tint = Color("e4d3e7")
	elif world_level == 19:
		# Penombra solenne ma leggibile: il fondale pittorico è già scuro.
		profile_night_tint = Color("b8a786")
		profile_dawn_tint = Color("b79161")
		profile_day_tint = Color("dfd0aa")
	elif world_level == 20:
		profile_night_tint = Color("58738f")
		profile_dawn_tint = Color("596990")
		profile_day_tint = Color("bac9df")
	elif world_level == 21:
		profile_night_tint = Color("8a8069")
		profile_dawn_tint = Color("c89c68")
		profile_day_tint = Color("e1d8b5")
	elif world_level == 22:
		profile_night_tint = Color("6c9781")
		profile_dawn_tint = Color("5d9c81")
		profile_day_tint = Color("b8dfc8")
	elif world_level == 23:
		profile_night_tint = Color("7185a3")
		profile_dawn_tint = Color("9aa9bd")
		profile_day_tint = Color("d8e0eb")
	elif world_level == 24:
		profile_night_tint = Color("6f668c")
		profile_dawn_tint = Color("c9a477")
		profile_day_tint = Color("f0dfbd")
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
	_update_building_stages()
	if world_life != null:
		world_life.set_stage(_npc_story_stage())
	if is_instance_valid(portal) and portal.has_method("set_gate_state"):
		portal.call("set_gate_state", bool(runtime.get("ready", false)), str(runtime.get("apparatus", "nucleo")), bool(runtime.get("complete", false)))

func _on_gameplay_session_requested(session: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(interaction_button):
		interaction_button.visible = false
	if is_instance_valid(touch_controls_panel):
		touch_controls_panel.visible = false
	_set_feedback("")
	if is_instance_valid(player):
		player.set_physics_process(false)
	exercise_player.visible = true
	var accessible_session := session.duplicate(true)
	accessible_session["accessibility"] = {
		"highContrast": high_contrast,
		"reducedMotion": reduced_motion,
	}
	var maestro_voice := _maestro_voice_for_session(accessible_session)
	if not maestro_voice.is_empty():
		accessible_session["maestroVoice"] = maestro_voice
	exercise_player.start_session(accessible_session)

func _maestro_voice_for_session(session: Dictionary) -> Dictionary:
	var subject := str(session.get("subject", _world_subject()))
	var maestro := MAESTRI_CATALOG.maestro_of(subject)
	if maestro.is_empty():
		return {}
	var repaired: Array = []
	for apparatus_id in Dictionary(game_save.data.get("apparatus", {})).keys():
		if int(Dictionary(game_save.data["apparatus"][apparatus_id]).get("repairedLevel", 0)) > 0:
			repaired.append(str(apparatus_id))
	var narrative: Dictionary = game_save.data.get("narrative", {})
	var thirteenth: Dictionary = narrative.get("thirteenth", {})
	var subjects_met: Array = []
	for unlocked_level in game_save.unlocked_worlds():
		var subject_met := ApparatusConfig.world_subject(int(unlocked_level))
		if not subjects_met.has(subject_met):
			subjects_met.append(subject_met)
	var available := MAESTRI_CATALOG.voices_for(
		repaired,
		bool(thirteenth.get("nameRestored", false)),
		subjects_met
	)
	var maestro_id := str(maestro.get("id", ""))
	if not available.has(maestro_id):
		return {}
	var out := {"id": maestro_id, "name": str(maestro.get("nome", "NORA"))}
	var salt := str(session.get("sessionId", "%s:%d" % [world_seed, world_level]))
	for pool in ["apertura", "rilancio", "chiusura"]:
		var lines := MAESTRI_CATALOG.lines_of(maestro_id, pool)
		if not lines.is_empty():
			out[pool] = str(lines[posmod(hash("%s:%s" % [salt, pool]), lines.size())])
	return out

## Sensore ambientale, non un contatto: raggio più largo di `EnemyContact` (che
## respinge Eli), controllato ogni due secondi e non a ogni fotogramma — quattro
## nemici al massimo per mondo, ma non c'è motivo di ricalcolare le distanze
## sessanta volte al secondo per un avviso puramente atmosferico. Lo Sbiadito è
## già visibile a schermo: la faccia non rivela nulla che il bambino non veda.
const PET_FADED_SENSE_RADIUS := 110.0
const PET_FADED_CHECK_INTERVAL := 2.0
var _pet_faded_check_elapsed := 0.0

func _process(delta: float) -> void:
	if is_instance_valid(pet_companion):
		pet_companion.set_antics_blocked(_blocking_panel_visible())
	_pet_faded_check_elapsed += delta
	if _pet_faded_check_elapsed >= PET_FADED_CHECK_INTERVAL:
		_pet_faded_check_elapsed = 0.0
		_pet_check_faded_proximity()
	day_clock = fmod(day_clock + delta, DAY_LENGTH)
	var daylight := (sin(day_clock / DAY_LENGTH * TAU - PI / 2.0) + 1.0) * 0.5
	var phase_id := "giorno" if daylight > 0.72 else "alba" if daylight > 0.42 else "notte"
	if is_instance_valid(day_light):
		# notte → giorno con transizione calda (alba/tramonto) a metà corsa
		var base := profile_night_tint.lerp(profile_day_tint, daylight)
		# Senza torcia la notte è una vera condizione di esplorazione; con la
		# torcia resta scura globalmente ma il chiarore locale diventa ampio.
		# La notte deve cambiare lettura e valorizzare la torcia, non cancellare
		# Eli, POI e percorsi sui pannelli scolastici a contrasto ridotto.
		var night_depth := (1.0 - daylight) * (0.06 if equipped_field_tool() == "tool-torch" else 0.20)
		base = base.darkened(night_depth)
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
		atmosphere_material.set_shader_parameter("clock", 0.0 if reduced_motion else day_clock / DAY_LENGTH)
	_update_night_glow(daylight)
	if is_instance_valid(player):
		_enforce_water_traversal()
		chunks.update_stream(player.position)
		if is_instance_valid(camera):
			camera.position = player.position
		if is_instance_valid(fireflies):
			fireflies.emitting = not reduced_motion and daylight < 0.45
		if is_instance_valid(world_weather_particles):
			world_weather_particles.position = player.position
		_update_biome_hud()
		_update_ship_navigation()
		_update_pending_touch_interaction()
		_update_interaction_countdown()
		_update_pulse_button()
		if world_life != null:
			var view_size := get_viewport_rect().size
			if is_instance_valid(camera):
				view_size = Vector2(view_size.x / camera.zoom.x, view_size.y / camera.zoom.y)
			var visible_world := Rect2(player.global_position - view_size * 0.5, view_size)
			world_life.update(phase_id, player.global_position, visible_world, delta)
		_update_npc_streaming()

func _enforce_water_traversal() -> void:
	if not is_instance_valid(player) or chunks == null or chunks.composition == null:
		return
	if not _water_blocks_position(player.position):
		last_traversable_position = player.position
		return
	player.position = last_traversable_position
	player.velocity = Vector2.ZERO
	player.touch_target = Vector2.INF
	var now := Time.get_ticks_msec()
	if now - water_block_feedback_msec > 1500:
		water_block_feedback_msec = now
		_set_feedback("La corrente è invalicabile · ricostruisci il ponte-enigma dalla riva.")

func _water_blocks_position(position: Vector2) -> bool:
	if chunks == null or chunks.composition == null:
		return false
	var composition := chunks.composition
	# Le zone protette sono terra/causeway autorati: l'acqua viene già mascherata
	# anche visivamente e non costituisce un guado nascosto.
	if composition.is_protected(position):
		return false
	if composition.raw_water_weight(position) < 0.58:
		return false
	for crossing_data in composition.crossings:
		var crossing: Dictionary = crossing_data
		var event_id := str(crossing.get("eventId", ""))
		if event_id == "" or not Array(result.get("completedEncounterIds", [])).has(event_id):
			continue
		var delta := position - (crossing.get("position", Vector2.ZERO) as Vector2)
		var tangent: Vector2 = crossing.get("tangent", Vector2.DOWN)
		var normal: Vector2 = crossing.get("normal", Vector2.RIGHT)
		if absf(delta.dot(tangent)) <= 72.0 and absf(delta.dot(normal)) <= float(crossing.get("halfWidth", 100.0)) + 86.0:
			return false
	return true

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
		biome_label.text = "%s · %s" % [
			str(world_profile.get("terrainFamily", "territorio")).replace("-", " ").capitalize(),
			str(world_profile.get("topology", "percorso")).replace("-", " ").capitalize()]
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
	player.reduced_motion = reduced_motion
	_apply_accessory(player.visual, visual_data)
	_apply_emblem(player.visual, visual_data)
	_add_player_night_light()
	fireflies = OutdoorVisualFactory.make_sparkles(Color(1.0, 0.93, 0.62, 0.85), 560.0, 24)
	fireflies.lifetime = 5.0
	fireflies.preprocess = 3.0
	fireflies.scale_amount_min = 0.04
	fireflies.scale_amount_max = 0.08
	fireflies.add_to_group("night_glow")
	fireflies.emitting = not reduced_motion
	player.add_child(fireflies)
	world_layer.add_child(player)
	_spawn_pet(visual_data)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = player.position
	camera.position_smoothing_enabled = not reduced_motion
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
	_update_equipment_presentation()
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
	_update_equipment_presentation()

func equipped_field_tool() -> String:
	return str(Dictionary(runtime.get("cosmeticsEquipped", {})).get("tool", ""))

func _update_equipment_presentation() -> void:
	var tool := equipped_field_tool()
	if is_instance_valid(player):
		var light := player.get_node_or_null("PlayerNightLight") as PointLight2D
		if light != null:
			light.energy = 1.08 if tool == "tool-torch" else 0.10
			light.texture_scale = 3.0 if tool == "tool-torch" else 1.15
	for gate in get_tree().get_nodes_in_group("equipment_gate"):
		if gate.has_method("set_equipped_tool"):
			gate.call("set_equipped_tool", tool)

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
	# Il primo Custode non è un acquisto di bottega: dopo la consegna deve avere
	# un corpo nel mondo anche quando lo slot cosmetico `pet` è vuoto.
	if typeof(pet_data) != TYPE_DICTIONARY and PetState.is_granted(game_save):
		pet_data = {"kind": "spark"}
	if typeof(pet_data) != TYPE_DICTIONARY:
		return
	var palette := PetState.livery(game_save)
	var color := OutdoorVisualFactory.hex_color(
		int(palette[0]) if not palette.is_empty() else int(pet_data.get("color", 0xf6c85f)))
	pet_companion = OutdoorPetCompanion.new()
	world_layer.add_child(pet_companion)
	pet_companion.setup(
		str(pet_data.get("kind", "spark")), color, player,
		PetState.temperament(game_save), reduced_motion)
	pet_companion.configure_antics(PetState.antics(game_save))
	pet_companion.antic_started.connect(_on_pet_antic)

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
	if world_level == 1:
		return PORTAL_POSITION + Vector2(160, 1050)
	if world_level == 3:
		return PORTAL_POSITION + Vector2(0, 1280)
	if world_level == 4:
		return PORTAL_POSITION + Vector2(1320, 1280)
	if world_level == 5:
		return PORTAL_POSITION + Vector2(-180, 1450)
	if world_level == 6:
		return PORTAL_POSITION + Vector2(0, 1400)
	if world_level == 7:
		return PORTAL_POSITION + Vector2(0, 1450)
	if world_level == 8:
		return PORTAL_POSITION + Vector2(0, 1420)
	if world_level == 9:
		return PORTAL_POSITION + Vector2(0, 1420)
	if world_level == 10:
		return PORTAL_POSITION + Vector2(0, 1400)
	if world_level == 11:
		return PORTAL_POSITION + Vector2(0, 1450)
	if world_level == 12:
		return PORTAL_POSITION + Vector2(0, 1420)
	if world_level == 13:
		return PORTAL_POSITION + Vector2(0, 1460)
	if world_level == 14:
		return PORTAL_POSITION + Vector2(0, 1500)
	if world_level == 15:
		return PORTAL_POSITION + Vector2(0, 1510)
	if world_level == 16:
		return PORTAL_POSITION + Vector2(120, 1520)
	if world_level == 17:
		return PORTAL_POSITION + Vector2(0, 1460)
	if world_level == 18:
		return PORTAL_POSITION + Vector2(0, 1510)
	if world_level == 19:
		return PORTAL_POSITION + Vector2(0, 1460)
	if world_level == 20:
		return PORTAL_POSITION + Vector2(0, 1510)
	if world_level == 21:
		return PORTAL_POSITION + Vector2(0, 1460)
	if world_level == 22:
		return PORTAL_POSITION + Vector2(0, 1460)
	if world_level == 23:
		return PORTAL_POSITION + Vector2(0, 1510)
	if world_level == 24:
		return PORTAL_POSITION + Vector2(0, 1690)
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
	elif world_level == 5:
		specs = [
			{"kind": "rail_switch", "offset": Vector2(-154, 48), "variant": 0.25},
			{"kind": "motion_piston", "offset": Vector2(154, 48), "variant": 0.76},
		]
	elif world_level == 6:
		specs = [
			{"kind": "echo_bloom", "offset": Vector2(-150, 44), "variant": 0.24},
			{"kind": "tuning_pod", "offset": Vector2(150, 44), "variant": 0.72},
		]
	elif world_level == 7:
		specs = [
			{"kind": "glyph_stele", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "mosaic_brazier", "offset": Vector2(150, 46), "variant": 0.74},
		]
	elif world_level == 8:
		specs = [
			{"kind": "circuit_node", "offset": Vector2(-150, 46), "variant": 0.26},
			{"kind": "coil_tower", "offset": Vector2(150, 46), "variant": 0.77},
		]
	elif world_level == 9:
		specs = [
			{"kind": "route_beacon", "offset": Vector2(-150, 44), "variant": 0.24},
			{"kind": "contour_plinth", "offset": Vector2(150, 44), "variant": 0.74},
		]
	elif world_level == 10:
		specs = [
			{"kind": "pollinator_lamp", "offset": Vector2(-150, 44), "variant": 0.25},
			{"kind": "symbiosis_pod", "offset": Vector2(150, 44), "variant": 0.75},
		]
	elif world_level == 11:
		specs = [
			{"kind": "source_stele", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "timeline_relay", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 12:
		specs = [
			{"kind": "rule_node", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "logic_gate", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 13:
		specs = [
			{"kind": "trajectory_pylon", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "fraction_dial", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 14:
		specs = [
			{"kind": "memory_lantern", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "echo_lectern", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 15:
		specs = [
			{"kind": "data_relay", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "debug_console", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 16:
		specs = [
			{"kind": "passage_beacon", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "market_stall", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 17:
		specs = [
			{"kind": "pressure_buoy", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "current_vane", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 18:
		specs = [
			{"kind": "organ_pipe", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "timbre_resonator", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 19:
		specs = [
			{"kind": "crypt_lantern", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "lineage_tablet", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 20:
		specs = [
			{"kind": "sensor_probe", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "surge_grounder", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 21:
		specs = [
			{"kind": "climate_beacon", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "fault_marker", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 22:
		specs = [
			{"kind": "cell_pod", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "adaptation_spore", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 23:
		specs = [
			{"kind": "roman_archive_pod", "offset": Vector2(-150, 46), "variant": 0.25},
			{"kind": "medieval_archive_pod", "offset": Vector2(150, 46), "variant": 0.75},
		]
	elif world_level == 24:
		specs = [
			{"kind": "system_pylon", "offset": Vector2(-150, 46), "variant": 0.0},
			{"kind": "system_pylon", "offset": Vector2(150, 46), "variant": 1.0},
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
		"storia": "forge", "logica": "logicSpire",
	}
	var landmark_kind := (
		"cycleMachine" if world_level == 3 else
		"signalLighthouse" if world_level == 4 else
		"motionLever" if world_level == 5 else
		"resonantTree" if world_level == 6 else
		"glyphArch" if world_level == 7 else
		"circuitNode" if world_level == 8 else
		"cartographyTower" if world_level == 9 else
		"livingDome" if world_level == 10 else
		"timeThreshold" if world_level == 11 else
		"labyrinthHeart" if world_level == 12 else
		"orbitalObservatory" if world_level == 13 else
		"hallOfVoices" if world_level == 14 else
		"controlTower" if world_level == 15 else
		"languageGate" if world_level == 16 else
		"underwaterCathedral" if world_level == 17 else
		"grandOrgan" if world_level == 18 else
		"rootTree" if world_level == 19 else
		"fieldTower" if world_level == 20 else
		"tectonicPillar" if world_level == 21 else
		"livingCore" if world_level == 22 else
		"hallOfEras" if world_level == 23 else
		"firstHeart" if world_level == 24 else
		str(kinds.get(subject, "skyTree"))
	)
	var label := str(names[0]).replace("-", " ").capitalize()
	var landmark := OutdoorVisualFactory.build_landmark(
		landmark_kind, label, _profile_accent_rgb())
	# Il landmark espone una sola caption funzionale con stato/progresso; la
	# label puramente ornamentale del builder produrrebbe un doppione.
	for decorative_label in landmark.find_children("*", "Label", true, false):
		(decorative_label as Label).visible = false
	landmark.name = "ProfileHeroLandmark"
	landmark.set_meta("landmark_kind", landmark_kind)
	landmark.set_meta("transform_trigger", str(environment_transform.get("trigger", "")))
	landmark.set_meta("transform_effect", str(environment_transform.get("effect", "")))
	landmark.position = _hero_landmark_position()
	landmark.scale = Vector2.ONE * (1.48 if world_level == 24 else 1.34 if world_level == 21 else 1.52 if world_level in [3, 4] else 1.48 if world_level in [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23] else 1.32)
	world_layer.add_child(landmark)
	profile_hero_landmark = landmark
	var landmark_area := Area2D.new()
	landmark_area.name = "HeroLandmarkInteraction"
	landmark_area.add_to_group("world_interactable")
	landmark_area.set_meta("kind", "landmark")
	landmark_area.set_meta("id", "hero-landmark")
	landmark_area.set_meta("payload", {
		"label": label,
		"purpose": str(environment_transform.get("effect", "si trasforma completando le missioni")),
	})
	var landmark_shape := CollisionShape2D.new()
	var landmark_circle := CircleShape2D.new()
	landmark_circle.radius = INTERACTION_DISTANCE + 34.0
	landmark_shape.shape = landmark_circle
	landmark_area.add_child(landmark_shape)
	landmark.add_child(landmark_area)
	landmark_area.body_entered.connect(func(body): on_interactable_entered(landmark_area, body))
	landmark_area.body_exited.connect(func(body): on_interactable_exited(landmark_area, body))
	var purpose := _make_landmark_caption(label, 0, 1)
	landmark.add_child(purpose)
	profile_environment_reaction = LEARNING_REACTION_SCRIPT.new()
	profile_environment_reaction.setup(
		_learning_reaction_theme(),
		"world",
		OutdoorVisualFactory.hex_color(_profile_accent_rgb()),
		environment_transform,
		true)  # landmark: una sola per mondo, costruita subito
	profile_environment_reaction.name = "ProfileEnvironmentTransform"
	profile_environment_reaction.position = _hero_landmark_position() + Vector2(0, 42)
	profile_environment_reaction.scale = Vector2.ONE * (2.0 if world_level == 24 else 1.75 if world_level in [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] else 1.35)
	world_layer.add_child(profile_environment_reaction)

func _learning_reaction_theme() -> String:
	if world_level == 2:
		return "archive"
	if world_level == 3:
		return "crater"
	if world_level == 4:
		return "signal_bay"
	if world_level == 5:
		return "motion_forge"
	if world_level == 6:
		return "resonance_garden"
	if world_level == 7:
		return "glyph_ruins"
	if world_level == 8:
		return "circuit_delta"
	if world_level == 9:
		return "charted_archipelago"
	if world_level == 10:
		return "symbiosis_greenhouse"
	if world_level == 11:
		return "history_threshold"
	if world_level == 12:
		return "rule_labyrinth"
	if world_level == 13:
		return "orbital_desert"
	if world_level == 14:
		return "voices_library"
	if world_level == 15:
		return "machine_city"
	if world_level == 16:
		return "language_frontier"
	if world_level == 17:
		return "force_ocean"
	if world_level == 18:
		return "sound_cathedral"
	if world_level == 19:
		return "root_necropolis"
	if world_level == 20:
		return "electromagnetic_storm"
	if world_level == 21:
		return "fractured_atlas"
	if world_level == 22:
		return "deep_biosphere"
	if world_level == 23:
		return "hall_of_eras"
	if world_level == 24:
		return "first_heart"
	return "radura"

func _sync_profile_environment_transform(animate: bool) -> void:
	if not is_instance_valid(profile_environment_reaction):
		return
	var completed_ids: Array = result.get("completedEncounterIds", [])
	var completed_count := 0
	var total_count := 0
	for event_data in mission_events:
		var event: Dictionary = event_data
		if not bool(event.get("countsForGate", false)):
			continue
		total_count += 1
		if completed_ids.has(str(event.get("id", ""))):
			completed_count += 1
	profile_environment_reaction.set_progress(completed_count, total_count, animate)
	var ratio := clampf(float(completed_count) / maxf(float(total_count), 1.0), 0.0, 1.0)
	if not is_instance_valid(profile_hero_landmark):
		return
	var purpose := profile_hero_landmark.get_node_or_null("LandmarkPurpose") as Label
	if purpose != null:
		purpose.text = "%s\nPROGRESSO %d/%d" % [
			str(world_profile.get("heroLandmarks", ["PUNTO CHIAVE"])[0]).replace("-", " ").to_upper(),
			completed_count,
			total_count,
		]
	var art := profile_hero_landmark.find_child("Landmark*Art", true, false) as CanvasItem
	if art == null:
		return
	var target := Color(0.76, 0.82, 0.91, 0.86).lerp(Color.WHITE, ratio)
	if animate and not reduced_motion:
		var tween := create_tween()
		tween.tween_property(art, "modulate", target, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		art.modulate = target

func _create_profile_events() -> void:
	for event_data in mission_events:
		var event: Dictionary = event_data
		var director_kind := str(event.get("kind", "mission"))
		var scene_kind := "encounter" if director_kind == "mission" else "minigame" if director_kind == "practice" else "enigma"
		var event_id := str(event.get("id", ""))
		var completed := (
			director_kind != "practice"
			and Array(result.get("completedEncounterIds", [])).has(event_id)
		)
		var area := Area2D.new()
		area.name = "MissionEvent_%s" % event_id.replace("-", "_")
		area.position = event.get("position", Vector2.ZERO)
		area.monitoring = not completed
		area.monitorable = not completed
		area.set_meta("completed", completed)
		if not completed:
			area.add_to_group("world_interactable")
			if bool(event.get("countsForGate", false)):
				area.add_to_group("mission_poi")
			if director_kind == "enigma":
				area.add_to_group("enigma_poi")
			elif director_kind == "practice":
				area.add_to_group("minigame_poi")
		area.set_meta("kind", scene_kind)
		area.set_meta("id", event_id)
		area.set_meta("directorEvent", event.duplicate(true))
		var payload := {
			"subject": str(event.get("subject", _world_subject())),
			"label": _event_label(event),
			"format": str(event.get("format", "multiple_choice")),
			"topicHint": str(event.get("topicHint", "")),
			"countsForGate": bool(event.get("countsForGate", false)),
			"directorKind": director_kind,
			"ownerNpc": NPC_CATALOG.owner_for(world_level, director_kind),
		}
		if director_kind == "practice" and world_level >= 2:
			# Solo deviazioni opzionali: nessuno strumento può bloccare il gate.
			payload["requiredTool"] = (
				"tool-torch" if posmod(hash(event_id), 2) == 0 else "tool-scythe"
			)
		area.set_meta("payload", payload)
		var shape := CollisionShape2D.new()
		shape.name = "EventCollision"
		var circle := CircleShape2D.new()
		circle.radius = INTERACTION_DISTANCE
		shape.shape = circle
		shape.disabled = completed
		area.add_child(shape)
		if director_kind == "enigma":
			var visual := ENIGMA_STRUCTURE.new()
			visual.name = "EnigmaStructureVisual"
			# La struttura antepone già "ENIGMA": il titolo deve contenere solo
			# la materia, altrimenti appare "ENIGMA · ENIGMA DI …".
			visual.setup(
				"ponte" if event.has("bridgeCenter") else ContentManager.enigma_theme(str(payload["subject"])),
				str(payload["subject"]).capitalize())
			if event.has("bridgeCenter"):
				var bridge_center: Vector2 = event.get("bridgeCenter", area.position)
				var bridge_normal: Vector2 = event.get("bridgeNormal", Vector2.RIGHT)
				visual.position = bridge_center - area.position
				visual.rotation = bridge_normal.angle()
				var water_gate_sign := _make_water_gate_sign(completed)
				water_gate_sign.name = "WaterGateObjective"
				area.add_child(water_gate_sign)
			visual.set_stage(4 if completed else 0, 4)
			area.add_child(visual)
		elif director_kind == "practice":
			area.add_child(_make_minigame_marker())
			var equipment_gate := EQUIPMENT_GATE_SCRIPT.new()
			equipment_gate.name = "EquipmentGate"
			area.add_child(equipment_gate)
			equipment_gate.configure(str(payload.get("requiredTool", "")), equipped_field_tool())
		elif not completed:
			var marker := OutdoorVisualFactory.build_encounter(
				_event_visual_kind(str(payload["subject"])),
				clampi(floori(float(world_level) / 4.0) + 1, 1, 7))
			marker.name = "EventMarker"
			area.add_child(marker)
		var reaction := LEARNING_REACTION_SCRIPT.new()
		reaction.setup(
			_learning_reaction_theme(),
			director_kind,
			OutdoorVisualFactory.hex_color(_profile_accent_rgb()),
			environment_transform)
		reaction.position = Vector2(0, 28)
		reaction.set_complete(completed)
		area.add_child(reaction)
		# EnigmaStructureVisual possiede già un titolo contestuale leggibile:
		# aggiungerne un secondo produceva etichette sovrapposte su tablet.
		# Una missione già conclusa conserva la trasformazione ambientale, ma non
		# la sfera/caption che la facevano sembrare ancora disponibile.
		if director_kind != "enigma" and not completed:
			var caption := _make_event_caption(director_kind, str(payload["subject"]))
			caption.name = "EventCaption"
			area.add_child(caption)
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

func _create_world_buildings() -> void:
	var specs := BUILDING_CATALOG.for_world(world_level, world_profile)
	var occupied: Array = []
	for index in specs.size():
		var spec: Dictionary = specs[index]
		var actor: Node2D = BUILDING_ACTOR_SCRIPT.new()
		actor.call("configure", spec, _npc_story_stage(), high_contrast, reduced_motion)
		actor.position = _building_position(str(spec.get("role", "")), index, occupied)
		occupied.append(actor.position)
		world_layer.add_child(actor)
		world_buildings.append(actor)

func _create_mystery_artifacts() -> void:
	var ruin: Node2D = null
	for building in world_buildings:
		if is_instance_valid(building) and str(building.get_meta("building_role", "")) == "first_ruin":
			ruin = building
			break
	if ruin == null:
		return
	var trace: Dictionary = MYSTERY_CATALOG.traccia_for(world_level)
	var occupied: Array = []
	var seed_count := 0
	for raw_seed in MYSTERY_CATALOG.SEMI:
		if int((raw_seed as Dictionary).get("world", 0)) == world_level:
			seed_count += 1
	if not trace.is_empty():
		var trace_area: Area2D = MYSTERY_ARTIFACT_SCRIPT.new()
		trace_area.configure("trace", "trace-%02d" % world_level, trace, high_contrast)
		trace_area.position = _mystery_artifact_position(ruin.global_position, 0, seed_count + 1, occupied)
		occupied.append(trace_area.position)
		world_layer.add_child(trace_area)
		_bind_mystery_artifact(trace_area)
	var seeds: Array = []
	for raw_seed in MYSTERY_CATALOG.SEMI:
		var seed_data: Dictionary = raw_seed
		if int(seed_data.get("world", 0)) == world_level:
			seeds.append(seed_data.duplicate(true))
	for index in seeds.size():
		var seed_data: Dictionary = seeds[index]
		var seed_area: Area2D = MYSTERY_ARTIFACT_SCRIPT.new()
		seed_area.configure("seed", "seed-%02d-%d" % [world_level, index], seed_data, high_contrast)
		seed_area.position = _mystery_artifact_position(
			ruin.global_position, index + 1, seeds.size() + 1, occupied)
		occupied.append(seed_area.position)
		world_layer.add_child(seed_area)
		_bind_mystery_artifact(seed_area)

func _mystery_artifact_position(base: Vector2, index: int, total: int, occupied: Array) -> Vector2:
	var phase := float(posmod(hash("%s:%d:mystery" % [world_seed, world_level]), 6283)) / 1000.0
	for attempt in 48:
		var ring := attempt / 12
		var angle := phase + TAU * float(index) / maxf(float(total), 1.0) + TAU * float(attempt % 12) / 12.0
		# I landmark più grandi (Cuore del Labirinto, sigilli, cupole) coprono la
		# prima corona da 180 px: la Traccia risultava presente ma nascosta sotto
		# l'illustrazione. Quattro corone entro 510 px la tengono fuori dalla
		# sagoma e comunque nella stessa schermata di esplorazione.
		var radius := 360.0 + float(ring) * 50.0
		var candidate := chunks.clamp_to_world(base + Vector2.RIGHT.rotated(angle) * radius)
		if absf(candidate.y - base.y) > 300.0:
			continue
		if chunks.composition != null:
			if chunks.composition.is_protected(candidate, 40.0):
				continue
			if chunks.composition.raw_water_weight(candidate) >= 0.24:
				continue
		var overlaps := false
		for used in occupied:
			if candidate.distance_to(used as Vector2) < 112.0:
				overlaps = true
				break
		if not overlaps:
			return candidate
	# Fallback di sola sicurezza: la Rovina resta leggibile anche se un profilo
	# futuro esaurisce tutti i candidati; l'audit L1 impedisce che accada oggi.
	return chunks.clamp_to_world(base + Vector2(420, 0).rotated(phase + index))

func _bind_mystery_artifact(area: Area2D) -> void:
	area.body_entered.connect(func(body): on_interactable_entered(area, body))
	area.body_exited.connect(func(body): on_interactable_exited(area, body))

func _mystery_seen_list(key: String) -> Array:
	var narrative: Dictionary = game_save.data.get("narrative", {})
	return Array(narrative.get(key, [])).duplicate()

func _mark_mystery_seen(key: String, id: String) -> void:
	var narrative: Dictionary = game_save.data.get("narrative", {})
	var seen: Array = Array(narrative.get(key, [])).duplicate()
	if not seen.has(id):
		seen.append(id)
		narrative[key] = seen
		game_save.data["narrative"] = narrative
		if bool(request.get("loadLocalSave", true)):
			game_save.save()

func _open_mystery_artifact(target: Area2D) -> void:
	var kind := str(target.get_meta("kind", ""))
	var id := str(target.get_meta("id", ""))
	var payload: Dictionary = target.get_meta("payload", {})
	var pages: Array = []
	var speaker := "Indizio"
	var role := "Seme del mistero"
	if kind == "mystery_trace":
		pages = Array(payload.get("testo", [])).duplicate()
		speaker = str(payload.get("oggetto", "Traccia dei Primi"))
		role = "Rovina dei Primi · Traccia %d" % world_level
		_mark_mystery_seen("tracesSeen", str(world_level))
	else:
		pages = [str(payload.get("cosa", ""))]
		speaker = str(payload.get("dove", "dettaglio")).capitalize()
		role = "Seme · %s" % str(payload.get("colpo", "mistero")).replace("-", " ")
		_mark_mystery_seen("seedsSeen", id)
	if pages.is_empty() or str(pages[0]).strip_edges() == "":
		return
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", id, speaker, role, pages)
	_refresh_interaction_button(null)

func _show_decisive_fallback_if_needed() -> bool:
	if not MYSTERY_CATALOG.tracce_decisive().has(world_level):
		return false
	if _mystery_seen_list("tracesSeen").has(str(world_level)):
		return false
	if _mystery_seen_list("fallbacksSeen").has(str(world_level)):
		return false
	var trace := MYSTERY_CATALOG.traccia_for(world_level)
	var fallback := str(trace.get("ripiego", "")).strip_edges()
	if fallback == "":
		return false
	_mark_mystery_seen("fallbacksSeen", str(world_level))
	if fallback.begins_with("NORA:"):
		fallback = fallback.trim_prefix("NORA:").strip_edges()
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", "mystery-fallback-%d" % world_level, "NORA", "Beat di ripiego", [fallback])
	return true

func _building_position(role: String, index: int, occupied: Array) -> Vector2:
	if role == "first_ruin":
		return _hero_landmark_position()
	var spawn: Vector2 = world_profile.get("spawn", Vector2(0, 1180))
	var base := spawn + (Vector2(-650, 260) if role == "work_home" else Vector2(650, 260))
	for attempt in 24:
		var radius := 0.0 if attempt == 0 else 90.0 + 34.0 * floori(float(attempt) / 6.0)
		var candidate := chunks.clamp_to_world(
			base + Vector2.RIGHT.rotated(TAU * float(attempt) / 6.0) * radius)
		if chunks.composition != null:
			if chunks.composition.is_protected(candidate, 96.0):
				continue
			if chunks.composition.raw_water_weight(candidate) >= 0.24:
				continue
		var blocked := false
		for event in mission_events:
			if candidate.distance_to(event.get("position", Vector2.ZERO)) < 190.0:
				blocked = true
				break
		for used in occupied:
			if candidate.distance_to(used as Vector2) < 260.0:
				blocked = true
				break
		if not blocked:
			return candidate
	return chunks.clamp_to_world(base + Vector2(0, 180.0 * float(index + 1)))

func _update_building_stages() -> void:
	var current_stage := _npc_story_stage()
	for building in world_buildings:
		if is_instance_valid(building):
			building.call("set_stage", current_stage)

func ritrovo_position() -> Vector2:
	for building in world_buildings:
		if is_instance_valid(building) and str(building.get_meta("building_role", "")) == "ritrovo":
			return building.global_position
	return world_profile.get("spawn", Vector2.ZERO)

func _create_world_npcs() -> void:
	if world_level == WorldProfileCatalog.MAX_LEVEL:
		_create_finale_convergence_cast()
		return
	var cast := NPC_CATALOG.for_world(world_level)
	var ids: Array = Array(cast.get("residents", [])).duplicate()
	ids.append_array(Array(cast.get("bislacchi", [])))
	if ids.is_empty():
		return
	# Il budget globale vieta più di quattro presenze simultanee. La fixture del
	# mondo 1 ne usa tre; i mondi futuri passeranno dallo stesso limite.
	ids.resize(mini(ids.size(), 4))
	var occupied: Array = []
	for index in ids.size():
		var npc_id := str(ids[index])
		var data := NPC_CATALOG.resident(npc_id)
		if data.is_empty():
			data = NPC_CATALOG.bislacco(npc_id)
		if data.is_empty():
			continue
		var actor: Area2D = NPC_ACTOR_SCRIPT.new()
		actor.call("configure", npc_id, data, reduced_motion)
		actor.call("set_high_contrast", high_contrast)
		actor.position = _npc_spawn_position(index, occupied)
		occupied.append(actor.position)
		world_layer.add_child(actor)
		actor.body_entered.connect(func(body): on_interactable_entered(actor, body))
		actor.body_exited.connect(func(body): on_interactable_exited(actor, body))
		npc_actors.append(actor)
	# Un solo volto ricorrente per mondo. Residenti (2) + Bislacco (1) +
	# itinerante (1) rispettano il budget assoluto di quattro presenze.
	if npc_actors.size() < 4:
		var itinerant_id := ITINERANT_CATALOG.itinerant_for(hash(world_seed), world_level)
		var itinerant_data := ITINERANT_CATALOG.itinerant(itinerant_id)
		if not itinerant_data.is_empty():
			var actor_data := itinerant_data.duplicate(true)
			actor_data["ruolo"] = str(itinerant_data.get("funzione", "itinerante")).capitalize()
			var itinerant: Area2D = NPC_ACTOR_SCRIPT.new()
			itinerant.call("configure", itinerant_id, actor_data, reduced_motion)
			itinerant.call("set_high_contrast", high_contrast)
			itinerant.position = _npc_spawn_position(npc_actors.size(), occupied)
			occupied.append(itinerant.position)
			world_layer.add_child(itinerant)
			itinerant.body_entered.connect(func(body): on_interactable_entered(itinerant, body))
			itinerant.body_exited.connect(func(body): on_interactable_exited(itinerant, body))
			npc_actors.append(itinerant)

func _finale_stage2_residents() -> Array:
	var out: Array = []
	if not is_instance_valid(gameplay):
		return out
	for completed_world in gameplay.stage2_worlds():
		var world_cast := NPC_CATALOG.for_world(int(completed_world))
		for npc_id in Array(world_cast.get("residents", [])):
			if FINALE_CATALOG.RESIDENTI.has(str(npc_id)):
				out.append(str(npc_id))
	return out

func _create_finale_convergence_cast() -> void:
	var ids := FINALE_CATALOG.cast_for(_finale_stage2_residents(), finale_convergence_wave)
	finale_wave_heard.clear()
	var occupied: Array = []
	for index in ids.size():
		var npc_id := str(ids[index])
		var data := NPC_CATALOG.resident(npc_id)
		if data.is_empty():
			data = ITINERANT_CATALOG.itinerant(npc_id)
			if not data.is_empty():
				data["ruolo"] = str(data.get("funzione", "itinerante")).capitalize()
		if data.is_empty():
			continue
		var actor: Area2D = NPC_ACTOR_SCRIPT.new()
		actor.call("configure", npc_id, data, reduced_motion)
		actor.call("set_high_contrast", high_contrast)
		actor.set_meta("finale_convergence", true)
		actor.position = _npc_spawn_position(index, occupied)
		occupied.append(actor.position)
		world_layer.add_child(actor)
		actor.body_entered.connect(func(body): on_interactable_entered(actor, body))
		actor.body_exited.connect(func(body): on_interactable_exited(actor, body))
		npc_actors.append(actor)

func _advance_finale_convergence_wave() -> void:
	var current_ids: Array[String] = []
	for actor in npc_actors:
		if is_instance_valid(actor) and bool(actor.get_meta("finale_convergence", false)):
			current_ids.append(str(actor.get_meta("id", "")))
	for npc_id in current_ids:
		if not finale_wave_heard.has(npc_id):
			return
	var total_waves := FINALE_CATALOG.waves_needed(_finale_stage2_residents())
	if finale_convergence_wave + 1 >= total_waves:
		return
	finale_convergence_wave += 1
	for actor in npc_actors.duplicate():
		if is_instance_valid(actor) and bool(actor.get_meta("finale_convergence", false)):
			nearby.erase(actor)
			npc_actors.erase(actor)
			actor.queue_free()
	_create_finale_convergence_cast()
	_refresh_prompt()

func _npc_spawn_position(index: int, occupied: Array) -> Vector2:
	var spawn: Vector2 = world_profile.get("spawn", Vector2(0, 1180))
	var anchors := [Vector2(-430, -250), Vector2(430, -220), Vector2(390, 170), Vector2(-420, 180)]
	var base: Vector2 = spawn + anchors[index % anchors.size()]
	for attempt in 16:
		var angle := TAU * float(attempt) / 16.0
		var radius := 0.0 if attempt == 0 else 72.0 + 26.0 * floori(float(attempt) / 4.0)
		var candidate := chunks.clamp_to_world(base + Vector2.RIGHT.rotated(angle) * radius)
		if chunks.composition != null:
			if chunks.composition.is_protected(candidate, 72.0) or chunks.composition.raw_water_weight(candidate) >= 0.28:
				continue
		var blocked := candidate.distance_to(_hero_landmark_position()) < 150.0
		for event in mission_events:
			if candidate.distance_to(event.get("position", Vector2.ZERO)) < 150.0:
				blocked = true
				break
		for used in occupied:
			if candidate.distance_to(used as Vector2) < 150.0:
				blocked = true
				break
		if not blocked:
			for artifact in get_tree().get_nodes_in_group("mystery_artifact"):
				if artifact is Node2D and is_ancestor_of(artifact) \
					and candidate.distance_to((artifact as Node2D).global_position) < 170.0:
					blocked = true
					break
		if not blocked:
			return candidate
	return chunks.clamp_to_world(base)

func _create_world_life() -> void:
	if npc_actors.is_empty() or world_level == WorldProfileCatalog.MAX_LEVEL:
		return
	var anchor_map: Dictionary = {}
	var work_center := _building_role_position("work_home")
	var social_center := ritrovo_position()
	var work_offsets := [Vector2(-115, 72), Vector2(115, 72), Vector2(-175, 145), Vector2(175, 145)]
	var social_offsets := [Vector2(-108, 92), Vector2(108, 92), Vector2(0, 164), Vector2(190, 40)]
	for index in npc_actors.size():
		var actor := npc_actors[index]
		var npc_id := str(actor.get_meta("id", ""))
		anchor_map[npc_id] = {
			"home": actor.global_position,
			"work": _safe_world_life_anchor(work_center + work_offsets[index % work_offsets.size()], index),
			"ritrovo": _safe_world_life_anchor(social_center + social_offsets[index % social_offsets.size()], index + 7),
		}
	world_life = WORLD_LIFE_SCRIPT.new()
	world_life.configure(world_level, npc_actors, anchor_map, _npc_story_stage(), reduced_motion)

func _building_role_position(role: String) -> Vector2:
	for building in world_buildings:
		if is_instance_valid(building) and str(building.get_meta("building_role", "")) == role:
			return building.global_position
	return world_profile.get("spawn", Vector2.ZERO)

func _safe_world_life_anchor(base: Vector2, salt: int) -> Vector2:
	for attempt in 24:
		var radius := 0.0 if attempt == 0 else 42.0 + 28.0 * floori(float(attempt) / 8.0)
		var angle := TAU * float((attempt + salt * 3) % 8) / 8.0
		var candidate := chunks.clamp_to_world(base + Vector2.RIGHT.rotated(angle) * radius)
		if chunks.composition != null:
			if chunks.composition.is_protected(candidate, 52.0):
				continue
			if chunks.composition.raw_water_weight(candidate) >= 0.24:
				continue
		var blocks_gate := false
		for event in mission_events:
			if candidate.distance_to(event.get("position", Vector2.ZERO)) < 112.0:
				blocks_gate = true
				break
		if not blocks_gate:
			return candidate
	return chunks.clamp_to_world(base)

func _update_npc_streaming() -> void:
	if not is_instance_valid(player):
		return
	var stream_distance := float((chunks.active_radius + 1) * OutdoorChunkManager.CHUNK_SIZE)
	for actor in npc_actors:
		if is_instance_valid(actor):
			actor.call("set_stream_active", player.global_position.distance_to(actor.global_position) <= stream_distance)

func _create_dialogue_box() -> void:
	dialogue_box = DIALOGUE_BOX_SCRIPT.new()
	dialogue_box.name = "DialogueBox"
	ui_layer.add_child(dialogue_box)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.connect("dialogue_closed", _on_dialogue_closed)

func _create_thirteenth_presence() -> void:
	thirteenth_director = THIRTEENTH_DIRECTOR_SCRIPT.new()
	var narrative: Dictionary = game_save.data.get("narrative", {})
	var persistent: Dictionary = narrative.get("thirteenth", {})
	thirteenth_director.setup(
		world_level,
		world_seed,
		Array(persistent.get("forgottenResidents", [])),
		_active_mission_owner())
	if not thirteenth_director.is_present():
		return
	var action_id: String = thirteenth_director.ambient_action()
	var action: Dictionary = thirteenth_director.action_data(action_id)
	match action_id:
		"scrive":
			for building in world_buildings:
				if not is_instance_valid(building):
					continue
				var sign := Label.new()
				sign.name = "ThirteenthWord"
				sign.text = str(action.get("parola", ""))
				sign.position = Vector2(-90, -112)
				sign.size = Vector2(180, 34)
				sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sign.add_theme_font_size_override("font_size", 22)
				sign.add_theme_color_override("font_color", Color.WHITE)
				sign.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.96))
				sign.add_theme_constant_override("shadow_offset_x", 3)
				sign.add_theme_constant_override("shadow_offset_y", 3)
				sign.accessibility_name = sign.text
				building.add_child(sign)
		"risbiadisce":
			if not world_buildings.is_empty():
				var index := posmod(hash("%s:%d:risbiadisce" % [world_seed, world_level]), world_buildings.size())
				var faded = world_buildings[index]
				if is_instance_valid(faded):
					faded.modulate = Color(0.58, 0.61, 0.64, 1.0)
		"smemora":
			var cast: Dictionary = NPC_CATALOG.for_world(world_level)
			thirteenth_director.active_owner = _active_mission_owner()
			thirteenth_forgotten_npc = thirteenth_director.choose_forgotten_resident(
				Array(cast.get("residents", [])))
			if thirteenth_forgotten_npc != "":
				persistent["forgottenResidents"] = thirteenth_director.forgotten_residents.duplicate()
				narrative["thirteenth"] = persistent
				game_save.data["narrative"] = narrative
				if bool(request.get("loadLocalSave", true)):
					game_save.save()
		"chiude":
			# Il mondo aperto offre un solo portale: nessuna falsa chiusura. La
			# regia la autorizzera' nelle sale nave solo con una seconda rotta.
			thirteenth_director.choose_closed_route([], str(runtime.get("apparatus", "")))
	if not action.is_empty() and action_id != "chiude":
		_present_feedback(str(action.get("manifestazione", "")), "thirteenth")
	var voice: Dictionary = thirteenth_director.next_voice()
	if not voice.is_empty():
		var pages := PackedStringArray(Array(voice.get("dice", [])))
		get_tree().create_timer(5.0).timeout.connect(func():
			if is_inside_tree() and not _blocking_panel_visible():
				_present_feedback("\n".join(pages), "thirteenth")
		)

func _active_mission_owner() -> String:
	if mission_ownership_flow == null:
		return ""
	var route: Dictionary = mission_ownership_flow.navigation()
	var phase := str(route.get("phase", ""))
	if phase == "mission":
		return mission_ownership_flow.owner_of(str(route.get("id", "")))
	if phase == "return":
		return str(route.get("id", ""))
	return ""

func _open_npc_dialogue(npc_id: String) -> void:
	_pet_greet(npc_id)
	if world_level == WorldProfileCatalog.MAX_LEVEL and not FINALE_CATALOG.lines_for(npc_id).is_empty():
		_open_finale_convergence_dialogue(npc_id)
		return
	if npc_id == thirteenth_forgotten_npc:
		var owner_now := _active_mission_owner()
		if owner_now == npc_id:
			# La missione ha avuto la precedenza dopo l'ingresso nel mondo: la
			# scena di memoria si annulla invece di colpire il suo proprietario.
			thirteenth_forgotten_npc = ""
		else:
			var manifestation := ThirteenthCatalog.action("smemora")
			_present_feedback(str(manifestation.get("manifestazione", "")), "thirteenth")
			thirteenth_forgotten_npc = ""
	var data := NPC_CATALOG.resident(npc_id)
	var lines: Array = []
	var mission_pool := ""
	var pending_return: Dictionary = {}
	if not data.is_empty():
		var narrative: Dictionary = game_save.data.get("narrative", {})
		if npc_id == "w01-ersilia" and not bool(narrative.get("ersiliaCountHeard", false)):
			lines = [_ersilia_count_pages()]
			mission_pool = "conta"
			ersilia_count_pending = true
		elif mission_ownership_flow != null:
			pending_return = mission_ownership_flow.pending_return_for(npc_id)
			if not pending_return.is_empty():
				mission_pool = "reazione" if bool(pending_return.get("passed", false)) else "consolazione"
				lines = NPC_CATALOG.mission_lines(npc_id, mission_pool)
			else:
				var assignment: Dictionary = mission_ownership_flow.accept_request(npc_id)
				if not assignment.is_empty():
					mission_pool = "richiesta"
					lines = NPC_CATALOG.mission_lines(npc_id, mission_pool)
		if lines.is_empty():
			var stage := _npc_story_stage()
			var pools := data.get("battute", {}) as Dictionary
			lines = Array(pools.get("stadio%d" % stage, pools.get("riempimento", [])))
	else:
		data = NPC_CATALOG.bislacco(npc_id)
		lines = Array(data.get("battute", []))
		if data.is_empty():
			data = ITINERANT_CATALOG.itinerant(npc_id)
			if not data.is_empty():
				data["ruolo"] = str(data.get("funzione", "itinerante")).capitalize()
				var pools: Dictionary = data.get("battute", {})
				for pool_name in ["saluto", str(data.get("funzione", "")), "riempimento", "congedo"]:
					if pool_name != "":
						lines.append_array(Array(pools.get(pool_name, [])))
				if npc_id == "itin-vera" and not vera_teaching_used:
					vera_topic_key = _vera_applied_topic()
					if vera_topic_key != "":
						var teaching_lines := ITINERANT_CATALOG.lines_of(npc_id, "rispiegamelo")
						if not teaching_lines.is_empty():
							lines = teaching_lines
							mission_pool = "rispiegamelo"
							vera_teaching_pending = true
	if data.is_empty() or lines.is_empty():
		return
	var cursor_key := "%s:%s" % [npc_id, mission_pool if mission_pool != "" else "ordinary"]
	var cursor := int(npc_dialogue_cursors.get(cursor_key, 0))
	var pages: Array = (lines[cursor % lines.size()] as Array).duplicate()
	npc_dialogue_cursors[cursor_key] = cursor + 1
	if not pending_return.is_empty():
		mission_ownership_flow.consume_return(npc_id)
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", npc_id, str(data.get("nome", npc_id)), str(data.get("ruolo", "abitante")), pages)
	_update_ship_navigation()
	_refresh_interaction_button(null)

func _open_finale_convergence_dialogue(npc_id: String) -> void:
	var data := NPC_CATALOG.resident(npc_id)
	if data.is_empty():
		data = ITINERANT_CATALOG.itinerant(npc_id)
		if not data.is_empty():
			data["ruolo"] = str(data.get("funzione", "itinerante")).capitalize()
	var pages := FINALE_CATALOG.lines_for(npc_id)
	if data.is_empty() or pages.is_empty():
		return
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", npc_id, str(data.get("nome", npc_id)), str(data.get("ruolo", "equipaggio")), pages)
	_update_ship_navigation()
	_refresh_interaction_button(null)

func _ersilia_count_pages() -> Array:
	var verses: Array = Array(NPC_CATALOG.CONTA_ERSILIA.get("versi", []))
	if verses.is_empty():
		return []
	return [
		"\n".join(verses.slice(0, 4)),
		"\n".join(verses.slice(4, 7)),
		"\n".join(verses.slice(7)),
	]

func _npc_story_stage() -> int:
	var completed := Array(result.get("completedEncounterIds", [])).size()
	if completed >= 3:
		return 2
	if completed >= 1:
		return 1
	return 0

func _on_dialogue_closed(npc_id: String) -> void:
	if is_instance_valid(player):
		player.set_physics_process(true)
	if npc_id == "w01-ersilia" and ersilia_count_pending:
		ersilia_count_pending = false
		var narrative: Dictionary = game_save.data.get("narrative", {})
		narrative["ersiliaCountHeard"] = true
		game_save.data["narrative"] = narrative
		if bool(request.get("loadLocalSave", true)):
			game_save.save()
	if vera_teaching_pending:
		vera_teaching_pending = false
		_open_vera_teaching_choice()
		return
	if world_level == WorldProfileCatalog.MAX_LEVEL and not FINALE_CATALOG.lines_for(npc_id).is_empty():
		if not finale_wave_heard.has(npc_id):
			finale_wave_heard.append(npc_id)
		_advance_finale_convergence_wave()
	_update_ship_navigation()
	_refresh_prompt()

func _vera_applied_topic() -> String:
	var codex: Dictionary = game_save.data.get("codex", {})
	var narrative: Dictionary = game_save.data.get("narrative", {})
	var explained: Dictionary = narrative.get("veraExplainedOn", {})
	var today := Time.get_date_string_from_system()
	var eligible: Array = []
	for key in codex.keys():
		if str(codex[key]) in ["applied", "consolidated"] and str(explained.get(key, "")) != today:
			eligible.append(str(key))
	eligible.sort()
	return str(eligible[0]) if not eligible.is_empty() else ""

func _open_vera_teaching_choice() -> void:
	if vera_topic_key == "":
		return
	if not is_instance_valid(teaching_choice_panel):
		teaching_choice_panel = TEACHING_CHOICE_PANEL_SCRIPT.new()
		teaching_choice_panel.name = "TeachingChoicePanel"
		ui_layer.add_child(teaching_choice_panel)
		teaching_choice_panel.connect("choice_made", _on_vera_teaching_choice)
	if is_instance_valid(player):
		player.set_physics_process(false)
	var topic := vera_topic_key.get_slice(":", 1) if vera_topic_key.contains(":") else vera_topic_key
	teaching_choice_panel.call("open", topic, TEACHING_CATALOG.rispiegamelo_options())

func _on_vera_teaching_choice(_option_id: String, correct: bool) -> void:
	vera_teaching_used = true
	var pool := "capito" if correct else "non_capito"
	var responses := ITINERANT_CATALOG.lines_of("itin-vera", pool)
	var pages: Array = []
	if not responses.is_empty():
		var index := posmod(hash("%s:%s" % [world_seed, vera_topic_key]), responses.size())
		pages = Array(responses[index]).duplicate()
	if correct:
		_record_vera_retention()
	if pages.is_empty():
		if is_instance_valid(player):
			player.set_physics_process(true)
		return
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", "itin-vera-result", "Vera", "Consolidamento · zero energia", pages)

func _record_vera_retention() -> void:
	var narrative: Dictionary = game_save.data.get("narrative", {})
	var explained: Dictionary = narrative.get("veraExplainedOn", {})
	explained[vera_topic_key] = Time.get_date_string_from_system()
	narrative["veraExplainedOn"] = explained
	game_save.data["narrative"] = narrative
	var repetition: Dictionary = game_save.data.get("spacedRepetition", {})
	var history: Array = Array(repetition.get("history", [])).duplicate()
	history.append({
		"type": "vera-explanation",
		"topicKey": vera_topic_key,
		"sessionClock": int(repetition.get("sessionClock", 0)),
	})
	if history.size() > 200:
		history = history.slice(history.size() - 200)
	repetition["history"] = history
	game_save.data["spacedRepetition"] = repetition
	if bool(request.get("loadLocalSave", true)):
		game_save.save()

func _create_world_enemies() -> void:
	if mission_events.is_empty() or chunks == null or chunks.composition == null:
		return
	var count := clampi(1 + floori(float(world_level - 1) / 6.0), 1, 4)
	var subject := _world_subject()
	for index in range(count):
		var event: Dictionary = mission_events[(index * 2 + 1) % mission_events.size()]
		var base: Vector2 = event.get("position", world_profile.get("spawn", Vector2.ZERO))
		var angle := float(posmod(hash("%s:enemy:%d" % [world_seed, index]), 6283)) / 1000.0
		var enemy_position := base + Vector2.RIGHT.rotated(angle) * (170.0 + index * 24.0)
		for attempt in range(8):
			if (
				not chunks.composition.is_protected(enemy_position, 58.0)
				and chunks.composition.raw_water_weight(enemy_position) < 0.35
			):
				break
			angle += PI * 0.5
			enemy_position = base + Vector2.RIGHT.rotated(angle) * (170.0 + index * 24.0)
		enemy_position = chunks.clamp_to_world(enemy_position)
		var enemy := WORLD_ENEMY_SCRIPT.new()
		enemy.name = "WorldEnemy_%02d" % index
		var accent := chunks.composition.blended_accent(enemy_position)
		enemy.setup(self, enemy_position, world_level, subject, accent, index)
		enemy.reduced_motion = reduced_motion
		world_layer.add_child(enemy)

## Il Custode si irrigidisce vicino a uno Sbiadito, prima ancora del contatto
## che respinge Eli. Vedi docs/CUSTODE_LIVELLO_AVANZATO.md §Asse B.
func _pet_check_faded_proximity() -> void:
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		return
	if not enemy_gameplay_active():
		return
	for enemy in get_tree().get_nodes_in_group("world_enemy"):
		if enemy is Node2D and player.global_position.distance_to((enemy as Node2D).global_position) <= PET_FADED_SENSE_RADIUS:
			_pet_react("near_faded")
			return

func enemy_gameplay_active() -> bool:
	return (
		is_instance_valid(player)
		and player.is_physics_processing()
		and not (is_instance_valid(exercise_player) and exercise_player.visible)
		and not (is_instance_valid(shop_panel) and shop_panel.visible)
		and not (is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible)
	)

func _on_enemy_contact(enemy: Node2D, body: Node) -> void:
	if body != player or not enemy_gameplay_active():
		return
	var away := enemy.global_position.direction_to(player.global_position)
	if away.length_squared() < 0.01:
		away = Vector2.DOWN
	var target := chunks.clamp_to_world(player.global_position + away * 104.0)
	if _water_blocks_position(target):
		target = last_traversable_position
	player.global_position = target
	player.velocity = Vector2.ZERO
	player.touch_target = Vector2.INF
	last_traversable_position = target
	_set_feedback("%s blocca il percorso · usa IMPULSO per stabilizzarlo." % str(enemy.get("enemy_name")))
	if is_instance_valid(player_presentation):
		if reduced_motion:
			player_presentation.modulate = Color.WHITE
			return
		var tween := create_tween()
		tween.tween_property(player_presentation, "modulate", Color(1.0, 0.46, 0.42), 0.08)
		tween.tween_property(player_presentation, "modulate", Color.WHITE, 0.22)

func _combat_pulse() -> void:
	if not enemy_gameplay_active():
		return
	var now := Time.get_ticks_msec()
	if now < pulse_ready_msec:
		return
	pulse_ready_msec = now + 1250
	player.play_pulse_action()
	_spawn_combat_pulse_visual()
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("world_enemy"):
		if enemy is Node2D and player.global_position.distance_to(enemy.global_position) <= 168.0:
			enemy.call("stun", 5.5)
			hits += 1
	_set_feedback(
		"Impulso stabilizzante · varco libero per alcuni secondi."
		if hits > 0
		else "Impulso emesso · nessuna anomalia nel raggio."
	)
	_update_pulse_button()

func _spawn_combat_pulse_visual() -> void:
	var pulse := Node2D.new()
	pulse.name = "EliCombatPulse"
	pulse.position = player.global_position
	pulse.z_index = 80
	var ring := OutdoorVisualFactory.make_ring(24.0, Color("6be7d6"), 5.0, 36)
	pulse.add_child(ring)
	world_layer.add_child(pulse)
	if reduced_motion:
		pulse.scale = Vector2.ONE * 1.35
		pulse.modulate.a = 0.72
		await get_tree().create_timer(0.12).timeout
		pulse.queue_free()
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector2.ONE * 6.8, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.34)
	tween.set_parallel(false)
	tween.tween_callback(pulse.queue_free)

func _update_pulse_button() -> void:
	if not is_instance_valid(pulse_button):
		return
	var remaining := maxi(0, pulse_ready_msec - Time.get_ticks_msec())
	pulse_button.disabled = remaining > 0 or not enemy_gameplay_active()
	pulse_button.text = "IMPULSO\n%.1f s" % (float(remaining) / 1000.0) if remaining > 0 else "IMPULSO\nTOCCA"

func _event_visual_kind(subject: String) -> String:
	if subject in ["matematica", "fisica"]:
		return "times"
	if subject in ["geografia", "inglese"]:
		return "capital"
	if subject in ["coding", "elettronica", "logica"]:
		return "guardian"
	if subject in ["scienze", "storia"]:
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

func _make_landmark_caption(label_text: String, completed: int, total: int) -> Label:
	var label := Label.new()
	label.name = "LandmarkPurpose"
	label.position = Vector2(-132, -146)
	label.custom_minimum_size = Vector2(264, 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "%s\nPROGRESSO %d/%d" % [label_text.to_upper(), completed, total]
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_color", Color("f6c85f"))
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.035, 0.04, 0.94))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_water_gate_sign(completed: bool) -> Label:
	var label := Label.new()
	label.position = Vector2(-150, -142)
	label.custom_minimum_size = Vector2(300, 58)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = (
		"PASSAGGIO APERTO · PONTE COSTRUITO"
		if completed
		else "PASSAGGIO BLOCCATO\nRISOLVI L'ENIGMA PER COSTRUIRE IL PONTE"
	)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("outline_size", 7)
	label.add_theme_color_override("font_color", Color("6be7d6") if completed else Color("f6c85f"))
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.025, 0.035, 0.96))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _profile_accent_rgb() -> int:
	var colors := {
		"matematica": 0x6be7d6, "italiano": 0xe9a86d, "coding": 0x8fa7ff,
		"inglese": 0x72c9ff, "fisica": 0xa2d8ff, "musica": 0xd7a0ff,
		"latino": 0xd4b17a, "elettronica": 0x79e7ff, "geografia": 0x7fd19b,
		"scienze": 0x91dc72, "storia": 0xf2c96d, "logica": 0xb7a2ff,
	}
	return int(colors.get(_world_subject(), 0x6be7d6))

func _create_profile_weather() -> void:
	var weather := str(world_profile.get("weather", "sereno")).to_lower()
	if world_level not in [3, 4, 13] and weather in ["sereno", "quiete", "controllato", "sereno-secco"]:
		return
	world_weather_particles = CPUParticles2D.new()
	world_weather_particles.name = "WorldProfileWeather"
	world_weather_particles.emitting = not reduced_motion
	world_weather_particles.position = world_profile.get("spawn", PORTAL_POSITION)
	world_weather_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	world_weather_particles.emission_rect_extents = Vector2(680, 430)
	world_weather_particles.local_coords = false
	world_weather_particles.lifetime = 2.8
	world_weather_particles.preprocess = 2.0
	world_weather_particles.scale_amount_min = 0.05
	world_weather_particles.scale_amount_max = 0.13
	world_weather_particles.z_index = 2 if world_level in [17, 20, 21, 22, 24] else 42
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
	elif world_level == 6:
		world_weather_particles.amount = 38
		world_weather_particles.direction = Vector2(0.72, -0.28)
		world_weather_particles.gravity = Vector2(12, -10)
		world_weather_particles.initial_velocity_min = 12.0
		world_weather_particles.initial_velocity_max = 34.0
		world_weather_particles.scale_amount_min = 0.08
		world_weather_particles.scale_amount_max = 0.18
		world_weather_particles.color = Color(0.78, 0.64, 1.0, 0.42)
	elif world_level == 9:
		world_weather_particles.amount = 38
		world_weather_particles.direction = Vector2(1.0, -0.16)
		world_weather_particles.gravity = Vector2(24, -5)
		world_weather_particles.initial_velocity_min = 24.0
		world_weather_particles.initial_velocity_max = 58.0
		world_weather_particles.color = Color(0.72, 0.94, 1.0, 0.26)
	elif world_level == 10:
		world_weather_particles.amount = 34
		world_weather_particles.direction = Vector2(0.34, -0.82)
		world_weather_particles.gravity = Vector2(8, -8)
		world_weather_particles.initial_velocity_min = 10.0
		world_weather_particles.initial_velocity_max = 30.0
		world_weather_particles.scale_amount_min = 0.07
		world_weather_particles.scale_amount_max = 0.16
		world_weather_particles.color = Color(0.78, 1.0, 0.70, 0.30)
	elif world_level == 13:
		world_weather_particles.amount = 46
		world_weather_particles.direction = Vector2(0.95, -0.20)
		world_weather_particles.gravity = Vector2(26, -5)
		world_weather_particles.initial_velocity_min = 24.0
		world_weather_particles.initial_velocity_max = 62.0
		world_weather_particles.scale_amount_min = 0.05
		world_weather_particles.scale_amount_max = 0.13
		world_weather_particles.color = Color(0.94, 0.70, 0.39, 0.30)
	elif world_level == 17:
		world_weather_particles.amount = 34
		world_weather_particles.direction = Vector2(0.34, -1.0)
		world_weather_particles.gravity = Vector2(8, -18)
		world_weather_particles.initial_velocity_min = 12.0
		world_weather_particles.initial_velocity_max = 36.0
		world_weather_particles.scale_amount_min = 0.05
		world_weather_particles.scale_amount_max = 0.12
		world_weather_particles.color = Color(0.48, 0.92, 1.0, 0.24)
	elif world_level == 20:
		world_weather_particles.amount = 64
		world_weather_particles.direction = Vector2(0.82, 0.56)
		world_weather_particles.gravity = Vector2(46, 72)
		world_weather_particles.initial_velocity_min = 52.0
		world_weather_particles.initial_velocity_max = 112.0
		world_weather_particles.scale_amount_min = 0.04
		world_weather_particles.scale_amount_max = 0.11
		world_weather_particles.color = Color(0.63, 0.76, 1.0, 0.30)
	elif world_level == 21:
		world_weather_particles.amount = 36
		world_weather_particles.direction = Vector2(0.88, -0.18)
		world_weather_particles.gravity = Vector2(24, -5)
		world_weather_particles.initial_velocity_min = 20.0
		world_weather_particles.initial_velocity_max = 54.0
		world_weather_particles.color = Color(0.82, 0.91, 0.88, 0.22)
	elif world_level == 22:
		world_weather_particles.amount = 38
		world_weather_particles.direction = Vector2(0.24, -0.92)
		world_weather_particles.gravity = Vector2(5, -10)
		world_weather_particles.initial_velocity_min = 10.0
		world_weather_particles.initial_velocity_max = 30.0
		world_weather_particles.scale_amount_min = 0.06
		world_weather_particles.scale_amount_max = 0.14
		world_weather_particles.color = Color(0.54, 1.0, 0.72, 0.24)
	elif world_level == 24:
		world_weather_particles.amount = 42
		world_weather_particles.direction = Vector2(0.0, -1.0)
		world_weather_particles.gravity = Vector2(0, -8)
		world_weather_particles.initial_velocity_min = 8.0
		world_weather_particles.initial_velocity_max = 24.0
		world_weather_particles.scale_amount_min = 0.05
		world_weather_particles.scale_amount_max = 0.13
		world_weather_particles.color = Color(1.0, 0.86, 0.52, 0.24)
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
	exercise_player.configure_accessibility(high_contrast, reduced_motion)
	exercise_player.session_finished.connect(_on_exercise_finished)
	exercise_player.concept_help_requested.connect(_open_contextual_codex)
	exercise_player.learning_signal.connect(_on_nora_learning_signal)
	exercise_player.topic_struggle.connect(_on_pet_struggle)
	exercise_player.answer_resolved.connect(_on_pet_answer_resolved)
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
	style.set_border_width_all(3 if high_contrast else 1)
	style.border_color = Color.WHITE if high_contrast else Color(0.42, 0.9, 0.84, 0.25)
	return style

func _touch_action_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(16)
	style.set_content_margin_all(14)
	style.set_border_width_all(4 if high_contrast else 2)
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
	world_title_label.add_theme_font_size_override("font_size", 17)
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
	objective_label.custom_minimum_size = Vector2(270, 0)
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
	hint.text = "TOCCA IL TERRENO PER MUOVERTI  ·  USA I PULSANTI TOUCH"
	hint.add_theme_color_override("font_color", Color("9fc4bb"))
	hint.add_theme_font_size_override("font_size", 12)
	hint.visible = false
	info.add_child(hint)

	guide_button = Button.new()
	guide_button.name = "GuideToShipButton"
	guide_button.text = "TROVA UNA MISSIONE"
	guide_button.custom_minimum_size = Vector2(180, 46)
	guide_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	guide_button.pressed.connect(_guide_to_objective)
	root.add_child(guide_button)
	utility_menu_button = Button.new()
	utility_menu_button.name = "OpenUtilityMenuButton"
	utility_menu_button.text = "OPZIONI"
	utility_menu_button.anchor_left = 1.0
	utility_menu_button.anchor_right = 1.0
	utility_menu_button.offset_left = -148.0
	utility_menu_button.offset_right = -16.0
	utility_menu_button.offset_top = 68.0
	utility_menu_button.offset_bottom = 114.0
	utility_menu_button.custom_minimum_size.y = 46
	utility_menu_button.pressed.connect(_toggle_utility_menu)
	root.add_child(utility_menu_button)

	# Azione primaria persistente: su tablet è sempre riconoscibile e si abilita
	# vicino a un POI. Tastiera e gamepad restano scorciatoie non essenziali.
	interaction_button = Button.new()
	interaction_button.name = "ContextInteractButton"
	interaction_button.text = "AZIONE\nAVVICINATI A UN PUNTO"
	interaction_button.disabled = true
	interaction_button.anchor_left = 1.0
	interaction_button.anchor_right = 1.0
	interaction_button.anchor_top = 1.0
	interaction_button.anchor_bottom = 1.0
	interaction_button.add_theme_font_size_override("font_size", 18)
	interaction_button.add_theme_color_override("font_color", Color("06272a"))
	interaction_button.add_theme_color_override("font_hover_color", Color("031d20"))
	interaction_button.add_theme_stylebox_override("normal", _touch_action_style(Color("6be7d6"), Color("d8fff8")))
	interaction_button.add_theme_stylebox_override("hover", _touch_action_style(Color("83f4df"), Color.WHITE))
	interaction_button.add_theme_stylebox_override("pressed", _touch_action_style(Color("f6c85f"), Color("fff1b8")))
	interaction_button.add_theme_stylebox_override("disabled", _touch_action_style(Color("426a68"), Color("739b96")))
	interaction_button.pressed.connect(_interact)
	root.add_child(interaction_button)
	pulse_button = Button.new()
	pulse_button.name = "CombatPulseButton"
	pulse_button.text = "IMPULSO\nTOCCA"
	pulse_button.anchor_left = 1.0
	pulse_button.anchor_right = 1.0
	pulse_button.anchor_top = 1.0
	pulse_button.anchor_bottom = 1.0
	pulse_button.tooltip_text = "Stabilizza temporaneamente le anomalie vicine"
	pulse_button.add_theme_font_size_override("font_size", 14)
	pulse_button.add_theme_color_override("font_color", Color("06272a"))
	pulse_button.add_theme_stylebox_override("normal", _touch_action_style(Color("f6c85f"), Color("fff1b8")))
	pulse_button.add_theme_stylebox_override("pressed", _touch_action_style(Color("6be7d6"), Color("d8fff8")))
	pulse_button.add_theme_stylebox_override("disabled", _touch_action_style(Color("5b5131"), Color("9f9462")))
	pulse_button.pressed.connect(_combat_pulse)
	root.add_child(pulse_button)
	shop_button = Button.new()
	shop_button.name = "OpenShopButton"
	shop_button.text = "BOTTEGA"
	shop_button.anchor_left = 1.0
	shop_button.anchor_right = 1.0
	shop_button.offset_left = -132.0
	shop_button.offset_right = -16.0
	shop_button.offset_top = 120.0
	shop_button.offset_bottom = 164.0
	shop_button.custom_minimum_size = Vector2(116, 44)
	shop_button.add_theme_color_override("font_color", Color("f6c85f"))
	shop_button.pressed.connect(_open_shop)
	shop_button.visible = false
	root.add_child(shop_button)
	manual_button = Button.new()
	manual_button.name = "OpenKnowledgeCodexButton"
	manual_button.text = "MANUALE NORA"
	manual_button.anchor_left = 1.0
	manual_button.anchor_right = 1.0
	manual_button.offset_left = -164.0
	manual_button.offset_right = -16.0
	manual_button.offset_top = 168.0
	manual_button.offset_bottom = 214.0
	manual_button.custom_minimum_size.y = 46
	manual_button.add_theme_color_override("font_color", Color("6be7d6"))
	manual_button.pressed.connect(_open_codex)
	manual_button.visible = false
	root.add_child(manual_button)
	_create_touch_controls_customizer(root)
	_load_touch_controls_settings()
	_apply_touch_controls_layout()

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
	feedback_label.name = "FeedbackText"
	feedback_label.add_theme_color_override("font_color", Color("ffffff"))
	feedback_label.add_theme_font_size_override("font_size", 15)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(340, 0)
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_row.add_child(feedback_label)

	_create_economy_panel(root)
	_create_pet_face(root)
	_create_shop_panel(root)

func _create_shop_panel(root: Control) -> void:
	shop_panel = SHOP_PANEL_SCRIPT.new()
	root.add_child(shop_panel)
	shop_panel.setup(gameplay)
	shop_panel.closed.connect(_on_shop_closed)

func _create_touch_controls_customizer(root: Control) -> void:
	touch_controls_button = Button.new()
	touch_controls_button.name = "CustomizeTouchControlsButton"
	touch_controls_button.text = "COMANDI TOUCH"
	touch_controls_button.anchor_left = 1.0
	touch_controls_button.anchor_right = 1.0
	touch_controls_button.offset_left = -164.0
	touch_controls_button.offset_right = -16.0
	touch_controls_button.offset_top = 218.0
	touch_controls_button.offset_bottom = 264.0
	touch_controls_button.custom_minimum_size.y = 46
	touch_controls_button.add_theme_color_override("font_color", Color("f6c85f"))
	touch_controls_button.pressed.connect(_toggle_touch_controls_panel)
	touch_controls_button.visible = false
	root.add_child(touch_controls_button)

	touch_controls_panel = PanelContainer.new()
	touch_controls_panel.name = "TouchControlsCustomizer"
	touch_controls_panel.visible = false
	touch_controls_panel.anchor_left = 1.0
	touch_controls_panel.anchor_right = 1.0
	touch_controls_panel.offset_left = -360.0
	touch_controls_panel.offset_right = -16.0
	touch_controls_panel.offset_top = 120.0
	touch_controls_panel.offset_bottom = 448.0
	touch_controls_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(touch_controls_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	touch_controls_panel.add_child(box)
	var title := Label.new()
	title.text = "PERSONALIZZA L’ESPERIENZA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("e7fff8"))
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	touch_side_button = Button.new()
	touch_side_button.name = "TouchControlsSide"
	touch_side_button.custom_minimum_size.y = 44
	touch_side_button.pressed.connect(_cycle_touch_side)
	box.add_child(touch_side_button)
	touch_size_button = Button.new()
	touch_size_button.name = "TouchControlsSize"
	touch_size_button.custom_minimum_size.y = 44
	touch_size_button.pressed.connect(_cycle_touch_size)
	box.add_child(touch_size_button)
	touch_opacity_button = Button.new()
	touch_opacity_button.name = "TouchControlsOpacity"
	touch_opacity_button.custom_minimum_size.y = 44
	touch_opacity_button.pressed.connect(_cycle_touch_opacity)
	box.add_child(touch_opacity_button)
	high_contrast_button = Button.new()
	high_contrast_button.name = "HighContrastToggle"
	high_contrast_button.custom_minimum_size.y = 44
	high_contrast_button.pressed.connect(_toggle_high_contrast)
	box.add_child(high_contrast_button)
	reduced_motion_button = Button.new()
	reduced_motion_button.name = "ReducedMotionToggle"
	reduced_motion_button.custom_minimum_size.y = 44
	reduced_motion_button.pressed.connect(_toggle_reduced_motion)
	box.add_child(reduced_motion_button)

func _load_touch_controls_settings() -> void:
	if not is_instance_valid(game_save):
		return
	var config: Dictionary = game_save.data.get("config", {})
	var saved: Dictionary = config.get("touchControls", {})
	var side := str(saved.get("side", "right"))
	var size := str(saved.get("size", "large"))
	touch_controls_settings["side"] = side if side in ["left", "right"] else "right"
	touch_controls_settings["size"] = size if size in ["standard", "large"] else "large"
	touch_controls_settings["opacity"] = clampf(float(saved.get("opacity", 1.0)), 0.65, 1.0)

func _persist_touch_controls_settings() -> void:
	if not is_instance_valid(game_save):
		return
	var config: Dictionary = game_save.data.get("config", {})
	config["touchControls"] = touch_controls_settings.duplicate(true)
	game_save.data["config"] = config
	game_save.save()

func _apply_touch_controls_layout() -> void:
	if not is_instance_valid(interaction_button) or not is_instance_valid(pulse_button):
		return
	var on_left := str(touch_controls_settings.get("side", "right")) == "left"
	var is_large := str(touch_controls_settings.get("size", "large")) == "large"
	var margin := 28.0
	var action_width := 332.0 if is_large else 280.0
	var action_height := 72.0 if is_large else 64.0
	var pulse_side := 92.0 if is_large else 76.0
	var lower_hud_clearance := 116.0
	interaction_button.anchor_left = 0.5
	interaction_button.anchor_right = 0.5
	interaction_button.anchor_top = 1.0
	interaction_button.anchor_bottom = 1.0
	interaction_button.offset_left = -action_width * 0.5
	interaction_button.offset_right = action_width * 0.5
	pulse_button.anchor_left = 0.0 if on_left else 1.0
	pulse_button.anchor_right = 0.0 if on_left else 1.0
	pulse_button.anchor_top = 1.0
	pulse_button.anchor_bottom = 1.0
	if on_left:
		pulse_button.offset_left = margin
		pulse_button.offset_right = margin + pulse_side
	else:
		pulse_button.offset_left = -margin - pulse_side
		pulse_button.offset_right = -margin
	interaction_button.offset_top = -lower_hud_clearance - action_height
	interaction_button.offset_bottom = -lower_hud_clearance
	pulse_button.offset_top = -lower_hud_clearance - action_height - 16.0 - pulse_side
	pulse_button.offset_bottom = -lower_hud_clearance - action_height - 16.0
	interaction_button.custom_minimum_size = Vector2(action_width, action_height)
	pulse_button.custom_minimum_size = Vector2(pulse_side, pulse_side)
	interaction_button.add_theme_font_size_override("font_size", 18 if is_large else 15)
	pulse_button.add_theme_font_size_override("font_size", 14 if is_large else 10)
	var opacity := float(touch_controls_settings.get("opacity", 1.0))
	interaction_button.modulate.a = opacity
	pulse_button.modulate.a = opacity
	_refresh_touch_controls_labels()

func _refresh_touch_controls_labels() -> void:
	if is_instance_valid(touch_side_button):
		touch_side_button.text = "IMPULSO: %s" % ("SINISTRA" if str(touch_controls_settings["side"]) == "left" else "DESTRA")
	if is_instance_valid(touch_size_button):
		touch_size_button.text = "DIMENSIONE: %s" % ("GRANDE" if str(touch_controls_settings["size"]) == "large" else "STANDARD")
	if is_instance_valid(touch_opacity_button):
		touch_opacity_button.text = "VISIBILITÀ: %s" % ("PIENA" if float(touch_controls_settings["opacity"]) > 0.9 else "LEGGERA")
	if is_instance_valid(high_contrast_button):
		high_contrast_button.text = "CONTRASTO ELEVATO: %s" % ("SÌ" if high_contrast else "NO")
	if is_instance_valid(reduced_motion_button):
		reduced_motion_button.text = "RIDUZIONE MOVIMENTO: %s" % ("SÌ" if reduced_motion else "NO")

func _toggle_touch_controls_panel() -> void:
	if not is_instance_valid(touch_controls_panel):
		return
	touch_controls_panel.visible = not touch_controls_panel.visible
	if touch_controls_panel.visible:
		_set_utility_menu_visible(false)

func _toggle_utility_menu() -> void:
	if is_instance_valid(touch_controls_panel) and touch_controls_panel.visible:
		touch_controls_panel.visible = false
		_set_utility_menu_visible(true)
		return
	_set_utility_menu_visible(not (is_instance_valid(shop_button) and shop_button.visible))

func _set_utility_menu_visible(value: bool) -> void:
	if is_instance_valid(shop_button):
		shop_button.visible = value
	if is_instance_valid(manual_button):
		manual_button.visible = value
	if is_instance_valid(touch_controls_button):
		touch_controls_button.visible = value
	if is_instance_valid(utility_menu_button):
		utility_menu_button.text = "CHIUDI" if value else "OPZIONI"

func _cycle_touch_side() -> void:
	touch_controls_settings["side"] = "left" if str(touch_controls_settings["side"]) == "right" else "right"
	_apply_touch_controls_layout()
	_persist_touch_controls_settings()

func _cycle_touch_size() -> void:
	touch_controls_settings["size"] = "standard" if str(touch_controls_settings["size"]) == "large" else "large"
	_apply_touch_controls_layout()
	_persist_touch_controls_settings()

func _cycle_touch_opacity() -> void:
	touch_controls_settings["opacity"] = 0.72 if float(touch_controls_settings["opacity"]) > 0.9 else 1.0
	_apply_touch_controls_layout()
	_persist_touch_controls_settings()

func _toggle_high_contrast() -> void:
	high_contrast = not high_contrast
	_apply_accessibility_settings()

func _toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	_apply_accessibility_settings()

func _apply_accessibility_settings() -> void:
	request["accessibility"] = {
		"highContrast": high_contrast,
		"reducedMotion": reduced_motion,
	}
	request["accessibilityExplicit"] = true
	if is_instance_valid(game_save):
		game_save.data["accessibility"] = Dictionary(request["accessibility"]).duplicate(true)
		game_save.save()
	if is_instance_valid(player):
		player.reduced_motion = reduced_motion
	if is_instance_valid(camera):
		camera.position_smoothing_enabled = not reduced_motion
	if is_instance_valid(fireflies):
		fireflies.emitting = not reduced_motion
	if is_instance_valid(world_weather_particles):
		world_weather_particles.emitting = not reduced_motion
	for enemy in get_tree().get_nodes_in_group("world_enemy"):
		if is_instance_valid(enemy):
			enemy.set("reduced_motion", reduced_motion)
	if is_instance_valid(exercise_player):
		exercise_player.configure_accessibility(high_contrast, reduced_motion)
	if is_instance_valid(dialogue_box):
		dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	if is_instance_valid(pet_screen):
		pet_screen.call("configure", game_save, high_contrast, reduced_motion)
	if is_instance_valid(pet_companion):
		pet_companion.set_reduced_motion(reduced_motion)
	for actor in npc_actors:
		if is_instance_valid(actor):
			actor.call("set_reduced_motion", reduced_motion)
	if is_instance_valid(ui_layer):
		for panel in ui_layer.find_children("*", "PanelContainer", true, false):
			(panel as PanelContainer).add_theme_stylebox_override("panel", _panel_style())
	if is_instance_valid(interaction_button):
		interaction_button.add_theme_stylebox_override(
			"normal", _touch_action_style(Color("4b746f"), Color("b5d8d3")))
		interaction_button.add_theme_stylebox_override(
			"disabled", _touch_action_style(Color("31514f"), Color("789b97")))
	if is_instance_valid(pulse_button):
		pulse_button.add_theme_stylebox_override(
			"normal", _touch_action_style(Color("f6c85f"), Color("fff1b8")))
		pulse_button.add_theme_stylebox_override(
			"pressed", _touch_action_style(Color("6be7d6"), Color("d8fff8")))
	_refresh_touch_controls_labels()
	_publish_web_accessibility_state()

func _publish_web_accessibility_state() -> void:
	if not OS.has_feature("web"):
		return
	var nearest_mission := {}
	if NativeWorldState.release_smoke_enabled():
		var mission := _nearest_available_mission()
		if mission != null:
			var screen_position := get_viewport().get_canvas_transform() * mission.global_position
			nearest_mission = {"x": screen_position.x, "y": screen_position.y}
	JavaScriptBridge.eval("window.__eliAccessibility = %s;" % JSON.stringify({
		"highContrast": high_contrast,
		"reducedMotion": reduced_motion,
		"viewportWidth": int(get_viewport_rect().size.x),
		"viewportHeight": int(get_viewport_rect().size.y),
		"worldLevel": world_level,
		"saveMarker": str(game_save.data.get("releaseSmokeMarker", "")) if is_instance_valid(game_save) else "",
		"nearestMission": nearest_mission,
	}))

func _open_shop() -> void:
	if not is_instance_valid(shop_panel):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(interaction_button):
		interaction_button.visible = false
	if is_instance_valid(touch_controls_panel):
		touch_controls_panel.visible = false
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
	if is_instance_valid(touch_controls_panel):
		touch_controls_panel.visible = false
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

# --- Custode (volto sempre visibile) ------------------------------------------
# La scena non decide le espressioni: inoltra SEGNALI DI GIOCO al widget, che li
# traduce con `PetExpressionEngine`. Vedi docs/PET_CUSTODE.md.

func _create_pet_face(root: Control) -> void:
	pet_face = PET_FACE_WIDGET_SCRIPT.new()
	pet_face.name = "PetFaceWidget"
	pet_face.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pet_face.position = Vector2(-104.0, -122.0)
	pet_face.cuddled.connect(_on_pet_cuddled)
	pet_face.screen_requested.connect(_open_pet_screen)
	root.add_child(pet_face)
	pet_screen = PET_SCREEN_SCRIPT.new()
	pet_screen.name = "PetScreen"
	pet_screen.connect("closed", _on_pet_screen_closed)
	pet_screen.connect("customization_changed", _on_pet_customization_changed)
	ui_layer.add_child(pet_screen)
	pet_screen.call("configure", game_save, high_contrast, reduced_motion)
	_refresh_pet_face()

func _refresh_pet_face() -> void:
	if not is_instance_valid(pet_face) or not is_instance_valid(game_save):
		return
	pet_face.visible = PetState.is_granted(game_save)
	pet_face.configure(
		PetState.name_of(game_save),
		PetState.livery(game_save),
		PetState.temperament(game_save),
		PetState.resting_face(game_save),
		PetState.bond(game_save),
		PetState.faces(game_save),
		reduced_motion)

func _pet_react(game_signal: String) -> void:
	if is_instance_valid(pet_face) and pet_face.visible:
		pet_face.react_to(game_signal)

func _on_pet_answer_resolved(is_correct: bool) -> void:
	_pet_react("answer_correct" if is_correct else "answer_wrong")

func _on_pet_cuddled() -> void:
	if not is_instance_valid(game_save):
		return
	# Tetto per sessione: le coccole non devono diventare un lavoro né una barra
	# da riempire. Nessun contatore visibile, nessun obiettivo dichiarato.
	if _pet_cuddles_this_session >= PetState.CUDDLES_PER_SESSION:
		_pet_react("cuddle")
		return
	_pet_cuddles_this_session += 1
	var unlocked := PetState.register_cuddle(game_save)
	game_save.save()
	_pet_react("cuddle")
	_announce_pet_unlocks(unlocked)

func _open_pet_screen() -> void:
	if not is_instance_valid(pet_screen) or not is_instance_valid(game_save):
		return
	if not PetState.is_granted(game_save):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(player):
		player.set_physics_process(false)
	pet_screen.call("configure", game_save, high_contrast, reduced_motion)
	pet_screen.call("open_screen")

func _on_pet_screen_closed() -> void:
	if is_instance_valid(player) and not _blocking_panel_visible():
		player.set_physics_process(true)
	_refresh_prompt()

func _on_pet_customization_changed() -> void:
	_refresh_pet_face()
	_respawn_pet_companion()

func _respawn_pet_companion() -> void:
	if is_instance_valid(pet_companion):
		world_layer.remove_child(pet_companion)
		pet_companion.queue_free()
		pet_companion = null
	_spawn_pet(_resolved_avatar_visual())

func _blocking_panel_visible() -> bool:
	return (is_instance_valid(exercise_player) and exercise_player.visible) \
		or (is_instance_valid(shop_panel) and shop_panel.visible) \
		or (is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible) \
		or (is_instance_valid(dialogue_box) and dialogue_box.visible) \
		or (is_instance_valid(teaching_choice_panel) and teaching_choice_panel.visible) \
		or (is_instance_valid(pet_screen) and pet_screen.visible)

## Consegna il primo Custode: gratuito, e alla prima missione superata. Il volto
## sta sempre in schermo, quindi non si può aspettare il livello 4 e 1500 di
## energia guardando un buco. La cornice narrativa (Lucilla che lo affida) arriva
## con gli itineranti: qui c'è la meccanica, non la scena.
func _grant_pet_if_needed() -> void:
	if not is_instance_valid(game_save) or PetState.is_granted(game_save):
		return
	if not PetState.grant(game_save, world_level):
		return
	game_save.save()
	_refresh_pet_face()
	_respawn_pet_companion()
	_pet_react("festa")
	if PetState.needs_name(game_save):
		_open_pet_naming()

## Chiede il nome. È la prima cosa che si fa col Custode, e non è un dettaglio:
## dare un nome nei primi minuti è ciò che trasforma un compagno in *il proprio*
## compagno. Si può rimandare — il pannello si chiude e il nome resta vuoto —
## perché nessuna richiesta del gioco deve bloccare il gioco.
func _open_pet_naming() -> void:
	if is_instance_valid(pet_naming_panel):
		return
	pet_naming_panel = PanelContainer.new()
	pet_naming_panel.name = "PetNamingPanel"
	pet_naming_panel.add_theme_stylebox_override(
		"panel", _panel_style_with_border(Color(0.02, 0.10, 0.11, 0.96), Color("ffd75e")))
	pet_naming_panel.set_anchors_preset(Control.PRESET_CENTER)
	pet_naming_panel.custom_minimum_size = Vector2(320, 0)
	pet_naming_panel.pivot_offset = Vector2(160, 60)
	pet_naming_panel.position = Vector2(-160, -70)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	pet_naming_panel.add_child(box)

	var title := Label.new()
	title.text = "Ti si è affezionato qualcosa."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("ffe9a8"))
	box.add_child(title)

	var body := Label.new()
	body.text = "È un Custode. Sente dove le cose hanno ancora un significato.\nCome lo chiami?"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color("cfe4e6"))
	box.add_child(body)

	var field := LineEdit.new()
	field.name = "PetNameField"
	field.placeholder_text = "un nome"
	field.max_length = PetState.MAX_NAME_LENGTH
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.custom_minimum_size = Vector2(0, 44)
	field.add_theme_font_size_override("font_size", 17)
	box.add_child(field)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	var later := Button.new()
	later.text = "DOPO"
	later.custom_minimum_size = Vector2(96, 44)
	later.pressed.connect(_close_pet_naming)
	row.add_child(later)

	var confirm := Button.new()
	confirm.name = "PetNameConfirm"
	confirm.text = "È TUO"
	confirm.custom_minimum_size = Vector2(0, 44)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.add_theme_color_override("font_color", Color("07181d"))
	confirm.add_theme_stylebox_override(
		"normal", _touch_action_style(Color("ffd75e"), Color("fff0c0")))
	confirm.pressed.connect(_confirm_pet_name.bind(field))
	row.add_child(confirm)

	ui_layer.add_child(pet_naming_panel)
	field.grab_focus()

func _confirm_pet_name(field: LineEdit) -> void:
	if not is_instance_valid(field) or not is_instance_valid(game_save):
		_close_pet_naming()
		return
	var chosen := PetState.set_pet_name(game_save, field.text)
	if chosen == "":
		# Nessun nome, nessun rimprovero: si può fare dopo.
		_close_pet_naming()
		return
	game_save.save()
	_close_pet_naming()
	_refresh_pet_face()
	_pet_react("festa")
	_spawn_gain_popup("%s è con te" % chosen, Color("ffd75e"))

func _close_pet_naming() -> void:
	if is_instance_valid(pet_naming_panel):
		pet_naming_panel.queue_free()
	pet_naming_panel = null

func _panel_style_with_border(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(18)
	return style

func _announce_pet_unlocks(unlocked: Array) -> void:
	if unlocked.is_empty():
		return
	_refresh_pet_face()
	_spawn_gain_popup("Il Custode ha imparato una faccia", Color("ffd75e"))

func _on_nora_learning_signal(signal_name: String) -> void:
	if not is_instance_valid(game_save):
		return
	NoraState.register(game_save, signal_name)
	game_save.save()
	# Anche il Custode reagisce ai segnali di apprendimento, con il prefisso che il
	# motore conosce. Nessuno di questi produce una faccia negativa, nemmeno
	# `recurring_error`: la mappa vieta le facce negative per costruzione.
	_pet_react("learning:%s" % signal_name)

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
	if reduced_motion:
		_release_gain_popup(label)
		return
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
	if is_instance_valid(dialogue_box) and dialogue_box.visible:
		return
	if is_instance_valid(teaching_choice_panel) and teaching_choice_panel.visible:
		return
	if is_instance_valid(pet_screen) and pet_screen.visible:
		if event.is_action_pressed("leave_portal") and not event.is_echo():
			pet_screen.call("close_screen")
			get_viewport().set_input_as_handled()
		return
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
	elif event.is_action_pressed("combat_pulse") and not event.is_echo():
		_combat_pulse()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("leave_portal") and not event.is_echo():
		_guide_to_ship()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(dialogue_box) and dialogue_box.visible:
		return
	if is_instance_valid(pet_screen) and pet_screen.visible:
		return
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
		_pet_notice_poi(area)
	_refresh_prompt()

## Le uniche destinazioni che contano come «da esplorare»: un incontro, un
## enigma o un minigioco non ancora completato — per costruzione, quelli
## completati non arrivano mai qui (l'area smette di monitorare all'ingresso).
## Portali, landmark e abitanti sono sempre lì e non sono un'esplorazione.
## Vedi docs/CUSTODE_LIVELLO_AVANZATO.md §Asse B.
const PET_POI_KINDS := ["encounter", "enigma", "minigame"]

func _pet_notice_poi(area: Area2D) -> void:
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		return
	if not PET_POI_KINDS.has(str(area.get_meta("kind", ""))):
		return
	_pet_react("near_unexplored")

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
	elif kind == "landmark":
		var landmark_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("%s · %s. Le missioni vicine ne mostrano il progresso." % [
			str(landmark_payload.get("label", "Punto chiave")).capitalize(),
			str(landmark_payload.get("purpose", "si trasforma completando le missioni")),
		])
	elif kind == "enigma":
		var payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s è già ricostruito" % str(payload.get("label", "L'enigma")).capitalize())
		elif is_instance_valid(gameplay) and gameplay.enigma_retry_seconds(id) > 0:
			_set_warning_feedback(
				"Ricostruzione instabile · nessuna ricompensa · ricalibrazione %d s" %
				gameplay.enigma_retry_seconds(id))
		else:
			_set_feedback("Interagisci per ricostruire %s con gli esercizi" % str(payload.get("label", "il ponte")))
	elif kind == "minigame":
		var mg_payload: Dictionary = target.get_meta("payload")
		if not _equipment_requirement_met(target):
			_set_feedback(_equipment_requirement_message(target))
		else:
			_set_feedback("Interagisci · %s: minigioco di %s" % [str(mg_payload.get("label", "Palestra")), str(mg_payload.get("subject", "matematica")).capitalize()])
	elif kind == "treasure":
		if result["collectedTreasureIds"].has(id):
			_set_feedback("Tesoro già raccolto")
		elif not _equipment_requirement_met(target):
			_set_feedback(_equipment_requirement_message(target))
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
	elif kind == "npc":
		var npc_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("Parla con %s · %s" % [
			str(npc_payload.get("label", "abitante")),
			str(npc_payload.get("role", "abitante"))])

	elif kind == "mystery_trace":
		var trace_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("Leggi la Traccia: %s" % str(trace_payload.get("oggetto", "reperto dei Primi")))
	elif kind == "mystery_seed":
		var seed_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("Osserva il seme: %s" % str(seed_payload.get("dove", "dettaglio")))

func _refresh_interaction_button(target: Area2D) -> void:
	if not is_instance_valid(interaction_button):
		return
	var panel_open: bool = (is_instance_valid(exercise_player) and exercise_player.visible) or (is_instance_valid(shop_panel) and shop_panel.visible) or (is_instance_valid(knowledge_codex_panel) and knowledge_codex_panel.visible) or (is_instance_valid(dialogue_box) and dialogue_box.visible)
	interaction_button.visible = not panel_open
	if panel_open:
		return
	if target == null:
		interaction_button.disabled = true
		interaction_button.text = "AZIONE\nAVVICINATI A UN PUNTO"
		interaction_button.tooltip_text = "Si abilita quando Eli è vicino a un punto interattivo"
		return
	var completed := _interaction_is_completed(target)
	var cooldown := (
		gameplay.enigma_retry_seconds(str(target.get_meta("id", "")))
		if str(target.get_meta("kind", "")) == "enigma" and is_instance_valid(gameplay)
		else 0
	)
	interaction_button.disabled = completed or cooldown > 0
	interaction_button.text = (
		"✓ GIÀ COMPLETATO" if completed
		else "RICALIBRAZIONE · %d s" % cooldown if cooldown > 0
		else _interaction_action_text(target)
	)
	interaction_button.tooltip_text = "Azione contestuale disponibile al tocco"

func _update_interaction_countdown() -> void:
	if not is_instance_valid(interaction_button) or not interaction_button.visible:
		interaction_countdown_second = -1
		return
	var target := _nearest()
	if target == null or str(target.get_meta("kind", "")) != "enigma":
		interaction_countdown_second = -1
		return
	var seconds := gameplay.enigma_retry_seconds(str(target.get_meta("id", "")))
	if seconds == interaction_countdown_second:
		return
	interaction_countdown_second = seconds
	_refresh_prompt()

func _interaction_action_text(target: Area2D) -> String:
	if target == null:
		return "INTERAGISCI"
	if not _equipment_requirement_met(target):
		return "SERVE TORCIA" if _required_tool(target) == "tool-torch" else "SERVE FALCE"
	var event_id := str(target.get_meta("id", ""))
	if mission_ownership_flow != null and mission_ownership_flow.requires_request(event_id):
		var owner_id: String = mission_ownership_flow.owner_of(event_id)
		var owner_data := NPC_CATALOG.resident(owner_id)
		return "PARLA CON %s" % str(owner_data.get("nome", owner_id)).to_upper()
	match str(target.get_meta("kind", "")):
		"portal":
			return "ENTRA NELLA NAVE"
		"landmark":
			return "SCOPRI LA FUNZIONE"
		"enigma":
			return "RICOSTRUISCI"
		"minigame":
			return "ALLENATI"
		"treasure":
			return "RACCOGLI"
		"encounter":
			return "AVVIA MISSIONE"
		"npc":
			return "PARLA"
		"mystery_trace":
			return "LEGGI LA TRACCIA"
		"mystery_seed":
			return "OSSERVA IL SEME"
	return "INTERAGISCI"

func _interaction_is_completed(target: Area2D) -> bool:
	var kind := str(target.get_meta("kind", ""))
	var id := str(target.get_meta("id", ""))
	if kind == "treasure":
		return Array(result.get("collectedTreasureIds", [])).has(id)
	if kind == "encounter" or kind == "enigma":
		return Array(result.get("completedEncounterIds", [])).has(id)
	return false

func _required_tool(target: Area2D) -> String:
	if target == null:
		return ""
	var payload: Dictionary = target.get_meta("payload", {})
	return str(payload.get("requiredTool", ""))

func _equipment_requirement_met(target: Area2D) -> bool:
	var required := _required_tool(target)
	return required == "" or required == equipped_field_tool()

func _equipment_requirement_message(target: Area2D) -> String:
	return (
		"Oscurità impenetrabile · equipaggia la Torcia da ricognizione in bottega."
		if _required_tool(target) == "tool-torch"
		else "Erba alta invalicabile · equipaggia la Falce da campo in bottega."
	)

func _interact() -> void:
	var target := _nearest()
	if target == null:
		_set_feedback("Avvicinati a un tesoro, a un incontro o al portale.")
		return
	var kind := str(target.get_meta("kind"))
	var id := str(target.get_meta("id"))
	var completed: Array = result["completedEncounterIds"]
	if kind == "npc":
		_open_npc_dialogue(id)
		return
	if kind == "mystery_trace" or kind == "mystery_seed":
		_open_mystery_artifact(target)
		return
	if kind == "portal":
		if _show_decisive_fallback_if_needed():
			return
		_set_feedback("Ingresso nave attivo: salvataggio in corso…")
		_leave_world()
		return
	if kind == "landmark":
		var landmark_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("%s: %s. Completa le tappe indicate sulla mappa per trasformarlo." % [
			str(landmark_payload.get("label", "Punto chiave")).capitalize(),
			str(landmark_payload.get("purpose", "reagisce ai progressi")),
		])
		_guide_to_objective()
		return
	if kind == "enigma":
		var enigma_payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s è già ricostruito." % str(enigma_payload.get("label", "L'enigma")).capitalize())
			return
		if _route_to_owner_if_needed(id):
			return
		gameplay.try_start_enigma(enigma_payload, id)
		return
	if kind == "minigame":
		if not _equipment_requirement_met(target):
			_set_feedback(_equipment_requirement_message(target))
			return
		# Pratica ripetibile sulla materia dominante del bioma (nessun lock).
		gameplay.try_start_minigame(target.get_meta("payload"), id)
		return
	if kind == "treasure":
		var payload: Dictionary = target.get_meta("payload")
		if not _equipment_requirement_met(target):
			_set_feedback(_equipment_requirement_message(target))
			return
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
		if _route_to_owner_if_needed(id):
			return
		gameplay.try_start_mission(mission_payload, id)
		return


func _on_exercise_finished(exercise_result: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	exercise_player.visible = false
	if is_instance_valid(player):
		player.set_physics_process(true)
	var session_passed := bool(exercise_result.get("passed", false))
	var context: Dictionary = {}
	if is_instance_valid(gameplay):
		context = gameplay.active_session_context.duplicate(true)
		gameplay.resolve_session(exercise_result)
		if str(context.get("kind", "")) in ["mission", "enigma"]:
			var encounter_id := str(context.get("encounterId", ""))
			if mission_ownership_flow != null:
				mission_ownership_flow.record_result(encounter_id, session_passed)
			if session_passed:
				_complete_learning_reaction(encounter_id)
				if world_life != null:
					world_life.enqueue_news({
						"type": str(context.get("kind", "mission")),
						"world": world_level,
						"subject": str(exercise_result.get("subject", _world_subject())),
						"level": game_save.level(),
					})
	# Il legame cresce per aver GIOCATO, superata o no: conta aver provato. Se
	# dipendesse dall'esito, sbagliare costerebbe anche l'affetto del compagno.
	if is_instance_valid(game_save):
		var unlocked := PetState.register_session(game_save)
		_pet_cuddles_this_session = 0
		# Il legame può aver sbloccato una combinella nuova: senza questo, il
		# repertorio restava quello del momento in cui il Custode è comparso.
		if is_instance_valid(pet_companion):
			pet_companion.configure_antics(PetState.antics(game_save))
		_maybe_pet_gift()
		game_save.save()
		_announce_pet_unlocks(unlocked)
		_grant_pet_if_needed()
	_pet_react("session_passed" if session_passed else "session_failed")
	var finished_voice := _maestro_voice_for_session({
		"subject": str(exercise_result.get("subject", _world_subject())),
		"sessionId": str(exercise_result.get("sessionId", "finished")),
	})
	if session_passed and not finished_voice.is_empty():
		_set_nora_feedback("%s · %s" % [
			str(finished_voice.get("name", "Maestro")),
			str(finished_voice.get("chiusura", ""))])
	_refresh_economy()
	_update_ship_navigation()
	_refresh_prompt()

## Ogni tanto, a fine sessione, il Custode ha portato qualcosa.
##
## Arriva da solo: non si chiede, non si cerca, non dipende dall'esito. Un
## bambino che ha appena sbagliato una prova riceve lo stesso il suo sasso, ed è
## metà del motivo per cui il regalo esiste.
##
## NORA lo commenta come un rapporto tecnico. È affetto travestito da inventario:
## non lo sgrida mai e non lo chiama stupido — è un guard-rail del personaggio.
func _maybe_pet_gift() -> void:
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		return
	if _pet_gift_rng == null:
		_pet_gift_rng = RandomNumberGenerator.new()
		_pet_gift_rng.randomize()
	if not PetGifts.rolls_gift(_pet_gift_rng):
		return
	var gift_id := PetGifts.pick(_pet_gift_rng)
	var voce := PetState.register_gift(game_save, gift_id, world_level)
	if voce.is_empty():
		return
	var quanti := PetState.gifts(game_save).size()
	_pet_react("antic")
	_set_nora_feedback(_nora_gift_line(gift_id, quanti))

## Il Custode sdrammatizza al terzo errore sullo stesso argomento nella
## sessione corrente. Non aiuta — non deve, è vietato dai guard-rail del
## Custode — e non lo fa sempre: se lo starnuto non è ancora sbloccato dal
## legame, o il Custode sta già facendo qualcos'altro, non succede niente.
## Vedi docs/CUSTODE_LIVELLO_AVANZATO.md §Asse B.
func _on_pet_struggle(_topic: String) -> void:
	if not is_instance_valid(pet_companion) or not is_instance_valid(game_save):
		return
	if not PetState.is_granted(game_save):
		return
	_pet_silent_antic = true
	if not pet_companion.force_sneeze():
		_pet_silent_antic = false

## Il Custode ha fatto una combinella. Faccia impicciata, e ogni tanto NORA la
## registra. Vedi docs/PET_CUSTODE.md §3.5.
##
## Non ogni volta: una combinella che NORA commenta sempre diventa una didascalia,
## e il tempo comico si perde. Una su tre, e le battute non si ripetono finché non
## sono finite tutte.
func _on_pet_antic(antic_id: String) -> void:
	_pet_react("antic")
	# Lo starnuto sollecitato dal terzo errore consuma qui il proprio silenzio:
	# la faccia reagisce (sopra), ma NORA non lo commenta. È un guard-rail
	# dell'intervento, non solo uno stile — coerente con «NORA non commenta mai
	# un errore», e qui l'errore è la ragione per cui il Custode si è mosso.
	if _pet_silent_antic:
		_pet_silent_antic = false
		return
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		return
	_pet_antic_count += 1
	if _pet_antic_count % 3 != 0:
		return
	var battute: Array = NORA_SU_COMBINELLA.get(antic_id, NORA_SU_COMBINELLA["_qualsiasi"])
	var scelta := str(battute[_pet_antic_line_cursor % battute.size()])
	_pet_antic_line_cursor += 1
	_set_nora_feedback("NORA · %s" % (scelta % PetState.name_of(game_save)))

## Il duetto. NORA non lo sgrida mai e non lo chiama stupido: è affetto travestito
## da rapporto tecnico, ed è un guard-rail del personaggio, non uno stile.
const NORA_SU_COMBINELLA := {
	"tail": [
		"Confermo: %s si è di nuovo stupito della propria coda. Registro l'evento come nuovo, per rispetto.",
	],
	"nap": [
		"%s dorme in piedi e sostiene di no. Non ho elementi per contraddirlo.",
	],
	"guard": [
		"%s sorveglia un sasso da quattro minuti. Non commento.",
	],
	"sneeze": [
		"Ha starnutito. Stavo per dire una cosa importante. Ora non la ricordo. Forse era meglio così.",
	],
	"stare": [
		"%s fissa un punto vuoto del muro. Ho controllato: è vuoto. Lui insiste.",
	],
	"echo": [
		"%s ha risposto al proprio eco. Entrambi sembravano convinti.",
	],
	"_qualsiasi": [
		"Registro il comportamento di %s. Nessuna funzione nota.",
		"%s ha fatto una cosa. Trascrivo senza interpretare.",
		"Nota: %s ha di nuovo agito prima di pensare. Coerenza: alta.",
		"Osservazione su %s: nessun progresso, nessun peggioramento. Stabile.",
	],
}

## Il Custode riconosce un abitante. Vedi docs/PET_CUSTODE.md §3.4.
##
## Una volta per abitante per sessione di gioco: la reazione è fissa apposta —
## è quello che la rende un riconoscimento invece di una battuta a caso — ma
## ripeterla a ogni singolo dialogo la trasformerebbe in rumore.
func _pet_greet(npc_id: String) -> void:
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		return
	if _pet_greeted.has(npc_id):
		return
	var opinione := PetAntics.opinion_for(npc_id)
	if opinione.is_empty():
		return
	_pet_greeted[npc_id] = true
	_pet_react(str(opinione.get("signal", "meet_shy")))
	_present_feedback(str(opinione.get("line", "")) % PetState.name_of(game_save), "pet")

## Il duetto NORA/Custode su un regalo. Vedi docs/PET_CUSTODE.md §3.5.
func _nora_gift_line(gift_id: String, quanti: int) -> String:
	var nome := PetState.name_of(game_save)
	var cosa := PetGifts.label_of(gift_id).to_lower()
	if quanti == 1:
		return "NORA · %s ha portato %s. Apro una voce di inventario. Non so ancora per cosa." % [nome, cosa]
	if gift_id.begins_with("sasso"):
		return "NORA · %s ha portato %s. È il %d° oggetto. Tengo il conto io perché qualcuno deve." % [
			nome, cosa, quanti]
	return "NORA · %s ha portato %s. Registro. Nessuna funzione nota." % [nome, cosa]

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
			_retire_completed_event(node as Area2D)
			break
	_sync_profile_environment_transform(true)

func _retire_completed_event(area: Area2D) -> void:
	## Mantiene l'esito ambientale conquistato, ma ritira affordance, collisione
	## e sfera della tappa. Gli enigmi conservano invece la struttura costruita.
	if not is_instance_valid(area):
		return
	area.set_meta("completed", true)
	for group in ["world_interactable", "mission_poi", "enigma_poi"]:
		if area.is_in_group(group):
			area.remove_from_group(group)
	nearby.erase(area)
	if pending_touch_interaction == area:
		pending_touch_interaction = null
	var collision := area.get_node_or_null("EventCollision") as CollisionShape2D
	if collision != null:
		collision.set_deferred("disabled", true)
	area.set_deferred("monitoring", false)
	area.set_deferred("monitorable", false)
	for child_name in ["EventMarker", "EventCaption"]:
		var visual := area.get_node_or_null(child_name) as CanvasItem
		if visual == null:
			continue
		if reduced_motion:
			visual.queue_free()
			continue
		var tween := create_tween().set_parallel(true)
		tween.tween_property(visual, "modulate:a", 0.0, 0.30)
		tween.tween_property(visual, "scale", Vector2.ONE * 0.32, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(visual.queue_free)
	_refresh_prompt()

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
	var ownership_route := _ownership_navigation_target()
	if not ownership_route.is_empty():
		var route_node := ownership_route.get("node") as Area2D
		if route_node != null:
			player.set_touch_target(route_node.global_position)
			_set_feedback(str(ownership_route.get("message", "Rotta della missione impostata.")))
			_spawn_touch_ping(route_node.global_position)
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
		var ownership_route := _ownership_navigation_target()
		if not ownership_route.is_empty():
			var route_node := ownership_route.get("node") as Area2D
			if route_node != null:
				target_position = route_node.global_position
				prefix = str(ownership_route.get("prefix", "MISSIONE"))
		else:
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
		guide_button.text = "RAGGIUNGI LA NAVE" if bool(runtime.get("ready", false)) or bool(runtime.get("complete", false)) else "SEGUI LA MISSIONE"

func _ownership_navigation_target() -> Dictionary:
	if mission_ownership_flow == null:
		return {}
	var route: Dictionary = mission_ownership_flow.navigation()
	if route.is_empty():
		return {}
	var phase := str(route.get("phase", "mission"))
	if str(route.get("kind", "")) == "npc":
		var npc_id := str(route.get("id", ""))
		var actor := _npc_actor_by_id(npc_id)
		if actor == null:
			return {}
		var data := NPC_CATALOG.resident(npc_id)
		var npc_name := str(data.get("nome", npc_id))
		return {
			"node": actor,
			"prefix": "RITORNA DA %s" % npc_name.to_upper() if phase == "return" else "PARLA CON %s" % npc_name.to_upper(),
			"message": "Ritorna da %s." % npc_name if phase == "return" else "Prima parla con %s: questa missione è sua." % npc_name,
		}
	var event_area := _event_area_by_id(str(route.get("id", "")))
	if event_area == null:
		return {}
	var payload := _mission_payload_for(event_area)
	return {
		"node": event_area,
		"prefix": "MISSIONE %s" % str(payload.get("subject", _world_subject())).to_upper(),
		"message": "Richiesta ricevuta: raggiungi %s." % str(payload.get("label", "la missione")),
	}

func _npc_actor_by_id(npc_id: String) -> Area2D:
	for actor in npc_actors:
		if is_instance_valid(actor) and str(actor.get_meta("id", "")) == npc_id:
			return actor
	return null

func _event_area_by_id(event_id: String) -> Area2D:
	for node in get_tree().get_nodes_in_group("world_interactable"):
		if node is Area2D and str(node.get_meta("id", "")) == event_id:
			return node as Area2D
	return null

func _route_to_owner_if_needed(event_id: String) -> bool:
	if mission_ownership_flow == null or not mission_ownership_flow.requires_request(event_id):
		return false
	var owner_id: String = mission_ownership_flow.owner_of(event_id)
	var actor := _npc_actor_by_id(owner_id)
	var data := NPC_CATALOG.resident(owner_id)
	var npc_name := str(data.get("nome", owner_id))
	if actor != null and is_instance_valid(player):
		player.set_touch_target(actor.global_position)
		_spawn_touch_ping(actor.global_position)
	_set_feedback("Prima parla con %s: questa missione è sua." % npc_name)
	_update_ship_navigation()
	return true

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

func _set_warning_feedback(message: String) -> void:
	_present_feedback(message, "warning")

func _present_feedback(message: String, source: String = "system") -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = message
		feedback_label.add_theme_color_override(
			"font_color",
			Color("ffd08a") if source == "warning" else Color("d6eceb"))
	if is_instance_valid(feedback_panel):
		feedback_panel.visible = message != ""
	if is_instance_valid(feedback_source_label):
		feedback_source_label.text = (
			"NORA" if source == "nora"
			else "TREDICESIMO" if source == "thirteenth"
			else "RICALIBRAZIONE" if source == "warning"
			else "SISTEMA"
		)
		feedback_source_label.add_theme_color_override(
			"font_color",
			Color("6be7d6") if source == "nora"
			else Color("d7dbe0") if source == "thirteenth"
			else Color("f6a85f") if source == "warning"
			else Color("9fc4bb"))
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
		# Il livello si apre col nucleo; l'apparato con la materia del mondo.
		var core_parts: Array = []
		for entry_data in Array(runtime.get("core", [])):
			var entry: Dictionary = entry_data
			core_parts.append("%s %.0f%%" % [
				str(entry.get("subject", "")).substr(0, 3).to_upper(),
				float(entry.get("progress", 0.0)) * 100.0])
		objective_label.text = "Livello %d · Materia %s\nApparato: %s · padronanza %.0f%%/%.0f%%\nNucleo: %s · stanze %d/%d" % [
			int(runtime.get("level", 1)), subject, apparatus,
			float(runtime.get("mastery", 0.0)) * 100.0,
			float(runtime.get("masteryThreshold", 0.0)) * 100.0,
			" · ".join(PackedStringArray(core_parts)),
			int(runtime.get("apparatusRepaired", 0)), int(runtime.get("apparatusTotal", 12))]
	for event_data in mission_events:
		var event: Dictionary = event_data
		if (
			event.has("crossingId")
			and not Array(result.get("completedEncounterIds", [])).has(str(event.get("id", "")))
		):
			objective_label.text = "PASSAGGIO D'ACQUA BLOCCATO\nTrova il ponte-enigma: risolvilo per attraversare\n%s" % objective_label.text
			break
