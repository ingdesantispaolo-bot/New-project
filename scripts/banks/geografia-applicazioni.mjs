// Geografia — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Terza materia convertita alla regola delle dispense (`docs/REGOLA_DISPENSE.md`),
// e la più difficile delle tre. La misura del 1 settembre lo diceva già: **il 78%
// delle domande di geografia ha per risposta un NOME**, e su `capitali` e
// `continenti` è il 100%. «Qual è la capitale della Norvegia?» non si ragiona: si
// sa o non si sa.
//
// ## Che cosa fanno le dispense che le tavole non facevano
//
// Le quarantanove tavole di `TavoleRiferimento` elencano i nomi con la loro
// coordinata, e restano: nessuna dispensa ripete quell'elenco. Le sedici dispense
// di geografia fanno l'altra metà, che mancava — **dicono perché le cose stanno
// dove stanno**:
//
//   la tavola dice      Oslo, in fondo a un fiordo
//   la dispensa dice    le capitali antiche stanno dove passava il commercio, e
//                       la Norvegia è tutta costa
//
// Il primo è un nome da imparare; il secondo è un criterio che si applica a un
// Paese mai visto. Per questo qui le domande chiedono quasi sempre di APPLICARE
// il criterio, e le poche di richiamo nominano solo ciò che il documento nomina.
//
// ## Le regole di scrittura
//
// Le stesse degli altri lotti, più le due di `storia-applicazioni.mjs` — niente
// che il documento non abbia detto, distrattori che sono errori plausibili — più
// una che è di questa materia:
//
//   **Una domanda di nome si scrive solo se la dispensa quel nome lo pronuncia.**
//   Il controllo 4b di `dispense_audit` lo verifica riga per riga, e su geografia
//   è la differenza fra una prova e un tiro a indovinare. Se serve chiedere un
//   nome che il documento non contiene, quella domanda appartiene alle tavole, non
//   a questo file.

export const GEOGRAFIA_APPLICAZIONI = [

  // ==================================================== GEOGRAFIA FISICA
  { topic: "geografia-fisica", difficulty: 2, difficulty8: true, applica: "geografia-geografia-fisica-base",
    prompt: "Una terra è bagnata dal mare su tre lati e attaccata al continente sul quarto. Come si chiama?",
    answer: "Penisola", distractors: ["Isola", "Arcipelago", "Istmo"],
    explanation: "Il lato attaccato fa tutta la differenza: ci si arriva via terra senza attraversare acqua, ed è il caso dell'Italia.",
    distractorWhy: { "Isola": "Un'isola è circondata dal mare da ogni lato: qui un lato resta unito alla terraferma.", "Arcipelago": "È un gruppo di isole vicine, quindi più terre e non una sola.", "Istmo": "È la striscia sottile che unisce due terre, non la terra che sporge nel mare." } },

  { topic: "geografia-fisica", difficulty: 3, difficulty8: true, applica: "geografia-geografia-fisica-base",
    format: "short_answer",
    prompt: "Come si chiama un gruppo di isole vicine fra loro, considerate come un insieme?",
    answer: "arcipelago", accept: ["un arcipelago", "l'arcipelago"],
    explanation: "Si usa il nome collettivo perché quelle isole condividono clima, storia e spesso abitanti: separarle sulla carta avrebbe poco senso." },

  { topic: "geografia-fisica", difficulty: 4, difficulty8: true, applica: "geografia-geografia-fisica-base",
    prompt: "Perché le catene montuose più alte del pianeta sono anche le più giovani?",
    answer: "Perché l'erosione non le ha ancora consumate", distractors: ["Perché la roccia giovane è più dura", "Perché si formano sempre più in alto", "Perché la Terra si sta raffreddando"],
    explanation: "Pioggia, gelo e vento smussano ogni rilievo senza mai fermarsi: una catena appena sollevata non ha ancora avuto il tempo di essere consumata.",
    distractorWhy: { "Perché la roccia giovane è più dura": "La durezza dipende dal tipo di roccia, non dall'età del sollevamento.", "Perché si formano sempre più in alto": "Ogni catena si solleva dal terreno che c'era: non esiste una quota di partenza che aumenta.", "Perché la Terra si sta raffreddando": "Il raffreddamento del pianeta non c'entra con l'altezza di una catena, che dipende da spinta ed erosione." } },

  { topic: "geografia-fisica", difficulty: 5, difficulty8: true, applica: "geografia-geografia-fisica-alta",
    prompt: "Perché i grandi deserti caldi stanno quasi tutti intorno ai trenta gradi di latitudine?",
    answer: "Perché lì ridiscende aria già asciutta", distractors: ["Perché lì il sole è più vicino alla Terra", "Perché lì il vento soffia più forte", "Perché lì la sabbia si accumula da sola"],
    explanation: "L'aria sale all'equatore, scarica lì tutta la pioggia, viaggia in quota e ritorna al suolo a quella latitudine ormai senza umidità.",
    distractorWhy: { "Perché lì il sole è più vicino alla Terra": "La distanza dal Sole è praticamente la stessa per tutto il pianeta: cambia l'inclinazione dei raggi, non la distanza.", "Perché lì il vento soffia più forte": "Il vento sposta la sabbia ma non toglie l'umidità: sono i deserti a fare il vento, non il contrario.", "Perché lì la sabbia si accumula da sola": "La sabbia è una conseguenza dell'aridità, non la sua causa: esistono deserti di roccia e di ghiaccio." } },

  { topic: "geografia-fisica", difficulty: 6, difficulty8: true, applica: "geografia-geografia-fisica-alta",
    format: "short_answer",
    prompt: "Come si chiama il più esteso deserto caldo della Terra, che occupa il nord dell'Africa?",
    answer: "Sahara", accept: ["il sahara", "deserto del sahara"],
    explanation: "Sta esattamente sulla fascia dei trenta gradi, dove ridiscende l'aria che ha già scaricato la sua pioggia sull'equatore." },

  { topic: "geografia-fisica", difficulty: 7, difficulty8: true, applica: "geografia-geografia-fisica-alta",
    prompt: "Un fiume lunghissimo attraversa il deserto, un altro più corto raccoglie una foresta piovosa. Quale porta più acqua?",
    answer: "Quello più corto nella foresta", distractors: ["Quello più lungo nel deserto", "Ne portano la stessa quantità", "Dipende solo dalla larghezza"],
    explanation: "La portata dipende da quanta pioggia cade sul bacino, non da quanta strada fa il fiume: una foresta ne raccoglie enormemente di più di un deserto.",
    distractorWhy: { "Quello più lungo nel deserto": "Confonde lunghezza e portata: il Nilo è lunghissimo e attraversa il deserto, e ne arriva poca.", "Ne portano la stessa quantità": "Non c'è nessuna ragione per cui debbano coincidere: sono due misure indipendenti l'una dall'altra.", "Dipende solo dalla larghezza": "La larghezza è un effetto della portata e della pendenza, non la causa di quanta acqua arriva." } },

  // =============================================================== CLIMI
  { topic: "climi", difficulty: 1, difficulty8: true, applica: "geografia-climi-base",
    prompt: "Perché all'Equatore fa più caldo che ai poli, se il Sole è lo stesso?",
    answer: "Perché i raggi arrivano più dritti", distractors: ["Perché l'Equatore è più vicino al Sole", "Perché ai poli c'è più ghiaccio", "Perché ai poli il Sole è più piccolo"],
    explanation: "Su una sfera i raggi colpiscono l'equatore quasi perpendicolari e concentrano il calore; ai poli arrivano radenti e lo spalmano su molta più superficie.",
    distractorWhy: { "Perché l'Equatore è più vicino al Sole": "La differenza di distanza fra equatore e poli è trascurabile: quello che cambia è l'angolo dei raggi.", "Perché ai poli c'è più ghiaccio": "Il ghiaccio è una conseguenza del freddo, non la sua causa: senza freddo non ci sarebbe.", "Perché ai poli il Sole è più piccolo": "Il Sole è lo stesso corpo visto da ogni punto del pianeta: cambia solo quanto in alto sale nel cielo." } },

  { topic: "climi", difficulty: 3, difficulty8: true, applica: "geografia-climi-base",
    format: "short_answer",
    prompt: "Come si chiama la media del tempo atmosferico calcolata su molti anni in un luogo?",
    answer: "clima", accept: ["il clima"],
    explanation: "Di solito si usano trent'anni. Per questo una giornata o una stagione fuori media non smentiscono nulla: per parlarne servono decenni di misure." },

  { topic: "climi", difficulty: 4, difficulty8: true, applica: "geografia-climi-base",
    format: "numeric_input",
    prompt: "Salendo di mille metri di quota, di quanti gradi cala circa la temperatura?",
    answer: "6",
    explanation: "È il motivo per cui esistono ghiacciai anche in Africa: basta essere abbastanza in alto, e l'altitudine compensa la latitudine." },

  { topic: "climi", difficulty: 6, difficulty8: true, applica: "geografia-climi-alta",
    prompt: "Perché in Italia piove molto più d'inverno che d'estate?",
    answer: "Perché d'estate l'alta pressione le blocca", distractors: ["Perché d'estate il mare è troppo caldo", "Perché d'estate manca l'acqua nell'aria", "Perché d'inverno il Sole scalda di meno"],
    explanation: "D'estate la fascia di alta pressione dei deserti risale e copre il Mediterraneo, spingendo via le perturbazioni; d'inverno scende, e quelle atlantiche rientrano.",
    distractorWhy: { "Perché d'estate il mare è troppo caldo": "Un mare caldo fornisce anzi più umidità: quello che manca è il meccanismo che la faccia salire e condensare.", "Perché d'estate manca l'acqua nell'aria": "L'aria calda può contenerne molta di più: il problema non è la quantità ma che non viene sollevata.", "Perché d'inverno il Sole scalda di meno": "Spiega perché fa più freddo, non perché cadano più millimetri di pioggia." } },

  { topic: "climi", difficulty: 6, difficulty8: true, applica: "geografia-climi-alta",
    format: "short_answer",
    prompt: "Come si chiama l'ambiente con erba alta, alberi radi e una lunga stagione secca, poco oltre l'Equatore?",
    answer: "savana", accept: ["la savana"],
    explanation: "Riceve quasi la stessa acqua della foresta pluviale ma tutta concentrata in una sola stagione: è la distribuzione, non la quantità, a fare la differenza." },

  { topic: "climi", difficulty: 7, difficulty8: true, applica: "geografia-climi-alta",
    prompt: "Di giorno, al mare, la brezza soffia dall'acqua verso la spiaggia. Perché?",
    answer: "Perché la terra si scalda più in fretta", distractors: ["Perché il mare spinge l'aria a riva", "Perché le onde sollevano il vento", "Perché di giorno la pressione sale ovunque"],
    explanation: "La terra si scalda prima, l'aria sopra di essa sale e lascia pressione bassa: quella più fresca del mare scivola a prenderne il posto. Di notte la cosa si rovescia.",
    distractorWhy: { "Perché il mare spinge l'aria a riva": "L'acqua non spinge l'aria: il movimento nasce da una differenza di pressione, non da una spinta meccanica.", "Perché le onde sollevano il vento": "Sono le onde a essere fatte dal vento, e non il contrario.", "Perché di giorno la pressione sale ovunque": "Se salisse ovunque allo stesso modo non ci sarebbe nessuna differenza, e quindi nessun vento." } },

  // ========================================================== CONTINENTI
  { topic: "continenti", difficulty: 1, difficulty8: true, applica: "geografia-continenti-base",
    prompt: "Quanti sono i continenti, e quanti di essi sono abitati stabilmente?",
    answer: "Sette, e sei abitati", distractors: ["Sette, e tutti abitati", "Sei, e tutti abitati", "Cinque, e quattro abitati"],
    explanation: "L'Antartide è un continente a tutti gli effetti ma non ha popolazione residente: solo basi scientifiche in cui i ricercatori si alternano.",
    distractorWhy: { "Sette, e tutti abitati": "Conta bene i continenti ma dimentica che in Antartide nessuno risiede stabilmente.", "Sei, e tutti abitati": "Toglie l'Antartide dal conto dei continenti invece che da quello degli abitati: resta un continente.", "Cinque, e quattro abitati": "È il conteggio dei cerchi olimpici, che raggruppano le due Americhe e lasciano fuori l'Antartide." } },

  { topic: "continenti", difficulty: 2, difficulty8: true, applica: "geografia-continenti-base",
    format: "short_answer",
    prompt: "Quale continente non ha popolazione residente, ma soltanto basi scientifiche?",
    answer: "Antartide", accept: ["l'antartide", "antartide"],
    explanation: "I ricercatori si alternano per qualche mese e poi rientrano: nessuno ci nasce, ci cresce e ci resta, ed è l'unico continente di cui si possa dirlo." },

  { topic: "continenti", difficulty: 4, difficulty8: true, applica: "geografia-continenti-base",
    prompt: "Perché il confine fra Europa e Asia non è un mare come tutti gli altri confini fra continenti?",
    answer: "Perché stanno sulla stessa terra", distractors: ["Perché il mare in mezzo è troppo stretto", "Perché nessuno lo ha mai misurato", "Perché il confine cambia ogni secolo"],
    explanation: "Sono un unico blocco continuo di terra, e la linea che le separa è tracciata per convenzione lungo i Monti Urali: è una scelta storica e culturale.",
    distractorWhy: { "Perché il mare in mezzo è troppo stretto": "Non c'è nessun mare in mezzo: a est l'Europa continua nella stessa massa di terra.", "Perché nessuno lo ha mai misurato": "Il confine è tracciato con precisione: quello che gli manca non è la misura ma una base naturale.", "Perché il confine cambia ogni secolo": "La convenzione degli Urali è stabile da molto tempo: a cambiare sono i confini politici, non questo." } },

  { topic: "continenti", difficulty: 5, difficulty8: true, applica: "geografia-continenti-alta",
    prompt: "Perché la costa occidentale dell'Africa e quella orientale del Sud America sembrano combaciare?",
    answer: "Perché erano attaccate e si sono separate", distractors: ["Perché le ha scavate la stessa corrente", "Perché sono state disegnate in scala", "Perché il vento le ha erose allo stesso modo"],
    explanation: "Facevano parte dello stesso blocco unico, la Pangea: quando si è spezzato l'Atlantico si è aperto nello spazio rimasto in mezzo.",
    distractorWhy: { "Perché le ha scavate la stessa corrente": "Una corrente modella il dettaglio di una costa, non la forma generale di due continenti.", "Perché sono state disegnate in scala": "La somiglianza si vede su qualunque carta e su qualunque scala: non è un effetto del disegno.", "Perché il vento le ha erose allo stesso modo": "L'erosione agisce su tempi e modi diversi ai due lati di un oceano: non potrebbe produrre due profili complementari." } },

  { topic: "continenti", difficulty: 6, difficulty8: true, applica: "geografia-continenti-alta",
    format: "short_answer",
    prompt: "Come si chiama il blocco unico in cui erano riunite tutte le terre emerse duecento milioni di anni fa?",
    answer: "Pangea", accept: ["la pangea", "pangea"],
    explanation: "Poi si è spezzato e i frammenti si sono allontanati di pochi centimetri l'anno: su tempi lunghissimi quei centimetri fanno migliaia di chilometri." },

  { topic: "continenti", difficulty: 8, difficulty8: true, applica: "geografia-continenti-alta",
    prompt: "Dove avviene la quasi totalità dei terremoti e delle eruzioni vulcaniche?",
    answer: "Sui bordi delle placche", distractors: ["Al centro dei continenti", "Sul fondo degli oceani", "Vicino ai due poli"],
    explanation: "È lì che le placche si scontrano, si allontanano o scorrono l'una accanto all'altra: al centro di una placca non succede quasi niente.",
    distractorWhy: { "Al centro dei continenti": "È la zona più tranquilla: l'attività si concentra sui margini, dove le placche si toccano.", "Sul fondo degli oceani": "Sul fondo ci sono le dorsali, che sono bordi di placca: non è il fondo in quanto tale a contare, è il bordo.", "Vicino ai due poli": "La latitudine non c'entra: il cerchio di fuoco corre attorno al Pacifico attraversando ogni fascia climatica." } },

  // =============================================================== MONDO
  { topic: "mondo", difficulty: 1, difficulty8: true, applica: "geografia-mondo-base",
    prompt: "Che cosa copre più superficie del pianeta: le terre emerse o gli oceani?",
    answer: "Gli oceani, di gran lunga", distractors: ["Le terre emerse, di poco", "Sono quasi in parità", "Dipende dalla stagione"],
    explanation: "L'acqua salata copre circa il settanta per cento della superficie: le terre emerse sono meno di un terzo del totale.",
    distractorWhy: { "Le terre emerse, di poco": "È il contrario, e non di poco: il rapporto è circa settanta a trenta in favore dell'acqua.", "Sono quasi in parità": "La differenza è grande: il solo Pacifico copre più superficie di tutte le terre messe insieme.", "Dipende dalla stagione": "Le stagioni spostano il ghiaccio marino di poco, e non cambiano il rapporto fra terre e oceani." } },

  { topic: "mondo", difficulty: 3, difficulty8: true, applica: "geografia-mondo-base",
    format: "short_answer",
    prompt: "Quale oceano, da solo, copre più superficie di tutte le terre emerse messe insieme?",
    answer: "Pacifico", accept: ["il pacifico", "oceano pacifico"],
    explanation: "È anche il più profondo. Il suo bordo coincide in gran parte con il cerchio di fuoco, la corona di vulcani e terremoti che lo circonda." },

  { topic: "mondo", difficulty: 4, difficulty8: true, applica: "geografia-mondo-base",
    prompt: "A dicembre, in Australia, la stagione è…",
    answer: "piena estate", distractors: ["pieno inverno", "inizio primavera", "uguale che in Europa"],
    explanation: "L'Australia è nell'emisfero meridionale, dove le stagioni sono invertite: a dicembre quell'emisfero è quello rivolto verso il Sole.",
    distractorWhy: { "pieno inverno": "Applica il calendario dell'emisfero settentrionale a un Paese che sta nell'altro.", "inizio primavera": "Nell'emisfero meridionale la primavera comincia a settembre, non a dicembre.", "uguale che in Europa": "È proprio quello che non succede: l'inclinazione dell'asse terrestre rende opposte le stagioni dei due emisferi." } },

  { topic: "mondo", difficulty: 5, difficulty8: true, applica: "geografia-mondo-alta",
    prompt: "Perché il Canale di Suez è così importante per il commercio mondiale?",
    answer: "Evita alle navi il giro dell'Africa", distractors: ["Collega due oceani mai collegati", "È l'unico passaggio verso l'Atlantico", "Permette di evitare le tempeste"],
    explanation: "Aperto nel 1869 fra Mediterraneo e Mar Rosso: prima una nave diretta in Asia doveva circumnavigare l'intero continente africano.",
    distractorWhy: { "Collega due oceani mai collegati": "I due bacini erano già collegati girando attorno all'Africa: il canale accorcia la strada, non la crea.", "È l'unico passaggio verso l'Atlantico": "Per l'Atlantico si passa da Gibilterra: Suez porta nella direzione opposta, verso il Mar Rosso.", "Permette di evitare le tempeste": "Qualche tratto pericoloso si evita, ma la ragione economica è il tempo risparmiato, non il meteo." } },

  { topic: "mondo", difficulty: 6, difficulty8: true, applica: "geografia-mondo-alta",
    format: "numeric_input",
    prompt: "Quanti gradi di longitudine copre in media un fuso orario?",
    answer: "15",
    explanation: "La Terra compie trecentosessanta gradi in ventiquattro ore: dividendo si ottengono quindici gradi per ogni ora di differenza." },

  { topic: "mondo", difficulty: 8, difficulty8: true, applica: "geografia-mondo-alta",
    format: "short_answer",
    prompt: "Quale canale collega Atlantico e Pacifico evitando alle navi il giro del Sud America?",
    answer: "Canale di Panama", accept: ["panama", "il canale di panama"],
    explanation: "Aperto nel 1914. Come Suez, il suo valore è il tempo risparmiato, ed è la ragione per cui il controllo di un canale è sempre stato una questione politica." },

  // ============================================================== EUROPA
  { topic: "europa", difficulty: 2, difficulty8: true, applica: "geografia-europa-base",
    prompt: "Perché per gli europei il mare è sempre stato una strada vicina e non un confine lontano?",
    answer: "Perché il continente è molto frastagliato", distractors: ["Perché l'Europa è il continente più grande", "Perché in Europa non ci sono montagne", "Perché il Mediterraneo non ha maree"],
    explanation: "Penisole e isole ovunque danno all'Europa un rapporto altissimo fra coste e superficie: nessun suo punto è davvero lontano dall'acqua.",
    distractorWhy: { "Perché l'Europa è il continente più grande": "È il secondo più piccolo: quello che la distingue non è la dimensione ma la forma.", "Perché in Europa non ci sono montagne": "Ce ne sono e sono importanti, a cominciare dalle Alpi: non è questo a rendere il mare vicino.", "Perché il Mediterraneo non ha maree": "Le maree sono deboli ma esistono, e comunque non spiegano la vicinanza del mare alle terre." } },

  { topic: "europa", difficulty: 3, difficulty8: true, applica: "geografia-europa-base",
    format: "short_answer",
    prompt: "Quale fiume collega le Alpi al Mare del Nord ed è la via d'acqua più trafficata d'Europa?",
    answer: "Reno", accept: ["il reno"],
    explanation: "I fiumi europei sono corti ma quasi tutti navigabili, e per secoli sono stati le vere autostrade del continente: questo è il più usato di tutti." },

  { topic: "europa", difficulty: 4, difficulty8: true, applica: "geografia-europa-base",
    prompt: "Parigi è nata su un'isola in mezzo a un fiume. Quale?",
    answer: "Senna", distractors: ["Reno", "Danubio", "Volga"],
    explanation: "Un'isola fluviale è facile da difendere e sta su un punto di guado: è il genere di posto in cui nascono le città destinate a crescere.",
    distractorWhy: { "Reno": "Scorre più a est, dalle Alpi al Mare del Nord, e non passa per Parigi.", "Danubio": "Nasce in Germania e scorre verso est fino al Mar Nero, nella direzione opposta.", "Volga": "È il fiume più lungo d'Europa e scorre in Russia, a migliaia di chilometri da Parigi." } },

  { topic: "europa", difficulty: 6, difficulty8: true, applica: "geografia-europa-alta",
    prompt: "L'Unione Europea nasce mettendo in comune carbone e acciaio. Perché proprio quelli?",
    answer: "Perché sono le materie delle armi", distractors: ["Perché erano i prodotti più venduti", "Perché scarseggiavano ovunque", "Perché erano i più facili da tassare"],
    explanation: "Legare la produzione delle materie con cui si fabbricano le armi rende una guerra futura non solo sbagliata ma tecnicamente scomoda: era il punto.",
    distractorWhy: { "Perché erano i prodotti più venduti": "Il criterio non era commerciale: si cercava il punto in cui l'interdipendenza pesasse di più sulla guerra.", "Perché scarseggiavano ovunque": "Erano anzi abbondanti nella regione fra Francia e Germania, e proprio per questo contesi.", "Perché erano i più facili da tassare": "L'accordo serviva a togliere barriere, non a metterne: le tasse non c'entrano." } },

  { topic: "europa", difficulty: 7, difficulty8: true, applica: "geografia-europa-alta",
    prompt: "Tutti gli Stati membri dell'Unione Europea usano l'euro?",
    answer: "No, solo una parte", distractors: ["Sì, è obbligatorio", "No, quasi nessuno", "Sì, dalla fondazione"],
    explanation: "Alcuni membri hanno mantenuto la propria moneta: l'adesione all'Unione e l'adozione della moneta comune sono due scelte separate.",
    distractorWhy: { "Sì, è obbligatorio": "Non lo è: l'Unione è un insieme di accordi a cui ciascuno partecipa in misura diversa.", "No, quasi nessuno": "L'euro è adottato dalla maggioranza dei membri: la minoranza è chi ha tenuto la propria valuta.", "Sì, dalla fondazione": "L'Unione esiste da decenni prima dell'euro, che è arrivato molto più tardi." } },

  { topic: "europa", difficulty: 8, difficulty8: true, applica: "geografia-europa-alta",
    prompt: "Confrontando una carta del 1900 e una di oggi, quale delle due cambia quasi del tutto?",
    answer: "Carta politica", distractors: ["Carta fisica", "Cambiano allo stesso modo", "Nessuna delle due cambia"],
    explanation: "Gli Stati nascono, si uniscono e si dividono; montagne, fiumi e coste si muovono su tempi geologici e restano dove sono.",
    distractorWhy: { "Carta fisica": "Rilievi e coste cambiano su scale di milioni di anni: in un secolo sono praticamente identici.", "Cambiano allo stesso modo": "I confini politici sono decisioni umane e cambiano in pochi anni: i due tipi di carta invecchiano a velocità diversissime.", "Nessuna delle due cambia": "La carta politica dell'Europa del 1900 mostra Stati che oggi non esistono più." } },

  // =================================================== GEOGRAFIA ITALIA
  { topic: "geografia-italia", difficulty: 1, difficulty8: true, applica: "geografia-geografia-italia-base",
    prompt: "Quale catena montuosa chiude l'Italia a nord, separandola dal resto d'Europa?",
    answer: "Le Alpi", distractors: ["Gli Appennini", "I Pirenei", "I Monti Urali"],
    explanation: "Formano un arco da ovest a est e sono le montagne più alte d'Europa: è l'unico lato del Paese che non dà sul mare.",
    distractorWhy: { "Gli Appennini": "Percorrono la penisola da nord a sud, nel senso della lunghezza, e non la chiudono in alto.", "I Pirenei": "Separano Spagna e Francia, all'altro capo del Mediterraneo occidentale.", "I Monti Urali": "Stanno in Russia e segnano il confine convenzionale fra Europa e Asia." } },

  { topic: "geografia-italia", difficulty: 3, difficulty8: true, applica: "geografia-geografia-italia-base",
    format: "short_answer",
    prompt: "Come si chiama la catena che percorre l'Italia da nord a sud, come una spina dorsale?",
    answer: "Appennini", accept: ["gli appennini", "appennino"],
    explanation: "Più bassa e più antica delle Alpi, corre vicino al mare per gran parte del percorso: è per questo che i fiumi del centro-sud sono corti." },

  { topic: "geografia-italia", difficulty: 4, difficulty8: true, applica: "geografia-geografia-italia-base",
    prompt: "Perché i fiumi del centro e del sud Italia sono molto più corti del Po?",
    answer: "Perché i monti sono vicini al mare", distractors: ["Perché al sud piove molto di meno", "Perché scorrono più lentamente", "Perché le sorgenti sono più basse"],
    explanation: "Gli Appennini corrono vicini alla costa: l'acqua che nasce lì ha pochissima strada da fare prima di arrivare al mare.",
    distractorWhy: { "Perché al sud piove molto di meno": "La quantità di pioggia influenza la portata, non la lunghezza del percorso.", "Perché scorrono più lentamente": "Scendendo da monti vicini alla costa sono anzi più rapidi e irregolari.", "Perché le sorgenti sono più basse": "Quello che conta è la distanza dal mare, non la quota di partenza." } },

  { topic: "geografia-italia", difficulty: 5, difficulty8: true, applica: "geografia-geografia-italia-alta",
    prompt: "Perché in Italia montagne, terremoti e vulcani si presentano tutti insieme?",
    answer: "Perché hanno la stessa causa", distractors: ["Perché il Paese è molto lungo", "Perché è circondato dal mare", "Perché ha un clima particolare"],
    explanation: "La placca africana spinge contro quella euroasiatica: il terreno compresso si corruga, si spezza e lascia risalire materiale fuso. Una causa, tre effetti.",
    distractorWhy: { "Perché il Paese è molto lungo": "La lunghezza spiega le differenze di clima fra nord e sud, non i terremoti.", "Perché è circondato dal mare": "Il mare non produce né montagne né vulcani: molti Paesi costieri non hanno né gli uni né gli altri.", "Perché ha un clima particolare": "Il clima agisce sulla superficie; terremoti e vulcani vengono da molto più in profondità." } },

  { topic: "geografia-italia", difficulty: 7, difficulty8: true, applica: "geografia-geografia-italia-alta",
    prompt: "Come si è formata la Pianura Padana, dove milioni di anni fa c'era il mare?",
    answer: "Riempita dai detriti dei fiumi", distractors: ["Sollevata da un terremoto", "Prosciugata dagli abitanti", "Scavata da un grande ghiacciaio"],
    explanation: "I fiumi alpini e appenninici hanno depositato sabbia, ghiaia e limo strappati alle montagne per milioni di anni, riempiendo un antico golfo strato su strato.",
    distractorWhy: { "Sollevata da un terremoto": "Un terremoto è un movimento di pochi istanti e di pochi metri: non costruisce una pianura.", "Prosciugata dagli abitanti": "Le bonifiche hanno riguardato paludi già emerse, molto più tardi e su superfici piccolissime.", "Scavata da un grande ghiacciaio": "I ghiacciai hanno scavato i laghi prealpini: la pianura non è stata scavata ma riempita." } },

  { topic: "geografia-italia", difficulty: 8, difficulty8: true, applica: "geografia-geografia-italia-alta",
    prompt: "Perché la Pianura Padana ha sbalzi fra estate e inverno più forti di una città di mare alla stessa latitudine?",
    answer: "Perché è lontana dal mare", distractors: ["Perché è più alta sul livello del mare", "Perché riceve molta più pioggia", "Perché il Sole vi arriva più dritto"],
    explanation: "L'acqua si scalda e si raffredda molto lentamente e smorza gli estremi: dove il mare è lontano e le montagne chiudono, quel freno non c'è.",
    distractorWhy: { "Perché è più alta sul livello del mare": "È una pianura, quindi molto bassa: l'altitudine qui non spiega niente.", "Perché riceve molta più pioggia": "La pioggia influenza l'umidità, non l'ampiezza dell'escursione fra le stagioni.", "Perché il Sole vi arriva più dritto": "A parità di latitudine l'inclinazione dei raggi è la stessa: quello che cambia è la vicinanza all'acqua." } },

  // ==================================================== GEOGRAFIA UMANA
  { topic: "geografia-umana", difficulty: 1, difficulty8: true, applica: "geografia-geografia-umana-base",
    format: "short_answer",
    prompt: "Da quale punto cardinale tramonta il Sole?",
    answer: "ovest", accept: ["a ovest", "l'ovest", "occidente"],
    explanation: "Sorge a est e tramonta a ovest, ogni giorno e ovunque: è il riferimento più antico e più affidabile per orientarsi senza strumenti." },

  { topic: "geografia-umana", difficulty: 3, difficulty8: true, applica: "geografia-geografia-umana-base",
    prompt: "Su una carta in scala 1:100.000, a quanto corrisponde un centimetro sul foglio?",
    answer: "Un chilometro", distractors: ["Cento metri", "Dieci chilometri", "Cento chilometri"],
    explanation: "Centomila centimetri fanno mille metri, cioè un chilometro: la scala dice esattamente di quanto la realtà è stata rimpicciolita.",
    distractorWhy: { "Cento metri": "Sarebbe la scala 1:10.000, dieci volte più dettagliata di questa.", "Dieci chilometri": "Sarebbe la scala 1:1.000.000, dieci volte più ridotta.", "Cento chilometri": "Sarebbe una riduzione enorme, da mappamondo: su un foglio ci starebbe un continente intero." } },

  { topic: "geografia-umana", difficulty: 4, difficulty8: true, applica: "geografia-geografia-umana-base",
    prompt: "Devi sapere dove passa un fiume e quanto è alta una catena. Quale carta apri?",
    answer: "La carta fisica", distractors: ["La carta politica", "Una carta stradale", "Una carta dei fusi orari"],
    explanation: "La carta fisica disegna il terreno — rilievi, acque, coste — con i colori dell'altitudine. I confini fra Stati stanno invece su quella politica.",
    distractorWhy: { "La carta politica": "Mostra confini, capitali e città: i fiumi al massimo li accenna, e le altitudini non le dà affatto.", "Una carta stradale": "Serve a spostarsi fra luoghi abitati: il rilievo ci compare solo come sfondo.", "Una carta dei fusi orari": "Mostra soltanto come è divisa l'ora: del terreno non dice nulla." } },

  { topic: "geografia-umana", difficulty: 6, difficulty8: true, applica: "geografia-geografia-umana-alta",
    prompt: "Il Canada ha densità bassissima, eppure quasi tutti i canadesi vivono addensati vicino al confine sud. Che cosa insegna?",
    answer: "Che la media nasconde i vuoti", distractors: ["Che il dato è stato calcolato male", "Che la densità non serve a niente", "Che il Paese è più piccolo del previsto"],
    explanation: "La densità è abitanti diviso superficie, cioè una media: mescola in un numero solo le zone affollate e quelle disabitate, e non descrive nessuna delle due.",
    distractorWhy: { "Che il dato è stato calcolato male": "Il calcolo è corretto: il limite non è nell'aritmetica ma in che cosa una media può dire.", "Che la densità non serve a niente": "Serve eccome per confrontare Paesi: va solo letta sapendo che è una media.", "Che il Paese è più piccolo del previsto": "È il secondo Paese più esteso del mondo: è proprio la sua vastità a rendere bassa la media." } },

  { topic: "geografia-umana", difficulty: 6, difficulty8: true, applica: "geografia-geografia-umana-alta",
    format: "short_answer",
    prompt: "Come si chiama lo spostamento della popolazione dalle campagne verso le città?",
    answer: "urbanizzazione", accept: ["l'urbanizzazione"],
    explanation: "Comincia con la rivoluzione industriale e non si è più fermata: da circa il 2007 più della metà dell'umanità vive in centri urbani." },

  { topic: "geografia-umana", difficulty: 8, difficulty8: true, applica: "geografia-geografia-umana-alta",
    prompt: "Perché quasi tutte le grandi città del mondo sono nate vicino a un fiume o a una costa?",
    answer: "Perché sull'acqua il trasporto costa meno", distractors: ["Perché l'aria di mare è più salubre", "Perché i confini seguono i fiumi", "Perché il terreno è più facile da scavare"],
    explanation: "Acqua dolce e terra fertile contano, ma la ragione decisiva è economica: per gran parte della storia muovere merci pesanti sull'acqua è stato l'unico modo conveniente.",
    distractorWhy: { "Perché l'aria di mare è più salubre": "Molte grandi città fluviali sono nell'entroterra, e storicamente le zone umide erano anzi malsane.", "Perché i confini seguono i fiumi": "Capita spesso, ma un confine non attira abitanti: semmai li divide.", "Perché il terreno è più facile da scavare": "Il terreno alluvionale è morbido ma anche instabile: non è questo a decidere dove nasce una città." } },

  // ============================================================ CAPITALI
  { topic: "capitali", difficulty: 1, difficulty8: true, applica: "geografia-capitali-base",
    format: "short_answer",
    prompt: "Qual è la capitale del Regno Unito, nata sul Tamigi nel primo punto dal mare in cui si poteva costruire un ponte?",
    answer: "Londra", accept: ["londra"],
    explanation: "È il criterio generale delle capitali antiche: nascono dove passava qualcosa — un guado, un ponte, un porto — perché chi controlla un passaggio accumula potere." },

  { topic: "capitali", difficulty: 3, difficulty8: true, applica: "geografia-capitali-base",
    prompt: "Che cos'è esattamente la capitale di uno Stato?",
    answer: "La sede del suo governo", distractors: ["La città con più abitanti", "La città più antica", "La città con più monumenti"],
    explanation: "È dove stanno parlamento, ministeri e capo dello Stato: la domanda «qual è la capitale» e la domanda «qual è la città più grande» sono due domande diverse.",
    distractorWhy: { "La città con più abitanti": "In Europa spesso coincidono, ma è un'abitudine e non una regola: negli Stati Uniti la più popolosa è New York.", "La città più antica": "L'età non c'entra: molte capitali sono state fondate di recente, e qualcuna costruita da zero.", "La città con più monumenti": "I monumenti seguono la storia di una città, non il posto in cui oggi si prendono le decisioni." } },

  { topic: "capitali", difficulty: 4, difficulty8: true, applica: "geografia-capitali-base",
    prompt: "Negli Stati Uniti la città più popolosa è New York. Qual è la capitale?",
    answer: "Washington", distractors: ["New York", "Los Angeles", "Chicago"],
    explanation: "È il caso che smonta l'abitudine europea: fuori dall'Europa capitale e città più grande molto spesso non coincidono, e quasi sempre per una scelta precisa.",
    distractorWhy: { "New York": "È la città più popolosa e il centro economico, ma il governo federale non ha sede lì.", "Los Angeles": "È la seconda città per popolazione, sulla costa opposta, e non ha mai avuto ruolo di capitale.", "Chicago": "È una grande città dell'interno, ma le istituzioni federali non vi hanno sede." } },

  { topic: "capitali", difficulty: 5, difficulty8: true, applica: "geografia-capitali-alta",
    prompt: "Perché la capitale dell'Australia è Canberra e non Sydney, che è molto più grande?",
    answer: "Perché Sydney e Melbourne erano rivali", distractors: ["Perché Sydney è troppo lontana dal mare", "Perché Canberra è la città più antica", "Perché Sydney era già una capitale estera"],
    explanation: "Scegliere una delle due rivali avrebbe dato un vantaggio permanente a metà del Paese: si fondò una città nuova in mezzo, in una zona allora quasi disabitata.",
    distractorWhy: { "Perché Sydney è troppo lontana dal mare": "Sydney è una città portuale sulla costa: è semmai Canberra a essere nell'interno.", "Perché Canberra è la città più antica": "È il contrario: fu fondata nel primo Novecento proprio per fare la capitale.", "Perché Sydney era già una capitale estera": "Nessuna città australiana ha mai avuto quel ruolo: la scelta fu interna e politica." } },

  { topic: "capitali", difficulty: 6, difficulty8: true, applica: "geografia-capitali-alta",
    format: "short_answer",
    prompt: "Quale capitale fu progettata e costruita da zero lontano dalla costa, e inaugurata nel 1960?",
    answer: "Brasilia", accept: ["brasilia", "brasília"],
    explanation: "Tutte le grandi città brasiliane stavano sull'Atlantico e l'immenso interno restava vuoto: la capitale fu usata come strumento per spostare il baricentro del Paese." },

  { topic: "capitali", difficulty: 7, difficulty8: true, applica: "geografia-capitali-alta",
    prompt: "Oslo sorge in fondo a un fiordo. Che cosa spiega questa scelta?",
    answer: "Che la Norvegia è tutta costa", distractors: ["Che il fiordo è il punto più caldo", "Che l'interno era già occupato", "Che i fiordi sono al centro del Paese"],
    explanation: "In un Paese di coste e montagne, con l'interno poco praticabile, il mare è la via principale e una città di governo deve stare su un porto riparato.",
    distractorWhy: { "Che il fiordo è il punto più caldo": "Il clima aiuta, ma non è la ragione: la scelta è dettata dall'accesso al mare.", "Che l'interno era già occupato": "L'interno norvegese è montuoso e scarsamente abitato: non c'era nessuna concorrenza per lo spazio.", "Che i fiordi sono al centro del Paese": "I fiordi sono insenature costiere per definizione: stanno sul bordo, non al centro." } },
];
