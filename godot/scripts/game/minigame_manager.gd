class_name MinigameManager
extends RefCounted

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")

## Costruisce sessioni-MINIGIOCO risolte con le competenze delle materie. Due
## formati interattivi (resi da ExercisePlayer): "matching" (abbina le coppie) e
## "ordering" (metti in ordine). Riusa il contratto di sessione di ContentManager
## (nodi con topic/difficoltà) così mastery per-topic, energia e adattività
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
		{"explanation": "Alcuni comparativi non si formano con -er o con more: good, bad e far cambiano parola del tutto. Sono pochissimi, e proprio per questo si imparano a memoria.", "topic": "comparatives", "minLevel": 20, "kind": "pool", "pool": [
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
		{"explanation": "Gli opposti conviene impararli in coppia: ricordarne uno tira su anche l'altro, e dimezza la fatica.", "topic": "opposites", "minLevel": 3, "pairs": [
			["hot", "cold"], ["big", "small"], ["fast", "slow"], ["happy", "sad"],
			["old", "new"], ["long", "short"], ["high", "low"], ["light", "heavy"],
			["full", "empty"], ["open", "shut"], ["clean", "dirty"], ["easy", "hard"],
			["strong", "weak"], ["rich", "poor"], ["near", "far"], ["young", "elderly"],
			["loud", "quiet"], ["wet", "dry"], ["early", "late"], ["first", "last"],
			["day", "night"], ["summer", "winter"], ["inside", "outside"], ["above", "below"],
			["always", "never"], ["everything", "nothing"]]},
		# Conversazione: micro-scambi domanda -> risposta.
		{"explanation": "Micro-scambi domanda-risposta. La risposta riusa le parole della domanda: è il trucco che permette di rispondere anche quando non si è capito tutto.", "topic": "conversation", "minLevel": 5, "pairs": [
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
		{"explanation": "Le contrazioni uniscono due parole togliendone una parte, e l'apostrofo segna il posto di quello che manca.", "topic": "contractions", "minLevel": 6, "pairs": [
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
		{"explanation": "Plurali che non prendono la -s: sono resti di forme antiche, sopravvissuti perché sono parole usatissime.", "topic": "irregular-plural", "minLevel": 8, "pairs": [
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
	],
	"geografia": [
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
		{"explanation": "Ogni passaggio di stato ha un nome proprio e un verso preciso: fusione e solidificazione sono lo stesso confine percorso nei due sensi.", "topic": "passaggi-stato", "minLevel": 5, "pairs": [["Fusione", "solido → liquido"], ["Evaporazione", "liquido → gas"], ["Solidificazione", "liquido → solido"], ["Condensazione", "gas → liquido"]]},
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
		{"explanation": "Ogni componente ha un ruolo solo: chi fornisce energia, chi lascia passare la corrente o la interrompe, chi la limita.", "topic": "componenti", "pairs": [["Pila", "Fornisce energia"], ["Interruttore", "Apre e chiude"], ["Resistore", "Limita la corrente"], ["LED", "Emette luce"]]},
		{"explanation": "Ogni grandezza ha la sua unità e il suo strumento. Confonderle significa collegare lo strumento nel modo sbagliato.", "topic": "misure-elettriche", "pairs": [["Tensione", "Volt"], ["Corrente", "Ampere"], ["Resistenza", "Ohm"]]},
		{"explanation": "Le unità portano il nome di chi le ha studiate: Watt, Joule e Hertz erano persone.", "topic": "grandezze", "minLevel": 3, "pairs": [["Potenza", "Watt"], ["Energia", "Joule"], ["Frequenza", "Hertz"]]},
		# Scuola media — legge di Ohm e prefissi delle unità.
		{"explanation": "Dalla legge di Ohm si ricavano tutte e tre le formule: conoscendo due grandezze si trova sempre la terza.", "topic": "legge-ohm", "minLevel": 6, "pairs": [["Tensione (V)", "R × I"], ["Corrente (I)", "V / R"], ["Resistenza (R)", "V / I"]]},
		{"explanation": "I prefissi valgono mille per volta: k moltiplica per mille, m divide per mille.", "topic": "prefissi", "minLevel": 7, "pairs": [["1000 Ω", "1 kΩ"], ["1000 mA", "1 A"], ["1000 mV", "1 V"]]},
		# --- Mondo 1: ricette in più (tappa 3, 6 agosto 2026) -----------------
		{"explanation": "L'elettricità si capisce meglio pensando all'acqua nei tubi: è un paragone, non la verità, ma regge abbastanza da farci ragionare sui circuiti.", "topic": "elettricita-base", "pairs": [
			["la pila", "la pompa che spinge"], ["la tensione", "la pressione dell'acqua"],
			["la corrente", "quanta acqua passa al secondo"], ["la resistenza", "il tubo stretto"],
			["l'interruttore", "il rubinetto"], ["il filo", "il tubo"],
			["il condensatore", "il serbatoio che si riempie"]]},
		{"explanation": "Un guasto si trova ragionando, non provando a caso: ogni sintomo restringe il campo, e il primo controllo è sempre se il circuito è chiuso.", "topic": "guasti", "pairs": [
			["la lampadina non si accende", "il circuito è interrotto"],
			["i fili scaldano troppo", "passa più corrente del dovuto"],
			["la pila si scarica in pochi minuti", "c'è un cortocircuito"],
			["la luce è debole", "la pila è quasi scarica"],
			["il motore gira al contrario", "i poli sono invertiti"],
			["funziona solo muovendo il filo", "un contatto è allentato"]]},
	],
	"fisica": [
		{"explanation": "Sono tre delle sette unità di base del Sistema Internazionale: tutte le altre si costruiscono a partire da queste.", "topic": "misure", "pairs": [["Lunghezza", "Metro"], ["Massa", "Chilogrammo"], ["Tempo", "Secondo"], ["Temperatura", "Grado"]]},
		{"explanation": "L'energia cambia forma e non sparisce: ferma in alto è potenziale, mentre cade diventa cinetica.", "topic": "energia", "pairs": [["Palla in alto", "Energia potenziale"], ["Palla che cade", "Energia cinetica"], ["Cibo", "Energia chimica"], ["Lampadina accesa", "Energia luminosa"]]},
		{"explanation": "Ogni strumento misura una grandezza sola: sbagliare strumento significa misurare un'altra cosa.", "topic": "strumenti", "minLevel": 3, "pairs": [["Righello", "lunghezza"], ["Bilancia", "massa"], ["Cronometro", "tempo"], ["Termometro", "temperatura"]]},
		{"explanation": "Una forza si riconosce da cosa fa al moto: lo avvia, lo rallenta o lo devia.", "topic": "forze", "minLevel": 4, "pairs": [["Attrito", "Rallenta il moto"], ["Gravità", "Attira verso il basso"], ["Spinta", "Mette in moto"], ["Magnetismo", "Attira il ferro"]]},
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
	],
	"logica": [
		# Una relazione sola per insieme, come deciso nella Fase 3: mescolarne due
		# renderebbe l'abbinamento indovinabile per associazione invece che per
		# ragionamento. Qui la relazione è «il piccolo → l'adulto».
		{"explanation": "L'analogia si risolve trovando la relazione: qui è «il piccolo di». Trovata quella, la coppia si completa da sé.", "topic": "analogie", "kind": "pool", "pool": [
			["cucciolo", "cane"], ["puledro", "cavallo"], ["gattino", "gatto"],
			["agnello", "pecora"], ["pulcino", "gallina"], ["vitello", "mucca"],
			["cerbiatto", "cervo"], ["anatroccolo", "anatra"], ["leprotto", "lepre"],
			["capretto", "capra"], ["porcellino", "maiale"], ["girino", "rana"]]},
		# Ogni insieme è UNA relazione sola, dichiarata nel commento: è questo che lo
		# rende un esercizio di logica invece che di vocabolario. Mescolare relazioni
		# diverse nello stesso insieme renderebbe l'abbinamento indovinabile per
		# associazione, che è il contrario di quello che la materia allena.
		# Relazione: «chi ci abita».
		{"explanation": "La relazione è «dove abita». In un'analogia conta il legame fra le due parole, non la somiglianza fra loro.", "topic": "analogie", "pairs": [
			["Cane", "Cuccia"], ["Uccello", "Nido"], ["Ape", "Alveare"], ["Pesce", "Acquario"],
			["Cavallo", "Stalla"], ["Topo", "Tana"], ["Formica", "Formicaio"], ["Ragno", "Ragnatela"],
			["Coniglio", "Conigliera"], ["Maiale", "Porcile"], ["Aquila", "Nido d'aquila"], ["Castoro", "Diga"],
			["Volpe", "Tana scavata"], ["Gallina", "Pollaio"], ["Pecora", "Ovile"], ["Orso", "Caverna"],
			["Talpa", "Galleria"], ["Lumaca", "Guscio"], ["Termite", "Termitaio"], ["Marmotta", "Cunicolo"]]},
		# Relazione: «a che cosa serve».
		{"explanation": "La relazione è «a che cosa serve»: ogni oggetto va con la sua funzione.", "topic": "analogie", "minLevel": 3, "pairs": [
			["Penna", "Scrivere"], ["Forbici", "Tagliare"], ["Martello", "Battere"], ["Chiave", "Aprire"],
			["Scopa", "Spazzare"], ["Ago", "Cucire"], ["Pettine", "Pettinare"], ["Termometro", "Misurare la febbre"],
			["Bussola", "Orientarsi"], ["Ombrello", "Ripararsi dalla pioggia"], ["Bilancia", "Pesare"], ["Telescopio", "Osservare lontano"],
			["Lente", "Ingrandire"], ["Remo", "Spingere la barca"], ["Sega", "Segare"], ["Freno", "Fermare"],
			["Setaccio", "Separare"], ["Imbuto", "Travasare"], ["Livella", "Verificare l'orizzontale"], ["Pinza", "Afferrare"]]},
		{"explanation": "Ogni elemento va con la categoria che lo contiene: la rosa è un fiore, e «fiore» è più ampio di «rosa».", "topic": "categorie", "minLevel": 4, "pairs": [["Rosa", "Fiore"], ["Cane", "Animale"], ["Mela", "Frutto"], ["Tavolo", "Mobile"]]},
		# Relazione: «parte di».
		{"explanation": "La relazione è «parte di»: la ruota fa parte dell'automobile come la pagina fa parte del libro.", "topic": "analogie", "minLevel": 4, "pairs": [
			["Ruota", "Automobile"], ["Foglia", "Albero"], ["Pagina", "Libro"], ["Dito", "Mano"],
			["Tasto", "Pianoforte"], ["Petalo", "Fiore"], ["Corda", "Chitarra"], ["Gradino", "Scala"],
			["Ala", "Uccello"], ["Radice", "Pianta"], ["Nota", "Melodia"], ["Mattone", "Muro"],
			["Stanza", "Casa"], ["Capitolo", "Romanzo"], ["Isola", "Arcipelago"], ["Vagone", "Treno"],
			["Lettera", "Parola"], ["Cellula", "Tessuto"], ["Fotogramma", "Film"], ["Stella", "Costellazione"]]},
		# Relazione: «il contrario di».
		{"explanation": "Gli opposti stanno sulla stessa scala, ai due estremi: giorno e notte sono i due capi della stessa giornata.", "topic": "opposti", "minLevel": 5, "pairs": [
			["Giorno", "Notte"], ["Salita", "Discesa"], ["Pieno", "Vuoto"], ["Inizio", "Fine"],
			["Vittoria", "Sconfitta"], ["Silenzio", "Rumore"], ["Ordine", "Disordine"], ["Verità", "Menzogna"],
			["Domanda", "Risposta"], ["Entrata", "Uscita"], ["Ricordo", "Oblio"], ["Guerra", "Pace"],
			["Partenza", "Arrivo"], ["Luce", "Buio"], ["Coraggio", "Paura"], ["Successo", "Fallimento"],
			["Presenza", "Assenza"], ["Movimento", "Quiete"], ["Nascita", "Morte"], ["Certezza", "Dubbio"]]},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "Una deduzione è valida quando la conclusione è già dentro le premesse: non aggiunge niente di nuovo, tira fuori quello che c'era. Per questo è sicura.", "topic": "deduzioni", "pairs": [
			["Tutti i gatti sono felini. Micio è un gatto.", "Micio è un felino."],
			["Se piove la strada si bagna. Piove.", "La strada si bagna."],
			["Nessun pesce vola. Il tonno è un pesce.", "Il tonno non vola."],
			["Tutti i quadrati hanno quattro lati. Questa figura è un quadrato.", "Questa figura ha quattro lati."],
			["Se studio passo l'esame. Ho studiato.", "Ho passato l'esame."],
			["Tutti i numeri pari finiscono con una cifra pari. 38 è pari.", "38 finisce con una cifra pari."]]},
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
		{"explanation": "La dinamica cresce per gradi con nomi propri: dal pianissimo al fortissimo si passa sempre per i valori intermedi.", "topic": "dinamica", "minLevel": 5, "prompt": "Ordina le dinamiche dal più piano al più forte.", "correctOrder": ["pianissimo", "piano", "mezzoforte", "forte", "fortissimo"]},
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
		{"explanation": "Soggetto, verbo, complemento: in inglese l'ordine non si può cambiare senza cambiare il senso della frase.", "topic": "sentence", "minLevel": 3, "prompt": "Order the words to make a sentence.", "correctOrder": ["She", "reads", "a", "book"]},
		{"explanation": "La negazione si costruisce con l'ausiliare più «not», e va fra il soggetto e il verbo principale.", "topic": "negative", "minLevel": 5, "prompt": "Order the words to make a negative sentence.", "correctOrder": ["He", "does", "not", "play"]},
		# Domande: inversione dell'ausiliare (diverso dall'italiano).
		{"explanation": "Nella domanda l'ausiliare passa davanti al soggetto: è l'inversione a rendere interrogativa la frase, non solo il punto di domanda.", "topic": "question", "minLevel": 5, "prompt": "Order the words to make a question.", "correctOrder": ["Do", "you", "like", "pizza?"]},
		{"explanation": "Nelle domande con wh- la parola interrogativa va per prima, poi l'ausiliare, poi il soggetto.", "topic": "wh-question", "minLevel": 6, "prompt": "Order the words to make a question.", "correctOrder": ["Where", "do", "you", "live?"]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "In inglese l'ordine delle parole porta il significato, perche' le parole non cambiano forma: soggetto, verbo, oggetto, e poi il resto.", "topic": "sentence", "prompt": "Order the words to make a sentence.", "correctOrder": ["I", "read", "a book", "every evening"]},
	],
	"fisica": [
		# Insiemi a estrazione: in fisica l'ordine NON è una convenzione da ricordare,
		# è una grandezza. `value` è la grandezza vera (km/h, kg), quindi ogni
		# estrazione è una domanda sensata e la risposta è verificabile.
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
		{"explanation": "Prima si guarda, poi si misura, e solo alla fine si calcola: invertire l'ordine porta a calcolare una cosa che non si e' capita.", "topic": "metodo", "prompt": "Ordina i passi per misurare quanto e' veloce un oggetto.", "correctOrder": ["Segna il punto di partenza", "Misura la distanza", "Cronometra il tempo", "Dividi distanza per tempo"]},
	],
	"elettronica": [
		# Tensioni reali, dalla pila a bottone alla linea ad alta tensione: qui il
		# valore da ordinare è scritto sull'etichetta, quindi l'esercizio allena a
		# leggere gli ordini di grandezza (mV, V, kV) invece di ricordare una lista.
		{"explanation": "Si porta tutto alla stessa unità prima di confrontare: 300 mV sono 0,3 V, quindi meno di 1,2 V.", "topic": "misure-elettriche", "kind": "pool", "draw": 4, "prompt": "Ordina le tensioni dalla più piccola alla più grande.", "pool": [
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
		{"explanation": "La corrente percorre un anello chiuso: parte dal polo positivo, attraversa i componenti in fila e torna al negativo. In serie l'ordine è obbligato.", "topic": "circuito", "prompt": "Partendo dal polo positivo, ordina i componenti attraversati dalla corrente in questo circuito in serie.",
			"correctOrder": ["Polo positivo della pila", "Interruttore chiuso", "Resistore", "LED", "Polo negativo della pila"]},
		{"explanation": "Si monta il circuito prima di dargli corrente: collegare l'alimentazione per ultima è ciò che evita di bruciare il LED.", "topic": "montaggio", "minLevel": 3, "prompt": "Ordina i passi per costruire un circuito che accende un LED.", "correctOrder": ["Prendi la pila", "Collega il filo al polo +", "Aggiungi l'interruttore", "Collega il LED", "Chiudi il circuito al polo -"]},
		{"explanation": "Si confrontano i valori nella stessa unità: l'ordine delle fasce colorate dice il numero, non la grandezza.", "topic": "misure-elettriche", "minLevel": 5, "prompt": "Ordina le resistenze dalla più piccola.", "correctOrder": ["10 Ω", "100 Ω", "1 kΩ", "10 kΩ"]},
		# --- Terzo ordinamento al mondo 1 (7 agosto 2026) ----------------------
		{"explanation": "Si lavora sempre dal generatore verso l'utilizzatore: seguire la corrente nel suo verso e' il modo per non perdersi in un circuito grande.", "topic": "circuito", "prompt": "Ordina i passi per costruire un circuito che accende una lampadina.", "correctOrder": ["Prendi la pila", "Collega il primo filo al polo positivo", "Collega la lampadina", "Chiudi il circuito sul polo negativo"]},
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
		{"explanation": "Il plurale non si riconosce dalla vocale finale ma dal confronto con il singolare: «città» non cambia mai, e resta l'articolo a dirlo.", "topic": "pensiero-linguaggio", "draw": 6, "prompt": "Smista ogni parola: singolare o plurale?",
			"categories": ["singolare", "plurale"],
			"assignments": {
				"libro": "singolare", "fiore": "singolare", "casa": "singolare", "città": "singolare",
				"uovo": "singolare", "braccio": "singolare", "amico": "singolare", "problema": "singolare",
				"crisi": "singolare", "specie": "singolare", "dito": "singolare", "lenzuolo": "singolare",
				"libri": "plurale", "fiori": "plurale", "case": "plurale", "uova": "plurale",
				"braccia": "plurale", "amici": "plurale", "problemi": "plurale", "dita": "plurale",
				"lenzuola": "plurale", "valigie": "plurale", "camicie": "plurale", "ciliegie": "plurale"}},
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
	],
	"scienze": [
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
		{"explanation": "Un programma prende dati e ne restituisce: quello che entra viene da fuori, quello che esce va verso chi guarda. Confonderli è l'errore più comune all'inizio.", "topic": "input", "draw": 6, "prompt": "Smista ogni operazione: il dato entra o esce?",
			"categories": ["entra", "esce"],
			"assignments": {
				"chiedere il nome a chi gioca": "entra", "leggere la temperatura da un sensore": "entra",
				"ricevere il clic di un pulsante": "entra", "leggere una riga da un file": "entra",
				"registrare il tasto premuto": "entra", "ricevere un messaggio dalla rete": "entra",
				"scrivere il risultato a schermo": "esce", "accendere una lampadina": "esce",
				"salvare i punti in un file": "esce", "far suonare un avviso": "esce",
				"disegnare una figura": "esce", "mandare un messaggio in rete": "esce"}},
	],
	"storia": [
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
	],
	"fisica": [
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
		{"explanation": "I conduttori hanno elettroni liberi di muoversi — quasi tutti i metalli; gli isolanti no, e per questo si usano per rivestire.", "topic": "conduttori", "draw": 6, "prompt": "Smista ogni materiale: conduttore o isolante?",
			"categories": ["conduttore", "isolante"],
			"assignments": {
				"Rame": "conduttore", "Ferro": "conduttore", "Alluminio": "conduttore", "Argento": "conduttore",
				"Oro": "conduttore", "Acciaio": "conduttore", "Ottone": "conduttore", "Grafite": "conduttore",
				"Acqua salata": "conduttore", "Stagno": "conduttore", "Nichel": "conduttore", "Zinco": "conduttore",
				"Plastica": "isolante", "Legno secco": "isolante", "Gomma": "isolante", "Vetro": "isolante",
				"Ceramica": "isolante", "Carta": "isolante", "Aria secca": "isolante", "Porcellana": "isolante",
				"Silicone": "isolante", "Stoffa": "isolante", "Sughero": "isolante", "Acqua distillata": "isolante"}},
		{"explanation": "Si guarda il verso dell'energia: la pila e la cella solare la mettono nel circuito, la lampadina e il motore la prelevano per fare qualcosa.", "topic": "componenti", "draw": 6, "prompt": "Smista ogni componente: dà energia o la usa?",
			"categories": ["fornisce energia", "usa energia"],
			"assignments": {
				"Pila": "fornisce energia", "Batteria": "fornisce energia", "Cella solare": "fornisce energia",
				"Dinamo": "fornisce energia", "Alternatore": "fornisce energia", "Generatore a manovella": "fornisce energia",
				"Accumulatore carico": "fornisce energia", "Pila a bottone": "fornisce energia",
				"Powerbank": "fornisce energia", "Turbina eolica": "fornisce energia",
				"LED": "usa energia", "Motorino": "usa energia", "Lampadina": "usa energia",
				"Cicalino": "usa energia", "Ventola": "usa energia", "Resistore": "usa energia",
				"Altoparlante": "usa energia", "Display": "usa energia", "Elettrocalamita": "usa energia",
				"Riscaldatore": "usa energia", "Pompa elettrica": "usa energia", "Schermo LCD": "usa energia"}},
		# Ruolo nel circuito: sorgente, conduttore, isolante o carico.
		{"explanation": "Ogni elemento del circuito ha un ruolo solo: chi fornisce energia, chi la trasporta, chi la ferma, chi la consuma facendo un lavoro.", "topic": "ruoli", "minLevel": 4, "draw": 8, "prompt": "Smista ogni elemento per il suo ruolo nel circuito.",
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
		{"explanation": "In serie la corrente ha una strada sola, quindi se si interrompe si spegne tutto. In parallelo ognuno ha la sua strada, ed è il motivo per cui in casa è cablato così.", "topic": "serie-parallelo", "draw": 6, "prompt": "Smista ogni descrizione: serie o parallelo?",
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
		{"explanation": "La corrente cerca sempre la strada più facile per tornare indietro, e il corpo umano è una strada. Le regole di sicurezza servono tutte a non diventarlo.", "topic": "sicurezza-elettrica", "draw": 6, "prompt": "Smista ogni comportamento: prudente o pericoloso?",
			"categories": ["prudente", "pericoloso"],
			"assignments": {
				"staccare la spina prima di aprire un apparecchio": "prudente",
				"usare cacciaviti con il manico isolato": "prudente",
				"asciugarsi le mani prima di toccare una presa": "prudente",
				"far riparare un filo scoperto da un adulto": "prudente",
				"spegnere l'interruttore generale prima di lavorare": "prudente",
				"usare una pila da 4,5 volt per un esperimento": "prudente",
				"toccare una presa con le mani bagnate": "pericoloso",
				"infilare oggetti di metallo in una presa": "pericoloso",
				"usare un filo con la guaina rotta": "pericoloso",
				"collegare i due poli della pila con un filo nudo": "pericoloso",
				"attaccare troppe spine alla stessa presa": "pericoloso",
				"aprire un apparecchio ancora collegato": "pericoloso"}},
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
		{"explanation": "Si usa «an» davanti a suono vocalico e «a» davanti a suono consonantico: conta come si pronuncia la parola, non come si scrive.", "topic": "articles", "minLevel": 5, "draw": 6, "prompt": "Sort each word: does it take 'a' or 'an'?",
			"categories": ["a", "an"],
			"assignments": {
				"apple": "an", "orange": "an", "umbrella": "an", "elephant": "an",
				"island": "an", "hour": "an", "onion": "an", "artist": "an",
				"idea": "an", "egg": "an", "engine": "an", "honest man": "an",
				"dog": "a", "car": "a", "book": "a", "university": "a",
				"table": "a", "house": "a", "European city": "a", "friend": "a",
				"uniform": "a", "window": "a", "garden": "a", "yellow bird": "a"}},
		{"explanation": "La parte del discorso dipende dal lavoro che la parola fa: nomina qualcosa, dice un'azione o la descrive.", "topic": "parts-of-speech", "minLevel": 6, "draw": 6, "prompt": "Sort each word into its part of speech.",
			"categories": ["noun", "verb", "adjective"],
			"assignments": {
				"dog": "noun", "house": "noun", "river": "noun", "teacher": "noun",
				"bottle": "noun", "friendship": "noun", "mountain": "noun", "window": "noun",
				"run": "verb", "eat": "verb", "build": "verb", "listen": "verb",
				"forget": "verb", "choose": "verb", "arrive": "verb", "explain": "verb",
				"big": "adjective", "red": "adjective", "quiet": "adjective", "heavy": "adjective",
				"ancient": "adjective", "friendly": "adjective", "narrow": "adjective", "brave": "adjective"}},
		# Scuola media — verbi regolari/irregolari e nomi numerabili/non numerabili.
		{"explanation": "I verbi regolari fanno il passato in -ed; gli irregolari cambiano forma e vanno imparati uno per uno.", "topic": "verbs", "minLevel": 8, "draw": 6, "prompt": "Sort each past-tense verb: regular or irregular?",
			"categories": ["regular", "irregular"],
			"assignments": {
				"played": "regular", "walked": "regular", "watched": "regular", "opened": "regular",
				"listened": "regular", "arrived": "regular", "studied": "regular", "helped": "regular",
				"cleaned": "regular", "carried": "regular", "wanted": "regular", "stopped": "regular",
				"went": "irregular", "ate": "irregular", "saw": "irregular", "took": "irregular",
				"wrote": "irregular", "drank": "irregular", "began": "irregular", "brought": "irregular",
				"caught": "irregular", "chose": "irregular", "slept": "irregular", "spoke": "irregular"}},
		{"explanation": "I nomi numerabili si possono contare uno, due, tre; quelli non numerabili si misurano ma non si contano — acqua, riso, denaro.", "topic": "nouns", "minLevel": 9, "draw": 6, "prompt": "Sort each noun: countable or uncountable?",
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
	],
	"latino": [
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
		{"explanation": "Si smista per categoria di appartenenza, non per somiglianza d'aspetto: un fungo non è una pianta, anche se sta fermo nel terreno.", "topic": "esclusioni", "draw": 6, "prompt": "Smista ogni elemento nel suo insieme.",
			"categories": ["animale", "pianta"],
			"assignments": {
				"Cane": "animale", "Aquila": "animale", "Gatto": "animale", "Lombrico": "animale",
				"Ape": "animale", "Delfino": "animale", "Ragno": "animale", "Corallo": "animale",
				"Spugna di mare": "animale", "Medusa": "animale", "Pipistrello": "animale", "Formica": "animale",
				"Rosa": "pianta", "Quercia": "pianta", "Tulipano": "pianta", "Felce": "pianta",
				"Muschio": "pianta", "Cactus": "pianta", "Girasole": "pianta", "Trifoglio": "pianta",
				"Bambù": "pianta", "Edera": "pianta", "Grano": "pianta", "Pino": "pianta"}},
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
		{"explanation": "Ogni elemento va nell'insieme che lo contiene per proprietà, non per come è scritto: il blu è un colore anche se la parola è corta.", "topic": "insiemi", "minLevel": 3, "draw": 6, "prompt": "Smista ogni elemento nel suo insieme.",
			"categories": ["colori", "forme", "numeri"],
			"assignments": {
				"Rosso": "colori", "Blu": "colori", "Verde": "colori", "Giallo": "colori",
				"Viola": "colori", "Arancione": "colori", "Turchese": "colori", "Magenta": "colori",
				"Cerchio": "forme", "Quadrato": "forme", "Triangolo": "forme", "Rombo": "forme",
				"Trapezio": "forme", "Esagono": "forme", "Pentagono": "forme", "Ellisse": "forme",
				"Uno": "numeri", "Due": "numeri", "Sette": "numeri", "Dodici": "numeri",
				"Venti": "numeri", "Cento": "numeri", "Tre quarti": "numeri", "Zero": "numeri"}},
		# --- Mondo 1: ricette in più (tappa 4, 6 agosto 2026) -----------------
		{"explanation": "«Tutti», «qualcuno» e «nessuno» dicono QUANTI, e cambiare quello cambia tutto: negare «tutti» non dà «nessuno», dà «qualcuno no».", "topic": "quantificatori", "draw": 6, "prompt": "Smista ogni frase: parla di tutti, di qualcuno o di nessuno?",
			"categories": ["tutti", "qualcuno", "nessuno"],
			"assignments": {
				"Ogni quadrato ha quattro lati": "tutti",
				"Tutti i cani sono animali": "tutti",
				"Ciascun numero pari è divisibile per due": "tutti",
				"Qualche uccello non vola": "qualcuno",
				"Alcuni numeri pari sono anche primi": "qualcuno",
				"C'è almeno un pianeta con gli anelli": "qualcuno",
				"Nessun triangolo ha quattro lati": "nessuno",
				"Nessun mammifero ha le piume": "nessuno",
				"Non esiste un numero pari dispari": "nessuno"}},
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
		{"topic": "misure-elettriche", "xLabel": "pile in serie", "yLabel": "tensione", "answer": "D",
			"prompt": "Aggiungendo pile uguali in serie, in quale punto la tensione totale è maggiore?",
			"domande": [
				{"prompt": "In quale punto tensione scende al minimo?", "answer": "A", "explanation": "Il punto più basso è A: conta l'altezza, non quanto sta a destra. Poca tensione vuol dire poca spinta: il circuito riceve meno energia per far muovere le cariche."},
				{"prompt": "In quale punto si arriva dopo il salto in alto più grande di tensione?", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C. Un salto grande di tensione vuol dire che lì è stato aggiunto il contributo più grosso."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.43, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.67, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.91, "label": "D"}],
			"explanation": "In serie le tensioni delle pile si sommano: con più pile la tensione totale cresce, fino al punto D."},
		{"topic": "sicurezza", "xLabel": "resistenza", "yLabel": "corrente", "answer": "D",
			"prompt": "A tensione costante, la corrente diminuisce quando la resistenza aumenta. In quale punto la corrente è minore?",
			"domande": [
				{"prompt": "Guardando il grafico, dove corrente tocca il valore più alto?", "answer": "A", "explanation": "Il punto più alto è A: conta l'altezza, non quanto sta a destra. Molta corrente vuol dire molta carica che passa ogni secondo — ed è anche quando i fili scaldano di più."},
				{"prompt": "Quale punto è il più vicino alla metà strada fra minimo e massimo di corrente?", "answer": "B", "explanation": "Si guarda il valore più basso e il più alto, si pensa alla metà fra i due e si cerca il punto più vicino a quell'altezza: è B."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.91, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.65, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.40, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.18, "label": "D"}],
			"explanation": "Con la stessa tensione, una resistenza maggiore lascia passare meno corrente: il minimo è D."},
		{"topic": "legge-ohm", "minLevel": 6, "xLabel": "tensione", "yLabel": "corrente", "answer": "D",
			"prompt": "Il grafico mostra la corrente al crescere della tensione (legge di Ohm): in quale punto la corrente è massima?",
			"domande": [
				{"prompt": "Quale punto ha il valore di corrente più basso di tutti?", "answer": "A", "explanation": "Il punto più basso è A: conta l'altezza, non quanto sta a destra. Poca corrente vuol dire poca carica che passa ogni secondo: il LED illumina meno."},
				{"prompt": "Fra due punti vicini, dove corrente cresce di più? Indica il punto in cui arriva.", "answer": "B", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in B. Un salto grande di corrente vuol dire che lì il circuito ha lasciato passare molto di più di prima."},
			],
			"points": [{"id": "A", "x": 0.12, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.42, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.94, "label": "D"}],
			"explanation": "La corrente cresce in modo proporzionale alla tensione: è massima all'ultimo punto, D."},
		{"topic": "misure-elettriche", "minLevel": 5, "xLabel": "tempo", "yLabel": "carica", "answer": "D",
			"prompt": "Il grafico mostra la carica di una batteria mentre si scarica usandola: in quale punto è più scarica?",
			"domande": [
				{"prompt": "In quale punto carica arriva al massimo?", "answer": "A", "explanation": "Il punto più alto è A: conta l'altezza, non quanto sta a destra. Carica al massimo: la batteria è piena e il circuito ha tutta l'energia che gli serve."},
				{"prompt": "Guardando il grafico, dove carica tocca il valore più basso?", "answer": "D", "explanation": "Il punto più basso è D: conta l'altezza, non quanto sta a destra. Poca carica vuol dire batteria vicina a esaurirsi: da lì in poi il circuito comincia a spegnersi."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.66, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.38, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.12, "label": "D"}],
			"explanation": "Usandola la carica cala nel tempo: la batteria è più scarica alla fine, nel punto D."},
		{"topic": "legge-ohm", "minLevel": 12, "xLabel": "tensione", "yLabel": "corrente", "answer": "B",
			"prompt": "Ogni punto è una misura diversa. Poiché R = V / I, quale punto indica la resistenza maggiore (tensione alta ma corrente bassa)?",
			"domande": [
				{"prompt": "Guardando il grafico, dove corrente tocca il valore più basso?", "answer": "B", "explanation": "Il punto più basso è B: conta l'altezza, non quanto sta a destra. Poca corrente vuol dire poca carica che passa ogni secondo: il LED illumina meno."},
				{"prompt": "Dove corrente fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C. Un salto grande di corrente vuol dire che lì il circuito ha lasciato passare molto di più di prima."},
			],
			"points": [{"id": "A", "x": 0.28, "y": 0.72, "label": "A"}, {"id": "B", "x": 0.72, "y": 0.34, "label": "B"}, {"id": "C", "x": 0.48, "y": 0.80, "label": "C"}, {"id": "D", "x": 0.86, "y": 0.74, "label": "D"}],
			"explanation": "La resistenza è il rapporto V/I: B combina una tensione alta con una corrente bassa, quindi ha il rapporto maggiore."},
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
				{"prompt": "Dove velocità fa il balzo verso l'alto più netto? Indica il punto d'arrivo.", "answer": "C", "explanation": "Non conta quanto è alto un punto, ma quanto SALE rispetto a quello prima: il tratto più ripido arriva in C."},
			],
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.50, "label": "D"}],
			"explanation": "La velocità è massima dove la curva è più in alto: il punto C."},
		{"topic": "temperatura", "xLabel": "tempo", "yLabel": "temperatura", "answer": "A",
			"prompt": "Una bevanda calda si raffredda sul tavolo. In quale punto è ancora più calda?",
			"domande": [
				{"prompt": "Quale punto ha il valore di temperatura più basso di tutti?", "answer": "D", "explanation": "Il minimo si trova guardando chi sta più in BASSO, non chi sta più a sinistra: su questo grafico temperatura cresce verso l'alto, quindi il punto più basso è D."},
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
		{"topic": "circuito", "answer": "interruttore",
			"prompt": "Quale componente apre e chiude il passaggio della corrente?",
			"domande": [
				{"prompt": "Quale componente fornisce l'energia che fa muovere la corrente?", "answer": "pila", "explanation": "La pila è la sorgente: spinge la corrente lungo l'anello. Senza di lei nel circuito non si muove niente."},
				{"prompt": "Quale componente serve a limitare la corrente e proteggere il LED?", "answer": "resistore", "explanation": "Il resistore fa da freno: senza, il LED riceverebbe troppa corrente e si brucerebbe."},
			],
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.50, "y": 0.22, "label": "Interruttore"}, {"id": "resistore", "x": 0.80, "y": 0.50, "label": "Resistore"}, {"id": "led", "x": 0.50, "y": 0.78, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "resistore"], ["resistore", "led"], ["led", "pila"]],
			"explanation": "L'interruttore apre e chiude il circuito: accende o spegne il LED."},
		{"topic": "componenti", "answer": "led",
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
			"explanation": "Ha le ali → sì → il ramo porta a 'Uccello'."},
		{"topic": "albero-decisioni", "minLevel": 6, "answer": "quadrato",
			"prompt": "Segui l'albero: una figura ha 4 lati UGUALI e 4 angoli retti. Dove arrivi?",
			"domande": [
				{"prompt": "Segui l'albero: una figura NON ha 4 lati. Dove arrivi?", "answer": "triangolo", "explanation": "La prima domanda separa: se i lati non sono quattro, il ramo porta al triangolo."},
				{"prompt": "Segui l'albero: una figura ha 4 lati ma NON tutti uguali. Dove arrivi?", "answer": "rettangolo", "explanation": "Quattro lati sì, ma non uguali: il ramo porta al rettangolo."},
			],
			"components": [{"id": "quattro", "x": 0.50, "y": 0.12, "label": "Ha 4 lati?"}, {"id": "triangolo", "x": 0.20, "y": 0.52, "label": "Triangolo"}, {"id": "uguali", "x": 0.70, "y": 0.44, "label": "Lati uguali?"}, {"id": "quadrato", "x": 0.55, "y": 0.86, "label": "Quadrato"}, {"id": "rettangolo", "x": 0.90, "y": 0.86, "label": "Rettangolo"}],
			"connections": [["quattro", "triangolo"], ["quattro", "uguali"], ["uguali", "quadrato"], ["uguali", "rettangolo"]],
			"explanation": "4 lati → sì → lati uguali → sì → il ramo porta a 'Quadrato'."},
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
		{"topic": "vocabolario", "minLevel": 5, "answer": "play",
			"prompt": "These words all grow from the same short word. Which one is the base?",
			"domande": [
				{"prompt": "Which word means the person who plays?", "answer": "player", "explanation": "«Player» is «play» plus «-er»: the ending «-er» turns an action into the person who does it."},
				{"prompt": "Which word is the «-ing» form of the verb?", "answer": "playing", "explanation": "«Playing» is «play» plus «-ing»: it describes the action while it is happening."},
			],
			"components": [{"id": "play", "x": 0.50, "y": 0.20, "label": "play"}, {"id": "player", "x": 0.18, "y": 0.65, "label": "player"}, {"id": "playing", "x": 0.50, "y": 0.85, "label": "playing"}, {"id": "playful", "x": 0.82, "y": 0.65, "label": "playful"}],
			"connections": [["play", "player"], ["play", "playing"], ["play", "playful"]],
			"explanation": "«play» è la parola base: player, playing e playful sono costruite tutte su di lei aggiungendo un pezzo in fondo."},
		{"topic": "word-family", "minLevel": 5, "answer": "play",
			"prompt": "These English words belong to the same family. Which is the base word (the root)?",
			"domande": [
				{"prompt": "Which word names a place where children play?", "answer": "playground", "explanation": "«Playground» joins «play» and «ground»: it is a compound word, not just an ending."},
				{"prompt": "Which word describes someone full of fun?", "answer": "playful", "explanation": "«Playful» is «play» plus «-ful»: the ending «-ful» means «full of»."},
			],
			"components": [{"id": "play", "x": 0.50, "y": 0.20, "label": "play"}, {"id": "player", "x": 0.18, "y": 0.65, "label": "player"}, {"id": "playful", "x": 0.50, "y": 0.82, "label": "playful"}, {"id": "playground", "x": 0.82, "y": 0.65, "label": "playground"}],
			"connections": [["play", "player"], ["play", "playful"], ["play", "playground"]],
			"explanation": "The base word is 'play': player, playful and playground all come from it."},
		{"topic": "word-family", "minLevel": 6, "answer": "help",
			"prompt": "These words share the same root. Which is the base word?",
			"domande": [
				{"prompt": "Which word means the person who helps?", "answer": "helper", "explanation": "«Helper» is «help» plus «-er»: the ending «-er» names the person who does the action."},
				{"prompt": "Which word means «without help»?", "answer": "helpless", "explanation": "«Helpless» is «help» plus «-less»: the ending «-less» means «without»."},
			],
			"components": [{"id": "help", "x": 0.50, "y": 0.20, "label": "help"}, {"id": "helper", "x": 0.20, "y": 0.68, "label": "helper"}, {"id": "helpful", "x": 0.52, "y": 0.84, "label": "helpful"}, {"id": "helpless", "x": 0.82, "y": 0.66, "label": "helpless"}],
			"connections": [["help", "helper"], ["help", "helpful"], ["help", "helpless"]],
			"explanation": "The base word is 'help': helper, helpful and helpless are built from it."},
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
	],
	# MATEMATICA — "Caccia all'errore nel calcolo": si segue un procedimento passo
	# per passo e si smaschera la riga sbagliata. Colpisce le misconcezioni tipiche
	# (priorità, area vs perimetro, somma di frazioni): più coinvolgente che ripetere.
	"matematica": [
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
		{"topic": "sentence", "answerLine": 2,
			"prompt": "Find the mistake in this English text.",
			"codeLines": ["She is my best friend.", "She have a blue bike.", "She goes to school by bus.", "# check the verb"],
			"explanation": "Riga 2: con she, he e it il verbo diventa «has», non «have». La forma giusta è «She has a blue bike». Le righe 1 e 3 sono corrette."},
		{"topic": "spelling", "answerLine": 2, "shuffleLines": true,
			"prompt": "One word is spelled wrong. Which line?",
			"codeLines": ["I have a cat.", "The sun is yelow.", "She likes books.", "# find the spelling mistake"],
			"explanation": "Line 2: 'yellow' has a double L."},
		{"topic": "articles", "minLevel": 5, "answerLine": 3, "shuffleLines": true,
			"prompt": "One article is wrong. Which line?",
			"codeLines": ["I have a dog.", "There is an egg.", "She eats a apple.", "# which article is wrong?"],
			"explanation": "Line 3: before a vowel sound use 'an': 'an apple'."},
		{"topic": "third-person", "minLevel": 6, "answerLine": 2, "shuffleLines": true,
			"prompt": "One sentence has a grammar mistake. Which line?",
			"codeLines": ["I like pizza.", "She go to school every day.", "They play football.", "# find the sentence with the error"],
			"explanation": "Line 2: third person singular needs -s: 'She goes to school'."},
		{"topic": "past-tense", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One past tense is wrong. Which line?",
			"codeLines": ["Yesterday I played tennis.", "She goed home.", "We watched a film.", "# which past tense is wrong?"],
			"explanation": "Line 2: 'go' is irregular, the past is 'went', not 'goed'."},
		{"topic": "do-does", "minLevel": 7, "answerLine": 2, "shuffleLines": true,
			"prompt": "One negative sentence is wrong. Which line?",
			"codeLines": ["I don't like fish.", "He don't like tea.", "We don't watch TV.", "# which negative is wrong?"],
			"explanation": "Line 2: third person singular uses 'doesn't': 'He doesn't like tea'."},
	],
	# ELETTRONICA — "Caccia all'errore": si scova l'affermazione falsa sul circuito
	# o il passaggio sbagliato nel calcolo elettrico. Il ragionamento come sfida.
	"elettronica": [
		{"topic": "circuito", "answerLine": 3, "shuffleLines": true,
			"prompt": "Una sola affermazione sul circuito è falsa. Quale riga?",
			"codeLines": ["La pila fornisce energia.", "Il LED emette luce.", "Il filo di rame blocca la corrente.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il rame è un conduttore, quindi il filo LASCIA passare la corrente, non la blocca."},
		{"topic": "circuito", "answerLine": 2,
			"prompt": "Il LED dovrebbe accendersi: quale passaggio descrive un collegamento sbagliato?",
			"codeLines": ["Collego il polo + della pila al resistore", "Lascio un'interruzione tra resistore e LED", "Collego il LED al polo − della pila", "# la corrente ha bisogno di un percorso chiuso"],
			"explanation": "Riga 2: l'interruzione apre il circuito, quindi non scorre corrente. Serve un collegamento continuo tra resistore e LED."},
		{"topic": "serie-parallelo", "minLevel": 8, "answerLine": 3,
			"prompt": "Due lampadine sono in serie: quale conclusione sul percorso della corrente è sbagliata?",
			"codeLines": ["La corrente attraversa la prima lampadina", "Poi attraversa la seconda lampadina", "Può saltare la seconda scegliendo un altro ramo", "# in serie esiste un solo percorso"],
			"explanation": "Riga 3: in un circuito in serie non ci sono rami alternativi; la stessa corrente attraversa entrambe le lampadine."},
		{"topic": "potenza", "minLevel": 14, "answerLine": 2,
			"prompt": "Calcola la potenza con V = 6 V e I = 2 A: quale riga sbaglia?",
			"codeLines": ["P = V × I", "P = 6 + 2", "P = 8 W", "# nella formula i valori si moltiplicano"],
			"explanation": "Riga 2: la potenza è 6 × 2 = 12 W. La somma non applica la formula P = V × I."},
		{"topic": "condensatore", "minLevel": 20, "answerLine": 1,
			"prompt": "Segui la carica di un condensatore: quale passaggio è sbagliato?",
			"codeLines": ["Appena collegato è già alla tensione massima", "All'inizio entra corrente e la tensione cresce", "Avvicinandosi al massimo la crescita rallenta", "# la carica richiede un intervallo di tempo"],
			"explanation": "Riga 1: un condensatore non si carica istantaneamente; la sua tensione cresce nel tempo fino ad avvicinarsi a quella della sorgente."},
		{"topic": "legge-ohm", "minLevel": 6, "answerLine": 2, "shuffleLines": true,
			"prompt": "Corrente con V = 10 V e R = 2 Ω: quale riga sbaglia?",
			"codeLines": ["V = 10 V, R = 2 Ω", "I = V × R", "I = 20 A", "# come si calcola la corrente?"],
			"explanation": "Riga 2: la legge di Ohm è I = V / R (10 / 2 = 5 A), non V × R (che darebbe 20)."},
	],
	# SCIENZE — "Caccia all'errore": fra tre affermazioni una è falsa. Colpisce le
	# misconcezioni classiche (la Luna, le branchie, il vapore).
	"scienze": [
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
		{"topic": "pressione", "minLevel": 19, "answerLine": 2,
			"prompt": "La stessa forza agisce prima su un'area grande e poi su una piccola. Quale passaggio sbaglia?",
			"codeLines": ["pressione = forza / area", "Riducendo l'area, la pressione diminuisce", "A parità di forza, un'area minore dà più pressione", "# il denominatore diventa più piccolo"],
			"explanation": "Riga 2: dividendo la stessa forza per un'area più piccola si ottiene una pressione maggiore, non minore."},
	],
	# GEOGRAFIA — "Caccia all'errore": fra tre affermazioni una è falsa.
	"geografia": [
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
		{"topic": "casi", "minLevel": 3, "answerLine": 2,
			"prompt": "Segui l'analisi della frase: quale passo sbaglia?",
			"codeLines": ["«Puella rosam amat» vuol dire «la fanciulla ama la rosa».", "«rosam» è il soggetto della frase.", "Quindi è la rosa a fare l'azione.", "# quale parola compie l'azione?"],
			"explanation": "Riga 2: «rosam» finisce in -am, è accusativo, e l'accusativo è il complemento oggetto — la cosa amata. Il soggetto è «puella», in nominativo."},
		{"topic": "frasi", "minLevel": 3, "answerLine": 3, "shuffleLines": true,
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

# Argomenti che la materia sa servire con i minigiochi (oltre al banco statico).
# Sono contenuto reale a tutti gli effetti: una lezione può prometterli e il
# mondo li serve davvero (verificato in `world_lesson_audit`).
static func topics_for(subject: String) -> Array:
	var topics: Dictionary = {}
	for table in [MATCHING, ORDERING, CLASSIFICATION, GRAPH, CIRCUIT, CODE_DEBUG]:
		for spec in Array((table as Dictionary).get(subject, [])):
			var topic := str((spec as Dictionary).get("topic", ""))
			if topic != "":
				topics[topic] = true
	# Il generatore quantitativo non è a tabella: i suoi argomenti vanno aggiunti
	# a mano, altrimenti resta fuori dal registro e nessun audit lo controlla.
	for topic in Array(NUMERIC_ORDERING_TOPICS.get(subject, [])):
		topics[str(topic)] = true
	return topics.keys()

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
		{"topic": "irregular-past", "minLevel": 6, "prompt": "Scorri: a destra se il passato è giusto, a sinistra se è sbagliato.", "seconds": 50.0, "minAccuracy": 0.75,
			"statements": [
				{"text": "go → went", "correct": true},
				{"text": "eat → eated", "correct": false},
				{"text": "see → saw", "correct": true},
				{"text": "take → took", "correct": true},
				{"text": "make → maked", "correct": false},
				{"text": "come → came", "correct": true},
				{"text": "give → gave", "correct": true},
				{"text": "run → runned", "correct": false},
				{"text": "write → wrote", "correct": true},
				{"text": "buy → buyed", "correct": false},
				{"text": "find → found", "correct": true},
				{"text": "know → knew", "correct": true},
				{"text": "think → thinked", "correct": false}],
			"explanation": "I verbi irregolari non seguono la regola del -ed, e sono proprio quelli che si usano di più: le lingue non regolarizzano mai ciò che si dice ogni giorno. Le forme false qui sono quelle che un bambino costruirebbe applicando la regola — ed è giusto che sembrino plausibili."},
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
				{"text": "Francia → Parigi", "correct": true},
				{"text": "Spagna → Barcellona", "correct": false},
				{"text": "Germania → Berlino", "correct": true},
				{"text": "Portogallo → Lisbona", "correct": true},
				{"text": "Svizzera → Zurigo", "correct": false},
				{"text": "Grecia → Atene", "correct": true},
				{"text": "Austria → Vienna", "correct": true},
				{"text": "Turchia → Istanbul", "correct": false},
				{"text": "Polonia → Varsavia", "correct": true},
				{"text": "Italia → Roma", "correct": true},
				{"text": "Regno Unito → Londra", "correct": true},
				{"text": "Belgio → Bruxelles", "correct": true},
				{"text": "Paesi Bassi → Rotterdam", "correct": false},
				{"text": "Stati Uniti → New York", "correct": false}],
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
	],
	"geografia": [
		{"topic": "europa", "minLevel": 7, "prompt": "Quale Paese è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "Si trova in Europa e ha una costa sul mare."}, {"text": "Confina con la Francia via terra, ma non con la Germania."}, {"text": "Occupa gran parte di una penisola che condivide con un altro Paese."}, {"text": "La sua capitale sta quasi al centro esatto del territorio."}],
			"targets": [{"id": "a", "label": "Italia"}, {"id": "b", "label": "Spagna"}, {"id": "c", "label": "Portogallo"}, {"id": "d", "label": "Grecia"}],
			"answer": "b",
			"explanation": "Il secondo indizio esclude l'Italia, che confina anche con l'Austria e la Svizzera. Il terzo lascia Spagna e Portogallo; il quarto decide, perché Madrid è al centro e Lisbona è sulla costa."},
	],
	"scienze": [
		{"topic": "viventi", "minLevel": 5, "prompt": "Quale animale è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "È un vertebrato e vive in ambienti caldi e umidi."}, {"text": "Da piccolo respira nell'acqua, da adulto anche fuori."}, {"text": "La sua pelle è nuda e umida, senza squame né peli."}, {"text": "Da uovo diventa girino prima di avere le zampe."}],
			"targets": [{"id": "a", "label": "Rana"}, {"id": "b", "label": "Serpente"}, {"id": "c", "label": "Pesce rosso"}, {"id": "d", "label": "Tartaruga"}],
			"answer": "a",
			"explanation": "Il secondo indizio è già decisivo: cambiare modo di respirare crescendo è la definizione stessa di anfibio. Gli altri due lo confermano, e servono a chi non aveva colto il primo segnale."},
	],
	"inglese": [
		{"topic": "parts-of-speech", "minLevel": 9, "prompt": "Quale parola è? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "È un sostantivo inglese di uso comune, non un verbo."}, {"text": "Somiglia a una parola italiana ma non significa la stessa cosa."}, {"text": "Chi la traduce a orecchio pensa a un negozio, e sbaglia."}, {"text": "Il posto giusto dove tradurla è quello in cui i libri si prendono in prestito."}],
			"targets": [{"id": "a", "label": "bookshop"}, {"id": "b", "label": "library"}, {"id": "c", "label": "factory"}, {"id": "d", "label": "camera"}],
			"answer": "b",
			"explanation": "Il terzo indizio è quello che conta: «library» somiglia a «libreria» e invece è la biblioteca. È il falso amico che fa sbagliare più spesso, ed è per questo che qui si arriva scartando, non ricordando."},
	],
	"logica": [
		{"topic": "deduzioni", "minLevel": 8, "prompt": "Chi ha vinto la gara? Scopri solo gli indizi che ti servono.",
			"clues": [{"text": "I concorrenti erano quattro: Ada, Bruno, Carla e Dino."}, {"text": "Bruno si è ritirato prima della partenza, quindi non può aver vinto."}, {"text": "Il vincitore ha tagliato il traguardo pochi secondi prima di Carla."}, {"text": "Ada è arrivata subito dopo il vincitore, ma prima di Carla."}],
			"targets": [{"id": "a", "label": "Ada"}, {"id": "b", "label": "Bruno"}, {"id": "c", "label": "Carla"}, {"id": "d", "label": "Dino"}],
			"answer": "d",
			"explanation": "Ogni indizio toglie esattamente un nome: il secondo Bruno, il terzo Carla (che arriva dopo il vincitore), il quarto Ada (che arriva dopo anche lei). Resta Dino. In un'eliminazione non serve mai una prova diretta del vincitore: basta chiudere tutte le altre porte."},
	],
}

# LINEA DEL TEMPO: conta la DISTANZA, non solo l'ordine.
#
# Un ordinamento mette in fila due fatti a dieci anni e due a quattro secoli
# esattamente allo stesso modo. Sulla linea del tempo no — e quella differenza
# è tutta la storia.
const TIMELINE := {
	"storia": [
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
	],
	"musica": [
		{"topic": "compositori", "minLevel": 16, "prompt": "Quale compositore è vissuto più lontano nel tempo dagli altri due?",
			"min": 1650.0, "max": 1950.0,
			"labels": [{"value": 1650.0, "text": "1650"}, {"value": 1800.0, "text": "1800"}, {"value": 1950.0, "text": "1950"}],
			"targets": [{"id": "a", "label": "Vivaldi (1678)", "value": 1678.0}, {"id": "b", "label": "Beethoven (1770)", "value": 1770.0}, {"id": "c", "label": "Debussy (1862)", "value": 1862.0}],
			"answer": "a",
			"explanation": "Vivaldi è barocco, Beethoven a cavallo fra classico e romantico, Debussy quasi novecentesco. Le distanze sulla linea sono anche distanze di linguaggio musicale."},
	],
	"italiano": [
		{"topic": "testo-narrativo", "minLevel": 10, "prompt": "Quale opera è la più antica?",
			"min": 1250.0, "max": 1900.0,
			"labels": [{"value": 1300.0, "text": "1300"}, {"value": 1600.0, "text": "1600"}, {"value": 1900.0, "text": "1900"}],
			"targets": [{"id": "a", "label": "Divina Commedia (1321)", "value": 1321.0}, {"id": "b", "label": "Orlando furioso (1532)", "value": 1532.0}, {"id": "c", "label": "I promessi sposi (1827)", "value": 1827.0}],
			"answer": "a",
			"explanation": "Fra Dante e Manzoni passano cinquecento anni: la lingua italiana in mezzo cambia più di quanto sia cambiata dal 1827 a oggi."},
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
		{"topic": "analisi-grammaticale", "minLevel": 3, "prompt": "Completa la frase scegliendo la forma che concorda.",
			"slots": [{"text": "Le"}, {"text": "bambine"}, {"text": ""}, {"text": "in giardino"}],
			"targets": [{"id": "a", "label": "corre"}, {"id": "b", "label": "corrono"}, {"id": "c", "label": "correva"}],
			"answer": "b",
			"explanation": "Il soggetto è plurale, quindi il verbo va al plurale: «le bambine corrono». Gli altri due sono verbi giusti con l'accordo sbagliato — ed è l'accordo, non il verbo, che questa prova chiede."},
		{"topic": "ortografia", "minLevel": 6, "prompt": "Completa la frase con la forma corretta.",
			"slots": [{"text": "Non so"}, {"text": ""}, {"text": "ne abbia parlato"}],
			"targets": [{"id": "a", "label": "se"}, {"id": "b", "label": "sé"}, {"id": "c", "label": "s'è"}],
			"answer": "a",
			"explanation": "Qui «se» introduce una domanda indiretta e non vuole accento. «Sé» è il pronome riflessivo, «s'è» sta per «si è»: tre parole diverse che suonano identiche."},
	],
	"latino": [
		{"topic": "declinazioni-base", "minLevel": 5, "prompt": "Completa la forma: accusativo singolare di «rosa».",
			"slots": [{"text": "ros"}, {"text": ""}],
			"targets": [{"id": "a", "label": "-am"}, {"id": "b", "label": "-ae"}, {"id": "c", "label": "-is"}],
			"answer": "a",
			"explanation": "L'accusativo singolare della prima declinazione esce in -am. «-ae» è genitivo o nominativo plurale, «-is» appartiene alla terza: le desinenze sbagliate qui sono vere desinenze, prese dal posto sbagliato."},
	],
	"inglese": [
		{"topic": "question", "minLevel": 7, "prompt": "Completa la domanda mettendo l'ausiliare al posto giusto.",
			"slots": [{"text": "Where"}, {"text": ""}, {"text": "you live?"}],
			"targets": [{"id": "a", "label": "do"}, {"id": "b", "label": "are"}, {"id": "c", "label": "does"}],
			"answer": "a",
			"explanation": "In inglese la domanda inverte: dopo il «where» viene l'ausiliare e poi il soggetto. Con «you» l'ausiliare è «do» — «does» vale solo per lui, lei, esso."},
	],
	"coding": [
		{"topic": "sequenza", "minLevel": 4, "prompt": "Completa la riga perché il ciclo sia sintatticamente valido.",
			"slots": [{"text": "for i in range(5)"}, {"text": ""}],
			"targets": [{"id": "a", "label": ":"}, {"id": "b", "label": ";"}, {"id": "c", "label": "niente"}],
			"answer": "a",
			"explanation": "In Python i due punti aprono il blocco: senza, l'interprete non sa dove comincia il corpo del ciclo. Il punto e virgola non serve, ed è l'abitudine che arriva da altri linguaggi."},
	],
	"musica": [
		{"topic": "intervalli", "minLevel": 12, "prompt": "Completa l'accordo di Do maggiore.",
			"slots": [{"text": "Do"}, {"text": ""}, {"text": "Sol"}],
			"targets": [{"id": "a", "label": "Mi"}, {"id": "b", "label": "Fa"}, {"id": "c", "label": "Re"}],
			"answer": "a",
			"explanation": "L'accordo maggiore è fondamentale, terza maggiore e quinta: Do-Mi-Sol. Fa e Re sono note vicinissime, e proprio per questo sono l'errore che si fa davvero."},
	],
	"matematica": [
		{"topic": "calcolo", "minLevel": 6, "prompt": "Completa l'espressione perché il risultato sia 20.",
			"slots": [{"text": "4"}, {"text": ""}, {"text": "5"}],
			"targets": [{"id": "a", "label": "×"}, {"id": "b", "label": "+"}, {"id": "c", "label": "−"}],
			"answer": "a",
			"explanation": "Quattro per cinque fa venti. Scegliere l'operazione invece di eseguirla obbliga a ragionare al contrario, partendo dal risultato — che è quello che serve per risolvere un problema."},
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
	"logica": [
		{"topic": "deduzioni", "minLevel": 7, "prompt": "Applica le eliminazioni in ordine: chi resta?",
			"steps": [{"label": "in gara: Ada, Bruno, Carla, Dino", "state": "4 rimasti"}, {"label": "non è un maschio", "state": "Ada, Carla"}, {"label": "il nome non finisce per -a", "state": ""}],
			"targets": [{"id": "a", "label": "Ada"}, {"id": "b", "label": "Carla"}, {"id": "c", "label": "nessuno"}],
			"answer": "c",
			"explanation": "Dopo la prima eliminazione restano due nomi che finiscono entrambi per -a: la seconda condizione li toglie tutti. Un indovinello può non avere soluzione, e accorgersene è parte del ragionamento."},
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
		{"topic": "forze", "minLevel": 8, "prompt": "La leva è in equilibrio. Quale peso manca a destra, a 1 metro dal fulcro?",
			"left": [{"label": "2 kg a 3 m", "value": 6.0}],
			"right": [],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "2 kg", "value": 2.0}, {"id": "b", "label": "4 kg", "value": 4.0}, {"id": "c", "label": "6 kg", "value": 6.0}],
			"answer": "c",
			"explanation": "Su una leva non conta il peso ma il momento: peso per distanza. Due chili a tre metri fanno sei, e per pareggiare a un solo metro servono sei chili. È il motivo per cui un bambino può sollevare un adulto stando più lontano dal fulcro."},
	],
	"elettronica": [
		{"topic": "serie-parallelo", "minLevel": 10, "prompt": "Le due serie devono avere la stessa resistenza totale. Quale resistore manca?",
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
	"logica": [
		{"topic": "insiemi", "minLevel": 7, "prompt": "I due gruppi devono avere lo stesso numero di elementi. Quanti ne mancano a destra?",
			"left": [{"label": "7 elementi", "value": 7.0}],
			"right": [{"label": "4 elementi", "value": 4.0}],
			"gapSide": "right",
			"targets": [{"id": "a", "label": "1 elemento", "value": 1.0}, {"id": "b", "label": "3 elementi", "value": 3.0}, {"id": "c", "label": "5 elementi", "value": 5.0}],
			"answer": "b",
			"explanation": "Confrontare due insiemi non richiede di contarli entrambi da capo: basta la differenza. È lo stesso ragionamento che permette di dire «ce ne sono di più» senza sapere quanti."},
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
		{"topic": "italia-fisica", "minLevel": 3, "mapId": "italy",
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
	],
}

## Reperti illustrati. `assetId` nomina un atlante condiviso — un foglio solo con
## più reperti, mai un file per esercizio — e i bersagli sono semantici: le
## coordinate stanno in `artifact_atlas_catalog.gd`.
const HOTSPOT := {
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
		{"topic": "roma", "minLevel": 3, "assetId": "roman_artifacts",
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
	"verb_decoder",
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
## voluto: la banda 4 comincia a comparire dal mondo 13 invece che dal 19, e la
## banda 1 non sparisce di colpo al mondo 6.
static func gradient_step(idx: int, total: int) -> int:
	if total < 3:
		return 0   # con una o due campate un gradiente non ha senso
	if idx == 0:
		return -1
	if idx >= total - 1:
		return 1
	return 0

static func difficulty_of(level: int, step: int) -> int:
	return clampi(ContentManager.target_difficulty(level) + step, 1, 4)

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

func build_minigame(subject: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var has_match := MATCHING.has(subject)
	var has_order := ORDERING.has(subject)
	var has_classify := CLASSIFICATION.has(subject)
	var numeric := NUMERIC_ORDERING_SUBJECTS.has(subject)
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
	if subject in ["scienze", "fisica"]:
		base.append("mystery_sample")
	if subject == "italiano":
		# Un messaggio da ricostruire con tre regolazioni: quando accade,
		# con quale intenzione viene detto e quale forma verbale lo completa.
		base.append("verb_decoder")
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
	if GRAPH.has(subject) and _has_eligible(GRAPH[subject], level):
		specialists.append("graph")
	if CIRCUIT.has(subject) and _has_eligible(CIRCUIT[subject], level):
		specialists.append("circuit")
	if CYCLE.has(subject) and _has_eligible(CYCLE[subject], level):
		specialists.append("cycle")
	if NOTATION.has(subject) and format_available(subject, "notation", level):
		specialists.append("notation")
	if BALANCE.has(subject) and _has_eligible(BALANCE[subject], level):
		specialists.append("balance")
	if TIMELINE.has(subject) and _has_eligible(TIMELINE[subject], level):
		specialists.append("timeline")
	if CLUE.has(subject) and _has_eligible(CLUE[subject], level):
		specialists.append("clue")
	if SWIPE.has(subject) and _has_eligible(SWIPE[subject], level):
		specialists.append("swipe")
	if COMPOSE.has(subject) and _has_eligible(COMPOSE[subject], level):
		specialists.append("compose")
	if TRACE.has(subject) and _has_eligible(TRACE[subject], level):
		specialists.append("trace")
	if NUMBER_LINE.has(subject) and _has_eligible(NUMBER_LINE[subject], level):
		specialists.append("number_line")
	if MAP_READING.has(subject) and format_available(subject, "map", level):
		specialists.append("map")
	if HOTSPOT.has(subject) and format_available(subject, "hotspot", level):
		specialists.append("hotspot")
	if CODE_DEBUG.has(subject) and _has_eligible(CODE_DEBUG[subject], level):
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
		var difficulty := difficulty_of(level, step)
		match fmt:
			"machine_path":
				nodes.append(_machine_path_node(subject, level, step, generator, idx))
			"mystery_sample":
				nodes.append(_mystery_sample_node(subject, level, step, generator, idx))
			"verb_decoder":
				nodes.append(_verb_decoder_node(subject, level, step, generator, idx))
			"matching":
				nodes.append(_matching_node(subject, _pick(MATCHING[subject], generator, level), level, step, generator, idx))
			"ordering":
				nodes.append(_ordering_node(subject, _pick(ORDERING[subject], generator, level), level, step, generator, idx))
			"numeric":
				nodes.append(_numeric_ordering_node(subject, level, step, generator, idx))
			"classification":
				nodes.append(_classification_node(subject, _pick(CLASSIFICATION[subject], generator, level), level, step, generator, idx))
			"graph":
				nodes.append(_graph_node(subject, _pick(GRAPH[subject], generator, level), difficulty, generator, idx))
			"circuit":
				nodes.append(_circuit_node(subject, _pick(CIRCUIT[subject], generator, level), difficulty, generator, idx))
			"cycle":
				nodes.append(_cycle_node(subject, _pick(CYCLE[subject], generator, level), difficulty, generator, idx))
			"notation":
				nodes.append(_notation_node(subject, _pick(NOTATION[subject], generator, level), difficulty, generator, idx))
			"swipe":
				nodes.append(_swipe_node(subject, _pick(SWIPE[subject], generator, level), difficulty, generator, idx))
			"clue":
				nodes.append(_clue_node(subject, _pick(CLUE[subject], generator, level), difficulty, generator, idx))
			"timeline":
				nodes.append(_timeline_node(subject, _pick(TIMELINE[subject], generator, level), difficulty, generator, idx))
			"compose":
				nodes.append(_compose_node(subject, _pick(COMPOSE[subject], generator, level), difficulty, generator, idx))
			"trace":
				nodes.append(_trace_node(subject, _pick(TRACE[subject], generator, level), difficulty, generator, idx))
			"balance":
				nodes.append(_balance_node(subject, _pick(BALANCE[subject], generator, level), difficulty, generator, idx))
			"number_line":
				nodes.append(_number_line_node(subject, _pick(NUMBER_LINE[subject], generator, level), difficulty, generator, idx))
			"map":
				nodes.append(_map_node(subject, _pick(MAP_READING[subject], generator, level), difficulty, generator, idx))
			"hotspot":
				nodes.append(_hotspot_node(subject, _pick(HOTSPOT[subject], generator, level), difficulty, generator, idx))
			"code_debug":
				nodes.append(_code_debug_node(subject, _pick(CODE_DEBUG[subject], generator, level), difficulty, generator, idx))
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
	var frasi: Array = (spec["statements"] as Array).duplicate(true)
	_shuffle(frasi, rng)
	return {
		"id": "minigame-swipe-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "swipe",
		"prompt": str(spec["prompt"]),
		"seconds": float(spec.get("seconds", 45.0)),
		"minAccuracy": float(spec.get("minAccuracy", 0.75)),
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
	if ExercisePool.is_pool(spec):
		# Etichette e valori tutti distinti: due voci con lo stesso valore
		# renderebbero l'ordine ambiguo, due con la stessa etichetta impossibile.
		var drawn := ExercisePool.draw(spec, "", ordering_draw(spec, level, step), rng, ORDERING_UNIQUE)
		drawn.sort_custom(func(a, b): return float((a as Dictionary)["value"]) < float((b as Dictionary)["value"]))
		if bool(spec.get("descending", false)):
			drawn.reverse()
		for entry in drawn:
			correct.append(str((entry as Dictionary)["label"]))
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
		"explanation": "Ogni macchina lavora sul risultato della precedente. Un percorso possibile è: %s. La sfera arriva così a %d." % ["  →  ".join(PackedStringArray(labels)), target],
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
		{"id": "magnet", "label": "Avvicina la calamita", "short": "CALAMITA", "glyph": "⌁"},
		{"id": "circuit", "label": "Chiudi il circuito", "short": "CIRCUITO", "glyph": "ϟ"},
		{"id": "light", "label": "Accendi la lampada", "short": "LUCE", "glyph": "✦"},
		{"id": "water", "label": "Posa sull'acqua", "short": "ACQUA", "glyph": "≈"},
	]
	if difficulty <= 1:
		tests = tests.filter(func(test): return str((test as Dictionary).get("id", "")) != "circuit")
	_shuffle(tests, rng)
	var answer := str((samples[rng.randi_range(0, samples.size() - 1)] as Dictionary).get("id", ""))
	var explanations := {
		"iron": "Il ferro conduce la corrente e, fra questi campioni, è l'unico attirato dalla calamita.",
		"copper": "Il rame conduce la corrente ma non viene attirato dalla calamita: le due prove insieme lo distinguono dal ferro.",
		"glass": "Il vetro non conduce e non galleggia, ma lascia passare il fascio della lampada.",
		"cork": "Il sughero non conduce e non lascia passare la luce, ma galleggia perché è meno denso dell'acqua.",
		"ceramic": "La ceramica non conduce, non è attirata dalla calamita, non lascia passare la luce e affonda: conta l'insieme delle prove.",
	}
	return {
		"id": "minigame-mystery-sample-%s-%d-%d" % [subject, level, idx],
		"subject": subject,
		"topic": "proprietà-dei-materiali",
		"difficulty": difficulty,
		"format": "mystery_sample",
		"title": "Il campione senza nome",
		"prompt": "Dal Relitto è arrivato un campione senza etichetta. Scegli gli esperimenti, osserva le reazioni e scopri di quale materiale si tratta.",
		"samples": samples,
		"tests": tests,
		"results": _mystery_sample_results(),
		"answer": answer,
		"minTests": 3 if difficulty >= 4 else 2,
		"explanation": str(explanations.get(answer, "Le proprietà osservate permettono di riconoscere il materiale.")),
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
	for raw in _verb_decoder_templates():
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
static func _verb_decoder_templates() -> Array:
	return [
		{"case":"now", "tier":1, "topic":"indicativo-tempi",
			"segments":["Adesso NORA", "la mappa sul tavolo."], "time":"presente", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio o desiderio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["osserva","ha osservato","osserverà"], "clues":["adesso","un fatto osservato"],
			"hints":{"time":"“Adesso” porta l'azione nel presente.","mood":"La frase presenta un fatto, quindi usa l'indicativo.","form":"Serve la forma che concorda con NORA e indica il presente."},
			"discovery":"Sul bordo della mappa compare una traccia appena disegnata.",
			"explanation":"“Adesso” indica il presente; la frase racconta un fatto come reale, quindi usa l'indicativo presente: osserva."},
		{"case":"yesterday", "tier":1, "topic":"indicativo-tempi",
			"segments":["Ieri Rame", "una chiave sotto la passerella."], "time":"passato_prossimo", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio o desiderio"],["imperativo","IMPERATIVO · ordine"]],
			"forms":["ha trovato","trova","troverà"], "clues":["ieri","azione conclusa"],
			"hints":{"time":"“Ieri” indica un fatto già concluso.","mood":"Il ritrovamento viene raccontato come reale.","form":"Cerca ausiliare + participio: è un tempo composto."},
			"discovery":"La chiave apre un cassetto che nessuno aveva notato.",
			"explanation":"“Ieri” e l'azione conclusa richiedono il passato prossimo indicativo: ha trovato."},
		{"case":"tomorrow", "tier":1, "topic":"indicativo-tempi",
			"segments":["Domani NORA", "il corridoio oltre il vetro."], "time":"futuro_semplice", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto previsto"],["condizionale","CONDIZIONALE · possibilità"],["imperativo","IMPERATIVO · ordine"]],
			"forms":["esplorerà","esplora","esplorerebbe"], "clues":["domani","programma stabilito"],
			"hints":{"time":"“Domani” sposta l'azione nel futuro.","mood":"È un programma presentato come certo, non come ipotesi.","form":"La desinenza -erà indica il futuro della terza persona."},
			"discovery":"La voce conosce un luogo che non compare sulle mappe.",
			"explanation":"“Domani” indica futuro; il programma è presentato come certo, quindi indicativo futuro semplice: esplorerà."},
		{"case":"habit", "tier":1, "topic":"indicativo-tempi",
			"segments":["Ogni notte la luce azzurra", "tre volte."], "time":"presente", "mood":"indicativo",
			"times":[["presente","PRESENTE"],["imperfetto","IMPERFETTO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["lampeggia","lampeggiava","lampeggerebbe"], "clues":["ogni notte","fenomeno che si ripete"],
			"hints":{"time":"Un'abitudine ancora valida può essere espressa al presente.","mood":"La luce viene descritta come un fenomeno osservato.","form":"Il soggetto è singolare: la luce lampeggia."},
			"discovery":"I tre lampi sembrano una richiesta di risposta.",
			"explanation":"“Ogni notte” descrive qui un'abitudine ancora valida: indicativo presente, lampeggia."},
		{"case":"while", "tier":2, "topic":"indicativo-tempi",
			"segments":["Mentre Rame", "il corridoio, una porta si aprì."], "time":"imperfetto", "mood":"indicativo",
			"times":[["imperfetto","IMPERFETTO"],["passato_prossimo","PASSATO PROSSIMO"],["futuro_semplice","FUTURO SEMPLICE"]],
			"moods":[["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["esplorava","ha esplorato","esplorerà"], "clues":["mentre","azione in corso nel passato"],
			"hints":{"time":"“Mentre” presenta un'azione in corso quando ne accade un'altra.","mood":"Entrambe le azioni sono narrate come fatti.","form":"L'imperfetto di esplorare termina in -ava."},
			"discovery":"La porta reagì al passaggio di Rame, non a un comando.",
			"explanation":"L'azione di esplorare era in corso quando la porta si aprì: indicativo imperfetto, esplorava."},
		{"case":"before", "tier":2, "topic":"indicativo-tempi",
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
		{"case":"would_explore", "tier":3, "topic":"congiuntivo-condizionale",
			"segments":["Con una torcia, io", "anche il tunnel più buio."], "time":"presente", "mood":"condizionale",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["condizionale","CONDIZIONALE · possibilità"],["indicativo","INDICATIVO · fatto"],["congiuntivo","CONGIUNTIVO · dubbio"]],
			"forms":["esplorerei","esploro","esplorassi"], "clues":["con una torcia","azione possibile a una condizione"],
			"hints":{"time":"La possibilità riguarda il presente o il futuro vicino.","mood":"L'azione dipende dalla condizione “con una torcia”.","form":"Alla prima persona: esplorerei."},
			"discovery":"Nel tunnel c'è ancora una luce: qualcuno potrebbe essere dentro.",
			"explanation":"Esplorare dipende da una condizione: condizionale presente, esplorerei."},
		{"case":"if_present", "tier":3, "topic":"congiuntivo-condizionale",
			"segments":["Se trovassimo la chiave,", "la stanza nascosta."], "time":"presente", "mood":"condizionale",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["imperfetto","IMPERFETTO"]],
			"moods":[["condizionale","CONDIZIONALE · conseguenza"],["congiuntivo","CONGIUNTIVO · ipotesi"],["indicativo","INDICATIVO · fatto"]],
			"forms":["apriremmo","aprissimo","apriamo"], "clues":["se trovassimo","conseguenza possibile"],
			"hints":{"time":"La conseguenza è ancora possibile, non già conclusa.","mood":"Dopo l'ipotesi al congiuntivo, la conseguenza va al condizionale.","form":"La prima persona plurale termina in -remmo."},
			"discovery":"La stanza nascosta esiste, ma la sua posizione resta incerta.",
			"explanation":"“Se trovassimo” esprime l'ipotesi; la conseguenza usa il condizionale presente: apriremmo."},
		{"case":"if_past", "tier":4, "topic":"congiuntivo-condizionale",
			"segments":["Se avessimo letto il diario,", "la trappola."], "time":"passato", "mood":"condizionale",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["imperfetto","IMPERFETTO"]],
			"moods":[["condizionale","CONDIZIONALE · conseguenza"],["congiuntivo","CONGIUNTIVO · ipotesi"],["indicativo","INDICATIVO · fatto"]],
			"forms":["avremmo evitato","eviteremmo","avessimo evitato"], "clues":["se avessimo letto","occasione ormai trascorsa"],
			"hints":{"time":"L'occasione è passata e non può più realizzarsi.","mood":"La conseguenza non avvenuta usa il condizionale.","form":"Serve avremmo + participio passato."},
			"discovery":"Qualcuno aveva lasciato un avvertimento che non vedemmo in tempo.",
			"explanation":"L'ipotesi passata non si è realizzata: la conseguenza usa il condizionale passato, avremmo evitato."},
		{"case":"already_left", "tier":4, "topic":"concordanza-tempi-verbali",
			"segments":["NORA pensava che Rame", "già partito."], "time":"trapassato", "mood":"congiuntivo",
			"times":[["presente","PRESENTE"],["imperfetto","IMPERFETTO"],["trapassato","TRAPASSATO"]],
			"moods":[["congiuntivo","CONGIUNTIVO · pensiero"],["indicativo","INDICATIVO · fatto"],["condizionale","CONDIZIONALE · possibilità"]],
			"forms":["fosse","sia","sarebbe"], "clues":["pensava che","partire è precedente al pensiero"],
			"hints":{"time":"La partenza è anteriore a un pensiero già nel passato.","mood":"“Pensava che” introduce ciò che NORA riteneva, non un fatto certificato.","form":"Fosse + participio costruisce il congiuntivo trapassato."},
			"discovery":"Rame non era partito: stava seguendo la voce da solo.",
			"explanation":"La partenza sarebbe precedente al pensiero passato: congiuntivo trapassato, fosse già partito."},
		{"case":"after_decoding", "tier":4, "topic":"imperativo-infinito-participio-gerundio",
			"segments":["Dopo", "il messaggio, Rame spense il ricevitore."], "time":"passato", "mood":"infinito",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["infinito","INFINITO · forma senza persona"],["gerundio","GERUNDIO · azione collegata"],["participio","PARTICIPIO · risultato"]],
			"forms":["aver decifrato","decifrare","avendo decifrato"], "clues":["dopo","azione conclusa prima della principale"],
			"hints":{"time":"Decifrare è concluso prima di spegnere.","mood":"Dopo la preposizione “dopo” si può usare l'infinito.","form":"L'infinito passato usa avere + participio: aver decifrato."},
			"discovery":"Il ricevitore spento continuò a sussurrare per alcuni secondi.",
			"explanation":"L'azione è anteriore e non indica una persona propria: infinito passato, aver decifrato."},
		{"case":"having_understood", "tier":4, "topic":"imperativo-infinito-participio-gerundio",
			"segments":["Pur", "la risposta, NORA attese prima di parlare."], "time":"passato", "mood":"gerundio",
			"times":[["presente","PRESENTE"],["passato","PASSATO"],["futuro","FUTURO"]],
			"moods":[["gerundio","GERUNDIO · azione collegata"],["infinito","INFINITO · forma base"],["participio","PARTICIPIO · risultato"]],
			"forms":["avendo capito","capendo","aver capito"], "clues":["pur","capire avviene prima di attendere"],
			"hints":{"time":"NORA ha già capito quando decide di aspettare.","mood":"“Pur” collega qui due azioni dello stesso soggetto con il gerundio.","form":"Il gerundio passato usa avendo + participio."},
			"discovery":"NORA riconobbe la voce, ma non volle ancora dire di chi fosse.",
			"explanation":"Capire precede l'attesa e il soggetto resta NORA: gerundio passato, avendo capito."},
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
