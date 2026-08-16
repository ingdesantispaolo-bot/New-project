extends SceneTree

## **Una materia portata in linea non ricade fra quelle da fare perché si è
## giocata un'altra materia.** (16 agosto 2026)
##
## Segnalazione di gioco: nel mondo 1, superata la prova di musica, l'elenco
## degli obiettivi tornava a chiedere **elettronica**, che era già stata portata
## in linea. Richiesta del committente: «le materie superate non possono ricadere
## in quelle da fare se si supera l'altra materia».
##
## **La causa non era il decadimento** — quello era già stato rimediato il 15
## agosto, e la padronanza nella misura restava a 0,900. Era la **ritenzione**.
## L'orologio del ripasso spaziato è uno solo per tutta la partita e avanza a
## ogni sessione risolta, di qualunque materia: un argomento di elettronica
## ripassato bene torna dovuto due sessioni dopo, e se quelle due sessioni sono
## di musica, elettronica cade da sola. Con dodici materie da tenere in linea
## insieme, ognuna rimetteva indietro le altre — giocare la cosa giusta disfaceva
## il lavoro appena fatto.
##
## Questo audit tiene ferme le quattro cose che la correzione non deve rompere:
##
##  1. il traguardo regge mentre si gioca un'altra materia;
##  2. i numeri veri restano veri (il ripasso continua a essere dovuto, e il
##     gioco lo dice: coprirlo sarebbe mentire allo studente);
##  3. il traguardo vale **per il suo grado** e scade salendo di livello;
##  4. non regala l'esame a chi non l'ha mai guadagnato.

## Le materie usate: una del nucleo (soglia più alta, copertura più larga) e una
## satellite. Se la regola valesse solo per una delle due famiglie, il difetto
## resterebbe per undici materie su dodici.
const MATERIA_NUCLEO := "matematica"
const MATERIA_SATELLITE := "elettronica"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_il_traguardo_regge_giocando_altrove()
	_i_numeri_veri_restano_veri()
	_il_traguardo_scade_salendo_di_livello()
	_niente_esame_senza_averlo_guadagnato()
	_l_esame_non_si_riapre_dopo_l_esame()
	print("MATERIA IN LINEA audit OK - una materia chiusa non torna da fare per una sessione altrove")
	quit()

## Un salvataggio con `materia` portata in linea a questo livello e il traguardo
## registrato. Ritorna [save, progression].
func _in_linea(materia: String, livello: int) -> Array:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.set_level(livello)
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)
	save.set_mastery(materia, 0.95)
	save.set_mastery_peak(materia, 0.95)
	save.touch_subject(materia, SpacedRepetition.session_clock(save))
	for topic in content.bank_topics(materia).slice(0, 8):
		save.set_topic_mastery(materia, str(topic), 1.0)
	prog.aggiorna_traguardi_di_livello()
	assert(save.subject_cleared_level(materia) == livello,
		"%s non risulta in linea nemmeno da pronta: audit non applicabile" % materia)
	return [save, prog]

## Manda in scadenza un ripasso di `materia` e poi gioca N sessioni di un'ALTRA
## materia. È la sequenza esatta della segnalazione.
func _gioca_altrove(save, prog, materia: String, altra: String, sessioni: int) -> void:
	var topic := str(ContentManager.new().bank_topics(materia)[0])
	SpacedRepetition.apply_outcome(save, materia, [topic], [])
	for _giro in sessioni:
		prog.record_practice(altra, 3, 3, 0)
		SpacedRepetition.tick(save)
		prog.aggiorna_traguardi_di_livello()

# --- 1. Il traguardo regge -----------------------------------------------------

func _il_traguardo_regge_giocando_altrove() -> void:
	for materia in [MATERIA_NUCLEO, MATERIA_SATELLITE]:
		var coppia := _in_linea(str(materia), 1)
		var save = coppia[0]
		var prog = coppia[1]
		var altra := "musica" if str(materia) != "musica" else "storia"
		assert(not Array(prog.readiness().get("missing", [])).has(str(materia)),
			"%s risulta da fare pur essendo in linea" % materia)
		_gioca_altrove(save, prog, str(materia), altra, 4)
		assert(not Array(prog.readiness().get("missing", [])).has(str(materia)),
			"%s è ricaduta fra le materie da fare dopo quattro sessioni di %s" % [materia, altra])
		assert(bool(prog.materia_in_linea(str(materia))),
			"%s non risulta più in linea dopo aver giocato %s" % [materia, altra])
		assert(prog.can_repair_apparatus(str(materia)),
			"la porta dell'esame di %s si è richiusa mentre si giocava %s" % [materia, altra])

# --- 2. I numeri veri restano veri ---------------------------------------------

## La correzione non deve nascondere il ripasso arretrato: la misura grezza resta
## grezza, e serve a NORA per dire che cosa conviene fare adesso. Coprirla
## sarebbe più comodo e sarebbe una bugia — e il ripasso spaziato smetterebbe di
## esistere per chiunque abbia già chiuso la materia.
func _i_numeri_veri_restano_veri() -> void:
	var coppia := _in_linea(MATERIA_SATELLITE, 1)
	var save = coppia[0]
	var prog = coppia[1]
	_gioca_altrove(save, prog, MATERIA_SATELLITE, "musica", 4)
	var grezzo: Dictionary = prog.apparatus_readiness(MATERIA_SATELLITE)
	assert(int(grezzo.get("topicsOverdue", 0)) > 0,
		"l'audit non sta misurando niente: nessun ripasso è diventato dovuto")
	assert(not bool(grezzo.get("ready", false)),
		"apparatus_readiness onora il traguardo: è la valutazione sbagliata per farlo")
	assert(not bool(grezzo.get("certified", false)),
		"la misura grezza non deve dichiararsi certificata")

# --- 3. Il traguardo vale per il suo grado -------------------------------------

func _il_traguardo_scade_salendo_di_livello() -> void:
	var coppia := _in_linea(MATERIA_SATELLITE, 1)
	var save = coppia[0]
	var prog = coppia[1]
	save.set_level(2)
	save.reset_coverage_this_level()
	assert(not bool(prog.materia_in_linea(MATERIA_SATELLITE)),
		"il traguardo del livello 1 vale ancora al livello 2: la scala non sarebbe una scala")
	assert(Array(prog.readiness().get("missing", [])).has(MATERIA_SATELLITE),
		"al grado nuovo la materia non viene richiesta")

# --- 4. Non si regala l'esame ---------------------------------------------------

func _niente_esame_senza_averlo_guadagnato() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.set_level(1)
	var prog := ProgressionManager.new(save, ContentManager.new())
	prog.aggiorna_traguardi_di_livello()
	assert(save.subject_cleared_level(MATERIA_NUCLEO) == 0,
		"traguardo registrato a chi non ha mai giocato")
	assert(not prog.can_repair_apparatus(MATERIA_NUCLEO),
		"l'esame è aperto senza aver raggiunto niente")
	assert(Array(prog.readiness().get("missing", [])).has(MATERIA_NUCLEO),
		"una materia mai toccata non risulta da fare")

# --- 5. La stanza accesa non si riaccende --------------------------------------

## Il rimedio del 15 agosto deve restare in piedi: il traguardo apre la porta
## dell'esame, non la tiene aperta dopo che l'esame è stato superato.
func _l_esame_non_si_riapre_dopo_l_esame() -> void:
	var coppia := _in_linea(MATERIA_NUCLEO, 1)
	var prog = coppia[1]
	assert(prog.repair_apparatus(MATERIA_NUCLEO, true),
		"la materia in linea non riesce a riparare il proprio apparato")
	assert(not prog.can_repair_apparatus(MATERIA_NUCLEO),
		"il traguardo riapre un esame già superato")
