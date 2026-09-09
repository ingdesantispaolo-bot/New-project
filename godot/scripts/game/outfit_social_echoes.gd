class_name OutfitSocialEchoes
extends RefCounted

## Gli outfit vengono riconosciuti dagli abitanti una volta per persona.
## La patina cambia il tono della battuta, non la disponibilita' del dialogo.

const EVENT_KIND := "social_echo"

const REGISTER_CODA := {
	"curioso": "Posso guardare meglio?",
	"misterioso": "I tessuti ricordano piu' di quanto raccontano.",
	"buffo": "Io invece porto sempre la stessa macchia.",
	"divertente": "Di questo passo servira' una tuta anche alla tuta.",
	"caloroso": "Tienila cara, ma non tenerla al riparo.",
	"burbero": "Non sto dicendo che mi piace. Sto dicendo che si vede.",
	"solenne": "E' una testimonianza degna di essere conservata.",
	"sognante": "Chissa' quali colori avra' al prossimo ritorno.",
}

const ECHOES := {
	"avatar-gold": {
		"title": "Parata mai avvenuta",
		"lines": [
			"Quella tuta sembra aspettare una parata. Qui non ne facciamo da anni.",
			"La tuta da parata ha gia' polvere sulle cuciture. Forse finalmente sta servendo a qualcosa.",
			"Ormai non sembra piu' una divisa da mostrare: sembra la mappa dei posti in cui sei stata.",
		],
	},
	"avatar-violet": {
		"title": "Turno notturno",
		"lines": [
			"Quel viola e' il colore di chi resta sveglio quando gli archivi tacciono.",
			"Riconosco sulle maniche la polvere di piu' di un archivio.",
			"Quella tuta non e' piu' notturna: porta con se' tutte le notti che hai attraversato.",
		],
	},
	"avatar-emerald": {
		"title": "Traccia della Serra",
		"lines": [
			"Hai addosso il verde delle serre nuove, quello che ancora non sa dove attecchire.",
			"C'e' polline di posti diversi su quella tuta. Non spazzarlo via tutto.",
			"Il verde ha preso sfumature che qui non crescono: adesso la Serra viaggia con te.",
		],
	},
	"avatar-crimson": {
		"title": "Segni d'officina",
		"lines": [
			"Rosso d'officina. Si vede ancora dove nessuno ha stretto una vite.",
			"Hai una bruciatura e tre cuciture nuove: almeno quella tuta ha incontrato del lavoro vero.",
			"Ogni toppa racconta una riparazione diversa. Non chiamarla usura.",
		],
	},
	"avatar-nebula": {
		"title": "Carta dei segnali",
		"lines": [
			"Quella stoffa sembra una carta del cielo prima che qualcuno segni le rotte.",
			"Le cuciture stanno collegando i punti come una costellazione incompleta.",
			"Adesso sulla tuta c'e' una rotta che nessun osservatorio possiede intera.",
		],
	},
	"avatar-aurora": {
		"title": "Viaggio lungo",
		"lines": [
			"Una tuta da viaggio lungo, ancora troppo pulita per sapere quanto e' lungo.",
			"I colori cambiano sulle pieghe. Hai attraversato piu' di un'alba.",
			"Quell'aurora non appartiene piu' a un solo cielo.",
		],
	},
	"avatar-pilot": {
		"title": "Ruolo di Pilota",
		"lines": [
			"Uniforme da Pilota. Allora sarai tu a ricordare da dove siamo passati.",
			"Vedo correzioni di rotta sulle cuciture: un Pilota che non finge di andare sempre diritto.",
			"La tua uniforme porta piu' rotte dei registri della nave.",
		],
	},
	"avatar-engineer": {
		"title": "Ruolo di Ingegnere",
		"lines": [
			"Uniforme da Ingegnere. Spero che tu sappia anche sporcarla.",
			"Quelle macchie vengono da riparazioni diverse. Le hai lasciate apposta, vero?",
			"Un'Ingegnere con una tuta cosi' non deve mostrare un distintivo: mostra il lavoro.",
		],
	},
	"avatar-captain": {
		"title": "Ruolo di Capitano",
		"lines": [
			"Uniforme da Capitano. Qui pero' il primo ordine e' ascoltare.",
			"Hai segni di lavori fatti con persone diverse. Forse stai coordinando davvero.",
			"Quella non sembra piu' l'uniforme di chi comanda: sembra quella di chi tiene insieme.",
		],
	},
	"avatar-shadow": {
		"title": "Passaggio nel Silenzio",
		"lines": [
			"Quella tuta assorbe i bordi. Nel Silenzio dovrai ricordarti da sola dove finisci.",
			"Le cuciture chiare sono rimaste anche dove il resto del colore si e' spento.",
			"Hai attraversato abbastanza ombra da sapere che nascondersi e sparire non sono la stessa cosa.",
		],
	},
	"avatar-astral": {
		"title": "Cuciture di risonanza",
		"lines": [
			"Sulla tuta astrale i punti sembrano vicini anche quando vengono da mondi lontani.",
			"Una cucitura brilla in due colori. Hai trovato qualcosa che rispondeva da lontano?",
			"Quella tuta ormai non rappresenta il cielo: rappresenta i legami che hai ricostruito.",
		],
	},
}

static func echo(id: String) -> Dictionary:
	return Dictionary(ECHOES.get(id, {})).duplicate(true)

static func ids() -> Array:
	return ECHOES.keys().duplicate()

static func line(id: String, patina_stage: int, register: String = "") -> String:
	var lines: Array = Array(Dictionary(ECHOES.get(id, {})).get("lines", []))
	if lines.is_empty():
		return ""
	var base := str(lines[clampi(patina_stage, 0, lines.size() - 1)])
	var coda := str(REGISTER_CODA.get(register, ""))
	return base if coda.is_empty() else "%s %s" % [base, coda]
