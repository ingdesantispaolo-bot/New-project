extends SceneTree

## **Una spiegazione per ogni tipologia di esercizio.** (6 agosto 2026)
##
## Gli audit che c'erano guardavano le spiegazioni dei **banchi** e quelle dei
## **minigiochi**, separatamente. Nessuno chiedeva la cosa più semplice: che
## **ogni formato raggiungibile** ne abbia una, sempre. Un formato nuovo — e in
## questo progetto ne nascono spesso — poteva entrare senza spiegazioni e i due
## audit esistenti restavano verdi, perché guardavano altrove.
##
## Qui si costruiscono sessioni vere su tutte e dodici le materie e sette
## livelli, si raggruppa per formato e si pretende:
##
##   1. **nessuna spiegazione mancante**, in nessun formato;
##   2. **abbastanza formati visti**: se il campione ne coprisse tre, la prova
##      direbbe poco e sembrerebbe dire molto;
##   3. **niente formule generiche**: nessuna frase può coprire più di un quarto
##      dei nodi del suo formato. È il difetto del 5 agosto — «Collega ogni
##      elemento a sinistra con quello giusto a destra», identica in ogni materia
##      e in ogni mondo — che era un'istruzione travestita da spiegazione.
##
## Non si guarda la LUNGHEZZA, ed è una lezione pagata: misurando, le
## spiegazioni più corte del gioco sono anche fra le migliori — «Dal greco aer,
## aria», «Sorge sulla Senna». Corte perché precise.

const LIVELLI := [1, 3, 6, 10, 14, 18, 22]
const ESTRAZIONI := 6
## Formati che il campione deve incontrare. Sotto questa soglia la prova non sta
## verificando il gioco: sta verificando una sua fetta.
const FORMATI_MINIMI := 18
## Quota massima di nodi di un formato coperti dalla stessa identica frase.
const QUOTA_GENERICA := 0.25
## Sotto questo numero di nodi un formato è troppo raro perché la quota dica
## qualcosa: con sei nodi due frasi uguali fanno già il 33%.
const CAMPIONE_MINIMO := 40

func _init() -> void:
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var per_formato: Dictionary = {}    # formato -> {frase: conteggio}
	var totali: Dictionary = {}
	var mancanti: Array = []

	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for livello in LIVELLI:
			for seme in range(ESTRAZIONI):
				var rng := RandomNumberGenerator.new()
				rng.seed = seme * 7919 + livello * 131 + subject.hash()
				_raccogli(per_formato, totali, mancanti,
					Array(content.build_mission(subject, livello, 4, {}, rng).get("nodes", [])))
				var rng2 := RandomNumberGenerator.new()
				rng2.seed = seme * 104729 + livello * 17
				_raccogli(per_formato, totali, mancanti,
					Array(mg.build_minigame(subject, livello, rng2).get("nodes", [])))
			_raccogli(per_formato, totali, mancanti,
				Array(content.build_final_exam(subject, livello, 3).get("nodes", [])))

	# Il messaggio si compone PRIMA: in GDScript l'argomento di `assert` viene
	# valutato comunque, anche quando la condizione è vera, e leggere
	# `mancanti[0]` su un elenco vuoto faceva esplodere proprio il caso buono.
	var elenco := "nessuno" if mancanti.is_empty() else ", ".join(PackedStringArray(mancanti))
	assert(mancanti.is_empty(),
		"%d esercizi senza spiegazione: %s" % [mancanti.size(), elenco])

	assert(totali.size() >= FORMATI_MINIMI,
		"il campione ha incontrato solo %d formati (minimo %d): la prova non sta guardando tutto il gioco" % [
			totali.size(), FORMATI_MINIMI])

	for formato_data in totali.keys():
		var formato := str(formato_data)
		var nodi := int(totali[formato])
		if nodi < CAMPIONE_MINIMO:
			continue
		var frasi: Dictionary = per_formato[formato]
		for frase_data in frasi.keys():
			var quota := float(int(frasi[frase_data])) / float(nodi)
			assert(quota <= QUOTA_GENERICA,
				"in «%s» una sola frase copre il %.0f%% dei nodi: è un'istruzione, non una spiegazione — «%s»" % [
					formato, quota * 100.0, str(frase_data).substr(0, 70)])

	print("EXPLANATION COVERAGE audit OK — %d formati, nessuna spiegazione mancante, nessuna formula sopra il %.0f%%" % [
		totali.size(), QUOTA_GENERICA * 100.0])
	quit(0)

func _raccogli(per_formato: Dictionary, totali: Dictionary, mancanti: Array, nodi: Array) -> void:
	for n in nodi:
		var nodo: Dictionary = n
		var formato := str(nodo.get("format", "?"))
		totali[formato] = int(totali.get(formato, 0)) + 1
		var spieg := str(nodo.get("explanation", "")).strip_edges()
		if spieg.is_empty():
			if mancanti.size() < 5:
				mancanti.append("%s · %s" % [formato, str(nodo.get("prompt", "")).substr(0, 60)])
			continue
		var frasi: Dictionary = per_formato.get(formato, {})
		frasi[spieg] = int(frasi.get(spieg, 0)) + 1
		per_formato[formato] = frasi
