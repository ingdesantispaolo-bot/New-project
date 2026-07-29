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
		{"topic": "monumenti", "minLevel": 3, "pairs": [["Colosseo", "Italia"], ["Tour Eiffel", "Francia"], ["Piramidi", "Egitto"], ["Statua della Libertà", "Stati Uniti"]]},
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
	"storia": [
		{"topic": "civilta", "pairs": [["Egizi", "Nilo"], ["Romani", "Roma"], ["Greci", "Grecia"], ["Sumeri", "Mesopotamia"]]},
		{"topic": "invenzioni", "minLevel": 4, "pairs": [["Egizi", "Piramidi"], ["Romani", "Acquedotti"], ["Greci", "Democrazia"], ["Fenici", "Alfabeto"]]},
		# Scuola media — personaggi e le loro imprese.
		{"topic": "personaggi", "minLevel": 5, "pairs": [["Romolo", "Fondò Roma"], ["Giulio Cesare", "Conquistò la Gallia"], ["Colombo", "Arrivò in America"], ["Marco Polo", "Viaggiò in Cina"]]},
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
		{"topic": "analogie", "minLevel": 3, "pairs": [["Penna", "Scrivere"], ["Forbici", "Tagliare"], ["Martello", "Battere"], ["Chiave", "Aprire"]]},
		{"topic": "categorie", "minLevel": 4, "pairs": [["Rosa", "Fiore"], ["Cane", "Animale"], ["Mela", "Frutto"], ["Tavolo", "Mobile"]]},
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
	],
	"geografia": [
		{"topic": "geografia-umana", "prompt": "Ordina dal più piccolo al più grande", "correctOrder": ["Paese", "Regione", "Nazione", "Continente"]},
		{"topic": "geografia-fisica", "minLevel": 3, "prompt": "Ordina il corso di un fiume, dalla nascita al mare.", "correctOrder": ["Sorgente", "Torrente", "Fiume", "Foce"]},
		{"topic": "geografia-umana", "minLevel": 4, "prompt": "Ordina dal più piccolo al più grande.", "correctOrder": ["Via", "Quartiere", "Città", "Regione"]},
		# Scuola media — montagne italiane per altezza.
		{"topic": "italia-fisica", "minLevel": 6, "prompt": "Ordina i rilievi per altezza crescente.", "correctOrder": ["Collina", "Appennini", "Alpi", "Monte Bianco"]},
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
		# Pensiero computazionale "unplugged": la vita quotidiana come algoritmo.
		{"topic": "algoritmi", "minLevel": 2, "prompt": "Ordina i passi dell'algoritmo per fare un tè.", "correctOrder": ["Scalda l'acqua", "Metti la bustina nella tazza", "Versa l'acqua calda", "Aspetta due minuti", "Togli la bustina"]},
		{"topic": "algoritmi", "minLevel": 5, "prompt": "Ordina i passi per trovare il numero più grande in una lista.", "correctOrder": ["Prendi il primo numero come massimo", "Guarda il numero successivo", "Se è più grande, aggiorna il massimo", "Ripeti fino alla fine", "Restituisci il massimo"]},
	],
	"storia": [
		{"topic": "ere", "prompt": "Ordina le grandi età della storia, dalla più antica.", "correctOrder": ["Preistoria", "Età antica", "Medioevo", "Età moderna", "Età contemporanea"]},
		{"topic": "preistoria", "minLevel": 4, "prompt": "Ordina i periodi della preistoria, dal più antico.", "correctOrder": ["Paleolitico", "Neolitico", "Età dei metalli"]},
		{"topic": "roma", "minLevel": 5, "prompt": "Ordina le fasi della storia di Roma.", "correctOrder": ["Monarchia", "Repubblica", "Impero"]},
		# Scuola media — ordinare eventi lontani per data.
		{"topic": "cronologia", "minLevel": 6, "prompt": "Ordina questi eventi dal più antico al più recente.", "correctOrder": ["Fondazione di Roma", "Nascita di Cristo", "Caduta dell'Impero Romano", "Scoperta dell'America"]},
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
		{"topic": "misure", "minLevel": 3, "prompt": "Ordina gli oggetti per massa crescente.", "correctOrder": ["Piuma", "Mela", "Gatto", "Automobile"]},
		{"topic": "materia", "minLevel": 5, "prompt": "Ordina gli stati per energia delle particelle, dal minore al maggiore.", "correctOrder": ["Solido", "Liquido", "Gassoso"]},
	],
	"elettronica": [
		{"topic": "misure-elettriche", "prompt": "Ordina le tensioni dalla più piccola", "correctOrder": ["1 V", "5 V", "12 V", "220 V"]},
		{"topic": "montaggio", "minLevel": 3, "prompt": "Ordina i passi per costruire un circuito che accende un LED.", "correctOrder": ["Prendi la pila", "Collega il filo al polo +", "Aggiungi l'interruttore", "Collega il LED", "Chiudi il circuito al polo -"]},
		{"topic": "misure-elettriche", "minLevel": 5, "prompt": "Ordina le resistenze dalla più piccola.", "correctOrder": ["10 Ω", "100 Ω", "1 kΩ", "10 kΩ"]},
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
		{"topic": "viventi", "minLevel": 2, "prompt": "Smista ogni cosa: vivente o non vivente?",
			"categories": ["vivente", "non vivente"],
			"assignments": {"Cane": "vivente", "Albero": "vivente", "Fiore": "vivente", "Roccia": "non vivente", "Acqua": "non vivente", "Nuvola": "non vivente"}},
		{"topic": "materia", "minLevel": 3, "prompt": "Smista ogni sostanza nel suo stato.",
			"categories": ["solido", "liquido", "gassoso"],
			"assignments": {"Ghiaccio": "solido", "Ferro": "solido", "Acqua": "liquido", "Latte": "liquido", "Vapore": "gassoso", "Aria": "gassoso"}},
		{"topic": "classi", "minLevel": 5, "prompt": "Smista ogni animale: vertebrato o invertebrato?",
			"categories": ["vertebrato", "invertebrato"],
			"assignments": {"Cane": "vertebrato", "Uccello": "vertebrato", "Pesce": "vertebrato", "Verme": "invertebrato", "Ragno": "invertebrato", "Farfalla": "invertebrato"}},
		# Scuola media — ruoli nella rete trofica.
		{"topic": "ecosistema", "minLevel": 6, "prompt": "Smista ogni organismo per il suo ruolo nell'ecosistema.",
			"categories": ["produttore", "consumatore", "decompositore"],
			"assignments": {"Erba": "produttore", "Albero": "produttore", "Coniglio": "consumatore", "Lupo": "consumatore", "Fungo": "decompositore", "Batterio": "decompositore"}},
	],
	"coding": [
		{"topic": "tipi", "prompt": "Smista ogni valore nel suo tipo di dato.",
			"categories": ["intero", "stringa", "booleano", "lista"],
			"assignments": {"7": "intero", "42": "intero", "'ciao'": "stringa", "'sole'": "stringa", "True": "booleano", "False": "booleano", "[1, 2]": "lista", "[3, 4, 5]": "lista"}},
		{"topic": "operatori", "prompt": "Smista ogni operatore nella sua famiglia.",
			"categories": ["aritmetico", "confronto", "logico"],
			"assignments": {"+": "aritmetico", "*": "aritmetico", ">": "confronto", "==": "confronto", "and": "logico", "or": "logico"}},
		# Valuta l'espressione come il computer: è vera o falsa?
		{"topic": "booleani", "minLevel": 4, "prompt": "Ogni espressione: è True o False?",
			"categories": ["True", "False"],
			"assignments": {"5 > 3": "True", "2 == 2": "True", "10 < 1": "False", "'a' == 'b'": "False"}},
		{"topic": "controllo", "minLevel": 5, "prompt": "Smista ogni riga nella sua struttura di controllo.",
			"categories": ["ciclo", "condizione", "funzione"],
			"assignments": {"for i in range(3):": "ciclo", "while x > 0:": "ciclo", "if x > 5:": "condizione", "else:": "condizione", "def saluta():": "funzione", "def somma(a, b):": "funzione"}},
		# Scuola media — regole dei nomi di variabile (Python).
		{"topic": "nomi", "minLevel": 6, "prompt": "Smista ogni nome di variabile: valido o no?",
			"categories": ["valido", "non valido"],
			"assignments": {"nome": "valido", "x1": "valido", "_temp": "valido", "2cose": "non valido", "mia var": "non valido", "3x": "non valido"}},
	],
	"storia": [
		{"topic": "tempo", "prompt": "Smista ogni oggetto: molto antico o moderno?",
			"categories": ["molto antico", "moderno"],
			"assignments": {"Piramide": "molto antico", "Anfora": "molto antico", "Ruota di pietra": "molto antico", "Smartphone": "moderno", "Automobile": "moderno", "Computer": "moderno"}},
		{"topic": "fonti", "minLevel": 3, "prompt": "Smista ogni fonte storica nel suo tipo.",
			"categories": ["materiale", "scritta", "orale"],
			"assignments": {"Piramide": "materiale", "Vaso antico": "materiale", "Papiro": "scritta", "Lettera antica": "scritta", "Racconto del nonno": "orale", "Leggenda tramandata": "orale"}},
		# Scuola media — collocare oggetti e monumenti nella loro epoca.
		{"topic": "epoca", "minLevel": 5, "prompt": "Smista ogni cosa nella sua epoca storica.",
			"categories": ["preistoria", "antichità", "medioevo"],
			"assignments": {"Pittura rupestre": "preistoria", "Selce scheggiata": "preistoria", "Colosseo": "antichità", "Anfora romana": "antichità", "Castello": "medioevo", "Cattedrale gotica": "medioevo"}},
	],
	"geografia": [
		{"topic": "continenti", "prompt": "Smista ogni Paese nel suo continente.",
			"categories": ["Africa", "Europa", "Asia", "America"],
			"assignments": {"Egitto": "Africa", "Kenya": "Africa", "Italia": "Europa", "Francia": "Europa", "Giappone": "Asia", "Cina": "Asia", "Brasile": "America", "Canada": "America"}},
		{"topic": "geografia-fisica", "prompt": "Smista ogni elemento: d'acqua o di terra?",
			"categories": ["acqua", "terra"],
			"assignments": {"Fiume": "acqua", "Lago": "acqua", "Mare": "acqua", "Montagna": "terra", "Pianura": "terra", "Collina": "terra"}},
		{"topic": "climi", "minLevel": 4, "prompt": "Smista ogni luogo nel suo clima.",
			"categories": ["caldo", "temperato", "freddo"],
			"assignments": {"Sahara": "caldo", "Equatore": "caldo", "Italia": "temperato", "California": "temperato", "Polo Nord": "freddo", "Siberia": "freddo"}},
		# Scuola media — i grandi paesaggi d'Italia.
		{"topic": "italia-fisica", "minLevel": 5, "prompt": "Smista ogni elemento nel suo paesaggio italiano.",
			"categories": ["montagna", "pianura", "mare"],
			"assignments": {"Alpi": "montagna", "Appennini": "montagna", "Pianura Padana": "pianura", "Tavoliere": "pianura", "Mar Adriatico": "mare", "Mar Tirreno": "mare"}},
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
		# Scuola media — forze di contatto o a distanza, e la luce nei materiali.
		{"topic": "forze", "minLevel": 5, "prompt": "Smista ogni forza: agisce per contatto o a distanza?",
			"categories": ["contatto", "a distanza"],
			"assignments": {"Attrito": "contatto", "Spinta": "contatto", "Tensione della fune": "contatto", "Gravità": "a distanza", "Magnetismo": "a distanza"}},
		{"topic": "luce", "minLevel": 6, "prompt": "Smista ogni materiale per come lascia passare la luce.",
			"categories": ["trasparente", "opaco", "translucido"],
			"assignments": {"Vetro": "trasparente", "Aria": "trasparente", "Muro": "opaco", "Legno": "opaco", "Carta velina": "translucido", "Vetro smerigliato": "translucido"}},
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
		# Ruolo nel circuito: sorgente, conduttore, isolante o carico.
		{"topic": "ruoli", "minLevel": 4, "prompt": "Smista ogni elemento per il suo ruolo nel circuito.",
			"categories": ["sorgente", "conduttore", "isolante", "carico"],
			"assignments": {"Pila": "sorgente", "Batteria": "sorgente", "Rame": "conduttore", "Filo": "conduttore", "Plastica": "isolante", "Gomma": "isolante", "LED": "carico", "Lampadina": "carico"}},
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
		{"topic": "verita", "minLevel": 4, "prompt": "Ogni affermazione: è vera o falsa?",
			"categories": ["vera", "falsa"],
			"assignments": {"Tutti i quadrati hanno 4 lati": "vera", "Alcuni uccelli volano": "vera", "Ogni numero pari è divisibile per 2": "vera", "Tutti i pesci volano": "falsa", "Un triangolo ha 4 lati": "falsa", "Nessun cane è un animale": "falsa"}},
		# Scuola media — ragionamento sui quantificatori.
		{"topic": "quantificatori", "minLevel": 6, "prompt": "Ogni cosa accade sempre, a volte o mai?",
			"categories": ["sempre", "a volte", "mai"],
			"assignments": {"Un triangolo ha 3 lati": "sempre", "Il ghiaccio è freddo": "sempre", "Piove": "a volte", "Un bambino dorme": "a volte", "Un cerchio ha spigoli": "mai", "2 è un numero dispari": "mai"}},
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
		{"topic": "confronto", "minLevel": 3, "answerLine": 2,
			"prompt": "Vogliamo controllare se x vale 5. Quale riga sbaglia?",
			"codeLines": ["x = 5", "if x = 5:", "    print('cinque')", "# come si confronta in Python?"],
			"explanation": "Riga 2: per confrontare serve '==' (uguaglianza), non '=' (che assegna)."},
		{"topic": "cicli", "minLevel": 4, "answerLine": 1,
			"prompt": "Dovrebbe stampare 0, 1, 2. Quale riga sbaglia?",
			"codeLines": ["for i in range(1, 3):", "    print(i)", "# atteso: 0, 1, 2"],
			"explanation": "Riga 1: range(1, 3) dà 1, 2. Per 0, 1, 2 serve range(3)."},
		{"topic": "indentazione", "minLevel": 5, "answerLine": 2,
			"prompt": "Il numero dovrebbe stamparsi dentro il ciclo. Quale riga sbaglia?",
			"codeLines": ["for i in range(3):", "print(i)", "# print deve stare dentro il for"],
			"explanation": "Riga 2: manca l'indentazione. print(i) va rientrato per stare dentro il for."},
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
	# ELETTRONICA — "Caccia all'errore": si scova l'affermazione falsa sul circuito
	# o il passaggio sbagliato nel calcolo elettrico. Il ragionamento come sfida.
	"elettronica": [
		{"topic": "circuito", "answerLine": 3,
			"prompt": "Una sola affermazione sul circuito è falsa. Quale riga?",
			"codeLines": ["La pila fornisce energia.", "Il LED emette luce.", "Il filo di rame blocca la corrente.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il rame è un conduttore, quindi il filo LASCIA passare la corrente, non la blocca."},
		{"topic": "legge-ohm", "minLevel": 6, "answerLine": 2,
			"prompt": "Corrente con V = 10 V e R = 2 Ω: quale riga sbaglia?",
			"codeLines": ["V = 10 V, R = 2 Ω", "I = V × R", "I = 20 A", "# come si calcola la corrente?"],
			"explanation": "Riga 2: la legge di Ohm è I = V / R (10 / 2 = 5 A), non V × R (che darebbe 20)."},
	],
	# SCIENZE — "Caccia all'errore": fra tre affermazioni una è falsa. Colpisce le
	# misconcezioni classiche (la Luna, le branchie, il vapore).
	"scienze": [
		{"topic": "astronomia", "minLevel": 3, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Il Sole è una stella.", "La Terra gira intorno al Sole.", "La Luna produce luce propria.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: la Luna non produce luce, riflette quella del Sole."},
		{"topic": "corpo", "minLevel": 4, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Le piante fanno la fotosintesi.", "Gli animali respirano ossigeno.", "I pesci respirano con i polmoni.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: i pesci respirano con le branchie, non con i polmoni."},
		{"topic": "materia", "minLevel": 5, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["L'acqua bolle a 100 °C.", "Il ghiaccio è acqua allo stato solido.", "Il vapore è più freddo dell'acqua.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il vapore è più caldo, si forma quando l'acqua bolle a 100 °C."},
	],
	# FISICA — "Caccia all'errore": affermazione falsa o calcolo sbagliato. Colpisce
	# le misconcezioni classiche (Galileo, la formula della velocità, l'energia).
	"fisica": [
		{"topic": "gravita", "minLevel": 4, "answerLine": 1,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Gli oggetti pesanti cadono più veloci di quelli leggeri.", "La gravità attira gli oggetti verso il basso.", "L'attrito dell'aria rallenta la caduta.", "# quale affermazione è falsa?"],
			"explanation": "Riga 1: senza aria tutti gli oggetti cadono insieme, come mostrò Galileo (piuma e martello sulla Luna cadono uguale)."},
		{"topic": "moto", "minLevel": 5, "answerLine": 2,
			"prompt": "Velocità di un'auto che fa 100 km in 2 ore: quale riga sbaglia?",
			"codeLines": ["Spazio = 100 km, tempo = 2 h", "velocità = spazio × tempo", "= 200 km/h", "# come si calcola la velocità?"],
			"explanation": "Riga 2: la velocità è spazio / tempo (100 / 2 = 50 km/h), non spazio × tempo."},
		{"topic": "energia", "minLevel": 6, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["La palla in alto ha energia potenziale.", "Cadendo si trasforma in energia cinetica.", "Toccando terra l'energia sparisce nel nulla.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: l'energia non sparisce, si trasforma (in calore, suono, deformazione): è la conservazione dell'energia."},
	],
	# GEOGRAFIA — "Caccia all'errore": fra tre affermazioni una è falsa.
	"geografia": [
		{"topic": "mondo", "minLevel": 3, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Roma è la capitale d'Italia.", "Il Nilo è un fiume.", "L'Everest è un oceano.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: l'Everest è la montagna più alta del mondo, non un oceano."},
		{"topic": "italia", "minLevel": 4, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Il Po è il fiume più lungo d'Italia.", "L'Etna è un vulcano.", "La Sicilia è una catena montuosa.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: la Sicilia è un'isola, non una catena montuosa."},
		{"topic": "climi", "minLevel": 5, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["L'equatore divide la Terra in due emisferi.", "Al Polo Nord fa molto freddo.", "Nel deserto piove quasi ogni giorno.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: il deserto è arido, con pochissime piogge in tutto l'anno."},
	],
	# STORIA — "Caccia all'errore": affermazione falsa o cronologia sbagliata.
	"storia": [
		{"topic": "civilta", "minLevel": 3, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Gli Egizi costruirono le piramidi.", "I Romani parlavano latino.", "La Preistoria viene dopo il Medioevo.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: la Preistoria è il periodo più antico, viene molto PRIMA del Medioevo."},
		{"topic": "personaggi", "minLevel": 4, "answerLine": 3,
			"prompt": "Una sola affermazione è falsa. Quale riga?",
			"codeLines": ["Ad Atene nacque la democrazia.", "Roma fu fondata nel 753 a.C.", "Cristoforo Colombo era un faraone egizio.", "# quale affermazione è falsa?"],
			"explanation": "Riga 3: Colombo era un navigatore del Quattrocento, non un faraone egizio."},
		{"topic": "cronologia", "minLevel": 6, "answerLine": 3,
			"prompt": "Come si contano gli anni avanti Cristo? Quale riga sbaglia?",
			"codeLines": ["Ci sono il 100 a.C. e il 50 a.C.", "Più il numero è grande, più l'anno è antico.", "Quindi il 100 a.C. viene dopo il 50 a.C.", "# quale passaggio è sbagliato?"],
			"explanation": "Riga 3: negli anni a.C. i numeri grandi sono più antichi, quindi il 100 a.C. viene PRIMA del 50 a.C."},
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

func _has_eligible(list: Array, level: int) -> bool:
	for spec in list:
		if int((spec as Dictionary).get("minLevel", 0)) <= level:
			return true
	return false

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
