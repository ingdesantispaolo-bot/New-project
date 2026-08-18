extends SceneTree

## Verifica il contratto su cui si appoggia l'aggancio reale in `outdoor_world.gd`
## (16 agosto 2026, `_open_npc_dialogue`): ogni itinerante riceve, mescolata al
## resto del riempimento, esattamente una battuta della leggenda dell'Ingegnere
## nella propria voce di registro — deterministica (stesso `npc_id` → stessa
## riga, sempre), leggibile, e mai identica a una battuta già autorata per quel
## personaggio in `itinerant_catalog.gd`.
##
## Non instanzia `outdoor_world.tscn` (pesante, richiede asset del mondo): la
## formula di selezione — `leggenda[absi(hash(npc_id)) % leggenda.size()]` — è
## banale abbastanza da riprodurre qui e verificare contro il catalogo reale
## degli itineranti, che è la parte che può disallinearsi silenziosamente
## (registro cambiato, id rinominato).

func _init() -> void:
	var failures: Array = []

	for itinerant_id in ItinerantCatalog.ITINERANTI.keys():
		var npc := ItinerantCatalog.ITINERANTI[itinerant_id] as Dictionary
		var registro := str(npc.get("registro", ""))
		var leggenda := EngineerLegendCatalog.for_registro(registro)
		if leggenda.is_empty():
			failures.append("%s: registro «%s» senza voce nella leggenda dell'Ingegnere" % [itinerant_id, registro])
			continue
		var scelta: Array = leggenda[absi(hash(str(itinerant_id))) % leggenda.size()]
		if scelta.is_empty():
			failures.append("%s: la riga scelta dalla leggenda è vuota" % itinerant_id)
			continue
		for screen in scelta:
			if str(screen).strip_edges() == "":
				failures.append("%s: la leggenda ha una schermata vuota" % itinerant_id)
		if scelta.size() > 3:
			failures.append("%s: la leggenda ha %d schermate, massimo 3" % [itinerant_id, scelta.size()])
		var testo_scelta := "|".join(PackedStringArray(scelta))
		for line_data in ItinerantCatalog.all_lines(str(itinerant_id)):
			if "|".join(PackedStringArray(line_data)) == testo_scelta:
				failures.append("%s: la riga della leggenda coincide con una battuta già autorata" % itinerant_id)

	if not failures.is_empty():
		printerr("ENGINEER LEGEND WIRING audit ROSSO — %d problemi:" % failures.size())
		for f in failures:
			printerr("  - %s" % f)
		quit(1)
		return
	print("Engineer legend wiring audit OK — ogni itinerante riceve una riga di leggenda coerente col proprio registro")
	quit(0)
