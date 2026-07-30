extends SceneTree

## Audit di CHIAREZZA della caccia all'errore (`code_debug`), 30 luglio.
##
## Segnalato giocando, sull'esame finale di matematica: «Controlla il calcolo
## passo per passo: quale riga sbaglia?» con righe `7 + 5` / `= 13` /
## `# quanto fa davvero?`. Tre difetti di chiarezza, sistemici:
##
##  1. **la riga di commento è selezionabile ma non può mai essere la risposta.**
##     Il renderer crea un pulsante numerato per ogni riga di `codeLines`; chi
##     sceglie il commento riceve «Quella riga è valida: segui i valori passo per
##     passo», che per un commento non significa niente. Il commento serve — porta
##     l'INTENTO, senza cui il bug non è trovabile — ma va mostrato come nota, non
##     come candidato;
##  2. **candidati troppo pochi.** Togliendo il commento, quella specifica lasciava
##     due sole righe: una scelta quasi a testa o croce, sotto il tetto del 33%
##     fissato per la scelta multipla;
##  3. **righe che non sono passi.** `7 + 5` e `= 13` sono i due pezzi di UNA
##     uguaglianza, non due passaggi: chiedere «quale riga sbaglia» è ambiguo,
##     perché l'errore sta nella relazione fra le due, non dentro una delle due.
##
## Regole verificate su TUTTE le materie:
##  - `answerLine` punta sempre a una riga CANDIDATA, mai a un commento;
##  - ogni specifica ha almeno 3 righe candidate;
##  - al massimo un commento, e sempre come ultima riga (layout prevedibile);
##  - la posizione dell'errore varia dentro la materia (guard-rail del 29 luglio:
##     non può essere sempre la seconda riga).

const MIN_CANDIDATES := 3

static func is_comment(line: String) -> bool:
	return line.strip_edges().begins_with("#")

func _init() -> void:
	var problems: Array = []
	var manager := MinigameManager.new()

	for subject in MinigameManager.CODE_DEBUG.keys():
		var specs: Array = MinigameManager.CODE_DEBUG[subject]
		var answer_positions: Dictionary = {}
		for spec_data in specs:
			var spec: Dictionary = spec_data
			var lines: Array = spec.get("codeLines", [])
			var answer_line := int(spec.get("answerLine", 0))
			var label := "%s/%s L%d" % [
				str(subject), str(spec.get("topic", "?")), int(spec.get("minLevel", 0))]

			var candidates := 0
			var comments := 0
			var last_is_comment := false
			for index in lines.size():
				var line := str(lines[index])
				if is_comment(line):
					comments += 1
					last_is_comment = index == lines.size() - 1
					if index + 1 == answer_line:
						problems.append("%s: answerLine %d punta a un COMMENTO" % [label, answer_line])
				else:
					candidates += 1

			if candidates < MIN_CANDIDATES:
				problems.append("%s: solo %d righe candidate (minimo %d)" % [label, candidates, MIN_CANDIDATES])
			if comments > 1:
				problems.append("%s: %d righe di commento (massimo 1)" % [label, comments])
			if comments == 1 and not last_is_comment:
				problems.append("%s: il commento non è l'ultima riga" % label)

			# La posizione conta SOLO dove le righe non si rimescolano. Con
			# `shuffleLines` il generatore rimescola il corpo a ogni partita e
			# ricalcola `answerLine`, quindi la posizione autorata è irrilevante:
			# controllarla comunque produce un falso positivo — cinque materie
			# risultavano "sempre alla riga 3" pur essendo già a posto.
			if not bool(spec.get("shuffleLines", false)):
				answer_positions[answer_line] = int(answer_positions.get(answer_line, 0)) + 1

		# Dove l'ordine è il ragionamento la posizione dell'errore non può essere
		# sempre la stessa: basterebbe impararla per superare la prova senza leggerla
		# (guard-rail del 29 luglio).
		if answer_positions.size() == 1 and int(answer_positions.values()[0]) >= 3:
			problems.append(
				"%s: l'errore è SEMPRE alla riga %s nelle %d specifiche a ordine fisso" % [
					str(subject), str(answer_positions.keys()[0]), int(answer_positions.values()[0])])

	# Esce con codice 1 invece di fallire un `assert`. Un assert fallito interrompe
	# `_init()` senza raggiungere `quit()`: il processo resta appeso fino al timeout
	# del runner (240 s) e lo stdout bufferizzato va perso proprio quando serve —
	# cioè quando ci sono problemi da leggere. Il runner considera rosso anche un
	# exit code diverso da zero, quindi il gate non si indebolisce.
	if not problems.is_empty():
		printerr("CODE-DEBUG chiarezza ROSSO — %d problemi:" % problems.size())
		for problem in problems:
			printerr("  - %s" % problem)
		quit(1)
		return
	print("Code-debug clarity audit OK — %d materie, righe candidate e commenti coerenti" % MinigameManager.CODE_DEBUG.size())
	quit(0)
