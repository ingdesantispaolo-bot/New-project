class_name GateReadiness
extends RefCounted

## Readiness a TRE dimensioni, per materia. Il gate del livello le richiede tutte
## e tre su ciascuna delle materie del NUCLEO (italiano, matematica, inglese); la
## riparazione di un apparato le richiede sulla propria materia.
##
##   1. ACCURATEZZA  — la padronanza (media mobile) raggiunge la soglia.
##   2. COPERTURA    — sono stati incontrati abbastanza argomenti distinti della
##                     materia (non basta ripetere sempre lo stesso topic facile).
##   3. RITENZIONE   — nessun argomento della materia è arretrato nel ripasso
##                     spaziato: ciò che era stato sbagliato è stato ripreso.
##
## La quarta dimensione — CONFIDENZA, cioè "N missioni superate" — è stata
## **rimossa** il 30 luglio per decisione dell'utente: si sale quando la competenza
## c'è, non quando si sono fatti abbastanza giri.
##
## Copertura e ritenzione non sono un contorno: **senza il conteggio sono loro a
## impedire che una serie fortunata apra il gate.** E chi fatica non resta
## bloccato, perché la difficoltà adattiva abbassa gli item finché l'accuratezza
## risale — lo sforzo porta comunque da qualche parte.
##
## `total_topics` è il numero di argomenti che la materia PUÒ proporre (dal banco).
## Se ignoto (≤ 0), la copertura ripiega su un minimo assoluto di argomenti visti,
## così il gate resta significativo anche senza il catalogo dei topic.

# Frazione di argomenti distinti da incontrare, con un tetto basso: bastano pochi
# argomenti distinti, non metà del banco (a bassa difficoltà pochi sono
# raggiungibili). MIN_TOPICS_UNKNOWN è il minimo quando il totale è ignoto.
const COVERAGE_FRACTION := 0.34
## La frazione di materia richiesta all'ultimo livello. Non è 1.0: pretendere
## ogni singolo argomento renderebbe il gate ostaggio dell'argomento più raro.
const COVERAGE_FRACTION_MAX := 0.80
## Quanti argomenti al massimo si chiedono PER LIVELLO. Quattro sono raggiungibili
## in ogni materia a ogni livello, e moltiplicati per dodici materie fanno il
## lavoro vero: è il prodotto che rende serio il gate, non il singolo numero.
const COVERAGE_PER_LEVEL_CAP := 5
const COVERAGE_CAP := 3   # storico, non più usato dal calcolo
const MIN_TOPICS_UNKNOWN := 2

# Quanti argomenti distinti servono per la copertura della materia. Il tetto basso
# evita il deadlock: chiediamo "hai toccato più di un argomento facile", non "hai
# coperto metà del banco" (impossibile finché la difficoltà del livello è bassa).
## Quanti argomenti bisogna aver toccato in una materia perché conti come
## coperta, **a questo livello**.
##
## Fino al 5 agosto 2026 era una frazione con un tetto fisso di tre: matematica
## (8 argomenti) e italiano (21) chiedevano entrambe tre argomenti, al mondo 1
## come al mondo 24. La conseguenza si è vista misurando: una volta superata la
## soglia al primo livello, tutti i ventitré successivi si aprivano **senza
## lavoro aggiuntivo** — la padronanza non decade e la copertura non cresceva.
## L'intera campagna costava quanto il primo mondo.
##
## Ora la copertura sale col livello: al primo si chiede poco più di un assaggio,
## all'ultimo quasi tutta la materia. È questo che rende vero «padroneggiare le
## materie a quel grado di difficoltà»: ogni mondo chiede una fetta più larga di
## programma, in tutte e dodici.
## `core` allarga la copertura di un argomento: le tre materie del nucleo
## chiedono una fetta di programma più larga a ogni livello. Uno solo, non due:
## la copertura si conta PER LIVELLO e un livello propone una fetta limitata del
## banco — chiederne troppi renderebbe il gate impossibile invece che severo,
## errore già commesso e misurato su italiano al livello 2.
static func coverage_target(total_topics: int, level: int = 1, core: bool = false) -> int:
	var extra := 1 if core else 0
	if total_topics <= 0:
		return MIN_TOPICS_UNKNOWN + extra
	# Il primo mondo chiede un argomento per materia: dodici materie da zero
	# sono già il lavoro più grosso della campagna, e aggiungere ampiezza lì
	# significa solo allontanare il momento in cui il bambino vede il mondo 2.
	if level <= 1:
		return mini(1 + extra, total_topics)
	var passo := clampf(float(clampi(level, 1, 24) - 1) / 23.0, 0.0, 1.0)
	var frazione := lerpf(COVERAGE_FRACTION, COVERAGE_FRACTION_MAX, passo)
	var richiesti := int(ceil(frazione * float(total_topics)))
	# Tetto per livello, e non è una rinuncia: la copertura si conta ORA — gli
	# argomenti toccati da quando il livello è cominciato — e un livello propone
	# solo una fetta del banco. Senza tetto il gate chiedeva otto argomenti dove
	# la selezione ne offriva quattro: non difficile, **impossibile**.
	# Misurato su italiano al livello 2 prima di questo limite.
	return clampi(richiesti + extra, 1, mini(COVERAGE_PER_LEVEL_CAP + extra, total_topics))

# Valuta la prontezza. Ritorna ogni dimensione (bool + dettaglio numerico), la
# lista dei motivi non soddisfatti e il verdetto complessivo `ready`.
## **Una materia già certificata a questo livello.** (15 agosto 2026)
##
## Vero quando la stanza di quella materia è stata accesa **a questo grado**: cioè
## l'esame è stato superato al livello corrente e da allora il livello non è
## salito. Non basta «l'apparato è acceso»: al secondo passaggio della materia
## (mondi 13-24) il grado è un altro e la certificazione va rifatta — è il senso
## dell'intera scala.
static func certified_at_level(save, subject: String) -> bool:
	var quando := int(save.apparatus_repaired_level(ApparatusConfig.apparatus_of(subject)))
	return quando > 0 and quando >= int(save.level())

## **Una materia superata a questo grado non torna fra quelle da fare.**
## (16 agosto 2026)
##
## Segnalazione di gioco: nel mondo 1, superata la prova di musica, l'elenco
## tornava a chiedere **elettronica**, che era gia' stata portata in linea.
##
## Misurato: non era il decadimento — la padronanza restava a 0,900 — era la
## RITENZIONE. L'orologio del ripasso spaziato e' **uno solo per tutta la
## partita** e avanza a ogni sessione risolta, di qualunque materia. Un argomento
## di elettronica ripassato bene torna dovuto due sessioni dopo; se quelle due
## sessioni sono di musica, elettronica cade da sola. Con dodici materie da
## tenere in linea insieme, ognuna rimetteva indietro le altre: giocare la cosa
## giusta disfaceva il lavoro appena fatto, ed e' il modo piu' rapido di
## convincere un bambino che il gioco non tiene il conto.
##
## Il rimedio ricalca quello gia' scelto il 15 agosto per la certificazione
## d'apparato: **il traguardo si registra, e vale per questo grado**. Sotto non
## cambia niente — il ripasso continua a riproporre gli argomenti dovuti, la
## padronanza continua a calare e i numeri lo dicono. Quello che non succede piu'
## e' che una materia gia' chiusa torni nella lista delle cose da fare per colpa
## di una sessione altrove. Al livello successivo il grado e' nuovo e si
## ricomincia: e' il senso della scala.
##
## Due sorgenti, un solo significato: l'esame d'apparato superato qui, oppure le
## tre condizioni raggiunte qui (`ProgressionManager.aggiorna_traguardi_di_livello`).
static func in_linea_a_questo_livello(save, subject: String) -> bool:
	if certified_at_level(save, subject):
		return true
	var quando := int(save.subject_cleared_level(subject))
	return quando > 0 and quando >= int(save.level())

## `certified` = la materia è già stata superata a questo livello (vedi
## `in_linea_a_questo_livello`: esame d'apparato passato qui, oppure tre
## condizioni centrate qui). Quando è vero il verdetto è «pronta» senza guardare
## le tre dimensioni. **Il parametro è esplicito e di default falso apposta**: chi
## valuta se un apparato si può RIPARARE non deve passarlo, o una stanza accesa
## si dichiarerebbe riparabile all'infinito.
static func evaluate_subject(
	save, subject: String, mastery_threshold: float, total_topics: int = -1,
	certified: bool = false
) -> Dictionary:
	# L'asticella del NUCLEO sta più in alto. Il bonus si applica QUI, dove passa
	# ogni valutazione di materia, invece che nei chiamanti: così l'HUD, il
	# portale, il report e gli audit leggono tutti la stessa soglia senza doverla
	# ricalcolare, ed è impossibile che due punti del gioco dissentano su quanto
	# serve per essere pronti.
	var soglia := mastery_threshold
	var nucleo := ApparatusConfig.is_core(subject)
	if nucleo:
		soglia = minf(
			soglia + ApparatusConfig.core_bonus(int(save.level())), ApparatusConfig.MASTERY_CEILING)
	var mastery := float(save.mastery_of(subject))
	# Copertura DI QUESTO LIVELLO, non cumulativa: si contano gli argomenti
	# visti da quando il livello è cominciato. Prima era il totale di sempre, e
	# la conseguenza misurata era che dopo il primo mondo il gate non chiedeva
	# più niente — 24 livelli al prezzo di uno.
	var seen := int(save.topics_seen_this_level(subject))
	var target := coverage_target(total_topics, int(save.level()), nucleo)
	var overdue := int(SpacedRepetition.subject_overdue_count(save, subject))
	# **Ripreso, non consolidato.** (26 agosto 2026) La ritenzione chiede che cio'
	# che e' stato sbagliato sia stato ripreso — e non che il calendario dei
	# ripassi sia vuoto in questo istante, che e' un bersaglio che si sposta e che
	# teneva chiuso il gate del mondo 1 all'infinito. Vedi
	# `SpacedRepetition.da_riprendere_count` e `gate_mondo1_audit`.
	var da_riprendere := int(SpacedRepetition.da_riprendere_count(save, subject))

	var accuracy_ok := mastery >= soglia
	var coverage_ok := seen >= target
	var retention_ok := da_riprendere == 0

	var reasons: Array = []
	if not accuracy_ok:
		reasons.append("accuratezza")
	if not coverage_ok:
		reasons.append("copertura")
	if not retention_ok:
		reasons.append("ritenzione")

	# **Una materia superata a questo livello è superata, e basta.**
	#
	# Due difetti diversi rimediati dalla stessa riga. Il decadimento (15 agosto
	# 2026) e la ritenzione (16 agosto 2026, vedi `in_linea_a_questo_livello`):
	# il primo lento, la seconda immediata, entrambi capaci di disfare una prova
	# già passata senza che lo studente sbagliasse niente.
	#
	# Senza questa riga il decadimento per trascuratezza disfaceva una prova già
	# passata: misurato il 15 agosto 2026 — matematica certificata al livello 1
	# con padronanza 0,85, quarantacinque sessioni sulle ALTRE materie (che è
	# esattamente ciò che il gate chiede di fare, non un ozio), padronanza scesa a
	# 0,722 sotto la soglia 0,78, e la materia tornava nell'elenco di quelle
	# mancanti con la stanza accesa in bella vista. Il bambino aveva superato
	# l'esame e il gioco glielo richiedeva.
	#
	# Il decadimento resta: la padronanza cala davvero e il numero lo dice. Quello
	# che non deve più succedere è che cancelli una CERTIFICAZIONE. La distinzione
	# è la stessa fra sapere e aver dimostrato di sapere — e vale per questo
	# livello soltanto: al successivo il grado cambia e si ricomincia.
	if certified:
		reasons = []
	return {
		"subject": subject,
		"ready": certified or (accuracy_ok and coverage_ok and retention_ok),
		"reasons": reasons,
		# Perché la presentazione possa dire «già superata» invece di disegnare
		# una barra piena che non corrisponde ai numeri qui sotto.
		"certified": certified,
		"accuracy": accuracy_ok,
		"coverage": coverage_ok,
		"retention": retention_ok,
		# Dettagli per HUD/report (letti, non ricalcolati, dalla presentazione).
		"mastery": mastery,
		# La soglia EFFETTIVA di questa materia, non quella di base: chi la
		# mostra al bambino deve dire il numero vero.
		"masteryThreshold": soglia,
		"core": nucleo,
		# Quanto manca, già normalizzato 0..1: chi disegna non deve dividere a mano.
		"progress": clampf(mastery / maxf(soglia, 0.01), 0.0, 1.0),
		"topicsSeen": seen,
		"topicsTarget": target,
		# Quanti ripassi il calendario propone adesso: e' il numero che serve a
		# chi presenta «hai dei ripassi da fare», e non e' quello che gata.
		"topicsOverdue": overdue,
		# Quanti argomenti sbagliati aspettano ancora di essere ripresi: e' questo
		# che tiene chiusa la dimensione ritenzione.
		"topicsDaRiprendere": da_riprendere,
	}

## Prontezza del LIVELLO: tutte e tre le dimensioni su ciascuna delle materie del
## nucleo. `topics_by_subject` porta il numero di argomenti che ogni materia può
## proporre (per la copertura); se manca, la copertura ripiega sul minimo assoluto.
## Le materie che aprono il LIVELLO. Erano le tre strumentali; dal 5 agosto 2026
## sono tutte, perché il livello dichiara di certificare quel grado di
## difficoltà — e certificarlo su un quarto del programma non lo certifica.
const GATE_SUBJECTS := ApparatusConfig.SUBJECT_CYCLE

static func evaluate_core(
	save, mastery_threshold: float, topics_by_subject: Dictionary = {}, required_subjects: Array = GATE_SUBJECTS
) -> Dictionary:
	var subjects: Dictionary = {}
	var missing: Array = []
	var ready := true
	var total_progress := 0.0
	# **Tutte e dodici, non più tre.** (5 agosto 2026, decisione del committente
	# dopo un collaudo vero.)
	#
	# Il gate chiedeva italiano, matematica e inglese. Con quello un bambino
	# saliva di livello in 18 esercizi su 3 argomenti — circa dieci minuti — e le
	# altre nove materie poteva non toccarle mai: gli eventi di pratica c'erano,
	# ma erano facoltativi e il gioco non li chiedeva. La strada più corta
	# premiava chi non praticava.
	#
	# Ora il livello si apre solo padroneggiando **tutte le materie a quel
	# livello di difficoltà**. La pratica smette di essere un extra e diventa la
	# strada: è l'unico modo di alzare le materie che il mondo non ospita.
	#
	# Costo misurato (`effort_probe`): 180 esercizi contro 18, circa un'ora per
	# mondo rispondendo sempre giusto.
	for subject in required_subjects:
		var s := str(subject)
		# Il gate del LIVELLO onora il traguardo gia' raggiunto a questo grado —
		# esame d'apparato superato QUI, oppure tre condizioni centrate QUI. La
		# riparazione di un apparato (`evaluate_subject` chiamato senza
		# `certified`) no: quella deve sempre guardare i numeri veri, o una stanza
		# accesa si dichiarerebbe riparabile all'infinito.
		var evaluation := evaluate_subject(
			save, s, mastery_threshold, int(topics_by_subject.get(s, -1)),
			in_linea_a_questo_livello(save, s))
		subjects[s] = evaluation
		total_progress += float(evaluation["progress"])
		if not bool(evaluation["ready"]):
			ready = false
			missing.append(s)
	return {
		"ready": ready,
		"coreSubjects": required_subjects.duplicate(),
		"subjects": subjects,
		"missing": missing,
		"masteryThreshold": mastery_threshold,
		# Media dei tre avanzamenti: una sola barra riassuntiva per l'HUD compatto,
		# accanto alle tre di dettaglio.
		"progress": total_progress / float(maxi(1, required_subjects.size())),
	}
