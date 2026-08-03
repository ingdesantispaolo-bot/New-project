extends SceneTree

## Il tastierino numerico degli esercizi a risposta libera.
##
## Nasce da un blocco vero, trovato su tablet: in un enigma di matematica il
## campo della risposta **non si riempiva** e non c'era modo di uscire dalla
## sessione. Causa: nella build Web la tastiera di sistema arriva solo con
## `html/experimental_virtual_keyboard`, che nel preset era `false`.
##
## Riacceso il flag, resta il fatto che quella funzione è dichiarata
## sperimentale e dipende dal browser. Il tastierino invece è fatto di bottoni:
## qui si verifica che componga i numeri come deve, perché è la strada che non
## dipende da nessuno.

func _init() -> void:
	var failures: Array = []
	print("Tastierino numerico — comporre una risposta senza tastiera\n")

	var player := preload("res://scripts/game/exercise_player.gd").new()
	root.add_child(player)

	var numpad: GridContainer = player._build_numpad()
	root.add_child(numpad)
	var keys: Array = []
	for child in numpad.get_children():
		keys.append(str((child as Button).text))
	print("tasti: %s" % ", ".join(PackedStringArray(keys)))
	for atteso in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "−", ",", "←", "C", "OK"]:
		if not keys.has(atteso):
			failures.append("manca il tasto «%s»" % atteso)

	# Il campo su cui scrive il tastierino.
	player._input = LineEdit.new()
	root.add_child(player._input)

	# 1 · comporre un numero.
	for key in ["4", "2"]:
		player._numpad_press(key)
	if player._input.text != "42":
		failures.append("comporre 4 e 2 ha dato «%s» invece di «42»" % player._input.text)

	# 2 · cancellare una cifra, poi tutto.
	player._numpad_press("←")
	if player._input.text != "4":
		failures.append("la cancellazione ha lasciato «%s» invece di «4»" % player._input.text)
	player._numpad_press("C")
	if player._input.text != "":
		failures.append("«C» ha lasciato «%s» invece di svuotare" % player._input.text)

	# 3 · il meno è un interruttore in testa, non un carattere qualunque.
	for key in ["1", "2", "−"]:
		player._numpad_press(key)
	if player._input.text != "-12":
		failures.append("il meno ha dato «%s» invece di «-12»" % player._input.text)
	player._numpad_press("−")
	if player._input.text != "12":
		failures.append("il meno premuto due volte ha lasciato «%s» invece di «12»" % player._input.text)

	# 4 · una virgola sola, anche premendola tre volte.
	for key in [",", ",", "5"]:
		player._numpad_press(key)
	if player._input.text != "12,5":
		failures.append("le virgole hanno dato «%s» invece di «12,5»" % player._input.text)

	# 5 · il tastierino compare per i numeri e non per le parole.
	var numerici := ["7", "-3", "12,5", "0.25"]
	var testuali := ["ghianda", "the cat", "", "12 ghiande"]
	for value in numerici:
		if not player._answer_is_numeric(value):
			failures.append("«%s» non è riconosciuta come risposta numerica" % value)
	for value in testuali:
		if player._answer_is_numeric(value):
			failures.append("«%s» è trattata come numero: il tastierino coprirebbe una parola" % value)

	print("composizione: 42 → 4 → vuoto → -12 → 12 → 12,5")
	print("numeriche riconosciute: %d/%d · testuali escluse: %d/%d" % [
		numerici.size(), numerici.size(), testuali.size(), testuali.size()])

	if not failures.is_empty():
		printerr("TASTIERINO NON VALIDO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nNumpad probe OK — si può rispondere a un esercizio numerico senza tastiera")
	quit(0)
