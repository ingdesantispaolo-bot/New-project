class_name AccessoryFieldActions
extends RefCounted

## Azioni facoltative degli accessori acquistabili.
##
## Ogni azione e' una piccola rotta in tre tappe: il giocatore deve leggere il
## verbo, raggiungere il punto successivo e completare il gesto. Non concede
## valuta, energia o progressione; produce soltanto una traccia nella biografia
## dell'oggetto.

const EVENT_KIND := "accessory_action"

const ACTIONS := {
	"accessory-visor": {
		"title": "Triangolazione del Visore", "action": "METTI A FUOCO",
		"steps": [
			{"cue": "Trova il contorno", "response": "Il Visore separa il contorno dal rumore.", "offset": Vector2(0, 0)},
			{"cue": "Cambia angolo", "response": "Da un secondo angolo compare cio' che prima si sovrapponeva.", "offset": Vector2(170, -80)},
			{"cue": "Confronta le due viste", "response": "Le due viste concordano: l'osservazione ha una forma.", "offset": Vector2(80, 155)},
		],
		"completion": "NORA: il Visore non ha trovato una risposta; ha reso confrontabili tre osservazioni.",
	},
	"accessory-scarf": {
		"title": "Ritmo della Sciarpa", "action": "SEGUI IL BATTITO",
		"steps": [
			{"cue": "Ascolta il primo battito", "response": "La Sciarpa trattiene il primo intervallo.", "offset": Vector2(0, 0)},
			{"cue": "Ripeti la distanza", "response": "Il secondo battito torna alla stessa distanza.", "offset": Vector2(135, 90)},
			{"cue": "Chiudi il ritmo", "response": "Tre battiti fanno del percorso una frase.", "offset": Vector2(-45, 165)},
		],
		"completion": "NORA: la Sciarpa ha trasformato una distanza in ritmo. La risonanza fra mondi usa la stessa memoria.",
	},
	"accessory-compass": {
		"title": "Rilievo della Bussola", "action": "SEGNA LA ROTTA",
		"steps": [
			{"cue": "Fissa il punto di partenza", "response": "La Bussola non indica avanti: stabilisce da dove stai partendo.", "offset": Vector2(0, 0)},
			{"cue": "Prendi un secondo riferimento", "response": "Due riferimenti trasformano una direzione in una rotta.", "offset": Vector2(185, 35)},
			{"cue": "Ritorna sulla diagonale", "response": "La diagonale chiude il rilievo senza cancellare la deviazione.", "offset": Vector2(70, -155)},
		],
		"completion": "NORA: rotta registrata. La Bussola ricorda una scelta, non ordina dove andare.",
	},
	"accessory-pack": {
		"title": "Campione dello Zaino", "action": "CATALOGA",
		"steps": [
			{"cue": "Osserva senza raccogliere", "response": "Prima il contesto: un campione senza luogo perde meta' del significato.", "offset": Vector2(0, 0)},
			{"cue": "Isola il campione", "response": "Lo Zaino separa il campione senza confonderlo con il contenitore.", "offset": Vector2(-165, 55)},
			{"cue": "Collega campione e luogo", "response": "Il cartellino conserva insieme cosa, dove e quando.", "offset": Vector2(-45, -150)},
		],
		"completion": "NORA: campione catalogato. Conservare non significa accumulare: significa non perdere il contesto.",
	},
	"accessory-crown": {
		"title": "Sequenza della Corona", "action": "RICOSTRUISCI",
		"steps": [
			{"cue": "Individua la causa", "response": "La Corona conserva il problema prima dell'intervento.", "offset": Vector2(0, 0)},
			{"cue": "Segna il gesto decisivo", "response": "Ora causa e gesto non possono piu' scambiarsi di posto.", "offset": Vector2(120, -135)},
			{"cue": "Verifica l'esito", "response": "L'esito chiude la sequenza: causa, gesto, conseguenza.", "offset": Vector2(185, 70)},
		],
		"completion": "NORA: ricostruzione completa. La Corona testimonia il metodo, non il rango di chi la porta.",
	},
	"accessory-antenna": {
		"title": "Segnale dell'Antenna", "action": "SINTONIZZA",
		"steps": [
			{"cue": "Separa il segnale basso", "response": "Sotto il rumore resta una pulsazione lenta.", "offset": Vector2(0, 0)},
			{"cue": "Segui la banda intermedia", "response": "La seconda banda conferma che il segnale si sta muovendo.", "offset": Vector2(-150, -95)},
			{"cue": "Aggancia il picco", "response": "Il picco completa la firma senza rivelare una scorciatoia.", "offset": Vector2(65, -175)},
		],
		"completion": "NORA: firma sintonizzata. L'Antenna ha ascoltato cio' che il mondo dice piano.",
	},
	"accessory-wings": {
		"title": "Corrente delle Ali", "action": "STABILIZZA",
		"steps": [
			{"cue": "Entra nella corrente", "response": "Le Ali leggono la spinta senza annullarla.", "offset": Vector2(0, 0)},
			{"cue": "Compensa la deriva", "response": "La deriva diventa misurabile quando smetti di combatterla alla cieca.", "offset": Vector2(155, 105)},
			{"cue": "Ritrova l'asse", "response": "L'asse e' stabile: il campo resta difficile, ma ora ha una traccia.", "offset": Vector2(-55, 175)},
		],
		"completion": "NORA: corrente attraversata. Le Ali non eliminano il campo; ricordano come Eli gli ha risposto.",
	},
	"accessory-jetpack": {
		"title": "Balzi del Jetpack", "action": "COLLEGA I BALZI",
		"steps": [
			{"cue": "Calibra il primo impulso", "response": "Primo impulso breve: abbastanza per misurare, non per saltare il mondo.", "offset": Vector2(0, 0)},
			{"cue": "Raggiungi il secondo vettore", "response": "Il secondo impulso cambia direzione e conserva la velocita'.", "offset": Vector2(195, -30)},
			{"cue": "Chiudi la traiettoria", "response": "Tre vettori descrivono una deviazione completa.", "offset": Vector2(105, 180)},
		],
		"completion": "NORA: traiettoria registrata. Il Jetpack apre una deviazione personale, mai un passaggio obbligatorio.",
	},
	"accessory-halo": {
		"title": "Legame dell'Aureola", "action": "COLLEGA",
		"steps": [
			{"cue": "Riconosci il primo nodo", "response": "Un nodo da solo e' soltanto una presenza.", "offset": Vector2(0, 0)},
			{"cue": "Trova una proprieta' comune", "response": "Il secondo nodo condivide una forma, non una posizione.", "offset": Vector2(-185, 15)},
			{"cue": "Chiudi il legame", "response": "Il terzo nodo mostra che il legame puo' attraversare la distanza.", "offset": Vector2(-85, 170)},
		],
		"completion": "NORA: legame ricostruito. L'Aureola rende visibile una relazione che esisteva gia'.",
	},
}

static func action(id: String) -> Dictionary:
	return Dictionary(ACTIONS.get(id, {})).duplicate(true)

static func ids() -> Array:
	return ACTIONS.keys().duplicate()

static func event_id(id: String, world: int) -> String:
	return "field-%s-%02d" % [id, world]

static func event_signature(id: String, world: int) -> String:
	return "%s:%d:%s" % [EVENT_KIND, world, event_id(id, world)]

static func completed(state: Dictionary, id: String, world: int) -> bool:
	return Array(state.get("events", [])).has(event_signature(id, world))
