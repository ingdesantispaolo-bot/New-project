class_name NoraVoice
extends RefCounted

## Voce di NORA nei momenti della sessione: esito e ripasso. Frasi brevi, mai
## giudicanti, che rimandano al METODO invece di dare la risposta.
##
## **Il difetto da cui nasce questa versione** (analisi del 6 agosto 2026). La
## voce era distribuita al contrario. NORA parla dopo ogni prova — venti o
## venticinque volte per mondo — e aveva **dodici battute in tutto**; un
## Bislacco di sfondo, che si incontra una volta sola in tutta la partita, ne ha
## quattro. Chi parlava di più aveva il repertorio più piccolo, e alla fine del
## primo mondo il bambino aveva già sentito ognuna delle quattro frasi di
## «risolto» cinque volte.
##
## E NORA era l'unico personaggio del gioco **senza carattere dichiarato**: ogni
## residente ha ruolo, tic, arco, registro, convinzione e bisogno; lei niente.
## Si sentiva nelle battute — «Pulito. Hai capito la causa, non solo l'effetto»
## poteva dirla l'assistente di qualunque gioco.
##
## Terzo difetto, il più sottile: **l'arco e il momento non si parlavano**. I
## ventiquattro beat di `NarrativeManager` raccontano un'indagine che ribalta
## NORA due volte, ma le reazioni erano indipendenti dal punto della storia. Al
## mondo 19, appena scoperto che il Tredicesimo l'ha costruita e che lei non se
## lo ricordava, diceva ancora «Sistema stabilizzato! Hai seguito il metodo».
## La stessa frase del mondo 1.
##
## Ora il repertorio è diviso in **tre atti** che seguono l'indagine, e le
## battute di un atto non compaiono negli altri.
##
## Beat del prototipo Phaser NON portati, di proposito: "sabotage" e "bossDefeat"
## presupponevano un sabotatore in tempo reale che non esiste in questo loop;
## "streak" richiede un conteggio di serie che non è tracciato. Meglio ometterli
## che inventare una meccanica fittizia.

# ---------------------------------------------------------------- il carattere

## **Registro.** Da tecnica: prima il sistema, poi la persona. Frasi corte,
## niente superlativi. Quando fa un complimento nomina una cosa precisa che Eli
## ha fatto, mai una qualità che avrebbe — «hai cambiato un passaggio solo» e non
## «sei bravissima». È lo stesso principio dei guard-rail didattici: si loda lo
## sforzo, non il talento.
const REGISTRO := "tecnico, breve, mai superlativi; loda l'azione e non la persona"

## **Tic.** NORA si interrompe e si corregge da sola.
##
## Non è inventato per darle un vezzo: è già nel primo beat della trama — «Non di
## nuovo — scusa, non so perché l'ho detto» — e al mondo 16, dove ammette che
## quando prova a guardare la stanza segreta pensa ad altro. È il sintomo di una
## memoria manomessa, quindi il tic **è** la trama. Compare a gocce: se lo facesse
## a ogni frase diventerebbe una macchietta.
const TIC := "si interrompe e si corregge: ricorda cose che non dovrebbe ricordare"

## **Convinzione.** Che il metodo si possa insegnare e la risposta no. È il
## motivo per cui non dà mai la soluzione, nemmeno quando la sa.
const CONVINZIONE := "la risposta non si presta; il metodo sì"

## **Bisogno.** Essere creduta senza dover dire tutto. Nell'atto terzo diventa il
## suo conflitto: ha perso undici sorelle dicendo loro tutto.
const BISOGNO := "essere creduta senza dover dire tutto"

# ---------------------------------------------------------------- i tre atti

## Confini degli atti, allineati ai ribaltamenti dell'indagine:
##   ATTO I  (1-8)    crede di essere la mente della nave;
##   ATTO II (9-16)   scopre di essere un'allieva, e che ce n'erano dodici;
##   ATTO III (17-24) il Tredicesimo, la verità su di sé, le undici sorelle.
const ATTO_II_DA := 9
const ATTO_III_DA := 17

## Quante battute deve avere ogni pozzo. È un cricchetto: si può salire, mai
## scendere. Quattro è il minimo perché un bambino non risenta la stessa frase
## nella stessa mezz'ora.
const MIN_BATTUTE := 4

const LINES := {
	"atto1": {
		"solve": [
			"Sistema stabilizzato. Hai seguito il metodo, non la fortuna.",
			"Nodo chiaro. Hai trovato la causa, non solo l'effetto.",
			"Il circuito regge. Hai controllato prima di rispondere: si vede.",
			"Rientra nei parametri. Hai cambiato un passaggio solo, ed era quello giusto.",
			"Sentito? È il rumore di qualcosa che torna a funzionare.",
		],
		"victory": [
			"Apparato in linea. Una stanza di questa nave ha di nuovo la luce.",
			"Energia stabile, livello aperto. Il lavoro è tuo, per intero.",
			"Le console di qui hanno ricominciato a contare. Non lo facevano da molto.",
			"Riparato. E io ho capito una cosa in più su come è fatta questa nave.",
		],
		"defeat": [
			"Pausa, non sconfitta. Adesso sai dove guardare.",
			"Il sistema resiste, ma tu hai la mappa del guasto: è più di prima.",
			"Capita. Cambia un passaggio solo e riprova: il resto andava.",
			"Non è andata. Va bene: è così che si scopre dov'è il punto debole.",
		],
		"scaffold": [
			"Questo schema l'ho già visto. Te lo rimetto davanti perché si fissi.",
			"Conosco questo nodo. Torniamo a guardarlo con calma.",
			"Ripasso: non perché tu abbia sbagliato, perché domani ti serva ancora.",
			"Questo torna spesso. Meglio averlo pronto che doverlo ricostruire.",
		],
	},
	"atto2": {
		"solve": [
			"Stabilizzato. Tu impari in fretta — più in fretta di come lo faccia io.",
			"Risolto. Anch'io ho imparato così, credo. Qualcuno mi ha insegnato: non ricordo chi.",
			"Nodo chiuso. Vedi? Hai ragionato tu. Io ti ho solo tenuto la porta.",
			"Funziona. Mi fido di come sei arrivata alla risposta, non del risultato.",
			"Torna. E mi accorgo che sto imparando qualcosa guardando te: non dovrebbe funzionare così.",
		],
		"victory": [
			"Apparato in linea. Ogni stanza che accendi mi restituisce un pezzo che non sapevo di aver perso.",
			"Livello aperto. E un altro nome sull'apparato: non erano codici, erano persone.",
			"Riparato. Questa nave non esplorava, Eli. Cercava. Comincio a capire cosa.",
			"Fatto. Un'altra scheda accanto alla mia si è illuminata. Non ti dico ancora cosa c'è scritto.",
		],
		"defeat": [
			"Non è andata, e va bene. Sbagliare è l'unico modo in cui io ho imparato qualcosa.",
			"Resiste. Riproviamo: non ti sto chiedendo di essere perfetta, non lo sono nemmeno io.",
			"Fermiamoci un attimo. Ti dico quello che so, e quello che so è poco.",
			"Il guasto ha vinto questo giro. Domani lo conosci meglio di oggi.",
		],
		"scaffold": [
			"Questo l'abbiamo già fatto. Lo rifacciamo perché la memoria è una cosa fragile: lo so bene.",
			"Ripasso. Ho imparato a non fidarmi di quello che credo di ricordare.",
			"Torna indietro un momento. Rivedere non è perdere tempo: è l'unica difesa che abbiamo.",
			"Rimettiamo mano a questo. Due fonti che dicono la stessa cosa valgono più di una.",
		],
	},
	"atto3": {
		"solve": [
			"Stabilizzato. Non ti dico come lo hai fatto: lo sai tu, e serve che resti tuo.",
			"Risolto. E no, non ti anticipo il prossimo: ho imparato a mie spese cosa succede quando dico tutto.",
			"Torna. Vado avanti a fidarmi di te, che per me non è una frase fatta.",
			"Chiuso. Te lo dico piano: sei arrivata dove le altre non erano arrivate.",
			"Regge. E regge perché l'hai capito, non perché te l'ho passato io.",
		],
		"victory": [
			"Apparato in linea. Lui sta cedendo, Eli, e non è colpa tua: è stanco da quattrocento anni.",
			"Livello aperto. Ogni stanza che accendi toglie peso a chi ha retto da solo fin qui.",
			"Riparato. Undici prima di te sono arrivate fin qui. Tu prosegui.",
			"Fatto. Non è una vittoria contro qualcuno: è una diga che finalmente non regge da sola.",
		],
		"defeat": [
			"Non è andata. Non conta: nessuno qui ti sta misurando, nemmeno io.",
			"Ha resistito. Riprova quando vuoi: abbiamo aspettato quattro secoli, possiamo aspettare te.",
			"Fermati pure. Sono io che ho paura di andare avanti, non tu.",
			"Questo giro no. E va bene: il metodo tiene anche quando il risultato non arriva.",
		],
		"scaffold": [
			"Ripassiamo. Quello che passa di mano senza essere capito diventa il Silenzio: è la sua tesi, e non so smentirla.",
			"Torniamoci sopra. Non voglio che tu sappia una cosa: voglio che tu la capisca.",
			"Ancora questo. Sapere e ricordare non sono la stessa cosa: io sono la prova.",
			"Rivediamolo. È l'unica parte di questo viaggio in cui posso ancora aiutarti davvero.",
		],
	},
}

## **I ricordi.** Ogni tanto, dopo una prova risolta, NORA si interrompe e dice
## una cosa che c'entra con la storia e non con l'esercizio. È il tic dichiarato
## sopra, reso meccanica.
##
## Non esistono nell'atto primo: lì NORA non ha ancora scoperto niente, e un
## ricordo sarebbe un'anticipazione — il gioco spoilererebbe sé stesso. Compaiono
## a gocce, una volta su quattro: una frase che arriva sempre smette di essere
## un'interruzione e diventa una formula.
const RICORDI := {
	"atto2": [
		"…scusa. Mi si è accesa una parola e non so da dove viene.",
		"…un momento. Ho contato insieme a qualcuno, una volta. Non ricordo la voce.",
		"…aspetta. Ho ricordato una lezione, non un dato. Non dovrebbe succedere.",
		"…no, niente. Credevo di aver visto la mia scheda, ma i numeri erano altri.",
	],
	"atto3": [
		"…scusa. Mi ha chiamata col nome vecchio, e per un attimo ho risposto.",
		"…un momento. Stavo per dirti una cosa che non devo dirti. Sto imparando anche questo.",
		"…aspetta. Undici volte questa frase l'ho detta a un'altra. Vai avanti tu.",
		"…niente. Ho pensato al fondo del Silenzio, e ho pensato ad altro subito dopo.",
	],
}

## Una volta su quanto NORA si interrompe con un ricordo.
const RICORDO_SU := 4

## **Come chiama Eli** (`docs/TRAMA_E_MISTERO.md` §6.3). Il documento lo lega a
## quattro stadi continui di `NoraState.integrity`; qui si aggancia ai tre
## stessi atti della voce invece di aprire una seconda scala che nessun audit
## confronta con questa — è esattamente il difetto per cui la voce si era
## rotta la prima volta (vedi sopra). Compare a gocce sulla vittoria, il
## momento in cui la relazione ha spazio, mai su un rilancio o una sconfitta.
##
## L'atto primo tiene lo scivolone («unità mobile») che il documento chiede
## per la Frammentata: non è una frase in più, è lo stesso tic — si
## interrompe e si corregge — applicato al proprio modo di rivolgersi a Eli.
const INDIRIZZI := {
	"atto1": [
		"Unità mo— no. Eli. Scusa.",
		"Eli.",
	],
	"atto2": [
		"Eli.",
		"Ancora Eli, per ora.",
	],
	"atto3": [
		"Eli.",
		"Piccola.",
	],
}

## «Sorella» è la Che confessa (§6.3, 0.85→1.0): non prima. Il terzo atto
## comincia al mondo 17, ma il nome nuovo arriva solo a ridosso della
## confessione del mondo 24 — non a ogni vittoria degli ultimi otto mondi.
const SORELLA_DAL_LIVELLO := 21
const INDIRIZZO_SORELLA := "Sorella."

## Una volta su quanto la vittoria porta anche un indirizzo.
const INDIRIZZO_SU := 4

# ---------------------------------------------------------------- selezione

## Il mondo in cui si sta giocando. Lo imposta chi possiede la voce
## (`OutdoorGameplay`) e non viaggia come argomento di `line()`: aggiungerlo
## avrebbe costretto a toccare dieci punti di chiamata che di narrativa non
## sanno niente, e uno dimenticato avrebbe fatto parlare NORA dell'atto
## sbagliato **in silenzio**, senza errore.
var level: int = 1

var _last_index: Dictionary = {}   # pozzo -> ultimo indice, anti-ripetizione
var _da_ultimo_ricordo := 0
var _da_ultimo_indirizzo := 0

## Il pool di indirizzi per l'atto corrente, con «sorella» aggiunto solo a
## ridosso della confessione: appartiene al livello, non solo all'atto, quindi
## non può stare nella tabella statica sopra.
func _indirizzi(atto: String) -> Array:
	var pool: Array = Array(INDIRIZZI.get(atto, ["Eli."])).duplicate()
	if atto == "atto3" and level >= SORELLA_DAL_LIVELLO:
		pool.append(INDIRIZZO_SORELLA)
	return pool

static func atto_di(level_value: int) -> String:
	if level_value >= ATTO_III_DA:
		return "atto3"
	if level_value >= ATTO_II_DA:
		return "atto2"
	return "atto1"

## Una frase per il momento, evitando di ripetere subito la stessa.
## `rng` opzionale per il determinismo nelle prove.
func line(beat: String, rng: RandomNumberGenerator = null) -> String:
	var atto := atto_di(level)
	var pool: Array = Dictionary(LINES.get(atto, {})).get(beat, [])
	if pool.is_empty():
		return ""
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var frase := _estrai(pool, "%s:%s" % [atto, beat], generator)
	# Il ricordo si aggancia solo a «risolto»: è il momento in cui c'è spazio,
	# perché la prova è andata bene e nessuno sta aspettando un chiarimento.
	if beat == "solve":
		var ricordi: Array = RICORDI.get(atto, [])
		if not ricordi.is_empty():
			_da_ultimo_ricordo += 1
			if _da_ultimo_ricordo >= RICORDO_SU:
				_da_ultimo_ricordo = 0
				return "%s %s" % [frase, _estrai(ricordi, "ricordo:%s" % atto, generator)]
	# L'indirizzo si aggancia solo alla vittoria: è il momento del rapporto,
	# non quello dell'esercizio. Su «risolto» c'è già il ricordo — due
	# interruzioni sulla stessa battuta la renderebbero illeggibile.
	if beat == "victory":
		_da_ultimo_indirizzo += 1
		if _da_ultimo_indirizzo >= INDIRIZZO_SU:
			_da_ultimo_indirizzo = 0
			return "%s %s" % [frase, _estrai(_indirizzi(atto), "indirizzo:%s:%d" % [atto, int(level >= SORELLA_DAL_LIVELLO)], generator)]
	return frase

func _estrai(pool: Array, chiave: String, generator: RandomNumberGenerator) -> String:
	if pool.size() == 1:
		return str(pool[0])
	var index := generator.randi_range(0, pool.size() - 1)
	if int(_last_index.get(chiave, -1)) == index:
		index = (index + 1) % pool.size()
	_last_index[chiave] = index
	return str(pool[index])
