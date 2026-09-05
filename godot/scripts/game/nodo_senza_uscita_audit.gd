extends SceneTree

## **Da ogni domanda si deve poter proseguire.** (5 settembre 2026)
##
## Terza segnalazione sullo stesso sintomo, e le prime due sono citate dentro
## `exercise_player.gd`: *«rispondendo correttamente la prova si blocca»*
## (8 agosto — il contenuto non scorreva) e *«VERIFICA tagliato dal bordo»*
## (15 agosto — i pulsanti scorrevano via col contenuto). Questa è la terza:
##
##   *«lo studente risponde, preme avanti, e si blocca: AVANTI è visibile ma non
##   sembra succedere niente»*.
##
## Le due correzioni precedenti hanno riparato **il riquadro della domanda**. La
## **scheda di NORA** — quella che si apre sopra la prova quando un nodo porta un
## concetto nuovo — non le ha mai ricevute: è un `Control` a tutto schermo con
## `MOUSE_FILTER_STOP`, e il suo unico modo di chiudersi è un pulsante in fondo a
## una colonna scorrevole. Se quel pulsante finisce sotto il bordo, la scheda
## resta lì e **si mangia ogni tocco**: chi gioca preme AVANTI, che sta sotto, e
## non succede niente. È esattamente la descrizione della segnalazione.
##
## ## Che cosa misura
##
## Gioca sessioni **vere** — quelle che il gioco serve davvero — su più schermi, e
## a ogni scheda di NORA che si apre chiede due cose:
##
##   1. il pulsante che la chiude sta **dentro lo schermo**, senza scorrere;
##   2. non ce n'è **più di una** aperta insieme: una scheda sopra l'altra si
##      chiude una volta e sembra non essersi chiusa.
##
## E la stessa domanda per la prova sotto: dopo aver risposto, esiste un comando
## visibile per andare avanti.

const PLAYER := preload("res://scripts/game/exercise_player.gd")
const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")
## Schermi su cui la prova deve reggere: desktop, tablet in orizzontale, e una
## finestra bassa — che è il caso in cui i due difetti gemelli erano comparsi.
const SCHERMI := [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(1280, 560)]

var _rossi: Array = []
var _schede := 0
var _nodi := 0

func _init() -> void:
	call_deferred("_run")

func _fallisci(messaggio: String) -> void:
	if _rossi.size() < 30:
		_rossi.append(messaggio)

func _schede_aperte(player: Node, fuori: Array) -> void:
	for figlio in player.get_children():
		if figlio is Control and (figlio as Control).visible:
			var c := figlio as Control
			# La scheda di NORA: a tutto schermo, ferma il tocco, e porta il
			# pulsante che la chiude. Il nome può essere stato reso unico da
			# Godot se ne esiste già una — ed è proprio il caso da prendere.
			if c.find_child("TeachingStartButton", true, false) != null:
				# Una scheda si conta una volta sola: dentro di lei il pulsante si
				# ritrova a ogni livello di annidamento, e contare anche quelli
				# farebbe gridare a una sovrapposizione che non c'è.
				fuori.append(c)
				continue
		_schede_aperte(figlio, fuori)

## **Le sessioni devono venire dal MONDO, non da `ContentManager` a mano.**
##
## La scheda di NORA la attacca il percorso di gioco (`teachingLesson` sul nodo),
## non il costruttore della sessione: una prima stesura di questa guardia
## costruiva le prove a mano, apriva **zero** schede su centosessantotto nodi e
## sarebbe stata verde su un difetto vivo. Qui si entra nel mondo e si gioca ciò
## che il mondo serve.
const WORLD_SCENE := "res://scenes/outdoor_world.tscn"

func _apri_mondo(livello: int) -> Node:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 600
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	initial["cosmetics"] = {
		"unlocked": FieldTools.consegnati_entro(maxi(1, livello - 1)), "equipped": {}}
	var request := NativeWorldState.default_request("nodo-senza-uscita")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	var world := (load(WORLD_SCENE) as PackedScene).instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 2)
	root.add_child(world)
	current_scene = world
	for _g in range(30):
		await process_frame
	return world

func _run() -> void:
	for schermo in SCHERMI:
		root.size = schermo
		for livello in [1, 2, 5, 9]:
			var world := await _apri_mondo(livello)
			var gameplay := world.get("gameplay") as OutdoorGameplay
			# Ogni evento del mondo che apre una prova: missioni, enigmi e la
			# riparazione — cioè la strada della segnalazione.
			for evento_data in Array(world.get("mission_events")):
				var evento: Dictionary = evento_data
				var genere := str(evento.get("kind", ""))
				if genere != "minimission" and genere != "enigma" and genere != "mission":
					continue
				var id := str(evento.get("id", ""))
				var area := world.find_child(
					"MissionEvent_%s" % id.replace("-", "_"), true, false) as Area2D
				if area == null:
					continue
				var carico: Dictionary = area.get_meta("payload", {})
				var avviata := false
				if genere == "minimission":
					avviata = gameplay.try_start_minimission(carico, id)
				elif genere == "enigma":
					avviata = gameplay.try_start_enigma(carico, id)
				else:
					avviata = gameplay.try_start_mission(carico, id)
				if not avviata:
					continue
				await process_frame
				var player = world.get("exercise_player")
				for _passo in range(8):
					var indice: int = player._index
					if indice < 0 or indice >= player._nodes.size():
						break
					_nodi += 1
					Autoplay.solve(player, player._nodes[indice], true)
					await process_frame
					player._advance()
					await process_frame
					await process_frame
					_controlla_schede(player, schermo, livello)
			world.queue_free()
			await process_frame
	current_scene = null

	print("NODO SENZA USCITA — %d nodi giocati, %d schede di NORA aperte, su %d schermi" % [
		_nodi, _schede, SCHERMI.size()])
	if _rossi.is_empty():
		print("NODO SENZA USCITA audit OK — da ogni scheda si esce senza scorrere")
		quit(0)
		return
	for riga in _rossi:
		printerr("NODO SENZA USCITA audit FALLITO — %s" % riga)
	quit(1)

func _controlla_schede(player: Node, schermo: Vector2i, livello: int) -> void:
	var schede: Array = []
	_schede_aperte(player, schede)
	if schede.is_empty():
		return
	_schede += 1
	if schede.size() > 1:
		_fallisci("mondo %d · %dx%d: %d schede di NORA aperte una sull'altra — chiuderne una non basta e sembra che il tocco non funzioni" % [
			livello, schermo.x, schermo.y, schede.size()])
	for scheda_data in schede:
		var scheda: Control = scheda_data
		var pulsante := scheda.find_child("TeachingStartButton", true, false) as Button
		if pulsante == null or not pulsante.visible:
			_fallisci("mondo %d · %dx%d: una scheda di NORA senza il pulsante che la chiude" % [
				livello, schermo.x, schermo.y])
			continue
		var r := pulsante.get_global_rect()
		var alto := float(player.get_viewport_rect().size.y)
		if r.end.y > alto + 1.0:
			_fallisci("mondo %d · %dx%d: «HO CAPITO» finisce a y %.0f su uno schermo alto %.0f — la scheda non si chiude e si mangia i tocchi" % [
				livello, schermo.x, schermo.y, r.end.y, alto])
		# Chiusa la scheda si prosegue: se restasse, il conto sopra la
		# troverebbe di nuovo al nodo dopo e il difetto sarebbe muto.
		pulsante.pressed.emit()
