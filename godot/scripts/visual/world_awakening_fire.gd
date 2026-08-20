class_name WorldAwakeningFire
extends Node2D

## Il fuoco del risveglio: l'oggetto che una prova superata accende
## ([[WorldAwakening]]). Solo estetica — non tiene stato, non tocca il
## salvataggio, non decide quando accendersi: glielo dice il mondo.
##
## Perché un fuoco e non, per dire, un colore che cambia: deve leggersi **di
## giorno e di notte**, adesso che il tempo torna a passare ([[WorldSky]]). Il
## corpo — il braciere e la fiamma — si vede in pieno sole; l'alone sta nel
## gruppo `night_glow`, quindi al calare della luce diventa il segno più forte
## della scena. Lo stesso oggetto racconta la stessa cosa a ogni ora.

const FACTORY := preload("res://scripts/visual_factory.gd")

var acceso := false

## Quanto e' completa l'accensione, 0..1. E' una variabile e non un colore
## perche' l'alone lo ridipinge il mondo a ogni fotogramma — piu' scuro e' il
## cielo, piu' forte e' il fuoco — e un tween sull'alfa verrebbe sovrascritto
## sessanta volte al secondo. Il tween muove questa, il mondo la moltiplica.
var _accensione := 0.0

var _accento := Color("f4cf69")
var _movimento_ridotto := false
var _fiamma: Node2D
var _alone: Sprite2D
var _braciere: Polygon2D

func configure(accento: Color, movimento_ridotto: bool) -> void:
	_accento = accento
	_movimento_ridotto = movimento_ridotto
	name = "FuocoDelRisveglio"
	z_index = 4
	_costruisci()

func _costruisci() -> void:
	add_child(FACTORY.make_shadow(13.0, 5.0, 0.22, 1.0))
	# Il palo e la coppa restano identici accesi o spenti: quello che cambia è
	# **dentro**. Un oggetto che compare dal nulla direbbe «questo non c'era»,
	# e invece c'era e aspettava.
	var palo := FACTORY.make_polygon(
		PackedVector2Array([Vector2(-2.5, 0), Vector2(2.5, 0), Vector2(2.0, -26), Vector2(-2.0, -26)]),
		Color("3b3126"))
	add_child(palo)
	_braciere = FACTORY.make_polygon(
		PackedVector2Array([Vector2(-9, -26), Vector2(9, -26), Vector2(6, -34), Vector2(-6, -34)]),
		Color("564636"))
	add_child(_braciere)

	# **Fuori dal gruppo `night_glow`.** Quel gruppo lo alza il mondo al calare
	# della luce, senza chiedere niente a nessuno: un fuoco ancora spento si
	# sarebbe acceso da solo la prima volta che veniva sera, e la ricompensa
	# avrebbe smesso di dipendere dal lavoro fatto. Qui l'ora del giorno decide
	# solo QUANTO forte si vede un fuoco gia' acceso.
	_alone = FACTORY.make_glow(30.0, _accento, 0.0)
	_alone.position = Vector2(0, -34)
	add_child(_alone)

	_fiamma = Node2D.new()
	_fiamma.name = "Fiamma"
	_fiamma.position = Vector2(0, -34)
	_fiamma.visible = false
	var lingua := FACTORY.make_polygon(
		PackedVector2Array([Vector2(-5, 0), Vector2(0, -14), Vector2(5, 0), Vector2(0, -3)]),
		Color(_accento, 0.95))
	_fiamma.add_child(lingua)
	var cuore := FACTORY.make_polygon(
		PackedVector2Array([Vector2(-2.4, -1), Vector2(0, -8), Vector2(2.4, -1), Vector2(0, -3)]),
		Color("fff3d0"))
	_fiamma.add_child(cuore)
	add_child(_fiamma)

## Acceso senza animazione: è il caso del rientro in un mondo già giocato, dove i
## fuochi guadagnati devono essere già lì. Animarli tutti all'ingresso sarebbe una
## parata di ricompense che nessuno ha appena vinto.
func accendi(animato: bool) -> void:
	if acceso:
		return
	acceso = true
	_fiamma.visible = true
	_braciere.color = Color("6d5942")
	if _movimento_ridotto or not animato:
		_accensione = 1.0
		if not _movimento_ridotto:
			FACTORY.attach_anim(_fiamma, "pulse", 1.4, 0.9)
		return
	_accensione = 0.0
	_fiamma.scale = Vector2(0.4, 0.2)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "_accensione", 1.0, 0.45)
	tween.tween_property(_fiamma, "scale", Vector2.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FACTORY.attach_anim(_fiamma, "pulse", 1.4, 0.9)
	# L'anello che si allarga una volta sola: è il «qui» del momento, e serve
	# perché la prova è appena finita in un pannello e lo sguardo deve tornare
	# nel mondo sapendo dove guardare.
	var anello := FACTORY.make_ring(16.0, Color(_accento, 0.85), 2.4, 24)
	anello.position = Vector2(0, -34)
	add_child(anello)
	FACTORY.attach_anim(anello, "ping", 1.0, 1.0)

## La fiammata del richiamo: i fuochi già accesi divampano una volta, insieme.
## Non accende niente — un fuoco spento resta spento — perché il richiamo è
## regia, e i fuochi si pagano una prova per volta.
func fiammata() -> void:
	if not acceso or _movimento_ridotto or not is_instance_valid(_fiamma):
		return
	var tween := create_tween()
	tween.tween_property(_fiamma, "scale", Vector2(1.7, 1.9), 0.32) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_fiamma, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## Quanto si vede il fuoco a quest'ora. Lo chiama il mondo a ogni fotogramma,
## con la stessa luce che pilota il cielo: e' cosi' che lo stesso oggetto sa
## raccontare la stessa cosa a mezzogiorno e a mezzanotte, forte dove serve.
func aggiorna_notte(luce_del_giorno: float) -> void:
	if not is_instance_valid(_alone):
		return
	_alone.modulate.a = (0.26 + (1.0 - clampf(luce_del_giorno, 0.0, 1.0)) * 0.58) * _accensione
