extends SceneTree

## **Il perimetro del corso vale anche sulla pratica.** (3 settembre 2026)
##
## Fisica e musica sono corsi, non vetrine del banco: `STRICT_LESSON_SUBJECTS`
## dice che in un mondo si può chiedere soltanto ciò che quel mondo insegna. La
## regola era applicata in due punti su tre — `build_mission` e `inject_non_mc` —
## e non nel terzo, **l'evento pratica**, che è il minigioco che si trova
## camminando e che da solo vale due terzi dei nodi di un mondo.
##
## Misurato prima di collegarlo: **il 71% dei nodi di pratica di fisica e il 63%
## di quelli di musica stavano fuori dalla lezione del loro mondo** — la densità
## dei materiali nel mondo che aveva appena spiegato che cos'è una leva.
##
## ## Perché questo audit ha due metà, e la seconda conta quanto la prima
##
## Stringere un perimetro senza rifornirlo è il modo più veloce di peggiorare un
## mondo: le prove disponibili crollano, la pratica ripete le stesse tre e
## `variety_audit` se ne accorge una settimana dopo. È già successo — il mondo 17
## di fisica insegnava pressione, galleggiamento e correnti e giocava al 52% di
## scelta multipla, contro l'8% del mondo 5, perché dentro il suo perimetro non
## c'era quasi niente da fare con le mani.
##
## Quindi qui si verificano due cose insieme:
##
##   1. **niente esce dal perimetro**: ogni nodo di pratica porta un argomento
##      che la lezione di quel mondo dichiara;
##   2. **il perimetro è abitabile**: quel mondo offre comunque abbastanza
##      caselle (formato, argomento) e abbastanza prove distinte perché la
##      pratica non diventi una filastrocca.
##
## Il secondo numero è un cricchetto: sale, non scende.
##
## Uso: node scripts/run-godot-audits.mjs pratica_perimetro

const OK := "PRATICA PERIMETRO audit VERDE"
const SEMI := 60

## Caselle (formato, argomento) e prove distinte misurate il 3 settembre 2026,
## dopo il rifornimento. Possono solo salire: chi stringe ancora il perimetro, o
## alza un `minLevel` dentro un corso, trova rosso qui invece che in
## `variety_audit` fra una settimana.
const PAVIMENTO := {
	"fisica@5": {"caselle": 11, "prove": 150},
	"fisica@17": {"caselle": 14, "prove": 159},
	"musica@6": {"caselle": 17, "prove": 133},
	"musica@18": {"caselle": 7, "prove": 137},
}

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	var manager := MinigameManager.new()
	print("")
	print("MONDO             ARGOMENTI DELLA LEZIONE                 NODI  FUORI  CASELLE  PROVE")
	for subject_data in ContentManager.STRICT_LESSON_SUBJECTS:
		var subject := str(subject_data)
		for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
			var lezione := ContentManager.lesson_topic_set(subject, level)
			if lezione.is_empty():
				continue   # non è un mondo di questa materia: nessun perimetro
			var argomenti: Array = lezione.keys()
			argomenti.sort()
			var nodi := 0
			var fuori: Dictionary = {}
			var caselle: Dictionary = {}
			var prove: Dictionary = {}
			for seme in range(SEMI):
				var rng := RandomNumberGenerator.new()
				rng.seed = hash("perimetro:%s:%d:%d" % [subject, level, seme])
				for node_data in Array(manager.build_minigame(subject, level, rng).get("nodes", [])):
					var nodo: Dictionary = node_data
					var topic := str(nodo.get("topic", ""))
					var fmt := str(nodo.get("format", ""))
					nodi += 1
					if not lezione.has(topic):
						fuori[topic] = int(fuori.get(topic, 0)) + 1
					caselle["%s|%s" % [fmt, topic]] = true
					prove[ExerciseSignature.of(nodo)] = true
			var quanti_fuori := 0
			for chiave in fuori.keys():
				quanti_fuori += int(fuori[chiave])
			print("%-9s mondo %2d  %-38s %5d  %5d  %7d  %5d" % [
				subject, level, ", ".join(PackedStringArray(argomenti)),
				nodi, quanti_fuori, caselle.size(), prove.size()])

			_controlla(quanti_fuori == 0,
				"%s mondo %d: %d nodi di pratica fuori dalla lezione (%s)" % [
					subject, level, quanti_fuori, str(fuori)])

			var chiave_pavimento := "%s@%d" % [subject, level]
			var atteso: Dictionary = PAVIMENTO.get(chiave_pavimento, {})
			if atteso.is_empty():
				errori.append("%s: manca il pavimento dichiarato per il mondo %d" % [subject, level])
				continue
			_controlla(caselle.size() >= int(atteso["caselle"]),
				"%s mondo %d: solo %d caselle (formato, argomento), il pavimento è %d — il perimetro è stato stretto senza rifornirlo" % [
					subject, level, caselle.size(), int(atteso["caselle"])])
			_controlla(prove.size() >= int(atteso["prove"]),
				"%s mondo %d: solo %d prove distinte in %d sessioni, il pavimento è %d" % [
					subject, level, prove.size(), SEMI, int(atteso["prove"])])

	# **E qualcuno lo applica davvero.** Il difetto ricorrente di questo progetto
	# è la regola scritta e mai collegata: qui la si verifica dal lato del
	# chiamante, cioè che `build_minigame` filtri per conto suo senza che nessuno
	# gli passi niente — è così che lo chiamano l'evento pratica del mondo e
	# `inject_non_mc`.
	var sorgente := FileAccess.get_file_as_string("res://scripts/game/minigame_manager.gd")
	_controlla(sorgente.contains("perimetro_di(subject, level)"),
		"build_minigame non calcola più il perimetro: la regola tornerebbe scritta e non applicata")

	print("")
	if errori.is_empty():
		print(OK)
	else:
		printerr("PRATICA PERIMETRO audit ROSSO — %d problemi:" % errori.size())
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
