class_name MinigameManager
extends RefCounted

## Costruisce sessioni-MINIGIOCO risolte con le competenze delle materie. Due
## formati interattivi (resi da ExercisePlayer): "matching" (abbina le coppie) e
## "ordering" (metti in ordine). Riusa il contratto di sessione di ContentManager
## (nodi con topic/difficoltà) così mastery per-topic, energia e adattività
## restano identici. I contenuti sono curati per correttezza; l'ordinamento
## numerico è generato e tarato sul livello.

# Coppie da abbinare, per materia → gruppi tematici (topic + lista [sinistra, destra]).
const MATCHING := {
	"inglese": [
		{"topic": "vocabolario", "pairs": [["dog", "cane"], ["cat", "gatto"], ["sun", "sole"], ["house", "casa"], ["water", "acqua"], ["book", "libro"], ["tree", "albero"], ["red", "rosso"]]},
		{"topic": "vocabolario", "pairs": [["one", "uno"], ["two", "due"], ["three", "tre"], ["four", "quattro"], ["five", "cinque"], ["ten", "dieci"]]},
		{"topic": "opposites", "minLevel": 3, "pairs": [["hot", "cold"], ["big", "small"], ["fast", "slow"], ["happy", "sad"], ["old", "new"]]},
		# Conversazione: micro-scambi domanda -> risposta.
		{"topic": "conversation", "minLevel": 5, "pairs": [["What's your name?", "I'm Anna"], ["How old are you?", "I'm ten"], ["Where are you from?", "From Italy"], ["How are you?", "I'm fine"]]},
		# Scuola media — le forme che l'inglese non regolarizza.
		{"topic": "contractions", "minLevel": 6, "pairs": [["I am", "I'm"], ["you are", "you're"], ["do not", "don't"], ["cannot", "can't"], ["it is", "it's"]]},
		{"topic": "irregular-past", "minLevel": 7, "pairs": [["go", "went"], ["eat", "ate"], ["see", "saw"], ["have", "had"], ["make", "made"]]},
		{"topic": "irregular-plural", "minLevel": 8, "pairs": [["child", "children"], ["man", "men"], ["foot", "feet"], ["mouse", "mice"], ["tooth", "teeth"]]},
	],
	"geografia": [
		{"topic": "capitali", "pairs": [["Italia", "Roma"], ["Francia", "Parigi"], ["Spagna", "Madrid"], ["Germania", "Berlino"], ["Portogallo", "Lisbona"], ["Grecia", "Atene"]]},
		{"topic": "continenti", "pairs": [["Egitto", "Africa"], ["Brasile", "America del Sud"], ["Giappone", "Asia"], ["Italia", "Europa"], ["Australia", "Oceania"]]},
	],
	"scienze": [
		{"topic": "corpo", "pairs": [["Cuore", "Pompa il sangue"], ["Polmoni", "Respirazione"], ["Cervello", "Comanda il corpo"], ["Stomaco", "Digestione"], ["Occhi", "Vista"]]},
		{"topic": "viventi", "pairs": [["Erbivoro", "Mangia piante"], ["Carnivoro", "Mangia animali"], ["Onnivoro", "Mangia tutto"], ["Decompositore", "Ricicla i resti"]]},
	],
	"latino": [
		{"topic": "casi", "pairs": [["Nominativo", "Soggetto"], ["Accusativo", "Oggetto"], ["Genitivo", "Specificazione"], ["Dativo", "Termine"], ["Vocativo", "Invocazione"]]},
		{"topic": "vocabolario", "pairs": [["aqua", "acqua"], ["silva", "bosco"], ["puella", "fanciulla"], ["lupus", "lupo"], ["terra", "terra"]]},
	],
	"musica": [
		{"topic": "ritmo", "pairs": [["Semibreve", "4 battiti"], ["Minima", "2 battiti"], ["Semiminima", "1 battito"], ["Croma", "mezzo battito"]]},
		{"topic": "strumenti", "pairs": [["Chitarra", "Corde"], ["Flauto", "Fiato"], ["Tamburo", "Percussione"], ["Pianoforte", "Tastiera"]]},
	],
	"italiano": [
		{"topic": "contrari", "pairs": [["alto", "basso"], ["grande", "piccolo"], ["giorno", "notte"], ["caldo", "freddo"], ["veloce", "lento"]]},
		{"topic": "categorie", "pairs": [["correre", "verbo"], ["gatto", "nome"], ["rosso", "aggettivo"], ["velocemente", "avverbio"]]},
		{"topic": "sinonimi", "pairs": [["felice", "contento"], ["veloce", "rapido"], ["bello", "stupendo"], ["triste", "malinconico"], ["furbo", "astuto"]]},
		{"topic": "definizioni", "minLevel": 7, "pairs": [["effimero", "che dura poco"], ["arduo", "molto difficile"], ["placido", "calmo e tranquillo"], ["arguto", "acuto e spiritoso"], ["tenace", "che non si arrende"]]},
		{"topic": "modi-di-dire", "minLevel": 6, "pairs": [["In bocca al lupo", "Buona fortuna"], ["Tagliare la corda", "Scappare via"], ["Avere le mani in pasta", "Essere coinvolti"], ["Costare un occhio", "Essere carissimo"], ["Perdere la testa", "Innamorarsi o agitarsi"]]},
		{"topic": "figure-retoriche", "minLevel": 8, "pairs": [["Veloce come il vento", "Similitudine"], ["Il sole sorride nel cielo", "Personificazione"], ["Ho un mare di compiti", "Iperbole"], ["Che silenzio assordante", "Ossimoro"]]},
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
	"cittadinanza": [
		{"topic": "istituzioni", "pairs": [["Sindaco", "Comune"], ["Parlamento", "Fa le leggi"], ["Costituzione", "Legge fondamentale"], ["Voto", "Scelta dei rappresentanti"]]},
		{"topic": "diritti-doveri", "pairs": [["Studiare", "Diritto e dovere"], ["Curarsi", "Diritto"], ["Rispettare l'ambiente", "Dovere"]]},
	],
	"coding": [
		{"topic": "tipi", "pairs": [["7", "intero"], ["'ciao'", "stringa"], ["True", "booleano"], ["[1, 2, 3]", "lista"]]},
		{"topic": "operatori", "pairs": [["+", "somma"], ["*", "moltiplicazione"], ["%", "resto"], ["**", "potenza"]]},
	],
	"elettronica": [
		{"topic": "componenti", "pairs": [["Pila", "Fornisce energia"], ["Interruttore", "Apre e chiude"], ["Resistore", "Limita la corrente"], ["LED", "Emette luce"]]},
		{"topic": "misure-elettriche", "pairs": [["Tensione", "Volt"], ["Corrente", "Ampere"], ["Resistenza", "Ohm"]]},
	],
	"fisica": [
		{"topic": "misure", "pairs": [["Lunghezza", "Metro"], ["Massa", "Chilogrammo"], ["Tempo", "Secondo"], ["Temperatura", "Grado"]]},
		{"topic": "energia", "pairs": [["Palla in alto", "Energia potenziale"], ["Palla che cade", "Energia cinetica"], ["Cibo", "Energia chimica"], ["Lampadina accesa", "Energia luminosa"]]},
	],
	"matematica": [
		{"topic": "tabelline", "pairs": [["3 × 4", "12"], ["6 × 7", "42"], ["8 × 5", "40"], ["9 × 3", "27"]]},
		{"topic": "calcolo", "pairs": [["10 + 5", "15"], ["20 - 8", "12"], ["4 × 4", "16"], ["18 ÷ 3", "6"], ["7 + 6", "13"]]},
		# Fluenza tra rappresentazioni: la stessa quantità in forme diverse (idea CPA).
		{"topic": "frazioni", "minLevel": 4, "pairs": [["1/2", "0,5"], ["1/4", "0,25"], ["3/4", "0,75"], ["1/5", "0,2"]]},
		{"topic": "percentuali", "minLevel": 5, "pairs": [["1/2", "50%"], ["1/4", "25%"], ["1/5", "20%"], ["3/4", "75%"]]},
		# Scuola media — potenze e formule di geometria.
		{"topic": "potenze", "minLevel": 6, "pairs": [["2³", "8"], ["3²", "9"], ["5²", "25"], ["10³", "1000"]]},
		{"topic": "geometria", "minLevel": 5, "pairs": [["Area del quadrato", "lato × lato"], ["Perimetro del rettangolo", "(base + altezza) × 2"], ["Area del triangolo", "base × altezza ÷ 2"], ["Area del cerchio", "π × raggio²"]]},
	],
	"logica": [
		{"topic": "analogie", "pairs": [["Cane", "Cuccia"], ["Uccello", "Nido"], ["Ape", "Alveare"], ["Pesce", "Acqua"], ["Cavallo", "Stalla"]]},
	],
}

# Sequenze da ordinare, per materia (l'ordine dato è quello CORRETTO).
const ORDERING := {
	"scienze": [
		{"topic": "viventi", "prompt": "Metti in ordine le fasi della farfalla", "correctOrder": ["Uovo", "Bruco", "Crisalide", "Farfalla"]},
		{"topic": "materia", "prompt": "Ordina per temperatura crescente", "correctOrder": ["Ghiaccio", "Acqua fredda", "Acqua calda", "Vapore"]},
	],
	"geografia": [
		{"topic": "geografia-umana", "prompt": "Ordina dal più piccolo al più grande", "correctOrder": ["Paese", "Regione", "Nazione", "Continente"]},
	],
	"musica": [
		{"topic": "note", "prompt": "Metti in ordine le note dopo il Do", "correctOrder": ["Re", "Mi", "Fa", "Sol"]},
		{"topic": "ritmo", "prompt": "Ordina dalla durata più breve alla più lunga", "correctOrder": ["Croma", "Semiminima", "Minima", "Semibreve"]},
	],
	"italiano": [
		{"topic": "ortografia", "prompt": "Metti in ordine alfabetico", "correctOrder": ["albero", "casa", "fiore", "sole"]},
		{"topic": "sintassi", "prompt": "Riordina le parole per formare una frase corretta.", "correctOrder": ["Il", "gatto", "dorme", "sul", "divano"]},
		{"topic": "sintassi", "prompt": "Riordina le parole per formare una frase corretta.", "correctOrder": ["Domani", "andremo", "tutti", "al", "mare"]},
		{"topic": "testo-narrativo", "prompt": "Metti in ordine gli eventi della storia.", "correctOrder": ["C'era una volta un re", "Il re partì per un lungo viaggio", "Incontrò un drago feroce", "Con astuzia lo sconfisse", "Tornò a casa vittorioso"]},
	],
	"coding": [
		{"topic": "algoritmi", "prompt": "Ordina i passi del programma", "correctOrder": ["Chiedi il numero", "Controlla se è pari", "Se è pari stampa 'pari'", "Altrimenti stampa 'dispari'"]},
	],
	"cittadinanza": [
		{"topic": "partecipazione", "prompt": "Ordina come nasce una legge", "correctOrder": ["Si propone una legge", "Si discute in Parlamento", "Si vota", "La legge entra in vigore"]},
	],
	"latino": [
		{"topic": "frasi", "prompt": "Ordina la frase latina (soggetto, oggetto, verbo): «la fanciulla ama la rosa»", "correctOrder": ["Puella", "rosam", "amat"]},
	],
	"inglese": [
		{"topic": "everyday-phrases", "prompt": "Order the words to make a sentence", "correctOrder": ["I", "like", "green", "apples"]},
		# Word order inglese: soggetto-verbo-oggetto e adjective prima del nome.
		{"topic": "sentence", "minLevel": 3, "prompt": "Order the words to make a sentence.", "correctOrder": ["She", "reads", "a", "book"]},
		{"topic": "negative", "minLevel": 5, "prompt": "Order the words to make a negative sentence.", "correctOrder": ["He", "does", "not", "play"]},
		# Domande: inversione dell'ausiliare (diverso dall'italiano).
		{"topic": "question", "minLevel": 5, "prompt": "Order the words to make a question.", "correctOrder": ["Do", "you", "like", "pizza?"]},
		{"topic": "wh-question", "minLevel": 6, "prompt": "Order the words to make a question.", "correctOrder": ["Where", "do", "you", "live?"]},
	],
	"fisica": [
		{"topic": "moto", "prompt": "Ordina per velocità crescente", "correctOrder": ["Lumaca", "Persona a piedi", "Bicicletta", "Automobile"]},
	],
	"elettronica": [
		{"topic": "misure-elettriche", "prompt": "Ordina le tensioni dalla più piccola", "correctOrder": ["1 V", "5 V", "12 V", "220 V"]},
	],
}

# Smistamento in categorie (drag-to-sort), per materia. Ogni item ha UNA categoria
# corretta (`assignments`); il renderer classification li fa trascinare nei bidoni.
# Formato testuale ad alto coinvolgimento, senza asset (playthrough #11).
const CLASSIFICATION := {
	"italiano": [
		{"topic": "categorie", "prompt": "Smista ogni parola nella sua classe grammaticale.",
			"categories": ["nome", "verbo", "aggettivo", "avverbio"],
			"assignments": {"gatto": "nome", "casa": "nome", "correre": "verbo", "saltare": "verbo", "rosso": "aggettivo", "felice": "aggettivo", "velocemente": "avverbio", "lentamente": "avverbio"}},
		{"topic": "pensiero-linguaggio", "prompt": "Smista ogni parola: singolare o plurale?",
			"categories": ["singolare", "plurale"],
			"assignments": {"libro": "singolare", "fiore": "singolare", "casa": "singolare", "libri": "plurale", "fiori": "plurale", "case": "plurale"}},
		{"topic": "verbo", "prompt": "Smista ogni verbo nel suo tempo.",
			"categories": ["passato", "presente", "futuro"],
			"assignments": {"ho letto": "passato", "mangiai": "passato", "corro": "presente", "gioca": "presente", "andrò": "futuro", "vedremo": "futuro"}},
		{"topic": "lessico", "prompt": "Smista ogni nome: concreto o astratto?",
			"categories": ["concreto", "astratto"],
			"assignments": {"tavolo": "concreto", "cane": "concreto", "montagna": "concreto", "amore": "astratto", "libertà": "astratto", "coraggio": "astratto"}},
		# Scuola media — tempi dell'indicativo con i loro nomi.
		{"topic": "tempi-indicativo", "minLevel": 9, "prompt": "Smista ogni voce verbale nel suo tempo dell'indicativo.",
			"categories": ["presente", "imperfetto", "passato prossimo", "futuro"],
			"assignments": {"mangio": "presente", "leggo": "presente", "mangiavo": "imperfetto", "leggevo": "imperfetto", "ho mangiato": "passato prossimo", "ho letto": "passato prossimo", "mangerò": "futuro", "leggerò": "futuro"}},
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
		{"topic": "viventi", "prompt": "Smista ogni animale per come si nutre.",
			"categories": ["erbivoro", "carnivoro", "onnivoro"],
			"assignments": {"Mucca": "erbivoro", "Coniglio": "erbivoro", "Leone": "carnivoro", "Lupo": "carnivoro", "Orso": "onnivoro", "Maiale": "onnivoro"}},
		{"topic": "ecosistema", "prompt": "Smista ogni animale nel suo ambiente.",
			"categories": ["acqua", "aria", "terra"],
			"assignments": {"Pesce": "acqua", "Delfino": "acqua", "Aquila": "aria", "Rondine": "aria", "Talpa": "terra", "Lombrico": "terra"}},
	],
	"coding": [
		{"topic": "tipi", "prompt": "Smista ogni valore nel suo tipo di dato.",
			"categories": ["intero", "stringa", "booleano", "lista"],
			"assignments": {"7": "intero", "42": "intero", "'ciao'": "stringa", "'sole'": "stringa", "True": "booleano", "False": "booleano", "[1, 2]": "lista", "[3, 4, 5]": "lista"}},
		{"topic": "operatori", "prompt": "Smista ogni operatore nella sua famiglia.",
			"categories": ["aritmetico", "confronto", "logico"],
			"assignments": {"+": "aritmetico", "*": "aritmetico", ">": "confronto", "==": "confronto", "and": "logico", "or": "logico"}},
	],
	"cittadinanza": [
		{"topic": "diritti-doveri", "prompt": "Smista ciascuna azione: diritto o dovere?",
			"categories": ["diritto", "dovere"],
			"assignments": {"Curarsi": "diritto", "Esprimere la propria opinione": "diritto", "Essere istruiti": "diritto", "Pagare le tasse": "dovere", "Rispettare l'ambiente": "dovere", "Rispettare le regole": "dovere"}},
		{"topic": "istituzioni", "prompt": "Smista ogni istituzione per il suo livello.",
			"categories": ["locale", "nazionale"],
			"assignments": {"Sindaco": "locale", "Comune": "locale", "Consiglio comunale": "locale", "Parlamento": "nazionale", "Governo": "nazionale", "Presidente della Repubblica": "nazionale"}},
	],
	"geografia": [
		{"topic": "continenti", "prompt": "Smista ogni Paese nel suo continente.",
			"categories": ["Africa", "Europa", "Asia", "America"],
			"assignments": {"Egitto": "Africa", "Kenya": "Africa", "Italia": "Europa", "Francia": "Europa", "Giappone": "Asia", "Cina": "Asia", "Brasile": "America", "Canada": "America"}},
		{"topic": "geografia-fisica", "prompt": "Smista ogni elemento: d'acqua o di terra?",
			"categories": ["acqua", "terra"],
			"assignments": {"Fiume": "acqua", "Lago": "acqua", "Mare": "acqua", "Montagna": "terra", "Pianura": "terra", "Collina": "terra"}},
	],
	"matematica": [
		{"topic": "numeri", "prompt": "Smista i numeri in pari e dispari.",
			"categories": ["pari", "dispari"],
			"assignments": {"4": "pari", "8": "pari", "12": "pari", "7": "dispari", "15": "dispari", "21": "dispari"}},
		{"topic": "calcolo", "prompt": "Smista ogni numero: minore di 10 oppure 10 o più.",
			"categories": ["minore di 10", "10 o più"],
			"assignments": {"3": "minore di 10", "6": "minore di 10", "9": "minore di 10", "10": "10 o più", "14": "10 o più", "23": "10 o più"}},
		# Il segno "=" come bilancia: l'uguaglianza è vera o falsa? (misconcezione classica)
		{"topic": "uguaglianze", "minLevel": 2, "prompt": "Ogni uguaglianza è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {"3 + 4 = 7": "vera", "10 - 6 = 4": "vera", "2 × 5 = 10": "vera", "5 + 3 = 9": "falsa", "12 ÷ 3 = 5": "falsa", "6 × 2 = 10": "falsa"}},
		{"topic": "multipli", "minLevel": 3, "prompt": "Smista: è multiplo di 3 oppure no?",
			"categories": ["multiplo di 3", "non multiplo"],
			"assignments": {"9": "multiplo di 3", "12": "multiplo di 3", "15": "multiplo di 3", "7": "non multiplo", "10": "non multiplo", "14": "non multiplo"}},
		# Scuola media — numeri primi, frazioni rispetto a 1/2, interi.
		{"topic": "primi", "minLevel": 5, "prompt": "Smista ogni numero: primo o composto?",
			"categories": ["primo", "composto"],
			"assignments": {"2": "primo", "5": "primo", "7": "primo", "4": "composto", "6": "composto", "9": "composto"}},
		{"topic": "frazioni", "minLevel": 6, "prompt": "Smista ogni frazione rispetto a 1/2.",
			"categories": ["minore di 1/2", "uguale a 1/2", "maggiore di 1/2"],
			"assignments": {"1/4": "minore di 1/2", "1/3": "minore di 1/2", "2/4": "uguale a 1/2", "3/6": "uguale a 1/2", "3/4": "maggiore di 1/2", "5/6": "maggiore di 1/2"}},
		{"topic": "interi", "minLevel": 6, "prompt": "Smista ogni numero intero: positivo o negativo?",
			"categories": ["positivo", "negativo"],
			"assignments": {"5": "positivo", "12": "positivo", "3": "positivo", "-3": "negativo", "-8": "negativo", "-1": "negativo"}},
	],
	"fisica": [
		{"topic": "energia", "prompt": "Smista ogni situazione per l'energia prevalente.",
			"categories": ["potenziale", "cinetica"],
			"assignments": {"Palla in cima a una rampa": "potenziale", "Molla compressa": "potenziale", "Palla che rotola": "cinetica", "Auto in corsa": "cinetica"}},
		{"topic": "materia", "prompt": "Smista ogni materiale nel suo stato.",
			"categories": ["solido", "liquido", "gassoso"],
			"assignments": {"Ghiaccio": "solido", "Ferro": "solido", "Acqua": "liquido", "Latte": "liquido", "Vapore": "gassoso", "Aria": "gassoso"}},
	],
	"musica": [
		{"topic": "strumenti", "prompt": "Smista ogni strumento nella sua famiglia.",
			"categories": ["corde", "fiati", "percussioni"],
			"assignments": {"Chitarra": "corde", "Violino": "corde", "Flauto": "fiati", "Tromba": "fiati", "Tamburo": "percussioni", "Timpani": "percussioni"}},
		{"topic": "timbro", "prompt": "Smista ogni strumento: acustico o elettronico?",
			"categories": ["acustico", "elettronico"],
			"assignments": {"Violino": "acustico", "Chitarra classica": "acustico", "Pianoforte": "acustico", "Sintetizzatore": "elettronico", "Tastiera elettronica": "elettronico", "Batteria elettronica": "elettronico"}},
	],
	"elettronica": [
		{"topic": "conduttori", "prompt": "Smista ogni materiale: conduttore o isolante?",
			"categories": ["conduttore", "isolante"],
			"assignments": {"Rame": "conduttore", "Ferro": "conduttore", "Alluminio": "conduttore", "Plastica": "isolante", "Legno": "isolante", "Gomma": "isolante"}},
		{"topic": "componenti", "prompt": "Smista ogni componente: dà energia o la usa?",
			"categories": ["fornisce energia", "usa energia"],
			"assignments": {"Pila": "fornisce energia", "Batteria": "fornisce energia", "LED": "usa energia", "Motorino": "usa energia", "Lampadina": "usa energia", "Cella solare": "fornisce energia"}},
	],
	"inglese": [
		{"topic": "categorie", "prompt": "Sort each word into its category.",
			"categories": ["animals", "food", "colours", "actions"],
			"assignments": {"dog": "animals", "cat": "animals", "apple": "food", "bread": "food", "red": "colours", "blue": "colours", "run": "actions", "jump": "actions"}},
		{"topic": "home-family", "prompt": "Sort each word: family, school or nature.",
			"categories": ["family", "school", "nature"],
			"assignments": {"mother": "family", "father": "family", "teacher": "school", "book": "school", "tree": "nature", "river": "nature"}},
		# Articolo a/an secondo il suono iniziale: regola tipica dell'inglese.
		{"topic": "articles", "minLevel": 5, "prompt": "Sort each word: does it take 'a' or 'an'?",
			"categories": ["a", "an"],
			"assignments": {"apple": "an", "orange": "an", "umbrella": "an", "dog": "a", "car": "a", "book": "a"}},
		{"topic": "parts-of-speech", "minLevel": 6, "prompt": "Sort each word into its part of speech.",
			"categories": ["noun", "verb", "adjective"],
			"assignments": {"dog": "noun", "house": "noun", "run": "verb", "eat": "verb", "big": "adjective", "red": "adjective"}},
		# Scuola media — verbi regolari/irregolari e nomi numerabili/non numerabili.
		{"topic": "verbs", "minLevel": 8, "prompt": "Sort each past-tense verb: regular or irregular?",
			"categories": ["regular", "irregular"],
			"assignments": {"played": "regular", "walked": "regular", "watched": "regular", "went": "irregular", "ate": "irregular", "saw": "irregular"}},
		{"topic": "nouns", "minLevel": 9, "prompt": "Sort each noun: countable or uncountable?",
			"categories": ["countable", "uncountable"],
			"assignments": {"apple": "countable", "book": "countable", "car": "countable", "water": "uncountable", "milk": "uncountable", "rice": "uncountable"}},
	],
	"latino": [
		{"topic": "vocabolario", "prompt": "Smista ogni parola latina per campo di significato.",
			"categories": ["natura", "persone", "animali"],
			"assignments": {"aqua": "natura", "silva": "natura", "terra": "natura", "puella": "persone", "poeta": "persone", "lupus": "animali", "equus": "animali"}},
	],
	"logica": [
		{"topic": "esclusioni", "prompt": "Smista ogni elemento nel suo insieme.",
			"categories": ["animale", "pianta"],
			"assignments": {"Cane": "animale", "Aquila": "animale", "Gatto": "animale", "Rosa": "pianta", "Quercia": "pianta", "Tulipano": "pianta"}},
	],
}

# Lettura di GRAFICO (assi + curva disegnati proceduralmente): scegli il punto
# richiesto. Nessun asset immagine. `points` in coordinate normalizzate 0..1.
const GRAPH := {
	"fisica": [
		{"topic": "moto", "xLabel": "tempo", "yLabel": "velocità", "answer": "C",
			"prompt": "Il grafico mostra la velocità nel tempo: in quale punto è massima?",
			"points": [{"id": "A", "x": 0.10, "y": 0.20, "label": "A"}, {"id": "B", "x": 0.35, "y": 0.55, "label": "B"}, {"id": "C", "x": 0.60, "y": 0.92, "label": "C"}, {"id": "D", "x": 0.88, "y": 0.50, "label": "D"}],
			"explanation": "La velocità è massima dove la curva è più in alto: il punto C."},
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
	],
}

# CODE-DEBUG (righe numerate selezionabili): trova la riga con l'errore. Testo puro.
const CODE_DEBUG := {
	"coding": [
		{"topic": "cicli", "answerLine": 2,
			"prompt": "Dovrebbe stampare 1, 2, 3. Quale riga contiene l'errore?",
			"codeLines": ["for i in [1, 2, 3]:", "    print(i + 1)", "# atteso: 1, 2, 3"],
			"explanation": "La riga 2 stampa i+1 (2, 3, 4): va corretta in print(i)."},
		{"topic": "condizioni", "answerLine": 1,
			"prompt": "Vogliamo salutare solo se il nome NON è vuoto. Quale riga sbaglia?",
			"codeLines": ["if nome == \"\":", "    print('Ciao ' + nome)", "# salutare solo se c'è un nome"],
			"explanation": "La riga 1 controlla se il nome È vuoto: la condizione va invertita (nome != '')."},
	],
	"logica": [
		{"topic": "deduzioni", "answerLine": 3,
			"prompt": "Segui la deduzione: quale passo è sbagliato?",
			"codeLines": ["Tutti i gatti sono felini.", "Alcuni felini sono neri.", "Quindi tutti i gatti sono neri.", "# dove si rompe il ragionamento?"],
			"explanation": "La riga 3 generalizza indebitamente: da 'alcuni felini neri' non segue 'tutti i gatti neri'."},
	],
	# ITALIANO — "Caccia all'errore": fra più frasi corrette, una nasconde uno
	# sbaglio (ortografia, accordo, tempo verbale). Si clicca la riga sbagliata: la
	# correzione di bozze come sfida, ben più coinvolgente della scelta multipla.
	"italiano": [
		{"topic": "ortografia", "answerLine": 3,
			"prompt": "Una frase contiene un errore di ortografia. Quale riga?",
			"codeLines": ["Bevo un po' d'acqua fresca.", "Qual è il tuo colore preferito?", "A scuola studio la sciensa.", "# tutte tranne una sono corrette"],
			"explanation": "Riga 3: si scrive 'scienza' con -sci-, non 'sciensa'. ('un po'' e 'qual è' sono invece corretti)."},
		{"topic": "morfologia", "answerLine": 2,
			"prompt": "Una frase ha un errore di accordo (genere o numero). Quale riga?",
			"codeLines": ["I bambini giocano in giardino.", "La macchina rosse è veloce.", "Le case sono grandi e luminose.", "# trova l'accordo sbagliato"],
			"explanation": "Riga 2: 'macchina' è singolare femminile, quindi 'rossa', non 'rosse'."},
		{"topic": "verbo", "answerLine": 3,
			"prompt": "Una frase sbaglia il tempo del verbo. Quale riga?",
			"codeLines": ["Ieri ho finito i compiti.", "Domani andremo al mare.", "L'anno scorso vado in montagna.", "# quale verbo non concorda col tempo?"],
			"explanation": "Riga 3: 'l'anno scorso' è passato, quindi 'sono andato' o 'andavo', non 'vado'."},
		{"topic": "punteggiatura", "answerLine": 2,
			"prompt": "Una frase usa male l'apostrofo. Quale riga?",
			"codeLines": ["Un'amica mi ha aiutato molto.", "Ho visto un'orso nel bosco.", "L'albero è pieno di frutti.", "# dove l'apostrofo è di troppo?"],
			"explanation": "Riga 2: 'orso' è maschile, quindi 'un orso' senza apostrofo (l'apostrofo va solo con il femminile: un'amica)."},
		# Scuola media — la caccia all'errore diventa correzione di un'analisi.
		{"topic": "analisi-grammaticale", "minLevel": 8, "answerLine": 2,
			"prompt": "Analisi grammaticale di 'La bianca luna splende': quale riga sbaglia?",
			"codeLines": ["La = articolo determinativo", "bianca = nome comune", "luna = nome comune", "splende = verbo"],
			"explanation": "Riga 2: 'bianca' è un aggettivo qualificativo (descrive la luna), non un nome."},
		{"topic": "verbo", "minLevel": 9, "answerLine": 2,
			"prompt": "Modo e tempo dei verbi: quale analisi è errata?",
			"codeLines": ["mangerò = futuro semplice", "che io mangi = indicativo presente", "mangiando = gerundio", "# quale voce verbale è analizzata male?"],
			"explanation": "Riga 2: 'che io mangi' è congiuntivo presente, non indicativo (l'indicativo presente è 'io mangio')."},
		{"topic": "analisi-logica", "minLevel": 11, "answerLine": 3,
			"prompt": "Analisi logica di 'Marco regala un libro a Luca': quale riga sbaglia?",
			"codeLines": ["Marco = soggetto", "regala = predicato verbale", "un libro = complemento di termine", "a Luca = complemento di termine"],
			"explanation": "Riga 3: 'un libro' risponde a 'che cosa?', è complemento oggetto. Il complemento di termine (a chi?) è 'a Luca'."},
	],
	# MATEMATICA — "Caccia all'errore nel calcolo": si segue un procedimento passo
	# per passo e si smaschera la riga sbagliata. Colpisce le misconcezioni tipiche
	# (priorità, area vs perimetro, somma di frazioni): più coinvolgente che ripetere.
	"matematica": [
		{"topic": "calcolo", "answerLine": 2,
			"prompt": "Controlla il calcolo passo per passo: quale riga sbaglia?",
			"codeLines": ["7 + 5", "= 13", "# quanto fa davvero?"],
			"explanation": "Riga 2: 7 + 5 = 12, non 13."},
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
	],
	# INGLESE — "Find the mistake": error correction, il cuore dell'apprendimento
	# di una lingua straniera. Una frase su tante nasconde lo sbaglio: si clicca.
	"inglese": [
		{"topic": "spelling", "answerLine": 2,
			"prompt": "One word is spelled wrong. Which line?",
			"codeLines": ["I have a cat.", "The sun is yelow.", "She likes books.", "# find the spelling mistake"],
			"explanation": "Line 2: 'yellow' has a double L."},
		{"topic": "articles", "minLevel": 5, "answerLine": 3,
			"prompt": "One article is wrong. Which line?",
			"codeLines": ["I have a dog.", "There is an egg.", "She eats a apple.", "# which article is wrong?"],
			"explanation": "Line 3: before a vowel sound use 'an': 'an apple'."},
		{"topic": "third-person", "minLevel": 6, "answerLine": 2,
			"prompt": "One sentence has a grammar mistake. Which line?",
			"codeLines": ["I like pizza.", "She go to school every day.", "They play football.", "# find the sentence with the error"],
			"explanation": "Line 2: third person singular needs -s: 'She goes to school'."},
		{"topic": "past-tense", "minLevel": 7, "answerLine": 2,
			"prompt": "One past tense is wrong. Which line?",
			"codeLines": ["Yesterday I played tennis.", "She goed home.", "We watched a film.", "# which past tense is wrong?"],
			"explanation": "Line 2: 'go' is irregular, the past is 'went', not 'goed'."},
		{"topic": "do-does", "minLevel": 7, "answerLine": 2,
			"prompt": "One negative sentence is wrong. Which line?",
			"codeLines": ["I don't like fish.", "He don't like tea.", "We don't watch TV.", "# which negative is wrong?"],
			"explanation": "Line 2: third person singular uses 'doesn't': 'He doesn't like tea'."},
	],
}

const NUMERIC_ORDERING_SUBJECTS := ["matematica", "logica"]

func build_minigame(subject: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var has_match := MATCHING.has(subject)
	var has_order := ORDERING.has(subject)
	var has_classify := CLASSIFICATION.has(subject)
	var numeric := NUMERIC_ORDERING_SUBJECTS.has(subject)
	var nodes: Array = []
	# Primo nodo: preferisci un abbinamento (più ricco); ripiega su ordinamento.
	if has_match:
		nodes.append(_matching_node(subject, _pick(MATCHING[subject], generator, level), level, generator, 0))
	elif numeric:
		nodes.append(_numeric_ordering_node(subject, level, generator, 0))
	elif has_order:
		nodes.append(_ordering_node(subject, _pick(ORDERING[subject], generator, level), level, generator, 0))
	# Secondo nodo: preferisci un formato DIVERSO per varietà.
	if numeric:
		nodes.append(_numeric_ordering_node(subject, level, generator, 1))
	elif has_order:
		nodes.append(_ordering_node(subject, _pick(ORDERING[subject], generator, level), level, generator, 1))
	elif has_match:
		nodes.append(_matching_node(subject, _pick(MATCHING[subject], generator, level), level, generator, 1))
	# Terzo nodo (se disponibile): smistamento drag-to-sort — il formato più
	# distante da abbinamento/ordinamento, per esercizi davvero vari (#11).
	if has_classify:
		nodes.append(_classification_node(subject, _pick(CLASSIFICATION[subject], generator, level), level, generator, 2))
	# Quarto nodo (formato SPECIALISTA): grafico/circuito/code-debug se la materia
	# ne ha — leggere dati, schemi o codice: la competenza come sfida visuale.
	# Quando una materia ne ha più d'uno (es. italiano: arco narrativo + caccia
	# all'errore) si ruota a caso, così le missioni non ripetono sempre lo stesso.
	var specialists: Array = []
	if GRAPH.has(subject):
		specialists.append("graph")
	if CIRCUIT.has(subject):
		specialists.append("circuit")
	if CODE_DEBUG.has(subject):
		specialists.append("code_debug")
	if not specialists.is_empty():
		var pick_fmt := str(specialists[generator.randi_range(0, specialists.size() - 1)])
		if pick_fmt == "graph":
			nodes.append(_graph_node(subject, _pick(GRAPH[subject], generator, level), level, generator, 3))
		elif pick_fmt == "circuit":
			nodes.append(_circuit_node(subject, _pick(CIRCUIT[subject], generator, level), level, generator, 3))
		else:
			nodes.append(_code_debug_node(subject, _pick(CODE_DEBUG[subject], generator, level), level, generator, 3))
	if nodes.is_empty():
		# Fallback generico: un abbinamento numerico sempre valido.
		nodes.append(_numeric_ordering_node(subject, level, generator, 0))
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

func _matching_node(subject: String, group: Dictionary, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var all: Array = (group["pairs"] as Array).duplicate()
	_shuffle(all, rng)
	var take := clampi(3 + int(level / 8.0), 3, mini(5, all.size()))
	var pairs: Array = []
	for i in take:
		var p: Array = all[i]
		pairs.append({"left": str(p[0]), "right": str(p[1])})
	return {
		"id": "minigame-match-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(group["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "matching",
		"prompt": "Abbina ogni elemento alla sua coppia.",
		"pairs": pairs,
		"explanation": "Collega ogni elemento a sinistra con quello giusto a destra.",
	}

func _classification_node(subject: String, spec: Dictionary, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var assignments: Dictionary = spec["assignments"]
	var items: Array = assignments.keys()
	_shuffle(items, rng)
	return {
		"id": "minigame-classify-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "classification",
		"prompt": str(spec["prompt"]),
		"items": items,
		"categories": Array(spec["categories"]).duplicate(),
		"assignments": assignments.duplicate(true),
		"explanation": "Ogni tessera va nel gruppo giusto secondo la sua proprietà.",
	}

func _graph_node(subject: String, spec: Dictionary, level: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-graph-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "graph",
		"prompt": str(spec["prompt"]),
		"points": (spec["points"] as Array).duplicate(true),
		"xLabel": str(spec.get("xLabel", "x")),
		"yLabel": str(spec.get("yLabel", "y")),
		"answer": str(spec["answer"]),
		"explanation": str(spec["explanation"]),
	}

func _circuit_node(subject: String, spec: Dictionary, level: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-circuit-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "circuit",
		"prompt": str(spec["prompt"]),
		"components": (spec["components"] as Array).duplicate(true),
		"connections": (spec["connections"] as Array).duplicate(true),
		"answer": str(spec["answer"]),
		"explanation": str(spec["explanation"]),
	}

func _code_debug_node(subject: String, spec: Dictionary, level: int, _rng: RandomNumberGenerator, idx: int) -> Dictionary:
	return {
		"id": "minigame-code-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "code_debug",
		"prompt": str(spec["prompt"]),
		"codeLines": (spec["codeLines"] as Array).duplicate(),
		"answerLine": int(spec["answerLine"]),
		"answer": str(spec["answerLine"]),
		"explanation": str(spec["explanation"]),
	}

func _ordering_node(subject: String, spec: Dictionary, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var correct: Array = (spec["correctOrder"] as Array).duplicate()
	var items := correct.duplicate()
	_shuffle(items, rng)
	return {
		"id": "minigame-order-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": str(spec["topic"]),
		"difficulty": ContentManager.target_difficulty(level),
		"format": "ordering",
		"prompt": str(spec["prompt"]),
		"items": items,
		"correctOrder": correct,
		"explanation": "Ordine giusto: %s." % ", ".join(PackedStringArray(correct)),
	}

func _numeric_ordering_node(subject: String, level: int, rng: RandomNumberGenerator, idx: int) -> Dictionary:
	var count := clampi(3 + int(level / 6.0), 3, 5)
	var span := 5 + level * 2
	var values: Array = []
	while values.size() < count:
		var v := rng.randi_range(1, span)
		if not values.has(v):
			values.append(v)
	var ascending := rng.randf() < 0.5
	var ordered := values.duplicate()
	ordered.sort()
	if not ascending:
		ordered.reverse()
	var correct: Array = []
	for v in ordered:
		correct.append(str(v))
	var items := correct.duplicate()
	_shuffle(items, rng)
	return {
		"id": "minigame-numorder-%s-%d" % [subject, idx],
		"subject": subject,
		"topic": "sequenze",
		"difficulty": ContentManager.target_difficulty(level),
		"format": "ordering",
		"prompt": "Metti i numeri in ordine %s." % ("crescente" if ascending else "decrescente"),
		"items": items,
		"correctOrder": correct,
		"explanation": "Ordine giusto: %s." % ", ".join(PackedStringArray(correct)),
	}

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = values[i]
		values[i] = values[j]
		values[j] = tmp
