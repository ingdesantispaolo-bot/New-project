class_name TeachingCatalog
extends RefCounted

## Il contratto di ciò che il gioco chiede al giocatore di **spiegare**: la
## meccanica «Rispiegamelo» di Vera (primo gioco) e la Diagnosi del Secondo
## Viaggio. Dati e regole; la regia è di chi costruisce le scene.
##
## Le due cose stanno insieme perché sono la stessa idea a due profondità. In
## «Rispiegamelo» il giocatore sceglie **quale spiegazione è quella giusta**; nel
## Secondo Viaggio sceglie **come dirla a qualcuno che ha capito male**. La
## seconda è la prima, un anno dopo.
##
## Fonti: `docs/ABITANTI_E_LUOGHI.md` §5.3 e `docs/SECONDO_VIAGGIO.md` §4.

## --- «Rispiegamelo» (Vera) --------------------------------------------------
##
## Le tre spiegazioni non si scrivono a mano una per topic: si **compongono** da
## campi che esistono già nel Codex. È quello che rende la meccanica applicabile
## a tutti i topic invece che a dodici scelti a mano.
const RISPIEGAMELO := {
	"quando": "Solo dopo che un argomento è passato ad `applied` nel Codex.",
	"opzioni": [
		{
			"id": "corretta",
			"fonte": "campo `explanation` dell'item + `strategy` del Codex",
			"cosa": "Tocca il perché, non solo il come.",
			"giusta": true,
		},
		{
			"id": "superficiale",
			"fonte": "la regola operativa dell'item, senza il `why`",
			"cosa": "Vera, plausibile, e non spiega niente: descrive il procedimento e si ferma lì.",
			"giusta": false,
		},
		{
			"id": "con-errore",
			"fonte": "campo `error` del Codex — l'errore tipico di quell'argomento",
			"cosa": "Suona bene ed è la trappola in cui cade davvero chi studia quel topic.",
			"giusta": false,
		},
	],
	# Il vincolo che tiene in piedi tutto: la ricompensa è sociale. Se dessi
	# energia, «rispiegamelo» diventerebbe una miniera da farmare e Vera un
	# distributore. Non dando niente, resta l'unica cosa nel gioco che si fa
	# perché fa piacere farla.
	"ricompensa": {
		"energia": 0,
		"gate": false,
		"cosa_succede": "Vera capisce, e lo dice. L'argomento riceve una prova di ritenzione in `spaced_repetition`.",
	},
	"frequenza": {
		"per_sessione": 1,
		"stesso_topic_stesso_giorno": false,
		"perche": "Più spesso di così diventa un'interruzione, e l'elaborazione si trasforma in ripetizione.",
	},
}

## --- La Diagnosi (Secondo Viaggio) ------------------------------------------
##
## Quattro modi di spiegare a una sorella sbiadita, e ognuno ha una conseguenza
## **visibile sulla prova successiva**. Nessuno toglie progressi al giocatore: la
## conseguenza è sulla sorella, ed è sempre recuperabile.
const DIAGNOSI := [
	{
		"id": "mirata",
		"titolo": "Spiegazione mirata",
		"cosa": "Tocca esattamente la regola sbagliata che le ha fatto sbagliare il passo.",
		"subito": "Ci mette qualche secondo, poi capisce.",
		"dopo": "Applica il concetto anche in un contesto nuovo. La sbiadatura si ritira.",
		"sempre_disponibile": true,
		"punita": false,
	},
	{
		"id": "fuori-bersaglio",
		"titolo": "Spiegazione corretta ma fuori bersaglio",
		"cosa": "Vera, giusta, e non parla del suo errore.",
		"subito": "Annuisce.",
		"dopo": "Rifà lo stesso errore, identico. Nessun danno, nessun progresso.",
		"sempre_disponibile": true,
		"punita": false,
	},
	{
		# Deve restare sempre lì e sempre funzionare nell'immediato. Bloccarla o
		# punirla con una schermata di errore sarebbe una lezione morale;
		# lasciarla lì con la sua conseguenza visibile la trasforma in una
		# scoperta del giocatore. Il gioco non dice che è sbagliato: lo fa vedere.
		"id": "dille-la-risposta",
		"titolo": "Dille la risposta",
		"cosa": "Gliela dai e basta.",
		"subito": "Giusto subito, sollievo immediato.",
		"dopo": "Il ragionamento successivo è più meccanico: copia la forma. Un passo verso la sbiadatura, reversibile.",
		"sempre_disponibile": true,
		"punita": false,
	},
	{
		"id": "chiedile-perche",
		"titolo": "Chiedile perché",
		"cosa": "Non spieghi: le chiedi di giustificare il passo.",
		"subito": "Prova a giustificarsi e si accorge da sola.",
		"dopo": "L'effetto migliore di tutti.",
		"sempre_disponibile": false,
		"punita": false,
	},
]

## --- Il ragionamento a passi ------------------------------------------------
##
## L'unico pezzo di contenuto nuovo che il Secondo Viaggio richiede: una catena
## di 3–4 passaggi con l'errore in uno di essi, composta da item reali.
##
## **La regola pagata a caro prezzo il 29 luglio**: la posizione del passo
## sbagliato deve ruotare. Un errore sempre al terzo passo produce un giocatore
## che clicca il terzo passo senza leggere — e a quel punto il gioco non allena
## più l'analisi dell'errore, allena a contare fino a tre.
const PASSI_MIN := 3
const PASSI_MAX := 4

## La posizione dell'errore, deterministica e distribuita. Non è casuale: è una
## rotazione seminata sul topic e sul tentativo, così due sessioni consecutive
## sullo stesso argomento non ripetono mai la stessa posizione, e la partita
## resta riproducibile a parità di seme.
static func error_step(topic_id: String, attempt: int, steps: int) -> int:
	var total: int = clampi(steps, PASSI_MIN, PASSI_MAX)
	var base := 0
	for i in topic_id.length():
		base = (base * 31 + topic_id.unicode_at(i)) % 9973
	return (base + attempt) % total

## --- API --------------------------------------------------------------------

static func diagnosi_option(option_id: String) -> Dictionary:
	for entry in DIAGNOSI:
		if str((entry as Dictionary).get("id", "")) == option_id:
			return (entry as Dictionary).duplicate(true)
	return {}

static func rispiegamelo_options() -> Array:
	return (RISPIEGAMELO["opzioni"] as Array).duplicate(true)
