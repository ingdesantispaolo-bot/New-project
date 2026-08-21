extends SceneTree

## **Quanti simboli il gioco disegna con un carattere che non possiede.**
## (21 agosto 2026)
##
## Nasce da una segnalazione di gioco: *«gli ingressi sono icone sparse a caso,
## anche brutte, con 2605 come logo»*. `2605` non è un logo: è il **codice
## esadecimale di ★** (U+2605), e il rettangolo col codice dentro è quello che
## Godot disegna quando il font non ha il glifo che gli è stato chiesto.
##
## ## Perché su Windows non si vede
##
## Il progetto non imbarca nessun font: usa `Open Sans SemiBold`, quello di
## ripiego del motore, che di simboli ne ha pochissimi. Su Windows Godot ripiega
## sui font di sistema — Segoe UI Symbol, Segoe UI Emoji — e la stella compare.
## **Nel Web e su tablet quel ripiego non esiste**, e resta il rettangolo. Ecco
## perché ogni cattura fatta qui è sempre stata pulita e il bambino vedeva 2605:
## il difetto è invisibile esattamente sulla macchina di chi sviluppa.
##
## ## Che cosa misura
##
## Ogni carattere sopra U+2100 che compare in un sorgente `.gd`, diviso fra
## quelli che il font imbarcato **ha** e quelli che **non ha**. Il conteggio
## include i commenti, e va bene così: una freccia in un commento non fa danno,
## ma il numero dice quanto quel repertorio sia entrato nelle abitudini di chi
## scrive — ed è da lì che finisce in una stringa che va sullo schermo.
##
## La colonna che conta è la seconda: **i glifi del catalogo della bottega**, che
## sono per costruzione tutti visibili, e le insegne disegnate a testo.
##
## Uso: godot --headless --path godot --script res://scripts/game/glifi_probe.gd

const RADICE := "res://scripts"

func _init() -> void:
	var font := ThemeDB.fallback_font
	print("")
	print("Font imbarcato: %s" % (font.get_font_name() if font != null else "NESSUNO"))
	print("")
	_censimento_sorgenti(font)
	_censimento_bottega(font)
	quit(0)

func _censimento_sorgenti(font: Font) -> void:
	var trovati: Dictionary = {}
	_raccogli(RADICE, trovati)
	var mancanti := 0
	var presenti := 0
	var usi_mancanti := 0
	for code in trovati.keys():
		if font.has_char(int(code)):
			presenti += 1
		else:
			mancanti += 1
			usi_mancanti += int(trovati[code])
	print("SORGENTI — simboli sopra U+2100 usati nel codice")
	print("  con glifo nel font imbarcato:   %d" % presenti)
	print("  SENZA glifo nel font imbarcato: %d  (%d occorrenze)" % [mancanti, usi_mancanti])

## **La riga che decide.** I glifi del catalogo finiscono tutti in bottega, uno
## per articolo: se il font non li ha, il bambino compra rettangoli.
func _censimento_bottega(font: Font) -> void:
	var rotti: Array = []
	var interi := 0
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var glifo := str(voce.get("glyph", ""))
		if glifo.is_empty():
			continue
		var tutto_ok := true
		for i in glifo.length():
			if not font.has_char(glifo.unicode_at(i)):
				tutto_ok = false
				break
		if tutto_ok:
			interi += 1
		else:
			rotti.append("%-22s %s  U+%04X" % [
				str(voce.get("id", "")), glifo, glifo.unicode_at(0)])
	print("")
	print("BOTTEGA — un glifo per articolo, tutti visibili sullo schermo")
	print("  interi: %d" % interi)
	print("  ROTTI:  %d" % rotti.size())
	for r in rotti:
		print("    " + str(r))
	print("")
	if rotti.is_empty():
		print("Nessun articolo della bottega mostra un rettangolo. Questa sonda puo'")
		print("diventare un audit.")
	else:
		print("Finche' questa lista non e' vuota, la bottega mostra rettangoli col")
		print("codice dentro a chi gioca nel browser o su tablet. La correzione non e'")
		print("imbarcare un font — servirebbe anche un font emoji, e sono megabyte —")
		print("ma **disegnare** le insegne, come si e' fatto per le palestre.")

func _raccogli(percorso: String, fuori: Dictionary) -> void:
	var d := DirAccess.open(percorso)
	if d == null:
		return
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		var pieno := "%s/%s" % [percorso, nome]
		if d.current_is_dir():
			_raccogli(pieno, fuori)
		elif nome.ends_with(".gd"):
			var f := FileAccess.open(pieno, FileAccess.READ)
			if f != null:
				var testo := f.get_as_text()
				for i in testo.length():
					var code := testo.unicode_at(i)
					if code > 0x2100:
						fuori[code] = int(fuori.get(code, 0)) + 1
		nome = d.get_next()
	d.list_dir_end()
