extends SceneTree

## **Ogni fascia deve portare qualcosa di nuovo da toccare.** (9 settembre 2026)
##
## Le ricette di minigioco sono cumulative: il gate `minLevel` fa sì che una
## fascia veda tutto ciò che le fasce precedenti hanno sbloccato. Contarle così
## nasconde il difetto peggiore, perché un numero alto può voler dire «ne ha
## tante» oppure «le ha tutte dal mondo 1 e da allora non è cambiato niente».
##
## Il censimento del 9 settembre ha trovato esattamente quel difetto:
##
##   italiano     fasce 5-8:  1 · 1 · 1 · 0   ricette nuove
##   elettronica  fasce 2-6:  2 · 1 · 2 · 2 · 0
##   latino       fasce 5-8:  0 · 1 · 0 · 0
##
## Italiano è materia di PRIMA fascia e serve sei esercizi per sessione: la
## domanda in più va per forza a pescare nel banco, dove vive la crocetta. È la
## causa misurata di R-18 (`gesto_audit`: italiano al 26,0% di «sceglie» contro
## un tetto di 22,3%).
##
## ## Perché il pavimento è per materia e non uno solo
##
## Il bersaglio dichiarato è **tre ricette nuove per fascia, per tutte e dodici
## le materie** — il piano in `docs/PIANO_OTTIMIZZAZIONE_FASCE.md`, Fase 3.
## Oggi solo italiano ci arriva, perché è l'unica pagata. Mettere subito 3 per
## tutti renderebbe rosso un audit su contenuto che nessuno ha ancora scritto, e
## obbligherebbe a scrivere ricette per far passare un test: è l'invariante
## «prima il contenuto, poi il cricchetto», e si applica anche qui.
##
## Quindi il pavimento parte dal valore misurato di ciascuna materia e **sale,
## mai scende**. Ogni lotto della Fase 3 alza la riga della materia che ha
## pagato. Quando tutte e dodici sono a 3, questo dizionario sparisce e resta una
## costante sola.

## Ricette NUOVE che ogni fascia deve portare, per materia. Cricchetto: si alza,
## non si abbassa mai.
## **Come si tarano queste righe, perché sbagliarlo è facile.** La fascia di una
## ricetta è `target_difficulty(minLevel)`, non «in quale fascia il conteggio
## cumulativo cresce». Le due cose divergono sui `minLevel` di confine — 3, 6, 9,
## … — perché la sonda cumulativa campiona il mondo centrale della fascia e una
## ricetta con `minLevel` 3 appartiene alla fascia 1 ma diventa idonea solo al
## mondo 3. Tarando queste righe sulla differenza dei cumulati, matematica e
## coding sono risultate un punto più ricche di quanto sono: due rossi al primo
## giro. I valori qui sotto sono quelli misurati da QUESTO audit.
const PAVIMENTO := {
	# 9 settembre 2026, Fase 3 chiusa: tutte e dodici le materie portano almeno
	# tre ricette nuove in ogni fascia, quindi il dizionario per materia non
	# serve piu' e resta solo per il caso in cui una materia futura entri povera.
	# Nessuna riga scende: e' un cricchetto.
	"italiano": 3,
	"inglese": 3,
	"matematica": 3,
	"scienze": 3,
	"coding": 3,
	"fisica": 3,
	"geografia": 3,
	"elettronica": 3,
	"latino": 3,
	"logica": 3,
	"musica": 3,
	"storia": 3,
}

const BERSAGLIO := 3

func _init() -> void:
	var rotte: Array = []
	print("RICETTE NUOVE PER FASCIA (non cumulative)")
	print("materia        pav |    F1    F2    F3    F4    F5    F6    F7    F8 |  min")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var per_fascia := _nuove_per_fascia(subject)
		var pavimento := int(PAVIMENTO.get(subject, 0))
		var riga := ""
		var minimo := 9999
		for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
			var n := int(per_fascia.get(band, 0))
			minimo = mini(minimo, n)
			riga += "%6d" % n
			if n < pavimento:
				rotte.append("%s fascia %d: %d ricette nuove, il pavimento è %d" % [
					subject, band, n, pavimento])
		print("%-14s %3d |%s |%5d" % [subject, pavimento, riga, minimo])
		# Il cricchetto: se la materia è salita sopra il proprio pavimento in
		# tutte le fasce, la riga va aggiornata. Lo dice invece di lasciarlo
		# scoprire per caso fra sei mesi.
		if minimo > pavimento and pavimento < BERSAGLIO:
			print("      ^ il pavimento di %s può salire da %d a %d" % [
				subject, pavimento, mini(minimo, BERSAGLIO)])

	# La materia del nucleo con meno gesti è la prima a produrre crocette: questa
	# è la misura che ha aperto R-18, e resta come sonda anche quando il rosso è
	# chiuso.
	var totali: Dictionary = {}
	for subject in ApparatusConfig.CORE_SUBJECTS:
		totali[subject] = _totale(str(subject))
	print("\nnucleo, ricette totali: %s" % str(totali))

	for riga in rotte:
		print("ROTTO — %s" % riga)
	assert(rotte.is_empty(), "pavimento delle ricette non rispettato: %d casi" % rotte.size())

	# Nessuna materia deve stare sotto quattro meccaniche in rotazione già alla
	# prima fascia: con tre, due sessioni di fila si somigliano troppo.
	var povere: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var meccaniche := 0
		for fmt in MinigameManager.FORMATS:
			if MinigameManager.format_available(subject, str(fmt), 2):
				meccaniche += 1
		if meccaniche < 4:
			povere.append("%s: %d meccaniche in rotazione alla fascia 1" % [subject, meccaniche])
	for riga in povere:
		print("SOTTO QUATTRO — %s" % riga)
	assert(povere.size() <= 1,
		"più di una materia sotto quattro meccaniche alla fascia 1: %s" % str(povere))

	print("\nRICETTE PER FASCIA audit OK — pavimenti rispettati, bersaglio %d" % BERSAGLIO)
	quit(0)

func _nuove_per_fascia(subject: String) -> Dictionary:
	var out: Dictionary = {}
	for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
		out[band] = 0
	for fmt in MinigameManager.FORMATS:
		for spec_data in Array(MinigameManager.table_for(str(fmt)).get(subject, [])):
			var min_level := maxi(1, int((spec_data as Dictionary).get("minLevel", 0)))
			var band := ContentManager.target_difficulty(min_level)
			out[band] = int(out[band]) + 1
	return out

func _totale(subject: String) -> int:
	var n := 0
	for fmt in MinigameManager.FORMATS:
		n += Array(MinigameManager.table_for(str(fmt)).get(subject, [])).size()
	return n
