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
	{"bond": 0.25, "face": "curioso"},
	{"bond": 0.45, "face": "concentrato"},
	{"bond": 0.65, "face": "attento"},
	{"bond": 0.85, "face": "impicciato"},
	{"bond": 1.00, "face": "offeso"},
]

const MAX_NAME_LENGTH := 12
const BOND_PER_SESSION := 0.02
const BOND_PER_CUDDLE := 0.002
const CUDDLES_PER_SESSION := 10

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

static func bond(save) -> float:
	return clampf(float(_pet(save).get("bond", 0.0)), 0.0, 1.0)

static func faces(save) -> Array:
	return Array(_pet(save).get("faces", [])).duplicate()

static func has_face(save, face: String) -> bool:
	return Array(_pet(save).get("faces", [])).has(face)

static func sessions_together(save) -> int:
	return int(_pet(save).get("sessionsTogether", 0))

# --- Legame -------------------------------------------------------------------
## Aumenta il legame e sblocca le espressioni raggiunte. `amount` negativo viene
## ignorato: il legame è monotono per contratto, non per convenzione.
## Ritorna le espressioni sbloccate da questa chiamata (per la celebrazione).
static func add_bond(save, amount: float) -> Array:
	if amount <= 0.0:
		return []
	var pet := _pet(save)
	pet["bond"] = clampf(float(pet.get("bond", 0.0)) + amount, 0.0, 1.0)
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
