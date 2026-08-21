class_name OutdoorPlayerController
extends CharacterBody2D

@export var speed := 260.0
## Quanto va più veloce la corsa. Lo imposta la scena leggendo il contratto
## runtime (`sprintMultiplier`): il modulo «Passo lungo» lo alza, e qui non si sa
## niente di bottega né di acquisti.
var sprint_multiplier := 1.65

## **LO SCATTO.** (19 agosto 2026)
##
## Nasce da un'analisi del gioco giocato: fino a oggi Eli aveva **un verbo solo**.
## Questo file erano settantaquattro righe — cammina, e una corsa che moltiplica
## la velocità — e le dodici cose interattive della mappa finivano tutte nello
## stesso gesto: avvicinati, premi. Il corpo di Eli non decideva mai niente, e
## l'avventura era il tempo di trasferimento fra un esercizio e il successivo.
##
## ## Un solo tasto, due verbi
##
## Lo scatto **non è un tasto nuovo**: è quello che la corsa avrebbe sempre
## dovuto essere. Si preme `sprint` e Eli parte con un balzo; si tiene premuto e
## prosegue di corsa. Tre ragioni, in ordine:
##
##   1. non c'era un tasto libero decente — lo spazio è già `interact`, e Ctrl in
##      una pagina Web insieme a W chiude la scheda;
##   2. sul tablet la corsa **non esisteva affatto** (`sprint` era legato al solo
##      Maiusc, e su tablet non c'è una tastiera): un bottone solo ne consegna
##      due, e il modulo «Passo lungo» smette di essere un acquisto che su tablet
##      non faceva niente;
##   3. «ogni volta che parti di corsa, parti con uno slancio» è una cosa sola da
##      imparare invece che due.
##
## ## Che cosa attraversa, e che cosa no
##
## Attraversa **le sacche di Silenzio**: durante il balzo non c'è morso e non c'è
## spintone, ci si passa dentro. Non attraversa nient'altro, e le due esclusioni
## valgono più della regola:
##
##   - **l'acqua, mai.** Il fiume si passa col ponte-enigma, ed è una decisione
##     vincolante del progetto: uno scatto che guada trasformerebbe l'enigma in
##     scenografia. Lo scatto che tocca l'acqua si spegne e Eli resta sulla riva
##     (`OutdoorWorld._enforce_water_traversal`);
##   - **l'erba alta**, e in generale i varchi da equipaggiamento. Sono le chiavi
##     del gioco: il rovo si taglia con la falce. Il blocco è fisico e il balzo ci
##     sbatte contro come il passo.
##
## ## Perché non annulla il presidio
##
## Lo scatto passa **una** sacca e si ricarica in 1,1 secondi — la stessa finestra
## del morso. L'impulso passa **tutte** quelle nel raggio e le tiene ferme cinque
## secondi e mezzo. Sono due risposte diverse alla stessa domanda: lo scatto è
## gratis e chiede tempismo, l'impulso costa una carica guadagnata studiando ed è
## garantito. Chi ha quattro scorte addosso, o chi non vuole giocare di tempismo,
## continua a volere l'impulso — ed è giusto che sia così, perché il tempismo non
## può diventare l'unica strada in un gioco che si studia.
##
## Non costa energia, non tocca padronanza, non apre niente: è movimento.

## Quanto dura il balzo. Due decimi: abbastanza da attraversare il cerchio di
## contatto di una sacca, troppo poco per essere una seconda velocità.
const SCATTO_DURATA := 0.20

## Quanto ci mette a tornare disponibile, dal momento in cui parte. La stessa
## finestra del morso di una sacca (`WorldEnemy`, 1100 ms): una sacca attraversata
## bene e una sacca subita costano lo stesso tempo, e il confronto fra le due
## strade resta onesto.
const SCATTO_RICARICA_MSEC := 1100

## Quanto lontano porta il balzo. Lo imposta la scena dal contratto runtime
## (`dashDistance`), come il moltiplicatore della corsa: qui non si sa niente di
## moduli comprati.
var dash_distance := 190.0

## Vero mentre il pulsante dello scatto è tenuto premuto. Su tablet `sprint` non
## esiste — è legato al solo Maiusc — e senza questo tenere il dito sul pulsante
## farebbe partire il balzo ma non la corsa che gli va dietro.
var corsa_richiesta := false

var touch_target := Vector2.INF
## Contenitore visivo animato (assegnato da outdoor_world alla creazione):
## bob e inclinazione durante la camminata, con una riga atlas per direzione.
var visual: Node2D
var reduced_motion := false
var _walk_time := 0.0
var _action_until_msec := 0
var _facing_row := 0

## Lo stato del balzo: quanto ne resta, dove va, e quando se ne potrà fare un
## altro. `_ultima_direzione` serve allo scatto da fermo — chi preme senza
## muoversi scatta dove stava guardando, non in una direzione a caso.
var _scatto_restante := 0.0
var _scatto_direzione := Vector2.ZERO
var _scatto_pronto_msec := 0
var _ultima_direzione := Vector2.DOWN

const FACING_DOWN_ROW := 0
const FACING_UP_ROW := 1
const FACING_RIGHT_ROW := 2
const FACING_LEFT_ROW := 3

func _physics_process(delta: float) -> void:
	if _scatto_restante > 0.0:
		_scatto_restante -= delta
		velocity = _scatto_direzione * (dash_distance / SCATTO_DURATA)
		# `move_and_slide` fa comunque un movimento spazzato: un blocco fisico —
		# l'erba alta della falce — ferma il balzo invece di lasciarsi attraversare.
		move_and_slide()
		_animate(delta)
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var corre := Input.is_action_pressed("sprint") or corsa_richiesta
	var move_speed := speed * (sprint_multiplier if corre else 1.0)
	if input_vector.length() > 0.0:
		velocity = input_vector * move_speed
		touch_target = Vector2.INF
	elif touch_target != Vector2.INF:
		var direction := global_position.direction_to(touch_target)
		velocity = direction * move_speed
		if global_position.distance_to(touch_target) < 8.0:
			touch_target = Vector2.INF
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	if velocity.length() > 8.0:
		_ultima_direzione = velocity.normalized()
	move_and_slide()
	_animate(delta)

func set_touch_target(target: Vector2) -> void:
	touch_target = target

## **Parte il balzo.** Vero solo se è partito davvero: la scena lo usa per
## decidere se disegnare la scia, così una pressione a vuoto non produce un
## effetto che promette un movimento che non c'è stato.
##
## La direzione, in ordine di preferenza: i tasti se sono premuti, la meta del
## tocco se ce n'è una, altrimenti dove Eli stava guardando.
func scatta() -> bool:
	if _scatto_restante > 0.0 or not scatto_pronto():
		return false
	var direzione := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direzione.length() <= 0.0 and touch_target != Vector2.INF:
		direzione = global_position.direction_to(touch_target)
	if direzione.length() <= 0.0:
		direzione = _ultima_direzione
	if direzione.length() <= 0.0:
		direzione = Vector2.DOWN
	_scatto_direzione = direzione.normalized()
	_ultima_direzione = _scatto_direzione
	_scatto_restante = SCATTO_DURATA
	_scatto_pronto_msec = Time.get_ticks_msec() + SCATTO_RICARICA_MSEC
	# La posa d'azione dura quanto il balzo: senza, i fotogrammi della camminata
	# scorrerebbero a velocità di scatto e sembrerebbe un errore di animazione.
	_action_until_msec = Time.get_ticks_msec() + roundi(SCATTO_DURATA * 1000.0)
	# Il balzo prende il comando: proseguire verso la meta del tocco dopo aver
	# scattato dall'altra parte farebbe tornare Eli indietro da sola.
	touch_target = Vector2.INF
	return true

func sta_scattando() -> bool:
	return _scatto_restante > 0.0

## Dove sta andando il balzo in corso. Serve alla scena per disegnare la scia
## nella direzione giusta senza frugare fra le variabili di questo file.
func scatto_direzione() -> Vector2:
	return _scatto_direzione

func scatto_pronto() -> bool:
	return Time.get_ticks_msec() >= _scatto_pronto_msec

## Quanti millisecondi mancano al prossimo balzo. Zero se è pronto.
func scatto_attesa_msec() -> int:
	return maxi(0, _scatto_pronto_msec - Time.get_ticks_msec())

## **Spegne il balzo a metà.** La chiama la scena quando il balzo finirebbe dove
## non si può stare — in acqua, sopra ogni altra cosa. La ricarica **non** si
## azzera: un balzo speso contro una riva è comunque un balzo speso, e regalarlo
## indietro insegnerebbe a lanciarsi nel fiume per vedere che succede.
func annulla_scatto() -> void:
	_scatto_restante = 0.0
	velocity = Vector2.ZERO

func _animate(delta: float) -> void:
	if visual == null:
		return
	var sprite := visual.find_child("EliSprite", true, false) as Sprite2D
	if velocity.length() > 8.0:
		if absf(velocity.x) > absf(velocity.y):
			_facing_row = FACING_RIGHT_ROW if velocity.x > 0.0 else FACING_LEFT_ROW
		elif velocity.y < -8.0:
			_facing_row = FACING_UP_ROW
		else:
			_facing_row = FACING_DOWN_ROW
	if reduced_motion:
		_walk_time = 0.0
		visual.position.y = 0.0
		visual.rotation = 0.0
	elif sta_scattando():
		# Durante il balzo il corpo si inclina in avanti e resta basso: è l'unica
		# posa del gioco che non oscilla, e si legge come slancio.
		_walk_time = 0.0
		visual.position.y = 1.5
		visual.rotation = _scatto_direzione.x * 0.14
	elif velocity.length() > 8.0:
		_walk_time += delta * 9.5
		visual.position.y = -absf(sin(_walk_time * 0.5)) * 1.5
		visual.rotation = sin(_walk_time) * 0.025
	else:
		_walk_time = 0.0
		visual.position.y = lerpf(visual.position.y, 0.0, minf(10.0 * delta, 1.0))
		visual.rotation = lerpf(visual.rotation, 0.0, minf(10.0 * delta, 1.0))
	visual.scale.x = absf(visual.scale.x)
	if sprite != null and sprite.texture is AtlasTexture:
		var walk_frame := 1 if reduced_motion else 1 + posmod(floori(_walk_time), 4)
		var frame := 4 if Time.get_ticks_msec() < _action_until_msec else (walk_frame if velocity.length() > 8.0 else 0)
		(sprite.texture as AtlasTexture).region = Rect2(frame * 96, _facing_row * 96, 96, 96)
