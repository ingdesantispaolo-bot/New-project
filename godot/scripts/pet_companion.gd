class_name OutdoorPetCompanion
extends Node2D

signal antic_started(antic_id: String)

const PET_ANTICS := preload("res://scripts/game/pet_antics.gd")

## Compagno equipaggiato in bottega: segue il player con smorzamento, fluttua
## e scatta una reazione festosa quando Eli raccoglie un tesoro o affronta una
## prova. Chiude il loop shopping ↔ avventura: comprare un pet lo fa comparire
## accanto a te nel mondo.

var target  # OutdoorPlayerController (untyped: accesso dinamico a .velocity)
var visual: Node2D
## Che Custode e di che livrea, per poterlo rifare se la sua tavola arriva dopo.
var _kind_del_custode := ""
var _colore_del_custode := Color.WHITE
var offset := Vector2(-34, -6)
var _bob := 0.0
var _react := 0.0
var _reaction_delay := 0.0
var _amplitude := 1.0
var _bounce := false
var _reduced_motion := false
var _antics: Node
var _unlocked_antics: Array = []
var _antic_id := ""
var _antic_time := 0.0
var _expression_pose := "sereno"
var _expression_time := 0.0
var _expression_duration := 0.0
var _expression_mark: Node2D

func setup(
	kind: String,
	color: Color,
	follow_target,
	temperament := "vivace",
	reduced_motion := false
) -> void:
	target = follow_target
	set_temperament(temperament)
	set_reduced_motion(reduced_motion)
	_kind_del_custode = kind
	_colore_del_custode = color
	visual = OutdoorVisualFactory.build_pet(kind, color)
	add_child(visual)
	if visual.get_node_or_null("PetGeneratedArt") == null:
		# Il Custode illustrato viaggia in `content.pck` come i ritratti e i
		# guardiani: se non c'è ancora, si torna qui quando arriva.
		add_to_group("arte_differita")
	_antics = PET_ANTICS.new()
	_antics.name = "PetAntics"
	add_child(_antics)
	_antics.configure([], reduced_motion)
	_antics.antic_started.connect(_on_antic_started)
	_antics.antic_finished.connect(_on_antic_finished)
	z_index = 8
	if is_instance_valid(target):
		global_position = target.global_position + offset
	_bob = randf() * TAU
	_expression_mark = Node2D.new()
	_expression_mark.name = "PetExpressionPose"
	_expression_mark.position = Vector2(0, -42)
	add_child(_expression_mark)

## **La freccia del Custode.** (7 agosto 2026)
##
## Segnalazione di gioco: «il pallino giallo che segue il personaggio non sembra
## significare qualcosa». Era vero — seguiva Eli e basta — e nella stessa
## segnalazione c'era anche «e' noioso girovagare senza uno scopo». Le due cose
## si rispondono a vicenda: il compagno diventa la **bussola**.
##
## Punta verso la prova non ancora fatta piu' vicina. Non ci porta e non la
## nomina: indica una direzione, e la scelta resta di Eli. Un compagno che
## decidesse la strada trasformerebbe l'esplorazione in un corridoio, che e'
## esattamente il difetto da cui veniamo.
##
## Il Custode non da' MAI vantaggi di gioco (contratto di `pet_state.gd`): una
## direzione non e' un vantaggio, e' un'informazione che la mappa gia' contiene —
## la stessa che si otterrebbe girando in tondo, ma senza la noia di girare in
## tondo.
var _freccia: Polygon2D

func _crea_freccia() -> void:
	_freccia = Polygon2D.new()
	_freccia.name = "GuideArrow"
	_freccia.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(6, 5), Vector2(0, 1), Vector2(-6, 5)])
	_freccia.color = Color(1.0, 0.86, 0.42, 0.88)
	_freccia.position = Vector2(0, -26)
	_freccia.visible = false
	add_child(_freccia)

## **La freccia indica soltanto cio' che il gioco ha gia' dichiarato.**
## (19 agosto 2026)
##
## Fino a oggi questa funzione scorreva `world_interactable` e puntava al nodo
## aperto piu' vicino, **qualunque fosse**: un forziere, una traccia del mistero,
## e perfino il portale o un landmark — che stanno in quel gruppo e non hanno mai
## una `completed` a vero, quindi risultavano eternamente «da fare».
##
## Il difetto non era la freccia sbagliata, era la freccia **onnisciente**: in un
## mondo dove ogni cosa e' gia' indicata non si scopre niente, e l'esplorazione
## diventa il percorso di una lista. Le deviazioni — che sono la meta' facoltativa
## del gioco, quella dei frammenti e del racconto — venivano consegnate esattamente
## come gli obiettivi, e quindi non erano piu' deviazioni.
##
## Adesso la freccia conosce un gruppo solo: `mission_poi`, cioe' gli eventi che
## contano per il gate — esattamente quelli che il quadro degli obiettivi nomina.
## Quello che il gioco non ha dichiarato si trova; non si riceve. E quando non
## resta nessun obiettivo aperto la freccia si spegne invece di ripiegare sul
## portale: la strada verso la nave ha gia' la sua barra di navigazione, e due
## indicatori per la stessa cosa sono uno di troppo.
##
## Quello che prendeva il posto della freccia sulle deviazioni non e' un'altra
## freccia: e' il fiuto, che indica molto meno. Vedi `fiuta`.
const GRUPPO_OBIETTIVI := "mission_poi"

func _obiettivo_piu_vicino() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.INF
	var migliore := Vector2.INF
	var distanza := INF
	for nodo in get_tree().get_nodes_in_group(GRUPPO_OBIETTIVI):
		if not (nodo is Node2D):
			continue
		if bool((nodo as Node).get_meta("completed", false)):
			continue
		var d: float = target.global_position.distance_to((nodo as Node2D).global_position)
		if d < distanza:
			distanza = d
			migliore = (nodo as Node2D).global_position
	return migliore

## **Il fiuto del Custode.** (19 agosto 2026)
##
## Il posto lasciato libero dalla freccia non resta vuoto, ma quello che ci va
## dentro e' di un'altra specie. Non una direzione da seguire: un **sospetto**.
## Il Custode si mette dalla parte in cui sente qualcosa e si sporge da quel lato,
## e non dice altro — niente nome, niente distanza, niente freccia, nessuna riga
## di testo. Chi lo vede sporgersi sa che da quella parte c'e' qualcosa e non sa
## che cosa: e' la differenza fra ricevere un elenco e avere un motivo per
## deviare.
##
## **Chi decide che cosa vale un fiuto non e' questo file.** La scena e' l'unica a
## sapere quali forzieri sono gia' stati presi e quali tracce gia' lette; qui si
## riceve un punto e lo si guarda. Il contratto e' che siano sempre e solo
## **deviazioni** — forzieri e tracce, cioe' frammenti e racconto — e mai un
## obiettivo del gate: il Custode non ha mai aiutato a progredire e non comincia
## adesso (`pet_state.gd`, «nessun vantaggio di gioco»).
##
## `Vector2.INF` spegne il fiuto.
func fiuta(posizione: Vector2) -> void:
	var lato_prima := _fiuto_lato
	var acceso_prima := _fiuto != Vector2.INF
	_fiuto = posizione
	if _fiuto == Vector2.INF:
		_fiuto_lato = 0.0
	elif is_instance_valid(target):
		# `target` e' volutamente senza tipo (accesso dinamico a `.velocity`), quindi
		# il tipo qui va scritto a mano: senza, l'inferenza non ha da dove partire.
		var dx: float = _fiuto.x - target.global_position.x
		_fiuto_lato = signf(dx) if absf(dx) > FIUTO_ZONA_MORTA else _fiuto_lato
	# Il segno dipende solo dall'essere acceso e dal lato: si ridisegna quando
	# cambia una delle due cose, non a ogni fotogramma. La sporgenza invece e'
	# animata, ma vive sulla posizione del corpo e non sul disegno.
	if _fiuto_lato != lato_prima or acceso_prima != (_fiuto != Vector2.INF):
		queue_redraw()

## Il punto sentito, `Vector2.INF` quando non c'e' niente.
var _fiuto := Vector2.INF
## Da che parte sta (−1 sinistra, +1 destra, 0 nessuna). Si tiene a parte dal
## punto perche' e' quello che disegna il segno, e un segno che sfarfalla mentre
## Eli passa esattamente sopra la verticale del forziere sarebbe rumore.
var _fiuto_lato := 0.0
## Quanto e' sporto adesso, in pixel. Animato, cosi' il gesto si nota anche di
## coda d'occhio.
var _fiuto_sporgenza := 0.0

## Sotto questo scarto orizzontale il lato non cambia: vedi `_fiuto_lato`.
const FIUTO_ZONA_MORTA := 24.0
## Quanto si sporge il Custode quando sente. Nove pixel: si vede, e non lo
## stacca dal fianco di Eli.
const FIUTO_SPORGENZA := 9.0

func _aggiorna_fiuto(delta: float) -> void:
	var voluta := FIUTO_SPORGENZA * _fiuto_lato if _fiuto != Vector2.INF else 0.0
	if _reduced_motion:
		_fiuto_sporgenza = voluta
	else:
		_fiuto_sporgenza = lerpf(_fiuto_sporgenza, voluta, minf(1.0, delta * 6.0))

func _aggiorna_freccia() -> void:
	if not is_instance_valid(_freccia) or not is_instance_valid(target):
		return
	# Mentre è dentro una tana non indica niente: sta facendo un'altra cosa, e una
	# bussola che continua a funzionare mentre il suo portatore è sottoterra
	# toglierebbe al momento tutto quello che ha.
	if _meta != Vector2.INF or not visible:
		_freccia.visible = false
		return
	var meta := _obiettivo_piu_vicino()
	if meta == Vector2.INF:
		_freccia.visible = false
		return
	# Sotto una certa distanza la freccia si spegne: sei arrivato, e una freccia
	# che punta a due passi e' rumore.
	var d: float = target.global_position.distance_to(meta)
	if d < 190.0:
		_freccia.visible = false
		return
	_freccia.visible = true
	var verso: Vector2 = meta - target.global_position
	_freccia.rotation = verso.angle() + PI * 0.5

func _process(delta: float) -> void:
	if not _reduced_motion:
		_bob += delta
	if _freccia == null:
		_crea_freccia()
	_aggiorna_freccia()
	_aggiorna_fiuto(delta)
	if _meta != Vector2.INF:
		# Con una meta sua smette di seguire: è l'unico momento in cui il Custode
		# non è al fianco di Eli.
		global_position = global_position.move_toward(_meta, VELOCITA_INCARICO * delta)
	elif is_instance_valid(target):
		# il pet resta sul lato opposto alla direzione di marcia
		var side := signf(offset.x)
		if target.velocity.x > 8.0:
			side = -1.0
		elif target.velocity.x < -8.0:
			side = 1.0
		# ...a meno che non abbia sentito qualcosa: allora passa da quella parte.
		# E' l'unica cosa che gli fa scegliere il fianco al posto della marcia, ed
		# e' meta' di come si legge il fiuto — l'altra meta' e' la sporgenza.
		if _fiuto != Vector2.INF and _fiuto_lato != 0.0:
			side = _fiuto_lato
		var desired: Vector2 = target.global_position + Vector2(absf(offset.x) * side, offset.y)
		global_position = global_position.lerp(desired, minf(1.0, delta * 5.0))
	if visual != null:
		_update_antic_pose(delta)
		_update_expression_pose(delta)
		var lift := 0.0 if _reduced_motion else sin(_bob * 3.2) * 3.0 * _amplitude
		if _reaction_delay > 0.0:
			_reaction_delay = maxf(0.0, _reaction_delay - delta)
			if _reaction_delay <= 0.0:
				_react = 1.0
		if _react > 0.0:
			_react = maxf(0.0, _react - delta * 2.4)
			if not _reduced_motion:
				lift -= _react * 11.0 * _amplitude
				var bounce_scale := 1.0 + sin(_react * PI * 3.0) * 0.08 if _bounce else 1.0
				visual.scale = Vector2.ONE * (1.0 + _react * 0.28 * _amplitude) * bounce_scale
		else:
			visual.scale = Vector2.ONE
		visual.position.y = -14.0 + lift
		# La sporgenza sta sulla X del corpo e non sulla rotazione apposta: la
		# rotazione e' gia' contesa da combinelle ed espressioni, e sommarcisi
		# avrebbe voluto dire togliere e rimettere un pezzo di posa a ogni
		# fotogramma. La X non la scrive nessun altro, quindi il fiuto convive con
		# qualunque smorfia il Custode stia facendo — che e' giusto: sentire una
		# cosa non lo rende meno vivo.
		visual.position.x = _fiuto_sporgenza

## **Il Custode va da solo.** (19 agosto 2026)
##
## Finché c'è una meta, smette di seguire Eli e ci va. È l'unico momento in cui
## il compagno non è attaccato al fianco di chi gioca, ed è tutta la ragione per
## cui le tane esistono ([[PetErrand]]): si preme un pulsante e non si apre
## niente — si guarda qualcun altro fare una cosa.
##
## Qui non si sa che cosa ci sia in fondo. La scena decide quando sparisce, che
## cosa riporta e quando torna; questo file sa soltanto camminare e nascondersi.
var _meta := Vector2.INF

## Quanto va veloce quando ha una meta sua. Più svelto del passo con cui segue:
## ci va di corsa, perché è entusiasta e perché una traversata lenta mentre non
## si può fare altro sarebbe un'attesa e basta.
const VELOCITA_INCARICO := 210.0

func manda_a(posizione: Vector2) -> void:
	_meta = posizione
	_fiuto = Vector2.INF
	_fiuto_lato = 0.0
	queue_redraw()

## Vero quando è arrivato: la scena aspetta questo per farlo sparire dentro.
func arrivato() -> bool:
	return _meta != Vector2.INF and global_position.distance_to(_meta) < 26.0

## Torna al fianco di Eli. Da qui in poi il seguito riprende da solo.
func torna() -> void:
	_meta = Vector2.INF
	visible = true

## Sparisce dentro. Non è `queue_free`: è lo stesso Custode, che rientra.
func entra() -> void:
	visible = false

func react() -> void:
	var profile := PetExpressionEngine.temperament_profile(_temperament)
	_reaction_delay = float(profile.get("delay", 0.0))
	_react = 1.0 if _reaction_delay <= 0.0 else 0.0
	if _reduced_motion:
		return
	var burst := OutdoorVisualFactory.make_sparkles(Color(1.0, 0.92, 0.6, 0.9), 9.0, 7)
	burst.one_shot = true
	burst.explosiveness = 0.8
	burst.lifetime = 1.0
	burst.position = Vector2(0, -14)
	add_child(burst)
	burst.emitting = true
	get_tree().create_timer(1.4).timeout.connect(burst.queue_free)

## Traduce il volto già deciso da PetExpressionEngine in una posa del corpo.
## Non decide eventi né utilità: è soltanto la parte visibile di C-G9.
func react_to(game_signal: String) -> void:
	_expression_pose = PetExpressionEngine.face_for(game_signal)
	_expression_time = 0.0
	_expression_duration = maxf(1.0, PetExpressionEngine.duration_of(_expression_pose))
	set_meta("expression_pose", _expression_pose)
	react()
	queue_redraw()

var _temperament := "vivace"

func set_temperament(value: String) -> void:
	_temperament = value if PetExpressionEngine.TEMPERAMENTS.has(value) else "vivace"
	var profile := PetExpressionEngine.temperament_profile(_temperament)
	_amplitude = float(profile.get("amplitude", 1.0))
	_bounce = bool(profile.get("bounce", false))

func set_reduced_motion(value: bool) -> void:
	_reduced_motion = value
	if _reduced_motion:
		_react = 0.0
		_reaction_delay = 0.0
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE
	if is_instance_valid(_antics):
		_antics.configure(_unlocked_antics, value)

func configure_antics(unlocked: Array) -> void:
	_unlocked_antics = unlocked.duplicate()
	if is_instance_valid(_antics):
		_antics.configure(_unlocked_antics, _reduced_motion)

## Fa starnutire il Custode adesso, a prescindere dal turno delle combinelle
## ambientali. Vero se è partito davvero.
func force_sneeze() -> bool:
	return is_instance_valid(_antics) and str(_antics.force_sneeze()) == "sneeze"

func set_antics_blocked(value: bool) -> void:
	if is_instance_valid(_antics):
		_antics.set_blocked(value)

func _on_antic_started(antic_id: String, _duration: float) -> void:
	_antic_id = antic_id
	_antic_time = 0.0
	antic_started.emit(antic_id)

func _on_antic_finished(_finished: String) -> void:
	_antic_id = ""
	if is_instance_valid(visual):
		visual.rotation = 0.0

func _update_antic_pose(delta: float) -> void:
	if _antic_id == "" or not is_instance_valid(visual):
		return
	_antic_time += delta
	match _antic_id:
		"tail":
			visual.rotation = -0.12 if _reduced_motion else sin(_antic_time * 7.0) * 0.22
		"pose":
			visual.rotation = -0.18
		"nap":
			visual.rotation = 0.30
		"guard":
			visual.rotation = 0.08

func _update_expression_pose(delta: float) -> void:
	if _expression_duration <= 0.0 or not is_instance_valid(visual):
		return
	_expression_time += delta
	var phase := clampf(_expression_time / _expression_duration, 0.0, 1.0)
	if _expression_time >= _expression_duration:
		_expression_duration = 0.0
		_expression_pose = "sereno"
		set_meta("expression_pose", _expression_pose)
		queue_redraw()
		return
	if _reduced_motion:
		match _expression_pose:
			"festa", "orgoglioso": visual.rotation = -0.10
			"curioso": visual.rotation = 0.14
			"attento", "concentrato": visual.rotation = -0.04
			"incoraggiante": visual.rotation = 0.06
		return
	var pulse := sin(phase * PI)
	match _expression_pose:
		"festa":
			visual.rotation = sin(_expression_time * 8.0) * 0.18 * pulse
		"orgoglioso":
			visual.rotation = -0.12 * pulse
			visual.scale *= 1.0 + 0.16 * pulse
		"curioso":
			visual.rotation = 0.20 * pulse
		"attento", "concentrato":
			visual.rotation = sin(_expression_time * 3.0) * 0.035
			visual.position.y += 3.0 * pulse
		"incoraggiante":
			visual.rotation = sin(_expression_time * 4.5) * 0.08 * pulse

func _draw() -> void:
	_disegna_fiuto()
	if _expression_duration <= 0.0 or _expression_pose == "sereno":
		return
	var accent := Color("f6c85f")
	match _expression_pose:
		"curioso":
			draw_arc(Vector2(18, -48), 8, -0.4, 2.4, 12, accent, 2.0, true)
		"attento", "concentrato":
			draw_line(Vector2(-16, -47), Vector2(16, -47), Color("7ad7ff"), 3.0, true)
		"orgoglioso", "festa":
			for index in 5:
				var angle := TAU * float(index) / 5.0
				draw_circle(Vector2.RIGHT.rotated(angle) * 27 + Vector2(0, -15), 2.5, accent)
		"incoraggiante":
			draw_arc(Vector2(0, -16), 30, 0.25, PI - 0.25, 18, Color("8ff6d2"), 2.5, true)

## Il segno del fiuto: due archetti dalla parte in cui il Custode ha sentito.
##
## Sono **due trattini**, non una punta: una punta e' una freccia, e una freccia
## e' esattamente quello che questo lotto ha tolto. Non dicono quanto e' lontano
## e non dicono che cos'e'; dicono che da quella parte c'e' qualcosa e che il
## Custode se n'e' accorto.
##
## Il colore e' quello del Custode e non quello degli obiettivi: chi ha imparato
## a leggere la freccia dorata non deve confondersi.
func _disegna_fiuto() -> void:
	if _fiuto == Vector2.INF or _fiuto_lato == 0.0:
		return
	var tinta := Color("d8f3ff", 0.72)
	for indice in 2:
		var scarto := 20.0 + float(indice) * 8.0
		var altezza := -34.0 + float(indice) * 7.0
		draw_arc(
			Vector2(_fiuto_lato * scarto, altezza), 5.0 + float(indice) * 1.5,
			-0.7 if _fiuto_lato > 0.0 else PI + 0.7,
			0.7 if _fiuto_lato > 0.0 else PI - 0.7,
			8, tinta, 1.8, true)

## Chiamata da `ContentPackLoader` quando il pacchetto differito è montato: il
## corpo del Custode si ricostruisce con la tavola che prima non c'era. È un
## nodo solo e succede una volta per sessione, quindi si rifà invece di
## rattopparlo — posa e temperamento li ridecide comunque il motore delle
## espressioni al fotogramma dopo.
func riapplica_arte_differita() -> void:
	if _kind_del_custode.is_empty() or not is_instance_valid(visual):
		return
	if visual.get_node_or_null("PetGeneratedArt") != null:
		remove_from_group("arte_differita")
		return
	var rifatto := OutdoorVisualFactory.build_pet(_kind_del_custode, _colore_del_custode)
	if rifatto.get_node_or_null("PetGeneratedArt") == null:
		rifatto.queue_free()
		return
	var posto := visual.get_index()
	var vecchio := visual
	visual = rifatto
	add_child(visual)
	move_child(visual, posto)
	vecchio.queue_free()
	remove_from_group("arte_differita")
