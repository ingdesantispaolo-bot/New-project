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

## Livelli campione: il primo mondo (dove `minLevel` lascia meno materiale) e uno
## alto (dove è tutto sbloccato). La povertà dei livelli bassi è invisibile se si
## misura solo a fine campagna.
const SAMPLE_LEVELS := [1, 13]

## Profondità minima misurata, per materia, sommata sui formati. Non è la
## profondità ACCETTABILE: è quella raggiunta, congelata perché non scenda. Si
## aggiorna solo verso l'alto, e ogni aggiornamento è contenuto consegnato.
##
## Il numero è il PEGGIORE fra i livelli campione: una materia ricca solo in fondo
## alla campagna è povera dove il bambino comincia.
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
	"coding": 7666565,
	"matematica": 407510,
	"latino": 297163,
	"fisica": 248258,
	"musica": 243781,
	"scienze": 221329,
	"elettronica": 213551,
	"logica": 133892,
	"storia": 133313,
	# Musica sale a 243.781 nella Fase 4: al primo mondo aveva otto abbinamenti
	# possibili in tutto, ed era l'ultima materia sopra la soglia di ripetizione.
}

func _init() -> void:
	var failures: Array = []
	print("Profondità combinatoria — prove distinte producibili per (materia, formato)")
	print("bersaglio per coppia: %d   ·   L%d = primo mondo, L%d = mondo alto\n" % [
		TARGET_DEPTH, int(SAMPLE_LEVELS[0]), int(SAMPLE_LEVELS[1])])

	var header := "%-13s" % "MATERIA"
	for fmt in MinigameManager.FORMATS:
		header += "%12s" % _short(str(fmt))
	header += "%14s" % "TOTALE L1"
	header += "%14s" % "TOTALE L13"
	print(header)

	var reached := 0
	var pairs := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var row := "%-13s" % subject
		var totals: Dictionary = {}
		for level_data in SAMPLE_LEVELS:
			totals[int(level_data)] = 0
		for fmt_data in MinigameManager.FORMATS:
			var fmt := str(fmt_data)
			var low := MinigameManager.format_depth(subject, fmt, int(SAMPLE_LEVELS[0]))
			for level_data in SAMPLE_LEVELS:
				var level := int(level_data)
				totals[level] = int(totals[level]) + MinigameManager.format_depth(subject, fmt, level)
			var high := MinigameManager.format_depth(subject, fmt, int(SAMPLE_LEVELS[1]))
			if high > 0:
				pairs += 1
				if high >= TARGET_DEPTH:
					reached += 1
			row += "%12s" % _compact(low if low > 0 else high)
		var floor_value := int(DEPTH_FLOOR.get(subject, 0))
		var worst := mini(int(totals[int(SAMPLE_LEVELS[0])]), int(totals[int(SAMPLE_LEVELS[1])]))
		# I totali si stampano per intero, non abbreviati: sono i numeri che
		# diventano il pavimento del cricchetto, e un pavimento arrotondato non è
		# un pavimento.
		for level_data in SAMPLE_LEVELS:
			row += "%14d" % int(totals[int(level_data)])
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
		var lowest := MAX_INT
		for level_data in SAMPLE_LEVELS:
			var total := 0
			for fmt_data in MinigameManager.FORMATS:
				total += MinigameManager.format_depth(subject, str(fmt_data), int(level_data))
			lowest = mini(lowest, total)
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
		"code_debug": return "errore"
	return fmt

## I numeri veri sono più utili delle potenze, finché stanno in colonna.
func _compact(value: int) -> String:
	if value >= 1_000_000:
		return "%.1fM" % (float(value) / 1_000_000.0)
	if value >= 10_000:
		return "%.1fk" % (float(value) / 1_000.0)
	return str(value)
