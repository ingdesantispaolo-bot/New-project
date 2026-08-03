extends SceneTree

## La convergenza al Cuore, mondo 24.
##
## Il finale è il punto in cui è più facile fare del male al giocatore senza
## accorgersene, perché è il punto in cui il gioco tira le somme. Tre cose sono
## vincolate qui:
##
## 1. **Il Cuore non è mai vuoto.** Chi non ha portato nessun residente allo
##    stadio 2 trova comunque i sei itineranti. Un finale che premia con la
##    solitudine chi ha giocato in un altro modo è una punizione travestita da
##    conseguenza;
## 2. **nessuna battuta nomina ciò che il giocatore non ha fatto.** Non «peccato
##    che gli altri non siano venuti»: gli assenti non si nominano;
## 3. **ogni residente ha la sua riga.** Se ne mancasse una, il gioco direbbe
##    «chi ti aspetta dipende da chi hai fatto crescere» e poi, per qualcuno,
##    non manterrebbe la promessa.

const MAX_IN_SCENA := 4

## Formule che nominano l'assente o rimproverano la partita giocata.
const RIMPROVERI := [
	"peccato che", "avresti potuto", "se solo avessi", "gli altri non",
	"nessun altro è venuto", "sei da sola perché", "avresti dovuto",
	"non hai aiutato", "ti sei persa",
]

const MORTE := [
	"è morto", "è morta", "sono morti", "sono morte", "morire",
	"ucciso", "uccisa", "defunt", "perduto per sempre",
]
const NEGAZIONI := ["non ", "nessuno ", "nessuna ", "né ", "mai "]

func _init() -> void:
	var failures: Array = []
	print("Il Cuore dei Primi — chi ti aspetta, e chi non viene nominato\n")

	failures.append_array(_check_copertura())
	failures.append_array(_check_rotazione())
	failures.append_array(_check_cattedra())

	if not failures.is_empty():
		printerr("FINALE NON VALIDO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nFinale content audit OK — nessuno assente nominato, il Cuore non è mai vuoto")
	quit(0)

## Ogni residente ha la sua riga, e ogni itinerante anche.
func _check_copertura() -> Array:
	var out: Array = []
	var mancanti: Array = []
	for npc_id in NpcCatalog.RESIDENTS.keys():
		if not FinaleCatalog.RESIDENTI.has(str(npc_id)):
			mancanti.append(str(npc_id))
	if not mancanti.is_empty():
		mancanti.sort()
		out.append("%d residenti senza battuta al Cuore: %s" % [
			mancanti.size(), ", ".join(PackedStringArray(mancanti))])

	for npc_id in FinaleCatalog.RESIDENTI.keys():
		if not NpcCatalog.RESIDENTS.has(str(npc_id)):
			out.append("«%s» ha una battuta al Cuore e non è un residente" % str(npc_id))

	for itinerant_id in FinaleCatalog.ITINERANTI.keys():
		if not ItinerantCatalog.ITINERANTI.has(str(itinerant_id)):
			out.append("«%s» è al Cuore e non è un itinerante" % str(itinerant_id))
	if FinaleCatalog.ITINERANTI.size() != ItinerantCatalog.ITINERANTI.size():
		out.append("al Cuore ci sono %d itineranti su %d: al finale convergono tutti" % [
			FinaleCatalog.ITINERANTI.size(), ItinerantCatalog.ITINERANTI.size()])

	# Il testo: niente rimproveri, niente morte, niente battute vuote.
	var tutte: Dictionary = {}
	for source in [FinaleCatalog.ITINERANTI, FinaleCatalog.RESIDENTI]:
		for npc_id in (source as Dictionary).keys():
			tutte[str(npc_id)] = (source as Dictionary)[npc_id]
	var testi: Dictionary = {}
	for npc_id in tutte.keys():
		var screens: Array = tutte[npc_id]
		if screens.is_empty() or screens.size() > 3:
			out.append("%s: battuta di %d schermate al Cuore, ammesse 1-3" % [npc_id, screens.size()])
		var joined := " ".join(PackedStringArray(screens))
		if joined.strip_edges() == "":
			out.append("%s: battuta vuota al Cuore" % npc_id)
		if testi.has(joined):
			out.append("%s dice al Cuore la stessa cosa di %s" % [npc_id, str(testi[joined])])
		testi[joined] = npc_id
		out.append_array(_check_testo(str(npc_id), joined))

	print("battute al Cuore: %d residenti + %d itineranti" % [
		FinaleCatalog.RESIDENTI.size(), FinaleCatalog.ITINERANTI.size()])
	return out

## La rotazione: mai più di quattro in scena, e il Cuore mai vuoto.
func _check_rotazione() -> Array:
	var out: Array = []

	# Il caso che conta: nessun residente allo stadio 2.
	var soli := FinaleCatalog.cast_for([], 0)
	if soli.is_empty():
		out.append("senza residenti allo stadio 2 il Cuore è vuoto: sarebbe una punizione")
	if soli.size() > MAX_IN_SCENA:
		out.append("con nessun residente ci sono %d personaggi in scena" % soli.size())

	# Un caso medio e il caso pieno.
	var tutti: Array = FinaleCatalog.RESIDENTI.keys()
	tutti.sort()
	for stage2 in [[], tutti.slice(0, 3), tutti]:
		var visti: Dictionary = {}
		var waves := FinaleCatalog.waves_needed(stage2)
		for wave in range(waves):
			var cast := FinaleCatalog.cast_for(stage2, wave)
			if cast.size() > MAX_IN_SCENA:
				out.append("ondata %d: %d personaggi in scena, massimo %d" % [
					wave, cast.size(), MAX_IN_SCENA])
			for npc_id in cast:
				visti[str(npc_id)] = true
				if FinaleCatalog.lines_for(str(npc_id)).is_empty():
					out.append("%s è in scena al Cuore senza battuta" % str(npc_id))
		var attesi: int = FinaleCatalog.ITINERANTI.size() + (stage2 as Array).size()
		if visti.size() < attesi:
			out.append("con %d residenti allo stadio 2, in %d ondate parlano %d su %d" % [
				stage2.size(), waves, visti.size(), attesi])
		print("stadio 2: %-2d residenti → %d ondate, %d personaggi al Cuore" % [
			stage2.size(), waves, visti.size()])
	return out

func _check_cattedra() -> Array:
	var out: Array = []
	var scena: Array = (FinaleCatalog.CATTEDRA as Dictionary).get("scena", [])
	if scena.is_empty():
		out.append("l'assegnazione del tredicesimo posto non ha scena")
	var joined := ""
	for entry in scena:
		var screens: Array = (entry as Dictionary).get("dice", [])
		if screens.size() > 3:
			out.append("cattedra: battuta di %d schermate, ammesse 1-3" % screens.size())
		joined += " ".join(PackedStringArray(screens)) + " "
	out.append_array(_check_testo("cattedra", joined))

	# §4.3: il posto si assegna DOPO il nodo di sintesi, non all'arrivo.
	var innesco := str((FinaleCatalog.CATTEDRA as Dictionary).get("innesco", "")).to_lower()
	if not innesco.contains("sintesi"):
		out.append("l'innesco della cattedra non nomina il nodo di sintesi: si assegnerebbe a chi arriva, non a chi risolve")
	# §4.4: la domanda resta aperta.
	if str((FinaleCatalog.CATTEDRA as Dictionary).get("resta_aperta", "")).strip_edges() == "":
		out.append("il finale non dichiara cosa resta aperto: chiuderebbe una domanda che il gioco tiene aperta di proposito")
	print("\ncattedra: %d battute, assegnata dopo il nodo di sintesi, domanda aperta" % scena.size())
	return out

func _check_testo(where: String, text: String) -> Array:
	var out: Array = []
	var lower := text.to_lower()
	for formula in RIMPROVERI:
		if lower.contains(formula):
			out.append("%s: nomina ciò che il giocatore non ha fatto («%s»)" % [where, formula])
	for term in MORTE:
		var at := lower.find(term)
		while at >= 0:
			var before := lower.substr(maxi(0, at - 20), mini(20, at))
			var negato := false
			for negazione in NEGAZIONI:
				if before.contains(negazione):
					negato = true
					break
			if not negato:
				out.append("%s: dice che qualcuno è morto («%s»)" % [where, term])
			at = lower.find(term, at + 1)
	return out
