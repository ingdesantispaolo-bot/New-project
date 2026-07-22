class_name ShipRoomCatalog
extends RefCounted

## Registro data-driven dei ponti del Relitto. La scena nave è unica: cambiare
## stanza sostituisce dati, sfondo e stato dell'apparato senza duplicare logica.

const DEFAULT_ROOM := "central"

const ROOM_ORDER := [
	"central", "bio", "reactor", "command", "resonance", "data_core", "glyphs",
]

const ROOMS := {
	"central": {
		"label": "Ponte Centrale",
		"short": "CENTRALE",
		"texture": "res://assets/ship/academy-action-room-bg.webp",
		"accent": "6be7d6",
		"apparatus": "nucleo",
		"restoration": "decor-laboratorio",
		"subjects": ["matematica", "coding", "logica"],
		"description": "Nodo di navigazione, diagnosi e coordinamento del Relitto.",
	},
	"bio": {
		"label": "Bio-ponte",
		"short": "BIO-PONTE",
		"texture": "res://assets/ship/area-bio-ponte-primi.webp",
		"accent": "7cf6a6",
		"apparatus": "serra-bio",
		"restoration": "decor-serra",
		"subjects": ["scienze", "cittadinanza"],
		"description": "Ecosistemi, osservazione e sistemi di supporto vitale.",
	},
	"reactor": {
		"label": "Reattore",
		"short": "REATTORE",
		"texture": "res://assets/ship/area-reattore-primi.webp",
		"accent": "f6c85f",
		"apparatus": "reattore",
		"restoration": "decor-circuiti",
		"subjects": ["elettronica", "fisica"],
		"description": "Energia, condotti, misure e protezione dei sistemi.",
	},
	"command": {
		"label": "Ponte di Comando",
		"short": "COMANDO",
		"texture": "res://assets/ship/area-ponte-comando-primi.webp",
		"accent": "9f8cff",
		"apparatus": "ponte-comando",
		"restoration": "decor-osservatorio",
		"subjects": ["geografia", "fisica"],
		"description": "Rotte, mappe stellari, segnali e modelli del movimento.",
	},
	"resonance": {
		"label": "Motore a Risonanza",
		"short": "RISONANZA",
		"texture": "res://assets/ship/area-motore-risonanza-primi.webp",
		"accent": "ff9d5c",
		"apparatus": "motore-risonanza",
		"restoration": "decor-musica",
		"subjects": ["musica", "matematica"],
		"description": "Onde, ritmo e frequenze che stabilizzano la propulsione.",
	},
	"data_core": {
		"label": "Data-core",
		"short": "DATA-CORE",
		"texture": "res://assets/ship/area-data-core-primi.webp",
		"accent": "7ad7ff",
		"apparatus": "data-core",
		"restoration": "decor-archivio",
		"subjects": ["italiano", "inglese", "coding"],
		"description": "Memoria, lingue, registri e protocolli della nave.",
	},
	"glyphs": {
		"label": "Sala dei Glifi",
		"short": "GLIFI",
		"texture": "res://assets/ship/area-sala-glifi-primi.webp",
		"accent": "d8a24a",
		"apparatus": "sala-glifi",
		"restoration": "decor-biblioteca-classica",
		"subjects": ["latino", "italiano", "logica"],
		"description": "Lingua dei Primi, radici, simboli e deduzioni.",
	},
}

static func room(id: String) -> Dictionary:
	return Dictionary(ROOMS.get(id, ROOMS[DEFAULT_ROOM])).duplicate(true)

static func ids() -> Array:
	return ROOM_ORDER.duplicate()

static func room_for_apparatus(apparatus: String) -> String:
	for id in ROOM_ORDER:
		if str(ROOMS[id].get("apparatus", "")) == apparatus:
			return str(id)
	return DEFAULT_ROOM

static func room_for_subject(subject: String) -> String:
	for id in ROOM_ORDER:
		if Array(ROOMS[id].get("subjects", [])).has(subject):
			return str(id)
	return DEFAULT_ROOM
