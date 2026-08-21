class_name ObjectivePanel
extends Control

## **Il quadro degli obiettivi**: che cosa fare adesso, e quanto manca al mondo
## successivo. (7 agosto 2026)
##
## Due parti, nell'ordine in cui servono. In alto **una cosa sola da fare**,
## grande, con scritto dove farla. Sotto l'elenco delle dodici materie ordinate
## dalla più vicina, con la spunta su quelle chiuse.
##
## **Perché l'elenco sta sotto e non sopra.** Chi apre questo pannello quasi
## sempre sta chiedendo «e adesso?», non «quanto manca in tutto»: la risposta
## breve va dove cade l'occhio. L'elenco lungo serve la seconda volta che si
## apre, ed è giusto che costi uno sguardo in più.
##
## **Perché le materie chiuse restano nell'elenco.** Toglierle sarebbe più
## pulito e sbagliato: vedere quello che si è già fatto è metà della
## motivazione, e un elenco che si accorcia da solo nasconde i progressi.
##
## ## PORTAMI (21 agosto 2026)
##
## Questo quadro diceva già che cosa manca a ciascuna materia, e poi lasciava
## il bambino a cercarla camminando: la scelta di che cosa allenare si prendeva
## leggendo le etichette dei punti uno per uno, cioè non si prendeva. Adesso
## ogni materia aperta ha il suo **PORTAMI**, che chiude il quadro e punta la
## bussola alla sua stazione.
##
## È il pezzo che mancava al filo delle palestre: il filo risolve il **dove**,
## questo pulsante risolve il **come ci arrivo**.

signal chiuso
## La materia che il bambino ha scelto di allenare adesso. La scena la
## trasforma in una rotta verso la sua stazione del filo.
signal portami(materia: String)

const VERDE := Color("8ff6d2")
const ORO := Color("f4cf69")
const SPENTO := Color("9fb7bb")

var _colonna: VBoxContainer

func apri(passo: Dictionary, percorso: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_costruisci(passo, percorso)

func _costruisci(passo: Dictionary, percorso: Dictionary) -> void:
	var velo := ColorRect.new()
	velo.name = "ObjectiveVeil"
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.008, 0.03, 0.04, 0.94)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	var pannello := PanelContainer.new()
	pannello.name = "ObjectiveCard"
	pannello.anchor_left = 0.06
	pannello.anchor_top = 0.05
	pannello.anchor_right = 0.94
	pannello.anchor_bottom = 0.95
	add_child(pannello)

	var scorri := ScrollContainer.new()
	scorri.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pannello.add_child(scorri)

	_colonna = VBoxContainer.new()
	_colonna.name = "ObjectiveColumn"
	_colonna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_colonna.add_theme_constant_override("separation", 12)
	scorri.add_child(_colonna)

	# ------------------------------------------------- che cosa fare adesso
	_riga("ADESSO", 13, Color("6be7d6"))
	_riga(str(passo.get("titolo", "")), 24, ORO)
	_riga(str(passo.get("azione", "")), 17, Color("e7fffb"))
	var dove := str(passo.get("dove", "")).strip_edges()
	if not dove.is_empty():
		_riga("Dove: %s" % dove, 15, VERDE)

	_separatore()

	# ------------------------------------------------- il mondo successivo
	_riga("PER IL MONDO SUCCESSIVO", 13, Color("6be7d6"))
	_riga(ObjectiveBriefing.riassunto(percorso), 16, Color("e7fffb"))
	_riga(str(percorso.get("dove", "")), 14, VERDE)

	for riga_dati in Array(percorso.get("righe", [])):
		var riga: Dictionary = riga_dati
		_materia(riga)

	var chiudi := Button.new()
	chiudi.name = "ObjectiveCloseButton"
	chiudi.text = "HO CAPITO"
	chiudi.custom_minimum_size = Vector2(0, 56)
	chiudi.add_theme_font_size_override("font_size", 18)
	chiudi.pressed.connect(func(): chiuso.emit())
	_colonna.add_child(chiudi)
	chiudi.call_deferred("grab_focus")

## Una materia dell'elenco: spunta, nome, e che cosa manca in numeri.
func _materia(riga: Dictionary) -> void:
	var fatto := bool(riga.get("fatto", false))
	var nome := str(riga.get("materia", "")).capitalize()
	var blocco := VBoxContainer.new()
	blocco.name = "Subject_%s" % str(riga.get("materia", ""))
	blocco.add_theme_constant_override("separation", 2)
	var testa := Label.new()
	# Il nucleo è segnato perché la sua asticella è più alta: se non si dice, un
	# bambino legge «italiano più indietro di storia» come una sua mancanza,
	# mentre è il gioco che chiede di più.
	testa.text = "%s %s%s" % [
		"OK" if fatto else "·", nome, "  ·  asticella più alta" if bool(riga.get("nucleo", false)) else ""]
	testa.add_theme_font_size_override("font_size", 16)
	testa.add_theme_color_override("font_color", VERDE if fatto else ORO)
	blocco.add_child(testa)
	if not fatto:
		var manca := Label.new()
		manca.text = "   %s" % str(riga.get("manca", ""))
		manca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		manca.add_theme_font_size_override("font_size", 14)
		manca.add_theme_color_override("font_color", SPENTO)
		blocco.add_child(manca)
		var portami_bottone := Button.new()
		portami_bottone.name = "Portami_%s" % str(riga.get("materia", ""))
		portami_bottone.text = "PORTAMI"
		portami_bottone.custom_minimum_size = Vector2(0, 44)
		portami_bottone.add_theme_font_size_override("font_size", 13)
		portami_bottone.pressed.connect(_chiedi_rotta.bind(str(riga.get("materia", ""))))
		blocco.add_child(portami_bottone)
	var barra := ProgressBar.new()
	barra.name = "Progress_%s" % str(riga.get("materia", ""))
	barra.custom_minimum_size = Vector2(0, 8)
	barra.show_percentage = false
	barra.max_value = 1.0
	barra.value = 1.0 if fatto else float(riga.get("progresso", 0.0))
	blocco.add_child(barra)
	_colonna.add_child(blocco)

func _chiedi_rotta(materia: String) -> void:
	portami.emit(materia)

func _riga(testo: String, dimensione: int, colore: Color) -> void:
	if testo.strip_edges().is_empty():
		return
	var etichetta := Label.new()
	etichetta.text = testo
	etichetta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etichetta.add_theme_font_size_override("font_size", dimensione)
	etichetta.add_theme_color_override("font_color", colore)
	_colonna.add_child(etichetta)

func _separatore() -> void:
	var linea := HSeparator.new()
	linea.custom_minimum_size = Vector2(0, 10)
	_colonna.add_child(linea)
