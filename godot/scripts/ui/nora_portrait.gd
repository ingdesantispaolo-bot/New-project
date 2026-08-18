class_name NoraPortrait
extends Control

## **Il volto di NORA cambia mentre la nave torna viva.** (18 agosto 2026)
##
## Il ritratto era vettoriale: un rombo, una lente e qualche arco che si
## ricomponeva al crescere dell'integrità. Funzionava, ma diceva una cosa sola —
## «più arco, più riparato» — e i cinque ritratti dipinti di NORA esistevano già,
## fermi fra le sorgenti d'arte perché erano stati integrati soltanto nel
## prototipo Phaser, che non viene più eseguito.
##
## Ora gli stadi sono cinque e si vedono: NORA passa da una figura quasi spenta,
## appena leggibile nel blu, a una presenza accesa circondata da anelli e scudi.
## È la stessa figura in tutti e cinque — cambia quanta luce ha — ed è questo che
## la rende leggibile come progressione invece che come cinque immagini diverse.
##
## Lo stadio NON è uno stato nuovo da salvare: si deriva da `integrity`, che è già
## la spina dorsale del gioco (apparati riparati su ventiquattro). Aggiungere un
## contatore parallelo avrebbe creato due verità sullo stesso fatto.
##
## Le soglie sono in APPARATI, non in frazioni, perché è così che il giocatore
## conta i suoi progressi: 0, 4, 12, 16, 24. Ricalcano le tappe che il prototipo
## legava alle sue sei missioni (1ª, 3ª, 4ª, 6ª), riportate sulla scala dei
## ventiquattro mondi.

const APPARATI_TOTALI := 24.0

## Stadi dal meno al più acceso. `apparati` è la soglia di ingresso.
## I parametri di resa vengono dal prototipo: aura e anello crescono, i nodi in
## orbita si moltiplicano e girano più veloci, il ritratto si fa più opaco.
const STADI := [
	{"id": "dormant", "titolo": "NORA quasi spenta", "apparati": 0,
		"aura": 0.025, "anello": 0.12, "nodi": 1, "orbita": 22.0, "opacita": 0.78,
		"arte": preload("res://assets/nora/nora-presence-dormant-v3.webp")},
	{"id": "awakening", "titolo": "Primo risveglio", "apparati": 4,
		"aura": 0.055, "anello": 0.20, "nodi": 2, "orbita": 16.0, "opacita": 0.90,
		"arte": preload("res://assets/nora/nora-presence-awakening-v3.webp")},
	{"id": "memory", "titolo": "Memoria in ricostruzione", "apparati": 12,
		"aura": 0.090, "anello": 0.30, "nodi": 3, "orbita": 12.5, "opacita": 0.96,
		"arte": preload("res://assets/nora/nora-presence-memory-v3.webp")},
	{"id": "restored", "titolo": "NORA restaurata", "apparati": 16,
		"aura": 0.110, "anello": 0.38, "nodi": 4, "orbita": 10.0, "opacita": 0.98,
		"arte": preload("res://assets/nora/nora-presence-portrait-v2.webp")},
	{"id": "guardian", "titolo": "Custode della Città", "apparati": 24,
		"aura": 0.160, "anello": 0.52, "nodi": 5, "orbita": 7.6, "opacita": 1.0,
		"arte": preload("res://assets/nora/nora-presence-guardian-v3.webp")},
]

var _time := 0.0
var _speech := 0.0
var _accent := Color("6be7d6")
var _integrity := 0.0
var _trust := 0.5
var _reduced_motion := false

func _ready() -> void:
	custom_minimum_size = Vector2(82, 82)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

## Lo stadio corrente, derivato dall'integrità. Pubblico perché il pannello del
## manuale e gli audit devono poterlo nominare senza rifare il conto.
func stadio() -> Dictionary:
	var apparati := _integrity * APPARATI_TOTALI
	var scelto: Dictionary = STADI[0]
	for stadio_data in STADI:
		var s: Dictionary = stadio_data
		# Tolleranza minima: l'integrità arriva da una divisione, e l'ultimo
		# apparato non deve mancare l'ultimo stadio per un errore di virgola.
		if apparati >= float(s["apparati"]) - 0.001:
			scelto = s
	return scelto

func stadio_id() -> String:
	return str(stadio()["id"])

func speak(message: String) -> void:
	_speech = 1.0
	var lowered := message.to_lower()
	if "non " in lowered or "insufficiente" in lowered or "riprova" in lowered:
		_accent = Color("ff8fa0")
	elif "+" in message or "vittoria" in lowered or "ottimo" in lowered:
		_accent = Color("f6c85f")
	else:
		_accent = Color("6be7d6")
	if not _reduced_motion:
		scale = Vector2(0.88, 0.88)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	queue_redraw()

func set_livery(color: Color) -> void:
	_accent = color
	queue_redraw()

## Integrità puramente presentazionale derivata dalla riattivazione didattica
## della nave (0 frammentata → 1 pienamente ricostruita). Non decide storia,
## fiducia o progresso: rende visibile lo stato già calcolato altrove.
func set_integrity(ratio: float, use_reduced_motion: bool = false, trust: float = 0.5) -> void:
	_integrity = clampf(ratio, 0.0, 1.0)
	_trust = clampf(trust, 0.0, 1.0)
	_reduced_motion = use_reduced_motion
	set_meta("integrity", _integrity)
	set_meta("trust", _trust)
	set_meta("stage", stadio_id())
	queue_redraw()

func _process(delta: float) -> void:
	if not _reduced_motion:
		_time += delta * lerpf(0.42, 1.0, _integrity)
	_speech = maxf(0.0, _speech - delta * 0.72)
	queue_redraw()

## Poligono circolare con le UV che ritagliano il quadrato centrale della
## sorgente. `draw_texture_rect` disegnerebbe un quadrato: qui serve un tondo, e
## un poligono texturizzato è l'unico modo di ritagliarlo dentro `_draw`.
func _disco_texturizzato(centro: Vector2, raggio: float, texture: Texture2D, tinta: Color) -> void:
	var lati := 40
	var punti := PackedVector2Array()
	var uv := PackedVector2Array()
	for i in range(lati):
		var a := TAU * float(i) / float(lati)
		var dir := Vector2(cos(a), sin(a))
		punti.append(centro + dir * raggio)
		uv.append(Vector2(0.5, 0.5) + dir * 0.5)
	draw_colored_polygon(punti, tinta, uv, texture)

func _draw() -> void:
	var lato := minf(size.x, size.y)
	if lato <= 0.0:
		lato = 82.0
	var centro := Vector2(size.x, size.y) * 0.5
	if size.x <= 0.0 or size.y <= 0.0:
		centro = Vector2(41, 42)
	var s := stadio()
	var respiro := 1.0 + sin(_time * 2.4) * 0.025 * lerpf(0.2, 1.0, _integrity)
	var parla := sin(_time * 12.0) * _speech
	var accento_fiducia := _accent.lerp(Color("f6c85f"), clampf((_trust - 0.5) * 0.32, 0.0, 0.16))
	var accento := Color("75888c").lerp(accento_fiducia, 0.28 + _integrity * 0.72)
	var raggio := lato * 0.46 * respiro

	# Alone: cresce con lo stadio e si accende quando NORA parla.
	draw_circle(centro, raggio * 1.12,
		Color(accento, float(s["aura"]) + _speech * 0.06))

	# Il ritratto dipinto è il soggetto. Gli anelli e la trama stanno già dentro
	# l'immagine — per questo qui sopra non si disegnano più archi vettoriali:
	# sovrapposti all'arte facevano rumore invece di leggersi come una cosa sola.
	_disco_texturizzato(centro, raggio, s["arte"] as Texture2D,
		Color(1, 1, 1, float(s["opacita"])))

	# Un solo anello sottile, in tinta con la livrea: lega il ritratto al resto
	# della HUD, che è vettoriale, senza coprirlo.
	draw_arc(centro, raggio + 1.5, 0.0, TAU, 48,
		Color(accento.lightened(0.2), float(s["anello"]) + _speech * 0.2),
		1.6 + absf(parla) * 0.5, true)

	# Nodi in orbita: uno per stadio, e girano più veloci man mano che NORA torna
	# presente. È il segnale che si legge anche con la coda dell'occhio.
	var nodi := int(s["nodi"])
	var velocita := TAU / float(s["orbita"])
	for i in range(nodi):
		var angolo := _time * (velocita + _speech * 1.4) + TAU * float(i) / float(nodi)
		var p := centro + Vector2(cos(angolo), sin(angolo)) * (raggio + lato * 0.07)
		draw_circle(p, lato * 0.026 + _speech, Color(accento.lightened(0.25), 0.82))
