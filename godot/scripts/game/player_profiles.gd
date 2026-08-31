class_name PlayerProfiles
extends RefCounted

## Più bambini, stesso tablet — e lo stesso bambino su tablet diversi.
##
## Fino al 6 agosto 2026 il salvataggio era uno solo, in `user://eli-quest-save.json`.
## Bastava finché giocava una persona sola su un dispositivo solo. Due fratelli
## sullo stesso tablet si sovrascrivevano a vicenda senza accorgersene: la
## campagna dura circa venti ore, ed è il tipo di perdita che chiude un gioco per
## sempre.
##
## Qui vive l'elenco dei profili. Ogni profilo ha un **file suo** e un **codice
## suo**: il file risolve «stesso tablet, bambini diversi», il codice risolve
## «stesso bambino, tablet diversi» perché è la chiave con cui il Worker in cloud
## ritrova quel salvataggio (vedi `cloud/LEGGIMI.md`).
##
## COMPATIBILITÀ, che è la ragione della forma di questo file:
## senza `eli-quest-profiles.json` tutto si comporta **esattamente** come prima —
## un salvataggio solo, nel percorso storico. Un gioco già avviato non si accorge
## del cambiamento, e le decine di audit che fanno `GameSaveManager.new()` non
## vanno toccate. Il primo profilo, quando nasce, **adotta** quel file invece di
## crearne uno nuovo: chi stava giocando ritrova la sua partita, non un livello 1.

const PROFILES_PATH := "user://eli-quest-profiles.json"
const LEGACY_SAVE_PATH := "user://eli-quest-save.json"
const SCHEMA_VERSION := 1

## Sei bastano per una famiglia e per una postazione di classe. Il limite non è
## tecnico: è un elenco che deve restare leggibile a colpo d'occhio da un bambino.
const MAX_PROFILES := 6
const NAME_MAX_CHARS := 14

## Alfabeto del codice di ripristino, **senza I e senza O**: un bambino che
## ricopia il codice dal foglio le confonde con 1 e 0, e un codice sbagliato non
## dà errore — apre un salvataggio che non esiste. Tolte quelle due lettere, la
## lettura è priva di ambiguità. Restano 24^4 · 10^4 ≈ 3,3 miliardi di codici.
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ"

# ---------------------------------------------------------------- lettura/scrittura

static func _read() -> Dictionary:
	if not FileAccess.file_exists(PROFILES_PATH):
		return {}
	var file := FileAccess.open(PROFILES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	if not d.has("profiles"):
		return {}
	return d

static func _write(d: Dictionary) -> void:
	var file := FileAccess.open(PROFILES_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(d, "\t"))

# ---------------------------------------------------------------- interrogazione

## Vero se l'elenco esiste. Falso al primo avvio e in tutti gli audit, che è ciò
## che li lascia invariati.
static func has_profiles() -> bool:
	return not _read().is_empty()

static func all() -> Array:
	var out: Array = []
	for p in Array(_read().get("profiles", [])):
		if typeof(p) == TYPE_DICTIONARY:
			out.append(p)
	return out

static func count() -> int:
	return all().size()

static func find(id: String) -> Dictionary:
	for p in all():
		if str((p as Dictionary).get("id", "")) == id:
			return p
	return {}

static func active_id() -> String:
	var d := _read()
	if d.is_empty():
		return ""
	var wanted := str(d.get("active", ""))
	if not find(wanted).is_empty():
		return wanted
	# L'attivo punta a un profilo sparito: invece di restare senza salvataggio,
	# ricade sul primo dell'elenco. Un elenco vuoto non può esistere, perché
	# `bootstrap` crea sempre almeno un profilo e non esiste una cancellazione.
	var lista := all()
	return "" if lista.is_empty() else str(Dictionary(lista[0]).get("id", ""))

static func active() -> Dictionary:
	return find(active_id())

## Il percorso su cui lavora `GameSaveManager` quando nessuno gli dice altro.
## Senza elenco è il percorso storico: è questo che tiene fermo tutto il resto.
static func active_save_path() -> String:
	var p := active()
	if p.is_empty():
		return LEGACY_SAVE_PATH
	return str(p.get("file", LEGACY_SAVE_PATH))

static func save_path_of(id: String) -> String:
	var p := find(id)
	return LEGACY_SAVE_PATH if p.is_empty() else str(p.get("file", LEGACY_SAVE_PATH))

# ---------------------------------------------------------------- creazione

## Garantisce che esista almeno un profilo, **adottando** il salvataggio storico.
## Idempotente: chiamarla a ogni avvio non duplica niente.
static func bootstrap(nome: String = "Giocatore 1") -> Dictionary:
	var d := _read()
	if not d.is_empty():
		return active()
	var primo := {
		"id": "p1",
		"name": sanitize_name(nome, 1),
		# Il file storico, non uno nuovo: qui sta la partita di chi giocava prima.
		"file": LEGACY_SAVE_PATH,
		"code": "",
		"createdAt": int(Time.get_unix_time_from_system()),
		"lastPlayed": 0,
	}
	_write({
		"schemaVersion": SCHEMA_VERSION,
		"active": "p1",
		"nextId": 2,
		"profiles": [primo],
	})
	return primo

## Nuovo profilo, con un file tutto suo. Restituisce {} se l'elenco è pieno.
##
## L'identificatore non riusa mai un numero già speso (`nextId` cresce e basta):
## un profilo nuovo non può ereditare per sbaglio il file di uno precedente.
static func create(nome: String) -> Dictionary:
	bootstrap()
	var d := _read()
	var profili: Array = Array(d.get("profiles", []))
	if profili.size() >= MAX_PROFILES:
		return {}
	var numero := int(d.get("nextId", profili.size() + 1))
	var id := "p%d" % numero
	var nuovo := {
		"id": id,
		"name": sanitize_name(nome, numero),
		"file": "user://eli-quest-save-%s.json" % id,
		"code": "",
		"createdAt": int(Time.get_unix_time_from_system()),
		"lastPlayed": 0,
	}
	profili.append(nuovo)
	d["profiles"] = profili
	d["nextId"] = numero + 1
	_write(d)
	return nuovo

## Non esiste una cancellazione, ed è una scelta.
##
## Cancellare un profilo butterebbe via venti ore di lavoro di un bambino con un
## tocco, sul dispositivo di un altro bambino, senza che il proprietario sia
## presente. Chi vuole riusare una casella la **rinomina**: è ciò che fa davvero
## una famiglia, e non distrugge niente. Il limite di sei caselle esiste perché
## senza cancellazione l'elenco non deve poter crescere all'infinito.

static func rename(id: String, nome: String) -> bool:
	var d := _read()
	var profili: Array = Array(d.get("profiles", []))
	for i in range(profili.size()):
		var p: Dictionary = profili[i]
		if str(p.get("id", "")) == id:
			p["name"] = sanitize_name(nome, i + 1)
			profili[i] = p
			d["profiles"] = profili
			_write(d)
			return true
	return false

static func set_active(id: String) -> bool:
	var d := _read()
	if find(id).is_empty():
		return false
	d["active"] = id
	_write(d)
	return true

## Segna che questo profilo ha giocato adesso: serve a mostrare l'elenco con
## l'ultimo usato in evidenza, così il bambino ritrova la sua casella senza
## leggerle tutte.
static func touch(id: String) -> void:
	var d := _read()
	var profili: Array = Array(d.get("profiles", []))
	for i in range(profili.size()):
		var p: Dictionary = profili[i]
		if str(p.get("id", "")) == id:
			p["lastPlayed"] = int(Time.get_unix_time_from_system())
			profili[i] = p
			d["profiles"] = profili
			_write(d)
			return

# ---------------------------------------------------------------- nomi

## Un nome che entra in una riga e non contiene niente che possa rompere la UI.
## Vuoto o fatto di soli spazi ricade su «Giocatore N»: una casella senza nome
## sarebbe indistinguibile dalle altre.
static func sanitize_name(nome: String, indice: int = 1) -> String:
	var pulito := ""
	for c in nome.strip_edges():
		# Fuori i caratteri di controllo: un a capo dentro un nome spezza la riga
		# dell'elenco e un profilo finisce fuori dallo schermo.
		if c.unicode_at(0) >= 32:
			pulito += c
	while pulito.contains("  "):
		pulito = pulito.replace("  ", " ")
	if pulito.is_empty():
		return "Giocatore %d" % indice
	if pulito.length() > NAME_MAX_CHARS:
		pulito = pulito.substr(0, NAME_MAX_CHARS).strip_edges()
	return pulito

# ---------------------------------------------------------------- codice cloud

## Forma del codice: quattro lettere, trattino, quattro cifre (`ABCD-1234`).
## È la stessa che il Worker pretende, in `cloud/index.ts`.
static func is_valid_code(codice: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[A-Z]{4}-[0-9]{4}$")
	return regex.search(codice.to_upper()) != null

## Genera un codice **non già usato da un altro profilo su questo dispositivo**.
##
## Non garantisce l'unicità globale, e non può: il Worker non ha un elenco da
## consultare. Chi lo usa deve prima chiedere al cloud se quel codice è già
## occupato (GET) e rigenerare in caso — è ciò che fa `cloud_save.gd`, ed è
## l'unica difesa contro l'unico incidente davvero grave: due bambini che
## finiscono sullo stesso salvataggio.
static func generate_code(rng: RandomNumberGenerator = null) -> String:
	var r := rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	var occupati: Dictionary = {}
	for p in all():
		occupati[str(Dictionary(p).get("code", ""))] = true
	for _tentativo in range(40):
		var codice := ""
		for _i in range(4):
			codice += ALPHABET[r.randi_range(0, ALPHABET.length() - 1)]
		codice += "-"
		for _i in range(4):
			codice += str(r.randi_range(0, 9))
		if not occupati.has(codice):
			return codice
	return ""

static func code_of(id: String) -> String:
	return str(find(id).get("code", ""))

## Stacca il codice da una casella **senza toccare quello che c'e' in cloud**.
##
## Serve a «ricomincia da capo»: la partita nuova non deve ereditare il codice
## della precedente, o al primo salvataggio ci scriverebbe sopra — e la copia di
## sicurezza del bambino di prima sparirebbe proprio mentre qualcun altro inizia.
## Staccandolo, quel salvataggio resta in cloud sotto il suo codice e chi lo ha
## scritto su un foglio puo' ancora riprenderselo.
static func clear_code(id: String) -> bool:
	var d := _read()
	var profili: Array = Array(d.get("profiles", []))
	for i in range(profili.size()):
		var p: Dictionary = profili[i]
		if str(p.get("id", "")) == id:
			p["code"] = ""
			profili[i] = p
			d["profiles"] = profili
			_write(d)
			return true
	return false

# ---------------------------------------------------------------- gruppo

## Il codice del GRUPPO (registro dei giocatori) è più corto di quello di
## ripristino — tre lettere e tre cifre — e non per risparmiare caratteri: i due
## campi di testo stanno vicini nella stessa schermata, e le due cose fanno
## l'opposto. Un codice di ripristino SOVRASCRIVE un salvataggio; un codice
## gruppo mostra una tabella. Con la stessa forma, un bambino li scambierebbe e
## il primo errore sarebbe irreversibile. Con forme diverse, un codice sbagliato
## non passa nemmeno il controllo.
static func is_valid_group_code(codice: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[A-Z]{3}-[0-9]{3}$")
	return regex.search(codice.to_upper()) != null

static func generate_group_code(rng: RandomNumberGenerator = null) -> String:
	var r := rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	var codice := ""
	for _i in range(3):
		codice += ALPHABET[r.randi_range(0, ALPHABET.length() - 1)]
	codice += "-"
	for _i in range(3):
		codice += str(r.randi_range(0, 9))
	return codice

## Il gruppo è del DISPOSITIVO, non del singolo bambino: due fratelli sullo
## stesso tablet stanno nello stesso registro di classe o di famiglia. Ognuno ci
## compare con la propria scheda, perché la sigla di membro è per profilo.
static func group_code() -> String:
	return str(_read().get("group", ""))

static func set_group_code(codice: String) -> bool:
	var pulito := codice.to_upper().strip_edges()
	if not is_valid_group_code(pulito):
		return false
	bootstrap()
	var d := _read()
	d["group"] = pulito
	_write(d)
	return true

static func clear_group_code() -> void:
	var d := _read()
	if d.is_empty():
		return
	d["group"] = ""
	_write(d)

## La sigla con cui un profilo compare nel gruppo. Otto caratteri opachi, creati
## al primo bisogno e poi fissi: è ciò che permette a un bambino di aggiornare la
## PROPRIA riga senza poter toccare quella degli altri.
##
## Non è il codice di ripristino, e non deve diventarlo mai: quello apre e
## sovrascrive un salvataggio, e nel registro lo vedrebbe tutta la classe.
static func member_id_of(id: String) -> String:
	var esistente := str(find(id).get("member", ""))
	if not esistente.is_empty():
		return esistente
	var r := RandomNumberGenerator.new()
	r.randomize()
	var alfabeto := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var sigla := ""
	for _i in range(8):
		sigla += alfabeto[r.randi_range(0, alfabeto.length() - 1)]
	var d := _read()
	var profili: Array = Array(d.get("profiles", []))
	for i in range(profili.size()):
		var p: Dictionary = profili[i]
		if str(p.get("id", "")) == id:
			p["member"] = sigla
			profili[i] = p
			d["profiles"] = profili
			_write(d)
			return sigla
	return ""

## Assegna un codice a un profilo. Rifiuta una forma non valida e rifiuta un
## codice già in uso da un ALTRO profilo locale: due caselle sullo stesso tablet
## che puntano allo stesso salvataggio in cloud si sovrascriverebbero a vicenda
## ogni volta, che è esattamente il guasto da cui nasce tutto questo file.
static func set_code(id: String, codice: String) -> bool:
	var pulito := codice.to_upper().strip_edges()
	if not is_valid_code(pulito):
		return false
	for p in all():
		var altro: Dictionary = p
		if str(altro.get("id", "")) != id and str(altro.get("code", "")) == pulito:
			return false
	var d := _read()
	var profili: Array = Array(d.get("profiles", []))
	for i in range(profili.size()):
		var p: Dictionary = profili[i]
		if str(p.get("id", "")) == id:
			p["code"] = pulito
			profili[i] = p
			d["profiles"] = profili
			_write(d)
			return true
	return false
