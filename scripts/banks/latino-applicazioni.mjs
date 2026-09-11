// Latino — le applicazioni delle dispense. 11 settembre 2026.
//
// ## Perché questo file esiste
//
// Quarta materia convertita alla regola delle dispense
// (`docs/REGOLA_DISPENSE.md`). Il latino ha un difetto suo, misurato il 2
// settembre: non la domanda di NOME come storia e geografia, ma la domanda di
// **FORMA**. «Da *rosa*, quale forma useresti per dire *della rosa*?» non si
// deduce da niente — o si è vista la tabella, o si tira a indovinare.
//
// ## Le ventidue dispense, e perché non trenta
//
// I sette argomenti di declinazione hanno **una dispensa sola che copre tutte e
// otto le fasce**: le caselle di un paradigma sono una tabella, e una tabella non
// si divide in «prime quattro fasce» e «ultime quattro» senza che i due documenti
// si ripetano mezzi a vicenda. Gli argomenti concettuali — i casi, i verbi, le
// frasi, l'etimologia, il vocabolario — si dividono invece in due bande, perché
// lì un prima e un dopo esistono davvero.
//
// ## Il controllo che qui morde più che altrove
//
// Il latino entra fra le `MATERIE_DI_RICHIAMO` di `dispense_audit`: una risposta
// che è un nome — e in latino quasi ogni forma lo è — deve comparire nel testo
// della dispensa, **oppure** essere descritta da una delle sue `regole`.
//
// Le `regole` fanno qui il lavoro pesante, e per una ragione aritmetica: le forme
// costruibili sono centinaia, elencarle tutte nel testo sarebbe assurdo, e una
// riga di espressione regolare copre un intero gruppo di radici. È la stessa
// scelta che `TAVOLE_LATINO` aveva già fatto il 2 settembre, e le espressioni sono
// scritte sulle stesse radici.
//
// ## Regole di scrittura
//
// Quelle degli altri lotti, più una che è di questa materia:
//
//   **Una domanda di forma si scrive solo se la dispensa insegna a costruirla.**
//   Non basta che la forma esista: deve essere ricavabile dal tema e dalla
//   desinenza che il documento dichiara. Se non lo è, la domanda non misura la
//   competenza: misura se quella parola era già stata incontrata per caso.

export const LATINO_APPLICAZIONI = [

  // ================================================================ BASI
  { topic: "basi", difficulty: 1, difficulty8: true, applica: "latino-basi-base",
    prompt: "In una frase latina, che cosa dice quale mestiere sta facendo una parola?",
    answer: "La desinenza", distractors: ["La posizione", "La lunghezza", "L'articolo davanti"],
    explanation: "È la differenza di fondo con l'italiano: la funzione sta scritta nella coda della parola, quindi l'ordine può cambiare senza che il senso cambi.",
    distractorWhy: { "La posizione": "È così in italiano, non in latino: qui l'ordine serve a dare enfasi, non ad assegnare i ruoli.", "La lunghezza": "La lunghezza non porta nessuna informazione grammaticale in nessuna lingua.", "L'articolo davanti": "Il latino non ha articoli: è una delle prime cose che colpiscono chi lo incontra." } },

  { topic: "basi", difficulty: 2, difficulty8: true, applica: "latino-basi-base",
    format: "numeric_input",
    prompt: "Quanti sono i casi latini, contando anche il vocativo?",
    answer: "6",
    explanation: "Nominativo, genitivo, dativo, accusativo, vocativo e ablativo: ognuno corrisponde a un mestiere diverso dentro la frase." },

  { topic: "basi", difficulty: 2, difficulty8: true, applica: "latino-basi-base",
    prompt: "In italiano «il cane morde l'uomo» e «l'uomo morde il cane» dicono cose opposte. Che cosa le distingue?",
    answer: "L'ordine delle parole", distractors: ["La desinenza dei nomi", "Il tempo del verbo", "Il genere dei nomi"],
    explanation: "In italiano è la posizione ad assegnare i ruoli. In latino no: lì le stesse due frasi si distinguerebbero cambiando le code, non l'ordine.",
    distractorWhy: { "La desinenza dei nomi": "In italiano le desinenze dei nomi non cambiano fra le due frasi: «cane» e «uomo» restano identici.", "Il tempo del verbo": "Il verbo è lo stesso presente in entrambe: non è lui a cambiare.", "Il genere dei nomi": "Il genere non cambia e non ha nessun ruolo nell'assegnare chi morde." } },

  { topic: "basi", difficulty: 3, difficulty8: true, applica: "latino-basi-base",
    format: "short_answer",
    prompt: "Come si chiama una lingua in cui le parole cambiano desinenza invece di affidarsi all'ordine?",
    answer: "flessiva", accept: ["lingua flessiva", "una lingua flessiva"],
    explanation: "Il latino lo è in modo pieno; l'italiano lo è rimasto solo nei verbi, e per i nomi si è spostato sull'ordine e sulle preposizioni." },

  // ================================================================ CASI
  { topic: "casi", difficulty: 1, difficulty8: true, applica: "latino-casi-base",
    prompt: "«Poeta puellam laudat.» vuol dire «Il poeta loda la fanciulla.». Quale parola porta la desinenza dell'accusativo?",
    answer: "puellam", distractors: ["poeta", "laudat", "nessuna"],
    explanation: "La coda -am è l'accusativo singolare della prima declinazione: dice che quella parola subisce l'azione, dovunque si trovi nella frase.",
    distractorWhy: { "poeta": "Finisce in -a: è il nominativo, cioè chi compie l'azione.", "laudat": "È il verbo, e i verbi non hanno casi: hanno persone.", "nessuna": "Il verbo «lodare» ha un oggetto, e quell'oggetto porta per forza la desinenza dell'accusativo." } },

  { topic: "casi", difficulty: 2, difficulty8: true, applica: "latino-casi-base",
    prompt: "A quale domanda risponde il genitivo?",
    answer: "Di chi?", distractors: ["A chi?", "Chi?", "Con che cosa?"],
    explanation: "Il genitivo indica appartenenza e si traduce quasi sempre con «di»: *rosae* è «della rosa», *domini* «del padrone».",
    distractorWhy: { "A chi?": "È la domanda del dativo, che indica il destinatario dell'azione.", "Chi?": "È la domanda del nominativo, cioè del soggetto che compie l'azione.", "Con che cosa?": "È una delle domande dell'ablativo, che indica il mezzo." } },

  { topic: "casi", difficulty: 3, difficulty8: true, applica: "latino-casi-base",
    format: "short_answer",
    prompt: "Come si chiama il caso di chi compie l'azione?",
    answer: "nominativo", accept: ["il nominativo", "caso nominativo"],
    explanation: "È il caso del soggetto. Trovarlo è il secondo passo della lettura di una frase latina, subito dopo aver individuato il verbo." },

  { topic: "casi", difficulty: 5, difficulty8: true, applica: "latino-casi-alta",
    prompt: "In «Rosae pulchrae sunt.», che funzione ha «rosae»?",
    answer: "Nominativo plurale", distractors: ["Genitivo singolare", "Dativo singolare", "Accusativo plurale"],
    explanation: "La forma *rosae* può essere tre cose, ma il verbo *sunt* è plurale e chiede un soggetto plurale: resta solo il nominativo plurale.",
    distractorWhy: { "Genitivo singolare": "Sarebbe possibile come forma, ma non c'è nessun sostantivo di cui la rosa possa essere proprietà.", "Dativo singolare": "Anche questa forma esiste, ma il verbo essere non regge un destinatario: qui serve un soggetto.", "Accusativo plurale": "L'accusativo plurale della prima declinazione è *rosas*, non *rosae*." } },

  { topic: "casi", difficulty: 6, difficulty8: true, applica: "latino-casi-alta",
    prompt: "Quale caso copre insieme «con che cosa», «da dove» e «in che modo»?",
    answer: "L'ablativo", distractors: ["Il dativo", "Il genitivo", "Il vocativo"],
    explanation: "È il più versatile dei sei, e spesso in latino va senza preposizione: la preposizione la aggiunge l'italiano in traduzione.",
    distractorWhy: { "Il dativo": "Risponde solo a «a chi, per chi»: indica il destinatario, non il mezzo né il luogo.", "Il genitivo": "Risponde a «di chi»: indica appartenenza.", "Il vocativo": "Serve soltanto a chiamare qualcuno, e non regge nessun complemento." } },

  { topic: "casi", difficulty: 8, difficulty8: true, applica: "latino-casi-alta",
    prompt: "Davanti a una forma che potrebbe essere tre casi diversi, qual è la prima cosa da guardare?",
    answer: "Il numero del verbo", distractors: ["La posizione nella frase", "La lunghezza della parola", "La prima lettera"],
    explanation: "Se il verbo è plurale il soggetto deve essere plurale: è l'informazione che costa meno da leggere e che elimina più possibilità.",
    distractorWhy: { "La posizione nella frase": "In latino la posizione non assegna i ruoli: una parola in fondo può benissimo essere il soggetto.", "La lunghezza della parola": "La lunghezza non porta nessuna informazione grammaticale.", "La prima lettera": "La prima parte della parola è il tema e dice il significato, non la funzione: quella sta in fondo." } },

  // =================================================== DECLINAZIONI BASE
  { topic: "declinazioni-base", difficulty: 3, difficulty8: true, applica: "latino-declinazioni-base-base",
    prompt: "Un sostantivo latino si cita con due forme. Quale delle due dice a quale declinazione appartiene?",
    answer: "Il genitivo singolare", distractors: ["Il nominativo singolare", "L'accusativo singolare", "Nessuna delle due"],
    explanation: "Nominativi simili appartengono a gruppi diversi — *dominus* e *manus* ne sono la prova — mentre la coda del genitivo appartiene a un gruppo solo.",
    distractorWhy: { "Il nominativo singolare": "È la prima forma citata ma inganna: *manus* e *dominus* finiscono uguale e sono di declinazioni diverse.", "L'accusativo singolare": "Non fa parte della citazione, e comunque si ricava dopo aver stabilito il gruppo.", "Nessuna delle due": "Una delle due lo dice con certezza, ed è proprio per questo che la citazione ne porta due." } },

  { topic: "declinazioni-base", difficulty: 3, difficulty8: true, applica: "latino-declinazioni-base-base",
    prompt: "A quale declinazione appartiene «rex, regis»?",
    answer: "Terza", distractors: ["Prima", "Seconda", "Quarta"],
    explanation: "Il genitivo singolare finisce in -is, e quella coda appartiene alla sola terza declinazione. Dal nominativo *rex* non si sarebbe potuto dedurre niente.",
    distractorWhy: { "Prima": "La prima fa il genitivo in -ae, come *rosae*.", "Seconda": "La seconda fa il genitivo in -i, come *domini*.", "Quarta": "La quarta fa il genitivo in -us, uguale al proprio nominativo." } },

  { topic: "declinazioni-base", difficulty: 4, difficulty8: true, applica: "latino-declinazioni-base-base",
    format: "short_answer",
    prompt: "Da «dominus, domini», qual è il tema su cui si costruiscono tutte le altre forme?",
    answer: "domin", accept: ["domin-", "domini meno la i"],
    explanation: "Si ricava togliendo la desinenza al genitivo singolare: da *domini* si toglie la -i. Da lì in poi basta attaccare la desinenza della casella che serve." },

  { topic: "declinazioni-base", difficulty: 5, difficulty8: true, applica: "latino-declinazioni-base-alta",
    format: "short_answer",
    prompt: "Qual è il genitivo plurale di «rosa»?",
    answer: "rosarum", accept: ["rosarum"],
    explanation: "Tema ros- più la desinenza -arum. È l'unica casella del paradigma con quella coda, quindi non si confonde mai con nessun'altra." },

  { topic: "declinazioni-base", difficulty: 6, difficulty8: true, applica: "latino-declinazioni-base-alta",
    prompt: "Quali due caselle hanno sempre la stessa forma, in tutte e cinque le declinazioni?",
    answer: "Dativo e ablativo plurale", distractors: ["Nominativo e genitivo singolare", "Genitivo e ablativo singolare", "Accusativo e vocativo plurale"],
    explanation: "Vale ovunque: *rosis*, *dominis*, *regibus*, *manibus*, *diebus*. Sapendolo si dimezza il numero di caselle da ricordare al plurale.",
    distractorWhy: { "Nominativo e genitivo singolare": "Coincidono solo nella quarta declinazione, dove *manus* fa entrambi: non è una regola generale.", "Genitivo e ablativo singolare": "Nella prima declinazione sono *rosae* e *rosa*, cioè diversi: non coincidono quasi mai.", "Accusativo e vocativo plurale": "Il vocativo plurale segue il nominativo, non l'accusativo, tranne nei neutri dove coincidono tutti." } },

  { topic: "declinazioni-base", difficulty: 6, difficulty8: true, applica: "latino-declinazioni-base-alta",
    format: "short_answer",
    prompt: "Qual è il dativo plurale di «rosa»?",
    answer: "rosis", accept: ["rosis"],
    explanation: "Tema ros- più la desinenza -is. La stessa forma vale anche come ablativo plurale, perché quelle due caselle coincidono sempre." },

  // ===================================================== DECLINAZIONE 1
  { topic: "declinazione-1", difficulty: 3, difficulty8: true, applica: "latino-declinazione-1",
    format: "short_answer",
    prompt: "Da «terra» (la terra): quale forma useresti per dire «della terra»?",
    answer: "terrae", accept: ["terrae"],
    explanation: "È il genitivo singolare della prima declinazione: tema terr- più la desinenza -ae. La stessa forma vale anche come dativo e come nominativo plurale." },

  { topic: "declinazione-1", difficulty: 4, difficulty8: true, applica: "latino-declinazione-1",
    prompt: "Da «silva» (la selva): quale forma useresti se è la selva a SUBIRE l'azione?",
    answer: "silvam", distractors: ["silvae", "silva", "silvas"],
    explanation: "Chi subisce va all'accusativo, e l'accusativo singolare della prima declinazione è -am: tema silv- più -am.",
    distractorWhy: { "silvae": "È genitivo o dativo singolare, oppure nominativo plurale: nessuna di queste è chi subisce.", "silva": "È il nominativo, cioè chi compie l'azione, oppure l'ablativo singolare.", "silvas": "È l'accusativo PLURALE: subirebbe l'azione, ma sarebbero più selve." } },

  { topic: "declinazione-1", difficulty: 5, difficulty8: true, applica: "latino-declinazione-1",
    format: "short_answer",
    prompt: "Qual è il genitivo plurale di «puella»?",
    answer: "puellarum", accept: ["puellarum"],
    explanation: "Tema puell- più la desinenza -arum del genitivo plurale. Vale per ogni parola di questo gruppo: la procedura non cambia da una all'altra." },

  // ==================================================== DECLINAZIONE 2M
  { topic: "declinazione-2m", difficulty: 4, difficulty8: true, applica: "latino-declinazione-2m",
    prompt: "Da «puer» (il ragazzo): quale forma useresti per dire «del ragazzo»?",
    answer: "pueri", distractors: ["puero", "puerum", "puer"],
    explanation: "È il genitivo singolare: tema puer- più la desinenza -i. Le parole in -er si comportano come tutte le altre della seconda a partire dal genitivo.",
    distractorWhy: { "puero": "È il dativo o l'ablativo singolare: risponde a «a chi» o «con che cosa», non a «di chi».", "puerum": "È l'accusativo singolare, cioè chi subisce l'azione.", "puer": "È il nominativo, la forma di citazione: indica chi compie l'azione." } },

  { topic: "declinazione-2m", difficulty: 5, difficulty8: true, applica: "latino-declinazione-2m",
    format: "short_answer",
    prompt: "Qual è l'accusativo plurale di «dominus»?",
    answer: "dominos", accept: ["dominos"],
    explanation: "Tema domin- più la desinenza -os. Insieme a -um del singolare è una delle poche caselle di questo gruppo che non si confondono con nessun'altra." },

  { topic: "declinazione-2m", difficulty: 7, difficulty8: true, applica: "latino-declinazione-2m",
    prompt: "Per rivolgersi direttamente a qualcuno chiamandolo, da «dominus» si usa…",
    answer: "domine", distractors: ["dominus", "dominum", "domini"],
    explanation: "È il vocativo, e questo è l'unico gruppo di tutto il latino in cui il vocativo differisce dal nominativo. È la forma di «Et tu, Brute?».",
    distractorWhy: { "dominus": "È il nominativo: vale per il soggetto, e coincide col vocativo in tutte le declinazioni tranne questa.", "dominum": "È l'accusativo singolare: indica chi subisce l'azione, non chi viene chiamato.", "domini": "È il genitivo singolare o il nominativo plurale: nessuno dei due serve a chiamare." } },

  // ==================================================== DECLINAZIONE 2N
  { topic: "declinazione-2n", difficulty: 4, difficulty8: true, applica: "latino-declinazione-2n",
    prompt: "Da «bellum» (la guerra): qual è il nominativo plurale?",
    answer: "bella", distractors: ["belli", "bellos", "bellae"],
    explanation: "Nei neutri il nominativo e l'accusativo plurale finiscono sempre in -a, in tutte e cinque le declinazioni: tema bell- più -a.",
    distractorWhy: { "belli": "È il genitivo singolare: sarebbe il nominativo plurale se la parola fosse maschile, ma è neutra.", "bellos": "È la forma dei maschili della seconda all'accusativo plurale: i neutri non la usano mai.", "bellae": "È una desinenza della prima declinazione, e *bellum* appartiene alla seconda." } },

  { topic: "declinazione-2n", difficulty: 6, difficulty8: true, applica: "latino-declinazione-2n",
    prompt: "Nei sostantivi neutri, quali due casi hanno sempre la stessa forma?",
    answer: "Nominativo e accusativo", distractors: ["Genitivo e dativo", "Dativo e ablativo", "Nominativo e genitivo"],
    explanation: "Vale al singolare e al plurale, e in tutte le declinazioni: per questo in una frase con un neutro il ruolo va ricavato dal resto della frase.",
    distractorWhy: { "Genitivo e dativo": "Coincidono nella prima declinazione al singolare, ma non è una regola dei neutri.", "Dativo e ablativo": "Coincidono al plurale in tutte le declinazioni, neutri e non: non è una caratteristica dei neutri.", "Nominativo e genitivo": "Coincidono solo nella quarta declinazione, e per un'altra ragione." } },

  // ==================================================== DECLINAZIONE 3M
  { topic: "declinazione-3m", difficulty: 3, difficulty8: true, applica: "latino-declinazione-3m",
    format: "short_answer",
    prompt: "Da «lex, legis» (la legge): quale forma useresti se è la legge a SUBIRE l'azione?",
    answer: "legem", accept: ["legem"],
    explanation: "Chi subisce va all'accusativo, e l'accusativo singolare della terza è -em: tema leg- ricavato dal genitivo, più -em. Dal nominativo *lex* quel tema non si vedeva." },

  { topic: "declinazione-3m", difficulty: 5, difficulty8: true, applica: "latino-declinazione-3m",
    prompt: "Quale coda al dativo e ablativo plurale è la firma inconfondibile della terza declinazione?",
    answer: "-ibus", distractors: ["-is", "-orum", "-arum"],
    explanation: "Non compare in nessun altro gruppo con quella funzione, quindi vederla significa essere in terza declinazione senza bisogno di altri controlli.",
    distractorWhy: { "-is": "È il dativo e ablativo plurale della prima e della seconda: *rosis*, *dominis*.", "-orum": "È il genitivo plurale della seconda, non un dativo né un ablativo.", "-arum": "È il genitivo plurale della prima declinazione." } },

  { topic: "declinazione-3m", difficulty: 7, difficulty8: true, applica: "latino-declinazione-3m",
    format: "short_answer",
    prompt: "Da «miles, militis» (il soldato): qual è il genitivo singolare?",
    answer: "militis", accept: ["militis"],
    explanation: "È la seconda forma della citazione, e serve proprio perché dal nominativo *miles* nessuno avrebbe potuto ricavare il tema milit-." },

  // ==================================================== DECLINAZIONE 3N
  { topic: "declinazione-3n", difficulty: 7, difficulty8: true, applica: "latino-declinazione-3n",
    prompt: "Da «corpus, corporis» (il corpo): qual è il nominativo plurale?",
    answer: "corpora", distractors: ["corpi", "corpores", "corpus"],
    explanation: "Tema corpor- ricavato dal genitivo, più la -a dei neutri plurali. Dal nominativo *corpus* quel tema non si sarebbe potuto indovinare.",
    distractorWhy: { "corpi": "È l'italiano, non il latino: la desinenza dei neutri plurali latini è -a.", "corpores": "Applica la desinenza -es dei maschili di terza, che i neutri non usano.", "corpus": "È il nominativo singolare, cioè la forma di partenza." } },

  { topic: "declinazione-3n", difficulty: 8, difficulty8: true, applica: "latino-declinazione-3n",
    prompt: "Perché il tema di «tempus» non si può ricavare dal suo nominativo?",
    answer: "Perché il nominativo è trasformato", distractors: ["Perché è una parola presa dal greco", "Perché manca il genitivo", "Perché è un plurale"],
    explanation: "Il tema è tempor-, e fra lui e *tempus* c'è una trasformazione antica per cui non esiste regola: lo si legge solo nel genitivo *temporis*.",
    distractorWhy: { "Perché è una parola presa dal greco": "È latina: il fenomeno riguarda moltissime parole di terza declinazione, tutte latine.", "Perché manca il genitivo": "Il genitivo esiste ed è proprio quello che risolve il problema: *temporis*.", "Perché è un plurale": "*Tempus* è un singolare: il suo plurale è *tempora*." } },

  // ===================================================== DECLINAZIONE 4
  { topic: "declinazione-4", difficulty: 7, difficulty8: true, applica: "latino-declinazione-4",
    prompt: "«manus» e «dominus» finiscono allo stesso modo ma sono di declinazioni diverse. Come si distinguono?",
    answer: "Dal genitivo singolare", distractors: ["Dal genere", "Dalla loro lunghezza", "Dall'accento"],
    explanation: "La quarta fa il genitivo in -us, uguale al nominativo; la seconda in -i. Al nominativo le due parole sono indistinguibili.",
    distractorWhy: { "Dal genere": "Il genere non basta: la quarta contiene sia maschili sia femminili, e il nominativo non lo dice.", "Dalla loro lunghezza": "Sono lunghe in modo diverso ma per caso: la lunghezza non è un criterio grammaticale.", "Dall'accento": "L'accento non è scritto nei testi latini e non distingue le declinazioni." } },

  { topic: "declinazione-4", difficulty: 8, difficulty8: true, applica: "latino-declinazione-4",
    format: "short_answer",
    prompt: "Da «exercitus» (l'esercito): qual è l'accusativo singolare?",
    answer: "exercitum", accept: ["exercitum"],
    explanation: "Tema exercit- più la desinenza -um. È una delle poche caselle della quarta che non si sovrappone a nessun'altra: *exercitus* da solo ne vale cinque." },

  // ===================================================== DECLINAZIONE 5
  { topic: "declinazione-5", difficulty: 7, difficulty8: true, applica: "latino-declinazione-5",
    prompt: "Quale coda al genitivo singolare identifica con certezza la quinta declinazione?",
    answer: "-ei", distractors: ["-is", "-us", "-ae"],
    explanation: "Nessun altro gruppo la usa, quindi quando compare non c'è nessuna ambiguità: *diei*, *rei*, *spei*.",
    distractorWhy: { "-is": "È il genitivo singolare della terza declinazione, come *regis*.", "-us": "È il genitivo singolare della quarta, uguale al suo nominativo.", "-ae": "È il genitivo singolare della prima, come *rosae*." } },

  { topic: "declinazione-5", difficulty: 8, difficulty8: true, applica: "latino-declinazione-5",
    format: "short_answer",
    prompt: "Da quale espressione latina viene la parola italiana «repubblica»?",
    answer: "res publica", accept: ["res publica", "respublica"],
    explanation: "Letteralmente «la cosa pubblica», cioè ciò che appartiene a tutti: *res* è una parola della quinta declinazione, e una delle più frequenti del latino." },

  // =========================================================== VERBO SUM
  { topic: "verbo-sum", difficulty: 2, difficulty8: true, applica: "latino-verbo-sum-base",
    prompt: "Che cosa significa «est»?",
    answer: "Egli è", distractors: ["Io sono", "Tu sei", "Essi sono"],
    explanation: "Terza persona singolare del verbo essere. È la forma più frequente del latino, perché serve anche a collegare il soggetto a ciò che se ne dice.",
    distractorWhy: { "Io sono": "Sarebbe *sum*: la desinenza della prima persona singolare è -m o -o, non -t.", "Tu sei": "Sarebbe *es*: la seconda persona singolare finisce in -s.", "Essi sono": "Sarebbe *sunt*: la terza plurale porta la coda -nt." } },

  { topic: "verbo-sum", difficulty: 3, difficulty8: true, applica: "latino-verbo-sum-base",
    format: "short_answer",
    prompt: "Nel presente del verbo essere, quale forma corrisponde alla prima persona plurale?",
    answer: "sumus", accept: ["sumus"],
    explanation: "La desinenza -mus dà la prima persona plurale in ogni verbo latino: qui è irregolare il tema, non la coda." },

  { topic: "verbo-sum", difficulty: 3, difficulty8: true, applica: "latino-verbo-sum-base",
    prompt: "Perché il verbo essere è irregolare in quasi tutte le lingue?",
    answer: "Perché è usato moltissimo", distractors: ["Perché è molto antico", "Perché è molto corto", "Perché ha pochi tempi"],
    explanation: "Le parole usate di continuo si consumano nella pronuncia, e le irregolarità sopravvivono proprio perché l'uso costante le fissa nella memoria di tutti.",
    distractorWhy: { "Perché è molto antico": "Sono antiche anche moltissime parole perfettamente regolari: l'età da sola non spiega niente.", "Perché è molto corto": "È corto proprio perché è consumato dall'uso: la brevità è un effetto, non la causa.", "Perché ha pochi tempi": "Ha tutti i tempi degli altri verbi: il numero di forme non c'entra con la loro regolarità." } },

  { topic: "verbo-sum", difficulty: 5, difficulty8: true, applica: "latino-verbo-sum-alta",
    prompt: "In «rosa pulchra est», a quale caso sta «pulchra»?",
    answer: "Nominativo", distractors: ["Accusativo", "Genitivo", "Ablativo"],
    explanation: "Non subisce nessuna azione ma descrive il soggetto: con il verbo essere ciò che si dice del soggetto si accorda con lui, e resta al nominativo.",
    distractorWhy: { "Accusativo": "Sarebbe il caso di chi subisce, ma il verbo essere non regge complementi oggetto.", "Genitivo": "Indicherebbe appartenenza, e qui non si sta dicendo di chi è la rosa.", "Ablativo": "Indicherebbe mezzo, luogo o modo: nessuno dei tre è quello che *pulchra* sta facendo." } },

  { topic: "verbo-sum", difficulty: 6, difficulty8: true, applica: "latino-verbo-sum-alta",
    prompt: "Che cosa significa «erat»?",
    answer: "Egli era", distractors: ["Egli è", "Essi erano", "Tu eri"],
    explanation: "È l'imperfetto, riconoscibile dal blocco er- che il presente non ha mai; la desinenza -t dà la terza persona singolare.",
    distractorWhy: { "Egli è": "Sarebbe *est*, al presente: il blocco er- segnala che siamo al passato.", "Essi erano": "Sarebbe *erant*, con la coda -nt della terza plurale.", "Tu eri": "Sarebbe *eras*, con la -s della seconda singolare." } },

  // =============================================================== VERBI
  { topic: "verbi", difficulty: 4, difficulty8: true, applica: "latino-verbi-base",
    prompt: "Nel verbo latino che significa «amare»: in «amant», chi compie l'azione?",
    answer: "Essi", distractors: ["Noi", "Voi", "Tu"],
    explanation: "La coda -nt è la terza persona plurale in ogni verbo latino: si riconosce anche senza sapere che cosa il verbo significhi.",
    distractorWhy: { "Noi": "Sarebbe *amamus*, con la desinenza -mus della prima plurale.", "Voi": "Sarebbe *amatis*, con la desinenza -tis della seconda plurale.", "Tu": "Sarebbe *amas*, con la -s della seconda singolare." } },

  { topic: "verbi", difficulty: 4, difficulty8: true, applica: "latino-verbi-base",
    format: "short_answer",
    prompt: "Quale desinenza indica la prima persona plurale in ogni verbo latino?",
    answer: "-mus", accept: ["mus", "-mus"],
    explanation: "Vale in tutte e quattro le coniugazioni e anche nel verbo essere: *amamus*, *monemus*, *regimus*, *audimus*, *sumus*." },

  { topic: "verbi", difficulty: 4, difficulty8: true, applica: "latino-verbi-base",
    prompt: "Perché in latino il pronome personale quasi non si scrive mai?",
    answer: "Perché lo dice la desinenza", distractors: ["Perché non esisteva", "Perché si scriveva in fondo", "Perché lo dice il caso"],
    explanation: "La coda del verbo indica già chi compie l'azione, quindi il pronome sarebbe una ripetizione: si scrive solo quando si vuole insistere sul soggetto.",
    distractorWhy: { "Perché non esisteva": "Esisteva eccome — *ego*, *tu*, *nos* — e si usava quando serviva enfasi.", "Perché si scriveva in fondo": "Non è una questione di posizione: nella maggior parte delle frasi il pronome proprio non c'è.", "Perché lo dice il caso": "Il caso riguarda i nomi e dice la loro funzione: chi compie l'azione lo dice la persona del verbo." } },

  { topic: "verbi", difficulty: 6, difficulty8: true, applica: "latino-verbi-alta",
    prompt: "Perché «essi governano» si dice «regunt» e non «regint»?",
    answer: "Perché nella terza la vocale diventa -u-", distractors: ["Perché è un verbo irregolare", "Perché la -i- non esiste al plurale", "Perché il tema finisce per consonante"],
    explanation: "Nella terza coniugazione la vocale del tema è instabile: diventa -i- quasi ovunque, sparisce in *rego* e diventa -u- solo davanti alla desinenza -nt.",
    distractorWhy: { "Perché è un verbo irregolare": "*Regere* è un verbo regolarissimo della terza: quel comportamento è la regola del gruppo, non un'eccezione.", "Perché la -i- non esiste al plurale": "Esiste: *regimus* e *regitis* sono plurali e la contengono.", "Perché il tema finisce per consonante": "Finiscono per consonante anche i temi di altre coniugazioni, che però non cambiano vocale." } },

  { topic: "verbi", difficulty: 6, difficulty8: true, applica: "latino-verbi-alta",
    format: "numeric_input",
    prompt: "Quante coniugazioni ha il verbo latino?",
    answer: "4",
    explanation: "Si distinguono dalla vocale dell'infinito: -a- in *amare*, -e- in *monere* e in *regere*, -i- in *audire*." },

  { topic: "verbi", difficulty: 8, difficulty8: true, applica: "latino-verbi-alta",
    prompt: "Che cosa, nell'infinito, rivela a quale coniugazione appartiene un verbo?",
    answer: "La vocale prima di -re", distractors: ["La prima lettera", "La lunghezza del tema", "Il numero di sillabe"],
    explanation: "*Amare* ha la -a-, *monere* la -e-, *audire* la -i-: è lo stesso principio per cui il genitivo rivela la declinazione di un sostantivo.",
    distractorWhy: { "La prima lettera": "Appartiene al tema e dice il significato: verbi di gruppi diversi possono cominciare allo stesso modo.", "La lunghezza del tema": "Non ha nessun rapporto con il gruppo: esistono temi lunghi e corti in tutte e quattro le coniugazioni.", "Il numero di sillabe": "Varia da parola a parola dentro lo stesso gruppo, quindi non distingue niente." } },

  // =============================================================== FRASI
  { topic: "frasi", difficulty: 2, difficulty8: true, applica: "latino-frasi-base",
    prompt: "Qual è la prima cosa da cercare quando si legge una frase latina?",
    answer: "Il verbo", distractors: ["La prima parola", "Il soggetto", "L'aggettivo"],
    explanation: "Il verbo dice quale azione avviene e a quale numero: sapere se è singolare o plurale restringe subito i candidati al ruolo di soggetto.",
    distractorWhy: { "La prima parola": "In latino la posizione non assegna i ruoli: la prima parola può essere un complemento oggetto.", "Il soggetto": "Si cerca subito dopo, e si trova molto più in fretta sapendo già il numero del verbo.", "L'aggettivo": "Si assegna per ultimo, quando lo scheletro della frase è già in piedi." } },

  { topic: "frasi", difficulty: 4, difficulty8: true, applica: "latino-frasi-base",
    prompt: "«Rosam puella amat» rispetto a «Puella rosam amat»…",
    answer: "Significa la stessa cosa", distractors: ["Significa il contrario", "Non è una frase valida", "Cambia il tempo del verbo"],
    explanation: "Le desinenze non sono cambiate, quindi i ruoli non cambiano. In latino l'ordine serve a mettere in evidenza una parola, non ad assegnare le funzioni.",
    distractorWhy: { "Significa il contrario": "Sarebbe vero in italiano, dove i ruoli li dà la posizione: in latino li danno le code.", "Non è una frase valida": "È validissima, e ordini di questo tipo sono comunissimi nei testi latini, soprattutto in poesia.", "Cambia il tempo del verbo": "Il verbo è lo stesso *amat* in entrambe: spostare i sostantivi non lo tocca." } },

  { topic: "frasi", difficulty: 4, difficulty8: true, applica: "latino-frasi-base",
    prompt: "Se l'ordine delle parole non assegna i ruoli, a che cosa serve in latino?",
    answer: "A dare enfasi", distractors: ["Ad assegnare i ruoli", "A indicare il tempo", "A distinguere i generi"],
    explanation: "Mettere una parola in un punto in cui normalmente non starebbe la mette in evidenza: è una risorsa che l'italiano ha quasi perso e che i poeti latini usano continuamente.",
    distractorWhy: { "Ad assegnare i ruoli": "È proprio quello che in latino fanno le desinenze, e che libera l'ordine per altro.", "A indicare il tempo": "Il tempo sta nella forma del verbo, non nella posizione delle parole.", "A distinguere i generi": "Il genere sta nella parola stessa e nella sua declinazione, non in dove si trova." } },

  { topic: "frasi", difficulty: 5, difficulty8: true, applica: "latino-frasi-alta",
    prompt: "In «Dominus servos vocat», come si capisce che il soggetto è «dominus»?",
    answer: "Il verbo è singolare", distractors: ["È la prima parola", "È la più corta", "Finisce in -us"],
    explanation: "*Vocat* è terza persona singolare, quindi il soggetto deve essere singolare: *servos* è accusativo plurale ed è escluso in partenza.",
    distractorWhy: { "È la prima parola": "La posizione non decide niente: la frase significherebbe lo stesso scrivendola in un altro ordine.", "È la più corta": "La lunghezza non è un criterio grammaticale in nessuna lingua.", "Finisce in -us": "Anche *manus* finisce in -us e può essere accusativo plurale: la coda va letta insieme al gruppo e al verbo." } },

  { topic: "frasi", difficulty: 6, difficulty8: true, applica: "latino-frasi-alta",
    prompt: "In «Milites patriam defendunt», perché il soggetto è «milites» e non «patriam»?",
    answer: "Perché il verbo è plurale", distractors: ["Perché viene per primo", "Perché finisce in -es", "Perché è più lungo"],
    explanation: "*Defendunt* è terza plurale e chiede un soggetto plurale; inoltre *patriam* porta la desinenza dell'accusativo singolare, quindi subisce.",
    distractorWhy: { "Perché viene per primo": "L'ordine in latino non assegna i ruoli: serve a dare enfasi.", "Perché finisce in -es": "Nella terza declinazione -es vale sia per il nominativo sia per l'accusativo plurale: da sola non decide.", "Perché è più lungo": "La lunghezza non ha nessun valore grammaticale." } },

  { topic: "frasi", difficulty: 8, difficulty8: true, applica: "latino-frasi-alta",
    prompt: "Su una frase lunga, che cosa conviene fare prima di cominciare a tradurre?",
    answer: "Assegnare un ruolo a ogni parola", distractors: ["Tradurre subito le parole note", "Cercare i nomi propri", "Contare le sillabe"],
    explanation: "Una traduzione costruita a metà, con due parole ancora senza funzione, porta quasi sempre a forzare il senso perché torni.",
    distractorWhy: { "Tradurre subito le parole note": "È proprio il modo in cui si costruisce un senso plausibile e sbagliato, saltando le desinenze.", "Cercare i nomi propri": "Aiutano a capire di che cosa si parla, ma non dicono nulla sulla struttura della frase.", "Contare le sillabe": "Serve in metrica, quando si studia il verso, e non ha niente a che fare con la traduzione." } },

  // ========================================================== ETIMOLOGIA
  { topic: "etimologia", difficulty: 2, difficulty8: true, applica: "latino-etimologia-base",
    prompt: "Da quale parola latina vengono insieme «acquedotto», «acquario» e «subacqueo»?",
    answer: "aqua", distractors: ["terra", "videre", "liber"],
    explanation: "Tutte e tre contengono la radice acqu-, e in tutte e tre il significato torna: condurre l'acqua, luogo per l'acqua, sotto l'acqua.",
    distractorWhy: { "terra": "Da lei vengono terrestre, sotterraneo e territorio: un'altra famiglia.", "videre": "Da lei vengono visione, televisione ed evidente, tutte legate al vedere.", "liber": "Da lei vengono libro e libreria, e nessuna delle tre parole della domanda." } },

  { topic: "etimologia", difficulty: 3, difficulty8: true, applica: "latino-etimologia-base",
    prompt: "Due parole si somigliano nella forma ma i loro significati non c'entrano niente. Che cosa se ne conclude?",
    answer: "La parentela non c'è", distractors: ["La parentela è certa", "Una deriva dall'altra", "Hanno la stessa radice"],
    explanation: "Una radice si riconosce da due cose insieme: il pezzo comune e il senso che torna. Senza la seconda, la somiglianza è quasi sempre casuale.",
    distractorWhy: { "La parentela è certa": "La forma da sola non basta: somiglianze casuali fra parole non imparentate sono frequentissime.", "Una deriva dall'altra": "Sarebbe una parentela, e la parentela va confermata dal significato prima che dalle lettere.", "Hanno la stessa radice": "Se avessero la stessa radice i significati sarebbero collegati, perché è la radice a portare il senso." } },

  { topic: "etimologia", difficulty: 5, difficulty8: true, applica: "latino-etimologia-alta",
    prompt: "Che cosa significa il prefisso latino «inter-»?",
    answer: "Fra", distractors: ["Sotto", "Oltre", "Dopo"],
    explanation: "Lo si ritrova in internazionale, cioè fra le nazioni, e in intervallo, cioè lo spazio fra due cose.",
    distractorWhy: { "Sotto": "È il significato di *sub-*, che sta in sottomarino e subacqueo.", "Oltre": "È il significato di *trans-*, che sta in transatlantico e transito.", "Dopo": "È il significato di *post-*, che sta in posticipare e postumo." } },

  { topic: "etimologia", difficulty: 6, difficulty8: true, applica: "latino-etimologia-alta",
    prompt: "Perché «illegale» comincia con il- e «irregolare» con ir-, se il prefisso è lo stesso?",
    answer: "Il prefisso si adatta al suono", distractors: ["Sono due prefissi diversi", "È un errore ormai accettato", "Derivano da lingue diverse"],
    explanation: "È sempre *in-*, che davanti a l diventa il- e davanti a r diventa ir- per ragioni di pronuncia: il significato di negazione resta identico.",
    distractorWhy: { "Sono due prefissi diversi": "Fanno lo stesso lavoro e hanno lo stesso senso: è il travestimento a cambiare, non il prefisso.", "È un errore ormai accettato": "Non è un errore: è un adattamento regolare che il latino faceva già, e che si chiama assimilazione.", "Derivano da lingue diverse": "Entrambe le parole vengono dal latino, e il prefisso è il medesimo in tutte e due." } },

  // ========================================================= VOCABOLARIO
  { topic: "vocabolario", difficulty: 1, difficulty8: true, applica: "latino-vocabolario-base",
    prompt: "Che cosa significa «servus»?",
    answer: "Schiavo", distractors: ["Signore", "Amico", "Maestro"],
    explanation: "È la parola che sta di fronte a *dominus* in moltissime frasi di esercizio: sono il modello più usato per mostrare chi compie e chi subisce.",
    distractorWhy: { "Signore": "Sarebbe *dominus*, cioè il padrone: è esattamente la parola opposta.", "Amico": "Sarebbe *amicus*, da cui viene l'italiano amicizia.", "Maestro": "Sarebbe *magister*, da cui vengono maestro e magistrato." } },

  { topic: "vocabolario", difficulty: 2, difficulty8: true, applica: "latino-vocabolario-base",
    format: "short_answer",
    prompt: "Quale parola latina significa «amico», e ha dato all'italiano «amicizia»?",
    answer: "amicus", accept: ["amicus", "amicus, amici"],
    explanation: "Seconda declinazione, maschile in -us. Agganciare la parola latina a un derivato italiano è quello che la fa restare in memoria." },

  { topic: "vocabolario", difficulty: 4, difficulty8: true, applica: "latino-vocabolario-base",
    prompt: "Quante informazioni servono per imparare bene una parola latina?",
    answer: "Tre: le due forme e il senso", distractors: ["Una: il significato", "Due: forma e senso", "Quattro: anche il genere"],
    explanation: "Nominativo, genitivo e significato: senza il genitivo non si conosce la declinazione, e senza quella non si costruisce nessun'altra forma.",
    distractorWhy: { "Una: il significato": "Il significato senza le forme permette di riconoscere la parola ma non di usarla né di declinarla.", "Due: forma e senso": "Con un solo nominativo manca proprio l'informazione che dice il gruppo, cioè il genitivo.", "Quattro: anche il genere": "Il genere è utile ma si ricava quasi sempre dal gruppo: le informazioni indispensabili restano tre." } },

  { topic: "vocabolario", difficulty: 5, difficulty8: true, applica: "latino-vocabolario-alta",
    prompt: "Che cosa significa «bellum»?",
    answer: "Guerra", distractors: ["Bello", "Bellezza", "Duello"],
    explanation: "È il falso amico più frequente del latino: somiglia all'aggettivo italiano ma non c'entra, e l'aggettivo latino per bello è *pulcher*.",
    distractorWhy: { "Bello": "È la trappola: la somiglianza è casuale, e in un testo storico produce frasi che non significano niente.", "Bellezza": "Segue la stessa somiglianza ingannevole, spostata sul sostantivo astratto.", "Duello": "È un tipo particolare di scontro fra due, e viene da *duellum*: il senso generale di *bellum* è guerra." } },

  { topic: "vocabolario", difficulty: 8, difficulty8: true, applica: "latino-vocabolario-alta",
    prompt: "Che cosa distingue «vir» da «homo»?",
    answer: "Vir è il maschio adulto", distractors: ["Sono sinonimi esatti", "Homo è più antico", "Vir è un plurale"],
    explanation: "*Homo* significa essere umano in generale, *vir* l'uomo inteso come maschio adulto: l'italiano ha fuso le due parole in una sola.",
    distractorWhy: { "Sono sinonimi esatti": "Il latino li tiene distinti proprio dove l'italiano no, ed è una distinzione che cambia il senso di molte frasi.", "Homo è più antico": "L'antichità delle due parole non è il criterio che le distingue: a distinguerle è l'ampiezza del significato.", "Vir è un plurale": "È un singolare della seconda declinazione: il plurale è *viri*." } },
];
