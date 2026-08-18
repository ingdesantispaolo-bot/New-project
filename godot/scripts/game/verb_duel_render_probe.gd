extends SceneTree

## Sonda visuale del duello delle voci. Salva viste reali in `artifacts/voci/`
## per giudicare composizione e leggibilità con gli occhi invece che a parole.
##
## Qui serve più che altrove: i tre binari degli assi sono nati dopo aver provato
## la tabella modi × tempi e aver visto che a nove tempi le intestazioni
## scendevano a corpo dieci. Una decisione così non si prende ragionando, si
## prende guardando.
##
## Le viste: il primo mondo (un modo solo, tre tempi, bersaglio a etichetta),
## l'ultimo (tre modi, nove tempi che vanno a capo, bersaglio da riconoscere), lo
## scambio a metà con la catena scritta e le rune consumate, il momento in cui il
## sigillo si spezza, la parata, e la resa ad alto contrasto.
##
## Uso: godot --path godot --script res://scripts/game/verb_duel_render_probe.gd

const OUTPUT_DIR := "res://../artifacts/voci"

var pannello: VerbDuelPanel
var _host: Control

func _init() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var host := Control.new()
	host.name = "VerbDuelRenderHost"
	host.size = root.get_visible_rect().size
	root.add_child(host)
	var sfondo := ColorRect.new()
	sfondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sfondo.color = Color("101c26")
	host.add_child(sfondo)
	_host = host
	await process_frame

	# 1 · Mondo 1: un modo solo, tre tempi, il bersaglio scritto a parole.
	await _avvia(1, 2, 1, 20260817, false, false)
	if await _capture("voci-mondo-01.png") != OK:
		push_error("VERB RENDER: renderer grafico non disponibile")
		quit(2)
		return

	# 2 · Mondo 24: tre modi, nove tempi che vanno a capo, e il sigillo che
	# mostra una voce vera di un altro verbo. È la vista che dice se regge.
	await _avvia(24, 8, 8, 777, false, false)
	if await _capture("voci-mondo-24.png") != OK:
		quit(2)
		return

	# 3 · Mondo 12, a metà scambio: un colpo dato, la catena che comincia a
	# scriversi, una runa consumata e i tempi che si spengono.
	await _avvia(12, 4, 3, 4242, false, false)
	var strada: Array = pannello.sequenza_vincente()
	if not strada.is_empty():
		pannello.colpisci(int(strada[0]))
	await _settle()
	if await _capture("voci-in-corso.png") != OK:
		quit(2)
		return

	# 4 · Il sigillo che si spezza.
	await _avvia(12, 4, 3, 909, false, false)
	for passo in pannello.sequenza_vincente():
		pannello.colpisci(int(passo))
	await process_frame
	await process_frame
	if await _capture("voci-sigillo-rotto.png") != OK:
		quit(2)
		return

	# 5 · La parata.
	await _avvia(18, 6, 4, 313, false, false)
	pannello.call("incassa")
	await process_frame
	await process_frame
	if await _capture("voci-parata.png") != OK:
		quit(2)
		return

	# 6 · Alto contrasto e movimento ridotto.
	await _avvia(15, 4, 3, 4242, true, true)
	if await _capture("voci-contrasto.png") != OK:
		quit(2)
		return

	print("VERB DUEL RENDER probe OK - artifacts/voci")
	quit(0)

## Ogni vista nasce su un pannello nuovo, come nel gioco: il mondo ne crea uno
## per sfida e lo butta.
func _avvia(mondo: int, tier: int, grado: int, seme: int, ridotto: bool, contrasto: bool) -> void:
	if is_instance_valid(pannello):
		pannello.queue_free()
	pannello = VerbDuelPanel.new()
	_host.add_child(pannello)
	pannello.avvia(VerbDuel.regole(mondo, tier, grado, ridotto),
		GuardianVisualCatalog.name_for(mondo), seme, ridotto, contrasto)
	# L'ingresso del pannello è una dissolvenza: catturare prima che finisca
	# fotograferebbe un duello semitrasparente.
	await create_timer(0.26).timeout

func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.14).timeout

func _capture(file_name: String) -> Error:
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		return ERR_UNAVAILABLE
	return image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name]))
