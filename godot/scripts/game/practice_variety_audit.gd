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
				var prompts: Array = []
				for n in nodi:
					var p := str((n as Dictionary).get("prompt", ""))
					assert(not p.strip_edges().is_empty(),
						"quesito senza testo in %s L%d: la memoria non potrebbe riconoscerlo" % [
							subject, livello])
					# Il cuore: niente di già visto, né in questa sessione né
					# nelle precedenti.
					assert(not visti.has(p),
						"%s L%d, giro %d: quesito già visto — «%s»" % [
							subject, livello, giro + 1, p.substr(0, 60)])
					visti[p] = true
					prompts.append(p)
				save.remember_practice(subject, prompts)
			# Il fondo: si continua a giocare, stavolta ammettendo ripetizioni, e
			# si conta quanti quesiti DIVERSI la casella sa produrre in tutto.
			for _giro in range(GIRI_FONDO - GIRI_PULITI):
				var altri := Array(gameplay._build_practice_session(subject).get("nodes", []))
				var testi: Array = []
				for n in altri:
					var p := str((n as Dictionary).get("prompt", ""))
					visti[p] = true
					testi.append(p)
				save.remember_practice(subject, testi)
			assert(visti.size() >= FONDO_MINIMO,
				"%s L%d offre solo %d quesiti distinti in %d giri: il fondo è tornato sottile" % [
					subject, livello, visti.size(), GIRI_FONDO])
