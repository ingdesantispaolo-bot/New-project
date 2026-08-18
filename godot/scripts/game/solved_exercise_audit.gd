extends SceneTree

const Autoplay = preload("res://scripts/game/exercise_autoplay.gd")

## **Una prova superata non viene richiesta di nuovo.** (15 agosto 2026)
##
## Il gioco aveva una memoria sola di ciò che lo studente aveva già visto —
## `recentPractice` — e serviva alla sola palestra. Missioni, enigmi, riparazioni
## ed esami pescavano dal banco senza guardare niente: bastava tornare nel mondo
## per ritrovare parola per parola la domanda a cui si era già risposto bene. È il
## modo peggiore in cui una domanda può tornare, perché la seconda volta si ricorda
## la risposta e non il ragionamento: la padronanza sale e la competenza no.
##
## Questo audit tiene le cinque promesse del meccanismo, e le tiene MISURANDO:
##  1. il save ricorda, non duplica e non cresce oltre il tetto;
##  2. l'indice che la selezione tiene per riferimento resta vivo dopo ogni
##     scrittura — se si congelasse, la prova risolta tornerebbe subito;
##  3. dodici materie, sei missioni ciascuna: nessuna prova già superata torna
##     finché la materia ha altro da chiedere, e le sessioni restano piene;
##  4. superata vuol dire risolta PULITA: chi sbaglia non si porta via la prova;
##  5. il ripasso spaziato passa sopra: un argomento dovuto viene servito anche
##     quando su quell'argomento non è rimasto niente di nuovo.

## Missioni simulate per materia. Sei bastano a esaurire l'argomento del mondo su
## una materia stretta: è lì che si vede se il ripiego regge invece di produrre
## sessioni corte.
const MISSIONI_PER_MATERIA := 6
const NODI_PER_MISSIONE := 3
## Fino a qui la memoria deve essere PERFETTA: nove prove sono circa tre visite
## allo stesso mondo, cioè la distanza a cui la ripetizione era stata segnalata.
## Oltre, su una materia con pochi item al livello giusto, il ripiego può
## legittimamente ripescare — meglio una prova già vista che una missione corta.
const MISSIONI_SENZA_RIPETIZIONI := 3

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_memoria_del_save()
	_indice_vivo()
	var totali := _selezione_non_ripete()
	await _solo_le_prove_pulite()
	_il_ripasso_passa_sopra()
	print("SOLVED EXERCISE audit OK - %d prove servite, %d gia' superate (%d senza memoria)" % [
		int(totali["servite"]), int(totali["ripetute"]), int(totali["ripetute_senza_memoria"])])
	quit()

# --- 1. Il save ricorda -------------------------------------------------------

func _memoria_del_save() -> void:
	var save := GameSaveManager.new()
	var nodo := {"format": "multiple_choice", "prompt": "2+2?", "options": ["4", "5"], "answer": "4"}
	var impronta := GameSaveManager.solved_fingerprint(nodo)
	assert(not save.has_solved("matematica", nodo), "prova segnata superata prima di essere giocata")
	save.remember_solved("matematica", [impronta])
	assert(save.has_solved("matematica", nodo), "prova superata non ricordata")
	assert(not save.has_solved("italiano", nodo), "la memoria ha attraversato le materie")

	# L'impronta guarda il CONTENUTO, non la presentazione: la stessa prova con le
	# opzioni mescolate è la stessa prova per chi la gioca, e deve restare fuori.
	var mescolata := {"format": "multiple_choice", "prompt": "2+2?", "options": ["5", "4"], "answer": "4"}
	assert(save.has_solved("matematica", mescolata), "la stessa prova mescolata risulta nuova")

	# Idempotente: risegnarla non la duplica.
	save.remember_solved("matematica", [impronta, impronta])
	assert(Array(save.data["solvedExercises"]["matematica"]).size() == 1,
		"impronta duplicata nel salvataggio")

	# Il tetto: la memoria non cresce all'infinito, e a cedere è la più anziana.
	var molte: Array = []
	for i in range(GameSaveManager.SOLVED_MAX + 50):
		molte.append(1000 + i)
	save.remember_solved("italiano", molte)
	var coda: Array = Array(save.data["solvedExercises"]["italiano"])
	assert(coda.size() == GameSaveManager.SOLVED_MAX,
		"tetto delle prove superate non rispettato: %d" % coda.size())
	assert(not coda.has(1000), "al tetto ha ceduto una impronta che non era la piu' anziana")
	assert(coda.has(1000 + GameSaveManager.SOLVED_MAX + 49), "l'ultima impronta non e' entrata")

	# La mappa per materia: è la forma in cui l'esito di una sessione arriva qui.
	save.remember_solved_map({"latino": [7], "musica": [9]})
	assert(save.solved_exercises("latino").has(7) and save.solved_exercises("musica").has(9),
		"remember_solved_map non ha distribuito le impronte")

# --- 2. L'indice resta vivo ---------------------------------------------------

func _indice_vivo() -> void:
	# `ContentManager` tiene l'indice per RIFERIMENTO e non lo richiede mai più.
	# Se una scrittura lo sostituisse invece di aggiornarlo, la selezione
	# continuerebbe a leggere una fotografia vecchia: la prova appena risolta
	# tornerebbe alla sessione successiva, che è esattamente il difetto da chiudere.
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	content.solved_by_subject = save.solved_index()
	save.remember_solved("fisica", [42])
	assert(Dictionary(content.solved_by_subject.get("fisica", {})).has(42),
		"l'indice tenuto dalla selezione non ha visto la prova appena superata")

	# E dopo aver caricato un altro profilo l'indice non deve restare quello di prima.
	var altro := GameSaveManager._default_data()
	altro["solvedExercises"] = {"fisica": [99]}
	save.apply_launch_state({"initialSave": altro})
	assert(not Dictionary(content.solved_by_subject.get("fisica", {})).has(42),
		"l'indice ha conservato le prove di un altro salvataggio")
	assert(Dictionary(content.solved_by_subject.get("fisica", {})).has(99),
		"l'indice non ha adottato le prove del salvataggio caricato")

# --- 3. La selezione non ripropone --------------------------------------------

func _selezione_non_ripete() -> Dictionary:
	var servite := 0
	var ripetute := 0
	var ripetute_senza_memoria := 0
	# Ogni materia nel mondo che la ospita: è lì che la si gioca davvero, con la
	# difficoltà e la lezione che le competono.
	for indice in ApparatusConfig.SUBJECT_CYCLE.size():
		var materia := str(ApparatusConfig.SUBJECT_CYCLE[indice])
		var livello := indice + 1
		var con := _simula(materia, livello, true)
		var senza := _simula(materia, livello, false)
		servite += int(con["servite"])
		ripetute += int(con["ripetute"])
		ripetute_senza_memoria += int(senza["ripetute"])
		assert(int(con["prime_ripetute"]) == 0,
			"%s: %d prove gia' superate riproposte nelle prime %d missioni" % [
				materia, int(con["prime_ripetute"]), MISSIONI_SENZA_RIPETIZIONI])
		assert(int(con["ripetute"]) <= int(senza["ripetute"]),
			"%s: con la memoria le ripetizioni sono aumentate (%d contro %d)" % [
				materia, int(con["ripetute"]), int(senza["ripetute"])])
		# Il ripiego non deve mai accorciare una sessione: meglio una prova rivista
		# che una missione da due campate.
		assert(int(con["servite"]) == MISSIONI_PER_MATERIA * NODI_PER_MISSIONE,
			"%s: la memoria ha accorciato le sessioni (%d nodi su %d)" % [
				materia, int(con["servite"]), MISSIONI_PER_MATERIA * NODI_PER_MISSIONE])
	assert(ripetute < ripetute_senza_memoria,
		"la memoria non ha ridotto nessuna ripetizione (%d contro %d)" % [
			ripetute, ripetute_senza_memoria])
	return {
		"servite": servite, "ripetute": ripetute,
		"ripetute_senza_memoria": ripetute_senza_memoria,
	}

## Gioca `MISSIONI_PER_MATERIA` missioni di fila segnando come superato tutto ciò
## che viene servito. Con `memoria = false` si registra lo stesso ma la selezione
## non guarda: è il metro di paragone, cioè il comportamento di prima.
func _simula(materia: String, livello: int, memoria: bool) -> Dictionary:
	var save := GameSaveManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(materia) + livello
	var servite := 0
	var ripetute := 0
	var prime_ripetute := 0
	for giro in range(MISSIONI_PER_MATERIA):
		# **Un ContentManager nuovo a ogni giro**, e non è un dettaglio dell'audit:
		# è il caso segnalato. Uscire dal mondo e rientrarci ricostruisce tutto, e
		# con esso si azzerano le memorie che vivono nell'istanza
		# (`_recent_node_signatures`, `_recent_math_signatures`). Erano l'unica
		# difesa contro la ripetizione, e non sopravvivevano a un viaggio.
		var content := ContentManager.new()
		if memoria:
			content.solved_by_subject = save.solved_index()
		var sessione := content.build_varied_mission(
			materia, livello, NODI_PER_MISSIONE, {}, rng,
			save.mastery_of(materia), save.topic_masteries(materia))
		var impronte: Array = []
		for nodo_data in Array(sessione.get("nodes", [])):
			var nodo: Dictionary = nodo_data
			servite += 1
			if save.has_solved(materia, nodo):
				ripetute += 1
				if giro < MISSIONI_SENZA_RIPETIZIONI:
					prime_ripetute += 1
			impronte.append(GameSaveManager.solved_fingerprint(nodo))
		save.remember_solved(materia, impronte)
	return {"servite": servite, "ripetute": ripetute, "prime_ripetute": prime_ripetute}

# --- 4. Superata vuol dire risolta pulita -------------------------------------

func _solo_le_prove_pulite() -> void:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260815
	var sessione := content.build_varied_mission("italiano", 4, 3, {}, rng)
	var nodi := Array(sessione.get("nodes", [])).size()

	var bene := Autoplay.play(root, sessione.duplicate(true), true)
	var superate: Dictionary = bene.get("solved", {})
	assert(Array(superate.get("italiano", [])).size() == nodi,
		"una sessione risolta tutta bene ha segnato %d prove su %d" % [
			Array(superate.get("italiano", [])).size(), nodi])

	# Sbagliando non si superano prove: sono proprio quelle che devono tornare.
	var male := Autoplay.play(root, sessione.duplicate(true), false)
	var nessuna: Dictionary = male.get("solved", {})
	assert(Array(nessuna.get("italiano", [])).is_empty(),
		"una sessione sbagliata ha segnato %d prove come superate" % Array(nessuna.get("italiano", [])).size())
	await process_frame

# --- 5. Il ripasso passa sopra ------------------------------------------------

func _il_ripasso_passa_sopra() -> void:
	# Tutto il banco di una materia segnato come superato: la selezione non ha più
	# niente di nuovo da offrire. Un ripasso dovuto deve arrivare lo stesso — un
	# ripasso saltato è un danno più grande di una domanda già vista — e la
	# sessione deve restare piena.
	var save := GameSaveManager.new()
	var content := ContentManager.new()
	content.solved_by_subject = save.solved_index()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var tutte: Array = []
	var argomento := ""
	for item_data in content._load_bank("geografia"):
		var item: Dictionary = item_data
		tutte.append(GameSaveManager.solved_fingerprint(item))
		if argomento == "" and int(item.get("difficulty", 1)) <= 2:
			argomento = str(item.get("topic", ""))
	save.remember_solved("geografia", tutte)
	assert(argomento != "", "banco di geografia senza argomenti: audit non applicabile")

	var dovuto := {"geografia:%s" % argomento: 1}
	var sessione := content.build_mission("geografia", 3, 3, dovuto, rng)
	var nodi := Array(sessione.get("nodes", []))
	assert(nodi.size() == 3, "con il banco esaurito la sessione si e' accorciata a %d nodi" % nodi.size())
	var trovato := false
	for nodo_data in nodi:
		var nodo: Dictionary = nodo_data
		if str(nodo.get("topic", "")) == argomento and bool(nodo.get("review", false)):
			trovato = true
			break
	assert(trovato, "l'argomento dovuto in ripasso e' stato saltato perche' gia' superato")
