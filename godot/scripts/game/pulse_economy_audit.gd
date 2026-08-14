extends SceneTree

## **L'impulso si guadagna, non si aspetta.** (14 agosto 2026)
##
## Questo audit esiste per un difetto che nessun controllo aveva visto per una
## settimana, perché ogni pezzo era coerente con se stesso: il 7 agosto le sacche
## di Silenzio sono diventate un pericolo con un costo tarato sul grado di Eli, e
## nello stesso mondo c'era un pulsante che le stordiva **gratis** ricaricandosi
## in 1,25 secondi. Il morso non lo pagava nessuno. Un lotto intero — la barra di
## potenza, i gradi, la promessa *chi si allena passa* — era stato annullato da un
## bottone.
##
## Le cinque cose che verifica, e perché ognuna:
##
## 1. **L'aritmetica delle cariche**, tetto compreso, e che a serbatoio pieno non
##    si accumuli una riserva invisibile.
## 2. **L'impulso non è mai gratuito**: a zero cariche rifiuta, e rifiutare non
##    cambia niente.
## 3. **Le cariche si guadagnano solo con le prove**: energia, frammenti e
##    acquisti non ne producono. È la catena che tiene insieme il lotto — se un
##    giorno si potessero comprare, la potenza tornerebbe a non servire a niente.
## 4. **Usare l'impulso non tocca nient'altro**: né energia, né frammenti, né
##    padronanza, né gate.
## 5. **Le cariche non gattano niente**: due partite identiche con zero e con tre
##    cariche hanno lo stesso identico stato di progressione. È la forma
##    verificabile di «niente sulla mappa può fermare la progressione».
##
## Il lato mappa della stessa promessa — il morso che prende quel che c'è quando
## l'energia non basta, e il forziere che si apre col varco e non con l'impulso —
## lo tengono `reflex_duel_audit` e il mondo.

var errori: Array = []
var gameplay: OutdoorGameplay

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_l_aritmetica_delle_cariche()
	_la_partita()
	if errori.is_empty():
		print("PULSE ECONOMY audit VERDE — cariche guadagnate, mai gratis, e niente gate")
	else:
		printerr("PULSE ECONOMY audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## **L'aritmetica.** Due prove una carica, tetto a tre, e a serbatoio pieno il
## progresso non si accumula: altrimenti chi gioca a lungo con tre cariche si
## ritroverebbe una riserva nascosta che si scarica tutta insieme, e il tetto
## sarebbe una finzione.
func _l_aritmetica_delle_cariche() -> void:
	var save := GameSaveManager.new()
	_controlla(PulseCharge.cariche(save) == 0,
		"un salvataggio nuovo parte con %d cariche invece di zero" % PulseCharge.cariche(save))
	_controlla(not PulseCharge.consuma(save),
		"a serbatoio vuoto l'impulso si accende lo stesso")

	# La prima carica costa esattamente le prove dichiarate, non una di meno.
	for prova in range(PulseCharge.PROVE_PER_CARICA - 1):
		_controlla(not PulseCharge.accredita(save),
			"la carica è arrivata dopo %d prove invece di %d" % [
				prova + 1, PulseCharge.PROVE_PER_CARICA])
	_controlla(PulseCharge.accredita(save),
		"dopo %d prove la carica non è arrivata" % PulseCharge.PROVE_PER_CARICA)
	_controlla(PulseCharge.cariche(save) == 1,
		"dopo la prima carica ne risultano %d" % PulseCharge.cariche(save))

	# Il tetto tiene, per quante prove si facciano.
	for _i in range(200):
		PulseCharge.accredita(save)
	_controlla(PulseCharge.cariche(save) == PulseCharge.MASSIMO,
		"duecento prove danno %d cariche invece del tetto %d" % [
			PulseCharge.cariche(save), PulseCharge.MASSIMO])
	_controlla(PulseCharge.verso_la_prossima(save) == 0,
		"a serbatoio pieno il gioco dichiara ancora prove mancanti")

	# **Nessuna riserva invisibile**: spesa una carica, la successiva costa di
	# nuovo il prezzo pieno.
	_controlla(PulseCharge.consuma(save), "a serbatoio pieno l'impulso non si accende")
	_controlla(PulseCharge.verso_la_prossima(save) == PulseCharge.PROVE_PER_CARICA,
		"dopo aver speso una carica ne mancano %d invece di %d: c'era una riserva accumulata" % [
			PulseCharge.verso_la_prossima(save), PulseCharge.PROVE_PER_CARICA])

	# Si spende una per volta, e sotto zero non si va.
	for _i in range(PulseCharge.MASSIMO):
		PulseCharge.consuma(save)
	_controlla(PulseCharge.cariche(save) == 0,
		"spendendo tutto restano %d cariche" % PulseCharge.cariche(save))
	_controlla(not PulseCharge.consuma(save), "l'impulso si accende con il serbatoio a zero")
	_controlla(PulseCharge.cariche(save) >= 0, "le cariche sono andate sotto zero")

# --------------------------------------------------------------- partita vera

func _prova_superata(subject: String, id: String) -> void:
	gameplay.active_session_context = {
		"kind": "minigame", "encounterId": id, "subject": subject, "impronte": []}
	gameplay.resolve_session({
		"correct": 3, "total": 3, "passed": true, "energyGained": 30,
		"subject": subject, "seconds": 12.0,
		"missed": [], "reviewedOk": [], "topicStats": {},
	})

## Tutto il resto si misura sulla partita, non sulla formula: è lì che i difetti
## di questa specie si nascondono.
func _la_partita() -> void:
	gameplay = OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := NativeWorldState.default_request("pulse-economy-audit")
	var risultato := NativeWorldState.result_for(request)
	gameplay.setup(request, risultato, false)
	var save := gameplay.game_save

	# --- 5 · Le cariche non gattano niente ---------------------------------
	# Stesso salvataggio, due soli valori di carica: lo stato di progressione
	# deve differire SOLO nel numero di cariche. È la forma verificabile della
	# regola di tutta la mappa — niente qui può fermare la progressione.
	var senza := gameplay.runtime_state()
	for _i in range(PulseCharge.PROVE_PER_CARICA * PulseCharge.MASSIMO):
		PulseCharge.accredita(save)
	var con := gameplay.runtime_state()
	_controlla(int(con.get("pulseCharges", -1)) == PulseCharge.MASSIMO,
		"il contratto runtime non pubblica le cariche piene")
	var diverse: Array = []
	for chiave in senza.keys():
		if str(senza[chiave]) != str(con.get(chiave)):
			diverse.append(str(chiave))
	_controlla(diverse == ["pulseCharges"],
		"le cariche cambiano anche %s: l'impulso sta toccando la progressione" % str(diverse))

	# --- Il contratto per la resa (C-G2) ------------------------------------
	# Senza queste due chiavi il pannello dell'HUD torna al cronometro senza che
	# nessuno se ne accorga: la resa legge di qui e non ricalcola niente.
	_controlla(con.has("pulseCharges") and con.has("pulseChargeMax"),
		"il contratto runtime non espone le cariche: la resa dell'HUD resta muta")
	_controlla(int(con.get("pulseChargeMax", 0)) == PulseCharge.MASSIMO,
		"il tetto pubblicato non è quello della regola")

	# --- 4 · Usare l'impulso non tocca nient'altro --------------------------
	var prima := save.data.duplicate(true)
	_controlla(gameplay.usa_impulso(), "con tre cariche l'impulso non si accende")
	for chiave in prima.keys():
		if str(chiave) == "pulse":
			continue
		_controlla(str(prima[chiave]) == str(save.data.get(chiave)),
			"accendere l'impulso ha cambiato «%s» nel salvataggio" % str(chiave))
	_controlla(PulseCharge.cariche(save) == PulseCharge.MASSIMO - 1,
		"accendere l'impulso non ha speso esattamente una carica")

	# --- 2 · Mai gratis ------------------------------------------------------
	# Il ciclo è limitato di proposito. Alla prima stesura qui c'era un
	# `while PulseCharge.consuma(...)`, e provando a falsificare l'audit — un
	# impulso che si accende sempre, cioè il difetto da cui nasce questo lotto —
	# non è diventato rosso: si è **appeso**, per quattro minuti, fino al timeout.
	# Un audit che si blocca invece di fallire fa perdere il giro a tutta la
	# suite e non dice niente a chi guarda. Un cricchetto deve rompersi in fretta.
	for _i in range(PulseCharge.MASSIMO + 1):
		PulseCharge.consuma(save)
	_controlla(PulseCharge.cariche(save) == 0,
		"dopo aver speso tutto restano %d cariche" % PulseCharge.cariche(save))
	var vuoto := save.data.duplicate(true)
	_controlla(not gameplay.usa_impulso(),
		"a serbatoio vuoto l'impulso si accende: è tornato gratuito")
	for chiave in vuoto.keys():
		_controlla(str(vuoto[chiave]) == str(save.data.get(chiave)),
			"un impulso rifiutato ha comunque cambiato «%s»" % str(chiave))

	# --- 3 · Si guadagnano solo con le prove ---------------------------------
	# Energia, frammenti e acquisti: nessuno di questi è una prova superata.
	save.add_energy(5000)
	gameplay.collect_treasure({"rewardFragments": 50}, "pulse-audit-tesoro")
	gameplay.try_purchase_cosmetic("tool-torch")
	_controlla(PulseCharge.cariche(save) == 0,
		"energia, frammenti o acquisti hanno prodotto %d cariche" % PulseCharge.cariche(save))

	# E una prova superata invece sì, esattamente al prezzo dichiarato.
	for prova in range(PulseCharge.PROVE_PER_CARICA):
		_prova_superata("matematica", "pulse-audit-%d" % prova)
	_controlla(PulseCharge.cariche(save) == 1,
		"due prove superate danno %d cariche invece di una" % PulseCharge.cariche(save))

	# Una prova FALLITA non paga: se pagasse, l'impulso si ricaricherebbe
	# sbagliando, e la catena studi → passi si spezzerebbe nel punto peggiore.
	var prima_del_fallimento := PulseCharge.cariche(save)
	gameplay.active_session_context = {
		"kind": "minigame", "encounterId": "pulse-audit-ko", "subject": "matematica",
		"impronte": []}
	gameplay.resolve_session({
		"correct": 0, "total": 3, "passed": false, "energyGained": 0,
		"subject": "matematica", "seconds": 9.0,
		"missed": [], "reviewedOk": [], "topicStats": {},
	})
	_controlla(PulseCharge.cariche(save) == prima_del_fallimento,
		"una prova fallita ha ricaricato l'impulso")

	root.remove_child(gameplay)
	gameplay.free()
	gameplay = null
