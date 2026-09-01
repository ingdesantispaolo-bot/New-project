extends SceneTree

## PROFONDITÀ COMBINATORIA: quante prove distinte ogni materia sa produrre.
##
## `variety_audit` misura le ripetizioni OSSERVATE in trenta campate: dice se oggi
## va male. Non sa dire quando una materia è finita, perché trenta campate non
## distinguono un insieme da mille combinazioni da uno da un milione.
##
## Questo audit misura la capacità: per ogni (materia, formato) somma le prove
## distinte che le specifiche idonee a quel livello possono generare. È il numero
## che dichiara il traguardo delle Fasi 1–3, e l'unico modo di sapere se una
## materia è a posto senza rigiocarla cinquanta volte.
##
## Il bersaglio dichiarato è **10.000 combinazioni per coppia (materia, formato)**:
## a quel punto cinquanta partite non bastano a esaurire la materia. Ventitré
## coppie su 67 ci arrivano; le altre sono formati a dato fisso, dove una
## specifica vale una prova ed è corretto così.
##
## Vale un CRICCHETTO AL CONTRARIO rispetto a `variety_audit`: là le ripetizioni
## possono solo scendere, qui la profondità può solo **salire**.
## Difende dal difetto silenzioso che nessun altro audit vedrebbe: accorciare un
## insieme (o alzare un `minLevel`) non rompe niente e non fa fallire nulla, ma
## toglie varietà a una materia già consegnata.

const TARGET_DEPTH := 10_000

## Ogni materia viene incontrata ~138 volte per partita. Con meno prove distinte
## di così la PRIMA partita esaurisce il materiale; ×10 di margine copre le
## cinquanta partite chieste. È una soglia di sufficienza, non un bersaglio: le
## materie stanno tutte fra 133.000 e 8 milioni.
const MIN_SUBJECT_DEPTH := 1380
const MAX_INT := 9223372036854775807

## La misura copre l'intera campagna. Campionare soltanto L1 e L13 nascondeva sia
## i livelli senza nuovi sblocchi sia eventuali cali dovuti al cambio di
## generatore/difficoltà. Il cricchetto usa il peggiore dei ventiquattro.
const FIRST_LEVEL := 1
const LAST_LEVEL := 24

## Profondità minima misurata, per materia, sommata sui formati. Non è la
## profondità ACCETTABILE: è quella raggiunta, congelata perché non scenda. Si
## aggiorna solo verso l'alto, e ogni aggiornamento è contenuto consegnato.
##
## Il numero è il PEGGIORE fra tutti i 24 livelli: una materia ricca solo in fondo
## alla campagna è povera dove il bambino comincia. Dal 3 agosto 2026 la misura
## completa sostituisce il vecchio campione L1/L13; questo è l'unico caso in cui
## il pavimento può essere ricalibrato verso il basso senza perdere contenuto.
##
## Storia del piano, in due righe. Il 31 luglio 2026 la prima misura onesta trovò
## undici materie su dodici fra 6 e 124 prove distinte — con ~138 incontri per
## partita, la prima partita esauriva già il materiale. L'unica eccezione era
## l'ordinamento generato di matematica (132.110 prove), che è anche la ragione
## per cui le fasi successive hanno esteso il meccanismo combinatorio a tutto il
## resto invece di autorare a mano. Oggi la più povera è elettronica con 213.551:
## millecinquecento volte il fabbisogno di una partita.
const DEPTH_FLOOR := {
	"italiano": 8074778,
	"geografia": 7791351,
	"inglese": 7785076,
	"coding": 7666570,
	"matematica": 407513,
	"latino": 297163,
	"fisica": 248264,
	"musica": 243781,
	"scienze": 221334,
	"elettronica": 213555,
	"logica": 158454,
	"storia": 133313,
	# Musica sale a 243.781 nella Fase 4: al primo mondo aveva otto abbinamenti
	# possibili in tutto, ed era l'ultima materia sopra la soglia di ripetizione.
	#
	# Logica sale a 158.454 il 1 settembre 2026. Non per un insieme allungato: la
	# materia aveva TRE formati che giravano su una specifica sola — indiziario,
	# tracciatore, bilancia — e insieme valevano l'8,6% dei nodi giocati di un
	# mondo. Tre prove, sempre le stesse, per un dodicesimo dell'esperienza. Ora
	# sono tre ciascuno, e due insiemi di smistamento che non insegnavano logica
	# (animale/pianta, colori/forme/numeri) sono diventati contenuto della materia.
}

func _init() -> void:
	var failures: Array = []
	print("Profondità combinatoria — prove distinte producibili per (materia, formato)")
	print("bersaglio per coppia: %d   ·   cricchetto sul peggiore fra L%d e L%d\n" % [
		TARGET_DEPTH, FIRST_LEVEL, LAST_LEVEL])

	var header := "%-13s" % "MATERIA"
	for fmt in MinigameManager.FORMATS:
		header += "%12s" % _short(str(fmt))
	header += "%14s" % "TOTALE MIN"
	header += "%9s" % "LIVELLO"
	header += "%14s" % "TOTALE L24"
	print(header)

	var reached := 0
	var pairs := 0
	var lowest_by_subject: Dictionary = {}
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var row := "%-13s" % subject
		var totals: Dictionary = {}
		for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
			totals[level] = 0
		for fmt_data in MinigameManager.FORMATS:
			var fmt := str(fmt_data)
			var low := MinigameManager.format_depth(subject, fmt, FIRST_LEVEL)
			for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
				totals[level] = int(totals[level]) + MinigameManager.format_depth(subject, fmt, level)
			var high := MinigameManager.format_depth(subject, fmt, LAST_LEVEL)
			if high > 0:
				pairs += 1
				if high >= TARGET_DEPTH:
					reached += 1
			row += "%12s" % _compact(low if low > 0 else high)
		var floor_value := int(DEPTH_FLOOR.get(subject, 0))
		var worst := MAX_INT
		var worst_level := FIRST_LEVEL
		for level in range(FIRST_LEVEL, LAST_LEVEL + 1):
			var total := int(totals[level])
			if total < worst:
				worst = total
				worst_level = level
		lowest_by_subject[subject] = worst
		# I totali si stampano per intero, non abbreviati: sono i numeri che
		# diventano il pavimento del cricchetto, e un pavimento arrotondato non è
		# un pavimento.
		row += "%14d" % worst
		row += "%9s" % ("L%d" % worst_level)
		row += "%14d" % int(totals[LAST_LEVEL])
		print(row)
		if worst < floor_value:
			failures.append(
				"%s: profondità scesa a %d (pavimento %d) — un insieme è stato accorciato o un minLevel alzato" % [
					subject, worst, floor_value])

	print("\ncoppie (materia, formato) al bersaglio di %d: %d su %d" % [TARGET_DEPTH, reached, pairs])
	print("i formati a dato fisso valgono 1: è corretto, una specifica statica è una prova sola")

	# Soglia di SUFFICIENZA per materia: una materia viene incontrata ~138 volte
	# per partita, quindi con meno di 138 prove distinte la prima partita esaurisce
	# già il materiale. Il margine ×10 copre le cinquanta partite chieste senza
	# pretendere che ogni materia arrivi ai milioni.
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var lowest := int(lowest_by_subject.get(subject, 0))
		if lowest < MIN_SUBJECT_DEPTH:
			failures.append(
				"%s: solo %d prove distinte producibili (minimo %d) — una partita esaurisce il materiale" % [
					subject, lowest, MIN_SUBJECT_DEPTH])

	if not failures.is_empty():
		printerr("PROFONDITÀ IN CALO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Combinatorial depth audit OK — nessuna materia ha perso profondità")
	quit(0)

func _short(fmt: String) -> String:
	match fmt:
		"matching": return "abbina"
		"ordering": return "ordina"
		"classification": return "smista"
		"graph": return "grafico"
		"circuit": return "circuito"
		"cycle": return "ciclo"
		"code_debug": return "errore"
	return fmt

## I numeri veri sono più utili delle potenze, finché stanno in colonna.
func _compact(value: int) -> String:
	if value >= 1_000_000:
		return "%.1fM" % (float(value) / 1_000_000.0)
	if value >= 10_000:
		return "%.1fk" % (float(value) / 1_000.0)
	return str(value)
