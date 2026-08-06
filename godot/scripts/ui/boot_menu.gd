extends Control

## Entrata nativa dell'applicazione. Questa scena possiede soltanto la UI di
## avvio: lo stato e il gameplay restano nei manager e in outdoor_world.tscn.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const BACKDROP := preload("res://assets/radura-accademia-hero-backdrop-v2.png")

var play_button: Button
var second_journey_button: Button
var second_journey_status: Label
var second_journey_bar: ProgressBar
var player_label: Label
var profile_panel: ProfilePanel

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.eliScene = 'boot';")
		_publish_saved_smoke_marker()
	_build_interface()
	play_button.grab_focus()

func _build_interface() -> void:
	var background := TextureRect.new()
	background.name = "Backdrop"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BACKDROP
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.015, 0.055, 0.075, 0.58)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "TitleCard"
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 34)
	content_margin.add_theme_constant_override("margin_top", 28)
	content_margin.add_theme_constant_override("margin_right", 34)
	content_margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(content_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	content_margin.add_child(column)

	var eyebrow := Label.new()
	eyebrow.text = "ACCADEMIA DELLE MISSIONI"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("8ff6d2"))
	eyebrow.add_theme_font_size_override("font_size", 14)
	column.add_child(eyebrow)

	var title := Label.new()
	title.name = "GameTitle"
	title.text = "ELI QUEST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f7fbff"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 46)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Esplora il mondo, completa le missioni\ne ripara la nave dell'Accademia."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("d4e7e9"))
	subtitle.add_theme_font_size_override("font_size", 17)
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	column.add_child(spacer)

	column.add_child(_build_player_row())

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "GIOCA"
	play_button.custom_minimum_size = Vector2(0, 58)
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color("07181d"))
	play_button.add_theme_color_override("font_hover_color", Color("07181d"))
	play_button.add_theme_color_override("font_focus_color", Color("07181d"))
	play_button.add_theme_stylebox_override("normal", _button_style(Color("6be7d6"), Color("b8fff0")))
	play_button.add_theme_stylebox_override("hover", _button_style(Color("8ff6d2"), Color.WHITE))
	play_button.add_theme_stylebox_override("pressed", _button_style(Color("49bcae"), Color("8ff6d2")))
	play_button.add_theme_stylebox_override("focus", _focus_style())
	play_button.pressed.connect(_play)
	column.add_child(play_button)

	var hint := Label.new()
	hint.name = "BootInputHint"
	hint.text = "Tocca GIOCA per iniziare"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("9fb7bb"))
	hint.add_theme_font_size_override("font_size", 13)
	column.add_child(hint)

	column.add_child(_build_second_journey_card())

## Chi sta per giocare, e come cambiarlo.
##
## La riga compare SEMPRE, anche quando il giocatore è uno solo: un bambino che
## non sa di poter avere una casella sua non la cercherà mai, e continuerà a
## giocare sopra la partita del fratello. Ma l'elenco dei profili viene creato
## solo quando qualcuno apre davvero il pannello — finché nessuno lo fa, il
## gioco resta sul salvataggio storico come ha sempre fatto.
func _build_player_row() -> Control:
	var riga := HBoxContainer.new()
	riga.name = "PlayerRow"
	riga.add_theme_constant_override("separation", 8)

	player_label = Label.new()
	player_label.name = "PlayerName"
	player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_label.add_theme_font_size_override("font_size", 15)
	player_label.add_theme_color_override("font_color", Color("d4e7e9"))
	riga.add_child(player_label)

	var cambia := Button.new()
	cambia.name = "ChangePlayerButton"
	cambia.text = "CAMBIA"
	cambia.custom_minimum_size = Vector2(0, 40)
	cambia.add_theme_font_size_override("font_size", 14)
	cambia.pressed.connect(_open_profiles)
	riga.add_child(cambia)

	_refresh_player_row()
	return riga

func _refresh_player_row() -> void:
	if not is_instance_valid(player_label):
		return
	var nome := "Giocatore 1"
	if PlayerProfiles.has_profiles():
		nome = str(PlayerProfiles.active().get("name", nome))
	player_label.text = "Giochi come: %s" % nome

func _open_profiles() -> void:
	if is_instance_valid(profile_panel):
		return
	profile_panel = ProfilePanel.new()
	profile_panel.name = "ProfilePanel"
	profile_panel.chosen.connect(_on_profile_chosen)
	add_child(profile_panel)

func _on_profile_chosen(_id: String) -> void:
	if is_instance_valid(profile_panel):
		profile_panel.queue_free()
		profile_panel = null
	_refresh_player_row()
	# Il Secondo Viaggio dipende dalla campagna di CHI gioca: cambiando bambino
	# la voce deve rileggere il suo salvataggio, non restare su quella di prima.
	_refresh_second_journey()
	play_button.grab_focus()

func _refresh_second_journey() -> void:
	if not is_instance_valid(second_journey_status) or not is_instance_valid(second_journey_button):
		return
	var progress := _campaign_progress()
	var unlocked := bool(progress.get("complete", false))
	var completed := int(progress.get("worldsCompleted", 0))
	var total := int(progress.get("worldsTotal", 24))
	second_journey_status.text = (
		"Rotta aperta" if unlocked else "Rotta chiusa · %d/%d" % [completed, total])
	second_journey_button.disabled = not unlocked
	second_journey_button.text = "ROTTA APERTA" if unlocked else "ROTTA CHIUSA"
	if is_instance_valid(second_journey_bar):
		second_journey_bar.max_value = float(maxi(total, 1))
		second_journey_bar.value = float(completed)

## Voce del Secondo Viaggio: presente e BLOCCATA dal primo avvio, con il
## contatore dei mondi completati.
##
## Mostrare il progresso invece di un lucchetto muto è deliberato: è un
## goal-gradient — si sa sempre quanto manca — e trasforma i 24 mondi in un
## percorso verso qualcosa invece che in una lista. Vedi docs/SECONDO_VIAGGIO.md §3.
##
## Lo stato non è calcolato qui: arriva da `ProgressionManager.campaign_progress()`.
func _build_second_journey_card() -> Control:
	var progress := _campaign_progress()
	var unlocked := bool(progress.get("complete", false))
	var completed := int(progress.get("worldsCompleted", 0))
	var total := int(progress.get("worldsTotal", 24))

	var card := PanelContainer.new()
	card.name = "SecondJourneyCard"
	card.add_theme_stylebox_override("panel", _card_style(unlocked))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var heading := Label.new()
	heading.name = "SecondJourneyTitle"
	heading.text = "IL SECONDO VIAGGIO"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override(
		"font_color", Color("ffd75e") if unlocked else Color("8ba3a7"))
	box.add_child(heading)

	second_journey_status = Label.new()
	second_journey_status.name = "SecondJourneyStatus"
	second_journey_status.text = (
		"Rotta aperta" if unlocked else "Rotta chiusa · %d/%d" % [completed, total])
	second_journey_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	second_journey_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	second_journey_status.add_theme_font_size_override("font_size", 13)
	second_journey_status.add_theme_color_override(
		"font_color", Color("ffe9a8") if unlocked else Color("9fb7bb"))
	box.add_child(second_journey_status)

	var bar := ProgressBar.new()
	second_journey_bar = bar
	bar.name = "SecondJourneyProgress"
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = float(maxi(total, 1))
	bar.value = float(completed)
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", _bar_style(Color(0.05, 0.13, 0.15, 0.92)))
	bar.add_theme_stylebox_override(
		"fill", _bar_style(Color("ffd75e") if unlocked else Color(0.42, 0.78, 0.72, 0.85)))
	box.add_child(bar)

	second_journey_button = Button.new()
	second_journey_button.name = "SecondJourneyButton"
	second_journey_button.custom_minimum_size = Vector2(0, 40)
	second_journey_button.add_theme_font_size_override("font_size", 15)
	# Bloccata finché la campagna non è completa. Non esiste percorso alternativo:
	# nessuna energia, nessun cosmetico e nessun modulo la aprono.
	second_journey_button.disabled = not unlocked
	second_journey_button.text = "ROTTA APERTA" if unlocked else "ROTTA CHIUSA"
	second_journey_button.tooltip_text = (
		"Le undici sorelle ti aspettano."
		if unlocked
		else "Ripara i %d apparati che restano per aprire la rotta." % maxi(total - completed, 0))
	second_journey_button.pressed.connect(_on_second_journey_pressed)
	box.add_child(second_journey_button)

	return card

## Segnaposto dichiarato: la modalità non esiste ancora (tappa 9). Meglio un
## messaggio onesto che un pulsante che porta a una scena vuota, e meglio un
## pulsante attivo che uno disabilitato a 24/24, che somiglierebbe a un difetto
## subito dopo la celebrazione del finale.
func _on_second_journey_pressed() -> void:
	if not is_instance_valid(second_journey_status):
		return
	second_journey_status.text = "Rotta aperta · in arrivo"

## Progresso della campagna letto dal salvataggio locale. Un save assente
## produce il profilo di default (livello 1 → 0/24), quindi la voce è sempre
## disegnabile anche al primissimo avvio.
func _campaign_progress() -> Dictionary:
	var save := GameSaveManager.new()
	save.load_save()
	return ProgressionManager.new(save).campaign_progress()

func _play() -> void:
	play_button.disabled = true
	play_button.text = "AVVIO…"
	# Segna che questa casella ha giocato adesso: serve all'elenco a mostrare per
	# prima quella usata di recente. Silenzioso se i profili non esistono ancora.
	if PlayerProfiles.has_profiles():
		PlayerProfiles.touch(PlayerProfiles.active_id())
	if NativeWorldState.release_smoke_enabled():
		_prepare_release_smoke_save()
	get_tree().change_scene_to_file(WORLD_SCENE)

func _prepare_release_smoke_save() -> void:
	# Fixture attivabile soltanto dagli argomenti dell'istanza di collaudo. La
	# build pubblicata continua ad avviare il profilo locale normale.
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	var content := ContentManager.new()
	var progression := ProgressionManager.new(save, content)
	var gate := progression.current_gate()
	var threshold := float(gate.get("masteryThreshold", 0.7))
	# Il gate del livello è il NUCLEO: la fixture deve soddisfare accuratezza e
	# copertura su tutte e tre le materie, non su quella del mondo. Più la materia
	# ospite, perché il collaudo apre anche l'esame dell'apparato.
	var prepared: Array = Array(ApparatusConfig.CORE_SUBJECTS).duplicate()
	var host := ApparatusConfig.world_subject(save.level())
	if not prepared.has(host):
		prepared.append(host)
	for subject_data in prepared:
		var subject := str(subject_data)
		save.add_mission(subject)
		save.set_mastery(subject, threshold)
		var topic_target := GateReadiness.coverage_target(content.subject_topic_count(subject))
		for index in range(maxi(topic_target, 1)):
			save.set_topic_mastery(subject, "release-smoke-topic-%d" % index, 1.0)
	save.data["accessibility"] = {
		"highContrast": true,
		"reducedMotion": true,
	}
	save.data["releaseSmokeMarker"] = "web-release-save-v1"
	save.save()
	var request := NativeWorldState.default_request("web-release-smoke")
	request["loadLocalSave"] = false
	request["initialSave"] = save.data.duplicate(true)
	request["worldLevel"] = 1
	request["accessibility"] = Dictionary(save.data["accessibility"]).duplicate(true)
	request["accessibilityExplicit"] = true
	NativeWorldState.stage_launch_request(request)

func _publish_saved_smoke_marker() -> void:
	if not NativeWorldState.release_smoke_enabled():
		return
	var save := GameSaveManager.new()
	save.load_save()
	JavaScriptBridge.eval(
		"document.documentElement.dataset.eliSaveMarker = %s;" %
		JSON.stringify(str(save.data.get("releaseSmokeMarker", "")))
	)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.075, 0.095, 0.94)
	style.border_color = Color(0.42, 0.91, 0.84, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 18
	return style

func _card_style(unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.10, 0.09, 0.03, 0.62) if unlocked else Color(0.02, 0.06, 0.07, 0.58))
	style.border_color = (
		Color(1.0, 0.84, 0.37, 0.72) if unlocked else Color(0.42, 0.60, 0.62, 0.34))
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style

func _bar_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(4)
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.expand_margin_left = 4
	style.expand_margin_top = 4
	style.expand_margin_right = 4
	style.expand_margin_bottom = 4
	return style
