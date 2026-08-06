extends SceneTree

## **La copia in cloud: la busta e i messaggi.** (6 agosto 2026)
##
## Questo audit non tocca la rete, di proposito: una prova che chiama un Worker
## vero fallisce quando manca la connessione, e una suite che diventa rossa per
## il wifi smette di essere creduta. Si verifica ciò che si può verificare da
## fermi — e che è anche dove stanno gli errori veri:
##
##   - la **busta**, che è l'unica difesa contro «quel codice contiene i dati di
##     qualcun altro». Se `scarta` accettasse qualunque JSON, un errore di
##     battitura nel codice sostituirebbe la partita di un bambino con roba
##     estranea;
##   - i **messaggi**, che un bambino di dieci anni deve poter leggere. «Errore
##     404» somiglia a un guasto del gioco, non a «quel codice non ha niente».
##
## Il giro completo sul Worker vero è verificato a mano al deploy (`curl` in
## `cloud/LEGGIMI.md`), che è il posto giusto: lì la rete è il soggetto.

func _init() -> void:
	_prova_indirizzo()
	_prova_busta()
	_prova_busta_rifiuta()
	_prova_messaggi()
	_prova_registro_gruppo()
	print("CLOUD SAVE audit OK — busta chiusa, estranei rifiutati, messaggi leggibili, gruppo filtrato")
	quit(0)

func _prova_indirizzo() -> void:
	# Il gioco è pubblicato su https. Un indirizzo in http verrebbe bloccato dal
	# browser come contenuto misto, e il salvataggio in cloud fallirebbe in
	# silenzio nella build vera pur funzionando in locale.
	assert(CloudSave.ENDPOINT.begins_with("https://"),
		"l'indirizzo del cloud non è https: %s" % CloudSave.ENDPOINT)
	assert(not CloudSave.ENDPOINT.ends_with("/"),
		"l'indirizzo finisce con una barra: l'URL avrebbe due barre di fila")

func _prova_busta() -> void:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.data["level"] = 7
	save.data["fragments"] = 42

	var testo := CloudSave.incarta(save.data, "Eli")
	var busta := CloudSave.scarta(testo)
	assert(not busta.is_empty(), "la busta appena scritta non si riapre")
	assert(str(busta["nome"]) == "Eli", "il nome non ha attraversato la busta")
	assert(int(busta["salvatoIl"]) > 0, "manca la data di scrittura")

	var dati: Dictionary = busta["dati"]
	assert(int(dati["level"]) == 7, "il livello non ha attraversato la busta")
	assert(int(dati["fragments"]) == 42, "i frammenti non hanno attraversato la busta")
	# Il giro completo deve restituire lo stesso salvataggio, non uno somigliante.
	#
	# Il confronto passa da JSON su ENTRAMBI i lati, e non è un modo di
	# addolcire la prova: JSON non distingue interi da decimali, quindi `7`
	# torna `7.0`. Non è un difetto del cloud — succede identico a ogni
	# caricamento da disco, perché anche il salvataggio locale è JSON. Il gioco
	# convive con questo da sempre (gli accessori fanno `int(...)`), e una prova
	# che pretendesse i tipi originali chiederebbe al cloud una garanzia che il
	# disco non dà. Ciò che deve restare identico — le chiavi e i valori — è
	# esattamente ciò che questo confronto verifica.
	assert(JSON.stringify(dati) == JSON.stringify(JSON.parse_string(JSON.stringify(save.data))),
		"il salvataggio è cambiato passando dalla busta")

	# Un salvataggio scritto senza busta resta riconoscibile: il Worker accetta
	# qualunque JSON, e rifiutare un salvataggio valido per la carta che ha
	# attorno sarebbe la perdita che stiamo cercando di evitare.
	var nudo := CloudSave.scarta(JSON.stringify(save.data))
	assert(not nudo.is_empty(), "un salvataggio senza busta è stato rifiutato")
	assert(int(Dictionary(nudo["dati"])["level"]) == 7, "salvataggio senza busta letto male")

func _prova_busta_rifiuta() -> void:
	# Tutto ciò che NON è una partita di Eli Quest deve essere rifiutato: è
	# quello che si trova dietro un codice ricopiato male.
	for estraneo in [
		"",
		"non sono json",
		"[1,2,3]",
		"null",
		"42",
		'{"qualcosa":"altro"}',
		'{"gioco":"un-altro-gioco","dati":{"level":3}}',
		'{"gioco":"eli-quest","dati":{}}',
		'{"gioco":"eli-quest"}',
		'{"level":3}',                    # forma di save incompleta: manca schemaVersion
		'{"schemaVersion":3}',            # e viceversa
	]:
		assert(CloudSave.scarta(str(estraneo)).is_empty(),
			"accettato come partita qualcosa che non lo è: %s" % str(estraneo))

func _prova_messaggi() -> void:
	# Nessun messaggio deve essere vuoto, e nessuno deve mostrare un codice HTTP
	# nudo per i casi che un bambino incontra davvero.
	for stato in [0, 400, 404, 413, 500]:
		for azione in ["scarica", "carica", "riserva"]:
			var m := CloudSave.messaggio_errore(stato, str(azione))
			assert(not m.strip_edges().is_empty(),
				"messaggio vuoto per stato %d, azione %s" % [stato, azione])
			assert(m.length() > 20, "messaggio troppo scarno per stato %d: %s" % [stato, m])

	assert(not CloudSave.messaggio_errore(404, "scarica").contains("404"),
		"il messaggio di codice inesistente mostra il numero HTTP")
	assert(CloudSave.messaggio_errore(404, "scarica").to_lower().contains("codice"),
		"il messaggio di codice inesistente non nomina il codice")
	# Senza rete il bambino deve sapere che può continuare a giocare: è la regola
	# per cui il locale resta la verità e il cloud è solo una copia.
	var offline := CloudSave.messaggio_errore(0, "carica").to_lower()
	assert(offline.contains("gioca") or offline.contains("tablet"),
		"il messaggio di rete assente non rassicura sulla partita locale: %s" % offline)
	assert(CloudSave.messaggio_errore(400, "scarica").to_lower().contains("lettere"),
		"il messaggio di codice malformato non spiega la forma del codice")

## Il registro di gruppo riceve righe scritte da ALTRI tablet: non è mai da
## credere sulla parola.
##
## E le due forme di codice devono restare distinguibili. I due campi di testo
## stanno nella stessa schermata e fanno l'opposto: un codice di ripristino
## SOVRASCRIVE un salvataggio, un codice gruppo apre una tabella. Se un codice
## gruppo passasse per codice di ripristino, il primo scambio sarebbe
## irreversibile.
func _prova_registro_gruppo() -> void:
	var buona := {"nome": "Eli", "livello": 3, "settimana": 5, "giorni": 2,
		"consolidati": 1, "materie": {"matematica": 0.5}}
	var risposta := JSON.stringify({"membri": [
		buona,
		{"nome": "", "livello": 1, "settimana": 0, "giorni": 0, "consolidati": 0},
		{"non": "una scheda"},
		"nemmeno questa",
		42,
	]})
	var schede := CloudSave.schede_valide(risposta)
	assert(schede.size() == 1, "il filtro del gruppo ha accettato righe rotte: %d" % schede.size())
	assert(str(Dictionary(schede[0])["nome"]) == "Eli", "il filtro ha tenuto la riga sbagliata")

	for spazzatura in ["", "non json", "[]", "null", '{"membri":"stringa"}', '{"altro":[]}']:
		assert(CloudSave.schede_valide(str(spazzatura)).is_empty(),
			"il filtro ha prodotto righe da: %s" % str(spazzatura))

	# Le due forme non devono sovrapporsi, in nessuna delle due direzioni.
	assert(not PlayerProfiles.is_valid_code("ABC-123"),
		"un codice gruppo passa per codice di ripristino: uno scambio sovrascriverebbe una partita")
	assert(not PlayerProfiles.is_valid_group_code("ABCD-1234"),
		"un codice di ripristino passa per codice gruppo")
	assert(PlayerProfiles.is_valid_group_code("ABC-123"), "un codice gruppo valido è stato rifiutato")

	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for _i in range(100):
		var g := PlayerProfiles.generate_group_code(rng)
		assert(PlayerProfiles.is_valid_group_code(g), "codice gruppo generato non valido: %s" % g)
		assert(not PlayerProfiles.is_valid_code(g), "codice gruppo generato confondibile: %s" % g)
		var lettere := g.substr(0, 3)
		assert(not lettere.contains("I") and not lettere.contains("O"),
			"il codice gruppo contiene una lettera ambigua: %s" % g)

	assert(CloudSave.messaggio_errore(409, "scheda").to_lower().contains("pieno"),
		"il gruppo pieno non è spiegato")
	assert(CloudSave.messaggio_errore(400, "gruppo").to_lower().contains("tre"),
		"il messaggio del codice gruppo non spiega la forma giusta")
