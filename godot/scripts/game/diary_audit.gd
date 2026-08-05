extends SceneTree

## **Il diario: giorni giocati, prove superate, statistiche.** (5 agosto 2026)
##
## Il difetto che l'ha reso necessario: `daily {date, missions, streak}` era nel
## salvataggio dal primo giorno e **non lo scriveva né lo leggeva nessuno** —
## terzo campo morto della serie, dopo i regali del Custode e i segnali di
## lettura del mondo. I giorni giocati non esistevano: il gioco misurava dodici
## materie, mastery per argomento e ritenzione, e non mostrava niente al bambino.
##
## Il controllo che giustifica l'audit, e che deve restare vero per sempre:
## **i giorni giocati non scendono mai**. È lo stesso guard-rail del legame del
## Custode — un gioco che si studia non può punire chi torna dopo tre giorni.
## Una serie che si azzera sarebbe una minaccia sul domani, non un resoconto di
## ieri, ed è il motivo per cui `streak` resta nello schema ma non si mostra.

func _init() -> void:
	_prova_giorni()
	_prova_monotonia()
	_prova_riepilogo()
	_prova_abbandono_non_conta()
	print("DIARY audit OK — giorni cumulativi e monòtoni, prove superate contate, abbandoni esclusi")
	quit(0)

func _nuovo_save() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

func _prova_giorni() -> void:
	var save := _nuovo_save()
	assert(PlayDiary.days_played(save) == 0, "un profilo nuovo non ha giorni giocati")
	assert(PlayDiary.first_day(save) == "", "un profilo nuovo non ha un primo giorno")

	assert(PlayDiary.register_day(save, "2026-08-01"), "il primo giorno deve aprirsi")
	assert(PlayDiary.days_played(save) == 1, "primo giorno non contato")
	assert(PlayDiary.first_day(save) == "2026-08-01", "primo giorno non memorizzato")

	# Idempotente entro la giornata: rientrare dieci volte conta un giorno solo.
	for _i in range(10):
		assert(not PlayDiary.register_day(save, "2026-08-01"),
			"rientrare nello stesso giorno ha aperto un giorno nuovo")
	assert(PlayDiary.days_played(save) == 1, "lo stesso giorno è stato contato più volte")

	assert(PlayDiary.register_day(save, "2026-08-02"), "il giorno dopo deve aprirsi")
	assert(PlayDiary.days_played(save) == 2, "secondo giorno non contato")

	# Un salto di un mese non azzera niente: chi torna trova quello che aveva.
	assert(PlayDiary.register_day(save, "2026-09-15"), "il ritorno dopo un mese deve contare")
	assert(PlayDiary.days_played(save) == 3, "il ritorno dopo un mese non è stato contato")
	assert(PlayDiary.first_day(save) == "2026-08-01",
		"il primo giorno è cambiato: deve restare quello vero")

	# Le prove di oggi ripartono con la giornata, i giorni no.
	PlayDiary.register_passed_today(save)
	PlayDiary.register_passed_today(save)
	assert(PlayDiary.passed_today(save) == 2, "prove di oggi non contate")
	PlayDiary.register_day(save, "2026-09-16")
	assert(PlayDiary.passed_today(save) == 0, "le prove di oggi non sono ripartite col giorno")
	assert(PlayDiary.days_played(save) == 4, "il contatore dei giorni si è azzerato col giorno")

func _prova_monotonia() -> void:
	# Sequenza avversa: date fuori ordine, ripetute, vuote. In nessun caso il
	# numero di giorni può scendere.
	var save := _nuovo_save()
	var precedente := 0
	for giorno in [
		"2026-08-10", "2026-08-10", "2026-01-01", "2026-08-11",
		"2025-12-31", "2026-08-11", "2027-03-03", "2026-08-10",
	]:
		PlayDiary.register_day(save, str(giorno))
		var ora := PlayDiary.days_played(save)
		assert(ora >= precedente, "i giorni giocati sono scesi: %d → %d" % [precedente, ora])
		precedente = ora

	# La migrazione di un salvataggio vecchio non deve azzerare niente.
	var vecchio := _nuovo_save()
	vecchio.data["daily"] = {"date": "2026-07-01", "missions": 3, "streak": 9}
	assert(PlayDiary.days_played(vecchio) == 0,
		"un salvataggio senza `days` deve partire da zero, non inventare")
	PlayDiary.register_day(vecchio, "2026-07-02")
	assert(PlayDiary.days_played(vecchio) == 1, "migrazione: il giorno nuovo non è stato contato")
	assert(int(vecchio.data["daily"].get("streak", -1)) == 9,
		"la migrazione ha perso una chiave che c'era già")

func _prova_riepilogo() -> void:
	var save := _nuovo_save()
	PlayDiary.register_day(save, "2026-08-01")
	PlayDiary.register_day(save, "2026-08-02")
	save.data["worlds"] = {"unlocked": [1, 2, 3], "current": 3}
	save.data["mastery"] = {"matematica": 0.7, "storia": 0.4}
	save.data["codex"] = {
		"matematica:misure": KnowledgeCodex.STATE_CONSOLIDATED,
		"matematica:frazioni": KnowledgeCodex.STATE_APPLIED,
		"storia:roma": KnowledgeCodex.STATE_ENCOUNTERED,
		"storia:egizi": KnowledgeCodex.STATE_UNKNOWN,
	}
	save.data["progressReport"] = {"events": [
		{"level": 1, "subject": "matematica", "mastery": 0.5, "missions": 1, "seconds": 120.0},
		{"level": 1, "subject": "matematica", "mastery": 0.6, "missions": 0, "seconds": 90.0},
		{"level": 1, "subject": "matematica", "mastery": 0.7, "missions": 1, "seconds": 150.0},
		{"level": 1, "subject": "storia", "mastery": 0.4, "missions": 1, "seconds": 60.0},
	]}

	var r: Dictionary = PlayDiary.summary(save)
	assert(int(r["giorni"]) == 2, "giorni sbagliati: %d" % int(r["giorni"]))
	assert(str(r["primoGiorno"]) == "2026-08-01", "primo giorno sbagliato")
	assert(int(r["proveAffrontate"]) == 4, "prove affrontate sbagliate: %d" % int(r["proveAffrontate"]))
	assert(int(r["proveSuperate"]) == 3, "prove superate sbagliate: %d" % int(r["proveSuperate"]))
	assert(int(r["minuti"]) == 7, "minuti sbagliati: %d (attesi 7)" % int(r["minuti"]))
	assert(int(r["mondiVisitati"]) == 3, "mondi visitati sbagliati")

	# Le materie in ordine di quante prove hai affrontato, non di punteggio.
	var materie: Array = r["materie"]
	assert(materie.size() == 2, "materie sbagliate: %d" % materie.size())
	assert(str(materie[0]["subject"]) == "matematica", "ordine delle materie sbagliato")
	assert(int(materie[0]["prove"]) == 3 and int(materie[0]["superate"]) == 2,
		"conteggio per materia sbagliato")

	var argomenti: Dictionary = r["argomenti"]
	assert(int(argomenti[KnowledgeCodex.STATE_CONSOLIDATED]) == 1, "consolidati sbagliati")
	assert(int(argomenti[KnowledgeCodex.STATE_APPLIED]) == 1, "applicati sbagliati")
	assert(int(argomenti[KnowledgeCodex.STATE_ENCOUNTERED]) == 1, "incontrati sbagliati")

	# `summary` è pura: chiamarla non deve cambiare niente nel salvataggio.
	var prima := JSON.stringify(save.data)
	PlayDiary.summary(save)
	assert(JSON.stringify(save.data) == prima, "summary() ha scritto nel salvataggio")

	# Il Custode compare solo se è stato consegnato.
	assert(Dictionary(r["custode"]).is_empty(), "il Custode compare prima di essere consegnato")
	PetState.grant(save, 1)
	PetState.register_session(save)
	var con_custode: Dictionary = PlayDiary.summary(save)["custode"]
	assert(not con_custode.is_empty(), "il Custode consegnato non compare nel diario")
	assert(int(con_custode["sessioni"]) == 1, "sessioni col Custode sbagliate")

func _prova_abbandono_non_conta() -> void:
	# Una prova chiusa non è un tentativo fallito: `resolve_session` esce prima
	# di registrarla nel progressReport, quindi il diario non la vede affatto.
	# Se un giorno qualcuno la registrasse, «affrontate» si gonfierebbe e il
	# bambino leggerebbe un fallimento che non c'è stato.
	var save := _nuovo_save()
	save.data["progressReport"] = {"events": [
		{"level": 1, "subject": "coding", "mastery": 0.3, "missions": 1, "seconds": 30.0},
	]}
	var r: Dictionary = PlayDiary.summary(save)
	assert(int(r["proveAffrontate"]) == 1 and int(r["proveSuperate"]) == 1,
		"il diario conta prove che non sono nel report")
