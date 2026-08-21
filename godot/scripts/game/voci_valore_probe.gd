extends SceneTree

## **Un bambino che non sa niente di verbi può vincere questo duello?**
## (21 agosto 2026)
##
## Segnalazione del committente: la sfida dei verbi «era incomprensibile, oppure
## semplicemente banale senza alcun valore didattico». La comprensibilità è stata
## corretta il 21 agosto; la banalità è un'accusa diversa e va misurata, non
## discussa.
##
## ## La misura
##
## Si gioca ogni scambio con **due giocatori finti**, e si guarda chi vince.
##
##   IGNORANTE   non sa niente di italiano e non guarda mai il verbo. Fa una cosa
##               sola: legge le tre parole scritte sul sigillo e tocca le rune il
##               cui valore compare in quelle parole. È l'abbinamento di simboli
##               che un bambino di sei anni farebbe senza saper leggere l'italiano.
##
##   CIECO       non legge nemmeno il sigillo: tocca rune a caso fra quelle che
##               entrano. È la linea di base — quanto si vince per fortuna.
##
## Se l'IGNORANTE vince, quello scambio **non ha misurato la grammatica**: ha
## misurato la capacità di abbinare due parole uguali. È il difetto che la
## segnalazione chiama «banale».
##
## Uso: godot --headless --path godot --script res://scripts/game/voci_valore_probe.gd

const CAMPIONI := 400

func _init() -> void:
	print("")
	print("Chi vince questo duello, mondo per mondo")
	print("")
	print("MONDO  bersaglio    IGNORANTE  CIECO   rune-che-entrano  scambi")
	var rng := RandomNumberGenerator.new()
	for mondo in [1, 3, 5, 8, 10, 14, 15, 19, 20, 24]:
		var regole := VerbDuel.regole(mondo, 4, 2)
		var vinti_ignorante := 0
		var vinti_cieco := 0
		var vive_totali := 0
		var tipo := ""
		for campione in range(CAMPIONI):
			rng.seed = hash("valore-%d-%d" % [mondo, campione])
			var scambio := VerbDuel.genera_scambio(rng, regole)
			tipo = str(Dictionary(scambio.get("sigillo", {})).get("tipo", ""))
			vive_totali += _quante_entrano(scambio)
			if _vince_ignorante(scambio, regole):
				vinti_ignorante += 1
			if _vince_cieco(scambio, regole, rng):
				vinti_cieco += 1
		print("%5d  %-11s %7.1f%%  %5.1f%%  %14.1f  %6d" % [
			mondo, tipo,
			100.0 * float(vinti_ignorante) / float(CAMPIONI),
			100.0 * float(vinti_cieco) / float(CAMPIONI),
			float(vive_totali) / float(CAMPIONI),
			CAMPIONI,
		])
	_duelli_alla_cieca()
	_verdetto()
	quit(0)

func _quante_entrano(scambio: Dictionary) -> int:
	var quante := 0
	for runa in Array(scambio.get("rune", [])):
		if VerbDuel.applicabile(Dictionary(scambio.get("partenza", {})), runa):
			quante += 1
	return quante

## **L'ignorante.** Legge le parole del sigillo — e solo quelle — e tocca le rune
## il cui valore compare lì dentro. Non guarda mai la voce di Eli, non sa che
## cos'è un congiuntivo, non sa che «cantaste» viene da «cantare».
##
## Nei mondi a etichetta il sigillo scrive «indicativo imperfetto · voi», quindi
## le parole ci sono tutte. Nei mondi a campione il sigillo scrive «staremmo»:
## nessuna runa può combaciare, e questa strategia non ha niente da leggere.
func _vince_ignorante(scambio: Dictionary, regole_duello: Dictionary) -> bool:
	var sigillo: Dictionary = scambio.get("sigillo", {})
	var parole := (str(sigillo.get("testo", "")) + " " + str(sigillo.get("sotto", ""))).to_lower()
	var cella: Dictionary = Dictionary(scambio.get("partenza", {})).duplicate()
	var bersaglio: Dictionary = scambio.get("bersaglio", {})
	var rune: Array = scambio.get("rune", [])
	var usate: Dictionary = {}
	var colpi := int(regole_duello.get("colpi", 3))
	for _giro in range(colpi):
		var scelta := -1
		for indice in rune.size():
			if usate.has(indice):
				continue
			var runa: Dictionary = rune[indice]
			if not parole.contains(str(runa.get("testo", "")).to_lower()):
				continue
			if not VerbDuel.applicabile(cella, runa):
				continue
			scelta = indice
			break
		if scelta < 0:
			return false
		usate[scelta] = true
		cella = VerbDuel.applica(cella, rune[scelta])
		if VerbDuel.uguali(cella, bersaglio):
			return true
	return false

## **Il cieco.** La fortuna pura: rune a caso fra quelle che entrano.
func _vince_cieco(scambio: Dictionary, regole_duello: Dictionary, rng: RandomNumberGenerator) -> bool:
	var cella: Dictionary = Dictionary(scambio.get("partenza", {})).duplicate()
	var bersaglio: Dictionary = scambio.get("bersaglio", {})
	var rune: Array = scambio.get("rune", [])
	var usate: Dictionary = {}
	for _giro in range(int(regole_duello.get("colpi", 3))):
		var candidate: Array = []
		for indice in rune.size():
			if not usate.has(indice) and VerbDuel.applicabile(cella, rune[indice]):
				candidate.append(indice)
		if candidate.is_empty():
			return false
		var scelta: int = candidate[rng.randi_range(0, candidate.size() - 1)]
		usate[scelta] = true
		cella = VerbDuel.applica(cella, rune[scelta])
		if VerbDuel.uguali(cella, bersaglio):
			return true
	return false

## **E un duello intero, non un solo scambio.** Uno scambio vinto per fortuna
## non basta: per battere un guardiano ne servono `sigilli` prima di aver perso
## `tenuta` volte. E' il numero che dice davvero se il minigioco si puo'
## superare senza sapere niente.
func _duelli_alla_cieca() -> void:
	var rng := RandomNumberGenerator.new()
	print("")
	print("Duelli INTERI vinti dal CIECO — quanto porta la sola fortuna")
	print("")
	print("MONDO  grado Eli  sigilli  tenuta  duelli vinti alla cieca")
	for mondo in [1, 8, 15, 24]:
		for grado in [0, 4, 8]:
			var regole := VerbDuel.regole(mondo, 4, grado)
			var vinti := 0
			for prova in range(CAMPIONI):
				rng.seed = hash("duello-%d-%d-%d" % [mondo, grado, prova])
				var rotti := 0
				var tenuta := int(regole.get("tenuta", 2))
				while rotti < int(regole.get("sigilli", 2)) and tenuta > 0:
					var scambio := VerbDuel.genera_scambio(rng, regole)
					if _vince_cieco(scambio, regole, rng):
						rotti += 1
					else:
						tenuta -= 1
				if rotti >= int(regole.get("sigilli", 2)):
					vinti += 1
			print("%5d  %9d  %7d  %6d  %20.1f%%" % [
				mondo, grado, int(regole["sigilli"]), int(regole["tenuta"]),
				100.0 * float(vinti) / float(CAMPIONI)])

func _verdetto() -> void:
	print("")
	print("COME SI LEGGE")
	print("  IGNORANTE alto = quello scambio si vince abbinando due parole uguali,")
	print("  senza sapere niente di verbi e senza mai guardare la voce di Eli.")
	print("  E' quello che la segnalazione chiama «banale».")
	print("")
	print("  IGNORANTE ~ CIECO = la lettura del sigillo non aiuta piu' della")
	print("  fortuna: li' la grammatica serve davvero.")
