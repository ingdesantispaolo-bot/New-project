extends SceneTree

## **Ogni item ha una spiegazione, e nessuna spiegazione vale per tutti.**
## (5 agosto 2026)
##
## Il difetto curato: nel banco di inglese **968 spiegazioni su 1109** erano la
## ripetizione della risposta appena data — alla domanda «come si dice
## *controllare*?» la spiegazione era «*check*: controllare». Il bambino
## rileggeva quello che aveva appena scritto.
##
## ### Perché questo audit NON misura la lunghezza
##
## Il piano diceva di respingere le spiegazioni «sotto una soglia di lunghezza».
## Scrivendolo ho misurato, e la soglia era la metrica sbagliata: fra le 143
## spiegazioni sotto i 40 caratteri **la maggioranza era ottima** — «Pro-nome: al
## posto del nome», «*Riso* è un cereale e anche una risata», «Sorge sulla
## Senna». Corte perché precise. Allungarle le avrebbe peggiorate.
##
## Le vere tautologie erano 31, e si trovano guardando **che cosa resta** della
## spiegazione tolte le parole della domanda e della risposta. Anche così restano
## dei falsi positivi — «La serie alterna +2 e +3: 9 + 3 = 12» contiene la
## risposta ed è esattamente la spiegazione giusta — quindi il residuo qui è una
## soglia prudente: prende solo i casi in cui non resta davvero niente.
##
## ### Il controllo che vale
##
## Il tetto sulle ripetizioni. Una spiegazione usata da mezzo banco non spiega
## quel banco: descrive il formato. È la stessa malattia dei minigiochi, dove una
## stringa sola copriva il 22% del giocato. Il tetto è alto di proposito, perché
## qualche ripetizione è legittima: le etichette dei casi latini («genitivo
## (specificazione), plurale») valgono per parole diverse con la stessa analisi.

## Nessuna spiegazione può coprire più di tanti item. Oggi il massimo reale è 13
## (i casi latini); il tetto lascia margine e scatterebbe subito su una stringa
## generica applicata a un intero formato o a un'intera materia.
const MAX_RIPETIZIONI := 20

## Quanto deve restare della spiegazione tolte le parole di domanda e risposta.
## Prudente: sotto questa soglia non è rimasto nulla di nuovo.
const MIN_RESIDUO := 8

func _init() -> void:
	var failures: Array = []
	var cm := ContentManager.new()
	var usi: Dictionary = {}      # spiegazione -> quante volte
	var esempio: Dictionary = {}  # spiegazione -> primo id che la usa
	var totale := 0

	print("%-14s %6s %8s %10s" % ["MATERIA", "item", "vuote", "circolari"])
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var items: Array = cm._load_bank(subject)
		var vuote := 0
		var circolari := 0
		for entry in items:
			var item := entry as Dictionary
			totale += 1
			var testo := str(item.get("explanation", "")).strip_edges()
			var id := str(item.get("id", "?"))

			if testo == "":
				vuote += 1
				failures.append("%s: nessuna spiegazione" % id)
				continue
			usi[testo] = int(usi.get(testo, 0)) + 1
			if not esempio.has(testo):
				esempio[testo] = id
			if _residuo(testo, str(item.get("prompt", "")), str(item.get("answer", ""))) < MIN_RESIDUO:
				circolari += 1
				failures.append("%s: la spiegazione ripete la domanda e la risposta senza aggiungere niente — «%s»" % [
					id, testo])
		print("%-14s %6d %8d %10d" % [subject, items.size(), vuote, circolari])

	for testo in usi.keys():
		var quante := int(usi[testo])
		if quante > MAX_RIPETIZIONI:
			failures.append("una sola spiegazione copre %d item (tetto %d): «%s» — a partire da %s" % [
				quante, MAX_RIPETIZIONI, str(testo).substr(0, 60), str(esempio[testo])])

	if failures.is_empty():
		print("\nBank explanation audit OK — %d item, %d spiegazioni distinte, nessuna oltre %d usi" % [
			totale, usi.size(), MAX_RIPETIZIONI])
		quit(0)
	else:
		print("\nSPIEGAZIONI ROSSE — %d problemi:" % failures.size())
		for f in failures.slice(0, 20):
			print("  - %s" % f)
		quit(1)

## Le parole della spiegazione che non compaiono già nella domanda o nella
## risposta. È quello che il bambino non aveva ancora davanti agli occhi.
func _residuo(spiegazione: String, prompt: String, answer: String) -> int:
	var noto: Dictionary = {}
	for parola in _parole(prompt) + _parole(answer):
		noto[parola] = true
	var nuove := 0
	for parola in _parole(spiegazione):
		if not noto.has(parola):
			nuove += str(parola).length() + 1
	return nuove

func _parole(testo: String) -> Array:
	var pulito := ""
	for c in testo.to_lower():
		pulito += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c in "àèéìòù" else " "
	var out: Array = []
	for parola in pulito.split(" ", false):
		if str(parola).length() > 1:
			out.append(str(parola))
	return out
