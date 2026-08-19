extends SceneTree

## **Il ritmo di un mondo: inizio, mezzo e fine.** (19 agosto 2026)
##
## Tre lotti che rispondono alla stessa misura: **un mondo non aveva una curva.**
## Diciotto punti d'interesse equivalenti, in qualunque ordine, ricetta identica
## ventiquattro volte, e poi si tornava al portale camminando come si era
## arrivati. L'esame sta dentro la nave, quindi il mondo esterno finiva senza
## accorgersene.
##
##   MEZZO   il **momento d'autore** ([[WorldSetPiece]]): sei in tutta la
##           campagna, agganciati ai colpi di scena, a mondo scoperto a meta';
##   FINE    il **richiamo**: quando l'apparato diventa riparabile il mondo
##           cambia stato e non torna indietro;
##   SEMPRE  la **tana** ([[PetErrand]]): la prima interazione del gioco che non
##           apre un pannello — si preme e si guarda il Custode andare.
##
## Le proprieta' che questo audit tiene, e le prime due valgono piu' delle altre:
##
##   1. **niente di tutto questo toglie qualcosa.** Ne' energia, ne' padronanza,
##      ne' progressione: il branco insegue ma morde con le regole di sempre, il
##      buio nasconde ma non chiude strade, la tana non puo' fallire;
##   2. **niente si ripete.** Un momento d'autore visto e' visto, una tana
##      svuotata resta svuotata: una cutscene che ricompare si salta, e una gag
##      che si farma smette di essere una gag;
##   3. i sei momenti stanno sui mondi dei colpi di scena, e ognuno ha le sue
##      parole;
##   4. il richiamo scatta una volta sola e allunga le sacche senza fermarle;
##   5. la tana rimanda il Custode e lo fa tornare.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const MONDI_DEI_COLPI := [5, 8, 12, 16, 19, 23]

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

# --- 3. I sei momenti, senza costruire niente ---------------------------------

func _prova_catalogo() -> void:
	_controlla(WorldSetPiece.MOMENTI.size() == 6,
		"i momenti d'autore sono %d invece di sei" % WorldSetPiece.MOMENTI.size())
	# Stanno sui mondi dei colpi di scena: e' l'aggancio che li rende economici,
	# perche' la storia li paga gia'.
	for mondo in MONDI_DEI_COLPI:
		_controlla(WorldSetPiece.ha(int(mondo)),
			"il mondo %d ha un colpo di scena e nessun momento d'autore" % mondo)
	var forme: Dictionary = {}
	var id_visti: Dictionary = {}
	for voce_data in WorldSetPiece.MOMENTI:
		var voce: Dictionary = voce_data
		var id := str(voce["id"])
		_controlla(not id_visti.has(id), "due momenti con lo stesso identificativo: «%s»" % id)
		id_visti[id] = true
		# **Ogni momento ha una forma diversa.** Sei volte la stessa cosa con sei
		# testi diversi sarebbe un elenco, non un ritmo.
		var forma := str(voce["forma"])
		_controlla(not forme.has(forma), "la forma «%s» si ripete: sei momenti uguali non sono un ritmo" % forma)
		forme[forma] = true
		_controlla(str(voce.get("apertura", "")).strip_edges() != "",
			"il momento «%s» non dice niente quando comincia" % id)
		# **Durano poco.** Sono un respiro dentro una sessione, non un capitolo.
		var durata := float(voce.get("durata", 0.0))
		_controlla(durata > 0.0 and durata <= 40.0,
			"il momento «%s» dura %.0f s: fuori dal respiro di una sessione" % [id, durata])
	# E la soglia di innesco sta a meta': sulla soglia del mondo sarebbe una
	# presentazione, a fine mondo arriverebbe mentre si sta gia' uscendo.
	_controlla(WorldSetPiece.LUCE_DI_INNESCO > 0.2 and WorldSetPiece.LUCE_DI_INNESCO < 0.85,
		"i momenti scattano a luce %.2f: troppo presto o troppo tardi" % WorldSetPiece.LUCE_DI_INNESCO)

# --- 1. Niente toglie niente, misurato sui numeri ------------------------------

func _prova_nessun_costo() -> void:
	# La caccia e il richiamo allungano la SOGLIA, non il morso: il costo di un
	# contatto e' `(grado sacca − grado Eli) × COSTO_PER_GRADO` e non compare in
	# nessuna delle due costanti. Se un giorno qualcuno ci mettesse un
	# moltiplicatore di danno, questa prova e' il posto in cui se ne accorge.
	_controlla(WorldEnemy.CACCIA_ALLUNGO > WorldEnemy.RICHIAMO_ALLUNGO,
		"la caccia non insegue piu' del richiamo: il momento del mondo 5 non si sente")
	_controlla(WorldEnemy.RICHIAMO_ALLUNGO > 1.0,
		"il richiamo non cambia niente nelle sacche")
	# La tana non puo' costare: paga in frammenti, e pochi.
	_controlla(PetErrand.FRAMMENTI > 0 and PetErrand.FRAMMENTI <= 40,
		"la tana paga %d frammenti: o non paga, o paga come un forziere e insegna a cercare tane"
		% PetErrand.FRAMMENTI)
	# E l'esito piu' probabile e' la figura barbina: il momento e' il Custode che
	# esce, non quello che ha in bocca.
	var peso_niente := 0
	var peso_totale := 0
	for voce_data in PetErrand.ESITI:
		var voce: Dictionary = voce_data
		peso_totale += int(voce["peso"])
		if str(voce["id"]) == "niente":
			peso_niente = int(voce["peso"])
	_controlla(peso_niente * 2 >= peso_totale,
		"la tana rende piu' spesso di quanto non renda: diventa una miniera invece di una gag")

# --- 2. Niente si ripete -------------------------------------------------------

func _prova_niente_si_ripete() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var id := str(Dictionary(WorldSetPiece.MOMENTI[0])["id"])
	_controlla(not save.set_piece_seen(id), "un salvataggio nuovo ha gia' visto un momento")
	_controlla(save.claim_set_piece(id), "il primo momento non viene segnato")
	_controlla(not save.claim_set_piece(id),
		"lo stesso momento si prende due volte: una cutscene che ricompare si salta")
	_controlla(save.set_piece_seen(id), "il momento segnato non risulta visto")
	# La tana: svuotata resta svuotata. L'esito e' deciso dall'identificativo,
	# quindi rimandarci il Custode darebbe sempre la stessa cosa.
	_controlla(not save.tana_svuotata("3", "tana-3-0"), "una tana nuova risulta gia' svuotata")
	_controlla(save.mark_tana_svuotata("3", "tana-3-0"), "la tana svuotata non viene segnata")
	_controlla(not save.mark_tana_svuotata("3", "tana-3-0"), "la stessa tana si svuota due volte")
	_controlla(save.tana_svuotata("3", "tana-3-0"), "la tana segnata non risulta svuotata")
	# E l'esito e' stabile: la stessa tana da' sempre la stessa cosa.
	var primo := PetErrand.esito_di("tana-9-1")
	for _giro in range(20):
		_controlla(PetErrand.esito_di("tana-9-1") == primo,
			"l'esito di una tana cambia fra una lettura e l'altra: insegnerebbe a riprovare")

# --- 4 e 5. Il mondo vero ------------------------------------------------------

func _request(livello: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("ritmo-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	return request

func _prova_nel_mondo() -> void:
	root.size = Vector2i(900, 600)
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _request(5))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	current_scene = mondo
	await process_frame
	await process_frame

	var save: GameSaveManager = mondo.get("game_save")

	# --- Le tane ci sono, e senza Custode non si mandano ----------------------
	var tane: Array = []
	for nodo in get_nodes_in_group("world_interactable"):
		if str((nodo as Node).get_meta("kind", "")) == "tana":
			tane.append(nodo)
	_controlla(not tane.is_empty(), "il mondo 5 non ha nessuna tana")
	if not tane.is_empty():
		var tana := tane[0] as Area2D
		_controlla(str(mondo.call("_interaction_action_text", tana)) == "MANDA IL CUSTODE",
			"il pulsante della tana non dice che ci va il Custode")
		# Senza Custode concesso non parte niente, e la riga lo spiega.
		mondo.call("_manda_il_custode", tana)
		_controlla(str(mondo.get("_tana_in_corso")) == "",
			"la spedizione parte senza un Custode da mandare")

		# Con il Custode: parte, arriva, entra, torna, e la tana si chiude.
		PetState.grant(save, 5)
		save.save()
		mondo.call("_refresh_pet_face")
		mondo.call("_respawn_pet_companion")
		await process_frame
		var custode = mondo.get("pet_companion")
		_controlla(is_instance_valid(custode), "nessun Custode dopo la concessione")
		if is_instance_valid(custode):
			var frammenti_prima := int(save.fragments())
			var energia_prima := int(save.energy())
			var materia := str(mondo.call("_world_subject"))
			var padronanza_prima := float(save.mastery_of(materia))
			var id_tana := str(tana.get_meta("id", ""))
			mondo.call("_manda_il_custode", tana)
			await process_frame
			_controlla(str(mondo.get("_tana_in_corso")) == id_tana,
				"la spedizione non risulta in corso")
			# Il Custode si stacca: e' l'unico momento in cui non e' al fianco.
			_controlla(custode.get("_meta") != Vector2.INF,
				"il Custode non ha una meta sua: sta ancora seguendo Eli")
			# Si aspetta la scena intera.
			var atteso := 0.0
			while str(mondo.get("_tana_in_corso")) != "" and atteso < 20.0:
				await create_timer(0.25).timeout
				atteso += 0.25
			_controlla(str(mondo.get("_tana_in_corso")) == "",
				"la spedizione non si e' mai chiusa")
			_controlla(custode.get("_meta") == Vector2.INF and bool(custode.visible),
				"il Custode non e' tornato al fianco di Eli")
			_controlla(save.tana_svuotata("5", id_tana), "la tana giocata non risulta svuotata")
			# **La riga che vale piu' delle altre**: da una tana non esce mai
			# niente che serva a imparare.
			_controlla(int(save.energy()) == energia_prima, "la tana ha toccato l'energia")
			_controlla(is_equal_approx(save.mastery_of(materia), padronanza_prima),
				"la tana ha toccato la padronanza")
			_controlla(int(save.fragments()) >= frammenti_prima,
				"la tana ha TOLTO frammenti: non puo' fallire")

	# --- Il richiamo ----------------------------------------------------------
	_controlla(not bool(mondo.get("_richiamo_attivo")),
		"il richiamo e' gia' aperto appena entrati nel mondo")
	mondo.call("_apri_il_richiamo")
	_controlla(bool(mondo.get("_richiamo_attivo")), "il richiamo non si apre")
	_controlla(str(mondo.call("_turno_del_villaggio", 0.0)) == "richiamo",
		"durante il richiamo il villaggio continua il proprio turno di lavoro")
	for enemy in get_nodes_in_group("world_enemy"):
		_controlla(bool(enemy.get("richiamo")),
			"una sacca non si e' accorta del richiamo")
	# E non si riapre: e' un momento, non uno stato che lampeggia.
	var energia_prima_richiamo := int(save.energy())
	mondo.call("_apri_il_richiamo")
	_controlla(int(save.energy()) == energia_prima_richiamo,
		"riaprire il richiamo ha toccato l'energia")

	root.remove_child(mondo)
	mondo.queue_free()
	current_scene = null
	await process_frame

func _run() -> void:
	_prova_catalogo()
	_prova_nessun_costo()
	_prova_niente_si_ripete()
	await _prova_nel_mondo()
	if _rossi.is_empty():
		print("RITMO DEL MONDO audit OK — sei momenti sui colpi, il richiamo alla fine, la tana che non apre pannelli")
		quit(0)
		return
	for riga in _rossi:
		printerr("RITMO DEL MONDO audit FALLITO — %s" % riga)
	quit(1)
