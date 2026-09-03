extends SceneTree

## **Eli si rilegge.** (2 settembre 2026)
##
## Il difetto misurato: Eli ha una voce in sessantasette punti del gioco — una
## riga sopra ogni forziere di qualcuno, una sopra i semi che la riguardano, una
## sopra ognuna delle undici sorelle — e ognuna di quelle righe **compariva per
## tre secondi e spariva per sempre**. Sono i soli pensieri della protagonista in
## ventiquattro mondi, e il gioco non ne conservava nessuno.
##
## Le sei cose che questo audit verifica:
##
## 1. **Le righe da conservare esistono davvero**, e sono tante: se un giorno
##    qualcuno svuotasse i campi `eli`, il taccuino resterebbe bianco senza che
##    nessun altro audit se ne accorga.
## 2. **Il taccuino scrive, e non scrive due volte.** Rileggere lo stesso
##    forziere non riempie il quaderno di doppioni.
## 3. **Non tocca niente.** Non è valuta, non apre gate, non muove padronanza né
##    energia: se un giorno il taccuino desse un vantaggio, smetterebbe di essere
##    di Eli e diventerebbe una lista di raccolta.
## 4. **Non esiste un taccuino sbagliato.** Chi non si è fermato a guardare
##    niente ha un quaderno corto, e il ritratto finale funziona lo stesso.
## 5. **Il ritratto conta e non giudica**: nessuna soglia, nessun punteggio,
##    nessun confronto con un ideale — solo cose fatte.
## 6. **Il gioco lo riempie davvero.** La scena deve chiamare il taccuino nei
##    punti in cui Eli parla, altrimenti è l'ennesimo catalogo scritto e mai
##    collegato.

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _nuovo_save() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

func _init() -> void:
	_le_righe_esistono()
	_scrive_e_non_duplica()
	_non_tocca_niente()
	_il_taccuino_corto_va_bene()
	_il_ritratto_conta_e_non_giudica()
	_il_gioco_lo_riempie()
	if errori.is_empty():
		print("ELI NOTEBOOK audit VERDE — %d righe d'autore da conservare" % _righe_d_autore())
	else:
		printerr("ELI NOTEBOOK audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Quante righe di Eli esistono in tutto il gioco, contate alla fonte.
func _righe_d_autore() -> int:
	var totale := 0
	for seme_data in MysteryCatalog.tutti_i_semi():
		if str((seme_data as Dictionary).get("eli", "")).strip_edges() != "":
			totale += 1
	for subject in TreasureCatalog.OGGETTI.keys():
		for oggetto_data in Array(TreasureCatalog.OGGETTI[subject]):
			if str((oggetto_data as Dictionary).get("eli", "")).strip_edges() != "":
				totale += 1
	return totale

func _le_righe_esistono() -> void:
	var totale := _righe_d_autore()
	_controlla(totale >= 50,
		"solo %d righe di Eli in tutto il gioco: il taccuino resterebbe quasi bianco" % totale)
	# E ce ne sono anche PRIMA del colpo 3, che è il punto in cui la campagna
	# rischiava di lasciarla muta per undici mondi.
	var prima := 0
	for seme_data in MysteryCatalog.tutti_i_semi():
		var seme: Dictionary = seme_data
		if int(seme.get("world", 0)) <= 11 and str(seme.get("eli", "")).strip_edges() != "":
			prima += 1
	_controlla(prima >= 5,
		"solo %d pensieri di Eli nei primi undici mondi: nella prima metà resta muta" % prima)

func _scrive_e_non_duplica() -> void:
	var save := _nuovo_save()
	_controlla(EliNotebook.conta(save) == 0, "un taccuino nuovo non è vuoto")
	_controlla(
		EliNotebook.registra(save, "seme:x", EliNotebook.FONTE_SEME, 3, "Un pensiero."),
		"il taccuino rifiuta una voce valida")
	_controlla(EliNotebook.conta(save) == 1, "la voce non è stata scritta")
	_controlla(
		not EliNotebook.registra(save, "seme:x", EliNotebook.FONTE_SEME, 3, "Un pensiero."),
		"la stessa voce entra due volte: rileggere un forziere riempirebbe il quaderno")
	_controlla(EliNotebook.conta(save) == 1, "il doppione è stato scritto lo stesso")
	_controlla(
		not EliNotebook.registra(save, "vuota", EliNotebook.FONTE_SEME, 1, "   "),
		"una voce senza testo entra nel taccuino")
	_controlla(
		not EliNotebook.registra(save, "ignota", "fonte-inventata", 1, "Testo."),
		"una fonte non dichiarata entra nel taccuino")
	# L'ordine di rilettura parte dall'ultima: è come si rilegge un quaderno vero.
	EliNotebook.registra(save, "seme:y", EliNotebook.FONTE_SEME, 4, "Un altro pensiero.")
	var ultime := EliNotebook.ultime(save, 2)
	_controlla(ultime.size() == 2 and str((ultime[0] as Dictionary).get("id", "")) == "seme:y",
		"il taccuino non si rilegge dall'ultima pagina")

func _non_tocca_niente() -> void:
	var save := _nuovo_save()
	var energia := save.energy()
	var frammenti := save.fragments()
	var livello := save.level()
	var padronanza := save.mastery_of("matematica")
	for i in range(20):
		EliNotebook.registra(
			save, "seme:%d" % i, EliNotebook.FONTE_SEME, 1 + i, "Pensiero numero %d." % i)
	_controlla(save.energy() == energia and save.fragments() == frammenti,
		"scrivere sul taccuino muove la valuta")
	_controlla(save.level() == livello,
		"scrivere sul taccuino fa salire di livello")
	_controlla(is_equal_approx(save.mastery_of("matematica"), padronanza),
		"scrivere sul taccuino muove la padronanza")
	var contenuti := ContentManager.new()
	var prog := ProgressionManager.new(save, contenuti)
	var vuoto := ProgressionManager.new(_nuovo_save(), contenuti)
	_controlla(str(prog.readiness().get("missing", [])) == str(vuoto.readiness().get("missing", [])),
		"un taccuino pieno cambia la prontezza al livello successivo")

func _il_taccuino_corto_va_bene() -> void:
	var vuoto := _nuovo_save()
	var ritratto := EliNotebook.ritratto(vuoto)
	_controlla(int(ritratto.get("voci", -1)) == 0,
		"il ritratto di un taccuino vuoto non è leggibile")
	for chiave in ["voci", "mondi", "lasciti", "semi", "sorelleTrovate", "posizioni"]:
		_controlla(ritratto.has(chiave),
			"il ritratto non dichiara «%s»: la scena finale non saprebbe cosa nominare" % chiave)

func _il_ritratto_conta_e_non_giudica() -> void:
	var save := _nuovo_save()
	EliNotebook.registra(save, "a", EliNotebook.FONTE_LASCITO, 2, "Uno.")
	EliNotebook.registra(save, "b", EliNotebook.FONTE_LASCITO, 2, "Due.")
	EliNotebook.registra(save, "c", EliNotebook.FONTE_SORELLA, 13, "Tre.")
	EliNotebook.registra(save, "d", EliNotebook.FONTE_POSIZIONE, 23, "Quattro.")
	var ritratto := EliNotebook.ritratto(save)
	_controlla(int(ritratto.get("lasciti", 0)) == 2, "il ritratto sbaglia il conto dei lasciti")
	_controlla(int(ritratto.get("sorelleTrovate", 0)) == 1, "il ritratto sbaglia il conto delle sorelle")
	_controlla(int(ritratto.get("posizioni", 0)) == 1, "il ritratto sbaglia il conto delle posizioni")
	_controlla(int(ritratto.get("mondi", 0)) == 3, "il ritratto sbaglia i mondi toccati")
	# **Nessun voto.** Il ritratto non deve contenere niente che somigli a un
	# punteggio, a una percentuale o a un giudizio: sarebbe una pagella.
	for chiave in ritratto.keys():
		var valore = ritratto[chiave]
		_controlla(typeof(valore) == TYPE_INT,
			"il ritratto espone «%s», che non è un conteggio: rischia di diventare un voto" % str(chiave))
	for vietata in ["punteggio", "voto", "score", "rank", "percentuale", "completamento"]:
		_controlla(not ritratto.has(vietata),
			"il ritratto espone «%s»: il finale darebbe un giudizio invece di un ritratto" % vietata)

## **Il taccuino deve essere chiamato dal gioco.** È la riga che impedisce al
## difetto ricorrente del progetto di ripetersi: un catalogo scritto per intero,
## con il suo audit verde, che nessun file di gioco legge.
func _il_gioco_lo_riempie() -> void:
	var scena := FileAccess.get_file_as_string("res://scripts/outdoor_world.gd")
	_controlla(scena.contains("EliNotebook.registra"),
		"la scena non scrive mai sul taccuino: resterebbe vuoto per tutta la campagna")
	var chiamate := scena.count("EliNotebook.registra")
	_controlla(chiamate >= 3,
		"il taccuino viene riempito da %d punti soli: mancano dei canali in cui Eli parla" % chiamate)
