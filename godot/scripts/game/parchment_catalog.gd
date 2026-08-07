class_name ParchmentCatalog
extends RefCounted

## **Le pergamene dei Dodici**: una per mondo, chiusa in una camera che si apre
## solo con la serratura. (7 agosto 2026)
##
## **Perché esistono, e perché non sono un doppione dei beat.** I ventiquattro
## beat di `NarrativeManager` sono la voce di NORA: raccontano l'indagine dal
## suo lato, al presente, mentre accade. Le pergamene sono l'**altro lato** —
## quello dei Dodici, scritto quattrocento anni prima, da chi c'era.
##
## È la differenza fra sapere che cosa è successo e leggere chi l'ha fatto. NORA
## deduce; i Dodici testimoniano, e a volte si contraddicono fra loro: è la
## stessa lezione di metodo che il gioco insegna in storia — due fonti che
## dicono cose diverse, e bisogna scegliere di quale fidarsi.
##
## **Nessuna pergamena è obbligatoria.** Sono chiuse in una camera che si apre
## con una prova dedicata, e la camera è l'unico posto del gioco in cui una zona
## è davvero inaccessibile — cosa che qui si può fare **proprio perché dentro non
## c'è niente che serva a progredire**. Chi non esplora finisce il gioco lo
## stesso, e capisce la storia lo stesso: gli manca il perché, non il cosa.
##
## **Regola di scrittura ereditata dalla trama (§10.1):** nessuno è morto. Le
## undici sorelle e Meridiana sono trattenute, non perdute — e le pergamene, che
## sono più antiche, non possono saperlo: dicono quello che sapevano allora.

## Le pergamene, in ordine di mondo. `autore` è chi scrive, `testo` è quello che
## il bambino legge.
const PERGAMENE := {
	1: {"autore": "Verbale della Prima Cattedra",
		"testo": "Oggi abbiamo contato i sistemi: dodici. Uno per ciascuno di noi, e una cattedra in più che nessuno ha voluto occupare. Il Primo dice che è per ciò che andiamo a cercare. Nessuno ha chiesto che cosa."},
	2: {"autore": "Diario della Seconda",
		"testo": "Ho insegnato alle macchine a ripetere elenchi perfetti. Sono bravissime. Non capiscono una parola di quello che dicono, e per un attimo mi sono chiesta se la differenza si veda da fuori."},
	3: {"autore": "Nota tecnica della Terza",
		"testo": "Un procedimento che nessuno rilegge diventa una superstizione. Ho scritto ogni passo del ciclo su pietra, perché fra cent'anni qualcuno possa dirmi che sbagliavo."},
	4: {"autore": "Registro della Quarta",
		"testo": "Il segnale è partito in sei lingue. Se una sola arriva a qualcuno che la capisce, il circuito ha funzionato. Non è ottimismo: è aritmetica."},
	5: {"autore": "Appunti della Quinta",
		"testo": "La leva più lunga solleva il peso più grande, ma sposta il fulcro più lontano da chi spinge. Tutte le nostre soluzioni funzionano così, e comincio a temerlo."},
	6: {"autore": "Quaderno della Sesta",
		"testo": "L'accordo tiene finché ogni voce resta al suo posto. Ho passato la vita a insegnarlo, e stasera in consiglio nessuno ascoltava nessuno."},
	7: {"autore": "Iscrizione della Settima",
		"testo": "Incidiamo per durare, non per essere letti. Sono due mestieri diversi, e noi ne pratichiamo uno solo. Quando me ne sono accorta era già tardi."},
	8: {"autore": "Schema dell'Ottavo",
		"testo": "Ho messo le stanze in parallelo apposta: se una si spegne, le altre restano accese. Contro la caduta di una sola cattedra questo basta. Contro la caduta di tutte, no."},
	9: {"autore": "Carta della Nona",
		"testo": "Ho disegnato la rotta e mi sono accorta che è un anello. Torniamo negli stessi dodici mondi da nove giri. Non stiamo esplorando: stiamo aspettando che qualcosa ci raggiunga."},
	10: {"autore": "Erbario della Decima",
		"testo": "La simbiosi non è gentilezza: è che nessuno dei due sopravvive da solo. L'ho scritto pensando alle piante e riletto pensando a noi."},
	11: {"autore": "Cronaca dell'Undicesima",
		"testo": "Due registri, due date diverse per lo stesso giorno. Uno dei due è stato riscritto. Ho annotato entrambi e non ho detto quale credo: chi verrà dopo scelga con la propria testa."},
	12: {"autore": "Verbale della Dodicesima",
		"testo": "Siamo dodici e le schede sono venticinque. Le altre tredici sono vuote, numerate, pronte. Il Primo dice che sono per le allieve. Non ci sono allieve."},
	13: {"autore": "Margine di una tavola numerica",
		"testo": "Il Tredicesimo ha corretto i miei calcoli e aveva ragione. Poi ha corretto le mie conclusioni, e su quelle sbagliava. Ho lasciato entrambe le correzioni: si veda la differenza."},
	14: {"autore": "Indice interrotto",
		"testo": "Catalogo tutto quello che sappiamo. Sono arrivata alla lettera M in quarant'anni. Alla fine mancherà tutto il resto, e sarà comunque più di quanto avevamo."},
	15: {"autore": "Turno di manutenzione",
		"testo": "La macchina gira da sola solo finché qualcuno la guarda girare. È la cosa più difficile da spiegare a chi arriva: non è rotta, è sola."},
	16: {"autore": "Lettera bilingue al valico",
		"testo": "Ho tradotto la loro parola per «sapere» e non c'è. Hanno una parola per «aver capito insieme». Torno indietro a rifare tutto il vocabolario."},
	17: {"autore": "Giornale di bordo del palombaro",
		"testo": "Sceso a duecento. Sotto non c'è il fondo: c'è un'altra superficie, e da lì viene una luce che sale. Non l'ho scritto nel rapporto ufficiale."},
	18: {"autore": "Partitura annotata",
		"testo": "Dodici canne, una per sistema. Se ne togli una l'accordo resta, ma cambia nome. Il Tredicesimo ha chiesto quale togliere. Gli ho detto: nessuna."},
	19: {"autore": "Epigrafe alle radici",
		"testo": "Sotto le città ci sono altre città, e sotto quelle il primo che ha inciso un segno per non dimenticare. Da lui discendiamo, non dai re."},
	20: {"autore": "Rilevamento della tempesta",
		"testo": "Il Silenzio non arriva come una nube: arriva come una dimenticanza. Prima non ricordi la formula, poi non ricordi che ce n'era una. Chi lo attraversa non se ne accorge."},
	21: {"autore": "Calendario del pastore",
		"testo": "Mio nonno contava le stagioni con dodici tacche. Io ne uso trecentosessantacinque e sbaglio più spesso. Non tutto quello che è preciso è più vero."},
	22: {"autore": "Taccuino della biologa",
		"testo": "Nel buio profondo le creature fanno luce da sole. Nessuna gliel'ha insegnato. Se il sapere si perde davvero, forse ricomincia da qui — ma ci vorranno milioni di anni, e noi abbiamo fretta."},
	23: {"autore": "Ultimo verbale, mano ignota",
		"testo": "La proposta di chiusura è passata in un'ora. Undici voti a favore, uno contrario, e il contrario era il mio. Cancellate il mio nome se serve, ma lasciate il conteggio."},
	24: {"autore": "Riga sola, incisa dall'interno",
		"testo": "Se leggete questo, la cattedra vuota è ancora vuota e qualcuno è arrivato fin qui. Allora avevamo torto su una cosa sola: che non sarebbe venuto nessuno."},
}

static func per_world(level: int) -> Dictionary:
	return PERGAMENE.get(clampi(level, 1, ApparatusConfig.MAX_LEVEL), {})

static func esiste(level: int) -> bool:
	return PERGAMENE.has(clampi(level, 1, ApparatusConfig.MAX_LEVEL))

## Il testo pronto da mostrare, autore compreso.
static func testo_completo(level: int) -> String:
	var p := per_world(level)
	if p.is_empty():
		return ""
	return "%s\n\n«%s»" % [str(p.get("autore", "")), str(p.get("testo", ""))]
