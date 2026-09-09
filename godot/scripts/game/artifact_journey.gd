class_name ArtifactJourney
extends RefCounted

## Memoria d'uso degli oggetti della bottega.
##
## Il catalogo dice che cosa un oggetto e'; questa classe dice che cosa fa e
## conserva dove e' stato usato. Non concede ricompense e non legge o scrive
## alcuno stato didattico. Vedi docs/PIANO_BOTTEGA_OGGETTI_VIVI.md.

const SAVE_KEY := "artifactJourney"
const ITEM_KEY := "items"
const RESONANCE_KEY := "resonances"
const ACCESSORY_FIELD_ACTIONS := preload("res://scripts/game/accessory_field_actions.gd")
const PET_FIELD_METHODS := preload("res://scripts/game/pet_field_methods.gd")
const EMBLEM_PROMISES := preload("res://scripts/game/emblem_promises.gd")
const OUTFIT_SOCIAL_ECHOES := preload("res://scripts/game/outfit_social_echoes.gd")
const SHIP_LABORATORIES := preload("res://scripts/game/ship_laboratories.gd")
const MEMENTO_RESONANCES := preload("res://scripts/game/memento_resonances.gd")

const PATINA_WORLDS := [1, 3, 6]

const FAMILY_METHODS := {
	"bot": "osservare e registrare",
	"avatar": "abitare il viaggio",
	"accessory": "agire sul campo",
	"tool": "riaprire una deviazione",
	"pet": "esplorare insieme",
	"emblem": "dichiarare un metodo",
	"module": "preparare la spedizione",
	"upgrade": "ricostruire la memoria di NORA",
	"decor": "restituire una funzione alla nave",
	"memento": "collegare due mondi",
}

const FAMILY_VERBS := {
	"bot": "registrare",
	"avatar": "attraversare",
	"accessory": "usare",
	"tool": "aprire",
	"pet": "cercare",
	"emblem": "testimoniare",
	"module": "preparare",
	"upgrade": "ricordare",
	"decor": "riabitare",
	"memento": "risuonare",
}

const FAMILY_EVENTS := {
	"bot": ["expedition", "minimission"],
	"avatar": ["expedition", "minimission"],
	"accessory": ["expedition", "treasure", "mystery", "hazard"],
	"tool": ["tool_use"],
	"pet": ["expedition", "den", "treasure", "mystery"],
	"emblem": ["expedition", "minimission", "treasure", "mystery"],
	"module": ["expedition", "treasure", "hazard"],
	"upgrade": ["purchase", "minimission", "mystery", "ship_room"],
	"decor": ["ship_room"],
	"memento": ["expedition", "resonance", "mystery"],
}

## Condizioni specifiche: due oggetti della stessa famiglia non devono
## accumulare la stessa biografia per inerzia. L'evento resta descrittivo e non
## modifica mai il suo esito.
const EVENTS := {
	"avatar-pilot": ["expedition"],
	"avatar-engineer": ["minimission"],
	"avatar-captain": ["minimission", "expedition"],
	"avatar-shadow": ["hazard", "expedition"],
	"avatar-astral": ["resonance", "expedition"],
	"accessory-visor": ["treasure", "mystery"],
	"accessory-scarf": ["expedition", "resonance", "mystery"],
	"accessory-compass": ["expedition", "treasure"],
	"accessory-pack": ["expedition", "treasure"],
	"accessory-crown": ["minimission"],
	"accessory-antenna": ["mystery", "hazard"],
	"accessory-wings": ["hazard"],
	"accessory-jetpack": ["expedition", "tool_use"],
	"accessory-halo": ["resonance", "mystery"],
	"pet-dog": ["den", "treasure"],
	"pet-cat": ["den", "mystery"],
	"pet-rabbit": ["den"],
	"pet-spark": ["mystery", "hazard"],
	"pet-comet": ["expedition", "mystery"],
	"pet-orbit": ["mystery"],
	"pet-satellite": ["treasure", "mystery"],
	"pet-prisma": ["resonance", "mystery"],
	"pet-luma": ["hazard", "mystery"],
	"pet-guardiano": ["hazard"],
	"pet-codex": ["mystery", "minimission"],
	"emblem-star": ["expedition"],
	"emblem-bolt": ["hazard", "tool_use"],
	"emblem-crown": ["minimission"],
	"emblem-atom": ["treasure", "mystery"],
	"emblem-scroll": ["mystery"],
	"module-hush": ["hazard"],
	"module-ballast": ["hazard"],
	"module-stride": ["expedition"],
	"module-lantern": ["expedition", "mystery"],
	"module-divining": ["treasure"],
	"module-ledger": ["treasure"],
	"nora-lens": ["ship_room", "minimission", "mystery"],
	"nora-reserve": ["ship_room", "mystery"],
	"nora-shield": ["ship_room", "hazard"],
	"nora-prismatic-core": ["ship_room", "resonance"],
}

const VERBS := {
	"accessory-visor": "osservare",
	"accessory-scarf": "sincronizzare",
	"accessory-compass": "segnare",
	"accessory-pack": "conservare",
	"accessory-crown": "ricostruire",
	"accessory-antenna": "ascoltare",
	"accessory-wings": "stabilizzare",
	"accessory-jetpack": "superare",
	"accessory-halo": "collegare",
	"tool-torch": "rivelare",
	"tool-scythe": "liberare",
	"tool-lever": "sollevare",
	"tool-lens": "mettere a fuoco",
	"tool-bellows": "disperdere",
	"pet-dog": "fiutare",
	"pet-cat": "raggiungere",
	"pet-rabbit": "infilarsi",
	"pet-spark": "riaccendere",
	"pet-comet": "ripercorrere",
	"pet-orbit": "circondare",
	"pet-satellite": "osservare oltre",
	"pet-prisma": "rifrangere",
	"pet-luma": "rivelare al buio",
	"pet-guardiano": "restare",
	"pet-codex": "ascoltare",
	"emblem-star": "perseverare",
	"emblem-bolt": "agire con precisione",
	"emblem-crown": "coordinare",
	"emblem-atom": "osservare prima di cambiare",
	"emblem-scroll": "confrontare le fonti",
	"module-hush": "passare inosservata",
	"module-ballast": "tenere la posizione",
	"module-stride": "coprire distanza",
	"module-lantern": "dirigere la luce",
	"module-divining": "segnalare i forzieri",
	"module-ledger": "registrare gli scambi",
	"nora-lens": "collegare causa ed effetto",
	"nora-reserve": "conservare una voce",
	"nora-shield": "custodire una memoria",
	"nora-prismatic-core": "riunire dodici sistemi",
	"decor-laboratorio": "provare",
	"decor-serra": "coltivare",
	"decor-circuiti": "configurare",
	"decor-osservatorio": "orientare",
	"decor-musica": "riascoltare",
	"decor-archivio": "ordinare",
	"decor-biblioteca-classica": "interpretare",
}

const USES := {
	"avatar-gold": "La tuta di parata conserva i luoghi in cui Eli ha scelto di usarla davvero.",
	"avatar-violet": "La tuta notturna accumula segni dei mondi attraversati e delle riparazioni compiute.",
	"avatar-emerald": "La tuta della Serra conserva polline e patina dei luoghi visitati.",
	"avatar-crimson": "La tuta delle Officine conserva i segni delle riparazioni sul campo.",
	"avatar-nebula": "La tuta dei segnali conserva le rotte percorse fra mondi lontani.",
	"avatar-aurora": "La tuta da viaggio lungo rende visibile quante destinazioni ha attraversato.",
	"avatar-pilot": "Registra le rotte percorse mentre Eli porta il ruolo di Pilota.",
	"avatar-engineer": "Registra le riparazioni concluse mentre Eli porta il ruolo di Ingegnere.",
	"avatar-captain": "Registra spedizioni e riparazioni coordinate nel ruolo di Capitano.",
	"avatar-shadow": "Registra gli attraversamenti dei campi del Silenzio senza renderli piu' facili.",
	"avatar-astral": "Registra le risonanze fra sistemi incontrate durante le spedizioni.",
	"accessory-visor": "Registra le relazioni osservate presso reperti, tracce e forzieri.",
	"accessory-scarf": "Conserva il ritmo di un luogo e lo fa risuonare nel suo mondo gemello.",
	"accessory-compass": "Conserva le deviazioni scelte e i punti ritrovati durante le spedizioni.",
	"accessory-pack": "Tiene insieme campioni e reperti incontrati nella stessa spedizione.",
	"accessory-crown": "Ricostruisce il metodo di una riparazione gia' portata a termine.",
	"accessory-antenna": "Raccoglie segnali deboli vicino a tracce, tesori e campi instabili.",
	"accessory-wings": "Registra gli attraversamenti compiuti contro correnti e campi instabili.",
	"accessory-jetpack": "Segna le deviazioni raggiunte fuori dal percorso principale.",
	"accessory-halo": "Riconosce i luoghi in cui due sistemi diversi condividono lo stesso metodo.",
	"tool-torch": "Rivela deviazioni schermate dall'oscurita' e ricorda dove e' stata usata.",
	"tool-scythe": "Libera deviazioni coperte dall'erba alta e ricorda dove e' stata usata.",
	"tool-lever": "Solleva le lastre opzionali dei Primi e ricorda dove e' stata usata.",
	"tool-lens": "Rende leggibili iscrizioni opzionali e ricorda dove e' stata usata.",
	"tool-bellows": "Disperde il Silenzio denso dalle deviazioni e ricorda dove e' stato usato.",
	"pet-dog": "Il Custode segue tracce basse e tane con il fiuto.",
	"pet-cat": "Il Custode osserva bordi, mensole e passaggi alti.",
	"pet-rabbit": "Il Custode affronta tane e fessure con un salto breve.",
	"pet-spark": "Il Custode reagisce agli oggetti che hanno perso la propria luce.",
	"pet-comet": "Il Custode ripercorre traiettorie interrotte nel terreno.",
	"pet-orbit": "Il Custode gira attorno ai reperti per mostrarne il contorno.",
	"pet-satellite": "Il Custode osserva oltre gli ostacoli senza indicare obiettivi obbligatori.",
	"pet-prisma": "Il Custode rifrange la luce dei Ricordi portati da Eli.",
	"pet-luma": "Il Custode rende leggibile la propria presenza nelle zone scure.",
	"pet-guardiano": "Il Custode resta accanto alle zone sbiadite invece di fuggire.",
	"pet-codex": "Il Custode ascolta iscrizioni, registri e oggetti di memoria.",
	"emblem-star": "Tiene memoria delle spedizioni affrontate con continuita'.",
	"emblem-bolt": "Tiene memoria degli ostacoli risolti con un gesto preciso.",
	"emblem-crown": "Tiene memoria delle riparazioni compiute insieme agli abitanti.",
	"emblem-atom": "Tiene memoria dei reperti osservati prima di intervenire.",
	"emblem-scroll": "Tiene memoria delle tracce e delle fonti confrontate.",
	"module-hush": "Lascia una traccia quando la bardatura affronta il raggio delle sacche.",
	"module-ballast": "Lascia una traccia quando la bardatura attraversa un campo che respinge.",
	"module-stride": "Conta i mondi attraversati portando il passo da spedizione.",
	"module-lantern": "Registra le spedizioni in cui la torcia ha proiettato il suo cono.",
	"module-divining": "Registra i forzieri incontrati mentre il rabdomante era in bardatura.",
	"module-ledger": "Registra i forzieri scambiati mentre il taccuino era in bardatura.",
	"nora-lens": "Conserva le riparazioni e le tracce in cui NORA collega causa ed effetto.",
	"nora-reserve": "Conserva le visite in cui una voce della nave torna leggibile.",
	"nora-shield": "Conserva le memorie affrontate senza cancellarne la crepa.",
	"nora-prismatic-core": "Riunisce le risonanze fra i dodici sistemi in un ritratto della campagna.",
	"decor-laboratorio": "Rende il Ponte Centrale un banco per osservare strumenti e configurazioni.",
	"decor-serra": "Rende il Bio-ponte il luogo in cui conservare campioni del viaggio.",
	"decor-circuiti": "Rende il Reattore il banco della bardatura di spedizione.",
	"decor-osservatorio": "Rende il Ponte di Comando il luogo delle rotte e dei ritorni.",
	"decor-musica": "Rende il Motore a Risonanza il luogo delle memorie sonore.",
	"decor-archivio": "Rende il Data-core il luogo delle testimonianze raccolte.",
	"decor-biblioteca-classica": "Rende la Sala dei Glifi il luogo delle iscrizioni e delle radici.",
}

const TRACE_LABELS := {
	"bot": "Sistemi registrati",
	"avatar": "Patina di viaggio",
	"accessory": "Azioni sul campo",
	"tool": "Varchi riaperti",
	"pet": "Esplorazioni insieme",
	"emblem": "Promessa testimoniata",
	"module": "Spedizioni preparate",
	"upgrade": "Memoria ricostruita",
	"decor": "Stanza riabitata",
	"memento": "Mondi collegati",
}

static func is_memento(item_or_id) -> bool:
	var item: Dictionary = RewardCatalog.find(str(item_or_id)) \
		if typeof(item_or_id) == TYPE_STRING else Dictionary(item_or_id)
	return int(item.get("requiresHazardWorld", 0)) > 0

static func family_of(item: Dictionary) -> String:
	return "memento" if is_memento(item) else str(item.get("slot", ""))

static func profile(item_or_id) -> Dictionary:
	var item: Dictionary = RewardCatalog.find(str(item_or_id)) \
		if typeof(item_or_id) == TYPE_STRING else Dictionary(item_or_id)
	if item.is_empty():
		return {}
	var id := str(item.get("id", ""))
	var family := family_of(item)
	var source_world := int(item.get("requiresHazardWorld", item.get("mondo", 0)))
	var verb := str(VERBS.get(id, FAMILY_VERBS.get(family, "usare")))
	var method := str(FAMILY_METHODS.get(family, "restituire significato"))
	if source_world > 0:
		method = "%s · %s" % [method, ApparatusConfig.world_subject(source_world)]
	var use_text := str(USES.get(id, ""))
	if use_text.is_empty():
		match family:
			"bot":
				use_text = "Bit registra con questa livrea i mondi in cui agisce per NORA. Il colore ritorna nell'interfaccia di supporto."
			"avatar":
				use_text = "La tuta accumula patina nei mondi visitati e conserva la strada percorsa da Eli."
			"memento":
				use_text = "Il Ricordo reagisce nel mondo gemello e conserva il collegamento fra i due luoghi."
			_:
				use_text = "L'oggetto conserva i luoghi e gli eventi in cui viene usato."
	var events: Array = Array(EVENTS.get(
		id, FAMILY_EVENTS.get(family, ["expedition"]))).duplicate()
	var field_action := ACCESSORY_FIELD_ACTIONS.action(id)
	if not field_action.is_empty() and not events.has("accessory_action"):
		events.append("accessory_action")
	if not field_action.is_empty():
		use_text += " Equipaggiato, apre in ogni mondo la rotta facoltativa «%s» in tre tappe." % str(
			field_action.get("title", "azione sul campo"))
	var pet_method := PET_FIELD_METHODS.method(id)
	if not pet_method.is_empty() and not events.has("den"):
		events.append("den")
	if not pet_method.is_empty():
		use_text += " Nelle tane applica il metodo «%s»: cambia il percorso osservabile, mai l'esito." % str(
			pet_method.get("title", "esplorazione"))
	var emblem_promise := EMBLEM_PROMISES.promise(id)
	if not emblem_promise.is_empty():
		use_text += " %s Richiede tre testimonianze e non concede premi." % str(
			emblem_promise.get("statement", "Dichiara un metodo osservabile."))
	var social_echo := OUTFIT_SOCIAL_ECHOES.echo(id)
	if not social_echo.is_empty() and not events.has("social_echo"):
		events.append("social_echo")
	if not social_echo.is_empty():
		use_text += " Gli abitanti riconoscono una volta il ruolo «%s» e leggono diversamente i tre stadi di patina." % str(
			social_echo.get("title", "viaggiatore"))
	var laboratory_room := SHIP_LABORATORIES.room_for_decor(id)
	if not laboratory_room.is_empty() and not events.has(SHIP_LABORATORIES.EVENT_KIND):
		events.append(SHIP_LABORATORIES.EVENT_KIND)
	if not laboratory_room.is_empty():
		var laboratory := SHIP_LABORATORIES.laboratory(laboratory_room)
		use_text += " Nella stanza restaurata apre «%s»: tre decisioni senza risposta giusta producono una sintesi sostituibile." % str(
			laboratory.get("title", "laboratorio"))
	var resonance_contract := MEMENTO_RESONANCES.resonance(id)
	if not resonance_contract.is_empty():
		use_text += " Nel mondo gemello chiede il gesto «%s» e lascia la traccia «%s»." % [
			str(resonance_contract.get("action", "FAI RISUONARE")),
			str(resonance_contract.get("trace", "legame conservato"))]
	return {
		"id": id,
		"family": family,
		"verb": verb,
		"method": method,
		"use": use_text,
		"events": events,
		"sourceWorld": source_world,
		"resonanceWorld": resonance_world(item),
		"trace": str(TRACE_LABELS.get(family, "Traccia d'uso")),
	}

static func resonance_world(item_or_id) -> int:
	var item: Dictionary = RewardCatalog.find(str(item_or_id)) \
		if typeof(item_or_id) == TYPE_STRING else Dictionary(item_or_id)
	if not is_memento(item):
		return 0
	var source := int(item.get("requiresHazardWorld", 0))
	return source + 12 if source <= 12 else source - 12

static func _journey(save) -> Dictionary:
	var journey: Dictionary = Dictionary(save.data.get(SAVE_KEY, {})).duplicate(true)
	if typeof(journey.get(ITEM_KEY, {})) != TYPE_DICTIONARY:
		journey[ITEM_KEY] = {}
	if typeof(journey.get(RESONANCE_KEY, [])) != TYPE_ARRAY:
		journey[RESONANCE_KEY] = []
	if not journey.has(ITEM_KEY):
		journey[ITEM_KEY] = {}
	if not journey.has(RESONANCE_KEY):
		journey[RESONANCE_KEY] = []
	save.data[SAVE_KEY] = journey
	return journey

static func item_state(save, id: String) -> Dictionary:
	var journey := _journey(save)
	return Dictionary(Dictionary(journey.get(ITEM_KEY, {})).get(id, {})).duplicate(true)

static func summary(save) -> Dictionary:
	return _journey(save).duplicate(true)

static func active_ids(save) -> Array:
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	var out: Array = []
	for value in Dictionary(cosmetics.get("equipped", {})).values():
		_append_unique(out, str(value))
	_append_unique(out, str(cosmetics.get("mementoDisplayed", "")))
	for value in Array(cosmetics.get("loadout", [])):
		_append_unique(out, str(value))
	# Gli apparati NORA e i restauri sono installazioni permanenti. I moduli e i
	# Ricordi nello stesso inventario contano invece soltanto se preparati.
	for value in Array(cosmetics.get("inventory", [])):
		var id := str(value)
		var slot := str(RewardCatalog.find(id).get("slot", ""))
		if slot in ["upgrade", "decor"]:
			_append_unique(out, id)
	return out

static func record_acquired(save, id: String, world: int) -> bool:
	if RewardCatalog.find(id).is_empty():
		return false
	var journey := _journey(save)
	var items: Dictionary = Dictionary(journey.get(ITEM_KEY, {})).duplicate(true)
	var state: Dictionary = Dictionary(items.get(id, {})).duplicate(true)
	if bool(state.get("acquired", false)):
		return false
	# L'acquisto apre la biografia dell'oggetto, ma non conta come uso e non
	# produce patina: la traccia nasce soltanto quando l'oggetto entra in scena.
	state["acquired"] = true
	state["acquiredWorld"] = world
	# Forma esplicita e stabile anche prima del primo uso: semplifica migrazione,
	# UI e audit senza inventare eventi.
	state["uses"] = int(state.get("uses", 0))
	state["events"] = Array(state.get("events", [])).duplicate()
	state["worlds"] = Array(state.get("worlds", [])).duplicate()
	state["resonances"] = Array(state.get("resonances", [])).duplicate()
	items[id] = state
	journey[ITEM_KEY] = items
	save.data[SAVE_KEY] = journey
	return true

## Registra l'ingresso in un mondo per tutti gli oggetti effettivamente
## preparati. Se il Ricordo esposto riconosce il mondo, dichiara una risonanza
## disponibile: sara' il gesto sul POI, non il caricamento, a compierla.
static func begin_expedition(save, world: int) -> Dictionary:
	var used := record_event(save, "expedition", "world-%02d" % world, world)
	var resonance: Dictionary = {}
	var displayed := str(Dictionary(save.data.get("cosmetics", {})).get("mementoDisplayed", ""))
	if not displayed.is_empty() and resonance_world(displayed) == world:
		var key := "%s:%d" % [displayed, world]
		var journey := _journey(save)
		var done: Array = Array(journey.get(RESONANCE_KEY, []))
		resonance = _resonance_payload(displayed, world, done.has(key))
	return {"used": used, "resonance": resonance}

static func activate_resonance(save, id: String, world: int) -> Dictionary:
	var displayed := str(Dictionary(save.data.get("cosmetics", {})).get("mementoDisplayed", ""))
	if displayed != id or resonance_world(id) != world:
		return {}
	var key := "%s:%d" % [id, world]
	var journey := _journey(save)
	var done: Array = Array(journey.get(RESONANCE_KEY, []))
	var first := not done.has(key)
	if first:
		done.append(key)
		journey[RESONANCE_KEY] = done
		save.data[SAVE_KEY] = journey
		# Il gesto appartiene anche agli oggetti attivi che sanno leggere una
		# risonanza (per esempio Prisma, Aureola e Nucleo prismatico).
		record_event(save, "resonance", key, world)
		# Garanzia difensiva: il Ricordo deve conservare la propria risonanza
		# anche se in futuro cambiasse il profilo di eventi della famiglia.
		_record_one(save, id, "resonance", key, world, true)
	var payload := _resonance_payload(id, world, true)
	payload["first"] = first
	return payload

static func resonance_line(id: String, world: int) -> String:
	var contract := MEMENTO_RESONANCES.resonance(id)
	if not contract.is_empty() and int(contract.get("target", 0)) == world:
		return str(contract.get("line", ""))
	var item := RewardCatalog.find(id)
	var source := int(item.get("requiresHazardWorld", 0))
	return "%s riconosce un legame fra %s e %s. Il Ricordo conserva la traccia." % [
		str(item.get("name", "Il Ricordo")), _world_name(source), _world_name(world)]

static func _resonance_payload(id: String, world: int, completed: bool) -> Dictionary:
	var contract := MEMENTO_RESONANCES.resonance(id)
	return {
		"id": id,
		"world": world,
		"completed": completed,
		"line": resonance_line(id, world),
		"action": str(contract.get("action", "FAI RISUONARE")),
		"prompt": str(contract.get("prompt", "Il Ricordo riconosce questo luogo.")),
		"trace": str(contract.get("trace", "Legame conservato")),
		"motif": str(contract.get("motif", "link")),
		"direction": int(contract.get("direction", 1)),
		"pair": int(contract.get("pair", 0)),
	}

static func record_event(
		save, event_kind: String, event_id: String, world: int,
		only_ids: Array = []) -> Array:
	var candidates := only_ids.duplicate() if not only_ids.is_empty() else active_ids(save)
	var changed: Array = []
	for id_data in candidates:
		var id := str(id_data)
		var item_profile := profile(id)
		if item_profile.is_empty() or not Array(item_profile.get("events", [])).has(event_kind):
			continue
		if _record_one(save, id, event_kind, event_id, world, false):
			changed.append(id)
	return changed

static func record_tool_use(save, id: String, gate_id: String, world: int) -> bool:
	if not FieldTools.is_field_tool(id):
		return false
	var unlocked: Array = Array(Dictionary(save.data.get("cosmetics", {})).get("unlocked", []))
	if not unlocked.has(id):
		return false
	return _record_one(save, id, "tool_use", gate_id, world, false)

static func record_ship_room(save, room_id: String) -> Array:
	var room := ShipRoomCatalog.room(room_id)
	var restoration := str(room.get("restoration", ""))
	var only: Array = []
	if _owned(save, restoration):
		only.append(restoration)
	# I pezzi di NORA vengono letti nel Ponte Centrale: e' il loro banco, non un
	# effetto globale invisibile in tutte le stanze.
	if room_id == ShipRoomCatalog.DEFAULT_ROOM:
		for id in ["nora-lens", "nora-reserve", "nora-shield", "nora-prismatic-core"]:
			if _owned(save, id):
				only.append(id)
	return record_event(save, "ship_room", room_id, 0, only)

static func patina_stage(state: Dictionary) -> int:
	var worlds := Array(state.get("worlds", [])).size()
	var stage := 0
	for threshold in PATINA_WORLDS:
		if worlds >= int(threshold):
			stage += 1
	return stage

static func status_line(save, id: String) -> String:
	var state := item_state(save, id)
	var promise_status := EMBLEM_PROMISES.status(id, state)
	var laboratory_room := SHIP_LABORATORIES.room_for_decor(id)
	var laboratory_done := not laboratory_room.is_empty() and bool(
		SHIP_LABORATORIES.reflection(save, laboratory_room).get("completed", false))
	if state.is_empty():
		if not promise_status.is_empty():
			return "Promessa · %s" % promise_status
		return "Nessuna traccia ancora: preparalo e portalo nel mondo."
	if int(state.get("uses", 0)) == 0:
		if not promise_status.is_empty():
			return "Restaurato · %s" % promise_status
		return "Restaurato · laboratorio senza sintesi." if not laboratory_room.is_empty() \
			else "Restaurato · nessuna traccia d'uso ancora."
	var worlds: Array = Array(state.get("worlds", []))
	var resonances: Array = Array(state.get("resonances", []))
	var line := "%d usi distinti · %d mondi" % [int(state.get("uses", 0)), worlds.size()]
	if is_memento(id):
		line += " · %d risonanze" % resonances.size()
	elif not promise_status.is_empty():
		line += " · %s" % promise_status
	else:
		line += " · patina %d/3" % patina_stage(state)
	if not laboratory_room.is_empty():
		line += " · sintesi presente" if laboratory_done else " · sintesi da comporre"
	return line

static func _record_one(
		save, id: String, event_kind: String, event_id: String, world: int,
		allow_inactive: bool) -> bool:
	if RewardCatalog.find(id).is_empty():
		return false
	if not allow_inactive and not active_ids(save).has(id) and not FieldTools.is_field_tool(id):
		return false
	var journey := _journey(save)
	var items: Dictionary = Dictionary(journey.get(ITEM_KEY, {})).duplicate(true)
	var state: Dictionary = Dictionary(items.get(id, {})).duplicate(true)
	var events: Array = Array(state.get("events", [])).duplicate()
	var signature := "%s:%d:%s" % [event_kind, world, event_id]
	if events.has(signature):
		return false
	events.append(signature)
	state["events"] = events
	state["uses"] = int(state.get("uses", 0)) + 1
	state["lastWorld"] = world
	var worlds: Array = Array(state.get("worlds", [])).duplicate()
	if world > 0 and not worlds.has(world):
		worlds.append(world)
		worlds.sort()
	state["worlds"] = worlds
	if event_kind == "resonance":
		var resonances: Array = Array(state.get("resonances", [])).duplicate()
		if not resonances.has(world):
			resonances.append(world)
		state["resonances"] = resonances
	items[id] = state
	journey[ITEM_KEY] = items
	save.data[SAVE_KEY] = journey
	return true

static func _owned(save, id: String) -> bool:
	if id.is_empty():
		return false
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	return Array(cosmetics.get("unlocked", [])).has(id) \
		or Array(cosmetics.get("inventory", [])).has(id)

static func _append_unique(target: Array, id: String) -> void:
	if not id.is_empty() and not target.has(id):
		target.append(id)

static func _world_name(world: int) -> String:
	if world <= 0:
		return "la nave"
	return str(WorldProfileCatalog.profile(world).get("title", "mondo %d" % world))
