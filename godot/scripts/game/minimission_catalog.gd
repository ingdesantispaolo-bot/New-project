class_name MinimissionCatalog
extends RefCounted

## **Le minimissioni: le riparazioni che i Dodici hanno lasciato a metà.**
## (7 agosto 2026)
##
## Nascono dal verdetto di un collaudo vero — «è noioso girovagare senza uno
## scopo» — e dalla richiesta che ne è seguita: elementi della mappa che si
## **modificano** una volta superate le prove. Liberare degli animali, spegnere
## un incendio, aggiustare un faro, riparare un mulino.
##
## **Il ribaltamento, che è tutto il punto.** Fino a ieri l'esercizio era il
## FINE e il luogo era la cornice: rispondi bene, la barra sale, il posto dove
## eri non c'entrava niente. In una minimissione l'esercizio è il MEZZO e il
## cambiamento del mondo è il fine. Lo sforzo è identico — le stesse domande,
## dallo stesso banco — ma il motivo no, ed è il motivo che il collaudo ha
## trovato mancante.
##
## **Sostituire, non aggiungere.** Direttiva esplicita del committente, e la
## misura le dava ragione: la campagna sta a 21,1 ore e il collaudo l'aveva già
## definita faticosa. Una minimissione **prende il posto** del primo evento-gate
## del mondo invece di affiancarlo (vedi `MissionEventDirector.plan`), con lo
## stesso numero di campate. Il conto degli esercizi non cambia di uno: cambia
## che cosa succede quando finiscono.
##
## **Perché quattro forme e non venti.** Ognuna chiede un'azione mentale diversa
## e non solo una scenografia diversa — è la stessa lezione delle ricette: la
## varietà che conta è quella delle AZIONI, non quella dei parametri.
##
##   SPEGNERE     c'è un danno che peggiora se si sbaglia: è l'unica forma con
##                un rischio, e l'unica in cui un errore costa qualcosa in più;
##   LIBERARE     quello che era chiuso RESTA nel mondo, visibile per sempre:
##                è la forma della ricompensa che si vede;
##   RIPARARE     a campate come l'enigma, e alla fine la macchina FUNZIONA e fa
##                una cosa utile;
##   RIACCENDERE  scopre una fetta di mondo in permanenza: è la forma legata
##                alla luce.
##
## **Autoriale il COSA, procedurale il QUANDO e il DOVE.** Il testo, la forma e
## il numero di campate sono scritti a mano qui, mondo per mondo, perché sono la
## parte che porta la storia; la posizione la decide il seme. Il contrario
## darebbe varietà dove non serve e ripetizione dove fa male.
##
## **Il filo.** Non ventiquattro incarichi scollegati: ogni riparazione è una
## cosa che uno dei Dodici stava facendo quando è arrivato il Silenzio, e ha
## lasciato lì. È la terza faccia della stessa vicenda — dopo le pergamene (la
## loro voce, [[ParchmentCatalog]]) e gli apparati della nave (le stanze) —, ed
## è quella che si tocca con le mani.
##
## **E il filo adesso ha dei nomi.** (2 settembre 2026) Per un mese il filo è
## stato dichiarato qui e mai teso: i mondi 1-12 chiamavano il proprietario con
## un **ordinale** — «La Prima», «L'Ottavo» — che non compare in nessun altro
## punto del gioco, e i mondi **13-24 non nominavano nessuno**. Gli stessi dodici
## Maestri che NORA ha in bocca ([[MaestriCatalog]]) e che il giocatore risveglia
## uno per uno erano estranei proprio nelle cose che avevano lasciato a metà.
##
## Adesso ogni incarico porta il nome del Maestro della sua materia — **lo stesso
## alla prima e alla seconda visita**, perché è la stessa persona che ha lasciato
## indietro due cose — e la frase che lo nomina dice anche *come lavorava*: Rame
## seguiva il percorso fino in fondo, Seme cambiava una cosa per volta, Clessidra
## accendeva una fonte solo quando qualcuno la interrogava. Chi ripara il mulino
## del mondo 15 sta finendo il ciclo di Telaio, e Telaio è la voce che gli parla
## di coding da quando ha riacceso il Cratere.
##
## **Due eccezioni, e sono la trama.** I mondi 12 e 24 sono della logica, il cui
## Maestro è il Tredicesimo: il suo nome è stato raschiato da ogni registro, e
## scriverlo qui brucerebbe la restituzione che regge il finale. Il mondo 12 lo
## dice — è l'unica riparazione per cui non c'è nessuno da chiamare, ed è un seme
## invece di un ordinale muto; il 24 parla dei Dodici insieme, perché è la loro
## ultima stanza. Lo tiene `minimission_audit._ogni_riparazione_ha_un_padrone`.

const FORMA_SPEGNERE := "spegnere"
const FORMA_LIBERARE := "liberare"
const FORMA_RIPARARE := "riparare"
const FORMA_RIACCENDERE := "riaccendere"

const FORME := [FORMA_SPEGNERE, FORMA_LIBERARE, FORMA_RIPARARE, FORMA_RIACCENDERE]

## Che cosa il gioco mostra per ciascuna forma: il verbo del pulsante, il glifo
## sulla mappa, il colore. Stanno qui e non nella scena perché il bambino deve
## imparare a riconoscere una minimissione a colpo d'occhio, e un glifo che
## cambia da un mondo all'altro non si impara.
const RESA := {
	FORMA_SPEGNERE: {"verbo": "SPEGNI", "glifo": "*", "colore": "ff8a5c", "campate": 3},
	FORMA_LIBERARE: {"verbo": "LIBERA", "glifo": "◊", "colore": "8ff6c0", "campate": 3},
	FORMA_RIPARARE: {"verbo": "RIPARA", "glifo": "*", "colore": "ffd75e", "campate": 3},
	FORMA_RIACCENDERE: {"verbo": "RIACCENDI", "glifo": "*", "colore": "7ad7ff", "campate": 3},
}

## Gli incarichi, uno per mondo.
##
## `apertura` è quello che si legge avvicinandosi: dice il guasto e chi l'ha
## lasciato. `esito` è quello che si legge dopo, e deve nominare un cambiamento
## VISIBILE — se l'esito racconta una cosa che sulla mappa non si vede, la
## minimissione è tornata a essere un esercizio con una didascalia sopra.
const INCARICHI := {
	1: {
		"forma": FORMA_RIACCENDERE,
		"titolo": "L'obelisco che ha smesso di contare",
		"apertura": "L'obelisco dei numeri è spento da quattrocento anni. Abaco lo aveva acceso per contare i giorni: si è fermato a metà di un conto, e nessuno sa a quale numero.",
		"esito": "L'obelisco riprende il conto da dove l'aveva lasciato. La radura attorno si scopre fin dove arriva la sua luce.",
	},
	2: {
		"forma": FORMA_LIBERARE,
		"titolo": "Le rondini dell'Archivio",
		"apertura": "Stilo teneva delle rondini nell'Archivio: entravano dalle finestre alte e le portavano le parole che sentivano fuori. Le finestre si sono chiuse con loro dentro.",
		"esito": "Le finestre si riaprono. Le rondini restano — ci hanno fatto il nido — ma adesso escono e rientrano.",
	},
	3: {
		"forma": FORMA_RIPARARE,
		"titolo": "La macchina a cicli",
		"apertura": "Telaio aveva costruito una macchina che ripete un gesto finché la condizione regge. Si è inceppata al terzo giro, e da allora fa sempre il terzo giro.",
		"esito": "La macchina finisce il ciclo e ne comincia un altro, pulito. Il rumore che fa è regolare: è così che si sente che funziona.",
	},
	4: {
		"forma": FORMA_SPEGNERE,
		"titolo": "Il molo che brucia piano",
		"apertura": "Un braciere di segnalazione è caduto sul molo e da allora cova. Faro lo teneva acceso per farsi vedere da lontano: adesso si vede troppo.",
		"esito": "Il fuoco si spegne. Sotto la cenere il molo è intero, e le boe tornano a rispondere.",
	},
	5: {
		"forma": FORMA_RIPARARE,
		"titolo": "La grande leva",
		"apertura": "Leva aveva calcolato il fulcro al centimetro. Qualcuno l'ha spostato di un palmo per fare prima, e la leva non solleva più niente.",
		"esito": "Il fulcro torna al suo posto. La leva solleva il blocco che chiudeva la rampa, e la rampa si può salire.",
	},
	6: {
		"forma": FORMA_RIACCENDERE,
		"titolo": "L'albero che non risuona",
		"apertura": "Corda accordava l'albero risonante ogni stagione. Da quattrocento anni nessuno lo accorda: le corde ci sono, la nota no.",
		"esito": "L'albero riprende la sua nota. Le terrazze attorno si illuminano al ritmo, una per battuta.",
	},
	7: {
		"forma": FORMA_LIBERARE,
		"titolo": "Il cortile murato",
		"apertura": "Radice aveva murato un cortile per proteggere le iscrizioni dal vento. Dentro c'era anche una colonia di lucertole di pietra, e la protezione è diventata una prigione.",
		"esito": "Il muro si apre. Le lucertole si spargono per le rovine e ci restano: si vedono sugli archi, al sole.",
	},
	8: {
		"forma": FORMA_SPEGNERE,
		"titolo": "Il nodo in cortocircuito",
		"apertura": "Rame aveva messo le stanze in parallelo perché la caduta di una non spegnesse le altre. Un nodo è in corto e le sta trascinando giù una per una.",
		"esito": "Il corto si isola. Il ronzio cala di colpo, e gli isolotti attorno tornano ad accendersi in ordine.",
	},
	9: {
		"forma": FORMA_RIPARARE,
		"titolo": "La torre cartografica",
		"apertura": "Bussola misurava le rotte da questa torre. Il braccio dello strumento è caduto in mare: senza, la carta dell'arcipelago resta una carta di quattro secoli fa.",
		"esito": "Lo strumento torna a girare. La carta si aggiorna, e sulle isole compaiono i nomi che mancavano.",
	},
	10: {
		"forma": FORMA_LIBERARE,
		"titolo": "Le vasche della Serra",
		"apertura": "Seme aveva separato le specie in vasche per studiarle una per volta. Poi ha capito che nessuna sopravvive da sola, ed è arrivato il Silenzio prima che potesse rimetterle insieme.",
		"esito": "Le paratie si aprono. Gli animali passano da una vasca all'altra e restano dove hanno scelto: la Serra si rimescola da sola.",
	},
	11: {
		"forma": FORMA_RIACCENDERE,
		"titolo": "Il portale delle epoche",
		"apertura": "Clessidra teneva acceso il portale per confrontare due date che non tornavano. Si è spento con la domanda ancora aperta.",
		"esito": "Il portale si riaccende e mostra gli strati dello scavo tutti insieme. Si vede dove il terreno è stato rimosso, e quando.",
	},
	12: {
		"forma": FORMA_SPEGNERE,
		"titolo": "Il cuore che si surriscalda",
		"apertura": "Il labirinto muove i muri da solo, e il meccanismo al centro sta andando in temperatura. L'ha progettato per riposare ogni notte qualcuno il cui nome, sui registri di questa sala, è stato raschiato via con una lama: non riposa da quattro secoli, e non c'è nessuno da chiamare.",
		"esito": "Il meccanismo si ferma e si raffredda. I muri restano dove sono — per la prima volta il labirinto ha una forma sola.",
	},
	13: {
		"forma": FORMA_RIACCENDERE,
		"titolo": "L'osservatorio cieco",
		"apertura": "La lente maggiore è coperta di sabbia da tanto tempo che la sabbia è diventata crosta. Sotto, lo specchio è intatto: Abaco l'aveva chiuso bene prima di andarsene, perché di quello che si può controllare lui controllava tutto.",
		"esito": "La lente torna limpida e l'osservatorio proietta il cielo sulle dune. Si cammina dentro una mappa di stelle.",
	},
	14: {
		"forma": FORMA_LIBERARE,
		"titolo": "Le voci chiuse nella sala",
		"apertura": "La sala registra chi la attraversa e ripete quello che ha sentito. Le porte si sono bloccate con dentro quattro secoli di voci, che si ripetono addosso l'una all'altra. La sala l'aveva regolata Stilo, che sulle parole non lasciava mai niente al caso.",
		"esito": "Le porte cedono. Le voci si spargono per le gallerie e si diradano: adesso se ne distingue una per volta.",
	},
	15: {
		"forma": FORMA_RIPARARE,
		"titolo": "Il mulino della Città Macchina",
		"apertura": "Il mulino muove l'acqua per tutta la rete bassa. Una pala è saltata e le altre tre girano storte: la rete beve, ma male. Il ciclo lo aveva impostato Telaio: quattro pale, un giro, e si ricomincia da capo.",
		"esito": "Le quattro pale tornano in fase e il mulino gira pieno. L'acqua arriva ai quartieri bassi, e si sente da lontano.",
	},
	16: {
		"forma": FORMA_SPEGNERE,
		"titolo": "L'incendio al valico",
		"apertura": "Il mercato del valico ha preso fuoco da una parte sola, e da quella parte c'erano le insegne in sei lingue. Se brucia quello, la frontiera resta muta. Quelle insegne le aveva scritte Faro in sei lingue, perché nessuno restasse fuori per una parola sola.",
		"esito": "Il fuoco si spegne prima delle insegne. Il valico riapre, e i cartelli si leggono ancora tutti e sei.",
	},
	17: {
		"forma": FORMA_LIBERARE,
		"titolo": "La rete sul fondo",
		"apertura": "Una rete da misurazione si è impigliata sulla cattedrale sottomarina. Serviva a contare quello che passava: adesso lo trattiene. L'aveva calata Leva, per pesare la corrente con le mani invece di indovinarla.",
		"esito": "La rete si stacca e sale in superficie vuota. Quello che c'era dentro resta a nuotare attorno alla cattedrale.",
	},
	18: {
		"forma": FORMA_RIACCENDERE,
		"titolo": "Le canne mute",
		"apertura": "Metà del grande organo non prende più aria. Suona lo stesso, ma con metà delle voci: da secoli la cattedrale canta un accordo incompleto e nessuno ricorda quello intero. Lo accordava Corda, canna per canna, sempre a tempo.",
		"esito": "L'aria torna in tutte le canne. L'accordo si chiude, e le vetrate si accendono una per voce.",
	},
	19: {
		"forma": FORMA_RIPARARE,
		"titolo": "Le radici che sollevano le cripte",
		"apertura": "L'albero delle radici cresce da solo da quattrocento anni e sta scoperchiando gli archivi sotto. Nessuno l'ha potato: nessuno c'era. L'aveva piantato Radice, per far vedere con un albero che ogni parola ne tiene su delle altre.",
		"esito": "Le radici vengono guidate lungo i canali che la Diciannovesima aveva scavato apposta. Le cripte si richiudono, e l'albero cresce lo stesso.",
	},
	20: {
		"forma": FORMA_SPEGNERE,
		"titolo": "La torre che attira i fulmini",
		"apertura": "La torre di campo doveva scaricare a terra. Il collegamento è saltato e adesso raccoglie e basta: ogni scarica se la tiene, e la tempesta lo ha capito. La messa a terra l'aveva fatta Rame, che il percorso lo seguiva sempre fino in fondo.",
		"esito": "La scarica trova la sua strada verso terra. I lampi continuano, ma passano oltre: da qui si può stare.",
	},
	21: {
		"forma": FORMA_RIPARARE,
		"titolo": "Il pilastro tettonico",
		"apertura": "Il pilastro tiene ferme due placche che vogliono andare in direzioni diverse. Si è crepato in tre punti, e la crepa si allarga di un dito all'anno. Lo aveva piantato lì Bussola, dove le due placche si toccano: prima si capisce dove si è, poi si regge.",
		"esito": "Le tre crepe vengono cerchiate. Il pilastro tiene, e la faglia smette di allargarsi: si sente perché il terreno non trema più.",
	},
	22: {
		"forma": FORMA_LIBERARE,
		"titolo": "Il nucleo isolato",
		"apertura": "Una paratia di sicurezza ha sigillato il nucleo vivente insieme a tutto quello che ci viveva attorno. Doveva restare chiusa un'ora. L'aveva tarata Seme, che chiudeva una cosa per volta e aspettava di vedere che cosa cambiava.",
		"esito": "La paratia si apre. La bioluminescenza si spande nelle caverne, e quello che era chiuso dentro esce e ci resta.",
	},
	23: {
		"forma": FORMA_RIACCENDERE,
		"titolo": "L'Archivio delle Ere al buio",
		"apertura": "L'archivio si illumina solo dove qualcuno sta leggendo. Da quattrocento anni non legge nessuno, e quindi è tutto buio: le fonti ci sono ancora, ma non si vedono. Le lampade le aveva legate alla lettura Clessidra, perché una fonte si accende quando qualcuno la interroga.",
		"esito": "Le sale si riaccendono man mano. Le fonti si possono confrontare a coppie, che è l'unico modo di leggerle.",
	},
	24: {
		"forma": FORMA_SPEGNERE,
		"titolo": "Il Cuore in sovraccarico",
		"apertura": "Il Cuore dei Primi sta ricevendo da dodici sistemi tutti insieme e non regge. È l'ultima cosa che i Dodici hanno acceso, e nessuno di loro ha fatto in tempo a spegnerla bene.",
		"esito": "Il sovraccarico rientra. Il Cuore resta acceso — ma alla sua temperatura, quella per cui era stato costruito.",
	},
}

## Il grado di potenza consigliato, per mondo.
##
## **Non è un cancello.** Sotto il grado si può tentare lo stesso: costa di più
## e la forma SPEGNERE diventa più severa, ma la strada non si chiude mai — vale
## il guard-rail di tutta la mappa, **niente che sta qui può fermare la
## progressione**. Ed è calcolato invece che scritto perché deve seguire le
## soglie di [[WorldLight]]: se un giorno cambiano quelle, questo si adegua da
## solo invece di mentire.
## Il grado consigliato per un incarico segue la scala della minaccia, non una
## sua. Era tarato su cinque gradi (uno ogni cinque mondi, tetto 4); con la scala
## a nove del 14 agosto restava fermo a 4 dalla metà della campagna in poi, e da
## lì in avanti qualunque giocatore lo superava senza accorgersene: il rischio
## dichiarato — entrare impreparati costa una volta e mezzo e il danno si allarga
## — smetteva semplicemente di esistere per dodici mondi.
static func grado_richiesto(level: int) -> int:
	return clampi(floori(float(level - 1) / 3.0), 0, WorldLight.SOGLIE.size() - 2)

static func ha(level: int) -> bool:
	return INCARICHI.has(level)

## L'incarico completo di un mondo: testo autoriale + resa della forma + grado.
## Ritorna una copia: il dizionario costante è di sola lettura, e chi chiama in
## genere ci aggiunge l'identificativo dell'evento.
static func incarico(level: int) -> Dictionary:
	if not INCARICHI.has(level):
		return {}
	var voce: Dictionary = Dictionary(INCARICHI[level]).duplicate(true)
	var forma := str(voce["forma"])
	var resa: Dictionary = Dictionary(RESA[forma]).duplicate(true)
	voce["verbo"] = resa["verbo"]
	voce["glifo"] = resa["glifo"]
	voce["colore"] = resa["colore"]
	voce["campate"] = int(resa["campate"])
	voce["gradoRichiesto"] = grado_richiesto(level)
	voce["level"] = level
	return voce

## L'etichetta sulla mappa: il verbo e il titolo, niente materia.
##
## La materia la dice già la caption dell'evento, e ripeterla qui toglierebbe
## spazio all'unica cosa che distingue una minimissione da una missione — che
## c'è qualcosa di rotto, e ha un nome.
static func etichetta(level: int) -> String:
	var voce := incarico(level)
	if voce.is_empty():
		return "incarico"
	return str(voce["titolo"])

## Quante minimissioni usano ciascuna forma. Serve solo all'audit: quattro forme
## distribuite male sarebbero quattro nomi per la stessa cosa.
static func conteggio_forme() -> Dictionary:
	var out := {}
	for forma in FORME:
		out[forma] = 0
	for level in INCARICHI.keys():
		var forma := str(Dictionary(INCARICHI[level])["forma"])
		out[forma] = int(out.get(forma, 0)) + 1
	return out
