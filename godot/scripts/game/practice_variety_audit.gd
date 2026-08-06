extends SceneTree

## **La pratica non ripete gli stessi quesiti.** (6 agosto 2026)
##
## Segnalazione di gioco: «lo studente supera le prove di una location, è tentato
## di rifare la stessa location, e ritrova gli stessi quesiti identici». Non era
## un'impressione. Misurato prima di toccare niente, rigiocando dieci volte:
##
##   pratica (minigiochi)   **55% di quesiti identici**, fino all'83% in geografia L1
##   missioni (banchi)      13% — normale sovrapposizione d'estrazione
##
## E la causa non era il caso: entrambi i costruttori estraggono davvero a sorte.
## Era il **fondo**. Il repertorio dei minigiochi per geografia e storia al
## livello 1 conteneva cinque quesiti distinti in tutto, e una sessione ne
## consuma quattro o cinque: la seconda volta non poteva che essere la prima.
##
## Tre riparazioni, e questo audit tiene la terza:
##   1. una palestra SUPERATA si chiude e sparisce dalla mappa (minigame_audit);
##   2. la successiva nasce altrove, con identificativo nuovo (director);
##   3. **i quesiti già visti non tornano**, perché il salvataggio se li ricorda
##      e la composizione attinge ai banchi quando il catalogo si esaurisce.
##
## Misurato dopo: 55% → 20% su dieci giri, e **almeno sette giri consecutivi
## interamente nuovi** in ogni casella. La soglia qui sotto è cinque: sotto il
## misurato, per non diventare rossa a ogni oscillazione, sopra il vissuto
## realistico — una materia ha una palestra per mondo, non sette.

## Giri consecutivi che devono restare interamente nuovi.
const GIRI_PULITI := 5

## Quesiti distinti che una casella deve poter offrire in DODICI giri, cioè con
## margine oltre i cinque puliti. Prima della riparazione la casella peggiore ne
## aveva cinque in tutto; dopo, il misurato sta fra 27 e 33.
##
## Va verificato oltre i giri puliti, non dentro: cinque giri da quattro nodi
## fanno venti quesiti comunque vada, quindi contarli lì non direbbe niente sul
## fondo — direbbe solo che so moltiplicare.
const GIRI_FONDO := 12
const FONDO_MINIMO := 25

## Quota di quesiti INEDITI che deve trovare chi rigioca un mondo già fatto.
##
## Misurata il 6 agosto 2026 su una campagna simulata due volte: era il **13%**
## nel mondo 1 — chi ricominciava rivedeva quasi tutto, proprio nel mondo che
## incontra per primo. La causa: la pratica pescava dal catalogo interattivo
## (5-16 quesiti per casella al livello 1) avendo accanto i banchi (53-508).
## Mettendo un tetto alla quota di catalogo è salita al 50% nel mondo 1 e al 59%
## sull'intera campagna. La soglia qui è 35: sotto il misurato, sopra il
## «rivedo sempre le stesse cose» che l'ha fatta nascere.
const INEDITI_MINIMI := 0.35

func _init() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var gameplay := OutdoorGameplay.new()
	get_root().add_child(gameplay)
	gameplay.setup(NativeWorldState.default_request("audit"), {}, false)
	gameplay.game_save = save
	gameplay.content_manager = ContentManager.new()

	_prova_memoria(save)
	_prova_varieta(gameplay, save)
	_prova_rigiocata(gameplay, save)
	gameplay.queue_free()
	print("PRACTICE VARIETY audit OK — %d giri consecutivi senza ripetizioni, fondo >= %d" % [
		GIRI_PULITI, FONDO_MINIMO])
	quit(0)

## La memoria è limitata e ordinata: un esercizio rivisto ora torna in fondo alla
## coda, non resta dov'era. Senza, «visto una volta tre sessioni fa» e «visto
## adesso» peserebbero uguale e la coda scaderebbe nell'ordine sbagliato.
func _prova_memoria(save: GameSaveManager) -> void:
	save.data["recentPractice"] = {}
	assert(save.recent_practice("matematica").is_empty(), "la memoria non parte vuota")

	save.remember_practice("matematica", ["Quanto fa 2+2?", "  QUANTO FA 2+2?  "])
	var memoria := save.recent_practice("matematica")
	assert(memoria.size() == 1,
		"lo stesso quesito, scritto con spazi e maiuscole diverse, conta due volte")

	# Non deborda, e non tocca le altre materie.
	var molti: Array = []
	for i in range(GameSaveManager.RECENT_PRACTICE_MAX * 3):
		molti.append("domanda numero %d" % i)
	save.remember_practice("matematica", molti)
	assert(save.recent_practice("matematica").size() == GameSaveManager.RECENT_PRACTICE_MAX,
		"la memoria è cresciuta oltre il limite: %d" % save.recent_practice("matematica").size())
	assert(save.recent_practice("italiano").is_empty(), "la memoria di una materia ha invaso un'altra")
	# La più vecchia è uscita, le ultime ci sono ancora.
	assert(not save.recent_practice("matematica").has(
		GameSaveManager.practice_fingerprint("domanda numero 0")),
		"la memoria ha scartato le voci recenti invece delle vecchie")
	assert(save.recent_practice("matematica").has(
		GameSaveManager.practice_fingerprint("domanda numero %d" % (molti.size() - 1))),
		"l'ultimo quesito visto non è nella memoria")

func _prova_varieta(gameplay: OutdoorGameplay, save: GameSaveManager) -> void:
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for livello in [1, 3, 8]:
			save.data["recentPractice"] = {}
			save.data["level"] = livello
			var visti: Dictionary = {}
			for giro in range(GIRI_PULITI):
				var nodi := Array(gameplay._build_practice_session(subject).get("nodes", []))
				assert(not nodi.is_empty(),
					"pratica vuota per %s L%d: sarebbe un vicolo cieco" % [subject, livello])
				var impronte: Array = []
				for n in nodi:
					var nodo: Dictionary = n
					assert(not str(nodo.get("prompt", "")).strip_edges().is_empty(),
						"quesito senza testo in %s L%d" % [subject, livello])
					# L'identità è il CONTENUTO, non il testo: nei formati
					# interattivi il testo è una costante, e misurare con quello
					# faceva sembrare uguali due abbinamenti diversissimi.
					var impronta := GameSaveManager.practice_node_fingerprint(nodo)
					assert(not visti.has(impronta),
						"%s L%d, giro %d: quesito già visto — «%s»" % [
							subject, livello, giro + 1,
							str(nodo.get("prompt", "")).substr(0, 50)])
					visti[impronta] = true
					impronte.append(impronta)
				save.remember_practice_prints(subject, impronte)
			# Il fondo: si continua a giocare, stavolta ammettendo ripetizioni, e
			# si conta quanti quesiti DIVERSI la casella sa produrre in tutto.
			for _giro in range(GIRI_FONDO - GIRI_PULITI):
				var altri := Array(gameplay._build_practice_session(subject).get("nodes", []))
				var altre_impronte: Array = []
				for n in altri:
					var f := GameSaveManager.practice_node_fingerprint(n as Dictionary)
					visti[f] = true
					altre_impronte.append(f)
				save.remember_practice_prints(subject, altre_impronte)
			assert(visti.size() >= FONDO_MINIMO,
				"%s L%d offre solo %d quesiti distinti in %d giri: il fondo è tornato sottile" % [
					subject, livello, visti.size(), GIRI_FONDO])


## Chi rigioca deve trovare roba nuova.
##
## Due passaggi sullo stesso livello con salvataggi diversi — cioè il caso
## peggiore, quello in cui la memoria del già visto non aiuta perché è vuota. Se
## regge questo, regge anche la rivisitazione con la memoria piena.
func _prova_rigiocata(gameplay: OutdoorGameplay, save: GameSaveManager) -> void:
	var primo: Dictionary = {}
	for livello in [1, 2]:
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			save.data["recentPractice"] = {}
			save.data["level"] = livello
			for _giro in range(3):
				var impronte: Array = []
				for n in Array(gameplay._build_practice_session(subject).get("nodes", [])):
					var f := GameSaveManager.practice_node_fingerprint(n as Dictionary)
					primo["%s|%d|%d" % [subject, livello, f]] = true
					impronte.append(f)
				save.remember_practice_prints(subject, impronte)

	# Secondo viaggio: salvataggio pulito, come un bambino che ricomincia.
	var totale := 0
	var inediti := 0
	for livello in [1, 2]:
		for subject_data in ApparatusConfig.SUBJECT_CYCLE:
			var subject := str(subject_data)
			save.data["recentPractice"] = {}
			save.data["level"] = livello
			for _giro in range(3):
				var impronte: Array = []
				for n in Array(gameplay._build_practice_session(subject).get("nodes", [])):
					var f := GameSaveManager.practice_node_fingerprint(n as Dictionary)
					totale += 1
					if not primo.has("%s|%d|%d" % [subject, livello, f]):
						inediti += 1
					impronte.append(f)
				save.remember_practice_prints(subject, impronte)

	var quota := float(inediti) / maxf(1.0, float(totale))
	assert(quota >= INEDITI_MINIMI,
		"chi rigioca trova solo il %.0f%% di esercizi inediti (minimo %.0f%%): il fondo si e ristretto" % [
			quota * 100.0, INEDITI_MINIMI * 100.0])
