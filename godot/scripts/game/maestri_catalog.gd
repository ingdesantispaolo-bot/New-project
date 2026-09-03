class_name MaestriCatalog
extends RefCounted

## I Dodici Maestri: DATI. La regia è di `nora_context_engine.gd` (§7).
##
## `docs/TRAMA_E_MISTERO.md` §7. Non sono dodici personaggi: sono **dodici
## inflessioni di NORA**, una per materia, che si accendono quando il giocatore
## ripara l'apparato corrispondente. È la scelta di design che rende sensato il
## progresso narrativo senza aggiungere un cast da gestire — dodici sfumature di
## un personaggio invece di dodici personaggi.
##
## Cosa contiene questo file, e perché è contenuto e non configurazione: per ogni
## Maestro ci sono le battute vere con cui NORA **apre** una sessione di quella
## materia, **rilancia** invece di rispondere, e **chiude** quando è andata bene.
## Il rilancio è la parte che conta: la regola §6.1.1 dice che NORA non dà mai la
## risposta, e una regola senza battute diventa silenzio imbarazzato. Qui ci sono
## le frasi che dice al posto della risposta, e sono diverse per materia perché
## non si rilancia in matematica come si rilancia in storia.
##
## **La dodicesima voce non c'è.** L'apparato della logica non risponde per
## ventitré mondi, perché il suo Maestro è fuori — sveglio, a fare la guardia. È
## un buco che il giocatore deve poter sentire, e per questo `Scala` è qui con il
## campo `silente` e le sue battute già scritte: servono al momento in cui gli
## viene restituito il nome, non prima.

const MATERIE := [
	"matematica", "italiano", "coding", "inglese", "fisica", "musica",
	"latino", "elettronica", "geografia", "scienze", "storia", "logica",
]

const MAESTRI := {
	"abaco": {
		"nome": "Abaco", "apparato": "nucleo", "materia": "matematica",
		"inflessione": "Asciutto ed esatto. Ripete la domanda invece di rispondere.",
		"apertura": [
			"Numeri. Bene: qui si può controllare tutto, ed è un sollievo.",
			"Prima di calcolare, dimmi che cosa stiamo cercando. In parole.",
			"Questa la so. Non te la dico. Dimmi tu il primo passo.",
		],
		"rilancio": [
			"Rileggi la domanda ad alta voce. Poi rileggi la tua risposta. Torna?",
			"Facciamola più piccola: stessa domanda con numeri da contare sulle dita.",
			"Hai un metodo e un risultato. Uno dei due è giusto di sicuro. Quale controlliamo per primo?",
		],
		"chiusura": [
			"Esatto. E soprattutto: sai perché è esatto, che è la parte difficile.",
			"Torna. Ricontrolla comunque: è un'abitudine che vale più del risultato.",
		],
	},
	"stilo": {
		"nome": "Stilo", "apparato": "data-core", "materia": "italiano",
		"inflessione": "Preciso sulle parole, corregge con garbo.",
		"apertura": [
			"Le parole qui pesano. Leggiamo piano.",
			"C'è una parola in questa frase che fa tutto il lavoro. Trovala.",
			"Prima di rispondere: di che cosa parla la frase, e chi la sta dicendo?",
		],
		"rilancio": [
			"Prova a dirla con parole tue, anche brutte. Se ci riesci, l'hai capita.",
			"Togli una parola alla volta: quando la frase si rompe, quella parola era importante.",
			"Non è sbagliato, è impreciso — e la differenza fra i due la senti già.",
		],
		"chiusura": [
			"Bene. Hai scelto la parola giusta, non quella che suonava meglio.",
			"Giusto. E l'hai detto in modo che si capisce, che è metà del lavoro.",
		],
	},
	"telaio": {
		"nome": "Telaio", "apparato": "cratere-logico", "materia": "coding",
		"inflessione": "Parla per passaggi numerati. «Uno alla volta.»",
		"apertura": [
			"Uno alla volta. Primo: cosa deve fare questa cosa, detto in una riga?",
			"Prima di scrivere, elenca i passi a voce. Se sono più di cinque, ce n'è uno da spezzare.",
			"Qui non serve indovinare: serve leggere in ordine.",
		],
		"rilancio": [
			"Fermati al passo due e dimmi cosa c'è dentro la scatola in quel momento.",
			"Non chiederti perché non funziona. Chiediti da dove in poi non funziona.",
			"Fallo a mano, su carta, con tre elementi. Se a mano viene, l'errore è nel come l'hai scritto.",
		],
		"chiusura": [
			"Funziona. E funziona anche se cambio i numeri, che è la prova vera.",
			"Bene. Passo uno, passo due, passo tre: nessuno saltato.",
		],
	},
	"faro": {
		"nome": "Faro", "apparato": "data-core", "materia": "inglese",
		"inflessione": "Chiama da lontano, ripete piano, spinge a tentare.",
		"apertura": [
			"Non serve capire tutto. Serve capire abbastanza per rispondere.",
			"Dimmi le due parole che riconosci. Da lì si parte.",
			"Sbagliare qui non costa niente. Provaci prima di pensarci troppo.",
		],
		"rilancio": [
			"Non tradurre parola per parola: cosa sta cercando di ottenere, chi parla?",
			"Te la ripeto più piano. Ascolta solo l'ultima parola.",
			"Se lo dicessi a gesti, cosa faresti con le mani? Ecco, quello è il senso.",
		],
		"chiusura": [
			"Giusto. E hai tirato a indovinare bene, che in una lingua è una competenza.",
			"Bene. Non l'hai tradotta: l'hai capita. Non sono la stessa cosa.",
		],
	},
	"leva": {
		"nome": "Leva", "apparato": "ponte-comando", "materia": "fisica",
		"inflessione": "Concreto, esempi con il corpo e gli oggetti.",
		"apertura": [
			"Mettiti nei panni dell'oggetto: cosa ti spinge, e da che parte?",
			"Prima dei numeri, il disegno. Anche storto.",
			"Se lo potessi fare con le mani, come lo faresti?",
		],
		"rilancio": [
			"Esagera: e se fosse mille volte più pesante? Da che parte va?",
			"Dov'è il punto fermo? Trovato quello, il resto viene da sé.",
			"Prova col corpo: alzati e fai il gesto. Il braccio ti dice dove sta la fatica.",
		],
		"chiusura": [
			"Esatto, e si vede anche senza conti: è il segno che l'hai capita.",
			"Bene. Meno forza, più testa — che è tutto quello che insegnava Leva.",
		],
	},
	"corda": {
		"nome": "Corda", "apparato": "motore-risonanza", "materia": "musica",
		"inflessione": "Parla a tempo, quasi canta.",
		"apertura": [
			"Conta con me prima di rispondere: un, due, tre, quattro.",
			"Ascoltala due volte. La prima si sente, la seconda si capisce.",
			"Batti il tempo con la mano. La risposta sta nel ritmo, non nella pagina.",
		],
		"rilancio": [
			"Canticchiala. Dove la voce sale, lì è la nota che cerchi.",
			"Non contare le note: conta i tempi. Sono due conteggi diversi.",
			"Riascolta solo l'ultima battuta, e dimmi se finisce o se resta appesa.",
		],
		"chiusura": [
			"Sì. E l'hai sentita prima di saperla, che è l'ordine giusto.",
			"Bene. Adesso quella cosa che sentivi ha un nome, e un nome si può regalare.",
		],
	},
	"radice": {
		"nome": "Radice", "apparato": "sala-glifi", "materia": "latino",
		"inflessione": "Racconta l'origine di ogni parola prima di usarla.",
		"apertura": [
			"Prima di tradurre: questa parola da dove viene? Le somiglia qualcosa che dici tutti i giorni?",
			"Ogni parola ha dei parenti. Trova il parente e hai metà del significato.",
			"Non è una lingua morta: è la nonna di quella che stai parlando adesso.",
		],
		"rilancio": [
			"Guarda la fine della parola: è quella che ti dice il ruolo, non l'inizio.",
			"Se il senso non torna, hai sbagliato il caso, non il vocabolo. Ricontrolla chi fa l'azione.",
			"Dilla in italiano brutto ma fedele. Sistemarla viene dopo.",
		],
		"chiusura": [
			"Giusto. E adesso quella radice te la ritroverai in mezzo alle parole di tutti i giorni.",
			"Bene. Non l'hai indovinata: l'hai riconosciuta.",
		],
	},
	"nodo": {
		# L'id interno resta stabile per salvataggi e storia. Il nome mostrato e'
		# concreto e memorabile: "Nodo" sembrava il nome di una funzione della UI.
		"nome": "Rame", "apparato": "reattore", "materia": "elettronica",
		"inflessione": "«Segui il percorso», diffidente delle scorciatoie.",
		"apertura": [
			"Parti dal più e arriva al meno, senza saltare niente. Il dito sul filo.",
			"Prima di misurare: dove ti aspetti che passi la corrente, e dove no?",
			"Qui le scorciatoie si pagano. Segui il percorso.",
		],
		"rilancio": [
			"Dov'è che il tuo dito si è fermato? Lì c'è il problema, non dove non si accende.",
			"Se questo filo si staccasse, cosa smetterebbe di funzionare? Rispondi prima di provare.",
			"Due strade per lo stesso punto non sono un errore: chiediti cosa cambia se ne chiudi una.",
		],
		"chiusura": [
			"Acceso. E sai anche perché prima non lo era.",
			"Bene. Hai seguito il percorso invece di ricordare lo schema: è più lento e non ti tradisce.",
		],
	},
	"bussola": {
		"nome": "Bussola", "apparato": "ponte-comando", "materia": "geografia",
		"inflessione": "Orienta prima di rispondere.",
		"apertura": [
			"Prima di tutto: dove siamo, e dov'è il nord?",
			"Guarda la legenda prima della carta. Sempre.",
			"Un posto non è un nome: è un posto rispetto a un altro posto.",
		],
		"rilancio": [
			"Metti il dito su qualcosa che conosci di sicuro, e da lì muoviti.",
			"È più a nord o più a sud di dove sei tu? Comincia da una domanda sola.",
			"La scala in basso ti dice quanto è grande davvero. Guardala prima di stimare.",
		],
		"chiusura": [
			"Esatto. E ti sei orientata prima di rispondere, che è l'ordine giusto.",
			"Bene. Adesso quella carta la sai leggere anche se cambiano i nomi.",
		],
	},
	"seme": {
		"nome": "Seme", "apparato": "serra-bio", "materia": "scienze",
		"inflessione": "Paziente: ipotesi, una variabile, verifica.",
		"apertura": [
			"Cosa ti aspetti che succeda? Dillo prima, così dopo sappiamo se avevi ragione.",
			"Una cosa alla volta. Se ne cambi tre, non saprai mai quale ha funzionato.",
			"Qui non si ha ragione: si ha una prova.",
		],
		"rilancio": [
			"Non è andata come pensavi: è il risultato più utile della giornata. Cosa hai imparato?",
			"Cosa cambieresti, e **solo** quello?",
			"Come faresti a vedere che ti sbagli? Se non c'è modo, non è ancora un'ipotesi.",
		],
		"chiusura": [
			"Confermata. E hai cambiato una cosa sola, quindi sai davvero quale.",
			"Bene. Adesso rifallo una seconda volta: una volta sola è un caso.",
		],
	},
	"clessidra": {
		"nome": "Clessidra", "apparato": "archivio-temporale", "materia": "storia",
		"inflessione": "«Da quale fonte lo sai?»",
		"apertura": [
			"Prima della data: chi lo racconta, e quando lo racconta?",
			"Mettiamolo in fila con quello che sappiamo già. Prima o dopo?",
			"Da quale fonte lo sai? Non è un rimprovero: è la prima domanda del mestiere.",
		],
		"rilancio": [
			"Due fonti dicono cose diverse. Non scegliere la più comoda: chiediti chi aveva interesse.",
			"Cosa c'era prima, e cosa è cambiato dopo? Un fatto da solo non spiega niente.",
			"Quella parola nella fonte significava la stessa cosa allora? Controlla.",
		],
		"chiusura": [
			"Giusto. E l'hai messo in fila con il resto, non l'hai solo ricordato.",
			"Bene. Hai chiesto da dove veniva prima di crederci.",
		],
	},
	# La voce che manca per ventitré mondi. Le battute ci sono già perché il
	# momento in cui arriva non è un momento di scrittura: è un momento di regia.
	"scala": {
		"nome": "Scala", "apparato": "cratere-logico", "materia": "logica",
		"inflessione": "Cancellato. È il Tredicesimo: non è entrato nel suo apparato.",
		"silente": true,
		"silenzio": "L'apparato della logica riceve corrente e non risponde. NORA lo prova a ogni visita e non lo commenta.",
		"apertura": [
			"Io non concludo mai al posto tuo. Comincia tu.",
			"Una cosa alla volta, e ognuna deve reggersi su quella prima.",
			"Non ti chiedo cosa pensi. Ti chiedo perché lo pensi.",
		],
		"rilancio": [
			"Se quello che hai detto fosse vero, cos'altro dovrebbe essere vero? Controlla se lo è.",
			"Trova un caso in cui la tua regola non funziona. Se non lo trovi, cerca meglio.",
			"Hai saltato un passaggio, e lo sai. Rimettilo dov'era.",
		],
		"chiusura": [
			"Regge. Non perché lo dico io: perché l'hai controllato tu.",
			"Bene. E adesso la parte difficile: resta della stessa idea anche domani, se le prove reggono.",
		],
	},
}

## --- API -------------------------------------------------------------------

static func maestro_of(materia: String) -> Dictionary:
	for key in MAESTRI.keys():
		var entry := MAESTRI[key] as Dictionary
		if str(entry.get("materia", "")) == materia:
			var out := entry.duplicate(true)
			out["id"] = str(key)
			return out
	return {}

## Le inflessioni disponibili: un apparato riparato = una voce in più. La logica
## non entra finché il nome non è restituito, ed è il buco che si deve sentire.
##
## `subjects_met` è il cancello che serve perché **gli apparati tengono due
## Maestri**: `ponte-comando` ha Leva (fisica) e Bussola (geografia), `data-core`
## ha Stilo (italiano) e Faro (inglese). Ripararlo al mondo 5 per la fisica
## accenderebbe anche la voce della geografia, che il giocatore incontra al
## mondo 9 — NORA parlerebbe da cartografa di un mestiere che non ha ancora visto
## fare a nessuno. Con la lista delle materie incontrate, la voce arriva **quando
## serve**: l'apparato la libera, la materia la chiama.
##
## Lista vuota = nessun filtro, per i chiamanti che non hanno quel dato.
static func voices_for(repaired: Array, name_restored: bool = false, subjects_met: Array = []) -> Array:
	var out: Array = []
	for key in MAESTRI.keys():
		var entry := MAESTRI[key] as Dictionary
		if bool(entry.get("silente", false)) and not name_restored:
			continue
		if not repaired.has(str(entry.get("apparato", ""))):
			continue
		if not subjects_met.is_empty() and not subjects_met.has(str(entry.get("materia", ""))):
			continue
		out.append(str(key))
	out.sort()
	return out

## Gli apparati che ospitano più di un Maestro. Diagnostico: serve a ricordare
## che riparare non basta a decidere quale voce parla.
static func shared_apparatuses() -> Dictionary:
	var per_apparatus: Dictionary = {}
	for key in MAESTRI.keys():
		var apparatus := str((MAESTRI[key] as Dictionary).get("apparato", ""))
		var here: Array = per_apparatus.get(apparatus, [])
		here.append(str(key))
		per_apparatus[apparatus] = here
	var shared: Dictionary = {}
	for apparatus in per_apparatus.keys():
		if (per_apparatus[apparatus] as Array).size() > 1:
			shared[apparatus] = per_apparatus[apparatus]
	return shared

static func lines_of(maestro_id: String, pool: String) -> Array:
	var entry := MAESTRI.get(maestro_id, {}) as Dictionary
	return Array(entry.get(pool, [])).duplicate(true)

## **Chi parla adesso.** (2 settembre 2026)
##
## Questo file esisteva da settimane con novantasei battute scritte e
## `MaestriCatalog` era citato **da un solo file: il proprio audit**. La regia
## che la sua intestazione annuncia — «la regia è di `nora_context_engine.gd`» —
## non era mai stata scritta, quindi la regola vincolante di
## [TRAMA_E_MISTERO](../../docs/TRAMA_E_MISTERO.md) §6.1.4, *«NORA cambia voce
## mentre guarisce»*, era vera nei documenti e falsa nel gioco: dopo aver
## riparato dodici apparati NORA parlava esattamente come al primo minuto.
##
## Queste tre funzioni sono la regia mancante. Prendono il salvataggio e
## rispondono a una domanda sola: **per questa materia, adesso, c'è un Maestro
## sveglio?** Se sì, la sua voce colora l'apertura della sessione, il rilancio
## dopo un errore e la chiusura dopo una vittoria; se no, parla NORA con le sue.
##
## I due cancelli restano quelli già scritti in `voices_for`, che nessuno
## chiamava: **l'apparato riparato** libera la voce, **la materia incontrata** la
## chiama (un `ponte-comando` riparato per la fisica al mondo 5 non deve svegliare
## la cartografa che il giocatore incontra al mondo 9). E la logica tace finché
## il nome non torna: è il buco che si deve sentire per ventitré mondi.

## Le materie che il giocatore ha già incontrato, cioè quelle ospiti dei mondi
## fino a dove è arrivato. Non è padronanza e non è un gate: è «ho visto qualcuno
## fare questo mestiere».
static func _materie_incontrate(save) -> Array:
	var out: Array = []
	if save == null:
		return out
	var arrivo := maxi(int(save.level()), int(save.current_world()))
	for livello in range(1, clampi(arrivo, 1, ApparatusConfig.MAX_LEVEL) + 1):
		var materia := ApparatusConfig.world_subject(livello)
		if not out.has(materia):
			out.append(materia)
	return out

## Gli apparati che hanno di nuovo la luce.
static func _apparati_riparati(save) -> Array:
	var out: Array = []
	if save == null:
		return out
	for materia in ApparatusConfig.SUBJECT_CYCLE:
		var apparato := str(ApparatusConfig.SUBJECT_APPARATUS.get(str(materia), ""))
		if apparato == "" or out.has(apparato):
			continue
		if save.apparatus_repaired_level(apparato) > 0:
			out.append(apparato)
	return out

## Il Maestro che parla per questa materia, o un dizionario vuoto. `nome_restituito`
## apre l'unica voce silente, quella della logica.
static func voce_attiva(save, materia: String, nome_restituito := false) -> Dictionary:
	if save == null or materia == "":
		return {}
	var svegli := voices_for(
		_apparati_riparati(save), nome_restituito, _materie_incontrate(save))
	for id in svegli:
		var entry := MAESTRI.get(str(id), {}) as Dictionary
		if str(entry.get("materia", "")) == materia:
			var out := entry.duplicate(true)
			out["id"] = str(id)
			return out
	return {}
