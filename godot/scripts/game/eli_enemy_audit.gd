extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PLAYER := preload("res://scripts/player_controller.gd")

## C-P6 #7/#8: Eli usa le 4 direzioni del foglio a 20 frame; le anomalie
## ostacolano senza sottrarre progresso e l'impulso è disponibile su tablet.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Animazione direzionale: il vecchio runtime restava sempre sul frame (0,0).
	var controller := PLAYER.new()
	var presentation := OutdoorVisualFactory.build_player(Color("6be7d6"))
	controller.add_child(presentation)
	controller.visual = presentation.get_node("Visual")
	root.add_child(controller)
	var sprite := controller.visual.find_child("EliSprite", true, false) as Sprite2D
	assert(sprite != null and sprite.texture is AtlasTexture, "sprite Eli non animabile")
	var sheet := (sprite.texture as AtlasTexture).atlas
	assert(sheet.resource_path.ends_with("assets/player/eli-scintilla-v1.png"),
		"il runtime non parte dalla forma Scintilla approvata")
	assert(sheet.get_width() == 480 and sheet.get_height() == 384,
		"foglio Eli non conforme al contratto 5x4 da 96 px")
	controller.velocity = Vector2.RIGHT * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 192.0, "direzione destra non usa la riga che guarda a destra")
	assert((sprite.texture as AtlasTexture).region.position.x > 0.0, "camminata ferma sul frame idle")
	controller.velocity = Vector2.LEFT * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 288.0, "direzione sinistra non usa la riga che guarda a sinistra")
	controller.velocity = Vector2.UP * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 96.0, "direzione su non usa la riga corretta")
	controller.velocity = Vector2.DOWN * 100.0
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 0.0, "direzione giù non usa la riga corretta")
	controller.velocity = Vector2.ZERO
	controller.call("_animate", 0.2)
	assert((sprite.texture as AtlasTexture).region.position.y == 0.0, "Eli cambia direzione quando si ferma")
	controller.play_pulse_action()
	controller.call("_animate", 0.01)
	assert((sprite.texture as AtlasTexture).region.position.x == 384.0, "posa impulso assente")
	controller.queue_free()

	var initial := GameSaveManager._default_data()
	initial["level"] = 7
	initial["energy"] = 500
	initial["worlds"] = {"unlocked": range(1, 8), "current": 7}
	var request := NativeWorldState.default_request("eli-enemy-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = 7
	var world := WORLD_SCENE.instantiate()
	world.set("launch_request_override", request)
	world.set("launch_stream_radius_override", 0)
	root.add_child(world)
	await process_frame
	await process_frame
	# **Tre popolazioni, non due.** (7 agosto 2026 → 19 agosto 2026)
	#
	# Le sacche che pattugliano scalano col mondo, e quella regola resta. Dal
	# 7 agosto ce ne sono anche di GUARDIANE, una per forziere scoperto: quelle
	# non seguono il conteggio del mondo — seguono i forzieri, che compaiono e
	# spariscono mentre la mappa scorre. Contarle insieme faceva fallire questo
	# audit su una regola che non e' mai stata violata.
	#
	# Dal 19 agosto ce n'e' una terza — le SCORTE dell'anello — e la partizione
	# non si deduce piu' dal forziere addosso: la dice il **ruolo**, che ogni
	# sacca dichiara ([[WorldEnemy]]). Dedurla era la ragione per cui una terza
	# specie sarebbe finita muta dentro una delle due.
	var tutte := get_nodes_in_group("world_enemy")
	var enemies: Array = []
	var guardiani: Array = []
	var scorte: Array = []
	for sacca in tutte:
		match str(sacca.get("ruolo")):
			WorldEnemy.RUOLO_GUARDIANO: guardiani.append(sacca)
			WorldEnemy.RUOLO_SCORTA: scorte.append(sacca)
			_: enemies.append(sacca)
	assert(enemies.size() == 2, "il mondo 7 deve scalare a due anomalie in pattuglia, trovate %d" % enemies.size())
	# Una guardiana senza forziere sarebbe una sacca piazzata a caso con
	# un'etichetta diversa: il legame col premio e' tutto il senso della cosa.
	for guardia in guardiani:
		assert(not str(guardia.get("treasure_id")).is_empty(),
			"guardiano senza forziere da sorvegliare")
		assert(guardia.find_child("EnemyChallenge", true, false) != null,
			"guardiano che non si puo' affrontare: si potrebbe solo subire")
	# Una scorta non si sfida: non ha il gesto, e non deve averlo. Se un giorno
	# ne comparisse una con `EnemyChallenge`, il bambino aprirebbe un duello
	# davanti a una sacca che non custodisce niente.
	for scorta in scorte:
		assert(scorta.find_child("EnemyChallenge", true, false) == null,
			"una scorta si puo' sfidare: promette un duello che non esiste")
		assert(not str(scorta.get("presidio")).is_empty(),
			"scorta senza presidio: e' una pattuglia con un'etichetta diversa")
	for enemy in enemies:
		assert(str(enemy.get("enemy_name")).begins_with("Sbiadito"),
			"sentinella legacy non rinominata: %s" % str(enemy.get("enemy_name")))
		assert(str(enemy.get_meta("nature", "")) == "sacca_di_silenzio",
			"Sbiadito senza natura narrativa")
		assert(enemy.find_child("FadedGlyphGlow", true, false) != null,
			"Sbiadito senza iscrizione illeggibile")
		assert(enemy.find_children("BrokenInscription_*", "Line2D", true, false).size() == 3,
			"iscrizione spezzata non riconoscibile per forma")
	var pulse := world.find_child("CombatPulseButton", true, false) as Button
	assert(pulse != null and pulse.custom_minimum_size.x >= 64.0 and pulse.custom_minimum_size.y >= 64.0, "impulso touch insufficiente")

	var player: CharacterBody2D = world.get("player")
	var first: Node2D = enemies[0]
	first.global_position = player.global_position + Vector2(54, 0)
	first.set("anchor", first.global_position)
	var energy_before := int(world.get("game_save").energy())
	# **L'impulso adesso si guadagna** (14 agosto 2026): non è più un cooldown che
	# si ricarica da solo, è una carica che si ottiene superando prove. Qui si
	# misura la meccanica dello stordimento, non l'economia — quella la tiene
	# `pulse_economy_audit` — quindi la carica si accredita esplicitamente, con lo
	# stesso gesto che la darebbe al giocatore: prove superate.
	for _prova in range(PulseCharge.PROVE_PER_CARICA):
		PulseCharge.accredita(world.get("game_save"))
	world.call("_combat_pulse")
	await process_frame
	assert(bool(first.call("is_stunned")), "l'impulso non stabilizza l'anomalia vicina")
	assert(bool(first.get_meta("stabilized", false)), "l'impulso non marca lo Sbiadito come leggibile")
	assert(first.visible and first.modulate.a >= 0.9 and first.scale.x >= 0.9,
		"stabilizzare elimina lo Sbiadito invece di renderlo leggibile")
	assert(int(world.get("game_save").energy()) == energy_before, "il combattimento non deve tassare l'energia didattica")
	# Spesa l'unica carica, il pulsante deve dirlo: un comando che sembra pronto e
	# non fa niente è peggio di un comando spento.
	assert(pulse.disabled, "serbatoio dell'impulso vuoto non comunicato al touch")

	var second: Node2D = enemies[1]
	second.global_position = player.global_position - Vector2(28, 0)
	var before_contact := player.global_position
	var save_prima: GameSaveManager = world.get("game_save")
	var materia := str(world.call("_world_subject"))
	var mastery_before := float(save_prima.mastery_of(materia))
	world.call("_on_enemy_contact", second, player)
	assert(player.global_position.distance_to(before_contact) > 40.0, "il nemico non ostacola/respinge Eli")
	# **Il contatto costa, dal 7 agosto 2026.** Questa prova pretendeva che non
	# costasse niente, e con quella regola le sacche erano un ostacolo scenico:
	# il grado di potenza non serviva a niente contro di loro, e la barra era un
	# indicatore invece che un desiderio.
	#
	# Cio' che resta vero, e che va tenuto: il morso tocca solo l'ENERGIA, mai la
	# padronanza — una sacca non puo' farti disimparare — e non blocca mai il
	# passaggio.
	var save_dopo: GameSaveManager = world.get("game_save")
	assert(save_dopo.energy() <= energy_before,
		"il contatto ha REGALATO energia")
	assert(is_equal_approx(save_dopo.mastery_of(materia), mastery_before),
		"il contatto ha toccato la padronanza: una sacca non puo' farti disimparare")
	# Non blocca: Eli e' stata respinta, non fermata.
	assert(player.global_position.distance_to(before_contact) > 40.0,
		"dopo il morso Eli e' rimasta ferma invece di essere respinta")

	world.queue_free()
	await process_frame
	print("ELI/ENEMY audit OK — 20 frame direzionali, ostacoli per livello e impulso touch non punitivo")
	quit(0)
