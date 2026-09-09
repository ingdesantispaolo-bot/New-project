class_name ShipLaboratories
extends RefCounted

## Laboratori interpretativi delle sette stanze restaurate. Ogni sessione pone
## tre decisioni senza risposta giusta: la sintesi descrive il metodo scelto e
## sostituisce quella precedente. Nessun campo di progressione viene toccato.

const REFLECTIONS_KEY := "labReflections"
const EVENT_KIND := "ship_lab"

const LABS := {
	"central": {
		"decor": "decor-laboratorio", "title": "Banco dei legami",
		"intro": "Confronta tre modi di leggere gli oggetti riportati a bordo.",
		"completion": "NORA: il banco non ha scelto al posto tuo. Ha conservato come hai costruito il confronto.",
		"steps": [
			{"prompt": "Due configurazioni hanno prodotto lo stesso esito. Che cosa conservi?", "options": [
				{"label": "LA CONFIGURAZIONE", "meaning": "hai conservato come erano disposti i pezzi"},
				{"label": "IL RISULTATO", "meaning": "hai conservato cio' che entrambe le configurazioni hanno ottenuto"}]},
			{"prompt": "Una traccia compare una volta sola. Come la tratti?", "options": [
				{"label": "ECCEZIONE PREZIOSA", "meaning": "hai protetto l'evento unico"},
				{"label": "IPOTESI DA RIPETERE", "meaning": "hai lasciato aperta la verifica"}]},
			{"prompt": "Il confronto resta ambiguo. Che cosa annoti?", "options": [
				{"label": "IL DUBBIO", "meaning": "hai conservato l'incertezza"},
				{"label": "IL PROSSIMO TEST", "meaning": "hai trasformato il dubbio in una prova futura"}]},
		],
	},
	"bio": {
		"decor": "decor-serra", "title": "Serra dei campioni",
		"intro": "Costruisci una scheda che conservi il campione insieme al suo ambiente.",
		"completion": "NORA: la Serra ricorda che prendersi cura di un campione significa ricordare da dove viene.",
		"steps": [
			{"prompt": "Il campione cambia colore fuori dal suo mondo. Quale dato viene prima?", "options": [
				{"label": "LUOGO D'ORIGINE", "meaning": "hai dato priorita' all'ambiente"},
				{"label": "TEMPO TRASCORSO", "meaning": "hai dato priorita' alla trasformazione"}]},
			{"prompt": "Una foglia reagisce alla luce della nave. Che cosa confronti?", "options": [
				{"label": "LUCE E OMBRA", "meaning": "hai variato una condizione"},
				{"label": "PRIMA E DOPO", "meaning": "hai seguito il cambiamento nel tempo"}]},
			{"prompt": "Il campione e' stabile. Come continui a osservarlo?", "options": [
				{"label": "NON INTERVENIRE", "meaning": "hai scelto una cura minima"},
				{"label": "CAMBIA UNA COSA", "meaning": "hai scelto un esperimento controllato"}]},
		],
	},
	"reactor": {
		"decor": "decor-circuiti", "title": "Banco dei circuiti",
		"intro": "Segui un segnale senza trasformare la diagnosi in una riparazione automatica.",
		"completion": "NORA: il Reattore conserva la sequenza della diagnosi, non soltanto il punto in cui il circuito e' ripartito.",
		"steps": [
			{"prompt": "Il segnale si interrompe fra due nodi. Da dove inizi?", "options": [
				{"label": "DALLA SORGENTE", "meaning": "hai seguito il segnale in avanti"},
				{"label": "DAL GUASTO", "meaning": "hai risalito il circuito all'indietro"}]},
			{"prompt": "Due componenti sembrano identici. Come li distingui?", "options": [
				{"label": "MISURA SEPARATA", "meaning": "hai isolato i componenti"},
				{"label": "SCAMBIO DI POSTO", "meaning": "hai confrontato il loro comportamento"}]},
			{"prompt": "Il circuito funziona di nuovo. Che cosa lasci montato?", "options": [
				{"label": "RIDONDANZA", "meaning": "hai protetto il sistema con una seconda via"},
				{"label": "SEMPLICITA'", "meaning": "hai ridotto i punti che possono fallire"}]},
		],
	},
	"command": {
		"decor": "decor-osservatorio", "title": "Osservatorio delle rotte",
		"intro": "Leggi la stessa rotta a scale diverse e decidi quale relazione conservare.",
		"completion": "NORA: l'Osservatorio ha registrato una prospettiva. Una mappa onesta dichiara sempre la propria scala.",
		"steps": [
			{"prompt": "Una deviazione e' piccola sulla carta e grande nel viaggio. Quale scala usi?", "options": [
				{"label": "MAPPA GENERALE", "meaning": "hai conservato la relazione fra i mondi"},
				{"label": "TRATTO LOCALE", "meaning": "hai conservato il costo della deviazione"}]},
			{"prompt": "Due rotte arrivano insieme. Come le confronti?", "options": [
				{"label": "DISTANZA", "meaning": "hai confrontato quanto spazio attraversano"},
				{"label": "CAMBI DI DIREZIONE", "meaning": "hai confrontato la complessita' del percorso"}]},
			{"prompt": "Un punto non coincide con il modello. Che cosa diventa?", "options": [
				{"label": "ERRORE DI MISURA", "meaning": "hai chiesto una seconda osservazione"},
				{"label": "ANOMALIA REALE", "meaning": "hai protetto cio' che il modello non spiega"}]},
		],
	},
	"resonance": {
		"decor": "decor-musica", "title": "Archivio delle risonanze",
		"intro": "Costruisci una frase sonora scegliendo che cosa ascoltare fra gli impulsi.",
		"completion": "NORA: il Motore conserva anche le pause. Senza di loro tre impulsi sarebbero soltanto rumore.",
		"steps": [
			{"prompt": "Due impulsi hanno la stessa altezza ma durate diverse. Che cosa segui?", "options": [
				{"label": "LA DURATA", "meaning": "hai ascoltato la forma nel tempo"},
				{"label": "L'ALTEZZA COMUNE", "meaning": "hai ascoltato cio' che resta uguale"}]},
			{"prompt": "Fra gli impulsi compare un silenzio. Come lo annoti?", "options": [
				{"label": "PAUSA", "meaning": "hai trattato il silenzio come parte del ritmo"},
				{"label": "SEPARAZIONE", "meaning": "hai usato il silenzio per distinguere due eventi"}]},
			{"prompt": "La seconda onda arriva in ritardo. Che cosa confronti?", "options": [
				{"label": "FASE", "meaning": "hai confrontato la posizione nel ciclo"},
				{"label": "ECO", "meaning": "hai cercato il percorso che ha prodotto il ritardo"}]},
		],
	},
	"data_core": {
		"decor": "decor-archivio", "title": "Tavolo delle testimonianze",
		"intro": "Ordina una memoria senza separare frase, fonte e momento.",
		"completion": "NORA: il Data-core conserva il tuo criterio. Ordinare una memoria e' gia' interpretarla.",
		"steps": [
			{"prompt": "Due testimoni ricordano parole diverse. Che cosa registri per primo?", "options": [
				{"label": "CHI PARLA", "meaning": "hai ancorato la frase alla fonte"},
				{"label": "COSA COINCIDE", "meaning": "hai cercato il nucleo condiviso"}]},
			{"prompt": "Una parola non ha traduzione esatta. Come la conservi?", "options": [
				{"label": "PAROLA ORIGINALE", "meaning": "hai protetto l'ambiguita' della lingua"},
				{"label": "NOTA DI CONTESTO", "meaning": "hai spiegato quando quella parola viene usata"}]},
			{"prompt": "Due cronache collocano prima eventi diversi. Come le ordini?", "options": [
				{"label": "DUE LINEE PARALLELE", "meaning": "hai conservato il disaccordo"},
				{"label": "PUNTI COMUNI", "meaning": "hai costruito una cronologia minima"}]},
		],
	},
	"glyphs": {
		"decor": "decor-biblioteca-classica", "title": "Biblioteca delle radici",
		"intro": "Interpreta un glifo distinguendo radice, uso e parti ancora ignote.",
		"completion": "NORA: la Biblioteca non ha chiuso il significato. Ha conservato quali indizi lo sostengono.",
		"steps": [
			{"prompt": "Un glifo ricorre in tre iscrizioni. Da che cosa parti?", "options": [
				{"label": "PARTE COMUNE", "meaning": "hai isolato una possibile radice"},
				{"label": "CONTESTO DIVERSO", "meaning": "hai confrontato come cambia l'uso"}]},
			{"prompt": "La radice somiglia a una parola nota. Come procedi?", "options": [
				{"label": "IPOTESI ETIMOLOGICA", "meaning": "hai proposto una parentela da verificare"},
				{"label": "SOSPENDI IL LEGAME", "meaning": "hai evitato una somiglianza ingannevole"}]},
			{"prompt": "Resta un segno che nessuna frase spiega. Che cosa annoti?", "options": [
				{"label": "SIGNIFICATO APERTO", "meaning": "hai conservato cio' che ancora non sai"},
				{"label": "POSIZIONE NELLA FRASE", "meaning": "hai conservato la funzione prima del significato"}]},
		],
	},
}

static func laboratory(room_id: String) -> Dictionary:
	return Dictionary(LABS.get(room_id, {})).duplicate(true)

static func ids() -> Array:
	return LABS.keys().duplicate()

static func room_for_decor(decor_id: String) -> String:
	for room_id in LABS:
		if str(Dictionary(LABS[room_id]).get("decor", "")) == decor_id:
			return str(room_id)
	return ""

static func reflection(save, room_id: String) -> Dictionary:
	var journey: Dictionary = save.data.get("artifactJourney", {})
	return Dictionary(Dictionary(journey.get(REFLECTIONS_KEY, {})).get(room_id, {})).duplicate(true)

static func store_reflection(save, room_id: String, choices: Array) -> Dictionary:
	var lab := laboratory(room_id)
	var steps: Array = Array(lab.get("steps", []))
	if lab.is_empty() or choices.size() != steps.size():
		return {}
	var meanings: Array[String] = []
	for index in range(steps.size()):
		var options: Array = Array(Dictionary(steps[index]).get("options", []))
		var choice := int(choices[index])
		if choice < 0 or choice >= options.size():
			return {}
		meanings.append(str(Dictionary(options[choice]).get("meaning", "")))
	var saved := {
		"choices": choices.duplicate(),
		"summary": "; ".join(PackedStringArray(meanings)),
		"completed": true,
	}
	var journey: Dictionary = Dictionary(save.data.get("artifactJourney", {})).duplicate(true)
	var reflections: Dictionary = Dictionary(journey.get(REFLECTIONS_KEY, {})).duplicate(true)
	reflections[room_id] = saved
	journey[REFLECTIONS_KEY] = reflections
	save.data["artifactJourney"] = journey
	return saved.duplicate(true)
