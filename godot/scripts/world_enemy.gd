class_name WorldEnemy
extends CharacterBody2D

const GUARDIAN_VISUALS := preload("res://scripts/game/guardian_visual_catalog.gd")

## **Le sacche di Silenzio.** Pattugliano, inseguono e respingono Eli.
##
## **Cattive sul serio dal 7 agosto 2026**, su indicazione del committente dopo
## un collaudo: «devono essere sempre piu' cattivi man mano che saliamo di
## livello». Prima erano un ostacolo puramente scenico — respingevano e basta,
## e il grado di potenza appena introdotto non serviva a niente contro di loro.
##
## Adesso il contatto **costa energia**, e la cifra e' la differenza fra quanto
## e' forte la sacca e quanto e' forte Eli:
##
##     costo = (grado della sacca − grado di Eli) × COSTO_PER_GRADO
##
## Che e' il punto di tutto il lotto precedente: **la barra della potenza serve a
## qualcosa**. Chi si allena passa in mezzo alle sacche senza pagare; chi non si
## allena le paga tutte. E siccome il grado si guadagna facendo prove, la strada
## per diventare piu' forti e' la stessa che il gioco vuole insegnare.
##
## **Non blocca mai.** Se l'energia non basta si paga quel che c'e' e si passa
## lo stesso: e' la regola di tutta la mappa — niente che sta qui puo' fermare
## la progressione. E chi non vuole pagare attraversa di slancio: la corsa
## passa una sacca senza morso, gratis, ogni 1,1 secondi.

## Quanta energia costa ogni grado di scarto. Due: un incontro sfortunato si
## assorbe, una traversata fatta di sacche no.
const COSTO_PER_GRADO := 2

## **Due popolazioni, e tutte e due si sfidano.** (24 agosto 2026)
##
## Il ruolo si dichiara invece di dedursi dal forziere addosso: `treasure_id`
## vuoto voleva dire «pattuglia», pieno voleva dire «guardiana», e una deduzione
## avrebbe fatto finire muta dentro una delle due qualunque specie nuova.
##
##   PATTUGLIA  vaga per il mondo e ti trova lei. Respinge, morde, e si sfida;
##   GUARDIANO  sta su un forziere e lo chiude finche' non lo si batte in duello.
##
## Il 19 agosto ce n'era una terza — la SCORTA, l'anello attorno a un forziere
## gia' sorvegliato — tolta il 24 agosto su indicazione del committente: non si
## sfidava e non chiudeva niente, quindi chiedeva riflessi e pazienza invece di
## competenza. Vedi [[pattuglia_sfidabile]].
const RUOLO_PATTUGLIA := "pattuglia"
const RUOLO_GUARDIANO := "guardiano"


## Che cosa fa questa sacca sulla mappa. Vedi le tre costanti qui sopra.
var ruolo := RUOLO_PATTUGLIA

## **Il richiamo.** (19 agosto 2026) Quando l'apparato diventa riparabile e la
## nave chiama, le sacche si accorgono che Eli sta andando via: la soglia di
## inseguimento si allunga di meta'. Il morso non cambia di un'energia e la
## regola della mappa non si tocca — non fermano niente, non chiudono niente:
## solo, per l'ultima traversata, si fanno sentire.
var richiamo := false

## Quanto si allunga la soglia di inseguimento durante il richiamo.
const RICHIAMO_ALLUNGO := 1.5

## **La caccia.** (19 agosto 2026) Il momento d'autore del mondo 5
## ([[WorldSetPiece]]): per sedici secondi tutte le sacche del mondo si voltano
## insieme. Il morso resta quello di sempre — non c'e' un danno nuovo e non si
## puo' perdere niente — cambia solo che, per una volta, il mondo ti insegue.
var caccia := false

## Quanto si allunga la soglia durante la caccia. Quattro volte: da qualunque
## punto della mappa visibile, si voltano.
const CACCIA_ALLUNGO := 4.0

## **Il forziere che questa sacca sorveglia**, vuoto se pattuglia e basta.
##
## Richiesta del committente del 7 agosto 2026: «i nemici proteggono i bauli con
## i frammenti». Una guardiana non si allontana mai dal suo forziere: il suo
## raggio di inseguimento e' piu' corto ma dentro quel raggio e' molto piu'
## aggressiva, e finche' e' viva il forziere non si apre.
##
## Il forziere contiene frammenti, cioe' cosmetici: **niente che serva a
## progredire**. E' la condizione che rende lecito metterci davanti una prova di
## abilita' in un gioco che si studia.
var treasure_id := ""

var world: Node
var anchor := Vector2.ZERO
var tier := 1
var accent := Color("ff7b72")
var enemy_name := "Sbiadito"
var phase := 0.0
var stunned_until_msec := 0
var contact_ready_msec := 0
## Quanto lontano questa sacca si accorge di Eli, in frazione della sua vista
## piena. Lo abbassa «Andatura felpata» ([[ExpeditionModules]]); la scena lo
## passa dal contratto runtime, e qui non si sa niente di che cosa sia stato
## comprato.
var vista_scala := 1.0
var reduced_motion := false
var body_shape: CollisionShape2D
var contact_area: Area2D
var visual: Node2D
## Il mondo di questa sacca. Serve a rimontare l'illustrazione del guardiano se
## `content.pck` arriva dopo che la sacca è già nata.
var livello_del_mondo := 1

func setup(
	world_ref: Node, start: Vector2, level: int, subject: String, color: Color,
	index: int, ruolo_iniziale := RUOLO_PATTUGLIA
) -> void:
	world = world_ref
	anchor = start
	position = start
	ruolo = ruolo_iniziale
	# Il grado cresce ogni TRE mondi invece che ogni sei: a ventiquattro mondi
	# la scala arriva a otto invece che a quattro, e la differenza fra il mondo 3
	# e il mondo 21 si sente. Prima due mondi lontanissimi avevano la stessa
	# sacca.
	tier = clampi(1 + floori(float(level - 1) / 3.0), 1, 8)
	# Il ruolo si decide PRIMA del corpo: il grado entra nella scala, nei
	# frammenti che orbitano e nel raggio del contatto, e una sacca disegnata su
	# un grado che non e' il suo sarebbe una bugia disegnata.

	accent = color
	phase = float(index) * 1.73
	enemy_name = _name_for_subject(subject, tier)
	set_meta("nature", "sacca_di_silenzio")
	set_meta("stabilized", false)
	add_to_group("world_enemy")
	_build_collision()
	_build_visual(level)

func _build_collision() -> void:
	body_shape = CollisionShape2D.new()
	body_shape.name = "EnemyBodyCollision"
	var body_circle := CircleShape2D.new()
	body_circle.radius = 22.0 + float(mini(tier, 4)) * 2.0
	body_shape.shape = body_circle
	add_child(body_shape)
	contact_area = Area2D.new()
	contact_area.name = "EnemyContact"
	var contact_shape := CollisionShape2D.new()
	var contact_circle := CircleShape2D.new()
	contact_circle.radius = 34.0 + float(tier) * 2.0
	contact_shape.shape = contact_circle
	contact_area.add_child(contact_shape)
	contact_area.body_entered.connect(_on_body_entered)
	add_child(contact_area)

func _build_visual(level: int) -> void:
	visual = Node2D.new()
	visual.name = "EnemyVisual"
	visual.scale = Vector2.ONE * (1.06 + float(tier) * 0.055)
	visual.add_child(OutdoorVisualFactory.make_shadow(24.0, 8.0, 0.42, 20.0))
	var faded_accent := accent.lerp(Color("9299a8"), 0.68)
	var aura := OutdoorVisualFactory.make_glow(40.0 + tier * 4.0, faded_accent, 0.22)
	aura.add_to_group("night_glow")
	visual.add_child(aura)
	livello_del_mondo = level
	var guardian_sprite := _monta_arte_guardiano()
	var shell_color := faded_accent.darkened(0.38)
	var outer_ring := OutdoorVisualFactory.make_ring(31.0 + tier * 2.0, Color(faded_accent, 0.48), 2.6, 28)
	outer_ring.scale = Vector2(1.0, 0.82)
	outer_ring.position.y = -6
	visual.add_child(outer_ring)
	for shard_index in range(3 + tier):
		var shard_angle := TAU * float(shard_index) / float(3 + tier) + phase * 0.15
		var shard := OutdoorVisualFactory.make_polygon(PackedVector2Array([
			Vector2(-4, 5), Vector2(0, -7), Vector2(4, 5), Vector2(0, 2),
		]), Color(faded_accent, 0.66))
		shard.position = Vector2(cos(shard_angle), sin(shard_angle)) * Vector2(36.0 + tier, 27.0 + tier)
		shard.rotation = shard_angle + PI * 0.5
		visual.add_child(shard)
	match posmod(level - 1, 4):
		0:
			visual.add_child(OutdoorVisualFactory.make_polygon(
				OutdoorVisualFactory.ellipse_polygon(21, 15, 20), shell_color, Vector2(0, -7)))
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([Vector2(-29, -7), Vector2(-18, -14), Vector2(-18, 0)]), Color(accent, 0.82)))
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([Vector2(29, -7), Vector2(18, -14), Vector2(18, 0)]), Color(accent, 0.82)))
		1:
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([Vector2(0, -33), Vector2(23, -5), Vector2(0, 18), Vector2(-23, -5)]), shell_color))
		2:
			var ring := OutdoorVisualFactory.make_ring(24.0, accent, 5.0, 6)
			ring.position.y = -6
			visual.add_child(ring)
			visual.add_child(OutdoorVisualFactory.make_polygon(
				OutdoorVisualFactory.circle_polygon(15, 16), shell_color, Vector2(0, -6)))
		_:
			visual.add_child(OutdoorVisualFactory.make_polygon(
				PackedVector2Array([
					Vector2(-23, 10), Vector2(-17, -25), Vector2(0, -34),
					Vector2(17, -25), Vector2(23, 10), Vector2(0, 19),
				]), shell_color))
	# Non e' un occhio ostile: e' un'iscrizione diventata illeggibile.
	var glyph_glow := OutdoorVisualFactory.make_glow(10.0, Color("c5cad3"), 0.46)
	glyph_glow.name = "FadedGlyphGlow"
	glyph_glow.position = Vector2(0, -8)
	visual.add_child(glyph_glow)
	visual.add_child(OutdoorVisualFactory.make_polygon(
		OutdoorVisualFactory.circle_polygon(3.8, 12), faded_accent.lightened(0.18), Vector2(0, -8)))
	visual.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
		Vector2(-11, -9), Vector2(-4, -13), Vector2(4, -13),
		Vector2(11, -9), Vector2(4, -5), Vector2(-4, -5),
	]), Color(0.02, 0.05, 0.08, 0.88)))
	visual.add_child(OutdoorVisualFactory.make_polygon(
		OutdoorVisualFactory.circle_polygon(3.2, 12), faded_accent.lightened(0.32), Vector2(0, -9)))
	for line_index in 3:
		var fragment := Line2D.new()
		fragment.name = "BrokenInscription_%d" % line_index
		fragment.width = 2.2
		fragment.default_color = Color("c7ccd4", 0.48)
		fragment.points = PackedVector2Array([
			Vector2(-13 + line_index * 2, 4 + line_index * 5),
			Vector2(-3, 4 + line_index * 5),
			Vector2(4, 3 + line_index * 5),
			Vector2(12 - line_index * 2, 4 + line_index * 5),
		])
		visual.add_child(fragment)
	var tier_ring := OutdoorVisualFactory.make_ring(27.0 + tier * 2.0, Color(accent, 0.72), 2.0, 24)
	tier_ring.scale = Vector2(1.0, 0.34)
	tier_ring.position.y = 17
	visual.add_child(tier_ring)
	# Il vecchio corpo procedurale resta dietro come fallback strutturale e per i
	# nodi semantici degli audit; l'illustrazione approvata e' il livello visibile.
	if guardian_sprite != null:
		visual.move_child(guardian_sprite, visual.get_child_count() - 1)
	add_child(visual)
	_apply_role_visual()

	var label := Label.new()
	label.name = "EnemyLabel"
	label.text = "SBIADITO · T%d" % tier
	label.position = Vector2(-80, -76)
	label.custom_minimum_size.x = 140
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_color", accent.lightened(0.25))
	label.accessibility_name = "%s, pattuglia di Silenzio; l'impulso la rende leggibile" % enemy_name
	add_child(label)

## **L'illustrazione del guardiano arriva con il pacchetto differito.**
## (20 agosto 2026)
##
## Le 24 tavole dei guardiani stanno in `content.pck` insieme ai 74 ritratti e
## all'audio ([[ContentPackLoader]]): una sacca che nasce mentre il pacchetto è
## ancora in volo trova `texture_for()` vuoto e resta il guscio vettoriale. Era
## previsto — il ripiego esiste apposta, il gioco non si rompe — ma non era
## previsto che ci restasse **per sempre**: nessuno diceva a chi era già nato
## che i contenuti erano arrivati. E siccome la copia locale del pacchetto porta
## il commit nel nome, ogni build nuova la ributta via e la riscarica: il primo
## giro di ogni versione mostrava i gusci al posto dei guardiani.
##
## L'audio quella spinta ce l'aveva già (`refresh_after_content_load`).
## L'arte no.
func _monta_arte_guardiano() -> Sprite2D:
	if visual == null:
		return null
	var gia_montata := visual.get_node_or_null("GuardianGeneratedArt") as Sprite2D
	if gia_montata != null:
		return gia_montata
	var texture := GUARDIAN_VISUALS.texture_for(livello_del_mondo)
	if texture == null:
		add_to_group("arte_differita")
		return null
	var sprite := Sprite2D.new()
	sprite.name = "GuardianGeneratedArt"
	sprite.texture = texture
	sprite.scale = Vector2.ONE * (118.0 / 384.0)
	sprite.position = Vector2(0, -14)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.add_child(sprite)
	set_meta("usesGeneratedGuardianArt", true)
	set_meta("guardianArtPath", texture.resource_path)
	set_meta("guardianVisualFamily", GUARDIAN_VISUALS.family_for(livello_del_mondo))
	remove_from_group("arte_differita")
	return sprite

## Chiamata da `ContentPackLoader` quando il pacchetto differito è montato.
## L'illustrazione torna in fondo alla lista: la sagoma di ruolo le sta sotto e
## non deve coprirla — lo pretende `generated_character_art_audit`.
func riapplica_arte_differita() -> void:
	var sprite := _monta_arte_guardiano()
	if sprite != null and visual != null:
		visual.move_child(sprite, visual.get_child_count() - 1)

func _apply_role_visual() -> void:
	if visual == null:
		return
	var previous := visual.get_node_or_null("RoleVisualMarker")
	if previous != null:
		previous.queue_free()
	var marker := Node2D.new()
	marker.name = "RoleVisualMarker"
	var faded := accent.lerp(Color("9299a8"), 0.68)
	match ruolo:
		RUOLO_GUARDIANO:
			# Corona alta: ferma e larga, riconoscibile prima del raggio di sfida.
			marker.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
				Vector2(-28, 8), Vector2(-24, -26), Vector2(-10, -13),
				Vector2(0, -35), Vector2(10, -13), Vector2(24, -26), Vector2(28, 8),
			]), Color(faded.lightened(0.12), 0.92)))
			set_meta("roleVisualMarker", "crown")
		_:
			# Tre vele spezzate: una pattuglia mobile, senza il profilo del guardiano.
			for x in [-13.0, 0.0, 13.0]:
				marker.add_child(OutdoorVisualFactory.make_polygon(PackedVector2Array([
					Vector2(x - 5, 8), Vector2(x, -20), Vector2(x + 5, 8),
				]), Color(faded.lightened(0.08), 0.86)))
			set_meta("roleVisualMarker", "sails")
	# **La sagoma sta dietro e sopra, non addosso.** (20 agosto 2026)
	#
	# Nata al centro del corpo e come ultima figlia, copriva il guardiano
	# illustrato: 43×56 px in mezzo a uno sprite da 118. Non è una questione di
	# gusto — `generated_character_art_audit` lo vieta da prima di questo lotto,
	# e pretende che l'illustrazione resti l'ultima figlia di `visual`.
	#
	# Quindi la sagoma passa sotto, e per restare leggibile deve **sporgere**
	# dalla silhouette invece di sovrapporsi: lo sprite occupa x ±59 e da y −73
	# a +45, e ogni ruolo esce da un lato diverso — la corona con le punte sopra
	# la testa e le vele sopra. Scala e quota sono calcolate su
	# quei numeri, non a occhio: se un giorno lo sprite cambia misura, vanno
	# rifatte insieme a lui.
	match ruolo:
		RUOLO_GUARDIANO:
			marker.scale = Vector2(2.0, 2.0)
			marker.position.y = -34.0
		_:
			marker.scale = Vector2(2.6, 2.6)
			marker.position.y = -40.0
	visual.add_child(marker)
	var illustrazione := visual.get_node_or_null("GuardianGeneratedArt")
	if illustrazione != null:
		visual.move_child(illustrazione, visual.get_child_count() - 1)
	set_meta("roleVisualDistinct", true)

func _physics_process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now < stunned_until_msec:
		velocity = Vector2.ZERO
		return
	if modulate.a < 0.99:
		_restore()
	if world == null or not world.has_method("enemy_gameplay_active") or not bool(world.call("enemy_gameplay_active")):
		velocity = Vector2.ZERO
		return
	phase += delta * (0.75 + float(tier) * 0.08)
	# Il respiro largo: una sacca si legge da lontano, ed e' quello che permette
	# di decidere se affrontarla PRIMA di averla addosso.
	var respiro := Vector2(92.0, 62.0)
	var target := anchor + Vector2(cos(phase), sin(phase * 0.72)) * respiro
	var player := world.get("player") as CharacterBody2D
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		# Chi custodisce ha un guinzaglio corto e una soglia bassa: non insegue per
		# mezza mappa — sarebbe fastidio, non pericolo — ma chi si avvicina al
		# forziere se la trova addosso subito.
		var soglia := (190.0 + tier * 12.0 if _ancorata() else 250.0 + tier * 20.0) * vista_scala
		if caccia:
			soglia *= CACCIA_ALLUNGO
		elif richiamo:
			soglia *= RICHIAMO_ALLUNGO
		if distance < soglia:
			target = player.global_position
		if _ancorata() and anchor.distance_to(target) > _guinzaglio():
			target = anchor
	var speed := 74.0 + float(tier) * 11.0
	if _ancorata():
		# Chi custodisce e' piu' svelto dentro il suo territorio: e' li' che deve
		# essere un pericolo, ed e' li' che c'e' qualcosa da difendere.
		speed += 26.0
	velocity = global_position.direction_to(target) * speed
	if global_position.distance_to(target) < 8.0:
		velocity = Vector2.ZERO
	move_and_slide()

## **Ferma una sacca per qualche secondo.** Non la scioglie: si riprende da
## sola, e nel frattempo non morde e non respinge.
##
## **Non e' piu' l'impulso.** (21 agosto 2026) Fino al 20 agosto la chiamava
## soprattutto l'impulso stabilizzante, che e' stato tolto. I due chiamanti
## rimasti non c'entrano niente con quello, e sono tutti e due necessari:
##
##   - la **sconfitta in duello**, per due secondi e mezzo: senza, la sacca e'
##     addosso a Eli nell'istante in cui il pannello si chiude e il duello
##     ricomincerebbe da solo;
##   - i **momenti d'autore**, per venti: una sacca che morde mentre il mondo
##     sta dicendo la sua battuta trasforma una scena in un incidente.
func stun(seconds: float = 5.0) -> void:
	stunned_until_msec = Time.get_ticks_msec() + roundi(seconds * 1000.0)
	velocity = Vector2.ZERO
	body_shape.set_deferred("disabled", true)
	(contact_area.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	set_meta("stabilized", true)
	if reduced_motion:
		modulate = Color(0.78, 0.98, 1.0, 0.96)
		scale = Vector2.ONE * 0.96
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.78, 0.98, 1.0, 0.96), 0.18)
	tween.tween_property(self, "scale", Vector2.ONE * 0.94, 0.18)

## Vero se questa sacca ha qualcosa da custodire, e quindi un territorio. Le
## pattuglie non ce l'hanno: vagano, e il mondo intero e' il loro giro.
func _ancorata() -> bool:
	return ruolo != RUOLO_PATTUGLIA

## Quanto puo' allontanarsi dal proprio ancoraggio inseguendo Eli. Vale per la
## guardiana, che deve restare sul forziere che custodisce: se inseguendo si
## portasse via, il forziere resterebbe scoperto senza che nessuno lo abbia
## guadagnato.
func _guinzaglio() -> float:
	return 260.0

## Mette questa sacca di guardia a un forziere. Si chiama DOPO `setup`, perche'
## chi crea le sacche scopre i forzieri solo quando il pezzo di mappa che li
## contiene e' stato costruito.
func sorveglia(id: String) -> void:
	treasure_id = id
	ruolo = RUOLO_GUARDIANO
	_apply_role_visual()
	enemy_name = GUARDIAN_VISUALS.name_for(int(world.get("world_level")) if world != null else 1)
	var label := get_node_or_null("EnemyLabel") as Label
	if label != null:
		# Il nome completo vive nel duello e nell'accessibilita': sul mondo il
		# cartiglio corto non copre il guardiano illustrato.
		#
		# **La materia sta scritta sul cartiglio** (17 agosto 2026). Da quando i
		# guardiani sfidano in due materie, avvicinarsi dev'essere una scelta e
		# non una lotteria: si legge da lontano se quello chiede conti o voci, e
		# si decide se affrontarlo adesso o allenarsi prima.
		var materia := DuelRules.materia(str(get_meta("guardId", "")))
		label.text = "GUARDIANO %s · T%d" % [str(DuelRules.NOMI_MATERIA.get(materia, "")), tier]
		label.accessibility_name = "%s, guardiano di un forziere; sfida in %s, si scioglie spezzandogli i sigilli" % [
			enemy_name, "modi e tempi verbali" if materia == DuelRules.VOCI else "calcolo veloce"]

## **La pattuglia adesso si sfida.** (24 agosto 2026)
##
## Qui c'era `fa_la_scorta`, che metteva una sacca nell'anello attorno a un
## forziere sorvegliato. L'anello è stato tolto: due sacche che mordono e
## respingono e basta chiedevano riflessi, non competenza, e nel mondo 1 erano la
## faccia che il mondo mostrava più spesso — la faccia di un nemico che non si
## può affrontare.
##
## Al posto suo, il gesto che mancava alla popolazione che resta. Una pattuglia
## gira per il mondo e ti trova lei: adesso quell'incontro può finire in una
## prova invece che in un morso.
##
## Il cartiglio cambia parola, e la parola conta: chi legge «GUARDIANO» sa che
## lì c'è un forziere da liberare, chi legge «SBIADITO» sapeva che c'era solo da
## passare. Adesso una pattuglia annuncia la propria materia come la annuncia una
## guardiana — perché avvicinarsi resti una scelta informata e non una lotteria.
##
## Il guard-rail non si muove: dietro una pattuglia non c'è niente che serva a
## salire di livello. Vincere dà frammenti, cioè cosmetici; perdere costa quanto
## un morso; e come tutto il resto della mappa **non blocca** — si può sempre
## girarle attorno o passarle accanto di slancio.
func pattuglia_sfidabile(pattuglia_id: String) -> void:
	set_meta("guardId", pattuglia_id)
	var label := get_node_or_null("EnemyLabel") as Label
	if label == null:
		return
	var materia := DuelRules.materia(pattuglia_id)
	label.text = "SBIADITO %s · T%d" % [str(DuelRules.NOMI_MATERIA.get(materia, "")), tier]
	label.accessibility_name = "%s, pattuglia di Silenzio; sfida in %s, si scioglie spezzandole i sigilli" % [
		enemy_name, "modi e tempi verbali" if materia == DuelRules.VOCI else "calcolo veloce"]

## **Sciolta per sempre.** Non e' uno stordimento: la sacca sparisce, il
## forziere che sorvegliava si apre, e rientrando nel mondo non la si ritrova.
## Chi ha vinto il duello non deve rigiocarlo per lo stesso premio.
func elimina() -> void:
	set_meta("stabilized", true)
	remove_from_group("world_enemy")
	if is_instance_valid(body_shape):
		body_shape.set_deferred("disabled", true)
	if is_instance_valid(contact_area):
		contact_area.set_deferred("monitoring", false)
	if reduced_motion:
		queue_free()
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.tween_property(self, "scale", Vector2.ONE * 0.3, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func is_stunned() -> bool:
	return Time.get_ticks_msec() < stunned_until_msec

func _restore() -> void:
	position = anchor
	modulate = Color.WHITE
	scale = Vector2.ONE
	set_meta("stabilized", false)
	body_shape.set_deferred("disabled", false)
	(contact_area.get_child(0) as CollisionShape2D).set_deferred("disabled", false)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or is_stunned():
		return
	var now := Time.get_ticks_msec()
	if now < contact_ready_msec:
		return
	contact_ready_msec = now + 1100
	if world != null and world.has_method("_on_enemy_contact"):
		world.call("_on_enemy_contact", self, body)

func _name_for_subject(subject: String, rank: int) -> String:
	var names := {
		"matematica": "Sbiadito dei Conti", "italiano": "Sbiadito delle Parole",
		"coding": "Sbiadito dei Cicli", "inglese": "Sbiadito delle Voci",
		"fisica": "Sbiadito del Moto", "musica": "Sbiadito dei Suoni",
		"latino": "Sbiadito dei Glifi", "elettronica": "Sbiadito dei Circuiti",
		"geografia": "Sbiadito delle Mappe", "scienze": "Sbiadito delle Forme",
		"storia": "Sbiadito delle Memorie", "logica": "Sbiadito delle Regole",
	}
	var romani := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
	return "%s %s" % [str(names.get(subject, "Sbiadito")), romani[clampi(rank, 1, romani.size()) - 1]]
