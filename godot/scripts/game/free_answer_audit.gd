extends SceneTree

## **Almeno un quinto delle domande senza opzioni da cui copiare.** Standard
## fissato il 4 agosto 2026.
##
## Perché: una domanda a quattro opzioni si può risolvere per esclusione senza
## sapere niente. Tre distrattori scartati e la risposta resta, anche a chi la
## lezione non l'ha mai sentita. Scrivere «rifrazione» in un campo vuoto no: o
## la parola c'è in testa o non c'è. Il 3 agosto undici banchi su dodici erano
## al cento per cento di scelta multipla, e il gioco misurava soprattutto
## l'abilità nell'escludere.
##
## Perché un quinto e non tutto: la scelta multipla non è inutile. Regge le
## domande di ragionamento, dove la risposta è una frase e digitarla sarebbe una
## gara di dattilografia; e regge il primo incontro con un argomento, quando
## vedere le alternative fa parte dell'imparare. Il tetto del trenta per cento
## dice la stessa cosa dall'altro lato: oltre, il banco diventa un dettato.
##
## Le due forme di risposta libera: `numeric_input` per i numeri, `short_answer`
## per le parole. La seconda accetta le varianti dichiarate in `accept` — «to
## check» vale «check» — perché segnare sbagliata una risposta giusta è il modo
## più veloce per far smettere di provare.

const MINIMA := 0.20
const MASSIMA := 0.30

## I formati che chiedono al bambino di produrre la risposta invece di
## riconoscerla fra quattro.
const LIBERI := ["numeric_input", "short_answer"]

func _init() -> void:
	var failures: Array = []
	var cm := ContentManager.new()
	print("Risposta libera per banco — forbice: %d%%-%d%%\n" % [int(MINIMA * 100), int(MASSIMA * 100)])
	print("%-14s %6s %8s %7s" % ["MATERIA", "item", "liberi", "quota"])

	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var items: Array = cm._load_bank(subject)
		if items.is_empty():
			failures.append("%s: banco vuoto" % subject)
			continue

		var liberi := 0
		var senza_risposta: Array = []
		for entry in items:
			var item := entry as Dictionary
			var fmt := str(item.get("format", "multiple_choice"))
			if not LIBERI.has(fmt):
				continue
			liberi += 1
			# Un item a risposta libera senza risposta scritta è una domanda a
			# cui è impossibile rispondere: la scelta multipla almeno mostrava
			# qualcosa da premere.
			if str(item.get("answer", "")).strip_edges() == "":
				senza_risposta.append(str(item.get("id", "?")))

		var quota := float(liberi) / float(items.size())
		print("%-14s %6d %8d %6d%%" % [subject, items.size(), liberi, int(round(quota * 100.0))])

		if quota < MINIMA:
			# Troncato, non arrotondato: un 19,6% stampato come «20%» sotto la
			# soglia del 20% farebbe sembrare l'audit rotto.
			failures.append("%s: solo il %d%% di risposta libera (minimo %d%%), mancano %d item" % [
				subject, int(floor(quota * 100.0)), int(MINIMA * 100),
				int(ceil(MINIMA * items.size())) - liberi])
		if quota > MASSIMA:
			failures.append("%s: il %d%% di risposta libera supera il tetto del %d%%" % [
				subject, int(round(quota * 100.0)), int(MASSIMA * 100)])
		if not senza_risposta.is_empty():
			failures.append("%s: %d item a risposta libera senza risposta (%s)" % [
				subject, senza_risposta.size(), ", ".join(PackedStringArray(senza_risposta.slice(0, 3)))])

	if failures.is_empty():
		print("\nFree answer audit OK — ogni banco fra il %d%% e il %d%% di risposta libera" % [
			int(MINIMA * 100), int(MASSIMA * 100)])
		quit(0)
	else:
		print("\nRISPOSTA LIBERA ROSSA — %d problemi:" % failures.size())
		for f in failures:
			print("  - %s" % f)
		quit(1)
