extends SceneTree

## **Un varco esiste se qualcuno lo apre e se aprirlo serve.** (8 settembre 2026)
##
## Tre difetti misurati lo stesso giorno, tutti e tre con la stessa forma —
## *la struttura c'era, il collegamento no* — e nessuno dei 250 audit li vedeva,
## perché guardavano tutti le REGOLE e nessuno la GEOMETRIA:
##
##   1. **Il varco fantasma.** Dal 4 settembre le palestre non ricevono più
##      `requiredTool`, ma la scena continuava a costruirci sopra un
##      `EquipmentGate` con la stringa vuota: 264 targhette «PASSAGGIO APERTO»
##      col disegno della torcia, su undici palestre per ventiquattro mondi,
##      dove un passaggio non è mai esistito.
##
##   2. **Il muro senza prova.** `_align_enigma_to_crossing` faceva `return` dopo
##      il primo aggancio. Il mondo 3 pianifica tre enigmi e ha due sbarramenti:
##      ne legava uno. «IL CANCELLO DEI PRIMI» — sette collisioni e una targhetta
##      — restava chiuso per sempre in tutti e diciotto i mondi di terra.
##
##   3. **La scorciatoia che non accorcia.** Misurato col cammino minimo, muro
##      chiuso contro muro aperto: **80-160 px**. Mezzo secondo. La meccanica più
##      interessante del gioco — una prova che apre fisicamente la mappa — esisteva
##      solo nei sei mondi d'acqua, dove ne vale 1600-2240.
##
## ## Che cosa misura, e come
##
## Le prime due domande si fanno alla scena vera di tutti e ventiquattro i mondi.
## La terza è geometrica e costa: si allaga l'isola con una griglia e si cammina.
## Si fa su un campione di mondi — uno d'acqua, uno di terra, il primo e l'ultimo
## — perché il difetto è nel generatore, non nel singolo profilo: se sfugge lì,
## sfugge ovunque.
##
## Sulla stessa griglia si chiede anche l'invariante che regge tutta la mappa:
## **tutto ciò che il mondo posa si tocca con i piedi**. La sonda gemella
## `raggiungibilita_probe` la misura su tutti e ventiquattro senza asserire.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
## Più larga della sonda (40 px): qui serve una risposta sì/no, non una misura
## fine, e la griglia grossa tiene l'audit sotto il minuto.
const CELLA := 60.0
const RAGGIO_ELI := 18.0
const DIREZIONI: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## Il pavimento del risparmio, in pixel. Misurato l'8 settembre 2026 sul caso
## peggiore dei diciotto mondi di terra: 400 px. Come il tetto delle scorciatoie,
## **questo numero sale e non scende**: se un giorno un muro torna a valere meno,
## è perché la posa si è rotta, non perché il mondo è cambiato.
const RISPARMIO_MINIMO := 300.0

## Un mondo di terra all'inizio, uno a metà, uno d'acqua e il finale.
const MONDI_CAMPIONE := [1, 3, 8, 24]

var _rossi: Array = []

func _init() -> void:
	call_deferred("_run")

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

func _run() -> void:
	root.size = Vector2i(900, 600)
	for livello in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		await _prova_nel_mondo(int(livello))
	if _rossi.is_empty():
		print("VARCHI VERI audit OK - nessun cartello senza porta, nessun muro senza prova, ogni scorciatoia accorcia")
		quit(0)
		return
	# Niente `assert` qui: un'asserzione fallita interrompe la funzione e `quit`
	# non arriva mai — l'audit resta appeso e il runner lo chiude in timeout dopo
	# quattro minuti invece di dire subito che cosa non va. È la stessa trappola
	# descritta in testa a `run-godot-audits.mjs`, presa dal lato opposto.
	for riga in _rossi:
		printerr("VARCHI VERI audit FALLITO — %s" % str(riga))
	quit(1)

func _richiesta(livello: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 400
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("varchi-veri-audit")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	return request

func _prova_nel_mondo(livello: int) -> void:
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _richiesta(livello))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	await process_frame
	await process_frame

	# --- 1. Nessun cartello davanti a una porta che non c'è ---------------------
	for nodo in mondo.get_tree().get_nodes_in_group("equipment_gate"):
		if not mondo.is_ancestor_of(nodo):
			continue
		_controlla(str(nodo.get("required_tool")) != "",
			"mondo %d: un varco costruito senza chiave — targhetta e disegno senza porta" % livello)

	# --- 2. Ogni muro in piedi ha la prova che lo apre --------------------------
	var muri := 0
	for nodo in mondo.get_tree().get_nodes_in_group("world_barrier"):
		if not mondo.is_ancestor_of(nodo):
			continue
		muri += 1
		var evento := str(nodo.get_meta("eventId", ""))
		var etichetta := nodo.get_node_or_null("BarrierLabel") as Label
		var nome := etichetta.text if etichetta != null else str(nodo.name)
		_controlla(evento != "",
			"mondo %d: «%s» sbarra la strada e nessuna prova lo apre" % [livello, nome])
		# E la prova deve esistere davvero fra gli eventi del mondo: un id
		# scritto ma non pianificato sarebbe lo stesso vicolo cieco.
		if evento != "":
			var trovata := false
			for evento_data in Array(mondo.get("mission_events")):
				if str(Dictionary(evento_data).get("id", "")) == evento:
					trovata = true
					break
			_controlla(trovata,
				"mondo %d: «%s» rimanda alla prova «%s», che non è nel piano del mondo" % [
					livello, nome, evento])

	# --- 3. La geometria, sul campione -----------------------------------------
	if MONDI_CAMPIONE.has(livello):
		_prova_geometria(mondo, livello)

	root.remove_child(mondo)
	mondo.queue_free()
	await process_frame

func _prova_geometria(mondo, livello: int) -> void:
	var chunks = mondo.get("chunks")
	var comp: WorldCompositionData = chunks.composition
	var profilo: Dictionary = mondo.get("world_profile")
	var spawn: Vector2 = profilo.get("spawn", Vector2.ZERO)
	var sagoma: PackedVector2Array = profilo.get("worldShape", PackedVector2Array())
	if comp == null or sagoma.is_empty():
		return
	var bordi := WorldExpeditionLayout.bounds_of(sagoma)
	var colonne := int(ceil(bordi.size.x / CELLA)) + 2
	var file := int(ceil(bordi.size.y / CELLA)) + 2
	var origine := bordi.position - Vector2.ONE * CELLA

	# 0 = fuori dalla sagoma · 1 = terra · 2 = acqua che ferma
	var mappa := PackedByteArray()
	mappa.resize(colonne * file)
	for j in range(file):
		for i in range(colonne):
			var p := origine + Vector2(float(i) + 0.5, float(j) + 0.5) * CELLA
			if not chunks.contains_world_point(p, RAGGIO_ELI):
				mappa[j * colonne + i] = 0
			elif _acqua_ferma(comp, p, true):
				mappa[j * colonne + i] = 2
			else:
				mappa[j * colonne + i] = 1

	var muri: Array = []
	for crossing_data in comp.crossings:
		if str(Dictionary(crossing_data).get("kind", "")) == "barrier":
			muri.append(crossing_data)

	# **Tutto quello che il mondo posa si tocca con i piedi.** Con i varchi
	# aperti: un forziere di là dal fiume è una promessa, non un difetto — un
	# forziere in mezzo al fiume lo è.
	var raggiunto := _allaga(mappa, colonne, file, origine, spawn, comp, true, [])
	for voce_data in _oggetti(mondo):
		var voce: Dictionary = voce_data
		var indice := _indice(voce["p"] as Vector2, origine, colonne, file)
		_controlla(indice >= 0 and raggiunto.has(indice),
			"mondo %d: «%s» è posato dove Eli non arriva (%s)" % [
				livello, str(voce["nome"]), str(voce["p"])])

	# **E ogni scorciatoia accorcia.** Cammino minimo fino all'altra faccia del
	# muro, con il muro in piedi e con il muro caduto.
	for muro_data in muri:
		var muro: Dictionary = muro_data
		var centro: Vector2 = muro.get("position", Vector2.ZERO)
		var approccio: Vector2 = muro.get("approach", Vector2.ZERO)
		var altra_faccia := centro + (centro - approccio)
		var chiuso := _distanza(mappa, colonne, file, origine, spawn, altra_faccia, comp, false, muri)
		var aperto := _distanza(mappa, colonne, file, origine, spawn, altra_faccia, comp, true, [])
		if chiuso < 0.0 or aperto < 0.0:
			continue   # l'altra faccia cade fuori griglia: niente da misurare
		_controlla(chiuso - aperto >= RISPARMIO_MINIMO,
			"mondo %d: aprire «%s» risparmia %.0f px invece di %.0f: è un cartello, non una scorciatoia" % [
				livello, str(muro.get("label", muro.get("id", "?"))),
				chiuso - aperto, RISPARMIO_MINIMO])

func _oggetti(mondo) -> Array:
	var elenco: Array = []
	for evento_data in Array(mondo.get("mission_events")):
		var evento: Dictionary = evento_data
		elenco.append({
			"nome": "evento %s" % str(evento.get("id", "")),
			"p": evento.get("position", Vector2.ZERO) as Vector2,
		})
	for edificio in Array(mondo.get("world_buildings")):
		if edificio is Node2D:
			elenco.append({
				"nome": "edificio %s" % str((edificio as Node2D).get_meta("building_role", "?")),
				"p": (edificio as Node2D).global_position,
			})
	for attore in Array(mondo.get("npc_actors")):
		if attore is Node2D:
			elenco.append({"nome": "abitante %s" % attore.name, "p": (attore as Node2D).global_position})
	for traccia in mondo.get_tree().get_nodes_in_group("mystery_artifact"):
		if traccia is Node2D and mondo.is_ancestor_of(traccia):
			elenco.append({"nome": "traccia %s" % traccia.name, "p": (traccia as Node2D).global_position})
	return elenco

## Copia fedele di `outdoor_world._water_blocks_position`, con l'aggiunta di
## poter dichiarare aperti tutti i varchi invece di leggere il salvataggio.
func _acqua_ferma(comp: WorldCompositionData, p: Vector2, tutti_aperti: bool) -> bool:
	if comp == null or comp.is_protected(p):
		return false
	if comp.raw_water_weight(p) < 0.58:
		return false
	if not tutti_aperti:
		return true
	for crossing_data in comp.crossings:
		var crossing: Dictionary = crossing_data
		if str(crossing.get("kind", "")) == "barrier":
			continue
		var delta := p - (crossing.get("position", Vector2.ZERO) as Vector2)
		var tangente: Vector2 = crossing.get("tangent", Vector2.DOWN)
		var normale: Vector2 = crossing.get("normal", Vector2.RIGHT)
		if absf(delta.dot(tangente)) <= 72.0 \
				and absf(delta.dot(normale)) <= float(crossing.get("halfWidth", 100.0)) + 86.0:
			return false
	return true

## I muri di terra: cerchi da 34 px in fila lungo la tangente.
func _muro_ferma(muri: Array, p: Vector2) -> bool:
	for muro_data in muri:
		var muro: Dictionary = muro_data
		var centro: Vector2 = muro.get("position", Vector2.ZERO)
		var tangente: Vector2 = muro.get("tangent", Vector2.RIGHT)
		var meta: float = float(muro.get("halfWidth", 150.0))
		var a := centro - tangente * meta
		var b := centro + tangente * meta
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(a + ab * t) <= 34.0 + RAGGIO_ELI:
			return true
	return false

func _indice(p: Vector2, origine: Vector2, colonne: int, file: int) -> int:
	var i := floori((p.x - origine.x) / CELLA)
	var j := floori((p.y - origine.y) / CELLA)
	if i < 0 or j < 0 or i >= colonne or j >= file:
		return -1
	return j * colonne + i

func _allaga(mappa: PackedByteArray, colonne: int, file: int, origine: Vector2,
		spawn: Vector2, comp: WorldCompositionData, tutti_aperti: bool,
		muri: Array) -> Dictionary:
	var raggiunto: Dictionary = {}
	var partenza := _indice(spawn, origine, colonne, file)
	if partenza < 0:
		return raggiunto
	raggiunto[partenza] = true
	var coda: Array[int] = [partenza]
	while not coda.is_empty():
		var corrente: int = coda.pop_back()
		var ci := corrente % colonne
		var cj := corrente / colonne
		for direzione in DIREZIONI:
			var ni := ci + direzione.x
			var nj := cj + direzione.y
			if ni < 0 or nj < 0 or ni >= colonne or nj >= file:
				continue
			var vicino := nj * colonne + ni
			if raggiunto.has(vicino) or mappa[vicino] != 1:
				continue
			if not tutti_aperti:
				var p := origine + Vector2(float(ni) + 0.5, float(nj) + 0.5) * CELLA
				if _acqua_ferma(comp, p, false) or _muro_ferma(muri, p):
					continue
			raggiunto[vicino] = true
			coda.append(vicino)
	return raggiunto

## Cammino minimo sulla griglia, in pixel. -1 se non ci si arriva.
func _distanza(mappa: PackedByteArray, colonne: int, file: int, origine: Vector2,
		da: Vector2, a: Vector2, comp: WorldCompositionData, tutti_aperti: bool,
		muri: Array) -> float:
	var partenza := _indice(da, origine, colonne, file)
	var arrivo := _indice(a, origine, colonne, file)
	if partenza < 0 or arrivo < 0 or mappa[arrivo] != 1:
		return -1.0
	var costo: Dictionary = {partenza: 0}
	var coda: Array[int] = [partenza]
	var testa := 0
	while testa < coda.size():
		var corrente: int = coda[testa]
		testa += 1
		if corrente == arrivo:
			return float(int(costo[corrente])) * CELLA
		var ci := corrente % colonne
		var cj := corrente / colonne
		for direzione in DIREZIONI:
			var ni := ci + direzione.x
			var nj := cj + direzione.y
			if ni < 0 or nj < 0 or ni >= colonne or nj >= file:
				continue
			var vicino := nj * colonne + ni
			if costo.has(vicino) or mappa[vicino] != 1:
				continue
			if not tutti_aperti:
				var p := origine + Vector2(float(ni) + 0.5, float(nj) + 0.5) * CELLA
				if _acqua_ferma(comp, p, false) or _muro_ferma(muri, p):
					continue
			costo[vicino] = int(costo[corrente]) + 1
			coda.append(vicino)
	return -1.0
