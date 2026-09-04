extends SceneTree

## **Con gli attrezzi che hai all'arrivo, tutte e dodici le materie si allenano.**
## (4 settembre 2026)
##
## Segnalazione di gioco: *«al livello 2 non riesco a recuperare la falcetta per
## completare il livello»*. Era vero, ed era un blocco.
##
## Chi arrivava al mondo 2 aveva la sola torcia — la falce la consegna la
## riparazione di quel mondo, che non è ancora stata fatta — e in quello stato
## **sette materie su dodici** erano allenabili: coding, elettronica, matematica,
## musica e storia stavano tutte dietro l'erba alta. Il gate chiede tutte e
## dodici, quindi il mondo non si chiudeva. Stessa forma al mondo 5 (7/12), al 7
## (9/12) e all'11 (11/12).
##
## ## Perché nessuna guardia lo prendeva
##
## `tool_verticality_audit` controlla due cose, e sono le due sbagliate per
## questo difetto: che nessun evento con `countsForGate` stia dietro una chiave,
## e che nessuna palestra stia dietro una chiave **futura**. Ma la copertura
## delle dodici materie non passa da `countsForGate` — si calcola sulle materie
## effettivamente allenate — e la falce, al mondo 2, non è una chiave futura: è
## quella del mondo, in elenco fra le «già consegnabili» mentre sta ancora nelle
## mani di chi la consegna.
##
## Il buco aveva esattamente la forma della segnalazione, ed è il motivo per cui
## questo audit misura una cosa sola, ma dal punto di vista del bambino:
## **apri il mondo con quello che hai in mano quando ci entri, e conta le materie
## che puoi davvero allenare.**
##
## ## Che cosa NON pretende
##
## Non pretende che nessuna palestra sia chiusa: il varco sulle palestre è una
## meccanica voluta e `equipment_traversal_audit` ne pretende una al mondo 2.
## Pretende che una palestra chiusa sia una **deviazione**, cioè che la sua
## materia resti allenabile altrove — che è ciò che il commento di
## `_create_profile_event` dichiarava già di voler fare.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

## Il mondo aperto con gli attrezzi di chi ci ARRIVA: quelli consegnati dai mondi
## precedenti, mai quello che questo mondo deve ancora dare.
func _apri(livello: int) -> Node:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	initial["cosmetics"] = {
		"unlocked": FieldTools.consegnati_entro(maxi(1, livello - 1)),
		"equipped": {},
	}
	var request := NativeWorldState.default_request("materie-raggiungibili")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	current_scene = world
	for _giro in range(30):
		await process_frame
	return world

func _prova(livello: int) -> void:
	var mondo := await _apri(livello)
	var aperte: Dictionary = {}
	var chiuse_da: Dictionary = {}
	for nodo in get_nodes_in_group("world_interactable"):
		if not (nodo is Area2D) or not mondo.is_ancestor_of(nodo):
			continue
		var kind := str(nodo.get_meta("kind", ""))
		if kind != "minigame" and kind != "encounter" and kind != "enigma":
			continue
		var payload: Dictionary = nodo.get_meta("payload", {})
		var materia := str(payload.get("subject", ""))
		if materia == "":
			continue
		if bool(mondo.call("_equipment_requirement_met", nodo)):
			aperte[materia] = true
		else:
			chiuse_da[materia] = str(payload.get("requiredTool", ""))

	var mancanti: Array = []
	for s in ApparatusConfig.SUBJECT_CYCLE:
		if not aperte.has(str(s)):
			mancanti.append(str(s))
	mancanti.sort()

	print("MATERIE RAGGIUNGIBILI| mondo %02d: %2d/12%s" % [
		livello, aperte.size(),
		"" if mancanti.is_empty() else "   MANCANO: " + ", ".join(PackedStringArray(mancanti))])

	if not mancanti.is_empty():
		var dettaglio: Array = []
		for materia in mancanti:
			var chiave := str(chiuse_da.get(str(materia), ""))
			dettaglio.append("%s (%s)" % [
				materia, "dietro «%s»" % chiave if chiave != "" else "nessun nodo"])
		_rossi.append(
			"mondo %d: %d materie su 12 non si allenano con gli attrezzi dell'arrivo — %s"
			% [livello, mancanti.size(), ", ".join(PackedStringArray(dettaglio))])

	mondo.queue_free()
	await process_frame

func _run() -> void:
	root.size = Vector2i(900, 600)
	print("MATERIE RAGGIUNGIBILI — il mondo aperto con gli attrezzi di chi ci entra\n")
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		await _prova(int(livello))
	current_scene = null
	if _rossi.is_empty():
		print("\nMATERIE RAGGIUNGIBILI audit OK — 24 mondi, dodici materie allenabili in ognuno")
		quit(0)
		return
	print("")
	for riga in _rossi:
		printerr("MATERIE RAGGIUNGIBILI audit FALLITO — %s" % riga)
	quit(1)
