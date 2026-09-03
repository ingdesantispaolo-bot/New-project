class_name FinaleCatalog
extends RefCounted

## Il mondo 24 · Cuore dei Primi: DATI della convergenza. La sequenza è in
## `docs/FINALE_SPEC.md` e la regia è di Codex.
##
## Il mondo 24 **non ha residenti suoi** (§3 del documento abitanti): al Cuore
## convergono i sei itineranti e i residenti che hai portato allo stadio 2, al
## massimo quattro in scena per volta. È l'unica cosa nel gioco che dice
## esplicitamente *chi ti aspetta dipende da chi hai fatto crescere*, ed è per
## questo che qui non c'è una lista di comparse: c'è **una riga per ognuno dei 46
## residenti**, e quella riga esiste solo se quel residente è arrivato in fondo
## al suo arco.
##
## La regola vale anche al contrario, ed è la parte che protegge il giocatore:
## **il Cuore non è mai vuoto**. Chi non ha portato nessuno allo stadio 2 trova
## comunque gli itineranti, che ci sono sempre. Nessuno viene punito al finale per
## come ha giocato — e nessuna di queste battute nomina ciò che il giocatore *non*
## ha fatto.

const MAX_IN_SCENA := 4

## Gli itineranti al Cuore: ci sono tutti e sei, sempre. Sono il cast fisso, e il
## finale è il posto in cui si vede che erano un cast.
const ITINERANTI := {
	"itin-nima": ["Capitana. Ho disegnato anche questo posto, e stavolta la mappa è giusta.", "Non me lo perdonerò mai."],
	"itin-vera": ["Sei arrivata fin qui. Me lo rispieghi tutto, dopo?", "Cioè: dall'inizio. Tutto quanto. Posso?"],
	"itin-orsolo": ["Mah.", "(più piano) Mah. …avevi ragione tu, e non lo dirò una seconda volta."],
	"itin-sesto": ["Piacere, Sesto. Ci conosciamo?", "…scherzavo. Ti conosco benissimo. È la prima volta che lo dico e so che è vero."],
	"itin-cinabro": ["Cinabrio è venuto a vedere come finisce. …Cinabro.", "Cinabro non sa come finisce. Nessuno lo sa. È il bello."],
	"itin-lucilla": ["Guardalo, tesoro. Dice che ha capito dove siamo.", "Dice anche che non ha paura. Su quello mente, ma con affetto."],
}

## Una riga per residente, e ognuna dice **cosa ha smesso di credere**. Non sono
## saluti: sono la prova che quell'arco è successo davvero. Chi non è arrivato
## allo stadio 2 non è qui, e nessuno lo nomina.
const RESIDENTI := {
	"w01-tobia": ["Ho contato i settori. Dodici, a gruppi di quattro.", "Tre colpi invece di dodici, e uno."],
	"w01-ersilia": ["Cuore, guarda quanta strada. E io che credevo di cantare una canzone.", "Tieni, mangia: là dentro chissà quando si mangia."],
	"w02-corinna": ["Ho catalogato questo posto per funzione, non per forma.", "Le dita mi servono ancora, ma per contare le persone."],
	"w02-bruno": ["Ho inventato un nome per il Cuore e Corinna l'ha scritto.", "E questa come la chiami, se non una parola vera?"],
	"w03-ruggine": ["(soffia sulla chiave) Una riga, e la macchina ha fatto il resto.", "Non è pigrizia. Me l'hai fatto capire tu."],
	"w03-sesto": ["Piacere, Sesto. E stavolta me lo ricordo, il tuo nome.", "Ho ritrovato la cosa che sapevo fare: era insegnare."],
	"w04-marea": ["(sussurra) Ho risposto al faro senza tradurre.", "Ho capito, e basta. Non credevo si potesse."],
	"w04-lino": ["Captain! Ho spedito la lettera.", "Venti parole non bastavano. Adesso ne so quaranta e piango lo stesso."],
	"w05-gerbo": ["Ho spostato il masso con un sasso e un palo.", "(si guarda le mani) Queste servono ancora. Solo, non da sole."],
	"w05-tilla": ["Te lo faccio vedere? …no. Stavolta guardo io te."],
	"w06-ambra": ["Mmh. Ho dato un nome a tutto quello che sento.", "E sento ancora tutto. Non si è rotto niente."],
	"w06-oreste": ["(mano sulla parete del Cuore) Trema di sette.", "Adesso so anche come si chiama quello che sento."],
	"w07-livia": ["(soffia sull'inchiostro) Ho copiato meno e ho letto di più.", "È stato l'anno più lento e più utile della mia vita."],
	"w07-zeno": ["E questa di chi è parente? Di tutto, credo.", "Il mio gioco era studiare. Nessuno me l'aveva detto."],
	"w08-ciro": ["Uno, due, tre nodi. E stavolta so cosa fa ognuno.", "Se me li spostano, li ritrovo."],
	"w08-doria": ["L'acqua e la corrente vanno d'accordo più di quanto credessi.", "Chiedilo a una chiusa, se non mi credi."],
	"w09-alma": ["(bagna la matita) Ho disegnato un posto in cui non sono mai stata.", "Ed è venuto giusto. Ancora non me ne capacito."],
	"w09-remo": ["Le mie rotte sono scritte. Tutte.", "Adesso possono trovare la strada anche senza di me."],
	"w10-ortensia": ["Una variabile alla volta. L'ho scritto sul vetro e non l'ho più tolto.", "Le piante approvano, dicono."],
	"w10-mirta": ["Bevi, piccola, che poi si fredda.", "Quarant'anni di quaderni. Non guardavo: misuravo."],
	"w11-danio": ["Non scommetto più su quello che dicono tutti.", "Scommetto sul fondo dei vasi. È molto più redditizio."],
	"w11-vesta": ["Non ho bruciato niente. Le ho tenute tutte e due.", "Le cronache discordi sono la cosa più onesta che ho in archivio."],
	"w12-quinto": ["Quaranta passi invece di trecento, e non ne ho contato uno.", "Conto le scelte, adesso."],
	"w12-isa": ["E se invece il mio trucco avesse sempre avuto un nome?", "Ce l'aveva. L'ho scoperto grazie a te."],
	"w13-solano": ["(pulisce le lenti) Tre mani. Due ore e mezzo.", "L'ho stimato. E poi l'ho controllato, che è la parte seria."],
	"w13-duna": ["(mano tesa verso il Cuore) Ho insegnato come faccio.", "Non era un dono. Era un metodo, e i metodi si regalano."],
	"w14-elmo": ["(taglia l'aria) Ho riassunto tutto in tre righe.", "E in ognuna c'è chi parla. Prima non c'era nessuno."],
	"w14-ottavia": ["(cambia voce) «E la ragazzina arrivò al Cuore!»", "…la racconterò per anni. In tre modi diversi, come si deve."],
	"w15-gru": ["(colpetto al muro del Cuore) Due mesi senza un guasto.", "Non era sfortuna. Era il martedì."],
	"w15-pila": ["E quando è successo tutto questo? L'ho scritto.", "Ogni cosa, con l'ora. Serve, il mio quaderno."],
	"w16-talia": ["Scusa. Cioè: grazie.", "Ho smesso di tradurre le parole e ho cominciato a tradurre le persone."],
	"w16-marco": ["(conta sulle dita) Sei lingue. Sette. Comunque: ho letto il contratto prima di firmarlo.", "Mi sembra un miracolo più grande del Cuore."],
	"w17-nerea": ["(trattiene il fiato, poi lo lascia andare) Prima il conto, poi l'acqua.", "Ho toccato il relitto e sono risalita. Tutte e due le cose."],
	"w17-coral": ["I miei numeri li usa qualcuno.", "Trent'anni di quaderni e servivano. Non chiedermi di dirlo due volte."],
	"w18-silo": ["(conta il riverbero) Quattro secondi, e dentro ci sta una voce sola.", "Il piano qui si sente. Bastava lasciarle il posto."],
	"w18-bea": ["La navata mi deve delle scuse e non me le farà mai.", "Però la mia mappa dell'eco adesso ce l'hanno tutti."],
	"w19-numa": ["(lucida la pietra) La lingua pura non è mai esistita.", "È stata la scoperta peggiore e migliore della mia vita."],
	"w19-fiorina": ["I nomi che chiamo me li ha passati qualcuno.", "Li sto passando avanti. Non lo sapevo, e lo facevo lo stesso."],
	"w20-sferza": ["(nocche piano) Misuro, guardo, e poi tocco.", "Zero sensori bruciati. Zero!"],
	"w20-quieto": ["Uno. Due. Tre.", "Ho insegnato a contare i secondi a qualcuno. Adesso posso anche stancarmi."],
	"w21-terza": ["(allinea i fogli) Undici studi e una filastrocca.", "È la filastrocca che li teneva insieme. Non lo ammetterò in pubblico."],
	"w21-mino": ["Prendi il formaggio, che là dentro chissà.", "Il calendario del nonno vale ancora. Spostato di due settimane, ma vale."],
	"w22-vesca": ["(annusa l'aria del Cuore) Non c'è un più forte. C'è una rete.", "E odora di tutti quanti insieme."],
	"w22-fondo": ["Guarda.", "(indica il Cuore) Non te lo spiego. Ci sei arrivata da sola fin qui."],
	"w23-cronia": ["(timbra) Ho registrato anche le fonti che mi danno torto.", "Il vuoto di quattro secoli adesso ha dentro qualcosa."],
	"w23-ovidio": ["Le carte sono al sicuro, e nessuno è finito nei guai.", "Non era disobbedienza. Era il mio lavoro, e me l'hanno detto."],
}

## L'assegnazione del tredicesimo posto (§4.3). Non è una ricompensa: è la nave
## che fa una cosa che nessuno le ha ordinato, e la fa **dopo** l'ultima sfida,
## cioè dopo che il giocatore ha fatto da solo la cosa che una civiltà
## non era riuscita a fare in secoli.
const CATTEDRA := {
	"innesco": "L'ultima sfida è risolta. Non prima: il posto si assegna a chi l'ha fatto, non a chi è arrivato.",
	"scena": [
		{"chi": "nora", "dice": [
			"Eli. La nave sta apparecchiando.",
			"Non gliel'ho chiesto io.",
		]},
		{"chi": "nora", "dice": [
			"Tredici posti. Dodici hanno un nome inciso da quattrocento anni.",
			"Il tredicesimo era tenuto per quello che andavamo a cercare.",
		]},
		{"chi": "nora", "dice": [
			"Lo sta assegnando adesso. E non a una nozione.",
		]},
		{"chi": "nora", "dice": [
			"Il Fondo non era una cosa da trovare, sorella.",
			"Era qualcuno da diventare. È supremo perché è l'unico sapere che si può regalare senza perderlo.",
		]},
	],
	# La domanda resta aperta di proposito (§4.4): Meridiana è ancora là dentro e
	# ha visto qualcosa. Il primo gioco dà la sua risposta e ammette che c'è chi
	# ne ha un'altra.
	"resta_aperta": "Meridiana ha avuto quattrocento anni per pensarci e potrebbe non essere d'accordo. Il Secondo Viaggio va a chiederglielo.",
}

## **Il riconoscimento: la nave assegna il posto, NORA dice perché.**
## (2 settembre 2026)
##
## Richiesta esplicita del committente: *il finale deve accorgersi di come hai
## giocato — senza rami*. Fino a oggi la Cattedra diceva le stesse quattro
## battute a chiunque: chi si era fermato davanti a ogni cosa lasciata da
## qualcuno e chi aveva attraversato ventiquattro mondi guardando avanti
## ricevevano parola per parola lo stesso finale.
##
## **Le regole che lo tengono un ritratto e non una pagella**, e sono vincolanti:
##
## - **nomina solo cose successe.** Non esiste una riga che dica che cosa NON hai
##   fatto: sarebbe un rimprovero all'ultima scena del gioco, e i guard-rail
##   §10.6 vietano che l'errore abbia conseguenze narrative;
## - **nessuna soglia e nessun confronto.** I numeri che compaiono sono conteggi
##   — «trentun volte» — mai percentuali, mai «su quante», mai «più di». Un
##   conteggio è un fatto; una frazione è un voto;
## - **il taccuino vuoto ha la sua riga**, ed è calda. Chi non si è fermato mai
##   non ha sbagliato niente: ha attraversato i mondi in un altro modo, e il
##   gioco glielo dice così;
## - **non apre rami.** La scena resta la stessa, nello stesso posto, con lo
##   stesso esito: cambiano due battute in mezzo.
##
## Legge da [[EliNotebook]] `ritratto()`, che restituisce conteggi e nient'altro.
const RICONOSCIMENTO_INTRO := "Prima che te lo dica la nave: quello che ho visto lo dico io."

## Le osservazioni possibili, in ordine di quanto pesano. Se ne prendono al
## massimo due: tre righe su una schermata sono il tetto (§10.2), e due cose
## dette bene si ricordano meglio di quattro elencate.
const RICONOSCIMENTO_MAX := 2

static func _osservazioni(ritratto: Dictionary) -> Array:
	var out: Array = []
	var sorelle := int(ritratto.get("sorelleTrovate", 0))
	var lasciti := int(ritratto.get("lasciti", 0))
	var posizioni := int(ritratto.get("posizioni", 0))
	var semi := int(ritratto.get("semi", 0))
	if sorelle > 0:
		out.append("Ne hai trovate %d, delle mie. Le hai lette invece di passare oltre." % sorelle)
	if lasciti > 0:
		out.append("E %d volte ti sei fermata davanti alla roba di qualcuno che non c'era più. Non te lo aveva chiesto nessuno." % lasciti)
	if posizioni > 0:
		out.append("%d volte hai detto quello che pensavi a qualcuno che non se lo aspettava. Anche a me." % posizioni)
	if semi > 0:
		out.append("E hai guardato %d cose che non tornavano, invece di lasciarle stare." % semi)
	return out

## I blocchi da inserire nella sequenza del finale, nello stesso formato della
## scena della Cattedra (`chi` + `dice`). Mai vuoto: anche un taccuino bianco ha
## la sua riga.
static func riconoscimento(ritratto: Dictionary) -> Array:
	var osservazioni := _osservazioni(ritratto)
	var prima: Array = [RICONOSCIMENTO_INTRO]
	if osservazioni.is_empty():
		# **Il taccuino bianco.** Chi ha attraversato senza fermarsi non ha
		# sbagliato niente, e questa riga non deve nemmeno sfiorare il rimprovero.
		prima.append("Hai attraversato ventiquattro mondi tenendo gli occhi sulla strada, e sei arrivata.")
	else:
		for i in range(mini(RICONOSCIMENTO_MAX, osservazioni.size())):
			prima.append(str(osservazioni[i]))
	return [
		{"chi": "nora", "dice": prima},
		{"chi": "nora", "dice": [
			"Per ventiquattro mondi non ti ho detto niente.",
			"Quindi quello che sai adesso non te l'ha dato nessuno. È tuo, e non si può togliere.",
		]},
	]

## --- API -------------------------------------------------------------------

## Chi è al Cuore, in scena, a rotazione. `stage2` sono gli id dei residenti
## portati allo stadio 2; `wave` è il giro di rotazione (0, 1, 2…).
##
## Gli itineranti entrano **sempre**: sono la garanzia che il Cuore non sia mai
## vuoto. I residenti si aggiungono e ruotano insieme a loro.
static func cast_for(stage2: Array, wave: int = 0) -> Array:
	var pool: Array = []
	var itinerant_ids: Array = ITINERANTI.keys()
	itinerant_ids.sort()
	pool.append_array(itinerant_ids)
	var residents: Array = []
	for npc_id in stage2:
		if RESIDENTI.has(str(npc_id)):
			residents.append(str(npc_id))
	residents.sort()
	pool.append_array(residents)

	var out: Array = []
	var total := pool.size()
	if total == 0:
		return out
	var start := (maxi(wave, 0) * MAX_IN_SCENA) % total
	for i in range(mini(MAX_IN_SCENA, total)):
		out.append(str(pool[(start + i) % total]))
	return out

## Quante ondate servono perché tutti quelli che sono venuti abbiano parlato.
static func waves_needed(stage2: Array) -> int:
	var total := ITINERANTI.size()
	for npc_id in stage2:
		if RESIDENTI.has(str(npc_id)):
			total += 1
	return int(ceil(float(total) / float(MAX_IN_SCENA)))

static func lines_for(npc_id: String) -> Array:
	if ITINERANTI.has(npc_id):
		return (ITINERANTI[npc_id] as Array).duplicate(true)
	return Array(RESIDENTI.get(npc_id, [])).duplicate(true)
