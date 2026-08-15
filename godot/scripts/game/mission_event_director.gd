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
##  - i formati non si ripetono tra eventi consecutivi della stessa materia;
##    le palestre di materie diverse percorrono invece la propria rotazione completa;
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
const SEMANTIC_MIN_SPACING := 176.0
const SEMANTIC_MAX_SITE_OFFSET := 420.0

## Quanti eventi della materia DEL MONDO popolano il mondo. Non è più il requisito
## del gate — dal 30 luglio il livello non conta le missioni — ma quanto la materia
## ospite è presente: è la sua dominanza, resa in numero di POI.
const HOST_EVENTS := 5

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

## Porta il POI sul bordo della strada più vicina. Gli esercizi restano
## raggiungibili e leggibili dalla rete principale, senza occupare la corsia.
static func _beside_path(composition: WorldCompositionData, target: Vector2, index: int) -> Vector2:
	if composition == null:
		return target
	var best_point := target
	var best_tangent := Vector2.RIGHT
	var best_width := 64.0
	var best_distance := INF
	for path in composition.paths:
		var points: PackedVector2Array = path.get("points", PackedVector2Array())
		for segment in range(maxi(0, points.size() - 1)):
			var a := points[segment]
			var b := points[segment + 1]
			var ab := b - a
			var amount := clampf((target - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
			var candidate := a + ab * amount
			var distance := target.distance_squared_to(candidate)
			if distance < best_distance:
				best_distance = distance
				best_point = candidate
				best_tangent = ab.normalized()
				best_width = float(path.get("width", 64.0))
	var normal := Vector2(-best_tangent.y, best_tangent.x)
	if posmod(index, 2) == 1:
		normal = -normal
	var offset := best_width * 0.5 + 112.0
	var result := best_point + normal * offset
	# Se il lato scelto cade in acqua, prova l'altro bordo della stessa strada.
	if composition.raw_water_weight(result) > 0.28:
		var opposite := best_point - normal * offset
		if composition.raw_water_weight(opposite) < composition.raw_water_weight(result):
			result = opposite
	return result

static func _inside_playfield(position: Vector2, ship: Vector2, safe_radius: float, half_extent: float) -> Vector2:
	var result := position
	var from_ship := result - ship
	if from_ship.length() < safe_radius + SHIP_MARGIN:
		var direction := from_ship.normalized() if from_ship.length() > 0.001 else Vector2.DOWN
		result = ship + direction * (safe_radius + SHIP_MARGIN)
	result.x = clampf(result.x, ship.x - half_extent, ship.x + half_extent)
	result.y = clampf(result.y, ship.y - half_extent, ship.y + half_extent)
	return result

static func _distributed_position(
	rng: RandomNumberGenerator,
	composition: WorldCompositionData,
	spawn: Vector2,
	ship: Vector2,
	safe_radius: float,
	index: int,
	t: float,
	min_r: float,
	max_r: float,
	half_extent: float,
	events: Array
) -> Vector2:
	var candidate := spawn
	for attempt in range(10):
		var radial := _placed(
			rng, spawn, ship, safe_radius,
			index + attempt * 11, fmod(t + float(attempt) * 0.137, 1.0),
			min_r, max_r, half_extent)
		candidate = _inside_playfield(
			_beside_path(composition, radial, index + attempt),
			ship, safe_radius, half_extent)
		var separated := true
		for previous_data in events:
			var previous: Vector2 = (previous_data as Dictionary).get("position", Vector2.INF)
			if candidate.distance_to(previous) < 176.0:
				separated = false
				break
		if separated:
			return candidate
	return candidate

## Sceglie un LUOGO prima di scegliere una coordinata. I socket arrivano dalla
## composizione autorata e descrivono affordance (archivio, strumento, sentiero,
## varco, landmark); il formato e la materia dell'evento dichiarano invece che
## cosa cercano. La casualita' risolve soltanto pareggi e piccoli scarti locali.
##
## Il ritorno conserva anche l'identita' del posto: scena, bussola e audit non
## devono piu' dedurre a posteriori perche' una prova sia finita li'.
static func _semantic_placement(
	rng: RandomNumberGenerator,
	composition: WorldCompositionData,
	spawn: Vector2,
	ship: Vector2,
	safe_radius: float,
	half_extent: float,
	event_kind: String,
	format: String,
	subject: String,
	event_index: int,
	events: Array,
	fallback_t: float,
	fallback_min_r: float,
	fallback_max_r: float
) -> Dictionary:
	if composition == null or composition.activity_sockets.is_empty():
		return _fallback_placement(
			rng, composition, spawn, ship, safe_radius, half_extent,
			event_index, events, fallback_t, fallback_min_r, fallback_max_r)

	var wanted := _event_place_tags(event_kind, format, subject)
	var socket_usage: Dictionary = {}
	var cluster_usage: Dictionary = {}
	for previous_data in events:
		var previous: Dictionary = previous_data
		var socket_id := str(previous.get("locationSocket", ""))
		var cluster_id := str(previous.get("locationCluster", ""))
		if not socket_id.is_empty():
			socket_usage[socket_id] = int(socket_usage.get(socket_id, 0)) + 1
		if not cluster_id.is_empty():
			cluster_usage[cluster_id] = int(cluster_usage.get(cluster_id, 0)) + 1

	var ranked: Array = []
	for socket_data in composition.activity_sockets:
		var socket: Dictionary = socket_data
		var socket_id := str(socket.get("id", ""))
		var cluster_id := str(socket.get("cluster", socket_id))
		var role := str(socket.get("role", "region"))
		var tags: Array = socket.get("tags", [])
		var used := int(socket_usage.get(socket_id, 0))
		var capacity := maxi(1, int(socket.get("capacity", 1)))
		var score := 0.0
		for tag_data in wanted:
			if tags.has(str(tag_data)):
				score += 34.0
		score += _role_score(event_kind, role)
		# Le prove dello stesso giro formano costellazioni, non un unico mucchio:
		# riusare un quartiere e' lecito, saturare sempre lo stesso no.
		score -= float(cluster_usage.get(cluster_id, 0)) * 18.0
		score -= float(used) * 58.0
		if used >= capacity:
			score -= 180.0 + float(used - capacity) * 70.0
		# Il primo incontro deve essere leggibile senza attraversare tutto il
		# mondo; quelli successivi possono spingersi verso regioni piu' profonde.
		var depth := float(socket.get("routeDepth", 0.5))
		if event_index == 0:
			score += maxf(0.0, 1.0 - depth) * 72.0
		elif event_kind == "minimission":
			score += minf(depth, 1.0) * 34.0
		# Il seed varia la scelta solo fra luoghi gia' sensati.
		score += rng.randf_range(-7.0, 7.0)
		ranked.append({"score": score, "socket": socket})
	ranked.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))

	for ranked_data in ranked:
		var socket: Dictionary = Dictionary(ranked_data)["socket"]
		var socket_id := str(socket.get("id", "semantic-site"))
		var used := int(socket_usage.get(socket_id, 0))
		var anchor: Vector2 = socket.get("position", spawn)
		for local_attempt in range(5):
			var orbit_index := event_index + used * 3 + local_attempt
			var candidate := anchor
			if str(socket.get("role", "")) != "crossing":
				var radius := 28.0 + float(used + local_attempt) * 74.0
				var angle := GOLDEN_ANGLE * float(orbit_index) + rng.randf_range(-0.18, 0.18)
				var target := anchor + Vector2(cos(angle), sin(angle)) * radius
				candidate = _beside_path(composition, target, orbit_index)
				# Un nome semantico non deve diventare un'etichetta finta: se la
				# strada porterebbe la prova fuori vista dal luogo, prova un altro
				# socket invece di dichiararla ancora parte di questo sito.
				if candidate.distance_to(anchor) > SEMANTIC_MAX_SITE_OFFSET:
					continue
			candidate = _inside_playfield(candidate, ship, safe_radius, half_extent)
			if composition.raw_water_weight(candidate) > 0.32:
				continue
			if composition.is_protected(candidate, 18.0):
				continue
			if not _separated_from_events(candidate, events, SEMANTIC_MIN_SPACING):
				continue
			return {
				"position": candidate,
				"locationSocket": socket_id,
				"locationCluster": str(socket.get("cluster", socket_id)),
				"locationRole": str(socket.get("role", "region")),
				"discoveryCue": str(socket.get("visibility", "proximity")),
				"placementModel": "semantic",
			}

	return _fallback_placement(
		rng, composition, spawn, ship, safe_radius, half_extent,
		event_index, events, fallback_t, fallback_min_r, fallback_max_r)

static func _fallback_placement(
	rng: RandomNumberGenerator,
	composition: WorldCompositionData,
	spawn: Vector2,
	ship: Vector2,
	safe_radius: float,
	half_extent: float,
	event_index: int,
	events: Array,
	t: float,
	min_r: float,
	max_r: float
) -> Dictionary:
	return {
		"position": _distributed_position(
			rng, composition, spawn, ship, safe_radius, event_index, t,
			min_r, max_r, half_extent, events),
		"locationSocket": "",
		"locationCluster": "fallback",
		"locationRole": "route",
		"discoveryCue": "proximity",
		"placementModel": "radial-fallback",
	}

static func _separated_from_events(position: Vector2, events: Array, spacing: float) -> bool:
	for previous_data in events:
		var previous: Vector2 = (previous_data as Dictionary).get("position", Vector2.INF)
		if position.distance_to(previous) < spacing:
			return false
	return true

static func _role_score(event_kind: String, role: String) -> float:
	if event_kind == "enigma":
		return 270.0 if role == "crossing" else 92.0 if role == "landmark" else 20.0
	if event_kind == "minimission":
		return 86.0 if role == "instrument" or role == "region" else 24.0
	if event_kind == "practice":
		return 78.0 if role == "instrument" else 46.0 if role == "trail" else 18.0
	return 62.0 if role == "region" else 50.0 if role == "instrument" else 22.0

static func _event_place_tags(event_kind: String, format: String, subject: String) -> Array:
	var tags: Array = []
	match event_kind:
		"enigma":
			tags.append_array(["crossing", "traversal", "mystery", "landmark"])
		"minimission":
			tags.append_array(["worksite", "machine", "living", "field"])
		"practice":
			tags.append_array(["instrument", "exploration"])
		_:
			tags.append_array(["region", "worksite", "observation"])
	match format:
		"numeric_input":
			tags.append_array(["measurement", "sequence"])
		"matching":
			tags.append_array(["matching", "archive", "classification", "sound"])
		"ordering":
			tags.append_array(["ordering", "sequence", "route", "machine"])
		"classification":
			tags.append_array(["classification", "archive", "living"])
		"graph":
			tags.append_array(["graph", "measurement", "navigation"])
		"circuit":
			tags.append_array(["circuit", "machine", "energy"])
		"cycle":
			tags.append_array(["cycle", "living", "sequence"])
		"code_debug":
			tags.append_array(["machine", "sequence", "archive"])
		_:
			tags.append("observation")
	match subject:
		"matematica":
			tags.append_array(["measurement", "sequence"])
		"italiano", "inglese", "latino":
			tags.append_array(["language", "archive"])
		"coding", "logica":
			tags.append_array(["sequence", "machine"])
		"fisica", "elettronica":
			tags.append_array(["measurement", "machine", "circuit"])
		"musica":
			tags.append_array(["sound", "sequence"])
		"geografia":
			tags.append_array(["navigation", "graph"])
		"scienze":
			tags.append_array(["living", "cycle", "classification"])
		"storia":
			tags.append_array(["history", "archive", "ordering"])
	return tags

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

# Suggerisce un argomento: prima i topic dovuti (ripasso), poi i deboli, poi il
# `fallback` (per gli eventi del focus: gli argomenti che la LEZIONE del mondo
# promette). `slot` ruota tra i candidati per non insistere sullo stesso.
#
# Il fallback non è un dettaglio: senza, un evento del focus senza ripasso in
# sospeso pescava liberamente da tutto il banco della materia, anche fuori dalla
# lezione. Con undici eventi di altre materie accanto, la quota di nodi sugli
# argomenti promessi scendeva sotto il minimo didattico (misurato: 13% al mondo 2,
# 10% al 16, contro un minimo del 15% — `content_depth_audit`).
static func _topic_hint(
	due_topics: Array, weak_topics: Array, slot: int, fallback: Array = []
) -> String:
	if not due_topics.is_empty():
		return str(due_topics[slot % due_topics.size()])
	if not weak_topics.is_empty():
		return str(weak_topics[slot % weak_topics.size()])
	if not fallback.is_empty():
		return str(fallback[slot % fallback.size()])
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

	var missions_required := int(context.get("missionsRequired", HOST_EVENTS))
	var weak_topics: Array = context.get("weakTopics", [])
	var due_topics: Array = context.get("dueTopics", [])
	var recent_formats: Array = context.get("recentFormats", [])

	var rng := _make_rng(world_seed, level)
	var composition := WorldCompositionGenerator.generate(world_seed, profile)
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
	# **La minimissione prende il POSTO del primo evento-gate.** (7 agosto 2026)
	#
	# Direttiva esplicita del committente — «accolgo sostituire e non aggiungere»
	# — e la misura le dava ragione: la campagna sta a 21,1 ore e il collaudo
	# l'aveva già definita faticosa. Se l'incarico si fosse aggiunto agli eventi
	# esistenti avremmo risposto a «è noioso» con «è più lungo», che è
	# esattamente l'errore che ha prodotto quel verdetto.
	#
	# Quindi: l'incarico prende l'**ultimo** slot-gate, che è sempre una missione,
	# e ne eredita le tre campate. Il conto degli esercizi del mondo non cambia
	# di uno.
	#
	# **Perché l'ultimo e non il primo.** Il primo tentativo prendeva lo slot 0,
	# che è un enigma quando il mondo ne ha uno: nei mondi con un enigma solo
	# l'incarico lo cancellava, e il mondo perdeva una meccanica invece di
	# guadagnarne una. Se ne sono accorti `enigma_cooldown_audit` e
	# `enigma_scene_audit`, che pretendono un enigma vivo in ogni mondo — ed
	# è una pretesa giusta: l'enigma e l'incarico si assomigliano nel gesto ma
	# raccontano due cose diverse, e servono tutti e due.
	var mini_level := level if MinimissionCatalog.ha(level) else -1
	var mini_slot := gate_total - 1
	var mini_campate := 3
	for i in range(gate_total):
		var kind := "enigma" if i < enigma_count else "mission"
		if i == mini_slot and mini_level > 0:
			kind = "minimission"
		var t := float(i) / float(maxi(1, gate_total - 1))
		var fmt := _next_format(formats, fmt_index, last_format, recent_formats)
		last_format = fmt
		fmt_index += 1
		var placement := _semantic_placement(
			rng, composition, spawn, ship, safe_radius, half_extent,
			kind, fmt, subject, i, events, t, GATE_MIN_R, GATE_MAX_R)
		var voce := {
			"id": "evt-%d-gate-%d" % [level, i],
			"kind": kind,
			"subject": subject,
			"format": fmt,
			# Gli eventi del focus restano sugli argomenti che il mondo PROMETTE di
			# insegnare: è questo che rende la materia dominante davvero dominante.
			"topicHint": _topic_hint(
				due_topics, weak_topics, i, Array(context.get("lessonTopics", []))),
			"position": placement["position"],
			"locationSocket": placement["locationSocket"],
			"locationCluster": placement["locationCluster"],
			"locationRole": placement["locationRole"],
			"discoveryCue": placement["discoveryCue"],
			"placementModel": placement["placementModel"],
			"navigationSector": posmod(i, 6),
			"countsForGate": true,
			"reachable": true,
		}
		if kind == "minimission":
			# La forma e il testo vengono dal catalogo autoriale; qui viaggiano
			# solo i pochi campi che servono a disegnare il POI e ad aprire la
			# sessione, così la scena non deve conoscere il catalogo.
			var incarico := MinimissionCatalog.incarico(mini_level)
			voce["forma"] = incarico["forma"]
			voce["titolo"] = incarico["titolo"]
			voce["gradoRichiesto"] = incarico["gradoRichiesto"]
			voce["campate"] = mini_campate
		events.append(voce)

	# --- Eventi di VARIETÀ: uno per ogni ALTRA materia -------------------------
	# Decisione dell'utente (30 luglio): **un mondo è un LIVELLO, non una materia.**
	# Ogni mondo ospita missioni di tutte e dodici le materie; quella del focus
	# resta dominante, perché è l'unica che conta per il gate ed è quella che dà
	# identità, lezione e trasformazione ambientale al mondo.
	#
	# Non tocca la progressione: `countsForGate: false`, e `record_practice` non
	# chiama `add_mission`. Allenano padronanza e ripasso, non aprono l'apparato.
	#
	# Perché conta oltre alla varietà percepita: sette missioni di fila della stessa
	# materia sono pratica BLOCCATA, inferiore a quella alternata per ritenzione e
	# trasferimento. E il ripasso spaziato può finalmente far riemergere un
	# argomento debole di un'ALTRA materia: prima il filtro lo escludeva sempre,
	# quindi delle tabelline arrugginite al mondo 12 non tornavano mai.
	var reach := float(profile["eventPools"].get("reachRadius", 1900.0))
	var others := other_subjects(subject)
	for j in others.size():
		var other := str(others[j])
		var idx := gate_total + j
		var t2 := 0.55 + 0.45 * float(j) / float(maxi(1, others.size()))
		# I formati seguono la materia dell'EVENTO, non quella del mondo: una prova
		# di latino non può usare il repertorio della matematica.
		var giro := int(Dictionary(context.get("practiceRound", {})).get(other, 0))
		# La tavolozza viene dal generatore reale; il giro cambia indice, cosi una
		# palestra completata riappare altrove con una meccanica diversa.
		var other_formats := MinigameManager.runtime_formats_for(other, level)
		if other_formats.is_empty():
			other_formats = WorldProfileCatalog.formats_for(other)
		# Materie diverse possono condividere la stessa meccanica consecutivamente:
		# evitarlo qui saltava per sempre una casella della rotazione di ciascuna
		# materia. L'indice del giro percorre invece l'intera tavolozza.
		var fmt2 := str(other_formats[posmod(idx + giro, other_formats.size())])
		last_format = fmt2
		fmt_index += 1
		# Il GIRO di pratica: quante palestre di questa materia sono già state
		# chiuse in questo mondo. Entra nell'identificativo — così la palestra
		# nuova non è quella vecchia — e nella posizione, perché deve nascere
		# ALTROVE: ritrovarla nello stesso punto sarebbe la stessa location, e la
		# segnalazione di gioco del 6 agosto nasce proprio da lì.
		var placement := _semantic_placement(
			rng, composition, spawn, ship, safe_radius, half_extent,
			"practice", fmt2, other, idx + giro * 5, events, t2,
			GATE_MAX_R, reach + 350.0)
		events.append({
			"id": "evt-%d-practice-%s-r%d" % [level, other, giro],
			"kind": "practice",
			"subject": other,
			"format": fmt2,
			"topicHint": _topic_hint(
				Array(Dictionary(context.get("dueBySubject", {})).get(other, [])),
				Array(Dictionary(context.get("weakBySubject", {})).get(other, [])),
				idx),
			"position": placement["position"],
			"locationSocket": placement["locationSocket"],
			"locationCluster": placement["locationCluster"],
			"locationRole": placement["locationRole"],
			"discoveryCue": placement["discoveryCue"],
			"placementModel": placement["placementModel"],
			"navigationSector": posmod(idx, 6),
			"countsForGate": false,
			"reachable": spawn.distance_to(placement["position"] as Vector2) <= reach,
		})

	return events

## Le altre undici materie, nell'ordine del ciclo a partire da quella successiva
## al focus. Mondi diversi presentano quindi le altre materie in ordini diversi,
## senza introdurre casualità: il determinismo per seed resta un contratto.
static func other_subjects(focus: String) -> Array:
	var cycle: Array = ApparatusConfig.SUBJECT_CYCLE
	var start := cycle.find(focus)
	if start < 0:
		start = 0
	var out: Array = []
	for offset in range(1, cycle.size()):
		out.append(str(cycle[(start + offset) % cycle.size()]))
	return out

# Quanti eventi del focus contano per il gate ENTRO distanza raggiungibile.
# Serve al controllo di non-blocco (deve essere ≥ missionsRequired).
static func reachable_gate_events(events: Array, subject: String) -> int:
	var count := 0
	for e in events:
		if bool(e.get("countsForGate", false)) and bool(e.get("reachable", false)) and str(e.get("subject", "")) == subject:
			count += 1
	return count
