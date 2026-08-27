extends SceneTree

## La bottega non disegna caratteri Unicode: ogni articolo passa dall'atlante
## illustrato. Questo cricchetto copre Web e tablet, dove il ripiego di sistema
## che in sviluppo mascherava i glifi mancanti non esiste.

const ATLAS_DATA := "res://assets/shop/reward-items-sheet.json"

## Gli scaffali che la bottega espone davvero. **Non sono tutto il catalogo**, e
## la differenza ha tenuto questo audit rosso.
##
## Lo slot `tool` — torcia e falce — non si compra: lo consegna il mondo, e
## `shop_presentation_audit` **vieta esplicitamente** a quei due di occupare
## l'atlante («gli strumenti consegnati dal mondo non devono occupare l'atlante
## della bottega»). Questo audit, che scandiva `RewardCatalog.CATALOG` per intero,
## pretendeva l'esatto contrario: i due si contraddicevano, e vinceva quello che
## girava per ultimo.
##
## La contraddizione e' emersa il 21 agosto, quando il modulo torcia e' stato
## ritirato e le sue illustrazioni tolte da `build-reward-assets.mjs`: da allora
## `glifi_audit` era rosso su `tool-torch` e nessuno dei due audit stava
## sbagliando sul contenuto — sbagliava questo sulla premessa. La regola vera e'
## «ogni articolo **esposto in bottega** ha la sua insegna», non «ogni riga del
## catalogo».
##
## Stessa lista di `shop_presentation_audit`: se un giorno si aggiunge uno slot,
## va aggiunto in tutti e due, e il disaccordo torna a essere visibile subito.
const SLOT_IN_VETRINA := ["bot", "avatar", "accessory", "module", "pet", "emblem", "upgrade", "decor"]

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_DATA))
	assert(typeof(parsed) == TYPE_DICTIONARY, "atlante bottega non leggibile")
	var frames: Dictionary = (parsed as Dictionary).get("frames", {})
	var esposti := 0
	for entry_data in RewardCatalog.CATALOG:
		var entry: Dictionary = entry_data
		if not str(entry.get("slot", "")) in SLOT_IN_VETRINA:
			continue
		esposti += 1
		var item_id := str(entry.get("id", ""))
		assert(frames.has(item_id), "articolo senza insegna illustrata: %s" % item_id)
	# Se un giorno la lista degli slot si svuotasse per un refuso, l'audit
	# resterebbe verde senza guardare niente. Meglio che si accorga di se stesso.
	assert(esposti > 20, "solo %d articoli esposti controllati: la lista degli slot non torna" % esposti)
	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/outdoor_shop_panel.gd")
	assert(not panel_source.contains("return _tool_fallback_texture"),
		"la bottega non deve ricadere sul glifo di sistema")
	# **E nessuna stringa mostrata usa un carattere che il font non ha.**
	# (21 agosto 2026)
	#
	# La bottega era il caso piu' vistoso ma non l'unico: c'erano 232
	# occorrenze di sessanta simboli in giro per il codice, e le peggiori
	# stavano nei posti che si vedono sempre — la freccia della catena del
	# duello, i pallini della tenuta, la freccia di cancellazione del
	# tastierino numerico, la bussola a otto direzioni.
	#
	# Su Windows non si vedeva niente: Godot ripiega sui font di sistema. Nel
	# Web e su tablet quel ripiego non esiste, e resta il rettangolo col codice
	# esadecimale dentro. Il difetto e' invisibile **esattamente sulla macchina
	# di chi scrive il codice**, ed e' per questo che serve un audit e non
	# l'attenzione.
	#
	# Si guardano solo i letterali fra virgolette: un simbolo in un commento
	# non finisce sullo schermo, e vietarlo sarebbe una regola di stile.
	var font := ThemeDB.fallback_font
	var rotte: Array[String] = []
	_scandaglia("res://scripts", font, rotte)
	for riga in rotte:
		printerr("  carattere senza glifo: %s" % riga)
	assert(rotte.is_empty(),
		"%d stringhe usano un carattere che il font imbarcato non ha" % rotte.size())
	print("GLIFI audit OK - %d articoli dall'atlante, e nessuna stringa mostrata senza glifo" % RewardCatalog.CATALOG.size())
	quit(0)

## Percorre gli script e raccoglie i letterali che chiedono un glifo assente.
##
## Gli audit e le sonde restano fuori: stampano su console, dove il font non
## c'entra, e sono l'unico posto in cui un simbolo serve a leggere una tabella.
func _scandaglia(percorso: String, font: Font, fuori: Array[String]) -> void:
	var d := DirAccess.open(percorso)
	if d == null:
		return
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		var pieno := "%s/%s" % [percorso, nome]
		if d.current_is_dir():
			_scandaglia(pieno, font, fuori)
		elif nome.ends_with(".gd") and not nome.ends_with("_audit.gd") 				and not nome.ends_with("_probe.gd"):
			_leggi_file(pieno, nome, font, fuori)
		nome = d.get_next()
	d.list_dir_end()

func _leggi_file(pieno: String, nome: String, font: Font, fuori: Array[String]) -> void:
	var testo := FileAccess.get_file_as_string(pieno)
	var numero := 0
	for riga in testo.split("
"):
		numero += 1
		if riga.strip_edges().begins_with("#"):
			continue
		var dentro := false
		for i in riga.length():
			var code := riga.unicode_at(i)
			if code == 34:  # virgolette doppie
				dentro = not dentro
				continue
			if dentro and code > 0x7F and not font.has_char(code):
				fuori.append("%s:%d U+%04X" % [nome, numero, code])
