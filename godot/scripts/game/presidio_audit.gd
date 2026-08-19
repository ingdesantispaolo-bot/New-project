extends SceneTree

## **Il presidio: l'unico posto in cui l'impulso e' una decisione.**
## (19 agosto 2026)
##
## Le cariche d'impulso si guadagnano studiando ([[PulseCharge]]) e il morso non
## blocca mai. Messe insieme, queste due regole giustissime producevano una cosa
## che nessuna delle due voleva: **non e' mai esistito un momento in cui valesse
## la pena spendere una carica**. Si passava sempre e comunque, pagando due
## energie o non pagandole. Una risorsa che non si sceglie mai quando spendere non
## e' una risorsa, e' un numero sullo schermo.
##
## L'anello di scorte attorno a un forziere sorvegliato e' il posto dove quella
## scelta esiste: attraversarlo costa piu' di un morso solo, e un impulso lo
## spegne per il tempo di passare. Passo adesso e pago, oppure spendo una carica,
## oppure torno quando sono piu' forte.
##
## Le cinque proprieta' che tengono in piedi il compromesso — e le prime due
## valgono piu' delle altre tre:
##
##   1. **un presidio sta solo davanti a un forziere**, cioe' davanti a frammenti,
##      cioe' a cosmetici. Mai davanti a una prova che apre il livello: sarebbe
##      un'abilita' messa davanti alla progressione, e in questo gioco non puo'
##      esistere;
##   2. **non blocca**. Si attraversa pagando, e a energia zero si attraversa
##      gratis. E' la regola di tutta la mappa;
##   3. **l'impulso lo spegne tutto insieme**, altrimenti la scelta non e'
##      pagabile e resta soltanto il pedaggio;
##   4. **costa meno di quanto un morso possa costare per contratto**: il tetto e'
##      lo stesso di `enemy_threat_audit`, `LAVORETTO_PAGA * 2`, e qui vale
##      sull'anello intero perche' attraversarlo e' una cosa che si sceglie;
##   5. **si scioglie con la guardiana**. Un anello che sopravvive al proprio
##      centro sarebbe una tassa su un forziere gia' guadagnato.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const OUTDOOR_WORLD := preload("res://scripts/outdoor_world.gd")

## Il mondo su cui si apre la scena. Tredici perche' e' oltre la meta' della
## campagna: le scorte hanno gia' un grado proprio e il forziere e' abbastanza
## lontano dallo spawn da poter essere sorvegliato.
const MONDO_DI_PROVA := 13

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

func _request(livello: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 400
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("presidio-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	return request

func _grado_sacca(livello: int) -> int:
	return clampi(1 + floori(float(livello - 1) / 3.0), 1, 8)

func _grado_scorta(livello: int) -> int:
	return maxi(1, _grado_sacca(livello) - WorldEnemy.SCARTO_SCORTA)

## --- La taratura, provata senza aprire nessun mondo ---------------------------

## Il tetto di spesa vale sull'ANELLO, non sulla singola sacca. Provato su tutti
## e ventiquattro i mondi perche' e' l'unico numero di questo lotto che, se
## sbagliato, trasforma una scelta in una punizione.
func _prova_costo_dell_anello() -> void:
	var tetto := OutdoorGameplay.LAVORETTO_PAGA * 2
	var quante := int(OUTDOOR_WORLD.SCORTE_PER_PRESIDIO)
	_controlla(quante >= 2,
		"un presidio di %d sacca non e' un anello: si aggira invece di attraversarlo" % quante)
	var precedente := 0
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var grado := _grado_scorta(livello)
		# Il caso peggiore: Eli al grado zero, cioe' chi non si e' allenato per
		# niente. E' proprio lui che dev'essere ancora in grado di attraversare.
		var anello := quante * grado * WorldEnemy.COSTO_PER_GRADO
		_controlla(anello <= tetto,
			"al mondo %d attraversare l'anello costa %d energie, oltre il tetto di %d"
			% [livello, anello, tetto])
		# Una scorta non puo' essere piu' forte della guardiana che affianca: il
		# pericolo vero e' al centro, non sul bordo.
		_controlla(grado <= _grado_sacca(livello),
			"al mondo %d la scorta e' piu' forte della guardiana" % livello)
		_controlla(grado >= precedente,
			"al mondo %d le scorte sono piu' deboli di quelle del mondo prima" % livello)
		precedente = grado
	# E devono crescere: un anello identico dal mondo 1 al 24 non e' una minaccia.
	_controlla(_grado_scorta(ApparatusConfig.MAX_LEVEL) > _grado_scorta(1),
		"le scorte dell'ultimo mondo non sono piu' forti di quelle del primo")

## --- Il presidio giocato ------------------------------------------------------

func _run() -> void:
	_prova_costo_dell_anello()

	root.size = Vector2i(900, 600)
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _request(MONDO_DI_PROVA))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	current_scene = mondo
	await process_frame
	await process_frame

	var costanti: Dictionary = mondo.get_script().get_script_constant_map()
	var raggio := float(costanti.get("PRESIDIO_RAGGIO", 156.0))
	var distanza_obiettivo := float(costanti.get("PRESIDIO_DISTANZA_DA_OBIETTIVO", 340.0))
	var quante := int(costanti.get("SCORTE_PER_PRESIDIO", 2))
	var player: CharacterBody2D = mondo.get("player")
	var scorte_dict: Dictionary = mondo.get("_scorte")

	# Gli obiettivi veri del mondo si mettono da parte per la durata della prova:
	# la regola «niente presidi vicino al gate» va provata su un obiettivo
	# piazzato apposta, altrimenti l'esito dipenderebbe da dove il direttore ha
	# disposto gli eventi di QUESTO seed — cioe' non proverebbe la regola.
	var veri_aperti: Array = []
	for nodo in get_nodes_in_group("mission_poi"):
		if not bool((nodo as Node).get_meta("completed", false)):
			veri_aperti.append(nodo)
			(nodo as Node).set_meta("completed", true)

	# --- 0. Un centro utilizzabile -------------------------------------------
	# Una scorta che cadrebbe in acqua o dentro un'area protetta viene saltata
	# invece che forzata altrove: si cerca quindi un centro dove l'anello nasce
	# intero, provando attorno a Eli. Se non se ne trova nessuno in ventiquattro
	# direzioni, e' il presidio a non funzionare, non l'audit a essere sfortunato.
	var chiave := ""
	var centro := Vector2.ZERO
	var anello: Array = []
	for tentativo in range(24):
		var candidata := "guardia-prova-%02d" % tentativo
		var punto: Vector2 = player.global_position + Vector2.RIGHT.rotated(
			TAU * float(tentativo) / 24.0) * 900.0
		mondo.call("_schiera_presidio", candidata, punto)
		var schierate: Array = Array(scorte_dict.get(candidata, []))
		if schierate.size() == quante:
			chiave = candidata
			centro = punto
			anello = schierate
			break
		mondo.call("_sciogli_presidio", candidata)
	_controlla(not anello.is_empty(),
		"nessun anello intero in ventiquattro direzioni attorno a Eli: il presidio non si schiera")
	if anello.is_empty():
		await _esito(mondo, veri_aperti)
		return

	# --- 1. Vicino a un obiettivo del gate, nessun presidio -------------------
	# E' la riga che rende lecito tutto il resto.
	var finto_obiettivo := Area2D.new()
	finto_obiettivo.name = "FintoObiettivoDiGate"
	finto_obiettivo.set_meta("kind", "encounter")
	finto_obiettivo.set_meta("id", "finto-gate")
	finto_obiettivo.set_meta("completed", false)
	finto_obiettivo.add_to_group("mission_poi")
	mondo.get("world_layer").add_child(finto_obiettivo)
	finto_obiettivo.global_position = centro + Vector2(distanza_obiettivo - 40.0, 0)
	mondo.call("_schiera_presidio", "guardia-vietata", centro + Vector2(2, 0))
	_controlla(not scorte_dict.has("guardia-vietata"),
		"un presidio e' nato a %.0f unita' da un obiettivo del gate: pedaggio sulla progressione"
		% (distanza_obiettivo - 40.0))
	# Un obiettivo gia' chiuso non protegge piu' niente: e' passato, e continuare a
	# tenergli attorno una zona franca sarebbe una regola che non scade mai.
	finto_obiettivo.set_meta("completed", true)
	mondo.call("_schiera_presidio", "guardia-lecita", centro + Vector2(2, 0))
	_controlla(scorte_dict.has("guardia-lecita"),
		"nessun presidio accanto a un obiettivo gia' completato: la zona franca non scade mai")
	mondo.call("_sciogli_presidio", "guardia-lecita")
	finto_obiettivo.queue_free()
	await process_frame

	# --- 2. L'anello e' un anello, e le scorte sono scorte --------------------
	for scorta in anello:
		_controlla(str(scorta.get("ruolo")) == WorldEnemy.RUOLO_SCORTA,
			"una sacca dell'anello non ha il ruolo di scorta")
		_controlla(str(scorta.get("presidio")) == chiave,
			"una scorta non sa a quale presidio appartiene: non si scioglierebbe mai")
		_controlla(scorta.find_child("EnemyChallenge", true, false) == null,
			"una scorta si puo' sfidare: promette un duello che non esiste")
		_controlla(str(scorta.get("treasure_id")).is_empty(),
			"una scorta dichiara un forziere: chiuderebbe una cassa che non custodisce")
		var quanto: float = centro.distance_to((scorta as Node2D).global_position)
		_controlla(absf(quanto - raggio) < 90.0,
			"una scorta sta a %.0f dal centro invece che sull'anello di %.0f" % [quanto, raggio])
		_controlla(int(scorta.get("tier")) == _grado_scorta(MONDO_DI_PROVA),
			"la scorta non ha il grado ridotto: l'anello costa quanto due guardiane")

	# --- 3. Non blocca: si attraversa pagando, e a zero si attraversa gratis ---
	var save: GameSaveManager = mondo.get("game_save")
	var materia := str(mondo.call("_world_subject"))
	var padronanza_prima := float(save.mastery_of(materia))
	var prima: Node2D = anello[0]
	prima.global_position = player.global_position + Vector2(30, 0)
	var dove_era := player.global_position
	var energia_prima := int(save.energy())
	mondo.call("_on_enemy_contact", prima, player)
	_controlla(player.global_position.distance_to(dove_era) > 40.0,
		"la scorta ha fermato Eli invece di respingerla: un presidio non blocca mai")
	_controlla(int(save.energy()) <= energia_prima, "il contatto con la scorta ha REGALATO energia")
	_controlla(int(save.energy()) >= 0, "il morso della scorta ha portato l'energia sotto zero")
	_controlla(is_equal_approx(save.mastery_of(materia), padronanza_prima),
		"la scorta ha toccato la padronanza: una sacca non puo' farti disimparare")

	# A energia zero si passa lo stesso e non si paga niente: e' il caso che
	# dimostra il «non blocca mai» invece di dichiararlo.
	save.spend_energy(save.energy())
	prima.global_position = player.global_position + Vector2(30, 0)
	prima.set("contact_ready_msec", 0)
	dove_era = player.global_position
	mondo.call("_on_enemy_contact", prima, player)
	_controlla(int(save.energy()) == 0, "a energia zero il presidio ha comunque tolto qualcosa")
	_controlla(player.global_position.distance_to(dove_era) > 40.0,
		"a energia zero Eli e' rimasta ferma: il presidio sta bloccando la mappa")

	# --- 4. Un impulso spegne l'anello intero ---------------------------------
	# Senza questo la scelta non e' pagabile e resta soltanto il pedaggio: e' il
	# controllo che dice se questo lotto ha fatto quello che diceva di fare.
	for scorta in anello:
		(scorta as Node2D).global_position = player.global_position + Vector2(0, 40)
		scorta.set("stunned_until_msec", 0)
	for _prova in range(PulseCharge.PROVE_PER_CARICA):
		PulseCharge.accredita(save)
	mondo.call("_combat_pulse")
	await process_frame
	for scorta in anello:
		_controlla(bool(scorta.call("is_stunned")),
			"una scorta e' rimasta attiva dopo l'impulso: la carica non compra il passaggio")

	# --- 5. L'anello si scioglie con la guardiana -----------------------------
	mondo.call("_sciogli_presidio", chiave)
	_controlla(not scorte_dict.has(chiave),
		"il presidio resta registrato dopo essere stato sciolto")
	await create_timer(0.8).timeout
	for scorta in anello:
		_controlla(not is_instance_valid(scorta) or not scorta.is_in_group("world_enemy"),
			"una scorta sopravvive alla propria guardiana: pedaggio su un forziere gia' guadagnato")

	await _esito(mondo, veri_aperti)

func _esito(mondo: Node, veri_aperti: Array) -> void:
	for nodo in veri_aperti:
		if is_instance_valid(nodo):
			(nodo as Node).set_meta("completed", false)
	root.remove_child(mondo)
	mondo.queue_free()
	current_scene = null
	await process_frame
	if _rossi.is_empty():
		print("PRESIDIO audit OK — solo davanti ai forzieri, non blocca, l'impulso lo apre, si scioglie con la guardiana")
		quit(0)
		return
	for riga in _rossi:
		printerr("PRESIDIO audit FALLITO — %s" % riga)
	quit(1)
