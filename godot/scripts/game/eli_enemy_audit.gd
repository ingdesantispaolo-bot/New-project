extends SceneTree

const WORLD_SCENE := preload("res://scenes/outdoor_world.tscn")
const PLAYER := preload("res://scripts/player_controller.gd")

## C-P6 #7/#8: Eli usa le 4 direzioni del foglio a 20 frame; le anomalie
## ostacolano senza sottrarre progresso e la corsa è disponibile su tablet.

func _init() -> void:
	call_deferred("_run")

func _assert_role_silhouettes() -> void:
	var patrol := WorldEnemy.new()
	patrol.setup(null, Vector2.ZERO, 7, "matematica", Color("ff7b72"), 0)
	var guardian := WorldEnemy.new()
	guardian.setup(null, Vector2.ZERO, 7, "matematica", Color("ff7b72"), 1)
	guardian.sorveglia("audit-treasure")
	# La pattuglia sfidabile: dal 24 agosto 2026 e' la seconda popolazione, e deve
	# restare distinguibile dalla guardiana a colpo d'occhio — chi legge il
	# cartiglio deve sapere se li' c'e' un forziere da liberare o soltanto una
	# sacca da togliere di mezzo.
	patrol.pattuglia_sfidabile("audit-pattuglia")
	var seen: Array = []
	var accessible_names: Array = []
	for enemy in [patrol, guardian]:
		var marker := str(enemy.get_meta("roleVisualMarker", ""))
		assert(marker != "" and not seen.has(marker),
			"ogni ruolo del Silenzio deve avere una sagoma distinta")
		assert(bool(enemy.get_meta("roleVisualDistinct", false)),
			"marcatore visuale di ruolo mancante")
		var label := enemy.get_node_or_null("EnemyLabel") as Label
		assert(label != null and not label.accessibility_name.is_empty(),
			"ruolo senza nome accessibile")
		assert(not accessible_names.has(label.accessibility_name),
			"due ruoli del Silenzio hanno lo stesso nome accessibile")
		seen.append(marker)
		accessible_names.append(label.accessibility_name)
		enemy.queue_free()

func _run() -> void:
	_assert_role_silhouettes()
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
	for sacca in tutte:
		match str(sacca.get("ruolo")):
			WorldEnemy.RUOLO_GUARDIANO: guardiani.append(sacca)
			_: enemies.append(sacca)
	assert(enemies.size() == 2, "il mondo 7 deve scalare a due anomalie in pattuglia, trovate %d" % enemies.size())
	# Una guardiana senza forziere sarebbe una sacca piazzata a caso con
	# un'etichetta diversa: il legame col premio e' tutto il senso della cosa.
	for guardia in guardiani:
		assert(not str(guardia.get("treasure_id")).is_empty(),
			"guardiano senza forziere da sorvegliare")
		assert(guardia.find_child("EnemyChallenge", true, false) != null,
			"guardiano che non si puo' affrontare: si potrebbe solo subire")
	# **Nessuna sacca senza gesto.** (24 agosto 2026) E' la riga che chiude la
	# segnalazione da cui nasce questo lotto: le sacche che il bambino incontrava
	# davvero erano proprio quelle che non si potevano affrontare. Adesso
	# qualunque cosa stia in `world_enemy` si sfida, e se un giorno ne comparisse
	# una senza `EnemyChallenge` questo audit lo direbbe prima di lui.
	for enemy in enemies:
		assert(enemy.find_child("EnemyChallenge", true, false) != null,
			"pattuglia che non si puo' affrontare: si potrebbe solo subire")
		assert(not str(enemy.get_meta("guardId", "")).is_empty(),
			"pattuglia senza identificativo: il cartiglio non sa che materia annunciare")
	for enemy in enemies:
		assert(str(enemy.get("enemy_name")).begins_with("Sbiadito"),
			"sentinella legacy non rinominata: %s" % str(enemy.get("enemy_name")))
		assert(str(enemy.get_meta("nature", "")) == "sacca_di_silenzio",
			"Sbiadito senza natura narrativa")
		assert(enemy.find_child("FadedGlyphGlow", true, false) != null,
			"Sbiadito senza iscrizione illeggibile")
		assert(enemy.find_children("BrokenInscription_*", "Line2D", true, false).size() == 3,
			"iscrizione spezzata non riconoscibile per forma")
	# **Il comando touch che deve esserci e' la corsa.** (21 agosto 2026)
	# L'impulso e' stato tolto: `impulso_scatto_probe` ha misurato che dal
	# mondo 2 in poi nessuna sacca costa energia, quindi non c'era piu' niente
	# da comprare con una carica. Questo pulsante invece lavora sempre: su
	# tablet e' l'unica corsa che esista.
	var corsa := world.find_child("ScattoButton", true, false) as Button
	assert(corsa != null and corsa.custom_minimum_size.x >= 64.0 and corsa.custom_minimum_size.y >= 64.0, "corsa touch insufficiente")
	assert(str(corsa.text).begins_with("CORRI"), "il comando touch non dice per primo il verbo che si usa sempre")

	var player: CharacterBody2D = world.get("player")
	var first: Node2D = enemies[0]
	first.global_position = player.global_position + Vector2(54, 0)
	first.set("anchor", first.global_position)
	var second: Node2D = enemies[1]
	second.global_position = player.global_position - Vector2(28, 0)
	var before_contact := player.global_position
	var save_prima: GameSaveManager = world.get("game_save")
	var energy_before := int(save_prima.energy())
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
	print("ELI/ENEMY audit OK — 20 frame direzionali, ostacoli per livello e corsa touch non punitiva")
	quit(0)
