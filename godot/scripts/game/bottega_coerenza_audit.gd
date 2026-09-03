extends SceneTree

## **La bottega dice il vero sui posti e sulle persone.** (2 settembre 2026)
##
## Ogni voce del catalogo ha un campo `origine` che la lega a un luogo o a
## qualcuno — *«Pigmento delle Rovine dei Glifi»*, *«Registro dei baratti»* — ed è
## l'unica superficie con cui la bottega tocca la storia. Dal 14 agosto il campo
## `mondo` rende quel legame una regola: la voce entra in vetrina quando quel
## mondo è raggiungibile.
##
## **Nessuno però confrontava il testo con la regola.** Misurato il 2 settembre:
##
## - il **Soffietto** si consegna alla Soglia del Tempo (mondo 11) e la sua
##   origine citava la Sala delle Ere, che è il mondo 23;
## - il **Ricordo del mondo 5** lo faceva togliere dal binario a Ruggine, che
##   vive nel mondo 3 e non si sposta mai da lì;
## - la **Zavorra** — un modulo comprabile ovunque, quindi ancorato a nessun
##   mondo — citava anche lei Ruggine;
## - **sei restauri** nominavano il materiale di un mondo preciso («Quadro di
##   manutenzione della Città Macchina») senza chiedere di esserci mai stati.
##
## Otto voci su ottantatré: poche, e tutte invisibili, perché un'incoerenza
## narrativa non fa crashare niente. Un catalogo che sbaglia i posti insegna al
## bambino che i posti non contano — che è l'esatto contrario di ciò per cui il
## campo `mondo` è stato scritto.
##
## Le tre cose che questo audit verifica:
##
## 1. **Nessuna voce nomina un luogo che non è il suo.** I ventiquattro titoli
##    sono stringhe lunghe e uniche: qui non c'è ambiguità possibile.
## 2. **Nessuna voce nomina qualcuno che vive in un altro mondo.** I residenti
##    stanno in un mondo solo (gli itineranti no, e infatti sono leciti ovunque).
## 3. **L'ancoraggio non è solo un campo**: una quota dichiarata delle voci
##    ancorate nomina davvero il proprio posto o la sua gente. È un cricchetto:
##    si può alzare, mai abbassare.

const OK := "BOTTEGA COERENZA audit VERDE"

## **Quante voci ancorate devono davvero raccontare il proprio mondo.**
## Misurato il 2 settembre 2026: 25 su 62. Il numero sale quando qualcuno
## riscrive un'origine, e questa riga scende soltanto se qualcuno spiega perché.
const MINIMO_CHE_RACCONTANO := 25

## **I nomi che sono anche cose.** Il cast è scritto in italiano e alcuni nomi
## coincidono con nomi comuni: cercarli come sottostringa produrrebbe un falso
## allarme ogni volta che un'origine parla della cosa invece che della persona.
##
## La lista si tiene **corta e giustificata**: ci si finisce solo dopo aver
## verificato che nel catalogo quel nome compaia davvero come cosa. Oggi ce n'è
## uno. Se un domani un testo nuovo fa scattare l'audit su un altro nome, la
## risposta giusta è quasi sempre riscrivere il testo, non allungare questa lista.
##
##   Scintilla — bislacco del mondo 8, ma «Scintilla staccata da un quadro della
##   Tempesta» (pet-spark, mondo 20) parla di una favilla, non di lui.
const NOMI_CHE_SONO_ANCHE_COSE := ["Scintilla"]

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	var luoghi := _luoghi()
	var persone := _persone()
	_nessun_luogo_sbagliato(luoghi)
	_nessuna_persona_fuori_dal_suo_mondo(persone)
	_l_ancoraggio_si_sente(luoghi, persone)
	if errori.is_empty():
		print(OK)
	else:
		printerr("BOTTEGA COERENZA audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## I ventiquattro titoli, dal profilo dei mondi: titolo -> mondo.
func _luoghi() -> Dictionary:
	var out: Dictionary = {}
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var titolo := str(WorldProfileCatalog.profile(level).get("title", ""))
		if titolo != "":
			out[titolo] = level
	return out

## Chi vive in un mondo solo: nome -> mondo. Gli itineranti non hanno un mondo e
## restano fuori, perché citarli è lecito ovunque — girano tutti i mondi.
func _persone() -> Dictionary:
	var out: Dictionary = {}
	for gruppo in [NpcCatalog.RESIDENTS, NpcCatalog.BISLACCHI]:
		for key in (gruppo as Dictionary).keys():
			var voce: Dictionary = (gruppo as Dictionary)[key]
			var nome := str(voce.get("nome", ""))
			var world := int(voce.get("world", 0))
			if nome == "" or world <= 0 or NOMI_CHE_SONO_ANCHE_COSE.has(nome):
				continue
			out[nome] = world
	return out

func _nessun_luogo_sbagliato(luoghi: Dictionary) -> void:
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var id := str(voce.get("id", ""))
		var origine := str(voce.get("origine", ""))
		var mondo := int(voce.get("mondo", 0))
		for titolo in luoghi.keys():
			if not origine.contains(str(titolo)):
				continue
			var suo := int(luoghi[titolo])
			if mondo == suo:
				continue
			if mondo == 0:
				_fallisci("«%s» viene da %s (mondo %d) e non chiede di esserci mai stati: manca il campo mondo"
					% [id, str(titolo), suo])
			else:
				_fallisci("«%s» è ancorata al mondo %d ma nomina %s, che è il mondo %d"
					% [id, mondo, str(titolo), suo])

func _nessuna_persona_fuori_dal_suo_mondo(persone: Dictionary) -> void:
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var id := str(voce.get("id", ""))
		var origine := str(voce.get("origine", ""))
		var mondo := int(voce.get("mondo", 0))
		for nome in persone.keys():
			if not origine.contains(str(nome)):
				continue
			var suo := int(persone[nome])
			if mondo == suo:
				continue
			if mondo == 0:
				_fallisci("«%s» si compra ovunque ma cita %s, che vive solo nel mondo %d"
					% [id, str(nome), suo])
			else:
				_fallisci("«%s» è ancorata al mondo %d ma cita %s, che vive nel mondo %d"
					% [id, mondo, str(nome), suo])

## **L'ancoraggio deve sentirsi.** Un campo `mondo` che il testo non nomina è un
## requisito invisibile: il bambino legge una scheda che parla di niente e trova
## scritto «DA TROVARE · ROVINE DEI GLIFI» senza capire perché.
func _l_ancoraggio_si_sente(luoghi: Dictionary, persone: Dictionary) -> void:
	var ancorate := 0
	var raccontano := 0
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var mondo := int(voce.get("mondo", 0))
		if mondo <= 0:
			continue
		ancorate += 1
		var origine := str(voce.get("origine", ""))
		var parla := false
		for titolo in luoghi.keys():
			if int(luoghi[titolo]) == mondo and origine.contains(str(titolo)):
				parla = true
				break
		if not parla:
			for nome in persone.keys():
				if int(persone[nome]) == mondo and origine.contains(str(nome)):
					parla = true
					break
		if parla:
			raccontano += 1
	print("  voci ancorate: %d · che nominano il proprio posto o la sua gente: %d" % [
		ancorate, raccontano])
	if raccontano < MINIMO_CHE_RACCONTANO:
		_fallisci("solo %d voci ancorate su %d raccontano il proprio mondo (minimo %d)"
			% [raccontano, ancorate, MINIMO_CHE_RACCONTANO])
