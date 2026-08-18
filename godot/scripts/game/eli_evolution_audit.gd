extends SceneTree

const FACTORY := preload("res://scripts/visual_factory.gd")
const WORLD_LIGHT := preload("res://scripts/game/world_light.gd")
const OUTDOOR_WORLD := preload("res://scripts/outdoor_world.gd")
const EXPECTED_NAMES := [
	"Scintilla", "Lampada", "Faro", "Aurora", "Meridiana",
	"Solstizio", "Costellazione", "Galassia", "Prima Luce",
]
const SHEETS: Array[Texture2D] = [
	preload("res://assets/player/eli-scintilla-v1.png"),
	preload("res://assets/player/eli-lampada-v1.png"),
	preload("res://assets/player/eli-faro-v1.png"),
	preload("res://assets/player/eli-aurora-v1.png"),
	preload("res://assets/player/eli-meridiana-v1.png"),
	preload("res://assets/player/eli-grade5-v1.png"),
	preload("res://assets/player/eli-grade6-v1.png"),
	preload("res://assets/player/eli-grade7-v1.png"),
	preload("res://assets/player/eli-grade8-v1.png"),
]

func _init() -> void:
	assert(SHEETS.size() == 9, "Eli deve avere nove forme: base + otto gradi")
	assert(WORLD_LIGHT.SOGLIE.size() == SHEETS.size(),
		"contratto e resa devono avere gli stessi nove gradi")
	var actual_names: Array = WORLD_LIGHT.SOGLIE.map(func(entry): return str(entry.get("nome", "")))
	assert(actual_names == EXPECTED_NAMES,
		"le forme di Eli non seguono i nomi del contratto: %s" % str(actual_names))
	for tier in range(SHEETS.size()):
		var texture := SHEETS[tier]
		assert(texture != null, "spritesheet Eli mancante al grado %d" % tier)
		assert(texture.get_size() == Vector2(480, 384),
			"spritesheet Eli %d non conforme alla griglia 5x4: %s" % [tier, texture.get_size()])
		assert(FACTORY.player_sheet_for_tier(tier) == texture,
			"il loader non associa il grado %d alla sua tavola" % tier)
		var sprite := FACTORY.player_sprite(Vector2(84, 84), tier)
		assert(sprite.name == "EliSprite", "il controller non trovera' EliSprite")
		assert(sprite.texture is AtlasTexture, "l'animazione richiede AtlasTexture")
		assert((sprite.texture as AtlasTexture).region == Rect2(0, 0, 96, 96),
			"la cella di animazione deve restare 96x96")
	var base := FACTORY.build_player(Color("6be7d6"), 0)
	var finale := FACTORY.build_player(Color("fff0ae"), 8)
	assert(base.find_child("EliCoreGlow", true, false) != null, "nucleo energia assente")
	assert(finale.find_child("EliCoreGlow", true, false) != null, "nucleo finale assente")
	var marks := FACTORY.build_upgrade_marks([
		"nora-lens", "nora-reserve", "nora-shield", "nora-prismatic-core"])
	assert(marks.get_child_count() == 8, "i quattro potenziamenti devono avere segno e bagliore")
	base.free()
	finale.free()
	marks.free()
	_prova_orbite_del_contratto()
	print("ELI_EVOLUTION_AUDIT_OK: 9 forme nominate, griglia 5x4, 6 orbite")
	quit()

func _prova_orbite_del_contratto() -> void:
	var world := OUTDOOR_WORLD.new()
	var save := GameSaveManager.new()
	var controller := OutdoorPlayerController.new()
	var presentation := FACTORY.build_player(Color("e8fff4"), 0)
	controller.add_child(presentation)
	controller.visual = presentation.get_node("Visual")
	world.add_child(controller)
	world.set("player", controller)
	world.set("player_presentation", presentation)
	world.set("game_save", save)
	world.set("reduced_motion", true)

	# Prima Luce: tavola finale e tutte le orbite dichiarate dalla scena.
	save.data["powerRuns"] = int(WORLD_LIGHT.SOGLIE[8]["prove"])
	world.call("_applica_grado_al_personaggio", WORLD_LIGHT.grado(save))
	assert(int(world.get("applied_power_grade")) == 8, "Prima Luce non arriva alla scena")
	var sprite := controller.find_child("EliSprite", true, false) as Sprite2D
	assert(sprite != null and sprite.texture is AtlasTexture, "tavola finale assente dalla scena")
	assert((sprite.texture as AtlasTexture).atlas == SHEETS[8],
		"Prima Luce non usa lo spritesheet del grado 8")
	var orbit_names := [
		"PowerOrbitInner", "PowerOrbitOuter", "PowerOrbitZenith",
		"PowerOrbitCrown", "PowerOrbitPrism", "PowerOrbitHeart",
	]
	for orbit_name in orbit_names:
		var orbit := controller.get_node_or_null(orbit_name) as Line2D
		assert(orbit != null and orbit.visible, "%s non è visibile a Prima Luce" % orbit_name)
	var particles := controller.get_node_or_null("EliPowerParticles") as CPUParticles2D
	assert(particles != null and not particles.emitting,
		"movimento ridotto non spegne le particelle di Prima Luce")

	# Tornare a Meridiana deve spegnere le quattro orbite aggiunte da C-G3.
	save.data["powerRuns"] = int(WORLD_LIGHT.SOGLIE[4]["prove"])
	world.call("_applica_grado_al_personaggio", WORLD_LIGHT.grado(save))
	for orbit_name in orbit_names.slice(2):
		var orbit := controller.get_node_or_null(orbit_name) as Line2D
		assert(orbit != null and not orbit.visible,
			"%s resta visibile prima del proprio grado" % orbit_name)
	world.free()
