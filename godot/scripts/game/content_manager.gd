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

## **Elettronica fa eccezione, e l'aveva già dichiarato.** (1 settembre 2026)
##
## È l'unica materia che ha portato la scelta multipla a zero in TUTTO il resto:
## l'esame è il solo posto in cui misura, e `elettronica_hands_on_audit` pretende
## che almeno metà delle sue prove restino domande dirette. Con la quota generale
## scendevano al 44% e l'audit — a ragione — lo chiamava «non misura più».
const EXAM_NON_MC_PER_MATERIA := {
	"elettronica": 0.3,
}

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
	"inglese": ["irregular-past", "irregular-plural", "contractions", "vocabolario", "opposites"],
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

func _superate(subject: String) -> Dictionary:
	return Dictionary(solved_by_subject.get(subject, {}))

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

# Difficoltà target in base al SOLO livello del giocatore (banda 1-4). È la base;
# la difficoltà effettiva la corregge con la mastery e la calibra sul banco reale.
#
# La scala segue le DUE COMPARSE di ogni materia, non solo il numero del mondo.
# Prima passata (mondi 1-12): il mondo di INTRODUZIONE della materia, difficoltà
# da 1 a 3. Seconda passata (13-24): la stessa materia torna per APPROFONDIRE,
# da 3 a 4. Con la vecchia rampa (1 + (livello-1)/3) la difficoltà saturava a 4
# già dal livello 10: le ultime materie del ciclo (scienze, storia, logica)
# nascevano al massimo — nessuna introduzione — e la loro seconda comparsa non
# poteva più crescere (misurato: 3.90 → 3.91 di difficoltà media giocata).
static func target_difficulty(level: int) -> int:
	if level <= 12:
		return clampi(1 + (level - 1) / 5, 1, 3)
	return clampi(3 + (level - 13) / 6, 3, 4)

# Correzione di difficoltà secondo la padronanza (mastery 0..1): chi fatica scende
# di un gradino, chi padroneggia sale. `mastery < 0` = sconosciuta → nessun nudge
# (fallback solo-livello, retro-compatibile con chiamanti/audit che non la passano).
static func mastery_nudge(mastery: float) -> int:
	if mastery < 0.0:
		return 0
	if mastery >= 0.85:
		return 1
	if mastery < 0.5:
		return -1
	return 0

# Range di difficoltà REALMENTE presente nel banco della materia (cache). Serve a
# calibrare la selezione per materia: senza, un target 4 su una materia il cui
# banco arriva a 2 (es. italiano) svuoterebbe la finestra e cadrebbe nel casuale.
func subject_difficulty_range(subject: String) -> Vector2i:
	if _difficulty_ranges.has(subject):
		return _difficulty_ranges[subject]
	var items := _load_bank(subject)
	var lo := 4
	var hi := 1
	for item in items:
		var d := clampi(int(item.get("difficulty", 1)), 1, 4)
		lo = mini(lo, d)
		hi = maxi(hi, d)
	if items.is_empty() or lo > hi:
		lo = 1
		hi = 4
	var span := Vector2i(lo, hi)
	_difficulty_ranges[subject] = span
	return span

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

# Difficoltà EFFETTIVA per materia: banda di livello + nudge di mastery, poi
# calibrata (clamp) sul range che il banco può davvero servire. Così la selezione
# resta significativa su ogni materia, anche con banchi di ampiezza diversa.
func effective_difficulty(subject: String, level: int, mastery: float = -1.0) -> int:
	var span := subject_difficulty_range(subject)
	return clampi(target_difficulty(level) + mastery_nudge(mastery), span.x, span.y)

# Livello efficace per il generatore matematico: la mastery sposta il livello di
# ±3 (≈ ±1 gradino di complessità), così anche la matematica generata è adattiva.
static func math_effective_level(level: int, mastery: float = -1.0) -> int:
	return maxi(1, level + mastery_nudge(mastery) * 3)

# Costruisce una sessione-missione: alcuni item della materia vicini alla
# difficoltà del livello. `rng` opzionale per selezione deterministica nei test.
# Selezione adattiva: prima i topic in ripasso spaziato (`review_due` = mappa
# "subject:topic" -> conteggio, dagli errori passati), poi item vicini alla
# difficoltà del livello. Gli item di ripasso sono marcati `review:true`.
# `topic_mastery` = {topic: float 0..1} degli argomenti già incontrati: la
# selezione privilegia gli argomenti PIÙ DEBOLI (mastery < soglia), così il
# bambino esercita dentro la materia proprio ciò che padroneggia meno.
const WEAK_TOPIC_THRESHOLD := 0.6

# Progressione per ERA della storia. I due mondi storia (livelli 11 e 23) hanno la
# stessa difficoltà bersaglio (target_difficulty satura a 4 dal livello 10), quindi
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
func _innesta_banco_matematica(nodi: Array, level: int, rng: RandomNumberGenerator, mastery: float, da_ripassare: Array = []) -> Array:
	var quanti := int(round(float(nodi.size()) / float(QUOTA_BANCO_MATEMATICA)))
	if quanti <= 0 or nodi.is_empty():
		return nodi
	var target := effective_difficulty("matematica", level, mastery)
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

func _era_gated(subject: String, level: int, items: Array) -> Array:
	var beginner_electronics := subject == "elettronica" and level < 20
	if not ERA_GATED_TOPICS.has(subject) and not beginner_electronics:
		return items
	var gate: Dictionary = ERA_GATED_TOPICS.get(subject, {})
	var out: Array = []
	for it in items:
		if beginner_electronics \
				and not ELECTRONICS_BEGINNER_EXAM_IDS.has(str((it as Dictionary).get("id", ""))):
			continue
		var topic := str((it as Dictionary).get("topic", ""))
		if gate.has(topic) and level < int(gate[topic]):
			continue
		out.append(it)
	return out if not out.is_empty() else items

func build_mission(subject: String, level: int, node_count: int = 3, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
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
		# La mastery sposta il livello efficace: matematica generata adattiva.
		# Le prove già superate viaggiano fin dentro il generatore: qui non si può
		# filtrare a valle come per un banco — scartare un nodo generato lascerebbe
		# la sessione corta — e l'unico posto che può riprovare è chi lo costruisce.
		var generated := MathExerciseGenerator.new().build_nodes(
			math_effective_level(level, mastery), node_count, generator,
			_recent_math_signatures, review_topics, _superate(subject))
		return _session(subject, level, _innesta_banco_matematica(
			generated, level, generator, mastery, review_topics))
	var items := _era_gated(subject, level, _load_bank(subject))
	# Difficoltà efficace: livello + mastery, calibrata sul range reale del banco.
	var target := effective_difficulty(subject, level, mastery)
	var lesson := lesson_topic_set(subject, level)
	var superate := _superate(subject)
	var review_pool: Array = []
	var review_done_pool: Array = [] # ripasso dovuto, ma su prove già superate
	var weak_near_pool: Array = []   # item vicini alla difficoltà su argomenti deboli
	var near_pool: Array = []        # gli altri item vicini alla difficoltà
	var lesson_weak_pool: Array = [] # argomenti del mondo, ancora deboli
	var lesson_near_pool: Array = [] # argomenti del mondo
	var done_pool: Array = []        # prove già superate: ultima risorsa
	for item in items:
		var topic := str(item.get("topic", ""))
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
		near_pool = items.duplicate()
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
	while chosen.size() < node_count and not items.is_empty():
		chosen.append(items[generator.randi_range(0, items.size() - 1)].duplicate())
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
func _drain_into(chosen: Array, pool: Array, node_count: int, generator: RandomNumberGenerator, review: bool) -> void:
	var work := pool.duplicate()
	var used_topics: Dictionary = {}
	for node in chosen:
		used_topics[str((node as Dictionary).get("topic", ""))] = true
	while chosen.size() < node_count and not work.is_empty():
		var idx := _pick_fresh_topic(work, used_topics, generator)
		var item: Dictionary = work[idx].duplicate()
		work.remove_at(idx)
		if review:
			item["review"] = true
		used_topics[str(item.get("topic", ""))] = true
		chosen.append(item)

func _pick_fresh_topic(work: Array, used_topics: Dictionary, generator: RandomNumberGenerator) -> int:
	var fresh: Array = []
	for i in work.size():
		if not used_topics.has(str((work[i] as Dictionary).get("topic", ""))):
			fresh.append(i)
	if fresh.is_empty():
		return generator.randi_range(0, work.size() - 1)
	return int(fresh[generator.randi_range(0, fresh.size() - 1)])

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
## adattiva di `build_mission`; ogni esercizio corrisponde a una "campata"
## (`stages` = node_count), così il progresso misura QUANTI hai capito, non la
## grandezza dei numeri. Contratto in più rispetto alla missione: `theme` e
## `stages` per la resa (vedi OutdoorGameplay.enigma_progress, gate I-01).
func build_enigma(subject: String, level: int, node_count: int = 4, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
	# Campate a formati VARI come le missioni: l'enigma è la prova più lunga del
	# mondo (4 campate) e, se restasse a sola scelta multipla, riporterebbe la
	# scelta multipla a dominare l'esperienza giocata (misurato: 41% nei mondi con
	# due enigmi). Ogni campata resta un esercizio del contratto comune.
	var session := build_varied_mission(subject, level, node_count, review_due, rng, mastery, topic_mastery)
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
func build_final_exam(subject: String, level: int, node_count: int = 3, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	# L'esame è più lungo e più severo di una missione. (5 agosto 2026)
	#
	# Era una missione da tre nodi con due scudi, costruita con la stessa logica:
	# poteva cadere sugli stessi argomenti appena praticati e si superava
	# sbagliandone uno. Misurava l'ultima mezz'ora, non la materia.
	#
	# Ora: cinque nodi, e per passare ne servono quattro. Sbagliarne uno è
	# ammesso — un esame che non perdona nessun errore misura la tensione, non la
	# competenza — ma due no.
	# Mai più nodi degli argomenti che il livello propone: con cinque nodi su una
	# materia che ne offre tre, la selezione era costretta a ripetere lo stesso
	# argomento nello stesso formato — 89 sessioni su 3648, e `format_mix_audit`
	# lo vieta a ragione. Dove la materia è ricca l'esame resta lungo.
	var nodi_esame := clampi(reachable_topic_count(subject, level), node_count, EXAM_NODES)
	var exam := build_mission(subject, level, nodi_esame, {}, generator, mastery, topic_mastery)
	# **L'esame non è un compito in classe.** (1 settembre 2026)
	#
	# Qui c'era un `1` fisso: «garantisci almeno un formato oltre la scelta
	# multipla». Misurato su logica (1168 nodi giocati), quel numero produceva un
	# esame fatto per il 61,3% di «tocca una fra N» e per il 20% di risposte
	# digitate: manipolazione al 15%. Il mondo si apre con la pratica al 75% di
	# manipolazione e si chiude con la meccanica peggiore che possiede — e
	# l'ultima cosa giocata è quella che resta.
	#
	# Resta vero che misurare è un'altra attività dall'imparare, ed è la ragione
	# per cui l'esame non diventa una sessione di soli minigiochi: la metà dei
	# nodi, non tutti. Ma la competenza va misurata con lo stesso gesto con cui è
	# stata insegnata, altrimenti si misura un'altra cosa.
	var non_mc_esame := int(ceil(float(Array(exam.get("nodes", [])).size()) * exam_non_mc_ratio(subject)))
	# I nodi che entrano non sono «un formato qualsiasi purché non a crocette»:
	# sono quelli in cui si fa la cosa con le mani. Senza questa preferenza
	# l'iniezione pescava spesso un grafico o un circuito — che sono a loro volta
	# «tocca una fra N», e l'esame restava un quiz illustrato.
	exam["nodes"] = inject_non_mc(
		exam.get("nodes", []), subject, level, non_mc_esame, generator, FORMATI_MANIPOLATIVI,
		["multiple_choice"])
	# **E se restasse lo stesso argomento due volte.** (1 settembre 2026)
	#
	# La sostituzione qui sopra tocca solo la scelta multipla, così le domande da
	# digitare sopravvivono. Ma in logica il banco ha sei argomenti e l'esame ha
	# sette campate: in due sessioni su mille finivano due `numeric_input` sullo
	# stesso argomento — la stessa competenza chiesta due volte nello stesso modo,
	# che `format_mix_audit` vieta e che a giocarla sembra un errore del gioco.
	# Quando succede, e solo allora, si sostituisce anche una domanda da digitare.
	exam["nodes"] = _sciogli_doppioni(
		Array(exam.get("nodes", [])), subject, level, generator)
	# La PROVA DI NUCLEO. (6 agosto 2026)
	#
	# L'esame era solo della materia che abita il mondo: in ventuno mondi su
	# ventiquattro italiano, matematica e inglese non comparivano nel momento
	# decisivo. Un bambino impara che cosa conta da dove viene interrogato, non
	# da quello che gli si dice — e il gioco gli stava dicendo che il nucleo
	# conta solo tre volte su ventiquattro.
	#
	# Due nodi, non di più: l'esame resta della materia del mondo, e trasformarlo
	# in un esame generale cancellerebbe il senso di riparare QUELLA stanza.
	exam["nodes"] = _aggiungi_prova_di_nucleo(
		Array(exam.get("nodes", [])), subject, level, generator, topic_mastery)
	_flag_transfer_node(exam.get("nodes", []))
	exam["sessionId"] = "final-exam-%s-lvl%d" % [subject, level]
	exam["kind"] = "final_exam"
	exam["shields"] = 2
	exam["minimumCorrect"] = int(ceil(float(Array(exam.get("nodes", [])).size()) * EXAM_PASS_RATIO))
	exam["rewards"] = {"energyPerCorrect": 12, "onComplete": {"energy": 40, "fragments": 4}}
	return exam

## Quante campate dell'esame ripetono un (formato, argomento) già visto, e le
## rimpiazza con un minigioco. Zero doppioni è la regola, non un obiettivo.
func _sciogli_doppioni(nodes: Array, subject: String, level: int, rng: RandomNumberGenerator) -> Array:
	var viste: Dictionary = {}
	var doppioni := 0
	for node_data in nodes:
		var n: Dictionary = node_data
		var chiave := "%s|%s" % [str(n.get("format", "")), str(n.get("topic", ""))]
		if viste.has(chiave):
			doppioni += 1
		viste[chiave] = true
	if doppioni <= 0:
		return nodes
	return inject_non_mc(nodes, subject, level, doppioni, rng, FORMATI_MANIPOLATIVI)

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
	for i in range(CORE_EXAM_NODES):
		var core := str(candidate[i % candidate.size()])
		var pezzo := build_mission(core, level, 1, {}, rng, -1.0, topic_mastery)
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
## trasferimento a scala d'avventura. `mastery_by_subject` (opzionale) rende ogni
## sistema adattivo alla competenza reale della materia.
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
		"completeAllSystems": true,
		"pace": PACE_REASONING,
		"timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 120, "fragments": 12}},
	}

## Missione a formati VARI (O-P3, policy "scelta multipla non dominante"): come
## Frazione bersaglio di scelta multipla nell'esperienza giocata (~20%).
const MC_TARGET_RATIO := 0.20

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

static func mc_target_for(subject: String) -> float:
	return float(MC_TARGET_PER_MATERIA.get(subject, MC_TARGET_RATIO))

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
}

static func formati_da_sostituire(subject: String) -> Array:
	return Array(FORMATI_DA_SOSTITUIRE.get(subject, ["multiple_choice"]))

## build_mission ma con la scelta multipla portata al ~20% dei nodi iniettando
## nodi non-MC (abbina/ordina/classifica + specialisti) della materia. Dal gate
## C-P3 questa è la variante usata dal percorso live delle missioni esterne.
func build_varied_mission(subject: String, level: int, node_count: int = 3, review_due: Dictionary = {}, rng: RandomNumberGenerator = null, mastery: float = -1.0, topic_mastery: Dictionary = {}) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var session := build_mission(subject, level, node_count, review_due, generator, mastery, topic_mastery)
	# Mix target dell'esperienza giocata: la scelta multipla è un formato tra tanti,
	# non il dominante. Obiettivo ~20% MC, ~20% abbina, ~60% al resto (ordina,
	# classifica, grafico, circuito, caccia-all'errore). Con poche campate per
	# missione l'arrotondamento è stocastico per centrare la media sull'insieme.
	var nodes: Array = session.get("nodes", [])
	var target_mc := _stochastic_round(mc_target_for(subject) * float(nodes.size()), generator)
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
	var preferiti: Array = FORMATI_MANIPOLATIVI if mc_target_for(subject) <= 0.0 else []
	session["nodes"] = inject_non_mc(nodes, subject, level, to_replace, generator, preferiti)
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
	"matching": 20, "ordering": 15, "classification": 13,
	# **La linea del tempo pesa come un abbinamento.** (1 settembre 2026)
	# Un formato senza una riga qui dentro prende il peso di ripiego, 10: meno
	# della metà del grafico e del circuito, che sono «tocca una fra N» con un
	# disegno sopra. È il punto 1 del debito dichiarato in `gesto_audit` — i pesi
	# favorivano proprio i formati in cui il gesto non è la competenza. Collocare
	# un evento su una linea del tempo è un gesto di posizione, ed è la forma in
	# cui la cronologia si impara davvero quando la tavola sta davanti.
	"timeline": 20,
	"graph": 25, "circuit": 25, "cycle": 18, "code_debug": 25, "hotspot": 18,
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
]

## Quanto pesa di più un formato preferito nel sorteggio. Tre volte: abbastanza
## perché domini quando c'è, non tanto da escludere gli altri — un esame di soli
## trascinamenti sarebbe monotono quanto uno di sole crocette.
const PESO_PREFERITO := 3.0

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
	var stale: Dictionary = {}     # format -> prove già viste di recente
	var risolte: Dictionary = {}   # format -> prove GIÀ SUPERATE (in fondo a tutto)
	var superate := _superate(subject)
	for draw in range(PALETTE_DRAWS):
		for n in minigame_manager.build_minigame(subject, level, rng).get("nodes", []):
			if ExerciseInteraction.is_multiple_choice(n):
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
		var fmt := _pick_weighted_format(available, used, rng, preferiti)
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
func _pick_weighted_format(formats: Array, used: Dictionary, rng: RandomNumberGenerator, preferiti: Array = []) -> String:
	var weighted: Array = []
	var total := 0.0
	for f in formats:
		var w := float(NONMC_FORMAT_WEIGHTS.get(f, 10))
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
