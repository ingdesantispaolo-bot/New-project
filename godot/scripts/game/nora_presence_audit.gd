extends SceneTree

## **I cinque stadi visivi di NORA sono raggiungibili e distinti.** (18 agosto 2026)
##
## Il difetto che questo audit impedisce è già successo una volta, in un'altra
## forma: l'arte dei cinque ritratti era stata prodotta e integrata soltanto nel
## prototipo Phaser. Il gioco vero mostrava una figura vettoriale, e nessun
## controllo se ne accorgeva perché nessuno aveva scritto che cosa il volto di
## NORA dovesse fare.
##
## Qui si pretende:
##   1. cinque stadi, con cinque immagini DIVERSE (una svista di copia-incolla
##      renderebbe due stadi indistinguibili senza nessun errore a schermo);
##   2. ogni stadio raggiungibile percorrendo i ventiquattro apparati, e nessuno
##      saltato — uno stadio che nessun giocatore può vedere è arte sprecata;
##   3. la progressione monotòna: NORA non torna mai indietro.
##
## Uso: godot --headless --path godot --script res://scripts/game/nora_presence_audit.gd

const NoraPortrait = preload("res://scripts/ui/nora_portrait.gd")

func _init() -> void:
	var ritratto = NoraPortrait.new()

	# 1) Cinque stadi con arte distinta.
	var stadi: Array = NoraPortrait.STADI
	assert(stadi.size() == 5, "servono cinque stadi, trovati %d" % stadi.size())
	var viste: Dictionary = {}
	for stadio_data in stadi:
		var s: Dictionary = stadio_data
		var arte := s["arte"] as Texture2D
		assert(arte != null, "stadio %s senza ritratto" % str(s["id"]))
		var percorso := arte.resource_path
		assert(not viste.has(percorso),
			"due stadi condividono lo stesso ritratto (%s): sarebbero indistinguibili" % percorso)
		viste[percorso] = true
		assert(str(s["titolo"]).strip_edges() != "", "stadio %s senza titolo" % str(s["id"]))

	# 2) Ogni stadio è raggiungibile riparando gli apparati, uno per uno.
	var incontrati: Dictionary = {}
	var ordine: Array = []
	for apparati in range(0, 25):
		ritratto.set_integrity(float(apparati) / 24.0)
		var id := ritratto.stadio_id()
		if not incontrati.has(id):
			incontrati[id] = apparati
			ordine.append(id)
	for stadio_data in stadi:
		var s: Dictionary = stadio_data
		assert(incontrati.has(str(s["id"])),
			"stadio %s mai raggiunto in ventiquattro apparati" % str(s["id"]))

	# 3) L'ordine incontrato è quello dichiarato: NORA non torna indietro.
	var atteso: Array = []
	for stadio_data in stadi:
		atteso.append(str((stadio_data as Dictionary)["id"]))
	assert(ordine == atteso,
		"la progressione non è monotòna: attesa %s, incontrata %s" % [str(atteso), str(ordine)])

	# Il primo stadio parte da nave spenta, l'ultimo si accende solo a nave intera.
	assert(ritratto.stadio_id() == "guardian",
		"a ventiquattro apparati NORA deve essere Custode, non %s" % ritratto.stadio_id())
	ritratto.set_integrity(0.0)
	assert(ritratto.stadio_id() == "dormant",
		"a nave spenta NORA deve essere quasi spenta, non %s" % ritratto.stadio_id())

	var righe: Array = []
	for id in ordine:
		righe.append("%s@%d" % [str(id), int(incontrati[id])])
	print("NORA presence audit OK — %s" % " → ".join(PackedStringArray(righe)))
	quit(0)
