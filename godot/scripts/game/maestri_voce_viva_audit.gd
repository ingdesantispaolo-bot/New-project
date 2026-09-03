extends SceneTree

## **La voce dei Maestri arriva al giocatore.** (2 settembre 2026)
##
## Nasce da un difetto misurato, non da un'idea: `MaestriCatalog` conteneva
## **novantasei battute** — 36 aperture, 36 rilanci, 24 chiusure per dodici
## Maestri — ed era citato **da un solo file in tutto il progetto: il proprio
## audit**. `maestri_audit` verificava che i dati fossero completi e coerenti, e
## lo erano; nessuno verificava che qualcuno li leggesse.
##
## Il risultato è che la regola vincolante di
## [TRAMA_E_MISTERO](../../docs/TRAMA_E_MISTERO.md) §6.1.4 — *«NORA cambia voce
## mentre guarisce»* — era vera nei documenti e falsa nel gioco: dopo aver
## riparato dodici apparati NORA parlava esattamente come al primo minuto. È la
## stessa forma del difetto dei quattro upgrade del 6 agosto e delle due rese
## spente della bottega: contenuto scritto, mai collegato.
##
## Questo audit è il collegamento reso obbligatorio. Verifica sul
## **comportamento**, non sull'esistenza dei dati:
##
## 1. **Un apparato spento non ha voce.** A partita nuova NORA parla con le sue
##    battute, e nessuna materia porta un'inflessione che non si è guadagnata.
## 2. **Un apparato riparato accende la sua voce**, e si sente: l'apertura della
##    sessione cambia, e il rilancio dopo un errore diventa quello del Maestro.
## 3. **La materia chiama la voce.** `data-core` tiene Stilo (italiano) e Faro
##    (inglese), `ponte-comando` tiene Leva (fisica) e Bussola (geografia):
##    riparare per una non deve svegliare l'altra prima che il giocatore l'abbia
##    incontrata.
## 4. **La logica tace per ventitré mondi.** Il suo Maestro è fuori, ed è un buco
##    che si deve sentire. Torna solo con il nome restituito.
## 5. **La voce non copre NORA.** Il rilancio del Maestro si alterna con le sue
##    battute: chi guarisce prende un'inflessione, non diventa qualcun altro.
## 6. **Il metodo non si perde.** L'apertura del Maestro porta comunque la frase
##    di metodo della materia: è la parte che serve al bambino, e non può
##    sparire perché è cambiata la voce.

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _save_con(riparati: Array, livello: int) -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.set_level(livello)
	for apparato in riparati:
		save.set_apparatus_repaired(str(apparato), 1)
	return save

func _init() -> void:
	_una_partita_nuova_non_ha_voci()
	_un_apparato_riparato_si_sente()
	_la_materia_chiama_la_voce()
	_la_logica_tace()
	_la_voce_non_copre_nora()
	_il_metodo_non_si_perde()
	_qualcuno_la_chiama_davvero()
	if errori.is_empty():
		print("MAESTRI VOCE VIVA audit VERDE — %d Maestri, %d battute che arrivano al giocatore"
			% [MaestriCatalog.MAESTRI.size(), _battute_totali()])
	else:
		printerr("MAESTRI VOCE VIVA audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _battute_totali() -> int:
	var totale := 0
	for id in MaestriCatalog.MAESTRI.keys():
		for pool in ["apertura", "rilancio", "chiusura"]:
			totale += MaestriCatalog.lines_of(str(id), pool).size()
	return totale

func _una_partita_nuova_non_ha_voci() -> void:
	var save := _save_con([], 1)
	for materia in ApparatusConfig.SUBJECT_CYCLE:
		_controlla(MaestriCatalog.voce_attiva(save, str(materia)).is_empty(),
			"a partita nuova la materia «%s» ha già un Maestro sveglio" % str(materia))
	var muta := NoraContextEngine.open_line("matematica", false, 1, {})
	var con_save := NoraContextEngine.open_line(
		"matematica", false, 1, MaestriCatalog.voce_attiva(save, "matematica"))
	_controlla(muta == con_save,
		"l'apertura cambia prima che un apparato sia stato riparato")

func _un_apparato_riparato_si_sente() -> void:
	var prima := _save_con([], 1)
	var dopo := _save_con(["nucleo"], 1)
	var voce := MaestriCatalog.voce_attiva(dopo, "matematica")
	_controlla(not voce.is_empty(),
		"riparato il nucleo, la matematica resta senza la voce di Abaco")
	_controlla(str(voce.get("nome", "")) == "Abaco",
		"il nucleo riparato accende «%s» invece di Abaco" % str(voce.get("nome", "")))
	var apertura_muta := NoraContextEngine.open_line(
		"matematica", false, 1, MaestriCatalog.voce_attiva(prima, "matematica"))
	var apertura_voce := NoraContextEngine.open_line("matematica", false, 1, voce)
	_controlla(apertura_muta != apertura_voce,
		"l'apertura della sessione non cambia quando il Maestro si sveglia")
	# E la battuta è davvero una delle sue, non una parafrasi generata.
	var sue: Array = MaestriCatalog.lines_of(str(voce.get("id", "")), "apertura")
	var riconosciuta := false
	for battuta in sue:
		if apertura_voce.begins_with(str(battuta)):
			riconosciuta = true
			break
	_controlla(riconosciuta,
		"l'apertura non è una delle battute scritte per il Maestro: «%s»" % apertura_voce)

	# Il rilancio dopo un errore: è la ragione per cui i Maestri esistono.
	var nora := NoraVoice.new()
	nora.level = 1
	nora.voce = voce
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var rilanci: Array = MaestriCatalog.lines_of(str(voce.get("id", "")), "rilancio")
	var sentito := false
	for _i in range(12):
		if rilanci.has(nora.line("defeat", rng)):
			sentito = true
			break
	_controlla(sentito,
		"dopo dodici errori il rilancio del Maestro non si è mai sentito")

func _la_materia_chiama_la_voce() -> void:
	# `data-core` tiene Stilo (italiano, mondo 2) e Faro (inglese, mondo 4).
	# Al mondo 2 l'italiano ce l'ha; l'inglese no, perché non l'ha ancora visto.
	var save := _save_con(["data-core"], 2)
	_controlla(not MaestriCatalog.voce_attiva(save, "italiano").is_empty(),
		"riparato il data-core al mondo 2, l'italiano resta senza voce")
	_controlla(MaestriCatalog.voce_attiva(save, "inglese").is_empty(),
		"la voce dell'inglese si accende al mondo 2, prima che il giocatore lo incontri")
	var piu_avanti := _save_con(["data-core"], 4)
	_controlla(not MaestriCatalog.voce_attiva(piu_avanti, "inglese").is_empty(),
		"arrivata al mondo 4, l'inglese non riceve la voce di Faro")

func _la_logica_tace() -> void:
	var save := _save_con(["cratere-logico"], 23)
	_controlla(MaestriCatalog.voce_attiva(save, "logica", false).is_empty(),
		"la logica ha una voce prima che il nome sia restituito: il buco non si sente più")
	_controlla(not MaestriCatalog.voce_attiva(save, "coding", false).is_empty(),
		"lo stesso apparato non dà la voce al coding, che invece la deve avere")
	_controlla(not MaestriCatalog.voce_attiva(save, "logica", true).is_empty(),
		"restituito il nome, la voce della logica non torna")

func _la_voce_non_copre_nora() -> void:
	var save := _save_con(["nucleo"], 1)
	var nora := NoraVoice.new()
	nora.level = 1
	nora.voce = MaestriCatalog.voce_attiva(save, "matematica")
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var rilanci: Array = MaestriCatalog.lines_of(str(nora.voce.get("id", "")), "rilancio")
	var dal_maestro := 0
	var da_nora := 0
	for _i in range(40):
		if rilanci.has(nora.line("defeat", rng)):
			dal_maestro += 1
		else:
			da_nora += 1
	_controlla(dal_maestro > 0 and da_nora > 0,
		"su quaranta errori parla sempre lo stesso: Maestro %d, NORA %d" % [dal_maestro, da_nora])
	# E la vittoria resta di NORA: è il momento in cui un apparato torna in
	# linea, cioè quello in cui un Maestro si sveglia.
	var chiusure: Array = MaestriCatalog.lines_of(str(nora.voce.get("id", "")), "chiusura")
	for _i in range(20):
		_controlla(not chiusure.has(nora.line("victory", rng)),
			"il Maestro commenta la riparazione dell'apparato che lo sta svegliando")

func _il_metodo_non_si_perde() -> void:
	var save := _save_con(["nucleo", "data-core", "serra-bio"], 12)
	for materia in ["matematica", "italiano", "scienze"]:
		var voce := MaestriCatalog.voce_attiva(save, str(materia))
		if voce.is_empty():
			continue
		var riga := NoraContextEngine.open_line(str(materia), false, 12, voce)
		var metodo := NoraContextEngine.subject_method(str(materia))
		_controlla(riga.to_lower().contains(metodo.to_lower()),
			"l'apertura di %s perde la frase di metodo quando parla il Maestro" % str(materia))

## **Il collegamento esiste nel codice di gioco, non solo qui.** È la riga che
## impedisce al difetto di tornare: un catalogo può restare completo, coerente e
## verificato per settimane senza che nessuno lo legga, ed è esattamente ciò che
## è successo.
func _qualcuno_la_chiama_davvero() -> void:
	var lettori: Array = []
	for percorso in [
		"res://scripts/game/outdoor_gameplay.gd",
		"res://scripts/game/nora_context_engine.gd",
		"res://scripts/game/nora_voice.gd",
	]:
		if FileAccess.get_file_as_string(percorso).contains("voce"):
			lettori.append(percorso)
	_controlla(lettori.size() == 3,
		"la voce del Maestro non attraversa tutti e tre gli anelli (gioco, apertura, battute): %s"
			% str(lettori))
	var gameplay := FileAccess.get_file_as_string("res://scripts/game/outdoor_gameplay.gd")
	_controlla(gameplay.contains("MaestriCatalog"),
		"il codice di gioco non chiama MaestriCatalog: le battute tornerebbero a non sentirsi mai")
