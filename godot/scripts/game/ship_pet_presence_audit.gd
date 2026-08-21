extends SceneTree

## C-G9: il Custode non si ferma fuori dalla nave. Il test prepara un salvataggio
## con compagno già consegnato, verifica volto/interazione e attraversa l'esame
## reale che accende il primo apparato.

const HUB_SCENE := "res://scenes/hub.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var fixture := GameSaveManager.new()
	fixture.data = GameSaveManager._default_data()
	PetState.grant(fixture, 1)
	PetState.set_pet_name(fixture, "Luma")
	fixture.data["cosmetics"] = {
		"unlocked": ["pet-guardiano"],
		"equipped": {"pet": "pet-guardiano"},
		"inventory": [],
	}
	var subject := ApparatusConfig.world_subject(1)
	fixture.add_mission(subject)
	fixture.set_mastery(subject, ApparatusConfig.subject_mastery_threshold(subject, 1))
	for topic in ["audit-a", "audit-b", "audit-c"]:
		fixture.set_topic_mastery(subject, topic, 1.0)

	var hub := (load(HUB_SCENE) as PackedScene).instantiate()
	hub.set("launch_save_override", fixture.data.duplicate(true))
	root.add_child(hub)
	current_scene = hub
	await process_frame
	await process_frame

	var face := hub.find_child("ShipPetFaceWidget", true, false) as PetFaceWidget
	assert(face != null and face.is_visible_in_tree(),
		"il Custode consegnato non è visibile nella nave")
	assert(face.current_pet_kind() == "guardiano",
		"il volto nella nave non mostra la forma del Custode equipaggiata")
	hub.call("_pet_react", "apparatus_repaired")
	assert(face.current_face() == PetExpressionEngine.face_for("apparatus_repaired"),
		"il widget della nave non traduce il segnale dell'apparato")
	hub.set_meta("last_pet_signal", "")

	var save: GameSaveManager = hub.get("save")
	var bond_before := PetState.bond(save)
	hub.call("_on_pet_cuddled")
	assert(PetState.bond(save) > bond_before, "la carezza nella nave non raggiunge lo stato del Custode")
	hub.call("_open_pet_screen")
	var pet_screen := hub.get("pet_screen") as Control
	assert(pet_screen != null and pet_screen.visible, "la pressione lunga non apre la schermata Custode")
	pet_screen.call("close_screen")

	var controller: HubController = hub.get("controller")
	assert(controller.progression.can_repair_apparatus(subject),
		"fixture nave non pronta per l'esame")
	await hub.call("_on_exam_finished", {
		"passed": true,
		"subject": subject,
		"correct": 3,
		"total": 3,
		"seconds": 1.0,
	})
	assert(str(hub.get_meta("last_pet_signal", "")) == "apparatus_repaired",
		"l'esame superato non emette apparatus_repaired")
	assert(face.is_visible_in_tree(), "il Custode sparisce durante la riattivazione")

	print("C-G9 SHIP PET PRESENCE audit VERDE - volto, carezza, schermata e apparato")
	quit(0)
