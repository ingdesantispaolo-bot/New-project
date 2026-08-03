class_name RitrovoCatalog
extends RefCounted

## Le conversazioni al Ritrovo: DATI. La regia è di `world_life.gd`.
##
## «La feature più importante di questa sezione» secondo il documento abitanti
## (§6.3), e il motivo è semplice: sono l'unica cosa che fa sembrare che il mondo
## viva anche quando Eli non c'è. Due o tre abitanti parlano **fra loro**; Eli può
## avvicinarsi e ascoltare, e non è un dialogo — è una scena che accade comunque.
##
## Contratto di ogni scena:
##
## - **4–6 battute alternate**, con i tic dei personaggi;
## - una **battuta di notizia** che cita qualcosa che ha fatto il giocatore, senza
##   rivolgersi a lui. Sostituisce la battuta all'indice indicato quando c'è una
##   notizia in coda; senza notizia, la scena resta intera e sensata;
## - un **congedo**: se Eli si avvicina se ne accorgono **alla fine**, non subito.
##   Essere visti *dopo* è ciò che fa sembrare che vivessero anche senza di te —
##   interromperli all'istante li trasformerebbe in distributori di battute;
## - una scena **per stadio del mondo**: allo stadio 0 si discute il gesto vuoto,
##   allo stadio 2 uno insegna all'altro.
##
## Stato: **mondo 1 completo** come fixture di C6 (A5 · Vita di mondo). Le altre
## 69 scene entrano nella stessa forma. Dove una scena manca, il Ritrovo resta un
## luogo normale: nessun errore.

const SCENES := {
	# -- Mondo 1 · Radura Accademia -------------------------------------------
	# Le scene di stadio 0 e 2 sono quelle scritte in ABITANTI_E_LUOGHI.md §6.3:
	# le riporto come stanno perché sono già giuste, e perché l'esempio del
	# documento è il metro su cui misurare le altre settanta.
	"w01-s0": {
		"world": 1,
		"stadio": 0,
		"cast": ["w01-tobia", "w01-ersilia"],
		"scena": [
			{"chi": "w01-tobia", "dice": "Filari da sei. Sempre sei. Uno, due, tre… e uno."},
			# «cuore» aggiunto rispetto all'esempio del documento: lì Ersilia non
			# dice mai il suo tic, e l'audit l'ha preso. L'esempio è un esempio,
			# la regola dei tic vale anche al Ritrovo.
			{"chi": "w01-ersilia", "dice": "Canta invece di contare, cuore, che fai prima."},
			{"chi": "w01-tobia", "dice": "La tua canzone non è contare, nonna."},
			{"chi": "w01-ersilia", "dice": "No? «Sette, quattordici, ventuno…» Boh. Mia madre la faceva così."},
		],
		"notizia": {
			"indice": 1,
			"chi": "w01-ersilia",
			"dice": "Dicono che quella ragazzina nuova abbia contato il filare est in tre respiri.",
		},
		"congedo": {"chi": "w01-ersilia", "dice": "Oh! Cuore, eri lì? Vieni, che il pane è ancora caldo."},
	},
	"w01-s1": {
		"world": 1,
		"stadio": 1,
		"cast": ["w01-tobia", "w01-ersilia"],
		"scena": [
			{"chi": "w01-tobia", "dice": "Nonna. Quella tua canzone. Di quanto sale per volta?"},
			{"chi": "w01-ersilia", "dice": "Sale? Non sale niente, cuore. Canta."},
			{"chi": "w01-tobia", "dice": "Sette, quattordici, ventuno. Sono sette. Sette per volta, e uno."},
			{"chi": "w01-ersilia", "dice": "…e allora? È sempre andata così."},
			{"chi": "w01-tobia", "dice": "E allora niente. Solo che io conto a uno a uno e ci metto un'ora, e uno."},
		],
		"notizia": {
			"indice": 3,
			"chi": "w01-ersilia",
			"dice": "Quella ragazzina l'ha rifatto stamattina, al deposito. Senza nemmeno fermarsi, cuore.",
		},
		"congedo": {"chi": "w01-tobia", "dice": "…tu. Da quanto ascolti? Niente, ho perso il segno lo stesso, e uno."},
	},
	"w01-s2": {
		"world": 1,
		"stadio": 2,
		"cast": ["w01-tobia", "w01-ersilia"],
		"scena": [
			{"chi": "w01-ersilia", "dice": "…ventotto, trentacinque. Ecco. E tu dicevi che non era contare."},
			{"chi": "w01-tobia", "dice": "È contare a gruppi. Me l'ha spiegato Eli. Salti di sette, e uno."},
			{"chi": "w01-ersilia", "dice": "E allora perché la mia canzone lo sapeva e io no, cuore?"},
			{"chi": "w01-tobia", "dice": "Perché qualcuno te l'ha insegnata e poi ha smesso di dirti il perché."},
			{"chi": "w01-ersilia", "dice": "…Mah. Cantiamo il nove, adesso?"},
		],
		"notizia": {
			"indice": 2,
			"chi": "w01-ersilia",
			"dice": "Da quando è arrivata quella ragazzina, qui si fanno i conti cantando, cuore.",
		},
		"congedo": {"chi": "w01-ersilia", "dice": "Cuore! Siamo qui a contare in musica. Vieni a sentire."},
	},
	"w02-s0": {
		"world": 2,
		"stadio": 0,
		"cast": ["w02-corinna", "w02-bruno"],
		"scena": [
			{"chi": "w02-corinna", "dice": "Ventidue. Ventitré. Ventiquattro dita di scaffale."},
			{"chi": "w02-bruno", "dice": "E questa come la chiami, la fila che finisce e ricomincia?"},
			{"chi": "w02-corinna", "dice": "Si chiama scaffale, Bruno."},
			{"chi": "w02-bruno", "dice": "Io la chiamo «serpescaffale». Perché gira."},
			{"chi": "w02-corinna", "dice": "Non esiste. Misuro con le dita e misuro cose che esistono."},
		],
		"notizia": {"indice": 1, "chi": "w02-bruno", "dice": "Quella ragazzina nuova ha trovato tre schede senza cercarle. E questa come la chiami, se non fortuna?"},
		"congedo": {"chi": "w02-corinna", "dice": "Oh. Eri lì. Vieni, che ti mostro come si misura una scheda con le dita."},
	},
	"w02-s1": {
		"world": 2,
		"stadio": 1,
		"cast": ["w02-corinna", "w02-bruno"],
		"scena": [
			{"chi": "w02-bruno", "dice": "Corinna. Quante dita è lungo «pane»?"},
			{"chi": "w02-corinna", "dice": "Quattro dita. Perché?"},
			{"chi": "w02-bruno", "dice": "E «forno»? Cinque. Eppure stanno insieme, e questa come la chiami?"},
			{"chi": "w02-corinna", "dice": "…stanno insieme perché parlano della stessa cosa. Non perché sono lunghe uguali."},
			{"chi": "w02-bruno", "dice": "Ecco. E allora perché le tieni in scaffali diversi?"},
		],
		"notizia": {"indice": 3, "chi": "w02-corinna", "dice": "La ragazzina ha rimesso in fila le schede per quello che servono a fare. Con le dita non l'avrei trovato mai."},
		"congedo": {"chi": "w02-bruno", "dice": "Ehi! Da quanto sei lì? E questa come la chiami, spiare o imparare?"},
	},
	"w02-s2": {
		"world": 2,
		"stadio": 2,
		"cast": ["w02-corinna", "w02-bruno"],
		"scena": [
			{"chi": "w02-corinna", "dice": "«Ricciolo». Non è una parola vera."},
			{"chi": "w02-bruno", "dice": "Non ancora. E questa come la chiami, quando una parola ce la fa?"},
			{"chi": "w02-corinna", "dice": "…si chiama entrare nell'uso. Le mie dita non c'entrano niente."},
			{"chi": "w02-bruno", "dice": "Allora scrivila nel catalogo. Fra cent'anni sarà vera."},
			{"chi": "w02-corinna", "dice": "Le concedo una riga a matita. Una."},
		],
		"notizia": {"indice": 2, "chi": "w02-bruno", "dice": "Da quando è passata quella ragazzina, Corinna scrive a matita. Prima scriveva solo a penna."},
		"congedo": {"chi": "w02-corinna", "dice": "Sei qui. Bene: mi serve un parere su una parola che non esiste ancora."},
	},
	"w03-s0": {
		"world": 3,
		"stadio": 0,
		"cast": ["w03-ruggine", "w03-sesto"],
		"scena": [
			{"chi": "w03-ruggine", "dice": "(soffia sulla manovella) Novantotto. Novantanove. Cento."},
			{"chi": "w03-sesto", "dice": "Piacere, Sesto. Perché cento?"},
			{"chi": "w03-ruggine", "dice": "Perché cento. Ci siamo presentati tre volte oggi."},
			{"chi": "w03-sesto", "dice": "Ah. Allora perché cento?"},
		],
		"notizia": {"indice": 3, "chi": "w03-sesto", "dice": "Piacere! Dicono che c'è una ragazzina che ha fatto girare la pompa senza contare fino a cento."},
		"congedo": {"chi": "w03-ruggine", "dice": "(soffia) Tu. Sei arrivata alla novantesima e non ho sentito niente."},
	},
	"w03-s1": {
		"world": 3,
		"stadio": 1,
		"cast": ["w03-ruggine", "w03-sesto"],
		"scena": [
			{"chi": "w03-sesto", "dice": "Piacere. Senti: tu fai cento volte la stessa cosa?"},
			{"chi": "w03-ruggine", "dice": "Sì."},
			{"chi": "w03-sesto", "dice": "Io me la dimentico alla terza. Come fai a ricordarti che è la stessa?"},
			{"chi": "w03-ruggine", "dice": "(soffia sulla chiave) …non me la ricordo. La rifaccio e basta."},
			{"chi": "w03-sesto", "dice": "Allora siamo uguali, solo che tu ti stanchi di più."},
		],
		"notizia": {"indice": 1, "chi": "w03-ruggine", "dice": "Quella ragazzina ha scritto la cosa una volta sola e la macchina l'ha rifatta cento. Ci penso da ieri."},
		"congedo": {"chi": "w03-sesto", "dice": "Piacere, Se— ah, sei tu. Ci eravamo già presentati stamattina, vero?"},
	},
	"w03-s2": {
		"world": 3,
		"stadio": 2,
		"cast": ["w03-ruggine", "w03-sesto"],
		"scena": [
			{"chi": "w03-ruggine", "dice": "(soffia sul foglio) Guarda: una riga. E sotto, «ripeti cento volte»."},
			{"chi": "w03-sesto", "dice": "Piacere. Cioè non lo fai più?"},
			{"chi": "w03-ruggine", "dice": "Lo faccio una volta e lo dico bene. Il ripetere è compito suo."},
			{"chi": "w03-sesto", "dice": "Quindi anche io potrei dire una cosa una volta e ricordarmela cento."},
			{"chi": "w03-ruggine", "dice": "Non funziona così per le persone. Ma il quaderno sì. Prova."},
		],
		"notizia": {"indice": 4, "chi": "w03-ruggine", "dice": "L'ha imparato da quella ragazzina: scrivi una volta, ripeti cento. E adesso Sesto ha un quaderno."},
		"congedo": {"chi": "w03-ruggine", "dice": "(soffia sugli attrezzi) Sei qui. Bene, sto insegnando a uno che dimentica. Serve pazienza in due."},
	},
	"w04-s0": {
		"world": 4,
		"stadio": 0,
		"cast": ["w04-marea", "w04-lino"],
		"scena": [
			{"chi": "w04-marea", "dice": "(sussurra) «It is raining cats and dogs». Gatti. E cani."},
			{"chi": "w04-lino", "dice": "Piove forte, captain."},
			{"chi": "w04-marea", "dice": "Ma dice gatti."},
			{"chi": "w04-lino", "dice": "E io dico «piove che Dio la manda» e non manda niente nessuno."},
		],
		"notizia": {"indice": 2, "chi": "w04-marea", "dice": "(sussurra) Dicono che la ragazzina abbia risposto al faro senza tradurre parola per parola."},
		"congedo": {"chi": "w04-lino", "dice": "Ehi, captain! Da quanto sei sul molo? Vieni che qui si discute di gatti."},
	},
	"w04-s1": {
		"world": 4,
		"stadio": 1,
		"cast": ["w04-marea", "w04-lino"],
		"scena": [
			{"chi": "w04-lino", "dice": "Captain Marea. Quante parole sai?"},
			{"chi": "w04-marea", "dice": "(sussurra il conto) …milleduecento, forse."},
			{"chi": "w04-lino", "dice": "Io venti. E ci ho comprato una barca."},
			{"chi": "w04-marea", "dice": "E come hai fatto?"},
			{"chi": "w04-lino", "dice": "Ho detto «good boat, good price, my friend» e ho sorriso, captain."},
		],
		"notizia": {"indice": 3, "chi": "w04-lino", "dice": "La ragazzina ha fatto come me: quattro parole e una faccia sicura. Ha funzionato, captain."},
		"congedo": {"chi": "w04-marea", "dice": "(sussurra) …sei qui. Non ti ho sentita arrivare. Vieni, oggi si impara dal Vecchio Lino."},
	},
	"w04-s2": {
		"world": 4,
		"stadio": 2,
		"cast": ["w04-marea", "w04-lino"],
		"scena": [
			{"chi": "w04-marea", "dice": "«Break a leg». Non è rompere una gamba: è in bocca al lupo."},
			{"chi": "w04-lino", "dice": "Ma va'. E io che auguravo le gambe rotte a mezzo porto, captain."},
			{"chi": "w04-marea", "dice": "(sussurra) Le frasi fatte si imparano intere. Come i nodi."},
			{"chi": "w04-lino", "dice": "Ecco, i nodi li capisco. Dimmene un'altra, captain."},
			{"chi": "w04-marea", "dice": "«Under the weather». Vuol dire che non ti senti bene."},
		],
		"notizia": {"indice": 1, "chi": "w04-marea", "dice": "(sussurra) L'ha spiegato la ragazzina: le frasi fatte non si smontano, si imparano intere."},
		"congedo": {"chi": "w04-lino", "dice": "Captain! Arrivi giusta: mi stanno insegnando a non augurare gambe rotte."},
	},
	"w05-s0": {
		"world": 5,
		"stadio": 0,
		"cast": ["w05-gerbo", "w05-tilla"],
		"scena": [
			{"chi": "w05-gerbo", "dice": "(si sputa sulle mani) Ancora. Alla tre."},
			{"chi": "w05-tilla", "dice": "Te lo faccio vedere un modo più facile?"},
			{"chi": "w05-gerbo", "dice": "No."},
			{"chi": "w05-tilla", "dice": "Ok. Te lo faccio vedere domani, allora."},
		],
		"notizia": {"indice": 3, "chi": "w05-tilla", "dice": "Quella ragazzina ha spostato la trave da sola. Te lo faccio vedere dove ha messo il sasso sotto?"},
		"congedo": {"chi": "w05-gerbo", "dice": "(si asciuga le mani) Tu. Non startene lì impalata: guarda come si fa a sbagliare."},
	},
	"w05-s1": {
		"world": 5,
		"stadio": 1,
		"cast": ["w05-gerbo", "w05-tilla"],
		"scena": [
			{"chi": "w05-tilla", "dice": "Gerbo. Sull'altalena io sollevo mio fratello e pesa il doppio di me."},
			{"chi": "w05-gerbo", "dice": "L'altalena è un gioco."},
			{"chi": "w05-tilla", "dice": "E la trave no? Te lo faccio vedere: sono uguali, solo che una è più lunga."},
			{"chi": "w05-gerbo", "dice": "(si guarda le mani) …fammi vedere. Una volta sola."},
		],
		"notizia": {"indice": 1, "chi": "w05-gerbo", "dice": "Ho visto quella ragazzina fare come dici tu. E la trave si è mossa. Con un dito."},
		"congedo": {"chi": "w05-tilla", "dice": "Sei arrivata! Guarda: sta per dire che è un gioco, e poi guarda cosa fa."},
	},
	"w05-s2": {
		"world": 5,
		"stadio": 2,
		"cast": ["w05-gerbo", "w05-tilla"],
		"scena": [
			{"chi": "w05-gerbo", "dice": "Il sasso più vicino al masso. Il palo più lungo di qua."},
			{"chi": "w05-tilla", "dice": "E adesso spingi piano. Te lo faccio vedere io quanto piano?"},
			{"chi": "w05-gerbo", "dice": "(si sputa sulle mani per abitudine, poi si ferma) …non serve nemmeno."},
			{"chi": "w05-tilla", "dice": "No. Non serve."},
			{"chi": "w05-gerbo", "dice": "Vent'anni di schiena, e bastava spostare un sasso."},
		],
		"notizia": {"indice": 4, "chi": "w05-gerbo", "dice": "Me l'ha fatto capire quella ragazzina, mica io. Io spingevo e basta."},
		"congedo": {"chi": "w05-tilla", "dice": "Oh, ci sei anche tu! Te lo faccio vedere di nuovo? A lui è servito guardarlo due volte."},
	},
	"w06-s0": {
		"world": 6,
		"stadio": 0,
		"cast": ["w06-ambra", "w06-oreste"],
		"scena": [
			{"chi": "w06-ambra", "dice": "Mmh. (canticchia due note)"},
			{"chi": "w06-oreste", "dice": "(appoggia la mano alla cassa) La seconda trema di più."},
			{"chi": "w06-ambra", "dice": "Sì! Mmh… ma non so dirti perché."},
			{"chi": "w06-oreste", "dice": "Io non ho bisogno del perché. Ho la mano."},
		],
		"notizia": {"indice": 2, "chi": "w06-ambra", "dice": "Mmh. Dicono che la ragazzina abbia messo un nome a quello che sentiamo. Un nome vero."},
		"congedo": {"chi": "w06-oreste", "dice": "(alza la mano dalla cassa) C'è qualcuno. Ho sentito il pavimento. Vieni."},
	},
	"w06-s1": {
		"world": 6,
		"stadio": 1,
		"cast": ["w06-ambra", "w06-oreste"],
		"scena": [
			{"chi": "w06-oreste", "dice": "Ambra. Se accorcio la corda a metà, la mano sente il doppio del tremito."},
			{"chi": "w06-ambra", "dice": "Mmh. E suona più alta. Molto più alta."},
			{"chi": "w06-oreste", "dice": "Metà corda, doppio tremito. Sempre. Non è una mia impressione."},
			{"chi": "w06-ambra", "dice": "Mmh… allora quello che sento io e quello che tocchi tu sono la stessa cosa?"},
			{"chi": "w06-oreste", "dice": "(mano sulla corda) Lo stai chiedendo a me?"},
		],
		"notizia": {"indice": 3, "chi": "w06-ambra", "dice": "La ragazzina ha misurato le corde del salice. Mmh. I numeri e le mie orecchie dicevano la stessa cosa."},
		"congedo": {"chi": "w06-ambra", "dice": "Mmh! Sei qui. Vieni: stiamo scoprendo che sentiamo la stessa cosa in due modi."},
	},
	"w06-s2": {
		"world": 6,
		"stadio": 2,
		"cast": ["w06-ambra", "w06-oreste"],
		"scena": [
			{"chi": "w06-ambra", "dice": "Questa è una quinta. Mmh. Adesso ha un nome."},
			{"chi": "w06-oreste", "dice": "(mano sulla cassa) Quinta. E la sento uguale a prima."},
			{"chi": "w06-ambra", "dice": "Uguale. Solo che adesso te la posso chiedere da lontano."},
			{"chi": "w06-oreste", "dice": "Questo è il punto. Un suono con un nome si può regalare."},
			{"chi": "w06-ambra", "dice": "Mmh. Chi te l'ha detto?"},
			{"chi": "w06-oreste", "dice": "C'era scritto sulla custodia di un diapason. L'ho letto con le dita."},
		],
		"notizia": {"indice": 4, "chi": "w06-oreste", "dice": "(mano sullo strumento) La ragazzina ha letto quella custodia prima di me. Mi ha detto cosa c'era scritto."},
		"congedo": {"chi": "w06-ambra", "dice": "Mmh, sei arrivata! Oreste ha appena detto una cosa che voglio farti sentire."},
	},
	"w07-s0": {
		"world": 7,
		"stadio": 0,
		"cast": ["w07-livia", "w07-zeno"],
		"scena": [
			{"chi": "w07-livia", "dice": "(soffia sull'inchiostro) Ventidue righe, nessun errore."},
			{"chi": "w07-zeno", "dice": "E questa parola di chi è parente?"},
			{"chi": "w07-livia", "dice": "Non lo so. La copio, non la interrogo."},
			{"chi": "w07-zeno", "dice": "Però l'hai scritta duecento volte. Non ti è mai venuta voglia?"},
			{"chi": "w07-livia", "dice": "(soffia sull'inchiostro) La voglia non c'entra con la precisione."},
		],
		"notizia": {"indice": 1, "chi": "w07-zeno", "dice": "La ragazzina nuova ha letto tre parole del muro senza copiarle. E questa di chi è parente, si è chiesta."},
		"congedo": {"chi": "w07-zeno", "dice": "Ehi! Eri lì dietro. E questa di chi è parente, una che ascolta senza farsi vedere?"},
	},
	"w07-s1": {
		"world": 7,
		"stadio": 1,
		"cast": ["w07-livia", "w07-zeno"],
		"scena": [
			{"chi": "w07-zeno", "dice": "Livia. «Aqua». «Acquaio». «Acquerello». Parenti?"},
			{"chi": "w07-livia", "dice": "…sì. Evidentemente sì."},
			{"chi": "w07-zeno", "dice": "E questa di chi è parente: «acquisto»?"},
			{"chi": "w07-livia", "dice": "(soffia sull'inchiostro) Di nessuno. Sembra, e non lo è."},
			{"chi": "w07-zeno", "dice": "Quindi il mio gioco a volte sbaglia."},
			{"chi": "w07-livia", "dice": "Il tuo gioco a volte sbaglia. Il mio non prova nemmeno."},
		],
		"notizia": {"indice": 4, "chi": "w07-livia", "dice": "La ragazzina ha trovato una parola che sembrava parente e non lo era. (soffia sull'inchiostro) Nemmeno io l'avrei vista."},
		"congedo": {"chi": "w07-livia", "dice": "(soffia sull'inchiostro fresco) Sei arrivata. Bene: ho bisogno di qualcuno che sappia dubitare."},
	},
	"w07-s2": {
		"world": 7,
		"stadio": 2,
		"cast": ["w07-livia", "w07-zeno"],
		"scena": [
			{"chi": "w07-livia", "dice": "Ho copiato questa riga per vent'anni. Oggi l'ho letta."},
			{"chi": "w07-zeno", "dice": "E cosa dice?"},
			{"chi": "w07-livia", "dice": "Dice che chi copia senza capire conserva la forma e perde la cosa."},
			{"chi": "w07-zeno", "dice": "E questa di chi è parente, «conservare»?"},
			{"chi": "w07-livia", "dice": "(soffia sull'inchiostro) Di «servare», tenere. Vedi? Lo sto facendo anch'io."},
		],
		"notizia": {"indice": 2, "chi": "w07-zeno", "dice": "L'ha letta grazie alla ragazzina. Vent'anni a copiarla e non l'aveva mai letta, capisci?"},
		"congedo": {"chi": "w07-zeno", "dice": "Sei qui! E questa di chi è parente: una copista che di colpo legge?"},
	},
	"w08-s0": {
		"world": 8,
		"stadio": 0,
		"cast": ["w08-ciro", "w08-doria"],
		"scena": [
			{"chi": "w08-ciro", "dice": "Uno, due, tre nodi. Come sempre."},
			{"chi": "w08-doria", "dice": "E se domani fossero quattro?"},
			{"chi": "w08-ciro", "dice": "Non lo sono mai stati."},
			{"chi": "w08-doria", "dice": "L'acqua del canale, sai, cambia strada ogni primavera."},
			{"chi": "w08-ciro", "dice": "L'acqua è acqua. Questi sono nodi."},
		],
		"notizia": {"indice": 3, "chi": "w08-doria", "dice": "Dicono che la ragazzina abbia acceso la lampada da una strada nuova. L'acqua fa lo stesso, quando può."},
		"congedo": {"chi": "w08-ciro", "dice": "Sei tu! Vieni, conta i nodi con me: da solo mi perdo sempre al quarto."},
	},
	"w08-s1": {
		"world": 8,
		"stadio": 1,
		"cast": ["w08-ciro", "w08-doria"],
		"scena": [
			{"chi": "w08-doria", "dice": "Ciro. Perché la chiusa stretta manda l'acqua veloce?"},
			{"chi": "w08-ciro", "dice": "Perché deve passarne tanta da poco spazio. Che c'entra con i nodi?"},
			{"chi": "w08-doria", "dice": "Niente, forse. Però il filo sottile scalda e quello grosso no."},
			{"chi": "w08-ciro", "dice": "…uno, due, tre. Aspetta."},
			{"chi": "w08-doria", "dice": "Prenditi il tempo. L'acqua ha aspettato me per trent'anni."},
		],
		"notizia": {"indice": 1, "chi": "w08-ciro", "dice": "La ragazzina l'ha detto prima di te: stretto e veloce, largo e piano. Contavo i nodi e non ci arrivavo."},
		"congedo": {"chi": "w08-doria", "dice": "C'è qualcuno alla porta. L'acqua lo sa prima di me: la superficie si muove. Entra."},
	},
	"w08-s2": {
		"world": 8,
		"stadio": 2,
		"cast": ["w08-ciro", "w08-doria"],
		"scena": [
			{"chi": "w08-ciro", "dice": "Ho rifatto il quadro. Non a memoria: seguendo il percorso, tutti e tre i nodi."},
			{"chi": "w08-doria", "dice": "E se domani lo spostano?"},
			{"chi": "w08-ciro", "dice": "Lo rifaccio. Perché adesso so cosa fa ogni nodo, non solo dov'è."},
			{"chi": "w08-doria", "dice": "Ecco. Adesso somigli all'acqua."},
			{"chi": "w08-ciro", "dice": "Non so se è un complimento, ma me lo tengo."},
		],
		"notizia": {"indice": 2, "chi": "w08-doria", "dice": "È stata la ragazzina a chiederglielo: non dov'è il nodo, cosa fa. L'acqua chiede sempre così."},
		"congedo": {"chi": "w08-ciro", "dice": "Ah, sei arrivata! Uno, due, tre nodi — e stavolta so dirti a cosa servono."},
	},
	"w09-s0": {
		"world": 9,
		"stadio": 0,
		"cast": ["w09-alma", "w09-remo"],
		"scena": [
			{"chi": "w09-alma", "dice": "(bagna la matita) Disegno solo quello che ho visto."},
			{"chi": "w09-remo", "dice": "Allora metà arcipelago non esiste."},
			{"chi": "w09-alma", "dice": "Metà arcipelago non è disegnato. È diverso."},
			{"chi": "w09-remo", "dice": "La rotta del nord la conosco a memoria e non è su nessuna carta. Anche lei è diversa?"},
		],
		"notizia": {"indice": 2, "chi": "w09-remo", "dice": "Dicono che la ragazzina abbia trovato un'isola partendo da due numeri. La rotta, quella, non l'ha chiesta a nessuno."},
		"congedo": {"chi": "w09-alma", "dice": "(bagna la matita) Sei lì da un po'. Vieni: mi serve qualcuno che abbia visto il promontorio est."},
	},
	"w09-s1": {
		"world": 9,
		"stadio": 1,
		"cast": ["w09-alma", "w09-remo"],
		"scena": [
			{"chi": "w09-remo", "dice": "Alma. Se io dico «due mani a destra del faro», tu ci arrivi?"},
			{"chi": "w09-alma", "dice": "No."},
			{"chi": "w09-remo", "dice": "E se dico due numeri?"},
			{"chi": "w09-alma", "dice": "(bagna la matita) …ci arrivo. Ci arriva chiunque, anche chi non ti ha mai sentito parlare."},
			{"chi": "w09-remo", "dice": "Ecco perché voglio scriverla. Ogni rotta deve sopravvivere a chi la sa."},
		],
		"notizia": {"indice": 3, "chi": "w09-alma", "dice": "La ragazzina ha messo i numeri sulla carta e la rotta è comparsa. (bagna la matita) I numeri sono posti, a quanto pare."},
		"congedo": {"chi": "w09-remo", "dice": "Ehi. La rotta di chi entra piano è quella dei curiosi. Siediti."},
	},
	"w09-s2": {
		"world": 9,
		"stadio": 2,
		"cast": ["w09-alma", "w09-remo"],
		"scena": [
			{"chi": "w09-alma", "dice": "Rotta del nord, scritta. Undici punti, con i numeri."},
			{"chi": "w09-remo", "dice": "L'hai fatta più corta di come la racconto io."},
			{"chi": "w09-alma", "dice": "(bagna la matita) L'ho fatta più precisa. Il racconto tienitelo tu."},
			{"chi": "w09-remo", "dice": "Allora è giusta così: la rotta ha bisogno di tutte e due le cose."},
			{"chi": "w09-alma", "dice": "Su questo non discuto. Ho scritto anche i tuoi nomi, in fondo."},
		],
		"notizia": {"indice": 1, "chi": "w09-remo", "dice": "L'ha cominciata la ragazzina, quella carta. Poi Alma non si è più fermata."},
		"congedo": {"chi": "w09-alma", "dice": "(bagna la matita) Arrivi giusta. Guarda: la rotta di Remo, su carta, che non si perde più."},
	},
	"w10-s0": {
		"world": 10,
		"stadio": 0,
		"cast": ["w10-ortensia", "w10-mirta"],
		"scena": [
			{"chi": "w10-ortensia", "dice": "Ho cambiato acqua, luce e terra. Le piante stanno benissimo."},
			{"chi": "w10-mirta", "dice": "Bevi la tisana, piccola. E quale delle tre ha funzionato?"},
			{"chi": "w10-ortensia", "dice": "Tutte e tre insieme, immagino. Le piante non si lamentano."},
			{"chi": "w10-mirta", "dice": "Le mie non si lamentavano mai. E infatti non ho capito niente per vent'anni."},
		],
		"notizia": {"indice": 1, "chi": "w10-mirta", "dice": "Bevi la tisana. Dicono che la ragazzina abbia cambiato una cosa sola, e che si sia visto subito."},
		"congedo": {"chi": "w10-mirta", "dice": "Oh, piccola, sei qui. Siediti che la tisana è appena pronta."},
	},
	"w10-s1": {
		"world": 10,
		"stadio": 1,
		"cast": ["w10-ortensia", "w10-mirta"],
		"scena": [
			{"chi": "w10-mirta", "dice": "Guarda qua, piccola. Quarant'anni di prime gemme, una data per riga."},
			{"chi": "w10-ortensia", "dice": "…queste sono misure. Le piante te lo dicono da quarant'anni e nessuno le ascolta."},
			{"chi": "w10-mirta", "dice": "Io ho solo scritto quando fioriva il pesco. Non è scienza."},
			{"chi": "w10-ortensia", "dice": "È esattamente scienza. Ti manca solo il nome."},
			{"chi": "w10-mirta", "dice": "Prendi la tisana e non dire sciocchezze."},
		],
		"notizia": {"indice": 3, "chi": "w10-ortensia", "dice": "La ragazzina ha messo i quaderni in fila e ha visto la curva. Anche le piante l'avevano vista."},
		"congedo": {"chi": "w10-ortensia", "dice": "Ah, ci sei. Vieni: sto convincendo Mirta di essere una scienziata da quarant'anni."},
	},
	"w10-s2": {
		"world": 10,
		"stadio": 2,
		"cast": ["w10-ortensia", "w10-mirta"],
		"scena": [
			{"chi": "w10-ortensia", "dice": "Una variabile alla volta. L'ho scritto sul vetro della serra."},
			{"chi": "w10-mirta", "dice": "E ha funzionato, piccola?"},
			{"chi": "w10-ortensia", "dice": "Alla terza prova. Le prime due sono andate male e so anche perché."},
			{"chi": "w10-mirta", "dice": "Allora tieni, la tisana della terza prova. È la più buona."},
			{"chi": "w10-ortensia", "dice": "Le piante approvano. Me l'hanno detto stamattina."},
		],
		"notizia": {"indice": 2, "chi": "w10-mirta", "dice": "Bevi, piccola. La ragazzina gliel'ha fatto scrivere sul vetro, così non se lo dimentica più."},
		"congedo": {"chi": "w10-mirta", "dice": "Piccola! Arrivi giusta per la tisana e per la buona notizia."},
	},
	"w11-s0": {
		"world": 11,
		"stadio": 0,
		"cast": ["w11-danio", "w11-vesta"],
		"scena": [
			{"chi": "w11-danio", "dice": "Autentica. Ci scommetto una moneta."},
			{"chi": "w11-vesta", "dice": "Su cosa, esattamente?"},
			{"chi": "w11-danio", "dice": "Me l'hanno detto in tre. Tre persone diverse!"},
			{"chi": "w11-vesta", "dice": "Anche le cronache si copiano fra loro. Tre copie non fanno tre testimoni."},
		],
		"notizia": {"indice": 3, "chi": "w11-vesta", "dice": "Dicono che la ragazzina abbia chiesto a ciascuno dove l'avesse sentito. Tutte e tre le cronache portavano allo stesso tale."},
		"congedo": {"chi": "w11-danio", "dice": "Oh, sei tu! Scommetto che hai sentito tutto. Scommetto anche che hai ragione tu."},
	},
	"w11-s1": {
		"world": 11,
		"stadio": 1,
		"cast": ["w11-danio", "w11-vesta"],
		"scena": [
			{"chi": "w11-vesta", "dice": "Danio. Due cronache dicono cose opposte sullo stesso anno."},
			{"chi": "w11-danio", "dice": "Facile: scommetto su quella che dicono in più persone."},
			{"chi": "w11-vesta", "dice": "Le ho pesate. Una è di chi c'era, l'altra è di chi l'ha sentito raccontare."},
			{"chi": "w11-danio", "dice": "…e allora la scommessa non si vince contando le teste."},
			{"chi": "w11-vesta", "dice": "No. E non si vince nemmeno bruciando una delle due cronache."},
		],
		"notizia": {"indice": 2, "chi": "w11-danio", "dice": "Scommetto che è stata la ragazzina a chiederlo: non quanti lo dicono, chi lo dice. Ho perso una moneta e ho imparato una cosa."},
		"congedo": {"chi": "w11-vesta", "dice": "(posa le cronache) C'è qualcuno. Avvicinati: si stava discutendo di prove."},
	},
	"w11-s2": {
		"world": 11,
		"stadio": 2,
		"cast": ["w11-danio", "w11-vesta"],
		"scena": [
			{"chi": "w11-danio", "dice": "Ho restituito l'anfora. Falsa, e l'ho capito dal fondo."},
			{"chi": "w11-vesta", "dice": "Dal bollo?"},
			{"chi": "w11-danio", "dice": "Dal bollo. Scommetto che al mercato non se l'aspettavano."},
			{"chi": "w11-vesta", "dice": "Le cronache si controllano allo stesso modo: si guarda chi le ha firmate."},
			{"chi": "w11-danio", "dice": "Sto imparando a perdere le scommesse. È più utile di quanto sembri."},
		],
		"notizia": {"indice": 1, "chi": "w11-vesta", "dice": "Gliel'ha insegnato la ragazzina, guardando il fondo di un vaso. Le cronache hanno un fondo anche loro."},
		"congedo": {"chi": "w11-danio", "dice": "Ehi! Scommetto che vuoi vedere il bollo. Vieni, te lo mostro."},
	},
	"w12-s0": {
		"world": 12,
		"stadio": 0,
		"cast": ["w12-quinto", "w12-isa"],
		"scena": [
			{"chi": "w12-quinto", "dice": "Duecentododici passi fino alla sala rossa."},
			{"chi": "w12-isa", "dice": "E se invece i muri si spostassero?"},
			{"chi": "w12-quinto", "dice": "Non si spostano."},
			{"chi": "w12-isa", "dice": "Stamattina si sono spostati. E i tuoi passi sono diventati duecentonovanta."},
		],
		"notizia": {"indice": 3, "chi": "w12-isa", "dice": "E se invece fosse come dice la ragazzina? Lei non conta i passi: segna i bivi e torna indietro."},
		"congedo": {"chi": "w12-quinto", "dice": "Tu. Quanti passi hai fatto per arrivare fin qui senza che ti sentissi?"},
	},
	"w12-s1": {
		"world": 12,
		"stadio": 1,
		"cast": ["w12-quinto", "w12-isa"],
		"scena": [
			{"chi": "w12-isa", "dice": "Guarda. Filo al primo bivio, filo al secondo."},
			{"chi": "w12-quinto", "dice": "È un gioco da bambini."},
			{"chi": "w12-isa", "dice": "E se invece funzionasse anche coi muri che si spostano?"},
			{"chi": "w12-quinto", "dice": "…ho contato i passi per trent'anni."},
			{"chi": "w12-isa", "dice": "Lo so. Per questo te lo dico piano."},
		],
		"notizia": {"indice": 1, "chi": "w12-quinto", "dice": "La ragazzina ha usato il filo di Isa e ha fatto meno passi di me. Molti meno."},
		"congedo": {"chi": "w12-isa", "dice": "Oh, sei arrivata! E se invece provassimo il filo in tre?"},
	},
	"w12-s2": {
		"world": 12,
		"stadio": 2,
		"cast": ["w12-quinto", "w12-isa"],
		"scena": [
			{"chi": "w12-quinto", "dice": "Bivio segnato. Torno indietro. Provo l'altro."},
			{"chi": "w12-isa", "dice": "E se invece ti dimentichi quale hai già provato?"},
			{"chi": "w12-quinto", "dice": "Non me lo dimentico: c'è il filo. Non conto più i passi, conto le scelte."},
			{"chi": "w12-isa", "dice": "Il tuo metodo ha un nome, sai. Me l'hanno detto."},
			{"chi": "w12-quinto", "dice": "Il *tuo* metodo, Isa. Io l'ho solo imparato."},
		],
		"notizia": {"indice": 3, "chi": "w12-isa", "dice": "Gliel'ha detto la ragazzina: il mio trucco ha un nome anche fuori dal Labirinto. E se invece fosse sempre stato un metodo?"},
		"congedo": {"chi": "w12-quinto", "dice": "Sei qui. Guarda: ho fatto quaranta passi invece di trecento, e non ho contato nemmeno uno."},
	},
	"w13-s0": {
		"world": 13,
		"stadio": 0,
		"cast": ["w13-solano", "w13-duna"],
		"scena": [
			{"chi": "w13-solano", "dice": "(pulisce le lenti) Senza strumento non do numeri."},
			{"chi": "w13-duna", "dice": "(mano tesa) Due mani e mezzo. Due ore di cammino."},
			{"chi": "w13-solano", "dice": "Questo non è misurare. È indovinare."},
			{"chi": "w13-duna", "dice": "Sarà. Però ci arrivo, e tu sei fermo qui."},
		],
		"notizia": {"indice": 3, "chi": "w13-duna", "dice": "Dicono che la ragazzina abbia dato una risposta con lo strumento rotto. E che fosse vicina a quella vera."},
		"congedo": {"chi": "w13-solano", "dice": "(pulisce le lenti) C'è qualcuno. Bene: mi serve un giudice imparziale."},
	},
	"w13-s1": {
		"world": 13,
		"stadio": 1,
		"cast": ["w13-solano", "w13-duna"],
		"scena": [
			{"chi": "w13-duna", "dice": "Ho camminato fino alla roccia. Due ore e sette minuti."},
			{"chi": "w13-solano", "dice": "E la tua mano diceva due ore."},
			{"chi": "w13-duna", "dice": "(mano tesa) Sette minuti di sbaglio su centoventi."},
			{"chi": "w13-solano", "dice": "(pulisce le lenti) …è un errore del sei per cento. È una stima, Duna. Non un dono."},
			{"chi": "w13-duna", "dice": "E che differenza fa?"},
			{"chi": "w13-solano", "dice": "Che un dono non si insegna. Una stima sì."},
		],
		"notizia": {"indice": 2, "chi": "w13-solano", "dice": "La ragazzina ha misurato quello che Duna indovinava. I due numeri erano quasi lo stesso numero."},
		"congedo": {"chi": "w13-duna", "dice": "(mano tesa verso di te) Eccoti. Sei a dieci passi, e non ho bisogno di contarli."},
	},
	"w13-s2": {
		"world": 13,
		"stadio": 2,
		"cast": ["w13-solano", "w13-duna"],
		"scena": [
			{"chi": "w13-solano", "dice": "Braccio teso, pollice alzato, un occhio chiuso. Così?"},
			{"chi": "w13-duna", "dice": "(mano tesa) Così. E adesso conta quante mani."},
			{"chi": "w13-solano", "dice": "(pulisce le lenti, poi le posa) Tre. Tre mani."},
			{"chi": "w13-duna", "dice": "Due ore e mezzo di cammino. Controlla domani con lo strumento nuovo."},
			{"chi": "w13-solano", "dice": "Lo farò. E se torna, avrò imparato una cosa che credevo impossibile."},
		],
		"notizia": {"indice": 4, "chi": "w13-duna", "dice": "(mano tesa) È la ragazzina che ha detto a Solano di provare. Lui non l'avrebbe mai fatto da solo."},
		"congedo": {"chi": "w13-solano", "dice": "(pulisce le lenti) Sei arrivata. Guarda l'astronomo che indovina, e non ridere."},
	},
	"w14-s0": {
		"world": 14,
		"stadio": 0,
		"cast": ["w14-elmo", "w14-ottavia"],
		"scena": [
			{"chi": "w14-elmo", "dice": "(taglia l'aria) Finisce che il ponte crolla. Ecco, riassunta."},
			{"chi": "w14-ottavia", "dice": "(cambia voce) «E io ve l'avevo detto, di non passarci!»"},
			{"chi": "w14-elmo", "dice": "Non è nel testo."},
			{"chi": "w14-ottavia", "dice": "È nel modo in cui la vecchia lo racconta. Il finale è lo stesso, la storia no."},
		],
		"notizia": {"indice": 3, "chi": "w14-ottavia", "dice": "(cambia voce) «Quella ragazzina!» Ha chiesto alla vecchia del ponte di raccontarla lei. Ed era un'altra storia."},
		"congedo": {"chi": "w14-elmo", "dice": "(taglia l'aria) Chiudo qui. Tu, vieni: mi serve qualcuno che legga anche la parte di mezzo."},
	},
	"w14-s1": {
		"world": 14,
		"stadio": 1,
		"cast": ["w14-elmo", "w14-ottavia"],
		"scena": [
			{"chi": "w14-ottavia", "dice": "Stessa storia, tre voci. (cambia voce) «Io c'ero.» (cambia voce) «Io l'ho sentito dire.»"},
			{"chi": "w14-elmo", "dice": "Il fatto non cambia."},
			{"chi": "w14-ottavia", "dice": "No. Cambia chi ha paura, e di cosa."},
			{"chi": "w14-elmo", "dice": "(taglia l'aria) …e questo, in un riassunto, dove lo metto?"},
			{"chi": "w14-ottavia", "dice": "Ecco. Adesso hai fatto una domanda da narratore."},
		],
		"notizia": {"indice": 1, "chi": "w14-elmo", "dice": "La ragazzina me l'ha chiesto ieri: chi lo racconta? Ci ho pensato tutta la notte."},
		"congedo": {"chi": "w14-ottavia", "dice": "(cambia voce) «Chi va là?» …ah, sei tu. Entra, entra."},
	},
	"w14-s2": {
		"world": 14,
		"stadio": 2,
		"cast": ["w14-elmo", "w14-ottavia"],
		"scena": [
			{"chi": "w14-elmo", "dice": "Riassunto nuovo. Tre righe, e in ognuna c'è chi parla."},
			{"chi": "w14-ottavia", "dice": "(cambia voce) «Guardate! Il vecchio Elmo ha scoperto il punto di vista!»"},
			{"chi": "w14-elmo", "dice": "(taglia l'aria) Basta così."},
			{"chi": "w14-ottavia", "dice": "No, dai, è una bella notizia. Rileggilo."},
			{"chi": "w14-elmo", "dice": "…«il ponte crolla, e ognuno dei tre pensa che sia colpa sua». Ecco."},
		],
		"notizia": {"indice": 4, "chi": "w14-ottavia", "dice": "(cambia voce) «Merito mio!» No: della ragazzina. Gli ha chiesto in che punto il testimone cambia idea."},
		"congedo": {"chi": "w14-elmo", "dice": "(taglia l'aria) Sei arrivata. Siediti: c'è una cosa che ho capito tardi e voglio dirla bene."},
	},
	"w15-s0": {
		"world": 15,
		"stadio": 0,
		"cast": ["w15-gru", "w15-pila"],
		"scena": [
			{"chi": "w15-gru", "dice": "(dà un colpetto alla macchina) Ecco, riparte. Sfortuna."},
			{"chi": "w15-pila", "dice": "E quando è successo?"},
			{"chi": "w15-gru", "dice": "Adesso. Che domanda è?"},
			{"chi": "w15-pila", "dice": "È una domanda importante. Io le scrivo tutte, le ore."},
		],
		"notizia": {"indice": 3, "chi": "w15-pila", "dice": "E quando è successo? Alle undici, dice la ragazzina. Come martedì scorso, e come quello prima."},
		"congedo": {"chi": "w15-gru", "dice": "(colpetto al banco) Oh, sei qui! Guarda che macchina testarda mi tocca."},
	},
	"w15-s1": {
		"world": 15,
		"stadio": 1,
		"cast": ["w15-gru", "w15-pila"],
		"scena": [
			{"chi": "w15-pila", "dice": "Guarda il quaderno. Martedì, martedì, martedì."},
			{"chi": "w15-gru", "dice": "(colpetto alla pagina) …tre martedì."},
			{"chi": "w15-pila", "dice": "Cinque. E quando è successo il quinto? Stamattina."},
			{"chi": "w15-gru", "dice": "Allora non è sfortuna. La sfortuna non guarda il calendario."},
			{"chi": "w15-pila", "dice": "Ecco. È quello che dico da un anno e nessuno mi ascolta."},
		],
		"notizia": {"indice": 4, "chi": "w15-gru", "dice": "La ragazzina ha letto il quaderno di Pila prima di me. (colpetto) Un anno che ce l'avevo sotto il naso."},
		"congedo": {"chi": "w15-pila", "dice": "Sei tu! E quando è successo che sei arrivata? Devo scriverlo."},
	},
	"w15-s2": {
		"world": 15,
		"stadio": 2,
		"cast": ["w15-gru", "w15-pila"],
		"scena": [
			{"chi": "w15-gru", "dice": "Martedì è il giorno in cui lavano i condotti. Entra umidità."},
			{"chi": "w15-pila", "dice": "E quando è successo l'ultimo guasto?"},
			{"chi": "w15-gru", "dice": "Non è successo. Ho spostato il lavaggio al giovedì."},
			{"chi": "w15-pila", "dice": "…allora il mio quaderno serve davvero."},
			{"chi": "w15-gru", "dice": "(colpetto affettuoso al quaderno) Serve più di me, direi."},
		],
		"notizia": {"indice": 2, "chi": "w15-pila", "dice": "E quando è successo il cambiamento? Da quando la ragazzina ha detto a Gru di leggere invece di picchiare."},
		"congedo": {"chi": "w15-gru", "dice": "(colpetto alla macchina) Arrivi giusta! Guarda: due settimane senza un guasto."},
	},
	"w16-s0": {
		"world": 16,
		"stadio": 0,
		"cast": ["w16-talia", "w16-marco"],
		"scena": [
			{"chi": "w16-talia", "dice": "Scusa. Ho tradotto «in bocca al lupo» parola per parola."},
			{"chi": "w16-marco", "dice": "E che è successo?"},
			{"chi": "w16-talia", "dice": "L'ambasciatore ha chiesto di che lupo si trattava. Scusa, davvero."},
			{"chi": "w16-marco", "dice": "(conta sulle dita) Io in sei lingue non ho mai nominato un lupo. Cinque. Sette."},
		],
		"notizia": {"indice": 1, "chi": "w16-marco", "dice": "Dicono che la ragazzina abbia trovato la frase giusta senza tradurre le parole. Chissà in quante lingue si può fare."},
		"congedo": {"chi": "w16-talia", "dice": "Oh, scusa, non ti avevo vista. Scusa. Entra pure."},
	},
	"w16-s1": {
		"world": 16,
		"stadio": 1,
		"cast": ["w16-talia", "w16-marco"],
		"scena": [
			{"chi": "w16-marco", "dice": "Talia. Come si dice «affare fatto» al valico?"},
			{"chi": "w16-talia", "dice": "Alla lettera sarebbe «affare compiuto». Ma nessuno lo dice, scusa."},
			{"chi": "w16-marco", "dice": "E allora cosa dicono?"},
			{"chi": "w16-talia", "dice": "Si stringono la mano e dicono «bevuto». Perché si beve sopra l'accordo."},
			{"chi": "w16-marco", "dice": "(conta sulle dita) Sei lingue e non lo sapevo. Sette. Comunque non lo sapevo."},
		],
		"notizia": {"indice": 3, "chi": "w16-talia", "dice": "Scusa, ma devo dirlo: la ragazzina l'ha capito guardando cosa facevano, non cosa dicevano."},
		"congedo": {"chi": "w16-marco", "dice": "Ehi! (conta sulle dita) Arrivi in tempo per la lingua numero otto. O sei."},
	},
	"w16-s2": {
		"world": 16,
		"stadio": 2,
		"cast": ["w16-talia", "w16-marco"],
		"scena": [
			{"chi": "w16-talia", "dice": "Ho riscritto il contratto. Le due colonne dicono la stessa cosa. Scusa se ci ho messo tre giorni."},
			{"chi": "w16-marco", "dice": "Tre giorni! (conta sulle dita) In tre giorni io imparo due lingue e mezza."},
			{"chi": "w16-talia", "dice": "E firmi contratti che non capisci."},
			{"chi": "w16-marco", "dice": "…giusto. Ecco perché stavolta l'ho fatto leggere a te."},
			{"chi": "w16-talia", "dice": "Grazie. Scusa. Cioè: grazie."},
		],
		"notizia": {"indice": 2, "chi": "w16-marco", "dice": "La ragazzina gli ha detto di guardare la clausola in tutte e due le lingue. (conta sulle dita) Una cosa da nove lingue."},
		"congedo": {"chi": "w16-talia", "dice": "Sei arrivata! Scusa il disordine. Guarda: due colonne che finalmente dicono la stessa cosa."},
	},
	"w17-s0": {
		"world": 17,
		"stadio": 0,
		"cast": ["w17-nerea", "w17-coral"],
		"scena": [
			{"chi": "w17-nerea", "dice": "(trattiene il fiato) Sono scesa a diciotto. Il corpo reggeva."},
			{"chi": "w17-coral", "dice": "Il corpo regge finché non regge più. Poi non te lo dice in anticipo."},
			{"chi": "w17-nerea", "dice": "Tu hai smesso, Coral."},
			{"chi": "w17-coral", "dice": "Ho smesso di scendere. Non di fare i numeri."},
		],
		"notizia": {"indice": 3, "chi": "w17-coral", "dice": "Quei numeri lì la ragazzina se li è letti tutti. Quattro quaderni. Non li aveva aperti mai nessuno."},
		"congedo": {"chi": "w17-nerea", "dice": "(riprende fiato) Ah, ci sei. Vieni: si discute di quanto si può stare sotto."},
	},
	"w17-s1": {
		"world": 17,
		"stadio": 1,
		"cast": ["w17-nerea", "w17-coral"],
		"scena": [
			{"chi": "w17-coral", "dice": "Diciotto metri, due minuti. Sai quanta sosta ti serve?"},
			{"chi": "w17-nerea", "dice": "(trattiene il fiato) …non lo so."},
			{"chi": "w17-coral", "dice": "Sta scritto. Terzo quaderno, pagina undici. Numeri, non opinioni."},
			{"chi": "w17-nerea", "dice": "Se lo leggo, vuol dire che il corpo non basta."},
			{"chi": "w17-coral", "dice": "Il corpo ti porta giù. I numeri ti riportano su."},
		],
		"notizia": {"indice": 2, "chi": "w17-coral", "dice": "La ragazzina ha rifatto il conto della sosta e le è tornato uguale al mio. Numeri di trent'anni fa."},
		"congedo": {"chi": "w17-coral", "dice": "C'è qualcuno lì. Avanti: se sei venuta per i numeri sei nel posto giusto."},
	},
	"w17-s2": {
		"world": 17,
		"stadio": 2,
		"cast": ["w17-nerea", "w17-coral"],
		"scena": [
			{"chi": "w17-nerea", "dice": "Ventidue metri. Sosta a sei, tre minuti."},
			{"chi": "w17-coral", "dice": "E il relitto?"},
			{"chi": "w17-nerea", "dice": "(trattiene il fiato, poi ride) L'ho toccato. E sono risalita piano."},
			{"chi": "w17-coral", "dice": "Ecco. Quei numeri servivano a questo."},
			{"chi": "w17-nerea", "dice": "Insegnamelo per bene. Voglio scendere ancora, e voglio tornare su ogni volta."},
		],
		"notizia": {"indice": 1, "chi": "w17-coral", "dice": "Gliel'ha fatto fare la ragazzina: prima il conto, poi l'acqua. Adesso Nerea legge i miei numeri prima di ogni discesa."},
		"congedo": {"chi": "w17-nerea", "dice": "(riprende fiato) Sei tu! Vieni a sentire dove sono arrivata. E come sono tornata."},
	},
	"w18-s0": {
		"world": 18,
		"stadio": 0,
		"cast": ["w18-silo", "w18-bea"],
		"scena": [
			{"chi": "w18-silo", "dice": "(a occhi chiusi) Quattro secondi di riverbero. Quattro."},
			{"chi": "w18-bea", "dice": "E tu che fai? Suoni più forte, così i quattro secondi diventano otto."},
			{"chi": "w18-silo", "dice": "Il piano qui non si sente."},
			{"chi": "w18-bea", "dice": "La navata è una ficcanaso, mica sorda."},
		],
		"notizia": {"indice": 3, "chi": "w18-bea", "dice": "La ragazzina ha cantato piano sotto il pulpito e l'ha sentita anche il fondo della navata. La ficcanaso ha fatto tutto il resto."},
		"congedo": {"chi": "w18-silo", "dice": "(apre gli occhi) C'è qualcuno in fondo. Il riverbero è cambiato. Vieni avanti."},
	},
	"w18-s1": {
		"world": 18,
		"stadio": 1,
		"cast": ["w18-silo", "w18-bea"],
		"scena": [
			{"chi": "w18-bea", "dice": "Mettiti qui. Sussurra."},
			{"chi": "w18-silo", "dice": "…mi sento in fondo alla navata. Con un filo di voce."},
			{"chi": "w18-bea", "dice": "Perché la navata te la porta lei. Non serve spingere."},
			{"chi": "w18-silo", "dice": "(conta il riverbero) Quattro secondi. E si capisce ogni parola."},
			{"chi": "w18-bea", "dice": "Se suoni forte, i quattro secondi si accavallano e diventano fango."},
		],
		"notizia": {"indice": 1, "chi": "w18-silo", "dice": "(conta il riverbero) La ragazzina è stata in fondo e mi ha detto dove le parole si impastavano. Da qui non lo sentivo."},
		"congedo": {"chi": "w18-bea", "dice": "Ehi, sei arrivata! Vieni sul punto magico, che la navata ti fa uno scherzo."},
	},
	"w18-s2": {
		"world": 18,
		"stadio": 2,
		"cast": ["w18-silo", "w18-bea"],
		"scena": [
			{"chi": "w18-silo", "dice": "Stasera accompagno una voce sola. Registro piccolo, mani leggere."},
			{"chi": "w18-bea", "dice": "E la navata?"},
			{"chi": "w18-silo", "dice": "(conta il riverbero a occhi chiusi) La navata canta con noi, se le lasciamo il posto."},
			{"chi": "w18-bea", "dice": "Guarda che io la prendo in giro da vent'anni e adesso mi tocca ringraziarla."},
			{"chi": "w18-silo", "dice": "Ringrazia la tua mappa. Io ci suono sopra da stasera."},
		],
		"notizia": {"indice": 4, "chi": "w18-bea", "dice": "La ragazzina ha preso sul serio la mia mappa dell'eco. Da allora la navata si comporta bene."},
		"congedo": {"chi": "w18-silo", "dice": "(conta il riverbero) Sei entrata. Resta: stasera si prova col piano."},
	},
	"w19-s0": {
		"world": 19,
		"stadio": 0,
		"cast": ["w19-numa", "w19-fiorina"],
		"scena": [
			{"chi": "w19-numa", "dice": "(lucida la lapide) Questa è lingua pura. Le altre sono corrotte."},
			{"chi": "w19-fiorina", "dice": "Io la chiamo «erba del sonno». È corrotta anche lei?"},
			{"chi": "w19-numa", "dice": "È un nome da contadini."},
			{"chi": "w19-fiorina", "dice": "Sarà. Però è scritto lì, sulla tua lapide, sotto la polvere."},
		],
		"notizia": {"indice": 3, "chi": "w19-fiorina", "dice": "La ragazzina ha letto quel nome sulla pietra. Io lo chiamo così da sempre e non l'avevo mai visto scritto."},
		"congedo": {"chi": "w19-numa", "dice": "(lucida la pietra) Sei arrivata. Vieni a leggere: c'è una cosa che mi dà fastidio."},
	},
	"w19-s1": {
		"world": 19,
		"stadio": 1,
		"cast": ["w19-numa", "w19-fiorina"],
		"scena": [
			{"chi": "w19-fiorina", "dice": "Numa. Questa parola sulla lapide, e la mia. Sono la stessa?"},
			{"chi": "w19-numa", "dice": "(lucida la lapide) …sono la stessa. La tua è la figlia."},
			{"chi": "w19-fiorina", "dice": "Allora io chiamo le piante con la lingua che tu chiami pura."},
			{"chi": "w19-numa", "dice": "Tu chiami le piante con quello che ne è rimasto. Che non è la stessa cosa. E non è peggio."},
			{"chi": "w19-fiorina", "dice": "Io le chiamo e basta. Non sapevo di portare niente."},
		],
		"notizia": {"indice": 1, "chi": "w19-numa", "dice": "(lucida la lapide) La ragazzina ha messo i due nomi uno accanto all'altro. Trent'anni che li avevo davanti."},
		"congedo": {"chi": "w19-fiorina", "dice": "Oh, ci sei. Vieni, che oggi chiamo le piante e Numa fa finta di non ascoltare."},
	},
	"w19-s2": {
		"world": 19,
		"stadio": 2,
		"cast": ["w19-numa", "w19-fiorina"],
		"scena": [
			{"chi": "w19-numa", "dice": "Ho datato l'iscrizione. Non è pura: è in mezzo. Come tutte."},
			{"chi": "w19-fiorina", "dice": "E la mia erba del sonno?"},
			{"chi": "w19-numa", "dice": "(lucida la lapide) Anche lei è in mezzo. Fra una nonna e la prossima."},
			{"chi": "w19-fiorina", "dice": "Allora i nomi che chiamo non me li sono inventati."},
			{"chi": "w19-numa", "dice": "Te li hanno passati. E tu li stai passando avanti senza accorgertene."},
		],
		"notizia": {"indice": 4, "chi": "w19-fiorina", "dice": "L'ha detto la ragazzina per prima: i nomi si tramandano anche quando nessuno sa di tramandarli."},
		"congedo": {"chi": "w19-numa", "dice": "(lucida la lapide) Eccoti. Siediti: ho una parola in mezzo che ti riguarda."},
	},
	"w20-s0": {
		"world": 20,
		"stadio": 0,
		"cast": ["w20-sferza", "w20-quieto"],
		"scena": [
			{"chi": "w20-sferza", "dice": "(batte le nocche sul quadro) Non legge. Alzo la potenza."},
			{"chi": "w20-quieto", "dice": "Lampo. Uno, due, tre, quattro, cinque. Tuono."},
			{"chi": "w20-sferza", "dice": "Bello. E il mio sensore?"},
			{"chi": "w20-quieto", "dice": "Bruciato, immagino. Come gli altri due, in cinque secondi."},
		],
		"notizia": {"indice": 3, "chi": "w20-quieto", "dice": "Cinque secondi, sempre. La ragazzina li ha contati con me e le tornavano gli stessi."},
		"congedo": {"chi": "w20-sferza", "dice": "(nocche sul banco) Ehi, sei tu! Vieni, che qui si brucia roba e si impara poco."},
	},
	"w20-s1": {
		"world": 20,
		"stadio": 1,
		"cast": ["w20-sferza", "w20-quieto"],
		"scena": [
			{"chi": "w20-quieto", "dice": "Sferza. Se il sensore non legge, prima di spingere, cosa controlli?"},
			{"chi": "w20-sferza", "dice": "(batte le nocche) …niente. Spingo."},
			{"chi": "w20-quieto", "dice": "Io conto i secondi prima di dire quanto è lontano il temporale. Ci metto cinque secondi in più e non brucio niente."},
			{"chi": "w20-sferza", "dice": "Cinque secondi. Detto così sembra poco."},
			{"chi": "w20-quieto", "dice": "È tutto quello che serve, di solito."},
		],
		"notizia": {"indice": 1, "chi": "w20-sferza", "dice": "(nocche sul quadro) La ragazzina ha misurato prima di toccare. Il sensore è ancora vivo, guarda."},
		"congedo": {"chi": "w20-quieto", "dice": "Uno. Due. Tre. Sei entrata al terzo secondo. Benvenuta."},
	},
	"w20-s2": {
		"world": 20,
		"stadio": 2,
		"cast": ["w20-sferza", "w20-quieto"],
		"scena": [
			{"chi": "w20-sferza", "dice": "Misuro, guardo, poi tocco. (nocche piano) E le nocche adesso sono un saluto, non un metodo."},
			{"chi": "w20-quieto", "dice": "Quanti sensori questa settimana?"},
			{"chi": "w20-sferza", "dice": "Zero. Zero bruciati."},
			{"chi": "w20-quieto", "dice": "Allora te la insegno tutta, la lettura dei lampi. Uno, due, tre secondi: tre chilometri."},
			{"chi": "w20-sferza", "dice": "Aspetta che prendo da scrivere. Non voglio perderla."},
		],
		"notizia": {"indice": 3, "chi": "w20-quieto", "dice": "È la ragazzina che ha convinto Sferza a contare i secondi. Adesso posso lasciare a qualcuno la lettura dei lampi."},
		"congedo": {"chi": "w20-sferza", "dice": "(nocche sul quadro, piano) Arrivi giusta: sto imparando a contare invece che a spingere."},
	},
	"w21-s0": {
		"world": 21,
		"stadio": 0,
		"cast": ["w21-terza", "w21-mino"],
		"scena": [
			{"chi": "w21-terza", "dice": "(allinea i fogli) Undici studi. Tutti giusti, ognuno per conto suo."},
			{"chi": "w21-mino", "dice": "Prendi il formaggio. Mio nonno il tempo lo diceva con dodici versi."},
			{"chi": "w21-terza", "dice": "Una filastrocca non è uno studio."},
			{"chi": "w21-mino", "dice": "No. Però copre tutto l'anno, e i tuoi undici studi coprono undici posti."},
		],
		"notizia": {"indice": 3, "chi": "w21-mino", "dice": "Mangia il formaggio. La ragazzina ha messo i versi di mio nonno accanto ai fogli di Terza, e qualcosa combaciava."},
		"congedo": {"chi": "w21-terza", "dice": "(batte i fogli sul tavolo) Sei qui. Bene: mi serve qualcuno che regga una filastrocca."},
	},
	"w21-s1": {
		"world": 21,
		"stadio": 1,
		"cast": ["w21-terza", "w21-mino"],
		"scena": [
			{"chi": "w21-mino", "dice": "«Se marzo ride, aprile piange.» Quest'anno marzo ha riso."},
			{"chi": "w21-terza", "dice": "E aprile?"},
			{"chi": "w21-mino", "dice": "Ha pianto. Prendi il formaggio, che poi si asciuga."},
			{"chi": "w21-terza", "dice": "(allinea i fogli) Il mio studio del versante nord dice la stessa cosa. In quattordici pagine."},
			{"chi": "w21-mino", "dice": "Il nonno ci metteva otto parole. Però il nonno non sapeva perché."},
		],
		"notizia": {"indice": 1, "chi": "w21-terza", "dice": "(allinea i fogli) La ragazzina ha chiesto se qualcuno dei miei undici posti si parlasse con gli altri. Non me l'ero mai chiesto."},
		"congedo": {"chi": "w21-mino", "dice": "Oh! Formaggio? C'è sempre formaggio. Siediti, che si parla di mesi."},
	},
	"w21-s2": {
		"world": 21,
		"stadio": 2,
		"cast": ["w21-terza", "w21-mino"],
		"scena": [
			{"chi": "w21-terza", "dice": "Il calendario di tuo nonno funziona ancora per otto mesi su dodici."},
			{"chi": "w21-mino", "dice": "E gli altri quattro?"},
			{"chi": "w21-terza", "dice": "(allinea i fogli) Slittati. Di due settimane, tutti nella stessa direzione."},
			{"chi": "w21-mino", "dice": "Allora non è che il nonno si sbagliava. È che il tempo si è spostato."},
			{"chi": "w21-terza", "dice": "Esatto. E la tua filastrocca me lo ha fatto vedere prima dei miei undici studi."},
			{"chi": "w21-mino", "dice": "Tieni il formaggio. Te lo sei guadagnato, dottoressa."},
		],
		"notizia": {"indice": 2, "chi": "w21-mino", "dice": "Prendi il formaggio. È stata la ragazzina a mettere insieme i versi e i numeri, mica noi."},
		"congedo": {"chi": "w21-terza", "dice": "(allinea i fogli) Arrivi giusta. Guarda cosa esce da una filastrocca e undici studi."},
	},
	"w22-s0": {
		"world": 22,
		"stadio": 0,
		"cast": ["w22-vesca", "w22-fondo"],
		"scena": [
			{"chi": "w22-vesca", "dice": "(annusa la parete) Cerco il più forte. In ogni caverna ce n'è uno."},
			{"chi": "w22-fondo", "dice": "Guarda il lichene."},
			{"chi": "w22-vesca", "dice": "È piccolo e non mangia nessuno."},
			{"chi": "w22-fondo", "dice": "Guarda quanto ce n'è."},
		],
		"notizia": {"indice": 3, "chi": "w22-fondo", "dice": "Guarda: la ragazzina ha contato chi mangia chi. E ha disegnato le frecce, non i nomi."},
		"congedo": {"chi": "w22-vesca", "dice": "(annusa l'aria) C'è qualcuno. Odore di fuori. Vieni, che qui si discute di forza."},
	},
	"w22-s1": {
		"world": 22,
		"stadio": 1,
		"cast": ["w22-vesca", "w22-fondo"],
		"scena": [
			{"chi": "w22-fondo", "dice": "Guarda il lichene con la lente."},
			{"chi": "w22-vesca", "dice": "(lo annusa) Sa di alga. E anche di fungo."},
			{"chi": "w22-fondo", "dice": "Perché è tutti e due."},
			{"chi": "w22-vesca", "dice": "…e allora chi dei due vince?"},
			{"chi": "w22-fondo", "dice": "Guarda meglio. Nessuno dei due, ed è per questo che sono ovunque."},
		],
		"notizia": {"indice": 1, "chi": "w22-vesca", "dice": "(annusa il campione) La ragazzina l'ha visto al microscopio prima di me: due cose che stanno insieme e nessuna comanda."},
		"congedo": {"chi": "w22-fondo", "dice": "Guarda chi c'è. (indica lo sgabello) Siediti là."},
	},
	"w22-s2": {
		"world": 22,
		"stadio": 2,
		"cast": ["w22-vesca", "w22-fondo"],
		"scena": [
			{"chi": "w22-vesca", "dice": "Non c'è un organismo dominante. C'è una rete."},
			{"chi": "w22-fondo", "dice": "Guarda dove finisce la rete."},
			{"chi": "w22-vesca", "dice": "(annusa) In fondo alla caverna. Dove c'è quella cosa incisa."},
			{"chi": "w22-fondo", "dice": "Guarda quella. È l'unica cosa qua sotto che non mangia e non viene mangiata."},
			{"chi": "w22-vesca", "dice": "Una domanda. Qualcuno ha inciso una domanda e ha aspettato."},
		],
		"notizia": {"indice": 2, "chi": "w22-fondo", "dice": "Guarda: la ragazzina l'ha letta ad alta voce. Era la prima volta in quattrocento anni."},
		"congedo": {"chi": "w22-vesca", "dice": "(annusa l'aria) Sei tu. Vieni in fondo: c'è una cosa che devi leggere."},
	},
	"w23-s0": {
		"world": 23,
		"stadio": 0,
		"cast": ["w23-cronia", "w23-ovidio"],
		"scena": [
			{"chi": "w23-cronia", "dice": "(timbra il faldone) Versione ufficiale. Le altre confondono."},
			{"chi": "w23-ovidio", "dice": "Le altre carte hanno freddo, se posso dirlo."},
			{"chi": "w23-cronia", "dice": "Le carte non hanno freddo, Ovidio."},
			{"chi": "w23-ovidio", "dice": "Allora diciamo che ce l'ho io, e che le tengo al caldo lo stesso."},
		],
		"notizia": {"indice": 3, "chi": "w23-ovidio", "dice": "Le carte lo sanno: la ragazzina ne ha lette tre versioni e non ne ha buttata nessuna."},
		"congedo": {"chi": "w23-cronia", "dice": "(timbra) C'è qualcuno. Avanti. E non toccare i faldoni sul tavolo."},
	},
	"w23-s1": {
		"world": 23,
		"stadio": 1,
		"cast": ["w23-cronia", "w23-ovidio"],
		"scena": [
			{"chi": "w23-ovidio", "dice": "Quattro secoli di vuoto. La versione ufficiale non lo spiega."},
			{"chi": "w23-cronia", "dice": "(timbra un foglio già timbrato) Lo so."},
			{"chi": "w23-ovidio", "dice": "Ho delle carte che lo coprono. Le ho copiate di nascosto, per quarant'anni."},
			{"chi": "w23-cronia", "dice": "…quarant'anni."},
			{"chi": "w23-ovidio", "dice": "Non per disobbedire. Perché sparivano, e qualcuno doveva tenerle."},
		],
		"notizia": {"indice": 1, "chi": "w23-cronia", "dice": "(timbra) La ragazzina mi ha chiesto da quale fonte lo sapessi. Non me l'aveva mai chiesto nessuno."},
		"congedo": {"chi": "w23-ovidio", "dice": "Oh, sei arrivata. Piano con la porta: le carte si spaventano."},
	},
	"w23-s2": {
		"world": 23,
		"stadio": 2,
		"cast": ["w23-cronia", "w23-ovidio"],
		"scena": [
			{"chi": "w23-cronia", "dice": "Ho aperto la cassa che avevo fatto sigillare io."},
			{"chi": "w23-ovidio", "dice": "E le carte?"},
			{"chi": "w23-cronia", "dice": "(timbra) Registrate. Tutte. Anche quelle che mi danno torto."},
			{"chi": "w23-ovidio", "dice": "Allora non era disobbedienza, la mia. Era conservazione."},
			{"chi": "w23-cronia", "dice": "Era il tuo lavoro, Ovidio. L'ho capito con quarant'anni di ritardo."},
		],
		"notizia": {"indice": 2, "chi": "w23-ovidio", "dice": "Le carte respirano meglio da quando è passata la ragazzina. Ha chiesto di vedere anche quelle scomode."},
		"congedo": {"chi": "w23-cronia", "dice": "(timbra) Sei tu. Vieni: c'è un vuoto di quattro secoli e adesso abbiamo di che riempirlo."},
	},
}

static func scene(scene_id: String) -> Dictionary:
	return (SCENES.get(scene_id, {}) as Dictionary).duplicate(true)

## La scena di un mondo per lo stadio richiesto, se esiste. Vuota vuol dire
## «Ritrovo normale», non errore.
static func scene_for(world: int, stadio: int) -> Dictionary:
	for key in SCENES.keys():
		var data := SCENES[key] as Dictionary
		if int(data.get("world", 0)) == world and int(data.get("stadio", -1)) == stadio:
			var out := data.duplicate(true)
			out["id"] = str(key)
			return out
	return {}

## Le battute nell'ordine in cui vanno recitate. Con `con_notizia` la battuta
## all'indice dichiarato viene sostituita da quella che cita il giocatore.
static func lines_of(scene_id: String, con_notizia: bool = false) -> Array:
	var data := SCENES.get(scene_id, {}) as Dictionary
	if data.is_empty():
		return []
	var lines: Array = (data.get("scena", []) as Array).duplicate(true)
	if con_notizia and data.has("notizia"):
		var news := data["notizia"] as Dictionary
		var index := int(news.get("indice", -1))
		if index >= 0 and index < lines.size():
			lines[index] = {"chi": str(news["chi"]), "dice": str(news["dice"])}
	return lines

## Quanti mondi hanno tutte e tre le scene.
static func complete_worlds() -> Array:
	var per_world: Dictionary = {}
	for key in SCENES.keys():
		var data := SCENES[key] as Dictionary
		var world := int(data.get("world", 0))
		var stages: Array = per_world.get(world, [])
		stages.append(int(data.get("stadio", -1)))
		per_world[world] = stages
	var complete: Array = []
	for world in per_world.keys():
		var stages: Array = per_world[world]
		if stages.has(0) and stages.has(1) and stages.has(2):
			complete.append(int(world))
	complete.sort()
	return complete
