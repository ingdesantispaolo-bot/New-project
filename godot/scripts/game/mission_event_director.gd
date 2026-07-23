class_name MissionEventDirector
extends RefCounted

## Direttore deterministico degli eventi di un mondo (O-P1). Dato un `WorldProfile`
## e lo stato del giocatore, sceglie GLI EVENTI che popolano il mondo: tappe di
## missione, eventi liberi di pratica ed enigmi persistenti — con posizione,
## formato e argomento. È un contratto READ-ONLY per Codex: il visuale posiziona e
## rende gli eventi ma non decide materia, conteggi o ricompense.
##
## Garanzie (Gate Opus P1):
##  - stesso seed e stesso stato → stessi eventi (determinismo);
##  - il focus del livello ha SEMPRE ≥ `missionsRequired` eventi che contano per il
##    gate ENTRO distanza raggiungibile (nessun blocco della progressione);
##  - nessun evento cade dentro `shipEntrance.safeRadius` (zona nave protetta);
##  - i formati non si ripetono tra eventi consecutivi ed evitano quelli recenti;
##  - un minigioco/pratica aggiorna mastery e ripasso ma NON il conteggio del gate.
##
## Un evento:
##   { id, kind: "mission"|"practice"|"enigma", subject, format, topicHint,
##     position: Vector2, countsForGate: bool, reachable: bool }

const GOLDEN_ANGLE := 2.39996323   # distribuzione angolare uniforme (spirale aurea)
const SHIP_MARGIN := 60.0          # scarto oltre il raggio nave
const GATE_MIN_R := 420.0          # raggio min di un evento-gate dallo spawn
const GATE_MAX_R := 1100.0         # raggio max di un evento-gate dallo spawn
const GATE_SURPLUS := 2            # eventi-gate oltre il minimo (offre scelta)
const PRACTICE_COUNT := 3          # eventi liberi di pratica (non contano al gate)

# Semina deterministica dal seed del mondo + livello.
static func _make_rng(world_seed: String, level: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s::mission-events::%d" % [world_seed, level]))
	return rng

# Posizione deterministica attorno allo spawn, garantita FUORI dalla zona nave.
# `t` (0..1) scala il raggio nella banda [min,max]; l'angolo segue la spirale.
static func _placed(rng: RandomNumberGenerator, spawn: Vector2, ship: Vector2, safe_radius: float, index: int, t: float, min_r: float, max_r: float, half_extent: float) -> Vector2:
	var ang := GOLDEN_ANGLE * float(index) + rng.randf_range(-0.12, 0.12)
	var r := lerpf(min_r, max_r, clampf(t, 0.0, 1.0)) + rng.randf_range(-70.0, 70.0)
	var pos := spawn + Vector2(cos(ang), sin(ang)) * r
	# Fuori dalla zona nave: se troppo vicino all'ingresso, spingi lungo il raggio.
	var from_ship := pos - ship
	if from_ship.length() < safe_radius + SHIP_MARGIN:
		var dir := from_ship.normalized() if from_ship.length() > 0.001 else Vector2.DOWN
		pos = ship + dir * (safe_radius + SHIP_MARGIN)
	# Dentro l'area giocabile.
	pos.x = clampf(pos.x, ship.x - half_extent, ship.x + half_extent)
	pos.y = clampf(pos.y, ship.y - half_extent, ship.y + half_extent)
	return pos

# Sceglie un formato dalla pool evitando il precedente e quelli recenti (se
# possibile), in modo deterministico (avanza un indice).
static func _next_format(formats: Array, used_index: int, last_format: String, recent: Array) -> String:
	var n := formats.size()
	if n == 0:
		return "multiple_choice"
	# Prima passata: evita last_format e recent. Seconda: evita solo last_format.
	for pass_strict in [true, false]:
		for step in range(n):
			var f := str(formats[(used_index + step) % n])
			if f == last_format:
				continue
			if pass_strict and recent.has(f):
				continue
			return f
	return str(formats[used_index % n])

# Suggerisce un argomento: prima i topic dovuti (ripasso), poi i deboli, altrimenti
# nessun vincolo. `slot` ruota tra i candidati per non insistere sullo stesso.
static func _topic_hint(due_topics: Array, weak_topics: Array, slot: int) -> String:
	if not due_topics.is_empty():
		return str(due_topics[slot % due_topics.size()])
	if not weak_topics.is_empty():
		return str(weak_topics[slot % weak_topics.size()])
	return ""

# Pianifica gli eventi del mondo. `context` (tutti opzionali):
#   missionsRequired:int, weakTopics:Array, dueTopics:Array, recentFormats:Array
static func plan(profile: Dictionary, context: Dictionary, world_seed: String) -> Array:
	var level := int(profile["level"])
	var subject := str(profile["learningFocus"]["subject"])
	var formats: Array = profile["eventPools"]["formats"]
	var grammar: Dictionary = profile["missionGrammar"]
	var ship_entrance: Dictionary = profile["shipEntrance"]
	var ship: Vector2 = ship_entrance["position"]
	var safe_radius := float(ship_entrance["safeRadius"])
	var spawn: Vector2 = profile["spawn"]
	var half_extent := float(profile.get("worldHalfExtent", 2200.0))

	var missions_required := int(context.get("missionsRequired", ApparatusConfig.level_gate(level).get("missionsRequired", 5)))
	var weak_topics: Array = context.get("weakTopics", [])
	var due_topics: Array = context.get("dueTopics", [])
	var recent_formats: Array = context.get("recentFormats", [])

	var rng := _make_rng(world_seed, level)
	var events: Array = []
	var last_format := ""
	var fmt_index := 0

	# --- Eventi che CONTANO per il gate (focus del livello) --------------------
	# Distribuzione mission/enigma dalla grammatica: almeno un enigma persistente
	# se ammesso, il resto missioni-tappa. Tutti raggiungibili e fuori zona nave.
	var gate_total := missions_required + GATE_SURPLUS
	var enigma_weight := int(grammar.get("enigma", 0))
	var enigma_count := 0
	if enigma_weight > 0:
		enigma_count = clampi(int(round(float(gate_total) * float(enigma_weight) / float(maxi(1, int(grammar.get("mission", 3)) + enigma_weight)))), 1, maxi(1, gate_total - missions_required + 1))
	for i in range(gate_total):
		var kind := "enigma" if i < enigma_count else "mission"
		var t := float(i) / float(maxi(1, gate_total - 1))
		var fmt := _next_format(formats, fmt_index, last_format, recent_formats)
		last_format = fmt
		fmt_index += 1
		events.append({
			"id": "evt-%d-gate-%d" % [level, i],
			"kind": kind,
			"subject": subject,
			"format": fmt,
			"topicHint": _topic_hint(due_topics, weak_topics, i),
			"position": _placed(rng, spawn, ship, safe_radius, i, t, GATE_MIN_R, GATE_MAX_R, half_extent),
			"countsForGate": true,
			"reachable": true,
		})

	# --- Eventi liberi di PRATICA (non contano per il gate) --------------------
	# Ripasso ripetibile del focus; posizionati più larghi (alcuni oltre la
	# distanza raggiungibile: sono deviazioni opzionali, marcate `reachable`).
	var reach := float(profile["eventPools"].get("reachRadius", 1900.0))
	for j in range(PRACTICE_COUNT):
		var idx := gate_total + j
		var t2 := 0.6 + 0.5 * float(j) / float(maxi(1, PRACTICE_COUNT))
		var fmt2 := _next_format(formats, fmt_index, last_format, recent_formats)
		last_format = fmt2
		fmt_index += 1
		var pos: Vector2 = _placed(rng, spawn, ship, safe_radius, idx, t2, GATE_MAX_R, reach + 350.0, half_extent)
		events.append({
			"id": "evt-%d-practice-%d" % [level, j],
			"kind": "practice",
			"subject": subject,
			"format": fmt2,
			"topicHint": _topic_hint(due_topics, weak_topics, idx),
			"position": pos,
			"countsForGate": false,
			"reachable": spawn.distance_to(pos) <= reach,
		})

	return events

# Quanti eventi del focus contano per il gate ENTRO distanza raggiungibile.
# Serve al controllo di non-blocco (deve essere ≥ missionsRequired).
static func reachable_gate_events(events: Array, subject: String) -> int:
	var count := 0
	for e in events:
		if bool(e.get("countsForGate", false)) and bool(e.get("reachable", false)) and str(e.get("subject", "")) == subject:
			count += 1
	return count
