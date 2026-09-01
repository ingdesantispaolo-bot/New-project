extends SceneTree

const ProgressRecognition = preload("res://scripts/game/progress_recognition.gd")

## Prova del contratto importante: la zona puo' colpire, ma non puo' mai
## diventare un corpo che impedisce di camminare.

var exposures := 0
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node2D.new()
	stage.name = "HazardAuditStage"
	root.add_child(stage)

	var hazard := WorldHazard.new()
	hazard.configure("audit-hazard", "campo di prova", Color("ffb35c"), 2, 0.0, true)
	stage.add_child(hazard)
	hazard.exposed.connect(func(_area: Area2D, _body: Node): exposures += 1)

	var player := CharacterBody2D.new()
	player.name = "AuditPlayer"
	player.collision_layer = 1
	player.collision_mask = 1
	player.add_to_group("player")
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	collision.shape = circle
	player.add_child(collision)
	stage.add_child(player)

	await physics_frame
	# Attraversamento completo: un'Area2D viene rilevata, non risolta come urto.
	player.position = Vector2(-140.0, 0.0)
	var impact := player.move_and_collide(Vector2(280.0, 0.0))
	assert(impact == null and player.position.x > 100.0,
		"il pericolo ambientale sta bloccando il cammino")
	assert(_count_static_bodies(hazard) == 0,
		"un hazard contiene uno StaticBody2D: deve restare attraversabile")

	player.position = Vector2.ZERO
	hazard.force_phase_for_audit(WorldHazard.ACTIVE)
	await physics_frame
	await physics_frame
	assert(exposures == 1, "l'impulso attivo non produce una conseguenza")
	await physics_frame
	assert(exposures == 1, "lo stesso impulso colpisce ogni frame invece che una volta")

	hazard.force_phase_for_audit(WorldHazard.SAFE)
	await physics_frame
	hazard.force_phase_for_audit(WorldHazard.ACTIVE)
	await physics_frame
	assert(exposures == 2, "un nuovo impulso non puo' colpire di nuovo")

	stage.queue_free()
	await process_frame
	await _audit_outdoor_consequence()
	print("WORLD HAZARD audit OK — leggibile, pulsante, costi scalati, fallimento accelerante, minigioco risolutivo e mai bloccante")
	quit(0)

func _audit_outdoor_consequence() -> void:
	var initial := GameSaveManager._default_data()
	initial["energy"] = 40
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("hazard-outdoor-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 1)
	root.add_child(world)
	await process_frame
	await process_frame
	var outdoor_hazard: Area2D = null
	for node in get_nodes_in_group("world_hazard"):
		if node is Area2D and world.is_ancestor_of(node):
			outdoor_hazard = node
			break
	assert(outdoor_hazard != null, "la scena reale non crea il pericolo")
	var challenge_hazard: Area2D = null
	for node in get_nodes_in_group("world_challenge_hazard"):
		if node is Area2D and world.is_ancestor_of(node):
			challenge_hazard = node
			break
	assert(challenge_hazard != null, "manca il pericolo specifico del mondo")
	var challenge_payload: Dictionary = challenge_hazard.get_meta("payload", {})
	assert(str(challenge_payload.get("subject", "")) == "matematica",
		"il primo mondo deve aprire l'alternanza con matematica")
	var outdoor_player := world.get("player") as OutdoorPlayerController
	outdoor_player.global_position = outdoor_hazard.global_position
	var before_energy := int(world.get("game_save").energy())
	world.call("_on_hazard_exposed", outdoor_hazard, outdoor_player)
	var contact_cost := int(Dictionary(outdoor_hazard.get_meta("payload", {})).get("cost", 2))
	assert(int(world.get("game_save").energy()) == before_energy - contact_cost,
		"il contatto reale non applica il costo scalato")
	assert(outdoor_player.global_position.distance_to(outdoor_hazard.global_position) >= 90.0,
		"il contatto reale non respinge Eli fuori dal centro")

	world.call("_avvia_prova_del_pericolo", challenge_hazard)
	var gameplay := world.get("gameplay") as OutdoorGameplay
	assert(str(gameplay.active_session_context.get("encounterId", "")) == "world-danger-01",
		"interagire col pericolo non apre il suo minigioco")
	assert(int(gameplay.active_session_context.get("challengeLevel", 0)) == 1,
		"il minigioco non eredita il livello del mondo")
	assert(int(world.get("exercise_player").session.get("level", 0)) == 1,
		"la sessione visualizzata non usa il livello del mondo")
	var before_failure := int(world.get("game_save").energy())
	world.call("_on_exercise_finished", {
		"passed": false,
		"correct": 0,
		"total": 1,
		"energyGained": 0,
		"subject": "matematica",
		"topicStats": {},
		"solved": {},
		"seconds": 1.0,
	})
	await process_frame
	var failure_cost := int(challenge_payload.get("failureCost", 0))
	assert(int(world.get("game_save").energy()) == before_failure - failure_cost,
		"fallire non applica la penalita' scalata")
	assert(bool(challenge_hazard.call("failure_surge_active")),
		"il fallimento non accelera il pericolo")
	assert(not Array(world.get("game_save").world_progress("1").get(
		"clearedHazardIds", [])).has("world-danger-01"),
		"fallire elimina comunque il pericolo")

	world.call("_avvia_prova_del_pericolo", challenge_hazard)
	assert(str(gameplay.active_session_context.get("encounterId", "")) == "world-danger-01",
		"il pericolo non permette di riprovare")
	var fragments_before_victory := int(world.get("game_save").fragments())
	world.call("_on_exercise_finished", {
		"passed": true,
		"correct": 1,
		"total": 1,
		"energyGained": 0,
		"subject": "matematica",
		"topicStats": {},
		"solved": {},
		"seconds": 1.0,
	})
	await process_frame
	assert(Array(world.get("game_save").world_progress("1").get(
		"clearedHazardIds", [])).has("world-danger-01"),
		"superare il minigioco non stabilizza il pericolo")
	assert(int(world.get("game_save").fragments()) - fragments_before_victory
		== FragmentEconomy.premio_pericolo(1),
		"il Pericolo del Mondo non paga il premio dichiarato")
	assert(get_nodes_in_group("world_stability_marker").size() == 1,
		"la vittoria lascia soltanto un vuoto invece di un segno stabile")
	var recognition := ProgressRecognition.summary(world.get("game_save"))
	assert(int(recognition.get("facets", 0)) >= 2,
		"pratica e pericolo non lasciano tracce distinte nel ritratto")
	world.queue_free()
	await process_frame

func _count_static_bodies(node: Node) -> int:
	var count := 1 if node is StaticBody2D else 0
	for child in node.get_children():
		count += _count_static_bodies(child)
	return count
