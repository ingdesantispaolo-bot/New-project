extends SceneTree

## **I forzieri valgono qualcosa, e la valuta ha uno scarico.** (14 agosto 2026)
##
## Nasce da una segnalazione del committente: forzieri e frammenti «sono solo una
## distrazione che non apporta nulla». Misurando, era vero due volte — la valuta
## non si spendeva da nessuna parte (`spend_fragments` non esisteva) e i forzieri
## erano quarantadue per mondo con un'etichetta estratta a sorte fra tre, di cui
## una prometteva un'energia che nessuno pagava.
##
## Le sei cose che verifica, e perché ognuna:
##
## 1. **La valuta ha uno scarico**: si può spendere, non si va sotto zero, e
##    comprare in bottega toglie frammenti e **non tocca l'energia**. È la
##    separazione delle valute: l'energia la fa lo studio, i frammenti
##    l'esplorazione ([[FragmentEconomy]]).
## 2. **Comprare non toglie niente di didattico**: padronanza, livello, missioni
##    e Codex sono identici prima e dopo un acquisto.
## 3. **Il contenuto è deterministico**: lo stesso forziere dà lo stesso
##    contenuto a due chiamate e dopo un riavvio, altrimenti «l'ho già aperto»
##    diventerebbe una bugia.
## 4. **Il contenuto non dipende dal giocatore**: livello, padronanza e cosmetici
##    non cambiano cosa c'è dentro. Un forziere che paga di più a chi va meglio
##    sarebbe una ricompensa nascosta al rendimento, e questo gioco non ne ha.
## 5. **I testi ci sono tutti**: le dodici materie hanno cinque oggetti a testa,
##    ognuno con la cosa e la riga di Eli, e nessuno è vuoto.
## 6. **La densità è quella dichiarata**: circa un terzo dei forzieri generati
##    resta nel mondo, e la scelta è stabile fra due chiamate.

const CAMPIONE := 4000

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_lo_scarico_della_valuta()
	_comprare_non_tocca_lo_studio()
	_il_contenuto_e_stabile()
	_il_contenuto_non_guarda_il_giocatore()
	_i_testi_ci_sono()
	_la_densita_dichiarata()
	if errori.is_empty():
		print("TREASURE audit VERDE — frammenti spendibili, forzieri con dentro qualcosa")
	else:
		printerr("TREASURE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Lo scarico che mancava. Il controllo che conta davvero è l'ultimo: un acquisto
## **non deve toccare l'energia**, perché era esattamente il difetto — comprarsi
## un cappello competeva con l'allenarsi.
func _lo_scarico_della_valuta() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	_controlla(save.fragments() == 0, "un salvataggio nuovo non parte da zero frammenti")
	save.add_fragments(500)
	_controlla(save.spend_fragments(120), "spendere 120 su 500 frammenti è stato rifiutato")
	_controlla(save.fragments() == 380, "dopo la spesa restano %d frammenti invece di 380" % save.fragments())
	_controlla(not save.spend_fragments(10_000), "spendere più frammenti di quanti se ne hanno è stato accettato")
	_controlla(save.fragments() == 380, "una spesa rifiutata ha comunque cambiato il saldo")
	_controlla(save.spend_fragments(-50), "una spesa negativa doveva essere innocua, non un rifiuto")
	_controlla(save.fragments() == 380, "una spesa negativa ha aggiunto frammenti: sarebbe una zecca")

	var manager := RewardManager.new(save)
	var economico := _cosmetico_piu_economico()
	var costo := int(economico.get("cost", 0))
	save.add_fragments(costo)          # ora bastano
	save.add_energy(1000)
	var energia_prima := save.energy()
	_controlla(manager.can_afford(str(economico.get("id", ""))),
		"con i frammenti esatti la bottega dice ancora che non ci si arriva")
	save.data["fragments"] = 0
	_controlla(not manager.can_afford(str(economico.get("id", ""))),
		"senza frammenti la bottega considera comunque acquistabile «%s»" % str(economico.get("name", "")))
	_controlla(manager.unavailable_reason(str(economico.get("id", ""))) == "Frammenti insufficienti",
		"il motivo del rifiuto parla ancora di energia: «%s»" % manager.unavailable_reason(str(economico.get("id", ""))))
	_controlla(save.energy() == energia_prima,
		"controllare un acquisto ha toccato l'energia")

## Quello che un acquisto NON deve muovere. Sono le cinque misure che il Lascito
## legge (`LegacyScore`): se una si muovesse comprando, il finale sarebbe in
## vendita.
func _comprare_non_tocca_lo_studio() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.set_mastery("matematica", 0.62)
	save.data["missionsBySubject"] = {"matematica": 14}
	save.data["codex"] = {"matematica:tabelline": KnowledgeCodex.STATE_CONSOLIDATED}
	save.set_level(5)
	save.add_energy(900)
	save.add_fragments(5000)

	var livello := save.level()
	var energia := save.energy()
	var padronanza := save.mastery_of("matematica")
	var missioni := save.missions_of("matematica")
	var codex: Dictionary = Dictionary(save.data.get("codex", {})).duplicate(true)

	var manager := RewardManager.new(save)
	var economico := _cosmetico_piu_economico()
	var id := str(economico.get("id", ""))
	var costo := int(economico.get("cost", 0))
	_controlla(save.spend_fragments(costo), "l'acquisto con frammenti sufficienti è stato rifiutato")
	manager.unlock_and_equip(id)

	_controlla(save.energy() == energia,
		"comprare ha cambiato l'energia: %d invece di %d" % [save.energy(), energia])
	_controlla(save.level() == livello, "comprare ha cambiato il livello")
	_controlla(is_equal_approx(save.mastery_of("matematica"), padronanza),
		"comprare ha cambiato la padronanza")
	_controlla(save.missions_of("matematica") == missioni, "comprare ha cambiato le missioni")
	_controlla(Dictionary(save.data.get("codex", {})) == codex, "comprare ha cambiato il Codex")
	_controlla(manager.owned(id), "dopo l'acquisto il cosmetico non risulta posseduto")

## Stesso forziere, stesso contenuto. Vale per il tipo, per il premio e per
## l'oggetto: sono tre estrazioni diverse e devono essere stabili tutte e tre.
func _il_contenuto_e_stabile() -> void:
	for indice in range(0, 200):
		var id := "treasure-3_%d-1" % indice
		var primo := TreasureCatalog.contenuto(7, id)
		var secondo := TreasureCatalog.contenuto(7, id)
		if primo != secondo:
			errori.append("il forziere %s cambia contenuto fra due chiamate" % id)
			break
		var tipo := str(primo.get("tipo", ""))
		var fascia: Array = TreasureCatalog.FASCIA.get(tipo, [])
		if fascia.is_empty():
			errori.append("il forziere %s ha un tipo sconosciuto: «%s»" % [id, tipo])
			break
		var premio := int(primo.get("frammenti", 0))
		if premio < int(fascia[0]) or premio > int(fascia[1]):
			errori.append("il forziere %s paga %d, fuori dalla fascia %s" % [id, premio, str(fascia)])
			break
		if str(primo.get("cosa", "")).strip_edges() == "":
			errori.append("il forziere %s non ha niente dentro da raccontare" % id)
			break
	# Il lascito deve pagare più del resto: è anche quello che chiede di fermarsi.
	_controlla(int(TreasureCatalog.FASCIA[TreasureCatalog.TIPO_LASCITO][0])
			> int(TreasureCatalog.FASCIA[TreasureCatalog.TIPO_RESTO][1]),
		"un lascito può pagare meno di una cassa qualunque: fermarsi a leggere costerebbe")

## Il contenuto guarda l'id e il mondo, mai il giocatore. Il controllo è
## strutturale — `contenuto()` non riceve il save — ma vale scriverlo: il giorno
## in cui qualcuno gli passasse la padronanza «per bilanciare», questo audit
## smetterebbe di compilare, ed è il punto.
func _il_contenuto_non_guarda_il_giocatore() -> void:
	var povero := GameSaveManager.new()
	povero.data = GameSaveManager._default_data()
	var esperto := GameSaveManager.new()
	esperto.data = GameSaveManager._default_data()
	esperto.set_level(20)
	esperto.set_mastery("matematica", 0.95)
	esperto.add_fragments(9000)
	# Stessa firma, stesso risultato: l'unica variabilità ammessa è il Custode,
	# che cambia la SCENA e non la ricompensa.
	for indice in range(0, 60):
		var id := "treasure-0_%d-0" % indice
		var con_custode := TreasureCatalog.contenuto(3, id, true)
		var senza := TreasureCatalog.contenuto(3, id, false)
		if int(con_custode.get("frammenti", 0)) != int(senza.get("frammenti", 0)) \
				and str(con_custode.get("tipo", "")) != TreasureCatalog.TIPO_CUSTODE:
			errori.append("il forziere %s paga diversamente senza Custode, e non è un forziere del Custode" % id)
			break
		if str(senza.get("tipo", "")) == TreasureCatalog.TIPO_CUSTODE:
			errori.append("il forziere %s promette il Custode a chi non ce l'ha" % id)
			break

func _i_testi_ci_sono() -> void:
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var lista: Array = TreasureCatalog.OGGETTI.get(str(subject), [])
		if lista.size() < 5:
			errori.append("la materia %s ha %d oggetti invece di cinque" % [str(subject), lista.size()])
			continue
		for voce in lista:
			var scheda: Dictionary = voce
			if str(scheda.get("nome", "")).strip_edges() == "":
				errori.append("un oggetto di %s non ha nome" % str(subject))
			if str(scheda.get("cosa", "")).strip_edges() == "":
				errori.append("l'oggetto «%s» di %s non descrive niente" % [str(scheda.get("nome", "?")), str(subject)])
			if str(scheda.get("eli", "")).strip_edges() == "":
				errori.append("l'oggetto «%s» di %s non ha la riga di Eli" % [str(scheda.get("nome", "?")), str(subject)])
	_controlla(TreasureCatalog.RESTI.size() >= 8,
		"le cianfrusaglie sono %d: troppo poche perché non si ripetano nello stesso mondo" % TreasureCatalog.RESTI.size())
	_controlla(not TreasureCatalog.CUSTODE_RIGHE.is_empty(), "il Custode non ha righe da giocare")

## La densità dichiarata, misurata su un campione grande, e la stabilità della
## scelta: un forziere saltato deve restare saltato.
func _la_densita_dichiarata() -> void:
	var presenti := 0
	for indice in range(0, CAMPIONE):
		var id := "treasure-%d_%d-%d" % [indice % 7, indice % 13, indice % 3]
		var primo := TreasureCatalog.presente(id)
		if primo != TreasureCatalog.presente(id):
			errori.append("il forziere %s appare e sparisce fra due chiamate" % id)
			return
		if primo:
			presenti += 1
	var percentuale := float(presenti) / float(CAMPIONE) * 100.0
	var atteso := float(TreasureCatalog.DENSITA_PERCENTUALE)
	_controlla(absf(percentuale - atteso) <= 6.0,
		"la densità misurata è %.1f%% contro il %.0f%% dichiarato" % [percentuale, atteso])

func _cosmetico_piu_economico() -> Dictionary:
	var migliore: Dictionary = {}
	for voce in RewardCatalog.CATALOG:
		var scheda: Dictionary = voce
		if int(scheda.get("minLevel", 1)) > 1:
			continue
		if migliore.is_empty() or int(scheda.get("cost", 0)) < int(migliore.get("cost", 0)):
			migliore = scheda
	return migliore
