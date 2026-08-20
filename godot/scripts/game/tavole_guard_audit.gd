extends SceneTree

## **G-11 · La guardia sulle tavole.** (20 agosto 2026)
##
## Tre lotti d'arte consegnati in un giorno, tre audit nuovi scritti insieme a
## loro, tutti e tre verdi — e tre difetti passati sotto: un ritaglio che taglia
## l'oggetto, due testi a 1,8:1 su carta chiara, un budget di nodi misurato su un
## oggetto che in scena non esiste.
##
## Non è distrazione. Quegli audit verificano che la cosa sia **dichiarata** — che
## la tavola abbia un identificativo, che il nodo esista, che il tipo sia quello
## giusto — e una dichiarazione è esattamente ciò che un difetto di resa lascia
## intatto. È la decisione 14 applicata alle immagini: *sembravano vivi perché
## stavano nello schema*.
##
## Qui si guarda il disegno. Tre controlli, e nessuno di loro ha una soglia
## inventata a occhio:
##
##   1. **il ritaglio contiene l'oggetto**, e la griglia dichiarata copre il
##      foglio esatto;
##   2. **il testo si legge sulla superficie che ha sotto**, in tutte e due le
##      modalità;
##   3. **il budget di nodi si misura sull'oggetto che il mondo costruisce**, non
##      sull'aiutante che lo prepara.
##
## **Perché la regola 1 è aritmetica e non pittorica.** La prima idea era «nessun
## pixel opaco tocca il bordo del ritaglio». Misurata sui fogli veri dà 45 falsi
## positivi su 71: un arco di radici *deve* toccare i bordi della sua cella, ed è
## disegnato apposta. La regola che separa i due casi senza guardare i pixel è
## che **una griglia deve dividere il suo foglio esattamente**: se le celle sono
## alte 241 su un foglio alto 1659, quella griglia non è la griglia di quel
## foglio, e da lì in giù ogni riga scivola. Le altre due condizioni — la regione
## sta dentro la texture, la regione non è vuota — chiudono i casi rimanenti.

const PARCHMENT_PANEL := preload("res://scripts/ui/parchment_panel.gd")

## WCAG AA per testo normale. Non è un'opinione estetica: sotto questo valore un
## bambino su un tablet scolastico a luce ambientale non legge.
const CONTRASTO_MINIMO := 4.5

## **Cricchetto, e va solo verso il basso.** È il numero di nodi che un prop
## identitario porta davvero in scena oggi: radice, tavola, ombra, alone e
## l'animazione dell'alone. Quando l'alone decorativo uscirà dalla scenografia
## (coda di C-ART-10) questo numero scende, e scendendo non si allenta niente.
## Alzarlo è la cosa che questo audit esiste per impedire.
const BUDGET_NODI_PROP := 5

var difetti: Array = []
var misure: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_controlla_ritagli()
	_controlla_contrasto()
	_controlla_budget_nodi()

	for riga in misure:
		print("  %s" % riga)
	if not difetti.is_empty():
		print("\nTAVOLE GUARD — %d difetti di resa:" % difetti.size())
		for difetto in difetti:
			print("  · %s" % difetto)

	# **L'assert sta in una funzione sua, e non è pignoleria.** Un `assert`
	# fallito interrompe la funzione in corso: se stesse qui, `quit()` non
	# verrebbe mai raggiunto e il processo resterebbe appeso fino al timeout del
	# runner — che è esattamente il modo in cui un rosso si traveste da lentezza.
	# Interrompendo solo `_verdetto`, il messaggio esce e il processo muore con
	# il codice giusto.
	_verdetto()
	if difetti.is_empty():
		print("TAVOLE GUARD audit OK - ritagli, contrasto e budget misurati sul disegno")
	quit(0 if difetti.is_empty() else 1)

func _verdetto() -> void:
	assert(difetti.is_empty(),
		"la guardia sulle tavole ha trovato %d difetti di resa" % difetti.size())

# --- 1 · i ritagli ------------------------------------------------------------

## Raccoglie le regioni davvero usate dal gioco interrogando gli oggetti che il
## mondo costruisce, non le costanti che li descrivono: se domani la mappatura
## cambia forma, questa raccolta continua a dire la verità.
func _regioni_in_uso() -> Dictionary:
	var per_tavola := {}
	# La chiave è **il nome della tavola**, non l'oggetto che la mostra: quattro
	# semi dello stesso colpo condividono un'illustrazione per contratto, e senza
	# questa distinzione lo stesso difetto uscirebbe quattro volte mentre due
	# tavole diverse che pescano lo stesso ritaglio passerebbero inosservate.
	## `alias_ammesso` distingue due mondi diversi. Una **tavola** ha un nome
	## semantico e un disegno suo: due tracce sullo stesso ritaglio sarebbero due
	## oggetti diversi con la stessa faccia. Un **kind di bioma** no: nella Radura
	## un «crystal» mostra la roccia perché lì i cristalli non ci sono, ed è una
	## scelta scritta in `build_obstacle` dal primo giorno.
	var aggiungi := func(chi: String, sprite: Sprite2D, alias_ammesso := false) -> void:
		if sprite == null:
			return
		var atlas := sprite.texture as AtlasTexture
		if atlas == null or atlas.atlas == null:
			return
		var chiave := atlas.atlas.resource_path
		if not per_tavola.has(chiave):
			per_tavola[chiave] = {"texture": atlas.atlas, "regioni": {}, "alias_ammesso": false}
		if alias_ammesso:
			per_tavola[chiave]["alias_ammesso"] = true
		var regioni: Dictionary = per_tavola[chiave]["regioni"]
		if regioni.has(chi) and regioni[chi] != atlas.region:
			difetti.append("«%s» pesca da due ritagli diversi dello stesso foglio" % chi)
		regioni[chi] = atlas.region

	for livello in MysteryCatalog.TRACCE.keys():
		var traccia := MysteryCatalog.traccia_for(int(livello))
		var artefatto := MysteryArtifact.new()
		artefatto.configure("trace", "guard-%02d" % int(livello), traccia, false)
		aggiungi.call(str(traccia.get("tavola", "traccia %d" % int(livello))),
			artefatto.get_node_or_null("ArtifactIllustration") as Sprite2D)
		artefatto.free()

	var indice := 0
	for seme in MysteryCatalog.tutti_i_semi():
		var artefatto := MysteryArtifact.new()
		artefatto.configure("seed", "guard-seme-%d" % indice, seme as Dictionary, false)
		aggiungi.call(MysteryCatalog.tavola_per_seme(seme as Dictionary),
			artefatto.get_node_or_null("ArtifactIllustration") as Sprite2D)
		artefatto.free()
		indice += 1

	for famiglia in IdentityPropArt.FAMILIES:
		for kind in IdentityPropArt.FAMILIES[famiglia]:
			var prop := IdentityPropArt.build(str(kind), 0.5)
			if prop == null:
				difetti.append("prop «%s» senza tavola" % str(kind))
				continue
			aggiungi.call(str(kind),
				prop.get_node_or_null("IdentityPropSprite") as Sprite2D)
			prop.free()

	# Gli edifici (C-ART-11): tre atlanti 4×6, una cella per mondo. La cella qui
	# è calcolata dividendo la texture, quindi non può sfalsarsi — ma può
	# diventare frazionaria, ed è la stessa famiglia di difetto vista sul foglio
	# dei misteri.
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		for spec in BuildingCatalog.for_world(livello, {}):
			var dati := spec as Dictionary
			if str(dati.get("artPath", "")).is_empty():
				continue
			var edificio := BuildingActor.new()
			edificio.configure(dati, 0, false, true)
			var arte := edificio.find_children("GeneratedBuildingArt", "Sprite2D", true, false)
			aggiungi.call("%s del mondo %d" % [str(dati.get("role", "edificio")), livello],
				(arte[0] if not arte.is_empty() else null) as Sprite2D)
			edificio.free()

	# Gli atlanti naturali (C-ART-14): il vocabolario di ogni bioma. Si passa da
	# `build_obstacle`, cioè da chi li mette davvero nel mondo.
	for bioma in ["academy", "wild", "geo", "logic", "ruins", "crystal"]:
		for kind in ["tree", "bush", "rock", "crystal", "pillar", "ruin", "mushroom"]:
			var ostacolo := OutdoorVisualFactory.build_obstacle(str(kind), 40.0, 0x6be7d6, 0.5, str(bioma))
			if ostacolo == null:
				continue
			for figlio in ostacolo.get_children():
				aggiungi.call("%s/%s" % [str(bioma), str(kind)], figlio as Sprite2D, true)
			ostacolo.free()

	return per_tavola

func _controlla_ritagli() -> void:
	var per_tavola := _regioni_in_uso()
	for percorso in per_tavola:
		var scheda: Dictionary = per_tavola[percorso]
		var texture: Texture2D = scheda["texture"]
		var regioni: Dictionary = scheda["regioni"]
		var nome := str(percorso).get_file()
		var larghezza := float(texture.get_width())
		var altezza := float(texture.get_height())
		var immagine := texture.get_image()
		if immagine != null and immagine.is_compressed():
			immagine.decompress()

		# a) la griglia dichiarata deve dividere il foglio esattamente — ma solo
		#    se quel foglio è davvero una griglia. Un atlante a regioni scritte
		#    a mano (`outdoor_sprite`, `NpcPortrait.PORTRAIT_REGIONS`) non lo è,
		#    e pretendere che una misura qualunque divida la texture sarebbe un
		#    rosso inventato.
		var misure_uniche := {}
		for chi in regioni:
			misure_uniche[(regioni[chi] as Rect2).size] = true
		if misure_uniche.size() == 1 and regioni.size() >= 2 and _e_una_griglia(regioni, misure_uniche.keys()[0]):
			var cella: Vector2 = misure_uniche.keys()[0]
			if cella.x > 0.0 and not is_equal_approx(fmod(larghezza, cella.x), 0.0):
				difetti.append("%s: celle larghe %d su un foglio largo %d — la griglia non divide il foglio"
					% [nome, int(cella.x), int(larghezza)])
			if cella.y > 0.0 and not is_equal_approx(fmod(altezza, cella.y), 0.0):
				difetti.append("%s: celle alte %d su un foglio alto %d — la griglia non divide il foglio, e da lì in giù ogni riga scivola di %d px"
					% [nome, int(cella.y), int(altezza), int(cella.y - fmod(altezza, cella.y))])
			misure.append("%s: %d regioni da %dx%d su %dx%d" % [
				nome, regioni.size(), int(cella.x), int(cella.y), int(larghezza), int(altezza)])
		else:
			misure.append("%s: %d regioni di misura variabile su %dx%d" % [
				nome, regioni.size(), int(larghezza), int(altezza)])

		for chi in regioni:
			var rect: Rect2 = regioni[chi]
			# b) la regione sta dentro il foglio.
			if rect.position.x < 0.0 or rect.position.y < 0.0 \
					or rect.end.x > larghezza or rect.end.y > altezza:
				difetti.append("%s · «%s»: il ritaglio a (%d,%d) da %dx%d esce dal foglio %dx%d"
					% [nome, str(chi), int(rect.position.x), int(rect.position.y),
					int(rect.size.x), int(rect.size.y), int(larghezza), int(altezza)])
				continue
			# c) la regione non è vuota: un ritaglio che pesca il nulla è una
			#    mappatura sbagliata, e a schermo diventa un buco senza errori.
			if immagine != null and not _contiene_disegno(immagine, rect):
				difetti.append("%s · «%s»: il ritaglio a (%d,%d) non contiene disegno"
					% [nome, str(chi), int(rect.position.x), int(rect.position.y)])

		# d) due tavole diverse non possono pescare dallo stesso pezzo di foglio:
		#    sarebbe la stessa illustrazione su due oggetti che il catalogo
		#    descrive come diversi.
		if not bool(scheda.get("alias_ammesso", false)):
			var nomi := regioni.keys()
			for i in nomi.size():
				for j in range(i + 1, nomi.size()):
					var a: Rect2 = regioni[nomi[i]]
					var b: Rect2 = regioni[nomi[j]]
					if a.intersects(b):
						difetti.append("%s: «%s» e «%s» pescano dallo stesso ritaglio"
							% [nome, str(nomi[i]), str(nomi[j])])

## Un foglio è una griglia quando ogni ritaglio comincia su un multiplo esatto
## della cella: è la condizione che separa un atlante a celle da un atlante a
## regioni scritte a mano.
func _e_una_griglia(regioni: Dictionary, cella: Vector2) -> bool:
	if cella.x <= 0.0 or cella.y <= 0.0:
		return false
	for chi in regioni:
		var rect: Rect2 = regioni[chi]
		if not is_equal_approx(fmod(rect.position.x, cella.x), 0.0):
			return false
		if not is_equal_approx(fmod(rect.position.y, cella.y), 0.0):
			return false
	return true

func _contiene_disegno(immagine: Image, rect: Rect2) -> bool:
	var passo := 4
	var x := int(rect.position.x)
	while x < int(rect.end.x):
		var y := int(rect.position.y)
		while y < int(rect.end.y):
			if immagine.get_pixel(x, y).a > 0.08:
				return true
			y += passo
		x += passo
	return false

# --- 2 · il contrasto ---------------------------------------------------------

## Luminanza relativa WCAG. I componenti di `Color` sono già in sRGB 0..1, quindi
## la formula si applica così com'è.
func _luminanza(colore: Color) -> float:
	var canali := [colore.r, colore.g, colore.b]
	var lineari := []
	for valore in canali:
		var v := float(valore)
		lineari.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * float(lineari[0]) + 0.7152 * float(lineari[1]) + 0.0722 * float(lineari[2])

func _contrasto(testo: Color, sfondo: Color) -> float:
	var a := _luminanza(testo)
	var b := _luminanza(sfondo)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)

## Il colore che il testo si trova davvero sotto: la media della texture, non il
## colore che il progettista aveva in mente quando ha scelto l'inchiostro.
func _colore_medio(texture: Texture2D) -> Color:
	var immagine := texture.get_image()
	if immagine == null:
		return Color.BLACK
	if immagine.is_compressed():
		immagine.decompress()
	var somma := Vector3.ZERO
	var conteggio := 0
	var passo := 8
	var x := 0
	while x < immagine.get_width():
		var y := 0
		while y < immagine.get_height():
			var pixel := immagine.get_pixel(x, y)
			somma += Vector3(pixel.r, pixel.g, pixel.b)
			conteggio += 1
			y += passo
		x += passo
	if conteggio == 0:
		return Color.BLACK
	return Color(somma.x / conteggio, somma.y / conteggio, somma.z / conteggio)

## Lo sfondo effettivo di uno stile: la media della texture se è un materiale,
## il riempimento se è il ripiego ad alto contrasto.
func _sfondo_di(stile: StyleBox) -> Color:
	var texture_style := stile as StyleBoxTexture
	if texture_style != null and texture_style.texture != null:
		return _colore_medio(texture_style.texture)
	var flat := stile as StyleBoxFlat
	return flat.bg_color if flat != null else Color.BLACK

func _controlla_contrasto() -> void:
	for alto_contrasto in [false, true]:
		var pannello := PARCHMENT_PANEL.new()
		pannello.livello = 1
		pannello.trovate = 1
		pannello.totali = 24
		pannello.high_contrast = alto_contrasto
		root.add_child(pannello)

		var contenitori := pannello.find_children("*", "PanelContainer", true, false)
		if contenitori.is_empty():
			difetti.append("pergamena: nessun pannello con superficie")
			pannello.queue_free()
			continue
		var contenitore: PanelContainer = contenitori[0]
		var sfondo := _sfondo_di(contenitore.get_theme_stylebox("panel"))
		var modalita := "alto contrasto" if alto_contrasto else "normale"
		for nodo in contenitore.find_children("*", "Label", true, false):
			var etichetta: Label = nodo
			var inchiostro := etichetta.get_theme_color("font_color")
			var rapporto := _contrasto(inchiostro, sfondo)
			var chi := _nome_leggibile(etichetta)
			misure.append("pergamena/%s · %s: %.1f:1" % [modalita, chi, rapporto])
			if rapporto < CONTRASTO_MINIMO:
				difetti.append("pergamena (%s): «%s» sta a %.1f:1 sulla carta, sotto %.1f:1"
					% [modalita, chi, rapporto, CONTRASTO_MINIMO])
		pannello.queue_free()

	# L'esame ha un fondo suo da quando il banco esiste: se la superficie
	# condivisa non lo distingue più, la differenza è dichiarata e non disegnata.
	var banco := SurfaceStyles.desk(false, Color("6be7d6"), false)
	var esame := SurfaceStyles.desk(false, Color("6be7d6"), true)
	if _stessa_faccia(banco, esame):
		difetti.append("banco ed esame producono la stessa superficie: `is_exam` non cambia un pixel")

## Un'etichetta senza nome esplicito si chiama `@Label@77`, che in un rosso non
## dice a nessuno quale riga guardare: allora la si nomina con il suo testo.
func _nome_leggibile(etichetta: Label) -> String:
	if not str(etichetta.name).begins_with("@"):
		return str(etichetta.name)
	var testo := etichetta.text.strip_edges().replace("\n", " ")
	if testo.length() > 32:
		testo = testo.substr(0, 32) + "…"
	return testo if not testo.is_empty() else str(etichetta.name)

## Due stili si vedono uguali? Confronta ciò che finisce a schermo, non
## l'istanza: due `StyleBox` diversi possono disegnare lo stesso rettangolo.
func _stessa_faccia(primo: StyleBox, secondo: StyleBox) -> bool:
	if not _stessi_margini(primo, secondo):
		return false
	var a := primo as StyleBoxTexture
	var b := secondo as StyleBoxTexture
	if a != null and b != null:
		return a.texture == b.texture and a.modulate_color == b.modulate_color \
			and a.region_rect == b.region_rect
	var fa := primo as StyleBoxFlat
	var fb := secondo as StyleBoxFlat
	if fa != null and fb != null:
		return fa.bg_color == fb.bg_color and fa.border_color == fb.border_color \
			and fa.border_width_left == fb.border_width_left
	return false

## Anche uno spessore diverso è una differenza che si vede: se domani l'esame si
## distinguesse per respiro invece che per colore, la guardia non deve gridare.
func _stessi_margini(primo: StyleBox, secondo: StyleBox) -> bool:
	for lato in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		if not is_equal_approx(primo.get_content_margin(lato), secondo.get_content_margin(lato)):
			return false
	return true

# --- 3 · il budget di nodi ----------------------------------------------------

func _conta_nodi(nodo: Node) -> int:
	var totale := 1
	for figlio in nodo.get_children():
		totale += _conta_nodi(figlio)
	return totale

func _controlla_budget_nodi() -> void:
	var peggiore := 0
	var peggiore_kind := ""
	var con_processo := 0
	for famiglia in IdentityPropArt.FAMILIES:
		for kind in IdentityPropArt.FAMILIES[famiglia]:
			var in_scena := OutdoorVisualFactory.build_identity_prop(str(kind), "", 0.5)
			if in_scena == null:
				difetti.append("prop «%s» non costruito dal mondo" % str(kind))
				continue
			var nodi := _conta_nodi(in_scena)
			if nodi > peggiore:
				peggiore = nodi
				peggiore_kind = str(kind)
			if not in_scena.find_children("*", "OutdoorAmbientAnim", true, false).is_empty():
				con_processo += 1
			if nodi > BUDGET_NODI_PROP:
				difetti.append("prop «%s»: %d nodi in scena, sopra il cricchetto di %d"
					% [str(kind), nodi, BUDGET_NODI_PROP])
			in_scena.free()
	misure.append("prop identitari: massimo %d nodi in scena (%s), cricchetto %d · %d su %d portano un nodo che gira in _process"
		% [peggiore, peggiore_kind, BUDGET_NODI_PROP, con_processo, _quanti_prop()])

func _quanti_prop() -> int:
	var totale := 0
	for famiglia in IdentityPropArt.FAMILIES:
		totale += (IdentityPropArt.FAMILIES[famiglia] as Array).size()
	return totale
