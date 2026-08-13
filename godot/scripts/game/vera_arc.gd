class_name VeraArc
extends RefCounted

## L'arco di Vera: si incrina, e si ricuce. DATI e stato; la regia è in
## `outdoor_world.gd`, sopra il flusso «Rispiegamelo» che c'era già.
##
## **Il difetto che risolve.** Vera è dichiarata «il pari» — la coetanea che fa
## le domande che il giocatore ha paura di fare — ed è, dopo NORA, il personaggio
## più importante del gioco. Ma per ventiquattro mondi fa una cosa sola: chiede
## di farsi rispiegare qualcosa, e ringrazia. È un'alleata perfetta, cioè una
## funzione. A dieci anni una compagna che ammira e basta va benissimo; a tredici
## no: a tredici le amicizie hanno attrito, e una che non ne ha si legge come
## finta proprio mentre dovrebbe essere l'unica cosa vera intorno.
##
## **Da dove esce l'attrito, senza che nessuno faccia niente di male.** Vera
## chiede sempre. Eli sa sempre. Nessuna delle due ha colpe, e la posizione è
## comunque insostenibile: essere in modo permanente quella che non capisce
## umilia, e a dodici anni umilia più di quanto si riesca a dire. Quindi Vera non
## si arrabbia perché Eli ha sbagliato qualcosa — si arrabbia **perché Eli è
## brava**, e la frase che lo dice è una domanda, come tutte le sue.
##
## **La soglia la fa il giocatore, non il calendario.** L'incrinatura non scatta
## a un mondo fisso: scatta quando le spiegazioni riuscite arrivano a
## `SOGLIA_INCRINATURA`. Il conteggio è già nel save (`narrative.veraExplainedOn`,
## scritto da `_record_vera_retention` **solo quando la spiegazione è giusta**).
## Chi non ha mai giocato con Vera non vede l'incrinatura, e non gli manca
## niente: non si può incrinare un rapporto che non c'è stato.
##
## **La ricucitura è il gioco al contrario.** Si ripara lasciando spiegare lei —
## ed è il loop del Secondo Viaggio («nel primo impari, nel secondo insegni»)
## anticipato da una persona sola, venti ore prima. Da lì in poi Vera ha un pool
## nuovo in cui insegna, e quando insegna **non dice tutto**: dà il pezzo che
## manca e lascia il resto. L'ha imparato guardando come lo fanno con lei, che è
## l'unico modo in cui si impara davvero un metodo.
##
## Guard-rail: nessuno stadio toglie qualcosa, nessuna risposta è punita
## (`StanceChoices` verifica), e Vera non fa **mai** una battuta sulle capacità di
## Eli — §2.4, si ride con lei e mai di lei. Qui non si ride affatto: si litiga
## per un minuto e poi si torna amiche.

const SCELTA_ID := "vera-incrinatura"

## Quattro spiegazioni riuscite. Meno, e l'incrinatura arriva prima che il
## rapporto esista; molte di più, e arriva quando la campagna è già finita —
## `veraExplainedOn` cresce di uno per topic e non per incontro.
const SOGLIA_INCRINATURA := 4

const STADIO_COMPAGNA := 0
const STADIO_INCRINATO := 1
const STADIO_RICUCITO := 2

## Le battute stanno in `ItinerantCatalog`, con tutte le altre di Vera, e non
## qui. Non è pignoleria: è l'unico modo per cui `itinerant_audit` le verifichi
## **da solo** — che finiscano tutte con una domanda (il suo tic è la sua
## personalità intera) e che nessuna prenda in giro il giocatore. Un pool tenuto
## fuori dal catalogo sarebbe un pool senza guardiano.
const POOL_INCRINATURA := "incrinatura"
const POOL_DOPO_LA_SCELTA := "dopo_la_scelta"
const POOL_RICUCITURA := "ricucitura"
const POOL_INSEGNA := "insegna"

## --- API -------------------------------------------------------------------

## Quante spiegazioni riuscite ha ricevuto Vera. Legge il conteggio che il gioco
## già teneva per il ripasso spaziato: nessun contatore nuovo da tenere allineato.
static func spiegazioni_ricevute(save_data: Dictionary) -> int:
	var narrative: Dictionary = save_data.get("narrative", {})
	return (narrative.get("veraExplainedOn", {}) as Dictionary).size()

## Lo stadio corrente. `veraArc` nel save tiene solo ciò che il conteggio non sa:
## se l'incrinatura è già stata vista e cosa ha risposto il giocatore.
static func stadio(save_data: Dictionary) -> int:
	var narrative: Dictionary = save_data.get("narrative", {})
	var arc: Dictionary = narrative.get("veraArc", {})
	if bool(arc.get("ricucito", false)):
		return STADIO_RICUCITO
	if str(arc.get("risposta", "")) != "":
		return STADIO_INCRINATO
	return STADIO_COMPAGNA

## Se tocca l'incrinatura adesso: soglia raggiunta e non ancora avvenuta.
static func incrinatura_dovuta(save_data: Dictionary) -> bool:
	if stadio(save_data) != STADIO_COMPAGNA:
		return false
	return spiegazioni_ricevute(save_data) >= SOGLIA_INCRINATURA

## Il pool da cui pescare quando Vera parla, dato lo stadio. Prima
## dell'incrinatura tutto resta esattamente com'era: chi non è arrivato alla
## soglia gioca il Vera di sempre, e non gli manca niente.
static func pool_per_stadio(stadio_corrente: int) -> String:
	match stadio_corrente:
		STADIO_INCRINATO:
			return POOL_RICUCITURA
		STADIO_RICUCITO:
			return POOL_INSEGNA
		_:
			return "rispiegamelo"

## Registra la risposta all'incrinatura. Non decide niente: segna soltanto che
## quella cosa è stata detta, così più tardi qualcuno può farci l'eco.
static func registra_risposta(save_data: Dictionary, option_id: String) -> void:
	var narrative: Dictionary = save_data.get("narrative", {})
	var arc: Dictionary = narrative.get("veraArc", {})
	arc["risposta"] = option_id
	narrative["veraArc"] = arc
	save_data["narrative"] = narrative

## La ricucitura è avvenuta: da qui Vera insegna.
static func registra_ricucitura(save_data: Dictionary) -> void:
	var narrative: Dictionary = save_data.get("narrative", {})
	var arc: Dictionary = narrative.get("veraArc", {})
	arc["ricucito"] = true
	narrative["veraArc"] = arc
	save_data["narrative"] = narrative

## L'eco della risposta data, o "" se l'incrinatura non è mai avvenuta.
static func eco(save_data: Dictionary) -> String:
	var narrative: Dictionary = save_data.get("narrative", {})
	var arc: Dictionary = narrative.get("veraArc", {})
	var risposta := str(arc.get("risposta", ""))
	if risposta == "" or bool(arc.get("ecoVista", false)):
		return ""
	return StanceChoices.eco(SCELTA_ID, risposta)

## L'eco si sente una volta sola: due volte sarebbe un promemoria, non un ricordo.
static func segna_eco_vista(save_data: Dictionary) -> void:
	var narrative: Dictionary = save_data.get("narrative", {})
	var arc: Dictionary = narrative.get("veraArc", {})
	arc["ecoVista"] = true
	narrative["veraArc"] = arc
	save_data["narrative"] = narrative
