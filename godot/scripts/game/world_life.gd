class_name WorldLife
extends RefCounted

## Regia deterministica e leggera della vita del mondo. Non scrive save,
## mastery, energia, gate o ricompense: muove presenze fuori campo e orchestra
## conversazioni che il giocatore puo' ascoltare senza perdere il controllo.

const RITROVO := preload("res://scripts/game/ritrovo_catalog.gd")
const MOVE_SPEED := 86.0
const ARRIVAL_RADIUS := 18.0
const LISTEN_RADIUS := 360.0
const NEWS_LIMIT := 8
const NEWS_MAX_USES := 2
const NEWS_MAX_DAYS := 3

var world := 0
var stage := 0
var reduced_motion := false
var actors: Dictionary = {}
var anchors: Dictionary = {}
var phase := ""
var target_anchor := "home"
var news: Array = []

var conversation_active := false
var conversation_id := ""
var conversation_lines: Array = []
var conversation_index := -1
var conversation_elapsed := 0.0
var conversation_heard := false
var farewell_shown := false
var played_stages: Dictionary = {}

func configure(world_level: int, actor_nodes: Array, anchor_map: Dictionary,
		world_stage: int, use_reduced_motion: bool) -> void:
	world = world_level
	stage = clampi(world_stage, 0, 2)
	reduced_motion = use_reduced_motion
	anchors = anchor_map.duplicate(true)
	actors.clear()
	for actor in actor_nodes:
		if actor is Area2D:
			var npc_id := str(actor.get_meta("id", ""))
			if npc_id != "":
				actors[npc_id] = actor

func set_stage(value: int) -> void:
	stage = clampi(value, 0, 2)

func enqueue_news(token: Dictionary) -> void:
	var item := token.duplicate(true)
	item["uses"] = clampi(int(item.get("uses", 0)), 0, NEWS_MAX_USES)
	item["age"] = maxi(0, int(item.get("age", 0)))
	news.append(item)
	while news.size() > NEWS_LIMIT:
		news.pop_front()

func update(new_phase: String, player_position: Vector2, visible_world: Rect2, delta: float) -> void:
	if new_phase != phase:
		var previous := phase
		phase = new_phase
		target_anchor = _anchor_for_phase(phase)
		if previous == "notte" and phase == "alba":
			_age_news()
	_update_routines(visible_world, delta)
	_update_conversation(player_position, delta)

func _anchor_for_phase(value: String) -> String:
	match value:
		"giorno":
			return "work"
		"alba":
			return "ritrovo"
	return "home"

func _update_routines(visible_world: Rect2, delta: float) -> void:
	var guarded_view := visible_world.grow(96.0)
	for npc_id in actors.keys():
		var actor := actors[npc_id] as Area2D
		if not is_instance_valid(actor):
			continue
		var npc_anchors: Dictionary = anchors.get(npc_id, {})
		var target: Vector2 = npc_anchors.get(target_anchor, actor.global_position)
		if actor.global_position.distance_to(target) <= ARRIVAL_RADIUS:
			actor.global_position = target
			continue
		# In campo resta soltanto l'animazione di occupazione: nessun abitante
		# scivola o compare davanti a Eli.
		if guarded_view.has_point(actor.global_position):
			continue
		var next := actor.global_position.move_toward(target, MOVE_SPEED * maxf(delta, 0.0))
		if not guarded_view.has_point(next):
			actor.global_position = next

func _update_conversation(player_position: Vector2, delta: float) -> void:
	if not conversation_active:
		_try_start_conversation()
		return
	if player_position.distance_to(_ritrovo_center()) <= LISTEN_RADIUS:
		conversation_heard = true
	conversation_elapsed += maxf(delta, 0.0)
	if conversation_elapsed < _line_duration():
		return
	conversation_elapsed = 0.0
	var next_index := conversation_index + 1
	if next_index < conversation_lines.size():
		_show_line(next_index)
		return
	if conversation_heard and not farewell_shown:
		var scene := RITROVO.scene(conversation_id)
		var farewell: Dictionary = scene.get("congedo", {})
		if not farewell.is_empty():
			farewell_shown = true
			_show_world_line(str(farewell.get("chi", "")), str(farewell.get("dice", "")))
			return
	_finish_conversation()

func _try_start_conversation() -> void:
	if phase != "alba" or bool(played_stages.get(stage, false)):
		return
	var scene := RITROVO.scene_for(world, stage)
	if scene.is_empty():
		return
	for npc_id in Array(scene.get("cast", [])):
		if not actors.has(str(npc_id)):
			return
		var actor := actors[str(npc_id)] as Area2D
		var target := Dictionary(anchors.get(str(npc_id), {})).get("ritrovo", actor.global_position) as Vector2
		if actor.global_position.distance_to(target) > ARRIVAL_RADIUS:
			return
	conversation_id = str(scene.get("id", ""))
	var with_news := not news.is_empty()
	conversation_lines = RITROVO.lines_of(conversation_id, with_news)
	if conversation_lines.is_empty():
		return
	if with_news:
		_consume_news()
	conversation_active = true
	conversation_heard = false
	farewell_shown = false
	played_stages[stage] = true
	_show_line(0)

func _show_line(index: int) -> void:
	conversation_index = index
	var line: Dictionary = conversation_lines[index]
	_show_world_line(str(line.get("chi", "")), str(line.get("dice", "")))

func _show_world_line(npc_id: String, text: String) -> void:
	_hide_all_lines()
	var actor := actors.get(npc_id) as Area2D
	if is_instance_valid(actor) and actor.has_method("show_world_line"):
		actor.call("show_world_line", text)

func _hide_all_lines() -> void:
	for actor in actors.values():
		if is_instance_valid(actor) and actor.has_method("hide_world_line"):
			actor.call("hide_world_line")

func _finish_conversation() -> void:
	_hide_all_lines()
	conversation_active = false
	conversation_lines.clear()
	conversation_index = -1
	conversation_elapsed = 0.0

func _line_duration() -> float:
	var text := ""
	if conversation_index >= 0 and conversation_index < conversation_lines.size():
		text = str(Dictionary(conversation_lines[conversation_index]).get("dice", ""))
	return clampf(2.8 + float(text.length()) / 22.0, 3.2, 7.5)

func _ritrovo_center() -> Vector2:
	for npc_anchors in anchors.values():
		if npc_anchors is Dictionary and (npc_anchors as Dictionary).has("ritrovo"):
			return (npc_anchors as Dictionary)["ritrovo"]
	return Vector2.ZERO

func _consume_news() -> void:
	if news.is_empty():
		return
	var item: Dictionary = news[0]
	item["uses"] = int(item.get("uses", 0)) + 1
	if int(item["uses"]) >= NEWS_MAX_USES:
		news.pop_front()
	else:
		news[0] = item

func _age_news() -> void:
	var fresh: Array = []
	for raw_item in news:
		var item: Dictionary = raw_item
		item["age"] = int(item.get("age", 0)) + 1
		if int(item["age"]) < NEWS_MAX_DAYS:
			fresh.append(item)
	news = fresh

func debug_state() -> Dictionary:
	return {
		"world": world,
		"stage": stage,
		"phase": phase,
		"targetAnchor": target_anchor,
		"active": conversation_active,
		"sceneId": conversation_id,
		"lineIndex": conversation_index,
		"baseLineCount": conversation_lines.size(),
		"heard": conversation_heard,
		"farewellShown": farewell_shown,
		"news": news.duplicate(true),
		"actorCount": actors.size(),
	}
