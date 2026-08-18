extends SceneTree

## Verifica il nuovo contratto esplorativo: il direttore non riceve una nube di
## coordinate, ma luoghi nominati dalla composizione (regioni, strumenti,
## landmark, varchi e sentieri). Ogni evento deve poter spiegare dove si trova e
## perche' quel posto e' stato scelto.

const FIXTURE_SEED := "semantic-placement-fixture"

func _init() -> void:
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var composition := WorldCompositionGenerator.generate(FIXTURE_SEED, profile)
		assert(composition.activity_sockets.size() >= 6,
			"mondo %d senza abbastanza luoghi di attivita'" % level)

		var sockets_by_id: Dictionary = {}
		var roles: Dictionary = {}
		for socket_data in composition.activity_sockets:
			var socket: Dictionary = socket_data
			var socket_id := str(socket.get("id", ""))
			assert(not socket_id.is_empty(), "mondo %d: socket senza id" % level)
			assert(not sockets_by_id.has(socket_id),
				"mondo %d: socket duplicato %s" % [level, socket_id])
			assert(not Array(socket.get("tags", [])).is_empty(),
				"mondo %d: socket %s senza affordance" % [level, socket_id])
			assert(not str(socket.get("cluster", "")).is_empty(),
				"mondo %d: socket %s senza costellazione" % [level, socket_id])
			assert(int(socket.get("capacity", 0)) > 0,
				"mondo %d: socket %s senza capacita'" % [level, socket_id])
			sockets_by_id[socket_id] = socket
			roles[str(socket.get("role", ""))] = true
		assert(roles.has("region") and roles.has("instrument") and roles.has("trail"),
			"mondo %d: grammatica di luoghi incompleta" % level)

		var context := {
			"missionsRequired": MissionEventDirector.HOST_EVENTS,
			"weakTopics": ["fragile"],
			"dueTopics": ["ripasso"],
			"recentFormats": [],
		}
		var events := MissionEventDirector.plan(profile, context, FIXTURE_SEED)
		var gate_clusters: Dictionary = {}
		for event_data in events:
			var event: Dictionary = event_data
			assert(str(event.get("placementModel", "")) == "semantic",
				"mondo %d: %s e' ricaduto nel posizionamento radiale" % [level, str(event.get("id", ""))])
			var socket_id := str(event.get("locationSocket", ""))
			assert(sockets_by_id.has(socket_id),
				"mondo %d: evento collegato a un luogo inesistente %s" % [level, socket_id])
			var socket: Dictionary = sockets_by_id[socket_id]
			assert(str(event.get("locationCluster", "")) == str(socket.get("cluster", "")),
				"mondo %d: costellazione persa nel passaggio director-scena" % level)
			assert(str(event.get("locationRole", "")) == str(socket.get("role", "")),
				"mondo %d: ruolo del luogo incoerente" % level)
			assert(not str(event.get("discoveryCue", "")).is_empty(),
				"mondo %d: luogo senza segnale di scoperta" % level)
			var event_position: Vector2 = event.get("position", Vector2.INF)
			var socket_position: Vector2 = socket.get("position", Vector2.ZERO)
			var site_offset := event_position.distance_to(socket_position)
			assert(site_offset <= MissionEventDirector.SEMANTIC_MAX_SITE_OFFSET + 1.0,
				"mondo %d: evento troppo lontano dal luogo dichiarato" % level)
			if bool(event.get("countsForGate", false)):
				gate_clusters[str(event.get("locationCluster", ""))] = true
		assert(gate_clusters.size() >= 3,
			"mondo %d: gate concentrato in %d sole costellazioni" % [level, gate_clusters.size()])

	print("Semantic placement audit OK - 24 mondi: luoghi nominati, costellazioni e segnali di scoperta")
	quit(0)
