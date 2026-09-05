extends SceneTree

const NORA_BOTTEGA_VOCE := preload("res://scripts/game/nora_bottega_voce.gd")

## **La bottega non può tornare a dire sempre la stessa frase.** (5 settembre 2026)
##
## Guardia di `nora_bottega_voce.gd`: la riga di apertura deve dipendere davvero
## dallo stato, deve restare corta abbastanza da stare su una riga di sottotitolo,
## e non deve mai essere vuota — un pannello che apre con un sottotitolo vuoto è
## un difetto muto, di quelli che non si vedono rileggendo.

const OK := "NORA BOTTEGA VOCE audit VERDE"

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _salvataggio(forzieri: int, pattuglie: int, mondi: int) -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var progresso: Dictionary = {}
	var restanti_forzieri := forzieri
	var restanti_pattuglie := pattuglie
	for w in range(1, 25):
		var ids: Array = []
		var nemici: Array = []
		var quanti_qui := mini(restanti_forzieri, 5)
		for k in range(quanti_qui):
			ids.append("t-%d-%d" % [w, k])
		restanti_forzieri -= quanti_qui
		var quanti_nemici_qui := mini(restanti_pattuglie, 4)
		for k in range(quanti_nemici_qui):
			nemici.append("g-%d-%d" % [w, k])
		restanti_pattuglie -= quanti_nemici_qui
		progresso[str(w)] = {"collectedTreasureIds": ids, "defeatedEnemyIds": nemici}
	save.data["worldProgress"] = progresso
	var aperti: Array = []
	for w in range(1, mini(mondi, 24) + 1):
		aperti.append(w)
	save.data["worlds"] = {"unlocked": aperti, "current": mini(mondi, 24)}
	return save

func _init() -> void:
	# Nessuna riga vuota, nessuna riga troppo lunga per un sottotitolo, e ogni
	# passo verso più esplorazione non torna alla frase di chi non ha fatto
	# niente — che sarebbe leggibile come «non ti ho vista fare nulla».
	var passi := [
		[0, 0, 1], [0, 0, 12], [1, 0, 12], [5, 0, 12], [15, 0, 12], [40, 0, 12],
		[40, 1, 12], [40, 8, 12], [40, 20, 12],
	]
	var frase_di_partenza := NORA_BOTTEGA_VOCE.riga(_salvataggio(0, 0, 1))
	var precedente_e_partenza := true
	for passo_data in passi:
		var passo: Array = passo_data
		var save := _salvataggio(int(passo[0]), int(passo[1]), int(passo[2]))
		var riga := NORA_BOTTEGA_VOCE.riga(save)
		if riga.strip_edges() == "":
			_fallisci("forzieri=%s pattuglie=%s mondi=%s: riga vuota" % [
				str(passo[0]), str(passo[1]), str(passo[2])])
			continue
		if riga.length() > 160:
			_fallisci("forzieri=%s pattuglie=%s mondi=%s: riga troppo lunga per un sottotitolo (%d caratteri)" % [
				str(passo[0]), str(passo[1]), str(passo[2]), riga.length()])
		var e_partenza := riga == frase_di_partenza
		if e_partenza and not precedente_e_partenza:
			_fallisci("forzieri=%s pattuglie=%s mondi=%s: si torna alla frase di chi non ha esplorato niente" % [
				str(passo[0]), str(passo[1]), str(passo[2])])
		precedente_e_partenza = e_partenza

	# Nessun salvataggio nullo: il pannello puo' essere costruito prima che
	# `gameplay` sia pronto, e la riga non deve piantare in quel momento.
	var vuota := NORA_BOTTEGA_VOCE.riga(null)
	if vuota.strip_edges() == "":
		_fallisci("save nullo: riga vuota")

	if errori.is_empty():
		print(OK)
	else:
		printerr("NORA BOTTEGA VOCE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
