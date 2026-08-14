extends SceneTree

## **La potenza deve stare al passo della minaccia.** (14 agosto 2026)
##
## Il difetto da cui nasce: la scala della potenza si fermava a 140 prove — cinque
## gradi — mentre le sacche di Silenzio salgono fino al grado otto. Misurata con
## `power_curve_probe`, la campagna vale 590 prove e il grado massimo arrivava
## all'ottavo mondo: **per sedici mondi Eli non cresceva più** mentre la minaccia
## continuava a salire, fino a uno scarto di quattro gradi, cioè otto energie a
## ogni morso contro un giocatore che non poteva farci niente.
##
## Nessun audit se ne era accorto perché ognuno guardava metà del problema:
## `world_light_audit` controllava che le soglie crescessero, `enemy_threat_audit`
## che il grado massimo bastasse contro le sacche. Nessuno confrontava **quando**
## si arriva a un grado con **quanto è forte la minaccia in quel momento**.
##
## Le quattro cose che verifica:
##
## 1. **Nessun mondo lascia Eli più di due gradi sotto le sue sacche.** Due è la
##    tolleranza, non l'obiettivo: dentro un mondo il conto delle prove cresce, e
##    la misura qui è quella di fine mondo.
## 2. **Ogni grado si raggiunge giocando.** Un grado che chiede più prove di
##    quante la campagna ne contenga è una promessa che nessuno vede.
## 3. **L'ultimo grado arriva prima della fine**, con margine: guadagnarlo
##    nell'ultima mezz'ora è come non averlo.
## 4. **Nessun gradino dura troppo.** Un grado che copre mezza campagna è il
##    difetto di partenza con un altro nome.

const OK := "POWER CURVE audit VERDE"

## Prove cumulate a fine mondo, misurate da `power_curve_probe` il 14 agosto 2026
## sul percorso vero (missione della materia del mondo + pratica delle materie che
## il gate dichiara mancanti + esame).
##
## È una fotografia, non una legge: se il costo dei mondi cambia, questa tabella
## va rimisurata con la sonda. Sta qui perché l'audit deve restare veloce — la
## simulazione vera impiega quasi un minuto — e perché un numero scritto è un
## numero che si può discutere.
const PROVE_A_FINE_MONDO := [
	13, 31, 57, 75, 94, 115, 138, 162, 183, 208, 230, 259,
	287, 312, 338, 366, 393, 421, 449, 474, 505, 534, 563, 590,
]

## Quanto può restare indietro il grado di Eli rispetto a quello delle sacche.
const SCARTO_TOLLERATO := 2

## Quanti mondi al massimo può durare lo stesso grado.
const PLATEAU_MASSIMO := 4

## Quante prove devono restare dopo l'ultimo grado, perché si faccia in tempo a
## goderselo: una quarantina, cioè un mondo e mezzo abbondante.
const CODA_MINIMA := 40

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

## Il grado delle sacche di un mondo, com'è calcolato in `world_enemy.gd`. Se
## quella formula cambia, questa deve cambiare con lei — ed è il motivo per cui
## l'audit confronta le due invece di fidarsi di una.
func _tier_sacche(livello: int) -> int:
	return clampi(1 + floori(float(livello - 1) / 3.0), 1, 8)

func _grado_a(prove: int) -> int:
	var save := GameSaveManager.new()
	save.data["powerRuns"] = prove
	return WorldLight.grado(save)

func _init() -> void:
	_la_potenza_sta_al_passo()
	_ogni_grado_si_raggiunge()
	_nessun_gradino_eterno()
	if errori.is_empty():
		print(OK)
	else:
		printerr("POWER CURVE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## **Il confronto che mancava.** Mondo per mondo: quanto è forte Eli quando
## incontra le sacche di quel mondo.
func _la_potenza_sta_al_passo() -> void:
	_controlla(PROVE_A_FINE_MONDO.size() == ApparatusConfig.MAX_LEVEL,
		"la tabella delle prove copre %d mondi invece di %d: va rimisurata con la sonda" % [
			PROVE_A_FINE_MONDO.size(), ApparatusConfig.MAX_LEVEL])
	for indice in range(mini(PROVE_A_FINE_MONDO.size(), ApparatusConfig.MAX_LEVEL)):
		var livello := indice + 1
		var grado := _grado_a(int(PROVE_A_FINE_MONDO[indice]))
		var tier := _tier_sacche(livello)
		_controlla(grado >= tier - SCARTO_TOLLERATO,
			"mondo %d: Eli arriva al grado %d contro sacche di grado %d (scarto %d, tollerato %d)" % [
				livello, grado, tier, tier - grado, SCARTO_TOLLERATO])

## **Nessuna promessa irraggiungibile.** Ogni grado dichiarato deve arrivare
## dentro la campagna, e l'ultimo con un po' di strada davanti.
func _ogni_grado_si_raggiunge() -> void:
	var totale := int(PROVE_A_FINE_MONDO[PROVE_A_FINE_MONDO.size() - 1])
	for voce in WorldLight.SOGLIE:
		var soglia: Dictionary = voce
		_controlla(int(soglia["prove"]) <= totale,
			"il grado «%s» chiede %d prove ma la campagna ne contiene %d" % [
				str(soglia["nome"]), int(soglia["prove"]), totale])
	var ultima := int(Dictionary(WorldLight.SOGLIE[WorldLight.SOGLIE.size() - 1])["prove"])
	_controlla(totale - ultima >= CODA_MINIMA,
		"l'ultimo grado arriva a %d prove su %d: restano %d prove per goderselo, ne servono %d" % [
			ultima, totale, totale - ultima, CODA_MINIMA])
	# E il grado massimo deve bastare contro la sacca più forte: se non bastasse,
	# allenarsi fino in fondo non annullerebbe comunque il morso, e la promessa di
	# `world_enemy.gd` sarebbe falsa.
	_controlla(WorldLight.SOGLIE.size() - 1 >= _tier_sacche(ApparatusConfig.MAX_LEVEL),
		"nemmeno il grado massimo raggiunge il grado delle sacche dell'ultimo mondo")

## **Nessun gradino eterno.** Un grado che copre mezza campagna è esattamente il
## difetto da cui questo audit nasce, scritto in un altro punto della scala.
func _nessun_gradino_eterno() -> void:
	var mondi_per_grado: Dictionary = {}
	for indice in range(mini(PROVE_A_FINE_MONDO.size(), ApparatusConfig.MAX_LEVEL)):
		var grado := _grado_a(int(PROVE_A_FINE_MONDO[indice]))
		mondi_per_grado[grado] = int(mondi_per_grado.get(grado, 0)) + 1
	for grado in mondi_per_grado.keys():
		# L'ultimo grado può durare quanto vuole: dopo di lui non c'è altro da
		# aspettare, ed è la ricompensa del finale.
		if int(grado) == WorldLight.SOGLIE.size() - 1:
			continue
		_controlla(int(mondi_per_grado[grado]) <= PLATEAU_MASSIMO,
			"il grado %d copre %d mondi di fila (massimo %d): in mezzo non cambia niente" % [
				int(grado), int(mondi_per_grado[grado]), PLATEAU_MASSIMO])
