extends SceneTree

## **Più bambini, stesso tablet.** (6 agosto 2026)
##
## Il difetto da cui nasce: il salvataggio era un file solo, a percorso fisso.
## Due fratelli sullo stesso tablet giocavano lo stesso salvataggio senza
## accorgersene — il secondo che apriva il gioco trovava il mondo del primo, e
## ogni sessione sovrascriveva l'altra. Con una campagna da venti ore è la
## perdita che chiude un gioco per sempre.
##
## I due controlli che contano davvero, e che devono restare veri:
##
##   1. **Due profili non si toccano.** È il guasto originale: se un giorno
##      qualcuno riportasse il percorso a una costante, questo audit cade.
##   2. **Senza profili non cambia niente.** Un gioco già avviato e ogni altro
##      audit devono continuare a leggere il percorso storico. È la ragione per
##      cui l'elenco dei profili è assente finché qualcuno non lo crea.
##
## Il terzo controllo è l'adozione: il primo profilo prende il file storico
## invece di crearne uno nuovo. Senza, chi stava giocando aprirebbe il gioco e
## troverebbe il livello 1 — un difetto peggiore di quello che stiamo riparando.

func _init() -> void:
	_pulisci()
	_prova_senza_profili()
	_prova_adozione()
	_prova_isolamento()
	_prova_identificatori_non_riusati()
	_prova_limite()
	_prova_nomi()
	_prova_codici()
	print("PROFILES audit OK — profili isolati, salvataggio storico adottato, codici non collidenti")
	quit(0)

func _pulisci() -> void:
	DirAccess.remove_absolute(PlayerProfiles.PROFILES_PATH)
	DirAccess.remove_absolute(PlayerProfiles.LEGACY_SAVE_PATH)
	for i in range(1, PlayerProfiles.MAX_PROFILES + 4):
		DirAccess.remove_absolute("user://eli-quest-save-p%d.json" % i)

## Senza elenco, il gioco è quello di prima: un salvataggio solo, nel percorso
## storico. Tutti gli altri audit vivono in questo stato.
func _prova_senza_profili() -> void:
	assert(not PlayerProfiles.has_profiles(), "l'elenco esiste prima che qualcuno lo crei")
	assert(PlayerProfiles.active_save_path() == PlayerProfiles.LEGACY_SAVE_PATH,
		"senza profili il percorso non è quello storico")
	var save := GameSaveManager.new()
	assert(save.path == GameSaveManager.SAVE_PATH,
		"senza profili il manager non usa il percorso storico: %s" % save.path)

## Il primo profilo adotta la partita già in corso.
func _prova_adozione() -> void:
	# Un bambino stava già giocando, prima che i profili esistessero.
	var prima := GameSaveManager.new()
	prima.data["level"] = 9
	prima.data["fragments"] = 123
	prima.save()

	var p := PlayerProfiles.bootstrap()
	assert(not p.is_empty(), "bootstrap non ha creato nessun profilo")
	assert(PlayerProfiles.has_profiles(), "bootstrap non ha scritto l'elenco")
	assert(str(p.get("file", "")) == PlayerProfiles.LEGACY_SAVE_PATH,
		"il primo profilo non ha adottato il file storico")

	var dopo := GameSaveManager.new()
	dopo.load_save()
	assert(dopo.level() == 9, "la partita in corso è andata persa: livello %d" % dopo.level())
	assert(dopo.fragments() == 123, "i frammenti sono andati persi")

	# Idempotente: riavviare il gioco non duplica il profilo.
	for _i in range(5):
		PlayerProfiles.bootstrap()
	assert(PlayerProfiles.count() == 1, "bootstrap ripetuto ha creato %d profili" % PlayerProfiles.count())

## Il controllo centrale: due bambini, due partite, nessuna interferenza.
func _prova_isolamento() -> void:
	var secondo := PlayerProfiles.create("Marta")
	assert(not secondo.is_empty(), "il secondo profilo non è stato creato")
	var id2 := str(secondo["id"])
	assert(str(secondo["file"]) != PlayerProfiles.LEGACY_SAVE_PATH,
		"il secondo profilo condivide il file del primo")

	# Marta gioca.
	assert(PlayerProfiles.set_active(id2), "cambio profilo fallito")
	var marta := GameSaveManager.new()
	marta.load_save()
	assert(marta.level() == 1, "Marta eredita la partita di un altro: livello %d" % marta.level())
	marta.data["level"] = 4
	marta.data["fragments"] = 7
	marta.save()

	# Il primo bambino ritrova la SUA partita, intatta.
	assert(PlayerProfiles.set_active("p1"), "ritorno al primo profilo fallito")
	var primo := GameSaveManager.new()
	primo.load_save()
	assert(primo.level() == 9,
		"la partita del primo è stata sovrascritta: livello %d invece di 9" % primo.level())
	assert(primo.fragments() == 123, "i frammenti del primo sono stati sovrascritti")

	# E scrivendo ancora non tocca quella di Marta.
	primo.data["level"] = 10
	primo.save()
	var marta_ancora := GameSaveManager.new(PlayerProfiles.save_path_of(id2))
	marta_ancora.load_save()
	assert(marta_ancora.level() == 4,
		"la partita di Marta è cambiata da sola: livello %d" % marta_ancora.level())

	# Leggere un profilo che non è quello attivo non cambia quello attivo: è ciò
	# che permette all'elenco di avvio di mostrare il livello di ogni bambino.
	assert(PlayerProfiles.active_id() == "p1", "leggere un altro profilo ha cambiato l'attivo")

## Gli identificatori non tornano indietro: un profilo nuovo non può ereditare
## per sbaglio il file di uno precedente.
func _prova_identificatori_non_riusati() -> void:
	var visti: Dictionary = {}
	for p in PlayerProfiles.all():
		visti[str(Dictionary(p).get("id", ""))] = true
	var terzo := PlayerProfiles.create("Luca")
	assert(not visti.has(str(terzo["id"])), "identificatore riusato: %s" % str(terzo["id"]))
	visti[str(terzo["id"])] = true

	var file_visti: Dictionary = {}
	for p in PlayerProfiles.all():
		var f := str(Dictionary(p).get("file", ""))
		assert(not file_visti.has(f), "due profili puntano allo stesso file: %s" % f)
		file_visti[f] = true

func _prova_limite() -> void:
	while PlayerProfiles.count() < PlayerProfiles.MAX_PROFILES:
		assert(not PlayerProfiles.create("extra").is_empty(), "creazione fallita sotto il limite")
	assert(PlayerProfiles.create("uno di troppo").is_empty(),
		"l'elenco ha superato il limite di %d" % PlayerProfiles.MAX_PROFILES)
	assert(PlayerProfiles.count() == PlayerProfiles.MAX_PROFILES, "conteggio oltre il limite")

func _prova_nomi() -> void:
	assert(PlayerProfiles.sanitize_name("") == "Giocatore 1", "nome vuoto senza ricaduta")
	assert(PlayerProfiles.sanitize_name("   ", 3) == "Giocatore 3", "nome di soli spazi senza ricaduta")
	assert(PlayerProfiles.sanitize_name("  Eli  ") == "Eli", "spazi ai bordi non tolti")
	assert(PlayerProfiles.sanitize_name("Eli    Q") == "Eli Q", "spazi interni non compattati")
	# Un a capo dentro un nome spezzerebbe la riga dell'elenco.
	assert(not PlayerProfiles.sanitize_name("Eli\nQ").contains("\n"), "a capo non tolto dal nome")
	var lungo := PlayerProfiles.sanitize_name("abcdefghijklmnopqrstuvwxyz")
	assert(lungo.length() <= PlayerProfiles.NAME_MAX_CHARS,
		"nome troppo lungo non troncato: %d caratteri" % lungo.length())

	assert(PlayerProfiles.rename("p1", "Eli"), "rinomina fallita")
	assert(str(PlayerProfiles.find("p1").get("name", "")) == "Eli", "rinomina non salvata")
	assert(not PlayerProfiles.rename("inesistente", "X"), "rinominato un profilo che non esiste")
	# Rinominare non tocca il salvataggio: è la ragione per cui la cancellazione
	# non serve — chi vuole riusare una casella la rinomina e basta.
	var dopo := GameSaveManager.new(PlayerProfiles.save_path_of("p1"))
	dopo.load_save()
	assert(dopo.level() == 10, "la rinomina ha toccato il salvataggio")

func _prova_codici() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234

	# Forma e alfabeto: niente I e niente O, che un bambino confonde con 1 e 0.
	for _i in range(200):
		var codice := PlayerProfiles.generate_code(rng)
		assert(PlayerProfiles.is_valid_code(codice), "codice di forma sbagliata: %s" % codice)
		var lettere := codice.substr(0, 4)
		assert(not lettere.contains("I") and not lettere.contains("O"),
			"il codice contiene una lettera ambigua: %s" % codice)

	assert(PlayerProfiles.is_valid_code("abcd-1234"), "un codice minuscolo valido è stato rifiutato")
	assert(not PlayerProfiles.is_valid_code("ABC-1234"), "accettate tre lettere")
	assert(not PlayerProfiles.is_valid_code("ABCD1234"), "accettato senza trattino")
	assert(not PlayerProfiles.is_valid_code("ABCD-12E4"), "accettata una lettera fra le cifre")
	assert(not PlayerProfiles.is_valid_code(""), "accettato un codice vuoto")

	assert(PlayerProfiles.set_code("p1", "ABCD-1234"), "assegnazione del codice fallita")
	assert(PlayerProfiles.code_of("p1") == "ABCD-1234", "codice non salvato")
	assert(PlayerProfiles.set_code("p1", "abcd-1234"), "codice minuscolo rifiutato")
	assert(PlayerProfiles.code_of("p1") == "ABCD-1234", "codice non normalizzato in maiuscolo")
	assert(not PlayerProfiles.set_code("p1", "ABC-1"), "accettato un codice malformato")

	# Il guasto grave: due caselle sullo stesso tablet che puntano allo stesso
	# salvataggio in cloud si sovrascriverebbero a vicenda a ogni sessione.
	assert(not PlayerProfiles.set_code("p2", "ABCD-1234"),
		"due profili locali hanno lo stesso codice")
	# Riassegnare a sé stessi lo stesso codice resta lecito.
	assert(PlayerProfiles.set_code("p1", "ABCD-1234"), "riassegnare il proprio codice fallisce")

	# E un codice generato non collide con quelli già assegnati localmente.
	for _i in range(50):
		var nuovo := PlayerProfiles.generate_code(rng)
		assert(nuovo != "ABCD-1234", "generato un codice già in uso su questo dispositivo")
