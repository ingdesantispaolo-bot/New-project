extends SceneTree

## **La logica si fa con le mani.** (1 settembre 2026)
##
## I due formati nati dallo studio sui contenuti di logica, e le proprietà che
## un generatore deve garantire ogni volta — non «di solito».
##
##   GRIGLIA   quattro nomi, quattro oggetti, qualche indizio. Si segnano le
##             caselle impossibili finché ne resta una per riga.
##   PORTE     la condizione è una lampada: per ognuno dei quattro casi si
##             decide se si accende.
##
## ## Le tre proprietà che non si vedono giocando
##
## 1. **La griglia ha una soluzione sola.** Una con due soluzioni non è più
##    difficile: è rotta. Il bambino ragiona bene, arriva a un'assegnazione
##    coerente con tutti gli indizi, e la verifica gli dice che ha sbagliato. È
##    il difetto peggiore possibile in un gioco che insegna a dedurre.
##
## 2. **Nessun indizio è di troppo.** Se togliendone uno la soluzione resta
##    unica, quell'indizio era rumore da leggere — e leggere non è dedurre. Il
##    generatore pota; qui si verifica che la potatura abbia funzionato.
##
## 3. **Nessun indizio regala una riga.** Un «Ada indossa il cappello rosso»
##    chiude una riga senza farla ragionare. Sono ammesse solo negazioni e
##    alternative: si toglie, non si consegna.
##
## Per le porte la proprietà è un'altra: i quattro casi devono esserci tutti,
## una volta ciascuno, e la tavola deve corrispondere a UNA delle porte
## dichiarate. Una tavola che non è nessuna porta insegnerebbe una regola che
## non esiste; una tutta accesa o tutta spenta si supera rispondendo sempre
## uguale.
##
## Uso: godot --headless --path godot --script res://scripts/game/logica_hands_on_audit.gd

const OK := "LOGICA HANDS ON audit VERDE"
const MATERIA := "logica"

## Quante costruzioni si provano per formato. Trecento: il generatore sorteggia
## scenario, permutazione e indizi, e con meno non si tocca ogni combinazione.
const PROVE := 300

var _fallimenti: Array = []


func _init() -> void:
	var manager := MinigameManager.new()
	_prova_griglia(manager)
	_prova_porte(manager)
	_prova_presenza_nel_percorso()

	if not _fallimenti.is_empty():
		printerr("LOGICA HANDS ON — %d problemi:" % _fallimenti.size())
		for riga in _fallimenti:
			printerr("  - %s" % str(riga))
		quit(1)
		return
	print(OK)
	quit(0)


func _guasto(messaggio: String) -> void:
	if _fallimenti.size() < 12:
		_fallimenti.append(messaggio)


# ---------------------------------------------------------------------------
# La griglia
# ---------------------------------------------------------------------------

func _prova_griglia(manager: MinigameManager) -> void:
	var indizi_totali := 0
	var lati: Dictionary = {}
	for prova in range(PROVE):
		var level := 1 + (prova % ApparatusConfig.MAX_LEVEL)
		var rng := RandomNumberGenerator.new()
		rng.seed = 51000 + prova
		var node := manager._griglia_node(MATERIA, level, prova % 3, rng, prova)

		var esito := ExerciseInteraction.validate(node)
		if not bool(esito.get("ok", false)):
			_guasto("griglia L%d non valida: %s" % [level, str(esito.get("errors", []))])
			continue

		var soggetti: Array = node.get("soggetti", [])
		var indizi: Array = node.get("indizi", [])
		lati[soggetti.size()] = true
		indizi_totali += indizi.size()

		# 2. Nessun indizio di troppo: toglierne uno deve riaprire il dubbio.
		for i in indizi.size():
			var ridotto := node.duplicate(true)
			var rimasti: Array = Array(indizi).duplicate()
			rimasti.remove_at(i)
			ridotto["indizi"] = rimasti
			if ExerciseInteraction._griglia_compatibili(ridotto) == 1:
				_guasto("griglia L%d: l'indizio %d non serve, la soluzione resta unica senza" % [
					level, i + 1])
				break

		# 3. Nessun indizio consegna una coppia: si toglie, non si dichiara.
		for indizio in indizi:
			var testo := str((indizio as Dictionary).get("text", ""))
			if not testo.contains(" non ") and not testo.contains("oppure"):
				_guasto("griglia L%d: indizio che dichiara direttamente una coppia — «%s»" % [
					level, testo])
				break

		# Senza indizi le soluzioni sono tante: se fossero già una, gli indizi
		# non servirebbero a niente e la griglia sarebbe un modulo da riempire.
		var nudo := node.duplicate(true)
		nudo["indizi"] = []
		if ExerciseInteraction._griglia_compatibili(nudo) <= 1:
			_guasto("griglia L%d: si chiude da sola anche senza indizi" % level)

	if lati.size() < 2:
		_guasto("la griglia esce sempre dello stesso lato: manca la progressione di difficoltà")
	print("griglia: %d costruzioni, lati %s, %.1f indizi in media" % [
		PROVE, str(lati.keys()), float(indizi_totali) / float(PROVE)])


# ---------------------------------------------------------------------------
# Le porte
# ---------------------------------------------------------------------------

func _prova_porte(manager: MinigameManager) -> void:
	var porte_viste: Dictionary = {}
	for prova in range(PROVE):
		var level := 1 + (prova % ApparatusConfig.MAX_LEVEL)
		var rng := RandomNumberGenerator.new()
		rng.seed = 61000 + prova
		var node := manager._porte_node(MATERIA, level, prova % 3, rng, prova)

		var esito := ExerciseInteraction.validate(node)
		if not bool(esito.get("ok", false)):
			_guasto("porta L%d non valida: %s" % [level, str(esito.get("errors", []))])
			continue

		var righe: Array = node.get("righe", [])
		var soluzione: Dictionary = node.get("soluzione", {})
		# Tutti e quattro i casi, una volta ciascuno.
		var combinazioni: Dictionary = {}
		for riga_data in righe:
			var riga: Dictionary = riga_data
			combinazioni["%s%s" % [bool(riga.get("a", false)), bool(riga.get("b", false))]] = true
		if combinazioni.size() != 4:
			_guasto("porta L%d: %d combinazioni distinte invece di quattro" % [level, combinazioni.size()])
			continue

		# La tavola deve essere UNA delle porte dichiarate, non una qualsiasi.
		var combacia := ""
		for regola_data in MinigameManager.PORTE_REGOLE:
			var regola: Dictionary = regola_data
			var id_regola := str(regola["id"])
			var tutte := true
			for riga_data in righe:
				var riga: Dictionary = riga_data
				var attesa := MinigameManager._porta_accende(
					id_regola, bool(riga.get("a", false)), bool(riga.get("b", false)))
				if bool(soluzione.get(str(riga.get("id", "")), false)) != attesa:
					tutte = false
					break
			if tutte:
				combacia = id_regola
				break
		if combacia == "":
			_guasto("porta L%d: la tavola non corrisponde a nessuna porta dichiarata" % level)
			continue
		porte_viste[combacia] = int(porte_viste.get(combacia, 0)) + 1

		# La spiegazione deve parlare di QUESTA porta, non dire una frase generica.
		if str(node.get("explanation", "")).strip_edges().length() < 80:
			_guasto("porta L%d (%s): spiegazione troppo corta per insegnare qualcosa" % [level, combacia])

	if porte_viste.size() < 4:
		_guasto("in %d costruzioni sono comparse solo %d porte diverse: la rotazione è povera" % [
			PROVE, porte_viste.size()])
	print("porte: %d costruzioni, %d porte diverse %s" % [
		PROVE, porte_viste.size(), str(porte_viste)])


# ---------------------------------------------------------------------------
# Ci arrivano davvero, giocando?
# ---------------------------------------------------------------------------

## Un formato che esiste e non compare mai è un formato che non esiste. I due
## mondi della logica sono il 12 e il 24: se lì una sessione di pratica non li
## incontra, il lavoro non è arrivato al bambino.
func _prova_presenza_nel_percorso() -> void:
	var content := ContentManager.new()
	for level in [12, 24]:
		var trovati: Dictionary = {}
		for ripetizione in range(24):
			var rng := RandomNumberGenerator.new()
			rng.seed = 71000 + level * 17 + ripetizione
			for node_data in content.minigame_manager.build_minigame(MATERIA, level, rng).get("nodes", []):
				trovati[str((node_data as Dictionary).get("format", ""))] = true
		for fmt in ["griglia", "porte"]:
			if not trovati.has(fmt):
				_guasto("mondo %d: la pratica di logica non propone mai «%s»" % [level, fmt])
		if not MinigameManager.runtime_formats_for(MATERIA, level).has("griglia"):
			_guasto("mondo %d: «griglia» fuori dai formati dichiarati della logica" % level)
		if not MinigameManager.runtime_formats_for(MATERIA, level).has("porte"):
			_guasto("mondo %d: «porte» fuori dai formati dichiarati della logica" % level)
