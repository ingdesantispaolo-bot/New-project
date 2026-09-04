extends SceneTree

## **Quanti minigiochi dei personaggi si vincono toccando a caso.**
## (21 agosto 2026)
##
## Domanda del committente: *«i minigiochi dei personaggi sono attivi e
## collaudati?»*. Attivi sì — quindici archetipi, quarantasei personaggi, tutti
## con un pannello e tutti con un audit. Ma nessuno di quegli audit chiede la
## cosa che conta: **si vincono senza capirli?**
##
## È la misura che ha smascherato il duello dei verbi. Lì un giocatore che
## toccava rune a caso vinceva il 90% dei duelli al mondo 1, e il difetto non si
## vedeva giocando: si vede solo contando. Qui la stessa domanda, generalizzata.
##
## ## Come gioca il CIECO
##
## Non sa niente. A ogni giro guarda i pulsanti **abilitati e visibili** del
## pannello, ne tocca uno a caso, e aspetta un fotogramma. Non tocca mai
## «LASCIA PERDERE», perché quello non è giocare: è andarsene.
##
## Si ferma quando il pannello dichiara l'esito, o dopo un tetto di tocchi.
##
## ## Come si legge
##
## Un archetipo che il CIECO vince spesso non sta misurando quello che dice di
## misurare. È il numero da guardare prima di dire che un minigioco «funziona».
##
## ## Quello che questa sonda NON misura, e va detto
##
## **La velocità del dito.** Il CIECO tocca un pulsante per fotogramma, cioè
## sessanta volte al secondo: nei giochi col cronometro il tempo non gli finisce
## mai, e la sua percentuale è un **tetto** che nessun bambino raggiunge.
##
## Per quegli archetipi il numero che conta è l'altro: **quanti tocchi** servono.
## Il 21 agosto 2026 il mucchio di Tobia ne chiedeva sei — ogni tocco prendeva
## una decina, perché nascevano tutti in file piene — e adesso ne chiede
## ventiquattro. La colonna «regge il tempo?» fa il conto al posto di chi legge:
## a `RITMO_UMANO` tocchi al secondo, quei tocchi stanno dentro il cronometro?
## Se non ci stanno, un giocatore a caso perde davvero, ed è quello che serve.
##
## Uso: godot --headless --path godot --script res://scripts/game/minigiochi_cieco_probe.gd

const PARTITE := 60
const TOCCHI_MASSIMI := 90

## Quanti tocchi al secondo fa un bambino di undici anni su un tablet, con
## intenzione e non a raffica. Due: e' il ritmo di chi guarda dove tocca.
const RITMO_UMANO := 2.0

var _host: Control
var _esito := {}

func _init() -> void:
	root.size = Vector2i(1024, 640)
	_host = Control.new()
	_host.size = root.get_visible_rect().size
	root.add_child(_host)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var per_archetipo := _un_personaggio_per_archetipo()
	print("")
	print("Minigiochi dei personaggi — quanti ne vince chi tocca a caso")
	print("")
	print("ARCHETIPO      personaggio      vinti a caso   tocchi   regge il tempo?")
	var rng := RandomNumberGenerator.new()
	var peggiore := 0.0
	var peggiore_nome := ""
	for archetipo in per_archetipo.keys():
		var npc := str(per_archetipo[archetipo])
		var vinti := 0
		var tocchi_totali := 0
		for partita in range(PARTITE):
			rng.seed = hash("cieco-%s-%d" % [archetipo, partita])
			var risultato := await _una_partita(npc, rng)
			if bool(risultato.get("vinto", false)):
				vinti += 1
			tocchi_totali += int(risultato.get("tocchi", 0))
		var quota := 100.0 * float(vinti) / float(PARTITE)
		var tocchi_medi := float(tocchi_totali) / float(PARTITE)
		var secondi := float(Dictionary(CharacterMinigameCatalog.scheda(npc)
			.get("parametri", {})).get("secondi", 0.0))
		var verdetto := "niente cronometro"
		# **La quota a ritmo umano.** (4 settembre 2026)
		#
		# Il CIECO tocca un pulsante per fotogramma, sessanta volte al secondo:
		# dove c'è un cronometro il tempo non gli finisce mai, e la sua percentuale
		# è un tetto che nessun bambino raggiunge. Il mucchio l'ha mostrato nel
		# modo più netto — 100% con il cronometro che a ritmo umano lo taglia
		# fuori di tre secondi. Leggere solo la prima colonna avrebbe detto che la
		# ritaratura non era servita a niente, mentre aveva funzionato.
		#
		# Quindi la colonna che decide è questa: **con un dito umano, quel
		# giocatore a caso ce la farebbe?** Dove non c'è cronometro le due quote
		# coincidono, ed è giusto che coincidano: lì niente lo ferma.
		var quota_umana := quota
		if secondi > 0.0:
			var servono := tocchi_medi / RITMO_UMANO
			verdetto = "%s (%.0f s su %.0f)" % [
				"sì" if servono <= secondi else "NO", servono, secondi]
			if servono > secondi:
				quota_umana = 0.0
		if quota_umana > peggiore:
			peggiore = quota_umana
			peggiore_nome = str(archetipo)
		print("%-14s %-16s %10.1f%%  %6.1f   %s" % [
			archetipo, npc, quota_umana, tocchi_medi, verdetto])
	print("")
	print("Il piu' vincibile a caso, a ritmo umano: %s, %.1f%%" % [peggiore_nome, peggiore])
	print("")
	print("COME SI LEGGE")
	print("  La colonna «vinti a caso» e' gia' corretta per il ritmo umano: dove")
	print("  il cronometro taglia fuori chi tocca a caso, vale zero. Il tetto")
	print("  grezzo della sonda — che tocca sessanta volte al secondo — resta")
	print("  leggibile nella colonna dei tocchi e nel verdetto sul tempo.")
	print("")
	print("  Alto = quel minigioco si supera senza capirlo. Non e' sempre un")
	print("  difetto — nei giochi di velocita' sbagliare costa tempo, non la")
	print("  partita — ma e' il numero da guardare prima di dire «funziona».")
	quit(0)

## Un personaggio per archetipo: il primo che lo usa, così i quindici pannelli
## vengono provati tutti senza provarne quarantasei.
func _un_personaggio_per_archetipo() -> Dictionary:
	var fuori: Dictionary = {}
	for archetipo in [
			CharacterMinigameCatalog.ARCHETIPO_MUCCHIO,
			CharacterMinigameCatalog.ARCHETIPO_SCAFFALE,
			CharacterMinigameCatalog.ARCHETIPO_CICLO,
			CharacterMinigameCatalog.ARCHETIPO_TRACCIA,
			CharacterMinigameCatalog.ARCHETIPO_RADIO,
			CharacterMinigameCatalog.ARCHETIPO_MERCATO,
			CharacterMinigameCatalog.ARCHETIPO_CIRCUITO,
			CharacterMinigameCatalog.ARCHETIPO_LEVA,
			CharacterMinigameCatalog.ARCHETIPO_ALTALENA,
			CharacterMinigameCatalog.ARCHETIPO_RITMO,
			CharacterMinigameCatalog.ARCHETIPO_VIBRAZIONE,
			CharacterMinigameCatalog.ARCHETIPO_GLIFI,
			CharacterMinigameCatalog.ARCHETIPO_PARENTELA,
			CharacterMinigameCatalog.ARCHETIPO_PROVA,
			CharacterMinigameCatalog.ARCHETIPO_STIMA,
	]:
		var elenco := CharacterMinigameCatalog.giochi_con_archetipo(str(archetipo))
		if not elenco.is_empty():
			fuori[str(archetipo)] = str(elenco[0])
	return fuori

func _una_partita(npc: String, rng: RandomNumberGenerator) -> Dictionary:
	var pannello := _pannello_per(npc)
	if pannello == null:
		return {"vinto": false, "tocchi": 0}
	_esito = {}
	pannello.risolto.connect(func(vinto: bool, _presi: int, _totale: int):
		_esito = {"vinto": vinto})
	_host.add_child(pannello)
	pannello.avvia(CharacterMinigameCatalog.scheda(npc), true)
	await process_frame
	var tocchi := 0
	while _esito.is_empty() and tocchi < TOCCHI_MASSIMI:
		var candidati := _pulsanti_giocabili(pannello)
		if candidati.is_empty():
			# Nessun pulsante: e' un archetipo che avanza da solo (velocita').
			# Gli si lascia un fotogramma e si riprova.
			await process_frame
			tocchi += 1
			continue
		var scelto: Button = candidati[rng.randi_range(0, candidati.size() - 1)]
		scelto.pressed.emit()
		tocchi += 1
		await process_frame
	var vinto := bool(_esito.get("vinto", false))
	_host.remove_child(pannello)
	pannello.queue_free()
	await process_frame
	return {"vinto": vinto, "tocchi": tocchi}

## I pulsanti che un dito troverebbe: abilitati, visibili, e mai quello che
## serve ad andarsene.
func _pulsanti_giocabili(pannello: Node) -> Array:
	var fuori: Array = []
	for nodo in pannello.find_children("*", "Button", true, false):
		var bottone := nodo as Button
		if bottone == null or bottone.disabled or not bottone.is_visible_in_tree():
			continue
		if str(bottone.text).to_upper().contains("LASCIA"):
			continue
		fuori.append(bottone)
	return fuori

func _pannello_per(npc: String) -> Control:
	var scheda := CharacterMinigameCatalog.scheda(npc)
	match str(scheda.get("archetipo", "")):
		CharacterMinigameCatalog.ARCHETIPO_SCAFFALE:
			return ShelfMinigamePanel.new()
		CharacterMinigameCatalog.ARCHETIPO_CICLO:
			return preload("res://scripts/ui/cycle_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_TRACCIA:
			return preload("res://scripts/ui/trace_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_RADIO:
			return preload("res://scripts/ui/radio_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_MERCATO:
			return preload("res://scripts/ui/market_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_CIRCUITO:
			return CircuitMinigamePanel.new()
		CharacterMinigameCatalog.ARCHETIPO_LEVA:
			return LeverMinigamePanel.new()
		CharacterMinigameCatalog.ARCHETIPO_ALTALENA:
			return preload("res://scripts/ui/seesaw_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_RITMO:
			return preload("res://scripts/ui/rhythm_count_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_VIBRAZIONE:
			return preload("res://scripts/ui/vibration_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_GLIFI:
			return preload("res://scripts/ui/glyph_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_PARENTELA:
			return preload("res://scripts/ui/kinship_minigame_panel.gd").new()
		CharacterMinigameCatalog.ARCHETIPO_PROVA:
			return ControlledTrialMinigamePanel.new()
		CharacterMinigameCatalog.ARCHETIPO_STIMA:
			return EstimateMinigamePanel.new()
		_:
			return PileMinigamePanel.new()
