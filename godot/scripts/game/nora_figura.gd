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
## I casi in colonna e la sagoma di una carta hanno bisogno di piu' spazio in
## verticale: sei righe non stanno in centosedici pixel senza diventare illeggibili.
const ALTEZZA_ALTA := 156.0

## **Quattro famiglie su dieci.** Il piano in `insieme.md` (voce C-N5) ne elenca
## dieci; qui ci sono griglia dei gruppi, torta tagliata, anello del circuito e
## due cerchi. Mancano la retta dei numeri, la bilancia dell'uguale, il contorno
## contro la superficie, la linea del tempo, la mappa muta e la parola smontata:
## sono quelle che servono a storia, geografia, latino e geometria, circa altri
## seicento esercizi. Aggiungerne una vuol dire una voce in `per_item`, una in
## `descrizione` e una in `_draw`.

const MAPPE := preload("res://scripts/visual/map_geometry_catalog.gd")

## I paesi che la carta d'Europa sa indicare, col nome che il bambino legge nella
## domanda. La geometria e i punti sono gia' in `MapGeometryCatalog` — presi da
## Natural Earth — e qui c'e' solo il ponte fra l'italiano e le sue chiavi.
const PAESI_SULLA_CARTA := {
	"italia": "italy", "francia": "france", "spagna": "spain", "germania": "germany",
	"polonia": "poland", "grecia": "greece", "regno unito": "united_kingdom",
	"inghilterra": "united_kingdom", "irlanda": "ireland", "islanda": "iceland",
	"norvegia": "norway", "svezia": "sweden", "finlandia": "finland",
	"ucraina": "ukraine",
}

## Le ere che la linea del tempo mostra, nell'ordine in cui sono accadute. Gli
## argomenti del banco di storia ne nominano cinque; `cronologia` le riguarda
## tutte e accende la linea senza puntare a nessuna.
const ERE := ["preistoria", "egizi", "grecia", "roma", "medioevo"]
const ERE_ETICHETTE := {
	"preistoria": "Preistoria", "egizi": "Egizi", "grecia": "Grecia",
	"roma": "Roma", "medioevo": "Medioevo",
}

## I sei casi latini nell'ordine in cui si recitano. Vederli in colonna con
## acceso quello chiesto e' la cosa che una tabella su carta fa da sempre e che
## il gioco non faceva.
const CASI := ["nominativo", "genitivo", "dativo", "accusativo", "vocativo", "ablativo"]

## Le sette note, nell'ordine in cui si cantano. Una scala che si vede è un'altra
## cosa rispetto a un elenco: «dopo il sol viene il la» diventa ovvio quando i
## gradini sono disegnati e si sale da sinistra a destra.
const NOTE := ["do", "re", "mi", "fa", "sol", "la", "si"]

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
	custom_minimum_size = Vector2(0, ALTEZZA_ALTA if tipo in ["casi", "mappa"] else ALTEZZA)
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

	# **Il coding viene prima della retta.** Una lista Python — `[10, 20, 30]` — al
	# lettore di espressioni regolari sembra una serie numerica, e finiva disegnata
	# come una retta: figura sbagliata, e per un bambino una figura sbagliata pesa
	# più di una frase sbagliata, perché ci si fida di quello che si vede.
	if materia == "coding":
		var lista := _lista_da(prompt)
		if not lista.is_empty():
			return {"tipo": "lista", "dati": lista}

	# La retta dei numeri: una serie scritta nel testo si guarda meglio distesa.
	var serie := _serie_da(prompt)
	if serie.size() >= 3:
		return {"tipo": "retta", "dati": {"valori": serie, "risposta": risposta}}

	if materia == "matematica" and _e_di_contorno(prompt, risposta):
		var basso_geo := (prompt + " " + risposta).to_lower()
		return {"tipo": "contorno", "dati": {
			"cosa": "area" if basso_geo.contains("area") or basso_geo.contains("superficie")
				else "perimetro"}}

	if materia == "latino":
		var smontata := _parola_smontata(prompt, risposta, topic)
		if not smontata.is_empty():
			return {"tipo": "parola", "dati": smontata}
		if topic == "casi":
			var quale := ""
			for caso_dato in CASI:
				if risposta.to_lower().contains(str(caso_dato)):
					quale = str(caso_dato)
					break
			if quale != "":
				return {"tipo": "casi", "dati": {"scelto": quale}}

	if materia == "storia":
		if topic == "cronologia":
			return {"tipo": "tempo", "dati": {"era": ""}}
		if ERE.has(topic):
			return {"tipo": "tempo", "dati": {"era": topic}}

	if materia == "geografia":
		var bersaglio := _paese_nominato(prompt + " " + risposta)
		if bersaglio != "":
			return {"tipo": "mappa", "dati": {"carta": "europe", "bersaglio": bersaglio}}

	if materia == "musica":
		var tempo_re := RegEx.create_from_string("([2-9])/([248])")
		var misura := tempo_re.search(prompt + " " + risposta)
		if misura != null:
			return {"tipo": "battuta", "dati": {
				"movimenti": int(misura.get_string(1)), "sotto": int(misura.get_string(2))}}
		if topic == "note":
			var quale_nota := ""
			for nota_dato in NOTE:
				if _nomina(risposta, str(nota_dato)) or _nomina(prompt, str(nota_dato)):
					quale_nota = str(nota_dato)
					break
			return {"tipo": "note", "dati": {"scelta": quale_nota}}

	if materia == "italiano":
		var frase := _frase_evidenziata(prompt)
		if not frase.is_empty():
			return {"tipo": "frase", "dati": frase}

	# **Le parole imparentate, disegnate.** La stessa figura della parola smontata
	# latina, usata sull'inglese: le lettere in comune accese dicono a colpo
	# d'occhio che «insert» e «inserire» sono la stessa parola.
	#
	# **Mai sui falsi amici.** Li' la somiglianza E' la trappola: disegnare
	# «library» e «libreria» con la radice accesa insegnerebbe l'errore che quelle
	# voci esistono apposta per prevenire.
	if materia == "inglese" and topic != "false-friends":
		var chiesta := RegEx.create_from_string('"([^"]+)"').search(prompt)
		if chiesta != null:
			var imparentata := _spezza(risposta, str(chiesta.get_string(1)), "etimologia", 4)
			if not imparentata.is_empty():
				imparentata["madre"] = str(chiesta.get_string(1))
				return {"tipo": "parola", "dati": imparentata}

	return {}

## Una parola intera dentro un testo, non un pezzo di un'altra: «la» non deve
## accendersi dentro «lavagna».
static func _nomina(testo: String, parola: String) -> bool:
	var confine := RegEx.create_from_string("(?i)(^|[^a-zA-Zàèéìòù])%s([^a-zA-Zàèéìòù]|$)" % parola)
	return confine.search(testo) != null

## I valori di una lista Python scritta nel testo, oppure quelli che `range(n)`
## produce. Sono la stessa figura: caselle numerate da zero.
static func _lista_da(prompt: String) -> Dictionary:
	var lista_re := RegEx.create_from_string("\\[\\s*(\\d+(?:\\s*,\\s*\\d+)+)\\s*\\]")
	var trovato := lista_re.search(prompt)
	if trovato != null:
		var valori: Array = []
		for pezzo in trovato.get_string(1).split(","):
			valori.append(str(pezzo).strip_edges())
		if valori.size() <= 8:
			return {"valori": valori, "titolo": "gli indici partono da zero"}
	var range_re := RegEx.create_from_string("range\\(\\s*(\\d+)\\s*\\)")
	trovato = range_re.search(prompt)
	if trovato != null:
		var quanti := int(trovato.get_string(1))
		if quanti >= 2 and quanti <= 8:
			var generati: Array = []
			for i in quanti:
				generati.append(str(i))
			return {"valori": generati, "titolo": "range(%d) si ferma PRIMA di %d" % [quanti, quanti]}
	return {}

## La frase dell'esercizio con acceso il pezzo di cui si parla.
##
## Non prova a dire quale sia il soggetto o il complemento — quello lo chiede
## l'esercizio e indovinarlo sarebbe rispondere al posto del bambino. Mostra
## soltanto DOVE guardare, che nell'analisi logica è metà del lavoro.
static func _frase_evidenziata(prompt: String) -> Dictionary:
	var virgolette := RegEx.create_from_string("«([^»]+)»")
	var pezzi: Array = []
	for esito in virgolette.search_all(prompt):
		pezzi.append(str(esito.get_string(1)))
	if pezzi.size() < 2:
		return {}
	var frase := str(pezzi[0])
	var dentro := str(pezzi[1])
	if frase.split(" ").size() < 3 or not frase.contains(dentro) or dentro == frase:
		return {}
	return {"testo": frase, "pezzo": dentro}

## I numeri di una serie scritta nel testo: «2, 4, 6, 8, ?». Servono almeno tre
## termini, altrimenti non e' una serie ed e' solo un elenco.
static func _serie_da(prompt: String) -> Array:
	var espressione := RegEx.create_from_string("(\\d+)(\\s*,\\s*\\d+){2,}")
	var trovato := espressione.search(prompt)
	if trovato == null:
		return []
	var valori: Array = []
	for pezzo in trovato.get_string(0).split(","):
		valori.append(int(str(pezzo).strip_edges()))
	# Oltre gli otto termini la retta si affolla e smette di aiutare.
	return valori if valori.size() <= 8 else []

static func _e_di_contorno(prompt: String, risposta: String) -> bool:
	var basso := (prompt + " " + risposta).to_lower()
	return (basso.contains("perimetro") or basso.contains("contorno")
		or basso.contains("area") or basso.contains("superficie"))

## La parola smontata: quanto e' radice e quanto e' desinenza.
##
## Due casi, la stessa figura. Nelle declinazioni il testo porta la forma e la
## voce di partenza — «"dominorum" (da "dominus")» — e la radice e' il pezzo che
## hanno in comune: `domin` + `orum`. Nell'etimologia c'e' la parola italiana e
## quella latina — «acqua» da *aqua* — e il pezzo comune e' la ragione per cui la
## seconda si riconosce nella prima.
##
## Sotto le due lettere in comune non c'e' niente da mostrare: due parole che
## cominciano per «a» non sono imparentate, e disegnarlo sarebbe insegnare una
## cosa falsa.
static func _parola_smontata(prompt: String, risposta: String, topic: String) -> Dictionary:
	if topic.begins_with("declinazione"):
		var forma_re := RegEx.create_from_string('"([^"]+)"\\s*\\(da\\s*"([^"]+)"')
		var trovato := forma_re.search(prompt)
		if trovato != null:
			return _spezza(trovato.get_string(1), trovato.get_string(2), "declinazione")
		return {}
	if topic == "etimologia":
		var italiana := RegEx.create_from_string("«([^»]+)»").search(prompt)
		if italiana != null:
			return _spezza(str(italiana.get_string(1)), risposta, "etimologia")
	return {}

## `minime` è quante lettere in comune servono perché valga la pena dirlo.
##
## Per una declinazione tre bastano: la forma e la voce di partenza sono la stessa
## parola per costruzione, e `domin-` è davvero la radice. **Per due lingue
## diverse tre sono troppo poche**: «predict» e «prevedere» condividono soltanto
## «pre», che è un prefisso e non una parentela, e disegnarli con la radice accesa
## insegnerebbe una cosa falsa. Quattro è la stessa soglia che usa la glossa in
## `build-exercise-banks.mjs`, così il disegno e il testo non possono dissentire.
static func _spezza(forma: String, radice_madre: String, genere: String, minime: int = 3) -> Dictionary:
	var a := forma.to_lower()
	var b := radice_madre.to_lower()
	var comuni := 0
	while comuni < mini(a.length(), b.length()) and a[comuni] == b[comuni]:
		comuni += 1
	if comuni < minime or comuni >= forma.length():
		return {}
	return {
		"forma": forma, "radice": forma.substr(0, comuni),
		"desinenza": forma.substr(comuni), "madre": radice_madre, "genere": genere,
	}

static func _paese_nominato(testo: String) -> String:
	var basso := testo.to_lower()
	for nome_dato in PAESI_SULLA_CARTA.keys():
		if basso.contains(str(nome_dato)):
			return str(PAESI_SULLA_CARTA[nome_dato])
	return ""

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
		"retta":
			var valori: Array = dati.get("valori", [])
			return "I numeri della serie messi in fila su una retta: %s, e poi il posto vuoto." % (
				", ".join(PackedStringArray(valori.map(func(v): return str(v)))))
		"contorno":
			if str(dati.get("cosa", "")) == "area":
				return "Un rettangolo con dentro tutti i quadretti colorati: l'area è quanto sta dentro."
			return "Un rettangolo con solo il bordo acceso: il perimetro è la lunghezza del giro."
		"parola":
			return "La parola «%s» spezzata in due: la radice «%s» e la desinenza «%s»." % [
				str(dati.get("forma", "")), str(dati.get("radice", "")), str(dati.get("desinenza", ""))]
		"casi":
			return "I sei casi latini in colonna, con «%s» acceso." % str(dati.get("scelto", ""))
		"tempo":
			var era := str(dati.get("era", ""))
			if era == "":
				return "La linea del tempo: preistoria, egizi, Grecia, Roma, Medioevo."
			return "La linea del tempo, con «%s» acceso al suo posto." % str(
				ERE_ETICHETTE.get(era, era))
		"mappa":
			return "La sagoma dell'Europa con un punto acceso dove si trova il paese della domanda."
		"battuta":
			return "Una battuta divisa in %d caselle uguali, con il primo movimento acceso." % int(
				dati.get("movimenti", 0))
		"note":
			var scelta := str(dati.get("scelta", ""))
			if scelta == "":
				return "Le sette note come sette gradini che salgono, e poi il do che ricomincia."
			return "Le sette note come gradini che salgono, con «%s» acceso al suo posto." % scelta
		"lista":
			var valori: Array = dati.get("valori", [])
			return "%d caselle in fila, numerate da zero: %s." % [
				valori.size(), ", ".join(PackedStringArray(valori.map(func(v): return str(v))))]
		"frase":
			return "La frase «%s» con acceso il pezzo «%s»." % [
				str(dati.get("testo", "")), str(dati.get("pezzo", ""))]
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
		"retta": _disegna_retta()
		"contorno": _disegna_contorno()
		"parola": _disegna_parola()
		"casi": _disegna_casi()
		"tempo": _disegna_tempo()
		"mappa": _disegna_mappa()
		"battuta": _disegna_battuta()
		"note": _disegna_note()
		"lista": _disegna_lista()
		"frase": _disegna_frase()

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

## **La retta dei numeri.** Una serie scritta di fila — «2, 4, 6, 8, ?» — dice il
## passo solo a chi lo calcola; distesa su una retta il passo si *vede*, perché è
## la distanza fra un segno e il successivo. È la figura che rende visibile la
## regola invece del risultato, che è quello che questo gioco cerca di insegnare.
func _disegna_retta() -> void:
	var valori: Array = dati.get("valori", [])
	if valori.size() < 2:
		return
	var minimo := int(valori[0])
	var massimo := int(valori[0])
	for v in valori:
		minimo = mini(minimo, int(v))
		massimo = maxi(massimo, int(v))
	# Il posto vuoto continua la serie: si tiene spazio per un passo in più.
	var passo := absi(int(valori[1]) - int(valori[0]))
	var fine := massimo + maxi(1, passo)
	var inizio := minimo - maxi(1, passo) / 2
	var ampiezza := maxf(1.0, float(fine - inizio))
	var margine := 22.0
	var y := _altezza() * 0.46
	var larghezza := size.x - margine * 2.0
	draw_line(Vector2(margine, y), Vector2(margine + larghezza, y), COLORE_TRATTO, 2.0)
	var font := get_theme_default_font()
	for v in valori:
		var x := margine + larghezza * (float(int(v) - inizio) / ampiezza)
		draw_circle(Vector2(x, y), 6.0, COLORE_PIENO)
		if font != null:
			draw_string(
				font, Vector2(x - 14.0, y + 24.0), str(v),
				HORIZONTAL_ALIGNMENT_CENTER, 28, 14, COLORE_TESTO)
	# Il posto vuoto: un cerchio non pieno, dove la serie andrebbe a finire.
	var x_vuoto := margine + larghezza * (float(fine - inizio) / ampiezza)
	draw_arc(Vector2(x_vuoto, y), 7.0, 0.0, TAU, 20, COLORE_ACCENTO, 2.0)
	if font != null:
		draw_string(
			font, Vector2(x_vuoto - 14.0, y + 24.0), "?",
			HORIZONTAL_ALIGNMENT_CENTER, 28, 15, COLORE_ACCENTO)

## **Il contorno contro la superficie.** Perimetro e area rispondono a due
## domande diverse — quanto filo per recintare, quanta vernice per dipingere — e
## sbagliare formula è quasi sempre sbagliare domanda. Nel disegno la differenza
## non si spiega: si vede quale delle due parti è accesa.
func _disegna_contorno() -> void:
	var area := str(dati.get("cosa", "")) == "area"
	var margine := 16.0
	var lato_y := _altezza() - margine * 2.0 - 16.0
	var rect := Rect2(
		Vector2(margine, margine),
		Vector2(minf(size.x - margine * 2.0, lato_y * 1.7), lato_y))
	if area:
		draw_rect(rect, Color(COLORE_ACCENTO.r, COLORE_ACCENTO.g, COLORE_ACCENTO.b, 0.55), true)
		draw_rect(rect, COLORE_TRATTO, false, 2.0)
	else:
		draw_rect(rect, Color(COLORE_PIENO.r, COLORE_PIENO.g, COLORE_PIENO.b, 0.10), true)
		draw_rect(rect, COLORE_ACCENTO, false, 5.0)
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(
		font, Vector2(rect.position.x + rect.size.x + 16.0, rect.position.y + rect.size.y * 0.5),
		"quanto sta dentro" if area else "il giro intorno",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLORE_TESTO)

## **La parola smontata.** Una declinazione non è una lista da imparare a memoria:
## è una parola che tiene ferma la testa e cambia la coda. Mostrare i due pezzi
## con due colori dice in un colpo solo che cos'è la radice e che cos'è la
## desinenza — e vale anche per l'etimologia, dove il pezzo comune è la ragione
## per cui la parola latina si riconosce dentro quella italiana.
func _disegna_parola() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var radice := str(dati.get("radice", ""))
	var desinenza := str(dati.get("desinenza", ""))
	var corpo := 30
	var largo_radice := font.get_string_size(radice, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	var largo_desinenza := font.get_string_size(desinenza, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	var x := 18.0
	var y := _altezza() * 0.46
	# Due sottolineature spesse: il colore separa i pezzi senza spezzare la parola,
	# che deve restare leggibile come una parola sola.
	draw_rect(Rect2(Vector2(x, y + 6.0), Vector2(largo_radice, 4.0)), COLORE_PIENO)
	draw_rect(Rect2(Vector2(x + largo_radice, y + 6.0), Vector2(largo_desinenza, 4.0)), COLORE_ACCENTO)
	draw_string(font, Vector2(x, y), radice, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, COLORE_PIENO)
	draw_string(
		font, Vector2(x + largo_radice, y), desinenza,
		HORIZONTAL_ALIGNMENT_LEFT, -1, corpo, COLORE_ACCENTO)
	var didascalia := "radice + desinenza"
	if str(dati.get("genere", "")) == "etimologia":
		didascalia = "dentro c'è «%s»" % str(dati.get("madre", ""))
	draw_string(
		font, Vector2(18.0, _altezza() - 10.0), didascalia,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLORE_TESTO)

## **I sei casi in colonna.** La tabella che ogni libro di latino ha in prima
## pagina, e che il gioco non mostrava mai: sapere che il genitivo è il secondo
## dei sei è metà del lavoro di ricordarsi che cosa fa.
func _disegna_casi() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var scelto := str(dati.get("scelto", ""))
	var passo := (_altezza() - 16.0) / float(CASI.size())
	for indice in CASI.size():
		var nome := str(CASI[indice])
		var acceso := nome == scelto
		var y := 10.0 + passo * float(indice)
		if acceso:
			draw_rect(
				Rect2(Vector2(12.0, y - 1.0), Vector2(196.0, passo - 3.0)),
				Color(COLORE_ACCENTO.r, COLORE_ACCENTO.g, COLORE_ACCENTO.b, 0.24), true)
		draw_string(
			font, Vector2(22.0, y + passo * 0.72), nome.capitalize(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			COLORE_ACCENTO if acceso else Color(COLORE_TESTO.r, COLORE_TESTO.g, COLORE_TESTO.b, 0.55))

## **La linea del tempo.** «Prima» e «dopo» sono la sola cosa che la storia chiede
## davvero a undici anni, e in un elenco di argomenti non si vedono. Qui le cinque
## ere stanno in fila e quella dell'esercizio è accesa: il bambino sa sempre dove
## si trova.
func _disegna_tempo() -> void:
	var font := get_theme_default_font()
	var era := str(dati.get("era", ""))
	var margine := 20.0
	var y := _altezza() * 0.40
	var larghezza := size.x - margine * 2.0
	draw_line(Vector2(margine, y), Vector2(margine + larghezza, y), COLORE_TRATTO, 2.0)
	# La freccia in fondo: il tempo va da qualche parte, e la linea deve dirlo.
	draw_line(
		Vector2(margine + larghezza - 9.0, y - 5.0), Vector2(margine + larghezza, y),
		COLORE_TRATTO, 2.0)
	draw_line(
		Vector2(margine + larghezza - 9.0, y + 5.0), Vector2(margine + larghezza, y),
		COLORE_TRATTO, 2.0)
	var passo := larghezza / float(ERE.size())
	for indice in ERE.size():
		var nome := str(ERE[indice])
		var acceso := nome == era
		var x := margine + passo * (float(indice) + 0.5)
		draw_circle(Vector2(x, y), 7.0 if acceso else 4.0, COLORE_ACCENTO if acceso else COLORE_PIENO)
		if font != null:
			draw_string(
				font, Vector2(x - passo * 0.5, y + 24.0), str(ERE_ETICHETTE.get(nome, nome)),
				HORIZONTAL_ALIGNMENT_CENTER, passo, 13,
				COLORE_ACCENTO if acceso else Color(COLORE_TESTO.r, COLORE_TESTO.g, COLORE_TESTO.b, 0.6))

## **La carta muta.** La sagoma dell'Europa con un punto acceso dove sta il paese
## della domanda. La geometria non è disegnata a mano: viene da
## `MapGeometryCatalog`, che la porta da Natural Earth ed è già quella usata dalle
## carte mute del gioco — una sola fonte, così due parti del gioco non possono
## disegnare due Europe diverse.
func _disegna_mappa() -> void:
	var carta: Dictionary = MAPPE.map_data(str(dati.get("carta", "europe")))
	if carta.is_empty():
		return
	var bounds: Rect2 = carta.get("bounds", Rect2())
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	var margine := 10.0
	var utile := Vector2(size.x - margine * 2.0, _altezza() - margine * 2.0)
	var scala := minf(utile.x / bounds.size.x, utile.y / bounds.size.y)
	var scarto := Vector2(
		margine + (utile.x - bounds.size.x * scala) * 0.5,
		margine + (utile.y - bounds.size.y * scala) * 0.5)
	for poligono_dato in Array(carta.get("polygons", [])):
		var poligono: PackedVector2Array = poligono_dato
		if poligono.size() < 3:
			continue
		var proiettato := PackedVector2Array()
		for punto in poligono:
			proiettato.append(_su_schermo(punto, bounds, scala, scarto))
		draw_colored_polygon(proiettato, Color(COLORE_PIENO.r, COLORE_PIENO.g, COLORE_PIENO.b, 0.26))
		draw_polyline(proiettato, COLORE_TRATTO, 1.0)
	var bersagli: Dictionary = carta.get("targets", {})
	var chiave := str(dati.get("bersaglio", ""))
	if bersagli.has(chiave):
		var punto := _su_schermo(bersagli[chiave], bounds, scala, scarto)
		draw_circle(punto, 6.0, COLORE_ACCENTO)
		draw_arc(punto, 11.0, 0.0, TAU, 24, COLORE_ACCENTO, 2.0)

## Da gradi a pixel. **La latitudine cresce verso nord e lo schermo verso il
## basso**: senza il capovolgimento l'Europa uscirebbe a testa in giù, ed è il
## genere di errore che un bambino nota prima di qualunque adulto.
func _su_schermo(punto: Vector2, bounds: Rect2, scala: float, scarto: Vector2) -> Vector2:
	return scarto + Vector2(
		(punto.x - bounds.position.x) * scala,
		(bounds.position.y + bounds.size.y - punto.y) * scala)

## **La battuta divisa.** Un tempo di 4/4 non è una frazione: il numero sopra dice
## quanti movimenti stanno in una battuta, quello sotto che figura vale un
## movimento. Scritto è un rebus, disegnato è una scatola con dentro quattro
## caselle uguali — e a quel punto «quanti movimenti ci sono in 4/4» non è più una
## domanda.
func _disegna_battuta() -> void:
	var movimenti := maxi(1, int(dati.get("movimenti", 4)))
	var sotto := maxi(1, int(dati.get("sotto", 4)))
	var margine := 18.0
	var alta := _altezza() - margine * 2.0 - 18.0
	var larga := minf(size.x - margine * 2.0, 40.0 * float(movimenti) + 20.0)
	var passo := larga / float(movimenti)
	for indice in movimenti:
		var casella := Rect2(
			Vector2(margine + passo * float(indice) + 3.0, margine),
			Vector2(passo - 6.0, alta))
		# Il primo movimento è quello forte: in musica è la cosa che si sente, e
		# nel disegno deve vedersi.
		draw_rect(casella, COLORE_ACCENTO if indice == 0 else COLORE_PIENO, indice == 0)
		if indice != 0:
			draw_rect(casella, Color(COLORE_PIENO.r, COLORE_PIENO.g, COLORE_PIENO.b, 0.22), true)
			draw_rect(casella, COLORE_PIENO, false, 2.0)
	# Le stanghette che chiudono la battuta: sono il segno che dice «qui si conta
	# da capo», ed è tutto il senso della misura.
	draw_line(Vector2(margine, margine), Vector2(margine, margine + alta), COLORE_TRATTO, 3.0)
	draw_line(
		Vector2(margine + larga, margine), Vector2(margine + larga, margine + alta),
		COLORE_TRATTO, 3.0)
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(
		font, Vector2(margine, _altezza() - 4.0),
		"%d movimenti in una battuta, e ognuno vale un %s" % [movimenti, _figura_di(sotto)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLORE_TESTO)

## Che figura vale un movimento, dal numero sotto la frazione.
func _figura_di(sotto: int) -> String:
	match sotto:
		2: return "minima"
		4: return "quarto (semiminima)"
		8: return "ottavo (croma)"
	return "movimento"

## **La scala delle sette note.** «Dopo il sol viene il la» è un elenco da
## ricordare finché le note stanno in fila su una riga; diventa ovvio quando sono
## sette gradini che salgono, e si vede che dopo il si si ricomincia dal do più in
## alto.
func _disegna_note() -> void:
	var scelta := str(dati.get("scelta", ""))
	var margine := 16.0
	var larga := size.x - margine * 2.0
	var passo := minf(larga / float(NOTE.size() + 1), 46.0)
	var base := _altezza() - 26.0
	var salita := (_altezza() - 44.0) / float(NOTE.size())
	var font := get_theme_default_font()
	for indice in NOTE.size():
		var nome := str(NOTE[indice])
		var acceso := nome == scelta
		var y := base - salita * float(indice)
		var gradino := Rect2(
			Vector2(margine + passo * float(indice), y), Vector2(passo - 5.0, 7.0))
		draw_rect(gradino, COLORE_ACCENTO if acceso else COLORE_PIENO, true)
		if font != null:
			draw_string(
				font, Vector2(margine + passo * float(indice), y - 4.0), nome,
				HORIZONTAL_ALIGNMENT_CENTER, passo - 5.0, 14,
				COLORE_ACCENTO if acceso else Color(COLORE_TESTO.r, COLORE_TESTO.g, COLORE_TESTO.b, 0.65))
	# L'ottavo gradino: il do che ricomincia più in alto. Senza, la scala sembra
	# finire, e invece gira.
	var y_ottava := base - salita * float(NOTE.size())
	draw_rect(
		Rect2(Vector2(margine + passo * float(NOTE.size()), y_ottava), Vector2(passo - 5.0, 7.0)),
		Color(COLORE_PIENO.r, COLORE_PIENO.g, COLORE_PIENO.b, 0.35), true)
	if font != null:
		draw_string(
			font, Vector2(margine + passo * float(NOTE.size()), y_ottava - 4.0), "do",
			HORIZONTAL_ALIGNMENT_CENTER, passo - 5.0, 14,
			Color(COLORE_TESTO.r, COLORE_TESTO.g, COLORE_TESTO.b, 0.4))

## **La lista con gli indici.** L'errore più comune di chi comincia a programmare
## non è un errore di logica: è credere che il primo elemento sia il numero uno.
## Le caselle con sotto lo zero, l'uno e il due lo dicono senza spiegarlo — e la
## stessa figura serve a `range(3)`, che si ferma prima del tre per la stessa
## ragione.
func _disegna_lista() -> void:
	var valori: Array = dati.get("valori", [])
	if valori.is_empty():
		return
	var font := get_theme_default_font()
	var margine := 16.0
	var passo := minf((size.x - margine * 2.0) / float(valori.size()), 66.0)
	var alta := _altezza() - 58.0
	for indice in valori.size():
		var casella := Rect2(
			Vector2(margine + passo * float(indice) + 3.0, 14.0), Vector2(passo - 8.0, alta))
		draw_rect(casella, Color(COLORE_PIENO.r, COLORE_PIENO.g, COLORE_PIENO.b, 0.22), true)
		draw_rect(casella, COLORE_PIENO, false, 2.0)
		if font == null:
			continue
		draw_string(
			font, Vector2(casella.position.x, casella.position.y + alta * 0.68),
			str(valori[indice]), HORIZONTAL_ALIGNMENT_CENTER, casella.size.x, 17, COLORE_TESTO)
		# L'indice sta SOTTO la casella, e in un altro colore: è un'etichetta del
		# posto, non un valore dentro la lista. Confonderli è l'errore stesso.
		draw_string(
			font, Vector2(casella.position.x, 14.0 + alta + 17.0), str(indice),
			HORIZONTAL_ALIGNMENT_CENTER, casella.size.x, 14, COLORE_ACCENTO)
	if font != null:
		draw_string(
			font, Vector2(margine, _altezza() - 4.0), str(dati.get("titolo", "")),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLORE_TESTO)

## **La frase con il pezzo acceso.** Nell'analisi logica metà della fatica è
## capire di quale pezzo si sta parlando: la domanda nomina «un libro» e il
## bambino deve ritrovarlo dentro la frase prima ancora di poterlo classificare.
##
## La figura si ferma lì di proposito: **non dice** se quel pezzo è soggetto o
## complemento — quello lo chiede l'esercizio, e indovinarlo sarebbe rispondere al
## posto suo.
func _disegna_frase() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var testo := str(dati.get("testo", ""))
	var pezzo := str(dati.get("pezzo", ""))
	var taglio := testo.find(pezzo)
	if taglio < 0:
		return
	var corpo := 19
	var prima := testo.substr(0, taglio)
	var dopo := testo.substr(taglio + pezzo.length())
	var x := 16.0
	var y := _altezza() * 0.44
	var largo_prima := font.get_string_size(prima, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	var largo_pezzo := font.get_string_size(pezzo, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo).x
	# Il riquadro dietro il pezzo: si vede prima delle parole, ed è quello che
	# fa da indice puntato.
	draw_rect(
		Rect2(Vector2(x + largo_prima - 3.0, y - float(corpo) + 2.0),
			Vector2(largo_pezzo + 6.0, float(corpo) + 8.0)),
		Color(COLORE_ACCENTO.r, COLORE_ACCENTO.g, COLORE_ACCENTO.b, 0.26), true)
	draw_string(font, Vector2(x, y), prima, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo,
		Color(COLORE_TESTO.r, COLORE_TESTO.g, COLORE_TESTO.b, 0.65))
	draw_string(font, Vector2(x + largo_prima, y), pezzo, HORIZONTAL_ALIGNMENT_LEFT, -1, corpo,
		COLORE_ACCENTO)
	draw_string(font, Vector2(x + largo_prima + largo_pezzo, y), dopo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, corpo,
		Color(COLORE_TESTO.r, COLORE_TESTO.g, COLORE_TESTO.b, 0.65))
	draw_string(
		font, Vector2(16.0, _altezza() - 10.0), "la domanda parla di questo pezzo",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLORE_TESTO)
