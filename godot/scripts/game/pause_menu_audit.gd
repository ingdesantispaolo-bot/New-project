extends SceneTree

## **Le tre uscite ci sono, e nessuna delle tre porta via qualcosa.**
## (21 agosto 2026)
##
## Richiesta del committente: tornare al menu principale, riavviare la missione,
## cambiare utente. Il pannello e' [[PauseMenuPanel]], condiviso da mondo e nave.
##
## Il controllo che nessun collaudo a mano puo' fare e' il terzo di questo file:
## **riavviare non deve restituire niente**. Un riavvio che rimettesse in piedi i
## tesori raccolti sarebbe il modo piu' veloce di guadagnare frammenti che il
## gioco abbia, e non lo si scopre giocando — lo si scopre quando un bambino lo
## scopre, e allora il duello dei guardiani e la bottega non contano piu' niente.
##
## Gli altri tre presidiano difetti che a un menu di pausa capitano sempre:
## uscire senza aver salvato, restare in pausa dentro la scena nuova, e aprirsi
## sopra una prova in corso mettendo due tasti «esci» uno sull'altro.
##
## Uso: godot --headless --path godot --script res://scripts/game/pause_menu_audit.gd

const OK := "PAUSE MENU audit VERDE"
const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const HUB_SCENE := preload("res://scenes/hub.tscn")

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(900, 600)
	await _il_riavvio_non_restituisce_niente()
	await _la_pausa_del_mondo()
	await _la_pausa_della_nave()
	if errori.is_empty():
		print(OK)
	else:
		printerr("PAUSE MENU audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## **Il controllo che vale per tutti gli altri.** Riavviare cancella dov'era
## rimasto e nient'altro: se un giorno qualcuno aggiungesse un `_world_bucket`
## azzerato «per pulizia», questo audit diventa rosso prima che diventi rosso il
## gioco.
func _il_riavvio_non_restituisce_niente() -> void:
	var salva := GameSaveManager.new("user://pause-menu-audit.json")
	salva.data = GameSaveManager._default_data()
	salva.mark_encounter_completed("3", "evt-3-gate-1")
	salva.mark_treasure_collected("3", "tesoro-3-a")
	salva.set_mastery("italiano", 0.72)
	salva.data["fragments"] = 140
	salva.set_world_resume("3", Vector2(512.0, 900.0), 0.42)

	_controlla(not salva.world_resume("3").is_empty(),
		"il salvataggio non registra dov'era rimasto")
	salva.clear_world_resume("3")
	_controlla(salva.world_resume("3").is_empty(),
		"riavviare non dimentica dov'era rimasto: si rientrerebbe dove si era")

	var bucket := salva.world_progress("3")
	_controlla(Array(bucket.get("completedEncounterIds", [])).has("evt-3-gate-1"),
		"riavviare cancella un incontro gia' risolto: si rifarebbe la stessa prova")
	_controlla(Array(bucket.get("collectedTreasureIds", [])).has("tesoro-3-a"),
		"riavviare restituisce i tesori: e' il modo piu' veloce di fare frammenti")
	_controlla(is_equal_approx(salva.mastery_of("italiano"), 0.72),
		"riavviare tocca la maestria: si perderebbe il lavoro invece del giro")
	_controlla(int(salva.data.get("fragments", 0)) == 140,
		"riavviare tocca i frammenti")
	# Un mondo mai visitato non deve nascere per il solo fatto di averlo azzerato.
	salva.clear_world_resume("17")
	_controlla(salva.world_resume("17").is_empty(),
		"azzerare un mondo mai visitato produce uno stato inatteso")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pause-menu-audit.json"))
	await process_frame

func _la_pausa_del_mondo() -> void:
	var iniziale := GameSaveManager._default_data()
	iniziale["level"] = 3
	iniziale["worlds"] = {"unlocked": [1, 2, 3], "current": 3}
	var richiesta := NativeWorldState.default_request("pause-menu-audit")
	richiesta["loadLocalSave"] = false
	richiesta["initialSave"] = iniziale
	richiesta["worldLevel"] = 3
	richiesta["accessibility"] = {"highContrast": false, "reducedMotion": true}
	richiesta["accessibilityExplicit"] = true
	var mondo := WORLD_SCENE.instantiate()
	mondo.set("launch_request_override", richiesta)
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	await process_frame
	await process_frame

	# Il pulsante c'e', e si raggiunge senza aprire nient'altro.
	var apri := mondo.find_child("OpenPauseMenuButton", true, false) as Button
	_controlla(apri != null and apri.visible and apri.custom_minimum_size.y >= 44.0,
		"il mondo non espone un PAUSA visibile e toccabile")
	# La colonna in alto a destra non deve accavallarsi: PAUSA sopra, OPZIONI sotto.
	var opzioni := mondo.find_child("OpenUtilityMenuButton", true, false) as Button
	_controlla(apri != null and opzioni != null and apri.offset_bottom <= opzioni.offset_top,
		"PAUSA e OPZIONI si sovrappongono nella colonna dell'HUD")

	if apri != null:
		apri.pressed.emit()
	await process_frame
	var pausa = mondo.get("pause_menu")
	_controlla(pausa != null and pausa.aperto(), "il mondo non apre il menu di pausa")
	_controlla(paused, "la pausa non ferma il mondo: la carica dei guardiani correrebbe")
	# **Aprire salva.** E' la promessa scritta sul pannello, e da qui si esce in
	# tre modi che cambiano tutti scena.
	var salvataggio = mondo.get("game_save")
	_controlla(salvataggio != null and FileAccess.file_exists(str(salvataggio.path)),
		"aprire la pausa non ha salvato la partita")

	for nome in [
		"PauseResumeButton", "PauseRestartButton",
		"PauseSwitchPlayerButton", "PauseMainMenuButton",
	]:
		var bottone: Button = null
		if pausa != null:
			bottone = pausa.find_child(nome, true, false) as Button
		_controlla(bottone != null, "comando assente nella pausa: %s" % nome)
		_controlla(bottone == null or bottone.custom_minimum_size.y >= 44.0,
			"bersaglio touch insufficiente: %s" % nome)

	# **Il riavvio chiede.** E' l'unico comando che sposta, ed e' l'unico che deve
	# fermarsi a domandare: chiederlo su tutti e tre insegnerebbe a dire «sì»
	# senza leggere.
	if pausa != null:
		var riavvia := pausa.find_child("PauseRestartButton", true, false) as Button
		if riavvia != null:
			riavvia.pressed.emit()
	await process_frame
	var conferma: Button = null
	if pausa != null:
		conferma = pausa.find_child("PauseRestartConfirmButton", true, false) as Button
	_controlla(conferma != null, "il riavvio non chiede conferma")
	_controlla(pausa == null or pausa.find_child("PauseResumeButton", true, false) == null,
		"la conferma lascia in vista i comandi che sta sostituendo")

	# RIPRENDI fa ripartire davvero: una pausa che non si toglie e' un gioco morto.
	if pausa != null:
		var annulla := pausa.find_child("PauseRestartCancelButton", true, false) as Button
		if annulla != null:
			annulla.pressed.emit()
		await process_frame
		var riprendi := pausa.find_child("PauseResumeButton", true, false) as Button
		if riprendi != null:
			riprendi.pressed.emit()
	await process_frame
	_controlla(not paused, "RIPRENDI non toglie la pausa")
	_controlla(pausa == null or not pausa.aperto(), "RIPRENDI non chiude il pannello")

	# **Mai sopra una prova.** Chi e' dentro un esercizio ha gia' la sua uscita.
	var prova = mondo.get("exercise_player")
	if prova != null:
		prova.visible = true
		mondo.call("_apri_pausa")
		_controlla(not paused and not pausa.aperto(),
			"la pausa si apre sopra una prova: due tasti «esci» uno sull'altro")
		prova.visible = false

	# Uscire non deve lasciare l'albero fermo: la scena che arriva dopo nascerebbe
	# bloccata, e nessun pulsante risponderebbe piu'.
	mondo.call("_apri_pausa")
	await process_frame
	_controlla(paused, "la pausa non si riapre dopo essere stata chiusa")
	pausa.congeda()
	_controlla(not paused, "congedare la pausa lascia l'albero in pausa")

	# Il riavvio prepara il rientro nello stesso mondo, con lo stesso salvataggio.
	mondo.call("_stage_rientro_nel_mondo", "audit-riavvio")
	var preparata := NativeWorldState.take_launch_request()
	_controlla(int(preparata.get("worldLevel", 0)) == 3,
		"il riavvio non rientra nello stesso mondo")
	_controlla(not bool(preparata.get("loadLocalSave", true))
			and not Dictionary(preparata.get("initialSave", {})).is_empty(),
		"il riavvio non porta con se' il salvataggio in corso")

	paused = false
	root.remove_child(mondo)
	mondo.queue_free()
	await process_frame

func _la_pausa_della_nave() -> void:
	var nave := HUB_SCENE.instantiate()
	root.add_child(nave)
	await process_frame
	await process_frame

	var apri := nave.find_child("MainMenuButton", true, false) as Button
	_controlla(apri != null and apri.text == "PAUSA",
		"la nave non espone la pausa dove c'era il ritorno al menu")
	if apri != null:
		apri.pressed.emit()
	await process_frame
	var pausa = nave.get("pause_menu")
	_controlla(pausa != null and pausa.aperto(), "la nave non apre il menu di pausa")
	_controlla(paused, "la pausa non ferma la nave")
	# **Gli stessi comandi, nello stesso ordine.** E' il motivo per cui il
	# pannello e' uno solo: chi impara a uscire da una scena esce anche dall'altra.
	for nome in [
		"PauseResumeButton", "PauseRestartButton",
		"PauseSwitchPlayerButton", "PauseMainMenuButton",
	]:
		_controlla(pausa != null and pausa.find_child(nome, true, false) != null,
			"la pausa della nave non ha lo stesso comando del mondo: %s" % nome)

	if pausa != null:
		pausa.congeda()
	_controlla(not paused, "uscire dalla pausa della nave lascia l'albero fermo")
	paused = false
	root.remove_child(nave)
	nave.queue_free()
	await process_frame
