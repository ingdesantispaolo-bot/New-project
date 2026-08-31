extends SceneTree

## **Ricominciare da capo cancella una partita: qui si controlla che non lo
## faccia mai per sbaglio.** (31 agosto 2026)
##
## Le caselle dei giocatori sono sei e non si cancellano — buttare via venti ore
## di lavoro di un bambino con un tocco resta fuori discussione. Mancava pero' la
## via di mezzo, e senza di quella un settimo bambino ereditava il livello di
## qualcun altro: `rename` cambia il nome e lascia dentro la partita.
##
## Questa prova tiene ferme le quattro cose che rendono la funzione accettabile:
##
##   1. **Una conferma sola non basta.** Il primo «sì» non cancella niente.
##   2. **La seconda domanda e' diversa dalla prima**, e porta il nome del
##      bambino: un «sei sicuro?» ripetuto identico si tocca due volte di
##      riflesso, e a quel punto non protegge piu' nessuno.
##   3. **Nessun'altra casella viene sfiorata.**
##   4. **Il codice cloud si stacca**, cosi' la partita nuova non sovrascrive in
##      cloud quella del bambino di prima: quel salvataggio resta sotto il suo
##      codice, e chi l'ha scritto su un foglio puo' riprenderselo.

func _init() -> void:
	call_deferred("_run")

func _livello(id: String) -> int:
	var save := GameSaveManager.new(PlayerProfiles.save_path_of(id))
	save.load_save()
	return save.level()

func _run() -> void:
	PlayerProfiles.bootstrap("Anna")
	var altro := PlayerProfiles.create("Bruno")
	var id := str(altro.get("id", ""))
	assert(id != "", "la fixture deve creare una seconda casella")

	var save := GameSaveManager.new(PlayerProfiles.save_path_of(id))
	save.data["level"] = 9
	save.data["missionsBySubject"] = {"matematica": 7}
	save.save()
	var codice := PlayerProfiles.generate_code()
	assert(PlayerProfiles.set_code(id, codice), "la fixture deve poter assegnare un codice")
	var vicina := GameSaveManager.new(PlayerProfiles.save_path_of("p1"))
	vicina.data["level"] = 4
	vicina.save()

	var pannello := ProfilePanel.new()
	root.add_child(pannello)
	await process_frame

	pannello.call("_apri_nome", id, false)
	await process_frame
	var apri := pannello.find_child("RestartProfileButton", true, false) as Button
	assert(apri != null, "la scheda di una casella deve offrire «ricomincia da capo»")
	apri.pressed.emit()
	await process_frame

	# 1. Una conferma sola non cancella.
	var prima := pannello.find_child("RestartFirstConfirmButton", true, false) as Button
	assert(prima != null, "la prima domanda non compare")
	assert(pannello.find_child("RestartSecondConfirmButton", true, false) == null,
		"le due domande non devono comparire insieme: sarebbero una sola")
	# Il testo si legge ADESSO: premere ridisegna la colonna, e il pulsante della
	# prima domanda viene liberato nello stesso istante.
	var testo_prima := str(prima.text)
	prima.pressed.emit()
	await process_frame
	assert(_livello(id) == 9, "una conferma sola ha gia' cancellato la partita")

	# 2. La seconda domanda e' diversa, e nomina chi si sta cancellando.
	var seconda := pannello.find_child("RestartSecondConfirmButton", true, false) as Button
	assert(seconda != null, "la seconda domanda non compare")
	assert(str(seconda.text) != testo_prima,
		"la seconda domanda ripete la prima: due tocchi identici non sono due conferme")
	assert("BRUNO" in str(seconda.text).to_upper(),
		"la seconda conferma deve nominare la partita che sta per sparire")

	seconda.pressed.emit()
	await process_frame

	# 3 e 4. Cancellata quella, e solo quella; il codice si stacca.
	assert(_livello(id) == 1, "dopo due conferme la partita deve ripartire da capo")
	assert(_livello("p1") == 4, "ricominciare una casella ha toccato la partita di un'altra")
	assert(str(PlayerProfiles.find(id).get("name", "")) == "Bruno",
		"la casella deve sopravvivere con il suo nome: non e' una cancellazione di profilo")
	assert(PlayerProfiles.code_of(id) == "",
		"il codice cloud deve staccarsi, o la partita nuova sovrascrive quella vecchia in cloud")

	# Ripensarci a meta' strada riporta all'elenco senza danni.
	pannello.call("_apri_nome", id, false)
	await process_frame
	(pannello.find_child("RestartProfileButton", true, false) as Button).pressed.emit()
	await process_frame
	(pannello.find_child("RestartCancelButton", true, false) as Button).pressed.emit()
	await process_frame
	assert(pannello.find_child("RestartSecondConfirmButton", true, false) == null,
		"annullare deve chiudere la richiesta, non lasciarla aperta")

	pannello.queue_free()
	await process_frame
	# Un `assert` fallito ferma `_run` prima di qui: `quit` non viene chiamato e
	# il runner lo raccoglie come TIMEOUT, oltre a leggere la riga «Assertion
	# failed» dall'output. E' il comportamento delle altre prove di scena.
	print("PROFILE RESTART audit OK — due conferme diverse, una casella sola azzerata, codice cloud staccato")
	quit(0)
