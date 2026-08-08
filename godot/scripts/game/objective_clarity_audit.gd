extends SceneTree

## **Il giocatore deve sapere che cosa fare.** (7 agosto 2026)
##
## Segnalazione del committente: «dobbiamo spiegare meglio al giocatore cosa deve
## fare, e cosa manca per passare di livello al mondo successivo».
##
## Il difetto non era la scrittura: il gate del livello chiede **dodici materie
## per tre condizioni**, e l'HUD ne mostrava due percentuali. Trentasei
## condizioni riassunte in due numeri non sono una spiegazione corta — sono una
## spiegazione assente.
##
## Questo audit protegge le due regole che rendono utile il rimedio, e sono
## regole di scrittura, non di codice:
##
##   1. **mai un numero senza un'azione**: ogni frase che il gioco mostra deve
##      contenere un verbo che si può eseguire. «Padronanza 34%» dice uno stato;
##      «rispondi bene a 4 prove» dice che cosa fare;
##   2. **una cosa alla volta**: il passo successivo nomina UN traguardo. Con
##      trentasei condizioni aperte, elencarle sarebbe onesto e inutile.
##
## E una terza, che è la garanzia di non mentire: quello che il quadro dice
## mancante deve coincidere con quello che il gate chiede davvero.

const OK := "OBJECTIVE CLARITY audit VERDE"

## I verbi con cui il gioco può dire a un bambino che cosa fare. Se una frase
## non ne contiene nessuno, molto probabilmente sta descrivendo invece di
## chiedere — ed è il difetto che stiamo riparando.
const VERBI := [
	"rispondi", "affronta", "recupera", "supera", "torna", "apri", "riaffronta",
	"manca", "mancano", "servono", "serve", "puoi", "ti aspetta", "hai",
]

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	if errori.size() < 30:
		errori.append(messaggio)

func _init() -> void:
	_ogni_frase_dice_che_cosa_fare()
	_il_passo_nomina_una_cosa_sola()
	_il_percorso_non_mente()
	_la_stima_e_utile()
	_niente_desinenze_incollate()
	if errori.is_empty():
		print(OK)
	else:
		printerr("OBJECTIVE CLARITY audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _con_verbo(frase: String) -> bool:
	var minuscola := frase.to_lower()
	for verbo in VERBI:
		if minuscola.contains(str(verbo)):
			return true
	return false

func _mondo(level: int) -> Dictionary:
	var save := GameSaveManager.new("user://objective-clarity-audit-%d.json" % level)
	save.data["level"] = level
	save.data["worlds"] = {"unlocked": range(1, level + 1), "current": level}
	var progression := ProgressionManager.new(save, ContentManager.new())
	return {"save": save, "progression": progression}

## Regola 1: ogni frase mostrata contiene un'azione eseguibile.
func _ogni_frase_dice_che_cosa_fare() -> void:
	for level in [1, 5, 12, 24]:
		var mondo := _mondo(level)
		var progression = mondo["progression"]
		var runtime := {
			"level": level,
			"focusSubject": str(ApparatusConfig.world_subject(level)),
			"apparatus": "nucleo",
			"ready": false,
			"complete": false,
		}
		var passo := ObjectiveBriefing.passo(runtime, progression)
		var azione := str(passo.get("azione", ""))
		if azione.strip_edges().is_empty():
			_fallisci("livello %d: il passo successivo non dice niente" % level)
			continue
		if not _con_verbo(azione):
			_fallisci("livello %d: «%s» descrive uno stato invece di chiedere un'azione" % [
				level, azione])
		if str(passo.get("titolo", "")).strip_edges().is_empty():
			_fallisci("livello %d: il passo successivo non ha un titolo" % level)
		# Anche l'esame, che è l'altro ramo.
		runtime["ready"] = true
		var passo_esame := ObjectiveBriefing.passo(runtime, progression)
		if not _con_verbo(str(passo_esame.get("azione", ""))):
			_fallisci("livello %d: il passo con l'esame pronto non dice che cosa fare" % level)
		if not str(passo_esame.get("dove", "")).strip_edges().length() > 0:
			_fallisci("livello %d: l'esame non dice DOVE andare" % level)

## Regola 2: una cosa alla volta. Il passo successivo non può essere un elenco.
func _il_passo_nomina_una_cosa_sola() -> void:
	for level in [1, 8, 20]:
		var mondo := _mondo(level)
		var runtime := {
			"level": level,
			"focusSubject": str(ApparatusConfig.world_subject(level)),
			"apparatus": "nucleo", "ready": false, "complete": false,
		}
		var azione := str(ObjectiveBriefing.passo(runtime, mondo["progression"]).get("azione", ""))
		# Tre virgole o più: è diventato un elenco, e un elenco non si esegue.
		if azione.count(",") >= 3:
			_fallisci("livello %d: il passo elenca invece di indicare — «%s»" % [level, azione])
		# Due frasi bastano; oltre, nell'HUD non ci sta e non si legge.
		if azione.length() > 160:
			_fallisci("livello %d: passo troppo lungo per l'HUD (%d caratteri)" % [
				level, azione.length()])

## Regola 3: il quadro non mente. Le materie che dichiara mancanti sono
## esattamente quelle che il gate considera mancanti — e ognuna dice perché.
func _il_percorso_non_mente() -> void:
	for level in [1, 12]:
		var mondo := _mondo(level)
		var progression = mondo["progression"]
		var percorso := ObjectiveBriefing.percorso(progression)
		var stato: Dictionary = progression.readiness()
		var mancanti: Array = Array(stato.get("missing", []))
		var righe: Array = percorso.get("righe", [])
		if righe.size() != ApparatusConfig.SUBJECT_CYCLE.size():
			_fallisci("livello %d: il quadro mostra %d materie invece di %d" % [
				level, righe.size(), ApparatusConfig.SUBJECT_CYCLE.size()])
		var aperte := 0
		for raw in righe:
			var riga: Dictionary = raw
			if bool(riga.get("fatto", false)):
				continue
			aperte += 1
			if not mancanti.has(str(riga.get("materia", ""))):
				_fallisci("livello %d: «%s» risulta da fare nel quadro ma il gate la dà chiusa" % [
					level, riga.get("materia", "")])
			var manca := str(riga.get("manca", ""))
			if manca.strip_edges().is_empty() or not _con_verbo(manca):
				_fallisci("livello %d · %s: «%s» non dice che cosa fare" % [
					level, riga.get("materia", ""), manca])
		if aperte != mancanti.size():
			_fallisci("livello %d: il quadro dà %d materie aperte, il gate %d" % [
				level, aperte, mancanti.size()])
		# Le materie già in linea restano nell'elenco: vedere quello che si è
		# chiuso è metà della motivazione.
		if righe.size() - aperte != percorso.get("fatte", -1):
			_fallisci("livello %d: il conteggio delle materie chiuse non torna" % level)
		var riassunto := ObjectiveBriefing.riassunto(percorso)
		if not riassunto.contains(str(ApparatusConfig.SUBJECT_CYCLE.size())):
			_fallisci("livello %d: il riassunto non dice su quante materie si è" % level)

## **Le frasi esatte, singolare e plurale.** (7 agosto 2026)
##
## Regola nata da un errore vero, trovato leggendo il testo e non
## controllandolo: componendo «nuovo» + «i» per il plurale usciva «argomenti
## nuovoi». Nessuno degli altri controlli se ne era accorto — passavano tutti,
## perché la frase conteneva un verbo ed era della lunghezza giusta.
##
## Il primo tentativo di rimedio cercava sequenze di vocali «impossibili». Era
## sbagliato due volte: «Hai» e «Sei» sono parole italiane normali, e indovinare
## la morfologia di una lingua con un elenco di digrammi non funziona.
##
## Qui si fa la cosa precisa: si confrontano le frasi con quelle **attese, per
## esteso**. Un confronto esatto non ha falsi allarmi e non lascia passare niente
## — e quando una frase cambia apposta, si aggiorna qui, che è il posto in cui si
## rilegge quello che il bambino leggerà.
func _niente_desinenze_incollate() -> void:
	var attese := [
		[{"topicsOverdue": 1, "topicsSeen": 0, "topicsTarget": 0, "mastery": 1.0, "masteryThreshold": 0.5},
			"Hai 1 ripasso da recuperare: riaffrontali."],
		[{"topicsOverdue": 3, "topicsSeen": 0, "topicsTarget": 0, "mastery": 1.0, "masteryThreshold": 0.5},
			"Hai 3 ripassi da recuperare: riaffrontali."],
		[{"topicsOverdue": 0, "topicsSeen": 0, "topicsTarget": 1, "mastery": 1.0, "masteryThreshold": 0.5},
			"Ti manca 1 argomento nuovo da affrontare (0 su 1 fatti)."],
		[{"topicsOverdue": 0, "topicsSeen": 1, "topicsTarget": 3, "mastery": 1.0, "masteryThreshold": 0.5},
			"Ti mancano 2 argomenti nuovi da affrontare (1 su 3 fatti)."],
		[{"topicsOverdue": 0, "topicsSeen": 3, "topicsTarget": 3, "mastery": 0.38, "masteryThreshold": 0.40},
			"Sei al 38% e serve il 40%: circa 1 prova da superare."],
		[{"topicsOverdue": 0, "topicsSeen": 3, "topicsTarget": 3, "mastery": 0.30, "masteryThreshold": 0.40},
			"Sei al 30% e serve il 40%: circa 3 prove da superare."],
		[{"topicsOverdue": 0, "topicsSeen": 3, "topicsTarget": 3, "mastery": 0.90, "masteryThreshold": 0.40},
			"Fatto: questa materia è in linea."],
	]
	for coppia in attese:
		var stato: Dictionary = coppia[0]
		var atteso := str(coppia[1])
		var ottenuto := ObjectiveBriefing.frase_di_stato(stato, false)
		if ottenuto != atteso:
			_fallisci("frase diversa da quella attesa:
      atteso:   %s
      ottenuto: %s" % [
				atteso, ottenuto])

## La stima in prove: deve crescere con la distanza, ed essere zero quando si è
## già arrivati. Una stima che dice «1 prova» a metà strada sarebbe peggio del
## silenzio — promette una cosa breve e ne consegna una lunga.
func _la_stima_e_utile() -> void:
	if ObjectiveBriefing.prove_stimate(0.5, 0.4) != 0:
		_fallisci("chi ha già superato la soglia si sente chiedere altre prove")
	if ObjectiveBriefing.prove_stimate(0.4, 0.4) != 0:
		_fallisci("chi è esattamente alla soglia si sente chiedere altre prove")
	var vicino := ObjectiveBriefing.prove_stimate(0.38, 0.40)
	var lontano := ObjectiveBriefing.prove_stimate(0.05, 0.40)
	if vicino < 1:
		_fallisci("a un passo dalla soglia la stima dice zero prove")
	if lontano <= vicino:
		_fallisci("la stima non cresce con la distanza dalla soglia")
	if lontano > 20:
		_fallisci("la stima dice %d prove: un numero così non motiva, scoraggia" % lontano)
