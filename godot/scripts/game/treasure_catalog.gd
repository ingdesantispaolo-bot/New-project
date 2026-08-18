class_name TreasureCatalog
extends RefCounted

## **Che cosa c'è dentro un forziere.** (14 agosto 2026)
##
## Il difetto, segnalato dal committente e confermato dai numeri: i forzieri
## «sono solo una distrazione che non apporta nulla». Erano tre cose insieme, e
## tutte e tre sbagliate.
##
## - Erano **troppi**: `fragment_economy_probe` ne conta 1018 raggiungibili in una
##   campagna, quarantadue per mondo. Una cosa che si trova quaranta volte per
##   mondo non è un ritrovamento, è arredamento.
## - Erano **anonimi**: l'etichetta usciva da tre stringhe estratte a sorte
##   (`scrigno raro`, `cassa energia`, `frammenti dispersi`), e una di quelle tre
##   mentiva — `rewardEnergy` era generato e mai pagato da nessuno.
## - Pagavano in una **valuta morta**: vedi [[FragmentEconomy]].
##
## Questo file risolve il secondo problema e governa il primo. Il terzo lo
## risolve l'economia.
##
## **La regola che tiene insieme il resto: il generatore fa la geometria, il
## catalogo fa il significato.** `OutdoorGenerator` non viene toccato — le
## fixture di parità e il determinismo dei semi restano quelli che erano. Qui si
## legge l'id già generato e si decide che cosa quel forziere *è*, con lo stesso
## meccanismo che il progetto usa già per gli attrezzi richiesti in
## `ChunkManager`: `posmod(hash(id), 100)`, stabile fra due partite e fra due
## riavvii.
##
## **Tre tipi, e perché tre.**
##
##   LASCITO   la roba di qualcuno che abita quel mondo. Si apre, ci si ferma un
##             momento, Eli dice una riga. È il forziere che porta la storia.
##   CUSTODE   il Custode gratta e tira fuori una cosa inutile
##             ([[PetGifts]]): un sasso, un bottone. Non vale niente ed è il
##             punto — dopo ventiquattro mondi quella lista è il diario del
##             viaggio, e adesso si riempie **esplorando** invece che a sorte a
##             fine sessione.
##   RESTO     cianfrusaglie. Si raccoglie camminando, una riga di feedback e via.
##
## Il rapporto fra i tre è la cosa che fa funzionare gli altri due: se ogni
## forziere si fermasse a raccontare qualcosa, fermarsi smetterebbe di essere un
## avvenimento. Un forziere su quattro parla, uno su sette porta il Custode, il
## resto è resto.
##
## **Gli oggetti sono della materia del mondo, i proprietari sono del suo cast.**
## Nessun testo dice mai chi era quella persona o come stava: dice che cosa ha
## lasciato e in che stato. Un mazzo di stecche rilegato a gruppi di dieci
## racconta Tobia meglio di una frase su Tobia — ed è la stessa regola delle
## Tracce (`MysteryCatalog`): si leggono, non si recitano.
##
## **Guard-rail.** Niente qui è obbligatorio, niente si perde, niente tocca una
## domanda, una soglia o un gate. Un forziere mancato non costa nulla: è la
## condizione perché possa valere qualcosa trovarlo.

const TIPO_LASCITO := "lascito"
const TIPO_CUSTODE := "custode"
const TIPO_RESTO := "resto"

## Quanti forzieri del generatore restano nel mondo, in percentuale. Un terzo:
## quarantadue per mondo diventano quattordici, cioè circa uno ogni due chunk —
## ancora una densità da esplorazione, non più da tappezzeria. La scelta è
## stabile sull'id, quindi un forziere che non c'è non ricompare al reload.
const DENSITA_PERCENTUALE := 34

## Le quote dei tre tipi, su cento forzieri presenti.
const QUOTA_LASCITO := 26
const QUOTA_CUSTODE := 14

## Le fasce di ricompensa, in frammenti. Il lascito paga di più perché è anche
## quello che si fa aspettare: pagarlo uguale insegnerebbe che fermarsi a leggere
## costa tempo e non rende niente.
const FASCIA := {
	TIPO_LASCITO: [240, 320],
	TIPO_CUSTODE: [160, 220],
	TIPO_RESTO: [130, 190],
}

## **Gli oggetti, materia per materia.** Cinque per materia: ogni materia abita
## due dei ventiquattro mondi (`ApparatusConfig.world_subject`), e un mondo ha
## circa quattro lasciti — cinque oggetti bastano perché in una campagna intera
## se ne ripeta al massimo qualcuno, e non nello stesso mondo.
##
## `cosa` è quello che si vede aprendo. `eli` è quello che pensa lei, ed è una
## riga sola: due righe diventerebbero un commento, e il commento spiega. Nessun
## oggetto dice se la persona sta bene, se è tornata, se ha finito — le cose
## lasciate non lo sanno.
const OGGETTI := {
	"matematica": [
		{"nome": "stecche da conteggio",
			"cosa": "Un mazzo di stecche da conteggio, legate a gruppi di dieci con lo spago.",
			"eli": "Nello spago ci sono i buchi vecchi: prima erano legate a una a una."},
		{"nome": "quaderno delle stime",
			"cosa": "Un quaderno di stime. Su ogni pagina un numero a matita, e sotto, in penna, quello vero.",
			"eli": "Sbagliava sempre per poco. E per poco vuol dire che aveva capito il grosso."},
		{"nome": "corda a nodi",
			"cosa": "Una corda da misura con tredici nodi, consumata solo fino al terzo.",
			"eli": "Le distanze lunghe non le ha mai misurate. Non so se non poteva o non voleva."},
		{"nome": "cassetta dei pesi",
			"cosa": "Una cassetta di pesi da bilancia. Ne manca uno, e al suo posto c'è un sasso della misura esatta.",
			"eli": "Quel sasso qualcuno l'ha pesato prima di metterlo lì. Non è una cosa che viene per caso."},
		{"nome": "tabella del mercato",
			"cosa": "Una tabella dei prezzi del mercato, con i conti rifatti a mano nel margine.",
			"eli": "Non si fidava dei totali stampati. Ha fatto bene: due sono sbagliati."},
	],
	"italiano": [
		{"nome": "quaderno di copiatura",
			"cosa": "Un quaderno di copiatura: la stessa frase quaranta volte. La quarantesima è diversa.",
			"eli": "Ha cambiato una parola all'ultimo giro. Una sua, in mezzo a quaranta di qualcun altro."},
		{"nome": "elenco di parole difficili",
			"cosa": "Un elenco di parole difficili. Di fianco a ognuna non c'è il significato: c'è dove l'ha sentita la prima volta.",
			"eli": "Anch'io me le ricordo così. Non l'avevo mai detto a nessuno."},
		{"nome": "lettera piegata in quattro",
			"cosa": "Una lettera con l'indirizzo scritto, la piega morbida, e nessun segno di essere mai partita.",
			"eli": "L'ha riaperta tante volte. Scriverla era la parte facile."},
		{"nome": "scatola di ritagli",
			"cosa": "Una scatola di frasi tagliate a metà: da una parte chi fa la cosa, dall'altra la cosa che fa.",
			"eli": "È un gioco per qualcuno che stava imparando a smontare le frasi. O per chi glielo stava insegnando."},
		{"nome": "mezzo vocabolario",
			"cosa": "Un vocabolario che arriva alla lettera L. La seconda metà non c'è.",
			"eli": "Fino alla L uno se la cava da solo. È dopo che servirebbe qualcuno."},
	],
	"coding": [
		{"nome": "mazzo di schede forate",
			"cosa": "Un mazzo di schede forate, in ordine, con una sola fuori posto e segnata a matita.",
			"eli": "L'errore l'ha trovato. Rimetterla dentro no."},
		{"nome": "foglio di istruzioni",
			"cosa": "Un foglio di istruzioni numerate. La numero sette dice «torna alla tre».",
			"eli": "E la tre arriva alla sette. Quella macchina gira per sempre — c'è un punto interrogativo di fianco, quindi lo sapeva."},
		{"nome": "cassetta di ingranaggi",
			"cosa": "Una cassetta di ingranaggi ordinati per numero di denti, dal più piccolo.",
			"eli": "Ordinare prima costa tempo e cercare dopo non ne costa più. È un baratto che conviene sempre."},
		{"nome": "elenco di prove",
			"cosa": "Un elenco di prove: per ognuna, cosa doveva succedere e cosa è successo.",
			"eli": "Le due colonne non coincidono quasi mai. Però le ha scritte tutte e due, ed è la parte difficile."},
		{"nome": "chiave con etichetta",
			"cosa": "Una chiave con un cartellino: «prova questa per prima».",
			"eli": "L'ha scritto per qualcuno che sarebbe arrivato dopo di lui. Sono io, per adesso."},
	],
	"inglese": [
		{"nome": "biglietti con i disegni",
			"cosa": "Un mazzetto di biglietti: da un lato una parola straniera, dall'altro il disegno della cosa.",
			"eli": "Nessuna traduzione da nessuna parte. Solo la parola e la cosa."},
		{"nome": "cartolina scritta due volte",
			"cosa": "Una cartolina con la stessa frase in due lingue. La seconda ha più errori.",
			"eli": "La seconda l'ha scritta da sola. Si vede, ed è quella che le è costata."},
		{"nome": "lista dei falsi amici",
			"cosa": "Una lista di parole che sembrano una cosa e ne dicono un'altra. In cima, «library».",
			"eli": "Sotto qualcun altro ha aggiunto «non è un negozio», e l'ha sottolineato due volte."},
		{"nome": "manuale di bordo",
			"cosa": "Un manuale con le istruzioni in una lingua e le annotazioni a margine in un'altra.",
			"eli": "Leggeva in una lingua e pensava nell'altra. A un certo punto succede, dice NORA."},
		{"nome": "canzone trascritta a orecchio",
			"cosa": "Il testo di una canzone trascritto a orecchio, con tre buchi lasciati in bianco.",
			"eli": "I buchi sono tutti nello stesso punto del ritornello. Ci ha riprovato più volte, quindi."},
	],
	"fisica": [
		{"nome": "pendolo con tre nodi",
			"cosa": "Un pendolo con la corda annodata a tre altezze, e tre tacche sul legno del sostegno.",
			"eli": "Tre lunghezze, tre segni. Non stava giocando: stava cambiando una cosa per volta."},
		{"nome": "asse con la biglia",
			"cosa": "Un asse inclinato con le tacche e una biglia di piombo consumata da una parte sola.",
			"eli": "Sempre lo stesso verso. Migliaia di volte, a giudicare da quanto è liscia."},
		{"nome": "molla con il cartellino",
			"cosa": "Una molla e un cartellino: «tira 4, torna 4. Tira 8, torna 8. Tira 20, non torna più».",
			"eli": "L'ultima riga ha una grafia più stretta. L'ha scritta dopo, quando è successo."},
		{"nome": "magneti con il cuneo",
			"cosa": "Due magneti tenuti separati da un cuneo di legno, come per guardarli spingere.",
			"eli": "Il cuneo è pieno di segni. Ha guardato a lungo una cosa che non si muoveva."},
		{"nome": "clessidra rigata",
			"cosa": "Una clessidra con il vetro rigato in tre punti diversi.",
			"eli": "Tre segni: tre tempi che voleva poter ritrovare uguali."},
	],
	"musica": [
		{"nome": "diapason",
			"cosa": "Un diapason con l'impugnatura consumata liscia.",
			"eli": "Per accordare basta tenerlo un momento. Questo l'hanno tenuto in mano molto più a lungo."},
		{"nome": "spartito con le dita",
			"cosa": "Uno spartito con i numeri delle dita scritti sopra le note, e cancellati da metà pagina in poi.",
			"eli": "Da metà pagina non gli servivano più. Vorrei vedere la mia faccia in quel punto lì."},
		{"nome": "corde di ricambio",
			"cosa": "Un rotolo di corde di ricambio, tutte della stessa nota.",
			"eli": "Una corda sola gli si spezzava sempre. Vuol dire che quella la suonava forte."},
		{"nome": "metronomo fermo",
			"cosa": "Un metronomo bloccato sul tempo più lento che ha.",
			"eli": "Andare piano è una decisione, e a guardarla da fuori sembra non saper fare."},
		{"nome": "quaderno di sassi",
			"cosa": "Un quaderno dove i ritmi sono disegnati come file di sassi, grandi e piccoli.",
			"eli": "Non conosceva le note e si è inventato un modo di scriverle lo stesso."},
	],
	"latino": [
		{"nome": "tavoletta cerata",
			"cosa": "Una tavoletta cerata con la stessa declinazione ripassata finché la cera si è consumata.",
			"eli": "Il legno si vede in un punto solo: il caso che le veniva peggio."},
		{"nome": "calco di un'iscrizione",
			"cosa": "Il calco di un'iscrizione, con le abbreviazioni sciolte a matita di fianco.",
			"eli": "Prima ha copiato, poi ha capito. In quest'ordine, e va bene così."},
		{"nome": "elenco di radici",
			"cosa": "Un elenco di radici di parole, e sotto ognuna quelle di oggi che ne vengono.",
			"eli": "Una colonna arriva fino a parole che uso io."},
		{"nome": "grammatica annotata",
			"cosa": "Una grammatica con i margini pieni di eccezioni raccolte a mano.",
			"eli": "Le regole erano già stampate. Le eccezioni se l'è trovate da solo, una per volta."},
		{"nome": "moneta consumata",
			"cosa": "Una moneta liscia con tre lettere ancora leggibili, e un foglio dove la parola intera è ricostruita.",
			"eli": "Tre lettere e ha ricavato una parola. Sul foglio c'è scritto anche come, che è la parte che serve."},
	],
	"elettronica": [
		{"nome": "matassa di fili",
			"cosa": "Una matassa di fili, divisi per colore e legati uno per uno.",
			"eli": "Chi li ha divisi così stava per fare una cosa lunga."},
		{"nome": "schema disegnato",
			"cosa": "Lo schema di un circuito disegnato due volte: la prima a mano libera, la seconda con la riga.",
			"eli": "Il secondo è più bello. Il primo è quello dove ha capito."},
		{"nome": "lampadina provata",
			"cosa": "Una lampadina con un'etichetta: «funziona. È il resto che non funziona».",
			"eli": "Ha escluso una cosa per volta. È l'unico modo che conosco anch'io."},
		{"nome": "cassetta di resistenze",
			"cosa": "Una cassetta di resistenze ordinate per fasce di colore, con un elenco che le traduce in numeri.",
			"eli": "L'elenco è consumato all'inizio e intatto alla fine: a un certo punto non gli è più servito."},
		{"nome": "campanello smontato",
			"cosa": "Un campanello smontato con i pezzi disposti in fila, nell'ordine in cui sono usciti.",
			"eli": "Metterli in fila così vuol dire che voleva rimontarlo."},
	],
	"geografia": [
		{"nome": "mappa a memoria",
			"cosa": "Una mappa disegnata a memoria, con le coste giuste e le distanze tutte sbagliate.",
			"eli": "Si ricordava la forma dei posti e non quanto stavano lontani. Anch'io, di certi."},
		{"nome": "bussola con lo specchio",
			"cosa": "Una bussola con lo specchietto crepato, e un nord segnato a mano che non è quello dell'ago.",
			"eli": "Sapeva che il suo ago mentiva di poco e si è tenuto la correzione addosso."},
		{"nome": "diario di rotta",
			"cosa": "Un diario di rotta dove ogni giorno è annotato il vento, e una riga sola dice dove sono arrivati.",
			"eli": "Venti giorni di vento e una riga di posto. Vuol dire che il viaggio era il vento."},
		{"nome": "sacchetto di sassi",
			"cosa": "Un sacchetto di sassi, ognuno con un'etichetta con il nome di un posto.",
			"eli": "Da ogni posto ne ha preso uno. Nessuno è bello: contava solo che fosse di lì."},
		{"nome": "profilo di costa",
			"cosa": "Un rotolo con il profilo di una costa disegnato per intero, e un tratto lasciato tratteggiato.",
			"eli": "Il tratteggio è la parte che non ha visto. Non l'ha inventata, e poteva."},
	],
	"scienze": [
		{"nome": "erbario",
			"cosa": "Un erbario con le foglie ancora attaccate e la data di raccolta sotto ognuna.",
			"eli": "Le date coprono un anno intero. Voleva vedere la stessa pianta cambiare."},
		{"nome": "barattolo di semi",
			"cosa": "Un barattolo di semi divisi in scomparti, con scritto sopra quanti giorni ci hanno messo a germogliare.",
			"eli": "Uno scomparto ha scritto «niente». L'ha tenuto lo stesso."},
		{"nome": "lente da campo",
			"cosa": "Una lente da campo con il manico segnato dai denti.",
			"eli": "Se la teneva in bocca per avere le mani libere. Lo faccio anch'io con la matita."},
		{"nome": "ossa piccole",
			"cosa": "Tre ossa piccole di uccello, pulite ed etichettate una per una.",
			"eli": "Le ha guardate da vicino invece di girarsi dall'altra parte. Ci vuole più coraggio di quanto sembri."},
		{"nome": "diario delle piogge",
			"cosa": "Un diario delle piogge, una tacca per giorno, e in fondo una somma per mese.",
			"eli": "Le tacche non dicono niente. È la somma in fondo che comincia a dire qualcosa."},
	],
	"storia": [
		{"nome": "cassa di reperti falsi",
			"cosa": "Una cassa di reperti con un cartellino: «due su cinque sono falsi. Non so quali due».",
			"eli": "L'ha scritto sopra invece di buttarli. Un falso riconosciuto vale più di un vero senza storia."},
		{"nome": "cronaca ricopiata",
			"cosa": "Una cronaca ricopiata a mano, con le parti dubbie messe fra parentesi.",
			"eli": "Chi copia tutto uguale non decide niente. Queste parentesi sono decisioni."},
		{"nome": "albero di nomi",
			"cosa": "Un albero di famiglia disegnato su un lenzuolo, con due rami che finiscono in un punto interrogativo.",
			"eli": "Non ha chiuso i rami che non sapeva. Li ha lasciati aperti in mezzo alla stanza."},
		{"nome": "chiodi di epoche diverse",
			"cosa": "Una fila di chiodi diversissimi fra loro, ordinati dal più rozzo al più preciso.",
			"eli": "Un chiodo non dice la data. Cento chiodi in fila sì."},
		{"nome": "registro dei nomi",
			"cosa": "Un registro di nomi, e in fondo una lista più corta: quelli che compaiono una volta sola.",
			"eli": "Si è messo a cercare proprio quelli che nessuno aveva più nominato."},
	],
	"logica": [
		{"nome": "gioco delle pesate",
			"cosa": "Una bilancia a due piatti, otto sfere uguali e un foglio: «tre pesate. Poi ne bastarono due».",
			"eli": "Ha trovato un modo più corto dopo aver trovato quello lungo. Mai il contrario."},
		{"nome": "labirinto disegnato",
			"cosa": "Un labirinto disegnato a inchiostro e risolto a matita, tenendo sempre la mano sulla parete destra.",
			"eli": "Non è la strada più corta. È quella che funziona anche quando non vedi niente."},
		{"nome": "quaderno di indovinelli",
			"cosa": "Un quaderno di indovinelli, ognuno con la risposta coperta da un lembo di carta incollato.",
			"eli": "Ha incollato le risposte per non guardarle. Le teneva a portata e non le guardava."},
		{"nome": "carte con le regole",
			"cosa": "Un mazzo di carte con le regole del gioco scritte sul dorso, e una regola cancellata e riscritta.",
			"eli": "Quella cancellata rendeva il gioco impossibile. Se ne sono accorti giocando, non pensando."},
		{"nome": "serratura a combinazione",
			"cosa": "Una serratura a combinazione smontata, con un foglio delle combinazioni già escluse.",
			"eli": "Duecento righe di cose che non funzionano. È così che si assottiglia un problema."},
	],
}

## Il resto: cianfrusaglie. Una riga sola, nessuna voce di Eli, nessuna sosta —
## dicono soltanto che questo mondo è abitato da gente che lascia in giro le
## proprie cose, che è già più di quanto dicessero «frammenti dispersi».
const RESTI := [
	{"nome": "cordame", "cosa": "Cordame arrotolato bene, ancora buono."},
	{"nome": "secchio ammaccato", "cosa": "Un secchio ammaccato e due pezze piegate."},
	{"nome": "barattolo di chiodi", "cosa": "Un barattolo di chiodi, divisi per lunghezza."},
	{"nome": "vasellame spaiato", "cosa": "Vasellame spaiato, lavato e messo via."},
	{"nome": "attrezzi da campo", "cosa": "Attrezzi da campo con i manici riavvolti con lo spago."},
	{"nome": "lanterna senza olio", "cosa": "Una lanterna senza più olio, con il vetro pulito."},
	{"nome": "monete fuori corso", "cosa": "Monete che qui non valgono più niente, tenute insieme lo stesso."},
	{"nome": "bottoni di ottone", "cosa": "Una scatola di bottoni di ottone, tutti diversi."},
	{"nome": "coperta ripiegata", "cosa": "Una coperta ripiegata sopra un cambio di vestiti."},
	{"nome": "provviste secche", "cosa": "Provviste secche in un panno, chiuse con cura."},
	{"nome": "vetri colorati", "cosa": "Pezzi di vetro colorato, levigati dall'acqua."},
	{"nome": "gomitoli", "cosa": "Gomitoli di lana grezza, uno cominciato."},
]

## Le righe del Custode che gratta. Non commentano il regalo — è la regola dei
## regali (`PetGifts`): il momento in cui una cosa inutile viene spiegata,
## smette di essere un regalo e diventa una ricompensa.
const CUSTODE_RIGHE := [
	"Il Custode ci mette il muso prima di te e ne esce con qualcosa in bocca.",
	"Il Custode gratta il fondo della cassa con ostinazione e tira su una cosa sua.",
	"Prima che tu arrivi al coperchio, il Custode ha già scelto la sua parte.",
	"Il Custode fruga, scarta tutto, e tiene una cosa sola.",
]

## Vero se questo forziere esiste nel mondo. Stabile sull'id: un forziere saltato
## resta saltato anche dopo un reload, e non ricompare al secondo giro.
static func presente(treasure_id: String) -> bool:
	return posmod(hash("%s:densita" % treasure_id), 100) < DENSITA_PERCENTUALE

static func tipo_di(treasure_id: String, custode_disponibile: bool = true) -> String:
	var roll := posmod(hash("%s:tipo" % treasure_id), 100)
	if roll < QUOTA_LASCITO:
		return TIPO_LASCITO
	if roll < QUOTA_LASCITO + QUOTA_CUSTODE:
		# Senza Custode non c'è nessuno che frughi: il forziere torna un resto
		# invece di promettere una scena che non può accadere.
		return TIPO_CUSTODE if custode_disponibile else TIPO_RESTO
	return TIPO_RESTO

static func frammenti_di(treasure_id: String, tipo: String) -> int:
	var fascia: Array = FASCIA.get(tipo, FASCIA[TIPO_RESTO])
	var minimo := int(fascia[0])
	var massimo := int(fascia[1])
	return minimo + posmod(hash("%s:premio" % treasure_id), massimo - minimo + 1)

## L'oggetto di questo forziere, scelto fra i cinque della materia del mondo.
static func oggetto_di(world_level: int, treasure_id: String) -> Dictionary:
	var subject := ApparatusConfig.world_subject(world_level)
	var lista: Array = OGGETTI.get(subject, OGGETTI["matematica"])
	return Dictionary(lista[posmod(hash("%s:oggetto" % treasure_id), lista.size())]).duplicate(true)

static func resto_di(treasure_id: String) -> Dictionary:
	return Dictionary(RESTI[posmod(hash("%s:resto" % treasure_id), RESTI.size())]).duplicate(true)

static func riga_custode(treasure_id: String) -> String:
	return str(CUSTODE_RIGHE[posmod(hash("%s:custode" % treasure_id), CUSTODE_RIGHE.size())])

## **Di chi era.** Il cast del mondo, residenti e Bislacco, in ordine stabile.
## Se un mondo non ha ancora abitanti scritti si torna vuoti e il lascito diventa
## un oggetto senza proprietario: dice comunque qualcosa, e non inventa una
## persona che il gioco non ha.
static func proprietario_di(world_level: int, treasure_id: String) -> Dictionary:
	var cast: Dictionary = NpcCatalog.for_world(world_level)
	var ids: Array = []
	ids.append_array(Array(cast.get("residents", [])))
	ids.append_array(Array(cast.get("bislacchi", [])))
	if ids.is_empty():
		return {}
	var npc_id := str(ids[posmod(hash("%s:chi" % treasure_id), ids.size())])
	var scheda := NpcCatalog.resident(npc_id)
	if scheda.is_empty():
		scheda = NpcCatalog.bislacco(npc_id)
	if scheda.is_empty():
		return {}
	return {
		"id": npc_id,
		"nome": str(scheda.get("nome", "")),
		"ruolo": str(scheda.get("ruolo", "")),
	}

## Tutto quello che serve a mettere in scena un forziere, in una chiamata sola.
##
## `frammenti` è già il premio finale: chi apre la cassa non deve più leggere
## `rewardFragments` dal payload procedurale, che era tarato su un'economia che
## non esiste più.
static func contenuto(world_level: int, treasure_id: String, custode_disponibile: bool = true) -> Dictionary:
	var tipo := tipo_di(treasure_id, custode_disponibile)
	var out := {
		"tipo": tipo,
		"frammenti": frammenti_di(treasure_id, tipo),
	}
	match tipo:
		TIPO_LASCITO:
			var oggetto := oggetto_di(world_level, treasure_id)
			var chi := proprietario_di(world_level, treasure_id)
			out["nome"] = str(oggetto.get("nome", "reperto"))
			out["cosa"] = str(oggetto.get("cosa", ""))
			out["eli"] = str(oggetto.get("eli", ""))
			out["proprietario"] = chi
		TIPO_CUSTODE:
			var resto := resto_di(treasure_id)
			out["nome"] = str(resto.get("nome", "roba"))
			out["cosa"] = str(resto.get("cosa", ""))
			out["riga"] = riga_custode(treasure_id)
		_:
			var cianfrusaglie := resto_di(treasure_id)
			out["nome"] = str(cianfrusaglie.get("nome", "roba"))
			out["cosa"] = str(cianfrusaglie.get("cosa", ""))
	return out

## L'etichetta che il forziere mostra prima di essere aperto. Non anticipa il
## contenuto — anticiparlo trasformerebbe l'apertura in una conferma — ma
## distingue il forziere di qualcuno dagli altri: si vede da fuori che è chiuso
## con cura.
static func etichetta(treasure_id: String, custode_disponibile: bool = true) -> String:
	return "forziere chiuso con cura" if tipo_di(treasure_id, custode_disponibile) == TIPO_LASCITO \
		else "cassa"
