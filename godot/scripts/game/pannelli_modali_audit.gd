extends SceneTree

## **Una schermata per volta, e il passo che le corrisponde.** (5 settembre 2026)
##
## Segnalazione di gioco: *«clicca il tasto per procurarsi la falcetta, procede
## alla prova, e dopo alcune domande corrette il programma si blocca»*.
##
## La riparazione in sé non era rotta — questa prova la gioca dall'inizio alla
## fine e finisce, con la falce consegnata. Rotto era **il contorno**: il Custode
## si concede alla prima sessione conclusa, quindi la richiesta del suo nome si
## apriva esattamente lì, e da lì in poi due difetti diversi.
##
##   1. Il pannello del nome faceva `grab_focus()` su una `LineEdit`. Su tablet e
##      su Web quello apre la tastiera di sistema: copre la scena, si prende i
##      tasti, e il gioco **sembra fermo mentre non lo è**.
##   2. Chiudendo un dialogo con un minigioco di personaggio già aperto,
##      `_on_dialogue_closed` restituiva il passo **prima** di decidere, e
##      `_apri_minigioco_personaggio` usciva subito perché il pannello c'era già:
##      il giocatore restava libero di camminare **sotto una schermata modale**.
##      Da fuori è indistinguibile da un blocco — si tocca la scena e risponde
##      qualcos'altro.
##
## ## Perché serviva un audit nuovo
##
## Nessuno giocava questa strada. `minimission_audit` guarda i dati e non entra
## in scena; `roundtrip_audit` scavalca chiamando `_on_exercise_finished`. Il
## ciclo domanda-per-domanda di una riparazione, e soprattutto **quello che
## succede dopo**, non li percorreva nessuno.
##
## ## L'invariante, in due righe
##
## Mai **due** schermate modali insieme; e il passo di Eli è spento **se e solo
## se** ce n'è una aperta. Non è una regola di stile: le due metà sbagliate di
## questa invariante sono i due modi in cui un bambino dice «si è bloccato».

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")
## I pannelli che chiedono un gesto e fermano il mondo. Il quadro degli obiettivi
## e il dialogo sono a schermo intero; il minigioco pure. La richiesta del nome
## del Custode NON è qui, ed è una scelta: è rimandabile per contratto, quindi
## non ferma il passo — ma proprio per questo non può stare sotto un'altra.
const MODALI := ["ObjectivePanel", "DialogueBox", "ShelfMinigamePanel",
	"CycleMinigamePanel", "TraceMinigamePanel", "RadioMinigamePanel",
	"MarketMinigamePanel", "CircuitMinigamePanel", "LeverMinigamePanel",
	"SeesawMinigamePanel", "VibrationMinigamePanel", "GlyphMinigamePanel",
	"KinshipMinigamePanel", "ControlledTrialMinigamePanel", "EstimateMinigamePanel",
	"PileMinigamePanel", "LockMinigamePanel"]

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _fallisci(messaggio: String) -> void:
	_rossi.append(messaggio)

func _aperti(world: Node) -> Array:
	var out: Array = []
	for figlio in world.get("ui_layer").get_children():
		if figlio is Control and (figlio as Control).visible:
			out.append(str(figlio.name))
	return out

func _modali_aperti(world: Node) -> Array:
	var out: Array = []
	for nome in _aperti(world):
		if MODALI.has(str(nome)):
			out.append(str(nome))
	var esercizio = world.get("exercise_player")
	if esercizio != null and esercizio.visible:
		out.append("ExercisePlayer")
	return out

## L'invariante, controllata in un istante preciso della partita.
##
## Le due metà si contano su insiemi diversi, e la differenza è il difetto che
## questa guardia è nata per prendere. La **sovrapposizione** riguarda tutto ciò
## che chiede un gesto, richiesta del nome compresa: due riquadri uno sull'altro
## sono un difetto anche se uno dei due è rimandabile. Il **passo**, invece, si
## confronta solo con le schermate che fermano il mondo, perché il pannello del
## nome per contratto non lo ferma.
func _controlla(world: Node, quando: String) -> void:
	var modali := _modali_aperti(world)
	var a_gesto := modali.duplicate()
	if _aperti(world).has("PetNamingPanel"):
		a_gesto.append("PetNamingPanel")
	if a_gesto.size() > 1:
		_fallisci("%s: due schermate insieme (%s)" % [
			quando, ", ".join(PackedStringArray(a_gesto))])
	var giocatore = world.get("player")
	if giocatore == null:
		return
	var cammina := bool(giocatore.is_physics_processing())
	if not modali.is_empty() and cammina:
		_fallisci("%s: Eli cammina sotto «%s» — si tocca la scena e risponde il pannello" % [
			quando, str(modali[0])])
	if modali.is_empty() and not cammina:
		_fallisci("%s: nessuna schermata aperta e Eli non si muove — è un blocco" % quando)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["energy"] = 400
	initial["worlds"] = {"unlocked": [1, 2], "current": 2}
	initial["cosmetics"] = {"unlocked": FieldTools.consegnati_entro(1), "equipped": {}}
	var request := NativeWorldState.default_request("pannelli-modali")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 2
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	current_scene = world
	for _g in range(30):
		await process_frame

	var gameplay := world.get("gameplay") as OutdoorGameplay
	_controlla(world, "all'ingresso nel mondo")

	# La riparazione del mondo 2: quella che consegna la falce.
	var incarico_id := ""
	var payload: Dictionary = {}
	for evento_data in Array(world.get("mission_events")):
		var evento: Dictionary = evento_data
		if str(evento.get("kind", "")) != "minimission":
			continue
		incarico_id = str(evento.get("id", ""))
		var area := world.find_child(
			"MissionEvent_%s" % incarico_id.replace("-", "_"), true, false) as Area2D
		if area != null:
			payload = area.get_meta("payload", {})
		break
	if incarico_id == "" or payload.is_empty():
		_fallisci("il mondo 2 non ha una riparazione raggiungibile")
		_chiudi(world)
		return
	if not gameplay.try_start_minimission(payload, incarico_id):
		_fallisci("la riparazione del mondo 2 non si avvia")
		_chiudi(world)
		return
	await process_frame

	var esercizio = world.get("exercise_player")
	var conclusa := {"si": false}
	esercizio.session_finished.connect(func(_r): conclusa["si"] = true)
	var giri := 0
	while not bool(conclusa["si"]) and giri < 40:
		giri += 1
		var indice: int = esercizio._index
		if indice < 0 or indice >= esercizio._nodes.size():
			_fallisci("la riparazione si è fermata al nodo %d di %d" % [
				indice, esercizio._nodes.size()])
			break
		Autoplay.solve(esercizio, esercizio._nodes[indice], true)
		await process_frame
		esercizio._advance()
		await process_frame
	if not bool(conclusa["si"]):
		_fallisci("la riparazione non si è chiusa in %d giri" % giri)
	for _g in range(10):
		await process_frame

	# **Il momento della segnalazione**: prova conclusa, strumento consegnato,
	# Custode appena arrivato.
	if not gameplay.reward_manager.owned(FieldTools.FALCE):
		_fallisci("la riparazione del mondo 2 non ha consegnato la falce")
	_controlla(world, "appena finita la riparazione")

	# E il seguito: un dialogo che si chiude puo' aprire il minigioco del
	# personaggio proprio mentre la richiesta del nome e' ancora lì.
	for npc in ["w02-corinna", "w02-bruno"]:
		world.call("_on_dialogue_closed", npc)
		for _g in range(10):
			await process_frame
		_controlla(world, "chiuso il dialogo con «%s»" % npc)

	_chiudi(world)

func _chiudi(world: Node) -> void:
	world.queue_free()
	await process_frame
	current_scene = null
	if _rossi.is_empty():
		print("PANNELLI MODALI audit OK — una schermata per volta, e il passo la segue")
		quit(0)
		return
	for riga in _rossi:
		printerr("PANNELLI MODALI audit FALLITO — %s" % riga)
	quit(1)
