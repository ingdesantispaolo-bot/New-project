extends Node2D

const PORTAL_POSITION := Vector2(448, 300)
const INTERACTION_DISTANCE := 88.0
const TOUCH_POI_RADIUS := 104.0
const TOUCH_APPROACH_DISTANCE := 58.0
const PORTAL_VISUAL := preload("res://scripts/portal_visual.gd")
const EXERCISE_ENERGY_COST := 3
const EXERCISE_PLAYER_SCRIPT := preload("res://scripts/game/exercise_player.gd")
const ENIGMA_STRUCTURE := preload("res://scripts/visual/enigma_structure.gd")
# chunk_ground.gd non ha class_name: serve il preload per raggiungerne gli statici.
const CHUNK_GROUND_SCRIPT := preload("res://scripts/chunk_ground.gd")
const LEARNING_REACTION_SCRIPT := preload("res://scripts/visual/world_learning_reaction.gd")
const WORLD1_ACTIVITY_SITE_SCRIPT := preload("res://scripts/visual/world1_activity_site.gd")
const SHOP_PANEL_SCRIPT := preload("res://scripts/ui/outdoor_shop_panel.gd")
const NORA_PORTRAIT_SCRIPT := preload("res://scripts/ui/nora_portrait.gd")
const WORLD_LESSON_CATALOG := preload("res://scripts/game/world_lesson.gd")
const KNOWLEDGE_CODEX_PANEL_SCRIPT := preload("res://scripts/ui/knowledge_codex_panel.gd")
const DIARY_PANEL_SCRIPT := preload("res://scripts/ui/diary_panel.gd")
const PET_FACE_WIDGET_SCRIPT := preload("res://scripts/ui/pet_face_widget.gd")
const PET_SCREEN_SCRIPT := preload("res://scripts/ui/pet_screen.gd")
const EQUIPMENT_GATE_SCRIPT := preload("res://scripts/visual/equipment_gate.gd")
const WORLD_ENEMY_SCRIPT := preload("res://scripts/world_enemy.gd")
const NPC_ACTOR_SCRIPT := preload("res://scripts/game/npc_actor.gd")
const NPC_CATALOG := preload("res://scripts/game/npc_catalog.gd")
const ITINERANT_CATALOG := preload("res://scripts/game/itinerant_catalog.gd")
const ENGINEER_LEGEND := preload("res://scripts/game/engineer_legend_catalog.gd")
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
const EXPEDITION_MODULE_PRESENTATION_SCRIPT := preload("res://scripts/visual/expedition_module_presentation.gd")
const SURFACE_STYLES := preload("res://scripts/ui/surface_styles.gd")

const PLAYER_ACCENT := Color("6be7d6")
const NIGHT_TINT := Color(0.46, 0.51, 0.70)
const DAWN_TINT := Color(1.0, 0.84, 0.72)
const WORLD_ATMOSPHERE_SHADER: Shader = preload("res://shaders/world_atmosphere.gdshader")

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
var pause_button: Button
var pause_menu: PauseMenuPanel
var utility_menu_button: Button
var shop_button: Button
var manual_button: Button
var interaction_button: Button
## Il pulsante dello scatto. Su tablet è anche l'unica corsa che esista: `sprint`
## era legato al solo Maiusc, e una tastiera lì non c'è.
var scatto_button: Button
## Il varco dello scatto si spiega una volta sola, la prima volta che capita. Una
## riga che torna a ogni attraversamento diventa rumore, e questa è una cosa che
## si capisce facendola.
var _scatto_varco_raccontato := false
## Il quadro degli obiettivi e il pulsante che lo apre.
var objective_button: Button
var objective_panel: ObjectivePanel
## Il minigioco del personaggio che si sta affrontando, se ce n'e' uno aperto.
var minigame_panel: Control
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
## Il tipo resta Node per non dipendere dall'aggiornamento della cache globale
## delle classi durante l'import headless; lo script e' comunque pre-caricato.
var expedition_module_presentation: Node
var nearby: Array = []
var day_clock := 0.0
## L'etichetta d'autore del mondo («neon-notturno», «blu-profondo»…) e se qui il
## tempo passa. Si leggono una volta all'ingresso: `_process` gira sessanta volte
## al secondo e non deve rifare una ricerca in dizionario per saperlo.
var _lighting_del_mondo := ""
var _il_cielo_cammina := true
var current_audio_phase := ""
var current_biome_chunk := ""
var energy_label: Label
var fragment_label: Label
var reward_name_label: Label
var reward_bar: ProgressBar
var reward_remaining_label: Label
var exercise_player: ExercisePlayer
var knowledge_codex_panel: KnowledgeCodexPanel
var diary_panel: DiaryPanel
var diary_button: Button
var shop_panel: Control
## Il chiavistello: il minigioco che apre i forzieri ([[LockMinigamePanel]]).
var lock_panel: Control
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
var applied_power_grade := -1
var last_energy_visual := -1
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
var high_contrast := false
var reduced_motion := false
var dialogue_box: Control
var npc_actors: Array[Area2D] = []
var npc_dialogue_cursors: Dictionary = {}
var mission_ownership_flow
var world_buildings: Array[Node2D] = []
var world_life
var village_clock := 0.0
var thirteenth_director
var thirteenth_forgotten_npc := ""
var thirteenth_deep_forgotten_npc := ""
var thirteenth_deep_dialogue_cursor := 0
var teaching_choice_panel: Control
var vera_teaching_pending := false
var vera_teaching_used := false
var vera_topic_key := ""
var vera_incrinatura_pending := false
var vera_ricucitura_pending := false
var open_choice_kind := ""
var stance_choice_after_dialogue: Dictionary = {}
var stance_echo_after_dialogue: Dictionary = {}
var ersilia_count_pending := false
var finale_convergence_wave := 0
var finale_wave_heard: Array[String] = []

## Libera le texture per-mondo tenute dalle cache statiche.
##
## Sta in `_exit_tree` e non accanto al `change_scene_to_file` di rientro alla
## nave perche' cosi' copre OGNI uscita dal mondo (nave, menu, cambio livello,
## teardown negli audit) senza doversi ricordare di ogni nuova via d'uscita.
##
## Senza questo la VRAM texture cresceva monotona: misurata a 63,7 MiB dopo il
## mondo 01 e 96,0 MiB dopo il mondo 24 nella stessa sessione, perche' underpaint
## identitarie, landmark e tavole degli enigmi di ogni mondo visitato restavano
## bloccati in cache statiche fino alla chiusura.
func _exit_tree() -> void:
	CHUNK_GROUND_SCRIPT.release_texture_cache()
	EnigmaStructureVisual.release_texture_cache()
	OutdoorVisualFactory.release_world_texture_caches()

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
	gameplay.world_light_changed.connect(_on_world_light_changed)
	gameplay.session_requested.connect(_on_gameplay_session_requested)
	gameplay.feedback_presented.connect(_present_feedback)
	gameplay.enigma_progress.connect(_on_enigma_progress)
	gameplay.minimission_completed.connect(_on_minimission_completed)
	gameplay.topic_consolidated.connect(
		func(_subject: String, _topic: String): _pet_react("topic_consolidated"))
	gameplay.setup(request, result, bool(request.get("loadLocalSave", true)))
	game_save = gameplay.game_save
	# Entrare in un mondo È aver giocato oggi. Idempotente entro la giornata:
	# rientrare dieci volte in un pomeriggio conta un giorno solo.
	if bool(request.get("loadLocalSave", true)) and PlayDiary.register_day(game_save):
		game_save.save()
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
	_stage_stance_world_beat()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_environment", "day")
		audio.call("configure_world_soundscape", str(world_profile.get("soundscape", "")))
		audio.call("play_subject", _world_subject())
	_publish_web_accessibility_state()
	_crea_hazard()
	_crea_tane()
	_crea_sbarramenti()
	_crea_camera_chiusa()
	_crea_velo_di_nebbia()
	# Dopo edifici, punti d'interesse e landmark: i fuochi si appoggiano a loro.
	_crea_i_fuochi_del_risveglio()
	_mostra_soglia_del_mondo()
	_ricorda_cosa_hai_lasciato_qui()

## **Rientrando in un mondo già visto: che cosa adesso sapresti aprire.**
## (19 agosto 2026)
##
## La soglia del mondo si mostra una volta sola, quindi chi torna indietro non
## riceve niente — ed è proprio chi torna indietro che questo lotto vuole
## servire. Una riga, alla ripresa del controllo, e soltanto se c'è davvero
## qualcosa: un promemoria che compare sempre diventa arredamento, e un
## promemoria che promette e non mantiene è peggio del silenzio.
func _ricorda_cosa_hai_lasciato_qui() -> void:
	if not is_instance_valid(game_save):
		return
	var quante := int(game_save.tool_gates_openable(str(world_level), _strumenti_posseduti()))
	if quante <= 0:
		return
	_set_nora_feedback(
		"Qui avevi lasciato %s: adesso hai la chiave." %
		("una cosa chiusa" if quante == 1 else "%d cose chiuse" % quante))

## La schermata di benvenuto del mondo, una volta sola per mondo.
##
## `claim_world_intro` chiede e segna in un colpo solo: due chiamate separate —
## prima «l'ho già vista?» e poi «segnala» — potrebbero mostrarla due volte in un
## rientro rapido, e una schermata che ricompare insegna a chiuderla senza
## leggerla.
##
## Se il pannello non si potesse costruire non succede niente: una schermata di
## benvenuto non deve poter impedire di entrare in un mondo.
func _mostra_soglia_del_mondo() -> void:
	if not is_instance_valid(game_save) or not is_instance_valid(ui_layer):
		return
	# Non quando il mondo è pilotato da qualcun altro.
	#
	# `launch_request_override` lo impostano le prove di scena, mai il gioco
	# vero — che stagia la richiesta via NativeWorldState. Una schermata modale
	# che ferma Eli mandava in timeout gli audit che guidano il mondo, e lo
	# facevano con un messaggio incomprensibile («l'impulso non stabilizza
	# l'anomalia»): il difetto era due strati più in là del sintomo.
	#
	# Il contenuto della soglia resta verificato da `world_intro_audit`, che lo
	# controlla per tutti e ventiquattro i mondi senza costruire la scena.
	if not launch_request_override.is_empty():
		return
	if not game_save.claim_world_intro(world_level):
		return
	var pannello := WorldIntroPanel.new()
	pannello.name = "WorldIntroPanel"
	pannello.livello = world_level
	pannello.chiusa.connect(func():
		if is_instance_valid(pannello):
			pannello.queue_free()
		if is_instance_valid(player):
			player.set_physics_process(true))
	ui_layer.add_child(pannello)
	# Eli si ferma mentre si legge: farla camminare sotto una schermata a tutto
	# schermo la fa finire chissà dove mentre il bambino legge.
	if is_instance_valid(player):
		player.set_physics_process(false)

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
	for index in range(mission_events.size()):
		var event: Dictionary = mission_events[index]
		if str(event.get("kind", "")) != "enigma":
			continue
		var crossing: Dictionary = preview.crossings[0]
		var selected_socket := str(event.get("locationSocket", ""))
		for crossing_data in preview.crossings:
			var candidate: Dictionary = crossing_data
			if selected_socket == "site-%s" % str(candidate.get("id", "")):
				crossing = candidate
				break
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

## Per ogni materia, quante palestre sono già state chiuse in QUESTO mondo.
## Si legge dal salvataggio e non da `result`, perché il piano degli eventi si
## costruisce prima che il delta di sessione sia idratato.
func _practice_rounds() -> Dictionary:
	var out: Dictionary = {}
	if not is_instance_valid(game_save):
		return out
	var chiusi: Array = Array(
		game_save.world_progress(str(world_level)).get("completedEncounterIds", []))
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var prefisso := "evt-%d-practice-%s-r" % [world_level, subject]
		var giri := 0
		for id in chiusi:
			if str(id).begins_with(prefisso):
				giri += 1
		out[subject] = giri
	return out

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
		# Quante palestre di questa materia sono già state chiuse in questo mondo.
		# Dal 6 agosto 2026 una palestra superata sparisce, e la successiva nasce
		# ALTROVE con un identificativo nuovo: senza questo conteggio la materia
		# resterebbe senza pratica per sempre dopo la prima volta.
		"practiceRound": _practice_rounds(),
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
	var tier := WorldProfileCatalog.current_tier()
	return Dictionary(budgets.get(tier, budgets.get("web", {})))

## Quanto lontano le sacche notano Eli adesso. Sta nel contratto runtime
## perche' dipende da un acquisto, e la scena non deve sapere quale.
func _vista_delle_sacche() -> float:
	return float(runtime.get("enemyNoticeScale", ExpeditionModules.VISTA_PIENA))

func _world_subject() -> String:
	return str(world_profile.get("learningFocus", {}).get("subject", "matematica"))

func _configure_profile_palette() -> void:
	var subject := _world_subject()
	# La tavolozza sta in [[SubjectPalette]] e non piu' qui: era in due copie,
	# e la seconda accendeva il nucleo prismatico della nave. Due copie della
	# stessa verita' sono una verita' che prima o poi diverge.
	var accent: Color = SubjectPalette.colore(subject)
	profile_night_tint = NIGHT_TINT.lerp(accent.darkened(0.58), 0.28)
	profile_dawn_tint = DAWN_TINT.lerp(accent.lightened(0.12), 0.30)
	profile_day_tint = Color.WHITE.lerp(accent.lightened(0.42), 0.08)
	if world_level == 1:
		# **La Radura ha un'ora d'oro.** (20 agosto 2026)
		#
		# Era l'unico mondo giocato davvero che ancora derivava le tinte
		# dall'accento della materia: matematica e' verde-azzurra, quindi il suo
		# tramonto veniva **freddo** — un mondo che si chiama «mattino dorato»
		# calava in un crepuscolo d'acquario. Finche' l'orologio era fermo non lo
		# vedeva nessuno, perche' quell'ora non arrivava mai.
		#
		# Le tre tinte adesso sono scritte, e sono un prato: mattino caldo di
		# grano, ora d'oro ambrata al tramonto, notte blu di luna — fredda, ma
		# con dentro il verde dell'erba, o il prato diventerebbe pietra.
		profile_night_tint = Color("41577f")
		profile_dawn_tint = Color("ffa257")
		profile_day_tint = Color("f7edd4")
	elif world_level == 3:
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
	# **L'ora d'autore, dalla tabella.** (20 agosto 2026, [[WorldSky]])
	#
	# Qui c'era un riconoscimento per sottostringa che capiva quattro casi su
	# ventiquattro etichette: diciotto mondi rendevano a mezzogiorno identico,
	# compresi quelli il cui nome prometteva il buio — «neon-notturno» non
	# contiene «notte», e nessuno se n'era accorto perche' il risultato era un
	# mondo perfettamente giocabile, solo con l'ora sbagliata.
	_lighting_del_mondo = str(world_profile.get("lighting", "")).to_lower()
	_il_cielo_cammina = WorldSky.cammina(_lighting_del_mondo)
	if not request.has("resume"):
		day_clock = WorldSky.ora_iniziale(_lighting_del_mondo) * WorldSky.DURATA

func _apply_resume() -> void:
	var resume: Dictionary = request.get("resume", {})
	if resume.is_empty():
		resume = game_save.world_resume(str(world_level))
	if resume.is_empty():
		return
	var resumed := Vector2(float(resume.get("playerX", player.position.x)), float(resume.get("playerY", player.position.y)))
	player.position = chunks.clamp_to_world(resumed)
	# Senza `dayPhase` — un salvataggio piu' vecchio dell'orologio nuovo — l'ora
	# resta quella d'autore, gia' impostata dal profilo. Non e' una perdita: e'
	# l'ora giusta per quel mondo.
	if resume.has("dayPhase"):
		day_clock = fposmod(float(resume["dayPhase"]), 1.0) * WorldSky.DURATA
	if is_instance_valid(camera):
		camera.position = player.position

func _on_runtime_state(state: Dictionary) -> void:
	runtime = state.duplicate(true)
	if is_instance_valid(player):
		player.sprint_multiplier = float(
			runtime.get("sprintMultiplier", ExpeditionModules.SCATTO_BASE))
		player.dash_distance = float(
			runtime.get("dashDistance", ExpeditionModules.SCATTO_DISTANZA))
	# La vista delle sacche gia' in campo si aggiorna appena il modulo entra
	# nell'inventario: un acquisto che si vede solo rientrando nel mondo e' un
	# acquisto che il bambino non collega a quello che ha appena speso.
	var vista := float(runtime.get("enemyNoticeScale", ExpeditionModules.VISTA_PIENA))
	for sacca in get_tree().get_nodes_in_group("world_enemy"):
		if sacca is Node2D:
			sacca.set("vista_scala", vista)
	if is_instance_valid(expedition_module_presentation):
		expedition_module_presentation.apply_runtime(
			runtime, equipped_field_tool(), Array(result.get("collectedTreasureIds", [])))
	# Il richiamo scatta quando l'apparato diventa riparabile, una volta sola.
	if bool(runtime.get("ready", false)) and not _richiamo_attivo:
		_apri_il_richiamo()
	_update_objective()
	_update_ship_navigation()
	_refresh_economy()
	_apply_cosmetic_presentation()
	_update_building_stages()
	if world_life != null:
		world_life.set_stage(_npc_story_stage())
		# Le battute di passaggio devono venire dallo stadio di QUELLA persona:
		# senza questo, chi ha appena completato il suo arco continuerebbe a
		# ripetere quello che diceva prima di capire.
		world_life.set_resident_stages(_stadi_dei_residenti())
	if is_instance_valid(portal) and portal.has_method("set_gate_state"):
		portal.call("set_gate_state", bool(runtime.get("ready", false)), str(runtime.get("apparatus", "nucleo")), bool(runtime.get("complete", false)))

func _on_gameplay_session_requested(session: Dictionary) -> void:
	if not is_instance_valid(exercise_player):
		return
	# Il Custode si mette a guardare: la faccia «concentrato» dura finché qualcosa
	# non la sostituisce, cioè per tutta la prova.
	_pet_react("session_start")
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

## **Il raggio del fiuto.** (19 agosto 2026)
##
## Seicento unità: alla velocità di Eli (260 al secondo) sono poco più di due
## secondi di cammino, cioè poco più di una schermata. È la distanza giusta
## perché il gesto voglia dire «da quella parte, vicino» e non «ecco la mappa»:
## chi si sporge per una cosa a mezzo mondo di distanza sta consegnando un elenco
## con un'altra faccia, ed è esattamente ciò che questo lotto ha tolto.
const PET_FIUTO_RAGGIO := 600.0
## Più fitto del sensore degli Sbiaditi: quello è atmosfera e due secondi bastano,
## questo è un gesto che deve seguire il passo, e a due secondi il Custode si
## sporgerebbe verso un forziere quando Eli gli è già oltre.
const PET_FIUTO_INTERVALLO := 0.7
var _pet_fiuto_trascorso := 0.0
## L'ultima deviazione sentita, per identificativo. Serve a far scattare la
## faccia curiosa **una volta sola** per ogni cosa trovata: un Custode che fa la
## stessa smorfia ogni settecento millisecondi finché resti nel raggio non è un
## compagno, è un allarme.
var _pet_fiuto_ultimo := ""

func _process(delta: float) -> void:
	_animare_potenza_eli(delta)
	if is_instance_valid(pet_companion):
		pet_companion.set_antics_blocked(_blocking_panel_visible())
	_pet_faded_check_elapsed += delta
	if _pet_faded_check_elapsed >= PET_FADED_CHECK_INTERVAL:
		_pet_faded_check_elapsed = 0.0
		_pet_check_faded_proximity()
		_pet_aggiorna_silenzio()
	_pet_fiuto_trascorso += delta
	if _pet_fiuto_trascorso >= PET_FIUTO_INTERVALLO:
		_pet_fiuto_trascorso = 0.0
		_pet_check_secret_proximity()
	# **Il tempo torna a passare.** (20 agosto 2026, [[WorldSky]])
	#
	# Era fermo dal 7 agosto, e la ragione era buona: il mondo si scopriva col
	# lavoro fatto, quindi c'erano due sorgenti di buio che si muovevano da sole
	# e un bambino non poteva sapere se era scuro perche' non aveva ancora
	# lavorato o perche' era calata la notte.
	#
	# Adesso l'avanzamento non tocca piu' la luce della scena — accende fuochi,
	# uno per prova ([[WorldAwakening]]) — e la contraddizione non c'e' piu'.
	# Resta la regola che le tiene separate: **la luce della scena dice che ora
	# e', gli oggetti che si accendono dicono quanto hai lavorato.**
	#
	# Dove non c'e' un cielo — un abisso, una cripta, un archivio — la banda del
	# mondo ha larghezza zero e l'orologio, pur girando, non cambia niente.
	if _il_cielo_cammina:
		day_clock = fposmod(day_clock + delta, WorldSky.DURATA)
	var giro := day_clock / WorldSky.DURATA
	var daylight := WorldSky.luce_del_cielo(_lighting_del_mondo, giro)
	var fase_estesa := WorldSky.fase(daylight, giro)
	var phase_id := WorldSky.fase_di_sistema(fase_estesa)
	if is_instance_valid(day_light):
		# notte → giorno con transizione calda (alba/tramonto) a metà corsa
		var base := profile_night_tint.lerp(profile_day_tint, daylight)
		# Senza torcia la notte è una vera condizione di esplorazione; con la
		# torcia resta scura globalmente ma il chiarore locale diventa ampio.
		#
		# **Possedere la torcia basta.** (20 agosto 2026) Questa riga guardava lo
		# strumento EQUIPAGGIATO mentre la lampada addosso a Eli guarda quello
		# posseduto: chi aveva comprato la torcia e teneva in mano un altro
		# attrezzo si ritrovava la lampada accesa e il mondo scuro come se non
		# l'avesse. Vale qui la ragione gia' scritta la' sotto: una torcia che
		# illumina solo se la si e' scelta in bottega e' un interruttore nascosto
		# in un menu.
		var night_depth := (1.0 - daylight) * (0.06 if _strumenti_posseduti().has(FieldTools.TORCIA) else 0.20)
		base = base.darkened(night_depth)
		var dawn_mix := clampf(1.0 - absf(daylight - 0.5) * 2.2, 0.0, 1.0)
		# Il pavimento di leggibilita' e' l'ultimo passaggio, e per forza: e' una
		# garanzia sul colore che finisce davvero sullo schermo, non
		# sull'intenzione di chi lo ha composto.
		day_light.color = WorldSky.sopra_il_pavimento(base.lerp(profile_dawn_tint, dawn_mix * 0.35))
		if is_instance_valid(phase_label):
			# Dove il tempo non passa, l'ora non e' un'informazione: «Tramonto» in
			# un archivio chiuso o in un abisso e' una parola presa a caso. Li' la
			# targa dice il nome d'autore della luce, che e' la cosa vera di quel
			# posto — ed e' anche il primo posto in cui quelle ventiquattro
			# etichette si vedono in gioco.
			phase_label.text = "%s · %s" % [
				fase_estesa.capitalize() if _il_cielo_cammina
					else _lighting_del_mondo.replace("-", " ").capitalize(),
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
		atmosphere_material.set_shader_parameter("clock", 0.0 if reduced_motion else giro)
		atmosphere_material.set_shader_parameter("motion_factor", 0.0 if reduced_motion else 1.0)
	for node in get_tree().get_nodes_in_group("natural_wind"):
		var canvas := node as CanvasItem
		if canvas != null and canvas.material is ShaderMaterial:
			(canvas.material as ShaderMaterial).set_shader_parameter("wind_strength", 0.0 if reduced_motion else 1.0)
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
		_update_scatto_button()
		_assegna_guardiani()
		if world_life != null:
			var view_size := get_viewport_rect().size
			if is_instance_valid(camera):
				view_size = Vector2(view_size.x / camera.zoom.x, view_size.y / camera.zoom.y)
			var visible_world := Rect2(player.global_position - view_size * 0.5, view_size)
			world_life.set_ambient_enabled(not _blocking_panel_visible())
			world_life.update(
				_turno_del_villaggio(delta), player.global_position, visible_world, delta)
		_update_npc_streaming()

## **Il villaggio ha un ritmo suo, e non è quello della luce.** (16 agosto 2026)
##
## `WorldLife` riceveva `phase_id`, che viene dall'orologio della luce. Quello
## orologio è **fermo** da quando il mondo nasce coperto e si illumina col lavoro
## fatto (il perché sta nel commento in `_process`): il profilo sceglie un'ora
## d'autore e lì resta. Conseguenza mai messa in conto quando la notte è stata
## tolta: la regia della vita riceveva sempre e solo «giorno» in quasi tutti i
## mondi. Tutti verso l'ancoraggio di lavoro, e mai più via — il capannello si
## riformava da solo — e la scena del Ritrovo, che parte all'alba, non si vedeva
## in nessun mondo tranne i tre col profilo di tramonto.
##
## Il turno della gente è adesso una cosa a sé: una giornata di lavoro lunga, un
## raduno breve al Ritrovo, un ritorno al proprio posto. Non è un ciclo
## giorno/notte — la luce non si muove di un capello — è la ragione per cui
## passare due volte dallo stesso punto non dà lo stesso mondo.
##
## I nomi delle fasi restano quelli che `WorldLife` già conosce: cambiarli
## avrebbe voluto dire toccare la regia per un'etichetta.
const TURNO_LAVORO := 110.0
const TURNO_RITROVO := 40.0
const TURNO_RIPOSO := 34.0

## **IL RICHIAMO.** (19 agosto 2026)
##
## Un mondo non aveva una curva: diciotto punti d'interesse equivalenti, in
## qualunque ordine, e poi si tornava al portale camminando come si era arrivati.
## L'esame sta dentro la nave, quindi il mondo esterno finiva senza accorgersene.
##
## Quando l'apparato diventa riparabile il mondo **cambia stato**, una volta
## sola, e non torna indietro finché Eli non se ne va:
##
##   - la luce sale al massimo: qui hai finito, e si vede;
##   - la gente smette di lavorare e si raduna ([[WorldLife]] fase «richiamo»);
##   - le sacche si allungano dietro a Eli — sempre senza fermarla, la regola
##     della mappa non si tocca: solo si accorgono che sta andando via;
##   - la rotta verso la nave si accende.
##
## Non è contenuto nuovo: è regia su cose che c'erano già e non parlavano fra
## loro. Ed è il motivo per cui adesso un mondo ha un inizio, un mezzo e una fine
## invece di un elenco.
var _richiamo_attivo := false

func _apri_il_richiamo() -> void:
	if _richiamo_attivo:
		return
	_richiamo_attivo = true
	# **La fiammata.** (20 agosto 2026) Qui la nebbia si alzava tutta insieme, e
	# il mondo scoperto un pezzo per volta si vedeva intero per la prima volta.
	# Da quando l'avanzamento non passa piu' dalla nebbia, la battuta ce l'hanno i
	# fuochi: quelli accesi divampano insieme, una volta. Non se ne accende
	# nessuno di nuovo — quelli si pagano una prova per volta, e il richiamo non
	# e' una prova.
	_aggiorna_nebbia(1.0, true)
	for nodo in get_tree().get_nodes_in_group("fuoco_del_risveglio"):
		var fuoco := nodo as WorldAwakeningFire
		if is_instance_valid(fuoco):
			fuoco.fiammata()
	for enemy in get_tree().get_nodes_in_group("world_enemy"):
		if is_instance_valid(enemy):
			enemy.set("richiamo", true)
	_accendi_la_rotta()
	_set_nora_feedback(
		"L'apparato è pronto. La nave chiama: senti che la gente ha smesso di lavorare?")
	_update_ship_navigation()

## La rotta accesa: una fila di impulsi dal punto in cui sei fino all'ingresso
## della nave. Non è una freccia e non guida — è la stessa strada di prima, vista
## una volta sola con la luce addosso.
func _accendi_la_rotta() -> void:
	if reduced_motion or not is_instance_valid(player):
		return
	var meta := PORTAL_POSITION
	var da := player.global_position
	var quanti := clampi(int(da.distance_to(meta) / 190.0), 3, 14)
	for indice in range(quanti):
		var punto := da.lerp(meta, float(indice + 1) / float(quanti))
		var scintilla := OutdoorVisualFactory.make_glow(26.0, Color("f6c85f"), 0.0)
		scintilla.name = "RichiamoScintilla_%02d" % indice
		scintilla.position = punto
		scintilla.z_index = 4
		world_layer.add_child(scintilla)
		var tween := create_tween()
		tween.tween_interval(float(indice) * 0.09)
		tween.tween_property(scintilla, "modulate:a", 0.9, 0.22)
		tween.tween_interval(0.5)
		tween.tween_property(scintilla, "modulate:a", 0.0, 0.7)
		tween.tween_callback(scintilla.queue_free)

func _turno_del_villaggio(delta: float) -> String:
	# Durante il richiamo l'orologio del villaggio si ferma sul raduno: la gente
	# non torna al lavoro mentre la nave chiama, e un capannello che si scioglie
	# da solo mentre Eli attraversa il mondo per uscire toglierebbe il momento.
	if _richiamo_attivo or _momento_convergenza_attiva:
		return "richiamo"
	return _turno_dell_orologio(delta)

func _turno_dell_orologio(delta: float) -> String:
	var giro := TURNO_LAVORO + TURNO_RITROVO + TURNO_RIPOSO
	village_clock = fmod(village_clock + maxf(delta, 0.0), giro)
	if village_clock < TURNO_LAVORO:
		return "giorno"
	if village_clock < TURNO_LAVORO + TURNO_RITROVO:
		return "alba"
	return "notte"

func _animare_potenza_eli(delta: float) -> void:
	if reduced_motion or not is_instance_valid(player):
		return
	for nome in ["PowerOrbitInner", "PowerOrbitOuter"]:
		var orbit := player.get_node_or_null(nome) as Node2D
		if orbit != null and orbit.visible:
			orbit.rotation += float(orbit.get_meta("spin", 0.0)) * delta

func _enforce_water_traversal() -> void:
	if not is_instance_valid(player) or chunks == null or chunks.composition == null:
		return
	if not _water_blocks_position(player.position):
		last_traversable_position = player.position
		return
	# **Lo scatto non guada.** (19 agosto 2026) Il fiume si passa col ponte-enigma
	# e con nient'altro: è una decisione vincolante del progetto, e un balzo che
	# la scavalcasse trasformerebbe l'enigma in scenografia. Il balzo si spegne
	# qui — la ricarica resta consumata, perché un balzo tirato contro una riva è
	# comunque un balzo tirato.
	var scattava := player.sta_scattando()
	if scattava:
		player.annulla_scatto()
	player.position = last_traversable_position
	player.velocity = Vector2.ZERO
	player.touch_target = Vector2.INF
	var now := Time.get_ticks_msec()
	if now - water_block_feedback_msec > 1500:
		water_block_feedback_msec = now
		_set_feedback(
			"Nemmeno di slancio: la corrente è invalicabile · ricostruisci il ponte-enigma dalla riva."
			if scattava
			else "La corrente è invalicabile · ricostruisci il ponte-enigma dalla riva.")

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
	atmosphere_material = ShaderMaterial.new()
	atmosphere_material.shader = WORLD_ATMOSPHERE_SHADER
	atmosphere_rect.material = atmosphere_material
	atmosphere_layer.add_child(atmosphere_rect)

func _update_night_glow(daylight: float) -> void:
	# I bagliori (lampade, cristalli, fari…) si accendono al calare della luce.
	var alpha := clampf(0.15 + (1.0 - daylight) * 0.95, 0.15, 1.0)
	for node in get_tree().get_nodes_in_group("night_glow"):
		var canvas := node as CanvasItem
		if canvas != null:
			canvas.modulate.a = alpha
	# I fuochi del risveglio hanno una regola loro, e non e' un capriccio: questo
	# gruppo alza TUTTO al calare della luce, e un fuoco ancora da guadagnare si
	# sarebbe acceso da solo alla prima sera. L'ora decide quanto si vede un
	# fuoco acceso; se sia acceso lo decidono le prove.
	for node in get_tree().get_nodes_in_group("fuoco_del_risveglio"):
		var fuoco := node as WorldAwakeningFire
		if is_instance_valid(fuoco):
			fuoco.aggiorna_notte(daylight)

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
	var power_grade := WorldLight.grado(game_save)
	player_presentation = OutdoorVisualFactory.build_player(livery, power_grade)
	player_presentation.name = "PlayerPresentation"
	player.add_child(player_presentation)
	player.visual = player_presentation.get_node("Visual")
	player.reduced_motion = reduced_motion
	_apply_accessory(player.visual, visual_data)
	_apply_emblem(player.visual, visual_data)
	_apply_upgrade_marks(player.visual)
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
	expedition_module_presentation = EXPEDITION_MODULE_PRESENTATION_SCRIPT.new()
	expedition_module_presentation.name = "ExpeditionModulePresentation"
	add_child(expedition_module_presentation)
	expedition_module_presentation.setup(player)
	expedition_module_presentation.apply_runtime(
		runtime, equipped_field_tool(), Array(result.get("collectedTreasureIds", [])))
	_applica_grado_al_personaggio(power_grade)
	_aggiorna_stato_energia(game_save.energy(), false)
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
			"glyph": str(emblem_item.get("glyph", "◊")),
			"color": int(emblem_item.get("color", 0xf6c85f)),
		}
	return visual_data

func _cosmetic_signature() -> String:
	return JSON.stringify({
		"equipped": runtime.get("cosmeticsEquipped", {}),
		"inventory": runtime.get("cosmeticsInventory", []),
	})

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
	var power_grade := WorldLight.grado(game_save)
	player_presentation = OutdoorVisualFactory.build_player(livery, power_grade)
	player_presentation.name = "PlayerPresentation"
	player.add_child(player_presentation)
	player.visual = player_presentation.get_node("Visual")
	_apply_accessory(player.visual, visual_data)
	_apply_emblem(player.visual, visual_data)
	_apply_upgrade_marks(player.visual)
	_applica_grado_al_personaggio(power_grade)
	_aggiorna_stato_energia(game_save.energy(), false)
	if is_instance_valid(pet_companion):
		world_layer.remove_child(pet_companion)
		pet_companion.queue_free()
		pet_companion = null
	_spawn_pet(visual_data)
	_refresh_pet_face()
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

## Lo strumento che Eli **porta addosso**: decide la livrea e la luce, e non
## decide più nessuna porta. Vedi `_strumenti_posseduti`.
func equipped_field_tool() -> String:
	return str(Dictionary(runtime.get("cosmeticsEquipped", {})).get("tool", ""))

## **Gli strumenti che il giocatore ha.** (19 agosto 2026)
##
## È questo — e non lo slot equipaggiato — che apre le porte. Con due attrezzi la
## differenza era un fastidio (tornare in bottega davanti a un rovo); con cinque
## sarebbe un pedaggio, e comunque in un gioco fatto di chiavi una chiave non si
## equipaggia, si ha. Vedi [[EquipmentGate]].
func _strumenti_posseduti() -> Array:
	var sbloccati: Array = Array(runtime.get("cosmeticsUnlocked", []))
	var out: Array = []
	for id in FieldTools.ids():
		if sbloccati.has(id):
			out.append(id)
	return out

func _update_equipment_presentation() -> void:
	var tool := equipped_field_tool()
	var posseduti := _strumenti_posseduti()
	if is_instance_valid(player):
		var light := player.get_node_or_null("PlayerNightLight") as PointLight2D
		if light != null:
			# Avere la torcia basta per vederci: una torcia che illumina solo se
			# la si è scelta in bottega è un interruttore nascosto in un menu.
			var illumina := posseduti.has(FieldTools.TORCIA)
			light.energy = 1.08 if illumina else 0.10
			light.texture_scale = 3.0 if illumina else 1.15
	if is_instance_valid(expedition_module_presentation):
		expedition_module_presentation.apply_runtime(
			runtime, tool, Array(result.get("collectedTreasureIds", [])))
	for gate in get_tree().get_nodes_in_group("equipment_gate"):
		if gate.has_method("set_strumenti"):
			gate.call("set_strumenti", posseduti)

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
	badge.text = str(emblem.get("glyph", "◊"))
	badge.position = Vector2(22, -61)
	badge.add_theme_font_size_override("font_size", 17)
	badge.add_theme_constant_override("outline_size", 5)
	badge.add_theme_color_override("font_color", OutdoorVisualFactory.hex_color(int(emblem.get("color", 0xf6c85f))))
	badge.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.06, 0.92))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_node.add_child(badge)

func _apply_upgrade_marks(visual_node: Node2D) -> void:
	visual_node.add_child(OutdoorVisualFactory.build_upgrade_marks(
		Array(runtime.get("cosmeticsInventory", [])).duplicate()))

func _spawn_pet(visual_data: Dictionary) -> void:
	var pet_data = visual_data.get("pet", null)
	# Il primo Custode non è un acquisto di bottega: dopo la consegna deve avere
	# un corpo nel mondo anche quando lo slot cosmetico `pet` è vuoto.
	if typeof(pet_data) != TYPE_DICTIONARY and PetState.is_granted(game_save):
		pet_data = {"kind": "spark"}
	if typeof(pet_data) != TYPE_DICTIONARY:
		return
	# **Chi decide il colore del Custode.** (14 agosto 2026)
	#
	# La livrea vinceva sempre, e siccome ne esiste una di default il colore dei
	# compagni comprati in bottega non si vedeva mai: chi pagava 3600 frammenti
	# per il Prisma vedeva il giallo di serie. Adesso l'ordine è quello del
	# significato: una livrea SCELTA a mano dal bambino batte tutto, perché è una
	# decisione; sopra il default silenzioso vince invece l'aspetto comprato.
	#
	# (Non sono due creature: il Custode È il compagno, e lo slot `pet` decide che
	# forma abbia — vedi `_resolved_avatar_visual`.)
	var palette := PetState.livery(game_save)
	var livrea_scelta := not palette.is_empty() 		and Array(palette) != Array(PetState.DEFAULT.get("livery", []))
	var color := OutdoorVisualFactory.hex_color(
		int(palette[0]) if livrea_scelta or not pet_data.has("color")
		else int(pet_data.get("color", 0xf6c85f)))
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

## **Il landmark segue le prove, non le missioni.** (20 agosto 2026)
##
## Fino a ieri la trasformazione del landmark contava gli **eventi del gate**
## conclusi: sette passi in un mondo, cioe' uno ogni venti o trenta minuti. Era
## la stessa grana lenta che il collaudo aveva bocciato — e restava lenta anche
## dopo che il velo di nebbia aveva rimesso a posto il ritmo, perche' il velo
## era un'altra cosa e stava altrove.
##
## Adesso conta le **prove superate** (dodici), le stesse che accendono i
## fuochi. Il contratto didattico non cambia: `environmentTransform` dice «quale
## evento di apprendimento cambia il mondo», e una prova superata e' un evento
## di apprendimento — piu' di quanto lo sia la chiusura amministrativa di un
## incontro. Cambia solo che il mondo risponde cinque volte piu' spesso.
##
## Il landmark e' l'unico posto in cui l'avanzamento si legge **da lontano**: i
## fuochi dicono «e' successo qui», la sua targa dice «quanto manca».
func _sync_profile_environment_transform(animate: bool) -> void:
	if not is_instance_valid(profile_environment_reaction):
		return
	var completed_count := 0
	if is_instance_valid(game_save):
		completed_count = WorldLight.prove_nel_mondo(game_save, _world_id_scena())
	var total_count := WorldLight.PROVE_PER_MONDO
	profile_environment_reaction.set_progress(completed_count, total_count, animate)
	var ratio := clampf(float(completed_count) / maxf(float(total_count), 1.0), 0.0, 1.0)
	if not is_instance_valid(profile_hero_landmark):
		return
	var purpose := profile_hero_landmark.get_node_or_null("LandmarkPurpose") as Label
	if purpose != null:
		purpose.text = "%s\nRISVEGLIO %d/%d" % [
			str(world_profile.get("heroLandmarks", ["PUNTO CHIAVE"])[0]).replace("-", " ").to_upper(),
			mini(completed_count, total_count),
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
		_create_profile_event(event_data as Dictionary)
	_rebuild_practice_circuit()

## La palestra successiva di una materia, piantata altrove a mondo già costruito.
##
## Il piano degli eventi si ricalcola: `_practice_rounds()` legge dal salvataggio
## quante palestre di questa materia sono già chiuse — e quella appena superata
## lo è — quindi il direttore restituisce il giro successivo, con identificativo
## nuovo e posizione nuova. Nessuna posizione inventata qui: la stessa funzione
## che dispone gli eventi alla nascita del mondo dispone anche questo.
func _respawn_practice_event(subject: String) -> void:
	if subject.is_empty():
		return
	var atteso := "evt-%d-practice-%s-r" % [world_level, subject]
	for evento in _planned_world_events():
		var e: Dictionary = evento
		if str(e.get("kind", "")) != "practice" or str(e.get("subject", "")) != subject:
			continue
		var id := str(e.get("id", ""))
		if not id.begins_with(atteso):
			continue
		if Array(result.get("completedEncounterIds", [])).has(id):
			continue
		# Già sulla mappa: può capitare se il piano viene ricalcolato due volte.
		for nodo in get_tree().get_nodes_in_group("world_interactable"):
			if nodo is Area2D and str(nodo.get_meta("id", "")) == id:
				return
		mission_events.append(e)
		_create_profile_event(e)
		_rebuild_practice_circuit()
		return

## Un solo evento, disegnato sulla mappa.
##
## Estratta dal ciclo il 6 agosto 2026 perché serviva chiamarla anche a mondo
## già costruito: quando una palestra viene superata sparisce, e la successiva
## deve comparire subito altrove invece di aspettare il rientro nel mondo.
func _create_profile_event(event: Dictionary) -> void:
	var director_kind := str(event.get("kind", "mission"))
	var scene_kind := (
		"encounter" if director_kind == "mission"
		else "minigame" if director_kind == "practice"
		else "minimission" if director_kind == "minimission"
		else "enigma")
	var event_id := str(event.get("id", ""))
	# Fino al 6 agosto 2026 la pratica era esclusa da questo controllo, e una
	# palestra restava sulla mappa per sempre: lo studente la rifaceva
	# all'infinito guadagnando padronanza sugli STESSI quesiti.
	var completed := Array(result.get("completedEncounterIds", [])).has(event_id)
	var area := Area2D.new()
	area.name = "MissionEvent_%s" % event_id.replace("-", "_")
	area.position = event.get("position", Vector2.ZERO)
	area.monitoring = not completed
	area.monitorable = not completed
	area.set_meta("completed", completed)
	if not completed:
		area.add_to_group("world_interactable")
		area.add_to_group("progress_reaction_poi")
		if bool(event.get("countsForGate", false)):
			area.add_to_group("mission_poi")
		if director_kind == "enigma" or director_kind == "minimission":
			# Le minimissioni si costruiscono a campate come gli enigmi: stanno
			# nello stesso gruppo perché `_on_enigma_progress` le aggiorni senza
			# un secondo instradamento identico al primo.
			area.add_to_group("enigma_poi")
		elif director_kind == "practice":
			area.add_to_group("minigame_poi")
	area.set_meta("kind", scene_kind)
	area.set_meta("id", event_id)
	area.set_meta("directorEvent", event.duplicate(true))
	area.set_meta("location_socket", str(event.get("locationSocket", "")))
	area.set_meta("location_cluster", str(event.get("locationCluster", "fallback")))
	area.set_meta("location_role", str(event.get("locationRole", "route")))
	area.set_meta("discovery_cue", str(event.get("discoveryCue", "proximity")))
	var payload := {
		"subject": str(event.get("subject", _world_subject())),
		"label": _event_label(event),
		"format": str(event.get("format", "multiple_choice")),
		"topicHint": str(event.get("topicHint", "")),
		"countsForGate": bool(event.get("countsForGate", false)),
		"directorKind": director_kind,
		"ownerNpc": NPC_CATALOG.owner_for(world_level, director_kind),
		"locationSocket": str(event.get("locationSocket", "")),
		"locationCluster": str(event.get("locationCluster", "fallback")),
		"locationRole": str(event.get("locationRole", "route")),
		"discoveryCue": str(event.get("discoveryCue", "proximity")),
	}
	if director_kind == "minimission":
		# Il testo autoriale viaggia INTERO nel payload: la logica di gioco non
		# conosce il catalogo, e la scena non riscrive niente di suo. Se un
		# giorno l'incarico del mondo cambia, cambia in un posto solo.
		var incarico := MinimissionCatalog.incarico(world_level)
		for chiave in ["forma", "titolo", "apertura", "esito", "verbo", "glifo", "colore", "gradoRichiesto"]:
			payload[chiave] = incarico.get(chiave, "")
		payload["campate"] = int(event.get("campate", incarico.get("campate", 4)))
	if director_kind == "practice" and world_level >= 2:
		# Solo deviazioni opzionali: nessuno strumento può bloccare il gate.
		#
		# **E nessuna chiave futura su una palestra.** (19 agosto 2026) La prima
		# stesura di questo lotto pescava dai varchi del mondo — quelli già
		# consegnabili *più il prossimo* — e sarebbe stato un errore serio: le
		# undici palestre sono una per materia, e chiuderne una fino a tre mondi
		# dopo vuol dire togliere a un bambino l'unico posto in cui allena quella
		# materia in questo mondo. La progressione non si sarebbe fermata (le
		# palestre non contano per il gate) ma l'apprendimento sì, che è peggio.
		#
		# Le palestre usano quindi solo le chiavi che il mondo ha **già**
		# consegnato: al più restano chiuse fino alla riparazione di questo mondo,
		# che è la scena che le consegna. Le porte che guardano avanti stanno sui
		# forzieri ([[ChunkManager]]), cioè davanti ai frammenti, cioè davanti ai
		# cosmetici — l'unico posto in cui questo gioco ammette di chiudere.
		var chiavi := FieldTools.consegnati_entro(world_level)
		payload["requiredTool"] = str(chiavi[posmod(hash(event_id), chiavi.size())])
	area.set_meta("payload", payload)
	var shape := CollisionShape2D.new()
	shape.name = "EventCollision"
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_DISTANCE
	shape.shape = circle
	shape.disabled = completed
	area.add_child(shape)
	if director_kind == "minimission":
		_disegna_incarico(area, payload, completed)
	elif director_kind == "enigma":
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
		area.add_child(_make_practice_repeater(str(payload["subject"]), completed))
		var equipment_gate := EQUIPMENT_GATE_SCRIPT.new()
		equipment_gate.name = "EquipmentGate"
		area.add_child(equipment_gate)
		equipment_gate.configure(str(payload.get("requiredTool", "")), _strumenti_posseduti())
	elif world_level == 1 and str(payload["subject"]) == "matematica":
		var activity_site := WORLD1_ACTIVITY_SITE_SCRIPT.new()
		activity_site.setup(
			str(payload["format"]), completed,
			OutdoorVisualFactory.hex_color(_profile_accent_rgb()), reduced_motion)
		area.add_child(activity_site)
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
	if world_level == 1 and bool(payload["countsForGate"]) and not completed:
		area.add_child(_make_world1_discovery_cue(event, director_kind))
	# EnigmaStructureVisual possiede già un titolo contestuale leggibile:
	# aggiungerne un secondo produceva etichette sovrapposte su tablet.
	# Una missione già conclusa conserva la trasformazione ambientale, ma non
	# la sfera/caption che la facevano sembrare ancora disponibile.
	if not (director_kind in ["enigma", "minimission"]) and not completed:
		var caption := _make_event_caption(director_kind, str(payload["subject"]))
		caption.name = "EventCaption"
		area.add_child(caption)
	world_layer.add_child(area)
	if director_kind == "minimission" and not completed \
			and WorldLight.prove_nel_mondo(game_save, _world_id_scena()) <= 0 \
			and Array(result.get("completedEncounterIds", [])).is_empty():
		# Al primo ingresso l'incarico non è già piantato sulla mappa: si accende
		# dopo la prima prova riuscita, cioè mentre il mondo sta cambiando.
		area.add_to_group("pending_minimission_reveal")
		area.visible = false
		area.monitoring = false
		area.monitorable = false
	area.body_entered.connect(func(body): on_interactable_entered(area, body))
	area.body_exited.connect(func(body): on_interactable_exited(area, body))

## La Radura insegna a leggere il paesaggio in tre distanze. Il segnale non e'
## un waypoint HUD: nasce dal sito e cambia altezza/intensita' secondo il
## contratto del socket (`proximity`, `local_clue`, `distant_signal`).
func _make_world1_discovery_cue(event: Dictionary, director_kind: String) -> Node2D:
	var cue_type := str(event.get("discoveryCue", "proximity"))
	var root_node := Node2D.new()
	root_node.name = "DiscoveryCue"
	root_node.set_meta("cue_type", cue_type)
	root_node.add_to_group("world1_discovery_cue")
	root_node.z_index = 8
	var elevation := (
		176.0 if director_kind == "enigma"
		else 154.0 if cue_type == "distant_signal"
		else 132.0 if cue_type == "local_clue"
		else 108.0)
	root_node.position = Vector2(0, -elevation)
	var stem := Line2D.new()
	stem.name = "SignalStem"
	stem.points = PackedVector2Array([Vector2(0, 13), Vector2(0, elevation - 70.0)])
	stem.width = 2.0 if cue_type == "proximity" else 3.0
	stem.default_color = Color("8ff6c0", 0.60)
	root_node.add_child(stem)
	var diamond := OutdoorVisualFactory.make_polygon(PackedVector2Array([
		Vector2(0, -14), Vector2(11, 0), Vector2(0, 14), Vector2(-11, 0),
	]), Color("f6cf65") if director_kind == "minimission" else Color("8ff6c0"))
	diamond.name = "SignalDiamond"
	root_node.add_child(diamond)
	var ring := OutdoorVisualFactory.make_ring(22, Color("8ff6c0", 0.72), 2.2, 24)
	ring.scale.y = 0.55
	root_node.add_child(ring)
	if not reduced_motion:
		OutdoorVisualFactory.attach_anim(ring, "pulse", 0.86, 0.62)
	return root_node

func _event_label(event: Dictionary) -> String:
	var subject := str(event.get("subject", _world_subject())).capitalize()
	match str(event.get("kind", "mission")):
		"minimission":
			# Il titolo dell'incarico, non la materia: è l'unica cosa che
			# distingue questo POI da una missione qualsiasi.
			return str(event.get("titolo", MinimissionCatalog.etichetta(world_level)))
		"enigma":
			return "enigma di %s" % subject
		"practice":
			return "evento di pratica · %s" % subject
	return "tappa di missione · %s" % subject

# ---------------------------------------------------------------------------
# **Le riparazioni dei Dodici.** (7 agosto 2026)
#
# Un incarico ha due stati e vanno disegnati **tutti e due**: rotto e riparato.
# Il secondo è il motivo per cui il lotto esiste — se al rientro nel mondo il
# posto tornasse com'era, la minimissione sarebbe stata un esercizio con una
# didascalia sopra, e il collaudo direbbe di nuovo «girovagare senza uno scopo».
#
# Il catalogo (`MinimissionCatalog`) dice che cosa; qui si dice soltanto come si
# vede. Nessun testo nasce in questo file.
# ---------------------------------------------------------------------------

## Il POI di una riparazione: il guasto se è ancora aperta, l'esito se è chiusa.
func _disegna_incarico(area: Area2D, payload: Dictionary, completed: bool) -> void:
	var forma := str(payload.get("forma", MinimissionCatalog.FORMA_RIPARARE))
	var colore := Color(str(payload.get("colore", "ffd75e")))
	if completed:
		area.add_child(_esito_visivo(forma, colore))
		return
	# Il guasto: il glifo della forma, che pulsa piano perché si veda da lontano
	# che lì c'è qualcosa che non va, più le campate dell'enigma — la stessa
	# meccanica, ed è giusto che si assomiglino.
	var guasto := Node2D.new()
	guasto.name = "IncaricoGuasto"
	var glifo := Label.new()
	glifo.text = str(payload.get("glifo", "*"))
	glifo.add_theme_font_size_override("font_size", 34)
	glifo.add_theme_color_override("font_color", colore)
	glifo.position = Vector2(-12, -52)
	guasto.add_child(glifo)
	var titolo := Label.new()
	titolo.text = str(payload.get("titolo", "")).to_upper()
	titolo.add_theme_font_size_override("font_size", 13)
	titolo.add_theme_color_override("font_color", colore)
	titolo.position = Vector2(-96, -76)
	titolo.custom_minimum_size = Vector2(192, 0)
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guasto.add_child(titolo)
	area.add_child(guasto)
	if not reduced_motion:
		var tween := create_tween().set_loops()
		tween.tween_property(glifo, "modulate:a", 0.45, 0.8).set_trans(Tween.TRANS_SINE)
		tween.tween_property(glifo, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	var visual := ENIGMA_STRUCTURE.new()
	visual.name = "EnigmaStructureVisual"
	visual.setup(forma, str(payload.get("subject", "")).capitalize())
	visual.set_stage(0, int(payload.get("campate", 4)))
	area.add_child(visual)

## Come si vede un posto **dopo**. Quattro forme, quattro cose diverse — e tutte
## e quattro devono essere riconoscibili da lontano senza leggere niente.
func _esito_visivo(forma: String, colore: Color) -> Node2D:
	var nodo := Node2D.new()
	nodo.name = "IncaricoEsito"
	match forma:
		MinimissionCatalog.FORMA_LIBERARE:
			# Quello che era chiuso RESTA nel mondo: cinque creature che si
			# muovono attorno al posto in cui erano rinchiuse. È la ricompensa
			# che si vede, ed è l'unica che non serve a niente e vale di più.
			for i in range(5):
				var bestia := Polygon2D.new()
				bestia.polygon = PackedVector2Array([
					Vector2(-6, 0), Vector2(0, -7), Vector2(6, 0), Vector2(0, 5)])
				bestia.color = colore
				var angolo := TAU * float(i) / 5.0
				bestia.position = Vector2.RIGHT.rotated(angolo) * 46.0
				nodo.add_child(bestia)
				if reduced_motion:
					continue
				var giro := create_tween().set_loops()
				giro.tween_property(bestia, "position",
					Vector2.RIGHT.rotated(angolo + 1.4) * 62.0, 2.6 + 0.3 * i
					).set_trans(Tween.TRANS_SINE)
				giro.tween_property(bestia, "position",
					Vector2.RIGHT.rotated(angolo) * 46.0, 2.6 + 0.3 * i
					).set_trans(Tween.TRANS_SINE)
		MinimissionCatalog.FORMA_SPEGNERE:
			# Dove bruciava adesso ricresce: la macchia scura resta, il verde
			# ci sta sopra. Cancellare del tutto il segno del fuoco toglierebbe
			# la prova che lì è successo qualcosa.
			var bruciato := Polygon2D.new()
			bruciato.polygon = _cerchio(52.0, 16)
			bruciato.color = Color(0.16, 0.13, 0.12, 0.85)
			nodo.add_child(bruciato)
			var ripresa := Polygon2D.new()
			ripresa.polygon = _cerchio(34.0, 14)
			ripresa.color = Color(0.35, 0.66, 0.38, 0.9)
			nodo.add_child(ripresa)
		MinimissionCatalog.FORMA_RIPARARE:
			# La macchina FUNZIONA: quattro pale che girano. Un ingranaggio fermo
			# e uno riparato hanno lo stesso aspetto — è il movimento che dice
			# che è finita.
			var mozzo := Polygon2D.new()
			mozzo.polygon = _cerchio(11.0, 10)
			mozzo.color = colore
			nodo.add_child(mozzo)
			var pale := Node2D.new()
			pale.name = "Pale"
			for i in range(4):
				var pala := Polygon2D.new()
				pala.polygon = PackedVector2Array([
					Vector2(-4, 0), Vector2(4, 0), Vector2(6, -44), Vector2(-6, -44)])
				pala.color = colore
				pala.rotation = TAU * float(i) / 4.0
				pale.add_child(pala)
			nodo.add_child(pale)
			if not reduced_motion:
				var rotazione := create_tween().set_loops()
				rotazione.tween_property(pale, "rotation", TAU, 6.0).from(0.0)
		_:
			# RIACCENDERE: un'aureola stabile. La luce vera la fa il velo che si
			# alza (vedi `_on_minimission_completed`); questa dice DOVE è stata
			# riaccesa, che altrimenti sarebbe un effetto senza un posto.
			for raggio in [64.0, 44.0, 26.0]:
				var alone := Polygon2D.new()
				alone.polygon = _cerchio(raggio, 18)
				alone.color = Color(colore.r, colore.g, colore.b, 0.14)
				nodo.add_child(alone)
	return nodo

func _cerchio(raggio: float, lati: int) -> PackedVector2Array:
	var punti := PackedVector2Array()
	for i in range(lati):
		punti.append(Vector2.RIGHT.rotated(TAU * float(i) / float(lati)) * raggio)
	return punti

## La riparazione è finita: il mondo cambia, adesso e per sempre.
##
## «Per sempre» è la parte che costa: l'evento risulta completato nel salvataggio
## (`completedEncounterIds`), quindi al rientro `_create_profile_event` ridisegna
## direttamente l'esito. Qui si fa solo la transizione che si vede accadere.
func _on_minimission_completed(forma: String, encounter_id: String, _esito: String) -> void:
	for area in get_tree().get_nodes_in_group("enigma_poi"):
		if not (area is Area2D) or str(area.get_meta("id", "")) != encounter_id:
			continue
		var poi := area as Area2D
		var payload: Dictionary = poi.get_meta("payload", {})
		var colore := Color(str(payload.get("colore", "ffd75e")))
		for figlio in poi.get_children():
			if figlio.name in ["IncaricoGuasto", "EnigmaStructureVisual"]:
				figlio.queue_free()
		var esito_nodo := _esito_visivo(forma, colore)
		poi.add_child(esito_nodo)
		if not reduced_motion:
			esito_nodo.scale = Vector2.ONE * 0.4
			var entrata := create_tween()
			entrata.tween_property(esito_nodo, "scale", Vector2.ONE, 0.5).set_trans(
				Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		break
	if forma == MinimissionCatalog.FORMA_RIACCENDERE:
		# Riaccendere fa quello che dice: tre prove di luce in un colpo, cioè un
		# quarto del mondo. È l'unica forma che tocca il velo, ed è il motivo per
		# cui esiste come forma a sé.
		var luce := 0.0
		for _i in range(3):
			luce = WorldLight.accendi(game_save, _world_id_scena())
		_aggiorna_nebbia(luce, true)
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "enigmaProgress", 1.18)
	_consegna_strumento_se_dovuto(encounter_id)
	_update_objective()
	_refresh_prompt()

## **Chi ti ha visto lavorare ti passa l'attrezzo.** (14 agosto 2026)
##
## La torcia e la falce non stanno più a listino ([[FieldTools]]): arrivano qui,
## alla prima riparazione finita in un mondo, dalle mani di chi quella
## riparazione l'aveva chiesta. Non costa niente e non si può mancare — le
## minimissioni prendono il posto del primo evento-gate, quindi ci passano tutti.
##
## Se il proprietario non è identificabile la riga cade su una formulazione senza
## nome invece di saltare la consegna: uno strumento mancato chiuderebbe
## deviazioni per il resto della campagna, e nessun dettaglio di messa in scena
## vale quel prezzo.
func _consegna_strumento_se_dovuto(encounter_id: String) -> void:
	if not is_instance_valid(gameplay) or gameplay.reward_manager == null:
		return
	# **Il calendario, dal 19 agosto 2026.** Si consegna il primo strumento dovuto
	# a questo mondo o a uno precedente: chi arriva al 7 senza aver finito una
	# riparazione al 5 riceve prima la leva e la lente al mondo dopo. Gli arretrati
	# non si perdono e non si accavallano — uno per riparazione, in ordine.
	var dovuto := FieldTools.dovuto(gameplay.reward_manager, world_level)
	if dovuto == "":
		return
	if not gameplay.reward_manager.deliver_field_tool(dovuto):
		return
	game_save.save()
	var chi := ""
	if mission_ownership_flow != null:
		var owner_id: String = mission_ownership_flow.owner_of(encounter_id)
		if str(owner_id) != "":
			chi = str(NPC_CATALOG.resident(str(owner_id)).get("nome", ""))
	_set_feedback(FieldTools.riga_di_consegna(dovuto, chi))
	_racconta_dove_apre(dovuto)
	# Lo strumento è addosso da subito: la luce della torcia, i cancelli dei POI e
	# la livrea si aggiornano nello stesso istante della riga, altrimenti il
	# giocatore legge di averlo ricevuto e il mondo non se ne accorge.
	gameplay.call("_emit_state")
	_update_equipment_presentation()
	_apply_cosmetic_presentation()

## **Dove ti aspetta, adesso che ce l'hai.** (19 agosto 2026)
##
## È la riga che chiude l'arcipelago. Un attrezzo nuovo senza questo elenco è una
## bella scena e niente più: nessun bambino si ricorda di aver visto una lastra
## sigillata al mondo 3 dodici ore di gioco prima, e senza il ricordo non torna
## indietro — che era esattamente lo stato del gioco prima di questo lotto.
##
## Non promette niente che non abbia registrato: nomina i mondi in cui **questa
## partita** ha davvero incontrato una porta di quella chiave. Se non ne ha
## incontrata nessuna, non si inventa un elenco: dice che d'ora in poi si aprono,
## e basta.
func _racconta_dove_apre(tool_id: String) -> void:
	if not is_instance_valid(game_save):
		return
	var aperti: Array = game_save.tool_gate_worlds(tool_id)
	if aperti.is_empty():
		return
	var qui := 0
	var altrove: Array = []
	for voce_data in aperti:
		var voce: Dictionary = voce_data
		if int(voce["world"]) == world_level:
			qui = int(voce["porte"])
		else:
			altrove.append("mondo %d" % int(voce["world"]))
	var pezzi: Array = []
	if qui > 0:
		pezzi.append("%d qui" % qui)
	# Al massimo tre mondi per nome: un elenco di otto si legge come un compito.
	if not altrove.is_empty():
		var nomi: Array = altrove.slice(0, 3)
		var coda := " e altri %d" % (altrove.size() - nomi.size()) if altrove.size() > nomi.size() else ""
		pezzi.append("%s%s" % [", ".join(PackedStringArray(nomi)), coda])
	if pezzi.is_empty():
		return
	_set_nora_feedback("Con %s si apre quello che avevi lasciato: %s." % [
		FieldTools.nome(tool_id), " · ".join(PackedStringArray(pezzi))])

func _create_world_buildings() -> void:
	var specs := BUILDING_CATALOG.for_world(world_level, world_profile)
	var occupied: Array = []
	for index in specs.size():
		var spec: Dictionary = specs[index]
		var actor: Node2D = BUILDING_ACTOR_SCRIPT.new()
		actor.call("configure", spec, _building_story_stage(spec), high_contrast, reduced_motion)
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
	var seeds: Array = MYSTERY_CATALOG.semi_for(world_level)
	if not trace.is_empty():
		var trace_area: Area2D = MYSTERY_ARTIFACT_SCRIPT.new()
		trace_area.configure("trace", "trace-%02d" % world_level, trace, high_contrast)
		# Una Traccia già letta resta sulla mappa — si rilegge quando si vuole —
		# ma non è più una scoperta, e il Custode non deve sporgersi verso una
		# cosa che il bambino ha già in mano. Il segno vive nel salvataggio; i
		# semi non hanno una memoria propria e si segnano leggendoli.
		trace_area.set_meta("completed", _mystery_seen_list("tracesSeen").has(str(world_level)))
		trace_area.position = _mystery_artifact_position(
			ruin.global_position, 0, seeds.size() + 1, occupied)
		occupied.append(trace_area.position)
		world_layer.add_child(trace_area)
		_bind_mystery_artifact(trace_area)
	for index in seeds.size():
		var seed_data: Dictionary = seeds[index]
		var seed_area: Area2D = MYSTERY_ARTIFACT_SCRIPT.new()
		var seed_id := "seed-%02d-%d" % [world_level, index]
		seed_area.configure("seed", seed_id, seed_data, high_contrast)
		seed_area.set_meta("completed", _mystery_seen_list("seedsSeen").has(seed_id))
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
	# Letta è letta: resta sulla mappa e si rilegge quando si vuole, ma smette di
	# essere una scoperta — e quindi smette di far sporgere il Custode.
	target.set_meta("completed", true)
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
		# La riga di Eli, quando c'è, è una seconda schermata e mai una sola: il
		# giocatore legge prima la cosa e poi cosa ne pensa lei, che è l'ordine in
		# cui la guarderebbe davvero. Il prefisso segue il contratto dei beat.
		var eli_line := str(payload.get("eli", "")).strip_edges()
		if eli_line != "":
			pages.append("Eli: %s" % eli_line)
		var sister := str(payload.get("sorella", "")).strip_edges()
		if sister != "":
			# **L'unico che sente dove il significato è svanito** (PET_CUSTODE §1).
			# Una traccia di sorella è esattamente quello, e il Custode non dice
			# niente — cambia faccia, e sta al bambino accorgersene.
			_pet_react("sister_found")
		speaker = sister if sister != "" else str(payload.get("dove", "dettaglio")).capitalize()
		role = "Traccia di una sorella" if sister != "" \
			else "Seme · %s" % str(payload.get("colpo", "mistero")).replace("-", " ")
		_mark_mystery_seen("seedsSeen", id)
		# Il fascicolo di Squadra non è soltanto un collezionabile: quando si
		# chiude l'ultima pagina, il giocatore decide che cosa farne. Il legame
		# usa l'id del dialogo, così nessun altro seme del mondo 23 può aprire la
		# scelta per sbaglio.
		if world_level == 23 and str(payload.get("sorella", "")) == "Squadra" \
				and StanceChoices.dovuta(game_save.data, "squadra-quaderno"):
			stance_choice_after_dialogue[id] = "squadra-quaderno"
	if pages.is_empty() or str(pages[0]).strip_edges() == "":
		return
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", id, speaker, role, pages)
	_refresh_interaction_button(null)

## **Aprire un forziere.** (14 agosto 2026)
##
## Prima era una riga sola per tutti: «Tesoro raccolto: +N frammenti». Adesso il
## forziere ha un contenuto ([[TreasureCatalog]]) e tre modi di consegnarlo, che
## sono tre pesi diversi dello stesso gesto:
##
##   LASCITO   la roba di qualcuno che abita qui. Si ferma il gioco e si legge,
##             come per una Traccia — è l'unico forziere che chiede un momento;
##   CUSTODE   il Custode fruga e tiene una cosa inutile per sé. Va a finire
##             nella lista dei regali, che a fine campagna è il diario del
##             viaggio (`PetGifts`);
##   RESTO     una riga di feedback, e si cammina.
##
## La ricompensa in frammenti la decide il catalogo e non più il payload
## procedurale: `rewardFragments` era tarato su un'economia in cui i frammenti
## non compravano niente. Vedi [[FragmentEconomy]].
##
## L'ordine conta: si incassa **prima** e si racconta dopo. Chi chiude il
## riquadro senza leggere ha già preso tutto, e nessun testo di questo gioco può
## stare fra un bambino e una cosa che ha guadagnato.
## **Il chiavistello davanti al forziere.** (14 agosto 2026)
##
## Richiesta del committente: i forzieri si aprono con un minigioco di velocità
## di matematica, difficoltà per mondo. Qui c'è solo la regia — le regole stanno
## in [[LockChallenge]], la scena in [[LockMinigamePanel]].
##
## Il seme cambia a ogni tentativo (`Time.get_ticks_msec`): un chiavistello
## fallito e riprovato non deve poter essere rifatto a memoria, altrimenti la
## seconda volta non si calcola più — si ricorda, che è la cosa che questo gioco
## non vuole insegnare.
func _apri_forziere(target: Area2D, id: String) -> void:
	if is_instance_valid(lock_panel):
		return
	var custode := is_instance_valid(game_save) and PetState.is_granted(game_save)
	var tipo := TreasureCatalog.tipo_di(id, custode)
	var regole := LockChallenge.regole(world_level, tipo, reduced_motion)
	var etichetta := "forziere chiuso con cura" if tipo == TreasureCatalog.TIPO_LASCITO else "cassa"
	lock_panel = LockMinigamePanel.new()
	lock_panel.name = "LockMinigamePanel"
	lock_panel.risolto.connect(func(vinto: bool, pulito: bool):
		_chiudi_chiavistello(target, id, vinto, pulito))
	ui_layer.add_child(lock_panel)
	lock_panel.call("avvia", regole, etichetta,
		hash("%s:%d" % [id, Time.get_ticks_msec()]), reduced_motion, high_contrast)
	# Eli si ferma: il pannello è modale, e lasciarla camminare sotto uno schermo
	# pieno la fa finire chissà dove. Stessa regola del varco.
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)

## Il chiavistello ha ceduto — o non ha ceduto. Fallire non toglie niente: il
## forziere resta chiuso dov'è, non risulta raccolto, e si può riprovare subito.
func _chiudi_chiavistello(target: Area2D, id: String, vinto: bool, pulito: bool) -> void:
	if is_instance_valid(lock_panel):
		lock_panel.queue_free()
		lock_panel = null
	if is_instance_valid(player):
		player.set_physics_process(true)
	if not vinto:
		# Va tolto dai raccolti: `_interact` lo aveva segnato prima di aprire, e
		# un forziere che risulta preso senza essere stato aperto è la sola cosa
		# peggiore di un forziere che non si apre.
		var raccolti: Array = result["collectedTreasureIds"]
		raccolti.erase(id)
		_set_warning_feedback(LockChallenge.riga_di_fallimento())
		_refresh_prompt()
		return
	_svuota_forziere(target, id, pulito)

func _svuota_forziere(target: Area2D, id: String, pulito := true) -> void:
	var custode_disponibile := is_instance_valid(game_save) and PetState.is_granted(game_save)
	var contenuto := TreasureCatalog.contenuto(world_level, id, custode_disponibile)
	var premio := int(contenuto.get("frammenti", 0))

	gameplay.collect_treasure({"rewardFragments": premio}, id)
	_update_objective()
	_refresh_economy()
	_spawn_gain_popup("+%d frammenti" % premio, Color("c7b8ff"))
	if is_instance_valid(pet_companion):
		pet_companion.react()
	nearby.erase(target)
	var owner_node := target.get_parent()
	if is_instance_valid(owner_node):
		owner_node.queue_free()
	_refresh_prompt()

	# Il chiavistello pulito non vale frammenti in più — il contenuto di un
	# forziere non dipende da come si gioca ([[TreasureCatalog]]) — vale una riga
	# diversa, che è l'unico premio che non sposta l'economia.
	if pulito and is_instance_valid(pet_companion):
		_pet_react("antic")

	match str(contenuto.get("tipo", TreasureCatalog.TIPO_RESTO)):
		TreasureCatalog.TIPO_LASCITO:
			_racconta_lascito(id, contenuto, premio)
		TreasureCatalog.TIPO_CUSTODE:
			_regalo_dal_forziere(id, contenuto, premio)
		_:
			_set_feedback("%s %s +%d frammenti." % [
				LockChallenge.riga_di_vittoria(pulito),
				str(contenuto.get("cosa", "Una cassa di roba.")), premio])

## Il forziere di qualcuno. Lo speaker è l'oggetto e non la persona — la persona
## non c'è, ed è metà di quello che il forziere racconta. Il ruolo dice di chi
## era, quando il mondo ha un cast scritto; quando non ce l'ha, l'oggetto parla
## da solo invece di attribuirsi un proprietario inventato.
func _racconta_lascito(id: String, contenuto: Dictionary, premio: int) -> void:
	var chi: Dictionary = contenuto.get("proprietario", {})
	var nome := str(chi.get("nome", ""))
	var ruolo := "Lasciato qui da %s · %s" % [nome, str(chi.get("ruolo", "abitante"))] if nome != "" \
		else "Lasciato qui da qualcuno"
	var pages: Array = [str(contenuto.get("cosa", ""))]
	var riga_eli := str(contenuto.get("eli", "")).strip_edges()
	if riga_eli != "":
		# Stesso contratto dei semi del mistero: prima la cosa, poi cosa ne pensa
		# lei. È l'ordine in cui la guarderebbe davvero.
		pages.append("Eli: %s" % riga_eli)
	if pages.is_empty() or str(pages[0]).strip_edges() == "":
		_set_feedback("Forziere aperto: +%d frammenti." % premio)
		return
	_set_feedback("+%d frammenti." % premio)
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", "forziere-%s" % id,
		str(contenuto.get("nome", "reperto")).capitalize(), ruolo, pages)
	_refresh_interaction_button(null)

## Il Custode fruga nel forziere e tiene una cosa che non serve a niente. NORA
## non la commenta qui: la commenta la schermata del Custode, dove la lista dei
## regali è già il diario del viaggio. Se la registrazione fallisce — id ignoto,
## Custode non concesso — resta un forziere normale, senza mezze scene.
func _regalo_dal_forziere(id: String, contenuto: Dictionary, premio: int) -> void:
	if _pet_gift_rng == null:
		_pet_gift_rng = RandomNumberGenerator.new()
		_pet_gift_rng.randomize()
	# Il regalo è stabile sull'id come tutto il resto del forziere: due partite
	# diverse trovano la stessa cosa nella stessa cassa.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:regalo" % id)
	var gift_id := PetGifts.pick(rng)
	var voce := PetState.register_gift(game_save, gift_id, world_level)
	if voce.is_empty():
		_set_feedback("%s +%d frammenti." % [str(contenuto.get("cosa", "Una cassa di roba.")), premio])
		return
	game_save.save()
	_pet_react("antic")
	_set_feedback("%s %s. E per te, +%d frammenti." % [
		str(contenuto.get("riga", "Il Custode fruga nella cassa.")),
		PetGifts.label_of(gift_id).to_lower(),
		premio,
	])

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
	for building in world_buildings:
		if is_instance_valid(building):
			var resident_owner := str(building.get_meta("resident_owner", ""))
			var current_stage := _resident_story_stage(resident_owner) \
				if resident_owner != "" else _npc_story_stage()
			building.call("set_stage", current_stage)

func _building_story_stage(spec: Dictionary) -> int:
	var resident_owner := str(spec.get("residentOwner", ""))
	return _resident_story_stage(resident_owner) if resident_owner != "" else _npc_story_stage()

## Il primo stadio segue ancora ciò che Eli impara; il compimento, invece,
## appartiene alla persona la cui convinzione è stata messa alla prova. Il
## marcatore `gioco-<npc>` è persistente e distinto per residente: è il segnale
## che mancava al vecchio contatore unico del mondo.
func _resident_story_stage(npc_id: String) -> int:
	if npc_id == "" or not is_instance_valid(gameplay):
		return 0
	if _minigioco_personaggio_superato(npc_id):
		return 2
	return mini(NpcArc.stadio(gameplay.progression_manager, npc_id), 1)

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
		actor.position = _npc_home_position(npc_id, data, index, occupied)
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
			itinerant.position = _npc_home_position(
				itinerant_id, actor_data, npc_actors.size(), occupied)
			occupied.append(itinerant.position)
			world_layer.add_child(itinerant)
			itinerant.body_entered.connect(func(body): on_interactable_entered(itinerant, body))
			itinerant.body_exited.connect(func(body): on_interactable_exited(itinerant, body))
			npc_actors.append(itinerant)
	# Dopo l'itinerante, non prima: la messa in scena degli archi deve vedere
	# tutto il cast — le tre parole sotto il nome e il fumetto valgono anche per
	# chi è di passaggio.
	_metti_in_scena_gli_archi()

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

## **Ognuno sta dove ha senso che stia.** (16 agosto 2026)
##
## Segnalazione del committente: «non devono essere collocati tutti insieme ma
## sparsi intelligentemente nella mappa». Aveva ragione, e la causa era doppia.
##
## La prima: `_npc_spawn_position` distribuiva il cast su **quattro ancoraggi
## fissi in un anello di quattrocento pixel attorno al punto di sbarco**,
## assegnati per indice. Chiunque fossero, i quattro abitanti del mondo si
## trovavano tutti nei primi dieci passi, in un capannello che non voleva dire
## niente — mentre i loro luoghi, che il catalogo assegna **per nome** in
## `BuildingCatalog._resident_owner`, restavano vuoti. Il gioco sapeva già che
## Tobia lavora alla Casa del Conto e che Nonna Ersilia presidia la Fontana dei
## Filari: non lo usava per metterceli.
##
## Adesso la posizione viene da CHI È la persona:
##
##   specialista  alla Casa del mestiere — è il suo laboratorio, e trovarcelo
##                dentro spiega l'edificio senza una riga di testo;
##   testimone    al Ritrovo, il luogo che presidia;
##   bislacco     fuori mano, lontano dagli edifici e dal corridoio sicuro:
##                incontrarlo dev'essere una piccola scoperta, non un saluto
##                obbligatorio all'arrivo;
##   itinerante   sulla strada fra lo sbarco e la nave — è di passaggio, e lo si
##                incontra camminando, che è l'unico modo sensato.
##
## La distanza minima fra due abitanti sale da 150 a 420 pixel: sotto quella
## soglia due presenze si leggono ancora come un gruppo.
const NPC_MIN_SEPARATION := 420.0

func _npc_home_position(npc_id: String, data: Dictionary, index: int, occupied: Array) -> Vector2:
	var base := _npc_home_base(npc_id, data)
	for attempt in 32:
		var angle := TAU * float(attempt) / 8.0
		var radius := 0.0 if attempt == 0 else 90.0 + 60.0 * floori(float(attempt) / 8.0)
		var candidate := chunks.clamp_to_world(base + Vector2.RIGHT.rotated(angle) * radius)
		if chunks.composition != null:
			if chunks.composition.is_protected(candidate, 72.0) \
					or chunks.composition.raw_water_weight(candidate) >= 0.24:
				continue
		var blocked := candidate.distance_to(_hero_landmark_position()) < 150.0
		for event in mission_events:
			if candidate.distance_to(event.get("position", Vector2.ZERO)) < 150.0:
				blocked = true
				break
		for used in occupied:
			if candidate.distance_to(used as Vector2) < NPC_MIN_SEPARATION:
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
	# Nessun posto libero attorno al luogo giusto: meglio l'anello di ripiego che
	# una presenza addosso a un'altra o dentro l'acqua.
	return _npc_spawn_position(index, occupied)

func _npc_home_base(npc_id: String, data: Dictionary) -> Vector2:
	var spawn: Vector2 = world_profile.get("spawn", Vector2(0, 1180))
	if not NPC_CATALOG.resident(npc_id).is_empty():
		if str(data.get("funzione", "")) == "testimone":
			return ritrovo_position() + Vector2(-136, 128)
		return _building_role_position("work_home") + Vector2(136, 128)
	var lato_bislacco := -1.0 if posmod(hash("%s:bislacco-lato" % world_seed), 2) == 0 else 1.0
	if not NPC_CATALOG.bislacco(npc_id).is_empty():
		# Fuori mano ma dentro il raggio raggiungibile: la direzione è decisa dal
		# seme del mondo, così due mondi non mettono lo stravagante nello stesso
		# angolo, e resta la stessa a ogni rientro nello stesso mondo.
		#
		# Fra 28° e 66° sopra l'orizzonte, da un lato o dall'altro. Mai in
		# verticale sopra lo sbarco: lì passa il corridoio sicuro e più su c'è il
		# raggio protetto della nave, e una presenza piazzata dentro finirebbe
		# spinta fuori dal ripiego, cioè di nuovo nel capannello.
		var quota := float(posmod(hash("%s:bislacco" % world_seed), 1000)) / 1000.0
		var angolo := lerpf(deg_to_rad(28.0), deg_to_rad(66.0), quota)
		return spawn + Vector2(cos(angolo) * lato_bislacco, -sin(angolo)) * 1180.0
	# Itinerante: a mezza via sulla risalita verso la nave, spostato di lato —
	# il corridoio sicuro non si occupa mai — e dalla parte opposta allo
	# stravagante, così i due che stanno fuori dai luoghi non stanno insieme.
	var ship: Vector2 = Dictionary(world_profile.get("shipEntrance", {})).get(
		"position", Vector2.ZERO)
	return spawn.lerp(ship, 0.58) + Vector2(430.0 * -lato_bislacco, 0.0)

## Anello di ripiego attorno allo sbarco. Non è più il criterio di collocazione
## degli abitanti — lo usano la convergenza del finale, dove il cast **deve**
## radunarsi, e i casi in cui attorno al luogo giusto non c'è terreno libero.
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
	var ruin_center := _hero_landmark_position()
	var social_offsets := [Vector2(-108, 92), Vector2(108, 92), Vector2(0, 164), Vector2(190, 40)]
	for index in npc_actors.size():
		var actor := npc_actors[index]
		var npc_id := str(actor.get_meta("id", ""))
		anchor_map[npc_id] = {
			"home": actor.global_position,
			"work": _safe_world_life_anchor(_npc_work_anchor_base(
				npc_id, work_center, social_center, ruin_center, actor.global_position), index),
			"ritrovo": _safe_world_life_anchor(social_center + social_offsets[index % social_offsets.size()], index + 7),
		}
	world_life = WORLD_LIFE_SCRIPT.new()
	world_life.configure(world_level, npc_actors, anchor_map, _npc_story_stage(), reduced_motion)
	world_life.set_resident_stages(_stadi_dei_residenti())

## **Il posto di lavoro è il PROPRIO, non quello di tutti.** (16 agosto 2026)
##
## Seconda causa del capannello, e la più insidiosa perché agiva DOPO aver
## sparso il cast: l'ancoraggio `work` era la Casa del mestiere per tutti e
## quattro, con quattro scostamenti presi per indice. La fase «giorno» è quella
## in cui il mondo resta per quasi tutta la visita — la luce non si muove più,
## vedi `_process` — quindi ogni abitante camminava verso lo stesso edificio e non
## se ne andava più. Bastava girare due minuti e li si ritrovava tutti lì.
##
## Adesso il turno di lavoro di ciascuno sta dove sta il suo mestiere. Il Ritrovo
## resta il solo momento in cui si radunano davvero, ed è giusto che sia l'unico:
## è la scena in cui si parlano fra loro.
func _npc_work_anchor_base(npc_id: String, work_center: Vector2, social_center: Vector2,
		ruin_center: Vector2, home: Vector2) -> Vector2:
	# Il turno sta dall'altro lato dell'edificio rispetto a dove la persona
	# staziona (vedi `_npc_home_base`): se coincidessero non ci sarebbe niente da
	# percorrere, e il turno di lavoro non si vedrebbe affatto.
	var funzione := str(NPC_CATALOG.resident(npc_id).get("funzione", ""))
	if funzione == "specialista":
		return work_center + Vector2(-150, -96)
	if funzione == "testimone":
		return social_center + Vector2(168, -104)
	if not NPC_CATALOG.bislacco(npc_id).is_empty():
		# Lo stravagante non ha un mestiere: gira attorno alla Rovina, che è la
		# cosa del mondo di cui nessuno sa dare una spiegazione sensata.
		#
		# Dalla parte della Rovina opposta alla nave, e non con uno scostamento
		# fisso: la Rovina di alcuni mondi sta a ridosso del corridoio sicuro, e
		# uno scostamento verso l'interno lo infilava dentro (`world_life_audit`).
		# Allontanarsi lungo il raggio nave→Rovina esce sempre da entrambi.
		var ship: Vector2 = Dictionary(world_profile.get("shipEntrance", {})).get(
			"position", Vector2.ZERO)
		var fuori := ship.direction_to(ruin_center)
		if fuori.length_squared() < 0.01:
			fuori = Vector2.DOWN
		return ruin_center + fuori * 230.0
	# L'itinerante è di passaggio: il suo turno è restare sulla strada.
	return home

func _stadi_dei_residenti() -> Dictionary:
	var stadi: Dictionary = {}
	if not is_instance_valid(gameplay):
		return stadi
	for attore in npc_actors:
		if not is_instance_valid(attore):
			continue
		var npc_id := str(attore.get_meta("id", ""))
		if npc_id != "" and NpcArc.ha_arco(npc_id):
			stadi[npc_id] = NpcArc.stadio(gameplay.progression_manager, npc_id)
	return stadi

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

## **Il cambiamento si deve vedere camminando.** (8 agosto 2026)
##
## Passo successivo di «i personaggi cambiano perché tu impari»: finora lo
## stadio dell'arco si leggeva soltanto parlandoci. Attraversando il mondo, un
## residente che ha completato il suo arco e uno che non l'ha nemmeno cominciato
## erano identici — e un cambiamento che si vede solo aprendo un dialogo è un
## cambiamento che quasi nessuno vedrà.
##
## Due segni, e sono diversi apposta:
##
##   - **l'attività sotto il nome**: tre parole, leggibili da lontano, che dicono
##     che qualcosa si è mosso senza dire che cosa (il che cosa costa
##     l'avvicinarsi, ed è giusto);
##   - **la vicinanza**: chi è arrivato in fondo al suo arco lo si trova accanto
##     a un altro residente. È il segno più forte perché non è scritto: due
##     persone che prima stavano ai due capi della radura adesso stanno insieme,
##     e non serve leggere niente per accorgersene.
func _metti_in_scena_gli_archi() -> void:
	if not is_instance_valid(gameplay):
		return
	var progressione = gameplay.progression_manager
	var in_fondo: Array = []
	for attore in npc_actors:
		if not is_instance_valid(attore):
			continue
		var npc_id := str(attore.get_meta("id", ""))
		if npc_id == "":
			continue
		if attore.has_method("set_activity"):
			attore.call("set_activity", NpcArc.attivita(progressione, npc_id))
		if NpcArc.in_fondo_all_arco(progressione, npc_id):
			in_fondo.append(attore)
	# Serve qualcuno a cui stare accanto: con un solo residente arrivato in fondo
	# lo si avvicina a un altro qualsiasi del mondo. Da soli non si insegna.
	if in_fondo.is_empty() or npc_actors.size() < 2:
		return
	for attore in in_fondo:
		var compagno := _compagno_di_arco(attore)
		if compagno == null:
			continue
		# Accanto, non addosso: a centoventi pixel si leggono come due persone
		# che stanno parlando, e restano due bersagli distinti da toccare.
		var verso := compagno.position.direction_to(attore.position)
		if verso.length_squared() < 0.01:
			verso = Vector2.RIGHT
		attore.position = chunks.clamp_to_world(compagno.position + verso * 120.0)

## A chi va vicino chi è arrivato in fondo al suo arco.
##
## Prima era «il primo altro attore della lista», che con quattro presenze nello
## stesso capannello non si notava. Adesso che il cast è sparso, spostare Tobia
## dall'altra parte della mappa per metterlo accanto a un venditore ambulante di
## passaggio sarebbe un'immagine falsa: chi ha capito una cosa la insegna a
## qualcuno **di qui**, e nell'arco scritto nel catalogo è sempre così.
##
## L'ordine è quello del significato: prima l'altro residente del mondo (è la
## persona con cui condivide la materia), poi lo stravagante, e l'itinerante mai
## — quello è già in cammino verso altrove.
func _compagno_di_arco(attore: Area2D) -> Area2D:
	var stravagante: Area2D = null
	for altro in npc_actors:
		if not is_instance_valid(altro) or altro == attore:
			continue
		var altro_id := str(altro.get_meta("id", ""))
		if not NPC_CATALOG.resident(altro_id).is_empty():
			return altro
		if stravagante == null and not NPC_CATALOG.bislacco(altro_id).is_empty():
			stravagante = altro
	return stravagante

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
			var residents := Array(cast.get("residents", []))
			thirteenth_deep_forgotten_npc = thirteenth_director.choose_deep_forgotten_resident(
				residents, bool(persistent.get("deepSmemoraUsed", false)))
			if thirteenth_deep_forgotten_npc != "":
				# Persistiamo che è accaduto, non che è ancora attivo. Il bersaglio
				# vive soltanto in questa scena e uscire dal mondo lo ripristina.
				persistent["deepSmemoraUsed"] = true
				persistent["deepSmemoraHistory"] = {
					"world": world_level,
					"resident": thirteenth_deep_forgotten_npc,
				}
				_apply_deep_smemora_visual(true)
			else:
				thirteenth_forgotten_npc = thirteenth_director.choose_forgotten_resident(residents)
			if thirteenth_deep_forgotten_npc != "" or thirteenth_forgotten_npc != "":
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
	# Nel mondo 22 la voce puntuale della scelta sostituisce il richiamo
	# ambientale: due finestre simultanee farebbero passare inosservata proprio
	# la domanda che conta.
	var voice: Dictionary = {} if (
		world_level == 22 and StanceChoices.dovuta(game_save.data, "tredicesimo-domanda")
	) else thirteenth_director.next_voice()
	if not voice.is_empty():
		var pages := PackedStringArray(Array(voice.get("dice", [])))
		get_tree().create_timer(5.0).timeout.connect(func():
			if is_inside_tree() and not _blocking_panel_visible():
				_present_feedback("\n".join(pages), "thirteenth")
		)

## Due scelte arrivano da una voce, non da un oggetto o da un NPC. Entrambe
## passano da un breve dialogo saltabile e solo alla sua chiusura aprono il
## pannello: prima si sente il momento, poi si prende posizione.
func _stage_stance_world_beat() -> void:
	# Le fixture pilotano già tempi e input della scena. Un beat automatico che
	# compare due secondi dopo trasforma un audit di dialogo/enigma in una gara
	# contro un timer; l'unico audit che prova questi beat li abilita in modo
	# esplicito. Il gioco normale non usa mai `launch_request_override`.
	if not launch_request_override.is_empty() \
			and not bool(request.get("stageNarrativeBeatsInFixture", false)):
		return
	if world_level == 22 and StanceChoices.dovuta(game_save.data, "tredicesimo-domanda"):
		var pages: Array = []
		for raw in ThirteenthCatalog.lines_for(22):
			var entry: Dictionary = raw
			var candidate := Array(entry.get("dice", []))
			if " ".join(PackedStringArray(candidate)).to_lower().contains("fammi una domanda"):
				pages = candidate.duplicate()
				break
		_schedule_stance_dialogue(
			"tredicesimo-domanda", "Il Tredicesimo", "Una voce che si ritira", pages, 2.4)
	elif world_level == 23 and StanceChoices.dovuta(game_save.data, "meridiana-riga"):
		_schedule_stance_dialogue(
			"meridiana-riga",
			"NORA",
			"Sensori lunghi · segnale di quattrocento anni fa",
			[
				"I sensori lunghi hanno agganciato una riga ancora accesa.",
				"Meridiana: «c'è qualcosa. venite.»",
			],
			2.4)

func _schedule_stance_dialogue(
	choice_id: String,
	speaker: String,
	role: String,
	pages: Array,
	delay: float,
	attempt: int = 0
) -> void:
	if pages.is_empty() or not is_inside_tree():
		return
	get_tree().create_timer(delay).timeout.connect(
		_try_show_stance_dialogue.bind(choice_id, speaker, role, pages, attempt))

func _try_show_stance_dialogue(
	choice_id: String,
	speaker: String,
	role: String,
	pages: Array,
	attempt: int
) -> void:
	if not is_inside_tree() or not StanceChoices.dovuta(game_save.data, choice_id):
		return
	if _blocking_panel_visible():
		if attempt < 30:
			_schedule_stance_dialogue(choice_id, speaker, role, pages, 1.5, attempt + 1)
		return
	var dialogue_id := "stance-beat-%s" % choice_id
	stance_choice_after_dialogue[dialogue_id] = choice_id
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", dialogue_id, speaker, role, pages)
	set_meta("stance_world_beat", choice_id)

func _apply_deep_smemora_visual(enabled: bool) -> void:
	for actor in npc_actors:
		if is_instance_valid(actor) and str(actor.get_meta("id", "")) == thirteenth_deep_forgotten_npc:
			if actor.has_method("set_deep_forgotten"):
				actor.call("set_deep_forgotten", enabled)
			set_meta("deep_smemora_visual_target", thirteenth_deep_forgotten_npc if enabled else "")
			return

func _restore_deep_smemora(show_return: bool) -> void:
	if thirteenth_deep_forgotten_npc == "":
		return
	var restored_id := thirteenth_deep_forgotten_npc
	for actor in npc_actors:
		if is_instance_valid(actor) and str(actor.get_meta("id", "")) == restored_id:
			if show_return and actor.has_method("play_deep_memory_return"):
				actor.call("play_deep_memory_return")
			elif actor.has_method("set_deep_forgotten"):
				actor.call("set_deep_forgotten", false)
			break
	thirteenth_deep_forgotten_npc = ""
	set_meta("deep_smemora_visual_target", "")
	if not show_return or not is_instance_valid(dialogue_box):
		return
	var data := NPC_CATALOG.resident(restored_id)
	var returns: Array = (ThirteenthCatalog.SMEMORA_PROFONDO as Dictionary).get("ritorno", [])
	if data.is_empty() or returns.is_empty():
		return
	if is_instance_valid(player):
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call(
		"show_dialogue",
		"deep-smemora-return-%s" % restored_id,
		str(data.get("nome", restored_id)),
		"Il gesto e il suo scopo tornano insieme",
		Array(returns[0]).duplicate())

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
	if npc_id == thirteenth_deep_forgotten_npc:
		# Se sta per diventare proprietario, l'incarico ha la precedenza e il
		# caso si scioglie prima dell'assegnazione. Così `smemora` non può mai
		# trasformare una scena emotiva in un blocco di missione.
		var about_to_assign: bool = mission_ownership_flow != null \
			and not mission_ownership_flow.assignment_for(npc_id).is_empty()
		if _active_mission_owner() == npc_id or about_to_assign:
			_restore_deep_smemora(false)
		else:
			_open_deep_smemora_dialogue(npc_id)
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
			# **Lo stadio è di QUESTO personaggio, e dipende da quanto hai
			# imparato nella SUA materia.** (8 agosto 2026)
			#
			# Prima veniva da `_npc_story_stage()`, che contava gli incontri
			# chiusi in quella visita: tutti i residenti del mondo cambiavano
			# insieme, e cambiavano perché avevi toccato delle cose. Un coro che
			# reagisce all'orologio, non delle persone che imparano.
			var stage := NpcArc.stadio(gameplay.progression_manager, npc_id)
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
				if npc_id == "itin-orsolo" and _orsolo_proof_available() \
						and StanceChoices.dovuta(game_save.data, "orsolo-prova"):
					lines = ITINERANT_CATALOG.lines_of(npc_id, "prova_accettata")
					mission_pool = "prova_accettata"
					stance_choice_after_dialogue[npc_id] = "orsolo-prova"
				else:
					var pool_order: Array = ["saluto", str(data.get("funzione", ""))]
					# `attrito` descrive la funzione di Orsolo, ma le sue battute di
					# attrito si chiamano `dubbio`: esplicitarlo evita che la sua
					# conversione arrivi senza che lo si sia mai sentito dubitare.
					if npc_id == "itin-orsolo":
						pool_order.append("dubbio")
					pool_order.append_array(["riempimento", "congedo"])
					for pool_name in pool_order:
						if pool_name != "":
							lines.append_array(Array(pools.get(pool_name, [])))
					# **La leggenda dell'Ingegnere** (docs/ABITANTI_E_LUOGHI.md §2.5,
					# 16 agosto 2026): una sola voce, nella voce di registro
					# dell'itinerante, mescolata al resto del riempimento. Un solo
					# elemento su un totale di dieci-quattordici battute mantiene la
					# rarità prevista (massimo 1 estrazione su 10) senza bisogno di un
					# contatore a parte — la stessa rotazione a cursore che sceglie le
					# altre battute la sceglie di rado, per costruzione.
					var leggenda := ENGINEER_LEGEND.for_registro(str(data.get("registro", "")))
					if not leggenda.is_empty():
						lines.append(leggenda[absi(hash(npc_id)) % leggenda.size()])
				if npc_id == "itin-vera" and not vera_teaching_used:
					var vera_arc := _vera_arc_lines()
					if not Array(vera_arc.get("lines", [])).is_empty():
						lines = vera_arc["lines"]
						mission_pool = str(vera_arc["pool"])
					else:
						vera_topic_key = _vera_applied_topic()
						if vera_topic_key != "":
							var teaching_lines := ITINERANT_CATALOG.lines_of(npc_id, "rispiegamelo")
							if not teaching_lines.is_empty():
								lines = teaching_lines
								mission_pool = "rispiegamelo"
								vera_teaching_pending = true
						elif VeraArc.stadio(game_save.data) == VeraArc.STADIO_RICUCITO:
							# Solo quando non c'è niente da rispiegare: la meccanica
							# didattica viene sempre prima del colore.
							var teaching_back := ITINERANT_CATALOG.lines_of(npc_id, VeraArc.POOL_INSEGNA)
							if not teaching_back.is_empty():
								lines = teaching_back
								mission_pool = VeraArc.POOL_INSEGNA
	if data.is_empty() or lines.is_empty():
		return
	var cursor_key := "%s:%s" % [npc_id, mission_pool if mission_pool != "" else "ordinary"]
	var cursor := int(npc_dialogue_cursors.get(cursor_key, 0))
	var pages: Array = (lines[cursor % lines.size()] as Array).duplicate()
	npc_dialogue_cursors[cursor_key] = cursor + 1
	# **Prima di sentirlo parlare, lo si guarda.** (8 agosto 2026)
	#
	# L'arco del residente — tre righe scritte per quarantasei personaggi — non
	# era letto da nessuno tranne il suo audit. È il pezzo di catalogo che
	# racconta come cambia, ed è scritto in terza persona apposta: non è una
	# battuta, è quello che il bambino OSSERVA. Le persone non annunciano di
	# essere cambiate.
	#
	# Sta in testa alle pagine perché è il contesto in cui va letto tutto il
	# resto: la stessa battuta detta da chi conta uno per uno e da chi ha appena
	# imparato a raggruppare non vuol dire la stessa cosa.
	#
	# **Solo nel dialogo ordinario.** Quando il residente sta chiedendo una
	# missione, o reagendo a come è andata, l'osservazione davanti è rumore: si
	# è lì per un'altra ragione, e una pagina in più allunga uno scambio che
	# deve restare svelto. Se ne è accorto `world_l1_readiness_audit`, che
	# pretende che la conta di Ersilia stia in tre schermate — ed è una pretesa
	# giusta: quelle pagine le legge un bambino in piedi davanti a qualcuno.
	if mission_pool == "" and NpcArc.ha_arco(npc_id):
		var osservazione := NpcArc.osservazione(gameplay.progression_manager, npc_id)
		if osservazione != "":
			var apertura: Array = [osservazione]
			# La cosa che crede, sulla STESSA pagina: è il contesto
			# dell'osservazione, non un capitolo a parte. E aggiungere una
			# seconda pagina allungherebbe uno scambio che deve restare svelto —
			# `world_l1_readiness_audit` pretende tre schermate, e ha ragione.
			var credenza := NpcArc.riga_di_credenza(gameplay.progression_manager, npc_id)
			if credenza != "":
				apertura.append(credenza)
			var traguardo := NpcArc.nota_di_traguardo(gameplay.progression_manager, npc_id)
			if traguardo != "":
				apertura.append(traguardo)
			pages.insert(0, "\n".join(PackedStringArray(apertura)))
	if not pending_return.is_empty():
		mission_ownership_flow.consume_return(npc_id)
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call(
		"show_dialogue", npc_id, str(data.get("nome", npc_id)),
		str(data.get("ruolo", "abitante")), pages, _resident_story_stage(npc_id))
	_update_ship_navigation()
	_refresh_interaction_button(null)

func _orsolo_proof_available() -> bool:
	var narrative: Dictionary = game_save.data.get("narrative", {})
	return not Array(narrative.get("tracesSeen", [])).is_empty() \
		or not Array(narrative.get("seedsSeen", [])).is_empty()

func _open_deep_smemora_dialogue(npc_id: String) -> void:
	# Il proprietario di una missione non può essere colpito nemmeno se la
	# proprietà cambiasse dopo il caricamento della scena.
	if _active_mission_owner() == npc_id:
		_restore_deep_smemora(false)
		return
	var data := NPC_CATALOG.resident(npc_id)
	var lines: Array = (ThirteenthCatalog.SMEMORA_PROFONDO as Dictionary).get("battute", [])
	if data.is_empty() or lines.is_empty():
		return
	var pages: Array = Array(lines[thirteenth_deep_dialogue_cursor % lines.size()]).duplicate()
	thirteenth_deep_dialogue_cursor += 1
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call(
		"show_dialogue",
		npc_id,
		str(data.get("nome", npc_id)),
		"Continua a lavorare · lo scopo non c'è più",
		pages)
	set_meta("deep_smemora_dialogue_override", npc_id)

func _open_finale_convergence_dialogue(npc_id: String) -> void:
	var data := NPC_CATALOG.resident(npc_id)
	if data.is_empty():
		data = ITINERANT_CATALOG.itinerant(npc_id)
		if not data.is_empty():
			data["ruolo"] = str(data.get("funzione", "itinerante")).capitalize()
	var pages := FINALE_CATALOG.lines_for(npc_id)
	if data.is_empty() or pages.is_empty():
		return
	if npc_id == "itin-orsolo":
		var echo := StanceChoices.eco_pendente(game_save.data, "orsolo-prova")
		if echo != "":
			pages.append(echo.trim_prefix("Orsolo:").strip_edges())
			stance_echo_after_dialogue[npc_id] = "orsolo-prova"
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

## **Il minigioco del personaggio.** (9 agosto 2026)
##
## Si apre chiudendo il dialogo di chi ne ha uno: e' il momento giusto, perche'
## si e' appena letto che cosa quella persona crede — e il gioco serve proprio a
## mettere quella convinzione alla prova.
##
## Vincerlo non regala progressione: lascia frammenti e fa avanzare la storia di
## quel personaggio. La padronanza si guadagna con le prove, e un minigioco di
## velocita' non e' una prova di matematica.
func _apri_minigioco_personaggio(npc_id: String) -> void:
	if is_instance_valid(minigame_panel) or not CharacterMinigameCatalog.ha_gioco(npc_id):
		return
	if not is_instance_valid(ui_layer):
		return
	# Un pannello per archetipo: la meccanica cambia, il contorno no. Il
	# catalogo dice quale, e la scena non conosce nessuna regola di gioco.
	var scheda_gioco := CharacterMinigameCatalog.scheda(npc_id)
	match str(scheda_gioco.get("archetipo", "")):
		CharacterMinigameCatalog.ARCHETIPO_SCAFFALE:
			minigame_panel = ShelfMinigamePanel.new()
			minigame_panel.name = "ShelfMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_CICLO:
			minigame_panel = preload("res://scripts/ui/cycle_minigame_panel.gd").new()
			minigame_panel.name = "CycleMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_TRACCIA:
			minigame_panel = preload("res://scripts/ui/trace_minigame_panel.gd").new()
			minigame_panel.name = "TraceMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_RADIO:
			minigame_panel = preload("res://scripts/ui/radio_minigame_panel.gd").new()
			minigame_panel.name = "RadioMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_MERCATO:
			minigame_panel = preload("res://scripts/ui/market_minigame_panel.gd").new()
			minigame_panel.name = "MarketMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_CIRCUITO:
			minigame_panel = CircuitMinigamePanel.new()
			minigame_panel.name = "CircuitMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_LEVA:
			minigame_panel = LeverMinigamePanel.new()
			minigame_panel.name = "LeverMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_ALTALENA:
			minigame_panel = preload("res://scripts/ui/seesaw_minigame_panel.gd").new()
			minigame_panel.name = "SeesawMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_RITMO:
			minigame_panel = preload("res://scripts/ui/rhythm_count_panel.gd").new()
			minigame_panel.name = "RhythmCountPanel"
		CharacterMinigameCatalog.ARCHETIPO_VIBRAZIONE:
			minigame_panel = preload("res://scripts/ui/vibration_minigame_panel.gd").new()
			minigame_panel.name = "VibrationMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_GLIFI:
			minigame_panel = preload("res://scripts/ui/glyph_minigame_panel.gd").new()
			minigame_panel.name = "GlyphMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_PARENTELA:
			minigame_panel = preload("res://scripts/ui/kinship_minigame_panel.gd").new()
			minigame_panel.name = "KinshipMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_PROVA:
			minigame_panel = ControlledTrialMinigamePanel.new()
			minigame_panel.name = "ControlledTrialMinigamePanel"
		CharacterMinigameCatalog.ARCHETIPO_STIMA:
			minigame_panel = EstimateMinigamePanel.new()
			minigame_panel.name = "EstimateMinigamePanel"
		_:
			minigame_panel = PileMinigamePanel.new()
			minigame_panel.name = "PileMinigamePanel"
	minigame_panel.risolto.connect(func(vinto: bool, presi: int, totale: int):
		_chiudi_minigioco_personaggio(npc_id, vinto, presi, totale))
	ui_layer.add_child(minigame_panel)
	minigame_panel.avvia(scheda_gioco, reduced_motion)
	if is_instance_valid(player):
		player.set_physics_process(false)

func _chiudi_minigioco_personaggio(npc_id: String, vinto: bool, presi: int, totale: int) -> void:
	if is_instance_valid(minigame_panel):
		minigame_panel.queue_free()
		minigame_panel = null
	if is_instance_valid(player):
		player.set_physics_process(true)
	var scheda := CharacterMinigameCatalog.scheda(npc_id)
	if vinto:
		var premio := FragmentEconomy.PREMIO_MINIGIOCO
		var gioco_id := "gioco-%s" % npc_id
		# Lo stesso id che rende unico il premio rende unico anche il momento
		# narrativo. Senza rispecchiarlo nel risultato di sessione, il pannello si
		# riapriva a ogni saluto fino al prossimo riavvio del mondo.
		var raccolti: Array = Array(result.get("collectedTreasureIds", []))
		if not raccolti.has(gioco_id):
			raccolti.append(gioco_id)
			result["collectedTreasureIds"] = raccolti
		gameplay.collect_treasure({"rewardFragments": premio}, gioco_id)
		_refresh_economy()
		_spawn_gain_popup("+%d frammenti" % premio, Color("c7b8ff"))
		_set_feedback(str(scheda.get("vittoria", "Fatto.")))
		# La conseguenza compare nello stesso istante della prima vittoria e solo
		# nel luogo di questa persona. Non aspetta un rientro nel mondo.
		_update_building_stages()
	else:
		# Perdere non toglie niente: si e' fermato il tempo, non il percorso.
		_set_feedback("%s (%d su %d)" % [str(scheda.get("sconfitta", "Non stavolta.")), presi, totale])
	_refresh_prompt()

func _minigioco_personaggio_superato(npc_id: String) -> bool:
	return Array(result.get("collectedTreasureIds", [])).has("gioco-%s" % npc_id)

func _on_dialogue_closed(npc_id: String) -> void:
	if is_instance_valid(player):
		player.set_physics_process(true)
	if stance_echo_after_dialogue.has(npc_id):
		var echo_id := str(stance_echo_after_dialogue.get(npc_id, ""))
		stance_echo_after_dialogue.erase(npc_id)
		StanceChoices.segna_eco_vista(game_save.data, echo_id)
		_persist_save()
	if stance_choice_after_dialogue.has(npc_id):
		var choice_id := str(stance_choice_after_dialogue.get(npc_id, ""))
		stance_choice_after_dialogue.erase(npc_id)
		_open_stance_choice(choice_id)
		return
	# Finché il caso profondo è attivo, parlare non lo risolve e non apre il
	# minigioco del personaggio: la sua battuta sostituisce davvero il dialogo.
	if npc_id == thirteenth_deep_forgotten_npc:
		_update_ship_navigation()
		_refresh_prompt()
		return
	# La conta viene registrata PRIMA di aprire il minigioco di Ersilia. Il
	# ritorno anticipato del minigioco la lasciava ascoltata ma mai persistita:
	# al rientro ricominciava da capo, proprio sulla chiave del finale.
	if npc_id == "w01-ersilia" and ersilia_count_pending:
		ersilia_count_pending = false
		var narrative: Dictionary = game_save.data.get("narrative", {})
		narrative["ersiliaCountHeard"] = true
		game_save.data["narrative"] = narrative
		if bool(request.get("loadLocalSave", true)):
			game_save.save()
	if CharacterMinigameCatalog.ha_gioco(npc_id) and not _minigioco_personaggio_superato(npc_id):
		_apri_minigioco_personaggio(npc_id)
		return
	if vera_incrinatura_pending:
		vera_incrinatura_pending = false
		_open_vera_incrinatura_choice()
		return
	if vera_ricucitura_pending:
		# Ha spiegato lei. Non c'è niente da scegliere e niente da guadagnare:
		# l'arco passa allo stadio in cui insegna, e basta.
		vera_ricucitura_pending = false
		VeraArc.registra_ricucitura(game_save.data)
		_persist_save()
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

## **L'arco di Vera.** (13 agosto 2026)
##
## Sta *sopra* «Rispiegamelo», non accanto: stessa persona, stessi incontri, uno
## stadio in più che dipende da quante volte le hai spiegato qualcosa davvero.
## Il perché è in `vera_arc.gd`; qui c'è solo l'ordine di precedenza, che è la
## sola cosa che si poteva sbagliare:
##
## 1. **l'eco** della risposta data all'incrinatura — una volta sola, e prima di
##    tutto, perché è la cosa che dice «ti ho sentita» e invecchia in fretta;
## 2. **l'incrinatura**, che interrompe di proposito «Rispiegamelo»: Vera si
##    rifiuta di farsi spiegare un'altra volta, ed è tutto il punto;
## 3. **la ricucitura**, in cui spiega lei.
##
## Sotto, invariato, quello che c'era: «Rispiegamelo» quando c'è un argomento da
## rispiegare. Il colore non passa mai davanti alla didattica.
func _vera_arc_lines() -> Dictionary:
	var eco := VeraArc.eco(game_save.data)
	if eco != "":
		VeraArc.segna_eco_vista(game_save.data)
		_persist_save()
		return {"lines": [[eco.trim_prefix("Vera:").strip_edges()]], "pool": "eco"}
	if VeraArc.incrinatura_dovuta(game_save.data):
		vera_incrinatura_pending = true
		return {
			"lines": ITINERANT_CATALOG.lines_of("itin-vera", VeraArc.POOL_INCRINATURA),
			"pool": VeraArc.POOL_INCRINATURA,
		}
	if VeraArc.stadio(game_save.data) == VeraArc.STADIO_INCRINATO:
		vera_ricucitura_pending = true
		return {
			"lines": ITINERANT_CATALOG.lines_of("itin-vera", VeraArc.POOL_RICUCITURA),
			"pool": VeraArc.POOL_RICUCITURA,
		}
	return {}

func _persist_save() -> void:
	if bool(request.get("loadLocalSave", true)):
		game_save.save()

## La scelta dell'incrinatura: tre modi di rispondere, nessuno giusto e nessuno
## punito (`stance_audit` lo verifica). Passa dallo stesso pannello di
## «Rispiegamelo» perché è lo stesso gesto — si sceglie una frase — e un secondo
## pannello identico sarebbe solo un altro posto in cui sbagliare i margini.
func _open_vera_incrinatura_choice() -> void:
	_ensure_choice_panel()
	open_choice_kind = "incrinatura"
	if is_instance_valid(player):
		player.set_physics_process(false)
	var scelta := StanceChoices.scelta(VeraArc.SCELTA_ID)
	teaching_choice_panel.call(
		"open_choice", "VERA", str(scelta.get("domanda", "")), scelta.get("opzioni", []))

## Un pannello solo per due scelte diverse: il `choice_made` va smistato qui,
## altrimenti la seconda connessione al segnale farebbe partire tutti e due i
## gestori sulla stessa pressione.
func _ensure_choice_panel() -> void:
	if is_instance_valid(teaching_choice_panel):
		return
	teaching_choice_panel = TEACHING_CHOICE_PANEL_SCRIPT.new()
	teaching_choice_panel.name = "TeachingChoicePanel"
	ui_layer.add_child(teaching_choice_panel)
	teaching_choice_panel.connect("choice_made", _on_choice_panel_made)
	teaching_choice_panel.connect("choice_skipped", _on_choice_panel_skipped)

func _on_choice_panel_made(option_id: String, correct: bool) -> void:
	var kind := open_choice_kind
	open_choice_kind = ""
	if kind == "incrinatura":
		_on_vera_incrinatura_choice(option_id)
	elif kind.begins_with("stance:"):
		_on_stance_choice_made(kind.trim_prefix("stance:"), option_id)
	else:
		_on_vera_teaching_choice(option_id, correct)

func _on_choice_panel_skipped() -> void:
	var kind := open_choice_kind
	open_choice_kind = ""
	if kind.begins_with("stance:"):
		StanceChoices.registra_salto(game_save.data, kind.trim_prefix("stance:"))
		_persist_save()
	if is_instance_valid(player):
		player.set_physics_process(true)
	_refresh_prompt()

func _open_stance_choice(choice_id: String) -> void:
	if not StanceChoices.dovuta(game_save.data, choice_id):
		if is_instance_valid(player):
			player.set_physics_process(true)
		return
	_ensure_choice_panel()
	open_choice_kind = "stance:%s" % choice_id
	if is_instance_valid(player):
		player.set_physics_process(false)
	var choice := StanceChoices.scelta(choice_id)
	teaching_choice_panel.call(
		"open_choice",
		str(choice.get("titolo", "UNA SCELTA")),
		str(choice.get("domanda", "")),
		choice.get("opzioni", []),
		true)
	set_meta("last_stance_choice_opened", choice_id)

func _on_stance_choice_made(choice_id: String, option_id: String) -> void:
	StanceChoices.registra_risposta(game_save.data, choice_id, option_id)
	_persist_save()
	var line := StanceChoices.testo_opzione(choice_id, option_id)
	if line == "":
		if is_instance_valid(player):
			player.set_physics_process(true)
		return
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call(
		"show_dialogue",
		"stance-result-%s" % choice_id,
		"Eli",
		"La scelta resterà nel mondo",
		[line])

func _on_vera_incrinatura_choice(option_id: String) -> void:
	VeraArc.registra_risposta(game_save.data, option_id)
	_persist_save()
	var risposta := ""
	for raw in StanceChoices.opzioni(VeraArc.SCELTA_ID):
		if str((raw as Dictionary).get("id", "")) == option_id:
			risposta = str((raw as Dictionary).get("dice", ""))
	var pages: Array = []
	if risposta != "":
		pages.append("Eli: %s" % risposta)
	var ritorno := ITINERANT_CATALOG.lines_of("itin-vera", VeraArc.POOL_DOPO_LA_SCELTA)
	if not ritorno.is_empty():
		pages.append_array(Array(ritorno[0]))
	if pages.is_empty():
		if is_instance_valid(player):
			player.set_physics_process(true)
		return
	dialogue_box.call("configure_accessibility", high_contrast, reduced_motion)
	dialogue_box.call("show_dialogue", "itin-vera-incrinatura", "Vera", "Nessuna risposta è quella giusta", pages)

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
	_ensure_choice_panel()
	open_choice_kind = "rispiegamelo"
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

# ---------------------------------------------------------------------------
# **I guardiani dei forzieri e il duello.** (7 agosto 2026)
#
# Richiesta del committente: gli Sbiaditi devono essere un pericolo vero,
# devono sorvegliare i bauli, e si devono poter eliminare con un minigioco
# tarato sul progresso del personaggio.
#
# Le tre cose sono una sola meccanica. Prima le sacche pattugliavano il vuoto:
# facevano perdere energia a chi passava di li' per caso, il che e' una tassa,
# non un pericolo. Un pericolo e' qualcosa che sta **fra te e una cosa che
# vuoi** — e allora avvicinarsi diventa una decisione invece che un incidente.
#
# Il minigioco era di riflessi fino al 16 agosto 2026; adesso e' di **calcolo**
# ([[GuardianDuel]]), su richiesta del committente e per una ragione che il
# varco non poteva risolvere: allenarsi a leggere e a contare non rendeva
# nessuno piu' bravo a centrare un cursore.
# ---------------------------------------------------------------------------

## Ogni quanto si controlla se sono comparsi forzieri da sorvegliare. I pezzi di
## mappa entrano ed escono mentre Eli cammina: fare questa scansione a ogni
## fotogramma sarebbe sprecato, farla una volta sola lascerebbe scoperti tutti i
## forzieri caricati dopo.
const GUARDIA_OGNI_MSEC := 900

## **Non tutti i forzieri sono sorvegliati, e non tutti insieme.**
##
## Misurato prima di decidere: mettendo una guardiana su ogni forziere scoperto
## ne comparivano **da otto a quindici in vista contemporaneamente**. Non e' un
## pericolo, e' un assedio — e un assedio non si affronta, si evita, che e'
## esattamente il contrario di quello che serviva.
##
## Quindi due limiti. Uno su QUALI forzieri: circa uno su tre, scelto
## dall'identificativo, quindi sempre lo stesso per lo stesso forziere — un
## premio che a volte e' difeso e a volte no insegnerebbe solo a riprovare. E uno
## su QUANTI ne sono vivi insieme: quattro. Gli altri forzieri restano liberi, e
## la scelta fra prendere quello facile o guadagnarsi quello difeso e' il gioco.
const GUARDIA_UNO_SU := 3
const GUARDIANI_VIVI_MAX := 4
## Quanto lontano dallo spawn comincia il territorio dei guardiani: entrare in un
## mondo e trovarsi una sacca addosso non e' una sfida, e' un'imboscata.
const GUARDIA_DISTANZA_MINIMA := 420.0

## **Le scorte sono state tolte.** (24 agosto 2026)
##
## Dal 19 al 24 agosto attorno a ogni guardiana stava un anello di due sacche di
## scorta: non si sfidavano e non chiudevano niente, servivano a rendere
## l'**avvicinamento** una scelta — lo si paga in energia, oppure lo si attraversa
## di slancio giocando di tempismo.
##
## Tolte su indicazione del committente, e la ragione è la sola che conti in
## questo gioco: **non avevano valore didattico**. Una sacca che morde e respinge
## e basta chiede riflessi e pazienza, non competenza — ed era per giunta la
## popolazione più numerosa della mappa (quattro scorte contro due guardiane nel
## mondo 1), quindi la faccia che il mondo mostrava più spesso era quella di un
## nemico che non si può affrontare. È esattamente la segnalazione arrivata: «i
## combattimenti con i guardiani non partono e quindi non si possono eliminare».
##
## Quello che resta al posto loro: **le pattuglie adesso si sfidano**. Erano
## l'altra popolazione senza gesto, e a differenza delle scorte hanno una ragione
## d'essere che il duello non cancella — girano per il mondo, ti trovano loro, e
## adesso quell'incontro finisce in una prova invece che in un morso.
##
## Lo scatto e lo spintone restano e non perdono il mestiere: una pattuglia
## continua a respingere, e passarle accanto di slancio continua a essere gratis.
## Quello che sparisce è il **pedaggio d'anello**, cioè il solo punto della mappa
## in cui si pagava per avvicinarsi a qualcosa.

var _guardia_prossima_msec := 0
## Le sacche gia' create, per identificativo: senza, ogni giro ne creerebbe
## un'altra sullo stesso forziere.
var _guardiani: Dictionary = {}
var duel_panel: DuelStage

## Mette una guardiana su ogni forziere scoperto e ancora chiuso.
func _assegna_guardiani() -> void:
	var ora := Time.get_ticks_msec()
	if ora < _guardia_prossima_msec:
		return
	_guardia_prossima_msec = ora + GUARDIA_OGNI_MSEC
	if not is_instance_valid(game_save) or chunks == null or chunks.composition == null:
		return
	var raccolti: Array = Array(result.get("collectedTreasureIds", []))
	for nodo in get_tree().get_nodes_in_group("world_interactable"):
		if not (nodo is Area2D) or str(nodo.get_meta("kind", "")) != "treasure":
			continue
		var id := str(nodo.get_meta("id", ""))
		if id.is_empty() or raccolti.has(id):
			continue
		# Uno su tre, deciso dall'identificativo del forziere: stabile fra una
		# partita e l'altra, e diverso da forziere a forziere.
		if posmod(hash(id), GUARDIA_UNO_SU) != 0:
			continue
		var guardia_id := "guardia-%s" % id
		if _guardiani.has(guardia_id):
			# Se la sacca e' stata sciolta il riferimento resta ma non e' piu'
			# valido: non se ne ricrea un'altra, ed e' il punto.
			continue
		if game_save.enemy_defeated(str(world_level), guardia_id):
			continue
		var posto: Vector2 = (nodo as Area2D).global_position
		if posto.distance_to(WorldProfileCatalog.SPAWN) < GUARDIA_DISTANZA_MINIMA:
			continue
		if _guardiani_vivi() >= GUARDIANI_VIVI_MAX:
			# Il tetto vale sui VIVI, non sui creati: scioglierne una fa spazio
			# alla successiva, e la mappa resta popolata senza mai affollarsi.
			return
		var sacca := WORLD_ENEMY_SCRIPT.new()
		sacca.name = "Guardiano_%s" % guardia_id.replace("-", "_")
		var accento := chunks.composition.blended_accent(posto)
		# La guardiana nasce accanto al forziere, non sopra: sopra coprirebbe il
		# forziere e un premio che non si vede non si desidera.
		sacca.setup(self, posto + Vector2(0, -54), world_level, _world_subject(), accento, _guardiani.size())
		sacca.reduced_motion = reduced_motion
		sacca.vista_scala = _vista_delle_sacche()
		# Una sacca nata dopo il richiamo lo eredita: altrimenti le guardiane
		# comparse durante l'ultima traversata sarebbero le uniche distratte.
		sacca.richiamo = _richiamo_attivo
		sacca.set_meta("guardId", guardia_id)
		# Il cartiglio legge il guardId per dire quale duello attende Eli: deve
		# esistere prima di costruire la guardiana, non un fotogramma dopo.
		sacca.sorveglia(id)
		world_layer.add_child(sacca)
		_guardiani[guardia_id] = sacca
		_rendi_sfidabile(sacca)

func _guardiani_vivi() -> int:
	var quante := 0
	for sacca in _guardiani.values():
		if is_instance_valid(sacca):
			quante += 1
	return quante

## La sacca diventa avvicinabile come qualunque altra cosa della mappa: stesso
## gesto, stesso pulsante contestuale. Senza questo si potrebbe solo subirla.
func _rendi_sfidabile(sacca: Node2D) -> void:
	var area := Area2D.new()
	area.name = "EnemyChallenge"
	area.set_meta("kind", "enemy")
	area.set_meta("id", str(sacca.get_meta("guardId", "")))
	# Il punto nasce dinamicamente quando arriva il pezzo di mappa. Dichiarare
	# esplicitamente il filtro evita che un profilo di collisione diverso dal
	# default lasci il guardiano visibile ma senza il gesto "AFFRONTA".
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	area.add_to_group("world_interactable")
	var forma := CollisionShape2D.new()
	var cerchio := CircleShape2D.new()
	cerchio.radius = INTERACTION_DISTANCE
	forma.shape = cerchio
	area.add_child(forma)
	sacca.add_child(area)
	area.body_entered.connect(func(body): on_interactable_entered(area, body))
	area.body_exited.connect(func(body): on_interactable_exited(area, body))
	# Se la guardiana compare mentre Eli è già accanto al forziere, Godot non
	# garantisce un nuovo body_entered per un'area aggiunta a sovrapposizione
	# avvenuta. Registrarla subito rende il duello disponibile anche in quel caso.
	if is_instance_valid(player) and player.global_position.distance_to(area.global_position) <= INTERACTION_DISTANCE:
		if not nearby.has(area):
			nearby.append(area)
		_refresh_prompt()

## La guardiana viva di un forziere, se c'e'.
func _guardiano_di(treasure_id: String) -> Node2D:
	var sacca = _guardiani.get("guardia-%s" % treasure_id, null)
	return sacca as Node2D if is_instance_valid(sacca) else null

## **Il duello.** Si apre il combattimento con le regole calcolate su tre cose:
## il **mondo** (che decide la difficolta' della materia), il grado della sacca e
## il grado di potenza di Eli — l'unico posto in cui la potenza accumulata cambia
## le regole invece del prezzo.
##
## **Due materie** (17 agosto 2026). Ogni guardiano ne chiede una:
##
##   CIFRE  costruisci un numero incatenando colpi ([[GuardianDuel]]);
##   VOCI   porta un verbo alla casella giusta di modo, tempo e persona
##          ([[VerbDuel]]).
##
## Quale tocchi lo decide l'identificativo del guardiano e non il caso del
## momento ([[DuelRules.materia]]): lo stesso guardiano chiede sempre la stessa
## cosa, e il cartiglio sulla mappa lo dice prima che ci si avvicini. Cosi'
## andargli incontro e' una scelta invece che una lotteria — e chi ha perso su
## una voce difficile puo' tornare proprio a quella.
##
## Il seme cambia a ogni sfida: un duello perso e ripreso deve dare numeri e voci
## nuovi, altrimenti la seconda volta non si pensa — si ricorda.
func _sfida_guardiano(sacca: Node2D) -> void:
	if not is_instance_valid(sacca) or is_instance_valid(duel_panel):
		return
	if is_instance_valid(exercise_player) and exercise_player.visible:
		return
	var tier := int(sacca.get("tier"))
	var grado := WorldLight.grado(game_save)
	var materia := DuelRules.materia(str(sacca.get_meta("guardId", "")))
	var regole: Dictionary = {}
	if materia == DuelRules.VOCI:
		regole = VerbDuel.regole(world_level, tier, grado, reduced_motion)
		duel_panel = VerbDuelPanel.new()
		duel_panel.name = "VerbDuelPanel"
	else:
		regole = GuardianDuel.regole(world_level, tier, grado, reduced_motion)
		duel_panel = GuardianDuelPanel.new()
		duel_panel.name = "GuardianDuelPanel"
	duel_panel.risolto.connect(func(vinto: bool, netto: bool): _chiudi_duello(sacca, vinto, netto))
	ui_layer.add_child(duel_panel)
	duel_panel.avvia(regole, str(sacca.get("enemy_name")),
		hash("%s:%d" % [str(sacca.get_meta("guardId", "")), Time.get_ticks_msec()]),
		reduced_motion, high_contrast)
	# Eli si ferma: il duello e' modale, e lasciarla camminare sotto un pannello
	# a tutto schermo la fa finire chissa' dove.
	if is_instance_valid(player):
		player.touch_target = Vector2.INF
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)

func _chiudi_duello(sacca: Node2D, vinto: bool, netto := false) -> void:
	if is_instance_valid(duel_panel):
		duel_panel.queue_free()
		duel_panel = null
	if is_instance_valid(player):
		player.set_physics_process(true)
	if not is_instance_valid(sacca):
		return
	var tier := int(sacca.get("tier"))
	var grado := WorldLight.grado(game_save)
	if vinto:
		var guardia_id := str(sacca.get_meta("guardId", ""))
		if guardia_id != "":
			game_save.mark_enemy_defeated(str(world_level), guardia_id)
		var premio := DuelRules.premio_frammenti(tier)
		gameplay.collect_treasure({"rewardFragments": premio}, "duello-%s" % guardia_id)
		sacca.call("elimina")
		game_save.save()
		_set_feedback("%s Il forziere è libero, e restano %d frammenti sul campo." % [
			DuelRules.riga_di_vittoria(netto), premio])
		_spawn_gain_popup("+%d frammenti" % premio, Color("c7b8ff"))
		_refresh_economy()
		if is_instance_valid(pet_companion):
			pet_companion.react()
	else:
		# **Perdere non chiude niente.** La sacca resta, il forziere resta, si
		# torna quando si e' piu' forti. Il costo e' lo stesso del morso: chi ci
		# prova e sbaglia non deve stare peggio di chi gira alla larga.
		var costo := mini(DuelRules.costo_sconfitta(tier, grado), game_save.energy())
		if costo > 0:
			game_save.spend_energy(costo)
			game_save.save()
			_spawn_gain_popup("−%d" % costo, Color("ff9b8a"))
			_refresh_economy()
		# Un attimo di respiro: senza, la sacca e' addosso a Eli nell'istante in
		# cui il pannello si chiude e il duello ricomincia da solo.
		sacca.call("stun", 2.5)
		_set_feedback("%s%s" % [DuelRules.riga_di_sconfitta(),
			" (−%d energia)" % costo if costo > 0 else ""])
	_refresh_prompt()

func _create_world_enemies() -> void:
	if mission_events.is_empty() or chunks == null or chunks.composition == null:
		return
	var count := clampi(1 + floori(float(world_level - 1) / 6.0), 1, 4)
	var subject := _world_subject()
	for index in range(count):
		# **Una pattuglia battuta non rinasce.** Da quando si sfidano, vincere
		# deve voler dire toglierla di mezzo: ritrovarla al rientro nel mondo
		# renderebbe il duello un pedaggio che si ripaga ogni volta, ed è
		# esattamente la cosa che il duello non deve essere. La guardia sta qui
		# e non dopo, perché costruire la sacca per poi scartarla lascerebbe
		# comunque il suo costo di scena.
		var pattuglia_id := "pattuglia-%d-%d" % [world_level, index]
		if is_instance_valid(game_save) and game_save.enemy_defeated(str(world_level), pattuglia_id):
			continue
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
		enemy.vista_scala = _vista_delle_sacche()
		# **Anche una pattuglia si sfida.** (24 agosto 2026)
		#
		# Fino a oggi il duello stava solo sulle guardiane, cioè sulle sacche
		# **ferme su un forziere**. La pattuglia è quella che ti trova lei: gira,
		# insegue, morde, e non aveva nessun gesto — la si poteva solo subire o
		# scansare. Nel mondo 1 era più della metà delle sacche vive senza duello,
		# ed è la ragione della segnalazione «i combattimenti non partono e non si
		# possono eliminare»: le sacche che il bambino incontrava davvero erano
		# proprio quelle senza combattimento.
		#
		# L'identificativo si dà **prima** di renderla sfidabile: il cartiglio e
		# [[DuelRules.materia]] lo leggono per dire quale prova aspetta Eli, e uno
		# vuoto farebbe annunciare la materia sbagliata.
		#
		# Il guard-rail regge lo stesso: dietro una pattuglia non c'è niente che
		# serva a salire di livello. Vincere dà frammenti, cioè cosmetici, e
		# toglie di mezzo la sacca; perdere costa quanto un morso.
		enemy.set_meta("guardId", pattuglia_id)
		enemy.pattuglia_sfidabile(pattuglia_id)
		world_layer.add_child(enemy)
		_rendi_sfidabile(enemy)

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

## **Le deviazioni.** Quello che il gioco NON ha dichiarato e che si può ancora
## prendere: forzieri e tracce del mistero, cioè frammenti e racconto. Niente che
## serva a salire di livello sta in questo elenco, ed è la riga che rende lecito
## il fiuto — il Custode non ha mai aiutato a progredire e non comincia adesso.
const PET_FIUTO_KINDS := ["treasure", "mystery_trace", "mystery_seed"]

## **Il Custode sente una deviazione e si sporge da quella parte.**
## (19 agosto 2026)
##
## È la metà che risponde alla freccia ristretta (`pet_companion._obiettivo_piu_vicino`).
## La freccia adesso nomina solo gli obiettivi dichiarati; quello che resta fuori
## non torna a essere invisibile, ma **cambia specie di informazione**: non più
## «vai lì», soltanto «da quella parte c'è qualcosa». Nessun nome, nessuna
## distanza, nessuna freccia — il Custode cambia fianco e si sporge, e la scelta
## di deviare resta di chi gioca.
##
## Perché sia meno di prima e non di più: la vecchia freccia puntava a queste
## stesse cose **da qualunque distanza** e diceva anche il punto esatto. Qui il
## raggio è poco più di una schermata (`PET_FIUTO_RAGGIO`) e l'informazione è un
## verso, non una destinazione.
func _pet_check_secret_proximity() -> void:
	if not is_instance_valid(pet_companion) or not is_instance_valid(player):
		return
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		pet_companion.fiuta(Vector2.INF)
		return
	var sentito := _deviazione_piu_vicina()
	pet_companion.fiuta(sentito.get("posizione", Vector2.INF))
	var id := str(sentito.get("id", ""))
	if id.is_empty():
		_pet_fiuto_ultimo = ""
		return
	if id == _pet_fiuto_ultimo:
		return
	# La faccia scatta alla scoperta, una volta per cosa trovata; la sporgenza
	# invece resta finché si è nel raggio. Il volto dice che se n'è accorto, il
	# corpo dice dove: separarli è il motivo per cui questa non è una notifica.
	_pet_fiuto_ultimo = id
	_pet_react("near_secret")

## La deviazione aperta più vicina entro il raggio del fiuto, o un dizionario
## vuoto. I forzieri già raccolti li sa solo la scena, ed è per questo che il
## conto si fa qui e non dentro il Custode.
func _deviazione_piu_vicina() -> Dictionary:
	var raccolti: Array = Array(result.get("collectedTreasureIds", []))
	var migliore: Dictionary = {}
	var distanza := PET_FIUTO_RAGGIO
	for nodo in get_tree().get_nodes_in_group("world_interactable"):
		if not (nodo is Node2D):
			continue
		var area := nodo as Node2D
		if not PET_FIUTO_KINDS.has(str(area.get_meta("kind", ""))):
			continue
		if bool(area.get_meta("completed", false)):
			continue
		var id := str(area.get_meta("id", ""))
		if id.is_empty() or raccolti.has(id):
			continue
		var quanto := player.global_position.distance_to(area.global_position)
		if quanto < distanza:
			distanza = quanto
			migliore = {"id": id, "posizione": area.global_position}
	return migliore

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
	# **Il varco dello scatto.** (19 agosto 2026) Chi passa di slancio non paga e
	# non viene respinto: ci si passa attraverso. È l'unico momento del gioco in
	# cui il tempismo vale quanto il grado, ed è lecito perché dietro una sacca
	# non c'è mai niente che serva a progredire.
	#
	# La sacca ha già consumato la propria finestra di morso (`_on_body_entered`
	# la segna prima di chiamarci): per il secondo dopo un attraversamento
	# riuscito quella sacca non morde. È un vantaggio, ed è voluto — è la
	# ricompensa del tempismo, e dura un secondo.
	if player.sta_scattando():
		if not _scatto_varco_raccontato:
			_scatto_varco_raccontato = true
			_set_feedback("Ci sei passata attraverso. Di slancio le sacche non ti toccano.")
		_pet_react("near_faded")
		return
	var away := enemy.global_position.direction_to(player.global_position)
	if away.length_squared() < 0.01:
		away = Vector2.DOWN
	# Quanto lontano butta lo spintone: la zavorra da campo lo accorcia, e non
	# lo azzera mai — una sacca che non sposta piu' nessuno smette di essere
	# l'ostacolo che rende una sacca una sacca.
	var spinta := float(runtime.get("knockbackDistance", ExpeditionModules.SPINTA_PIENA))
	var target := chunks.clamp_to_world(player.global_position + away * spinta)
	if _water_blocks_position(target):
		target = last_traversable_position
	player.global_position = target
	player.velocity = Vector2.ZERO
	player.touch_target = Vector2.INF
	last_traversable_position = target
	# **Il morso.** La sacca costa energia solo per quanto supera il grado di
	# Eli: chi si e' allenato passa senza pagare, ed e' il motivo per cui la
	# barra della potenza esiste. Non blocca mai — se l'energia non basta si
	# paga quel che c'e' e si passa lo stesso.
	var grado_sacca := int(enemy.get("tier"))
	var grado_eli := WorldLight.grado(game_save)
	var scarto := maxi(0, grado_sacca - grado_eli)
	var costo := mini(scarto * WorldEnemy.COSTO_PER_GRADO, game_save.energy())
	if costo > 0:
		game_save.spend_energy(costo)
		game_save.save()
		_spawn_gain_popup("−%d" % costo, Color("ff9b8a"))
		_set_feedback("%s ti respinge. −%d energia: è più forte di te di %d gradi. Allenati, oppure passale accanto di slancio." % [
			str(enemy.get("enemy_name")), costo, scarto])
	else:
		_set_feedback("%s ti respinge, ma non ti scalfisce: sei abbastanza forte." % str(enemy.get("enemy_name")))
	if is_instance_valid(player_presentation):
		if reduced_motion:
			player_presentation.modulate = Color.WHITE
			return
		var tween := create_tween()
		tween.tween_property(player_presentation, "modulate", Color(1.0, 0.46, 0.42), 0.08)
		tween.tween_property(player_presentation, "modulate", Color.WHITE, 0.22)

## **Lo scatto.** (19 agosto 2026)
##
## Il secondo verbo del corpo di Eli, e il primo che non finisce in un pannello.
## Le regole stanno tutte in [[OutdoorPlayerController]]: qui c'è solo il gesto —
## chi lo chiede, la scia che lascia, e il pulsante che dice quando torna.
##
## Non costa niente e non concede niente. Il balzo è movimento, e l'unica cosa
## che apre è il passaggio attraverso una sacca — che sta davanti ai frammenti,
## mai davanti a una prova.
func _scatto() -> void:
	if not is_instance_valid(player) or not enemy_gameplay_active():
		return
	if not player.scatta():
		return
	_spawn_scia_di_scatto()
	_update_scatto_button()

## Dito giù sul pulsante: parte il balzo **e** comincia la corsa. Sono lo stesso
## gesto perché sono la stessa idea — parti di slancio e prosegui — e perché un
## quarto bottone in fondo allo schermo lo si sarebbe pagato in leggibilità.
func _scatto_premuto() -> void:
	_scatto()
	if is_instance_valid(player):
		player.corsa_richiesta = true

func _scatto_rilasciato() -> void:
	if is_instance_valid(player):
		player.corsa_richiesta = false

## La scia: quattro sagome che restano indietro e svaniscono. Serve a far leggere
## il balzo come un gesto invece che come uno scatto di velocità — senza, a due
## decimi di secondo, Eli sembra semplicemente teletrasportata di un passo.
func _spawn_scia_di_scatto() -> void:
	if reduced_motion or not is_instance_valid(player):
		return
	var scia := Node2D.new()
	scia.name = "EliScattoScia"
	scia.z_index = 6
	var verso := player.scatto_direzione()
	var lunghezza := float(runtime.get("dashDistance", ExpeditionModules.SCATTO_DISTANZA))
	for indice in range(4):
		var quanto := lunghezza * (float(indice) + 1.0) / 5.0
		scia.add_child(OutdoorVisualFactory.make_polygon(
			OutdoorVisualFactory.ellipse_polygon(13.0, 19.0, 16),
			Color(0.42, 0.91, 0.84, 0.34 - float(indice) * 0.06),
			verso * quanto))
	scia.position = player.global_position
	world_layer.add_child(scia)
	var tween := create_tween()
	tween.tween_property(scia, "modulate:a", 0.0, 0.28)
	tween.tween_callback(scia.queue_free)

func _update_scatto_button() -> void:
	if not is_instance_valid(scatto_button) or not is_instance_valid(player):
		return
	var attesa := int(player.scatto_attesa_msec())
	scatto_button.disabled = attesa > 0 or not enemy_gameplay_active()
	if scatto_button.disabled:
		# Un pannello aperto mentre il dito era giù lascerebbe Eli a correre da
		# sola sotto la finestra: il rilascio non arriva mai su un bottone spento.
		player.corsa_richiesta = false
	# Il pulsante dice tutte e due le cose, e la corsa per prima: su tablet questa
	# è anche l'unica corsa che esista.
	scatto_button.text = "CORRI\n%.1f s" % (float(attesa) / 1000.0) if attesa > 0 else "CORRI\nTOCCA = BALZO"

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

## **L'insegna di una palestra.** (21 agosto 2026)
##
## Era un disco verde-azzurro uguale per tutte le undici materie, con una
## stella disegnata **come carattere di testo**: `"★"`, cioe' U+2605.
##
## Due difetti in una riga sola, e il secondo e' quello che si vede giocando:
##
## 1. **il carattere non esiste nel font imbarcato.** Il progetto non ha un
##    font suo e usa Open Sans SemiBold, che di quel simbolo non ha il glifo.
##    Su Windows Godot ripiega sui font di sistema e la stella si vede; nel
##    Web e su tablet quel ripiego non c'e', e il motore disegna il rettangolo
##    col codice dentro. Le palestre portavano **«2605» come insegna**, ed e'
##    la segnalazione da cui nasce questa riscrittura;
## 2. **erano tutte uguali.** Undici materie, un disco solo: da lontano non si
##    poteva decidere dove andare, e la scelta di che cosa allenare — che e' la
##    scelta piu' importante che questo gioco offra — si prendeva solo dopo
##    essersi avvicinati a leggere l'etichetta.
##
## Adesso l'insegna e' **disegnata** (nessun glifo, nessun ripiego possibile) e
## porta il **colore della materia** da [[SubjectPalette]] — lo stesso con cui
## il mondo di quella materia tinge la notte e con cui la sua scheda si accende
## nel nucleo prismatico della nave. Il verde della geografia e' lo stesso in
## tutti e tre i posti, e si riconosce da lontano senza leggere niente.
func _make_practice_repeater(subject: String, completed: bool) -> Node2D:
	var marker := Node2D.new()
	marker.name = "PracticeRepeater"
	var tint := SubjectPalette.colore(subject)
	marker.add_child(OutdoorVisualFactory.make_shadow(28, 8, 0.30, 8))
	var stone := Polygon2D.new()
	stone.name = "FirstRepeaterStone"
	stone.polygon = PackedVector2Array([Vector2(-22, 6), Vector2(-15, -42), Vector2(0, -56), Vector2(15, -42), Vector2(22, 6)])
	stone.color = Color.WHITE if high_contrast else Color("4a515c")
	marker.add_child(stone)
	var core := OutdoorVisualFactory.make_ring(15.0, tint if completed else Color("8a929a"), 2.2, 16)
	core.name = "RepeaterCore"
	core.position = Vector2(0, -25)
	marker.add_child(core)
	if completed:
		var glow := OutdoorVisualFactory.make_glow(28.0, tint, 0.62)
		glow.position = core.position
		glow.add_to_group("night_glow")
		marker.add_child(glow)
	return marker


func _make_minigame_marker(subject: String) -> Node2D:
	var marker := Node2D.new()
	marker.name = "MinigameMarker"
	var tinta := SubjectPalette.colore(subject)
	# L'alone: dice «qui c'e' qualcosa» prima che la forma sia leggibile.
	marker.add_child(OutdoorVisualFactory.make_glow(46.0, tinta, 0.20))
	var disco := Polygon2D.new()
	disco.name = "PracticeDisc"
	var punti := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		punti.append(Vector2(cos(a), sin(a)) * 30.0)
	disco.polygon = punti
	disco.color = Color(tinta.darkened(0.72), 0.94)
	marker.add_child(disco)
	marker.add_child(OutdoorVisualFactory.make_ring(30.0, tinta, 2.4, 28))
	# La stella a cinque punte, disegnata: dieci vertici alternati fra il
	# raggio pieno e il raggio interno. E' la stessa forma di prima, ma adesso
	# e' geometria e non una speranza sul font di chi gioca.
	var stella := Polygon2D.new()
	stella.name = "PracticeStar"
	var vertici := PackedVector2Array()
	for i in range(10):
		var raggio := 16.0 if i % 2 == 0 else 6.6
		var angolo := -PI * 0.5 + TAU * float(i) / 10.0
		vertici.append(Vector2(cos(angolo), sin(angolo)) * raggio)
	stella.polygon = vertici
	stella.color = tinta.lightened(0.28)
	marker.add_child(stella)
	return marker

func _rebuild_practice_circuit() -> void:
	var old := get_node_or_null("PracticeCircuit")
	if old != null:
		old.queue_free()
	var circuit := Node2D.new()
	circuit.name = "PracticeCircuit"
	add_child(circuit)
	var completed: Array = result.get("completedEncounterIds", [])
	var stations: Array[Dictionary] = []
	for event_data in mission_events:
		var event: Dictionary = event_data
		if str(event.get("kind", "")) == "practice":
			stations.append(event)
	for index in range(1, stations.size()):
		var previous: Dictionary = stations[index - 1]
		var current: Dictionary = stations[index]
		if not completed.has(str(previous.get("id", ""))) or not completed.has(str(current.get("id", ""))):
			continue
		var line := Line2D.new()
		line.name = "PracticeCircuitLink"
		line.points = PackedVector2Array([previous.get("position", Vector2.ZERO), current.get("position", Vector2.ZERO)])
		line.width = 5.0
		line.default_color = Color(SubjectPalette.colore(str(current.get("subject", "matematica"))), 0.78)
		line.z_index = -1
		circuit.add_child(line)


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
	diary_panel = DIARY_PANEL_SCRIPT.new()
	diary_panel.setup(game_save, high_contrast)
	diary_panel.panel_closed.connect(_on_diary_closed)
	ui_layer.add_child(diary_panel)

func _panel_style() -> StyleBox:
	return SURFACE_STYLES.ship(high_contrast)

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

## La barra della potenza nell'HUD: il traguardo di medio periodo sempre in
## vista. Senza, il grado si scoprirebbe solo quando arriva, e una ricompensa
## che non si vede avvicinare non tira.
func _crea_barra_potenza(genitore: Control) -> void:
	var scatola := VBoxContainer.new()
	scatola.name = "PowerBox"
	scatola.add_theme_constant_override("separation", 2)

	etichetta_potenza = Label.new()
	etichetta_potenza.name = "PowerLabel"
	etichetta_potenza.add_theme_font_size_override("font_size", 11)
	etichetta_potenza.add_theme_color_override("font_color", Color("cfe6e2"))
	scatola.add_child(etichetta_potenza)

	barra_potenza = ProgressBar.new()
	barra_potenza.name = "PowerBar"
	barra_potenza.show_percentage = false
	barra_potenza.custom_minimum_size = Vector2(150, 8)
	scatola.add_child(barra_potenza)

	genitore.add_child(scatola)
	_aggiorna_barra_potenza()

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
	# **«E adesso che faccio?»** (7 agosto 2026)
	#
	# Segnalazione del committente: bisogna spiegare meglio che cosa fare e che
	# cosa manca per il mondo successivo. La risposta breve sta nell'etichetta
	# qui sopra; questo pulsante apre quella lunga — le dodici materie con
	# quanto manca a ciascuna.
	#
	# Sta accanto all'obiettivo e non in un menu: la domanda nasce guardando
	# l'obiettivo, e la risposta deve stare a un dito di distanza.
	objective_button = Button.new()
	objective_button.name = "OpenObjectiveButton"
	objective_button.text = "CHE COSA DEVO FARE?"
	objective_button.custom_minimum_size = Vector2(0, 40)
	objective_button.add_theme_font_size_override("font_size", 13)
	objective_button.pressed.connect(_apri_obiettivi)
	info.add_child(objective_button)
	_crea_barra_potenza(info)
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
	# **La pausa sta fuori da OPZIONI, e non e' un dettaglio di layout.**
	# (21 agosto 2026) Le voci del menu utilita' sono cose che si fanno *dentro*
	# il gioco — la bottega, il manuale, il diario. Smettere, ricominciare e
	# passare il tablet a un altro bambino sono cose che si fanno *al* gioco, e
	# chi le cerca non sa che si chiamano «opzioni»: cerca il tasto per fermare.
	pause_button = Button.new()
	pause_button.name = "OpenPauseMenuButton"
	pause_button.text = "PAUSA"
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.offset_left = -148.0
	pause_button.offset_right = -16.0
	pause_button.offset_top = 68.0
	pause_button.offset_bottom = 114.0
	pause_button.custom_minimum_size.y = 46
	pause_button.add_theme_color_override("font_color", Color("f4cf69"))
	pause_button.pressed.connect(_apri_pausa)
	root.add_child(pause_button)
	utility_menu_button = Button.new()
	utility_menu_button.name = "OpenUtilityMenuButton"
	utility_menu_button.text = "OPZIONI"
	utility_menu_button.anchor_left = 1.0
	utility_menu_button.anchor_right = 1.0
	utility_menu_button.offset_left = -148.0
	utility_menu_button.offset_right = -16.0
	utility_menu_button.offset_top = 120.0
	utility_menu_button.offset_bottom = 166.0
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
	scatto_button = Button.new()
	scatto_button.name = "ScattoButton"
	# **Prima diceva «SCATTO / TIENI = CORRI».** (21 agosto 2026) Metteva per
	# primo il verbo che si usa meno: il balzo serve davanti a una sacca, la
	# corsa serve sempre — e su tablet questo pulsante è l'unica corsa che
	# esista, perché `sprint` è legato al solo Maiusc. Adesso l'etichetta dice
	# prima la cosa che si fa cento volte, e poi quella che si fa dieci.
	scatto_button.text = "CORRI\nTOCCA = BALZO"
	scatto_button.anchor_left = 1.0
	scatto_button.anchor_right = 1.0
	scatto_button.anchor_top = 1.0
	scatto_button.anchor_bottom = 1.0
	scatto_button.tooltip_text = "Tienilo premuto per correre · toccalo per un balzo che attraversa le sacche"
	scatto_button.add_theme_font_size_override("font_size", 13)
	scatto_button.add_theme_color_override("font_color", Color("06272a"))
	scatto_button.add_theme_stylebox_override("normal", _touch_action_style(Color("9ad8ff"), Color("e2f4ff")))
	scatto_button.add_theme_stylebox_override("pressed", _touch_action_style(Color("6be7d6"), Color("d8fff8")))
	scatto_button.add_theme_stylebox_override("disabled", _touch_action_style(Color("36505e"), Color("6d8794")))
	# `pressed` scatta al rilascio: per un balzo è tardi, e chi tiene premuto per
	# correre non vuole un balzo quando alza il dito. `button_down` è il gesto.
	scatto_button.button_down.connect(_scatto_premuto)
	scatto_button.button_up.connect(_scatto_rilasciato)
	root.add_child(scatto_button)
	shop_button = Button.new()
	shop_button.name = "OpenShopButton"
	shop_button.text = "BOTTEGA"
	shop_button.anchor_left = 1.0
	shop_button.anchor_right = 1.0
	shop_button.offset_left = -132.0
	shop_button.offset_right = -16.0
	shop_button.offset_top = 172.0
	shop_button.offset_bottom = 216.0
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
	manual_button.offset_top = 220.0
	manual_button.offset_bottom = 266.0
	manual_button.custom_minimum_size.y = 46
	manual_button.add_theme_color_override("font_color", Color("6be7d6"))
	manual_button.pressed.connect(_open_codex)
	manual_button.visible = false
	root.add_child(manual_button)
	diary_button = Button.new()
	diary_button.name = "OpenDiaryButton"
	diary_button.text = "DIARIO"
	diary_button.anchor_left = 1.0
	diary_button.anchor_right = 1.0
	diary_button.offset_left = -164.0
	diary_button.offset_right = -16.0
	diary_button.offset_top = 320.0
	diary_button.offset_bottom = 366.0
	diary_button.custom_minimum_size.y = 46
	diary_button.add_theme_color_override("font_color", Color("f6c85f"))
	diary_button.pressed.connect(_open_diary)
	diary_button.visible = false
	root.add_child(diary_button)
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
	touch_controls_button.offset_top = 270.0
	touch_controls_button.offset_bottom = 316.0
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
	touch_controls_panel.offset_top = 172.0
	touch_controls_panel.offset_bottom = 500.0
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
	if not is_instance_valid(interaction_button) or not is_instance_valid(scatto_button):
		return
	var on_left := str(touch_controls_settings.get("side", "right")) == "left"
	var is_large := str(touch_controls_settings.get("size", "large")) == "large"
	var margin := 28.0
	var action_width := 332.0 if is_large else 280.0
	var action_height := 72.0 if is_large else 64.0
	var lato_corsa := 92.0 if is_large else 76.0
	var lower_hud_clearance := 116.0
	interaction_button.anchor_left = 0.5
	interaction_button.anchor_right = 0.5
	interaction_button.anchor_top = 1.0
	interaction_button.anchor_bottom = 1.0
	interaction_button.offset_left = -action_width * 0.5
	interaction_button.offset_right = action_width * 0.5
	interaction_button.offset_top = -lower_hud_clearance - action_height
	interaction_button.offset_bottom = -lower_hud_clearance
	interaction_button.custom_minimum_size = Vector2(action_width, action_height)
	interaction_button.add_theme_font_size_override("font_size", 18 if is_large else 15)
	var opacity := float(touch_controls_settings.get("opacity", 1.0))
	interaction_button.modulate.a = opacity
	# **La corsa prende il posto che era dell'impulso.** (21 agosto 2026) Erano
	# due pulsanti in colonna sopra AZIONE; l'impulso non c'è più e la corsa
	# scende al primo posto, che è anche quello più vicino al pollice. Il senso
	# della preferenza «destra o sinistra» resta lo stesso: tutte le azioni sotto
	# lo stesso dito.
	if is_instance_valid(scatto_button):
		# **Il riquadro segue la scritta.** (21 agosto 2026) Con una larghezza
		# fissa di 92 il pulsante misurava 127 — la seconda riga non ci stava e
		# Godot lo faceva crescere da solo, verso i due lati: sette pixel
		# finivano **fuori dallo schermo**, cioe' fuori dal bersaglio del dito.
		# Difetto vecchio quanto lo scatto, e visibile solo misurando il rect.
		var larghezza_corsa := maxf(lato_corsa, _larghezza_del_testo(scatto_button) + 22.0)
		scatto_button.anchor_left = 0.0 if on_left else 1.0
		scatto_button.anchor_right = 0.0 if on_left else 1.0
		scatto_button.anchor_top = 1.0
		scatto_button.anchor_bottom = 1.0
		if on_left:
			scatto_button.offset_left = margin
			scatto_button.offset_right = margin + larghezza_corsa
		else:
			scatto_button.offset_left = -margin - larghezza_corsa
			scatto_button.offset_right = -margin
		scatto_button.offset_top = -lower_hud_clearance - action_height - 16.0 - lato_corsa
		scatto_button.offset_bottom = -lower_hud_clearance - action_height - 16.0
		scatto_button.custom_minimum_size = Vector2(larghezza_corsa, lato_corsa)
		scatto_button.add_theme_font_size_override("font_size", 13 if is_large else 10)
		scatto_button.modulate.a = opacity
	_refresh_touch_controls_labels()

## Quanto e' larga la riga piu' lunga di un pulsante, con il suo font e il suo
## corpo. Serve a dare al riquadro la misura della scritta invece di sperare
## che ci stia: quando non ci sta, Godot allarga il Control da solo e la parte
## che cresce puo' finire oltre il bordo dello schermo.
func _larghezza_del_testo(bottone: Button) -> float:
	var font := bottone.get_theme_font("font")
	var corpo := bottone.get_theme_font_size("font_size")
	if font == null:
		return 0.0
	var larga := 0.0
	for riga in str(bottone.text).split("\n"):
		larga = maxf(larga, font.get_string_size(
			str(riga), HORIZONTAL_ALIGNMENT_CENTER, -1, corpo).x)
	return larga

func _refresh_touch_controls_labels() -> void:
	if is_instance_valid(touch_side_button):
		touch_side_button.text = "COMANDI: %s" % ("SINISTRA" if str(touch_controls_settings["side"]) == "left" else "DESTRA")
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
	if is_instance_valid(diary_button):
		diary_button.visible = value
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
	# Il bordo dei comandi si ispessisce col contrasto elevato (`_touch_action_style`):
	# senza questo blocco la corsa sarebbe l'unico comando a non accorgersene.
	if is_instance_valid(scatto_button):
		scatto_button.add_theme_stylebox_override(
			"normal", _touch_action_style(Color("9ad8ff"), Color("e2f4ff")))
		scatto_button.add_theme_stylebox_override(
			"pressed", _touch_action_style(Color("6be7d6"), Color("d8fff8")))
		scatto_button.add_theme_stylebox_override(
			"disabled", _touch_action_style(Color("36505e"), Color("6d8794")))
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

## **Il velo non misura piu' il lavoro fatto.** (20 agosto 2026)
##
## Dal 7 agosto il mondo nasceva coperto e ogni prova ne scopriva un pezzo: e'
## stata la risposta giusta al difetto che il collaudo aveva misurato — l'unico
## momento in cui il gioco cambiava era l'esame, a mezz'ora di distanza — ma
## teneva occupata la **luminosita' della scena**, che e' il posto dove sta
## scritto che ora e'. Finche' la teneva occupata, il tempo non poteva tornare a
## passare.
##
## L'avanzamento adesso accende fuochi, uno per prova ([[WorldAwakening]]): sono
## oggetti in punti precisi, non un livello di luce. Il velo resta, ma solo come
## strumento di REGIA — il momento del buio e quello della marea lo alzano e lo
## riabbassano per pochi secondi — e all'ingresso di un mondo e' sempre a zero.
##
## `NEBBIA_MASSIMA` non e' piu' la nebbia di un mondo appena aperto: e' il tetto
## che un momento d'autore non puo' superare. Sopra i due terzi la mappa diventa
## illeggibile, e un mondo illeggibile e' un ostacolo travestito da atmosfera.
const NEBBIA_MASSIMA := 0.66

var velo_nebbia: ColorRect
var barra_potenza: ProgressBar
var etichetta_potenza: Label

func _crea_velo_di_nebbia() -> void:
	if not is_instance_valid(game_save) or not is_instance_valid(atmosphere_layer):
		return
	velo_nebbia = ColorRect.new()
	velo_nebbia.name = "FogVeil"
	velo_nebbia.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo_nebbia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo_nebbia.color = Color(0.05, 0.07, 0.11, 0.0)
	atmosphere_layer.add_child(velo_nebbia)
	_aggiorna_nebbia(1.0, false)

func _world_id_scena() -> String:
	return str(world_level)

# --- I fuochi del risveglio ---------------------------------------------------
#
## **Una prova, un fuoco.** (20 agosto 2026, [[WorldAwakening]])
##
## Il posto dove si vede che il lavoro fatto ha cambiato qualcosa. Dodici fuochi
## per mondo, quante sono le prove che lo risvegliano, ognuno appoggiato a
## qualcosa che nel mondo c'e' gia': una casa, un punto d'interesse, il landmark.
## Non sono arredamento sparso — un fuoco in mezzo al nulla direbbe soltanto «qui
## c'e' un fuoco», mentre uno accanto alla casa di qualcuno dice che quella casa
## si e' svegliata.
##
## Perche' il PIU' VICINO a Eli e non il prossimo di una lista: il velo cambiava
## dappertutto, e quindi in nessun posto in particolare. Chi esce da un pannello
## di esercizi deve poter riportare lo sguardo nel mondo e trovare la cosa nuova
## senza cercarla.
var _fuochi: Array[Node2D] = []

func _crea_i_fuochi_del_risveglio() -> void:
	if not is_instance_valid(game_save):
		return
	# Il fuoco prende il colore della materia del mondo, schiarito: deve leggersi
	# come fiamma anche su un accento freddo come quello di coding o inglese.
	var accento := OutdoorVisualFactory.hex_color(_profile_accent_rgb()).lerp(Color("ffd79a"), 0.45)
	var ancore := _ancore_del_risveglio()
	for indice in range(WorldAwakening.FUOCHI):
		var fuoco := WorldAwakeningFire.new()
		fuoco.configure(accento, reduced_motion)
		fuoco.position = ancore[indice]
		fuoco.add_to_group("fuoco_del_risveglio")
		world_layer.add_child(fuoco)
		_fuochi.append(fuoco)
	# I fuochi gia' guadagnati sono accesi dal primo fotogramma, e senza
	# animazione: una parata di dodici accensioni all'ingresso celebrerebbe un
	# lavoro che nessuno ha appena fatto.
	var gia_accesi := WorldAwakening.allinea(
		game_save, _world_id_scena(), WorldLight.prove_nel_mondo(game_save, _world_id_scena()))
	for indice in gia_accesi:
		var i := int(indice)
		if i >= 0 and i < _fuochi.size():
			(_fuochi[i] as WorldAwakeningFire).accendi(false)

## Dodici punti, presi da cio' che il mondo ha gia' costruito e **il piu'
## lontani possibile fra loro**.
##
## La prima versione prendeva le ancore a passo regolare da un elenco ordinato:
## sembrava ragionevole e ha prodotto due fuochi a ottantacinque unita' l'uno
## dall'altro — meno di mezzo secondo di cammino, cioe' un fuoco solo con una
## fiamma in piu'. `world_awakening_audit` l'ha misurato prima che lo vedesse un
## bambino.
##
## Adesso i posti si scelgono uno per volta prendendo ogni volta quello **piu'
## lontano da tutti i gia' scelti**. E' il modo piu' semplice di dire «sparsi» a
## una macchina, ed e' deterministico: due ingressi nello stesso mondo danno gli
## stessi dodici posti, o i fuochi guadagnati si sposterebbero da una sessione
## all'altra.
func _ancore_del_risveglio() -> Array[Vector2]:
	var candidate: Array[Vector2] = []
	for building in world_buildings:
		if is_instance_valid(building):
			candidate.append(_posto_del_fuoco(building.position))
	for nodo in get_tree().get_nodes_in_group("world_interactable"):
		var area := nodo as Node2D
		if is_instance_valid(area):
			candidate.append(_posto_del_fuoco(area.position))
	if is_instance_valid(profile_hero_landmark):
		candidate.append(_posto_del_fuoco(profile_hero_landmark.position))

	# Se il mondo avesse meno ancore dei fuochi — non succede con diciotto punti
	# d'interesse, ma un mondo futuro potrebbe essere piu' spoglio — si completa
	# con un anello attorno allo spawn, largo abbastanza da non ammucchiarsi.
	var base: Vector2 = world_profile.get("spawn", PORTAL_POSITION)
	var riempimento := 0
	while candidate.size() < WorldAwakening.FUOCHI:
		var angolo := float(riempimento) * 2.39996323
		candidate.append(chunks.clamp_to_world(base + Vector2.RIGHT.rotated(angolo) * (420.0 + 130.0 * float(riempimento % 3))))
		riempimento += 1

	candidate.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.y < b.y if not is_equal_approx(a.y, b.y) else a.x < b.x)

	var out: Array[Vector2] = []
	# Si parte dal piu' lontano dallo spawn: il primo fuoco della partita non
	# deve cadere addosso al portale da cui si e' appena entrati.
	var primo := 0
	var piu_lontano := -1.0
	for indice in range(candidate.size()):
		var quanto := base.distance_squared_to(candidate[indice])
		if quanto > piu_lontano:
			piu_lontano = quanto
			primo = indice
	out.append(candidate[primo])
	var presi: Dictionary = {primo: true}
	while out.size() < WorldAwakening.FUOCHI:
		var migliore := -1
		var migliore_distanza := -1.0
		for indice in range(candidate.size()):
			if presi.has(indice):
				continue
			var minima := INF
			for scelto in out:
				minima = minf(minima, candidate[indice].distance_squared_to(scelto))
			if minima > migliore_distanza:
				migliore_distanza = minima
				migliore = indice
		if migliore < 0:
			break
		presi[migliore] = true
		out.append(candidate[migliore])
	return out

## Il fuoco sta ACCANTO alla cosa a cui appartiene, non sopra. La direzione la
## decide la posizione dell'ancora: cosi' resta la stessa a ogni ingresso senza
## bisogno di ricordarsela, e due ancore vicine non scelgono lo stesso lato.
func _posto_del_fuoco(ancora: Vector2) -> Vector2:
	var angolo := fposmod(ancora.x * 0.0131 + ancora.y * 0.0197, TAU)
	return chunks.clamp_to_world(ancora + Vector2.RIGHT.rotated(angolo) * 86.0)

## Una prova superata: si accende il fuoco spento piu' vicino a Eli.
##
## Ritorna l'indice acceso, oppure -1 se erano gia' tutti accesi — succede
## quando si continua a giocare in un mondo gia' risvegliato, e non e' un errore:
## il mondo ha finito di cambiare molto prima dell'esame, apposta.
func _risveglia_il_fuoco_piu_vicino() -> int:
	if not is_instance_valid(player) or _fuochi.is_empty():
		return -1
	var migliore := -1
	var distanza := INF
	for indice in range(_fuochi.size()):
		var fuoco := _fuochi[indice] as WorldAwakeningFire
		if not is_instance_valid(fuoco) or fuoco.acceso:
			continue
		var quanto := player.global_position.distance_squared_to(fuoco.global_position)
		if quanto < distanza:
			distanza = quanto
			migliore = indice
	if migliore < 0:
		return -1
	if not WorldAwakening.accendi(game_save, _world_id_scena(), migliore):
		return -1
	(_fuochi[migliore] as WorldAwakeningFire).accendi(true)
	return migliore

func _aggiorna_nebbia(luce: float, animata: bool) -> void:
	if not is_instance_valid(velo_nebbia):
		return
	var alfa := NEBBIA_MASSIMA * (1.0 - clampf(luce, 0.0, 1.0))
	var meta := Color(0.05, 0.07, 0.11, alfa)
	if animata and not reduced_motion:
		var tween := create_tween()
		tween.tween_property(velo_nebbia, "color", meta, 0.7).set_trans(Tween.TRANS_SINE)
	else:
		velo_nebbia.color = meta

## Una prova e' andata bene: il mondo si scopre, la barra sale, e se il grado e'
## cambiato lo si dice. Tre ricompense diverse su tre orizzonti diversi —
## immediata, di sessione, di partita.
## **IL MOMENTO D'AUTORE.** (19 agosto 2026, [[WorldSetPiece]])
##
## Sei in tutta la campagna, agganciati ai colpi di scena. Scattano quando il
## mondo è scoperto a metà — a lavoro cominciato, quando il posto è già
## familiare — e durano al massimo quaranta secondi.
##
## Qui c'è solo la regia: che cosa dicono e quando stanno lo decide il catalogo.
## Nessuno dei sei toglie qualcosa a chi gioca; la riga è nel catalogo e vale
## quanto le altre.
var _luce_corrente := 0.0
var _momento_in_corso := ""

func _prova_il_momento(luce: float) -> void:
	if luce < WorldSetPiece.LUCE_DI_INNESCO or _momento_in_corso != "":
		return
	var momento := WorldSetPiece.momento(world_level)
	if momento.is_empty() or not is_instance_valid(game_save):
		return
	if not game_save.claim_set_piece(str(momento["id"])):
		return
	game_save.save()
	_momento_in_corso = str(momento["id"])
	_apri_il_momento(momento)

func _apri_il_momento(momento: Dictionary) -> void:
	_set_nora_feedback(str(momento.get("apertura", "")))
	match str(momento.get("forma", "")):
		WorldSetPiece.BRANCO:
			_momento_branco()
		WorldSetPiece.BUIO:
			_momento_buio()
		WorldSetPiece.SCRITTA:
			_momento_scritta(str(momento.get("parola", "FERMATI")))
		WorldSetPiece.ECO:
			_momento_eco(str(momento.get("eco", "")))
		WorldSetPiece.MAREA:
			_momento_marea()
		WorldSetPiece.CONVERGENZA:
			_momento_convergenza()
	await get_tree().create_timer(float(momento.get("durata", 20.0))).timeout
	_chiudi_il_momento(momento)

func _chiudi_il_momento(momento: Dictionary) -> void:
	match str(momento.get("forma", "")):
		WorldSetPiece.BRANCO:
			for enemy in get_tree().get_nodes_in_group("world_enemy"):
				if is_instance_valid(enemy):
					enemy.set("caccia", false)
		WorldSetPiece.BUIO, WorldSetPiece.MAREA:
			# Torna PULITO. Fino al 20 agosto qui si tornava al livello delle
			# prove, perche' il velo misurava quelle: adesso il velo e' solo
			# regia, e restituirgli il numero dell'avanzamento lascerebbe addosso
			# al mondo una nebbia che nessuno ha piu' motivo di vedere.
			_aggiorna_nebbia(1.0, true)
		WorldSetPiece.CONVERGENZA:
			_momento_convergenza_attiva = false
	var chiusura := str(momento.get("chiusura", "")).strip_edges()
	if chiusura != "":
		_set_nora_feedback(chiusura)
	_momento_in_corso = ""

## **Il branco.** Tutte le sacche si voltano insieme. Il morso non cambia di
## un'energia: cambia che per sedici secondi il mondo ti sta dietro.
func _momento_branco() -> void:
	for enemy in get_tree().get_nodes_in_group("world_enemy"):
		if is_instance_valid(enemy):
			enemy.set("caccia", true)

## **Il buio.** La luce crolla, e la torcia diventa l'unica cosa che conta. È il
## primo momento in cui avere il Custode e avere un attrezzo cambiano che cosa
## si vede, invece di che cosa si può aprire.
func _momento_buio() -> void:
	_aggiorna_nebbia(0.12, true)

## **La scritta.** Il Tredicesimo lascia una parola su un'insegna, senza
## spiegazione e senza minaccia. Non si può leggere meglio avvicinandosi e non si
## può interagire: è lì, e basta.
func _momento_scritta(parola: String) -> void:
	if not is_instance_valid(player):
		return
	var insegna := Node2D.new()
	insegna.name = "MomentoScritta"
	insegna.position = player.global_position + Vector2(0, -200)
	insegna.z_index = 60
	insegna.add_child(OutdoorVisualFactory.make_polygon(
		PackedVector2Array([
			Vector2(-118, -44), Vector2(118, -44), Vector2(118, 32), Vector2(-118, 32),
		]), Color(0.08, 0.07, 0.09, 0.92)))
	var testo := Label.new()
	testo.name = "MomentoScrittaTesto"
	testo.text = parola
	testo.position = Vector2(-118, -34)
	testo.custom_minimum_size = Vector2(236, 56)
	testo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	testo.add_theme_font_size_override("font_size", 40)
	testo.add_theme_constant_override("outline_size", 8)
	testo.add_theme_color_override("font_color", Color("ff9b8a"))
	testo.accessibility_name = "Un'insegna con una parola scritta di fresco: %s" % parola
	insegna.add_child(testo)
	world_layer.add_child(insegna)
	insegna.modulate.a = 0.0
	if reduced_motion:
		insegna.modulate.a = 1.0
	else:
		var tween := create_tween()
		tween.tween_property(insegna, "modulate:a", 1.0, 1.6)
	get_tree().create_timer(21.0).timeout.connect(func():
		if is_instance_valid(insegna):
			insegna.queue_free())

## **L'eco.** Una sacca si ferma e ripete una frase che NORA ha detto. Nessuna
## spiegazione adesso — al colpo di scena, quel ricordo torna.
func _momento_eco(frase: String) -> void:
	var vicina: Node2D = null
	var distanza := INF
	for enemy in get_tree().get_nodes_in_group("world_enemy"):
		if not (enemy is Node2D) or not is_instance_valid(player):
			continue
		var quanto: float = player.global_position.distance_to((enemy as Node2D).global_position)
		if quanto < distanza:
			distanza = quanto
			vicina = enemy as Node2D
	if vicina == null:
		# Nessuna sacca in vista: la frase arriva lo stesso, da nessuna parte, ed
		# è persino peggio. Un momento d'autore non si perde per una posizione.
		_set_feedback(frase)
		return
	vicina.call("stun", 20.0)
	var voce := Label.new()
	voce.name = "MomentoEco"
	voce.text = frase
	voce.position = Vector2(-190, -132)
	voce.custom_minimum_size = Vector2(380, 44)
	voce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voce.add_theme_font_size_override("font_size", 17)
	voce.add_theme_constant_override("outline_size", 7)
	voce.add_theme_color_override("font_color", Color("d8f3ff"))
	voce.accessibility_name = "Una sacca di Silenzio ripete: %s" % frase
	vicina.add_child(voce)
	_pet_react("sister_found")
	get_tree().create_timer(19.0).timeout.connect(func():
		if is_instance_valid(voce):
			voce.queue_free())

## **La marea.** Il velo si alza e si riabbassa tre volte: la mappa si legge a
## intermittenza, e non c'è niente da fare se non aspettare.
func _momento_marea() -> void:
	for giro in range(3):
		if _momento_in_corso == "":
			return
		_aggiorna_nebbia(0.18, true)
		await get_tree().create_timer(4.0).timeout
		_aggiorna_nebbia(1.0, true)
		await get_tree().create_timer(4.0).timeout

## **La convergenza.** Gli abitanti smettono di lavorare e si radunano. È lo
## stesso stato del richiamo — la regia della vita lo conosce già — e qui dura
## diciotto secondi invece che fino all'uscita dal mondo.
var _momento_convergenza_attiva := false

func _momento_convergenza() -> void:
	_momento_convergenza_attiva = true

func _on_world_light_changed(luce: float, grado: int, salito: bool) -> void:
	_luce_corrente = luce
	# **Il fuoco, non la nebbia.** (20 agosto 2026) Qui si alzava il velo di un
	# dodicesimo. Adesso si accende un oggetto: la ricompensa e' rimasta
	# immediata e ha smesso di occupare la luminosita' della scena, che da oggi
	# dice soltanto che ora e' ([[WorldSky]]).
	_risveglia_il_fuoco_piu_vicino()
	_sync_profile_environment_transform(true)
	_prova_il_momento(luce)
	_reveal_pending_minimissions()
	_aggiorna_barra_potenza()
	_applica_grado_al_personaggio(grado)
	if salito:
		_pet_react("power_grade_up")
		var scheda := WorldLight.scheda_grado(game_save)
		_set_feedback("Sei salita a %s. La luce che porti adesso arriva piu' lontano." % str(scheda.get("nome", "")))
		_spawn_gain_popup(str(scheda.get("nome", "")).to_upper(), Color(str(scheda.get("colore", "8ff6d2"))))
	elif luce < 1.0:
		# «+luce» era il nome giusto finche' la ricompensa era il velo che si
		# alzava. Adesso quello che succede e' che un fuoco si accende, e la
		# scritta deve dire quella cosa li' — e' l'unica riga che il bambino
		# legge nel momento esatto in cui il mondo cambia.
		_spawn_gain_popup("+fuoco", Color("ffd79a"))

func _reveal_pending_minimissions() -> void:
	for node in get_tree().get_nodes_in_group("pending_minimission_reveal"):
		if not (node is Area2D) or not is_ancestor_of(node):
			continue
		var area := node as Area2D
		area.remove_from_group("pending_minimission_reveal")
		area.visible = true
		area.monitoring = true
		area.monitorable = true
		area.scale = Vector2.ONE
		area.modulate = Color.WHITE
		if not reduced_motion:
			area.scale = Vector2.ONE * 0.28
			area.modulate.a = 0.0
			var reveal := create_tween().set_parallel(true)
			reveal.tween_property(area, "scale", Vector2.ONE, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			reveal.tween_property(area, "modulate:a", 1.0, 0.30)
		_spawn_touch_ping(area.global_position)

## Il grado si vede addosso a Eli: un alone che cambia colore e cresce.
##
## E' l'unica ricompensa puramente estetica del gioco che non si compra — si
## guadagna facendo prove, e per questo dice qualcosa di vero su chi la porta.
func _applica_grado_al_personaggio(grado: int) -> void:
	if not is_instance_valid(player):
		return
	grado = clampi(grado, 0, WorldLight.SOGLIE.size() - 1)
	var scheda := WorldLight.scheda_grado(game_save)
	var sprite := player.find_child("EliSprite", true, false) as Sprite2D
	if sprite != null and sprite.texture is AtlasTexture:
		(sprite.texture as AtlasTexture).atlas = OutdoorVisualFactory.player_sheet_for_tier(grado)
	var alone := player.get_node_or_null("PowerAura") as Node2D
	if alone == null:
		var nuovo := Line2D.new()
		nuovo.name = "PowerAura"
		nuovo.width = 4.0
		nuovo.closed = true
		for indice in range(19):
			nuovo.add_point(Vector2.RIGHT.rotated(TAU * float(indice) / 18.0) * 26.0)
		nuovo.z_index = -1
		player.add_child(nuovo)
		alone = nuovo
	var linea := alone as Line2D
	linea.default_color = Color(str(scheda.get("colore", "8ff6d2")))
	linea.default_color.a = 0.20 + 0.14 * float(grado)
	linea.scale = Vector2.ONE * (1.0 + 0.13 * float(grado))
	linea.visible = grado > 0
	linea.width = 3.0 + float(grado) * 0.8
	_configura_orbita_potenza("PowerOrbitInner", 32.0, grado >= 3, grado, false)
	_configura_orbita_potenza("PowerOrbitOuter", 39.0, grado >= 4, grado, true)
	_configura_orbita_potenza("PowerOrbitZenith", 46.0, grado >= 5, grado, false)
	_configura_orbita_potenza("PowerOrbitCrown", 53.0, grado >= 6, grado, true)
	_configura_orbita_potenza("PowerOrbitPrism", 60.0, grado >= 7, grado, false)
	_configura_orbita_potenza("PowerOrbitHeart", 67.0, grado >= 8, grado, true)
	_configura_particelle_potenza(grado)
	applied_power_grade = grado
	if is_instance_valid(game_save):
		_aggiorna_stato_energia(game_save.energy(), false)

func _configura_orbita_potenza(nome: String, raggio: float, visibile: bool, grado: int, inversa: bool) -> void:
	var orbit := player.get_node_or_null(nome) as Line2D
	if orbit == null:
		orbit = Line2D.new()
		orbit.name = nome
		orbit.closed = true
		orbit.width = 2.0
		for indice in range(25):
			var punto := Vector2.RIGHT.rotated(TAU * float(indice) / 24.0) * raggio
			punto.y *= 0.46
			orbit.add_point(punto)
		orbit.position.y = -4.0
		orbit.z_index = -1
		player.add_child(orbit)
	orbit.default_color = Color(str(WorldLight.SOGLIE[grado].get("colore", "8ff6d2")), 0.52)
	orbit.visible = visibile
	orbit.set_meta("spin", (-1.0 if inversa else 1.0) * (0.25 + 0.08 * float(grado)))

func _configura_particelle_potenza(grado: int) -> void:
	var particles := player.get_node_or_null("EliPowerParticles") as CPUParticles2D
	if particles == null:
		particles = CPUParticles2D.new()
		particles.name = "EliPowerParticles"
		particles.position = Vector2(0, -22)
		particles.z_index = 2
		particles.lifetime = 1.5
		particles.randomness = 0.8
		particles.direction = Vector2.UP
		particles.spread = 180.0
		particles.gravity = Vector2(0, -8)
		particles.initial_velocity_min = 5.0
		particles.initial_velocity_max = 16.0
		particles.scale_amount_min = 0.65
		particles.scale_amount_max = 1.35
		player.add_child(particles)
	particles.amount = 4 + grado * 3
	particles.color = Color(str(WorldLight.SOGLIE[grado].get("colore", "8ff6d2")), 0.72)
	particles.emitting = grado >= 2 and not reduced_motion

func _aggiorna_stato_energia(energia: int, celebra: bool = true) -> void:
	if not is_instance_valid(player) or not is_instance_valid(player_presentation):
		return
	var precedente := last_energy_visual
	last_energy_visual = maxi(0, energia)
	# L'energia non ha un cap: una curva saturante rende 0 chiaramente scarico e
	# continua a crescere senza far dipendere l'estetica da un massimo inventato.
	var intensita := float(last_energy_visual) / (float(last_energy_visual) + 75.0)
	var core := player.find_child("EliCoreGlow", true, false) as CanvasItem
	if core != null:
		core.modulate.a = 0.18 + intensita * 0.82
		core.scale = Vector2.ONE * (0.78 + intensita * 0.34)
	var aura_base := player.find_child("PlayerBaseAura", true, false) as CanvasItem
	if aura_base != null:
		aura_base.modulate.a = 0.28 + intensita * 0.72
	var particles := player.get_node_or_null("EliPowerParticles") as CPUParticles2D
	if particles != null:
		particles.emitting = applied_power_grade >= 2 and last_energy_visual > 0 and not reduced_motion
		particles.amount = maxi(1, 3 + applied_power_grade * 2 + roundi(intensita * 7.0))
	if not celebra or precedente < 0 or precedente == last_energy_visual:
		return
	if reduced_motion:
		player_presentation.modulate = Color.WHITE
		return
	var flash := Color("baffea") if last_energy_visual > precedente else Color("ff9b8a")
	var tween := create_tween()
	tween.tween_property(player_presentation, "modulate", flash, 0.09)
	tween.tween_property(player_presentation, "modulate", Color.WHITE, 0.28)

func _aggiorna_barra_potenza() -> void:
	if not is_instance_valid(barra_potenza) or not is_instance_valid(game_save):
		return
	var stato := WorldLight.verso_il_prossimo(game_save)
	var scheda := WorldLight.scheda_grado(game_save)
	if bool(stato.get("completo", false)):
		barra_potenza.max_value = 1.0
		barra_potenza.value = 1.0
		etichetta_potenza.text = "%s · al massimo" % str(scheda.get("nome", ""))
		return
	barra_potenza.max_value = float(maxi(1, int(stato.get("servono", 1))))
	barra_potenza.value = float(stato.get("fatte", 0))
	# La barra dice sempre quanto manca: una barra che non lo dice e' una
	# decorazione, e il bambino non sa se conviene fare un'altra prova adesso.
	etichetta_potenza.text = "%s · %d prove a %s" % [
		str(scheda.get("nome", "")), int(stato.get("mancano", 0)), str(stato.get("prossimo", ""))]

## **La camera chiusa.** (7 agosto 2026)
##
## L'unico posto del gioco in cui una zona e' **davvero inaccessibile**, e si puo'
## fare per una ragione precisa: **dentro non c'e' niente che serva a
## progredire**. Il rischio del vicolo cieco — quello che tiene gli sbarramenti
## a forma di segmento aggirabile — qui non esiste, perche' chi non entra
## finisce il gioco lo stesso.
##
## Dentro c'e' il tesoro speciale del mondo e la **pergamena dei Dodici**:
## l'altro lato della storia, scritto quattrocento anni prima da chi c'era.
## NORA deduce, i Dodici testimoniano — e chi esplora ottiene la meta' che il
## resto del gioco non racconta.
##
## Si apre con la **serratura**, una prova dedicata della materia del mondo, a
## costo d'ingresso pieno: e' un premio, e un premio che non costa niente non e'
## un premio.
const CAMERA_RAGGIO := 190.0
const CAMERA_MURI := 16

func _crea_camera_chiusa() -> void:
	if not is_instance_valid(game_save) or chunks == null or chunks.composition == null:
		return
	if not ParchmentCatalog.esiste(world_level):
		return
	if game_save.has_parchment(world_level):
		return   # gia' aperta: la camera resta aperta per sempre

	var centro := _posizione_camera()
	if centro == Vector2.ZERO:
		return

	var nodo := Node2D.new()
	nodo.name = "CameraChiusa"
	nodo.position = centro
	nodo.add_to_group("world_vault")
	world_layer.add_child(nodo)

	# L'anello: chiuso davvero, con un solo punto — la serratura — che lo apre.
	var corpo := StaticBody2D.new()
	corpo.name = "VaultWall"
	for indice in range(CAMERA_MURI):
		var angolo := TAU * float(indice) / float(CAMERA_MURI)
		var forma := CollisionShape2D.new()
		var cerchio := CircleShape2D.new()
		cerchio.radius = 42.0
		forma.shape = cerchio
		forma.position = Vector2.RIGHT.rotated(angolo) * CAMERA_RAGGIO
		corpo.add_child(forma)
	nodo.add_child(corpo)

	var anello := Line2D.new()
	anello.name = "VaultArt"
	anello.width = 20.0
	anello.default_color = Color(0.42, 0.34, 0.52, 0.95)
	anello.closed = true
	for indice in range(CAMERA_MURI + 1):
		anello.add_point(Vector2.RIGHT.rotated(TAU * float(indice) / float(CAMERA_MURI)) * CAMERA_RAGGIO)
	nodo.add_child(anello)

	# La serratura: si tocca da FUORI, quindi sta sul bordo.
	var serratura := Area2D.new()
	serratura.name = "VaultLock"
	serratura.position = Vector2.DOWN * CAMERA_RAGGIO
	serratura.set_meta("kind", "vault_lock")
	serratura.set_meta("id", "camera-%d" % world_level)
	var sforma := CollisionShape2D.new()
	var scerchio := CircleShape2D.new()
	scerchio.radius = INTERACTION_DISTANCE
	sforma.shape = scerchio
	serratura.add_child(sforma)
	serratura.add_to_group("world_interactable")
	var glifo := Label.new()
	glifo.text = "* CAMERA SIGILLATA"
	glifo.add_theme_font_size_override("font_size", 13)
	glifo.add_theme_color_override("font_color", Color("d9c8ff"))
	glifo.position = Vector2(-70, -46)
	serratura.add_child(glifo)
	nodo.add_child(serratura)
	serratura.body_entered.connect(func(body): on_interactable_entered(serratura, body))
	serratura.body_exited.connect(func(body): on_interactable_exited(serratura, body))

## Un punto lontano dai POI e dall'acqua: la camera non deve inghiottire un
## incontro del gate, perche' quello si', chiuderebbe la strada.
func _posizione_camera() -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("camera-%d" % world_level)
	for _tentativo in range(24):
		var angolo := rng.randf() * TAU
		var raggio := rng.randf_range(900.0, 1700.0)
		var punto := chunks.clamp_to_world(
			WorldProfileCatalog.SPAWN + Vector2.RIGHT.rotated(angolo) * raggio)
		if chunks.composition.is_protected(punto, CAMERA_RAGGIO + 80.0):
			continue
		if chunks.composition.raw_water_weight(punto) >= 0.35:
			continue
		var libero := true
		for evento in mission_events:
			var pos: Vector2 = Dictionary(evento).get("position", Vector2.ZERO)
			if pos.distance_to(punto) < CAMERA_RAGGIO + 160.0:
				libero = false
				break
		if libero:
			return punto
	return Vector2.ZERO

## La serratura: una prova dedicata della materia del mondo.
func _apri_camera() -> void:
	if not is_instance_valid(gameplay) or gameplay.session_active():
		return
	var subject := _world_subject()
	var payload := {"subject": subject}
	var formats := MinigameManager.runtime_formats_for(subject, world_level)
	if not formats.is_empty():
		payload["format"] = formats[posmod(world_level + 1, formats.size())]
	if gameplay.try_start_minigame(payload, "serratura-%d" % world_level):
		_set_feedback("La serratura chiede la materia di questo mondo. Aprila.")

## Superata la serratura: l'anello cade, la pergamena si legge, il tesoro e' preso.
func _sciogli_camera() -> void:
	if not is_instance_valid(game_save) or not game_save.claim_parchment(world_level):
		return
	for nodo in get_tree().get_nodes_in_group("world_vault"):
		nodo.queue_free()
	if is_instance_valid(gameplay):
		gameplay.collect_treasure({"rewardFragments": FragmentEconomy.PREMIO_CAMERA}, "camera-%d" % world_level)
	game_save.save()
	_mostra_pergamena()

## La pergamena ha un pannello suo, e non la riga di feedback dell'HUD.
##
## In quella riga finiva il briefing dei mondi, e lì veniva sostituito dal
## primo messaggio successivo: è un difetto già commesso una volta in questo
## progetto, e la pergamena è il testo più denso che il gioco consegni fuori da
## una lezione. Eli si ferma mentre si legge, come alla soglia di un mondo.
func _mostra_pergamena() -> void:
	if not ParchmentCatalog.esiste(world_level) or not is_instance_valid(ui_layer):
		return
	var pannello := ParchmentPanel.new()
	pannello.name = "ParchmentPanel"
	pannello.livello = world_level
	pannello.trovate = game_save.parchment_count()
	pannello.totali = ApparatusConfig.MAX_LEVEL
	pannello.high_contrast = high_contrast
	pannello.chiusa.connect(func():
		if is_instance_valid(pannello):
			pannello.queue_free()
		if is_instance_valid(player):
			player.set_physics_process(true))
	ui_layer.add_child(pannello)
	if is_instance_valid(player):
		player.set_physics_process(false)

## **Gli sbarramenti di terra.** (7 agosto 2026)
##
## Diciotto mondi su ventiquattro non hanno torrenti, quindi non avevano nessun
## passaggio da aprire: la prova che apre fisicamente la mappa viveva in sei
## mondi. La composizione ora vi mette una frana, un cancello o una parete, con
## la stessa struttura dati del guado — e l'enigma ci si aggancia senza che
## nessuna riga a monte cambi.
##
## **Il muro e' un segmento, non un anello**: si puo' sempre girargli attorno.
## Aprirlo e' una scorciatoia, non un permesso. E' l'unico modo di rispettare la
## regola di tutta la mappa — niente che sta qui puo' fermare la progressione —
## perche' un muro che chiude davvero rischierebbe di isolare un POI del gate, e
## quel difetto lo scoprirebbe un bambino, non un audit.
func _crea_sbarramenti() -> void:
	if chunks == null or chunks.composition == null:
		return
	var chiusi: Array = Array(result.get("completedEncounterIds", []))
	for voce in chunks.composition.crossings:
		var barriera: Dictionary = voce
		if str(barriera.get("kind", "")) != "barrier":
			continue
		var evento := str(barriera.get("eventId", ""))
		if evento != "" and chiusi.has(evento):
			continue   # gia' aperto: la scorciatoia resta aperta per sempre
		world_layer.add_child(_costruisci_sbarramento(barriera))

func _costruisci_sbarramento(barriera: Dictionary) -> Node2D:
	var nodo := Node2D.new()
	nodo.name = "Sbarramento_%s" % str(barriera.get("id", "x")).replace("-", "_")
	nodo.position = barriera.get("position", Vector2.ZERO)
	nodo.add_to_group("world_barrier")
	nodo.set_meta("eventId", str(barriera.get("eventId", "")))

	var tangente: Vector2 = barriera.get("tangent", Vector2.RIGHT)
	var meta_larghezza := float(barriera.get("halfWidth", 150.0))

	# Il muro: cerchi in fila lungo la tangente, come fa gia' il blocco d'erba
	# dell'EquipmentGate. Piu' semplice di un rettangolo ruotato, e il giocatore
	# vede dove finisce.
	var corpo := StaticBody2D.new()
	corpo.name = "BarrierBody"
	var passi := 7
	for indice in range(passi):
		var t_lineare := -1.0 + 2.0 * float(indice) / float(passi - 1)
		var forma := CollisionShape2D.new()
		var cerchio := CircleShape2D.new()
		cerchio.radius = 34.0
		forma.shape = cerchio
		forma.position = tangente * (t_lineare * meta_larghezza)
		corpo.add_child(forma)
	nodo.add_child(corpo)

	var disegno := Line2D.new()
	disegno.name = "BarrierArt"
	disegno.width = 26.0
	disegno.default_color = Color(0.36, 0.30, 0.26, 0.95)
	disegno.add_point(tangente * -meta_larghezza)
	disegno.add_point(tangente * meta_larghezza)
	nodo.add_child(disegno)

	var etichetta := Label.new()
	etichetta.name = "BarrierLabel"
	etichetta.text = str(barriera.get("label", "lo sbarramento")).to_upper()
	etichetta.add_theme_font_size_override("font_size", 13)
	etichetta.add_theme_color_override("font_color", Color("ffd7a8"))
	etichetta.position = Vector2(-60, -56)
	nodo.add_child(etichetta)
	return nodo

## Quando la prova legata a uno sbarramento e' superata, il muro se ne va.
func _apri_sbarramento(event_id: String) -> void:
	if event_id == "":
		return
	for nodo in get_tree().get_nodes_in_group("world_barrier"):
		if str(nodo.get_meta("eventId", "")) == event_id:
			_set_feedback("Il passaggio si apre: da qui si accorcia.")
			nodo.queue_free()
			return

## **Gli hazard.** (6 agosto 2026)
##
## `clearedHazardIds` stava nel salvataggio dal primo giorno e la parola
## «hazard» compariva in tutto l'albero degli script **una volta sola**: li'.
## Nessuno li creava, nessuno li leggeva — quarto campo di questa specie.
##
## Un hazard e' un tratto che costa energia ad attraversare, e si «pulisce» una
## volta sola: pagato il pedaggio, quella strada resta aperta per sempre. Non
## blocca mai — si attraversa anche a zero energia — perche' vale la regola di
## tutta la mappa: **niente che sta qui puo' fermare la progressione**.
const HAZARD_COSTO := 2
const HAZARD_PER_MONDO := 3

func _crea_hazard() -> void:
	if not is_instance_valid(game_save) or not is_instance_valid(chunks):
		return
	var puliti: Array = Array(
		game_save.world_progress(str(world_level)).get("clearedHazardIds", []))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("hazard-%d" % world_level)
	for indice in range(HAZARD_PER_MONDO):
		var id := "hazard-%d-%d" % [world_level, indice]
		if puliti.has(id):
			continue
		# **Si RIPROVA invece di arrendersi.** Misurato su tutti e ventiquattro i
		# mondi: con un solo tentativo, otto mondi ne ricevevano meno di tre e
		# due ne ricevevano uno. Il numero di pericoli dipendeva da dove cadeva
		# il primo dado, cioe' da niente. E' lo stesso schema che il
		# piazzamento dei nemici usa gia' da tempo, dieci righe piu' su.
		var posizione := Vector2.ZERO
		var trovata := false
		for tentativo in range(12):
			var angolo := rng.randf() * TAU
			var raggio := rng.randf_range(600.0, 1500.0)
			posizione = chunks.clamp_to_world(
				WorldProfileCatalog.SPAWN + Vector2.RIGHT.rotated(angolo) * raggio)
			if chunks.composition.is_protected(posizione, 60.0):
				continue
			if chunks.composition.raw_water_weight(posizione) >= 0.4:
				continue
			trovata = true
			break
		if not trovata:
			continue
		var area := Area2D.new()
		area.name = "Hazard_%d" % indice
		area.position = posizione
		area.set_meta("kind", "hazard")
		area.set_meta("id", id)
		area.set_meta("payload", {"cost": HAZARD_COSTO})
		var forma := CollisionShape2D.new()
		var cerchio := CircleShape2D.new()
		cerchio.radius = INTERACTION_DISTANCE
		forma.shape = cerchio
		area.add_child(forma)
		area.add_to_group("world_interactable")
		area.add_child(_make_hazard_marker())
		world_layer.add_child(area)
		area.body_entered.connect(func(body): on_interactable_entered(area, body))
		area.body_exited.connect(func(body): on_interactable_exited(area, body))

## **LE TANE.** (19 agosto 2026, [[PetErrand]])
##
## Due per mondo, e sono la prima cosa della mappa che non apre un pannello: si
## preme e si guarda il proprio compagno andare. Vedi `_manda_il_custode`.
const TANE_PER_MONDO := 2

func _crea_tane() -> void:
	if not is_instance_valid(game_save) or not is_instance_valid(chunks) or chunks.composition == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("tana-%d" % world_level)
	for indice in range(TANE_PER_MONDO):
		var id := "tana-%d-%d" % [world_level, indice]
		if game_save.tana_svuotata(str(world_level), id):
			continue
		var posizione := Vector2.ZERO
		var trovata := false
		for tentativo in range(12):
			var angolo := rng.randf() * TAU
			var raggio := rng.randf_range(520.0, 1400.0)
			posizione = chunks.clamp_to_world(
				WorldProfileCatalog.SPAWN + Vector2.RIGHT.rotated(angolo) * raggio)
			if chunks.composition.is_protected(posizione, 60.0):
				continue
			if chunks.composition.raw_water_weight(posizione) >= 0.4:
				continue
			trovata = true
			break
		if not trovata:
			continue
		var area := Area2D.new()
		area.name = "Tana_%d" % indice
		area.position = posizione
		area.set_meta("kind", "tana")
		area.set_meta("id", id)
		area.set_meta("payload", {"descrizione": PetErrand.descrizione_di(id)})
		var forma := CollisionShape2D.new()
		var cerchio := CircleShape2D.new()
		cerchio.radius = INTERACTION_DISTANCE
		forma.shape = cerchio
		area.add_child(forma)
		area.add_to_group("world_interactable")
		area.add_child(_make_tana_marker())
		world_layer.add_child(area)
		area.body_entered.connect(func(body): on_interactable_entered(area, body))
		area.body_exited.connect(func(body): on_interactable_exited(area, body))

## Il segno della tana: un'apertura scura sotto una sporgenza, e l'erba pettinata
## di chi ci entra e ne esce. Nessun luccichio e nessuna promessa — quello che si
## va a prendere non è il contenuto.
func _make_tana_marker() -> Node2D:
	var marker := Node2D.new()
	marker.name = "TanaMarker"
	marker.add_child(OutdoorVisualFactory.make_shadow(30.0, 11.0, 0.5, 14.0))
	marker.add_child(OutdoorVisualFactory.make_polygon(
		PackedVector2Array([
			Vector2(-30, 12), Vector2(-22, -16), Vector2(0, -26),
			Vector2(22, -16), Vector2(30, 12),
		]), Color(0.30, 0.28, 0.26, 0.96)))
	# Il buco: nero pieno, che è l'unica cosa che dice «qui non ci passi».
	marker.add_child(OutdoorVisualFactory.make_polygon(
		OutdoorVisualFactory.ellipse_polygon(13.0, 11.0, 18),
		Color(0.02, 0.03, 0.04, 0.98), Vector2(0, 2)))
	for filo in range(7):
		var linea := Line2D.new()
		linea.name = "ErbaPettinata_%d" % filo
		linea.width = 2.0
		linea.default_color = Color(0.42, 0.58, 0.32, 0.8)
		var x := -26.0 + float(filo) * 8.5
		linea.points = PackedVector2Array([Vector2(x, 14), Vector2(x + 5.0, 6.0)])
		marker.add_child(linea)
	var etichetta := Label.new()
	etichetta.name = "TanaLabel"
	etichetta.text = "TANA"
	etichetta.position = Vector2(-52, 20)
	etichetta.custom_minimum_size.x = 104
	etichetta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta.add_theme_font_size_override("font_size", 11)
	etichetta.add_theme_constant_override("outline_size", 5)
	etichetta.add_theme_color_override("font_color", Color("d8f3ff"))
	etichetta.accessibility_name = "Tana: ci entra il Custode, non Eli"
	marker.add_child(etichetta)
	return marker

## **Si preme, e non si apre niente.**
##
## Il Custode si stacca dal fianco di Eli, ci va, sparisce dentro, e dopo qualche
## secondo esce. È l'unica interazione del gioco in cui chi gioca non fa altro
## che guardare — ed è il motivo per cui esiste: tutte e dodici le altre cose
## della mappa finivano in un pannello.
func _manda_il_custode(target: Area2D) -> void:
	var id := str(target.get_meta("id", ""))
	if not is_instance_valid(game_save) or not PetState.is_granted(game_save):
		_set_feedback(PetErrand.SENZA_CUSTODE)
		return
	if not is_instance_valid(pet_companion) or _tana_in_corso != "":
		return
	_tana_in_corso = id
	pet_companion.manda_a(target.global_position)
	_set_nora_feedback(PetErrand.riga_di_partenza(PetState.name_of(game_save)))
	_pet_react("near_unexplored")
	# Da qui in avanti è una scena: si aspetta che arrivi, poi che esca.
	var atteso := 0.0
	while not pet_companion.arrivato() and atteso < 6.0:
		await get_tree().process_frame
		atteso += get_process_delta_time()
		if not is_instance_valid(pet_companion) or not is_instance_valid(target):
			_tana_in_corso = ""
			return
	pet_companion.entra()
	await get_tree().create_timer(PetErrand.DURATA).timeout
	if not is_instance_valid(pet_companion):
		_tana_in_corso = ""
		return
	pet_companion.torna()
	_risolvi_tana(target, id)
	_tana_in_corso = ""

## Che cosa ha riportato. Mai energia, mai padronanza, mai un pezzo di gate: dalle
## tane escono soltanto frammenti e regali, cioè cose che non servono a imparare.
## È la stessa linea che rende lecito il duello davanti a un forziere.
func _risolvi_tana(target: Area2D, id: String) -> void:
	game_save.mark_tana_svuotata(str(world_level), id)
	match PetErrand.esito_di(id):
		"frammenti":
			gameplay.collect_treasure({"rewardFragments": PetErrand.FRAMMENTI}, "tana-%s" % id)
			_spawn_gain_popup("+%d frammenti" % PetErrand.FRAMMENTI, Color("c7b8ff"))
			_refresh_economy()
			_set_feedback("Esce trascinando qualcosa che luccica. +%d frammenti." % PetErrand.FRAMMENTI)
			_pet_react("mission_complete")
		"regalo":
			# Un regalo dalla tana è lo stesso oggetto inutile di sempre
			# ([[PetGifts]]): un sasso, una vite storta. Non vale niente per
			# contratto, ed è il motivo per cui è il premio giusto — chi torna
			# da una spedizione porta qualcosa, e quel qualcosa è un sasso.
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%s:regalo" % id)
			var gift_id := PetGifts.pick(rng)
			var voce := PetState.register_gift(game_save, gift_id, world_level)
			_pet_react("antic")
			if voce.is_empty():
				# Ne aveva già uno uguale: lo riporta lo stesso, ed è più buffo.
				_set_feedback("Esce con qualcosa in bocca. Ne ha già uno identico.")
			else:
				_set_nora_feedback(_nora_gift_line(gift_id, PetState.gifts(game_save).size()))
		_:
			_set_feedback(PetErrand.barbina_di(id))
			_set_nora_feedback(PetErrand.appunto_di(id))
			_pet_react("antic")
	game_save.save()
	# La tana si chiude: svuotata resta svuotata, e la gag non si farma.
	nearby.erase(target)
	var contenitore := target
	if is_instance_valid(contenitore):
		contenitore.queue_free()
	_refresh_prompt()

## L'identificativo della tana attualmente in corso, vuoto se nessuna: due
## spedizioni insieme spezzerebbero la scena e il Custode è uno solo.
var _tana_in_corso := ""

func _make_hazard_marker() -> Node2D:
	var nodo := Node2D.new()
	nodo.name = "HazardMarker"
	var glifo := Label.new()
	glifo.text = "!"
	glifo.add_theme_font_size_override("font_size", 30)
	glifo.add_theme_color_override("font_color", Color("ffb35c"))
	glifo.position = Vector2(-10, -34)
	nodo.add_child(glifo)
	return nodo

## Sgombrare un hazard: si paga una volta e la strada resta aperta.
func _sgombra_hazard(target: Area2D) -> void:
	var id := str(target.get_meta("id", ""))
	var costo := int(Dictionary(target.get_meta("payload", {})).get("cost", HAZARD_COSTO))
	var pagato := mini(costo, game_save.energy())
	if pagato > 0:
		game_save.spend_energy(pagato)
	game_save.mark_hazard_cleared(str(world_level), id)
	game_save.save()
	_set_feedback("Passaggio sgombrato%s. Da qui si passa, e non costerà di nuovo." % (
		" (−%d energia)" % pagato if pagato > 0 else ""))
	target.queue_free()

## Entrare in un edificio. Tre ruoli, tre cose diverse.
func _entra_nell_edificio(target: Area2D) -> void:
	var payload: Dictionary = target.get_meta("payload", {})
	var ruolo := str(payload.get("role", ""))
	var nome := str(payload.get("label", "questo posto"))
	match ruolo:
		"ritrovo":
			# La bottega vive qui, non piu' in un pulsante dell'HUD: si compra
			# dove la gente si incontra. E si puo' anche LAVORARE: e' l'unico
			# posto del gioco in cui una prova paga invece di costare.
			if is_instance_valid(gameplay) and game_save.energy() < OutdoorGameplay.EXERCISE_ENERGY_COST * 2:
				# Senza energia comprare non serve e praticare non si puo': il
				# lavoretto e' l'uscita da quel vicolo, e va offerta proprio
				# quando serve invece di stare nascosta in un menu.
				if gameplay.try_start_lavoretto(_world_subject(), "lavoretto-%d" % world_level):
					_set_feedback("%s: c'e' un turno da fare, e si viene pagati." % nome)
					return
			_set_feedback("%s: qui si scambia e si chiacchiera." % nome)
			_open_shop()
		"work_home":
			_allenati_in_casa(nome)
		_:
			_leggi_la_rovina(nome)

## La casa del mestiere: il minigioco della materia del mondo, a costo ridotto.
##
## Lo sconto non e' una ricompensa: e' l'informazione. Un bambino che paga meno
## qui capisce da solo che quell'edificio serve ad allenarsi, senza che nessuno
## glielo spieghi.
func _allenati_in_casa(nome: String) -> void:
	if not is_instance_valid(gameplay) or gameplay.session_active():
		return
	var materia := _world_subject()
	var payload := {"subject": materia}
	var formats := MinigameManager.runtime_formats_for(materia, world_level)
	if not formats.is_empty():
		payload["format"] = formats[posmod(world_level, formats.size())]
	# Nel Deserto delle Orbite (mondo 13) la lezione promette esplicitamente le
	# frazioni: la casa della matematica apre quindi la Forgia, invece di affidare
	# il tema principale del mondo a un'estrazione casuale.
	if materia == "matematica" and WORLD_LESSON_CATALOG.topics(world_level).has("frazioni"):
		payload["topicHint"] = "frazioni"
	if gameplay.try_start_minigame(payload, "casa-%d-%s" % [world_level, materia], true):
		_set_feedback("%s: si lavora %s, e qui l'ingresso costa meno." % [nome, materia])

## La rovina dei Primi: una riga di trama, mai un esercizio.
##
## E' l'unico dei tre edifici che appartiene alla STORIA e non al mondo, e la
## riga cambia con il livello perche' l'indagine avanza.
func _leggi_la_rovina(nome: String) -> void:
	var atto := NoraVoice.atto_di(world_level)
	var riga := "Pietra dei Primi. Nessuna iscrizione leggibile, ma il taglio e' recente."
	if atto == "atto2":
		riga = "Qui c'e' un segno inciso, e lo stesso segno l'hai gia' visto altrove. Non e' un ornamento: e' una firma."
	elif atto == "atto3":
		riga = "Questa e' una delle dodici. Le altre le hai attraversate senza saperlo, e insieme dicono da che parte andavano."
	_set_feedback("%s — %s" % [nome, riga])
	if is_instance_valid(game_save):
		game_save.mark_encounter_completed(str(world_level), "rovina-%d" % world_level)

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

## Il diario: quanto hai giocato, quante prove hai superato, cosa sai adesso.
## Vedi `play_diary.gd` — in particolare il perché dei giorni cumulativi al posto
## di una serie che si azzera.
func _open_diary() -> void:
	if not is_instance_valid(diary_panel):
		return
	_cancel_pending_touch_interaction()
	if is_instance_valid(interaction_button):
		interaction_button.visible = false
	if is_instance_valid(touch_controls_panel):
		touch_controls_panel.visible = false
	if is_instance_valid(player):
		player.set_physics_process(false)
	diary_panel.open_diary()

func _on_diary_closed() -> void:
	if is_instance_valid(player):
		player.set_physics_process(true)
	_refresh_prompt()

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
	var equipped: Dictionary = runtime.get("cosmeticsEquipped", {})
	var pet_kind := str(equipped.get("pet", "pet-spark")).trim_prefix("pet-")
	pet_face.configure(
		PetState.name_of(game_save),
		PetState.livery(game_save),
		PetState.temperament(game_save),
		PetState.resting_face(game_save),
		PetState.bond(game_save),
		PetState.faces(game_save),
		reduced_motion,
		pet_kind)

## Dopo quanto silenzio il Custode si offende. Quarantacinque secondi: il tempo
## di attraversare mezza mappa senza che succeda niente.
##
## **Non è una penalità e non chiede niente.** È l'unica cosa che il Custode può
## fare per esistere quando il gioco non lo guarda: cambia faccia, e basta. Non
## toglie legame, non compare un messaggio, non si perde nulla — la decisione 13
## vieta di punire l'assenza, e una faccia imbronciata che passa da sola non
## punisce: fa compagnia.
const PET_SILENZIO_SEC := 45.0
var _pet_ultimo_segnale_msec := 0

func _pet_aggiorna_silenzio() -> void:
	if not is_instance_valid(pet_face) or _blocking_panel_visible():
		return
	if _pet_ultimo_segnale_msec == 0:
		_pet_ultimo_segnale_msec = Time.get_ticks_msec()
		return
	if Time.get_ticks_msec() - _pet_ultimo_segnale_msec < int(PET_SILENZIO_SEC * 1000.0):
		return
	_pet_react("idle")

func _pet_react(game_signal: String) -> void:
	_pet_ultimo_segnale_msec = Time.get_ticks_msec()
	if is_instance_valid(pet_face) and pet_face.visible:
		pet_face.react_to(game_signal)
	if is_instance_valid(pet_companion) and pet_companion.has_method("react_to"):
		pet_companion.call("react_to", game_signal)

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
		or (is_instance_valid(pet_screen) and pet_screen.visible) 		or (is_instance_valid(diary_panel) and diary_panel.visible)

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
	_pet_react("pet_granted")
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
	_pet_react("pet_granted")
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
	_aggiorna_stato_energia(current, true)
	if is_instance_valid(energy_label):
		energy_label.text = "Energia %d" % current
	if is_instance_valid(fragment_label):
		fragment_label.text = "Frammenti %d" % int(runtime.get("fragments", 0))
	# La barra del prossimo premio segue i FRAMMENTI, non l'energia: dal 14 agosto
	# 2026 la bottega si paga cosi', e una barra che misura la valuta sbagliata
	# dice a un bambino di allenarsi per comprare un cappello. Vedi
	# [[FragmentEconomy]].
	if reward_cost > 0 and is_instance_valid(reward_bar):
		var frammenti := int(runtime.get("fragments", 0))
		reward_name_label.text = "Prossimo: %s" % reward_name
		reward_bar.value = clampf(float(frammenti) / float(reward_cost) * 100.0, 0.0, 100.0)
		var remaining := maxi(0, reward_cost - frammenti)
		reward_remaining_label.text = ("Ti mancano %d frammenti" % remaining) if remaining > 0 else "Puoi comprarlo!"

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
	# A pausa aperta il mondo non riceve niente: Esc la richiude, tutto il
	# resto appartiene ai suoi pulsanti.
	if is_instance_valid(pause_menu) and pause_menu.aperto():
		if event.is_action_pressed("leave_portal") and not event.is_echo():
			pause_menu.chiudi()
			get_viewport().set_input_as_handled()
		return
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
	elif event.is_action_pressed("sprint") and not event.is_echo():
		# **Premere è scattare, tenere è correre.** Un tasto, due verbi: lo spazio
		# è già `interact` e Ctrl in una pagina Web, insieme a W, chiude la scheda.
		# La corsa continua a leggersi da sola nel controller, quindi qui non si
		# consuma l'evento — Maiusc deve restare premuto per chi corre.
		_scatto()
	elif event.is_action_pressed("leave_portal") and not event.is_echo():
		# **Esc ferma il gioco**, come in qualunque altro gioco esista. Prima
		# evidenziava la rotta verso la nave: una scorciatoia che il pulsante
		# della missione gia' offre (diventa «RAGGIUNGI LA NAVE» da solo quando
		# l'esame e' pronto), mentre il tasto per fermarsi non esisteva.
		_apri_pausa()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(pause_menu) and pause_menu.aperto():
		return
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

## **Quanto manca a questa materia, detto dove sta il compito.**
## (24 agosto 2026)
##
## Segnalazione di gioco: «ho finito il mondo 1 con tutti i compiti assegnati e
## non passo al mondo 2». Misurata (`compiti_bastano_probe`), la segnalazione era
## vera e il gate non c'entrava: **i compiti non erano tutti dichiarati**.
##
## I sette eventi della materia del mondo si vedono finire sulla mappa. Anche le
## undici palestre delle altre materie si vedono finire — ma finirne una non
## chiude la materia, e la successiva nasce ALTROVE ([[_respawn_practice_event]]).
## Chi guardava la mappa la vedeva spenta e concludeva di aver finito, mentre il
## quadro degli obiettivi — un'altra schermata — diceva che a latino ne servivano
## ancora due.
##
## Quindi il numero si dice qui, sul cartello e a fine prova, e viene dalla stessa
## funzione che alimenta il quadro ([[ObjectiveBriefing.prove_mancanti]]): due
## posti che dicono numeri diversi sarebbero peggio di uno solo che tace.
func _quota_della_materia(subject: String) -> String:
	if not is_instance_valid(gameplay) or gameplay.progression_manager == null:
		return ""
	var mancano := ObjectiveBriefing.prove_mancanti_di(gameplay.progression_manager, subject)
	if mancano <= 0:
		return " · in linea per il mondo successivo"
	return " · ancora %d %s per il mondo successivo" % [
		mancano, "prova" if mancano == 1 else "prove"]

## Chiusa una palestra: si dice subito se quella materia è a posto o quanto le
## manca. È il momento in cui la domanda «ho finito?» se la pone davvero.
func _annuncia_quota(subject: String) -> void:
	if subject.is_empty() or not is_instance_valid(gameplay) or gameplay.progression_manager == null:
		return
	var mancano := ObjectiveBriefing.prove_mancanti_di(gameplay.progression_manager, subject)
	if mancano <= 0:
		_set_feedback("%s è in linea per il mondo successivo." % subject.capitalize())
		return
	_set_feedback("%s: ancora %d %s. La prossima palestra è comparsa altrove sulla mappa." % [
		subject.capitalize(), mancano, "prova" if mancano == 1 else "prove"])

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
const PET_POI_KINDS := ["encounter", "enigma", "minigame", "minimission"]

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
	_annota_varco(target)
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
			_set_feedback("Interagisci · %s%s" % [
				str(mg_payload.get("label", "Palestra")),
				_quota_della_materia(str(mg_payload.get("subject", "matematica")))])
	elif kind == "treasure":
		if result["collectedTreasureIds"].has(id):
			_set_feedback("Tesoro già raccolto")
		elif not _equipment_requirement_met(target):
			_set_feedback(_equipment_requirement_message(target))
		elif TreasureCatalog.tipo_di(id) == TreasureCatalog.TIPO_LASCITO:
			# Si vede da fuori che questo qualcuno l'ha chiuso, non abbandonato.
			# Dirlo prima è quello che rende l'apertura una decisione invece di
			# un riflesso.
			_set_feedback("Un forziere chiuso con cura. Qualcuno di qui ci teneva.")
		else:
			_set_feedback("Interagisci per raccogliere la cassa")
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
	elif kind == "building":
		var building_role := str(target.get_meta("building_role", ""))
		var building_label := str(target.get_meta("label", "luogo"))
		if building_role == "work_home":
			_set_feedback("%s · entra e allenati nella materia guida" % building_label)
		elif building_role == "ritrovo":
			_set_feedback("%s · incontra chi vive e lavora qui" % building_label)
		else:
			_set_feedback("%s · cerca le tracce lasciate dai Primi" % building_label)

	elif kind == "tana":
		var tana_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("%s Tu non ci passi." % str(tana_payload.get("descrizione", "Una tana.")))
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
		"√ GIÀ COMPLETATO" if completed
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
		# Il pulsante nomina l'attrezzo: con cinque chiavi, «SERVE UNO STRUMENTO»
		# manderebbe a indovinare quale.
		return "SERVE %s" % FieldTools.nome(_required_tool(target)).to_upper().trim_prefix("LA ").trim_prefix("IL ")
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
		"minimission":
			# Il verbo lo decide la forma: «SPEGNI» davanti a un incendio dice
			# in una parola tutto quello che serve sapere.
			return str(Dictionary(target.get_meta("payload", {})).get("verbo", "RIPARA"))
		"minigame":
			return "ALLENATI"
		"enemy":
			return "AFFRONTA"
		"treasure":
			return "APRI" if TreasureCatalog.tipo_di(str(target.get_meta("id", ""))) 				== TreasureCatalog.TIPO_LASCITO else "RACCOGLI"
		"encounter":
			return "AVVIA MISSIONE"
		"npc":
			return "PARLA"
		"building":
			var building_role := str(target.get_meta("building_role", ""))
			if building_role == "work_home":
				return "ENTRA E ALLENATI"
			if building_role == "ritrovo":
				return "ENTRA NEL RITROVO"
			return "ESPLORA LA ROVINA"
		"tana":
			return "MANDA IL CUSTODE"
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
	if kind == "encounter" or kind == "enigma" or kind == "minimission":
		return Array(result.get("completedEncounterIds", [])).has(id)
	return false

func _required_tool(target: Area2D) -> String:
	if target == null:
		return ""
	var payload: Dictionary = target.get_meta("payload", {})
	return str(payload.get("requiredTool", ""))

func _equipment_requirement_met(target: Area2D) -> bool:
	var required := _required_tool(target)
	return required == "" or _strumenti_posseduti().has(required)

## **Segna una porta chiusa che il giocatore ha appena visto** — e la toglie dal
## registro quando invece la può aprire. (19 agosto 2026)
##
## Si chiama quando ci si avvicina abbastanza da leggerne il cartello, non
## quando ci si prova: «l'ho vista» è il fatto che conta, e chi passa davanti a
## un rovo senza premere l'ha vista lo stesso.
##
## Il registro vive nel salvataggio ([[GameSaveManager.record_tool_gate]]) ed è
## il pezzo che rende utile avere cinque chiavi invece di due: senza, uno
## strumento nuovo sarebbe una riga di dialogo, perché nessuno si ricorda dove
## ha visto una lastra sigillata dodici ore prima.
func _annota_varco(target: Area2D) -> void:
	if not is_instance_valid(game_save):
		return
	var richiesto := _required_tool(target)
	if richiesto == "":
		return
	var id := str(target.get_meta("id", ""))
	var mondo := str(world_level)
	if _strumenti_posseduti().has(richiesto):
		# Aperta, o apribile adesso: non è più qualcosa che aspetta.
		game_save.clear_tool_gate(mondo, richiesto, id)
		return
	if game_save.record_tool_gate(mondo, richiesto, id):
		# Si scrive solo alla PRIMA volta che questa porta viene vista: un
		# salvataggio a ogni passaggio davanti allo stesso rovo sarebbe decine di
		# scritture per niente.
		game_save.save()

## **Il messaggio dice quale chiave manca, dove si prende e quando.**
## (19 agosto 2026)
##
## Prima distingueva fra «non ce l'hai» e «ce l'hai ma non e' equipaggiato»: la
## seconda situazione non esiste piu' — uno strumento posseduto apre — e al suo
## posto c'e' quella che conta adesso, con cinque attrezzi distribuiti sull'arco
## della campagna: **questa porta si apre piu' avanti, e si sa quanto avanti.**
##
## Una porta chiusa senza data e' un vicolo cieco; una porta chiusa con la data
## e' un appuntamento, ed e' tutta la differenza fra frustrazione e curiosita'.
func _equipment_requirement_message(target: Area2D) -> String:
	var richiesto := _required_tool(target)
	var ostacolo := FieldTools.ostacolo(richiesto)
	var arnese := FieldTools.nome(richiesto)
	var mondo_strumento := FieldTools.mondo_di(richiesto)
	if is_instance_valid(game_save) and mondo_strumento > int(game_save.level()):
		return "%s · %s te la dara' chi lavora al mondo %d. Torna qui quando ce l'hai." % [
			ostacolo, arnese, mondo_strumento]
	return "%s · %s ce l'ha chi lavora qui: finiscigli una riparazione." % [ostacolo, arnese]

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
	if kind == "building":
		_entra_nell_edificio(target)
		return
	if kind == "hazard":
		_sgombra_hazard(target)
		return
	if kind == "tana":
		_manda_il_custode(target)
		return
	if kind == "enemy":
		var sacca := target.get_parent()
		if is_instance_valid(sacca):
			_sfida_guardiano(sacca)
		return
	if kind == "vault_lock":
		_apri_camera()
		return
	if kind == "landmark":
		var landmark_payload: Dictionary = target.get_meta("payload", {})
		_set_feedback("%s: %s. Completa le tappe indicate sulla mappa per trasformarlo." % [
			str(landmark_payload.get("label", "Punto chiave")).capitalize(),
			str(landmark_payload.get("purpose", "reagisce ai progressi")),
		])
		_guide_to_objective()
		return
	if kind == "minimission":
		var incarico_payload: Dictionary = target.get_meta("payload")
		if result["completedEncounterIds"].has(id):
			_set_feedback("%s: già fatto." % str(incarico_payload.get("titolo", "L'incarico")))
			return
		if _route_to_owner_if_needed(id):
			return
		gameplay.try_start_minimission(incarico_payload, id)
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
		if not _equipment_requirement_met(target):
			_set_feedback(_equipment_requirement_message(target))
			return
		# **Il forziere e' sorvegliato.** Richiesta del committente: gli Sbiaditi
		# proteggono i bauli. Finche' la guardiana e' viva la cassa non si apre —
		# e siccome dentro ci sono frammenti, cioe' cosmetici, questa e' l'unica
		# cosa del gioco che una prova di abilita' puo' lecitamente chiudere.
		var guardiano := _guardiano_di(id)
		if is_instance_valid(guardiano):
			_set_feedback("%s sorveglia questo forziere. Spezzagli i sigilli per scioglierlo." % str(guardiano.get("enemy_name")))
			_sfida_guardiano(guardiano)
			return
		var collected: Array = result["collectedTreasureIds"]
		if collected.has(id):
			_set_feedback("Questa cassa è già stata raccolta.")
		else:
			collected.append(id)
			_apri_forziere(target, id)
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
		if str(context.get("kind", "")) == "minigame" and session_passed \
				and str(context.get("encounterId", "")).begins_with("serratura-"):
			_sciogli_camera()
		if str(context.get("kind", "")) == "minigame" and session_passed:
			# La palestra superata sparisce dalla mappa all'istante, non al
			# rientro: il punto della segnalazione era proprio che si poteva
			# rifarla lì per lì. Non passa dal registro di proprietà — la
			# pratica non ha un proprietario, per contratto.
			_complete_learning_reaction(str(context.get("encounterId", "")))
			# E subito ne nasce un'altra ALTROVE. Senza questo, una materia
			# offrirebbe una sola pratica per visita e per allenarne dodici si
			# dovrebbe tornare alla nave quattro volte per mondo: la
			# ripetizione sparirebbe, ma al posto suo arriverebbe una corvée.
			_respawn_practice_event(str(context.get("subject", "")))
		if str(context.get("kind", "")) in ["mission", "enigma", "minimission"]:
			var encounter_id := str(context.get("encounterId", ""))
			if mission_ownership_flow != null:
				mission_ownership_flow.record_result(encounter_id, session_passed)
			if session_passed:
				_complete_learning_reaction(encounter_id)
				# Se quella prova reggeva uno sbarramento, il muro cade adesso.
				_apri_sbarramento(encounter_id)
				if world_life != null:
					world_life.enqueue_news({
						"type": str(context.get("kind", "mission")),
						"world": world_level,
						"subject": str(exercise_result.get("subject", _world_subject())),
						"level": game_save.level(),
					})
	# Non è il dialogo a restituire il mestiere: è rifarlo insieme. Tutti i
	# residenti di un mondo testimoniano la sua materia, ma il confronto resta
	# esplicito per impedire che una prova trasversale o un'altra materia chiuda
	# la scena per caso.
	if session_passed and thirteenth_deep_forgotten_npc != "":
		var proof_subject := str(context.get(
			"subject", exercise_result.get("subject", _world_subject())))
		if proof_subject == NpcArc.materia_di(thirteenth_deep_forgotten_npc):
			_restore_deep_smemora(true)
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
	# **Dopo `_refresh_prompt`, e non prima.** Quella riscrive la riga di feedback
	# con il cartello di ciò che Eli ha vicino: annunciare la quota più su
	# significava scriverla e vedersela cancellare nello stesso fotogramma. È il
	# genere di difetto che non si vede leggendo, perché le due chiamate stanno a
	# sessanta righe di distanza.
	if str(context.get("kind", "")) == "minigame" and session_passed:
		_annuncia_quota(str(context.get("subject", "")))

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
			var activity_site := node.get_node_or_null("World1ActivitySite")
			if activity_site != null and activity_site.has_method("set_progress"):
				activity_site.call("set_progress", correct, total, true)
			break

func _complete_learning_reaction(encounter_id: String) -> void:
	if encounter_id == "":
		return
	for node in get_tree().get_nodes_in_group("world_interactable"):
		if node is Area2D and str(node.get_meta("id", "")) == encounter_id:
			var reaction := node.get_node_or_null("LearningReaction")
			if reaction != null and reaction.has_method("set_complete"):
				reaction.call("set_complete", true, true)
			var activity_site := node.get_node_or_null("World1ActivitySite")
			if activity_site != null and activity_site.has_method("set_complete"):
				activity_site.call("set_complete", true, true)
			_retire_completed_event(node as Area2D)
			break
	_sync_profile_environment_transform(true)

func _retire_completed_event(area: Area2D) -> void:
	## Mantiene l'esito ambientale conquistato, ma ritira affordance, collisione
	## e sfera della tappa. Gli enigmi conservano invece la struttura costruita.
	if not is_instance_valid(area):
		return
	# La tappa si chiude e sparisce dalla mappa: è un momento visibile, e il
	# Custode lo festeggia. Distinto da «sessione superata», che riguarda le
	# risposte: qui riguarda il posto.
	_pet_react("mission_complete")
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
	for child_name in ["EventMarker", "EventCaption", "DiscoveryCue"]:
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
	for area in get_tree().get_nodes_in_group("progress_reaction_poi"):
		if area is Area2D and str(area.get_meta("id", "")) == encounter_id:
			for child in area.get_children():
				if child.has_method("set_stage"):
					child.set_stage(built, total)
	if built <= 0:
		# Una risposta errata mantiene il POI allo stadio iniziale, ma non deve
		# produrre commenti: l'errore resta narrativamente neutro (e il Custode
		# può sdrammatizzarlo senza che un messaggio di sistema lo copra).
		return
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "enigmaProgress", lerpf(0.9, 1.12, float(built) / maxf(float(total), 1.0)))
	_set_feedback("%s: %d/%d passaggi visibili" % [theme.capitalize(), built, total])
	_spawn_gain_popup("+1 segno nel mondo", Color("8ff6c0"))

func _leave_world() -> void:
	# Stato effimero per contratto: anche chi non ha notato il segno o non ha
	# voluto fare la prova ritrova l'abitante intero al prossimo ingresso.
	_restore_deep_smemora(false)
	if is_instance_valid(gameplay):
		if is_instance_valid(player):
			gameplay.game_save.set_world_resume(
				str(world_level), player.global_position, day_clock / WorldSky.DURATA)
		gameplay.game_save.save()
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play_event", "portalOpened")
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

# --- La pausa ------------------------------------------------------------------
#
# **Le tre uscite.** (21 agosto 2026) Richiesta del committente: tornare al menu
# principale, riavviare la missione, cambiare utente. Nel mondo aperto non ce
# n'era nessuna delle tre: l'unico modo di smettere era raggiungere il portale,
# entrare nella nave e cercare lassu'.
#
# Il pannello e' [[PauseMenuPanel]] e lo condivide con la nave. Qui vive soltanto
# che cosa significano quei comandi **dentro un mondo**.

## I pannelli che, se aperti, hanno gia' la loro via d'uscita e non devono
## averne due. Un menu di pausa sopra una prova in corso sarebbe due tasti
## «esci» sovrapposti, e il bambino imparerebbe che uno dei due perde il lavoro.
func _pausa_possibile() -> bool:
	for pannello in [
		exercise_player, dialogue_box, knowledge_codex_panel, diary_panel,
		shop_panel, pet_screen, pet_naming_panel, teaching_choice_panel,
		minigame_panel, duel_panel, objective_panel, lock_panel,
	]:
		if is_instance_valid(pannello) and pannello.visible:
			return false
	return true

## **Fermarsi salva.** Il salvataggio esplicito qui non e' prudenza generica: da
## questo pannello si esce in tre modi diversi e tutti e tre cambiano scena.
## Farlo una volta sola, all'apertura, e' l'unico modo per non doverselo
## ricordare tre volte, e per poter scrivere sul pannello che la partita e' al
## sicuro senza che sia una promessa.
func _apri_pausa() -> void:
	if not _pausa_possibile():
		return
	_salva_posizione_e_partita()
	if not is_instance_valid(pause_menu):
		pause_menu = PauseMenuPanel.new()
		pause_menu.name = "PauseMenuPanel"
		pause_menu.ripreso.connect(_on_pausa_chiusa)
		pause_menu.riavvio_chiesto.connect(_riavvia_mondo)
		pause_menu.giocatore_scelto.connect(_cambia_giocatore)
		pause_menu.menu_chiesto.connect(_torna_al_menu)
		ui_layer.add_child(pause_menu)
	pause_menu.move_to_front()
	pause_menu.apri(
		_nome_del_giocatore(),
		"Mondo %d · %s" % [world_level, str(world_profile.get("title", ""))],
		"RIAVVIA IL MONDO",
		"Torni al portale, all'ora in cui questo mondo comincia. Prove superate, tesori e frammenti restano tuoi.",
		true,
		high_contrast)
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null:
		audio.call("play", "panel.open")

func _on_pausa_chiusa() -> void:
	# Il dito che ha toccato RIPRENDI e' ancora sullo schermo, e senza questo
	# diventerebbe subito un ordine di camminare verso quel punto.
	_cancel_pending_touch_interaction()

func _nome_del_giocatore() -> String:
	if PlayerProfiles.has_profiles():
		return str(PlayerProfiles.active().get("name", "Giocatore 1"))
	return "Giocatore 1"

## Salva dove si e' arrivati e poi la partita, come fa l'uscita verso la nave.
## Senza la posizione, «menu principale» e poi «gioca» rimetterebbe Eli al
## portale: e' quello che il riavvio chiede, ed e' sbagliato per tutti gli altri.
func _salva_posizione_e_partita() -> void:
	if not is_instance_valid(game_save):
		return
	if is_instance_valid(player):
		game_save.set_world_resume(
			str(world_level), player.global_position, day_clock / WorldSky.DURATA)
	game_save.save()

## **Riavviare il mondo e' rifare il giro, non rifare la scuola.**
##
## Si cancella una cosa sola: dov'era rimasto. Tutto il resto (incontri risolti,
## tesori raccolti, maestria, frammenti) resta scritto, e non per pigrizia: un
## riavvio che restituisse i tesori sarebbe il modo piu' veloce di guadagnare
## frammenti che il gioco abbia, e diventerebbe la strada conveniente invece del
## comando di servizio che deve essere.
##
## Quello che torna davvero indietro e' il mondo effimero: Eli al portale, l'ora
## d'autore, le anomalie di nuovo in piedi, gli abitanti ai loro posti.
func _riavvia_mondo() -> void:
	if is_instance_valid(game_save):
		game_save.clear_world_resume(str(world_level))
		game_save.save()
	if is_instance_valid(pause_menu):
		pause_menu.congeda()
	_stage_rientro_nel_mondo("riavvio-%d" % world_level)
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

## **Cambiare giocatore.** La partita di chi esce e' gia' salvata (lo ha fatto
## l'apertura della pausa) e il profilo attivo l'ha gia' spostato il pannello dei
## profili: qui resta soltanto da entrare nel mondo dell'altro bambino.
##
## Non si passa dal menu d'avvio, di proposito: due fratelli che si alternano lo
## fanno dieci volte in un pomeriggio, e ogni passaggio in piu' e' un motivo per
## non farlo e giocare sopra la partita dell'altro, che e' esattamente il difetto
## che i profili sono nati per chiudere.
##
## Nessuna richiesta preparata: il mondo senza richiesta legge il salvataggio del
## profilo attivo e apre il mondo in cui **quel** bambino era arrivato.
func _cambia_giocatore(id: String) -> void:
	PlayerProfiles.set_active(id)
	PlayerProfiles.touch(id)
	if is_instance_valid(pause_menu):
		pause_menu.congeda()
	NativeWorldState.stage_launch_request({})
	get_tree().change_scene_to_file("res://scenes/outdoor_world.tscn")

func _torna_al_menu() -> void:
	if is_instance_valid(pause_menu):
		pause_menu.congeda()
	get_tree().change_scene_to_file("res://scenes/boot_menu.tscn")

## La richiesta di rientro nello stesso mondo con lo stesso salvataggio, nella
## forma che usa la nave quando ci riporta dentro.
func _stage_rientro_nel_mondo(seme: String) -> void:
	if not is_instance_valid(game_save):
		return
	var richiesta := NativeWorldState.default_request(seme)
	richiesta["loadLocalSave"] = false
	richiesta["initialSave"] = game_save.data.duplicate(true)
	richiesta["worldLevel"] = world_level
	richiesta["accessibility"] = {
		"highContrast": high_contrast,
		"reducedMotion": reduced_motion,
	}
	richiesta["accessibilityExplicit"] = true
	NativeWorldState.stage_launch_request(richiesta)

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
		return "o"
	var angle := fposmod(delta.angle() + PI / 8.0, TAU)
	var index := int(floor(angle / (PI / 4.0))) % 8
	var arrows := PackedStringArray(["»", "»", "v", "«", "«", "«", "^", "»"])
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

## Apre il quadro degli obiettivi. Eli si ferma: e' una schermata a tutto
## schermo, e lasciarla camminare sotto la manderebbe chissa' dove.
func _apri_obiettivi() -> void:
	if is_instance_valid(objective_panel):
		return
	if not is_instance_valid(gameplay) or not is_instance_valid(ui_layer):
		return
	objective_panel = ObjectivePanel.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.chiuso.connect(_chiudi_obiettivi)
	objective_panel.portami.connect(_portami_alla_palestra)
	ui_layer.add_child(objective_panel)
	objective_panel.apri(
		ObjectiveBriefing.passo(runtime, gameplay.progression_manager),
		ObjectiveBriefing.percorso(gameplay.progression_manager))
	if is_instance_valid(player):
		player.set_physics_process(false)

## **PORTAMI.** (21 agosto 2026) Il quadro degli obiettivi dice che cosa manca;
## questo porta dove si recupera. Punta la stazione di quella materia e chiude
## il quadro: se restasse aperto, il bambino leggerebbe una rotta che non vede.
##
## Non teletrasporta e non apre niente: imposta il bersaglio del passo, come
## fa «SEGUI LA MISSIONE». Camminarci resta il gioco.
func _portami_alla_palestra(materia: String) -> void:
	var meta: Node2D = null
	for nodo in get_tree().get_nodes_in_group("minigame_poi"):
		if not (nodo is Node2D) or not is_instance_valid(nodo):
			continue
		var carico: Dictionary = (nodo as Node).get_meta("payload", {})
		if str(carico.get("subject", "")) != materia:
			continue
		meta = nodo as Node2D
		break
	_chiudi_obiettivi()
	if meta == null:
		# Onesto invece che muto: la palestra di quella materia in questo mondo
		# puo' essere gia' stata chiusa, e ne rinasce una al giro dopo.
		_set_feedback("Qui la palestra di %s l'hai gia' chiusa: ne riapre una piu' avanti." % materia)
		return
	if is_instance_valid(player):
		player.set_touch_target(meta.global_position)
	_spawn_touch_ping(meta.global_position)
	_set_feedback("Rotta verso l'allenamento di %s." % materia)

func _chiudi_obiettivi() -> void:
	if is_instance_valid(objective_panel):
		objective_panel.queue_free()
		objective_panel = null
	if is_instance_valid(player):
		player.set_physics_process(true)

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
		# L'apparato pronto NON significa livello pronto: sono due gate distinti.
		# Dirlo QUI, prima dell'esame, evita che il bambino lo superi aspettando
		# il mondo successivo — che è esattamente quello che è successo al primo
		# collaudo vero, sul mondo 1. `coreMissing` era nello stato runtime dal
		# principio e non lo leggeva nessuno.
		var mancano: Array = Array(runtime.get("coreMissing", []))
		if not mancano.is_empty():
			objective_label.text += "\nPer il MONDO successivo serve anche il nucleo: manca %s" % (
				", ".join(PackedStringArray(mancano)))
	elif world_level != int(runtime.get("level", 1)):
		objective_label.text = "MONDO %d · %s · RIVISITA\nFocus locale: %s · Frontiera: livello %d, %s\nLe missioni qui allenano %s; usa la nave per cambiare rotta" % [
			world_level, str(world_profile.get("title", "")), profile_subject,
			int(runtime.get("level", 1)), subject, profile_subject]
	else:
		# **Un'istruzione, non un cruscotto.** (7 agosto 2026)
		#
		# Qui c'era: «Livello 1 · Materia matematica / Apparato: nucleo ·
		# padronanza 34%/45% / Nucleo: MAT 60% · ITA 20% · ING 0% · stanze 1/12».
		# Sei numeri e nessun verbo. Un bambino di undici anni non ne ricava che
		# cosa toccare adesso — e il gate vero chiede dodici materie per tre
		# condizioni, quindi quei numeri non lo dicevano nemmeno tutto.
		#
		# Adesso l'etichetta porta **una cosa sola da fare**; il conto lungo sta
		# dietro il pulsante «CHE COSA DEVO FARE?», per chi lo vuole.
		var passo := ObjectiveBriefing.passo(runtime, gameplay.progression_manager)
		objective_label.text = "%s\n%s" % [
			str(passo.get("titolo", "")), str(passo.get("azione", ""))]
		var dove := str(passo.get("dove", "")).strip_edges()
		if not dove.is_empty():
			objective_label.text += "\nDove: %s" % dove
	for event_data in mission_events:
		var event: Dictionary = event_data
		if (
			event.has("crossingId")
			and not Array(result.get("completedEncounterIds", [])).has(str(event.get("id", "")))
		):
			objective_label.text = "PASSAGGIO D'ACQUA BLOCCATO\nTrova il ponte-enigma: risolvilo per attraversare\n%s" % objective_label.text
			break
