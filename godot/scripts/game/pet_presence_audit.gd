extends SceneTree

## **Ogni segnale del Custode ha qualcuno che lo emette.** (14 agosto 2026)
##
## È la decisione 14 — *«una chiave del salvataggio senza lettori è un errore»* —
## applicata ai segnali, e non è un'analogia: quella decisione nomina proprio i
## segnali `near_unexplored` e `near_faded` come il quarto caso della stessa
## malattia, dichiarati il primo giorno e mai emessi.
##
## Misurato prima di questo lotto: il motore delle espressioni dichiarava
## ventuno segnali e la scena ne emetteva quindici. **Cinque erano morti**
## (`session_start`, `mission_complete`, `topic_consolidated`, `apparatus_repaired`,
## `idle`), e due chiamate passavano `"festa"` — che è una **faccia**, non un
## segnale — così il Custode restava sereno nel momento in cui viene consegnato
## al bambino e in quello in cui riceve un nome. La sua stessa presentazione.
##
## Le quattro cose che verifica:
##
## 1. **Nessun segnale dichiarato resta senza emittente**, salvo quelli in
##    `IN_ATTESA`, che devono dire perché e di chi aspettano.
## 2. **Nessuno emette una faccia al posto di un segnale.** È l'errore che non dà
##    nessun sintomo: `face_for` non trova la chiave e ripiega sul volto a
##    riposo, quindi la reazione sembra funzionare e non c'è.
## 3. **Ogni segnale ha una faccia dichiarata**, e nessun esito negativo mappa su
##    una faccia che rimprovera (regola già del motore, riverificata di qui).
## 4. **Il Custode non dà mai vantaggi.** Nessun segnale nasce da energia,
##    frammenti, acquisti o moduli: è la decisione 12, e vale anche per ciò che
##    lo fa reagire, non solo per ciò che fa.

const OK := "PET PRESENCE audit VERDE"
const RADICE := "res://scripts"
const MOTORE := "res://scripts/game/pet_expression_engine.gd"

## Nessun segnale è più in attesa: C-G9 ha portato il Custode nella nave e
## `apparatus_repaired` nasce ora dal ramo di esame realmente superato.
const IN_ATTESA := {}

## Parole che, se comparissero accanto a una reazione del Custode, direbbero che
## sta guardando la ricchezza invece dell'apprendimento.
const VIETATE := ["energy", "energia", "fragments", "frammenti", "cosmetic", "module"]

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _leggi(percorso: String) -> String:
	var file := FileAccess.open(percorso, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _raccogli(cartella: String, out: Dictionary) -> void:
	var dir := DirAccess.open(cartella)
	if dir == null:
		return
	dir.list_dir_begin()
	var nome := dir.get_next()
	while nome != "":
		var percorso := "%s/%s" % [cartella, nome]
		if dir.current_is_dir():
			_raccogli(percorso, out)
		elif nome.ends_with(".gd") and not (
				nome.contains("_audit") or nome.contains("probe") or nome.contains("autoplay")):
			out[percorso] = _leggi(percorso)
		nome = dir.get_next()
	dir.list_dir_end()

func _sorgenti() -> Dictionary:
	var out: Dictionary = {}
	_raccogli(RADICE, out)
	out.erase(MOTORE)   # la dichiarazione non conta come uso
	return out

func _init() -> void:
	var sorgenti := _sorgenti()
	_ogni_segnale_ha_un_emittente(sorgenti)
	_nessuna_faccia_al_posto_di_un_segnale(sorgenti)
	_ogni_segnale_ha_una_faccia()
	_nessun_vantaggio(sorgenti)
	if errori.is_empty():
		print(OK)
	else:
		printerr("PET PRESENCE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Vero se qualcuno emette questo segnale. Cerca il letterale, e in più il
## **modello interpolato**: i cinque `learning:*` nascono da
## `_pet_react("learning:%s" % nome)`, quindi la loro stringa intera non compare
## da nessuna parte. Alla prima stesura questo audit li aveva dichiarati morti
## tutti e cinque — un falso rosso è una bugia esattamente come un falso verde,
## e insegna a non fidarsi del cricchetto.
func _emesso(segnale: String, sorgenti: Dictionary) -> bool:
	var aghi := ['"%s"' % segnale]
	var due_punti := segnale.find(":")
	if due_punti > 0:
		aghi.append('"%s:%%s"' % segnale.substr(0, due_punti))
	for percorso in sorgenti.keys():
		var testo := str(sorgenti[percorso])
		for ago in aghi:
			if testo.contains(str(ago)):
				return true
	return false

func _ogni_segnale_ha_un_emittente(sorgenti: Dictionary) -> void:
	var muti: Array = []
	for segnale_data in PetExpressionEngine.GAME_SIGNALS:
		var segnale := str(segnale_data)
		if _emesso(segnale, sorgenti):
			continue
		if IN_ATTESA.has(segnale):
			continue
		muti.append(segnale)
	_controlla(muti.is_empty(),
		"segnali del Custode dichiarati e mai emessi (%d): %s" % [muti.size(), ", ".join(muti)])

	# La lista d'attesa può solo accorciarsi: una voce che nel frattempo è stata
	# collegata deve uscire, o smette di essere una lista d'attesa e diventa un
	# posto dove nascondere il lavoro non fatto.
	for segnale_data in IN_ATTESA.keys():
		var segnale := str(segnale_data)
		_controlla(PetExpressionEngine.GAME_SIGNALS.has(segnale),
			"«%s» è in attesa ma non è un segnale dichiarato" % segnale)
		_controlla(str(IN_ATTESA[segnale]).strip_edges() != "",
			"«%s» è in attesa senza dire perché" % segnale)
		_controlla(not _emesso(segnale, sorgenti),
			"«%s» è collegato ma resta nella lista d'attesa: va tolto di lì" % segnale)

## **L'errore senza sintomi.** Passare una faccia dove serve un segnale non
## solleva niente: `face_for` non trova la chiave, ripiega sul volto a riposo, e
## la reazione sembra esserci. Due chiamate lo facevano.
func _nessuna_faccia_al_posto_di_un_segnale(sorgenti: Dictionary) -> void:
	for percorso in sorgenti.keys():
		var testo := str(sorgenti[percorso])
		for faccia_data in PetExpressionEngine.CATALOG.keys():
			var faccia := str(faccia_data)
			if PetExpressionEngine.GAME_SIGNALS.has(faccia):
				continue
			for chiamata in ['_pet_react("%s")' % faccia, 'react_to("%s")' % faccia]:
				_controlla(not testo.contains(chiamata),
					"%s passa la faccia «%s» dove serve un segnale: la reazione non avviene" % [
						str(percorso).get_file(), faccia])

func _ogni_segnale_ha_una_faccia() -> void:
	for segnale_data in PetExpressionEngine.GAME_SIGNALS:
		var segnale := str(segnale_data)
		_controlla(PetExpressionEngine.SIGNAL_FACES.has(segnale),
			"il segnale «%s» non ha una faccia dichiarata" % segnale)
		var faccia := PetExpressionEngine.face_for(segnale)
		_controlla(PetExpressionEngine.is_known(faccia),
			"il segnale «%s» punta alla faccia sconosciuta «%s»" % [segnale, faccia])
	for segnale_data in PetExpressionEngine.FAILURE_SIGNALS:
		var segnale := str(segnale_data)
		_controlla(not PetExpressionEngine.NEGATIVE_FACES.has(
			PetExpressionEngine.face_for(segnale)),
			"l'esito negativo «%s» fa fare al Custode una faccia negativa" % segnale)

## **Il Custode avanza in carattere, mai in potere** (decisione 12), e questo vale
## anche a monte: non deve reagire a quanto il bambino possiede.
func _nessun_vantaggio(sorgenti: Dictionary) -> void:
	for percorso in sorgenti.keys():
		var testo := str(sorgenti[percorso])
		var righe := testo.split("\n")
		for riga_data in righe:
			var riga := str(riga_data)
			if not riga.contains("_pet_react(") and not riga.contains("react_to("):
				continue
			if riga.strip_edges().begins_with("#"):
				continue
			for parola_data in VIETATE:
				var parola := str(parola_data)
				_controlla(not riga.to_lower().contains(parola),
					"%s fa reagire il Custode a «%s»: sarebbe un vantaggio, non un carattere — %s" % [
						str(percorso).get_file(), parola, riga.strip_edges()])
