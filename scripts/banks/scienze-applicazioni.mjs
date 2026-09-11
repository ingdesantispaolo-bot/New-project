// Scienze — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Quinta materia convertita alla regola delle dispense
// (`docs/REGOLA_DISPENSE.md`). Otto argomenti, sedici dispense, due bande
// ciascuno.
//
// ## Che cosa cambia rispetto alle tre materie di richiamo
//
// In storia, geografia e latino la domanda impossibile è quella che chiede un
// fatto o una forma che nessuno ha mai detto. In scienze quasi tutte le risposte
// sono spiegazioni, non nomi, quindi il controllo 4b morde su poche domande.
// Scienze entra comunque fra le `MATERIE_DI_RICHIAMO`, e la ragione è che le
// poche domande di nome che restano — «qual è l'unità di base dei viventi?» —
// sono esattamente quelle in cui il documento deve aver pronunciato la parola.
//
// ## La forma delle domande
//
// Quasi tutte chiedono di **applicare un criterio a un caso nuovo**, e la
// tentazione da evitare qui è particolare: in scienze è facilissimo scrivere
// domande che chiedono di ripetere una definizione. Una definizione ripetuta non
// dice se sia stata capita. Applicarla a un caso che il documento non ha
// nominato, sì:
//
//   il documento dice   una fonte è rinnovabile se si rigenera più in fretta di
//                       quanto la consumiamo
//   la domanda chiede   perché il petrolio non lo sia
//
// ## Regole di scrittura
//
// Quelle degli altri lotti, più la regola di banda: un item di fascia 1-4 non
// può usare un termine che le dispense introducono nella banda alta. Un esempio
// vero incontrato scrivendo: la parola «fusione» compare nella banda alta di
// `materia`, quindi la domanda che la chiede sta alla fascia 5, non alla 4.

export const SCIENZE_APPLICAZIONI = [

  // ============================================================= VIVENTI
  { topic: "viventi", difficulty: 2, difficulty8: true, applica: "scienze-viventi-base",
    prompt: "Un cristallo di sale in una soluzione diventa sempre più grande. Perché non lo consideriamo vivo?",
    answer: "Perché cresce per accumulo esterno", distractors: ["Perché non si muove e non respira", "Perché è troppo duro", "Perché non ha un colore"],
    explanation: "Un vivente cresce dall'interno costruendosi da sé con il materiale che ha assorbito; il cristallo aggiunge strati dall'esterno, e nessuno degli altri segni della vita è presente.",
    distractorWhy: { "Perché non si muove e non respira": "Anche le piante non si spostano, e sono vive: il movimento non è uno dei segni che definiscono la vita.", "Perché è troppo duro": "Esistono viventi con parti durissime, come le conchiglie e le ossa: la durezza non c'entra.", "Perché non ha un colore": "Molti viventi sono incolori, a cominciare da moltissimi organismi microscopici." } },

  { topic: "viventi", difficulty: 4, difficulty8: true, applica: "scienze-viventi-base",
    format: "short_answer",
    prompt: "Qual è la parte più piccola capace di fare, da sola, tutto ciò che fa un essere vivente?",
    answer: "cellula", accept: ["la cellula", "una cellula"],
    explanation: "Alcuni organismi ne hanno una sola e altri miliardi, ma nessun vivente ne è privo. E ognuna nasce dalla divisione di un'altra." },

  { topic: "viventi", difficulty: 3, difficulty8: true, applica: "scienze-viventi-base",
    prompt: "Quale parte della pianta fabbrica il nutrimento usando la luce?",
    answer: "Le foglie", distractors: ["Le radici", "Il fusto", "I fiori"],
    explanation: "È la fotosintesi, e avviene nelle foglie: da acqua, anidride carbonica e luce la pianta costruisce da sé il proprio cibo.",
    distractorWhy: { "Le radici": "Assorbono acqua e sali dal terreno e tengono ferma la pianta, ma non ricevono luce.", "Il fusto": "Trasporta verso l'alto quello che le radici hanno assorbito: è la via, non l'officina.", "I fiori": "Servono alla riproduzione: non è da lì che arriva il nutrimento della pianta." } },

  { topic: "viventi", difficulty: 5, difficulty8: true, applica: "scienze-viventi-alta",
    prompt: "Il cactus ha le foglie ridotte a spine. Come si chiama una caratteristica del genere?",
    answer: "Un adattamento", distractors: ["Una difesa dal vento forte", "Un segno di crescita lenta", "Un richiamo per gli insetti"],
    explanation: "Meno superficie significa meno acqua persa per evaporazione: la caratteristica aiuta a vivere dove l'acqua è scarsa, ed è questo che definisce un adattamento.",
    distractorWhy: { "Una difesa dal vento forte": "Le spine non riparano dal vento, e nei deserti il problema principale per una pianta è l'acqua.", "Un segno di crescita lenta": "La crescita lenta è una conseguenza dell'ambiente arido, non il significato delle spine.", "Un richiamo per gli insetti": "Ad attirare gli insetti servono i fiori: le spine ottengono l'effetto opposto." } },

  { topic: "viventi", difficulty: 6, difficulty8: true, applica: "scienze-viventi-alta",
    prompt: "Ti dicono che un animale mai visto è un mammifero. Che cosa puoi affermare con certezza?",
    answer: "Che allatta i suoi piccoli", distractors: ["Che vive sulla terraferma", "Che ha quattro zampe", "Che è più grande di un insetto"],
    explanation: "È a questo che serve una classificazione: dal gruppo si ricavano proprietà di un individuo mai osservato. L'allattamento è proprio il carattere che definisce la classe.",
    distractorWhy: { "Che vive sulla terraferma": "Balene e delfini sono mammiferi e vivono in mare per tutta la vita.", "Che ha quattro zampe": "I pipistrelli hanno ali e i cetacei pinne: il numero di zampe non definisce il gruppo.", "Che è più grande di un insetto": "Quasi sempre vero, ma non è una proprietà che la classe garantisce: esistono mammiferi di pochi grammi." } },

  { topic: "viventi", difficulty: 7, difficulty8: true, applica: "scienze-viventi-alta",
    format: "short_answer",
    prompt: "Come si chiama un animale privo di colonna vertebrale?",
    answer: "invertebrato", accept: ["un invertebrato", "invertebrati"],
    explanation: "Sono la stragrande maggioranza delle specie animali, insetti in testa: i vertebrati ci vengono in mente per primi perché sono i più grandi e visibili, non i più numerosi." },

  // =============================================================== CORPO
  { topic: "corpo", difficulty: 2, difficulty8: true, applica: "scienze-corpo-base",
    prompt: "Nei polmoni il sangue lascia una sostanza da espellere. Quale?",
    answer: "L'anidride carbonica", distractors: ["L'ossigeno", "L'acqua salata", "Le cellule vecchie"],
    explanation: "Lo scambio avviene nei due versi: l'aria cede ossigeno al sangue, e il sangue lascia ai polmoni l'anidride carbonica prodotta dalle cellule.",
    distractorWhy: { "L'ossigeno": "L'ossigeno viaggia nel verso opposto: dai polmoni al sangue, e poi a tutto il corpo.", "L'acqua salata": "Del liquido in eccesso si occupano i reni, non i polmoni.", "Le cellule vecchie": "Vengono smaltite altrove, soprattutto nella milza e nel fegato: i polmoni scambiano gas." } },

  { topic: "corpo", difficulty: 3, difficulty8: true, applica: "scienze-corpo-base",
    prompt: "Perché masticare a lungo aiuta la digestione?",
    answer: "Aumenta la superficie del cibo", distractors: ["Riscalda il cibo ingerito", "Rende il cibo più dolce", "Accorcia il percorso nell'intestino"],
    explanation: "Più pezzi piccoli significa più superficie su cui i succhi possono lavorare; e insieme la saliva comincia già a trasformare chimicamente gli amidi.",
    distractorWhy: { "Riscalda il cibo ingerito": "La bocca scalda pochissimo, e la temperatura non è quello che rende un cibo digeribile.", "Rende il cibo più dolce": "Alcuni amidi diventano davvero più dolci, ma è un effetto collaterale della trasformazione, non lo scopo.", "Accorcia il percorso nell'intestino": "Il percorso è sempre lo stesso: quello che cambia è quanto lavoro resta da fare lungo la strada." } },

  { topic: "corpo", difficulty: 4, difficulty8: true, applica: "scienze-corpo-base",
    format: "short_answer",
    prompt: "Quale parte interna delle ossa produce le cellule del sangue?",
    answer: "midollo", accept: ["il midollo", "midollo osseo"],
    explanation: "È la prova che lo scheletro non è un'impalcatura morta: oltre a sostenere e a proteggere gli organi, fabbrica di continuo cellule nuove." },

  { topic: "corpo", difficulty: 6, difficulty8: true, applica: "scienze-corpo-alta",
    prompt: "Che cosa segnala al corpo che è ora di accelerare il respiro?",
    answer: "L'anidride carbonica nel sangue", distractors: ["La mancanza d'aria nei polmoni", "Il dolore dei muscoli stanchi", "La temperatura della pelle"],
    explanation: "È un segnale chimico, non una sensazione di vuoto: quando i muscoli lavorano ne producono di più, e il suo aumento fa accelerare respiro e battito.",
    distractorWhy: { "La mancanza d'aria nei polmoni": "I polmoni sono pieni come sempre: non è una questione di spazio ma di composizione del sangue.", "Il dolore dei muscoli stanchi": "Arriva molto dopo, e il respiro accelera già nei primi secondi di corsa.", "La temperatura della pelle": "Governa la sudorazione, non il ritmo del respiro." } },

  { topic: "corpo", difficulty: 6, difficulty8: true, applica: "scienze-corpo-alta",
    prompt: "Che cosa produce calore contraendosi rapidamente quando la temperatura scende?",
    answer: "I muscoli", distractors: ["I polmoni", "Il midollo osseo", "Le ossa"],
    explanation: "È il tremore: contrazioni rapide e ripetute che generano calore. Parte da sola, come la sudorazione nel caso opposto, per tenere costante la temperatura interna.",
    distractorWhy: { "I polmoni": "Scambiano gas e non si contraggono da soli: a muoverli sono i muscoli del torace.", "Il midollo osseo": "Produce cellule del sangue, non calore, e non ha capacità di contrarsi.", "Le ossa": "Sono rigide e non si contraggono: il movimento glielo danno i muscoli tirandole." } },

  { topic: "corpo", difficulty: 7, difficulty8: true, applica: "scienze-corpo-alta",
    prompt: "Il sangue fa tre mestieri insieme. Quali?",
    answer: "Rifornimento, smaltimento e comunicazione", distractors: ["Riscaldamento, filtraggio e digestione", "Movimento, protezione e sostegno", "Respirazione, nutrimento e riposo"],
    explanation: "Porta ossigeno e nutrienti, porta via anidride carbonica e scarti, e distribuisce i messaggeri chimici che dicono agli organi lontani che cosa succede.",
    distractorWhy: { "Riscaldamento, filtraggio e digestione": "Il sangue distribuisce calore ma non filtra né digerisce: quelli sono compiti di reni e apparato digerente.", "Movimento, protezione e sostegno": "Sono i mestieri di muscoli e scheletro, non del sangue.", "Respirazione, nutrimento e riposo": "Respirare è dei polmoni, e il riposo non è una funzione di un tessuto." } },

  // ============================================================= MATERIA
  { topic: "materia", difficulty: 2, difficulty8: true, applica: "scienze-materia-base",
    prompt: "Un campione mantiene sempre lo stesso volume ma prende la forma del recipiente. In quale stato è?",
    answer: "Liquido", distractors: ["Solido", "Gassoso", "Nessuno dei tre"],
    explanation: "Le sue particelle restano a contatto, e questo mantiene il volume; ma sono libere di scorrere l'una sull'altra, e questo fa perdere la forma.",
    distractorWhy: { "Solido": "Un solido mantiene anche la forma, perché le sue particelle hanno una posizione fissa.", "Gassoso": "Un gas non mantiene nessuna delle due: si espande fino a riempire tutto lo spazio disponibile.", "Nessuno dei tre": "La combinazione descritta è esattamente quella del liquido, ed è il criterio che li distingue." } },

  { topic: "materia", difficulty: 3, difficulty8: true, applica: "scienze-materia-base",
    prompt: "Perché un gas riempie sempre tutto il recipiente in cui si trova?",
    answer: "Perché niente tiene unite le particelle", distractors: ["Perché è più leggero dell'aria", "Perché le sue particelle sono grandi", "Perché è sempre più caldo"],
    explanation: "Nelle altre condizioni le particelle restano a contatto; in un gas sono lontanissime e si muovono in tutte le direzioni, quindi occupano qualunque spazio trovino.",
    distractorWhy: { "Perché è più leggero dell'aria": "Molti gas sono più pesanti dell'aria e si comportano esattamente allo stesso modo.", "Perché le sue particelle sono grandi": "Sono le stesse particelle della sostanza allo stato liquido o solido: cambia la distanza, non la dimensione.", "Perché è sempre più caldo": "Un gas può essere freddissimo e continua a riempire il recipiente." } },

  { topic: "materia", difficulty: 4, difficulty8: true, applica: "scienze-materia-base",
    prompt: "Che cosa significa scaldare una sostanza, guardando le sue particelle?",
    answer: "Aumentare la loro agitazione", distractors: ["Aumentare il loro numero", "Renderle più pesanti", "Cambiarne il colore"],
    explanation: "È solo movimento: finché l'aumento è piccolo si nota come temperatura più alta, e quando è abbastanza grande le particelle vincono ciò che le tratteneva e lo stato cambia.",
    distractorWhy: { "Aumentare il loro numero": "Le particelle restano le stesse: scaldando non se ne aggiunge nessuna.", "Renderle più pesanti": "La massa non cambia con la temperatura: cambia quanto si muovono.", "Cambiarne il colore": "Alcuni materiali cambiano colore scaldandosi, ma è un effetto, non che cosa sia il calore." } },

  { topic: "materia", difficulty: 5, difficulty8: true, applica: "scienze-materia-alta",
    format: "short_answer",
    prompt: "Un blocco di ghiaccio scaldato diventa acqua. Come si chiama questo passaggio di stato?",
    answer: "fusione", accept: ["la fusione"],
    explanation: "Il suo opposto è la solidificazione. Impararli a coppie conviene: nel verso che va verso il disordine si fornisce calore, in quello opposto lo si toglie." },

  { topic: "materia", difficulty: 6, difficulty8: true, applica: "scienze-materia-alta",
    prompt: "Perché il ghiaccio galleggia sull'acqua, al contrario di quasi tutti i solidi?",
    answer: "Perché occupa più spazio dell'acqua", distractors: ["Perché è molto più freddo", "Perché contiene bolle d'aria", "Perché la sua superficie è liscia"],
    explanation: "Congelando, le molecole d'acqua si dispongono in una struttura che le tiene più distanziate: la stessa quantità di sostanza occupa più volume, e quindi pesa meno a parità di spazio.",
    distractorWhy: { "Perché è molto più freddo": "Un oggetto freddo non galleggia per questo: l'acqua liquida vicina a zero gradi affonda nel ghiaccio, non viceversa.", "Perché contiene bolle d'aria": "Anche il ghiaccio perfettamente trasparente e senza bolle galleggia.", "Perché la sua superficie è liscia": "Il galleggiamento dipende dalla densità, non da come è fatta la superficie." } },

  { topic: "materia", difficulty: 7, difficulty8: true, applica: "scienze-materia-alta",
    prompt: "Hai sabbia mescolata ad acqua. Quale metodo di separazione usi?",
    answer: "Filtrare", distractors: ["Far evaporare l'acqua", "Scaldare fino a bollire", "Lasciar passare la luce"],
    explanation: "La differenza che conta è che una è un solido in pezzi e l'altra un liquido: un filtro lascia passare l'uno e trattiene l'altra, ed è il metodo più diretto.",
    distractorWhy: { "Far evaporare l'acqua": "Funzionerebbe ma butta via l'acqua, e serve calore: si usa quando la sostanza disciolta non si può filtrare, come il sale.", "Scaldare fino a bollire": "Stessa obiezione, con più spreco: la sabbia si sarebbe potuta togliere senza consumare niente.", "Lasciar passare la luce": "Non separa nulla: serve a osservare il miscuglio, non a dividerlo." } },

  // ====================================================== TERRA UNIVERSO
  { topic: "terra-universo", difficulty: 2, difficulty8: true, applica: "scienze-terra-universo-base",
    format: "numeric_input",
    prompt: "Quante ore impiega la Terra a compiere un giro completo su se stessa?",
    answer: "24",
    explanation: "È questo movimento a causare l'alternarsi del giorno e della notte: il Sole illumina sempre metà del pianeta, e ruotando ogni punto passa a turno dalle due parti." },

  { topic: "terra-universo", difficulty: 4, difficulty8: true, applica: "scienze-terra-universo-base",
    prompt: "Perché le stagioni dei due emisferi sono invertite?",
    answer: "Perché l'asse terrestre è inclinato", distractors: ["Perché la distanza dal Sole cambia", "Perché la Terra gira più veloce d'estate", "Perché la Luna influenza gli emisferi"],
    explanation: "Se dipendessero dalla distanza dal Sole le stagioni sarebbero uguali dappertutto. L'asse inclinato fa sì che un emisfero per volta riceva raggi più diretti.",
    distractorWhy: { "Perché la distanza dal Sole cambia": "Cambia pochissimo, e comunque sarebbe la stessa per tutto il pianeta: non produrrebbe stagioni opposte.", "Perché la Terra gira più veloce d'estate": "La velocità di rotazione è praticamente costante, e comunque sarebbe uguale per i due emisferi.", "Perché la Luna influenza gli emisferi": "La Luna governa le maree, non il ciclo delle stagioni." } },

  { topic: "terra-universo", difficulty: 4, difficulty8: true, applica: "scienze-terra-universo-base",
    format: "short_answer",
    prompt: "Come si chiama il movimento della Terra su se stessa?",
    answer: "rotazione", accept: ["la rotazione", "rotazione terrestre"],
    explanation: "Da non confondere con la rivoluzione, che è il giro attorno al Sole e dura un anno: la prima produce il giorno, la seconda insieme all'asse inclinato produce le stagioni." },

  { topic: "terra-universo", difficulty: 5, difficulty8: true, applica: "scienze-terra-universo-alta",
    prompt: "Come si chiama la galassia che contiene il nostro Sole?",
    answer: "Via Lattea", distractors: ["Sistema solare", "Costellazione", "Nebulosa"],
    explanation: "Contiene centinaia di miliardi di stelle tenute insieme dalla gravità, e il Sole è una di quelle. Di galassie come questa ce ne sono innumerevoli.",
    distractorWhy: { "Sistema solare": "È il livello più piccolo: il Sole con i pianeti che gli girano attorno, dentro la galassia.", "Costellazione": "È solo un disegno che facciamo noi unendo stelle che ci appaiono vicine: non è un oggetto reale.", "Nebulosa": "È una nube di gas e polveri, che sta dentro una galassia e non la contiene." } },

  { topic: "terra-universo", difficulty: 6, difficulty8: true, applica: "scienze-terra-universo-alta",
    prompt: "Osservi una stella che dista mille anni luce. Che cosa stai vedendo?",
    answer: "Com'era mille anni fa", distractors: ["Com'è in questo momento", "Come sarà fra mille anni", "Un riflesso della sua luce"],
    explanation: "La sua luce ha impiegato mille anni a raggiungerci: guardare lontano nello spazio significa sempre guardare indietro nel tempo, e quella stella potrebbe non esistere più.",
    distractorWhy: { "Com'è in questo momento": "Nessuna informazione viaggia più veloce della luce: del suo presente non possiamo sapere niente.", "Come sarà fra mille anni": "Il futuro non manda segnali: l'informazione che riceviamo è sempre partita in passato.", "Un riflesso della sua luce": "Le stelle emettono luce propria: non è un riflesso, è la loro luce che ha impiegato mille anni ad arrivare." } },

  { topic: "terra-universo", difficulty: 7, difficulty8: true, applica: "scienze-terra-universo-alta",
    prompt: "Un astronauta in orbita vede le stelle anche con il Sole illuminato. Che cosa dimostra?",
    answer: "Che a nasconderle è l'atmosfera", distractors: ["Che nello spazio brillano di più", "Che il Sole lassù è più debole", "Che gli occhi si abituano al buio"],
    explanation: "Le stelle ci sono anche di giorno: è la luce solare diffusa dall'aria a coprirle. Dove l'aria non c'è, quella diffusione non avviene e le stelle restano visibili.",
    distractorWhy: { "Che nello spazio brillano di più": "Emettono esattamente la stessa luce: quello che cambia è lo sfondo su cui la vediamo.", "Che il Sole lassù è più debole": "È anzi più intenso, perché nessuna atmosfera ne assorbe una parte.", "Che gli occhi si abituano al buio": "L'abitudine al buio aiuta di notte, ma non spiegherebbe perché in orbita si vedano anche con il Sole in vista." } },

  // ========================================================== ECOSISTEMA
  { topic: "ecosistema", difficulty: 3, difficulty8: true, applica: "scienze-ecosistema-base",
    prompt: "Da dove entra l'energia in un ecosistema?",
    answer: "Dal Sole, attraverso le piante", distractors: ["Dal suolo, attraverso le radici", "Dall'acqua dei fiumi e delle piogge", "Dai decompositori che riciclano"],
    explanation: "Le piante sono i produttori: con la fotosintesi trasformano la luce in nutrimento, e tutti gli altri vivono direttamente o indirettamente di quello che loro hanno costruito.",
    distractorWhy: { "Dal suolo, attraverso le radici": "Dal suolo arrivano acqua e sali minerali, che sono materiali: l'energia arriva dalla luce.", "Dall'acqua dei fiumi e delle piogge": "L'acqua è indispensabile come materiale, ma non porta l'energia che alimenta la catena.", "Dai decompositori che riciclano": "Rimettono in circolo le sostanze, non l'energia: quella, a ogni passaggio, si perde come calore." } },

  { topic: "ecosistema", difficulty: 5, difficulty8: true, applica: "scienze-ecosistema-base",
    format: "short_answer",
    prompt: "Come si chiamano i funghi e i batteri che trasformano i resti in sostanze riutilizzabili?",
    answer: "decompositori", accept: ["i decompositori", "decompositore"],
    explanation: "Chiudono il cerchio dell'ecosistema: senza di loro il materiale si accumulerebbe e le piante resterebbero senza le sostanze che prendono dal suolo." },

  { topic: "ecosistema", difficulty: 5, difficulty8: true, applica: "scienze-ecosistema-base",
    prompt: "Perché una rete alimentare regge meglio di una catena la scomparsa di una specie?",
    answer: "Perché ci sono alternative", distractors: ["Perché ha più produttori", "Perché è più corta", "Perché ha meno predatori"],
    explanation: "In una catena ogni anello dipende da uno solo; in una rete chi mangiava la specie scomparsa può ripiegare su un'altra, e il colpo non si propaga a tutti.",
    distractorWhy: { "Perché ha più produttori": "Il numero di produttori non cambia passando da una catena alla rete che la contiene: cambiano i collegamenti.", "Perché è più corta": "Una rete non è più corta: è fatta di più catene collegate, quindi semmai più estesa.", "Perché ha meno predatori": "Ne ha di più, non di meno: il vantaggio sta nel fatto che ciascuno ha più prede possibili." } },

  { topic: "ecosistema", difficulty: 6, difficulty8: true, applica: "scienze-ecosistema-alta",
    prompt: "Perché le catene alimentari sono quasi sempre di tre o quattro anelli e non di dieci?",
    answer: "Perché l'energia si esaurisce", distractors: ["Perché mancano i predatori grandi", "Perché gli animali si spostano troppo", "Perché le piante non bastano"],
    explanation: "A ogni passaggio arriva circa un decimo di quello che c'era nel livello precedente: dopo quattro salti resta un decimillesimo, che non mantiene più nessuna popolazione.",
    distractorWhy: { "Perché mancano i predatori grandi": "I predatori mancano perché non ci sarebbe energia per mantenerli: è la conseguenza, non la causa.", "Perché gli animali si spostano troppo": "Gli spostamenti allargano l'area di una catena, non ne riducono il numero di anelli.", "Perché le piante non bastano": "Le piante sono la base larghissima della piramide: il problema è quanto si perde salendo, non quanto c'è alla base." } },

  { topic: "ecosistema", difficulty: 6, difficulty8: true, applica: "scienze-ecosistema-alta",
    format: "short_answer",
    prompt: "Come si chiama una convivenza stretta fra due specie diverse?",
    answer: "simbiosi", accept: ["la simbiosi", "una simbiosi"],
    explanation: "Ne esistono tre forme: entrambe ci guadagnano, una guadagna e l'altra non ci perde, oppure una guadagna a spese dell'altra. Per distinguerle basta chiedersi che cosa ci guadagna ciascuna." },

  { topic: "ecosistema", difficulty: 8, difficulty8: true, applica: "scienze-ecosistema-alta",
    prompt: "L'ape prende il nettare dal fiore e nel farlo lo impollina. Che tipo di rapporto è?",
    answer: "Mutualismo", distractors: ["Parassitismo", "Predazione", "Competizione"],
    explanation: "Entrambe le specie ci guadagnano: l'ape si nutre, il fiore si riproduce. È la forma di simbiosi in cui nessuna delle due ci rimette.",
    distractorWhy: { "Parassitismo": "Nel parassitismo una guadagna a spese dell'altra: qui il fiore non subisce nessun danno, anzi.", "Predazione": "Il predatore uccide la preda: l'ape non danneggia il fiore in nessun modo.", "Competizione": "La competizione è fra chi cerca la stessa risorsa: qui le due specie si scambiano servizi diversi." } },

  // ============================================================ AMBIENTE
  { topic: "ambiente", difficulty: 3, difficulty8: true, applica: "scienze-ambiente-base",
    prompt: "Perché il petrolio non è considerato una fonte rinnovabile?",
    answer: "Perché si rifà in milioni di anni", distractors: ["Perché si trova sotto terra", "Perché inquina quando brucia", "Perché costa molto da estrarre"],
    explanation: "La differenza non è che una fonte finisca e l'altra no: è il confronto fra la velocità con cui si rigenera e quella con cui la consumiamo.",
    distractorWhy: { "Perché si trova sotto terra": "Anche il calore geotermico viene da sotto terra ed è rinnovabile: la posizione non c'entra.", "Perché inquina quando brucia": "L'inquinamento è un altro problema, importante ma separato: una fonte può essere pulita e non rinnovabile.", "Perché costa molto da estrarre": "Il costo varia nel tempo e non definisce niente: alcune rinnovabili costano più del petrolio." } },

  { topic: "ambiente", difficulty: 4, difficulty8: true, applica: "scienze-ambiente-base",
    format: "short_answer",
    prompt: "Come si chiama la varietà di specie viventi presenti in un ambiente?",
    answer: "biodiversità", accept: ["la biodiversità", "biodiversita"],
    explanation: "Si può misurare, e da essa dipende quanto quell'ambiente regge i cambiamenti: più specie ci sono, più la rete alimentare ha alternative." },

  { topic: "ambiente", difficulty: 4, difficulty8: true, applica: "scienze-ambiente-base",
    prompt: "Perché un ambiente con molte specie assorbe meglio la scomparsa di una di esse?",
    answer: "Perché la rete offre alternative", distractors: ["Perché ci sono più piante", "Perché il clima è più stabile", "Perché ci sono meno predatori"],
    explanation: "È il ragionamento della rete alimentare: chi si nutriva della specie scomparsa può ripiegare su un'altra, e il colpo non si propaga a tutto l'ambiente.",
    distractorWhy: { "Perché ci sono più piante": "Non è detto: la biodiversità riguarda il numero di specie, non la quantità di vegetazione.", "Perché il clima è più stabile": "Il clima non dipende dal numero di specie presenti: è una condizione esterna.", "Perché ci sono meno predatori": "Un ambiente ricco ne ha di più, non di meno, ed è comunque un vantaggio perché moltiplica i collegamenti." } },

  { topic: "ambiente", difficulty: 6, difficulty8: true, applica: "scienze-ambiente-alta",
    prompt: "In un ambiente sparisce il predatore al vertice. Che cosa succede per primo agli erbivori?",
    answer: "La loro popolazione aumenta", distractors: ["Diminuiscono subito di numero", "Restano esattamente uguali", "Cambiano specie di piante"],
    explanation: "Tolto chi li teneva sotto controllo, la loro popolazione aumenta: poi consumano troppa vegetazione, e il danno arriva fino al suolo e ai corsi d'acqua.",
    distractorWhy: { "Diminuiscono subito di numero": "Sarebbe il contrario: il predatore era ciò che ne limitava il numero.", "Restano esattamente uguali": "È proprio l'idea che la nozione di specie chiave smentisce: togliere un anello cambia gli altri.", "Cambiano specie di piante": "Possono estendersi a piante nuove, ma è un effetto successivo: il primo è l'aumento del numero." } },

  { topic: "ambiente", difficulty: 7, difficulty8: true, applica: "scienze-ambiente-alta",
    prompt: "Come si chiamano i frammenti minuscoli in cui la plastica si spezza senza degradarsi?",
    answer: "Microplastiche", distractors: ["Polveri sottili", "Sedimenti", "Fibre naturali"],
    explanation: "Non spariscono: vengono ingerite dagli organismi e risalgono la catena alimentare fino ai grandi predatori, e da lì ai nostri piatti.",
    distractorWhy: { "Polveri sottili": "Sono particelle sospese nell'aria, prodotte soprattutto da combustioni: un altro problema.", "Sedimenti": "Sono i materiali naturali depositati dall'acqua sul fondo, e fanno parte del funzionamento normale.", "Fibre naturali": "Si degradano in tempi brevi proprio perché naturali: è il contrario del problema descritto." } },

  { topic: "ambiente", difficulty: 8, difficulty8: true, applica: "scienze-ambiente-alta",
    prompt: "Perché l'effetto serra non è di per sé un problema da eliminare?",
    answer: "Perché senza saremmo sotto zero", distractors: ["Perché è poco intenso", "Perché riguarda solo i poli", "Perché si annulla di notte"],
    explanation: "È un fenomeno naturale e necessario: senza i gas che trattengono il calore, la temperatura media del pianeta sarebbe sotto zero. Ciò che è cambiato è la loro quantità.",
    distractorWhy: { "Perché è poco intenso": "È intensissimo, ed è proprio questo a rendere abitabile il pianeta: senza, sarebbe ghiacciato.", "Perché riguarda solo i poli": "Riguarda tutta l'atmosfera: ai poli si vedono prima gli effetti del suo aumento, ma il fenomeno è globale.", "Perché si annulla di notte": "Di notte agisce ancora di più, trattenendo il calore che la superficie irradia verso lo spazio." } },

  // ============================================================= ENERGIA
  { topic: "energia", difficulty: 3, difficulty8: true, applica: "scienze-energia-base",
    prompt: "Un sasso è fermo in cima a una scala. Ha energia?",
    answer: "Sì, potenziale per la posizione", distractors: ["No, perché è fermo", "Sì, cinetica perché è in alto", "No, perché non si scalda"],
    explanation: "L'energia potenziale è energia in attesa: basta lasciarlo andare perché la posizione si trasformi in movimento, cioè in energia cinetica.",
    distractorWhy: { "No, perché è fermo": "L'essere fermo esclude l'energia cinetica, non tutte: quella potenziale dipende dalla posizione, non dal moto.", "Sì, cinetica perché è in alto": "Cinetica significa «di movimento»: un corpo fermo non ne ha, per quanto in alto si trovi.", "No, perché non si scalda": "Il calore è un'altra forma di energia ancora: la sua assenza non esclude le altre." } },

  { topic: "energia", difficulty: 4, difficulty8: true, applica: "scienze-energia-base",
    prompt: "Il cibo che mangiamo contiene energia di quale forma?",
    answer: "Chimica", distractors: ["Cinetica", "Potenziale", "Luminosa"],
    explanation: "È immagazzinata nei legami delle sostanze, come nella benzina e in una pila: il corpo la libera e la trasforma in movimento e calore.",
    distractorWhy: { "Cinetica": "Sarebbe energia di movimento, e il cibo nel piatto è fermo.", "Potenziale": "Dipenderebbe dalla posizione: sollevare il piatto cambierebbe l'energia del pasto, il che non ha senso.", "Luminosa": "È l'energia portata dalla luce: quella del Sole serve alle piante per costruire il cibo, ma nel cibo è diventata chimica." } },

  { topic: "energia", difficulty: 5, difficulty8: true, applica: "scienze-energia-base",
    format: "short_answer",
    prompt: "Come si chiama l'energia che un corpo ha perché si muove?",
    answer: "cinetica", accept: ["energia cinetica", "l'energia cinetica"],
    explanation: "Dipende da quanto è veloce e da quanto è pesante. Le sta di fronte quella potenziale, che dipende dalla posizione ed è energia in attesa." },

  { topic: "energia", difficulty: 7, difficulty8: true, applica: "scienze-energia-alta",
    prompt: "Una macchina rallenta e si ferma. Dove è finita la sua energia?",
    answer: "È diventata calore disperso", distractors: ["È stata distrutta dall'attrito", "È tornata indietro alla fonte", "Si è trasformata in massa"],
    explanation: "L'energia non si distrugge: l'attrito e la resistenza dell'aria l'hanno trasformata in calore, che si è sparso nell'ambiente e non è più utilizzabile.",
    distractorWhy: { "È stata distrutta dall'attrito": "L'attrito non distrugge energia: la trasforma in calore, che è la forma meno riutilizzabile.", "È tornata indietro alla fonte": "Nessun meccanismo la riporta indietro: si disperde nell'ambiente attorno.", "Si è trasformata in massa": "È un fenomeno reale ma in condizioni estreme: in una macchina che si ferma l'energia diventa semplicemente calore." } },

  { topic: "energia", difficulty: 7, difficulty8: true, applica: "scienze-energia-alta",
    prompt: "Come si chiama il fatto che a ogni trasformazione una parte di energia diventa calore inutilizzabile?",
    answer: "Degradazione", distractors: ["Conservazione", "Dispersione totale", "Annullamento"],
    explanation: "La quantità si conserva ma l'utilizzabilità no: il calore sparso nell'ambiente non offre più nessuna differenza da sfruttare per far funzionare qualcosa.",
    distractorWhy: { "Conservazione": "Riguarda la quantità totale, che infatti non cambia: la degradazione riguarda quanto di quella quantità resta usabile.", "Dispersione totale": "Non si disperde tutto a ogni passaggio: solo una parte, e la macchina intanto fa il suo lavoro.", "Annullamento": "Niente si annulla: è proprio il principio di conservazione a escluderlo." } },

  { topic: "energia", difficulty: 8, difficulty8: true, applica: "scienze-energia-alta",
    prompt: "Perché anche l'energia del vento si può considerare energia solare?",
    answer: "Perché il Sole crea le differenze di temperatura", distractors: ["Perché il vento soffia solo di giorno", "Perché l'aria viene scaldata dai raggi in quota", "Perché segue il ritmo delle stagioni"],
    explanation: "Il Sole scalda in modo disuguale le diverse zone del pianeta; quelle differenze producono differenze di pressione, e il vento è aria che si sposta fra loro.",
    distractorWhy: { "Perché il vento soffia solo di giorno": "Soffia anche di notte, e la sua origine resta il riscaldamento disuguale accumulato.", "Perché l'aria viene scaldata dai raggi in quota": "L'aria in quota è la più fredda: il riscaldamento avviene soprattutto dal basso, dalla superficie.", "Perché segue il ritmo delle stagioni": "I venti cambiano con le stagioni, ma questo è un effetto: la causa è la differenza di temperatura." } },

  // ============================================================== METODO
  { topic: "metodo", difficulty: 1, difficulty8: true, applica: "scienze-metodo-base",
    prompt: "«La pianta sul davanzale è alta 30 centimetri.» Che cos'è questa frase?",
    answer: "Un'osservazione", distractors: ["Un'interpretazione", "Un'ipotesi", "Un esperimento"],
    explanation: "Registra quello che si vede e si può controllare misurando. Diventerebbe interpretazione aggiungendo un «perché»: quello sarebbe una proposta da verificare.",
    distractorWhy: { "Un'interpretazione": "Un'interpretazione spiega: qui non c'è nessun perché, solo un dato registrato.", "Un'ipotesi": "Un'ipotesi è una risposta possibile a una domanda: questa frase non risponde a niente, constata.", "Un esperimento": "Un esperimento è una situazione costruita apposta: qui si è solo guardato e misurato." } },

  { topic: "metodo", difficulty: 2, difficulty8: true, applica: "scienze-metodo-base",
    format: "short_answer",
    prompt: "Come si chiama una risposta possibile a una domanda, ancora da verificare?",
    answer: "ipotesi", accept: ["un'ipotesi", "una ipotesi", "l'ipotesi"],
    explanation: "Per essere utile deve dire anche che cosa si osserverebbe se fosse falsa: senza quello nessun esperimento potrebbe metterla alla prova." },

  { topic: "metodo", difficulty: 3, difficulty8: true, applica: "scienze-metodo-base",
    prompt: "Oltre a dire che cosa ci si aspetta se è vera, un'ipotesi utile deve dire anche…",
    answer: "Che cosa la smentirebbe", distractors: ["Chi l'ha proposta per primo", "Quanto tempo servirà a provarla", "Quante volte va ripetuta"],
    explanation: "Se nessun risultato possibile potrebbe contraddirla, allora nessun esperimento la sta mettendo alla prova, e confermarla non significa niente.",
    distractorWhy: { "Chi l'ha proposta per primo": "È un'informazione storica: non cambia se l'ipotesi si possa provare o no.", "Quanto tempo servirà a provarla": "È una questione pratica di organizzazione, non una condizione perché l'ipotesi sia utile.", "Quante volte va ripetuta": "La ripetizione riguarda l'esperimento, e si decide dopo aver stabilito che l'ipotesi è verificabile." } },

  { topic: "metodo", difficulty: 5, difficulty8: true, applica: "scienze-metodo-alta",
    prompt: "Cambi insieme la luce e l'acqua, e la pianta cresce di più. Che cosa puoi concludere?",
    answer: "Niente su quale delle due", distractors: ["Che è stata la luce", "Che è stata l'acqua", "Che servono tutte e due"],
    explanation: "Con due variabili cambiate insieme l'effetto può venire dall'una, dall'altra o dalla combinazione: l'esperimento su questa domanda non decide.",
    distractorWhy: { "Che è stata la luce": "È una delle tre possibilità, e l'esperimento non permette di sceglierla fra le altre due.", "Che è stata l'acqua": "Stessa obiezione simmetrica: nessun dato distingue il suo effetto da quello della luce.", "Che servono tutte e due": "Anche questa è una delle tre possibilità, e nemmeno lei è stata dimostrata." } },

  { topic: "metodo", difficulty: 5, difficulty8: true, applica: "scienze-metodo-alta",
    format: "short_answer",
    prompt: "Come si chiama il gruppo identico in tutto agli altri, tranne che non riceve l'intervento?",
    answer: "gruppo di controllo", accept: ["il gruppo di controllo", "controllo"],
    explanation: "Serve a confrontare con ciò che sarebbe successo comunque: senza di esso si misura l'intervento sommato a tutto il resto, e non si riescono a separare." },

  { topic: "metodo", difficulty: 7, difficulty8: true, applica: "scienze-metodo-alta",
    prompt: "Un'ipotesi che nessun risultato possibile potrebbe smentire è…",
    answer: "Inutile dal punto di vista scientifico", distractors: ["Certamente vera e dimostrata", "Certamente falsa e da scartare", "Particolarmente solida e ben verificata"],
    explanation: "Non falsa: inutile. Se qualunque risultato la conferma, nessun esperimento la sta mettendo alla prova, e il fatto che regga non dice niente.",
    distractorWhy: { "Certamente vera e dimostrata": "È l'errore esatto che si vuole evitare: resistere a tutto non è una prova, è il segno che non si sta provando nulla.", "Certamente falsa e da scartare": "Non c'è nessuna ragione di crederla falsa: semplicemente non si può decidere.", "Particolarmente solida e ben verificata": "La solidità viene dall'aver superato prove che avrebbero potuto smentirla: qui quelle prove non esistono." } },
];
