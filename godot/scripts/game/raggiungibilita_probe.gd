extends SceneTree

## **Che cosa si raggiunge davvero, camminando.** (sonda di misura)
##
## Tutti gli audit di raggiungibilita' esistenti guardano le REGOLE: la materia
## non deve stare dietro una chiave, il gate deve aprirsi, la palestra deve
## esistere. Nessuno guarda la GEOMETRIA: se il punto in cui l'oggetto e' stato
## posato si tocca con i piedi, partendo dallo sbarco.
##
## Questa sonda apre i ventiquattro mondi, allaga la sagoma dell'isola con una
## griglia da 40 px partendo dallo spawn e usando la stessa regola che il gioco
## applica al giocatore (`_water_blocks_position` + sagoma del profilo), e poi
## chiede di ogni cosa collocata: sei dentro l'area raggiunta?
##
## Misura, non giudica: stampa numeri, non `assert`. Serve a decidere quali
## tetti mettere, non a mettere un rosso su un caso che nessuno ha ancora visto.

const WORLD_SCENE := "res://scenes/outdoor_world.tscn"
const CELLA := 40.0
const RAGGIO_ELI := 18.0
const DIREZIONI: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var righe: Array = []
var totali := {
	"oggetti": 0, "irraggiungibili_sempre": 0, "irraggiungibili_all_arrivo": 0,
	"forzieri": 0, "forzieri_saltati": 0, "forzieri_spostati": 0,
	"sacche_isolate": 0, "area_isolata": 0.0,
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(900, 600)
	for livello in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		await _analizza(int(livello))
	print("\n================ RIEPILOGO ================")
	for riga in righe:
		print(riga)
	print("\noggetti collocati: %d" % int(totali["oggetti"]))
	print("mai raggiungibili (nemmeno aprendo tutti i varchi): %d" % int(totali["irraggiungibili_sempre"]))
	print("non raggiungibili all'arrivo (varchi chiusi): %d" % int(totali["irraggiungibili_all_arrivo"]))
	print("forzieri generati: %d · saltati per acqua: %d · spostati: %d" % [
		int(totali["forzieri"]), int(totali["forzieri_saltati"]), int(totali["forzieri_spostati"])])
	print("deserto medio (terra a piu' di 600 px da qualunque contenuto): %.1f%%" % (
		float(totali.get("deserto", 0.0)) / float(WorldProfileCatalog.MAX_LEVEL)))
	print("coppie di oggetti sovrapposti (<110 px): %d" % int(totali.get("addosso", 0)))
	print("sacche di terra isolate: %d · area isolata totale: %.0f k px²" % [
		int(totali["sacche_isolate"]), float(totali["area_isolata"]) / 1000.0])
	quit(0)

func _richiesta(livello: int) -> Dictionary:
	var initial := GameSaveManager._default_data()
	initial["level"] = livello
	initial["energy"] = 400
	initial["worlds"] = {"unlocked": range(1, livello + 1), "current": livello}
	var request := NativeWorldState.default_request("raggiungibilita-probe")
	request["loadLocalSave"] = false
	request["initialSave"] = initial
	request["worldLevel"] = livello
	return request

func _analizza(livello: int) -> void:
	var mondo := (load(WORLD_SCENE) as PackedScene).instantiate()
	mondo.set("launch_request_override", _richiesta(livello))
	mondo.set("launch_stream_radius_override", 0)
	root.add_child(mondo)
	await process_frame
	await process_frame

	var chunks = mondo.get("chunks")
	var comp: WorldCompositionData = chunks.composition
	var profilo: Dictionary = mondo.get("world_profile")
	var spawn: Vector2 = profilo.get("spawn", Vector2.ZERO)
	var sagoma: PackedVector2Array = profilo.get("worldShape", PackedVector2Array())
	var bordi := WorldExpeditionLayout.bounds_of(sagoma)

	var colonne := int(ceil(bordi.size.x / CELLA)) + 2
	var file := int(ceil(bordi.size.y / CELLA)) + 2
	var origine := bordi.position - Vector2.ONE * CELLA

	# 0 = fuori sagoma · 1 = terra · 2 = acqua che ferma
	var mappa := PackedByteArray()
	mappa.resize(colonne * file)
	var terra_totale := 0
	for j in range(file):
		for i in range(colonne):
			var p := origine + Vector2(float(i) + 0.5, float(j) + 0.5) * CELLA
			if not chunks.contains_world_point(p, RAGGIO_ELI):
				mappa[j * colonne + i] = 0
				continue
			if _acqua_ferma(comp, p, true):
				mappa[j * colonne + i] = 2
			else:
				mappa[j * colonne + i] = 1
				terra_totale += 1
	# Gli sbarramenti di terra non sono acqua: sono sette cerchi da 34 px in fila
	# lungo la tangente. Entrano nella griglia come muro, e si tolgono quando si
	# misura il mondo a varchi aperti.
	var muri: Array = []
	for crossing_data in comp.crossings:
		var crossing: Dictionary = crossing_data
		if str(crossing.get("kind", "")) != "barrier":
			continue
		muri.append(crossing)

	# Due allagamenti: con tutti i varchi aperti (che cosa esiste) e con quelli
	# chiusi (che cosa si tocca appena sbarcati).
	var raggiunto_sempre := _allaga(mappa, colonne, file, origine, spawn, comp, true)
	var raggiunto_arrivo := _allaga(mappa, colonne, file, origine, spawn, comp, false)

	var isolate := 0
	var area_isolata := 0.0
	for indice in range(mappa.size()):
		if mappa[indice] == 1 and not raggiunto_sempre.has(indice):
			area_isolata += CELLA * CELLA
	var sacche := _sacche_isolate(mappa, colonne, file, raggiunto_sempre)
	isolate = sacche.size()

	# Con i muri in piedi: che cosa si tocca appena sbarcati, per davvero.
	var raggiunto_muri := _allaga(mappa, colonne, file, origine, spawn, comp, false, muri)
	var oggetti := _oggetti(mondo, chunks, comp, livello)
	var mai: Array = []
	var non_ora: Array = []
	for voce_data in oggetti:
		var voce: Dictionary = voce_data
		var p: Vector2 = voce["p"]
		var indice := _indice(p, origine, colonne, file)
		var ok_sempre := indice >= 0 and raggiunto_sempre.has(indice)
		var ok_ora := indice >= 0 and raggiunto_arrivo.has(indice)
		if not ok_sempre:
			mai.append(voce)
		elif not ok_ora:
			non_ora.append(voce)

	totali["oggetti"] = int(totali["oggetti"]) + oggetti.size()
	totali["irraggiungibili_sempre"] = int(totali["irraggiungibili_sempre"]) + mai.size()
	totali["irraggiungibili_all_arrivo"] = int(totali["irraggiungibili_all_arrivo"]) + non_ora.size()
	totali["sacche_isolate"] = int(totali["sacche_isolate"]) + isolate
	totali["area_isolata"] = float(totali["area_isolata"]) + area_isolata

	var perc_arrivo := 100.0 * float(raggiunto_arrivo.size()) / maxf(1.0, float(terra_totale))
	var perc_sempre := 100.0 * float(raggiunto_sempre.size()) / maxf(1.0, float(terra_totale))
	var perc_muri := 100.0 * float(raggiunto_muri.size()) / maxf(1.0, float(terra_totale))
	var riga := "mondo %2d · terra %5d celle · all'arrivo (muri in piedi) %5.1f%% · solo acqua %5.1f%% · tutto aperto %5.1f%% · sacche isolate %d (%.0fk px²) · oggetti %d · mai %d · non all'arrivo %d" % [
		livello, terra_totale, perc_muri, perc_arrivo, perc_sempre, isolate, area_isolata / 1000.0,
		oggetti.size(), mai.size(), non_ora.size()]
	righe.append(riga)
	print(riga)
	for voce_data in mai:
		var voce: Dictionary = voce_data
		print("    [MAI]  %s @ %s" % [str(voce["nome"]), str(voce["p"])])
	for voce_data in non_ora:
		var voce: Dictionary = voce_data
		print("    [dopo] %s @ %s" % [str(voce["nome"]), str(voce["p"])])
	# Censimento dei passaggi: quanti sono, chi li apre, e quanto cammino
	# risparmia aprirli. Un varco che non accorcia niente e' un cartello.
	for crossing_data in comp.crossings:
		var crossing: Dictionary = crossing_data
		var tipo := str(crossing.get("kind", "acqua"))
		var evento := str(crossing.get("eventId", ""))
		var approccio: Vector2 = crossing.get("approach", Vector2.ZERO)
		var centro: Vector2 = crossing.get("position", Vector2.ZERO)
		# L'altra riva: l'approccio specchiato attraverso il centro del varco.
		var altra_riva := centro + (centro - approccio)
		var chiuso := _distanza(mappa, colonne, file, origine, spawn, altra_riva, comp, false, muri)
		var aperto := _distanza(mappa, colonne, file, origine, spawn, altra_riva, comp, true, [])
		var risparmio := "irraggiungibile" if chiuso < 0.0 else "%.0f px" % maxf(0.0, chiuso - aperto)
		print("    [varco] %s · %s · meta%.0f · prova=%s · da chiuso %s · da aperto %.0f px · risparmio %s" % [
			str(crossing.get("id", "")), tipo, float(crossing.get("halfWidth", 0.0)),
			evento if evento != "" else "NESSUNA",
			"irraggiungibile" if chiuso < 0.0 else "%.0f px" % chiuso,
			maxf(0.0, aperto), risparmio])
	# **Quanto deserto.** Distanza (a piedi, sulla griglia) di ogni cella di terra
	# raggiungibile dalla cosa piu' vicina: se meta' isola sta a piu' di 600 px da
	# qualunque contenuto, quella meta' e' strada, non gioco.
	var sorgenti: Array[int] = []
	for voce_data in oggetti:
		var indice_o := _indice(Dictionary(voce_data)["p"] as Vector2, origine, colonne, file)
		if indice_o >= 0 and raggiunto_sempre.has(indice_o):
			sorgenti.append(indice_o)
	var lontananza := _distanze_da(mappa, colonne, file, sorgenti, raggiunto_sempre)
	var deserto := 0
	var molto_deserto := 0
	for indice_c in raggiunto_sempre.keys():
		var passi := int(lontananza.get(indice_c, 9999))
		if float(passi) * CELLA > 600.0:
			deserto += 1
		if float(passi) * CELLA > 1000.0:
			molto_deserto += 1
	print("    [deserto] %.1f%% della terra raggiungibile e' a piu' di 600 px da qualunque contenuto · %.1f%% oltre 1000 px" % [
		100.0 * float(deserto) / maxf(1.0, float(raggiunto_sempre.size())),
		100.0 * float(molto_deserto) / maxf(1.0, float(raggiunto_sempre.size()))])
	totali["deserto"] = float(totali.get("deserto", 0.0)) + 100.0 * float(deserto) / maxf(1.0, float(raggiunto_sempre.size()))

	# Oggetti che si toccano: due segnaposto a meno di 110 px si disegnano uno
	# addosso all'altro (il marcatore dell'evento e' largo ~140 px).
	var addosso: Array = []
	for a in range(oggetti.size()):
		for b in range(a + 1, oggetti.size()):
			var pa: Vector2 = Dictionary(oggetti[a])["p"]
			var pb: Vector2 = Dictionary(oggetti[b])["p"]
			var d := pa.distance_to(pb)
			if d < 110.0:
				addosso.append("mondo %d: %s ~ %s (%.0f px)" % [
					livello,
					str(Dictionary(oggetti[a])["nome"]), str(Dictionary(oggetti[b])["nome"]), d])
	# **Dentro l'anello di un forziere chiuso.** Il varco da attrezzo e' dieci
	# cerchi in cerchio, raggio 50, che fermano Eli fra 30 e 70 px dal forziere.
	# Qualunque cosa cada li' dentro resta chiusa a chiave insieme al forziere,
	# e nessuno lo sta controllando.
	for a in range(oggetti.size()):
		var voce_a: Dictionary = oggetti[a]
		var nome_a := str(voce_a["nome"])
		if not nome_a.begins_with("forziere") or not nome_a.contains("[tool-"):
			continue
		for b in range(oggetti.size()):
			if a == b:
				continue
			var voce_b: Dictionary = oggetti[b]
			var d2: float = (voce_a["p"] as Vector2).distance_to(voce_b["p"] as Vector2)
			if d2 <= 70.0 + RAGGIO_ELI:
				print("    [in gabbia] mondo %d: %s dentro l'anello di %s (%.0f px)" % [
					livello, str(voce_b["nome"]), nome_a, d2])
	if not addosso.is_empty():
		totali["addosso"] = int(totali.get("addosso", 0)) + addosso.size()
		for riga_addosso in addosso:
			print("    [addosso] %s" % str(riga_addosso))
	for sacca_data in sacche:
		var sacca: Dictionary = sacca_data
		if float(sacca["area"]) >= 200000.0:
			print("    [zona] sacca isolata di %.0fk px² attorno a %s" % [
				float(sacca["area"]) / 1000.0, str(sacca["centro"])])

	root.remove_child(mondo)
	mondo.queue_free()
	await process_frame

## Copia fedele di `outdoor_world._water_blocks_position`, con l'aggiunta di
## poter dichiarare aperti TUTTI i varchi invece di leggere il salvataggio.
func _acqua_ferma(comp: WorldCompositionData, p: Vector2, tutti_aperti: bool) -> bool:
	if comp == null:
		return false
	if comp.is_protected(p):
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
		var tangent: Vector2 = crossing.get("tangent", Vector2.DOWN)
		var normal: Vector2 = crossing.get("normal", Vector2.RIGHT)
		if absf(delta.dot(tangent)) <= 72.0 \
				and absf(delta.dot(normal)) <= float(crossing.get("halfWidth", 100.0)) + 86.0:
			return false
	return true

func _indice(p: Vector2, origine: Vector2, colonne: int, file: int) -> int:
	var i := floori((p.x - origine.x) / CELLA)
	var j := floori((p.y - origine.y) / CELLA)
	if i < 0 or j < 0 or i >= colonne or j >= file:
		return -1
	return j * colonne + i

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

func _allaga(mappa: PackedByteArray, colonne: int, file: int, origine: Vector2,
		spawn: Vector2, comp: WorldCompositionData, tutti_aperti: bool,
		muri: Array = []) -> Dictionary:
	# Con i varchi chiusi la griglia va rivalutata solo sulle celle d'acqua che
	# il varco aperto renderebbe passabili: tutto il resto e' identico.
	var raggiunto: Dictionary = {}
	var partenza := _indice(spawn, origine, colonne, file)
	if partenza < 0:
		return raggiunto
	var coda: Array[int] = [partenza]
	raggiunto[partenza] = true
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
			if raggiunto.has(vicino):
				continue
			if mappa[vicino] == 0:
				continue
			if mappa[vicino] == 2:
				continue
			if not tutti_aperti:
				var p := origine + Vector2(float(ni) + 0.5, float(nj) + 0.5) * CELLA
				if _acqua_ferma(comp, p, false):
					continue
				if _muro_ferma(muri, p):
					continue
			raggiunto[vicino] = true
			coda.append(vicino)
	return raggiunto

## Cammino piu' corto sulla griglia, in pixel. -1 se non ci si arriva.
func _distanza(mappa: PackedByteArray, colonne: int, file: int, origine: Vector2,
		da: Vector2, a: Vector2, comp: WorldCompositionData, tutti_aperti: bool,
		muri: Array) -> float:
	var partenza := _indice(da, origine, colonne, file)
	var arrivo := _indice(a, origine, colonne, file)
	if partenza < 0 or arrivo < 0:
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
			if costo.has(vicino) or mappa[vicino] == 0 or mappa[vicino] == 2:
				continue
			if not tutti_aperti:
				var p := origine + Vector2(float(ni) + 0.5, float(nj) + 0.5) * CELLA
				if _acqua_ferma(comp, p, false) or _muro_ferma(muri, p):
					continue
			costo[vicino] = int(costo[corrente]) + 1
			coda.append(vicino)
	return -1.0

func _distanze_da(mappa: PackedByteArray, colonne: int, file: int,
		sorgenti: Array[int], dominio: Dictionary) -> Dictionary:
	var costo: Dictionary = {}
	var coda: Array[int] = []
	for sorgente in sorgenti:
		if not costo.has(sorgente):
			costo[sorgente] = 0
			coda.append(sorgente)
	var testa := 0
	while testa < coda.size():
		var corrente: int = coda[testa]
		testa += 1
		var ci := corrente % colonne
		var cj := corrente / colonne
		for direzione in DIREZIONI:
			var ni := ci + direzione.x
			var nj := cj + direzione.y
			if ni < 0 or nj < 0 or ni >= colonne or nj >= file:
				continue
			var vicino := nj * colonne + ni
			if costo.has(vicino) or not dominio.has(vicino):
				continue
			costo[vicino] = int(costo[corrente]) + 1
			coda.append(vicino)
	return costo

func _sacche_isolate(mappa: PackedByteArray, colonne: int, file: int,
		raggiunto: Dictionary) -> Array:
	var viste: Dictionary = {}
	var sacche: Array = []
	for indice in range(mappa.size()):
		if mappa[indice] != 1 or raggiunto.has(indice) or viste.has(indice):
			continue
		var coda: Array[int] = [indice]
		viste[indice] = true
		var celle: Array[int] = []
		while not coda.is_empty():
			var corrente: int = coda.pop_back()
			celle.append(corrente)
			var ci := corrente % colonne
			var cj := corrente / colonne
			for direzione in DIREZIONI:
				var ni := ci + direzione.x
				var nj := cj + direzione.y
				if ni < 0 or nj < 0 or ni >= colonne or nj >= file:
					continue
				var vicino := nj * colonne + ni
				if viste.has(vicino) or mappa[vicino] != 1 or raggiunto.has(vicino):
					continue
				viste[vicino] = true
				coda.append(vicino)
		var somma := Vector2i.ZERO
		for cella in celle:
			somma += Vector2i(cella % colonne, cella / colonne)
		sacche.append({
			"area": float(celle.size()) * CELLA * CELLA,
			"centro": Vector2i(somma.x / celle.size(), somma.y / celle.size()),
		})
	sacche.sort_custom(func(a, b): return float(a["area"]) > float(b["area"]))
	return sacche

func _oggetti(mondo, chunks, comp: WorldCompositionData, livello: int) -> Array:
	var fuori: Array = []
	for evento_data in Array(mondo.get("mission_events")):
		var evento: Dictionary = evento_data
		fuori.append({
			"nome": "evento %s (%s/%s)" % [
				str(evento.get("id", "")), str(evento.get("kind", "")),
				str(evento.get("subject", ""))],
			"p": evento.get("position", Vector2.ZERO) as Vector2,
		})
	for edificio in Array(mondo.get("world_buildings")):
		if edificio is Node2D:
			fuori.append({
				"nome": "edificio %s" % str((edificio as Node2D).get_meta("building_role", "?")),
				"p": (edificio as Node2D).global_position,
			})
	for attore in Array(mondo.get("npc_actors")):
		if attore is Node2D:
			fuori.append({
				"nome": "abitante %s" % str((attore as Node2D).get_meta("npc_id", attore.name)),
				"p": (attore as Node2D).global_position,
			})
	for traccia in mondo.get_tree().get_nodes_in_group("mystery_artifact"):
		if traccia is Node2D and mondo.is_ancestor_of(traccia):
			fuori.append({
				"nome": "traccia %s" % str((traccia as Node2D).get_meta("id", traccia.name)),
				"p": (traccia as Node2D).global_position,
			})
	fuori.append({"nome": "rovina eroe", "p": mondo.call("_hero_landmark_position") as Vector2})
	var nave: Vector2 = Dictionary(mondo.get("world_profile").get("shipEntrance", {})).get(
		"position", Vector2.ZERO)
	fuori.append({"nome": "ingresso nave", "p": nave})
	fuori.append_array(_forzieri(mondo, chunks, comp))
	return fuori

## I forzieri non arrivano dalla scena (lo streaming e' a zero per non costruire
## mezzo mondo per ventiquattro volte): si rigenerano gli stessi chunk con la
## stessa catena del gioco — generatore, filtro di profilo, punto asciutto.
func _forzieri(mondo, chunks, comp: WorldCompositionData) -> Array:
	var elenco: Array = []
	var bordi: Rect2 = chunks.world_bounds()
	var dimensione := float(OutdoorChunkManager.CHUNK_SIZE)
	var da_x := floori(bordi.position.x / dimensione)
	var a_x := floori(bordi.end.x / dimensione)
	var da_y := floori(bordi.position.y / dimensione)
	var a_y := floori(bordi.end.y / dimensione)
	var seme := str(mondo.get("world_seed"))
	for cy in range(da_y, a_y + 1):
		for cx in range(da_x, a_x + 1):
			if not chunks.call("_chunk_intersects_playfield", chunks.call("_chunk_rect", cx, cy)):
				continue
			var grezzo: Dictionary = chunks.generator.generate_chunk(seme, cx, cy)
			var filtrato: Dictionary = chunks.call("_profile_filtered_chunk", grezzo)
			for forziere_data in filtrato.get("treasures", []):
				var forziere: Dictionary = forziere_data
				totali["forzieri"] = int(totali["forzieri"]) + 1
				var punto := Vector2(float(forziere["x"]), float(forziere["y"]))
				var asciutto := _punto_asciutto(comp, punto)
				if asciutto == Vector2.INF:
					totali["forzieri_saltati"] = int(totali["forzieri_saltati"]) + 1
					continue
				if asciutto != punto:
					totali["forzieri_spostati"] = int(totali["forzieri_spostati"]) + 1
				elenco.append({
					"nome": "forziere %s%s" % [
						str(forziere.get("id", "")),
						" [%s]" % str(forziere.get("requiredTool", "")) if str(
							forziere.get("requiredTool", "")) != "" else ""],
					"p": asciutto,
				})
	return elenco

func _punto_asciutto(comp: WorldCompositionData, punto: Vector2) -> Vector2:
	if comp == null or not _bagnato(comp, punto):
		return punto
	for raggio_data in [70.0, 130.0, 200.0]:
		var raggio := float(raggio_data)
		for passo in range(8):
			var candidato: Vector2 = punto + Vector2.RIGHT.rotated(TAU * float(passo) / 8.0) * raggio
			if not _bagnato(comp, candidato):
				return candidato
	return Vector2.INF

func _bagnato(comp: WorldCompositionData, punto: Vector2) -> bool:
	return comp.raw_water_weight(punto) >= 0.4 or comp.is_protected(punto, 40.0)
