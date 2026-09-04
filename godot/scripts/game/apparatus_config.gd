class_name ApparatusConfig
extends RefCounted

## Scala di progressione (dati tunable). Per ogni livello definisce quale
## apparato/materia riparare e i gate: quante missioni della materia servono e
## quale soglia di padronanza. Le materie ruotano lungo la scala con difficoltà
## crescente; oltre la tabella esplicita si usa una formula ciclica → 20+ livelli.
##
## Vedi docs/DESIGN_COMPLETO.md §2 (Livelli e progressione).

const MAX_LEVEL := 24

const SUBJECT_APPARATUS := {
	"matematica": "nucleo",
	"coding": "cratere-logico",
	"italiano": "data-core",
	"inglese": "data-core",
	"fisica": "ponte-comando",
	"musica": "motore-risonanza",
	"latino": "sala-glifi",
	"elettronica": "reattore",
	"geografia": "ponte-comando",
	"scienze": "serra-bio",
	"storia": "archivio-temporale",
	"logica": "cratere-logico",
}

# Ordine di rotazione delle materie lungo la scala.
const SUBJECT_CYCLE := [
	"matematica", "italiano", "coding", "inglese", "fisica", "musica",
	"latino", "elettronica", "geografia", "scienze", "storia", "logica",
]

## Materie del NUCLEO: leggere, calcolare, comunicare. Le competenze abilitanti
## su cui poggiano le altre nove.
##
## Il loro rango è cambiato due volte, e la storia serve a non rifarlo una terza.
## Fino al 5 agosto erano **le uniche** a gatare il livello: un bambino saliva in
## dieci minuti e nove materie poteva non toccarle mai. Dal 5 agosto il gate le
## chiede tutte e dodici, e il nucleo è rimasto una dichiarazione senza
## conseguenze.
##
## Dal 6 agosto 2026 il rango non è più «quali materie fermano la progressione»
## ma **quanto alta è l'asticella**. Tutte e dodici restano obbligatorie — è ciò
## che impedisce di fare il minimo — e queste tre ne chiedono di più: soglia di
## padronanza più alta, copertura più ampia, presenza in ogni esame.
## Vedi docs/DESIGN_COMPLETO.md §2 e insieme.md.
const CORE_SUBJECTS := ["italiano", "matematica", "inglese"]

## Quanto più alta sta l'asticella del nucleo. Otto centesimi: al primo mondo
## 0,78 contro 0,70.
##
## Scelto per essere **percepibile ma non escludente**. Più in basso (0,04) il
## bambino non si accorge della differenza e il rango torna una dichiarazione;
## molto più in alto (0,15) chi è debole proprio in queste tre resta fermo, e
## sono le tre materie in cui essere deboli è più comune.
const CORE_MASTERY_BONUS := 0.08

## Tetto assoluto: nemmeno il nucleo all'ultimo mondo può chiedere la
## perfezione. Una soglia a 1,0 si raggiunge solo non sbagliando mai, e
## misurerebbe la fortuna dell'ultima sessione invece della competenza.
const MASTERY_CEILING := 0.95

static func is_core(subject: String) -> bool:
	return CORE_SUBJECTS.has(subject)

## La soglia di QUESTA materia a QUESTO livello: base per tutte, più il bonus
## per le tre del nucleo.
static func subject_mastery_threshold(subject: String, level: int) -> float:
	var base := mastery_threshold(level)
	if is_core(subject):
		return minf(base + core_bonus(level), MASTERY_CEILING)
	return base

## **Quanto piu' alta sta l'asticella del nucleo A QUESTO livello.** (26 agosto 2026)
##
## Il bonus era piatto: 0,08 dal primo mondo all'ultimo. Misurato con
## `gate_mondo1_audit`, era **la sola cosa che rendeva il mondo 1 impossibile** a
## chi risponde giusto sette volte su dieci: la stima di padronanza di un bambino
## cosi' si assesta intorno a 0,767, che sta sopra la soglia base di 0,70 e sotto
## quella del nucleo di 0,78. Non lento: impossibile, a qualunque quantita' di
## lavoro, per sempre.
##
## Il bonus pieno al mondo 1 rendeva però la soglia irraggiungibile per un
## bambino al 70%: gli esercizi non vengono abbassati in base allo studente e
## `target_difficulty(1)` è già il fondo del banco. La soglia iniziale deve
## quindi essere raggiungibile senza cambiare il livello della prova.
##
## Il rango del nucleo resta — e' una decisione del committente del 6 agosto e non
## si tocca — ma cresce con la scala invece di essere pieno subito. Al mondo 1,
## dove tutte e dodici le materie si incontrano per la prima volta e non c'e' un
## gradino piu' facile, il nucleo chiede quanto le altre; all'ultimo chiede gli
## otto centesimi interi, dove il bambino ha una storia alle spalle e il
## contenuto ha spazio per adattarsi.
##
## La rampa resta la valvola del gate; non interviene mai sugli esercizi.
static func core_bonus(level: int) -> float:
	var scala := clampf(float(clampi(level, 1, MAX_LEVEL) - 1) / float(MAX_LEVEL - 1), 0.0, 1.0)
	return CORE_MASTERY_BONUS * scala

## Materia che ABITA il mondo del livello: ne determina lezione, landmark,
## abitanti e trasformazione ambientale.
##
## Distinta da `level_gate()` di proposito. Finché le due cose coincidevano una
## sola funzione bastava; da quando il livello è gatato dal nucleo e il mondo
## resta caratterizzato dalla sua materia, confonderle significherebbe far
## dipendere l'identità di ventiquattro mondi dalla regola di progressione — e
## cambiarne una romperebbe l'altra.
static func world_subject(level: int) -> String:
	var lvl := clampi(level, 1, MAX_LEVEL)
	return str(SUBJECT_CYCLE[(lvl - 1) % SUBJECT_CYCLE.size()])

## Apparato (stanza della nave) di una materia.
static func apparatus_of(subject: String) -> String:
	return str(SUBJECT_APPARATUS.get(subject, "nucleo"))

## Soglia di padronanza del livello: cresce piano lungo la scala.
## Soglia di padronanza del gate: 0,70 al primo mondo, 0,90 all'ultimo.
##
## Il 6 agosto 2026 ho provato ad aggiungere una rampa di avvio più bassa sui
## primi mondi, perché uscire dal mondo 1 costava 128 minuti contro i 33 del
## secondo. Non serviva a niente: misurata, la rampa spostava il costo di
## quattro decimi di minuto. Il collo di bottiglia era altrove — la padronanza
## partiva da zero e la media mobile impiegava cinque sessioni perfette a
## raggiungere la soglia, anche rispondendo sempre giusto.
##
## Corretto quello (`ProgressionManager._padronanza_aggiornata`), il mondo 1 è
## sceso a 27 minuti da solo. La rampa è stata tolta invece di restare come
## manopola che non muove niente.
static func mastery_threshold(level: int) -> float:
	return minf(0.70 + float(clampi(level, 1, MAX_LEVEL) - 1) * 0.007, 0.90)

## Gate del LIVELLO: **tutte** le materie, con la soglia di padronanza.
##
## Non contiene più `subject` né `missionsRequired`. Prima il gate era «una materia
## e N missioni»; dal 30 luglio si sale con la competenza nelle tre strumentali e
## **senza conteggio di giri**. Chi cerca «quale materia abita il mondo N» usa
## `world_subject()`: sono due domande diverse, e tenerle nella stessa funzione
## faceva dipendere l'identità dei mondi dalla regola di progressione.
##
## Dal 5 agosto 2026 le materie sono dodici, non tre: si sale padroneggiando
## **tutte le materie a quel grado di difficoltà**, e la pratica smette di essere
## un extra per diventare la strada.
##
## **Il 24 agosto 2026 questo gate è stato ridotto alla sola materia del mondo, e
## rimesso com'era lo stesso giorno.** La segnalazione era vera — «ho finito il
## mondo 1 con tutti i compiti assegnati e non passo al mondo 2» — ma la causa non
## era l'ampiezza del gate: era che **il mondo non dichiarava come compiti tutto
## quello che il gate chiedeva**. I sette eventi del focus stavano segnati sulla
## mappa; le undici palestre delle altre materie c'erano, ma nessuno le chiamava
## compiti e nessuno diceva quante ne servissero.
##
## Misurato prima di decidere (`compiti_bastano_probe`): completando **tutti** i
## diciotto eventi del mondo una volta ciascuno, il gate si apre al mondo 1 e
## **non** si apre dal mondo 2 in poi — quattro materie restano corte di
## copertura, perché l'unico evento che il mondo dedica a ciascuna vale tre
## argomenti distinti e il gate ne chiede da quattro a sei.
##
## Ridurre il gate a una materia sola avrebbe tolto il blocco cancellando la
## decisione del 5 agosto — e con essa la garanzia delle dodici stanze, che con un
## gate locale si soddisferebbe da sola. La strada presa è l'altra: **il mondo
## dichiara la quota**, cioè quante prove servono ancora per ogni materia, e le
## mette fra i compiti. Vedi [[ObjectiveBriefing.percorso]] e
## `compiti_dichiarati_audit`.
static func level_gate(level: int) -> Dictionary:
	var lvl := clampi(level, 1, MAX_LEVEL)
	return {
		"level": lvl,
		"coreSubjects": Array(SUBJECT_CYCLE).duplicate(),
		"masteryThreshold": mastery_threshold(lvl),
	}

## Gate di un APPARATO: padronanza della sua materia. Riparare un apparato non fa
## salire di livello — accende una stanza.
static func apparatus_gate(subject: String, level: int) -> Dictionary:
	return {
		"subject": subject,
		"apparatus": apparatus_of(subject),
		"masteryThreshold": mastery_threshold(level),
		"core": is_core(subject),
	}
