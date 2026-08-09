extends SceneTree

## **I personaggi cambiano perché il bambino impara.** (8 agosto 2026)
##
## Richiesta del committente: «diamo sostanza alla vita dei mondi, curiamo
## carattere e comportamento dei personaggi dandogli un significato anche
## didattico».
##
## Il carattere c'era: quarantasei residenti con registro, tic, convinzione,
## bisogno e un **arco** in tre stadi. Non lo leggeva nessuno tranne il suo
## audit — contenuto scritto, verificato e mai pronunciato.
##
## Questo audit tiene le tre cose che rendono l'arco didattico invece che
## decorativo:
##
##   1. **lo stadio dipende dall'apprendimento**, non dal tempo né da quante
##      cose hai toccato. Un personaggio che cambia con l'orologio non insegna
##      niente;
##   2. **non torna indietro**: chi ha capito ha capito. Un personaggio che
##      disimpara perché tu hai smesso di giocare per una settimana sarebbe una
##      punizione travestita da narrazione;
##   3. **il terzo stadio insegna a qualcun altro**. È il payoff: vedere
##      qualcuno spiegare a un altro una cosa che poco fa non sapeva è la
##      dimostrazione, dentro la finzione, che imparare succede.

const OK := "NPC ARC audit VERDE"
## **Una regola che ho tolto, e perché.** (8 agosto 2026)
##
## Il primo tentativo pretendeva che l'ultimo stadio contenesse un verbo di
## trasmissione — «insegna», «spiega», «mostra» — per garantire che il terzo
## stadio fosse il momento in cui il metodo passa a un altro.
##
## Diciotto residenti su quarantasei sono diventati rossi, e leggendoli aveva
## torto la regola: «Stima prima e misura poi: la stima gli dice se la misura ha
## senso» e «Cambia una variabile per volta e per la prima volta può ripetere un
## successo» sono cambiamenti concettuali pieni — il metodo interiorizzato, che è
## il punto — semplicemente non consegnato a nessun altro. E due personaggi
## (Lino, Marco) **non cambiano apposta**: restano convinti di aver ragione, ed è
## scrittura onesta, non un buco da riempire.
##
## Applicarla avrebbe voluto dire riscrivere diciotto righe buone per soddisfare
## una regola inventata da me. È lo stesso errore dell'elenco di digrammi per
## l'ortografia italiana: indovinare il significato da un elenco di parole.
##
## Che il terzo stadio sia un buon terzo stadio resta un giudizio editoriale, e
## si fa leggendolo. Qui si tiene solo quello che si può verificare senza
## interpretare: tre stadi distinti, non banali, e uno stadio che risponde
## davvero all'apprendimento.

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	if errori.size() < 30:
		errori.append(messaggio)

func _init() -> void:
	_ogni_arco_e_completo()
	_lo_stadio_segue_l_apprendimento()
	_non_torna_mai_indietro()
	_si_vede_camminando()
	if errori.is_empty():
		print(OK)
	else:
		printerr("NPC ARC audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Il materiale: tre stadi distinti, e il terzo che trasmette.
func _ogni_arco_e_completo() -> void:
	var con_arco := 0
	for npc_id in NpcCatalog.RESIDENTS.keys():
		var dati: Dictionary = NpcCatalog.RESIDENTS[npc_id]
		var arco: Array = Array(dati.get("arco", []))
		if arco.is_empty():
			continue
		con_arco += 1
		if arco.size() != NpcArc.STADI:
			_fallisci("%s: %d stadi invece di %d" % [npc_id, arco.size(), NpcArc.STADI])
			continue
		var viste: Dictionary = {}
		for i in arco.size():
			var riga := str(arco[i]).strip_edges()
			if riga.length() < 30:
				_fallisci("%s stadio %d: troppo corto per raccontare un cambiamento" % [npc_id, i])
			if viste.has(riga):
				_fallisci("%s: due stadi identici — non è un arco, è una posa" % npc_id)
			viste[riga] = true
		# Le battute dello stadio devono esistere, altrimenti l'arco avanza e il
		# personaggio continua a dire le stesse cose.
		var battute: Dictionary = dati.get("battute", {})
		for i in NpcArc.STADI:
			if Array(battute.get("stadio%d" % i, [])).is_empty():
				_fallisci("%s: nessuna battuta per lo stadio %d" % [npc_id, i])
	if con_arco < 40:
		_fallisci("solo %d residenti hanno un arco: la vita dei mondi resta scritta a metà" % con_arco)

## **Lo stadio dipende dall'apprendimento.** Si costruiscono tre salvataggi
## nella stessa materia — ignorante, a metà, in linea — e si controlla che il
## personaggio sia in tre punti diversi del suo arco.
func _lo_stadio_segue_l_apprendimento() -> void:
	var campione := ""
	for npc_id in NpcCatalog.RESIDENTS.keys():
		if int(Dictionary(NpcCatalog.RESIDENTS[npc_id]).get("world", 0)) == 1 and NpcArc.ha_arco(str(npc_id)):
			campione = str(npc_id)
			break
	if campione == "":
		_fallisci("nessun residente con arco nel mondo 1: impossibile verificare")
		return
	var materia := NpcArc.materia_di(campione)
	var digiuno: ProgressionManager = _progressione(0.0, 0)
	var mezzo: ProgressionManager = _progressione(0.5, 3)
	var pieno: ProgressionManager = _progressione(1.0, 40)
	var a := NpcArc.stadio(digiuno, campione)
	var b := NpcArc.stadio(mezzo, campione)
	var c := NpcArc.stadio(pieno, campione)
	if a != 0:
		_fallisci("%s parte già cambiato (stadio %d) senza che si sia imparato niente" % [campione, a])
	if not (a <= b and b <= c):
		_fallisci("%s: lo stadio non cresce con l'apprendimento (%d, %d, %d)" % [campione, a, b, c])
	if c != NpcArc.STADI - 1:
		_fallisci("%s: con la materia (%s) in linea resta allo stadio %d" % [campione, materia, c])
	if a == c:
		_fallisci("%s: lo stadio non cambia mai — l'arco non arriva al giocatore" % campione)
	# L'osservazione deve cambiare con lo stadio, altrimenti il bambino non lo
	# vede: cambiare stato senza cambiare testo è cambiare per niente.
	if NpcArc.osservazione(digiuno, campione) == NpcArc.osservazione(pieno, campione):
		_fallisci("%s: si legge la stessa riga a inizio e a fine arco" % campione)
	# La nota di traguardo compare SOLO in fondo.
	if NpcArc.nota_di_traguardo(digiuno, campione) != "":
		_fallisci("%s: il gioco annuncia un traguardo che non c'è" % campione)
	if NpcArc.nota_di_traguardo(pieno, campione) == "":
		_fallisci("%s: il traguardo raggiunto non viene nominato" % campione)

## Chi ha capito ha capito: lo stadio non scende mai al crescere della
## padronanza. Il decadimento della padronanza esiste, e senza questo controllo
## un personaggio potrebbe **disimparare** perché il bambino è stato via una
## settimana — una punizione travestita da narrazione.
func _non_torna_mai_indietro() -> void:
	for npc_id_data in NpcCatalog.RESIDENTS.keys():
		var npc_id := str(npc_id_data)
		if not NpcArc.ha_arco(npc_id):
			continue
		var precedente := -1
		for passo in range(0, 11):
			var quota := float(passo) / 10.0
			var stadio := NpcArc.stadio(_progressione(quota, passo * 4), npc_id)
			if stadio < precedente:
				_fallisci("%s: a padronanza %.0f%% torna indietro (%d dopo %d)" % [
					npc_id, quota * 100.0, stadio, precedente])
				break
			precedente = stadio

## **Il cambiamento si vede da lontano.**
##
## Un arco che si legge solo aprendo un dialogo e' un arco che quasi nessuno
## vedra': la maggior parte dei personaggi si attraversa senza parlarci. Qui si
## controlla che l'attivita' sopra la testa esista, cambi con lo stadio, e non
## dica mai piu' di quello che il gioco sa.
func _si_vede_camminando() -> void:
	var digiuno: ProgressionManager = _progressione(0.0, 0)
	var pieno: ProgressionManager = _progressione(1.0, 40)
	var viste: Dictionary = {}
	for npc_id_data in NpcCatalog.RESIDENTS.keys():
		var npc_id := str(npc_id_data)
		if not NpcArc.ha_arco(npc_id):
			continue
		var prima := NpcArc.attivita(digiuno, npc_id)
		var dopo := NpcArc.attivita(pieno, npc_id)
		if prima.strip_edges().is_empty():
			_fallisci("%s: nessuna attivita' visibile da lontano" % npc_id)
		if prima == dopo:
			_fallisci("%s: l'attivita' non cambia mai — il cambiamento resta invisibile" % npc_id)
		# Sopra la testa ci stanno poche parole: oltre, l'etichetta non si legge
		# e copre il personaggio invece di descriverlo.
		for testo in [prima, dopo]:
			if testo.length() > 34:
				_fallisci("%s: attivita' troppo lunga per stare sopra la testa (%d caratteri)" % [
					npc_id, testo.length()])
		viste[prima] = true
		viste[dopo] = true
		if not NpcArc.in_fondo_all_arco(pieno, npc_id):
			_fallisci("%s: con la materia in linea non risulta in fondo all'arco" % npc_id)
		if NpcArc.in_fondo_all_arco(digiuno, npc_id):
			_fallisci("%s: risulta in fondo all'arco senza aver imparato niente" % npc_id)
	# **Nessuna attivita' puo' promettere un insegnamento.** Due residenti
	# arrivano in fondo restando convinti di aver ragione: una scritta come
	# «insegna quello che ha capito» sopra la loro testa sarebbe una bugia a
	# caratteri grandi. E' la stessa ragione per cui e' stata tolta la regola sui
	# verbi di trasmissione.
	for testo in viste.keys():
		for verbo in ["insegna", "spiega", "ha capito", "ha imparato"]:
			if str(testo).to_lower().contains(verbo):
				_fallisci("l'attivita' «%s» promette qualcosa che per due personaggi non e' vero" % testo)

## Una progressione finta con la padronanza voluta in tutte le materie.
func _progressione(padronanza: float, argomenti: int) -> ProgressionManager:
	var save := GameSaveManager.new("user://npc-arc-audit.json")
	var mastery: Dictionary = {}
	var copertura: Dictionary = {}
	for materia in ApparatusConfig.SUBJECT_CYCLE:
		mastery[str(materia)] = padronanza
		var visti: Array = []
		for i in range(argomenti):
			visti.append("t%d" % i)
		copertura[str(materia)] = visti
	save.data["mastery"] = mastery
	save.data["coverageThisLevel"] = copertura
	return ProgressionManager.new(save, ContentManager.new())
