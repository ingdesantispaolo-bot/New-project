class_name EmblemPromises
extends RefCounted

## Gli emblemi non certificano potere: dichiarano un metodo e aspettano tre
## fatti distinti che lo testimonino. Nessuna promessa concede ricompense.

const PROMISES := {
	"emblem-star": {
		"title": "Promessa della Costanza",
		"statement": "Portare a termine il viaggio in tre mondi distinti senza chiedere all'emblema di rendere la strada piu' facile.",
		"evidence": "mondi attraversati", "events": ["expedition"],
		"required": 3, "distinctWorlds": true,
		"completion": "La Stella testimonia che la costanza e' una serie di ritorni, non un talento istantaneo.",
	},
	"emblem-bolt": {
		"title": "Promessa della Precisione",
		"statement": "Affrontare tre ostacoli o campi con un gesto appropriato e osservabile.",
		"evidence": "gesti precisi", "events": ["tool_use", "hazard"],
		"required": 3, "distinctWorlds": false,
		"completion": "Il Fulmine testimonia che agire in fretta conta soltanto quando il gesto e' preciso.",
	},
	"emblem-crown": {
		"title": "Promessa del Coordinamento",
		"statement": "Concludere tre riparazioni affidate dagli abitanti, conservando chi ne aveva bisogno.",
		"evidence": "riparazioni coordinate", "events": ["minimission"],
		"required": 3, "distinctWorlds": false,
		"completion": "La Corona testimonia un servizio reso insieme, non un grado sopra gli altri.",
	},
	"emblem-atom": {
		"title": "Promessa dell'Osservazione",
		"statement": "Osservare tre reperti o ritrovamenti prima di trasformarli in possesso.",
		"evidence": "osservazioni", "events": ["treasure", "mystery"],
		"required": 3, "distinctWorlds": false,
		"completion": "L'Atomo testimonia che prima dell'intervento c'e' stata un'osservazione.",
	},
	"emblem-scroll": {
		"title": "Promessa delle Fonti",
		"statement": "Leggere tracce in tre mondi distinti e conservarne la provenienza.",
		"evidence": "mondi documentati", "events": ["mystery"],
		"required": 3, "distinctWorlds": true,
		"completion": "La Pergamena testimonia che una fonte senza provenienza e' soltanto una frase.",
	},
}

static func promise(id: String) -> Dictionary:
	return Dictionary(PROMISES.get(id, {})).duplicate(true)

static func ids() -> Array:
	return PROMISES.keys().duplicate()

static func progress(id: String, state: Dictionary) -> Dictionary:
	var spec := promise(id)
	if spec.is_empty():
		return {}
	var accepted: Array = Array(spec.get("events", []))
	var distinct_worlds := bool(spec.get("distinctWorlds", false))
	var evidence: Dictionary = {}
	for signature_data in Array(state.get("events", [])):
		var signature := str(signature_data)
		var pieces := signature.split(":", false, 2)
		if pieces.size() < 2 or not accepted.has(str(pieces[0])):
			continue
		var key := "world-%s" % str(pieces[1]) if distinct_worlds else signature
		evidence[key] = true
	var required := int(spec.get("required", 3))
	var count := evidence.size()
	return {
		"count": count,
		"required": required,
		"stage": mini(count, required),
		"complete": count >= required,
		"evidence": str(spec.get("evidence", "testimonianze")),
		"title": str(spec.get("title", "Promessa")),
		"completion": str(spec.get("completion", "")),
	}

static func status(id: String, state: Dictionary) -> String:
	var p := progress(id, state)
	if p.is_empty():
		return ""
	return "%s %d/%d" % [
		str(p.get("evidence", "testimonianze")),
		int(p.get("stage", 0)), int(p.get("required", 3)),
	]
