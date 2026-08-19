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

## **Chi ti vede passare ti dice qualcosa.** (16 agosto 2026)
##
## Difetto segnalato: gli abitanti sembravano stupidi. Il motivo non era il testo
## — il catalogo ha registro, tic, convinzione e arco per quarantasei persone —
## era che quel testo **usciva soltanto aprendo un dialogo**. Attraversando il
## mondo, un abitante era un birillo con un nome sopra: restava muto anche se gli
## passavi a due passi, anche se avevi appena rimesso in moto il suo apparato.
##
## Adesso, quando Eli arriva vicino, l'abitante dice **una riga sola**, presa dal
## suo stesso catalogo — quindi con la sua voce e il suo tic, non con una formula
## generica. Le regole servono a tenerla simpatica invece che molesta:
##
##   - parla all'**arrivo**, non finché resti lì (isteresi fra i due raggi): chi
##     ripete la stessa frase mentre gli stai davanti sembra rotto;
##   - un solo fumetto per volta in tutto il mondo, con una pausa fra uno e
##     l'altro: due presenze che parlano insieme sono rumore;
##   - un lungo riposo per persona, così la seconda battuta arriva a distanza e
##     non è mai la stessa della prima (il cursore avanza);
##   - **la notizia ha la precedenza sul colore**: se hai appena superato una
##     prova, chi incontri commenta quello. È il pezzo che li rende partecipi
##     della storia invece che decorativi.
const AMBIENT_RADIUS := 300.0
const AMBIENT_RELEASE := 470.0
const AMBIENT_DWELL := 0.55
const AMBIENT_COOLDOWN := 26.0
const AMBIENT_GAP := 4.5

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

## Lo stadio d'arco di ciascun residente, non quello del mondo: la battuta di
## passaggio deve venire da dove sta QUELLA persona (vedi `NpcArc`). Vuoto negli
## audit di sola regia, e allora si ripiega sullo stadio di mondo.
var resident_stages: Dictionary = {}
var ambient_speaker := ""
var ambient_hold := 0.0
var ambient_gap := 0.0
var ambient_near: Dictionary = {}
var ambient_dwell: Dictionary = {}
var ambient_cooldown: Dictionary = {}
var ambient_cursor: Dictionary = {}
var ambient_news_seen: Dictionary = {}
## Le battute di passaggio tacciono mentre un pannello copre il mondo: un fumetto
## che si accende dietro a un dialogo aperto è testo che nessuno leggerà e che
## sarà sparito quando si torna a guardare.
var ambient_enabled := true

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

func set_resident_stages(stages: Dictionary) -> void:
	resident_stages = stages.duplicate(true)

func set_ambient_enabled(enabled: bool) -> void:
	ambient_enabled = enabled

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
	_update_ambient(player_position, delta)

func _anchor_for_phase(value: String) -> String:
	match value:
		"giorno":
			return "work"
		"alba":
			return "ritrovo"
		# **Il richiamo** (19 agosto 2026): quando l'apparato diventa riparabile la
		# nave chiama, e la gente smette di lavorare e si raduna. Non è una fase
		# dell'orologio — non torna e non ruota — è uno stato in cui il mondo
		# entra e da cui esce solo quando Eli se ne va. Vedi
		# `OutdoorWorld._apri_il_richiamo`.
		"richiamo":
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
		# In campo resta soltanto l'animazione di occupazione: nessun abitante
		# scivola o compare davanti a Eli. Vale anche per lo scatto d'arrivo:
		# quando l'ancoraggio di lavoro cade a pochi passi da dove uno già sta —
		# succede al testimone, che vive e lavora allo stesso Ritrovo — quello
		# scatto era l'unico modo in cui una presenza si spostava sotto gli occhi.
		if guarded_view.has_point(actor.global_position):
			continue
		if actor.global_position.distance_to(target) <= ARRIVAL_RADIUS:
			actor.global_position = target
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

# --- Battute di passaggio -----------------------------------------------------

func _update_ambient(player_position: Vector2, delta: float) -> void:
	var step := maxf(delta, 0.0)
	for npc_id in ambient_cooldown.keys():
		ambient_cooldown[npc_id] = maxf(0.0, float(ambient_cooldown[npc_id]) - step)
	ambient_gap = maxf(0.0, ambient_gap - step)
	# La scena del Ritrovo ha sempre la precedenza: ha già nascosto i fumetti
	# quando ha mostrato la sua riga, qui resta solo da dimenticare chi parlava.
	if conversation_active:
		_clear_ambient(false)
		return
	if not ambient_enabled:
		_clear_ambient()
		return
	if ambient_speaker != "":
		ambient_hold -= step
		var speaker := actors.get(ambient_speaker) as Area2D
		var lost := not is_instance_valid(speaker) \
			or player_position.distance_to(speaker.global_position) > AMBIENT_RELEASE
		if ambient_hold <= 0.0 or lost:
			_clear_ambient()
		return
	var chosen := ""
	var chosen_distance := AMBIENT_RELEASE
	for npc_id in actors.keys():
		var actor := actors[npc_id] as Area2D
		if not is_instance_valid(actor):
			continue
		var distance := player_position.distance_to(actor.global_position)
		# Oltre il raggio di rilascio si "dimentica" Eli: è la condizione perché
		# tornando indietro più tardi abbia di nuovo qualcosa da dire.
		if distance > AMBIENT_RELEASE:
			ambient_near[npc_id] = false
			ambient_dwell[npc_id] = 0.0
			continue
		if distance > AMBIENT_RADIUS or bool(ambient_near.get(npc_id, false)):
			continue
		if not actor.visible:
			continue
		ambient_dwell[npc_id] = float(ambient_dwell.get(npc_id, 0.0)) + step
		if float(ambient_dwell[npc_id]) < AMBIENT_DWELL:
			continue
		ambient_near[npc_id] = true
		ambient_dwell[npc_id] = 0.0
		if float(ambient_cooldown.get(npc_id, 0.0)) > 0.0:
			continue
		if distance <= chosen_distance:
			chosen = npc_id
			chosen_distance = distance
	if chosen == "" or ambient_gap > 0.0:
		return
	var line := _ambient_line(chosen)
	if line == "":
		return
	ambient_speaker = chosen
	ambient_hold = _bubble_duration(line)
	ambient_cooldown[chosen] = AMBIENT_COOLDOWN
	ambient_gap = AMBIENT_GAP
	_show_world_line(chosen, line)

func _clear_ambient(hide_bubble: bool = true) -> void:
	if ambient_speaker == "":
		return
	if hide_bubble:
		var speaker := actors.get(ambient_speaker) as Area2D
		if is_instance_valid(speaker) and speaker.has_method("hide_world_line"):
			speaker.call("hide_world_line")
	ambient_speaker = ""
	ambient_hold = 0.0

## Una riga sola: la **prima schermata** della battuta scelta. Le battute del
## catalogo sono da una a tre schermate e la prima è sempre l'aggancio — quella
## che sta in un fumetto sopra la testa senza doverla sfogliare.
func _ambient_line(npc_id: String) -> String:
	var cursor := int(ambient_cursor.get(npc_id, 0))
	var pages := _ambient_pages(npc_id, cursor)
	if pages.is_empty():
		return ""
	ambient_cursor[npc_id] = cursor + 1
	var page: Array = Array(pages[cursor % pages.size()])
	if page.is_empty():
		return ""
	return str(page[0])

## Da dove viene la battuta di passaggio. Nessun testo nuovo: sono le stesse
## parole che il personaggio direbbe parlandoci, ed è il punto — così la voce
## resta una sola, col suo tic, invece di sdoppiarsi in un registro «da fumetto».
func _ambient_pages(npc_id: String, cursor: int) -> Array:
	var resident := NpcCatalog.resident(npc_id)
	if not resident.is_empty():
		var pools: Dictionary = resident.get("battute", {})
		# Se è appena successo qualcosa, se ne parla. Una volta per persona per
		# notizia: la seconda volta sarebbe un pappagallo.
		if _news_pending(npc_id):
			var reactions := Array(pools.get("reazione", []))
			if not reactions.is_empty():
				ambient_news_seen[npc_id] = _news_tag()
				return reactions
		var idle := Array(pools.get("riempimento", []))
		var arc_pool := Array(pools.get("stadio%d" % _stage_of(npc_id), []))
		if arc_pool.is_empty():
			return idle
		if idle.is_empty():
			return arc_pool
		# Alternati: passandogli davanti due volte si sente prima il colore e poi
		# dove sta col suo arco — che è la cosa che cambia mentre il bambino impara.
		return idle if cursor % 2 == 0 else arc_pool
	var jester := NpcCatalog.bislacco(npc_id)
	if not jester.is_empty():
		return Array(jester.get("battute", []))
	var wanderer := ItinerantCatalog.itinerant(npc_id)
	if wanderer.is_empty():
		return []
	var wander_pools: Dictionary = wanderer.get("battute", {})
	var pages: Array = []
	for pool_name in ["saluto", "riempimento", str(wanderer.get("funzione", ""))]:
		if pool_name != "":
			pages.append_array(Array(wander_pools.get(pool_name, [])))
	return pages

func _stage_of(npc_id: String) -> int:
	return clampi(int(resident_stages.get(npc_id, stage)), 0, 2)

## L'identità della notizia in testa alla coda. Serve solo a ricordare chi l'ha
## già commentata: non consuma la notizia, che appartiene alla scena del Ritrovo.
func _news_tag() -> String:
	if news.is_empty():
		return ""
	var item: Dictionary = news[0]
	return "%s|%s|%s" % [
		str(item.get("type", "")), str(item.get("subject", "")), str(item.get("level", ""))]

func _news_pending(npc_id: String) -> bool:
	var tag := _news_tag()
	return tag != "" and str(ambient_news_seen.get(npc_id, "")) != tag

func _line_duration() -> float:
	var text := ""
	if conversation_index >= 0 and conversation_index < conversation_lines.size():
		text = str(Dictionary(conversation_lines[conversation_index]).get("dice", ""))
	return _bubble_duration(text)

func _bubble_duration(text: String) -> float:
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
		"ambientSpeaker": ambient_speaker,
		"ambientHold": ambient_hold,
		"ambientGap": ambient_gap,
		"residentStages": resident_stages.duplicate(true),
	}
