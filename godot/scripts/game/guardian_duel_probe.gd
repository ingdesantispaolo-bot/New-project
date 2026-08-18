extends SceneTree

## **Che duello si trova un bambino, mondo per mondo?** (16 agosto 2026)
##
## Non è un audit e non diventa mai rosso: stampa scambi veri di ogni fascia
## perché la taratura si possa **leggere** invece che dedurla dalle costanti.
## `guardian_duel_audit` dice che nessuno scambio è impossibile; questo fa vedere
## se sono anche *interessanti* — che è una cosa che nessuna asserzione sa dire.
##
## Il grado di Eli si passa da riga di comando perché il confronto che conta non
## è mondo contro mondo, ma **mondo contro il grado che si ha davvero lì**: la
## curva della potenza porta un bambino al mondo 15 con cinque o sei gradi
## addosso, e misurare quel mondo a grado zero descrive una partita che nessuno
## gioca.
##
##     godot --headless --path godot --script res://scripts/game/guardian_duel_probe.gd -- 5

const MONDI := [1, 5, 10, 15, 20, 24]
const CAMPIONI := 4

func _init() -> void:
	var grado := 2
	for argomento in OS.get_cmdline_user_args():
		if str(argomento).is_valid_int():
			grado = int(str(argomento))
	var rng := RandomNumberGenerator.new()
	print("Duello dei guardiani — grado di Eli %d, guardiano T3\n" % grado)
	for mondo in MONDI:
		var regole := GuardianDuel.regole(mondo, 3, grado)
		print("=== mondo %d · %s · %d sigilli · tenuta %d · carica %.1fs · %d colpi su %d rune" % [
			mondo, regole["nome"], regole["sigilli"], regole["tenuta"],
			regole["secondi"], regole["colpi"], regole["mano"]])
		print("    %.1f secondi per colpo" % (float(regole["secondi"]) / float(regole["passi"])))
		for campione in range(CAMPIONI):
			rng.seed = hash("sonda-%d-%d" % [mondo, campione])
			var scambio := GuardianDuel.genera_scambio(rng, regole)
			print("    impulso %d ⇒ sigillo %d | mano [%s] | strada corta: %s" % [
				int(scambio["partenza"]), int(scambio["bersaglio"]),
				_mano(scambio), _strada(scambio, int(regole["colpi"]))])
		print("")
	quit(0)

func _mano(scambio: Dictionary) -> String:
	var testi: Array = []
	for runa in Array(scambio.get("rune", [])):
		testi.append(str(Dictionary(runa).get("testo", "")))
	return " ".join(PackedStringArray(testi))

func _strada(scambio: Dictionary, colpi: int) -> String:
	var rune: Array = scambio.get("rune", [])
	var valore := int(scambio.get("partenza", 0))
	var passi: Array = []
	for indice in GuardianDuel.percorso_minimo(valore, int(scambio.get("bersaglio", 0)), rune, colpi):
		var runa: Dictionary = rune[int(indice)]
		valore = GuardianDuel.applica(valore, runa)
		passi.append("%s→%d" % [str(runa.get("testo", "")), valore])
	return " ".join(PackedStringArray(passi)) if not passi.is_empty() else "NESSUNA"
