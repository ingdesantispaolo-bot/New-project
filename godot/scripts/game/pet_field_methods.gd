class_name PetFieldMethods
extends RefCounted

## Undici modi equivalenti di affrontare una tana.
##
## La forma cambia percorso, segni e lettura di NORA, mai accesso, probabilita'
## o ricompensa. Tutti i profili hanno tre punti e la stessa attesa interna:
## scegliere una forma e' scegliere un carattere, non un vantaggio.

const METHODS := {
	"pet-dog": {
		"title": "Fiuto radente", "verb": "FIUTA", "glyph": "∿",
		"points": [Vector2(-92, 28), Vector2(-42, -10), Vector2.ZERO],
		"departure": "%s abbassa il muso e confronta due scie prima di entrare.",
		"completion": "NORA: il fiuto ha separato la pista recente da quella lasciata dal vento.",
	},
	"pet-cat": {
		"title": "Bordo alto", "verb": "AGGIRA", "glyph": "⌁",
		"points": [Vector2(-76, -62), Vector2(44, -70), Vector2.ZERO],
		"departure": "%s cerca il bordo piu' alto e guarda la tana da sopra.",
		"completion": "NORA: il bordo alto ha mostrato un ingresso che dal suolo sembrava chiuso.",
	},
	"pet-rabbit": {
		"title": "Prova delle fessure", "verb": "MISURA", "glyph": "⋀",
		"points": [Vector2(-86, 18), Vector2(-35, -48), Vector2.ZERO],
		"departure": "%s misura due fessure con salti brevi, poi sceglie quella giusta.",
		"completion": "NORA: due tentativi piccoli hanno evitato un salto alla cieca.",
	},
	"pet-spark": {
		"title": "Scintilla di soglia", "verb": "RIACCENDI", "glyph": "✦",
		"points": [Vector2(-70, 48), Vector2(62, 38), Vector2.ZERO],
		"departure": "%s lascia due scintille ai lati dell'ingresso e segue l'ombra fra loro.",
		"completion": "NORA: le due scintille non hanno illuminato tutto; hanno reso leggibile la soglia.",
	},
	"pet-comet": {
		"title": "Traiettoria interrotta", "verb": "RIPERCORRI", "glyph": "↝",
		"points": [Vector2(-104, -20), Vector2(38, 64), Vector2.ZERO],
		"departure": "%s prende slancio, supera l'ingresso e torna lungo la traiettoria spezzata.",
		"completion": "NORA: la traiettoria completa esisteva nei due tratti, non nel punto di rottura.",
	},
	"pet-orbit": {
		"title": "Perimetro orbitale", "verb": "CIRCONDA", "glyph": "◌",
		"points": [Vector2(-72, -52), Vector2(72, 46), Vector2.ZERO],
		"departure": "%s compie mezza orbita per distinguere apertura e semplice ombra.",
		"completion": "NORA: osservare il perimetro ha dato un contorno alla cavita'.",
	},
	"pet-satellite": {
		"title": "Parallasse breve", "verb": "TRIANGOLA", "glyph": "△",
		"points": [Vector2(-112, -38), Vector2(96, -32), Vector2.ZERO],
		"departure": "%s osserva la fenditura da due punti lontani prima di avvicinarsi.",
		"completion": "NORA: la parallasse ha distinto la profondita' dall'oscurita'.",
	},
	"pet-prisma": {
		"title": "Rifrazione doppia", "verb": "RIFRANGI", "glyph": "◇",
		"points": [Vector2(-78, 56), Vector2(76, -54), Vector2.ZERO],
		"departure": "%s attraversa due fasci diversi e segue il colore che entrambi conservano.",
		"completion": "NORA: due colori diversi condividevano la stessa origine.",
	},
	"pet-luma": {
		"title": "Luce di ritorno", "verb": "SEGNALA", "glyph": "∙",
		"points": [Vector2(-90, 34), Vector2(-38, 68), Vector2.ZERO],
		"departure": "%s posa due luci di ritorno, cosi' il buio non cancella la strada fatta.",
		"completion": "NORA: le luci non indicavano una scorciatoia; custodivano il ritorno.",
	},
	"pet-guardiano": {
		"title": "Veglia della soglia", "verb": "CUSTODISCI", "glyph": "▮",
		"points": [Vector2(-58, 30), Vector2(-22, 10), Vector2.ZERO],
		"departure": "%s resta sulla soglia, ascolta, e avanza soltanto quando il terreno tace.",
		"completion": "NORA: aspettare non ha accorciato il percorso; ha impedito al rumore di decidere.",
	},
	"pet-codex": {
		"title": "Lettura delle incisioni", "verb": "ASCOLTA", "glyph": "≋",
		"points": [Vector2(-84, -36), Vector2(40, -58), Vector2.ZERO],
		"departure": "%s confronta i graffi sui due lati come righe della stessa nota.",
		"completion": "NORA: i graffi non erano parole, ma conservavano ordine e direzione.",
	},
}

static func method(id: String) -> Dictionary:
	return Dictionary(METHODS.get(id, {})).duplicate(true)

static func ids() -> Array:
	return METHODS.keys().duplicate()

static func route(id: String, den_position: Vector2) -> Array:
	var out: Array = []
	for offset_data in Array(Dictionary(METHODS.get(id, {})).get("points", [])):
		out.append(den_position + Vector2(offset_data))
	return out

static func departure_line(id: String, name: String) -> String:
	var template := str(Dictionary(METHODS.get(id, {})).get(
		"departure", "%s si avvicina alla tana e sceglie il proprio metodo."))
	var who := name.strip_edges() if not name.strip_edges().is_empty() else "Il Custode"
	return template % who

static func completion_line(id: String) -> String:
	return str(Dictionary(METHODS.get(id, {})).get(
		"completion", "NORA: metodo osservato e registrato."))
