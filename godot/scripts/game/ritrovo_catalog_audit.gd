extends SceneTree

## Le regole di §6.3 sulle conversazioni al Ritrovo, rese vincolanti.
##
## Sono la scena in cui il mondo dimostra di vivere anche senza Eli, e bastano
## due errori a rovinarla: due battute di fila dello stesso personaggio (non è
## più una conversazione, è un monologo con interruzioni) e un congedo che
## arriva all'inizio invece che alla fine (allora stavano aspettando te, e il
## mondo torna a girare intorno al giocatore).
##
## Non misura se fanno sorridere. Misura che siano conversazioni.

const MIN_LINES := 4
const MAX_LINES := 6

## Quante volte lo stesso modo di chiamare il giocatore può ripetersi in tutte e
## ventiquattro le mappe.
##
## Non è una raffinatezza: fino al 3 agosto **66 notizie su 66** dicevano «la
## ragazzina». Un giocatore che gira sei mondi sente sei paesi diversi, che non
## si sono mai parlati, usare la stessa identica formula — e a quel punto non è
## più un paese che commenta, è il narratore travestito da abitante. Il campo
## `chiama` obbliga a decidere *come lo direbbe questo qui*, e questo tetto
## impedisce che la comodità torni da sola.
const MAX_STESSA_DESIGNAZIONE := 4

func _init() -> void:
	var failures: Array = []
	var designazioni: Dictionary = {}
	print("Conversazioni al Ritrovo — forma e alternanza\n")

	var ids: Array = RitrovoCatalog.SCENES.keys()
	ids.sort()
	for scene_id in ids:
		var data := RitrovoCatalog.SCENES[scene_id] as Dictionary
		var world := int(data.get("world", 0))
		var stadio := int(data.get("stadio", -1))
		var cast: Array = data.get("cast", [])
		var lines: Array = data.get("scena", [])

		if stadio < 0 or stadio > 2:
			failures.append("%s: stadio %d fuori da 0-2" % [scene_id, stadio])
		if cast.size() < 2 or cast.size() > 3:
			failures.append("%s: %d personaggi in scena, attesi 2-3" % [scene_id, cast.size()])
		if lines.size() < MIN_LINES or lines.size() > MAX_LINES:
			failures.append("%s: %d battute, attese %d-%d" % [
				scene_id, lines.size(), MIN_LINES, MAX_LINES])

		# Chi parla deve essere in scena, e non due volte di fila.
		var previous := ""
		for entry in lines:
			var line := entry as Dictionary
			var who := str(line.get("chi", ""))
			if not cast.has(who):
				failures.append("%s: parla %s, che non è in scena" % [scene_id, who])
			if who == previous:
				failures.append("%s: %s parla due volte di fila — non è una conversazione" % [
					scene_id, who])
			previous = who
			if str(line.get("dice", "")).strip_edges() == "":
				failures.append("%s: battuta vuota" % scene_id)

		# Ogni personaggio in scena deve dire almeno una battuta.
		for npc_id in cast:
			var spoke := false
			for entry in lines:
				if str((entry as Dictionary).get("chi", "")) == str(npc_id):
					spoke = true
					break
			if not spoke:
				failures.append("%s: %s è in scena e non parla mai" % [scene_id, npc_id])

		# I tic: la scena deve suonare come i personaggi, non come un narratore.
		for npc_id in cast:
			var marker := str((NpcCatalog.RESIDENTS.get(npc_id, {}) as Dictionary).get("ticMarker", ""))
			if marker == "":
				continue
			var found := false
			for entry in lines:
				var line := entry as Dictionary
				if str(line.get("chi", "")) != str(npc_id):
					continue
				if str(line.get("dice", "")).to_lower().contains(marker.to_lower()):
					found = true
					break
			if not found:
				failures.append("%s: %s parla senza il suo tic «%s»" % [scene_id, npc_id, marker])

		# La battuta di notizia deve stare dentro la scena e citare il giocatore
		# senza rivolgersi a lui.
		if not data.has("notizia"):
			failures.append("%s: manca la battuta di notizia" % scene_id)
		else:
			var news := data["notizia"] as Dictionary
			var index := int(news.get("indice", -1))
			if index < 0 or index >= lines.size():
				failures.append("%s: indice della notizia (%d) fuori dalla scena" % [scene_id, index])
			if not cast.has(str(news.get("chi", ""))):
				failures.append("%s: la notizia la dice qualcuno che non è in scena" % scene_id)
			var text := str(news.get("dice", ""))
			if text.strip_edges() == "":
				failures.append("%s: notizia vuota" % scene_id)
			# «senza rivolgersi a te»: nessun tu diretto nella battuta di notizia.
			for pronoun in [" tu ", " ti ", " tuo ", " tua "]:
				if (" %s " % text.to_lower()).contains(pronoun):
					failures.append("%s: la notizia si rivolge al giocatore («%s»)" % [
						scene_id, pronoun.strip_edges()])

			# Come lo chiama, e quanto spesso quel modo torna altrove.
			var chiama := str(news.get("chiama", "")).strip_edges()
			if chiama == "":
				failures.append("%s: la notizia non dichiara come chiama il giocatore" % scene_id)
			else:
				if not text.to_lower().contains(chiama.to_lower()):
					failures.append("%s: dichiara di chiamarlo «%s» e nella battuta non c'è" % [
						scene_id, chiama])
				designazioni[chiama] = int(designazioni.get(chiama, 0)) + 1

		# Il congedo arriva alla fine, e lo dice qualcuno che è in scena.
		if not data.has("congedo"):
			failures.append("%s: manca il congedo" % scene_id)
		else:
			var farewell := data["congedo"] as Dictionary
			if not cast.has(str(farewell.get("chi", ""))):
				failures.append("%s: il congedo lo dice qualcuno che non è in scena" % scene_id)
			if str(farewell.get("dice", "")).strip_edges() == "":
				failures.append("%s: congedo vuoto" % scene_id)

		print("%-8s mondo %-3d stadio %d   %d battute · %s" % [
			scene_id, world, stadio, lines.size(),
			", ".join(PackedStringArray(cast))])

	var piu_usata := 0
	for chiama in designazioni.keys():
		var quante := int(designazioni[chiama])
		piu_usata = maxi(piu_usata, quante)
		if quante > MAX_STESSA_DESIGNAZIONE:
			failures.append("«%s» è il modo in cui lo chiamano in %d scene (massimo %d): non è più un paese che commenta, è il narratore" % [
				chiama, quante, MAX_STESSA_DESIGNAZIONE])
	print("\nmodi di chiamare il giocatore: %d distinti · il più frequente in %d scene su %d" % [
		designazioni.size(), piu_usata, RitrovoCatalog.SCENES.size()])

	var complete := RitrovoCatalog.complete_worlds()
	print("\nmondi con tutte e tre le scene: %d su 24 (%s)" % [
		complete.size(), ", ".join(PackedStringArray(complete.map(func(w): return str(w))))])

	if not failures.is_empty():
		printerr("CONVERSAZIONI NON VALIDE — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Ritrovo catalog audit OK — alternanza, tic, notizia e congedo a posto")
	quit(0)
