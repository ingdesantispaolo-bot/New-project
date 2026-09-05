extends SceneTree

## **Il minigioco di un personaggio cresce fra un incontro e l'altro.**
## (5 settembre 2026)
##
## Richiesta del committente: *«controlla che anche i minigiochi siano a
## difficoltà crescente sui 24 livelli»*.
##
## ## Il criterio giusto non è «ventiquattro gradini»
##
## La prima misura contava i gradini distinti che ogni archetipo produce fra il
## mondo 1 e il 24, e dava una media di 12,5 su 24 — con cinque archetipi fermi a
## tre. Ma è la domanda sbagliata: **un bambino non incontra un archetipo
## ventiquattro volte.** Il mucchio lo incontra una volta sola, al mondo 1; la
## prova quattro, ai mondi 10, 15, 20 e 21. Ventiquattro gradini per una prova
## giocata una volta sono un numero che non tocca nessuno.
##
## La domanda che conta è: **nei mondi in cui quell'archetipo compare davvero, la
## richiesta cresce?** È lo stesso criterio che `guardian_duel_audit` applica alle
## fasce del duello, ed è quello applicato qui.
##
## ## Che cosa NON dice questa misura
##
## Non dice che due incontri siano uguali: il materiale è del personaggio, non
## dell'archetipo, quindi Corinna e Coral propongono parole diverse anche a
## parità di parametri. Quello che si misura qui è **quanto il gioco chiede**, non
## che cosa mostra.

const OK := "MINIGIOCHI SCALA audit VERDE"

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	_la_richiesta_cresce_fra_gli_incontri()
	if errori.is_empty():
		print(OK)
	else:
		printerr("MINIGIOCHI SCALA audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## **Quanto chiede una prova, in un numero solo.**
##
## Le quantità salgono, gli errori concessi scendono: sono le due direzioni in cui
## ogni archetipo esprime la propria difficoltà. Il tempo NON entra nel conto —
## metà degli archetipi non ha cronometro per scelta, e sommare secondi a
## quantità confronterebbe cose diverse.
func _richiesta(p: Dictionary) -> int:
	var somma := 0
	for chiave in p.keys():
		var nome := str(chiave)
		if nome == "secondi" or nome == "cooldown" or nome == "arrivo":
			continue
		if nome == "errori":
			# Meno errori concessi = più richiesta. Il segno è l'unica cosa che
			# distingue questa chiave dalle altre.
			somma -= int(p[chiave]) * 3
			continue
		somma += int(p[chiave])
	return somma

func _la_richiesta_cresce_fra_gli_incontri() -> void:
	var per_archetipo: Dictionary = {}
	for npc_id in CharacterMinigameCatalog.GIOCHI.keys():
		var scheda: Dictionary = CharacterMinigameCatalog.GIOCHI[npc_id]
		var archetipo := str(scheda.get("archetipo", ""))
		if not per_archetipo.has(archetipo):
			per_archetipo[archetipo] = []
		Array(per_archetipo[archetipo]).append(str(npc_id))

	var chiavi := per_archetipo.keys()
	chiavi.sort()
	for a in chiavi:
		var npcs: Array = per_archetipo[a]
		var incontri: Array = []
		for npc_id in npcs:
			var scheda := CharacterMinigameCatalog.scheda(str(npc_id))
			incontri.append([int(scheda.get("world", 1)), str(npc_id)])
		incontri.sort_custom(func(x, y): return int(x[0]) < int(y[0]))
		if incontri.size() < 2:
			# Un archetipo che si incontra una volta sola non ha una curva da
			# rispettare: la sua difficoltà è quella del suo mondo, e basta.
			continue
		var precedente := -99999
		var primo := 0
		var ultimo := 0
		for indice in range(incontri.size()):
			var mondo := int(incontri[indice][0])
			var quanto := _richiesta(
				CharacterMinigameCatalog.parametri(str(a), mondo))
			if indice == 0:
				primo = quanto
			ultimo = quanto
			if quanto < precedente:
				_fallisci("%s: al mondo %d chiede MENO che all'incontro prima (%d dopo %d)" % [
					str(a), mondo, quanto, precedente])
			precedente = quanto
		# E la campagna deve sentirsi crescere: l'ultimo incontro non può chiedere
		# quanto il primo, o la difficoltà per mondo è una decorazione.
		if ultimo <= primo:
			var mondi: Array = []
			for v in incontri:
				mondi.append(int(v[0]))
			_fallisci("%s: l'ultimo incontro non chiede più del primo (%d contro %d, mondi %s)" % [
				str(a), ultimo, primo, str(mondi)])
