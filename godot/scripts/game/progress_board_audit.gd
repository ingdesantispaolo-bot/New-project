extends SceneTree

## **Il registro dei giocatori.** (6 agosto 2026)
##
## Il rischio di questa funzione non è tecnico, è di progetto: una classifica
## per livello premia chi ha cominciato prima e condanna chi arriva dopo, e in
## un gioco che ha appena legato la progressione alla padronanza — non alla
## velocità — sarebbe un contrordine. Le prove qui sotto difendono le tre
## proprietà che tengono in piedi il compromesso:
##
##   1. **Esiste sempre una gara che riparte.** Se un giorno gli assi
##      diventassero tutti cumulativi, chi arriva ultimo non avrebbe più modo di
##      tornare primo, e la tabella smetterebbe di dare sfida per iniziare a
##      dare motivi di smettere.
##   2. **Nessuna misura scende per un'assenza.** Niente serie da spezzare:
##      saltare tre giorni non deve togliere niente a nessuno.
##   3. **L'ordine non cambia da solo.** A parità di valore l'ordine è
##      alfabetico e non dipende da come sono stati letti i profili: senza,
##      due bambini a pari merito si scavalcherebbero a turno a ogni apertura.

func _init() -> void:
	_pulisci()
	_prova_settimana_riparte()
	_prova_assenza_non_toglie()
	_prova_scheda()
	_prova_ordine_stabile()
	_prova_medaglie()
	_prova_schede_locali()
	_prova_scheda_non_porta_segreti()
	print("PROGRESS BOARD audit OK — la settimana riparte, l'assenza non toglie, l'ordine non balla")
	quit(0)

func _pulisci() -> void:
	DirAccess.remove_absolute(PlayerProfiles.PROFILES_PATH)
	DirAccess.remove_absolute(PlayerProfiles.LEGACY_SAVE_PATH)
	for i in range(1, PlayerProfiles.MAX_PROFILES + 2):
		DirAccess.remove_absolute("user://eli-quest-save-p%d.json" % i)

func _nuovo_save() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

## La proprietà che dà la sfida: la settimana esce dalla finestra da sola.
func _prova_settimana_riparte() -> void:
	var save := _nuovo_save()
	PlayDiary.register_day(save, "2026-08-01")
	for _i in range(9):
		PlayDiary.register_passed_today(save)
	assert(PlayDiary.passed_this_week(save, "2026-08-01") == 9,
		"le prove di oggi non entrano nella settimana")

	# Due giorni dopo contano ancora entrambi.
	PlayDiary.register_day(save, "2026-08-03")
	for _i in range(4):
		PlayDiary.register_passed_today(save)
	assert(PlayDiary.passed_this_week(save, "2026-08-03") == 13,
		"la settimana non somma i giorni: %d" % PlayDiary.passed_this_week(save, "2026-08-03"))

	# Sette giorni dopo il primo, quel giorno è uscito dalla finestra: chi era
	# in testa non lo è più per forza di inerzia. È esattamente il punto.
	assert(PlayDiary.passed_this_week(save, "2026-08-08") == 4,
		"il giorno vecchio non è uscito dalla finestra: %d" % PlayDiary.passed_this_week(save, "2026-08-08"))
	assert(PlayDiary.passed_this_week(save, "2026-09-01") == 0,
		"dopo un mese la settimana non è vuota")

	# La coda non cresce all'infinito: gonfierebbe ogni salvataggio e ogni copia
	# in cloud per un dato che nessuno guarda.
	for giorno in range(1, 40):
		PlayDiary.register_day(save, "2026-10-%02d" % ((giorno % 28) + 1))
		PlayDiary.register_passed_today(save)
	var coda: Array = Array(Dictionary(save.data["daily"]).get("recent", []))
	assert(coda.size() <= PlayDiary.RECENT_MAX,
		"la coda dei giorni è cresciuta oltre il limite: %d" % coda.size())

## Nessuna misura scende perché qualcuno è stato via.
func _prova_assenza_non_toglie() -> void:
	var save := _nuovo_save()
	PlayDiary.register_day(save, "2026-08-01")
	PlayDiary.register_passed_today(save)
	save.data["codex"] = {"matematica:frazioni": KnowledgeCodex.STATE_CONSOLIDATED}
	save.data["level"] = 5
	var prima := ProgressBoard.scheda(save, "Eli", "2026-08-01")

	# Un mese di assenza.
	PlayDiary.register_day(save, "2026-09-10")
	var dopo := ProgressBoard.scheda(save, "Eli", "2026-09-10")
	for asse in ["livello", "giorni", "consolidati"]:
		assert(float(dopo[asse]) >= float(prima[asse]),
			"l'assenza ha fatto scendere «%s»: %s → %s" % [asse, prima[asse], dopo[asse]])
	assert(int(dopo["giorni"]) == 2, "il ritorno non è stato contato come giorno giocato")

## Almeno un asse deve ripartire, o la tabella esclude chi arriva dopo.
func _prova_scheda() -> void:
	var riparte := 0
	for a in ProgressBoard.ASSI:
		var asse: Dictionary = a
		assert(not str(asse.get("spiega", "")).strip_edges().is_empty(),
			"l'asse «%s» non spiega che cos'è" % str(asse.get("id", "")))
		if bool(asse.get("riparte", false)):
			riparte += 1
	assert(riparte >= 1, "nessun asse riparte: la tabella premia solo chi ha cominciato prima")

	var save := _nuovo_save()
	save.data["level"] = 3
	save.data["worlds"] = {"unlocked": [1, 2, 3], "current": 3}
	save.data["mastery"] = {"matematica": 0.8}
	var s := ProgressBoard.scheda(save, "Eli")
	assert(ProgressBoard.scheda_valida(s), "una scheda appena costruita non è valida")
	assert(int(s["livello"]) == 3 and int(s["mondi"]) == 3, "livello o mondi sbagliati")
	# Tutte e dodici le materie sono presenti, anche quelle mai giocate: una
	# colonna che appare e sparisce a seconda del giocatore rende la tabella
	# illeggibile.
	assert(Dictionary(s["materie"]).size() == ApparatusConfig.SUBJECT_CYCLE.size(),
		"la scheda non porta tutte le materie: %d" % Dictionary(s["materie"]).size())
	assert(is_equal_approx(float(Dictionary(s["materie"])["matematica"]), 0.8), "padronanza sbagliata")

	assert(not ProgressBoard.scheda_valida({}), "una scheda vuota è stata accettata")
	assert(not ProgressBoard.scheda_valida({"nome": "  ", "livello": 1, "settimana": 0,
		"giorni": 0, "consolidati": 0}), "una scheda senza nome è stata accettata")

## A parità di valore l'ordine non deve dipendere da come sono arrivate le schede.
func _prova_ordine_stabile() -> void:
	var a := {"nome": "Marta", "livello": 4, "settimana": 5, "giorni": 2, "consolidati": 0, "materie": {}}
	var b := {"nome": "Bruno", "livello": 4, "settimana": 5, "giorni": 2, "consolidati": 0, "materie": {}}
	var c := {"nome": "Ada", "livello": 9, "settimana": 1, "giorni": 2, "consolidati": 0, "materie": {}}

	var uno := ProgressBoard.ordina([a, b, c], "livello")
	var due := ProgressBoard.ordina([c, b, a], "livello")
	assert(str(uno[0]["nome"]) == "Ada", "il primo per livello è sbagliato")
	for i in range(uno.size()):
		assert(str(uno[i]["nome"]) == str(due[i]["nome"]),
			"l'ordine dipende da come sono arrivate le schede: %s vs %s" % [
				str(uno[i]["nome"]), str(due[i]["nome"])])
	assert(str(uno[1]["nome"]) == "Bruno", "a pari merito non ha vinto l'alfabeto")

	# Sull'asse che riparte la classifica si ribalta: è la prova che chi è
	# indietro nel viaggio può comunque essere primo.
	var settimana := ProgressBoard.ordina([a, b, c], "settimana")
	assert(str(settimana[0]["nome"]) != "Ada",
		"chi guida il viaggio guida anche la settimana: la gara non riparte davvero")

func _prova_medaglie() -> void:
	var a := {"nome": "Marta", "livello": 4, "settimana": 9, "giorni": 3, "consolidati": 1,
		"materie": {"matematica": 0.9, "musica": 0.1}}
	var b := {"nome": "Bruno", "livello": 7, "settimana": 2, "giorni": 8, "consolidati": 4,
		"materie": {"matematica": 0.2, "musica": 0.8}}

	var m := ProgressBoard.medaglie([a, b])
	assert(Array(m.get("Marta", [])).has("settimana"), "Marta non è prima nella settimana")
	assert(Array(m.get("Marta", [])).has("materia:matematica"), "Marta non è prima in matematica")
	assert(Array(m.get("Bruno", [])).has("livello"), "Bruno non è primo nel viaggio")
	assert(Array(m.get("Bruno", [])).has("materia:musica"), "Bruno non è primo in musica")
	# Il punto del compromesso: con dodici materie, entrambi guidano qualcosa.
	assert(m.has("Marta") and m.has("Bruno"), "qualcuno non guida niente pur essendo avanti in qualcosa")

	# Un primato su zero non è un primato: essere primi in una materia che
	# nessuno ha toccato non è un traguardo.
	var vuoto_a := {"nome": "Ada", "livello": 0, "settimana": 0, "giorni": 0, "consolidati": 0, "materie": {}}
	var vuoto_b := {"nome": "Dino", "livello": 0, "settimana": 0, "giorni": 0, "consolidati": 0, "materie": {}}
	assert(ProgressBoard.medaglie([vuoto_a, vuoto_b]).is_empty(),
		"assegnate medaglie a giocatori che non hanno fatto niente")

	# Un primato condiviso non si rivendica.
	var pari_a := {"nome": "Ada", "livello": 3, "settimana": 0, "giorni": 0, "consolidati": 0, "materie": {}}
	var pari_b := {"nome": "Dino", "livello": 3, "settimana": 0, "giorni": 0, "consolidati": 0, "materie": {}}
	assert(not Array(ProgressBoard.medaglie([pari_a, pari_b]).get("Ada", [])).has("livello"),
		"un primo posto a pari merito è stato assegnato")

	# Con un giocatore solo non c'è confronto, quindi non c'è medaglia.
	assert(ProgressBoard.medaglie([a]).is_empty(), "medaglie assegnate senza avversari")

func _prova_schede_locali() -> void:
	assert(ProgressBoard.schede_locali().is_empty(),
		"senza profili il registro di casa non è vuoto")

	PlayerProfiles.bootstrap("Eli")
	var secondo := PlayerProfiles.create("Marta")
	var s2 := GameSaveManager.new(str(secondo["file"]))
	s2.data["level"] = 6
	s2.save()

	var schede := ProgressBoard.schede_locali()
	assert(schede.size() == 2, "il registro di casa non vede tutte le caselle: %d" % schede.size())
	var per_nome: Dictionary = {}
	for s in schede:
		per_nome[str(Dictionary(s)["nome"])] = s
	assert(per_nome.has("Eli") and per_nome.has("Marta"), "manca un giocatore dal registro")
	assert(int(Dictionary(per_nome["Marta"])["livello"]) == 6,
		"il registro legge il salvataggio sbagliato: è il difetto originale del file unico")

## La scheda che va nel gruppo non deve portare con sé niente di riservato.
##
## Il codice di ripristino apre e SOVRASCRIVE un salvataggio: se finisse nella
## tabella, chiunque abbia il codice del gruppo potrebbe cancellare la partita di
## un altro bambino. È il difetto più grave che questa funzione potrebbe avere.
func _prova_scheda_non_porta_segreti() -> void:
	var save := _nuovo_save()
	save.data["level"] = 4
	var s := ProgressBoard.scheda(save, "Eli")
	var testo := JSON.stringify(s)
	for proibito in ["code", "codice", "masteryByTopic", "spacedRepetition", "worldProgress", "cosmetics"]:
		assert(not testo.contains(proibito),
			"la scheda porta con sé «%s»: nel gruppo deve viaggiare solo un riepilogo" % proibito)
	# E deve restare piccola: un gruppo di trenta schede sta in una chiave sola.
	assert(testo.length() < 1200, "la scheda è troppo grande: %d byte" % testo.length())
