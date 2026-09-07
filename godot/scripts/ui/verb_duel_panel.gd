class_name VerbDuelPanel
extends DuelStage

## **IL DUELLO DELLE VOCI** — il campo del guardiano che chiede verbi.
## (17 agosto 2026)
##
## Il guardiano, i sigilli, la carica e i cuori stanno in [[DuelStage]]. Qui vive
## quello che è **dell'italiano**: un obiettivo, la forma attuale e le poche
## mosse che cambiano modo, tempo o persona.
##
## La prima versione mostrava anche tre binari con l'intero paradigma. Era una
## mappa corretta ma, sommata a bersaglio, forma, rune e stato del combattimento,
## chiedeva di leggere troppe cose prima di giocare. La nuova arena mostra solo
## ciò che serve alla decisione presente. Le caselle impossibili restano nelle
## rune spente, quindi la grammatica e l'importanza dell'ordine non si perdono.
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
## Da tre a quattro pietre, ognuna con l'**asse** scritto piccolo
## sopra e il **valore** grande sotto. L'asse scritto non è decorazione: modo,
## tempo e persona sono le tre parole che servono a parlare dei verbi, e un
## bambino che tocca trenta volte una pietra con scritto «tempo» sopra
## «imperfetto» non le confonde più.
##
## Una runa che qui non entra è **spenta e barrata**, come nel duello delle
## cifre: `tempo → passato remoto` è spenta nel congiuntivo, perché il
## congiuntivo il passato remoto non ce l'ha.

const RUNA_LARGA := 178.0
const RUNA_ALTA := 62.0
const RUNA_GAP := 10.0
const RUNA_COLONNE := 3

const Y_VOCE := 208.0
const ALTEZZA_STATO := 68.0

var _cella: Dictionary = {}
var _voce_label: Label
## L'infinito del verbo di Eli, sotto la sua voce. Il cartiglio del guardiano
## scrive «da temere» sotto il campione dal primo giorno, per una ragione
## scritta in [[VerbDuel]]: il duello misura modi e tempi, non il vocabolario.
## Lo stesso ragionamento non era mai stato applicato al verbo di Eli, e chi
## leggeva «abbiate dato» doveva risalire da solo a «dare».
var _infinito_label: Label
func _init() -> void:
	geo["larghezza"] = 620.0
	geo["arena"] = 286.0
	geo["rune"] = 140.0
	geo["ySigilli"] = 10.0
	geo["yArte"] = 16.0
	geo["latoArte"] = 124.0
	geo["yTarga"] = 118.0
	geo["altezzaTarga"] = 60.0
	geo["yCarica"] = 188.0
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
		_sigillo_sotto.text = str(sigillo.get("sotto", "")).trim_prefix("CHI: ")
	else:
		_sigillo_label.add_theme_font_size_override("font_size", 28)
		_sigillo_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_sigillo_label.text = str(sigillo.get("testo", ""))
		_sigillo_sotto.text = "stessa forma · %s" % str(sigillo.get("campione", ""))
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
		_infinito_label.text = "%s  ·  %s %s  ·  %s" % [
			str(_scambio.get("infinito", "")),
			str(_cella.get("modo", "")), str(_cella.get("tempo", "")),
			str(VerbConjugator.PERSONE[int(_cella.get("persona", 0))])]
	aggiorna_stato()

## La catena come la si rilegge: `canto → imperfetto → cantavo → voi →
## cantavate`. Prima del primo colpo sarebbe la ripetizione della voce già
## scritta grande, e quel posto vale di più occupato dall'unica istruzione che
## questo minigioco ha bisogno di dare.
func _riga_catena() -> String:
	if _catena.size() <= 1:
		var sigillo: Dictionary = _scambio.get("sigillo", {})
		if str(sigillo.get("tipo", "")) == "campione":
			return "TOCCA LE PIETRE: usa la stessa forma grammaticale del modello"
		return "TOCCA LE PIETRE: cambia tempo, modo o persona"
	var pezzi: Array = _catena.duplicate()
	while pezzi.size() > 7:
		pezzi.remove_at(0)
	return "MOSSE: %s" % " » ".join(PackedStringArray(pezzi))

func _posiziona_campo() -> void:
	_voce_label.size = Vector2(_arena.size.x - 180.0, 38)
	_voce_label.position = Vector2(90, Y_VOCE + 4.0)
	_infinito_label.size = Vector2(_arena.size.x - 180.0, 20)
	_infinito_label.position = Vector2(90, Y_VOCE + 39.0)
	for indice in _rune_label.size():
		var nodo: Label = _rune_label[indice]
		if not is_instance_valid(nodo):
			continue
		var rect := rettangolo_runa(indice)
		nodo.size = Vector2(rect.size.x, 26)
		nodo.position = Vector2(rect.position.x, rect.position.y + 26.0)
		var entra := VerbDuel.applicabile(_cella, _rune[indice])
		nodo.modulate.a = 0.22 if _usate.has(indice) else (0.40 if not entra else 1.0)

# --- Lo stato attuale ---------------------------------------------------------

## Un solo pannello mostra dove si trova il verbo. La vecchia mappa completa di
## modi, tempi e persone obbligava a leggere fino a diciotto etichette prima di
## poter scegliere: era corretta, ma trasformava il combattimento in un indice.
func _disegna_campo(scossa: Vector2) -> void:
	var rect := Rect2(82.0, Y_VOCE, _arena.size.x - 164.0, ALTEZZA_STATO)
	rect.position += scossa
	_arena.draw_rect(rect, Color(0.025, 0.09, 0.13, 0.94))
	_arena.draw_rect(rect, Color(FREDDO, 0.62), false, 2.0)
	disegna_fascio(rect.get_center())

func rettangolo_runa(indice: int) -> Rect2:
	var colonne := mini(RUNA_COLONNE, maxi(_rune.size(), 1))
	var colonna := indice % colonne
	var riga := indice / colonne
	var larghezza := float(geo["larghezza"])
	if is_instance_valid(_rune_zona) and _rune_zona.size.x > 1.0:
		larghezza = _rune_zona.size.x
	var inizio_riga := riga * colonne
	var in_riga := mini(colonne, _rune.size() - inizio_riga)
	var totale := RUNA_LARGA * float(in_riga) + RUNA_GAP * float(in_riga - 1)
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
