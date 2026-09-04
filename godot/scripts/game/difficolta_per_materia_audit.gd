extends SceneTree

## **La difficoltà segue quanto sai, non quanto hai camminato.** (3 settembre 2026)
##
## Era il numero uno del piano da settimane, e il piano lo chiamava «l'unico
## difetto che può far perdere un bambino su una materia intera».
##
## Com'era: `target_difficulty(level)` decide, `mastery_nudge` corregge di **un
## gradino solo**, e il bersaglio satura a 4 dal mondo 13. Al mondo 20 un bambino
## a cui la fisica è sfuggita al mondo 5 riceveva difficoltà 3 — e non riceveva
## mai più 1 o 2. Poteva restare indietro per sedici mondi senza che il gioco se
## ne accorgesse mai.
##
## Com'è: l'esperienza nella materia — le sessioni **superate**, che è il solo
## conteggio che non premia chi sbaglia — decide a che gradino della scala sei;
## il mondo decide quanto è alta la scala. Chi macina non riceve al mondo 1 prove
## che il mondo 1 non ha spiegato; chi è indietro al mondo 20 riceve finalmente
## le prove che gli servono.
##
## ## Le cinque cose che questo audit tiene ferme
##
##   1. LA SCALA       l'esperienza muove la difficoltà, e la muove in salita;
##   2. IL TETTO       il mondo resta il massimo: nessuna esperienza sfonda la
##                     progressione del curricolo;
##   3. IL PAVIMENTO   chi è indietro riceve prove FACILI anche a mondo alto —
##                     è il difetto che questa modifica esiste per riparare;
##   4. IL RIPIEGO     `experience < 0` vale «sconosciuta» e ricade sul solo
##                     livello, come fa `mastery < 0`: i chiamanti vecchi e gli
##                     audit che non la passano continuano a valere;
##   5. IL COLLEGAMENTO il percorso VIVO la passa davvero. È il difetto ricorrente
##                     di questo progetto — la regola scritta e mai collegata — e
##                     qui costerebbe l'intera modifica: tutto verde, e nel gioco
##                     niente sarebbe cambiato.
##
## Uso: node scripts/run-godot-audits.mjs difficolta_per_materia

const OK := "DIFFICOLTA PER MATERIA audit VERDE"

## I punti del gioco che costruiscono una sessione per un bambino vero. Ognuno
## deve passare l'esperienza della materia, non solo la padronanza.
const CHIAMANTI_VIVI := {
	"res://scripts/game/outdoor_gameplay.gd": 6,
	"res://scripts/hub_scene.gd": 1,
}

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	var content := ContentManager.new()

	# --- 1. LA SCALA ---------------------------------------------------------
	var gradini: Array = []
	for esperienza in [0, 3, 4, 9, 10, 19, 20, 60]:
		gradini.append(ContentManager.experience_difficulty(esperienza))
	print("")
	print("scala dell'esperienza (0, 3, 4, 9, 10, 19, 20, 60 sessioni superate): %s" % str(gradini))
	for i in range(1, gradini.size()):
		_controlla(int(gradini[i]) >= int(gradini[i - 1]),
			"la scala dell'esperienza scende fra il passo %d e il %d" % [i - 1, i])
	_controlla(int(gradini[0]) == 1, "chi non ha mai superato una prova non parte dal primo gradino")
	_controlla(int(gradini[gradini.size() - 1]) == 4, "l'esperienza non arriva mai all'ultimo gradino")

	# --- 2. IL TETTO ---------------------------------------------------------
	# Un bambino con esperienza infinita non deve ricevere al mondo 1 prove che il
	# mondo 1 non ha ancora spiegato.
	print("")
	print("MATERIA        MONDO   SENZA STORIA   ESPERTO(60)   INDIETRO(0)")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for level in [1, 8, 20]:
			var cieco := content.effective_difficulty(subject, level, -1.0)
			var esperto := content.effective_difficulty(subject, level, -1.0, 60)
			var indietro := content.effective_difficulty(subject, level, -1.0, 0)
			if subject == "matematica" or level == 20:
				print("%-13s %5d   %12d   %11d   %11d" % [subject, level, cieco, esperto, indietro])
			_controlla(esperto <= cieco,
				"%s mondo %d: l'esperienza sfonda il tetto del mondo (%d oltre %d)" % [
					subject, level, esperto, cieco])

			# --- 3. IL PAVIMENTO ---------------------------------------------
			# Al mondo alto chi non ha esperienza deve ricevere prove piu' facili
			# di chi ce l'ha. Se i due numeri coincidono, la riparazione non e'
			# avvenuta e il bambino indietro resta indietro.
			if level == 20:
				var span := content.subject_difficulty_range(subject)
				if span.x < span.y:
					_controlla(indietro < esperto,
						"%s mondo 20: chi e' indietro riceve la stessa difficolta' di chi e' esperto (%d)" % [
							subject, indietro])

			# --- 4. IL RIPIEGO -----------------------------------------------
			_controlla(content.effective_difficulty(subject, level, -1.0, -1) == cieco,
				"%s mondo %d: esperienza sconosciuta non ricade sul solo livello" % [subject, level])

	# La differenza si vede nelle prove costruite, non solo nella formula.
	var medie: Dictionary = {}
	for esperienza in [0, 60]:
		var somma := 0.0
		var quanti := 0
		for seme in range(40):
			var rng := RandomNumberGenerator.new()
			rng.seed = 4400 + seme
			for nodo_data in Array(content.build_mission(
					"geografia", 20, 3, {}, rng, -1.0, {}, esperienza).get("nodes", [])):
				somma += float(int((nodo_data as Dictionary).get("difficulty", 0)))
				quanti += 1
		medie[esperienza] = somma / float(maxi(1, quanti))
	print("")
	print("geografia al mondo 20 · difficolta' media delle prove servite: indietro %.2f · esperto %.2f" % [
		float(medie[0]), float(medie[60])])
	_controlla(float(medie[0]) < float(medie[60]),
		"le prove servite non cambiano fra un bambino indietro e uno esperto: la regola non arriva ai nodi")

	# --- 5. IL COLLEGAMENTO --------------------------------------------------
	# Ogni costruttore di sessione chiamato dal gioco vivo deve passare
	# `missions_of`. Senza, questa modifica sarebbe verde qui e assente in gioco.
	for percorso_dato in CHIAMANTI_VIVI.keys():
		var percorso := str(percorso_dato)
		var sorgente := FileAccess.get_file_as_string(percorso)
		_controlla(sorgente != "", "sorgente illeggibile: %s" % percorso)
		var quante := sorgente.count("missions_of(subject)")
		_controlla(quante >= int(CHIAMANTI_VIVI[percorso_dato]),
			"%s passa l'esperienza solo %d volte su %d costruzioni di sessione: la difficolta' per materia non arriverebbe al bambino" % [
				percorso, quante, int(CHIAMANTI_VIVI[percorso_dato])])

	print("")
	if errori.is_empty():
		print(OK)
	else:
		printerr("DIFFICOLTA PER MATERIA audit ROSSO — %d problemi:" % errori.size())
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
