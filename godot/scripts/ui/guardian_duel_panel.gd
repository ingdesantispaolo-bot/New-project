class_name GuardianDuelPanel
extends DuelStage

## **IL DUELLO DELLE CIFRE** — il campo del guardiano che chiede conti.
## (16 agosto 2026; diviso da [[DuelStage]] il 17, quando è arrivata la seconda
## materia)
##
## Il guardiano, i sigilli, la carica, la tenuta e le pietre stanno nella classe
## base: sono il combattimento, e non cambiano con la materia. Qui vive quello
## che è **della matematica**: la corda di risonanza, il numero dell'impulso, la
## catena dei colpi e le rune con le operazioni.
##
## ## Le scelte di resa, e perché ognuna
##
## - **La corda di risonanza è il pezzo che insegna.** Un numero da raggiungere,
##   scritto e basta, dice solo *quanto*; una scala dice **quanto manca**, e a
##   colpo d'occhio. Un bambino che vede l'ago fermo a un terzo della corda sa
##   che gli serve un ×3 prima di averlo calcolato — e quello, l'ordine di
##   grandezza, è la prima cosa che fa un calcolatore veloce. La zona **oltre** il
##   sigillo è disegnata e barrata: superare si vede prima ancora di leggere.
## - **La catena resta scritta** (`4 → ×6 → 24 → +9 → 33`). È il quaderno del
##   duello: il bambino rilegge la propria strada mentre la percorre.
## - **Il suono sale con la vicinanza.** Ogni colpo suona `enigmaProgress` con
##   l'intonazione legata a quanto ci si è avvicinati: l'orecchio impara la
##   distanza prima degli occhi.

## Quanto della corda sta oltre il sigillo. Un quarto abbondante: abbastanza per
## vedere di quanto si è sfondato, non tanto da schiacciare la parte che conta.
const CORDA_OLTRE := 1.38

const RUNA_LARGA := 96.0
const RUNA_ALTA := 84.0
const RUNA_GAP := 12.0

const Y_IMPULSO := 228.0
const Y_CORDA := 282.0
const ALTEZZA_CORDA := 14.0

var _impulso := 0
var _impulso_label: Label

func _init() -> void:
	geo["arena"] = 332.0
	geo["rune"] = 116.0

func _costruisci_campo() -> void:
	_impulso_label = etichetta("DuelImpulseValue", 30, GHIACCIO)
	_arena.add_child(_impulso_label)

func _nuovo_scambio() -> void:
	_scambio = GuardianDuel.genera_scambio(_rng, regole)
	_rune = Array(_scambio.get("rune", []))
	_usate.clear()
	_impulso = int(_scambio.get("partenza", 1))
	_catena = [str(_impulso)]
	_colpi_dati = 0
	_tempo_massimo = DuelRules.secondi_del_sigillo(regole, _sigilli_rotti)
	_tempo = _tempo_massimo
	_sigillo_label.text = str(int(_scambio.get("bersaglio", 0)))
	_sigillo_sotto.text = ""
	_costruisci_rune()
	_aggiorna_testi()

func _costruisci_rune() -> void:
	for nodo in _rune_label:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_rune_label.clear()
	for indice in _rune.size():
		var nodo := etichetta("DuelRune%d" % indice, 26, TESTO)
		nodo.text = str(Dictionary(_rune[indice]).get("testo", ""))
		_rune_zona.add_child(nodo)
		_rune_label.append(nodo)

func colpisci(indice: int) -> void:
	if not _attivo or _in_pausa or indice < 0 or indice >= _rune.size() or _usate.has(indice):
		return
	var runa: Dictionary = _rune[indice]
	var esito := GuardianDuel.applica(_impulso, runa)
	if esito < 0:
		# La runa spenta non è un errore: non entra, e basta. Costa il tempo che
		# ci si è messi a provarla — che è già la lezione sulla divisibilità.
		runa_spenta()
		return
	var bersaglio := int(_scambio.get("bersaglio", 0))
	var prima := absi(bersaglio - _impulso)
	_usate[indice] = true
	_impulso = esito
	_colpi_dati += 1
	_catena.append(str(runa.get("testo", "")))
	_catena.append(str(_impulso))
	segna_colpo(indice)
	_aggiorna_testi()

	if _impulso == bersaglio:
		spezza_sigillo()
		return
	# L'intonazione sale con la vicinanza: l'orecchio impara la distanza prima
	# degli occhi, ed è la stessa cosa che fa la corda con lo sguardo.
	var dopo_colpo := absi(bersaglio - _impulso)
	var avvicinamento := clampf(1.0 - float(dopo_colpo) / float(maxi(prima, 1)), 0.0, 1.0)
	suona("enigmaProgress", 0.88 + avvicinamento * 0.5)
	if _colpi_dati >= int(regole.get("colpi", 3)):
		incassa()
		return
	# **La strada chiusa.** Se con le rune rimaste il sigillo non si fa più, il
	# guardiano chiude lo scambio subito: far scorrere la carica su una partita
	# già persa non insegna niente e sembra soltanto una punizione lunga.
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
	var percorso := GuardianDuel.percorso_minimo(
		_impulso, int(_scambio.get("bersaglio", 0)), mano, maxi(rimasti, 1))
	var fuori: Array = []
	for passo in percorso:
		fuori.append(int(mappa[int(passo)]))
	return fuori

func _aggiorna_testi() -> void:
	if not is_instance_valid(_stato):
		return
	_impulso_label.text = str(_impulso)
	_catena_label.text = _riga_catena()
	aggiorna_stato()

## La catena come la si rilegge. Prima del primo colpo sarebbe un numero solo,
## cioè la ripetizione di quello già scritto sull'ago: quel posto vale di più
## occupato dall'unica istruzione che questo minigioco ha bisogno di dare, e che
## sparisce da sé appena serve meno.
func _riga_catena() -> String:
	if _catena.size() <= 1:
		return "porta l'impulso esatto sul sigillo, un colpo alla volta"
	var pezzi: Array = _catena.duplicate()
	while pezzi.size() > 9:
		pezzi.remove_at(0)
	return " » ".join(PackedStringArray(pezzi))

func _posiziona_campo() -> void:
	# L'ago porta con sé il proprio numero: il valore dell'impulso sta sopra il
	# punto in cui l'impulso è arrivato, e non in un angolo da cui bisognerebbe
	# tornare indietro con gli occhi a ogni colpo.
	var ago := _punto_corda(_impulso)
	_impulso_label.size = Vector2(120, 34)
	_impulso_label.position = Vector2(
		clampf(ago - 60.0, 12.0, maxf(_arena.size.x - 132.0, 12.0)), Y_IMPULSO)
	for indice in _rune_label.size():
		var nodo: Label = _rune_label[indice]
		if not is_instance_valid(nodo):
			continue
		var rect := rettangolo_runa(indice)
		nodo.size = Vector2(rect.size.x, 34)
		nodo.position = Vector2(rect.position.x, rect.get_center().y - 17.0)
		var entra := GuardianDuel.applicabile(_impulso, _rune[indice])
		nodo.modulate.a = 0.22 if _usate.has(indice) else (0.40 if not entra else 1.0)

# --- La corda di risonanza ----------------------------------------------------

func _corda_rect() -> Rect2:
	return Rect2(50.0, Y_CORDA, maxf(_arena.size.x - 100.0, 1.0), ALTEZZA_CORDA)

## Dove cade un valore sulla corda. La scala arriva a un terzo abbondante oltre
## il sigillo: chi sfonda vede **di quanto**, e chi sfonda molto trova l'ago
## appoggiato al fondo — informazione, non punizione.
func _punto_corda(valore: int) -> float:
	var rect := _corda_rect()
	var bersaglio := maxi(int(_scambio.get("bersaglio", 1)), 1)
	return rect.position.x + rect.size.x * clampf(
		float(valore) / (float(bersaglio) * CORDA_OLTRE), 0.0, 1.0)

func _disegna_campo(scossa: Vector2) -> void:
	var bersaglio := int(_scambio.get("bersaglio", 0))
	var rect := _corda_rect()
	rect.position += scossa
	var tacca := _punto_corda(bersaglio) + scossa.x

	# Il binario, e la zona oltre il sigillo: barrata, perché superare si deve
	# vedere prima di leggerlo.
	_arena.draw_rect(rect, Color(0.04, 0.11, 0.15, 0.95))
	var oltre := Rect2(tacca, rect.position.y, rect.end.x - tacca, rect.size.y)
	if oltre.size.x > 0.0:
		_arena.draw_rect(oltre, Color(AMBRA, 0.12))
		var x := oltre.position.x
		while x < oltre.end.x:
			_arena.draw_line(Vector2(x, oltre.position.y),
				Vector2(x - 6.0, oltre.end.y), Color(AMBRA, 0.18), 1.0)
			x += 9.0
	var ago := _punto_corda(_impulso) + scossa.x
	_arena.draw_rect(Rect2(rect.position, Vector2(maxf(ago - rect.position.x, 0.0), rect.size.y)),
		Color(FREDDO, 0.42))
	_arena.draw_rect(rect, Color(FREDDO, 0.55 if not high_contrast else 1.0), false, 1.4)

	# La tacca del sigillo: alta, dorata, con la sua ombra.
	_arena.draw_line(Vector2(tacca, rect.position.y - 16.0),
		Vector2(tacca, rect.end.y + 12.0), Color(0.01, 0.03, 0.05, 0.8), 6.0)
	_arena.draw_line(Vector2(tacca, rect.position.y - 15.0),
		Vector2(tacca, rect.end.y + 11.0), ORO, 3.0)

	# L'ago dell'impulso: un triangolo che punta alla corda.
	var colore_ago := AMBRA if _impulso > bersaglio else GHIACCIO
	var punta := Vector2(ago, rect.position.y - 2.0)
	_arena.draw_colored_polygon(PackedVector2Array([
		punta, punta + Vector2(11, -17), punta + Vector2(-11, -17),
	]), colore_ago)
	_arena.draw_line(punta, Vector2(ago, rect.end.y + 8.0), Color(colore_ago, 0.75), 2.0)
	if not high_contrast:
		_arena.draw_circle(Vector2(ago, rect.get_center().y), 13.0, Color(colore_ago, 0.10))

	# Le tacche di lettura: un quarto, metà, tre quarti del sigillo. Servono a
	# stimare senza contare — «sono a metà» è più veloce di «sono a 21».
	for frazione in [0.25, 0.5, 0.75]:
		var x2 := _punto_corda(int(round(float(bersaglio) * frazione))) + scossa.x
		_arena.draw_line(Vector2(x2, rect.end.y + 2.0), Vector2(x2, rect.end.y + 7.0),
			Color(FREDDO, 0.4), 1.0)

	disegna_fascio(Vector2(ago, rect.get_center().y))

func rettangolo_runa(indice: int) -> Rect2:
	var quante := maxi(_rune.size(), 1)
	var totale := RUNA_LARGA * float(quante) + RUNA_GAP * float(quante - 1)
	var larghezza := float(geo["larghezza"])
	if is_instance_valid(_rune_zona) and _rune_zona.size.x > 1.0:
		larghezza = _rune_zona.size.x
	var x := (larghezza - totale) * 0.5 + float(indice) * (RUNA_LARGA + RUNA_GAP)
	return Rect2(x, 14.0, RUNA_LARGA, RUNA_ALTA)

func _disegna_rune() -> void:
	for indice in _rune.size():
		disegna_pietra(indice, rettangolo_runa(indice),
			GuardianDuel.applicabile(_impulso, _rune[indice]), _usate.has(indice))
