extends SceneTree

## Prova giocata della stima.
##
## L'audit **gioca la strategia buona**: parte dal centro dell'intervallo e a
## ogni riscontro dimezza. Se questa entra nei tiri concessi, allora stimare non
## è tirare a indovinare — ed è la convinzione di Solano che cade dentro la
## meccanica invece che dentro una spiegazione.
##
## `character_minigame_audit` fa l'aritmetica dell'altra metà (che provarle a
## caso *non* basti). Qui si verifica che l'aritmetica corrisponda a un gioco
## vero: che i pulsanti bastino a raggiungere il valore voluto e che il
## riscontro dica sempre da che parte.

const ESTIMATE_MINIGAME_PANEL := preload("res://scripts/ui/estimate_minigame_panel.gd")

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _esegui() -> void:
	root.size = Vector2i(1024, 760)
	for npc_id in CharacterMinigameCatalog.giochi_con_archetipo(CharacterMinigameCatalog.ARCHETIPO_STIMA):
		await _gioca(str(npc_id))
	if errori.is_empty():
		print("ESTIMATE MINIGAME audit VERDE")
	else:
		printerr("ESTIMATE MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)

## Il valore attualmente impostato, letto dal quadrante — cioè da quello che
## vede il bambino, non da una variabile interna.
func _valore(pannello: Control) -> int:
	var quadrante := pannello.find_child("EstimateDial", true, false) as Label
	if not is_instance_valid(quadrante):
		return -1
	var pezzi := quadrante.text.split(" ", false)
	return int(str(pezzi[pezzi.size() - 1])) if pezzi.size() > 0 else -1

## Porta il quadrante il più vicino possibile a `bersaglio` usando i passi che ha
## davvero il pannello. Se i passi non bastassero a muoversi, il gioco non
## sarebbe giocabile e l'audit se ne accorgerebbe qui.
func _porta_a(pannello: Control, bersaglio: int) -> void:
	var passi: Array = ESTIMATE_MINIGAME_PANEL.PASSI
	for _giro in 60:
		var attuale := _valore(pannello)
		var scarto := bersaglio - attuale
		if absi(scarto) < 1:
			return
		var migliore := -1
		var resto := absi(scarto)
		for i in passi.size():
			var passo := int(passi[i])
			if sign(passo) != sign(scarto):
				continue
			var dopo := absi(scarto - passo)
			if dopo < resto:
				resto = dopo
				migliore = i
		if migliore < 0:
			return
		(pannello.find_child("EstimateStep_%d" % migliore, true, false) as Button).pressed.emit()

func _gioca(npc_id: String) -> void:
	var scheda := CharacterMinigameCatalog.scheda(npc_id)
	var parametri: Dictionary = scheda.get("parametri", {})
	var intervallo := int(parametri.get("intervallo", 120))
	var tiri := int(parametri.get("tiri", 7))
	var bersagli := int(parametri.get("bersagli", 3))
	var pannello := ESTIMATE_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, presi: int, totale: int): esito["value"] = [vinto, presi, totale])
	pannello.avvia(scheda, true)
	await process_frame

	var riscontro := pannello.find_child("EstimateFeedback", true, false) as Label
	var corto := str(scheda.get("corto", "Troppo corto."))
	for _bersaglio in bersagli:
		var basso := 0
		var alto := intervallo
		var colpito := false
		for tiro in tiri:
			_porta_a(pannello, int((basso + alto) / 2))
			var provato := _valore(pannello)
			(pannello.find_child("EstimateFireButton", true, false) as Button).pressed.emit()
			if not esito["value"].is_empty():
				colpito = true
				break
			if riscontro.text == corto:
				basso = provato
			elif riscontro.text == str(scheda.get("lungo", "Troppo lungo.")):
				alto = provato
			else:
				# Né corto né lungo: il bersaglio è stato preso e ne è arrivato
				# un altro. L'intervallo riparte intero.
				colpito = true
				break
		if not colpito and esito["value"].is_empty():
			_fallisci("%s: dimezzando non si prende un bersaglio in %d tiri" % [npc_id, tiri])
			break
	if esito["value"].is_empty() or not bool(esito["value"][0]):
		_fallisci("%s: la strategia che stringe non ha vinto: %s" % [npc_id, str(esito["value"])])
	pannello.queue_free()
	await process_frame
