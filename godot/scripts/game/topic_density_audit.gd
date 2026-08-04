extends SceneTree

## **Almeno quindici item per argomento.** Standard fissato il 3 agosto 2026.
##
## Perché quindici e non quattro o sei: il gioco promette che un argomento è
## *consolidato* dopo tre risposte corrette in sessioni distinte, a tre giorni di
## distanza. Con un solo item per argomento — e ce n'erano **sette** così — il
## bambino rivede tre volte la stessa identica domanda e il gioco chiama quello
## consolidamento. Non è ritenzione: è memoria di una schermata.
##
## Quindici è la soglia sotto cui un argomento non regge il ripasso spaziato di
## una campagna intera, e sopra cui comincia a reggerlo con margine.
##
## **Questo audit non è ancora al suo standard, e lo dice.** Servivano 788 item
## il 3 agosto; il numero stampato a ogni giro è quello vero di oggi. Nel
## frattempo fa due cose che valgono già adesso:
##
## - **impedisce di peggiorare**: nessuna materia può guadagnare argomenti sotto
##   soglia né allontanarsi dal traguardo. È il cricchetto;
## - **pretende lo standard pieno** dalle materie dichiarate complete.
##
## La regola del progetto resta quella: prima il contenuto, poi il cricchetto. Qui
## il cricchetto c'è dal primo giorno, ma stringe sulla distanza dal traguardo,
## non sul traguardo — così la suite continua a essere un segnale invece di un
## semaforo rosso fisso.

const MIN_PER_TOPIC := 15

## Materie che hanno già lo standard pieno: qui un argomento sotto 15 è un errore
## immediato, non un lavoro da fare.
const COMPLETATE := ["inglese", "matematica", "coding", "storia", "logica", "musica", "scienze"]

## Distanza dal traguardo, misurata il 3 agosto. Sono **pavimenti**: possono solo
## scendere. Se un numero sale, qualcuno ha tolto contenuto o aggiunto un
## argomento senza riempirlo.
const PAVIMENTO := {
	"italiano": {"sotto": 9, "mancanti": 125},
	"latino": {"sotto": 9, "mancanti": 93},
	"elettronica": {"sotto": 7, "mancanti": 62},
	"fisica": {"sotto": 8, "mancanti": 57},
	"geografia": {"sotto": 6, "mancanti": 52},
}

func _init() -> void:
	var failures: Array = []
	var cm := ContentManager.new()
	print("Densità per argomento — standard: %d item\n" % MIN_PER_TOPIC)
	print("%-14s %6s %6s %8s %9s" % ["MATERIA", "item", "topic", "sotto15", "mancanti"])

	var mancanti_totali := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var items: Array = cm._load_bank(subject)
		var per_topic: Dictionary = {}
		for entry in items:
			var topic := str((entry as Dictionary).get("topic", ""))
			per_topic[topic] = int(per_topic.get(topic, 0)) + 1

		var sotto := 0
		var mancanti := 0
		var peggiori: Array = []
		for topic in per_topic.keys():
			var n := int(per_topic[topic])
			if n < MIN_PER_TOPIC:
				sotto += 1
				mancanti += MIN_PER_TOPIC - n
				peggiori.append({"topic": str(topic), "n": n})
		mancanti_totali += mancanti

		# Le materie complete non hanno margine: sotto soglia è un errore.
		if COMPLETATE.has(subject) and sotto > 0:
			peggiori.sort_custom(func(a, b): return int(a["n"]) < int(b["n"]))
			var nomi: Array = []
			for p in peggiori:
				nomi.append("%s(%d)" % [str(p["topic"]), int(p["n"])])
			failures.append("%s è dichiarata completa ma ha %d argomenti sotto %d: %s" % [
				subject, sotto, MIN_PER_TOPIC, ", ".join(PackedStringArray(nomi))])

		# Il cricchetto: la distanza dal traguardo può solo accorciarsi.
		if PAVIMENTO.has(subject):
			var pavimento := PAVIMENTO[subject] as Dictionary
			if sotto > int(pavimento["sotto"]):
				failures.append("%s: gli argomenti sotto soglia sono %d, erano %d — è peggiorata" % [
					subject, sotto, int(pavimento["sotto"])])
			if mancanti > int(pavimento["mancanti"]):
				failures.append("%s: mancano %d item, ne mancavano %d — è peggiorata" % [
					subject, mancanti, int(pavimento["mancanti"])])

		print("%-14s %6d %6d %8d %9d%s" % [
			subject, items.size(), per_topic.size(), sotto, mancanti,
			"   ✓ standard pieno" if sotto == 0 else ""])

	print("\nitem ancora da scrivere per arrivare a %d per argomento: %d" % [
		MIN_PER_TOPIC, mancanti_totali])
	if mancanti_totali > 0:
		print("(il traguardo è dichiarato, non ancora raggiunto: il cricchetto")
		print(" impedisce di allontanarsene, non finge che sia stato raggiunto)")

	if not failures.is_empty():
		printerr("DENSITÀ IN PEGGIORAMENTO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nTopic density audit OK — nessuna materia si è allontanata dallo standard")
	quit(0)
