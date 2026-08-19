extends SceneTree

## **Lo scatto: il secondo verbo del corpo.** (19 agosto 2026)
##
## Fino al 18 agosto Eli aveva **un verbo solo**. `player_controller.gd` erano
## settantaquattro righe — cammina, e una corsa che moltiplica la velocita' — e
## le dodici cose interattive della mappa finivano tutte nello stesso gesto:
## avvicinati, premi. Il corpo di Eli non decideva mai niente.
##
## Lo scatto e' un balzo breve che **attraversa le sacche di Silenzio**: durante
## il balzo non c'e' morso e non c'e' spintone. E' il primo momento del gioco in
## cui il tempismo conta quanto il grado.
##
## Questo audit tiene le sei proprieta' che lo rendono lecito e utile, e le prime
## due valgono piu' delle altre quattro:
##
##   1. **non guada.** Il fiume si passa col ponte-enigma e con nient'altro: e'
##      una decisione vincolante del progetto, e un balzo che la scavalcasse
##      trasformerebbe l'enigma in scenografia;
##   2. **non apre i varchi da equipaggiamento.** L'erba alta si taglia con la
##      falce. Se la si attraversasse di slancio, gli strumenti — che sono le
##      chiavi del gioco — diventerebbero decorazione;
##   3. **non costa e non concede niente**: ne' energia, ne' padronanza, ne'
##      frammenti. E' movimento;
##   4. **il varco funziona**: attraversando una sacca non si paga e non si viene
##      respinti;
##   5. **si ricarica**, e nella finestra di ricarica non riparte. Senza, la
##      scelta costruita col presidio — pago, spendo una carica, o rischio il
##      tempismo — collasserebbe in «scatta e basta»;
##   6. **con `reduced_motion` la meccanica resta intera.** Sparisce la scia, non
##      il balzo: un'impostazione di accessibilita' non puo' togliere un verbo.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

func _request(livello: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("scatto-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	return request

## **Il mondo su cui si apre la scena.** Nove, e la ragione e' la prova 5: e'
## l'unico dei mondi campionati che abbia acqua invalicabile in abbondanza
## attorno allo spawn (misurata: 519 celle su una griglia da sessanta unita',
## contro zero ai mondi 3, 5, 13 e 21). Provare che lo scatto non guada in un
## mondo senza fiumi sarebbe un verde che non ha misurato niente.
const MONDO_DI_PROVA := 9

## Aspetta che il balzo finisca, contando **fotogrammi di fisica** e non secondi.
##
## La prima stesura aspettava su un timer di scena, ed era sbagliato: il balzo si
## consuma dentro `_physics_process`, e sotto il carico di un mondo intero Godot
## limita i passi di fisica per fotogramma — il tempo di fisica smette di
## coincidere col tempo reale, e l'attesa scadeva con il balzo ancora in corso.
## Misurato: quattordici passi di fisica per finire un balzo da due decimi.
##
## Torna vero se e' finito nel numero di passi previsto, cioe' se **finisce da
## solo**: e' anche l'asserzione che serve, non solo un'attesa.
func _balzo_finito_da_solo() -> bool:
	var passi := 0
	var tetto := int(ceil(OutdoorPlayerController.SCATTO_DURATA * 240.0))
	while passi < tetto:
		if not _giocatore.sta_scattando():
			return true
		await physics_frame
		passi += 1
	return not _giocatore.sta_scattando()

var _giocatore: OutdoorPlayerController

func _run() -> void:
	# --- La taratura, prima di aprire qualunque cosa --------------------------
	# La ricarica non puo' essere piu' corta della finestra di morso di una sacca:
	# se lo fosse, si attraverserebbe un presidio a raffica e la scelta costruita
	# col lotto precedente non esisterebbe piu'.
	_controlla(OutdoorPlayerController.SCATTO_RICARICA_MSEC >= 1100,
		"la ricarica dello scatto (%d ms) e' piu' corta del morso di una sacca: il presidio si attraversa a raffica"
		% OutdoorPlayerController.SCATTO_RICARICA_MSEC)
	_controlla(OutdoorPlayerController.SCATTO_DURATA <= 0.3,
		"il balzo dura %.2f s: a questa lunghezza non e' uno scatto, e' una seconda velocita'"
		% OutdoorPlayerController.SCATTO_DURATA)
	# Il modulo «Passo lungo» deve allungare il balzo, altrimenti resta il +20% di
	# velocita' che su tablet non si sentiva.
	_controlla(ExpeditionModules.SCATTO_DISTANZA_LUNGA > ExpeditionModules.SCATTO_DISTANZA,
		"«Passo lungo» non allunga il balzo: e' di nuovo un acquisto che non si vede")
	# E il balzo deve superare il cerchio di contatto della sacca piu' grossa,
	# altrimenti il varco e' una promessa che la geometria non mantiene.
	var contatto_massimo := 34.0 + 8.0 * 2.0
	_controlla(ExpeditionModules.SCATTO_DISTANZA > contatto_massimo * 2.0,
		"il balzo (%.0f) non attraversa il contatto della sacca piu' grossa (%.0f)"
		% [ExpeditionModules.SCATTO_DISTANZA, contatto_massimo * 2.0])

	root.size = Vector2i(900, 600)
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _request(MONDO_DI_PROVA))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	current_scene = mondo
	await process_frame
	await process_frame

	var player: OutdoorPlayerController = mondo.get("player")
	var save: GameSaveManager = mondo.get("game_save")
	_controlla(is_instance_valid(player), "nessun personaggio nel mondo: l'audit non prova niente")
	if not is_instance_valid(player):
		await _esito(mondo)
		return
	_giocatore = player

	# --- 1. Il balzo sposta, e sposta davvero ---------------------------------
	var partenza := player.global_position
	_controlla(player.scatto_pronto(), "il balzo non e' disponibile appena entrati nel mondo")
	_controlla(bool(player.scatta()), "il balzo non parte")
	_controlla(player.sta_scattando(), "il balzo e' partito ma il personaggio non risulta in scatto")
	_controlla(await _balzo_finito_da_solo(), "il balzo non finisce da solo")
	var percorso := partenza.distance_to(player.global_position)
	# Meta' della distanza nominale basta a dire «si e' mosso davvero»: il terreno
	# puo' avere un ostacolo, e pretendere il valore esatto renderebbe l'audit
	# dipendente da dove il seed ha messo un sasso.
	_controlla(percorso > ExpeditionModules.SCATTO_DISTANZA * 0.5,
		"il balzo ha spostato Eli di sole %.0f unita' su %.0f" % [percorso, ExpeditionModules.SCATTO_DISTANZA])

	# --- 2. Si ricarica, e nella finestra non riparte -------------------------
	_controlla(not player.scatto_pronto(), "il balzo e' subito di nuovo pronto: non ha ricarica")
	_controlla(not bool(player.scatta()), "il balzo riparte dentro la propria ricarica")
	_controlla(player.scatto_attesa_msec() > 0, "la ricarica non e' leggibile: attesa a zero mentre e' spento")

	# --- 3. Non costa e non concede niente ------------------------------------
	var materia := str(mondo.call("_world_subject"))
	var energia_prima := int(save.energy())
	var frammenti_prima := int(save.fragments())
	var padronanza_prima := float(save.mastery_of(materia))
	player.set("_scatto_pronto_msec", 0)
	mondo.call("_scatto")
	await _balzo_finito_da_solo()
	_controlla(int(save.energy()) == energia_prima, "il balzo ha toccato l'energia: dev'essere solo movimento")
	_controlla(int(save.fragments()) == frammenti_prima, "il balzo ha toccato i frammenti")
	_controlla(is_equal_approx(save.mastery_of(materia), padronanza_prima),
		"il balzo ha toccato la padronanza: e' movimento, non una prova")

	# --- 4. Il varco: di slancio la sacca non morde e non respinge -------------
	var sacca := WorldEnemy.new()
	sacca.setup(mondo, player.global_position + Vector2(400, 0), MONDO_DI_PROVA, materia, Color("ff7b72"), 0)
	sacca.reduced_motion = true
	mondo.get("world_layer").add_child(sacca)
	await process_frame

	# Prima il caso normale, per avere un termine di paragone onesto: camminando,
	# una sacca di grado alto contro Eli al grado zero costa e respinge.
	sacca.global_position = player.global_position + Vector2(30, 0)
	var dove_era := player.global_position
	energia_prima = int(save.energy())
	mondo.call("_on_enemy_contact", sacca, player)
	_controlla(int(save.energy()) < energia_prima,
		"camminando la sacca non costa niente: senza questo il varco non prova niente")
	_controlla(player.global_position.distance_to(dove_era) > 40.0,
		"camminando la sacca non respinge: senza questo il varco non prova niente")

	# E adesso di slancio.
	player.set("_scatto_pronto_msec", 0)
	_controlla(bool(player.scatta()), "il balzo non riparte dopo la ricarica azzerata")
	sacca.global_position = player.global_position + Vector2(20, 0)
	sacca.set("contact_ready_msec", 0)
	dove_era = player.global_position
	energia_prima = int(save.energy())
	mondo.call("_on_enemy_contact", sacca, player)
	_controlla(int(save.energy()) == energia_prima,
		"la sacca morde anche durante il balzo: il varco non esiste")
	_controlla(player.global_position.distance_to(dove_era) < 40.0,
		"la sacca respinge anche durante il balzo: non ci si passa attraverso")
	await _balzo_finito_da_solo()
	sacca.queue_free()
	await process_frame

	# --- 5. Non guada ---------------------------------------------------------
	# **La prova che vale piu' di tutte.** Si cerca una riva vera nel mondo e si
	# scatta dentro il fiume: Eli deve restare fuori, e il balzo spegnersi.
	# Si cerca una cella d'acqua su una griglia vera attorno a Eli, e poi la riva
	# che la guarda. Non si accetta di NON trovarla: il mondo 9 ne ha 519, e se un
	# giorno non ne avesse piu' questa prova deve diventare rossa invece che
	# saltarsi in silenzio — un audit che si auto-esenta è peggio di un audit che
	# non esiste, perché sembra verde.
	var acqua := Vector2.INF
	for gx in range(-26, 27):
		if acqua != Vector2.INF:
			break
		for gy in range(-26, 27):
			var candidata: Vector2 = player.global_position + Vector2(float(gx), float(gy)) * 60.0
			if bool(mondo.call("_water_blocks_position", candidata)):
				acqua = candidata
				break
	_controlla(acqua != Vector2.INF,
		"nessuna acqua invalicabile attorno allo spawn del mondo %d: la prova del guado non ha misurato niente"
		% MONDO_DI_PROVA)
	if acqua != Vector2.INF:
		# La riva: il primo punto asciutto tornando indietro dall'acqua verso Eli.
		var verso_eli := (player.global_position - acqua).normalized()
		var riva := acqua
		for passo in range(1, 60):
			var indietro: Vector2 = acqua + verso_eli * float(passo) * 8.0
			if not bool(mondo.call("_water_blocks_position", indietro)):
				riva = indietro
				break
		_controlla(riva != acqua, "non si trova una riva accanto all'acqua: la prova non e' impostabile")
		player.global_position = riva
		mondo.set("last_traversable_position", riva)
		player.set("_scatto_pronto_msec", 0)
		player.set("_ultima_direzione", -verso_eli)
		player.set("dash_distance", 400.0)
		mondo.call("_scatto")
		await _balzo_finito_da_solo()
		mondo.call("_enforce_water_traversal")
		_controlla(not bool(mondo.call("_water_blocks_position", player.global_position)),
			"lo scatto ha guadato: il ponte-enigma smette di essere l'unico attraversamento")
		_controlla(not player.sta_scattando(),
			"il balzo contro l'acqua non si e' spento")
		# E la ricarica resta consumata: un balzo tirato contro una riva e'
		# comunque un balzo tirato, e restituirlo insegnerebbe a lanciarsi nel
		# fiume per vedere che succede.
		_controlla(not player.scatto_pronto(),
			"il balzo annullato dall'acqua ha restituito la ricarica")
		player.set("dash_distance", ExpeditionModules.SCATTO_DISTANZA)

	# --- 6. Non apre i varchi da equipaggiamento ------------------------------
	# L'erba alta e' un blocco fisico: il balzo ci sbatte contro come il passo.
	# Si prova sul comportamento, non sulla forma, perche' il rischio vero e' che
	# un balzo veloce **attraversi** la collisione invece di fermarcisi.
	var varco := EquipmentGate.new()
	varco.name = "VarcoDiProva"
	mondo.get("world_layer").add_child(varco)
	varco.global_position = player.global_position + Vector2(150, 0)
	varco.configure(FieldTools.FALCE, [])
	await process_frame
	_controlla(not varco.is_open(), "il varco di prova nasce gia' aperto: non prova niente")
	player.global_position = varco.global_position - Vector2(150, 0)
	player.set("_scatto_pronto_msec", 0)
	player.set("_ultima_direzione", Vector2.RIGHT)
	player.set("dash_distance", 400.0)
	mondo.call("_scatto")
	await _balzo_finito_da_solo()
	_controlla(player.global_position.x < varco.global_position.x,
		"il balzo ha attraversato l'erba alta: la falce diventa decorazione")
	varco.queue_free()
	await process_frame

	# --- 7. Con riduzione movimento la meccanica resta intera -----------------
	mondo.set("reduced_motion", true)
	player.reduced_motion = true
	player.set("_scatto_pronto_msec", 0)
	player.set("dash_distance", ExpeditionModules.SCATTO_DISTANZA)
	partenza = player.global_position
	_controlla(bool(player.scatta()),
		"con riduzione movimento il balzo non parte: un'impostazione di accessibilita' ha tolto un verbo")
	await _balzo_finito_da_solo()
	_controlla(partenza.distance_to(player.global_position) > ExpeditionModules.SCATTO_DISTANZA * 0.5,
		"con riduzione movimento il balzo non sposta")
	_controlla(mondo.find_child("EliScattoScia", true, false) == null,
		"con riduzione movimento la scia viene disegnata lo stesso")

	await _esito(mondo)

func _esito(mondo: Node) -> void:
	root.remove_child(mondo)
	mondo.queue_free()
	current_scene = null
	await process_frame
	if _rossi.is_empty():
		print("SCATTO audit OK — attraversa le sacche, non guada, non apre i varchi, si ricarica, non costa niente")
		quit(0)
		return
	for riga in _rossi:
		printerr("SCATTO audit FALLITO — %s" % riga)
	quit(1)
