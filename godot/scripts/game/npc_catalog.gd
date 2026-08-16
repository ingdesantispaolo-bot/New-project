class_name NpcCatalog
extends RefCounted

## Catalogo degli abitanti: DATI e basta. Non calcola stati, non legge il save,
## non decide chi è presente — quello è `npc_director.gd`.
##
## Cinque campi per residente, come da `docs/ABITANTI_E_LUOGHI.md` §2.1. Sono
## pochi di proposito: la varietà nasce dalla combinazione, non dalla quantità di
## testo. Il `registro` è il cuore piacevole (senza, il cast diventa una fila di
## casi clinici); la `convinzione` è il cuore didattico, ed è **un errore vero**,
## lo stesso che fa il bambino che gioca.
##
## Le battute sono raggruppate come le chiede `DialogueDirector` (§5.2): stadio,
## reazione a caldo, riempimento. Ogni battuta è un array di **1–3 schermate**,
## mai di più, una idea per schermata — e il `tic` del personaggio compare in
## almeno una riga su tre.
##
## Stato (corretto il 16 agosto 2026): **tutti i 23 mondi con residenti sono
## scritti** (46 residenti + 23 Bislacchi). Il mondo 1 resta la *fixture* usata
## da `dialogue_audit.gd` — «completo» si riferiva a quello, non al catalogo
## intero, e la nota precedente lasciava credere il contrario. Il cast è
## progettato in `ABITANTI_E_LUOGHI.md` §3, con l'implementazione di
## riferimento per `radice` e per la leggenda dell'Ingegnere in §3.2 e §2.5 —
## quest'ultima vive in `engineer_legend_catalog.gd`, non qui.

## I due residenti di un mondo hanno registri diversi e mai entrambi «solenne»;
## ogni mondo ha almeno un personaggio che fa ridere (il Bislacco basta).
const REGISTRI := [
	"curioso", "misterioso", "buffo", "divertente",
	"caloroso", "burbero", "solenne", "sognante",
]

const RESIDENTS := {
	# -- Mondo 1 · Radura Accademia · matematica ---------------------------------
	"w01-tobia": {
		"funzione": "specialista",
		"world": 1,
		"nome": "Tobia",
		"ruolo": "Contatore dei cristalli della radura",
		"registro": "burbero",
		"tic": "chiude le frasi con «…e uno»",
		"ticMarker": "e uno",
		# La convinzione è quella del bambino che non si fida delle scorciatoie:
		# se non ho toccato ogni oggetto, non l'ho contato davvero.
		"convinzione": "Contare in fretta è barare.",
		"bisogno": "Vuole sapere come fai a contare un mucchio senza saltarne nemmeno uno.",
		"arco": [
			"Conta uno per uno perché così ha sempre fatto, e non sa più perché.",
			"Ha visto Eli contare a gruppi e il numero tornava lo stesso: cerca l'inganno e non lo trova.",
			"Conta a gruppi di dieci e lo insegna a Puccio: raggruppare non salta niente, fa vedere da più lontano.",
		],
		"battute": {
			"richiesta": [
				["Il filare est non torna.", "L'ho contato tre volte e mi dà tre numeri diversi.", "Ci vai tu? Io ricomincio da capo, e uno."],
				["Al deposito da solo non ce la faccio.", "C'è un mucchio che non finisce mai. O finisce e io perdo il segno, e uno."],
				["Vai a vedere i cristalli del bordo?", "Sono quaranta. Dovrebbero essere quaranta, e uno."],
			],
			"consolazione": [
				["Neanche a te è tornato?", "Allora non ero solo io a non capire. Riproviamo insieme, e uno."],
				["Va bene così.", "Io ci ho messo quarant'anni a non capirlo. Tu ci stai mettendo un pomeriggio, e uno."],
			],
			"stadio0": [
				["Uno. Due. Tre.", "…scusa, dov'ero? Ho perso il segno.", "Devo ricominciare da capo. Uno… e uno."],
				["Quaranta cristalli. Li conto ogni mattina.", "Non chiedermi perché quaranta. Erano quaranta ieri, e uno."],
				["Tu vai di fretta, si vede.", "Qui non si va di fretta. Qui si conta.", "Uno per volta, e uno."],
			],
			"stadio1": [
				["Eli. Ti ho vista.", "Hai contato quel mucchio in tre respiri.", "Io ci metto un quarto d'ora. Come fai, e uno?"],
				["L'ho fatto come te. Ho preso i cristalli a gruppi.", "Mi sono sentito un imbroglione.", "Però il numero tornava. Tornava lo stesso, e uno."],
				["Dimmi una cosa, Eli. Se raggruppo e il numero è giusto…", "…dove sarebbe l'inganno?", "L'ho cercato tutta la notte e non l'ho trovato, e uno."],
			],
			"stadio2": [
				["Guarda qua. Dieci, dieci, dieci, dieci.", "Quaranta. In quattro colpi.", "Quarant'anni che ci mettevo un quarto d'ora, e uno."],
				["L'ho spiegato a Puccio stamattina.", "Lui li saluta a uno a uno e non vuole sentire ragioni.", "Però li ha salutati a gruppi di dieci. Ci è arrivato, e uno."],
				["Non era barare, Eli.", "Era che nessuno mi aveva mai detto che si poteva.", "Chi conta a gruppi non salta i cristalli: li guarda da più lontano, e uno."],
			],
			"reazione": [
				["L'hai risolto. Ho visto il lampo dalla radura.", "Vado a ricontare. Non perché non mi fidi…", "…perché mi piace il rumore che fa, e uno."],
				["Hai rimesso in moto l'apparato.", "Sai qual è la prima cosa che ha fatto? Ha contato.", "A gruppi. Come te, e uno."],
				["Hai portato Sesto a ripassare?", "Bene. Quel ragazzo conta peggio di me, e non credevo fosse possibile, e uno."],
			],
			"riempimento": [
				["I cristalli crescono di notte. Un pochino.", "Non abbastanza da cambiare il conto. Ma crescono, e uno."],
				["Nonna Ersilia canta mentre io conto. Mi fa perdere il segno.", "Non glielo dico. Canta bene, e uno."],
				["Sul mio bastone c'è una tacca per ogni mattina.", "Ho smesso di contarle da un pezzo.", "Ecco, quella l'ho persa adesso, e uno."],
			],
		},
	},
	"w01-ersilia": {
		"funzione": "testimone",
		"world": 1,
		"nome": "Nonna Ersilia",
		"ruolo": "Fornaia della radura, custode della conta",
		"registro": "caloroso",
		"tic": "chiama Eli «cuore» e le mette sempre in mano qualcosa da mangiare",
		"ticMarker": "cuore",
		# La testimone «sa senza sapere di sapere»: la sua conta È la tabellina
		# del sette, e lei la canta da sessant'anni senza averlo mai visto.
		"convinzione": "La mia conta è una canzone, mica un conto.",
		"bisogno": "Vuole capire perché quelle tre sillabe senza senso vadano cantate uguali.",
		"arco": [
			"Canta la conta come gliel'ha insegnata sua nonna, senza chiedersi cosa dica.",
			"Si accorge che i numeri della conta salgono sempre di sette e resta senza parole.",
			"Insegna la conta a Tobia come metodo, e si chiede cos'altro sta cantando senza saperlo.",
		],
		"battute": {
			"richiesta": [
				["Cuore, mi aiuti con una cosa?", "C'è un pezzo della conta che non mi torna più. Vieni a sentirlo."],
				["Tieni, mangia mentre cammini.", "E già che ci sei, cuore, dai un'occhiata alla Rovina: là dentro c'è qualcosa che somiglia alla mia canzone."],
				["Se passi dalla Rovina, guarda le tacche sul bastone.", "Sono a gruppi, cuore. Come la mia conta. Non mi dà pace."],
			],
			"consolazione": [
				["Vieni qui, cuore. Siediti.", "Prima si mangia. Poi, se ti va, ci riproviamo insieme."],
				["Pazienza, cuore.", "La mia conta l'ho cantata sessant'anni prima di capirla, cuore."],
			],
			"stadio0": [
				["Vieni qui, cuore. Hai la faccia di chi non ha fatto colazione.", "Tieni. Pane con i semi di girasole."],
				["Sette scalini per salir, quattordici per non finir…", "…scusa cuore, canticchio sempre. È una conta di quando ero piccola."],
				["La conta me l'ha insegnata mia nonna, e a lei la sua.", "Non vuol dire niente, cuore. È solo una canzone."],
			],
			"stadio1": [
				["Eli, tu che studi. Ascolta un momento.", "Ventuno, ventotto, trentacinque…", "Salgono sempre di sette. Tu l'avevi notato, cuore? Io mai."],
				["Ho cantato quella conta per sessant'anni.", "E per sessant'anni era una tabellina.", "Tieni, prendi una focaccia. Sono agitata."],
				["C'è un pezzo che non ho mai capito, cuore.", "In fondo ci sono tre sillabe che non sono parole: «sca», «la», «re».", "Mia nonna diceva di cantarle uguali. Che era importante."],
			],
			"stadio2": [
				["Allora la mia canzone era matematica, cuore.", "E io che credevo di non saperne niente."],
				["Gliel'ho insegnata a Tobia, la conta.", "Adesso conta a tempo di musica e va il doppio più svelto.", "Tieni, portagli questa: si dimentica di mangiare."],
				["Se una filastrocca può nascondere una tabellina per sessant'anni…", "…chissà cos'altro sto cantando senza saperlo, cuore."],
			],
			"reazione": [
				["Ho sentito il fragore. Sei stata tu, cuore?", "Siediti. Prima si mangia, poi si festeggia."],
				["Tobia è passato di corsa. Di corsa, capisci?", "Quell'uomo non correva dal Silenzio.", "Tieni, cuore, due focacce: una è per lui."],
				["L'apparato canta di nuovo.", "Ha la stessa nota della mia conta. Sarà un caso, cuore?"],
			],
			"riempimento": [
				["Quarantanove — sca — cinquantasei — la — sessantatré — re —", "…settanta, e chi conta se ne va.", "Bella, vero cuore?"],
				["Il forno è caldo. Il forno è sempre caldo.", "Passa quando vuoi, cuore."],
				["Mia nonna diceva che la conta serviva a non perdere qualcuno.", "Non ho mai capito chi intendesse. Tieni, mangia."],
			],
		},
	},
	"w02-corinna": {
		"funzione": "specialista",
		"world": 2,
		"nome": "Corinna",
		"ruolo": "Archivista dell'Archivio delle Parole",
		"registro": "solenne",
		"tic": "misura ogni cosa con le dita",
		"ticMarker": "dita",
		"convinzione": "L'ordine giusto è quello che si vede.",
		"bisogno": "Vuole sapere con quale criterio ordinare un catalogo, se non per lunghezza.",
		"arco": [
			"Ordina le parole dalla più corta alla più lunga, perché è l'unico ordine che si può controllare a occhio.",
			"Vede Eli trovare una parola in un attimo cercandola per funzione, e non riesce a spiegarsi come.",
			"Riordina l'Archivio per funzione e ammette che l'ordine non si trova: si sceglie.",
		],
		"battute": {
			"richiesta": [
				["Lo scaffale nord è un disastro.", "L'ho ordinato per lunghezza, dito per dito, e nessuno trova più niente.", "Vacci tu, e dimmi con che criterio lo rimetteresti."],
				["Il catalogo delle voci brevi va verificato.", "Sono duecento schede e le ho misurate tutte con le dita.", "Duecento volte. Voglio sapere se è servito a qualcosa."],
				["Una cassa di schede giace lì da anni, non classificata.", "Io non so da che parte prenderla: non hanno lunghezza uguale né simile.", "Prendile tu. Poi mi spieghi l'ordine che ne è uscito."],
			],
			"consolazione": [
				["Bene così.", "Un catalogo sbagliato al primo tentativo è ancora un catalogo: si riordina.", "Ricominciamo dalla prima scheda."],
				["Ho misurato per vent'anni la cosa sbagliata, con queste dita.", "Tu ci hai messo un pomeriggio a scoprire che era sbagliata.", "Non chiamarlo fallimento davanti a me."],
			],
			"stadio0": [
				["Undici lettere. Questa va nel settore undici.", "Misuro con le dita: tre dita e mezzo.", "L'ordine è ordine perché si vede."],
				["Non toccare gli scaffali. Sono ordinati.", "Dalla più corta alla più lunga, senza eccezioni."],
				["«Casa» sta accanto a «gara». Quattro lettere entrambe.", "Che non c'entrino niente l'una con l'altra non è un mio problema: io misuro con le dita, non giudico."],
			],
			"stadio1": [
				["Eli. Tu quella parola l'hai trovata in tre respiri.", "Io ci avrei messo mezza giornata a misurare scaffale per scaffale.", "Come sapevi dove guardare?"],
				["Li ho messi insieme, i verbi. Tutti quanti.", "Le mie dita non servivano a niente: sono lunghi diversi.", "Eppure li ritrovavo. Li ritrovavo subito."],
				["Se ordino per quello che le parole *fanno*…", "…non lo posso più controllare con le dita.", "E allora su cosa mi baso? Dimmelo tu, che io non dormo."],
			],
			"stadio2": [
				["Guarda l'Archivio adesso. Nomi, verbi, aggettivi.", "Le dita non mi servono più: mi serve sapere cosa fa una parola nella frase."],
				["Bruno viene a cercare le parole da solo, ora.", "Prima si perdeva. Non perché fosse piccolo: perché il mio ordine non voleva dire niente."],
				["Un ordine si sceglie in base alla domanda che farai.", "Per lunghezza, se cerchi una rima. Per funzione, se cerchi un senso.", "Ho misurato con le dita per vent'anni la domanda sbagliata."],
			],
			"reazione": [
				["L'apparato si è rimesso a catalogare.", "E cataloga per funzione. Da solo.", "Chi l'ha costruito lo sapeva già, e io ci ho messo vent'anni."],
				["Hai chiuso la missione dell'Archivio.", "Ho segnato l'ora sul registro. Con le dita, per abitudine."],
				["Ti ho vista aiutare Bruno.", "Non sgridarlo è già metà del lavoro. L'altra metà è ascoltarlo."],
			],
			"riempimento": [
				["Nell'Archivio ci sono parole che nessuno usa più.", "Le tengo lo stesso. Una parola che perdi non torna."],
				["Tre dita e mezzo. Sempre tre dita e mezzo.", "Ho le mani piccole: per me tutte le parole sono lunghe."],
				["Ditino continua a chiedermi in che settore va la sua parola.", "Non posso saperlo: non me la vuole dire."],
			],
		},
	},
	"w02-bruno": {
		"funzione": "testimone",
		"world": 2,
		"nome": "Bruno",
		"ruolo": "Bambino dell'Archivio, inventore di parole",
		"registro": "curioso",
		"tic": "chiede «e questa come la chiami?»",
		"ticMarker": "come la chiami",
		"convinzione": "Le parole che invento sono sbagliate, perché me lo dicono tutti.",
		"bisogno": "Vuole sapere se una parola inventata può diventare vera.",
		"arco": [
			"Inventa parole di continuo e ogni volta viene sgridato, quindi le nasconde.",
			"Scopre che parole normalissime sono state inventate da qualcuno, una volta.",
			"Propone una parola all'Archivio e Corinna la cataloga sul serio.",
		],
		"battute": {
			"richiesta": [
				["Nell'Archivio vecchio c'è una parete di parole che non ho mai sentito.", "E questa come la chiami, una parete che parla?", "Vacci. Se ne capisci una, torna a dirmela."],
				["Su una porta hanno scritto tre parole storte.", "Sembrano inventate, come le mie. Ma sono incise nella pietra.", "E questa come la chiami, una parola inventata da qualcuno che è morto?"],
				["La Rovina ha un elenco che finisce a metà.", "Io l'ho letto e mi è venuto da ridere e poi da piangere.", "Vallo a leggere e dimmi se ho capito bene."],
			],
			"consolazione": [
				["Vabbè!", "A me le parole escono storte otto volte su dieci. E questa come la chiami, se non allenamento?"],
				["Aspetta, resta un attimo.", "Anche i grandi sbagliano e nessuno glielo dice. Io lo dico a te: si riprova."],
			],
			"stadio0": [
				["Ho fatto una cosa che gira e fischia.", "E questa come la chiami? Io la chiamo «friscolo».", "…non dirlo a Corinna."],
				["Mi sgridano sempre.", "Dicono che le parole giuste esistono già e le altre no."],
				["Quel rumore che fa la pioggia sulle foglie larghe.", "Ha un nome? E se non ce l'ha, come la chiami?"],
			],
			"stadio1": [
				["Eli, senti questa. «Ombrello».", "Vuol dire piccola ombra. Qualcuno l'ha inventata.", "Qualcuno l'ha inventata e non l'hanno sgridato!"],
				["Ma allora chi decide quando una parola è vera?", "E questa come la chiami, una parola che sta diventando vera adesso?"],
				["Corinna dice che le parole nuove nascono da parole vecchie.", "Quindi «friscolo» viene da fischiare?", "Allora non me lo sono inventato del tutto."],
			],
			"stadio2": [
				["Corinna ha catalogato «friscolo».", "Settore dei nomi. Con la definizione. Scritta da me."],
				["Ho capito una cosa: una parola diventa vera quando serve a qualcuno.", "Se serve solo a me, è un gioco. E va bene lo stesso."],
				["Sto insegnando a Ditino a scrivere la sua parola prima di dimenticarla.", "E questa come la chiami, una parola che esiste solo in un foglio? Io la chiamo salvata."],
			],
			"reazione": [
				["Sei stata tu a far ripartire l'apparato?", "Ha detto una parola che non conoscevo. L'ho scritta.", "E questa come la chiami? Io per adesso la chiamo «mia»."],
				["La missione dell'Archivio è chiusa!", "Corinna ha sorriso. Non l'avevo mai vista farlo, giuro."],
				["Hai portato Sesto a ripassare. Bravo Sesto.", "Anche lui inventa parole, ma per sbaglio."],
			],
			"riempimento": [
				["Le parole più belle sono quelle lunghe che non stanno in bocca.", "«Strapiombante». E questa come la chiami se non bella?"],
				["Ho un quaderno con centosette parole mie.", "Centoquattro non ricordo più cosa vogliono dire."],
				["Se una cosa non ha un nome, esiste lo stesso?", "Io dico di sì. Ma con il nome esiste meglio."],
			],
		},
	},
	"w03-ruggine": {
		"funzione": "specialista",
		"world": 3,
		"nome": "Ruggine",
		"ruolo": "Meccanica del Cratere Logico",
		"registro": "burbero",
		"tic": "soffia sugli attrezzi prima di usarli",
		"ticMarker": "soffia",
		"convinzione": "I cicli sono per i pigri.",
		"bisogno": "Vuole capire perché la macchina dei Primi facesse in un giro quello che a lei costa cento.",
		"arco": [
			"Riavvia la macchina a mano a ogni giro, cento volte al giorno, e ne è fiera.",
			"Vede il ciclo fare cento giri senza sbagliarne uno e non riesce a chiamarlo pigrizia.",
			"Scrive il ciclo, e usa il tempo risparmiato per aggiustare quello che nessuno aggiustava.",
		],
		"battute": {
			"richiesta": [
				["(soffia sulla chiave inglese) La pompa del cratere.", "Cento colpi di manovella per un giro d'acqua. Cento.", "Vai a vederla e dimmi se c'è un modo che non sia cento."],
				["Il braccio meccanico vuole due occhi che non siano i miei.", "Ripete lo stesso gesto e io ho scritto lo stesso comando quaranta volte.", "Quaranta righe uguali. Anche a te sembra una cosa da persone serie?"],
				["(soffia sulle dita) Il nastro della macina si è inceppato.", "Ho contato: si inceppa sempre al dodicesimo passaggio.", "Va' a vedere cosa succede al dodicesimo."],
			],
			"consolazione": [
				["Non ha girato. Succede.", "(soffia) Ho passato tre inverni su una pompa che poi era montata al contrario.", "Tre inverni. Tu hai un pomeriggio, sei in anticipo."],
				["Ferma. Non toccare niente e respira.", "Le macchine non ce l'hanno con te. Aspettano solo che si riprovi."],
			],
			"stadio0": [
				["(soffia sulla chiave inglese) Cento giri, cento volte la mano.", "Chi lascia fare alla macchina non sa cosa sta facendo."],
				["Il mio maestro riavviava a mano. Suo padre pure.", "(soffia sulla leva) Si fa così e basta."],
				["Ti sembro lenta? Sono precisa.", "Sono due cose diverse, ragazzina."],
			],
			"stadio1": [
				["Eli. Quella tua istruzione ha fatto cento giri.", "(soffia sul quadrante) Cento, e non ne ha sbagliato uno.", "Io al settantesimo perdo il conto. Sempre."],
				["Ho contato gli errori miei di ieri. Quattro.", "La macchina con il tuo ciclo: zero.", "Non mi va giù, ma zero è zero."],
				["Se scrivo l'istruzione una volta e lei la ripete…", "…il lavoro l'ho fatto io o l'ho fatto lei?", "(soffia) Non è una domanda oziosa, per me."],
			],
			"stadio2": [
				["Il ciclo gira. Io intanto ho rifatto i cuscinetti.", "(soffia sui cuscinetti nuovi) Sei mesi che volevo farlo."],
				["Ripetere non è fatica. Ripetere è un'istruzione.", "L'ho scritto sul muro dell'officina, così me lo ricordo."],
				["Ho insegnato il ciclo a Manetta.", "Adesso dà istruzioni precise a una macchina spenta. Ma le dà bene."],
			],
			"reazione": [
				["L'apparato è ripartito. (soffia) L'ho sentito dal fondo del cratere.", "Fa un rumore pulito. Non lo faceva nemmeno da nuovo, scommetto."],
				["Chiuso. (soffia sulla chiave) Bene.", "(soffia sugli attrezzi) Non aspettarti che ti ringrazi due volte."],
				["Sesto è tornato in sé.", "Gli ho dato una chiave inglese. Adesso soffia anche lui. Contagioso."],
			],
			"riempimento": [
				["Questo cratere era una fabbrica. Si vede dai binari.", "(soffia sul binario) Sotto la ruggine il metallo è perfetto."],
				["La macchina grande non la tocco. Quella è dei Primi.", "Si guarda e si impara, non si smonta."],
				["(soffia sulla lima) Gli attrezzi puliti durano il doppio.", "Non è superstizione. È polvere in meno."],
			],
		},
	},
	"w03-sesto": {
		"funzione": "testimone",
		"world": 3,
		"nome": "Sesto",
		"ruolo": "Sbiadito che nel Cratere torna sé stesso",
		"registro": "buffo",
		"tic": "si presenta ogni volta da capo",
		"ticMarker": "piacere",
		"convinzione": "Se non me lo ricordo, vuol dire che non l'ho mai saputo.",
		"bisogno": "Vuole ritrovare una cosa che sapeva fare e non ricorda quale fosse.",
		"arco": [
			"Ripete gesti che non gli appartengono più e si ripresenta a ogni frase.",
			"Ricorda un pezzo — le mani sanno una cosa che la testa ha perso.",
			"Ha ritrovato il suo mestiere e ti segue per ripassarlo insieme.",
		],
		"battute": {
			"richiesta": [
				["Piacere, Sesto. Ci siamo già presentati? Non importa.", "Nella Rovina c'è una sala dove mi ricordo tutto. Tutto, capisci?", "Vieni con me. Anzi, vacci tu e poi raccontamelo, che io me lo scordo."],
				["Piacere! Senti una cosa.", "Là dentro c'è una macchina che ripete un gesto, e io so finire quel gesto.", "Io. Non so come. Va' a guardarla e dimmi cosa fa."],
				["Su un pannello dei segni si ripetono a gruppi.", "Io li guardo e mi vengono le lacrime, e non so perché.", "Piacere, comunque. Vacci tu, che ti reggi meglio."],
			],
			"consolazione": [
				["Piacere, Sest— ah, sì, ci conosciamo.", "Vedi? Anche io sbaglio ogni cinque minuti. Poi ricomincio da capo e non è mica una tragedia."],
				["Beh.", "Io ho dimenticato una cosa che sapevo fare benissimo. Tu la stai imparando adesso. Siamo pari, quasi."],
			],
			"stadio0": [
				["Sesto. Piacere.", "…te l'ho già detto, vero?", "Lo faccio sempre. Sesto. Piacere."],
				["Stavo facendo una cosa. Con le mani.", "Adesso non c'è più la cosa e non ci sono più le mani. Cioè, le mani ci sono."],
				["Sesto. Piacere.", "Ho la sensazione di conoscerti da prima di adesso."],
			],
			"stadio1": [
				["Sesto. Pia— …ok, ci siamo già presentati due volte.", "Tre. Va bene, tre.", "Però me lo ricordo! È già qualcosa, no?"],
				["Le mie mani sanno fare una cosa che io non so.", "Guarda: fanno così. Poi così.", "Che mestiere è? Piacere, comunque. Sesto."],
				["Ruggine mi ha dato una chiave inglese e ho smesso di tremare.", "Non so perché. Ma ho smesso."],
			],
			"stadio2": [
				["Sesto. Piacere. E stavolta lo dico perché mi va, non perché l'ho scordato.", "Facevo il montatore. Al ponte grande."],
				["Vengo con te, se ti va.", "Ripassare con qualcuno è diverso che ripassare da soli. L'ho scoperto ieri."],
				["Non è che non l'avevo mai saputo.", "È che nessuno me lo chiedeva più, e le cose che nessuno ti chiede scoloriscono.", "Piacere. Sesto. Che bello dirlo sapendo chi sono."],
			],
			"reazione": [
				["Hai acceso l'apparato! L'ho visto! Io!", "Sesto, piacere — no, aspetta, quello l'ho già fatto."],
				["È finita! Ero là. Mi ricordo di esserci stato, e non mi capita spesso.", "Mi ricordo, capisci? Piacere, comunque."],
				["Mi hai portato a ripassare.", "Non ho capito tutto. Ma ho capito più di ieri, e ieri più di prima."],
			],
			"riempimento": [
				["Sesto. Piacere.", "Ho detto una cosa buffa prima? La gente rideva.", "Non ricordo cos'era. Peccato, doveva essere ottima."],
				["Il cratere di notte fa eco.", "Ho gridato il mio nome per sentirmelo tornare indietro. Sesto!"],
				["Ruggine soffia sugli attrezzi. Io soffio sulle mani.", "Non serve a niente ma ci sentiamo colleghi."],
			],
		},
	},
	"w04-marea": {
		"funzione": "specialista",
		"world": 4,
		"nome": "Marea",
		"ruolo": "Radiotelegrafista della Baia dei Segnali",
		"registro": "sognante",
		"tic": "sussurra la frase a sé stessa prima di dirla",
		"ticMarker": "sussurr",
		"convinzione": "Capire è tradurre parola per parola.",
		"bisogno": "Vuole smettere di avere paura dei messaggi che non tornano parola per parola.",
		"arco": [
			"Ripete i messaggi lettera per lettera senza capirli, perché sbagliare le fa più paura di non capire.",
			"Trova un messaggio che parola per parola non vuol dire niente, e tutto insieme sì.",
			"Traduce il senso e non le parole, e per la prima volta risponde a una radio invece di ripeterla.",
		],
		"battute": {
			"richiesta": [
				["(sussurra) Ho un messaggio dal largo che non torna.", "Parola per parola è italiano, e insieme non vuol dire niente.", "Vieni a sentirlo con me?"],
				["La stazione del faro trasmette da tre giorni.", "Io sussurro le frasi prima di scriverle, e queste in bocca mi si rompono.", "Prova tu a rispondere. Io ho paura di sbagliare."],
				["(sussurra la frase due volte) «It's raining cats and dogs».", "Cani e gatti. Dal cielo. Capisci il problema?", "Va' al molo e chiedi a Lino cosa vuol dire davvero."],
			],
			"consolazione": [
				["(sussurra) Va bene. Va bene lo stesso.", "Anche i messaggi veri arrivano rotti, e si chiede di ripetere. Non è una vergogna: è la procedura."],
				["Vieni, sediamoci un momento sul molo.", "Io ho passato un anno a tradurre parola per parola. Tu ci hai messo un giorno a capire che non basta."],
			],
			"stadio0": [
				["(sussurra) …look forward… guardare avanti…", "Guardare avanti al viaggio. Non ha senso, ma è quello che c'è scritto."],
				["Io i messaggi li passo esatti. Parola per parola.", "Se poi non si capiscono, non è colpa mia."],
				["(sussurra la frase due volte prima di dirtela) Scusa. Lo faccio sempre.", "Se la dico senza averla sussurrata, mi si impasta."],
			],
			"stadio1": [
				["Eli, guarda questo. «It's raining cats and dogs».", "(sussurra) Piovono gatti e cani…", "Parola per parola è una sciocchezza. Ma il marinaio rideva. Perché rideva?"],
				["(sussurra) Me lo sono chiesta: cosa VOLEVA dire, invece di cosa diceva.", "(sussurra) Mi è sembrato di barare. Poi il messaggio aveva senso."],
				["Se traduco il senso e non le parole, chi mi dice che non sto inventando?", "Ho paura di inventare. È la mia paura, quella."],
			],
			"stadio2": [
				["(sussurra) …non vedo l'ora del viaggio.", "Ecco cosa voleva dire. Ci ho messo sei anni."],
				["Oggi ho risposto a una radio. Non ripetuto: risposto.", "Ho detto una cosa mia, in inglese, e dall'altra parte hanno capito."],
				["Le lingue non si incastrano parola su parola.", "Si toccano nel senso, e nel senso si trovano. (sussurra) Che sollievo."],
			],
			"reazione": [
				["(sussurra) È ripartito un segnale, da dentro.", "(sussurra) Era in due lingue. Le stesse parole, dette in due modi diversi."],
				["Fatto. L'ho segnata nel registro dei transiti.", "Grazie. (sussurra) Grazie davvero."],
				["Il vecchio Lino dice che parli bene.", "Da lui è un complimento enorme. Lui dice che parlano bene solo i pesci."],
			],
			"riempimento": [
				["(sussurra) Alfa. Bravo. Charlie.", "Le lettere hanno un nome perché al vento non si sentono."],
				["Di notte arrivano segnali da molto lontano.", "Alcuni non sono per noi. Li trascrivo lo stesso."],
				["Boa risponde a tutti i segnali, anche a quelli non suoi.", "(sussurra) Ogni tanto qualcuno gli risponde davvero."],
			],
		},
	},
	"w04-lino": {
		"funzione": "testimone",
		"world": 4,
		"nome": "Vecchio Lino",
		"ruolo": "Pescatore del molo, venti parole d'inglese e nessuna timidezza",
		"registro": "divertente",
		"tic": "chiama tutti «captain»",
		"ticMarker": "captain",
		"convinzione": "Per farsi capire bastano venti parole.",
		"bisogno": "Vuole scrivere una lettera a un amico oltremare, e venti parole non gli bastano più.",
		"arco": [
			"Contratta, scherza e vende pesce in inglese con venti parole, e ride di chi studia.",
			"Deve scrivere una lettera vera e scopre che le sue venti parole non dicono quello che sente.",
			"Ne ha imparate altre trenta e continua a dire che venti bastano. Per il molo.",
		],
		"battute": {
			"richiesta": [
				["Captain! Vieni qua.", "Sul relitto del faro c'è una targa in inglese che nessuno ha mai letto.", "Io ci arrivo a metà. Poi le mie venti parole finiscono."],
				["Captain, sai leggere le sigle?", "Sulla boa grande ce n'è una che i vecchi chiamavano «il saluto».", "Vacci a vedere. Poi mi dici se era un saluto o un avvertimento."],
				["Per la lettera manca ancora un pezzo, captain.", "C'è un vecchio quaderno di bordo nella Rovina, pieno di frasi fatte.", "Io ne voglio una. Una che dica «mi manchi» senza dire «mi manchi»."],
			],
			"consolazione": [
				["Ehi. Captain.", "Io parlo inglese da quarant'anni e sbaglio ancora tutti i verbi. Nessuno è mai annegato per un verbo."],
				["Niente muso lungo sul mio molo.", "Si riprova col vento di domani, captain. Il mare non tiene il punteggio."],
			],
			"stadio0": [
				["Fish! Good fish! Money?", "Visto, captain? Venduto. Tre parole."],
				["Quelli che studiano stanno lì col vocabolario mentre la barca parte.", "Io dico «fish», loro dicono «yes», affare fatto, captain."],
				["Venti parole, captain. Le ho contate.", "Con venti parole ci ho mangiato per quarant'anni."],
			],
			"stadio1": [
				["Captain, ho un problema e non è il pesce.", "Devo scrivere a un amico dall'altra parte del mare. È malato."],
				["Ci ho dato dentro con le mie venti parole, captain.", "Viene fuori: «amico. male. triste. io.»", "Non è quello che voglio dirgli, captain. Non ci somiglia nemmeno."],
				["Insegnami una parola sola, captain. Quella per dire che mi manca.", "Una parola per il molo non serve. Per una lettera sì."],
			],
			"stadio2": [
				["Cinquanta parole, captain. Le ho ricontate.", "La lettera è partita. Con dentro «I miss you» scritto giusto."],
				["Continuo a dire che venti bastano.", "Per vendere il pesce. Per il resto della vita, no."],
				["Marea non ha più paura della radio.", "Le ho detto: captain, sbaglia forte. Chi sbaglia piano non lo sente nessuno."],
			],
			"reazione": [
				["Hai svegliato quel coso, captain?", "Ha parlato in due lingue e le ho capite tutte e due. Quasi."],
				["Missione fatta! Prendi un pesce.", "No, captain, non è un modo di dire. Prendi il pesce."],
				["Ti ho vista con Sesto.", "Quel ragazzo si presenta tre volte per conversazione. Mi piace, captain."],
			],
			"riempimento": [
				["La marea sale due volte al giorno e non chiede il permesso.", "Come i clienti, captain."],
				["Captain, lo sai come si dice «tempesta» in inglese?", "Nemmeno io. Quando arriva non c'è tempo di dirlo."],
				["Il mio amico oltremare mi ha risposto.", "Tre pagine, captain. Tre. Me le sto studiando una riga al giorno."],
			],
		},
	},
	"w05-gerbo": {
		"funzione": "specialista",
		"world": 5,
		"nome": "Gerbo",
		"ruolo": "Sollevatore delle Officine del Moto",
		"registro": "burbero",
		"tic": "si sputa sulle mani prima di ogni sforzo",
		"ticMarker": "mani",
		"convinzione": "Le leve sono trucchi da deboli.",
		"bisogno": "Deve spostare il masso della chiusa e da solo non ci arriva più.",
		"arco": [
			"Solleva tutto a forza di braccia e considera ogni attrezzo una scorciatoia da furbi.",
			"Vede Tilla muovere con un palo quello che lui non muove in tre, e non sa dove sia il trucco.",
			"Usa la leva, e scopre che la forza che gli restava serviva a fare il resto.",
		],
		"battute": {
			"richiesta": [
				["Il masso della chiusa. Non si muove.", "Io ci ho messo queste mani per due giorni. Due.", "Vieni a vedere se c'è un altro modo, che io non lo trovo."],
				["(si sputa sulle mani) La trave del capannone.", "Devo alzarla da un lato solo e non ho abbastanza braccia.", "Portami qualcosa che alzi al posto mio. Se esiste."],
				["Dietro l'officina è buttata una carrucola vecchia.", "I Primi la usavano. Io non l'ho mai toccata: mi sembrava barare.", "Vacci tu. Guardala e dimmi come funziona."],
			],
			"consolazione": [
				["Non si è mosso neanche a te. Bene.", "Allora non era la forza. Era proprio la cosa. Ricominciamo da lì."],
				["(si asciuga le mani) Alzati.", "Io ho spinto per vent'anni una cosa che si spostava con un dito. Vent'anni. Tu hai sbagliato un pomeriggio."],
			],
			"stadio0": [
				["(si sputa sulle mani) Questo lo alzo io.", "Non mi servono bastoni. Mi servono braccia."],
				["Chi usa la leva sposta il peso su un legno.", "Il peso va sentito, non passato a qualcun altro."],
				["Ho le mani come il cuoio. Guarda.", "Quarant'anni di massi. Nessun trucco."],
			],
			"stadio1": [
				["Quella ragazzina ha alzato la pietra della chiusa.", "Con un palo e un sasso sotto. Lei. Da sola.", "(si sputa sulle mani) Io con due uomini non ci riesco."],
				["Il palo. L'ho messo sotto e si è alzata.", "Mi aspettavo di sentirmi debole. Mi sono sentito solo… stupito."],
				["Dov'è il trucco, Eli? Perché un trucco ci sarà.", "Il peso non sparisce. Dove va a finire?"],
			],
			"stadio2": [
				["Il peso non sparisce: si divide fra me e la distanza.", "Più lungo è il braccio, meno ne tocca a me. Non è magia, è geometria."],
				["(si sputa sulle mani per abitudine, poi ride) Non serve più, ma non riesco a smettere.", "Oggi ho spostato sei massi e mi è avanzata la giornata."],
				["Tilla aveva ragione da due anni e nessuno l'ascoltava.", "Compreso me. Soprattutto me."],
			],
			"reazione": [
				["L'apparato gira. Si sente dal ponte.", "(si sputa sulle mani) Vado a vedere se ha bisogno di braccia. Spero di no, ormai."],
				["Finito. Segnato.", "Non ti abbracci. Non lo faccio con nessuno."],
				["Hai fatto ripassare Sesto?", "Quel ragazzo ha due mani buone. Digli di venire qui, che gli insegno."],
			],
			"riempimento": [
				["Le Officine erano piene di gente, una volta.", "Adesso ci sono io e i massi. I massi parlano meno."],
				["(si sputa sulle mani) Abitudine. Lo facevo anche da bambino.", "Mio padre diceva che porta fortuna. Non ne ha portata a lui."],
				["Peso solleva cose che non vanno sollevate.", "Ieri ha sollevato una porta. Era aperta."],
			],
		},
	},
	"w05-tilla": {
		"funzione": "testimone",
		"world": 5,
		"nome": "Tilla",
		"ruolo": "Bambina delle Officine, ha capito il fulcro sull'altalena",
		"registro": "curioso",
		"tic": "chiede «te lo faccio vedere?»",
		"ticMarker": "vedere",
		"convinzione": "Se nessuno mi dà retta, vuol dire che ho torto.",
		"bisogno": "Vuole che qualcuno guardi davvero la cosa che ha scoperto.",
		"arco": [
			"Sa una cosa vera e ha smesso di dirla, perché nessuno si è mai fermato ad ascoltarla.",
			"Eli si ferma a guardare, e Tilla si accorge che il metodo funzionava anche prima.",
			"Insegna la leva a Gerbo e capisce che non aveva torto: aveva solo pochi anni.",
		],
		"battute": {
			"richiesta": [
				["Te lo faccio vedere? Vieni, dai.", "Sull'altalena c'è un punto in cui sollevo mio fratello che pesa il doppio di me.", "Un punto solo. Vieni a guardare dov'è."],
				["Nella Rovina c'è un disegno di un'asse con un sasso sotto.", "È la mia altalena. Disegnata da qualcuno di mille anni fa.", "Te lo faccio vedere dove sta? Voglio che lo guardi davvero."],
				["Nel deposito è rimasta una bilancia rotta.", "Se sposto il piatto piccolo lontano, pesa come quello grande. Non è magia.", "Vacci. Poi mi dici se ho ragione io o i grandi."],
			],
			"consolazione": [
				["Non ti è venuto? Ok, ma non andare via.", "Te lo faccio vedere di nuovo, più piano. A me nessuno l'ha fatto vedere due volte."],
				["Aspetta. Non è che hai sbagliato tu.", "Forse ho spiegato male io. Riproviamo, e stavolta guardo dove ti perdi."],
			],
			"stadio0": [
				["Sull'altalena, se il grande si sposta avanti, il piccolo lo alza.", "Te lo faccio vedere?", "…lascia stare. Nessuno guarda mai."],
				["Ho detto una cosa a Gerbo e ha riso.", "Forse ho sbagliato. Di solito ho sbagliato."],
				["Te lo faccio vedere? No? Va bene.", "Va bene davvero, eh."],
			],
			"stadio1": [
				["Ti sei fermata a guardare. Nessuno si ferma.", "Allora te lo faccio vedere per bene: palo lungo, sasso vicino al masso."],
				["Funziona da due anni. Funzionava anche quando ridevano.", "Le cose funzionano lo stesso, anche se nessuno ci crede? Te lo chiedo sul serio."],
				["Se sposto il sasso più vicino al masso, faccio meno fatica.", "Te lo faccio vedere tre volte di fila, così vedi che non è fortuna."],
			],
			"stadio2": [
				["Gerbo ha usato la leva. GERBO.", "Mi ha chiesto di spiegargliela. A me. Te lo faccio vedere come gliel'ho spiegata?"],
				["Non avevo torto. Avevo nove anni.", "Sono due cose diverse e nessuno me l'aveva detto."],
				["Adesso lo insegno agli altri bambini del molo.", "Te lo faccio vedere? Abbiamo alzato una barca. Una barca vera."],
			],
			"reazione": [
				["Là dentro c'è una leva grande così! Te lo faccio vedere?", "Te lo faccio vedere sul disegno? L'ho copiato tutto."],
				["Chiusa! Ero dietro il masso a guardare.", "Guardo sempre. È così che ho imparato."],
				["Sesto mi ha chiesto di spiegargli il fulcro.", "Se l'è dimenticato subito. Gliel'ho fatto vedere di nuovo. Va bene lo stesso."],
			],
			"riempimento": [
				["L'altalena è la macchina più onesta che c'è.", "Ti dice subito se hai capito: o sali o non sali."],
				["Te lo faccio vedere un trucco? Metti il dito qui.", "Senti? Il peso è tutto lì. È sempre stato lì."],
				["Peso mi ha chiesto di allenarsi con la leva.", "Gli ho detto che la leva serve a NON allenarsi. Ci è rimasto male."],
			],
		},
	},
	"w06-ambra": {
		"funzione": "specialista",
		"world": 6,
		"nome": "Ambra",
		"ruolo": "Accordatrice del Giardino della Risonanza",
		"registro": "sognante",
		"tic": "canticchia le risposte invece di dirle",
		"ticMarker": "mmh",
		"convinzione": "Dare un nome alla musica la rovina.",
		"bisogno": "Vuole insegnare a Oreste quello che sente, e senza nomi non ci riesce.",
		"arco": [
			"Accorda a orecchio meglio di chiunque e rifiuta la teoria: i nomi le sembrano gabbie.",
			"Prova a spiegare a Oreste un intervallo e si accorge che senza un nome non può passarglielo.",
			"Usa i nomi e scopre che un suono con un nome si può regalare a qualcuno.",
		],
		"battute": {
			"richiesta": [
				["Mmh. Senti questa.", "(canticchia tre note) Adesso questa. (ne canticchia altre tre)", "La seconda ti fa la stessa cosa in pancia? A me sì, e non so dire perché."],
				["Devo insegnare una cosa a Oreste e non ho parole. Mmh.", "Nel Giardino c'è una campana che dà due suoni insieme.", "Vacci. Poi torna e prova a dirmelo tu, con le parole."],
				["Mmh… c'è una cosa che mi tormenta.", "Le corde del salice suonano bene solo a certe distanze. Sempre le stesse.", "Va' a misurarle. Io non ci riesco: appena misuro, smetto di sentire."],
			],
			"consolazione": [
				["Mmh. Non è venuta.", "Anche a me le cose non vengono: allora le canto più piano e ricomincio."],
				["Vieni, siediti sull'erba un momento.", "Mmh. Nessuno accorda uno strumento al primo tentativo. Nessuno."],
			],
			"stadio0": [
				["Mmh… senti? È calante di un soffio.", "Non chiedermi di quanto. Di un soffio."],
				["I nomi delle note me li hanno insegnati e li ho dimenticati apposta.", "Mmh… la musica è prima delle parole."],
				["Questa corda vuole scendere. Mmh.", "Come faccio a saperlo? Lo vuole e basta."],
			],
			"stadio1": [
				["Mmh. Ci ho provato, a spiegare a Oreste come sale quel suono.", "Mmh… gli ho fatto sentire con le mani. Ma sentire non è dire."],
				["Lui mi ha chiesto: «di quanto sale?»", "E io non lo so dire. Mmh. Lo so fare e non lo so dire.", "È la prima volta che mi manca una parola."],
				["Se questo intervallo avesse un nome…", "…potrei mandarlo a qualcuno che non è nella stanza. Mmh.", "Non ci avevo mai pensato."],
			],
			"stadio2": [
				["Quinta giusta. Mmh. Sette semitoni.", "L'ho detto. Non è morto niente."],
				["Ho scritto una melodia per Oreste, con i nomi.", "Lui l'ha letta con le mani prima ancora che la suonassi. Mmh."],
				["Un suono senza nome resta mio.", "Un suono con un nome posso regalarlo. Mmh… avevo paura di perderlo, e invece si moltiplica."],
			],
			"reazione": [
				["È uscita una nota, da lì dentro. Mmh… un la, credo.", "Un la vero, non un la per modo di dire. Sto imparando a dirlo."],
				["È andata. Mmh.", "Il giardino è più intonato di ieri. Non è una metafora."],
				["Hai portato Sesto a ripassare?", "Canta stonatissimo. Mmh… ma canta forte, e quello conta."],
			],
			"riempimento": [
				["Il giardino risuona da solo quando tira vento.", "Mmh… ogni pianta ha una sua altezza. Le ho accordate tutte."],
				["Mmh… scusa, canticchio anche quando ti rispondo.", "È che la frase mi arriva prima come suono che come parole."],
				["Zufolo cerca la nota che gli ha rubato il cappello.", "Non gliel'ho detto, ma quella nota esiste. Mmh. Esiste davvero."],
			],
		},
	},
	"w06-oreste": {
		"funzione": "testimone",
		"world": 6,
		"nome": "Oreste",
		"ruolo": "Liutaio sordo del Giardino, legge la musica con le mani sulle corde",
		"registro": "solenne",
		"tic": "appoggia la mano allo strumento prima di parlare",
		"ticMarker": "mano",
		"convinzione": "La musica non è per me: io la tocco soltanto.",
		"bisogno": "Vuole sapere se quello che fa con le mani ha lo stesso nome di quello che fanno gli altri con le orecchie.",
		"arco": [
			"Sente le corde con le mani e costruisce strumenti perfetti, ma non si considera un musicista.",
			"Scopre che ciò che le sue mani distinguono ha un nome, ed è lo stesso che usano gli altri.",
			"Insegna ad Ambra a leggere la musica scritta: lei la sentiva, lui la vedeva.",
		],
		"battute": {
			"richiesta": [
				["(appoggia la mano alla cassa) Senti qui. Con la mano, non con l'orecchio.", "Quando Ambra canta la nota alta, questo legno trema forte.", "Va' a vedere se anche il legno grande fa lo stesso. Io non posso spostarmi."],
				["Nella Rovina c'è uno strumento senza corde.", "Ha dei segni sul manico, a distanze che io conosco con la mano.", "Vacci. Voglio sapere se quei segni hanno un nome."],
				["(mano sullo strumento) C'è una cosa che non capisco.", "Se accorcio la corda a metà, la mano sente lo stesso tremito ma più veloce.", "Metà. Sempre metà. Va' a chiedere perché."],
			],
			"consolazione": [
				["(posa la mano sul tavolo) Fermati.", "Il legno non si spacca al primo colpo di sgorbia. Nemmeno le cose difficili."],
				["Io ho imparato tutto due volte: una sbagliata e una giusta.", "(mano sulla corda) La seconda è quella che conta. Vai."],
			],
			"stadio0": [
				["(appoggia la mano alla cassa) Questa è pronta.", "Io costruisco. Chi suona è un altro."],
				["Le vibrazioni si contano con il palmo.", "Non è musica. È legno che si comporta bene."],
				["(mano sulla tavola armonica) Sento tutto. Non ascolto niente.", "Sono due cose diverse, e la seconda non mi appartiene."],
			],
			"stadio1": [
				["Ambra mi ha chiesto quanto sale un suono.", "(mano sulla corda) Io lo so. Sale di quattro dita di tensione.", "Non sapevo che avesse un nome anche per lei."],
				["Quindi ciò che le mie mani distinguono…", "…è la stessa cosa che le sue orecchie distinguono."],
				["(mano sulla corda, a lungo) Ho sempre creduto di stare fuori.", "E invece ero dentro, con un'altra porta."],
			],
			"stadio2": [
				["(mano sulla partitura) Le note scritte si toccano meglio di quelle suonate.", "Ad Ambra sfuggivano. A me no. Gliele ho insegnate io."],
				["Sono un musicista. L'ho detto ad alta voce una volta sola.", "Poi ho appoggiato la mano allo strumento, che è il mio modo di firmare."],
				["Chi non sente non è fuori dalla musica.", "È fuori da un solo modo di riceverla. Ce ne sono altri, e nessuno me li aveva mostrati."],
			],
			"reazione": [
				["(mano sul pilastro) L'apparato vibra di nuovo.", "Nota lunga, tenuta, pulita. La sento fino ai gomiti."],
				["Hai chiuso la missione del Giardino.", "(mano sulla spalla, un istante) Grazie."],
				["È passato quel ragazzo che ricomincia da capo ogni volta.", "Gli ho fatto toccare una corda grave. È rimasto zitto per un minuto intero."],
			],
			"riempimento": [
				["(mano sul legno stagionato) Questo abete ha aspettato trent'anni.", "Gli strumenti buoni sono fatti di pazienza, prima che di legno."],
				["Non ho mai sentito la mia voce.", "(mano sulla gola) La sento così. Basta e avanza."],
				["Ambra canticchia mentre lavora. Lo vedo dal tremito del banco.", "(mano sul banco) È un bel tremito."],
			],
		},
	},
	"w07-livia": {
		"funzione": "specialista",
		"world": 7,
		"nome": "Livia",
		"ruolo": "Prima copista delle Rovine dei Glifi",
		"registro": "solenne",
		"tic": "soffia sull'inchiostro fresco",
		"ticMarker": "inchiostro",
		"convinzione": "Copiare bene è già capire.",
		"bisogno": "Vuole sapere perché nessuno si accorga degli errori che copia alla perfezione.",
		"arco": [
			"Riproduce ogni glifo con esattezza assoluta senza leggere una sola parola.",
			"Copia un errore dei Primi identico, e solo Zeno se ne accorge: la sua perfezione ha tramandato uno sbaglio.",
			"Legge mentre copia, e in una settimana trova tre errori che quattro secoli avevano ricopiato.",
		],
		"battute": {
			"richiesta": [
				["(soffia sull'inchiostro) Ho copiato questa tavola alla perfezione.", "Ogni segno al suo posto. E il senso non c'è.", "Vieni a guardarla con me: forse l'errore non è mio, è di chi ha scritto."],
				["La tavola quarta va collazionata.", "Ne esistono due copie e differiscono in un punto solo.", "Va' a leggerle. Poi dimmi quale delle due ha senso, non quale è più bella."],
				["Nella sala bassa c'è un'iscrizione che ho rifiutato di copiare.", "(soffia sull'inchiostro) Ha una parola che non esiste in nessun lessico.", "Vacci tu. Io ho paura di trascriverla e renderla vera."],
			],
			"consolazione": [
				["Ferma la mano. Non strappare il foglio.", "Un errore di copia si vede, e ciò che si vede si corregge. Ricominciamo dal rigo."],
				["(soffia sull'inchiostro fresco) Io copio da trent'anni.", "E ho scoperto oggi che copiare non è capire. Tu lo sai già, e hai un terzo dei miei anni."],
			],
			"stadio0": [
				["(soffia sull'inchiostro) Trentadue righe, nessuna sbavatura.", "Cosa dicono non è compito mio."],
				["Il copista che legge rallenta. Il copista che rallenta sbaglia.", "Io non sbaglio."],
				["Questa tavola l'ho riprodotta tre volte in vent'anni.", "(soffia sull'inchiostro) Identica tutte e tre."],
			],
			"stadio1": [
				["Zeno dice che nella tavola quarta c'è un errore.", "Un errore dei Primi. E io l'ho copiato tre volte.", "(soffia sull'inchiostro) Perfettamente."],
				["Se copio uno sbaglio senza accorgermene…", "…la mia precisione a cosa è servita?"],
				["Ho letto una riga. Una sola. Ci ho messo un'ora.", "(soffia sull'inchiostro) Diceva una cosa bellissima e io la copiavo da vent'anni senza saperlo."],
			],
			"stadio2": [
				["Tre errori in una settimana. Tramandati per quattro secoli.", "(soffia sull'inchiostro) Adesso copio più lenta e molto meglio."],
				["Copiare bene conserva la forma. Leggere conserva il senso.", "Servono tutte e due, e io ne facevo solo una."],
				["Insegno a Zeno la mano ferma. Lui insegna a me le radici.", "(soffia sull'inchiostro) È il baratto migliore che abbia mai fatto."],
			],
			"reazione": [
				["Una riga si è incisa da sola sulla pietra.", "(soffia sull'inchiostro per abitudine) In latino. E l'ho letta."],
				["Missione conclusa. L'ho annotata nel registro.", "Con la data e il tuo nome, che è quello che si fa con le cose che contano."],
				["Ha ripassato con te, quel ragazzo smemorato.", "Gli ho fatto copiare tre glifi. Li ha copiati bene. Non se lo ricorda."],
			],
			"riempimento": [
				["(soffia sull'inchiostro) L'inchiostro dei Primi non è mai scolorito.", "Il mio dopo trent'anni ingiallisce. Sapevano qualcosa che non so."],
				["Le rovine sono più leggibili all'alba.", "La luce radente riempie i solchi. Non è poesia, è ombra."],
				["Postilla annota le iscrizioni antiche con osservazioni sue.", "(soffia sull'inchiostro) Le cancello ogni sera. Ogni mattina ce ne sono di nuove."],
			],
		},
	},
	"w07-zeno": {
		"funzione": "testimone",
		"world": 7,
		"nome": "Zeno",
		"ruolo": "Ragazzo delle Rovine, gioca a «trova la parola parente»",
		"registro": "curioso",
		"tic": "chiede «e questa di chi è parente?»",
		"ticMarker": "parente",
		"convinzione": "Indovinare non vale: bisogna sapere.",
		"bisogno": "Vuole sapere se il suo gioco conta come studiare.",
		"arco": [
			"Indovina il senso delle parole latine per somiglianza e si vergogna perché «è solo un gioco».",
			"Scopre che le somiglianze non sono casuali: sono radici, e le radici sono un metodo.",
			"Insegna il gioco agli altri e lo chiama con il suo nome vero: etimologia.",
		],
		"battute": {
			"richiesta": [
				["Guarda questa parola sul muro. E questa di chi è parente?", "Somiglia a una che diciamo tutti i giorni, ma è vecchia di mille anni.", "Va' a vedere le altre tre sul pilastro. Facciamo la famiglia intera."],
				["Nella sala crollata c'è un elenco di nomi di mestieri.", "Ne ho riconosciuti due. Due su venti.", "Vacci tu, che sai le regole. E questa di chi è parente, poi me lo dici?"],
				["Una parola è incisa due volte, in due modi diversi.", "Stessa parola, secoli diversi. È come vedere qualcuno da bambino e da vecchio.", "Vai a guardarla. Voglio sapere quale delle due è venuta prima."],
			],
			"consolazione": [
				["Non l'hai trovata? Vabbè.", "Anch'io indovino e sbaglio. E questa di chi è parente? Non lo so mai al primo colpo."],
				["Aspetta, non scappare.", "Il gioco è bello perché a volte perdi. Rifacciamolo da un'altra parola."],
			],
			"stadio0": [
				["«Aqua». E questa di chi è parente? Di acquedotto, secondo me.", "Ma è solo un gioco mio, eh. Non conta."],
				["Livia dice che indovinare non è leggere.", "Ha ragione lei. Lei è la prima copista."],
				["Ci prendo quasi sempre. E questa di chi è parente?", "…ma se ci prendo per caso, non vale."],
			],
			"stadio1": [
				["Eli, guarda: «portare», «porto», «trasporto», «portatile».", "E questa di chi è parente? Di tutte le altre!", "Non è caso. Non può essere caso quattro volte."],
				["Se le parole hanno una famiglia…", "…allora indovinare non è tirare a caso. È seguire la parentela."],
				["Ho trovato un errore nella tavola quarta.", "Una parola non è parente di nessuna. Sta lì da sola e non ci sta bene."],
			],
			"stadio2": [
				["Si chiama etimologia. Il mio gioco ha un nome vero.", "E questa di chi è parente? Di «etimo», che vuol dire «vero». Perfino il nome fa il gioco."],
				["Livia mi insegna la mano ferma, io le insegno le radici.", "Adesso legge mentre copia. Dice che va più piano e arriva più lontano."],
				["Ho insegnato il gioco ai piccoli del villaggio.", "E questa di chi è parente? Adesso me lo chiedono loro a me."],
			],
			"reazione": [
				["È comparsa una parola che non conoscevo! E questa di chi è parente?", "Ma era parente di tre che conosco. L'ho capita lo stesso."],
				["Fatto! Ero sulle scale a guardare.", "E questa di chi è parente, la tua faccia contenta? Della mia."],
				["Sesto ha ripassato con te.", "Gli ho chiesto di chi fosse parente il suo nome. Ha detto: «di cinque e sette». Ci sta."],
			],
			"riempimento": [
				["Sulle rovine ci sono parole scritte sopra altre parole.", "E questa di chi è parente? Di quella sotto, forse."],
				["Il latino non è morto: si è sparpagliato.", "Un pezzo qui, un pezzo in spagnolo, un pezzo in francese."],
				["Postilla ha annotato una mia scoperta come sua.", "Non me la prendo. Almeno l'ha letta."],
			],
		},
	},
	"w08-ciro": {
		"funzione": "specialista",
		"world": 8,
		"nome": "Ciro",
		"ruolo": "Manutentore dei circuiti del Delta",
		"registro": "caloroso",
		"tic": "conta i nodi a voce alta",
		"ticMarker": "nodi",
		"convinzione": "Basta ricordare lo schema giusto.",
		"bisogno": "Lo schema del Delta è cambiato e la sua memoria non serve più a niente.",
		"arco": [
			"Collega ogni cavo a memoria, velocissimo, e ha imparato a memoria anche gli schemi che non capisce.",
			"Il Delta si riconfigura, la memoria non basta più, e per la prima volta deve chiedersi perché.",
			"Ha capito la regola: adesso davanti a uno schema nuovo non si blocca, lo legge.",
		],
		"battute": {
			"richiesta": [
				["Uno, due, tre nodi… no, quattro. Il Delta ne ha uno in più di ieri.", "Non è possibile e invece è così.", "Vieni a contarli con me, che io non mi fido più della mia testa."],
				["Al quadro di monte ci vorrebbe un aiuto.", "La corrente arriva e non arriva. Ho controllato i nodi tre volte.", "Vacci tu, con occhi nuovi. I miei sanno già cosa vogliono vedere."],
				["Una derivazione, laggiù, non l'ho mai capita.", "Due strade per la stessa lampada. Perché due? Chi le ha fatte lo sapeva.", "Va' a guardarla e poi torna a spiegarmelo, per favore."],
			],
			"consolazione": [
				["Vieni qua, siediti.", "Non si è acceso? Bene: adesso sappiamo una cosa in più di prima."],
				["Ehi. Nessun muso.", "Io conto i nodi ad alta voce da vent'anni perché da solo mi perdo. In due ci si perde meno."],
			],
			"stadio0": [
				["Quattro nodi in linea, poi la derivazione. Sempre così.", "Siediti, vuoi un po' d'acqua? Fa caldo qui sotto."],
				["Undici nodi, dodici nodi… no, aspetta, ricomincio.", "Se perdo il conto dei nodi devo ripartire da capo."],
				["Lo schema lo so a memoria dal primo giorno.", "Non chiedermi perché è fatto così. Chiedimi com'è fatto: quello lo so."],
			],
			"stadio1": [
				["Il Delta ha cambiato configurazione stanotte.", "Sette nodi, non quattro. E io sono rimasto lì fermo come un palo."],
				["Eli, tu davanti a uno schema che non hai mai visto cosa fai?", "Perché io non faccio niente. Conto i nodi e mi blocco."],
				["Doria dice che l'acqua glielo spiega.", "Vuoi un po' d'acqua anche tu? Forse capisco meglio se guardo qualcuno bere."],
			],
			"stadio2": [
				["In serie la corrente è la stessa dappertutto, in parallelo si divide.", "Due regole. Due! Al posto di quaranta schemi a memoria."],
				["Oggi è arrivato uno schema nuovo e non ho contato i nodi.", "L'ho letto. Ho letto uno schema, Eli. Siediti che ti offro qualcosa."],
				["Ricordare serviva finché niente cambiava.", "Capire serve quando cambia tutto. E qui cambia tutto di continuo."],
			],
			"reazione": [
				["L'apparato si è riacceso e ha ridisegnato il circuito da solo!", "Sette nodi. Li ho contati. Ma li ho anche capiti."],
				["Tutto a posto. Bevi qualcosa, sei tutta polvere.", "No, insisto. Qui sotto si perde più acqua di quanta se ne pensi."],
				["Sesto è passato a ripassare.", "Gli ho fatto contare i nodi. Si è fermato al sei e ha chiesto come mi chiamo."],
			],
			"riempimento": [
				["Il Delta ha canali d'acqua e canali di corrente.", "Corrono paralleli e non si toccano mai. Bello, no?"],
				["Sedici nodi in questo tratto. Sedici.", "Li conto per abitudine, ormai, non per paura."],
				["Scintilla si presenta come il capo della palude.", "Qui non c'è nessuna palude. Ma lui è convinto, e a me sta simpatico."],
			],
		},
	},
	"w08-doria": {
		"funzione": "testimone",
		"world": 8,
		"nome": "Doria",
		"ruolo": "Guardiana delle chiuse del Delta",
		"registro": "misterioso",
		"tic": "risponde con una domanda sull'acqua",
		"ticMarker": "acqua",
		"convinzione": "Quello che so dell'acqua non c'entra niente con l'elettricità.",
		"bisogno": "Vuole sapere perché il sigillo dell'equipaggio abbia più posti che nomi.",
		"arco": [
			"Regola le chiuse per istinto e considera i circuiti una faccenda d'altri.",
			"Si accorge che le sue chiuse e i circuiti di Ciro obbediscono alla stessa regola.",
			"Usa l'analogia come metodo e insegna a Ciro a leggere un circuito come si legge un fiume.",
		],
		"battute": {
			"richiesta": [
				["Tu lo sai quanta acqua passa da una chiusa stretta?", "Poca e veloce. Da una larga? Tanta e piano.", "Va' a guardare il quadro elettrico e dimmi se ti ricorda qualcosa."],
				["Sulla paratia c'è un sigillo con più posti che nomi.", "Otto alloggiamenti, cinque nomi. Tre buchi che aspettano.", "Vacci. Io ci guardo dentro da anni e vedo solo acqua."],
				["Sai perché il canale gela sempre nello stesso punto?", "Perché lì rallenta. E dove rallenta, qualcosa si accumula.", "Va' a vedere se anche là dentro qualcosa rallenta."],
			],
			"consolazione": [
				["L'acqua ti torna indietro quando forzi la chiusa. Lo sapevi?", "Aspetti, riapri piano, e passa. Fai lo stesso."],
				["E allora?", "Anche il fiume sbaglia strada, e si chiama meandro. Nessuno lo sgrida."],
			],
			"stadio0": [
				["Vuoi passare? Prima dimmi: dove va l'acqua quando chiudo questa paratia.", "Se non lo sai, la chiusa te lo insegnerà."],
				["I cavi non li tocco. Io ho l'acqua.", "Sono due mestieri diversi. …o no?"],
				["Stretta la gola, veloce l'acqua. Larga la gola, lenta.", "Lo sanno tutti. Non è sapere, è guardare."],
			],
			"stadio1": [
				["Ciro dice che se stringi il filo passa meno corrente.", "E l'acqua nella gola stretta? Cosa fa l'acqua?", "…passa di meno. Uguale. Uguale identico."],
				["Due chiuse in fila fanno passare quanto la più stretta.", "Chiedi a Ciro cosa fanno due resistenze in fila. Poi torna e dimmelo."],
				["Se l'acqua e la corrente si comportano uguali…", "…allora quarant'anni di chiuse sono quarant'anni di elettricità che non sapevo di avere."],
			],
			"stadio2": [
				["Un'analogia non è una poesia: è uno strumento.", "Quando non capisci una cosa, chiediti a quale acqua somiglia."],
				["Ho insegnato a Ciro a leggere un circuito come si legge un fiume.", "Dove si allarga, dove si stringe, dove si divide."],
				["Vieni a vedere il sigillo dell'equipaggio, nella Rovina.", "Contali, i posti. Poi conta i nomi.", "…poi torna e dimmi se l'acqua ti sembra ancora l'unica cosa strana di questo Delta."],
			],
			"reazione": [
				["Tutte le paratie si sono aperte insieme. Come una piena.", "L'acqua è andata dove doveva. Chi l'ha progettato conosceva i fiumi."],
				["Hai chiuso la missione.", "Sai qual è la domanda giusta adesso? Dove va l'acqua che hai liberato."],
				["È passato il ragazzo che si perde per strada dentro le frasi.", "Gli ho chiesto dove va l'acqua. Ha risposto «in giù». Non è una risposta stupida."],
			],
			"riempimento": [
				["Di notte le chiuse cantano. È l'acqua che passa stretta.", "Dal tono capisco l'apertura senza guardare."],
				["C'è un canale che non porta acqua da quattrocento anni.", "È asciutto e pulito. Chi l'ha chiuso l'ha svuotato prima, con ordine."],
				["Il sigillo nella Rovina ha tredici posti.", "I nomi incisi sono undici. Non chiedermi altro: guarda tu."],
			],
		},
	},
	"w09-alma": {
		"funzione": "specialista",
		"world": 9,
		"nome": "Alma",
		"ruolo": "Cartografa dell'Arcipelago",
		"registro": "burbero",
		"tic": "bagna la punta della matita prima di ogni tratto",
		"ticMarker": "matita",
		"convinzione": "I numeri non sono posti.",
		"bisogno": "Deve disegnare la carta di un'isola su cui non è mai sbarcata.",
		"arco": [
			"Disegna soltanto ciò che ha visto con i suoi occhi, e le sue carte finiscono dove finisce lei.",
			"Le danno tre distanze misurate e scopre che bastano a collocare un'isola che non ha visto.",
			"Disegna con i numeri degli altri e la sua carta arriva più lontano di lei.",
		],
		"battute": {
			"richiesta": [
				["(bagna la punta della matita) Devo disegnare un'isola dove non sono mai stata.", "Ho solo due numeri, e i numeri non sono posti.", "Vai al porto, chiedi a Remo dove finiscono quei due numeri."],
				["Il promontorio est non l'ha mai rilevato nessuno.", "La mia matita arriva fin dove arriva la mia barca, e quella non ci arriva.", "Vacci tu. Segna tutto, anche quello che ti sembra inutile."],
				["Ho tre carte dello stesso tratto di costa e sono diverse.", "(bagna la matita) Diverse in modo interessante, non in modo sbagliato.", "Va' a controllare quale delle tre è ancora vera."],
			],
			"consolazione": [
				["Carta buttata? Se ne prende un'altra.", "Ho consumato più fogli io in un mese che tu in tutta la vita. Riparti dal margine."],
				["Senti. Nessun cartografo ha mai azzeccato una costa al primo giro.", "(bagna la matita) Si torna, si guarda, si corregge. È il mestiere."],
			],
			"stadio0": [
				["(bagna la matita) Questa costa l'ho vista. La disegno.", "Quella dietro no. Resta bianca."],
				["Mi portano fogli pieni di numeri e mi dicono: qui c'è un'isola.", "(bagna la matita) I numeri non sono posti. Un posto è un posto."],
				["La mia carta finisce dove sono arrivata io.", "È onesta, almeno."],
			],
			"stadio1": [
				["Eli, tre distanze da tre punti diversi.", "(bagna la matita) E l'isola sta in un solo posto possibile. Uno.", "Come fa un numero a sapere dov'è un'isola?"],
				["Ho segnato il punto senza esserci mai stata.", "Remo ci è passato ieri. C'era l'isola. Esattamente lì."],
				["(bagna la matita) Se i numeri collocano un'isola…", "…allora hanno visto qualcosa anche loro. E io non capisco cosa."],
			],
			"stadio2": [
				["(bagna la matita) Guarda la carta nuova. Arriva a nord del terzo braccio.", "Dove io non arriverò mai."],
				["Un numero è un posto detto in un'altra lingua.", "Ci ho messo trent'anni a impararla."],
				["Remo mi detta le rotte, io le disegno.", "(bagna la matita) La sua memoria e la mia mano. Insieme siamo una carta intera."],
			],
			"reazione": [
				["È comparsa una carta, proiettata in aria.", "(bagna la matita) Copiava la mia. Con dentro i pezzi che mi mancavano."],
				["Fatto. (bagna la matita) Segno il punto e la data.", "Le carte servono a questo: dire dov'eri e quando."],
				["Hai fatto ripassare Sesto?", "Quel ragazzo ha disegnato un'isola a memoria. Sbagliata, ma disegnata bene."],
			],
			"riempimento": [
				["(bagna la matita) L'inchiostro dei cartografi non si sbiadisce al sale.", "È l'unica cosa che ho di lusso."],
				["Bora disegna mappe di posti che non esistono ancora.", "Non lo correggo. Ogni tanto poi ci vado a vedere."],
				["Le isole si spostano sulle vecchie carte.", "Non sono le isole. Sono le carte fatte a occhio."],
			],
		},
	},
	"w09-remo": {
		"funzione": "testimone",
		"world": 9,
		"nome": "Remo",
		"ruolo": "Traghettatore dell'Arcipelago",
		"registro": "sognante",
		"tic": "parla delle rotte come di persone",
		"ticMarker": "rotta",
		"convinzione": "Una rotta si ricorda, non si scrive.",
		"bisogno": "Sta perdendo la memoria delle rotte e vuole lasciarne una copia.",
		"arco": [
			"Conosce ottanta rotte a memoria e considera scriverle un tradimento del mestiere.",
			"Dimentica un passaggio che faceva da trent'anni e capisce che la memoria non basta più.",
			"Detta le rotte ad Alma e scopre che scriverle non le uccide: le lascia in giro.",
		],
		"battute": {
			"richiesta": [
				["La rotta del nord è vecchia e stanca, come me.", "Non me la ricordo più tutta. Mi manca un pezzo in mezzo.", "Vieni in barca. Se la riconosci tu, io la scrivo."],
				["Una rotta, i vecchi, la chiamavano «la bugiarda».", "Sembra più corta e ci metti il doppio. Nessuno mi ha mai spiegato perché.", "Va' a vedere le secche. La risposta è lì sotto, credo."],
				["Sulla stele del molo vecchio ci sono dei numeri a coppie.", "Io li leggo come nomi di rotte, ma sono numeri.", "Vacci tu e chiedi ad Alma. Le mie rotte vorrei lasciarle a qualcuno."],
			],
			"consolazione": [
				["Ti sei perso? Anche le rotte si perdono.", "Poi però tornano. Si aspetta la marea buona e si riprova."],
				["Vieni, siediti a poppa un momento.", "La rotta più bella che conosco l'ho trovata sbagliando strada tre volte."],
			],
			"stadio0": [
				["Questa rotta la conosco da quando avevo le mani lisce.", "Non serve scriverla. Vive qui dentro."],
				["Le rotte hanno un carattere. Questa è permalosa: se la sbagli, non perdona.", "Ci si affeziona, sai."],
				["Scrivere una rotta è come chiudere qualcuno in un cassetto.", "Non lo faccio."],
			],
			"stadio1": [
				["Ho perso un passaggio, Eli. Trent'anni che lo facevo.", "Sono rimasto fermo in mezzo all'acqua a cercarlo dentro di me."],
				["Se una rotta muore con me, che rotta è stata?", "…me lo sono chiesto stanotte e non ho dormito."],
				["Alma dice che può disegnarle. Tutte e ottanta.", "La rotta scritta è ancora la mia rotta o è un'altra?"],
			],
			"stadio2": [
				["Ne abbiamo scritte quarantadue. Ci fermiamo, poi riprendiamo.", "Ogni rotta scritta è una rotta che qualcun altro potrà conoscere."],
				["Non era un cassetto. Era una barca in più.", "La rotta continua a navigare anche quando io sto fermo."],
				["Un ragazzo del molo ha preso la mia rotta numero nove.", "L'ha fatta senza di me. È la cosa più bella che mi sia capitata."],
			],
			"reazione": [
				["Si è accesa una luce sul terzo braccio. Come un fanale su una rotta.", "Proprio dove gira la rotta vecchia. Se ne ricordava anche lui."],
				["Finita. Ti traghetto dove vuoi, oggi non prendo niente."],
				["Sesto è salito sulla mia barca.", "Si è presentato quattro volte. Bella rotta anche la sua, a modo suo."],
			],
			"riempimento": [
				["Ogni rotta ha un'ora giusta. Prima o dopo è un'altra rotta.", "L'acqua cambia idea due volte al giorno."],
				["Da ragazzo credevo che il mare finisse dietro l'ultima isola.", "Poi ci sono andato. Ricomincia."],
				["La rotta undici passa vicino a una cosa che non guardo mai.", "Non chiedermelo. Passo e basta."],
			],
		},
	},
	"w10-ortensia": {
		"funzione": "specialista",
		"world": 10,
		"nome": "Ortensia",
		"ruolo": "Botanica della Serra delle Simbiosi",
		"registro": "curioso",
		"tic": "parla alle piante come a colleghe",
		"ticMarker": "piante",
		"convinzione": "Se cambio tutto, prima o poi funziona.",
		"bisogno": "Ha un esperimento che riesce e non sa dire perché.",
		"arco": [
			"Quando qualcosa fallisce cambia acqua, luce e terra insieme, e riprova.",
			"Un esperimento le riesce e non sa quale delle tre cose l'abbia fatto riuscire.",
			"Cambia una variabile per volta e per la prima volta può ripetere un successo.",
		],
		"battute": {
			"richiesta": [
				["Le piante del riquadro tre stanno benissimo e io non so perché.", "Ho cambiato acqua, luce e terra tutte insieme. Tutte e tre.", "Vieni a rifarlo con me cambiando una cosa sola."],
				["Sulla serra bassa ci vorrebbe un secondo paio di occhi.", "Le piante lì dentro parlano fra loro, te lo dico da collega.", "Va' a vedere quali stanno vicine e quali si evitano."],
				["Nel diario di Mirta un esperimento riusciva a lei e a me no.", "Quarant'anni fa le riusciva. A me no.", "Vacci tu e leggilo per intero. Anche le pagine noiose."],
			],
			"consolazione": [
				["Perfetto, sul serio.", "Un esperimento che fallisce ti dice una cosa; uno che riesce per caso non ti dice niente."],
				["Vieni, le piante ci guardano.", "Le mie sono morte a decine prima che ne capissi una. Riproviamo cambiando una cosa alla volta."],
			],
			"stadio0": [
				["Non cresceva. Ho cambiato terra, acqua e posizione.", "(alle piante) Ce l'avete fatta, brave.", "Non chiedermi cosa ha funzionato."],
				["Provo tutto insieme, così faccio prima.", "Le piante non hanno tempo da perdere e nemmeno io."],
				["(a una felce) Tu invece cosa vuoi? Dimmelo tu, che io ho finito le idee."],
			],
			"stadio1": [
				["È cresciuta, Eli! Trentadue centimetri!", "E adesso devo rifarlo per l'altra serra e… non so cosa rifare."],
				["Ho cambiato tre cose. Se ne rifaccio una sola, quale?", "(alle piante) Voi lo sapete e non me lo dite."],
				["Mirta tiene un diario da quarant'anni.", "Una riga al giorno, una cosa per volta. Io la prendevo per lentezza."],
			],
			"stadio2": [
				["Una variabile per volta. Sette giorni ciascuna.", "(alle piante) Sì, ci vuole più tempo. Ma poi so cosa vi ha fatto bene."],
				["Ho ripetuto il risultato. RIPETUTO.", "Non è fortuna se lo sai rifare."],
				["Sto copiando il metodo di Mirta e lei non se n'è ancora accorta.", "(alle piante) Non ditele niente."],
			],
			"reazione": [
				["La luce della serra si è regolata da sola.", "(alle piante) Ha cambiato una cosa sola. Ha imparato prima di me."],
				["Riuscita! Vieni, ti faccio vedere il germoglio nuovo."],
				["Sesto ha innaffiato tutto due volte.", "(alle piante) Sopravvivrete. Ha buone intenzioni."],
			],
			"riempimento": [
				["(a un rampicante) Tu cresci verso la luce anche se la luce ti fa male. Perché?"],
				["Nella Serra ci sono piante che si aiutano e piante che si fanno la guerra.", "Simbiosi non vuol dire pace."],
				["Terriccio ha dato un nome a ogni foglia.", "(alle piante) Voi lo assecondate, lo so."],
			],
		},
	},
	"w10-mirta": {
		"funzione": "testimone",
		"world": 10,
		"nome": "Mirta",
		"ruolo": "Custode della Serra, quarant'anni di diario",
		"registro": "caloroso",
		"tic": "offre sempre una tisana e chiama Eli «piccola»",
		"ticMarker": "tisana",
		"convinzione": "Io non faccio scienza, io guardo e basta.",
		"bisogno": "Vuole sapere se quei quaderni servono a qualcuno oltre che a lei.",
		"arco": [
			"Annota una riga al giorno da quarant'anni e lo considera un passatempo da vecchi.",
			"Ortensia le chiede il quaderno del 1987 e ci trova la risposta a un esperimento di oggi.",
			"I suoi quaderni diventano l'archivio della Serra, e lei smette di chiamarlo passatempo.",
		],
		"battute": {
			"richiesta": [
				["Siediti, piccola, che la tisana è pronta.", "Nel quaderno del terzo anno c'è una pagina che non torna con le altre.", "Vacci a guardare tu. Io non ho più gli occhi per i confronti."],
				["Ortensia mi ha chiesto un quaderno vecchio, e io ne ho dato uno solo.", "Gli altri undici sono ancora nella cassa, piccola.", "Va' a prenderli. Poi mi dici se dodici quaderni dicono la stessa cosa di uno."],
				["Una data l'ho segnata per quarant'anni: la prima gemma.", "Ogni anno un po' prima. Un po' prima, un po' prima.", "Bevi la tisana e poi va' a controllare se è successo anche quest'anno."],
			],
			"consolazione": [
				["Vieni qui, piccola. Prima la tisana, poi i pensieri.", "Le cose che non riescono si rimettono in fondo alla lista, non nel cestino."],
				["Non ti crucciare.", "Io ho guardato per quarant'anni senza capire di star facendo qualcosa. Tu stai già capendo. Riposa e riprova."],
			],
			"stadio0": [
				["Siediti, piccola. Ti faccio una tisana.", "Io qui guardo e scrivo. Non è mica un mestiere."],
				["Una riga al giorno. Che giorno era, che tempo faceva, cosa ho visto.", "Quarant'anni di righe. Tisana?"],
				["Gli scienziati veri hanno gli strumenti.", "Io ho una sedia e una matita."],
			],
			"stadio1": [
				["Ortensia mi ha chiesto un quaderno vecchio. Il tredicesimo.", "C'era scritta la risposta a una cosa che le succede adesso.", "Bevi la tisana che si fredda, piccola."],
				["Quarant'anni fa ho visto la stessa muffa. L'avevo scritto.", "Non sapevo di star rispondendo a una domanda che nessuno aveva ancora fatto."],
				["Se guardare e scrivere serve a qualcuno…", "…allora forse non era solo un passatempo. Tisana?"],
			],
			"stadio2": [
				["I quaderni stanno sullo scaffale grande adesso. Tutti e quaranta.", "Ortensia li consulta prima di ogni prova. Siediti, piccola, che te ne leggo uno."],
				["Osservare a lungo è un metodo, non un carattere.", "Me l'ha detto lei e io le ho creduto solo perché aveva i quaderni in mano."],
				["Ho cominciato il quarantunesimo.", "Scrivo diverso, adesso: scrivo per qualcuno che leggerà. Tisana?"],
			],
			"reazione": [
				["Ho sentito la Serra respirare diverso.", "L'ho scritto sul quaderno, con l'ora. Siediti, piccola."],
				["È andata bene, piccola? Allora si festeggia con la tisana buona, quella con il miele."],
				["È passato il ragazzo che si presenta due volte per merenda.", "Gli ho dato una tisana e si è presentato di nuovo. Caro."],
			],
			"riempimento": [
				["Tisana di melissa oggi. La melissa cresce dove le pare, mai dove la pianti."],
				["Il quaderno del terzo anno è tutto bagnato.", "Un temporale del 1962. Anche quello è un dato, piccola."],
				["Le piante non ti ringraziano mai.", "Però crescono. È il loro modo di dire grazie. Tisana?"],
			],
		},
	},
	"w11-danio": {
		"funzione": "specialista",
		"world": 11,
		"nome": "Danio",
		"ruolo": "Antiquario della Soglia del Tempo",
		"registro": "divertente",
		"tic": "scommette su qualunque cosa",
		"ticMarker": "scommett",
		"convinzione": "Se lo dicono tutti, è vero.",
		"bisogno": "Ha comprato un reperto falso e vuole capire come si fa a non ricascarci.",
		"arco": [
			"Data i reperti a occhio e crede alla prima versione che sente, purché sia raccontata bene.",
			"Scopre di aver pagato un falso perché «lo dicevano tutti», e la cosa non gli fa più ridere.",
			"Chiede sempre due fonti prima di comprare, e ci ha fatto una scommessa vinta.",
		],
		"battute": {
			"richiesta": [
				["Ti scommetto una moneta che questa anfora è autentica.", "…me l'hanno detto in tre. Tre persone diverse.", "Va' a farla vedere a Vesta prima che io perda la scommessa e la faccia."],
				["Ho una cassa di reperti comprati al mercato del valico.", "Scommetto che due su cinque sono falsi. Non so quali due.", "Vieni ad aprirla con me e insegnami a guardarli."],
				["Nella Rovina c'è un bollo di fabbrica sul fondo di un vaso.", "Se un vaso ha il bollo, qualcuno l'ha firmato. Scommetto che dice anche quando.", "Va' a leggerlo. Io da lì dentro non riesco più a uscire senza comprare qualcosa."],
			],
			"consolazione": [
				["Persa? Bene, scommetto che la prossima la vinci.", "Ho sbagliato più affari io in un mese che tu in tutta la giornata."],
				["Ehi, su la testa.", "Sbagliare da soli è brutto. Sbagliare in due è una scommessa, e le scommesse si rifanno."],
			],
			"stadio0": [
				["Questo è di quattrocento anni fa. Scommetti?", "Come lo so? Me l'ha detto quello che me l'ha venduto."],
				["Scommetto che indovino l'epoca a occhio. Dieci a uno.", "…ho vinto? Ho vinto. Di solito vinco."],
				["Se una storia la raccontano tutti uguale, è vera.", "Scommettiamo che è così?"],
			],
			"stadio1": [
				["Eli, ho comprato un vaso. Falsissimo.", "Lo dicevano tutti che era autentico. TUTTI.", "Scommetto che «tutti» erano tre persone che si erano sentite fra loro."],
				["Ho chiesto a Vesta. Ha due cronache che si contraddicono.", "Due! E nessuna delle due l'ha scritta un bugiardo."],
				["Come faccio a sapere quale versione regge?", "Scommetto che c'è un modo. Voglio saperlo."],
			],
			"stadio2": [
				["Due fonti indipendenti. Indipendenti, cioè che non si sono copiate.", "Scommetto che d'ora in poi non mi frega più nessuno."],
				["Ho rivenduto il vaso falso. Dichiarandolo falso.", "Ci ho guadagnato meno e dormo molto meglio."],
				["Anticaglia vende falsi e lo dice.", "Quello è onesto. Scommetto che vende più di me."],
			],
			"reazione": [
				["Un reperto si è datato da solo! Scommetto che nessuno mi crede.", "Scommetto che ci azzecca più di me. …ho perso la scommessa."],
				["Vinta! Offro io. No, davvero: scommetto che non mi credi."],
				["Sesto mi ha venduto una pietra dicendo che era antica.", "Non lo sapeva neanche lui. Scommetto che se l'era dimenticato."],
			],
			"riempimento": [
				["Scommetto che questa moneta è più vecchia di quella.", "…adesso però controllo prima di dirlo forte."],
				["La Soglia del Tempo è piena di roba che nessuno sa cos'è.", "Scommetto che metà è spazzatura e metà è tesoro. Il problema è quale metà."],
				["Vesta non brucia mai niente. Nemmeno le cose sbagliate.", "Scommetto che ha ragione lei."],
			],
		},
	},
	"w11-vesta": {
		"funzione": "testimone",
		"world": 11,
		"nome": "Vesta",
		"ruolo": "Custode delle cronache della Soglia",
		"registro": "solenne",
		"tic": "pesa le parole e le cronache con le stesse mani",
		"ticMarker": "cronac",
		"convinzione": "Se due cronache si contraddicono, una delle due va bruciata.",
		"bisogno": "Deve decidere quale delle due cronache del Silenzio distruggere.",
		"arco": [
			"Custodisce due racconti inconciliabili e vive nell'idea che tenerli entrambi sia disonesto.",
			"Capisce che il disaccordo fra due fonti è esso stesso un'informazione.",
			"Le tiene entrambe, affiancate, con una nota che spiega dove divergono.",
		],
		"battute": {
			"richiesta": [
				["Ho due cronache dello stesso anno e si contraddicono.", "Una dice che la città fu abbandonata, l'altra che fu incendiata.", "Va' a vedere le mura. Sono l'unica cronaca che non può mentire."],
				["Nella teca bassa c'è una cronaca senza autore.", "Chi scrive senza firmare o ha paura o ha uno scopo. Non ho mai deciso quale.", "Vacci tu e leggila. Poi mi dirai cosa ne pensi."],
				["Devo decidere quale delle due cronache del Silenzio distruggere.", "Prima di farlo voglio che qualcuno le abbia lette entrambe.", "Sei tu. Non tornare finché non le hai finite."],
			],
			"consolazione": [
				["Poso la penna. Ascoltami.", "Una cronaca sbagliata non si brucia: si annota a margine. Vale anche per gli errori delle persone."],
				["Il verdetto, oggi, non è la cosa che conta.", "Conta che hai pesato le cose invece di scegliere la più comoda. Riprendiamo domani."],
			],
			"stadio0": [
				["Due cronache dello stesso giorno. Dicono cose diverse.", "Una mente. Devo scoprire quale e bruciarla."],
				["Una biblioteca che conserva il falso non è una biblioteca.", "È un magazzino."],
				["(soppesa la cronaca) Questa è più antica. Forse basta questo."],
			],
			"stadio1": [
				["Nessuna delle due mente, Eli. Sono state scritte da due persone che erano in due stanze diverse.", "E allora chi brucio?"],
				["Il punto in cui le due cronache divergono…", "…è esattamente il punto in cui è successo qualcosa che qualcuno voleva nascondere."],
				["(soppesa le due cronache, una per mano) Sono uguali di peso.", "Non mi era mai sembrato così poco utile pesare una cosa."],
			],
			"stadio2": [
				["Le tengo tutte e due. Affiancate, con una nota in mezzo.", "La nota dice: qui divergono, e la divergenza è la notizia."],
				["Ho passato vent'anni a cercare quale bruciare.", "La domanda giusta era: perché due persone oneste raccontano diversamente."],
				["(soppesa una cronaca nuova) Danio me ne porta due per volta, adesso.", "Ha imparato in fretta, per essere uno che scommette."],
			],
			"reazione": [
				["Si è aperto un registro che non conoscevo. Una cronaca in più.", "(soppesa il foglio) Una terza cronaca. E concorda con nessuna delle due."],
				["Hai concluso. Lo annoto, con la data e le due versioni di come è andata."],
				["Ha raccontato la stessa storia tre volte, quel ragazzo smemorato.", "Tre versioni diverse. Le ho trascritte tutte."],
			],
			"riempimento": [
				["(soppesa una cronaca) Le cronache dei Primi sono scritte fitte.", "Chi ha poco tempo scrive piccolo."],
				["C'è una cronaca del Silenzio che si interrompe a metà frase.", "Non è strappata. Si interrompe."],
				["Anticaglia mi ha offerto una cronaca falsa.", "L'ho comprata. Anche i falsi dicono qualcosa su chi li fa."],
			],
		},
	},
	"w12-quinto": {
		"funzione": "specialista",
		"world": 12,
		"nome": "Quinto",
		"ruolo": "Guida del Labirinto delle Regole",
		"registro": "burbero",
		"tic": "conta i passi ad alta voce",
		"ticMarker": "passi",
		"convinzione": "Ricordare la strada è saperla.",
		"bisogno": "I muri del Labirinto si sono spostati e la sua memoria non vale più niente.",
		"arco": [
			"Attraversa il Labirinto a memoria, quattrocentododici passi, e se ne vanta.",
			"I muri si spostano di notte e lui resta bloccato: sapeva la strada, non il modo di trovarla.",
			"Usa il metodo del filo di Isa e attraversa un labirinto che non ha mai visto.",
		],
		"battute": {
			"richiesta": [
				["Duecentododici passi fino alla sala rossa. Erano duecentododici.", "Stamattina sono duecentonovanta e la sala non c'è.", "Vieni con me. Serve un modo che non sia contare i passi."],
				["Il braccio ovest è senza nessuno da due giorni.", "Io lì dentro giro in tondo da due giorni. Sempre lo stesso corridoio.", "Va' tu e segna qualcosa. Non so cosa. Qualcosa."],
				["Isa dice di avere un trucco col filo.", "Io conto i passi da trent'anni e non voglio sentire parlare di trucchi.", "Vacci tu. Guarda cosa fa e poi torna a dirmelo con parole mie."],
			],
			"consolazione": [
				["Ti sei perso. E allora?", "Il Labirinto perde tutti almeno una volta. Chi dice il contrario non ci è mai entrato."],
				["Fermati. Conta con me: uno, due, tre passi indietro.", "Ecco. Si riparte da un posto che conosciamo."],
			],
			"stadio0": [
				["Quattrocentododici passi fino al centro. Li conto da vent'anni.", "Non sbaglio mai. Mai."],
				["Chi segna i muri col gesso non sa il labirinto: lo copia.", "Contare i passi è un'altra cosa."],
				["Trentotto passi, poi a destra. Trentotto. Non trentanove."],
			],
			"stadio1": [
				["I muri si sono spostati stanotte.", "Ho contato trentotto passi e ho trovato pietra.", "Sono rimasto lì un'ora, Eli. Un'ora, a contare di nuovo."],
				["Sapevo la strada. Non sapevo trovarla.", "Adesso che l'ho detto ad alta voce suona terribile."],
				["Isa segna i bivi con un filo. Ha undici anni.", "…quattrocentododici passi e mi batte una bambina con uno spago."],
			],
			"stadio2": [
				["Bivio segnato, ramo esplorato, filo teso. Poi si torna e si prende l'altro.", "Non conto più i passi. Conto i bivi, che sono molti di meno."],
				["Ieri sono entrato in un labirinto che non avevo mai visto. E sono uscito.", "Vent'anni fa non sarei nemmeno entrato."],
				["Ricordare una strada è utile finché la strada sta ferma.", "Qui niente sta fermo. Neanche noi, a pensarci."],
			],
			"reazione": [
				["Le luci del settore est si sono spente. Trentadue passi al buio.", "Ho contato i passi al buio per abitudine. Poi ho usato il filo."],
				["Fatto. Bene. Non ti accompagno all'uscita: la trovi da sola, ormai."],
				["È entrato nel Labirinto, quel ragazzo senza segno.", "Ha usato il filo. Non ricorda perché funzioni, ma lo usa."],
			],
			"riempimento": [
				["Quattrocentododici. Ancora mi viene da contarli.", "È come una canzone che non ti esce dalla testa."],
				["Nel settore nord c'è una stanza con delle schede.", "Numerate. Non le ho contate. Non volevo."],
				["Svolta entra ogni mattina per «tenere il labirinto in esercizio».", "Il labirinto sta benissimo. È lui che si annoia."],
			],
		},
	},
	"w12-isa": {
		"funzione": "testimone",
		"world": 12,
		"nome": "Isa",
		"ruolo": "Bambina del Labirinto, ha inventato il metodo del filo",
		"registro": "curioso",
		"tic": "chiede «e se invece…?»",
		"ticMarker": "e se invece",
		"convinzione": "Se l'ho inventato io, allora non è un metodo vero.",
		"bisogno": "Vuole sapere se il suo trucco ha un nome anche fuori dal Labirinto.",
		"arco": [
			"Ha inventato da sola un metodo che funziona e lo tiene per sé perché «è solo una cosa mia».",
			"Scopre che altri, altrove, hanno inventato la stessa identica cosa: allora non era un caso.",
			"Insegna il metodo a Quinto e capisce che inventare e scoprire sono la stessa parola.",
		],
		"battute": {
			"richiesta": [
				["E se invece di ricordarti la strada, la segnassi?", "Ho lasciato dei fili nel braccio nord. Vai a vedere come li ho messi."],
				["Da qualche parte lì dentro, quattro porte uguali.", "Io ci ho provato: la prima a sinistra, sempre. Sempre la stessa regola.", "E se invece funzionasse davvero? Vacci a controllare."],
				["Nella Rovina c'è un pavimento con dei segni a bivio.", "Somigliano ai miei fili, ma sono di pietra e vecchissimi.", "Va' a guardarli. Voglio sapere se il mio trucco ce l'aveva già qualcuno."],
			],
			"consolazione": [
				["E se invece riprovassimo da metà strada?", "Non serve rifare tutto: solo il pezzo dove il filo si è rotto."],
				["Aspetta, non buttare via il foglio.", "Anche i miei fili si aggrovigliano. Li sbroglio e ricomincio, e nessuno mi guarda."],
			],
			"stadio0": [
				["Segno i bivi con il filo. Così so dove sono già stata.", "E se invece fosse una cosa da bambini? Probabilmente sì."],
				["Non lo dico a nessuno. Quinto conta i passi, lui è bravo."],
				["E se invece il filo si rompe? Ne porto tre."],
			],
			"stadio1": [
				["Eli, esiste già! Il mio metodo esiste già!", "Uno lo ha inventato tanto tempo fa, in un altro posto.", "E se invece non fosse una coincidenza?"],
				["Se due persone che non si conoscono trovano la stessa cosa…", "…allora la cosa era lì, e noi l'abbiamo trovata. Non inventata. Trovata."],
				["E se invece inventare e scoprire fossero la stessa parola detta da due punti di vista?"],
			],
			"stadio2": [
				["Ho insegnato il filo a Quinto! A QUINTO!", "E se invece adesso diventa più bravo di me? …va benissimo lo stesso."],
				["Il metodo funziona in qualunque labirinto. Anche in quelli che non esistono ancora.", "È questo che vuol dire metodo, no?"],
				["Non era una cosa da bambini.", "Era una cosa fatta bene, e l'ho fatta io. E se invece ne trovassi un'altra?"],
			],
			"reazione": [
				["Hai acceso l'apparato! E se invece adesso il labirinto smette di spostarsi?", "Sarebbe un peccato, quasi."],
				["Uscita! Ti ho seguita col filo da lontano. Non te la prendere."],
				["Sesto si perde anche con il filo.", "E se invece gli dessi due fili? Ci sto pensando."],
			],
			"riempimento": [
				["Nel settore nord c'è una stanza piena di schede numerate.", "Le ho contate: tredici. E se invece ne mancasse una?"],
				["Il filo verde per i bivi, il rosso per i vicoli ciechi.", "E se invece mi confondo? Non mi confondo."],
				["Quinto dice quattrocentododici passi. Io ne conto trecentonovanta.", "E se invece avessimo gambe diverse? Ecco, è quello."],
			],
		},
	},
	"w13-solano": {
		"funzione": "specialista",
		"world": 13,
		"nome": "Solano",
		"ruolo": "Astronomo del Deserto delle Orbite",
		"registro": "solenne",
		"tic": "pulisce le lenti prima di ogni frase importante",
		"ticMarker": "lenti",
		"convinzione": "Stimare è tirare a indovinare.",
		"bisogno": "Ha rotto lo strumento e deve dare una risposta lo stesso.",
		"arco": [
			"Misura tutto con precisione assoluta e senza strumenti non sa dire nulla.",
			"Lo strumento si rompe e Duna dà a occhio una distanza che poi risulta corretta al tre per cento.",
			"Stima prima e misura poi: la stima gli dice se la misura ha senso.",
		],
		"battute": {
			"richiesta": [
				["(pulisce le lenti) Il quadrante grande si è spezzato.", "Devo dare l'ora del passaggio lo stesso, stanotte.", "Vieni all'osservatorio. Mi serve un modo che non sia lo strumento."],
				["Mi occorre la larghezza del cratere sud.", "Non ho catena né corda abbastanza lunga. (pulisce le lenti) Non ne ho proprio."],
				["Duna dice di indovinare le distanze con la mano.", "Indovinare. Capisci perché non ci vado io?", "Vacci tu. Misura quello che lei indovina, e portami i due numeri."],
			],
			"consolazione": [
				["(pulisce le lenti) Una misura sbagliata è un dato.", "Si annota, si dichiara l'incertezza, si rifà. È così che si è sempre fatto."],
				["Alza gli occhi un momento.", "Le stelle stanno lì da prima di noi e ci aspettano. Riproviamo domani a quest'ora."],
			],
			"stadio0": [
				["(pulisce le lenti) Tre virgola quattro sette due gradi.", "Questa è una risposta. «Circa tre e mezzo» non lo è."],
				["Senza strumento non parlo. Sarebbe disonesto."],
				["(pulisce le lenti) Chi stima si accontenta. Io non mi accontento."],
			],
			"stadio1": [
				["Lo strumento si è rotto e dovevo dare una distanza.", "Duna l'ha detta a occhio. Sbagliava del tre per cento.", "(pulisce le lenti) Tre per cento, Eli. A occhio."],
				["Ci ho provato, a stimare. Mi sono sentito un ciarlatano.", "Poi ho misurato: ero vicino. Molto vicino."],
				["Se la stima è vicina alla misura…", "(pulisce le lenti) …a cosa serve la stima, se poi misuro comunque?"],
			],
			"stadio2": [
				["Stimo prima. Poi misuro.", "Se la misura è lontanissima dalla stima, ho sbagliato la misura.", "(pulisce le lenti) La stima non sostituisce lo strumento: lo controlla."],
				["Ieri lo strumento dava un valore assurdo. La stima me l'ha detto subito.", "Era una lente sporca. La mia lente."],
				["Duna non ha un dono. Ha un metodo che nessuno le aveva mai chiamato così.", "(pulisce le lenti) Gliel'ho detto io. Se l'è scritto."],
			],
			"reazione": [
				["(pulisce le lenti) L'apparato ha calcolato un'orbita.", "Ha dato prima un valore approssimato, poi quello esatto. Nell'ordine giusto."],
				["Missione conclusa. Registrata con l'ora esatta.", "(pulisce le lenti) E con la stima dell'ora, che oggi mi diverte fare."],
				["Il giovane smemorato ha guardato nel telescopio.", "Ha detto «grande». È una stima. Approssimativa, ma è una stima."],
			],
			"riempimento": [
				["(pulisce le lenti) Nel deserto l'aria è ferma e le stelle non tremano.", "Per questo l'osservatorio è qui e non altrove."],
				["Un registro di manutenzione, nel magazzino.", "Undici voci cancellate. La dodicesima è stata aperta oggi. (pulisce le lenti) Non da me."],
				["Miraggio giura di aver visto qualcosa di enorme.", "Nel deserto succede. Non è sempre falso."],
			],
		},
	},
	"w13-duna": {
		"funzione": "testimone",
		"world": 13,
		"nome": "Duna",
		"ruolo": "Guida del deserto, indovina le distanze a occhio",
		"registro": "sognante",
		"tic": "misura il mondo con la mano tesa",
		"ticMarker": "mano tesa",
		"convinzione": "La mia è una dote, e le doti non si insegnano.",
		"bisogno": "Vuole poter insegnare a qualcuno come fa, e non sa da dove cominciare.",
		"arco": [
			"Indovina distanze e altezze a occhio e crede sia un talento con cui si nasce.",
			"Solano le chiede *come* fa, e nel rispondere scopre di avere dei passaggi.",
			"Ha scritto il suo metodo su mezza pagina e adesso lo sa fare anche un ragazzino.",
		],
		"battute": {
			"richiesta": [
				["(tende la mano verso l'orizzonte) Vedi quella roccia?", "Due mani e mezzo. Sono due ore di cammino, sempre.", "Va' a camminarci. Poi torna a dirmi quanto ci hai messo."],
				["Voglio insegnare a qualcuno come faccio, e non so da dove si comincia.", "(mano tesa) Prova tu: chiudi un occhio, allunga il braccio."],
				["Nel deserto c'è una pietra con dei fori a distanze precise.", "Chi l'ha fatta misurava come me, ma sapeva dirlo.", "Vacci. Se ci sono numeri incisi, io non li so leggere."],
			],
			"consolazione": [
				["Non ci sei arrivata. Il deserto è largo, capita.", "(mano tesa) Si guarda da dove si è partiti e si riparte con l'ombra più corta."],
				["Siediti all'ombra un momento.", "Anche io sbaglio, sai. Sbaglio di poco e nessuno se ne accorge, ma sbaglio."],
			],
			"stadio0": [
				["(mano tesa verso l'orizzonte) Quella duna? Milleduecento passi.", "Come lo so? Lo so."],
				["È una dote. Mia nonna ce l'aveva, io ce l'ho.", "Non si spiega, si ha."],
				["(mano tesa) Quella roccia è alta come sei uomini.", "…perché me lo chiedi? Guarda anche tu."],
			],
			"stadio1": [
				["Solano mi ha chiesto COME faccio.", "Non me l'aveva mai chiesto nessuno. (mano tesa) Mi sono bloccata."],
				["Gli ho risposto piano, per una volta.", "Prima guardo una cosa di cui so la misura. Poi conto quante ci stanno.", "…l'ho detto e mi sono spaventata: sono passaggi."],
				["Se ci sono dei passaggi, allora non è una dote.", "(mano tesa) E se non è una dote, cosa sono io?"],
			],
			"stadio2": [
				["Mezza pagina. Il mio metodo sta in mezza pagina.", "(mano tesa) Un ragazzino del villaggio l'ha imparato in tre giorni."],
				["Ero fiera di avere una dote.", "Adesso sono fiera di avere un metodo, ed è meglio: le doti restano ferme, i metodi camminano."],
				["(mano tesa) Solano stima prima di misurare, adesso.", "Gli ho insegnato una cosa a un astronomo. Io."],
			],
			"reazione": [
				["(mano tesa) L'apparato ha mandato una luce fin oltre la terza duna.", "Duemilaquattrocento passi. A occhio."],
				["Chiusa? Vieni, ti mostro il punto dove il deserto sembra piatto e non lo è."],
				["Ha provato con la mano tesa, quel ragazzo che arriva sempre nuovo.", "Ha detto «lontano». (mano tesa) È un inizio."],
			],
			"riempimento": [
				["(mano tesa) Il pollice largo un dito, il braccio teso: quello è il mio strumento.", "Costa niente e non si rompe."],
				["Di notte le distanze cambiano. Non le distanze: gli occhi."],
				["Miraggio dice di aver visto una cosa enorme.", "(mano tesa) Nel deserto le cose lontane sembrano grandi. Ma qualcosa ha visto."],
			],
		},
	},
	"w14-elmo": {
		"funzione": "specialista",
		"world": 14,
		"nome": "Elmo",
		"ruolo": "Compilatore della Biblioteca delle Voci",
		"registro": "burbero",
		"tic": "taglia l'aria con la mano per chiudere il discorso",
		"ticMarker": "taglia l'aria",
		"convinzione": "Se so come finisce, ho capito.",
		"bisogno": "Deve riassumere una cronaca in cui il finale non è il punto.",
		"arco": [
			"Riduce ogni testo alla trama e considera il resto decorazione.",
			"Riassume due racconti dello stesso fatto e gli escono identici, mentre non lo sono affatto.",
			"Nei suoi riassunti scrive anche chi racconta, e da dove guarda.",
		],
		"battute": {
			"richiesta": [
				["(taglia l'aria con la mano) Questa cronaca. Trecento pagine.", "So come finisce. E non ho capito niente.", "Leggila tu e dimmi cosa succede in mezzo."],
				["La deposizione del secondo testimone va riassunta.", "Non il finale. Il finale ce l'ho.", "Voglio sapere in che punto cambia idea."],
				["Ottavia racconta la stessa storia in un altro modo e sembra un'altra storia.", "(taglia l'aria) Non è possibile e succede.", "Va' ad ascoltarla. Poi tornerai a spiegarmi cosa cambia se i fatti sono uguali."],
			],
			"consolazione": [
				["(taglia l'aria) Chiuso. Non ci pensare più oggi.", "Un riassunto sbagliato lo si rifà. Non è una condanna, è una pagina."],
				["Senti, una cosa.", "Io leggo per arrivare in fondo e mi perdo tutto. Tu ti sei fermata dove non capivi. È meglio, non peggio."],
			],
			"stadio0": [
				["Riassunto: il vecchio parte, il vecchio torna, il vecchio muore.", "(taglia l'aria con la mano) Fine. Trecento pagine in una riga."],
				["Il resto sono aggettivi.", "Gli aggettivi non cambiano come finisce."],
				["(taglia l'aria) Dammi un libro, ti do la trama in dieci secondi."],
			],
			"stadio1": [
				["Ho riassunto due cronache diverse. Sono venute identiche.", "Ma non erano identiche, Eli. Erano opposte."],
				["Una la raccontava chi partiva. L'altra chi restava.", "(taglia l'aria) …e nel riassunto questa cosa spariva."],
				["Se due racconti opposti hanno lo stesso riassunto…", "…allora il mio riassunto butta via proprio la parte che conta."],
			],
			"stadio2": [
				["Riassunto nuovo: «Il vecchio parte, e chi resta lo racconta come un abbandono».", "(taglia l'aria) Una riga in più. Ma è un'altra storia."],
				["Chi racconta non è una decorazione. È metà del fatto."],
				["Ottavia racconta la stessa storia da tre punti di vista, di mestiere.", "L'ho sempre trovato un vezzo. Era una tecnica."],
			],
			"reazione": [
				["Si è messo a leggere un verbale ad alta voce.", "(taglia l'aria) Tredici voci registrate. Ne ho contate tredici, e i presenti erano dodici."],
				["Fatto. (taglia l'aria) La riassumo in una riga? No. Merita tre."],
				["Sai chi è passato? Quello che comincia sempre dall'inizio. Mi ha raccontato la giornata.", "(taglia l'aria) Quattro volte. Ogni volta diversa. Utilissimo, in realtà."],
			],
			"riempimento": [
				["(taglia l'aria) La Biblioteca ha ottomila voci e nessun indice.", "Ci sto lavorando. Ci lavoro da nove anni."],
				["C'è un verbale della seduta del Silenzio.", "Lo sto trascrivendo. (taglia l'aria) Lentamente, per una volta."],
				["Prefazio racconta solo l'inizio delle storie.", "Io solo la fine. (taglia l'aria) Insieme faremmo un narratore intero."],
			],
		},
	},
	"w14-ottavia": {
		"funzione": "testimone",
		"world": 14,
		"nome": "Ottavia",
		"ruolo": "Narratrice della Biblioteca delle Voci",
		"registro": "divertente",
		"tic": "cambia voce a metà frase per fare un altro personaggio",
		"ticMarker": "(cambia voce)",
		"convinzione": "Raccontare bene è un mestiere, non un modo di capire.",
		"bisogno": "Vuole sapere perché la stessa storia detta da un altro sembri un'altra storia.",
		"arco": [
			"Racconta lo stesso fatto da tre prospettive per intrattenere, e lo considera un numero da fiera.",
			"Si accorge che il pubblico capisce cose diverse a seconda di chi racconta, e la cosa la spaventa.",
			"Usa le prospettive per far capire, non per stupire, e insegna a Elmo a metterle nei riassunti.",
		],
		"battute": {
			"richiesta": [
				["Vieni, ti racconto la storia del Ponte. (cambia voce) «Io non ci passo!»", "L'ho raccontata in tre modi e tre volte hanno pianto persone diverse.", "Va' a sentirla dalla vecchia del ponte. Poi mi dici quale versione è la sua."],
				["Nella Biblioteca c'è un rotolo con la stessa storia scritta due volte.", "Stessi fatti. (cambia voce) «E allora dov'è la differenza, eh?»", "Vacci tu, che hai pazienza. Io mi metto a recitarla e non finisco più."],
				["Ho una scommessa con me stessa.", "(cambia voce) «Chi parla per primo ha ragione.» Sarà vero?", "Va' a leggere le deposizioni nell'ordine contrario. Voglio saperlo."],
			],
			"consolazione": [
				["(cambia voce) «Disastro! Rovina! Catastrofe!»", "…no, dai. È solo un tentativo andato storto. Se ne fa un altro."],
				["Ehi. Nessuna storia viene bene la prima volta che la racconti.", "Io le rovino tutte, la prima volta. Poi le riprendo dal punto in cui mi sono annoiata."],
			],
			"stadio0": [
				["La stessa storia in tre voci! (cambia voce) Il marinaio! (cambia voce) La moglie! (cambia voce) Il porto!", "Applausi facili, questi."],
				["È un numero. Funziona sempre.", "(cambia voce) «E il porto disse: io li ho visti tutti partire.»"],
				["Capire è un'altra cosa. Io intrattengo."],
			],
			"stadio1": [
				["Ho fatto la storia del naufragio in tre voci.", "(cambia voce) Col marinaio ridevano. (cambia voce) Con la moglie no.", "Stessi fatti, Eli. Stessissimi."],
				["Se la voce cambia quello che il pubblico capisce…", "…allora non è un numero. È qualcosa che fa qualcosa."],
				["(cambia voce) «E chi racconta?» — questa domanda me la faccio adesso prima di cominciare."],
			],
			"stadio2": [
				["Tre voci per far capire, non per stupire.", "(cambia voce) È molto meno divertente e molto più utile. Ah no, è divertente uguale."],
				["Elmo adesso scrive nei riassunti chi racconta.", "L'ho convinto in due settimane. Record personale."],
				["(cambia voce) «Da dove guardi?» Se non lo dici, la storia è zoppa."],
			],
			"reazione": [
				["Hai svegliato l'apparato! (cambia voce) «E la macchina disse: mi ricordo tutto.»", "Battuta mia. L'apparato non ha detto niente."],
				["(cambia voce) «Riuscita!» Te la racconto in tre voci? …va bene, in una."],
				["(cambia voce) «Piacere, Sesto!» Quello lì è il mio pubblico preferito.", "(cambia voce) Ogni volta è la prima volta. Per lui e quindi anche per me."],
			],
			"riempimento": [
				["(cambia voce) «Nella Biblioteca» — no, aspetta, questa comincia male."],
				["Ottomila voci qui dentro e nessuno le ascolta.", "(cambia voce) «Ci ascoltiamo fra noi», dicono i libri."],
				["Il verbale che sta trascrivendo Elmo è agghiacciante.", "Non per quello che dice. Per come lo dice: come se fosse ovvio."],
			],
		},
	},
	"w15-gru": {
		"funzione": "specialista",
		"world": 15,
		"nome": "Gru",
		"ruolo": "Manutentore della Città Macchina",
		"registro": "buffo",
		"tic": "dà un colpetto alle macchine per convincerle",
		"ticMarker": "colpetto",
		"convinzione": "L'errore è solo sfortuna.",
		"bisogno": "La stessa macchina si guasta ogni martedì e lui non sa perché.",
		"arco": [
			"Riavvia e dà colpetti, e quando riparte considera il problema risolto.",
			"Il guasto torna sempre di martedì: la sfortuna non ha un calendario.",
			"Legge il messaggio d'errore invece di riavviare, e trova la causa in sei minuti.",
		],
		"battute": {
			"richiesta": [
				["(dà un colpetto alla macchina) Questa qua si guasta ogni martedì.", "Ogni. Martedì. Non è sfortuna, è un appuntamento.", "Vieni a guardarla di martedì, che io da solo mi arrabbio."],
				["Il nastro tre si ferma dopo un po'. Non so dopo quanto.", "Gli do un colpetto e riparte. Poi si ferma di nuovo.", "Va' a segnare a che ora si ferma. Tre volte, non una."],
				["Su un pannello di comandi una riga è barrata.", "Qualcuno prima di me sapeva cos'era e l'ha cancellata.", "Vacci tu. Se leggi cosa c'era sotto, siamo a cavallo."],
			],
			"consolazione": [
				["(colpetto alla panca) Non è ripartita? Normale.", "Le macchine sono testarde come le persone. Ci si riprova con più calma."],
				["Ehi, aspetta.", "Se si fosse guastata a caso saremmo fritti. Se si è guastata per un motivo, il motivo lo troviamo. È una buona notizia."],
			],
			"stadio0": [
				["(dà un colpetto alla caldaia) Vedi? Riparte.", "Era sfortuna."],
				["Il messaggio d'errore non lo leggo mai. È scritto per le macchine, mica per noi."],
				["(colpetto) Riavvio, colpetto, e via. Trent'anni di carriera."],
			],
			"stadio1": [
				["Si è guastata di martedì. Come martedì scorso.", "(colpetto) E quello prima. Tre martedì, Eli."],
				["La sfortuna non guarda il calendario.", "…o sì? No. No, vero?"],
				["Pila tiene un quaderno con tutti i guasti e la data.", "(colpetto) Ha nove anni e ha capito prima di me."],
			],
			"stadio2": [
				["Ho letto il messaggio d'errore. Diceva esattamente cosa non andava.", "(colpetto per abitudine) Sei minuti invece di due giorni."],
				["Il martedì fanno il lavaggio dei condotti e l'umidità arriva al quadro.", "Non era sfortuna. Era martedì."],
				["Un errore è una macchina che ti parla.", "(colpetto) Io per trent'anni le ho date pacche a una che chiedeva aiuto."],
			],
			"reazione": [
				["L'apparato si è acceso senza colpetti!", "(colpetto lo stesso) Scusa. Riflesso."],
				["È andata! Segno la data. Ho un quaderno adesso, come Pila."],
				["Il tipo che si ripresenta ogni cinque minuti ha dato un colpetto a una macchina.", "(colpetto) Gli ho detto di leggere prima. Se lo è dimenticato, ma ci ha provato."],
			],
			"riempimento": [
				["La Città Macchina ha settori che nessuno visita da secoli.", "(colpetto a un tubo) Questo suona pieno. Non dovrebbe."],
				["C'è un volume, qui sotto, senza porta.", "Alimentato. Da quattrocento anni. (colpetto) Non ci penso."],
				["Ronzino è convinto di essere un automa.", "(colpetto amichevole) Non gli dico niente. Sta bene così."],
			],
		},
	},
	"w15-pila": {
		"funzione": "testimone",
		"world": 15,
		"nome": "Pila",
		"ruolo": "Bambina della Città Macchina, ha inventato il registro dei guasti",
		"registro": "curioso",
		"tic": "chiede sempre «e quando è successo?»",
		"ticMarker": "quando è successo",
		"convinzione": "Scrivere le cose è da grandi, io gioco e basta.",
		"bisogno": "Vuole capire se il suo quaderno serve davvero o se è solo un gioco.",
		"arco": [
			"Annota guasti, date e cause perché le piace fare le liste.",
			"Nel quaderno compare uno schema che nessun adulto aveva visto: i martedì.",
			"Il suo quaderno diventa il registro ufficiale della Città e lei insegna a Gru a compilarlo.",
		],
		"battute": {
			"richiesta": [
				["E quando è successo? Me lo devi dire, se no non lo scrivo.", "Il nastro tre si è fermato di nuovo e nessuno segna l'ora.", "Vacci tu con l'orologio, per favore."],
				["Ho un quaderno con dentro tutti i guasti di un anno.", "Se lo apri, vedi delle cose. Delle cose strane, a gruppi.", "Va' a leggerlo. E quando è successo l'ultimo, poi me lo dici?"],
				["Nella Rovina c'è una parete piena di tacche a colonne.", "Sembra il mio quaderno ma è di pietra.", "Vacci. Voglio sapere se anche loro scrivevano quando succedevano le cose."],
			],
			"consolazione": [
				["Ok. E quando è successo, esattamente?", "Se me lo dici lo scrivo, e la prossima volta lo sappiamo prima."],
				["Aspetta. Non è colpa tua.", "Nel mio quaderno le prime venti pagine sono tutte sbagliate e le tengo lo stesso."],
			],
			"stadio0": [
				["Guasto numero settantatré. E quando è successo? Martedì.", "Lo scrivo perché mi piace scrivere."],
				["I grandi dicono che è un gioco.", "E quando è successo l'ultimo guasto? Non se lo ricordano. Io sì."],
				["Ho un quaderno per i guasti e uno per i rumori strani."],
			],
			"stadio1": [
				["Eli, guarda: martedì, martedì, martedì, martedì.", "E quando è successo il quinto? Indovina.", "Non è un caso, vero? Non può essere un caso."],
				["Gru dice che è sfortuna. Ma la sfortuna quattro volte di martedì?"],
				["Se scrivere le date fa vedere una cosa che nessuno vedeva…", "…e quando è successo che è diventato un gioco serio?"],
			],
			"stadio2": [
				["Il mio quaderno sta appeso nel capannone. Con la catenella.", "E quando è successo? Ieri. Ci ho messo il nome sopra."],
				["Gru compila la sua parte. Sbaglia le date, ma le scrive."],
				["Non serve essere grandi per tenere un registro.", "Serve solo chiedersi sempre: e quando è successo?"],
			],
			"reazione": [
				["Hai acceso l'apparato! E quando è successo? Adesso! L'ho scritto: «adesso»."],
				["Fatto! Numero, data, causa, esito. E quando è successo: tutto segnato."],
				["Tre volte la stessa cosa, me l'ha detta il ragazzo senza quaderno.", "E quando è successo? Tre volte oggi. L'ho scritto tre volte."],
			],
			"riempimento": [
				["Rumore strano numero dodici: un fischio dal condotto est.", "E quando è successo? Sempre alle undici."],
				["C'è una stanza senza porta laggiù.", "Non l'ho messa nel quaderno dei guasti. Non è un guasto. E quando è successo? Mai."],
				["Ronzino mi ha chiesto di segnare i suoi guasti.", "Non ha guasti. È una persona. Gliel'ho scritto lo stesso, per non offenderlo."],
			],
		},
	},
	"w16-talia": {
		"funzione": "specialista",
		"world": 16,
		"nome": "Talia",
		"ruolo": "Interprete della Frontiera delle Lingue",
		"registro": "caloroso",
		"tic": "si scusa prima e dopo ogni frase",
		"ticMarker": "scus",
		"convinzione": "Ogni parola ha una sola traduzione.",
		"bisogno": "Ha causato un equivoco grave traducendo alla lettera e vuole capire dove ha sbagliato.",
		"arco": [
			"Traduce parola per parola con enorme scrupolo, e genera equivoci di cui si sente in colpa.",
			"Scopre che l'equivoco non nasceva da un errore ma dall'idea che una parola valga una parola.",
			"Traduce l'intenzione, chiede quando non è sicura, e smette di scusarsi per mestiere.",
		],
		"battute": {
			"richiesta": [
				["Scusa se ti disturbo. Scusa davvero.", "Ho tradotto «in bocca al lupo» alla lettera e si è offeso un ambasciatore.", "Vieni con me a rimediare? Scusa ancora."],
				["Mi servirebbe, scusa, una mano al valico.", "C'è un contratto con una clausola che in due lingue dice due cose diverse.", "Va' a leggerlo prima che lo firmino."],
				["Scusa, so che hai da fare.", "Nell'archivio del valico c'è un glossario vecchio, con le frasi fatte accanto.", "Vacci tu. Io là dentro mi metto a chiedere scusa ai libri."],
			],
			"consolazione": [
				["Scusa. È colpa mia, ti ho spiegato male.", "…no, aspetta, non è colpa di nessuno. Si riprova, e stavolta lo guardiamo insieme."],
				["Non ti scusare tu, che tanto lo faccio io per due.", "Ho fatto errori peggiori con più gente davanti. Si va avanti."],
			],
			"stadio0": [
				["Scusa, non volevo interromperti.", "«Actually» vuol dire «attualmente». Scusa, è così, l'ho sul dizionario."],
				["Ogni parola ha la sua. Se sbagli parola, sbagli tutto.", "Scusa se insisto."],
				["Traduco esatto. Scusa se sono lenta, ma esatto."],
			],
			"stadio1": [
				["Ho tradotto «I'm afraid we can't» con «ho paura che non possiamo».", "Scusa… il mercante ha creduto che avessimo davvero paura.", "È saltato un accordo. Per una parola."],
				["«Afraid» lì non voleva dire paura. Voleva dire «mi dispiace».", "Scusa, ma allora una parola non ha una traduzione: ne ha tante."],
				["Marco commercia in sei lingue con cento parole ciascuna.", "Scusa, ma come fa a non sbagliare mai come sbaglio io?"],
			],
			"stadio2": [
				["Traduco quello che vuole dire, non quello che dice.", "E quando non sono sicura, chiedo. Non mi scuso: chiedo."],
				["Scusa — no, non mi scuso. Ci sto lavorando.", "Ho ricucito l'accordo del mercante. Con sei parole diverse da quelle di prima."],
				["Una parola ha una traduzione dentro una frase.", "Fuori dalla frase ha solo delle possibilità."],
			],
			"reazione": [
				["Ha parlato in due lingue insieme, lì dentro. Scusa, mi trema la voce.", "Scusa, mi sono commossa. Diceva la stessa cosa in due modi diversi, e tutti e due giusti."],
				["È andata. Scusa se te lo dico piano: sono contenta."],
				["Scusa: quel ragazzo che si presenta e riscusa ha imparato «hello».", "Lo dice a tutti. Scusa, ma lo trovo bellissimo."],
			],
			"riempimento": [
				["Alla Frontiera passano sei lingue al giorno.", "Scusa, sette. Ho dimenticato quella dei pastori."],
				["C'è una mappa nel deposito che non capisco.", "Scusa, è in una lingua che non è nessuna delle sei."],
				["Tuttolingue parla una lingua inventata da lui.", "Scusa, ma ha una grammatica coerente. L'ho controllata."],
			],
		},
	},
	"w16-marco": {
		"funzione": "testimone",
		"world": 16,
		"nome": "Marco dei Valichi",
		"ruolo": "Mercante di valico, sei lingue da cento parole",
		"registro": "divertente",
		"tic": "conta sulle dita le lingue che parla, sbagliando",
		"ticMarker": "lingue",
		"convinzione": "Capirsi è questione di faccia tosta, non di parole.",
		"bisogno": "Deve firmare un contratto scritto, e la faccia tosta lì non serve.",
		"arco": [
			"Commercia in sei lingue con cento parole ciascuna e ride di chi studia la grammatica.",
			"Un contratto scritto lo mette in ginocchio: cento parole bastano a vendere, non a impegnarsi.",
			"Impara le parole che contano e continua a dire che le altre non servono. Al valico.",
		],
		"battute": {
			"richiesta": [
				["Io parlo sei lingue. Cinque. (conta sulle dita) Sette.", "Comunque: al valico c'è un mercante che non mi capisce e io non capisco lui.", "Vieni a sentire cosa dice. Tu ci hai la scuola."],
				["Devo firmare un contratto scritto e lì la faccia tosta non serve.", "Va' a farti dare la copia in tutte e due le lingue.", "Poi me le leggi accanto, riga per riga."],
				["Sulla pietra del valico ci sono saluti in quattro lingue.", "Quattro. (conta sulle dita) Cinque, forse.", "Vacci. Se somigliano tra loro, voglio sapere perché."],
			],
			"consolazione": [
				["Ma va'! Non ti ha capito? E chi se ne importa.", "Io mi faccio capire a gesti da vent'anni e sbaglio ogni giorno. Riproviamo più forte. No, scherzo: più lento."],
				["Senti, una cosa vera.", "Le lingue non si imparano vincendo. Si imparano facendo figuracce. Ne hai appena fatta una, sei in pari con me."],
			],
			"stadio0": [
				["Sei lingue! …cinque. Sei. (conta sulle dita) Sei.", "Cento parole ciascuna e non ho mai perso un affare."],
				["La grammatica è per chi ha tempo.", "Io ho una mula e un valico da passare prima del buio."],
				["(conta le lingue sulle dita) Con la faccia tosta ne parli sette."],
			],
			"stadio1": [
				["Contratto scritto, Eli. Scritto.", "(conta sulle dita) Sei lingue e non capisco una riga di questa."],
				["A voce mi capiscono tutti. Sulla carta non mi capisce nessuno.", "Non me l'aspettavo, giuro."],
				["Talia dice che serve sapere le parole *esatte*.", "(conta sulle dita) Le mie sono approssimative in sei lingue."],
			],
			"stadio2": [
				["Ho imparato ventidue parole nuove. Quelle dei contratti.", "(conta sulle dita) Adesso sono sei lingue e mezzo."],
				["Al valico bastano cento parole. Lo dico ancora.", "Ma un contratto non è un valico."],
				["Talia non si scusa più a ogni frase.", "(conta sulle dita) Le ho detto: una scusa ogni sei. Come le lingue."],
			],
			"reazione": [
				["Ha detto una cosa in una lingua che non conosco! (conta sulle dita) La numero sette.", "(conta sulle dita) …sette. Adesso sono sette."],
				["Affare fatto! Cioè, missione. (conta sulle dita) Per me è lo stesso."],
				["Un sasso! Me l'ha venduto quello con la memoria corta.", "In tre lingue. (conta sulle dita) Gliel'ho pagato, per il coraggio."],
			],
			"riempimento": [
				["Al valico si impara la lingua che serve, non quella che piace.", "(conta sulle dita) Nessuna di queste sei mi piace, tra l'altro."],
				["Nel deposito c'è una mappa di posti che non ho mai sentito.", "E io ho sentito tutto, (conta sulle dita) in sei lingue."],
				["La mula capisce una lingua sola e la capisce benissimo.", "Tutto sta a essere chiari."],
			],
		},
	},
	"w17-nerea": {
		"funzione": "specialista",
		"world": 17,
		"nome": "Nerea",
		"ruolo": "Palombara dell'Oceano delle Forze",
		"registro": "curioso",
		"tic": "trattiene il fiato anche mentre parla",
		"ticMarker": "fiato",
		"convinzione": "Il corpo sa da solo quanto reggere.",
		"bisogno": "Vuole arrivare al relitto profondo e il corpo, stavolta, non basta.",
		"arco": [
			"Scende sempre più giù fidandosi delle sensazioni, e ogni volta va bene.",
			"Sviene a meno trentadue metri: il corpo l'aveva avvisata e lei non sapeva leggere il segnale.",
			"Calcola prima di scendere, e arriva più a fondo di quando andava a sentimento.",
		],
		"battute": {
			"richiesta": [
				["(trattiene il fiato) Il relitto profondo. Ci sono arrivata a metà.", "Poi il petto mi si è stretto e sono risalita.", "Vieni a vedere lo strumento di Coral. Io i suoi numeri non li leggo."],
				["Sul banco basso ci vuole una discesa di prova.", "Segna la profondità a ogni sosta. Anche se ti sembra inutile, segnala.", "Io a scendere sono brava. A scrivere no."],
				["Nella secca est riposa una campana da palombaro.", "Dentro ci resta l'aria. Sott'acqua. Non chiedermi come.", "Vacci e guarda fin dove arriva l'acqua dentro la campana."],
			],
			"consolazione": [
				["(riprende fiato) Sei risalita. È la cosa giusta.", "Chi risale può riprovare. È l'unica regola che conta qua sotto."],
				["Ferma. Respira con me: dentro, e fuori.", "Ecco. Adesso il secondo tentativo è già diverso dal primo."],
			],
			"stadio0": [
				["(trattiene il fiato) Quando è troppo, il corpo te lo dice.", "Basta ascoltarlo."],
				["Meno venti, meno venticinque. Scendo finché sento che va.", "I conti li fanno quelli che hanno paura."],
				["(riprende fiato) Scusa. Parlo trattenendo. Abitudine del mestiere."],
			],
			"stadio1": [
				["Sono svenuta a meno trentadue, Eli.", "(trattiene il fiato) Il corpo me l'aveva detto. Io non l'ho capito."],
				["Coral ha smesso di scendere e sa dire esattamente perché.", "Ha i numeri. Io ho le sensazioni. Una delle due cose si può spiegare a un altro."],
				["Se il corpo parla e io non so la sua lingua…", "(trattiene il fiato) …allora non lo stavo ascoltando. Lo stavo indovinando."],
			],
			"stadio2": [
				["Pressione, tempo, respiro. Tre numeri prima di ogni immersione.", "(trattiene il fiato) E adesso arrivo a meno quaranta. Più giù di prima."],
				["Il corpo sa, ma non parla italiano.", "I conti sono la traduzione."],
				["Ho insegnato la tabella a due ragazzi del molo.", "(trattiene il fiato) Se svengo io almeno non svengono loro."],
			],
			"reazione": [
				["Ha misurato la pressione della fossa, da solo.", "(trattiene il fiato) Il numero che ha dato è quello che avevo calcolato. A meno di due."],
				["(riprende fiato) Risalita, e chiusa. Vieni, ti presto la muta piccola."],
				["È sceso di tre metri, quello per cui ogni volta è la prima volta.", "(trattiene il fiato) Poi si è dimenticato di risalire. L'ho tirato su io."],
			],
			"riempimento": [
				["(trattiene il fiato) Le insegne del molo si sono sbiancate tutte.", "Tranne una parola, che è rimasta. Non ti dico quale: vai a vederla."],
				["A meno quaranta il buio è blu, non nero.", "Nessuno mi crede finché non scende."],
				["Scafandro fa il palombaro e ha paura dell'acqua.", "(trattiene il fiato) È l'uomo più coraggioso del molo, e non se ne accorge nessuno."],
			],
		},
	},
	"w17-coral": {
		"funzione": "testimone",
		"world": 17,
		"nome": "Coral",
		"ruolo": "Ex palombaro, tiene i conti delle immersioni",
		"registro": "burbero",
		"tic": "brontola i numeri come se fossero insulti",
		"ticMarker": "numer",
		"convinzione": "Chi ha smesso non ha più niente da insegnare.",
		"bisogno": "Vuole che qualcuno usi i suoi calcoli prima che diventino inutili.",
		"arco": [
			"Ha smesso di scendere, sa perfettamente perché, e considera la sua tabella un cimelio.",
			"Nerea sviene e le sue tabelle diventano di colpo una cosa viva.",
			"Insegna il calcolo ai giovani del molo e smette di chiamarsi «uno che ha smesso».",
		],
		"battute": {
			"richiesta": [
				["Ho quattro quaderni di numeri e nessuno che li usi.", "Tempi, profondità, soste. Trent'anni di immersioni.", "Prendili. Non mi ringraziare: portameli indietro usati."],
				["Nerea vuole scendere al relitto e non fa i conti.", "I numeri non sono un'opinione, sono l'aria che le resta.", "Va' a calcolarle la sosta. Poi glieli sbatti in faccia da parte mia."],
				["Nel magazzino c'è una tabella incisa su ottone.", "Numeri a coppie. Uno è la profondità, l'altro non l'ho mai capito.", "Vacci tu. Se lo capisci, mi togli un peso di trent'anni."],
			],
			"consolazione": [
				["Il conto non torna. Bene: meglio adesso che a venti metri.", "Rifallo. I numeri non si offendono se li fai due volte."],
				["Ma smettila di fare quella faccia.", "Ho sbagliato una tabella nel '38 e siamo tornati su tutti lo stesso. Si rifà, punto."],
			],
			"stadio0": [
				["Meno trentacinque, otto minuti, risalita a tappe.", "Numeri. A nessuno interessano i numeri di uno che non scende più."],
				["Ho una tabella appesa lì da sei anni. Guardala pure.", "Tanto non la guarda nessuno."],
				["Ho smesso perché i numeri dicevano di smettere.", "Non è coraggio, è aritmetica."],
			],
			"stadio1": [
				["Nerea è svenuta. Meno trentadue.", "Sulla mia tabella, meno trentadue con il suo tempo è rosso.", "Rosso, capisci? I numeri l'avevano scritto."],
				["Se avesse guardato la tabella non sarebbe successo.", "E la tabella è lì da sei anni. Colpa mia che non l'ho mai spiegata."],
				["Uno che ha smesso ha i numeri di uno che c'è stato.", "…detto così suona quasi utile."],
			],
			"stadio2": [
				["Corso di calcolo, giovedì, sul molo. Sei ragazzi.", "Numeri e tabelle. Vengono lo stesso, incredibilmente."],
				["Nerea scende più giù di prima e torna sempre su.", "Sono i miei numeri, con il suo fiato."],
				["Non sono «uno che ha smesso».", "Sono uno che è tornato indietro con le misure. È diverso."],
			],
			"reazione": [
				["È uscita una tabella di decompressione. Numeri, finalmente.", "Uguale alla mia. Con due numeri più prudenti. Aveva ragione lui."],
				["Finito? Bene. Prendi la tabella piccola, quella plastificata. Regalo."],
				["Una riga della tabella l'ha imparata quello che non tiene il conto di niente.", "Una. Ma è la riga che salva la vita, quindi va bene."],
			],
			"riempimento": [
				["I numeri non ti vogliono bene e non ti odiano.", "Per questo di loro ti puoi fidare."],
				["Sul molo le insegne si sono scolorite tutte insieme, un inverno.", "Poi su una è ricomparsa una parola sola. Nessuno l'ha riscritta."],
				["Scafandro mi chiede i numeri ogni giorno.", "Non scende mai. Ma li vuole sapere lo stesso. Rispetto."],
			],
		},
	},
	"w18-silo": {
		"funzione": "specialista",
		"world": 18,
		"nome": "Silo",
		"ruolo": "Organista della Cattedrale del Suono",
		"registro": "solenne",
		"tic": "conta il riverbero a occhi chiusi",
		"ticMarker": "riverbero",
		"convinzione": "Il piano qui non si sente.",
		"bisogno": "Deve accompagnare una voce sola e l'organo la copre sempre.",
		"arco": [
			"Suona sempre forte perché la navata mangia i suoni deboli, e ne ha fatto una dottrina.",
			"Bea canta piano in un punto preciso e la si sente in fondo: non era il volume, era il posto.",
			"Suona piano nei punti giusti, e per la prima volta l'organo accompagna invece di coprire.",
		],
		"battute": {
			"richiesta": [
				["Stasera accompagno una voce sola e l'organo la copre sempre.", "Ho contato il riverbero: quattro secondi buoni sotto la volta.", "Vieni in cantoria. Voglio provare con te ad ascoltare, non a suonare."],
				["In fondo alla navata non c'è nessuno ad ascoltare.", "Io suono, tu stai laggiù e mi dici quando le parole si impastano.", "Il riverbero da qui non lo sento: sono dentro al suono."],
				["Nella cripta dorme una registrazione di cent'anni fa.", "Un solo cantore, nessun organo. E si sente ogni parola.", "Vacci ad ascoltarla. Poi mi spieghi perché a loro riusciva."],
			],
			"consolazione": [
				["(chiude gli occhi) Contiamo il riverbero insieme. Uno… due… tre… quattro.", "Ecco: è passato. Anche l'errore passa così. Riprendiamo dalla battuta prima."],
				["La nota non è la cosa che hai sbagliato.", "È il silenzio che non hai lasciato. Si impara, e ci vogliono anni. Hai tempo."],
			],
			"stadio0": [
				["Sette secondi di riverbero. Sette.", "In sette secondi un pianissimo muore prima di arrivare in fondo."],
				["Qui o forte o niente. Non è brutalità: è acustica."],
				["(a occhi chiusi, conta il riverbero) …cinque, sei, sette. Sempre sette."],
			],
			"stadio1": [
				["Bea ha cantato piano vicino al terzo pilastro.", "L'ho sentita dal fondo. Piano.", "Sette secondi di riverbero e l'ho sentita."],
				["Non era il volume. Era dove stava.", "Quarant'anni che spingo, e bastava spostarsi di sei passi."],
				["(conta il riverbero) In certi punti la navata restituisce, in altri divora.", "Perché nessuno me l'ha mai detto?"],
			],
			"stadio2": [
				["Ho suonato pianissimo l'introito. Nel punto giusto.", "Riverbero al mio servizio, per la prima volta in quarant'anni."],
				["La Cattedrale non è un nemico da vincere a forza.", "È uno strumento anche lei. Va conosciuta, non sopraffatta."],
				["Accompagno Bea adesso. (conta il riverbero) Sotto la sua voce, non sopra."],
			],
			"reazione": [
				["Ha fatto suonare la canna maggiore. Sei secondi di riverbero.", "(conta il riverbero) Nove secondi. Nove. Non era mai successo."],
				["Hai concluso. Suono qualcosa per te? Piano, però. Ci tengo a farlo piano."],
				["È venuto alle prove quello che entra sempre come se fosse la prima volta.", "Ha ascoltato in silenzio per un'ora. (conta il riverbero) Sette secondi per sessanta minuti."],
			],
			"riempimento": [
				["(conta il riverbero) Le pietre della navata sono di due epoche diverse.", "Si sente. Restituiscono in modo diverso."],
				["C'è un registro dei turni di guardia, in sacrestia.", "Quattrocento anni. Nessun cambio. Non l'ho mai capito e non chiedo."],
				["Controcanto canta sempre mezzo tono sotto.", "(conta il riverbero) Nel punto giusto della navata, però, è quasi bello."],
			],
		},
	},
	"w18-bea": {
		"funzione": "testimone",
		"world": 18,
		"nome": "Bea",
		"ruolo": "Cantrice della Cattedrale, ha mappato l'eco",
		"registro": "divertente",
		"tic": "prende in giro l'acustica come fosse una persona",
		"ticMarker": "navata",
		"convinzione": "Quello che faccio è un trucco, non musica.",
		"bisogno": "Vuole che qualcuno prenda sul serio la sua mappa dell'eco.",
		"arco": [
			"Sa dove mettersi per farsi sentire e lo considera una furbizia da chierichetta.",
			"Silo le chiede la mappa, e la furbizia diventa un metodo con dei punti segnati.",
			"La mappa dell'eco è appesa in sacrestia e la usano tutti i cantori.",
		],
		"battute": {
			"richiesta": [
				["La navata è una gran ficcanaso: ti ripete tutto addosso.", "Ho fatto una mappa dei punti dove l'eco sparisce.", "Vieni a provarli con me. Uno per uno."],
				["Sotto il pulpito, un punto solo: sussurri lì e ti sente il fondo.", "Un punto! Grande come un piede!", "Vacci e prova. Poi torna a dirmi se sono matta io o la navata."],
				["Nella cripta c'è un disegno della volta con dei cerchi sopra.", "Secondo me qualcuno l'eco l'aveva già mappata prima di me.", "Va' a guardarlo. Se è così, la navata mi deve delle scuse."],
			],
			"consolazione": [
				["Colpa della navata, sicuro. È sempre colpa sua.", "Dai, si riprova due passi più in là."],
				["Ehi, ascolta.", "Io ho girato questa chiesa per un anno prima di trovare il primo punto buono. Un anno. Tu sei alla prima settimana."],
			],
			"stadio0": [
				["Mi metto qui e mi sentono in fondo. Mi metto lì e mi mangia.", "La navata ha i suoi favoriti, e io la corrompo."],
				["Non è cantare. È sapere dove mettere i piedi."],
				["La navata è permalosa: se la sfidi ti copre, se la assecondi ti porta."],
			],
			"stadio1": [
				["Silo mi ha chiesto la mappa. LA MAPPA.", "Quella che ho disegnato di nascosto sul retro di un salterio."],
				["Se un organista di quarant'anni me la chiede…", "…allora non era un trucco da chierichetta."],
				["Ho segnato undici punti buoni e sei da evitare.", "La navata è complicata, ma non è cattiva. Solo complicata."],
			],
			"stadio2": [
				["La mappa è appesa in sacrestia. Con i punti numerati.", "La navata adesso è dalla nostra parte, e lo sa."],
				["Silo suona piano. PIANO. Sotto di me.", "Non credevo che l'avrei visto succedere."],
				["Un trucco che funziona sempre e che puoi insegnare non è un trucco.", "È una cosa che hai capito. La navata è d'accordo."],
			],
			"reazione": [
				["Hai svegliato l'apparato! La navata ha risuonato tutta insieme.", "Mai sentita così: sembrava contenta anche lei."],
				["Chiusa! Ti canto una nota nel punto sette della navata? È il mio preferito."],
				["Si è presentato a metà del canto, quel tale.", "Tre volte. La navata gliel'ha rimandato indietro tre volte."],
			],
			"riempimento": [
				["Punto quattro: sotto il rosone. Ci sussurri e ti sentono in sacrestia.", "La navata fa la pettegola."],
				["Il turno di guardia in sacrestia non è mai cambiato in quattrocento anni.", "Chiedo, e nessuno risponde. Anche la navata tace, e a lei non capita mai."],
				["Controcanto sta sempre mezzo tono sotto.", "L'ho messo nel punto sei, quello che divora. Adesso stona in silenzio."],
			],
		},
	},
	"w19-numa": {
		"funzione": "specialista",
		"world": 19,
		"nome": "Numa",
		"ruolo": "Epigrafista della Necropoli delle Radici",
		"registro": "burbero",
		"tic": "lucida le lapidi mentre parla",
		"ticMarker": "lapid",
		"convinzione": "La lingua di prima era quella giusta: le parole di oggi sono corrotte.",
		"bisogno": "Deve datare un'iscrizione e la lingua «pura» che cerca non è mai esistita.",
		"arco": [
			"Considera ogni parola moderna una degradazione e le epigrafi l'unica lingua vera.",
			"Trova un'epigrafe antica piena di parole «storpiate»: anche i Primi cambiavano la lingua.",
			"Data le iscrizioni proprio dai cambiamenti, e chiama il mutamento «la cosa più antica che c'è».",
		],
		"battute": {
			"richiesta": [
				["(lucida la lapide) Questa iscrizione va datata e io non ci riesco.", "Le parole non sono né vecchie né nuove. Sono in mezzo.", "Vieni a leggerla. Forse tu non hai i miei pregiudizi."],
				["Tre lapidi del settore basso vanno confrontate.", "Stessa parola, tre forme diverse. Una delle tre è quella «pura», immagino.", "Va' a copiarle tutte e tre. Poi ne parliamo."],
				["C'è un'iscrizione che ho lasciato indietro per rabbia.", "(lucida la pietra) È scritta in una lingua storpiata, di quelle che disprezzo.", "Vacci tu. E dimmi se la capisci meglio di quelle giuste."],
			],
			"consolazione": [
				["Non l'hai sciolta. Neanche io, in trent'anni.", "(lucida la lapide) Siamo in buona compagnia. Si ricomincia dalla prima riga."],
				["Alzati da lì.", "Sbagliare una traduzione è meno grave che rifiutarsi di provarla. Tu ci hai provato."],
			],
			"stadio0": [
				["(lucida la lapide) Qui c'è scritto in latino vero.", "Non come parlate voi."],
				["«Sgrembo», «friscolo». Roba inventata da bambini.", "Il latino non lo inventava nessuno: era."],
				["(lucida la lapide) Ogni parola nuova è una parola persa."],
			],
			"stadio1": [
				["Eli, guarda la lapide del settore quinto.", "(lucida la lapide) Parole che io chiamerei storpiate. E ha ottocento anni."],
				["Se già allora storpiavano…", "…allora la lingua giusta a quale anno la fisso?"],
				["(lucida la lapide) Ho cercato una lingua pura per trent'anni.", "Comincio a sospettare che non ci sia mai stata."],
			],
			"stadio2": [
				["Le parole cambiano sempre. Sono i cambiamenti a datare l'epigrafe.", "(lucida la lapide) La lingua non decade: si muove."],
				["Ho datato tre iscrizioni in una settimana. Dai cambiamenti, non malgrado."],
				["Fiorina chiama le piante con nomi di ottocento anni fa e non lo sa.", "(lucida la lapide) La lingua vecchia non è morta: sta nel suo orto."],
			],
			"reazione": [
				["Una firma si è incisa nella pietra.", "(lucida la lapide) Un nome cancellato e un posto: il tredicesimo. Non chiedermi altro."],
				["Missione conclusa. Ti pulisco una lapide in tuo onore. È il massimo che offro."],
				["Un'epigrafe l'ha letta quello che si rinomina da solo.", "(lucida la lapide) Male. Ma l'ha letta, e nessuno gliel'aveva chiesto."],
			],
			"riempimento": [
				["(lucida la lapide) Il muschio protegge la pietra e cancella le lettere.", "Salva e distrugge insieme. Come tante cose qui."],
				["Nel settore chiuso c'è un progetto, non una tomba.", "Un disegno tecnico. Firmato. (lucida la lapide) Vacci tu."],
				["Lapidario legge le epigrafi come fossero notizie del giorno.", "(lucida la lapide) A volte lo sono."],
			],
		},
	},
	"w19-fiorina": {
		"funzione": "testimone",
		"world": 19,
		"nome": "Fiorina",
		"ruolo": "Erborista della Necropoli",
		"registro": "sognante",
		"tic": "chiama le piante con nomi che nessuno usa più",
		"ticMarker": "chiamo",
		"convinzione": "I nomi che uso me li sono inventati da bambina.",
		"bisogno": "Vuole sapere da dove le sono venuti certi nomi che non ha imparato da nessuno.",
		"arco": [
			"Chiama le erbe con nomi strani che crede propri, e non li dice a nessuno per non sembrare sciocca.",
			"Numa riconosce i suoi nomi su una lapide di ottocento anni fa.",
			"Capisce di essere l'ultima parlante di una lingua e comincia a insegnarla ai bambini.",
		],
		"battute": {
			"richiesta": [
				["Io la chiamo «erba del sonno». Nessuno la chiama più così.", "Ma sulla lapide del settore nord c'è scritto un nome che le somiglia.", "Vacci a vedere. Ho paura di andarci io."],
				["Una pianta la chiamo con un nome che non mi ha insegnato nessuno.", "Nessuno, capisci? E allora da dove mi è venuto?", "Va' nell'erbario vecchio e cercalo. Voglio sapere se esisteva prima di me."],
				["Nella Necropoli crescono tre erbe che io chiamo come sorelle.", "Hanno nomi che fanno lo stesso suono in fondo.", "Vacci e guarda se anche i vecchi le mettevano insieme."],
			],
			"consolazione": [
				["Vieni a sederti fra le radici.", "Le cose che non tornano subito le chiamo «da riprovare». Anche questa."],
				["Ti dico un segreto.", "Io sbaglio i nomi ogni giorno e le piante non si sono mai offese. Riprova con calma."],
			],
			"stadio0": [
				["Questa la chiamo «sanguinella». Non so perché.", "Mia nonna la chiamava così, credo. O l'ho inventato io."],
				["I nomi veri delle piante stanno sui libri.", "I miei sono nomi da orto, di quelli che non contano."],
				["La chiamo «vespertina» perché apre di sera.", "…o forse si chiama davvero così. Non ricordo più."],
			],
			"stadio1": [
				["Numa ha visto «sanguinella» scritta su una lapide.", "Ottocento anni, Eli. Io la chiamo così da sempre."],
				["Se un nome che credevo mio sta su una pietra di ottocento anni fa…", "…allora non l'ho inventato. L'ho ricevuto."],
				["Quanti altri ne ho, di nomi così? Li chiamo tutti i giorni senza sapere cosa sono."],
			],
			"stadio2": [
				["Ne abbiamo trovati quarantuno sulle lapidi. Quarantuno nomi miei.", "Io li chiamo come li chiamavano loro, e non lo sapevo."],
				["Insegno i nomi ai bambini dell'orto.", "Se li chiamano loro, non finiscono con me."],
				["Non sono l'ultima. Sono quella che è arrivata fin qui portandoli.", "Che è un'altra cosa, e molto più bella."],
			],
			"reazione": [
				["Ha detto un nome di pianta che conosco! Proprio come lo chiamo io.", "L'ho chiamata così tutta la vita. Lui pure."],
				["Finita? Ti do una talea di sanguinella. Chiamala come vuoi, ma chiamala."],
				["Mi ha chiesto come chiamo quella pianta, quello che perde i nomi.", "Gliel'ho detto tre volte. La quarta l'ha detto lui."],
			],
			"riempimento": [
				["Nel settore chiuso cresce una pianta che chiamo «guardiana».", "Sta lì sopra un disegno inciso. Non ci vado più."],
				["Le radici della Necropoli tengono insieme le pietre.", "Chi ha costruito qui lo sapeva."],
				["Lapidario legge le epigrafi ad alta voce.", "Io le ascolto mentre innaffio. Certe parole le chiamo anch'io."],
			],
		},
	},
	"w20-sferza": {
		"funzione": "specialista",
		"world": 20,
		"nome": "Sferza",
		"ruolo": "Tecnica dei quadri della Tempesta",
		"registro": "buffo",
		"tic": "batte le nocche sui quadri per «svegliarli»",
		"ticMarker": "nocche",
		"convinzione": "Se non legge, spingi di più.",
		"bisogno": "Ha bruciato tre sensori in una settimana e non sa più cosa spingere.",
		"arco": [
			"Quando un sensore non legge alza la potenza, e finora ha sempre funzionato. Quasi.",
			"Brucia tre sensori: la potenza non era la cura, era la causa.",
			"Cerca il motivo per cui un sensore non legge, e in un mese non ne brucia nemmeno uno.",
		],
		"battute": {
			"richiesta": [
				["(batte le nocche sul quadro) Questo qui non legge più niente.", "Ho spinto e ho bruciato il terzo sensore in una settimana. Il terzo!", "Vieni a guardarlo prima che io ci dia un'altra nocca."],
				["Il quadro di riserva non l'ha mai misurato nessuno.", "Io se non legge spingo. Tu invece guarda cosa dice mentre spingo piano.", "Segna tutto, anche i numeri piccoli."],
				["Nella sala fulmini è rimasto un quadro dei Primi.", "Ha una specie di valvola che si stacca da sola quando si esagera.", "Vacci a vedere. Se capisci come fa, io smetto di bruciare roba."],
			],
			"consolazione": [
				["(nocche sul tavolo) Bruciato? Buono. Adesso sai un limite in più."],
				["Ehi, non fare quella faccia.", "Io ne ho fusi tre in sette giorni e sono ancora qua. Riproviamo con meno foga."],
			],
			"stadio0": [
				["(batte le nocche sul quadro) Non legge? Spingi.", "Ha sempre funzionato."],
				["Il sensore è pigro. Va svegliato.", "(nocche) Così."],
				["Più potenza, più segnale. È matematica."],
			],
			"stadio1": [
				["Tre sensori bruciati in sette giorni, Eli.", "(batte le nocche, piano) E li ho bruciati io, spingendo."],
				["Quieto guarda i lampi e sa quando arriva la scarica.", "Non spinge niente. Guarda e basta. E ci prende."],
				["Se il sensore non legge perché è saturo…", "(nocche) …spingere è la cosa peggiore che posso fare. Ed è quella che faccio da vent'anni."],
			],
			"stadio2": [
				["Prima chiedo perché non legge. Poi decido.", "(batte le nocche per abitudine) Sei volte su dieci è sporco, non debole."],
				["Un mese senza bruciare un sensore. Un mese!", "Il magazziniere mi ha chiesto se sono malata."],
				["Quieto mi ha insegnato a guardare prima di toccare.", "(nocche, piano) È la cosa più difficile che ho imparato."],
			],
			"reazione": [
				["Ha retto la scarica senza saltare! (batte le nocche) E non l'ho toccato.", "(batte le nocche sul quadro) Ha abbassato la potenza da solo. Da solo, capisci?"],
				["Andata! Ti regalo un sensore. Non bruciato, giuro."],
				["Ha battuto le nocche su un quadro, quello che si ripresenta a raffica.", "Mi ha imitata. (nocche) Devo smettere, io."],
			],
			"riempimento": [
				["(nocche) Durante la tempesta i quadri cantano.", "È bruttissimo, ma è un canto."],
				["C'è un registro di misure lungo quattro secoli, nel bunker.", "Una riga al mese. (nocche) L'ultima parte scende. Non so cosa voglia dire."],
				["Parafulmine aspetta di essere colpito da un fulmine.", "(nocche) Gli ho spiegato cosa succede. Aspetta lo stesso."],
			],
		},
	},
	"w20-quieto": {
		"funzione": "testimone",
		"world": 20,
		"nome": "Quieto",
		"ruolo": "Osservatore dei lampi della Tempesta",
		"registro": "solenne",
		"tic": "conta i secondi fra lampo e tuono",
		"ticMarker": "second",
		"convinzione": "Quello che faccio non si può insegnare: si è fatto da sé, guardando.",
		"bisogno": "Vuole lasciare a qualcuno la lettura dei lampi prima che la tempesta lo superi.",
		"arco": [
			"Prevede le scariche con una precisione che nessuno spiega, nemmeno lui.",
			"Prova a insegnarlo a Sferza e si accorge di avere delle regole che non aveva mai detto ad alta voce.",
			"Ha scritto sette regole su un foglio, e adesso la tempesta la legge anche qualcun altro.",
		],
		"battute": {
			"richiesta": [
				["Lampo. Uno, due, tre, quattro, cinque… tuono.", "Cinque secondi. Vuol dire qualcosa, e io lo so senza saperlo dire.", "Va' sulla torre e conta con me da lassù. Poi confrontiamo."],
				["Voglio lasciare a qualcuno la lettura dei lampi.", "Non ho mai insegnato niente a nessuno. Comincio da te.", "Conta i secondi e non fidarti di me: fidati del conteggio."],
				["Sulla vecchia stazione c'è una tabella di secondi e distanze.", "Qualcuno prima di me contava come conto io e l'ha scritto.", "Vacci. Se quei numeri sono i miei, allora si può insegnare."],
			],
			"consolazione": [
				["Fermati e conta con me. Uno. Due. Tre.", "La tempesta non aspetta, ma torna. Ci sarà un altro lampo."],
				["Non hai sbagliato tu: hai contato troppo in fretta.", "Succede a tutti, i primi mesi. Un secondo dura più di quanto sembri."],
			],
			"stadio0": [
				["Tre secondi fra lampo e tuono: è vicina.", "Poi ci sono cose che si vedono e non si dicono."],
				["Guardo da trent'anni. Non è un metodo: è tempo passato a guardare."],
				["(conta i secondi) …quattro, cinque. Si allontana. Puoi passare."],
			],
			"stadio1": [
				["Sferza mi ha chiesto come faccio.", "Ho aperto la bocca e mi sono accorto di avere delle regole.", "Sette. Le ho contate come i secondi."],
				["Se ho delle regole, allora si può insegnare.", "(conta i secondi) …e se si può insegnare, avrei dovuto farlo prima."],
				["Regola quattro: se il lampo è a ventaglio, la scarica non arriva a terra.", "L'ho detta ad alta voce per la prima volta ieri."],
			],
			"stadio2": [
				["Sette regole su un foglio, appeso al quadro comandi.", "(conta i secondi) Sferza le usa. Sbaglia la sei, ma le usa."],
				["Non era un dono. Era attenzione, ripetuta per trent'anni.", "L'attenzione si può insegnare. Il dono no. Meno male che era attenzione."],
				["(conta i secondi) Se domani non ci fossi, la tempesta la leggerebbe qualcun altro.", "Non mi era mai capitato di pensarlo senza tristezza."],
			],
			"reazione": [
				["Ha previsto la scarica prima di me. Di due secondi buoni.", "(conta i secondi) Di due secondi. Solo due. Ma prima."],
				["Hai concluso. Resta un momento: sta arrivando un lampo a ventaglio, e sono belli."],
				["Ha contato i secondi con me quello che ogni volta ricomincia.", "Si è fermato al tre e ha ricominciato da uno. (conta i secondi) Va bene lo stesso."],
			],
			"riempimento": [
				["(conta i secondi) La tempesta qui non finisce mai. Cambia solo intensità."],
				["Nel bunker c'è una curva disegnata su quattro secoli.", "(conta i secondi) Sale per trecentonovanta anni. Poi scende. Scende adesso."],
				["Parafulmine si mette sotto i lampi con un bastone di ferro.", "Gli ho dato le sette regole. Ha letto solo la settima, che dice di non farlo."],
			],
		},
	},
	"w21-terza": {
		"funzione": "specialista",
		"world": 21,
		"nome": "Terza",
		"ruolo": "Climatologa dell'Atlante Fratturato",
		"registro": "burbero",
		"tic": "allinea i fogli battendoli sul tavolo",
		"ticMarker": "fogli",
		"convinzione": "Ogni posto fa storia a sé.",
		"bisogno": "Ha undici studi locali perfetti e nessuna spiegazione che li tenga insieme.",
		"arco": [
			"Studia un clima alla volta, con rigore, e rifiuta di confrontarli fra loro.",
			"Mino le mostra un calendario di pastori che prevede la pioggia in tre valli diverse.",
			"Mette in fila gli undici studi e vede il sistema che li governa tutti.",
		],
		"battute": {
			"richiesta": [
				["(batte i fogli sul tavolo) Undici studi locali. Tutti giusti.", "E nessuna spiegazione che li tenga insieme.", "Prendili e leggili di fila. Voglio sapere se vedi una cosa che io non vedo."],
				["La serie delle piogge del versante nord mi manca.", "Sta in fondo all'archivio, in una cassa che non apro da tre anni.", "Vacci tu. Se la porti qui, io la metto in colonna con le altre."],
				["Mino dice che il calendario di suo nonno prevede il tempo.", "(allinea i fogli) Io ho undici studi e lui ha una filastrocca.", "Va' a farsela dire tutta. Poi la mettiamo accanto ai miei numeri."],
			],
			"consolazione": [
				["Non torna. Meglio saperlo adesso che pubblicarlo.", "(batte i fogli) Si rimette in ordine e si riparte dalla serie più corta."],
				["Senti. Ho undici studi perfetti e nessuna idea.", "Tu hai sbagliato un tentativo e un'idea ce l'hai. Non scambierei."],
			],
			"stadio0": [
				["(allinea i fogli) Undici studi. Undici climi. Undici storie separate."],
				["Confrontare posti diversi è approssimare.", "Io non approssimo."],
				["(batte i fogli sul tavolo) Questa valle ha le sue regole. Punto."],
			],
			"stadio1": [
				["Mino ha un calendario tramandato che vale per tre valli.", "(allinea i fogli) Tre. Valli diverse, stesso calendario, e funziona."],
				["Se una regola sola vale per tre posti…", "…allora i posti non fanno storia a sé. Fanno parte di una storia più grande."],
				["(allinea i fogli, poi si ferma) Ho undici studi e non li ho mai messi uno accanto all'altro.", "Undici anni di lavoro, e non li ho mai guardati insieme."],
			],
			"stadio2": [
				["Li ho messi in fila per latitudine. (allinea i fogli) Il disegno è saltato fuori da solo."],
				["Il clima è un sistema. Le valli sono le sue stanze, non case separate."],
				["Mino aveva ragione da sei generazioni.", "(allinea i fogli) Il suo calendario è un modello. Fatto senza saperlo, ma è un modello."],
			],
			"reazione": [
				["Ha proiettato tutte le valli insieme. (allinea i fogli) Tutte.", "(allinea i fogli) Le correnti passano da una all'altra. È ovvio adesso. Non lo era ieri."],
				["Fatto. Segnata, con l'ora e le condizioni meteo."],
				["Mi ha chiesto se domani piove, quello che si presenta a ogni foglio.", "(allinea i fogli) Gli ho detto di sì. Non è piovuto. Succede."],
			],
			"riempimento": [
				["(allinea i fogli) L'Atlante è fratturato perché le carte vecchie non combaciano.", "Sono giuste tutte. Sono solo di anni diversi."],
				["Nel deposito c'è una tesi scritta a mano, lunghissima.", "(allinea i fogli) Non l'ho finita. Dice che il sapere che passa di mano fa danni. Non sono d'accordo, ma è ben argomentata."],
				["Meteora prevede il tempo di ieri con precisione impressionante.", "(allinea i fogli) È inutile e non ha mai sbagliato."],
			],
		},
	},
	"w21-mino": {
		"funzione": "testimone",
		"world": 21,
		"nome": "Mino",
		"ruolo": "Pastore dell'Atlante, custode di un calendario tramandato",
		"registro": "caloroso",
		"tic": "offre formaggio e parla dei mesi come di parenti",
		"ticMarker": "formaggio",
		"convinzione": "Il calendario è una tradizione, non una previsione.",
		"bisogno": "Vuole sapere se il calendario di suo nonno vale ancora, adesso che il tempo cambia.",
		"arco": [
			"Segue un calendario tramandato da sei generazioni e lo considera un'usanza di famiglia.",
			"Terza lo confronta con undici studi: l'usanza è un modello climatico che funziona.",
			"Aggiorna il calendario con le misure di Terza e lo lascia scritto, non più solo a voce.",
		],
		"battute": {
			"richiesta": [
				["Prendi il formaggio, che poi si asciuga.", "Mio nonno diceva: «se marzo ride, aprile piange». Quest'anno marzo ha riso.", "Va' a vedere se aprile ha pianto davvero. Io non ho il coraggio."],
				["Ho un calendario di dodici versi, uno per mese.", "Li chiamo per nome come parenti: marzo il permaloso, agosto il pigro.", "Vieni a sentirli tutti. Poi mi dici quali sbagliano."],
				["Il pascolo alto si apriva sempre lo stesso giorno.", "Adesso si apre prima. Tre settimane prima, mangia il formaggio.", "Va' a chiedere a Terza se lo sa. Io non oso disturbarla."],
			],
			"consolazione": [
				["Su, mangia qualcosa prima di parlare.", "Le annate storte ci sono sempre state. Si semina lo stesso l'anno dopo."],
				["Vieni qua sotto, che qui non piove.", "Nessuno ha mai imparato il tempo in un giorno solo. Ci vogliono le stagioni."],
			],
			"stadio0": [
				["Assaggia il formaggio. Poi parliamo.", "Il calendario dice che a fine mese piove. Lo dice da sempre."],
				["Mio nonno lo diceva a mio padre. Non è scienza, è famiglia."],
				["Marzo è permaloso, aprile è bugiardo. Prendi ancora formaggio."],
			],
			"stadio1": [
				["Terza ha confrontato il mio calendario con i suoi undici studi.", "Ha detto che è un modello. Un modello, al calendario di mio nonno.", "Ho dovuto sedermi. Vuoi del formaggio?"],
				["Sei generazioni di pastori che guardano il cielo…", "…sono sei generazioni di osservazioni. Detto così fa un altro effetto."],
				["Ma il tempo sta cambiando. Il calendario regge ancora?", "Questo mi preoccupa più del resto. Mangia, che ti fa bene."],
			],
			"stadio2": [
				["Il calendario è scritto. Con le date, le misure e le correzioni di Terza.", "Non è più solo mio. Prendi il formaggio, che festeggiamo."],
				["Sei generazioni a voce e una scritta.", "Se la settima si dimentica, adesso può rileggere."],
				["Terza viene a controllare le greggi con me, il giovedì.", "Dice che i suoi strumenti sbagliano meno se guarda anche le pecore. Formaggio?"],
			],
			"reazione": [
				["Ha annunciato la pioggia per venerdì! Come diceva mio nonno.", "Anche il mio calendario. Siamo d'accordo. Assaggia il formaggio della festa."],
				["Chiusa? Siediti. Prima si mangia."],
				["Ha mangiato tre volte, quello che saluta sempre come la prima volta.", "Perché ogni volta credeva di essere appena arrivato. Formaggio ce n'è."],
			],
			"riempimento": [
				["Le pecore sentono il temporale sei ore prima.", "Il calendario dice le stesse cose, ma con più anticipo. Formaggio?"],
				["Il mese che chiamiamo «il magro» è quello che nei libri sta fra due nomi.", "Il nostro nome è più utile."],
				["Meteora mi dice sempre che tempo ha fatto ieri.", "Gli do il formaggio lo stesso. È gentile."],
			],
		},
	},
	"w22-vesca": {
		"funzione": "specialista",
		"world": 22,
		"nome": "Vesca",
		"ruolo": "Biologa della Biosfera Profonda",
		"registro": "curioso",
		"tic": "annusa tutto prima di guardarlo",
		"ticMarker": "annus",
		"convinzione": "Vince sempre il più forte.",
		"bisogno": "Cerca l'organismo dominante della caverna e non riesce a trovarlo.",
		"arco": [
			"Classifica ogni specie per forza e cerca il vincitore della caverna.",
			"Scopre che le specie più diffuse sono quelle che stanno in una nicchia che nessun altro vuole.",
			"Smette di cercare il più forte e mappa chi sta bene dove: la caverna non ha un vincitore.",
		],
		"battute": {
			"richiesta": [
				["(annusa l'aria) In questa caverna c'è un odore che non riconosco.", "Cerco l'organismo che comanda qua sotto e non lo trovo.", "Vieni a cercarlo con me. Dev'esserci per forza."],
				["Nella sala dei funghi va contato chi mangia chi.", "Chi mangia chi. Segna le frecce, non i nomi.", "Poi torna e annusiamo il risultato insieme."],
				["Un lichene è due cose insieme e non capisco quale vinca.", "(lo annusa) Odora di alga e di fungo nello stesso momento.", "Va' a guardarlo al microscopio della sala bassa."],
			],
			"consolazione": [
				["(annusa il tuo quaderno) Sa di tentativo. Buon segno.", "Chi non prova non puzza di niente. Si ricomincia dal campione due."],
				["Aspetta un attimo, non buttarlo.", "Ho cercato per due anni un animale che non esisteva. Due anni. Tu hai perso un'ora."],
			],
			"stadio0": [
				["(annusa) Questo odore è di qualcosa che comanda.", "In ogni ambiente c'è un vincitore. Basta trovarlo."],
				["Il più forte prende tutto. È così ovunque."],
				["(annusa il muschio) Debole. Non conta niente nel bilancio della caverna."],
			],
			"stadio1": [
				["Quel muschio «debole» copre il quaranta per cento della caverna.", "(annusa) Odore di niente. Presenza enorme."],
				["Sta dove non c'è luce e quasi non c'è acqua.", "Nessun altro vuole quel posto. E lui non lo divide con nessuno."],
				["Se il più diffuso è quello che sta dove nessuno lo disturba…", "(annusa) …allora forte non vuol dire vincente. Vuol dire un'altra cosa e non so quale."],
			],
			"stadio2": [
				["Non c'è un vincitore. Ci sono ventidue nicchie e ventidue modi di starci bene.", "(annusa) Ogni odore è un mestiere diverso."],
				["Fondo mi ha portato in una grotta dove vivono solo tre specie.", "Nessuna forte. Tutte e tre insostituibili."],
				["Cercavo il campione della caverna.", "(annusa) La caverna non fa gare. Fa incastri."],
			],
			"reazione": [
				["Si è illuminata la grotta madre! (annusa) E l'aria è cambiata.", "(annusa) Odore di roccia bagnata e di qualcosa di vivo che non ho ancora classificato."],
				["Riuscita! Vieni, ti faccio annusare una cosa incredibile."],
				["Ha annusato un fungo, quello che sa di chi cammina molto.", "(annusa) Gli ho detto di non farlo. Poi l'ho fatto anch'io."],
			],
			"riempimento": [
				["(annusa) Ogni ramo della caverna ha il suo odore.", "Con gli occhi chiusi so dove sono."],
				["C'è una domanda incisa su una parete, in fondo.", "Due parole, e un punto interrogativo. (annusa) Nessuno ha mai scritto la risposta."],
				["Muffa considera i suoi funghi dei colleghi.", "(annusa) Scientificamente è discutibile. Umanamente lo capisco."],
			],
		},
	},
	"w22-fondo": {
		"funzione": "testimone",
		"world": 22,
		"nome": "Fondo",
		"ruolo": "Guida delle caverne della Biosfera Profonda",
		"registro": "misterioso",
		"tic": "risponde indicando invece di spiegare",
		"ticMarker": "guarda",
		"convinzione": "Certe cose si mostrano, non si dicono.",
		"bisogno": "Vuole che qualcuno legga la domanda incisa in fondo alla caverna.",
		"arco": [
			"Conosce ogni nicchia della Biosfera e non spiega niente: porta e indica.",
			"Si accorge che chi non sa cosa guardare non vede, e indicare non basta.",
			"Impara a dire qualche parola in più, senza smettere di far vedere per primo.",
		],
		"battute": {
			"richiesta": [
				["Guarda. (indica la parete) Non te lo spiego.", "Ci sono dei segni là dietro, incisi in fondo alla galleria.", "Vacci da sola. Con la lanterna bassa."],
				["Guarda dove metti i piedi, poi guarda in alto.", "Le radici scendono fin qua sotto. Da lassù a quaggiù.", "Va' a seguirne una fino in fondo. Poi capirai perché te lo dico."],
				["In fondo alla caverna c'è una domanda incisa.", "Io non so leggerla. Guarda tu.", "Se qualcuno si è preso la briga di inciderla, voleva una risposta."],
			],
			"consolazione": [
				["Guarda la parete, non me.", "Vedi quel solco? Ci è voluta l'acqua di mille anni. Nessuno ha fretta, qua sotto."],
				["Siediti. Guarda la lanterna.", "Anche la luce piccola arriva in fondo, se aspetti che gli occhi si abituino."],
			],
			"stadio0": [
				["Guarda lì. No, più in basso.", "…visto? Bene. Andiamo."],
				["Non spiego. Porto."],
				["Guarda dove metti i piedi. E guarda dove NON li metti."],
			],
			"stadio1": [
				["Ho portato Vesca alla grotta delle tre specie.", "Guardava e non vedeva. (indica) Le ho dovuto dire cosa cercare."],
				["Se indico e l'altro non vede…", "…l'ho portato per niente. Guarda: questo non me l'ero mai chiesto."],
				["Mio padre indicava e basta. Io ho imparato così.", "Guarda, però: forse non era il modo migliore. Solo quello che c'era."],
			],
			"stadio2": [
				["Guarda: muschio, acqua ferma, niente luce. Tre cose, e ti dico perché contano.", "Cinque parole in più e adesso vedi anche tu."],
				["Continuo a far vedere per primo. Ma poi parlo.", "Guarda — e ascolta."],
				["Vesca adesso trova le nicchie da sola.", "Guarda meglio di me, ormai. L'ho portata io fin lì, però."],
			],
			"reazione": [
				["Guarda in alto. L'apparato ha acceso le vene di quarzo.", "Quattrocento anni che non succedeva. Guarda, e non dire niente."],
				["Guarda: da qui si vede tutta la caverna madre. Volevo che la vedessi."],
				["È tornato. Quello che arriva sempre da capo.", "Gli ho indicato una cosa quattro volte. Guarda… la quarta l'ha vista."],
			],
			"riempimento": [
				["Guarda l'acqua: dove è ferma è vecchia, dove trema c'è un passaggio."],
				["In fondo c'è una domanda incisa nella pietra.", "Guarda tu. Io non la leggo più: l'ho letta troppe volte senza risposta."],
				["Muffa parla ai funghi. Guarda: i funghi rispondono, a modo loro."],
			],
		},
	},
	"w23-cronia": {
		"funzione": "specialista",
		"world": 23,
		"nome": "Cronia",
		"ruolo": "Archivista capo della Sala delle Ere",
		"registro": "solenne",
		"tic": "timbra ogni documento, anche quelli già timbrati",
		"ticMarker": "timbr",
		"convinzione": "Le fonti scomode confondono: si conserva la versione ufficiale.",
		"bisogno": "Deve spiegare un vuoto di quattro secoli e la versione ufficiale non lo copre.",
		"arco": [
			"Conserva una sola versione per ogni evento, per non confondere chi studia.",
			"Trova un vuoto che la versione ufficiale non spiega, e nessun documento autorizzato lo colma.",
			"Riapre l'archivio delle fonti scartate e ci trova quello che mancava.",
		],
		"battute": {
			"richiesta": [
				["(timbra il faldone) Quattro secoli di vuoto nella cronologia ufficiale.", "Quattro. E io devo spiegarli entro la fine del mese.", "Va' nel deposito e portami tutto quello che copre quegli anni."],
				["Le tre versioni del decreto vanno messe a confronto.", "Ho sempre conservato solo l'ufficiale. (timbra) Solo quella."],
				["Una cassa, anni fa, l'ho fatta sigillare io.", "Dentro ci sono fonti che davano fastidio. Non le ho distrutte: le ho nascoste.", "Vacci tu e aprila. Non riesco a farlo da sola."],
			],
			"consolazione": [
				["(timbra un foglio bianco) Ecco: annullato.", "Un documento sbagliato si annulla e si riscrive. Non si brucia. Vale anche per i tentativi."],
				["Alza la testa quando ti parlo.", "Io ho tenuto nascosto un vuoto di quattro secoli. Tu hai sbagliato una ricerca. Non sono la stessa cosa."],
			],
			"stadio0": [
				["(timbra) Versione ufficiale. Una per evento. Chiaro e definitivo."],
				["Le fonti discordanti confondono gli studenti.", "(timbra) Si conserva la migliore e si va avanti."],
				["Un archivio che dice due cose non è un archivio. È un dubbio conservato."],
			],
			"stadio1": [
				["C'è un vuoto di quattro secoli, e l'ufficiale lo salta.", "(timbra, poi si ferma) Lo salta e basta. Come se non fosse successo niente."],
				["Ho cercato negli atti autorizzati. Niente.", "(timbra) Il timbro non riempie un vuoto, ho scoperto."],
				["Ovidio dice di avere delle carte.", "Carte che io ho ordinato di scartare, quarant'anni fa."],
			],
			"stadio2": [
				["Le carte di Ovidio riempiono il vuoto. Tutte e quattro le scatole.", "(timbra) Le ho timbrate. Non per validarle: per non perderle di nuovo."],
				["Ho conservato una sola versione per quarant'anni.", "E per quarant'anni l'archivio ha avuto un buco della forma esatta di quello che avevo buttato."],
				["(timbra) C'è un registro del mondo 2. Una allieva di undici anni, partita e mai tornata.", "E mai registrata come perduta. Questo non lo timbro: lo lascio aperto sul tavolo."],
			],
			"reazione": [
				["Si è aperto l'archivio sigillato. (timbra) Registro anche questo.", "(timbra) Quattrocento spirali, di mani tutte diverse. Non ho parole, e io ho sempre parole."],
				["Missione conclusa. (timbra) Con data, ora e le tre versioni dei fatti."],
				["Quel giovane senza scheda, che si annuncia ogni volta, ha chiesto di vedere l'archivio.", "(timbra) Gliel'ho mostrato. Tre volte. Ogni volta si è stupito uguale."],
			],
			"riempimento": [
				["(timbra) Timbro anche i documenti già timbrati. Lo so. Non riesco a smettere."],
				["La Sala delle Ere ha ventidue scaffali e uno vuoto.", "Adesso so cosa ci andava."],
				["Errata timbra a caso per portarsi avanti.", "(timbra) L'ho sgridato. Poi ho guardato le mie mani."],
			],
		},
	},
	"w23-ovidio": {
		"funzione": "testimone",
		"world": 23,
		"nome": "Ovidio",
		"ruolo": "Copista della Sala delle Ere",
		"registro": "caloroso",
		"tic": "parla dei documenti come di persone da proteggere",
		"ticMarker": "carte",
		"convinzione": "Quello che ho fatto è una disobbedienza, non un lavoro.",
		"bisogno": "Vuole restituire le carte senza che nessuno finisca nei guai.",
		"arco": [
			"Ha conservato di nascosto per quarant'anni le fonti che gli era stato ordinato di distruggere.",
			"Cronia trova un vuoto che solo le sue carte possono riempire, e lui deve decidere se dirlo.",
			"Le carte tornano nell'archivio con il suo nome sopra, e nessuno finisce nei guai.",
		],
		"battute": {
			"richiesta": [
				["Queste carte hanno freddo e paura, se posso dirlo.", "Vanno riportate al loro posto senza che nessuno finisca nei guai.", "Mi aiuti a rimetterle in ordine prima del turno di Cronia?"],
				["Ho copiato di nascosto una pagina che stava per sparire.", "Adesso ne esistono due, e la copia è mia. È disobbedienza, lo so.", "Va' a confrontarla con l'originale. Voglio essere sicuro di non aver tradito le carte."],
				["Nel deposito c'è un registro dei prestiti di trent'anni fa.", "Dice chi ha portato via cosa. Alcune cose non sono mai tornate.", "Vacci tu, per favore. Le carte si fidano di chi le tratta piano."],
			],
			"consolazione": [
				["Vieni, siediti fra gli scaffali. Qui le carte non giudicano nessuno."],
				["Non fa niente.", "Anche una copia sbagliata conserva qualcosa. Si rifà il foglio, non si butta la giornata."],
			],
			"stadio0": [
				["Le carte scartate le ho… sistemate.", "Non dico dove. Stanno bene, questo sì."],
				["Un documento non si brucia. È come chiudere fuori qualcuno al freddo."],
				["Ho copiato per quarant'anni. Le carte che copiavo mi sembravano affidate, non consegnate."],
			],
			"stadio1": [
				["Cronia cerca una cosa che io ho in quattro scatole.", "Se parlo, ammetto di aver disobbedito per quarant'anni."],
				["Le carte stanno all'asciutto, in un posto che conosco solo io.", "Ho passato quarant'anni a temere questo giorno e adesso che è arrivato sono quasi sollevato."],
				["Non l'ho fatto per ribellione, sai.", "L'ho fatto perché mi facevano pena. Le carte, dico."],
			],
			"stadio2": [
				["Le scatole sono sullo scaffale ventidue. Con il mio nome sopra.", "Cronia le ha timbrate. Non mi ha nemmeno sgridato."],
				["Quarant'anni di nascondiglio e nessuno finisce nei guai.", "Se l'avessi detto prima… no. Prima non mi avrebbero ascoltato."],
				["Le carte adesso stanno al caldo, in fila, con le altre.", "È tutto quello che volevo. Non ero un eroe: ero un copista con un ripostiglio."],
			],
			"reazione": [
				["Hai aperto l'archivio sigillato!", "Ci sono quattrocento spirali dentro. Mani diverse, tutte. Le carte hanno aspettato tanto."],
				["È andata. Ti ho copiato una pagina in bella grafia. Tienila: le carte sono contente."],
				["Mi ha aiutato con una scatola quello che dimentica tutto tranne la gentilezza.", "Tre volte la stessa scatola. Le carte non se ne sono avute a male."],
			],
			"riempimento": [
				["Nelle carte scartate c'è un registro del mondo 2.", "Una bambina di undici anni. Non ti dico altro: leggilo tu."],
				["Ho la grafia di quando avevo vent'anni e di quando ne avevo sessanta.", "Le carte se ne accorgono, secondo me."],
				["Errata timbra a caso.", "Gli ho dato dei fogli bianchi da timbrare. Adesso è felice e le carte sono salve."],
			],
		},
	},
}

## I Bislacchi: 4–6 battute, zero carico didattico, nessun arco e nessuna
## missione. Esistono perché un mondo in cui tutti hanno una lezione da imparare
## è un mondo faticoso.
const BISLACCHI := {
	"w01-puccio": {
		"world": 1,
		"nome": "Puccio",
		"ruolo": "Saluta i cristalli per nome. Tutti e quaranta.",
		"registro": "buffo",
		"tic": "se lo interrompi ricomincia da Aurelio",
		"ticMarker": "Aurelio",
		"battute": [
			["Buongiorno Aurelio. Buongiorno Bice. Buongiorno Carmelo.", "…scusa, con chi stavo parlando? Ah, i cristalli.", "Ho perso il filo. Ricomincio. Buongiorno Aurelio."],
			["Sono quaranta e hanno tutti un nome.", "No, non li ho inventati io. Me li hanno detti loro."],
			["Il quattordicesimo si chiama Gustavo ed è permaloso.", "Se lo saluti per ultimo non brilla per due giorni."],
			["Tobia dice che potrei salutarli a gruppi di dieci.", "Ci ho provato. «Buongiorno, gruppo di dieci.»", "Si sono offesi tutti e quaranta."],
			["Non interrompermi mai mentre saluto.", "…ecco, me l'hai appena fatto fare. Buongiorno Aurelio."],
		],
	},
	"w02-ditino": {
		"world": 2,
		"nome": "Ditino",
		"ruolo": "Ha inventato una parola nuova e non ricorda cosa volesse dire",
		"registro": "buffo",
		"tic": "ripete la parola «sgrembo» sperando che gli torni in mente",
		"ticMarker": "sgrembo",
		"battute": [
			["L'ho inventata ieri. «Sgrembo».", "Bellissima. Utilissima.", "Non ho la più pallida idea di cosa voglia dire."],
			["Serviva per una cosa precisa. Precisissima.", "Sgrembo. Sgrembo. …niente."],
			["Corinna mi chiede in che settore catalogarla.", "E che ne so? Prima devo sapere cos'è."],
			["Forse era un oggetto. O un colore. O un sentimento.", "O tutte e tre. Sarebbe una gran parola, sgrembo."],
			["Bruno dice di scriverle subito, le parole.", "Ha ragione lui. Ha dieci anni e ha ragione lui. Sgrembo."],
		],
	},
	"w03-manetta": {
		"world": 3,
		"nome": "Manetta",
		"ruolo": "Dà istruzioni precise a una macchina spenta da secoli",
		"registro": "buffo",
		"tic": "giustifica la macchina dicendo che è timida",
		"ticMarker": "timida",
		"battute": [
			["Prima leva a sinistra. Poi la manovella. Poi aspetti.", "…non si muove. È timida."],
			["Le parlo tutti i giorni. Istruzioni chiare, tono gentile.", "È spenta da quattrocento anni, ma è una questione di rispetto."],
			["Ruggine dice che le manca la corrente.", "Ruggine non capisce le personalità delicate."],
			["Oggi ha fatto un rumore. Un rumore vero.", "Era il vento. Ma è un inizio: si sta sciogliendo, è solo timida."],
			["Se un giorno parte, io sarò qui.", "E le dirò: visto? Bastava chiedere."],
		],
	},
	"w04-boa": {
		"world": 4,
		"nome": "Boa",
		"ruolo": "Risponde a tutti i segnali radio, soprattutto a quelli non diretti a lui",
		"registro": "buffo",
		"tic": "chiude ogni frase con «ricevuto»",
		"ticMarker": "ricevuto",
		"battute": [
			["Segnale in arrivo. Non è per me.", "Rispondo lo stesso. Ricevuto!"],
			["Ieri ho risposto a una nave a duecento miglia.", "Cercavano un certo Aldo. Ricevuto."],
			["Marea dice che non si fa.", "Ma se nessuno risponde, quel segnale muore da solo. Ricevuto?"],
			["Una volta uno mi ha risposto indietro.", "Abbiamo parlato due ore. Non ho capito la lingua. Bellissimo. Ricevuto."],
			["Se un giorno chiami e nessuno risponde, chiama qui.", "Io ci sono sempre. Ricevuto."],
		],
	},
	"w05-peso": {
		"world": 5,
		"nome": "Peso",
		"ruolo": "Solleva cose che non vanno sollevate per allenarsi a sollevare cose",
		"registro": "buffo",
		"tic": "chiama tutto «allenamento»",
		"ticMarker": "allenamento",
		"battute": [
			["Oggi ho sollevato una porta.", "Era aperta. Ma è allenamento lo stesso."],
			["Ieri: un secchio vuoto, ottanta volte.", "Il segreto è la costanza, non il peso. Allenamento."],
			["Gerbo dice che sollevo cose inutili.", "Gerbo solleva massi utilissimi ed è sempre stanco. Io no. Allenamento."],
			["Tilla mi ha spiegato la leva.", "Ma se uso la leva non mi alleno! Le ho detto di no, grazie."],
			["Mi sto allenando a sollevare una nuvola.", "Non ci sono ancora arrivato. Ma l'allenamento è quello."],
		],
	},
	"w06-zufolo": {
		"world": 6,
		"nome": "Zufolo",
		"ruolo": "Cerca da anni la nota che gli ha rubato il cappello",
		"registro": "buffo",
		"tic": "torna sempre sul cappello",
		"ticMarker": "cappello",
		"battute": [
			["Era un si bemolle. Ne sono quasi certo.", "Ha preso il cappello ed è scappata verso il boschetto."],
			["La gente dice che una nota non può rubare niente.", "La gente non aveva quel cappello."],
			["L'ho quasi presa l'anno scorso.", "Poi ha fatto un salto di ottava e l'ho persa. Furba."],
			["Ambra dice che quella nota esiste davvero.", "Lo sapevo. Ora però mi deve restituire il cappello."],
			["Se la senti, non inseguirla.", "Fermati e aspetta. Prima o poi passa. Col mio cappello."],
		],
	},
	"w07-postilla": {
		"world": 7,
		"nome": "Postilla",
		"ruolo": "Corregge le iscrizioni antiche con annotazioni sue, nessuna pertinente",
		"registro": "buffo",
		"tic": "annuncia ogni volta una postilla",
		"ticMarker": "postilla",
		"battute": [
			["Qui c'era scritto «il grano fu diviso in parti uguali».", "Ho aggiunto una postilla: «anche a me piace il pane»."],
			["Livia le cancella ogni sera.", "Io le riscrivo ogni mattina. Postilla: è un dialogo."],
			["Postilla alla tavola nona: «bella giornata».", "Non c'entra niente, lo so. Ma è vero."],
			["Un'iscrizione senza commento è una conversazione a senso unico.", "Postilla: e le conversazioni a senso unico sono tristissime."],
			["Zeno ha trovato una parola sola in tutta la Rovina.", "Postilla mia: «bravo». Quella però l'ha lasciata."],
		],
	},
	"w08-scintilla": {
		"world": 8,
		"nome": "Scintilla",
		"ruolo": "Si presenta come «il capo di questa palude». Non c'è nessuna palude",
		"registro": "buffo",
		"tic": "rivendica la palude",
		"ticMarker": "palude",
		"battute": [
			["Fermo lì. Sono il capo di questa palude.", "…quale palude? Questa palude."],
			["Il Delta non è una palude, dicono.", "Il Delta è un delta, dicono. Io comando lo stesso."],
			["Ho un cappello da capo e un bastone da capo.", "Mi manca solo la palude. Dettagli."],
			["Doria dice che qui l'acqua scorre, e nelle paludi sta ferma.", "Allora questa è una palude veloce. Ho risposto."],
			["Se un giorno trovi una palude senza capo, chiamami.", "Trasloco in giornata."],
		],
	},
	"w09-bora": {
		"world": 9,
		"nome": "Bora",
		"ruolo": "Disegna mappe di posti che deve ancora inventare",
		"registro": "buffo",
		"tic": "parla dei posti inventati come se fossero già lì",
		"ticMarker": "ancora",
		"battute": [
			["Questa è la Baia dei Tre Cani.", "Non esiste ancora. Ma la mappa è pronta, così quando esiste siamo avanti."],
			["Ho mappato quattordici isole non ancora inventate.", "Alma dice che non si fa. Alma non ha visione."],
			["Il difficile non è disegnarle. È trovare i nomi.", "«Baia dei Tre Cani» mi è venuta benissimo."],
			["Se un giorno scopri un'isola senza nome, chiamami.", "Ne ho ancora undici in magazzino."],
			["Un posto che non esiste ancora non è un posto falso.", "È solo in anticipo."],
		],
	},
	"w10-terriccio": {
		"world": 10,
		"nome": "Terriccio",
		"ruolo": "Ha dato un nome a ogni foglia e adesso non le ricorda",
		"registro": "buffo",
		"tic": "chiama le foglie per nome e sbaglia",
		"ticMarker": "fogli",
		"battute": [
			["Questa è Bettina. …no, Bettina è caduta a marzo.", "Questa allora è… una foglia nuova. Ciao, foglia nuova."],
			["Ottomila nomi, una foglia per volta.", "Li avevo tutti in testa. Tutti."],
			["Il problema delle foglie è che cambiano di continuo.", "Nascono, cadono, e nessuna avvisa."],
			["Mirta dice di scriverli, i nomi.", "Ci vorrebbe un quaderno grande come la serra: una riga per foglia."],
			["Ho deciso: da oggi do il nome solo ai rami.", "I rami restano. Questo è Ubaldo."],
		],
	},
	"w11-anticaglia": {
		"world": 11,
		"nome": "Anticaglia",
		"ruolo": "Vende reperti falsissimi con passione commovente",
		"registro": "buffo",
		"tic": "giura sull'autenticità e poi ammette",
		"ticMarker": "autentic",
		"battute": [
			["Autentico! Quattrocento anni!", "…l'ho fatto io giovedì. Ma con amore autentico."],
			["Questa moneta è autentica. Di una civiltà che ho inventato.", "Ha una storia bellissima, vuoi sentirla?"],
			["Danio mi ha comprato un vaso. Falso.", "Gliel'ho detto dopo. Adesso siamo amici."],
			["Il falso fatto male è una truffa.", "Il falso fatto benissimo è artigianato. Autentico artigianato."],
			["Vesta mi compra i falsi e li archivia.", "Dice che raccontano qualcosa di me. Spero bene."],
		],
	},
	"w12-svolta": {
		"world": 12,
		"nome": "Svolta",
		"ruolo": "Entra nel labirinto ogni mattina per «tenerlo in esercizio»",
		"registro": "buffo",
		"tic": "tratta il labirinto come un animale da accudire",
		"ticMarker": "esercizio",
		"battute": [
			["Se non ci entra nessuno si intorpidisce.", "Il labirinto ha bisogno di esercizio come tutti."],
			["Oggi l'ho fatto correre un po'. Tre giri.", "Cioè, ho corso io. Ma è lo stesso esercizio."],
			["Quinto dice che i muri si spostano da soli.", "Certo che si spostano: si sta allenando anche lui."],
			["Isa mi ha dato un filo.", "L'ho usato per giocare col labirinto. Gli piace tirare."],
			["Un labirinto senza nessuno dentro è solo un muro complicato.", "L'esercizio lo tiene un labirinto."],
		],
	},
	"w13-miraggio": {
		"world": 13,
		"nome": "Miraggio",
		"ruolo": "Giura di aver visto qualcosa. Non ricorda cosa. Ma era enorme",
		"registro": "buffo",
		"tic": "ribadisce che era enorme",
		"ticMarker": "enorme",
		"battute": [
			["L'ho visto. A ovest, tre anni fa.", "Cos'era? Non lo so. Ma era enorme."],
			["Solano dice che nel deserto si vedono cose che non ci sono.", "Questa c'era. Enorme."],
			["Ho fatto un disegno.", "…è un rettangolo. Ma reso male: era molto più enorme."],
			["Ogni tanto torno a ovest a controllare.", "Non c'è più niente. Segno che si è spostato. Enorme e veloce."],
			["Duna dice che le cose lontane sembrano grandi.", "Sembrano. Quella era."],
		],
	},
	"w14-prefazio": {
		"world": 14,
		"nome": "Prefazio",
		"ruolo": "Racconta solo l'inizio delle storie. Il resto, dice, è ovvio",
		"registro": "buffo",
		"tic": "si interrompe dichiarando il resto ovvio",
		"ticMarker": "ovvio",
		"battute": [
			["C'era una volta un re che non voleva regnare.", "Il resto è ovvio. Prossima."],
			["Tre fratelli partono per il mare. Il più piccolo porta una chiave.", "…e da lì è ovvio, no?"],
			["Elmo mi ha chiesto il finale di una storia.", "Gli ho detto che era ovvio. Si è arrabbiato tantissimo."],
			["Gli inizi sono la parte difficile.", "Dopo la storia va da sola. Ovvio."],
			["Ottavia racconta anche la fine. Tre volte, per giunta.", "Fatica sprecata. Ma la ascolto sempre."],
		],
	},
	"w15-ronzino": {
		"world": 15,
		"nome": "Ronzino",
		"ruolo": "È convinto di essere un automa e nessuno ha il coraggio di dirglielo",
		"registro": "buffo",
		"tic": "descrive le proprie azioni come funzioni di macchina",
		"ticMarker": "funzione",
		"battute": [
			["Funzione attivata: saluto.", "Buongiorno. Funzione completata."],
			["Sono un automa di terza serie. Mi hanno costruito qui.", "Non ricordo la fabbrica, ma è normale nei modelli vecchi."],
			["Ho una funzione che si attiva quando qualcuno è triste.", "Non so cosa fa. Si attiva e basta."],
			["Gru mi dà i colpetti come alle macchine.", "Funzione gradita. Molto gradita."],
			["Ieri ho starnutito.", "Gli automi non starnutiscono. Sarà una funzione nuova."],
		],
	},
	"w16-tuttolingue": {
		"world": 16,
		"nome": "Tuttolingue",
		"ruolo": "Parla una lingua inventata da lui e si stupisce che nessuno la sappia",
		"registro": "buffo",
		"tic": "infila parole della sua lingua e le traduce male",
		"ticMarker": "vrenko",
		"battute": [
			["Vrenko! …come, non lo sai? Vuol dire «buongiorno». Lo sanno tutti."],
			["La mia lingua ha quattromila parole e tre tempi verbali.", "Vrenko è il più facile. E non lo sa nessuno."],
			["Talia dice che la mia grammatica è coerente.", "Vrenko! Cioè: grazie. Vale anche per grazie."],
			["Il problema non è la lingua. Il problema è che siete indietro."],
			["Ho scritto un dizionario.", "È in vrenko. Vrenko vuol dire anche «dizionario», adesso che ci penso."],
		],
	},
	"w17-scafandro": {
		"world": 17,
		"nome": "Scafandro",
		"ruolo": "Ha paura dell'acqua e fa il palombaro per orgoglio",
		"registro": "buffo",
		"tic": "dichiara di non avere paura",
		"ticMarker": "paura",
		"battute": [
			["Non ho paura dell'acqua.", "Ho un rapporto complicato con l'acqua. È diverso."],
			["Scendo domani. Ho detto domani anche ieri, ma domani è quello buono."],
			["Coral mi dà i numeri delle immersioni.", "Li studio tutti. Poi non scendo. Ma li so."],
			["Il casco me lo metto. È il resto che mi crea difficoltà.", "Non è paura, sia chiaro."],
			["Se un giorno l'acqua diventasse aria, sarei il migliore.", "E non per paura: per talento."],
		],
	},
	"w18-controcanto": {
		"world": 18,
		"nome": "Controcanto",
		"ruolo": "Canta sempre mezzo tono sotto e ne è fierissimo",
		"registro": "buffo",
		"tic": "rivendica il mezzo tono",
		"ticMarker": "mezzo tono",
		"battute": [
			["Sono sotto di mezzo tono. Di proposito.", "È una scelta artistica."],
			["Se tutti cantano uguale, chi si accorge del coro?", "Io sono il mezzo tono che vi fa notare."],
			["Bea mi ha messo nel punto della navata che divora i suoni.", "Gentilissima. Adesso il mio mezzo tono è intimo."],
			["Silo suona forte, io canto sotto.", "Ci compensiamo. Mezzo tono di differenza, nessun rancore."],
			["Una volta ho cantato giusto per sbaglio.", "Bruttissima esperienza. Mai più. Mezzo tono e basta."],
		],
	},
	"w19-lapidario": {
		"world": 19,
		"nome": "Lapidario",
		"ruolo": "Legge le epigrafi ad alta voce come fossero notizie del giorno",
		"registro": "buffo",
		"tic": "annuncia le epigrafi come titoli di giornale",
		"ticMarker": "notizia",
		"battute": [
			["Notizia del giorno: «Qui giace Marco, che amò il vino e la moglie, in quest'ordine».", "Ottocento anni fa. Ma è notizia fresca per chi non l'ha letta."],
			["Ultima ora dal settore quinto: «Il grano fu diviso in parti uguali».", "Notizia rassicurante. Rara, di questi tempi."],
			["Numa dice che disturbo i morti.", "I morti hanno scritto per essere letti. Notizia ovvia, direi."],
			["Fiorina ascolta mentre innaffia.", "Ho un pubblico. Notizia bellissima."],
			["Nel settore chiuso c'è un'iscrizione che non leggo mai ad alta voce.", "Quella non è una notizia. È una firma."],
		],
	},
	"w20-parafulmine": {
		"world": 20,
		"nome": "Parafulmine",
		"ruolo": "Aspetta di essere colpito da un fulmine per «vedere l'effetto che fa»",
		"registro": "buffo",
		"tic": "parla dell'effetto che farà",
		"ticMarker": "effetto",
		"battute": [
			["Sto qui col bastone di ferro.", "Voglio vedere l'effetto che fa."],
			["Quieto mi ha dato sette regole.", "La settima dice di non fare quello che faccio. L'ho letta. Effetto interessante."],
			["Non mi ha ancora colpito nessun fulmine.", "Comincio a prenderla sul personale."],
			["Sferza dice che l'effetto è che muoio.", "Sì, ma prima? Prima ci sarà un effetto."],
			["Se un giorno mi colpisce, ve lo racconto.", "Sarà l'effetto più raccontato della storia."],
		],
	},
	"w21-meteora": {
		"world": 21,
		"nome": "Meteora",
		"ruolo": "Prevede il tempo di ieri con precisione impressionante",
		"registro": "buffo",
		"tic": "annuncia previsioni al passato",
		"ticMarker": "ieri",
		"battute": [
			["Domani… no, aspetta. Ieri. Ieri pioveva.", "E infatti ha piovuto. Nove su nove."],
			["La mia percentuale di successo è del cento per cento.", "Sul passato. Sul futuro sto lavorando."],
			["Terza dice che non serve a niente.", "Ieri ha detto la stessa cosa. L'avevo previsto."],
			["Ho previsto la grandinata di tre anni fa.", "Con due anni e undici mesi di ritardo, ma l'ho presa in pieno."],
			["Mino mi dà il formaggio lo stesso.", "Anche ieri. L'avevo previsto."],
		],
	},
	"w22-muffa": {
		"world": 22,
		"nome": "Muffa",
		"ruolo": "Ha allevato una colonia di funghi e li considera colleghi",
		"registro": "buffo",
		"tic": "parla dei funghi come di uno staff",
		"ticMarker": "collegh",
		"battute": [
			["Ti presento i colleghi. Quello grande è il capoturno."],
			["Non li coltivo: collaboriamo.", "Loro crescono, io li ammiro. Divisione dei compiti."],
			["Vesca dice che scientificamente non sono colleghi.", "Scientificamente. Ma umanamente?"],
			["Ieri il collega del terzo scaffale ha fatto le spore.", "Grande soddisfazione per tutto il reparto."],
			["Fondo mi ha portato in una grotta con funghi che non conoscevo.", "Colleghi nuovi. Sono stato in imbarazzo per un'ora."],
		],
	},
	"w23-errata": {
		"world": 23,
		"nome": "Errata",
		"ruolo": "Timbra documenti a caso «per portarsi avanti»",
		"registro": "buffo",
		"tic": "giustifica ogni timbro con l'anticipo",
		"ticMarker": "avanti",
		"battute": [
			["Timbrato. Non so cosa fosse, ma adesso è timbrato.", "Mi porto avanti."],
			["Se un giorno serve un timbro, io ce l'ho già messo.", "Efficienza."],
			["Cronia mi ha sgridato.", "Poi si è guardata le mani. Ci portiamo avanti in due."],
			["Ho timbrato una scatola vuota.", "Quando la riempiranno, sarà già a posto. Avanti così."],
			["Ovidio mi ha dato fogli bianchi da timbrare.", "Ne ho fatti quattrocento. Mi sono portato avantissimo."],
		],
	},
}

## LA CONTA DI NONNA ERSILIA
##
## È la tabellina del sette, e nessuno nella radura lo sa. Il giocatore la sente
## nei primi cinque minuti di gioco (`TRAMA_E_MISTERO.md` §5.4).
##
## Le tre sillabe «sca · la · re» non sono un riempitivo: sono il nome cancellato
## del Tredicesimo, tramandato da chi non voleva che si perdesse. La rivelazione
## sta al mondo 19 e non va anticipata da nessuna parte — qui la conta è, per
## tutti, una canzone senza senso.
const CONTA_ERSILIA := {
	"id": "w01-conta-ersilia",
	"world": 1,
	"seedOf": "il-tredicesimo",
	"versi": [
		"Sette scalini per salir,",
		"quattordici per non finir,",
		"ventuno passi in mezzo al grano,",
		"ventotto e il monte è più lontano.",
		"Trentacinque, il vento gira,",
		"quarantadue, la corda tira.",
		"Quarantanove — sca —",
		"cinquantasei — la —",
		"sessantatré — re —",
		"settanta, e chi conta se ne va.",
	],
	"multipli": [7, 14, 21, 28, 35, 42, 49, 56, 63, 70],
	"sillabe": ["sca", "la", "re"],
}

## Dove la conta **riaffiora**. Aggiunto il 3 agosto, e chiude un buco serio.
##
## Le tre sillabe della conta sono la chiave del mondo 24: senza, il Tredicesimo
## non riavrà mai il suo nome. Ma la conta si sentiva **una volta sola**, nei
## primi cinque minuti di gioco, in un dialogo saltabile. Le tre Tracce decisive
## hanno un beat di ripiego proprio per non rendere obbligatorio un contenuto;
## la conta, che è più importante di tutte e tre, non ne aveva nessuno.
##
## Non risolvo con una spiegazione — sarebbe peggio del problema: se qualcuno
## dice «ricordati queste sillabe», l'enigma è già risolto. Risolvo con la
## ripetizione: la stessa filastrocca torna storpiata in bocca a chi non sa cosa
## sta cantando, che è anche il modo in cui una cosa attraversa quattro secoli.
const RIAFFIORAMENTI_CONTA := [
	{
		"world": 6,
		"dove": "Zufolo, il Bislacco del Giardino della Risonanza",
		"forma": "canticchiata storpiata, con le sillabe al posto giusto",
		"testo": "Quarantanove — sca — cinquantasei — la — sessantatré — re — e poi non mi ricordo come fa.",
		"spiegato": false,
	},
	{
		"world": 12,
		"dove": "Inciso su un muro del Labirinto delle Regole, a un bivio",
		"forma": "tre sillabe sole, come una firma",
		"testo": "sca · la · re",
		"spiegato": false,
	},
	{
		"world": 19,
		"dove": "Su una lapide della Necropoli, sotto il nome raschiato",
		"forma": "le sillabe separate da punti, come si incide un nome",
		"testo": "sca · la · re — «e chi conta se ne va»",
		"spiegato": false,
	},
]

## In quanti punti della campagna il giocatore può sentire le tre sillabe.
## Uno solo non basta: è la chiave del finale.
static func conta_occurrences() -> int:
	return 1 + RIAFFIORAMENTI_CONTA.size()

## CHI POSSIEDE QUALE EVENTO (sblocca C-P7 · A2)
##
## A2 dice «Codex non decide chi possiede cosa». Non lo decido nemmeno io evento
## per evento: lo decide una REGOLA. Gli eventi li pianifica `MissionEventDirector`
## a ogni partita con un seme diverso — una lista scritta a mano sarebbe vecchia
## al primo seme e falsa al secondo.
##
## La regola viene dai ruoli che il documento ha già assegnato, non è arbitraria:
##
## - le **missioni** sono dello SPECIALISTA: il problema del mondo è il suo, ed è
##   la sua convinzione sbagliata a essere in gioco;
## - gli **enigmi** sono del TESTIMONE, che «sa senza sapere di sapere e indica la
##   Rovina» — mandare il giocatore alla Rovina è letteralmente il suo ruolo;
## - la **pratica** non ha proprietario: è di chi passa di lì, cioè dell'itinerante
##   di turno (§5.4 del documento abitanti).
##
## Un evento senza proprietario resta perfettamente giocabile: nessun dialogo, e
## il gioco non si rompe. È il fallback previsto, e vale finché il catalogo non è
## completo di battute di richiesta.
static func owner_for(world: int, event_kind: String) -> String:
	for npc_id in RESIDENTS.keys():
		var npc := RESIDENTS[npc_id] as Dictionary
		if int(npc.get("world", 0)) != world:
			continue
		var funzione := str(npc.get("funzione", ""))
		if event_kind == "enigma" and funzione == "testimone":
			return str(npc_id)
		if event_kind == "mission" and funzione == "specialista":
			return str(npc_id)
	return ""

## Battute di richiesta e di consolazione, se il personaggio le ha.
## `consolazione` non contiene MAI una battuta di delusione: una sessione fallita
## è un motivo per riprovare insieme, non per far sentire in colpa (§5.4).
static func mission_lines(npc_id: String, pool: String) -> Array:
	var pools := (RESIDENTS.get(npc_id, {}) as Dictionary).get("battute", {}) as Dictionary
	return Array(pools.get(pool, [])).duplicate(true)

## Residenti pronti per il flusso completo di A2 (richiesta + consolazione).
## Diagnostico, non cricchetto: il contenuto arriva a ondate e il flusso degrada
## con grazia dove manca.
static func a2_ready() -> Array:
	var ready: Array = []
	for npc_id in RESIDENTS.keys():
		var pools := (RESIDENTS[npc_id] as Dictionary).get("battute", {}) as Dictionary
		if pools.has("richiesta") and pools.has("consolazione"):
			ready.append(str(npc_id))
	ready.sort()
	return ready

static func resident(npc_id: String) -> Dictionary:
	return (RESIDENTS.get(npc_id, {}) as Dictionary).duplicate(true)

static func bislacco(npc_id: String) -> Dictionary:
	return (BISLACCHI.get(npc_id, {}) as Dictionary).duplicate(true)

## Tutti gli abitanti di un mondo: due residenti più il Bislacco.
static func for_world(world: int) -> Dictionary:
	var residents: Array = []
	for key in RESIDENTS.keys():
		if int((RESIDENTS[key] as Dictionary).get("world", 0)) == world:
			residents.append(str(key))
	var jesters: Array = []
	for key in BISLACCHI.keys():
		if int((BISLACCHI[key] as Dictionary).get("world", 0)) == world:
			jesters.append(str(key))
	residents.sort()
	jesters.sort()
	return {"residents": residents, "bislacchi": jesters}

## Quante battute ha un personaggio: il minimo per la validazione è 12 per un
## residente (3 per stadio, 3 di reazione, 3 di riempimento) e 4 per un Bislacco.
static func line_count(npc_id: String) -> int:
	if BISLACCHI.has(npc_id):
		return Array((BISLACCHI[npc_id] as Dictionary).get("battute", [])).size()
	var pools := (RESIDENTS.get(npc_id, {}) as Dictionary).get("battute", {}) as Dictionary
	var total := 0
	for key in pools.keys():
		total += Array(pools[key]).size()
	return total
