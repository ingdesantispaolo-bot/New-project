class_name MinigameManager
extends RefCounted

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")
const ItalianMinigameCatalog = preload("res://scripts/game/italian_minigame_catalog.gd")
const SubjectSignatureGenerators = preload("res://scripts/game/subject_signature_generators.gd")

## Costruisce sessioni-MINIGIOCO risolte con le competenze delle materie. Due
## formati interattivi (resi da ExercisePlayer): "matching" (abbina le coppie) e
## "ordering" (metti in ordine). Riusa il contratto di sessione di ContentManager
## (nodi con topic/difficoltà) così mastery per-topic, energia e ripasso mirato
## restano identici. I contenuti sono curati per correttezza; l'ordinamento
## numerico è generato e tarato sul livello.

# Coppie da abbinare, per materia → gruppi tematici (topic + lista [sinistra, destra]).
const MATCHING := {
	"inglese": [
		# L10. Il passato irregolare è il primo scoglio vero dell'inglese: non c'è
		# regola, si impara verbo per verbo. Ventotto coppie a risposta unica.
		{"explanation": "I verbi irregolari non seguono la regola del -ed: ognuno cambia a modo suo e si impara uno per uno. Questi sono fra i più usati, ed è per questo che l'inglese non li ha mai regolarizzati.", "topic": "irregular-past", "minLevel": 10, "kind": "pool", "pool": [
			["go", "went"], ["see", "saw"], ["take", "took"], ["come", "came"],
			["give", "gave"], ["make", "made"], ["know", "knew"], ["think", "thought"],
			["find", "found"], ["tell", "told"], ["leave", "left"], ["feel", "felt"],
			["bring", "brought"], ["begin", "began"], ["keep", "kept"], ["write", "wrote"],
			["hear", "heard"], ["meet", "met"], ["run", "ran"], ["pay", "paid"],
			["speak", "spoke"], ["grow", "grew"], ["lose", "lost"], ["fall", "fell"],
			["build", "built"], ["drink", "drank"], ["eat", "ate"], ["buy", "bought"]]},
		# L20. Comparativi: quelli regolari seguono una regola, ma good/bad/far non
		# la seguono affatto — ed è per quelli che serve un insieme.
		{"explanation": "Alcuni comparativi non si formano con -er o con more: good, bad e far cambiano parola del tutto. Sono pochissimi, e proprio per questo si imparano a memoria.", "topic": "comparatives", "minLevel": 19, "kind": "pool", "pool": [
			["good", "better"], ["bad", "worse"], ["far", "further"],
			["many", "more"], ["little", "less"], ["big", "bigger"],
			["happy", "happier"], ["easy", "easier"], ["hot", "hotter"],
			["thin", "thinner"], ["young", "younger"], ["old", "older"],
			["fast", "faster"], ["slow", "slower"], ["strong", "stronger"],
			["heavy", "heavier"], ["early", "earlier"], ["late", "later"],
			["beautiful", "more beautiful"], ["expensive", "more expensive"],
			["difficult", "more difficult"], ["important", "more important"],
			["dangerous", "more dangerous"], ["interesting", "more interesting"]]},
		# Tre insiemi di vocabolario già dal primo mondo: al livello 1 si pescano solo
		# 3 coppie, quindi la profondità di una singola specifica non basta — servono
		# più insiemi idonei fin da subito, non insiemi più grandi più tardi.
		{"explanation": "Parole di tutti i giorni: nessuna somiglia all'italiano, quindi non c'è nessuna regola da dedurre. Vanno riconosciute a memoria, e queste sono le prime che tornano utili.", "topic": "vocabolario", "pairs": [
			["dog", "cane"], ["cat", "gatto"], ["sun", "sole"], ["house", "casa"],
			["water", "acqua"], ["book", "libro"], ["tree", "albero"], ["red", "rosso"],
			["moon", "luna"], ["star", "stella"], ["bread", "pane"], ["milk", "latte"],
			["door", "porta"], ["window", "finestra"], ["chair", "sedia"], ["table", "tavolo"],
			["hand", "mano"], ["head", "testa"], ["friend", "amico"], ["school", "scuola"],
			["city", "città"], ["river", "fiume"], ["mountain", "montagna"], ["sea", "mare"],
			["bird", "uccello"], ["horse", "cavallo"], ["flower", "fiore"], ["key", "chiave"],
			["road", "strada"], ["cloud", "nuvola"], ["snow", "neve"], ["fire", "fuoco"]]},
		{"explanation": "I numeri da uno a dieci. Tornano in date, ore, prezzi e in quasi ogni conversazione: sono le parole che si riusano di più in assoluto.", "topic": "vocabolario", "pairs": [
			["one", "uno"], ["two", "due"], ["three", "tre"], ["four", "quattro"],
			["five", "cinque"], ["six", "sei"], ["seven", "sette"], ["eight", "otto"],
			["nine", "nove"], ["ten", "dieci"], ["eleven", "undici"], ["twelve", "dodici"],
			["thirteen", "tredici"], ["fifteen", "quindici"], ["twenty", "venti"], ["thirty", "trenta"],
			["forty", "quaranta"], ["fifty", "cinquanta"], ["hundred", "cento"], ["thousand", "mille"]]},
		# Verbi di uso quotidiano: il terzo insieme disponibile dal mondo 1.
		{"explanation": "Verbi di azione quotidiana. In inglese l'infinito si riconosce dal «to» davanti: to run, to eat, to drink.", "topic": "vocabolario", "pairs": [
			["to run", "correre"], ["to eat", "mangiare"], ["to drink", "bere"], ["to sleep", "dormire"],
			["to read", "leggere"], ["to write", "scrivere"], ["to play", "giocare"], ["to sing", "cantare"],
			["to walk", "camminare"], ["to swim", "nuotare"], ["to laugh", "ridere"], ["to cry", "piangere"],
			["to open", "aprire"], ["to close", "chiudere"], ["to buy", "comprare"], ["to help", "aiutare"],
			["to listen", "ascoltare"], ["to look", "guardare"], ["to speak", "parlare"], ["to learn", "imparare"],
			["to teach", "insegnare"], ["to build", "costruire"], ["to find", "trovare"], ["to lose", "perdere"],
			["to give", "dare"], ["to take", "prendere"], ["to bring", "portare"], ["to answer", "rispondere"],
			["to ask", "chiedere"], ["to wait", "aspettare"]]},
		{"explanation": "Gli opposti conviene impararli in coppia: ricordarne uno tira su anche l'altro, e dimezza la fatica.", "topic": "opposites", "minLevel": 1, "pairs": [
			["hot", "cold"], ["big", "small"], ["fast", "slow"], ["happy", "sad"],
			["old", "new"], ["long", "short"], ["high", "low"], ["light", "heavy"],
			["full", "empty"], ["open", "shut"], ["clean", "dirty"], ["easy", "hard"],
			["strong", "weak"], ["rich", "poor"], ["near", "far"], ["young", "elderly"],
			["loud", "quiet"], ["wet", "dry"], ["early", "late"], ["first", "last"],
			["day", "night"], ["summer", "winter"], ["inside", "outside"], ["above", "below"],
			["always", "never"], ["everything", "nothing"]]},
		# Conversazione: micro-scambi domanda -> risposta.
		{"explanation": "Micro-scambi domanda-risposta. La risposta riusa le parole della domanda: è il trucco che permette di rispondere anche quando non si è capito tutto.", "topic": "conversation", "minLevel": 4, "pairs": [
			["What's your name?", "I'm Anna"], ["How old are you?", "I'm ten"],
			["Where are you from?", "From Italy"], ["How are you?", "I'm fine, thanks"],
			["What time is it?", "It's half past four"], ["Where do you live?", "In a small town"],
			["Have you got a pet?", "Yes, a grey cat"], ["What's your favourite subject?", "History"],
			["Can you help me?", "Of course I can"], ["What are you doing?", "I'm reading"],
			["Do you like pizza?", "Yes, I love it"], ["When is your birthday?", "In March"],
			["How much is it?", "Three euros"], ["What's the weather like?", "It's raining"],
			["Would you like some tea?", "No, thank you"], ["See you tomorrow!", "See you!"],
			["How do you go to school?", "By bus"], ["Whose book is this?", "It's mine"]]},
		# Scuola media — le forme che l'inglese non regolarizza.
		{"explanation": "Le contrazioni uniscono due parole togliendone una parte, e l'apostrofo segna il posto di quello che manca.", "topic": "contractions", "minLevel": 4, "pairs": [
			["I am", "I'm"], ["you are", "you're"], ["do not", "don't"], ["cannot", "can't"],
			["it is", "it's"], ["she is", "she's"], ["they are", "they're"], ["we are", "we're"],
			["does not", "doesn't"], ["did not", "didn't"], ["is not", "isn't"], ["are not", "aren't"],
			["was not", "wasn't"], ["were not", "weren't"], ["will not", "won't"], ["would not", "wouldn't"],
			["has not", "hasn't"], ["have not", "haven't"], ["I will", "I'll"], ["I have", "I've"]]},
		{"explanation": "Passati irregolari: la forma non si costruisce, si ricorda. Sono i verbi usati più spesso, e le lingue non regolarizzano mai quello che si dice tutti i giorni.", "topic": "irregular-past", "minLevel": 7, "pairs": [
			["go", "went"], ["eat", "ate"], ["see", "saw"], ["have", "had"], ["make", "made"],
			["take", "took"], ["give", "gave"], ["come", "came"], ["write", "wrote"], ["read", "read /red/"],
			["run", "ran"], ["swim", "swam"], ["sing", "sang"], ["drink", "drank"], ["begin", "began"],
			["buy", "bought"], ["bring", "brought"], ["think", "thought"], ["teach", "taught"], ["catch", "caught"],
			["find", "found"], ["lose", "lost"], ["sleep", "slept"], ["keep", "kept"], ["leave", "left"],
			["speak", "spoke"], ["break", "broke"], ["choose", "chose"]]},
		{"explanation": "Plurali che non prendono la -s: sono resti di forme antiche, sopravvissuti perché sono parole usatissime.", "topic": "irregular-plural", "minLevel": 7, "pairs": [
			["child", "children"], ["man", "men"], ["foot", "feet"], ["mouse", "mice"],
			["tooth", "teeth"], ["woman", "women"], ["goose", "geese"], ["person", "people"],
			["knife", "knives"], ["leaf", "leaves"], ["wife", "wives"], ["shelf", "shelves"],
			["life", "lives"], ["city", "cities"], ["baby", "babies"], ["sheep", "sheep (invariato)"],
			["fish", "fish (invariato)"], ["potato", "potatoes"]]},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "Nelle domande di tutti i giorni la risposta ricalca la domanda: «How old...?» chiede un'età e la risposta comincia con «I'm». Impararle a coppie è più veloce che impararle una per volta.", "topic": "everyday-phrases", "pairs": [
			["What's your name?", "My name is Anna."], ["How old are you?", "I'm eleven."],
			["Where are you from?", "I'm from Italy."], ["How are you?", "I'm fine, thanks."],
			["What time is it?", "It's half past three."], ["Can I help you?", "Yes, please."],
			["What's the weather like?", "It's sunny."], ["How much is it?", "Five euros."],
			["Where do you live?", "In a small town."], ["What's your favourite subject?", "Science."]]},
		# --- Il soffitto dei mondi alti (8 settembre 2026) --------------------
		#
		# Misurato con `inglese_livelli_probe`: dal livello 13 in poi l'inglese
		# non guadagnava più una sola ricetta, e il minLevel più alto era 20.
		# Undici mondi su ventiquattro ripetevano quello che il mondo 13 aveva
		# già mostrato. Queste ricette coprono i livelli 14-23 con il programma
		# del biennio, gli stessi argomenti dei 470 item nuovi di banco.
		{"explanation": "Il phrasal verb non è la somma dei due pezzi: «give up» non è «dare su», è arrendersi. Si impara intero, come una parola sola, ed è per questo che sta in un insieme di coppie.", "topic": "phrasal-verbs", "minLevel": 13, "kind": "pool", "pool": [
			["give up", "arrendersi"], ["look after", "prendersi cura di"], ["look for", "cercare"],
			["find out", "scoprire"], ["put off", "rimandare"], ["turn on", "accendere"],
			["turn off", "spegnere"], ["get up", "alzarsi"], ["take off", "decollare"],
			["run out of", "rimanere senza"], ["take after", "assomigliare a"], ["get on with", "andare d'accordo"],
			["look forward to", "aspettare con piacere"], ["give back", "restituire"], ["carry on", "continuare"],
			["break down", "guastarsi"], ["grow up", "crescere"], ["put on", "indossare"],
			["throw away", "buttare via"], ["work out", "allenarsi"], ["call off", "annullare"],
			["set off", "mettersi in viaggio"], ["make up", "inventare"], ["come across", "imbattersi in"]]},
		{"explanation": "Ogni tempo verbale è una formula di montaggio, e riconoscerla vale più che ricordarne il nome: chi sa quali pezzi servono può costruirlo anche con un verbo mai visto.", "topic": "present-perfect", "minLevel": 16, "kind": "pool", "pool": [
			["present perfect", "have/has + participio"], ["past perfect", "had + participio"],
			["present continuous", "am/is/are + verbo-ing"], ["past continuous", "was/were + verbo-ing"],
			["future with will", "will + verbo nudo"], ["future with going to", "am/is/are going to + verbo"],
			["passive present", "am/is/are + participio"], ["passive past", "was/were + participio"],
			["second conditional", "if + passato, would + verbo"], ["third conditional", "if + had done, would have done"],
			["causative", "have + oggetto + participio"], ["present simple", "verbo nudo, -s alla terza"]]},
		{"explanation": "I connettivi non decorano: dichiarano la logica del testo. Impararli con la traduzione italiana è il modo più rapido di smettere di sceglierli a orecchio.", "topic": "linkers", "minLevel": 16, "kind": "pool", "pool": [
			["although", "anche se"], ["however", "tuttavia"], ["despite", "nonostante"],
			["therefore", "perciò"], ["moreover", "inoltre"], ["whereas", "mentre invece"],
			["unless", "a meno che"], ["as long as", "purché"], ["in order to", "allo scopo di"],
			["nevertheless", "ciò nonostante"], ["besides", "oltretutto"], ["thus", "in questo modo"],
			["so that", "in modo che"], ["because of", "a causa di"], ["as soon as", "non appena"],
			["in conclusion", "in conclusione"], ["on the other hand", "d'altra parte"], ["first of all", "prima di tutto"]]},
		{"explanation": "La preposizione fa parte del significato del verbo, e non si ricava traducendo: «depend on» dove l'italiano direbbe «da». Si impara la coppia intera.", "topic": "prepositions", "minLevel": 19, "kind": "pool", "pool": [
			["depend on", "dipendere da"], ["interested in", "interessato a"], ["good at", "bravo in"],
			["afraid of", "spaventato da"], ["famous for", "famoso per"], ["similar to", "simile a"],
			["listen to", "ascoltare"], ["wait for", "aspettare"], ["belong to", "appartenere a"],
			["based on", "basato su"], ["worried about", "preoccupato per"], ["proud of", "orgoglioso di"],
			["married to", "sposato con"], ["full of", "pieno di"], ["angry with", "arrabbiato con"],
			["succeed in", "riuscire in"], ["apologise for", "scusarsi per"], ["rely on", "contare su"]]},
		{"explanation": "Una radice, molte parole: il suffisso dice il mestiere grammaticale prima ancora del significato. Riconoscerlo permette di capire una parola mai vista senza cercarla.", "topic": "word-family", "minLevel": 22, "kind": "pool", "pool": [
			["happy", "happiness"], ["decide", "decision"], ["arrive", "arrival"],
			["teach", "teacher"], ["danger", "dangerous"], ["care", "careless"],
			["use", "useful"], ["child", "childhood"], ["friend", "friendship"],
			["king", "kingdom"], ["free", "freedom"], ["punish", "punishment"],
			["agree", "agreement"], ["possible", "impossible"], ["legal", "illegal"],
			["regular", "irregular"], ["understand", "misunderstand"], ["read", "readable"],
			["strong", "strength"], ["long", "length"], ["honest", "dishonest"], ["appear", "disappear"]]},
		# --- La grammatica delle prime fasce (9 settembre 2026) ---------------
		#
		# Il mondo 4 e' l'UNICO mondo d'inglese sotto la fascia 5, e sta al PRIMO
		# dei tre livelli della sua fascia: una ricetta con `minLevel` a meta'
		# fascia non la incontra mai. Da qui in poi ogni gate d'inglese sta
		# all'inizio della fascia (1, 4, 7, 10, 13, 16, 19, 22), e la grammatica
		# del banco ha una forma da toccare, non solo da crocettare.
		{"explanation": "Dove l'italiano possiede uno stato, l'inglese lo E': non ha fame, e' affamato. E' la differenza che fa sbagliare piu' spesso chi traduce a mente, e si sente subito perche' cambia il verbo, non la parola.", "topic": "to-be", "minLevel": 1, "pairs": [
			["Ho fame", "I am hungry"], ["Ho sete", "I am thirsty"],
			["Ho freddo", "I am cold"], ["Ho caldo", "I am hot"],
			["Ho paura", "I am afraid"], ["Ho ragione", "I am right"],
			["Ho torto", "I am wrong"], ["Ho dieci anni", "I am ten"],
			["Ho fretta", "I am in a hurry"], ["Ho sonno", "I am sleepy"]]},
		{"explanation": "Ogni persona ha il suo possessivo, e non cambia mai con la cosa posseduta: «my» vale per un libro e per venti libri. E' il contrario dell'italiano, dove il possessivo si accorda con quello che si possiede.", "topic": "pronouns", "minLevel": 1, "pairs": [
			["I", "my"], ["you", "your"], ["he", "his"], ["she", "her"],
			["it", "its"], ["we", "our"], ["they", "their"]]},
		{"explanation": "Il possessivo ha due forme: una sta davanti al nome, l'altra sta da sola al posto suo. «My book» ha bisogno del libro, «mine» il libro lo contiene gia'. L'unico che non cambia e' «his», uguale nelle due caselle.", "topic": "possessives", "minLevel": 7, "pairs": [
			["my", "mine"], ["your", "yours"], ["her", "hers"],
			["our", "ours"], ["their", "theirs"]]},
		{"explanation": "I modali non dicono un'azione: dicono con che forza la si afferma. Sono pochi, non prendono la -s alla terza persona e reggono l'infinito senza «to» — tre eccezioni che valgono per tutti quanti insieme.", "topic": "modals", "minLevel": 7, "pairs": [
			["can", "capacita: ne sono capace"], ["must", "obbligo che mi do da solo"],
			["have to", "obbligo che arriva da fuori"], ["may", "permesso chiesto con garbo"],
			["should", "consiglio: faresti bene"], ["might", "possibilita incerta"],
			["cannot", "divieto: non si puo"], ["would like", "desiderio detto con cortesia"]]},
		{"explanation": "L'inglese ha quattro modi di parlare del futuro e non sono intercambiabili: cambia CHI ha deciso e QUANDO. La forma giusta si sceglie dal momento della decisione, non dalla distanza nel tempo.", "topic": "future", "minLevel": 13, "pairs": [
			["will", "decisione presa proprio adesso"],
			["going to", "intenzione decisa gia prima"],
			["present continuous", "appuntamento gia fissato in agenda"],
			["present simple", "orario fisso di treni, scuole e cinema"],
			["shall I?", "offerta di aiuto a chi ascolta"]]},
		{"explanation": "Ogni mestiere si dice con due informazioni: che cosa fa e dove lo fa. Tenerle in coppia serve a parlare di se' e degli altri, ed e' il primo modo per capire una domanda che non si era capita: se si riconosce il luogo, si indovina il mestiere.", "topic": "jobs-community", "minLevel": 13, "pairs": [
			["nurse", "works in a hospital"], ["teacher", "works in a school"],
			["baker", "works in a bakery"], ["farmer", "works on a farm"],
			["mechanic", "works in a garage"], ["chef", "works in a kitchen"],
			["librarian", "works in a library"], ["pilot", "works on a plane"],
			["vet", "looks after animals"], ["engineer", "designs machines"],
			["journalist", "writes for a newspaper"], ["firefighter", "puts out fires"]]},
		# --- I campi del lessico, uno per uno (9 settembre 2026) --------------
		{"explanation": "Le parole della tavola e della spesa sono le prime che servono davvero fuori dall'aula. Nessuna somiglia all'italiano: si imparano a coppie, ed e' il campo in cui una parola in piu' si sente subito.", "topic": "food-shopping", "minLevel": 1, "pairs": [
			["bread", "pane"], ["cheese", "formaggio"], ["meat", "carne"], ["fish", "pesce"],
			["apple", "mela"], ["egg", "uovo"], ["butter", "burro"], ["rice", "riso"],
			["shop", "negozio"], ["price", "prezzo"], ["meal", "pasto"], ["breakfast", "colazione"],
			["spoon", "cucchiaio"], ["bottle", "bottiglia"], ["market", "mercato"], ["change", "resto"]]},
		{"explanation": "Le parti del corpo e i modi di dire che ci girano intorno servono a chiedere aiuto, ed e' il primo motivo pratico per cui una lingua si impara. In inglese quasi tutte sono parole corte e antiche: cambiano poco, e per questo si ricordano.", "topic": "body-health", "minLevel": 1, "pairs": [
			["head", "testa"], ["hand", "mano"], ["foot", "piede"], ["eye", "occhio"],
			["mouth", "bocca"], ["heart", "cuore"], ["bone", "osso"], ["skin", "pelle"],
			["ill", "malato"], ["pain", "dolore"], ["nurse", "infermiere"], ["chemist", "farmacia"],
			["cold", "raffreddore"], ["cough", "tosse"], ["healthy", "sano"], ["rest", "riposo"]]},
		{"explanation": "Dire come si sta e' la prima cosa che si vuole poter fare in una lingua nuova, ed e' anche quella che manca piu' spesso: si conoscono le parole delle cose e non quelle degli stati d'animo. Molte finiscono in -ed quando dicono come ci si sente.", "topic": "feelings-opinions", "minLevel": 1, "pairs": [
			["happy", "felice"], ["sad", "triste"], ["angry", "arrabbiato"], ["tired", "stanco"],
			["scared", "spaventato"], ["proud", "orgoglioso"], ["bored", "annoiato"], ["surprised", "sorpreso"],
			["worried", "preoccupato"], ["excited", "entusiasta"], ["lonely", "solo"], ["calm", "tranquillo"]]},
		{"explanation": "Le parole della natura tornano in ogni testo di scienze e di geografia scritto in inglese: sono il ponte fra la lingua e le altre materie, ed e' la ragione per cui conviene impararle presto anche se sembrano meno urgenti.", "topic": "nature-environment", "minLevel": 4, "pairs": [
			["tree", "albero"], ["leaf", "foglia"], ["seed", "seme"], ["river", "fiume"],
			["field", "campo"], ["wood", "bosco"], ["sky", "cielo"], ["soil", "terreno"],
			["rubbish", "rifiuti"], ["waste", "spreco"], ["pollution", "inquinamento"], ["wildlife", "fauna selvatica"],
			["shore", "riva"], ["weather", "tempo atmosferico"]]},
		{"explanation": "Sport, musica e tempo libero sono il campo in cui l'inglese entra in italiano da solo: molte parole le usiamo gia' senza tradurle. Sapere che cosa vogliono dire davvero evita di usarle a sproposito.", "topic": "leisure-culture", "minLevel": 4, "pairs": [
			["football", "calcio"], ["basketball", "pallacanestro"], ["swimming", "nuoto"], ["running", "corsa"],
			["team", "squadra"], ["match", "partita"], ["coach", "allenatore"], ["prize", "premio"],
			["drawing", "disegno"], ["song", "canzone"], ["stage", "palcoscenico"], ["audience", "pubblico"]]},
		{"explanation": "Le parole della sicurezza sono quelle che si leggono sui cartelli, e vanno capite alla prima occhiata: non c'e' tempo per tradurle. Molte si costruiscono da una parola di base con un prefisso — safe, unsafe — e riconoscere il pezzo aggiunto vale piu' che ricordare l'intera lista.", "topic": "safety", "minLevel": 7, "pairs": [
			["safe", "sicuro"], ["danger", "pericolo"], ["warning", "avvertimento"], ["exit", "uscita"],
			["helmet", "casco"], ["rope", "corda"], ["shelter", "riparo"], ["rescue", "soccorso"],
			["forbidden", "vietato"], ["careful", "attento"], ["first aid", "pronto soccorso"], ["alarm", "allarme"]]},
		{"explanation": "Il lessico della scuola serve a capire una consegna scritta in inglese, ed e' il primo campo in cui una parola sbagliata costa un esercizio intero. Attenzione a «subject», che non e' un soggetto ma la materia.", "topic": "school-communication", "minLevel": 7, "pairs": [
			["lesson", "lezione"], ["subject", "materia"], ["homework", "compiti"], ["test", "verifica"],
			["mark", "voto"], ["timetable", "orario"], ["break", "ricreazione"], ["headmaster", "preside"],
			["notice", "avviso"], ["report", "pagella"], ["term", "quadrimestre"], ["deadline", "scadenza"]]},
		{"explanation": "Le parole del digitale arrivano in italiano gia' in inglese, e proprio per questo si crede di conoscerle: «to download» e «to upload» sono opposti, e chi li scambia manda via un file invece di prenderlo.", "topic": "digital-media", "minLevel": 13, "pairs": [
			["download", "scaricare"], ["upload", "caricare"], ["screen", "schermo"], ["keyboard", "tastiera"],
			["laptop", "portatile"], ["password", "parola d'ordine"], ["link", "collegamento"], ["file", "archivio"],
			["network", "rete"], ["browser", "navigatore"], ["account", "profilo"], ["backup", "copia di riserva"]]},
		{"explanation": "Numeri, valori e grafici si leggono in inglese in ogni materia scientifica: e' il lessico che permette di capire un grafico senza sapere l'argomento. Sono parole corte e sempre le stesse, e rendono piu' di qualunque altra lista.", "topic": "data-science", "minLevel": 13, "pairs": [
			["number", "numero"], ["value", "valore"], ["amount", "quantita"], ["average", "media"],
			["chart", "grafico"], ["table", "tabella"], ["row", "riga"], ["column", "colonna"],
			["increase", "aumento"], ["decrease", "diminuzione"], ["survey", "indagine"], ["result", "risultato"]]},
	],
	"geografia": [
		# Fasce 5-8, scritte il 9 settembre 2026. Non capitali: quelle stanno gia'
		# al primo mondo e sono nomi da ricordare. Qui si abbina un fenomeno alla
		# sua causa o al suo effetto, che e' un legame da ragionare.
		{"explanation": "Ogni grande fiume ha costruito attorno a se' una civilta': dove l'acqua arriva regolare si coltiva, e dove si coltiva nascono citta'. La geografia non spiega tutta la storia, ma spiega dove poteva cominciare.", "topic": "geografia-fisica", "minLevel": 14, "pairs": [
			["Nilo", "Egitto"],
			["Tigri ed Eufrate", "Mesopotamia"],
			["Indo", "Pakistan"],
			["Fiume Giallo", "Cina"],
			["Gange", "India"],
			["Danubio", "Europa centrale"],
			["Rio delle Amazzoni", "Brasile"],
			["Mississippi", "Stati Uniti"]]},
		{"explanation": "Il nome di un mare o di uno stretto dice spesso chi ci passava e perche': i punti stretti valgono piu' di intere coste, perche' chi li controlla controlla il passaggio di tutti gli altri.", "topic": "mondo", "minLevel": 17, "pairs": [
			["Stretto di Gibilterra", "Ingresso del Mediterraneo"],
			["Canale di Suez", "Scorciatoia verso l'oceano Indiano"],
			["Canale di Panama", "Collega i due oceani americani"],
			["Stretto di Bering", "Separa Asia e America"],
			["Stretto di Messina", "Divide la Sicilia dal continente"],
			["Bosforo", "Divide Europa e Asia a Istanbul"],
			["Stretto di Malacca", "Passaggio piu' trafficato dell'Asia"]]},
		{"explanation": "Un ambiente si riconosce dalla combinazione di clima e vegetazione, non da uno dei due: la savana e la steppa hanno entrambe erba e pochi alberi, ma piogge diversissime.", "topic": "climi", "minLevel": 20, "pairs": [
			["Tundra", "Muschi su terreno gelato"],
			["Taiga", "Foresta di conifere"],
			["Savana", "Erba alta e alberi radi"],
			["Steppa", "Praterie senza alberi"],
			["Macchia mediterranea", "Arbusti resistenti alla siccita'"],
			["Foresta pluviale", "Piogge quotidiane e alberi altissimi"],
			["Deserto", "Vegetazione rada e sparsa"]]},
		{"explanation": "Le risorse spiegano molte scelte politiche ed economiche: sapere dove sta una materia prima aiuta a capire perche' certe rotte, certi porti e certi conflitti esistono.", "topic": "geografia-umana", "minLevel": 23, "pairs": [
			["Petrolio", "Golfo Persico"],
			["Cacao", "Africa occidentale"],
			["Caffe'", "Brasile"],
			["Riso", "Sud-est asiatico"],
			["Rame", "Cile"],
			["Diamanti", "Africa australe"],
			["Legname tropicale", "Bacino amazzonico"],
			["Gas naturale", "Siberia"]]},
		# L12. Le capitali europee si incontrano al primo mondo; queste sono quelle
		# del resto del mondo, che è materia di seconda media.
		{"explanation": "La capitale è la città dove sta il governo, non per forza la più grande: Brasilia è stata costruita apposta, lontano dalla costa affollata.", "topic": "capitali", "minLevel": 12, "kind": "pool", "pool": [
			["Giappone", "Tokyo"], ["Egitto", "Il Cairo"], ["Brasile", "Brasilia"],
			["Canada", "Ottawa"], ["Australia", "Canberra"], ["India", "Nuova Delhi"],
			["Cina", "Pechino"], ["Russia", "Mosca"], ["Messico", "Città del Messico"],
			["Argentina", "Buenos Aires"], ["Ghana", "Accra"], ["Turchia", "Ankara"],
			["Marocco", "Rabat"], ["Kenya", "Nairobi"], ["Perù", "Lima"],
			["Cile", "Santiago"], ["Thailandia", "Bangkok"], ["Vietnam", "Hanoi"],
			["Corea del Sud", "Seul"], ["Indonesia", "Giacarta"], ["Iran", "Teheran"],
			["Pakistan", "Islamabad"], ["Nigeria", "Abuja"], ["Etiopia", "Addis Abeba"],
			["Cuba", "L'Avana"], ["Colombia", "Bogotà"], ["Nuova Zelanda", "Wellington"],
			["Arabia Saudita", "Riad"]]},
		{"explanation": "Capitali europee. Quasi tutte sorgono su un fiume o vicino al mare: le città nascono dove si può arrivare e commerciare.", "topic": "capitali", "pairs": [
			["Italia", "Roma"], ["Francia", "Parigi"], ["Spagna", "Madrid"], ["Germania", "Berlino"],
			["Portogallo", "Lisbona"], ["Grecia", "Atene"], ["Austria", "Vienna"], ["Belgio", "Bruxelles"],
			["Paesi Bassi", "Amsterdam"], ["Danimarca", "Copenaghen"], ["Svezia", "Stoccolma"], ["Norvegia", "Oslo"],
			["Finlandia", "Helsinki"], ["Polonia", "Varsavia"], ["Ungheria", "Budapest"], ["Irlanda", "Dublino"],
			["Svizzera", "Berna"], ["Croazia", "Zagabria"], ["Regno Unito", "Londra"], ["Repubblica Ceca", "Praga"],
			["Egitto", "Il Cairo"], ["Marocco", "Rabat"], ["Kenya", "Nairobi"], ["Giappone", "Tokyo"],
			["Cina", "Pechino"], ["India", "Nuova Delhi"], ["Brasile", "Brasilia"], ["Argentina", "Buenos Aires"],
			["Messico", "Città del Messico"], ["Canada", "Ottawa"], ["Australia", "Canberra"], ["Perù", "Lima"]]},
		{"explanation": "Un Paese sta nel continente su cui poggia la sua terra. L'Egitto è in Africa anche se una piccola parte sta oltre il canale di Suez.", "topic": "continenti", "pairs": [["Egitto", "Africa"], ["Brasile", "America del Sud"], ["Giappone", "Asia"], ["Italia", "Europa"], ["Australia", "Oceania"]]},
		{"explanation": "Ogni monumento dice chi l'ha costruito: riconoscerlo significa riconoscere un popolo e un'epoca, non solo un edificio.", "topic": "monumenti", "minLevel": 3, "pairs": [
			["Colosseo", "Italia"], ["Tour Eiffel", "Francia"], ["Piramidi di Giza", "Egitto"],
			["Statua della Libertà", "Stati Uniti"], ["Big Ben", "Regno Unito"], ["Sagrada Família", "Spagna"],
			["Partenone", "Grecia"], ["Muraglia cinese", "Cina"], ["Taj Mahal", "India"],
			["Cristo Redentore", "Brasile"], ["Machu Picchu", "Perù"], ["Monte Fuji", "Giappone"],
			["Opera House", "Australia"], ["Petra", "Giordania"], ["Stonehenge", "Inghilterra"],
			["Mulini di Kinderdijk", "Paesi Bassi"], ["Castello di Neuschwanstein", "Germania"], ["Cattedrale di San Basilio", "Russia"],
			["Chichén Itzá", "Messico"], ["Angkor Wat", "Cambogia"], ["Torre di Pisa", "Italia"],
			["Fiordi di Geiranger", "Norvegia"], ["Cascate Vittoria", "Zambia"], ["Colosso di Rodi (rovine)", "Grecia"]]},
		# Scuola media — monete del mondo ed elementi fisici d'Italia.
		{"explanation": "Ogni Stato batte la propria moneta. L'Euro è l'eccezione: è condiviso da Paesi che hanno scelto di usarlo insieme.", "topic": "monete", "minLevel": 5, "pairs": [["Italia", "Euro"], ["Stati Uniti", "Dollaro"], ["Giappone", "Yen"], ["Regno Unito", "Sterlina"]]},
		{"explanation": "Ogni nome appartiene a un tipo di elemento — fiume, vulcano, lago. Riconoscere il tipo è il primo passo per collocarlo sulla carta.", "topic": "italia-fisica", "minLevel": 4, "pairs": [["Po", "Fiume"], ["Etna", "Vulcano"], ["Garda", "Lago"], ["Alpi", "Catena montuosa"]]},
		# --- Mondo 1: due ricette in più (tappa 2, 6 agosto 2026) ---------------
		{"explanation": "Il capoluogo è la città dove sta l'amministrazione della regione: non sempre è la più famosa, e in Italia quasi mai la più centrale.", "topic": "geografia-italia", "kind": "pool", "pool": [
			["Lombardia", "Milano"], ["Veneto", "Venezia"], ["Piemonte", "Torino"],
			["Liguria", "Genova"], ["Toscana", "Firenze"], ["Lazio", "Roma"],
			["Campania", "Napoli"], ["Sicilia", "Palermo"], ["Sardegna", "Cagliari"],
			["Puglia", "Bari"], ["Calabria", "Catanzaro"], ["Emilia-Romagna", "Bologna"],
			["Marche", "Ancona"], ["Umbria", "Perugia"], ["Abruzzo", "L'Aquila"],
			["Molise", "Campobasso"], ["Basilicata", "Potenza"], ["Friuli-Venezia Giulia", "Trieste"],
			["Trentino-Alto Adige", "Trento"], ["Valle d'Aosta", "Aosta"]]},
		{"explanation": "Le montagne non stanno da sole: appartengono a una catena, cioè a una piega della crosta terrestre lunga migliaia di chilometri.", "topic": "geografia-fisica", "pairs": [
			["Monte Bianco", "Alpi"], ["Gran Sasso", "Appennini"], ["Everest", "Himalaya"],
			["Aconcagua", "Ande"], ["Elbrus", "Caucaso"], ["Kilimangiaro", "Tanzania"],
			["Monte Fuji", "Giappone"], ["Etna", "Sicilia"], ["Vesuvio", "Campania"],
			["Teide", "Canarie"], ["Denali", "Alaska"], ["Monte Rosa", "Alpi Pennine"]]},
	],
	"scienze": [
		{"explanation": "Ogni organo ha un compito solo, e il corpo funziona proprio perché nessuno fa il lavoro di un altro.", "topic": "corpo", "pairs": [["Cuore", "Pompa il sangue"], ["Polmoni", "Respirazione"], ["Cervello", "Comanda il corpo"], ["Stomaco", "Digestione"], ["Occhi", "Vista"]]},
		{"explanation": "Il nome dipende da cosa mangia l'animale, non da quanto è grande o feroce: il panda è erbivoro, l'orso onnivoro.", "topic": "viventi", "pairs": [["Erbivoro", "Mangia piante"], ["Carnivoro", "Mangia animali"], ["Onnivoro", "Mangia tutto"], ["Decompositore", "Ricicla i resti"]]},
		{"explanation": "La classe si riconosce da pelle, respirazione e riproduzione, non dall'aspetto: la balena vive in acqua ma non è un pesce.", "topic": "classi", "minLevel": 5, "pairs": [["Rana", "Anfibio"], ["Serpente", "Rettile"], ["Aquila", "Uccello"], ["Balena", "Mammifero"], ["Trota", "Pesce"]]},
		# Scuola media — sistemi del corpo e passaggi di stato.
		{"explanation": "Ogni organo lavora dentro un sistema, e il sistema prende il nome dal lavoro che fa, non dall'organo più grande.", "topic": "sistemi", "minLevel": 6, "pairs": [["Cuore", "Sistema circolatorio"], ["Polmoni", "Sistema respiratorio"], ["Stomaco", "Sistema digerente"], ["Cervello", "Sistema nervoso"]]},
		{"explanation": "Ogni passaggio di stato ha un nome proprio e un verso preciso: fusione e solidificazione sono lo stesso confine percorso nei due sensi.", "topic": "passaggi-stato", "minLevel": 5, "pairs": [["Fusione", "solido » liquido"], ["Evaporazione", "liquido » gas"], ["Solidificazione", "liquido » solido"], ["Condensazione", "gas » liquido"]]},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Gli organi non lavorano da soli: stanno in squadre che si chiamano apparati, e ogni squadra ha un compito solo per tutto il corpo.", "topic": "corpo", "pairs": [
			["cuore", "apparato circolatorio"], ["polmoni", "apparato respiratorio"],
			["stomaco", "apparato digerente"], ["reni", "apparato escretore"],
			["cervello", "sistema nervoso"], ["ossa", "apparato scheletrico"],
			["muscoli", "apparato muscolare"], ["pelle", "rivestimento del corpo"]]},
		{"explanation": "Gli animali si raggruppano per come sono fatti, non per dove vivono: la balena vive in mare ma respira aria e allatta, quindi è un mammifero.", "topic": "viventi", "pairs": [
			["rana", "anfibio"], ["serpente", "rettile"], ["aquila", "uccello"],
			["balena", "mammifero"], ["trota", "pesce"], ["ape", "insetto"],
			["ragno", "aracnide"], ["lumaca", "mollusco"], ["granchio", "crostaceo"],
			["stella marina", "echinoderma"]]},
	],
	"latino": [
		# Fasce 4, 6 e 8, scritte il 9 settembre 2026. Nessuno di questi abbinamenti
		# si vince cercando la parola ripetuta fra le due colonne — la scorciatoia
		# dell'eco che `scorciatoie_minigiochi_audit` misura: le due colonne parlano
		# lingue diverse, e il ponte va costruito.
		{"explanation": "Ogni caso ha un mestiere solo, e il mestiere si dice con una domanda: chi?, chi o che cosa?, di chi?, a chi?, con che cosa?. Impararli come domande invece che come nomi rende inutile ricordare l'ordine.", "topic": "casi", "minLevel": 11, "pairs": [
			["Nominativo", "Chi compie l'azione"],
			["Accusativo", "Chi o che cosa la subisce"],
			["Genitivo", "Di chi e' una cosa"],
			["Dativo", "A chi e' destinata"],
			["Ablativo", "Con che cosa si fa"],
			["Vocativo", "Chi viene chiamato"]]},
		{"explanation": "Le radici latine dei verbi sono rimaste dentro parole italiane che sembrano non c'entrare: riconoscerle vuol dire non dover imparare due volte la stessa cosa.", "topic": "etimologia", "minLevel": 16, "pairs": [
			["scribere", "Scrivania"],
			["ducere", "Condurre"],
			["mittere", "Missione"],
			["videre", "Evidente"],
			["audire", "Udienza"],
			["facere", "Fabbrica"],
			["ferre", "Trasferire"],
			["capere", "Ricevere"],
			["tenere", "Contenere"],
			["ponere", "Deporre"]]},
		{"explanation": "Molte istituzioni e mestieri romani hanno lasciato la parola e cambiato il contenuto: sapere che cosa facevano davvero evita di leggere il passato con le categorie di oggi.", "topic": "vocabolario", "minLevel": 22, "pairs": [
			["Consul", "Guidava lo stato per un anno"],
			["Legatus", "Comandava una legione"],
			["Censor", "Contava i cittadini"],
			["Aedilis", "Curava strade e mercati"],
			["Quaestor", "Amministrava il denaro pubblico"],
			["Tribunus", "Difendeva la plebe"],
			["Praetor", "Amministrava la giustizia"],
			["Scriba", "Copiava e conservava i documenti"]]},
		# L17. Le locuzioni latine che si usano ancora oggi in italiano: è il punto
		# in cui il latino smette di essere una lingua morta da declinare e diventa
		# una cosa che si sente parlare.
		{"explanation": "Frasi latine ancora vive nell'italiano di oggi. Si citano intere perché dicono in tre parole quello che a noi ne costa dieci.", "topic": "vocabolario", "minLevel": 17, "kind": "pool", "pool": [
			["Alea iacta est", "Il dado è tratto"],
			["Veni, vidi, vici", "Venni, vidi, vinsi"],
			["Errare humanum est", "Sbagliare è umano"],
			["Repetita iuvant", "Le cose ripetute aiutano"],
			["Ad maiora", "Verso cose più grandi"],
			["Cogito ergo sum", "Penso, dunque sono"],
			["Mens sana in corpore sano", "Mente sana in un corpo sano"],
			["Divide et impera", "Dividi e comanda"],
			["Verba volant, scripta manent", "Le parole volano, gli scritti restano"],
			["Dura lex, sed lex", "La legge è dura, ma è legge"],
			["In vino veritas", "Nel vino sta la verità"],
			["Festina lente", "Affrettati lentamente"],
			["Nomen omen", "Il nome è un presagio"],
			["Per aspera ad astra", "Attraverso le difficoltà, fino alle stelle"],
			["Nosce te ipsum", "Conosci te stesso"],
			["Vox populi, vox Dei", "Voce di popolo, voce di Dio"],
			["Historia magistra vitae", "La storia è maestra di vita"],
			["Si vis pacem, para bellum", "Se vuoi la pace, prepara la guerra"],
			["Panem et circenses", "Pane e giochi del circo"],
			["Tempus fugit", "Il tempo fugge"],
			["Carpe diem", "Cogli l'attimo"],
			["Ubi maior minor cessat", "Dove c'è il più grande, il minore si ritira"],
			["Primum vivere", "Prima di tutto vivere"],
			["Ipse dixit", "L'ha detto lui stesso"]]},
		{"explanation": "Il caso dice che ruolo ha la parola nella frase. In latino lo dice la desinenza; in italiano lo dicono la posizione e le preposizioni.", "topic": "casi", "pairs": [["Nominativo", "Soggetto"], ["Accusativo", "Oggetto"], ["Genitivo", "Specificazione"], ["Dativo", "Termine"], ["Vocativo", "Invocazione"]]},
		{"explanation": "Parole della prima declinazione: molte sono rimaste quasi identiche in italiano, e riconoscerle è la via più veloce per tradurre.", "topic": "vocabolario", "pairs": [
			["aqua", "acqua"], ["silva", "bosco"], ["puella", "fanciulla"], ["lupus", "lupo"],
			["terra", "terra"], ["stella", "stella"], ["luna", "luna"], ["sol", "sole"],
			["mare", "mare"], ["flumen", "fiume"], ["arbor", "albero"], ["ventus", "vento"],
			["mons", "monte"], ["campus", "campo"], ["rex", "re"], ["regina", "regina"],
			["miles", "soldato"], ["nauta", "marinaio"], ["agricola", "contadino"], ["magister", "maestro"],
			["puer", "fanciullo"], ["equus", "cavallo"], ["canis", "cane"], ["avis", "uccello"],
			["piscis", "pesce"], ["aquila", "aquila"], ["templum", "tempio"], ["bellum", "guerra"],
			["donum", "dono"], ["liber", "libro"], ["porta", "porta"], ["hortus", "giardino"]]},
		# Le radici latine vive nell'italiano: aggancio culturale forte.
		{"explanation": "Dalla stessa radice latina nascono parole italiane diverse. Conoscere la radice fa indovinare il senso di parole mai viste prima.", "topic": "etimologia", "minLevel": 4, "pairs": [
			["aqua", "acquedotto"], ["terra", "territorio"], ["liber", "libreria"], ["schola", "scuola"],
			["bellum", "bellicoso"], ["navis", "navigare"], ["manus", "manuale"], ["pes", "pedone"],
			["oculus", "oculista"], ["dens", "dentista"], ["cor", "cordiale"], ["caput", "capitale"],
			["ignis", "ignifugo"], ["lux", "lucido"], ["nox", "notturno"], ["annus", "annuale"],
			["dies", "diario"], ["via", "viadotto"], ["urbs", "urbano"], ["ager", "agricoltura"],
			["populus", "popolare"], ["civis", "civile"], ["vox", "vocale"], ["tempus", "temporale"]]},
		{"explanation": "Il verbo essere è irregolare in latino come in italiano: le sue forme non si costruiscono, si sanno.", "topic": "verbo-sum", "minLevel": 5, "pairs": [["sum", "io sono"], ["es", "tu sei"], ["est", "egli è"], ["sumus", "noi siamo"]]},
		# Scuola media — la prima declinazione (rosa): desinenza -> caso.
		{"explanation": "La stessa parola cambia finale secondo il ruolo: rosa fa il soggetto, rosam l'oggetto, rosae il complemento di specificazione.", "topic": "declinazioni-base", "minLevel": 6, "pairs": [["rosa", "Nominativo"], ["rosam", "Accusativo"], ["rosae", "Genitivo"], ["rosā", "Ablativo"]]},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "Il latino non è finito: è dentro l'italiano di tutti i giorni. Riconoscere la radice serve anche a indovinare parole che non si sono mai sentite.", "topic": "etimologia", "pairs": [
			["aqua", "acquario"], ["liber", "libreria"], ["schola", "scolaro"],
			["manus", "manuale"], ["terra", "terrestre"], ["bellum", "bellico"],
			["nox", "notturno"], ["pes", "pedone"], ["oculus", "oculista"],
			["caput", "capitale"], ["ignis", "igneo"], ["tempus", "temporale"]]},
	],
	"musica": [
		# Fascia 7, 9 settembre 2026: era l'ultima casella del gioco sotto le tre
		# ricette nuove per fascia.
		{"explanation": "Ogni forma musicale ha una struttura riconoscibile all'ascolto, e sapere che cosa aspettarsi cambia il modo di ascoltare: si smette di seguire la melodia e si comincia a seguire il disegno.", "topic": "compositori", "minLevel": 20, "pairs": [
			["Sinfonia", "Grande opera per orchestra in piu' movimenti"],
			["Concerto", "Uno strumento solista dialoga con l'orchestra"],
			["Sonata", "Composizione per uno o due strumenti"],
			["Opera lirica", "Racconto cantato con scene e costumi"],
			["Quartetto d'archi", "Due violini, viola e violoncello"],
			["Corale", "Brano scritto per voci che cantano insieme"],
			["Fuga", "Un tema rientra a turno in ogni voce"],
			["Preludio", "Brano breve che introduce quello dopo"]]},
		# Al primo mondo musica aveva otto abbinamenti possibili in tutto: due
		# specifiche da quattro coppie. Era la materia con la ripetizione peggiore
		# rimasta, e la cura non è pescare meno ma avere più materiale con risposte
		# uniche — durata in battiti, nome internazionale, modo di produrre il suono.
		{"explanation": "Ogni figura vale il doppio della successiva. Il punto aggiunge la metà del valore: per questo la minima puntata vale tre e non quattro.", "topic": "ritmo", "pairs": [
			["Breve", "8 battiti"], ["Semibreve", "4 battiti"], ["Minima puntata", "3 battiti"],
			["Minima", "2 battiti"], ["Semiminima puntata", "1 battito e mezzo"], ["Semiminima", "1 battito"],
			["Croma puntata", "tre quarti di battito"], ["Croma", "mezzo battito"],
			["Semicroma", "un quarto di battito"], ["Biscroma", "un ottavo di battito"]]},
		# I nomi internazionali delle note: si trovano su ogni spartito e su ogni
		# accordo di chitarra, quindi non è nozionismo ma alfabeto pratico.
		{"explanation": "Il sistema anglosassone usa lettere al posto dei nomi: si parte dal La = A e si prosegue in ordine alfabetico.", "topic": "note", "pairs": [
			["Do", "C"], ["Re", "D"], ["Mi", "E"], ["Fa", "F"],
			["Sol", "G"], ["La", "A"], ["Si", "B"]]},
		{"explanation": "Gli strumenti a corda si distinguono per come la corda viene messa in vibrazione: pizzicata, sfregata o percossa.", "topic": "strumenti", "pairs": [
			["Chitarra", "corde pizzicate con le dita"], ["Violino", "corde sfregate con l'archetto"],
			["Pianoforte", "corde percosse da martelletti"], ["Flauto", "aria soffiata in un tubo"],
			["Tromba", "labbra che vibrano nel bocchino"], ["Tamburo", "pelle tesa percossa"],
			["Xilofono", "lamine di legno percosse"], ["Arpa", "corde pizzicate a mano libera"],
			["Organo a canne", "aria spinta dentro le canne"], ["Fisarmonica", "ance mosse dal mantice"],
			["Maracas", "semi che sbattono dentro il guscio"], ["Triangolo", "barra di metallo percossa"]]},
		{"explanation": "La dinamica dice quanto forte suonare, non quanto veloce. Sono due cose diverse e si scrivono con segni diversi.", "topic": "dinamica", "minLevel": 3, "pairs": [["forte (f)", "suonare forte"], ["piano (p)", "suonare piano"], ["crescendo", "aumentare a poco a poco"], ["staccato", "note staccate e brevi"]]},
		# Termini italiani di tempo (usati in tutto il mondo).
		{"explanation": "I termini di tempo sono in italiano perché la notazione moderna è nata in Italia, e si usano uguali in tutto il mondo.", "topic": "tempo", "minLevel": 4, "pairs": [["Adagio", "lento"], ["Andante", "camminando, moderato"], ["Allegro", "veloce e vivace"], ["Presto", "molto veloce"]]},
		# Scuola media — compositori e opere celebri.
		{"explanation": "Ogni opera porta la firma di chi l'ha scritta: riconoscere la coppia autore-opera è il primo passo per orientarsi nella musica classica.", "topic": "compositori", "minLevel": 6, "pairs": [["Beethoven", "Quinta Sinfonia"], ["Vivaldi", "Le Quattro Stagioni"], ["Mozart", "Il Flauto Magico"], ["Verdi", "Aida"]]},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "I segni di dinamica non dicono come suonare le note, ma quanto forte: è la differenza fra leggere un testo e leggerlo sussurrando o gridando.", "topic": "dinamica", "pairs": [
			["p", "piano, cioè debole"], ["f", "forte"], ["pp", "pianissimo, appena udibile"],
			["ff", "fortissimo, con tutta la forza"], ["mf", "mezzo forte"],
			["crescendo", "sempre più forte"], ["diminuendo", "sempre più piano"],
			["sforzando", "un colpo improvviso su una nota sola"],
			["mp", "mezzo piano"], ["ppp", "il più debole che si riesca"],
			["fff", "il più forte che si riesca"], ["accento", "una nota più marcata delle altre"],
			["morendo", "spegnendosi fino al silenzio"], ["sotto voce", "trattenuto, quasi sussurrato"],
			["rinforzando", "rinforzando di colpo un breve tratto"], ["calando", "insieme più piano e più lento"]]},
		{"explanation": "Le indicazioni di andamento sono parole italiane, e le usano i musicisti di tutto il mondo: dicono la velocità ma anche il carattere del brano.", "topic": "tempo", "pairs": [
			["Largo", "molto lento e ampio"], ["Adagio", "lento e disteso"],
			["Andante", "come chi cammina"], ["Moderato", "né lento né veloce"],
			["Allegro", "svelto e brillante"], ["Vivace", "vivo, pieno di slancio"],
			["Presto", "molto veloce"], ["Prestissimo", "il più veloce possibile"],
			["Grave", "lentissimo e solenne"], ["Larghetto", "poco meno lento del Largo"],
			["Andantino", "poco più mosso dell'Andante"], ["Allegretto", "poco meno svelto dell'Allegro"],
			["Sostenuto", "trattenuto, senza correre"], ["Con moto", "con un po' di spinta in avanti"],
			["Accelerando", "andando via via più veloce"], ["Rallentando", "andando via via più lento"]]},
	],
	"italiano": [
		# **Nato da un rosso, il 9 settembre 2026.** Questa prova era uno
		# scorrimento a tempo, e `number_line_audit` l'ha bocciata: il cronometro
		# vale solo sugli argomenti «fluency», dove la velocita' E' la competenza.
		# Il periodo ipotetico non e' uno di quelli — li' il tempo misura ansia.
		# Stesso contenuto, gesto diverso: si abbina ogni condizione alla sua
		# conseguenza, e le due meta' si reggono a vicenda.
		{"explanation": "Le due meta' del periodo ipotetico vanno in coppia: al presente indicativo risponde il presente, al congiuntivo imperfetto il condizionale presente, al congiuntivo trapassato il condizionale passato. Cambiarne una sola sbilancia la frase.", "topic": "congiuntivo-condizionale", "minLevel": 13, "pairs": [
			["Se ho tempo,", "vengo con te"],
			["Se avessi tempo,", "verrei con te"],
			["Se avessi avuto tempo,", "sarei venuto con te"],
			["Se piove,", "resto a casa"],
			["Se piovesse,", "resterei a casa"],
			["Se fosse piovuto,", "sarei restato a casa"],
			["Se studi,", "superi la prova"],
			["Se studiassi,", "supereresti la prova"]]},
		# **Le analogie che erano lessico, tornate a casa.** (1 settembre 2026)
		#
		# Questi sei insiemi stavano in logica e valevano, da soli, un quinto dei
		# nodi giocati di un mondo di logica. Sono contenuto ottimo — «il piccolo
		# di», «dove abita», «a che cosa serve», «una parte di», «il contrario
		# di», «che cosa lo contiene» sono le sei relazioni con cui si costruisce
		# il vocabolario di un bambino — ma non chiedono nessun passo di
		# inferenza: chi sa che il puledro è il piccolo del cavallo lo abbina, chi
		# non lo sa non lo deduce da niente.
		#
		# Qui sono al loro posto. In logica resta la relazione da RICONOSCERE
		# (`CLASSIFICATION`, argomento «analogie»), che è la parte che ragiona.

		# Una relazione sola per insieme, come deciso nella Fase 3: mescolarne due
		# renderebbe l'abbinamento indovinabile per associazione invece che per
		# ragionamento. Qui la relazione è «il piccolo → l'adulto».
		{"explanation": "L'analogia si risolve trovando la relazione: qui è «il piccolo di». Trovata quella, la coppia si completa da sé.", "topic": "lessico", "kind": "pool", "pool": [
			["cucciolo", "cane"], ["puledro", "cavallo"], ["gattino", "gatto"],
			["agnello", "pecora"], ["pulcino", "gallina"], ["vitello", "mucca"],
			["cerbiatto", "cervo"], ["anatroccolo", "anatra"], ["leprotto", "lepre"],
			["capretto", "capra"], ["porcellino", "maiale"], ["girino", "rana"]]},
		# Ogni insieme è UNA relazione sola, dichiarata nel commento: è questo che lo
		# rende un esercizio di logica invece che di vocabolario. Mescolare relazioni
		# diverse nello stesso insieme renderebbe l'abbinamento indovinabile per
		# associazione, che è il contrario di quello che la materia allena.
		# Relazione: «chi ci abita».
		# **Cinque coppie su venti si risolvevano dal nome.** (1 settembre 2026)
		#
		# Formica → formicaio, coniglio → conigliera, termite → termitaio, aquila →
		# nido d'aquila, ragno → ragnatela: la casa portava scritto dentro il nome
		# dell'inquilino. Erano punti regalati a chi non aveva mai pensato alla
		# relazione, ed è la scorciatoia che `scorciatoie_minigiochi_audit` ora
		# misura. Sostituite con cinque coppie in cui il nome della casa non dice
		# niente dell'animale: lì la relazione bisogna cercarla davvero.
		{"explanation": "La relazione è «dove abita». In un'analogia conta il legame fra le due parole, non la somiglianza fra loro.", "topic": "lessico", "pairs": [
			["Cane", "Cuccia"], ["Uccello", "Nido"], ["Ape", "Alveare"], ["Pesce", "Acquario"],
			["Cavallo", "Stalla"], ["Topo", "Tana"], ["Scoiattolo", "Cavità del tronco"], ["Falco", "Rupe"],
			["Cicogna", "Comignolo"], ["Maiale", "Porcile"], ["Riccio", "Cumulo di foglie"], ["Castoro", "Diga"],
			["Volpe", "Tana scavata"], ["Gallina", "Pollaio"], ["Pecora", "Ovile"], ["Orso", "Caverna"],
			["Talpa", "Galleria"], ["Lumaca", "Guscio"], ["Vipera", "Fessura tra le rocce"], ["Marmotta", "Cunicolo"]]},
		# Relazione: «a che cosa serve».
		{"explanation": "La relazione è «a che cosa serve»: ogni oggetto va con la sua funzione.", "topic": "lessico", "minLevel": 3, "pairs": [
			["Penna", "Scrivere"], ["Forbici", "Tagliare"], ["Martello", "Battere"], ["Chiave", "Aprire"],
			["Scopa", "Spazzare"], ["Ago", "Cucire"], ["Pettine", "Pettinare"], ["Termometro", "Misurare la febbre"],
			["Bussola", "Orientarsi"], ["Ombrello", "Ripararsi dalla pioggia"], ["Bilancia", "Pesare"], ["Telescopio", "Osservare lontano"],
			["Lente", "Ingrandire"], ["Remo", "Spingere la barca"], ["Sega", "Segare"], ["Freno", "Fermare"],
			["Setaccio", "Separare"], ["Imbuto", "Travasare"], ["Livella", "Verificare l'orizzontale"], ["Pinza", "Afferrare"]]},
		{"explanation": "Ogni elemento va con la categoria che lo contiene: la rosa è un fiore, e «fiore» è più ampio di «rosa».", "topic": "categorie", "minLevel": 4, "pairs": [["Rosa", "Fiore"], ["Cane", "Animale"], ["Mela", "Frutto"], ["Tavolo", "Mobile"]]},
		# Relazione: «parte di».
		{"explanation": "La relazione è «parte di»: la ruota fa parte dell'automobile come la pagina fa parte del libro.", "topic": "lessico", "minLevel": 4, "pairs": [
			["Ruota", "Automobile"], ["Foglia", "Albero"], ["Pagina", "Libro"], ["Dito", "Mano"],
			["Tasto", "Pianoforte"], ["Petalo", "Fiore"], ["Corda", "Chitarra"], ["Gradino", "Scala"],
			["Ala", "Uccello"], ["Radice", "Pianta"], ["Nota", "Melodia"], ["Mattone", "Muro"],
			["Stanza", "Casa"], ["Capitolo", "Romanzo"], ["Isola", "Arcipelago"], ["Vagone", "Treno"],
			["Lettera", "Parola"], ["Cellula", "Tessuto"], ["Fotogramma", "Film"], ["Stella", "Costellazione"]]},
		# Relazione: «il contrario di».
		{"explanation": "Gli opposti stanno sulla stessa scala, ai due estremi: giorno e notte sono i due capi della stessa giornata.", "topic": "contrari", "minLevel": 5, "pairs": [
			["Giorno", "Notte"], ["Salita", "Discesa"], ["Pieno", "Vuoto"], ["Inizio", "Fine"],
			["Vittoria", "Sconfitta"], ["Silenzio", "Rumore"], ["Ordine", "Disordine"], ["Verità", "Menzogna"],
			["Domanda", "Risposta"], ["Entrata", "Uscita"], ["Ricordo", "Oblio"], ["Guerra", "Pace"],
			["Partenza", "Arrivo"], ["Luce", "Buio"], ["Coraggio", "Paura"], ["Successo", "Fallimento"],
			["Presenza", "Assenza"], ["Movimento", "Quiete"], ["Nascita", "Morte"], ["Certezza", "Dubbio"]]},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		# --- Insiemi profondi (Fase 1) ---------------------------------------------
		# L'abbinamento regge un insieme profondo solo quando OGNI voce ha una
		# risposta sua: contrari, sinonimi, definizioni, modi di dire. I contenuti
		# «a categoria» (classe grammaticale, tempo verbale) non possono crescere
		# qui — con quattro risposte per venti voci l'abbinamento sarebbe ambiguo:
		# quelli stanno nello smistamento, che è fatto apposta.
		{"explanation": "I contrari si oppongono sulla stessa qualità — altezza, dimensione, luce — non su cose diverse. Per questo si imparano in coppia.", "topic": "contrari", "pairs": [
			["alto", "basso"], ["grande", "piccolo"], ["giorno", "notte"], ["caldo", "freddo"],
			["veloce", "lento"], ["pieno", "vuoto"], ["aperto", "chiuso"], ["ricco", "povero"],
			["pulito", "sporco"], ["forte", "debole"], ["chiaro", "scuro"], ["dolce", "amaro"],
			["duro", "morbido"], ["largo", "stretto"], ["lungo", "corto"], ["pesante", "leggero"],
			["vicino", "lontano"], ["salire", "scendere"], ["entrare", "uscire"], ["ridere", "piangere"],
			["iniziare", "finire"], ["vincere", "perdere"], ["dare", "ricevere"], ["sopra", "sotto"],
			["davanti", "dietro"], ["dentro", "fuori"], ["prima", "dopo"], ["sempre", "mai"],
			["giovane", "vecchio"], ["asciutto", "bagnato"], ["liscio", "ruvido"], ["utile", "inutile"]]},
		{"explanation": "La parte del discorso dipende da cosa fa la parola, non da come finisce: correre è verbo perché indica un'azione.", "topic": "categorie", "pairs": [["correre", "verbo"], ["gatto", "nome"], ["rosso", "aggettivo"], ["velocemente", "avverbio"]]},
		{"explanation": "I sinonimi dicono quasi la stessa cosa, ma non sempre si possono scambiare: cambiano il tono, non il significato.", "topic": "sinonimi", "pairs": [
			["felice", "contento"], ["veloce", "rapido"], ["bello", "stupendo"], ["triste", "malinconico"],
			["furbo", "astuto"], ["grande", "enorme"], ["minuto", "minuscolo"], ["difficile", "arduo"],
			["facile", "semplice"], ["silenzioso", "quieto"], ["coraggioso", "valoroso"], ["stanco", "spossato"],
			["arrabbiato", "furioso"], ["buffo", "comico"], ["strano", "bizzarro"], ["sudicio", "lurido"],
			["agiato", "benestante"], ["anziano", "attempato"], ["iniziare", "cominciare"], ["terminare", "concludere"],
			["guardare", "osservare"], ["parlare", "conversare"], ["camminare", "passeggiare"], ["capire", "comprendere"],
			["sbagliare", "errare"], ["aiutare", "soccorrere"], ["nascondere", "celare"], ["scoprire", "svelare"],
			["urlare", "gridare"], ["saltare", "balzare"]]},
		{"explanation": "Parole poco comuni ma precise. Usarne una al posto di tre parole generiche è ciò che rende un testo chiaro.", "topic": "definizioni", "minLevel": 7, "pairs": [
			["effimero", "che dura pochissimo"], ["arduo", "molto difficile"], ["placido", "calmo e tranquillo"],
			["arguto", "acuto e spiritoso"], ["tenace", "che non si arrende"], ["esiguo", "molto scarso"],
			["mendace", "che dice il falso"], ["magnanimo", "generoso e nobile d'animo"], ["ostinato", "che non cambia idea"],
			["sagace", "che capisce in fretta"], ["taciturno", "che parla poco"], ["ameno", "piacevole e gradevole"],
			["insolito", "fuori dal comune"], ["meticoloso", "attento a ogni dettaglio"], ["irruento", "impetuoso e scomposto"],
			["frugale", "sobrio, senza sprechi"], ["arcano", "misterioso e oscuro"], ["ligio", "fedele alle regole"],
			["prolisso", "che si dilunga troppo"], ["temerario", "audace fino all'imprudenza"], ["candido", "innocente e sincero"],
			["arcigno", "dall'aria severa e scontrosa"], ["solerte", "svelto e diligente"], ["vetusto", "molto antico"],
			["mite", "dolce e non violento"], ["astruso", "difficile da capire"]]},
		{"explanation": "I modi di dire non si capiscono parola per parola: il significato sta nell'insieme, e va imparato tutto intero.", "topic": "modi-di-dire", "minLevel": 6, "pairs": [
			["In bocca al lupo", "Buona fortuna"], ["Tagliare la corda", "Scappare via"],
			["Avere le mani in pasta", "Essere coinvolti"], ["Costare un occhio", "Essere carissimo"],
			["Perdere la testa", "Agitarsi o innamorarsi"], ["Prendere due piccioni con una fava", "Risolvere due cose insieme"],
			["Essere al verde", "Non avere più soldi"], ["Cadere dalle nuvole", "Essere molto sorpresi"],
			["Avere un diavolo per capello", "Essere furiosi"], ["Mettere il carro davanti ai buoi", "Fare le cose fuori ordine"],
			["Non vedere l'ora", "Aspettare con impazienza"], ["Tenere il piede in due scarpe", "Non voler scegliere"],
			["Fare orecchie da mercante", "Fingere di non sentire"], ["Essere una spugna", "Imparare tutto in fretta"],
			["Avere la testa fra le nuvole", "Essere distratti"], ["Piove sul bagnato", "Capita ancora a chi ne ha già"],
			["Rompere il ghiaccio", "Superare l'imbarazzo iniziale"], ["Dormire sugli allori", "Smettere di impegnarsi"],
			["Prendere un granchio", "Fare un grosso errore"], ["Essere di manica larga", "Perdonare facilmente"],
			["Restare a bocca aperta", "Stupirsi moltissimo"], ["Vuotare il sacco", "Confessare tutto"],
			["Fare il passo più lungo della gamba", "Pretendere troppo da sé"], ["Essere un pesce fuor d'acqua", "Sentirsi a disagio"],
			["Battere il ferro finché è caldo", "Approfittare del momento giusto"], ["Andare a gonfie vele", "Procedere benissimo"]]},
		{"explanation": "Si riconoscono dalla forma: la similitudine ha il «come», la personificazione dà azioni umane alle cose, l'iperbole esagera di proposito.", "topic": "figure-retoriche", "minLevel": 8, "pairs": [
			["Veloce come il vento", "Similitudine"], ["Il sole sorride nel cielo", "Personificazione"],
			["Ho un mare di compiti", "Iperbole"], ["Che silenzio assordante", "Ossimoro"],
			["Sei un leone in campo", "Metafora"], ["Il tic tac dell'orologio", "Onomatopea"],
			["Fischia il fiato fra le foglie", "Allitterazione"], ["Non è per niente stupido", "Litote"],
			["Non temo, non tremo, non cedo", "Anafora"], ["Bianco di neve, nero di pece", "Antitesi"],
			["Non è forte: è fortissimo, è invincibile", "Climax"], ["Le vele lasciarono il porto", "Sineddoche"]]},
		# Scuola media — analisi grammaticale: ogni parola alla sua parte del discorso.
		{"explanation": "L'analisi grammaticale guarda la parola da sola: che cosa è, non che ruolo ha nella frase.", "topic": "analisi-grammaticale", "minLevel": 8, "pairs": [["il", "articolo"], ["gatto", "nome"], ["dorme", "verbo"], ["pigro", "aggettivo"], ["sotto", "preposizione"]]},
		# Scuola media — modi e tempi del verbo (terminologia esplicita).
		{"explanation": "Il modo dice come si presenta l'azione: certa con l'indicativo, possibile col congiuntivo, legata a una condizione col condizionale.", "topic": "modi-verbali", "minLevel": 9, "pairs": [["io leggo", "indicativo"], ["che io legga", "congiuntivo"], ["io leggerei", "condizionale"], ["leggi!", "imperativo"]]},
		{"explanation": "Il tempo dice quando: il passato prossimo indica un fatto concluso, l'imperfetto un'azione che durava o si ripeteva.", "topic": "tempi-indicativo", "minLevel": 9, "pairs": [["ho letto", "passato prossimo"], ["leggevo", "imperfetto"], ["leggerò", "futuro semplice"], ["lessi", "passato remoto"]]},
		{"explanation": "I modi indefiniti non dicono chi compie l'azione: per saperlo serve il resto della frase.", "topic": "modi-indefiniti", "minLevel": 10, "pairs": [["leggere", "infinito"], ["leggendo", "gerundio"], ["letto", "participio"]]},
		# Scuola media — analisi logica: ogni sintagma alla sua funzione.
		# Frase: "Il gatto insegue il topo nel prato".
		{"explanation": "L'analisi logica guarda il ruolo nella frase, non la parola: «il gatto» è soggetto perché è lui a compiere l'azione.", "topic": "analisi-logica", "minLevel": 11, "pairs": [["Il gatto", "soggetto"], ["insegue", "predicato verbale"], ["il topo", "complemento oggetto"], ["nel prato", "complemento di luogo"]]},
		# Metrica: rima e strofa, abbinate come si abbinerebbero in classe. Lo
		# schema di lettere (AABB, ABAB, ABBA) è astratto quanto basta perché
		# l'abbinamento chieda di RICONOSCERE il pattern, non di ricordarlo a
		# memoria da un elenco.
		{"explanation": "Lo schema si legge dalle lettere: quelle uguali segnano dove cade la stessa rima. AABB le appaia una accanto all'altra, ABAB le alterna, ABBA le incastra.", "topic": "metrica", "minLevel": 14, "pairs": [
			["AABB", "rima baciata"], ["ABAB", "rima alternata"], ["ABBA", "rima incrociata"],
			["2 versi", "distico"], ["3 versi", "terzina"], ["4 versi", "quartina"],
			["7 sillabe", "settenario"], ["11 sillabe", "endecasillabo"],
			["senza rima, misura fissa", "verso sciolto"], ["senza rima né misura fissa", "verso libero"]]},
	],
	"storia": [
		# Al primo mondo storia aveva UNA specifica di abbinamento, quattro coppie
		# fisse, quattro prove in tutto — e due delle quattro si risolvevano dal
		# nome senza sapere niente di storia («Romani → Roma», «Greci → Grecia»).
		#
		# Ora due insiemi, perché il criterio 5 chiede almeno due specifiche per
		# (materia, formato, livello): con una sola la consegna è sempre la stessa
		# anche quando cambiano le tessere.
		#
		# Solo civiltà che a dieci anni si sono già incontrate. Un insieme profondo
		# pesca tre voci qualsiasi, e tre civiltà oscure insieme non fanno una prova
		# difficile: fanno una prova impossibile. Le altre stanno nell'insieme
		# gatato qui sotto — è la lezione della Fase 2, non ridurre l'insieme ma
		# affiancarne uno più facile ai primi mondi.
		{"explanation": "Ogni popolo lascia ciò che sapeva fare meglio, e sapeva fare ciò di cui aveva bisogno dove viveva.", "topic": "invenzioni", "kind": "pool", "pool": [
			["Egizi", "le piramidi"], ["Romani", "gli acquedotti"],
			["Greci", "la democrazia"], ["Fenici", "l'alfabeto"],
			["Sumeri", "la scrittura cuneiforme"], ["Cinesi", "la carta"],
			["Vichinghi", "le navi drakkar"], ["Inca", "le strade sulle Ande"],
			["Aztechi", "gli orti galleggianti"], ["Babilonesi", "le prime leggi scritte"],
			["Arabi", "i numeri che usiamo oggi"], ["Etruschi", "le tombe dipinte"]]},
		# Dove viveva ciascuna: nessuna risposta ricavabile dal nome del popolo.
		{"explanation": "Le prime civiltà nascono tutte vicino all'acqua: senza fiume non c'è agricoltura, e senza agricoltura non c'è città.", "topic": "civilta", "kind": "pool", "pool": [
			["Egizi", "lungo il Nilo"], ["Sumeri", "fra Tigri ed Eufrate"],
			["Fenici", "sulle coste del Libano"], ["Etruschi", "in Toscana"],
			["Vichinghi", "in Scandinavia"], ["Inca", "sulle Ande"],
			["Aztechi", "in Messico"], ["Cinesi", "lungo il Fiume Giallo"],
			["Celti", "in Gallia"], ["Romani", "nel Lazio"],
			["Cartaginesi", "sulle coste del Nord Africa"], ["Greci", "intorno al Mar Egeo"]]},
		# Dal mondo 6 l'insieme si allarga ai popoli che si incontrano più tardi.
		{"explanation": "Un'invenzione resta legata al popolo che l'ha resa comune, non a chi l'ha pensata per primo.", "topic": "invenzioni", "minLevel": 6, "kind": "pool", "pool": [
			["Egizi", "le piramidi"], ["Romani", "gli acquedotti"],
			["Greci", "la democrazia"], ["Fenici", "l'alfabeto"],
			["Sumeri", "la scrittura cuneiforme"], ["Cinesi", "la carta"],
			["Vichinghi", "le navi drakkar"], ["Inca", "le strade sulle Ande"],
			["Aztechi", "gli orti galleggianti"], ["Babilonesi", "le prime leggi scritte"],
			["Arabi", "i numeri che usiamo oggi"], ["Etruschi", "le tombe dipinte"],
			["Persiani", "la strada reale"], ["Assiri", "i carri da guerra"],
			["Ittiti", "la lavorazione del ferro"], ["Micenei", "le maschere d'oro"],
			["Bizantini", "i mosaici dorati"], ["Longobardi", "i ducati"],
			["Maya", "il calendario di pietra"], ["Cretesi", "il palazzo di Cnosso"],
			["Ebrei", "la Bibbia ebraica"], ["Cartaginesi", "il porto circolare"],
			["Mongoli", "l'arco da cavallo"], ["Normanni", "i castelli in pietra"]]},
		# Scuola media — personaggi e le loro imprese. Ogni personaggio ha una sola
		# impresa e ogni impresa un solo personaggio: è la condizione che permette a
		# un abbinamento di diventare profondo senza diventare ambiguo.
		{"explanation": "Ogni nome si ricorda per un fatto solo: è quel fatto a fissarlo nella memoria, non la biografia intera.", "topic": "personaggi", "minLevel": 18, "pairs": [
			["Romolo", "Fondò Roma secondo la leggenda"], ["Giulio Cesare", "Conquistò la Gallia"],
			["Cristoforo Colombo", "Arrivò in America nel 1492"], ["Marco Polo", "Viaggiò fino alla Cina"],
			["Alessandro Magno", "Conquistò l'impero persiano"], ["Augusto", "Fu il primo imperatore romano"],
			["Annibale", "Attraversò le Alpi con gli elefanti"], ["Carlo Magno", "Fu incoronato imperatore nell'800"],
			["Gutenberg", "Inventò la stampa a caratteri mobili"], ["Leonardo da Vinci", "Dipinse la Gioconda"],
			["Galileo Galilei", "Puntò il telescopio sui pianeti"], ["Giuseppe Garibaldi", "Guidò la spedizione dei Mille"],
			["Pericle", "Guidò Atene nella sua età d'oro"], ["Archimede", "Scoprì la spinta idrostatica"],
			["Tutankhamon", "Fu sepolto in una tomba intatta"], ["Amerigo Vespucci", "Diede il nome all'America"],
			["Ferdinando Magellano", "Organizzò il primo giro del mondo"], ["Ipazia", "Insegnò matematica ad Alessandria"],
			["Costantino", "Rese lecito il cristianesimo"], ["Attila", "Guidò gli Unni in Europa"],
			["Cleopatra", "Fu l'ultima regina d'Egitto"], ["Erodoto", "È detto il padre della storia"],
			["Solone", "Diede ad Atene le prime leggi scritte"], ["Traiano", "Portò Roma alla massima estensione"]]},
		{"explanation": "Le date si tengono insieme con i punti fermi. Prima di Cristo si conta all'indietro, dopo in avanti: per questo il 753 a.C. viene prima del 476 d.C.", "topic": "cronologia", "minLevel": 5, "pairs": [
			["Fondazione di Roma", "753 a.C."], ["Nascita di Cristo", "Anno 0"],
			["Caduta di Roma d'Occidente", "476 d.C."], ["Scoperta dell'America", "1492"],
			["Primi Giochi olimpici", "776 a.C."], ["Eruzione di Pompei", "79 d.C."],
			["Incoronazione di Carlo Magno", "800 d.C."], ["Prima crociata", "1096"],
			["Viaggio di Marco Polo", "1271"], ["Peste nera in Europa", "1347"],
			["Stampa di Gutenberg", "1455"], ["Rivoluzione francese", "1789"],
			["Unità d'Italia", "1861"], ["Prima guerra mondiale", "1914"],
			["Sbarco sulla Luna", "1969"], ["Democrazia ad Atene", "508 a.C."],
			["Costruzione del Partenone", "447 a.C."], ["Cesare in Gallia", "52 a.C."],
			["Augusto imperatore", "27 a.C."], ["Codice di Hammurabi", "1750 a.C."]]},
		{"explanation": "L'architettura racconta la civiltà: l'arco e il cemento sono romani, le colonne dei templi greche, la piramide egizia.", "topic": "civilta", "minLevel": 6, "pairs": [["Colosseo", "Romani"], ["Partenone", "Greci"], ["Piramidi", "Egizi"], ["Ziggurat", "Sumeri"]]},
		# --- Mondo 1: una ricetta in più (tappa 2, 6 agosto 2026) ---------------
		{"explanation": "Le prime civiltà nascono sull'acqua: un fiume dà da bere, irriga i campi e serve da strada. Dove l'acqua manca, un impero non si regge.", "topic": "civilta", "pairs": [
			["Egizi", "Nilo"], ["Sumeri", "Tigri ed Eufrate"], ["Romani", "Tevere"],
			["Greci", "mar Egeo"], ["civiltà dell'Indo", "Indo"], ["Cinesi antichi", "Fiume Giallo"],
			["Fenici", "coste del Libano"], ["Etruschi", "Toscana"], ["Maya", "Yucatán"],
			["Inca", "Ande"], ["Aztechi", "altopiano del Messico"], ["Cartaginesi", "coste della Tunisia"]]},
	],
	"coding": [
		{"explanation": "Il tipo dipende da come è scritto il valore: le virgolette fanno una stringa, True e False sono booleani, un numero nudo è un intero.", "topic": "tipi", "pairs": [["7", "intero"], ["'ciao'", "stringa"], ["True", "booleano"], ["[1, 2, 3]", "lista"]]},
		{"explanation": "Ogni operatore fa una cosa sola. Il % non è una percentuale: è il resto della divisione.", "topic": "operatori", "pairs": [["+", "somma"], ["*", "moltiplicazione"], ["%", "resto"], ["**", "potenza"]]},
		{"explanation": "Sono i tre mattoni di ogni programma: conservare un valore, ripetere istruzioni, riusare un blocco già scritto.", "topic": "concetti", "minLevel": 3, "pairs": [["variabile", "contenitore di un valore"], ["ciclo", "ripete istruzioni"], ["funzione", "blocco riutilizzabile"], ["condizione", "sceglie un percorso"]]},
		{"explanation": "In programmazione == confronta e = assegna. Sono due cose diverse, ed è l'errore più comune di chi comincia.", "topic": "simboli", "minLevel": 4, "pairs": [["==", "uguale a"], ["!=", "diverso da"], [">=", "maggiore o uguale"], ["=", "assegnazione"]]},
		# Prevedi l'output: leggere il codice come lo legge il computer.
		{"explanation": "Per sapere cosa stampa un programma lo si esegue con la testa, un passo per volta: * su un testo lo ripete, // divide e butta via il resto.", "topic": "output", "minLevel": 5, "pairs": [["print(2 + 3)", "5"], ["print('ab' * 2)", "abab"], ["print(10 // 3)", "3"], ["len('ciao')", "4"]]},
		# Scuola media — numeri binari (fondamenti dell'informatica). Prefisso 0b
		# come in Python: chiarisce che è binario e insegna il letterale reale.
		{"explanation": "In binario ogni posizione vale il doppio della precedente: 0b100 è 4 perché il terzo posto vale quattro.", "topic": "binario", "minLevel": 7, "pairs": [["0b10", "2"], ["0b11", "3"], ["0b100", "4"], ["0b101", "5"], ["0b1000", "8"]]},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Ogni istruzione fa una cosa sola, e il nome quasi sempre lo dice. Il tranello è «=» contro «==»: uno assegna, l'altro chiede se due cose sono uguali.", "topic": "algoritmi", "pairs": [
			["print", "mostra a schermo"], ["input", "chiede un dato a chi usa il programma"],
			["if", "sceglie fra due strade"], ["while", "ripete finché una cosa è vera"],
			["for", "ripete un numero noto di volte"], ["def", "definisce una funzione"],
			["return", "restituisce un risultato"], ["len", "conta quanti elementi ci sono"],
			["append", "aggiunge in fondo a una lista"], ["=", "assegna un valore"],
			["==", "chiede se due valori sono uguali"], ["#", "scrive una nota per chi legge"]]},
	],
	"elettronica": [
		# Fascia 2. Nessuna coppia si vince cercando la parola ripetuta fra le due
		# colonne: il nome del pezzo non compare mai nella sua funzione.
		{"explanation": "Ogni pezzo di un circuito ha un mestiere solo, e il circuito funziona perche' nessuno fa il lavoro di un altro. Riconoscere il mestiere prima del nome rende leggibile qualunque schema.", "topic": "circuito", "minLevel": 4, "pairs": [
			["Pila", "Spinge le cariche nel giro"],
			["Interruttore", "Apre e chiude il passaggio"],
			["Lampadina", "Trasforma in luce e calore"],
			["Filo di rame", "Lascia passare senza ostacolare"],
			["Resistore", "Frena il passaggio delle cariche"],
			["Fusibile", "Si spezza se passa troppo"],
			["Motorino", "Trasforma in movimento"],
			["Portapile", "Tiene il contatto ai due poli"]]},
		{"explanation": "In un circuito LED ci sono quattro lavori diversi. La pila dà la spinta, l'interruttore apre o chiude la strada, il resistore frena la corrente per proteggere il LED e il LED trasforma l'energia in luce.", "topic": "componenti-base", "pairs": [["Pila", "Dà la spinta elettrica"], ["Interruttore", "Apre e chiude la strada"], ["Resistore", "Protegge il LED limitando la corrente"], ["LED", "Trasforma energia in luce"], ["Filo di rame", "Porta la corrente da un pezzo all'altro"], ["Lampadina", "Trasforma energia in luce e calore"], ["Motorino", "Trasforma energia in movimento"], ["Cicalino", "Trasforma energia in suono"]]},
		{"explanation": "Le tre parole rispondono a tre domande diverse. La tensione è la spinta e si misura in volt; la corrente è quanta carica passa e si misura in ampere; la resistenza è quanto un componente ostacola il passaggio e si misura in ohm.", "topic": "misure-elettriche", "pairs": [["Tensione: la spinta", "Volt (V)"], ["Corrente: quanto passa", "Ampere (A)"], ["Resistenza: quanto frena", "Ohm (Ω)"]]},
		{"explanation": "Potenza, energia e frequenza sono grandezze diverse e arrivano solo dopo le tre misure di base: watt dice quanta energia si usa ogni secondo, joule quanta energia in tutto, hertz quante volte un evento si ripete in un secondo.", "topic": "grandezze", "minLevel": 10, "pairs": [["Potenza", "Watt"], ["Energia", "Joule"], ["Frequenza", "Hertz"]]},
		# Scuola media — legge di Ohm e prefissi delle unità.
		{"explanation": "La legge di Ohm descrive il legame fra spinta, passaggio e ostacolo: V = I × R. Si usa soltanto dopo aver imparato che cosa significano tensione, corrente e resistenza.", "topic": "legge-ohm", "minLevel": 20, "pairs": [["Tensione (V)", "R × I"], ["Corrente (I)", "V / R"], ["Resistenza (R)", "V / I"]]},
		{"explanation": "I prefissi cambiano la grandezza di mille volte: chilo significa mille volte, milli significa la millesima parte. Prima si riconosce l'unità, poi si converte.", "topic": "prefissi", "minLevel": 9, "pairs": [["1000 Ω", "1 kΩ"], ["1000 mA", "1 A"], ["1000 mV", "1 V"]]},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Immagina un circuito come un giro di tubi. La pila fa da pompa, il filo da tubo, la tensione è la spinta, la corrente è ciò che scorre e l'interruttore è un rubinetto. È solo un modello, ma aiuta a distinguere le idee.", "topic": "elettricita-base", "pairs": [
			["la pila", "la pompa che spinge"], ["la tensione", "la pressione dell'acqua"],
			["la corrente", "quanta acqua passa al secondo"], ["la resistenza", "il tubo stretto"],
			["l'interruttore", "il rubinetto"], ["il filo", "il tubo"]]},
		{"explanation": "La diagnosi arriva dopo il circuito semplice: si parte dal sintomo, si controlla prima se il giro è chiuso e poi si prova un tratto per volta, senza cambiare tutti i pezzi insieme.", "topic": "guasti", "minLevel": 22, "pairs": [
			["la lampadina non si accende", "il circuito è interrotto"],
			["i fili scaldano troppo", "passa più corrente del dovuto"],
			["la pila si scarica in pochi minuti", "c'è un cortocircuito"],
			["la luce è debole", "la pila è quasi scarica"],
			["il motore gira al contrario", "i poli sono invertiti"],
			["funziona solo muovendo il filo", "un contatto è allentato"]]},
	],
	"fisica": [
		{"explanation": "Il movimento si legge da che cosa fa la velocità: se cresce, se cala o se resta com'è. La situazione la racconta, la velocità la misura.", "topic": "moto", "pairs": [
			["Il semaforo diventa verde e parti", "La velocità cresce"],
			["Freni davanti alle strisce", "La velocità cala"],
			["Vai dritto a passo costante", "La velocità resta com'era"],
			["Il sasso cade dal tetto", "Va sempre più forte"],
			["La palla rotola sull'erba e si ferma", "L'attrito la frena"],
			["Il paracadute si apre", "La caduta perde colpi"]]},
		{"explanation": "Sono tre delle sette unità di base del Sistema Internazionale: tutte le altre si costruiscono a partire da queste.", "topic": "misure", "pairs": [["Lunghezza", "Metro"], ["Massa", "Chilogrammo"], ["Tempo", "Secondo"], ["Temperatura", "Grado"]]},
		{"explanation": "L'energia cambia forma e non sparisce: ferma in alto è potenziale, mentre cade diventa cinetica.", "topic": "energia", "pairs": [["Palla in alto", "Energia potenziale"], ["Palla che cade", "Energia cinetica"], ["Cibo", "Energia chimica"], ["Lampadina accesa", "Energia luminosa"]]},
		{"explanation": "Ogni strumento misura una grandezza sola: sbagliare strumento significa misurare un'altra cosa.", "topic": "strumenti", "minLevel": 3, "pairs": [["Righello", "lunghezza"], ["Bilancia", "massa"], ["Cronometro", "tempo"], ["Termometro", "temperatura"]]},
		{"explanation": "Una forza si riconosce da cosa fa al moto: lo avvia, lo rallenta o lo devia.", "topic": "forze", "minLevel": 4, "pairs": [["Attrito", "Rallenta il moto"], ["Gravità", "Attira verso il basso"], ["Spinta", "Mette in moto"], ["Magnetismo", "Attira il ferro"]]},
		{"explanation": "Il fulcro è il punto fermo; allontanare la mano dal fulcro fa diminuire lo sforzo necessario.", "topic": "leve", "minLevel": 4, "pairs": [
			["Il punto fermo della leva", "Si chiama fulcro"],
			["La mano spinge molto lontano", "Serve meno forza"],
			["Il carico sta attaccato vicino", "Si solleva con poco sforzo"],
			["Le due distanze sono uguali", "Nessun guadagno: forza identica"],
			["La leva allunga la strada della mano", "Guadagni forza ma cammini di più"],
			["Le forbici e la carriola", "Sono macchine semplici"]]},
		{"explanation": "La pressione cresce quando la stessa forza si concentra su meno superficie; sott'acqua cresce anche con la profondità.", "topic": "pressione", "minLevel": 13, "pairs": [
			["Punta sottile della puntina", "Concentra la forza su pochissima superficie"],
			["Base larga dello sci", "Distribuisce il peso su molta superficie"],
			["Acqua bassa vicino a riva", "Sopra c'è poca acqua e la spinta è debole"],
			["Fondo profondo del lago", "Sopra c'è molta acqua e la spinta è forte"],
			["Diga più spessa in basso", "Regge una spinta che cresce scendendo"],
			["Tacco a spillo sul pavimento", "Lascia il segno perché preme su un punto"],
			["Zaino con le cinghie strette", "Fa male alle spalle più di uno morbido"],
			["Sub a venti metri di profondità", "Sente le orecchie premere"]]},
		{"explanation": "Il peso spinge in basso e l'acqua spinge in alto: dal confronto fra le due forze dipende il movimento verticale.", "topic": "galleggiamento", "minLevel": 13, "pairs": [
			["Il peso vince sulla spinta", "Va a fondo"],
			["La spinta vince sul peso", "Risale verso la superficie"],
			["Peso e spinta si equivalgono", "Resta ferma a mezz'acqua"],
			["Scafo vuoto dentro", "Sposta molta acqua e galleggia"],
			["Biglia piena di acciaio", "Sposta poca acqua e affonda"],
			["Giubbotto salvagente", "Aggiunge volume leggero al corpo"],
			["Tronco di legno secco", "Resta a galla da solo"],
			["Palla da spiaggia tenuta sotto", "Torna su appena la lasci"]]},
		{"explanation": "La corrente è il movimento dell'acqua: può aiutare, frenare o deviare ciò che viaggia al suo interno.", "topic": "correnti", "minLevel": 13, "pairs": [
			["Corrente nello stesso verso", "Aiuta ad avanzare"],
			["Corrente opposta", "Rallenta"],
			["Corrente laterale", "Fa deviare"],
			["Oggetto libero", "Segue l'acqua"],
			["Barca a motore spento", "Va dove la porta il fiume"],
			["Prua puntata un po' a monte", "Compensa lo scivolamento"],
			["Nuotatore che punta dritto", "Tocca riva più a valle"],
			["Due foglie diverse nello stesso tratto", "Viaggiano appaiate"]]},
		# Scuola media — macchine semplici e formule.
		{"explanation": "Le macchine semplici non riducono il lavoro: lo rendono più comodo, distribuendolo su più spazio o cambiandone la direzione.", "topic": "macchine", "minLevel": 6, "pairs": [["Leva", "Solleva con meno forza"], ["Carrucola", "Cambia direzione alla forza"], ["Piano inclinato", "Riduce lo sforzo in salita"], ["Ruota", "Riduce l'attrito"]]},
		{"explanation": "Ogni formula è una divisione o una moltiplicazione fra grandezze: leggerla dice già che cosa dipende da che cosa.", "topic": "formule", "minLevel": 7, "pairs": [["Velocità", "spazio / tempo"], ["Densità", "massa / volume"], ["Forza peso", "massa × gravità"]]},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Una forza non si vede: si vede quello che fa. Si riconosce dall'effetto, cioè da come cambia il movimento o la forma di una cosa.", "topic": "forze", "pairs": [
			["gravità", "fa cadere le cose verso il basso"], ["attrito", "rallenta e scalda"],
			["spinta di Archimede", "fa galleggiare"], ["forza elastica", "riporta la molla indietro"],
			["forza magnetica", "attira il ferro a distanza"], ["forza muscolare", "muove il corpo"],
			["resistenza dell'aria", "frena il paracadute"], ["forza centripeta", "tiene in curva"]]},
		{"explanation": "I passaggi di stato hanno un nome per ogni direzione: la stessa strada percorsa al contrario è un fenomeno diverso, e serve o libera calore.", "topic": "materia", "pairs": [
			["fusione", "da solido a liquido"], ["solidificazione", "da liquido a solido"],
			["evaporazione", "da liquido a gas"], ["condensazione", "da gas a liquido"],
			["sublimazione", "da solido a gas"], ["brinamento", "da gas a solido"]]},
	],
	"matematica": [
		# Prodotti tutti DIVERSI dentro l'insieme: due voci con lo stesso risultato
		# renderebbero l'abbinamento ambiguo appena capitassero insieme.
		{"explanation": "Sapere una tabellina significa averla pronta senza contare: è il tempo risparmiato che serve poi per tutto il resto.", "topic": "tabelline", "pairs": [
			["3 × 4", "12"], ["6 × 7", "42"], ["8 × 5", "40"], ["9 × 3", "27"],
			["7 × 8", "56"], ["6 × 9", "54"], ["4 × 7", "28"], ["8 × 8", "64"],
			["9 × 7", "63"], ["6 × 6", "36"], ["8 × 9", "72"], ["4 × 6", "24"],
			["7 × 5", "35"], ["9 × 9", "81"], ["8 × 6", "48"], ["3 × 7", "21"],
			["5 × 9", "45"], ["4 × 8", "32"], ["7 × 7", "49"], ["6 × 5", "30"],
			["11 × 4", "44"], ["12 × 3", "33"], ["11 × 6", "66"], ["11 × 7", "77"],
			["4 × 4", "16"], ["9 × 2", "18"], ["7 × 2", "14"], ["12 × 5", "60"],
			["11 × 9", "99"], ["12 × 7", "84"], ["11 × 8", "88"], ["12 × 9", "108"]]},
		{"explanation": "Le quattro operazioni di base. La divisione disfa la moltiplicazione e la sottrazione disfa l'addizione: per questo si controllano a vicenda.", "topic": "calcolo", "pairs": [
			["10 + 5", "15"], ["20 - 8", "12"], ["18 ÷ 3", "6"], ["7 + 6", "13"],
			["25 + 17", "42"], ["63 - 28", "35"], ["196 ÷ 14", "14"], ["17 × 3", "51"],
			["350 ÷ 7", "50"], ["45 + 38", "83"], ["100 - 47", "53"], ["23 × 4", "92"],
			["120 ÷ 5", "24"], ["56 + 29", "85"], ["81 - 36", "45"], ["19 × 5", "95"],
			["150 ÷ 6", "25"], ["74 + 48", "122"], ["200 - 133", "67"], ["16 × 7", "112"],
			["480 ÷ 12", "40"], ["87 + 96", "183"], ["310 - 145", "165"], ["24 × 6", "144"],
			["729 ÷ 9", "81"], ["108 + 97", "205"], ["500 - 264", "236"], ["32 × 8", "256"],
			["441 ÷ 21", "21"], ["76 + 88", "164"], ["1000 - 375", "625"], ["45 × 12", "540"]]},
		# Fluenza tra rappresentazioni: la stessa quantità in forme diverse (idea CPA).
		{"explanation": "Una frazione è una divisione: 1/2 è uno diviso due, cioè 0,5.", "topic": "frazioni", "minLevel": 4, "pairs": [
			["1/2", "0,5"], ["1/4", "0,25"], ["3/4", "0,75"], ["1/5", "0,2"],
			["1/10", "0,1"], ["3/10", "0,3"], ["7/10", "0,7"], ["1/8", "0,125"],
			["3/8", "0,375"], ["5/8", "0,625"], ["1/20", "0,05"], ["3/5", "0,6"],
			["2/5", "0,4"], ["4/5", "0,8"], ["1/100", "0,01"], ["9/10", "0,9"],
			["7/8", "0,875"], ["1/25", "0,04"], ["11/10", "1,1"], ["5/2", "2,5"]]},
		{"explanation": "Una percentuale è una frazione con cento sotto: 1/4 vale 25 su 100, cioè 25%.", "topic": "percentuali", "minLevel": 5, "pairs": [
			["1/2", "50%"], ["1/4", "25%"], ["1/5", "20%"], ["3/4", "75%"],
			["1/10", "10%"], ["3/10", "30%"], ["7/10", "70%"], ["9/10", "90%"],
			["2/5", "40%"], ["3/5", "60%"], ["4/5", "80%"], ["1/20", "5%"],
			["1/100", "1%"], ["1/1", "100%"], ["1/8", "12,5%"], ["3/8", "37,5%"]]},
		# Scuola media — potenze e formule di geometria.
		{"explanation": "La potenza dice quante volte moltiplicare il numero per se stesso: 2³ è 2×2×2, non 2×3.", "topic": "potenze", "minLevel": 6, "pairs": [
			["2³", "8"], ["3²", "9"], ["5²", "25"], ["10³", "1000"],
			["2⁴", "16"], ["2⁵", "32"], ["3³", "27"], ["4³", "64"],
			["6²", "36"], ["7²", "49"], ["2⁷", "128"], ["9²", "81"],
			["11²", "121"], ["12²", "144"], ["10²", "100"], ["10⁴", "10000"],
			["5³", "125"], ["4⁴", "256"], ["6³", "216"], ["1⁹", "1"]]},
		{"explanation": "Ogni formula segue la forma: l'area del triangolo è la metà di quella del rettangolo che lo contiene.", "topic": "geometria", "minLevel": 5, "pairs": [["Area del quadrato", "lato × lato"], ["Perimetro del rettangolo", "(base + altezza) × 2"], ["Area del triangolo", "base × altezza ÷ 2"], ["Area del cerchio", "π × raggio²"]]},
		# --- Mondo 1: altre tre ricette (6 agosto 2026) --------------------------
		# Il livello 1 aveva quattro sole specifiche, e due erano la STESSA
		# esperienza: espressione da calcolare, risultato da abbinare. Un bambino
		# le esauriva in due sessioni e da lì in poi vedeva sempre le stesse
		# consegne con dentro numeri diversi — la segnalazione di gioco del
		# 6 agosto nasce da qui. Queste chiedono azioni mentali diverse, non
		# altra aritmetica.
		{"explanation": "Ogni operazione ne ha una che la disfa: è il modo per controllare un conto senza rifarlo uguale, e se non torna l'errore è nel primo.", "topic": "operazioni-inverse", "pairs": [
			["aggiungere 7", "togliere 7"], ["moltiplicare per 3", "dividere per 3"],
			["il doppio", "la metà"], ["aggiungere 25", "togliere 25"],
			["moltiplicare per 10", "dividere per 10"], ["il triplo", "un terzo"],
			["togliere 12", "aggiungere 12"], ["dividere per 4", "moltiplicare per 4"],
			["salire di 100", "scendere di 100"], ["moltiplicare per 5", "dividere per 5"],
			["aggiungere 9", "togliere 9"], ["dividere per 2", "moltiplicare per 2"]]},
		{"explanation": "Il nome di un poligono dice quanti lati ha: penta cinque, esa sei, otta otto. Sono le stesse radici greche dei numeri.", "topic": "geometria", "pairs": [
			["triangolo", "3 lati"], ["quadrilatero", "4 lati"], ["pentagono", "5 lati"],
			["esagono", "6 lati"], ["ettagono", "7 lati"], ["ottagono", "8 lati"],
			["ennagono", "9 lati"], ["decagono", "10 lati"], ["dodecagono", "12 lati"],
			["cerchio", "nessun lato"]]},
		{"explanation": "Una sequenza si riconosce dal passo: si guarda che cosa succede da un numero al successivo, e si controlla che valga anche dopo.", "topic": "sequenze", "pairs": [
			["2, 4, 6, 8", "si aggiunge 2"], ["5, 10, 15, 20", "si aggiunge 5"],
			["3, 6, 12, 24", "si raddoppia"], ["100, 90, 80, 70", "si toglie 10"],
			["1, 3, 9, 27", "si moltiplica per 3"], ["50, 45, 40, 35", "si toglie 5"],
			["7, 14, 21, 28", "si aggiunge 7"], ["64, 32, 16, 8", "si dimezza"],
			["1, 4, 9, 16", "i quadrati"], ["11, 22, 33, 44", "si aggiunge 11"],
			["1000, 100, 10, 1", "si divide per 10"], ["9, 18, 27, 36", "si aggiunge 9"]]},
		# **I due argomenti del programma che non avevano nessun gesto.** (6
		# settembre 2026) Con il banco di medie e biennio il registro degli
		# argomenti di matematica passa da diciassette a venticinque, e sei di
		# quelli nuovi vivevano solo dentro una domanda a scelta multipla.
		# `radici` e `similitudine` sono i due che si abbinano davvero: la radice
		# è una tabellina letta al contrario, e i nomi della geometria euclidea
		# hanno ciascuno una definizione sola.
		{"explanation": "La radice quadrata cerca il numero che moltiplicato per sé stesso dà quello sotto il segno: è la tabellina letta al contrario, non una divisione per due.", "topic": "radici", "minLevel": 6, "pairs": [
			["√4", "2"], ["√9", "3"], ["√16", "4"], ["√25", "5"],
			["√36", "6"], ["√49", "7"], ["√64", "8"], ["√81", "9"],
			["√100", "10"], ["√121", "11"], ["√144", "12"], ["√169", "13"]]},
		{"explanation": "Nella geometria del triangolo rettangolo ogni nome indica una cosa sola e precisa: confondere il cateto con l'ipotenusa, o la similitudine con la congruenza, fa sbagliare la formula prima ancora del conto.", "topic": "similitudine", "minLevel": 16, "pairs": [
			["ipotenusa", "il lato più lungo del triangolo rettangolo"],
			["cateto", "uno dei due lati che formano l'angolo retto"],
			["figure congruenti", "si sovrappongono perfettamente"],
			["figure simili", "stessa forma, misure diverse"],
			["teorema di Pitagora", "collega i quadrati dei tre lati"],
			["teorema di Talete", "segmenti staccati fra rette parallele"],
			["primo teorema di Euclide", "un cateto e la sua proiezione"],
			["rapporto di similitudine", "quante volte una figura è ingrandita"],
			["scala di una mappa", "il legame fra carta e terreno"],
			["lati raddoppiati", "area quattro volte più grande"],
			["angoli corrispondenti", "restano uguali nell'ingrandimento"],
			["altezza del triangolo", "distanza fra un vertice e il lato opposto"]]},
		# --- Un gesto per gli argomenti aperti il 7 settembre 2026 ---------------
		#
		# Cinque argomenti nuovi del banco (misure, decimali, cerchio, figure,
		# trasformazioni) più i due del programma che mancavano (pitagora,
		# insiemi) si incontravano solo come domanda scritta. Questi quattro
		# abbinamenti e i quattro smistamenti più sotto danno loro la mano.
		#
		# L'abbinamento è il formato giusto quando **due scritture diverse dicono
		# la stessa quantità**: 3 kg e 3000 g, 3/8 e 0,375, cateti 5 e 12 e
		# ipotenusa 13. Non si sceglie fra opzioni: si riconosce, e il
		# riconoscimento è esattamente la competenza.
		{"explanation": "Le tre scale non salgono con lo stesso passo: le lunghezze di dieci in dieci, le superfici di cento in cento, i volumi di mille in mille. Contare le dimensioni della grandezza dice quanti zeri servono.", "topic": "misure", "minLevel": 3, "pairs": [
			["4 cm", "40 mm"], ["2 m", "200 cm"], ["1 km", "1000 m"], ["0,5 m", "50 cm"],
			["3 kg", "3000 g"], ["250 g", "0,25 kg"], ["1 hg", "100 g"], ["2 l", "200 cl"],
			["mezzo litro", "500 cm³"], ["1 m²", "10000 cm²"], ["1 m³", "1000 dm³"],
			["1 ettaro", "10000 m²"], ["2 ore", "120 minuti"], ["mezz'ora", "1800 secondi"]]},
		# La frazione e il decimale sono la stessa quantità in due scritture: qui
		# si vedono una accanto all'altra, che è il modo più corto per capirlo.
		{"explanation": "Una frazione è una divisione non ancora fatta: 3/8 vuol dire tre diviso otto, e il risultato è 0,375. Quando sotto ci sono solo fattori due e cinque la divisione finisce; con il tre non finisce mai, e nasce il periodo.", "topic": "decimali", "minLevel": 8, "pairs": [
			["1/2", "0,5"], ["1/4", "0,25"], ["3/4", "0,75"], ["1/5", "0,2"],
			["2/5", "0,4"], ["3/5", "0,6"], ["1/8", "0,125"], ["3/8", "0,375"],
			["5/8", "0,625"], ["1/10", "0,1"], ["7/10", "0,7"], ["1/20", "0,05"],
			["1/3", "0,333…"], ["2/3", "0,666…"]]},
		{"explanation": "Nel cerchio ogni parte ha un nome preciso, e i nomi non sono etichette: dicono da dove parte e dove arriva il segmento. Il raggio parte dal centro, la corda no, e il diametro è la corda che passa proprio di lì.", "topic": "cerchio", "minLevel": 12, "pairs": [
			["raggio", "dal centro al bordo"],
			["diametro", "da un bordo all'altro passando per il centro"],
			["corda", "unisce due punti qualsiasi del bordo"],
			["arco", "un pezzo della linea curva"],
			["settore", "la fetta di torta fra due tagli dal centro"],
			["corona", "lo spazio fra due cerchi concentrici"],
			["circonferenza", "la linea chiusa che delimita la figura"],
			["π", "poco più di tre"],
			["il giro completo", "2 × π × raggio"],
			["la superficie interna", "π × raggio²"],
			["raddoppiare il raggio", "area quattro volte più grande"],
			["mezzo cerchio", "180°"]]},
		# Le terne pitagoriche: qui l'abbinamento OBBLIGA a fare il conto, perché
		# fra i risultati non c'è nessuna somma dei due cateti da riconoscere a
		# occhio. È il contrario del quesito a scelta multipla, dove il distrattore
		# più vicino si può escludere per esclusione.
		{"explanation": "L'ipotenusa non è la somma dei cateti: si sommano i loro quadrati e alla fine si estrae la radice. Alcune terne tornano intere e conviene riconoscerle a memoria — 3-4-5, 5-12-13, 8-15-17 — perché fanno risparmiare tutta l'operazione.", "topic": "pitagora", "minLevel": 12, "pairs": [
			["cateti 3 e 4", "ipotenusa 5"], ["cateti 6 e 8", "ipotenusa 10"],
			["cateti 5 e 12", "ipotenusa 13"], ["cateti 8 e 15", "ipotenusa 17"],
			["cateti 9 e 12", "ipotenusa 15"], ["cateti 12 e 16", "ipotenusa 20"],
			["cateti 7 e 24", "ipotenusa 25"], ["cateti 10 e 24", "ipotenusa 26"],
			["cateti 12 e 35", "ipotenusa 37"], ["cateti 20 e 21", "ipotenusa 29"]]},
		# Semplificare un radicale è un gesto ripetitivo che conviene automatizzare:
		# si scompone il numero, si cerca il quadrato più grande che ci sta dentro,
		# lo si porta fuori. Abbinare dodici radicali alla loro forma semplificata
		# fa fare dodici volte quel passaggio in un minuto.
		{"explanation": "Si cerca il quadrato più grande contenuto nel numero e lo si porta fuori diventando la sua radice: in √8 il quadrato è 4, che esce come 2, e resta dentro il 2. Il valore non cambia, cambia solo la scrittura — ed è quella scrittura che permette poi di sommare i radicali simili.", "topic": "radicali", "minLevel": 18, "pairs": [
			["√8", "2√2"], ["√12", "2√3"], ["√18", "3√2"], ["√20", "2√5"],
			["√27", "3√3"], ["√32", "4√2"], ["√45", "3√5"], ["√48", "4√3"],
			["√50", "5√2"], ["√72", "6√2"], ["√75", "5√3"], ["√98", "7√2"]]},
	],
	"logica": [
		# **Due abbinamenti che non si possono sapere a memoria.** (1 settembre 2026)
		#
		# Tolte le sei liste di vocabolario, alla logica restava un solo insieme
		# di abbinamento — e un formato con una specifica sola è un formato che si
		# impara a memoria alla seconda visita. Questi due portano dentro
		# l'abbinamento le due operazioni che la materia insegna davvero.
		#
		# **Perché qui non c'è la negazione dei quantificatori.** Ci ho provato:
		# «Tutti i gatti dormono» a sinistra, «Almeno un gatto non dorme» a
		# destra. Misurato con `scorciatoie_minigiochi_audit`: quarantasette punti
		# sopra il caso, la peggiore specifica del gioco. La ragione è strutturale
		# e non si aggira scrivendo meglio — negare conserva il predicato, quindi
		# «dorme» sta da tutte e due le parti e basta cercare quella parola per
		# accoppiare senza aver capito niente del quantificatore, che è invece
		# tutta la competenza. La negazione si insegna nello smistamento
		# («Ognuna di queste frasi è FALSA…»), dove il bidone è il quantificatore
		# della negazione e cercare la parola porta di proposito nel posto sbagliato.
		# SMENTIRE: una regola generale cade per UN caso solo, e trovare quel caso
		# è l'unica dimostrazione che serve. Qui la coppia è regola → il caso che
		# la fa cadere, e sapere il caso senza aver capito la regola non aiuta:
		# tutti i controesempi sono cose comuni, è il legame a non essere ovvio.
		{"explanation": "Per far cadere un «tutti» basta un caso solo: non serve dimostrare il contrario, serve trovare l'eccezione. È il motivo per cui smentire una regola generale costa pochissimo e dimostrarla costa moltissimo — un controesempio si mostra, mentre «tutti» andrebbe controllato uno per uno.", "topic": "verita", "pairs": [
			["Tutti gli uccelli volano", "il pinguino"],
			["Tutti i mammiferi vivono sulla terraferma", "la balena"],
			["Tutti i numeri primi sono dispari", "il 2"],
			["Tutti i rettangoli sono quadrati", "un foglio A4"],
			["Tutti i frutti crescono sugli alberi", "la fragola"],
			["Tutti i metalli sono attirati dalla calamita", "il rame"],
			["Tutti i mesi hanno trentun giorni", "febbraio"],
			["Tutte le figure a tre lati hanno un angolo retto", "un triangolo equilatero"],
			["Tutti i pianeti hanno gli anelli", "Marte"],
			["Tutti i numeri pari sono divisibili per quattro", "il 6"],
			["Tutte le piante sono verdi", "un fungo che marcisce"],
			["Tutti gli animali che volano sono uccelli", "il pipistrello"],
			["Tutte le parole italiane finiscono per vocale", "«per»"],
			["Tutti i quadrilateri hanno i lati uguali", "un trapezio"]]},
		# **Le stesse sei forme, un'altra storia.** (1 settembre 2026)
		#
		# Questo insieme è il gemello di quello qui sotto, e la somiglianza è il
		# punto: le sei forme del ragionamento sono sempre quelle, e riconoscerle
		# sotto vestiti diversi È la competenza — chi ha capito «tutti i gatti
		# hanno la coda» deve cavarsela identico con «tutti i corvi hanno le penne»,
		# altrimenti aveva imparato i gatti, non la forma.
		#
		# Stessa regola di scrittura: due proprietà sole (penne e squame), di UNA
		# parola ciascuna —
		# ciascuna presente in più carte da tutte e due le parti, così nessuna
		# coppia si azzecca cercando la parola condivisa.
		{"explanation": "La forma del ragionamento non cambia col cambiare delle parole: da una regola su TUTTI si scende sempre sul caso singolo, e si risale solo negando. Chi non porta il mantello non è del Nord; chi lo porta può essere di qualunque posto, perché la regola non dice che il mantello lo portino soltanto loro.", "topic": "deduzioni", "pairs": [
			["Tutti i corvi hanno le penne. Kira è un corvo.", "Kira ha le penne."],
			["Nessun corvo ha le squame. Kira è un corvo.", "Kira non ha le squame."],
			["Tutti i corvi hanno le penne. Kira non ha le penne.", "Kira non è un corvo."],
			["Tutti i corvi hanno le penne. Kira ha le penne.", "Non si può dire se Kira è un corvo."],
			["Tutti i corvi hanno le penne. Kira non è un corvo.", "Non si può dire se Kira ha le penne."],
			["Nessun corvo ha le squame. Kira non è un corvo.", "Non si può dire se Kira ha le squame."]]},
		# **L'abbinamento che si risolveva senza logica.** (1 settembre 2026)
		#
		# La versione precedente aveva sei premesse su sei argomenti diversi —
		# Micio, la strada, il tonno, il quadrato, l'esame, il 38 — e ogni
		# conclusione ripeteva la parola della sua premessa. Misurato: **sei
		# coppie su sei** si azzeccavano cercando la parola condivisa, senza
		# leggere un solo quantificatore. Era l'unico insieme di abbinamento con
		# logica vera dentro, ed era quello in cui la logica non serviva.
		#
		# Ora tutte e sei le premesse parlano di Micio, dei gatti e della coda:
		# la parola non distingue più niente e a decidere resta soltanto la FORMA
		# del ragionamento. Le sei forme sono le sei che contano — modus ponens,
		# negazione universale, modus tollens, affermazione del conseguente,
		# negazione dell'antecedente, quantificatore esistenziale — e le ultime
		# tre sono proprio quelle in cui non segue niente.
		#
		# Le proprietà in gioco sono DUE — la coda e le piume — e ciascuna compare
		# in almeno due carte da tutte e due le parti. Non è un dettaglio: con una
		# proprietà nominata una volta sola, la carta che la contiene si accoppia
		# per quella parola e basta. `scorciatoie_minigiochi_audit` misura proprio
		# questo, e con sei proprietà diverse l'insieme non passava.
		{"explanation": "Una deduzione è sicura solo quando la conclusione è già dentro le premesse. Da «tutti i gatti hanno la coda» si scende su un gatto, e si risale solo per negazione: chi NON ha la coda non è un gatto. Chi ce l'ha, invece, può essere qualunque cosa — e da «alcuni» non si conclude mai su un singolo.", "topic": "deduzioni", "pairs": [
			["Tutti i gatti hanno la coda. Micio è un gatto.", "Micio ha la coda."],
			["Nessun gatto ha le piume. Micio è un gatto.", "Micio non ha le piume."],
			["Tutti i gatti hanno la coda. Micio non ha la coda.", "Micio non è un gatto."],
			["Tutti i gatti hanno la coda. Micio ha la coda.", "Non si può dire se Micio è un gatto."],
			["Tutti i gatti hanno la coda. Micio non è un gatto.", "Non si può dire se Micio ha la coda."],
			["Nessun gatto ha le piume. Micio non è un gatto.", "Non si può dire se Micio ha le piume."]]},
	],
}

# Sequenze da ordinare, per materia (l'ordine dato è quello CORRETTO).
const ORDERING := {
	"scienze": [
		{"explanation": "La metamorfosi va in un verso solo e non torna indietro: ogni fase prepara la successiva, e l'insetto adulto è l'ultimo stadio, non il primo.", "topic": "viventi", "prompt": "Metti in ordine le fasi della farfalla", "correctOrder": ["Uovo", "Bruco", "Crisalide", "Farfalla"]},
		{"explanation": "Si ordina per temperatura, non per quanto «sembra caldo»: il ghiaccio che fonde sta a zero gradi, l'acqua che bolle a cento.", "topic": "materia", "prompt": "Ordina per temperatura crescente", "correctOrder": ["Ghiaccio", "Acqua fredda", "Acqua calda", "Vapore"]},
		{"explanation": "Il ciclo dell'acqua è un anello: il calore fa evaporare, l'aria fredda condensa, la pioggia restituisce l'acqua e si ricomincia.", "topic": "ciclo-acqua", "minLevel": 3, "prompt": "Ordina le fasi del ciclo dell'acqua.", "correctOrder": ["Evaporazione", "Condensazione", "Precipitazione", "Raccolta nei fiumi"]},
		{"explanation": "L'energia entra dalle piante e sale di anello in anello: si parte sempre da chi la produce, mai da chi la mangia.", "topic": "catena", "minLevel": 4, "prompt": "Ordina la catena alimentare, da chi produce energia a chi la mangia.", "correctOrder": ["Erba", "Cavalletta", "Rana", "Serpente", "Aquila"]},
		{"explanation": "Il metodo scientifico ha un ordine obbligato: prima si osserva, poi si suppone, poi si prova. Cambiare l'ordine significa cercare conferme invece di verità.", "topic": "metodo", "minLevel": 4, "prompt": "Ordina i passi del metodo scientifico.", "correctOrder": ["Fai una domanda", "Formula un'ipotesi", "Fai l'esperimento", "Osserva i risultati", "Trai la conclusione"]},
		# Scuola media — livelli di organizzazione dei viventi.
		{"explanation": "Ogni livello contiene il precedente: la cellula sta nel tessuto, il tessuto nell'organo. Si sale per contenimento, non per importanza.", "topic": "organizzazione", "minLevel": 7, "prompt": "Ordina dal più piccolo al più grande.", "correctOrder": ["Cellula", "Tessuto", "Organo", "Sistema", "Organismo"]},
		# Insieme a estrazione sulle dimensioni reali dei viventi (`value` in metri).
		# Ordinare esseri viventi per grandezza è biologia, non aritmetica: costringe
		# a farsi un'idea di scala, che è ciò che i numeri da soli non insegnano.
		{"explanation": "Si confrontano le dimensioni reali, non quanto se ne parla: un virus è centinaia di volte più piccolo di un batterio, e il batterio più piccolo di una cellula.", "topic": "organizzazione", "minLevel": 7, "kind": "pool", "draw": 4, "prompt": "Ordina questi viventi dal più piccolo al più grande.", "pool": [
			{"label": "Virus", "value": 0.0000001}, {"label": "Batterio", "value": 0.000002},
			{"label": "Globulo rosso", "value": 0.000007}, {"label": "Cellula vegetale", "value": 0.00005},
			{"label": "Acaro della polvere", "value": 0.0003}, {"label": "Pulce", "value": 0.002},
			{"label": "Formica", "value": 0.005}, {"label": "Ape", "value": 0.013},
			{"label": "Coccinella", "value": 0.007}, {"label": "Lombrico", "value": 0.12},
			{"label": "Topolino", "value": 0.08}, {"label": "Rana", "value": 0.09},
			{"label": "Passero", "value": 0.15}, {"label": "Scoiattolo", "value": 0.25},
			{"label": "Gatto", "value": 0.5}, {"label": "Cane pastore", "value": 0.9},
			{"label": "Essere umano", "value": 1.7}, {"label": "Cavallo", "value": 2.4},
			{"label": "Giraffa", "value": 5.5}, {"label": "Elefante africano", "value": 3.3},
			{"label": "Balenottera azzurra", "value": 30.0}, {"label": "Sequoia gigante", "value": 85.0}]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Un vivente cresce mettendo insieme pezzi sempre piu' grandi: le cellule fanno i tessuti, i tessuti gli organi, gli organi l'individuo. Saltare un gradino non si puo'.", "topic": "viventi", "prompt": "Ordina dal piu' piccolo al piu' grande.", "correctOrder": ["Cellula", "Tessuto", "Organo", "Organismo"]},
		{"explanation": "Il giorno e la notte non dipendono dal Sole che si muove ma dalla Terra che gira su se' stessa: e' sempre la stessa faccia a illuminarsi e a spegnersi.", "topic": "terra-universo", "prompt": "Ordina i momenti della giornata.", "correctOrder": ["Alba", "Mezzogiorno", "Tramonto", "Notte"]},
	],
	"geografia": [
		# Fasce 4, 5 e 7. Ordinare e' un ragionamento: si mette in fila per una
		# grandezza sola, e la grandezza va capita prima di poter confrontare.
		{"explanation": "I livelli del rilievo si contano dal mare in su, e ogni gradino ha un nome che dice un'altezza approssimativa: pianura sotto i 200 metri, collina fino a 600, poi la montagna.", "topic": "geografia-fisica", "minLevel": 11, "prompt": "Ordina dal punto piu' basso al piu' alto.", "correctOrder": ["Fondale marino", "Spiaggia", "Pianura", "Collina", "Alta montagna"]},
		{"explanation": "L'acqua compie sempre lo stesso giro, e ogni passaggio rende possibile il successivo: se ne salta uno, il ciclo si interrompe e la pioggia non arriva.", "topic": "geografia-fisica", "minLevel": 15, "prompt": "Ordina le fasi del ciclo dell'acqua.", "correctOrder": ["L'acqua evapora dal mare", "Il vapore sale e si raffredda", "Si formano le nuvole", "Cade la pioggia", "L'acqua torna al mare"]},
		{"explanation": "Le unita' amministrative si contengono una dentro l'altra come scatole: sapere l'ordine serve a leggere qualunque indirizzo e qualunque dato statistico.", "topic": "geografia-italia", "minLevel": 20, "prompt": "Ordina dall'unita' piu' piccola alla piu' grande.", "correctOrder": ["Quartiere", "Comune", "Provincia", "Regione", "Stato"]},
		# L21. Estensione degli Stati in milioni di km². Scelti bene distanziati:
		# ordinare Canada e Stati Uniti sarebbe memoria di un numero, non geografia.
		{"explanation": "Si guarda la superficie in chilometri quadrati, non la popolazione né la fama: un Paese può essere piccolo e importante.", "topic": "geografia-umana", "minLevel": 21, "kind": "pool", "prompt": "Ordina questi Stati per superficie crescente (in milioni di km²).", "pool": [
			{"label": "Italia", "value": 0.30}, {"label": "Egitto", "value": 1.00},
			{"label": "Perù", "value": 1.28}, {"label": "Iran", "value": 1.65},
			{"label": "Messico", "value": 1.96}, {"label": "Algeria", "value": 2.38},
			{"label": "Argentina", "value": 2.78}, {"label": "India", "value": 3.29},
			{"label": "Australia", "value": 7.69}, {"label": "Brasile", "value": 8.52},
			{"label": "Canada", "value": 9.98}, {"label": "Russia", "value": 17.10}]},
		# L'ordinamento di geografia aveva una specifica sola ai primi due mondi.
		# Qui l'ordine è una grandezza (la latitudine) ma si ricava dalla carta
		# mentale dell'Italia, non da un numero da ricordare.
		{"explanation": "Si guarda la latitudine sulla carta, non la distanza percorsa in strada: da sud a nord si risale la penisola.", "topic": "italia-fisica", "kind": "pool", "prompt": "Ordina queste città italiane da sud a nord.", "pool": [
			{"label": "Palermo", "value": 38.1}, {"label": "Cosenza", "value": 39.3},
			{"label": "Napoli", "value": 40.8}, {"label": "Roma", "value": 41.9},
			{"label": "Firenze", "value": 43.8}, {"label": "Bologna", "value": 44.5},
			{"label": "Milano", "value": 45.5}, {"label": "Bolzano", "value": 46.5}]},
		{"explanation": "Si confronta la stessa grandezza per tutti, dall'unità più piccola alla più grande: cambiare unità a metà confronto è l'errore da evitare.", "topic": "geografia-umana", "prompt": "Ordina dal più piccolo al più grande", "correctOrder": ["Paese", "Regione", "Nazione", "Continente"]},
		{"explanation": "Un fiume ha un verso obbligato: nasce in alto alla sorgente, raccoglie affluenti scendendo e finisce alla foce, dove incontra il mare.", "topic": "geografia-fisica", "minLevel": 3, "prompt": "Ordina il corso di un fiume, dalla nascita al mare.", "correctOrder": ["Sorgente", "Torrente", "Fiume", "Foce"]},
		{"explanation": "Si ordina per estensione, confrontando la stessa unità di misura per ogni elemento.", "topic": "geografia-umana", "minLevel": 4, "prompt": "Ordina dal più piccolo al più grande.", "correctOrder": ["Via", "Quartiere", "Città", "Regione"]},
		# Insiemi a estrazione: in geografia quasi ogni ordine è una GRANDEZZA —
		# altezza in metri, lunghezza in chilometri, abitanti. È lo stesso motivo per
		# cui la cronologia funziona in storia: c'è un numero vero sotto l'etichetta.
		{"explanation": "Si confrontano le quote in metri: la cima più alta non è per forza la più famosa né la più difficile.", "topic": "italia-fisica", "minLevel": 6, "kind": "pool", "draw": 4, "prompt": "Ordina le cime per altezza crescente (in metri).", "pool": [
			{"label": "Monte Bianco", "value": 4808.0}, {"label": "Monte Rosa", "value": 4634.0},
			{"label": "Cervino", "value": 4478.0}, {"label": "Gran Paradiso", "value": 4061.0},
			{"label": "Ortles", "value": 3905.0}, {"label": "Marmolada", "value": 3343.0},
			{"label": "Gran Sasso", "value": 2912.0}, {"label": "Etna", "value": 3357.0},
			{"label": "Monte Cimone", "value": 2165.0}, {"label": "Monte Terminillo", "value": 2217.0},
			{"label": "Monte Amiata", "value": 1738.0}, {"label": "Vesuvio", "value": 1281.0},
			{"label": "Monte Titano", "value": 749.0}, {"label": "Colli Euganei", "value": 601.0},
			{"label": "Vulture", "value": 1326.0}, {"label": "Monte Baldo", "value": 2218.0},
			{"label": "Punta La Marmora", "value": 1834.0}, {"label": "Monte Pollino", "value": 2248.0},
			{"label": "Monte Velino", "value": 2487.0}, {"label": "Monte Grappa", "value": 1775.0}]},
		{"explanation": "Si confronta la lunghezza del corso in chilometri, non la portata d'acqua né l'importanza storica.", "topic": "geografia-fisica", "minLevel": 5, "kind": "pool", "draw": 4, "prompt": "Ordina i fiumi per lunghezza crescente (in chilometri).", "pool": [
			{"label": "Arno", "value": 241.0}, {"label": "Tevere", "value": 405.0},
			{"label": "Po", "value": 652.0}, {"label": "Adige", "value": 410.0},
			{"label": "Piave", "value": 220.0}, {"label": "Ticino", "value": 248.0},
			{"label": "Senna", "value": 777.0}, {"label": "Tamigi", "value": 346.0},
			{"label": "Reno (europeo)", "value": 1233.0}, {"label": "Elba", "value": 1091.0},
			{"label": "Danubio", "value": 2860.0}, {"label": "Volga", "value": 3530.0},
			{"label": "Gange", "value": 2525.0}, {"label": "Indo", "value": 3180.0},
			{"label": "Mekong", "value": 4350.0}, {"label": "Yangtze", "value": 6300.0},
			{"label": "Nilo", "value": 6650.0}, {"label": "Rio delle Amazzoni", "value": 6400.0},
			{"label": "Mississippi", "value": 3770.0}, {"label": "Congo", "value": 4700.0}]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Le divisioni del territorio stanno una dentro l'altra come scatole: ogni livello contiene tutti quelli piu' piccoli.", "topic": "geografia-italia", "prompt": "Ordina dal piu' piccolo al piu' grande.", "correctOrder": ["Comune", "Provincia", "Regione", "Stato"]},
	],
	"musica": [
		# L22. Gli intervalli misurati in semitoni: qui l'ordine è una grandezza
		# esatta, e capire che la quarta giusta vale cinque semitoni e non quattro
		# è il passaggio da «contare i nomi» a «contare le distanze».
		{"explanation": "L'ampiezza di un intervallo si conta in semitoni, non in nomi di nota: fra due note vicine può esserci un semitono o due.", "topic": "intervalli", "minLevel": 22, "kind": "pool", "prompt": "Ordina gli intervalli dal più stretto al più ampio (in semitoni).", "pool": [
			{"label": "Seconda minore", "value": 1.0}, {"label": "Seconda maggiore", "value": 2.0},
			{"label": "Terza minore", "value": 3.0}, {"label": "Terza maggiore", "value": 4.0},
			{"label": "Quarta giusta", "value": 5.0}, {"label": "Tritono", "value": 6.0},
			{"label": "Quinta giusta", "value": 7.0}, {"label": "Sesta minore", "value": 8.0},
			{"label": "Sesta maggiore", "value": 9.0}, {"label": "Settima minore", "value": 10.0},
			{"label": "Settima maggiore", "value": 11.0}, {"label": "Ottava", "value": 12.0}]},
		{"explanation": "Le sette note girano sempre nello stesso ordine e poi ricominciano: è un anello, non una fila che finisce.", "topic": "note", "prompt": "Metti in ordine le note dopo il Do", "correctOrder": ["Re", "Mi", "Fa", "Sol"]},
		{"explanation": "Ogni figura vale la metà della precedente: il rapporto fra le durate è sempre di due, mai di uno.", "topic": "ritmo", "prompt": "Ordina dalla durata più breve alla più lunga", "correctOrder": ["Croma", "Semiminima", "Minima", "Semibreve"]},
		{"explanation": "La scala procede per gradi vicini, senza salti: è questo che la rende una scala e non un arpeggio.", "topic": "note", "minLevel": 3, "prompt": "Ordina la scala musicale completa, dal Do.", "correctOrder": ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]},
		# Scuola media — dinamiche dal più piano al più forte, tempi dal più lento.
		{"explanation": "La dinamica cresce per gradi con nomi propri, e i gradi sono più di cinque: fra il piano e il forte ci sono il mezzopiano e il mezzoforte, e agli estremi si arriva a tre lettere. Ordinare vuol dire sapere dove sta ognuno, non ricordare un elenco.", "topic": "dinamica", "minLevel": 5, "kind": "pool", "draw": 4, "prompt": "Ordina le dinamiche dalla più piano alla più forte.", "pool": [
			{"label": "pianississimo (ppp)", "value": 1.0}, {"label": "pianissimo (pp)", "value": 2.0},
			{"label": "piano (p)", "value": 3.0}, {"label": "mezzopiano (mp)", "value": 4.0},
			{"label": "mezzoforte (mf)", "value": 5.0}, {"label": "forte (f)", "value": 6.0},
			{"label": "fortissimo (ff)", "value": 7.0}, {"label": "fortississimo (fff)", "value": 8.0}]},
		{"explanation": "Ogni figura vale il doppio di quella dopo: la semibreve vale due minime, la minima due semiminime, e così via. Ordinare le durate è leggere quel dimezzamento, non ricordare i nomi.", "topic": "ritmo", "kind": "pool", "draw": 4, "prompt": "Ordina le figure dalla durata più breve alla più lunga.", "pool": [
			{"label": "semibiscroma", "value": 0.125}, {"label": "biscroma", "value": 0.25},
			{"label": "semicroma", "value": 0.5}, {"label": "croma", "value": 1.0},
			{"label": "semiminima", "value": 2.0}, {"label": "semiminima puntata", "value": 3.0},
			{"label": "minima", "value": 4.0}, {"label": "minima puntata", "value": 6.0},
			{"label": "semibreve", "value": 8.0}]},
		# I termini italiani di tempo hanno un valore vero: i battiti al minuto. Sono
		# la stessa scala che il metronomo mostra, quindi ordinarli è leggere una
		# grandezza, non ricordare un elenco.
		{"explanation": "I termini di tempo formano una scala continua dal più lento al più veloce: sono parole italiane usate in tutto il mondo proprio per non doverle tradurre.", "topic": "tempo", "minLevel": 5, "kind": "pool", "draw": 4, "prompt": "Ordina i tempi dal più lento al più veloce.", "pool": [
			{"label": "Grave", "value": 40.0}, {"label": "Largo", "value": 50.0},
			{"label": "Lento", "value": 55.0}, {"label": "Adagio", "value": 66.0},
			{"label": "Larghetto", "value": 63.0}, {"label": "Andante", "value": 80.0},
			{"label": "Andantino", "value": 88.0}, {"label": "Moderato", "value": 100.0},
			{"label": "Allegretto", "value": 112.0}, {"label": "Allegro", "value": 130.0},
			{"label": "Vivace", "value": 150.0}, {"label": "Presto", "value": 175.0},
			{"label": "Prestissimo", "value": 200.0}, {"label": "Adagietto", "value": 72.0},
			{"label": "Allegro molto", "value": 140.0}, {"label": "Largamente", "value": 46.0}]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Le figure musicali si dimezzano l'una dopo l'altra: ogni durata vale la meta' di quella prima, ed e' per questo che si incastrano sempre in una battuta.", "topic": "ritmo", "prompt": "Ordina le figure dalla piu' lunga alla piu' breve.", "correctOrder": ["Semibreve", "Minima", "Semiminima", "Croma"]},
	],
	"italiano": [
		# Insieme a estrazione: si pescano 4 parole fra trentadue e si ordinano per
		# `value`, che è il posto della parola nel dizionario. Trentadue parole
		# danno C(32,4) = 35.960 prove diverse da una sola specifica — ed è il
		# motivo per cui i valori sono scritti a mano invece che calcolati: qui
		# l'ordine alfabetico è il CONTENUTO della prova, quindi va autorato e
		# controllato, non dedotto a runtime da una funzione di confronto.
		{"explanation": "L'ordine alfabetico si decide sulla prima lettera diversa: se le prime coincidono si passa alla seconda, e così via.", "topic": "ortografia", "kind": "pool", "draw": 4, "prompt": "Metti le parole in ordine alfabetico.", "pool": [
			{"label": "albero", "value": 1.0}, {"label": "amico", "value": 2.0},
			{"label": "barca", "value": 3.0}, {"label": "bosco", "value": 4.0},
			{"label": "casa", "value": 5.0}, {"label": "chiave", "value": 6.0},
			{"label": "denaro", "value": 7.0}, {"label": "dono", "value": 8.0},
			{"label": "elmo", "value": 9.0}, {"label": "erba", "value": 10.0},
			{"label": "faro", "value": 11.0}, {"label": "fiore", "value": 12.0},
			{"label": "gatto", "value": 13.0}, {"label": "giorno", "value": 14.0},
			{"label": "isola", "value": 15.0}, {"label": "lampada", "value": 16.0},
			{"label": "luna", "value": 17.0}, {"label": "mare", "value": 18.0},
			{"label": "monte", "value": 19.0}, {"label": "nave", "value": 20.0},
			{"label": "nube", "value": 21.0}, {"label": "ombra", "value": 22.0},
			{"label": "porta", "value": 23.0}, {"label": "quaderno", "value": 24.0},
			{"label": "ramo", "value": 25.0}, {"label": "rosa", "value": 26.0},
			{"label": "sole", "value": 27.0}, {"label": "strada", "value": 28.0},
			{"label": "tempo", "value": 29.0}, {"label": "torre", "value": 30.0},
			{"label": "vento", "value": 31.0}, {"label": "voce", "value": 32.0}]},
		{"explanation": "In italiano l'ordine normale è soggetto, verbo, complemento. Si può cambiare per dare enfasi, ma la frase base segue questo.", "topic": "sintassi", "prompt": "Riordina le parole per formare una frase corretta.", "correctOrder": ["Il", "gatto", "dorme", "sul", "divano"]},
		{"explanation": "Si parte dal soggetto e si cerca il verbo che gli si accorda: il resto della frase si dispone attorno a quei due.", "topic": "sintassi", "prompt": "Riordina le parole per formare una frase corretta.", "correctOrder": ["Domani", "andremo", "tutti", "al", "mare"]},
		{"explanation": "Una storia ha un ordine di causa: ogni evento è possibile solo perché è successo quello prima. Se si può scambiare, non era una storia.", "topic": "testo-narrativo", "prompt": "Metti in ordine gli eventi della storia.", "correctOrder": ["C'era una volta un re", "Il re partì per un lungo viaggio", "Incontrò un drago feroce", "Con astuzia lo sconfisse", "Tornò a casa vittorioso"]},
		# **Il tempo verbale come unico indizio.** (9 settembre 2026) Fascia 8.
		#
		# Qui le frasi non raccontano una storia: sono scollegate apposta, così
		# l'ordine non si indovina dal senso. L'unica cosa che dice quale viene
		# prima è il TEMPO del verbo — trapassato, passato, presente, futuro — ed
		# è esattamente la competenza che `concordanza-tempi-verbali` chiede e che
		# finora si poteva solo crocettare.
		{"explanation": "Il trapassato racconta ciò che era già successo prima di un altro fatto passato; poi vengono il passato prossimo, il presente e il futuro. Quando le frasi non si tengono per il senso, l'ordine lo dà soltanto il tempo del verbo.", "topic": "concordanza-tempi-verbali", "minLevel": 22, "kind": "pool", "draw": 4, "prompt": "Metti le frasi in ordine di tempo, dalla più lontana alla più vicina. Guarda solo il verbo.", "pool": [
			{"label": "Avevo già chiuso la finestra", "value": 1.0},
			{"label": "Era partito da un pezzo", "value": 2.0},
			{"label": "Aveva finito prima degli altri", "value": 3.0},
			{"label": "Ho chiuso la finestra", "value": 4.0},
			{"label": "Sono partito stamattina", "value": 5.0},
			{"label": "Ha finito poco fa", "value": 6.0},
			{"label": "Chiudo la finestra", "value": 7.0},
			{"label": "Parto adesso", "value": 8.0},
			{"label": "Finisce in questo momento", "value": 9.0},
			{"label": "Chiuderò la finestra", "value": 10.0},
			{"label": "Partirò domani", "value": 11.0},
			{"label": "Finirà la settimana prossima", "value": 12.0}]},
	],
	"coding": [
		{"explanation": "Un programma esegue una riga per volta dall'alto in basso: un'istruzione che usa un valore deve venire dopo quella che lo crea.", "topic": "algoritmi", "prompt": "Ordina i passi del programma", "correctOrder": ["Chiedi il numero", "Controlla se è pari", "Se è pari stampa 'pari'", "Altrimenti stampa 'dispari'"]},
		{"explanation": "Prima si prende il dato, poi lo si trasforma, infine si mostra il risultato: leggere, calcolare, stampare.", "topic": "sequenza", "prompt": "Ordina le istruzioni per mostrare il doppio di un numero.", "correctOrder": ["Chiedi un numero", "Salvalo nella variabile n", "Calcola n × 2", "Mostra il risultato"]},
		# Pensiero computazionale "unplugged": la vita quotidiana come algoritmo.
		{"explanation": "Un algoritmo va scritto in un ordine eseguibile davvero: non si versa l'acqua prima di averla scaldata.", "topic": "algoritmi", "minLevel": 2, "prompt": "Ordina i passi dell'algoritmo per fare un tè.", "correctOrder": ["Scalda l'acqua", "Metti la bustina nella tazza", "Versa l'acqua calda", "Aspetta due minuti", "Togli la bustina"]},
		{"explanation": "Per trovare il massimo si parte da un candidato e lo si confronta con tutti gli altri, sostituendolo ogni volta che se ne trova uno più grande.", "topic": "algoritmi", "minLevel": 5, "prompt": "Ordina i passi per trovare il numero più grande in una lista.", "correctOrder": ["Prendi il primo numero come massimo", "Guarda il numero successivo", "Se è più grande, aggiorna il massimo", "Ripeti fino alla fine", "Restituisci il massimo"]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Un programma si scrive in quest'ordine perche' ogni passo ha bisogno del precedente: senza il dato non c'e' niente da calcolare, e senza il calcolo non c'e' niente da mostrare.", "topic": "algoritmi", "prompt": "Ordina i passi di un programma che saluta chi lo usa.", "correctOrder": ["Chiedi il nome", "Salva il nome in una variabile", "Componi il saluto", "Mostra il saluto"]},
	],
	"storia": [
		# L14. Il Novecento: l'ordine è una grandezza (l'anno) e i fatti sono quelli
		# che a tredici anni si studiano davvero.
		{"explanation": "Si ordina per data, dalla più lontana alla più vicina a noi: la cronologia non guarda l'importanza dei fatti.", "topic": "cronologia", "minLevel": 14, "kind": "pool", "prompt": "Ordina gli eventi del Novecento dal più antico al più recente.", "pool": [
			{"label": "Inizia la prima guerra mondiale", "value": 1914.0},
			{"label": "Rivoluzione russa", "value": 1917.0},
			{"label": "Marcia su Roma", "value": 1922.0},
			{"label": "Crollo della borsa di Wall Street", "value": 1929.0},
			{"label": "Inizia la seconda guerra mondiale", "value": 1939.0},
			{"label": "Attacco a Pearl Harbor", "value": 1941.0},
			{"label": "Sbarco in Normandia", "value": 1944.0},
			{"label": "Bomba atomica su Hiroshima", "value": 1945.0},
			{"label": "L'Italia diventa una repubblica", "value": 1946.0},
			{"label": "Entra in vigore la Costituzione italiana", "value": 1948.0},
			{"label": "Trattati di Roma", "value": 1957.0},
			{"label": "Viene costruito il muro di Berlino", "value": 1961.0},
			{"label": "Primo uomo sulla Luna", "value": 1969.0},
			{"label": "Cade il muro di Berlino", "value": 1989.0},
			{"label": "Si scioglie l'Unione Sovietica", "value": 1991.0},
			{"label": "Nasce l'Unione Europea", "value": 1993.0}]},
		# L24. L'ultimo mondo: cinque secoli di invenzioni in fila. Chiude il
		# percorso di storia con la domanda che lo attraversa tutto — cosa è venuto
		# prima di cosa, e quanto in fretta le cose hanno cominciato ad accelerare.
		{"explanation": "Ogni invenzione poggia su quelle prima: il telescopio ha bisogno delle lenti, la macchina a vapore della metallurgia.", "topic": "cronologia", "minLevel": 24, "kind": "pool", "prompt": "Ordina le invenzioni dalla più antica alla più recente.", "pool": [
			{"label": "Stampa a caratteri mobili", "value": 1455.0},
			{"label": "Telescopio", "value": 1608.0},
			{"label": "Macchina a vapore", "value": 1712.0},
			{"label": "Vaccino", "value": 1796.0},
			{"label": "Treno a vapore", "value": 1825.0},
			{"label": "Fotografia", "value": 1826.0},
			{"label": "Telefono", "value": 1876.0},
			{"label": "Lampadina", "value": 1879.0},
			{"label": "Automobile", "value": 1886.0},
			{"label": "Radio", "value": 1895.0},
			{"label": "Aeroplano", "value": 1903.0},
			{"label": "Televisione", "value": 1926.0},
			{"label": "Penicillina", "value": 1928.0},
			{"label": "Computer elettronico", "value": 1946.0},
			{"label": "Satellite artificiale", "value": 1957.0},
			{"label": "Internet", "value": 1969.0},
			{"label": "Telefono cellulare", "value": 1973.0},
			{"label": "World Wide Web", "value": 1989.0}]},
		{"explanation": "Le grandi età si succedono per fatti precisi che le aprono e le chiudono, non per durata: alcune durano millenni, altre pochi secoli.", "topic": "ere", "prompt": "Ordina le grandi età della storia, dalla più antica.", "correctOrder": ["Preistoria", "Età antica", "Medioevo", "Età moderna", "Età contemporanea"]},
		# Insieme cronologico PER I PRIMI MONDI. L'insieme grande (28 eventi, più
		# sotto) parte dal mondo 6 perché contiene date che a dieci anni non si
		# possono conoscere: pescandone tre a caso poteva uscire «Hammurabi, prima
		# crociata, peste nera», che non è una prova difficile ma una prova
		# impossibile. Qui gli eventi sono pochi, notissimi e molto distanti fra
		# loro: l'ordine si ricava dal senso storico, non dalla memoria delle date.
		{"explanation": "Si va dal più lontano al più vicino: davanti sta ciò che è successo prima, anche quando lo conosciamo peggio.", "topic": "cronologia", "kind": "pool", "draw": 3,
			"prompt": "Ordina questi eventi dal più antico al più recente.", "pool": [
			{"label": "Gli uomini vivevano nelle caverne", "value": -30000.0},
			{"label": "Nascono l'agricoltura e i primi villaggi", "value": -9000.0},
			{"label": "Vengono costruite le piramidi d'Egitto", "value": -2560.0},
			{"label": "Si disputano i primi Giochi olimpici", "value": -776.0},
			{"label": "Viene fondata Roma", "value": -753.0},
			{"label": "Ad Atene nasce la democrazia", "value": -508.0},
			{"label": "Giulio Cesare conquista la Gallia", "value": -52.0},
			{"label": "Il Vesuvio seppellisce Pompei", "value": 79.0},
			{"label": "Cade l'Impero Romano d'Occidente", "value": 476.0},
			{"label": "Si costruiscono i castelli e le cattedrali", "value": 1200.0},
			{"label": "Marco Polo arriva in Cina", "value": 1271.0},
			{"label": "Colombo arriva in America", "value": 1492.0},
			{"label": "Nasce il Regno d'Italia", "value": 1861.0},
			{"label": "Si costruiscono le prime automobili", "value": 1890.0},
			{"label": "Scoppia la Prima guerra mondiale", "value": 1914.0},
			{"label": "L'uomo cammina sulla Luna", "value": 1969.0}]},
		{"explanation": "I periodi della preistoria si distinguono da come veniva lavorata la pietra: prima scheggiata, poi levigata, poi sostituita dai metalli.", "topic": "preistoria", "minLevel": 4, "prompt": "Ordina i periodi della preistoria, dal più antico.", "correctOrder": ["Paleolitico", "Neolitico", "Età dei metalli"]},
		{"explanation": "Roma cambia forma di governo tre volte: prima i re, poi la repubblica, infine l'impero. L'ordine è quello, e ogni passaggio nasce dalla crisi del precedente.", "topic": "roma", "minLevel": 18, "prompt": "Ordina le fasi della storia di Roma.", "correctOrder": ["Monarchia", "Repubblica", "Impero"]},
		# Scuola media — ordinare eventi lontani per data.
		#
		# Il caso in cui l'ordinamento si parametrizza meglio di ogni altro: l'ordine
		# giusto NON è una convenzione da ricordare, è una proprietà misurabile
		# (l'anno). Ventotto eventi danno C(28,4) = 20.475 prove diverse, e ogni
		# estrazione è una domanda storica sensata perché la linea del tempo è una
		# sola. `value` è l'anno con segno: negativo prima di Cristo.
		{"explanation": "Si confrontano le date fra loro: quando mancano i numeri esatti si ragiona su cosa rese possibile cosa.", "topic": "cronologia", "minLevel": 6, "kind": "pool", "draw": 4,
			"prompt": "Ordina questi eventi dal più antico al più recente.", "pool": [
			{"label": "Prime pitture rupestri", "value": -30000.0},
			{"label": "Nascita dell'agricoltura", "value": -9000.0},
			{"label": "Prime città sumere", "value": -3500.0},
			{"label": "Invenzione della scrittura", "value": -3200.0},
			{"label": "Costruzione delle piramidi di Giza", "value": -2560.0},
			{"label": "Codice di Hammurabi", "value": -1750.0},
			{"label": "Guerra di Troia (tradizione)", "value": -1200.0},
			{"label": "Primi Giochi olimpici", "value": -776.0},
			{"label": "Fondazione di Roma (tradizione)", "value": -753.0},
			{"label": "Nascita della democrazia ad Atene", "value": -508.0},
			{"label": "Costruzione del Partenone", "value": -447.0},
			{"label": "Impero di Alessandro Magno", "value": -330.0},
			{"label": "Cesare conquista la Gallia", "value": -52.0},
			{"label": "Augusto primo imperatore", "value": -27.0},
			{"label": "Nascita di Cristo", "value": 0.0},
			{"label": "Eruzione che seppellisce Pompei", "value": 79.0},
			{"label": "Inaugurazione del Colosseo", "value": 80.0},
			{"label": "Caduta dell'Impero Romano d'Occidente", "value": 476.0},
			{"label": "Incoronazione di Carlo Magno", "value": 800.0},
			{"label": "Prima crociata", "value": 1096.0},
			{"label": "Viaggio di Marco Polo in Cina", "value": 1271.0},
			{"label": "La peste nera in Europa", "value": 1347.0},
			{"label": "Stampa a caratteri mobili di Gutenberg", "value": 1455.0},
			{"label": "Colombo arriva in America", "value": 1492.0},
			{"label": "Rivoluzione francese", "value": 1789.0},
			{"label": "Unità d'Italia", "value": 1861.0},
			{"label": "Prima guerra mondiale", "value": 1914.0},
			{"label": "Primo uomo sulla Luna", "value": 1969.0}]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Le eta' della preistoria prendono il nome dal materiale che si sapeva lavorare: ogni passaggio e' una tecnica nuova, non un capriccio degli storici.", "topic": "preistoria", "prompt": "Ordina le eta' della preistoria, dalla piu' antica.", "correctOrder": ["Pietra antica", "Pietra nuova", "Eta' del rame", "Eta' del bronzo", "Eta' del ferro"]},
	],
	"latino": [
		# Fasce 4-8, scritte il 9 settembre 2026. La frase da rimontare cresce con
		# il grado: prima soggetto-oggetto-verbo, poi il complemento, poi la
		# subordinata. E' l'unico modo di chiedere la sintassi latina senza
		# chiedere di produrre forme, che senza tavola non si deducono.
		{"explanation": "Con un complemento in piu' la frase resta leggibile solo se si riconosce il caso: «in silva» dice dove, e sta fra l'oggetto e il verbo senza spostare nessun ruolo.", "topic": "frasi", "minLevel": 10, "prompt": "Ordina la frase latina: «il contadino vede il lupo nel bosco».", "correctOrder": ["Agricola", "lupum", "in silva", "videt"]},
		{"explanation": "Il genitivo si appoggia alla parola che possiede e la segue: «la figlia del contadino» diventa «filia agricolae», e il gruppo resta unito quando la frase si allunga.", "topic": "frasi", "minLevel": 13, "prompt": "Ordina la frase latina: «la figlia del contadino porta l'acqua».", "correctOrder": ["Filia", "agricolae", "aquam", "portat"]},
		{"explanation": "Con due complementi l'ordine abituale mette prima il termine e poi il mezzo, ma sono le desinenze a stabilire i ruoli: spostarli non cambierebbe il senso, solo l'enfasi.", "topic": "frasi", "minLevel": 17, "prompt": "Ordina la frase latina: «il servo porta una lettera al padrone con il cavallo».", "correctOrder": ["Servus", "domino", "epistulam", "equo", "portat"]},
		{"explanation": "La subordinata temporale precede la principale e ha un verbo suo: si riconosce dalla congiunzione iniziale, ed e' il primo passo verso il periodo latino vero.", "topic": "frasi", "minLevel": 22, "prompt": "Ordina il periodo latino: «quando il console arriva, i soldati lodano».", "correctOrder": ["Cum", "consul", "venit", "milites", "laudant"]},
		{"explanation": "In latino il verbo va di solito in fondo: la frase si costruisce soggetto, oggetto, verbo, ed è la differenza più visibile rispetto all'italiano.", "topic": "frasi", "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «la fanciulla ama la rosa»", "correctOrder": ["Puella", "rosam", "amat"]},
		{"explanation": "Il verbo chiude la frase latina. Il caso dice già chi fa e chi subisce, quindi l'ordine può permettersi di essere diverso dal nostro.", "topic": "frasi", "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «il contadino ama la terra»", "correctOrder": ["Agricola", "terram", "amat"]},
		{"explanation": "Soggetto in nominativo, oggetto in accusativo, verbo alla fine: le desinenze reggono il senso, la posizione lo conferma.", "topic": "frasi", "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «la regina guarda la luna»", "correctOrder": ["Regina", "lunam", "spectat"]},
		{"explanation": "L'ordine tipico è soggetto, oggetto, verbo. In latino spostare le parole cambia l'enfasi, non chi fa che cosa: a quello pensano i casi.", "topic": "frasi", "minLevel": 4, "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «il poeta ama la patria»", "correctOrder": ["Poeta", "patriam", "amat"]},
		# L'ordinamento di latino aveva UNA specifica al primo mondo, cioè una prova
		# sola: sempre «Puella rosam amat». La Fase 3 aveva concluso che in latino
		# l'ordine è convenzione pura e quindi non si parametrizza — vero per i casi
		# e per le parole di una frase, ma non per i NUMERI ROMANI, dove l'ordine è
		# una grandezza misurabile. È esattamente il criterio del progetto, e qui
		# vale: da venti numerali escono più di mille prove, tutte sensate.
		{"explanation": "I numeri romani si leggono sommando, ma un simbolo minore prima di uno maggiore si sottrae: IV è cinque meno uno.", "topic": "numeri", "kind": "pool", "prompt": "Ordina i numeri romani dal più piccolo al più grande.", "pool": [
			{"label": "I", "value": 1.0}, {"label": "II", "value": 2.0},
			{"label": "III", "value": 3.0}, {"label": "IV", "value": 4.0},
			{"label": "V", "value": 5.0}, {"label": "VI", "value": 6.0},
			{"label": "VII", "value": 7.0}, {"label": "VIII", "value": 8.0},
			{"label": "IX", "value": 9.0}, {"label": "X", "value": 10.0},
			{"label": "XI", "value": 11.0}, {"label": "XII", "value": 12.0},
			{"label": "XIII", "value": 13.0}, {"label": "XIV", "value": 14.0},
			{"label": "XV", "value": 15.0}, {"label": "XVI", "value": 16.0},
			{"label": "XVII", "value": 17.0}, {"label": "XVIII", "value": 18.0},
			{"label": "XIX", "value": 19.0}, {"label": "XX", "value": 20.0}]},
		# Dal mondo 5 entrano le cifre alte e le forme sottrattive (XL, XC, CD, CM),
		# che sono la parte davvero difficile della numerazione romana.
		{"explanation": "Con numeri più grandi la regola resta: si sottrae solo il simbolo che precede uno maggiore, e mai più di uno per volta.", "topic": "numeri", "minLevel": 5, "kind": "pool", "prompt": "Ordina i numeri romani dal più piccolo al più grande.", "pool": [
			{"label": "IV", "value": 4.0}, {"label": "IX", "value": 9.0},
			{"label": "XIV", "value": 14.0}, {"label": "XIX", "value": 19.0},
			{"label": "XXIV", "value": 24.0}, {"label": "XXX", "value": 30.0},
			{"label": "XXXIX", "value": 39.0}, {"label": "XL", "value": 40.0},
			{"label": "XLV", "value": 45.0}, {"label": "L", "value": 50.0},
			{"label": "LX", "value": 60.0}, {"label": "LXX", "value": 70.0},
			{"label": "LXXX", "value": 80.0}, {"label": "XC", "value": 90.0},
			{"label": "XCIX", "value": 99.0}, {"label": "C", "value": 100.0},
			{"label": "CL", "value": 150.0}, {"label": "CC", "value": 200.0},
			{"label": "CD", "value": 400.0}, {"label": "D", "value": 500.0},
			{"label": "DC", "value": 600.0}, {"label": "CM", "value": 900.0},
			{"label": "M", "value": 1000.0}, {"label": "MM", "value": 2000.0}]},
		# Scuola media — l'ordine tradizionale dei casi (come sul libro).
		{"explanation": "L'ordine tradizionale dei casi non è casuale: mette vicini quelli che spesso hanno la stessa forma, e per questo si impara in fila.", "topic": "casi", "minLevel": 5, "prompt": "Ordina i casi latini nell'ordine tradizionale.", "correctOrder": ["Nominativo", "Genitivo", "Dativo", "Accusativo", "Vocativo", "Ablativo"]},
	],
	"inglese": [
		{"explanation": "In inglese l'ordine è rigido: soggetto, verbo, complemento. Non essendoci i casi, è la posizione a dire chi fa che cosa.", "topic": "everyday-phrases", "prompt": "Order the words to make a sentence", "correctOrder": ["I", "like", "green", "apples"]},
		# Insieme a estrazione: i numeri scritti a parole, ordinati per valore.
		# Ventiquattro voci → C(24,4) = 10.626 prove. Il riordino di una frase non
		# si può parametrizzare (l'ordine è quello di QUELLA frase); i numeri sì, e
		# sono contenuto d'inglese vero quanto il word order.
		{"explanation": "Si confrontano i valori numerici, non la lunghezza della parola: «one» è corta e vale meno di «six».", "topic": "vocabolario", "kind": "pool", "draw": 4, "prompt": "Order the numbers from the smallest to the largest.", "pool": [
			{"label": "one", "value": 1.0}, {"label": "three", "value": 3.0},
			{"label": "four", "value": 4.0}, {"label": "six", "value": 6.0},
			{"label": "seven", "value": 7.0}, {"label": "nine", "value": 9.0},
			{"label": "eleven", "value": 11.0}, {"label": "twelve", "value": 12.0},
			{"label": "fourteen", "value": 14.0}, {"label": "sixteen", "value": 16.0},
			{"label": "eighteen", "value": 18.0}, {"label": "nineteen", "value": 19.0},
			{"label": "twenty-two", "value": 22.0}, {"label": "twenty-five", "value": 25.0},
			{"label": "thirty", "value": 30.0}, {"label": "thirty-seven", "value": 37.0},
			{"label": "forty", "value": 40.0}, {"label": "forty-eight", "value": 48.0},
			{"label": "fifty", "value": 50.0}, {"label": "sixty-three", "value": 63.0},
			{"label": "seventy", "value": 70.0}, {"label": "eighty-one", "value": 81.0},
			{"label": "ninety", "value": 90.0}, {"label": "one hundred", "value": 100.0}]},
		# Word order inglese: soggetto-verbo-oggetto e adjective prima del nome.
		{"explanation": "Soggetto, verbo, complemento: in inglese l'ordine non si può cambiare senza cambiare il senso della frase.", "topic": "sentence", "minLevel": 1, "prompt": "Order the words to make a sentence.", "correctOrder": ["She", "reads", "a", "book"]},
		{"explanation": "La negazione si costruisce con l'ausiliare più «not», e va fra il soggetto e il verbo principale.", "topic": "negative", "minLevel": 4, "prompt": "Order the words to make a negative sentence.", "correctOrder": ["He", "does", "not", "play"]},
		# Domande: inversione dell'ausiliare (diverso dall'italiano).
		{"explanation": "Nella domanda l'ausiliare passa davanti al soggetto: è l'inversione a rendere interrogativa la frase, non solo il punto di domanda.", "topic": "question", "minLevel": 4, "prompt": "Order the words to make a question.", "correctOrder": ["Do", "you", "like", "pizza?"]},
		{"explanation": "Nelle domande con wh- la parola interrogativa va per prima, poi l'ausiliare, poi il soggetto.", "topic": "wh-question", "minLevel": 4, "prompt": "Order the words to make a question.", "correctOrder": ["Where", "do", "you", "live?"]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "In inglese l'ordine delle parole porta il significato, perche' le parole non cambiano forma: soggetto, verbo, oggetto, e poi il resto.", "topic": "sentence", "prompt": "Order the words to make a sentence.", "correctOrder": ["I", "read", "a book", "every evening"]},
		# --- Le costruzioni del biennio (8 settembre 2026) --------------------
		{"explanation": "Dentro un'altra frase la domanda perde l'inversione: chi la ospita ha già fatto il lavoro di domandare, e il soggetto torna davanti al verbo.", "topic": "question", "minLevel": 13, "prompt": "Order the words to make an indirect question.", "correctOrder": ["Can you tell me", "where", "he", "lives?"]},
		{"explanation": "Il passivo si monta sempre nello stesso ordine: la cosa che subisce, il verbo essere al tempo giusto, il participio, e solo alla fine chi ha agito.", "topic": "passive", "minLevel": 19, "prompt": "Order the words to make a passive sentence.", "correctOrder": ["The bridge", "was built", "in 1890", "by the Romans"]},
		{"explanation": "Nel terzo tipo di periodo ipotetico la condizione va al trapassato e la conseguenza al condizionale composto: due pezzi in tre parole ciascuno, e nessuno dei due si può accorciare.", "topic": "conditionals", "minLevel": 22, "prompt": "Order the words to make a third conditional.", "correctOrder": ["If I", "had known,", "I would", "have come"]},
		# --- La grammatica delle prime fasce (9 settembre 2026) ---------------
		{"explanation": "Il verbo essere sta sempre al secondo posto, fra chi e' e com'e'. In inglese l'eta' si E', non si ha: per questo il numero segue «is» e non un verbo avere.", "topic": "to-be", "minLevel": 1, "prompt": "Order the words to make a sentence.", "correctOrder": ["My sister", "is", "ten", "years old"]},
		{"explanation": "Per dire che una cosa esiste l'inglese apre con «there», che non indica nessun luogo: e' solo il posto che la frase pretende prima del verbo. Il luogo vero arriva in fondo.", "topic": "there-is", "minLevel": 4, "prompt": "Order the words to make a sentence.", "correctOrder": ["There", "is", "a book", "on the table"]},
		{"explanation": "Due passati in una frase sola: quello lungo fa da sfondo con la forma in -ing, quello breve lo taglia. «When» resta sempre attaccato all'azione breve, ed e' cosi' che si capisce quale delle due ha interrotto l'altra.", "topic": "past-continuous", "minLevel": 13, "prompt": "Order the words to make a sentence.", "correctOrder": ["She was reading", "when", "the phone", "rang"]},
		{"explanation": "«Going to» e' una cosa sola in tre pezzi: essere, going, to. Il verbo vero arriva dopo, all'infinito, e il quando si mette in fondo — l'inglese chiude quasi sempre con il tempo.", "topic": "future", "minLevel": 13, "prompt": "Order the words to make a sentence about a plan.", "correctOrder": ["I am going to", "visit", "my aunt", "tomorrow"]},
		{"explanation": "La relativa si infila subito dopo il nome che spiega, non alla fine della frase: se si allontana non si capisce piu' di chi si stia parlando. «Who» vale per le persone e tiene il posto del soggetto.", "topic": "relatives", "minLevel": 16, "prompt": "Order the words to make a sentence.", "correctOrder": ["The man", "who lives", "next door", "is a doctor"]},
		{"explanation": "Quando due cose sono successe entrambe prima, la piu' antica arretra di un gradino e prende «had». E' l'unico modo che ha l'inglese di dire che il film era gia' cominciato PRIMA del nostro arrivo.", "topic": "past-perfect", "minLevel": 22, "prompt": "Order the words to make a sentence.", "correctOrder": ["When we arrived", "the film", "had already", "started"]},
		{"explanation": "Raccontare una giornata e' il primo testo che si scrive in una lingua nuova: le azioni si mettono nell'ordine in cui succedono, e le espressioni di tempo — first, then, after that — sono i chiodi a cui si appende il racconto.", "topic": "actions", "minLevel": 1, "prompt": "Order the actions of a normal school morning.", "correctOrder": ["I get up", "I have breakfast", "I go to school", "I come back home"]},
	],
	"fisica": [
		# Insiemi a estrazione: in fisica l'ordine NON è una convenzione da ricordare,
		# è una grandezza. `value` è la grandezza vera (km/h, kg), quindi ogni
		# estrazione è una domanda sensata e la risposta è verificabile.
		{"explanation": "Il peso è una forza: è quanto forte la Terra tira una cosa verso il basso. Più materia c'è, più forte tira — e i chili sull'etichetta lo dicono.", "topic": "forze", "kind": "pool", "draw": 4, "prompt": "Ordina dal peso più leggero al più pesante, leggendo i chili.", "pool": [
			{"label": "Una piuma: 0,001 kg", "value": 0.001}, {"label": "Una mela: 0,2 kg", "value": 0.2},
			{"label": "Un libro: 1 kg", "value": 1.0}, {"label": "Una bottiglia piena: 2 kg", "value": 2.0},
			{"label": "Un gatto: 4 kg", "value": 4.0}, {"label": "Uno zaino di scuola: 8 kg", "value": 8.0},
			{"label": "Un cane grande: 25 kg", "value": 25.0}, {"label": "Un bambino: 35 kg", "value": 35.0},
			{"label": "Un adulto: 70 kg", "value": 70.0}, {"label": "Un frigorifero: 90 kg", "value": 90.0},
			{"label": "Un motorino: 120 kg", "value": 120.0}, {"label": "Un cavallo: 500 kg", "value": 500.0},
			{"label": "Un'automobile: 1200 kg", "value": 1200.0}]},
		{"explanation": "Si confrontano le velocità reali, non la taglia dell'animale: conta lo spazio percorso nello stesso tempo.", "topic": "moto", "kind": "pool", "draw": 4, "prompt": "Ordina per velocità crescente.", "pool": [
			{"label": "Lumaca", "value": 0.05}, {"label": "Tartaruga", "value": 0.3},
			{"label": "Persona che cammina", "value": 5.0}, {"label": "Corridore", "value": 15.0},
			{"label": "Bicicletta", "value": 25.0}, {"label": "Cavallo al galoppo", "value": 55.0},
			{"label": "Automobile in città", "value": 50.0}, {"label": "Ghepardo", "value": 110.0},
			{"label": "Automobile in autostrada", "value": 130.0}, {"label": "Treno regionale", "value": 140.0},
			{"label": "Falco pellegrino in picchiata", "value": 320.0}, {"label": "Treno ad alta velocità", "value": 300.0},
			{"label": "Aereo di linea", "value": 900.0}, {"label": "Suono nell'aria", "value": 1235.0},
			{"label": "Proiettile", "value": 3000.0}, {"label": "Stazione spaziale in orbita", "value": 27600.0},
			{"label": "Formica", "value": 0.9}, {"label": "Monopattino elettrico", "value": 20.0},
			{"label": "Delfino che nuota", "value": 40.0}, {"label": "Motocicletta", "value": 160.0}]},
		{"explanation": "Per misurare una velocità serve prima definire il percorso, poi cronometrare, e solo alla fine dividere: invertire i passi rende la misura senza senso.", "topic": "moto", "prompt": "Ordina i passi per misurare la velocità media di un oggetto.",
			"correctOrder": ["Segna il punto di partenza e quello di arrivo", "Misura la distanza fra i due punti", "Misura il tempo impiegato", "Dividi la distanza per il tempo"]},
		{"explanation": "Si confrontano le masse, non i volumi: una piuma è grande e leggerissima, una graffetta è piccola e pesa di più.", "topic": "misure", "minLevel": 3, "kind": "pool", "draw": 4, "prompt": "Ordina gli oggetti per massa crescente.", "pool": [
			{"label": "Piuma", "value": 0.0005}, {"label": "Formica", "value": 0.000005},
			{"label": "Graffetta", "value": 0.001}, {"label": "Moneta da 1 euro", "value": 0.0075},
			{"label": "Uovo", "value": 0.06}, {"label": "Mela", "value": 0.15},
			{"label": "Bottiglia d'acqua da 1,5 L", "value": 1.5}, {"label": "Libro di testo", "value": 0.9},
			{"label": "Mattone", "value": 2.5}, {"label": "Gatto", "value": 4.0},
			{"label": "Zaino pieno", "value": 8.0}, {"label": "Cane di taglia media", "value": 20.0},
			{"label": "Bicicletta", "value": 12.0}, {"label": "Ragazzo di undici anni", "value": 38.0},
			{"label": "Lavatrice", "value": 70.0}, {"label": "Motocicletta", "value": 180.0},
			{"label": "Pianoforte a coda", "value": 400.0}, {"label": "Cavallo", "value": 500.0},
			{"label": "Automobile", "value": 1300.0}, {"label": "Elefante africano", "value": 6000.0},
			{"label": "Autobus", "value": 12000.0}, {"label": "Balenottera azzurra", "value": 150000.0}]},
		{"explanation": "Le particelle si muovono sempre di più passando da solido a liquido a gas: è l'energia a slegarle, non la temperatura in sé.", "topic": "materia", "minLevel": 5, "prompt": "Ordina gli stati per energia delle particelle, dal minore al maggiore.", "correctOrder": ["Solido", "Liquido", "Gassoso"]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "La densità dice quanto pesa una cosa per lo spazio che occupa. L'acqua vale 1: tutto ciò che sta sotto l'1 galleggia, tutto ciò che sta sopra affonda. Non conta quanto è grosso l'oggetto — una nave d'acciaio galleggia perché è cava, non perché l'acciaio sia leggero.", "topic": "galleggiamento", "minLevel": 13, "kind": "pool", "draw": 4, "prompt": "Ordina dal meno denso al più denso. L'acqua vale 1: sotto galleggia, sopra affonda.", "pool": [
			{"label": "Sughero: 0,24", "value": 0.24}, {"label": "Legno di pino: 0,5", "value": 0.5},
			{"label": "Olio da cucina: 0,92", "value": 0.92}, {"label": "Ghiaccio: 0,93", "value": 0.93},
			{"label": "Acqua: 1", "value": 1.0}, {"label": "Plastica dura: 1,2", "value": 1.2},
			{"label": "Sabbia: 1,6", "value": 1.6}, {"label": "Vetro: 2,5", "value": 2.5},
			{"label": "Alluminio: 2,7", "value": 2.7}, {"label": "Ferro: 7,8", "value": 7.8},
			{"label": "Rame: 8,9", "value": 8.9}, {"label": "Piombo: 11,3", "value": 11.3},
			{"label": "Oro: 19,3", "value": 19.3}]},
		{"explanation": "Sott'acqua conta quanta acqua hai sopra la testa: più scendi, più ne hai, e più forte preme. Non conta quanto è largo il lago né quanto è grande il mare: conta la profondità.", "topic": "pressione", "minLevel": 13, "kind": "pool", "draw": 4, "prompt": "Ordina dalla pressione più leggera alla più forte, guardando a che profondità si trova ognuno.", "pool": [
			{"label": "A galla, sulla superficie: 0 m", "value": 0.0}, {"label": "Con i piedi in acqua: 1 m", "value": 1.0},
			{"label": "Sul fondo della piscina: 3 m", "value": 3.0}, {"label": "Dove si tuffano dal trampolino: 5 m", "value": 5.0},
			{"label": "Un pescatore in apnea: 12 m", "value": 12.0}, {"label": "Il fondo di un porto: 20 m", "value": 20.0},
			{"label": "Un sub con le bombole: 30 m", "value": 30.0}, {"label": "Un relitto vicino a riva: 60 m", "value": 60.0},
			{"label": "Un sottomarino turistico: 120 m", "value": 120.0}, {"label": "Il fondo di un lago profondo: 250 m", "value": 250.0},
			{"label": "Un robot che filma un relitto: 900 m", "value": 900.0}, {"label": "La fossa più profonda: 10900 m", "value": 10900.0}]},
		{"explanation": "Con la corrente non si punta dove si vuole arrivare: si punta un po' più su, e l'acqua fa il resto del lavoro. Prima si guarda dove va l'acqua, poi si sceglie la prua.", "topic": "correnti", "minLevel": 13, "prompt": "Ordina i passi per attraversare un fiume che scorre, senza finire troppo a valle.", "correctOrder": ["Guarda da che parte scorre l'acqua", "Scegli il punto dove vuoi arrivare", "Punta la prua un po' più a monte", "Rema tenendo ferma quella direzione", "Correggi se la riva ti scivola di lato"]},
		{"explanation": "Prima si guarda, poi si misura, e solo alla fine si calcola: invertire l'ordine porta a calcolare una cosa che non si e' capita.", "topic": "metodo", "prompt": "Ordina i passi per misurare quanto e' veloce un oggetto.", "correctOrder": ["Segna il punto di partenza", "Misura la distanza", "Cronometra il tempo", "Dividi distanza per tempo"]},
	],
	"elettronica": [
		# Tensioni reali, dalla pila a bottone alla linea ad alta tensione: qui il
		# valore da ordinare è scritto sull'etichetta, quindi l'esercizio allena a
		# leggere gli ordini di grandezza (mV, V, kV) invece di ricordare una lista.
		{"explanation": "Prima si traduce ogni valore nella stessa unità: 300 mV sono 0,3 V, quindi meno di 1,2 V. Questa conversione arriva dopo aver imparato volt e prefissi.", "topic": "prefissi", "minLevel": 20, "kind": "pool", "draw": 4, "prompt": "Ordina le tensioni dalla più piccola alla più grande.", "pool": [
			{"label": "50 mV", "value": 0.05}, {"label": "300 mV", "value": 0.3},
			{"label": "1,2 V", "value": 1.2}, {"label": "1,5 V", "value": 1.5},
			{"label": "3 V", "value": 3.0}, {"label": "3,7 V", "value": 3.7},
			{"label": "5 V", "value": 5.0}, {"label": "9 V", "value": 9.0},
			{"label": "12 V", "value": 12.0}, {"label": "24 V", "value": 24.0},
			{"label": "48 V", "value": 48.0}, {"label": "110 V", "value": 110.0},
			{"label": "230 V", "value": 230.0}, {"label": "400 V", "value": 400.0},
			{"label": "1 kV", "value": 1000.0}, {"label": "15 kV", "value": 15000.0},
			{"label": "132 kV", "value": 132000.0}, {"label": "380 kV", "value": 380000.0},
			{"label": "750 mV", "value": 0.75}, {"label": "6 V", "value": 6.0},
			{"label": "18 V", "value": 18.0}, {"label": "36 V", "value": 36.0}]},
		{"explanation": "Sull'etichetta di ogni pila c'è scritto quanti volt dà. Con l'unità uguale per tutte basta confrontare i numeri: più volt vuol dire spinta più forte, non pila più grande.", "topic": "misure-elettriche", "kind": "pool", "draw": 4, "prompt": "Ordina le pile dalla spinta più debole alla più forte, leggendo i volt sull'etichetta.", "pool": [
			{"label": "Pila a bottone: 1,5 V", "value": 1.5}, {"label": "Pila stilo: 1,5 V", "value": 1.51},
			{"label": "Pila a bottone da orologio: 3 V", "value": 3.0}, {"label": "Pila piatta: 4,5 V", "value": 4.5},
			{"label": "Pila da 6 V", "value": 6.0}, {"label": "Pila rettangolare: 9 V", "value": 9.0},
			{"label": "Batteria da 12 V", "value": 12.0}, {"label": "Batteria da 18 V", "value": 18.0},
			{"label": "Powerbank: 5 V", "value": 5.0}, {"label": "Batteria del telecomando: 1,2 V", "value": 1.2}]},
		{"explanation": "La corrente percorre un anello chiuso: parte dal polo positivo, attraversa i componenti in fila e torna al negativo. In serie l'ordine è obbligato.", "topic": "circuito", "prompt": "Partendo dal polo positivo, ordina i componenti attraversati dalla corrente in questo circuito in serie.",
			"correctOrder": ["Polo positivo della pila", "Interruttore chiuso", "Resistore", "LED", "Polo negativo della pila"]},
		{"explanation": "Un LED ha un verso e ha bisogno di un resistore che limiti la corrente. Si controllano i collegamenti con la pila staccata e si collega la pila solo alla fine: così un errore si può correggere prima che passi corrente.", "topic": "montaggio-led", "prompt": "Monta in sicurezza il circuito LED: ordina i passi, lasciando l'alimentazione per ultima.", "correctOrder": ["Tieni la pila scollegata", "Controlla il verso del LED", "Collega interruttore e resistore", "Collega il LED e il filo di ritorno", "Controlla che il giro sia chiuso", "Collega la pila per ultima"]},
		{"explanation": "Per confrontare ohm e kilo-ohm bisogna prima portarli alla stessa unità: 1 kΩ significa 1000 Ω.", "topic": "prefissi", "minLevel": 9, "prompt": "Ordina le resistenze dalla più piccola.", "correctOrder": ["10 Ω", "100 Ω", "1 kΩ", "10 kΩ"]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Un circuito funziona soltanto se esiste un giro completo dai due poli della pila. Si prepara il percorso con la pila staccata, si controlla che non ci siano buchi e si alimenta soltanto alla fine.", "topic": "montaggio-lampada", "prompt": "Costruisci un circuito semplice senza alimentarlo mentre lavori: ordina i passi.", "correctOrder": ["Tieni la pila scollegata", "Collega il filo alla lampadina", "Collega il ritorno all'altro lato della lampadina", "Controlla che il percorso non abbia buchi", "Collega i due poli della pila per ultimi"]},
	],
	# Logica (mondi 12 e 24). Prima di queste specifiche la logica riceveva
	# l'ordinamento procedurale di numeri nudi, che dichiarava `topic: "sequenze"`
	# senza avere nessuna regola da scoprire: sequenza è "trova la regola che
	# genera i termini", non "ordina tre interi". Qui l'ordine È il ragionamento.
	"logica": [
		{"explanation": "Per scoprire una regola si guardano prima le differenze fra termini vicini, poi si prova l'ipotesi su un termine noto: indovinare senza verificare non è trovare la regola.", "topic": "sequenze", "prompt": "Ordina i passi per scoprire la regola di una sequenza.", "correctOrder": ["Confronta due termini vicini", "Di' a parole che cosa cambia", "Verifica la regola su un altro termine", "Applica la regola al termine dopo"]},
		{"explanation": "In una deduzione le premesse vengono prima e la conclusione dopo: se la conclusione arriva per prima non si sta deducendo, si sta cercando di giustificarla.", "topic": "deduzioni", "prompt": "Ordina la deduzione: prima le premesse, poi la conclusione.", "correctOrder": ["Tutti i pianeti girano attorno a una stella", "La Terra è un pianeta", "Allora la Terra gira attorno a una stella"]},
		{"explanation": "Prima si trova la relazione fra la prima coppia, poi la si applica alla seconda: saltare il primo passo significa indovinare.", "topic": "analogie", "prompt": "Ordina i passi per risolvere un'analogia.", "correctOrder": ["Guarda la prima coppia", "Di' a parole come sono legate", "Cerca lo stesso legame nella seconda coppia", "Scegli la parola che lo completa"]},
		# Una sequenza che NON si risolve ordinando per grandezza: la regola
		# alterna ×2 e −1, quindi i termini salgono e scendono. È la prova che
		# distingue "so applicare una regola" da "so confrontare due numeri".
		{"explanation": "Si applica la regola un passo per volta, sempre nello stesso ordine: cambiarlo dà una successione diversa anche partendo dallo stesso numero.", "topic": "sequenze", "minLevel": 18, "prompt": "La regola è: ×2, poi −1, poi ×2, poi −1. Rimetti i termini nell'ordine giusto partendo da 3.", "correctOrder": ["3", "6", "5", "10", "9"]},
		{"explanation": "In un indovinello a eliminazione si scartano prima i casi impossibili: quello che resta è la risposta, anche se non si è mai dimostrato direttamente.", "topic": "deduzioni", "minLevel": 20, "prompt": "Ordina i passi per risolvere un indovinello a eliminazione.", "correctOrder": ["Elenca tutti i casi possibili", "Applica il primo indizio e scarta", "Applica il secondo indizio e scarta", "Controlla che resti un solo caso", "Scrivi la conclusione"]},
		{"explanation": "Le relazioni si ordinano per ampiezza: ogni insieme contiene il precedente, dal più specifico al più generale.", "topic": "analogie", "minLevel": 20, "prompt": "Ordina le relazioni dalla più stretta alla più ampia.", "correctOrder": ["Cucciolo : cane", "Cane : mammifero", "Mammifero : animale", "Animale : vivente"]},
		# **La transitività come ordinamento.** (1 settembre 2026)
		#
		# Il banco chiedeva già tre volte «Marco è più alto di Sara, Sara di Ugo:
		# chi è il più basso?» — a scelta multipla, dove si azzecca guardando
		# quale nome non compare nella domanda. Incatenare i confronti È
		# l'ordinamento: qui la stessa competenza si fa con le mani.
		#
		# Due accorgimenti che tolgono le scorciatoie: i nomi non sono in ordine
		# alfabetico né di lunghezza, e nella seconda la consegna chiede l'ordine
		# INVERSO rispetto a come i confronti compaiono nel testo — chi tiene
		# l'ordine di lettura sbaglia tutto.
		{"explanation": "Due confronti si incatenano quando hanno un nome in comune: da «Sara più alta di Nina» e «Nina più alta di Ivo» esce anche «Sara più alta di Ivo», che nessuno aveva detto. È la transitività, e vale per l'altezza come per l'età, il prezzo o la velocità.", "topic": "deduzioni", "minLevel": 3, "prompt": "Sara è più alta di Nina. Nina è più alta di Ivo. Ivo è più alto di Tobia. Ordina dal più alto al più basso.", "correctOrder": ["Sara", "Nina", "Ivo", "Tobia"]},
		{"explanation": "La catena si costruisce sempre allo stesso modo, ma la consegna può chiederla dall'altro capo: prima si mette in fila, poi si guarda da che parte va letta. Chi risponde nell'ordine in cui i confronti sono scritti sbaglia proprio qui.", "topic": "deduzioni", "minLevel": 5, "prompt": "Marta è più giovane di Luca. Luca è più giovane di Sara. Sara è più giovane di Ugo. Ordina dal più VECCHIO al più giovane.", "correctOrder": ["Ugo", "Sara", "Luca", "Marta"]},
		{"explanation": "Gli insiemi si ordinano per ampiezza, non per quanto è comune la parola: ogni quadrato è un rettangolo, ogni rettangolo è un quadrilatero, ogni quadrilatero è un poligono. Salendo si comprende sempre di più, e non si torna mai indietro.", "topic": "deduzioni", "minLevel": 4, "prompt": "Ordina dal gruppo più piccolo a quello che li contiene tutti.", "correctOrder": ["I quadrati", "I rettangoli", "I quadrilateri", "I poligoni"]},
	],
}

# Smistamento in categorie (drag-to-sort), per materia. Ogni item ha UNA categoria
# corretta (`assignments`); il renderer classification li fa trascinare nei bidoni.
# Formato testuale ad alto coinvolgimento, senza asset (playthrough #11).
const CLASSIFICATION := {
	"italiano": [
		# L11. Analisi logica vera: riconoscere il complemento dalla domanda a cui
		# risponde, non dalla preposizione — «in giardino» è luogo, «in bicicletta»
		# è mezzo, e la preposizione è la stessa.
		{"explanation": "Il complemento si riconosce dalla domanda a cui risponde, non dalla preposizione: «in giardino» è luogo e «in bicicletta» è mezzo, con la stessa «in».", "topic": "analisi-logica", "minLevel": 11, "draw": 6, "prompt": "Smista ogni espressione nel suo complemento.",
			"categories": ["di tempo", "di luogo", "di mezzo", "di compagnia"],
			"assignments": {
				"alle otto": "di tempo", "dopo cena": "di tempo", "ogni domenica": "di tempo",
				"in primavera": "di tempo", "fra due ore": "di tempo", "il mese scorso": "di tempo",
				"in giardino": "di luogo", "sotto il tavolo": "di luogo", "verso la scuola": "di luogo",
				"dalla finestra": "di luogo", "in cima al monte": "di luogo", "attraverso il bosco": "di luogo",
				"con il treno": "di mezzo", "in bicicletta": "di mezzo", "a matita": "di mezzo",
				"per posta": "di mezzo", "con la calcolatrice": "di mezzo", "in aereo": "di mezzo",
				"con Marco": "di compagnia", "insieme ai nonni": "di compagnia", "con i compagni": "di compagnia",
				"con mia sorella": "di compagnia", "insieme al cane": "di compagnia", "con gli amici": "di compagnia"}},
		# L19. Figure retoriche riconosciute dagli esempi, non dalla definizione. La
		# similitudine ha sempre il «come»: è l'unico indizio di forma, e serve a
		# distinguerla dalla metafora, che dice la stessa cosa togliendolo.
		{"explanation": "Ogni figura si riconosce dalla forma: la similitudine ha sempre il «come», la metafora dice la stessa cosa togliendolo, la personificazione dà azioni umane alle cose, l'iperbole esagera apposta.", "topic": "figure-retoriche", "minLevel": 19, "draw": 6, "prompt": "Smista ogni espressione nella sua figura retorica.",
			"categories": ["similitudine", "metafora", "personificazione", "iperbole"],
			"assignments": {
				"Sei veloce come il vento": "similitudine", "Dorme come un ghiro": "similitudine",
				"Bianco come la neve": "similitudine", "Forte come un leone": "similitudine",
				"Leggero come una piuma": "similitudine", "Rosso come un peperone": "similitudine",
				"Sei un leone in campo": "metafora", "Il mare di grano": "metafora",
				"Ha un cuore di pietra": "metafora", "La luna è una falce": "metafora",
				"I suoi capelli d'oro": "metafora", "Un fiume di parole": "metafora",
				"Il vento sussurra tra gli alberi": "personificazione", "La luna ci guarda": "personificazione",
				"Le foglie danzano": "personificazione", "Il sole ride": "personificazione",
				"La città dorme": "personificazione", "Il mare ruggisce": "personificazione",
				"Te l'ho detto un milione di volte": "iperbole", "Muoio di fame": "iperbole",
				"Pesa una tonnellata": "iperbole", "Ci metto un secolo": "iperbole",
				"Ho aspettato un'eternità": "iperbole", "Ti ho chiamato mille volte": "iperbole"}},
		# --- Insiemi profondi (Fase 1) ---------------------------------------------
		# Lo smistamento è il formato che regge meglio la profondità: le categorie
		# restano poche (il bidone si deve poter leggere), ma le tessere possono
		# essere trenta. `draw` dice quante se ne pescano; l'estrazione garantisce
		# almeno una tessera per bidone, altrimenti la prova sarebbe rotta.
		{"explanation": "La parte del discorso dipende da che lavoro fa la parola, non da come finisce: si guarda se nomina, se dice un'azione, se descrive o se precisa.", "topic": "categorie", "draw": 8, "prompt": "Smista ogni parola nella sua classe grammaticale.",
			"categories": ["nome", "verbo", "aggettivo", "avverbio"],
			"assignments": {
				"gatto": "nome", "casa": "nome", "montagna": "nome", "quaderno": "nome",
				"amicizia": "nome", "treno": "nome", "finestra": "nome", "coraggio": "nome",
				"correre": "verbo", "saltare": "verbo", "leggere": "verbo", "dormire": "verbo",
				"costruire": "verbo", "ridere": "verbo", "scrivere": "verbo", "partire": "verbo",
				"rosso": "aggettivo", "felice": "aggettivo", "enorme": "aggettivo", "gentile": "aggettivo",
				"antico": "aggettivo", "buio": "aggettivo", "leggero": "aggettivo", "curioso": "aggettivo",
				"velocemente": "avverbio", "lentamente": "avverbio", "domani": "avverbio", "sempre": "avverbio",
				"forse": "avverbio", "bene": "avverbio", "quasi": "avverbio", "altrove": "avverbio"}},
		# I nomi INVARIABILI non possono stare qui da soli. Segnalato giocando:
		# «crisi è singolare o plurale? entrambi, e lo studente tira a caso».
		# Era vero, e la spiegazione lo diceva già da sé — «resta l'articolo a
		# dirlo» — mentre la tessera l'articolo non ce l'aveva. Città, crisi e
		# specie entrano quindi in coppia e con l'articolo davanti: la prova
		# resta la stessa, ma la risposta è di nuovo una sola.
		{"explanation": "Il plurale non si riconosce dalla vocale finale ma dal confronto con il singolare. Le parole invariabili — città, crisi, specie — non cambiano mai forma: da sole non dicono il numero, e a dirlo resta l'articolo. È per questo che qui alcune tessere arrivano con l'articolo davanti.", "topic": "pensiero-linguaggio", "draw": 6, "prompt": "Smista ogni parola: singolare o plurale?",
			"categories": ["singolare", "plurale"],
			"assignments": {
				"libro": "singolare", "fiore": "singolare", "casa": "singolare", "la città": "singolare",
				"uovo": "singolare", "braccio": "singolare", "amico": "singolare", "problema": "singolare",
				"la crisi": "singolare", "la specie": "singolare", "dito": "singolare", "lenzuolo": "singolare",
				"libri": "plurale", "fiori": "plurale", "case": "plurale", "uova": "plurale",
				"braccia": "plurale", "amici": "plurale", "problemi": "plurale", "dita": "plurale",
				"lenzuola": "plurale", "le città": "plurale", "le crisi": "plurale", "le specie": "plurale",
				"valigie": "plurale", "camicie": "plurale", "ciliegie": "plurale"}},
		{"explanation": "Il tempo si legge nella desinenza, non nel senso della frase: «mangiai» e «avete visto» sono entrambi passati, con forme lontanissime.", "topic": "verbo", "draw": 6, "prompt": "Smista ogni verbo nel suo tempo.",
			"categories": ["passato", "presente", "futuro"],
			"assignments": {
				"ho letto": "passato", "mangiai": "passato", "correvo": "passato", "avete visto": "passato",
				"partimmo": "passato", "era": "passato", "hanno deciso": "passato", "dormivi": "passato",
				"corro": "presente", "gioca": "presente", "leggiamo": "presente", "sono": "presente",
				"dormono": "presente", "capisci": "presente", "costruisce": "presente", "aspettate": "presente",
				"andrò": "futuro", "vedremo": "futuro", "partirai": "futuro", "saranno": "futuro",
				"dormirà": "futuro", "leggerete": "futuro", "capiremo": "futuro", "costruiranno": "futuro"}},
		{"explanation": "Concreto è ciò che si può toccare o percepire con i sensi; astratto è ciò che esiste solo nel pensiero — un'idea, un sentimento, una qualità.", "topic": "lessico", "draw": 6, "prompt": "Smista ogni nome: concreto o astratto?",
			"categories": ["concreto", "astratto"],
			"assignments": {
				"tavolo": "concreto", "cane": "concreto", "montagna": "concreto", "chiave": "concreto",
				"pioggia": "concreto", "quaderno": "concreto", "nave": "concreto", "lampada": "concreto",
				"scarpa": "concreto", "fiume": "concreto", "pane": "concreto", "vetro": "concreto",
				"amore": "astratto", "libertà": "astratto", "coraggio": "astratto", "paura": "astratto",
				"giustizia": "astratto", "speranza": "astratto", "noia": "astratto", "pazienza": "astratto",
				"silenzio": "astratto", "fantasia": "astratto", "amicizia": "astratto", "orgoglio": "astratto"}},
		# Scuola media — tempi dell'indicativo con i loro nomi.
		{"explanation": "I quattro tempi dell'indicativo dicono momenti diversi: il presente ora, l'imperfetto un'azione che durava, il passato prossimo un fatto concluso, il futuro ciò che deve ancora accadere.", "topic": "tempi-indicativo", "minLevel": 9, "draw": 8, "prompt": "Smista ogni voce verbale nel suo tempo dell'indicativo.",
			"categories": ["presente", "imperfetto", "passato prossimo", "futuro"],
			"assignments": {
				"mangio": "presente", "leggo": "presente", "parti": "presente", "costruiamo": "presente",
				"dormite": "presente", "capiscono": "presente",
				"mangiavo": "imperfetto", "leggevo": "imperfetto", "partivi": "imperfetto", "costruivamo": "imperfetto",
				"dormivate": "imperfetto", "capivano": "imperfetto",
				"ho mangiato": "passato prossimo", "ho letto": "passato prossimo", "sei partito": "passato prossimo",
				"abbiamo costruito": "passato prossimo", "avete dormito": "passato prossimo", "hanno capito": "passato prossimo",
				"mangerò": "futuro", "leggerò": "futuro", "partirai": "futuro", "costruiremo": "futuro",
				"dormirete": "futuro", "capiranno": "futuro"}},
		# Scuola media — modi finiti del verbo.
		{"explanation": "Il modo dice come si presenta l'azione: certa nell'indicativo, possibile o dubbia nel congiuntivo, legata a una condizione nel condizionale, ordinata nell'imperativo.", "topic": "modi-verbali", "minLevel": 10, "prompt": "Smista ogni voce verbale nel suo modo.",
			"categories": ["indicativo", "congiuntivo", "condizionale", "imperativo"],
			"assignments": {"io canto": "indicativo", "tu cantavi": "indicativo", "che io canti": "congiuntivo", "che tu cantassi": "congiuntivo", "io canterei": "condizionale", "tu canteresti": "condizionale", "canta!": "imperativo", "cantate!": "imperativo"}},
		# Scuola media — analisi grammaticale: parti del discorso.
		{"explanation": "L'analisi grammaticale guarda la parola isolata: che cosa è di suo, senza chiedersi che ruolo abbia nella frase.", "topic": "analisi-grammaticale", "minLevel": 8, "prompt": "Smista ogni parola nella sua parte del discorso.",
			"categories": ["articolo", "nome", "verbo", "preposizione"],
			"assignments": {"il": "articolo", "la": "articolo", "cane": "nome", "sole": "nome", "corre": "verbo", "salta": "verbo", "con": "preposizione", "tra": "preposizione"}},
		# Scuola media — analisi logica: riconoscere i complementi.
		{"explanation": "Si guarda la domanda: dove? è luogo, quando? è tempo, con che cosa? è mezzo. La preposizione da sola non basta mai a decidere.", "topic": "analisi-logica", "minLevel": 11, "prompt": "Smista ogni espressione nel suo complemento.",
			"categories": ["compl. di luogo", "compl. di tempo", "compl. di mezzo"],
			"assignments": {"a Roma": "compl. di luogo", "in giardino": "compl. di luogo", "alle otto": "compl. di tempo", "di sera": "compl. di tempo", "con la penna": "compl. di mezzo", "in treno": "compl. di mezzo"}},
		# I tre argomenti aperti il 7 settembre 2026 prendono anche un gesto.
		# Nessuna tessera nomina il proprio bidone: si smista riconoscendo, non
		# leggendo l'etichetta.
		{"explanation": "Ognuno dei tre poemi ha il suo eroe e il suo viaggio: l'Iliade racconta pochi giorni di guerra, l'Odissea il ritorno a casa, l'Eneide la fuga verso una fondazione nuova. Un nome basta a riconoscere il poema a cui appartiene.", "topic": "epica", "minLevel": 15, "draw": 6, "prompt": "Smista ogni nome nel poema epico a cui appartiene.",
			"categories": ["Iliade", "Odissea", "Eneide"],
			"assignments": {
				"Achille": "Iliade", "Ettore": "Iliade", "Agamennone": "Iliade",
				"Paride": "Iliade", "Priamo": "Iliade", "Patroclo": "Iliade",
				"Ulisse": "Odissea", "Penelope": "Odissea", "Polifemo": "Odissea",
				"Circe": "Odissea", "Calipso": "Odissea", "Nausicaa": "Odissea",
				"Enea": "Eneide", "Anchise": "Eneide", "Didone": "Eneide",
				"Lavinia": "Eneide", "Ascanio": "Eneide", "Turno": "Eneide"}},
		{"explanation": "Lo scopo del testo decide la categoria: se ferma un'immagine è descrittivo, se dà fatti verificabili è espositivo, se sostiene un'idea è argomentativo, se guida un gesto passo passo è regolativo.", "topic": "tipologie-testuali", "minLevel": 3, "draw": 6, "prompt": "Smista ogni frase secondo il tipo di testo a cui appartiene.",
			"categories": ["descrittivo", "espositivo", "argomentativo", "regolativo"],
			"assignments": {
				"Le pareti erano di un azzurro pallido, quasi grigio": "descrittivo",
				"Aveva mani grandi e nodose, segnate dal lavoro": "descrittivo",
				"Il profumo di pane caldo riempiva la stanza": "descrittivo",
				"Un vento leggero muoveva le tende bianche": "descrittivo",
				"Il Colosseo fu costruito nel primo secolo dopo Cristo": "espositivo",
				"L'acqua bolle a cento gradi al livello del mare": "espositivo",
				"I vulcani si formano dove due placche si scontrano": "espositivo",
				"La popolazione della città supera un milione di abitanti": "espositivo",
				"Per questi motivi, credo che la proposta vada respinta": "argomentativo",
				"Non si può ignorare che i dati confermano questa tesi": "argomentativo",
				"Qualcuno obietterà che i costi sono alti, ma i benefici sono maggiori": "argomentativo",
				"Di conseguenza, ritengo necessario cambiare la regola": "argomentativo",
				"Versa la farina e mescola fino a ottenere un composto liscio": "regolativo",
				"Premi il tasto verde per accendere il dispositivo": "regolativo",
				"Ogni giocatore pesca una carta e la mostra agli altri": "regolativo",
				"Non superare mai i 120 caratteri per riga di codice": "regolativo"}},
		{"explanation": "La h separa il verbo avere dalla sua parola gemella senza h: chi confonde le due non ha sbagliato un dettaglio, ha scritto un'altra parola.", "topic": "ortografia", "minLevel": 2, "draw": 6, "prompt": "Smista ogni frase secondo se contiene una voce del verbo avere (con la h) o la sua parola gemella senza h.",
			"categories": ["verbo avere, con la h", "preposizione o nome, senza h"],
			"assignments": {
				"Ho fame da stamattina": "verbo avere, con la h", "Marco ha sempre ragione": "verbo avere, con la h",
				"Loro hanno vinto la partita": "verbo avere, con la h", "Hai un fratello maggiore?": "verbo avere, con la h",
				"Vado a scuola a piedi": "preposizione o nome, senza h", "Un anno intero è passato": "preposizione o nome, senza h",
				"Vengo a piedi ogni giorno": "preposizione o nome, senza h", "Penso spesso a te": "preposizione o nome, senza h"}},
		# **I tre modi indefiniti, riconosciuti dalla forma.** (9 settembre 2026)
		#
		# `imperativo-infinito-participio-gerundio` aveva quindici item nel banco,
		# distribuiti su tutte e otto le fasce, e ZERO minigiochi: si poteva solo
		# crocettare. Il nome della categoria non compare in nessuna tessera — si
		# smista guardando la desinenza, che è l'unico indizio vero.
		{"explanation": "I tre modi indefiniti si riconoscono dalla fine della parola: -are/-ere/-ire per l'infinito, -ando/-endo per il gerundio, -ato/-uto/-ito per il participio. Non dicono chi compie l'azione, ed è per questo che si chiamano indefiniti.", "topic": "imperativo-infinito-participio-gerundio", "minLevel": 16, "draw": 6, "prompt": "Smista ogni voce verbale guardando come finisce.",
			"categories": ["infinito", "gerundio", "participio"],
			"assignments": {
				"correre": "infinito", "partire": "infinito", "cantare": "infinito",
				"scrivere": "infinito", "capire": "infinito", "temere": "infinito",
				"correndo": "gerundio", "partendo": "gerundio", "cantando": "gerundio",
				"scrivendo": "gerundio", "capendo": "gerundio", "temendo": "gerundio",
				"corso": "participio", "partito": "participio", "cantato": "participio",
				"scritto": "participio", "capito": "participio", "temuto": "participio"}},
		# **Fascia 5, e serve al MONDO 14.** (9 settembre 2026)
		#
		# Italiano è materia del mondo soltanto ai mondi 2 e 14: è lì che
		# `gesto_audit` lo misura. Al mondo 14 la pratica stava al 33,5% di
		# «sceglie» contro il 20,0% del mondo 2, e la pratica è il 70,5% dei nodi
		# del mondo. Questa ricetta e quella di scorrimento a `minLevel` 13 sono
		# manipolative apposta: al mondo 14 servono mani, non alternative.
		# Due accorgimenti, e il primo è stato pagato con un rosso. **I nomi dei
		# contenitori non condividono nessuna parola con le tessere**: la prima
		# stesura diceva «era successo prima» e «sarebbe successo dopo», e le
		# tessere contenevano «la sera prima» e «il giorno dopo» — venti punti
		# sopra il caso, la scorciatoia del bidone in piena regola. Il secondo:
		# dalle tessere sono sparite anche le espressioni di tempo, così l'unico
		# indizio rimasto è la voce verbale, che è ciò che la prova vuole chiedere.
		{"explanation": "Rispetto a un fatto passato una subordinata può guardare indietro (trapassato), stare insieme (imperfetto) o guardare avanti (condizionale composto). Il tempo verbale non dice quando è successo in assoluto, ma dove si colloca rispetto alla principale.", "topic": "concordanza-tempi-verbali", "minLevel": 13, "draw": 6, "prompt": "«Marta raccontò che…»: smista ogni seguito guardando soltanto la voce verbale.",
			"categories": ["già concluso", "ancora in corso", "non ancora avvenuto"],
			"assignments": {
				"aveva chiuso il cancello": "già concluso", "era uscito senza avvisare": "già concluso",
				"aveva perso le chiavi": "già concluso", "si era alzata presto": "già concluso",
				"pioveva forte": "ancora in corso", "tutti aspettavano in silenzio": "ancora in corso",
				"nevicava senza sosta": "ancora in corso", "faceva molto freddo": "ancora in corso",
				"sarebbe tornata": "non ancora avvenuto", "avrebbe scritto una lettera": "non ancora avvenuto",
				"si sarebbero rivisti": "non ancora avvenuto", "avrebbe chiamato": "non ancora avvenuto"}},
		# **Il periodo ipotetico nei suoi tre gradi.** (9 settembre 2026)
		#
		# Fascia 8: qui non si chiede la forma ma il GRADO — quanto il parlante
		# crede possibile ciò che dice. Nessuna tessera contiene le parole
		# «realtà», «possibilità» o «impossibile»: si decide dai modi verbali.
		{"explanation": "Il grado del periodo ipotetico si legge nei modi: indicativo per ciò che si dà per certo, congiuntivo imperfetto con il condizionale presente per ciò che è possibile, congiuntivo trapassato con il condizionale passato per ciò che ormai non può più accadere.", "topic": "congiuntivo-condizionale", "minLevel": 22, "draw": 6, "prompt": "Smista ogni periodo ipotetico secondo quanto chi parla lo dà per possibile.",
			"categories": ["dato per certo", "possibile", "ormai impossibile"],
			"assignments": {
				"Se piove, resto a casa": "dato per certo", "Se studi, superi la prova": "dato per certo",
				"Se scaldi il ghiaccio, si scioglie": "dato per certo", "Se parti alle otto, arrivi in tempo": "dato per certo",
				"Se avessi tempo, verrei con te": "possibile", "Se piovesse, resteremmo a casa": "possibile",
				"Se vincessi, dividerei il premio": "possibile", "Se partissi ora, arriveresti prima": "possibile",
				"Se avessi avuto tempo, sarei venuto": "ormai impossibile", "Se fosse partito prima, sarebbe arrivato": "ormai impossibile",
				"Se avesse studiato, avrebbe superato la prova": "ormai impossibile", "Se me l'avessi detto, ti avrei aiutato": "ormai impossibile"}},
	],
	"scienze": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "materia", "minLevel": 10, "draw": 6, "prompt": "Smista ogni trasformazione: cambia solo la forma oppure nasce una sostanza nuova?",
			"categories": ["cambia solo la forma", "nasce una sostanza nuova"],
			"assignments": {
				"il ghiaccio si scioglie": "cambia solo la forma", "l'acqua evapora": "cambia solo la forma",
				"lo zucchero si scioglie nel te'": "cambia solo la forma", "il ferro viene battuto in lamina": "cambia solo la forma",
				"la cera fonde": "cambia solo la forma", "il sale si deposita evaporando": "cambia solo la forma",
				"il legno brucia": "nasce una sostanza nuova", "il ferro arrugginisce": "nasce una sostanza nuova",
				"il latte inacidisce": "nasce una sostanza nuova", "un frutto marcisce": "nasce una sostanza nuova",
				"il pane lievita": "nasce una sostanza nuova", "una candela consuma lo stoppino": "nasce una sostanza nuova"},
			"explanation": "La prova sta nel poter tornare indietro: il ghiaccio sciolto ridiventa ghiaccio, la cenere non ridiventa legno. Dove la strada e' a senso unico, le sostanze si sono davvero riorganizzate."},
		{"topic": "energia", "minLevel": 13, "draw": 6, "prompt": "Smista ogni fonte di energia secondo se si esaurisce oppure no.",
			"categories": ["si rigenera", "una volta usata finisce"],
			"assignments": {
				"il vento": "si rigenera", "il Sole": "si rigenera", "le maree": "si rigenera",
				"l'acqua di un fiume": "si rigenera", "il calore della Terra": "si rigenera", "la legna ripiantata": "si rigenera",
				"il petrolio": "una volta usata finisce", "il carbone": "una volta usata finisce", "il gas naturale": "una volta usata finisce",
				"l'uranio": "una volta usata finisce", "la torba estratta": "una volta usata finisce", "lo scisto bituminoso": "una volta usata finisce"},
			"explanation": "La differenza non e' la quantita' ma il tempo di ricarica: il carbone si e' formato in milioni di anni e lo bruciamo in decenni. Una fonte e' rinnovabile quando si rigenera alla velocita' con cui la usiamo."},
		{"topic": "corpo", "minLevel": 16, "draw": 6, "prompt": "Smista ogni organo secondo l'apparato a cui appartiene.",
			"categories": ["respirazione", "circolazione", "digestione"],
			"assignments": {
				"polmoni": "respirazione", "trachea": "respirazione", "bronchi": "respirazione",
				"diaframma": "respirazione", "laringe": "respirazione", "alveoli": "respirazione",
				"cuore": "circolazione", "arterie": "circolazione", "vene": "circolazione",
				"capillari": "circolazione", "milza": "circolazione", "aorta": "circolazione",
				"stomaco": "digestione", "intestino": "digestione", "fegato": "digestione",
				"esofago": "digestione", "pancreas": "digestione", "colon": "digestione"},
			"explanation": "Gli apparati sono squadre di organi che lavorano a uno stesso compito, e si passano il lavoro l'uno con l'altro: l'ossigeno entra con il primo e viene distribuito dal secondo, che a sua volta raccoglie dal terzo."},
		{"topic": "ecosistema", "minLevel": 19, "draw": 6, "prompt": "Smista ogni essere vivente secondo il posto che occupa nella catena alimentare.",
			"categories": ["produce il proprio cibo", "mangia altri viventi", "smonta i resti"],
			"assignments": {
				"quercia": "produce il proprio cibo", "alga verde": "produce il proprio cibo", "felce": "produce il proprio cibo",
				"muschio": "produce il proprio cibo", "grano": "produce il proprio cibo", "fitoplancton": "produce il proprio cibo",
				"lupo": "mangia altri viventi", "capriolo": "mangia altri viventi", "aquila": "mangia altri viventi",
				"bruco": "mangia altri viventi", "rana": "mangia altri viventi", "coniglio": "mangia altri viventi",
				"fungo del sottobosco": "smonta i resti", "batterio del suolo": "smonta i resti", "lombrico": "smonta i resti",
				"muffa": "smonta i resti", "scarabeo stercorario": "smonta i resti", "termite": "smonta i resti"},
			"explanation": "Ogni ruolo e' definito da dove prende il carbonio: chi lo cattura dall'aria, chi lo prende mangiando, chi lo restituisce al terreno. Togli l'ultimo gruppo e il ciclo si ferma, anche se sembra il meno importante."},
		{"explanation": "Il gruppo dipende da che cosa mangia l'animale, non da quanto è grande: il coniglio e la giraffa stanno insieme perché mangiano entrambi piante.", "topic": "viventi", "draw": 6, "prompt": "Smista ogni animale per come si nutre.",
			"categories": ["erbivoro", "carnivoro", "onnivoro"],
			"assignments": {
				"Mucca": "erbivoro", "Coniglio": "erbivoro", "Cavallo": "erbivoro", "Giraffa": "erbivoro",
				"Elefante": "erbivoro", "Pecora": "erbivoro", "Capriolo": "erbivoro", "Bruco": "erbivoro",
				"Leone": "carnivoro", "Lupo": "carnivoro", "Aquila": "carnivoro", "Squalo": "carnivoro",
				"Ragno": "carnivoro", "Coccodrillo": "carnivoro", "Gufo": "carnivoro", "Ghepardo": "carnivoro",
				"Orso": "onnivoro", "Maiale": "onnivoro", "Cinghiale": "onnivoro", "Corvo": "onnivoro",
				"Riccio": "onnivoro", "Scimpanzé": "onnivoro", "Gabbiano": "onnivoro", "Volpe": "onnivoro"}},
		{"explanation": "L'ambiente è dove l'animale vive e respira abitualmente, non dove capita di vederlo: il delfino vive in acqua pur respirando aria.", "topic": "ecosistema", "draw": 6, "prompt": "Smista ogni animale nel suo ambiente.",
			"categories": ["acqua", "aria", "terra"],
			"assignments": {
				"Pesce": "acqua", "Delfino": "acqua", "Polpo": "acqua", "Granchio": "acqua",
				"Balena": "acqua", "Medusa": "acqua", "Stella marina": "acqua", "Anguilla": "acqua",
				"Aquila": "aria", "Rondine": "aria", "Pipistrello": "aria", "Libellula": "aria",
				"Farfalla": "aria", "Gabbiano": "aria", "Ape": "aria", "Falco": "aria",
				"Talpa": "terra", "Lombrico": "terra", "Formica": "terra", "Lupo": "terra",
				"Scoiattolo": "terra", "Serpente": "terra", "Tasso": "terra", "Riccio": "terra"}},
		{"explanation": "È vivente ciò che nasce, si nutre, cresce e può riprodursi. Muoversi non basta: l'acqua di un fiume si muove e non è viva.", "topic": "viventi", "minLevel": 2, "draw": 6, "prompt": "Smista ogni cosa: vivente o non vivente?",
			"categories": ["vivente", "non vivente"],
			"assignments": {
				"Cane": "vivente", "Albero": "vivente", "Fiore": "vivente", "Fungo": "vivente",
				"Muschio": "vivente", "Batterio": "vivente", "Alga": "vivente", "Lombrico": "vivente",
				"Felce": "vivente", "Lievito": "vivente", "Corallo": "vivente", "Seme germogliato": "vivente",
				"Roccia": "non vivente", "Acqua": "non vivente", "Nuvola": "non vivente", "Sabbia": "non vivente",
				"Vento": "non vivente", "Cristallo di sale": "non vivente", "Fuoco": "non vivente", "Ghiaccio": "non vivente",
				"Vetro": "non vivente", "Ferro": "non vivente", "Fulmine": "non vivente", "Argilla": "non vivente"}},
		{"explanation": "Lo stato dipende da forma e volume: il solido tiene entrambi, il liquido tiene il volume e prende la forma del recipiente, il gas non tiene né l'uno né l'altra.", "topic": "materia", "minLevel": 3, "draw": 6, "prompt": "Smista ogni sostanza nel suo stato a temperatura ambiente.",
			"categories": ["solido", "liquido", "gassoso"],
			"assignments": {
				"Ghiaccio": "solido", "Ferro": "solido", "Legno": "solido", "Sale": "solido",
				"Vetro": "solido", "Sabbia": "solido", "Rame": "solido", "Zucchero": "solido",
				"Acqua": "liquido", "Latte": "liquido", "Olio": "liquido", "Miele": "liquido",
				"Alcol": "liquido", "Succo": "liquido", "Mercurio": "liquido", "Aceto": "liquido",
				"Vapore": "gassoso", "Aria": "gassoso", "Ossigeno": "gassoso", "Anidride carbonica": "gassoso",
				"Elio": "gassoso", "Azoto": "gassoso", "Metano": "gassoso", "Vapore acqueo": "gassoso"}},
		{"explanation": "Il confine è la colonna vertebrale: i vertebrati hanno uno scheletro interno con la spina dorsale, gli invertebrati no.", "topic": "classi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni animale: vertebrato o invertebrato?",
			"categories": ["vertebrato", "invertebrato"],
			"assignments": {
				"Cane": "vertebrato", "Uccello": "vertebrato", "Pesce": "vertebrato", "Rana": "vertebrato",
				"Serpente": "vertebrato", "Balena": "vertebrato", "Tartaruga": "vertebrato", "Pipistrello": "vertebrato",
				"Squalo": "vertebrato", "Aquila": "vertebrato", "Cavallo": "vertebrato", "Salamandra": "vertebrato",
				"Verme": "invertebrato", "Ragno": "invertebrato", "Farfalla": "invertebrato", "Polpo": "invertebrato",
				"Medusa": "invertebrato", "Granchio": "invertebrato", "Lumaca": "invertebrato", "Ape": "invertebrato",
				"Formica": "invertebrato", "Stella marina": "invertebrato", "Scorpione": "invertebrato", "Cozza": "invertebrato"}},
		# Scuola media — ruoli nella rete trofica.
		{"explanation": "Il ruolo dipende da come l'organismo si procura energia: i produttori la fabbricano con la luce, i consumatori la prendono mangiando, i decompositori la ricavano dai resti.", "topic": "ecosistema", "minLevel": 6, "draw": 6, "prompt": "Smista ogni organismo per il suo ruolo nell'ecosistema.",
			"categories": ["produttore", "consumatore", "decompositore"],
			"assignments": {
				"Erba": "produttore", "Albero": "produttore", "Alga": "produttore", "Felce": "produttore",
				"Muschio": "produttore", "Girasole": "produttore", "Fitoplancton": "produttore", "Cespuglio": "produttore",
				"Coniglio": "consumatore", "Lupo": "consumatore", "Cavalletta": "consumatore", "Aquila": "consumatore",
				"Cervo": "consumatore", "Rana": "consumatore", "Volpe": "consumatore", "Pesce": "consumatore",
				"Fungo": "decompositore", "Batterio": "decompositore", "Muffa": "decompositore", "Lombrico": "decompositore",
				"Scarabeo stercorario": "decompositore", "Millepiedi": "decompositore", "Lievito": "decompositore", "Termite del legno morto": "decompositore"}},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Il metodo scientifico è un ordine: prima si guarda, poi si immagina una spiegazione, poi si prova, e solo alla fine si dice che cosa si è capito. Saltare un passo fa dire cose false con sicurezza.", "topic": "metodo", "draw": 6, "prompt": "Smista ogni frase nel passo del metodo scientifico.",
			"categories": ["osservazione", "ipotesi", "esperimento", "conclusione"],
			"assignments": {
				"le piante sul davanzale sono più alte di quelle nell'angolo": "osservazione",
				"il ghiaccio nel bicchiere si scioglie in venti minuti": "osservazione",
				"la palla rossa arriva sempre prima di quella blu": "osservazione",
				"forse crescono di più perché ricevono più luce": "ipotesi",
				"potrebbe dipendere dal peso della palla": "ipotesi",
				"immagino che l'acqua calda sciolga prima lo zucchero": "ipotesi",
				"metto due piante uguali, una al buio e una alla luce": "esperimento",
				"peso il sale prima e dopo averlo sciolto": "esperimento",
				"lascio cadere le due palle dalla stessa altezza": "esperimento",
				"quindi la luce fa crescere le piante di più": "conclusione",
				"il peso non cambia il tempo di caduta": "conclusione",
				"lo zucchero si scioglie prima nell'acqua calda": "conclusione"}},
		{"explanation": "Una stella produce luce da sola, un pianeta la riflette e gira attorno a una stella, un satellite gira attorno a un pianeta. È una questione di chi gira attorno a chi.", "topic": "terra-universo", "draw": 6, "prompt": "Smista ogni corpo celeste.",
			"categories": ["stella", "pianeta", "satellite"],
			"assignments": {
				"Sole": "stella", "Sirio": "stella", "Proxima Centauri": "stella",
				"Betelgeuse": "stella", "Vega": "stella",
				"Marte": "pianeta", "Terra": "pianeta", "Giove": "pianeta",
				"Venere": "pianeta", "Saturno": "pianeta",
				"Luna": "satellite", "Ganimede": "satellite", "Titano": "satellite",
				"Io": "satellite", "Europa (di Giove)": "satellite"}},
	],
	"coding": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "cicli", "minLevel": 13, "draw": 6, "prompt": "Smista ogni compito secondo il ciclo che gli serve.",
			"categories": ["so gia' quante volte", "mi fermo quando succede qualcosa"],
			"assignments": {
				"stampare i numeri da 1 a 100": "so gia' quante volte", "salutare ognuno di venti nomi": "so gia' quante volte",
				"leggere tutte le righe di una lista": "so gia' quante volte", "ripetere un disegno per otto lati": "so gia' quante volte",
				"chiedere la password finche' non e' giusta": "mi fermo quando succede qualcosa", "sommare finche' il totale supera cento": "mi fermo quando succede qualcosa",
				"attendere finche' l'utente scrive fine": "mi fermo quando succede qualcosa", "cercare finche' non trovo l'elemento": "mi fermo quando succede qualcosa"},
			"explanation": "Il ciclo a conteggio serve quando il numero di giri e' noto prima di partire; quello a condizione quando dipende da che cosa succede dentro. Sbagliare il tipo produce o un giro di troppo o un programma che non finisce mai."},
		{"topic": "funzioni", "minLevel": 19, "draw": 6, "prompt": "Smista ogni riga secondo se la funzione consegna un risultato o si limita a mostrarlo.",
			"categories": ["consegna un valore", "mostra e basta"],
			"assignments": {
				"return n * 2": "consegna un valore", "return len(lista)": "consegna un valore",
				"return a + b": "consegna un valore", "return True": "consegna un valore",
				"print(n * 2)": "mostra e basta", "print(len(lista))": "mostra e basta",
				"print(a + b)": "mostra e basta", "print(True)": "mostra e basta"},
			"explanation": "Chi consegna un valore permette di riusarlo: sommarlo, salvarlo, passarlo a un'altra funzione. Chi mostra e basta chiude la strada, e per questo una funzione che stampa non si puo' comporre con altre."},
		{"topic": "tipi", "minLevel": 22, "draw": 6, "prompt": "Smista ogni struttura secondo se si puo' modificare dopo averla creata.",
			"categories": ["si puo' modificare", "resta com'e'"],
			"assignments": {
				"lista": "si puo' modificare", "dizionario": "si puo' modificare",
				"insieme": "si puo' modificare", "array di byte": "si puo' modificare",
				"stringa": "resta com'e'", "tupla": "resta com'e'",
				"numero intero": "resta com'e'", "valore booleano": "resta com'e'"},
			"explanation": "Su cio' che resta com'e' ogni operazione produce una copia nuova invece di cambiare l'originale: e' il motivo per cui `parola.upper()` va assegnato a qualcosa, altrimenti il risultato si perde."},
		{"explanation": "Il tipo si legge da come è scritto il valore: le virgolette fanno una stringa, True e False sono booleani, le parentesi quadre una lista, un numero nudo un intero.", "topic": "tipi", "draw": 8, "prompt": "Smista ogni valore nel suo tipo di dato.",
			"categories": ["intero", "stringa", "booleano", "lista"],
			"assignments": {
				"7": "intero", "42": "intero", "-5": "intero", "0": "intero",
				"1000": "intero", "-128": "intero", "99": "intero", "256": "intero",
				"'ciao'": "stringa", "'sole'": "stringa", "'42'": "stringa", "''": "stringa",
				"'True'": "stringa", "'a b c'": "stringa", "'3.14'": "stringa", "'[1, 2]'": "stringa",
				"True": "booleano", "False": "booleano", "3 > 2": "booleano", "1 == 2": "booleano",
				"not True": "booleano", "5 != 5": "booleano", "'a' in 'casa'": "booleano", "bool(0)": "booleano",
				"[1, 2]": "lista", "[3, 4, 5]": "lista", "[]": "lista", "['a', 'b']": "lista",
				"[True, False]": "lista", "[[1], [2]]": "lista", "list('ciao')": "lista", "[0] * 3": "lista"}},
		# Insieme volutamente SBILANCIATO: Python ha tre soli operatori logici, e
		# inventarne altri cinque per fare simmetria sarebbe contenuto falso.
		# L'estrazione garantisce comunque almeno una voce per famiglia.
		{"explanation": "Gli aritmetici calcolano un numero, quelli di confronto rispondono vero o falso, i logici combinano più condizioni.", "topic": "operatori", "draw": 6, "prompt": "Smista ogni operatore nella sua famiglia.",
			"categories": ["aritmetico", "confronto", "logico"],
			"assignments": {
				"+": "aritmetico", "*": "aritmetico", "-": "aritmetico", "/": "aritmetico",
				"//": "aritmetico", "%": "aritmetico", "**": "aritmetico",
				">": "confronto", "==": "confronto", "<": "confronto", "!=": "confronto",
				">=": "confronto", "<=": "confronto", "is": "confronto", "in": "confronto",
				"and": "logico", "or": "logico", "not": "logico"}},
		# Valuta l'espressione come il computer: è vera o falsa?
		{"explanation": "Un'espressione booleana ha solo due esiti possibili: o è vera o è falsa, non esiste una via di mezzo.", "topic": "booleani", "minLevel": 4, "draw": 6, "prompt": "Ogni espressione: è True o False?",
			"categories": ["True", "False"],
			"assignments": {
				"5 > 3": "True", "2 == 2": "True", "7 != 4": "True", "10 >= 10": "True",
				"'a' < 'b'": "True", "3 in [1, 2, 3]": "True", "not False": "True", "len('ciao') == 4": "True",
				"2 ** 3 == 8": "True", "9 % 3 == 0": "True", "True and True": "True", "False or True": "True",
				"10 < 1": "False", "'a' == 'b'": "False", "4 != 4": "False", "3 >= 7": "False",
				"5 in [1, 2, 3]": "False", "not True": "False", "len('ciao') == 5": "False", "2 ** 3 == 6": "False",
				"9 % 2 == 0": "False", "True and False": "False", "False or False": "False", "'B' == 'b'": "False"}},
		{"explanation": "Il ciclo ripete, la condizione sceglie, la funzione raccoglie istruzioni per riusarle: si riconoscono dalla parola chiave che apre la riga.", "topic": "controllo", "minLevel": 5, "draw": 6, "prompt": "Smista ogni riga nella sua struttura di controllo.",
			"categories": ["ciclo", "condizione", "funzione"],
			"assignments": {
				"for i in range(3):": "ciclo", "while x > 0:": "ciclo", "for nome in lista:": "ciclo",
				"while True:": "ciclo", "for c in 'ciao':": "ciclo", "for i in range(1, 10, 2):": "ciclo",
				"while conta < 5:": "ciclo", "for chiave in dizionario:": "ciclo",
				"if x > 5:": "condizione", "else:": "condizione", "elif x == 0:": "condizione",
				"if nome in lista:": "condizione", "if a and b:": "condizione", "if not trovato:": "condizione",
				"if len(parola) > 3:": "condizione", "elif y < 0:": "condizione",
				"def saluta():": "funzione", "def somma(a, b):": "funzione", "def area(base, altezza):": "funzione",
				"return risultato": "funzione", "def massimo(lista):": "funzione", "def stampa(testo):": "funzione",
				"return a + b": "funzione", "def conta(parola):": "funzione"}},
		# Scuola media — regole dei nomi di variabile (Python).
		{"explanation": "Un nome di variabile non può cominciare con un numero, contenere spazi o essere una parola riservata del linguaggio.", "topic": "nomi", "minLevel": 6, "draw": 6, "prompt": "Smista ogni nome di variabile: valido o no?",
			"categories": ["valido", "non valido"],
			"assignments": {
				"nome": "valido", "x1": "valido", "_temp": "valido", "conta_righe": "valido",
				"Totale": "valido", "n2n": "valido", "_": "valido", "areaDelCerchio": "valido",
				"lista_1": "valido", "MAX": "valido", "prezzo_euro": "valido", "a1b2": "valido",
				"2cose": "non valido", "mia var": "non valido", "3x": "non valido", "nome-utente": "non valido",
				"class": "non valido", "prezzo€": "non valido", "for": "non valido", "totale!": "non valido",
				"1_lista": "non valido", "if": "non valido", "a+b": "non valido", "mio.valore": "non valido"}},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Una condizione è una domanda che ha una risposta sola: sì o no. Il computer non sa fare «forse», e per questo un programma è prevedibile.", "topic": "condizioni", "draw": 6, "prompt": "Smista ogni condizione: è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"5 > 3": "vera", "10 == 10": "vera", "7 != 2": "vera",
				"4 < 9": "vera", "12 >= 12": "vera", "0 < 1": "vera",
				"2 > 8": "falsa", "3 == 5": "falsa", "6 != 6": "falsa",
				"15 < 9": "falsa", "4 >= 7": "falsa", "1 == 0": "falsa"}},
		{"explanation": "Il ciclo serve quando la stessa cosa va rifatta più volte. Scriverla dieci volte a mano funziona, ma quando le volte diventano mille non funziona più.", "topic": "cicli", "draw": 6, "prompt": "Serve un ciclo, oppure basta un'istruzione sola?",
			"categories": ["serve un ciclo", "basta un'istruzione"],
			"assignments": {
				"scrivere i numeri da 1 a 100": "serve un ciclo",
				"salutare ogni nome di una lista": "serve un ciclo",
				"sommare tutti i voti della classe": "serve un ciclo",
				"controllare una per una le lettere di una parola": "serve un ciclo",
				"chiedere la password finché non è giusta": "serve un ciclo",
				"disegnare i quattro lati di un quadrato": "serve un ciclo",
				"scrivere «Ciao» a schermo": "basta un'istruzione",
				"sommare due numeri": "basta un'istruzione",
				"chiedere il nome all'utente": "basta un'istruzione",
				"mettere 10 dentro una variabile": "basta un'istruzione",
				"controllare se un numero è positivo": "basta un'istruzione",
				"calcolare il doppio di un numero": "basta un'istruzione"}},
		# Ingresso e uscita sono RELATIVI: senza dire rispetto a che cosa, metà
		# delle tessere ha due risposte difendibili. Segnalato giocando: «nel
		# coding i segnali di ingresso e di uscita possono essere fraintesi,
		# rispetto a cosa si deve considerare?». Aveva ragione: «chiedere il nome
		# a chi gioca» è un ingresso per il programma e un'uscita per chi legge
		# la domanda a schermo, e la vecchia tessera non diceva quale dei due
		# momenti stesse nominando. Adesso il verso è dichiarato nella consegna e
		# ripetuto nel nome dei bidoni, e ogni tessera nomina UN solo momento.
		{"explanation": "Ingresso e uscita si contano sempre dal programma, mai da chi lo usa: ENTRA il dato che il programma riceve da fuori (tastiera, sensore, file, rete), ESCE il dato che il programma manda fuori (schermo, altoparlante, file, rete). Lo stesso istante può contenere le due cose insieme — la domanda «Come ti chiami?» esce, il nome digitato entra — e per questo ogni tessera ne nomina una sola.", "topic": "input", "draw": 6, "prompt": "Dal punto di vista del programma: il dato entra nel programma o ne esce?",
			"categories": ["entra nel programma", "esce dal programma"],
			"assignments": {
				"leggere il nome digitato da chi gioca": "entra nel programma",
				"leggere la temperatura da un sensore": "entra nel programma",
				"ricevere il clic di un pulsante": "entra nel programma",
				"leggere una riga da un file": "entra nel programma",
				"registrare il tasto premuto": "entra nel programma",
				"ricevere un messaggio dalla rete": "entra nel programma",
				"leggere la risposta scritta sulla tastiera": "entra nel programma",
				"scrivere il risultato a schermo": "esce dal programma",
				"mostrare a schermo la domanda «Come ti chiami?»": "esce dal programma",
				"accendere una lampadina": "esce dal programma",
				"salvare i punti in un file": "esce dal programma",
				"far suonare un avviso": "esce dal programma",
				"disegnare una figura": "esce dal programma",
				"mandare un messaggio in rete": "esce dal programma"}},
	],
	"storia": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "civilta", "minLevel": 19, "draw": 6, "prompt": "Smista ogni invenzione secondo l'epoca in cui compare.",
			"categories": ["mondo antico", "medioevo", "eta' moderna"],
			"assignments": {
				"acquedotto in muratura": "mondo antico", "scrittura su papiro": "mondo antico",
				"strada lastricata": "mondo antico", "calendario solare": "mondo antico",
				"mulino ad acqua diffuso": "medioevo", "aratro pesante con ruote": "medioevo",
				"occhiali da vista": "medioevo", "orologio meccanico da torre": "medioevo",
				"stampa a caratteri mobili": "eta' moderna", "telescopio": "eta' moderna",
				"macchina a vapore": "eta' moderna", "vaccino": "eta' moderna"},
			"explanation": "Le invenzioni non arrivano a caso: ognuna ha bisogno di quelle prima. La stampa richiede carta economica e metallurgia fine, e infatti nasce dove tutte e due erano gia' disponibili."},
		{"topic": "metodo", "minLevel": 20, "draw": 6, "prompt": "Smista ogni domanda secondo se una fonte puo' rispondere da sola.",
			"categories": ["basta una fonte", "servono piu' fonti"],
			"assignments": {
				"in che anno e' datato questo documento": "basta una fonte", "quale nome compare sulla lapide": "basta una fonte",
				"quale materiale e' stato usato": "basta una fonte", "quante righe contiene il testo": "basta una fonte",
				"perche' quella guerra e' scoppiata": "servono piu' fonti", "che cosa pensava la gente comune": "servono piu' fonti",
				"quanto era diffusa quell'abitudine": "servono piu' fonti", "se il racconto e' attendibile": "servono piu' fonti"},
			"explanation": "Una fonte risponde bene alle domande su se stessa e male a quelle sul mondo attorno: per sapere che cosa e' successo davvero servono voci diverse, perche' ciascuna vede da un punto solo."},
		{"topic": "cronologia", "minLevel": 23, "draw": 6, "prompt": "Smista ogni cambiamento secondo la velocita' con cui e' avvenuto.",
			"categories": ["nel giro di giorni", "nel giro di secoli"],
			"assignments": {
				"una battaglia decisiva": "nel giro di giorni", "l'incoronazione di un sovrano": "nel giro di giorni",
				"la firma di un trattato": "nel giro di giorni", "l'eruzione che sepolli' Pompei": "nel giro di giorni",
				"il passaggio dalla caccia all'agricoltura": "nel giro di secoli", "la diffusione di una lingua": "nel giro di secoli",
				"lo spostamento dei commerci verso l'oceano": "nel giro di secoli", "il cambiamento del clima medievale": "nel giro di secoli"},
			"explanation": "La storia si muove su due orologi insieme: gli eventi che si datano al giorno e i processi che nessuno vede accadere. Guardare solo il primo fa credere che la storia sia una fila di date."},
		{"topic": "fonti", "draw": 6, "prompt": "Smista ogni traccia del passato: fonte scritta o fonte materiale?",
			"categories": ["fonte scritta", "fonte materiale"],
			"assignments": {
				"Papiro": "fonte scritta", "Iscrizione su pietra": "fonte scritta",
				"Diario di viaggio": "fonte scritta", "Lettera": "fonte scritta",
				"Cronaca di un monaco": "fonte scritta", "Tavoletta di argilla": "fonte scritta",
				"Vaso dipinto": "fonte materiale", "Moneta": "fonte materiale",
				"Punta di freccia": "fonte materiale", "Mosaico": "fonte materiale",
				"Rovine di una casa": "fonte materiale", "Osso di animale": "fonte materiale"},
			"explanation": "Le fonti scritte raccontano a parole, quelle materiali sono oggetti che parlano con la loro forma. Servono entrambe: dove nessuno scriveva, restano solo le seconde."},
		{"explanation": "Si ordina per distanza da oggi: più uno strumento è semplice e fatto di materiali naturali, più è probabile che sia antico.", "topic": "tempo", "draw": 6, "prompt": "Smista ogni oggetto: molto antico o moderno?",
			"categories": ["molto antico", "moderno"],
			"assignments": {
				"Piramide": "molto antico", "Anfora": "molto antico", "Ruota di pietra": "molto antico",
				"Papiro": "molto antico", "Clessidra": "molto antico", "Spada di bronzo": "molto antico",
				"Acquedotto romano": "molto antico", "Tavoletta di argilla": "molto antico",
				"Mosaico": "molto antico", "Carro trainato da buoi": "molto antico",
				"Toga": "molto antico", "Arco e frecce": "molto antico",
				"Smartphone": "moderno", "Automobile": "moderno", "Computer": "moderno",
				"Aereo di linea": "moderno", "Frigorifero": "moderno", "Televisore": "moderno",
				"Vaccino": "moderno", "Satellite": "moderno", "Bicicletta": "moderno",
				"Macchina fotografica": "moderno", "Lampadina elettrica": "moderno", "Ascensore": "moderno"}},
		{"explanation": "Le fonti si dividono per come arrivano fino a noi: un oggetto è materiale, un documento è scritto, un racconto tramandato a voce è orale.", "topic": "fonti", "minLevel": 3, "draw": 6, "prompt": "Smista ogni fonte storica nel suo tipo.",
			"categories": ["materiale", "scritta", "orale"],
			"assignments": {
				"Piramide": "materiale", "Vaso antico": "materiale", "Moneta romana": "materiale",
				"Punta di lancia": "materiale", "Mosaico di una villa": "materiale", "Rovine di un tempio": "materiale",
				"Scheletro in una tomba": "materiale", "Anello d'oro": "materiale",
				"Papiro": "scritta", "Lettera antica": "scritta", "Iscrizione su pietra": "scritta",
				"Diario di viaggio": "scritta", "Registro di un mercante": "scritta", "Cronaca di un monaco": "scritta",
				"Trattato di pace": "scritta", "Elenco delle tasse": "scritta",
				"Racconto del nonno": "orale", "Leggenda tramandata": "orale", "Canto popolare": "orale",
				"Filastrocca antica": "orale", "Intervista a un testimone": "orale", "Proverbio del paese": "orale",
				"Fiaba raccontata a voce": "orale", "Ninna nanna tradizionale": "orale"}},
		# Scuola media — collocare oggetti e monumenti nella loro epoca.
		{"explanation": "Le epoche si separano da fatti precisi: la scrittura chiude la preistoria, la caduta di Roma d'Occidente apre il medioevo.", "topic": "epoca", "minLevel": 5, "draw": 6, "prompt": "Smista ogni cosa nella sua epoca storica.",
			"categories": ["preistoria", "antichità", "medioevo"],
			"assignments": {
				"Pittura rupestre": "preistoria", "Selce scheggiata": "preistoria", "Palafitta": "preistoria",
				"Ascia di pietra": "preistoria", "Menhir": "preistoria", "Vaso di terracotta grezza": "preistoria",
				"Osso inciso": "preistoria", "Prima ruota di legno": "preistoria",
				"Colosseo": "antichità", "Anfora romana": "antichità", "Partenone": "antichità",
				"Ziggurat": "antichità", "Sarcofago egizio": "antichità", "Elmo greco": "antichità",
				"Acquedotto": "antichità", "Mosaico pompeiano": "antichità",
				"Castello": "medioevo", "Cattedrale gotica": "medioevo", "Armatura da cavaliere": "medioevo",
				"Manoscritto miniato": "medioevo", "Mulino ad acqua": "medioevo", "Torre di avvistamento": "medioevo",
				"Blasone nobiliare": "medioevo", "Spada da crociato": "medioevo"}},
		# Le civiltà come contenitori: qui il materiale «una civiltà, molte opere»
		# trova casa. Nell'abbinamento non poteva crescere — con quattro civiltà e
		# venti opere due voci si sarebbero contese la stessa risposta.
		{"explanation": "Ogni popolo si riconosce da ciò che ha costruito e dal modo in cui scriveva: sono le due tracce che restano più a lungo.", "topic": "civilta", "minLevel": 2, "draw": 6, "prompt": "Smista ogni opera nella civiltà che l'ha realizzata.",
			"categories": ["Egizi", "Greci", "Romani", "Sumeri"],
			"assignments": {
				"Piramidi di Giza": "Egizi", "Sfinge": "Egizi", "Geroglifici": "Egizi",
				"Papiro come supporto": "Egizi", "Mummificazione": "Egizi", "Calendario solare": "Egizi",
				"Partenone": "Greci", "Democrazia": "Greci", "Giochi olimpici": "Greci",
				"Teatro tragico": "Greci", "Filosofia": "Greci", "Colonne doriche": "Greci",
				"Colosseo": "Romani", "Acquedotti": "Romani", "Strade lastricate": "Romani",
				"Diritto romano": "Romani", "Terme pubbliche": "Romani", "Arco di trionfo": "Romani",
				"Scrittura cuneiforme": "Sumeri", "Ziggurat": "Sumeri", "Prime città-stato": "Sumeri",
				"Ruota a raggi": "Sumeri", "Codice di leggi inciso": "Sumeri", "Aratro tirato da animali": "Sumeri"}},
		# --- Mondo 1: tre ricette in più (tappa 2, 6 agosto 2026) ---------------
		{"explanation": "Le fonti si distinguono da come sono arrivate fino a noi: scritte se qualcuno le ha messe su carta o pietra, materiali se sono cose, orali se sono passate di bocca in bocca.", "topic": "fonti", "draw": 6, "prompt": "Smista ogni traccia del passato: che tipo di fonte è?",
			"categories": ["scritta", "materiale", "orale"],
			"assignments": {
				"un diario di viaggio": "scritta", "una lettera di un soldato": "scritta",
				"un'iscrizione su una lapide": "scritta", "un registro di battesimi": "scritta",
				"una cronaca di monastero": "scritta",
				"una moneta romana": "materiale", "un vaso greco": "materiale",
				"le fondamenta di una casa": "materiale", "un'arma di bronzo": "materiale",
				"un osso lavorato": "materiale",
				"una leggenda raccontata dai nonni": "orale", "una canzone popolare tramandata": "orale",
				"il racconto di un testimone": "orale", "un proverbio di paese": "orale",
				"una filastrocca antica": "orale"}},
		{"explanation": "Gli anni prima di Cristo si contano all'indietro: più il numero è grande, più l'evento è antico. È l'unica numerazione della storia che va al contrario.", "topic": "cronologia", "draw": 6, "prompt": "Smista ogni evento: prima o dopo la nascita di Cristo?",
			"categories": ["prima di Cristo", "dopo Cristo"],
			"assignments": {
				"la fondazione di Roma": "prima di Cristo", "le piramidi di Giza": "prima di Cristo",
				"la morte di Giulio Cesare": "prima di Cristo", "la battaglia di Maratona": "prima di Cristo",
				"la guerra di Troia": "prima di Cristo", "l'impero di Alessandro Magno": "prima di Cristo",
				"la caduta dell'Impero romano d'Occidente": "dopo Cristo",
				"l'incoronazione di Carlo Magno": "dopo Cristo",
				"la scoperta dell'America": "dopo Cristo", "la Rivoluzione francese": "dopo Cristo",
				"l'Unità d'Italia": "dopo Cristo", "lo sbarco sulla Luna": "dopo Cristo"}},
		{"explanation": "Le quattro età non hanno confini naturali: sono tagli decisi dagli storici su avvenimenti che hanno cambiato tutto, come la caduta di Roma o la scoperta dell'America.", "topic": "civilta", "draw": 6, "prompt": "Smista ogni avvenimento nella sua età.",
			"categories": ["antichità", "medioevo", "età moderna", "età contemporanea"],
			"assignments": {
				"le piramidi d'Egitto": "antichità", "la democrazia di Atene": "antichità",
				"l'impero di Augusto": "antichità", "la guerra di Troia": "antichità",
				"i castelli e i feudi": "medioevo", "le crociate": "medioevo",
				"i monasteri copiano i libri a mano": "medioevo", "l'incoronazione di Carlo Magno": "medioevo",
				"la scoperta dell'America": "età moderna", "la stampa di Gutenberg": "età moderna",
				"Galileo e il telescopio": "età moderna", "la Riforma di Lutero": "età moderna",
				"la Rivoluzione francese": "età contemporanea", "l'Unità d'Italia": "età contemporanea",
				"le due guerre mondiali": "età contemporanea", "lo sbarco sulla Luna": "età contemporanea"}},
	],
	"geografia": [
		# **Le fasce alte della geografia, scritte il 9 settembre 2026.** Il
		# censimento trovava geografia con ZERO ricette nuove dalla fascia 5 in
		# poi: dal mondo 13 al 24 non sbloccava piu' niente, e restavano le carte
		# mute imparate al primo mondo. Nessuna tessera contiene il nome del
		# proprio contenitore: e' la scorciatoia del bidone.
		{"topic": "climi", "minLevel": 13, "draw": 6, "prompt": "Smista ogni paesaggio secondo la fascia climatica in cui si trova.",
			"categories": ["equatoriale", "arido", "polare"],
			"assignments": {
				"foresta sempre verde e piogge quotidiane": "equatoriale", "alberi altissimi e umidita' costante": "equatoriale",
				"vegetazione fitta su piu' piani sovrapposti": "equatoriale", "fiumi larghi che non seccano mai": "equatoriale",
				"dune mobili e pochissima vegetazione": "arido", "escursione fortissima fra giorno e notte": "arido",
				"piante grasse che immagazzinano riserve": "arido", "corsi d'acqua che scorrono solo dopo i temporali": "arido",
				"suolo gelato tutto l'anno sotto la superficie": "polare", "muschi e licheni al posto degli alberi": "polare",
				"mesi interi senza che il Sole tramonti": "polare", "distese bianche senza alcuna coltivazione": "polare"},
			"explanation": "Il clima si legge dal paesaggio prima che dai numeri: la vegetazione e' un termometro e un pluviometro insieme, perche' cresce solo dove trova le condizioni che le servono."},
		{"topic": "geografia-fisica", "minLevel": 16, "draw": 6, "prompt": "Smista ogni forma del rilievo secondo chi l'ha modellata.",
			"categories": ["un fiume", "un ghiacciaio", "il mare"],
			"assignments": {
				"valle stretta e incisa a V": "un fiume", "pianura di detriti alla foce": "un fiume",
				"meandri che serpeggiano in piano": "un fiume", "gole profonde scavate nella roccia": "un fiume",
				"valle larga con il fondo piatto": "un ghiacciaio", "massi enormi lasciati fuori posto": "un ghiacciaio",
				"conche riempite d'acqua in quota": "un ghiacciaio", "rocce levigate e striate in una direzione": "un ghiacciaio",
				"falesie tagliate a picco": "il mare", "cordoni di sabbia lungo la riva": "il mare",
				"archi di roccia forati dalle onde": "il mare", "spiagge che avanzano dove la corrente rallenta": "il mare"},
			"explanation": "Ogni agente lascia una firma riconoscibile: l'acqua corrente incide in profondita', il ghiaccio allarga il fondo, le onde tagliano di lato. Il paesaggio conserva la storia di chi lo ha costruito anche milioni di anni dopo."},
		{"topic": "geografia-umana", "minLevel": 22, "draw": 6, "prompt": "Smista ogni attivita' secondo il settore economico a cui appartiene.",
			"categories": ["primario", "secondario", "terziario"],
			"assignments": {
				"coltivare grano": "primario", "pescare in mare aperto": "primario",
				"estrarre minerali": "primario", "allevare bestiame": "primario",
				"assemblare automobili": "secondario", "trasformare il latte in formaggio": "secondario",
				"tessere stoffe": "secondario", "raffinare petrolio": "secondario",
				"insegnare in una scuola": "terziario", "curare in ospedale": "terziario",
				"trasportare merci": "terziario", "vendere in un negozio": "terziario"},
			"explanation": "Il primario prende dalla natura, il secondario trasforma, il terziario offre servizi. La ricchezza di un paese si legge in come le persone si distribuiscono fra i tre, e lo spostamento dal primo al terzo e' il ritratto di un secolo di storia."},
		{"explanation": "Un Paese sta nel continente su cui poggia la sua terra, non in quello a cui somiglia per lingua o cultura.", "topic": "continenti", "draw": 8, "prompt": "Smista ogni Paese nel suo continente.",
			"categories": ["Africa", "Europa", "Asia", "America"],
			"assignments": {
				"Egitto": "Africa", "Kenya": "Africa", "Marocco": "Africa", "Nigeria": "Africa",
				"Sudafrica": "Africa", "Etiopia": "Africa", "Tunisia": "Africa", "Senegal": "Africa",
				"Italia": "Europa", "Francia": "Europa", "Spagna": "Europa", "Germania": "Europa",
				"Grecia": "Europa", "Norvegia": "Europa", "Polonia": "Europa", "Portogallo": "Europa",
				"Giappone": "Asia", "Cina": "Asia", "India": "Asia", "Vietnam": "Asia",
				"Thailandia": "Asia", "Corea del Sud": "Asia", "Nepal": "Asia", "Indonesia": "Asia",
				"Brasile": "America", "Canada": "America", "Messico": "America", "Argentina": "America",
				"Perù": "America", "Cile": "America", "Cuba": "America", "Stati Uniti": "America"}},
		{"explanation": "Si guarda che cosa copre la superficie: mari, oceani, laghi e fiumi da una parte; pianure, monti, isole e deserti dall'altra.", "topic": "geografia-fisica", "draw": 6, "prompt": "Smista ogni elemento: d'acqua o di terra?",
			"categories": ["acqua", "terra"],
			"assignments": {
				"Fiume": "acqua", "Lago": "acqua", "Mare": "acqua", "Oceano": "acqua",
				"Golfo": "acqua", "Torrente": "acqua", "Cascata": "acqua", "Ghiacciaio": "acqua",
				"Laguna": "acqua", "Stretto": "acqua", "Sorgente": "acqua", "Palude": "acqua",
				"Montagna": "terra", "Pianura": "terra", "Collina": "terra", "Altopiano": "terra",
				"Deserto": "terra", "Vulcano": "terra", "Isola": "terra", "Penisola": "terra",
				"Valle": "terra", "Promontorio": "terra", "Dune": "terra", "Canyon": "terra"}},
		{"explanation": "La fascia climatica dipende soprattutto dalla distanza dall'equatore: più ci si allontana, meno calore diretto arriva dal Sole.", "topic": "climi", "minLevel": 4, "draw": 6, "prompt": "Smista ogni luogo nel suo clima.",
			"categories": ["caldo", "temperato", "freddo"],
			"assignments": {
				"Sahara": "caldo", "Equatore": "caldo", "Amazzonia": "caldo", "Congo": "caldo",
				"Arabia": "caldo", "Borneo": "caldo", "Deserto del Kalahari": "caldo", "India del Sud": "caldo",
				"Italia": "temperato", "California": "temperato", "Grecia": "temperato", "Portogallo": "temperato",
				"Francia": "temperato", "Giappone centrale": "temperato", "Cile centrale": "temperato", "Turchia": "temperato",
				"Polo Nord": "freddo", "Siberia": "freddo", "Groenlandia": "freddo", "Antartide": "freddo",
				"Alaska": "freddo", "Islanda": "freddo", "Lapponia": "freddo", "Patagonia meridionale": "freddo"}},
		# Scuola media — i grandi paesaggi d'Italia.
		{"explanation": "Si guarda la forma del rilievo: la montagna sale ripida, la pianura resta bassa e distesa, il mare è l'acqua che le chiude.", "topic": "italia-fisica", "minLevel": 5, "draw": 6, "prompt": "Smista ogni elemento nel suo paesaggio italiano.",
			"categories": ["montagna", "pianura", "mare"],
			"assignments": {
				"Alpi": "montagna", "Appennini": "montagna", "Dolomiti": "montagna", "Monte Bianco": "montagna",
				"Gran Sasso": "montagna", "Etna": "montagna", "Vesuvio": "montagna", "Monte Rosa": "montagna",
				"Pianura Padana": "pianura", "Tavoliere delle Puglie": "pianura", "Maremma": "pianura", "Agro Pontino": "pianura",
				"Valle Padana orientale": "pianura", "Piana di Catania": "pianura", "Campidano": "pianura", "Valdarno": "pianura",
				"Mar Adriatico": "mare", "Mar Tirreno": "mare", "Mar Ionio": "mare", "Mar Ligure": "mare",
				"Golfo di Napoli": "mare", "Stretto di Messina": "mare", "Canale di Sicilia": "mare", "Golfo di Trieste": "mare"}},
		# --- Mondo 1: due ricette in più (tappa 2, 6 agosto 2026) ---------------
		{"explanation": "Gli oceani sono cinque e circondano i continenti; i mari sono più piccoli e stanno incassati fra le terre. È una questione di dimensione e di chiusura, non di salinità.", "topic": "geografia-fisica", "draw": 6, "prompt": "Smista ogni distesa d'acqua: oceano o mare?",
			"categories": ["oceano", "mare"],
			"assignments": {
				"Pacifico": "oceano", "Atlantico": "oceano", "Indiano": "oceano",
				"Artico": "oceano", "Antartico": "oceano",
				"Mediterraneo": "mare", "Adriatico": "mare", "Tirreno": "mare",
				"Ionio": "mare", "Egeo": "mare", "mar Rosso": "mare",
				"mar Nero": "mare", "Baltico": "mare", "mare del Nord": "mare",
				"mar dei Caraibi": "mare"}},
		{"explanation": "Il clima dipende soprattutto da quanto si è lontani dall'equatore: più ci si allontana, meno sole arriva dall'alto e più le stagioni si sentono.", "topic": "climi", "draw": 6, "prompt": "Smista ogni luogo per il suo clima.",
			"categories": ["caldo", "temperato", "freddo"],
			"assignments": {
				"Sahara": "caldo", "Amazzonia": "caldo", "bacino del Congo": "caldo",
				"deserto arabico": "caldo", "Yucatán": "caldo",
				"Roma": "temperato", "Parigi": "temperato", "Lisbona": "temperato",
				"Tokyo": "temperato", "Buenos Aires": "temperato",
				"Siberia": "freddo", "Groenlandia": "freddo", "Antartide": "freddo",
				"Alaska": "freddo", "Lapponia": "freddo"}},
	],
	"matematica": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "insiemi-numerici", "minLevel": 13, "draw": 6, "prompt": "Smista ogni numero secondo il tipo a cui appartiene.",
			"categories": ["intero", "frazionario", "negativo"],
			"assignments": {
				"7": "intero", "0": "intero", "42": "intero",
				"100": "intero", "15": "intero", "8": "intero",
				"1/2": "frazionario", "3/4": "frazionario", "0,75": "frazionario",
				"2,5": "frazionario", "7/8": "frazionario", "0,2": "frazionario",
				"-3": "negativo", "-12": "negativo", "-0,5": "negativo",
				"-100": "negativo", "-7": "negativo", "-1/4": "negativo"},
			"explanation": "I numeri si allargano per necessita': gli interi non bastano a dividere una torta, i positivi non bastano a dire quanto si scende sotto zero. Ogni famiglia nuova contiene la precedente."},
		{"topic": "geometria", "minLevel": 22, "draw": 6, "prompt": "Smista ogni formula secondo che cosa calcola.",
			"categories": ["il contorno", "la superficie", "lo spazio occupato"],
			"assignments": {
				"lato per quattro": "il contorno", "somma di tutti i lati": "il contorno",
				"due per pi greco per raggio": "il contorno", "base piu' base piu' i due lati": "il contorno",
				"base per altezza": "la superficie", "lato per lato": "la superficie",
				"base per altezza diviso due": "la superficie", "pi greco per raggio al quadrato": "la superficie",
				"spigolo elevato al cubo": "lo spazio occupato", "area di base per altezza": "lo spazio occupato",
				"lunghezza per larghezza per altezza": "lo spazio occupato", "area di base per altezza diviso tre": "lo spazio occupato"},
			"explanation": "Il numero di misure moltiplicate dice la dimensione del risultato: una sola per un contorno, due per una superficie, tre per un volume. E' anche il modo piu' rapido per accorgersi di aver usato la formula sbagliata."},
		{"explanation": "Un numero è pari se finisce per 0, 2, 4, 6 o 8: basta guardare l'ultima cifra, non serve dividere.", "topic": "numeri", "draw": 6, "prompt": "Smista i numeri in pari e dispari.",
			"categories": ["pari", "dispari"],
			"assignments": {
				"4": "pari", "8": "pari", "12": "pari", "26": "pari", "34": "pari", "50": "pari",
				"78": "pari", "96": "pari", "114": "pari", "130": "pari", "248": "pari", "306": "pari",
				"7": "dispari", "15": "dispari", "21": "dispari", "33": "dispari", "47": "dispari", "59": "dispari",
				"85": "dispari", "91": "dispari", "107": "dispari", "123": "dispari", "251": "dispari", "399": "dispari"}},
		{"explanation": "Si confronta con cento guardando quante cifre ha il numero e, a parità di cifre, la prima da sinistra.", "topic": "calcolo", "draw": 6, "prompt": "Smista ogni risultato: minore di 100 oppure 100 o più.",
			"categories": ["minore di 100", "100 o più"],
			"assignments": {
				"12 × 7": "minore di 100", "45 + 38": "minore di 100", "150 ÷ 2": "minore di 100",
				"9 × 9": "minore di 100", "120 - 45": "minore di 100", "13 × 6": "minore di 100",
				"240 ÷ 4": "minore di 100", "88 + 9": "minore di 100", "300 - 215": "minore di 100",
				"7 × 13": "minore di 100", "196 ÷ 4": "minore di 100", "60 + 35": "minore di 100",
				"12 × 9": "100 o più", "87 + 96": "100 o più", "500 ÷ 4": "100 o più",
				"11 × 11": "100 o più", "300 - 155": "100 o più", "24 × 6": "100 o più",
				"960 ÷ 8": "100 o più", "108 + 97": "100 o più", "1000 - 375": "100 o più",
				"16 × 7": "100 o più", "444 ÷ 4": "100 o più", "55 + 66": "100 o più"}},
		# Il segno "=" come bilancia: l'uguaglianza è vera o falsa? (misconcezione classica)
		{"explanation": "Si calcolano i due lati dell'uguale separatamente e si confrontano i risultati: se coincidono l'uguaglianza è vera.", "topic": "uguaglianze", "minLevel": 2, "draw": 6, "prompt": "Ogni uguaglianza è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"3 + 4 = 7": "vera", "10 - 6 = 4": "vera", "2 × 5 = 10": "vera", "24 ÷ 6 = 4": "vera",
				"9 + 8 = 17": "vera", "7 × 6 = 42": "vera", "100 - 45 = 55": "vera", "144 ÷ 12 = 12": "vera",
				"15 + 27 = 42": "vera", "8 × 9 = 72": "vera", "3 + 4 = 4 + 3": "vera", "2 × (3 + 4) = 14": "vera",
				"5 + 3 = 9": "falsa", "12 ÷ 3 = 5": "falsa", "6 × 2 = 10": "falsa", "20 - 7 = 14": "falsa",
				"11 + 12 = 24": "falsa", "9 × 7 = 61": "falsa", "81 ÷ 9 = 8": "falsa", "50 - 23 = 33": "falsa",
				"13 + 19 = 31": "falsa", "6 × 8 = 46": "falsa", "2 + 3 × 4 = 20": "falsa", "100 ÷ 4 = 20": "falsa"}},
		{"explanation": "Un numero è multiplo di 3 se la somma delle sue cifre è divisibile per 3: è una prova che si fa a mente, senza dividere.", "topic": "multipli", "minLevel": 3, "draw": 6, "prompt": "Smista: è multiplo di 3 oppure no?",
			"categories": ["multiplo di 3", "non multiplo"],
			"assignments": {
				"9": "multiplo di 3", "12": "multiplo di 3", "15": "multiplo di 3", "27": "multiplo di 3",
				"36": "multiplo di 3", "48": "multiplo di 3", "51": "multiplo di 3", "63": "multiplo di 3",
				"72": "multiplo di 3", "81": "multiplo di 3", "111": "multiplo di 3", "123": "multiplo di 3",
				"7": "non multiplo", "10": "non multiplo", "14": "non multiplo", "22": "non multiplo",
				"25": "non multiplo", "34": "non multiplo", "41": "non multiplo", "50": "non multiplo",
				"64": "non multiplo", "70": "non multiplo", "97": "non multiplo", "115": "non multiplo"}},
		# Scuola media — numeri primi, frazioni rispetto a 1/2, interi.
		{"explanation": "Un numero è primo se ha esattamente due divisori, uno e se stesso. L'1 non è primo, perché di divisori ne ha uno solo.", "topic": "primi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni numero: primo o composto?",
			"categories": ["primo", "composto"],
			"assignments": {
				"2": "primo", "5": "primo", "7": "primo", "11": "primo", "13": "primo", "17": "primo",
				"19": "primo", "23": "primo", "29": "primo", "31": "primo", "37": "primo", "41": "primo",
				"4": "composto", "6": "composto", "9": "composto", "15": "composto", "21": "composto", "25": "composto",
				"27": "composto", "33": "composto", "35": "composto", "39": "composto", "49": "composto", "51": "composto"}},
		{"explanation": "Per confrontare con 1/2 si guarda se il numeratore è più o meno della metà del denominatore: in 3/8 la metà di 8 è 4, e 3 è meno.", "topic": "frazioni", "minLevel": 6, "draw": 6, "prompt": "Smista ogni frazione rispetto a 1/2.",
			"categories": ["minore di 1/2", "uguale a 1/2", "maggiore di 1/2"],
			"assignments": {
				"1/4": "minore di 1/2", "1/3": "minore di 1/2", "2/5": "minore di 1/2", "3/8": "minore di 1/2",
				"1/6": "minore di 1/2", "4/10": "minore di 1/2", "2/9": "minore di 1/2", "5/12": "minore di 1/2",
				"2/4": "uguale a 1/2", "3/6": "uguale a 1/2", "4/8": "uguale a 1/2", "5/10": "uguale a 1/2",
				"6/12": "uguale a 1/2", "7/14": "uguale a 1/2", "8/16": "uguale a 1/2", "9/18": "uguale a 1/2",
				"3/4": "maggiore di 1/2", "5/6": "maggiore di 1/2", "3/5": "maggiore di 1/2", "5/8": "maggiore di 1/2",
				"7/10": "maggiore di 1/2", "7/12": "maggiore di 1/2", "5/9": "maggiore di 1/2", "9/16": "maggiore di 1/2"}},
		# Le proporzioni erano promesse dalla lezione del mondo 13 ma servite solo dal
		# banco a scelta multipla. Con la tavolozza più ricca della Fase 1 le campate
		# di banco vengono sostituite più spesso, e l'argomento è sparito del tutto:
		# preso da `content_depth_audit`. La cura non è iniettare meno minigiochi — è
		# dare ai minigiochi l'argomento che il mondo promette.
		{"explanation": "Una proporzione è vera se i prodotti incrociati coincidono: si moltiplicano gli estremi e i medi e si confrontano.", "topic": "proporzioni", "minLevel": 13, "draw": 6, "prompt": "Ogni proporzione è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"2 : 4 = 3 : 6": "vera", "1 : 3 = 5 : 15": "vera", "4 : 6 = 6 : 9": "vera",
				"3 : 5 = 12 : 20": "vera", "2 : 7 = 6 : 21": "vera", "5 : 8 = 15 : 24": "vera",
				"9 : 12 = 3 : 4": "vera", "10 : 25 = 2 : 5": "vera", "7 : 14 = 4 : 8": "vera",
				"6 : 10 = 9 : 15": "vera", "8 : 12 = 10 : 15": "vera", "14 : 21 = 2 : 3": "vera",
				"2 : 4 = 3 : 5": "falsa", "1 : 3 = 4 : 15": "falsa", "4 : 6 = 6 : 10": "falsa",
				"3 : 5 = 12 : 18": "falsa", "2 : 7 = 6 : 20": "falsa", "5 : 8 = 15 : 25": "falsa",
				"9 : 12 = 3 : 5": "falsa", "10 : 25 = 2 : 6": "falsa", "7 : 14 = 4 : 9": "falsa",
				"6 : 10 = 9 : 16": "falsa", "8 : 12 = 10 : 14": "falsa", "14 : 21 = 2 : 4": "falsa"}},
		{"explanation": "Il segno dice da che parte dello zero sta il numero: i positivi a destra, i negativi a sinistra.", "topic": "interi", "minLevel": 6, "draw": 6, "prompt": "Smista ogni numero intero: positivo o negativo?",
			"categories": ["positivo", "negativo"],
			"assignments": {
				"5": "positivo", "12": "positivo", "3": "positivo", "27": "positivo", "48": "positivo", "101": "positivo",
				"+9": "positivo", "+16": "positivo", "+35": "positivo", "74": "positivo", "6": "positivo", "19": "positivo",
				"-3": "negativo", "-8": "negativo", "-1": "negativo", "-15": "negativo", "-24": "negativo", "-40": "negativo",
				"-7": "negativo", "-52": "negativo", "-11": "negativo", "-99": "negativo", "-6": "negativo", "-30": "negativo"}},
		# --- Mondo 1: altre tre ricette (6 agosto 2026) --------------------------
		{"explanation": "Una divisione è esatta quando non avanza niente. Se il dividendo sta nella tabellina del divisore, il resto è zero: si vede prima di dividere.", "topic": "divisioni", "draw": 6, "prompt": "Smista le divisioni: esatte oppure con resto.",
			"categories": ["esatta", "con resto"],
			"assignments": {
				"12 ÷ 4": "esatta", "36 ÷ 6": "esatta", "45 ÷ 9": "esatta", "56 ÷ 8": "esatta",
				"81 ÷ 9": "esatta", "100 ÷ 5": "esatta", "144 ÷ 12": "esatta", "63 ÷ 7": "esatta",
				"13 ÷ 4": "con resto", "38 ÷ 6": "con resto", "47 ÷ 9": "con resto", "59 ÷ 8": "con resto",
				"85 ÷ 9": "con resto", "103 ÷ 5": "con resto", "150 ÷ 12": "con resto", "67 ÷ 7": "con resto"}},
		{"explanation": "La parola del problema dice l'operazione: «in tutto» somma, «resta» sottrae, «ciascuno» divide, «ogni... per» moltiplica. Riconoscerla è metà del lavoro.", "topic": "problemi", "draw": 6, "prompt": "Quale operazione serve per risolvere?",
			"categories": ["addizione", "sottrazione", "moltiplicazione", "divisione"],
			"assignments": {
				"Ho 12 figurine e ne ricevo 7: quante in tutto?": "addizione",
				"In classe ci sono 14 maschi e 11 femmine: quanti alunni?": "addizione",
				"Al mattino 8 gradi, a mezzogiorno 9 in più: quanti gradi?": "addizione",
				"Avevo 50 euro e ne spendo 18: quanti me ne restano?": "sottrazione",
				"Il libro ha 200 pagine, ne ho lette 74: quante mancano?": "sottrazione",
				"Sono partito con 30 caramelle, ora ne ho 12: quante ne ho date?": "sottrazione",
				"6 scatole con 8 penne ciascuna: quante penne?": "moltiplicazione",
				"Un biglietto costa 7 euro, siamo in 5: quanto spendiamo?": "moltiplicazione",
				"Ogni giorno leggo 15 pagine per 4 giorni: quante pagine?": "moltiplicazione",
				"48 biscotti divisi fra 6 bambini: quanti a testa?": "divisione",
				"Ho 60 euro e ogni quaderno costa 5: quanti ne compro?": "divisione",
				"90 sedie in file da 15: quante file?": "divisione"}},
		{"explanation": "Un numero si legge da sinistra: prima le migliaia, poi le centinaia. A parità di cifre vince la prima che è diversa, non l'ultima.", "topic": "numeri", "draw": 6, "prompt": "Smista i numeri: sopra o sotto mille?",
			"categories": ["sotto mille", "mille o più"],
			"assignments": {
				"342": "sotto mille", "87": "sotto mille", "999": "sotto mille", "706": "sotto mille",
				"5": "sotto mille", "480": "sotto mille", "913": "sotto mille", "268": "sotto mille",
				"1000": "mille o più", "1204": "mille o più", "3560": "mille o più", "10000": "mille o più",
				"1001": "mille o più", "2450": "mille o più", "7890": "mille o più", "12500": "mille o più"}},
		# --- Il programma di medie e biennio prende le mani (6 settembre 2026) ---
		#
		# Quattro argomenti nuovi del banco che si smistano meglio di quanto si
		# rispondano. Il primo è il più utile di tutti: **l'unità di misura non è
		# una decorazione in fondo al numero**, e chi non distingue cm da cm³ non
		# può accorgersi che un risultato è assurdo. Gli altri tre portano dentro
		# un gesto la parte del biennio che altrimenti resterebbe solo scritta.
		#
		# Nessun nome di contenitore compare dentro le tessere: è la scorciatoia
		# del «bidone» misurata da `scorciatoie_minigiochi_audit`, e chi smista
		# leggendo l'etichetta invece di ragionare qui non arriva da nessuna parte.
		{"explanation": "L'unità dice quante dimensioni sono in gioco: i cm misurano una linea, i cm² una superficie piatta, i cm³ uno spazio pieno. Sbagliare unità vuol dire aver risposto a un'altra domanda.", "topic": "solidi", "minLevel": 11, "draw": 6, "prompt": "Smista ogni cosa secondo che cosa misura.",
			"categories": ["lunghezza", "superficie", "volume"],
			"assignments": {
				"cm": "lunghezza", "m": "lunghezza", "km": "lunghezza",
				"il perimetro di un quadrato": "lunghezza", "lo spigolo di un cubo": "lunghezza",
				"il raggio di un cerchio": "lunghezza", "quanto filo per recintare": "lunghezza",
				"il diametro di una ruota": "lunghezza",
				"cm²": "superficie", "m²": "superficie", "ettaro": "superficie",
				"quanta vernice per dipingere": "superficie", "l'area di un rettangolo": "superficie",
				"quanta carta per incartare": "superficie", "il pavimento di una stanza": "superficie",
				"l'etichetta intorno a un barattolo": "superficie",
				"cm³": "volume", "dm³": "volume", "m³": "volume", "litri": "volume",
				"millilitri": "volume", "quanta acqua ci sta dentro": "volume",
				"lo spazio pieno di una scatola": "volume", "quanti cubetti riempiono una scatola": "volume"}},
		{"explanation": "I termini si contano dai segni di più e di meno che li separano: uno solo è un monomio, due un binomio, tre un trinomio. Le potenze e le moltiplicazioni non spezzano niente.", "topic": "calcolo-letterale", "minLevel": 17, "draw": 6, "prompt": "Smista ogni espressione per quanti termini ha.",
			"categories": ["monomio", "binomio", "trinomio"],
			"assignments": {
				"3x": "monomio", "−5a": "monomio", "x²": "monomio", "7": "monomio",
				"2ab": "monomio", "x³y": "monomio", "−a": "monomio", "12xy": "monomio",
				"3x + 5": "binomio", "a − b": "binomio", "x² + 1": "binomio", "2a + 3b": "binomio",
				"x − 7": "binomio", "4y + y²": "binomio", "5 − x": "binomio", "ab + 2": "binomio",
				"x² + 2x + 1": "trinomio", "a + b + c": "trinomio", "3x − 2y + 5": "trinomio",
				"x² − x − 6": "trinomio", "2a + 3b − c": "trinomio", "x³ + x + 1": "trinomio",
				"4 + x + x²": "trinomio", "a² + 2ab + b²": "trinomio"}},
		{"explanation": "Ogni equazione è una retta: se le rette si incrociano c'è una risposta sola, se sono parallele non ce n'è nessuna, se sono la stessa retta ce ne sono infinite. Si guarda la pendenza prima di calcolare.", "topic": "sistemi", "minLevel": 18, "draw": 6, "prompt": "Smista ogni coppia di rette per quante risposte dà.",
			"categories": ["un punto solo", "nessun punto", "tutta la retta"],
			"assignments": {
				"due rette che si incrociano": "un punto solo", "x + y = 5 e x − y = 1": "un punto solo",
				"y = 2x e y = x + 1": "un punto solo", "pendenze diverse": "un punto solo",
				"y = 3x + 1 e y = −x": "un punto solo", "x = 2 e y = 5": "un punto solo",
				"y = x e y = 4 − x": "un punto solo", "inclinazioni diverse": "un punto solo",
				"due rette parallele distinte": "nessun punto", "y = 2x + 1 e y = 2x + 5": "nessun punto",
				"stessa pendenza, quote diverse": "nessun punto", "x + y = 3 e x + y = 7": "nessun punto",
				"2x + 2y = 4 e x + y = 9": "nessun punto", "y = x + 1 e y = x + 6": "nessun punto",
				"3x − y = 1 e 3x − y = 8": "nessun punto", "rette che non si toccano mai": "nessun punto",
				"due rette sovrapposte": "tutta la retta", "y = 2x e 2y = 4x": "tutta la retta",
				"x + y = 4 e 2x + 2y = 8": "tutta la retta", "la seconda è la prima raddoppiata": "tutta la retta",
				"y = x + 3 e 2y = 2x + 6": "tutta la retta", "le due rette coincidono": "tutta la retta",
				"5x + 5y = 10 e x + y = 2": "tutta la retta", "la seconda non aggiunge niente": "tutta la retta"}},
		{"explanation": "Per controllare se un numero risolve una disequazione lo si sostituisce e si guarda se la scrittura resta vera. Attenzione al confine: con > il valore uguale è fuori, con ≥ è dentro.", "topic": "disequazioni", "minLevel": 18, "draw": 6, "prompt": "Ogni affermazione è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"7 > 5": "vera", "x > 5 con x = 9": "vera", "3 ≤ 3": "vera",
				"x ≥ 2 con x = 2": "vera", "−1 < 0": "vera", "x < 10 con x = 4": "vera",
				"−5 < −2": "vera", "x ≤ 6 con x = 6": "vera", "0 > −3": "vera",
				"2x < 10 con x = 3": "vera", "x + 1 > 4 con x = 5": "vera", "−x > 0 con x = −2": "vera",
				"5 > 7": "falsa", "x > 5 con x = 5": "falsa", "4 ≤ 3": "falsa",
				"x ≥ 2 con x = 1": "falsa", "0 < −1": "falsa", "x < 10 con x = 12": "falsa",
				"−2 < −5": "falsa", "x ≤ 6 con x = 8": "falsa", "−3 > 0": "falsa",
				"2x < 10 con x = 6": "falsa", "x + 1 > 4 con x = 2": "falsa", "−x > 0 con x = 3": "falsa"}},
		# --- Quattro smistamenti per gli argomenti del 7 settembre 2026 ----------
		#
		# Lo smistamento è il gesto giusto quando la competenza è **riconoscere a
		# quale famiglia appartiene un caso**: che triangolo è, che angolo è, che
		# trasformazione è, in quale insieme sta un numero. Nessuna tessera nomina
		# il proprio bidone — è la scorciatoia che misura
		# `scorciatoie_minigiochi_audit` — e nei primi due le tessere sono numeri
		# nudi, quindi si smista solo confrontandoli fra loro.
		{"explanation": "Il nome del triangolo dipende da quanti lati sono uguali: tre uguali è equilatero, due uguali è isoscele, nessuno uguale è scaleno. Si contano le uguaglianze, non si guarda il disegno — che può essere storto o girato.", "topic": "figure", "minLevel": 4, "draw": 6, "prompt": "Smista ogni triangolo guardando i suoi tre lati.",
			"categories": ["equilatero", "isoscele", "scaleno"],
			"assignments": {
				"lati 5, 5, 5": "equilatero", "lati 7, 7, 7": "equilatero",
				"lati 12, 12, 12": "equilatero", "lati 3, 3, 3": "equilatero",
				"lati 9, 9, 9": "equilatero", "lati 20, 20, 20": "equilatero",
				"lati 6, 6, 6": "equilatero", "lati 15, 15, 15": "equilatero",
				"lati 6, 6, 4": "isoscele", "lati 8, 5, 5": "isoscele",
				"lati 10, 10, 3": "isoscele", "lati 7, 9, 9": "isoscele",
				"lati 4, 4, 7": "isoscele", "lati 13, 13, 5": "isoscele",
				"lati 11, 6, 6": "isoscele", "lati 2, 3, 3": "isoscele",
				"lati 3, 4, 5": "scaleno", "lati 6, 8, 10": "scaleno",
				"lati 7, 9, 12": "scaleno", "lati 5, 6, 7": "scaleno",
				"lati 2, 3, 4": "scaleno", "lati 8, 11, 14": "scaleno",
				"lati 9, 10, 12": "scaleno", "lati 4, 7, 9": "scaleno"}},
		{"explanation": "I nomi degli angoli sono una scala che parte dai novanta gradi: sotto è acuto, esattamente novanta è retto, sopra è ottuso. Le tessere senza numero si risolvono ricordando che il giro completo vale 360° e il piatto 180°.", "topic": "figure", "minLevel": 2, "draw": 6, "prompt": "Smista ogni angolo secondo la sua ampiezza.",
			"categories": ["acuto", "retto", "ottuso"],
			"assignments": {
				"30°": "acuto", "45°": "acuto", "10°": "acuto", "75°": "acuto",
				"89°": "acuto", "60°": "acuto", "20°": "acuto",
				"fra le lancette all'una in punto": "acuto",
				"90°": "retto", "un quarto di giro": "retto",
				"l'angolo della squadra": "retto", "l'angolo di un foglio": "retto",
				"ognuno degli angoli del quadrato": "retto",
				"dove due linee perpendicolari si incrociano": "retto",
				"la metà di un angolo piatto": "retto",
				"fra le lancette alle tre in punto": "retto",
				"120°": "ottuso", "135°": "ottuso", "91°": "ottuso", "150°": "ottuso",
				"170°": "ottuso", "100°": "ottuso", "110°": "ottuso",
				"fra le lancette alle cinque in punto": "ottuso"}},
		{"explanation": "Le tre trasformazioni si distinguono da ciò che serve per descriverle: una freccia per lo spostamento, un centro e un angolo per il giro, uno specchio per il ribaltamento. Nessuna delle tre cambia le misure della figura.", "topic": "trasformazioni", "minLevel": 6, "draw": 6, "prompt": "Smista ogni caso nella trasformazione che lo descrive.",
			"categories": ["traslazione", "rotazione", "simmetria assiale"],
			"assignments": {
				"la figura scivola senza girare": "traslazione",
				"serve una freccia con direzione e verso": "traslazione",
				"ogni punto si sposta di 5 a destra": "traslazione",
				"(3, 2) diventa (8, 2)": "traslazione",
				"le mattonelle ripetute sul pavimento": "traslazione",
				"il disegno rifatto identico più in basso": "traslazione",
				"tutti i punti fanno lo stesso viaggio": "traslazione",
				"il nastro trasportatore che porta avanti la scatola": "traslazione",
				"serve un centro e un angolo": "rotazione",
				"le lancette che avanzano di un quarto d'ora": "rotazione",
				"la ruota panoramica in movimento": "rotazione",
				"il quadrato girato di 90° torna uguale": "rotazione",
				"la figura fa mezzo giro attorno a un punto": "rotazione",
				"la chiave nella serratura": "rotazione",
				"l'elica del ventilatore": "rotazione",
				"la Terra che compie un giro su sé stessa": "rotazione",
				"la farfalla con le ali aperte": "simmetria assiale",
				"l'immagine riflessa nello specchio": "simmetria assiale",
				"si piega il foglio e i bordi combaciano": "simmetria assiale",
				"(3, 2) diventa (−3, 2)": "simmetria assiale",
				"la scritta AMBULANZA letta nello specchietto": "simmetria assiale",
				"il riflesso della montagna nel lago": "simmetria assiale",
				"la lettera A ribaltata lungo la sua metà": "simmetria assiale",
				"le due metà di un cuore disegnato": "simmetria assiale"}},
		# L'intersezione senza il disegno: un numero sta in tutti e due i gruppi
		# quando ha dentro tutti e due i fattori, e i multipli di sei sono
		# esattamente quello. È il punto in cui il linguaggio degli insiemi
		# smette di essere vocabolario e diventa un conto.
		{"explanation": "Un numero sta in tutti e due i gruppi se ha dentro sia il tre sia il due: e chi ha tutti e due ha anche il loro prodotto, cioè è multiplo di sei. L'intersezione di due insiemi si trova guardando i fattori, non provando a caso.", "topic": "insiemi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni numero: è multiplo di tre, è pari, oppure tutti e due?",
			"categories": ["solo multiplo di tre", "solo pari", "tutti e due"],
			"assignments": {
				"3": "solo multiplo di tre", "9": "solo multiplo di tre",
				"15": "solo multiplo di tre", "21": "solo multiplo di tre",
				"27": "solo multiplo di tre", "33": "solo multiplo di tre",
				"45": "solo multiplo di tre", "51": "solo multiplo di tre",
				"2": "solo pari", "4": "solo pari", "8": "solo pari", "10": "solo pari",
				"14": "solo pari", "16": "solo pari", "20": "solo pari", "22": "solo pari",
				"6": "tutti e due", "12": "tutti e due", "18": "tutti e due",
				"24": "tutti e due", "30": "tutti e due", "36": "tutti e due",
				"42": "tutti e due", "48": "tutti e due"}},
		# Il discriminante conta le soluzioni PRIMA di calcolarle, ed è la cosa che
		# a scuola si salta per fretta: qui non si risolve nemmeno un'equazione, si
		# decide solo quante risposte aspettarsi. Le tessere sono equazioni, i
		# bidoni sono numeri di soluzioni: nessuna parola in comune, quindi si
		# smista solo guardando b² − 4ac.
		{"explanation": "Il segno di b² − 4ac decide tutto: positivo dà due soluzioni, zero una sola, negativo nessuna — perché servirebbe la radice di un numero negativo. Nei casi senza termine noto (x² − 3x) la x si raccoglie e le soluzioni sono sempre due, una delle quali è zero.", "topic": "secondo-grado", "minLevel": 19, "draw": 6, "prompt": "Smista ogni equazione secondo quante soluzioni reali ha.",
			"categories": ["due soluzioni", "una soluzione", "nessuna soluzione"],
			"assignments": {
				"x² − 5x + 6 = 0": "due soluzioni", "x² − 1 = 0": "due soluzioni",
				"x² − 4 = 0": "due soluzioni", "x² + x − 2 = 0": "due soluzioni",
				"x² − 3x = 0": "due soluzioni", "x² − 7x + 12 = 0": "due soluzioni",
				"x² + 2x − 3 = 0": "due soluzioni", "x² − 9 = 0": "due soluzioni",
				"x² − 2x + 1 = 0": "una soluzione", "x² + 2x + 1 = 0": "una soluzione",
				"x² − 4x + 4 = 0": "una soluzione", "x² + 4x + 4 = 0": "una soluzione",
				"x² − 6x + 9 = 0": "una soluzione", "x² + 6x + 9 = 0": "una soluzione",
				"x² − 8x + 16 = 0": "una soluzione", "x² − 10x + 25 = 0": "una soluzione",
				"x² + 4 = 0": "nessuna soluzione", "x² + 1 = 0": "nessuna soluzione",
				"x² + x + 1 = 0": "nessuna soluzione", "x² − x + 1 = 0": "nessuna soluzione",
				"x² + 2x + 5 = 0": "nessuna soluzione", "x² − 2x + 5 = 0": "nessuna soluzione",
				"x² + 9 = 0": "nessuna soluzione", "x² + 3 = 0": "nessuna soluzione"}},
	],
	"fisica": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "misure", "minLevel": 10, "draw": 6, "prompt": "Smista ogni unita' secondo la grandezza che misura.",
			"categories": ["quanta materia", "quanto spazio", "quanto tempo"],
			"assignments": {
				"chilogrammo": "quanta materia", "grammo": "quanta materia", "tonnellata": "quanta materia",
				"quintale": "quanta materia", "milligrammo": "quanta materia", "ettogrammo": "quanta materia",
				"metro": "quanto spazio", "centimetro": "quanto spazio", "chilometro": "quanto spazio",
				"millimetro": "quanto spazio", "decametro": "quanto spazio", "micrometro": "quanto spazio",
				"secondo": "quanto tempo", "minuto": "quanto tempo", "ora": "quanto tempo",
				"millisecondo": "quanto tempo", "giorno": "quanto tempo", "anno": "quanto tempo"},
			"explanation": "Ogni grandezza ha una sua famiglia di unita', e i prefissi si ripetono uguali in tutte: chilo vale mille ovunque, milli vale un millesimo ovunque. Imparato il prefisso, vale per qualunque grandezza."},
		{"topic": "forze", "minLevel": 16, "draw": 6, "prompt": "Smista ogni situazione: le forze si annullano oppure no?",
			"categories": ["forze in equilibrio", "forze sbilanciate"],
			"assignments": {
				"un libro fermo sul tavolo": "forze in equilibrio", "un lampadario appeso immobile": "forze in equilibrio",
				"un'auto a velocita' costante in rettilineo": "forze in equilibrio", "una barca ferma che galleggia": "forze in equilibrio",
				"un paracadutista sceso a velocita' costante": "forze in equilibrio", "una cassa spinta che non si muove": "forze in equilibrio",
				"una mela che sta cadendo": "forze sbilanciate", "un'auto che frena": "forze sbilanciate",
				"un razzo che accelera": "forze sbilanciate", "una palla che curva in aria": "forze sbilanciate",
				"un'altalena che riparte": "forze sbilanciate", "un ciclista che aumenta velocita'": "forze sbilanciate"},
			"explanation": "Fermo e a velocita' costante sono lo stesso caso: in tutti e due le forze si annullano. Cambiare velocita' o direzione richiede sempre una forza netta, e questa e' la scoperta che ha rovesciato la fisica di Aristotele."},
		{"topic": "onde-luce", "minLevel": 19, "draw": 6, "prompt": "Smista ogni fenomeno secondo che cosa fa la luce quando incontra la superficie.",
			"categories": ["torna indietro", "prosegue piegando", "viene trattenuta"],
			"assignments": {
				"la propria immagine nello specchio": "torna indietro", "il riflesso sull'acqua ferma": "torna indietro",
				"il bagliore su una lamina lucida": "torna indietro", "il faro che rimanda il fascio": "torna indietro",
				"il bastone che sembra spezzato": "prosegue piegando", "l'arcobaleno dentro una goccia": "prosegue piegando",
				"la lente che ingrandisce": "prosegue piegando", "il fondo della piscina che sembra vicino": "prosegue piegando",
				"un panno nero al sole che scotta": "viene trattenuta", "una tenda spessa che fa buio": "viene trattenuta",
				"l'asfalto che si scalda d'estate": "viene trattenuta", "il fumo denso che oscura": "viene trattenuta"},
			"explanation": "Sono i tre destini possibili di un raggio, e quasi sempre avvengono insieme in proporzioni diverse: una finestra ne lascia passare molta, ne riflette un poco e ne trattiene pochissima."},
		{"explanation": "L'energia potenziale è immagazzinata dalla posizione, la cinetica è quella del movimento in corso: cadendo la prima diventa la seconda.", "topic": "energia", "draw": 6, "prompt": "Smista ogni situazione per l'energia prevalente.",
			"categories": ["potenziale", "cinetica"],
			"assignments": {
				"Palla in cima a una rampa": "potenziale", "Molla compressa": "potenziale",
				"Arco teso": "potenziale", "Acqua ferma dietro una diga": "potenziale",
				"Libro sullo scaffale alto": "potenziale", "Elastico tirato": "potenziale",
				"Sciatore fermo in cima": "potenziale", "Pendolo nel punto più alto": "potenziale",
				"Sasso sul bordo del dirupo": "potenziale", "Altalena ferma in alto": "potenziale",
				"Molla di un orologio caricata": "potenziale", "Palloncino gonfiato": "potenziale",
				"Palla che rotola": "cinetica", "Auto in corsa": "cinetica",
				"Freccia in volo": "cinetica", "Acqua che scende dalla diga": "cinetica",
				"Libro che cade": "cinetica", "Elastico appena lasciato": "cinetica",
				"Sciatore in discesa": "cinetica", "Pendolo nel punto più basso": "cinetica",
				"Sasso in caduta": "cinetica", "Altalena a metà corsa": "cinetica",
				"Lancetta che gira": "cinetica", "Aria che esce dal palloncino": "cinetica"}},
		{"explanation": "Lo stato si riconosce da forma e volume: il solido tiene entrambi, il liquido solo il volume, il gas nessuno dei due.", "topic": "materia", "draw": 6, "prompt": "Smista ogni materiale nel suo stato a temperatura ambiente.",
			"categories": ["solido", "liquido", "gassoso"],
			"assignments": {
				"Ghiaccio": "solido", "Ferro": "solido", "Legno": "solido", "Vetro": "solido",
				"Sale": "solido", "Rame": "solido", "Plastica": "solido", "Marmo": "solido",
				"Acqua": "liquido", "Latte": "liquido", "Olio": "liquido", "Alcol": "liquido",
				"Mercurio": "liquido", "Benzina": "liquido", "Miele": "liquido", "Aceto": "liquido",
				"Vapore": "gassoso", "Aria": "gassoso", "Ossigeno": "gassoso", "Elio": "gassoso",
				"Azoto": "gassoso", "Metano": "gassoso", "Anidride carbonica": "gassoso", "Idrogeno": "gassoso"}},
		# Scuola media — forze di contatto o a distanza, e la luce nei materiali.
		{"explanation": "Le forze di contatto hanno bisogno di toccare, quelle a distanza agiscono attraverso lo spazio vuoto — come la gravità e il magnetismo.", "topic": "forze", "minLevel": 5, "draw": 6, "prompt": "Smista ogni forza: agisce per contatto o a distanza?",
			"categories": ["contatto", "a distanza"],
			"assignments": {
				"Attrito": "contatto", "Spinta": "contatto", "Tensione della fune": "contatto",
				"Resistenza dell'aria": "contatto", "Urto fra due palline": "contatto", "Compressione di una molla": "contatto",
				"Attrito volvente della ruota": "contatto", "Spinta di Archimede": "contatto",
				"Trazione di un rimorchio": "contatto", "Pressione del vento sulla vela": "contatto",
				"Reazione del pavimento": "contatto", "Spinta del remo sull'acqua": "contatto",
				"Gravità": "a distanza", "Magnetismo": "a distanza", "Forza elettrica": "a distanza",
				"Attrazione fra Terra e Luna": "a distanza", "Calamita che attira un chiodo": "a distanza",
				"Peso di un corpo": "a distanza", "Repulsione fra due poli nord": "a distanza",
				"Attrazione del Sole sui pianeti": "a distanza", "Elettrizzazione per strofinio": "a distanza",
				"Ago della bussola che ruota": "a distanza", "Fulmine fra nuvola e suolo": "a distanza",
				"Caduta di una mela": "a distanza"}},
		{"explanation": "Confronta le due frecce: peso in basso e spinta dell'acqua in alto. La più grande decide se l'oggetto sale o affonda.", "topic": "galleggiamento", "minLevel": 13, "draw": 6, "prompt": "Smista ogni situazione secondo ciò che farà l'oggetto nell'acqua.",
			"categories": ["sale", "resta", "affonda"],
			"assignments": {
				"spinta maggiore del peso": "sale", "pallone tenuto sott'acqua e lasciato": "sale",
				"salvagente immerso e lasciato": "sale", "aria aggiunta al giubbotto del sub": "sale",
				"spinta uguale al peso": "resta", "sommergibile in equilibrio": "resta",
				"pesce fermo alla stessa profondità": "resta", "boa ferma sulla superficie": "resta",
				"peso maggiore della spinta": "affonda", "sasso lasciato in acqua": "affonda",
				"aria tolta al giubbotto del sub": "affonda", "biglia d'acciaio lasciata libera": "affonda"}},
		{"explanation": "Guarda il verso della corrente rispetto alla barca: insieme aiuta, contro rallenta, di lato fa deviare.", "topic": "correnti", "minLevel": 13, "draw": 6, "prompt": "Smista l'effetto della corrente sulla barca.",
			"categories": ["aiuta", "rallenta", "devia"],
			"assignments": {
				"barca a est, corrente a est": "aiuta", "barca a nord, corrente a nord": "aiuta",
				"barca a ovest, corrente a ovest": "aiuta", "barca a sud, corrente a sud": "aiuta",
				"barca a est, corrente a ovest": "rallenta", "barca a nord, corrente a sud": "rallenta",
				"barca a ovest, corrente a est": "rallenta", "barca a sud, corrente a nord": "rallenta",
				"barca a nord, corrente a est": "devia", "barca a est, corrente a sud": "devia",
				"barca a sud, corrente a ovest": "devia", "barca a ovest, corrente a nord": "devia"}},
		{"explanation": "Trasparente lascia passare la luce e vedere le forme, translucido lascia passare la luce ma non le forme, opaco non lascia passare niente.", "topic": "luce", "minLevel": 6, "draw": 6, "prompt": "Smista ogni materiale per come lascia passare la luce.",
			"categories": ["trasparente", "opaco", "translucido"],
			"assignments": {
				"Vetro": "trasparente", "Aria": "trasparente", "Acqua limpida": "trasparente",
				"Plastica trasparente": "trasparente", "Cristallo": "trasparente", "Cellophane": "trasparente",
				"Vetro di finestra": "trasparente", "Ghiaccio limpido": "trasparente",
				"Muro": "opaco", "Legno": "opaco", "Metallo": "opaco", "Cartone": "opaco",
				"Pietra": "opaco", "Stoffa spessa": "opaco", "Terra": "opaco", "Libro chiuso": "opaco",
				"Carta velina": "translucido", "Vetro smerigliato": "translucido", "Carta da forno": "translucido",
				"Nebbia": "translucido", "Tenda leggera": "translucido", "Plastica opalina": "translucido",
				"Acqua torbida": "translucido", "Ghiaccio opaco": "translucido"}},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "Ogni grandezza ha la sua unità: misurare una lunghezza in chilogrammi non è un errore di conto, è una domanda senza senso.", "topic": "misure", "draw": 6, "prompt": "Con quale unità si misura?",
			"categories": ["metro", "chilogrammo", "secondo", "grado"],
			"assignments": {
				"la lunghezza di un banco": "metro", "l'altezza di una porta": "metro",
				"la distanza fra due città": "metro", "la profondità di una piscina": "metro",
				"la massa di una mela": "chilogrammo", "quanto pesa uno zaino": "chilogrammo",
				"la massa di un sacco di farina": "chilogrammo", "quanto pesa un gatto": "chilogrammo",
				"la durata di una corsa": "secondo", "quanto dura una canzone": "secondo",
				"il tempo di caduta di un sasso": "secondo", "quanto dura una lezione": "secondo",
				"la temperatura dell'acqua": "grado", "quanto è caldo il forno": "grado",
				"la febbre di un bambino": "grado", "la temperatura di oggi": "grado"}},
		{"explanation": "Guarda che cosa fa la velocità nel tempo, non quanto è grande adesso. Una bici lentissima che sta partendo sta guadagnando velocità; un treno lanciato che va dritto e tranquillo non ne guadagna né ne perde.", "topic": "moto", "draw": 6, "prompt": "Smista ogni scena: la velocità sta crescendo, sta calando o resta com'è?",
			"categories": ["accelera", "rallenta", "va costante"],
			"assignments": {
				"Il semaforo diventa verde e l'auto parte": "accelera",
				"Il sasso lasciato cade dal tetto": "accelera",
				"La bici scende lungo la discesa": "accelera",
				"Il razzo si stacca dalla rampa": "accelera",
				"Il nuotatore si spinge via dal bordo": "accelera",
				"La pallina rotola giù dallo scivolo": "accelera",
				"Il treno entra in stazione e frena": "rallenta",
				"La palla rotola sull'erba alta": "rallenta",
				"Il paracadute si apre nel cielo": "rallenta",
				"La bici sale lungo la salita": "rallenta",
				"Il pattinatore smette di spingere": "rallenta",
				"L'automobile finisce sulla ghiaia": "rallenta",
				"Il treno corre dritto in pianura": "va costante",
				"La navicella viaggia nello spazio vuoto a motore spento": "va costante",
				"Il tapis roulant porta avanti la valigia": "va costante",
				"L'ascensore è a metà della sua corsa": "va costante",
				"La barca segue il fiume senza remare": "va costante",
				"Il ciclista pedala sempre allo stesso ritmo in pianura": "va costante"}},
		{"explanation": "La stessa spinta può lasciare un buco o non lasciare traccia: dipende da quanta superficie tocca. Tutta la forza su un punto piccolo schiaccia; la stessa forza spalmata su una superficie larga quasi non si sente.", "topic": "pressione", "minLevel": 13, "draw": 6, "prompt": "Smista ogni caso: a parità di forza, lascia il segno o quasi no?",
			"categories": ["schiaccia di più", "schiaccia di meno"],
			"assignments": {
				"Il tacco a spillo sul parquet": "schiaccia di più",
				"La punta della puntina nel muro": "schiaccia di più",
				"Il coltello affilato sul pane": "schiaccia di più",
				"Lo spigolo dello zaino sulla spalla": "schiaccia di più",
				"Il chiodo battuto dal martello": "schiaccia di più",
				"La lama dei pattini sul ghiaccio": "schiaccia di più",
				"Il manico sottile di una busta pesante": "schiaccia di più",
				"Un sasso appuntito sotto il sacco a pelo": "schiaccia di più",
				"Lo sci largo sulla neve": "schiaccia di meno",
				"La ciaspola sulla neve fresca": "schiaccia di meno",
				"Il cingolo del trattore nel fango": "schiaccia di meno",
				"La zampa larga del cammello sulla sabbia": "schiaccia di meno",
				"Il cuscino sotto il ginocchio": "schiaccia di meno",
				"La cinghia larga dello zaino": "schiaccia di meno",
				"Il materassino gonfio sotto la schiena": "schiaccia di meno",
				"Il palmo aperto della mano": "schiaccia di meno"}},
		{"explanation": "Alcune forze hanno bisogno di toccare, altre no: gravità e magnetismo agiscono attraverso lo spazio vuoto, ed è la cosa che ha stupito di più chi le ha studiate.", "topic": "forze", "draw": 6, "prompt": "Smista ogni forza: agisce a contatto o a distanza?",
			"categories": ["a contatto", "a distanza"],
			"assignments": {
				"attrito fra ruota e strada": "a contatto", "spinta di una mano": "a contatto",
				"tensione di una corda": "a contatto", "resistenza dell'aria": "a contatto",
				"forza elastica di una molla": "a contatto", "urto fra due palline": "a contatto",
				"gravità della Terra": "a distanza", "attrazione di una calamita": "a distanza",
				"forza fra due cariche elettriche": "a distanza", "attrazione fra Terra e Luna": "a distanza",
				"campo magnetico che devia la bussola": "a distanza", "gravità del Sole sui pianeti": "a distanza"}},
	],
	"musica": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "ritmo", "minLevel": 7, "draw": 6, "prompt": "Smista ogni figura secondo quanto dura.",
			"categories": ["dura di piu'", "dura di meno"],
			"assignments": {
				"semibreve": "dura di piu'", "minima": "dura di piu'", "semiminima": "dura di piu'",
				"croma": "dura di meno", "semicroma": "dura di meno", "biscroma": "dura di meno"},
			"explanation": "Ogni figura vale la meta' di quella prima: e' una scala di dimezzamenti, non un elenco da ricordare. Capito il dimezzamento, si ricava qualunque durata senza impararla."},
		{"topic": "strumenti", "minLevel": 13, "draw": 6, "prompt": "Smista ogni strumento secondo che cosa vibra per produrre il suono.",
			"categories": ["una corda tesa", "una colonna d'aria", "una pelle percossa"],
			"assignments": {
				"violino": "una corda tesa", "arpa": "una corda tesa", "chitarra": "una corda tesa",
				"contrabbasso": "una corda tesa", "violoncello": "una corda tesa", "mandolino": "una corda tesa",
				"flauto": "una colonna d'aria", "tromba": "una colonna d'aria", "clarinetto": "una colonna d'aria",
				"oboe": "una colonna d'aria", "corno": "una colonna d'aria", "fagotto": "una colonna d'aria",
				"tamburo": "una pelle percossa", "timpano": "una pelle percossa", "bongo": "una pelle percossa",
				"grancassa": "una pelle percossa", "rullante": "una pelle percossa", "tamburello": "una pelle percossa"},
			"explanation": "Non conta il materiale ne' la forma: conta che cosa vibra. E' per questo che il sassofono, tutto d'ottone, sta con i legni — dentro vibra una linguetta di canna."},
		{"topic": "dinamica", "minLevel": 16, "draw": 6, "prompt": "Smista ogni indicazione secondo se chiede di aumentare o di ridurre.",
			"categories": ["si cresce", "si cala"],
			"assignments": {
				"crescendo": "si cresce", "forte": "si cresce", "fortissimo": "si cresce",
				"rinforzando": "si cresce", "sforzando": "si cresce",
				"diminuendo": "si cala", "piano": "si cala", "pianissimo": "si cala",
				"morendo": "si cala", "calando": "si cala"},
			"explanation": "Le indicazioni di dinamica sono ordini al musicista, non descrizioni: dicono che cosa fare adesso rispetto a un attimo fa. Per questo hanno senso solo dentro un brano, mai da sole."},
		{"topic": "tempo", "minLevel": 19, "draw": 6, "prompt": "Smista ogni andamento: piu' lento o piu' mosso di una camminata?",
			"categories": ["piu' lento", "piu' mosso"],
			"assignments": {
				"largo": "piu' lento", "adagio": "piu' lento", "lento": "piu' lento",
				"grave": "piu' lento", "andantino": "piu' lento",
				"allegro": "piu' mosso", "vivace": "piu' mosso", "presto": "piu' mosso",
				"prestissimo": "piu' mosso", "allegretto": "piu' mosso"},
			"explanation": "«Andante» vuol dire proprio «che cammina», ed e' il riferimento di tutti gli altri: sotto ci sono gli andamenti larghi, sopra quelli mossi. Il tempo si impara rispetto a un passo umano, non a un numero."},
		{"topic": "intervalli", "minLevel": 22, "draw": 6, "prompt": "Smista ogni intervallo secondo quanto suona concluso all'orecchio.",
			"categories": ["riposa", "chiede di proseguire"],
			"assignments": {
				"ottava": "riposa", "quinta giusta": "riposa", "quarta giusta": "riposa",
				"terza maggiore": "riposa", "terza minore": "riposa", "sesta maggiore": "riposa",
				"seconda minore": "chiede di proseguire", "settima maggiore": "chiede di proseguire", "tritono": "chiede di proseguire",
				"settima minore": "chiede di proseguire", "seconda maggiore": "chiede di proseguire", "nona minore": "chiede di proseguire"},
			"explanation": "Alcuni intervalli suonano finiti e altri lasciano in sospeso: su questa tensione si regge quasi tutta la musica occidentale, perche' un suono che chiede di proseguire tiene chi ascolta in attesa."},
		# L15. Le famiglie dell'orchestra. Il sassofono è il caso che insegna la
		# regola: è di ottone ma sta nei legni, perché la famiglia la decide come
		# nasce il suono — l'ancia — non di che materiale è fatto lo strumento.
		{"explanation": "Nell'orchestra le famiglie si dividono per come nasce il suono: sfregando corde, soffiando in un tubo di legno o di metallo, percuotendo.", "topic": "strumenti", "minLevel": 15, "draw": 6, "prompt": "Smista ogni strumento nella sua famiglia dell'orchestra.",
			"categories": ["archi", "legni", "ottoni", "percussioni"],
			"assignments": {
				"Violino": "archi", "Viola": "archi", "Violoncello": "archi",
				"Contrabbasso": "archi", "Arpa": "archi",
				"Flauto": "legni", "Oboe": "legni", "Clarinetto": "legni",
				"Fagotto": "legni", "Sassofono": "legni",
				"Tromba": "ottoni", "Trombone": "ottoni", "Corno": "ottoni",
				"Tuba": "ottoni", "Cornetta": "ottoni",
				"Timpani": "percussioni", "Grancassa": "percussioni", "Piatti": "percussioni",
				"Triangolo": "percussioni", "Xilofono": "percussioni"}},
		{"explanation": "Il gruppo dipende da che cosa vibra: una corda, una colonna d'aria o una superficie colpita.", "topic": "strumenti", "draw": 6, "prompt": "Smista ogni strumento nella sua famiglia.",
			"categories": ["corde", "fiati", "percussioni"],
			"assignments": {
				"Chitarra": "corde", "Violino": "corde", "Viola": "corde", "Violoncello": "corde",
				"Contrabbasso": "corde", "Arpa": "corde", "Mandolino": "corde", "Banjo": "corde",
				"Flauto": "fiati", "Tromba": "fiati", "Clarinetto": "fiati", "Sassofono": "fiati",
				"Oboe": "fiati", "Trombone": "fiati", "Corno": "fiati", "Fagotto": "fiati",
				"Tamburo": "percussioni", "Timpani": "percussioni", "Piatti": "percussioni", "Xilofono": "percussioni",
				"Triangolo": "percussioni", "Maracas": "percussioni", "Grancassa": "percussioni", "Tamburello": "percussioni"}},
		{"explanation": "Acustico è ciò che suona da sé, per vibrazione di un materiale; elettronico è ciò che ha bisogno di corrente per produrre il suono.", "topic": "timbro", "draw": 6, "prompt": "Smista ogni strumento: acustico o elettronico?",
			"categories": ["acustico", "elettronico"],
			"assignments": {
				"Violino": "acustico", "Chitarra classica": "acustico", "Pianoforte": "acustico",
				"Flauto traverso": "acustico", "Arpa": "acustico", "Tromba": "acustico",
				"Fisarmonica": "acustico", "Violoncello": "acustico", "Clarinetto": "acustico",
				"Tamburo a mano": "acustico", "Organo a canne": "acustico", "Xilofono": "acustico",
				"Sintetizzatore": "elettronico", "Tastiera elettronica": "elettronico", "Batteria elettronica": "elettronico",
				"Chitarra elettrica": "elettronico", "Basso elettrico": "elettronico", "Theremin": "elettronico",
				"Campionatore": "elettronico", "Drum machine": "elettronico", "Organo elettrico": "elettronico",
				"Vocoder": "elettronico", "Piano digitale": "elettronico", "Sequencer": "elettronico"}},
		# Altezza del suono: strumenti acuti o gravi.
		{"explanation": "L'altezza dipende dalla frequenza della vibrazione: più rapida è, più il suono è acuto. Non c'entra quanto è forte.", "topic": "intervalli", "minLevel": 4, "draw": 6, "prompt": "Smista ogni strumento per l'altezza del suono.",
			"categories": ["acuto", "grave"],
			"assignments": {
				"Flauto": "acuto", "Ottavino": "acuto", "Violino": "acuto", "Tromba": "acuto",
				"Oboe": "acuto", "Clarinetto piccolo": "acuto", "Triangolo": "acuto", "Glockenspiel": "acuto",
				"Mandolino": "acuto", "Soprano": "acuto", "Campanelli": "acuto", "Sassofono contralto": "acuto",
				"Violoncello": "grave", "Contrabbasso": "grave", "Tuba": "grave", "Fagotto": "grave",
				"Trombone": "grave", "Grancassa": "grave", "Timpani": "grave", "Basso elettrico": "grave",
				"Corno": "grave", "Sassofono baritono": "grave", "Organo (canne lunghe)": "grave", "Basso": "grave"}},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "Un suono è acuto quando l'aria vibra tante volte al secondo, e questo succede negli strumenti piccoli e corti. I grandi vibrano piano e suonano gravi.", "topic": "note", "draw": 6, "prompt": "Smista ogni voce o strumento: suono acuto o grave?",
			"categories": ["acuto", "grave"],
			"assignments": {
				"ottavino": "acuto", "flauto": "acuto", "violino": "acuto",
				"triangolo": "acuto", "voce di soprano": "acuto", "campanelli": "acuto",
				"tromba": "acuto", "glockenspiel": "acuto", "flauto dolce": "acuto",
				"voce di bambino": "acuto", "mandolino": "acuto",
				"contrabbasso": "grave", "tuba": "grave", "violoncello": "grave",
				"grancassa": "grave", "voce di basso": "grave", "fagotto": "grave",
				"trombone": "grave", "corno": "grave", "timpani": "grave",
				"contrafagotto": "grave", "gong": "grave"}},
	],
	"elettronica": [
		# Fascia 2, scritte il 9 settembre 2026. Argomento da principiante di
		# proposito: una ricetta a `minLevel` 4 e' idonea anche al mondo 8, che e'
		# il primo incontro con elettronica, e li' `electronics_beginner_audit`
		# vieta legge di Ohm, prefissi, serie/parallelo e gli altri argomenti alti.
		{"explanation": "Prima di capire come funziona un circuito conviene sapere da dove arriva la corrente: una pila la porta con se' ed e' poca, la presa la prende dalla rete ed e' tanta. E' anche la prima regola di sicurezza.", "topic": "elettricita-base", "minLevel": 4, "draw": 6, "prompt": "Smista ogni oggetto secondo da dove prende la corrente.",
			"categories": ["da una pila", "dalla presa di casa"],
			"assignments": {
				"telecomando": "da una pila", "orologio da polso": "da una pila",
				"torcia tascabile": "da una pila", "calcolatrice": "da una pila",
				"telefono senza filo": "da una pila", "giocattolo telecomandato": "da una pila",
				"frigorifero": "dalla presa di casa", "lavatrice": "dalla presa di casa",
				"forno elettrico": "dalla presa di casa", "lampadario": "dalla presa di casa",
				"televisore": "dalla presa di casa", "aspirapolvere": "dalla presa di casa"}},
		{"explanation": "Un conduttore lascia passare facilmente la corrente; un isolante la ostacola e protegge dal contatto. Nei primi circuiti la regola utile è semplice: il metallo interno porta la corrente, plastica e gomma all'esterno ci proteggono.", "topic": "conduttori", "draw": 6, "prompt": "Smista i materiali comuni: lasciano passare la corrente o proteggono dal passaggio?",
			"categories": ["conduttore", "isolante"],
			"assignments": {
				"Rame": "conduttore", "Ferro": "conduttore", "Alluminio": "conduttore", "Acciaio": "conduttore",
				"Moneta metallica": "conduttore", "Graffetta metallica": "conduttore",
				"Chiodo di ferro": "conduttore", "Chiave di casa": "conduttore",
				"Cucchiaio di metallo": "conduttore", "Pentola di alluminio": "conduttore",
				"Lama delle forbici": "conduttore", "Filo di rame spelato": "conduttore",
				"Cerniera del giubbotto": "conduttore",
				"Plastica": "isolante", "Legno secco": "isolante", "Gomma": "isolante", "Vetro": "isolante",
				"Ceramica": "isolante", "Sughero": "isolante",
				"Carta asciutta": "isolante", "Stoffa asciutta": "isolante",
				"Guanto di gomma": "isolante", "Manico di plastica": "isolante",
				"Elastico": "isolante", "Cartone asciutto": "isolante",
				"Gomma da cancellare": "isolante"}},
		{"explanation": "Segui l'energia: una sorgente la mette nel circuito; un utilizzatore la trasforma in luce, suono o movimento. La pila è una sorgente, mentre LED, lampadina e motorino sono utilizzatori.", "topic": "energia-nei-componenti", "draw": 6, "prompt": "Smista i componenti: chi dà energia al circuito e chi la trasforma?",
			"categories": ["fornisce energia", "usa energia"],
			"assignments": {
				"Pila": "fornisce energia", "Batteria": "fornisce energia", "Cella solare": "fornisce energia",
				"Powerbank": "fornisce energia", "Pila a bottone": "fornisce energia",
				"Dinamo della bicicletta": "fornisce energia", "Pannellino solare da giardino": "fornisce energia",
				"Batteria del telecomando": "fornisce energia",
				"LED": "usa energia", "Motorino": "usa energia", "Lampadina": "usa energia",
				"Cicalino": "usa energia", "Ventola": "usa energia",
				"Torcia elettrica": "usa energia", "Campanello": "usa energia",
				"Sveglia a pile": "usa energia"}},
		{"explanation": "Prima regola: nei circuiti didattici si usano pile a bassa tensione; prese e cavi di casa non sono materiale da esperimento. Seconda: si monta a pila scollegata. Terza: se qualcosa scalda, odora o ha un filo scoperto, si stacca e si chiama un adulto.", "topic": "sicurezza-elettrica", "draw": 6, "prompt": "Porta ogni situazione nel contenitore giusto: posso continuare o devo fermarmi?",
			"categories": ["posso continuare", "stop e chiamo un adulto"],
			"assignments": {
				"Monto un circuito con la pila scollegata": "posso continuare",
				"Uso una pila da laboratorio e fili integri": "posso continuare",
				"Controllo due volte prima di collegare la pila": "posso continuare",
				"Il circuito è spento e il banco è asciutto": "posso continuare",
				"Ho asciugato le mani prima di cominciare": "posso continuare",
				"Il kit funziona con una pila da 4,5 volt": "posso continuare",
				"Ho tolto la pila prima di cambiare un collegamento": "posso continuare",
				"Chiedo a un adulto di guardare il circuito prima di accenderlo": "posso continuare",
				"Voglio aprire una presa di casa": "stop e chiamo un adulto",
				"Un filo ha il rame scoperto": "stop e chiamo un adulto",
				"Sento odore di bruciato": "stop e chiamo un adulto",
				"La pila o un componente diventano caldi": "stop e chiamo un adulto",
				"Ho le mani bagnate": "stop e chiamo un adulto",
				"Vorrei usare la corrente della presa per provare": "stop e chiamo un adulto",
				"Il caricabatterie del telefono ha il filo rotto": "stop e chiamo un adulto",
				"Un apparecchio acceso è caduto nell'acqua": "stop e chiamo un adulto"}},
		# Ruolo nel circuito: sorgente, conduttore, isolante o carico.
		{"explanation": "In uno schema avanzato gli elementi si distinguono per ruolo: sorgente, conduttore, isolante o carico. Prima si riconosce che cosa entra e che cosa esce in termini di energia.", "topic": "ruoli", "minLevel": 10, "draw": 8, "prompt": "Smista ogni elemento per il suo ruolo nel circuito.",
			"categories": ["sorgente", "conduttore", "isolante", "carico"],
			"assignments": {
				"Pila": "sorgente", "Batteria": "sorgente", "Cella solare": "sorgente",
				"Dinamo": "sorgente", "Powerbank": "sorgente", "Generatore": "sorgente",
				"Rame": "conduttore", "Filo elettrico": "conduttore", "Piste del circuito stampato": "conduttore",
				"Morsetto metallico": "conduttore", "Alluminio": "conduttore", "Stagno di saldatura": "conduttore",
				"Plastica": "isolante", "Gomma": "isolante", "Guaina del cavo": "isolante",
				"Basetta di vetronite": "isolante", "Ceramica": "isolante", "Nastro isolante": "isolante",
				"LED": "carico", "Lampadina": "carico", "Motorino": "carico",
				"Cicalino": "carico", "Ventola": "carico", "Resistore di potenza": "carico"}},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "In serie la corrente ha una strada sola, quindi se si interrompe si spegne tutto. In parallelo ogni ramo ha la sua strada. Questa distinzione arriva dopo aver imparato a seguire un circuito semplice.", "topic": "serie-parallelo", "minLevel": 13, "draw": 6, "prompt": "Smista ogni descrizione: serie o parallelo?",
			"categories": ["serie", "parallelo"],
			"assignments": {
				"se una lampadina si brucia si spengono tutte": "serie",
				"la corrente ha una strada sola": "serie",
				"più lampadine ci sono, più sono deboli": "serie",
				"le vecchie luci dell'albero di Natale": "serie",
				"le resistenze si sommano": "serie",
				"basta un filo staccato e non funziona niente": "serie",
				"ogni lampadina ha il suo percorso": "parallelo",
				"se una si brucia le altre restano accese": "parallelo",
				"le prese di casa": "parallelo",
				"ognuna riceve la stessa tensione": "parallelo",
				"si può spegnere una luce sola": "parallelo",
				"la corrente si divide fra i rami": "parallelo"}},
		{"explanation": "La corrente può attraversare il corpo se questo completa un percorso fra due punti a tensione diversa. Per un bambino la regola non è «riparare con cautela»: è usare solo kit a pile, tenere tutto asciutto e chiamare un adulto davanti a prese, fili rotti, calore o odore di bruciato.", "topic": "sicurezza-elettrica", "draw": 6, "prompt": "Smista ogni comportamento: prudente o pericoloso?",
			"categories": ["prudente", "pericoloso"],
			"assignments": {
				"usare soltanto un kit didattico alimentato a pile": "prudente",
				"montare il circuito con la pila scollegata": "prudente",
				"tenere asciutti mani e banco di lavoro": "prudente",
				"mostrare un filo scoperto a un adulto senza toccarlo": "prudente",
				"fermarsi se una pila diventa calda": "prudente",
				"controllare i collegamenti prima di inserire la pila": "prudente",
				"toccare una presa con le mani bagnate": "pericoloso",
				"infilare oggetti di metallo in una presa": "pericoloso",
				"usare un filo con la guaina rotta": "pericoloso",
				"collegare i due poli della pila con un filo nudo": "pericoloso",
				"attaccare troppe spine alla stessa presa": "pericoloso",
				"aprire da soli un apparecchio elettrico": "pericoloso"}},
	],
	"inglese": [
		{"explanation": "Ogni parola va nel campo di significato a cui appartiene: è il modo in cui il cervello archivia il lessico, per gruppi e non alla rinfusa.", "topic": "categorie", "draw": 8, "prompt": "Sort each word into its category.",
			"categories": ["animals", "food", "colours", "actions"],
			"assignments": {
				"dog": "animals", "cat": "animals", "horse": "animals", "bird": "animals",
				"fish": "animals", "sheep": "animals", "mouse": "animals", "bear": "animals",
				"apple": "food", "bread": "food", "cheese": "food", "rice": "food",
				"milk": "food", "soup": "food", "cake": "food", "honey": "food",
				"red": "colours", "blue": "colours", "green": "colours", "yellow": "colours",
				"black": "colours", "white": "colours", "purple": "colours", "grey": "colours",
				"run": "actions", "jump": "actions", "swim": "actions", "write": "actions",
				"sing": "actions", "read": "actions", "climb": "actions", "listen": "actions"}},
		{"explanation": "Le parole si raggruppano per ambito di vita: la famiglia, la scuola, la natura. Impararle in gruppo le rende più facili da richiamare.", "topic": "home-family", "draw": 6, "prompt": "Sort each word: family, school or nature.",
			"categories": ["family", "school", "nature"],
			"assignments": {
				"mother": "family", "father": "family", "sister": "family", "brother": "family",
				"grandmother": "family", "uncle": "family", "cousin": "family", "aunt": "family",
				"teacher": "school", "book": "school", "pencil": "school", "desk": "school",
				"classroom": "school", "homework": "school", "blackboard": "school", "schoolbag": "school",
				"tree": "nature", "river": "nature", "mountain": "nature", "forest": "nature",
				"cloud": "nature", "flower": "nature", "beach": "nature", "valley": "nature"}},
		# Articolo a/an secondo il suono iniziale: regola tipica dell'inglese.
		# Attenzione: la regola è sul SUONO, non sulla lettera — «a university»,
		# «an hour». Le voci trabocchetto sono deliberate: è lì che si impara.
		{"explanation": "Si usa «an» davanti a suono vocalico e «a» davanti a suono consonantico: conta come si pronuncia la parola, non come si scrive.", "topic": "articles", "minLevel": 4, "draw": 6, "prompt": "Sort each word: does it take 'a' or 'an'?",
			"categories": ["a", "an"],
			"assignments": {
				"apple": "an", "orange": "an", "umbrella": "an", "elephant": "an",
				"island": "an", "hour": "an", "onion": "an", "artist": "an",
				"idea": "an", "egg": "an", "engine": "an", "honest man": "an",
				"dog": "a", "car": "a", "book": "a", "university": "a",
				"table": "a", "house": "a", "European city": "a", "friend": "a",
				"uniform": "a", "window": "a", "garden": "a", "yellow bird": "a"}},
		{"explanation": "La parte del discorso dipende dal lavoro che la parola fa: nomina qualcosa, dice un'azione o la descrive.", "topic": "parts-of-speech", "minLevel": 4, "draw": 6, "prompt": "Sort each word into its part of speech.",
			"categories": ["noun", "verb", "adjective"],
			"assignments": {
				"dog": "noun", "house": "noun", "river": "noun", "teacher": "noun",
				"bottle": "noun", "friendship": "noun", "mountain": "noun", "window": "noun",
				"run": "verb", "eat": "verb", "build": "verb", "listen": "verb",
				"forget": "verb", "choose": "verb", "arrive": "verb", "explain": "verb",
				"big": "adjective", "red": "adjective", "quiet": "adjective", "heavy": "adjective",
				"ancient": "adjective", "friendly": "adjective", "narrow": "adjective", "brave": "adjective"}},
		# Scuola media — verbi regolari/irregolari e nomi numerabili/non numerabili.
		{"explanation": "I verbi regolari fanno il passato in -ed; gli irregolari cambiano forma e vanno imparati uno per uno.", "topic": "verbs", "minLevel": 7, "draw": 6, "prompt": "Sort each past-tense verb: regular or irregular?",
			"categories": ["regular", "irregular"],
			"assignments": {
				"played": "regular", "walked": "regular", "watched": "regular", "opened": "regular",
				"listened": "regular", "arrived": "regular", "studied": "regular", "helped": "regular",
				"cleaned": "regular", "carried": "regular", "wanted": "regular", "stopped": "regular",
				"went": "irregular", "ate": "irregular", "saw": "irregular", "took": "irregular",
				"wrote": "irregular", "drank": "irregular", "began": "irregular", "brought": "irregular",
				"caught": "irregular", "chose": "irregular", "slept": "irregular", "spoke": "irregular"}},
		{"explanation": "I nomi numerabili si possono contare uno, due, tre; quelli non numerabili si misurano ma non si contano — acqua, riso, denaro.", "topic": "nouns", "minLevel": 7, "draw": 6, "prompt": "Sort each noun: countable or uncountable?",
			"categories": ["countable", "uncountable"],
			"assignments": {
				"apple": "countable", "book": "countable", "car": "countable", "chair": "countable",
				"idea": "countable", "song": "countable", "bottle": "countable", "child": "countable",
				"city": "countable", "coin": "countable", "letter": "countable", "tree": "countable",
				"water": "uncountable", "milk": "uncountable", "rice": "uncountable", "bread": "uncountable",
				"money": "uncountable", "music": "uncountable", "advice": "uncountable", "information": "uncountable",
				"sugar": "uncountable", "homework": "uncountable", "furniture": "uncountable", "weather": "uncountable"}},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "Si sceglie «an» davanti a un SUONO di vocale, non a una lettera vocale: «hour» comincia per h muta e vuole «an», «university» si legge «iu» e vuole «a».", "topic": "everyday-phrases", "draw": 6, "prompt": "Sort each word: does it take «a» or «an»?",
			"categories": ["a", "an"],
			"assignments": {
				"book": "a", "car": "a", "dog": "a", "university": "a",
				"European city": "a", "house": "a", "table": "a", "uniform": "a",
				"apple": "an", "orange": "an", "elephant": "an", "hour": "an",
				"honest boy": "an", "umbrella": "an", "island": "an", "egg": "an"}},
		{"explanation": "I giorni finiscono in -day, i mesi cominciano con la maiuscola come i giorni, le stagioni no: sono le uniche tre parole di questo gruppo che si scrivono minuscole.", "topic": "time-weather", "draw": 6, "prompt": "Sort each word: day, month or season.",
			"categories": ["day", "month", "season"],
			"assignments": {
				"Monday": "day", "Wednesday": "day", "Friday": "day", "Sunday": "day", "Thursday": "day",
				"January": "month", "April": "month", "July": "month", "October": "month", "December": "month",
				"spring": "season", "summer": "season", "autumn": "season", "winter": "season"}},
		# --- Il biennio: i mondi 15-22 (8 settembre 2026) ---------------------
		{"explanation": "Dopo certi verbi va la forma in «-ing», dopo altri l'infinito con «to». Non c'è una regola che lo spieghi: si imparano in due liste, e smistarli è il modo di costruirsele.", "topic": "gerund-infinitive", "minLevel": 13, "draw": 6, "prompt": "Sort each verb: does it take «-ing» or «to»?",
			"categories": ["+ -ing", "+ to"],
			"assignments": {
				"enjoy": "+ -ing", "avoid": "+ -ing", "finish": "+ -ing", "mind": "+ -ing",
				"suggest": "+ -ing", "practise": "+ -ing", "imagine": "+ -ing", "risk": "+ -ing",
				"decide": "+ to", "want": "+ to", "hope": "+ to", "promise": "+ to",
				"refuse": "+ to", "agree": "+ to", "learn": "+ to", "offer": "+ to"}},
		{"explanation": "La spia del passivo sono due cose insieme: il verbo essere e il participio. Se ne manca uno, la frase è attiva anche quando racconta una disgrazia.", "topic": "passive", "minLevel": 16, "draw": 6, "prompt": "Sort each sentence: active or passive?",
			"categories": ["active", "passive"],
			"assignments": {
				"The window was broken": "passive", "English is spoken here": "passive",
				"The bridge was built in 1890": "passive", "My phone was stolen": "passive",
				"The work has been done": "passive", "The car will be repaired": "passive",
				"It is said that he is rich": "passive", "She was given a present": "passive",
				"The window broke": "active", "She broke the window": "active",
				"They speak English": "active", "He has done the work": "active",
				"The car needs cleaning": "active", "Someone stole my phone": "active",
				"They built the bridge": "active", "He gave her a present": "active"}},
		{"explanation": "«For» misura quanto è durata una cosa, «since» dichiara da quando è cominciata. È la stessa domanda posta in due modi, e la risposta sta nel tipo di parola che segue.", "topic": "present-perfect", "minLevel": 19, "draw": 6, "prompt": "Sort each expression: does it take «for» or «since»?",
			"categories": ["for", "since"],
			"assignments": {
				"three years": "for", "a week": "for", "two hours": "for",
				"a long time": "for", "ages": "for", "ten minutes": "for",
				"six months": "for", "a few days": "for",
				"2020": "since", "Monday": "since", "last summer": "since",
				"I was a child": "since", "September": "since", "yesterday": "since",
				"we met": "since", "this morning": "since"}},
		{"explanation": "I tre tipi di periodo ipotetico si distinguono dai tempi, non dal senso: più la condizione è improbabile, più il verbo arretra. Contare i gradini basta a riconoscerli.", "topic": "conditionals", "minLevel": 22, "draw": 6, "prompt": "Sort each sentence: first, second or third conditional?",
			"categories": ["first", "second", "third"],
			"assignments": {
				"If it rains, we will stay in": "first", "If she comes, I will tell her": "first",
				"If you study, you will pass": "first", "If I have time, I will call you": "first",
				"If he asks, I will help him": "first",
				"If I were rich, I would travel": "second", "If I had time, I would learn Greek": "second",
				"If I were you, I would call him": "second", "If she came, I would tell her": "second",
				"If he asked, I would help him": "second",
				"If you had studied, you would have passed": "third",
				"If I had known, I would have come": "third",
				"If she had come, I would have told her": "third",
				"If he had asked, I would have helped him": "third",
				"If it had rained, we would have stayed in": "third"}},
		# --- La grammatica delle prime fasce (9 settembre 2026) ---------------
		#
		# Lo smistamento e' il formato piu' adatto alla grammatica inglese, perche'
		# quasi ogni regola qui e' una scelta fra due o tre caselle: am/is/are,
		# have/has, much/many, will/going to. Sbagliare casella si vede subito, e
		# la casella giusta si ritrova ragionando invece che ricordando.
		{"explanation": "Il verbo essere ha tre forme al presente e basta: una per «I», una per chi e' uno solo, una per tutto il resto. Chi smista qui non impara tre parole, impara che l'inglese accorda soltanto in questo punto del presente.", "topic": "to-be", "minLevel": 1, "draw": 8, "prompt": "Sort each subject: am, is or are?",
			"categories": ["am", "is", "are"],
			"assignments": {
				"I": "am",
				"he": "is", "she": "is", "it": "is", "my sister": "is", "the dog": "is",
				"Anna": "is", "my teacher": "is", "this book": "is", "the sun": "is",
				"you": "are", "we": "are", "they": "are", "my parents": "are",
				"the boys": "are", "Anna and Tom": "are", "those cats": "are", "you and I": "are"}},
		{"explanation": "Il plurale inglese e' quasi sempre una -s, ma la parola che la riceve decide come: se finisce con un suono sibilante ci vuole una vocale d'appoggio, se finisce in -y dopo consonante la y diventa i. Non sono tre regole, e' una regola e due aggiustamenti di pronuncia.", "topic": "plurals", "minLevel": 1, "draw": 8, "prompt": "Sort each word: how does it make the plural?",
			"categories": ["+ -s", "+ -es", "-y diventa -ies"],
			"assignments": {
				"book": "+ -s", "cat": "+ -s", "tree": "+ -s", "house": "+ -s",
				"car": "+ -s", "friend": "+ -s", "desk": "+ -s", "river": "+ -s",
				"box": "+ -es", "bus": "+ -es", "watch": "+ -es", "dish": "+ -es",
				"glass": "+ -es", "church": "+ -es", "brush": "+ -es", "tomato": "+ -es",
				"city": "-y diventa -ies", "baby": "-y diventa -ies", "country": "-y diventa -ies",
				"story": "-y diventa -ies", "lady": "-y diventa -ies", "party": "-y diventa -ies",
				"family": "-y diventa -ies", "dictionary": "-y diventa -ies"}},
		{"explanation": "Il possesso si dice con due parole e solo la prima cambia: «got» resta ferma per tutti. La forma corta vale per lui, lei, esso — la stessa persona che nel presente semplice prende la -s.", "topic": "have-got", "minLevel": 4, "draw": 6, "prompt": "Sort each subject: have got or has got?",
			"categories": ["have got", "has got"],
			"assignments": {
				"I": "have got", "you": "have got", "we": "have got", "they": "have got",
				"my parents": "have got", "the children": "have got", "Anna and Tom": "have got",
				"my friends": "have got",
				"he": "has got", "she": "has got", "it": "has got", "my brother": "has got",
				"the cat": "has got", "Anna": "has got", "the school": "has got", "my teacher": "has got"}},
		{"explanation": "«There is» e «there are» si scelgono guardando quello che viene DOPO, non quello che viene prima: e' la cosa nominata a decidere. E le cose che non si contano restano al singolare per quanta ce ne sia.", "topic": "there-is", "minLevel": 4, "draw": 6, "prompt": "Sort each ending: does it take «there is» or «there are»?",
			"categories": ["there is", "there are"],
			"assignments": {
				"a book on the desk": "there is", "one apple in the bag": "there is",
				"some milk in the fridge": "there is", "a car in the street": "there is",
				"some bread on the table": "there is", "water in the bottle": "there is",
				"a girl at the door": "there is", "some snow on the road": "there is",
				"two books on the desk": "there are", "some apples in the bag": "there are",
				"many cars in the street": "there are", "three chairs in the room": "there are",
				"the children in the garden": "there are", "five euros in my pocket": "there are",
				"some people outside": "there are", "four windows in the classroom": "there are"}},
		{"explanation": "«Much» e «many» non si scelgono a orecchio: dipendono da come si conta la cosa nominata. Quello che si misura — acqua, tempo, denaro — non ha plurale e prende «much»; quello che si conta a uno a uno prende «many».", "topic": "quantifiers", "minLevel": 7, "draw": 6, "prompt": "Sort each word: much or many?",
			"categories": ["much", "many"],
			"assignments": {
				"water": "much", "milk": "much", "money": "much", "time": "much",
				"bread": "much", "sugar": "much", "rain": "much", "information": "much",
				"music": "much", "homework": "much",
				"books": "many", "apples": "many", "friends": "many", "cars": "many",
				"chairs": "many", "people": "many", "questions": "many", "euros": "many",
				"days": "many", "photos": "many"}},
		{"explanation": "Le due forme del presente rispondono a due domande diverse: «di solito» e «proprio adesso». La spia non e' il verbo, e' l'espressione di tempo che lo accompagna — per questo si riconoscono senza leggere il resto della frase.", "topic": "present-continuous", "minLevel": 7, "draw": 6, "prompt": "Sort each expression: present simple (usually) or present continuous (now)?",
			"categories": ["present simple", "present continuous"],
			"assignments": {
				"every day": "present simple", "usually": "present simple", "on Mondays": "present simple",
				"never": "present simple", "twice a week": "present simple", "always": "present simple",
				"in the morning": "present simple", "sometimes": "present simple",
				"right now": "present continuous", "at the moment": "present continuous",
				"Look!": "present continuous", "Listen!": "present continuous",
				"today at five": "present continuous", "this week": "present continuous",
				"at present": "present continuous", "still": "present continuous"}},
		{"explanation": "Le tre preposizioni di tempo vanno dal grande al piccolo: «in» per i contenitori lunghi (mesi, anni, stagioni), «on» per il giorno preciso, «at» per l'ora e per i due modi di dire che fanno eccezione, at night e at the weekend.", "topic": "prepositions", "minLevel": 7, "draw": 6, "prompt": "Sort each time expression: in, on or at?",
			"categories": ["in", "on", "at"],
			"assignments": {
				"July": "in", "2020": "in", "the morning": "in", "summer": "in",
				"the evening": "in", "December": "in",
				"Monday": "on", "15th May": "on", "Christmas Day": "on", "my birthday": "on",
				"Friday evening": "on", "Saturday afternoon": "on",
				"seven o'clock": "at", "night": "at", "the weekend": "at", "lunchtime": "at",
				"midnight": "at", "half past three": "at"}},
		{"explanation": "«Will» e «going to» parlano dello stesso futuro da due momenti diversi: «going to» quando la decisione era gia' presa o la prova e' sotto gli occhi, «will» quando si decide mentre si parla. La differenza non e' nel tempo, e' in chi ha deciso e quando.", "topic": "future", "minLevel": 13, "draw": 6, "prompt": "Sort each situation: will or going to?",
			"categories": ["will", "going to"],
			"assignments": {
				"The phone is ringing: I answer it": "will",
				"The bag is heavy: I help you": "will",
				"I think our team wins the cup": "will",
				"Maybe it rains tomorrow": "will",
				"I promise: I call you tonight": "will",
				"I offer: I make the tea": "will",
				"We have booked: we visit Rome in July": "going to",
				"Look at those clouds: it rains soon": "going to",
				"She has bought the paint: she paints her room": "going to",
				"He has decided: he studies Chinese": "going to",
				"The tank is empty: the car stops": "going to",
				"They have the tickets: they leave on Monday": "going to"}},
		{"explanation": "Nel racconto al passato i due tempi hanno due mestieri: uno stende lo sfondo che durava, l'altro segna il fatto successo dentro quello sfondo. «While» apre sempre lo sfondo, «when» quasi sempre il fatto.", "topic": "past-continuous", "minLevel": 13, "draw": 6, "prompt": "Sort each half sentence: past simple or past continuous?",
			"categories": ["past simple", "past continuous"],
			"assignments": {
				"the phone rang": "past simple", "I opened the door": "past simple",
				"she arrived at eight": "past simple", "we saw the ship": "past simple",
				"he broke the glass": "past simple", "they left in silence": "past simple",
				"while it was raining": "past continuous", "she was reading a book": "past continuous",
				"they were waiting outside": "past continuous", "I was having dinner": "past continuous",
				"the sun was going down": "past continuous", "we were walking home": "past continuous"}},
		{"explanation": "Gli stessi modali che chiedono permesso servono a fare ipotesi: «must» diventa la quasi certezza, «cannot» la certezza contraria, «might» il forse. E' lo stesso verbo che cambia mestiere, ed e' il gradino in cui il modale smette di parlare di regole e comincia a dire quanto ci si crede.", "topic": "modals", "minLevel": 16, "draw": 6, "prompt": "Sort each deduction: must, cannot or might?",
			"categories": ["must (quasi certo)", "cannot (certo di no)", "might (forse)"],
			"assignments": {
				"The light is on, so he ___ be at home": "must (quasi certo)",
				"She has studied all year, so she ___ know the answer": "must (quasi certo)",
				"They are laughing, so they ___ be happy": "must (quasi certo)",
				"The plate is empty, so the cat ___ be full": "must (quasi certo)",
				"He is in Rome today, so he ___ be here": "cannot (certo di no)",
				"That is not her car, so it ___ be hers": "cannot (certo di no)",
				"She never eats meat, so that ___ be her plate": "cannot (certo di no)",
				"The shop closed at six, so it ___ be open": "cannot (certo di no)",
				"The sky is grey, so it ___ rain later": "might (forse)",
				"He has not answered, so he ___ be busy": "might (forse)",
				"I do not know the time, so she ___ arrive soon": "might (forse)",
				"There are clouds, so we ___ stay at home": "might (forse)"}},
		{"explanation": "Il trapassato serve solo quando due fatti passati vanno messi in ordine fra loro: il piu' antico arretra con «had», l'altro resta al passato semplice. Se il racconto e' gia' in ordine il trapassato non serve, ed e' l'errore piu' comune — usarlo dove non c'e' niente da riordinare.", "topic": "past-perfect", "minLevel": 22, "draw": 6, "prompt": "Sort each action: which happened FIRST (past perfect) and which after (past simple)?",
			"categories": ["past perfect (prima)", "past simple (dopo)"],
			"assignments": {
				"the train had left": "past perfect (prima)",
				"the film had already started": "past perfect (prima)",
				"she had finished her homework": "past perfect (prima)",
				"they had eaten everything": "past perfect (prima)",
				"I had never seen the sea": "past perfect (prima)",
				"he had lost the keys": "past perfect (prima)",
				"we arrived at the station": "past simple (dopo)",
				"we entered the cinema": "past simple (dopo)",
				"she went out to play": "past simple (dopo)",
				"we sat down at the table": "past simple (dopo)",
				"I went to Sicily last year": "past simple (dopo)",
				"he rang the bell": "past simple (dopo)"}},
		{"explanation": "Le parole di uso quotidiano si ricordano meglio a gruppi, perche' la memoria le archivia per luogo: le stesse cose che si vedono insieme si richiamano insieme. E' il motivo per cui un vocabolario per argomenti rende piu' di uno in ordine alfabetico.", "topic": "objects", "minLevel": 1, "draw": 6, "prompt": "Sort each object: classroom, kitchen or bathroom?",
			"categories": ["classroom", "kitchen", "bathroom"],
			"assignments": {
				"desk": "classroom", "blackboard": "classroom", "pencil case": "classroom",
				"rubber": "classroom", "ruler": "classroom", "schoolbag": "classroom",
				"fridge": "kitchen", "spoon": "kitchen", "plate": "kitchen",
				"cooker": "kitchen", "kettle": "kitchen", "cup": "kitchen",
				"towel": "bathroom", "soap": "bathroom", "mirror": "bathroom",
				"toothbrush": "bathroom", "shower": "bathroom", "comb": "bathroom"}},
		{"explanation": "Un viaggio si racconta con le parole del posto in cui si e': al banco della stazione servono i binari, all'aeroporto le carte d'imbarco, in albergo le chiavi. Sapere dove si e' aiuta a indovinare la parola che manca, ed e' la strategia che regge una conversazione vera.", "topic": "travel-places", "minLevel": 13, "draw": 6, "prompt": "Sort each word: station, airport or hotel?",
			"categories": ["station", "airport", "hotel"],
			"assignments": {
				"platform": "station", "ticket office": "station", "timetable": "station",
				"return ticket": "station", "waiting room": "station", "left luggage": "station",
				"boarding pass": "airport", "gate": "airport", "check-in desk": "airport",
				"hand luggage": "airport", "departure lounge": "airport", "runway": "airport",
				"reception": "hotel", "single room": "hotel", "room key": "hotel",
				"lift": "hotel", "half board": "hotel", "guest": "hotel"}},
		{"explanation": "I connettivi non aggiungono contenuto: dichiarano che rapporto c'e' fra due frasi. Sbagliare connettivo non e' un errore di parole, e' dire un rapporto che non c'e' — e chi ascolta segue il connettivo, non l'intenzione.", "topic": "connectors", "minLevel": 16, "draw": 6, "prompt": "Sort each linking word: does it add, oppose or explain?",
			"categories": ["aggiunge", "oppone", "spiega la causa"],
			"assignments": {
				"and": "aggiunge", "also": "aggiunge", "besides": "aggiunge",
				"moreover": "aggiunge", "as well as": "aggiunge", "in addition": "aggiunge",
				"but": "oppone", "however": "oppone", "although": "oppone",
				"whereas": "oppone", "on the other hand": "oppone", "even if": "oppone",
				"because": "spiega la causa", "so": "spiega la causa", "since": "spiega la causa",
				"therefore": "spiega la causa", "that is why": "spiega la causa", "as": "spiega la causa"}},
		{"explanation": "Il comparativo si sceglie contando le sillabe, non a orecchio: le parole corte prendono -er, quelle lunghe si fanno precedere da «more». Le poche irregolari sono le piu' usate di tutte — good, bad, far — e proprio per questo non si sono mai regolarizzate.", "topic": "comparatives", "minLevel": 16, "draw": 6, "prompt": "Sort each adjective: how does it make the comparative?",
			"categories": ["+ -er", "more + aggettivo", "irregolare"],
			"assignments": {
				"tall": "+ -er", "fast": "+ -er", "old": "+ -er", "young": "+ -er",
				"big": "+ -er", "small": "+ -er", "high": "+ -er", "cold": "+ -er",
				"beautiful": "more + aggettivo", "expensive": "more + aggettivo",
				"difficult": "more + aggettivo", "important": "more + aggettivo",
				"interesting": "more + aggettivo", "dangerous": "more + aggettivo",
				"comfortable": "more + aggettivo", "popular": "more + aggettivo",
				"good": "irregolare", "bad": "irregolare", "far": "irregolare",
				"little": "irregolare"}},
	],
	"latino": [
		# **Le fasce alte del latino, scritte il 9 settembre 2026.** Il censimento
		# trovava latino con 31 ricette in tutto e ZERO nuove dalla fascia 5 in
		# poi: dal mondo 13 al 24 non sblocca piu' niente. Queste smistano forme
		# gia' visibili sulla tessera, quindi non violano il vincolo delle tavole:
		# non chiedono di PRODURRE una forma, chiedono di riconoscerne la funzione.
		{"topic": "casi", "minLevel": 7, "draw": 6, "prompt": "Smista ogni forma secondo la domanda a cui risponde.",
			"categories": ["chi compie", "chi subisce", "di chi e'"],
			"assignments": {
				"puella": "chi compie", "rosa": "chi compie", "dominus": "chi compie",
				"lupus": "chi compie", "terra": "chi compie", "servus": "chi compie",
				"puellam": "chi subisce", "rosam": "chi subisce", "dominum": "chi subisce",
				"lupum": "chi subisce", "terram": "chi subisce", "servum": "chi subisce",
				"puellae": "di chi e'", "rosae": "di chi e'", "domini": "di chi e'",
				"lupi": "di chi e'", "terrae": "di chi e'", "servi": "di chi e'"},
			"explanation": "La stessa parola cambia finale secondo il mestiere che svolge nella frase: -a chi compie, -am chi subisce, -ae o -i di chi e'. Imparata la scala su una parola, vale per tutte quelle del suo gruppo."},
		{"topic": "verbi", "minLevel": 13, "draw": 6, "prompt": "Smista ogni voce verbale secondo quando accade l'azione.",
			"categories": ["adesso", "prima", "dopo"],
			"assignments": {
				"amat": "adesso", "videt": "adesso", "audit": "adesso",
				"laborat": "adesso", "portat": "adesso", "docet": "adesso",
				"amavit": "prima", "vidit": "prima", "audivit": "prima",
				"laboravit": "prima", "portavit": "prima", "docuit": "prima",
				"amabit": "dopo", "videbit": "dopo", "audiet": "dopo",
				"laborabit": "dopo", "portabit": "dopo", "docebit": "dopo"},
			"explanation": "Il tempo sta dentro il verbo, in un pezzo che si infila fra la radice e la persona: -bi- porta avanti, -v- o -u- portano indietro. Riconosciuto quel pezzo, il tempo si legge senza tradurre la frase intera."},
		{"topic": "verbi", "minLevel": 16, "draw": 6, "prompt": "Smista ogni voce verbale secondo chi compie l'azione.",
			"categories": ["una persona sola", "piu' persone"],
			"assignments": {
				"amat": "una persona sola", "videt": "una persona sola", "portat": "una persona sola",
				"audit": "una persona sola", "docet": "una persona sola", "laborat": "una persona sola",
				"amant": "piu' persone", "vident": "piu' persone", "portant": "piu' persone",
				"audiunt": "piu' persone", "docent": "piu' persone", "laborant": "piu' persone"},
			"explanation": "La -t finale dice «uno», la -nt dice «piu' di uno»: una lettera sola separa «ama» da «amano». E' il motivo per cui in latino il pronome non serve — la persona e' gia' scritta nel verbo."},
		{"topic": "casi", "minLevel": 22, "draw": 6, "prompt": "Smista ogni espressione secondo il complemento che esprime.",
			"categories": ["luogo", "mezzo", "compagnia"],
			"assignments": {
				"in villa": "luogo", "in silva": "luogo", "in horto": "luogo",
				"in oppido": "luogo", "in templo": "luogo", "in agro": "luogo",
				"gladio": "mezzo", "sagitta": "mezzo", "stilo": "mezzo",
				"navibus": "mezzo", "curru": "mezzo", "manu": "mezzo",
				"cum amico": "compagnia", "cum servo": "compagnia", "cum matre": "compagnia",
				"cum sociis": "compagnia", "cum patre": "compagnia", "cum filia": "compagnia"},
			"explanation": "Il complemento si riconosce dalla coppia preposizione piu' caso, non dalla preposizione da sola: «cum» chiede sempre compagnia, il mezzo va senza preposizione e «in» con questo caso indica dove si sta."},
		{"topic": "declinazioni-base", "minLevel": 19, "draw": 6, "prompt": "Smista ogni parola secondo il gruppo a cui appartiene.",
			"categories": ["prima", "seconda", "terza"],
			"assignments": {
				"rosa": "prima", "puella": "prima", "terra": "prima",
				"aqua": "prima", "silva": "prima", "villa": "prima",
				"dominus": "seconda", "servus": "seconda", "lupus": "seconda",
				"hortus": "seconda", "murus": "seconda", "amicus": "seconda",
				"consul": "terza", "rex": "terza", "miles": "terza",
				"pater": "terza", "mater": "terza", "civis": "terza"},
			"explanation": "Il gruppo si legge dalla finale del nominativo: -a la prima, -us la seconda, e la terza raccoglie tutto il resto — ed e' per questo che e' la piu' numerosa e la piu' irregolare."},
		{"topic": "declinazioni-base", "draw": 6, "prompt": "Smista ogni parola latina: singolare o plurale?",
			"categories": ["singolare", "plurale"],
			"assignments": {
				"rosam": "singolare", "puellam": "singolare", "aquam": "singolare",
				"terram": "singolare", "dominum": "singolare", "lupum": "singolare",
				"rosas": "plurale", "puellas": "plurale", "aquas": "plurale",
				"terras": "plurale", "dominos": "plurale", "lupos": "plurale"},
			"explanation": "Le forme in -am e -um sono singolari, quelle in -as e -os plurali: in latino il numero si legge dalla desinenza, non dall'articolo — che non esiste."},
		# In latino l'ordine è convenzione pura — i casi si recitano in quell'ordine
		# perché così li recita il libro, non perché uno sia «maggiore» di un altro.
		# Quindi l'ordinamento qui resta a dato fisso, e tutta la profondità deve
		# venire da smistamento e abbinamento. È il caso opposto a storia e fisica.
		{"explanation": "Le parole si raggruppano per campo di significato, come in italiano: è così che si costruisce un vocabolario che resta.", "topic": "vocabolario", "draw": 6, "prompt": "Smista ogni parola latina per campo di significato.",
			"categories": ["natura", "persone", "animali"],
			"assignments": {
				"aqua": "natura", "silva": "natura", "terra": "natura", "stella": "natura",
				"luna": "natura", "mare": "natura", "flumen": "natura", "arbor": "natura",
				"ventus": "natura", "sol": "natura", "campus": "natura", "mons": "natura",
				"puella": "persone", "poeta": "persone", "agricola": "persone", "nauta": "persone",
				"miles": "persone", "rex": "persone", "magister": "persone", "puer": "persone",
				"lupus": "animali", "equus": "animali", "canis": "animali", "avis": "animali",
				"taurus": "animali", "piscis": "animali", "ursus": "animali", "aquila": "animali"}},
		{"explanation": "Il genere in latino si riconosce dalla desinenza e va imparato con la parola: «poeta» finisce in -a ed è maschile.", "topic": "casi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni parola latina nel suo genere.",
			"categories": ["maschile", "femminile", "neutro"],
			"assignments": {
				"lupus": "maschile", "poeta": "maschile", "servus": "maschile", "dominus": "maschile",
				"agricola": "maschile", "nauta": "maschile", "hortus": "maschile", "amicus": "maschile",
				"puella": "femminile", "rosa": "femminile", "silva": "femminile", "aqua": "femminile",
				"terra": "femminile", "stella": "femminile", "regina": "femminile", "porta": "femminile",
				"templum": "neutro", "bellum": "neutro", "donum": "neutro", "verbum": "neutro",
				"oppidum": "neutro", "vinum": "neutro", "signum": "neutro", "regnum": "neutro"}},
		# Scuola media — riconoscere la declinazione di appartenenza.
		{"explanation": "La declinazione si riconosce dal genitivo singolare, non dal nominativo: è l'unica desinenza che non si ripete fra declinazioni diverse.", "topic": "declinazioni-base", "minLevel": 6, "draw": 6, "prompt": "Smista ogni parola nella sua declinazione.",
			"categories": ["1ª declinazione", "2ª declinazione", "3ª declinazione"],
			"assignments": {
				"rosa": "1ª declinazione", "puella": "1ª declinazione", "silva": "1ª declinazione", "aqua": "1ª declinazione",
				"terra": "1ª declinazione", "stella": "1ª declinazione", "regina": "1ª declinazione", "porta": "1ª declinazione",
				"lupus": "2ª declinazione", "templum": "2ª declinazione", "servus": "2ª declinazione", "donum": "2ª declinazione",
				"hortus": "2ª declinazione", "bellum": "2ª declinazione", "amicus": "2ª declinazione", "verbum": "2ª declinazione",
				"rex": "3ª declinazione", "miles": "3ª declinazione", "flumen": "3ª declinazione", "mare": "3ª declinazione",
				"consul": "3ª declinazione", "corpus": "3ª declinazione", "civis": "3ª declinazione", "nomen": "3ª declinazione"}},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "In latino non è l'ordine delle parole a dire chi fa che cosa, ma la desinenza: il caso è il mestiere che la parola svolge nella frase.", "topic": "casi", "draw": 6, "prompt": "Smista ogni funzione nel caso che le corrisponde.",
			"categories": ["nominativo", "genitivo", "dativo", "accusativo"],
			"assignments": {
				"chi compie l'azione": "nominativo", "il soggetto della frase": "nominativo",
				"di chi si parla": "nominativo",
				"di chi è una cosa": "genitivo", "il complemento di specificazione": "genitivo",
				"«il libro DI Marco»": "genitivo",
				"a chi si dà qualcosa": "dativo", "il complemento di termine": "dativo",
				"«scrivo A mia sorella»": "dativo",
				"chi subisce l'azione": "accusativo", "il complemento oggetto": "accusativo",
				"«vedo LA CASA»": "accusativo"}},
		# --- Terzo smistamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Il numero si legge dalla desinenza, non dal senso: -a e -ae distinguono una rosa da molte rose senza bisogno di articoli.", "topic": "declinazioni-base", "draw": 6, "prompt": "Smista ogni forma: singolare o plurale?",
			"categories": ["singolare", "plurale"],
			"assignments": {
				"rosa": "singolare", "puella": "singolare", "silva": "singolare",
				"aqua": "singolare", "terra": "singolare", "stella": "singolare",
				"rosae": "plurale", "puellae": "plurale", "silvae": "plurale",
				"aquae": "plurale", "terrae": "plurale", "stellae": "plurale"}},
	],
	"logica": [
		# Fasce alte, scritte il 9 settembre 2026 (Fase 3 del piano): il censimento
		# trovava questa materia con meno di tre ricette nuove in queste fasce.
		{"topic": "insiemi", "minLevel": 10, "draw": 6, "prompt": "Da «tutti i cani sono animali»: smista ogni affermazione secondo se si puo' dedurre.",
			"categories": ["segue per forza", "non segue"],
			"assignments": {
				"se e' un cane, allora e' un animale": "segue per forza", "non esiste un cane che non sia animale": "segue per forza",
				"i cani stanno dentro il gruppo degli animali": "segue per forza", "chi non e' animale non e' cane": "segue per forza",
				"tutti gli animali sono cani": "non segue", "se e' un animale, allora e' un cane": "non segue",
				"esiste per certo un animale che non e' cane": "non segue", "i due gruppi coincidono esattamente": "non segue"},
			"explanation": "Una frase con «tutti» vale in una direzione sola: dal gruppo piccolo a quello grande. Girarla al contrario e' l'errore piu' frequente del ragionamento, e ha perfino un nome — conversione illecita."},
		{"topic": "verita", "minLevel": 13, "draw": 6, "prompt": "Smista ogni coppia di affermazioni: possono essere vere insieme?",
			"categories": ["stanno insieme", "si escludono"],
			"assignments": {
				"piove / fa freddo": "stanno insieme", "e' alto / e' magro": "stanno insieme",
				"studia / lavora": "stanno insieme", "e' rosso / e' grande": "stanno insieme",
				"piove / non piove": "si escludono", "e' tutto blu / e' tutto rosso": "si escludono",
				"sono tutti presenti / manca qualcuno": "si escludono", "e' il piu' alto / c'e' chi lo supera": "si escludono"},
			"explanation": "Due affermazioni si escludono solo quando una nega l'altra, non quando parlano di cose diverse: alto e magro convivono benissimo. Riconoscere una contraddizione vera serve soprattutto a non vederne dove non ci sono."},
		{"topic": "deduzioni", "minLevel": 16, "draw": 6, "prompt": "Smista ogni ragionamento: la conclusione segue davvero dalle premesse?",
			"categories": ["non lascia scampo", "solo probabile"],
			"assignments": {
				"tutti i A sono B, x e' A, quindi x e' B": "non lascia scampo", "nessun A e' B, x e' A, quindi x non e' B": "non lascia scampo",
				"se piove la strada si bagna, piove, quindi si bagna": "non lascia scampo", "tutti i A sono B, x non e' B, quindi x non e' A": "non lascia scampo",
				"tutti i A sono B, x e' B, quindi x e' A": "solo probabile", "se piove la strada si bagna, e' bagnata, quindi piove": "solo probabile",
				"molti A sono B, x e' A, quindi x e' B": "solo probabile", "alcuni A sono B, quindi ogni A e' B": "solo probabile"},
			"explanation": "La validita' non dipende da quanto la conclusione sembri sensata ma dalla forma: la strada puo' essersi bagnata perche' e' passata l'autobotte. Un ragionamento valido obbliga, uno plausibile suggerisce."},
		{"topic": "sequenze", "minLevel": 19, "draw": 6, "prompt": "Smista ogni serie secondo la regola che la governa.",
			"categories": ["si aggiunge sempre lo stesso", "si moltiplica sempre per lo stesso", "ognuno nasce dai due prima"],
			"assignments": {
				"2, 5, 8, 11": "si aggiunge sempre lo stesso", "7, 12, 17, 22": "si aggiunge sempre lo stesso",
				"3, 9, 15, 21": "si aggiunge sempre lo stesso", "10, 14, 18, 22": "si aggiunge sempre lo stesso",
				"2, 4, 8, 16": "si moltiplica sempre per lo stesso", "3, 9, 27, 81": "si moltiplica sempre per lo stesso",
				"5, 25, 125, 625": "si moltiplica sempre per lo stesso", "1, 10, 100, 1000": "si moltiplica sempre per lo stesso",
				"1, 1, 2, 3, 5": "ognuno nasce dai due prima", "2, 2, 4, 6, 10": "ognuno nasce dai due prima",
				"1, 3, 4, 7, 11": "ognuno nasce dai due prima", "4, 4, 8, 12, 20": "ognuno nasce dai due prima"},
			"explanation": "Per capire quale regola governa una serie si guarda il passaggio fra un termine e il successivo: se la differenza resta costante si aggiunge, se il rapporto resta costante si moltiplica. Quando nessuno dei due torna, la regola guarda piu' indietro."},
		{"topic": "esclusioni", "minLevel": 22, "draw": 6, "prompt": "Smista ogni indizio secondo quanto restringe il campo.",
			"categories": ["toglie una casella", "ne toglie molte insieme"],
			"assignments": {
				"non e' Marco": "toglie una casella", "non e' il rosso": "toglie una casella",
				"non e' arrivato per primo": "toglie una casella", "non abita al numero tre": "toglie una casella",
				"e' uno fra Marco e Luca": "ne toglie molte insieme", "e' un numero pari": "ne toglie molte insieme",
				"e' arrivato prima di Sara": "ne toglie molte insieme", "abita in una casa dispari": "ne toglie molte insieme"},
			"explanation": "In un enigma a griglia conviene partire dagli indizi che tagliano di piu': un «e' uno fra due» chiude tutte le altre righe in un colpo, mentre una singola negazione libera una casella sola."},
		# L16. Tre gradi di verità invece di due: «a volte vera» è la categoria che
		# costa di più, perché obbliga a cercare sia un caso favorevole sia un
		# controesempio prima di decidere.
		{"explanation": "«Sempre vera» vuol dire che non esiste nemmeno un caso contrario. Basta un pinguino per far cadere «gli uccelli volano»: un solo controesempio è sufficiente.", "topic": "verita", "minLevel": 16, "draw": 6, "prompt": "Smista ogni affermazione: sempre vera, a volte vera o mai vera?",
			"categories": ["sempre vera", "a volte vera", "mai vera"],
			"assignments": {
				"Un quadrato ha quattro lati uguali": "sempre vera",
				"Un numero pari si divide per due": "sempre vera",
				"Un triangolo ha tre angoli": "sempre vera",
				"Ogni mese ha almeno 28 giorni": "sempre vera",
				"Due più due fa quattro": "sempre vera",
				"Un cerchio ha un solo centro": "sempre vera",
				"Piove di domenica": "a volte vera",
				"Un cane è nero": "a volte vera",
				"Un numero è maggiore di dieci": "a volte vera",
				"Una porta è aperta": "a volte vera",
				"Un libro ha le figure": "a volte vera",
				"Un bambino ha un fratello": "a volte vera",
				"Un triangolo ha quattro lati": "mai vera",
				"Un numero pari finisce per sette": "mai vera",
				"Il sole sorge a ovest": "mai vera",
				"Due più due fa cinque": "mai vera",
				"Un mese ha quaranta giorni": "mai vera",
				"Un numero è più grande di sé stesso": "mai vera"}},
		# L23. Necessario contro sufficiente, l'ultima distinzione logica del
		# percorso e la più utile fuori dalla scuola: «avere quattro lati» serve per
		# essere un quadrato ma non basta, «essere un quadrato» basta per essere un
		# rettangolo ma non serve.
		{"explanation": "Una condizione che basta da sola porta sempre alla conclusione; una che serve ma non basta è necessaria e va accompagnata da altro.", "topic": "quantificatori", "minLevel": 23, "draw": 6, "prompt": "Smista ogni condizione: basta da sola, oppure serve ma non basta?",
			"categories": ["basta da sola", "serve ma non basta"],
			"assignments": {
				"Finire per zero, per essere divisibile per cinque": "basta da sola",
				"Essere un quadrato, per essere un rettangolo": "basta da sola",
				"Piovere, per avere la strada bagnata": "basta da sola",
				"Essere a Roma, per essere in Italia": "basta da sola",
				"Essere il 25 dicembre, per essere Natale": "basta da sola",
				"Essere un cane, per essere un mammifero": "basta da sola",
				"Nascere a gennaio, per essere nato d'inverno": "basta da sola",
				"Avere tre lati uguali, per essere un triangolo equilatero": "basta da sola",
				"Avere quattro lati, per essere un quadrato": "serve ma non basta",
				"Essere un mammifero, per essere un cane": "serve ma non basta",
				"Essere in Italia, per essere a Roma": "serve ma non basta",
				"Avere la strada bagnata, per aver piovuto": "serve ma non basta",
				"Essere un rettangolo, per essere un quadrato": "serve ma non basta",
				"Essere dispari, per essere un numero primo": "serve ma non basta",
				"Avere le ali, per essere un uccello": "serve ma non basta",
				"Essere d'inverno, per essere gennaio": "serve ma non basta"}},
		{"topic": "esclusioni", "draw": 6, "prompt": "Smista ogni affermazione: è sempre vera o solo qualche volta?",
			"categories": ["sempre vera", "non sempre vera"],
			"assignments": {
				"Ogni quadrato ha quattro lati": "sempre vera",
				"Ogni triangolo ha tre angoli": "sempre vera",
				"Un numero pari si divide per due": "sempre vera",
				"Ogni mese ha almeno 28 giorni": "sempre vera",
				"Il ghiaccio è acqua diventata solida": "sempre vera",
				"Ogni cerchio ha un centro": "sempre vera",
				"I cani hanno la coda": "non sempre vera",
				"Gli uccelli volano": "non sempre vera",
				"D'estate fa caldo": "non sempre vera",
				"Chi è alto gioca a pallacanestro": "non sempre vera",
				"I gatti hanno il pelo nero": "non sempre vera",
				"Le mele sono rosse": "non sempre vera"},
			"explanation": "«Sempre vera» vuol dire che non esiste nemmeno un caso contrario. Basta un pinguino per far cadere «gli uccelli volano»: in logica un solo controesempio è sufficiente."},
		# In logica la profondità non può venire da PIÙ ELEMENTI: un insieme di
		# trenta cani e trenta rose non rende il ragionamento più ricco, solo più
		# lungo. Deve venire da più REGOLE — quantificatori diversi, negazioni,
		# affermazioni vere per ragioni diverse. Perciò qui gli insiemi sono grandi
		# ma le voci sono scelte perché ciascuna chiede un passo di ragionamento suo.
		# **Il tavolo delle conclusioni.** (1 settembre 2026)
		#
		# Qui c'era «animale / pianta»: ventiquattro tessere di scienze dentro la
		# materia sbagliata. Era contenuto corretto e richiamo puro — Cane va con
		# animale, Rosa con pianta — mentre le domande di deduzione, le migliori
		# che la logica possiede, restavano tutte a scelta multipla. Il gesto
		# buono serviva il contenuto peggiore: qui l'accoppiamento si raddrizza.
		#
		# La regola di scrittura che lo rende non banale: **ogni forma valida sta
		# in tavola insieme alla sua fallacia, con le stesse parole.** «Piove → la
		# strada è bagnata» accanto a «la strada è bagnata → piove». Con la
		# coppia davanti, nessuna parola chiave decide il bidone: decide solo la
		# forma del ragionamento, che è esattamente la competenza.
		#
		# Il bidone di mezzo è quello che costa: «non si può dire» non è una
		# rinuncia, è una conclusione — ed è la più difficile da accettare.
		{"explanation": "Da una regola generale si scende sempre sul caso singolo, e si risale solo per negazione: se la strada è asciutta non piove di sicuro, ma se è bagnata può essere passata l'autobotte. «Non si può dire» non vuol dire «non lo so»: vuol dire che le premesse lasciano aperte tutte e due le strade.", "topic": "deduzioni", "draw": 6, "prompt": "Ogni carta propone una conclusione. Smistala: segue di sicuro, non si può dire, oppure è esclusa?",
			"categories": ["segue di sicuro", "non si può dire", "è escluso"],
			"assignments": {
				"Tutti i cani abbaiano. Fido è un cane. Quindi Fido abbaia": "segue di sicuro",
				"Nessun pesce vola. Nemo è un pesce. Quindi Nemo non vola": "segue di sicuro",
				"Se piove la strada si bagna. Piove. Quindi la strada è bagnata": "segue di sicuro",
				"Se piove la strada si bagna. La strada è asciutta. Quindi non sta piovendo": "segue di sicuro",
				"Ada è più alta di Bea, Bea è più alta di Cleo. Quindi Ada è più alta di Cleo": "segue di sicuro",
				"Nella scatola ci sono solo biglie rosse e blu. Questa non è rossa. Quindi è blu": "segue di sicuro",
				"Tutti i quadrati sono rettangoli. Questa figura non è un rettangolo. Quindi non è un quadrato": "segue di sicuro",
				"Alcuni gatti sono neri. Quindi esiste almeno un gatto nero": "segue di sicuro",
				"Se piove la strada si bagna. La strada è bagnata. Quindi sta piovendo": "non si può dire",
				"Se piove la strada si bagna. Non piove. Quindi la strada è asciutta": "non si può dire",
				"Tutti i cani abbaiano. Questo animale abbaia. Quindi è un cane": "non si può dire",
				"Alcuni gatti sono neri. Micio è un gatto. Quindi Micio è nero": "non si può dire",
				"Ada è più alta di Bea, Ada è più alta di Cleo. Quindi Bea è più alta di Cleo": "non si può dire",
				"Tutti i quadrati sono rettangoli. Questa figura è un rettangolo. Quindi è un quadrato": "non si può dire",
				"Se studio passo l'esame. Ho passato l'esame. Quindi ho studiato": "non si può dire",
				"Tutti i cani abbaiano. Questo animale non è un cane. Quindi non abbaia": "non si può dire",
				"Tutti i cani abbaiano. Fido è un cane. Quindi Fido non abbaia": "è escluso",
				"Nessun pesce vola. Nemo è un pesce. Quindi Nemo vola": "è escluso",
				"Ada è più alta di Bea. Quindi Bea è più alta di Ada": "è escluso",
				"Se piove la strada si bagna. Piove. Quindi la strada resta asciutta": "è escluso",
				"Tutti i quadrati hanno quattro lati. Questa figura è un quadrato. Quindi ha tre lati": "è escluso",
				"Nella scatola ci sono solo biglie rosse e blu. Questa non è rossa. Quindi è verde": "è escluso",
				"Nessun numero pari è dispari. 8 è pari. Quindi 8 è dispari": "è escluso",
				"Alcuni gatti sono neri. Quindi nessun gatto è nero": "è escluso"}},
		# **L'analogia che ragiona.** (1 settembre 2026)
		#
		# Le sei liste di analogie della logica sono andate a italiano, dove sono
		# vocabolario e servono. Qui resta la parte che è logica: non completare
		# la coppia — quello lo fa chi conosce le parole — ma RICONOSCERE quale
		# legame tiene insieme le due, che è il primo passo di ogni analogia e
		# l'unico che si può sbagliare ragionando.
		#
		# Nessun bidone si trova cercandone il nome dentro la tessera: «il piccolo
		# di» non compare in «Cucciolo : cane», e «serve per» non compare in
		# «Forbici : tagliare». Bisogna guardare il legame.
		{"explanation": "Un'analogia si risolve in due tempi: prima si dice a parole che cosa lega la prima coppia, poi si cerca lo stesso legame nella seconda. Saltare il primo tempo vuol dire indovinare, e infatti chi sbaglia un'analogia quasi sempre ha trovato una parola che «ci sta bene» invece della relazione.", "topic": "analogie", "draw": 6, "prompt": "Che legame tiene insieme le due parole? Smista ogni coppia.",
			"categories": ["il piccolo di", "una parte di", "il contrario di", "serve per"],
			"assignments": {
				"Cucciolo : cane": "il piccolo di",
				"Puledro : cavallo": "il piccolo di",
				"Agnello : pecora": "il piccolo di",
				"Girino : rana": "il piccolo di",
				"Vitello : mucca": "il piccolo di",
				"Pulcino : gallina": "il piccolo di",
				"Ruota : automobile": "una parte di",
				"Pagina : libro": "una parte di",
				"Petalo : fiore": "una parte di",
				"Tasto : pianoforte": "una parte di",
				"Gradino : scala": "una parte di",
				"Mattone : muro": "una parte di",
				"Giorno : notte": "il contrario di",
				"Salita : discesa": "il contrario di",
				"Pieno : vuoto": "il contrario di",
				"Guerra : pace": "il contrario di",
				"Luce : buio": "il contrario di",
				"Partenza : arrivo": "il contrario di",
				"Forbici : tagliare": "serve per",
				"Martello : battere": "serve per",
				"Bussola : orientarsi": "serve per",
				"Bilancia : pesare": "serve per",
				"Setaccio : separare": "serve per",
				"Ombrello : ripararsi": "serve per"}},
		{"explanation": "Si verifica il fatto, non l'impressione: una frase è vera se corrisponde a come stanno le cose, anche quando suona strana.", "topic": "verita", "minLevel": 4, "draw": 6, "prompt": "Ogni affermazione: è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"Tutti i quadrati hanno 4 lati": "vera", "Alcuni uccelli volano": "vera",
				"Ogni numero pari è divisibile per 2": "vera", "Nessun triangolo ha 4 lati": "vera",
				"Alcuni mammiferi vivono nell'acqua": "vera", "Tutti i cani sono animali": "vera",
				"Alcuni numeri primi sono pari": "vera", "Nessun quadrato è un cerchio": "vera",
				"Tutti i cerchi hanno un raggio": "vera", "Alcuni rettangoli sono quadrati": "vera",
				"Ogni multiplo di 4 è pari": "vera", "Non tutti gli uccelli volano": "vera",
				"Tutti i pesci volano": "falsa", "Un triangolo ha 4 lati": "falsa",
				"Nessun cane è un animale": "falsa", "Tutti i numeri dispari sono primi": "falsa",
				"Ogni animale che vola è un uccello": "falsa", "Tutti i quadrati sono cerchi": "falsa",
				"Nessun numero pari è divisibile per 2": "falsa", "Tutti i rettangoli sono quadrati": "falsa",
				"Alcuni triangoli hanno quattro angoli": "falsa", "Ogni pianta è verde": "falsa",
				"Nessun mammifero depone uova": "falsa", "Tutti i numeri maggiori di 2 sono primi": "falsa"}},
		# Scuola media — ragionamento sui quantificatori.
		{"explanation": "«Sempre» non ammette eccezioni, «a volte» ne ammette, «mai» le esclude tutte: la differenza sta nel quantificatore, non nel fatto.", "topic": "quantificatori", "minLevel": 6, "draw": 6, "prompt": "Ogni cosa accade sempre, a volte o mai?",
			"categories": ["sempre", "a volte", "mai"],
			"assignments": {
				"Un triangolo ha 3 lati": "sempre", "Il ghiaccio è freddo": "sempre",
				"La somma di due numeri pari è pari": "sempre", "Il quadrato di un numero è positivo o zero": "sempre",
				"Un quadrato ha i lati uguali": "sempre", "L'acqua bagna": "sempre",
				"Un numero diviso per sé stesso fa 1": "sempre", "Il Sole sorge a est": "sempre",
				"Piove": "a volte", "Un bambino dorme": "a volte",
				"Un numero pari è anche multiplo di 4": "a volte", "Un rettangolo è un quadrato": "a volte",
				"Fa freddo a settembre": "a volte", "Un animale che vola è un uccello": "a volte",
				"La neve arriva a dicembre": "a volte", "Una parola lunga è difficile": "a volte",
				"Un cerchio ha spigoli": "mai", "2 è un numero dispari": "mai",
				"Un triangolo ha due angoli retti": "mai", "La somma di due numeri pari è dispari": "mai",
				"Un quadrato ha cinque lati": "mai", "Un numero è maggiore di sé stesso": "mai",
				"Il ghiaccio è più caldo del vapore": "mai", "Un pesce vive fuori dall'acqua per sempre": "mai"}},
		# **Gli insiemi, non gli elementi.** (1 settembre 2026)
		#
		# Qui c'era «colori / forme / numeri»: Rosso nel bidone dei colori, Cerchio
		# in quello delle forme. Ventiquattro tessere di richiamo, zero passi di
		# ragionamento, in un argomento — «insiemi» — che ha invece una cosa sola
		# da insegnare e non la chiedeva mai: come stanno DUE insiemi l'uno
		# rispetto all'altro.
		#
		# Adesso la tessera è una coppia e il bidone è la relazione. Non si può
		# indovinare per parola: bisogna cercare un elemento comune (ce n'è?) e
		# poi un elemento del primo fuori dal secondo (ce n'è?). Due domande, e
		# la risposta esce da sola — è il diagramma di Venn prima del disegno.
		{"explanation": "Due insiemi possono stare in tre modi soli. Per decidere bastano due domande: c'è qualcosa in comune? E c'è qualcosa del primo che sta fuori dal secondo? Se non c'è niente in comune sono separati; se c'è tutto in comune uno sta dentro l'altro; se ce n'è un po' si sovrappongono. Il 2 basta a far sovrapporre pari e primi.", "topic": "insiemi", "minLevel": 3, "draw": 6, "prompt": "Come stanno fra loro i due insiemi? Smista ogni coppia.",
			"categories": ["uno dentro l'altro", "si sovrappongono in parte", "separati"],
			"assignments": {
				"Quadrati e rettangoli": "uno dentro l'altro",
				"Cani e mammiferi": "uno dentro l'altro",
				"Numeri pari e multipli di 4": "uno dentro l'altro",
				"Chitarristi e musicisti": "uno dentro l'altro",
				"Rose e fiori": "uno dentro l'altro",
				"Numeri primi e numeri interi": "uno dentro l'altro",
				"Città italiane e città europee": "uno dentro l'altro",
				"Violini e strumenti a corda": "uno dentro l'altro",
				"Numeri pari e numeri primi": "si sovrappongono in parte",
				"Uccelli e animali che volano": "si sovrappongono in parte",
				"Medici e italiani": "si sovrappongono in parte",
				"Numeri pari e multipli di 3": "si sovrappongono in parte",
				"Numeri pari e numeri maggiori di dieci": "si sovrappongono in parte",
				"Numeri dispari e multipli di 3": "si sovrappongono in parte",
				"Insegnanti e genitori": "si sovrappongono in parte",
				"Numeri pari e numeri di due cifre": "si sovrappongono in parte",
				"Numeri pari e numeri dispari": "separati",
				"Cani e gatti": "separati",
				"Triangoli e quadrilateri": "separati",
				"Vocali e consonanti": "separati",
				"Mammiferi e uccelli": "separati",
				"Numeri primi e multipli di 4": "separati",
				"Rettili e uccelli": "separati",
				"Vertebrati e insetti": "separati"}},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		# **Lo smistamento che premiava la prima parola.** (1 settembre 2026)
		#
		# Prima le tessere erano «Ogni quadrato…», «Qualche uccello…», «Nessun
		# triangolo…» e i bidoni si chiamavano «tutti», «qualcuno», «nessuno»:
		# nove tessere su nove decise dalla prima parola. Chi aveva imparato tre
		# vocaboli e non aveva capito niente prendeva nove su nove.
		#
		# Adesso i bidoni non sono il quantificatore della frase ma quello della
		# sua NEGAZIONE — e le due cose non coincidono mai. Negare «tutti» non dà
		# «nessuno», dà «almeno uno no»; negare «nessuno» dà «almeno uno sì». Chi
		# cerca la parola del bidone dentro la tessera («nessun» in «Nessun
		# uccello vola») finisce nel bidone sbagliato di proposito.
		{"explanation": "Negare un «tutti» non dà un «nessuno»: basta UN caso contrario, e la frase cade. Negare un «qualcuno» invece costa molto di più — bisogna che non ce ne sia nemmeno uno — e negare un «nessuno» richiede di trovarne uno solo. Il quantificatore della negazione è sempre l'altro rispetto a quello di partenza.", "topic": "quantificatori", "draw": 6, "prompt": "Ognuna di queste frasi è FALSA. Smista che cosa questo fa sapere di sicuro.",
			"categories": ["almeno uno NON lo è", "nessuno lo è", "almeno uno LO è"],
			"assignments": {
				"Tutti i numeri primi sono dispari": "almeno uno NON lo è",
				"Ogni numero pari è divisibile per tre": "almeno uno NON lo è",
				"Ogni pianta è verde": "almeno uno NON lo è",
				"Tutti i pianeti hanno gli anelli": "almeno uno NON lo è",
				"Ciascun mese ha trentun giorni": "almeno uno NON lo è",
				"Tutti i mammiferi vivono sulla terraferma": "almeno uno NON lo è",
				"Ogni parola italiana finisce per vocale": "almeno uno NON lo è",
				"Qualche gatto vola": "nessuno lo è",
				"Alcuni triangoli hanno quattro lati": "nessuno lo è",
				"C'è almeno un mese con quaranta giorni": "nessuno lo è",
				"Qualche numero è più grande di sé stesso": "nessuno lo è",
				"Almeno un quadrato ha tre lati": "nessuno lo è",
				"Alcuni numeri pari sono dispari": "nessuno lo è",
				"C'è almeno un triangolo con due angoli retti": "nessuno lo è",
				"Nessun uccello vola": "almeno uno LO è",
				"Nessun numero pari è divisibile per due": "almeno uno LO è",
				"Non esiste un mammifero che vive nell'acqua": "almeno uno LO è",
				"Nessun rettangolo è un quadrato": "almeno uno LO è",
				"Non c'è nemmeno un gatto nero": "almeno uno LO è",
				"Nessun numero è divisibile per sé stesso": "almeno uno LO è",
				"Non esiste un mese con ventotto giorni": "almeno uno LO è"}},
		{"explanation": "Per dire che una frase con «tutti» è falsa basta UN caso contrario; per dire che una con «qualcuno» è falsa bisogna controllarli tutti. Non costano la stessa fatica.", "topic": "verita", "draw": 6, "prompt": "Smista ogni affermazione: vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"Tutti i cani sono animali": "vera",
				"Alcuni uccelli non volano": "vera",
				"Ogni numero pari è divisibile per due": "vera",
				"Nessun triangolo ha quattro lati": "vera",
				"Qualche numero primo è pari": "vera",
				"Tutti gli animali sono cani": "falsa",
				"Ogni numero pari è divisibile per tre": "falsa",
				"Nessun uccello vola": "falsa",
				"Tutti i numeri primi sono dispari": "falsa",
				"Ogni rettangolo è un quadrato": "falsa"}},
	],
}

# Lettura di GRAFICO (assi + curva disegnati proceduralmente): scegli il punto
# richiesto. Nessun asset immagine. `points` in coordinate normalizzate 0..1.
const GRAPH := {
	"elettronica": [
		{"topic": "serie-parallelo", "minLevel": 16, "xLabel": "pile in serie", "yLabel": "tensione", "answer": "D",
			"prompt": "Aggiungendo pile uguali in serie, in quale punto la tensione totale è maggiore?",
			"domande": [
				{"prompt": "In quale punto tensione scende al minimo?", "answer": "A", "explanation": "Il punto più basso è A: conta l'altezza, non quanto sta a destra. Poca tensione vuol dire poca spinta: il circuito riceve meno energia per far muovere le cariche."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di tensione?", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C. Un salto grande di tensione vuol dire che lì è stato aggiunto il contributo più grosso."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.43, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.67, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.91, "label": "D"}],
			"explanation": "In serie le tensioni delle pile si sommano: con più pile la tensione totale cresce, fino al punto D."},
		{"topic": "legge-ohm", "minLevel": 16, "xLabel": "resistenza", "yLabel": "corrente", "answer": "D",
			"prompt": "A tensione costante, la corrente diminuisce quando la resistenza aumenta. In quale punto la corrente è minore?",
			"domande": [
				{"prompt": "Guardando il grafico, dove corrente tocca il valore più alto?", "answer": "A", "explanation": "Il punto più alto è A: conta l'altezza, non quanto sta a destra. Molta corrente vuol dire molta carica che passa ogni secondo — ed è anche quando i fili scaldano di più."},
				{"prompt": "Quale punto è il più vicino alla metà strada fra minimo e massimo di corrente?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.91, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.65, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.40, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.18, "label": "D"}],
			"explanation": "Con la stessa tensione, una resistenza maggiore lascia passare meno corrente: il minimo è D."},
		{"topic": "legge-ohm", "minLevel": 16, "xLabel": "tensione", "yLabel": "corrente", "answer": "D",
			"prompt": "Il grafico mostra la corrente al crescere della tensione (legge di Ohm): in quale punto la corrente è massima?",
			"domande": [
				{"prompt": "Quale punto ha il valore di corrente più basso di tutti?", "answer": "A", "explanation": "Il punto più basso è A: conta l'altezza, non quanto sta a destra. Poca corrente vuol dire poca carica che passa ogni secondo: il LED illumina meno."},
				{"prompt": "Fra due punti vicini, dove corrente cresce di più? Indica il punto in cui arriva.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B. Un salto grande di corrente vuol dire che lì il circuito ha lasciato passare molto di più di prima."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.42, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.94, "label": "D"}],
			"explanation": "La corrente cresce in modo proporzionale alla tensione: è massima all'ultimo punto, D."},
		{"topic": "batteria", "minLevel": 13, "xLabel": "tempo", "yLabel": "carica", "answer": "D",
			"prompt": "Il grafico mostra la carica di una batteria mentre si scarica usandola: in quale punto è più scarica?",
			"domande": [
				{"prompt": "In quale punto carica arriva al massimo?", "answer": "A", "explanation": "Il punto più alto è A: conta l'altezza, non quanto sta a destra. Carica al massimo: la batteria è piena e il circuito ha tutta l'energia che gli serve."},
				{"prompt": "Guardando il grafico, dove carica tocca il valore più basso?", "answer": "D", "explanation": "Il punto più basso è D: conta l'altezza, non quanto sta a destra. Poca carica vuol dire batteria vicina a esaurirsi: da lì in poi il circuito comincia a spegnersi."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.66, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.38, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.12, "label": "D"}],
			"explanation": "Usandola la carica cala nel tempo: la batteria è più scarica alla fine, nel punto D."},
		{"topic": "legge-ohm", "minLevel": 20, "xLabel": "tensione", "yLabel": "corrente", "answer": "B",
			"prompt": "Ogni punto è una misura diversa. Poiché R = V / I, quale punto indica la resistenza maggiore (tensione alta ma corrente bassa)?",
			"domande": [
				{"prompt": "Guardando il grafico, dove corrente tocca il valore più basso?", "answer": "B", "explanation": "Il punto più basso è B: conta l'altezza, non quanto sta a destra. Poca corrente vuol dire poca carica che passa ogni secondo: il LED illumina meno."},
				{"prompt": "Dove corrente fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C. Un salto grande di corrente vuol dire che lì il circuito ha lasciato passare molto di più di prima."},
			],
			"points": [{"id": "A", "x": 0.28, "y": 0.72, "label": "A"}, {"id": "B", "x": 0.72, "y": 0.34, "label": "B"}, {"id": "C", "x": 0.48, "y": 0.80, "label": "C"}, {"id": "D", "x": 0.86, "y": 0.74, "label": "D"}],
			"explanation": "La resistenza è il rapporto V/I: B combina una tensione alta con una corrente bassa, quindi ha il rapporto maggiore."},
		# --- Quattro grafici che non chiedono nessuna formula (3 settembre 2026) ---
		{"topic": "misure-elettriche", "xLabel": "pile provate", "yLabel": "volt sull'etichetta", "answer": "D",
			"prompt": "Ogni punto è una pila diversa. In quale punto l'etichetta dice più volt?",
			"domande": [
				{"prompt": "In quale punto l'etichetta dice meno volt di tutte?", "answer": "A", "explanation": "Il punto più basso è A: si guarda l'altezza, non quanto sta a destra. Meno volt vuol dire spinta più debole, non pila più piccola."},
				{"prompt": "Quale punto sta più vicino alla metà strada fra la pila più debole e la più forte?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto che le sta più vicino: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.10, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.45, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.93, "label": "D"}],
			"explanation": "I volt si leggono sull'etichetta e si confrontano come numeri: il massimo è il punto più in alto, D."},
		{"topic": "energia-nei-componenti", "xLabel": "LED accesi", "yLabel": "ore di pila", "answer": "D",
			"prompt": "Con la stessa pila accendi sempre più LED insieme. In quale punto la pila dura di meno?",
			"domande": [
				{"prompt": "In quale punto la pila dura di più?", "answer": "A", "explanation": "Il punto più alto è A: si guarda l'altezza, non quanto sta a destra. Con un LED solo la pila ha poco da alimentare e dura a lungo."},
				{"prompt": "Fra due punti vicini, dove le ore di pila calano di più? Indica il punto d'arrivo.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma di quanto SCENDE rispetto a quello prima: il tratto più ripido arriva in B. Lì il LED aggiunto ha pesato più di tutti."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.56, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.34, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.14, "label": "D"}],
			"explanation": "Ogni LED acceso prende energia dalla stessa pila: più ne accendi, prima la riserva finisce. Il minimo è D."},
		{"topic": "conduttori", "minLevel": 5, "xLabel": "materiale provato", "yLabel": "corrente che passa", "answer": "A",
			"prompt": "Hai messo quattro materiali diversi nello stesso circuito. In quale punto passa più corrente?",
			"domande": [
				{"prompt": "In quale punto passa meno corrente di tutti?", "answer": "D", "explanation": "Il punto più basso è D: si guarda l'altezza, non la posizione. Corrente quasi zero vuol dire isolante: il materiale non lascia passare quasi niente."},
				{"prompt": "Quale punto sta più vicino alla metà strada fra il minimo e il massimo?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto che le sta più vicino: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.93, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.24, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.08, "label": "D"}],
			"explanation": "I metalli lasciano passare molta corrente, plastica e gomma quasi niente: il massimo è A, il metallo della prova."},
		{"topic": "circuito", "minLevel": 9, "xLabel": "fili staccati", "yLabel": "lampadine accese", "answer": "D",
			"prompt": "Stacchi un filo alla volta da un circuito in serie. In quale punto restano accese meno lampadine?",
			"domande": [
				{"prompt": "In quale punto sono accese più lampadine?", "answer": "A", "explanation": "Il punto più alto è A: si guarda l'altezza. Con tutti i fili al loro posto il giro è chiuso e le lampadine si accendono tutte."},
				{"prompt": "Fra due punti vicini, dove il numero di lampadine accese crolla di più? Indica il punto d'arrivo.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma di quanto SCENDE rispetto a quello prima: il salto più grande arriva in B. Quel filo teneva insieme il pezzo più grosso del giro."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.94, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.48, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.26, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.06, "label": "D"}],
			"explanation": "In serie basta un buco per fermare tutto: più fili stacchi, meno lampadine restano accese. Il minimo è D."},
		{"topic": "segnali", "minLevel": 23, "xLabel": "tempo", "yLabel": "tensione", "answer": "B",
			"prompt": "Un segnale digitale dovrebbe restare basso o alto. Quale punto è disturbato e cade in una zona intermedia incerta?",
			"domande": [
				{"prompt": "Quale punto ha il valore di tensione più alto di tutti?", "answer": "D", "explanation": "Il punto più alto è D: conta l'altezza, non quanto sta a destra. Molta tensione vuol dire molta spinta sulle cariche: è la pila che lavora al massimo."},
				{"prompt": "In quale punto tensione scende al minimo?", "answer": "A", "explanation": "Il punto più basso è A: conta l'altezza, non quanto sta a destra. Poca tensione vuol dire poca spinta: il circuito riceve meno energia per far muovere le cariche."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.12, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.50, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.90, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.91, "label": "D"}],
			"explanation": "A è un livello basso e C-D sono alti; B sta a metà, dove il circuito non legge con sicurezza né 0 né 1."},
		{"topic": "condensatore", "minLevel": 21, "xLabel": "tempo", "yLabel": "tensione", "answer": "C",
			"prompt": "Un condensatore si carica rapidamente e poi si avvicina al valore massimo. Quale punto mostra che è quasi carico?",
			"domande": [
				{"prompt": "In quale punto tensione scende al minimo?", "answer": "A", "explanation": "Il punto più basso è A: conta l'altezza, non quanto sta a destra. Poca tensione vuol dire poca spinta: il circuito riceve meno energia per far muovere le cariche."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di tensione?", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B. Un salto grande di tensione vuol dire che lì è stato aggiunto il contributo più grosso."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.16, "label": "A"}, {"id": "B", "x": 0.34, "y": 0.66, "label": "B"}, {"id": "C", "x": 0.72, "y": 0.91, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.92, "label": "D"}],
			"explanation": "La curva ormai è quasi orizzontale e vicina al massimo: in C il condensatore è quasi carico."},
	],
	"fisica": [
		{"topic": "moto", "xLabel": "tempo", "yLabel": "velocità", "answer": "C",
			"prompt": "Il grafico mostra la velocità nel tempo: in quale punto è massima?",
			"domande": [
				{"prompt": "Guardando il grafico, dove velocità tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico velocità cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "Dopo quale punto la velocità comincia a scendere invece di salire?", "answer": "C", "explanation": "Si cerca la cima: fino a C la linea sale, da C in poi va giù. Il punto di svolta è C, e da lì in avanti l'oggetto sta rallentando."},
				{"prompt": "Dove velocità fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.50, "label": "D"}],
			"explanation": "La velocità è massima dove la curva è più in alto: il punto C."},
		{"topic": "pressione", "minLevel": 13, "xLabel": "profondità", "yLabel": "pressione", "answer": "D",
			"prompt": "Il grafico mostra la pressione mentre un sub scende. In quale punto è più alta?",
			"domande": [
				{"prompt": "In quale punto il sub è meno in profondità e sente meno pressione?", "answer": "A", "explanation": "A è il punto più basso su entrambi gli assi: poca profondità, poca acqua sopra e quindi poca pressione."},
				{"prompt": "La profondità aumenta da B a C: che cosa fa la pressione?", "answer": "C", "explanation": "Anche la pressione sale: sul grafico C è più in alto di B."}],
			"points": [{"id": "A", "x": 0.10, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.38, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.66, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.92, "label": "D"}],
			"explanation": "Più il sub scende, più acqua ha sopra di sé: la pressione è massima nel punto D."},
		{"topic": "temperatura", "xLabel": "tempo", "yLabel": "temperatura", "answer": "A",
			"prompt": "Una bevanda calda si raffredda sul tavolo. In quale punto è ancora più calda?",
			"domande": [
				{"prompt": "Quale punto ha il valore di temperatura più basso di tutti?", "answer": "D", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico temperatura cresce verso l'alto, quindi il punto più basso è D."},
				{"prompt": "Fra due punti vicini, dove la bevanda perde più calore in una volta sola? Indica il punto d'arrivo.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma di quanto SCENDE rispetto a quello prima: il tratto più ripido arriva in B. Appena versata la bevanda è molto più calda dell'aria, e proprio per questo si raffredda in fretta."},
				{"prompt": "Fra due punti vicini, dove temperatura cresce di più? Indica il punto in cui arriva.", "answer": "D", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in D."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.65, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.43, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.28, "label": "D"}],
			"explanation": "All'inizio la bevanda non ha ancora ceduto molto calore all'ambiente: A è il punto più caldo."},
		{"topic": "moto", "minLevel": 4, "xLabel": "tempo", "yLabel": "distanza", "answer": "D",
			"prompt": "Il grafico mostra la distanza percorsa nel tempo: in quale punto l'oggetto è più lontano dalla partenza?",
			"domande": [
				{"prompt": "In quale punto distanza arriva al massimo?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Guardando il grafico, dove distanza tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico distanza cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.12, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.66, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.92, "y": 0.95, "label": "D"}],
			"explanation": "La distanza cresce sempre: l'oggetto è più lontano alla fine, nel punto D."},
		{"topic": "caduta", "minLevel": 6, "xLabel": "tempo", "yLabel": "velocità", "answer": "D",
			"prompt": "Un sasso cade e accelera per gravità: in quale punto va più veloce?",
			"domande": [
				{"prompt": "Guardando il grafico, dove velocità tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico velocità cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "Dove velocità fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "D", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in D."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.08, "label": "A"}, {"id": "B", "x": 0.40, "y": 0.28, "label": "B"}, {"id": "C", "x": 0.68, "y": 0.58, "label": "C"}, {"id": "D", "x": 0.92, "y": 0.95, "label": "D"}],
			"explanation": "Cadendo la velocità cresce sempre di più: è massima alla fine, nel punto D."},
		{"topic": "dinamica", "minLevel": 12, "xLabel": "massa", "yLabel": "accelerazione", "answer": "D",
			"prompt": "La stessa spinta agisce su carrelli di massa diversa. Quale punto rappresenta il carrello più pesante, che accelera meno?",
			"domande": [
				{"prompt": "Quale punto ha il valore di accelerazione più alto di tutti?", "answer": "A", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è A. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha accelerazione più o meno a metà fra il minimo e il massimo?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.90, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.65, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.40, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.20, "label": "D"}],
			"explanation": "Con la stessa forza, aumentando la massa l'accelerazione diminuisce: D ha massa massima e accelerazione minima."},
		{"topic": "onde", "minLevel": 23, "xLabel": "tempo", "yLabel": "spostamento", "answer": "C",
			"prompt": "Il grafico mostra un'oscillazione. Quale punto è il ventre inferiore, cioè lo spostamento massimo sotto l'equilibrio?",
			"domande": [
				{"prompt": "In quale punto spostamento scende al minimo?", "answer": "C", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico spostamento cresce verso l'alto, quindi il punto più basso è C."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di spostamento?", "answer": "D", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in D."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.50, "label": "A"}, {"id": "B", "x": 0.34, "y": 0.90, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.10, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.52, "label": "D"}],
			"explanation": "La linea di equilibrio è a metà: C è il punto più lontano verso il basso, quindi il ventre inferiore."},
		{"topic": "passaggi-stato", "minLevel": 19, "xLabel": "tempo", "yLabel": "temperatura", "answer": "C",
			"prompt": "Il ghiaccio viene scaldato. Quale punto ha quasi la stessa temperatura del punto precedente, perché durante la fusione la curva si appiattisce?",
			"domande": [
				{"prompt": "Guardando il grafico, dove temperatura tocca il valore più alto?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha il valore di temperatura più basso di tutti?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico temperatura cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.34, "y": 0.48, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.50, "label": "C"}, {"id": "D", "x": 0.86, "y": 0.82, "label": "D"}],
			"explanation": "B e C sono quasi alla stessa altezza: arrivando a C il calore sta cambiando lo stato, non alzando la temperatura."},
	],
	"matematica": [
		{"topic": "coordinate", "xLabel": "x", "yLabel": "y", "answer": "Q",
			"prompt": "Quale punto si trova più in alto (ordinata y maggiore)?",
			"domande": [
				{"prompt": "Quale punto ha il valore di y più basso di tutti?", "answer": "P", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico y cresce verso l'alto, quindi il punto più basso è P."},
				{"prompt": "Fra due punti vicini, dove y cresce di più? Indica il punto in cui arriva.", "answer": "Q", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in Q."},
			],
			"points": [{"id": "P", "x": 0.20, "y": 0.35, "label": "P"}, {"id": "Q", "x": 0.50, "y": 0.85, "label": "Q"}, {"id": "R", "x": 0.80, "y": 0.55, "label": "R"}],
			"explanation": "Il punto Q ha l'ordinata (y) più grande."},
		# Lettura di grafici: competenza chiave di dati e statistica.
		{"topic": "dati", "xLabel": "ora", "yLabel": "temperatura", "answer": "C",
			"prompt": "Il grafico mostra la temperatura durante il giorno: in quale punto è massima?",
			"domande": [
				{"prompt": "In quale punto temperatura scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico temperatura cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di temperatura?", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.25, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.60, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.55, "label": "D"}],
			"explanation": "La temperatura è massima dove la curva è più in alto: il punto C."},
		{"topic": "dati", "xLabel": "settimana", "yLabel": "risparmi", "answer": "A",
			"prompt": "Il grafico mostra i risparmi settimana per settimana: in quale punto sono minimi?",
			"domande": [
				{"prompt": "Guardando il grafico, dove risparmi tocca il valore più alto?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto è il più vicino alla metà strada fra minimo e massimo di risparmi?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.40, "y": 0.45, "label": "B"}, {"id": "C", "x": 0.68, "y": 0.70, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.92, "label": "D"}],
			"explanation": "I risparmi sono minimi dove la curva è più in basso: il punto A."},
		{"topic": "funzioni", "minLevel": 6, "xLabel": "x", "yLabel": "y", "answer": "A",
			"prompt": "La retta sale da sinistra a destra: in quale punto tocca l'asse x (y = 0)?",
			"domande": [
				{"prompt": "Quale punto ha il valore di y più alto di tutti?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "In quale punto y scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico y cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.15, "y": 0.05, "label": "A"}, {"id": "B", "x": 0.45, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.72, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.92, "y": 0.90, "label": "D"}],
			"explanation": "La retta interseca l'asse x dove y vale (quasi) zero: il punto A, in basso."},
		{"topic": "proporzioni", "minLevel": 12, "xLabel": "quaderni", "yLabel": "costo", "answer": "D",
			"prompt": "Ogni quaderno costa uguale. Quale punto rappresenta l'acquisto con il costo totale maggiore?",
			"domande": [
				{"prompt": "In quale punto costo scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico costo cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di costo?", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.16, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.66, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.92, "label": "D"}],
			"explanation": "Se il prezzo unitario è fisso, più quaderni significano un costo maggiore: D è massimo su entrambi gli assi."},
		{"topic": "funzioni", "minLevel": 23, "xLabel": "x", "yLabel": "y", "answer": "C",
			"prompt": "Una funzione cresce, raggiunge un massimo e poi diminuisce. Quale punto è il massimo locale?",
			"domande": [
				{"prompt": "Guardando il grafico, dove y tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico y cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "Dove y fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.24, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.62, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.46, "label": "D"}],
			"explanation": "C è più alto dei punti vicini: la funzione cresce fino a C e poi scende, quindi C è un massimo locale."},
		{"topic": "statistica", "minLevel": 19, "xLabel": "giorno", "yLabel": "media mobile", "answer": "B",
			"prompt": "La media mobile attenua gli sbalzi giornalieri. Quale punto indica l'inizio di una tendenza in discesa?",
			"domande": [
				{"prompt": "Quale punto ha il valore di media mobile più alto di tutti?", "answer": "B", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è B. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "In quale punto media mobile scende al minimo?", "answer": "D", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico media mobile cresce verso l'alto, quindi il punto più basso è D."},
			],
			"points": [{"id": "A", "x": 0.14, "y": 0.54, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.82, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.60, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.35, "label": "D"}],
			"explanation": "B è il massimo locale: dopo B i valori medi calano in C e D, quindi lì comincia la discesa."},
	],
	"scienze": [
		{"topic": "metodo", "xLabel": "giorni", "yLabel": "altezza", "answer": "D",
			"prompt": "La pianta cresce nel tempo: in quale punto è più alta?",
			"domande": [
				{"prompt": "In quale punto altezza scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico altezza cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di altezza?", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.70, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.95, "label": "D"}],
			"explanation": "La curva sale sempre: l'ultimo punto D è il più alto."},
		{"topic": "ecosistemi", "xLabel": "pioggia", "yLabel": "numero di piante", "answer": "D",
			"prompt": "Nello stesso terreno, più pioggia permette a più piante di crescere. Quale punto mostra il maggior numero di piante?",
			"domande": [
				{"prompt": "Guardando il grafico, dove numero di piante tocca il valore più alto?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha il valore di numero di piante più basso di tutti?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico numero di piante cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.41, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.66, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.90, "label": "D"}],
			"explanation": "Nel caso osservato il numero di piante cresce con la pioggia: il valore massimo è D."},
		{"topic": "materia", "minLevel": 4, "xLabel": "tempo", "yLabel": "temperatura", "answer": "D",
			"prompt": "Una tazza di tè si raffredda: in quale punto la temperatura è più bassa?",
			"domande": [
				{"prompt": "Quale punto ha il valore di temperatura più alto di tutti?", "answer": "A", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è A. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha temperatura più o meno a metà fra il minimo e il massimo?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è B."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.62, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.38, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.18, "label": "D"}],
			"explanation": "La curva scende raffreddandosi: la temperatura è più bassa alla fine, nel punto D."},
		{"topic": "fotosintesi", "minLevel": 8, "xLabel": "luce", "yLabel": "ossigeno prodotto", "answer": "D",
			"prompt": "Aumentando la luce, la fotosintesi cresce e poi raggiunge un limite. Quale punto mostra che altra luce cambia pochissimo il risultato?",
			"domande": [
				{"prompt": "In quale punto ossigeno prodotto arriva al massimo?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Guardando il grafico, dove ossigeno prodotto tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico ossigeno prodotto cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.62, "label": "B"}, {"id": "C", "x": 0.68, "y": 0.88, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.90, "label": "D"}],
			"explanation": "Arrivando a D la luce aumenta molto rispetto a C, ma l'ossigeno quasi no: la pianta è vicina al suo limite."},
		{"topic": "corpo", "minLevel": 15, "xLabel": "tempo dopo la corsa", "yLabel": "battiti", "answer": "D",
			"prompt": "Dopo una corsa i battiti tornano gradualmente verso il valore di riposo. In quale punto il recupero è più avanzato?",
			"domande": [
				{"prompt": "Guardando il grafico, dove battiti tocca il valore più alto?", "answer": "A", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è A. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha il valore di battiti più basso di tutti?", "answer": "D", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico battiti cresce verso l'alto, quindi il punto più basso è D."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.68, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.46, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.30, "label": "D"}],
			"explanation": "Più tempo passa, più i battiti scendono verso il riposo: D è il recupero più avanzato."},
		{"topic": "ecosistemi", "minLevel": 22, "xLabel": "inquinamento", "yLabel": "numero di specie", "answer": "D",
			"prompt": "Nel campione osservato, più inquinamento corrisponde a meno specie. Quale punto mostra la biodiversità più bassa?",
			"domande": [
				{"prompt": "Quale punto ha il valore di numero di specie più alto di tutti?", "answer": "A", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è A. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha numero di specie più o meno a metà fra il minimo e il massimo?", "answer": "C", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è C."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.68, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.44, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.18, "label": "D"}],
			"explanation": "D combina il massimo inquinamento con il minor numero di specie: è la biodiversità più bassa."},
	],
	"coding": [
		{"topic": "variabili", "xLabel": "passo", "yLabel": "valore di x", "answer": "D",
			"prompt": "Il programma parte da x = 1 e aggiunge 2 a ogni passo. In quale punto x è maggiore?",
			"domande": [
				{"prompt": "In quale punto valore di x scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico valore di x cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di valore di x?", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.42, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.66, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.90, "label": "D"}],
			"explanation": "Ogni istruzione aumenta x di 2: il valore cresce passo dopo passo ed è massimo in D."},
		{"topic": "cicli", "xLabel": "giro del ciclo", "yLabel": "elementi stampati", "answer": "C",
			"prompt": "Un ciclo stampa un elemento a ogni giro. Quale punto indica che sono stati stampati tre elementi?",
			"domande": [
				{"prompt": "Guardando il grafico, dove elementi stampati tocca il valore più alto?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha il valore di elementi stampati più basso di tutti?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico elementi stampati cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.18, "y": 0.25, "label": "A"}, {"id": "B", "x": 0.42, "y": 0.50, "label": "B"}, {"id": "C", "x": 0.66, "y": 0.75, "label": "C"}, {"id": "D", "x": 0.90, "y": 1.00, "label": "D"}],
			"explanation": "Dopo tre giri sono stati stampati tre elementi: il terzo punto è C."},
		{"topic": "variabili", "xLabel": "passo", "yLabel": "totale", "answer": "C",
			"prompt": "Il programma parte da totale = 0 e aggiunge in ordine 2, 3 e 4. In quale punto il totale supera 4 per la prima volta?",
			"domande": [
				{"prompt": "Quale punto ha il valore di totale più alto di tutti?", "answer": "D", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è D. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "In quale punto totale scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico totale cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.08, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.24, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.56, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.94, "label": "D"}],
			"explanation": "Dopo il primo passo il totale è 2; dopo il secondo è 5, quindi C è il primo punto sopra 4. D rappresenta il totale finale 9."},
		{"topic": "condizioni", "xLabel": "valore letto", "yLabel": "condizione (0/1)", "answer": "C",
			"prompt": "La condizione vale 0 finché il valore non è positivo e 1 quando valore > 0. Quale punto è il primo in cui diventa vera?",
			"domande": [
				{"prompt": "In quale punto condizione (0/1) arriva al massimo?", "answer": "C", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è C. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Guardando il grafico, dove condizione (0/1) tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico condizione (0/1) cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.10, "label": "A"}, {"id": "B", "x": 0.40, "y": 0.10, "label": "B"}, {"id": "C", "x": 0.66, "y": 0.90, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.90, "label": "D"}],
			"explanation": "A e B rappresentano valori non positivi; C è il primo valore sopra zero, quindi lì la condizione passa da 0 a 1."},
		{"topic": "variabili", "xLabel": "passo", "yLabel": "valore di energia", "answer": "D",
			"prompt": "Il programma parte da energia = 6 e sottrae 2 a ogni passo. In quale punto energia arriva a zero?",
			"domande": [
				{"prompt": "Guardando il grafico, dove valore di energia tocca il valore più alto?", "answer": "A", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è A. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha il valore di valore di energia più basso di tutti?", "answer": "D", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico valore di energia cresce verso l'alto, quindi il punto più basso è D."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.90, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.62, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.34, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.06, "label": "D"}],
			"explanation": "I valori sono 6, 4, 2 e 0: sottraendo 2 tre volte, energia raggiunge zero nel punto D."},
		{"topic": "condizioni", "minLevel": 8, "xLabel": "temperatura letta", "yLabel": "ventola (0/1)", "answer": "C",
			"prompt": "La ventola vale 0 fino a 25 °C e 1 sopra 25 °C. Quale punto è il primo in cui la condizione la accende?",
			"domande": [
				{"prompt": "Quale punto ha il valore di ventola (0/1) più alto di tutti?", "answer": "C", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è C. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "In quale punto ventola (0/1) scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico ventola (0/1) cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.18, "y": 0.10, "label": "A"}, {"id": "B", "x": 0.42, "y": 0.10, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.88, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.88, "label": "D"}],
			"explanation": "C è la prima lettura oltre la soglia: lì la condizione diventa vera e l'uscita passa da 0 a 1."},
		{"topic": "ricerca", "minLevel": 12, "xLabel": "passo", "yLabel": "elementi rimasti", "answer": "D",
			"prompt": "Una ricerca dimezza ogni volta la parte di elenco ancora da controllare. In quale punto restano meno elementi?",
			"domande": [
				{"prompt": "In quale punto elementi rimasti arriva al massimo?", "answer": "A", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è A. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Fra il valore più basso e quello più alto di elementi rimasti, quale punto sta in mezzo?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.54, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.30, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.17, "label": "D"}],
			"explanation": "A ogni passo resta circa metà dell'intervallo precedente: D è il punto con meno elementi da controllare."},
		{"topic": "sensori", "minLevel": 16, "xLabel": "tempo", "yLabel": "distanza letta", "answer": "B",
			"prompt": "Un sensore misura una parete ferma. Una sola lettura è un picco anomalo: quale punto andrebbe controllato?",
			"domande": [
				{"prompt": "Guardando il grafico, dove distanza letta tocca il valore più alto?", "answer": "B", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è B. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "Quale punto ha il valore di distanza letta più basso di tutti?", "answer": "D", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico distanza letta cresce verso l'alto, quindi il punto più basso è D."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.48, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.92, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.50, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.47, "label": "D"}],
			"explanation": "A, C e D sono vicini; B è molto distante dagli altri ed è probabilmente una lettura anomala."},
		{"topic": "efficienza", "minLevel": 20, "xLabel": "dati in ingresso", "yLabel": "operazioni", "answer": "D",
			"prompt": "Due cicli annidati fanno crescere rapidamente le operazioni. Quale punto mostra il costo maggiore?",
			"domande": [
				{"prompt": "Quale punto ha il valore di operazioni più basso di tutti?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico operazioni cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "Fra due punti vicini, dove operazioni cresce di più? Indica il punto in cui arriva.", "answer": "D", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in D."},
			],
			"points": [{"id": "A", "x": 0.14, "y": 0.16, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.28, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.55, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.94, "label": "D"}],
			"explanation": "Con due cicli annidati, più dati moltiplicano le operazioni: il costo massimo è nel punto D."},
	],
	# ITALIANO — "L'arco narrativo": la curva della tensione di un racconto, a forma
	# di montagna (esposizione A -> complicazione B -> climax C -> scioglimento D ->
	# finale E). Stessa curva, domande diverse: si legge la struttura di una storia.
	"italiano": [
		{"topic": "testo-narrativo", "xLabel": "tempo del racconto", "yLabel": "tensione", "answer": "C",
			"prompt": "La curva mostra la tensione di un racconto dall'inizio (A) alla fine (E). In quale punto c'è il climax, la massima suspense?",
			"domande": [
				{"prompt": "Sulla curva della tensione, in quale punto la storia è più calma?", "answer": "A", "explanation": "A è il punto più basso: l'inizio, prima che la tensione salga."},
			],
			"points": [{"id": "A", "x": 0.08, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.52, "label": "B"}, {"id": "C", "x": 0.52, "y": 0.94, "label": "C"}, {"id": "D", "x": 0.75, "y": 0.46, "label": "D"}, {"id": "E", "x": 0.93, "y": 0.16, "label": "E"}],
			"explanation": "Il climax è il punto più alto della tensione: C. Dopo, la storia si avvia allo scioglimento."},
		{"topic": "testo-narrativo", "xLabel": "tempo del racconto", "yLabel": "tensione", "answer": "A",
			"prompt": "In quale punto la storia presenta con calma personaggi e luogo, prima che arrivino i problemi (l'esposizione)?",
			"domande": [
				{"prompt": "Dopo l'esposizione la tensione comincia a crescere: quale punto è il primo a salire?", "answer": "B", "explanation": "B è il primo punto più alto di A: lì comincia la complicazione."},
			],
			"points": [{"id": "A", "x": 0.08, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.52, "label": "B"}, {"id": "C", "x": 0.52, "y": 0.94, "label": "C"}, {"id": "D", "x": 0.75, "y": 0.46, "label": "D"}, {"id": "E", "x": 0.93, "y": 0.16, "label": "E"}],
			"explanation": "L'esposizione è l'inizio calmo, con tensione bassa: il punto A."},
		{"topic": "testo-narrativo", "xLabel": "tempo del racconto", "yLabel": "tensione", "answer": "D",
			"prompt": "Superato il climax (C), la tensione cala e i nodi si sciolgono: quale punto è lo scioglimento?",
			"domande": [
				{"prompt": "Sulla curva del racconto, quale punto è il momento di massima tensione?", "answer": "C", "explanation": "C è il punto più alto della curva: il climax."},
			],
			"points": [{"id": "A", "x": 0.08, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.52, "label": "B"}, {"id": "C", "x": 0.52, "y": 0.94, "label": "C"}, {"id": "D", "x": 0.75, "y": 0.46, "label": "D"}, {"id": "E", "x": 0.93, "y": 0.16, "label": "E"}],
			"explanation": "Lo scioglimento è la discesa dopo il climax: il punto D, prima della situazione finale E."},
	],
	# LOGICA — riconoscimento di schemi: i punti salgono in linea, ma uno è fuori
	# posto. Trovare l'intruso è ragionamento visivo puro.
	"logica": [
		{"topic": "schemi", "minLevel": 4, "xLabel": "posizione", "yLabel": "valore", "answer": "D",
			"prompt": "Questi punti salgono a gradini regolari, ma uno resta indietro: quale rompe lo schema?",
			"domande": [
				{"prompt": "Se tutti i punti seguissero lo schema a gradini, quale sarebbe l'ULTIMO a rispettarlo?", "answer": "C", "explanation": "Lo schema regge fino a C; è da D in poi che il gradino non torna."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.50, "y": 0.60, "label": "C"}, {"id": "D", "x": 0.70, "y": 0.42, "label": "D"}, {"id": "E", "x": 0.90, "y": 0.98, "label": "E"}],
			"explanation": "Da A a C si sale di un gradino uguale ogni volta. D invece scende sotto C: è lui l'intruso, e la E riprende lo schema."},
		{"topic": "schemi", "minLevel": 4, "xLabel": "posizione", "yLabel": "valore", "answer": "C",
			"prompt": "Questi punti seguono uno schema che sale in linea, ma uno è fuori posto: quale rompe lo schema?",
			"domande": [
				{"prompt": "La linea sale in modo regolare tranne un punto: quale sarebbe al posto giusto se lo schema valesse per tutti?", "answer": "C", "explanation": "C è proprio il punto fuori linea: rimetterlo sulla retta è ciò che ripara lo schema."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.35, "label": "B"}, {"id": "C", "x": 0.50, "y": 0.90, "label": "C"}, {"id": "D", "x": 0.70, "y": 0.72, "label": "D"}, {"id": "E", "x": 0.90, "y": 0.92, "label": "E"}],
			"explanation": "Gli altri salgono in modo regolare; il punto C schizza troppo in alto: è l'intruso fuori schema."},
		{"topic": "schemi", "minLevel": 5, "xLabel": "posizione", "yLabel": "valore", "answer": "B",
			"prompt": "Questi punti scendono in modo regolare, ma uno è fuori posto: quale rompe lo schema?",
			"domande": [
				{"prompt": "Questi punti scendono a passo costante: quale punto rompe la discesa?", "answer": "B", "explanation": "B non rispetta il passo di discesa degli altri: è l'intruso."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.90, "label": "A"}, {"id": "B", "x": 0.34, "y": 0.22, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.52, "label": "C"}, {"id": "D", "x": 0.86, "y": 0.30, "label": "D"}],
			"explanation": "Gli altri scendono in modo regolare; il punto B crolla troppo in basso: è l'intruso fuori schema."},
	],
	# GEOGRAFIA — leggere climogrammi e profili altimetrici: competenza cartografica.
	"geografia": [
		# Il climogramma si legge su due grandezze, non una: c'era la temperatura,
		# mancava la pioggia.
		{"topic": "climi", "minLevel": 4, "xLabel": "mese", "yLabel": "pioggia", "answer": "A",
			"prompt": "Il diagramma mostra la pioggia caduta mese per mese: in quale punto (mese) ha piovuto di meno?",
			"domande": [
				{"prompt": "Nel diagramma delle piogge, in quale mese ha piovuto di PIÙ?", "answer": "C", "explanation": "C è la colonna più alta: il mese più piovoso."},
				{"prompt": "Fra il mese più secco e quello più piovoso, quale mese sta circa a metà?", "answer": "D", "explanation": "Il minimo è A e il massimo è C: D sta all'incirca a metà strada fra i due."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.12, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.62, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.88, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.45, "label": "D"}],
			"explanation": "Il mese più secco è quello con la colonna più bassa: il punto A. Il più piovoso è il C."},
		{"topic": "climi", "minLevel": 4, "xLabel": "mese", "yLabel": "temperatura", "answer": "C",
			"prompt": "Il climogramma mostra la temperatura mese per mese: in quale punto (mese) fa più caldo?",
			"domande": [
				{"prompt": "Nel climogramma, in quale mese fa più FREDDO?", "answer": "A", "explanation": "A è il punto più basso della curva delle temperature: il mese più freddo."},
				{"prompt": "Dopo il mese più caldo la temperatura scende: quale mese viene subito dopo il culmine?", "answer": "D", "explanation": "Il culmine è C; D lo segue ed è più basso: la temperatura ha già cominciato a calare."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.55, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.80, "y": 0.60, "label": "D"}],
			"explanation": "Il punto più in alto è il mese più caldo (l'estate): il punto C."},
		{"topic": "geografia-fisica", "minLevel": 5, "xLabel": "percorso", "yLabel": "altitudine", "answer": "C",
			"prompt": "Il profilo altimetrico mostra l'altitudine lungo un percorso: quale punto è la vetta più alta?",
			"domande": [
				{"prompt": "Nel profilo altimetrico, quale punto è il più BASSO del percorso?", "answer": "A", "explanation": "A è il punto più basso del profilo: il fondovalle di partenza."},
				{"prompt": "Sul profilo altimetrico, fra quali due punti consecutivi si sale di più?", "answer": "C", "explanation": "Da B a C il dislivello è il maggiore fra due punti vicini: è il tratto più ripido, e C ne è la cima."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.30, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.60, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.85, "y": 0.45, "label": "D"}],
			"explanation": "La vetta è il punto più in alto del profilo: il punto C."},
	],
	# STORIA — leggere un grafico storico: come cambia un dato nei secoli.
	"storia": [
		# Fra il mondo 5 e il 17 storia aveva UN solo grafico. Questi due lo
		# affiancano e coprono anche la seconda metà della campagna.
		{"topic": "cronologia", "minLevel": 5, "xLabel": "secoli", "yLabel": "chi sa leggere", "answer": "D",
			"prompt": "Il grafico mostra quante persone sapevano leggere in Europa nei secoli: in quale punto erano di più?",
			"domande": [
				{"prompt": "In quale punto chi sa leggere scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico chi sa leggere cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di chi sa leggere?", "answer": "D", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in D."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.12, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.28, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.52, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.94, "label": "D"}],
			"explanation": "La curva sale sempre e il punto più alto è l'ultimo, D: leggere e scrivere si è diffuso nel tempo, soprattutto dopo la stampa."},
		{"topic": "cronologia", "minLevel": 10, "xLabel": "anni", "yLabel": "persone in città", "answer": "B",
			"prompt": "Il grafico mostra quanta gente viveva in città. In quale punto la crescita è stata più RIPIDA (il salto più grande rispetto al punto prima)?",
			"domande": [
				{"prompt": "Guardando il grafico, dove persone in città tocca il valore più basso?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico persone in città cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "Dove persone in città fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.72, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.80, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.88, "label": "D"}],
			"explanation": "Non conta essere in alto, conta il salto: da A a B la curva sale di molto, poi si appiattisce. È la rivoluzione industriale."},
		{"topic": "cronologia", "minLevel": 5, "xLabel": "secoli", "yLabel": "abitanti", "answer": "C",
			"prompt": "Il grafico mostra gli abitanti di una città nei secoli: in quale punto la città era più popolosa?",
			"domande": [
				{"prompt": "Quale punto ha il valore di abitanti più alto di tutti?", "answer": "C", "explanation": "Il massimo è il punto più in ALTO del grafico: qui è C. La posizione orizzontale non conta, conta solo l'altezza."},
				{"prompt": "In quale punto abitanti scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico abitanti cresce verso l'alto, quindi il punto più basso è A."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.85, "y": 0.45, "label": "D"}],
			"explanation": "La città era più popolosa dove la curva è più in alto: il punto C. Poi la popolazione è calata."},
		{"topic": "roma", "minLevel": 18, "xLabel": "secoli", "yLabel": "estensione", "answer": "C",
			"prompt": "Il grafico mostra l'estensione dell'Impero Romano nei secoli: in quale punto era più vasto (al massimo)?",
			"domande": [
				{"prompt": "In quale punto estensione scende al minimo?", "answer": "A", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico estensione cresce verso l'alto, quindi il punto più basso è A."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di estensione?", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.25, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.60, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.85, "y": 0.35, "label": "D"}],
			"explanation": "L'Impero era più vasto al culmine (punto C); poi si ridusse fino alla caduta."},
	],
	# MUSICA — il contorno melodico: l'altezza delle note nel tempo. Leggere se il
	# suono sale o scende è una competenza musicale di base.
	"musica": [
		# Il contorno melodico c'era già; qui si legge la DURATA invece dell'altezza,
		# che è l'altro asse su cui si legge la musica.
		{"topic": "ritmo", "minLevel": 4, "xLabel": "tempo", "yLabel": "durata", "answer": "B",
			"prompt": "Il grafico mostra quanto dura ciascuna di quattro note: quale nota dura di più?",
			"domande": [
				{"prompt": "Guarda le durate delle quattro note: quale dura di MENO?", "answer": "D", "explanation": "D è il punto più basso: la nota più corta delle quattro."},
				{"prompt": "Fra le quattro note, quale dura circa la metà della più lunga?", "answer": "C", "explanation": "La più lunga è B; C sta a poco più della metà della sua altezza."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.35, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.88, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.52, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.22, "label": "D"}],
			"explanation": "La nota più lunga è quella che arriva più in alto: il punto B. La D è la più breve."},
		{"topic": "note", "minLevel": 4, "xLabel": "tempo", "yLabel": "altezza", "answer": "C",
			"prompt": "Il grafico è il contorno di una melodia (l'altezza delle note nel tempo): in quale punto la nota è più ACUTA (più alta)?",
			"domande": [
				{"prompt": "Nel contorno della melodia, in quale punto la nota è più GRAVE (più bassa)?", "answer": "A", "explanation": "A è il punto più basso del contorno: la nota più grave."},
				{"prompt": "La melodia sale fino al culmine e poi ricade: in quale punto comincia a scendere?", "answer": "D", "explanation": "Dopo il culmine in C, D è più basso: lì la melodia ha già cominciato a ricadere."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.30, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.40, "label": "D"}],
			"explanation": "La nota più acuta è dove la linea è più in alto: il punto C. Più in basso = più grave."},
		{"topic": "dinamica", "minLevel": 5, "xLabel": "tempo", "yLabel": "volume", "answer": "D",
			"prompt": "Il grafico mostra il volume in un diminuendo: in quale punto il suono è più DEBOLE?",
			"domande": [
				{"prompt": "Nel diminuendo, da quale punto parte il suono più FORTE?", "answer": "A", "explanation": "Un diminuendo parte forte e cala: A è il punto più alto, l'inizio."},
				{"prompt": "Nel diminuendo, quale punto ha ancora circa metà del volume iniziale?", "answer": "C", "explanation": "A vale il massimo; C sta a poco meno della metà di A: è il punto di mezzo del calo."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.65, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.40, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.12, "label": "D"}],
			"explanation": "Nel diminuendo il volume cala nel tempo: è più debole alla fine, dove la linea è più in basso, il punto D."},
	],
}

# CIRCUITO (schema + collegamenti disegnati proceduralmente): scegli il componente
# richiesto. `components` in coordinate 0..1, `connections` come coppie di id.
const CIRCUIT := {
	"elettronica": [
		{"topic": "componenti-base", "answer": "interruttore",
			"prompt": "Quale componente apre e chiude il passaggio della corrente?",
			"domande": [
				{"prompt": "Quale componente fornisce l'energia che fa muovere la corrente?", "answer": "pila", "explanation": "La pila è la sorgente: spinge la corrente lungo l'anello. Senza di lei nel circuito non si muove niente."},
				{"prompt": "Quale componente serve a limitare la corrente e proteggere il LED?", "answer": "resistore", "explanation": "Il resistore fa da freno: senza, il LED riceverebbe troppa corrente e si brucerebbe."},
			],
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.50, "y": 0.22, "label": "Interruttore"}, {"id": "resistore", "x": 0.80, "y": 0.50, "label": "Resistore"}, {"id": "led", "x": 0.50, "y": 0.78, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "resistore"], ["resistore", "led"], ["led", "pila"]],
			"explanation": "L'interruttore apre e chiude il circuito: accende o spegne il LED."},
		{"topic": "componenti-base", "answer": "led",
			"prompt": "Quale componente emette luce quando la corrente lo attraversa?",
			"domande": [
				{"prompt": "Quale elemento serve soltanto a collegare, senza trasformare niente?", "answer": "filo", "explanation": "Il filo è la strada: porta la corrente da un componente all'altro senza cambiarla."},
				{"prompt": "Quale componente è la sorgente di energia del circuito?", "answer": "pila", "explanation": "La pila mette in moto la corrente: è l'unico componente che fornisce energia invece di consumarla."},
			],
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "resistore", "x": 0.50, "y": 0.24, "label": "Resistore"}, {"id": "led", "x": 0.80, "y": 0.50, "label": "LED"}, {"id": "filo", "x": 0.50, "y": 0.78, "label": "Filo"}],
			"connections": [["pila", "resistore"], ["resistore", "led"], ["led", "filo"], ["filo", "pila"]],
			"explanation": "Il LED emette luce quando è attraversato dalla corrente."},
		{"topic": "sorgente", "answer": "pila",
			"prompt": "Quale componente fornisce l'energia a tutto il circuito?",
			"domande": [
				{"prompt": "Quale componente permette di accendere e spegnere senza staccare i fili?", "answer": "interruttore", "explanation": "L'interruttore apre e chiude la strada della corrente: aperto, il circuito è interrotto."},
				{"prompt": "Quale componente si accende quando la corrente lo attraversa?", "answer": "led", "explanation": "Il LED trasforma la corrente in luce. È l'unico dei quattro che si vede funzionare."},
			],
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.50, "y": 0.22, "label": "Interruttore"}, {"id": "resistore", "x": 0.80, "y": 0.50, "label": "Resistore"}, {"id": "led", "x": 0.50, "y": 0.78, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "resistore"], ["resistore", "led"], ["led", "pila"]],
			"explanation": "La pila è la sorgente: spinge la corrente in tutto il circuito."},
		{"topic": "protezione", "minLevel": 3, "answer": "resistore",
			"prompt": "Quale componente limita la corrente così il LED non si brucia?",
			"domande": [
				{"prompt": "Quale componente trasforma la corrente in luce?", "answer": "led", "explanation": "Il LED è il componente che emette luce: la resistenza lo protegge, la pila lo alimenta."},
				{"prompt": "Quale componente sarebbe inutile se togliessi tutti gli altri?", "answer": "pila", "explanation": "La pila è la sorgente: gli altri componenti esistono per usare l'energia che lei fornisce."},
			],
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "resistore", "x": 0.50, "y": 0.24, "label": "Resistore"}, {"id": "led", "x": 0.80, "y": 0.50, "label": "LED"}, {"id": "filo", "x": 0.50, "y": 0.78, "label": "Filo"}],
			"connections": [["pila", "resistore"], ["resistore", "led"], ["led", "filo"], ["filo", "pila"]],
			"explanation": "Il resistore limita la corrente: protegge il LED dal bruciarsi."},
		{"topic": "diodo", "minLevel": 12, "answer": "diodo",
			"prompt": "Quale componente lascia passare la corrente soprattutto in una sola direzione?",
			"domande": [
				{"prompt": "Quale componente si illumina scaldandosi al passaggio della corrente?", "answer": "lampada", "explanation": "La lampada emette luce perché il filamento si scalda: è diverso dal LED, che scalda pochissimo."},
				{"prompt": "Quale componente fornisce l'energia a questo circuito?", "answer": "pila", "explanation": "La pila è la sorgente: il diodo indirizza, la resistenza frena, la lampada consuma."},
			],
			"components": [{"id": "pila", "x": 0.18, "y": 0.50, "label": "Pila"}, {"id": "diodo", "x": 0.44, "y": 0.24, "label": "Diodo"}, {"id": "resistore", "x": 0.78, "y": 0.50, "label": "Resistore"}, {"id": "lampada", "x": 0.48, "y": 0.80, "label": "Lampada"}],
			"connections": [["pila", "diodo"], ["diodo", "resistore"], ["resistore", "lampada"], ["lampada", "pila"]],
			"explanation": "Il diodo è come una porta a senso unico: conduce in una direzione e ostacola quella opposta."},
		{"topic": "sensori", "minLevel": 23, "answer": "partitore",
			"prompt": "Un sensore resistivo cambia resistenza. Quale blocco lo trasforma in una tensione leggibile dal microcontrollore?",
			"domande": [
				{"prompt": "Quale elemento cambia il proprio comportamento quando cambia l'ambiente?", "answer": "sensore", "explanation": "Il sensore resistivo cambia resistenza al variare di luce, calore o umidità: è lui a «sentire»."},
				{"prompt": "Quale elemento fa da riferimento comune a cui tutto il circuito si appoggia?", "answer": "massa", "explanation": "La massa è il riferimento: tutte le tensioni si misurano rispetto a lei."},
			],
			"components": [{"id": "sensore", "x": 0.16, "y": 0.50, "label": "Sensore resistivo"}, {"id": "partitore", "x": 0.44, "y": 0.24, "label": "Partitore"}, {"id": "ingresso", "x": 0.78, "y": 0.50, "label": "Ingresso analogico"}, {"id": "massa", "x": 0.46, "y": 0.80, "label": "Massa"}],
			"connections": [["sensore", "partitore"], ["partitore", "ingresso"], ["partitore", "massa"]],
			"explanation": "Il partitore converte la variazione di resistenza in una tensione; l'ingresso analogico può così misurarla."},
		{"topic": "condensatore", "minLevel": 19, "answer": "condensatore",
			"prompt": "Quale componente può accumulare carica e restituirla per un breve intervallo?",
			"domande": [
				{"prompt": "Quale componente apre e chiude il passaggio in questo circuito?", "answer": "interruttore", "explanation": "L'interruttore comanda il passaggio: chiuso lascia scorrere la corrente, aperto la ferma."},
				{"prompt": "Quale componente mostra a occhio che la carica accumulata si sta scaricando?", "answer": "led", "explanation": "Il LED si accende e poi si spegne piano piano: è così che si vede il condensatore che si svuota."},
			],
			"components": [{"id": "pila", "x": 0.18, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.44, "y": 0.22, "label": "Interruttore"}, {"id": "condensatore", "x": 0.80, "y": 0.50, "label": "Condensatore"}, {"id": "led", "x": 0.48, "y": 0.80, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "condensatore"], ["condensatore", "led"], ["led", "pila"]],
			"explanation": "Il condensatore accumula separando cariche sulle sue armature e può poi scaricarsi nel circuito."},
	],
	# CODING — il renderer nodi+collegamenti diventa un DIAGRAMMA DI FLUSSO: si
	# legge il percorso di un programma e si sceglie il blocco richiesto. (Codex
	# potrà poi dare al blocco-decisione la forma a rombo tipica dei flowchart.)
	"coding": [
		{"topic": "sequenza", "answer": "secondo",
			"prompt": "Il programma deve prima leggere un nome, poi salutarlo. Quale blocco viene eseguito per secondo?",
			"domande": [
				{"prompt": "Quale blocco legge il nome, cioè viene per primo dopo l'avvio?", "answer": "primo", "explanation": "L'ordine conta: prima si legge il nome, poi lo si può salutare. Un programma esegue le istruzioni in fila."},
				{"prompt": "Quale blocco segna la fine dell'esecuzione?", "answer": "fine", "explanation": "Il blocco di fine chiude il programma: dopo di lui non viene eseguito più niente."},
			],
			"components": [{"id": "inizio", "x": 0.50, "y": 0.12, "label": "Inizio"}, {"id": "primo", "x": 0.50, "y": 0.36, "label": "Leggi nome"}, {"id": "secondo", "x": 0.50, "y": 0.62, "label": "Stampa saluto"}, {"id": "fine", "x": 0.50, "y": 0.88, "label": "Fine"}],
			"connections": [["inizio", "primo"], ["primo", "secondo"], ["secondo", "fine"]],
			"explanation": "Il flusso segue le frecce: dopo 'Leggi nome' viene 'Stampa saluto'."},
		{"topic": "condizioni", "answer": "vero",
			"prompt": "Se punti > 10 è vero, quale ramo stampa 'Hai vinto'?",
			"domande": [
				{"prompt": "Se punti > 10 è FALSO, quale ramo viene eseguito?", "answer": "falso", "explanation": "Ogni condizione ha due uscite: quando il test è falso si prende il ramo «Riprova»."},
				{"prompt": "Quale blocco pone la domanda che decide la strada?", "answer": "test", "explanation": "Il blocco di test è il bivio: confronta punti con 10 e manda su un ramo o sull'altro."},
			],
			"components": [{"id": "test", "x": 0.50, "y": 0.18, "label": "punti > 10?"}, {"id": "vero", "x": 0.24, "y": 0.58, "label": "Hai vinto"}, {"id": "falso", "x": 0.76, "y": 0.58, "label": "Riprova"}, {"id": "fine", "x": 0.50, "y": 0.88, "label": "Fine"}],
			"connections": [["test", "vero"], ["test", "falso"], ["vero", "fine"], ["falso", "fine"]],
			"explanation": "Quando la condizione è vera il flusso prende il ramo che porta a 'Hai vinto'."},
		{"topic": "sensori", "answer": "controllo",
			"prompt": "Il robot legge la distanza e deve fermarsi solo se trova un ostacolo vicino. Quale blocco decide se attivare l'arresto?",
			"domande": [
				{"prompt": "Quale blocco agisce sui motori quando l'ostacolo è vicino?", "answer": "ferma", "explanation": "Il blocco «Ferma motori» è l'azione: viene eseguito solo se il controllo ha dato esito vero."},
				{"prompt": "Quale blocco raccoglie il dato dal mondo esterno?", "answer": "sensore", "explanation": "Leggere la distanza è il primo passo: senza quel dato il controllo non avrebbe niente da confrontare."},
			],
			"components": [{"id": "sensore", "x": 0.50, "y": 0.12, "label": "Leggi distanza"}, {"id": "controllo", "x": 0.50, "y": 0.40, "label": "Distanza < 20?"}, {"id": "ferma", "x": 0.24, "y": 0.72, "label": "Ferma motori"}, {"id": "continua", "x": 0.76, "y": 0.72, "label": "Continua"}],
			"connections": [["sensore", "controllo"], ["controllo", "ferma"], ["controllo", "continua"]],
			"explanation": "Il blocco 'Distanza < 20?' confronta la lettura con la soglia e sceglie fra fermare i motori e continuare."},
		{"topic": "diagramma-flusso", "minLevel": 4, "answer": "decisione",
			"prompt": "Questo è il diagramma di flusso di un programma. Quale blocco DECIDE il percorso (la condizione)?",
			"domande": [
				{"prompt": "Quale blocco raccoglie il numero da esaminare?", "answer": "leggi", "explanation": "Prima si legge n, poi lo si può controllare: senza il dato la decisione non ha su cosa lavorare."},
				{"prompt": "Se n è divisibile per due, in quale blocco arriva il programma?", "answer": "pari", "explanation": "La decisione ha due uscite: quando la risposta è sì si prende il ramo «pari»."},
			],
			"components": [{"id": "inizio", "x": 0.50, "y": 0.10, "label": "Inizio"}, {"id": "leggi", "x": 0.50, "y": 0.30, "label": "Leggi n"}, {"id": "decisione", "x": 0.50, "y": 0.52, "label": "n pari?"}, {"id": "pari", "x": 0.24, "y": 0.75, "label": "pari"}, {"id": "dispari", "x": 0.76, "y": 0.75, "label": "dispari"}, {"id": "fine", "x": 0.50, "y": 0.92, "label": "Fine"}],
			"connections": [["inizio", "leggi"], ["leggi", "decisione"], ["decisione", "pari"], ["decisione", "dispari"], ["pari", "fine"], ["dispari", "fine"]],
			"explanation": "Il blocco 'n pari?' è la condizione: da lì il flusso si divide in due strade."},
		{"topic": "diagramma-flusso", "minLevel": 5, "answer": "controllo",
			"prompt": "In questo diagramma di flusso, quale blocco controlla quante volte si ripete il ciclo?",
			"domande": [
				{"prompt": "Quale blocco prepara il contatore prima che il ciclo cominci?", "answer": "init", "explanation": "Mettere i = 0 è l'inizializzazione: senza, il contatore non partirebbe da un valore noto."},
				{"prompt": "Quale blocco viene ripetuto a ogni giro del ciclo?", "answer": "corpo", "explanation": "Il corpo è la parte che si ripete: il controllo decide quante volte, il corpo dice cosa fare."},
			],
			"components": [{"id": "inizio", "x": 0.50, "y": 0.10, "label": "Inizio"}, {"id": "init", "x": 0.50, "y": 0.30, "label": "i = 0"}, {"id": "controllo", "x": 0.50, "y": 0.52, "label": "i < 3?"}, {"id": "corpo", "x": 0.24, "y": 0.72, "label": "stampa i"}, {"id": "fine", "x": 0.78, "y": 0.72, "label": "Fine"}],
			"connections": [["inizio", "init"], ["init", "controllo"], ["controllo", "corpo"], ["corpo", "controllo"], ["controllo", "fine"]],
			"explanation": "Il blocco 'i < 3?' è la condizione del ciclo: finché è vera si ripete 'stampa i'."},
		{"topic": "validazione", "minLevel": 12, "answer": "errore",
			"prompt": "Il programma accetta solo età da 0 a 120. Quale blocco gestisce un valore non valido?",
			"domande": [
				{"prompt": "Se l'età inserita è valida, in quale blocco arriva il programma?", "answer": "ok", "explanation": "Quando il test è vero il dato è accettabile e si passa al salvataggio."},
				{"prompt": "Quale blocco pone la condizione che divide i dati buoni da quelli sbagliati?", "answer": "test", "explanation": "Il test è il filtro: confronta l'età con l'intervallo ammesso e decide la strada."},
			],
			"components": [{"id": "leggi", "x": 0.50, "y": 0.12, "label": "Leggi età"}, {"id": "test", "x": 0.50, "y": 0.40, "label": "0 ≤ età ≤ 120?"}, {"id": "ok", "x": 0.24, "y": 0.72, "label": "Salva"}, {"id": "errore", "x": 0.76, "y": 0.72, "label": "Segnala errore"}],
			"connections": [["leggi", "test"], ["test", "ok"], ["test", "errore"]],
			"explanation": "Se l'età è fuori dall'intervallo, la condizione è falsa e il flusso va a 'Segnala errore'."},
		{"topic": "funzioni", "minLevel": 18, "answer": "ritorno",
			"prompt": "La funzione calcola un valore e il programma chiamante deve riceverlo. Quale blocco rimanda il risultato al chiamante?",
			"domande": [
				{"prompt": "Quale blocco riceve i valori su cui la funzione deve lavorare?", "answer": "parametri", "explanation": "I parametri sono i dati in ingresso: la funzione li legge prima di calcolare."},
				{"prompt": "Quale blocco fa il lavoro vero e proprio della funzione?", "answer": "calcolo", "explanation": "Il calcolo è il cuore della funzione: prende i parametri e produce il valore che verrà restituito."},
			],
			"components": [{"id": "chiamata", "x": 0.16, "y": 0.50, "label": "Chiama funzione"}, {"id": "parametri", "x": 0.42, "y": 0.24, "label": "Leggi parametri"}, {"id": "calcolo", "x": 0.68, "y": 0.50, "label": "Calcola"}, {"id": "ritorno", "x": 0.46, "y": 0.80, "label": "Restituisci valore"}],
			"connections": [["chiamata", "parametri"], ["parametri", "calcolo"], ["calcolo", "ritorno"], ["ritorno", "chiamata"]],
			"explanation": "Il blocco di ritorno consegna il risultato al punto che ha chiamato la funzione; senza, il valore resta locale."},
		{"topic": "cicli-annidati", "minLevel": 23, "answer": "interno",
			"prompt": "Per ogni riga di una griglia il programma visita tutte le colonne. Quale blocco si ripete più spesso?",
			"domande": [
				{"prompt": "Quale ciclo si ripete più volte per ogni singolo giro dell'altro?", "answer": "colonne", "explanation": "Il ciclo delle colonne sta dentro quello delle righe: per ogni riga percorre tutte le colonne."},
				{"prompt": "Quale ciclo scorre le righe della griglia?", "answer": "righe", "explanation": "Il ciclo esterno è quello delle righe: ne prende una alla volta e passa il lavoro a quello interno."},
			],
			"components": [{"id": "righe", "x": 0.50, "y": 0.12, "label": "Per ogni riga"}, {"id": "colonne", "x": 0.50, "y": 0.38, "label": "Per ogni colonna"}, {"id": "interno", "x": 0.50, "y": 0.66, "label": "Visita cella"}, {"id": "fine", "x": 0.82, "y": 0.88, "label": "Fine"}],
			"connections": [["righe", "colonne"], ["colonne", "interno"], ["interno", "colonne"], ["colonne", "righe"], ["righe", "fine"]],
			"explanation": "'Visita cella' sta nel ciclo interno: viene eseguito per ogni colonna di ogni riga, quindi più spesso."},
	],
	# SCIENZE — il renderer nodi+collegamenti diventa una CATENA ALIMENTARE: si
	# legge il flusso di energia e si sceglie l'organismo richiesto.
	"scienze": [
		{"topic": "ciclo-acqua", "answer": "condensazione",
			"prompt": "Nel ciclo dell'acqua, quale passaggio trasforma il vapore in piccole gocce che formano le nuvole?",
			"domande": [
				{"prompt": "Nel ciclo dell'acqua, quale passaggio trasforma l'acqua liquida in vapore?", "answer": "evaporazione", "explanation": "Il calore del sole fa evaporare l'acqua: da liquida diventa vapore e sale."},
				{"prompt": "Quale passaggio riporta l'acqua a terra?", "answer": "pioggia", "explanation": "Quando le goccioline diventano abbastanza pesanti cadono: è la pioggia che chiude il ciclo."},
			],
			"components": [{"id": "mare", "x": 0.18, "y": 0.82, "label": "Acqua liquida"}, {"id": "evaporazione", "x": 0.28, "y": 0.38, "label": "Evaporazione"}, {"id": "condensazione", "x": 0.64, "y": 0.18, "label": "Condensazione"}, {"id": "pioggia", "x": 0.82, "y": 0.62, "label": "Pioggia"}],
			"connections": [["mare", "evaporazione"], ["evaporazione", "condensazione"], ["condensazione", "pioggia"], ["pioggia", "mare"]],
			"explanation": "Raffreddandosi, il vapore condensa in goccioline: insieme formano le nuvole."},
		{"topic": "ciclo-vita", "answer": "adulto",
			"prompt": "Nel ciclo della farfalla, quale stadio depone nuove uova e fa ripartire il ciclo?",
			"domande": [
				{"prompt": "Nel ciclo della farfalla, quale stadio esce dall'uovo e mangia in continuazione?", "answer": "larva", "explanation": "Il bruco è lo stadio di crescita: mangia moltissimo per accumulare le riserve della trasformazione."},
				{"prompt": "In quale stadio l'animale sembra fermo ma dentro si sta trasformando?", "answer": "crisalide", "explanation": "Nella crisalide non si vede movimento, ma è lì che il bruco diventa farfalla."},
			],
			"components": [{"id": "uovo", "x": 0.18, "y": 0.30, "label": "Uovo"}, {"id": "larva", "x": 0.42, "y": 0.72, "label": "Bruco"}, {"id": "crisalide", "x": 0.70, "y": 0.72, "label": "Crisalide"}, {"id": "adulto", "x": 0.82, "y": 0.28, "label": "Farfalla adulta"}],
			"connections": [["uovo", "larva"], ["larva", "crisalide"], ["crisalide", "adulto"], ["adulto", "uovo"]],
			"explanation": "La farfalla adulta si riproduce e depone le uova: così il ciclo ricomincia."},
		{"topic": "catena", "minLevel": 4, "answer": "erba",
			"prompt": "In questa catena alimentare l'energia sale da un anello all'altro. Quale organismo è il PRODUTTORE, alla base di tutto?",
			"domande": [
				{"prompt": "In questa catena, quale animale mangia direttamente l'erba?", "answer": "cavalletta", "explanation": "La cavalletta è il primo consumatore: si nutre del produttore, cioè della pianta."},
				{"prompt": "Quale animale mangia la rana ed è a sua volta mangiato?", "answer": "serpente", "explanation": "Il serpente sta in mezzo: è predatore della rana e preda dell'aquila."},
			],
			"components": [{"id": "erba", "x": 0.12, "y": 0.82, "label": "Erba"}, {"id": "cavalletta", "x": 0.32, "y": 0.62, "label": "Cavalletta"}, {"id": "rana", "x": 0.52, "y": 0.44, "label": "Rana"}, {"id": "serpente", "x": 0.72, "y": 0.30, "label": "Serpente"}, {"id": "aquila", "x": 0.90, "y": 0.14, "label": "Aquila"}],
			"connections": [["erba", "cavalletta"], ["cavalletta", "rana"], ["rana", "serpente"], ["serpente", "aquila"]],
			"explanation": "L'erba è il produttore: crea energia con la fotosintesi e tutti gli altri dipendono da lei."},
		{"topic": "catena", "minLevel": 5, "answer": "aquila",
			"prompt": "In questa catena alimentare, quale organismo è il predatore al vertice, che nessuno mangia?",
			"domande": [
				{"prompt": "In questa catena, quale organismo produce da sé il proprio nutrimento?", "answer": "erba", "explanation": "L'erba è il produttore: usa la luce del sole e non mangia nessuno."},
				{"prompt": "Quale animale mangia la cavalletta?", "answer": "rana", "explanation": "La rana è il secondo consumatore: mangia la cavalletta, che a sua volta ha mangiato l'erba."},
			],
			"components": [{"id": "erba", "x": 0.12, "y": 0.82, "label": "Erba"}, {"id": "cavalletta", "x": 0.32, "y": 0.62, "label": "Cavalletta"}, {"id": "rana", "x": 0.52, "y": 0.44, "label": "Rana"}, {"id": "serpente", "x": 0.72, "y": 0.30, "label": "Serpente"}, {"id": "aquila", "x": 0.90, "y": 0.14, "label": "Aquila"}],
			"connections": [["erba", "cavalletta"], ["cavalletta", "rana"], ["rana", "serpente"], ["serpente", "aquila"]],
			"explanation": "L'aquila è il predatore all'apice: in questa catena nessuno la caccia."},
		{"topic": "ciclo-carbonio", "minLevel": 12, "answer": "pianta",
			"prompt": "Quale elemento del ciclo assorbe anidride carbonica dall'aria tramite fotosintesi?",
			"domande": [
				{"prompt": "Quale elemento del ciclo restituisce carbonio al terreno smontando ciò che resta?", "answer": "decompositori", "explanation": "I decompositori chiudono il ciclo: smontano resti e materia morta e liberano il carbonio."},
				{"prompt": "Dove si trova il carbonio prima che la pianta lo catturi?", "answer": "atmosfera", "explanation": "Il carbonio è nell'aria sotto forma di anidride carbonica: la pianta lo prende da lì."},
			],
			"components": [{"id": "atmosfera", "x": 0.50, "y": 0.12, "label": "CO₂ nell'aria"}, {"id": "pianta", "x": 0.20, "y": 0.52, "label": "Pianta"}, {"id": "animale", "x": 0.50, "y": 0.84, "label": "Animale"}, {"id": "decompositori", "x": 0.82, "y": 0.52, "label": "Decompositori"}],
			"connections": [["atmosfera", "pianta"], ["pianta", "animale"], ["animale", "decompositori"], ["decompositori", "atmosfera"]],
			"explanation": "Le piante assorbono CO₂ dall'aria e usano il carbonio per costruire sostanze organiche."},
		{"topic": "fotosintesi", "minLevel": 23, "answer": "glucosio",
			"prompt": "Segui lo schema della fotosintesi: quale prodotto conserva l'energia della luce in forma chimica?",
			"domande": [
				{"prompt": "Nella fotosintesi, quale sostanza viene liberata nell'aria come prodotto di scarto?", "answer": "ossigeno", "explanation": "L'ossigeno è ciò che la pianta rilascia: per noi è essenziale, per lei è un residuo."},
				{"prompt": "Che cosa fornisce l'energia che fa partire la fotosintesi?", "answer": "luce", "explanation": "Senza luce la fotosintesi non parte: è l'energia che permette di costruire il glucosio."},
			],
			"components": [{"id": "luce", "x": 0.14, "y": 0.24, "label": "Luce"}, {"id": "acqua", "x": 0.14, "y": 0.76, "label": "Acqua"}, {"id": "co2", "x": 0.42, "y": 0.76, "label": "CO₂"}, {"id": "foglia", "x": 0.50, "y": 0.34, "label": "Foglia"}, {"id": "glucosio", "x": 0.84, "y": 0.28, "label": "Glucosio"}, {"id": "ossigeno", "x": 0.84, "y": 0.72, "label": "Ossigeno"}],
			"connections": [["luce", "foglia"], ["acqua", "foglia"], ["co2", "foglia"], ["foglia", "glucosio"], ["foglia", "ossigeno"]],
			"explanation": "La foglia usa luce, acqua e CO₂ per produrre glucosio, dove l'energia resta immagazzinata nei legami chimici; libera anche ossigeno."},
		{"topic": "rete-alimentare", "minLevel": 19, "answer": "volpe",
			"prompt": "Nella rete, quale predatore riceve energia sia dal coniglio sia dal topo?",
			"domande": [
				{"prompt": "Nella rete, quale organismo sta alla base e nutre gli altri?", "answer": "erba", "explanation": "L'erba è il produttore: tutta l'energia della rete comincia da lì."},
				{"prompt": "Quale animale si nutre dei semi?", "answer": "topo", "explanation": "Il topo mangia i semi: è un consumatore, e a sua volta è preda della volpe."},
			],
			"components": [{"id": "erba", "x": 0.15, "y": 0.75, "label": "Erba"}, {"id": "semi", "x": 0.15, "y": 0.28, "label": "Semi"}, {"id": "coniglio", "x": 0.48, "y": 0.72, "label": "Coniglio"}, {"id": "topo", "x": 0.48, "y": 0.30, "label": "Topo"}, {"id": "volpe", "x": 0.82, "y": 0.52, "label": "Volpe"}],
			"connections": [["erba", "coniglio"], ["semi", "topo"], ["coniglio", "volpe"], ["topo", "volpe"]],
			"explanation": "Entrambe le frecce da coniglio e topo arrivano alla volpe: può nutrirsi di entrambe le prede."},
	],
	# FISICA — il renderer nodi+collegamenti diventa la CATENA DI TRASFORMAZIONI
	# dell'energia: si segue come l'energia cambia forma e si sceglie quella giusta.
	"fisica": [
		{"topic": "correnti", "minLevel": 13, "answer": "deriva",
			"prompt": "La barca punta dritta verso l'altra riva mentre il fiume scorre di lato. Quale passaggio mostra dove arriva davvero?",
			"domande": [
				{"prompt": "Quale passaggio è la spinta che la barca si dà da sola?", "answer": "remata", "explanation": "La remata è l'unica spinta che decide la barca: punta dove vuole andare."},
				{"prompt": "Quale passaggio è la spinta che la barca non decide?", "answer": "fiume", "explanation": "La corrente del fiume spinge di lato comunque, che tu remi o no: è la parte del movimento che non hai scelto."},
			],
			"components": [{"id": "remata", "x": 0.18, "y": 0.50, "label": "Remata verso la riva"}, {"id": "fiume", "x": 0.48, "y": 0.24, "label": "Corrente del fiume"}, {"id": "deriva", "x": 0.80, "y": 0.50, "label": "Punto d'arrivo spostato"}],
			"connections": [["remata", "fiume"], ["fiume", "deriva"]],
			"explanation": "I due movimenti si sommano: quello che decidi tu e quello che decide l'acqua. Il punto d'arrivo è più a valle di quello a cui puntavi."},
		{"topic": "forze", "answer": "movimento",
			"prompt": "Una mano spinge una scatola ferma. Quale passaggio mostra l'effetto della forza?",
			"domande": [
				{"prompt": "Che cosa rallenta la scatola mentre si muove?", "answer": "attrito", "explanation": "L'attrito è la forza che si oppone al movimento: agisce fra scatola e pavimento."},
				{"prompt": "Quale passaggio rappresenta la forza applicata dalla mano?", "answer": "spinta", "explanation": "La spinta è la forza: è la causa, il movimento è l'effetto."},
			],
			"components": [{"id": "ferma", "x": 0.18, "y": 0.50, "label": "Scatola ferma"}, {"id": "spinta", "x": 0.48, "y": 0.26, "label": "Spinta"}, {"id": "movimento", "x": 0.80, "y": 0.50, "label": "Scatola accelera"}, {"id": "attrito", "x": 0.48, "y": 0.80, "label": "Attrito"}],
			"connections": [["ferma", "spinta"], ["spinta", "movimento"], ["movimento", "attrito"]],
			"explanation": "Una forza non bilanciata cambia il moto: la spinta fa accelerare la scatola."},
		{"topic": "suono", "answer": "vibrazione",
			"prompt": "In una chitarra, quale elemento avvia il suono prima che arrivi all'orecchio?",
			"domande": [
				{"prompt": "Che cosa porta il suono dalla corda fino all'orecchio?", "answer": "aria", "explanation": "L'aria trasmette la vibrazione: senza un mezzo, il suono non viaggia."},
				{"prompt": "Dove arriva il suono alla fine del percorso?", "answer": "orecchio", "explanation": "L'orecchio è il punto d'arrivo: riceve la vibrazione dell'aria e la trasforma in sensazione."},
			],
			"components": [{"id": "dito", "x": 0.12, "y": 0.50, "label": "Pizzico"}, {"id": "vibrazione", "x": 0.38, "y": 0.30, "label": "Corda vibra"}, {"id": "aria", "x": 0.64, "y": 0.52, "label": "Aria vibra"}, {"id": "orecchio", "x": 0.90, "y": 0.32, "label": "Orecchio"}],
			"connections": [["dito", "vibrazione"], ["vibrazione", "aria"], ["aria", "orecchio"]],
			"explanation": "Il pizzico mette in vibrazione la corda; la vibrazione passa all'aria e poi all'orecchio."},
		{"topic": "energia", "minLevel": 5, "answer": "potenziale",
			"prompt": "Una pallina viene sollevata, cade e rimbalza. Quando è ferma in alto, prima di cadere, che energia possiede?",
			"domande": [
				{"prompt": "In quale fase la pallina deforma il suolo e accumula energia elastica?", "answer": "elastica", "explanation": "Nel momento del contatto l'energia si accumula nella deformazione: è energia elastica."},
				{"prompt": "In quale fase la pallina risale dopo il rimbalzo?", "answer": "risalita", "explanation": "Nella risalita l'energia elastica torna movimento e poi altezza."},
			],
			"components": [{"id": "potenziale", "x": 0.18, "y": 0.18, "label": "Ferma in alto"}, {"id": "cinetica", "x": 0.50, "y": 0.72, "label": "Sta cadendo"}, {"id": "elastica", "x": 0.82, "y": 0.88, "label": "Tocca il suolo"}, {"id": "risalita", "x": 0.86, "y": 0.34, "label": "Risale"}],
			"connections": [["potenziale", "cinetica"], ["cinetica", "elastica"], ["elastica", "risalita"]],
			"explanation": "Ferma in alto la pallina ha energia potenziale (di posizione); cadendo diventa cinetica."},
		{"topic": "energia", "minLevel": 6, "answer": "cinetica",
			"prompt": "Segui la trasformazione dell'energia della pallina: in quale fase l'energia è tutta cinetica (di movimento)?",
			"domande": [
				{"prompt": "In quale fase l'energia è tutta dovuta all'altezza, senza movimento?", "answer": "potenziale", "explanation": "Ferma in alto la pallina non si muove: tutta la sua energia dipende da quanto è in alto."},
				{"prompt": "In quale fase l'energia elastica si trasforma di nuovo in movimento?", "answer": "risalita", "explanation": "Nel rimbalzo la deformazione si ricompone e rilancia la pallina verso l'alto."},
			],
			"components": [{"id": "potenziale", "x": 0.18, "y": 0.18, "label": "Ferma in alto"}, {"id": "cinetica", "x": 0.50, "y": 0.72, "label": "Sta cadendo"}, {"id": "elastica", "x": 0.82, "y": 0.88, "label": "Tocca il suolo"}, {"id": "risalita", "x": 0.86, "y": 0.34, "label": "Risale"}],
			"connections": [["potenziale", "cinetica"], ["cinetica", "elastica"], ["elastica", "risalita"]],
			"explanation": "Mentre cade, l'energia potenziale si è trasformata tutta in cinetica: è il momento più veloce."},
		{"topic": "leve", "minLevel": 12, "answer": "fulcro",
			"prompt": "In una leva, quale punto resta fermo e permette all'asta di ruotare?",
			"domande": [
				{"prompt": "In una leva, dove si trova il peso da sollevare?", "answer": "carico", "explanation": "Il carico è ciò che si vuole spostare: sta da una parte del fulcro."},
				{"prompt": "In una leva, dove si applica lo sforzo di chi la usa?", "answer": "forza", "explanation": "La forza è dove si spinge o si tira: più è lontana dal fulcro, meno se ne serve."},
			],
			"components": [{"id": "forza", "x": 0.15, "y": 0.40, "label": "Forza"}, {"id": "fulcro", "x": 0.50, "y": 0.72, "label": "Fulcro"}, {"id": "carico", "x": 0.85, "y": 0.40, "label": "Carico"}, {"id": "asta", "x": 0.50, "y": 0.30, "label": "Asta"}],
			"connections": [["forza", "asta"], ["asta", "fulcro"], ["asta", "carico"]],
			"explanation": "Il fulcro è il punto di appoggio attorno al quale l'asta ruota."},
		{"topic": "elettricita", "minLevel": 23, "answer": "magnetico",
			"prompt": "In un motore elettrico, quale passaggio trasforma la corrente in una forza che mette in rotazione l'asse?",
			"domande": [
				{"prompt": "In un motore elettrico, quale elemento diventa un magnete quando lo attraversa la corrente?", "answer": "bobina", "explanation": "La bobina è filo avvolto: percorsa dalla corrente si comporta come un magnete."},
				{"prompt": "Qual è il risultato finale della catena, ciò che il motore produce?", "answer": "rotazione", "explanation": "La rotazione è l'effetto utile: è per questo che il motore esiste."},
			],
			"components": [{"id": "corrente", "x": 0.14, "y": 0.50, "label": "Corrente"}, {"id": "bobina", "x": 0.40, "y": 0.24, "label": "Bobina"}, {"id": "magnetico", "x": 0.66, "y": 0.50, "label": "Forza magnetica"}, {"id": "rotazione", "x": 0.88, "y": 0.28, "label": "Rotazione"}],
			"connections": [["corrente", "bobina"], ["bobina", "magnetico"], ["magnetico", "rotazione"]],
			"explanation": "La corrente nella bobina interagisce con il campo magnetico: nasce una forza che fa ruotare l'asse."},
		{"topic": "energia", "minLevel": 19, "answer": "calore",
			"prompt": "Una bicicletta frena: dove finisce gran parte dell'energia di movimento?",
			"domande": [
				{"prompt": "Che cosa rallenta la bicicletta quando si frena?", "answer": "attrito", "explanation": "I freni sfregano sul cerchione: l'attrito è ciò che toglie movimento."},
				{"prompt": "Da quale forma di energia si parte prima di frenare?", "answer": "cinetica", "explanation": "La bicicletta in corsa ha energia di movimento: è quella che i freni trasformano."},
			],
			"components": [{"id": "cinetica", "x": 0.16, "y": 0.50, "label": "Movimento"}, {"id": "attrito", "x": 0.46, "y": 0.28, "label": "Freni: attrito"}, {"id": "calore", "x": 0.78, "y": 0.50, "label": "Calore"}, {"id": "suono", "x": 0.48, "y": 0.78, "label": "Suono"}],
			"connections": [["cinetica", "attrito"], ["attrito", "calore"], ["attrito", "suono"]],
			"explanation": "L'attrito dei freni trasforma soprattutto l'energia cinetica in calore; una piccola parte diventa suono."},
	],
	"matematica": [
		{"topic": "operazioni", "answer": "risultato",
			"prompt": "La macchina prende 4, aggiunge 3 e poi raddoppia. Quale nodo contiene il risultato finale?",
			"domande": [
				{"prompt": "In questa macchina di calcolo, quale nodo aggiunge 3?", "answer": "somma", "explanation": "L'ordine conta: prima si aggiunge 3 a 4 ottenendo 7, e solo dopo si raddoppia."},
				{"prompt": "Quale nodo raddoppia il numero?", "answer": "doppio", "explanation": "Il raddoppio arriva per secondo: si applica al risultato della somma, non al numero di partenza."},
			],
			"components": [{"id": "inizio", "x": 0.12, "y": 0.50, "label": "4"}, {"id": "somma", "x": 0.38, "y": 0.30, "label": "+ 3"}, {"id": "doppio", "x": 0.64, "y": 0.50, "label": "× 2"}, {"id": "risultato", "x": 0.90, "y": 0.30, "label": "14"}],
			"connections": [["inizio", "somma"], ["somma", "doppio"], ["doppio", "risultato"]],
			"explanation": "Seguendo le frecce: 4 + 3 = 7, poi 7 × 2 = 14. Il nodo finale è 14."},
		{"topic": "problemi", "answer": "totale",
			"prompt": "Tre sacchetti contengono 5 biglie ciascuno. Quale nodo rappresenta il totale?",
			"domande": [
				{"prompt": "Quale nodo dice quante biglie ci sono in ogni sacchetto?", "answer": "pergruppo", "explanation": "«5 per sacchetto» è la quantità di un gruppo: moltiplicata per il numero di gruppi dà il totale."},
				{"prompt": "Quale nodo dice quanti sacchetti ci sono?", "answer": "gruppi", "explanation": "Tre sacchetti è il numero di gruppi: è uno dei due fattori della moltiplicazione."},
			],
			"components": [{"id": "gruppi", "x": 0.18, "y": 0.28, "label": "3 sacchetti"}, {"id": "pergruppo", "x": 0.18, "y": 0.72, "label": "5 per sacchetto"}, {"id": "moltiplica", "x": 0.52, "y": 0.50, "label": "3 × 5"}, {"id": "totale", "x": 0.84, "y": 0.50, "label": "15 biglie"}],
			"connections": [["gruppi", "moltiplica"], ["pergruppo", "moltiplica"], ["moltiplica", "totale"]],
			"explanation": "Tre gruppi uguali da cinque si calcolano con 3 × 5: il totale è 15."},
		{"topic": "frazioni", "minLevel": 7, "answer": "equivalente",
			"prompt": "Quale nodo mostra una frazione equivalente a 1/2?",
			"domande": [
				{"prompt": "Quale nodo mostra una frazione che NON è equivalente a 1/2?", "answer": "non_equiv", "explanation": "In 2/3 il sopra e il sotto non sono stati moltiplicati per lo stesso numero: vale più di un mezzo."},
				{"prompt": "Quale nodo mostra l'operazione che crea una frazione equivalente?", "answer": "doppio", "explanation": "Moltiplicare sopra e sotto per lo stesso numero non cambia il valore: è la regola delle frazioni equivalenti."},
			],
			"components": [{"id": "partenza", "x": 0.18, "y": 0.50, "label": "1/2"}, {"id": "doppio", "x": 0.48, "y": 0.24, "label": "×2 sopra e sotto"}, {"id": "equivalente", "x": 0.82, "y": 0.28, "label": "2/4"}, {"id": "non_equiv", "x": 0.82, "y": 0.74, "label": "2/3"}],
			"connections": [["partenza", "doppio"], ["doppio", "equivalente"], ["partenza", "non_equiv"]],
			"explanation": "Moltiplicare numeratore e denominatore per lo stesso numero non cambia il valore: 1/2 = 2/4."},
		{"topic": "geometria", "minLevel": 11, "answer": "area",
			"prompt": "Per un rettangolo, quale nodo usa base e altezza per misurare la superficie interna?",
			"domande": [
				{"prompt": "Per un rettangolo, quale nodo misura il contorno invece della superficie?", "answer": "perimetro", "explanation": "Il perimetro è la lunghezza del bordo: si sommano i lati, non si moltiplicano."},
				{"prompt": "Quale nodo indica il lato che appoggia sotto la figura?", "answer": "base", "explanation": "La base è uno dei due lati che servono per l'area: l'altro è l'altezza."},
			],
			"components": [{"id": "base", "x": 0.16, "y": 0.28, "label": "Base"}, {"id": "altezza", "x": 0.16, "y": 0.72, "label": "Altezza"}, {"id": "area", "x": 0.54, "y": 0.32, "label": "Area = b × h"}, {"id": "perimetro", "x": 0.82, "y": 0.70, "label": "Perimetro = 2(b+h)"}],
			"connections": [["base", "area"], ["altezza", "area"], ["base", "perimetro"], ["altezza", "perimetro"]],
			"explanation": "L'area misura la superficie e si ottiene moltiplicando base per altezza; il perimetro misura il contorno."},
		{"topic": "probabilita", "minLevel": 17, "answer": "due_test",
			"prompt": "Lanciando due monete, quale esito contiene due teste?",
			"domande": [
				{"prompt": "Lanciando due monete, quale esito contiene due croci?", "answer": "due_croci", "explanation": "CC significa croce su entrambe le monete: è uno dei quattro esiti possibili."},
				{"prompt": "Quale esito ha una testa e una croce?", "answer": "misto", "explanation": "TC è l'esito misto: capita più spesso degli altri, perché può uscire in due modi."},
			],
			"components": [{"id": "lancio1", "x": 0.50, "y": 0.10, "label": "Prima moneta"}, {"id": "testa1", "x": 0.26, "y": 0.38, "label": "T"}, {"id": "croce1", "x": 0.74, "y": 0.38, "label": "C"}, {"id": "due_test", "x": 0.12, "y": 0.78, "label": "TT"}, {"id": "misto", "x": 0.42, "y": 0.78, "label": "TC"}, {"id": "due_croci", "x": 0.88, "y": 0.78, "label": "CC"}],
			"connections": [["lancio1", "testa1"], ["lancio1", "croce1"], ["testa1", "due_test"], ["testa1", "misto"], ["croce1", "misto"], ["croce1", "due_croci"]],
			"explanation": "TT indica testa al primo lancio e testa al secondo: è l'esito con due teste."},
		{"topic": "funzioni", "minLevel": 20, "answer": "uscita",
			"prompt": "La funzione prima triplica x e poi sottrae 1. Con x = 4, quale nodo mostra l'uscita?",
			"domande": [
				{"prompt": "Con x = 4, quale nodo mostra il risultato dopo aver triplicato?", "answer": "triplica", "explanation": "Prima si triplica: 3 × 4 fa 12. La sottrazione viene dopo."},
				{"prompt": "Quale nodo contiene il valore di partenza?", "answer": "input", "explanation": "x = 4 è l'ingresso: è il numero su cui la funzione lavora."},
			],
			"components": [{"id": "input", "x": 0.12, "y": 0.50, "label": "x = 4"}, {"id": "triplica", "x": 0.38, "y": 0.28, "label": "3x = 12"}, {"id": "sottrai", "x": 0.64, "y": 0.50, "label": "12 − 1"}, {"id": "uscita", "x": 0.90, "y": 0.28, "label": "11"}],
			"connections": [["input", "triplica"], ["triplica", "sottrai"], ["sottrai", "uscita"]],
			"explanation": "Seguendo la composizione: 4 × 3 = 12 e 12 − 1 = 11. L'uscita è 11."},
	],
	# LOGICA — il renderer nodi+collegamenti diventa un ALBERO DELLE DECISIONI: si
	# seguono le risposte sì/no fino alla conclusione giusta.
	"logica": [
		{"topic": "insiemi", "minLevel": 5, "answer": "animali",
			"prompt": "Questi gruppi stanno uno dentro l'altro. Qual è il gruppo che contiene tutti gli altri?",
			"domande": [
				{"prompt": "Fra questi gruppi, qual è il più piccolo, quello contenuto in tutti gli altri?", "answer": "cani", "explanation": "I cani stanno dentro i mammiferi, che stanno dentro i vertebrati, che stanno dentro gli animali."},
				{"prompt": "Quale gruppo contiene i cani ma è contenuto nei vertebrati?", "answer": "mammiferi", "explanation": "I mammiferi sono un sottoinsieme dei vertebrati e contengono i cani: sta nel mezzo della scala."},
			],
			"components": [{"id": "animali", "x": 0.50, "y": 0.14, "label": "Animali"}, {"id": "vertebrati", "x": 0.50, "y": 0.40, "label": "Vertebrati"}, {"id": "mammiferi", "x": 0.50, "y": 0.66, "label": "Mammiferi"}, {"id": "cani", "x": 0.50, "y": 0.90, "label": "Cani"}],
			"connections": [["animali", "vertebrati"], ["vertebrati", "mammiferi"], ["mammiferi", "cani"]],
			"explanation": "Ogni cane è un mammifero, ogni mammifero un vertebrato, ogni vertebrato un animale. Il gruppo più grande è quello in cima: gli animali."},
		{"topic": "albero-decisioni", "minLevel": 5, "answer": "uccello",
			"prompt": "Segui l'albero: un animale HA le ali. A quale conclusione arrivi?",
			"domande": [
				{"prompt": "Segui l'albero: un animale NON ha le ali ma ha le pinne. A quale conclusione arrivi?", "answer": "pesce", "explanation": "Niente ali, sì pinne: il ramo porta al pesce."},
				{"prompt": "Segui l'albero: un animale non ha né ali né pinne. Dove arrivi?", "answer": "mammifero", "explanation": "Quando entrambe le domande danno no, resta l'ultima conclusione dell'albero."},
			],
			"components": [{"id": "ali", "x": 0.50, "y": 0.12, "label": "Ha le ali?"}, {"id": "uccello", "x": 0.22, "y": 0.52, "label": "Uccello"}, {"id": "pinne", "x": 0.72, "y": 0.44, "label": "Ha le pinne?"}, {"id": "pesce", "x": 0.55, "y": 0.86, "label": "Pesce"}, {"id": "mammifero", "x": 0.90, "y": 0.86, "label": "Mammifero"}],
			"connections": [["ali", "uccello"], ["ali", "pinne"], ["pinne", "pesce"], ["pinne", "mammifero"]],
			"explanation": "Ha le ali » sì » il ramo porta a 'Uccello'."},
		{"topic": "albero-decisioni", "minLevel": 6, "answer": "quadrato",
			"prompt": "Segui l'albero: una figura ha 4 lati UGUALI e 4 angoli retti. Dove arrivi?",
			"domande": [
				{"prompt": "Segui l'albero: una figura NON ha 4 lati. Dove arrivi?", "answer": "triangolo", "explanation": "La prima domanda separa: se i lati non sono quattro, il ramo porta al triangolo."},
				{"prompt": "Segui l'albero: una figura ha 4 lati ma NON tutti uguali. Dove arrivi?", "answer": "rettangolo", "explanation": "Quattro lati sì, ma non uguali: il ramo porta al rettangolo."},
			],
			"components": [{"id": "quattro", "x": 0.50, "y": 0.12, "label": "Ha 4 lati?"}, {"id": "triangolo", "x": 0.20, "y": 0.52, "label": "Triangolo"}, {"id": "uguali", "x": 0.70, "y": 0.44, "label": "Lati uguali?"}, {"id": "quadrato", "x": 0.55, "y": 0.86, "label": "Quadrato"}, {"id": "rettangolo", "x": 0.90, "y": 0.86, "label": "Rettangolo"}],
			"connections": [["quattro", "triangolo"], ["quattro", "uguali"], ["uguali", "quadrato"], ["uguali", "rettangolo"]],
			"explanation": "4 lati » sì » lati uguali » sì » il ramo porta a 'Quadrato'."},
	],
	# GEOGRAFIA — il renderer nodi+collegamenti diventa il CORSO DI UN FIUME, con un
	# affluente che confluisce: si legge dove nasce e dove sfocia.
	"geografia": [
		{"topic": "geografia-fisica", "minLevel": 4, "answer": "valico",
			"prompt": "Due valli sono collegate attraverso la montagna. Qual è il punto da cui si passa dall'una all'altra?",
			"domande": [
				{"prompt": "In questo profilo, qual è il punto più alto della montagna?", "answer": "cima", "explanation": "La cima è il punto più elevato: il valico invece è l'insellatura più bassa da cui si passa."},
			],
			"components": [{"id": "valle-a", "x": 0.12, "y": 0.75, "label": "Valle"}, {"id": "cima", "x": 0.50, "y": 0.12, "label": "Cima"}, {"id": "valico", "x": 0.50, "y": 0.48, "label": "Valico"}, {"id": "valle-b", "x": 0.88, "y": 0.75, "label": "Altra valle"}],
			"connections": [["valle-a", "valico"], ["valico", "valle-b"], ["cima", "valico"]],
			"explanation": "Il valico (o passo) è il punto più basso della cresta: si passa da lì, non dalla cima, proprio perché costa meno salita."},
		{"topic": "fiume", "minLevel": 4, "answer": "foce",
			"prompt": "Questo è il corso di un fiume. In quale punto sfocia nel mare (la foce)?",
			"domande": [
				{"prompt": "In questo corso d'acqua, dove il fiume secondario si unisce a quello principale?", "answer": "confluenza", "explanation": "La confluenza è il punto d'incontro fra due corsi d'acqua."},
				{"prompt": "Quale elemento è il corso d'acqua minore che si unisce al fiume principale?", "answer": "affluente", "explanation": "L'affluente è il fiume che porta la sua acqua a un altro: si unisce nella confluenza."},
			],
			"components": [{"id": "sorgente", "x": 0.20, "y": 0.12, "label": "Sorgente"}, {"id": "affluente", "x": 0.72, "y": 0.20, "label": "Affluente"}, {"id": "confluenza", "x": 0.48, "y": 0.50, "label": "Confluenza"}, {"id": "foce", "x": 0.60, "y": 0.90, "label": "Foce"}],
			"connections": [["sorgente", "confluenza"], ["affluente", "confluenza"], ["confluenza", "foce"]],
			"explanation": "La foce è dove il fiume finisce nel mare, il punto più in basso del corso."},
		{"topic": "fiume", "minLevel": 5, "answer": "sorgente",
			"prompt": "In questo corso d'acqua, dove nasce il fiume principale (la sorgente)?",
			"domande": [
				{"prompt": "In questo corso d'acqua, dove il fiume finisce nel mare?", "answer": "foce", "explanation": "La foce è il punto d'arrivo del fiume, dove si getta nel mare."},
				{"prompt": "Qual è il corso d'acqua che si unisce al principale portandogli altra acqua?", "answer": "affluente", "explanation": "L'affluente non arriva al mare da solo: confluisce nel fiume principale."},
			],
			"components": [{"id": "sorgente", "x": 0.20, "y": 0.12, "label": "Sorgente"}, {"id": "affluente", "x": 0.72, "y": 0.20, "label": "Affluente"}, {"id": "confluenza", "x": 0.48, "y": 0.50, "label": "Confluenza"}, {"id": "foce", "x": 0.60, "y": 0.90, "label": "Foce"}],
			"connections": [["sorgente", "confluenza"], ["affluente", "confluenza"], ["confluenza", "foce"]],
			"explanation": "La sorgente è dove il fiume nasce, in alto: da lì l'acqua scende verso la foce."},
	],
	# STORIA — il renderer nodi+collegamenti diventa una LINEA DEL TEMPO: le ere in
	# fila, si sceglie la più antica o la più recente.
	"storia": [
		{"topic": "roma", "minLevel": 4, "answer": "repubblica",
			"prompt": "Roma attraversò queste fasi in quest'ordine. Qual era la fase di mezzo?",
			"domande": [
				{"prompt": "Con quale forma di governo cominciò la storia di Roma?", "answer": "monarchia", "explanation": "Roma nacque come monarchia, con i re: solo dopo divenne repubblica."},
				{"prompt": "Quale fase venne dopo la repubblica?", "answer": "impero", "explanation": "Dopo la repubblica Roma divenne impero, con un solo capo al potere."},
			],
			"components": [{"id": "monarchia", "x": 0.10, "y": 0.50, "label": "Monarchia"}, {"id": "repubblica", "x": 0.37, "y": 0.50, "label": "Repubblica"}, {"id": "impero", "x": 0.64, "y": 0.50, "label": "Impero"}, {"id": "caduta", "x": 0.92, "y": 0.50, "label": "Caduta"}],
			"connections": [["monarchia", "repubblica"], ["repubblica", "impero"], ["impero", "caduta"]],
			"explanation": "Roma fu prima monarchia (i re), poi repubblica (i consoli), infine impero. La fase di mezzo è la repubblica."},
		{"topic": "ere", "minLevel": 4, "answer": "preistoria",
			"prompt": "Questa è la linea del tempo delle grandi età. Quale era è la più antica, all'inizio di tutto?",
			"domande": [
				{"prompt": "In questa linea del tempo, in quale età si colloca il Medioevo?", "answer": "medioevo", "explanation": "Il Medioevo sta fra l'età antica e quella moderna: è la terza delle cinque."},
				{"prompt": "Quale età viene subito dopo il Medioevo?", "answer": "moderna", "explanation": "L'età moderna segue il Medioevo e precede quella contemporanea."},
			],
			"components": [{"id": "preistoria", "x": 0.10, "y": 0.50, "label": "Preistoria"}, {"id": "antica", "x": 0.32, "y": 0.50, "label": "Età antica"}, {"id": "medioevo", "x": 0.55, "y": 0.50, "label": "Medioevo"}, {"id": "moderna", "x": 0.77, "y": 0.50, "label": "Età moderna"}, {"id": "contemporanea", "x": 0.95, "y": 0.50, "label": "Contemporanea"}],
			"connections": [["preistoria", "antica"], ["antica", "medioevo"], ["medioevo", "moderna"], ["moderna", "contemporanea"]],
			"explanation": "La Preistoria è la più antica: è la prima era, prima ancora della scrittura."},
		{"topic": "ere", "minLevel": 5, "answer": "contemporanea",
			"prompt": "In questa linea del tempo, quale era è la più recente, quella in cui viviamo?",
			"domande": [
				{"prompt": "Quale età viene subito dopo la preistoria?", "answer": "antica", "explanation": "L'età antica comincia con la scrittura e chiude la preistoria."},
				{"prompt": "Quale età sta fra l'antica e la moderna?", "answer": "medioevo", "explanation": "Il Medioevo è l'età di mezzo: il nome stesso lo dice."},
			],
			"components": [{"id": "preistoria", "x": 0.10, "y": 0.50, "label": "Preistoria"}, {"id": "antica", "x": 0.32, "y": 0.50, "label": "Età antica"}, {"id": "medioevo", "x": 0.55, "y": 0.50, "label": "Medioevo"}, {"id": "moderna", "x": 0.77, "y": 0.50, "label": "Età moderna"}, {"id": "contemporanea", "x": 0.95, "y": 0.50, "label": "Contemporanea"}],
			"connections": [["preistoria", "antica"], ["antica", "medioevo"], ["medioevo", "moderna"], ["moderna", "contemporanea"]],
			"explanation": "L'Età contemporanea è l'ultima della linea: è quella in cui viviamo oggi."},
	],
	# MUSICA — il renderer nodi+collegamenti diventa la FORMA DI UNA CANZONE: le
	# sezioni in fila, si riconosce quella che torna uguale (il ritornello).
	"musica": [
		{"topic": "ritmo", "minLevel": 4, "answer": "croma",
			"prompt": "Le figure musicali sono in fila dalla più lunga alla più breve: qual è la più breve?",
			"domande": [
				{"prompt": "Fra queste figure musicali, qual è la più lunga?", "answer": "semibreve", "explanation": "La semibreve è la più lunga della fila: ogni figura successiva dura la metà della precedente."},
				{"prompt": "Quale figura dura la metà della semibreve?", "answer": "minima", "explanation": "La minima vale metà semibreve: la scala procede sempre dimezzando."},
			],
			"components": [{"id": "semibreve", "x": 0.12, "y": 0.50, "label": "Semibreve"}, {"id": "minima", "x": 0.38, "y": 0.50, "label": "Minima"}, {"id": "semiminima", "x": 0.64, "y": 0.50, "label": "Semiminima"}, {"id": "croma", "x": 0.90, "y": 0.50, "label": "Croma"}],
			"connections": [["semibreve", "minima"], ["minima", "semiminima"], ["semiminima", "croma"]],
			"explanation": "Ogni figura vale la metà di quella prima: semibreve 4 battiti, minima 2, semiminima 1, croma mezzo. La più breve è la croma."},
		{"topic": "lettura", "minLevel": 4, "answer": "ritornello2",
			"prompt": "Questa è la struttura di una canzone. Quale sezione RIPETE il ritornello già sentito?",
			"domande": [
				{"prompt": "In questa struttura, quale sezione chiude la canzone?", "answer": "finale", "explanation": "Il finale è l'ultima sezione: chiude il brano dopo l'ultimo ritornello."},
				{"prompt": "Quale sezione apre la canzone raccontando la storia?", "answer": "strofa1", "explanation": "La strofa è la parte che racconta e cambia parole a ogni ripetizione."},
			],
			"components": [{"id": "strofa1", "x": 0.12, "y": 0.50, "label": "Strofa"}, {"id": "ritornello1", "x": 0.34, "y": 0.50, "label": "Ritornello"}, {"id": "strofa2", "x": 0.56, "y": 0.50, "label": "Strofa 2"}, {"id": "ritornello2", "x": 0.78, "y": 0.50, "label": "Ritornello"}, {"id": "finale", "x": 0.95, "y": 0.50, "label": "Finale"}],
			"connections": [["strofa1", "ritornello1"], ["ritornello1", "strofa2"], ["strofa2", "ritornello2"], ["ritornello2", "finale"]],
			"explanation": "Il ritornello è la parte che torna uguale: qui è il secondo 'Ritornello', che ripete il primo."},
		{"topic": "lettura", "minLevel": 5, "answer": "ponte",
			"prompt": "In questa struttura, quale sezione è il PONTE, quella diversa che appare una volta sola tra due ritornelli?",
			"domande": [
				{"prompt": "In questa struttura, quale sezione torna uguale dopo il ponte?", "answer": "ritornello2", "explanation": "Il ritornello ritorna sempre uguale: è la parte che si ricorda e si canta."},
				{"prompt": "Quale sezione chiude il brano?", "answer": "finale", "explanation": "Il finale è l'ultima sezione della struttura."},
			],
			"components": [{"id": "strofa", "x": 0.10, "y": 0.50, "label": "Strofa"}, {"id": "ritornello1", "x": 0.32, "y": 0.50, "label": "Ritornello"}, {"id": "ponte", "x": 0.55, "y": 0.50, "label": "Ponte"}, {"id": "ritornello2", "x": 0.78, "y": 0.50, "label": "Ritornello"}, {"id": "finale", "x": 0.95, "y": 0.50, "label": "Finale"}],
			"connections": [["strofa", "ritornello1"], ["ritornello1", "ponte"], ["ponte", "ritornello2"], ["ritornello2", "finale"]],
			"explanation": "Il ponte è la sezione nuova che compare una sola volta, tra i due ritornelli: crea varietà."},
	],
	# LATINO — il renderer nodi+collegamenti diventa un ALBERO DELL'ETIMOLOGIA: una
	# radice latina al centro e le parole italiane che ne derivano. Si sceglie la
	# radice comune: il latino che vive ancora nell'italiano.
	"latino": [
		{"topic": "etimologia", "minLevel": 4, "answer": "videre",
			"prompt": "Queste parole italiane derivano tutte dalla stessa radice latina. Qual è la radice comune?",
			"domande": [
				{"prompt": "Fra queste parole, qual è la più recente, nata con un'invenzione moderna?", "answer": "televisione", "explanation": "«Televisione» è composta di recente unendo il greco «tele» (lontano) alla radice latina di «videre»."},
				{"prompt": "Quale parola significa «che si vede chiaramente»?", "answer": "evidente", "explanation": "«Evidente» viene da «videre»: è ciò che si mostra alla vista senza bisogno di spiegazioni."},
			],
			"components": [{"id": "videre", "x": 0.50, "y": 0.20, "label": "videre"}, {"id": "video", "x": 0.18, "y": 0.65, "label": "video"}, {"id": "evidente", "x": 0.50, "y": 0.85, "label": "evidente"}, {"id": "televisione", "x": 0.82, "y": 0.65, "label": "televisione"}],
			"connections": [["videre", "video"], ["videre", "evidente"], ["videre", "televisione"]],
			"explanation": "La radice è «videre», vedere: da lì video, evidente (che si vede bene) e televisione, che significa «vedere lontano»."},
		{"topic": "etimologia", "minLevel": 4, "answer": "aqua",
			"prompt": "Queste parole italiane derivano tutte dalla stessa radice latina. Qual è la radice comune?",
			"domande": [
				{"prompt": "Quale parola indica la costruzione che porta l'acqua da lontano?", "answer": "acquedotto", "explanation": "«Acquedotto» unisce «aqua» e «ducere» (condurre): è ciò che conduce l'acqua."},
				{"prompt": "Quale parola indica il recipiente dove vivono i pesci?", "answer": "acquario", "explanation": "«Acquario» viene da «aqua»: è il luogo dell'acqua."},
			],
			"components": [{"id": "aqua", "x": 0.50, "y": 0.20, "label": "aqua"}, {"id": "acqua", "x": 0.18, "y": 0.65, "label": "acqua"}, {"id": "acquedotto", "x": 0.50, "y": 0.82, "label": "acquedotto"}, {"id": "acquario", "x": 0.82, "y": 0.65, "label": "acquario"}],
			"connections": [["aqua", "acqua"], ["aqua", "acquedotto"], ["aqua", "acquario"]],
			"explanation": "La radice è 'aqua' (acqua in latino): da lì nascono acqua, acquedotto, acquario."},
		{"topic": "etimologia", "minLevel": 6, "answer": "terra",
			"prompt": "Anche queste parole italiane vengono dalla stessa radice latina. Qual è la radice comune?",
			"domande": [
				{"prompt": "Quale parola indica ciò che sta sotto la superficie del suolo?", "answer": "sotterraneo", "explanation": "«Sotterraneo» unisce «sotto» e la radice di «terra»."},
				{"prompt": "Quale parola indica una porzione di terra che appartiene a qualcuno?", "answer": "territorio", "explanation": "«Territorio» viene da «terra»: è l'estensione di terra di uno Stato o di un gruppo."},
			],
			"components": [{"id": "terra", "x": 0.50, "y": 0.20, "label": "terra"}, {"id": "territorio", "x": 0.18, "y": 0.65, "label": "territorio"}, {"id": "terrestre", "x": 0.50, "y": 0.82, "label": "terrestre"}, {"id": "sotterraneo", "x": 0.82, "y": 0.65, "label": "sotterraneo"}],
			"connections": [["terra", "territorio"], ["terra", "terrestre"], ["terra", "sotterraneo"]],
			"explanation": "La radice è 'terra': da lì nascono territorio, terrestre e sotterraneo."},
	],
	# INGLESE — il renderer nodi+collegamenti diventa un ALBERO DELLE PAROLE: una
	# parola base e le parole inglesi che ne derivano (morfologia). Si sceglie la
	# base comune.
	"inglese": [
		{"topic": "vocabolario", "minLevel": 4, "answer": "play",
			"prompt": "These words all grow from the same short word. Which one is the base?",
			"domande": [
				{"prompt": "Which word means the person who plays?", "answer": "player", "explanation": "«Player» is «play» plus «-er»: the ending «-er» turns an action into the person who does it."},
				{"prompt": "Which word is the «-ing» form of the verb?", "answer": "playing", "explanation": "«Playing» is «play» plus «-ing»: it describes the action while it is happening."},
			],
			"components": [{"id": "play", "x": 0.50, "y": 0.20, "label": "play"}, {"id": "player", "x": 0.18, "y": 0.65, "label": "player"}, {"id": "playing", "x": 0.50, "y": 0.85, "label": "playing"}, {"id": "playful", "x": 0.82, "y": 0.65, "label": "playful"}],
			"connections": [["play", "player"], ["play", "playing"], ["play", "playful"]],
			"explanation": "«play» è la parola base: player, playing e playful sono costruite tutte su di lei aggiungendo un pezzo in fondo."},
		{"topic": "word-family", "minLevel": 4, "answer": "play",
			"prompt": "These English words belong to the same family. Which is the base word (the root)?",
			"domande": [
				{"prompt": "Which word names a place where children play?", "answer": "playground", "explanation": "«Playground» joins «play» and «ground»: it is a compound word, not just an ending."},
				{"prompt": "Which word describes someone full of fun?", "answer": "playful", "explanation": "«Playful» is «play» plus «-ful»: the ending «-ful» means «full of»."},
			],
			"components": [{"id": "play", "x": 0.50, "y": 0.20, "label": "play"}, {"id": "player", "x": 0.18, "y": 0.65, "label": "player"}, {"id": "playful", "x": 0.50, "y": 0.82, "label": "playful"}, {"id": "playground", "x": 0.82, "y": 0.65, "label": "playground"}],
			"connections": [["play", "player"], ["play", "playful"], ["play", "playground"]],
			"explanation": "The base word is 'play': player, playful and playground all come from it."},
		{"topic": "word-family", "minLevel": 4, "answer": "help",
			"prompt": "These words share the same root. Which is the base word?",
			"domande": [
				{"prompt": "Which word means the person who helps?", "answer": "helper", "explanation": "«Helper» is «help» plus «-er»: the ending «-er» names the person who does the action."},
				{"prompt": "Which word means «without help»?", "answer": "helpless", "explanation": "«Helpless» is «help» plus «-less»: the ending «-less» means «without»."},
			],
			"components": [{"id": "help", "x": 0.50, "y": 0.20, "label": "help"}, {"id": "helper", "x": 0.20, "y": 0.68, "label": "helper"}, {"id": "helpful", "x": 0.52, "y": 0.84, "label": "helpful"}, {"id": "helpless", "x": 0.82, "y": 0.66, "label": "helpless"}],
			"connections": [["help", "helper"], ["help", "helpful"], ["help", "helpless"]],
			"explanation": "The base word is 'help': helper, helpful and helpless are built from it."},
		# --- La formazione delle parole, fasce 7 e 8 (9 settembre 2026) -------
		{"topic": "word-family", "minLevel": 19, "answer": "happy",
			"prompt": "These words are built from the same base. Which one is the base?",
			"domande": [
				{"prompt": "Which word means the opposite, built with a prefix?", "answer": "unhappy", "explanation": "«Unhappy» is «happy» with «un-» in front: a prefix changes the meaning, it does not change the part of speech."},
				{"prompt": "Which word is the noun of the family?", "answer": "happiness", "explanation": "«Happiness» is «happy» plus «-ness»: the ending «-ness» turns a quality into the name of that quality."},
			],
			"components": [{"id": "happy", "x": 0.50, "y": 0.20, "label": "happy"}, {"id": "unhappy", "x": 0.18, "y": 0.65, "label": "unhappy"}, {"id": "happiness", "x": 0.50, "y": 0.85, "label": "happiness"}, {"id": "happily", "x": 0.82, "y": 0.65, "label": "happily"}],
			"connections": [["happy", "unhappy"], ["happy", "happiness"], ["happy", "happily"]],
			"explanation": "La base e' «happy», e i tre rami mostrano i due mestieri diversi degli affissi: davanti «un-» rovescia il significato, in fondo «-ness» e «-ly» cambiano il mestiere della parola — nome e avverbio. Riconoscere il pezzo aggiunto permette di capire una parola mai vista."},
		{"topic": "word-family", "minLevel": 22, "answer": "care",
			"prompt": "These words share the same root. Which is the base word?",
			"domande": [
				{"prompt": "Which word means «without care»?", "answer": "careless", "explanation": "«Careless» is «care» plus «-less»: the ending «-less» means «without», and it is the exact opposite of «-ful»."},
				{"prompt": "Which word tells you HOW something is done?", "answer": "carefully", "explanation": "«Carefully» ends in «-ly»: that ending builds adverbs, and an adverb answers the question «how?»."},
			],
			"components": [{"id": "care", "x": 0.50, "y": 0.20, "label": "care"}, {"id": "careful", "x": 0.18, "y": 0.65, "label": "careful"}, {"id": "carefully", "x": 0.50, "y": 0.85, "label": "carefully"}, {"id": "careless", "x": 0.82, "y": 0.65, "label": "careless"}],
			"connections": [["care", "careful"], ["care", "carefully"], ["care", "careless"]],
			"explanation": "«Care» e' la base, e i suffissi si sommano in fila: «-ful» fa l'aggettivo, «-ly» lo trasforma in avverbio, «-less» costruisce il contrario. E' la stessa catena che regge migliaia di parole inglesi, ed e' il motivo per cui la formazione delle parole vale piu' di un vocabolario."},
	],
}

# CICLO VISUALE: le fasi sono dati disciplinari, mentre posizione, frecce e glifi
# sono composti dal renderer. L'array `stages` non porta coordinate di schermo;
# il builder lo mescola e `correctOrder` conserva il processo scientifico.
const CYCLE := {
	"scienze": [
		{"topic": "ciclo-acqua",
			"prompt": "Ricostruisci il ciclo dell'acqua partendo dall'acqua raccolta in mari e laghi.",
			"stages": [{"id": "raccolta", "label": "Raccolta", "glyph": "water"}, {"id": "evaporazione", "label": "Evaporazione", "glyph": "sun"}, {"id": "condensazione", "label": "Condensazione", "glyph": "cloud"}, {"id": "precipitazione", "label": "Precipitazione", "glyph": "rain"}],
			"correctOrder": ["raccolta", "evaporazione", "condensazione", "precipitazione"],
			"explanation": "Il Sole fa evaporare l'acqua raccolta; il vapore condensa nelle nuvole e torna al suolo con le precipitazioni, alimentando di nuovo la raccolta."},
		{"topic": "ciclo-vita",
			"prompt": "Ricostruisci il ciclo della farfalla partendo dall'uovo.",
			"stages": [{"id": "uovo", "label": "Uovo", "glyph": "egg"}, {"id": "larva", "label": "Bruco", "glyph": "larva"}, {"id": "crisalide", "label": "Crisalide", "glyph": "chrysalis"}, {"id": "adulto", "label": "Farfalla", "glyph": "butterfly"}],
			"correctOrder": ["uovo", "larva", "crisalide", "adulto"],
			"explanation": "Dall'uovo nasce il bruco; il bruco forma la crisalide e da questa emerge la farfalla adulta, che depone nuove uova."},
		{"topic": "ciclo-carbonio", "minLevel": 12,
			"prompt": "Segui una parte del ciclo del carbonio partendo dalla CO₂ nell'atmosfera.",
			"stages": [{"id": "atmosfera", "label": "CO₂ nell'aria", "glyph": "air"}, {"id": "pianta", "label": "Pianta", "glyph": "plant"}, {"id": "animale", "label": "Animale", "glyph": "animal"}, {"id": "respirazione", "label": "Respirazione", "glyph": "carbon"}],
			"correctOrder": ["atmosfera", "pianta", "animale", "respirazione"],
			"explanation": "La pianta assorbe CO₂, l'animale riceve carbonio nutrendosi e la respirazione ne restituisce una parte all'atmosfera."},
		{"topic": "fotosintesi", "minLevel": 18,
			"prompt": "Segui il carbonio dalla CO₂ nell'aria fino al suo ritorno con la respirazione.",
			"stages": [{"id": "co2", "label": "CO₂", "glyph": "carbon"}, {"id": "foglia", "label": "Fotosintesi", "glyph": "leaf"}, {"id": "glucosio", "label": "Glucosio", "glyph": "sugar"}, {"id": "animale", "label": "Nutrimento", "glyph": "animal"}, {"id": "aria", "label": "Respirazione", "glyph": "air"}],
			"correctOrder": ["co2", "foglia", "glucosio", "animale", "aria"],
			"explanation": "La fotosintesi incorpora il carbonio della CO₂ nel glucosio; il carbonio passa col nutrimento e la respirazione ne restituisce una parte all'aria."},
	],
	"coding": [
		{"topic": "algoritmi", "minLevel": 3, "prompt": "Ricostruisci il giro di un ciclo, partendo da quando la variabile viene preparata.",
			"stages": [{"id": "inizializza", "label": "Prepara il contatore", "glyph": "pen"}, {"id": "condizione", "label": "Controlla la condizione", "glyph": "question"}, {"id": "corpo", "label": "Esegue le istruzioni", "glyph": "gear"}, {"id": "incremento", "label": "Aggiorna il contatore", "glyph": "arrow"}],
			"correctOrder": ["inizializza", "condizione", "corpo", "incremento"],
			"explanation": "Il controllo viene PRIMA del corpo: se la condizione è già falsa il ciclo non gira nemmeno una volta. E senza l'aggiornamento finale la condizione resta vera per sempre — è il ciclo infinito."},
		{"topic": "sequenza", "minLevel": 6, "prompt": "Ricostruisci il giro che un programma fa su ogni dato, partendo dalla lettura.",
			"stages": [{"id": "leggi", "label": "Legge il dato", "glyph": "book"}, {"id": "controlla", "label": "Verifica che sia valido", "glyph": "question"}, {"id": "trasforma", "label": "Lo trasforma", "glyph": "gear"}, {"id": "scrivi", "label": "Scrive il risultato", "glyph": "check"}],
			"correctOrder": ["leggi", "controlla", "trasforma", "scrivi"],
			"explanation": "Il controllo sta subito dopo la lettura, non alla fine: trasformare un dato sbagliato costa lavoro e produce un risultato sbagliato con sicurezza."},
	],
	"matematica": [
		{"topic": "numeri", "minLevel": 6, "prompt": "Sull'orologio a 12 ore, ricostruisci il giro partendo dalle 9.",
			"stages": [{"id": "nove", "label": "Ore 9", "glyph": "clock"}, {"id": "dodici", "label": "Ore 12", "glyph": "clock"}, {"id": "tre", "label": "Ore 3", "glyph": "clock"}, {"id": "sei", "label": "Ore 6", "glyph": "clock"}],
			"correctOrder": ["nove", "dodici", "tre", "sei"],
			"explanation": "Dopo il 12 non si arriva al 13: si torna a 1. È l'aritmetica dell'orologio, e funziona così ogni volta che si conta «a giro» — i giorni della settimana, i mesi, i resti di una divisione."},
	],
	"fisica": [
		{"topic": "energia", "minLevel": 8, "prompt": "Segui l'energia di un pendolo, partendo dal punto più alto.",
			"stages": [{"id": "alto", "label": "Ferma in alto", "glyph": "arrow"}, {"id": "scende", "label": "Scende e accelera", "glyph": "bolt"}, {"id": "basso", "label": "Veloce in basso", "glyph": "fire"}, {"id": "risale", "label": "Risale e rallenta", "glyph": "arrow"}],
			"correctOrder": ["alto", "scende", "basso", "risale"],
			"explanation": "L'energia non si consuma, cambia forma: potenziale in alto, cinetica in basso, e di nuovo potenziale. Il pendolo si ferma solo perché l'attrito ne trasforma un po' in calore a ogni giro."},
	],
	"geografia": [
		{"topic": "geografia-fisica", "minLevel": 10, "prompt": "Ricostruisci il ciclo delle rocce partendo dal magma.",
			"stages": [{"id": "magma", "label": "Magma", "glyph": "fire"}, {"id": "ignea", "label": "Roccia ignea", "glyph": "rock"}, {"id": "sedimento", "label": "Sedimento", "glyph": "soil"}, {"id": "metamorfica", "label": "Roccia metamorfica", "glyph": "rock"}],
			"correctOrder": ["magma", "ignea", "sedimento", "metamorfica"],
			"explanation": "Nessuna roccia è per sempre: il magma raffreddandosi diventa ignea, l'erosione la riduce in sedimenti, pressione e calore li trasformano ancora, e in profondità tutto può rifondersi."},
	],
	"italiano": [
		{"topic": "testo-narrativo", "minLevel": 4, "prompt": "Ricostruisci come nasce un testo, partendo dall'idea.",
			"stages": [{"id": "idea", "label": "L'idea", "glyph": "question"}, {"id": "scaletta", "label": "La scaletta", "glyph": "book"}, {"id": "stesura", "label": "La stesura", "glyph": "pen"}, {"id": "revisione", "label": "La revisione", "glyph": "check"}],
			"correctOrder": ["idea", "scaletta", "stesura", "revisione"],
			"explanation": "La scaletta viene prima di scrivere, non dopo: serve a decidere l'ordine quando è ancora facile cambiarlo. E la revisione non è un extra — è dove un testo diventa leggibile."},
	],
	"storia": [
		{"topic": "metodo", "minLevel": 7, "prompt": "Ricostruisci il lavoro dello storico, partendo dalla domanda.",
			"stages": [{"id": "domanda", "label": "La domanda", "glyph": "question"}, {"id": "fonti", "label": "La ricerca delle fonti", "glyph": "book"}, {"id": "confronto", "label": "Il confronto", "glyph": "gear"}, {"id": "tesi", "label": "La tesi", "glyph": "check"}],
			"correctOrder": ["domanda", "fonti", "confronto", "tesi"],
			"explanation": "La domanda viene prima delle fonti: senza, si raccolgono documenti a caso. E la tesi viene ultima, dopo il confronto — chi la decide all'inizio poi cerca solo le fonti che gli danno ragione."},
		{"topic": "preistoria", "minLevel": 5, "prompt": "Rimetti in fila come si è passati dal gruppo nomade al villaggio.",
			"stages": [{"id": "caccia", "label": "Si segue la selvaggina", "glyph": "question"}, {"id": "semi", "label": "Si semina e si allevano animali", "glyph": "book"}, {"id": "villaggio", "label": "Ci si ferma in un villaggio", "glyph": "gear"}, {"id": "mestieri", "label": "Il cibo avanza e nascono i mestieri", "glyph": "check"}],
			"correctOrder": ["caccia", "semi", "villaggio", "mestieri"],
			"explanation": "Fermarsi viene DOPO aver imparato a produrre il cibo, non prima: finché lo si insegue non ci si può fermare. E i mestieri vengono ultimi perché nascono da un avanzo — se tutti devono procurarsi da mangiare, nessuno può fare il vasaio a tempo pieno."},
		{"topic": "cronologia", "minLevel": 12, "prompt": "Rimetti le quattro età nell'ordine in cui sono venute.",
			"stages": [{"id": "preistoria", "label": "Preistoria", "glyph": "question"}, {"id": "antica", "label": "Età antica", "glyph": "book"}, {"id": "medioevo", "label": "Medioevo", "glyph": "gear"}, {"id": "moderna", "label": "Età moderna", "glyph": "check"}],
			"correctOrder": ["preistoria", "antica", "medioevo", "moderna"],
			"explanation": "Il confine fra preistoria ed età antica non è una data ma un'invenzione: la scrittura. Prima non ci sono documenti, e ciò che sappiamo lo dicono gli oggetti — per questo la prima si chiama «pre-istoria» e non «storia povera»."},
	],
	"musica": [
		{"topic": "intervalli", "minLevel": 16, "prompt": "Ricostruisci un tratto del circolo delle quinte partendo da Do.",
			"stages": [{"id": "do", "label": "Do", "glyph": "note"}, {"id": "sol", "label": "Sol", "glyph": "note"}, {"id": "re", "label": "Re", "glyph": "note"}, {"id": "la", "label": "La", "glyph": "note"}],
			"correctOrder": ["do", "sol", "re", "la"],
			"explanation": "Salendo di una quinta ogni volta si tocca ogni tonalità e si torna al punto di partenza. È il motivo per cui il circolo si chiama così: continuando, dopo dodici quinte si ritorna al Do."},
	],
}

# CODE-DEBUG (righe numerate selezionabili): trova la riga con l'errore. Testo puro.
const CODE_DEBUG := {
	"coding": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "liste", "minLevel": 14, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni sulle liste: quale e' falsa?",
			"codeLines": ["La prima posizione di una lista e' zero.", "len(lista) restituisce l'indice dell'ultimo elemento.", "append aggiunge un elemento in fondo.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: len restituisce QUANTI elementi ci sono. L'ultimo indice e' len meno uno, ed e' l'errore che produce piu' spesso il messaggio «indice fuori intervallo»."},
		{"topic": "condizioni", "minLevel": 15, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre affermazioni sugli if: quale e' falsa?",
			"codeLines": ["Ogni if deve avere un else.", "Un elif viene valutato solo se l'if prima e' falso.", "La condizione produce vero o falso.", "# trova l'affermazione falsa"],
			"explanation": "Riga 1: l'else e' facoltativo. Quando non serve fare niente nel caso contrario, aggiungerlo vuoto rende il codice piu' lungo e meno chiaro."},
		{"topic": "algoritmi", "minLevel": 20, "answerLine": 3, "shuffleLines": true,
			"prompt": "Tre affermazioni sugli algoritmi: quale e' falsa?",
			"codeLines": ["Un algoritmo deve terminare.", "Lo stesso problema puo' avere algoritmi diversi.", "L'algoritmo piu' corto da scrivere e' sempre il piu' veloce.", "# trova l'affermazione falsa"],
			"explanation": "Riga 3: la ricerca sequenziale si scrive in tre righe e su un milione di elementi e' lentissima; la binaria e' piu' lunga da scrivere e incomparabilmente piu' rapida. Brevita' del codice e velocita' di esecuzione sono due cose diverse."},
		{"topic": "cicli", "answerLine": 3,
			"prompt": "Dovrebbe stampare 1, 2, 3. Quale riga contiene l'errore?",
			"codeLines": ["numeri = [1, 2, 3]", "for i in numeri:", "    print(i + 1)", "# atteso: 1, 2, 3"],
			"explanation": "Riga 3: stampa i+1, cioè 2, 3, 4. Va corretta in print(i)."},
		{"topic": "condizioni", "answerLine": 2,
			"prompt": "Vogliamo salutare solo se il nome NON è vuoto. Quale riga sbaglia?",
			"codeLines": ["nome = 'Sofia'", "if nome == '':", "    print('Ciao ' + nome)", "# salutare solo se c'è un nome"],
			"explanation": "Riga 2: controlla se il nome È vuoto. La condizione va invertita: nome != ''."},
		{"topic": "variabili", "answerLine": 3,
			"prompt": "Il programma dovrebbe stampare 10. Quale riga contiene l'errore?",
			"codeLines": ["x = 3", "x = x + 2", "print(x + 2)", "# dopo la seconda riga x vale 5: va raddoppiato"],
			"explanation": "Riga 3: dopo x = x + 2 il valore è 5; per stampare 10 serve print(x * 2), non aggiungere ancora 2."},
		{"topic": "confronto", "minLevel": 3, "answerLine": 2,
			"prompt": "Vogliamo controllare se x vale 5. Quale riga sbaglia?",
			"codeLines": ["x = 5", "if x = 5:", "    print('cinque')", "# come si confronta in Python?"],
			"explanation": "Riga 2: per confrontare serve '==' (uguaglianza), non '=' (che assegna)."},
		{"topic": "cicli", "minLevel": 4, "answerLine": 1,
			"prompt": "Dovrebbe stampare 0, 1, 2 e poi 'fine'. Quale riga sbaglia?",
			"codeLines": ["for i in range(1, 3):", "    print(i)", "print('fine')", "# atteso: 0, 1, 2, poi fine"],
			"explanation": "Riga 1: range(1, 3) dà 1, 2. Per 0, 1, 2 serve range(3)."},
		{"topic": "indentazione", "minLevel": 5, "answerLine": 3,
			"prompt": "Il totale dovrebbe stamparsi a ogni giro. Quale riga sbaglia?",
			"codeLines": ["for i in range(3):", "    totale = i * 2", "print(totale)", "# il print deve stare dentro il for"],
			"explanation": "Riga 3: print(totale) è fuori dal ciclo, quindi stampa una volta sola. Va rientrato dentro il for."},
		{"topic": "liste", "minLevel": 18, "answerLine": 2,
			"prompt": "Vogliamo visitare tutti gli elementi della lista senza uscire dai limiti. Quale riga sbaglia?",
			"codeLines": ["valori = [10, 20, 30]", "for i in range(1, len(valori) + 1):", "    print(valori[i])", "# gli indici validi partono da 0 e finiscono a len - 1"],
			"explanation": "Riga 2: range(1, len + 1) produce gli indici 1, 2, 3: salta lo 0 e il 3 è fuori lista. Serve range(len(valori))."},
		{"topic": "strutture-dati", "minLevel": 23, "answerLine": 2,
			"prompt": "Vogliamo una copia indipendente della lista. Quale riga fa condividere invece lo stesso oggetto?",
			"codeLines": ["originale = [1, 2]", "copia = originale", "copia.append(3)", "print(originale)", "# originale dovrebbe restare [1, 2]"],
			"explanation": "Riga 2: assegna alla copia lo stesso riferimento. Serve copia = originale.copy(), così append non modifica anche l'originale."},
		{"topic": "logica-booleana", "minLevel": 6, "answerLine": 2,
			"prompt": "Deve essere vero solo se l'età è tra 6 e 10. Quale riga sbaglia?",
			"codeLines": ["eta = 8", "if eta >= 6 or eta <= 10:", "    print('ok')", "# dentro l'intervallo, non fuori"],
			"explanation": "Riga 2: con 'or' è sempre vero. Per l'intervallo serve 'and': eta >= 6 and eta <= 10."},
	],
	"logica": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "verita", "minLevel": 11, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre negazioni: quale e' sbagliata?",
			"codeLines": ["Il contrario di «tutti hanno risposto» e' «almeno uno non ha risposto».", "Il contrario di «tutti hanno risposto» e' «nessuno ha risposto».", "Il contrario di «esiste un cigno nero» e' «nessun cigno e' nero».", "# trova la negazione sbagliata"],
			"explanation": "Riga 2: negare «tutti» non da' «nessuno», da' «non tutti» — cioe' basta un'eccezione. Saltare da un estremo all'altro e' l'errore che rende impossibile discutere davvero."},
		{"topic": "insiemi", "minLevel": 14, "answerLine": 3, "shuffleLines": true,
			"prompt": "Tre affermazioni sugli insiemi: quale e' falsa?",
			"codeLines": ["Se A sta dentro B, ogni elemento di A e' in B.", "Due insiemi possono avere elementi in comune senza contenersi.", "Se A e B hanno elementi in comune, A sta dentro B.", "# trova l'affermazione falsa"],
			"explanation": "Riga 3: avere qualcosa in comune non basta a essere contenuti. I quadrati e i rossi si sovrappongono senza che nessuno dei due stia dentro l'altro, ed e' il caso piu' frequente."},
		{"topic": "sequenze", "minLevel": 15, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre regole per la serie 2, 4, 8, 16: quale NON la spiega?",
			"codeLines": ["Si aggiunge sempre due.", "Ogni numero e' il doppio del precedente.", "Ogni numero e' due elevato alla sua posizione.", "# trova la regola che non funziona"],
			"explanation": "Riga 1: aggiungendo due si otterrebbe 2, 4, 6, 8. Le altre due regole danno la stessa serie con parole diverse, ed e' normale: una sequenza puo' avere piu' descrizioni corrette."},
		{"topic": "quantificatori", "minLevel": 23, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni sui quantificatori: quale e' falsa?",
			"codeLines": ["«Alcuni» non esclude che siano tutti.", "«Alcuni A sono B» implica «alcuni A non sono B».", "«Nessun A e' B» equivale a «nessun B e' A».", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: dire che alcuni lo sono non dice niente sugli altri — potrebbero esserlo tutti. La lingua di tutti i giorni suggerisce il contrario, e in logica quella suggestione va messa da parte."},
		{"topic": "deduzioni", "answerLine": 3,
			"prompt": "Segui la deduzione: quale passo è sbagliato?",
			"codeLines": ["Tutti i gatti sono felini.", "Alcuni felini sono neri.", "Quindi tutti i gatti sono neri.", "# dove si rompe il ragionamento?"],
			"explanation": "La riga 3 generalizza indebitamente: da 'alcuni felini neri' non segue 'tutti i gatti neri'."},
		# Al primo mondo la caccia all'errore di logica aveva UNA specifica: sempre
		# questa, sempre con l'errore alla riga 3. Ed è il formato dove non si può
		# pescare — l'ordine delle righe È il ragionamento — quindi la profondità
		# qui si autora e basta.
		#
		# L'errore è distribuito su tutte e tre le righe di proposito: con l'errore
		# sempre in fondo si impara a scegliere l'ultima riga invece di leggere.
		# Ogni caso rompe un anello diverso — premessa falsa, regola letta male,
		# quantificatore allargato, conto sbagliato — perché è la varietà del TIPO
		# di errore, non del testo, a insegnare a controllare un ragionamento.
		{"topic": "insiemi", "answerLine": 2,
			"prompt": "Segui il ragionamento: quale passo non è valido?",
			"codeLines": ["Tutti i cani hanno quattro zampe.", "Allora tutti gli animali a quattro zampe sono cani.", "Quindi il gatto è un cane.", "# la relazione vale anche al contrario?"],
			"explanation": "Riga 2: la relazione vale in un verso solo. Che ogni cane abbia quattro zampe non rende cane ogni animale a quattro zampe — il gatto ne è la prova. La riga 3 sbaglia solo perché si fida della riga 2."},
		{"topic": "deduzioni", "answerLine": 1,
			"prompt": "Segui il ragionamento: quale affermazione è falsa?",
			"codeLines": ["Tutti i numeri pari finiscono per 2.", "Il numero 14 è pari.", "Eppure 14 finisce per 4.", "# quale delle tre non può stare con le altre?"],
			"explanation": "Riga 1: un numero è pari se finisce per 0, 2, 4, 6 o 8. Le righe 2 e 3 sono vere, ed è proprio la loro verità a smascherare la premessa."},
		{"topic": "sequenze", "answerLine": 2,
			"prompt": "Segui la regola della sequenza: quale passo sbaglia?",
			"codeLines": ["Sequenza: 1, 2, 4, 8, ...", "La regola aggiunge 2 ogni volta", "Il numero dopo l'8 è 16", "# guarda come si passa da 2 a 4"],
			"explanation": "Riga 2: da 2 si arriva a 4 raddoppiando, non aggiungendo 2 — con +2 dopo il 2 verrebbe 4 ma poi 6, non 8. La regola è «×2», e infatti dopo l'8 viene 16: la riga 3 è giusta."},
		{"topic": "deduzioni", "answerLine": 3,
			"prompt": "Segui il conto: quale passo sbaglia?",
			"codeLines": ["In classe ci sono 12 bambini.", "Metà di loro porta gli occhiali.", "Quindi 8 bambini portano gli occhiali.", "# quanto fa la metà di 12?"],
			"explanation": "Riga 3: la metà di 12 è 6, non 8. Le prime due righe sono in ordine: l'errore è solo nel conto finale."},
		{"topic": "deduzioni", "answerLine": 2,
			"prompt": "Segui il ragionamento: quale passo non è valido?",
			"codeLines": ["Alcuni fiori sono rossi.", "Allora tutti i fiori sono rossi.", "Quindi anche questa margherita bianca è rossa.", "# «alcuni» e «tutti» dicono la stessa cosa?"],
			"explanation": "Riga 2: «alcuni» non diventa mai «tutti». La riga 3 arriva a una conclusione assurda proprio perché si appoggia a quel salto."},
		{"topic": "deduzioni", "answerLine": 1,
			"prompt": "Segui il ragionamento: quale affermazione è falsa?",
			"codeLines": ["Tutti i mesi hanno 30 giorni.", "Febbraio è un mese.", "Quindi febbraio ha 30 giorni.", "# tutti i mesi sono lunghi uguale?"],
			"explanation": "Riga 1: i mesi hanno 28, 29, 30 o 31 giorni. Il ragionamento delle righe 2 e 3 è corretto — è la premessa a essere falsa, e una conclusione sbagliata può nascere da un ragionamento giusto."},
		{"topic": "sequenze", "minLevel": 3, "answerLine": 3,
			"prompt": "Segui la regola della sequenza: quale passo sbaglia?",
			"codeLines": ["Sequenza: 2, 4, 6, 8, ...", "La regola aggiunge 2 ogni volta", "Il numero dopo l'8 è 9", "# controlla la regola"],
			"explanation": "Riga 3: con +2, dopo l'8 viene 10, non 9."},
		{"topic": "deduzioni", "minLevel": 5, "answerLine": 3,
			"prompt": "Segui la catena dei confronti: quale conclusione sbaglia?",
			"codeLines": ["Marco è più alto di Luca.", "Luca è più alto di Sara.", "Quindi Sara è più alta di Marco.", "# metti tutti in fila per altezza"],
			"explanation": "Riga 3: se Marco > Luca > Sara, il più alto è Marco. Sara è la più bassa, non la più alta."},
		{"topic": "deduzioni", "minLevel": 7, "answerLine": 3,
			"prompt": "Segui il ragionamento: quale passo non è valido?",
			"codeLines": ["Se piove, la strada è bagnata.", "La strada è bagnata.", "Quindi ha piovuto di sicuro.", "# la strada può bagnarsi in altri modi?"],
			"explanation": "Riga 3: la strada può essere bagnata anche senza pioggia (un annaffiatoio). Non è certo che abbia piovuto."},
		# L'errore non sta sempre nella conclusione: qui è la REGOLA a essere letta
		# male, lì una premessa falsa. Senza queste varianti bastava scegliere
		# l'ultimo passo per superare ogni caccia all'errore di logica.
		{"topic": "sequenze", "minLevel": 4, "answerLine": 2,
			"prompt": "Segui la regola della sequenza: quale passo sbaglia?",
			"codeLines": ["Sequenza: 3, 6, 9, 12, ...", "La regola aggiunge 2 ogni volta", "Il numero dopo il 12 è 15", "# confronta la regola con i numeri"],
			"explanation": "Riga 2: tra 3 e 6 la differenza è 3, non 2. La regola giusta è +3, e infatti dopo il 12 viene 15."},
		{"topic": "deduzioni", "minLevel": 6, "answerLine": 1,
			"prompt": "Segui il ragionamento: quale passo non è valido?",
			"codeLines": ["Tutti gli uccelli volano.", "Il pinguino è un uccello.", "Eppure il pinguino non vola.", "# quale affermazione è troppo assoluta?"],
			"explanation": "Riga 1: \"tutti gli uccelli volano\" è falsa. Il pinguino è la prova: il ragionamento regge, sbaglia la premessa."},
		{"topic": "insiemi", "minLevel": 8, "answerLine": 2,
			"prompt": "Segui la classificazione: quale passo sbaglia?",
			"codeLines": ["Ogni quadrato è un rettangolo.", "Ogni rettangolo è un quadrato.", "Quindi quadrato e rettangolo sono la stessa cosa.", "# la relazione vale in entrambi i versi?"],
			"explanation": "Riga 2: un rettangolo lungo e stretto non è un quadrato. La relazione vale in un verso solo."},
	],
	# ITALIANO — "Caccia all'errore": fra più frasi corrette, una nasconde uno
	# sbaglio (ortografia, accordo, tempo verbale). Si clicca la riga sbagliata: la
	# correzione di bozze come sfida, ben più coinvolgente della scelta multipla.
	"italiano": [
		{"topic": "ortografia", "answerLine": 3, "shuffleLines": true,
			"prompt": "Una frase contiene un errore di ortografia. Quale riga?",
			"codeLines": ["Bevo un po' d'acqua fresca.", "Qual è il tuo colore preferito?", "A scuola studio la sciensa.", "# tutte tranne una sono corrette"],
			"explanation": "Riga 3: si scrive 'scienza' con -sci-, non 'sciensa'. ('un po'' e 'qual è' sono invece corretti)."},
		{"topic": "morfologia", "answerLine": 2, "shuffleLines": true,
			"prompt": "Una frase ha un errore di accordo (genere o numero). Quale riga?",
			"codeLines": ["I bambini giocano in giardino.", "La macchina rosse è veloce.", "Le case sono grandi e luminose.", "# trova l'accordo sbagliato"],
			"explanation": "Riga 2: 'macchina' è singolare femminile, quindi 'rossa', non 'rosse'."},
		{"topic": "verbo", "answerLine": 3, "shuffleLines": true,
			"prompt": "Una frase sbaglia il tempo del verbo. Quale riga?",
			"codeLines": ["Ieri ho finito i compiti.", "Domani andremo al mare.", "L'anno scorso vado in montagna.", "# quale verbo non concorda col tempo?"],
			"explanation": "Riga 3: 'l'anno scorso' è passato, quindi 'sono andato' o 'andavo', non 'vado'."},
		{"topic": "punteggiatura", "answerLine": 2, "shuffleLines": true,
			"prompt": "Una frase usa male l'apostrofo. Quale riga?",
			"codeLines": ["Un'amica mi ha aiutato molto.", "Ho visto un'orso nel bosco.", "L'albero è pieno di frutti.", "# dove l'apostrofo è di troppo?"],
			"explanation": "Riga 2: 'orso' è maschile, quindi 'un orso' senza apostrofo (l'apostrofo va solo con il femminile: un'amica)."},
		# Scuola media — la caccia all'errore diventa correzione di un'analisi.
		{"topic": "analisi-grammaticale", "minLevel": 8, "answerLine": 2, "shuffleLines": true,
			"prompt": "Analisi grammaticale di 'La bianca luna splende': quale riga sbaglia?",
			"codeLines": ["La = articolo determinativo", "bianca = nome comune", "luna = nome comune", "splende = verbo"],
			"explanation": "Riga 2: 'bianca' è un aggettivo qualificativo (descrive la luna), non un nome."},
		{"topic": "verbo", "minLevel": 9, "answerLine": 2, "shuffleLines": true,
			"prompt": "Modo e tempo dei verbi: quale analisi è errata?",
			"codeLines": ["mangerò = futuro semplice", "che io mangi = indicativo presente", "mangiando = gerundio", "# quale voce verbale è analizzata male?"],
			"explanation": "Riga 2: 'che io mangi' è congiuntivo presente, non indicativo (l'indicativo presente è 'io mangio')."},
		{"topic": "analisi-logica", "minLevel": 11, "answerLine": 3, "shuffleLines": true,
			"prompt": "Analisi logica di 'Marco regala un libro a Luca': quale riga sbaglia?",
			"codeLines": ["Marco = soggetto", "regala = predicato verbale", "un libro = complemento di termine", "a Luca = complemento di termine"],
			"explanation": "Riga 3: 'un libro' risponde a 'che cosa?', è complemento oggetto. Il complemento di termine (a chi?) è 'a Luca'."},
		# **I tre argomenti verbali che si potevano solo crocettare.** (9 settembre
		# 2026) `concordanza-tempi-verbali`, `congiuntivo-condizionale` e
		# `imperativo-infinito-participio-gerundio` avevano quindici item ciascuno
		# in tutte le fasce e nessun gesto. Sono anche i tre punti in cui l'errore
		# di un ragazzo di tredici anni è più tipico, e vanno mostrati su una
		# frase intera: fuori dal periodo la concordanza non esiste.
		{"topic": "concordanza-tempi-verbali", "minLevel": 16, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre periodi raccontano un fatto passato: in quale la subordinata non concorda con la principale?",
			"codeLines": ["Disse che sarebbe tornato presto.", "Disse che tornerà presto.", "Sapevo che avevi già finito.", "# trova la subordinata fuori tempo"],
			"explanation": "Riga 2: la principale è al passato («disse»), quindi il futuro va visto da lì — «sarebbe tornato», il futuro nel passato. «Tornerà» guarda avanti da oggi, e nel racconto di ieri non c'è un oggi."},
		{"topic": "congiuntivo-condizionale", "minLevel": 16, "answerLine": 3, "shuffleLines": true,
			"prompt": "Quale frase usa l'indicativo dove il verbo della principale chiede il congiuntivo?",
			"codeLines": ["Penso che tu abbia ragione.", "Spero che arrivino in orario.", "Credo che lui ha capito.", "# trova il modo sbagliato"],
			"explanation": "Riga 3: «credo» esprime un'opinione, non un fatto, e regge il congiuntivo: «che lui abbia capito». L'indicativo direbbe che la cosa è certa, e allora «credo» non servirebbe."},
		{"topic": "imperativo-infinito-participio-gerundio", "minLevel": 22, "answerLine": 2, "shuffleLines": true,
			"prompt": "Il gerundio deve avere lo stesso soggetto della frase principale. Quale riga lo tradisce?",
			"codeLines": ["Uscendo di casa, Marco chiuse la porta.", "Correndo verso la stazione, il treno era già partito.", "Leggendo il biglietto, capimmo tutto.", "# trova il gerundio con il soggetto sbagliato"],
			"explanation": "Riga 2: il gerundio prende il soggetto della principale, che qui è «il treno» — e un treno non corre verso la stazione. Serve «Mentre correvo verso la stazione», che dichiara chi corre."},
	],
	# MATEMATICA — "Caccia all'errore nel calcolo": si segue un procedimento passo
	# per passo e si smaschera la riga sbagliata. Colpisce le misconcezioni tipiche
	# (priorità, area vs perimetro, somma di frazioni): più coinvolgente che ripetere.
	"matematica": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "frazioni", "minLevel": 14, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni sulle frazioni: quale e' falsa?",
			"codeLines": ["Una frazione con numeratore minore del denominatore vale meno di uno.", "Per sommare due frazioni si sommano numeratori e denominatori.", "Moltiplicare per una frazione minore di uno rimpicciolisce.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: sommando cosi', un mezzo piu' un mezzo darebbe due quarti, cioe' meno di quello che si aveva. Per sommare servono lo stesso denominatore, perche' si possono sommare solo pezzi della stessa taglia."},
		# Riscritta il 30 luglio dopo una segnalazione: era ["7 + 5", "= 13",
		# "# quanto fa davvero?"]. Due sole righe candidate (quasi testa o croce) e
		# soprattutto non erano PASSAGGI: "7 + 5" e "= 13" sono i due pezzi di una
		# sola uguaglianza, quindi «quale riga sbaglia» era ambiguo — l'errore stava
		# nella relazione fra le due, non dentro una delle due. Ora sono tre passaggi
		# veri e l'errore è nell'ultimo, dopo un primo passaggio corretto.
		{"topic": "calcolo", "answerLine": 3,
			"prompt": "Controlla il calcolo passo per passo: quale riga sbaglia?",
			"codeLines": ["7 + 5 + 6", "= 12 + 6", "= 19", "# controlla ogni passaggio"],
			"explanation": "Riga 3: 12 + 6 fa 18, non 19. Il primo passaggio (7 + 5 = 12) era giusto."},
		{"topic": "calcolo", "answerLine": 2,
			"prompt": "Controlla la sottrazione 52 − 18: quale passaggio sbaglia?",
			"codeLines": ["52 − 18", "= (50 − 10) + (8 − 2)", "= 34", "# controlla se la scomposizione conserva il valore"],
			"explanation": "Riga 2: ha invertito le unità, infatti (50 − 10) + (8 − 2) fa 46. Col prestito, 52 diventa 40 + 12: (40 − 10) + (12 − 8) = 30 + 4 = 34. Nei numeri relativi anche 2 − 8 è possibile e vale −6."},
		{"topic": "espressioni", "minLevel": 3, "answerLine": 2,
			"prompt": "Calcolo di 2 + 3 × 4 passo per passo: quale riga sbaglia?",
			"codeLines": ["2 + 3 × 4", "= 5 × 4   (ho sommato 2 + 3)", "= 20", "# le priorità sono rispettate?"],
			"explanation": "Riga 2: prima la moltiplicazione! 3 × 4 = 12, poi 2 + 12 = 14. Non si somma 2 + 3 per primo."},
		{"topic": "geometria", "minLevel": 4, "answerLine": 2,
			"prompt": "Perimetro di un rettangolo 5 m × 3 m: quale riga sbaglia?",
			"codeLines": ["Perimetro del rettangolo 5 × 3", "= 5 × 3", "= 15 m", "# è davvero il perimetro?"],
			"explanation": "Riga 2: 5 × 3 è l'AREA. Il perimetro è 2 × (5 + 3) = 16 m."},
		{"topic": "frazioni", "minLevel": 6, "answerLine": 2,
			"prompt": "Somma 1/2 + 1/4 passo per passo: quale riga sbaglia?",
			"codeLines": ["1/2 + 1/4", "= 2/6   (somma sopra e sotto)", "= 1/3", "# si sommano così le frazioni?"],
			"explanation": "Riga 2: non si sommano numeratori e denominatori. Con lo stesso denominatore: 2/4 + 1/4 = 3/4."},
		# Le righe di un calcolo non si possono rimescolare (l'ordine è il
		# ragionamento), quindi l'errore va autorato in punti diversi: senza queste
		# varianti bastava scegliere sempre la seconda riga. Qui sbaglia la
		# traduzione del problema, lì l'ultimo conto dopo un'impostazione giusta.
		{"topic": "problemi", "minLevel": 3, "answerLine": 2,
			"prompt": "Tre scatole con 15 gemme ciascuna: quale riga tradisce il problema?",
			"codeLines": ["Tre scatole da 15 gemme", "3 + 15", "= 18 gemme", "# 'tre scatole DA 15' come si calcola?"],
			"explanation": "Riga 2: \"tre scatole da 15\" sono gruppi uguali, quindi 3 × 15 = 45. L'addizione traduce male il problema."},
		{"topic": "calcolo", "minLevel": 4, "answerLine": 3,
			"prompt": "Calcolo di 12 × 4 passo per passo: quale riga sbaglia?",
			"codeLines": ["12 × 4", "= (10 × 4) + (2 × 4)", "= 40 + 8 = 46", "# la scomposizione è giusta: e la somma?"],
			"explanation": "Riga 3: 40 + 8 fa 48, non 46. La scomposizione in decine e unità era corretta."},
		{"topic": "equazioni", "minLevel": 18, "answerLine": 2,
			"prompt": "Risolvi 2(x + 3) = 14: qual è il primo passaggio sbagliato?",
			"codeLines": ["2(x + 3) = 14", "2x + 3 = 14", "2x = 11", "x = 5,5", "# distribuisci 2 a entrambi i termini nella parentesi"],
			"explanation": "Riga 2: 2 moltiplica sia x sia 3, quindi 2(x + 3) = 2x + 6. Da 2x + 6 = 14 segue x = 4."},
		{"topic": "probabilita", "minLevel": 23, "answerLine": 4,
			"prompt": "Un sacchetto ha 3 palline rosse e 2 blu. Controlla la probabilità di estrarre una rossa: quale riga sbaglia?",
			"codeLines": ["casi possibili = 3 + 2 = 5", "casi favorevoli = 3", "P(rossa) = 3/5 = 0,6", "P(rossa) = 6%", "# trasforma 0,6 in percentuale"],
			"explanation": "Riga 4: 0,6 corrisponde al 60%, non al 6%. Numeratore, denominatore e frazione dei passaggi precedenti sono corretti."},
		{"topic": "frazioni", "minLevel": 7, "answerLine": 3,
			"prompt": "Calcolo di 3/4 di 20: quale riga sbaglia?",
			"codeLines": ["3/4 di 20", "= 20 : 4 × 3", "= 5 × 3 = 12", "# l'impostazione è giusta: e il conto finale?"],
			"explanation": "Riga 3: 5 × 3 fa 15, non 12. Dividere per il denominatore e moltiplicare per il numeratore era la strada giusta."},
	],
	# INGLESE — "Find the mistake": error correction, il cuore dell'apprendimento
	# di una lingua straniera. Una frase su tante nasconde lo sbaglio: si clicca.
	"inglese": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "past-tense", "minLevel": 10, "answerLine": 3, "shuffleLines": true,
			"prompt": "Three sentences about the past: which one is wrong?",
			"codeLines": ["Yesterday I played football.", "She watched a film last night.", "They goed to the park on Sunday.", "# find the wrong verb"],
			"explanation": "Riga 3: «go» e' irregolare e al passato fa «went», non «goed». La regola del -ed vale per la maggioranza dei verbi, ma i piu' usati sono quasi tutti irregolari — ed e' proprio perche' si usano tanto che non si sono mai regolarizzati."},
		{"topic": "sentence", "answerLine": 2,
			"prompt": "Find the mistake in this English text.",
			"codeLines": ["She is my best friend.", "She have a blue bike.", "She goes to school by bus.", "# check the verb"],
			"explanation": "Riga 2: con she, he e it il verbo diventa «has», non «have». La forma giusta è «She has a blue bike». Le righe 1 e 3 sono corrette."},
		{"topic": "spelling", "answerLine": 2, "shuffleLines": true,
			"prompt": "One word is spelled wrong. Which line?",
			"codeLines": ["I have a cat.", "The sun is yelow.", "She likes books.", "# find the spelling mistake"],
			"explanation": "Riga 2: «yellow» vuole due L. E' una parola che si sente giusta anche scritta male, ed e' per questo che va guardata invece che ascoltata: l'inglese raddoppia la consonante per tenere corta la vocale che la precede."},
		{"topic": "articles", "minLevel": 4, "answerLine": 3, "shuffleLines": true,
			"prompt": "One article is wrong. Which line?",
			"codeLines": ["I have a dog.", "There is an egg.", "She eats a apple.", "# which article is wrong?"],
			"explanation": "Riga 3: davanti a un suono di vocale l'articolo prende una consonante d'appoggio, «an apple». Decide il SUONO e non la lettera: per questo si dice «an hour», dove la h non si sente, e «a university», che comincia con il suono di «yes»."},
		{"topic": "third-person", "minLevel": 4, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a grammar mistake. Which line?",
			"codeLines": ["I like pizza.", "She go to school every day.", "They play football.", "# find the sentence with the error"],
			"explanation": "Riga 2: con he, she e it il presente prende la -s, «She goes to school». E' l'unico punto di tutta la coniugazione inglese in cui il verbo cambia, e proprio perche' e' uno solo si dimentica."},
		{"topic": "past-tense", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One past tense is wrong. Which line?",
			"codeLines": ["Yesterday I played tennis.", "She goed home.", "We watched a film.", "# which past tense is wrong?"],
			"explanation": "Riga 2: «go» e' irregolare e al passato diventa «went». «Goed» non e' una svista: e' la regola del -ed applicata dove non vale, l'errore che fanno anche i bambini inglesi — segno che la regola e' stata capita e manca solo la lista delle eccezioni."},
		{"topic": "do-does", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One negative sentence is wrong. Which line?",
			"codeLines": ["I don't like fish.", "He don't like tea.", "We don't watch TV.", "# which negative is wrong?"],
			"explanation": "Riga 2: alla terza persona singolare la -s passa all'ausiliare, «He doesn't like tea», e il verbo principale resta nudo. Due -s nella stessa frase non si mettono mai: una sola, e la prende chi arriva prima."},
		# --- Gli errori del biennio (8 settembre 2026) ------------------------
		{"topic": "present-perfect", "minLevel": 13, "answerLine": 2, "shuffleLines": true,
			"prompt": "One tense is wrong. Which line?",
			"codeLines": ["I have lived here since 2020.", "I have seen him yesterday.", "She has just arrived.", "# which tense does not fit?"],
			"explanation": "Riga 2: «yesterday» dichiara un momento finito e taglia il filo con il presente. Con un tempo chiuso ci vuole il past simple: «I saw him yesterday». Le righe 1 e 3 tengono il filo aperto e vanno bene così."},
		{"topic": "conditionals", "minLevel": 16, "answerLine": 2, "shuffleLines": true,
			"prompt": "One conditional is wrong. Which line?",
			"codeLines": ["If it rains, we will stay in.", "If it will rain, we will stay in.", "If I were you, I would go.", "# which «if» sentence is wrong?"],
			"explanation": "Riga 2: dopo «if» il futuro non si scrive mai. Il futuro lo porta la principale, e la condizione resta al presente — come succede anche dopo «when» e «as soon as»."},
		{"topic": "reported-speech", "minLevel": 16, "answerLine": 2, "shuffleLines": true,
			"prompt": "One reported sentence is wrong. Which line?",
			"codeLines": ["He said he was tired.", "He asked where did I live.", "She told me to close the door.", "# which reported sentence is wrong?"],
			"explanation": "Riga 2: nel discorso indiretto la domanda perde l'inversione e l'aiutante. La forma giusta è «He asked where I lived»: l'ordine torna quello di un'affermazione, e il tempo arretra."},
		{"topic": "passive", "minLevel": 19, "answerLine": 2, "shuffleLines": true,
			"prompt": "One passive sentence is wrong. Which line?",
			"codeLines": ["The house was built in 1890.", "The house built in 1890 by them.", "English is spoken here.", "# which passive is wrong?"],
			"explanation": "Riga 2: senza il verbo essere non c'è nessun passivo, e la casa diventa chi costruisce. Il passivo è sempre verbo essere più participio, in questo ordine e senza saltarne nessuno."},
		{"topic": "gerund-infinitive", "minLevel": 22, "answerLine": 2, "shuffleLines": true,
			"prompt": "One verb form is wrong. Which line?",
			"codeLines": ["I enjoy reading books.", "I decided going home early.", "She is good at solving problems.", "# which verb form is wrong?"],
			"explanation": "Riga 2: «decide» regge l'infinito con «to», non la forma in «-ing». La riga 1 usa un verbo che vuole «-ing», la 3 sta dopo una preposizione, e dopo una preposizione la forma in «-ing» è obbligatoria."},
		# --- La grammatica delle prime fasce (9 settembre 2026) ---------------
		#
		# La caccia all'errore e' il cuore dell'apprendimento di una lingua: si
		# legge una frase plausibile e si trova il punto in cui non regge. Ogni
		# riga sbagliata qui e' un errore che un italiano fa DAVVERO, e le due
		# righe giuste servono a impedire che si risponda a caso.
		{"topic": "to-be", "minLevel": 1, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["I am eleven years old.", "She are my sister.", "We are good friends.", "# check the verb to be"],
			"explanation": "Riga 2: «she» e' una persona sola e vuole «is». La forma «are» vale per il plurale e per «you»: qui il soggetto e' uno, e il verbo deve dirlo."},
		{"topic": "have-got", "minLevel": 4, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["I have got two brothers.", "He have got a dog.", "They have got a big house.", "# check have got"],
			"explanation": "Riga 2: con «he» la prima parola del verbo diventa «has». Cambia solo quella: «got» resta uguale per tutte le persone, e chi la cambia sta cercando la regola nel posto sbagliato."},
		{"topic": "plurals", "minLevel": 4, "answerLine": 2, "shuffleLines": true,
			"prompt": "One plural is wrong. Which line?",
			"codeLines": ["There are three boxes.", "There are two childs.", "There are five cities.", "# which plural is wrong?"],
			"explanation": "Riga 2: il plurale di «child» e' «children», non «childs». E' un plurale antico sopravvissuto perche' la parola si usa moltissimo: le lingue non regolarizzano quello che si dice ogni giorno."},
		{"topic": "there-is", "minLevel": 4, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["There is a cat in the garden.", "There is two cats in the garden.", "There are four chairs here.", "# check there is and there are"],
			"explanation": "Riga 2: i gatti sono due, quindi ci vuole «there are». Il verbo si accorda con quello che viene dopo, non con «there», che non e' un soggetto ma solo il posto che la frase pretende."},
		{"topic": "pronouns", "minLevel": 4, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["She is my best friend.", "Me like chocolate.", "They live in Milan.", "# which pronoun is in the wrong place?"],
			"explanation": "Riga 2: chi compie l'azione e' «I», non «me». L'inglese ha due serie di pronomi e la posizione decide quale: prima del verbo chi agisce, dopo il verbo chi subisce."},
		{"topic": "prepositions", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One preposition is wrong. Which line?",
			"codeLines": ["The lesson starts at nine.", "My birthday is in Monday.", "We go skiing in winter.", "# which preposition is wrong?"],
			"explanation": "Riga 2: il giorno preciso vuole «on», «on Monday». «In» regge i contenitori lunghi — mesi, stagioni, anni — e «at» l'ora: si va dal grande al piccolo, e il giorno sta nel mezzo."},
		{"topic": "present-continuous", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["Look! It is raining.", "She is play tennis now.", "They are having lunch.", "# check the -ing form"],
			"explanation": "Riga 2: dopo il verbo essere ci vuole la forma in -ing, «is playing». Il presente continuo e' fatto di due pezzi e nessuno dei due regge da solo: «is» senza -ing resta a meta'."},
		{"topic": "possessives", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence sounds wrong in English. Which line?",
			"codeLines": ["This is my brother's bike.", "This is the bike of my brother.", "Anna's room is upstairs.", "# how does English show possession?"],
			"explanation": "Riga 2: quando il possessore e' una persona l'inglese non usa «of», mette il possessore davanti con l'apostrofo: «my brother's bike». La frase non e' incomprensibile, e' calcata sull'italiano — e si riconosce proprio da questo."},
		{"topic": "quantifiers", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One question is wrong. Which line?",
			"codeLines": ["How much sugar do you need?", "How much apples do you want?", "How many friends have you got?", "# much or many?"],
			"explanation": "Riga 2: le mele si contano una a una, quindi vuole «many». «Much» sta con quello che si misura e non ha plurale — e la -s finale di «apples» e' gia' la prova che qui non ci va."},
		{"topic": "modals", "minLevel": 13, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["You should call her tonight.", "She must to go home now.", "I can swim very well.", "# check the modal verb"],
			"explanation": "Riga 2: dopo un modale il verbo va all'infinito senza «to», «she must go». I modali sono gli unici verbi che reggono un altro verbo nudo: e' la stessa eccezione che spiega anche perche' non prendono la -s."},
		{"topic": "future", "minLevel": 13, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["I will call you tomorrow.", "I will to call you tomorrow.", "We are going to leave at six.", "# check the future form"],
			"explanation": "Riga 2: «will» e' un modale e non vuole «to» dopo di se'. Il «to» compare invece dentro «going to», dove pero' fa parte della formula: due futuri, due costruzioni, e si confondono proprio per quel «to»."},
		{"topic": "past-continuous", "minLevel": 13, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a mistake. Which line?",
			"codeLines": ["While I was walking, it started to rain.", "While I was walk, it started to rain.", "They were waiting at the station.", "# check the past continuous"],
			"explanation": "Riga 2: manca la -ing, «I was walking». Il passato continuo e' «was/were» piu' la forma in -ing: senza quella coda il verbo non dura, e la frase perde proprio lo sfondo che «while» aveva aperto."},
		{"topic": "relatives", "minLevel": 16, "answerLine": 2, "shuffleLines": true,
			"prompt": "One relative pronoun is wrong. Which line?",
			"codeLines": ["The man who lives here is a doctor.", "The girl which won the race is my cousin.", "The book that I read was long.", "# which relative pronoun is wrong?"],
			"explanation": "Riga 2: «which» vale per le cose, per le persone ci vuole «who» (o «that»). L'italiano usa «che» per tutto e non costringe a scegliere: qui la scelta c'e', e passa dalla differenza fra chi e che cosa."},
		{"topic": "past-perfect", "minLevel": 22, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence puts the two past actions in the wrong order. Which line?",
			"codeLines": ["When I arrived, the train had already left.", "When I arrived, the train already left.", "She had finished her homework before dinner.", "# which sentence loses the order of the two actions?"],
			"explanation": "Riga 2: due passati semplici mettono i fatti sullo stesso piano, e la frase finisce per dire che il treno e' partito dopo il mio arrivo. Il trapassato serve proprio a questo: fa arretrare di un gradino il fatto piu' antico."},
		{"topic": "comparatives", "minLevel": 16, "answerLine": 2, "shuffleLines": true,
			"prompt": "One comparative is wrong. Which line?",
			"codeLines": ["She is taller than her brother.", "This book is more cheap than that one.", "My bike is better than yours.", "# which comparative is wrong?"],
			"explanation": "Riga 2: «cheap» e' una parola corta e prende -er, «cheaper». «More» si mette davanti alle parole lunghe, e le due strade non si sommano mai: chi scrive «more cheaper» applica due volte la stessa regola."},
	],
	# ELETTRONICA — "Caccia all'errore": si scova l'affermazione falsa sul circuito
	# o il passaggio sbagliato nel calcolo elettrico. Il ragionamento come sfida.
	"elettronica": [
		{"topic": "conduttori", "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione sul circuito è falsa. Quale riga?",
			"codeLines": ["La pila fornisce energia.", "Il LED emette luce.", "Il filo di rame blocca la corrente.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il rame è un conduttore, quindi il filo LASCIA passare la corrente, non la blocca."},
		{"topic": "circuito", "answerLine": 2,
			"prompt": "Il LED dovrebbe accendersi: quale passaggio descrive un collegamento sbagliato?",
			"codeLines": ["Collego il polo + della pila al resistore", "Lascio un'interruzione tra resistore e LED", "Collego il LED al polo − della pila", "# la corrente ha bisogno di un percorso chiuso"],
			"explanation": "Riga 2: l'interruzione apre il circuito, quindi non scorre corrente. Serve un collegamento continuo tra resistore e LED."},
		{"topic": "serie-parallelo", "minLevel": 20, "answerLine": 3,
			"prompt": "Due lampadine sono in serie: quale conclusione sul percorso della corrente è sbagliata?",
			"codeLines": ["La corrente attraversa la prima lampadina", "Poi attraversa la seconda lampadina", "Può saltare la seconda scegliendo un altro ramo", "# in serie esiste un solo percorso"],
			"explanation": "Riga 3: in un circuito in serie non ci sono rami alternativi; la stessa corrente attraversa entrambe le lampadine."},
		{"topic": "sicurezza-elettrica", "answerLine": 2, "shuffleLines": true,
			"prompt": "Una di queste regole di sicurezza è sbagliata. Quale riga?",
			"codeLines": ["Monto il circuito con la pila scollegata.", "Se un filo scalda molto, lo tengo in mano per capire quanto.", "Se sento odore di bruciato, stacco e chiamo un adulto.", "# quale riga farebbe finire male la giornata?"],
			"explanation": "Riga 2: se qualcosa scalda si smette di toccarlo. Il calore è il segnale che passa più corrente del dovuto, e la mano non è uno strumento di misura."},
		{"topic": "energia-nei-componenti", "minLevel": 8, "answerLine": 3,
			"prompt": "Segui l'energia in un circuito con la pila e un motorino: quale riga sbaglia?",
			"codeLines": ["La pila mette energia nel circuito.", "Il filo la porta fino al motorino.", "Il motorino la restituisce alla pila come nuova energia.", "# chi dà energia e chi la trasforma?"],
			"explanation": "Riga 3: il motorino non restituisce niente alla pila. Trasforma l'energia in movimento (e un po' in calore), e la riserva della pila cala."},
		{"topic": "potenza", "minLevel": 14, "answerLine": 2,
			"prompt": "Calcola la potenza con V = 6 V e I = 2 A: quale riga sbaglia?",
			"codeLines": ["P = V × I", "P = 6 + 2", "P = 8 W", "# nella formula i valori si moltiplicano"],
			"explanation": "Riga 2: la potenza è 6 × 2 = 12 W. La somma non applica la formula P = V × I."},
		{"topic": "condensatore", "minLevel": 20, "answerLine": 1,
			"prompt": "Segui la carica di un condensatore: quale passaggio è sbagliato?",
			"codeLines": ["Appena collegato è già alla tensione massima", "All'inizio entra corrente e la tensione cresce", "Avvicinandosi al massimo la crescita rallenta", "# la carica richiede un intervallo di tempo"],
			"explanation": "Riga 1: un condensatore non si carica istantaneamente; la sua tensione cresce nel tempo fino ad avvicinarsi a quella della sorgente."},
		{"topic": "legge-ohm", "minLevel": 20, "answerLine": 2, "shuffleLines": true,
			"prompt": "Corrente con V = 10 V e R = 2 Ω: quale riga sbaglia?",
			"codeLines": ["V = 10 V, R = 2 Ω", "I = V × R", "I = 20 A", "# come si calcola la corrente?"],
			"explanation": "Riga 2: la legge di Ohm è I = V / R (10 / 2 = 5 A), non V × R (che darebbe 20)."},
	],
	# SCIENZE — "Caccia all'errore": fra tre affermazioni una è falsa. Colpisce le
	# misconcezioni classiche (la Luna, le branchie, il vapore).
	"scienze": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "terra-universo", "minLevel": 14, "answerLine": 3, "shuffleLines": true,
			"prompt": "Tre affermazioni sul sistema solare: quale e' falsa?",
			"codeLines": ["La Terra impiega un anno a girare attorno al Sole.", "La Luna mostra sempre la stessa faccia alla Terra.", "Le stagioni dipendono dalla distanza dal Sole.", "# trova l'affermazione falsa"],
			"explanation": "Riga 3: dipendono dall'inclinazione dell'asse. Se fosse la distanza, estate e inverno cadrebbero negli stessi mesi nei due emisferi, e invece sono opposti."},
		{"topic": "ambiente", "minLevel": 17, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre affermazioni sull'ambiente: quale e' falsa?",
			"codeLines": ["Riciclare un materiale costa sempre piu' energia che produrlo nuovo.", "L'alluminio si puo' riciclare molte volte.", "La plastica in mare si spezza ma non sparisce.", "# trova l'affermazione falsa"],
			"explanation": "Riga 1: per l'alluminio riciclare costa circa il cinque per cento dell'energia della produzione da minerale. Il bilancio cambia da materiale a materiale, e non e' mai una regola unica."},
		{"topic": "metodo", "answerLine": 2,
			"prompt": "Vogliamo capire se la luce cambia la crescita di una pianta. Quale passaggio rende il confronto scorretto?",
			"codeLines": ["Uso due piante della stessa specie", "Do anche quantità d'acqua diverse", "Cambio soltanto le ore di luce", "# per confrontare, deve cambiare una sola variabile"],
			"explanation": "Riga 2: se cambiano sia luce sia acqua non sappiamo quale causa la differenza. L'acqua deve restare uguale."},
		{"topic": "catena", "answerLine": 3,
			"prompt": "Segui il trasferimento di energia nella catena alimentare: quale riga inverte il verso?",
			"codeLines": ["L'erba cattura energia dalla luce", "Il coniglio mangia l'erba", "L'erba riceve energia dal coniglio", "# l'energia passa dal cibo a chi lo mangia"],
			"explanation": "Riga 3: è il coniglio a ricevere energia dall'erba che mangia, non il contrario."},
		{"topic": "astronomia", "minLevel": 3, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Il Sole è una stella.", "La Terra gira intorno al Sole.", "La Luna produce luce propria.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: la Luna non produce luce, riflette quella del Sole."},
		{"topic": "corpo", "minLevel": 4, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Le piante fanno la fotosintesi.", "Gli animali respirano ossigeno.", "I pesci respirano con i polmoni.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: i pesci respirano con le branchie, non con i polmoni."},
		{"topic": "materia", "minLevel": 5, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["L'acqua bolle a 100 °C.", "Il ghiaccio è acqua allo stato solido.", "Il vapore è più freddo dell'acqua.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il vapore è più caldo, si forma quando l'acqua bolle a 100 °C."},
		{"topic": "ciclo-carbonio", "minLevel": 19, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione sul ciclo del carbonio è falsa. Quale riga?",
			"codeLines": ["Le piante assorbono CO₂ durante la fotosintesi.", "Gli animali ottengono carbonio nutrendosi.", "La respirazione toglie CO₂ dall'atmosfera.", "# segui dove va il carbonio durante la respirazione"],
			"explanation": "Riga 3: la respirazione libera CO₂ nell'atmosfera; è la fotosintesi delle piante che la assorbe."},
		{"topic": "genetica", "minLevel": 24, "answerLine": 1,
			"prompt": "Segui il ragionamento su geni e ambiente: quale passaggio è troppo assoluto?",
			"codeLines": ["Un singolo gene decide da solo ogni caratteristica", "Molti caratteri dipendono da più geni", "Anche l'ambiente può influire su come un carattere appare", "# cerca l'affermazione che elimina tutte le altre cause"],
			"explanation": "Riga 1: molti caratteri dipendono dall'azione di più geni e dall'ambiente; raramente un solo gene decide tutto da solo."},
	],
	# FISICA — "Caccia all'errore": affermazione falsa o calcolo sbagliato. Colpisce
	# le misconcezioni classiche (Galileo, la formula della velocità, l'energia).
	"fisica": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "calore", "minLevel": 16, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni su calore e temperatura: quale e' falsa?",
			"codeLines": ["Il calore passa sempre dal caldo al freddo.", "Due corpi alla stessa temperatura contengono lo stesso calore.", "Durante la fusione la temperatura resta ferma.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: dipende anche da quanta materia c'e'. Una piscina e un bicchiere a venti gradi hanno la stessa temperatura e quantita' di energia lontanissime."},
		{"topic": "energia", "minLevel": 17, "answerLine": 3, "shuffleLines": true,
			"prompt": "Tre affermazioni sull'energia: quale e' falsa?",
			"codeLines": ["L'energia si trasforma da una forma all'altra.", "In ogni trasformazione una parte diventa calore.", "Una macchina ben costruita puo' restituire tutta l'energia ricevuta.", "# trova l'affermazione falsa"],
			"explanation": "Riga 3: nessuna macchina ci riesce, nemmeno quella perfetta. Attriti e resistenze disperdono sempre una quota in calore, ed e' il motivo per cui il moto perpetuo e' impossibile e non soltanto difficile."},
		{"topic": "moto", "answerLine": 3,
			"prompt": "Una bici percorre 30 km in 2 ore. Quale passaggio sbaglia?",
			"codeLines": ["velocità = spazio / tempo", "velocità = 30 km / 2 h", "velocità = 60 km/h", "# dividi 30 per 2"],
			"explanation": "Riga 3: 30 diviso 2 fa 15, quindi la velocità media è 15 km/h, non 60 km/h."},
		{"topic": "forze", "answerLine": 1,
			"prompt": "Un libro resta fermo sul tavolo. Quale passaggio interpreta male le forze?",
			"codeLines": ["Se è fermo, sul libro non agisce alcuna forza", "La gravità tira il libro verso il basso", "Il tavolo esercita una forza verso l'alto", "# due forze opposte possono bilanciarsi"],
			"explanation": "Riga 1: il libro è fermo perché gravità e reazione del tavolo si bilanciano, non perché le forze sono assenti."},
		{"topic": "gravita", "minLevel": 4, "answerLine": 1, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Gli oggetti pesanti cadono più veloci di quelli leggeri.", "La gravità attira gli oggetti verso il basso.", "L'attrito dell'aria rallenta la caduta.", "# quale affermazione è falsa?"],
			"explanation": "Riga 1: senza aria tutti gli oggetti cadono insieme, come mostrò Galileo (piuma e martello sulla Luna cadono uguale)."},
		{"topic": "moto", "minLevel": 5, "answerLine": 2, "shuffleLines": true,
			"prompt": "Velocità di un'auto che fa 100 km in 2 ore: quale riga sbaglia?",
			"codeLines": ["Spazio = 100 km, tempo = 2 h", "velocità = spazio × tempo", "= 200 km/h", "# come si calcola la velocità?"],
			"explanation": "Riga 2: la velocità è spazio / tempo (100 / 2 = 50 km/h), non spazio × tempo."},
		{"topic": "energia", "minLevel": 6, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["La palla in alto ha energia potenziale.", "Cadendo si trasforma in energia cinetica.", "Toccando terra l'energia sparisce nel nulla.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: l'energia non sparisce, si trasforma (in calore, suono, deformazione): è la conservazione dell'energia."},
		{"topic": "onde", "minLevel": 23, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione su frequenza e periodo è falsa. Quale riga?",
			"codeLines": ["La frequenza conta le oscillazioni ogni secondo.", "A frequenza maggiore corrisponde un periodo più breve.", "Raddoppiando la frequenza raddoppia anche il periodo.", "# frequenza e periodo sono inversamente proporzionali"],
			"explanation": "Riga 3: periodo e frequenza sono inversi. Se la frequenza raddoppia, il periodo si dimezza."},
		{"topic": "pressione", "minLevel": 13, "answerLine": 2,
			"prompt": "La stessa forza agisce prima su un'area grande e poi su una piccola. Quale passaggio sbaglia?",
			"codeLines": ["pressione = forza / area", "Riducendo l'area, la pressione diminuisce", "A parità di forza, un'area minore dà più pressione", "# il denominatore diventa più piccolo"],
			"explanation": "Riga 2: dividendo la stessa forza per un'area più piccola si ottiene una pressione maggiore, non minore."},
	],
	# GEOGRAFIA — "Caccia all'errore": fra tre affermazioni una è falsa.
	"geografia": [
		{"topic": "geografia-fisica", "minLevel": 17, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni sul rilievo: quale e' falsa?",
			"codeLines": ["I fiumi scavano di piu' dove la pendenza e' maggiore.", "Le montagne piu' alte sono anche le piu' antiche.", "Il ghiaccio allarga il fondo delle valli scendendo.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: e' il contrario. Le catene giovani come Alpi e Himalaya sono le piu' alte perche' l'erosione non ha ancora avuto tempo; quelle antiche, come gli Urali, sono state consumate fino a diventare colline."},
		{"topic": "geografia-umana", "minLevel": 23, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre affermazioni sulla popolazione: quale e' falsa?",
			"codeLines": ["Un paese con reddito medio alto non ha poveri.", "La densita' non dice come sono distribuiti gli abitanti.", "Una popolazione puo' crescere anche con poche nascite.", "# trova l'affermazione falsa"],
			"explanation": "Riga 1: la media nasconde la distribuzione. Un paese ricco puo' avere disuguaglianze fortissime, ed e' per questo che accanto al reddito medio si guardano sempre gli indici che misurano quanto e' distribuito."},
		{"topic": "climi", "minLevel": 3, "answerLine": 3,
			"prompt": "Segui il ragionamento sul clima: quale passo sbaglia?",
			"codeLines": ["Salendo in montagna la temperatura scende.", "Il rifugio sta a 2000 metri, il paese a 500.", "Quindi al rifugio fa più caldo che in paese.", "# chi dei due sta più in alto?"],
			"explanation": "Riga 3: il rifugio sta millecinquecento metri più in alto, quindi ci fa più FREDDO, non più caldo. Le prime due righe sono giuste."},
		{"topic": "mondo", "minLevel": 3, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Roma è la capitale d'Italia.", "Il Nilo è un fiume.", "L'Everest è un oceano.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: l'Everest è la montagna più alta del mondo, non un oceano."},
		{"topic": "italia", "minLevel": 4, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Il Po è il fiume più lungo d'Italia.", "L'Etna è un vulcano.", "La Sicilia è una catena montuosa.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: la Sicilia è un'isola, non una catena montuosa."},
		{"topic": "climi", "minLevel": 5, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["L'equatore divide la Terra in due emisferi.", "Al Polo Nord fa molto freddo.", "Nel deserto piove quasi ogni giorno.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il deserto è arido, con pochissime piogge in tutto l'anno."},
	],
	# STORIA — "Caccia all'errore": affermazione falsa o cronologia sbagliata.
	"storia": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "roma", "minLevel": 20, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni su Roma antica: quale e' falsa?",
			"codeLines": ["La repubblica precede l'impero.", "Tutti gli abitanti dell'impero erano cittadini fin dall'inizio.", "Il latino si diffuse con l'amministrazione e l'esercito.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: la cittadinanza fu estesa a tutti gli abitanti liberi solo nel 212 dopo Cristo, quasi mille anni dopo la fondazione. Prima era un privilegio concesso poco per volta, ed e' proprio con quelle concessioni che Roma teneva insieme l'impero."},
		{"topic": "medioevo", "minLevel": 23, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre affermazioni sul medioevo: quale e' falsa?",
			"codeLines": ["Nel medioevo non ci furono progressi tecnici.", "I monasteri copiavano e conservavano i testi antichi.", "Le universita' nascono in eta' medievale.", "# trova l'affermazione falsa"],
			"explanation": "Riga 1: mulino ad acqua, aratro pesante, occhiali, bussola e orologio meccanico sono tutti medievali. L'idea di un'epoca ferma nasce molto dopo, da chi voleva presentarsi come il suo contrario."},
		{"topic": "cronologia", "minLevel": 3, "answerLine": 3,
			"prompt": "Segui la linea del tempo: quale passo sbaglia?",
			"codeLines": ["Roma fu fondata nel 753 a.C.", "Gli anni «a.C.» si contano all'indietro.", "Quindi il 753 a.C. viene dopo il 500 a.C.", "# quale dei due è più lontano da noi?"],
			"explanation": "Riga 3: contando all'indietro, il 753 a.C. viene PRIMA del 500 a.C. Più grande è il numero avanti Cristo, più indietro nel tempo si va."},
		{"topic": "civilta", "minLevel": 3, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Gli Egizi costruirono le piramidi.", "I Romani parlavano latino.", "La Preistoria viene dopo il Medioevo.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: la Preistoria è il periodo più antico, viene molto PRIMA del Medioevo."},
		{"topic": "personaggi", "minLevel": 18, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Ad Atene nacque la democrazia.", "Roma fu fondata nel 753 a.C.", "Cristoforo Colombo era un faraone egizio.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: Colombo era un navigatore del Quattrocento, non un faraone egizio."},
		{"topic": "cronologia", "minLevel": 6, "answerLine": 3, "shuffleLines": true,
			"prompt": "Come si contano gli anni avanti Cristo? Quale riga sbaglia?",
			"codeLines": ["Ci sono il 100 a.C. e il 50 a.C.", "Più il numero è grande, più l'anno è antico.", "Quindi il 100 a.C. viene dopo il 50 a.C.", "# quale passaggio è sbagliato?"],
			"explanation": "Riga 3: negli anni a.C. i numeri grandi sono più antichi, quindi il 100 a.C. viene PRIMA del 50 a.C."},
	],
	# MUSICA — "Caccia all'errore": affermazione falsa di teoria musicale.
	"musica": [
		# Completamento della Fase 3, 9 settembre 2026: queste fasce restavano
		# sotto le tre ricette nuove che il piano dichiara come bersaglio.
		{"topic": "note", "minLevel": 8, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni sulle note: quale e' falsa?",
			"codeLines": ["La scala di do non ha alterazioni.", "Fra mi e fa c'e' un tono intero.", "Il pentagramma ha cinque righe.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: fra mi e fa c'e' un semitono, non un tono. Sono le due coppie senza tasto nero in mezzo — mi-fa e si-do — e sono la ragione per cui la tastiera del pianoforte ha quell'aspetto irregolare."},
		{"topic": "tempo", "minLevel": 14, "answerLine": 3, "shuffleLines": true,
			"prompt": "Tre letture di indicazioni di tempo: quale sbaglia?",
			"codeLines": ["4/4 significa quattro semiminime per battuta.", "3/4 e' il tempo del valzer.", "6/8 significa sei semiminime per battuta.", "# trova la lettura sbagliata"],
			"explanation": "Riga 3: in 6/8 il numero sotto dice che l'unita' e' la croma, non la semiminima. Il numero sopra conta quante ne stanno in una battuta, quello sotto dice quale figura si conta."},
		{"topic": "strumenti", "minLevel": 20, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre affermazioni sull'orchestra: quale e' falsa?",
			"codeLines": ["Il sassofono appartiene alla famiglia degli ottoni.", "Gli archi sono la sezione piu' numerosa.", "Il direttore non produce suono.", "# trova l'affermazione falsa"],
			"explanation": "Riga 1: il sassofono e' un legno, anche se e' fatto di metallo. La famiglia si decide da che cosa vibra, e dentro il sassofono vibra una linguetta di canna come nel clarinetto."},
		{"topic": "dinamica", "minLevel": 23, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre affermazioni sulla dinamica: quale e' falsa?",
			"codeLines": ["Il crescendo si distende su piu' battute.", "Un pianissimo va suonato piu' lentamente.", "Il forte riguarda l'intensita', non la velocita'.", "# trova l'affermazione falsa"],
			"explanation": "Riga 2: dinamica e tempo sono assi indipendenti. Si puo' suonare pianissimo e velocissimo, o fortissimo e lentissimo: confonderli e' l'errore piu' comune di chi comincia."},
		{"topic": "ritmo", "minLevel": 3, "answerLine": 2,
			"prompt": "Conta i battiti della battuta: quale passo sbaglia?",
			"codeLines": ["In 4/4 ogni battuta vale 4 battiti.", "Una semiminima vale 2 battiti.", "Quindi in una battuta ci stanno 4 semiminime.", "# quanto vale davvero una semiminima?"],
			"explanation": "Riga 2: la semiminima vale 1 battito, non 2. La riga 3 è giusta proprio perché quattro semiminime da un battito riempiono la battuta."},
		{"topic": "strumenti", "minLevel": 3, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Il violino è uno strumento a corde.", "La tromba è uno strumento a fiato.", "Il flauto è uno strumento a percussione.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il flauto è uno strumento a fiato, non a percussione."},
		{"topic": "ritmo", "minLevel": 5, "answerLine": 3, "shuffleLines": true,
			"prompt": "Controlla le durate: quale riga sbaglia?",
			"codeLines": ["Una minima vale 2 semiminime.", "Una semiminima vale 1 battito.", "Una semibreve vale 2 semiminime.", "# quanti battiti dura la semibreve?"],
			"explanation": "Riga 3: la semibreve vale 4 semiminime (4 battiti), non 2."},
		{"topic": "note", "minLevel": 4, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione sulla scala è falsa. Quale riga?",
			"codeLines": ["La scala è Do Re Mi Fa Sol La Si.", "Dopo il Si si torna al Do.", "Tra il Do e il Re c'è il La.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: tra Do e Re non c'è il La; il La viene più avanti, dopo il Sol."},
	],
	# LATINO — "Caccia all'errore": analisi o affermazione sbagliata sul latino.
	"latino": [
		# Fasce 5 e 7. La caccia all'errore e' il formato giusto per il latino alto:
		# non chiede di produrre una forma — cosa che senza tavola non si deduce —
		# ma di accorgersi che una concordanza non torna, e per accorgersene bisogna
		# aver capito il sistema.
		{"topic": "casi", "minLevel": 14, "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre traduzioni di frasi latine: quale sbaglia il ruolo delle parole?",
			"codeLines": ["«Dominus servum vocat» = il padrone chiama il servo.", "«Servus dominum vocat» = il servo chiama i padroni.", "«Puella rosas portat» = la fanciulla porta le rose.", "# trova la traduzione sbagliata"],
			"explanation": "Riga 2: «dominum» finisce in -um, accusativo SINGOLARE, quindi «il padrone». Il plurale sarebbe «dominos». Chi traduce a orecchio perde il numero, che sta tutto nella desinenza."},
		{"topic": "verbi", "minLevel": 19, "answerLine": 3, "shuffleLines": true,
			"prompt": "Tre analisi di voci verbali: quale e' errata?",
			"codeLines": ["«amant» = terza persona plurale, presente.", "«amabit» = terza persona singolare, futuro.", "«amavit» = terza persona plurale, passato.", "# trova l'analisi sbagliata"],
			"explanation": "Riga 3: «amavit» finisce in -t, quindi e' singolare — «amo'», non «amarono». Il plurale sarebbe «amaverunt». La -t e la -nt distinguono una persona da molte in ogni tempo."},
		{"topic": "frasi", "minLevel": 20, "answerLine": 1, "shuffleLines": true,
			"prompt": "Tre affermazioni sul latino: quale e' falsa?",
			"codeLines": ["Il genitivo indica a chi e' destinata una cosa.", "L'ablativo puo' indicare il mezzo con cui si agisce.", "Il vocativo si usa per chiamare qualcuno.", "# trova l'affermazione falsa"],
			"explanation": "Riga 1: a chi e' destinata una cosa lo dice il DATIVO. Il genitivo dice di chi e', cioe' il possesso: sono due domande diverse, «a chi?» e «di chi?»."},
		# Portate a `minLevel` 1 il 9 settembre 2026: latino era l'unica materia con
		# tre sole meccaniche in rotazione alla fascia 1, perche' queste due
		# stavano a 3 e al mondo 2 non erano ancora idonee. Il contenuto e' adatto
		# fin dall'inizio — riconoscere un errore in un'analisi e' piu' facile che
		# produrla — quindi non c'era ragione di tenerle indietro.
		{"topic": "casi", "minLevel": 1, "answerLine": 2,
			"prompt": "Segui l'analisi della frase: quale passo sbaglia?",
			"codeLines": ["«Puella rosam amat» vuol dire «la fanciulla ama la rosa».", "«rosam» è il soggetto della frase.", "Quindi è la rosa a fare l'azione.", "# quale parola compie l'azione?"],
			"explanation": "Riga 2: «rosam» finisce in -am, è accusativo, e l'accusativo è il complemento oggetto — la cosa amata. Il soggetto è «puella», in nominativo."},
		{"topic": "frasi", "minLevel": 1, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Il latino usa i casi per la funzione delle parole.", "'aqua' significa acqua.", "In latino il verbo di solito sta all'inizio della frase.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: in latino il verbo di solito sta alla FINE della frase (ordine soggetto-oggetto-verbo)."},
		{"topic": "casi", "minLevel": 5, "answerLine": 3, "shuffleLines": true,
			"prompt": "Analisi della frase 'Puella rosam amat': quale riga sbaglia?",
			"codeLines": ["Puella = nominativo (soggetto)", "rosam = accusativo (oggetto)", "amat = genitivo", "# quale analisi è sbagliata?"],
			"explanation": "Riga 3: 'amat' è un verbo (3ª persona di amare), non un caso. I casi valgono per i nomi."},
		{"topic": "declinazioni-base", "minLevel": 6, "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione sulla declinazione è falsa. Quale riga?",
			"codeLines": ["'rosa' è nominativo singolare.", "'rosam' è accusativo singolare.", "'rosarum' è nominativo singolare.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: 'rosarum' è genitivo PLURALE ('delle rose'), non nominativo singolare."},
	],
}

## Materie il cui ordinamento è QUANTITATIVO e generato (non a tabella).
## La logica è stata rimossa il 30 luglio: ordinare numeri non può servire
## onestamente `sequenze`/`deduzioni`/`analogie`, quindi ora ha specifiche
## autorate in `ORDERING` come le altre dieci materie.
const NUMERIC_ORDERING_SUBJECTS := ["matematica"]

## Denominatori delle frazioni generate. Costante di classe (non locale) perché la
## profondità combinatoria si calcola su questi stessi valori: la misura deve
## leggere il dato che il generatore usa davvero, non una copia che può divergere.
const FRACTION_DENOMINATORS := [2, 3, 4, 5, 6, 8, 10, 12]

## Argomenti serviti dal generatore quantitativo, che NON compare in nessuna
## tabella. Dichiararli qui è obbligatorio: `topics_for()` si costruisce dalle
## tabelle, quindi un generatore procedurale non dichiarato resta **invisibile a
## ogni audit** — ed è esattamente così che il difetto del 30 luglio (topic
## "sequenze" iniettato nei mondi di matematica, che dichiarano tabelline/problemi
## e proporzioni/frazioni/geometria) è passato inosservato fino a un playthrough.
const NUMERIC_ORDERING_TOPICS := {
	"matematica": ["tabelline", "frazioni"],
}

# Stessa ragione di NUMERIC_ORDERING_TOPICS, per i formati costruiti da template
# invece che da tabella.
#
# Le quattro famiglie verbali del decodificatore sono argomenti a sé, e non
# accorpate sotto `verbo`: `verb_decoder_audit` pretende che la progressione ne
# copra almeno quattro distinte, perché imparare quando si usa il congiuntivo non
# è imparare a coniugare l'indicativo. Tenerle distinte ha un prezzo, che è stato
# pagato: quindici item di banco ciascuna — così l'esame può davvero interrogarle
# e `topic_alignment_audit` non peggiora — più una voce di manuale e un contesto
# NORA a testa.
#
# Il campione misterioso è il caso opposto: nessun audit chiede granularità, e
# `materia` è già l'argomento che scienze e fisica riconoscono.
const TEMPLATE_FORMAT_TOPICS := {
	"matematica": ["calcolo"],
	"scienze": ["materia"],
	"fisica": ["materia"],
	"italiano": [
		"tempi-indicativo",
		"congiuntivo-condizionale",
		"imperativo-infinito-participio-gerundio",
		"concordanza-tempi-verbali",
	],
	# La griglia degli incroci deduce, le porte decidono quando una condizione è
	# vera: nessuno dei due sta a tabella, quindi i loro argomenti vanno
	# dichiarati qui o restano fuori dal registro della materia.
	"logica": ["deduzioni", "verita"],
}

# Argomenti che la materia sa servire con i minigiochi (oltre al banco statico).
# Sono contenuto reale a tutti gli effetti: una lezione può prometterli e il
# mondo li serve davvero (verificato in `world_lesson_audit`).
static func topics_for(subject: String) -> Array:
	var topics: Dictionary = {}
	for table in [MATCHING, ORDERING, CLASSIFICATION, GRAPH, CIRCUIT, CODE_DEBUG, SWIPE]:
		for spec in Array((table as Dictionary).get(subject, [])):
			var topic := str((spec as Dictionary).get("topic", ""))
			if topic != "":
				topics[topic] = true
	# Il generatore quantitativo non è a tabella: i suoi argomenti vanno aggiunti
	# a mano, altrimenti resta fuori dal registro e nessun audit lo controlla.
	for topic in Array(NUMERIC_ORDERING_TOPICS.get(subject, [])):
		topics[str(topic)] = true
	for topic in Array(TEMPLATE_FORMAT_TOPICS.get(subject, [])):
		topics[str(topic)] = true
	if subject == "italiano":
		for challenge_data in ItalianMinigameCatalog.all_challenges():
			var challenge := challenge_data as Dictionary
			var spec := challenge.get("spec", {}) as Dictionary
			var topic := str(spec.get("topic", ""))
			if topic != "":
				topics[topic] = true
	return topics.keys()

## **La spiegazione che il minigioco ha gia' scritto.** (15 agosto 2026)
##
## Nasce dalla scheda vuota della segnalazione: NORA non aveva niente da dire su
## «numeri» perche' `KnowledgeCodex` raccoglie gli esempi dai BANCHI, e i topic
## dei minigiochi non stanno nei banchi. Ma la spiegazione c'era gia', scritta
## dentro la spec: «Un numero e' pari se finisce per 0, 2, 4, 6 o 8: basta
## guardare l'ultima cifra, non serve dividere».
##
## Il contenuto non mancava: mancava una porta per andarlo a prendere. Questa e'
## la porta. Ritorna la prima spec di quel topic che porta una spiegazione — e la
## sua domanda, che diventa l'esempio svolto.
static func spiegazione_di_topic(subject: String, topic: String) -> Dictionary:
	for table in [MATCHING, ORDERING, CLASSIFICATION, GRAPH, CIRCUIT, CODE_DEBUG, SWIPE]:
		for spec_data in Array((table as Dictionary).get(subject, [])):
			var spec: Dictionary = spec_data
			if str(spec.get("topic", "")) != topic:
				continue
			var spiegazione := str(spec.get("explanation", "")).strip_edges()
			if spiegazione == "":
				continue
			return {
				"explanation": spiegazione,
				"prompt": str(spec.get("prompt", "")).strip_edges(),
			}
	if subject == "italiano":
		for challenge_data in ItalianMinigameCatalog.all_challenges():
			var spec := (challenge_data as Dictionary).get("spec", {}) as Dictionary
			if str(spec.get("topic", "")) != topic:
				continue
			var spiegazione := str(spec.get("explanation", "")).strip_edges()
			if spiegazione != "":
				return {
					"explanation": spiegazione,
					"prompt": str(spec.get("prompt", "")).strip_edges(),
				}
	return {}

# --- Specifiche a insieme: quante voci si pescano, e quanto sono profonde -------
#
# Queste funzioni sono la SORGENTE UNICA della politica di estrazione: le usano sia
# i costruttori di nodi (per pescare) sia gli audit (per dichiarare la profondità).
# Tenerle separate significherebbe misurare una cosa e giocarne un'altra.

# Campi che devono restare distinti dentro una prova, per non renderla ambigua.
const MATCHING_UNIQUE := [0, 1]              # coppie [sinistra, destra]
const ORDERING_UNIQUE := ["label", "value"]  # voci {label, value}

# ---------------------------------------------------------------------------
# Formati visuali: notazione, carta muta, reperti
# ---------------------------------------------------------------------------
#
# Tre superfici che il runtime sa già disegnare (`exercise_diagram.gd`) e
# validare (`exercise_interaction.gd`), e che fino al 3 agosto 2026 non avevano
# contenuto: erano renderer vuoti, cioè peso morto nel PCK.
#
# Perché servono davvero, e non sono decorazione: la lettura sul pentagramma è
# una competenza VISIVA, e finora il gioco la chiedeva *descrivendo a parole*
# dove sta la nota — come insegnare a leggere raccontando le lettere. Stessa
# cosa per una carta muta: «qual è la capitale» è memoria, «dov'è il Po» è
# geografia.
#
# La posizione orizzontale dei simboli e le coordinate dei bersagli NON stanno
# qui: le decide il runtime. Il contenuto nomina soltanto `staffStep` (che è
# musicale, non grafico), `mapId` e bersagli semantici.

## Notazione musicale. `staffStep` conta righe e spazi dal basso: 0, 2, 4, 6, 8
## sono le cinque righe, i dispari sono gli spazi, e fuori scala servono le
## linee addizionali. In chiave di violino le righe sono Mi Sol Si Re Fa e gli
## spazi Fa La Do Mi.
# SCORRIMENTO: a sinistra se è sbagliato, a destra se è corretto. A tempo.
#
# È l'unico formato che misura la FLUENZA invece del ragionamento: non «sai
# arrivarci» ma «lo riconosci senza doverci pensare». Vive solo su argomenti
# dichiarati fluency in `ContentManager.FLUENCY_TOPICS` — su un'analisi logica
# il cronometro non misurerebbe competenza, misurerebbe ansia.
#
# Una prova binaria si indovina al cinquanta per cento: è la LUNGHEZZA a
# renderla onesta, non la difficoltà delle singole frasi. Dieci affermazioni
# come minimo, vere e false in equilibrio, e una soglia di precisione ben sopra
# il caso — tutto verificato da `_validate_swipe`.
#
# Le affermazioni false non sono a caso: sono gli errori che i bambini fanno
# davvero (3³ = 9, un'amico, eated, Barcellona capitale di Spagna).
const SWIPE := {
	"matematica": [
		{"topic": "frazioni", "minLevel": 1, "actionTheme": "fraction_forge", "prompt": "Forgia delle Frazioni: stabilizza a destra le operazioni corrette; rifondi a sinistra quelle che violano le regole.", "seconds": 68.0, "secondsByDifficulty": [0.0, 72.0, 68.0, 64.0, 60.0], "draw": 12, "minAccuracy": 0.80,
			"statements": [
				{"text": "1/4 + 2/4 = 3/4", "correct": true, "minDifficulty": 1, "visual": {"aNum": 1, "aDen": 4, "op": "+", "bNum": 2, "bDen": 4, "rNum": 3, "rDen": 4}},
				{"text": "1/3 + 1/3 = 2/3", "correct": true, "minDifficulty": 1, "visual": {"aNum": 1, "aDen": 3, "op": "+", "bNum": 1, "bDen": 3, "rNum": 2, "rDen": 3}},
				{"text": "3/4 - 1/4 = 2/4", "correct": true, "minDifficulty": 1, "visual": {"aNum": 3, "aDen": 4, "op": "-", "bNum": 1, "bDen": 4, "rNum": 2, "rDen": 4}},
				{"text": "2/5 + 1/5 = 3/5", "correct": true, "minDifficulty": 1, "visual": {"aNum": 2, "aDen": 5, "op": "+", "bNum": 1, "bDen": 5, "rNum": 3, "rDen": 5}},
				{"text": "1/2 + 1/2 = 1", "correct": true, "minDifficulty": 1, "visual": {"aNum": 1, "aDen": 2, "op": "+", "bNum": 1, "bDen": 2, "rNum": 1, "rDen": 1}},
				{"text": "1/4 + 1/4 = 2/8", "correct": false, "minDifficulty": 1, "visual": {"aNum": 1, "aDen": 4, "op": "+", "bNum": 1, "bDen": 4, "rNum": 2, "rDen": 8}},
				{"text": "1/3 + 1/3 = 2/6", "correct": false, "minDifficulty": 1, "visual": {"aNum": 1, "aDen": 3, "op": "+", "bNum": 1, "bDen": 3, "rNum": 2, "rDen": 6}},
				{"text": "3/4 - 1/4 = 2/3", "correct": false, "minDifficulty": 1, "visual": {"aNum": 3, "aDen": 4, "op": "-", "bNum": 1, "bDen": 4, "rNum": 2, "rDen": 3}},
				{"text": "2/5 + 1/5 = 3/10", "correct": false, "minDifficulty": 1, "visual": {"aNum": 2, "aDen": 5, "op": "+", "bNum": 1, "bDen": 5, "rNum": 3, "rDen": 10}},
				{"text": "1/2 + 1/2 = 2/4", "correct": false, "minDifficulty": 1, "visual": {"aNum": 1, "aDen": 2, "op": "+", "bNum": 1, "bDen": 2, "rNum": 2, "rDen": 4}},
				{"text": "1/2 + 1/4 = 3/4", "correct": true, "minDifficulty": 3, "visual": {"aNum": 1, "aDen": 2, "op": "+", "bNum": 1, "bDen": 4, "rNum": 3, "rDen": 4}},
				{"text": "2/3 + 1/6 = 5/6", "correct": true, "minDifficulty": 3, "visual": {"aNum": 2, "aDen": 3, "op": "+", "bNum": 1, "bDen": 6, "rNum": 5, "rDen": 6}},
				{"text": "7/8 - 3/8 = 1/2", "correct": true, "minDifficulty": 2, "visual": {"aNum": 7, "aDen": 8, "op": "-", "bNum": 3, "bDen": 8, "rNum": 1, "rDen": 2}},
				{"text": "1/2 + 1/3 = 2/5", "correct": false, "minDifficulty": 3, "visual": {"aNum": 1, "aDen": 2, "op": "+", "bNum": 1, "bDen": 3, "rNum": 2, "rDen": 5}},
				{"text": "5/6 - 1/3 = 4/3", "correct": false, "minDifficulty": 3, "visual": {"aNum": 5, "aDen": 6, "op": "-", "bNum": 1, "bDen": 3, "rNum": 4, "rDen": 3}},
				{"text": "2/3 x 3/4 = 1/2", "correct": true, "minDifficulty": 3, "visual": {"aNum": 2, "aDen": 3, "op": "x", "bNum": 3, "bDen": 4, "rNum": 1, "rDen": 2}},
				{"text": "3/4 x 2/3 = 1/2", "correct": true, "minDifficulty": 3, "visual": {"aNum": 3, "aDen": 4, "op": "x", "bNum": 2, "bDen": 3, "rNum": 1, "rDen": 2}},
				{"text": "2/5 x 3/4 = 6/9", "correct": false, "minDifficulty": 3, "visual": {"aNum": 2, "aDen": 5, "op": "x", "bNum": 3, "bDen": 4, "rNum": 6, "rDen": 9}},
				{"text": "1/2 : 1/4 = 1/8", "correct": false, "minDifficulty": 4, "visual": {"aNum": 1, "aDen": 2, "op": ":", "bNum": 1, "bDen": 4, "rNum": 1, "rDen": 8}},
				{"text": "4/5 : 2 = 2/5", "correct": true, "minDifficulty": 4, "visual": {"aNum": 4, "aDen": 5, "op": ":", "bNum": 2, "bDen": 1, "rNum": 2, "rDen": 5}},
				{"text": "2/3 : 4/3 = 1/2", "correct": true, "minDifficulty": 4, "visual": {"aNum": 2, "aDen": 3, "op": ":", "bNum": 4, "bDen": 3, "rNum": 1, "rDen": 2}},
				{"text": "3/5 : 2/5 = 3/2", "correct": true, "minDifficulty": 4, "visual": {"aNum": 3, "aDen": 5, "op": ":", "bNum": 2, "bDen": 5, "rNum": 3, "rDen": 2}}],
			"explanation": "Per sommare o sottrarre servono parti della stessa grandezza: rendi uguali i denominatori e lavora sui numeratori. Per moltiplicare opera sopra con sopra e sotto con sotto; per dividere moltiplica per il reciproco. Alla fine semplifica sempre."},
		{"topic": "multipli", "minLevel": 3, "actionTheme": "multiple_defense", "prompt": "Difesa dei Multipli: colpisci a destra i bersagli che rispettano la regola; deviali a sinistra se sono esche.", "seconds": 48.0, "minAccuracy": 0.78,
			"statements": [
				{"text": "Multiplo di 3: 27", "correct": true}, {"text": "Multiplo di 4: 18", "correct": false},
				{"text": "Multiplo di 5: 45", "correct": true}, {"text": "Multiplo di 6: 32", "correct": false},
				{"text": "Multiplo di 8: 56", "correct": true}, {"text": "Multiplo di 7: 45", "correct": false},
				{"text": "Multiplo di 9: 63", "correct": true}, {"text": "Multiplo di 2: 37", "correct": false},
				{"text": "Multiplo di 4: 36", "correct": true}, {"text": "Multiplo di 5: 52", "correct": false},
				{"text": "Multiplo di 6: 54", "correct": true}, {"text": "Multiplo di 3: 40", "correct": false},
				{"text": "Multiplo di 8: 64", "correct": true}],
			"explanation": "Un multiplo nasce moltiplicando il numero per un intero. Le esche qui sono vicine apposta: 36 e divisibile per 4, ma 18 non lo e; 54 e divisibile per 6, ma 32 no."},
		{"topic": "calcolo", "minLevel": 5, "actionTheme": "math_dash", "prompt": "Corsa Numerica: apri a destra i varchi con il risultato corretto, devia a sinistra quelli fuori traiettoria.", "seconds": 50.0, "minAccuracy": 0.78,
			"statements": [
				{"text": "Varco: 7 x 8 = 56", "correct": true}, {"text": "Varco: 45 + 19 = 63", "correct": false},
				{"text": "Varco: 96 : 12 = 8", "correct": true}, {"text": "Varco: doppio di 37 = 72", "correct": false},
				{"text": "Varco: meta di 86 = 43", "correct": true}, {"text": "Varco: 25% di 80 = 25", "correct": false},
				{"text": "Varco: 9 x 6 - 4 = 50", "correct": true}, {"text": "Varco: 120 - 37 = 93", "correct": false},
				{"text": "Varco: 15% di 200 = 30", "correct": true}, {"text": "Varco: 144 : 12 = 14", "correct": false},
				{"text": "Varco: 18 + 27 = 45", "correct": true}, {"text": "Varco: 3/4 di 40 = 25", "correct": false},
				{"text": "Varco: 11 x 11 = 121", "correct": true}],
			"explanation": "La corsa non premia un tocco frettoloso: ogni varco chiede un controllo rapido. 25% e un quarto, 15% di 200 e 10% piu 5%, e 96 : 12 si verifica con 12 x 8."},
		{"topic": "tabelline", "prompt": "Scorri: a destra se il calcolo è giusto, a sinistra se è sbagliato.", "seconds": 45.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "6 × 7 = 42", "correct": true},
				{"text": "8 × 4 = 34", "correct": false},
				{"text": "9 × 3 = 27", "correct": true},
				{"text": "7 × 7 = 49", "correct": true},
				{"text": "5 × 6 = 35", "correct": false},
				{"text": "8 × 8 = 64", "correct": true},
				{"text": "4 × 9 = 36", "correct": true},
				{"text": "6 × 6 = 32", "correct": false},
				{"text": "3 × 8 = 24", "correct": true},
				{"text": "7 × 5 = 40", "correct": false},
				{"text": "9 × 9 = 81", "correct": true},
				{"text": "8 × 6 = 48", "correct": true},
				{"text": "7 × 8 = 54", "correct": false}],
			"explanation": "Le tabelline si misurano a tempo perché servono automatiche: rallentare qui rallenta ogni divisione, ogni frazione e ogni problema che le contiene. Gli errori messi qui sono quelli veri — 8 × 4 confuso con 34, 6 × 6 con 32."},
		{"topic": "potenze", "minLevel": 8, "prompt": "Scorri: a destra se la potenza è giusta, a sinistra se è sbagliata.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "2³ = 8", "correct": true},
				{"text": "3² = 9", "correct": true},
				{"text": "2⁴ = 8", "correct": false},
				{"text": "5² = 25", "correct": true},
				{"text": "4² = 16", "correct": true},
				{"text": "3³ = 9", "correct": false},
				{"text": "10² = 100", "correct": true},
				{"text": "2⁵ = 32", "correct": true},
				{"text": "6² = 36", "correct": true},
				{"text": "4³ = 12", "correct": false},
				{"text": "10³ = 1000", "correct": true},
				{"text": "5³ = 125", "correct": true},
				{"text": "2² = 4 e 4² = 8", "correct": false},
				{"text": "7² = 47", "correct": false}],
			"explanation": "L'errore più comune è moltiplicare la base per l'esponente invece di elevarla: 3³ non è 9 ma 27, 4³ non è 12 ma 64. Riconoscerlo a colpo d'occhio è ciò che distingue chi ha capito le potenze da chi le ricalcola ogni volta."},
		{"topic": "frazioni", "minLevel": 10, "prompt": "Scorri: a destra se l'uguaglianza è giusta, a sinistra se è sbagliata.", "seconds": 55.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "1/2 = 0,5", "correct": true},
				{"text": "1/4 = 0,4", "correct": false},
				{"text": "3/4 = 0,75", "correct": true},
				{"text": "1/5 = 0,2", "correct": true},
				{"text": "2/4 = 1/2", "correct": true},
				{"text": "1/3 = 0,3", "correct": false},
				{"text": "2/5 = 0,4", "correct": true},
				{"text": "5/10 = 0,5", "correct": true},
				{"text": "3/5 = 0,35", "correct": false},
				{"text": "1/10 = 0,1", "correct": true},
				{"text": "4/4 = 1", "correct": true},
				{"text": "2/3 = 0,6", "correct": false},
				{"text": "3/4 = 0,34", "correct": false}],
			"explanation": "Le trappole sono le frazioni che «sembrano» decimali: 1/4 non è 0,4 e 1/3 non è 0,3. Confonderle è l'errore che sopravvive più a lungo, perché la cifra del denominatore somiglia a quella del decimale."},
		{"topic": "percentuali", "minLevel": 12, "prompt": "Scorri: a destra se la percentuale è giusta, a sinistra se è sbagliata.", "seconds": 55.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "50% di 80 = 40", "correct": true},
				{"text": "25% di 40 = 12", "correct": false},
				{"text": "10% di 90 = 9", "correct": true},
				{"text": "20% di 50 = 10", "correct": true},
				{"text": "75% di 40 = 30", "correct": true},
				{"text": "30% di 60 = 20", "correct": false},
				{"text": "100% di 37 = 37", "correct": true},
				{"text": "5% di 200 = 10", "correct": true},
				{"text": "40% di 25 = 12", "correct": false},
				{"text": "1% di 500 = 5", "correct": true},
				{"text": "50% di 15 = 7,5", "correct": true},
				{"text": "25% di 80 = 20", "correct": true},
				{"text": "10% di 45 = 4", "correct": false},
				{"text": "50% di 90 = 40", "correct": false}],
			"explanation": "Il 10% si trova spostando la virgola di un posto, e da lì si costruisce tutto: il 20% è il doppio, il 5% la metà. Chi lo fa a mente riconosce un prezzo sbagliato prima di finire il conto."},
	],
	"italiano": [
		{"topic": "tempi-indicativo", "minLevel": 9, "actionTheme": "verb_time_race", "prompt": "Corsa nel Tempo: apri a destra i portali con il tempo verbale giusto; correggi a sinistra quelli falsi.", "seconds": 52.0, "minAccuracy": 0.80,
			"statements": [
				{"text": "Domani partiremo -> futuro semplice", "correct": true}, {"text": "Da piccolo giocavo fuori -> passato prossimo", "correct": false},
				{"text": "Ho chiuso la porta -> passato prossimo", "correct": true}, {"text": "Ogni estate andavamo al mare -> presente", "correct": false},
				{"text": "Ora preparo lo zaino -> presente", "correct": true}, {"text": "Ieri finii il libro -> imperfetto", "correct": false},
				{"text": "Mentre pioveva, leggevo -> imperfetto", "correct": true}, {"text": "Tra poco arrivera Marta -> passato remoto", "correct": false},
				{"text": "Nel 1861 nacque lo Stato italiano -> passato remoto", "correct": true}, {"text": "Abbiamo visto il film ieri -> futuro semplice", "correct": false},
				{"text": "Fra un'ora iniziera la gara -> futuro semplice", "correct": true}, {"text": "Ogni lunedi studio chitarra -> imperfetto", "correct": false},
				{"text": "Quando ero piccolo temevo il buio -> imperfetto", "correct": true}],
			"explanation": "Il tempo racconta quando e come accade l'azione: presente adesso o abituale, imperfetto per sfondo e ripetizione, passato prossimo per un fatto concluso, futuro per cio che deve arrivare."},
		{"topic": "modi-verbali", "minLevel": 10, "actionTheme": "verb_mode_factory", "prompt": "Officina dei Modi: conferma a destra i comandi verbali calibrati; manda a sinistra quelli con il modo sbagliato.", "seconds": 54.0, "minAccuracy": 0.80,
			"statements": [
				{"text": "Spero che tu arrivi -> congiuntivo", "correct": true}, {"text": "Se avessi tempo, partirei -> imperativo", "correct": false},
				{"text": "Chiudi la finestra! -> imperativo", "correct": true}, {"text": "Vorrei un gelato -> indicativo", "correct": false},
				{"text": "Luca legge un fumetto -> indicativo", "correct": true}, {"text": "Che noi vinciamo -> condizionale", "correct": false},
				{"text": "Se piovesse, resterei qui -> condizionale", "correct": true}, {"text": "Penso che sia tardi -> imperativo", "correct": false},
				{"text": "Credo che Marta abbia capito -> congiuntivo", "correct": true}, {"text": "Andiamo al parco ogni sabato -> congiuntivo", "correct": false},
				{"text": "Vorremmo provare ancora -> condizionale", "correct": true}, {"text": "Non toccare quel filo! -> indicativo", "correct": false},
				{"text": "Portate i quaderni! -> imperativo", "correct": true}],
			"explanation": "Il modo mostra l'atteggiamento verso l'azione: l'indicativo afferma un fatto, il congiuntivo porta dubbio o desiderio, il condizionale immagina una possibilita, l'imperativo da un comando."},
		{"topic": "verbo", "minLevel": 3, "prompt": "Scorri: a destra se la frase è corretta, a sinistra se è sbagliata.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "Le bambine corrono in giardino.", "correct": true},
				{"text": "I ragazzi mangia la merenda.", "correct": false},
				{"text": "Noi andiamo al mare.", "correct": true},
				{"text": "Tu sei arrivato tardi.", "correct": true},
				{"text": "Loro ha finito i compiti.", "correct": false},
				{"text": "Voi avete capito bene.", "correct": true},
				{"text": "Il cane abbaiano forte.", "correct": false},
				{"text": "Io ho visto un film.", "correct": true},
				{"text": "Le foglie cade in autunno.", "correct": false},
				{"text": "Marco e Luca giocano insieme.", "correct": true},
				{"text": "Lei è andata a scuola.", "correct": true},
				{"text": "Gli studenti studiano molto.", "correct": true},
				{"text": "I bambini è andati a casa.", "correct": false}],
			"explanation": "L'accordo fra soggetto e verbo si sente prima di saperlo spiegare, ed è per questo che si misura a tempo: qui non si analizza la frase, si riconosce se «suona». Gli sbagli messi qui sono singolare e plurale scambiati, l'errore che resta anche a chi scrive bene."},
		{"topic": "ortografia", "minLevel": 5, "prompt": "Scorri: a destra se la parola è scritta bene, a sinistra se è sbagliata.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "un'amica", "correct": true},
				{"text": "un'amico", "correct": false},
				{"text": "qual è", "correct": true},
				{"text": "qual'è", "correct": false},
				{"text": "scienza", "correct": true},
				{"text": "coscenza", "correct": false},
				{"text": "efficiente", "correct": true},
				{"text": "propio", "correct": false},
				{"text": "acqua", "correct": true},
				{"text": "soqquadro", "correct": true},
				{"text": "ce n'è", "correct": true},
				{"text": "cé", "correct": false}],
			"explanation": "Sono le forme che si sbagliano scrivendo in fretta, ed è in fretta che vanno riconosciute. «Un'amico» è l'errore più diffuso in assoluto: l'apostrofo va solo davanti al femminile, perché «uno» maschile perde la o senza bisogno di segnalarlo."},
	],
	"inglese": [
		{"topic": "irregular-past", "minLevel": 4, "prompt": "Scorri: a destra se il passato è giusto, a sinistra se è sbagliato.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "go » went", "correct": true},
				{"text": "eat » eated", "correct": false},
				{"text": "see » saw", "correct": true},
				{"text": "take » took", "correct": true},
				{"text": "make » maked", "correct": false},
				{"text": "come » came", "correct": true},
				{"text": "give » gave", "correct": true},
				{"text": "run » runned", "correct": false},
				{"text": "write » wrote", "correct": true},
				{"text": "buy » buyed", "correct": false},
				{"text": "find » found", "correct": true},
				{"text": "know » knew", "correct": true},
				{"text": "think » thinked", "correct": false}],
			"explanation": "I verbi irregolari non seguono la regola del -ed, e sono proprio quelli che si usano di più: le lingue non regolarizzano mai ciò che si dice ogni giorno. Le forme false qui sono quelle che un bambino costruirebbe applicando la regola — ed è giusto che sembrino plausibili."},
		{"topic": "false-friends", "minLevel": 10, "prompt": "Scorri: a destra se la traduzione è vera, a sinistra se è un falso amico.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "actually » in realtà", "correct": true},
				{"text": "actually » attualmente", "correct": false},
				{"text": "library » biblioteca", "correct": true},
				{"text": "library » libreria", "correct": false},
				{"text": "parents » genitori", "correct": true},
				{"text": "parents » parenti", "correct": false},
				{"text": "eventually » alla fine", "correct": true},
				{"text": "eventually » eventualmente", "correct": false},
				{"text": "pretend » fingere", "correct": true},
				{"text": "pretend » pretendere", "correct": false},
				{"text": "sensible » sensato", "correct": true},
				{"text": "sensible » sensibile", "correct": false}],
			"explanation": "I falsi amici somigliano a parole italiane ma hanno cambiato significato. La somiglianza è la trappola: bisogna verificare l'uso nella frase, non fidarsi della forma."},
		{"topic": "present-perfect", "minLevel": 19, "prompt": "Scorri: a destra se la frase è giusta, a sinistra se il tempo è sbagliato.", "seconds": 55.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "I have lived here since 2020", "correct": true},
				{"text": "I have seen him yesterday", "correct": false},
				{"text": "She has just arrived", "correct": true},
				{"text": "We went to Rome last year", "correct": true},
				{"text": "We have gone to Rome last year", "correct": false},
				{"text": "Have you finished yet?", "correct": true},
				{"text": "Did you finish yet?", "correct": false},
				{"text": "I know her since 2019", "correct": false},
				{"text": "I have known her since 2019", "correct": true},
				{"text": "He has been ill for a week", "correct": true},
				{"text": "He is ill since a week", "correct": false},
				{"text": "They arrived two days ago", "correct": true},
				{"text": "They have arrived two days ago", "correct": false}],
			"explanation": "La regola si decide su una parola sola: se la frase dichiara QUANDO — yesterday, last year, two days ago — il filo con il presente si taglia e ci vuole il past simple. Se il periodo resta aperto — since, for, yet, just — ci vuole il present perfect. Le frasi false qui sono tutte errori che un italiano fa davvero, perché in italiano quel filo lo teniamo con il presente."},
	],
	"latino": [
		{"topic": "declinazioni-base", "minLevel": 7, "prompt": "Scorri: a destra se il caso è giusto, a sinistra se è sbagliato.", "seconds": 55.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "rosa = nominativo singolare", "correct": true},
				{"text": "rosam = genitivo singolare", "correct": false},
				{"text": "rosae = genitivo singolare", "correct": true},
				{"text": "rosas = accusativo plurale", "correct": true},
				{"text": "rosis = nominativo plurale", "correct": false},
				{"text": "rosarum = genitivo plurale", "correct": true},
				{"text": "rosa = accusativo singolare", "correct": false},
				{"text": "rosae = nominativo plurale", "correct": true},
				{"text": "rosam = accusativo singolare", "correct": true},
				{"text": "rosis = dativo plurale", "correct": true},
				{"text": "rosarum = accusativo plurale", "correct": false},
				{"text": "rosa = ablativo singolare", "correct": true},
				{"text": "rosarum = dativo singolare", "correct": false}],
			"explanation": "Riconoscere un caso dalla desinenza deve diventare immediato: è la chiave che apre ogni frase latina. Le forme sbagliate qui sono desinenze vere messe sul caso sbagliato — l'errore che si fa davvero traducendo di fretta."},
	],
	"musica": [
		{"topic": "ritmo", "minLevel": 6, "prompt": "Scorri: a destra se la durata è giusta, a sinistra se è sbagliata.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "La semibreve vale 4 movimenti", "correct": true},
				{"text": "La minima vale 3 movimenti", "correct": false},
				{"text": "La semiminima vale 1 movimento", "correct": true},
				{"text": "La croma vale mezzo movimento", "correct": true},
				{"text": "La minima vale 2 movimenti", "correct": true},
				{"text": "La semicroma vale 1 movimento", "correct": false},
				{"text": "Il punto aggiunge metà del valore", "correct": true},
				{"text": "La semibreve vale 2 movimenti", "correct": false},
				{"text": "Due crome fanno una semiminima", "correct": true},
				{"text": "La semicroma vale un quarto di movimento", "correct": true},
				{"text": "Il punto raddoppia il valore della nota", "correct": false},
				{"text": "Quattro semiminime fanno una minima", "correct": false}],
			"explanation": "Le durate stanno fra loro in rapporto di due, sempre: ogni figura vale la metà della precedente. Chi lo ha automatico legge un ritmo a prima vista; chi lo ricalcola si ferma a ogni battuta."},
	],
	"geografia": [
		{"topic": "capitali", "minLevel": 4, "prompt": "Scorri: a destra se la capitale è giusta, a sinistra se è sbagliata.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "Francia » Parigi", "correct": true},
				{"text": "Spagna » Barcellona", "correct": false},
				{"text": "Germania » Berlino", "correct": true},
				{"text": "Portogallo » Lisbona", "correct": true},
				{"text": "Svizzera » Zurigo", "correct": false},
				{"text": "Grecia » Atene", "correct": true},
				{"text": "Austria » Vienna", "correct": true},
				{"text": "Turchia » Istanbul", "correct": false},
				{"text": "Polonia » Varsavia", "correct": true},
				{"text": "Italia » Roma", "correct": true},
				{"text": "Regno Unito » Londra", "correct": true},
				{"text": "Belgio » Bruxelles", "correct": true},
				{"text": "Paesi Bassi » Rotterdam", "correct": false},
				{"text": "Stati Uniti » New York", "correct": false}],
			"explanation": "Gli errori qui non sono a caso: Barcellona, Zurigo e Istanbul sono le città più grandi o più famose dei loro Paesi, ma la capitale è dove sta il governo. È la confusione più comune, e riconoscerla al volo vale più di ripetere l'elenco."},
	],
}

# INDIZIARIO: si chiedono indizi per identificare, e si sceglie quando fermarsi.
#
# È l'unico formato con una SCELTA STRATEGICA dentro: rispondere presto
# rischiando, o scoprire un'altra carta e andare sul sicuro. E rende visibile una
# competenza che nessun altro formato tocca — non «sai la risposta», ma «sai
# quanto ti basta per essere sicuro».
#
# Gli indizi vanno in ORDINE DI FORZA, dal vago al decisivo. Il primo è già
# scoperto quando la prova comincia: partire da zero non è una scelta, è un
# tocco obbligato prima di poter pensare. Che ogni indizio sia più stringente
# del precedente non lo può verificare una macchina: lo giudica chi legge, e
# `_validate_clue` lo dice invece di fingere il contrario.
#
# Nessun indizio costa energia o punti: in un gioco che per contratto non
# punisce, il prezzo di una carta in più è la soddisfazione in meno di averne
# usate poche.
const CLUE := {
	"storia": [
		{"topic": "roma", "minLevel": 6, "prompt": "Chi è il personaggio? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "Visse nell'antica Roma e cambiò per sempre il modo in cui era governata."}, {"text": "Conquistò la Gallia e ne scrisse il racconto di suo pugno."}, {"text": "Attraversò il Rubicone con l'esercito, e non si poteva tornare indietro."}, {"text": "Fu ucciso alle Idi di marzo del 44 a.C."}],
			"targets": [{"id": "a", "label": "Giulio Cesare"}, {"id": "b", "label": "Augusto"}, {"id": "c", "label": "Romolo"}, {"id": "d", "label": "Nerone"}],
			"answer": "a",
			"explanation": "Il primo indizio vale per tutti e quattro: serve a cominciare, non a decidere. La Gallia già restringe a uno solo — chi lo sapeva poteva rispondere lì e risparmiarsi gli altri due."},
		{"topic": "civilta", "minLevel": 11, "prompt": "Quale civiltà è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "Nacque lungo un grande fiume e dipendeva dalle sue piene."}, {"text": "Scriveva con segni che rappresentavano cose e suoni insieme."}, {"text": "Costruì tombe monumentali a base quadrata per i suoi re."}, {"text": "Il suo fiume scorre da sud a nord e sfocia nel Mediterraneo."}],
			"targets": [{"id": "a", "label": "Sumeri"}, {"id": "b", "label": "Egizi"}, {"id": "c", "label": "Fenici"}, {"id": "d", "label": "Greci"}],
			"answer": "b",
			"explanation": "Il primo indizio lascia in gioco Sumeri ed Egizi: entrambi nascono su un fiume. È il terzo a chiudere la questione, ma chi ricorda che il Nilo è l'unico grande fiume che scorre verso nord poteva arrivarci con il quarto."},
		{"topic": "medioevo", "minLevel": 13, "prompt": "Di quale luogo si parla? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "Nel Medioevo ci vivevano decine di persone, e tutte seguivano la stessa regola scritta."}, {"text": "Al suo interno si copiavano a mano i libri antichi, riga per riga."}, {"text": "Coltivava i propri campi e produceva quasi tutto ciò che consumava."}, {"text": "Chi ci entrava rinunciava a sposarsi e a possedere beni propri."}],
			"targets": [{"id": "a", "label": "Il castello"}, {"id": "b", "label": "Il monastero"}, {"id": "c", "label": "Il comune"}, {"id": "d", "label": "La corporazione"}],
			"answer": "b",
			"explanation": "Il terzo indizio non decide niente: nel Medioevo quasi tutti producevano da sé quello che consumavano, castello compreso. Sono il secondo e il quarto a chiudere — la copiatura dei libri e la rinuncia ai beni valgono per un posto solo, ed è per quella copiatura che oggi possediamo i testi antichi."},
	],
	"geografia": [
		{"topic": "europa", "minLevel": 7, "prompt": "Quale Paese è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "Si trova in Europa e ha una costa sul mare."}, {"text": "Confina con la Francia via terra, ma non con la Germania."}, {"text": "Occupa gran parte di una penisola che condivide con un altro Paese."}, {"text": "La sua capitale sta quasi al centro esatto del territorio."}],
			"targets": [{"id": "a", "label": "Italia"}, {"id": "b", "label": "Spagna"}, {"id": "c", "label": "Portogallo"}, {"id": "d", "label": "Grecia"}],
			"answer": "b",
			"explanation": "Il secondo indizio esclude l'Italia, che confina anche con l'Austria e la Svizzera. Il terzo lascia Spagna e Portogallo; il quarto decide, perché Madrid è al centro e Lisbona è sulla costa."},
	],
	"scienze": [
		{"topic": "viventi", "minLevel": 1, "prompt": "Quale animale è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "È un vertebrato e vive in ambienti caldi e umidi."}, {"text": "Da piccolo respira nell'acqua, da adulto anche fuori."}, {"text": "La sua pelle è nuda e umida, senza squame né peli."}, {"text": "Da uovo diventa girino prima di avere le zampe."}],
			"targets": [{"id": "a", "label": "Rana"}, {"id": "b", "label": "Serpente"}, {"id": "c", "label": "Pesce rosso"}, {"id": "d", "label": "Tartaruga"}],
			"answer": "a",
			"explanation": "Il secondo indizio è già decisivo: cambiare modo di respirare crescendo è la definizione stessa di anfibio. Gli altri due lo confermano, e servono a chi non aveva colto il primo segnale."},
	],
	"inglese": [
		{"topic": "parts-of-speech", "minLevel": 7, "prompt": "Quale parola è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "È un sostantivo inglese di uso comune, non un verbo."}, {"text": "Somiglia a una parola italiana ma non significa la stessa cosa."}, {"text": "Chi la traduce a orecchio pensa a un negozio, e sbaglia."}, {"text": "Il posto giusto dove tradurla è quello in cui i libri si prendono in prestito."}],
			"targets": [{"id": "a", "label": "bookshop"}, {"id": "b", "label": "library"}, {"id": "c", "label": "factory"}, {"id": "d", "label": "camera"}],
			"answer": "b",
			"explanation": "Il terzo indizio è quello che conta: «library» somiglia a «libreria» e invece è la biblioteca. È il falso amico che fa sbagliare più spesso, ed è per questo che qui si arriva scartando, non ricordando."},
		{"topic": "false-friends", "minLevel": 13, "prompt": "Quale parola e'? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "E' un aggettivo inglese di uso comune."}, {"text": "Somiglia a una parola italiana che parla dei sentimenti."}, {"text": "Chi la traduce a orecchio descrive una persona che si commuove facilmente."}, {"text": "In inglese descrive invece chi ragiona bene e non fa scelte avventate."}],
			"targets": [{"id": "a", "label": "sensitive"}, {"id": "b", "label": "sensible"}, {"id": "c", "label": "sincere"}, {"id": "d", "label": "silent"}],
			"answer": "b",
			"explanation": "«Sensible» vuol dire sensato, ragionevole; chi si commuove facilmente e' «sensitive». Le due parole esistono entrambe e sono vicinissime: e' per questo che il falso amico regge, e per questo si arriva scartando invece che ricordando."},
		{"topic": "phrasal-verbs", "minLevel": 16, "prompt": "Quale phrasal verb e'? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "E' un verbo seguito da una particella, e insieme valgono una parola sola."}, {"text": "Il verbo di base vuol dire «guardare»."}, {"text": "Ma il significato dell'insieme non ha piu' niente a che fare con gli occhi."}, {"text": "Lo fa un genitore con un bambino, o un'infermiera con un malato."}],
			"targets": [{"id": "a", "label": "look for"}, {"id": "b", "label": "look at"}, {"id": "c", "label": "look after"}, {"id": "d", "label": "look up"}],
			"answer": "c",
			"explanation": "«Look after» significa prendersi cura, e non e' deducibile dai pezzi: e' la particella a decidere tutto. «Look for» e' cercare, «look up» e' cercare su un dizionario, «look at» e' l'unico dei quattro che riguarda ancora gli occhi."},
	],
	# Anche l'indiziario della logica girava su una specifica sola: chi ha vinto la
	# gara era sempre Dino. Dal 1 settembre 2026 sono tre, con tre risposte in tre
	# posizioni diverse — un indiziario che si ricorda a memoria non è un
	# indiziario, è un aneddoto.
	"logica": [
		{"topic": "deduzioni", "minLevel": 8, "prompt": "Chi ha vinto la gara? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "I concorrenti erano quattro: Ada, Bruno, Carla e Dino."}, {"text": "Bruno si è ritirato prima della partenza, quindi non può aver vinto."}, {"text": "Il vincitore ha tagliato il traguardo pochi secondi prima di Carla."}, {"text": "Ada è arrivata subito dopo il vincitore, ma prima di Carla."}],
			"targets": [{"id": "a", "label": "Ada"}, {"id": "b", "label": "Bruno"}, {"id": "c", "label": "Carla"}, {"id": "d", "label": "Dino"}],
			"answer": "d",
			"explanation": "Ogni indizio toglie esattamente un nome: il secondo Bruno, il terzo Carla (che arriva dopo il vincitore), il quarto Ada (che arriva dopo anche lei). Resta Dino. In un'eliminazione non serve mai una prova diretta del vincitore: basta chiudere tutte le altre porte."},
		{"topic": "deduzioni", "minLevel": 8, "prompt": "Quale carta tengo in mano? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "È una delle quattro carte che vedi scoperte sul tavolo."}, {"text": "Non è una figura: sulla mia carta c'è scritto un numero."}, {"text": "Il numero della mia carta è pari."}, {"text": "Il numero della mia carta non si divide per quattro."}],
			"targets": [{"id": "a", "label": "Il 7 di cuori"}, {"id": "b", "label": "La donna di picche"}, {"id": "c", "label": "Il 6 di fiori"}, {"id": "d", "label": "L'8 di quadri"}],
			"answer": "c",
			"explanation": "Il primo indizio non toglie niente e serve solo a partire. Il secondo elimina la donna, il terzo il 7, il quarto l'8 — che è pari ma è anche 4 × 2. Resta il 6. Chi sapeva già che due condizioni insieme (pari e non multiplo di quattro) lasciano un solo numero poteva fermarsi al terzo indizio."},
		{"topic": "deduzioni", "minLevel": 10, "prompt": "Chi ha spento la radio? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "In casa quel pomeriggio c'erano solo Nina, Ivo, Sara e Tobia."}, {"text": "La radio è stata spenta in salotto, e in salotto ci si stava da soli."}, {"text": "Nina e Ivo hanno passato tutto il pomeriggio insieme, in giardino."}, {"text": "Tobia era già uscito di casa quando la radio suonava ancora."}],
			"targets": [{"id": "a", "label": "Nina"}, {"id": "b", "label": "Ivo"}, {"id": "c", "label": "Sara"}, {"id": "d", "label": "Tobia"}],
			"answer": "c",
			"explanation": "Il terzo indizio toglie due nomi in un colpo solo, ed è quello che conta: se Nina e Ivo erano insieme, nessuno dei due era da solo in salotto. Il quarto chiude Tobia e resta Sara, di cui nessun indizio parla mai. In un'eliminazione il nome che non compare non è il meno sospetto: spesso è la risposta."},
	],
}

# LINEA DEL TEMPO: conta la DISTANZA, non solo l'ordine.
#
# Un ordinamento mette in fila due fatti a dieci anni e due a quattro secoli
# esattamente allo stesso modo. Sulla linea del tempo no — e quella differenza
# è tutta la storia.
const TIMELINE := {
	"storia": [
		{"topic": "cronologia", "minLevel": 1, "prompt": "Quale momento della giornata e piu vicino alle 12:00?",
			"min": 0.0, "max": 24.0,
			"labels": [{"value": 0.0, "text": "mezzanotte"}, {"value": 12.0, "text": "mezzogiorno"}, {"value": 24.0, "text": "mezzanotte"}],
			"targets": [{"id": "a", "label": "Colazione (8:00)", "value": 8.0}, {"id": "b", "label": "Pranzo (13:00)", "value": 13.0}, {"id": "c", "label": "Cena (20:00)", "value": 20.0}],
			"answer": "b",
			"explanation": "La linea del tempo mostra anche le distanze: le 13 sono a un'ora da mezzogiorno, le 8 a quattro ore e le 20 a otto. Prima si impara a leggere la distanza, poi si applica alle epoche."},
		{"topic": "cronologia", "minLevel": 8, "prompt": "Quale evento è il più vicino nel tempo alla caduta dell'Impero romano d'Occidente?",
			"min": -800.0, "max": 1500.0,
			"labels": [{"value": -800.0, "text": "800 a.C."}, {"value": 0.0, "text": "0"}, {"value": 476.0, "text": "476"}, {"value": 1500.0, "text": "1500"}],
			"targets": [{"id": "a", "label": "Fondazione di Roma (753 a.C.)", "value": -753.0}, {"id": "b", "label": "Nascita di Augusto imperatore (27 a.C.)", "value": -27.0}, {"id": "c", "label": "Editto di Costantino (313)", "value": 313.0}, {"id": "d", "label": "Scoperta dell'America (1492)", "value": 1492.0}],
			"answer": "c",
			"explanation": "Sulla linea del tempo si vede quello che una fila non mostra: fra l'editto e la caduta passano 163 anni, fra la caduta e Colombo più di mille. Erano vicine solo nell'elenco."},
		{"topic": "cronologia", "minLevel": 14, "prompt": "Quale evento cade nel mezzo fra gli altri due estremi?",
			"min": 1400.0, "max": 1950.0,
			"labels": [{"value": 1400.0, "text": "1400"}, {"value": 1700.0, "text": "1700"}, {"value": 1950.0, "text": "1950"}],
			"targets": [{"id": "a", "label": "Stampa a caratteri mobili (1455)", "value": 1455.0}, {"id": "b", "label": "Rivoluzione francese (1789)", "value": 1789.0}, {"id": "c", "label": "Prima guerra mondiale (1914)", "value": 1914.0}],
			"answer": "b",
			"explanation": "Il 1789 sta quasi a metà fra il 1455 e il 1914. Guardare le distanze invece dell'ordine cambia il senso: fra stampa e rivoluzione passano più di tre secoli, fra rivoluzione e guerra poco più di uno."},
		# **Le tavole diventano prove.** (1 settembre 2026) Le date qui sotto sono
		# le stesse di `TavoleRiferimento` — sezioni Roma, Grecia e medioevo. È il
		# motivo per cui una linea del tempo funziona meglio di una crocetta su
		# questi contenuti: la scheda che NORA mostra prima della domanda è una
		# linea, e la domanda è la stessa linea con un segnaposto da trovare.
		{"topic": "roma", "minLevel": 6, "prompt": "Quale evento apre l'età dell'impero?",
			"min": -800.0, "max": 600.0,
			"labels": [{"value": -753.0, "text": "753 a.C."}, {"value": 0.0, "text": "0"}, {"value": 476.0, "text": "476"}],
			"targets": [{"id": "a", "label": "Fondazione di Roma (753 a.C.)", "value": -753.0}, {"id": "b", "label": "Nasce la repubblica (509 a.C.)", "value": -509.0}, {"id": "c", "label": "Augusto primo imperatore (27 a.C.)", "value": -27.0}, {"id": "d", "label": "Caduta dell'Impero d'Occidente (476)", "value": 476.0}],
			"answer": "c",
			"explanation": "Con Augusto, nel 27 a.C., finisce la repubblica e comincia l'impero. Sulla linea si vede anche il resto: la repubblica è durata quasi cinque secoli, l'impero d'Occidente cinque.",
			"domande": [
				{"prompt": "Quale evento chiude l'età antica?", "answer": "d", "explanation": "La caduta dell'Impero d'Occidente, nel 476: è la data con cui gli storici aprono il medioevo."},
				{"prompt": "Quale evento è il più antico dei quattro?", "answer": "a", "explanation": "753 a.C., la fondazione leggendaria. Prima di Cristo il numero più grande è l'anno più lontano."},
			]},
		{"topic": "grecia", "minLevel": 10, "prompt": "Quale di questi eventi greci è il più recente?",
			"min": -900.0, "max": -300.0,
			"labels": [{"value": -800.0, "text": "800 a.C."}, {"value": -500.0, "text": "500 a.C."}, {"value": -300.0, "text": "300 a.C."}],
			"targets": [{"id": "a", "label": "Nascono le pòleis (800 a.C.)", "value": -800.0}, {"id": "b", "label": "Primi Giochi olimpici (776 a.C.)", "value": -776.0}, {"id": "c", "label": "Democrazia ad Atene (508 a.C.)", "value": -508.0}],
			"answer": "c",
			"explanation": "La democrazia ateniese arriva quasi trecento anni dopo la nascita delle città-stato: prima ci sono volute le pòleis, poi dentro una di esse è nato quel modo di decidere.",
			"domande": [
				{"prompt": "Quale evento viene per primo, cioè è il più antico?", "answer": "a", "explanation": "Le pòleis nascono intorno all'800 a.C.: tutto il resto della storia greca succede dentro di esse."},
			]},
		{"topic": "medioevo", "minLevel": 12, "prompt": "Fra questi, quale evento è il più vicino nel tempo alla caduta di Roma?",
			"min": 300.0, "max": 1600.0,
			"labels": [{"value": 476.0, "text": "476"}, {"value": 1000.0, "text": "1000"}, {"value": 1492.0, "text": "1492"}],
			"targets": [{"id": "a", "label": "Carlo Magno incoronato (800)", "value": 800.0}, {"id": "b", "label": "Peste nera (1347)", "value": 1347.0}, {"id": "c", "label": "Scoperta dell'America (1492)", "value": 1492.0}],
			"answer": "a",
			"explanation": "Fra la caduta di Roma e Carlo Magno passano poco più di trecento anni; fra Carlo Magno e la peste nera più di cinquecento. Il medioevo dura mille anni, e in fila non si vede.",
			"domande": [
				{"prompt": "Quale evento chiude convenzionalmente il medioevo?", "answer": "c", "explanation": "Il 1492, la scoperta dell'America: è la data che gli storici usano per aprire l'età moderna."},
			]},
	],
	"musica": [
		{"topic": "compositori", "minLevel": 16, "prompt": "Quale compositore è vissuto più lontano nel tempo dagli altri due?",
			"domande": [
				{"prompt": "Quale compositore è il più vicino a noi nel tempo?", "answer": "c", "explanation": "Debussy nasce nel 1862, un secolo dopo Beethoven e quasi due dopo Vivaldi. Sulla linea del tempo «vicino a noi» vuol dire più a destra, e basta leggere l'anno."},
				{"prompt": "Quale compositore sta nel mezzo fra gli altri due?", "answer": "b", "explanation": "Beethoven (1770) sta fra Vivaldi (1678) e Debussy (1862). «Nel mezzo» non è il più famoso né quello scritto al centro dell'elenco: è quello con l'anno in mezzo agli altri."},
			],
			"min": 1650.0, "max": 1950.0,
			"labels": [{"value": 1650.0, "text": "1650"}, {"value": 1800.0, "text": "1800"}, {"value": 1950.0, "text": "1950"}],
			"targets": [{"id": "a", "label": "Vivaldi (1678)", "value": 1678.0}, {"id": "b", "label": "Beethoven (1770)", "value": 1770.0}, {"id": "c", "label": "Debussy (1862)", "value": 1862.0}],
			"answer": "a",
			"explanation": "Vivaldi è barocco, Beethoven a cavallo fra classico e romantico, Debussy quasi novecentesco. Le distanze sulla linea sono anche distanze di linguaggio musicale."},
	],
	"italiano": [
		{"topic": "testo-narrativo", "minLevel": 10, "prompt": "Quale opera è la più antica?",
			"domande": [
				{"prompt": "Quale opera è la più recente?", "answer": "c", "explanation": "I promessi sposi escono nel 1827, cinquecento anni dopo la Divina Commedia. È il romanzo con cui l'italiano moderno prende la forma che leggiamo oggi."},
				{"prompt": "Quale opera sta nel mezzo fra le altre due?", "answer": "b", "explanation": "L'Orlando furioso (1532) sta fra Dante e Manzoni. Duecento anni dopo la Commedia e trecento prima dei Promessi sposi: la lingua che ci senti dentro è a metà strada fra le due."},
			],
			"min": 1250.0, "max": 1900.0,
			"labels": [{"value": 1300.0, "text": "1300"}, {"value": 1600.0, "text": "1600"}, {"value": 1900.0, "text": "1900"}],
			"targets": [{"id": "a", "label": "Divina Commedia (1321)", "value": 1321.0}, {"id": "b", "label": "Orlando furioso (1532)", "value": 1532.0}, {"id": "c", "label": "I promessi sposi (1827)", "value": 1827.0}],
			"answer": "a",
			"explanation": "Fra Dante e Manzoni passano cinquecento anni: la lingua italiana in mezzo cambia più di quanto sia cambiata dal 1827 a oggi."},
	],
	# INGLESE — il sistema dei tempi E' una linea del tempo, ed e' l'unico modo di
	# mostrarlo che non chieda di ricordare un nome. Qui non si sceglie un tempo
	# verbale da un elenco: si guarda DOVE cade un fatto, e il tempo verbale e'
	# la conseguenza. Aggiunto il 9 settembre 2026 insieme al resto della
	# grammatica giocabile: il mondo 16 e' l'unico mondo d'inglese delle fasce
	# alte, e i tre tempi del passato ci arrivano tutti insieme.
	"inglese": [
		{"topic": "past-tense", "minLevel": 13, "prompt": "All four sentences are in the past. Which one happened FIRST?",
			"min": 0.0, "max": 24.0,
			"labels": [{"value": 0.0, "text": "midnight"}, {"value": 12.0, "text": "midday"}, {"value": 24.0, "text": "midnight"}],
			"targets": [{"id": "a", "label": "I got up at seven", "value": 7.0}, {"id": "b", "label": "I left home at half past eight", "value": 8.5}, {"id": "c", "label": "We had lunch at one", "value": 13.0}, {"id": "d", "label": "I went to bed at ten", "value": 22.0}],
			"answer": "a",
			"explanation": "Il past simple serve a questo: mettere un fatto in un punto preciso e chiuso del tempo. Ogni frase qui porta la sua ora, e la linea mostra quello che l'elenco non mostrava — che fra l'alzarsi e l'uscire passa un'ora e mezza, e fra il pranzo e il letto nove.",
			"domande": [
				{"prompt": "Which action happened LAST?", "answer": "d", "explanation": "Le dieci di sera sono il punto piu' a destra della linea: piu' avanti nella giornata vuol dire piu' avanti nel tempo, e il past simple li tratta tutti allo stesso modo — fatti chiusi, ognuno al suo posto."},
				{"prompt": "Which action is the closest to midday?", "answer": "c", "explanation": "Le tredici distano un'ora da mezzogiorno; le otto e mezza quasi quattro. Sulla linea la distanza si vede, nell'elenco no."},
			]},
		{"topic": "present-perfect", "minLevel": 16, "prompt": "Which event is the CLOSEST to today?",
			"min": 2014.0, "max": 2026.0,
			"labels": [{"value": 2014.0, "text": "2014"}, {"value": 2020.0, "text": "2020"}, {"value": 2026.0, "text": "oggi"}],
			"targets": [{"id": "a", "label": "We met in 2016", "value": 2016.0}, {"id": "b", "label": "She started school in 2019", "value": 2019.0}, {"id": "c", "label": "They moved to Rome in 2024", "value": 2024.0}],
			"answer": "c",
			"explanation": "Qui si legge la distanza da oggi, ed e' esattamente quello che fanno «since» e «for»: «since» segna il punto in cui una cosa e' cominciata, «for» misura il tratto da li' a oggi. Sulla linea sono la stessa distanza guardata da due estremi.",
			"domande": [
				{"prompt": "Which event started the longest time ago?", "answer": "a", "explanation": "Il 2016 e' il punto piu' a sinistra: piu' lontano da oggi vuol dire un tratto piu' lungo da misurare, e in inglese quel tratto si dice con «for» — for ten years."},
			]},
		{"topic": "past-perfect", "minLevel": 22, "prompt": "Three past actions, one morning. Which one needs the past perfect, because it happened before the others?",
			"min": 8.0, "max": 11.0,
			"labels": [{"value": 8.0, "text": "8:00"}, {"value": 9.0, "text": "9:00"}, {"value": 10.0, "text": "10:00"}, {"value": 11.0, "text": "11:00"}],
			"targets": [{"id": "a", "label": "The train left (9:00)", "value": 9.0}, {"id": "b", "label": "We arrived at the station (9:20)", "value": 9.33}, {"id": "c", "label": "We called home (9:40)", "value": 9.66}],
			"answer": "a",
			"explanation": "Il trapassato non e' «un passato piu' lontano»: e' il fatto che sta PRIMA di un altro passato di cui si sta parlando. Il treno e' partito prima del nostro arrivo, quindi arretra di un gradino — «the train had left» — e gli altri due restano al passato semplice.",
			"domande": [
				{"prompt": "Which action happened LAST?", "answer": "c", "explanation": "La telefonata e' il punto piu' a destra, e resta al passato semplice: il trapassato serve solo al fatto che deve arretrare, non a tutti quelli che vengono prima nell'orologio."},
			]},
	],
}

# COMPOSITORE: si SCELGONO i pezzi, non si riordinano quelli dati.
#
# La differenza con l'ordinamento è che qui esistono pezzi sbagliati, ed è lì
# l'insegnamento: la concordanza che non torna, la desinenza presa dalla
# declinazione sbagliata, l'ausiliare che in inglese va prima del soggetto, i
# due punti che in Python aprono il blocco.
const COMPOSE := {
	"italiano": [
		{"topic": "analisi-grammaticale", "minLevel": 1, "prompt": "Completa la frase scegliendo la forma che concorda.",
			"slots": [{"text": "Le"}, {"text": "bambine"}, {"text": ""}, {"text": "in giardino"}],
			"targets": [{"id": "a", "label": "corre"}, {"id": "b", "label": "corrono"}, {"id": "c", "label": "correva"}],
			"answer": "b",
			"explanation": "Il soggetto è plurale, quindi il verbo va al plurale: «le bambine corrono». Gli altri due sono verbi giusti con l'accordo sbagliato — ed è l'accordo, non il verbo, che questa prova chiede."},
		{"topic": "ortografia", "minLevel": 6, "prompt": "Completa la frase con la forma corretta.",
			"slots": [{"text": "Non so"}, {"text": ""}, {"text": "ne abbia parlato"}],
			"targets": [{"id": "a", "label": "se"}, {"id": "b", "label": "sé"}, {"id": "c", "label": "s'è"}],
			"answer": "a",
			"explanation": "Qui «se» introduce una domanda indiretta e non vuole accento. «Sé» è il pronome riflessivo, «s'è» sta per «si è»: tre parole diverse che suonano identiche."},
		{"topic": "punteggiatura", "minLevel": 9, "prompt": "Completa la frase: manca un segno.",
			"slots": [{"text": "Marco, il fratello di Anna"}, {"text": ""}, {"text": "è arrivato ieri"}],
			"targets": [{"id": "a", "label": ","}, {"id": "b", "label": ":"}, {"id": "c", "label": "niente"}],
			"answer": "a",
			"explanation": "L'inciso «il fratello di Anna» si è aperto con una virgola e va chiuso con l'altra: le due virgole sono una coppia, come due parentesi. Lasciarlo aperto attacca «Anna» al verbo, e a quel punto è Anna ad arrivare."},
		# Fascia 5. La concordanza dei tempi si sceglie, non si riconosce: qui il
		# tempo della principale è già dato, e la subordinata va messa in accordo.
		{"topic": "concordanza-tempi-verbali", "minLevel": 13, "prompt": "Completa: la principale è al passato, la subordinata deve guardare avanti da lì.",
			"slots": [{"text": "Marta promise che"}, {"text": ""}, {"text": "il giorno dopo"}],
			"targets": [{"id": "a", "label": "tornerà"}, {"id": "b", "label": "sarebbe tornata"}, {"id": "c", "label": "torna"}],
			"answer": "b",
			"explanation": "«Promise» colloca tutto nel passato: il futuro va misurato da quel momento, ed è «sarebbe tornata». «Tornerà» guarda avanti da oggi, ma nel racconto di allora oggi non esiste ancora."},
		# Fascia 7. Il periodo ipotetico della possibilità: le due metà si reggono
		# a vicenda, e sbagliarne una sola sbilancia tutta la frase.
		{"topic": "congiuntivo-condizionale", "minLevel": 19, "prompt": "Completa il periodo ipotetico: la prima metà è al congiuntivo imperfetto.",
			"slots": [{"text": "Se il ponte fosse più largo,"}, {"text": ""}, {"text": "passare in due"}],
			"targets": [{"id": "a", "label": "potremmo"}, {"id": "b", "label": "possiamo"}, {"id": "c", "label": "potremo"}],
			"answer": "a",
			"explanation": "Al congiuntivo imperfetto della condizione risponde il condizionale presente: «se fosse… potremmo». Le due metà vanno in coppia, e cambiarne una sola rompe l'accordo — «possiamo» direbbe che il ponte è già largo."},
		# Fascia 7. Il modo indefinito si sceglie dalla funzione: dopo una
		# preposizione l'italiano vuole l'infinito, non il gerundio.
		{"topic": "imperativo-infinito-participio-gerundio", "minLevel": 19, "prompt": "Completa: dopo «prima di» quale forma verbale può stare?",
			"slots": [{"text": "Controlla lo zaino prima di"}, {"text": ""}, {"text": "di casa"}],
			"targets": [{"id": "a", "label": "uscendo"}, {"id": "b", "label": "uscire"}, {"id": "c", "label": "uscito"}],
			"answer": "b",
			"explanation": "Dopo una preposizione il verbo va all'infinito: «prima di uscire». Il gerundio non regge una preposizione, e il participio da solo indicherebbe un'azione già conclusa."},
	],
	"latino": [
		{"topic": "declinazioni-base", "minLevel": 5, "prompt": "Completa la forma: accusativo singolare di «rosa».",
			"domande": [
				{"prompt": "Completa la forma: genitivo singolare di «rosa».", "answer": "b", "explanation": "Il genitivo singolare della prima declinazione esce in -ae, ed è la desinenza da cui si riconosce la declinazione stessa. La stessa forma vale anche come nominativo plurale: è il contesto a dire quale delle due sia."},
			],
			"slots": [{"text": "ros"}, {"text": ""}],
			"targets": [{"id": "a", "label": "-am"}, {"id": "b", "label": "-ae"}, {"id": "c", "label": "-is"}],
			"answer": "a",
			"explanation": "L'accusativo singolare della prima declinazione esce in -am. «-ae» è genitivo o nominativo plurale, «-is» appartiene alla terza: le desinenze sbagliate qui sono vere desinenze, prese dal posto sbagliato."},
		{"topic": "declinazione-2m", "minLevel": 8, "prompt": "Completa la forma: dativo singolare di «dominus».",
			"domande": [
				{"prompt": "Completa la forma: genitivo singolare di «dominus».", "answer": "c", "explanation": "Il genitivo della seconda esce in -i, e serve a dire «di chi»: *domini* è «del padrone». È la stessa uscita del nominativo plurale — due casi, una desinenza, e li separa solo la frase intorno."},
			],
			"slots": [{"text": "domin"}, {"text": ""}],
			"targets": [{"id": "a", "label": "-o"}, {"id": "b", "label": "-um"}, {"id": "c", "label": "-i"}],
			"answer": "a",
			"explanation": "Il dativo risponde a «a chi», e nella seconda declinazione esce in -o. «-um» è l'accusativo, cioè chi subisce l'azione: scambiarli cambia chi fa e chi riceve, che è la cosa che il caso serve a dire."},
		{"topic": "verbo-sum", "minLevel": 11, "prompt": "Completa la frase: «Roma ___ in Italia».",
			"slots": [{"text": "Roma"}, {"text": ""}, {"text": "in Italia"}],
			"targets": [{"id": "a", "label": "est"}, {"id": "b", "label": "sunt"}, {"id": "c", "label": "esse"}],
			"answer": "a",
			"explanation": "Roma è una sola città, e il verbo si accorda con chi compie l'azione: *sunt* servirebbe se le città fossero più d'una. *Esse* non è coniugato — è il verbo prima che qualcuno lo usi, come «essere» in italiano."},
	],
	"inglese": [
		{"topic": "question", "minLevel": 7, "prompt": "Completa la domanda mettendo l'ausiliare al posto giusto.",
			"domande": [
				{"prompt": "Quale ausiliare qui non può stare, perché va soltanto con «he», «she» o «it»?", "answer": "c", "explanation": "«Does» è la forma della terza persona singolare: con «you» si usa «do». Riconoscere dove NON va una forma è il modo più rapido per smettere di confonderle."},
			],
			"slots": [{"text": "Where"}, {"text": ""}, {"text": "you live?"}],
			"targets": [{"id": "a", "label": "do"}, {"id": "b", "label": "are"}, {"id": "c", "label": "does"}],
			"answer": "a",
			"explanation": "In inglese la domanda inverte: dopo il «where» viene l'ausiliare e poi il soggetto. Con «you» l'ausiliare è «do» — «does» vale solo per lui, lei, esso."},
		{"topic": "third-person", "minLevel": 7, "prompt": "Completa la frase con la forma giusta del verbo.",
			"slots": [{"text": "She"}, {"text": ""}, {"text": "to school every day"}],
			"targets": [{"id": "a", "label": "goes"}, {"id": "b", "label": "go"}, {"id": "c", "label": "going"}],
			"answer": "a",
			"explanation": "In inglese il verbo cambia in un punto solo di tutta la coniugazione: con *he*, *she*, *it* prende la -s. «Go» è la forma di tutti gli altri, e «going» ha bisogno di *is* davanti per reggersi in piedi."},
		{"topic": "irregular-past", "minLevel": 13, "prompt": "Completa la frase al passato.",
			"domande": [
				{"prompt": "Quale delle tre forme non esiste in inglese, perché applica una regola dove non vale?", "answer": "b", "explanation": "«Goed» nasce dalla regola giusta — passato in -ed — applicata a un verbo che non la segue. È l'errore che fanno anche i bambini inglesi, ed è la prova che la regola è stata capita: manca solo la lista delle eccezioni."},
			],
			"slots": [{"text": "Yesterday I"}, {"text": ""}, {"text": "to the park"}],
			"targets": [{"id": "a", "label": "went"}, {"id": "b", "label": "goed"}, {"id": "c", "label": "gone"}],
			"answer": "a",
			"explanation": "I verbi irregolari cambiano parola invece di prendere una desinenza, e vanno imparati a coppie. «Gone» esiste, ma non regge da sola: chiede *have* davanti, e senza resta a metà."},
		# --- I tempi composti (8 settembre 2026) ------------------------------
		{"topic": "present-perfect", "minLevel": 16, "prompt": "Completa la frase con la forma giusta.",
			"domande": [
				{"prompt": "Quale forma non può stare dopo «has», perché non è un participio?", "answer": "b", "explanation": "«Went» è il passato semplice, e il passato semplice non regge mai dopo un ausiliare. Dopo «have» o «has» ci va sempre la terza forma del verbo, quella della tabella."},
			],
			"slots": [{"text": "She has"}, {"text": ""}, {"text": "to London twice"}],
			"targets": [{"id": "a", "label": "been"}, {"id": "b", "label": "went"}, {"id": "c", "label": "gone"}],
			"answer": "a",
			"explanation": "«Been» dice che ci è andata ed è tornata; «gone» direbbe che è partita e non c'è più — e con «twice» non tornerebbe. È la differenza più utile della coppia, e la sola che cambia il senso della frase."},
		{"topic": "conditionals", "minLevel": 19, "prompt": "Completa la conseguenza del terzo tipo.",
			"domande": [
				{"prompt": "Quale forma parla del presente e non del passato ormai perduto?", "answer": "c", "explanation": "«Would pass» è il condizionale semplice, e guarda a una cosa ancora possibile adesso. Il terzo tipo parla di un passato che non si può più cambiare, e chiede il condizionale composto."},
			],
			"slots": [{"text": "If you had studied, you"}, {"text": ""}, {"text": "the exam"}],
			"targets": [{"id": "a", "label": "would have passed"}, {"id": "b", "label": "will have passed"}, {"id": "c", "label": "would pass"}],
			"answer": "a",
			"explanation": "Nel terzo tipo la condizione sta al trapassato e la conseguenza al condizionale composto: la frase racconta quello che sarebbe successo e non è successo. È il tempo del rimpianto."},
		# --- La grammatica delle prime fasce (9 settembre 2026) ---------------
		{"topic": "to-be", "minLevel": 1, "prompt": "Completa la frase con la forma giusta del verbo essere.",
			"slots": [{"text": "My sister"}, {"text": ""}, {"text": "twelve"}],
			"targets": [{"id": "a", "label": "is"}, {"id": "b", "label": "am"}, {"id": "c", "label": "are"}],
			"answer": "a",
			"explanation": "«My sister» e' una persona sola come «she», e prende «is». «Am» esiste solo per «I» — e' l'unica forma di tutta la lingua che appartiene a una persona sola — mentre «are» serve al plurale."},
		{"topic": "have-got", "minLevel": 4, "prompt": "Completa la frase con la forma giusta di «have got».",
			"domande": [
				{"prompt": "Quale forma qui non puo' stare, perche' e' il verbo essere e non il possesso?", "answer": "c", "explanation": "«Is» dice com'e' una cosa, non che cosa possiede. Il possesso lo dice «have got», e la prova e' che dopo «is» la parola «got» non avrebbe nessun posto dove stare."},
			],
			"slots": [{"text": "She"}, {"text": ""}, {"text": "got a new bike"}],
			"targets": [{"id": "a", "label": "has"}, {"id": "b", "label": "have"}, {"id": "c", "label": "is"}],
			"answer": "a",
			"explanation": "Con lei cambia solo la prima parola del verbo: «has got». «Got» resta ferma per tutte le persone, ed e' questo che rende la coppia facile: c'e' un pezzo solo da accordare."},
		{"topic": "there-is", "minLevel": 4, "prompt": "Completa la frase.",
			"slots": [{"text": ""}, {"text": "some milk in the fridge"}],
			"targets": [{"id": "a", "label": "There is"}, {"id": "b", "label": "There are"}, {"id": "c", "label": "It is"}],
			"answer": "a",
			"explanation": "Il latte si misura, non si conta: resta singolare anche quando e' tanto, e vuole «there is». «It is» direbbe com'e' il latte, non che ce n'e' — sono due frasi diverse che in italiano cominciano quasi uguali."},
		{"topic": "quantifiers", "minLevel": 7, "prompt": "Completa la domanda.",
			"slots": [{"text": "How"}, {"text": ""}, {"text": "sugar do you need?"}],
			"targets": [{"id": "a", "label": "much"}, {"id": "b", "label": "many"}, {"id": "c", "label": "long"}],
			"answer": "a",
			"explanation": "Lo zucchero si pesa e non ha plurale: prende «much». «Many» chiederebbe quanti zuccheri, che non vuol dire niente — ed e' proprio il plurale mancante il segnale da cercare, prima ancora della parola."},
		{"topic": "future", "minLevel": 13, "prompt": "Completa la frase guardando la prova che c'e' gia'.",
			"domande": [
				{"prompt": "Quale forma userebbe chi decide proprio adesso, senza nessuna prova davanti?", "answer": "b", "explanation": "«Will» e' il futuro della decisione presa mentre si parla: si usa per offerte, promesse e previsioni senza appoggio. Qui invece le nuvole sono gia' li', e la prova esclude la decisione improvvisa."},
			],
			"slots": [{"text": "Look at those clouds! It"}, {"text": ""}, {"text": "rain"}],
			"targets": [{"id": "a", "label": "is going to"}, {"id": "b", "label": "will"}, {"id": "c", "label": "rains"}],
			"answer": "a",
			"explanation": "Quando la prova e' sotto gli occhi l'inglese usa «going to»: il futuro e' gia' cominciato qui, e si vede. «Will» servirebbe a una previsione senza appoggio, e il presente semplice a un orario fisso."},
		{"topic": "relatives", "minLevel": 16, "prompt": "Completa la frase con il pronome relativo giusto.",
			"slots": [{"text": "The book"}, {"text": ""}, {"text": "I bought yesterday is long"}],
			"targets": [{"id": "a", "label": "that"}, {"id": "b", "label": "who"}, {"id": "c", "label": "whose"}],
			"answer": "a",
			"explanation": "«That» vale per le cose e puo' sostituire «which». «Who» e' riservato alle persone e «whose» dice di chi e' una cosa: l'italiano se la cava con «che» in tutti e tre i casi, e per questo qui bisogna guardare di che cosa si parla."},
		{"topic": "past-perfect", "minLevel": 22, "prompt": "Completa la frase mettendo in ordine i due passati.",
			"slots": [{"text": "The train"}, {"text": ""}, {"text": "before we arrived"}],
			"targets": [{"id": "a", "label": "had left"}, {"id": "b", "label": "has left"}, {"id": "c", "label": "leaves"}],
			"answer": "a",
			"explanation": "«Before we arrived» mette la frase nel passato e chiede quale dei due fatti viene prima: quello piu' antico arretra con «had». «Has left» terrebbe il filo con adesso, e qui il filo e' gia' tagliato dall'arrivo."},
		{"topic": "connectors", "minLevel": 13, "prompt": "Completa la frase con il connettivo che dice il rapporto giusto.",
			"domande": [
				{"prompt": "Quale connettivo useresti per aggiungere un secondo motivo invece di opporlo?", "answer": "c", "explanation": "«And» somma e basta: mette due cose sullo stesso piano senza dire che una contrasta con l'altra. E' il connettivo che si usa quando non c'e' nessun rapporto da segnalare oltre l'aggiunta."},
			],
			"slots": [{"text": "I wanted to go out,"}, {"text": ""}, {"text": "it was raining hard"}],
			"targets": [{"id": "a", "label": "but"}, {"id": "b", "label": "because"}, {"id": "c", "label": "and"}],
			"answer": "a",
			"explanation": "Le due meta' si contrastano: volevo uscire, la pioggia lo ha impedito. «Because» direbbe che sono uscito A CAUSA della pioggia, e «and» le metterebbe una accanto all'altra come se non c'entrassero niente."},
	],
	"coding": [
		{"topic": "sequenza", "minLevel": 4, "prompt": "Completa la riga perché il ciclo sia sintatticamente valido.",
			"domande": [
				{"prompt": "Quale segno chiuderebbe la riga in un linguaggio come C o Java, ma qui è di troppo?", "answer": "b", "explanation": "Il punto e virgola chiude l'istruzione in molti linguaggi, e chi arriva da lì lo scrive per abitudine. In Python non serve: la riga finisce dove finisce."},
			],
			"slots": [{"text": "for i in range(5)"}, {"text": ""}],
			"targets": [{"id": "a", "label": ":"}, {"id": "b", "label": ";"}, {"id": "c", "label": "niente"}],
			"answer": "a",
			"explanation": "In Python i due punti aprono il blocco: senza, l'interprete non sa dove comincia il corpo del ciclo. Il punto e virgola non serve, ed è l'abitudine che arriva da altri linguaggi."},
		{"topic": "condizioni", "minLevel": 8, "prompt": "Completa la condizione: deve CONFRONTARE, non assegnare.",
			"slots": [{"text": "if x"}, {"text": ""}, {"text": "5:"}],
			"targets": [{"id": "a", "label": "=="}, {"id": "b", "label": "="}, {"id": "c", "label": "=<"}],
			"answer": "a",
			"explanation": "Un segno solo mette dentro x il valore 5 e cancella quello che c'era; ne servono due per chiedere se sono uguali. È lo stesso simbolo per due lavori opposti, ed è il motivo per cui il doppio esiste. «=<» invece è scritto al contrario: il minore-o-uguale si scrive «<=»."},
		{"topic": "liste", "minLevel": 12, "prompt": "Completa la riga per prendere il PRIMO nome della lista.",
			"slots": [{"text": "primo = nomi"}, {"text": ""}],
			"targets": [{"id": "a", "label": "[0]"}, {"id": "b", "label": "[1]"}, {"id": "c", "label": "(0)"}],
			"answer": "a",
			"explanation": "Le caselle di una lista si contano da zero, quindi il primo nome sta nella casella 0 e «[1]» consegna il secondo. Le parentesi tonde invece chiamano una funzione: chiedono alla lista di *fare* qualcosa, non di dare quello che ha dentro."},
	],
	"musica": [
		{"topic": "intervalli", "minLevel": 12, "prompt": "Completa l'accordo di Do maggiore.",
			"domande": [
				{"prompt": "Quale di queste note è a un solo grado da Do, cioè troppo vicina per far parte dell'accordo?", "answer": "c", "explanation": "Re è la nota subito dopo Do: fra le due c'è una seconda, e l'accordo maggiore è fatto di terze. Sentire che Re «stona» dentro Do-Sol è il modo in cui si impara la distanza prima del nome."},
			],
			"slots": [{"text": "Do"}, {"text": ""}, {"text": "Sol"}],
			"targets": [{"id": "a", "label": "Mi"}, {"id": "b", "label": "Fa"}, {"id": "c", "label": "Re"}],
			"answer": "a",
			"explanation": "L'accordo maggiore è fondamentale, terza maggiore e quinta: Do-Mi-Sol. Fa e Re sono note vicinissime, e proprio per questo sono l'errore che si fa davvero."},
		{"topic": "note", "minLevel": 6, "prompt": "Completa la scala salendo da Do.",
			"slots": [{"text": "Do Re Mi"}, {"text": ""}, {"text": "Sol"}],
			"targets": [{"id": "a", "label": "Fa"}, {"id": "b", "label": "Fa#"}, {"id": "c", "label": "La"}],
			"answer": "a",
			"explanation": "Le sette note salgono in fila e nessuna si salta: dopo Mi viene Fa, e chi mette La ne salta due. Il diesis alzerebbe Fa di mezzo gradino, ma fra Mi e Fa quel mezzo gradino c'è già — è il punto in cui la scala si stringe da sola."},
		{"topic": "ritmo", "minLevel": 6, "prompt": "Completa la battuta: in 4/4 devono starci quattro movimenti.",
			"slots": [{"text": "semiminima"}, {"text": "semiminima"}, {"text": ""}],
			"targets": [{"id": "a", "label": "minima"}, {"id": "b", "label": "semibreve"}, {"id": "c", "label": "croma"}],
			"answer": "a",
			"explanation": "Le due semiminime valgono un movimento ciascuna, quindi ne restano due da riempire e la minima ne dura esattamente due. La semibreve ne dura quattro e sfonda la battuta; la croma ne dura mezzo e la lascia a metà."},
	],
	"matematica": [
		{"topic": "calcolo", "minLevel": 6, "prompt": "Completa l'espressione perché il risultato sia 20.",
			"domande": [
				{"prompt": "Completa l'espressione perché il risultato sia 9.", "answer": "b", "explanation": "Quattro più cinque fa nove. Partire dal risultato e cercare l'operazione è il gesto che serve nei problemi: lì il numero d'arrivo è dato e la strada no."},
				{"prompt": "Completa l'espressione perché il risultato sia −1.", "answer": "c", "explanation": "Quattro meno cinque fa meno uno. Il segno negativo dice che si è tolto più di quanto c'era: è il primo incontro con i numeri sotto lo zero, e qui si vede da dove nascono."},
			],
			"slots": [{"text": "4"}, {"text": ""}, {"text": "5"}],
			"targets": [{"id": "a", "label": "×"}, {"id": "b", "label": "+"}, {"id": "c", "label": "−"}],
			"answer": "a",
			"explanation": "Quattro per cinque fa venti. Scegliere l'operazione invece di eseguirla obbliga a ragionare al contrario, partendo dal risultato — che è quello che serve per risolvere un problema."},
		{"topic": "frazioni", "minLevel": 10, "prompt": "Completa perché le due frazioni valgano lo stesso.",
			"slots": [{"text": "1/2"}, {"text": "="}, {"text": ""}, {"text": "/8"}],
			"targets": [{"id": "a", "label": "4"}, {"id": "b", "label": "2"}, {"id": "c", "label": "8"}],
			"answer": "a",
			"explanation": "Sotto si è passati da 2 a 8, cioè per quattro: sopra va fatto lo stesso viaggio, altrimenti si è tagliata la torta in più fette senza prenderne di più. Chi scrive 2 ha cambiato solo il numero sotto, e mezza torta è diventata un quarto."},
		{"topic": "geometria", "minLevel": 12, "prompt": "Completa la formula dell'AREA del rettangolo.",
			"domande": [
				{"prompt": "Completa la formula del PERIMETRO del rettangolo: quale segno unisce base e altezza?", "answer": "b", "explanation": "Il perimetro è un giro tutto intorno, e i lati si percorrono uno dopo l'altro: si sommano. È l'unico dei due conti che si può fare camminando col dito sul bordo."},
			],
			"slots": [{"text": "base"}, {"text": ""}, {"text": "altezza"}],
			"targets": [{"id": "a", "label": "×"}, {"id": "b", "label": "+"}, {"id": "c", "label": "−"}],
			"answer": "a",
			"explanation": "L'area conta i quadretti che stanno dentro, e i quadretti si contano a righe per colonne: è la stessa griglia della tabellina. Sommare base e altezza dà una lunghezza, non una superficie — cioè un pezzo di contorno, che è l'altra domanda."},
	],
}

# TRACCIATORE: si ESEGUE passo per passo e si dichiara lo stato finale.
#
# Insegna la cosa più difficile da dire a parole — che una sequenza si simula,
# non si indovina. È la tabella di traccia di chi programma, ed è lo stesso
# gesto con cui si segue la corrente in un circuito o l'acqua in un bacino.
const TRACE := {
	"coding": [
		{"topic": "algoritmi", "minLevel": 5, "prompt": "Segui il ciclo: quanto vale il contatore alla fine?",
			"steps": [{"label": "i = 0", "state": "0"}, {"label": "primo giro: i = i + 3", "state": "3"}, {"label": "secondo giro: i = i + 3", "state": "6"}, {"label": "terzo giro: i = i + 3", "state": ""}],
			"targets": [{"id": "a", "label": "6"}, {"id": "b", "label": "9"}, {"id": "c", "label": "12"}],
			"answer": "b",
			"explanation": "Ogni giro aggiunge tre: 0, 3, 6, 9. È la tabella di traccia, e si compila una riga per volta — provare a indovinare il risultato finale senza scriverlo è dove si sbaglia."},
		{"topic": "algoritmi", "minLevel": 11, "prompt": "Segui il ciclo: quanto vale il totale alla fine?",
			"steps": [{"label": "totale = 1", "state": "1"}, {"label": "totale = totale × 2", "state": "2"}, {"label": "totale = totale × 2", "state": "4"}, {"label": "totale = totale × 2", "state": ""}],
			"targets": [{"id": "a", "label": "6"}, {"id": "b", "label": "8"}, {"id": "c", "label": "16"}],
			"answer": "b",
			"explanation": "Raddoppiando tre volte da 1 si arriva a 8, non a 6: moltiplicare ripetutamente non è sommare. È la differenza fra crescita lineare ed esponenziale, vista su tre righe."},
	],
	"matematica": [
		{"topic": "calcolo", "minLevel": 1, "prompt": "Segui i passi: quale numero ottieni?",
			"steps": [{"label": "parti da 2", "state": "2"}, {"label": "aggiungi 1", "state": "3"}, {"label": "aggiungi ancora 1", "state": ""}],
			"targets": [{"id": "a", "label": "3"}, {"id": "b", "label": "4"}, {"id": "c", "label": "5"}],
			"answer": "b",
			"explanation": "Si esegue un passo alla volta: 2 diventa 3 e poi 4. Il tracciato rende visibile lo stato dopo ogni azione, prima di introdurre operazioni piu lunghe."},
		{"topic": "calcolo", "minLevel": 4, "prompt": "Applica le operazioni in ordine: che numero esce?",
			"steps": [{"label": "parti da 7", "state": "7"}, {"label": "aggiungi 5", "state": "12"}, {"label": "dividi per 3", "state": "4"}, {"label": "moltiplica per 10", "state": ""}],
			"targets": [{"id": "a", "label": "40"}, {"id": "b", "label": "34"}, {"id": "c", "label": "120"}],
			"answer": "a",
			"explanation": "Quattro per dieci fa quaranta. L'ordine conta: cambiando l'ultimo passo con il secondo il risultato sarebbe diverso, ed è la ragione per cui le operazioni si eseguono una per volta."},
	],
	"elettronica": [
		{"topic": "circuito", "minLevel": 9, "prompt": "Segui la corrente: che cosa succede alla lampadina?",
			"steps": [{"label": "la pila fornisce tensione", "state": "corrente presente"}, {"label": "l'interruttore è chiuso", "state": "corrente passa"}, {"label": "il secondo interruttore si apre", "state": ""}],
			"targets": [{"id": "a", "label": "resta accesa"}, {"id": "b", "label": "si spegne"}, {"id": "c", "label": "diventa più forte"}],
			"answer": "b",
			"explanation": "In serie basta un'interruzione qualunque per fermare tutto: non conta che il primo interruttore sia chiuso. È il motivo per cui le vecchie file di lucine si spegnevano tutte insieme."},
	],
	"geografia": [
		{"topic": "geografia-fisica", "minLevel": 8, "prompt": "Segui l'acqua che cade sulle Alpi: dove finisce?",
			"steps": [{"label": "pioggia sulle Alpi", "state": "torrente"}, {"label": "il torrente scende a valle", "state": "affluente"}, {"label": "l'affluente entra nel Po", "state": "fiume"}, {"label": "il Po arriva alla fine del suo corso", "state": ""}],
			"targets": [{"id": "a", "label": "mar Tirreno"}, {"id": "b", "label": "mare Adriatico"}, {"id": "c", "label": "lago di Garda"}],
			"answer": "b",
			"explanation": "Il Po scorre da ovest a est e sfocia nell'Adriatico. Seguire l'acqua passo per passo è anche il modo in cui si legge un bacino idrografico su una carta."},
	],
	# Fino al 1 settembre 2026 la logica aveva UNA traccia sola, e valeva il 3,3%
	# dei nodi di un mondo: la stessa identica prova, per sempre. Adesso sono tre
	# e chiedono tre esiti diversi — nessuno resta, restano in due, resta uno —
	# perché è proprio l'esito a non dover essere prevedibile.
	"logica": [
		{"topic": "deduzioni", "minLevel": 7, "prompt": "Applica le eliminazioni in ordine: chi resta?",
			"steps": [{"label": "in gara: Ada, Bruno, Carla, Dino", "state": "4 rimasti"}, {"label": "non è un maschio", "state": "Ada, Carla"}, {"label": "il nome non finisce per -a", "state": ""}],
			"targets": [{"id": "a", "label": "Ada"}, {"id": "b", "label": "Carla"}, {"id": "c", "label": "nessuno"}],
			"answer": "c",
			"explanation": "Dopo la prima eliminazione restano due nomi che finiscono entrambi per -a: la seconda condizione li toglie tutti. Un indovinello può non avere soluzione, e accorgersene è parte del ragionamento."},
		{"topic": "deduzioni", "minLevel": 7, "prompt": "Applica i filtri in ordine: quali carte restano?",
			"steps": [{"label": "sul tavolo: 2, 5, 8, 9, 12", "state": "5 carte"}, {"label": "togli le dispari", "state": "2, 8, 12"}, {"label": "togli quelle minori di 5", "state": ""}],
			"targets": [{"id": "a", "label": "solo la 12"}, {"id": "b", "label": "8 e 12"}, {"id": "c", "label": "2, 8 e 12"}],
			"answer": "b",
			"explanation": "Ogni filtro lavora su ciò che il precedente ha lasciato, non sul mazzo di partenza: dopo il primo restano 2, 8 e 12, e il secondo toglie solo il 2. Chi riparte ogni volta dalle cinque carte iniziali ottiene un risultato diverso — ed è l'errore che si fa più spesso."},
		{"topic": "insiemi", "minLevel": 9, "prompt": "Applica le condizioni in ordine: quali numeri restano?",
			"steps": [{"label": "i numeri da 1 a 10", "state": "10 numeri"}, {"label": "tieni solo i pari", "state": "2, 4, 6, 8, 10"}, {"label": "tieni solo i multipli di 3", "state": ""}],
			"targets": [{"id": "a", "label": "solo il 6"}, {"id": "b", "label": "6 e 9"}, {"id": "c", "label": "3, 6 e 9"}],
			"answer": "a",
			"explanation": "Due condizioni una dopo l'altra danno l'intersezione: sopravvive solo chi le soddisfa entrambe. Il 9 è multiplo di 3 ma è già stato tolto dal filtro dei pari, e nella traccia ciò che è uscito non rientra: resta il 6, l'unico numero fino a dieci che è pari e multiplo di 3 insieme."},
	],
}

# BILANCIA: due cose diverse che pesano uguale.
#
# È l'unico formato che MOSTRA l'equivalenza invece di chiederla — un'equazione
# è una bilancia — e fino al 5 agosto 2026 nessun formato la rendeva visibile.
#
# La struttura si adatta cambiando che cosa significa «pesare»: in matematica il
# valore, in fisica il momento (peso per distanza), in elettronica la resistenza
# in serie, in logica la cardinalità, in musica la DURATA — dove pareggiare vuol
# dire riempire esattamente la battuta, e avanzare spazio è sbagliato quanto
# traboccare.
#
# `exercise_interaction._validate_balance` verifica l'aritmetica, non la forma:
# la risposta deve pareggiare davvero e gli altri candidati no.
const BALANCE := {
	"matematica": [
		{"topic": "calcolo", "minLevel": 1, "prompt": "Che cosa manca per avere la stessa quantita sui due piatti?",
			"left": [{"label": "3", "value": 3.0}, {"label": "2", "value": 2.0}],
			"right": [{"label": "3", "value": 3.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "1", "value": 1.0}, {"id": "b", "label": "2", "value": 2.0}, {"id": "c", "label": "3", "value": 3.0}],
			"answer": "b",
			"explanation": "A sinistra ci sono cinque unita e a destra tre: ne mancano due. La bilancia introduce l'uguaglianza con quantita piccole prima delle espressioni."},
		{"topic": "calcolo", "minLevel": 5, "prompt": "Che cosa manca perché i due piatti pesino uguale?",
			"left": [{"label": "7", "value": 7.0}, {"label": "5", "value": 5.0}],
			"right": [{"label": "9", "value": 9.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "1", "value": 1.0}, {"id": "b", "label": "3", "value": 3.0}, {"id": "c", "label": "5", "value": 5.0}],
			"answer": "b",
			"explanation": "A sinistra ci sono 12, a destra 9: manca esattamente la differenza. Un'equazione è una bilancia, e «togliere da una parte» significa sempre togliere anche dall'altra."},
		{"topic": "calcolo", "minLevel": 9, "prompt": "Che cosa manca perché i due piatti pesino uguale?",
			"left": [{"label": "4 × 3", "value": 12.0}],
			"right": [{"label": "8", "value": 8.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "2", "value": 2.0}, {"id": "b", "label": "4", "value": 4.0}, {"id": "c", "label": "6", "value": 6.0}],
			"answer": "b",
			"explanation": "Due espressioni scritte in modo diverso possono pesare uguale: 4 × 3 vale 12 come 8 + 4. È questo che vuol dire «uguale» in matematica — stesso valore, non stessa forma."},
		{"topic": "frazioni", "minLevel": 12, "prompt": "Che cosa manca perché i due piatti pesino uguale?",
			"left": [{"label": "1", "value": 1.0}],
			"right": [{"label": "1/2", "value": 0.5}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "1/4", "value": 0.25}, {"id": "b", "label": "1/2", "value": 0.5}, {"id": "c", "label": "3/4", "value": 0.75}],
			"answer": "b",
			"explanation": "Due mezzi fanno un intero. Sulla bilancia si vede che 1/2 + 1/2 pesa quanto 1, senza dover ridurre allo stesso denominatore."},
	],
	"fisica": [
		{"topic": "galleggiamento", "minLevel": 13, "prompt": "Il pezzo di legno resta fermo a mezz'acqua: peso e spinta si pareggiano. Quanto vale la spinta dell'acqua?",
			"left": [{"label": "Peso: 6 N", "value": 6.0}],
			"right": [],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "3 N", "value": 3.0}, {"id": "b", "label": "6 N", "value": 6.0}, {"id": "c", "label": "12 N", "value": 12.0}],
			"answer": "b",
			"explanation": "Fermo vuol dire pareggiato: se il peso tira giù con 6 newton, l'acqua deve spingere su con 6 newton esatti. Con meno andrebbe a fondo, con più risalirebbe."},
		{"topic": "forze", "minLevel": 8, "prompt": "La leva è in equilibrio. Quale peso manca a destra, a 1 metro dal fulcro?",
			"left": [{"label": "2 kg a 3 m", "value": 6.0}],
			"right": [],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "2 kg", "value": 2.0}, {"id": "b", "label": "4 kg", "value": 4.0}, {"id": "c", "label": "6 kg", "value": 6.0}],
			"answer": "c",
			"explanation": "Su una leva non conta il peso ma il momento: peso per distanza. Due chili a tre metri fanno sei, e per pareggiare a un solo metro servono sei chili. È il motivo per cui un bambino può sollevare un adulto stando più lontano dal fulcro."},
	],
	"elettronica": [
		{"topic": "serie-parallelo", "minLevel": 20, "prompt": "Le due serie devono avere la stessa resistenza totale. Quale resistore manca?",
			"left": [{"label": "100 Ω", "value": 100.0}, {"label": "220 Ω", "value": 220.0}],
			"right": [{"label": "150 Ω", "value": 150.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "100 Ω", "value": 100.0}, {"id": "b", "label": "150 Ω", "value": 150.0}, {"id": "c", "label": "170 Ω", "value": 170.0}],
			"answer": "c",
			"explanation": "In serie le resistenze si sommano e basta: 100 + 220 fa 320, e per arrivarci da 150 ne mancano 170. In parallelo invece il totale è più piccolo del più piccolo — è l'errore più comune."},
	],
	"musica": [
		{"topic": "ritmo", "minLevel": 6, "prompt": "La battuta di 4/4 deve essere piena. Quale figura la completa?",
			"left": [{"label": "battuta 4/4", "value": 4.0}],
			"right": [{"label": "minima", "value": 2.0}, {"label": "semiminima", "value": 1.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "croma", "value": 0.5}, {"id": "b", "label": "semiminima", "value": 1.0}, {"id": "c", "label": "minima", "value": 2.0}],
			"answer": "b",
			"explanation": "Qui «pareggiare» vuol dire riempire la battuta: né una figura in meno né una in più. Minima più semiminima fanno tre movimenti su quattro, quindi manca una semiminima. Se avanzasse spazio la battuta sarebbe sbagliata quanto se traboccasse."},
		{"topic": "ritmo", "minLevel": 12, "prompt": "La battuta di 3/4 deve essere piena. Quale figura la completa?",
			"left": [{"label": "battuta 3/4", "value": 3.0}],
			"right": [{"label": "semiminima puntata", "value": 1.5}, {"label": "croma", "value": 0.5}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "croma", "value": 0.5}, {"id": "b", "label": "semiminima", "value": 1.0}, {"id": "c", "label": "minima", "value": 2.0}],
			"answer": "b",
			"explanation": "Il punto aggiunge la metà: la semiminima puntata vale 1,5 movimenti. Con la croma si arriva a 2, e per chiudere il 3/4 manca una semiminima intera."},
	],
	# **La bilancia della logica era una sottrazione.** (1 settembre 2026)
	#
	# C'era una specifica sola — «a sinistra 7 elementi, a destra 4, quanti ne
	# mancano?» — e valeva il 2,5% dei nodi di un mondo di logica. Sempre la
	# stessa, e per giunta era 7 − 4: aritmetica di prima elementare con
	# l'etichetta della logica sopra.
	#
	# Adesso sono tre, e in tutte e tre il numero non è dato: va ricavato da come
	# stanno gli insiemi. È la stessa competenza di «uno dentro l'altro / si
	# sovrappongono / separati», con i numeri al posto delle parole.
	"logica": [
		{"topic": "insiemi", "minLevel": 7, "prompt": "In classe: 12 fanno nuoto, 8 fanno musica, e 17 ne fanno almeno una delle due. Quanti sono stati contati due volte?",
			"left": [{"label": "nuoto: 12", "value": 12.0}, {"label": "musica: 8", "value": 8.0}],
			"right": [{"label": "almeno una delle due: 17", "value": 17.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "2 ragazzi", "value": 2.0}, {"id": "b", "label": "3 ragazzi", "value": 3.0}, {"id": "c", "label": "5 ragazzi", "value": 5.0}],
			"answer": "b",
			"explanation": "Sommando i due gruppi, chi fa tutte e due le cose viene contato una volta di troppo. Per questo 12 + 8 fa 20 mentre le persone sono 17: i 3 di differenza non sono spariti, sono stati contati due volte. Chi somma due insiemi che si sovrappongono deve sempre togliere l'intersezione."},
		{"topic": "insiemi", "minLevel": 7, "prompt": "Nel gruppo ci sono 20 persone e 15 hanno il cane. Quante NON ce l'hanno?",
			"left": [{"label": "tutto il gruppo: 20", "value": 20.0}],
			"right": [{"label": "chi ha il cane: 15", "value": 15.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "3 persone", "value": 3.0}, {"id": "b", "label": "5 persone", "value": 5.0}, {"id": "c", "label": "8 persone", "value": 8.0}],
			"answer": "b",
			"explanation": "Chi non ha il cane è il complementare: tutto ciò che sta dentro il gruppo e fuori dall'insieme. Non serve andarli a cercare uno per uno — il gruppo intero meno la parte nota lascia esattamente il resto, e l'insieme e il suo complementare insieme rifanno sempre il tutto."},
		{"topic": "insiemi", "minLevel": 9, "prompt": "Da 1 a 20: quanti ne mancano a sinistra perché i due gruppi siano pari?",
			"left": [{"label": "i multipli di 3 da 1 a 20", "value": 6.0}],
			"right": [{"label": "i numeri primi da 1 a 20", "value": 8.0}],
			"gapSide": "left",
			"targets": [{"id": "a", "label": "1 numero", "value": 1.0}, {"id": "b", "label": "2 numeri", "value": 2.0}, {"id": "c", "label": "4 numeri", "value": 4.0}],
			"answer": "b",
			"explanation": "Qui i due numeri non sono scritti da nessuna parte: vanno costruiti. I multipli di 3 fino a 20 sono 3, 6, 9, 12, 15, 18 — sei. I primi sono 2, 3, 5, 7, 11, 13, 17, 19 — otto, e il 2 ci sta dentro anche se è pari, perché primo vuol dire divisibile solo per uno e per sé stesso. Otto meno sei fa due."},
	],
}

# RETTA NUMERICA: un numero smette di essere un simbolo e diventa una posizione.
#
# Aggiunta il 5 agosto 2026 perché a livello 1 matematica non aveva NESSUN
# formato visuale: solo abbinamenti, ordinamenti e smistamenti, tutti di testo.
# È anche il posto in cui frazioni, decimali e negativi diventano confrontabili
# a occhio invece che a regola.
const NUMBER_LINE := {
	"matematica": [
		{"topic": "numeri", "prompt": "Quale punto sta sul 7?", "min": 0.0, "max": 10.0, "tick": 1.0,
			"labels": [{"value": 0.0, "text": "0"}, {"value": 5.0, "text": "5"}, {"value": 10.0, "text": "10"}],
			"targets": [{"id": "a", "label": "Punto sul 3", "value": 3.0}, {"id": "b", "label": "Punto sul 7", "value": 7.0}, {"id": "c", "label": "Punto sul 9", "value": 9.0}],
			"answer": "b",
			"explanation": "Il 7 sta fra il 5 e il 10, più vicino al 5. Contare le tacche dal riferimento più vicino è più rapido che contarle da zero."},
		{"topic": "numeri", "prompt": "Quale punto sta esattamente a metà fra 0 e 10?", "min": 0.0, "max": 10.0, "tick": 1.0,
			"labels": [{"value": 0.0, "text": "0"}, {"value": 10.0, "text": "10"}],
			"targets": [{"id": "a", "label": "Punto sul 4", "value": 4.0}, {"id": "b", "label": "Punto sul 5", "value": 5.0}, {"id": "c", "label": "Punto sul 6", "value": 6.0}],
			"answer": "b",
			"explanation": "La metà si trova sommando gli estremi e dividendo per due: (0 + 10) / 2 = 5. Sulla retta è il punto equidistante dai due capi."},
		{"topic": "frazioni", "minLevel": 4, "prompt": "Quale punto corrisponde a 1/2?", "min": 0.0, "max": 2.0, "tick": 0.5,
			"labels": [{"value": 0.0, "text": "0"}, {"value": 1.0, "text": "1"}, {"value": 2.0, "text": "2"}],
			"targets": [{"id": "a", "label": "Punto su un mezzo", "value": 0.5}, {"id": "b", "label": "Punto su uno e mezzo", "value": 1.5}, {"id": "c", "label": "Punto su due", "value": 2.0}],
			"answer": "a",
			"explanation": "Una frazione minore di 1 sta fra lo zero e l'uno: 1/2 è a metà di quel primo tratto, non a metà di tutta la retta."},
		{"topic": "frazioni", "minLevel": 6, "prompt": "Quale punto corrisponde a 3/4?", "min": 0.0, "max": 1.0, "tick": 0.25,
			"labels": [{"value": 0.0, "text": "0"}, {"value": 0.5, "text": "1/2"}, {"value": 1.0, "text": "1"}],
			"targets": [{"id": "a", "label": "Punto su un quarto", "value": 0.25}, {"id": "b", "label": "Punto su un mezzo", "value": 0.5}, {"id": "c", "label": "Punto su tre quarti", "value": 0.75}],
			"answer": "c",
			"explanation": "Diviso il tratto in quattro parti uguali, 3/4 è la terza tacca: più di 1/2 e meno di 1. Confrontare le frazioni sulla retta evita di doverle ridurre allo stesso denominatore."},
		{"topic": "numeri", "minLevel": 8, "prompt": "Quale punto sta su −3?", "min": -5.0, "max": 5.0, "tick": 1.0,
			"labels": [{"value": -5.0, "text": "-5"}, {"value": 0.0, "text": "0"}, {"value": 5.0, "text": "5"}],
			"targets": [{"id": "a", "label": "Punto su meno tre", "value": -3.0}, {"id": "b", "label": "Punto su zero", "value": 0.0}, {"id": "c", "label": "Punto su tre", "value": 3.0}],
			"answer": "a",
			"explanation": "I negativi stanno a sinistra dello zero, e più il numero è grande più si va lontano: −3 è più a sinistra di −1, anche se «tre» è più di «uno»."},
		{"topic": "numeri", "minLevel": 10, "prompt": "Quale punto corrisponde a 2,5?", "min": 0.0, "max": 5.0, "tick": 0.5,
			"labels": [{"value": 0.0, "text": "0"}, {"value": 2.0, "text": "2"}, {"value": 5.0, "text": "5"}],
			"targets": [{"id": "a", "label": "Punto su due", "value": 2.0}, {"id": "b", "label": "Punto su due e cinque", "value": 2.5}, {"id": "c", "label": "Punto su tre", "value": 3.0}],
			"answer": "b",
			"explanation": "Il decimale sta fra due interi: 2,5 è la tacca a metà fra 2 e 3. È lo stesso punto che occupa la frazione 5/2."},
		# I due decimali sulla retta (7 settembre 2026). La retta è il posto in cui
		# 0,75 e 3/4 smettono di essere due argomenti e diventano lo stesso punto:
		# la voce delle frazioni qui sopra usa la stessa scala apposta.
		{"topic": "decimali", "minLevel": 9, "prompt": "Quale punto corrisponde a 0,75?", "min": 0.0, "max": 1.0, "tick": 0.25,
			"labels": [{"value": 0.0, "text": "0"}, {"value": 0.5, "text": "0,5"}, {"value": 1.0, "text": "1"}],
			"targets": [{"id": "a", "label": "Punto su zero virgola venticinque", "value": 0.25}, {"id": "b", "label": "Punto su zero virgola cinque", "value": 0.5}, {"id": "c", "label": "Punto su zero virgola settantacinque", "value": 0.75}],
			"answer": "c",
			"explanation": "Diviso il tratto in quattro parti, 0,75 è la terza tacca: è lo stesso punto in cui sta la frazione 3/4, perché sono due scritture della stessa quantità."},
		{"topic": "decimali", "minLevel": 12, "prompt": "Quale punto corrisponde a 1,4?", "min": 1.0, "max": 2.0, "tick": 0.2,
			"labels": [{"value": 1.0, "text": "1"}, {"value": 1.5, "text": "1,5"}, {"value": 2.0, "text": "2"}],
			"targets": [{"id": "a", "label": "Punto su uno virgola due", "value": 1.2}, {"id": "b", "label": "Punto su uno virgola quattro", "value": 1.4}, {"id": "c", "label": "Punto su uno virgola otto", "value": 1.8}],
			"answer": "b",
			"explanation": "Qui ogni tacca vale due decimi, non un decimo: prima di contare si guarda quanto vale un passo, altrimenti si arriva al punto sbagliato pur contando bene."},
	],
}

const NOTATION := {
	"musica": [
		{"topic": "lettura",
			"prompt": "In chiave di violino, quale di queste note è il SOL?",
			"domande": [
				{"prompt": "In chiave di violino, quale di queste tre note è la più GRAVE, cioè la più in basso sul pentagramma?", "answer": "riga1", "explanation": "Più una nota sta in basso sul pentagramma, più è grave: la nota sulla prima riga è la più bassa delle tre."},
				{"prompt": "Fra queste note sulle righe, quale è la più ACUTA?", "answer": "riga3", "explanation": "Più si sale sul pentagramma, più il suono è acuto: la nota sulla terza riga è la più alta delle tre."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "riga1", "label": "Nota sulla prima riga", "kind": "note", "staffStep": 0, "duration": "quarter"},
				{"id": "riga2", "label": "Nota sulla seconda riga", "kind": "note", "staffStep": 2, "duration": "quarter"},
				{"id": "riga3", "label": "Nota sulla terza riga", "kind": "note", "staffStep": 4, "duration": "quarter"}],
			"answer": "riga2",
			"explanation": "Le note sulle righe, dal basso, sono Mi, Sol, Si, Re, Fa: il SOL è sulla seconda. Non a caso la chiave di violino si chiama anche «chiave di Sol» — la sua spirale gira proprio intorno a quella riga."},
		{"topic": "lettura",
			"prompt": "Quale di queste note sta in uno SPAZIO e non su una riga?",
			"domande": [
				{"prompt": "Quale di queste note ha una riga che le passa in mezzo al pallino?", "answer": "riga1", "explanation": "Una nota sta SU una riga quando la riga attraversa il pallino. Questa è la prima riga del pentagramma."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "riga1", "label": "Prima nota", "kind": "note", "staffStep": 0, "duration": "quarter"},
				{"id": "spazio2", "label": "Seconda nota", "kind": "note", "staffStep": 3, "duration": "quarter"},
				{"id": "riga3", "label": "Terza nota", "kind": "note", "staffStep": 4, "duration": "quarter"}],
			"answer": "spazio2",
			"explanation": "Una nota sta in uno spazio quando il pallino è fra due righe e non ne è attraversato. Le note negli spazi, dal basso, sono Fa, La, Do, Mi: questa è un LA."},
		{"topic": "ritmo", "minLevel": 3,
			"prompt": "Quale di queste figure dura di più?",
			"domande": [
				{"prompt": "Fra queste figure musicali, quale dura di MENO?", "answer": "croma", "explanation": "La croma è la più breve delle quattro: ogni figura vale la metà di quella prima di lei, e la croma è l'ultima della scala."},
				{"prompt": "Quale figura dura esattamente la metà della semibreve?", "answer": "minima", "explanation": "La minima vale metà semibreve. La semiminima ne vale un quarto e la croma un ottavo."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "semiminima", "label": "Nota nera con il gambo", "kind": "note", "staffStep": 4, "duration": "quarter"},
				{"id": "semibreve", "label": "Nota vuota senza gambo", "kind": "note", "staffStep": 4, "duration": "whole"},
				{"id": "croma", "label": "Nota nera con la bandierina", "kind": "note", "staffStep": 4, "duration": "eighth"},
				{"id": "minima", "label": "Nota vuota con il gambo", "kind": "note", "staffStep": 4, "duration": "half"}],
			"answer": "semibreve",
			"explanation": "La durata si legge dalla forma: la semibreve è vuota e senza gambo e vale 4 battiti, la minima è vuota col gambo (2), la semiminima è nera col gambo (1), la croma ha la bandierina (mezzo)."},
		{"topic": "ritmo", "minLevel": 4,
			"prompt": "Quale di questi simboli indica un silenzio?",
			"domande": [
				{"prompt": "Fra questi simboli, quale indica un suono da eseguire e non un silenzio?", "answer": "nota-a", "explanation": "Le note hanno il pallino sul rigo e si suonano; la pausa è il segno che dice di tacere per quella durata."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "nota-a", "label": "Primo simbolo", "kind": "note", "staffStep": 2, "duration": "quarter"},
				{"id": "pausa", "label": "Secondo simbolo", "kind": "rest", "staffStep": 4, "duration": "quarter"},
				{"id": "nota-b", "label": "Terzo simbolo", "kind": "note", "staffStep": 6, "duration": "quarter"}],
			"answer": "pausa",
			"explanation": "La pausa è un silenzio, e dura esattamente quanto la nota corrispondente: una pausa di semiminima vale un battito. In musica anche il silenzio si conta."},
		{"topic": "lettura", "minLevel": 5,
			"prompt": "Quale di queste alterazioni ALZA la nota di un semitono?",
			"domande": [
				{"prompt": "Quale di queste alterazioni ABBASSA la nota di un semitono?", "answer": "bemolle", "explanation": "Il bemolle abbassa di un semitono. Il diesis fa il contrario, il bequadro annulla l'alterazione precedente."},
				{"prompt": "Quale simbolo CANCELLA un diesis o un bemolle messo prima?", "answer": "bequadro", "explanation": "Il bequadro riporta la nota al suo suono naturale: non alza e non abbassa, toglie l'alterazione."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "bemolle", "label": "Primo simbolo", "kind": "accidental", "staffStep": 2, "accidental": "flat"},
				{"id": "diesis", "label": "Secondo simbolo", "kind": "accidental", "staffStep": 4, "accidental": "sharp"},
				{"id": "bequadro", "label": "Terzo simbolo", "kind": "accidental", "staffStep": 6, "accidental": "natural"}],
			"answer": "diesis",
			"explanation": "Il diesis alza di un semitono, il bemolle abbassa di un semitono, il bequadro annulla l'alterazione e riporta la nota al suo suono naturale."},
		{"topic": "note", "minLevel": 6,
			"prompt": "Quale di queste note suona più ACUTA?",
			"domande": [
				{"prompt": "Fra queste tre note, quale suona più GRAVE?", "answer": "bassa", "explanation": "Più una nota sta in basso sul pentagramma, più il suono è grave: qui la più bassa delle tre."},
				{"prompt": "Quale di queste note sta a metà fra la più grave e la più acuta?", "answer": "media", "explanation": "Sul pentagramma l'altezza si legge dalla posizione: questa nota sta fra le altre due."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "bassa", "label": "Prima nota", "kind": "note", "staffStep": 1, "duration": "quarter"},
				{"id": "media", "label": "Seconda nota", "kind": "note", "staffStep": 5, "duration": "quarter"},
				{"id": "alta", "label": "Terza nota", "kind": "note", "staffStep": 8, "duration": "quarter"}],
			"answer": "alta",
			"explanation": "Sul pentagramma l'altezza è letterale: più in alto sta il pallino, più il suono è acuto. La più alta qui è sulla quinta riga, il FA."},
		{"topic": "lettura", "minLevel": 8,
			"prompt": "Quale nota esce dal pentagramma e ha bisogno di una linea addizionale?",
			"domande": [
				{"prompt": "Fra queste note, quale sta comodamente dentro le cinque righe del pentagramma?", "answer": "dentro-a", "explanation": "Il pentagramma ha cinque righe: le note che ci stanno dentro non hanno bisogno di linee aggiunte."},
				{"prompt": "Quale nota, pur restando dentro il pentagramma, è la più acuta delle due interne?", "answer": "dentro-b", "explanation": "Fra le due note interne, quella più in alto è la più acuta: sul pentagramma l'altezza è la posizione."},
			],
			"staff": {"clef": "treble"},
			"symbols": [
				{"id": "dentro-a", "label": "Prima nota", "kind": "note", "staffStep": 2, "duration": "quarter"},
				{"id": "dentro-b", "label": "Seconda nota", "kind": "note", "staffStep": 6, "duration": "quarter"},
				{"id": "fuori", "label": "Terza nota", "kind": "note", "staffStep": 10, "duration": "quarter"}],
			"answer": "fuori",
			"explanation": "Il pentagramma ha cinque righe e basta. Per le note più acute o più gravi si disegnano linee addizionali corte, una per ogni riga che servirebbe in più."},
		{"topic": "lettura", "minLevel": 10,
			"prompt": "In chiave di basso, quale di queste note è il FA?",
			"domande": [
				{"prompt": "In chiave di basso, quale di queste note è la più GRAVE?", "answer": "riga2", "explanation": "In qualsiasi chiave la nota più in basso sul pentagramma è la più grave: cambia il nome, non la regola."},
				{"prompt": "In chiave di basso, quale nota sta fra le altre due?", "answer": "riga3", "explanation": "La posizione verticale dice l'altezza: questa nota sta in mezzo alle altre due."},
			],
			"staff": {"clef": "bass"},
			"symbols": [
				{"id": "riga2", "label": "Nota sulla seconda riga", "kind": "note", "staffStep": 2, "duration": "quarter"},
				{"id": "riga3", "label": "Nota sulla terza riga", "kind": "note", "staffStep": 4, "duration": "quarter"},
				{"id": "riga4", "label": "Nota sulla quarta riga", "kind": "note", "staffStep": 6, "duration": "quarter"}],
			"answer": "riga4",
			"explanation": "La chiave di basso si chiama anche «chiave di Fa»: i suoi due punti stanno sopra e sotto la quarta riga, ed è proprio lì che si trova il FA. Attenzione: in chiave di basso le stesse righe hanno nomi diversi che in chiave di violino."},
	],
}

## Carta muta. Il contenuto nomina soltanto `mapId` e bersagli semantici; la
## proiezione e le coordinate stanno in `map_geometry_catalog.gd`. Le etichette
## identificano il segnaposto senza descriverlo: «segnaposto sulla pianura del
## nord» regalerebbe la risposta.
const MAP_READING := {
	"geografia": [
		{"topic": "italia-fisica", "mapId": "italy",
			"prompt": "Sulla carta muta dell'Italia, quale segnaposto indica il fiume Po?",
			"domande": [
				{"prompt": "Sulla carta muta dell'Italia, quale segnaposto NON indica un'isola?", "answer": "po", "explanation": "Il Po è un fiume e scorre sulla terraferma: Sicilia e Sardegna sono invece le due grandi isole."},
				{"prompt": "Quale segnaposto indica l'isola più grande del Mediterraneo?", "answer": "sicily", "explanation": "La Sicilia è la maggiore isola del Mediterraneo, separata dalla Calabria dallo stretto di Messina."},
			],
			"targets": [
				{"id": "po", "label": "Segnaposto A"},
				{"id": "sicily", "label": "Segnaposto B"},
				{"id": "sardinia", "label": "Segnaposto C"}],
			"answer": "po",
			"explanation": "Il Po attraversa da ovest a est la grande pianura del nord, quella che porta il suo nome: è l'unico dei tre segnaposto sulla terraferma."},
		{"topic": "italia-fisica", "minLevel": 1, "mapId": "italy",
			"prompt": "Sulla carta muta dell'Italia, quale segnaposto indica la Sicilia?",
			"domande": [
				{"prompt": "Sulla carta muta, quale segnaposto indica l'isola a ovest della penisola?", "answer": "sardinia", "explanation": "La Sardegna sta a ovest, in mezzo al Mar Tirreno: la Sicilia invece è a sud."},
				{"prompt": "Quale segnaposto indica il corso d'acqua che attraversa la pianura del nord?", "answer": "po", "explanation": "Il Po attraversa da ovest a est la pianura che porta il suo nome."},
			],
			"targets": [
				{"id": "po", "label": "Segnaposto A"},
				{"id": "sicily", "label": "Segnaposto B"},
				{"id": "sardinia", "label": "Segnaposto C"}],
			"answer": "sicily",
			"explanation": "La Sicilia è la grande isola triangolare all'estremità sud della penisola, separata dalla Calabria dallo stretto di Messina."},
		# Cinque carte nuove sulle ancore che il catalogo di geometria aveva gia'
		# e che nessuna prova usava: alpi, appennini e i mari. La carta muta aveva
		# TRE bersagli in tutto, quindi tre domande possibili in tutta la
		# campagna; qui i bersagli diventano nove e le domande dodici.
		#
		# Le etichette restano "Segnaposto A/B/C": identificano senza descrivere,
		# che e' l'unica scelta che non regala la risposta a chi legge le etichette.
		{"topic": "italia-fisica", "minLevel": 4, "mapId": "italy",
			"prompt": "Sulla carta muta dell'Italia, quale segnaposto indica la catena delle Alpi?",
			"targets": [
				{"id": "alps", "label": "Segnaposto A"},
				{"id": "apennines", "label": "Segnaposto B"},
				{"id": "po", "label": "Segnaposto C"}],
			"answer": "alps",
			"explanation": "Le Alpi chiudono l'Italia a nord, sopra la pianura del Po: sono l'arco montuoso piu' settentrionale, al confine con gli altri Paesi.",
			"domande": [
				{"prompt": "Sulla carta muta, quale segnaposto indica la catena che percorre la penisola da nord a sud?", "answer": "apennines",
					"explanation": "Gli Appennini corrono lungo tutta la penisola come una spina dorsale, dal nord fino alla Calabria."},
				{"prompt": "Fra questi tre segnaposto, quale NON indica una catena di montagne?", "answer": "po",
					"explanation": "Il Po e' un fiume: scorre nella pianura, non e' un rilievo. Gli altri due sono Alpi e Appennini."},
			]},
		{"topic": "italia-fisica", "minLevel": 6, "mapId": "italy",
			"prompt": "Sulla carta muta dell'Italia, quale segnaposto indica il Mar Tirreno?",
			"targets": [
				{"id": "tyrrhenian_sea", "label": "Segnaposto A"},
				{"id": "adriatic_sea", "label": "Segnaposto B"},
				{"id": "ligurian_sea", "label": "Segnaposto C"}],
			"answer": "tyrrhenian_sea",
			"explanation": "Il Tirreno sta a ovest della penisola, fra la costa, la Sardegna e la Sicilia.",
			"domande": [
				{"prompt": "Sulla carta muta, quale segnaposto indica il mare a EST della penisola, verso i Balcani?", "answer": "adriatic_sea",
					"explanation": "L'Adriatico e' il mare lungo e stretto a est dell'Italia, fra la penisola e la costa balcanica."},
				{"prompt": "Quale segnaposto indica il mare piccolo a nord-ovest, davanti alla Liguria?", "answer": "ligurian_sea",
					"explanation": "Il Mar Ligure e' il tratto a nord-ovest, davanti all'arco costiero della Liguria."},
			]},
		{"topic": "italia-fisica", "minLevel": 8, "mapId": "italy",
			"prompt": "Sulla carta muta dell'Italia, quale segnaposto indica il Mar Ionio?",
			"targets": [
				{"id": "ionian_sea", "label": "Segnaposto A"},
				{"id": "adriatic_sea", "label": "Segnaposto B"},
				{"id": "sicily", "label": "Segnaposto C"}],
			"answer": "ionian_sea",
			"explanation": "Lo Ionio sta a sud-est, fra la punta della Calabria, la Puglia e la Grecia: e' il mare dentro l'arco del \"tacco\" e della \"punta\".",
			"domande": [
				{"prompt": "Fra questi tre segnaposto, quale indica una TERRA e non un mare?", "answer": "sicily",
					"explanation": "La Sicilia e' un'isola: gli altri due segnaposto indicano lo Ionio e l'Adriatico, che sono mari."},
			]},
		{"topic": "italia-fisica", "minLevel": 5, "mapId": "italy",
			"prompt": "Sulla carta muta dell'Italia, quale segnaposto indica la Sardegna?",
			"domande": [
				{"prompt": "Sulla carta muta, quale segnaposto indica l'isola a sud della penisola?", "answer": "sicily", "explanation": "La Sicilia è la grande isola triangolare all'estremità sud dell'Italia."},
				{"prompt": "Quale dei tre segnaposto indica qualcosa che non è terra emersa?", "answer": "po", "explanation": "Il Po è un fiume: gli altri due segnaposto indicano isole, cioè terra."},
			],
			"targets": [
				{"id": "po", "label": "Segnaposto A"},
				{"id": "sicily", "label": "Segnaposto B"},
				{"id": "sardinia", "label": "Segnaposto C"}],
			"answer": "sardinia",
			"explanation": "La Sardegna è l'isola a ovest della penisola, in mezzo al Mar Tirreno: è la seconda isola del Mediterraneo dopo la Sicilia."},

		# --- La carta d'Europa, che nessuna prova usava (1 settembre 2026) -----
		#
		# `MapGeometryCatalog` possiede la sagoma dell'Europa e quindici ancore
		# di Paese dal 21 agosto, e in tutta la campagna non c'era una sola prova
		# che le usasse: le capitali si chiedevano soltanto a parole.
		#
		# «Qual è la capitale della Norvegia?» è una domanda che si sa o non si
		# sa. «Quale segnaposto indica il Paese la cui capitale è Oslo?» è la
		# stessa conoscenza chiesta dove abita — su una carta — ed è la forma in
		# cui l'atlante di NORA (`TavoleRiferimento`, tavola delle capitali) può
		# davvero servire da riferimento: la scheda mostra il posto, la prova
		# chiede il posto.
		#
		# Ogni Paese nominato qui sta su quella tavola. È il vincolo che tiene
		# insieme le due cose, ed è quello che va rispettato aggiungendone altre.
		{"topic": "capitali", "minLevel": 1, "mapId": "europe",
			"prompt": "Sulla carta d'Europa, quale segnaposto indica il Paese la cui capitale è Parigi?",
			"targets": [
				{"id": "france", "label": "Segnaposto A"},
				{"id": "spain", "label": "Segnaposto B"},
				{"id": "germany", "label": "Segnaposto C"}],
			"answer": "france",
			"explanation": "Parigi è la capitale della Francia, che sta al centro-ovest del continente, fra l'Atlantico e le Alpi.",
			"domande": [
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Madrid?", "answer": "spain",
					"explanation": "Madrid è la capitale della Spagna, e sta al centro esatto della penisola iberica, la più a sud-ovest d'Europa."},
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Berlino?", "answer": "germany",
					"explanation": "Berlino è la capitale della Germania, nel cuore dell'Europa centrale, a nord-est rispetto a Francia e Spagna."},
			]},
		{"topic": "capitali", "minLevel": 2, "mapId": "europe",
			"prompt": "Quale segnaposto indica il Paese la cui capitale è Oslo?",
			"targets": [
				{"id": "norway", "label": "Segnaposto A"},
				{"id": "sweden", "label": "Segnaposto B"},
				{"id": "finland", "label": "Segnaposto C"}],
			"answer": "norway",
			"explanation": "Oslo è la capitale della Norvegia, il Paese affacciato sull'Atlantico, sul lato occidentale della penisola scandinava.",
			"domande": [
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Stoccolma?", "answer": "sweden",
					"explanation": "Stoccolma è la capitale della Svezia, sul lato orientale della Scandinavia, affacciato sul Mar Baltico."},
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Helsinki?", "answer": "finland",
					"explanation": "Helsinki è la capitale della Finlandia, il più orientale dei tre Paesi nordici, oltre il golfo che porta il suo nome."},
			]},
		{"topic": "capitali", "minLevel": 5, "mapId": "europe",
			"prompt": "Quale segnaposto indica il Paese la cui capitale è Londra?",
			"targets": [
				{"id": "united_kingdom", "label": "Segnaposto A"},
				{"id": "ireland", "label": "Segnaposto B"},
				{"id": "italy", "label": "Segnaposto C"}],
			"answer": "united_kingdom",
			"explanation": "Londra è la capitale del Regno Unito, sull'isola grande a nord-ovest del continente.",
			"domande": [
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Dublino?", "answer": "ireland",
					"explanation": "Dublino è la capitale dell'Irlanda, l'isola più a ovest, oltre la Gran Bretagna."},
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Roma?", "answer": "italy",
					"explanation": "Roma è la capitale dell'Italia, la penisola che entra nel Mediterraneo dal centro del continente."},
			]},
		{"topic": "capitali", "minLevel": 8, "mapId": "europe",
			"prompt": "Quale segnaposto indica il Paese la cui capitale è Atene?",
			"targets": [
				{"id": "greece", "label": "Segnaposto A"},
				{"id": "poland", "label": "Segnaposto B"},
				{"id": "spain", "label": "Segnaposto C"}],
			"answer": "greece",
			"explanation": "Atene è la capitale della Grecia, all'estremità sud-orientale del continente, in mezzo al Mediterraneo.",
			"domande": [
				{"prompt": "Quale segnaposto indica il Paese la cui capitale è Varsavia?", "answer": "poland",
					"explanation": "Varsavia è la capitale della Polonia, nell'Europa centro-orientale, fra Germania e Ucraina."},
				{"prompt": "Quale dei tre segnaposto indica un Paese che NON è bagnato dal Mediterraneo?", "answer": "poland",
					"explanation": "La Polonia si affaccia sul Baltico, a nord. Grecia e Spagna hanno entrambe coste sul Mediterraneo."},
			]},
		{"topic": "europa", "minLevel": 3, "mapId": "europe",
			"prompt": "Sulla carta d'Europa, quale segnaposto indica la penisola iberica?",
			"targets": [
				{"id": "spain", "label": "Segnaposto A"},
				{"id": "italy", "label": "Segnaposto B"},
				{"id": "greece", "label": "Segnaposto C"}],
			"answer": "spain",
			"explanation": "La penisola iberica è quella a sud-ovest, dove stanno Spagna e Portogallo: è bagnata dal Mediterraneo a est e dall'Atlantico a ovest.",
			"domande": [
				{"prompt": "Quale segnaposto indica la penisola bagnata a est dal mare Adriatico?", "answer": "italy",
					"explanation": "È l'Italia: l'Adriatico la separa dalla penisola balcanica, che le sta di fronte."},
				{"prompt": "Quale segnaposto indica il Paese più a est fra i tre, sul mare Egeo?", "answer": "greece",
					"explanation": "La Grecia chiude il Mediterraneo a est, con le sue centinaia di isole nell'Egeo."},
			]},
		{"topic": "europa", "minLevel": 6, "mapId": "europe",
			"prompt": "Quale segnaposto indica lo Stato più esteso che sta interamente in Europa?",
			"targets": [
				{"id": "ukraine", "label": "Segnaposto A"},
				{"id": "norway", "label": "Segnaposto B"},
				{"id": "mediterranean", "label": "Segnaposto C"}],
			"answer": "ukraine",
			"explanation": "L'Ucraina: la Russia è più grande, ma per la maggior parte sta in Asia, oltre gli Urali.",
			"domande": [
				{"prompt": "Quale segnaposto NON indica una terra?", "answer": "mediterranean",
					"explanation": "Il Mediterraneo è il mare che chiude l'Europa a sud: gli altri due segnaposto indicano Paesi."},
				{"prompt": "Quale segnaposto indica il Paese dei fiordi, affacciato sull'Atlantico a nord?", "answer": "norway",
					"explanation": "La Norvegia: la sua costa è tutta valli invase dal mare, e le città stanno in fondo a quelle insenature."},
			]},
	],
}

## Reperti illustrati. `assetId` nomina un atlante condiviso — un foglio solo con
## più reperti, mai un file per esercizio — e i bersagli sono semantici: le
## coordinate stanno in `artifact_atlas_catalog.gd`.
const HOTSPOT := {
	"elettronica": [
		{"topic": "componenti", "assetId": "electronics_components",
			"prompt": "Quale componente emette luce quando la corrente lo attraversa nel verso corretto?",
			"domande": [
				{"prompt":"Quale componente ha due piedini di lunghezza diversa che aiutano a riconoscere la polarita'?", "answer":"led", "explanation":"Nel LED il piedino piu' lungo indica di solito l'anodo: la polarita' conta perche' il diodo lascia passare corrente in un solo verso."},
				{"prompt":"Quale componente limita la corrente grazie a un valore indicato da bande colorate?", "answer":"resistor", "explanation":"Le bande del resistore codificano il suo valore; limitarne la corrente protegge per esempio un LED da una corrente eccessiva."},
			],
			"targets":[{"id":"led","label":"Primo componente da sinistra"},{"id":"resistor","label":"Secondo componente"},{"id":"capacitor","label":"Terzo componente"},{"id":"push_button","label":"Quarto componente"}],
			"answer":"led", "explanation":"Il LED e' un diodo che trasforma parte dell'energia elettrica in luce e conduce soltanto se collegato con la polarita' corretta."},
		{"topic": "componenti", "minLevel": 1, "assetId": "electronics_components",
			"prompt": "Quale componente accumula temporaneamente carica elettrica fra due armature?",
			"domande": [
				{"prompt":"Quale componente chiude il contatto soltanto mentre viene premuto?", "answer":"push_button", "explanation":"Il pulsante tattile e' un interruttore momentaneo: premendolo i contatti si chiudono, rilasciandolo tornano aperti."},
				{"prompt":"Quale dei quattro componenti mostra bande colorate invece di una polarita' positiva e negativa?", "answer":"resistor", "explanation":"Il resistore usa bande colorate per il valore; LED e condensatore hanno polarita', mentre il pulsante e' un contatto meccanico."},
			],
			"targets":[{"id":"led","label":"Primo componente da sinistra"},{"id":"resistor","label":"Secondo componente"},{"id":"capacitor","label":"Terzo componente"},{"id":"push_button","label":"Quarto componente"}],
			"answer":"capacitor", "explanation":"Il condensatore separa cariche sulle sue armature e puo' restituirle al circuito; per questo filtra variazioni e crea piccoli ritardi."},
	],
	"storia": [
		{"topic": "roma", "assetId": "roman_artifacts",
			"prompt": "Quale di questi reperti romani serviva a portare l'acqua fino in città?",
			"domande": [
				{"prompt": "Quale di questi reperti sorreggeva il tetto di un edificio, non conteneva niente?", "answer": "column", "explanation": "La colonna è un elemento portante: regge il peso del tetto. Gli altri tre servono a trasportare acqua, a contenere liquidi o a decorare un pavimento."},
				{"prompt": "Fra questi quattro reperti, quale si CAMMINA sopra?", "answer": "mosaic", "explanation": "Il mosaico è un pavimento: le tessere formano il disegno su cui si cammina. Gli altri stanno in piedi o si trasportano."},
			],
			"targets": [
				{"id": "aqueduct", "label": "Primo reperto da sinistra"},
				{"id": "column", "label": "Secondo reperto"},
				{"id": "amphora", "label": "Terzo reperto"},
				{"id": "mosaic", "label": "Quarto reperto"}],
			"answer": "aqueduct",
			"explanation": "L'acquedotto porta l'acqua da lontano sfruttando una pendenza minima: gli archi servono a tenere il canale sempre alla quota giusta mentre il terreno sale e scende."},
		{"topic": "roma", "minLevel": 1, "assetId": "roman_artifacts",
			"prompt": "Quale di questi reperti serviva a conservare e trasportare vino e olio?",
			"domande": [
				{"prompt": "Quale di questi reperti si spostava da un posto all'altro, e non stava fermo dov'era costruito?", "answer": "amphora", "explanation": "L'anfora è l'unico oggetto mobile: aveva due anse proprio per essere sollevata e caricata sulle navi. Acquedotto, colonna e mosaico si costruiscono sul posto."},
			],
			"targets": [
				{"id": "aqueduct", "label": "Primo reperto da sinistra"},
				{"id": "column", "label": "Secondo reperto"},
				{"id": "amphora", "label": "Terzo reperto"},
				{"id": "mosaic", "label": "Quarto reperto"}],
			"answer": "amphora",
			"explanation": "L'anfora ha il fondo a punta non per sbaglio: si conficcava nella sabbia o negli appositi sostegni delle navi, e le due anse servivano a sollevarla in due."},
		{"topic": "roma", "minLevel": 5, "assetId": "roman_artifacts",
			"prompt": "Quale di questi reperti è un pavimento decorato con piccole tessere colorate?",
			"domande": [
				{"prompt": "Quale di questi reperti è fatto di tante piccolissime parti uguali messe insieme?", "answer": "mosaic", "explanation": "Il mosaico nasce dall'accostare migliaia di tessere: il disegno esiste solo guardando l'insieme, non la singola tessera."},
			],
			"targets": [
				{"id": "aqueduct", "label": "Primo reperto da sinistra"},
				{"id": "column", "label": "Secondo reperto"},
				{"id": "amphora", "label": "Terzo reperto"},
				{"id": "mosaic", "label": "Quarto reperto"}],
			"answer": "mosaic",
			"explanation": "Il mosaico è fatto di tessere piccolissime di pietra e vetro. È una fonte materiale preziosa: ci mostra come i Romani si vestivano, cosa mangiavano e a cosa giocavano."},
		{"topic": "roma", "minLevel": 7, "assetId": "roman_artifacts",
			"prompt": "Quale di questi reperti sorreggeva il tetto di un tempio?",
			"domande": [
				{"prompt": "Quale di questi reperti veniva costruito con una pendenza minima per far scorrere l'acqua?", "answer": "aqueduct", "explanation": "L'acquedotto funziona grazie a una pendenza piccolissima e costante: gli archi servono a mantenerla mentre il terreno cambia quota."},
				{"prompt": "Quale di questi reperti si poteva riempire e trasportare?", "answer": "amphora", "explanation": "L'anfora è un contenitore: aveva due anse per essere sollevata e il fondo a punta per essere infilata nella sabbia o nei sostegni delle navi."},
			],
			"targets": [
				{"id": "aqueduct", "label": "Primo reperto da sinistra"},
				{"id": "column", "label": "Secondo reperto"},
				{"id": "amphora", "label": "Terzo reperto"},
				{"id": "mosaic", "label": "Quarto reperto"}],
			"answer": "column",
			"explanation": "La colonna scarica a terra il peso del tetto. Il capitello in cima, qui decorato a foglie d'acanto, è corinzio: dallo stile del capitello si riconosce l'epoca dell'edificio."},
	],
}

const FORMATS := [
	"matching", "ordering", "classification", "graph", "circuit", "cycle",
	"notation", "map", "hotspot", "code_debug", "number_line", "balance",
	"timeline", "compose", "trace", "clue", "swipe", "machine_path", "mystery_sample",
	"verb_decoder", "griglia", "porte",
	"breadboard", "rhythm_fill", "causal_chain", "robot_grid", "blank_map",
]

static func table_for(fmt: String) -> Dictionary:
	match fmt:
		"matching": return MATCHING
		"ordering": return ORDERING
		"classification": return CLASSIFICATION
		"graph": return GRAPH
		"circuit": return CIRCUIT
		"cycle": return CYCLE
		"notation": return NOTATION
		"map": return MAP_READING
		"number_line": return NUMBER_LINE
		"balance": return BALANCE
		"timeline": return TIMELINE
		"compose": return COMPOSE
		"trace": return TRACE
		"clue": return CLUE
		"swipe": return SWIPE
		"hotspot": return HOTSPOT
		"code_debug": return CODE_DEBUG
	return {}

## Le specifiche che questo livello può davvero incontrare. Il gate `minLevel` non
## è un dettaglio della misura: ai livelli bassi lascia spesso UNA specifica per
## formato, ed è lì che nasce la ripetizione peggiore.
static func eligible_specs(subject: String, fmt: String, level: int) -> Array:
	var out: Array = []
	for spec in Array(table_for(fmt).get(subject, [])):
		if int((spec as Dictionary).get("minLevel", 0)) <= level:
			out.append(spec)
	return out

## Un formato con una sola consegna idonea non entra ancora nella rotazione:
## altrimenti ogni visita a quel livello riproporrebbe la stessa prova. I
## contenuti restano progressivi; è il runtime a non esporre una corsia prima
## che abbia almeno due alternative reali.
static func format_available(subject: String, fmt: String, level: int) -> bool:
	return eligible_specs(subject, fmt, level).size() >= 2

## Meccaniche che il runtime puo' davvero costruire per materia e livello.
## Questa lista alimenta gli eventi di pratica: non include formati soltanto
## dichiarati nei profili, ma esclusivamente corsie con contenuto giocabile.
static func runtime_formats_for(subject: String, level: int) -> Array:
	var out: Array = []
	if MATCHING.has(subject):
		out.append("matching")
	if ORDERING.has(subject) or NUMERIC_ORDERING_SUBJECTS.has(subject):
		out.append("ordering")
	if CLASSIFICATION.has(subject):
		out.append("classification")
	for fmt in [
		"graph", "circuit", "cycle", "balance", "timeline", "clue", "swipe",
		"compose", "trace", "number_line", "code_debug",
	]:
		if not eligible_specs(subject, str(fmt), level).is_empty():
			out.append(str(fmt))
	# Questi renderer richiedono almeno due specifiche introduttive, perche' una
	# sola carta fissa verrebbe imparata a memoria gia' alla seconda visita.
	for fmt in ["notation", "map", "hotspot"]:
		if format_available(subject, str(fmt), level):
			out.append(str(fmt))
	# Formati costruiti da template: non hanno specifiche in tabella, quindi
	# `eligible_specs` non li vede mai e i cicli qui sopra non possono trovarli.
	# La disponibilità dipende solo dalla materia — gli stessi criteri con cui
	# `build_minigame` li mette in scaletta.
	if NUMERIC_ORDERING_SUBJECTS.has(subject):
		out.append("machine_path")
	if subject in ["scienze", "fisica"]:
		out.append("mystery_sample")
	if subject in ["italiano", "inglese"]:
		out.append("verb_decoder")
	if subject == "logica":
		out.append("griglia")
		out.append("porte")
	var signature_by_subject := {
		"elettronica": "breadboard", "musica": "rhythm_fill", "storia": "causal_chain",
		"coding": "robot_grid", "geografia": "blank_map",
	}
	if signature_by_subject.has(subject): out.append(str(signature_by_subject[subject]))
	return out

## GRADIENTE DI DIFFICOLTÀ dentro la sessione.
##
## Fino alla Fase 4 ogni minigioco di un mondo aveva la STESSA identica
## difficoltà, quella del livello: al mondo 3 tutto a 1, al mondo 20 tutto a 4.
## Una sessione piatta non è solo monotona, è didatticamente peggiore — si entra
## senza scaldarsi e si esce senza essere stati messi alla prova.
##
## Ora la prima campata scende di un gradino e l'ultima sale: riscaldamento,
## corpo, sfida. La media resta quella del livello, quindi la progressione della
## campagna non cambia; cambia il profilo dentro il mondo. Effetto collaterale
## voluto: ogni mondo attraversa riscaldamento, centro e finale senza uscire
## dalla scala 1..8.
static func gradient_step(idx: int, total: int) -> int:
	if total < 3:
		return 0   # con una o due campate un gradiente non ha senso
	if idx == 0:
		return -1
	if idx >= total - 1:
		return 1
	return 0

static func difficulty_of(level: int, step: int) -> int:
	return clampi(ContentManager.target_difficulty(level) + step, 1, ContentManager.DIFFICULTY_BANDS)

## Quante voci si pescano: ora dipende dalla DIFFICOLTÀ della campata, non dal
## livello. È la stessa cosa nella media (la difficoltà viene dal livello) ma
## rende reale il gradiente: la campata di riscaldamento ha davvero meno tessere
## da tenere a mente di quella finale.
##
## Il numero di voci segue il PASSO DEL GRADIENTE (−1 riscaldamento, +1 finale),
## non la difficoltà assoluta.
##
## Provato prima nell'altro modo, e misurato: legandolo alla difficoltà assoluta
## la profondità del primo mondo crollava da 200.000 a 15.000 e le ripetizioni
## risalivano dal 17% al 23% — perché al mondo 1 *ogni* campata pescava meno, non
## solo quella di riscaldamento. Il gradiente deve variare dentro la sessione,
## non spostare tutta la campagna verso il basso: il numero di tessere che una
## materia ha scelto resta quello del mondo, e il riscaldamento ne toglie una.
const MIN_SEQUENCE_DRAW := 3
const MAX_SEQUENCE_DRAW := 5

## La BASE resta legata al livello per le specifiche che non dichiarano `draw`:
## al mondo 1 un abbinamento mostra tre coppie, al 24 cinque. Averla tolta per un
## momento — facendo pescare cinque coppie anche al primo mondo — ha fatto
## risalire le ripetizioni di musica e storia a ×6, perché con otto coppie in
## tutto pescarne cinque lascia pochissime combinazioni. Il gradiente si somma
## alla progressione della campagna, non la sostituisce.
static func _sequence_draw(spec: Dictionary, base: int, step: int, available: int) -> int:
	var wanted := base
	if spec.has(ExercisePool.DRAW_KEY):
		wanted = int(spec[ExercisePool.DRAW_KEY])
	return clampi(wanted + step, MIN_SEQUENCE_DRAW, mini(MAX_SEQUENCE_DRAW, available))

static func matching_draw(spec: Dictionary, level: int, step: int = 0) -> int:
	var base := clampi(3 + int(level / 8.0), MIN_SEQUENCE_DRAW, MAX_SEQUENCE_DRAW)
	return _sequence_draw(spec, base, step, ExercisePool.entries(spec, "pairs").size())

static func ordering_draw(spec: Dictionary, level: int, step: int = 0) -> int:
	var available := ExercisePool.entries(spec, "correctOrder").size()
	if not ExercisePool.is_pool(spec):
		return available   # forma statica: la sequenza è tutta la prova
	var base := clampi(3 + int(level / 9.0), MIN_SEQUENCE_DRAW, MAX_SEQUENCE_DRAW)
	return _sequence_draw(spec, base, step, available)

## Lo smistamento ha bidoni da riempire, quindi il minimo non è 3 ma il numero di
## categorie: sotto quello una tessera per bidone non ci sta e la prova è rotta.
static func classification_draw(spec: Dictionary, step: int = 0) -> int:
	var assignments := spec.get("assignments", {}) as Dictionary
	if not spec.has(ExercisePool.DRAW_KEY):
		return assignments.size()
	var base := int(spec[ExercisePool.DRAW_KEY])
	var floor_value := maxi(2, Array(spec.get("categories", [])).size())
	return clampi(base + step, floor_value, assignments.size())

## PROFONDITÀ COMBINATORIA: quante prove distinte questa specifica può produrre.
##
## È la misura che mancava. Le ripetizioni osservate (`variety_audit`) dicono se
## oggi va male; la profondità dice **quando una materia è finita** — senza, si
## aggiunge contenuto senza sapere se basta.
## `difficulty` è quella della campata centrale del livello: è la stima
## CONSERVATIVA. Il gradiente pesca anche a ±1, quindi la varietà reale è la somma
## di tre estrazioni diverse — misurarne una sola non gonfia mai il numero, e un
## pavimento gonfiato sarebbe peggio di nessun pavimento.
static func spec_depth(fmt: String, spec: Dictionary, level: int, step: int = 0) -> int:
	match fmt:
		"matching":
			return ExercisePool.combinations(
				ExercisePool.entries(spec, "pairs").size(), matching_draw(spec, level, step))
		"ordering":
			if not ExercisePool.is_pool(spec):
				return 1
			return ExercisePool.combinations(
				ExercisePool.entries(spec).size(), ordering_draw(spec, level, step))
		"classification":
			var assignments := spec.get("assignments", {}) as Dictionary
			var count := classification_draw(spec, step)
			if count >= assignments.size():
				return 1
			var sizes: Dictionary = {}
			for key in assignments.keys():
				var category := str(assignments[key])
				sizes[category] = int(sizes.get(category, 0)) + 1
			return ExercisePool.covering_combinations(sizes.values(), count)
	# Grafico, circuito, notazione, carta, hotspot e caccia all'errore hanno dati
	# fissi. Il rimescolamento delle righe cambia la presentazione, non la prova
	# (vedi `ExerciseSignature`), quindi non conta come profondità — **ma una
	# domanda diversa sugli stessi dati sì**, ed è una prova a tutti gli effetti:
	# risposta diversa, spiegazione diversa, ragionamento diverso.
	#
	# È il rimedio con la resa più alta che esista qui dentro, perché non aggiunge
	# dati: usa meglio quelli che ci sono. Un grafico letto solo per «dov'è il
	# massimo?» insegna a cercare il punto più alto; lo stesso grafico che a volte
	# chiede «di quanto sale fra B e C?» insegna a leggerlo.
	# Lettura diretta e non `ExercisePool.entries`: quella darebbe la precedenza
	# al pool della specifica, e qui il pool non c'entra niente.
	#
	# `domande` si SOMMA alla domanda scritta a livello di specifica, non la
	# sostituisce. Prima la sostituiva, e una specifica con una domanda in piu'
	# restava profonda uno: aggiungere contenuto non contava niente. Se ne e'
	# accorto il probe che misura la profondita' al livello 24, non la rilettura.
	return 1 + Array(spec.get("domande", [])).size()

## La domanda scelta per questa comparsa, fra quelle che la specifica dichiara.
##
## Deterministica sull'indice, non casuale: due partite con lo stesso seme fanno
## le stesse domande, ed è un contratto del progetto. Senza `domande` restituisce
## la domanda unica scritta a livello di specifica, quindi tutte le specifiche
## esistenti continuano a funzionare senza toccarle.
static func question_of(spec: Dictionary, idx: int) -> Dictionary:
	var domande := Array(spec.get("domande", []))
	var base := {
		"prompt": str(spec.get("prompt", "")),
		"answer": str(spec.get("answer", "")),
		"explanation": str(spec.get("explanation", "")),
	}
	if domande.is_empty():
		return base
	# Indice 0 = la domanda della specifica; le altre vengono dopo.
	var slot := posmod(idx, domande.size() + 1)
	if slot == 0:
		return base
	var chosen := domande[slot - 1] as Dictionary
	return {
		"prompt": str(chosen.get("prompt", spec.get("prompt", ""))),
		"answer": str(chosen.get("answer", spec.get("answer", ""))),
		"explanation": str(chosen.get("explanation", spec.get("explanation", ""))),
	}

static func format_depth(subject: String, fmt: String, level: int) -> int:
	if fmt in ["breadboard", "rhythm_fill", "causal_chain", "robot_grid", "blank_map"]:
		return SubjectSignatureGenerators.depth(fmt, subject)
	if fmt == "griglia":
		return griglia_depth(subject, level)
	if fmt == "porte":
		return porte_depth(subject, level)
	if fmt == "machine_path":
		# Generato a ogni comparsa: partenza, valori e ordine delle macchine
		# cambiano. La stima è prudente e conta solo la matematica.
		return 40000 if subject == "matematica" else 0
	if fmt == "mystery_sample":
		# Il campione nascosto cambia, così come l'ordine di strumenti e ipotesi.
		# La profondità conta solo i casi scientificamente distinti.
		return 12 if subject in ["scienze", "fisica"] else 0
	if fmt == "verb_decoder":
		if subject != "italiano":
			return 0
		var difficulty := ContentManager.target_difficulty(level)
		var count := 0
		for spec in _verb_decoder_templates():
			if int((spec as Dictionary).get("tier", 1)) <= difficulty:
				count += 1
		return count
	# Solo i tre specialisti appena introdotti hanno il gate di attivazione a
	# due specifiche. `ordering` può avere anche il generatore quantitativo fuori
	# tabella: azzerarlo in base alla sola tabella perderebbe profondità reale.
	if fmt in ["notation", "map", "hotspot"] and not format_available(subject, fmt, level):
		return 0
	var total := 0
	# Si misura al passo CENTRALE del gradiente: il riscaldamento pesca una voce in
	# meno e il finale una in più, quindi la varietà reale è la somma di tre
	# estrazioni diverse. Misurarne una sola non gonfia mai il numero, e un
	# pavimento gonfiato sarebbe peggio di nessun pavimento.
	for spec in eligible_specs(subject, fmt, level):
		total += spec_depth(fmt, spec as Dictionary, level, 0)
	if fmt == "ordering" and NUMERIC_ORDERING_SUBJECTS.has(subject):
		total += numeric_ordering_depth(level)
	return total

## Profondità del generatore quantitativo di matematica, che non sta a tabella.
## Va contata comunque: è l'unica sorgente già combinatoria del progetto, e
## ometterla farebbe sembrare matematica più povera di quanto sia.
static func numeric_ordering_depth(level: int) -> int:
	# Passo centrale del gradiente (0), come per tutte le altre misure.
	var count := clampi(4 + int(level / 9.0), 4, 5)
	if level <= 12:
		# Carte "a × b" con prodotti tutti diversi: si sceglie fra i prodotti distinti.
		var products: Dictionary = {}
		for a in range(2, 11):
			for b in range(2, 11):
				products[a * b] = true
		return ExercisePool.combinations(products.size(), count) * 2   # ×2: crescente/decrescente
	return _fraction_depth(0, count) * 2

## Frazioni: denominatori tutti diversi, quindi si sceglie un sottoinsieme di
## denominatori e per ciascuno un numeratore. Stima per eccesso di poco: scarta
## solo le estrazioni con due valori equivalenti (1/2 e 2/4), che il generatore
## rifiuta.
static func _fraction_depth(index: int, remaining: int) -> int:
	if remaining <= 0:
		return 1
	if index >= FRACTION_DENOMINATORS.size():
		return 0
	var d := int(FRACTION_DENOMINATORS[index])
	return (d - 1) * _fraction_depth(index + 1, remaining - 1) + _fraction_depth(index + 1, remaining)

func _build_node_for_format(fmt: String, subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int, forced_spec: Dictionary = {}) -> Dictionary:
	var difficulty := difficulty_of(level, step)
	var spec := forced_spec
	# Il perimetro del corso (vedi `perimetro_di`) filtra le specifiche prima del
	# sorteggio: e' l'unico imbuto da cui passano tutti e quindici i formati a
	# tabella, quindi si applica qui una volta invece che in ogni costruttore.
	var perimetro := perimetro_di(subject, level)
	if spec.is_empty() and fmt != "ordering":
		var table := table_for(fmt)
		if table.has(subject):
			spec = _pick(_dentro_il_perimetro(Array(table[subject]), perimetro), rng, level)
	match fmt:
		"matching": return _matching_node(subject, spec, level, step, rng, idx)
		"ordering":
			if NUMERIC_ORDERING_SUBJECTS.has(subject):
				return _numeric_ordering_node(subject, level, step, rng, idx)
			if spec.is_empty() and ORDERING.has(subject):
				spec = _pick(_dentro_il_perimetro(Array(ORDERING[subject]), perimetro), rng, level)
			return _ordering_node(subject, spec, level, step, rng, idx)
		"classification": return _classification_node(subject, spec, level, step, rng, idx)
		"graph": return _graph_node(subject, spec, difficulty, rng, idx)
		"circuit": return _circuit_node(subject, spec, difficulty, rng, idx)
		"cycle": return _cycle_node(subject, spec, difficulty, rng, idx)
		"notation": return _notation_node(subject, spec, difficulty, rng, idx)
		"swipe": return _swipe_node(subject, spec, difficulty, rng, idx)
		"clue": return _clue_node(subject, spec, difficulty, rng, idx)
		"timeline": return _timeline_node(subject, spec, difficulty, rng, idx)
		"compose": return _compose_node(subject, spec, difficulty, rng, idx)
		"trace": return _trace_node(subject, spec, difficulty, rng, idx)
		"balance": return _balance_node(subject, spec, difficulty, rng, idx)
		"number_line": return _number_line_node(subject, spec, difficulty, rng, idx)
		"map": return _map_node(subject, spec, difficulty, rng, idx)
		"hotspot": return _hotspot_node(subject, spec, difficulty, rng, idx)
		"code_debug": return _code_debug_node(subject, spec, difficulty, rng, idx)
		# Costruiscono da template propri, non da una tabella di specifiche:
		# `table_for` restituisce {} e `spec` resta vuoto senza fare danni.
		"machine_path": return _machine_path_node(subject, level, step, rng, idx)
		"mystery_sample": return _mystery_sample_node(subject, level, step, rng, idx)
		"verb_decoder": return _verb_decoder_node(subject, level, step, rng, idx)
		"griglia": return _griglia_node(subject, level, step, rng, idx)
		"porte": return _porte_node(subject, level, step, rng, idx)
		"breadboard", "rhythm_fill", "causal_chain", "robot_grid", "blank_map":
			return SubjectSignatureGenerators.build(fmt, subject, level, difficulty, rng, idx)
	return {}

## Una campata della sessione di italiano e' sempre ancorata alla fascia del
## mondo. Il catalogo contiene due varianti per fascia e cambia gesto lungo il
## percorso; qui le trasformiamo negli stessi nodi usati da tutti gli esercizi.
func _italian_band_node(level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var band := ContentManager.target_difficulty(level)
	var challenge := ItalianMinigameCatalog.pick(band, rng)
	if challenge.is_empty():
		return {}
	var fmt := str(challenge.get("format", ""))
	var spec := challenge.get("spec", {}) as Dictionary
	var node := _build_node_for_format(fmt, "italiano", level, 0, rng, idx, spec)
	if node.is_empty():
		return {}
	node["id"] = "italiano-fascia-%d-%d" % [band, idx]
	node["calibrationBand"] = band
	node["challengeComplexity"] = int(challenge.get("complexity", band))
	node["minigameTitle"] = str(challenge.get("title", "Sfida d'italiano"))
	node["actionTheme"] = "italiano_fascia_%d" % band
	return node

func build_minigame(subject: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var has_match := MATCHING.has(subject)
	var has_order := ORDERING.has(subject)
	var has_classify := CLASSIFICATION.has(subject)
	var numeric := NUMERIC_ORDERING_SUBJECTS.has(subject)
	# Il perimetro del corso (vedi `perimetro_di`): vuoto per dieci materie su
	# dodici e per i mondi che non sono i loro, cioe' quasi sempre.
	var perimetro := perimetro_di(subject, level)
	# Si decide PRIMA quali formati comporranno la sessione, poi si costruisce.
	# Serve per il gradiente di difficoltà: la difficoltà di una campata dipende da
	# quante ce ne sono in tutto, e un builder che non sa di essere l'ultimo non può
	# saperlo. Prima la sequenza si scopriva costruendo, quindi non era possibile.
	var plan: Array = []
	# I tre formati di base, in ordine RUOTATO.
	#
	# Fino al 5 agosto 2026 l'ordine era cablato: abbinamento, ordinamento,
	# classificazione. `format_shape_probe` ha misurato 288 sessioni — dodici
	# materie per quattro livelli — e **288 su 288 aprivano con le stesse tre
	# mosse nello stesso ordine**, dal mondo 1 al mondo 24. Le forme di sessione
	# esistenti in tutto il gioco erano otto, e differivano solo nell'ultima
	# campata. Nessun formato nuovo avrebbe riparato questo.
	#
	# La rotazione dipende da materia e livello, non dal caso: due materie dello
	# stesso mondo aprono in modo diverso, e la stessa materia rivisitata dodici
	# mondi dopo apre in modo diverso da prima. Restando deterministica, una
	# sessione rigiocata con lo stesso seme resta identica e gli audit reggono.
	var base: Array = []
	if has_match:
		base.append("matching")
	if numeric:
		# In matematica, fra le azioni possibili ora si monta anche una piccola
		# macchina e la si vede funzionare. L'ordinamento numerico resta nel
		# repertorio: non si perde contenuto già validato.
		base.append("machine_path")
		base.append("numeric")
	elif has_order:
		base.append("ordering")
	if has_classify:
		base.append("classification")
	# Il campione senza nome porta argomenti diversi secondo la materia (vedi
	# `_mystery_sample_node`): «materia» per scienze, «galleggiamento» per fisica.
	# La scaletta deve chiedere il permesso al perimetro con l'argomento giusto,
	# altrimenti lo esclude da un mondo che lo accetterebbe.
	if subject in ["scienze", "fisica"]:
		var argomento_campione := "galleggiamento" if subject == "fisica" else "materia"
		if perimetro.is_empty() or perimetro.has(argomento_campione):
			base.append("mystery_sample")
	if subject in ["italiano", "inglese"]:
		# Un messaggio da ricostruire con tre regolazioni: quando accade,
		# con quale intenzione viene detto e quale forma verbale lo completa.
		# In inglese le tre ghiere diventano tempo, forma della frase
		# (afferma / nega / chiede) e voce del verbo: la coniugazione SI FA
		# invece di riconoscerla in un elenco.
		base.append("verb_decoder")
	if subject == "logica":
		# I due formati in cui la logica si FA invece di riconoscerla: la griglia
		# degli incroci (si deduce chiudendo le caselle impossibili) e le porte
		# (la tavola di verità come lampada che si accende). Stanno fra i formati
		# di base, non fra gli specialisti, perché sono il cuore della materia e
		# non un contorno visivo.
		base.append("griglia")
		base.append("porte")
	var signature_by_subject := {
		"elettronica": "breadboard", "musica": "rhythm_fill", "storia": "causal_chain",
		"coding": "robot_grid", "geografia": "blank_map",
	}
	if signature_by_subject.has(subject):
		# La firma e' un gesto di base della disciplina, non un esercizio ornamentale
		# aggiunto in coda: di norma sostituisce a rotazione uno dei tre gesti
		# generici. Musica conserva invece le quattro campate precedenti: e' uno dei
		# due corsi a perimetro stretto e togliere una famiglia farebbe scendere i
		# pavimenti gia' misurati di caselle e prove. In entrambi i casi la firma
		# compare in ogni sessione; negli altri corsi non allunga la palestra e non
		# diluisce la materia ospite nel mondo.
		var generici_presenti: Array = []
		for generico in ["matching", "ordering", "classification"]:
			if base.has(generico):
				generici_presenti.append(generico)
		if subject != "musica" and not generici_presenti.is_empty():
			var slot_generico := posmod(hash(subject) + level, generici_presenti.size())
			base.erase(str(generici_presenti[slot_generico]))
		base.append(str(signature_by_subject[subject]))
	var giro := posmod(hash(subject) + level, maxi(1, base.size()))
	for i in base.size():
		plan.append(base[(giro + i) % base.size()])
	# Quarta campata (formato SPECIALISTA): grafico/circuito/code-debug se la materia
	# ne ha — leggere dati, schemi o codice: la competenza come sfida visuale.
	# Quando una materia ne ha più d'uno (es. italiano: arco narrativo + caccia
	# all'errore) si ruota a caso, così le missioni non ripetono sempre lo stesso.
	# Un formato specialista entra nella rotazione solo se ha almeno uno spec
	# idoneo a questo livello: così un formato tutto "da scuola media" (es. il
	# diagramma di flusso del coding) non trapela nei primi mondi via fallback.
	var specialists: Array = []
	if GRAPH.has(subject) and _has_eligible_dentro(GRAPH[subject], level, perimetro):
		specialists.append("graph")
	if CIRCUIT.has(subject) and _has_eligible_dentro(CIRCUIT[subject], level, perimetro):
		specialists.append("circuit")
	if CYCLE.has(subject) and _has_eligible_dentro(CYCLE[subject], level, perimetro):
		specialists.append("cycle")
	if NOTATION.has(subject) and format_available(subject, "notation", level):
		if _quante_dentro(Array(NOTATION[subject]), level, perimetro) >= 2:
			specialists.append("notation")
	if BALANCE.has(subject) and _has_eligible_dentro(BALANCE[subject], level, perimetro):
		specialists.append("balance")
	if TIMELINE.has(subject) and _has_eligible_dentro(TIMELINE[subject], level, perimetro):
		specialists.append("timeline")
	if CLUE.has(subject) and _has_eligible_dentro(CLUE[subject], level, perimetro):
		specialists.append("clue")
	if SWIPE.has(subject) and _has_eligible_dentro(SWIPE[subject], level, perimetro):
		specialists.append("swipe")
	if COMPOSE.has(subject) and _has_eligible_dentro(COMPOSE[subject], level, perimetro):
		specialists.append("compose")
	if TRACE.has(subject) and _has_eligible_dentro(TRACE[subject], level, perimetro):
		specialists.append("trace")
	if NUMBER_LINE.has(subject) and _has_eligible_dentro(NUMBER_LINE[subject], level, perimetro):
		specialists.append("number_line")
	if MAP_READING.has(subject) and format_available(subject, "map", level):
		if _quante_dentro(Array(MAP_READING[subject]), level, perimetro) >= 2:
			specialists.append("map")
	if HOTSPOT.has(subject) and format_available(subject, "hotspot", level):
		if _quante_dentro(Array(HOTSPOT[subject]), level, perimetro) >= 2:
			specialists.append("hotspot")
	if CODE_DEBUG.has(subject) and _has_eligible_dentro(CODE_DEBUG[subject], level, perimetro):
		specialists.append("code_debug")
	if not specialists.is_empty():
		var scelto := str(specialists[generator.randi_range(0, specialists.size() - 1)])
		# Lo specialista non è più per forza l'ultimo. È il formato con più
		# carattere della sessione — il grafico, il circuito, il ciclo — e
		# tenerlo sempre in coda significava che le prime tre campate erano
		# sempre le tre generiche. La posizione dipende da livello e materia,
		# come la rotazione qui sopra.
		var posto := posmod(hash(subject) * 3 + level, plan.size() + 1)
		plan.insert(posto, scelto)
	if plan.is_empty():
		# Fallback generico: un ordinamento numerico sempre valido.
		plan.append("numeric")

	var nodes: Array = []
	var total := plan.size()
	for idx in total:
		var fmt := str(plan[idx])
		var step := gradient_step(idx, total)
		var runtime_fmt := "ordering" if fmt == "numeric" else fmt
		nodes.append(_build_node_for_format(runtime_fmt, subject, level, step, generator, idx))
	# La campata centrale ha difficolta' esattamente uguale alla fascia (le due
	# estremita' sono riscaldamento e finale). Sostituirla conserva il numero di
	# prove e garantisce che ogni sessione d'italiano alleni il grado del mondo.
	if subject == "italiano" and not nodes.is_empty():
		var band_index := floori(float(nodes.size()) / 2.0)
		var band_node := _italian_band_node(level, generator, band_index)
		if not band_node.is_empty():
			nodes[band_index] = band_node
	return {
		"sessionId": "minigame-%s-lvl%d" % [subject, level],
		"kind": "minigame",
		"subject": subject,
		"level": level,
		"nodes": nodes,
		"shields": 3,
		"pace": ContentManager.subject_pace(subject),
		"timed": false,
		"rewards": {"energyPerCorrect": 12, "onComplete": {"energy": 30, "fragments": 2}},
	}

## Costruisce una sessione normale, poi guida UNA campata verso l'argomento o la
## meccanica richiesti dal mondo. Il topic ha precedenza didattica; il formato
## entra quando non c'e' un ripasso mirato. Le altre campate restano varie.
func build_guided_minigame(subject: String, topic: String, format_hint: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var session := build_minigame(subject, level, generator)
	var target_format := ""
	var selected: Dictionary = {}
	var topic_candidates: Array = []
	var themed: Array = []
	if topic != "":
		for fmt_data in runtime_formats_for(subject, level):
			var fmt := str(fmt_data)
			for spec_data in eligible_specs(subject, fmt, level):
				var spec: Dictionary = spec_data
				if str(spec.get("topic", "")) != topic:
					continue
				var candidate := {"format": fmt, "spec": spec}
				topic_candidates.append(candidate)
				if str(spec.get("actionTheme", "")) != "":
					themed.append(candidate)
		var candidates := themed if not themed.is_empty() else topic_candidates
		if not candidates.is_empty():
			var candidate: Dictionary = candidates[generator.randi_range(0, candidates.size() - 1)]
			target_format = str(candidate["format"])
			selected = candidate["spec"] as Dictionary

	if target_format == "" and runtime_formats_for(subject, level).has(format_hint):
		target_format = format_hint
		var specs := eligible_specs(subject, target_format, level)
		if not specs.is_empty():
			selected = specs[generator.randi_range(0, specs.size() - 1)] as Dictionary
	if target_format == "":
		return session

	var nodes: Array = Array(session.get("nodes", [])).duplicate(true)
	if nodes.is_empty():
		return session
	var replace_at := nodes.size() - 1
	for index in nodes.size():
		var node: Dictionary = nodes[index]
		# La campata calibrata e' il riferimento della fascia e non va rimossa da
		# una richiesta di pratica guidata: si sostituisce un'altra campata.
		if node.has("calibrationBand"):
			continue
		if str(node.get("format", "")) == target_format:
			replace_at = index
			break
	var step := gradient_step(replace_at, nodes.size())
	var replacement := _build_node_for_format(target_format, subject, level, step, generator, replace_at, selected)
	if replacement.is_empty():
		return session
	nodes[replace_at] = replacement
	session["nodes"] = nodes
	var guide := topic if topic != "" else target_format
	session["sessionId"] = "%s-guide-%s" % [str(session.get("sessionId", "minigame")), guide]
	return session

func build_topic_minigame(subject: String, topic: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	return build_guided_minigame(subject, topic, "", level, rng)

## **Il perimetro didattico di un corso vale anche per la pratica.**
## (3 settembre 2026)
##
## Fisica e musica sono corsi, non vetrine del banco: al mondo 5 si insegnano
## moto, forze e leve, e solo quelli si possono chiedere. La regola era applicata
## in due punti su tre — `build_mission` e `inject_non_mc` — e non nel terzo,
## che è **l'evento pratica**: il minigioco che si trova camminando, e che da
## solo vale due terzi dei nodi di un mondo.
##
## Misurato prima di collegarlo: il 71% dei nodi di pratica di fisica e il 63%
## di quelli di musica stavano fuori dalla lezione del loro mondo. Il bambino
## riceveva la densità dei materiali al mondo che gli aveva appena spiegato che
## cos'è una leva.
##
## Vuoto quando la materia non è un corso, o quando il mondo non è il suo: fuori
## dai propri due mondi una materia non ha lezione, e lì la pratica resta libera
## come per tutte le altre dieci.
static func perimetro_di(subject: String, level: int) -> Dictionary:
	if not ContentManager.STRICT_LESSON_SUBJECTS.has(subject):
		return {}
	return ContentManager.lesson_topic_set(subject, level)

## Le specifiche di un formato che stanno dentro il perimetro. Se nessuna ci
## sta, restituisce la lista intera: meglio una prova fuori perimetro che una
## materia senza minigioco — ma è una condizione che `pratica_perimetro_audit`
## non lascia esistere, perché vorrebbe dire che quel mondo insegna qualcosa che
## non si può esercitare.
static func _dentro_il_perimetro(list: Array, perimetro: Dictionary) -> Array:
	if perimetro.is_empty():
		return list
	var dentro: Array = []
	for spec in list:
		if perimetro.has(str((spec as Dictionary).get("topic", ""))):
			dentro.append(spec)
	return dentro if not dentro.is_empty() else list

func _pick(list: Array, rng: RandomNumberGenerator, level: int = -1) -> Dictionary:
	# Con `level` >= 0 si scartano gli spec con "minLevel" oltre il livello: così i
	# contenuti da scuola media (analisi grammaticale/logica, modi e tempi) arrivano
	# nei mondi avanzati e non spiazzano un principiante. Se nessuno è ammesso si
	# ripiega sull'intera lista, per non lasciare mai la materia senza minigioco.
	if level >= 0:
		var eligible: Array = []
		for spec in list:
			if int((spec as Dictionary).get("minLevel", 0)) <= level:
				eligible.append(spec)
		if not eligible.is_empty():
			return eligible[rng.randi_range(0, eligible.size() - 1)]
	return list[rng.randi_range(0, list.size() - 1)]

## Come `_has_eligible`, ma dentro il perimetro del corso: serve alla scaletta
## della pratica, che deve scartare un formato specialista quando quel mondo non
## ha niente da fargli dire.
func _has_eligible_dentro(list: Array, level: int, perimetro: Dictionary) -> bool:
	for spec in list:
		var s: Dictionary = spec
		if int(s.get("minLevel", 0)) > level:
			continue
		if perimetro.is_empty() or perimetro.has(str(s.get("topic", ""))):
			return true
	return false

## Quante specifiche sono insieme idonee al livello e dentro il perimetro.
func _quante_dentro(list: Array, level: int, perimetro: Dictionary) -> int:
	var quante := 0
	for spec in list:
		var s: Dictionary = spec
		if int(s.get("minLevel", 0)) > level:
			continue
		if perimetro.is_empty() or perimetro.has(str(s.get("topic", ""))):
			quante += 1
	return quante

func _has_eligible(list: Array, level: int) -> bool:
	for spec in list:
		if int((spec as Dictionary).get("minLevel", 0)) <= level:
			return true
	return false

## L'abbinamento è sempre stato un'estrazione: pesca 3–5 coppie fra quelle
## dichiarate. Ora passa da `ExercisePool` come tutti gli altri, così la stessa
## regola vale per le specifiche statiche e per quelle a insieme — ed è la stessa
## funzione che dichiara la profondità agli audit, invece di due conti separati
## che possono divergere.
func _matching_node(subject: String, group: Dictionary, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	# Lati sinistri e destri tutti distinti: un abbinamento con due destre uguali
	# non ha una soluzione sola (lo stesso vincolo che `validate` pretende dopo).
	var drawn := ExercisePool.draw(group, "pairs", matching_draw(group, level, step), rng, MATCHING_UNIQUE)
	var pairs: Array = []
	for entry in drawn:
		var p: Array = entry
		pairs.append({"left": str(p[0]), "right": str(p[1])})
	return {
		"id": "minigame-match-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(group["topic"]),
		"difficulty": difficulty_of(level, step),
		"format": "matching",
		"prompt": "Abbina ogni elemento alla sua coppia.",
		"pairs": pairs,
		# La spiegazione viene dal GRUPPO, non dal formato. Fino al 5 agosto 2026
		# qui c'era una stringa sola, identica in ogni materia e in ogni mondo:
		# «Collega ogni elemento a sinistra con quello giusto a destra». Non è una
		# spiegazione, è l'istruzione di come si gioca — ripetuta dopo che il
		# bambino ha già giocato. L'abbinamento è il 22% di tutto ciò che si
		# gioca: era il 22% del gioco che non insegnava niente dopo la risposta.
		"explanation": str(group.get("explanation", "")),
	}

## Smistamento. Una specifica che dichiara `draw` diventa un insieme: si pescano
## `draw` tessere fra quelle disponibili, garantendo **almeno una per categoria** —
## un contenitore vuoto non è una prova più facile, è una prova rotta.
func _classification_node(subject: String, spec: Dictionary, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var assignments: Dictionary = spec["assignments"]
	var categories: Array = Array(spec["categories"])
	var count := classification_draw(spec, step)
	var items: Array = []
	if count < assignments.size():
		items = ExercisePool.draw_covering(assignments, categories, count, rng)
		var subset: Dictionary = {}
		for key in items:
			subset[key] = assignments[key]
		assignments = subset
	else:
		items = assignments.keys()
		_shuffle(items, rng)
	return {
		"id": "minigame-classify-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty_of(level, step),
		"format": "classification",
		"prompt": str(spec["prompt"]),
		"items": items,
		"categories": categories.duplicate(),
		"assignments": assignments.duplicate(true),
		# Come per l'abbinamento: la ragione sta nella specifica, perché è lì che
		# si sa PERCHÉ quelle tessere stanno in quei gruppi.
		"explanation": str(spec.get("explanation", "")),
	}

func _graph_node(subject: String, spec: Dictionary, difficulty: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	return {
		"id": "minigame-graph-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "graph",
		"prompt": str(question["prompt"]),
		"points": (spec["points"] as Array).duplicate(true),
		"xLabel": str(spec.get("xLabel", "x")),
		"yLabel": str(spec.get("yLabel", "y")),
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _circuit_node(subject: String, spec: Dictionary, difficulty: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	return {
		"id": "minigame-circuit-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "circuit",
		"prompt": str(question["prompt"]),
		"components": (spec["components"] as Array).duplicate(true),
		"connections": (spec["connections"] as Array).duplicate(true),
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _cycle_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var stages: Array = (spec["stages"] as Array).duplicate(true)
	var correct: Array = (spec["correctOrder"] as Array).duplicate()
	_shuffle(stages, rng)
	var presented := stages.map(func(stage): return str((stage as Dictionary).get("id", "")))
	if presented == correct and stages.size() >= 2:
		var first = stages[0]
		stages[0] = stages[1]
		stages[1] = first
	return {
		"id": "minigame-cycle-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "cycle",
		"prompt": str(spec["prompt"]),
		"stages": stages,
		"correctOrder": correct,
		"explanation": str(spec["explanation"]),
	}

func _notation_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var symbols: Array = (spec["symbols"] as Array).duplicate(true)
	_shuffle(symbols, rng)
	return {
		"id": "minigame-notation-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "notation",
		"prompt": str(question["prompt"]),
		"staff": (spec["staff"] as Dictionary).duplicate(true),
		"symbols": symbols,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _swipe_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var tutte: Array = spec["statements"] as Array
	var consentite: Array = []
	for statement_data in tutte:
		var statement: Dictionary = statement_data
		if int(statement.get("minDifficulty", 1)) <= difficulty:
			consentite.append(statement.duplicate(true))
	if consentite.is_empty():
		consentite = tutte.duplicate(true)

	var frasi: Array = consentite
	var draw := mini(int(spec.get("draw", consentite.size())), consentite.size())
	if draw < consentite.size():
		# I contenuti appena sbloccati entrano sempre nel round; il resto completa
		# un mazzo vero/falso equilibrato. Cosi la difficolta non e solo un numero
		# nell'HUD: cambia davvero le operazioni che il giocatore deve dominare.
		var tier_true: Array = []
		var tier_false: Array = []
		var lower_true: Array = []
		var lower_false: Array = []
		for statement_data in consentite:
			var statement: Dictionary = statement_data
			var target: Array
			if bool(statement.get("correct", false)):
				target = tier_true if int(statement.get("minDifficulty", 1)) == difficulty else lower_true
			else:
				target = tier_false if int(statement.get("minDifficulty", 1)) == difficulty else lower_false
			target.append(statement)
		for pool in [tier_true, tier_false, lower_true, lower_false]:
			_shuffle(pool, rng)
		var true_pool := tier_true + lower_true
		var false_pool := tier_false + lower_false
		var per_side := int(ceil(float(draw) * 0.5))
		var used_true := mini(per_side, true_pool.size())
		var used_false := mini(draw - used_true, false_pool.size())
		frasi = []
		for pool_index in used_true:
			frasi.append(true_pool[pool_index])
		for pool_index in used_false:
			frasi.append(false_pool[pool_index])
		if frasi.size() < draw:
			var extra_true := mini(draw - frasi.size(), true_pool.size() - used_true)
			for offset in extra_true:
				frasi.append(true_pool[used_true + offset])
		if frasi.size() < draw:
			var extra_false := mini(draw - frasi.size(), false_pool.size() - used_false)
			for offset in extra_false:
				frasi.append(false_pool[used_false + offset])
	_shuffle(frasi, rng)
	var seconds := float(spec.get("seconds", 45.0))
	var seconds_by_difficulty: Array = spec.get("secondsByDifficulty", [])
	if difficulty < seconds_by_difficulty.size() and float(seconds_by_difficulty[difficulty]) > 0.0:
		seconds = float(seconds_by_difficulty[difficulty])
	return {
		"id": "minigame-swipe-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "swipe",
		"prompt": str(spec["prompt"]),
		"seconds": seconds,
		"minAccuracy": float(spec.get("minAccuracy", 0.75)),
		"actionTheme": str(spec.get("actionTheme", "")),
		# Le affermazioni si mescolano: l'ordine non è contenuto, e un round
		# rigiocato che ripropone la stessa fila si impara a memoria.
		"statements": frasi,
		"answer": "",
		"explanation": str(spec["explanation"]),
	}

func _clue_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-clue-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "clue",
		"prompt": str(question["prompt"]),
		# Gli indizi NON si mescolano: l'ordine è il contenuto. Mescolarli
		# renderebbe la prima carta decisiva una volta su quattro, e la scelta
		# di quando fermarsi diventerebbe fortuna.
		"clues": (spec.get("clues", []) as Array).duplicate(true),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _timeline_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-timeline-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "timeline",
		"prompt": str(question["prompt"]),
		"min": float(spec.get("min", 0.0)),
		"max": float(spec.get("max", 100.0)),
		"labels": (spec.get("labels", []) as Array).duplicate(true),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _compose_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-compose-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "compose",
		"prompt": str(question["prompt"]),
		"slots": (spec.get("slots", []) as Array).duplicate(true),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _trace_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-trace-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "trace",
		"prompt": str(question["prompt"]),
		"steps": (spec.get("steps", []) as Array).duplicate(true),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _balance_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-balance-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "balance",
		"prompt": str(question["prompt"]),
		"left": (spec.get("left", []) as Array).duplicate(true),
		"right": (spec.get("right", []) as Array).duplicate(true),
		"gapSide": str(spec.get("gapSide", "right")),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _number_line_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-numline-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "number_line",
		"prompt": str(question["prompt"]),
		"min": float(spec.get("min", 0.0)),
		"max": float(spec.get("max", 10.0)),
		"tick": float(spec.get("tick", 1.0)),
		"labels": (spec.get("labels", []) as Array).duplicate(true),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _map_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-map-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "map",
		"prompt": str(question["prompt"]),
		"mapId": str(spec["mapId"]),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

func _hotspot_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var question := question_of(spec, idx)
	var targets: Array = (spec["targets"] as Array).duplicate(true)
	_shuffle(targets, rng)
	return {
		"id": "minigame-hotspot-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "hotspot",
		"prompt": str(question["prompt"]),
		"assetId": str(spec["assetId"]),
		"targets": targets,
		"answer": str(question["answer"]),
		"explanation": str(question["explanation"]),
	}

## Caccia all'errore. Dove le righe sono AFFERMAZIONI INDIPENDENTI (`shuffleLines`)
## vengono rimescolate a ogni partita e la riga giusta viene ricalcolata: senza,
## la soluzione resterebbe sempre nella stessa posizione e in alcune materie era
## *sempre* la terza — bastava impararlo per superare la prova senza leggerla.
## Dove invece l'ordine porta significato (codice, passaggi di un calcolo, premesse
## di un sillogismo) le righe non si toccano: mescolarle distruggerebbe l'esercizio.
func _code_debug_node(subject: String, spec: Dictionary, difficulty: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var lines: Array = (spec["codeLines"] as Array).duplicate()
	var answer_line := int(spec["answerLine"])
	var explanation := str(spec["explanation"])
	if bool(spec.get("shuffleLines", false)):
		var solution := str(lines[answer_line - 1])
		# Le righe di commento ("# quale…?") restano in coda: sono la consegna.
		var body: Array = []
		var trailer: Array = []
		for line in lines:
			if str(line).begins_with("#"):
				trailer.append(line)
			else:
				body.append(line)
		if body.size() >= 2:
			ExerciseInteraction.shuffle_avoiding(body, rng, body.duplicate())
			lines = body + trailer
			answer_line = lines.find(solution) + 1
			explanation = _renumber_explanation(explanation, answer_line)
	return {
		"id": "minigame-code-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "code_debug",
		"prompt": str(spec["prompt"]),
		"codeLines": lines,
		"answerLine": answer_line,
		"answer": str(answer_line),
		"explanation": explanation,
	}

# Le spiegazioni della caccia all'errore iniziano con "Riga N:". Se le righe sono
# state rimescolate quel numero va corretto, altrimenti la spiegazione indicherebbe
# una riga innocente — peggio dell'errore stesso, perché insegna la cosa sbagliata.
func _renumber_explanation(explanation: String, answer_line: int) -> String:
	var regex := RegEx.create_from_string("^Riga\\s+\\d+")
	if regex.search(explanation) == null:
		return explanation
	return regex.sub(explanation, "Riga %d" % answer_line)

## Ordinamento. Forma statica: `correctOrder` è la sequenza, sempre la stessa —
## profondità 1. Forma a insieme: `pool` elenca voci `{label, value}` e si pescano
## `draw` elementi, ordinati per VALORE (mai per etichetta: "10/12" viene dopo
## "1/2" per valore ma prima in ordine alfabetico). Le due forme convivono, così la
## migrazione di una materia alla volta non rompe le altre.
func _ordering_node(subject: String, spec: Dictionary, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var correct: Array = []
	# {label, value} dei soli ordinamenti a insieme: serve a chi insegna il
	# fatto prima di chiederlo (KnowledgeCodex.unknown_facts, 16 agosto 2026),
	# perché un `correctOrder` a lista fissa ripropone sempre lo stesso pescato
	# e non ha bisogno di un fatto nuovo da spiegare ogni volta.
	var detail: Array = []
	if ExercisePool.is_pool(spec):
		# Etichette e valori tutti distinti: due voci con lo stesso valore
		# renderebbero l'ordine ambiguo, due con la stessa etichetta impossibile.
		var drawn := ExercisePool.draw(spec, "", ordering_draw(spec, level, step), rng, ORDERING_UNIQUE)
		drawn.sort_custom(func(a, b): return float((a as Dictionary)["value"]) < float((b as Dictionary)["value"]))
		if bool(spec.get("descending", false)):
			drawn.reverse()
		for entry in drawn:
			correct.append(str((entry as Dictionary)["label"]))
		detail = drawn.duplicate(true)
	else:
		correct = (spec["correctOrder"] as Array).duplicate()
	var items := correct.duplicate()
	# Mai presentare gli elementi già ordinati: sarebbe una prova che si risolve
	# premendo in fila (misurato: capitava a un ordinamento su ventuno).
	ExerciseInteraction.shuffle_avoiding(items, rng, correct)
	return {
		"id": "minigame-order-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty_of(level, step),
		"format": "ordering",
		"prompt": str(spec["prompt"]),
		"items": items,
		"correctOrder": correct,
		"correctOrderDetail": detail,
		# L'ordine giusto resta — è informazione utile — ma da solo non spiegava
		# niente: diceva *cosa*, mai *perché quello*. Il criterio dell'ordinamento
		# viene dalla specifica e va davanti, perché è la parte che si porta via.
		"explanation": _spiegazione_ordinamento(spec, correct),
	}

## Ordinamento QUANTITATIVO di matematica. Non ordina numeri nudi: ordina il
## RISULTATO di operazioni, così il compito richiede davvero di calcolare.
##
## Difetto corretto il 30 luglio, segnalato da un playthrough. La versione
## precedente estraeva `count = 3 + level/6` interi distinti in `1..5 + level*2`
## e chiedeva di ordinarli: al livello 1 erano tre numeri sotto il 7 («metti in
## ordine 5, 6, 2»), al livello 24 cinque numeri sotto il 53. Tre difetti in uno:
##
##  1. **sotto la fascia 10–13** — ordinare tre interi a una cifra non è
##     difficoltà 1 per la secondaria di primo grado, è un compito di prima
##     elementare;
##  2. **fuori dalla lezione** — dichiarava `topic: "sequenze"`, che non è tra gli
##     argomenti di nessuno dei due mondi di matematica (il mondo 1 dichiara
##     tabelline/problemi, il 13 proporzioni/frazioni/geometria). Accumulava così
##     padronanza su un argomento mai insegnato lì, e quella padronanza conta
##     nella dimensione COPERTURA del gate e verso lo stato "consolidato";
##  3. **invisibile agli audit** — essendo procedurale non compariva in
##     `topics_for()`, che si costruisce dalle tabelle: nessun controllo poteva
##     vedere il topic che emetteva davvero a runtime.
##
## Ora l'argomento è quello che il mondo dichiara: `tabelline` fino al 12,
## `frazioni` dal 13.
## Criterio + ordine. Se la specifica non dichiara un criterio resta il solo
## elenco, ed è esattamente il caso che `minigame_explanation_audit` vieta.
func _spiegazione_ordinamento(spec: Dictionary, correct: Array) -> String:
	var elenco := "Ordine giusto: %s." % ", ".join(PackedStringArray(correct))
	var criterio := str(spec.get("explanation", "")).strip_edges()
	return elenco if criterio == "" else "%s %s" % [criterio, elenco]

## PONTE DELLE TRASFORMAZIONI — primo minigioco in cui la matematica è la
## regola fisica del sistema. Non si sceglie un risultato: si montano macchine,
## si fa partire la sfera e si osservano tutti i valori intermedi.
func _machine_path_node(subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var difficulty := difficulty_of(level, step)
	var slot_count := 2 if difficulty == 1 else 3 if difficulty <= 3 else 4
	var start := rng.randi_range(2, 9 + difficulty * 2)
	var machines: Array = []
	var solution: Array = []
	var current := start

	# Le bande cambiano il tipo di ragionamento, non soltanto la grandezza dei
	# numeri. Dalla terza compare la divisione, ma solo quando è esatta.
	var plan: Array = []
	if difficulty == 1:
		plan = [
			{"op": "add", "value": rng.randi_range(2, 6)},
			{"op": "multiply", "value": rng.randi_range(2, 3)},
		]
	elif difficulty == 2:
		plan = [
			{"op": "multiply", "value": rng.randi_range(2, 4)},
			{"op": "add", "value": rng.randi_range(2, 8)},
			{"op": "subtract", "value": rng.randi_range(1, mini(6, start))},
		]
	else:
		var divisor := rng.randi_range(2, 4)
		start = divisor * rng.randi_range(3, 8 + difficulty)
		plan = [
			{"op": "divide", "value": divisor},
			{"op": "add", "value": rng.randi_range(2, 9)},
			{"op": "multiply", "value": rng.randi_range(2, 4)},
		]
		if slot_count == 4:
			plan.append({"op": "subtract", "value": rng.randi_range(2, 8)})

	# Le bande avanzate scelgono una nuova partenza divisibile: il calcolo del
	# traguardo deve partire da quella, non dal valore provvisorio iniziale.
	current = start
	for op_index in plan.size():
		var spec := plan[op_index] as Dictionary
		var id := "m%d" % op_index
		var machine := _number_machine(id, str(spec["op"]), int(spec["value"]))
		machines.append(machine)
		solution.append(id)
		current = int(ExerciseInteraction.evaluate_machine_path(current, [id], [machine]).get("value", current))

	var target := current
	# Due macchine credibili ma non necessarie. I valori sono scelti lontano da
	# quelli del percorso per evitare doppioni visivi e tocchi ambigui.
	machines.append(_number_machine("d0", "add", 10 + difficulty))
	machines.append(_number_machine("d1", "multiply", 5 + difficulty))
	_shuffle(machines, rng)

	var labels: Array = []
	for id in solution:
		for raw in machines:
			var machine := raw as Dictionary
			if str(machine.get("id", "")) == str(id):
				labels.append(str(machine.get("label", "")))
				break
	return {
		"id": "minigame-machine-path-%s-%d-%d" % [subject, level, idx],
		"subject": subject,
		"topic": "calcolo",
		"difficulty": difficulty,
		"format": "machine_path",
		"title": "Il ponte delle trasformazioni",
		"prompt": "La sfera parte con %d unità. Il ponte si apre a %d. Monta %d macchine e avvia il percorso." % [start, target, slot_count],
		"start": start,
		"target": target,
		"slotCount": slot_count,
		"machines": machines,
		"solution": solution,
		"explanation": "Ogni macchina lavora sul risultato della precedente. Un percorso possibile è: %s. La sfera arriva così a %d." % ["  »  ".join(PackedStringArray(labels)), target],
	}

func _number_machine(id: String, op: String, value: int) -> Dictionary:
	var symbol: String = str({"add": "+", "subtract": "−", "multiply": "×", "divide": "÷"}.get(op, "?"))
	return {"id": id, "op": op, "value": value, "label": "%s %d" % [symbol, value]}

## IL CAMPIONE SENZA NOME — un piccolo giallo scientifico. Il giocatore sceglie
## gli esperimenti, raccoglie osservazioni e formula l'ipotesi; la risposta è
## l'ultima conseguenza del metodo, non il centro dell'interazione.
func _mystery_sample_node(subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var difficulty := difficulty_of(level, step)
	var all_samples := [
		{"id": "iron", "name": "Ferro"},
		{"id": "copper", "name": "Rame"},
		{"id": "glass", "name": "Vetro"},
		{"id": "cork", "name": "Sughero"},
		{"id": "ceramic", "name": "Ceramica"},
	]
	var sample_ids: Array = (
		["iron", "glass", "cork"] if difficulty <= 1
		else ["iron", "copper", "glass", "cork"] if difficulty == 2
		else ["iron", "copper", "glass", "cork", "ceramic"])
	var samples: Array = []
	for sample in all_samples:
		if sample_ids.has(str((sample as Dictionary).get("id", ""))):
			samples.append((sample as Dictionary).duplicate())
	_shuffle(samples, rng)
	var tests: Array = [
		{"id": "magnet", "label": "Avvicina la calamita", "short": "CALAMITA", "glyph": "~"},
		{"id": "circuit", "label": "Chiudi il circuito", "short": "CIRCUITO", "glyph": "*"},
		{"id": "light", "label": "Accendi la lampada", "short": "LUCE", "glyph": "*"},
		{"id": "water", "label": "Posa sull'acqua", "short": "ACQUA", "glyph": "≈"},
	]
	if difficulty <= 1:
		tests = tests.filter(func(test): return str((test as Dictionary).get("id", "")) != "circuit")
	_shuffle(tests, rng)
	var answer := str((samples[rng.randi_range(0, samples.size() - 1)] as Dictionary).get("id", ""))
	# Più modi di spiegare lo stesso materiale, non uno solo.
	#
	# Con una frase fissa per materiale, il ferro da solo copriva il 27% dei nodi
	# del formato — `explanation_coverage_audit` lo rifiuta sopra il 25%, e ha
	# ragione per un motivo che non è statistico: una frase che tornerà identica
	# ogni volta smette di essere letta dopo la seconda. Ogni variante dice la
	# stessa proprietà partendo da una prova diversa, così chi rigioca trova un
	# appiglio nuovo invece di riconoscere una formula.
	var explanations := {
		"iron": [
			"Il ferro conduce la corrente e, fra questi campioni, è l'unico attirato dalla calamita.",
			"La calamita da sola basta a riconoscere il ferro: nessuno degli altri campioni le risponde.",
			"Il ferro fa passare la corrente e affonda, ma è la calamita a toglierti ogni dubbio.",
		],
		"copper": [
			"Il rame conduce la corrente ma non viene attirato dalla calamita: le due prove insieme lo distinguono dal ferro.",
			"Se la lampadina si accende e la calamita resta ferma, il metallo è rame e non ferro.",
			"Il rame è un metallo che conduce, però alla calamita è indifferente: una prova sola qui non basta.",
		],
		"glass": [
			"Il vetro non conduce e non galleggia, ma lascia passare il fascio della lampada.",
			"Trasparente alla luce e muto alla corrente: è la coppia di prove che indica il vetro.",
			"Il vetro affonda come la ceramica, ma la luce lo attraversa — ed è lì che si separano.",
		],
		"cork": [
			"Il sughero non conduce e non lascia passare la luce, ma galleggia perché è meno denso dell'acqua.",
			"È l'unico campione che resta a galla: il sughero pesa poco per quanto spazio occupa.",
			"Sughero: la luce non passa, la corrente nemmeno, però l'acqua lo tiene su.",
		],
		"ceramic": [
			"La ceramica non conduce, non è attirata dalla calamita, non lascia passare la luce e affonda: conta l'insieme delle prove.",
			"Nessuna prova da sola riconosce la ceramica: la si trova escludendo tutti gli altri.",
			"La ceramica dice no a ogni prova e va a fondo: è il profilo di chi non reagisce a niente.",
		],
	}
	var varianti := Array(explanations.get(answer, []))
	var spiegazione := (
		str(varianti[rng.randi_range(0, varianti.size() - 1)])
		if not varianti.is_empty()
		else "Le proprietà osservate permettono di riconoscere il materiale."
	)
	return {
		"id": "minigame-mystery-sample-%s-%d-%d" % [subject, level, idx],
		"subject": subject,
		# **L'argomento dipende da chi lo gioca.** (3 settembre 2026)
		#
		# Le quattro prove sono calamita, circuito, luce e acqua, e chiedono di
		# riconoscere un materiale: per SCIENZE e' «materia», e lo e' sempre stato.
		# Ma fisica e' un corso a perimetro stretto, e «materia» non e' fra i suoi
		# sei nuclei: il campione senza nome — il suo minigioco piu' bello — non
		# poteva comparire in nessuno dei suoi due mondi.
		#
		# Non e' un'etichetta messa per farlo passare: la prova che decide e' quella
		# dell'acqua, e le spiegazioni lo dicono gia' («il sughero galleggia perche'
		# e' meno denso dell'acqua», «la biglia d'acciaio va a fondo»). Per fisica
		# quel gesto e' galleggiamento, che e' esattamente cio' che il mondo 17
		# insegna.
		"topic": "galleggiamento" if subject == "fisica" else "materia",
		"difficulty": difficulty,
		"format": "mystery_sample",
		"title": "Il campione senza nome",
		"prompt": "Dal Relitto è arrivato un campione senza etichetta. Scegli gli esperimenti, osserva le reazioni e scopri di quale materiale si tratta.",
		"samples": samples,
		"tests": tests,
		"results": _mystery_sample_results(),
		"answer": answer,
		"minTests": 3 if difficulty >= 4 else 2,
		"explanation": spiegazione,
	}

func _mystery_sample_results() -> Dictionary:
	return {
		"iron": {
			"magnet": "La calamita scatta verso il campione.",
			"circuit": "La lampadina si accende: la corrente passa.",
			"light": "Il fascio non attraversa il campione.",
			"water": "Il campione affonda.",
		},
		"copper": {
			"magnet": "La calamita non si muove.",
			"circuit": "La lampadina si accende: la corrente passa.",
			"light": "Il fascio non attraversa il campione.",
			"water": "Il campione affonda.",
		},
		"glass": {
			"magnet": "La calamita non si muove.",
			"circuit": "La lampadina resta spenta: la corrente non passa.",
			"light": "Il fascio attraversa il campione.",
			"water": "Il campione affonda.",
		},
		"cork": {
			"magnet": "La calamita non si muove.",
			"circuit": "La lampadina resta spenta: la corrente non passa.",
			"light": "Il fascio non attraversa il campione.",
			"water": "Il campione galleggia.",
		},
		"ceramic": {
			"magnet": "La calamita non si muove.",
			"circuit": "La lampadina resta spenta: la corrente non passa.",
			"light": "Il fascio non attraversa il campione.",
			"water": "Il campione affonda.",
		},
	}

## IL MESSAGGIO FUORI TEMPO — grammatica trasformata in indagine. Tre ghiere
## separano domande che spesso vengono confuse: QUANDO accade, CON QUALE
## INTENZIONE viene detto e QUALE FORMA completa davvero la frase.
func _verb_decoder_node(subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var difficulty := difficulty_of(level, step)
	var eligible: Array = []
	for raw in _verb_decoder_templates(subject):
		if int((raw as Dictionary).get("tier", 1)) <= difficulty:
			eligible.append(raw)
	var spec := (eligible[rng.randi_range(0, eligible.size() - 1)] as Dictionary).duplicate(true)
	var time_choices: Array = []
	for raw in Array(spec.get("times", [])):
		var pair := raw as Array
		time_choices.append({"id": str(pair[0]), "label": str(pair[1])})
	var mood_choices: Array = []
	for raw in Array(spec.get("moods", [])):
		var pair := raw as Array
		mood_choices.append({"id": str(pair[0]), "label": str(pair[1])})
	var forms: Array = []
	var labels: Array = spec.get("forms", [])
	for form_index in labels.size():
		forms.append({
			"id": "right" if form_index == 0 else "decoy%d" % form_index,
			"label": str(labels[form_index]),
		})
	_shuffle(time_choices, rng)
	_shuffle(mood_choices, rng)
	_shuffle(forms, rng)
	return {
		"id": "minigame-verb-decoder-%s-%d-%d" % [str(spec.get("case", "case")), level, idx],
		"subject": subject,
		"topic": str(spec.get("topic", "verbi-mappa-modi-tempi")),
		"difficulty": difficulty,
		"format": "verb_decoder",
		"title": "Il messaggio fuori tempo",
		"prompt": "Una voce dal Relitto ha lasciato una frase incompleta. Regola tempo e modo, poi scegli la forma che restituisce il significato.",
		"segments": Array(spec.get("segments", [])).duplicate(),
		"clues": Array(spec.get("clues", [])).duplicate(),
		"timeChoices": time_choices,
		"moodChoices": mood_choices,
		"forms": forms,
		"solution": {
			"time": str(spec.get("time", "")),
			"mood": str(spec.get("mood", "")),
			"form": "right",
		},
		"hints": (spec.get("hints", {}) as Dictionary).duplicate(),
		"discovery": str(spec.get("discovery", "")),
		"explanation": str(spec.get("explanation", "")),
	}

## Casi scritti a mano: ogni distrattore cambia davvero tempo o modo, e ogni
## soluzione ha una parola-spia o un rapporto logico che la rende univoca.
##
## **Due materie, dal 9 settembre 2026.** Il decodificatore era il formato-firma
## dell'italiano, ma le tre ghiere — tempo, modo, forma — sono la coniugazione di
## qualunque lingua, e in inglese sono il gesto che mancava: la grammatica del
## banco si poteva solo crocettare. Il campo `tier` di ogni caso E' la fascia
## (1..8), quindi la progressione non ha avuto bisogno di nessuna impalcatura
## nuova: al mondo 4 si aprono i casi 1-3, al mondo 16 fino al settimo.
static func _verb_decoder_templates(subject: String = "italiano") -> Array:
	if subject == "inglese":
		return _verb_decoder_templates_inglese()
	return [
		{"case":"now", "tier":1, "topic":"tempi-indicativo",
			"segments":["Adesso NORA", "la mappa sul tavolo."], "time":"presente", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio o desiderio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["osserva","ha osservato","osserverà"], "clues":["adesso","un fatto osservato"],
			"hints":{"time":"“Adesso” porta l'azione nel presente.","mood":"La frase presenta un fatto, quindi usa l'indicativo.","form":"Serve la forma che concorda con NORA e indica il presente."},
			"discovery":"Sul bordo della mappa compare una traccia appena disegnata.",
			"explanation":"“Adesso” indica il presente; la frase racconta un fatto come reale, quindi usa l'indicativo presente: osserva."},
		{"case":"yesterday", "tier":1, "topic":"tempi-indicativo",
			"segments":["Ieri Rame", "una chiave sotto la passerella."], "time":"passato_prossimo", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio o desiderio"],["imperativo","IMPERATIVO · ordine"]],
			"forms":["ha trovato","trova","troverà"], "clues":["ieri","azione conclusa"],
			"hints":{"time":"“Ieri” indica un fatto già concluso.","mood":"Il ritrovamento viene raccontato come reale.","form":"Cerca ausiliare + participio: è un tempo composto."},
			"discovery":"La chiave apre un cassetto che nessuno aveva notato.",
			"explanation":"“Ieri” e l'azione conclusa richiedono il passato prossimo indicativo: ha trovato."},
		{"case":"tomorrow", "tier":1, "topic":"tempi-indicativo",
			"segments":["Domani NORA", "il corridoio oltre il vetro."], "time":"futuro_semplice", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto previsto"],["condizionale","CONDIZIONALE · possibilità"],["imperativo","IMPERATIVO · ordine"]],
			"forms":["esplorerà","esplora","esplorerebbe"], "clues":["domani","programma stabilito"],
			"hints":{"time":"“Domani” sposta l'azione nel futuro.","mood":"È un programma presentato come certo, non come ipotesi.","form":"La desinenza -erà indica il futuro della terza persona."},
			"discovery":"La voce conosce un luogo che non compare sulle mappe.",
			"explanation":"“Domani” indica futuro; il programma è presentato come certo, quindi indicativo futuro semplice: esplorerà."},
		{"case":"habit", "tier":1, "topic":"tempi-indicativo",
			"segments":["Ogni notte la luce azzurra", "tre volte."], "time":"presente", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["imperfetto","IMPERFETTO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["lampeggia","lampeggiava","lampeggerebbe"], "clues":["ogni notte","fenomeno che si ripete"],
			"hints":{"time":"Un'abitudine ancora valida può essere espressa al presente.","mood":"La luce viene descritta come un fenomeno osservato.","form":"Il soggetto è singolare: la luce lampeggia."},
			"discovery":"I tre lampi sembrano una richiesta di risposta.",
			"explanation":"“Ogni notte” descrive qui un'abitudine ancora valida: indicativo presente, lampeggia."},
		{"case":"while", "tier":2, "topic":"tempi-indicativo",
			"segments":["Mentre Rame", "il corridoio, una porta si aprì."], "time":"imperfetto", "mood":"indicativo",
			"times":[["imperfetto","IMPERFETTO"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["esplorava","ha esplorato","esplorerà"], "clues":["mentre","azione in corso nel passato"],
			"hints":{"time":"“Mentre” presenta un'azione in corso quando ne accade un'altra.","mood":"Entrambe le azioni sono narrate come fatti.","form":"L'imperfetto di esplorare termina in -ava."},
			"discovery":"La porta reagì al passaggio di Rame, non a un comando.",
			"explanation":"L'azione di esplorare era in corso quando la porta si aprì: indicativo imperfetto, esplorava."},
		{"case":"before", "tier":2, "topic":"tempi-indicativo",
			"segments":["Quando arrivammo, NORA", "già il simbolo."], "time":"trapassato_prossimo", "mood":"indicativo",
			"times":[["trapassato_prossimo","TRAPASSATO PROSSIMO"],["passato_prossimo","PASSATO PROSSIMO"],["imperfetto","IMPERFETTO"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["aveva decifrato","ha decifrato","decifrava"], "clues":["quando arrivammo","l'altra azione era già conclusa"],
			"hints":{"time":"Un fatto concluso prima di un altro fatto passato usa il trapassato prossimo.","mood":"La decifrazione è presentata come reale.","form":"Serve aveva + participio passato."},
			"discovery":"NORA aveva aspettato il gruppo prima di aprire il passaggio.",
			"explanation":"Decifrare avviene prima del nostro arrivo, già passato: indicativo trapassato prossimo, aveva decifrato."},
		{"case":"command", "tier":2, "topic":"imperativo-infinito-participio-gerundio",
			"segments":["Rame,", "la leva soltanto al mio via."], "time":"presente", "mood":"imperativo",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["imperativo","IMPERATIVO · ordine"],["indicativo","INDICATIVO · fatto"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["tira","tirerai","tireresti"], "clues":["Rame, ...","un'istruzione diretta"],
			"hints":{"time":"L'ordine riguarda ciò che Rame deve fare ora.","mood":"Un'istruzione diretta usa l'imperativo.","form":"Alla seconda persona singolare: tira."},
			"discovery":"La leva attiva una voce, ma solo nel momento esatto.",
			"explanation":"È un ordine rivolto direttamente a Rame: imperativo presente, tira."},
		{"case":"purpose", "tier":2, "topic":"imperativo-infinito-participio-gerundio",
			"segments":["Per", "la porta servono due chiavi."], "time":"presente", "mood":"infinito",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["infinito","INFINITO · forma base"],["imperativo","IMPERATIVO · ordine"],["indicativo","INDICATIVO · fatto"]],
			"forms":["aprire","apri","aperta"], "clues":["per ...","non è indicata una persona"],
			"hints":{"time":"L'azione è vista come scopo presente, non come già conclusa.","mood":"Dopo “per”, quando esprime uno scopo, si usa l'infinito.","form":"La forma base del verbo termina in -ire."},
			"discovery":"Le due chiavi hanno incisioni che si completano a vicenda.",
			"explanation":"“Per” introduce lo scopo e non indica chi compie l'azione: infinito presente, aprire."},
		{"case":"following", "tier":2, "topic":"imperativo-infinito-participio-gerundio",
			"segments":["", "le impronte, NORA trovò il pannello nascosto."], "time":"presente", "mood":"gerundio",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["gerundio","GERUNDIO · azione collegata"],["participio","PARTICIPIO · qualità o risultato"],["infinito","INFINITO · forma base"]],
			"forms":["Seguendo","Seguite","Seguire"], "clues":["due azioni dello stesso soggetto","azioni contemporanee"],
			"hints":{"time":"Seguire avviene mentre NORA cerca il pannello.","mood":"Il gerundio collega un'azione alla principale.","form":"Il gerundio di seguire termina in -endo."},
			"discovery":"Le impronte appartengono a qualcuno che conosceva il Relitto.",
			"explanation":"Le due azioni hanno lo stesso soggetto e avvengono insieme: gerundio presente, seguendo."},
		{"case":"possible", "tier":3, "topic":"congiuntivo-condizionale",
			"segments":["È possibile che la mappa", "incompleta."], "time":"presente", "mood":"congiuntivo",
			"times":[["presente","PRESENTE"],["imperfetto","IMPERFETTO"],["passato","PASSATO"]],
			"moods":[["congiuntivo","CONGIUNTIVO · dubbio o possibilità"],["indicativo","INDICATIVO · fatto"],["condizionale","CONDIZIONALE · conseguenza"]],
			"forms":["sia","è","sarebbe"], "clues":["è possibile che","ipotesi nel presente"],
			"hints":{"time":"L'ipotesi riguarda lo stato attuale della mappa.","mood":"“È possibile che” richiede il congiuntivo.","form":"Il congiuntivo presente di essere è sia."},
			"discovery":"Forse manca proprio il settore in cui ci troviamo.",
			"explanation":"“È possibile che” introduce un'ipotesi presente: congiuntivo presente, sia."},
		{"case":"feared", "tier":3, "topic":"concordanza-tempi-verbali",
			"segments":["Temevo che il custode", "del passaggio."], "time":"imperfetto", "mood":"congiuntivo",
			"times":[["presente","PRESENTE"],["imperfetto","IMPERFETTO"],["trapassato","TRAPASSATO"]],
			"moods":[["congiuntivo","CONGIUNTIVO · timore"],["indicativo","INDICATIVO · fatto"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["sapesse","sa","saprebbe"], "clues":["temevo che","timore contemporaneo nel passato"],
			"hints":{"time":"Il sapere è contemporaneo a un timore collocato nel passato.","mood":"“Temevo che” introduce un contenuto temuto, non affermato.","form":"Dopo una principale al passato serve qui sapesse."},
			"discovery":"Il custode non era sorpreso: aveva già visto quella porta.",
			"explanation":"Il timore è nel passato e il sapere è contemporaneo: congiuntivo imperfetto, sapesse."},
		{"case":"would_explore", "tier":3, "topic":"verbo",
			"segments":["Con una torcia, io", "anche il tunnel più buio."], "time":"presente", "mood":"condizionale",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["condizionale","CONDIZIONALE · possibilità"],["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"]],
			"forms":["esplorerei","esploro","esplorassi"], "clues":["con una torcia","azione possibile a una condizione"],
			"hints":{"time":"La possibilità riguarda il presente o il futuro vicino.","mood":"L'azione dipende dalla condizione “con una torcia”.","form":"Alla prima persona: esplorerei."},
			"discovery":"Nel tunnel c'è ancora una luce: qualcuno potrebbe essere dentro.",
			"explanation":"Esplorare dipende da una condizione: condizionale presente, esplorerei."},
		{"case":"if_present", "tier":3, "topic":"verbo",
			"segments":["Se trovassimo la chiave,", "la stanza nascosta."], "time":"presente", "mood":"condizionale",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["imperfetto","IMPERFETTO"]],
			"moods":[["condizionale","CONDIZIONALE · conseguenza"],["congiuntivo","CONGIUNTIVO · ipotesi"],["indicativo","INDICATIVO · fatto"]],
			"forms":["apriremmo","aprissimo","apriamo"], "clues":["se trovassimo","conseguenza possibile"],
			"hints":{"time":"La conseguenza è ancora possibile, non già conclusa.","mood":"Dopo l'ipotesi al congiuntivo, la conseguenza va al condizionale.","form":"La prima persona plurale termina in -remmo."},
			"discovery":"La stanza nascosta esiste, ma la sua posizione resta incerta.",
			"explanation":"“Se trovassimo” esprime l'ipotesi; la conseguenza usa il condizionale presente: apriremmo."},
		{"case":"if_past", "tier":4, "topic":"verbo",
			"segments":["Se avessimo letto il diario,", "la trappola."], "time":"passato", "mood":"condizionale",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["imperfetto","IMPERFETTO"]],
			"moods":[["condizionale","CONDIZIONALE · conseguenza"],["congiuntivo","CONGIUNTIVO · ipotesi"],["indicativo","INDICATIVO · fatto"]],
			"forms":["avremmo evitato","eviteremmo","avessimo evitato"], "clues":["se avessimo letto","occasione ormai trascorsa"],
			"hints":{"time":"L'occasione è passata e non può più realizzarsi.","mood":"La conseguenza non avvenuta usa il condizionale.","form":"Serve avremmo + participio passato."},
			"discovery":"Qualcuno aveva lasciato un avvertimento che non vedemmo in tempo.",
			"explanation":"L'ipotesi passata non si è realizzata: la conseguenza usa il condizionale passato, avremmo evitato."},
		{"case":"already_left", "tier":4, "topic":"verbo",
			"segments":["NORA pensava che Rame", "già partito."], "time":"trapassato", "mood":"congiuntivo",
			"times":[["presente","PRESENTE"],["imperfetto","IMPERFETTO"],["trapassato","TRAPASSATO"]],
			"moods":[["congiuntivo","CONGIUNTIVO · pensiero"],["indicativo","INDICATIVO · fatto"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["fosse","sia","sarebbe"], "clues":["pensava che","partire è precedente al pensiero"],
			"hints":{"time":"La partenza è anteriore a un pensiero già nel passato.","mood":"“Pensava che” introduce ciò che NORA riteneva, non un fatto certificato.","form":"Fosse + participio costruisce il congiuntivo trapassato."},
			"discovery":"Rame non era partito: stava seguendo la voce da solo.",
			"explanation":"La partenza sarebbe precedente al pensiero passato: congiuntivo trapassato, fosse già partito."},
		{"case":"after_decoding", "tier":4, "topic":"verbo",
			"segments":["Dopo", "il messaggio, Rame spense il ricevitore."], "time":"passato", "mood":"infinito",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["infinito","INFINITO · forma senza persona"],["gerundio","GERUNDIO · azione collegata"],["participio","PARTICIPIO · risultato"]],
			"forms":["aver decifrato","decifrare","avendo decifrato"], "clues":["dopo","azione conclusa prima della principale"],
			"hints":{"time":"Decifrare è concluso prima di spegnere.","mood":"Dopo la preposizione “dopo” si può usare l'infinito.","form":"L'infinito passato usa avere + participio: aver decifrato."},
			"discovery":"Il ricevitore spento continuò a sussurrare per alcuni secondi.",
			"explanation":"L'azione è anteriore e non indica una persona propria: infinito passato, aver decifrato."},
		{"case":"having_understood", "tier":4, "topic":"verbo",
			"segments":["Pur", "la risposta, NORA attese prima di parlare."], "time":"passato", "mood":"gerundio",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["gerundio","GERUNDIO · azione collegata"],["infinito","INFINITO · forma base"],["participio","PARTICIPIO · risultato"]],
			"forms":["avendo capito","capendo","aver capito"], "clues":["pur","capire avviene prima di attendere"],
			"hints":{"time":"NORA ha già capito quando decide di aspettare.","mood":"“Pur” collega qui due azioni dello stesso soggetto con il gerundio.","form":"Il gerundio passato usa avendo + participio."},
			"discovery":"NORA riconobbe la voce, ma non volle ancora dire di chi fosse.",
			"explanation":"Capire precede l'attesa e il soggetto resta NORA: gerundio passato, avendo capito."},
	]

## I casi inglesi del Messaggio fuori tempo. Le tre ghiere qui sono: QUANDO
## (tempo verbale), COME (afferma, nega, chiede — cioe' che cosa fa l'ausiliare)
## e QUALE forma. I due distrattori non sono forme sbagliate a caso: uno e' la
## risposta giusta con la ghiera del tempo storta, l'altro con quella della
## forma. Sbagliare una ghiera mostra quale delle due domande non era chiara.
static func _verb_decoder_templates_inglese() -> Array:
	return [
		{"case":"beacon", "tier":1, "topic":"to-be",
			"segments":["Right now the beacon", "silent."], "time":"present", "mood":"afferma",
			"times":[["present","PRESENTE"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA · dice che e' cosi'"],["nega","NEGA · dice che non e' cosi'"],["chiede","CHIEDE · fa una domanda"]],
			"forms":["is","was","is not"], "clues":["right now","un fatto di adesso"],
			"hints":{"time":"«Right now» tiene la frase nel presente.","mood":"Il faro E' silenzioso: la frase afferma, non nega.","form":"Serve la forma del verbo essere che va con una cosa sola."},
			"discovery":"Nel silenzio si sente un secondo segnale, piu' debole, sotto il primo.",
			"explanation":"«Right now» chiede il presente e la frase afferma: resta «is», la forma del verbo essere per una cosa sola. «Was» sposterebbe tutto nel passato, «is not» direbbe il contrario di quello che il segnale mostra."},
		{"case":"empty", "tier":1, "topic":"to-be",
			"segments":["The tower", "empty: someone is inside."], "time":"present", "mood":"nega",
			"times":[["present","PRESENTE"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA · dice che e' cosi'"],["nega","NEGA · dice che non e' cosi'"],["chiede","CHIEDE · fa una domanda"]],
			"forms":["is not","is","was not"], "clues":["someone is inside","la seconda meta' smentisce la prima"],
			"hints":{"time":"La frase parla di adesso: «someone IS inside».","mood":"La seconda meta' dice che c'e' qualcuno, quindi la prima deve negare.","form":"Il verbo essere si nega da solo, mettendogli «not» subito dopo."},
			"discovery":"Dietro il vetro appannato si muove un'ombra che non risponde alla radio.",
			"explanation":"Il verbo essere e' l'unico che si nega senza chiedere aiuto a nessuno: basta «not» subito dopo. Tutti gli altri verbi, per negare, devono chiamare «do»."},
		{"case":"checks", "tier":2, "topic":"third-person",
			"segments":["Every morning she", "the radio."], "time":"present", "mood":"afferma",
			"times":[["present","PRESENTE ABITUALE"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["checks","checked","does not check"], "clues":["every morning","abitudine che si ripete"],
			"hints":{"time":"«Every morning» e' un'abitudine, e le abitudini stanno al presente semplice.","mood":"La frase racconta quello che fa, non quello che non fa.","form":"Con she il presente semplice prende una lettera in piu'."},
			"discovery":"Il registro della torre mostra la stessa ora annotata per settantatre giorni.",
			"explanation":"Con he, she e it il presente prende la -s: e' l'unico punto in cui il verbo inglese cambia, e per questo si dimentica. «Checked» sposterebbe l'abitudine nel passato, «does not check» la rovescerebbe."},
		{"case":"live", "tier":2, "topic":"do-does",
			"segments":["", "she live near the tower?"], "time":"present", "mood":"chiede",
			"times":[["present","PRESENTE"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["Does","Do","Did"], "clues":["il punto interrogativo","soggetto alla terza persona"],
			"hints":{"time":"Non c'e' nessuna parola che sposti la frase nel passato.","mood":"C'e' un punto interrogativo: la frase chiede.","form":"L'aiutante si accorda con «she», e il verbo dopo di lui resta nudo."},
			"discovery":"L'indirizzo sulla busta corrisponde alla casa piu' vicina al faro.",
			"explanation":"Nella domanda la -s della terza persona passa all'aiutante: «Does she live», mai «Does she lives». Due -s nella stessa frase non si mettono: la prende chi arriva prima."},
		{"case":"raining", "tier":3, "topic":"present-continuous",
			"segments":["Look outside: it", "on the deck."], "time":"present", "mood":"afferma",
			"times":[["present","PRESENTE · sta accadendo"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["is raining","rains","was raining"], "clues":["look outside","proprio in questo momento"],
			"hints":{"time":"«Look outside» chiama a guardare adesso, mentre succede.","mood":"La frase constata quello che si vede.","form":"Per un'azione in corso servono due pezzi: il verbo essere e la forma in -ing."},
			"discovery":"Sul ponte bagnato restano impronte che nessuno del gruppo ha lasciato.",
			"explanation":"«Rains» direbbe che piove di solito, non che sta piovendo adesso: e' la differenza fra l'abitudine e il momento. L'azione in corso vuole sempre due pezzi, e nessuno dei due regge da solo."},
		{"case":"working", "tier":3, "topic":"present-continuous",
			"segments":["The radio", "at the moment."], "time":"present", "mood":"nega",
			"times":[["present","PRESENTE · sta accadendo"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["is not working","is working","did not work"], "clues":["at the moment","nessun segnale in arrivo"],
			"hints":{"time":"«At the moment» inchioda la frase a questo istante.","mood":"La radio tace: la frase deve dire che non funziona.","form":"Il «not» si infila fra il verbo essere e la forma in -ing."},
			"discovery":"Aprendo il pannello si scopre un filo tagliato di netto, non consumato.",
			"explanation":"Nella forma in corso il «not» va in mezzo, fra i due pezzi del verbo: e' lo stesso posto che prende con il verbo essere da solo. «Did not work» avrebbe spostato il guasto nel passato, e la radio invece tace adesso."},
		{"case":"north", "tier":4, "topic":"irregular-past",
			"segments":["Yesterday the crew", "to the north shore."], "time":"past", "mood":"afferma",
			"times":[["present","PRESENTE"],["past","PASSATO · momento chiuso"],["future","FUTURO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["went","goes","did not go"], "clues":["yesterday","un momento finito"],
			"hints":{"time":"«Yesterday» e' un momento chiuso: il filo con adesso e' tagliato.","mood":"La frase racconta che ci sono andati.","form":"«Go» non prende la -ed: cambia parola."},
			"discovery":"Sulla spiaggia a nord la sabbia conserva il segno di una chiglia.",
			"explanation":"«Goed» non esiste: «go» e' irregolare e al passato diventa «went». Sono proprio i verbi piu' usati a restare irregolari, perche' nessuna lingua regolarizza quello che si dice ogni giorno."},
		{"case":"light", "tier":4, "topic":"past-tense",
			"segments":["", "you see the light last night?"], "time":"past", "mood":"chiede",
			"times":[["present","PRESENTE"],["past","PASSATO · momento chiuso"],["present_perfect","TEMPO ANCORA APERTO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["Did","Do","Have"], "clues":["last night","il punto interrogativo"],
			"hints":{"time":"«Last night» e' finito: e' un momento chiuso.","mood":"La frase chiede, quindi l'aiutante va davanti.","form":"L'aiutante del passato e' uno solo, e dopo di lui il verbo resta alla forma base."},
			"discovery":"Tre persone rispondono di si', e nessuna delle tre era di guardia.",
			"explanation":"Con un tempo dichiarato e chiuso — last night — l'aiutante e' «did», e il verbo dopo di lui resta base: «Did you see». «Have you seen» servirebbe se il momento fosse ancora aperto, e «last night» lo chiude."},
		{"case":"signal", "tier":5, "topic":"present-perfect",
			"segments":["The signal", "three times since midnight."], "time":"present_perfect", "mood":"afferma",
			"times":[["present","PRESENTE"],["past","PASSATO · momento chiuso"],["present_perfect","TEMPO ANCORA APERTO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["has come","came","will come"], "clues":["since midnight","la notte non e' finita"],
			"hints":{"time":"«Since midnight» apre un tratto che arriva fino ad adesso.","mood":"La frase conta i segnali arrivati, non quelli mancati.","form":"Il tempo aperto si fa con have o has piu' la terza forma del verbo."},
			"discovery":"I tre segnali hanno la stessa firma, e non e' quella della nave.",
			"explanation":"«Since» dichiara da quando, e il tratto non si e' ancora chiuso: ci vuole il present perfect. «Came» avrebbe chiuso la notte, e la notte e' ancora in corso — e' la parola-spia, non il verbo, a decidere."},
		{"case":"reached", "tier":5, "topic":"present-perfect",
			"segments":["The crew", "the tower yet."], "time":"present_perfect", "mood":"nega",
			"times":[["present","PRESENTE"],["past","PASSATO · momento chiuso"],["present_perfect","TEMPO ANCORA APERTO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["has not reached","has reached","did not reach"], "clues":["yet","l'attesa dura ancora"],
			"hints":{"time":"«Yet» dice che si aspetta ancora: il tratto e' aperto.","mood":"La torre non e' stata raggiunta.","form":"Il «not» si mette fra l'ausiliare e il participio."},
			"discovery":"L'ultimo punto tracciato sulla mappa e' a meno di un chilometro dalla torre.",
			"explanation":"«Yet» vive solo nelle frasi che negano o che chiedono, e tiene aperto il conto: ci vuole il present perfect. «Did not reach» chiuderebbe la faccenda, e invece la squadra sta ancora camminando."},
		{"case":"heavy", "tier":6, "topic":"future",
			"segments":["That crate is heavy: I", "you."], "time":"will", "mood":"afferma",
			"times":[["will","FUTURO · decido adesso"],["going_to","FUTURO · deciso prima"],["past","PASSATO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["will help","am going to help","helped"], "clues":["that crate is heavy","l'offerta nasce adesso"],
			"hints":{"time":"L'offerta nasce mentre si parla: nessuno l'aveva decisa prima.","mood":"E' un'offerta, non un rifiuto.","form":"Il futuro della decisione immediata si fa con un modale, e i modali non vogliono «to»."},
			"discovery":"Sotto la cassa c'e' un secondo fondo, e dentro una radio ancora accesa.",
			"explanation":"«Will» e' il futuro di chi decide in questo istante: offerte, promesse, aiuti che nascono vedendo. «Going to» avrebbe voluto una decisione gia' presa, e qui la cassa si e' vista adesso."},
		{"case":"storm", "tier":6, "topic":"modals",
			"segments":["The storm is close: we", "the shore now."], "time":"present", "mood":"obbligo",
			"times":[["present","ADESSO"],["past","PASSATO"],["future","PIU' TARDI"]],
			"moods":[["obbligo","MUST · non c'e' scelta"],["permesso","MAY · si puo', se si vuole"],["consiglio","SHOULD · sarebbe meglio"]],
			"forms":["must leave","may leave","should leave"], "clues":["the storm is close","non c'e' alternativa"],
			"hints":{"time":"«Now» chiude ogni rinvio: si parla di adesso.","mood":"Con la tempesta addosso non e' un consiglio ne' un permesso.","form":"Dopo un modale il verbo va nudo, senza «to»."},
			"discovery":"Il barometro e' sceso di dodici punti in un'ora.",
			"explanation":"I tre modali dicono la stessa azione con tre forze diverse: obbligo, permesso, consiglio. Il contesto sceglie la forza, e in tutti e tre i casi il verbo che segue resta all'infinito senza «to»."},
		{"case":"rains", "tier":7, "topic":"conditionals",
			"segments":["If it rains tomorrow, we", "at the base."], "time":"first", "mood":"afferma",
			"times":[["first","PRIMO TIPO · puo' succedere"],["second","SECONDO TIPO · non succedera'"],["third","TERZO TIPO · non e' successo"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["will stay","would stay","would have stayed"], "clues":["tomorrow","una pioggia possibile"],
			"hints":{"time":"Domani puo' piovere davvero: la condizione e' possibile.","mood":"La frase dice che cosa si fara', non quello che non si fara'.","form":"Nel primo tipo la conseguenza prende il futuro, e dopo «if» il futuro non si scrive mai."},
			"discovery":"Il piano B era gia' scritto sul retro della mappa, con un'altra calligrafia.",
			"explanation":"Il primo tipo parla di una cosa che puo' succedere davvero: condizione al presente, conseguenza al futuro. «Would stay» la renderebbe irreale, «would have stayed» la sposterebbe in un passato che non si puo' piu' cambiare."},
		{"case":"lighthouse", "tier":7, "topic":"passive",
			"segments":["The lighthouse", "in 1890."], "time":"past", "mood":"passiva",
			"times":[["present","PRESENTE"],["past","PASSATO"],["future","FUTURO"]],
			"moods":[["attiva","VOCE ATTIVA · si dice chi agisce"],["passiva","VOCE PASSIVA · conta chi subisce"],["chiede","CHIEDE"]],
			"forms":["was built","built","is built"], "clues":["in 1890","non si sa chi lo costrui'"],
			"hints":{"time":"Il 1890 e' un momento chiuso e dichiarato.","mood":"Il faro non ha costruito niente: l'ha subito.","form":"Il passivo e' sempre verbo essere piu' participio, in quest'ordine."},
			"discovery":"La data incisa sulla pietra e' stata corretta: sotto se ne legge un'altra.",
			"explanation":"«The lighthouse built» direbbe che e' stato il faro a costruire. Il passivo serve proprio quando chi ha agito non si sa o non importa, e si riconosce dai due pezzi: essere piu' participio, sempre insieme."},
		{"case":"boat", "tier":8, "topic":"past-perfect",
			"segments":["When we arrived, the boat", "already."], "time":"past_perfect", "mood":"afferma",
			"times":[["past","PASSATO SEMPLICE"],["past_perfect","PRIMA DI UN ALTRO PASSATO"],["present_perfect","TEMPO ANCORA APERTO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["had left","left","has left"], "clues":["when we arrived","already"],
			"hints":{"time":"Ci sono due fatti passati, e uno e' successo prima dell'altro.","mood":"La barca e' partita davvero.","form":"Il fatto piu' antico arretra di un gradino e prende «had»."},
			"discovery":"Sul molo restano due cime tagliate, non slegate.",
			"explanation":"Il trapassato non e' un passato piu' lontano: e' il fatto che sta PRIMA di un altro passato di cui si sta parlando. Con «left» i due fatti finirebbero sullo stesso piano, e la barca sembrerebbe partita dopo il nostro arrivo."},
		{"case":"tired", "tier":8, "topic":"reported-speech",
			"segments":["He said he", "tired."], "time":"indiretto", "mood":"afferma",
			"times":[["diretto","PAROLE ESATTE · fra virgolette"],["indiretto","RIFERITO · un passo indietro"],["futuro","FUTURO"]],
			"moods":[["afferma","AFFERMA"],["nega","NEGA"],["chiede","CHIEDE"]],
			"forms":["was","is","will be"], "clues":["he said","non ci sono virgolette"],
			"hints":{"time":"Non ci sono virgolette: le parole vengono riferite, non ripetute.","mood":"Ha detto di essere stanco, non il contrario.","form":"Quando il verbo che introduce e' al passato, quello riferito arretra di un tempo."},
			"discovery":"Nella registrazione originale la voce dice un'altra cosa, e non e' la stanchezza.",
			"explanation":"«He said» sta al passato, e trascina indietro anche il verbo riferito: «is» diventa «was». E' lo stesso arretramento che nel discorso indiretto tocca i pronomi e le parole del tempo — today diventa that day."},
	]

func _numeric_ordering_node(subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var count := clampi(4 + int(level / 9.0) + step, 4, 5)
	var ascending := rng.randf() < 0.5
	var quantitative := level <= 12
	var topic := "tabelline" if quantitative else "frazioni"
	var cards := (
		_multiplication_cards(count, rng) if quantitative else _fraction_cards(count, rng))

	# Ordina per valore, non per etichetta: "10/12" viene dopo "1/2" per valore,
	# ma prima in ordine alfabetico.
	cards.sort_custom(func(a, b): return float(a["value"]) < float(b["value"]))
	if not ascending:
		cards.reverse()

	var correct: Array = []
	var worked: Array = []
	for card in cards:
		correct.append(str(card["label"]))
		worked.append(str(card["worked"]))
	var items := correct.duplicate()
	# Mai presentare gli elementi già ordinati (guard-rail del 29 luglio).
	ExerciseInteraction.shuffle_avoiding(items, rng, correct)

	var direction := (
		"dal risultato più piccolo al più grande"
		if ascending
		else "dal risultato più grande al più piccolo")
	var prompt := ""
	if quantitative:
		prompt = "Ordina le moltiplicazioni %s." % direction
	else:
		prompt = "Ordina le frazioni %s." % (
			"dalla più piccola alla più grande"
			if ascending
			else "dalla più grande alla più piccola")

	return {
		"id": "minigame-numorder-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": topic,
		"difficulty": difficulty_of(level, step),
		"format": "ordering",
		"prompt": prompt,
		"items": items,
		"correctOrder": correct,
		# La spiegazione mostra i valori calcolati: chi sbaglia vede il confronto,
		# non solo la sequenza giusta.
		"explanation": "Si confrontano i valori uno per uno, dal più piccolo al più grande: "
			+ "il numero di cifre non basta, conta quanto vale. Ordine giusto: %s."
			% ", ".join(PackedStringArray(worked)),
	}

## Carte "a × b" con prodotti tutti DIVERSI e almeno due primi fattori distinti.
## Il secondo vincolo non è estetico: se tutte le carte condividessero il primo
## fattore (7×3, 7×5, 7×8) si potrebbe ordinare guardando solo l'altro fattore,
## senza calcolare nulla — la stessa famiglia di scorciatoie ripulita il 29 luglio.
func _multiplication_cards(count: int, rng: RandomNumberGenerator) -> Array:
	var cards: Array = []
	var seen_products: Dictionary = {}
	var first_factors: Dictionary = {}
	var guard := 0
	while cards.size() < count and guard < 400:
		guard += 1
		var a := rng.randi_range(2, 10)
		var b := rng.randi_range(2, 10)
		var product := a * b
		if seen_products.has(product):
			continue
		# All'ultima carta pretendi che i primi fattori non siano tutti uguali.
		if cards.size() == count - 1 and first_factors.size() == 1 and first_factors.has(a):
			continue
		seen_products[product] = true
		first_factors[a] = true
		cards.append({
			"label": "%d × %d" % [a, b],
			"value": float(product),
			"worked": "%d × %d = %d" % [a, b, product],
		})
	return cards

## Frazioni proprie con denominatori tutti diversi e valori tutti distinti
## (mai una coppia equivalente come 2/4 e 1/2, che renderebbe l'ordine ambiguo).
## Confrontarle richiede denominatore comune: è l'argomento che i mondi alti di
## matematica dichiarano davvero.
func _fraction_cards(count: int, rng: RandomNumberGenerator) -> Array:
	var cards: Array = []
	var used_denominators: Dictionary = {}
	var seen_values: Dictionary = {}
	var guard := 0
	while cards.size() < count and guard < 600:
		guard += 1
		var d := int(FRACTION_DENOMINATORS[rng.randi_range(0, FRACTION_DENOMINATORS.size() - 1)])
		if used_denominators.has(d):
			continue
		var n := rng.randi_range(1, d - 1)
		var value := float(n) / float(d)
		var key := "%.4f" % value
		if seen_values.has(key):
			continue
		used_denominators[d] = true
		seen_values[key] = true
		cards.append({
			"label": "%d/%d" % [n, d],
			"value": value,
			"worked": "%d/%d" % [n, d],
		})
	return cards

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = values[i]
		values[i] = values[j]
		values[j] = tmp


# ---------------------------------------------------------------------------
# LA GRIGLIA DEGLI INCROCI (1 settembre 2026)
# ---------------------------------------------------------------------------
#
# È il minigioco di logica per definizione, e mancava. Quattro nomi, quattro
# oggetti, una manciata di indizi: si segnano le caselle — «no» dove l'indizio
# lo esclude, «sì» dove non resta altro — finché sopravvive una sola
# assegnazione. Il gesto È la deduzione: la griglia mostra il ragionamento
# mentre lo si fa, e non serve nessuna risposta da confrontare perché la
# coerenza si vede da sé.
#
# **Perché serviva.** La logica aveva l'indiziario e il tracciatore con UNA
# specifica ciascuno: chi ha vinto la gara era sempre Dino. Un indovinello che
# si ricorda a memoria non è un indovinello. Questa invece si GENERA: quattro
# scenari per le permutazioni dei loro elementi, con gli indizi sorteggiati ogni
# volta, e due partite non incontrano la stessa griglia.
#
# **Come nascono gli indizi.** Si parte dalla soluzione, si riempie un sacco di
# indizi veri (negazioni e alternative), se ne aggiungono a caso finché le
# permutazioni compatibili scendono a una sola, poi si TOLGONO quelli che non
# servono più. La potatura è la parte importante: senza, la griglia arriva con
# dieci indizi di cui sei ridondanti, e leggerli tutti è fatica, non pensiero.
const GRIGLIA_SCENARI := [
	{
		"titolo": "Chi indossa quale cappello?",
		"verbo": "indossa",
		"soggetti": ["Ada", "Bruno", "Carla", "Dino"],
		"attributi": ["il cappello rosso", "il cappello verde", "il cappello blu", "il cappello giallo"],
	},
	{
		"titolo": "Chi suona quale strumento?",
		"verbo": "suona",
		"soggetti": ["Nina", "Ivo", "Sara", "Tobia"],
		"attributi": ["il flauto", "la chitarra", "il violino", "il tamburo"],
	},
	{
		"titolo": "Chi ha portato quale frutto?",
		"verbo": "ha portato",
		"soggetti": ["Lea", "Marco", "Ugo", "Vera"],
		"attributi": ["la mela", "la pera", "la banana", "l'arancia"],
	},
	{
		"titolo": "Chi sta esplorando quale settore?",
		"verbo": "sta esplorando",
		"soggetti": ["Eli", "BIT", "NORA", "il Custode"],
		"attributi": ["il settore nord", "il settore sud", "il settore est", "il settore ovest"],
	},
]

## **Tre modi di spiegare la stessa griglia, non uno.**
##
## `explanation_coverage_audit` rifiuta una frase che copra più di un quarto dei
## nodi di un formato, e ha ragione per una ragione che non è statistica: una
## spiegazione che torna identica ogni volta smette di essere letta alla seconda.
## Le tre qui sotto dicono tre parti diverse del metodo — che cosa si toglie, che
## cosa vale un «sì», da quale indizio conviene partire — così chi rigioca trova
## un appiglio nuovo invece di riconoscere una formula.
const GRIGLIA_SPIEGAZIONI := [
	"In una griglia non si cerca la risposta: si tolgono le impossibili. Ogni «no» restringe la sua riga e la sua colonna, e quando in una riga resta una casella sola quella è un «sì» — anche se nessun indizio l'ha mai detto. È lo stesso ragionamento del «non si può dire»: si chiudono le porte finché ne resta aperta una.",
	"Un «sì» vale doppio: chiude la sua riga e anche la sua colonna, perché ogni cosa appartiene a uno solo e ogni cosa è di qualcuno. È questo vincolo a rendere la griglia risolvibile — senza, gli stessi indizi non basterebbero, e infatti da soli non dicono mai tutto.",
	"Gli indizi non vanno letti nell'ordine in cui stanno scritti: conviene partire da quello che toglie di più, di solito l'alternativa fra due nomi. Poi si torna sugli altri con la griglia già più stretta, e un indizio che prima sembrava inutile all'improvviso decide.",
	"Una griglia non si risolve indovinando e poi controllando: si risolve al contrario. Ogni casella che spegni è una possibilità in meno, e quando le possibilità di una riga scendono a una sola quella è la risposta — trovata senza averla mai cercata.",
	"Un indizio che dice «è questo oppure quello» sembra dire poco e invece dice moltissimo: esclude tutti gli altri in un colpo solo. Qui le informazioni negative valgono più di quelle positive, perché tolgono a molte righe insieme.",
	# Sesta, aggiunta il 9 settembre 2026. Non è un riempitivo: con cinque frasi e
	# una distribuzione legata alla griglia, una di loro arrivava al 26% dei nodi
	# e `explanation_coverage_audit` la bocciava a ragione, perché una spiegazione
	# che torna troppo spesso smette di essere letta. Ma è anche il pezzo di
	# metodo che mancava davvero: le altre cinque dicono come si stringe, questa
	# dice come si sa di aver finito.
	"Quando la griglia è piena non hai ancora finito: torna sugli indizi e verifica che li spieghi TUTTI, compresi quelli che non hai usato. Una soluzione che ne contraddice uno solo è sbagliata, e accorgersene alla fine costa molto meno che accorgersene mai.",
]

## Quanti indizi al massimo restano a schermo. Sei: oltre, la colonna non ci sta
## su un tablet e la lettura diventa il problema al posto della deduzione.
const GRIGLIA_MAX_INDIZI := 6

## Lato della griglia per difficoltà. Tre righe sono sei permutazioni e si
## chiudono con due indizi; quattro sono ventiquattro e ne vogliono tre o quattro.
static func griglia_lato(difficulty: int) -> int:
	return 3 if difficulty <= 2 else 4

## Quante griglie distinte il formato può produrre a questo livello. Scenari per
## permutazioni: gli indizi cambiano ancora dentro ognuna, quindi è una stima
## per difetto — che è il verso giusto per un pavimento.
static func griglia_depth(subject: String, level: int) -> int:
	if subject != "logica":
		return 0
	var lato := griglia_lato(ContentManager.target_difficulty(level))
	var permutazioni := 1
	for i in range(2, lato + 1):
		permutazioni *= i
	return GRIGLIA_SCENARI.size() * permutazioni

func _griglia_node(subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var difficulty := difficulty_of(level, step)
	var lato := griglia_lato(difficulty)
	var scenario_indice := rng.randi_range(0, GRIGLIA_SCENARI.size() - 1)
	var scenario: Dictionary = GRIGLIA_SCENARI[scenario_indice]
	var soggetti: Array = Array(scenario["soggetti"]).slice(0, lato)
	var attributi: Array = Array(scenario["attributi"]).duplicate()
	_shuffle(attributi, rng)
	attributi = attributi.slice(0, lato)
	var verbo := str(scenario["verbo"])

	# La soluzione: una permutazione, cioè un attributo per soggetto e nessuno
	# ripetuto. È il vincolo che rende la griglia risolvibile per esclusione.
	var perm: Array = []
	for i in lato:
		perm.append(i)
	_shuffle(perm, rng)

	var candidati := _griglia_indizi_possibili(soggetti, attributi, perm, verbo, rng)
	var scelti: Array = []
	for candidato in candidati:
		if _griglia_soluzioni(perm.size(), scelti) <= 1:
			break
		scelti.append(candidato)
	# Potatura: un indizio che non toglie più niente è rumore da leggere.
	var potati: Array = scelti.duplicate()
	for candidato in scelti:
		var prova: Array = potati.duplicate()
		prova.erase(candidato)
		if _griglia_soluzioni(perm.size(), prova) == 1:
			potati = prova
	if potati.size() > GRIGLIA_MAX_INDIZI:
		potati = potati.slice(0, GRIGLIA_MAX_INDIZI)

	var indizi: Array = []
	for candidato in potati:
		indizi.append({"text": str((candidato as Dictionary)["text"])})
	var soluzione: Dictionary = {}
	for i in soggetti.size():
		soluzione[str(soggetti[i])] = str(attributi[int(perm[i])])

	return {
		"id": "minigame-griglia-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": "deduzioni",
		"difficulty": difficulty,
		"format": "griglia",
		"prompt": "%s Segna «no» dove un indizio lo esclude e «sì» quando non resta altro." % str(scenario["titolo"]),
		"soggetti": soggetti,
		"attributi": attributi,
		"indizi": indizi,
		"soluzione": soluzione,
		"explanation": GRIGLIA_SPIEGAZIONI[_griglia_spiegazione(scenario_indice, perm)],
	}

## Quale delle sei spiegazioni accompagna questa griglia. Non a sorte: legata
## alla griglia stessa, così le sei si distribuiscono in modo regolare invece
## di raggrupparsi — `explanation_coverage_audit` misura la QUOTA di ciascuna, e
## un sorteggio su un campione piccolo la fa ballare di dieci punti.
## **I moltiplicatori devono essere coprimi con il numero di frasi.** (9 settembre
## 2026) Erano 3 e 2 su cinque frasi, e funzionavano per caso: 3 e 5 sono
## coprimi. Passando a sei frasi il 3 è diventato un divisore — `scenario * 3`
## modulo 6 vale soltanto 0 o 3 — e la distribuzione è peggiorata invece di
## migliorare, lasciando una frase al 26% come prima. Con 7, 5 e 3 la mescola
## resta regolare per qualunque numero di frasi che non sia multiplo di quei tre.
func _griglia_spiegazione(scenario_indice: int, perm: Array) -> int:
	var mescola := scenario_indice * 7 + int(perm[0]) * 5 + int(perm[perm.size() - 1]) * 3
	return posmod(mescola, GRIGLIA_SPIEGAZIONI.size())

## Tutti gli indizi VERI che si possono dire su questa soluzione, mescolati.
## Due tipi soltanto, ed è voluto: la negazione toglie una casella, l'alternativa
## ne accende due lasciando il dubbio. Un indizio che dichiara direttamente una
## coppia risolverebbe una riga senza farla ragionare, e non entra mai.
func _griglia_indizi_possibili(
		soggetti: Array, attributi: Array, perm: Array, verbo: String,
		rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for i in soggetti.size():
		for j in attributi.size():
			if int(perm[i]) == j:
				continue
			out.append({
				"tipo": "no",
				"soggetto": i,
				"attributo": j,
				"text": "%s non %s %s." % [str(soggetti[i]), verbo, str(attributi[j])],
			})
	for j in attributi.size():
		var proprietario := -1
		for i in soggetti.size():
			if int(perm[i]) == j:
				proprietario = i
		var altri: Array = []
		for i in soggetti.size():
			if i != proprietario:
				altri.append(i)
		if altri.is_empty():
			continue
		var compagno := int(altri[rng.randi_range(0, altri.size() - 1)])
		var primo := mini(proprietario, compagno)
		var secondo := maxi(proprietario, compagno)
		out.append({
			"tipo": "oppure",
			"attributo": j,
			"soggetti": [primo, secondo],
			"text": "Chi %s %s è %s oppure %s." % [
				verbo, str(attributi[j]), str(soggetti[primo]), str(soggetti[secondo])],
		})
	_shuffle(out, rng)
	return out

## Quante permutazioni sopravvivono a questi indizi. Con quattro righe sono
## ventiquattro casi da provare: si conta per forza bruta, ed è l'unico modo di
## garantire che la griglia abbia una soluzione sola davvero.
func _griglia_soluzioni(lato: int, indizi: Array) -> int:
	var valide := 0
	for candidata in _permutazioni(lato):
		var ok := true
		for indizio_data in indizi:
			var indizio: Dictionary = indizio_data
			if str(indizio["tipo"]) == "no":
				if int(candidata[int(indizio["soggetto"])]) == int(indizio["attributo"]):
					ok = false
					break
			else:
				var trovato := false
				for i in Array(indizio["soggetti"]):
					if int(candidata[int(i)]) == int(indizio["attributo"]):
						trovato = true
				if not trovato:
					ok = false
					break
		if ok:
			valide += 1
	return valide

func _permutazioni(n: int) -> Array:
	if n <= 0:
		return [[]]
	if n == 1:
		return [[0]]
	var out: Array = []
	for coda in _permutazioni(n - 1):
		for posto in range(n):
			var nuova: Array = Array(coda).duplicate()
			nuova.insert(posto, n - 1)
			out.append(nuova)
	return out


# ---------------------------------------------------------------------------
# LE PORTE (1 settembre 2026)
# ---------------------------------------------------------------------------
#
# «Piove E fa freddo» smette di essere una frase e diventa una lampadina.
#
# Il banco chiedeva già, a scelta multipla, quando è vera una congiunzione e
# quante combinazioni esistono con due affermazioni. Sono le domande giuste nel
# formato sbagliato: la tavola di verità non si impara leggendola, si impara
# accendendo e spegnendo. Qui i quattro casi sono quattro righe da decidere una
# per una, e la lampada si accende mentre si decide.
#
# Nessun cronometro, come per ogni cosa che chiede di ragionare.
const PORTE_INGRESSI := [
	["Piove", "Fa freddo"],
	["La porta è aperta", "La luce è accesa"],
	["Il numero è pari", "Il numero è maggiore di dieci"],
	["Eli ha la chiave", "Il ponte è abbassato"],
	["Il campanello suona", "Il cane abbaia"],
]

## Le cinque porte, in ordine di quanto costano. Le prime due si capiscono a
## parole; «solo uno dei due» è quella che il linguaggio comune sbaglia sempre,
## perché nel parlato «o» spesso vuol dire proprio quella.
const PORTE_REGOLE := [
	{"id": "e", "tier": 1, "modello": "%s E %s"},
	{"id": "o", "tier": 1, "modello": "%s OPPURE %s (anche tutti e due)"},
	{"id": "solo_uno", "tier": 3, "modello": "%s oppure %s, ma non tutti e due"},
	{"id": "nessuno", "tier": 3, "modello": "né %s né %s"},
	{"id": "ma_non", "tier": 4, "modello": "%s, ma NON %s"},
]

## Quali porte può incontrare questa difficoltà. Il minimo è due, altrimenti a
## difficoltà 1 la sessione riproporrebbe sempre la stessa.
static func porte_regole_per(difficulty: int) -> Array:
	var out: Array = []
	for regola in PORTE_REGOLE:
		if int((regola as Dictionary).get("tier", 1)) <= maxi(difficulty, 2):
			out.append(regola)
	return out

static func porte_depth(subject: String, level: int) -> int:
	if subject != "logica":
		return 0
	return porte_regole_per(ContentManager.target_difficulty(level)).size() * PORTE_INGRESSI.size()

static func _porta_accende(regola: String, a: bool, b: bool) -> bool:
	match regola:
		"e": return a and b
		"o": return a or b
		"solo_uno": return a != b
		"nessuno": return (not a) and (not b)
		"ma_non": return a and not b
	return false

func _porte_node(subject: String, level: int, step: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var difficulty := difficulty_of(level, step)
	var ammesse := porte_regole_per(difficulty)
	var regola: Dictionary = ammesse[rng.randi_range(0, ammesse.size() - 1)]
	var ingressi_indice := rng.randi_range(0, PORTE_INGRESSI.size() - 1)
	var ingressi: Array = Array(PORTE_INGRESSI[ingressi_indice]).duplicate()
	var id_regola := str(regola["id"])
	var condizione := str(regola["modello"]) % [str(ingressi[0]).to_lower(), str(ingressi[1]).to_lower()]
	condizione = condizione.substr(0, 1).to_upper() + condizione.substr(1)

	var combinazioni := [[false, false], [false, true], [true, false], [true, true]]
	_shuffle(combinazioni, rng)
	var righe: Array = []
	var soluzione: Dictionary = {}
	for i in combinazioni.size():
		var a := bool(combinazioni[i][0])
		var b := bool(combinazioni[i][1])
		var chiave := "r%d" % i
		righe.append({
			"id": chiave,
			"a": a,
			"b": b,
			"label": "%s: %s   ·   %s: %s" % [
				str(ingressi[0]), "sì" if a else "no",
				str(ingressi[1]), "sì" if b else "no"],
		})
		soluzione[chiave] = _porta_accende(id_regola, a, b)

	return {
		"id": "minigame-porte-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": "verita",
		"difficulty": difficulty,
		"format": "porte",
		"prompt": "La lampada deve accendersi quando: %s. Decidi caso per caso." % condizione,
		"condizione": condizione,
		"ingressi": ingressi,
		"righe": righe,
		"soluzione": soluzione,
		"explanation": _porte_spiegazione(id_regola, ingressi_indice),
	}

## **Tre spiegazioni per porta, non una.**
##
## Con due sole porte ammesse ai primi livelli, una frase per porta copriva metà
## dei nodi del formato — e `explanation_coverage_audit` la rifiuta, a ragione:
## una frase che torna identica smette di essere letta. Le tre di ogni porta
## dicono cose diverse — quando accende, che cosa se ne conclude, dove sbaglia
## di solito chi la incontra — e si scelgono dalla coppia di ingressi, non a
## sorte, così restano distribuite anche su un campione piccolo.
const PORTE_SPIEGAZIONI := {
	"e": [
		"Una «E» è severa: chiede tutte e due le cose insieme, e basta che una manchi perché la lampada resti spenta. Dei quattro casi ne accende uno solo — ed è per questo che aggiungere una condizione con «E» non allarga mai, restringe sempre.",
		"Con la «E» il caso buono è uno su quattro, e i tre spenti non sono tutti uguali: in due manca una cosa sola, nell'ultimo mancano tutte e due. Sapere QUALE manca è quasi sempre più utile che sapere soltanto che la lampada è spenta.",
		"Se una «E» accende, allora sono vere anche le due condizioni prese da sole: da «piove e fa freddo» si può sempre concludere «piove». Al contrario non funziona, ed è l'errore che si fa più spesso.",
	],
	"o": [
		"In logica «oppure» non esclude niente: accende quando c'è la prima, quando c'è la seconda e anche quando ci sono tutte e due. Dei quattro casi ne spegne uno solo, quello in cui non c'è nessuna delle due. Nel parlare di tutti i giorni «o» suona spesso come «uno solo dei due», e proprio lì nasce l'errore.",
		"L'«oppure» della logica è generoso: gli basta una delle due. Per spegnerlo bisogna smentirle tutte e due insieme, ed è il motivo per cui negare un «o» costa molta più fatica che negare una «e».",
		"Tre casi accesi su quattro: con due ingressi non esiste condizione più facile da soddisfare. Quando in un problema compare un «oppure», la parte che richiede attenzione è quasi sempre l'unico caso che lo spegne.",
	],
	"solo_uno": [
		"Questa è la «o» del linguaggio comune — «o vieni tu o vengo io» — e in logica ha un nome diverso perché si comporta diversamente: si accende quando le due cose sono DIVERSE fra loro e si spegne quando sono uguali, sia se ci sono tutte e due sia se non c'è nessuna.",
		"Non serve guardare quale delle due condizioni c'è: basta chiedersi se sono diverse fra loro. Se lo sono accende, se sono uguali resta spenta. È l'unica delle cinque porte che non guarda il contenuto ma il confronto.",
		"Due casi accesi e due spenti, come l'«oppure» — ma non gli stessi due. Questa spegne anche quando ci sono tutte e due le cose, e proprio in quel caso si vede chi ha capito la differenza fra le due «o» e chi le sta confondendo.",
	],
	"nessuno": [
		"«Né… né…» accende solo nel caso in cui non c'è proprio niente: è la negazione dell'«oppure», e infatti accende esattamente dove quello spegneva. Negare un «o» non dà un altro «o»: dà una «E» di negazioni.",
		"È la «E» delle negazioni: «né questo né quello» vuol dire «non questo E non quello». Riscriverla così è la regola più utile di tutte, perché trasforma una frase che sembra strana in due condizioni semplici messe insieme.",
		"Basta che una qualsiasi delle due condizioni si avveri e la lampada resta spenta: il «né… né…» è la più fragile delle cinque porte, e accende in un caso solo su quattro.",
	],
	"ma_non": [
		"Qui la seconda condizione lavora al contrario: serve che la prima ci sia e che la seconda NON ci sia. È la forma di ogni eccezione — «tutti i giorni tranne la domenica» — e si accende in un caso solo su quattro, come la «E», ma non nello stesso.",
		"Le due condizioni non contano allo stesso modo: la prima deve esserci, la seconda deve mancare. La porta è asimmetrica, e scambiare le due condizioni dà una porta diversa che accende in un caso completamente diverso.",
		"«Tutti i pari tranne quelli divisibili per quattro», «aperto tutti i giorni tranne il lunedì»: ogni eccezione ha questa forma. Riconoscerla vuol dire accorgersi che una delle due condizioni va negata prima di metterla insieme all'altra.",
	],
}

## Quale delle tre varianti accompagna questa porta: legata alla coppia di
## ingressi, non sorteggiata, così le tre restano distribuite.
func _porte_spiegazione(id_regola: String, ingressi_indice: int) -> String:
	var varianti: Array = Array(PORTE_SPIEGAZIONI.get(id_regola, []))
	if varianti.is_empty():
		return "Ogni porta decide in modo diverso quando la lampada si accende: si controllano i quattro casi uno per uno, senza indovinare."
	return str(varianti[posmod(ingressi_indice, varianti.size())])
