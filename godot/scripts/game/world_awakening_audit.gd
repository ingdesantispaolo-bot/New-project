extends SceneTree

## **Il risveglio, nel mondo vero.** (20 agosto 2026)
##
## `world_light_audit` prova il modello: i contatori salgono, niente torna
## indietro, i fuochi pareggiano le prove. Sono proprietà che si possono
## verificare senza costruire niente, e che restano vere anche se il mondo non
## disegna un solo fuoco.
##
## Questo audit costruisce il mondo e guarda. Le proprietà che tiene:
##
##   1. **i fuochi ci sono, e sono spenti** in un mondo mai giocato;
##   2. **stanno lontani fra loro**: dodici fuochi nello stesso quartiere non
##      raccontano un mondo che si sveglia, ma un angolo che si illumina;
##   3. **una prova accende il più vicino a Eli**, non il primo di una lista:
##      chi esce da un pannello di esercizi deve trovare la cosa nuova senza
##      cercarla;
##   4. **rientrando, i fuochi sono gli stessi**. Se si spostassero, la
##      ricompensa sembrerebbe tornata indietro — l'unica cosa che avevamo
##      promesso di non fare mai;
##   5. **la nebbia resta pulita**. È il guardiano del cambio: se una prova
##      tornasse a muovere il velo, la luminosità smetterebbe di essere libera di
##      dire l'ora, e il ciclo giorno/notte tornerebbe a contraddirsi.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const LIVELLO := 5

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

func _request(salvataggio: Dictionary) -> Dictionary:
	var request := NativeWorldState.default_request("risveglio-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = salvataggio
	request["worldLevel"] = LIVELLO
	return request

func _salvataggio_iniziale() -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = LIVELLO
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, LIVELLO + 1), "current": LIVELLO}
	return initial

func _apri_il_mondo(salvataggio: Dictionary) -> Node:
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _request(salvataggio))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	current_scene = mondo
	await process_frame
	await process_frame
	return mondo

func _chiudi(mondo: Node) -> void:
	root.remove_child(mondo)
	mondo.queue_free()
	current_scene = null
	await process_frame

func _fuochi(mondo: Node) -> Array:
	var out: Array = []
	for nodo in get_nodes_in_group("fuoco_del_risveglio"):
		if mondo.is_ancestor_of(nodo as Node):
			out.append(nodo)
	return out

func _accesi(fuochi: Array) -> Array:
	var out: Array = []
	for indice in range(fuochi.size()):
		if bool((fuochi[indice] as Node).get("acceso")):
			out.append(indice)
	return out

func _run() -> void:
	root.size = Vector2i(900, 600)
	var mondo := await _apri_il_mondo(_salvataggio_iniziale())
	var save: GameSaveManager = mondo.get("game_save")
	var fuochi := _fuochi(mondo)

	# --- 1. Ci sono, e sono spenti -------------------------------------------
	_controlla(fuochi.size() == WorldAwakening.FUOCHI,
		"il mondo ha %d fuochi invece di %d" % [fuochi.size(), WorldAwakening.FUOCHI])
	_controlla(_accesi(fuochi).is_empty(),
		"un mondo mai giocato ha gia' %d fuochi accesi" % _accesi(fuochi).size())

	# --- 2. Sono sparsi -------------------------------------------------------
	if fuochi.size() >= 2:
		var minima := INF
		var massima := 0.0
		for i in range(fuochi.size()):
			for j in range(i + 1, fuochi.size()):
				var quanto := (fuochi[i] as Node2D).position.distance_to((fuochi[j] as Node2D).position)
				minima = minf(minima, quanto)
				massima = maxf(massima, quanto)
		# Due fuochi a meno di centoventi unita' l'uno dall'altro si leggono come
		# un fuoco solo: alla velocita' di Eli sono meno di mezzo secondo.
		_controlla(minima >= 120.0,
			"due fuochi distano %.0f unita': si leggono come uno solo" % minima)
		_controlla(massima >= 900.0,
			"i fuochi stanno tutti dentro %.0f unita': e' un angolo, non un mondo" % massima)

	# --- 3. Si accende il piu' vicino a Eli -----------------------------------
	var eli: Node2D = mondo.get("player")
	_controlla(is_instance_valid(eli), "Eli non e' nel mondo")
	if is_instance_valid(eli):
		var atteso := -1
		var distanza := INF
		for indice in range(fuochi.size()):
			var quanto := eli.global_position.distance_squared_to((fuochi[indice] as Node2D).global_position)
			if quanto < distanza:
				distanza = quanto
				atteso = indice
		# La prova superata, con lo stesso giro che fa il gioco: il contatore
		# sale e la scena reagisce.
		var luce := WorldLight.accendi(save, str(LIVELLO))
		mondo.call("_on_world_light_changed", luce, WorldLight.grado(save), false)
		var accesi := _accesi(fuochi)
		_controlla(accesi.size() == 1, "una prova ha acceso %d fuochi" % accesi.size())
		_controlla(accesi.has(atteso),
			"la prova ha acceso il fuoco %s invece del piu' vicino a Eli (%d)" % [str(accesi), atteso])
		_controlla(WorldAwakening.quanti(save, str(LIVELLO)) == 1,
			"il fuoco acceso non e' finito nel salvataggio")

		# --- 5. La nebbia non si e' mossa ------------------------------------
		var velo := mondo.get("velo_nebbia") as ColorRect
		_controlla(velo != null and is_equal_approx(velo.color.a, 0.0),
			"dopo una prova il velo di nebbia ha alfa %.2f: l'avanzamento e' tornato sulla luminosita'"
			% (velo.color.a if velo != null else -1.0))

	var accesi_prima := _accesi(fuochi)
	var salvataggio := (save.data as Dictionary).duplicate(true)
	await _chiudi(mondo)

	# --- 4. Rientrando sono gli stessi ---------------------------------------
	var secondo := await _apri_il_mondo(salvataggio)
	var fuochi_2 := _fuochi(secondo)
	_controlla(_accesi(fuochi_2) == accesi_prima,
		"rientrando i fuochi accesi sono %s invece di %s" % [str(_accesi(fuochi_2)), str(accesi_prima)])
	await _chiudi(secondo)

	if _rossi.is_empty():
		print("WORLD AWAKENING audit OK — dodici fuochi sparsi, si accende il piu' vicino, il velo resta pulito")
		quit(0)
		return
	for riga in _rossi:
		printerr("WORLD AWAKENING audit FALLITO — %s" % riga)
	quit(1)
