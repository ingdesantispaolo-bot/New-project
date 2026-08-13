class_name VibrationMinigameBoard
extends Control

## Banco vettoriale di Oreste. Lo stesso ritmo viene mostrato in due alfabeti:
## pressione sotto il palmo in alto, oscillazione di una corda in basso.
## Il disegno resta completo senza audio e senza aptica; la vibrazione del
## dispositivo, quando esiste, è soltanto un rinforzo.

var _bersaglio: Array = []
var _corde: Array = []
var _selezionata := -1
var _esito_scelto := -1
var _esito_giusto := -1
var _fase := 0.0
var _riproduce := false
var _ultimo_battito := -1
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(650, 245)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configura(bersaglio: Array, corde: Array, selezionata: int, reduced_motion: bool) -> void:
	_bersaglio = bersaglio.duplicate()
	_corde = corde.duplicate(true)
	_selezionata = selezionata
	_esito_scelto = -1
	_esito_giusto = -1
	_reduced_motion = reduced_motion
	queue_redraw()

func seleziona(indice: int) -> void:
	_selezionata = indice
	_esito_scelto = -1
	_esito_giusto = -1
	queue_redraw()

func mostra_esito(scelto: int, giusto: int) -> void:
	_esito_scelto = scelto
	_esito_giusto = giusto
	queue_redraw()

func riproduci_tremito() -> void:
	_fase = 0.0
	_ultimo_battito = -1
	_riproduce = true
	queue_redraw()

func _process(delta: float) -> void:
	if not _riproduce or _bersaglio.is_empty():
		return
	_fase += delta * (1.25 if _reduced_motion else 1.75)
	var battito := mini(int(floor(_fase)), _bersaglio.size() - 1)
	if battito != _ultimo_battito:
		_ultimo_battito = battito
		# Su desktop e Web senza attuatore non succede nulla: l'informazione è
		# già tutta nei dischi e nelle onde, quindi l'accessibilità non dipende
		# dall'hardware.
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(int(65.0 + float(_bersaglio[battito]) * 115.0),
				clampf(float(_bersaglio[battito]), 0.2, 1.0))
	if _fase >= float(_bersaglio.size()):
		_riproduce = false
	queue_redraw()

func _draw() -> void:
	if size.x < 300.0 or _bersaglio.is_empty():
		return
	# Banco di liuteria e due intarsi luminosi che separano i due modi di
	# ricevere il ritmo.
	draw_style_box(_stile(Color("142b31"), Color("41777a"), 18, 2), Rect2(2, 2, size.x - 4, size.y - 4))
	draw_rect(Rect2(18, 16, size.x - 36, 78), Color("0d2026", 0.94), true)
	draw_rect(Rect2(18, 16, size.x - 36, 78), Color("67d9d0", 0.42), false, 2.0)
	_disegna_palmo(Vector2(66, 55))
	_disegna_impulsi(Rect2(125, 28, size.x - 165, 52))

	var n := maxi(1, _corde.size())
	var spazio := 10.0
	var larghezza := (size.x - 36.0 - spazio * float(n - 1)) / float(n)
	for i in n:
		var r := Rect2(18.0 + float(i) * (larghezza + spazio), 109, larghezza, 116)
		_disegna_corda(r, Array(_corde[i]), i)

func _disegna_palmo(centro: Vector2) -> void:
	var pelle := Color("e7ad7d")
	# Palmo, pollice e quattro dita: icona leggibile, non decorazione astratta.
	draw_circle(centro + Vector2(0, 10), 22, pelle)
	draw_line(centro + Vector2(-18, 8), centro + Vector2(-31, -2), pelle, 11, true)
	for i in 4:
		var x := -15.0 + float(i) * 10.0
		var h := 25.0 + (7.0 if i == 1 or i == 2 else 0.0)
		draw_line(centro + Vector2(x, 0), centro + Vector2(x, -h), pelle, 8, true)
	draw_arc(centro + Vector2(0, 10), 17, 0.15, PI - 0.15, 20, Color("7d493b", 0.55), 2)

func _disegna_impulsi(area: Rect2) -> void:
	var n := maxi(1, _bersaglio.size())
	for i in n:
		var forza := float(_bersaglio[i])
		var x := area.position.x + (float(i) + 0.5) * area.size.x / float(n)
		var attivo := _riproduce and i == mini(int(floor(_fase)), n - 1)
		var r := 9.0 + forza * 13.0 + (5.0 if attivo and not _reduced_motion else 0.0)
		var colore := Color("ffd36f") if forza > 0.75 else Color("8be5d7") if forza > 0.5 else Color("78a6c7")
		if attivo:
			draw_circle(Vector2(x, area.get_center().y), r + 8, Color(colore, 0.16))
		draw_circle(Vector2(x, area.get_center().y), r, Color(colore, 0.88))
		draw_circle(Vector2(x, area.get_center().y), r, Color("fff6d5", 0.72), false, 2.0)
		# Le tacche rendono esplicito che conta anche l'ordine, non solo quanti
		# impulsi sono forti.
		draw_line(Vector2(x, area.end.y - 4), Vector2(x, area.end.y), Color("d6fffa", 0.38), 2)

func _disegna_corda(area: Rect2, ritmo: Array, indice: int) -> void:
	var bordo := Color("5c8588")
	var sfondo := Color("172f34")
	if indice == _selezionata:
		bordo = Color("ffe08a")
		sfondo = Color("294542")
	if indice == _esito_giusto:
		bordo = Color("7ff0b5")
		sfondo = Color("194b3b")
	elif indice == _esito_scelto and _esito_scelto != _esito_giusto:
		bordo = Color("ff827f")
		sfondo = Color("4d292c")
	draw_style_box(_stile(sfondo, bordo, 14, 2 if indice != _selezionata else 3), area)
	# Ponticelli e corda: ogni tratto usa l'intensità dello stesso battito,
	# trasformando i dischi del palmo in ampiezza dell'onda.
	var y := area.position.y + area.size.y * 0.54
	var sinistra := area.position.x + 16
	var destra := area.end.x - 16
	draw_line(Vector2(sinistra, y - 28), Vector2(sinistra, y + 28), Color("d6a45f"), 5, true)
	draw_line(Vector2(destra, y - 28), Vector2(destra, y + 28), Color("d6a45f"), 5, true)
	var punti := PackedVector2Array()
	var segmenti := maxi(1, ritmo.size())
	var campioni := segmenti * 16
	for k in range(campioni + 1):
		var t := float(k) / float(campioni)
		var segmento := mini(int(floor(t * float(segmenti))), segmenti - 1)
		var ampiezza := 8.0 + float(ritmo[segmento]) * 24.0
		var locale := fmod(t * float(segmenti), 1.0)
		var onda := sin(locale * TAU) * ampiezza
		punti.append(Vector2(lerpf(sinistra, destra, t), y + onda))
	draw_polyline(punti, Color("dffdf5"), 3.0, true)
	# Numero romano puramente identificativo; non codifica la soluzione.
	var tacche := indice + 1
	for t in tacche:
		var tx := area.get_center().x + (float(t) - float(tacche - 1) * 0.5) * 7.0
		draw_line(Vector2(tx, area.end.y - 19), Vector2(tx, area.end.y - 9), bordo, 2.5)

func _stile(sfondo: Color, bordo: Color, raggio: int, spessore: int) -> StyleBoxFlat:
	var stile := StyleBoxFlat.new()
	stile.bg_color = sfondo
	stile.border_color = bordo
	stile.set_border_width_all(spessore)
	stile.set_corner_radius_all(raggio)
	return stile
