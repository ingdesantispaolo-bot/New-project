extends SceneTree

## **Quanto costa davvero una sacca, mondo per mondo.** (21 agosto 2026)
##
## Nasce da una domanda del committente: l'impulso e lo scatto servono ancora a
## qualcosa, o vanno tolti? La misura ha risposto per tutti e due, e in modo
## opposto — l'impulso è stato tolto, lo scatto è rimasto.
##
## La misura che decide è una sola, e non si vede giocando due ore:
##
##     costo del morso = (grado della sacca − grado di Eli) × 2
##
## Il grado di Eli usciva dallo **stesso rubinetto** delle cariche d'impulso: una
## prova superata chiamava `WorldLight.avanza_potenza` e `PulseCharge.accredita`
## nella stessa riga di `outdoor_gameplay`. Più cariche avevi, più eri forte — e
## più eri forte, meno c'era da comprare con quelle cariche. Il risultato, qui
## sotto: **dal mondo 2 in poi nessuna sacca costa una sola energia**, per il
## resto della campagna.
##
## ## Perché resta, adesso che l'impulso non c'è più
##
## Perché la saturazione è ancora lì, e il giorno in cui qualcuno vorrà rimettere
## una risorsa da spendere contro le sacche — o alzare il grado dei nemici, o
## mettere un pavimento al morso — questa tabella è il posto dove si vede subito
## se quella cosa avrebbe lavoro da fare. Senza, la si taglierebbe di nuovo a
## naso e si scoprirebbe di nuovo fra un mese.
##
## Uso: godot --headless --path godot --script res://scripts/game/costo_delle_sacche_probe.gd

## Esercizi cumulativi all'INGRESSO di ogni mondo, da `effort_probe`. Usarli al
## posto del totale di fine mondo è la lettura più generosa possibile verso le
## meccaniche misurate: durante il mondo il grado sale ancora, e il costo scende.
const CUMULATO_INGRESSO := [
	0, 41, 118, 231, 308, 457, 606, 719, 796, 909, 1022, 1243,
	1356, 1469, 1582, 1767, 1916, 2029, 2178, 2327, 2440, 2553, 2666, 2851,
]

func _init() -> void:
	_tabella()
	_il_verdetto()
	quit(0)

func _grado_di(prove: int) -> int:
	var g := 0
	for voce in WorldLight.SOGLIE:
		if prove >= int(Dictionary(voce)["prove"]):
			g = int(Dictionary(voce)["tier"])
	return g

func _grado_sacca(mondo: int) -> int:
	return clampi(1 + floori(float(mondo - 1) / 3.0), 1, 8)

func _grado_scorta(mondo: int) -> int:
	return maxi(1, _grado_sacca(mondo) - WorldEnemy.SCARTO_SCORTA)

func _costo(grado_sacca: int, grado_eli: int) -> int:
	return maxi(0, grado_sacca - grado_eli) * WorldEnemy.COSTO_PER_GRADO

func _tabella() -> void:
	print("")
	print("Costo reale di una sacca — campagna seguita, non Eli ferma al grado zero")
	print("")
	print("MONDO  prove  gradoEli  guardiana→costo  scorta→costo  ANELLO")
	for mondo in range(1, 25):
		var prove: int = CUMULATO_INGRESSO[mondo - 1]
		var grado := _grado_di(prove)
		var gs := _grado_sacca(mondo)
		var sc := _grado_scorta(mondo)
		print("%5d  %5d  %8d  %8d→%-6d %6d→%-6d %6d" % [
			mondo, prove, grado,
			gs, _costo(gs, grado),
			sc, _costo(sc, grado),
			2 * _costo(sc, grado),
		])

func _il_verdetto() -> void:
	var primo_mondo_gratis := -1
	var mondi_a_costo_zero := 0
	var mondi_anello_zero := 0
	for mondo in range(1, 25):
		var grado := _grado_di(CUMULATO_INGRESSO[mondo - 1])
		if _costo(_grado_scorta(mondo), grado) == 0:
			mondi_anello_zero += 1
		if _costo(_grado_sacca(mondo), grado) == 0:
			mondi_a_costo_zero += 1
			if primo_mondo_gratis < 0:
				primo_mondo_gratis = mondo
		else:
			primo_mondo_gratis = -1
	print("")
	print("VERDETTO")
	print("  mondi in cui l'ANELLO del presidio costa zero: %d su 24" % mondi_anello_zero)
	print("  mondi in cui NESSUNA sacca costa niente:       %d su 24" % mondi_a_costo_zero)
	print("  dal mondo %d in poi non si paga piu' niente, per il resto della campagna"
		% primo_mondo_gratis)
	print("")
	# Quello che resta a difendere l'anello, e perche' non si esaurisce: lo
	# spintone costa posizione e tempo, e quelli il grado non li azzera.
	print("  quel che resta contro l'anello e' la corsa: costa 0, torna ogni %.1f s,"
		% (float(OutdoorPlayerController.SCATTO_RICARICA_MSEC) / 1000.0))
	print("  attraversa una sacca senza morso e senza spintone — e lo spintone")
	print("  non si azzera col grado, quindi questa strada non satura mai.")
