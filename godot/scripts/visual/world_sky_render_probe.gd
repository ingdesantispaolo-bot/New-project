extends SceneTree

## Guarda con gli occhi che cosa fanno l'orologio e i fuochi. (20 agosto 2026)
##
## Gli audit misurano numeri: la banda di luce di ogni mondo, la distanza fra i
## fuochi, il pavimento di leggibilità. Nessuno dei due sa dire se il tramonto è
## *bello* o se un fuoco acceso di notte si *vede*. Questa sonda produce le
## immagini per rispondere a occhio, che è l'unico modo.
##
## Non è un audit — il nome finisce per `_probe` apposta, quindi la suite non la
## esegue. Si lancia a mano quando si tocca la luce:
##
##   godot --headless --path godot --script scripts/visual/world_sky_render_probe.gd
##
## Le immagini finiscono in `artifacts/sky-*.png`.

const ORE := [
	{"id": "notte", "giro": 0.02},
	{"id": "alba", "giro": 0.16},
	{"id": "mezzogiorno", "giro": 0.50},
	{"id": "tramonto", "giro": 0.84},
]

## Quanti fuochi accendere per la coppia di immagini «prima e dopo».
const FUOCHI_ACCESI := 6

## Il mondo da fotografare. La Radura è quella che tutti riconoscono; si cambia
## dalla riga di comando, che serve soprattutto per i mondi notturni — è lì che
## il pavimento di leggibilità lavora davvero:
##
##   godot --headless=false --path godot --script .../world_sky_render_probe.gd -- 13
const LIVELLO_PREDEFINITO := 1

func _livello() -> int:
	for argomento in OS.get_cmdline_user_args():
		if str(argomento).is_valid_int():
			return clampi(int(str(argomento)), 1, WorldProfileCatalog.MAX_LEVEL)
	return LIVELLO_PREDEFINITO

func _initialize() -> void:
	var packed := load("res://scenes/outdoor_world.tscn") as PackedScene
	if packed == null:
		push_error("WORLD_SKY_PROBE: scena mondo assente")
		quit(1)
		return
	var scene := packed.instantiate()
	# La richiesta pilotata salta la soglia del mondo: senza, ogni scatto
	# ritrarrebbe il pannello «ENTRA» invece del mondo dietro.
	var initial := GameSaveManager._default_data()
	var livello := _livello()
	initial["level"] = livello
	initial["energy"] = 300
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("sky-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	scene.set("launch_request_override", request)
	root.add_child(scene)
	_giro_delle_ore.call_deferred(scene)

func _giro_delle_ore(scene: Node) -> void:
	var player: Node2D = scene.get("player")
	var camera: Camera2D = scene.get("camera")
	if player == null or camera == null:
		push_error("WORLD_SKY_PROBE: mondo non pronto")
		quit(2)
		return
	player.set_physics_process(false)
	camera.position_smoothing_enabled = false
	# Il mondo cammina da solo: per fotografare un'ora precisa bisogna prima
	# fermare l'orologio, o fra la posa e lo scatto è già passato altro tempo.
	scene.set("_il_cielo_cammina", false)

	var fuochi := get_nodes_in_group("fuoco_del_risveglio")
	print("WORLD_SKY_PROBE fuochi=%d" % fuochi.size())

	for ora in ORE:
		scene.set("day_clock", WorldSky.DURATA * float(ora["giro"]))
		for _frame in range(12):
			await process_frame
		_scatta("sky%d-%s-spento" % [_livello(), str(ora["id"])])

	# E adesso con il mondo a metà risveglio: sei fuochi accesi, gli altri no.
	# La coppia notte-spento / notte-acceso è quella che dice se il lavoro fatto
	# si vede davvero.
	var accesi := 0
	for nodo in fuochi:
		if accesi >= FUOCHI_ACCESI:
			break
		var fuoco := nodo as WorldAwakeningFire
		if is_instance_valid(fuoco):
			fuoco.accendi(false)
			accesi += 1
	for ora in ORE:
		scene.set("day_clock", WorldSky.DURATA * float(ora["giro"]))
		for _frame in range(12):
			await process_frame
		_scatta("sky%d-%s-acceso" % [_livello(), str(ora["id"])])

	print("WORLD_SKY_PROBE_OK %d immagini" % (ORE.size() * 2))
	quit(0)

func _scatta(nome: String) -> void:
	var texture := root.get_texture()
	if texture == null:
		push_error("WORLD_SKY_PROBE: viewport non disponibile")
		return
	var image := texture.get_image()
	if image == null:
		push_error("WORLD_SKY_PROBE: immagine non disponibile")
		return
	var assoluto := ProjectSettings.globalize_path("res://../artifacts/%s.png" % nome)
	DirAccess.make_dir_recursive_absolute(assoluto.get_base_dir())
	if image.save_png(assoluto) != OK:
		push_error("WORLD_SKY_PROBE: salvataggio fallito per %s" % nome)
		return
	print("WORLD_SKY_PROBE_CAPTURE %s" % nome)
