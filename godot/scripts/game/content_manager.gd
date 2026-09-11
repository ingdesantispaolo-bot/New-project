class_name ContentManager
extends RefCounted

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## Carica i banchi di esercizi (JSON prodotti da scripts/build-exercise-banks.mjs)
## e costruisce le missioni selezionando item vicini alla difficoltà del livello.
## Vedi docs/ARCHITETTURA_FULL_GODOT.md §3 (strategia "bake prima, port poi").

## Ritmo cognitivo della materia (decisione didattica): le materie di RAGIONAMENTO
## non hanno mai limite di tempo — il bambino deve poter pensare senza pressione.
## Solo la matematica (tabelline) è "fluency", una competenza di rapidità/automatismo
## e l'unica per cui un tempo avrebbe senso didattico. Oggi NESSUNA materia è
## cronometrata (l'ExercisePlayer è turn-based): questa classificazione garantisce
## che, se mai si introdurrà un tempo su una fluency, il ragionamento resti esente,
## e alimenta l'affordance "senza limite di tempo" mostrata all'utente.
const PACE_REASONING := "reasoning"
const PACE_FLUENCY := "fluency"
const SUBJECT_PACE := {
	"matematica": PACE_FLUENCY,
	"italiano": PACE_REASONING,
	"inglese": PACE_REASONING,
	"coding": PACE_REASONING,
	"fisica": PACE_REASONING,
	"musica": PACE_REASONING,
	"latino": PACE_REASONING,
	"elettronica": PACE_REASONING,
	"geografia": PACE_REASONING,
	"scienze": PACE_REASONING,
	"storia": PACE_REASONING,
	"logica": PACE_REASONING,
}

# Ritmo della materia (default: ragionamento, cioè senza tempo — la scelta prudente
# per ogni materia nuova finché non è deliberatamente marcata "fluency").
## L'esame finale: quanti nodi e quale quota per passarlo.
const EXAM_NODES := 5
## Per passare: tre quarti. Su quattro nodi significa un errore concesso; un
## esame che non perdona nulla misura la tensione, non la competenza.
const EXAM_PASS_RATIO := 0.75
## Quanti nodi dell'esame vengono portati fuori dalla scelta multipla. Vedi la
## nota estesa in `build_final_exam`.
const EXAM_NON_MC_RATIO := 0.7

## Venti prove permettono una composizione intera 10/7/3: esattamente
## 50% / 35% / 15%, senza dover consumare la tolleranza disponibile.
const PRIORITY_EXAM_NODES := 20
const PRIORITY_EXAM_COUNTS := {1: 10, 2: 7, 3: 3}

## L'esame è ora multi-materia: il mix dei gesti non dipende più dalla materia
## che ospita il mondo. Elettronica conserva comunque domande dirette nei SUOI
## nodi (vedi la selezione in `build_final_exam`).
const EXAM_NON_MC_PER_MATERIA := {}

static func exam_non_mc_ratio(subject: String) -> float:
	return float(EXAM_NON_MC_PER_MATERIA.get(subject, EXAM_NON_MC_RATIO))

static func subject_pace(subject: String) -> String:
	return str(SUBJECT_PACE.get(subject, PACE_REASONING))

# Vero se la materia NON deve mai avere limite di tempo (tutte tranne le fluency).
static func is_untimed(subject: String) -> bool:
	return subject_pace(subject) != PACE_FLUENCY

## **La fluency è una proprietà dell'ARGOMENTO, non della materia.** (5 agosto 2026)
##
## Fino a oggi la regola era per materia: la matematica poteva essere
## cronometrata, tutte le altre no. È una semplificazione che regge finché il
## gioco misura solo il ragionamento — ma dentro una materia di ragionamento
## esistono automatismi veri. Coniugare «loro corrono» o riconoscere «un'amica»
## non è ragionare: è sapere o non sapere, e la velocità *è* la misura. Al
## contrario l'analisi logica non diventa fluency nemmeno in matematica.
##
## Serve a distinguere dove il cronometro insegna qualcosa da dove fa solo
## ansia. Un argomento non elencato qui resta senza tempo: è la scelta prudente,
## come lo era il ritmo di default per le materie nuove.
const FLUENCY_TOPICS := {
	"matematica": ["tabelline", "calcolo", "multipli", "frazioni", "percentuali", "potenze", "numeri"],
	# Nota: «analisi-grammaticale» è stata tolta da qui. Riconoscere che «gatto»
	# è un nome sembra automatico, ma il confine con l'analisi vera è sottile e
	# la scelta prudente vale più della copertura: un argomento in dubbio resta
	# senza tempo.
	"italiano": ["verbo", "ortografia", "tempi-indicativo", "modi-verbali"],
	"inglese": [
		"irregular-past", "irregular-plural", "contractions", "vocabolario",
		"opposites", "false-friends", "present-perfect",
	],
	"latino": ["declinazioni-base", "declinazione-2m", "verbo-sum", "vocabolario", "casi"],
	"musica": ["note", "ritmo", "lettura"],
	"geografia": ["capitali", "continenti"],
	"elettronica": ["misure-elettriche", "componenti"],
	"scienze": ["classi", "corpo"],
	"logica": ["sequenze", "analogie"],
	"storia": ["cronologia"],
	"coding": ["tipi", "operatori"],
	"fisica": ["misure"],
}

## Vero se su questo argomento il cronometro misura una competenza reale.
static func is_fluency_topic(subject: String, topic: String) -> bool:
	return Array(FLUENCY_TOPICS.get(subject, [])).has(topic)

const BANKS := {
	"matematica": "res://data/banks/matematica-tabelline.json",
	"italiano": "res://data/banks/italiano-base.json",
	"inglese": "res://data/banks/inglese-base.json",
	"coding": "res://data/banks/coding-base.json",
	"fisica": "res://data/banks/fisica-base.json",
	"musica": "res://data/banks/musica-base.json",
	"latino": "res://data/banks/latino-base.json",
	"elettronica": "res://data/banks/elettronica-base.json",
	# Materie nuove (scope ampliato 2026-07-21). La difficoltà è tarata sul
	# LIVELLO (target_difficulty) come tutte le altre: nessun tetto per anno
	# scolastico (guardrail per livello raggiunto, non per età).
	"geografia": "res://data/banks/geografia-base.json",
	"scienze": "res://data/banks/scienze-base.json",
	"storia": "res://data/banks/storia-base.json",
	"logica": "res://data/banks/logica-base.json",
}

## Il corso di fisica non coincide con tutto ciò che esiste nel banco.
##
## Un bambino di dieci anni non deve incontrare per caso rifrazione, incertezza
## sperimentale o passaggi di stato dentro un mondo che ha appena insegnato moto
## e leve. Questi sono i sei nuclei effettivamente introdotti nei mondi 5 e
## 17; ogni domanda ordinaria e l'esame finale di fisica restano entro questo
## perimetro. Gli altri contenuti rimangono nel Manuale per futuri mondi.
const PHYSICS_CURRICULUM_TOPICS := [
	"moto", "forze", "leve",
	"pressione", "galleggiamento", "correnti",
]

## Materie in cui i due mondi sono un corso, non una semplice vetrina del banco.
##
## In musica il catalogo contiene anche chiavi, alterazioni, compositori, tempi e
## armonia avanzata. Sono contenuti validi, ma non sono prerequisiti impliciti di
## un bambino al primo incontro: una missione può chiedere soltanto i topic che
## la lezione del mondo dichiara e che NORA presenta prima del relativo nodo.
const STRICT_LESSON_SUBJECTS := ["fisica", "musica"]

var _cache: Dictionary = {}  # subject -> Array item
var _difficulty_ranges: Dictionary = {}  # subject -> Vector2i(min,max) difficoltà nel banco
var _topic_counts: Dictionary = {}  # subject -> int argomenti distinti (cache copertura)
var _recent_math_signatures: Array = []

## Finestra anti-ripetizione delle prove NON a scelta multipla. Ampia quanto basta
## a coprire una manciata di missioni consecutive: è lì che la ripetizione si nota.
const RECENT_NODE_WINDOW := 24
var _recent_node_signatures: Array = []
# Sorgente di nodi NON a scelta multipla (abbina/ordina) per diversificare i
# formati (O-P3, policy "scelta multipla non dominante") ed esami multi-formato.
var minigame_manager := MinigameManager.new()
var _mission_serial := 0

## Le prove GIÀ SUPERATE dallo studente: {materia: {impronta: true}}.
##
## Vuoto significa «nessuna memoria», ed è il comportamento di prima: gli audit e
## le sonde che costruiscono missioni senza un save continuano a vedere l'intero
## banco. Il percorso vivo ci mette l'indice del salvataggio (`solved_index()`),
## che è un oggetto stabile aggiornato in casa sua: assegnarlo una volta basta.
##
## È una PREFERENZA con l'ultima parola al didattico, non un filtro cieco: una
## prova superata esce dalla scelta finché resta altro da chiedere, e rientra solo
## quando l'alternativa sarebbe una missione corta o un ripasso saltato.
var solved_by_subject: Dictionary = {}
var seen_by_subject: Dictionary = {}

func _superate(subject: String) -> Dictionary:
	# Compatibilita' con i salvataggi precedenti: le prove superate sono viste
	# anche se la nuova memoria globale non esisteva ancora.
	var known := Dictionary(seen_by_subject.get(subject, {})).duplicate()
	for fingerprint in Dictionary(solved_by_subject.get(subject, {})).keys():
		known[fingerprint] = true
	return known

func _e_superata(superate: Dictionary, item: Dictionary) -> bool:
	if superate.is_empty():
		return false
	return superate.has(ExerciseSignature.fingerprint(item))

func _load_bank(subject: String) -> Array:
	if _cache.has(subject):
		return _cache[subject]
	var items: Array = []
	if BANKS.has(subject):
		var path: String = BANKS[subject]
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parsed = JSON.parse_string(file.get_as_text())
				if typeof(parsed) == TYPE_DICTIONARY:
					items = parsed.get("items", [])
	_cache[subject] = items
	return items

## Otto fasce di contenuto, tre mondi ciascuna. Il livello del mondo resta il
## solo requisito: padronanza ed esperienza non abbassano il bersaglio.
##
## La fascia descrive la complessita' della materia; il gesto cognitivo e il
## formato restano assi separati e continuano a maturare lungo tutti i 24 mondi.
const DIFFICULTY_BANDS := 8

static func target_difficulty(level: int) -> int:
	var lvl := clampi(level, 1, ApparatusConfig.MAX_LEVEL)
	return clampi(1 + floori(float(lvl - 1) / 3.0), 1, DIFFICULTY_BANDS)

## Scala fine della campagna: ogni fascia contiene tre gradini consecutivi.
## `difficulty` vale 1..8; `challenge_level` conserva i 24 livelli reali e guida
## valori, numero di passaggi, scaffolding e maturazione dei formati.
static func challenge_level(level: int) -> int:
	return clampi(level, 1, ApparatusConfig.MAX_LEVEL)

## Livello dei FORMATI e dei generatori. Coincide sempre con quello del mondo:
## padronanza ed esperienza restano parametri compatibili con i chiamanti, ma
## non modificano più la prova. Per avanzare va padroneggiato il grado corrente.
func effective_exercise_level(_subject: String, level: int, _mastery: float = -1.0, _experience: int = -1) -> int:
	return challenge_level(level)

# Range di difficoltà REALMENTE presente nel banco della materia (cache). Serve a
# calibrare la selezione per materia: senza, un target 4 su una materia il cui
# banco arriva a 2 (es. italiano) svuoterebbe la finestra e cadrebbe nel casuale.
func subject_difficulty_range(subject: String) -> Vector2i:
	if _difficulty_ranges.has(subject):
		return _difficulty_ranges[subject]
	var items := _load_bank(subject)
	var lo := DIFFICULTY_BANDS
	var hi := 1
	for item in items:
		var d := clampi(int(item.get("difficulty", 1)), 1, DIFFICULTY_BANDS)
		lo = mini(lo, d)
		hi = maxi(hi, d)
	if items.is_empty() or lo > hi:
		lo = 1
		hi = DIFFICULTY_BANDS
	var span := Vector2i(lo, hi)
	_difficulty_ranges[subject] = span
	return span

## Censimento pubblico delle otto fasce realmente disponibili. Gli audit lo
## usano per impedire che una materia dichiari 1..8 avendo in realta' buchi nel
## mezzo; il selettore non deve scoprirlo a campagna iniziata.
func bank_difficulty_counts(subject: String) -> Dictionary:
	var counts: Dictionary = {}
	for band in range(1, DIFFICULTY_BANDS + 1):
		counts[band] = 0
	for item_data in _load_bank(subject):
		var item := item_data as Dictionary
		var band := clampi(int(item.get("difficulty", 1)), 1, DIFFICULTY_BANDS)
		counts[band] = int(counts[band]) + 1
	return counts

# Numero di argomenti DISTINTI che la materia può proporre (dal banco). Alimenta
# la dimensione COPERTURA del gate (GateReadiness). Per la matematica, generata a
# runtime, il banco statico può non elencare topic: in tal caso torna 0 e la
# copertura ripiega sul minimo assoluto (la copertura vissuta la traccia comunque
# `masteryByTopic`, popolato dai topic del generatore).
## Cache condivisa da tutte le istanze: la prontezza si valuta a ogni
## fotogramma dell'HUD e ogni `ContentManager` nuovo ripagherebbe il conto.
static var _reachable_cache: Dictionary = {}

func subject_topic_count(subject: String) -> int:
	return bank_topics(subject).size()

## Argomenti effettivamente RAGGIUNGIBILI a questo livello.
##
## Serve alla copertura del gate, e la differenza non è teorica: italiano ha 21
## argomenti in tutto, ma al livello 2 la selezione ne rende disponibili quattro
## (difficoltà e `ERA_GATED_TOPICS` filtrano il resto). Chiedere una frazione dei
## 21 rendeva il gate **impossibile** invece che difficile — misurato: copertura
## ferma a 4 su 8 richiesti, per sempre.
func reachable_topic_count(subject: String, level: int) -> int:
	var chiave := "%s@%d" % [subject, level]
	if _reachable_cache.has(chiave):
		return int(_reachable_cache[chiave])
	# Si CHIEDE al costruttore di missioni, invece di reimplementare la sua
	# selezione. Filtrare il banco «attorno alla difficoltà» sembrava
	# equivalente e non lo era: dava 21 argomenti per italiano al livello 2,
	# dove la selezione ne propone quattro. Il gate chiedeva otto, e restava
	# impossibile per sempre.
	#
	# Cinque estrazioni con semi fissi: deterministico, e il risultato si tiene
	# in cache perché la prontezza si valuta a ogni fotogramma dell'HUD. Con
	# dodici il primo calcolo costruiva 144 missioni e faceva scadere i test di
	# scena: il numero di argomenti distinti si stabilizza molto prima.
	var topics: Dictionary = {}
	for seme in range(5):
		var rng := RandomNumberGenerator.new()
		rng.seed = seme * 7919 + level
		for node in Array(build_mission(subject, level, 3, {}, rng).get("nodes", [])):
			topics[str((node as Dictionary).get("topic", ""))] = true
	var quanti := maxi(1, topics.size())
	_reachable_cache[chiave] = quanti
	return quanti

# Argomenti DISTINTI presenti nel banco statico della materia (cache). Per la
# matematica, generata a runtime, il banco statico può elencarne pochi: i topic
# effettivi emergono dal generatore (vedi build_mission).
func bank_topics(subject: String) -> Array:
	if _topic_counts.has(subject):
		return Array(_topic_counts[subject]).duplicate()
	var topics: Dictionary = {}
	for item in _load_bank(subject):
		var topic := str(item.get("topic", ""))
		if topic != "":
			topics[topic] = true
	_topic_counts[subject] = topics.keys()
	return Array(_topic_counts[subject]).duplicate()

# Difficoltà EFFETTIVA per materia: banda del mondo calibrata sul range che il
# banco può davvero servire. Mastery ed esperienza alimentano il gate, non
# abbassano o alzano gli esercizi richiesti.
## **Il mondo è il requisito, non soltanto il tetto.** (4 settembre 2026)
##
## Una prova del mondo 20 resta di livello 20 anche per chi ha poca esperienza
## nella materia. La padronanza decide se il gate si apre; non modifica la prova
## con cui quella padronanza viene dimostrata. Gli aiuti restano indizi, assenza
## di cronometro, ripasso mirato e spiegazioni: nessuno abbassa il curricolo.
func effective_difficulty(subject: String, level: int, _mastery: float = -1.0, _experience: int = -1) -> int:
	var span := subject_difficulty_range(subject)
	return clampi(target_difficulty(level), span.x, span.y)

# Anche il generatore matematico usa esattamente il livello del mondo.
static func math_effective_level(level: int, _mastery: float = -1.0) -> int:
	return challenge_level(level)

# Costruisce una sessione-missione: alcuni item della materia vicini alla
# difficoltà del livello. `rng` opzionale per selezione deterministica nei test.
# Selezione mirata: prima i topic in ripasso spaziato (`review_due` = mappa
# "subject:topic" -> conteggio, dagli errori passati), poi item vicini alla
# difficoltà del livello. Gli item di ripasso sono marcati `review:true`.
# `topic_mastery` = {topic: float 0..1} degli argomenti già incontrati: la
# selezione privilegia gli argomenti PIÙ DEBOLI (mastery < soglia), così il
# bambino esercita dentro la materia proprio ciò che padroneggia meno.
const WEAK_TOPIC_THRESHOLD := 0.6

# Progressione per ERA della storia. I due mondi storia (livelli 11 e 23) hanno
# bande alte vicine, quindi
# la difficoltà non li distingue. Le ere "tarde" restano riservate al mondo
# avanzato: così il mondo 11 "Soglia del Tempo" resta sulle prime civiltà e il 23
# "Sala delle Ere" è l'unico a trattare Roma e Medioevo. Mappa topic -> livello min.
const ERA_GATED_TOPICS := {
	"storia": {"roma": 18, "medioevo": 18},
}

## **Il primo esame di elettronica verifica soltanto ciò che il mondo 8 ha
## insegnato.** (2 settembre 2026)
##
## La sola difficoltà numerica non basta: nel banco «condensatore», «relè»,
## messa a terra e strumenti di misura avevano difficoltà 1–2 come pila e LED.
## Un bambino poteva quindi fare un intero percorso su circuito chiuso e quattro
## componenti base, poi essere bocciato su un nome mai incontrato. Questa lista
## è volutamente esplicita: ogni voce deve poter indicare l'attività del mondo 8
## che la prepara. Dal mondo 20 torna disponibile l'intero banco avanzato.
const ELECTRONICS_BEGINNER_EXAM_IDS := {
	"elettronica-funzione-battery": true,
	"elettronica-attenzione-battery": true,
	"elettronica-funzione-switch": true,
	"elettronica-attenzione-switch": true,
	"elettronica-funzione-resistor": true,
	"elettronica-attenzione-resistor": true,
	"elettronica-funzione-led": true,
	"elettronica-attenzione-led": true,
	"elettronica-funzione-return": true,
	"elettronica-attenzione-return": true,
	"elettronica-sicurezza-elettrica-0": true,
	"elettronica-sicurezza-elettrica-6": true,
	"elettronica-sicurezza-elettrica-10": true,
	"elettronica-sicurezza-elettrica-72": true,
	"elettronica-misure-elettriche-23": true,
	"elettronica-misure-elettriche-24": true,
	"elettronica-misure-elettriche-25": true,
	"elettronica-circuito-34": true,
	"elettronica-circuito-39": true,
	"elettronica-circuito-65": true,
	"elettronica-circuito-66": true,
	"elettronica-circuito-67": true,
	"elettronica-circuito-88": true,
	"elettronica-conduttori-43": true,
	"elettronica-conduttori-44": true,
	"elettronica-conduttori-68": true,
	"elettronica-conduttori-97": true,
	"elettronica-conduttori-98": true,
	"elettronica-conduttori-99": true,
	"elettronica-elettricita-base-52": true,
	"elettronica-elettricita-base-62": true,
	"elettronica-elettricita-base-63": true,
	"elettronica-elettricita-base-78": true,
	"elettronica-elettricita-base-79": true,
	"elettronica-elettricita-base-80": true,
	"elettronica-componenti-74": true,
	"elettronica-componenti-75": true,
	"elettronica-componenti-82": true,
	"elettronica-componenti-85": true,
	"elettronica-componenti-87": true,
	"elettronica-elettricita-base-che-cosa-fornisce-l-energia-in-un-circuito-con-l": true,
	"elettronica-elettricita-base-a-che-cosa-serve-l-interruttore-in-un-circuito": true,
	"elettronica-conduttori-quale-di-questi-materiali-conduce-la-corrente": true,
	"elettronica-conduttori-quale-di-questi-materiali-non-conduce-la-corrent": true,
	"elettronica-circuito-perche-una-lampadina-non-si-accende-se-il-circui": true,
}

# Toglie dal banco gli item la cui era non è ancora sbloccata a questo livello.
# Fallback prudente: se il filtro svuotasse il banco, restituisce l'originale.
## Ogni quanti nodi di una sessione di matematica uno viene dal banco.
const QUOTA_BANCO_MATEMATICA := 3

## **Il banco entra anche in matematica.** (14 agosto 2026)
##
## Per undici materie su dodici una missione nasce dal banco. Per la matematica
## no: `build_mission` costruiva i nodi con il generatore e **usciva prima di
## guardare il banco**, sempre, anche nell'esame. Era una scelta ragionevole
## finché il banco conteneva soltanto tabelline — il generatore le fa meglio e
## infinite — ed è diventata un difetto nel momento in cui il banco ha imparato a
## dire altro: frazioni, percentuali, geometria, espressioni, statistica. Ottanta
## item scritti e nessuna strada per arrivarci: è la stessa specie di guasto dei
## `modules` nel salvataggio, dichiarati e senza lettori.
##
## **Un nodo su tre**, non di più. Il generatore resta la spina dorsale della
## materia: è l'unico che scala di complessità con la competenza e non si ripete
## mai. Il banco porta ciò che un generatore non sa produrre — che cosa dice il
## denominatore, perché la media a volte inganna — e sono domande che si scrivono
## a mano una per una.
##
## **Le tabelline restano fuori** da questa estrazione: il generatore ne produce
## già in abbondanza, e pescarle anche dal banco vorrebbe dire spendere il nodo
## del banco per ridire la stessa cosa.
## `da_ripassare` sono gli argomenti di matematica che il calendario vuole
## rivedere oggi. **Senza questa lista un argomento sbagliato poteva non tornare
## mai piu'**, ed e' il difetto misurato il 26 agosto 2026 (`gate_mondo1_audit`):
## `matematica:statistica` sbagliata al giro tredici, mai piu' proposta in
## cinquanta giri di gioco, e la dimensione RITENZIONE del gate bloccata per
## sempre — sulla materia che ABITA il mondo 1, cioe' addosso a tutti.
##
## La causa e' che la matematica non nasce dal banco come le altre undici
## materie: nasce dal generatore, e il generatore riceve gia' la sua lista di
## ripasso. Ma gli argomenti scritti a mano — statistica, divisioni, frazioni —
## entrano solo da qui, e qui il calendario non arrivava.
func _innesta_banco_matematica(nodi: Array, level: int, rng: RandomNumberGenerator, mastery: float, da_ripassare: Array = [], experience: int = -1) -> Array:
	var quanti := int(round(float(nodi.size()) / float(QUOTA_BANCO_MATEMATICA)))
	if quanti <= 0 or nodi.is_empty():
		return nodi
	var target := effective_difficulty("matematica", level, mastery, experience)
	var superate := _superate("matematica")
	var candidati: Array = []
	var gia_risolti: Array = []
	for voce in _era_gated("matematica", level, _load_bank("matematica")):
		var item: Dictionary = voce
		if str(item.get("topic", "")) == "tabelline":
			continue
		if absi(int(item.get("difficulty", 1)) - target) <= 1:
			if _e_superata(superate, item):
				gia_risolti.append(item)
			else:
				candidati.append(item)
	# Gli ottanta item scritti a mano finiscono: quando il livello li ha risolti
	# tutti, il nodo del banco torna a pescare fra quelli invece di sparire — la
	# matematica senza innesto tornerebbe alle sole tabelline generate.
	if candidati.is_empty():
		candidati = gia_risolti
	if candidati.is_empty():
		return nodi
	# **Il ripasso dovuto viene prima.** Se fra i candidati c'e' un argomento che
	# il calendario reclama, l'innesto pesca solo fra quelli: e' l'unica strada
	# che un argomento di banco ha per tornare, e lasciarla al caso significa
	# lasciarla chiusa.
	var dovuti: Array = []
	for voce_candidata in candidati:
		if da_ripassare.has(str(Dictionary(voce_candidata).get("topic", ""))):
			dovuti.append(voce_candidata)
	if not dovuti.is_empty():
		candidati = dovuti
	var out := nodi.duplicate()
	var posizioni_usate: Dictionary = {}
	for _i in range(quanti):
		# **Un argomento per sessione, e mai uno già presente.** Senza questo
		# controllo l'esame di matematica — cinque nodi, quindi due dal banco —
		# poteva chiedere due volte la statistica nello stesso formato: tre
		# sessioni su 3648, trovate da `format_mix_audit`, che a ragione ne
		# ammette zero. Il conto degli argomenti si rifà a ogni giro perché il
		# nodo sostituito libera il proprio.
		var presenti: Dictionary = {}
		for voce_presente in out:
			presenti[str(Dictionary(voce_presente).get("topic", ""))] = true
		var scelto: Dictionary = {}
		for _tentativo in range(12):
			var c: Dictionary = candidati[rng.randi_range(0, candidati.size() - 1)]
			if presenti.has(str(c.get("topic", ""))):
				continue
			scelto = c
			break
		if scelto.is_empty():
			break
		# Dove innestarlo. Tre esclusioni, e la prima vale più delle altre due:
		#
		# **mai sopra un nodo di ripasso.** Il ripasso spaziato decide che cosa
		# deve tornare oggi, e un innesto che glielo cancella rompe la promessa
		# più importante del sistema didattico. È successo: `c11_world_content_audit`
		# chiedeva le tabelline in ripasso e non le trovava più.
		#
		# **mai l'ultimo nodo**, che lo preferisce `inject_non_mc` sostituendo le
		# scelte multiple dal fondo: metterci un item di banco vorrebbe dire
		# farselo cancellare un istante dopo.
		#
		# **mai una posizione fissa**, o ogni sessione di matematica avrebbe la
		# stessa forma — il difetto misurato il 5 agosto sulle aperture.
		var libere: Array = []
		for indice in range(maxi(0, out.size() - 1)):
			if posizioni_usate.has(indice):
				continue
			if bool(Dictionary(out[indice]).get("review", false)):
				continue
			libere.append(indice)
		if libere.is_empty():
			break
		var posizione := int(libere[rng.randi_range(0, libere.size() - 1)])
		posizioni_usate[posizione] = true
		var innestato := scelto.duplicate(true)
		# La `signature` la porta ogni nodo di matematica: il generatore la usa per
		# non ripetersi e c'è chi la legge a valle senza difese. Un item di banco
		# non ne ha una, e senza questa riga la sessione porta un nodo che sembra
		# di matematica e non lo è del tutto — se ne è accorto `c11_world_content_audit`
		# andando in errore invece che in rosso.
		innestato["signature"] = "banco:%s" % str(scelto.get("id", ""))
		out[posizione] = innestato
	return out

## **Che cosa puo' chiedere l'elettronica prima del mondo 20.**
##
## La lista di id sopra e' cio' che il mondo 8 prepara, ed e' giusta per l'esame
## del mondo 8. Ma il filtro vale per TUTTI i mondi sotto il 20, e quelle prove
## stanno tutte nelle fasce basse: al mondo 17, che e' fascia 6, non restava
## niente nella finestra di difficolta' e la selezione ripiegava sul primo item
## disponibile - una domanda di fascia 1 dentro l'esame del mondo 17. L'ha
## trovato `difficulty_bands_audit` il 10 settembre 2026.
##
## Passa quindi anche l'approfondimento di `elettricita-base` scritto per le
## fasce 5-8 (`elettronica-sl-`): e' lo **stesso argomento** che il mondo 8 ha
## gia' insegnato - corrente, tensione, resistenza - chiesto piu' a fondo man
## mano che il mondo sale. Il vincolo che questa lista difende resta intatto:
## nessun componente e nessun concetto che il percorso non abbia presentato.
const ELECTRONICS_DEEPENING_PREFIX := "elettronica-sl-"

static func _elettronica_prima_del_20(item: Dictionary) -> bool:
	var id := str(item.get("id", ""))
	return ELECTRONICS_BEGINNER_EXAM_IDS.has(id) or id.begins_with(ELECTRONICS_DEEPENING_PREFIX)

func _era_gated(subject: String, level: int, items: Array) -> Array:
	var beginner_electronics := subject == "elettronica" and level < 20
	if not ERA_GATED_TOPICS.has(subject) and not beginner_electronics:
		return items
	var gate: Dictionary = ERA_GATED_TOPICS.get(subject, {})
	var out: Array = []
	for it in items:
		if beginner_electronics and not _elettronica_prima_del_20(it as Dictionary):
			continue
		var topic := str((it as Dictionary).get("topic", ""))
		if gate.has(topic) and level < int(gate[topic]):
			continue
		out.append(it)
	return out if not out.is_empty() else items

func build_mission(subject: String, level: int, node_count: int = 3, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}, experience: int = -1) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	_mission_serial += 1
	if subject == "matematica":
		var review_topics: Array = []
		for key in review_due.keys():
			var prefix := "matematica:"
			if str(key).begins_with(prefix) and int(review_due[key]) > 0:
				review_topics.append(str(key).trim_prefix(prefix))
		# La matematica generata usa il livello del mondo; mastery ed esperienza
		# non ne spostano più la complessità.
		# Le prove già superate viaggiano fin dentro il generatore: qui non si può
		# filtrare a valle come per un banco — scartare un nodo generato lascerebbe
		# la sessione corta — e l'unico posto che può riprovare è chi lo costruisce.
		var generated := MathExerciseGenerator.new().build_nodes(
			effective_exercise_level(subject, level, mastery, experience), node_count, generator,
			_recent_math_signatures, review_topics, _superate(subject))
		return _session(subject, level, _innesta_banco_matematica(
			generated, level, generator, mastery, review_topics, experience))
	var items := _era_gated(subject, level, _load_bank(subject))
	# I soli livelli in cui una missione di fisica viene davvero servita sono i
	# suoi due mondi e il finale trasversale. Gli strumenti di authoring possono
	# continuare a esplorare il catalogo futuro sugli altri livelli.
	if subject == "fisica" and level in [5, 17, ApparatusConfig.MAX_LEVEL]:
		var nel_percorso: Array = []
		for raw_item in items:
			if PHYSICS_CURRICULUM_TOPICS.has(str((raw_item as Dictionary).get("topic", ""))):
				nel_percorso.append(raw_item)
		# Il banco viene validato al bake, ma questo ripiego evita una missione
		# vuota durante lo sviluppo se il JSON non è ancora stato rigenerato.
		if not nel_percorso.is_empty():
			items = nel_percorso
	# Banda del mondo, calibrata sul range reale del banco.
	var target := effective_difficulty(subject, level, mastery, experience)
	var lesson := lesson_topic_set(subject, level)
	var superate := _superate(subject)
	var review_pool: Array = []
	var review_done_pool: Array = [] # ripasso dovuto, ma su prove già superate
	var weak_near_pool: Array = []   # item vicini alla difficoltà su argomenti deboli
	var near_pool: Array = []        # gli altri item vicini alla difficoltà
	var lesson_weak_pool: Array = [] # argomenti del mondo, ancora deboli
	var lesson_near_pool: Array = [] # argomenti del mondo
	var done_pool: Array = []        # prove già superate: ultima risorsa
	var eligible_items: Array = []  # stesso perimetro didattico, anche nei fallback
	for item in items:
		var topic := str(item.get("topic", ""))
		# Nei due mondi di fisica il perimetro è stretto: una domanda fuori
		# lezione entra soltanto se è un ripasso già dovuto.
		if subject in STRICT_LESSON_SUBJECTS and not lesson.is_empty() and not lesson.has(topic) \
				and int(review_due.get("%s:%s" % [subject, topic], 0)) <= 0:
			continue
		# Il primo mondo di musica costruisce l'alfabeto sonoro. La banda 3
		# contiene già alterazioni, triadi e metri composti: non sono una versione
		# più difficile delle basi, sono concetti successivi e restano al mondo 18.
		if subject == "musica" and level == 6 and int(item.get("difficulty", 1)) > 2:
			continue
		eligible_items.append(item)
		var done := _e_superata(superate, item)
		if int(review_due.get("%s:%s" % [subject, topic], 0)) > 0:
			if done:
				review_done_pool.append(item)
			else:
				review_pool.append(item)
		elif abs(int(item.get("difficulty", 1)) - target) <= 1:
			if done:
				done_pool.append(item)
				continue
			var tm := float(topic_mastery.get(topic, -1.0))
			var weak := tm >= 0.0 and tm < WEAK_TOPIC_THRESHOLD
			if lesson.has(topic):
				if weak:
					lesson_weak_pool.append(item)
				else:
					lesson_near_pool.append(item)
			elif weak:
				weak_near_pool.append(item)
			else:
				near_pool.append(item)
	if review_pool.is_empty() and weak_near_pool.is_empty() and near_pool.is_empty() \
			and lesson_weak_pool.is_empty() and lesson_near_pool.is_empty() \
			and review_done_pool.is_empty() and done_pool.is_empty():
		near_pool = eligible_items.duplicate()
	var chosen: Array = []
	# Priorità: ripasso spaziato → argomenti del mondo (quota morbida) → argomenti
	# deboli → resto vicino → di nuovo argomenti del mondo → riempimento.
	_drain_into(chosen, review_pool, node_count, generator, true)
	# Il ripasso su una prova già superata viene subito dopo quello su materiale
	# nuovo e PRIMA di tutto il resto: l'argomento dovuto va onorato comunque, e
	# rivedere una prova risolta è meno grave che lasciare scadere un ripasso.
	_drain_into(chosen, review_done_pool, node_count, generator, true)
	var lesson_quota := int(ceil(float(node_count) * LESSON_TOPIC_SHARE))
	_drain_into(chosen, lesson_weak_pool, lesson_quota, generator, false)
	_drain_into(chosen, lesson_near_pool, lesson_quota, generator, false)
	_drain_into(chosen, weak_near_pool, node_count, generator, false)
	_drain_into(chosen, near_pool, node_count, generator, false)
	_drain_into(chosen, lesson_weak_pool, node_count, generator, false)
	_drain_into(chosen, lesson_near_pool, node_count, generator, false)
	# Solo qui le prove già superate: quando il livello non ha più niente di nuovo
	# da chiedere in questa materia. Prima del riempimento casuale, che pescherebbe
	# anche fuori dalla difficoltà giusta.
	_drain_into(chosen, done_pool, node_count, generator, false)
	# Anche il riempimento consuma: pescare con reinserimento da un banco piccolo
	# mette la stessa prova due volte nella stessa sessione.
	while chosen.size() < node_count and not eligible_items.is_empty():
		var riempi := generator.randi_range(0, eligible_items.size() - 1)
		chosen.append((eligible_items[riempi] as Dictionary).duplicate())
		eligible_items.remove_at(riempi)
	return _session(subject, level, chosen)

## Quota dei nodi riservata agli argomenti che la LEZIONE del mondo promette.
## Senza questa preferenza la selezione guarda solo la difficoltà: i mondi delle
## materie con banchi larghi servivano altro (misurato: il mondo 16 "Frontiera
## delle Lingue" proponeva il 2% di nodi sui topic promessi, il mondo 11 di storia
## trattava Roma). È una preferenza MORBIDA — circa due nodi su tre — perché il
## resto resti disponibile a ripasso e varietà.
const LESSON_TOPIC_SHARE := 0.67

# Argomenti promessi dalla lezione del mondo, come insieme. Vuoto se il livello
# non ha lezione o se la lezione è di un'ALTRA materia (caso dell'esame finale
# trasversale, dove tutte le 12 materie usano lo stesso livello).
static func lesson_topic_set(subject: String, level: int) -> Dictionary:
	if not WorldLessonCatalog.has_lesson(level):
		return {}
	var lesson := WorldLessonCatalog.lesson(level)
	if str(lesson.get("subject", "")) != subject:
		return {}
	var out: Dictionary = {}
	for topic in Array(lesson.get("topics", [])):
		out[str(topic)] = true
	return out

func _session(subject: String, level: int, nodes: Array) -> Dictionary:
	return {
		"sessionId": "mission-%s-lvl%d-%d" % [subject, level, _mission_serial],
		"kind": "mission",
		"subject": subject,
		"level": level,
		"nodes": nodes,
		"shields": 3,
		# Ritmo cognitivo e limite di tempo: le materie di ragionamento sono sempre
		# non cronometrate (`timed=false`). Nessuna sessione è cronometrata oggi;
		# il campo rende la politica esplicita, verificabile e leggibile dalla UI.
		"pace": subject_pace(subject),
		"timed": false,
		"rewards": {"energyPerCorrect": 10, "onComplete": {"energy": 30, "fragments": 2}},
	}

# Sposta item unici da `pool` in `chosen` (fino a node_count), marcando il ripasso.
## A parità di priorità si preferisce un ARGOMENTO non ancora presente nella
## sessione. Due domande sullo stesso argomento in una missione da tre campate
## sono la stessa richiesta a un minuto di distanza, anche quando il testo è
## diverso: è il residuo che `format_mix_audit` continuava a contare dopo che i
## minigiochi erano stati sistemati, e veniva tutto dal banco.
##
## Preferenza, non divieto: se restano solo item di argomenti già usati la
## missione si riempie comunque. Una missione corta è un difetto peggiore di una
## missione un po' ripetitiva.
## **Pescare da un pozzo lo svuota.** (10 settembre 2026)
##
## Qui c'era `var work := pool.duplicate()`: la copia veniva consumata e il pozzo
## del chiamante restava pieno. Sembra innocuo finche' non si guarda l'ordine
## delle chiamate — `lesson_weak_pool` e `lesson_near_pool` vengono pescati DUE
## volte, prima con la quota del mondo e poi con il conto pieno — e la seconda
## pescata poteva ridare lo stesso identico item della prima. Misurato su musica
## al mondo 6: `musica-sl-note-1` due volte nella stessa missione, cinque
## missioni su cento, e `music_beginner_audit` le trovava.
##
## L'id in chiaro e' la seconda rete: due pozzi diversi non possono contenere lo
## stesso item, ma se un giorno potessero, la missione non se ne accorgerebbe.
func _drain_into(chosen: Array, pool: Array, node_count: int, generator: RandomNumberGenerator, review: bool) -> void:
	var used_topics: Dictionary = {}
	var used_ids: Dictionary = {}
	for node in chosen:
		used_topics[str((node as Dictionary).get("topic", ""))] = true
		used_ids[str((node as Dictionary).get("id", ""))] = true
	while chosen.size() < node_count and not pool.is_empty():
		var idx := _pick_fresh_topic(pool, used_topics, generator)
		var item: Dictionary = pool[idx].duplicate()
		pool.remove_at(idx)
		if used_ids.has(str(item.get("id", ""))):
			continue
		if review:
			item["review"] = true
		used_topics[str(item.get("topic", ""))] = true
		used_ids[str(item.get("id", ""))] = true
		chosen.append(item)
		# **Anche le prove del banco vanno ricordate.** (10 settembre 2026) La
		# memoria delle prove recenti esisteva solo per i minigiochi iniettati:
		# un item del banco poteva tornare in ogni missione di fila senza che
		# niente se ne accorgesse. Finche' i formati da toccare arrivavano tutti
		# dalle ricette il difetto era invisibile, perche' i posti buoni li
		# occupavano loro; con gli ordinamenti dentro il banco e' venuto fuori
		# subito — `variety_audit`, logica al mondo 1, la stessa prova cinque
		# volte su trenta.
		_remember_node(_node_signature(item))


## Sceglie che cosa pescare: prima un argomento non ancora usato in questa
## sessione, e a parita' di argomento una prova che il bambino non ha visto di
## recente. Il secondo criterio e' arrivato il 10 settembre 2026: senza, un banco
## sottile ripeteva la stessa prova in missioni consecutive.
func _pick_fresh_topic(work: Array, used_topics: Dictionary, generator: RandomNumberGenerator) -> int:
	var fresh: Array = []
	for i in work.size():
		if not used_topics.has(str((work[i] as Dictionary).get("topic", ""))):
			fresh.append(i)
	var candidati: Array = fresh if not fresh.is_empty() else range(work.size())
	var mai_viste: Array = []
	for i in candidati:
		if not _recent_node_signatures.has(_node_signature(work[int(i)] as Dictionary)):
			mai_viste.append(int(i))
	if not mai_viste.is_empty():
		return int(mai_viste[generator.randi_range(0, mai_viste.size() - 1)])
	if candidati.is_empty():
		return generator.randi_range(0, work.size() - 1)
	return int(candidati[generator.randi_range(0, candidati.size() - 1)])

# Tema visivo dell'enigma per materia: la logica è identica, cambia solo la
# "costruzione" che Codex rende (ponte, cristalli, porta…). Default: "ponte".
const ENIGMA_THEMES := {
	"matematica": "ponte",
	"coding": "circuito",
	"musica": "cristalli",
	"latino": "porta",
	"fisica": "reattore",
	"inglese": "porta",
	"italiano": "porta",
	"elettronica": "circuito",
	# Materie nuove: temi visivi da rendere (Codex). Fallback "ponte" se assente.
	"geografia": "mappa",
	"scienze": "serra",
	"storia": "rete",
	"logica": "griglia",
}

static func enigma_theme(subject: String) -> String:
	return str(ENIGMA_THEMES.get(subject, "ponte"))

## Enigma ambientale: una missione la cui risposta corretta costruisce, campata
## per campata, un elemento del mondo (il ponte, la porta…). Riusa la selezione
## mirata di `build_mission`; ogni esercizio corrisponde a una "campata"
## (`stages` = node_count), così il progresso misura QUANTI hai capito, non la
## grandezza dei numeri. Contratto in più rispetto alla missione: `theme` e
## `stages` per la resa (vedi OutdoorGameplay.enigma_progress, gate I-01).
func build_enigma(subject: String, level: int, node_count: int = 4, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}, experience: int = -1) -> Dictionary:
	# Campate a formati VARI come le missioni: l'enigma è la prova più lunga del
	# mondo (4 campate) e, se restasse a sola scelta multipla, riporterebbe la
	# scelta multipla a dominare l'esperienza giocata (misurato: 41% nei mondi con
	# due enigmi). Ogni campata resta un esercizio del contratto comune.
	var session := build_varied_mission(subject, level, node_count, review_due, rng, mastery, topic_mastery, experience)
	session["sessionId"] = "enigma-%s-lvl%d" % [subject, level]
	session["kind"] = "enigma"
	session["theme"] = enigma_theme(subject)
	session["stages"] = int(session.get("nodes", []).size())
	session["shields"] = 3
	session["rewards"] = {"energyPerCorrect": 10, "onComplete": {"energy": 35, "fragments": 3}}
	return session

## Esame cumulativo dell'apparato corrente. MULTI-FORMATO (O-P3): non è mai
## composto soltanto da scelta multipla — include almeno un nodo non-MC
## (abbina/ordina) e marca un nodo di TRASFERIMENTO (applicazione in un contesto
## diverso), così l'esame verifica applicazione e trasferimento, non solo memoria.
func build_final_exam(subject: String, level: int, node_count: int = 3, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}, experience: int = -1) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	# La materia del mondo resta sempre presente, ma la prova misura il profilo
	# complessivo: 10 nodi di prima fascia, 7 di seconda e 3 di terza. Le materie
	# che non entrano in questo esame ruotano col livello; i compiti del mondo le
	# hanno comunque rese tutte obbligatorie prima di arrivare qui.
	var piano := _priority_exam_subjects(subject, level)
	var nodes: Array = []
	var used_signatures: Dictionary = {}
	var used_format_topics: Dictionary = {}
	var non_mc_target := int(ceil(float(PRIORITY_EXAM_NODES) * exam_non_mc_ratio(subject)))
	for i in piano.size():
		var node_subject := str(piano[i])
		var node_mastery := mastery if node_subject == subject else -1.0
		var node_topics := topic_mastery if node_subject == subject else {}
		var chosen: Dictionary = {}
		var fallback: Dictionary = {}
		var known_exercises := _superate(node_subject)
		# Un esame multi-materia puo' incontrare lo stesso nome d'argomento in due
		# banchi diversi. Riestraiamo per non chiedere due volte la stessa coppia
		# (formato, argomento) e, a maggior ragione, la stessa prova.
		var attempts := 12 if node_subject == "elettronica" else 6
		for attempt in range(attempts):
			var wants_manipulative := i < non_mc_target
			var piece := (
				minigame_manager.build_minigame(node_subject, level, generator)
				if wants_manipulative
				else build_mission(node_subject, level, 1, {}, generator, node_mastery, node_topics, experience))
			var candidates: Array = piece.get("nodes", [])
			if candidates.is_empty():
				continue
			# Il catalogo contiene più gesti validi: partire sempre dalla prima
			# riga concentrerebbe anche la stessa spiegazione in tutti gli esami.
			var candidate_start := generator.randi_range(0, candidates.size() - 1)
			for candidate_offset in candidates.size():
				var candidate_data = candidates[posmod(candidate_start + candidate_offset, candidates.size())]
				var candidate: Dictionary = (candidate_data as Dictionary).duplicate(true)
				if wants_manipulative and not FORMATI_MANIPOLATIVI.has(str(candidate.get("format", ""))):
					continue
				# Fuori dall'esame elettronica si impara facendo; qui il suo nodo
				# resta una domanda diretta, così la prova misura anche il richiamo.
				if node_subject == "elettronica" and not str(candidate.get("format", "")) in ["multiple_choice", "short_answer"]:
					continue
				if fallback.is_empty():
					fallback = candidate
				# L'esame condivide lo stesso mazzo globale di missioni, enigmi e
				# pratica. Prima si cercano prove mai mostrate; una vecchia rientra
				# soltanto come ripiego se il formato richiesto ha esaurito le varianti.
				if _e_superata(known_exercises, candidate):
					continue
				var format_topic := "%s|%s" % [str(candidate.get("format", "")), str(candidate.get("topic", ""))]
				var signature := ExerciseSignature.of(candidate)
				if not used_format_topics.has(format_topic) and not used_signatures.has(signature):
					chosen = candidate
					used_format_topics[format_topic] = true
					used_signatures[signature] = true
					break
			if not chosen.is_empty():
				break
		if chosen.is_empty():
			chosen = fallback
		if chosen.is_empty():
			continue
		var tier := ApparatusConfig.priority_tier(node_subject)
		chosen["subject"] = node_subject
		chosen["priorityTier"] = tier
		chosen["tierCheck"] = node_subject != subject
		chosen["scoreWeight"] = ApparatusConfig.tier_weight(tier) / float(PRIORITY_EXAM_COUNTS[tier])
		nodes.append(chosen)
	var exam := {
		"subject": subject,
		"level": level,
		"nodes": nodes,
		"pace": PACE_REASONING,
		"timed": false,
	}
	_flag_transfer_node(nodes)
	exam["sessionId"] = "final-exam-%s-lvl%d" % [subject, level]
	exam["kind"] = "final_exam"
	# Tutte le venti prove vengono affrontate; il verdetto arriva dal punteggio
	# pesato, non dall'esaurimento anticipato degli scudi.
	exam["shields"] = nodes.size() + 1
	exam["minimumCorrect"] = int(ceil(float(Array(exam.get("nodes", [])).size()) * EXAM_PASS_RATIO))
	exam["weightedScoring"] = true
	exam["weightedPassRatio"] = EXAM_PASS_RATIO
	exam["effortWeights"] = ApparatusConfig.PRIORITY_WEIGHTS.duplicate()
	exam["rewards"] = {"energyPerCorrect": 12, "onComplete": {"energy": 40, "fragments": 4}}
	return exam

func _priority_exam_subjects(host_subject: String, level: int) -> Array:
	var result: Array = []
	for tier in [1, 2, 3]:
		var subjects := ApparatusConfig.tier_subjects(tier)
		if subjects.has(host_subject):
			subjects.erase(host_subject)
			subjects.push_front(host_subject)
		elif not subjects.is_empty():
			var offset := posmod(level - 1, subjects.size())
			subjects = subjects.slice(offset) + subjects.slice(0, offset)
		for i in int(PRIORITY_EXAM_COUNTS[tier]):
			result.append(subjects[i % subjects.size()])
	return result

## Quante campate dell'esame ripetono un (formato, argomento) già visto, e le
## rimpiazza con un minigioco. Zero doppioni è la regola, non un obiettivo.
func _sciogli_doppioni(nodes: Array, subject: String, level: int, rng: RandomNumberGenerator) -> Array:
	var viste: Dictionary = {}
	var doppioni := 0
	# **Il formato del doppione dice quale nodo si puo' sostituire.** (10 settembre
	# 2026) Prima si contavano i doppioni e si chiedeva a `inject_non_mc` di
	# rimpiazzarne altrettanti, ma quella funzione tocca solo i formati che la
	# materia dichiara sostituibili — di norma la sola scelta multipla. Due nodi
	# `short_answer` sullo stesso argomento restavano quindi dov'erano e il
	# doppione sopravviveva in silenzio: misurato da `format_mix_audit` sull'enigma
	# di storia al mondo 23, `short_answer|roma` due volte nella stessa prova.
	var formati_in_doppio: Dictionary = {}
	for node_data in nodes:
		var n: Dictionary = node_data
		var chiave := "%s|%s" % [str(n.get("format", "")), str(n.get("topic", ""))]
		if viste.has(chiave):
			doppioni += 1
			formati_in_doppio[str(n.get("format", ""))] = true
		viste[chiave] = true
	if doppioni <= 0:
		return nodes
	var sostituibili: Array = formati_da_sostituire(subject)
	for formato in formati_in_doppio.keys():
		if not sostituibili.has(str(formato)):
			sostituibili.append(str(formato))
	return inject_non_mc(nodes, subject, level, doppioni, rng, FORMATI_MANIPOLATIVI, sostituibili)

## I nodi di nucleo da aggiungere a un esame di mondo.
##
## Si pescano dalle materie del nucleo DIVERSE da quella del mondo: se il mondo
## ospita già matematica, arrivano da italiano e inglese. Un esame di matematica
## con dentro altra matematica non direbbe niente di nuovo.
##
## `CORE_EXAM_NODES` è due. Uno solo si perderebbe fra i cinque della materia
## ospite; tre sposterebbero il baricentro dell'esame e renderebbero possibile
## bocciare su una materia che quel mondo non ha insegnato.
const CORE_EXAM_NODES := 2

func _aggiungi_prova_di_nucleo(
	nodes: Array, subject: String, level: int, rng: RandomNumberGenerator,
	topic_mastery: Dictionary = {}
) -> Array:
	var candidate: Array = []
	for core_data in ApparatusConfig.CORE_SUBJECTS:
		var core := str(core_data)
		if core != subject:
			candidate.append(core)
	if candidate.is_empty():
		return nodes
	var out := nodes.duplicate()
	# Una materia per nodo, a rotazione: due nodi di italiano di fila
	# somiglierebbero a un esame di italiano appiccicato in fondo.
	#
	# **Una si chiede, l'altra si fa.** (3 settembre 2026)
	#
	# I nodi di nucleo sono due su cinque — il quaranta per cento dell'ultima cosa
	# che si gioca in un mondo — e uscivano da `build_mission` grezza, cioè quasi
	# sempre a crocette. Misurato: fra l'86% e il 94% di «tocca una fra N», e da
	# soli valevano 31-37 punti dei tetti di `gesto_audit`. Tre materie li hanno
	# sfondati appena il loro contenuto si è spostato di qualche punto, perché
	# partivano già con quel peso addosso.
	#
	# Il resto dell'esame passa da `inject_non_mc` e la prova di nucleo no: era una
	# dimenticanza, non una scelta. Ma nemmeno il contrario va bene — «misurare non
	# è insegnare» vale anche qui, e due minigiochi di altre materie in fondo
	# all'esame lo trasformerebbero in un intermezzo.
	#
	# Quindi: la prima prova di nucleo si fa con il gesto della SUA materia
	# (`build_varied_mission`, che sostituisce con minigiochi di quella materia,
	# non di questo mondo), la seconda resta una domanda diretta.
	for i in range(CORE_EXAM_NODES):
		var core := str(candidate[i % candidate.size()])
		var pezzo := (
			build_varied_mission(core, level, 1, {}, rng, -1.0, topic_mastery) if i == 0
			else build_mission(core, level, 1, {}, rng, -1.0, topic_mastery))
		for n in Array(pezzo.get("nodes", [])):
			var nodo: Dictionary = n
			# Marcato, perché la resa possa dirlo: il bambino deve capire perché
			# gli arriva una domanda di un'altra materia.
			nodo["coreCheck"] = true
			# E la materia scritta addosso, perché a valle nessuno la indovini dalla
			# sessione: sarebbe quella del mondo, non quella della domanda — NORA
			# spiegherebbe le declinazioni dopo una divisione, e la prova risolta
			# finirebbe segnata nella materia sbagliata.
			nodo["subject"] = core
			out.append(nodo)
			break
	return out

## Esame FINALE TRASVERSALE del mondo 24 (Gate E2 — struttura congelata da Opus):
## i DODICI SISTEMI convergono. Una prova per ciascuna delle 12 materie, in ordine
## canonico (la "sequenza dei dodici sistemi"): ogni nodo risolto accende il proprio
## sistema (`system`). Chiude un nodo di SINTESI interattivo marcato `transfer`:
## non una materia, ma tutte insieme applicate a un caso nuovo. È l'unica prova di
## trasferimento a scala d'avventura. `mastery_by_subject` resta accettato per
## compatibilità, ma non abbassa la difficoltà dei sistemi.
func build_final_transversal_exam(level: int = ApparatusConfig.MAX_LEVEL, rng: RandomNumberGenerator = null, mastery_by_subject: Dictionary = {}) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var nodes: Array = []
	for subject in ApparatusConfig.SUBJECT_CYCLE:  # 12 sistemi, ordine canonico
		var subject_mastery := float(mastery_by_subject.get(str(subject), -1.0))
		var mission := build_mission(str(subject), level, 1, {}, generator, subject_mastery)
		for node in mission.get("nodes", []):
			var n: Dictionary = (node as Dictionary).duplicate(true)
			n["system"] = str(subject)   # quale sistema accende questo nodo
			n["subject"] = str(subject)
			n["priorityTier"] = ApparatusConfig.priority_tier(str(subject))
			n["scoreWeight"] = ApparatusConfig.subject_weight(str(subject))
			nodes.append(n)
			break
	# Nodo di SINTESI finale: un formato interattivo (non scelta multipla) di logica,
	# marcato come prova di trasferimento — l'ultimo impulso che accende il Cuore.
	var synth := minigame_manager.build_minigame("logica", level, generator)
	# L'ultima prova dell'avventura non può essere una che lo studente ha già
	# risolto. Non passa da `inject_non_mc`, quindi il filtro va messo qui a mano:
	# si preferisce un nodo interattivo mai risolto e si ripiega sul primo utile —
	# il Cuore deve poter essere acceso comunque.
	var superate_logica := _superate("logica")
	var sintesi: Dictionary = {}
	var ripiego: Dictionary = {}
	for node in synth.get("nodes", []):
		if ExerciseInteraction.is_multiple_choice(node):
			continue
		var candidato: Dictionary = node
		if _e_superata(superate_logica, candidato):
			if ripiego.is_empty():
				ripiego = candidato
			continue
		sintesi = candidato
		break
	if sintesi.is_empty():
		sintesi = ripiego
	if not sintesi.is_empty():
		var s := sintesi.duplicate(true)
		s["system"] = "sintesi"
		s["transfer"] = true
		# La materia vera del nodo: senza, a valle vale «trasversale», che non è
		# una materia e manderebbe fuori posto sia la spiegazione sia il segno
		# della prova superata.
		s["subject"] = "logica"
		# La sintesi e' obbligatoria a parte e non altera il 50/35/15 delle
		# dodici materie.
		s["scoreWeight"] = 0.0
		nodes.append(s)
	return {
		"sessionId": "final-transversal-exam",
		"kind": "final_exam",
		"subject": "trasversale",
		"transversal": true,
		"level": level,
		"nodes": nodes,
		"systems": Array(ApparatusConfig.SUBJECT_CYCLE).duplicate(),
		# Tutti i dodici sistemi devono essere attraversati: la stabilità ampia
		# impedisce che tre errori tronchino il viaggio prima della convergenza.
		# Il superamento richiede circa il 70%, più severo dell'esame ordinario.
		"shields": nodes.size() + 1,
		"minimumCorrect": ceili(float(nodes.size()) * 0.69),
		"weightedScoring": true,
		"weightedPassRatio": EXAM_PASS_RATIO,
		"effortWeights": ApparatusConfig.PRIORITY_WEIGHTS.duplicate(),
		"completeAllSystems": true,
		"pace": PACE_REASONING,
		"timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 120, "fragments": 12}},
	}

## Missione a formati VARI (O-P3, policy "scelta multipla non dominante"): come
## Frazione bersaglio di scelta multipla nell'esperienza giocata (~20%).
const MC_TARGET_RATIO := 0.20

## La media sui 24 mondi resta 20%, ma non e' piatta: all'inizio una quota un
## po' maggiore di riconoscimento contiene il carico di lavoro; verso il finale
## piu' risposte vengono costruite o manipolate. I due estremi restano dentro il
## tetto didattico del 33% e la variazione e' continua, quindi ogni mondo ha una
## pressione appena diversa dal precedente.
const MC_TARGET_EARLY := 0.28
const MC_TARGET_LATE := 0.12

## **Elettronica: nessuna scelta multipla fuori dall'esame.** (7 agosto 2026)
##
## Direttiva del committente: «dobbiamo creare minigiochi che insegnino i
## concetti e lasciare le domande a scelta multipla solo nell'esame di livello».
## Elettronica e' la materia da cui e' partita la segnalazione, ed e' quella su
## cui la direttiva si prova prima di estenderla alle altre undici.
##
## **Perche' proprio qui.** Un decenne non ha mai visto un rele' ne' un
## condensatore. Una domanda a scelta multipla su un oggetto mai visto misura se
## ha letto la riga giusta; montarlo in un circuito glielo fa capire. Le forme
## interattive — abbina, classifica, costruisci il circuito, trova il guasto —
## chiedono di FARE la cosa, ed e' l'unico modo in cui questa materia si impara.
##
## L'esame resta a scelta multipla apposta: li' si misura, e misurare e' un'altra
## attivita' dall'imparare. Vedi `build_final_exam`, che non passa di qui.
##
## **La seconda materia: logica.** (1 settembre 2026)
##
## La direttiva diceva «prima di estenderla alle altre undici», e la logica è
## quella che la chiedeva più forte. Misurato sull'esperienza giocata dei mondi
## 12 e 24 (1168 nodi): il ragionamento vero della materia — deduzioni, verità,
## quantificatori, cioè le domande migliori che il banco possiede — stava tutto
## a scelta multipla, mentre i formati manipolativi ricevevano il vocabolario
## (cuccioli e cani, penne e scrivere, animale contro pianta). Il gesto buono
## serviva il contenuto peggiore.
##
## Spostato quel contenuto dentro lo smistamento (il «tavolo delle conclusioni»
## in `MinigameManager.CLASSIFICATION`), la scelta multipla qui non ha più un
## compito che qualcun altro non faccia meglio. Resta all'esame, come in
## elettronica e per la stessa ragione: misurare è un'altra attività dall'imparare.
const MC_TARGET_PER_MATERIA := {
	"elettronica": 0.0,
	"logica": 0.0,
}

static func mc_target_for(subject: String, level: int = -1) -> float:
	if MC_TARGET_PER_MATERIA.has(subject):
		return float(MC_TARGET_PER_MATERIA[subject])
	if level < 1:
		return MC_TARGET_RATIO
	var progress := float(challenge_level(level) - 1) / float(ApparatusConfig.MAX_LEVEL - 1)
	return lerpf(MC_TARGET_EARLY, MC_TARGET_LATE, progress)

## Carico cognitivo del GESTO, separato dalla difficolta' del contenuto. Un
## grafico semplice puo' avere banda 1 e un abbinamento difficile banda 4: le
## due misure non si sostituiscono, si sommano.
const FORMAT_STAGE := {
	"multiple_choice": 1, "matching": 1, "classification": 1,
	"short_answer": 2, "numeric_input": 2, "ordering": 2, "cycle": 2,
	"timeline": 2,
	"graph": 3, "map": 3, "hotspot": 3, "clue": 3, "circuit": 3,
	"notation": 3, "number_line": 3, "trace": 3,
	"balance": 4, "compose": 4, "code_debug": 4, "swipe": 4,
	"machine_path": 4, "mystery_sample": 4, "verb_decoder": 4,
	"griglia": 4, "porte": 4,
	"breadboard": 4, "rhythm_fill": 4, "causal_chain": 4,
	"robot_grid": 4, "blank_map": 4,
}

static func format_stage(format: String) -> int:
	return int(FORMAT_STAGE.get(format, 1))

static func target_format_stage(level: int) -> float:
	var progress := float(challenge_level(level) - 1) / float(ApparatusConfig.MAX_LEVEL - 1)
	return lerpf(1.0, 4.0, progress)

## Peso progressivo per la tavolozza dei formati. Non chiude mai una corsia:
## conserva varieta' e ripasso, ma sposta con continuita' la probabilita' dalle
## forme di riconoscimento verso i gesti con rappresentazioni e vincoli.
static func format_progression_weight(format: String, level: int) -> float:
	var centered_target := target_format_stage(level) - 2.5
	var centered_format := float(format_stage(format)) - 2.5
	return clampf(1.0 + centered_target * centered_format * 0.28, 0.40, 1.70)

## **Anche le risposte aperte, in elettronica.** (7 agosto 2026)
##
## Portata la scelta multipla a zero, il posto se l'e' preso la risposta aperta:
## misurato, il 36-38% dei nodi. E guardando che cosa chiede — «come si chiama il
## componente che accumula carica fra due armature?» — e' **peggio** della scelta
## multipla per questa eta': la scelta multipla la parola almeno te la mostra.
##
## Sono domande di NOMENCLATURA: sapere che si dice «condensatore» non e' aver
## capito che cosa fa un condensatore. Fuori dall'esame vanno via anche quelle.
##
## Vale solo per elettronica. In italiano e in inglese una risposta aperta e'
## esattamente la prova giusta — si scrive la parola perche' l'obiettivo E'
## saperla scrivere — e toglierla li' sarebbe un danno.
##
## **E in logica anche i numeri da digitare.** (1 settembre 2026)
##
## Stessa direttiva, seconda materia. Portata a zero la scelta multipla, il posto
## se l'è preso l'inserimento numerico: misurato, il 13% dei nodi — e sono quasi
## tutti serie aritmetiche, «quale numero continua», che è il pezzo di logica che
## lo studio ha trovato più debole. Peggio: con il banco ridotto ai soli argomenti
## di ragionamento, due campate della stessa sessione finivano tutte e due su
## `numeric_input|sequenze`, e `format_mix_audit` lo vieta a ragione — la stessa
## competenza chiesta due volte nello stesso modo a un minuto di distanza.
##
## Le sequenze restano, e restano in tre direzioni (il termine dopo, il decimo,
## la posizione di un numero): si incontrano all'esame, dove si misura. Fuori si
## trova l'ordinamento «scopri la regola di una sequenza», che chiede la stessa
## cosa facendola.
const FORMATI_DA_SOSTITUIRE := {
	"elettronica": ["multiple_choice", "short_answer"],
	"logica": ["multiple_choice", "numeric_input"],
	# Nei corsi a perimetro stretto le campate sono più numerose dei topic e un
	# duplicato può cadere anche su risposta breve o numerica. La seconda prova
	# viene trasformata in un gesto diverso, senza introdurre un altro argomento.
	"fisica": ["multiple_choice", "short_answer", "numeric_input"],
	"musica": ["multiple_choice", "short_answer", "numeric_input"],
}

static func formati_da_sostituire(subject: String) -> Array:
	return Array(FORMATI_DA_SOSTITUIRE.get(subject, ["multiple_choice"]))

## build_mission ma con la scelta multipla portata al ~20% dei nodi iniettando
## nodi non-MC (abbina/ordina/classifica + specialisti) della materia. Dal gate
## C-P3 questa è la variante usata dal percorso live delle missioni esterne.
func build_varied_mission(subject: String, level: int, node_count: int = 3, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}, experience: int = -1) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var session := build_mission(subject, level, node_count, review_due, generator, mastery, topic_mastery, experience)
	# Mix target dell'esperienza giocata: la scelta multipla è un formato tra tanti,
	# non il dominante. Obiettivo ~20% MC, ~20% abbina, ~60% al resto (ordina,
	# classifica, grafico, circuito, caccia-all'errore). Con poche campate per
	# missione l'arrotondamento è stocastico per centrare la media sull'insieme.
	var nodes: Array = session.get("nodes", [])
	var target_mc := _stochastic_round(mc_target_for(subject, level) * float(nodes.size()), generator)
	var da_sostituire := formati_da_sostituire(subject)
	var mc_count := 0
	for n in nodes:
		if str(Dictionary(n).get("format", "")) in da_sostituire:
			mc_count += 1
	var to_replace := maxi(0, mc_count - target_mc)
	# **Chi ha detto «minigiochi che insegnano» li vuole davvero.** (1 settembre 2026)
	#
	# Una materia con la scelta multipla a zero fuori dall'esame ha preso una
	# decisione precisa: qui si impara facendo. Ma `inject_non_mc` sostituisce con
	# un formato non-MC qualsiasi, e metà di quelli — grafico, circuito, caccia
	# all'errore, tracciatore, indiziario, bilancia — sono a loro volta «tocca una
	# fra N» con un disegno sopra. Misurato in logica: portando fuori anche i
	# numeri da digitare, la quota di «sceglie» SALIVA invece di scendere, perché
	# il posto lasciato libero se lo prendevano loro.
	#
	# Dove la materia ha dichiarato quella scelta, la sostituzione preferisce i
	# formati in cui il gesto è la competenza. Le altre dieci non cambiano.
	#
	# **La condizione era troppo stretta.** (3 settembre 2026)
	#
	# Guardava soltanto `mc_target_for(subject) <= 0.0`, cioè elettronica e
	# logica. Ma il 2 settembre fisica e musica sono entrate in
	# `FORMATI_DA_SOSTITUIRE` con tre formati invece di uno: portano fuori dalla
	# missione anche le risposte brevi e i numeri da digitare. Sostituiscono
	# quindi molti più nodi — e senza preferenza ognuno di quei nodi aveva una
	# probabilità su due di finire su un grafico o una bilancia, che sono «tocca
	# una fra N» con un disegno sopra. Misurato: fisica al 29,2% di «sceglie» nel
	# mondo contro il 25,5% del suo tetto, musica al 29,8 contro 28,3. Il posto
	# lasciato libero dalle crocette se l'erano preso i quiz illustrati, esattamente
	# come era successo alla logica.
	#
	# La regola giusta non è «la materia ha azzerato la scelta multipla», è **la
	# materia toglie dal giro anche le domande dirette**: chi lo fa ha deciso che
	# lì si impara facendo, e la sostituzione deve rispettarlo.
	var preferisce_le_mani := mc_target_for(subject, level) <= 0.0 or formati_da_sostituire(subject).size() > 1
	var preferiti: Array = FORMATI_MANIPOLATIVI if preferisce_le_mani else []
	var exercise_level := effective_exercise_level(subject, level, mastery, experience)
	var vari: Array = inject_non_mc(nodes, subject, exercise_level, to_replace, generator, preferiti)
	# Dopo il mix, nessun bambino deve ricevere due volte lo stesso argomento con
	# lo stesso gesto nella stessa missione: sarebbe ripetizione, non rinforzo.
	session["nodes"] = _sciogli_doppioni(vari, subject, exercise_level, generator)
	return session

# Arrotonda a intero mantenendo la media: la parte frazionaria diventa la
# probabilità di arrotondare per eccesso (es. 0.6 → 1 nel 60% dei casi).
func _stochastic_round(x: float, rng: RandomNumberGenerator) -> int:
	var base := int(floor(x))
	return base + (1 if rng.randf() < (x - float(base)) else 0)

# Sostituisce fino a `count` nodi a scelta multipla con nodi NON-MC (abbina/ordina)
# della stessa materia, presi dal MinigameManager (topic/difficoltà coerenti). I
# nodi iniettati restano nel contratto comune (ExerciseInteraction): stesso
# scoring/scudi/mastery. Sostituisce partendo dagli ultimi nodi MC.

# Peso di ogni formato tra i nodi NON-MC iniettati. Calibrato perché, con MC ~20%,
# l'esperienza giocata risulti ~20% abbina e ~60% al resto (ordina/classifica +
# specialisti). Un formato già usato nella stessa missione viene smorzato, così le
# poche campate restano varie e nessun formato torna a dominare.
const NONMC_FORMAT_WEIGHTS := {
	# ## Riequilibrati il 9 settembre 2026 — il peso segue il GESTO
	#
	# Era il punto 1 del debito dichiarato in `gesto_audit`, scritto il 1
	# settembre e mai pagato: grafico, circuito e caccia all'errore pesavano 25,
	# cioe' quasi il doppio dello smistamento (13). Ma quei tre sono «tocca una
	# fra N con un disegno sopra» — `gesto_audit` li elenca fra i SCEGLIE — mentre
	# abbinare, ordinare e smistare sono gesti in cui si sposta qualcosa.
	# **La tabella favoriva esattamente i formati in cui il gesto non e' la
	# competenza**, ed e' la causa misurata di R-18.
	#
	# Adesso i tre manipolativi di base stanno a 20 e i tre «sceglie» con disegno
	# a 14: sotto, non sopra. I formati-firma di materia restano a 34 perche' sono
	# tutti manipolativi, e `hotspot` resta a 18 perche' e' l'unico in cui si
	# riconosce una cosa vera invece di leggerne il nome (vedi G-C5).
	"matching": 20, "ordering": 20, "classification": 20,
	# Lo scorrimento e' manipolativo e prendeva il peso di ripiego, 10: meno di
	# tutti. Dichiarato.
	"swipe": 18,
	# **La linea del tempo pesa come un abbinamento.** (1 settembre 2026)
	# Un formato senza una riga qui dentro prende il peso di ripiego, 10: meno
	# della metà del grafico e del circuito, che sono «tocca una fra N» con un
	# disegno sopra. È il punto 1 del debito dichiarato in `gesto_audit` — i pesi
	# favorivano proprio i formati in cui il gesto non è la competenza. Collocare
	# un evento su una linea del tempo è un gesto di posizione, ed è la forma in
	# cui la cronologia si impara davvero quando la tavola sta davanti.
	"timeline": 20,
	"graph": 14, "circuit": 14, "cycle": 14, "code_debug": 14, "hotspot": 18,
	# La matematica diventa un oggetto da far funzionare, non una risposta da
	# riconoscere. Il peso alto rende il vertical slice visibile nel percorso live.
	"machine_path": 34,
	# Scienze e fisica diventano indagine: prima si producono prove, poi si dà un
	# nome al campione. Il formato è intenzionalmente visibile nel percorso live.
	"mystery_sample": 34,
	# Italiano come indagine: tre regolazioni separate rendono visibili tempo,
	# modo e forma prima che il messaggio del Relitto possa essere aperto.
	"verb_decoder": 34,
	# La logica smette di essere un elenco di alternative: la griglia si deduce
	# chiudendo le caselle impossibili, le porte si accendono una alla volta.
	# Stesso peso degli altri formati-firma di materia.
	"griglia": 34,
	"porte": 34,
	"breadboard": 34,
	"rhythm_fill": 34,
	"causal_chain": 34,
	"robot_grid": 34,
	"blank_map": 34,
}

# Quante costruzioni di minigioco attingere per la tavolozza: con più prove per
# formato una campata non ripete mai la prova della campata precedente.
const PALETTE_DRAWS := 3

## **I formati in cui il gesto È la competenza.** (1 settembre 2026)
##
## Non tutti i formati «non a scelta multipla» chiedono la stessa cosa. Grafico,
## circuito, caccia all'errore, tracciatore, indiziario e bilancia restano «tocca
## una fra N» con un disegno sopra: sostituire una scelta multipla con uno di
## loro cambia il vestito, non il gesto. Questi invece si trascinano, si ordinano,
## si montano, si provano — ed è la lista che `gesto_audit` chiama MANIPOLA.
##
## Serve all'esame, che finora riceveva il primo formato non-MC che capitava e
## chiudeva il mondo con la meccanica peggiore che possedeva.
const FORMATI_MANIPOLATIVI := [
	"matching", "ordering", "classification", "timeline", "swipe",
	"machine_path", "mystery_sample", "verb_decoder", "griglia", "porte",
	"breadboard", "rhythm_fill", "causal_chain", "robot_grid", "blank_map",
]

## Quanto pesa di più un formato preferito nel sorteggio. Tre volte: abbastanza
## perché domini quando c'è, non tanto da escludere gli altri — un esame di soli
## trascinamenti sarebbe monotono quanto uno di sole crocette.
##
## **Quattro dal 3 settembre 2026.** Il tre era stato tarato su logica ed
## elettronica, che di formati «tocca una fra N» ne hanno pochi. Fisica ne ha
## cinque contro quattro manipolativi al mondo 1 — grafico, circuito, ciclo,
## bilancia, caccia all'errore — e con peso tre più di un terzo delle
## sostituzioni finiva ancora su un quiz illustrato. E i suoi cinque sono anche i
## più sottili del progetto (ciclo e bilancia hanno UNA ricetta al mondo 1),
## quindi ogni volta che uscivano tendevano a ripetersi: `variety_audit` li vedeva
## tre volte in dieci missioni. Quattro sposta l'ago senza escludere nessuno — nel
## mondo di fisica il grafico continua a comparire, semplicemente non tre volte
## di fila.
const PESO_PREFERITO := 4.0

## `sostituibili` permette di restringere QUALI nodi possono essere sostituiti.
## Serve all'esame: lì una materia come la logica vuole ancora le sue domande da
## digitare — è il posto in cui si misura — anche se fuori le ha portate via.
func inject_non_mc(nodes: Array, subject: String, level: int, count: int, rng: RandomNumberGenerator, preferiti: Array = [], sostituibili: Array = []) -> Array:
	if count <= 0:
		return nodes
	# Tavolozza: per ciascun formato non-MC una CODA di prove distinte. Con una sola
	# prova per formato una sessione lunga (l'enigma ha 4 campate) rischiava di
	# ripetere lo stesso esercizio due volte: la ripetizione non insegna nulla.
	var palette: Dictionary = {}   # format -> Array[Dictionary] prove distinte
	var seen: Dictionary = {}      # firma prova -> true
	# **La tavolozza deve conoscere quello che c'e' gia' nella sessione.**
	# (10 settembre 2026) `seen` nasceva vuota e teneva unica solo la tavolozza
	# costruita QUI. Ma `build_varied_mission` chiama questa funzione due volte
	# — una per il mix e una da `_sciogli_doppioni` — e la seconda ricostruiva
	# la tavolozza da zero: poteva reinserire lo stesso (formato, argomento) che
	# stava cercando di sciogliere. Tolta la riga, `music_beginner_audit` torna
	# rosso: e' misurata, non teorica.
	for presente in nodes:
		var gia := presente as Dictionary
		seen["%s|%s" % [str(gia.get("format", "")), str(gia.get("topic", ""))]] = true
	var stale: Dictionary = {}     # format -> prove già viste di recente
	var risolte: Dictionary = {}   # format -> prove GIÀ SUPERATE (in fondo a tutto)
	var superate := _superate(subject)
	var topic_consentiti := lesson_topic_set(subject, level)
	if subject == "fisica" and topic_consentiti.is_empty():
		for topic in PHYSICS_CURRICULUM_TOPICS:
			topic_consentiti[str(topic)] = true
	for draw in range(PALETTE_DRAWS):
		for n in minigame_manager.build_minigame(subject, level, rng).get("nodes", []):
			if ExerciseInteraction.is_multiple_choice(n):
				continue
			# Un formato più visuale non può cambiare di nascosto la competenza.
			if subject in STRICT_LESSON_SUBJECTS and not topic_consentiti.is_empty() \
					and not topic_consentiti.has(str(n.get("topic", ""))):
				continue
			# DUE chiavi, per due scopi diversi — e questa volta la distinzione è
			# deliberata e dichiarata, non un incidente come lo era prima della Fase 0.
			#
			# `session_key` (formato + argomento) governa l'unicità DENTRO la sessione.
			# Non basta che due prove siano diverse: se sono lo stesso argomento nello
			# stesso formato, il bambino legge due volte la stessa consegna a un minuto
			# di distanza e la percepisce come una ripetizione, anche se i dati sono
			# altri. Con gli insiemi profondi il problema è PEGGIORATO invece di
			# migliorare — due estrazioni dello stesso insieme non sono più identiche,
			# quindi non venivano più scartate: misurato salire da 141 a 184 sessioni.
			#
			# `content_key` (identità di contenuto) governa la memoria FRA le sessioni,
			# dove invece conta solo se è letteralmente la stessa prova.
			var session_key := "%s|%s" % [str(n.get("format", "")), str(n.get("topic", ""))]
			var content_key := ExerciseSignature.of(n)
			if seen.has(session_key):
				continue
			seen[session_key] = true
			var f := str(n.get("format", ""))
			# Le prove viste di recente finiscono in fondo, non fuori: con due sole
			# specifiche per formato escluderle svuoterebbe la tavolozza. Le prove
			# già SUPERATE finiscono ancora più in fondo — «l'ha risolta» pesa più
			# di «l'ha vista», perché la seconda volta la risposta è già in mano.
			if superate.has(ExerciseSignature.fingerprint_of(content_key)):
				var risolta: Array = risolte.get(f, [])
				risolta.append(n)
				risolte[f] = risolta
			elif _recent_node_signatures.has(content_key):
				var back: Array = stale.get(f, [])
				back.append(n)
				stale[f] = back
			else:
				var queue: Array = palette.get(f, [])
				queue.append(n)
				palette[f] = queue
	for f in stale.keys():
		var queue: Array = palette.get(f, [])
		queue.append_array(stale[f])
		palette[f] = queue
	for f in risolte.keys():
		var queue: Array = palette.get(f, [])
		queue.append_array(risolte[f])
		palette[f] = queue
	if palette.is_empty():
		return nodes
	var out := nodes.duplicate()
	if sostituibili.is_empty():
		sostituibili = formati_da_sostituire(subject)
	var used: Dictionary = {}
	var injected := 0
	for i in range(out.size() - 1, -1, -1):
		if injected >= count:
			break
		if not (str(Dictionary(out[i]).get("format", "")) in sostituibili):
			continue
		# Un recupero e' un vincolo didattico, non un candidato al mix visuale.
		# Sostituirlo con un minigioco casuale perde sia l'argomento dovuto sia il
		# flag `review`, lasciando il registro bloccato anche dopo una risposta
		# corretta. Il 20% di scelta multipla e' un obiettivo medio; saldare un
		# recupero viene prima.
		if bool(Dictionary(out[i]).get("review", false)):
			continue
		# Solo i formati con una prova ancora disponibile restano nella scelta.
		var available: Array = []
		var fresh: Array = []
		for f in palette.keys():
			var pool: Array = palette[f]
			if pool.is_empty():
				continue
			available.append(f)
			# Formato la cui prossima prova NON è stata vista di recente né risolta.
			var prossima := _node_signature(pool[0])
			if not _recent_node_signatures.has(prossima) \
					and not superate.has(ExerciseSignature.fingerprint_of(prossima)):
				fresh.append(f)
		if available.is_empty():
			break
		# Si preferisce un formato con materiale nuovo. Serve perché ai livelli bassi
		# il gate `minLevel` lascia spesso UNA SOLA specifica per formato: lì la
		# memoria non può ruotare, e l'unico modo di non ripetere è cambiare formato.
		# Meglio un abbinamento nuovo che il quinto identico grafico.
		if not fresh.is_empty():
			available = fresh
		var fmt := _pick_weighted_format(available, used, rng, preferiti, level)
		var queue: Array = palette[fmt]
		var chosen_node: Dictionary = (queue.pop_front() as Dictionary).duplicate(true)
		out[i] = chosen_node
		_remember_node(_node_signature(chosen_node))
		used[fmt] = int(used.get(fmt, 0)) + 1
		injected += 1
	return out

## Firma di una prova iniettata. Delega a `ExerciseSignature`, che è la sola
## definizione di «stessa prova» del progetto: dedup di sessione, memoria delle
## prove recenti e misura di varietà devono usare la stessa, altrimenti misurano
## tre cose diverse e nessuna delle tre è quella che il bambino vede.
func _node_signature(node: Dictionary) -> String:
	return ExerciseSignature.of(node)

## Memoria anti-ripetizione delle prove iniettate, l'equivalente di quella che la
## matematica generata aveva già (`_recent_math_signatures`) e che ai formati
## specialisti mancava del tutto.
##
## È il difetto segnalato il 31 luglio: la tavolozza deduplicava DENTRO una
## sessione ma non FRA sessioni, e con due-quattro specifiche autorate per formato
## la stessa prova tornava fino a nove volte su trenta. Aggravato dalla decisione
## del 29 luglio, che portando la scelta multipla al 20% ha instradato l'80% delle
## campate proprio su quelle tabelle piccole: una correzione della varietà dei
## FORMATI aveva peggiorato la varietà dei CONTENUTI.
func _remember_node(signature: String) -> void:
	_recent_node_signatures.append(signature)
	while _recent_node_signatures.size() > RECENT_NODE_WINDOW:
		_recent_node_signatures.pop_front()

# Sceglie un formato tra quelli disponibili con probabilità proporzionale al peso,
# smorzando i formati già usati in questa missione (varietà dentro la singola
# missione oltre che nell'insieme).
func _pick_weighted_format(formats: Array, used: Dictionary, rng: RandomNumberGenerator, preferiti: Array = [], level: int = 1) -> String:
	var weighted: Array = []
	var total := 0.0
	for f in formats:
		var w := float(NONMC_FORMAT_WEIGHTS.get(f, 10))
		w *= format_progression_weight(str(f), level)
		if preferiti.has(f):
			w *= PESO_PREFERITO
		w /= float(1 + int(used.get(f, 0)) * 3)
		weighted.append([str(f), w])
		total += w
	var r := rng.randf() * total
	for pair in weighted:
		r -= float(pair[1])
		if r <= 0.0:
			return str(pair[0])
	return str(weighted[weighted.size() - 1][0])

# Marca un nodo di TRASFERIMENTO: preferisci il nodo (non-MC escluso) di
# difficoltà più alta e, a parità, di topic diverso dal primo — un'applicazione
# in contesto più impegnativo/altro. Se non c'è, marca l'ultimo nodo utile.
func _flag_transfer_node(nodes: Array) -> void:
	if nodes.is_empty():
		return
	var base_topic := str((nodes[0] as Dictionary).get("topic", ""))
	var best := -1
	var best_diff := -1
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		var d := int(n.get("difficulty", 1))
		var other_topic := 1 if str(n.get("topic", "")) != base_topic else 0
		var score := d * 2 + other_topic
		if score > best_diff:
			best_diff = score
			best = i
	if best >= 0:
		(nodes[best] as Dictionary)["transfer"] = true
