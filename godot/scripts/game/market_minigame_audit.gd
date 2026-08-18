extends SceneTree

## Prova giocata del mercato di Lino, più la regola che il mercato deve rispettare
## per insegnare qualcosa.
##
## **La regola.** La cassetta giusta non può contenere nessuna parola della
## richiesta. Nella prima stesura la conteneva sempre — «Three silver fish,
## please» contro «THREE silver fish» — e allora il gioco si vinceva accoppiando
## le lettere, cioè **senza sapere una parola d'inglese**. Un banco così non
## smentisce la convinzione di Lino («per farsi capire bastano venti parole»):
## gliela conferma, perché dimostra che le parole non servono affatto. È lo
## stesso errore del mucchio di Tobia alla prima taratura, ed è il motivo per cui
## questa regola sta in un audit e non in un commento.

const MARKET_MINIGAME_PANEL := preload("res://scripts/ui/market_minigame_panel.gd")
## Sotto le tre lettere il confronto non significa niente: «a», «il», «of» si
## ripetono ovunque e non aiutano nessuno a indovinare.
const LUNGHEZZA_MINIMA := 3

var errori: Array[String] = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	call_deferred("_esegui")

func _parole(testo: String) -> PackedStringArray:
	var pulito := testo.to_lower()
	for segno in [",", ".", "!", "?", ":", ";", "“", "”", "\"", "'", "\n"]:
		pulito = pulito.replace(segno, " ")
	var fuori := PackedStringArray()
	for parola in pulito.split(" ", false):
		if str(parola).length() >= LUNGHEZZA_MINIMA:
			fuori.append(str(parola))
	return fuori

## Nessuna richiesta si serve accoppiando le lettere.
##
## **La regola vale solo dove significa qualcosa**, e la scheda lo dichiara con
## `senzaRicalco`. Da Lino e da Talia la richiesta è in inglese e le cassette in
## italiano: una parola in comune sarebbe una scorciatoia che salta la lingua. Da
## Elmo le tre versioni della scena sono in italiano come la scena, e il
## dettaglio decisivo **è** una parola — pretendere lì il non ricalco vorrebbe
## dire vietare al gioco di essere quello che è.
func _la_cassetta_giusta_non_ripete_la_richiesta() -> void:
	var controllati := 0
	for npc_id_dato in CharacterMinigameCatalog.giochi_con_archetipo(
			CharacterMinigameCatalog.ARCHETIPO_MERCATO):
		var npc_id := str(npc_id_dato)
		var scheda := CharacterMinigameCatalog.scheda(npc_id)
		if not bool(scheda.get("senzaRicalco", false)):
			continue
		controllati += 1
		var turni: Array = Array(scheda.get("turni", MARKET_MINIGAME_PANEL.TURNI))
		if turni.is_empty():
			turni = MARKET_MINIGAME_PANEL.TURNI
		for turno_dato in turni:
			var turno: Dictionary = turno_dato
			var richiesta := str(turno["richiesta"])
			var giusta := str(Array(turno["scelte"])[int(turno["giusta"])])
			var parole_richiesta := _parole(richiesta)
			for parola in _parole(giusta):
				if parola in parole_richiesta:
					_fallisci("%s · «%s» → «%s»: la parola «%s» sta in tutte e due, si vince accoppiando le lettere" % [
						npc_id, richiesta, giusta, parola])
	if controllati == 0:
		_fallisci("nessun mercato dichiara «senzaRicalco»: la regola non sta guardando niente")

func _esegui() -> void:
	_la_cassetta_giusta_non_ripete_la_richiesta()

	root.size = Vector2i(1024, 600)
	var pannello := MARKET_MINIGAME_PANEL.new()
	root.add_child(pannello)
	var esito := {"value": []}
	pannello.risolto.connect(func(vinto: bool, fatti: int, totale: int): esito["value"] = [vinto, fatti, totale])
	pannello.avvia(CharacterMinigameCatalog.scheda("w04-lino"), true)
	await process_frame

	var sbagliata := pannello.find_child("MarketCrate_0", true, false) as Button
	# Il confronto è sul colore e non sull'oggetto: la cassetta viene ridipinta con
	# una StyleBoxFlat nuova a ogni cliente, quindi due riferimenti diversi non
	# direbbero niente.
	var legno: Color = (sbagliata.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	sbagliata.pressed.emit()
	if not esito["value"].is_empty():
		_fallisci("un dettaglio errato ha chiuso il banco: %s" % str(esito["value"]))
	if (sbagliata.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == legno:
		_fallisci("la cassetta sbagliata non si segna: l'errore non si vede")
	# La cassetta segnata resta segnata solo per il cliente in corso.
	(pannello.find_child("MarketCrate_1", true, false) as Button).pressed.emit()
	if (sbagliata.get_theme_stylebox("normal") as StyleBoxFlat).bg_color != legno:
		_fallisci("la cassetta sbagliata è ancora rossa al cliente dopo — un errore che non c'entra più")

	for cassetta in [1, 2]:
		(pannello.find_child("MarketCrate_%d" % cassetta, true, false) as Button).pressed.emit()
	if esito["value"] != [true, 3, 3]:
		_fallisci("le richieste complete non hanno chiuso il mercato: %s" % str(esito["value"]))

	if errori.is_empty():
		print("MARKET MINIGAME audit VERDE")
	else:
		printerr("MARKET MINIGAME audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)
