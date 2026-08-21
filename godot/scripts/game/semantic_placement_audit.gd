extends SceneTree

## Verifica il nuovo contratto esplorativo: il direttore non riceve una nube di
## coordinate, ma luoghi nominati dalla composizione (regioni, strumenti,
## landmark, varchi e sentieri). Ogni evento deve poter spiegare dove si trova e
## perche' quel posto e' stato scelto.

const FIXTURE_SEED := "semantic-placement-fixture"

## I due tetti del quartiere degli allenamenti, misurati sul caso peggiore dei
## ventiquattro mondi il 21 agosto 2026. Prima dell'ancora erano undici
## quartieri e 1993 unita' di raggio.
const QUARTIERI_MASSIMI := 6
const RAGGIO_MASSIMO := 2300.0

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
		var filo: Array = []
		var filo_cluster: Array = []
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
			elif str(event.get("kind", "")) == "practice":
				filo.append(event_position)
				filo_cluster.append(str(event.get("locationCluster", "")))
		assert(gate_clusters.size() >= 3,
			"mondo %d: gate concentrato in %d sole costellazioni" % [level, gate_clusters.size()])

		# **Il quartiere degli allenamenti.** (21 agosto 2026)
		#
		# Gli eventi del gate devono stare in costellazioni diverse — e' l'assert
		# qui sopra, e serve a offrire una scelta di rotta. Le palestre vogliono
		# l'opposto: sono un **servizio**, e undici servizi sparsi su duemila
		# unita' non si usano. Segnalazione di gioco: «icone sparse a caso».
		#
		# **La misura giusta e' il numero di quartieri, non il passo fra due
		# stazioni.** La prima stesura di questa guardia contava il passo, ed era
		# sbagliata: alzare il premio di vicinanza non lo accorcia, perche' il
		# collo di bottiglia e' la capienza dei luoghi. Quello che l'ancora
		# ottiene davvero e' raccogliere le palestre in **meno quartieri**, e
		# quello e' anche cio' che un bambino puo' imparare a memoria.
		#
		# I due tetti sono il caso peggiore misurato sui 24 mondi il giorno in cui
		# la guardia e' nata. Si abbassano, non si alzano.
		assert(filo.size() >= 6,
			"mondo %d: solo %d palestre, non c'e' un quartiere da misurare" % [level, filo.size()])
		var quartieri: Dictionary = {}
		for cluster_data in filo_cluster:
			quartieri[str(cluster_data)] = true
		assert(quartieri.size() <= QUARTIERI_MASSIMI,
			"mondo %d: le palestre finiscono in %d quartieri diversi (tetto %d): sono tornate sparse" % [
				level, quartieri.size(), QUARTIERI_MASSIMI])
		var centro := Vector2.ZERO
		for punto in filo:
			centro += Vector2(punto)
		centro /= float(filo.size())
		var raggio := 0.0
		for punto in filo:
			raggio = maxf(raggio, centro.distance_to(Vector2(punto)))
		assert(raggio <= RAGGIO_MASSIMO,
			"mondo %d: il gruppo delle palestre ha raggio %.0f (tetto %.0f)" % [
				level, raggio, RAGGIO_MASSIMO])

	print("Semantic placement audit OK - 24 mondi: luoghi nominati, costellazioni, segnali di scoperta e filo delle palestre")
	quit(0)
