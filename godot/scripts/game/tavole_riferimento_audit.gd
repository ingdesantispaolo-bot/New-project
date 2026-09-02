extends SceneTree

## **Nessuna domanda senza una tavola su cui impararla.** (1 settembre 2026)
##
## La guardia della richiesta del committente: «dobbiamo evitare che lo studente
## si trovi a rispondere a domande che non può conoscere senza avere riferimenti
## didattici dove apprendere».
##
## `teach_before_ask_audit` garantisce che ogni ARGOMENTO nuovo porti una
## lezione; `fact_level_teaching_audit` che gli ordinamenti a insieme insegnino i
## FATTI che pescano. Restava scoperto il caso più numeroso dei due banchi: la
## domanda di puro nome — «qual è la capitale della Norvegia?» — dove la lezione
## dell'argomento è vera, utile, e non contiene la risposta.
##
## Questo audit controlla quattro cose, in ordine di quanto costa ripararle:
##
##   1. **il materiale**: ogni risposta-nome dei banchi di storia e geografia sta
##      su una tavola, e ogni argomento dei due banchi ha almeno una tavola;
##   2. **le tavole tengono**: coordinata giusta per famiglia, nota che spiega,
##      etichette non ripetute, ancore di carta che esistono davvero, linee del
##      tempo in ordine cronologico;
##   3. **la scheda ha sostanza**: quello che NORA mostrerebbe passa lo stesso
##      esame di qualunque altra lezione (`lezione_ha_sostanza`);
##   4. **il percorso**: giocando davvero, un nodo che chiede un nome mai visto
##      arriva con l'estratto della tavola davanti.
##
## Uso: godot --headless --path godot --script res://scripts/game/tavole_riferimento_audit.gd

const VERDE := "TAVOLE RIFERIMENTO audit VERDE"
## **Il latino è entrato il 2 settembre 2026.** Storia e geografia avevano il
## difetto della domanda di NOME; il latino ha quello della domanda di FORMA —
## «che caso è *dominorum*?» — e una forma si può soltanto aver visto: non si
## deduce da niente. Le tavole `paradigma` sono la tabella che ogni libro di
## latino stampa nella prima pagina e che questo gioco non aveva mai mostrato.
const MATERIE := ["storia", "geografia", "latino"]

## Una nota che sta sotto questa soglia non spiega: ripete il titolo della voce.
const NOTA_MINIMA := 60

## Quante sessioni per livello nel controllo del percorso. Quaranta: ogni fatto
## si insegna una volta sola, quindi il campione cresce solo finché restano nomi
## nuovi da incontrare — sotto le quaranta sessioni se ne vedeva un terzo.
const SESSIONI := 40

var errori: Array = []
var misure: Array = []

func _fallisci(messaggio: String) -> void:
	if errori.size() < 40:
		errori.append(messaggio)

func _init() -> void:
	_ogni_domanda_di_nome_ha_la_sua_tavola()
	_ogni_argomento_ha_una_tavola()
	_le_capitali_degli_abbinamenti_stanno_sull_atlante()
	_le_tavole_tengono()
	_le_schede_hanno_sostanza()
	_il_percorso_mostra_la_tavola()

	for riga in misure:
		print("  %s" % str(riga))
	if errori.is_empty():
		print(VERDE)
	else:
		printerr("TAVOLE RIFERIMENTO audit ROSSO — %d problemi:" % errori.size())
		for e in errori:
			printerr("  - %s" % str(e))
	quit(0 if errori.is_empty() else 1)

## 1a. Il materiale. Si passa tutto il banco e si tiene solo ciò che il runtime
## tratterebbe come domanda di richiamo — la stessa regola di
## `KnowledgeCodex.recall_fact`, non una regola nuova inventata qui.
func _ogni_domanda_di_nome_ha_la_sua_tavola() -> void:
	var content := ContentManager.new()
	for materia in MATERIE:
		var totale := 0
		var coperti := 0
		var visti: Dictionary = {}
		for raw in content._load_bank(str(materia)):
			var item: Dictionary = raw
			var richiamo := KnowledgeCodex.recall_fact(item)
			if richiamo.is_empty():
				continue
			totale += 1
			var topic := str(item.get("topic", ""))
			var risposta := str(richiamo.get("label", ""))
			if TavoleRiferimento.copre(str(materia), topic, risposta):
				coperti += 1
				continue
			var chiave := "%s · «%s»" % [topic, risposta]
			if visti.has(chiave):
				continue
			visti[chiave] = true
			_fallisci("%s %s: nessuna tavola insegna questa risposta prima di chiederla" % [materia, chiave])
		if totale > 0:
			misure.append("%s · domande di nome coperte da una tavola: %d/%d (%.1f%%)" % [
				materia, coperti, totale, 100.0 * float(coperti) / float(totale)])

## 1b. Nessun argomento senza tavola: senza questo, aggiungere un topic nuovo ai
## banchi passerebbe in silenzio finché qualcuno non ci scrive una domanda di nome.
func _ogni_argomento_ha_una_tavola() -> void:
	var content := ContentManager.new()
	for materia in MATERIE:
		for topic_data in content.bank_topics(str(materia)):
			var topic := str(topic_data)
			if not TavoleRiferimento.ha_tavola(str(materia), topic):
				_fallisci("%s · «%s»: argomento del banco senza nessuna tavola di riferimento" % [materia, topic])

## 1c. **Le capitali, anche quelle che chiede solo l'abbinamento.**
##
## I banchi sono la superficie misurata, ma non l'unica: i minigiochi hanno
## contenuto proprio, e gli insiemi di `MinigameManager.MATCHING` arrivano a 49
## coppie Paese-capitale, ventiquattro delle quali nessun banco nomina.
##
## Si controlla QUESTA famiglia e non tutti gli abbinamenti, ed è una scelta con
## un motivo: le capitali sono il richiamo puro allo stato più concentrato — il
## 100% delle domande del loro argomento — e sono anche le uniche che l'atlante
## copre per intero oggi. Il resto (popoli e invenzioni, monumenti, catene
## montuose) è il debito dichiarato in `docs/PEDAGOGY.md`: circa 490 etichette
## scoperte, da pagare allargando le tavole.
func _le_capitali_degli_abbinamenti_stanno_sull_atlante() -> void:
	var totale := 0
	var coperte := 0
	var viste: Dictionary = {}
	for spec_data in Array(MinigameManager.MATCHING.get("geografia", [])):
		var spec: Dictionary = spec_data
		if str(spec.get("topic", "")) != "capitali":
			continue
		for coppia_data in Array(spec.get("pairs", [])) + Array(spec.get("pool", [])):
			for lato in Array(coppia_data):
				var etichetta := str(lato).strip_edges()
				if etichetta == "" or viste.has(etichetta):
					continue
				viste[etichetta] = true
				totale += 1
				if TavoleRiferimento.copre("geografia", "capitali", etichetta):
					coperte += 1
				else:
					_fallisci("geografia · capitali · «%s»: l'abbinamento la chiede e nessuna tavola la insegna" % etichetta)
	if totale > 0:
		misure.append("geografia · capitali degli abbinamenti sull'atlante: %d/%d (%.1f%%)" % [
			coperte, totale, 100.0 * float(coperte) / float(totale)])

## 2. Le tavole tengono.
func _le_tavole_tengono() -> void:
	var identificativi: Dictionary = {}
	for tavola_data in TavoleRiferimento.tutte():
		var tavola: Dictionary = tavola_data
		var id := str(tavola.get("id", ""))
		if id == "":
			_fallisci("una tavola senza identificativo")
			continue
		if identificativi.has(id):
			_fallisci("tavola «%s»: identificativo ripetuto" % id)
		identificativi[id] = true
		var kind := str(tavola.get("kind", ""))
		if not TavoleRiferimento.COORDINATA.has(kind):
			_fallisci("tavola «%s»: famiglia «%s» sconosciuta" % [id, kind])
			continue
		if Array(tavola.get("topics", [])).is_empty():
			_fallisci("tavola «%s»: non dichiara nessun argomento" % id)
		if str(tavola.get("titolo", "")).strip_edges() == "":
			_fallisci("tavola «%s»: senza titolo" % id)
		if str(tavola.get("come_si_legge", "")).strip_edges().length() < NOTA_MINIMA:
			_fallisci("tavola «%s»: il «come si legge» non spiega come si legge" % id)
		var map_id := str(tavola.get("mapId", ""))
		if map_id != "" and not MapGeometryCatalog.has_map(map_id):
			_fallisci("tavola «%s»: la carta «%s» non esiste nel runtime" % [id, map_id])
		var ancore: Array = MapGeometryCatalog.target_ids(map_id) if map_id != "" else []

		var etichette: Dictionary = {}
		var anno_precedente := -99999999
		var voci: Array = tavola.get("voci", [])
		if voci.size() < 3:
			_fallisci("tavola «%s»: %d voci, troppo poche per fare da riferimento" % [id, voci.size()])
		for voce_data in voci:
			var voce: Dictionary = voce_data
			var label := str(voce.get("label", "")).strip_edges()
			if label == "":
				_fallisci("tavola «%s»: una voce senza etichetta" % id)
				continue
			var chiave := TavoleRiferimento.normalizza(label)
			if etichette.has(chiave):
				_fallisci("tavola «%s»: l'etichetta «%s» compare due volte" % [id, label])
			etichette[chiave] = true
			if TavoleRiferimento.coordinata_di(tavola, voce) == "":
				_fallisci("tavola «%s» · «%s»: manca il campo «%s», cioè il posto della voce" % [
					id, label, str(TavoleRiferimento.COORDINATA[kind])])
			var nota := str(voce.get("nota", "")).strip_edges()
			if nota.length() < NOTA_MINIMA:
				_fallisci("tavola «%s» · «%s»: la nota è troppo corta per insegnare qualcosa (%d caratteri)" % [
					id, label, nota.length()])
			for risposta in Array(voce.get("risposte", [])):
				if str(risposta).strip_edges() == "":
					_fallisci("tavola «%s» · «%s»: una risposta dichiarata vuota" % [id, label])
			var regola := str(voce.get("regola", ""))
			if regola != "":
				var re := RegEx.new()
				if re.compile(regola) != OK:
					_fallisci("tavola «%s» · «%s»: la regola «%s» non compila" % [id, label, regola])
			var target := str(voce.get("target", ""))
			if target != "":
				if map_id == "":
					_fallisci("tavola «%s» · «%s»: dichiara un'ancora ma la tavola non dichiara una carta" % [id, label])
				elif not ancore.has(target):
					_fallisci("tavola «%s» · «%s»: l'ancora «%s» non esiste sulla carta «%s»" % [
						id, label, target, map_id])
			# La linea del tempo deve stare in ordine, o non è una linea: chi la
			# legge ricava le distanze dalla posizione, e una voce fuori posto
			# insegna una cronologia sbagliata senza dire niente di falso.
			if kind == TavoleRiferimento.KIND_LINEA and voce.has("anno"):
				var anno := int(voce["anno"])
				if anno < anno_precedente:
					_fallisci("tavola «%s» · «%s»: anno %d dopo %d, la linea del tempo non è in ordine" % [
						id, label, anno, anno_precedente])
				anno_precedente = anno
	var voci_totali := 0
	for t in TavoleRiferimento.tutte():
		voci_totali += Array((t as Dictionary).get("voci", [])).size()
	misure.append("tavole: %d, voci: %d" % [TavoleRiferimento.tutte().size(), voci_totali])

## 3. Quello che NORA mostrerebbe regge l'esame di qualunque altra lezione. È il
## controllo che impedisce di dichiarare una tavola e mostrarne un guscio.
func _le_schede_hanno_sostanza() -> void:
	for tavola_data in TavoleRiferimento.tutte():
		var tavola: Dictionary = tavola_data
		var subject := str(tavola.get("subject", ""))
		var topics: Array = tavola.get("topics", [])
		if topics.is_empty():
			continue
		var topic := str(topics[0])
		for voce_data in Array(tavola.get("voci", [])):
			var voce: Dictionary = voce_data
			var etichetta := str(voce.get("label", ""))
			var scheda := TavoleRiferimento.lezione(subject, topic, [etichetta], "")
			if scheda.is_empty():
				_fallisci("tavola «%s» · «%s»: la voce non è raggiungibile dal suo stesso argomento" % [
					str(tavola.get("id", "")), etichetta])
				continue
			if not KnowledgeCodex.lezione_ha_sostanza(scheda):
				_fallisci("tavola «%s» · «%s»: la scheda mostrata non ha sostanza" % [
					str(tavola.get("id", "")), etichetta])
			if not str(scheda.get("facts", "")).contains(etichetta):
				_fallisci("tavola «%s» · «%s»: l'estratto non contiene la voce cercata" % [
					str(tavola.get("id", "")), etichetta])

## 4. Il percorso: si gioca davvero, e ogni nodo che chiede un nome mai visto
## deve arrivare con la tavola davanti.
func _il_percorso_mostra_la_tavola() -> void:
	var gameplay := OutdoorGameplay.new()
	gameplay.content_manager = ContentManager.new()
	gameplay.game_save = GameSaveManager.new("user://tavole-riferimento-audit.json")
	var con_tavola := 0
	var senza_tavola := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var subject := str(ApparatusConfig.world_subject(level))
		if not MATERIE.has(subject):
			continue
		for giro in range(SESSIONI):
			# Seme dichiarato, non `null`. Un audit che sorteggia a caso misura
			# ogni volta un campione diverso: verde stamattina e rosso stasera
			# senza che nessuno abbia toccato niente, e chi lo incontra impara a
			# rilanciarlo invece di leggerlo. È la lezione pagata lo stesso giorno
			# su `gesto_audit`, dove un tetto congelato su un campione piccolo si
			# muoveva di quindici punti a contenuto fermo.
			var rng := RandomNumberGenerator.new()
			rng.seed = 4400 + level * 97 + giro
			var sessione: Dictionary = gameplay.content_manager.build_varied_mission(
				subject, level, 3, {}, rng,
				gameplay.game_save.mastery_of(subject),
				gameplay.game_save.topic_masteries(subject))
			var nodi: Array = sessione.get("nodes", [])
			if nodi.is_empty():
				continue
			# Chi era nuovo PRIMA della decorazione: dopo, la decorazione stessa
			# ha già marcato i fatti come noti e non si troverebbe più niente.
			#
			# **Si controlla NODO per nodo, non argomento per argomento.** La
			# prima versione teneva una lezione per argomento e ne perdeva una
			# quando due nodi della stessa sessione condividevano il topic: la
			# seconda sovrascriveva la prima e l'audit denunciava tre casi che
			# in gioco erano regolari. La scheda viaggia sul nodo, e va cercata lì.
			var attesi: Array = []
			for indice in range(nodi.size()):
				var nodo: Dictionary = nodi[indice]
				var topic := str(nodo.get("topic", ""))
				var richiamo := KnowledgeCodex.recall_fact(nodo)
				if richiamo.is_empty():
					continue
				var etichetta := str(richiamo.get("label", ""))
				if not TavoleRiferimento.copre(subject, topic, etichetta):
					continue
				if KnowledgeCodex.fact_known(gameplay.game_save, subject, topic, etichetta):
					continue
				attesi.append({"indice": indice, "topic": topic, "label": etichetta})
			sessione = gameplay._decorate_teaching_session(sessione, subject)
			var decorati: Array = sessione.get("nodes", [])
			for atteso_data in attesi:
				var atteso: Dictionary = atteso_data
				var decorato: Dictionary = decorati[int(atteso["indice"])]
				var lezione: Dictionary = decorato.get("teachingLesson", {})
				if lezione.has("tavolaId"):
					con_tavola += 1
					continue
				senza_tavola += 1
				_fallisci("%s livello %d · «%s»: chiede «%s» senza mostrare la tavola che lo insegna" % [
					subject, level, str(atteso["topic"]), str(atteso["label"])])
	var totale := con_tavola + senza_tavola
	if totale > 0:
		misure.append("percorso giocato · nomi nuovi presentati con la loro tavola: %d/%d (%.1f%%)" % [
			con_tavola, totale, 100.0 * float(con_tavola) / float(totale)])
	else:
		_fallisci("percorso giocato: nessun nodo di richiamo incontrato, il controllo non ha misurato niente")
