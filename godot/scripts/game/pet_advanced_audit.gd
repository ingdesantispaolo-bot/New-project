extends SceneTree

## **Il Custode avanzato: repertorio, regali, opinioni, duetto.** (4 agosto 2026)
##
## Vedi docs/CUSTODE_LIVELLO_AVANZATO.md. Questo audit tiene i quattro pezzi che
## quello studio ha trovato mancanti, e in particolare il difetto che ne ha reso
## necessario lo studio: `pet_antics.gd` aveva un ramo dedicato allo starnuto
## dentro una prova, e `sneeze` non esisteva nel catalogo. Un ramo morto non si
## vede finché qualcuno non lo cerca — quindi qui lo si cerca ogni volta.
##
## GUARDRAIL verificati, non solo descritti: il legame non scende mai, nessun
## regalo dà un vantaggio, e dentro una prova l'unica combinella ammessa resta
## lo starnuto.

func _init() -> void:
	var failures: Array = []

	# --- 1. Il repertorio ------------------------------------------------------
	if PetAntics.CATALOG.size() < 16:
		failures.append("solo %d combinelle su 16 promesse" % PetAntics.CATALOG.size())
	if not PetAntics.CATALOG.has("sneeze"):
		failures.append("«sneeze» manca dal catalogo: il ramo dentro la prova è morto")
	for step in PetAntics.BOND_UNLOCKS:
		var antic := str(step["antic"])
		if not PetAntics.CATALOG.has(antic):
			failures.append("il legame sblocca «%s», che non esiste nel catalogo" % antic)
	for base_antic in PetState.BASE_ANTICS:
		if not PetAntics.CATALOG.has(str(base_antic)):
			failures.append("combinella di base «%s» assente dal catalogo" % str(base_antic))
	# Ogni combinella deve essere raggiungibile: o è di base, o la sblocca il legame.
	var raggiungibili: Array = Array(PetState.BASE_ANTICS).duplicate()
	for step in PetAntics.BOND_UNLOCKS:
		raggiungibili.append(str(step["antic"]))
	for antic_id in PetAntics.CATALOG.keys():
		if not raggiungibili.has(str(antic_id)):
			failures.append("«%s» è nel catalogo ma non la sblocca niente" % str(antic_id))

	# --- 2. Il legame sblocca davvero, e non scende mai ------------------------
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	PetState.grant(save, 1)
	var iniziali: int = PetState.antics(save).size()
	PetState.add_bond(save, 1.0)
	var finali: int = PetState.antics(save).size()
	if finali <= iniziali:
		failures.append("a legame pieno il repertorio non è cresciuto (%d → %d)" % [iniziali, finali])
	if finali != PetAntics.CATALOG.size():
		failures.append("a legame pieno mancano ancora %d combinelle" % [
			PetAntics.CATALOG.size() - finali])
	var legame_pieno := PetState.bond(save)
	PetState.add_bond(save, -0.5)
	if PetState.bond(save) < legame_pieno:
		failures.append("il legame è sceso: deve essere monotono per contratto")

	# --- 3. I regali ----------------------------------------------------------
	var prima: int = PetState.gifts(save).size()
	var voce := PetState.register_gift(save, "sasso", 7)
	if voce.is_empty() or PetState.gifts(save).size() != prima + 1:
		failures.append("un regalo valido non è stato registrato")
	elif int(voce.get("world", 0)) != 7 or str(voce.get("date", "")) == "":
		failures.append("il regalo non ricorda dove e quando: senza, non è un ricordo")
	if not PetState.register_gift(save, "non-esiste", 1).is_empty():
		failures.append("un regalo inventato è stato accettato")
	if PetGifts.total_count() < 12:
		failures.append("troppi pochi regali diversi (%d): la collezione si ripete subito" % PetGifts.total_count())

	# --- 4. Le opinioni sugli abitanti ----------------------------------------
	for npc_id in PetAntics.OPINIONI.keys():
		var opinione := PetAntics.opinion_for(str(npc_id))
		var segnale := str(opinione.get("signal", ""))
		if not PetExpressionEngine.GAME_SIGNALS.has(segnale):
			failures.append("l'opinione su %s usa il segnale sconosciuto «%s»" % [npc_id, segnale])
		var riga := str(opinione.get("line", ""))
		if not riga.contains("%s"):
			failures.append("l'opinione su %s non nomina il Custode" % npc_id)
	if PetAntics.OPINIONI.size() < 6:
		failures.append("solo %d opinioni: docs/PET_CUSTODE.md §3.4 ne elenca sette" % PetAntics.OPINIONI.size())

	# --- 5. I guard-rail che questo lavoro non può rompere ---------------------
	if not PetExpressionEngine.NEGATIVE_FACES.is_empty():
		failures.append("sono comparse espressioni negative: nessun errore può produrre delusione")
	for segnale in ["meet_beloved", "meet_shy", "meet_fond"]:
		var faccia := PetExpressionEngine.face_for(segnale)
		if faccia == "sereno":
			failures.append("il segnale «%s» non ha una faccia propria" % segnale)

	# --- 6. Dentro una prova solo lo starnuto ---------------------------------
	var antics := PetAntics.new()
	antics.configure(PetAntics.CATALOG.keys(), false)
	var partite: Array = []
	for i in range(12):
		var avviata := antics.try_start("exercise", true)
		if avviata != "":
			partite.append(avviata)
			antics.set_blocked(true)
			antics.set_blocked(false)
	for avviata in partite:
		if str(avviata) != "sneeze":
			failures.append("dentro una prova è partita «%s»: solo lo starnuto è ammesso" % avviata)
	antics.free()

	if failures.is_empty():
		print("PET ADVANCED audit OK — %d combinelle, %d regali, %d opinioni, legame monotono" % [
			PetAntics.CATALOG.size(), PetGifts.total_count(), PetAntics.OPINIONI.size()])
		quit(0)
	else:
		print("CUSTODE ROSSO — %d problemi:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		quit(1)
