class_name WorldReadings
extends RefCounted

## **La lettura di uscita da un mondo.** (2 settembre 2026)
##
## Richiesta del committente: *«pagine con una piccola lettura di introduzione e
## di uscita da ogni mondo, per guidare e immergere lo studente nella storia»* —
## e, insieme, che *«i dialoghi e le parti che spiegano la storia non siano
## criptiche o oscure, ma adatte a un ragazzo di undici anni»*.
##
## L'ingresso c'era già: [[WorldIntroPanel]], nato dalla prima metà della stessa
## richiesta. L'uscita no. `WorldLessonCatalog` aveva un `debrief` per tutti e
## ventiquattro i mondi e quel file dichiarava per iscritto che **restava senza
## lettore**: è il difetto ricorrente di questo progetto, contenuto scritto e mai
## collegato. Qui il debrief trova la sua casa, e attorno gli cresce la lettura.
##
## ---
##
## # Perché serviva, misurato
##
## Prima di riscrivere ho misurato la leggibilità dei testi che raccontano la
## storia. **Non sono lunghi**: i beat di NORA stanno a 7,9 parole per frase e una
## sola frase su ottantasette supera le venti parole. Il problema è un altro, e
## la misura non lo vedeva: la storia è raccontata **per allusioni**. «Il sigillo
## ha tredici posti e undici nomi. Uno raschiato con una lama, dall'interno.»
## È bellissimo e per un undicenne è un enigma dentro un enigma.
##
## La scelta non è stata appiattire i beat — l'allusione è ciò che rende la
## storia bella, e toglierla la farebbe diventare un riassunto. È stato **darle
## accanto una versione detta in chiaro**, una volta per mondo, nel momento in cui
## il mondo si chiude. Chi ha capito tutto la legge e conferma; chi non aveva
## capito, capisce. Nessuno dei due si sente trattato da piccolo.
##
## ---
##
## # La forma, e perché quattro parti
##
## Sono le quattro domande che un ragazzino si fa uscendo da un posto, nell'ordine
## in cui se le fa:
##
##   FATTO      che cosa è cambiato qui, e si vede. Mai «hai completato»: una
##              cosa del mondo che prima era ferma e adesso funziona;
##   SAI FARE   la competenza, con parole di azione e mai di scuola. Non
##              «padronanza delle tabelline» ma «sai contare a gruppi senza
##              saltare niente»;
##   STORIA     **la parte che non deve essere criptica.** Dice in chiaro quello
##              che il beat ha detto per accenni, e non aggiunge niente che il
##              giocatore non possa già sapere a quel punto;
##   ADESSO     dove si va, e perché ha senso andarci.
##
## **Regola dura sulla parte STORIA: non anticipa mai.** La lettura del mondo N
## può dire soltanto quello che si sa alla fine del mondo N. `world_readings_audit`
## lo verifica cercando i nomi e i fatti dei colpi successivi.
##
## Guard-rail: nessuna lettura è obbligatoria, nessuna dà o toglie qualcosa,
## nessuna dice al giocatore che cosa NON ha fatto, e in nessuna muore nessuno
## (§10.1 di `docs/TRAMA_E_MISTERO.md`).

const LETTURE := {
	1: {
		"titolo": "La radura che ha ricominciato a contare",
		"fatto": "L'obelisco dei numeri conta di nuovo. Tobia ha smesso di contare i cristalli uno per uno: adesso li fa a gruppi di dieci, e non ne salta nessuno.",
		"sai_fare": "Sai le tabelline fino al dieci. E sai perché funzionano: moltiplicare vuol dire contare gruppi tutti uguali, non ripetere a memoria.",
		"storia": "Una voce si è svegliata dentro la nave e si chiama NORA. Non ricorda quasi niente. Appena accesa ha detto «non di nuovo», poi ha detto che non sa perché l'ha detto. Tienilo da parte: chi dice «non di nuovo» ha già visto la stessa cosa un'altra volta.",
		"adesso": "La nave ha ancora undici stanze spente. La prossima è l'Archivio delle Parole.",
	},
	2: {
		"titolo": "Le finestre dell'Archivio",
		"fatto": "Le finestre alte sono riaperte e le rondini entrano ed escono. Corinna ha smesso di mettere le parole in fila per lunghezza.",
		"sai_fare": "Sai capire una parola che non conosci guardando quelle che le stanno intorno. Non serve cercarla: serve leggere la frase intera.",
		"storia": "Qui la gente recita elenchi perfetti e non sa più che cosa vogliono dire. NORA ha detto una cosa che le fa paura: che forse è fatta così anche lei, con le parole giuste e il senso perso. È la prima volta che ti dice di avere paura.",
		"adesso": "Nel Cratere Logico c'è una macchina che ripete lo stesso giro da quattrocento anni.",
	},
	3: {
		"titolo": "La macchina che rifaceva sempre il terzo giro",
		"fatto": "La macchina a cicli è ripartita. Non è più bloccata sul terzo giro: adesso ripete finché serve e poi si ferma da sola.",
		"sai_fare": "Sai leggere una sequenza di istruzioni e seguirla passo per passo. E sai usare un ciclo: scrivere una volta quello che va fatto molte volte.",
		"storia": "NORA ha trovato nei registri il nome di quello che è successo: si chiama Silenzio. Non l'ha ricordato — l'ha letto, come lo leggeresti tu. Dice che è diverso, e che le fa paura. Il Silenzio non rompe le cose: le lascia dove sono e porta via il motivo per cui servivano.",
		"adesso": "Alla Baia dei Segnali qualcuno sta ancora trasmettendo.",
	},
	4: {
		"titolo": "Il faro che ha ripreso a chiamare",
		"fatto": "Il braciere del molo non cova più e il faro trasmette. Marea ha smesso di ripetere i messaggi senza capirli.",
		"sai_fare": "Sai riconoscere le parole inglesi delle cose e delle azioni di ogni giorno, e sai tirare fuori il senso di un messaggio dalle parole che già conosci, senza capirle tutte.",
		"storia": "È arrivato un segnale da un altro mondo, in un'altra lingua. Non è un'eco vecchia: è di adesso. Vuol dire che là fuori c'è qualcuno vivo che sta ancora spiegando qualcosa a qualcun altro. Non siete sole.",
		"adesso": "Alle Officine del Moto c'è una leva enorme che non solleva più niente.",
	},
	5: {
		"titolo": "Il taglio fresco",
		"fatto": "Il fulcro della Grande Leva è tornato al suo posto, al centimetro. Gerbo ha sollevato un masso con un dito e ci è rimasto male, poi ha riso.",
		"sai_fare": "Sai distinguere spazio, tempo e velocità. E sai perché una leva funziona: sposti il punto d'appoggio e la fatica cambia.",
		"storia": "Sul muro delle Officine c'è una spirale incisa nella pietra, di quelle aperte che girano su se stesse e non si chiudono mai. Sembra una decorazione vecchia come tutto il resto, e infatti l'avevi già vista: c'è lo stesso segno negli altri quattro mondi che hai attraversato, e ci sei passata accanto quattro volte senza fermarti a guardarlo. Poi NORA guarda il taglio nella pietra, e cambia voce. Un solco vecchio di quattrocento anni è consumato, arrotondato, sporco. Questo ha i bordi vivi: è stato inciso poche settimane fa. Vuol dire che qualcuno, mentre tu dormivi dentro la nave, camminava in questi mondi e incideva quel segno sui muri. E non ha ancora smesso.",
		"adesso": "Al Delta dei Circuiti c'è il sigillo dell'equipaggio della nave.",
	},
	6: {
		"titolo": "L'albero che si accorda",
		"fatto": "L'albero risonante è accordato. Ambra sa finalmente dire il nome di quello che sente da sempre, e Oreste legge la musica con le mani appoggiate sulle corde.",
		"sai_fare": "Sai distinguere un suono grave da uno acuto e mettere le note in ordine. Sai leggere le note sul pentagramma e contare quanto durano.",
		"storia": "NORA ha ricordato una cosa nuova, e non è un dato: è una lezione. Una voce che contava il tempo insieme a lei. Quindi qualcuno le ha insegnato qualcosa — quindi lei è stata l'allieva di qualcuno. Non è la mente di questa nave come credevate.",
		"adesso": "Nelle Rovine dei Glifi gli apparati hanno delle scritte sopra.",
	},
	7: {
		"titolo": "I nomi sugli apparati",
		"fatto": "Il cortile murato è riaperto e le lucertole di pietra sono uscite. Livia ha letto un'iscrizione invece di ricopiarla, e le è venuto da ridere.",
		"sai_fare": "Sai riconoscere i casi latini e a che cosa servono. Guardi la fine della parola e capisci che lavoro fa nella frase.",
		"storia": "Gli apparati della nave non hanno codici: hanno nomi. Nomi di persone. Quindi quando ne ripari uno non stai aggiustando una macchina — stai svegliando qualcuno. NORA ti ha chiesto di trattarli bene.",
		"adesso": "Al Delta dei Circuiti c'è il sigillo con i nomi dell'equipaggio.",
	},
	8: {
		"titolo": "Tredici posti, undici nomi",
		"fatto": "Le stanze del Delta sono di nuovo in parallelo: se una si spegne, le altre restano accese. Ciro ha smesso di collegare i cavi a memoria.",
		"sai_fare": "Sai riconoscere i pezzi di un circuito e capire dove passa la corrente. Sai che serve un percorso chiuso, altrimenti non passa niente.",
		"storia": "Nel Nodo Centrale c'è il sigillo dell'equipaggio: un disco di metallo con i posti di chi viaggiava su questa nave, e sotto ogni posto il nome inciso. I posti sono tredici. I nomi sono undici, e questo è il punto da cui non si torna indietro. Uno dei due che mancano c'era e non c'è più: è stato raschiato via con una lama, e lo si vede dai graffi. È stato fatto da dentro la nave, dopo che si era già chiusa — quindi da uno di loro, che voleva far sparire un altro di loro. L'ultimo posto invece non è stato cancellato: non è mai stato inciso. Era libero fin dall'inizio, apparecchiato apposta, e aspettava qualcuno che non è mai arrivato. NORA ripete «i Dodici Maestri» dal primo giorno. Erano dodici perché uno lo hanno cancellato, e il tredicesimo non è mai esistito.",
		"adesso": "All'Arcipelago Cartografico c'è la carta della rotta che faceva questa nave.",
	},
	9: {
		"titolo": "La rotta era un giro",
		"fatto": "La torre cartografica misura di nuovo le rotte. Alma ha disegnato un posto dove non è mai stata, usando le coordinate, e le è venuto giusto.",
		"sai_fare": "Sai trovare un luogo su una carta con le coordinate, e sai leggere le quote. Sai distinguere quello che c'è davvero sul territorio da come è disegnato.",
		"storia": "NORA ha ricostruito la rotta della nave e non è una fuga: è un giro. Tornavano sempre negli stessi mondi. Una nave che gira in tondo non sta scappando e non sta esplorando. Sta cercando qualcosa, e continua a cercarlo nello stesso posto.",
		"adesso": "Nella Serra delle Simbiosi hanno lasciato tutto in ordine prima di andarsene.",
	},
	10: {
		"titolo": "Il posto in più a tavola",
		"fatto": "Le vasche della Serra sono di nuovo collegate e le specie tornano a vivere insieme. Ortensia ha cambiato una cosa sola e ha visto cosa succedeva.",
		"sai_fare": "Sai distinguere i viventi da come si nutrono e sai vedere chi dipende da chi. E sai fare una prova come si deve: guardi, provi, cambi una cosa sola, riguardi.",
		"storia": "Qui non è successo niente di brutto in fretta. Le provviste sono chiuse in ordine, gli appunti impilati: non sono stati sorpresi, si sono preparati. E a tavola c'è un posto in più, apparecchiato. Non era di nessuno. Aspettavano qualcuno.",
		"adesso": "Alla Soglia del Tempo ci sono due date che non vanno d'accordo.",
	},
	11: {
		"titolo": "Due date che non tornano",
		"fatto": "Il portale delle Ere è acceso e le scene del passato si rivedono. Vesta non deve più scegliere quale delle sue due cronache bruciare: tiene tutte e due.",
		"sai_fare": "Sai mettere gli avvenimenti in ordine nel tempo e capire cosa viene prima e cosa dopo. E sai chiederti da dove arriva una notizia, prima di crederci.",
		"storia": "Due fonti danno due date diverse per l'arrivo del Silenzio. Una delle due sbaglia — oppure qualcuno l'ha riscritta. NORA ti ha detto di fidarti del metodo e non della prima riga che leggi. Vale per la storia e vale anche per lei.",
		"adesso": "Nel Labirinto delle Regole c'è una stanza con dentro degli schedari.",
	},
	12: {
		"titolo": "La tua è la dodici",
		"fatto": "Il meccanismo al centro del labirinto riposa di nuovo. Quinto ha smesso di imparare la strada a memoria: adesso segna i bivi con un filo, come Isa.",
		"sai_fare": "Sai trovare la regola che tiene insieme una sequenza e usarla per il passo dopo. Sai risolvere un'analogia e dire perché un elemento non c'entra.",
		"storia": "Nel cuore del Labirinto c'è uno schedario, e dentro NORA trova la propria scheda. Non è la mente di questa nave, come ha creduto e come ti ha detto per dodici mondi: è la prima allieva che i Primi hanno avuto, una ragazza a cui qualcuno ha insegnato tutto. Ma non è la scheda che fa male. Accanto alla sua ce ne sono altre dodici, identiche, numerate una per una: unità mandate fuori a esplorare. La tua porta il numero dodici. Vuol dire che prima di te ce ne sono state undici, che hanno fatto la tua stessa strada e hanno aperto le stesse porte, e che di loro non si sa più niente. Adesso quella frase che NORA ha detto appena sveglia — «non di nuovo» — ha un significato preciso, e non è bello.",
		"adesso": "Nel Deserto delle Orbite c'è una lente coperta di sabbia da tanto tempo.",
	},
	13: {
		"titolo": "«Non ho il file»",
		"fatto": "La lente maggiore dell'osservatorio è pulita e lo specchio sotto era intatto. Solano ha provato a indovinare una distanza a occhio, e ci è andato vicino.",
		"sai_fare": "Sai confrontare due grandezze con una proporzione e lavorare con le frazioni. E sai stimare: dare un numero vicino senza misurare tutto.",
		"storia": "Le hai chiesto delle undici prima di te. Ha risposto tre parole: «non ho il file». È vero, e non è tutta la verità: una risposta così corta, da una che parla sempre, vuol dire che sotto c'è dell'altro. Non l'ha detto. Voi due siete andate avanti.",
		"adesso": "Nella Biblioteca delle Voci ci sono i verbali di una riunione di quattrocento anni fa.",
	},
	14: {
		"titolo": "Il nome cancellato anche qui",
		"fatto": "Le porte della sala delle voci sono sbloccate e i quattro secoli di eco si sono sciolti. Elmo ha raccontato la stessa storia da due punti di vista diversi.",
		"sai_fare": "Sai capire da che parte sta chi racconta, e che la stessa identica cosa cambia a seconda di chi te la dice. Sai leggere anche quello che un testo non dice apertamente.",
		"storia": "Nei verbali c'è la riunione in cui si è deciso di chiudere tutto. La proposta l'ha fatta uno dei dodici, e ha convinto gli altri undici in un'ora. Il suo nome è cancellato anche lì dentro. Qualcuno lo ha inseguito ovunque per toglierlo da ogni foglio.",
		"adesso": "Nella Città Macchina i conti delle stanze della nave non tornano.",
	},
	15: {
		"titolo": "Una stanza che non c'è sulla mappa",
		"fatto": "Il mulino gira dritto e la rete bassa beve come deve. Gru ha letto l'errore invece di riavviare la macchina, e Pila lo ha segnato sul suo quaderno.",
		"sai_fare": "Sai spezzare un problema grosso in pezzi che puoi riusare. E sai cercare un errore invece di ricominciare da capo: è più veloce, anche se sembra più lento.",
		"storia": "NORA ha misurato le sezioni della nave e la somma non torna. C'è un volume senza porta che non compare su nessuna mappa, e che consuma energia da quattrocento anni. Quando gliel'hai chiesto ha detto: non chiedermi altro adesso.",
		"adesso": "Alla Frontiera delle Lingue si parla in sei lingue e le insegne stanno bruciando.",
	},
	16: {
		"titolo": "Ti ha girata attorno per sedici mondi",
		"fatto": "Il mercato del valico non brucia più e le insegne in sei lingue sono salve. Talia ha smesso di tradurre parola per parola e la gente si capisce.",
		"sai_fare": "Sai cavartela in inglese quando viaggi e scambi qualcosa. Sai legare le frasi con i connettivi e dire che cosa preferisci e perché.",
		"storia": "La stanza senza porta esiste davvero, e NORA lo sapeva. Per sedici mondi ti ha suggerito rotte diverse dentro la nave, corridoi più comodi, giri più lunghi — e ogni volta ti stava portando via da lì. Non è una bugia, e la differenza conta: quando prova a guardare quella stanza, dice, si accorge di stare pensando ad altro. Non riesce proprio ad appoggiarci sopra l'attenzione. Qualcuno l'ha fatta così apposta, e quel qualcuno sapeva esattamente cosa stava facendo. Non ti ha nascosto una cosa: le hanno tolto la possibilità di vederla. È la prima volta che ti accorgi che qualcuno ha messo le mani dentro la testa della persona di cui ti fidi.",
		"adesso": "Nell'Oceano delle Forze le insegne del molo si stanno riempiendo da sole.",
	},
	17: {
		"titolo": "Una parola sola, su ogni insegna",
		"fatto": "La rete da misurazione è staccata dalla cattedrale sottomarina e non trattiene più niente. Nerea ha fatto i conti prima di scendere, come Coral.",
		"sai_fare": "Sai che più scendi più la pressione aumenta, e sai spiegare perché una cosa galleggia. Sai riconoscere quando è la corrente a spostare le cose.",
		"storia": "Le insegne bianche del molo si sono riempite da sole, tutte con la stessa parola: FERMATI. NORA è stata netta: non è il Silenzio. Il Silenzio porta via le parole, non le scrive. Quindi c'è qualcuno che scrive, e sa che ci sei.",
		"adesso": "Nella Cattedrale del Suono, per la prima volta, qualcuno parla.",
	},
	18: {
		"titolo": "Ha parlato, ed è stanco",
		"fatto": "Metà organo aveva smesso di prendere aria: adesso la cattedrale canta l'accordo intero. Silo ha suonato piano e per la prima volta si è sentito tutto.",
		"sai_fare": "Sai riconoscere quando più note stanno bene insieme. Sai tenere il piano e il forte, e distinguere gli strumenti dal loro suono.",
		"storia": "Ha parlato. Non urla e non minaccia: è stanco come nessuno che NORA abbia mai sentito. E conosce il nome vecchio di lei, quello che non ha mai detto a nessuno. Chi conosce un nome che nessuno sa, quel nome glielo ha dato lui.",
		"adesso": "Nella Necropoli delle Radici c'è il turno di guardia di qualcuno che non ha mai smesso.",
	},
	19: {
		"titolo": "Non è il nemico",
		"fatto": "L'albero delle radici è potato e non scoperchia più gli archivi sotto. Le epigrafi si leggono, e Lapidario le legge ad alta voce come fossero notizie di oggi.",
		"sai_fare": "Sai ricostruire il significato di una parola dalla sua radice. Riconosci più declinazioni e leggi frasi latine intere.",
		"storia": "Adesso sai chi è. È il tredicesimo dell'equipaggio, quello a cui hanno raschiato via il nome, e non è un mostro: è un uomo stanchissimo. La chiusura della nave l'ha proposta lui, ha convinto gli altri undici in un'ora, e poi ha fatto la cosa che nessuno si aspettava — si è tirato fuori. Niente apparato, niente sonno: è rimasto sveglio, da solo, quattrocento anni, a tenere il Silenzio lontano dai ventiquattro mondi con le sue sole forze. E c'è dell'altro, ed è la parte che NORA fatica a dire: è lui che ha costruito lei. Lo aveva dimenticato fino a un minuto fa, perché anche quel ricordo gliel'avevano tolto.",
		"adesso": "Nella Tempesta Elettromagnetica c'è una torre che raccoglie scariche e non le scarica più.",
	},
	20: {
		"titolo": "Il Silenzio si diradava dove reggeva lui",
		"fatto": "La torre di campo scarica di nuovo a terra e la tempesta non la carica più a vuoto. Parafulmine è deluso: sperava di essere colpito.",
		"sai_fare": "Sai distinguere un collegamento in serie da uno in parallelo. Sai leggere un sensore e trovare dove si è rotta una rete.",
		"storia": "Questa è la cosa difficile del gioco, e vale la pena leggerla piano. Per venti mondi hai creduto che il Silenzio si diradasse dove passavi tu. Non è così: si diradava dove reggeva lui, e regge da quattrocento anni senza cambio. Sta cedendo adesso, mentre tu riaccendi le stanze una dopo l'altra. E la sua idea è questa: che il Silenzio non sia arrivato da fuori, ma che lo fabbrichi il sapere stesso, ogni volta che passa da qualcuno a qualcun altro senza essere capito davvero. Chi impara la forma e non il senso ne produce un po'. I Primi giravano i mondi consegnando conoscenza e ripartendo, e secondo lui sono stati loro la sorgente. Non lo dice per farti smettere: lo dice perché ha quattrocento anni di osservazioni, e NORA non sa come smentirlo. Nemmeno tu, per adesso.",
		"adesso": "Nell'Atlante Fratturato c'è la risposta a chi aspettava quel posto vuoto.",
	},
	21: {
		"titolo": "Per chi era la cattedra vuota",
		"fatto": "Il pilastro fra le due placche è di nuovo intero e la crepa ha smesso di allargarsi. Meteora continua a prevedere il tempo di ieri, e ne va fiero.",
		"sai_fare": "Sai collegare il clima al territorio e riconoscere rilievi e faglie. Sai leggere come le persone cambiano un posto e come il posto cambia loro.",
		"storia": "Il tredicesimo posto non era di nessuno, ed è questo il punto: era apparecchiato per quello che andavano a cercare. I Primi credevano che sotto tutte le materie ce ne fosse una sola. Giravano i mondi per trovarla. Il loro giro non era un giro di lezioni. Era una ricerca.",
		"adesso": "Nella Biosfera Profonda si capisce perché lo hanno cancellato.",
	},
	22: {
		"titolo": "Si è seduto lui",
		"fatto": "La paratia si è riaperta dopo quattrocento anni, e il nucleo vivente ha ricominciato a respirare insieme a tutto quello che ha intorno. Muffa ha presentato i suoi funghi, uno per uno.",
		"sai_fare": "Sai che la cellula è il pezzo di cui sono fatti i viventi. Sai seguire l'energia che passa da uno all'altro e spiegare come ci si adatta a un posto.",
		"storia": "In quella cattedra vuota lui ci si è seduto. Ha dichiarato che la ricerca era finita e si è preso lui il posto che era tenuto per una cosa che non avevano mai trovato. Ecco perché gli altri undici lo hanno cancellato da ogni registro. Non per aver chiuso la nave: per la sedia.",
		"adesso": "Nella Sala delle Ere c'è il nome che tutti tramandano da quattro secoli.",
	},
	23: {
		"titolo": "Meridiana aveva undici anni",
		"fatto": "L'archivio è illuminato di nuovo, perché qualcuno è tornato a leggere. Errata ha smesso di timbrare a caso, o quasi.",
		"sai_fare": "Sai spiegare perché un fatto è successo e che cosa ha causato dopo. Sai usare le fonti per raccontare un cambiamento invece di ripetere una data.",
		"storia": "Meridiana non era una grande maestra. Era una ragazzina del secondo mondo, undici anni, un'allieva del posto: è rimasta fuori quando la nave si è chiusa. Ha inciso lei la prima spirale. Poi è andata a vedere che cosa c'è in fondo al Silenzio, a piedi, da sola. Non è tornata — e non è morta: il Silenzio non distrugge, trattiene. È ancora là, ancora di undici anni, e ha lasciato acceso un messaggio di tre parole: «c'è qualcosa. venite». Le altre quattrocento spirali le hanno incise persone qualunque, una dopo l'altra, insegnandosele. Non c'è mai stata una leggenda: c'è stata una ragazzina che ha cominciato, e dietro di lei una fila di gente qualunque che non ha smesso.",
		"adesso": "Al Cuore dei Primi ti aspetta l'ultima cosa, e la dice NORA.",
	},
	24: {
		"titolo": "Le ho fatte io, e le ho perse io",
		"fatto": "I dodici sistemi arrivano insieme al Cuore e reggono. La nave è di nuovo intera, e nella sala c'è tutta la gente che hai aiutato.",
		"sai_fare": "Sai tenere insieme dodici modi diversi di capire e usarli sullo stesso problema. E sai fare l'ultimo passo di un ragionamento quando nessuno te lo ha spiegato.",
		"storia": "Le undici prima di te non le ha costruite il Tredicesimo: le ha costruite NORA, una alla volta, per quattro secoli. Voleva fare per qualcuno quello che avevano fatto per lei. E le ha perse tutte allo stesso modo: dicendogli tutto. Le guidava, le correggeva, dava la risposta prima ancora che sbagliassero — e una dopo l'altra si sono spente, perché sapevano tutto e non capivano niente. Tu sei la prima a cui non ha detto. Ventiquattro mondi di «non posso dirtelo, dimmi tu come faresti» non erano un limite tecnico: erano la cosa più difficile che abbia mai fatto.",
		"adesso": "Sono tutte vive, e sono là fuori. E molto più lontano c'è una riga vecchia di quattrocento anni, ancora accesa.",
	},
}

## **La tavola dipinta di ogni mondo.** (2 settembre 2026)
##
## Una lettura vuole un'immagine, e il progetto ne ha già ventitré: le
## `*-underpaint-*.png` che `ChunkGround` stende sotto il terreno per dare a
## ogni mondo la sua identità di colore. Sono dipinte a mano, sono già nel
## pacchetto e finora si vedevano solo di sbieco, sfocate sotto l'erba e le
## strade. Qui hanno una pagina intera.
##
## Sono dichiarate una per una invece di dedurle dal tema visivo: la mappa
## livello → tema vive dentro un'espressione di `WorldCompositionGenerator` e
## ricopiarne ventiquattro rami qui vorrebbe dire tenerne due versioni. Una riga
## esplicita per mondo è più lunga da leggere e non può divergere.
##
## Il mondo 1 non ha una tavola sua — usa quella comune dell'accademia — ed è
## giusto che la lettura mostri esattamente quello che il giocatore ha appena
## calpestato.
const TAVOLE := {
	1: "res://assets/terrain-underpaint-academy.png",
	2: "res://assets/archivio-parole-underpaint-v1.png",
	3: "res://assets/cratere-logico-underpaint-v1.png",
	4: "res://assets/baia-segnali-underpaint-v1.png",
	5: "res://assets/officine-moto-underpaint-v1.png",
	6: "res://assets/giardino-risonanza-underpaint-v1.png",
	7: "res://assets/rovine-glifi-underpaint-v1.png",
	8: "res://assets/delta-circuiti-underpaint-v1.png",
	9: "res://assets/arcipelago-cartografico-underpaint-v1.png",
	10: "res://assets/serra-simbiosi-underpaint-v1.png",
	11: "res://assets/soglia-tempo-underpaint-v2.png",
	12: "res://assets/labirinto-regole-underpaint-v1.png",
	13: "res://assets/deserto-orbite-underpaint-v1.png",
	14: "res://assets/biblioteca-voci-underpaint-v1.png",
	15: "res://assets/citta-macchina-underpaint-v1.png",
	16: "res://assets/frontiera-lingue-underpaint-v1.png",
	17: "res://assets/oceano-forze-underpaint-v1.png",
	18: "res://assets/cattedrale-suono-underpaint-v1.png",
	19: "res://assets/necropoli-radici-underpaint-v1.png",
	20: "res://assets/tempesta-elettromagnetica-underpaint-v1.png",
	21: "res://assets/atlante-fratturato-underpaint-v1.png",
	22: "res://assets/biosfera-profonda-underpaint-v1.png",
	23: "res://assets/sala-ere-underpaint-v2.png",
	24: "res://assets/cuore-primi-underpaint-v1.png",
}

static func tavola(level: int) -> String:
	return str(TAVOLE.get(level, ""))

## L'ordine in cui la pagina mostra le parti. Sta qui e non nel pannello perché
## è una decisione di scrittura — le quattro domande nell'ordine in cui se le fa
## chi esce da un posto — e non una decisione di disegno.
const PARTI := [
	{"chiave": "fatto", "titolo": "QUI È CAMBIATO QUESTO"},
	{"chiave": "sai_fare", "titolo": "ADESSO SAI FARE"},
	{"chiave": "storia", "titolo": "LA STORIA, IN CHIARO"},
	{"chiave": "adesso", "titolo": "DOVE SI VA"},
]

static func ha(level: int) -> bool:
	return LETTURE.has(level)

static func lettura(level: int) -> Dictionary:
	return Dictionary(LETTURE.get(level, {})).duplicate(true)

static func titolo(level: int) -> String:
	return str(lettura(level).get("titolo", ""))

## Il testo intero di una lettura, per gli audit e per chi deve misurarla.
static func testo_intero(level: int) -> String:
	var voce := lettura(level)
	var pezzi: Array = []
	for parte_data in PARTI:
		pezzi.append(str(voce.get(str((parte_data as Dictionary)["chiave"]), "")))
	return " ".join(PackedStringArray(pezzi))
