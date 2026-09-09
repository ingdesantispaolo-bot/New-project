extends SceneTree

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## **L'inglese ha casa in due mondi soli, e stanno a inizio fascia.**
## (9 settembre 2026)
##
## Con dodici materie su ventiquattro mondi l'inglese e' materia di casa al
## mondo 4 (fascia 2) e al mondo 16 (fascia 6) — in entrambi i casi il PRIMO dei
## tre livelli della fascia. Ne segue una cosa che non si vede leggendo il
## codice: una ricetta con `minLevel` a meta' fascia non la incontra mai.
##
## Misurato prima di ripararlo: delle 61 ricette d'inglese di `MinigameManager`
## il mondo 4 ne vedeva **15**, tutte di lessico, perche' ogni ricetta di
## grammatica aveva `minLevel` 5 o 6 — un mondo troppo tardi. La grammatica
## arrivava alle mani solo come ordine delle parole e ortografia, e sulla carta
## come **due nodi su millesettecento**: la quota `LESSON_TOPIC_SHARE` tirava
## verso i topic della lezione, e la lezione del mondo 4 prometteva solo lessico.
##
## Questo audit tiene insieme le quattro cose che hanno sbloccato la materia, e
## nessuna delle quattro regge senza le altre:
##
##   1. **nessun gate a meta' fascia**: ogni `minLevel` d'inglese sta all'inizio
##      della sua fascia (1, 4, 7, 10, 13, 16, 19, 22);
##   2. **la lezione nomina cio' che il mondo chiede**: ogni argomento promesso
##      da un mondo d'inglese ha una ricetta giocabile in quel mondo;
##   3. **la grammatica del programma si tocca**: ogni argomento di grammatica
##      del banco ha almeno una ricetta dentro la propria finestra di fasce;
##   4. **i numeri vissuti sono un cricchetto**: salgono, non scendono.
##
## Uso: node scripts/run-godot-audits.mjs inglese_minigiochi

## Otto ripetizioni per ciascuno di quattro PIANI di eventi diversi. I piani
## contano quanto le ripetizioni: `MissionEventDirector` decide da un seme quante
## tappe, enigmi e pratiche ha il mondo, e la quota di gesto cambia di dieci punti
## fra un piano con due pratiche e uno con una. Misurare un piano solo e' il
## cricchetto tarato sul seme di `gesto_audit`, gia' pagato una volta.
const RIPETIZIONI := 8
const PIANI := 4

## Inizi di fascia: gli unici `minLevel` ammessi (0 vale «da sempre»).
const INIZI_FASCIA := [1, 4, 7, 10, 13, 16, 19, 22]

## La grammatica del programma di `scripts/banks/inglese-programma.mjs`. Sono gli
## argomenti che non si possono imparare guardando: vanno costruiti, smistati o
## corretti almeno una volta con le mani.
const GRAMMATICA := [
	"to-be", "have-got", "articles", "plurals", "pronouns", "there-is",
	"third-person", "do-does", "present-continuous", "possessives", "prepositions",
	"quantifiers", "modals", "past-tense", "irregular-past", "past-continuous",
	"present-perfect", "future", "comparatives", "question", "relatives",
	"phrasal-verbs", "word-family", "conditionals", "passive", "past-perfect",
	"reported-speech", "gerund-infinitive", "linkers",
]

## Misurato il 9 settembre 2026, dopo il rifornimento. Come il pavimento di
## `pratica_perimetro_audit` questi numeri possono solo salire: chi alza un
## `minLevel`, restringe una lezione o toglie una ricetta trova rosso qui invece
## che in `variety_audit` fra una settimana.
##
## I due mondi hanno pavimenti diversi perche' sono mondi diversi: il 4 e' il
## primo incontro con la materia e tiene ancora meta' sessione sul lessico, il 16
## e' il mondo in cui la grammatica E' il programma. Misura di oggi: mondo 4 al
## 45,5% con 12 argomenti, mondo 16 al 59,0% con 28. La quota era due punti piu'
## alta prima che i nove campi di lessico (food-shopping, body-health,
## digital-media…) ricevessero anch'essi una forma da toccare: la grammatica non
## ha perso nodi, ne ha guadagnati il lessico. Il pavimento sta appena sotto la
## misura, mai sopra.
const PAVIMENTO := {
	4: {"ricette": 51, "grammatica_mani": 0.43, "argomenti_mani": 12},
	16: {"ricette": 110, "grammatica_mani": 0.57, "argomenti_mani": 27},
}

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	var content := ContentManager.new()
	_test_gate_a_inizio_fascia()
	_test_grammatica_ha_una_forma(content)
	_test_nessun_argomento_orfano(content)
	_test_lezione_giocabile()
	_test_spiegazioni_rinumerabili()
	_test_esperienza_vissuta(content)

	if not errori.is_empty():
		print("INGLESE MINIGIOCHI audit ROSSO:")
		for e in errori:
			print("  - %s" % str(e))
		quit(1)
		return
	print("INGLESE MINIGIOCHI audit VERDE — gate a inizio fascia, grammatica giocabile, lezione servita")
	quit(0)

## 1. Nessun gate a meta' fascia. Un `minLevel` 5 o 6 e' contenuto scritto e mai
## incontrato: il solo mondo d'inglese di quella fascia e' il 4.
func _test_gate_a_inizio_fascia() -> void:
	var fuori: Array = []
	for fmt_data in MinigameManager.FORMATS:
		var fmt := str(fmt_data)
		for spec_data in Array(MinigameManager.table_for(fmt).get("inglese", [])):
			var spec: Dictionary = spec_data
			var min_level := int(spec.get("minLevel", 0))
			if min_level != 0 and not INIZI_FASCIA.has(min_level):
				fuori.append("%s/%s: minLevel %d (fascia %d, che comincia al mondo %d)" % [
					fmt, str(spec.get("topic", "?")), min_level,
					ContentManager.target_difficulty(min_level),
					(ContentManager.target_difficulty(min_level) - 1) * 3 + 1])
	_controlla(fuori.is_empty(), "gate a meta' fascia: %s" % ", ".join(PackedStringArray(fuori)))

## 2. Ogni argomento di grammatica del banco ha una ricetta DENTRO la finestra di
## fasce in cui il banco lo colloca. Una ricetta di fascia 8 su un argomento che
## il banco chiude alla 4 non serve a niente: quel mondo non esiste.
func _test_grammatica_ha_una_forma(content: ContentManager) -> void:
	var fasce_banco: Dictionary = {}
	for item_data in content._load_bank("inglese"):
		var item: Dictionary = item_data
		var topic := str(item.get("topic", ""))
		var d := clampi(int(item.get("difficulty", 1)), 1, ContentManager.DIFFICULTY_BANDS)
		var info: Dictionary = fasce_banco.get(topic, {"min": 9, "max": 0})
		info["min"] = mini(int(info["min"]), d)
		info["max"] = maxi(int(info["max"]), d)
		fasce_banco[topic] = info

	var per_topic: Dictionary = {}   # topic -> Array[fascia della ricetta]
	for fmt_data in MinigameManager.FORMATS:
		for spec_data in Array(MinigameManager.table_for(str(fmt_data)).get("inglese", [])):
			var spec: Dictionary = spec_data
			var topic := str(spec.get("topic", ""))
			var fasce: Array = per_topic.get(topic, [])
			fasce.append(ContentManager.target_difficulty(maxi(1, int(spec.get("minLevel", 0)))))
			per_topic[topic] = fasce
	# Il decodificatore dei verbi non ha specifiche in tabella: i suoi casi
	# portano la fascia nel campo `tier`, e vanno contati come tutti gli altri.
	for caso_data in MinigameManager._verb_decoder_templates_inglese():
		var caso: Dictionary = caso_data
		var topic := str(caso.get("topic", ""))
		var fasce: Array = per_topic.get(topic, [])
		fasce.append(clampi(int(caso.get("tier", 1)), 1, ContentManager.DIFFICULTY_BANDS))
		per_topic[topic] = fasce

	print("")
	print("ARGOMENTO             BANCO   RICETTE (fasce)")
	var scoperti: Array = []
	for topic_data in GRAMMATICA:
		var topic := str(topic_data)
		if not fasce_banco.has(topic):
			continue   # argomento del solo catalogo interattivo: non lo giudica questo audit
		var banco: Dictionary = fasce_banco[topic]
		var fasce: Array = per_topic.get(topic, [])
		fasce.sort()
		print("%-20s  %d-%d     %s" % [topic, int(banco["min"]), int(banco["max"]),
			str(fasce) if not fasce.is_empty() else "NESSUNA"])
		var dentro := false
		for fascia in fasce:
			if int(fascia) <= int(banco["max"]):
				dentro = true
		if not dentro:
			scoperti.append("%s (banco fasce %d-%d, ricette %s)" % [
				topic, int(banco["min"]), int(banco["max"]),
				str(fasce) if not fasce.is_empty() else "nessuna"])
	_controlla(scoperti.is_empty(),
		"grammatica senza una forma da toccare dentro la sua fascia: %s" % ", ".join(PackedStringArray(scoperti)))

## 2-bis. **Nessun argomento del banco resta senza una forma da toccare.**
## Il 9 settembre 2026 erano 27 su 47 — fra cui to be, have got e i pronomi, cioe'
## tutto cio' con cui la lingua comincia. E' un assoluto e non un cricchetto:
## un argomento che l'esame chiede e la pratica non sa far toccare e' contenuto
## scritto e mai collegato, la voce G-C4 di `insieme.md` letta dall'altro verso.
func _test_nessun_argomento_orfano(content: ContentManager) -> void:
	var con_ricetta: Dictionary = {}
	for fmt_data in MinigameManager.FORMATS:
		for spec_data in Array(MinigameManager.table_for(str(fmt_data)).get("inglese", [])):
			con_ricetta[str((spec_data as Dictionary).get("topic", ""))] = true
	for caso_data in MinigameManager._verb_decoder_templates_inglese():
		con_ricetta[str((caso_data as Dictionary).get("topic", ""))] = true
	var orfani: Dictionary = {}
	for item_data in content._load_bank("inglese"):
		var topic := str((item_data as Dictionary).get("topic", ""))
		if not con_ricetta.has(topic):
			orfani[topic] = true
	var elenco: Array = orfani.keys()
	elenco.sort()
	_controlla(elenco.is_empty(),
		"argomenti del banco che si possono solo crocettare: %s" % ", ".join(PackedStringArray(elenco)))

## 3. Quello che la lezione promette si deve poter GIOCARE in quel mondo, non
## solo crocettare. Vale per il lessico quanto per la grammatica: e' la lezione
## a tirare due nodi su tre.
func _test_lezione_giocabile() -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if ApparatusConfig.world_subject(level) != "inglese":
			continue
		var lezione := ContentManager.lesson_topic_set("inglese", level)
		var giocabili: Dictionary = {}
		for fmt_data in MinigameManager.runtime_formats_for("inglese", level):
			for spec_data in MinigameManager.eligible_specs("inglese", str(fmt_data), level):
				giocabili[str((spec_data as Dictionary).get("topic", ""))] = true
		for caso_data in MinigameManager._verb_decoder_templates_inglese():
			var caso: Dictionary = caso_data
			if int(caso.get("tier", 1)) <= ContentManager.target_difficulty(level):
				giocabili[str(caso.get("topic", ""))] = true
		var mancanti: Array = []
		for topic in lezione.keys():
			if not giocabili.has(str(topic)):
				mancanti.append(str(topic))
		mancanti.sort()
		_controlla(mancanti.is_empty(),
			"mondo %d: la lezione promette %s, ma al mondo non c'e' nessuna ricetta che li faccia toccare" % [
				level, ", ".join(PackedStringArray(mancanti))])

## 4. Le spiegazioni della caccia all'errore con righe rimescolate DEVONO aprire
## con «Riga N»: e' l'unica forma che `_renumber_explanation` sa correggere.
## Cinque ricette d'inglese aprivano con «Line N» e dopo il rimescolamento
## indicavano una riga innocente — insegnare la cosa sbagliata e' peggio
## dell'errore da trovare. Vale per tutte e dodici le materie.
func _test_spiegazioni_rinumerabili() -> void:
	var storte: Array = []
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		for spec_data in Array(MinigameManager.CODE_DEBUG.get(subject, [])):
			var spec: Dictionary = spec_data
			if not bool(spec.get("shuffleLines", false)):
				continue
			if not str(spec.get("explanation", "")).begins_with("Riga "):
				storte.append("%s/%s" % [subject, str(spec.get("topic", "?"))])
	_controlla(storte.is_empty(),
		"caccia all'errore rimescolata con spiegazione non rinumerabile (non apre con «Riga N»): %s" % ", ".join(PackedStringArray(storte)))

## 5. I numeri vissuti nei due mondi d'inglese. Non contano le ricette scritte:
## conta quello che l'ExercisePlayer riceve davvero giocando il mondo.
func _test_esperienza_vissuta(content: ContentManager) -> void:
	print("")
	print("MONDO  RICETTE  NODI   GRAMMATICA A MANI  ARGOMENTI A MANI")
	for level_data in PAVIMENTO.keys():
		var level := int(level_data)
		var pavimento: Dictionary = PAVIMENTO[level]
		var ricette := 0
		for fmt in MinigameManager.runtime_formats_for("inglese", level):
			ricette += MinigameManager.eligible_specs("inglese", str(fmt), level).size()
		_controlla(ricette >= int(pavimento["ricette"]),
			"mondo %d: %d ricette d'inglese, sotto il pavimento di %d" % [level, ricette, int(pavimento["ricette"])])

		var profile := WorldProfileCatalog.profile(level)
		var mani := 0
		var totale := 0
		var argomenti: Dictionary = {}
		for piano in range(PIANI):
			var events := MissionEventDirector.plan(profile, {}, "audit-inglese-%d-%d" % [level, piano])
			for repeat in range(RIPETIZIONI):
				var rng := RandomNumberGenerator.new()
				rng.seed = 4400 + level * 37 + piano * 911 + repeat
				var sessioni: Array = []
				for event in events:
					var kind := str((event as Dictionary).get("kind", "mission"))
					if kind == "enigma":
						sessioni.append(content.build_enigma("inglese", level, 4, {}, rng))
					elif kind == "practice":
						sessioni.append(content.minigame_manager.build_minigame("inglese", level, rng))
					else:
						sessioni.append(content.build_varied_mission("inglese", level, 3, {}, rng))
				sessioni.append(content.build_final_exam("inglese", level, 3, rng))
				for sessione in sessioni:
					for node_data in Array((sessione as Dictionary).get("nodes", [])):
						var node: Dictionary = node_data
						if str(node.get("subject", "")) != "inglese":
							continue
						totale += 1
						var fmt := ExerciseInteraction.format_of(node)
						var carta := fmt == "multiple_choice" or fmt == "short_answer"
						if carta or not GRAMMATICA.has(str(node.get("topic", ""))):
							continue
						mani += 1
						argomenti[str(node.get("topic", ""))] = true
		var quota := float(mani) / float(maxi(1, totale))
		print("%5d  %7d  %4d  %16.1f%%  %16d" % [level, ricette, totale, quota * 100.0, argomenti.size()])
		_controlla(quota >= float(pavimento["grammatica_mani"]),
			"mondo %d: grammatica toccata con le mani al %.1f%%, sotto il pavimento del %.0f%%" % [
				level, quota * 100.0, float(pavimento["grammatica_mani"]) * 100.0])
		_controlla(argomenti.size() >= int(pavimento["argomenti_mani"]),
			"mondo %d: solo %d argomenti di grammatica toccati con le mani, sotto il pavimento di %d" % [
				level, argomenti.size(), int(pavimento["argomenti_mani"])])
