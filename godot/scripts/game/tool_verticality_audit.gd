extends SceneTree

## **L'arcipelago: che i mondi dietro restino aperti.** (19 agosto 2026)
##
## Il difetto misurato prima di intervenire: gli strumenti erano **due**,
## consegnati entrambi entro il mondo 2. **Dal mondo 3 in poi, in tutta la
## campagna, non esisteva una sola porta chiusa.** Un gioco con due chiavi date
## subito non ha verticalita': ha un tutorial sugli attrezzi e poi ventidue mondi
## piatti. E i mondi erano gia' rivisitabili dalla nave — mancava la ragione.
##
## Questo audit tiene le cinque proprieta' che fanno l'arcipelago:
##
##   1. **il calendario esiste e sale**: cinque strumenti, mondi crescenti, e
##      nessuno consegnato prima del proprio;
##   2. **ogni mondo della prima meta' ha una porta che non si puo' aprire**, e
##      non e' mai chiuso tutto: e' il «piu' uno» di `varchi_del_mondo`, ed e'
##      l'unica riga di questo lotto che, se cade, riporta il gioco esattamente
##      dov'era;
##   3. **gli arretrati non si perdono**: chi salta la riparazione di un mondo
##      riceve la chiave al mondo dopo, in ordine;
##   4. **il registro ricorda le porte viste**, e le dimentica quando si aprono.
##      Senza, un attrezzo nuovo sarebbe una riga di dialogo: nessuno si ricorda
##      dove ha visto una lastra sigillata dodici ore di gioco prima;
##   5. **niente di necessario sta dietro una chiave.** Su tutti i mondi
##      campionati, nessun evento che conta per il gate porta `requiredTool`.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

# --- 1. Il calendario ---------------------------------------------------------

func _prova_calendario() -> void:
	var ids := FieldTools.ids()
	_controlla(ids.size() >= 5,
		"gli strumenti sono %d: con meno di cinque non c'e' un arco, c'e' un tutorial" % ids.size())
	var precedente := 0
	for id in ids:
		var mondo := FieldTools.mondo_di(str(id))
		_controlla(mondo >= 1, "«%s» non dichiara il mondo in cui viene consegnato" % id)
		_controlla(FieldTools.del_mondo(mondo) == str(id),
			"il mondo %d non consegna esattamente «%s»" % [mondo, id])
		_controlla(mondo >= precedente,
			"«%s» arriva al mondo %d, prima di quello che lo precede nell'ordine" % [id, mondo])
		precedente = mondo
		# Le parole con cui il gioco ne parla: se manca una di queste, una porta
		# chiusa diventa muta e il bambino non sa che cosa gli serve.
		_controlla(FieldTools.ostacolo(str(id)) != "",
			"«%s» non ha un nome per il proprio ostacolo" % id)
		_controlla(FieldTools.nome(str(id)) != "", "«%s» non ha un nome" % id)
		_controlla(FieldTools.riga_di_consegna(str(id), "Tobia") != "",
			"«%s» non ha una riga di consegna" % id)
		_controlla(FieldTools.riga_di_consegna(str(id), "") != "",
			"«%s» non ha una riga di consegna senza nome: la scena cadrebbe muta" % id)
	# L'ultimo non puo' arrivare troppo tardi: una chiave consegnata al mondo 22
	# non riaprirebbe niente, perche' non resta campagna per tornare indietro.
	var ultimo := FieldTools.mondo_di(str(ids[ids.size() - 1]))
	_controlla(ultimo <= 16,
		"l'ultimo strumento arriva al mondo %d: troppo tardi per riaprire qualcosa" % ultimo)
	# E il primo deve esserci subito: chi comincia non puo' trovare solo porte.
	_controlla(FieldTools.mondo_di(str(ids[0])) == 1,
		"il primo strumento non arriva al mondo 1")

# --- 2. Ogni mondo ha una porta chiusa, e non e' chiuso tutto -----------------

func _prova_porte_chiuse() -> void:
	var ultimo_mondo := FieldTools.mondo_di(str(FieldTools.ids()[FieldTools.ids().size() - 1]))
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var varchi := FieldTools.varchi_del_mondo(livello)
		_controlla(not varchi.is_empty(), "il mondo %d non ha nessuna chiave: le porte sarebbero mute" % livello)
		var apribili := 0
		var chiuse := 0
		for id in varchi:
			if FieldTools.mondo_di(str(id)) <= livello:
				apribili += 1
			else:
				chiuse += 1
		# Sempre almeno una che si puo' aprire adesso: un mondo interamente chiuso
		# sarebbe una promessa rimandata invece di un posto da esplorare.
		_controlla(apribili >= 1,
			"al mondo %d nessuna porta e' apribile con quello che si ha: il mondo e' tutto rimandato" % livello)
		# E, finche' esistono chiavi da consegnare, almeno una che non si puo'.
		# E' la riga che, se cade, riporta il gioco a com'era prima del lotto.
		if livello < ultimo_mondo:
			_controlla(chiuse >= 1,
				"al mondo %d si apre tutto: non resta niente da tornare a prendere" % livello)
		# Mai troppe rimandate insieme: due o tre chiavi di anticipo e mezzo mondo
		# diventerebbe un elenco di appuntamenti invece che un posto.
		_controlla(chiuse <= 1,
			"al mondo %d ci sono %d chiavi di anticipo: l'esplorazione diventa una lista di rimandi"
			% [livello, chiuse])

# --- 3. Gli arretrati -----------------------------------------------------------

## Un finto portafogli: sa soltanto rispondere «ce l'ho» o «non ce l'ho», che e'
## l'unica cosa che `FieldTools.dovuto` chiede al gestore delle ricompense.
class BorsaFinta:
	extends RefCounted
	var posseduti: Array = []
	func owned(id: String) -> bool:
		return posseduti.has(id)

func _prova_arretrati() -> void:
	var borsa := BorsaFinta.new()
	# Chi non ha niente e sta al mondo 1 riceve il primo, e non il secondo.
	_controlla(FieldTools.dovuto(borsa, 1) == FieldTools.TORCIA,
		"al mondo 1 non e' dovuta la torcia")
	borsa.posseduti.append(FieldTools.TORCIA)
	_controlla(FieldTools.dovuto(borsa, 1) == "",
		"al mondo 1 e' dovuto un secondo strumento: il calendario non tiene")
	# **L'arretrato.** Chi arriva al mondo 7 senza aver mai finito una riparazione
	# riceve prima la falce, poi la leva, poi la lente: in ordine, uno per volta,
	# e non se ne perde nessuno. E' il caso che rende impossibile restare senza
	# chiavi per non aver esplorato abbastanza.
	var atteso := [FieldTools.FALCE, FieldTools.LEVA, FieldTools.LENTE]
	for id_atteso in atteso:
		var dovuto := FieldTools.dovuto(borsa, 7)
		_controlla(dovuto == str(id_atteso),
			"al mondo 7 l'arretrato dovuto era «%s», invece e' «%s»" % [id_atteso, dovuto])
		borsa.posseduti.append(dovuto)
	_controlla(FieldTools.dovuto(borsa, 7) == "",
		"al mondo 7 e' dovuto anche uno strumento di un mondo successivo")
	# E un attrezzo non arriva mai prima del proprio mondo.
	var vuota := BorsaFinta.new()
	for id in FieldTools.ids():
		var mondo := FieldTools.mondo_di(str(id))
		if mondo <= 1:
			continue
		_controlla(FieldTools.dovuto(vuota, mondo - 1) != str(id),
			"«%s» viene consegnato al mondo %d, prima del suo" % [id, mondo - 1])

# --- 4. Il registro delle porte viste -----------------------------------------

func _prova_registro() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	_controlla(save.tool_gate_worlds(FieldTools.LEVA).is_empty(),
		"un salvataggio nuovo ricorda gia' delle porte")
	_controlla(save.record_tool_gate("3", FieldTools.LEVA, "forziere-a"),
		"la prima porta vista non viene registrata")
	_controlla(not save.record_tool_gate("3", FieldTools.LEVA, "forziere-a"),
		"la stessa porta viene registrata due volte: il salvataggio si riscriverebbe a ogni passaggio")
	save.record_tool_gate("3", FieldTools.LEVA, "forziere-b")
	save.record_tool_gate("7", FieldTools.LEVA, "palestra-c")
	save.record_tool_gate("7", FieldTools.LENTE, "traccia-d")
	var mondi: Array = save.tool_gate_worlds(FieldTools.LEVA)
	_controlla(mondi.size() == 2, "il registro non elenca i due mondi con porte di leva")
	if mondi.size() == 2:
		_controlla(int(Dictionary(mondi[0])["world"]) == 3 and int(Dictionary(mondi[0])["porte"]) == 2,
			"il registro conta male le porte del mondo 3")
		_controlla(int(Dictionary(mondi[1])["world"]) == 7,
			"il registro non ordina i mondi")
	_controlla(save.tool_gates_openable("7", [FieldTools.LEVA, FieldTools.LENTE]) == 2,
		"il conto di cio' che si puo' aprire al mondo 7 e' sbagliato")
	_controlla(save.tool_gates_openable("7", [FieldTools.TORCIA]) == 0,
		"il conto include porte di chiavi che non si hanno")
	# Aperta una porta, sparisce: continuare a segnalarla manderebbe il giocatore
	# a cercare una cosa che ha gia' preso.
	save.clear_tool_gate("3", FieldTools.LEVA, "forziere-a")
	_controlla(int(Dictionary(save.tool_gate_worlds(FieldTools.LEVA)[0])["porte"]) == 1,
		"una porta aperta resta nel registro")
	save.clear_tool_gate("3", FieldTools.LEVA, "forziere-b")
	_controlla(save.tool_gate_worlds(FieldTools.LEVA).size() == 1,
		"un mondo senza piu' porte resta nell'elenco")

# --- 5. Niente di necessario dietro una chiave, e il registro nel mondo vero ---

func _request(livello: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("tool-verticality-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	return request

func _prova_nel_mondo(livello: int) -> void:
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _request(livello))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	current_scene = mondo
	await process_frame
	await process_frame
	var manager: RewardManager = mondo.get("gameplay").reward_manager
	var strumento_corrente := FieldTools.del_mondo(livello)
	for id_data in FieldTools.ids():
		var tool_id := str(id_data)
		var dovrebbe_esserci := FieldTools.mondo_di(tool_id) < livello
		_controlla(manager.owned(tool_id) == dovrebbe_esserci,
			"mondo %d: possesso iniziale incoerente per %s (atteso %s)" % [
				livello, tool_id, "sì" if dovrebbe_esserci else "no"])
	var dovuto_qui := FieldTools.dovuto(manager, livello)
	_controlla(dovuto_qui == strumento_corrente,
		"mondo %d: lo strumento dovuto è %s invece di %s" % [
			livello, dovuto_qui, strumento_corrente])

	var chiusi := 0
	var chiavi_viste: Dictionary = {}
	for evento_data in Array(mondo.get("mission_events")):
		var evento: Dictionary = evento_data
		var id := str(evento.get("id", ""))
		var area := mondo.find_child("MissionEvent_%s" % id.replace("-", "_"), true, false) as Area2D
		if area == null:
			continue
		var richiesto := str(Dictionary(area.get_meta("payload", {})).get("requiredTool", ""))
		if richiesto == "":
			continue
		# **La riga che rende lecito tutto il resto.**
		_controlla(not bool(evento.get("countsForGate", false)),
			"al mondo %d una prova che apre il livello e' chiusa da «%s»" % [livello, richiesto])
		# **E nessuna palestra dietro una chiave futura.** Le undici palestre sono
		# una per materia: chiuderne una fino a tre mondi dopo toglie a un bambino
		# l'unico posto in cui allena quella materia qui. La progressione non si
		# ferma — le palestre non contano per il gate — ma l'apprendimento si', ed
		# e' peggio. Le porte che guardano avanti stanno sui forzieri.
		if str(evento.get("kind", "")) == "practice":
			_controlla(FieldTools.mondo_di(richiesto) <= livello,
				"al mondo %d la palestra di %s e' chiusa da «%s», che arriva al mondo %d"
				% [livello, str(evento.get("subject", "?")), richiesto, FieldTools.mondo_di(richiesto)])
		chiavi_viste[richiesto] = true
		if not bool(mondo.call("_equipment_requirement_met", area)):
			chiusi += 1
			# E il messaggio deve dire DOVE si prende: una porta chiusa senza
			# indicazione e' un vicolo cieco.
			var riga := str(mondo.call("_equipment_requirement_message", area))
			_controlla(riga.contains(str(FieldTools.mondo_di(richiesto))) or riga.contains("qui"),
				"al mondo %d la porta di «%s» non dice dove si prende la chiave" % [livello, richiesto])

	# **Il registro, sul mondo vero.** Il gioco annota le porte avvicinandosi
	# (`_annota_varco` da `_refresh_prompt`): qui si passa davanti a tutte con la
	# stessa funzione, e si pretende che il salvataggio se le sia segnate. E'
	# questa la meta' che rende utili cinque chiavi invece di due — senza il
	# registro, un attrezzo nuovo resta una riga di dialogo.
	#
	# Nota su cosa NON si prova qui: la porta che guarda avanti sta sui forzieri,
	# e i forzieri arrivano dallo streaming dei pezzi di mappa, che questo audit
	# tiene a zero per non costruire mezzo mondo. La regola dei forzieri e'
	# provata dove vive, su `varchi_del_mondo`, per tutti e ventiquattro i mondi
	# (`_prova_porte_chiuse`). Dirlo qui invece di fingere di misurarlo.
	if chiusi > 0:
		var save: GameSaveManager = mondo.get("game_save")
		for evento_data in Array(mondo.get("mission_events")):
			var id := str(Dictionary(evento_data).get("id", ""))
			var area := mondo.find_child("MissionEvent_%s" % id.replace("-", "_"), true, false) as Area2D
			if area != null:
				mondo.call("_annota_varco", area)
		var totale := 0
		for chiave in chiavi_viste.keys():
			for voce in save.tool_gate_worlds(str(chiave)):
				totale += int(Dictionary(voce)["porte"])
		_controlla(totale >= chiusi,
			"al mondo %d il registro ha annotato %d porte su %d viste chiuse" % [livello, totale, chiusi])

	# Nei cinque mondi che portano una chiave la minimissione deve essere visibile
	# subito e la scena vera deve consegnare esattamente quella chiave, senza
	# aspettare un rientro o consumare al suo posto un arretrato.
	var incarico: Area2D = null
	var incarico_id := ""
	for evento_data in Array(mondo.get("mission_events")):
		var evento: Dictionary = evento_data
		if str(evento.get("kind", "")) != "minimission":
			continue
		incarico_id = str(evento.get("id", ""))
		incarico = mondo.find_child(
			"MissionEvent_%s" % incarico_id.replace("-", "_"), true, false) as Area2D
		break
	_controlla(incarico != null, "mondo %d: minimissione assente dalla scena" % livello)
	if strumento_corrente != "" and incarico != null:
		_controlla(incarico.visible and incarico.monitoring,
			"mondo %d: la minimissione che consegna %s è nascosta" % [
				livello, strumento_corrente])
		var payload: Dictionary = incarico.get_meta("payload", {})
		_controlla(str(payload.get("rewardTool", "")) == strumento_corrente,
			"mondo %d: l'incarico non dichiara la ricompensa %s" % [
				livello, strumento_corrente])
		var reward_label := incarico.find_child("ToolRewardLabel", true, false) as Label
		_controlla(reward_label != null and reward_label.text.contains(
			FieldTools.nome(strumento_corrente).to_upper()),
			"mondo %d: la ricompensa %s non e' leggibile sul luogo" % [
				livello, strumento_corrente])
		var route: Dictionary = mondo.get("mission_ownership_flow").navigation()
		_controlla(str(route.get("id", "")) == incarico_id \
				or str(route.get("eventId", "")) == incarico_id,
			"mondo %d: la bussola non conduce all'incarico di %s" % [
				livello, strumento_corrente])
		var navigation_target: Dictionary = mondo.call("_ownership_navigation_target")
		_controlla(not navigation_target.is_empty() \
				and str(navigation_target.get("prefix", "")).contains(
					FieldTools.nome(strumento_corrente).to_upper()),
			"mondo %d: la guida non nomina %s" % [livello, strumento_corrente])
		mondo.call("_consegna_strumento_se_dovuto", incarico_id)
		_controlla(manager.owned(strumento_corrente),
			"mondo %d: la riparazione non consegna %s nella stessa sessione" % [
				livello, strumento_corrente])

	root.remove_child(mondo)
	mondo.queue_free()
	await process_frame

func _prova_recupero_salvataggio_vecchio() -> void:
	var initial := GameSaveManager._default_data()
	initial["level"] = 2
	initial["worlds"] = {"unlocked": [1, 2], "current": 2}
	initial["minimissions"] = [1, 2]
	var request := NativeWorldState.default_request("tool-recovery-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 2
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", request)
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	await process_frame
	await process_frame
	var manager = mondo.get("gameplay").reward_manager
	_controlla(manager.owned(FieldTools.TORCIA),
		"salvataggio con riparazione del mondo 1 non recupera la torcia")
	_controlla(manager.owned(FieldTools.FALCE),
		"salvataggio con riparazione del mondo 2 non recupera la falce")
	root.remove_child(mondo)
	mondo.queue_free()
	await process_frame

func _run() -> void:
	_prova_calendario()
	_prova_porte_chiuse()
	_prova_arretrati()
	_prova_registro()
	root.size = Vector2i(900, 600)
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		await _prova_nel_mondo(int(livello))
	await _prova_recupero_salvataggio_vecchio()
	current_scene = null
	if _rossi.is_empty():
		print("TOOL VERTICALITY audit OK — 24 mondi, cinque consegne live in ordine, arretrati recuperati e porte coerenti")
		quit(0)
		return
	for riga in _rossi:
		printerr("TOOL VERTICALITY audit FALLITO — %s" % riga)
	quit(1)
