// Elettronica — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Sesta materia convertita alla regola delle dispense
// (`docs/REGOLA_DISPENSE.md`). Otto argomenti, sedici dispense.
//
// ## Il rischio didattico di questa materia, e come le dispense lo affrontano
//
// L'elettricità non si vede. Tutto quello che se ne impara passa da
// un'analogia, e un'analogia sbagliata resta addosso per anni: chi ha imparato
// che «la pila contiene corrente e la manda nel filo» sbaglierà ogni previsione
// sui circuiti in parallelo, e non saprà perché.
//
// Le sedici dispense usano **una sola immagine** — il dislivello e lo
// scorrimento — e la tengono per tutti e otto gli argomenti invece di cambiarla
// a ogni capitolo. Da lì discende la frase che ritorna ovunque e che le domande
// applicano: **la tensione spinge, la resistenza frena, la corrente scorre**.
//
// ## La forma delle domande
//
// Le prove chiedono quasi sempre di **prevedere** invece che di definire, ed è
// la forma in cui una analogia sbagliata si rivela subito:
//
//   il documento dice   in parallelo la tensione è comune, la corrente si divide
//   la domanda chiede   che cosa succede alle altre lampadine quando una si fulmina
//
// Le poche domande di nome — Ampere, Volt, Ohm, rame — sono coperte dal
// controllo 4b: elettronica entra fra le `MATERIE_DI_RICHIAMO`, quindi il nome
// chiesto deve comparire nel documento.

export const ELETTRONICA_APPLICAZIONI = [

  // =================================================== ELETTRICITA BASE
  { topic: "elettricita-base", difficulty: 2, difficulty8: true, applica: "elettronica-elettricita-base-base",
    prompt: "Due vasche d'acqua allo stesso livello sono collegate da un tubo. L'acqua scorre?",
    answer: "No, manca il dislivello", distractors: ["Sì, se il tubo è largo", "Sì, ma molto lentamente", "Dipende da quanta acqua c'è"],
    explanation: "È la stessa cosa della tensione elettrica: non basta che le cariche ci siano, serve una differenza fra due punti che le metta in moto.",
    distractorWhy: { "Sì, se il tubo è largo": "La larghezza del tubo è l'equivalente della resistenza: cambia quanto scorre, non se scorre.", "Sì, ma molto lentamente": "Senza dislivello non scorre affatto, nemmeno piano: manca proprio la causa del movimento.", "Dipende da quanta acqua c'è": "Due vasche enormi allo stesso livello restano ferme come due bicchieri: conta la differenza, non la quantità." } },

  { topic: "elettricita-base", difficulty: 3, difficulty8: true, applica: "elettronica-elettricita-base-base",
    format: "short_answer",
    prompt: "Come si chiama l'ostacolo che un materiale oppone al passaggio della corrente?",
    answer: "resistenza", accept: ["la resistenza", "resistenza elettrica"],
    explanation: "È il terzo dei tre mestieri: la tensione spinge, questa frena, e quello che ne risulta è la corrente che scorre." },

  { topic: "elettricita-base", difficulty: 4, difficulty8: true, applica: "elettronica-elettricita-base-base",
    prompt: "Prima di accendere un circuito, dentro il filo di rame ci sono già delle cariche elettriche?",
    answer: "Sì, ma si agitano a caso", distractors: ["No, arrivano dalla pila", "No, le crea l'interruttore", "Sì, ma sono ferme del tutto"],
    explanation: "Le cariche stanno già nel metallo. Accendere non le manda dentro: le fa smettere di muoversi a caso e le fa spostare mediamente nello stesso verso.",
    distractorWhy: { "No, arrivano dalla pila": "La pila crea una differenza di potenziale, non spedisce cariche: quelle che si muovono erano già nel circuito.", "No, le crea l'interruttore": "L'interruttore decide solo se il percorso continua: non produce né fornisce niente.", "Sì, ma sono ferme del tutto": "Si agitano sempre in tutte le direzioni: quello che manca prima di accendere è l'ordine, non il movimento." } },

  { topic: "elettricita-base", difficulty: 5, difficulty8: true, applica: "elettronica-elettricita-base-alta",
    prompt: "Che cosa finisce davvero quando una pila si scarica?",
    answer: "L'energia chimica al suo interno", distractors: ["L'elettricità che aveva dentro", "Le cariche del circuito", "La tensione dei fili"],
    explanation: "Dentro la pila una reazione chimica mantiene la differenza fra i poli: quando i reagenti si esauriscono la differenza non si mantiene più.",
    distractorWhy: { "L'elettricità che aveva dentro": "La pila non contiene elettricità da spedire: crea un dislivello che muove le cariche già presenti nel circuito.", "Le cariche del circuito": "Le cariche restano tutte dove sono: si spostano, non si consumano.", "La tensione dei fili": "La tensione non sta nei fili ed è una conseguenza, non una riserva: sparisce perché sparisce la causa che la produceva." } },

  { topic: "elettricita-base", difficulty: 6, difficulty8: true, applica: "elettronica-elettricita-base-alta",
    prompt: "Perché la corrente della rete elettrica è alternata e non continua?",
    answer: "Perché la sua tensione si trasforma facilmente", distractors: ["Perché scorre più veloce nei cavi", "Perché è meno pericolosa da toccare", "Perché le centrali non sanno farla continua"],
    explanation: "Trasportare a tensione alta fa perdere molta meno energia lungo chilometri di cavo, e alzare e riabbassare la tensione con un trasformatore si può fare solo con l'alternata.",
    distractorWhy: { "Perché scorre più veloce nei cavi": "La velocità con cui il segnale si propaga è praticamente la stessa: non è questo a distinguerle.", "Perché è meno pericolosa da toccare": "Non lo è affatto, e a parità di tensione in molti casi è il contrario.", "Perché le centrali non sanno farla continua": "Sanno farla benissimo, e alcune linee di trasporto molto lunghe la usano davvero: la scelta è economica." } },

  // ============================================================ CIRCUITO
  { topic: "circuito", difficulty: 2, difficulty8: true, applica: "elettronica-circuito-base",
    prompt: "Una lampadina collegata a una pila carica resta spenta. Quale controllo fai per primo?",
    answer: "Se il percorso si chiude", distractors: ["Se la lampadina è nuova", "Se la pila è della marca giusta", "Se i fili sono abbastanza lunghi"],
    explanation: "L'interruzione del percorso è la causa più frequente e la più veloce da escludere: si segue il filo con il dito dalla sorgente fino a tornare indietro.",
    distractorWhy: { "Se la lampadina è nuova": "Può darsi che sia bruciata, ma sostituirla prima di aver controllato il percorso aggiunge una variabile invece di toglierne una.", "Se la pila è della marca giusta": "La marca non c'entra: quello che conta è che dia tensione, e il problema dice che è carica.", "Se i fili sono abbastanza lunghi": "La lunghezza incide sulla resistenza in modo trascurabile su un circuito così piccolo." } },

  { topic: "circuito", difficulty: 3, difficulty8: true, applica: "elettronica-circuito-base",
    prompt: "Un interruttore chiuso in un circuito senza pila: la corrente scorre?",
    answer: "No, manca la sorgente", distractors: ["Sì, l'interruttore la produce", "Sì, ma pochissima", "Dipende dal tipo di interruttore"],
    explanation: "Servono due condizioni insieme: un percorso chiuso e una sorgente di tensione. L'interruttore fornisce la prima e non può fornire la seconda.",
    distractorWhy: { "Sì, l'interruttore la produce": "L'interruttore non genera corrente: decide soltanto se il percorso continua.", "Sì, ma pochissima": "Non ne scorre affatto: senza dislivello le cariche non hanno nessuna ragione di spostarsi ordinatamente.", "Dipende dal tipo di interruttore": "Nessun interruttore, di nessun tipo, è una sorgente di tensione." } },

  { topic: "circuito", difficulty: 5, difficulty8: true, applica: "elettronica-circuito-alta",
    prompt: "Un filo collega direttamente i due poli di una pila, saltando la lampadina. Che cosa succede?",
    answer: "Passa moltissima corrente e scalda", distractors: ["Non passa niente, è interrotto", "Passa la stessa corrente di prima", "La pila si spegne da sola"],
    explanation: "È un cortocircuito: la corrente trova una via quasi senza resistenza, quindi diventa enorme, e tutta quell'energia si trasforma in calore nel filo e nella pila.",
    distractorWhy: { "Non passa niente, è interrotto": "È il guasto opposto: qui il percorso non è interrotto, è anzi accorciato e reso facilissimo.", "Passa la stessa corrente di prima": "La lampadina era la resistenza del circuito: saltandola l'ostacolo quasi sparisce e la corrente cresce moltissimo.", "La pila si spegne da sola": "Non ha nessun modo di spegnersi: continua a spingere finché non si scarica o non si rovina." } },

  { topic: "circuito", difficulty: 6, difficulty8: true, applica: "elettronica-circuito-alta",
    format: "short_answer",
    prompt: "Come si chiama il punto di un circuito in cui si incontrano tre o più fili?",
    answer: "nodo", accept: ["un nodo", "il nodo"],
    explanation: "È dove la lettura lineare di uno schema si rompe: lì la corrente si divide fra i rami, e da quel punto in poi ogni ramo ha la propria." },

  // ========================================================== COMPONENTI
  { topic: "componenti", difficulty: 2, difficulty8: true, applica: "elettronica-componenti-base",
    prompt: "A che cosa serve la resistenza messa in serie a un LED?",
    answer: "A non farlo bruciare", distractors: ["A farlo brillare di più", "A farlo accendere prima", "A cambiargli colore"],
    explanation: "Limita la corrente che lo attraversa. Il LED brilla meno del massimo teorico, e quello è il prezzo voluto perché duri anni invece di un istante.",
    distractorWhy: { "A farlo brillare di più": "Fa l'opposto, ed è proprio il fraintendimento più comune: toglie luce per togliere corrente.", "A farlo accendere prima": "L'accensione è immediata in entrambi i casi: la resistenza non introduce nessun ritardo percepibile.", "A cambiargli colore": "Il colore dipende dal materiale del LED e non dalla corrente che lo attraversa." } },

  { topic: "componenti", difficulty: 4, difficulty8: true, applica: "elettronica-componenti-base",
    format: "short_answer",
    prompt: "Quale componente fornisce la spinta elettrica fra un polo più e un polo meno?",
    answer: "batteria", accept: ["la batteria", "pila", "la pila"],
    explanation: "È la sorgente del circuito. Attenzione a non scambiarla per una resistenza: non limita la corrente, la alimenta." },

  { topic: "componenti", difficulty: 6, difficulty8: true, applica: "elettronica-componenti-alta",
    prompt: "Stai per montare un pezzo. Come capisci se ha un verso obbligato?",
    answer: "Se ha una tacca o una gamba più lunga", distractors: ["Se è di forma allungata", "Se è più grande degli altri", "Se ha due terminali invece di tre"],
    explanation: "I componenti polarizzati portano sempre un segno che li distingue: una tacca, una fascia, un terminale più lungo. Resistenze e interruttori non ne hanno, e infatti si montano come capita.",
    distractorWhy: { "Se è di forma allungata": "Le resistenze sono allungate e non hanno nessun verso: la forma non dice niente sulla polarità.", "Se è più grande degli altri": "La dimensione dipende dalla potenza che il componente deve reggere, non dal suo verso.", "Se ha due terminali invece di tre": "Sia il LED sia la resistenza ne hanno due, e solo il primo dei due è polarizzato." } },

  { topic: "componenti", difficulty: 6, difficulty8: true, applica: "elettronica-componenti-alta",
    prompt: "Un LED è montato al contrario in un circuito per il resto sano. Che cosa succede?",
    answer: "Resta spento e non si rompe", distractors: ["Si brucia dopo poco", "Brilla ma più debolmente", "Fa scaldare la pila"],
    explanation: "Un LED è un diodo: in quel verso non lascia passare corrente. Non passando corrente non si scalda niente, e basta girarlo.",
    distractorWhy: { "Si brucia dopo poco": "Per bruciarsi dovrebbe passare corrente, e in quel verso non ne passa affatto.", "Brilla ma più debolmente": "Non conduce per niente: non c'è nessuna via intermedia fra acceso e spento.", "Fa scaldare la pila": "Il circuito è di fatto aperto in quel punto: la pila non eroga corrente e non si scalda." } },

  // ========================================================== CONDUTTORI
  { topic: "conduttori", difficulty: 2, difficulty8: true, applica: "elettronica-conduttori-base",
    format: "short_answer",
    prompt: "Quale metallo si usa quasi sempre nei fili elettrici perché conduce meglio degli altri comuni?",
    answer: "rame", accept: ["il rame"],
    explanation: "Come tutti i metalli ha elettroni liberi di spostarsi, e più della maggior parte degli altri: è questo a fare la conduzione, non la durezza o il peso." },

  { topic: "conduttori", difficulty: 4, difficulty8: true, applica: "elettronica-conduttori-base",
    prompt: "Perché la guaina di plastica attorno a un filo elettrico non è una parte inutile?",
    answer: "Tiene la corrente dentro il percorso", distractors: ["Rende il filo più resistente agli urti", "Aiuta il rame a condurre", "Serve a distinguere i colori"],
    explanation: "Metà del lavoro di un impianto è far scorrere la corrente dove serve, e l'altra metà è impedirle di andare altrove: quella metà la fanno gli isolanti.",
    distractorWhy: { "Rende il filo più resistente agli urti": "Un po' lo protegge dagli urti, ma non è la ragione per cui c'è: la ragione è elettrica.", "Aiuta il rame a condurre": "Non partecipa in nessun modo alla conduzione: al contrario, è scelta proprio perché non conduce.", "Serve a distinguere i colori": "I colori aiutano a montare, ma su un filo singolo la guaina servirebbe ugualmente." } },

  { topic: "conduttori", difficulty: 5, difficulty8: true, applica: "elettronica-conduttori-alta",
    prompt: "Un cavo lungo fa arrivare troppo poca tensione all'apparecchio. Qual è la soluzione più diretta?",
    answer: "Usare un cavo più grosso", distractors: ["Accorciare l'apparecchio", "Usare un cavo più lungo", "Cambiare il colore della guaina"],
    explanation: "La resistenza di un filo cresce con la lunghezza e cala con la sezione: se non si può accorciare il percorso, si aumenta la sezione.",
    distractorWhy: { "Accorciare l'apparecchio": "L'apparecchio non c'entra: la tensione si perde lungo il cavo, prima di arrivargli.", "Usare un cavo più lungo": "Peggiorerebbe: ogni tratto in più è resistenza che si somma.", "Cambiare il colore della guaina": "Il colore è una convenzione di montaggio e non ha nessun effetto elettrico." } },

  { topic: "conduttori", difficulty: 6, difficulty8: true, applica: "elettronica-conduttori-alta",
    prompt: "«L'acqua pura non conduce.» Perché questa frase non autorizza nessuna imprudenza?",
    answer: "Perché l'acqua reale ha sempre sali", distractors: ["Perché la frase è falsa", "Perché l'acqua pura è rara e cara", "Perché conduce solo se calda"],
    explanation: "A condurre sono i sali disciolti, che si separano in particelle cariche. L'acqua del rubinetto, di mare, di pioggia e il sudore ne contengono sempre.",
    distractorWhy: { "Perché la frase è falsa": "È vera: l'acqua chimicamente pura conduce pochissimo. Il problema è che fuori da un laboratorio non esiste.", "Perché l'acqua pura è rara e cara": "La rarità non c'entra con il pericolo: quello che conta è che l'acqua che si incontra conduce.", "Perché conduce solo se calda": "La temperatura influisce poco: a fare la differenza sono le sostanze disciolte." } },

  // =================================================== MISURE ELETTRICHE
  { topic: "misure-elettriche", difficulty: 3, difficulty8: true, applica: "elettronica-misure-elettriche-base",
    format: "short_answer",
    prompt: "In quale unità di misura si esprime la tensione elettrica?",
    answer: "Volt", accept: ["volt", "in volt", "v"],
    explanation: "Dal cognome di Alessandro Volta. Le tre unità corrispondono una a una alle tre grandezze: Ampere per quello che scorre, Volt per quello che spinge, Ohm per quello che frena." },

  { topic: "misure-elettriche", difficulty: 4, difficulty8: true, applica: "elettronica-misure-elettriche-base",
    prompt: "Su un'etichetta leggi «230 V». Che cosa ti sta dicendo?",
    answer: "Quanta spinta serve per alimentarlo", distractors: ["Quanta corrente assorbe", "Quanta resistenza ha dentro", "Quanta energia consuma in un'ora"],
    explanation: "I Volt misurano la tensione, cioè la differenza di potenziale che deve esserci ai suoi capi. Gli Ampere direbbero invece quanta corrente assorbe.",
    distractorWhy: { "Quanta corrente assorbe": "Quella si esprime in Ampere: è un'informazione diversa, e sull'etichetta di solito c'è anche quella.", "Quanta resistenza ha dentro": "Si misurerebbe in Ohm, e quasi mai viene dichiarata su un apparecchio.", "Quanta energia consuma in un'ora": "È il consumo, e si esprime in wattora: un'altra grandezza ancora." } },

  { topic: "misure-elettriche", difficulty: 6, difficulty8: true, applica: "elettronica-misure-elettriche-alta",
    prompt: "Perché un amperometro va inserito in serie e non appoggiato come un voltmetro?",
    answer: "Perché la corrente deve attraversarlo", distractors: ["Perché è più fragile del voltmetro", "Perché misura numeri più grandi", "Perché va sempre vicino alla pila"],
    explanation: "La corrente è quanto scorre attraverso un punto: per misurarla bisogna aprire il circuito e farla passare dentro lo strumento. La tensione invece è una differenza fra due punti, e si tocca da fuori.",
    distractorWhy: { "Perché è più fragile del voltmetro": "La fragilità non deciderebbe il modo di collegarlo, e comunque l'errore opposto è proprio quello che lo rompe.", "Perché misura numeri più grandi": "I valori non c'entrano: conta la natura della grandezza, cioè se sia un flusso o una differenza.", "Perché va sempre vicino alla pila": "Si può inserire in qualunque punto del ramo di cui si vuole la corrente." } },

  { topic: "misure-elettriche", difficulty: 7, difficulty8: true, applica: "elettronica-misure-elettriche-alta",
    format: "numeric_input",
    prompt: "Con 24 volt applicati a una resistenza di 6 ohm, quanti ampere passano?",
    answer: "4",
    explanation: "La corrente è la tensione divisa per la resistenza. Controllo del verso: raddoppiando la resistenza la corrente si dimezzerebbe, quindi il conto è girato bene." },

  // ===================================================== SERIE PARALLELO
  { topic: "serie-parallelo", difficulty: 3, difficulty8: true, applica: "elettronica-serie-parallelo-base",
    prompt: "Due lampadine sono in serie e una si fulmina. Che cosa succede all'altra?",
    answer: "Si spegne anche lei", distractors: ["Resta accesa uguale", "Brilla il doppio", "Brilla un poco di meno"],
    explanation: "In serie il percorso è uno solo: interrompendolo in un punto si apre tutto, e nessuna corrente può più passare da nessuna parte.",
    distractorWhy: { "Resta accesa uguale": "È quello che succederebbe in parallelo, dove ogni lampadina ha un ramo suo.", "Brilla il doppio": "Non le arriva più niente: il percorso è interrotto, quindi non c'è nessuna corrente da ridistribuire.", "Brilla un poco di meno": "Non esiste una via di mezzo: o il percorso è chiuso o non lo è." } },

  { topic: "serie-parallelo", difficulty: 4, difficulty8: true, applica: "elettronica-serie-parallelo-base",
    prompt: "Dove va messo un fusibile perché protegga davvero il circuito?",
    answer: "In serie, sul percorso principale", distractors: ["In parallelo alla sorgente di tensione", "In parallelo al carico", "In un ramo separato"],
    explanation: "Un componente di protezione funziona solo se tutta la corrente è obbligata ad attraversarlo: in parallelo la corrente troverebbe la via che lo aggira.",
    distractorWhy: { "In parallelo alla sorgente di tensione": "Sarebbe un cortocircuito permanente: il fusibile salterebbe subito senza proteggere niente.", "In parallelo al carico": "La corrente continuerebbe a passare nel carico attraverso il suo ramo, e il fusibile non la vedrebbe.", "In un ramo separato": "Misurerebbe la corrente di quel ramo soltanto, e non quella che si vuole limitare." } },

  { topic: "serie-parallelo", difficulty: 6, difficulty8: true, applica: "elettronica-serie-parallelo-alta",
    prompt: "In un circuito in serie, che cosa è uguale in tutti i componenti?",
    answer: "La corrente", distractors: ["La tensione", "La resistenza", "La potenza"],
    explanation: "C'è un percorso solo: quello che entra da un capo esce dall'altro senza potersi dividere. A dividersi è la tensione. In parallelo le due cose si scambiano.",
    distractorWhy: { "La tensione": "È quella che si divide fra i componenti in serie: è comune invece in parallelo.", "La resistenza": "Dipende da ciascun componente e non c'è ragione che sia uguale: due resistenze in serie possono essere diversissime.", "La potenza": "Dipende dalla tensione ai capi di ciascuno, che è diversa: quindi anche la potenza lo è." } },

  { topic: "serie-parallelo", difficulty: 8, difficulty8: true, applica: "elettronica-serie-parallelo-alta",
    prompt: "Aggiungi una seconda resistenza uguale in parallelo alla prima. La resistenza totale…",
    answer: "La metà di una sola", distractors: ["Il doppio di una sola", "Uguale a una sola", "Poco più di una sola"],
    explanation: "Aggiungere un ramo apre una strada in più: complessivamente la corrente passa più facilmente, quindi la resistenza vista dalla sorgente diminuisce.",
    distractorWhy: { "Il doppio di una sola": "È quello che succede mettendole in serie, dove gli ostacoli si sommano lungo lo stesso percorso.", "Uguale a una sola": "Cambia eccome: la sorgente si trova davanti due vie invece di una.", "Poco più di una sola": "Va nella direzione sbagliata: aggiungere un percorso non può rendere più difficile il passaggio." } },

  // =================================================== SICUREZZA ELETTRICA
  { topic: "sicurezza-elettrica", difficulty: 2, difficulty8: true, applica: "elettronica-sicurezza-elettrica-base",
    prompt: "Perché con le mani bagnate la stessa presa diventa molto più pericolosa?",
    answer: "Perché la resistenza del corpo crolla", distractors: ["Perché la tensione della presa sale", "Perché l'acqua attira la corrente", "Perché la pelle si assottiglia"],
    explanation: "La tensione non cambia: cambia quanto il corpo si oppone. Con meno resistenza sullo stesso dislivello passa molta più corrente, ed è la corrente a fare danno.",
    distractorWhy: { "Perché la tensione della presa sale": "La presa fornisce sempre la stessa tensione, bagnate o asciutte che siano le mani.", "Perché l'acqua attira la corrente": "La corrente non viene attirata: prende le vie che le si offrono, e l'acqua ne offre una facile.", "Perché la pelle si assottiglia": "La pelle non cambia spessore: cambia quanto conduce, perché l'acqua e i sali riempiono le sue irregolarità." } },

  { topic: "sicurezza-elettrica", difficulty: 3, difficulty8: true, applica: "elettronica-sicurezza-elettrica-base",
    format: "short_answer",
    prompt: "Come si chiama il collegamento che dà alla corrente una via sicura verso il suolo?",
    answer: "messa a terra", accept: ["la messa a terra", "terra"],
    explanation: "È un percorso a bassissima resistenza: se un guasto mette in tensione l'involucro di un apparecchio, la corrente prende quella via invece del corpo di chi tocca." },

  { topic: "sicurezza-elettrica", difficulty: 5, difficulty8: true, applica: "elettronica-sicurezza-elettrica-alta",
    prompt: "Un uccello posato su un filo dell'alta tensione non si fulmina. Perché?",
    answer: "Tocca un solo filo e la corrente non ha dove andare", distractors: ["Perché è troppo leggero per condurre corrente", "Perché le piume lo isolano dal contatto col filo", "Perché il filo dell'alta tensione è isolato"],
    explanation: "Le due zampe stanno sullo stesso filo, quindi allo stesso potenziale: senza una differenza fra due punti nessuna corrente attraversa il corpo.",
    distractorWhy: { "Perché è troppo leggero per condurre corrente": "Il peso non ha nessun ruolo: conduce in base alla resistenza del suo corpo, che è come quella di qualunque animale.", "Perché le piume lo isolano dal contatto col filo": "Le zampe toccano il filo nudo: se esistesse un percorso, le piume non basterebbero.", "Perché il filo dell'alta tensione è isolato": "I cavi dell'alta tensione sono quasi sempre nudi: a isolarli è l'aria che li circonda." } },

  { topic: "sicurezza-elettrica", difficulty: 5, difficulty8: true, applica: "elettronica-sicurezza-elettrica-alta",
    prompt: "Una scintilla di elettricità statica può avere migliaia di volt e non fa male. Perché?",
    answer: "Perché dura un istante e porta poca carica", distractors: ["Perché i volt non fanno mai male", "Perché la pelle asciutta blocca la scintilla", "Perché l'aria assorbe quasi tutto"],
    explanation: "A fare danno è la corrente che attraversa il corpo, e qui la carica disponibile è minima e finisce subito: la tensione alta da sola non basta.",
    distractorWhy: { "Perché i volt non fanno mai male": "La tensione conta eccome, perché insieme alla resistenza determina la corrente: semplicemente non basta da sola.", "Perché la pelle asciutta blocca la scintilla": "La scintilla la attraversa, tanto che si sente: quello che manca è la quantità e la durata.", "Perché l'aria assorbe quasi tutto": "L'aria viene attraversata dalla scarica, altrimenti non ci sarebbe nessuna scintilla visibile." } },

  // ============================================================== GUASTI
  { topic: "guasti", difficulty: 2, difficulty8: true, applica: "elettronica-guasti-base",
    prompt: "Un LED ha brillato fortissimo per un istante e poi non si è più acceso. Quale guasto sospetti?",
    answer: "Resistenza assente", distractors: ["Filo mancante", "Interruttore aperto", "LED girato al contrario"],
    explanation: "Senza resistenza il LED riceve tutta la corrente che la sorgente può dare: il lampo iniziale è proprio il momento in cui si è bruciato.",
    distractorWhy: { "Filo mancante": "Con il percorso interrotto non si sarebbe acceso nemmeno il primo istante.", "Interruttore aperto": "Stessa obiezione: il circuito sarebbe stato aperto fin dall'inizio, e non ci sarebbe stato nessun lampo.", "LED girato al contrario": "Girato al rovescio non conduce affatto: resterebbe spento dall'inizio, senza brillare." } },

  { topic: "guasti", difficulty: 4, difficulty8: true, applica: "elettronica-guasti-base",
    prompt: "Prima di aprire un circuito guasto, qual è la mossa che fa risparmiare più tempo?",
    answer: "Scrivere che cosa ha fatto esattamente", distractors: ["Sostituire il pezzo più sospetto", "Rifare da capo tutto quanto il montaggio", "Provare una pila nuova"],
    explanation: "Il sintomo restringe la ricerca a uno o due guasti su quattro: niente del tutto significa percorso aperto, un lampo significa resistenza assente, tutto a posto significa verso sbagliato.",
    distractorWhy: { "Sostituire il pezzo più sospetto": "Se non cambia niente ci si ritrova con due incognite: il guasto originale e se il pezzo nuovo sia montato bene.", "Rifare da capo tutto quanto il montaggio": "Si perde l'informazione che il guasto conteneva, e nulla garantisce di non rifare lo stesso errore.", "Provare una pila nuova": "È una delle verifiche possibili, ma farla per prima non è giustificata da nessun sintomo." } },

  { topic: "guasti", difficulty: 6, difficulty8: true, applica: "elettronica-guasti-alta",
    prompt: "Su un circuito di trenta componenti, perché conviene misurare a metà invece di controllare in ordine?",
    answer: "Perché ogni prova dimezza la zona", distractors: ["Perché il guasto sta spesso al centro", "Perché gli strumenti misurano meglio lì", "Perché i componenti centrali si rompono di più"],
    explanation: "Controllando in ordine servono in media quindici prove; dimezzando la zona ne bastano cinque per isolare un pezzo su trenta. È lo stesso ragionamento della ricerca a metà.",
    distractorWhy: { "Perché il guasto sta spesso al centro": "Non c'è nessuna ragione per cui stia al centro: il vantaggio viene dal dimezzamento, non dalla posizione del guasto.", "Perché gli strumenti misurano meglio lì": "Uno strumento misura uguale in qualunque punto accessibile del circuito.", "Perché i componenti centrali si rompono di più": "La posizione nello schema non ha nessun effetto sulla probabilità che un pezzo si guasti." } },

  { topic: "guasti", difficulty: 7, difficulty8: true, applica: "elettronica-guasti-alta",
    prompt: "Hai cambiato due componenti insieme e adesso il circuito funziona. Che cosa hai imparato?",
    answer: "Niente su quale fosse il guasto", distractors: ["Che erano guasti entrambi", "Che il primo era quello giusto", "Che il circuito era montato male"],
    explanation: "Con due modifiche insieme non si sa quale abbia risolto: si è buttato un pezzo probabilmente buono, e la prossima volta si rifarà lo stesso errore.",
    distractorWhy: { "Che erano guasti entrambi": "È una delle possibilità, ma non è stata dimostrata: poteva bastarne uno.", "Che il primo era quello giusto": "Non c'è nessun dato che privilegi il primo rispetto al secondo.", "Che il circuito era montato male": "Il montaggio poteva essere corretto e un solo componente difettoso: l'esperimento non distingue." } },
];
