class_name WorldIntroPanel
extends Control

## **La soglia di un mondo**: la schermata che accoglie chi arriva.
##
## Nasce da una richiesta del committente — «una schermata di benvenuto in ogni
## nuovo mondo che guidi lo studente e lo immerga nella trama» — e da un difetto
## trovato preparandola, che è il terzo della stessa specie in questo progetto.
##
## **Il briefing aveva una casa sbagliata.** Per tutti e ventiquattro i mondi
## esiste un `briefing` di NORA scritto su misura, verificato da due audit. Non
## era inutilizzato — finiva nella riga di feedback dell'HUD all'ingresso — ma
## quella riga è la stessa in cui compaiono i costi d'energia, gli avvisi di
## sistema e le reazioni alle prove: un paragrafo didattico di due righe, in
## quella posizione, viene sostituito dal primo messaggio successivo e nessuno lo
## legge. Qui ha lo spazio che gli serve.
##
## (`debrief`, il testo di chiusura di un mondo, resta invece senza lettore: è un
## lotto suo, perché appartiene all'uscita e non all'ingresso.)
##
## **Che cosa mostra, e in quest'ordine.** L'ordine non è estetico: risponde alle
## tre domande che un bambino si fa varcando una soglia, nell'ordine in cui se le
## fa.
##
##   DOVE SONO      il nome del mondo e la voce di NORA sulla trama (il beat del
##                  livello): l'immersione viene prima, o il resto è un compito;
##   COSA IMPARO    il briefing e gli obiettivi della lezione: la guida vera,
##                  detta con parole di contenuto e non di punteggio;
##   COSA MI APRE   che cosa serve per andare avanti, detto senza numeri: le
##                  dodici materie a questo grado, e l'apparato del mondo.
##
## **Si vede una volta per mondo.** Riproporla a ogni rientro la trasformerebbe
## in una porta da chiudere, e una cosa che si impara a chiudere non si legge
## più. Resta riapribile dal mondo per chi vuole rileggerla.

signal chiusa

const ALTEZZA_TOCCO := 52
const CHAPTER_ART := preload("res://scripts/visual/chapter_art.gd")

var livello := 1
var strumento_dovuto := ""
var _colonna: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var velo := ColorRect.new()
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.01, 0.045, 0.06, 0.93)
	add_child(velo)

	var margine := MarginContainer.new()
	margine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 22)
	add_child(margine)

	var scorri := ScrollContainer.new()
	scorri.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margine.add_child(scorri)

	_colonna = VBoxContainer.new()
	_colonna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_colonna.add_theme_constant_override("separation", 10)
	scorri.add_child(_colonna)

	_disegna()

func _disegna() -> void:
	var lvl := clampi(livello, 1, ApparatusConfig.MAX_LEVEL)
	var lezione := WorldLessonCatalog.lesson(lvl)
	var materia := str(lezione.get("subject", ApparatusConfig.world_subject(lvl)))

	# --- Dove sono -----------------------------------------------------------
	var occhiello := Label.new()
	occhiello.text = "MONDO %d" % lvl
	occhiello.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	occhiello.add_theme_font_size_override("font_size", 13)
	occhiello.add_theme_color_override("font_color", Color("8ff6d2"))
	_colonna.add_child(occhiello)

	var titolo := Label.new()
	titolo.name = "WorldTitle"
	titolo.text = titolo_mondo(lvl).to_upper()
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titolo.add_theme_font_size_override("font_size", 34)
	titolo.add_theme_color_override("font_color", Color("f7fbff"))
	_colonna.add_child(titolo)

	# Sei tavole, una per arco di quattro mondi. Sono soltanto atmosfera: titolo,
	# contenuto e accessibilita' restano testo reale sotto l'immagine.
	var chapter_texture := CHAPTER_ART.texture_for_world(lvl)
	if chapter_texture != null:
		var tavola := TextureRect.new()
		tavola.name = "ChapterArt"
		tavola.texture = chapter_texture
		tavola.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tavola.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tavola.custom_minimum_size = Vector2(0, 220)
		tavola.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tavola.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_colonna.add_child(tavola)

	# Il beat di trama: NORA parla del punto in cui è l'indagine, non della
	# lezione. È la parte che immerge, e viene per prima di proposito — un
	# bambino che arriva in un posto nuovo vuole sapere dov'è, non cosa deve
	# fare.
	var beat := str(NarrativeManager.BEATS.get(lvl, ""))
	if beat != "":
		_colonna.add_child(_riquadro(beat.replace("NORA: ", ""), Color("d7f7ee"), 16, "NORA"))

	# --- Cosa imparo ---------------------------------------------------------
	_colonna.add_child(_sezione("QUI SI IMPARA · %s" % materia.to_upper()))
	var briefing := WorldLessonCatalog.briefing(lvl)
	if briefing != "":
		_colonna.add_child(_paragrafo(briefing, Color("e7f2f0"), 15))

	for obiettivo in Array(lezione.get("objectives", [])).slice(0, 3):
		_colonna.add_child(_voce("»  %s" % str(obiettivo)))

	var prerequisiti: Array = Array(lezione.get("prerequisites", []))
	if not prerequisiti.is_empty():
		# I prerequisiti si dicono, e si dicono qui: un bambino che scopre a metà
		# mondo che gli manca una base arriva a quella scoperta dopo aver
		# sbagliato, che è il modo peggiore di scoprirlo.
		_colonna.add_child(_nota("Ti servirà già: %s" % ", ".join(
			PackedStringArray(prerequisiti.slice(0, 2)))))

	# --- Come funzionano i lavori -------------------------------------------
	# Al mondo 2 il numero delle cose visibili cresce e, senza questa cerniera,
	# sembra che il gioco abbia cambiato regole durante il viaggio.
	_colonna.add_child(_sezione("COME FUNZIONANO I LAVORI"))
	_colonna.add_child(_paragrafo(
		"1. Scegli una missione indicata sulla mappa.  2. Completa le prove del luogo.  3. Riapri «CHE COSA DEVO FARE?» per vedere il prossimo passo e quante prove restano. I lavori già conclusi restano salvati.",
		Color("e7f2f0"), 14))
	if not strumento_dovuto.is_empty():
		_colonna.add_child(_riquadro(
			"In questo mondo riceverai %s completando la prima riparazione. Non cercarla nella bottega: lì trovi soltanto la scheda che indica dove ottenerla." % FieldTools.nome(strumento_dovuto),
			Color("ffe6a3"), 14, "STRUMENTO"))

	# --- Cosa mi apre --------------------------------------------------------
	_colonna.add_child(_sezione("COSA APRE LA STRADA"))
	_colonna.add_child(_paragrafo(
		"L'apparato di %s si ripara superando l'esame di questo mondo: accende una stanza della nave." % materia,
		Color("cfe6e2"), 14))
	_colonna.add_child(_paragrafo(
		"Per salire di livello servono invece TUTTE e dodici le materie a questo grado di difficoltà. Le altre si allenano nelle palestre sparse nel mondo — e italiano, matematica e inglese chiedono di più delle altre.",
		Color("cfe6e2"), 14))

	var chiudi := Button.new()
	chiudi.name = "StartButton"
	chiudi.text = "ENTRA"
	chiudi.custom_minimum_size = Vector2(0, ALTEZZA_TOCCO)
	chiudi.add_theme_font_size_override("font_size", 20)
	chiudi.pressed.connect(func(): chiusa.emit())
	_colonna.add_child(chiudi)

## Il nome del mondo dal profilo visivo. Se manca — non dovrebbe — si ripiega
## sulla materia, che è sempre nota: meglio «Mondo di matematica» che una
## schermata con un titolo vuoto.
static func titolo_mondo(lvl: int) -> String:
	for voce in WorldProfileCatalog.IDENTITIES:
		var p: Dictionary = voce
		if str(p.get("id", "")).begins_with("world-%02d" % lvl):
			return str(p.get("title", ""))
	return "Mondo di %s" % ApparatusConfig.world_subject(lvl)

# ---------------------------------------------------------------- mattoni

func _sezione(testo: String) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color("8ff6d2"))
	return l

func _paragrafo(testo: String, colore: Color, dim: int) -> Label:
	var l := Label.new()
	l.text = testo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", colore)
	return l

func _voce(testo: String) -> Label:
	return _paragrafo(testo, Color("f2f8f6"), 15)

func _nota(testo: String) -> Label:
	return _paragrafo(testo, Color("9fb7bb"), 13)

func _riquadro(testo: String, colore: Color, dim: int, chi: String) -> Control:
	var pannello := PanelContainer.new()
	var stile := StyleBoxFlat.new()
	stile.bg_color = Color(0.03, 0.11, 0.13, 0.85)
	stile.border_color = Color(0.42, 0.91, 0.84, 0.55)
	stile.set_border_width_all(1)
	stile.set_corner_radius_all(12)
	pannello.add_theme_stylebox_override("panel", stile)

	var margine := MarginContainer.new()
	for lato in ["left", "top", "right", "bottom"]:
		margine.add_theme_constant_override("margin_%s" % lato, 14)
	pannello.add_child(margine)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margine.add_child(box)
	box.add_child(_sezione(chi))
	box.add_child(_paragrafo(testo, colore, dim))
	return pannello
