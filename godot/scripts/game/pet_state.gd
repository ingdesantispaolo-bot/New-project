class_name PetState
extends RefCounted

## Stato del Custode: specie, nome, livrea, indole, volto a riposo, legame ed
## espressioni sbloccate. Vive nel salvataggio, sotto la chiave `pet`.
## Vedi docs/PET_CUSTODE.md.
##
## GUARDRAIL: il legame **sale e non scende mai**, in nessuna sequenza di eventi.
## Non esiste accudimento a decadimento, non esiste fame, non esiste trascuratezza.
## Un gioco che si studia non può punire chi torna dopo tre giorni, e un compagno
## che deperisce quando il bambino non gioca produce senso di colpa — che è
## esattamente ciò che spegne l'apprendimento.
##
## Il legame non sblocca vantaggi di gioco: solo espressioni e combinelle. Mai
## mastery, energia, aiuti o scorciatoie sul gate.

const DEFAULT := {
	"active": "pet-first",
	"name": "",
	"livery": [0xf6c85f, 0xffe3a8],
	"accessory": "",
	"temperament": "vivace",
	"restingFace": "sereno",
	"bond": 0.0,
	"faces": ["sereno", "orgoglioso", "incoraggiante", "festa", "beato"],
	"antics": [],
	"gifts": [],
	"sessionsTogether": 0,
	"grantedAtLevel": 0,
}

## Espressioni legate agli eventi del ciclo (risposta giusta, errore, traguardo,
## carezza) disponibili SUBITO: sono la reazione affettiva di base, e tenerle
## chiuse renderebbe il Custode piatto proprio nei minuti in cui il bambino gli
## si affeziona. Quelle che si sbloccano col legame sono le "extra": la lettura
## del mondo e la comicità, cioè il Custode che impara ad aiutarti.
const BOND_UNLOCKS := [
	{"bond": 0.18, "face": "curioso"},
	{"bond": 0.30, "face": "stupito"},
	{"bond": 0.42, "face": "concentrato"},
	{"bond": 0.54, "face": "coraggioso"},
	{"bond": 0.66, "face": "attento"},
	{"bond": 0.76, "face": "sollevato"},
	{"bond": 0.86, "face": "impicciato"},
	{"bond": 0.94, "face": "assonnato"},
	{"bond": 1.00, "face": "offeso"},
]

const MAX_NAME_LENGTH := 12
const BOND_PER_SESSION := 0.02
const BOND_PER_CUDDLE := 0.002
const CUDDLES_PER_SESSION := 10
const BASE_ANTICS := ["tail", "pose", "nap", "guard"]

const TEMPERAMENTS := ["vivace", "calmo", "buffo", "serio"]
const LIVERIES := [
	[0xf6c85f, 0xffe3a8],
	[0x6be7d6, 0xcffbf3],
	[0xc7b8ff, 0xeee9ff],
	[0xff8fa3, 0xffd6df],
]

# --- Accesso al salvataggio ----------------------------------------------------
# Migrazione non distruttiva e idempotente, come `GameSaveManager`: un salvataggio
# senza `pet` riceve i valori di default senza perdere chiavi sconosciute.
static func _pet(save) -> Dictionary:
	if not save.data.has("pet"):
		save.data["pet"] = DEFAULT.duplicate(true)
	var pet: Dictionary = save.data["pet"]
	for key in DEFAULT.keys():
		if not pet.has(key):
			pet[key] = DEFAULT[key] if typeof(DEFAULT[key]) != TYPE_ARRAY else Array(DEFAULT[key]).duplicate()
	return pet

static func is_granted(save) -> bool:
	return int(_pet(save).get("grantedAtLevel", 0)) > 0

## Consegna il primo Custode. Gratuito e presto: il volto sta sempre in schermo,
## quindi il giocatore non può guardare un buco per quattro livelli aspettando di
## potersi permettere un pet da 1500 di energia. Ritorna true solo la prima volta.
static func grant(save, level: int) -> bool:
	var pet := _pet(save)
	if int(pet.get("grantedAtLevel", 0)) > 0:
		return false
	pet["grantedAtLevel"] = maxi(1, level)
	return true

static func needs_name(save) -> bool:
	return is_granted(save) and str(_pet(save).get("name", "")).strip_edges() == ""

static func name_of(save) -> String:
	return str(_pet(save).get("name", ""))

## Il nome è la cosa che crea l'attaccamento, quindi si può cambiare sempre.
## Ritorna il nome effettivamente salvato (tagliato e ripulito).
##
## NON si chiama `set_name`: `Resource.set_name()` esiste già, e una chiamata
## statica su uno script (`PetState.set_name(...)`) si risolve su quella, con un
## errore a runtime che non compare in nessuna verifica statica.
static func set_pet_name(save, value: String) -> String:
	var clean := value.strip_edges()
	if clean.length() > MAX_NAME_LENGTH:
		clean = clean.substr(0, MAX_NAME_LENGTH).strip_edges()
	_pet(save)["name"] = clean
	return clean

static func temperament(save) -> String:
	return str(_pet(save).get("temperament", "vivace"))

static func resting_face(save) -> String:
	return str(_pet(save).get("restingFace", "sereno"))

static func livery(save) -> Array:
	return Array(_pet(save).get("livery", DEFAULT["livery"])).duplicate()

static func set_livery(save, value: Array) -> Array:
	if value.size() < 2:
		return livery(save)
	var candidate := [int(value[0]), int(value[1])]
	var allowed := false
	for palette in LIVERIES:
		if Array(palette) == candidate:
			allowed = true
			break
	if allowed:
		_pet(save)["livery"] = candidate
	return livery(save)

static func set_temperament(save, value: String) -> String:
	if TEMPERAMENTS.has(value):
		_pet(save)["temperament"] = value
	return temperament(save)

static func set_resting_face(save, value: String) -> String:
	# Il volto a riposo si può scegliere soltanto fra quelli già sbloccati: la
	# schermata non è una scorciatoia per il legame.
	if has_face(save, value):
		_pet(save)["restingFace"] = value
	return resting_face(save)

static func bond(save) -> float:
	return clampf(float(_pet(save).get("bond", 0.0)), 0.0, 1.0)

static func faces(save) -> Array:
	return Array(_pet(save).get("faces", [])).duplicate()

static func has_face(save, face: String) -> bool:
	return Array(_pet(save).get("faces", [])).has(face)

static func sessions_together(save) -> int:
	return int(_pet(save).get("sessionsTogether", 0))

static func antics(save) -> Array:
	var unlocked := Array(_pet(save).get("antics", [])).duplicate(true)
	for antic_id in BASE_ANTICS:
		if not unlocked.has(antic_id):
			unlocked.append(antic_id)
	return unlocked

static func gifts(save) -> Array:
	return Array(_pet(save).get("gifts", [])).duplicate(true)

## Registra una cosa che il Custode ha portato: cosa, dove e quando.
##
## Nessun regalo si perde e nessuno scade: la lista cresce e basta. Il mondo e la
## data non servono al gioco — servono a chi la rilegge a fine campagna, perché
## «un sasso, mondo 7» è un ricordo e «un sasso» non lo è.
static func register_gift(save, gift_id: String, world_id: int) -> Dictionary:
	if not PetGifts.CATALOG.has(gift_id):
		return {}
	var pet := _pet(save)
	var lista: Array = Array(pet.get("gifts", []))
	var voce := {
		"id": gift_id,
		"world": world_id,
		"date": Time.get_date_string_from_system(),
	}
	lista.append(voce)
	pet["gifts"] = lista
	return voce

# --- Legame -------------------------------------------------------------------
## Aumenta il legame e sblocca le espressioni raggiunte. `amount` negativo viene
## ignorato: il legame è monotono per contratto, non per convenzione.
## Ritorna le espressioni sbloccate da questa chiamata (per la celebrazione).
static func add_bond(save, amount: float) -> Array:
	if amount <= 0.0:
		return []
	var pet := _pet(save)
	pet["bond"] = clampf(float(pet.get("bond", 0.0)) + amount, 0.0, 1.0)
	# Le combinelle si sbloccano insieme alle facce. Il valore di ritorno resta
	# l'elenco delle sole espressioni: la celebrazione a schermo parla di quelle,
	# mentre una combinella nuova si deve scoprire vedendola, non leggendola in
	# un avviso.
	_sync_antics(save)
	return _sync_faces(save)

## Una sessione giocata con impegno, superata o no: conta aver provato. Il legame
## non si compra e non dipende dall'esito, altrimenti sbagliare costerebbe anche
## l'affetto del compagno.
static func register_session(save) -> Array:
	var pet := _pet(save)
	pet["sessionsTogether"] = int(pet.get("sessionsTogether", 0)) + 1
	return add_bond(save, BOND_PER_SESSION)

static func register_cuddle(save) -> Array:
	return add_bond(save, BOND_PER_CUDDLE)

## Combinelle raggiunte dal legame corrente. Il catalogo e le soglie vivono in
## `PetAntics`: qui si legge soltanto, così un repertorio nuovo non richiede di
## toccare il salvataggio.
static func _sync_antics(save) -> Array:
	var pet := _pet(save)
	var current: Array = Array(pet.get("antics", []))
	var unlocked: Array = []
	var value := float(pet.get("bond", 0.0))
	for step in PetAntics.BOND_UNLOCKS:
		var antic := str(step["antic"])
		if value + 0.0001 >= float(step["bond"]) and not current.has(antic):
			current.append(antic)
			unlocked.append(antic)
	pet["antics"] = current
	return unlocked

static func _sync_faces(save) -> Array:
	var pet := _pet(save)
	var current: Array = Array(pet.get("faces", []))
	var unlocked: Array = []
	var value := float(pet.get("bond", 0.0))
	for step in BOND_UNLOCKS:
		var face := str(step["face"])
		if value + 0.0001 >= float(step["bond"]) and not current.has(face):
			current.append(face)
			unlocked.append(face)
	pet["faces"] = current
	return unlocked

## Tutte le espressioni raggiungibili, per l'album della schermata Custode.
static func all_faces() -> Array:
	var out: Array = Array(DEFAULT["faces"]).duplicate()
	for step in BOND_UNLOCKS:
		out.append(str(step["face"]))
	return out
