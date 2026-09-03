class_name StanceChoices
extends RefCounted

## Le scelte di posizione: DATI. Cinque momenti in cui Eli decide **come sta**
## davanti a una cosa, e nessuno in cui decide come va a finire.
##
## **Il difetto che risolvono.** In tutta la campagna il giocatore sceglie una
## volta sola: se il Tredicesimo dorme o viene con te, al mondo 24. Ventiquattro
## mondi di storia in cui la protagonista non prende posizione mai. A dieci anni
## non pesa — la storia la si guarda. A tredici sì: è l'età in cui si comincia a
## pretendere che le proprie reazioni contino qualcosa, e un personaggio a cui
## non si può nemmeno rispondere si smette di sentirlo proprio.
##
## **Perché non sono bivi.** Un bivio vero (due rami di trama) costerebbe il
## doppio del contenuto e romperebbe due guard-rail insieme: §10.2, niente blocca
## il loop, e §10.6, l'errore non ha conseguenze narrative. Se una scelta potesse
## andare male, esisterebbe una scelta sbagliata — e allora il gioco starebbe
## insegnando che ci sono modi sbagliati di sentirsi, che è esattamente il
## contrario di quello che serve a quell'età.
##
## Quindi la regola, ed è verificata: **nessuna opzione è punita, nessuna cambia
## progressione, gate, energia o mastery.** Quello che cambia è che qualcuno se
## ne ricorda. Ogni opzione porta un `eco`: una riga sola, più tardi, che dice al
## giocatore *ti ho sentita*. È tutto lì il meccanismo, ed è sufficiente — la
## sensazione di aver deciso qualcosa non viene dalla ramificazione, viene
## dall'essere stati registrati.
##
## `dove` dichiara il punto d'innesco e `dove_eco` dove torna. Chi mette in scena
## non deve andarli a cercare.

## Quante opzioni può avere una scelta. Due è il minimo perché sia una scelta;
## oltre tre, su un riquadro di dialogo, si legge come un quiz — e un quiz ha una
## risposta giusta, che è la cosa che qui non deve esistere.
const MAX_OPZIONI := 3
const SAVE_KEY := "stanceChoices"

const SCELTE := {
	# La sola già cablata: la regia è in `outdoor_world.gd`, l'arco in
	# `vera_arc.gd`. Le altre quattro aspettano una messa in scena.
	"vera-incrinatura": {
		"dove": "Quando Vera dice che è sempre lei quella che non sa (`VeraArc`).",
		"dove_eco": "La volta dopo che la si incontra, in qualunque mondo.",
		"domanda": "Vera aspetta una risposta.",
		"opzioni": [
			{
				"id": "spiegami-tu",
				"dice": "Allora spiegami tu una cosa. Una qualunque, scegli tu.",
				"eco": "Vera: Ci ho pensato tutta la settimana a cosa spiegarti. Ne ho trovate tre — te le dico in ordine?",
				"punita": false,
			},
			{
				"id": "non-e-colpa-mia",
				"dice": "Non è che lo so perché sono più brava. Lo so perché ci ho sbattuto la testa prima.",
				"eco": "Vera: Ci ho sbattuto la testa anch'io, sai? Su una cosa mia, che tu non sai. Te la faccio vedere?",
				"punita": false,
			},
			{
				"id": "nemmeno-io",
				"dice": "Vera, io non lo so se ho capito. Lo dico e basta, e spero che venga giusto.",
				"eco": "Vera: Quella cosa che hai detto — che dici e speri. Ci penso ancora. Lo fanno tutti secondo te?",
				"punita": false,
			},
		],
	},
	"tredicesimo-domanda": {
		"titolo": "IL TREDICESIMO · UNA DOMANDA",
		"dove": "Mondo 22, quando il Tredicesimo dice «fammi una domanda, una qualunque» e poi si ritira.",
		"dove_eco": "Mondo 24, prima della restituzione del nome.",
		"domanda": "Ha chiesto una domanda e si è già pentito di averla chiesta.",
		"opzioni": [
			{
				"id": "chiedo",
				"dice": "Come si chiamava tua madre?",
				"eco": "Tredicesimo: Nessuno mi chiedeva una cosa che non servisse a niente da quattrocento anni. Grazie.",
				"punita": false,
			},
			{
				"id": "aspetto",
				"dice": "(non dico niente e aspetto)",
				"eco": "Tredicesimo: Non me l'hai fatta, la domanda. Hai aspettato. È stata la cosa più gentile in quattro secoli.",
				"punita": false,
			},
			{
				"id": "chiedo-di-lei",
				"dice": "Che cosa le hai detto, alla ragazzina, quando è partita?",
				"eco": "Tredicesimo: Te l'ho detto male, quel giorno. Le ho detto di non andare. Non le ho detto di tornare.",
				"punita": false,
			},
		],
	},
	"orsolo-prova": {
		"titolo": "ORSOLO · IL «MAH» PIÙ PIANO",
		"dove": "Quando Orsolo passa alla battuta di «prova_accettata» e il «mah» si fa più piano.",
		"dove_eco": "Al Cuore dei Primi, se Orsolo è in scena.",
		"domanda": "Orsolo ha quasi ammesso che avevi ragione.",
		"opzioni": [
			{
				"id": "insisto",
				"dice": "Dillo. Dimmi che avevo ragione, una volta.",
				"eco": "Orsolo: (più piano) Mah. E va bene: avevi ragione. Contento? Io no.",
				"punita": false,
			},
			{
				"id": "glielo-lascio",
				"dice": "Va bene così. Tienitelo pure, il tuo «mah».",
				"eco": "Orsolo: (più piano) Mah. Quella volta che non me l'hai fatto dire. Me la sono segnata.",
				"punita": false,
			},
		],
	},
	# **Il momento in cui Eli si chiude.** (2 settembre 2026)
	#
	# Richiesta esplicita: Eli deve poter stare male per conto suo — *«può
	# chiudersi, rispondere male, non voler parlare per una scena, purché ci sia
	# sempre un modo di ricucire e nessuno gliela faccia pagare»*.
	#
	# Il posto giusto è uno solo, e la trama ce l'aveva già: il mondo 16, dove
	# NORA ammette di averla fatta girare attorno a una stanza **per sedici
	# mondi**. Non è un tradimento — non riesce a guardarla, gliel'hanno fatta
	# così — ma per chi gioca è la prima volta che la persona di cui si fida
	# ammette di aver taciuto a lungo. A tredici anni quello è il momento in cui
	# si smette di parlare, e un personaggio che lì reagisce con un cenno del capo
	# non è più uno con cui ci si identifica.
	#
	# **Nessuna delle tre è la reazione giusta**, come sempre qui: una si chiude,
	# una pretende tutto e subito, una perdona e se lo segna. Sono tre modi veri
	# di prenderla, e il gioco non ne premia nessuno.
	#
	# **La ricucitura è nell'eco, ed è incondizionata.** Al mondo 18 il Tredicesimo
	# parla e conosce il nome vecchio di NORA: è lì che lei torna sull'argomento,
	# qualunque cosa Eli abbia detto. Non chiede scusa in ginocchio e non si
	# giustifica — risponde alla frase precisa che ha ricevuto. Chi si è chiusa
	# viene ripresa; chi ha preteso ottiene; chi si è segnata la cosa se la sente
	# restituire. Il rapporto si ricuce sempre, perché §10.6 vieta che una
	# reazione emotiva abbia conseguenze.
	"eli-tace": {
		"titolo": "ELI · SEDICI MONDI",
		"dove": "Mondo 16, appena NORA ammette di averti girata attorno alla stanza senza porta.",
		"dove_eco": "Mondo 18, quando il Tredicesimo parla e conosce il nome vecchio di NORA.",
		"domanda": "NORA ha appena finito di parlare e sta aspettando.",
		"opzioni": [
			{
				"id": "non-adesso",
				"dice": "Adesso non mi va di parlare. Cammino, e basta.",
				"eco": "NORA: L'altra volta non ti andava di parlare, e ho aspettato. Adesso però ho una cosa da dirti, e vorrei che la sentissi da me.",
				"punita": false,
			},
			{
				"id": "dimmi-tutto",
				"dice": "Allora dimmi adesso tutto quello che non mi hai detto. Anche quello che ti fa paura.",
				"eco": "NORA: Mi avevi chiesto tutto quello che non ti avevo detto. Comincio dalla cosa che mi fa più paura: quella voce sa come mi chiamavo.",
				"punita": false,
			},
			{
				"id": "me-lo-segno",
				"dice": "Ti credo. Però questa me la segno, e se ricapita te lo dico.",
				"eco": "NORA: Te l'eri segnata, e avevi ragione a segnartela. Questa te la dico prima che me la chieda tu: quella voce conosce il mio nome vecchio.",
				"punita": false,
			},
		],
	},
	"squadra-quaderno": {
		"titolo": "SQUADRA · IL FASCICOLO",
		"dove": "Mondo 23, alla traccia di Squadra — l'undicesima sorella, inchiostro di poche settimane fa.",
		"dove_eco": "Mondo 24, dopo il confronto con NORA.",
		"domanda": "Il fascicolo sta lì. Nessuno ti dice cosa farne.",
		"opzioni": [
			{
				"id": "lo-prendo",
				"dice": "(lo prendo e me lo tengo)",
				"eco": "Eli: Ce l'ho ancora, il suo fascicolo. Quando la troviamo glielo restituisco a pezzi di quaderno.",
				"punita": false,
			},
			{
				"id": "lo-lascio",
				"dice": "(lo rimetto dov'era, aperto sull'ultima riga)",
				"eco": "Eli: L'ho lasciato aperto. Se torna prima di noi, deve trovarlo dove l'ha messo.",
				"punita": false,
			},
			{
				"id": "ci-scrivo",
				"dice": "(sotto la sua riga ne scrivo una mia)",
				"eco": "Eli: Le ho risposto sul suo fascicolo. Ho scritto: «guardato. adesso vengo».",
				"punita": false,
			},
		],
	},
	"meridiana-riga": {
		"titolo": "MERIDIANA · SENSORI LUNGHI",
		"dove": "Mondo 23, quando la riga di Meridiana — «c'è qualcosa. venite.» — arriva sui sensori lunghi.",
		"dove_eco": "Beat finale, dopo che la nave assegna la cattedra.",
		"domanda": "Ha scritto quattro secoli fa e sta ancora aspettando una risposta.",
		"opzioni": [
			{
				"id": "rispondo",
				"dice": "Rispondiamole. Anche se ci mette altri quattrocento anni ad arrivare.",
				"eco": "NORA: Il segnale è partito. Due parole: «arriviamo. aspetta».",
				"punita": false,
			},
			{
				"id": "vado",
				"dice": "Non le rispondo. Le rispondo arrivando.",
				"eco": "NORA: Non hai voluto mandarle niente. Hai detto che le parole le porti tu.",
				"punita": false,
			},
		],
	},
}

## --- API -------------------------------------------------------------------

static func scelta(choice_id: String) -> Dictionary:
	return (SCELTE.get(choice_id, {}) as Dictionary).duplicate(true)

static func opzioni(choice_id: String) -> Array:
	return Array((SCELTE.get(choice_id, {}) as Dictionary).get("opzioni", [])).duplicate(true)

## L'eco di quello che il giocatore ha scelto, o "" se non ha scelto niente.
## Chi non ha incontrato la scelta non deve sentirsi mancare qualcosa: l'eco è
## una cosa in più per chi c'era, mai un buco per chi non c'era.
static func eco(choice_id: String, option_id: String) -> String:
	for raw in opzioni(choice_id):
		var option: Dictionary = raw
		if str(option.get("id", "")) == option_id:
			return str(option.get("eco", ""))
	return ""

## --- Stato di campagna -----------------------------------------------------
##
## La scena conserva soltanto tre cose: se il momento è già passato, che cosa
## ha scelto Eli e se la sua eco è già tornata. `incontrata` è distinta dalla
## risposta perché una scelta saltabile deve poter essere saltata davvero,
## senza ricomparire a ogni visita come un modulo non compilato.
static func stato(save_data: Dictionary, choice_id: String) -> Dictionary:
	var narrative: Dictionary = save_data.get("narrative", {})
	var all_states: Dictionary = narrative.get(SAVE_KEY, {})
	return (all_states.get(choice_id, {}) as Dictionary).duplicate(true)

static func dovuta(save_data: Dictionary, choice_id: String) -> bool:
	return SCELTE.has(choice_id) and not bool(stato(save_data, choice_id).get("incontrata", false))

static func registra_risposta(save_data: Dictionary, choice_id: String, option_id: String) -> void:
	if eco(choice_id, option_id) == "":
		return
	_scrivi_stato(save_data, choice_id, {
		"incontrata": true,
		"risposta": option_id,
		"ecoVista": false,
	})

static func registra_salto(save_data: Dictionary, choice_id: String) -> void:
	_scrivi_stato(save_data, choice_id, {
		"incontrata": true,
		"risposta": "",
		"ecoVista": true,
	})

static func risposta(save_data: Dictionary, choice_id: String) -> String:
	return str(stato(save_data, choice_id).get("risposta", ""))

static func eco_pendente(save_data: Dictionary, choice_id: String) -> String:
	var current := stato(save_data, choice_id)
	if not bool(current.get("incontrata", false)) or bool(current.get("ecoVista", false)):
		return ""
	return eco(choice_id, str(current.get("risposta", "")))

## Converte «NORA: testo» nella stessa forma data-driven usata dalle sequenze
## del finale. Il marcatore accompagna la riga fino alla chiusura: è lì, non al
## caricamento, che l'eco diventa davvero vista.
static func eco_entry(save_data: Dictionary, choice_id: String) -> Dictionary:
	var line := eco_pendente(save_data, choice_id)
	if line == "" or not line.contains(":"):
		return {}
	var speaker := line.get_slice(":", 0).strip_edges().to_lower()
	var text := line.substr(line.find(":") + 1).strip_edges()
	return {
		"chi": speaker,
		"dice": [text],
		"stance_echo": choice_id,
	}

static func segna_eco_vista(save_data: Dictionary, choice_id: String) -> void:
	var current := stato(save_data, choice_id)
	if current.is_empty():
		return
	current["ecoVista"] = true
	_scrivi_stato(save_data, choice_id, current)

static func testo_opzione(choice_id: String, option_id: String) -> String:
	for raw in opzioni(choice_id):
		var option: Dictionary = raw
		if str(option.get("id", "")) == option_id:
			return str(option.get("dice", ""))
	return ""

static func _scrivi_stato(save_data: Dictionary, choice_id: String, value: Dictionary) -> void:
	var narrative: Dictionary = save_data.get("narrative", {})
	var all_states: Dictionary = narrative.get(SAVE_KEY, {})
	all_states[choice_id] = value.duplicate(true)
	narrative[SAVE_KEY] = all_states
	save_data["narrative"] = narrative
