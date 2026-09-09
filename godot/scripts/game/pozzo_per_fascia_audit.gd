extends SceneTree

## **Quante sessioni distinte regge ogni fascia, e su quanti argomenti.**
## (9 settembre 2026)
##
## Il passaggio da quattro bande a otto fasce ha dimezzato ogni pozzo, e nessuna
## guardia se n'era accorta. `topic_density_audit` conta gli item per argomento
## sul TOTALE del banco; `difficulty_bands_audit` chiede solo che ogni fascia
## regga *una* sessione — che per una materia di terza fascia e' un esercizio
## solo, quindi passa con un item in tutta la fascia. Il buco stava in mezzo.
##
## Il caso peggiore misurato il 9 settembre, prima della Fase 2: **coding alla
## fascia 1 aveva quindici item e ne consuma cinque per sessione**. Tre sessioni
## e un bambino aveva visto tutto il materiale del suo grado.
##
## ## Le due misure, e perche' servono tutte e due
##
## **1. Il pozzo.** Un item vive in UNA fascia, ma la selezione ne ammette ±1:
## il pozzo reale di una fascia e' la somma di tre. Diviso per gli esercizi che
## la sessione consuma (6, 5 o 1 secondo la fascia di priorita'), da' quante
## sessioni distinte reggono prima che una prova torni.
##
## **2. La larghezza in argomenti.** E' la misura che mancava, ed e' quella che
## ha corretto due volte chi scriveva. Il selettore sceglie **prima l'argomento
## e poi l'item**: un pozzo abbondante con due soli argomenti ripete lo stesso.
## Storia alla fascia 5 era rossa in `variety_audit` con settantanove item nel
## pozzo, perche' `civilta` e `metodo` ci stavano con uno ciascuno.
##
## **Un banco puo' essere ricco e ripetitivo insieme.** La prima misura da sola
## non lo vede.
##
## ## Perche' i pavimenti sono per materia
##
## Come per `ricette_per_fascia_audit` e `fascia_autorata_audit`: il bersaglio
## dichiarato nel piano e' quindici sessioni per tutte, e oggi tutte e dodici ci
## arrivano. I pavimenti restano comunque per materia perche' la larghezza in
## argomenti dipende da quanti argomenti la materia ha — elettronica ne ha otto,
## inglese quarantasette — e una soglia unica sarebbe o inutile o impossibile.
## Si alzano, non si abbassano mai.

## Sessioni distinte minime che ogni fascia deve reggere. Bersaglio del piano.
const SESSIONI_MINIME := 15

## Argomenti distinti minimi raggiungibili dal pozzo di ogni fascia, per materia.
## Cricchetto: si alza, non si abbassa.
const ARGOMENTI_MINIMI := {
	"elettronica": 3,
	"logica": 4,
	"latino": 5,
	"musica": 5,
	"scienze": 5,
	"storia": 5,
	"geografia": 8,
	"fisica": 12,
	"coding": 13,
	"italiano": 20,
	"matematica": 21,
	"inglese": 23,
}

func _init() -> void:
	var content := ContentManager.new()
	var rotte: Array = []
	print("POZZO PER FASCIA — sessioni distinte (pozzo fascia ±1 / esercizi per sessione)")
	print("materia      es |    F1    F2    F3    F4    F5    F6    F7    F8 |  min  argomenti")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var per_fascia := content.bank_difficulty_counts(subject)
		var argomenti := _argomenti_per_fascia(subject)
		var esercizi := maxi(1, ApparatusConfig.exercise_nodes_for(subject))
		var riga := ""
		var minimo := 99999
		var minimo_argomenti := 99999
		for band in range(1, ContentManager.DIFFICULTY_BANDS + 1):
			var pozzo := int(per_fascia.get(band - 1, 0)) + int(per_fascia.get(band, 0)) \
				+ int(per_fascia.get(band + 1, 0))
			var sessioni := int(floor(float(pozzo) / float(esercizi)))
			minimo = mini(minimo, sessioni)
			riga += "%6d" % sessioni
			if sessioni < SESSIONI_MINIME:
				rotte.append("%s fascia %d: %d sessioni distinte (minimo %d) — pozzo di %d item, %d per sessione" % [
					subject, band, sessioni, SESSIONI_MINIME, pozzo, esercizi])

			var larghezza := _larghezza(argomenti, band)
			minimo_argomenti = mini(minimo_argomenti, larghezza)
			var pavimento := int(ARGOMENTI_MINIMI.get(subject, 0))
			if larghezza < pavimento:
				rotte.append("%s fascia %d: il pozzo tocca %d argomenti, il pavimento e' %d — il selettore sceglie prima l'argomento" % [
					subject, band, larghezza, pavimento])
		print("%-12s %3d |%s |%5d %9d" % [subject, esercizi, riga, minimo, minimo_argomenti])
		var pavimento_arg := int(ARGOMENTI_MINIMI.get(subject, 0))
		if minimo_argomenti > pavimento_arg:
			print("      ^ il pavimento di argomenti di %s puo' salire da %d a %d" % [
				subject, pavimento_arg, minimo_argomenti])

	for riga in rotte:
		print("ROTTO — %s" % riga)
	assert(rotte.is_empty(), "pozzo o larghezza sotto il pavimento: %d casi" % rotte.size())

	print("\nPOZZO PER FASCIA audit OK — ogni fascia regge almeno %d sessioni distinte" % SESSIONI_MINIME)
	quit(0)

## Argomenti presenti in ciascuna fascia, letti dal banco. Serve la scomposizione
## per fascia, che `ContentManager.topics_for` non da': quella conta gli argomenti
## del banco intero, ed e' esattamente la misura che non vedeva il difetto.
func _argomenti_per_fascia(subject: String) -> Dictionary:
	var out: Dictionary = {}
	for band in range(0, ContentManager.DIFFICULTY_BANDS + 2):
		out[band] = {}
	for item_data in _bank_items(subject):
		var item := item_data as Dictionary
		var band := clampi(int(item.get("difficulty", 1)), 1, ContentManager.DIFFICULTY_BANDS)
		var topic := str(item.get("topic", ""))
		if topic != "":
			(out[band] as Dictionary)[topic] = true
	return out

## Quanti argomenti distinti il pozzo di questa fascia puo' servire: la finestra
## e' ±1, quindi si uniscono i tre insiemi.
func _larghezza(argomenti: Dictionary, band: int) -> int:
	var uniti: Dictionary = {}
	for vicina in [band - 1, band, band + 1]:
		if not argomenti.has(vicina):
			continue
		for topic in (argomenti[vicina] as Dictionary).keys():
			uniti[topic] = true
	return uniti.size()

func _bank_items(subject: String) -> Array:
	var path := "res://data/banks/%s-base.json" % subject
	if not FileAccess.file_exists(path):
		path = "res://data/banks/%s-tabelline.json" % subject
	if not FileAccess.file_exists(path):
		return []
	var dati = JSON.parse_string(FileAccess.get_file_as_string(path))
	if dati is Dictionary:
		return Array((dati as Dictionary).get("items", []))
	return []
