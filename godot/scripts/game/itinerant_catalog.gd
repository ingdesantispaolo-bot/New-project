class_name ItinerantCatalog
extends RefCounted

## I sei itineranti: DATI. La rotazione è qui, la regia è di `npc_director.gd`.
##
## `docs/ABITANTI_E_LUOGHI.md` §2.4. Sono il cast fisso — quello a cui ci si
## affeziona — e sono i personaggi che il giocatore incontra **più spesso di
## tutti**: uno solo è presente per mondo, ma quello lì lo rivedi ventiquattro
## volte. Per questo hanno sei registri deliberatamente diversi: qualunque mondo
## apri, la compagnia cambia colore.
##
## Ognuno ha una **funzione di gioco**, e le battute sono raggruppate per quella
## funzione invece che per stadio del mondo: gli itineranti non hanno un arco da
## risolvere, hanno un mestiere da fare accanto a te.
##
## Due regole di regia che valgono per tutti e sei, e sono le più facili da
## sbagliare (§2.4):
##
## - **nessuno fa battute sul giocatore.** Si ride *con* Eli, mai di lei, e mai
##   di un errore. Il bersaglio comico è il personaggio stesso, un oggetto, o
##   Orsolo;
## - **Sesto è comico perché ci scherza per primo.** Un personaggio che dimentica
##   sarebbe triste se il gioco lo trattasse come un problema: lui arriva sempre
##   prima con la battuta, e la sua smemoratezza diventa il suo numero comico
##   invece che la sua ferita.

const ITINERANTI := {
	"itin-nima": {
		"nome": "Nima",
		"registro": "divertente",
		"chi": "Cartografa girovaga: baratta domande invece di merci, e le sue mappe sono bellissime e leggermente sbagliate.",
		"tic": "ti chiama «capitana», e non smette nemmeno quando le spieghi che non lo sei",
		"ticMarker": "capitana",
		"funzione": "orientamento",
		"battute": {
			"saluto": [
				["Capitana! Ti ho disegnata su una mappa, ieri. Eri più alta."],
				["Buongiorno, capitana. Ho tre domande e nessuna merce: barattiamo?"],
				["Capitana. Sei arrivata dal lato sbagliato, ma ci sei arrivata. Conta quello."],
			],
			"orientamento": [
				["Da qui, capitana: la Rovina è dietro il costone. La riconosci perché la usano per tenerci le capre."],
				["Non sei ancora stata al Ritrovo, capitana. Lo so perché lì dentro parlano di te al passato remoto."],
				["Ci sono due strade. Una è più corta e non ti fa vedere niente.", "L'altra è lunga e passa davanti a tutto. Indovina quale ti consiglio, capitana."],
				["Ti manca un posto in questo mondo. Non ti dico quale: te lo dico storto, come le mie mappe.", "È dove il vento cambia idea."],
			],
			"riempimento": [
				["Questa mappa ha un errore. Tutte le mie ce l'hanno: è la firma.", "Se una mappa è perfetta non l'ho fatta io, capitana."],
				["Ho barattato una domanda con un pescatore. Lui voleva sapere dove finisce il mare.", "Gli ho dato una risposta bellissima e completamente inventata."],
				["Capitana, tu che giri: hai mai visto una spirale incisa fresca?", "Io sì. Tre volte. E ogni volta ero arrivata tardi."],
			],
			"congedo": [
				["Vado, capitana. Se ti perdi, perditi verso nord: è più bello."],
				["A presto. Ti lascio la mappa: è sbagliata quanto basta per essere utile."],
			],
		},
	},
	"itin-vera": {
		"nome": "Vera",
		"registro": "curioso",
		"chi": "Coetanea, apprendista di niente, vuole imparare tutto e subito. È il pari: fa le domande che il giocatore ha paura di fare.",
		"tic": "finisce ogni battuta con una domanda, comprese quelle in cui stava rispondendo",
		"ticMarker": "?",
		"funzione": "consolidamento",
		"battute": {
			"saluto": [
				["Ehi! Dove sei stata? Cioè: sei stata da qualche parte dove non sono stata io?"],
				["Ti stavo aspettando. Posso venire? Poi ti lascio in pace, promesso — o forse no?"],
				["Ciao! Hai imparato qualcosa oggi che non sapevi ieri?"],
			],
			# La richiesta di «rispiegamelo»: nomina sempre la parte che non ha
			# capito, non l'argomento intero. Chiedere «me lo rispieghi tutto?»
			# sarebbe una richiesta finta; chiedere «la parte del perché» è la
			# richiesta vera di chi ha capito a metà.
			"rispiegamelo": [
				["Quella cosa dei gruppi uguali… me la rifai?", "Non ho capito la parte del perché funziona sempre. Me la spieghi tu?"],
				["Aspetta, aspetta. Io la so fare, ma se qualcuno mi chiede perché mi blocco.", "A te capita? O sono solo io?"],
				["Me lo ridici con parole tue? Le parole del libro le so a memoria e non mi servono a niente.", "Perché secondo te succede?"],
				["Ho provato a spiegarlo a mio cugino e mi sono impappinata a metà.", "Vuol dire che non l'ho capito davvero?"],
			],
			"capito": [
				["Ahh. AH. Adesso sì.", "Era lì il pezzo che mi mancava. Come hai fatto a sapere qual era?"],
				["Aspetta che me lo ridico da sola… sì. Sì!", "Posso spiegarlo io a qualcun altro adesso?"],
				["Questa me la ricordo per sempre. Lo dico sempre, lo so.", "Però stavolta è vero, no?"],
			],
			"non_capito": [
				["Mmm. No, mi sono persa a metà. Ma non è colpa tua.", "Me lo rifai domani con un esempio diverso?"],
				["Niente, non mi entra. Succede anche a te di sbatterci contro?", "Ci riproviamo quando abbiamo fame di meno?"],
			],
			"riempimento": [
				["Io non sono apprendista di niente, sai? Cioè, sono apprendista di *niente*.", "Si può fare l'apprendista di tutto, secondo te?"],
				["Ho contato le cose che non so. Mi sono fermata a quaranta.", "È tanto o è poco?"],
			],
			"congedo": [
				["Vado! Torno con altre domande. Ne hai ancora di pazienza?"],
				["Ciao! Ah — e quella cosa di prima, me la rispieghi domani?"],
			],
		},
	},
	"itin-orsolo": {
		"nome": "Orsolo",
		"registro": "burbero",
		"chi": "Vecchio riparatore. Non crede alle «storie dei Primi» e lo ripete anche quando gliele dimostri. Esiste perché un mistero senza nessuno che lo neghi non è un mistero: è un'informazione.",
		"tic": "«Mah.» — e quando è d'accordo, «Mah» detto più piano",
		"ticMarker": "mah",
		"funzione": "attrito",
		"battute": {
			"saluto": [
				["Mah. Sei ancora in giro."],
				["Mah. Buongiorno anche a te, immagino."],
				["Ti hanno mandata qui a raccontarmi delle storie? Mah."],
			],
			"dubbio": [
				["Gli antichi. Sempre gli antichi. Mah.", "Se erano così bravi, com'è che non ci sono più?"],
				["Una spirale su un muro. Mah. L'avrà fatta un ragazzino con uno scalpello."],
				["Tu dici che la nave parlava. Mah.", "Portami una cosa che parla e ne riparliamo."],
				["Tutti a dire «i Primi sapevano». Sapevano cosa? Mah.", "Nessuno lo dice mai, e questo mi basta."],
			],
			# La conversione: lenta, e mai ammessa. È il «mah» detto più piano.
			"prova_accettata": [
				["(più piano) Mah.", "…dove l'hai trovata, questa?"],
				["(più piano) Mah. Non dico che hai ragione.", "Dico che non ho niente da dirti, che è diverso."],
				["(più piano) Mah. Rimettila dov'era, che non si rovini."],
			],
			"riempimento": [
				["Ho riparato una porta stamattina. Non era rotta. Mah.", "Adesso però si chiude meglio."],
				["La gente ringrazia e poi rompe di nuovo la stessa cosa. Mah."],
			],
			"congedo": [
				["Mah. Vai, vai. Ho da fare."],
				["(più piano) Mah. Torna quando hai un'altra cosa da farmi vedere."],
			],
		},
	},
	"itin-sesto": {
		"nome": "Sesto",
		"registro": "buffo",
		"stesso_di": "w03-sesto",
		"chi": "Uno Sbiadito restituito a sé stesso nel mondo 3. Dimentica, e ci scherza sopra prima che lo faccia qualcun altro.",
		"tic": "scambia le parole: «passami il… coso che conta. Il conta-coso»",
		"ticMarker": "coso",
		"funzione": "ripasso spaziato",
		"battute": {
			"saluto": [
				["Piacere, Se— ah no, ci conosciamo. Lo sapevo, coso."],
				["Eccoti! Ti stavo aspettando da… da un coso. Da un po'."],
				["Ciao! Ho preparato una domanda e me la sono dimenticata. Il coso della domanda, insomma."],
			],
			# Chiede aiuto proprio sugli argomenti che il giocatore ha in scadenza:
			# ripassare smette di essere una punizione e diventa aiutare un amico.
			"ripasso": [
				["Senti, quella cosa dei numeri che saltano a gruppi… il salta-coso.", "Me la rifai? Io l'avevo capita e adesso è scappata."],
				["Mi serve il coso delle parole parenti. Come si chiamava?", "Ecco, quello. Rifacciamolo insieme, che a me da solo non torna."],
				["Ho un buco. Un coso vuoto qui in mezzo.", "Era una cosa che sapevo fare bene. Aiutami a ritrovarla?"],
				["Ti ricordi quella regola con i due passaggi? Il doppio-coso?", "Io mi ricordo solo il primo. Il secondo l'ha preso il vento."],
			],
			"grazie": [
				["Ecco! Era quello. Il coso giusto.", "Grazie. Domani me lo dimentico di nuovo, ma oggi ce l'ho."],
				["Guarda che bello: l'ho rifatto da solo.", "Il coso ha funzionato. Cioè il metodo. Il metodo-coso."],
				["Non è che me lo ricordo. È che adesso lo so rifare.", "Non sono la stessa cosa, vero? Vero."],
			],
			"riempimento": [
				["Ho tre tasche e in ognuna c'è un coso che non so cos'è.", "Uno è un sasso. Sono abbastanza sicuro del sasso."],
				["La gente si dispiace quando dimentico. Io no: io mi rincontro.", "Piacere, Sesto. Vedi? Due amici al prezzo di uno."],
			],
			"congedo": [
				["Vado. Se domani mi ripresento da capo, stai al gioco: mi diverte, coso."],
				["Ciao! Ricordati tu per me, che io ci provo e non ci riesco."],
			],
		},
	},
	"itin-cinabro": {
		"nome": "Cinabro",
		"registro": "misterioso",
		"chi": "Narratore mascherato, baratta storie in cambio di fatti. Sa troppo, ed è sempre nel mondo dove la spirale è più fresca.",
		"tic": "parla di sé in terza persona, e sbaglia apposta il proprio nome",
		"ticMarker": "cinab",
		"funzione": "mistero e falsa pista",
		"battute": {
			"saluto": [
				["Cinabrio saluta. …Cinabro. Cinabro saluta."],
				["Ah, la viaggiatrice. Cinaboro ti aspettava, e Cinaboro non aspetta quasi mai nessuno."],
				["Cinabro ha una storia. Cinabro vuole un fatto in cambio. Comincia tu."],
			],
			# La falsa pista: mai una bugia, sempre una verità messa in modo da
			# far pensare la cosa sbagliata. Al colpo 6 si scopre che le spirali
			# le incide davvero — insieme ad altre centinaia di persone.
			"indizio": [
				["Cinabro è arrivato ieri. La spirale sul costone è di stanotte.", "Cinabro non dice altro. Cinabro non dice mai altro."],
				["La ragazzina delle spirali? Cinabrio l'ha conosciuta.", "…in un certo senso. Cinabro conosce molta gente in un certo senso."],
				["Cinabro ha le mani sporche di polvere di pietra. È un mestiere, o è una prova?", "Scegli tu: le storie funzionano meglio se le finisci da solo."],
				["Cinaboro sa dov'è la Rovina di questo mondo senza esserci mai stato.", "Non è magia. È che sono tutte nello stesso posto, se sai guardare."],
			],
			"baratto": [
				["Una storia per un fatto. Cinabro comincia: c'era una nave che girava in tondo.", "Adesso tocca a te, e Cinabro vuole qualcosa di vero."],
				["Cinabro ha già questa storia. Cinabro ne vuole una che non ha.", "Raccontagli cosa hai visto oggi, non cosa ti hanno detto."],
			],
			"riempimento": [
				["Cinabro dorme poco. Cinabro cammina molto. Cinabro non spiega perché."],
				["Il nome vero di Cinabro non lo sa nemmeno Cinabro. Comodo, no?", "Chi non ha un nome può averne quattrocento."],
			],
			"congedo": [
				["Cinabro va. Cinabro sarà nel mondo dove la pietra è più fresca."],
				["Addio, viaggiatrice. Cinabrio ti pensa. …Cinabro. Cinabro ti pensa."],
			],
		},
	},
	"itin-lucilla": {
		"nome": "Lucilla",
		"registro": "caloroso",
		"chi": "Alleva e cura i Custodi. Ha un'opinione molto forte su ogni pet e nessuna sulle persone.",
		"tic": "parla al tuo Custode, non a te, e riferisce a te ciò che il Custode «ha detto»",
		"ticMarker": "dice che",
		"funzione": "compagno",
		"battute": {
			"saluto": [
				["Ciao, tesoro! …no, non tu. Dicevo a lui.", "Dice che siete stati in un posto pieno di scale."],
				["Guardalo! Guarda che pelo. Dice che dormi poco e che dovresti mangiare meglio."],
				["Buongiorno a tutti e due. Lui dice che vi siete alzati tardi, ma non lo tradisce nessuno."],
			],
			"custode": [
				["Questo qui ha bisogno di una carezza sulla testa, non sul collo.", "Dice che sul collo lo fai per abitudine e che non gli piace tanto."],
				["Mangia? Dorme? Fa quella cosa con la coda quando risolvi qualcosa?", "Dice che la fa apposta. Io gli credo."],
				["Ogni Custode ha una sua indole e questo qui è di quelli che aspettano.", "Dice che aspetta te, e a me pare vero."],
				["Non gli piace il buio, ma non te lo direbbe mai.", "Dice che se lo tiene, per non farti preoccupare."],
			],
			"legame": [
				["Sai qual è la cosa che gli piace di più? Non i regali.", "Dice che gli piace quando ti fermi a guardarlo prima di ripartire."],
				["State insieme da un po', ormai. Si vede da come si mette accanto a te.", "Dice che all'inizio non era sicuro. Adesso sì."],
			],
			"riempimento": [
				["Ne ho cresciuti quarantadue, di Custodi. Delle persone non capisco niente.", "Lui dice che è perché le persone parlano troppo."],
				["C'è chi crede che facciano le facce a caso. Non è vero.", "Dice che ci mette impegno, e io ci credo perché l'ho visto provare."],
			],
			"congedo": [
				["Andate, andate. Dice che ha voglia di camminare."],
				["A presto, tesoro. …no, sempre a lui. Dice di salutarti da parte sua."],
			],
		},
	},
}

## --- Rotazione --------------------------------------------------------------
##
## Uno solo per mondo, deterministico da seme e livello — così due partite con lo
## stesso seme incontrano gli stessi compagni, e due semi diversi no. Il vincolo
## che conta è che **non si ripeta due mondi di fila**: rivedere la stessa faccia
## due volte consecutive fa sembrare il cast piccolo, che è esattamente il
## contrario di quello che serve.
## Non una progressione aritmetica: un **mescolamento a blocchi di sei**. Ogni
## blocco contiene tutti e sei una volta sola — così nessuno sparisce per mezza
## campagna — ma l'ordine dentro il blocco cambia con il seme, e se il primo del
## blocco nuovo è l'ultimo del blocco vecchio si scambia con il secondo.
##
## Ci ero arrivato prima con un passo moltiplicativo, ed era sbagliato: con sei
## elementi un passo di 3 percorre due sole facce su ventiquattro mondi. Se ne è
## accorto l'audit, che misura la rotazione invece di crederci.
static func itinerant_for(campaign_seed: int, level: int) -> String:
	var ids: Array = ITINERANTI.keys()
	ids.sort()
	var count := ids.size()
	var block_index: int = (maxi(level, 1) - 1) / count
	var position: int = (maxi(level, 1) - 1) % count

	var block := _shuffled_block(ids, campaign_seed, block_index)
	if block_index > 0:
		var previous := _shuffled_block(ids, campaign_seed, block_index - 1)
		if str(block[0]) == str(previous[count - 1]):
			var swap = block[0]
			block[0] = block[1]
			block[1] = swap
	return str(block[position])

static func _shuffled_block(ids: Array, campaign_seed: int, block_index: int) -> Array:
	var block: Array = ids.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d/%d" % [campaign_seed, block_index])
	for i in range(block.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = block[i]
		block[i] = block[j]
		block[j] = swap
	return block

static func itinerant(itinerant_id: String) -> Dictionary:
	return (ITINERANTI.get(itinerant_id, {}) as Dictionary).duplicate(true)

static func lines_of(itinerant_id: String, pool: String) -> Array:
	var pools := (ITINERANTI.get(itinerant_id, {}) as Dictionary).get("battute", {}) as Dictionary
	return Array(pools.get(pool, [])).duplicate(true)

## Tutte le battute di un itinerante, per gli audit.
static func all_lines(itinerant_id: String) -> Array:
	var pools := (ITINERANTI.get(itinerant_id, {}) as Dictionary).get("battute", {}) as Dictionary
	var out: Array = []
	var names: Array = pools.keys()
	names.sort()
	for pool in names:
		out.append_array(pools[pool])
	return out
