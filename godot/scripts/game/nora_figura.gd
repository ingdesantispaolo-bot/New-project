class_name NoraFigura
extends Control

## **Il disegno che spiega.** (26 agosto 2026)
##
## Segnalazione dello studente: le spiegazioni «servono a poco, poca sostanza e
## poca chiarezza». Una delle cause misurate era che il gioco non ne ha nessuna:
## 71 oggetti identitari illustrati, otto atlanti di scenografia, **zero disegni
## che spieghino qualcosa**. Una moltiplicazione è una griglia, una frazione è una
## torta tagliata, un circuito è un anello che si chiude — e tutto questo arrivava
## al bambino come una riga di testo grigio.
##
## ### Disegnate, non esportate
##
## Nessuna di queste figure è un'immagine. Una griglia 7×8 sono due cicli dentro
## `_draw()`: pesa **zero MB**, si adatta ai numeri di QUESTO esercizio e non ne
## serve una versione per ognuna delle 284 moltiplicazioni del banco. È la stessa
## ragione per cui gli atlanti si contano in MB prima di generarli: il pacchetto
## arriva su un tablet scolastico.
##
## ### Il testo non sta dentro il disegno
##
## Regola già in vigore per le tavole, e qui serve anche per un secondo motivo: le
## etichette cambiano a ogni esercizio e devono restare leggibili da un lettore di
## schermo. Quello che si disegna sono forme e posizioni; i numeri li scrive
## `draw_string` con il font del tema, e `descrizione()` dice a parole la stessa
## cosa per chi non vede la figura.
##
## ### Una figura sola, e solo dove aggiunge
##
## `per_item()` torna vuoto quasi sempre, ed è voluto. Una figura che illustra ciò
## che il testo ha già detto è la stessa tappezzeria di prima, disegnata. Si pesca
## solo quando i numeri si possono estrarre con certezza dal testo dell'esercizio:
## nel dubbio, niente figura.

## Quanto è alta la figura. Non cresce con i numeri: una griglia 12×12 stringe le
## celle invece di allungare il pannello, perché sotto c'è il pulsante per
## proseguire e su un tablet in verticale lo spazio finisce.
const ALTEZZA := 116.0

## **Quattro famiglie su dieci.** Il piano in `insieme.md` (voce C-N5) ne elenca
## dieci; qui ci sono griglia dei gruppi, torta tagliata, anello del circuito e
## due cerchi. Mancano la retta dei numeri, la bilancia dell'uguale, il contorno
## contro la superficie, la linea del tempo, la mappa muta e la parola smontata:
## sono quelle che servono a storia, geografia, latino e geometria, circa altri
## seicento esercizi. Aggiungerne una vuol dire una voce in `per_item`, una in
## `descrizione` e una in `_draw`.

const COLORE_PIENO := Color("6be7d6")
const COLORE_VUOTO := Color(0.42, 0.90, 0.84, 0.22)
const COLORE_TRATTO := Color(0.62, 0.95, 0.92, 0.55)
const COLORE_ACCENTO := Color("ffc95c")
const COLORE_TESTO := Color("d8fff8")

var tipo := ""
var dati: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(0, ALTEZZA)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Configura la figura. Vuoto (`tipo == ""`) la nasconde.
func mostra(nuovo_tipo: String, nuovi_dati: Dictionary) -> void:
	tipo = nuovo_tipo
	dati = nuovi_dati
	visible = tipo != ""
	custom_minimum_size = Vector2(0, ALTEZZA)
	tooltip_text = descrizione()
	queue_redraw()

# ---------------------------------------------------------------------------
# QUALE FIGURA MERITA QUESTO ESERCIZIO
# ---------------------------------------------------------------------------

## Torna `{"tipo": String, "dati": Dictionary}`, oppure vuoto se l'esercizio non
## ha una figura da mostrare — che è il caso più comune e va bene così.
##
## Le regole sono volutamente strette: si disegna solo quando i numeri escono dal
## testo senza interpretazione. Una figura sbagliata è molto peggio di nessuna
## figura, perché il bambino si fida di quello che vede più che di quello che
## legge.
static func per_item(item: Dictionary, materia: String) -> Dictionary:
	var prompt := str(item.get("prompt", ""))
	var topic := str(item.get("topic", ""))
	var risposta := str(item.get("answer", ""))

	if materia == "matematica":
		var griglia := _griglia_da(prompt, risposta)
		if not griglia.is_empty():
			return {"tipo": "griglia", "dati": griglia}
		var torta := _torta_da(prompt, risposta)
		if not torta.is_empty():
			return {"tipo": "torta", "dati": torta}

	if materia == "elettronica" and (
			topic.contains("circuit") or prompt.to_lower().contains("serie")
			or prompt.to_lower().contains("parallelo")):
		var basso := prompt.to_lower()
		if basso.contains("parallelo"):
			return {"tipo": "circuito", "dati": {"forma": "parallelo"}}
		if basso.contains("serie"):
			return {"tipo": "circuito", "dati": {"forma": "serie"}}
		if basso.contains("aperto") or basso.contains("interrotto"):
			return {"tipo": "circuito", "dati": {"forma": "aperto"}}
		if basso.contains("chiuso"):
			return {"tipo": "circuito", "dati": {"forma": "chiuso"}}

	if materia == "logica" and (topic.contains("insiem") or topic.contains("quantific")):
		return {"tipo": "insiemi", "dati": {}}

	return {}

## Righe e colonne da una moltiplicazione, una divisione o un fattore mancante.
##
## I tre versi della tabellina sono la stessa griglia guardata da tre lati, ed è
## esattamente la cosa che il disegno rende ovvia e il testo no: `56 ÷ 8` non è
## un'operazione nuova, è la stessa griglia di `7 × 8` con una domanda diversa.
static func _griglia_da(prompt: String, risposta: String) -> Dictionary:
	var prodotto := RegEx.create_from_string("(\\d+)\\s*[×x]\\s*(\\d+)")
	var trovato := prodotto.search(prompt)
	if trovato != null:
		var a := int(trovato.get_string(1))
		var b := int(trovato.get_string(2))
		if _griglia_disegnabile(a, b):
			return {"righe": a, "colonne": b, "evidenzia": ""}
	var divisione := RegEx.create_from_string("(\\d+)\\s*[÷:]\\s*(\\d+)")
	trovato = divisione.search(prompt)
	if trovato != null:
		var totale := int(trovato.get_string(1))
		var per := int(trovato.get_string(2))
		if per > 0 and totale % per == 0 and _griglia_disegnabile(totale / per, per):
			return {"righe": totale / per, "colonne": per, "evidenzia": "riga"}
	# «Quale numero moltiplicato per 8 dà 56?»
	var fattore := RegEx.create_from_string("per\\s+(\\d+)\\s+d[àa]\\s+(\\d+)")
	trovato = fattore.search(prompt)
	if trovato != null:
		var noto := int(trovato.get_string(1))
		var totale2 := int(trovato.get_string(2))
		if noto > 0 and totale2 % noto == 0 and _griglia_disegnabile(totale2 / noto, noto):
			return {"righe": totale2 / noto, "colonne": noto, "evidenzia": "colonna"}
	return {}

## Sotto le due celle non è una griglia, sopra le dodici per lato diventa una
## macchia di puntini: in tutt'e due i casi il disegno smette di spiegare.
static func _griglia_disegnabile(righe: int, colonne: int) -> bool:
	return righe >= 2 and colonne >= 2 and righe <= 12 and colonne <= 12

## Numeratore e denominatore da una frazione scritta nel testo o nella risposta.
static func _torta_da(prompt: String, risposta: String) -> Dictionary:
	var frazione := RegEx.create_from_string("(\\d+)\\s*/\\s*(\\d+)")
	var trovato := frazione.search(prompt)
	if trovato == null:
		trovato = frazione.search(risposta)
	if trovato != null:
		var num := int(trovato.get_string(1))
		var den := int(trovato.get_string(2))
		if den >= 2 and den <= 12 and num >= 1 and num <= den:
			return {"parti": den, "prese": num}
	var percentuale := RegEx.create_from_string("(\\d+)\\s*%")
	trovato = percentuale.search(prompt)
	if trovato != null:
		var quanto := int(trovato.get_string(1))
		if quanto > 0 and quanto < 100 and quanto % 10 == 0:
			return {"parti": 10, "prese": quanto / 10}
	return {}

# ---------------------------------------------------------------------------
# A PAROLE, PER CHI NON VEDE IL DISEGNO
# ---------------------------------------------------------------------------

## La stessa informazione della figura, detta a parole. Va nel tooltip e serve al
## lettore di schermo: una figura che esiste solo per chi la vede è una figura che
## esclude, e questo gioco ha già deciso di non farlo (vedi lo scorrimento, che ha
## tre alternative al gesto).
func descrizione() -> String:
	match tipo:
		"griglia":
			var righe := int(dati.get("righe", 0))
			var colonne := int(dati.get("colonne", 0))
			return "Una griglia di %d righe per %d colonne: %d quadretti in tutto." % [
				righe, colonne, righe * colonne]
		"torta":
			return "Un cerchio diviso in %d fette, con %d colorate." % [
				int(dati.get("parti", 0)), int(dati.get("prese", 0))]
		"circuito":
			match str(dati.get("forma", "")):
				"aperto": return "Un anello interrotto: la corrente non passa."
				"chiuso": return "Un anello chiuso: la corrente gira tutt'attorno."
				"serie": return "Due lampadine una dopo l'altra sullo stesso filo."
				"parallelo": return "Due lampadine su due rami che si separano e si riuniscono."
			return ""
		"insiemi":
			return "Due cerchi che si sovrappongono: nel mezzo ciò che sta in tutti e due."
	return ""

# ---------------------------------------------------------------------------
# IL DISEGNO
# ---------------------------------------------------------------------------

## L'altezza su cui disegnare. **Si legge dal nodo, non dalla costante**: il
## contenitore puo' darne meno di quanto chiesto — su un tablet in verticale
## succede — e disegnare sulla costante manderebbe la didascalia fuori dal
## riquadro proprio dove lo spazio e' piu' stretto.
func _altezza() -> float:
	return maxf(48.0, size.y)

func _draw() -> void:
	if tipo == "" or size.x <= 0.0 or size.y <= 0.0:
		return
	match tipo:
		"griglia": _disegna_griglia()
		"torta": _disegna_torta()
		"circuito": _disegna_circuito()
		"insiemi": _disegna_insiemi()

## **La griglia dei gruppi.** Righe per colonne, e il totale è quanti quadretti
## ci sono. È la figura che serve al numero più grande di esercizi del gioco — le
## tabelline da sole sono 364 item — e la sola che rende evidente perché
## moltiplicare, dividere e cercare il fattore mancante siano la stessa domanda.
func _disegna_griglia() -> void:
	var righe := int(dati.get("righe", 0))
	var colonne := int(dati.get("colonne", 0))
	if righe <= 0 or colonne <= 0:
		return
	var evidenzia := str(dati.get("evidenzia", ""))
	var margine := 8.0
	var utile := Vector2(size.x - margine * 2.0, _altezza() - margine * 2.0 - 16.0)
	var lato := minf(utile.x / float(colonne), utile.y / float(righe))
	lato = minf(lato, 22.0)
	var origine := Vector2(margine, margine)
	for r in righe:
		for c in colonne:
			var rect := Rect2(
				origine + Vector2(float(c) * lato, float(r) * lato),
				Vector2(lato - 3.0, lato - 3.0))
			var acceso := (evidenzia == "riga" and r == 0) or (evidenzia == "colonna" and c == 0)
			draw_rect(rect, COLORE_ACCENTO if acceso else COLORE_PIENO, true)
	var font := get_theme_default_font()
	if font == null:
		return
	var didascalia := "%d righe × %d colonne = %d" % [righe, colonne, righe * colonne]
	draw_string(
		font, Vector2(margine, _altezza() - margine), didascalia,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLORE_TESTO)

## **La torta tagliata.** Quante fette in tutto, quante prese: è la frazione che
## si guarda invece di leggerla.
func _disegna_torta() -> void:
	var parti := int(dati.get("parti", 0))
	var prese := int(dati.get("prese", 0))
	if parti <= 0:
		return
	var raggio := (_altezza() - 34.0) * 0.5
	var centro := Vector2(raggio + 12.0, raggio + 8.0)
	var passo := TAU / float(parti)
	for i in parti:
		var punti := PackedVector2Array([centro])
		var da := -PI * 0.5 + float(i) * passo
		for passo_arco in 9:
			var ang := da + passo * (float(passo_arco) / 8.0)
			punti.append(centro + Vector2(cos(ang), sin(ang)) * raggio)
		draw_colored_polygon(punti, COLORE_PIENO if i < prese else COLORE_VUOTO)
		draw_line(centro, centro + Vector2(cos(da), sin(da)) * raggio, COLORE_TRATTO, 1.5)
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(
		font, Vector2(centro.x + raggio + 16.0, centro.y),
		"%d fette su %d" % [prese, parti],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLORE_TESTO)

## **L'anello del circuito.** La corrente gira solo se l'anello si chiude: è la
## cosa che tutta l'elettronica del gioco chiede, e in un disegno si vede subito.
func _disegna_circuito() -> void:
	var forma := str(dati.get("forma", ""))
	var margine := 16.0
	var rect := Rect2(
		Vector2(margine, margine), Vector2(size.x - margine * 2.0, _altezza() - margine * 2.0 - 14.0))
	rect.size.x = minf(rect.size.x, 230.0)
	var alto_sx := rect.position
	var alto_dx := rect.position + Vector2(rect.size.x, 0.0)
	var basso_sx := rect.position + Vector2(0.0, rect.size.y)
	var basso_dx := rect.position + rect.size
	var filo := COLORE_PIENO
	match forma:
		"aperto":
			# L'interruzione sta in alto, ben visibile: è la sola cosa che conta.
			var tacca := rect.size.x * 0.34
			draw_line(alto_sx, alto_sx + Vector2(tacca, 0.0), filo, 3.0)
			draw_line(alto_dx - Vector2(tacca, 0.0), alto_dx, filo, 3.0)
			draw_line(alto_sx, basso_sx, filo, 3.0)
			draw_line(alto_dx, basso_dx, filo, 3.0)
			draw_line(basso_sx, basso_dx, filo, 3.0)
			_lampadina(rect.position + Vector2(rect.size.x * 0.5, rect.size.y), false)
		"parallelo":
			draw_rect(rect, filo, false, 3.0)
			var meta := rect.position + Vector2(rect.size.x * 0.5, 0.0)
			draw_line(meta, meta + Vector2(0.0, rect.size.y), COLORE_TRATTO, 2.0)
			_lampadina(rect.position + Vector2(rect.size.x * 0.25, rect.size.y), true)
			_lampadina(rect.position + Vector2(rect.size.x * 0.75, rect.size.y), true)
		"serie":
			draw_rect(rect, filo, false, 3.0)
			_lampadina(rect.position + Vector2(rect.size.x * 0.33, rect.size.y), true)
			_lampadina(rect.position + Vector2(rect.size.x * 0.67, rect.size.y), true)
		_:
			draw_rect(rect, filo, false, 3.0)
			_lampadina(rect.position + Vector2(rect.size.x * 0.5, rect.size.y), true)
	var font := get_theme_default_font()
	if font != null:
		draw_string(
			font, Vector2(margine, _altezza() - 2.0), descrizione(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLORE_TESTO)

func _lampadina(centro: Vector2, accesa: bool) -> void:
	draw_circle(centro, 9.0, COLORE_ACCENTO if accesa else COLORE_VUOTO)
	draw_arc(centro, 9.0, 0.0, TAU, 20, COLORE_TRATTO, 1.5)

## **I due cerchi.** Che cosa sta dentro tutti e due, che cosa solo in uno: è la
## figura del ragionamento sugli insiemi, e regge anche i quantificatori — «tutti»
## è un cerchio dentro l'altro, «qualcuno» è la sovrapposizione.
func _disegna_insiemi() -> void:
	var raggio := (_altezza() - 30.0) * 0.5
	var centro_y := raggio + 8.0
	var sinistro := Vector2(raggio + 14.0, centro_y)
	var destro := Vector2(raggio * 2.6 + 14.0, centro_y)
	draw_circle(sinistro, raggio, Color(COLORE_PIENO.r, COLORE_PIENO.g, COLORE_PIENO.b, 0.22))
	draw_circle(destro, raggio, Color(COLORE_ACCENTO.r, COLORE_ACCENTO.g, COLORE_ACCENTO.b, 0.22))
	draw_arc(sinistro, raggio, 0.0, TAU, 32, COLORE_PIENO, 2.0)
	draw_arc(destro, raggio, 0.0, TAU, 32, COLORE_ACCENTO, 2.0)
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(
		font, Vector2(destro.x + raggio + 14.0, centro_y),
		"nel mezzo: quelli che stanno\nin tutti e due i gruppi",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLORE_TESTO)
