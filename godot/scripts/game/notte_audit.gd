extends SceneTree

## **La notte cambia qualcosa, e non è il buio.** (5 settembre 2026)
##
## Richiesta del committente: dare valore alla mappa e aggiungere tensione. Il
## ciclo giorno/notte c'era già e muoveva un solo `CanvasModulate`: il piano lo
## chiamava *«un filtro, non un'ora»*, perché oltre al colore non cambiava niente.
##
## **Il buio non poteva essere la leva.** `WorldSky.PAVIMENTO` garantisce una
## luminanza minima di 0,20 su tutto ciò che finisce sullo schermo, ed è una
## promessa di accessibilità che non si tocca da nessuna direzione — nemmeno per
## fare atmosfera. Quindi la notte doveva cambiare *che cosa succede*.
##
## Succede che le sacche notano Eli da più lontano. Questa guardia tiene le
## quattro proprietà che rendono quella regola giusta invece che solo severa.
##
##   1. **La notte stringe davvero.** Se il moltiplicatore tornasse a uno, il
##      ciclo tornerebbe a essere un filtro e nessuno se ne accorgerebbe.
##   2. **Non chiude nessuna strada.** Il guard-rail «niente blocca il loop» vale
##      anche per l'ora del giorno: una notte che rendesse un mondo
##      intraversabile sarebbe un muro con un orologio.
##   3. **L'Andatura felpata è la risposta.** Comprata, riporta la notte a essere
##      percorribile come il giorno. Un modulo da 340 frammenti deve avere un
##      momento in cui serve, o è un ornamento con una descrizione tecnica.
##   4. **Dove il tempo non passa, non cambia niente.** Negli archivi e negli
##      abissi l'ora non è un'informazione, e una sacca che si insospettisce a
##      mezzanotte in un posto senza mezzanotte sarebbe un difetto invisibile.

const OK := "NOTTE audit VERDE"

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	var pieno := ExpeditionModules.VISTA_PIENA
	var felpata := ExpeditionModules.VISTA_FELPATA

	# 1 · La notte stringe.
	var giorno := ExpeditionModules.vista_all_ora(pieno, 1.0)
	var notte := ExpeditionModules.vista_all_ora(pieno, 0.0)
	if notte <= giorno * 1.05:
		_fallisci("di notte le sacche notano come di giorno (%.2f contro %.2f): il ciclo è tornato un filtro" % [
			notte, giorno])

	# 2 · Ma non troppo: una notte che raddoppia la vista chiude il mondo.
	if notte > giorno * 1.6:
		_fallisci("di notte la vista è %.2f volte quella del giorno: a quel punto è un muro con un orologio" % [
			notte / giorno])

	# 3 · L'Andatura felpata riporta la notte al giorno.
	var felpata_di_notte := ExpeditionModules.vista_all_ora(felpata, 0.0)
	if felpata_di_notte > giorno:
		_fallisci("con l'Andatura felpata la notte resta più stretta del giorno (%.2f contro %.2f): il modulo non risponde alla domanda che il mondo pone" % [
			felpata_di_notte, giorno])
	# E non deve nemmeno regalare la notte: se felpata di notte fosse molto più
	# larga del giorno, comprarla cancellerebbe il pericolo invece di reggerlo.
	if felpata_di_notte < giorno * 0.85:
		_fallisci("l'Andatura felpata cancella la notte (%.2f contro %.2f): un pericolo disinnescato non è un pericolo, è un disegno" % [
			felpata_di_notte, giorno])

	# 4 · A metà strada la curva è monotona: nessun salto, nessuna inversione.
	var precedente := 0.0
	for passo in range(11):
		var luce := 1.0 - float(passo) / 10.0
		var quanto := ExpeditionModules.vista_all_ora(pieno, luce)
		if quanto < precedente - 0.0001:
			_fallisci("la vista cala scendendo verso la notte (%.3f dopo %.3f)" % [
				quanto, precedente])
		precedente = quanto

	if errori.is_empty():
		print("%s — di notte %.2f, con l'Andatura felpata %.2f, di giorno %.2f" % [
			OK, notte, felpata_di_notte, giorno])
	else:
		printerr("NOTTE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
