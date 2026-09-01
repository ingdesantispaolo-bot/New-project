class_name ProgressRecognition
extends RefCounted

## Il ritratto complessivo del percorso di Eli.
##
## Non e' una valuta, non apre gate e non giudica il rendimento. Registra forme
## diverse di progresso senza ridurle a un punteggio unico. In ogni mondo una
## via puo' accendersi una volta sola: ripetere resta utile per imparare e per le
## ricompense proprie dell'attivita', ma non permette di gonfiare il ritratto.

const COMPRENDERE := "comprendere"
const COSTRUIRE := "costruire"
const ESPLORARE := "esplorare"
const LEGAMI := "legami"

const PATH_ORDER := [COMPRENDERE, COSTRUIRE, ESPLORARE, LEGAMI]
const PATHS := {
	COMPRENDERE: {
		"name": "Comprendere", "glyph": "?", "color": "7ad7ff",
		"description": "Idee allenate, applicate e consolidate.",
	},
	COSTRUIRE: {
		"name": "Costruire", "glyph": "+", "color": "f6c85f",
		"description": "Missioni, enigmi e riparazioni che cambiano un luogo.",
	},
	ESPLORARE: {
		"name": "Esplorare", "glyph": "*", "color": "c7b8ff",
		"description": "Pericoli, tracce e ritrovamenti fuori dalla strada breve.",
	},
	LEGAMI: {
		"name": "Creare legami", "glyph": "o", "color": "8ff6d2",
		"description": "Persone e compagni aiutati lungo il viaggio.",
	},
}

## Ogni attivita' conserva il proprio nome, ma contribuisce a una delle quattro
## vie. Nessuna voce assegna frammenti, energia o padronanza: quelli restano ai
## sistemi che sanno perche' li stanno concedendo.
const KIND_PATH := {
	"practice": COMPRENDERE,
	"mission": COMPRENDERE,
	"final_exam": COMPRENDERE,
	"topic": COMPRENDERE,
	"enigma": COSTRUIRE,
	"minimission": COSTRUIRE,
	"apparatus": COSTRUIRE,
	"hazard": ESPLORARE,
	"treasure": ESPLORARE,
	"mystery": ESPLORARE,
	"parchment": ESPLORARE,
	"enemy": ESPLORARE,
	"den": ESPLORARE,
	"resident": LEGAMI,
	"work": LEGAMI,
	"pet_gift": LEGAMI,
}

const KIND_LABEL := {
	"practice": "Pratica portata a termine",
	"mission": "Missione completata",
	"final_exam": "Esame superato",
	"topic": "Argomento consolidato",
	"enigma": "Enigma ricostruito",
	"minimission": "Un luogo riparato",
	"apparatus": "Apparato riattivato",
	"hazard": "Pericolo del mondo superato",
	"treasure": "Ritrovamento custodito",
	"mystery": "Traccia compresa",
	"parchment": "Pergamena ritrovata",
	"enemy": "Varco liberato",
	"den": "Spedizione del Custode",
	"resident": "Abitante aiutato",
	"work": "Turno al Ritrovo",
	"pet_gift": "Ricordo del Custode",
}

## Traguardi di ampiezza: contano le facce mondo-via, non il numero grezzo di
## azioni. Il massimo e' 24 mondi x 4 vie = 96. Sono titoli, quindi testimoniano
## il percorso senza alterare le prove o competere con la bottega.
const MILESTONES := [
	{"facets": 4, "id": "primo-segno", "title": "Primo Segno"},
	{"facets": 12, "id": "carta-accesa", "title": "Carta Accesa"},
	{"facets": 24, "id": "viandante", "title": "Viandante dei Mondi"},
	{"facets": 48, "id": "custode-rotte", "title": "Custode delle Rotte"},
	{"facets": 72, "id": "costellazione", "title": "Costellazione Viva"},
	{"facets": 96, "id": "quattro-vie", "title": "Eli delle Quattro Vie"},
]

const RECENT_MAX := 20

static func default_state() -> Dictionary:
	return {
		"claimed": {},
		"byKind": {},
		"byWorld": {},
		"milestones": [],
		"recent": [],
	}

static func _state(save) -> Dictionary:
	if not save.data.has("recognition") or typeof(save.data["recognition"]) != TYPE_DICTIONARY:
		save.data["recognition"] = default_state()
	var state: Dictionary = save.data["recognition"]
	var defaults := default_state()
	for key in defaults:
		if not state.has(key) or typeof(state[key]) != typeof(defaults[key]):
			state[key] = defaults[key].duplicate(true)
	save.data["recognition"] = state
	return state

static func path_for(kind: String) -> String:
	return str(KIND_PATH.get(kind, ""))

static func path_card(path: String) -> Dictionary:
	return Dictionary(PATHS.get(path, {})).duplicate(true)

## Registra una prova di percorso. Dizionario vuoto significa che era gia' stata
## riconosciuta oppure che il tipo non appartiene al sistema.
static func record(
		save, kind: String, event_id: String, world_level: int,
		details: Dictionary = {}) -> Dictionary:
	var path := path_for(kind)
	if path.is_empty() or event_id.strip_edges().is_empty():
		return {}
	var world := clampi(world_level, 1, 24)
	var state := _state(save)
	var claim_key := "%02d:%s:%s" % [world, kind, event_id]
	var claimed: Dictionary = state.get("claimed", {})
	if claimed.has(claim_key):
		return {}
	claimed[claim_key] = true
	state["claimed"] = claimed

	var by_kind: Dictionary = state.get("byKind", {})
	by_kind[kind] = int(by_kind.get(kind, 0)) + 1
	state["byKind"] = by_kind

	var by_world: Dictionary = state.get("byWorld", {})
	var world_key := str(world)
	var world_row: Dictionary = Dictionary(by_world.get(world_key, {
		"paths": [], "counts": {},
	})).duplicate(true)
	var paths: Array = Array(world_row.get("paths", [])).duplicate()
	var new_facet := not paths.has(path)
	if new_facet:
		paths.append(path)
	world_row["paths"] = paths
	var counts: Dictionary = Dictionary(world_row.get("counts", {})).duplicate()
	counts[kind] = int(counts.get(kind, 0)) + 1
	world_row["counts"] = counts
	by_world[world_key] = world_row
	state["byWorld"] = by_world

	var entry := {
		"kind": kind,
		"path": path,
		"world": world,
		"label": str(details.get("label", KIND_LABEL.get(kind, "Progresso riconosciuto"))),
		"subject": str(details.get("subject", "")),
		"newFacet": new_facet,
	}
	var recent: Array = Array(state.get("recent", [])).duplicate(true)
	recent.push_front(entry.duplicate(true))
	if recent.size() > RECENT_MAX:
		recent.resize(RECENT_MAX)
	state["recent"] = recent

	var before_milestones: Array = Array(state.get("milestones", [])).duplicate()
	var milestones := before_milestones.duplicate()
	var total := _facet_total_from_worlds(by_world)
	var unlocked: Array = []
	for row_data in MILESTONES:
		var row: Dictionary = row_data
		var id := str(row["id"])
		if total >= int(row["facets"]) and not milestones.has(id):
			milestones.append(id)
			unlocked.append(row.duplicate(true))
	state["milestones"] = milestones
	save.data["recognition"] = state

	var card := path_card(path)
	entry["pathName"] = str(card.get("name", path.capitalize()))
	entry["glyph"] = str(card.get("glyph", "*"))
	entry["color"] = str(card.get("color", "ffffff"))
	entry["facetTotal"] = total
	entry["milestones"] = unlocked
	return entry

static func summary(save) -> Dictionary:
	var state := _state(save)
	var by_world: Dictionary = state.get("byWorld", {})
	var paths_out: Array = []
	for path_data in PATH_ORDER:
		var path := str(path_data)
		var worlds: Array = []
		for world_key in by_world:
			if Array(Dictionary(by_world[world_key]).get("paths", [])).has(path):
				worlds.append(int(world_key))
		worlds.sort()
		var card := path_card(path)
		card["id"] = path
		card["worlds"] = worlds
		card["count"] = worlds.size()
		paths_out.append(card)
	return {
		"facets": _facet_total_from_worlds(by_world),
		"maximum": 96,
		"paths": paths_out,
		"byKind": Dictionary(state.get("byKind", {})).duplicate(true),
		"milestones": Array(state.get("milestones", [])).duplicate(),
		"title": current_title(state),
		"recent": Array(state.get("recent", [])).duplicate(true),
	}

static func current_title(state: Dictionary) -> String:
	var unlocked: Array = Array(state.get("milestones", []))
	var title := "In Cammino"
	for row_data in MILESTONES:
		var row: Dictionary = row_data
		if unlocked.has(str(row["id"])):
			title = str(row["title"])
	return title

static func _facet_total_from_worlds(by_world: Dictionary) -> int:
	var total := 0
	for row_data in by_world.values():
		total += Array(Dictionary(row_data).get("paths", [])).size()
	return total
