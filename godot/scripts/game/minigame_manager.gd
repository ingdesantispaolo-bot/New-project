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
		# Tre insiemi di vocabolario già dal primo mondo: al livello 1 si pescano solo
		# 3 coppie, quindi la profondità di una singola specifica non basta — servono
		# più insiemi idonei fin da subito, non insiemi più grandi più tardi.
		{"topic": "vocabolario", "pairs": [
			["dog", "cane"], ["cat", "gatto"], ["sun", "sole"], ["house", "casa"],
			["water", "acqua"], ["book", "libro"], ["tree", "albero"], ["red", "rosso"],
			["moon", "luna"], ["star", "stella"], ["bread", "pane"], ["milk", "latte"],
			["door", "porta"], ["window", "finestra"], ["chair", "sedia"], ["table", "tavolo"],
			["hand", "mano"], ["head", "testa"], ["friend", "amico"], ["school", "scuola"],
			["city", "città"], ["river", "fiume"], ["mountain", "montagna"], ["sea", "mare"],
			["bird", "uccello"], ["horse", "cavallo"], ["flower", "fiore"], ["key", "chiave"],
			["road", "strada"], ["cloud", "nuvola"], ["snow", "neve"], ["fire", "fuoco"]]},
		{"topic": "vocabolario", "pairs": [
			["one", "uno"], ["two", "due"], ["three", "tre"], ["four", "quattro"],
			["five", "cinque"], ["six", "sei"], ["seven", "sette"], ["eight", "otto"],
			["nine", "nove"], ["ten", "dieci"], ["eleven", "undici"], ["twelve", "dodici"],
			["thirteen", "tredici"], ["fifteen", "quindici"], ["twenty", "venti"], ["thirty", "trenta"],
			["forty", "quaranta"], ["fifty", "cinquanta"], ["hundred", "cento"], ["thousand", "mille"]]},
		# Verbi di uso quotidiano: il terzo insieme disponibile dal mondo 1.
		{"topic": "vocabolario", "pairs": [
			["to run", "correre"], ["to eat", "mangiare"], ["to drink", "bere"], ["to sleep", "dormire"],
			["to read", "leggere"], ["to write", "scrivere"], ["to play", "giocare"], ["to sing", "cantare"],
			["to walk", "camminare"], ["to swim", "nuotare"], ["to laugh", "ridere"], ["to cry", "piangere"],
			["to open", "aprire"], ["to close", "chiudere"], ["to buy", "comprare"], ["to help", "aiutare"],
			["to listen", "ascoltare"], ["to look", "guardare"], ["to speak", "parlare"], ["to learn", "imparare"],
			["to teach", "insegnare"], ["to build", "costruire"], ["to find", "trovare"], ["to lose", "perdere"],
			["to give", "dare"], ["to take", "prendere"], ["to bring", "portare"], ["to answer", "rispondere"],
			["to ask", "chiedere"], ["to wait", "aspettare"]]},
		{"topic": "opposites", "minLevel": 3, "pairs": [
			["hot", "cold"], ["big", "small"], ["fast", "slow"], ["happy", "sad"],
			["old", "new"], ["long", "short"], ["high", "low"], ["light", "heavy"],
			["full", "empty"], ["open", "shut"], ["clean", "dirty"], ["easy", "hard"],
			["strong", "weak"], ["rich", "poor"], ["near", "far"], ["young", "elderly"],
			["loud", "quiet"], ["wet", "dry"], ["early", "late"], ["first", "last"],
			["day", "night"], ["summer", "winter"], ["inside", "outside"], ["above", "below"],
			["always", "never"], ["everything", "nothing"]]},
		# Conversazione: micro-scambi domanda -> risposta.
		{"topic": "conversation", "minLevel": 5, "pairs": [
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
		{"topic": "contractions", "minLevel": 6, "pairs": [
			["I am", "I'm"], ["you are", "you're"], ["do not", "don't"], ["cannot", "can't"],
			["it is", "it's"], ["she is", "she's"], ["they are", "they're"], ["we are", "we're"],
			["does not", "doesn't"], ["did not", "didn't"], ["is not", "isn't"], ["are not", "aren't"],
			["was not", "wasn't"], ["were not", "weren't"], ["will not", "won't"], ["would not", "wouldn't"],
			["has not", "hasn't"], ["have not", "haven't"], ["I will", "I'll"], ["I have", "I've"]]},
		{"topic": "irregular-past", "minLevel": 7, "pairs": [
			["go", "went"], ["eat", "ate"], ["see", "saw"], ["have", "had"], ["make", "made"],
			["take", "took"], ["give", "gave"], ["come", "came"], ["write", "wrote"], ["read", "read /red/"],
			["run", "ran"], ["swim", "swam"], ["sing", "sang"], ["drink", "drank"], ["begin", "began"],
			["buy", "bought"], ["bring", "brought"], ["think", "thought"], ["teach", "taught"], ["catch", "caught"],
			["find", "found"], ["lose", "lost"], ["sleep", "slept"], ["keep", "kept"], ["leave", "left"],
			["speak", "spoke"], ["break", "broke"], ["choose", "chose"]]},
		{"topic": "irregular-plural", "minLevel": 8, "pairs": [
			["child", "children"], ["man", "men"], ["foot", "feet"], ["mouse", "mice"],
			["tooth", "teeth"], ["woman", "women"], ["goose", "geese"], ["person", "people"],
			["knife", "knives"], ["leaf", "leaves"], ["wife", "wives"], ["shelf", "shelves"],
			["life", "lives"], ["city", "cities"], ["baby", "babies"], ["sheep", "sheep (invariato)"],
			["fish", "fish (invariato)"], ["potato", "potatoes"]]},
	],
	"geografia": [
		{"topic": "capitali", "pairs": [
			["Italia", "Roma"], ["Francia", "Parigi"], ["Spagna", "Madrid"], ["Germania", "Berlino"],
			["Portogallo", "Lisbona"], ["Grecia", "Atene"], ["Austria", "Vienna"], ["Belgio", "Bruxelles"],
			["Paesi Bassi", "Amsterdam"], ["Danimarca", "Copenaghen"], ["Svezia", "Stoccolma"], ["Norvegia", "Oslo"],
			["Finlandia", "Helsinki"], ["Polonia", "Varsavia"], ["Ungheria", "Budapest"], ["Irlanda", "Dublino"],
			["Svizzera", "Berna"], ["Croazia", "Zagabria"], ["Regno Unito", "Londra"], ["Repubblica Ceca", "Praga"],
			["Egitto", "Il Cairo"], ["Marocco", "Rabat"], ["Kenya", "Nairobi"], ["Giappone", "Tokyo"],
			["Cina", "Pechino"], ["India", "Nuova Delhi"], ["Brasile", "Brasilia"], ["Argentina", "Buenos Aires"],
			["Messico", "Città del Messico"], ["Canada", "Ottawa"], ["Australia", "Canberra"], ["Perù", "Lima"]]},
		{"topic": "continenti", "pairs": [["Egitto", "Africa"], ["Brasile", "America del Sud"], ["Giappone", "Asia"], ["Italia", "Europa"], ["Australia", "Oceania"]]},
		{"topic": "monumenti", "minLevel": 3, "pairs": [
			["Colosseo", "Italia"], ["Tour Eiffel", "Francia"], ["Piramidi di Giza", "Egitto"],
			["Statua della Libertà", "Stati Uniti"], ["Big Ben", "Regno Unito"], ["Sagrada Família", "Spagna"],
			["Partenone", "Grecia"], ["Muraglia cinese", "Cina"], ["Taj Mahal", "India"],
			["Cristo Redentore", "Brasile"], ["Machu Picchu", "Perù"], ["Monte Fuji", "Giappone"],
			["Opera House", "Australia"], ["Petra", "Giordania"], ["Stonehenge", "Inghilterra"],
			["Mulini di Kinderdijk", "Paesi Bassi"], ["Castello di Neuschwanstein", "Germania"], ["Cattedrale di San Basilio", "Russia"],
			["Chichén Itzá", "Messico"], ["Angkor Wat", "Cambogia"], ["Torre di Pisa", "Italia"],
			["Fiordi di Geiranger", "Norvegia"], ["Cascate Vittoria", "Zambia"], ["Colosso di Rodi (rovine)", "Grecia"]]},
		# Scuola media — monete del mondo ed elementi fisici d'Italia.
		{"topic": "monete", "minLevel": 5, "pairs": [["Italia", "Euro"], ["Stati Uniti", "Dollaro"], ["Giappone", "Yen"], ["Regno Unito", "Sterlina"]]},
		{"topic": "italia-fisica", "minLevel": 4, "pairs": [["Po", "Fiume"], ["Etna", "Vulcano"], ["Garda", "Lago"], ["Alpi", "Catena montuosa"]]},
	],
	"scienze": [
		{"topic": "corpo", "pairs": [["Cuore", "Pompa il sangue"], ["Polmoni", "Respirazione"], ["Cervello", "Comanda il corpo"], ["Stomaco", "Digestione"], ["Occhi", "Vista"]]},
		{"topic": "viventi", "pairs": [["Erbivoro", "Mangia piante"], ["Carnivoro", "Mangia animali"], ["Onnivoro", "Mangia tutto"], ["Decompositore", "Ricicla i resti"]]},
		{"topic": "classi", "minLevel": 5, "pairs": [["Rana", "Anfibio"], ["Serpente", "Rettile"], ["Aquila", "Uccello"], ["Balena", "Mammifero"], ["Trota", "Pesce"]]},
		# Scuola media — sistemi del corpo e passaggi di stato.
		{"topic": "sistemi", "minLevel": 6, "pairs": [["Cuore", "Sistema circolatorio"], ["Polmoni", "Sistema respiratorio"], ["Stomaco", "Sistema digerente"], ["Cervello", "Sistema nervoso"]]},
		{"topic": "passaggi-stato", "minLevel": 5, "pairs": [["Fusione", "solido → liquido"], ["Evaporazione", "liquido → gas"], ["Solidificazione", "liquido → solido"], ["Condensazione", "gas → liquido"]]},
	],
	"latino": [
		{"topic": "casi", "pairs": [["Nominativo", "Soggetto"], ["Accusativo", "Oggetto"], ["Genitivo", "Specificazione"], ["Dativo", "Termine"], ["Vocativo", "Invocazione"]]},
		{"topic": "vocabolario", "pairs": [
			["aqua", "acqua"], ["silva", "bosco"], ["puella", "fanciulla"], ["lupus", "lupo"],
			["terra", "terra"], ["stella", "stella"], ["luna", "luna"], ["sol", "sole"],
			["mare", "mare"], ["flumen", "fiume"], ["arbor", "albero"], ["ventus", "vento"],
			["mons", "monte"], ["campus", "campo"], ["rex", "re"], ["regina", "regina"],
			["miles", "soldato"], ["nauta", "marinaio"], ["agricola", "contadino"], ["magister", "maestro"],
			["puer", "fanciullo"], ["equus", "cavallo"], ["canis", "cane"], ["avis", "uccello"],
			["piscis", "pesce"], ["aquila", "aquila"], ["templum", "tempio"], ["bellum", "guerra"],
			["donum", "dono"], ["liber", "libro"], ["porta", "porta"], ["hortus", "giardino"]]},
		# Le radici latine vive nell'italiano: aggancio culturale forte.
		{"topic": "etimologia", "minLevel": 4, "pairs": [
			["aqua", "acquedotto"], ["terra", "territorio"], ["liber", "libreria"], ["schola", "scuola"],
			["bellum", "bellicoso"], ["navis", "navigare"], ["manus", "manuale"], ["pes", "pedone"],
			["oculus", "oculista"], ["dens", "dentista"], ["cor", "cordiale"], ["caput", "capitale"],
			["ignis", "ignifugo"], ["lux", "lucido"], ["nox", "notturno"], ["annus", "annuale"],
			["dies", "diario"], ["via", "viadotto"], ["urbs", "urbano"], ["ager", "agricoltura"],
			["populus", "popolare"], ["civis", "civile"], ["vox", "vocale"], ["tempus", "temporale"]]},
		{"topic": "verbo-sum", "minLevel": 5, "pairs": [["sum", "io sono"], ["es", "tu sei"], ["est", "egli è"], ["sumus", "noi siamo"]]},
		# Scuola media — la prima declinazione (rosa): desinenza -> caso.
		{"topic": "declinazioni-base", "minLevel": 6, "pairs": [["rosa", "Nominativo"], ["rosam", "Accusativo"], ["rosae", "Genitivo"], ["rosā", "Ablativo"]]},
	],
	"musica": [
		# Al primo mondo musica aveva otto abbinamenti possibili in tutto: due
		# specifiche da quattro coppie. Era la materia con la ripetizione peggiore
		# rimasta, e la cura non è pescare meno ma avere più materiale con risposte
		# uniche — durata in battiti, nome internazionale, modo di produrre il suono.
		{"topic": "ritmo", "pairs": [
			["Breve", "8 battiti"], ["Semibreve", "4 battiti"], ["Minima puntata", "3 battiti"],
			["Minima", "2 battiti"], ["Semiminima puntata", "1 battito e mezzo"], ["Semiminima", "1 battito"],
			["Croma puntata", "tre quarti di battito"], ["Croma", "mezzo battito"],
			["Semicroma", "un quarto di battito"], ["Biscroma", "un ottavo di battito"]]},
		# I nomi internazionali delle note: si trovano su ogni spartito e su ogni
		# accordo di chitarra, quindi non è nozionismo ma alfabeto pratico.
		{"topic": "note", "pairs": [
			["Do", "C"], ["Re", "D"], ["Mi", "E"], ["Fa", "F"],
			["Sol", "G"], ["La", "A"], ["Si", "B"]]},
		{"topic": "strumenti", "pairs": [
			["Chitarra", "corde pizzicate con le dita"], ["Violino", "corde sfregate con l'archetto"],
			["Pianoforte", "corde percosse da martelletti"], ["Flauto", "aria soffiata in un tubo"],
			["Tromba", "labbra che vibrano nel bocchino"], ["Tamburo", "pelle tesa percossa"],
			["Xilofono", "lamine di legno percosse"], ["Arpa", "corde pizzicate a mano libera"],
			["Organo a canne", "aria spinta dentro le canne"], ["Fisarmonica", "ance mosse dal mantice"],
			["Maracas", "semi che sbattono dentro il guscio"], ["Triangolo", "barra di metallo percossa"]]},
		{"topic": "dinamica", "minLevel": 3, "pairs": [["forte (f)", "suonare forte"], ["piano (p)", "suonare piano"], ["crescendo", "aumentare a poco a poco"], ["staccato", "note staccate e brevi"]]},
		# Termini italiani di tempo (usati in tutto il mondo).
		{"topic": "tempo", "minLevel": 4, "pairs": [["Adagio", "lento"], ["Andante", "camminando, moderato"], ["Allegro", "veloce e vivace"], ["Presto", "molto veloce"]]},
		# Scuola media — compositori e opere celebri.
		{"topic": "compositori", "minLevel": 6, "pairs": [["Beethoven", "Quinta Sinfonia"], ["Vivaldi", "Le Quattro Stagioni"], ["Mozart", "Il Flauto Magico"], ["Verdi", "Aida"]]},
	],
	"italiano": [
		# --- Insiemi profondi (Fase 1) ---------------------------------------------
		# L'abbinamento regge un insieme profondo solo quando OGNI voce ha una
		# risposta sua: contrari, sinonimi, definizioni, modi di dire. I contenuti
		# «a categoria» (classe grammaticale, tempo verbale) non possono crescere
		# qui — con quattro risposte per venti voci l'abbinamento sarebbe ambiguo:
		# quelli stanno nello smistamento, che è fatto apposta.
		{"topic": "contrari", "pairs": [
			["alto", "basso"], ["grande", "piccolo"], ["giorno", "notte"], ["caldo", "freddo"],
			["veloce", "lento"], ["pieno", "vuoto"], ["aperto", "chiuso"], ["ricco", "povero"],
			["pulito", "sporco"], ["forte", "debole"], ["chiaro", "scuro"], ["dolce", "amaro"],
			["duro", "morbido"], ["largo", "stretto"], ["lungo", "corto"], ["pesante", "leggero"],
			["vicino", "lontano"], ["salire", "scendere"], ["entrare", "uscire"], ["ridere", "piangere"],
			["iniziare", "finire"], ["vincere", "perdere"], ["dare", "ricevere"], ["sopra", "sotto"],
			["davanti", "dietro"], ["dentro", "fuori"], ["prima", "dopo"], ["sempre", "mai"],
			["giovane", "vecchio"], ["asciutto", "bagnato"], ["liscio", "ruvido"], ["utile", "inutile"]]},
		{"topic": "categorie", "pairs": [["correre", "verbo"], ["gatto", "nome"], ["rosso", "aggettivo"], ["velocemente", "avverbio"]]},
		{"topic": "sinonimi", "pairs": [
			["felice", "contento"], ["veloce", "rapido"], ["bello", "stupendo"], ["triste", "malinconico"],
			["furbo", "astuto"], ["grande", "enorme"], ["minuto", "minuscolo"], ["difficile", "arduo"],
			["facile", "semplice"], ["silenzioso", "quieto"], ["coraggioso", "valoroso"], ["stanco", "spossato"],
			["arrabbiato", "furioso"], ["buffo", "comico"], ["strano", "bizzarro"], ["sudicio", "lurido"],
			["agiato", "benestante"], ["anziano", "attempato"], ["iniziare", "cominciare"], ["terminare", "concludere"],
			["guardare", "osservare"], ["parlare", "conversare"], ["camminare", "passeggiare"], ["capire", "comprendere"],
			["sbagliare", "errare"], ["aiutare", "soccorrere"], ["nascondere", "celare"], ["scoprire", "svelare"],
			["urlare", "gridare"], ["saltare", "balzare"]]},
		{"topic": "definizioni", "minLevel": 7, "pairs": [
			["effimero", "che dura pochissimo"], ["arduo", "molto difficile"], ["placido", "calmo e tranquillo"],
			["arguto", "acuto e spiritoso"], ["tenace", "che non si arrende"], ["esiguo", "molto scarso"],
			["mendace", "che dice il falso"], ["magnanimo", "generoso e nobile d'animo"], ["ostinato", "che non cambia idea"],
			["sagace", "che capisce in fretta"], ["taciturno", "che parla poco"], ["ameno", "piacevole e gradevole"],
			["insolito", "fuori dal comune"], ["meticoloso", "attento a ogni dettaglio"], ["irruento", "impetuoso e scomposto"],
			["frugale", "sobrio, senza sprechi"], ["arcano", "misterioso e oscuro"], ["ligio", "fedele alle regole"],
			["prolisso", "che si dilunga troppo"], ["temerario", "audace fino all'imprudenza"], ["candido", "innocente e sincero"],
			["arcigno", "dall'aria severa e scontrosa"], ["solerte", "svelto e diligente"], ["vetusto", "molto antico"],
			["mite", "dolce e non violento"], ["astruso", "difficile da capire"]]},
		{"topic": "modi-di-dire", "minLevel": 6, "pairs": [
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
		{"topic": "figure-retoriche", "minLevel": 8, "pairs": [
			["Veloce come il vento", "Similitudine"], ["Il sole sorride nel cielo", "Personificazione"],
			["Ho un mare di compiti", "Iperbole"], ["Che silenzio assordante", "Ossimoro"],
			["Sei un leone in campo", "Metafora"], ["Il tic tac dell'orologio", "Onomatopea"],
			["Fischia il fiato fra le foglie", "Allitterazione"], ["Non è per niente stupido", "Litote"],
			["Non temo, non tremo, non cedo", "Anafora"], ["Bianco di neve, nero di pece", "Antitesi"],
			["Non è forte: è fortissimo, è invincibile", "Climax"], ["Le vele lasciarono il porto", "Sineddoche"]]},
		# Scuola media — analisi grammaticale: ogni parola alla sua parte del discorso.
		{"topic": "analisi-grammaticale", "minLevel": 8, "pairs": [["il", "articolo"], ["gatto", "nome"], ["dorme", "verbo"], ["pigro", "aggettivo"], ["sotto", "preposizione"]]},
		# Scuola media — modi e tempi del verbo (terminologia esplicita).
		{"topic": "modi-verbali", "minLevel": 9, "pairs": [["io leggo", "indicativo"], ["che io legga", "congiuntivo"], ["io leggerei", "condizionale"], ["leggi!", "imperativo"]]},
		{"topic": "tempi-indicativo", "minLevel": 9, "pairs": [["ho letto", "passato prossimo"], ["leggevo", "imperfetto"], ["leggerò", "futuro semplice"], ["lessi", "passato remoto"]]},
		{"topic": "modi-indefiniti", "minLevel": 10, "pairs": [["leggere", "infinito"], ["leggendo", "gerundio"], ["letto", "participio"]]},
		# Scuola media — analisi logica: ogni sintagma alla sua funzione.
		# Frase: "Il gatto insegue il topo nel prato".
		{"topic": "analisi-logica", "minLevel": 11, "pairs": [["Il gatto", "soggetto"], ["insegue", "predicato verbale"], ["il topo", "complemento oggetto"], ["nel prato", "complemento di luogo"]]},
	],
	"storia": [
		{"topic": "civilta", "pairs": [["Egizi", "Nilo"], ["Romani", "Roma"], ["Greci", "Grecia"], ["Sumeri", "Mesopotamia"]]},
		{"topic": "invenzioni", "minLevel": 4, "pairs": [["Egizi", "Piramidi"], ["Romani", "Acquedotti"], ["Greci", "Democrazia"], ["Fenici", "Alfabeto"]]},
		# Scuola media — personaggi e le loro imprese. Ogni personaggio ha una sola
		# impresa e ogni impresa un solo personaggio: è la condizione che permette a
		# un abbinamento di diventare profondo senza diventare ambiguo.
		{"topic": "personaggi", "minLevel": 18, "pairs": [
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
		{"topic": "cronologia", "minLevel": 5, "pairs": [
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
		{"topic": "civilta", "minLevel": 6, "pairs": [["Colosseo", "Romani"], ["Partenone", "Greci"], ["Piramidi", "Egizi"], ["Ziggurat", "Sumeri"]]},
	],
	"coding": [
		{"topic": "tipi", "pairs": [["7", "intero"], ["'ciao'", "stringa"], ["True", "booleano"], ["[1, 2, 3]", "lista"]]},
		{"topic": "operatori", "pairs": [["+", "somma"], ["*", "moltiplicazione"], ["%", "resto"], ["**", "potenza"]]},
		{"topic": "concetti", "minLevel": 3, "pairs": [["variabile", "contenitore di un valore"], ["ciclo", "ripete istruzioni"], ["funzione", "blocco riutilizzabile"], ["condizione", "sceglie un percorso"]]},
		{"topic": "simboli", "minLevel": 4, "pairs": [["==", "uguale a"], ["!=", "diverso da"], [">=", "maggiore o uguale"], ["=", "assegnazione"]]},
		# Prevedi l'output: leggere il codice come lo legge il computer.
		{"topic": "output", "minLevel": 5, "pairs": [["print(2 + 3)", "5"], ["print('ab' * 2)", "abab"], ["print(10 // 3)", "3"], ["len('ciao')", "4"]]},
		# Scuola media — numeri binari (fondamenti dell'informatica). Prefisso 0b
		# come in Python: chiarisce che è binario e insegna il letterale reale.
		{"topic": "binario", "minLevel": 7, "pairs": [["0b10", "2"], ["0b11", "3"], ["0b100", "4"], ["0b101", "5"], ["0b1000", "8"]]},
	],
	"elettronica": [
		{"topic": "componenti", "pairs": [["Pila", "Fornisce energia"], ["Interruttore", "Apre e chiude"], ["Resistore", "Limita la corrente"], ["LED", "Emette luce"]]},
		{"topic": "misure-elettriche", "pairs": [["Tensione", "Volt"], ["Corrente", "Ampere"], ["Resistenza", "Ohm"]]},
		{"topic": "grandezze", "minLevel": 3, "pairs": [["Potenza", "Watt"], ["Energia", "Joule"], ["Frequenza", "Hertz"]]},
		# Scuola media — legge di Ohm e prefissi delle unità.
		{"topic": "legge-ohm", "minLevel": 6, "pairs": [["Tensione (V)", "R × I"], ["Corrente (I)", "V / R"], ["Resistenza (R)", "V / I"]]},
		{"topic": "prefissi", "minLevel": 7, "pairs": [["1000 Ω", "1 kΩ"], ["1000 mA", "1 A"], ["1000 mV", "1 V"]]},
	],
	"fisica": [
		{"topic": "misure", "pairs": [["Lunghezza", "Metro"], ["Massa", "Chilogrammo"], ["Tempo", "Secondo"], ["Temperatura", "Grado"]]},
		{"topic": "energia", "pairs": [["Palla in alto", "Energia potenziale"], ["Palla che cade", "Energia cinetica"], ["Cibo", "Energia chimica"], ["Lampadina accesa", "Energia luminosa"]]},
		{"topic": "strumenti", "minLevel": 3, "pairs": [["Righello", "lunghezza"], ["Bilancia", "massa"], ["Cronometro", "tempo"], ["Termometro", "temperatura"]]},
		{"topic": "forze", "minLevel": 4, "pairs": [["Attrito", "Rallenta il moto"], ["Gravità", "Attira verso il basso"], ["Spinta", "Mette in moto"], ["Magnetismo", "Attira il ferro"]]},
		# Scuola media — macchine semplici e formule.
		{"topic": "macchine", "minLevel": 6, "pairs": [["Leva", "Solleva con meno forza"], ["Carrucola", "Cambia direzione alla forza"], ["Piano inclinato", "Riduce lo sforzo in salita"], ["Ruota", "Riduce l'attrito"]]},
		{"topic": "formule", "minLevel": 7, "pairs": [["Velocità", "spazio / tempo"], ["Densità", "massa / volume"], ["Forza peso", "massa × gravità"]]},
	],
	"matematica": [
		# Prodotti tutti DIVERSI dentro l'insieme: due voci con lo stesso risultato
		# renderebbero l'abbinamento ambiguo appena capitassero insieme.
		{"topic": "tabelline", "pairs": [
			["3 × 4", "12"], ["6 × 7", "42"], ["8 × 5", "40"], ["9 × 3", "27"],
			["7 × 8", "56"], ["6 × 9", "54"], ["4 × 7", "28"], ["8 × 8", "64"],
			["9 × 7", "63"], ["6 × 6", "36"], ["8 × 9", "72"], ["4 × 6", "24"],
			["7 × 5", "35"], ["9 × 9", "81"], ["8 × 6", "48"], ["3 × 7", "21"],
			["5 × 9", "45"], ["4 × 8", "32"], ["7 × 7", "49"], ["6 × 5", "30"],
			["11 × 4", "44"], ["12 × 3", "33"], ["11 × 6", "66"], ["11 × 7", "77"],
			["4 × 4", "16"], ["9 × 2", "18"], ["7 × 2", "14"], ["12 × 5", "60"],
			["11 × 9", "99"], ["12 × 7", "84"], ["11 × 8", "88"], ["12 × 9", "108"]]},
		{"topic": "calcolo", "pairs": [
			["10 + 5", "15"], ["20 - 8", "12"], ["18 ÷ 3", "6"], ["7 + 6", "13"],
			["25 + 17", "42"], ["63 - 28", "35"], ["196 ÷ 14", "14"], ["17 × 3", "51"],
			["350 ÷ 7", "50"], ["45 + 38", "83"], ["100 - 47", "53"], ["23 × 4", "92"],
			["120 ÷ 5", "24"], ["56 + 29", "85"], ["81 - 36", "45"], ["19 × 5", "95"],
			["150 ÷ 6", "25"], ["74 + 48", "122"], ["200 - 133", "67"], ["16 × 7", "112"],
			["480 ÷ 12", "40"], ["87 + 96", "183"], ["310 - 145", "165"], ["24 × 6", "144"],
			["729 ÷ 9", "81"], ["108 + 97", "205"], ["500 - 264", "236"], ["32 × 8", "256"],
			["441 ÷ 21", "21"], ["76 + 88", "164"], ["1000 - 375", "625"], ["45 × 12", "540"]]},
		# Fluenza tra rappresentazioni: la stessa quantità in forme diverse (idea CPA).
		{"topic": "frazioni", "minLevel": 4, "pairs": [
			["1/2", "0,5"], ["1/4", "0,25"], ["3/4", "0,75"], ["1/5", "0,2"],
			["1/10", "0,1"], ["3/10", "0,3"], ["7/10", "0,7"], ["1/8", "0,125"],
			["3/8", "0,375"], ["5/8", "0,625"], ["1/20", "0,05"], ["3/5", "0,6"],
			["2/5", "0,4"], ["4/5", "0,8"], ["1/100", "0,01"], ["9/10", "0,9"],
			["7/8", "0,875"], ["1/25", "0,04"], ["11/10", "1,1"], ["5/2", "2,5"]]},
		{"topic": "percentuali", "minLevel": 5, "pairs": [
			["1/2", "50%"], ["1/4", "25%"], ["1/5", "20%"], ["3/4", "75%"],
			["1/10", "10%"], ["3/10", "30%"], ["7/10", "70%"], ["9/10", "90%"],
			["2/5", "40%"], ["3/5", "60%"], ["4/5", "80%"], ["1/20", "5%"],
			["1/100", "1%"], ["1/1", "100%"], ["1/8", "12,5%"], ["3/8", "37,5%"]]},
		# Scuola media — potenze e formule di geometria.
		{"topic": "potenze", "minLevel": 6, "pairs": [
			["2³", "8"], ["3²", "9"], ["5²", "25"], ["10³", "1000"],
			["2⁴", "16"], ["2⁵", "32"], ["3³", "27"], ["4³", "64"],
			["6²", "36"], ["7²", "49"], ["2⁷", "128"], ["9²", "81"],
			["11²", "121"], ["12²", "144"], ["10²", "100"], ["10⁴", "10000"],
			["5³", "125"], ["4⁴", "256"], ["6³", "216"], ["1⁹", "1"]]},
		{"topic": "geometria", "minLevel": 5, "pairs": [["Area del quadrato", "lato × lato"], ["Perimetro del rettangolo", "(base + altezza) × 2"], ["Area del triangolo", "base × altezza ÷ 2"], ["Area del cerchio", "π × raggio²"]]},
	],
	"logica": [
		# Ogni insieme è UNA relazione sola, dichiarata nel commento: è questo che lo
		# rende un esercizio di logica invece che di vocabolario. Mescolare relazioni
		# diverse nello stesso insieme renderebbe l'abbinamento indovinabile per
		# associazione, che è il contrario di quello che la materia allena.
		# Relazione: «chi ci abita».
		{"topic": "analogie", "pairs": [
			["Cane", "Cuccia"], ["Uccello", "Nido"], ["Ape", "Alveare"], ["Pesce", "Acquario"],
			["Cavallo", "Stalla"], ["Topo", "Tana"], ["Formica", "Formicaio"], ["Ragno", "Ragnatela"],
			["Coniglio", "Conigliera"], ["Maiale", "Porcile"], ["Aquila", "Nido d'aquila"], ["Castoro", "Diga"],
			["Volpe", "Tana scavata"], ["Gallina", "Pollaio"], ["Pecora", "Ovile"], ["Orso", "Caverna"],
			["Talpa", "Galleria"], ["Lumaca", "Guscio"], ["Termite", "Termitaio"], ["Marmotta", "Cunicolo"]]},
		# Relazione: «a che cosa serve».
		{"topic": "analogie", "minLevel": 3, "pairs": [
			["Penna", "Scrivere"], ["Forbici", "Tagliare"], ["Martello", "Battere"], ["Chiave", "Aprire"],
			["Scopa", "Spazzare"], ["Ago", "Cucire"], ["Pettine", "Pettinare"], ["Termometro", "Misurare la febbre"],
			["Bussola", "Orientarsi"], ["Ombrello", "Ripararsi dalla pioggia"], ["Bilancia", "Pesare"], ["Telescopio", "Osservare lontano"],
			["Lente", "Ingrandire"], ["Remo", "Spingere la barca"], ["Sega", "Segare"], ["Freno", "Fermare"],
			["Setaccio", "Separare"], ["Imbuto", "Travasare"], ["Livella", "Verificare l'orizzontale"], ["Pinza", "Afferrare"]]},
		{"topic": "categorie", "minLevel": 4, "pairs": [["Rosa", "Fiore"], ["Cane", "Animale"], ["Mela", "Frutto"], ["Tavolo", "Mobile"]]},
		# Relazione: «parte di».
		{"topic": "analogie", "minLevel": 4, "pairs": [
			["Ruota", "Automobile"], ["Foglia", "Albero"], ["Pagina", "Libro"], ["Dito", "Mano"],
			["Tasto", "Pianoforte"], ["Petalo", "Fiore"], ["Corda", "Chitarra"], ["Gradino", "Scala"],
			["Ala", "Uccello"], ["Radice", "Pianta"], ["Nota", "Melodia"], ["Mattone", "Muro"],
			["Stanza", "Casa"], ["Capitolo", "Romanzo"], ["Isola", "Arcipelago"], ["Vagone", "Treno"],
			["Lettera", "Parola"], ["Cellula", "Tessuto"], ["Fotogramma", "Film"], ["Stella", "Costellazione"]]},
		# Relazione: «il contrario di».
		{"topic": "opposti", "minLevel": 5, "pairs": [
			["Giorno", "Notte"], ["Salita", "Discesa"], ["Pieno", "Vuoto"], ["Inizio", "Fine"],
			["Vittoria", "Sconfitta"], ["Silenzio", "Rumore"], ["Ordine", "Disordine"], ["Verità", "Menzogna"],
			["Domanda", "Risposta"], ["Entrata", "Uscita"], ["Ricordo", "Oblio"], ["Guerra", "Pace"],
			["Partenza", "Arrivo"], ["Luce", "Buio"], ["Coraggio", "Paura"], ["Successo", "Fallimento"],
			["Presenza", "Assenza"], ["Movimento", "Quiete"], ["Nascita", "Morte"], ["Certezza", "Dubbio"]]},
	],
}

# Sequenze da ordinare, per materia (l'ordine dato è quello CORRETTO).
const ORDERING := {
	"scienze": [
		{"topic": "viventi", "prompt": "Metti in ordine le fasi della farfalla", "correctOrder": ["Uovo", "Bruco", "Crisalide", "Farfalla"]},
		{"topic": "materia", "prompt": "Ordina per temperatura crescente", "correctOrder": ["Ghiaccio", "Acqua fredda", "Acqua calda", "Vapore"]},
		{"topic": "ciclo-acqua", "minLevel": 3, "prompt": "Ordina le fasi del ciclo dell'acqua.", "correctOrder": ["Evaporazione", "Condensazione", "Precipitazione", "Raccolta nei fiumi"]},
		{"topic": "catena", "minLevel": 4, "prompt": "Ordina la catena alimentare, da chi produce energia a chi la mangia.", "correctOrder": ["Erba", "Cavalletta", "Rana", "Serpente", "Aquila"]},
		{"topic": "metodo", "minLevel": 4, "prompt": "Ordina i passi del metodo scientifico.", "correctOrder": ["Fai una domanda", "Formula un'ipotesi", "Fai l'esperimento", "Osserva i risultati", "Trai la conclusione"]},
		# Scuola media — livelli di organizzazione dei viventi.
		{"topic": "organizzazione", "minLevel": 7, "prompt": "Ordina dal più piccolo al più grande.", "correctOrder": ["Cellula", "Tessuto", "Organo", "Sistema", "Organismo"]},
		# Insieme a estrazione sulle dimensioni reali dei viventi (`value` in metri).
		# Ordinare esseri viventi per grandezza è biologia, non aritmetica: costringe
		# a farsi un'idea di scala, che è ciò che i numeri da soli non insegnano.
		{"topic": "organizzazione", "minLevel": 7, "kind": "pool", "draw": 4, "prompt": "Ordina questi viventi dal più piccolo al più grande.", "pool": [
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
	],
	"geografia": [
		{"topic": "geografia-umana", "prompt": "Ordina dal più piccolo al più grande", "correctOrder": ["Paese", "Regione", "Nazione", "Continente"]},
		{"topic": "geografia-fisica", "minLevel": 3, "prompt": "Ordina il corso di un fiume, dalla nascita al mare.", "correctOrder": ["Sorgente", "Torrente", "Fiume", "Foce"]},
		{"topic": "geografia-umana", "minLevel": 4, "prompt": "Ordina dal più piccolo al più grande.", "correctOrder": ["Via", "Quartiere", "Città", "Regione"]},
		# Insiemi a estrazione: in geografia quasi ogni ordine è una GRANDEZZA —
		# altezza in metri, lunghezza in chilometri, abitanti. È lo stesso motivo per
		# cui la cronologia funziona in storia: c'è un numero vero sotto l'etichetta.
		{"topic": "italia-fisica", "minLevel": 6, "kind": "pool", "draw": 4, "prompt": "Ordina le cime per altezza crescente (in metri).", "pool": [
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
		{"topic": "geografia-fisica", "minLevel": 5, "kind": "pool", "draw": 4, "prompt": "Ordina i fiumi per lunghezza crescente (in chilometri).", "pool": [
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
	],
	"musica": [
		{"topic": "note", "prompt": "Metti in ordine le note dopo il Do", "correctOrder": ["Re", "Mi", "Fa", "Sol"]},
		{"topic": "ritmo", "prompt": "Ordina dalla durata più breve alla più lunga", "correctOrder": ["Croma", "Semiminima", "Minima", "Semibreve"]},
		{"topic": "note", "minLevel": 3, "prompt": "Ordina la scala musicale completa, dal Do.", "correctOrder": ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]},
		# Scuola media — dinamiche dal più piano al più forte, tempi dal più lento.
		{"topic": "dinamica", "minLevel": 5, "prompt": "Ordina le dinamiche dal più piano al più forte.", "correctOrder": ["pianissimo", "piano", "mezzoforte", "forte", "fortissimo"]},
		# I termini italiani di tempo hanno un valore vero: i battiti al minuto. Sono
		# la stessa scala che il metronomo mostra, quindi ordinarli è leggere una
		# grandezza, non ricordare un elenco.
		{"topic": "tempo", "minLevel": 5, "kind": "pool", "draw": 4, "prompt": "Ordina i tempi dal più lento al più veloce.", "pool": [
			{"label": "Grave", "value": 40.0}, {"label": "Largo", "value": 50.0},
			{"label": "Lento", "value": 55.0}, {"label": "Adagio", "value": 66.0},
			{"label": "Larghetto", "value": 63.0}, {"label": "Andante", "value": 80.0},
			{"label": "Andantino", "value": 88.0}, {"label": "Moderato", "value": 100.0},
			{"label": "Allegretto", "value": 112.0}, {"label": "Allegro", "value": 130.0},
			{"label": "Vivace", "value": 150.0}, {"label": "Presto", "value": 175.0},
			{"label": "Prestissimo", "value": 200.0}, {"label": "Adagietto", "value": 72.0},
			{"label": "Allegro molto", "value": 140.0}, {"label": "Largamente", "value": 46.0}]},
	],
	"italiano": [
		# Insieme a estrazione: si pescano 4 parole fra trentadue e si ordinano per
		# `value`, che è il posto della parola nel dizionario. Trentadue parole
		# danno C(32,4) = 35.960 prove diverse da una sola specifica — ed è il
		# motivo per cui i valori sono scritti a mano invece che calcolati: qui
		# l'ordine alfabetico è il CONTENUTO della prova, quindi va autorato e
		# controllato, non dedotto a runtime da una funzione di confronto.
		{"topic": "ortografia", "kind": "pool", "draw": 4, "prompt": "Metti le parole in ordine alfabetico.", "pool": [
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
		{"topic": "sintassi", "prompt": "Riordina le parole per formare una frase corretta.", "correctOrder": ["Il", "gatto", "dorme", "sul", "divano"]},
		{"topic": "sintassi", "prompt": "Riordina le parole per formare una frase corretta.", "correctOrder": ["Domani", "andremo", "tutti", "al", "mare"]},
		{"topic": "testo-narrativo", "prompt": "Metti in ordine gli eventi della storia.", "correctOrder": ["C'era una volta un re", "Il re partì per un lungo viaggio", "Incontrò un drago feroce", "Con astuzia lo sconfisse", "Tornò a casa vittorioso"]},
	],
	"coding": [
		{"topic": "algoritmi", "prompt": "Ordina i passi del programma", "correctOrder": ["Chiedi il numero", "Controlla se è pari", "Se è pari stampa 'pari'", "Altrimenti stampa 'dispari'"]},
		# Pensiero computazionale "unplugged": la vita quotidiana come algoritmo.
		{"topic": "algoritmi", "minLevel": 2, "prompt": "Ordina i passi dell'algoritmo per fare un tè.", "correctOrder": ["Scalda l'acqua", "Metti la bustina nella tazza", "Versa l'acqua calda", "Aspetta due minuti", "Togli la bustina"]},
		{"topic": "algoritmi", "minLevel": 5, "prompt": "Ordina i passi per trovare il numero più grande in una lista.", "correctOrder": ["Prendi il primo numero come massimo", "Guarda il numero successivo", "Se è più grande, aggiorna il massimo", "Ripeti fino alla fine", "Restituisci il massimo"]},
	],
	"storia": [
		{"topic": "ere", "prompt": "Ordina le grandi età della storia, dalla più antica.", "correctOrder": ["Preistoria", "Età antica", "Medioevo", "Età moderna", "Età contemporanea"]},
		# Insieme cronologico PER I PRIMI MONDI. L'insieme grande (28 eventi, più
		# sotto) parte dal mondo 6 perché contiene date che a dieci anni non si
		# possono conoscere: pescandone tre a caso poteva uscire «Hammurabi, prima
		# crociata, peste nera», che non è una prova difficile ma una prova
		# impossibile. Qui gli eventi sono pochi, notissimi e molto distanti fra
		# loro: l'ordine si ricava dal senso storico, non dalla memoria delle date.
		{"topic": "cronologia", "kind": "pool", "draw": 3,
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
		{"topic": "preistoria", "minLevel": 4, "prompt": "Ordina i periodi della preistoria, dal più antico.", "correctOrder": ["Paleolitico", "Neolitico", "Età dei metalli"]},
		{"topic": "roma", "minLevel": 18, "prompt": "Ordina le fasi della storia di Roma.", "correctOrder": ["Monarchia", "Repubblica", "Impero"]},
		# Scuola media — ordinare eventi lontani per data.
		#
		# Il caso in cui l'ordinamento si parametrizza meglio di ogni altro: l'ordine
		# giusto NON è una convenzione da ricordare, è una proprietà misurabile
		# (l'anno). Ventotto eventi danno C(28,4) = 20.475 prove diverse, e ogni
		# estrazione è una domanda storica sensata perché la linea del tempo è una
		# sola. `value` è l'anno con segno: negativo prima di Cristo.
		{"topic": "cronologia", "minLevel": 6, "kind": "pool", "draw": 4,
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
	],
	"latino": [
		{"topic": "frasi", "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «la fanciulla ama la rosa»", "correctOrder": ["Puella", "rosam", "amat"]},
		{"topic": "frasi", "minLevel": 4, "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «il poeta ama la patria»", "correctOrder": ["Poeta", "patriam", "amat"]},
		# Scuola media — l'ordine tradizionale dei casi (come sul libro).
		{"topic": "casi", "minLevel": 5, "prompt": "Ordina i casi latini nell'ordine tradizionale.", "correctOrder": ["Nominativo", "Genitivo", "Dativo", "Accusativo", "Vocativo", "Ablativo"]},
	],
	"inglese": [
		{"topic": "everyday-phrases", "prompt": "Order the words to make a sentence", "correctOrder": ["I", "like", "green", "apples"]},
		# Insieme a estrazione: i numeri scritti a parole, ordinati per valore.
		# Ventiquattro voci → C(24,4) = 10.626 prove. Il riordino di una frase non
		# si può parametrizzare (l'ordine è quello di QUELLA frase); i numeri sì, e
		# sono contenuto d'inglese vero quanto il word order.
		{"topic": "vocabolario", "kind": "pool", "draw": 4, "prompt": "Order the numbers from the smallest to the largest.", "pool": [
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
		{"topic": "sentence", "minLevel": 3, "prompt": "Order the words to make a sentence.", "correctOrder": ["She", "reads", "a", "book"]},
		{"topic": "negative", "minLevel": 5, "prompt": "Order the words to make a negative sentence.", "correctOrder": ["He", "does", "not", "play"]},
		# Domande: inversione dell'ausiliare (diverso dall'italiano).
		{"topic": "question", "minLevel": 5, "prompt": "Order the words to make a question.", "correctOrder": ["Do", "you", "like", "pizza?"]},
		{"topic": "wh-question", "minLevel": 6, "prompt": "Order the words to make a question.", "correctOrder": ["Where", "do", "you", "live?"]},
	],
	"fisica": [
		# Insiemi a estrazione: in fisica l'ordine NON è una convenzione da ricordare,
		# è una grandezza. `value` è la grandezza vera (km/h, kg), quindi ogni
		# estrazione è una domanda sensata e la risposta è verificabile.
		{"topic": "moto", "kind": "pool", "draw": 4, "prompt": "Ordina per velocità crescente.", "pool": [
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
		{"topic": "misure", "minLevel": 3, "kind": "pool", "draw": 4, "prompt": "Ordina gli oggetti per massa crescente.", "pool": [
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
		{"topic": "materia", "minLevel": 5, "prompt": "Ordina gli stati per energia delle particelle, dal minore al maggiore.", "correctOrder": ["Solido", "Liquido", "Gassoso"]},
	],
	"elettronica": [
		# Tensioni reali, dalla pila a bottone alla linea ad alta tensione: qui il
		# valore da ordinare è scritto sull'etichetta, quindi l'esercizio allena a
		# leggere gli ordini di grandezza (mV, V, kV) invece di ricordare una lista.
		{"topic": "misure-elettriche", "kind": "pool", "draw": 4, "prompt": "Ordina le tensioni dalla più piccola alla più grande.", "pool": [
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
		{"topic": "montaggio", "minLevel": 3, "prompt": "Ordina i passi per costruire un circuito che accende un LED.", "correctOrder": ["Prendi la pila", "Collega il filo al polo +", "Aggiungi l'interruttore", "Collega il LED", "Chiudi il circuito al polo -"]},
		{"topic": "misure-elettriche", "minLevel": 5, "prompt": "Ordina le resistenze dalla più piccola.", "correctOrder": ["10 Ω", "100 Ω", "1 kΩ", "10 kΩ"]},
	],
	# Logica (mondi 12 e 24). Prima di queste specifiche la logica riceveva
	# l'ordinamento procedurale di numeri nudi, che dichiarava `topic: "sequenze"`
	# senza avere nessuna regola da scoprire: sequenza è "trova la regola che
	# genera i termini", non "ordina tre interi". Qui l'ordine È il ragionamento.
	"logica": [
		{"topic": "sequenze", "prompt": "Ordina i passi per scoprire la regola di una sequenza.", "correctOrder": ["Confronta due termini vicini", "Di' a parole che cosa cambia", "Verifica la regola su un altro termine", "Applica la regola al termine dopo"]},
		{"topic": "deduzioni", "prompt": "Ordina la deduzione: prima le premesse, poi la conclusione.", "correctOrder": ["Tutti i pianeti girano attorno a una stella", "La Terra è un pianeta", "Allora la Terra gira attorno a una stella"]},
		{"topic": "analogie", "prompt": "Ordina i passi per risolvere un'analogia.", "correctOrder": ["Guarda la prima coppia", "Di' a parole come sono legate", "Cerca lo stesso legame nella seconda coppia", "Scegli la parola che lo completa"]},
		# Una sequenza che NON si risolve ordinando per grandezza: la regola
		# alterna ×2 e −1, quindi i termini salgono e scendono. È la prova che
		# distingue "so applicare una regola" da "so confrontare due numeri".
		{"topic": "sequenze", "minLevel": 18, "prompt": "La regola è: ×2, poi −1, poi ×2, poi −1. Rimetti i termini nell'ordine giusto partendo da 3.", "correctOrder": ["3", "6", "5", "10", "9"]},
		{"topic": "deduzioni", "minLevel": 20, "prompt": "Ordina i passi per risolvere un indovinello a eliminazione.", "correctOrder": ["Elenca tutti i casi possibili", "Applica il primo indizio e scarta", "Applica il secondo indizio e scarta", "Controlla che resti un solo caso", "Scrivi la conclusione"]},
		{"topic": "analogie", "minLevel": 20, "prompt": "Ordina le relazioni dalla più stretta alla più ampia.", "correctOrder": ["Cucciolo : cane", "Cane : mammifero", "Mammifero : animale", "Animale : vivente"]},
	],
}

# Smistamento in categorie (drag-to-sort), per materia. Ogni item ha UNA categoria
# corretta (`assignments`); il renderer classification li fa trascinare nei bidoni.
# Formato testuale ad alto coinvolgimento, senza asset (playthrough #11).
const CLASSIFICATION := {
	"italiano": [
		# --- Insiemi profondi (Fase 1) ---------------------------------------------
		# Lo smistamento è il formato che regge meglio la profondità: le categorie
		# restano poche (il bidone si deve poter leggere), ma le tessere possono
		# essere trenta. `draw` dice quante se ne pescano; l'estrazione garantisce
		# almeno una tessera per bidone, altrimenti la prova sarebbe rotta.
		{"topic": "categorie", "draw": 8, "prompt": "Smista ogni parola nella sua classe grammaticale.",
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
		{"topic": "pensiero-linguaggio", "draw": 6, "prompt": "Smista ogni parola: singolare o plurale?",
			"categories": ["singolare", "plurale"],
			"assignments": {
				"libro": "singolare", "fiore": "singolare", "casa": "singolare", "città": "singolare",
				"uovo": "singolare", "braccio": "singolare", "amico": "singolare", "problema": "singolare",
				"crisi": "singolare", "specie": "singolare", "dito": "singolare", "lenzuolo": "singolare",
				"libri": "plurale", "fiori": "plurale", "case": "plurale", "uova": "plurale",
				"braccia": "plurale", "amici": "plurale", "problemi": "plurale", "dita": "plurale",
				"lenzuola": "plurale", "valigie": "plurale", "camicie": "plurale", "ciliegie": "plurale"}},
		{"topic": "verbo", "draw": 6, "prompt": "Smista ogni verbo nel suo tempo.",
			"categories": ["passato", "presente", "futuro"],
			"assignments": {
				"ho letto": "passato", "mangiai": "passato", "correvo": "passato", "avete visto": "passato",
				"partimmo": "passato", "era": "passato", "hanno deciso": "passato", "dormivi": "passato",
				"corro": "presente", "gioca": "presente", "leggiamo": "presente", "sono": "presente",
				"dormono": "presente", "capisci": "presente", "costruisce": "presente", "aspettate": "presente",
				"andrò": "futuro", "vedremo": "futuro", "partirai": "futuro", "saranno": "futuro",
				"dormirà": "futuro", "leggerete": "futuro", "capiremo": "futuro", "costruiranno": "futuro"}},
		{"topic": "lessico", "draw": 6, "prompt": "Smista ogni nome: concreto o astratto?",
			"categories": ["concreto", "astratto"],
			"assignments": {
				"tavolo": "concreto", "cane": "concreto", "montagna": "concreto", "chiave": "concreto",
				"pioggia": "concreto", "quaderno": "concreto", "nave": "concreto", "lampada": "concreto",
				"scarpa": "concreto", "fiume": "concreto", "pane": "concreto", "vetro": "concreto",
				"amore": "astratto", "libertà": "astratto", "coraggio": "astratto", "paura": "astratto",
				"giustizia": "astratto", "speranza": "astratto", "noia": "astratto", "pazienza": "astratto",
				"silenzio": "astratto", "fantasia": "astratto", "amicizia": "astratto", "orgoglio": "astratto"}},
		# Scuola media — tempi dell'indicativo con i loro nomi.
		{"topic": "tempi-indicativo", "minLevel": 9, "draw": 8, "prompt": "Smista ogni voce verbale nel suo tempo dell'indicativo.",
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
		{"topic": "modi-verbali", "minLevel": 10, "prompt": "Smista ogni voce verbale nel suo modo.",
			"categories": ["indicativo", "congiuntivo", "condizionale", "imperativo"],
			"assignments": {"io canto": "indicativo", "tu cantavi": "indicativo", "che io canti": "congiuntivo", "che tu cantassi": "congiuntivo", "io canterei": "condizionale", "tu canteresti": "condizionale", "canta!": "imperativo", "cantate!": "imperativo"}},
		# Scuola media — analisi grammaticale: parti del discorso.
		{"topic": "analisi-grammaticale", "minLevel": 8, "prompt": "Smista ogni parola nella sua parte del discorso.",
			"categories": ["articolo", "nome", "verbo", "preposizione"],
			"assignments": {"il": "articolo", "la": "articolo", "cane": "nome", "sole": "nome", "corre": "verbo", "salta": "verbo", "con": "preposizione", "tra": "preposizione"}},
		# Scuola media — analisi logica: riconoscere i complementi.
		{"topic": "analisi-logica", "minLevel": 11, "prompt": "Smista ogni espressione nel suo complemento.",
			"categories": ["compl. di luogo", "compl. di tempo", "compl. di mezzo"],
			"assignments": {"a Roma": "compl. di luogo", "in giardino": "compl. di luogo", "alle otto": "compl. di tempo", "di sera": "compl. di tempo", "con la penna": "compl. di mezzo", "in treno": "compl. di mezzo"}},
	],
	"scienze": [
		{"topic": "viventi", "draw": 6, "prompt": "Smista ogni animale per come si nutre.",
			"categories": ["erbivoro", "carnivoro", "onnivoro"],
			"assignments": {
				"Mucca": "erbivoro", "Coniglio": "erbivoro", "Cavallo": "erbivoro", "Giraffa": "erbivoro",
				"Elefante": "erbivoro", "Pecora": "erbivoro", "Capriolo": "erbivoro", "Bruco": "erbivoro",
				"Leone": "carnivoro", "Lupo": "carnivoro", "Aquila": "carnivoro", "Squalo": "carnivoro",
				"Ragno": "carnivoro", "Coccodrillo": "carnivoro", "Gufo": "carnivoro", "Ghepardo": "carnivoro",
				"Orso": "onnivoro", "Maiale": "onnivoro", "Cinghiale": "onnivoro", "Corvo": "onnivoro",
				"Riccio": "onnivoro", "Scimpanzé": "onnivoro", "Gabbiano": "onnivoro", "Volpe": "onnivoro"}},
		{"topic": "ecosistema", "draw": 6, "prompt": "Smista ogni animale nel suo ambiente.",
			"categories": ["acqua", "aria", "terra"],
			"assignments": {
				"Pesce": "acqua", "Delfino": "acqua", "Polpo": "acqua", "Granchio": "acqua",
				"Balena": "acqua", "Medusa": "acqua", "Stella marina": "acqua", "Anguilla": "acqua",
				"Aquila": "aria", "Rondine": "aria", "Pipistrello": "aria", "Libellula": "aria",
				"Farfalla": "aria", "Gabbiano": "aria", "Ape": "aria", "Falco": "aria",
				"Talpa": "terra", "Lombrico": "terra", "Formica": "terra", "Lupo": "terra",
				"Scoiattolo": "terra", "Serpente": "terra", "Tasso": "terra", "Riccio": "terra"}},
		{"topic": "viventi", "minLevel": 2, "draw": 6, "prompt": "Smista ogni cosa: vivente o non vivente?",
			"categories": ["vivente", "non vivente"],
			"assignments": {
				"Cane": "vivente", "Albero": "vivente", "Fiore": "vivente", "Fungo": "vivente",
				"Muschio": "vivente", "Batterio": "vivente", "Alga": "vivente", "Lombrico": "vivente",
				"Felce": "vivente", "Lievito": "vivente", "Corallo": "vivente", "Seme germogliato": "vivente",
				"Roccia": "non vivente", "Acqua": "non vivente", "Nuvola": "non vivente", "Sabbia": "non vivente",
				"Vento": "non vivente", "Cristallo di sale": "non vivente", "Fuoco": "non vivente", "Ghiaccio": "non vivente",
				"Vetro": "non vivente", "Ferro": "non vivente", "Fulmine": "non vivente", "Argilla": "non vivente"}},
		{"topic": "materia", "minLevel": 3, "draw": 6, "prompt": "Smista ogni sostanza nel suo stato a temperatura ambiente.",
			"categories": ["solido", "liquido", "gassoso"],
			"assignments": {
				"Ghiaccio": "solido", "Ferro": "solido", "Legno": "solido", "Sale": "solido",
				"Vetro": "solido", "Sabbia": "solido", "Rame": "solido", "Zucchero": "solido",
				"Acqua": "liquido", "Latte": "liquido", "Olio": "liquido", "Miele": "liquido",
				"Alcol": "liquido", "Succo": "liquido", "Mercurio": "liquido", "Aceto": "liquido",
				"Vapore": "gassoso", "Aria": "gassoso", "Ossigeno": "gassoso", "Anidride carbonica": "gassoso",
				"Elio": "gassoso", "Azoto": "gassoso", "Metano": "gassoso", "Vapore acqueo": "gassoso"}},
		{"topic": "classi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni animale: vertebrato o invertebrato?",
			"categories": ["vertebrato", "invertebrato"],
			"assignments": {
				"Cane": "vertebrato", "Uccello": "vertebrato", "Pesce": "vertebrato", "Rana": "vertebrato",
				"Serpente": "vertebrato", "Balena": "vertebrato", "Tartaruga": "vertebrato", "Pipistrello": "vertebrato",
				"Squalo": "vertebrato", "Aquila": "vertebrato", "Cavallo": "vertebrato", "Salamandra": "vertebrato",
				"Verme": "invertebrato", "Ragno": "invertebrato", "Farfalla": "invertebrato", "Polpo": "invertebrato",
				"Medusa": "invertebrato", "Granchio": "invertebrato", "Lumaca": "invertebrato", "Ape": "invertebrato",
				"Formica": "invertebrato", "Stella marina": "invertebrato", "Scorpione": "invertebrato", "Cozza": "invertebrato"}},
		# Scuola media — ruoli nella rete trofica.
		{"topic": "ecosistema", "minLevel": 6, "draw": 6, "prompt": "Smista ogni organismo per il suo ruolo nell'ecosistema.",
			"categories": ["produttore", "consumatore", "decompositore"],
			"assignments": {
				"Erba": "produttore", "Albero": "produttore", "Alga": "produttore", "Felce": "produttore",
				"Muschio": "produttore", "Girasole": "produttore", "Fitoplancton": "produttore", "Cespuglio": "produttore",
				"Coniglio": "consumatore", "Lupo": "consumatore", "Cavalletta": "consumatore", "Aquila": "consumatore",
				"Cervo": "consumatore", "Rana": "consumatore", "Volpe": "consumatore", "Pesce": "consumatore",
				"Fungo": "decompositore", "Batterio": "decompositore", "Muffa": "decompositore", "Lombrico": "decompositore",
				"Scarabeo stercorario": "decompositore", "Millepiedi": "decompositore", "Lievito": "decompositore", "Termite del legno morto": "decompositore"}},
	],
	"coding": [
		{"topic": "tipi", "draw": 8, "prompt": "Smista ogni valore nel suo tipo di dato.",
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
		{"topic": "operatori", "draw": 6, "prompt": "Smista ogni operatore nella sua famiglia.",
			"categories": ["aritmetico", "confronto", "logico"],
			"assignments": {
				"+": "aritmetico", "*": "aritmetico", "-": "aritmetico", "/": "aritmetico",
				"//": "aritmetico", "%": "aritmetico", "**": "aritmetico",
				">": "confronto", "==": "confronto", "<": "confronto", "!=": "confronto",
				">=": "confronto", "<=": "confronto", "is": "confronto", "in": "confronto",
				"and": "logico", "or": "logico", "not": "logico"}},
		# Valuta l'espressione come il computer: è vera o falsa?
		{"topic": "booleani", "minLevel": 4, "draw": 6, "prompt": "Ogni espressione: è True o False?",
			"categories": ["True", "False"],
			"assignments": {
				"5 > 3": "True", "2 == 2": "True", "7 != 4": "True", "10 >= 10": "True",
				"'a' < 'b'": "True", "3 in [1, 2, 3]": "True", "not False": "True", "len('ciao') == 4": "True",
				"2 ** 3 == 8": "True", "9 % 3 == 0": "True", "True and True": "True", "False or True": "True",
				"10 < 1": "False", "'a' == 'b'": "False", "4 != 4": "False", "3 >= 7": "False",
				"5 in [1, 2, 3]": "False", "not True": "False", "len('ciao') == 5": "False", "2 ** 3 == 6": "False",
				"9 % 2 == 0": "False", "True and False": "False", "False or False": "False", "'B' == 'b'": "False"}},
		{"topic": "controllo", "minLevel": 5, "draw": 6, "prompt": "Smista ogni riga nella sua struttura di controllo.",
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
		{"topic": "nomi", "minLevel": 6, "draw": 6, "prompt": "Smista ogni nome di variabile: valido o no?",
			"categories": ["valido", "non valido"],
			"assignments": {
				"nome": "valido", "x1": "valido", "_temp": "valido", "conta_righe": "valido",
				"Totale": "valido", "n2n": "valido", "_": "valido", "areaDelCerchio": "valido",
				"lista_1": "valido", "MAX": "valido", "prezzo_euro": "valido", "a1b2": "valido",
				"2cose": "non valido", "mia var": "non valido", "3x": "non valido", "nome-utente": "non valido",
				"class": "non valido", "prezzo€": "non valido", "for": "non valido", "totale!": "non valido",
				"1_lista": "non valido", "if": "non valido", "a+b": "non valido", "mio.valore": "non valido"}},
	],
	"storia": [
		{"topic": "tempo", "draw": 6, "prompt": "Smista ogni oggetto: molto antico o moderno?",
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
		{"topic": "fonti", "minLevel": 3, "draw": 6, "prompt": "Smista ogni fonte storica nel suo tipo.",
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
		{"topic": "epoca", "minLevel": 5, "draw": 6, "prompt": "Smista ogni cosa nella sua epoca storica.",
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
		{"topic": "civilta", "minLevel": 2, "draw": 6, "prompt": "Smista ogni opera nella civiltà che l'ha realizzata.",
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
	],
	"geografia": [
		{"topic": "continenti", "draw": 8, "prompt": "Smista ogni Paese nel suo continente.",
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
		{"topic": "geografia-fisica", "draw": 6, "prompt": "Smista ogni elemento: d'acqua o di terra?",
			"categories": ["acqua", "terra"],
			"assignments": {
				"Fiume": "acqua", "Lago": "acqua", "Mare": "acqua", "Oceano": "acqua",
				"Golfo": "acqua", "Torrente": "acqua", "Cascata": "acqua", "Ghiacciaio": "acqua",
				"Laguna": "acqua", "Stretto": "acqua", "Sorgente": "acqua", "Palude": "acqua",
				"Montagna": "terra", "Pianura": "terra", "Collina": "terra", "Altopiano": "terra",
				"Deserto": "terra", "Vulcano": "terra", "Isola": "terra", "Penisola": "terra",
				"Valle": "terra", "Promontorio": "terra", "Dune": "terra", "Canyon": "terra"}},
		{"topic": "climi", "minLevel": 4, "draw": 6, "prompt": "Smista ogni luogo nel suo clima.",
			"categories": ["caldo", "temperato", "freddo"],
			"assignments": {
				"Sahara": "caldo", "Equatore": "caldo", "Amazzonia": "caldo", "Congo": "caldo",
				"Arabia": "caldo", "Borneo": "caldo", "Deserto del Kalahari": "caldo", "India del Sud": "caldo",
				"Italia": "temperato", "California": "temperato", "Grecia": "temperato", "Portogallo": "temperato",
				"Francia": "temperato", "Giappone centrale": "temperato", "Cile centrale": "temperato", "Turchia": "temperato",
				"Polo Nord": "freddo", "Siberia": "freddo", "Groenlandia": "freddo", "Antartide": "freddo",
				"Alaska": "freddo", "Islanda": "freddo", "Lapponia": "freddo", "Patagonia meridionale": "freddo"}},
		# Scuola media — i grandi paesaggi d'Italia.
		{"topic": "italia-fisica", "minLevel": 5, "draw": 6, "prompt": "Smista ogni elemento nel suo paesaggio italiano.",
			"categories": ["montagna", "pianura", "mare"],
			"assignments": {
				"Alpi": "montagna", "Appennini": "montagna", "Dolomiti": "montagna", "Monte Bianco": "montagna",
				"Gran Sasso": "montagna", "Etna": "montagna", "Vesuvio": "montagna", "Monte Rosa": "montagna",
				"Pianura Padana": "pianura", "Tavoliere delle Puglie": "pianura", "Maremma": "pianura", "Agro Pontino": "pianura",
				"Valle Padana orientale": "pianura", "Piana di Catania": "pianura", "Campidano": "pianura", "Valdarno": "pianura",
				"Mar Adriatico": "mare", "Mar Tirreno": "mare", "Mar Ionio": "mare", "Mar Ligure": "mare",
				"Golfo di Napoli": "mare", "Stretto di Messina": "mare", "Canale di Sicilia": "mare", "Golfo di Trieste": "mare"}},
	],
	"matematica": [
		{"topic": "numeri", "draw": 6, "prompt": "Smista i numeri in pari e dispari.",
			"categories": ["pari", "dispari"],
			"assignments": {
				"4": "pari", "8": "pari", "12": "pari", "26": "pari", "34": "pari", "50": "pari",
				"78": "pari", "96": "pari", "114": "pari", "130": "pari", "248": "pari", "306": "pari",
				"7": "dispari", "15": "dispari", "21": "dispari", "33": "dispari", "47": "dispari", "59": "dispari",
				"85": "dispari", "91": "dispari", "107": "dispari", "123": "dispari", "251": "dispari", "399": "dispari"}},
		{"topic": "calcolo", "draw": 6, "prompt": "Smista ogni risultato: minore di 100 oppure 100 o più.",
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
		{"topic": "uguaglianze", "minLevel": 2, "draw": 6, "prompt": "Ogni uguaglianza è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {
				"3 + 4 = 7": "vera", "10 - 6 = 4": "vera", "2 × 5 = 10": "vera", "24 ÷ 6 = 4": "vera",
				"9 + 8 = 17": "vera", "7 × 6 = 42": "vera", "100 - 45 = 55": "vera", "144 ÷ 12 = 12": "vera",
				"15 + 27 = 42": "vera", "8 × 9 = 72": "vera", "3 + 4 = 4 + 3": "vera", "2 × (3 + 4) = 14": "vera",
				"5 + 3 = 9": "falsa", "12 ÷ 3 = 5": "falsa", "6 × 2 = 10": "falsa", "20 - 7 = 14": "falsa",
				"11 + 12 = 24": "falsa", "9 × 7 = 61": "falsa", "81 ÷ 9 = 8": "falsa", "50 - 23 = 33": "falsa",
				"13 + 19 = 31": "falsa", "6 × 8 = 46": "falsa", "2 + 3 × 4 = 20": "falsa", "100 ÷ 4 = 20": "falsa"}},
		{"topic": "multipli", "minLevel": 3, "draw": 6, "prompt": "Smista: è multiplo di 3 oppure no?",
			"categories": ["multiplo di 3", "non multiplo"],
			"assignments": {
				"9": "multiplo di 3", "12": "multiplo di 3", "15": "multiplo di 3", "27": "multiplo di 3",
				"36": "multiplo di 3", "48": "multiplo di 3", "51": "multiplo di 3", "63": "multiplo di 3",
				"72": "multiplo di 3", "81": "multiplo di 3", "111": "multiplo di 3", "123": "multiplo di 3",
				"7": "non multiplo", "10": "non multiplo", "14": "non multiplo", "22": "non multiplo",
				"25": "non multiplo", "34": "non multiplo", "41": "non multiplo", "50": "non multiplo",
				"64": "non multiplo", "70": "non multiplo", "97": "non multiplo", "115": "non multiplo"}},
		# Scuola media — numeri primi, frazioni rispetto a 1/2, interi.
		{"topic": "primi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni numero: primo o composto?",
			"categories": ["primo", "composto"],
			"assignments": {
				"2": "primo", "5": "primo", "7": "primo", "11": "primo", "13": "primo", "17": "primo",
				"19": "primo", "23": "primo", "29": "primo", "31": "primo", "37": "primo", "41": "primo",
				"4": "composto", "6": "composto", "9": "composto", "15": "composto", "21": "composto", "25": "composto",
				"27": "composto", "33": "composto", "35": "composto", "39": "composto", "49": "composto", "51": "composto"}},
		{"topic": "frazioni", "minLevel": 6, "draw": 6, "prompt": "Smista ogni frazione rispetto a 1/2.",
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
		{"topic": "proporzioni", "minLevel": 13, "draw": 6, "prompt": "Ogni proporzione è vera o falsa?",
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
		{"topic": "interi", "minLevel": 6, "draw": 6, "prompt": "Smista ogni numero intero: positivo o negativo?",
			"categories": ["positivo", "negativo"],
			"assignments": {
				"5": "positivo", "12": "positivo", "3": "positivo", "27": "positivo", "48": "positivo", "101": "positivo",
				"+9": "positivo", "+16": "positivo", "+35": "positivo", "74": "positivo", "6": "positivo", "19": "positivo",
				"-3": "negativo", "-8": "negativo", "-1": "negativo", "-15": "negativo", "-24": "negativo", "-40": "negativo",
				"-7": "negativo", "-52": "negativo", "-11": "negativo", "-99": "negativo", "-6": "negativo", "-30": "negativo"}},
	],
	"fisica": [
		{"topic": "energia", "draw": 6, "prompt": "Smista ogni situazione per l'energia prevalente.",
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
		{"topic": "materia", "draw": 6, "prompt": "Smista ogni materiale nel suo stato a temperatura ambiente.",
			"categories": ["solido", "liquido", "gassoso"],
			"assignments": {
				"Ghiaccio": "solido", "Ferro": "solido", "Legno": "solido", "Vetro": "solido",
				"Sale": "solido", "Rame": "solido", "Plastica": "solido", "Marmo": "solido",
				"Acqua": "liquido", "Latte": "liquido", "Olio": "liquido", "Alcol": "liquido",
				"Mercurio": "liquido", "Benzina": "liquido", "Miele": "liquido", "Aceto": "liquido",
				"Vapore": "gassoso", "Aria": "gassoso", "Ossigeno": "gassoso", "Elio": "gassoso",
				"Azoto": "gassoso", "Metano": "gassoso", "Anidride carbonica": "gassoso", "Idrogeno": "gassoso"}},
		# Scuola media — forze di contatto o a distanza, e la luce nei materiali.
		{"topic": "forze", "minLevel": 5, "draw": 6, "prompt": "Smista ogni forza: agisce per contatto o a distanza?",
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
		{"topic": "luce", "minLevel": 6, "draw": 6, "prompt": "Smista ogni materiale per come lascia passare la luce.",
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
	],
	"musica": [
		{"topic": "strumenti", "draw": 6, "prompt": "Smista ogni strumento nella sua famiglia.",
			"categories": ["corde", "fiati", "percussioni"],
			"assignments": {
				"Chitarra": "corde", "Violino": "corde", "Viola": "corde", "Violoncello": "corde",
				"Contrabbasso": "corde", "Arpa": "corde", "Mandolino": "corde", "Banjo": "corde",
				"Flauto": "fiati", "Tromba": "fiati", "Clarinetto": "fiati", "Sassofono": "fiati",
				"Oboe": "fiati", "Trombone": "fiati", "Corno": "fiati", "Fagotto": "fiati",
				"Tamburo": "percussioni", "Timpani": "percussioni", "Piatti": "percussioni", "Xilofono": "percussioni",
				"Triangolo": "percussioni", "Maracas": "percussioni", "Grancassa": "percussioni", "Tamburello": "percussioni"}},
		{"topic": "timbro", "draw": 6, "prompt": "Smista ogni strumento: acustico o elettronico?",
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
		{"topic": "intervalli", "minLevel": 4, "draw": 6, "prompt": "Smista ogni strumento per l'altezza del suono.",
			"categories": ["acuto", "grave"],
			"assignments": {
				"Flauto": "acuto", "Ottavino": "acuto", "Violino": "acuto", "Tromba": "acuto",
				"Oboe": "acuto", "Clarinetto piccolo": "acuto", "Triangolo": "acuto", "Glockenspiel": "acuto",
				"Mandolino": "acuto", "Soprano": "acuto", "Campanelli": "acuto", "Sassofono contralto": "acuto",
				"Violoncello": "grave", "Contrabbasso": "grave", "Tuba": "grave", "Fagotto": "grave",
				"Trombone": "grave", "Grancassa": "grave", "Timpani": "grave", "Basso elettrico": "grave",
				"Corno": "grave", "Sassofono baritono": "grave", "Organo (canne lunghe)": "grave", "Basso": "grave"}},
	],
	"elettronica": [
		{"topic": "conduttori", "draw": 6, "prompt": "Smista ogni materiale: conduttore o isolante?",
			"categories": ["conduttore", "isolante"],
			"assignments": {
				"Rame": "conduttore", "Ferro": "conduttore", "Alluminio": "conduttore", "Argento": "conduttore",
				"Oro": "conduttore", "Acciaio": "conduttore", "Ottone": "conduttore", "Grafite": "conduttore",
				"Acqua salata": "conduttore", "Stagno": "conduttore", "Nichel": "conduttore", "Zinco": "conduttore",
				"Plastica": "isolante", "Legno secco": "isolante", "Gomma": "isolante", "Vetro": "isolante",
				"Ceramica": "isolante", "Carta": "isolante", "Aria secca": "isolante", "Porcellana": "isolante",
				"Silicone": "isolante", "Stoffa": "isolante", "Sughero": "isolante", "Acqua distillata": "isolante"}},
		{"topic": "componenti", "draw": 6, "prompt": "Smista ogni componente: dà energia o la usa?",
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
		{"topic": "ruoli", "minLevel": 4, "draw": 8, "prompt": "Smista ogni elemento per il suo ruolo nel circuito.",
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
	],
	"inglese": [
		{"topic": "categorie", "draw": 8, "prompt": "Sort each word into its category.",
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
		{"topic": "home-family", "draw": 6, "prompt": "Sort each word: family, school or nature.",
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
		{"topic": "articles", "minLevel": 5, "draw": 6, "prompt": "Sort each word: does it take 'a' or 'an'?",
			"categories": ["a", "an"],
			"assignments": {
				"apple": "an", "orange": "an", "umbrella": "an", "elephant": "an",
				"island": "an", "hour": "an", "onion": "an", "artist": "an",
				"idea": "an", "egg": "an", "engine": "an", "honest man": "an",
				"dog": "a", "car": "a", "book": "a", "university": "a",
				"table": "a", "house": "a", "European city": "a", "friend": "a",
				"uniform": "a", "window": "a", "garden": "a", "yellow bird": "a"}},
		{"topic": "parts-of-speech", "minLevel": 6, "draw": 6, "prompt": "Sort each word into its part of speech.",
			"categories": ["noun", "verb", "adjective"],
			"assignments": {
				"dog": "noun", "house": "noun", "river": "noun", "teacher": "noun",
				"bottle": "noun", "friendship": "noun", "mountain": "noun", "window": "noun",
				"run": "verb", "eat": "verb", "build": "verb", "listen": "verb",
				"forget": "verb", "choose": "verb", "arrive": "verb", "explain": "verb",
				"big": "adjective", "red": "adjective", "quiet": "adjective", "heavy": "adjective",
				"ancient": "adjective", "friendly": "adjective", "narrow": "adjective", "brave": "adjective"}},
		# Scuola media — verbi regolari/irregolari e nomi numerabili/non numerabili.
		{"topic": "verbs", "minLevel": 8, "draw": 6, "prompt": "Sort each past-tense verb: regular or irregular?",
			"categories": ["regular", "irregular"],
			"assignments": {
				"played": "regular", "walked": "regular", "watched": "regular", "opened": "regular",
				"listened": "regular", "arrived": "regular", "studied": "regular", "helped": "regular",
				"cleaned": "regular", "carried": "regular", "wanted": "regular", "stopped": "regular",
				"went": "irregular", "ate": "irregular", "saw": "irregular", "took": "irregular",
				"wrote": "irregular", "drank": "irregular", "began": "irregular", "brought": "irregular",
				"caught": "irregular", "chose": "irregular", "slept": "irregular", "spoke": "irregular"}},
		{"topic": "nouns", "minLevel": 9, "draw": 6, "prompt": "Sort each noun: countable or uncountable?",
			"categories": ["countable", "uncountable"],
			"assignments": {
				"apple": "countable", "book": "countable", "car": "countable", "chair": "countable",
				"idea": "countable", "song": "countable", "bottle": "countable", "child": "countable",
				"city": "countable", "coin": "countable", "letter": "countable", "tree": "countable",
				"water": "uncountable", "milk": "uncountable", "rice": "uncountable", "bread": "uncountable",
				"money": "uncountable", "music": "uncountable", "advice": "uncountable", "information": "uncountable",
				"sugar": "uncountable", "homework": "uncountable", "furniture": "uncountable", "weather": "uncountable"}},
	],
	"latino": [
		# In latino l'ordine è convenzione pura — i casi si recitano in quell'ordine
		# perché così li recita il libro, non perché uno sia «maggiore» di un altro.
		# Quindi l'ordinamento qui resta a dato fisso, e tutta la profondità deve
		# venire da smistamento e abbinamento. È il caso opposto a storia e fisica.
		{"topic": "vocabolario", "draw": 6, "prompt": "Smista ogni parola latina per campo di significato.",
			"categories": ["natura", "persone", "animali"],
			"assignments": {
				"aqua": "natura", "silva": "natura", "terra": "natura", "stella": "natura",
				"luna": "natura", "mare": "natura", "flumen": "natura", "arbor": "natura",
				"ventus": "natura", "sol": "natura", "campus": "natura", "mons": "natura",
				"puella": "persone", "poeta": "persone", "agricola": "persone", "nauta": "persone",
				"miles": "persone", "rex": "persone", "magister": "persone", "puer": "persone",
				"lupus": "animali", "equus": "animali", "canis": "animali", "avis": "animali",
				"taurus": "animali", "piscis": "animali", "ursus": "animali", "aquila": "animali"}},
		{"topic": "casi", "minLevel": 5, "draw": 6, "prompt": "Smista ogni parola latina nel suo genere.",
			"categories": ["maschile", "femminile", "neutro"],
			"assignments": {
				"lupus": "maschile", "poeta": "maschile", "servus": "maschile", "dominus": "maschile",
				"agricola": "maschile", "nauta": "maschile", "hortus": "maschile", "amicus": "maschile",
				"puella": "femminile", "rosa": "femminile", "silva": "femminile", "aqua": "femminile",
				"terra": "femminile", "stella": "femminile", "regina": "femminile", "porta": "femminile",
				"templum": "neutro", "bellum": "neutro", "donum": "neutro", "verbum": "neutro",
				"oppidum": "neutro", "vinum": "neutro", "signum": "neutro", "regnum": "neutro"}},
		# Scuola media — riconoscere la declinazione di appartenenza.
		{"topic": "declinazioni-base", "minLevel": 6, "draw": 6, "prompt": "Smista ogni parola nella sua declinazione.",
			"categories": ["1ª declinazione", "2ª declinazione", "3ª declinazione"],
			"assignments": {
				"rosa": "1ª declinazione", "puella": "1ª declinazione", "silva": "1ª declinazione", "aqua": "1ª declinazione",
				"terra": "1ª declinazione", "stella": "1ª declinazione", "regina": "1ª declinazione", "porta": "1ª declinazione",
				"lupus": "2ª declinazione", "templum": "2ª declinazione", "servus": "2ª declinazione", "donum": "2ª declinazione",
				"hortus": "2ª declinazione", "bellum": "2ª declinazione", "amicus": "2ª declinazione", "verbum": "2ª declinazione",
				"rex": "3ª declinazione", "miles": "3ª declinazione", "flumen": "3ª declinazione", "mare": "3ª declinazione",
				"consul": "3ª declinazione", "corpus": "3ª declinazione", "civis": "3ª declinazione", "nomen": "3ª declinazione"}},
	],
	"logica": [
		# In logica la profondità non può venire da PIÙ ELEMENTI: un insieme di
		# trenta cani e trenta rose non rende il ragionamento più ricco, solo più
		# lungo. Deve venire da più REGOLE — quantificatori diversi, negazioni,
		# affermazioni vere per ragioni diverse. Perciò qui gli insiemi sono grandi
		# ma le voci sono scelte perché ciascuna chiede un passo di ragionamento suo.
		{"topic": "esclusioni", "draw": 6, "prompt": "Smista ogni elemento nel suo insieme.",
			"categories": ["animale", "pianta"],
			"assignments": {
				"Cane": "animale", "Aquila": "animale", "Gatto": "animale", "Lombrico": "animale",
				"Ape": "animale", "Delfino": "animale", "Ragno": "animale", "Corallo": "animale",
				"Spugna di mare": "animale", "Medusa": "animale", "Pipistrello": "animale", "Formica": "animale",
				"Rosa": "pianta", "Quercia": "pianta", "Tulipano": "pianta", "Felce": "pianta",
				"Muschio": "pianta", "Cactus": "pianta", "Girasole": "pianta", "Trifoglio": "pianta",
				"Bambù": "pianta", "Edera": "pianta", "Grano": "pianta", "Pino": "pianta"}},
		{"topic": "verita", "minLevel": 4, "draw": 6, "prompt": "Ogni affermazione: è vera o falsa?",
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
		{"topic": "quantificatori", "minLevel": 6, "draw": 6, "prompt": "Ogni cosa accade sempre, a volte o mai?",
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
		{"topic": "insiemi", "minLevel": 3, "draw": 6, "prompt": "Smista ogni elemento nel suo insieme.",
			"categories": ["colori", "forme", "numeri"],
			"assignments": {
				"Rosso": "colori", "Blu": "colori", "Verde": "colori", "Giallo": "colori",
				"Viola": "colori", "Arancione": "colori", "Turchese": "colori", "Magenta": "colori",
				"Cerchio": "forme", "Quadrato": "forme", "Triangolo": "forme", "Rombo": "forme",
				"Trapezio": "forme", "Esagono": "forme", "Pentagono": "forme", "Ellisse": "forme",
				"Uno": "numeri", "Due": "numeri", "Sette": "numeri", "Dodici": "numeri",
				"Venti": "numeri", "Cento": "numeri", "Tre quarti": "numeri", "Zero": "numeri"}},
	],
}

# Lettura di GRAFICO (assi + curva disegnati proceduralmente): scegli il punto
# richiesto. Nessun asset immagine. `points` in coordinate normalizzate 0..1.
const GRAPH := {
	"elettronica": [
		{"topic": "legge-ohm", "minLevel": 6, "xLabel": "tensione", "yLabel": "corrente", "answer": "D",
			"prompt": "Il grafico mostra la corrente al crescere della tensione (legge di Ohm): in quale punto la corrente è massima?",
			"points": [{"id": "A", "x": 0.12, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.42, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.94, "label": "D"}],
			"explanation": "La corrente cresce in modo proporzionale alla tensione: è massima all'ultimo punto, D."},
		{"topic": "misure-elettriche", "minLevel": 5, "xLabel": "tempo", "yLabel": "carica", "answer": "D",
			"prompt": "Il grafico mostra la carica di una batteria mentre si scarica usandola: in quale punto è più scarica?",
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.66, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.38, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.12, "label": "D"}],
			"explanation": "Usandola la carica cala nel tempo: la batteria è più scarica alla fine, nel punto D."},
	],
	"fisica": [
		{"topic": "moto", "xLabel": "tempo", "yLabel": "velocità", "answer": "C",
			"prompt": "Il grafico mostra la velocità nel tempo: in quale punto è massima?",
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.50, "label": "D"}],
			"explanation": "La velocità è massima dove la curva è più in alto: il punto C."},
		{"topic": "moto", "minLevel": 4, "xLabel": "tempo", "yLabel": "distanza", "answer": "D",
			"prompt": "Il grafico mostra la distanza percorsa nel tempo: in quale punto l'oggetto è più lontano dalla partenza?",
			"points": [{"id": "A", "x": 0.10, "y": 0.12, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.66, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.92, "y": 0.95, "label": "D"}],
			"explanation": "La distanza cresce sempre: l'oggetto è più lontano alla fine, nel punto D."},
		{"topic": "caduta", "minLevel": 6, "xLabel": "tempo", "yLabel": "velocità", "answer": "D",
			"prompt": "Un sasso cade e accelera per gravità: in quale punto va più veloce?",
			"points": [{"id": "A", "x": 0.10, "y": 0.08, "label": "A"}, {"id": "B", "x": 0.40, "y": 0.28, "label": "B"}, {"id": "C", "x": 0.68, "y": 0.58, "label": "C"}, {"id": "D", "x": 0.92, "y": 0.95, "label": "D"}],
			"explanation": "Cadendo la velocità cresce sempre di più: è massima alla fine, nel punto D."},
	],
	"matematica": [
		{"topic": "coordinate", "xLabel": "x", "yLabel": "y", "answer": "Q",
			"prompt": "Quale punto si trova più in alto (ordinata y maggiore)?",
			"points": [{"id": "P", "x": 0.20, "y": 0.35, "label": "P"}, {"id": "Q", "x": 0.50, "y": 0.85, "label": "Q"}, {"id": "R", "x": 0.80, "y": 0.55, "label": "R"}],
			"explanation": "Il punto Q ha l'ordinata (y) più grande."},
		# Lettura di grafici: competenza chiave di dati e statistica.
		{"topic": "dati", "xLabel": "ora", "yLabel": "temperatura", "answer": "C",
			"prompt": "Il grafico mostra la temperatura durante il giorno: in quale punto è massima?",
			"points": [{"id": "A", "x": 0.10, "y": 0.25, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.60, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.55, "label": "D"}],
			"explanation": "La temperatura è massima dove la curva è più in alto: il punto C."},
		{"topic": "dati", "xLabel": "settimana", "yLabel": "risparmi", "answer": "A",
			"prompt": "Il grafico mostra i risparmi settimana per settimana: in quale punto sono minimi?",
			"points": [{"id": "A", "x": 0.12, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.40, "y": 0.45, "label": "B"}, {"id": "C", "x": 0.68, "y": 0.70, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.92, "label": "D"}],
			"explanation": "I risparmi sono minimi dove la curva è più in basso: il punto A."},
		{"topic": "funzioni", "minLevel": 6, "xLabel": "x", "yLabel": "y", "answer": "A",
			"prompt": "La retta sale da sinistra a destra: in quale punto tocca l'asse x (y = 0)?",
			"points": [{"id": "A", "x": 0.15, "y": 0.05, "label": "A"}, {"id": "B", "x": 0.45, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.72, "y": 0.68, "label": "C"}, {"id": "D", "x": 0.92, "y": 0.90, "label": "D"}],
			"explanation": "La retta interseca l'asse x dove y vale (quasi) zero: il punto A, in basso."},
	],
	"scienze": [
		{"topic": "metodo", "xLabel": "giorni", "yLabel": "altezza", "answer": "D",
			"prompt": "La pianta cresce nel tempo: in quale punto è più alta?",
			"points": [{"id": "A", "x": 0.10, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.40, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.70, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.95, "label": "D"}],
			"explanation": "La curva sale sempre: l'ultimo punto D è il più alto."},
		{"topic": "materia", "minLevel": 4, "xLabel": "tempo", "yLabel": "temperatura", "answer": "D",
			"prompt": "Una tazza di tè si raffredda: in quale punto la temperatura è più bassa?",
			"points": [{"id": "A", "x": 0.10, "y": 0.92, "label": "A"}, {"id": "B", "x": 0.36, "y": 0.62, "label": "B"}, {"id": "C", "x": 0.64, "y": 0.38, "label": "C"}, {"id": "D", "x": 0.90, "y": 0.18, "label": "D"}],
			"explanation": "La curva scende raffreddandosi: la temperatura è più bassa alla fine, nel punto D."},
	],
	# ITALIANO — "L'arco narrativo": la curva della tensione di un racconto, a forma
	# di montagna (esposizione A -> complicazione B -> climax C -> scioglimento D ->
	# finale E). Stessa curva, domande diverse: si legge la struttura di una storia.
	"italiano": [
		{"topic": "testo-narrativo", "xLabel": "tempo del racconto", "yLabel": "tensione", "answer": "C",
			"prompt": "La curva mostra la tensione di un racconto dall'inizio (A) alla fine (E). In quale punto c'è il climax, la massima suspense?",
			"points": [{"id": "A", "x": 0.08, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.52, "label": "B"}, {"id": "C", "x": 0.52, "y": 0.94, "label": "C"}, {"id": "D", "x": 0.75, "y": 0.46, "label": "D"}, {"id": "E", "x": 0.93, "y": 0.16, "label": "E"}],
			"explanation": "Il climax è il punto più alto della tensione: C. Dopo, la storia si avvia allo scioglimento."},
		{"topic": "testo-narrativo", "xLabel": "tempo del racconto", "yLabel": "tensione", "answer": "A",
			"prompt": "In quale punto la storia presenta con calma personaggi e luogo, prima che arrivino i problemi (l'esposizione)?",
			"points": [{"id": "A", "x": 0.08, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.52, "label": "B"}, {"id": "C", "x": 0.52, "y": 0.94, "label": "C"}, {"id": "D", "x": 0.75, "y": 0.46, "label": "D"}, {"id": "E", "x": 0.93, "y": 0.16, "label": "E"}],
			"explanation": "L'esposizione è l'inizio calmo, con tensione bassa: il punto A."},
		{"topic": "testo-narrativo", "xLabel": "tempo del racconto", "yLabel": "tensione", "answer": "D",
			"prompt": "Superato il climax (C), la tensione cala e i nodi si sciolgono: quale punto è lo scioglimento?",
			"points": [{"id": "A", "x": 0.08, "y": 0.18, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.52, "label": "B"}, {"id": "C", "x": 0.52, "y": 0.94, "label": "C"}, {"id": "D", "x": 0.75, "y": 0.46, "label": "D"}, {"id": "E", "x": 0.93, "y": 0.16, "label": "E"}],
			"explanation": "Lo scioglimento è la discesa dopo il climax: il punto D, prima della situazione finale E."},
	],
	# LOGICA — riconoscimento di schemi: i punti salgono in linea, ma uno è fuori
	# posto. Trovare l'intruso è ragionamento visivo puro.
	"logica": [
		{"topic": "schemi", "minLevel": 4, "xLabel": "posizione", "yLabel": "valore", "answer": "C",
			"prompt": "Questi punti seguono uno schema che sale in linea, ma uno è fuori posto: quale rompe lo schema?",
			"points": [{"id": "A", "x": 0.10, "y": 0.15, "label": "A"}, {"id": "B", "x": 0.30, "y": 0.35, "label": "B"}, {"id": "C", "x": 0.50, "y": 0.90, "label": "C"}, {"id": "D", "x": 0.70, "y": 0.72, "label": "D"}, {"id": "E", "x": 0.90, "y": 0.92, "label": "E"}],
			"explanation": "Gli altri salgono in modo regolare; il punto C schizza troppo in alto: è l'intruso fuori schema."},
		{"topic": "schemi", "minLevel": 5, "xLabel": "posizione", "yLabel": "valore", "answer": "B",
			"prompt": "Questi punti scendono in modo regolare, ma uno è fuori posto: quale rompe lo schema?",
			"points": [{"id": "A", "x": 0.10, "y": 0.90, "label": "A"}, {"id": "B", "x": 0.34, "y": 0.22, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.52, "label": "C"}, {"id": "D", "x": 0.86, "y": 0.30, "label": "D"}],
			"explanation": "Gli altri scendono in modo regolare; il punto B crolla troppo in basso: è l'intruso fuori schema."},
	],
	# GEOGRAFIA — leggere climogrammi e profili altimetrici: competenza cartografica.
	"geografia": [
		{"topic": "climi", "minLevel": 4, "xLabel": "mese", "yLabel": "temperatura", "answer": "C",
			"prompt": "Il climogramma mostra la temperatura mese per mese: in quale punto (mese) fa più caldo?",
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.55, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.80, "y": 0.60, "label": "D"}],
			"explanation": "Il punto più in alto è il mese più caldo (l'estate): il punto C."},
		{"topic": "geografia-fisica", "minLevel": 5, "xLabel": "percorso", "yLabel": "altitudine", "answer": "C",
			"prompt": "Il profilo altimetrico mostra l'altitudine lungo un percorso: quale punto è la vetta più alta?",
			"points": [{"id": "A", "x": 0.10, "y": 0.30, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.60, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.85, "y": 0.45, "label": "D"}],
			"explanation": "La vetta è il punto più in alto del profilo: il punto C."},
	],
	# STORIA — leggere un grafico storico: come cambia un dato nei secoli.
	"storia": [
		{"topic": "cronologia", "minLevel": 5, "xLabel": "secoli", "yLabel": "abitanti", "answer": "C",
			"prompt": "Il grafico mostra gli abitanti di una città nei secoli: in quale punto la città era più popolosa?",
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.85, "y": 0.45, "label": "D"}],
			"explanation": "La città era più popolosa dove la curva è più in alto: il punto C. Poi la popolazione è calata."},
		{"topic": "roma", "minLevel": 18, "xLabel": "secoli", "yLabel": "estensione", "answer": "C",
			"prompt": "Il grafico mostra l'estensione dell'Impero Romano nei secoli: in quale punto era più vasto (al massimo)?",
			"points": [{"id": "A", "x": 0.10, "y": 0.25, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.60, "label": "B"}, {"id": "C", "x": 0.58, "y": 0.95, "label": "C"}, {"id": "D", "x": 0.85, "y": 0.35, "label": "D"}],
			"explanation": "L'Impero era più vasto al culmine (punto C); poi si ridusse fino alla caduta."},
	],
	# MUSICA — il contorno melodico: l'altezza delle note nel tempo. Leggere se il
	# suono sale o scende è una competenza musicale di base.
	"musica": [
		{"topic": "note", "minLevel": 4, "xLabel": "tempo", "yLabel": "altezza", "answer": "C",
			"prompt": "Il grafico è il contorno di una melodia (l'altezza delle note nel tempo): in quale punto la nota è più ACUTA (più alta)?",
			"points": [{"id": "A", "x": 0.12, "y": 0.30, "label": "A"}, {"id": "B", "x": 0.38, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.62, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.40, "label": "D"}],
			"explanation": "La nota più acuta è dove la linea è più in alto: il punto C. Più in basso = più grave."},
		{"topic": "dinamica", "minLevel": 5, "xLabel": "tempo", "yLabel": "volume", "answer": "D",
			"prompt": "Il grafico mostra il volume in un diminuendo: in quale punto il suono è più DEBOLE?",
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
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.50, "y": 0.22, "label": "Interruttore"}, {"id": "resistore", "x": 0.80, "y": 0.50, "label": "Resistore"}, {"id": "led", "x": 0.50, "y": 0.78, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "resistore"], ["resistore", "led"], ["led", "pila"]],
			"explanation": "L'interruttore apre e chiude il circuito: accende o spegne il LED."},
		{"topic": "componenti", "answer": "led",
			"prompt": "Quale componente emette luce quando la corrente lo attraversa?",
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "resistore", "x": 0.50, "y": 0.24, "label": "Resistore"}, {"id": "led", "x": 0.80, "y": 0.50, "label": "LED"}, {"id": "filo", "x": 0.50, "y": 0.78, "label": "Filo"}],
			"connections": [["pila", "resistore"], ["resistore", "led"], ["led", "filo"], ["filo", "pila"]],
			"explanation": "Il LED emette luce quando è attraversato dalla corrente."},
		{"topic": "sorgente", "answer": "pila",
			"prompt": "Quale componente fornisce l'energia a tutto il circuito?",
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "interruttore", "x": 0.50, "y": 0.22, "label": "Interruttore"}, {"id": "resistore", "x": 0.80, "y": 0.50, "label": "Resistore"}, {"id": "led", "x": 0.50, "y": 0.78, "label": "LED"}],
			"connections": [["pila", "interruttore"], ["interruttore", "resistore"], ["resistore", "led"], ["led", "pila"]],
			"explanation": "La pila è la sorgente: spinge la corrente in tutto il circuito."},
		{"topic": "protezione", "minLevel": 3, "answer": "resistore",
			"prompt": "Quale componente limita la corrente così il LED non si brucia?",
			"components": [{"id": "pila", "x": 0.20, "y": 0.50, "label": "Pila"}, {"id": "resistore", "x": 0.50, "y": 0.24, "label": "Resistore"}, {"id": "led", "x": 0.80, "y": 0.50, "label": "LED"}, {"id": "filo", "x": 0.50, "y": 0.78, "label": "Filo"}],
			"connections": [["pila", "resistore"], ["resistore", "led"], ["led", "filo"], ["filo", "pila"]],
			"explanation": "Il resistore limita la corrente: protegge il LED dal bruciarsi."},
	],
	# CODING — il renderer nodi+collegamenti diventa un DIAGRAMMA DI FLUSSO: si
	# legge il percorso di un programma e si sceglie il blocco richiesto. (Codex
	# potrà poi dare al blocco-decisione la forma a rombo tipica dei flowchart.)
	"coding": [
		{"topic": "diagramma-flusso", "minLevel": 4, "answer": "decisione",
			"prompt": "Questo è il diagramma di flusso di un programma. Quale blocco DECIDE il percorso (la condizione)?",
			"components": [{"id": "inizio", "x": 0.50, "y": 0.10, "label": "Inizio"}, {"id": "leggi", "x": 0.50, "y": 0.30, "label": "Leggi n"}, {"id": "decisione", "x": 0.50, "y": 0.52, "label": "n pari?"}, {"id": "pari", "x": 0.24, "y": 0.75, "label": "pari"}, {"id": "dispari", "x": 0.76, "y": 0.75, "label": "dispari"}, {"id": "fine", "x": 0.50, "y": 0.92, "label": "Fine"}],
			"connections": [["inizio", "leggi"], ["leggi", "decisione"], ["decisione", "pari"], ["decisione", "dispari"], ["pari", "fine"], ["dispari", "fine"]],
			"explanation": "Il blocco 'n pari?' è la condizione: da lì il flusso si divide in due strade."},
		{"topic": "diagramma-flusso", "minLevel": 5, "answer": "controllo",
			"prompt": "In questo diagramma di flusso, quale blocco controlla quante volte si ripete il ciclo?",
			"components": [{"id": "inizio", "x": 0.50, "y": 0.10, "label": "Inizio"}, {"id": "init", "x": 0.50, "y": 0.30, "label": "i = 0"}, {"id": "controllo", "x": 0.50, "y": 0.52, "label": "i < 3?"}, {"id": "corpo", "x": 0.24, "y": 0.72, "label": "stampa i"}, {"id": "fine", "x": 0.78, "y": 0.72, "label": "Fine"}],
			"connections": [["inizio", "init"], ["init", "controllo"], ["controllo", "corpo"], ["corpo", "controllo"], ["controllo", "fine"]],
			"explanation": "Il blocco 'i < 3?' è la condizione del ciclo: finché è vera si ripete 'stampa i'."},
	],
	# SCIENZE — il renderer nodi+collegamenti diventa una CATENA ALIMENTARE: si
	# legge il flusso di energia e si sceglie l'organismo richiesto.
	"scienze": [
		{"topic": "catena", "minLevel": 4, "answer": "erba",
			"prompt": "In questa catena alimentare l'energia sale da un anello all'altro. Quale organismo è il PRODUTTORE, alla base di tutto?",
			"components": [{"id": "erba", "x": 0.12, "y": 0.82, "label": "Erba"}, {"id": "cavalletta", "x": 0.32, "y": 0.62, "label": "Cavalletta"}, {"id": "rana", "x": 0.52, "y": 0.44, "label": "Rana"}, {"id": "serpente", "x": 0.72, "y": 0.30, "label": "Serpente"}, {"id": "aquila", "x": 0.90, "y": 0.14, "label": "Aquila"}],
			"connections": [["erba", "cavalletta"], ["cavalletta", "rana"], ["rana", "serpente"], ["serpente", "aquila"]],
			"explanation": "L'erba è il produttore: crea energia con la fotosintesi e tutti gli altri dipendono da lei."},
		{"topic": "catena", "minLevel": 5, "answer": "aquila",
			"prompt": "In questa catena alimentare, quale organismo è il predatore al vertice, che nessuno mangia?",
			"components": [{"id": "erba", "x": 0.12, "y": 0.82, "label": "Erba"}, {"id": "cavalletta", "x": 0.32, "y": 0.62, "label": "Cavalletta"}, {"id": "rana", "x": 0.52, "y": 0.44, "label": "Rana"}, {"id": "serpente", "x": 0.72, "y": 0.30, "label": "Serpente"}, {"id": "aquila", "x": 0.90, "y": 0.14, "label": "Aquila"}],
			"connections": [["erba", "cavalletta"], ["cavalletta", "rana"], ["rana", "serpente"], ["serpente", "aquila"]],
			"explanation": "L'aquila è il predatore all'apice: in questa catena nessuno la caccia."},
	],
	# FISICA — il renderer nodi+collegamenti diventa la CATENA DI TRASFORMAZIONI
	# dell'energia: si segue come l'energia cambia forma e si sceglie quella giusta.
	"fisica": [
		{"topic": "energia", "minLevel": 5, "answer": "potenziale",
			"prompt": "Una pallina viene sollevata, cade e rimbalza. Quando è ferma in alto, prima di cadere, che energia possiede?",
			"components": [{"id": "potenziale", "x": 0.18, "y": 0.18, "label": "Ferma in alto"}, {"id": "cinetica", "x": 0.50, "y": 0.72, "label": "Sta cadendo"}, {"id": "elastica", "x": 0.82, "y": 0.88, "label": "Tocca il suolo"}, {"id": "risalita", "x": 0.86, "y": 0.34, "label": "Risale"}],
			"connections": [["potenziale", "cinetica"], ["cinetica", "elastica"], ["elastica", "risalita"]],
			"explanation": "Ferma in alto la pallina ha energia potenziale (di posizione); cadendo diventa cinetica."},
		{"topic": "energia", "minLevel": 6, "answer": "cinetica",
			"prompt": "Segui la trasformazione dell'energia della pallina: in quale fase l'energia è tutta cinetica (di movimento)?",
			"components": [{"id": "potenziale", "x": 0.18, "y": 0.18, "label": "Ferma in alto"}, {"id": "cinetica", "x": 0.50, "y": 0.72, "label": "Sta cadendo"}, {"id": "elastica", "x": 0.82, "y": 0.88, "label": "Tocca il suolo"}, {"id": "risalita", "x": 0.86, "y": 0.34, "label": "Risale"}],
			"connections": [["potenziale", "cinetica"], ["cinetica", "elastica"], ["elastica", "risalita"]],
			"explanation": "Mentre cade, l'energia potenziale si è trasformata tutta in cinetica: è il momento più veloce."},
	],
	# LOGICA — il renderer nodi+collegamenti diventa un ALBERO DELLE DECISIONI: si
	# seguono le risposte sì/no fino alla conclusione giusta.
	"logica": [
		{"topic": "albero-decisioni", "minLevel": 5, "answer": "uccello",
			"prompt": "Segui l'albero: un animale HA le ali. A quale conclusione arrivi?",
			"components": [{"id": "ali", "x": 0.50, "y": 0.12, "label": "Ha le ali?"}, {"id": "uccello", "x": 0.22, "y": 0.52, "label": "Uccello"}, {"id": "pinne", "x": 0.72, "y": 0.44, "label": "Ha le pinne?"}, {"id": "pesce", "x": 0.55, "y": 0.86, "label": "Pesce"}, {"id": "mammifero", "x": 0.90, "y": 0.86, "label": "Mammifero"}],
			"connections": [["ali", "uccello"], ["ali", "pinne"], ["pinne", "pesce"], ["pinne", "mammifero"]],
			"explanation": "Ha le ali → sì → il ramo porta a 'Uccello'."},
		{"topic": "albero-decisioni", "minLevel": 6, "answer": "quadrato",
			"prompt": "Segui l'albero: una figura ha 4 lati UGUALI e 4 angoli retti. Dove arrivi?",
			"components": [{"id": "quattro", "x": 0.50, "y": 0.12, "label": "Ha 4 lati?"}, {"id": "triangolo", "x": 0.20, "y": 0.52, "label": "Triangolo"}, {"id": "uguali", "x": 0.70, "y": 0.44, "label": "Lati uguali?"}, {"id": "quadrato", "x": 0.55, "y": 0.86, "label": "Quadrato"}, {"id": "rettangolo", "x": 0.90, "y": 0.86, "label": "Rettangolo"}],
			"connections": [["quattro", "triangolo"], ["quattro", "uguali"], ["uguali", "quadrato"], ["uguali", "rettangolo"]],
			"explanation": "4 lati → sì → lati uguali → sì → il ramo porta a 'Quadrato'."},
	],
	# GEOGRAFIA — il renderer nodi+collegamenti diventa il CORSO DI UN FIUME, con un
	# affluente che confluisce: si legge dove nasce e dove sfocia.
	"geografia": [
		{"topic": "fiume", "minLevel": 4, "answer": "foce",
			"prompt": "Questo è il corso di un fiume. In quale punto sfocia nel mare (la foce)?",
			"components": [{"id": "sorgente", "x": 0.20, "y": 0.12, "label": "Sorgente"}, {"id": "affluente", "x": 0.72, "y": 0.20, "label": "Affluente"}, {"id": "confluenza", "x": 0.48, "y": 0.50, "label": "Confluenza"}, {"id": "foce", "x": 0.60, "y": 0.90, "label": "Foce"}],
			"connections": [["sorgente", "confluenza"], ["affluente", "confluenza"], ["confluenza", "foce"]],
			"explanation": "La foce è dove il fiume finisce nel mare, il punto più in basso del corso."},
		{"topic": "fiume", "minLevel": 5, "answer": "sorgente",
			"prompt": "In questo corso d'acqua, dove nasce il fiume principale (la sorgente)?",
			"components": [{"id": "sorgente", "x": 0.20, "y": 0.12, "label": "Sorgente"}, {"id": "affluente", "x": 0.72, "y": 0.20, "label": "Affluente"}, {"id": "confluenza", "x": 0.48, "y": 0.50, "label": "Confluenza"}, {"id": "foce", "x": 0.60, "y": 0.90, "label": "Foce"}],
			"connections": [["sorgente", "confluenza"], ["affluente", "confluenza"], ["confluenza", "foce"]],
			"explanation": "La sorgente è dove il fiume nasce, in alto: da lì l'acqua scende verso la foce."},
	],
	# STORIA — il renderer nodi+collegamenti diventa una LINEA DEL TEMPO: le ere in
	# fila, si sceglie la più antica o la più recente.
	"storia": [
		{"topic": "ere", "minLevel": 4, "answer": "preistoria",
			"prompt": "Questa è la linea del tempo delle grandi età. Quale era è la più antica, all'inizio di tutto?",
			"components": [{"id": "preistoria", "x": 0.10, "y": 0.50, "label": "Preistoria"}, {"id": "antica", "x": 0.32, "y": 0.50, "label": "Età antica"}, {"id": "medioevo", "x": 0.55, "y": 0.50, "label": "Medioevo"}, {"id": "moderna", "x": 0.77, "y": 0.50, "label": "Età moderna"}, {"id": "contemporanea", "x": 0.95, "y": 0.50, "label": "Contemporanea"}],
			"connections": [["preistoria", "antica"], ["antica", "medioevo"], ["medioevo", "moderna"], ["moderna", "contemporanea"]],
			"explanation": "La Preistoria è la più antica: è la prima era, prima ancora della scrittura."},
		{"topic": "ere", "minLevel": 5, "answer": "contemporanea",
			"prompt": "In questa linea del tempo, quale era è la più recente, quella in cui viviamo?",
			"components": [{"id": "preistoria", "x": 0.10, "y": 0.50, "label": "Preistoria"}, {"id": "antica", "x": 0.32, "y": 0.50, "label": "Età antica"}, {"id": "medioevo", "x": 0.55, "y": 0.50, "label": "Medioevo"}, {"id": "moderna", "x": 0.77, "y": 0.50, "label": "Età moderna"}, {"id": "contemporanea", "x": 0.95, "y": 0.50, "label": "Contemporanea"}],
			"connections": [["preistoria", "antica"], ["antica", "medioevo"], ["medioevo", "moderna"], ["moderna", "contemporanea"]],
			"explanation": "L'Età contemporanea è l'ultima della linea: è quella in cui viviamo oggi."},
	],
	# MUSICA — il renderer nodi+collegamenti diventa la FORMA DI UNA CANZONE: le
	# sezioni in fila, si riconosce quella che torna uguale (il ritornello).
	"musica": [
		{"topic": "lettura", "minLevel": 4, "answer": "ritornello2",
			"prompt": "Questa è la struttura di una canzone. Quale sezione RIPETE il ritornello già sentito?",
			"components": [{"id": "strofa1", "x": 0.12, "y": 0.50, "label": "Strofa"}, {"id": "ritornello1", "x": 0.34, "y": 0.50, "label": "Ritornello"}, {"id": "strofa2", "x": 0.56, "y": 0.50, "label": "Strofa 2"}, {"id": "ritornello2", "x": 0.78, "y": 0.50, "label": "Ritornello"}, {"id": "finale", "x": 0.95, "y": 0.50, "label": "Finale"}],
			"connections": [["strofa1", "ritornello1"], ["ritornello1", "strofa2"], ["strofa2", "ritornello2"], ["ritornello2", "finale"]],
			"explanation": "Il ritornello è la parte che torna uguale: qui è il secondo 'Ritornello', che ripete il primo."},
		{"topic": "lettura", "minLevel": 5, "answer": "ponte",
			"prompt": "In questa struttura, quale sezione è il PONTE, quella diversa che appare una volta sola tra due ritornelli?",
			"components": [{"id": "strofa", "x": 0.10, "y": 0.50, "label": "Strofa"}, {"id": "ritornello1", "x": 0.32, "y": 0.50, "label": "Ritornello"}, {"id": "ponte", "x": 0.55, "y": 0.50, "label": "Ponte"}, {"id": "ritornello2", "x": 0.78, "y": 0.50, "label": "Ritornello"}, {"id": "finale", "x": 0.95, "y": 0.50, "label": "Finale"}],
			"connections": [["strofa", "ritornello1"], ["ritornello1", "ponte"], ["ponte", "ritornello2"], ["ritornello2", "finale"]],
			"explanation": "Il ponte è la sezione nuova che compare una sola volta, tra i due ritornelli: crea varietà."},
	],
	# LATINO — il renderer nodi+collegamenti diventa un ALBERO DELL'ETIMOLOGIA: una
	# radice latina al centro e le parole italiane che ne derivano. Si sceglie la
	# radice comune: il latino che vive ancora nell'italiano.
	"latino": [
		{"topic": "etimologia", "minLevel": 4, "answer": "aqua",
			"prompt": "Queste parole italiane derivano tutte dalla stessa radice latina. Qual è la radice comune?",
			"components": [{"id": "aqua", "x": 0.50, "y": 0.20, "label": "aqua"}, {"id": "acqua", "x": 0.18, "y": 0.65, "label": "acqua"}, {"id": "acquedotto", "x": 0.50, "y": 0.82, "label": "acquedotto"}, {"id": "acquario", "x": 0.82, "y": 0.65, "label": "acquario"}],
			"connections": [["aqua", "acqua"], ["aqua", "acquedotto"], ["aqua", "acquario"]],
			"explanation": "La radice è 'aqua' (acqua in latino): da lì nascono acqua, acquedotto, acquario."},
		{"topic": "etimologia", "minLevel": 6, "answer": "terra",
			"prompt": "Anche queste parole italiane vengono dalla stessa radice latina. Qual è la radice comune?",
			"components": [{"id": "terra", "x": 0.50, "y": 0.20, "label": "terra"}, {"id": "territorio", "x": 0.18, "y": 0.65, "label": "territorio"}, {"id": "terrestre", "x": 0.50, "y": 0.82, "label": "terrestre"}, {"id": "sotterraneo", "x": 0.82, "y": 0.65, "label": "sotterraneo"}],
			"connections": [["terra", "territorio"], ["terra", "terrestre"], ["terra", "sotterraneo"]],
			"explanation": "La radice è 'terra': da lì nascono territorio, terrestre e sotterraneo."},
	],
	# INGLESE — il renderer nodi+collegamenti diventa un ALBERO DELLE PAROLE: una
	# parola base e le parole inglesi che ne derivano (morfologia). Si sceglie la
	# base comune.
	"inglese": [
		{"topic": "word-family", "minLevel": 5, "answer": "play",
			"prompt": "These English words belong to the same family. Which is the base word (the root)?",
			"components": [{"id": "play", "x": 0.50, "y": 0.20, "label": "play"}, {"id": "player", "x": 0.18, "y": 0.65, "label": "player"}, {"id": "playful", "x": 0.50, "y": 0.82, "label": "playful"}, {"id": "playground", "x": 0.82, "y": 0.65, "label": "playground"}],
			"connections": [["play", "player"], ["play", "playful"], ["play", "playground"]],
			"explanation": "The base word is 'play': player, playful and playground all come from it."},
		{"topic": "word-family", "minLevel": 6, "answer": "help",
			"prompt": "These words share the same root. Which is the base word?",
			"components": [{"id": "help", "x": 0.50, "y": 0.20, "label": "help"}, {"id": "helper", "x": 0.20, "y": 0.68, "label": "helper"}, {"id": "helpful", "x": 0.52, "y": 0.84, "label": "helpful"}, {"id": "helpless", "x": 0.82, "y": 0.66, "label": "helpless"}],
			"connections": [["help", "helper"], ["help", "helpful"], ["help", "helpless"]],
			"explanation": "The base word is 'help': helper, helpful and helpless are built from it."},
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
		{"topic": "frazioni", "minLevel": 7, "answerLine": 3,
			"prompt": "Calcolo di 3/4 di 20: quale riga sbaglia?",
			"codeLines": ["3/4 di 20", "= 20 : 4 × 3", "= 5 × 3 = 12", "# l'impostazione è giusta: e il conto finale?"],
			"explanation": "Riga 3: 5 × 3 fa 15, non 12. Dividere per il denominatore e moltiplicare per il numeratore era la strada giusta."},
	],
	# INGLESE — "Find the mistake": error correction, il cuore dell'apprendimento
	# di una lingua straniera. Una frase su tante nasconde lo sbaglio: si clicca.
	"inglese": [
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
		{"topic": "legge-ohm", "minLevel": 6, "answerLine": 2, "shuffleLines": true,
			"prompt": "Corrente con V = 10 V e R = 2 Ω: quale riga sbaglia?",
			"codeLines": ["V = 10 V, R = 2 Ω", "I = V × R", "I = 20 A", "# come si calcola la corrente?"],
			"explanation": "Riga 2: la legge di Ohm è I = V / R (10 / 2 = 5 A), non V × R (che darebbe 20)."},
	],
	# SCIENZE — "Caccia all'errore": fra tre affermazioni una è falsa. Colpisce le
	# misconcezioni classiche (la Luna, le branchie, il vapore).
	"scienze": [
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
	],
	# FISICA — "Caccia all'errore": affermazione falsa o calcolo sbagliato. Colpisce
	# le misconcezioni classiche (Galileo, la formula della velocità, l'energia).
	"fisica": [
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
	],
	# GEOGRAFIA — "Caccia all'errore": fra tre affermazioni una è falsa.
	"geografia": [
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

const FORMATS := ["matching", "ordering", "classification", "graph", "circuit", "code_debug"]

static func table_for(fmt: String) -> Dictionary:
	match fmt:
		"matching": return MATCHING
		"ordering": return ORDERING
		"classification": return CLASSIFICATION
		"graph": return GRAPH
		"circuit": return CIRCUIT
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

static func difficulty_for(level: int, idx: int, total: int) -> int:
	return difficulty_of(level, gradient_step(idx, total))

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
const DEFAULT_SEQUENCE_DRAW := 5

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
	# Grafico, circuito e caccia all'errore sono ancora dati fissi: una specifica,
	# una prova. Il rimescolamento delle righe cambia la presentazione, non la
	# prova (vedi `ExerciseSignature`), quindi non conta come profondità.
	return 1

static func format_depth(subject: String, fmt: String, level: int) -> int:
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
	# Prima campata: preferisci un abbinamento (più ricco); ripiega su ordinamento.
	if has_match:
		plan.append("matching")
	elif numeric:
		plan.append("numeric")
	elif has_order:
		plan.append("ordering")
	# Seconda campata: preferisci un formato DIVERSO per varietà.
	if numeric:
		plan.append("numeric")
	elif has_order:
		plan.append("ordering")
	elif has_match:
		plan.append("matching")
	# Terza campata (se disponibile): smistamento drag-to-sort — il formato più
	# distante da abbinamento/ordinamento, per esercizi davvero vari (#11).
	if has_classify:
		plan.append("classification")
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
	if CODE_DEBUG.has(subject) and _has_eligible(CODE_DEBUG[subject], level):
		specialists.append("code_debug")
	if not specialists.is_empty():
		plan.append(str(specialists[generator.randi_range(0, specialists.size() - 1)]))
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
		"explanation": "Collega ogni elemento a sinistra con quello giusto a destra.",
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
		"explanation": "Ogni tessera va nel gruppo giusto secondo la sua proprietà.",
	}

func _graph_node(subject: String, spec: Dictionary, difficulty: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-graph-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "graph",
		"prompt": str(spec["prompt"]),
		"points": (spec["points"] as Array).duplicate(true),
		"xLabel": str(spec.get("xLabel", "x")),
		"yLabel": str(spec.get("yLabel", "y")),
		"answer": str(spec["answer"]),
		"explanation": str(spec["explanation"]),
	}

func _circuit_node(subject: String, spec: Dictionary, difficulty: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-circuit-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": difficulty,
		"format": "circuit",
		"prompt": str(spec["prompt"]),
		"components": (spec["components"] as Array).duplicate(true),
		"connections": (spec["connections"] as Array).duplicate(true),
		"answer": str(spec["answer"]),
		"explanation": str(spec["explanation"]),
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
		"explanation": "Ordine giusto: %s." % ", ".join(PackedStringArray(correct)),
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
		"explanation": "Ordine giusto: %s." % ", ".join(PackedStringArray(worked)),
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
