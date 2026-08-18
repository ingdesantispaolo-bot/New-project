export type EnglishVocabularyCategory =
  | "actions"
  | "objects"
  | "safety"
  | "data-science"
  | "school-communication"
  | "connectors"
  | "false-friends"
  | "home-family"
  | "food-shopping"
  | "time-weather"
  | "travel-places"
  | "body-health"
  | "feelings-opinions"
  | "digital-media"
  | "jobs-community"
  | "leisure-culture"
  | "nature-environment"
  | "everyday-phrases";

export type EnglishWordClass = "verb" | "noun" | "adjective" | "adverb" | "preposition" | "connector" | "phrase";

export type EnglishVocabularyEntry = {
  id: string;
  term: string;
  meaning: string;
  category: EnglishVocabularyCategory;
  wordClass: EnglishWordClass;
  level: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8;
  /**
   * Spiegazione autorata, quando ripetere l'accoppiata termine → significato non
   * insegna niente. Per il lessico l'accoppiata È il contenuto e `note` resta
   * vuota; per una collocazione o un phrasal verb no, perché la cosa da imparare
   * è proprio che il significato non si ricava dai pezzi. Chi genera esercizi
   * usa `note` al posto della spiegazione a modello quando c'è.
   */
  note?: string;
};

type CompactRow = readonly [
  term: string,
  meaning: string,
  wordClass: EnglishWordClass,
  level: EnglishVocabularyEntry["level"],
  note?: string,
];

const rows = <T extends readonly CompactRow[]>(category: EnglishVocabularyCategory, items: T) =>
  items.map((item) => ({ category, item }));

type Pair = readonly [term: string, meaning: string];

const topicRows = (
  category: EnglishVocabularyCategory,
  wordClass: EnglishWordClass,
  level: EnglishVocabularyEntry["level"],
  items: readonly Pair[],
) => rows(category, items.map(([term, meaning]) => [term, meaning, wordClass, level] as const));

const vocabularyRows = [
  ...rows("actions", [
    ["check", "controllare", "verb", 1],
    ["press", "premere", "verb", 1],
    ["open", "aprire", "verb", 1],
    ["close", "chiudere", "verb", 1],
    ["insert", "inserire", "verb", 1],
    ["remove", "rimuovere", "verb", 1],
    ["take", "prendere", "verb", 1],
    ["choose", "scegliere", "verb", 1],
    ["wait", "aspettare", "verb", 1],
    ["turn on", "accendere", "verb", 1],
    ["turn off", "spegnere", "verb", 1],
    ["write down", "annotare", "verb", 2],
    ["mark", "segnare", "verb", 2],
    ["select", "selezionare", "verb", 2],
    ["connect", "collegare", "verb", 2],
    ["disconnect", "scollegare", "verb", 2],
    ["measure", "misurare", "verb", 2],
    ["compare", "confrontare", "verb", 2],
    ["record", "registrare", "verb", 2],
    ["to report", "riferire, segnalare", "verb", 2, "Il verbo to report vuol dire riferire, segnalare. Il sostantivo a report è invece una relazione scritta: stessa parola, due usi."],
    ["restart", "riavviare", "verb", 2],
    ["protect", "proteggere", "verb", 2],
    ["avoid", "evitare", "verb", 3],
    ["repair", "riparare", "verb", 3],
    ["replace", "sostituire", "verb", 3],
    ["adjust", "regolare", "verb", 3],
    ["scan", "scansionare", "verb", 3],
    ["inspect", "ispezionare", "verb", 3],
    ["confirm", "confermare", "verb", 3],
    ["warn", "avvisare", "verb", 3],
    ["collect", "raccogliere", "verb", 3],
    ["store", "conservare / archiviare", "verb", 3],
    ["save", "salvare", "verb", 3],
    ["send", "inviare", "verb", 3],
    ["unlock", "sbloccare", "verb", 3],
    ["lock", "bloccare", "verb", 3],
    ["identify", "identificare", "verb", 4],
    ["explain", "spiegare", "verb", 4],
    ["describe", "descrivere", "verb", 4],
    ["summarize", "riassumere", "verb", 4],
    ["predict", "prevedere", "verb", 5],
    ["estimate", "stimare", "verb", 5],
    ["observe", "osservare", "verb", 5],
    ["install", "installare", "verb", 5],
    ["update", "aggiornare", "verb", 5],
    ["recharge", "ricaricare", "verb", 5],
    ["verify", "verificare", "verb", 6],
    ["detect", "rilevare", "verb", 6],
    ["prevent", "prevenire", "verb", 6],
    ["restore", "ripristinare", "verb", 6],
  ]),
  ...rows("objects", [
    ["button", "pulsante", "noun", 1],
    ["key", "chiave", "noun", 1],
    ["door", "porta", "noun", 1],
    ["card", "scheda / carta", "noun", 1],
    ["box", "scatola", "noun", 1],
    ["desk", "banco / scrivania", "noun", 1],
    ["drawer", "cassetto", "noun", 1],
    ["screen", "schermo", "noun", 1],
    ["light", "luce", "noun", 1],
    ["map", "mappa", "noun", 1],
    ["sensor", "sensore", "noun", 2],
    ["switch", "interruttore", "noun", 2],
    ["cable", "cavo", "noun", 2],
    ["battery", "batteria", "noun", 2],
    ["tool", "strumento", "noun", 2],
    ["device", "dispositivo", "noun", 2],
    ["module", "modulo", "noun", 2],
    ["valve", "valvola", "noun", 2],
    ["badge", "tesserino", "noun", 2],
    ["source", "fonte", "noun", 2],
    ["log", "registro", "noun", 2],
    ["message", "messaggio", "noun", 2],
    ["signal", "segnale", "noun", 2],
    ["panel", "pannello", "noun", 2],
    ["core", "nucleo", "noun", 2],
    ["pump", "pompa", "noun", 3],
    ["keyboard", "tastiera", "noun", 3],
    ["route", "percorso", "noun", 3],
    ["schedule", "orario / programma", "noun", 3],
    ["instruction", "istruzione", "noun", 3],
    ["question", "domanda", "noun", 3],
    ["answer", "risposta", "noun", 3],
    ["example", "esempio", "noun", 3],
    ["diagram", "diagramma", "noun", 3],
    ["table", "tabella", "noun", 3],
    ["graph", "grafico", "noun", 3],
    ["note", "nota / appunto", "noun", 3],
    ["file", "file / documento", "noun", 3],
    ["folder", "cartella", "noun", 3],
    ["supply", "fornitura / scorta", "noun", 4],
    ["crate", "cassa", "noun", 4],
    ["a report", "una relazione", "noun", 4, "Il sostantivo a report è una relazione, un resoconto scritto. Come verbo, to report vuol dire invece riferire."],
    ["result", "risultato", "noun", 4],
    ["warning", "avviso", "noun", 4],
    ["notice", "avviso scritto", "noun", 4, "Come verbo è «notare», come nome è un avviso affisso. Non è la «notizia», che è *news*."],
    ["equipment", "attrezzatura", "noun", 5],
    ["shortcut", "scorciatoia", "noun", 5],
    ["backup", "riserva / copia di sicurezza", "noun", 5],
    ["hatch", "sportello", "noun", 5],
    ["surface", "superficie", "noun", 5],
  ]),
  ...rows("safety", [
    ["safe", "sicuro", "adjective", 1],
    ["unsafe", "non sicuro", "adjective", 2],
    ["careful", "attento / prudente", "adjective", 2],
    ["danger", "pericolo", "noun", 2],
    ["risk", "rischio", "noun", 2],
    ["damage", "danno", "noun", 2],
    ["emergency", "emergenza", "noun", 2],
    ["gloves", "guanti", "noun", 2],
    ["alert", "allerta", "noun", 3],
    ["hazard", "pericolo specifico", "noun", 3],
    ["secure", "sicuro / protetto", "adjective", 3],
    ["fragile", "fragile", "adjective", 3],
    ["stable", "stabile", "adjective", 3],
    ["unstable", "instabile", "adjective", 3],
    ["blocked", "bloccato", "adjective", 3],
    ["overheated", "surriscaldato", "adjective", 3],
    ["protective", "protettivo", "adjective", 4],
    ["helmet", "casco", "noun", 4],
    ["mask", "maschera", "noun", 4],
    ["failure", "guasto / fallimento", "noun", 4],
    ["damaged", "danneggiato", "adjective", 4],
    ["spare", "di ricambio", "adjective", 4],
    ["broken", "rotto", "adjective", 4],
    ["loose", "allentato", "adjective", 5],
    ["sealed", "sigillato", "adjective", 5],
    ["required", "obbligatorio / richiesto", "adjective", 5],
  ]),
  ...rows("data-science", [
    ["number", "numero", "noun", 1],
    ["value", "valore", "noun", 2],
    ["total", "totale", "noun", 2],
    ["range", "intervallo", "noun", 2],
    ["pattern", "schema / andamento", "noun", 2],
    ["above", "sopra", "preposition", 2],
    ["below", "sotto, più in basso in un elenco", "preposition", 2, "below indica una posizione più in basso in un elenco, in una tabella o su una pagina: see the table below. Per «coperto da qualcosa» si usa invece under."],
    ["between", "tra / fra", "preposition", 2],
    ["inside", "dentro", "preposition", 2],
    ["outside", "fuori", "preposition", 2],
    ["under", "sotto, coperto da qualcosa", "preposition", 2, "under indica che una cosa sta sotto un'altra che la copre: the cat is under the table. Per «più in basso in un elenco» si usa invece below."],
    ["over", "sopra / oltre", "preposition", 2],
    ["through", "attraverso un passaggio", "preposition", 3],
    ["across", "attraverso una superficie", "preposition", 3],
    ["accurate", "preciso / accurato", "adjective", 3],
    ["reliable", "affidabile", "adjective", 3],
    ["random", "casuale", "adjective", 3],
    ["exact", "esatto", "adjective", 3],
    ["similar", "simile", "adjective", 3],
    ["different", "diverso", "adjective", 3],
    ["higher", "più alto", "adjective", 3],
    ["lower", "più basso", "adjective", 3],
    ["enough", "abbastanza / sufficiente", "adverb", 3],
    ["few", "pochi", "adjective", 3],
    ["several", "diversi / parecchi", "adjective", 3],
    ["temperature", "temperatura", "noun", 3],
    ["pressure", "pressione", "noun", 3],
    ["threshold", "soglia", "noun", 4],
    ["average", "media", "noun", 4],
    ["percentage", "percentuale", "noun", 4],
    ["fraction", "frazione", "noun", 4],
    ["increase", "aumento / aumentare", "noun", 4],
    ["decrease", "diminuzione / diminuire", "noun", 4],
    ["cause", "causa", "noun", 4],
    ["effect", "effetto", "noun", 4],
    ["evidence", "prova / evidenza", "noun", 4],
    ["measurement", "misurazione", "noun", 4],
    ["conclusion", "conclusione", "noun", 4],
    ["calibration", "calibrazione", "noun", 5],
    ["consistent", "coerente / costante", "adjective", 5],
    ["approximate", "approssimativo", "adjective", 5],
    ["therefore", "perciò / quindi", "connector", 5, "Introduce la conseguenza di quello che si è appena detto. Sta all'inizio della frase, spesso dopo il punto."],
    ["suggest", "suggerire / indicare", "verb", 5, "Proporre un'idea senza imporla. Regge la forma in -ing: *I suggest waiting*, non *to wait*."],
    ["prove", "dimostrare", "verb", 5, "Dimostrare che qualcosa è vero, con le prove. Non è «provare» nel senso di tentare: quello è *try*."],
    ["sample", "campione", "noun", 6],
    ["trend", "tendenza", "noun", 6],
    ["variable", "variabile", "noun", 6],
    ["accurately", "con precisione", "adverb", 6],
    ["roughly", "circa / approssimativamente", "adverb", 6],
    ["likely", "probabile", "adjective", 6],
  ]),
  ...rows("school-communication", [
    ["lesson", "lezione", "noun", 1],
    ["subject", "argomento / settore", "noun", 1],
    ["homework", "compiti", "noun", 1],
    ["classmate", "compagno di classe", "noun", 1],
    ["teacher", "insegnante", "noun", 1],
    ["assignment", "compito assegnato", "noun", 2],
    ["deadline", "scadenza", "noun", 2],
    ["chapter", "capitolo", "noun", 2],
    ["paragraph", "paragrafo", "noun", 2],
    ["summary", "riassunto", "noun", 2],
    ["reason", "ragione / motivo", "noun", 2],
    ["opinion", "opinione", "noun", 2],
    ["fact", "fatto", "noun", 2],
    ["detail", "dettaglio", "noun", 2],
    ["main idea", "idea principale", "noun", 3],
    ["mistake", "errore", "noun", 3],
    ["correction", "correzione", "noun", 3],
    ["feedback", "riscontro / feedback", "noun", 3],
    ["email", "email", "noun", 3],
    ["announcement", "annuncio", "noun", 3],
    ["request", "richiesta", "noun", 3],
    ["reply", "risposta / replica", "noun", 3],
    ["formal", "formale", "adjective", 4],
    ["informal", "informale", "adjective", 4],
    ["polite", "educato / cortese", "adjective", 4],
    ["brief", "breve", "adjective", 4],
    ["clear", "chiaro", "adjective", 4],
    ["unclear", "poco chiaro", "adjective", 4],
    ["relevant", "pertinente", "adjective", 5],
    ["irrelevant", "non pertinente", "adjective", 5],
    ["purpose", "scopo", "noun", 5],
    ["target audience", "i destinatari", "noun", 5, "La target audience è chi deve ricevere il messaggio: i destinatari a cui stai parlando. Da sola, audience vuol dire il pubblico."],
  ]),
  ...rows("connectors", [
    ["and", "e", "connector", 1],
    ["but", "ma", "connector", 1],
    ["or", "oppure", "connector", 1],
    ["then", "poi", "connector", 1],
    ["because", "perché / poiché", "connector", 2],
    ["if", "se", "connector", 2],
    ["when", "quando", "connector", 2],
    ["before", "prima", "connector", 2],
    ["after", "dopo", "connector", 2],
    ["while", "mentre", "connector", 3],
    ["until", "finché / fino a quando", "connector", 3],
    ["unless", "a meno che", "connector", 3],
    ["however", "tuttavia", "connector", 4],
    ["although", "sebbene / anche se", "connector", 4],
    ["therefore", "perciò / quindi", "connector", 4],
    ["instead", "invece", "adverb", 4],
    ["either", "uno dei due / o l'uno o l'altro", "adverb", 4],
    ["neither", "nessuno dei due / né", "adverb", 4],
    ["both", "entrambi", "adverb", 4],
    ["only", "solo / soltanto", "adverb", 2],
    ["except", "tranne / eccetto", "preposition", 5, "Toglie un elemento da un insieme appena nominato: tutti tranne quello."],
    ["since", "poiché / da quando", "connector", 5],
    ["so that", "in modo che", "connector", 5],
    ["despite", "nonostante", "preposition", 6, "Introduce un ostacolo che non ha fermato niente. Si usa senza «of»: *despite the rain*, mai *despite of*."],
    ["as soon as", "appena / non appena", "connector", 6],
    ["in order to", "per / allo scopo di", "connector", 6],
  ]),
  ...rows("false-friends", [
    ["actual", "reale / effettivo", "adjective", 5, "Non vuol dire «attuale»: quello è *current*. «Actual» dice ciò che è vero davvero, non ciò che accade adesso."],
    ["actually", "in realtà", "adverb", 5, "Non è «attualmente» (*currently*): introduce una correzione — «in realtà, veramente»."],
    ["eventually", "alla fine", "adverb", 5, "Non è «eventualmente» (*possibly*): dice che alla fine è successo per certo, non che potrebbe succedere."],
    ["sensible", "ragionevole", "adjective", 5, "Non è «sensibile» (*sensitive*): descrive chi ragiona bene e sceglie con buon senso."],
    ["sensitive", "sensibile / delicato", "adjective", 5, "Questo sì è «sensibile» nel senso di delicato. Da non scambiare con *sensible*, che invece è ragionevole."],
    ["library", "biblioteca", "noun", 3, "Non è la «libreria» dove si comprano i libri (*bookshop*): è dove si prendono in prestito."],
    ["bookshop", "libreria / negozio di libri", "noun", 3, "È il negozio, cioè la «libreria» italiana. La biblioteca è *library*: le due parole sono incrociate rispetto all'italiano."],
    ["factory", "fabbrica", "noun", 3, "Non è la «fattoria» (*farm*): è lo stabilimento dove si producono le cose."],
    ["argument", "discussione / argomento", "noun", 5, "Spesso è un litigio, non un «argomento» di discorso: quello è *topic*."],
    ["parents", "genitori", "noun", 3, "Non sono i «parenti» (*relatives*): sono soltanto la madre e il padre."],
    ["relative", "parente / relativo", "noun", 5, "Questo è il «parente». *Parents* invece sono solo i genitori: l'italiano fa il contrario e confonde."],
    ["comprehensive", "completo / esauriente", "adjective", 6, "Non vuol dire «comprensivo» nel senso di indulgente: dice che comprende tutto, che non lascia fuori niente."],
    ["pretend", "fingere", "verb", 5, "Non è «pretendere» (*demand*): è fare finta."],
    ["assist", "aiutare / assistere", "verb", 5, "Vuol dire aiutare attivamente, non «assistere» nel senso di guardare: quello è *attend* o *watch*."],
    ["brave", "coraggioso", "adjective", 4, "Non è «bravo» (*good at*): è coraggioso."],
    ["camera", "macchina fotografica / videocamera", "noun", 3, "Non è la «camera» da letto (*bedroom*): è l'apparecchio per fotografare."],
    ["education", "istruzione", "noun", 4, "È l'istruzione scolastica in generale; «educazione» come buone maniere è *manners*."],
    ["terrific", "fantastico / enorme", "adjective", 5, "Nonostante somigli a «terrificante», è un complimento: vuol dire fantastico."],
    ["realize", "rendersi conto", "verb", 5, "Prima di tutto è «accorgersi». «Realizzare» un progetto si dice *carry out* o *achieve*."],
    ["convenient", "comodo / conveniente", "adjective", 5, "Dice che è comodo e pratico, non che costa poco: quello è *cheap*."],
    ["notice", "avviso / notare", "noun", 4],
    ["lecture", "lezione universitaria / conferenza", "noun", 6, "Non è la «lettura» (*reading*): è una lezione tenuta parlando davanti a un pubblico."],
    ["eventual", "finale / definitivo", "adjective", 6, "Come *eventually*, dice ciò che accade alla fine per certo, non ciò che è possibile."],
    ["preservative", "conservante", "noun", 6, "Non è il «preservativo»: è la sostanza che conserva i cibi."],
    ["morbidity", "morbilità", "noun", 8, "Termine tecnico: quanta malattia c'è in una popolazione. Non ha il senso di «morbosità»."],
  ]),
] as const;

const everydayVocabularyRows = [
  ...topicRows("home-family", "noun", 1, [
    ["family", "famiglia"], ["mother", "madre"], ["father", "padre"], ["parent", "genitore"], ["sister", "sorella"],
    ["brother", "fratello"], ["son", "figlio"], ["daughter", "figlia"], ["child", "bambino / figlio"], ["children", "bambini / figli"],
    ["grandmother", "nonna"], ["grandfather", "nonno"], ["aunt", "zia"], ["uncle", "zio"], ["cousin", "cugino / cugina"],
    ["wife", "moglie"], ["husband", "marito"], ["neighbour", "vicino di casa"], ["friend", "amico"], ["guest", "ospite"],
    ["house", "casa"], ["home", "casa / abitazione"], ["room", "stanza"], ["bedroom", "camera da letto"], ["bathroom", "bagno"],
    ["kitchen", "cucina"], ["living room", "soggiorno"], ["garden", "giardino"], ["garage", "garage"], ["stairs", "scale"],
    ["floor", "pavimento / piano"], ["wall", "parete"], ["window", "finestra"], ["roof", "tetto"], ["gate", "cancello"],
    ["bed", "letto"], ["chair", "sedia"], ["sofa", "divano"], ["table", "tavolo"], ["cupboard", "armadio / credenza"],
    ["shelf", "mensola"], ["mirror", "specchio"], ["shower", "doccia"], ["toilet", "gabinetto"], ["sink", "lavandino"],
    ["towel", "asciugamano"], ["soap", "sapone"], ["blanket", "coperta"], ["pillow", "cuscino"], ["carpet", "tappeto"],
    ["lamp", "lampada"], ["fridge", "frigorifero"], ["oven", "forno"], ["plate", "piatto"], ["glass", "bicchiere"],
    ["cup", "tazza"], ["fork", "forchetta"], ["knife", "coltello"], ["spoon", "cucchiaio"], ["bottle", "bottiglia"],
    ["bag", "borsa / zaino"], ["wallet", "portafoglio"], ["pocket", "tasca"], ["address", "indirizzo"], ["surname", "cognome"],
  ]),
  ...topicRows("home-family", "adjective", 2, [
    ["young", "giovane"], ["old", "vecchio / anziano"], ["married", "sposato"], ["single", "single / non sposato"],
    ["clean", "pulito"], ["dirty", "sporco"], ["tidy", "ordinato"], ["untidy", "disordinato"], ["quiet", "silenzioso"],
    ["noisy", "rumoroso"], ["comfortable", "comodo"], ["empty", "vuoto"], ["full", "pieno"], ["private", "privato"],
  ]),
  ...topicRows("food-shopping", "noun", 1, [
    ["food", "cibo"], ["meal", "pasto"], ["breakfast", "colazione"], ["lunch", "pranzo"], ["dinner", "cena"],
    ["snack", "spuntino"], ["bread", "pane"], ["rice", "riso"], ["pasta", "pasta"], ["meat", "carne"],
    ["fish", "pesce"], ["egg", "uovo"], ["cheese", "formaggio"], ["milk", "latte"], ["butter", "burro"],
    ["fruit", "frutta"], ["apple", "mela"], ["banana", "banana"], ["orange", "arancia"], ["vegetable", "verdura"],
    ["potato", "patata"], ["tomato", "pomodoro"], ["salad", "insalata"], ["soup", "zuppa"], ["cake", "torta"],
    ["sugar", "zucchero"], ["salt", "sale"], ["pepper", "pepe"], ["water", "acqua"], ["juice", "succo"],
    ["tea", "tè"], ["coffee", "caffè"], ["menu", "menù"], ["recipe", "ricetta"], ["ingredient", "ingrediente"],
    ["shop", "negozio"], ["market", "mercato"], ["supermarket", "supermercato"], ["customer", "cliente"], ["shop assistant", "commesso"],
    ["price", "prezzo"], ["money", "denaro"], ["cash", "contanti"], ["coin", "moneta"], ["bill", "banconota / conto"],
    ["receipt", "scontrino"], ["discount", "sconto"], ["sale", "saldi / vendita"], ["size", "taglia / dimensione"], ["colour", "colore"],
    ["clothes", "vestiti"], ["shirt", "camicia"], ["T-shirt", "maglietta"], ["trousers", "pantaloni"], ["jeans", "jeans"],
    ["skirt", "gonna"], ["dress", "vestito"], ["jacket", "giacca"], ["coat", "cappotto"], ["shoes", "scarpe"],
    ["trainers", "scarpe da ginnastica"], ["socks", "calzini"], ["hat", "cappello"], ["scarf", "sciarpa"], ["glasses", "occhiali"],
  ]),
  ...topicRows("food-shopping", "adjective", 2, [
    ["hungry", "affamato"], ["thirsty", "assetato"], ["fresh", "fresco, appena fatto"], ["sweet", "dolce"], ["salty", "salato"],
    ["cheap", "economico"], ["expensive", "costoso"], ["free", "gratuito / libero"], ["available", "disponibile"], ["sold out", "esaurito"],
  ]),
  ...topicRows("time-weather", "noun", 1, [
    ["time", "tempo / ora"], ["hour", "ora"], ["minute", "minuto"], ["second", "secondo"], ["day", "giorno"],
    ["week", "settimana"], ["month", "mese"], ["year", "anno"], ["morning", "mattina"], ["afternoon", "pomeriggio"],
    ["evening", "sera"], ["night", "notte"], ["today", "oggi"], ["tomorrow", "domani"], ["yesterday", "ieri"],
    ["weekend", "fine settimana"], ["holiday", "vacanza / festa"], ["season", "stagione"], ["spring", "primavera"], ["summer", "estate"],
    ["autumn", "autunno"], ["winter", "inverno"], ["weather", "tempo atmosferico"], ["sun", "sole"], ["rain", "pioggia"],
    ["snow", "neve"], ["wind", "vento"], ["cloud", "nuvola"], ["storm", "temporale"], ["fog", "nebbia"],
    ["temperature", "temperatura"], ["degree", "grado"], ["forecast", "previsioni"], ["climate", "clima"], ["sky", "cielo"],
  ]),
  ...topicRows("time-weather", "adjective", 1, [
    ["early", "presto / in anticipo"], ["late", "tardi / in ritardo"], ["busy", "occupato / intenso"], ["ready", "pronto"],
    ["sunny", "soleggiato"], ["rainy", "piovoso"], ["cloudy", "nuvoloso"], ["windy", "ventoso"], ["snowy", "nevoso"],
    ["warm", "caldo / tiepido"], ["cool", "fresco, di temperatura"], ["cold", "freddo"], ["hot", "caldo"], ["dry", "asciutto / secco"],
    ["wet", "bagnato"], ["usual", "solito"], ["daily", "quotidiano"], ["weekly", "settimanale"],
  ]),
  ...topicRows("travel-places", "noun", 1, [
    ["place", "posto / luogo"], ["street", "strada"], ["road", "strada"], ["square", "piazza"], ["city", "città"],
    ["town", "cittadina"], ["village", "villaggio / paese"], ["country", "paese / campagna"], ["station", "stazione"], ["bus stop", "fermata dell'autobus"],
    ["airport", "aeroporto"], ["port", "porto"], ["platform", "binario / piattaforma"], ["ticket", "biglietto"], ["map", "mappa"],
    ["journey", "viaggio"], ["trip", "gita / viaggio breve"], ["travel", "viaggio / viaggiare"], ["traffic", "traffico"], ["vehicle", "veicolo"],
    ["car", "auto"], ["bus", "autobus"], ["train", "treno"], ["plane", "aereo"], ["bike", "bicicletta"],
    ["boat", "barca"], ["taxi", "taxi"], ["underground", "metropolitana"], ["bridge", "ponte"], ["crossing", "attraversamento"],
    ["corner", "angolo"], ["entrance", "entrata"], ["exit", "uscita"], ["building", "edificio"], ["library", "biblioteca"],
    ["museum", "museo"], ["cinema", "cinema"], ["theatre", "teatro"], ["hospital", "ospedale"], ["chemist's", "farmacia"],
    ["bank", "banca"], ["post office", "ufficio postale"], ["police station", "stazione di polizia"], ["hotel", "hotel"], ["restaurant", "ristorante"],
    ["café", "bar / caffetteria"], ["park", "parco"], ["beach", "spiaggia"], ["mountain", "montagna"], ["river", "fiume"],
  ]),
  ...topicRows("travel-places", "preposition", 2, [
    ["near", "vicino"], ["far from", "lontano da"], ["next to", "accanto a"], ["opposite", "di fronte a"], ["behind", "dietro"],
    ["in front of", "davanti a"], ["along", "lungo"], ["towards", "verso"], ["around", "intorno a"], ["past", "oltre / dopo"],
  ]),
  // Viaggio e scambio a livello avanzato (mondo 16, Frontiera delle Lingue): il
  // lessico del viaggio reale — biglietteria, ritardi, dogana, alloggio — che la
  // lezione promette e che ai livelli alti mancava (il banco si fermava al livello 1).
  ...topicRows("travel-places", "noun", 6, [
    ["departure", "partenza"], ["arrival", "arrivo"], ["delay", "ritardo"], ["timetable", "orario"], ["fare", "tariffa"],
    ["itinerary", "itinerario"], ["connection", "coincidenza"], ["luggage", "bagaglio"], ["suitcase", "valigia"], ["passenger", "passeggero"],
  ]),
  ...topicRows("travel-places", "noun", 7, [
    ["boarding pass", "carta d'imbarco"], ["customs", "dogana"], ["border", "confine"], ["accommodation", "alloggio"], ["destination", "destinazione"],
    ["return ticket", "biglietto di andata e ritorno"], ["single ticket", "biglietto di sola andata"], ["left luggage", "deposito bagagli"], ["waiting room", "sala d'attesa"], ["lost property", "oggetti smarriti"],
  ]),
  ...topicRows("travel-places", "verb", 7, [
    ["board", "salire a bordo"], ["check in", "fare il check-in"], ["book", "prenotare"], ["cancel", "annullare"], ["depart", "partire"],
    ["arrive", "arrivare"], ["change trains", "cambiare treno"], ["miss the train", "perdere il treno"], ["get off", "scendere"], ["set off", "mettersi in viaggio"],
  ]),
  ...topicRows("body-health", "noun", 1, [
    ["body", "corpo"], ["head", "testa"], ["face", "viso"], ["eye", "occhio"], ["ear", "orecchio"],
    ["nose", "naso"], ["mouth", "bocca"], ["tooth", "dente"], ["teeth", "denti"], ["hair", "capelli"],
    ["hand", "mano"], ["arm", "braccio"], ["leg", "gamba"], ["foot", "piede"], ["feet", "piedi"],
    ["back", "schiena"], ["stomach", "stomaco / pancia"], ["heart", "cuore"], ["blood", "sangue"], ["skin", "pelle"],
    ["health", "salute"], ["doctor", "dottore"], ["nurse", "infermiere"], ["patient", "paziente"], ["medicine", "medicina"],
    ["pill", "pillola"], ["pain", "dolore"], ["headache", "mal di testa"], ["toothache", "mal di denti"], ["stomach ache", "mal di pancia"],
    ["cold", "raffreddore"], ["cough", "tosse"], ["fever", "febbre"], ["sore throat", "mal di gola"], ["temperature", "febbre / temperatura"],
    ["accident", "incidente"], ["injury", "ferita / infortunio"], ["bandage", "bendaggio"], ["appointment", "appuntamento"], ["exercise", "attività fisica"],
  ]),
  ...topicRows("body-health", "adjective", 2, [
    ["ill", "malato"], ["sick", "malato / nauseato"], ["healthy", "sano"], ["tired", "stanco"], ["better", "meglio"],
    ["worse", "peggio"], ["weak", "debole"], ["strong", "forte"], ["fit", "in forma"], ["sleepy", "assonnato"],
  ]),
  ...topicRows("feelings-opinions", "adjective", 1, [
    ["happy", "felice"], ["sad", "triste"], ["angry", "arrabbiato"], ["worried", "preoccupato"], ["afraid", "spaventato"],
    ["scared", "spaventato"], ["bored", "annoiato"], ["interested", "interessato"], ["excited", "emozionato"], ["surprised", "sorpreso"],
    ["proud", "orgoglioso"], ["shy", "timido"], ["kind", "gentile"], ["friendly", "amichevole"], ["rude", "maleducato"],
    ["funny", "divertente"], ["serious", "serio"], ["clever", "intelligente"], ["brilliant", "brillante"], ["lazy", "pigro"],
    ["patient", "paziente"], ["popular", "popolare"], ["lonely", "solo"], ["calm", "calmo"], ["nervous", "nervoso"],
    ["confident", "sicuro di sé"], ["honest", "onesto"], ["fair", "giusto / equo"], ["unfair", "ingiusto"], ["useful", "utile"],
    ["useless", "inutile"], ["important", "importante"], ["necessary", "necessario"], ["possible", "possibile"], ["impossible", "impossibile"],
  ]),
  ...topicRows("feelings-opinions", "noun", 2, [
    ["feeling", "sensazione / sentimento"], ["idea", "idea"], ["opinion", "opinione"], ["choice", "scelta"], ["plan", "piano"],
    ["problem", "problema"], ["solution", "soluzione"], ["mistake", "errore"], ["chance", "possibilità"], ["hope", "speranza"],
    ["fear", "paura"], ["dream", "sogno"], ["success", "successo"], ["failure", "fallimento"], ["truth", "verità"],
  ]),
  ...topicRows("digital-media", "noun", 2, [
    ["computer", "computer"], ["laptop", "portatile"], ["tablet", "tablet"], ["phone", "telefono"], ["smartphone", "smartphone"],
    ["charger", "caricatore"], ["headphones", "cuffie"], ["speaker", "altoparlante"], ["mouse", "mouse"], ["printer", "stampante"],
    ["camera", "fotocamera"], ["photo", "foto"], ["video", "video"], ["website", "sito web"], ["page", "pagina"],
    ["link", "collegamento / link"], ["password", "password"], ["username", "nome utente"], ["account", "account"], ["app", "applicazione"],
    ["game", "gioco"], ["message", "messaggio"], ["chat", "chat"], ["post", "post"], ["comment", "commento"],
    ["news", "notizia"], ["article", "articolo"], ["search result", "risultato di ricerca"], ["download file", "file scaricato"], ["upload area", "area di caricamento"],
    ["file", "file"], ["folder", "cartella"], ["screen", "schermo"], ["keyboard", "tastiera"], ["internet", "internet"],
  ]),
  ...topicRows("digital-media", "verb", 3, [
    ["click", "cliccare"], ["type", "digitare"], ["print", "stampare"], ["share", "condividere"], ["delete", "cancellare"],
    ["copy", "copiare"], ["paste", "incollare"], ["save", "salvare"], ["search", "cercare"], ["download", "scaricare"],
    ["upload", "caricare online"], ["log in", "accedere"], ["log out", "uscire dall'account"], ["switch on", "accendere"], ["switch off", "spegnere"],
  ]),
  ...topicRows("jobs-community", "noun", 2, [
    ["job", "lavoro"], ["work", "lavoro"], ["worker", "lavoratore"], ["manager", "responsabile"], ["farmer", "contadino"],
    ["driver", "autista"], ["cook", "cuoco"], ["waiter", "cameriere"], ["shop assistant", "commesso"], ["mechanic", "meccanico"],
    ["engineer", "ingegnere"], ["scientist", "scienziato"], ["artist", "artista"], ["musician", "musicista"], ["actor", "attore"],
    ["writer", "scrittore"], ["journalist", "giornalista"], ["police officer", "poliziotto"], ["firefighter", "vigile del fuoco"], ["soldier", "soldato"],
    ["office", "ufficio"], ["factory", "fabbrica"], ["farm", "fattoria"], ["company", "azienda"], ["team", "squadra"],
    ["meeting", "riunione"], ["project", "progetto"], ["task", "compito"], ["service", "servizio"], ["community", "comunità"],
    ["city hall", "municipio"], ["school", "scuola"], ["college", "istituto / college"], ["club", "club"], ["charity", "beneficenza / ente benefico"],
  ]),
  ...topicRows("jobs-community", "adjective", 4, [
    ["local", "locale"], ["public", "pubblico"], ["private", "privato"], ["professional", "professionale"], ["responsible", "responsabile"],
    ["temporary", "temporaneo"], ["full-time", "a tempo pieno"], ["part-time", "part-time"], ["busy", "occupato"], ["available", "disponibile"],
  ]),
  // Mestieri e comunità a livello avanzato (mondo 16): candidature, turni, diritti
  // e doveri — il lessico degli scambi tra persone che la lezione promette.
  ...topicRows("jobs-community", "noun", 6, [
    ["interview", "colloquio"], ["salary", "stipendio"], ["shift", "turno"], ["colleague", "collega"], ["customer", "cliente"],
    ["appointment", "appuntamento"], ["council", "consiglio comunale"], ["citizen", "cittadino"], ["duty", "dovere / mansione"], ["volunteer", "volontario"],
  ]),
  ...topicRows("jobs-community", "verb", 7, [
    ["apply for", "candidarsi a"], ["hire", "assumere"], ["earn", "guadagnare"], ["manage", "gestire"], ["deliver", "consegnare"],
    ["repair", "riparare"], ["serve", "servire"], ["train", "formare / addestrare"], ["retire", "andare in pensione"], ["cooperate", "collaborare"],
  ]),
  ...topicRows("leisure-culture", "noun", 1, [
    ["sport", "sport"], ["football", "calcio"], ["basketball", "pallacanestro"], ["tennis", "tennis"], ["volleyball", "pallavolo"],
    ["swimming", "nuoto"], ["running", "corsa"], ["cycling", "ciclismo"], ["dance", "danza"], ["music", "musica"],
    ["song", "canzone"], ["film", "film"], ["movie", "film"], ["cartoon", "cartone animato"], ["book", "libro"],
    ["story", "storia / racconto"], ["magazine", "rivista"], ["comic", "fumetto"], ["drawing", "disegno"], ["painting", "dipinto"],
    ["hobby", "hobby"], ["free time", "tempo libero"], ["competition", "gara"], ["match", "partita"], ["race", "gara / corsa"],
    ["score", "punteggio"], ["team", "squadra"], ["player", "giocatore"], ["winner", "vincitore"], ["prize", "premio"],
    ["concert", "concerto"], ["festival", "festival"], ["exhibition", "mostra"], ["ticket", "biglietto"], ["audience", "pubblico"],
  ]),
  ...topicRows("leisure-culture", "adjective", 2, [
    ["interesting", "interessante"], ["boring", "noioso"], ["fun", "divertente"], ["amazing", "straordinario"], ["terrible", "terribile"],
    ["popular", "popolare"], ["traditional", "tradizionale"], ["modern", "moderno"], ["creative", "creativo"], ["famous", "famoso"],
  ]),
  ...topicRows("nature-environment", "noun", 1, [
    ["animal", "animale"], ["bird", "uccello"], ["cat", "gatto"], ["dog", "cane"], ["horse", "cavallo"],
    ["fish", "pesce"], ["tree", "albero"], ["flower", "fiore"], ["plant", "pianta"], ["grass", "erba"],
    ["forest", "foresta"], ["wood", "bosco / legno"], ["field", "campo"], ["farm", "fattoria"], ["hill", "collina"],
    ["mountain", "montagna"], ["lake", "lago"], ["river", "fiume"], ["sea", "mare"], ["ocean", "oceano"],
    ["island", "isola"], ["beach", "spiaggia"], ["sand", "sabbia"], ["stone", "pietra"], ["rock", "roccia"],
    ["air", "aria"], ["water", "acqua"], ["fire", "fuoco"], ["earth", "terra"], ["space", "spazio"],
    ["environment", "ambiente"], ["pollution", "inquinamento"], ["rubbish", "spazzatura"], ["plastic", "plastica"], ["energy", "energia"],
  ]),
  ...topicRows("nature-environment", "adjective", 3, [
    ["natural", "naturale"], ["wild", "selvatico"], ["clean", "pulito"], ["dirty", "sporco"], ["green", "verde / ecologico"],
    ["pure", "puro"], ["deep", "profondo"], ["shallow", "poco profondo"], ["wide", "ampio"], ["narrow", "stretto"],
  ]),
] as const;

// Una collocazione NON si traduce a pezzi: è il difetto che questa struttura
// aveva prima del 3 agosto 2026. Le famiglie erano definite come
// `verbMeaning + oggetto`, cioè un solo significato del verbo per tutta la
// famiglia, e il bake incollava i due pezzi. Ne uscivano ottanta traduzioni
// false — "fare / preparare un errore" per make a mistake, "guardare / sembrare
// la parola sul dizionario" per look up the word — e metà degli item chiedeva
// al bambino di tradurre IN inglese partendo da quell'italiano.
//
// L'ironia è che erano proprio i phrasal verb e le collocazioni: l'unica
// famiglia di espressioni che per definizione non è componibile. Ora ogni riga
// porta il significato italiano INTERO, e `note` dice qual è la trappola —
// perché è quello, non l'accoppiata, il contenuto che serve davvero.
type PhraseRow = readonly [object: string, meaning: string, note?: string];

type PhraseGroup = {
  category: EnglishVocabularyCategory;
  verb: string;
  level: EnglishVocabularyEntry["level"];
  objects: readonly PhraseRow[];
};

const phraseGroups: readonly PhraseGroup[] = [
  {
    category: "everyday-phrases",
    verb: "take",
    level: 2,
    objects: [
      ["a photo", "fare una foto", "take a photo = fare una foto: l'inglese la foto la «prende», l'italiano la «fa»."],
      ["a bus", "prendere l'autobus", "Qui take è davvero prendere, ma è un caso fortunato: con photo o shower lo stesso take diventa fare."],
      ["a break", "fare una pausa", "In inglese la pausa si «prende», in italiano si «fa»."],
      ["notes", "prendere appunti", "Uno dei pochi casi in cui i due verbi coincidono."],
      ["care", "abbi cura di te", "take care si usa per salutare: abbi cura di te, stammi bene. «Prendi cura» non è italiano."],
      ["a shower", "fare la doccia", "La doccia in inglese si «prende», in italiano si «fa»."],
      ["a seat", "accomodarsi", "take a seat è un invito cortese a sedersi: accomodarsi, prego."],
      ["a test", "fare un test", "Chi «prende» il test in inglese lo «fa» in italiano; chi lo svolge in classe dice do a test."],
      ["a message", "prendere un messaggio", "Al telefono: prendere un messaggio, cioè annotarlo per qualcun altro."],
      ["a look", "dare un'occhiata", "L'inglese lo sguardo lo «prende», l'italiano lo «dà»: verbi opposti, stesso significato."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "make",
    level: 2,
    objects: [
      ["a mistake", "fare un errore", "Make vuol dire costruire, produrre, ma con mistake in italiano diventa fare."],
      ["a plan", "fare un piano", "Con le cose che si progettano l'inglese usa make."],
      ["a list", "fare una lista", "Make si usa per ciò che prima non esisteva e viene creato."],
      ["breakfast", "preparare la colazione", "make breakfast è cucinarla; have breakfast è fare colazione, cioè mangiarla."],
      ["a choice", "fare una scelta", "Si può dire anche choose, con una parola sola."],
      ["a noise", "fare rumore", "In italiano il rumore non si «prepara»: si fa."],
      ["a phone call", "fare una telefonata", "Si dice anche call someone, più breve e più comune."],
      ["a cake", "preparare una torta", "Qui make è davvero il verbo del cucinare."],
      ["progress", "fare progressi", "In inglese progress è singolare, in italiano il plurale è obbligatorio: «fare progresso» non si dice."],
      ["a decision", "prendere una decisione", "Qui make non è fare ma prendere: la prova che queste espressioni vanno imparate intere."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "do",
    level: 2,
    objects: [
      ["homework", "fare i compiti", "Con do si svolgono lavori e compiti già stabiliti; con make si crea qualcosa di nuovo."],
      ["exercise", "fare attività fisica", "exercise qui è l'attività fisica, non l'esercizio di scuola."],
      ["the dishes", "lavare i piatti", "do the dishes = lavare i piatti. «Fare i piatti» in italiano vorrebbe dire fabbricarli."],
      ["the shopping", "fare la spesa", "do the shopping è la spesa di tutti i giorni; go shopping è andare per negozi."],
      ["research", "fare una ricerca"],
      ["a project", "fare un progetto"],
      ["a test", "svolgere un test", "do a test lo dice chi il test lo svolge; take a test è farlo, make a test è prepararlo."],
      ["your best", "fare del proprio meglio", "Il possessivo cambia con la persona: I do my best, you do your best."],
      ["the cleaning", "fare le pulizie"],
      ["a favour", "fare un favore", "Si scrive favour in inglese britannico, favor in quello americano."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "go",
    level: 2,
    objects: [
      ["home", "andare a casa", "Con home non ci vuole preposizione: si dice go home, non «go to home»."],
      ["shopping", "andare a fare acquisti", "go + verbo in -ing indica l'attività per cui ci si sposta."],
      ["swimming", "andare a nuotare", "Come go shopping: go + -ing per le attività."],
      ["online", "andare online"],
      ["to school", "andare a scuola", "Qui la preposizione to serve, a differenza di go home."],
      ["to work", "andare al lavoro"],
      ["by bus", "andare in autobus", "by + mezzo indica come ci si sposta: by bus, by train, by car."],
      ["on foot", "andare a piedi", "A piedi è l'eccezione: non by foot ma on foot."],
      ["abroad", "andare all'estero", "Anche abroad non vuole preposizione: go abroad."],
      ["out", "uscire", "go out = uscire, soprattutto per divertirsi la sera."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "get",
    level: 3,
    objects: [
      ["ready", "prepararsi", "get + aggettivo vuol dire diventare: get ready = diventare pronto, cioè prepararsi."],
      ["better", "migliorare", "Parlando di salute vuol dire guarire, rimettersi."],
      ["worse", "peggiorare", "get worse = diventare peggio. È il contrario di get better."],
      ["home", "arrivare a casa", "Con un luogo get non vuol dire ottenere ma arrivare."],
      ["lost", "perdersi", "get lost = diventare perso. In italiano si usa un verbo riflessivo."],
      ["tired", "stancarsi", "get + aggettivo indica il passaggio da uno stato all'altro: be tired è invece essere stanco."],
      ["a ticket", "ricevere un biglietto", "Con un oggetto get torna a voler dire ricevere, ottenere."],
      ["a message", "ricevere un messaggio", "Chi lo manda usa invece send a message."],
      ["on the bus", "salire sull'autobus", "get on = salire su un mezzo. La particella cambia tutto."],
      ["off the train", "scendere dal treno", "get off = scendere da un mezzo, il contrario di get on."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "have",
    level: 2,
    objects: [
      ["breakfast", "fare colazione", "L'inglese il pasto lo «ha», l'italiano lo «fa». Cucinarla è invece make breakfast."],
      ["lunch", "pranzare", "In italiano basta un verbo solo."],
      ["dinner", "cenare", "Come per lunch, l'italiano ha un verbo apposta."],
      ["a rest", "riposarsi", "L'inglese «ha» un riposo, l'italiano usa un verbo riflessivo."],
      ["a problem", "avere un problema", "Qui i due verbi coincidono davvero."],
      ["a headache", "avere mal di testa", "Attenzione all'articolo: in inglese ci vuole a, in italiano no."],
      ["a cold", "avere il raffreddore", "Da non confondere con catch a cold, che vuol dire prenderlo."],
      ["fun", "divertirsi", "«Avere divertimento» non si dice: l'italiano usa un verbo riflessivo."],
      ["a meeting", "fare una riunione", "L'inglese la riunione la «ha», l'italiano la «fa»."],
      ["a lesson", "avere lezione", "In italiano l'articolo di solito cade: avere lezione, non avere una lezione."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "look",
    level: 3,
    objects: [
      ["at the screen", "guardare lo schermo", "look at = guardare, posare lo sguardo. Senza la particella at, look da solo vuol dire sembrare."],
      ["for the key", "cercare la chiave", "Cambia la particella e cambia il verbo: look at è guardare, look for è cercare."],
      ["after a child", "prendersi cura di un bambino", "look after = badare a qualcuno. Non ha niente a che vedere con il guardare."],
      ["like a problem", "sembrare un problema", "look like = sembrare, assomigliare a."],
      ["tired", "sembrare stanco", "look + aggettivo vuol dire sembrare: chi guarda è un altro."],
      ["carefully", "guardare con attenzione", "look + avverbio resta il guardare."],
      ["around the room", "guardarsi intorno nella stanza", "look around = guardarsi intorno, dare un'occhiata in giro."],
      ["up the word", "cercare la parola sul dizionario", "look up = cercare un'informazione in un dizionario o in un elenco. Il significato non si ricava né da look né da up."],
      ["through the window", "guardare attraverso la finestra", "look through = guardare attraverso qualcosa di trasparente."],
      ["forward to the trip", "non vedere l'ora del viaggio", "look forward to = non vedere l'ora di. È l'esempio più netto: nessuna delle tre parole, da sola, porta a questo significato."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "feel",
    level: 3,
    objects: [
      ["happy", "sentirsi felice", "feel + aggettivo = sentirsi in un certo modo."],
      ["sad", "sentirsi triste"],
      ["ill", "sentirsi male", "feel ill = sentirsi male, non stare bene."],
      ["better", "sentirsi meglio", "feel better è come ci si sente; get better è guarire davvero."],
      ["worse", "sentirsi peggio"],
      ["tired", "sentirsi stanco", "feel tired è come ci si sente; look tired è come si appare agli altri."],
      ["nervous", "sentirsi nervoso"],
      ["safe", "sentirsi al sicuro"],
      ["proud", "sentirsi orgoglioso"],
      ["alone", "sentirsi solo", "alone è «da solo»; lonely è «solo e triste»."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "keep",
    level: 3,
    objects: [
      ["calm", "mantenere la calma", "keep + aggettivo vuol dire restare o mantenersi in uno stato."],
      ["quiet", "fare silenzio", "keep quiet = restare in silenzio, non parlare."],
      ["safe", "stare al sicuro", "keep safe = restare al riparo."],
      ["clean", "tenere pulito", "cioè fare in modo che resti pulito."],
      ["the receipt", "conservare lo scontrino", "Con un oggetto keep vuol dire conservare, non buttare via."],
      ["a promise", "mantenere una promessa", "Il contrario è break a promise, romperla."],
      ["in touch", "restare in contatto", "keep in touch = sentirsi ancora. Si dice salutandosi."],
      ["working", "continuare a lavorare", "keep + verbo in -ing vuol dire continuare a fare qualcosa."],
      ["the door closed", "tenere la porta chiusa", "keep something closed = fare in modo che resti chiuso."],
      ["the window open", "tenere la finestra aperta", "È il contrario di keep the door closed."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "turn",
    level: 3,
    objects: [
      ["left", "girare a sinistra", "Nelle indicazioni stradali turn vuol dire girare, svoltare."],
      ["right", "girare a destra"],
      ["on the light", "accendere la luce", "turn on = accendere. Con un apparecchio turn non ha niente a che vedere con il girare."],
      ["off the phone", "spegnere il telefono", "turn off = spegnere, il contrario di turn on."],
      ["up the volume", "alzare il volume", "turn up = alzare, aumentare. Vale per volume, riscaldamento, musica."],
      ["down the volume", "abbassare il volume", "turn down = abbassare, il contrario di turn up."],
      ["around", "girarsi", "turn around = voltarsi dalla parte opposta."],
      ["into a problem", "trasformarsi in un problema", "turn into = trasformarsi in, diventare un'altra cosa."],
      ["green", "diventare verde", "turn + colore vuol dire diventare di quel colore: il semaforo, le foglie."],
      ["red", "diventare rosso", "Parlando di una persona vuol dire arrossire."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "put",
    level: 3,
    objects: [
      ["on a jacket", "mettersi la giacca", "put on = mettersi addosso un capo di vestiario."],
      ["away the books", "mettere via i libri", "put away = rimettere a posto."],
      ["down the bag", "posare la borsa", "put down = posare, appoggiare."],
      ["the key in the drawer", "mettere la chiave nel cassetto"],
      ["the file in the folder", "mettere il file nella cartella"],
      ["the plate on the table", "mettere il piatto sul tavolo"],
      ["pressure on someone", "mettere pressione a qualcuno", "put pressure on = insistere perché qualcuno faccia qualcosa."],
      ["the rubbish outside", "portare fuori la spazzatura", "rubbish è britannico; in inglese americano si dice garbage o trash."],
      ["a note on the desk", "mettere un biglietto sul banco", "Qui note è un biglietto scritto, non una nota musicale."],
      ["the phone on silent", "mettere il telefono in silenzioso"],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "give",
    level: 3,
    objects: [
      ["advice", "dare un consiglio", "advice in inglese è sempre singolare: «advices» non esiste."],
      ["an answer", "dare una risposta"],
      ["a reason", "dare una motivazione"],
      ["a warning", "dare un avvertimento"],
      ["permission", "dare il permesso"],
      ["feedback", "dare un riscontro", "feedback si usa anche in italiano, ma «riscontro» è l'equivalente."],
      ["help", "dare aiuto", "Chi lo chiede dice ask for help."],
      ["information", "dare informazioni", "information in inglese è singolare: «informations» non esiste."],
      ["a chance", "dare una possibilità"],
      ["a presentation", "fare una presentazione", "give a presentation = fare una presentazione: qui give non è dare."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "ask",
    level: 3,
    objects: [
      ["a question", "fare una domanda", "ask a question = fare una domanda. «Chiedere una domanda» non si dice in italiano."],
      ["for help", "chiedere aiuto", "ask for = chiedere qualcosa; senza for si chiede a qualcuno."],
      ["for directions", "chiedere indicazioni"],
      ["for permission", "chiedere il permesso"],
      ["about the homework", "chiedere informazioni sui compiti", "ask about = chiedere notizie di qualcosa."],
      ["the teacher", "chiedere all'insegnante", "Senza preposizione, ask + persona vuol dire chiedere a quella persona."],
      ["for the price", "chiedere il prezzo"],
      ["for a receipt", "chiedere lo scontrino"],
      ["for advice", "chiedere un consiglio"],
      ["someone to wait", "chiedere a qualcuno di aspettare", "ask someone to + verbo = chiedere a qualcuno di fare qualcosa."],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "send",
    level: 3,
    objects: [
      ["an email", "inviare una email"],
      ["a message", "inviare un messaggio", "Chi lo riceve dice get a message."],
      ["a photo", "inviare una foto", "Scattarla è invece take a photo."],
      ["the file", "inviare il file"],
      ["a warning", "inviare un avvertimento"],
      ["the report", "inviare la relazione", "Qui report è il sostantivo: una relazione scritta."],
      ["a reply", "inviare una risposta", "reply è la risposta a un messaggio; answer è la risposta a una domanda."],
      ["the homework", "inviare i compiti"],
      ["a link", "inviare un link"],
      ["the address", "inviare l'indirizzo"],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "pay",
    level: 3,
    objects: [
      ["by card", "pagare con la carta", "by + mezzo di pagamento: by card, by phone."],
      ["in cash", "pagare in contanti", "Qui la preposizione cambia: non by cash ma in cash."],
      ["the bill", "pagare il conto", "bill è il conto al ristorante; in inglese americano si dice check."],
      ["for the ticket", "pagare il biglietto", "pay for = pagare per qualcosa che si riceve in cambio."],
      ["attention", "fare attenzione", "pay attention = fare attenzione. Qui pay non ha niente a che vedere con il pagare."],
      ["the price", "pagare il prezzo"],
      ["online", "pagare online"],
      ["at the desk", "pagare allo sportello"],
      ["less", "pagare meno"],
      ["more", "pagare di più"],
    ],
  },
  {
    category: "everyday-phrases",
    verb: "catch",
    level: 4,
    objects: [
      ["the bus", "fare in tempo a prendere l'autobus", "catch a bus non è solo prenderlo: è riuscirci prima che parta. Senza fretta si dice take a bus."],
      ["the train", "fare in tempo a prendere il treno", "Chi invece lo perde dice miss the train."],
      ["a cold", "prendere il raffreddore", "catch a cold = ammalarsi. Chi ce l'ha già dice have a cold."],
      ["the ball", "afferrare la palla", "Qui catch è il verbo concreto: afferrare al volo qualcosa che si muove."],
      ["a mistake", "notare un errore", "catch a mistake = accorgersene prima che faccia danni."],
      ["the meaning", "afferrare il significato", "Qui l'italiano usa «afferrare» proprio come l'inglese."],
      ["the thief", "catturare il ladro", "catch the thief = acciuffarlo."],
      ["someone's attention", "attirare l'attenzione di qualcuno", "catch someone's attention = farsi notare."],
      ["the next flight", "riuscire a prendere il volo successivo", "Come catch the bus: c'è dentro l'idea di arrivare in tempo."],
      ["up with the class", "mettersi in pari con la classe", "catch up with = recuperare il ritardo rispetto a qualcuno."],
    ],
  },
] as const;

const phraseRows = phraseGroups.flatMap((group) =>
  group.objects.map(([object, meaning, note]) => ({
    category: group.category,
    item: [
      `${group.verb} ${object}`,
      meaning,
      "phrase",
      group.level,
      note,
    ] as const,
  })),
);

// RIMOSSO il 5 agosto 2026: ottanta voci generate a macchina, «page 1» … «page
// 80» con il significato «pagina 1» … «pagina 80».
//
// Erano riempitivo. «Cosa significa in italiano *page 47*?» non insegna niente
// a nessuno: chi sa che «page» è «pagina» sa già tutte e ottanta le voci, e chi
// non lo sa non impara il numero. Facevano volume — quaranta item, un terzo
// dell'argomento `school-communication` — e il volume conta negli audit di
// densità, che così misuravano una profondità che non c'era.
//
// Tolti restano 73 item su quell'argomento, molto sopra la soglia di quindici.

const expandedVocabularyRows = [...vocabularyRows, ...everydayVocabularyRows, ...phraseRows] as const;

export const englishVocabularyEntries: EnglishVocabularyEntry[] = expandedVocabularyRows.map(({ category, item }, index) => {
  const [term, meaning, wordClass, level, note] = item;
  return {
    id: `${category}-${index}-${term.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}`,
    term,
    meaning,
    category,
    wordClass,
    level,
    ...(note ? { note } : {}),
  };
});

export const englishVocabularyCategoryLabels: Record<EnglishVocabularyCategory, string> = {
  actions: "azioni e procedure",
  objects: "oggetti e strumenti",
  safety: "sicurezza",
  "data-science": "dati e scienze",
  "school-communication": "scuola e comunicazione",
  connectors: "connettivi e logica",
  "false-friends": "falsi amici",
  "home-family": "casa e famiglia",
  "food-shopping": "cibo e acquisti",
  "time-weather": "tempo e meteo",
  "travel-places": "viaggi e luoghi",
  "body-health": "corpo e salute",
  "feelings-opinions": "emozioni e opinioni",
  "digital-media": "digitale e media",
  "jobs-community": "lavoro e comunità",
  "leisure-culture": "tempo libero e cultura",
  "nature-environment": "natura e ambiente",
  "everyday-phrases": "frasi quotidiane",
};

export const englishVocabularyByMaxLevel = (level: number): EnglishVocabularyEntry[] =>
  englishVocabularyEntries.filter((entry) => entry.level <= level);
