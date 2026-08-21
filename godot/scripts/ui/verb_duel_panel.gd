class_name VerbDuelPanel
extends DuelStage

## **IL DUELLO DELLE VOCI** — il campo del guardiano che chiede verbi.
## (17 agosto 2026)
##
## Il guardiano, i sigilli, la carica e la tenuta stanno in [[DuelStage]]: sono
## il combattimento, e non cambiano con la materia. Qui vive quello che è
## **dell'italiano**: i tre binari degli assi, la voce di Eli che si trasforma a
## ogni colpo, e le rune che spostano modo, tempo e persona.
##
## ## I tre binari, e perché non una tabella
##
## Il primo disegno era la tabella dei verbi: modi in riga, tempi in colonna,
## come sul libro. Non ci sta — a nove tempi e tre modi le intestazioni
## scendevano a corpo dieci, che su un tablet in mano a un bambino non è una
## tabella, è una macchia. E soprattutto non serviva: da una tabella si legge
## *dov'è tutto*, mentre qui bisogna leggere **dove sono io e dove devo
## arrivare**, che sono tre informazioni, una per asse.
##
## Quindi tre binari, uno sopra l'altro:
##
##     MODO      indicativo · [congiuntivo] · condizionale
##     TEMPO     presente · [imperfetto] · ~~passato remoto~~ · ~~futuro~~
##     PERSONA   io · tu · lui/lei · noi · [voi] · loro
##
## Sono la stessa idea della corda di risonanza del duello delle cifre — una
## scala su cui si vede a colpo d'occhio quanto manca — moltiplicata per le tre
## coordinate di una voce verbale. E fanno una cosa che una tabella stampata non
## può fare: **i tempi si spengono e si riaccendono mentre cambi modo**. Passi al
## condizionale e vedi sparire l'imperfetto e il futuro; torni all'indicativo e
## tornano. La forma del sistema verbale si impara guardandola muoversi, che è
## l'unico modo in cui a undici anni si impara qualcosa che sul libro è una
## griglia grigia.
##
## ## La voce che si trasforma
##
## Al centro, grande, c'è **la voce di Eli adesso**: `canto`. A ogni colpo
## cambia — `cantavo`, `cantavate`, `cantaste` — e sotto resta scritta la catena
## intera. È il quaderno del duello: il bambino rilegge la propria strada mentre
## la percorre, e vede il verbo piegarsi invece di leggerlo già piegato.
##
## ## Le rune
##
## Sei pietre in tre colonne e due righe, ognuna con l'**asse** scritto piccolo
## sopra e il **valore** grande sotto. L'asse scritto non è decorazione: modo,
## tempo e persona sono le tre parole che servono a parlare dei verbi, e un
## bambino che tocca trenta volte una pietra con scritto «tempo» sopra
## «imperfetto» non le confonde più.
##
## Una runa che qui non entra è **spenta e barrata**, come nel duello delle
## cifre: `tempo → passato remoto` è spenta nel congiuntivo, perché il
## congiuntivo il passato remoto non ce l'ha.

const RUNA_LARGA := 180.0
const RUNA_ALTA := 62.0
const RUNA_GAP := 12.0
const RUNA_COLONNE := 3

const Y_VOCE := 188.0
const Y_MODO := 236.0
const ALTEZZA_CHIP := 26.0
const X_BINARI := 92.0

var _cella: Dictionary = {}
var _voce_label: Label
## L'infinito del verbo di Eli, sotto la sua voce. Il cartiglio del guardiano
## scrive «da temere» sotto il campione dal primo giorno, per una ragione
## scritta in [[VerbDuel]]: il duello misura modi e tempi, non il vocabolario.
## Lo stesso ragionamento non era mai stato applicato al verbo di Eli, e chi
## leggeva «abbiate dato» doveva risalire da solo a «dare».
var _infinito_label: Label
## Dove cade ogni chip, ricalcolato a ogni disegno: serve al fascio del colpo,
## che deve arrivare sul binario dell'asse appena mosso.
var _ultimo_asse := "persona"
var _punti_chip: Dictionary = {}

func _init() -> void:
	geo["larghezza"] = 700.0
	geo["arena"] = 400.0
	geo["rune"] = 140.0
	geo["ySigilli"] = 10.0
	geo["yArte"] = 16.0
	geo["latoArte"] = 124.0
	geo["yTarga"] = 118.0
	geo["altezzaTarga"] = 60.0
	geo["yCarica"] = 182.0
	geo["larghezzaCarica"] = 280.0

func _costruisci_campo() -> void:
	_voce_label = etichetta("DuelVerbForm", 30, GHIACCIO)
	_arena.add_child(_voce_label)
	_infinito_label = etichetta("DuelVerbInfinitive", 13, Color("9fd8d2"))
	_arena.add_child(_infinito_label)

func _nuovo_scambio() -> void:
	_scambio = VerbDuel.genera_scambio(_rng, regole)
	_rune = Array(_scambio.get("rune", []))
	_usate.clear()
	_cella = Dictionary(_scambio.get("partenza", {})).duplicate()
	_catena = [VerbDuel.voce_di(_scambio, _cella)]
	_colpi_dati = 0
	_ultimo_asse = "persona"
	_tempo_massimo = DuelRules.secondi_del_sigillo(regole, _sigilli_rotti)
	_tempo = _tempo_massimo
	# **Il cartiglio si adatta a quello che porta.** Una voce sola («staremmo») sta
	# grande; un'etichetta intera («indicativo passato prossimo») a corpo trentaquattro
	# usciva dalla cornice d'oro — visto nella sonda, al primo mondo, cioè proprio
	# dove l'etichetta è l'unica cosa che il bambino ha per orientarsi. Quindi
	# l'etichetta si spezza in due: modo e tempo sopra, la persona sotto.
	var sigillo: Dictionary = _scambio.get("sigillo", {})
	if str(sigillo.get("tipo", "")) == "descrizione":
		# La descrizione e' una frase, non due parole: va a capo e sta piu'
		# piccola, o esce dalla cornice d'oro.
		_sigillo_label.add_theme_font_size_override("font_size", 17)
		_sigillo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_sigillo_label.text = str(sigillo.get("testo", ""))
		_sigillo_sotto.text = str(sigillo.get("sotto", ""))
	else:
		_sigillo_label.add_theme_font_size_override("font_size", 30)
		_sigillo_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_sigillo_label.text = str(sigillo.get("testo", ""))
		_sigillo_sotto.text = str(sigillo.get("sotto", ""))
	_costruisci_rune()
	_aggiorna_testi()

func _costruisci_rune() -> void:
	for nodo in _rune_label:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_rune_label.clear()
	for indice in _rune.size():
		var nodo := etichetta("DuelRune%d" % indice, 20, TESTO)
		nodo.text = str(Dictionary(_rune[indice]).get("testo", ""))
		_rune_zona.add_child(nodo)
		_rune_label.append(nodo)

func colpisci(indice: int) -> void:
	if not _attivo or _in_pausa or indice < 0 or indice >= _rune.size() or _usate.has(indice):
		return
	var runa: Dictionary = _rune[indice]
	var prossima := VerbDuel.applica(_cella, runa)
	if prossima.is_empty():
		# La runa spenta non è un errore: quella casella non esiste, o è quella
		# dove sei già. Costa il tempo che ci si è messi a provarla — che è già
		# la lezione su com'è fatto il sistema dei verbi.
		runa_spenta()
		return
	var bersaglio: Dictionary = _scambio.get("bersaglio", {})
	var prima := VerbDuel.assi_diversi(_cella, bersaglio)
	_usate[indice] = true
	_cella = prossima
	_ultimo_asse = str(runa.get("asse", "persona"))
	_colpi_dati += 1
	# **La runa entra fra parentesi quadre, e con il suo asse davanti.**
	# (21 agosto 2026) La catena scriveva «servissimo -> indicativo ->
	# servivamo»: tre parole con la stessa grafica, e in un gioco di grammatica
	# «servissimo -> indicativo» si legge come «servissimo E' indicativo», che e'
	# falso. Adesso la voce e il colpo hanno due forme diverse.
	_catena.append("[%s: %s]" % [str(runa.get("asse", "")), str(runa.get("testo", ""))])
	_catena.append(VerbDuel.voce_di(_scambio, _cella))
	segna_colpo(indice)
	_aggiorna_testi()

	if VerbDuel.uguali(_cella, bersaglio):
		spezza_sigillo()
		return
	# L'intonazione sale quando si è avvicinato un asse: l'orecchio conferma
	# quello che i binari mostrano, e conferma anche quando si è andati indietro.
	var dopo_colpo := VerbDuel.assi_diversi(_cella, bersaglio)
	suona("enigmaProgress", 1.30 if dopo_colpo < prima else 0.92)
	if _colpi_dati >= int(regole.get("colpi", 3)):
		incassa()
		return
	# **La strada chiusa.** Con le rune rimaste il sigillo non si fa più: il
	# guardiano chiude lo scambio subito invece di lasciar scorrere la carica su
	# una partita già persa.
	if sequenza_vincente().is_empty():
		incassa()

func sequenza_vincente() -> Array:
	if _scambio.is_empty():
		return []
	var mappa: Array = []
	var mano: Array = []
	for indice in _rune.size():
		if _usate.has(indice):
			continue
		mappa.append(indice)
		mano.append(_rune[indice])
	var rimasti := int(regole.get("colpi", 3)) - _colpi_dati
	var percorso := VerbDuel.percorso_minimo(
		_cella, Dictionary(_scambio.get("bersaglio", {})), mano, maxi(rimasti, 1))
	var fuori: Array = []
	for passo in percorso:
		fuori.append(int(mappa[int(passo)]))
	return fuori

func _aggiorna_testi() -> void:
	if not is_instance_valid(_stato):
		return
	_voce_label.text = VerbDuel.voce_di(_scambio, _cella)
	if is_instance_valid(_infinito_label):
		_infinito_label.text = "il tuo verbo: %s" % str(_scambio.get("infinito", ""))
	_catena_label.text = _riga_catena()
	aggiorna_stato()

## La catena come la si rilegge: `canto → imperfetto → cantavo → voi →
## cantavate`. Prima del primo colpo sarebbe la ripetizione della voce già
## scritta grande, e quel posto vale di più occupato dall'unica istruzione che
## questo minigioco ha bisogno di dare.
func _riga_catena() -> String:
	if _catena.size() <= 1:
		return "porta il verbo sulla casella del sigillo, un asse alla volta"
	var pezzi: Array = _catena.duplicate()
	while pezzi.size() > 7:
		pezzi.remove_at(0)
	return " → ".join(PackedStringArray(pezzi))

func _posiziona_campo() -> void:
	_voce_label.size = Vector2(_arena.size.x - 40.0, 42)
	_voce_label.position = Vector2(20, Y_VOCE)
	_infinito_label.size = Vector2(_arena.size.x - 40.0, 16)
	_infinito_label.position = Vector2(20, Y_VOCE + 34.0)
	for indice in _rune_label.size():
		var nodo: Label = _rune_label[indice]
		if not is_instance_valid(nodo):
			continue
		var rect := rettangolo_runa(indice)
		nodo.size = Vector2(rect.size.x, 26)
		nodo.position = Vector2(rect.position.x, rect.position.y + 26.0)
		var entra := VerbDuel.applicabile(_cella, _rune[indice])
		nodo.modulate.a = 0.22 if _usate.has(indice) else (0.40 if not entra else 1.0)

# --- I tre binari -------------------------------------------------------------

## I valori di ogni asse, nell'ordine in cui la grammatica li elenca. Non
## alfabetico e non a piacere: presente, imperfetto, passato remoto, futuro è
## l'ordine del libro, ed è quello che il bambino sta cercando di memorizzare.
func _valori(asse: String) -> Array:
	match asse:
		"modo":
			var modi: Array = []
			for m in VerbConjugator.MODI:
				if Array(regole.get("modi", [])).has(str(m)):
					modi.append(str(m))
			return modi
		"tempo":
			var tempi: Array = []
			var ammessi: Array = regole.get("tempi", [])
			for modo in VerbConjugator.MODI:
				for t in Array(VerbConjugator.TEMPI[modo]):
					if ammessi.has(str(t)) and not tempi.has(str(t)):
						tempi.append(str(t))
			return tempi
		_:
			return range(6)

func _testo_valore(asse: String, valore) -> String:
	return str(VerbConjugator.PERSONE[int(valore)]) if asse == "persona" else str(valore)

## Un valore è **giocabile adesso** se la casella che ne uscirebbe esiste. È il
## motivo per cui i tempi si spengono quando passi al condizionale: non è una
## regola del gioco, è che quelle caselle non ci sono.
func _valore_vivo(asse: String, valore) -> bool:
	match asse:
		"modo":
			return VerbConjugator.casella_esiste(str(valore), str(_cella.get("tempo", "")))
		"tempo":
			return VerbConjugator.casella_esiste(str(_cella.get("modo", "")), str(valore))
		_:
			return true

## I tre binari si impilano **secondo quanto occupano davvero**: nelle fasce
## basse i tempi sono tre e stanno in una riga, in quelle alte sono nove e vanno
## a capo. Con altezze fisse il primo mondo mostrava un buco fra il tempo e la
## persona, cioè lo spazio riservato a una seconda riga che non c'era.
func _disegna_campo(scossa: Vector2) -> void:
	_punti_chip.clear()
	var y := Y_MODO
	y += _disegna_binario("modo", "MODO", y, scossa) + 10.0
	y += _disegna_binario("tempo", "TEMPO", y, scossa) + 10.0
	_disegna_binario("persona", "PERSONA", y, scossa)
	var arrivo: Vector2 = _punti_chip.get(_ultimo_asse, Vector2(_arena.size.x * 0.5, y))
	disegna_fascio(arrivo + scossa)

## Disegna un binario e torna l'altezza che ha occupato.
func _disegna_binario(asse: String, titolo: String, y: float, scossa: Vector2) -> float:
	var font := ThemeDB.fallback_font
	_arena.draw_string(font, Vector2(14, y + 18) + scossa, titolo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(TESTO, 0.42))

	var x := X_BINARI
	var riga := 0.0
	for valore in _valori(asse):
		var testo := _testo_valore(asse, valore)
		var larghezza := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16.0
		if x + larghezza > _arena.size.x - 14.0:
			# I tempi non ci stanno in una riga sola nelle fasce alte: vanno a
			# capo invece di rimpicciolirsi, perché un'etichetta illeggibile non
			# è un'etichetta.
			x = X_BINARI
			riga += ALTEZZA_CHIP + 4.0
		var rect := Rect2(Vector2(x, y + riga) + scossa, Vector2(larghezza, ALTEZZA_CHIP))
		var qui: bool = str(_cella.get(asse)) == str(valore)
		# **Sui binari non c'e' piu' nessun oro.** (21 agosto 2026)
		#
		# Cerchiare d'oro la casella del sigillo sembrava un aiuto e invece era
		# la risposta scritta accanto alla domanda: `voci_valore_probe` ha
		# misurato che un giocatore che non sa niente di verbi vinceva quasi
		# ogni scambio guardando soltanto quei tre chip.
		#
		# Il sigillo pone la domanda, i binari sono la MAPPA su cui cercarla, e
		# la voce di Eli che si trasforma e' la risposta che arriva dopo il
		# colpo. Tre cose distinte: metterne due nella stessa non lascia niente
		# da fare al bambino.
		var vivo := _valore_vivo(asse, valore)

		var riempimento := Color(0.04, 0.10, 0.14, 0.85)
		if qui:
			riempimento = Color(GHIACCIO, 0.30)
		elif not vivo:
			riempimento = Color(0.03, 0.06, 0.08, 0.6)
		_arena.draw_rect(rect, riempimento)
		var bordo := Color(FREDDO, 0.22)
		if qui:
			bordo = GHIACCIO
		elif not vivo:
			bordo = Color(FREDDO, 0.10)
		_arena.draw_rect(rect, bordo, false, 2.0 if qui else 1.0)
		var colore_testo := Color(TESTO, 0.9)
		if not vivo:
			colore_testo = Color(TESTO, 0.28)
		_arena.draw_string(font, rect.position + Vector2(8, rect.size.y - 8), testo,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, colore_testo)
		# Il valore spento porta la sua sbarra, come la runa che non entra.
		if not vivo:
			_arena.draw_line(rect.position + Vector2(6, rect.size.y - 6),
				rect.position + Vector2(rect.size.x - 6, 6), Color(FREDDO, 0.22), 1.0)
		if qui:
			_punti_chip[asse] = rect.get_center() - scossa
		x += larghezza + 6.0
	return riga + ALTEZZA_CHIP

func rettangolo_runa(indice: int) -> Rect2:
	var colonna := indice % RUNA_COLONNE
	var riga := indice / RUNA_COLONNE
	var larghezza := float(geo["larghezza"])
	if is_instance_valid(_rune_zona) and _rune_zona.size.x > 1.0:
		larghezza = _rune_zona.size.x
	var totale := RUNA_LARGA * float(RUNA_COLONNE) + RUNA_GAP * float(RUNA_COLONNE - 1)
	var x := (larghezza - totale) * 0.5 + float(colonna) * (RUNA_LARGA + RUNA_GAP)
	return Rect2(x, 6.0 + float(riga) * (RUNA_ALTA + RUNA_GAP), RUNA_LARGA, RUNA_ALTA)

func _disegna_rune() -> void:
	var font := ThemeDB.fallback_font
	for indice in _rune.size():
		var runa: Dictionary = _rune[indice]
		var rect := rettangolo_runa(indice)
		var entra := VerbDuel.applicabile(_cella, runa)
		disegna_pietra(indice, rect, entra, _usate.has(indice))
		# L'asse scritto sopra il valore: «modo», «tempo», «persona» sono le tre
		# parole che servono a parlare dei verbi, e chi tocca trenta volte una
		# pietra con scritto «tempo» sopra «imperfetto» non le confonde più.
		var asse := str(runa.get("asse", ""))
		var alfa := 0.22 if _usate.has(indice) else (0.30 if not entra else 0.55)
		_arena_testo_asse(font, rect, asse, alfa)

func _arena_testo_asse(font: Font, rect: Rect2, asse: String, alfa: float) -> void:
	var larghezza := font.get_string_size(asse, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_rune_zona.draw_string(font,
		rect.position + Vector2((rect.size.x - larghezza) * 0.5, 22.0), asse,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(TESTO, alfa))
