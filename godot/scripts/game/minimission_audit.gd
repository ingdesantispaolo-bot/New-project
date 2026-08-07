extends SceneTree

## **Le riparazioni dei Dodici, verificate.** (7 agosto 2026)
##
## Cinque cose, e la prima è quella che vale davvero.
##
## 1. **SOSTITUISCE, NON AGGIUNGE.** È la direttiva esplicita del committente e
##    l'unico modo di rispondere a «faticoso» senza peggiorarlo. Si misura per
##    tutti e ventiquattro i mondi: il numero di eventi pianificati e il numero
##    di esercizi totali devono restare **identici** a prima dell'introduzione
##    delle minimissioni. Se un giorno qualcuno le aggiungerà invece di
##    sostituirle, questo audit lo dirà prima del collaudo.
## 2. Ogni mondo ha un incarico, e ogni incarico ha un testo suo.
## 3. Le quattro forme sono distribuite, non una sola con quattro nomi.
## 4. Il grado consigliato cresce e non supera mai le soglie che esistono.
## 5. L'esito nomina un cambiamento, e nessun testo è un doppione.

const OK := "MINIMISSION audit VERDE"

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	_catalogo_completo()
	_forme_distribuite()
	_gradi_coerenti()
	_testi_distinti()
	_sostituisce_non_aggiunge()
	if errori.is_empty():
		print(OK)
	else:
		printerr("MINIMISSION audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _catalogo_completo() -> void:
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		if not MinimissionCatalog.ha(level):
			_fallisci("mondo %d senza incarico" % level)
			continue
		var voce := MinimissionCatalog.incarico(level)
		for chiave in ["forma", "titolo", "apertura", "esito", "verbo", "glifo", "colore"]:
			if str(voce.get(chiave, "")).strip_edges().is_empty():
				_fallisci("mondo %d: campo «%s» vuoto" % [level, chiave])
		if not MinimissionCatalog.FORME.has(str(voce.get("forma", ""))):
			_fallisci("mondo %d: forma sconosciuta «%s»" % [level, voce.get("forma", "")])
		# Un'apertura di una riga non racconta un guasto: dice che c'è. Il numero
		# è basso apposta — è un pavimento contro il segnaposto, non uno stile.
		if str(voce.get("apertura", "")).length() < 80:
			_fallisci("mondo %d: apertura troppo corta per dire che cosa è rotto" % level)
		if str(voce.get("esito", "")).length() < 50:
			_fallisci("mondo %d: esito troppo corto per nominare un cambiamento" % level)

func _forme_distribuite() -> void:
	var conta := MinimissionCatalog.conteggio_forme()
	for forma in MinimissionCatalog.FORME:
		var n := int(conta.get(forma, 0))
		# Quattro forme su ventiquattro mondi: quattro a testa è il minimo sotto
		# il quale una forma diventa una curiosità invece di un archetipo.
		if n < 4:
			_fallisci("forma «%s» usata solo %d volte: non è un archetipo" % [forma, n])
	# Due mondi di fila con la stessa forma si sentono come lo stesso incarico
	# due volte, che è esattamente il difetto da cui questo lotto nasce.
	for level in range(2, WorldProfileCatalog.MAX_LEVEL + 1):
		var qui := str(MinimissionCatalog.incarico(level).get("forma", ""))
		var prima := str(MinimissionCatalog.incarico(level - 1).get("forma", ""))
		if qui == prima:
			_fallisci("mondi %d e %d hanno la stessa forma (%s)" % [level - 1, level, qui])

func _gradi_coerenti() -> void:
	var massimo := WorldLight.SOGLIE.size() - 1
	var precedente := -1
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var g := MinimissionCatalog.grado_richiesto(level)
		if g < 0 or g > massimo:
			_fallisci("mondo %d: grado %d fuori dalle soglie esistenti" % [level, g])
		if g < precedente:
			_fallisci("mondo %d: il grado consigliato scende (%d dopo %d)" % [level, g, precedente])
		precedente = g
	if MinimissionCatalog.grado_richiesto(1) != 0:
		_fallisci("il primo mondo chiede già potenza: la prima riparazione deve essere alla portata di chiunque")

func _testi_distinti() -> void:
	var titoli := {}
	var aperture := {}
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var voce := MinimissionCatalog.incarico(level)
		var titolo := str(voce.get("titolo", ""))
		if titoli.has(titolo):
			_fallisci("titolo ripetuto fra i mondi %d e %d: «%s»" % [titoli[titolo], level, titolo])
		titoli[titolo] = level
		var apertura := str(voce.get("apertura", ""))
		if aperture.has(apertura):
			_fallisci("apertura ripetuta fra i mondi %d e %d" % [aperture[apertura], level])
		aperture[apertura] = level

## **Il controllo che conta.** Si pianifica ogni mondo e si verifica che
## l'incarico abbia preso il posto di un evento invece di essersi aggiunto.
##
## Due misure separate, perché si può sbagliare in due modi diversi: il numero di
## POI (si affolla la mappa) e il numero di esercizi (si allunga la campagna).
func _sostituisce_non_aggiunge() -> void:
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var eventi := MissionEventDirector.plan(profile, {}, "audit-minimissione-%d" % level)
		var incarichi := 0
		var campate_incarico := 0
		var gate := 0
		for e in eventi:
			var evento: Dictionary = e
			if bool(evento.get("countsForGate", false)):
				gate += 1
			if str(evento.get("kind", "")) != "minimission":
				continue
			incarichi += 1
			campate_incarico += int(evento.get("campate", 0))
			if not bool(evento.get("countsForGate", false)):
				_fallisci("mondo %d: l'incarico non conta per il gate, quindi è un'aggiunta" % level)
		if incarichi != 1:
			_fallisci("mondo %d: %d incarichi invece di uno" % [level, incarichi])
		# L'incarico sostituisce una MISSIONE e ne eredita le tre campate: se un
		# giorno ne chiedesse quattro sarebbe un esercizio in più per mondo, cioè
		# ventiquattro in più in campagna, cioè di nuovo «faticoso».
		if campate_incarico > 3:
			_fallisci("mondo %d: l'incarico chiede %d campate, più dell'evento sostituito" %
				[level, campate_incarico])
		# Il numero di eventi-gate è quello di sempre: `gate_total` non dipende
		# dalle minimissioni, e se un giorno ci dipendesse si vedrebbe qui.
		if gate != MissionEventDirector.HOST_EVENTS + MissionEventDirector.GATE_SURPLUS:
			_fallisci("mondo %d: %d eventi-gate invece di %d — l'incarico si è aggiunto" %
				[level, gate, MissionEventDirector.HOST_EVENTS + MissionEventDirector.GATE_SURPLUS])
