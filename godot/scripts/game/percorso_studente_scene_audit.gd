extends SceneTree

## **La guardia che dimostra il collegamento.** (10 settembre 2026)
##
## `percorso_studente_audit` controlla i due moduli puri: nomi unici, sguardo
## deterministico, frasi senza parole di registro. Tutto vero, e non basta — il
## difetto ricorrente di questo progetto e' esattamente **contenuto scritto e mai
## collegato**, cioe' dati verdi che nessuno legge in gioco. Il caso piu' caro sta
## proprio qui: `locationRole` e `locationCluster` viaggiano fino al payload
## dell'area da mesi, e fuori dagli audit non li apriva nessuno.
##
## Questa guardia costruisce il mondo vero e pretende tre cose che si vedono
## soltanto a scena montata:
##
##   1. la targhetta di un punto d'interesse porta **il nome del posto**, non la
##      voce di registro `PRATICA · MATEMATICA`;
##   2. `_cose_del_mondo()` — cio' che lo sguardo puo' nominare — non e' vuoto e
##      non contiene cose senza nome;
##   3. lo sguardo, chiamato in mezzo al mondo con la striscia libera, **scrive
##      davvero** una riga nell'HUD.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("percorso-studente-scene")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 1
	request["accessibility"] = {"highContrast": false, "reducedMotion": true}
	request["accessibilityExplicit"] = true
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	root.add_child(world)
	await process_frame
	await process_frame

	# --- 1 · le targhette portano un nome ---------------------------------
	var targhette := 0
	for nodo in world.get_tree().get_nodes_in_group("world_interactable"):
		if not (nodo is Node2D):
			continue
		var caption := (nodo as Node).get_node_or_null("EventCaption") as Label
		if caption == null:
			continue
		targhette += 1
		var testo := str(caption.text)
		var carico: Dictionary = (nodo as Node).get_meta("payload", {})
		var atteso := NomiDeiLuoghi.sul_cartello(str(carico.get("placeName", "")))
		assert(not atteso.is_empty(),
			"un punto d'interesse e' arrivato alla scena senza nome del posto")
		assert(testo == atteso,
			"la targhetta dice «%s» e il payload «%s»: due nomi per un posto" % [testo, atteso])
		for parola in NomiDeiLuoghi.PAROLE_DEL_REGISTRO:
			assert(not testo.to_lower().contains(str(parola)),
				"la targhetta e' tornata una voce di registro: «%s»" % testo)
	assert(targhette >= 6,
		"solo %d targhette nel mondo 1: la scena non ha costruito i punti d'interesse" % targhette)

	# --- 1bis · il nome ha una distanza di lettura -------------------------
	#
	# La grammatica del luogo dev'essere arrivata fino all'etichetta, e
	# l'etichetta deve davvero spegnersi da lontano: e' la differenza fra un
	# paesaggio e una mappa con gli spilli, e non si vede nei dati.
	var etichette := world.get_tree().get_nodes_in_group("targhetta_del_luogo")
	assert(etichette.size() == targhette,
		"%d targhette costruite ma %d nel gruppo della distanza di lettura" % [
			targhette, etichette.size()])
	var lontano := 0
	for nodo in etichette:
		var etichetta := nodo as CanvasItem
		var cue := str((etichetta as Node).get_meta("cue", ""))
		assert(ScopertaLuogo.LETTURA.has(cue),
			"targhetta senza grammatica di scoperta: «%s»" % cue)
		var posto := etichetta.get_parent() as Node2D
		assert(posto != null, "targhetta senza posto sotto")
		var soglia := ScopertaLuogo.distanza_di_lettura(cue)
		if ScopertaLuogo.opacita_del_nome(cue, soglia + ScopertaLuogo.DISSOLVENZA + 1.0) <= 0.0:
			lontano += 1
	assert(lontano == etichette.size(),
		"%d targhette su %d restano leggibili oltre la loro distanza" % [
			etichette.size() - lontano, etichette.size()])

	# E il giro che le accende esiste e fa il suo mestiere: da lontanissimo
	# tutte spente, da sopra il posto accesa.
	var prova := etichette[0] as CanvasItem
	var posto_prova := prova.get_parent() as Node2D
	var eroe: Node2D = world.get("player")
	eroe.global_position = posto_prova.global_position + Vector2(4000, 4000)
	world.call("_turno_delle_targhette", 1.0)
	assert(prova.modulate.a <= 0.01,
		"il nome resta leggibile da quattromila unita': il giro non tocca l'opacita'")
	eroe.global_position = posto_prova.global_position
	world.call("_turno_delle_targhette", 1.0)
	assert(prova.modulate.a >= 0.99,
		"il nome non si accende nemmeno stando sul posto")

	# --- 1ter · il quadro degli obiettivi sa dire il quartiere -------------
	#
	# Il nome del quartiere e' calcolato da un modulo puro e verificato li'; qui
	# si controlla la sola cosa che quel modulo non puo' sapere, cioe' che la
	# scena lo cucia davvero sulle righe del quadro.
	var percorso: Dictionary = world.call("_percorso_coi_quartieri")
	var righe: Array = Array(percorso.get("righe", []))
	assert(righe.size() >= 12, "il quadro degli obiettivi ha %d righe" % righe.size())
	var con_quartiere := 0
	for riga_data in righe:
		var riga: Dictionary = riga_data
		assert(riga.has("quartiere"),
			"la riga di %s non porta il quartiere" % str(riga.get("materia", "")))
		var quartiere := str(riga["quartiere"])
		if quartiere.is_empty():
			continue
		con_quartiere += 1
		assert(quartiere.begins_with("il quartiere "),
			"quartiere scritto male nel quadro: «%s»" % quartiere)
	assert(con_quartiere >= 1,
		"nel mondo 1 nessuna materia sa dire in che quartiere si allena")

	# --- 1quater · la tavola del landmark ha finalmente un lettore ---------
	#
	# `landmarkTavoleSeen` esisteva nel salvataggio da settembre e serviva solo a
	# non rimostrare il pannello: chi si era fermato a leggere e chi era passato
	# dritto giocavano il resto del mondo in modo identico. Qui si pretende che
	# quel ricordo cambi due cose visibili.
	var salvataggio = world.get("game_save")
	var targa: Label = null
	for nodo in world.find_children("LandmarkPurpose", "Label", true, false):
		targa = nodo as Label
		break
	assert(targa != null, "il grande landmark del mondo 1 non ha la sua targa")
	assert(bool(world.call("_tavola_del_landmark_da_leggere")),
		"partita nuova e la tavola del mondo 1 risulta gia' letta")
	assert(str(targa.text).contains("QUALCOSA DA LEGGERE"),
		"la targa del landmark non richiama la tavola: «%s»" % str(targa.text))

	# Letta: il richiamo si spegne e NORA la riprende davanti a una prova.
	salvataggio.data["landmarkTavoleSeen"] = ["1"]
	world.call("_sync_profile_environment_transform", false)
	assert(not str(targa.text).contains("QUALCOSA DA LEGGERE"),
		"il richiamo resta acceso dopo che la tavola e' stata letta")
	var etichetta_nora := world.get("feedback_label") as Label
	etichetta_nora.text = ""
	world.call("_richiama_la_tavola")
	var scoperta := str(LandmarkTavolaCatalog.voce(1).get("scoperta", ""))
	assert(not scoperta.is_empty(), "il mondo 1 non ha una riga di scoperta")
	assert(str(etichetta_nora.text).contains(scoperta),
		"NORA non richiama la tavola letta: «%s»" % str(etichetta_nora.text))
	# Una volta per visita: due volte sarebbe arredamento.
	etichetta_nora.text = ""
	world.call("_richiama_la_tavola")
	assert(str(etichetta_nora.text).is_empty(),
		"il richiamo della tavola si ripete nella stessa visita")

	# --- 2 · quello che lo sguardo puo' nominare --------------------------
	var cose: Array = world.call("_cose_del_mondo")
	assert(not cose.is_empty(), "lo sguardo non ha niente da nominare nel mondo 1")
	var generi: Dictionary = {}
	for cosa_data in cose:
		var cosa: Dictionary = cosa_data
		assert(not str(cosa.get("nome", "")).strip_edges().is_empty(),
			"una cosa del mondo e' finita nello sguardo senza nome")
		assert(not str(cosa.get("id", "")).is_empty(), "cosa del mondo senza id")
		# Ortografia italiana nei nomi propri: «Obelisco Dei Numeri» e' la regola
		# dell'inglese, e questi nomi si leggono ad alta voce a un bambino.
		var parole := str(cosa.get("nome", "")).split(" ", false)
		for indice in range(1, parole.size()):
			var parola := str(parole[indice])
			assert(not NomiDeiLuoghi.PAROLE_MINUSCOLE.has(parola.to_lower())
					or parola == parola.to_lower(),
				"«%s»: preposizione con la maiuscola in un nome proprio" % str(cosa.get("nome", "")))
		generi[str(cosa.get("tipo", ""))] = true
	assert(generi.size() >= 2,
		"lo sguardo vede un genere solo (%s): non c'e' scelta da offrire" % ", ".join(
			PackedStringArray(generi.keys())))

	# --- 3 · lo sguardo scrive davvero nell'HUD ---------------------------
	# Ci si mette accanto a una cosa nominabile ma non addosso: e' la posizione
	# in cui un bambino si trova mentre cammina fra due tappe.
	var bersaglio: Vector2 = Vector2(Dictionary(cose[0]).get("posizione", Vector2.ZERO))
	var player: Node2D = world.get("player")
	player.global_position = bersaglio + Vector2(0, PercorsoStudente.PORTATA_VISTA * 0.5)
	world.get("chunks").update_stream(player.global_position)
	await process_frame
	var etichetta := world.get("feedback_label") as Label
	assert(etichetta != null, "la striscia di feedback non esiste")
	etichetta.text = ""
	world.set("nearby", [])
	world.call("_turno_dello_sguardo", 2.0)
	var riga := str(etichetta.text)
	assert(not riga.strip_edges().is_empty(),
		"lo sguardo non ha scritto niente: il modulo esiste e non lo legge nessuno")
	assert(riga.begins_with("Da qui si vede") or riga.begins_with("Ti ricordi"),
		"lo sguardo ha scritto qualcosa che non e' una lettura del mondo: «%s»" % riga)

	# E non scavalca chi sta gia' parlando.
	etichetta.text = "NORA sta dicendo qualcosa"
	world.set("_sguardo_ultimo_msec", 0)
	world.set("_sguardo_ultima_firma", "")
	world.call("_turno_dello_sguardo", 2.0)
	assert(str(etichetta.text) == "NORA sta dicendo qualcosa",
		"lo sguardo ha scavalcato una riga gia' scritta")

	print("Percorso studente scene audit OK - %d targhette con nome, %d cose nominabili, riga: «%s»" % [
		targhette, cose.size(), riga])
	quit(0)
