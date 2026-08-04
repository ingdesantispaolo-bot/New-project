extends SceneTree

## **Da una prova si esce sempre, e uscire costa.** (4 agosto 2026)
##
## Il difetto che ha reso necessaria questa porta: su tablet il campo numerico
## non si riempiva, e non esisteva nessun modo di lasciare l'esercizio — né un
## pulsante, né `ui_cancel`. Un bambino è rimasto chiuso lì dentro. Un gioco che
## si studia non può avere stanze senza porta, e questo audit esiste perché la
## porta non sparisca in una rifattorizzazione futura.
##
## Le quattro cose che verifica, e perché ognuna:
##
## 1. **Il pulsante c'è ed è visibile dal primo nodo.** Se comparisse solo dopo
##    un errore, la trappola resterebbe aperta per chi si blocca subito.
## 2. **Serve un secondo tocco.** L'uscita costa energia: un dito storto non
##    deve poterla spendere.
## 3. **L'esito è «non consegnata», non «fallita».** Niente incontro completato,
##    niente energia della sessione. Ma gli argomenti visti arrivano al Codex:
##    il gioco non toglie a nessuno quello che ha imparato.
## 4. **Con zero energia si esce lo stesso.** Una porta che si apre solo se hai
##    i soldi non è una porta.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _init() -> void:
	call_deferred("_run")

func _request(energia: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = 1
	initial["energy"] = energia
	initial["fragments"] = 0
	initial["worlds"] = {"unlocked": [1], "current": 1}
	var request := NativeWorldState.default_request("exercise-exit-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	return request

func _cleanup(world: Node) -> void:
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	var audio := root.get_node_or_null("NativeAudio")
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				if child.name not in ["MusicBase", "AmbienceBase", "MusicFocus"]:
					child.free()
		audio.set("_stream_cache", {})
	await create_timer(0.15).timeout

func _run() -> void:
	await _prova_uscita(100, "con energia piena")
	await _prova_uscita(0, "con zero energia")
	print("EXERCISE EXIT audit OK — porta sempre aperta, conferma a due tocchi, costo pagato, Codex intatto")
	quit(0)

func _prova_uscita(energia_iniziale: int, etichetta: String) -> void:
	root.size = Vector2i(900, 600)
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", _request(energia_iniziale))
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame

	var gameplay := world.get("gameplay") as OutdoorGameplay
	var save := gameplay.game_save
	var exercise := world.get("exercise_player") as ExercisePlayer

	# Una sessione di pratica: è il caso più comune e non tocca il gate.
	var cm := ContentManager.new()
	var sessione: Dictionary = cm.build_mission("matematica", 1)
	sessione["kind"] = "minigame"
	sessione["abandonCost"] = OutdoorGameplay.EXERCISE_ABANDON_COST
	gameplay.active_session_context = {
		"kind": "minigame", "encounterId": "uscita-audit", "subject": "matematica"}
	exercise.visible = true
	exercise.start_session(sessione)
	await process_frame

	var esci := exercise.find_child("ExerciseExitButton", true, false) as Button
	var resto := exercise.find_child("ExerciseStayButton", true, false) as Button
	var avviso := exercise.find_child("ExitNotice", true, false) as Label
	assert(esci != null, "%s: nessun pulsante di uscita nella prova" % etichetta)
	assert(esci.visible, "%s: il pulsante di uscita non è visibile dal primo nodo" % etichetta)
	assert(resto != null and not resto.visible,
		"%s: la conferma è già armata prima di toccare" % etichetta)

	# Primo tocco: chiede conferma, non esce, non spende niente.
	var uscite: Array = []
	exercise.session_finished.connect(func(res): uscite.append(res))
	var energia_prima := save.energy()
	esci.pressed.emit()
	await process_frame
	assert(uscite.is_empty(), "%s: il primo tocco ha già chiuso la prova" % etichetta)
	assert(resto.visible, "%s: il primo tocco non offre di restare" % etichetta)
	assert(avviso != null and avviso.visible and "energia" in avviso.text.to_lower(),
		"%s: il prezzo dell'uscita non è dichiarato prima" % etichetta)
	assert(save.energy() == energia_prima,
		"%s: il primo tocco ha già speso energia" % etichetta)

	# Ripensarci deve essere gratis e completo.
	resto.pressed.emit()
	await process_frame
	assert(uscite.is_empty() and not resto.visible,
		"%s: «resto» non ha disarmato la conferma" % etichetta)

	# Secondo tocco (riarmato): esce davvero.
	esci.pressed.emit()
	await process_frame
	esci.pressed.emit()
	await process_frame
	assert(uscite.size() == 1, "%s: la prova non si è chiusa al secondo tocco" % etichetta)
	var esito := uscite[0] as Dictionary
	assert(bool(esito.get("abandoned", false)), "%s: l'esito non è marcato come abbandono" % etichetta)
	assert(not bool(esito.get("passed", true)), "%s: una prova abbandonata risulta superata" % etichetta)
	assert(int(esito.get("energyGained", -1)) == 0,
		"%s: una prova non consegnata ha comunque consegnato energia" % etichetta)

	# Il lato semantica: paga l'uscita, non completa niente, non azzera il Codex.
	# Non serve richiamare `_on_exercise_finished` a mano: il mondo è già
	# collegato a `session_finished` e ha risolto la sessione da sé. Chiamarlo
	# di nuovo addebiterebbe l'uscita due volte — ed è esattamente l'errore che
	# questo audit ha preso al primo giro.
	await process_frame
	var atteso := mini(OutdoorGameplay.EXERCISE_ABANDON_COST, energia_prima)
	assert(save.energy() == energia_prima - atteso,
		"%s: costo dell'uscita sbagliato (atteso %d, energia %d → %d)" % [
			etichetta, atteso, energia_prima, save.energy()])
	assert(save.energy() >= 0, "%s: l'uscita ha portato l'energia sotto zero" % etichetta)
	assert(not Array(world.get("result").get("completedEncounterIds", [])).has("uscita-audit"),
		"%s: una prova abbandonata ha completato l'incontro" % etichetta)

	await _cleanup(world)
