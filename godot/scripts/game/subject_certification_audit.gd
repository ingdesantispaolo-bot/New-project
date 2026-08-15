extends SceneTree

## **Una materia superata e completata non viene più richiesta.** (15 agosto 2026)
##
## Due difetti misurati, tutti e due sulla stessa idea sbagliata — che una materia
## certificata potesse tornare «da fare» senza che il grado di difficoltà fosse
## cambiato:
##
##  1. **Il decadimento disfaceva l'esame.** Matematica certificata al livello 1
##     con padronanza 0,85; quarantacinque sessioni sulle ALTRE materie — cioè
##     esattamente il lavoro che il gate chiede, non dell'ozio — e la padronanza
##     scendeva a 0,722 sotto la soglia 0,78. La materia tornava nell'elenco di
##     quelle mancanti, con la stanza accesa in bella vista, e bloccava il salto
##     di livello. Il bambino aveva passato l'esame e il gioco glielo richiedeva.
##
##  2. **L'esame si poteva rifare.** `can_repair_apparatus` continuava a dire di
##     sì su una stanza già accesa, e ogni ripetizione pagava altri 80 di energia:
##     la prova appena superata riproposta con il premio più grosso del gioco
##     appeso davanti.
##
## Quello che questo audit NON deve lasciar passare è la correzione fatta troppo
## larga: la certificazione vale **per il livello in cui è stata presa**. Al
## livello dopo, e al secondo passaggio della materia (mondi 13-24), il grado è un
## altro e si ricomincia — è l'intera ragione per cui la scala ha ventiquattro
## mondi e non dodici.

## Sessioni su ALTRE materie dopo la certificazione. Quarantacinque sono la
## misura che faceva scendere matematica da 0,85 a 0,722: sotto soglia, ma sopra
## il pavimento del decadimento, cioè il caso vero e non un estremo costruito.
const SESSIONI_ALTROVE := 45

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_il_decadimento_non_disfa_una_certificazione()
	_l_esame_non_si_ripete()
	_la_certificazione_non_scavalca_il_livello()
	_riparare_richiede_prontezza_vera()
	print("SUBJECT CERTIFICATION audit OK - una materia superata resta superata, ma solo al suo grado")
	quit()

## Prepara un salvataggio con la materia del mondo corrente pronta e certificata.
func _certificata(livello: int) -> Array:
	var save := GameSaveManager.new()
	save.set_level(livello)
	var content := ContentManager.new()
	var prog := ProgressionManager.new(save, content)
	var materia := ApparatusConfig.world_subject(livello)
	save.set_mastery(materia, 0.85)
	save.set_mastery_peak(materia, 0.85)
	save.touch_subject(materia, SpacedRepetition.session_clock(save))
	for topic in content.bank_topics(materia).slice(0, 8):
		save.set_topic_mastery(materia, str(topic), 1.0)
	assert(prog.repair_apparatus(materia, true),
		"la materia non risulta riparabile nemmeno da pronta: audit non applicabile")
	return [save, prog, materia]

# --- 1. Il decadimento non disfa una certificazione ---------------------------

func _il_decadimento_non_disfa_una_certificazione() -> void:
	var pezzi := _certificata(1)
	var save: GameSaveManager = pezzi[0]
	var prog: ProgressionManager = pezzi[1]
	var materia: String = pezzi[2]

	var altre: Array = []
	for s in ApparatusConfig.SUBJECT_CYCLE:
		if str(s) != materia:
			altre.append(str(s))
	for giro in range(SESSIONI_ALTROVE):
		prog.record_mission(str(altre[giro % altre.size()]), 3, 3, 0, true)
		SpacedRepetition.tick(save)

	var dettaglio: Dictionary = Dictionary(prog.readiness().get("subjects", {})).get(materia, {})
	# Il decadimento deve essere AVVENUTO: se un giorno la franchigia cambiasse e
	# la padronanza non scendesse più sotto soglia, questo audit smetterebbe di
	# misurare qualcosa e nessuno se ne accorgerebbe.
	assert(save.mastery_of(materia) < float(dettaglio.get("masteryThreshold", 1.0)),
		"la padronanza non e' scesa sotto soglia (%.3f): l'audit non prova piu' niente" %
		save.mastery_of(materia))
	assert(not Array(prog.readiness().get("missing", [])).has(materia),
		"%s e' tornata fra le materie mancanti dopo essere stata certificata a questo livello" % materia)
	assert(bool(dettaglio.get("certified", false)),
		"la valutazione non dichiara la materia certificata: l'HUD non puo' dirlo")
	assert(Array(dettaglio.get("reasons", [])).is_empty(),
		"una materia certificata elenca ancora motivi mancanti: %s" % str(dettaglio.get("reasons", [])))
	# E la padronanza resta quella VERA: la certificazione non falsifica il numero,
	# decide soltanto che cosa il gate ne fa.
	assert(save.mastery_of(materia) < 0.85,
		"il decadimento e' stato annullato invece che ignorato dal gate")

# --- 2. L'esame non si ripete -------------------------------------------------

func _l_esame_non_si_ripete() -> void:
	var pezzi := _certificata(1)
	var save: GameSaveManager = pezzi[0]
	var prog: ProgressionManager = pezzi[1]
	var materia: String = pezzi[2]
	var energia := save.energy()
	assert(prog.apparatus_certified_now(materia), "la materia non risulta certificata subito dopo l'esame")
	assert(not prog.can_repair_apparatus(materia),
		"l'esame di %s viene ancora offerto dopo essere stato superato" % materia)
	assert(not prog.repair_apparatus(materia, true),
		"l'apparato di %s si e' lasciato riparare due volte" % materia)
	assert(save.energy() == energia,
		"ripetere un esame gia' superato ha pagato altri %d di energia" % (save.energy() - energia))
	# La stanza resta accesa: chiudere la ripetizione non deve spegnere niente.
	assert(prog.is_apparatus_repaired(materia), "la stanza si e' spenta")

# --- 3. La certificazione vale solo per il suo grado --------------------------

func _la_certificazione_non_scavalca_il_livello() -> void:
	var pezzi := _certificata(1)
	var save: GameSaveManager = pezzi[0]
	var prog: ProgressionManager = pezzi[1]
	var materia: String = pezzi[2]

	# Salito di livello, la certificazione del livello 1 non vale più.
	save.set_level(2)
	assert(not prog.apparatus_certified_now(materia),
		"la certificazione presa al livello 1 vale ancora al livello 2")
	assert(not GateReadiness.certified_at_level(save, materia),
		"il gate considera ancora certificata una materia di un livello precedente")

	# Il secondo passaggio della materia (mondo 13 = matematica) è un grado nuovo:
	# l'esame torna disponibile a chi è pronto.
	save.set_level(13)
	assert(ApparatusConfig.world_subject(13) == materia,
		"il mondo 13 non ospita piu' la materia del mondo 1: rivedere l'audit")
	assert(not prog.apparatus_certified_now(materia),
		"al secondo passaggio la materia risulta gia' certificata: la scala non chiede piu' niente")

# --- 4. Riparare richiede prontezza vera --------------------------------------

func _riparare_richiede_prontezza_vera() -> void:
	# La correzione non deve aver aperto una scorciatoia: una materia MAI
	# certificata si ripara solo con le tre dimensioni in ordine.
	var save := GameSaveManager.new()
	var prog := ProgressionManager.new(save, ContentManager.new())
	var materia := ApparatusConfig.world_subject(save.level())
	assert(not prog.apparatus_certified_now(materia), "materia certificata senza aver fatto niente")
	assert(not prog.can_repair_apparatus(materia),
		"l'apparato si ripara con padronanza zero")
	assert(not prog.repair_apparatus(materia, true), "apparato riparato senza prontezza")
	# E la valutazione della RIPARAZIONE non guarda la certificazione: se la
	# guardasse, una stanza accesa si dichiarerebbe riparabile per sempre.
	var pezzi := _certificata(1)
	var save2: GameSaveManager = pezzi[0]
	var prog2: ProgressionManager = pezzi[1]
	var materia2: String = pezzi[2]
	assert(not bool(prog2.apparatus_readiness(materia2).get("certified", false)),
		"apparatus_readiness onora la certificazione: e' la valutazione sbagliata per farlo")
