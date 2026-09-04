extends SceneTree

## Sonda usa e getta: con la torcia non ancora in mano, dove porta il bottone
## della bussola, e che cosa cambia quando la torcia arriva?

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _stato(world: Node, quando: String) -> void:
	var guide := world.find_child("GuideToShipButton", true, false)
	var rotta: Dictionary = world.call("_ownership_navigation_target")
	var nodo := rotta.get("node") as Area2D
	print("%s" % quando)
	print("   bottone: «%s»" % (str(guide.get("text")) if guide != null else "(assente)"))
	print("   rotta: fase «%s» · evento «%s» · messaggio «%s»" % [
		str(rotta.get("phase", "")), str(rotta.get("eventId", "")), str(rotta.get("message", ""))])
	if nodo != null:
		print("   punta a: id «%s» tipo «%s»" % [
			str(nodo.get_meta("id", "")), str(nodo.get_meta("kind", ""))])
	var tobia := world.call("_npc_actor_by_id", "w01-tobia") as Area2D
	if nodo != null and tobia != null:
		print("   e' Tobia: ", nodo == tobia)

func _run() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var gameplay = world.get("gameplay")
	var save = world.get("game_save")
	save.set_level(1)
	save.data["worlds"] = {"unlocked": [1], "current": 1}
	save.reset_missions()
	save.set_mastery("matematica", 0.0)
	gameplay.call("_emit_state")
	await process_frame
	_stato(world, "SENZA la torcia:")
	gameplay.reward_manager.deliver_field_tool("tool-torch")
	gameplay.call("_emit_state")
	await process_frame
	_stato(world, "CON la torcia:")
	quit(0)
