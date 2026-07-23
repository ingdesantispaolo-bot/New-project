class_name WorldProfileCatalog
extends RefCounted

## Catalogo dei 24 `WorldProfile` (O-P1). Una SOLA `WorldScene` (Codex) viene
## configurata da un profilo per livello: la generazione procedurale riempie il
## profilo ma NON può cambiarne l'identità né invadere `shipEntrance.safeRadius`.
## Vedi docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md (contratto WorldProfile e mappa 24).
##
## Contratto (read-only per Codex): il visuale legge il profilo, non decide
## materia, ricompense o completamenti. Le coordinate sono in "unità mondo" con
## origine sull'ingresso nave; Codex le mappa nella scena e risolve la
## navigabilità del terreno, rispettando spawn, percorso sicuro e raggio protetto.

# --- Geometria base condivisa (autorata, deterministica) ----------------------
# Convenzione: origine (0,0) = ingresso nave. Eli parte a sud e risale il
# corridoio sicuro fino alla nave. I mondi condividono questa geometria d'accesso
# (ingresso leggibile e protetto ovunque); l'identità cambia in terreno, arte,
# landmark, atmosfera e grammatica di missione, non nell'ergonomia dell'ingresso.
const SHIP_ENTRANCE := Vector2(0, 0)
const SHIP_SAFE_RADIUS := 340.0        # nessun POI/ostacolo entro questo raggio
const SPAWN := Vector2(0, 1180)        # punto iniziale di Eli (sud, fuori dal raggio)
const REACH_RADIUS := 1900.0           # distanza max dallo spawn per un evento "raggiungibile"
const WORLD_HALF_EXTENT := 2200.0      # semi-lato dell'area giocabile (clamp)

# Percorso sicuro garantito spawn → bordo del raggio nave (Codex non vi mette
# ostacoli): una spezzata dritta risalendo verso nord.
static func safe_route() -> Array:
	return [SPAWN, Vector2(0, 760), Vector2(0, 400), Vector2(0, SHIP_SAFE_RADIUS)]

# Budget prestazionale per tier (indicativo; Codex lo affina con capture reali).
static func performance_budget() -> Dictionary:
	return {
		"web": {"maxDrawCalls": 900, "maxActivePois": 14, "streamRadius": 1600},
		"mobile": {"maxDrawCalls": 700, "maxActivePois": 10, "streamRadius": 1400},
		"desktop": {"maxDrawCalls": 1400, "maxActivePois": 20, "streamRadius": 2000},
	}

# Formati d'esercizio coerenti con la materia (famiglie ExerciseInteraction).
# Servono all'event pool per variare le tappe evitando la scelta multipla ovunque.
const SUBJECT_FORMATS := {
	"matematica": ["numeric_input", "multiple_choice", "ordering"],
	"italiano": ["multiple_choice", "matching", "ordering"],
	"coding": ["ordering", "multiple_choice", "matching"],
	"inglese": ["multiple_choice", "matching"],
	"fisica": ["numeric_input", "multiple_choice", "ordering"],
	"musica": ["matching", "ordering", "multiple_choice"],
	"latino": ["matching", "multiple_choice", "ordering"],
	"elettronica": ["matching", "numeric_input", "multiple_choice"],
	"geografia": ["matching", "multiple_choice", "ordering"],
	"scienze": ["matching", "multiple_choice", "ordering"],
	"cittadinanza": ["multiple_choice", "matching", "ordering"],
	"logica": ["ordering", "multiple_choice", "numeric_input"],
}

# --- Identità dei 24 mondi (mappa del piano AAA) ------------------------------
# Solo i campi IDENTITARI: id, titolo, terreno, topologia, art kit, landmark,
# luce, meteo, soundscape, brief competenze. Il focus-materia è derivato da
# ApparatusConfig (unica fonte di verità della scala), la geometria dalla base.
const IDENTITIES := [
	{"id": "world-01-radura", "title": "Radura Accademia", "terrainFamily": "prato-luminoso", "topology": "radura-aperta", "artKit": "natura-rovine", "heroLandmarks": ["obelisco-dei-numeri"], "lighting": "mattino-dorato", "weather": "sereno", "soundscape": "bosco-cristallino", "brief": ["conteggio e tabelline", "problemi a storia"]},
	{"id": "world-02-archivio", "title": "Archivio delle Parole", "terrainFamily": "biblioteca-vegetale", "topology": "sale-e-ponti", "artKit": "carta-e-foglie", "heroLandmarks": ["ponte-delle-frasi"], "lighting": "luce-diffusa", "weather": "foschia-lieve", "soundscape": "pagine-e-vento", "brief": ["classi di parole", "costruzione di frasi"]},
	{"id": "world-03-cratere", "title": "Cratere Logico", "terrainFamily": "canyon-modulare", "topology": "canyon-a-gradoni", "artKit": "macchine-e-loop", "heroLandmarks": ["macchina-a-cicli"], "lighting": "controluce-metallico", "weather": "sereno", "soundscape": "ingranaggi-ritmici", "brief": ["sequenze e loop", "trace del codice"]},
	{"id": "world-04-baia", "title": "Baia dei Segnali", "terrainFamily": "porto-radio", "topology": "moli-e-boe", "artKit": "segnali-e-onde", "heroLandmarks": ["faro-dei-messaggi"], "lighting": "tramonto-marino", "weather": "brezza", "soundscape": "onde-e-radio", "brief": ["vocabolario base", "frasi quotidiane"]},
	{"id": "world-05-officine", "title": "Officine del Moto", "terrainFamily": "officina-meccanica", "topology": "rampe-e-rotaie", "artKit": "leve-e-carrelli", "heroLandmarks": ["grande-leva"], "lighting": "industriale-caldo", "weather": "sereno", "soundscape": "metallo-e-vapore", "brief": ["forze e moto", "leve e rampe"]},
	{"id": "world-06-giardino", "title": "Giardino della Risonanza", "terrainFamily": "flora-sonora", "topology": "terrazze-sonore", "artKit": "cristalli-vibranti", "heroLandmarks": ["albero-risonante"], "lighting": "crepuscolo-iridescente", "weather": "vento-melodico", "soundscape": "campane-di-cristallo", "brief": ["altezze e ritmo", "note e scale"]},
	{"id": "world-07-glifi", "title": "Rovine dei Glifi", "terrainFamily": "città-antica", "topology": "vie-e-acquedotti", "artKit": "pietra-e-iscrizioni", "heroLandmarks": ["arco-dei-glifi"], "lighting": "meriggio-polveroso", "weather": "sereno", "soundscape": "eco-di-pietra", "brief": ["radici e declinazioni", "lessico latino"]},
	{"id": "world-08-delta", "title": "Delta dei Circuiti", "terrainFamily": "acqua-conduttiva", "topology": "isolotti-e-nodi", "artKit": "generatori-e-cavi", "heroLandmarks": ["nodo-centrale"], "lighting": "notte-elettrica", "weather": "pioggia-lieve", "soundscape": "ronzio-e-acqua", "brief": ["circuiti e nodi", "misure elettriche"]},
	{"id": "world-09-arcipelago", "title": "Arcipelago Cartografico", "terrainFamily": "isole-e-rotte", "topology": "arcipelago", "artKit": "mappe-e-quote", "heroLandmarks": ["torre-cartografica"], "lighting": "giorno-limpido", "weather": "vento-di-mare", "soundscape": "gabbiani-e-risacca", "brief": ["carte e coordinate", "rotte e quote"]},
	{"id": "world-10-serra", "title": "Serra delle Simbiosi", "terrainFamily": "ecosistema-vivo", "topology": "serra-a-livelli", "artKit": "flora-e-fauna", "heroLandmarks": ["cupola-vivente"], "lighting": "verde-diffuso", "weather": "umido", "soundscape": "vita-brulicante", "brief": ["ecosistemi", "osservazione scientifica"]},
	{"id": "world-11-patti", "title": "Città dei Patti", "terrainFamily": "quartieri-civici", "topology": "piazze-e-servizi", "artKit": "edifici-e-insegne", "heroLandmarks": ["palazzo-dei-patti"], "lighting": "giorno-urbano", "weather": "sereno", "soundscape": "folla-e-campane", "brief": ["regole e servizi", "decisioni comuni"]},
	{"id": "world-12-labirinto", "title": "Labirinto delle Regole", "terrainFamily": "geometrie-mobili", "topology": "labirinto-modulare", "artKit": "muri-mobili", "heroLandmarks": ["cuore-del-labirinto"], "lighting": "luce-fredda", "weather": "sereno", "soundscape": "scatti-e-silenzi", "brief": ["deduzione", "sequenze e regole"]},
	{"id": "world-13-orbite", "title": "Deserto delle Orbite", "terrainFamily": "deserto-osservatorio", "topology": "dune-e-cupole", "artKit": "strumenti-astrali", "heroLandmarks": ["osservatorio"], "lighting": "notte-stellata", "weather": "sereno-secco", "soundscape": "vento-di-sabbia", "brief": ["traiettorie", "proporzioni e stime"]},
	{"id": "world-14-voci", "title": "Biblioteca delle Voci", "terrainFamily": "biblioteca-voci", "topology": "gallerie-narrative", "artKit": "libri-e-eco", "heroLandmarks": ["sala-delle-voci"], "lighting": "ambra-calda", "weather": "quiete", "soundscape": "sussurri-narranti", "brief": ["prospettive narrative", "comprensione profonda"]},
	{"id": "world-15-macchina", "title": "Città Macchina", "terrainFamily": "città-macchina", "topology": "reti-e-automi", "artKit": "automi-e-cavi", "heroLandmarks": ["torre-di-controllo"], "lighting": "neon-notturno", "weather": "sereno", "soundscape": "clic-e-segnali", "brief": ["reti e concorrenza", "debug avanzato"]},
	{"id": "world-16-frontiera", "title": "Frontiera delle Lingue", "terrainFamily": "frontiera-scambi", "topology": "valichi-e-mercati", "artKit": "insegne-multilingua", "heroLandmarks": ["porta-delle-lingue"], "lighting": "giorno-vivace", "weather": "brezza", "soundscape": "mercato-poliglotta", "brief": ["comunicazione", "viaggi e scambi"]},
	{"id": "world-17-oceano", "title": "Oceano delle Forze", "terrainFamily": "oceano-profondo", "topology": "correnti-e-abissi", "artKit": "pressione-e-flussi", "heroLandmarks": ["cattedrale-sottomarina"], "lighting": "blu-profondo", "weather": "correnti", "soundscape": "abisso-e-bolle", "brief": ["pressione e galleggiamento", "correnti"]},
	{"id": "world-18-cattedrale", "title": "Cattedrale del Suono", "terrainFamily": "grandi-spazi", "topology": "navate-riverberanti", "artKit": "canne-e-archi", "heroLandmarks": ["grande-organo"], "lighting": "vetrate-colorate", "weather": "quiete", "soundscape": "riverbero-armonico", "brief": ["armonia", "spazio e riverbero"]},
	{"id": "world-19-necropoli", "title": "Necropoli delle Radici", "terrainFamily": "necropoli-antica", "topology": "cripte-e-archivi", "artKit": "epigrafi-e-radici", "heroLandmarks": ["albero-delle-radici"], "lighting": "penombra-solenne", "weather": "sereno", "soundscape": "silenzio-antico", "brief": ["etimologie", "discendenze lessicali"]},
	{"id": "world-20-tempesta", "title": "Tempesta Elettromagnetica", "terrainFamily": "campi-instabili", "topology": "torri-e-sensori", "artKit": "sensori-e-scariche", "heroLandmarks": ["torre-di-campo"], "lighting": "lampi-intermittenti", "weather": "tempesta", "soundscape": "statica-e-tuoni", "brief": ["campi e sensori", "reti instabili"]},
	{"id": "world-21-atlante", "title": "Atlante Fratturato", "terrainFamily": "placche-e-climi", "topology": "faglie-e-biomi", "artKit": "strati-e-climi", "heroLandmarks": ["pilastro-tettonico"], "lighting": "cielo-variabile", "weather": "climi-misti", "soundscape": "terra-e-vento", "brief": ["sistemi territoriali", "placche e climi"]},
	{"id": "world-22-biosfera", "title": "Biosfera Profonda", "terrainFamily": "biosfera-profonda", "topology": "caverne-vive", "artKit": "cellule-e-energia", "heroLandmarks": ["nucleo-vivente"], "lighting": "bioluminescente", "weather": "umido-caldo", "soundscape": "pulsazioni-vitali", "brief": ["cellule ed energia", "adattamento"]},
	{"id": "world-23-concilio", "title": "Concilio delle Colonie", "terrainFamily": "colonie-orbitali", "topology": "cupole-e-assemblee", "artKit": "moduli-e-bandiere", "heroLandmarks": ["sala-del-concilio"], "lighting": "luce-artificiale", "weather": "controllato", "soundscape": "voci-in-assemblea", "brief": ["negoziazione", "beni comuni"]},
	{"id": "world-24-cuore", "title": "Cuore dei Primi", "terrainFamily": "convergenza-finale", "topology": "nucleo-trasversale", "artKit": "sintesi-di-tutti", "heroLandmarks": ["cuore-dei-primi"], "lighting": "luce-convergente", "weather": "sospeso", "soundscape": "coro-dei-sistemi", "brief": ["sintesi interdisciplinare", "prova finale"]},
]

const MAX_LEVEL := 24

# Formati coerenti con la materia (fallback: solo scelta multipla se ignota).
static func formats_for(subject: String) -> Array:
	return Array(SUBJECT_FORMATS.get(subject, ["multiple_choice"])).duplicate()

# Grammatica di missione: quali tipi di evento il mondo ammette e con che peso.
# Presenza garantita di missioni-tappa; enigma persistente e minigioco come
# varietà. La prova finale NON è un evento del mondo (vive nella nave).
static func mission_grammar_for(level: int) -> Dictionary:
	# Enigma un po' più presente nei mondi "di sistema" (multipli di 3), minigioco
	# più presente nei primi mondi di ogni ciclo (onboarding di una meccanica).
	var cycle_pos := (level - 1) % 12
	var enigma := 2 if (level % 3) == 0 else 1
	var minigame := 2 if cycle_pos <= 1 else 1
	return {"mission": 3, "enigma": enigma, "minigame": minigame}

# Profilo COMPLETO del livello (identità + focus derivato + geometria + budget).
static func profile(level: int) -> Dictionary:
	var lvl := clampi(level, 1, MAX_LEVEL)
	var identity: Dictionary = IDENTITIES[lvl - 1]
	var gate := ApparatusConfig.level_gate(lvl)
	var subject := str(gate["subject"])
	return {
		"id": str(identity["id"]),
		"level": lvl,
		"title": str(identity["title"]),
		"learningFocus": {
			"subject": subject,
			"apparatus": str(gate["apparatus"]),
			"competencies": Array(identity["brief"]).duplicate(),
		},
		"terrainFamily": str(identity["terrainFamily"]),
		"topology": str(identity["topology"]),
		"artKit": str(identity["artKit"]),
		"heroLandmarks": Array(identity["heroLandmarks"]).duplicate(),
		"lighting": str(identity["lighting"]),
		"weather": str(identity["weather"]),
		"soundscape": str(identity["soundscape"]),
		"missionGrammar": mission_grammar_for(lvl),
		"eventPools": {
			"formats": formats_for(subject),
			"reachRadius": REACH_RADIUS,
		},
		"shipEntrance": {
			"position": SHIP_ENTRANCE,
			"rotation": 0.0,
			"safeRadius": SHIP_SAFE_RADIUS,
		},
		"spawn": SPAWN,
		"safeRoute": safe_route(),
		"worldHalfExtent": WORLD_HALF_EXTENT,
		"performanceBudget": performance_budget(),
	}

static func all_profiles() -> Array:
	var out: Array = []
	for lvl in range(1, MAX_LEVEL + 1):
		out.append(profile(lvl))
	return out

# --- Validatore ---------------------------------------------------------------
# Ritorna {ok: bool, errors: Array[String]}. Verifica presenza campi, coerenza
# del focus con la scala, geometria dell'ingresso (spawn fuori dal raggio nave,
# percorso sicuro che parte dallo spawn e arriva al bordo del raggio) e budget.
const REQUIRED_KEYS := [
	"id", "level", "title", "learningFocus", "terrainFamily", "topology",
	"artKit", "heroLandmarks", "lighting", "weather", "soundscape",
	"missionGrammar", "eventPools", "shipEntrance", "spawn", "safeRoute",
	"worldHalfExtent", "performanceBudget",
]

static func validate(p: Dictionary) -> Dictionary:
	var errors: Array = []
	for key in REQUIRED_KEYS:
		if not p.has(key):
			errors.append("campo mancante: %s" % key)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}

	var lvl := int(p["level"])
	if lvl < 1 or lvl > MAX_LEVEL:
		errors.append("livello fuori scala: %d" % lvl)

	# Il focus deve coincidere con la scala di progressione (unica fonte di verità).
	var expected_subject := str(ApparatusConfig.level_gate(lvl)["subject"])
	if str(p["learningFocus"].get("subject", "")) != expected_subject:
		errors.append("focus incoerente col livello %d: atteso %s" % [lvl, expected_subject])

	if str(p["id"]) == "" or str(p["title"]) == "":
		errors.append("id/title vuoto")
	if Array(p["heroLandmarks"]).is_empty():
		errors.append("almeno un landmark eroe richiesto")
	if Array(p["eventPools"].get("formats", [])).is_empty():
		errors.append("eventPools.formats vuoto")
	if int(p["missionGrammar"].get("mission", 0)) <= 0:
		errors.append("missionGrammar deve ammettere missioni-tappa")

	# Geometria dell'ingresso: spawn fuori dal raggio protetto e percorso sicuro
	# valido (parte dallo spawn, termina sul bordo del raggio nave).
	var ship: Dictionary = p["shipEntrance"]
	var safe_radius := float(ship.get("safeRadius", 0.0))
	var ship_pos: Vector2 = ship.get("position", Vector2.ZERO)
	var spawn: Vector2 = p["spawn"]
	if safe_radius <= 0.0:
		errors.append("safeRadius deve essere positivo")
	if spawn.distance_to(ship_pos) <= safe_radius:
		errors.append("lo spawn cade dentro il raggio protetto della nave")
	var route: Array = p["safeRoute"]
	if route.size() < 2:
		errors.append("safeRoute deve avere almeno 2 waypoint")
	else:
		if (route[0] as Vector2).distance_to(spawn) > 1.0:
			errors.append("safeRoute non parte dallo spawn")
		var last: Vector2 = route[route.size() - 1]
		if last.distance_to(ship_pos) > safe_radius + 1.0:
			errors.append("safeRoute non raggiunge il bordo del raggio nave")

	if not p["performanceBudget"].has("web"):
		errors.append("performanceBudget.web mancante")

	return {"ok": errors.is_empty(), "errors": errors}

# Valida tutti i 24 profili. Ritorna {ok, count, errors: {level: [..]}}.
static func validate_all() -> Dictionary:
	var all_errors: Dictionary = {}
	var ids: Dictionary = {}
	var titles: Dictionary = {}
	for lvl in range(1, MAX_LEVEL + 1):
		var p := profile(lvl)
		var res := validate(p)
		if not bool(res["ok"]):
			all_errors[lvl] = res["errors"]

		# Unicità di id e titolo tra i mondi (distinzione richiesta dal piano).
		var id := str(p["id"])
		if ids.has(id):
			all_errors[lvl] = Array(all_errors.get(lvl, [])) + ["id duplicato: %s" % id]
		ids[id] = true
		var title := str(p["title"])
		if titles.has(title):
			all_errors[lvl] = Array(all_errors.get(lvl, [])) + ["titolo duplicato: %s" % title]
		titles[title] = true
	return {"ok": all_errors.is_empty(), "count": MAX_LEVEL, "errors": all_errors}
