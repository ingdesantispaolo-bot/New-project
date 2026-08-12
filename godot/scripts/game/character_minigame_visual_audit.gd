extends SceneTree

## Verifica strutturale di **tutti** i pannelli dei minigiochi-personaggio.
##
## Prima guardava solo i tre pilot, e nel frattempo i pannelli erano diventati
## sette: ciclo, traccia, radio e mercato non avevano nessun controllo. Un audit
## che copre un terzo di quello che esiste dà la stessa sensazione di uno che
## copre tutto, ed è il modo in cui i difetti passano.
##
## Il gusto si collauda a occhio. Qui stanno le condizioni che non devono
## regredire, e sono le stesse per tutti: **la carta c'è** (senza, il pannello
## non è centrato e su tablet finisce fuori), **il glifo della convinzione c'è**
## (è il filo che lega i venticinque giochi: lo stesso segno, intatto prima e
## spezzato dopo), **i bersagli sono da dito** e **i giochi di riflessione non
## mostrano un cronometro**.

const OK := "CHARACTER MINIGAME VISUAL audit VERDE"
## La misura di un bersaglio toccabile su tablet. Sotto questa, il dito copre
## anche quello accanto.
const LATO_MINIMO := 40.0

## Per ogni archetipo: pannello, prefisso dei nodi e un personaggio che lo usa.
const BANCHI := [
	{"archetipo": "mucchio", "script": "res://scripts/ui/pile_minigame_panel.gd", "prefisso": "Pile", "npc": "w01-tobia"},
	{"archetipo": "scaffale", "script": "res://scripts/ui/shelf_minigame_panel.gd", "prefisso": "Shelf", "npc": "w02-corinna"},
	{"archetipo": "ciclo", "script": "res://scripts/ui/cycle_minigame_panel.gd", "prefisso": "Cycle", "npc": "w03-ruggine"},
	{"archetipo": "traccia", "script": "res://scripts/ui/trace_minigame_panel.gd", "prefisso": "Trace", "npc": "w03-sesto"},
	{"archetipo": "radio", "script": "res://scripts/ui/radio_minigame_panel.gd", "prefisso": "Radio", "npc": "w04-marea"},
	{"archetipo": "mercato", "script": "res://scripts/ui/market_minigame_panel.gd", "prefisso": "Market", "npc": "w04-lino"},
	{"archetipo": "circuito", "script": "res://scripts/ui/circuit_minigame_panel.gd", "prefisso": "Circuit", "npc": "w08-ciro"},
	{"archetipo": "leva", "script": "res://scripts/ui/lever_minigame_panel.gd", "prefisso": "Lever", "npc": "w05-gerbo"},
	{"archetipo": "altalena", "script": "res://scripts/ui/seesaw_minigame_panel.gd", "prefisso": "Seesaw", "npc": "w05-tilla"},
	{"archetipo": "prova", "script": "res://scripts/ui/controlled_trial_minigame_panel.gd", "prefisso": "Trial", "npc": "w10-ortensia"},
	{"archetipo": "stima", "script": "res://scripts/ui/estimate_minigame_panel.gd", "prefisso": "Estimate", "npc": "w13-solano"},
]

var errori: Array[String] = []

func _init() -> void:
	call_deferred("_esegui")

func _pretendi(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _esegui() -> void:
	root.size = Vector2i(1024, 760)

	# Nessun archetipo del catalogo può restare senza un banco qui: è il modo in
	# cui questo audit smette di coprire un terzo di quello che esiste.
	var coperti := {}
	for banco in BANCHI:
		coperti[str(banco["archetipo"])] = true
	for npc_id in CharacterMinigameCatalog.GIOCHI.keys():
		var archetipo := str(Dictionary(CharacterMinigameCatalog.GIOCHI[npc_id]).get("archetipo", ""))
		_pretendi(coperti.has(archetipo), "l'archetipo «%s» non ha un banco visivo" % archetipo)

	for banco_dato in BANCHI:
		var banco: Dictionary = banco_dato
		await _guarda(banco)

	# Il mucchio ha in più l'asset generativo e i vassoi delle decine, che sono
	# l'indizio da cui si scopre la strategia: senza, il gioco non si scopre.
	var mucchio := PileMinigamePanel.new()
	root.add_child(mucchio)
	mucchio.avvia(CharacterMinigameCatalog.scheda("w01-tobia"), false)
	await process_frame
	_pretendi(mucchio.find_child("TenTray_00", true, false) != null,
		"prima decina senza vassoio visivo")
	var primo := mucchio.find_child("Crystal_00", true, false) as Button
	_pretendi(is_instance_valid(primo) and primo.icon != null,
		"cristallo generativo non caricato")
	mucchio.queue_free()
	await process_frame

	if errori.is_empty():
		print(OK)
	else:
		printerr("CHARACTER MINIGAME VISUAL audit ROSSO")
		for errore in errori:
			printerr("  - %s" % errore)
	quit(0 if errori.is_empty() else 1)

func _guarda(banco: Dictionary) -> void:
	var prefisso := str(banco["prefisso"])
	var npc_id := str(banco["npc"])
	var scheda := CharacterMinigameCatalog.scheda(npc_id)
	var pannello: Control = load(str(banco["script"])).new()
	root.add_child(pannello)
	pannello.avvia(scheda, false)
	await process_frame

	_pretendi(pannello.find_child("%sCard" % prefisso, true, false) != null,
		"%s: nessuna carta centrata" % prefisso)
	_pretendi(pannello.find_child("%sConvictionGlyph" % prefisso, true, false) is ConvictionGlyph,
		"%s: manca il glifo della convinzione" % prefisso)
	_pretendi(pannello.find_child("%sLeaveButton" % prefisso, true, false) != null,
		"%s: non si può uscire dal minigioco" % prefisso)

	# **Il gioco di riflessione non mostra un cronometro.** Non è una preferenza
	# grafica: un orologio che scorre cambia quello che il bambino fa.
	if str(scheda.get("forma", "")) == CharacterMinigameCatalog.FORMA_RIFLESSIONE:
		_pretendi(pannello.find_child("%sClock" % prefisso, true, false) == null,
			"%s: gioco di riflessione con un cronometro sullo schermo" % prefisso)

	# Ogni pulsante che si tocca per giocare deve essere grande abbastanza. Si
	# guardano tutti, così la regola vale anche per i pannelli scritti domani.
	for nodo in _pulsanti(pannello):
		var b := nodo as Button
		var largo := maxf(b.custom_minimum_size.x, b.size.x)
		var alto := maxf(b.custom_minimum_size.y, b.size.y)
		_pretendi(largo >= LATO_MINIMO and alto >= LATO_MINIMO,
			"%s: il pulsante «%s» è %.0fx%.0f, sotto il dito" % [prefisso, b.name, largo, alto])

	pannello.queue_free()
	await process_frame

func _pulsanti(nodo: Node) -> Array:
	var trovati: Array = []
	if nodo is Button:
		trovati.append(nodo)
	for figlio in nodo.get_children():
		trovati.append_array(_pulsanti(figlio))
	return trovati
