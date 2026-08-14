extends SceneTree

## **Il chiavistello, giocato per davvero.** (14 agosto 2026)
##
## `lock_challenge_audit` verifica i numeri; questo verifica la **scena**: che il
## pannello si apra davanti al forziere, che vincere paghi, e soprattutto che
## perdere non costi niente — che è la promessa su cui poggia il fatto stesso di
## poter mettere una prova a tempo davanti a una ricompensa.
##
## Le cinque cose che verifica:
##
## 1. Interagire con un forziere **apre il chiavistello** invece di aprire la
##    cassa: nessun forziere si apre più da solo.
## 2. **Vincere paga**: i denti scattano, il forziere risulta raccolto, i
##    frammenti arrivano.
## 3. **Perdere non toglie niente**: nessun frammento, nessuna energia, e il
##    forziere **non** resta segnato come raccolto — si può riprovare.
## 4. **Andarsene è gratis**, e lascia il gioco esattamente com'era.
## 5. **Il tempo scaduto** si comporta come una rinuncia, non come una punizione.

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := await _mondo()
	if world == null:
		printerr("LOCK PANEL audit ROSSO")
		printerr("  - impossibile istanziare il mondo")
		quit(1)
		return

	await _apre_il_chiavistello(world)
	await _vincere_paga(world)
	await _perdere_non_costa(world)
	await _andarsene_e_gratis(world)

	if errori.is_empty():
		print("LOCK PANEL audit VERDE — il chiavistello apre, paga, e perdere non costa niente")
	else:
		printerr("LOCK PANEL audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _mondo() -> Node:
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["energy"] = 400
	initial["fragments"] = 200
	initial["worlds"] = {"unlocked": [1, 2], "current": 2}
	# Con entrambi gli strumenti nessun forziere resta chiuso per un motivo che
	# non c'entra con il chiavistello.
	initial["cosmetics"] = {"unlocked": ["tool-torch"], "equipped": {"tool": "tool-torch"}, "inventory": []}
	var request := NativeWorldState.default_request("lock-panel-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 2
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	# Niente `launch_stream_radius_override`: i forzieri nascono nei chunk, e con
	# lo streaming a zero il mondo di prova sarebbe vuoto proprio della cosa che
	# questo audit deve giocare.
	root.add_child(world)
	for _giro in range(12):
		await process_frame
	return world

## Il primo forziere raggiungibile e non ancora raccolto.
func _forziere(world: Node):
	var raccolti: Array = Array(Dictionary(world.get("result")).get("collectedTreasureIds", []))
	for area in world.get_tree().get_nodes_in_group("world_interactable"):
		if not (area is Area2D):
			continue
		var zona := area as Area2D
		if str(zona.get_meta("kind", "")) != "treasure":
			continue
		if raccolti.has(str(zona.get_meta("id", ""))):
			continue
		if str(Dictionary(zona.get_meta("payload", {})).get("requiredTool", "")) == "tool-scythe":
			continue
		# Un forziere sorvegliato manda prima al varco (`_sfida_guardiano`): è la
		# regola del mondo e non riguarda il chiavistello. Nel mondo di prova i
		# forzieri liberi sono pochi, quindi la guardiana si scioglie qui invece
		# di cercare altrove — il duello ha già il suo audit.
		var guardiana = world.call("_guardiano_di", str(zona.get_meta("id", "")))
		if guardiana != null:
			var save = world.get("game_save")
			save.mark_enemy_defeated(str(world.get("world_level")),
				str(guardiana.get_meta("guardId", "")))
			guardiana.call("elimina")
			# `elimina` scioglie la sacca con la sua animazione: l'audit non ha
			# tempo per aspettarla e la toglie di scena subito, altrimenti il
			# forziere resterebbe sorvegliato da un nodo che sta già morendo.
			guardiana.queue_free()
			for _giro in range(3):
				await process_frame
		return zona
	return null

func _interagisci(world: Node, zona: Area2D) -> void:
	var player = world.get("player")
	if player != null:
		player.position = zona.global_position
	# `_interact` agisce sul più vicino fra i vicini registrati: se accanto al
	# forziere c'è un altro punto d'interesse, l'audit finirebbe per collaudare
	# quello. Qui il vicinato si azzera e resta solo la cassa da aprire.
	var vicini: Array = world.get("nearby")
	vicini.clear()
	world.call("on_interactable_entered", zona, player)
	var scelto = world.call("_nearest")
	if scelto != zona:
		errori.append("il vicinato del forziere contiene «%s» invece della cassa" % (
			str(scelto.get_meta("kind", "?")) if scelto != null else "niente"))
	world.call("_interact")
	await process_frame
	if world.get("lock_panel") == null:
		print("  diagnosi: tool richiesto «%s» · equipaggiato «%s» · guardiana %s · raccolto %s" % [
			str(Dictionary(zona.get_meta("payload", {})).get("requiredTool", "")),
			str(world.call("equipped_field_tool")),
			"sì" if world.call("_guardiano_di", str(zona.get_meta("id", ""))) != null else "no",
			"sì" if Array(Dictionary(world.get("result")).get("collectedTreasureIds", [])).has(str(zona.get_meta("id", ""))) else "no",
		])

func _apre_il_chiavistello(world: Node) -> void:
	var zona: Area2D = await _forziere(world)
	if zona == null:
		errori.append("nessun forziere raggiungibile nel mondo di prova")
		return
	await _interagisci(world, zona)
	var pannello = world.get("lock_panel")
	_controlla(pannello != null, "interagire con un forziere non apre il chiavistello")
	if pannello == null:
		return
	_controlla(bool(pannello.call("attivo")), "il chiavistello si apre già risolto")
	_controlla(int(pannello.call("indice_giusto")) >= 0,
		"il primo dente non ha nessuna tessera che apre")
	# E chiude senza lasciare tracce, per i controlli successivi.
	pannello.call("_fallisci")
	await process_frame

func _vincere_paga(world: Node) -> void:
	var zona: Area2D = await _forziere(world)
	if zona == null:
		errori.append("nessun forziere disponibile per la prova di vittoria")
		return
	var id := str(zona.get_meta("id", ""))
	var save = world.get("game_save")
	var frammenti_prima := int(save.fragments())
	var energia_prima := int(save.energy())
	await _interagisci(world, zona)
	var pannello = world.get("lock_panel")
	if pannello == null:
		errori.append("il chiavistello non si è aperto sulla prova di vittoria")
		return
	var giri := 0
	while bool(pannello.call("attivo")) and giri < 12:
		pannello.call("scegli", int(pannello.call("indice_giusto")))
		giri += 1
	await process_frame
	var raccolti: Array = Array(Dictionary(world.get("result")).get("collectedTreasureIds", []))
	_controlla(raccolti.has(id), "vinto il chiavistello, il forziere non risulta raccolto")
	_controlla(int(save.fragments()) > frammenti_prima,
		"vinto il chiavistello, i frammenti non sono arrivati")
	_controlla(int(save.energy()) == energia_prima,
		"il chiavistello ha toccato l'energia: è la valuta dello studio, non dell'abilità")

func _perdere_non_costa(world: Node) -> void:
	var zona: Area2D = await _forziere(world)
	if zona == null:
		errori.append("nessun forziere disponibile per la prova di sconfitta")
		return
	var id := str(zona.get_meta("id", ""))
	var save = world.get("game_save")
	var frammenti_prima := int(save.fragments())
	var energia_prima := int(save.energy())
	var livello_prima := int(save.level())
	await _interagisci(world, zona)
	var pannello = world.get("lock_panel")
	if pannello == null:
		errori.append("il chiavistello non si è aperto sulla prova di sconfitta")
		return
	# Tempo scaduto: la stessa strada che percorre il pannello quando l'orologio
	# arriva a zero.
	pannello.call("_fallisci")
	await process_frame
	var raccolti: Array = Array(Dictionary(world.get("result")).get("collectedTreasureIds", []))
	_controlla(not raccolti.has(id),
		"perso il chiavistello, il forziere risulta comunque raccolto: sarebbe perso per sempre")
	_controlla(int(save.fragments()) == frammenti_prima, "perdere ha cambiato i frammenti")
	_controlla(int(save.energy()) == energia_prima, "perdere ha cambiato l'energia")
	_controlla(int(save.level()) == livello_prima, "perdere ha cambiato il livello")
	# E il forziere si può riprovare subito: nessun cooldown, nessuna penalità.
	await _interagisci(world, zona)
	_controlla(world.get("lock_panel") != null,
		"dopo un fallimento il forziere non si lascia riprovare")
	if world.get("lock_panel") != null:
		world.get("lock_panel").call("_fallisci")
		await process_frame

func _andarsene_e_gratis(world: Node) -> void:
	var zona: Area2D = await _forziere(world)
	if zona == null:
		errori.append("nessun forziere disponibile per la prova di abbandono")
		return
	var save = world.get("game_save")
	var prima: Dictionary = save.data.duplicate(true)
	await _interagisci(world, zona)
	var pannello = world.get("lock_panel")
	if pannello == null:
		errori.append("il chiavistello non si è aperto sulla prova di abbandono")
		return
	var bottone := pannello.find_child("LockLeaveButton", true, false) as Button
	_controlla(bottone != null, "dal chiavistello non si può uscire: manca il pulsante")
	if bottone != null:
		bottone.emit_signal("pressed")
		await process_frame
	for chiave in prima.keys():
		if str(prima[chiave]) != str(save.data.get(chiave)):
			errori.append("andarsene dal chiavistello ha cambiato «%s» nel salvataggio" % str(chiave))
			break
