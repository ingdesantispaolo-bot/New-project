extends SceneTree

## Sonda visuale del duello. Salva viste reali in `artifacts/duello/` per
## giudicare composizione e leggibilità con gli occhi invece che a parole: un
## combattimento si valuta guardandolo, e la corda di risonanza è nata proprio
## perché il numero da raggiungere, scritto e basta, non diceva *quanto manca*.
##
## Cattura le situazioni che contano: il primo mondo (quattro rune, catena da due
## colpi), l'ultimo (sei rune, divisioni in mano), lo scambio già cominciato con
## rune consumate e rune spente, il momento in cui un sigillo si spezza, la
## parata del guardiano, e la resa ad alto contrasto.
##
## Uso: godot --path godot --script res://scripts/game/guardian_duel_render_probe.gd

const OUTPUT_DIR := "res://../artifacts/duello"

var pannello: GuardianDuelPanel
var _host: Control

func _init() -> void:
	root.size = Vector2i(1100, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var host := Control.new()
	host.name = "DuelRenderHost"
	host.size = root.get_visible_rect().size
	root.add_child(host)
	var sfondo := ColorRect.new()
	sfondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sfondo.color = Color("101c26")
	host.add_child(sfondo)

	_host = host
	await process_frame

	# 1 · Mondo 1: quattro rune, catena da due colpi, guardiano del primo mondo.
	await _avvia(1, 2, 1, 20260816, false, false)
	await _settle()
	if await _capture("duello-mondo-01.png") != OK:
		push_error("DUEL RENDER: renderer grafico non disponibile")
		quit(2)
		return

	# 2 · Mondo 24: sei rune, divisioni, il campo più affollato che il gioco
	# produce. È la vista che dice se la composizione regge.
	await _avvia(24, 8, 8, 777, false, false)
	await _settle()
	if await _capture("duello-mondo-24.png") != OK:
		quit(2)
		return

	# 3 · A metà scambio: un colpo dato, una runa consumata, l'ago spostato.
	await _avvia(12, 4, 3, 4242, false, false)
	await process_frame
	var strada: Array = pannello.sequenza_vincente()
	if not strada.is_empty():
		pannello.colpisci(int(strada[0]))
	await _settle()
	if await _capture("duello-in-corso.png") != OK:
		quit(2)
		return

	# 4 · Il sigillo che si spezza: il fotogramma della vittoria parziale.
	await _avvia(12, 4, 3, 909, false, false)
	await process_frame
	for passo in pannello.sequenza_vincente():
		pannello.colpisci(int(passo))
	await process_frame
	await process_frame
	if await _capture("duello-sigillo-rotto.png") != OK:
		quit(2)
		return

	# 5 · La parata: il guardiano incassa il tempo e colpisce.
	await _avvia(18, 6, 4, 313, false, false)
	await process_frame
	pannello.call("_incassa")
	await process_frame
	await process_frame
	if await _capture("duello-parata.png") != OK:
		quit(2)
		return

	# 6 · Alto contrasto e movimento ridotto: lo stesso duello, l'altra resa.
	await _avvia(12, 4, 3, 4242, true, true)
	await _settle()
	if await _capture("duello-contrasto.png") != OK:
		quit(2)
		return

	print("GUARDIAN DUEL RENDER probe OK - artifacts/duello")
	quit(0)

## Ogni vista nasce su un pannello nuovo, come nel gioco: il mondo ne crea uno
## per sfida e lo butta. Riusare lo stesso oggetto misurerebbe uno stato che
## nessun bambino incontra mai.
func _avvia(mondo: int, tier: int, grado: int, seme: int, ridotto: bool, contrasto: bool) -> void:
	if is_instance_valid(pannello):
		pannello.queue_free()
	pannello = GuardianDuelPanel.new()
	_host.add_child(pannello)
	pannello.avvia(GuardianDuel.regole(mondo, tier, grado, ridotto),
		GuardianVisualCatalog.name_for(mondo), seme, ridotto, contrasto)
	# L'ingresso del pannello è una dissolvenza: catturare prima che finisca
	# fotograferebbe un duello semitrasparente e direbbe il falso sui colori.
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
