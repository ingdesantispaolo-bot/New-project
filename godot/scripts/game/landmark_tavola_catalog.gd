class_name LandmarkTavolaCatalog
extends RefCounted

## **Quello che il grande landmark di ogni mondo mostra a chi si avvicina.**
## (5 settembre 2026)
##
## Richiesta del committente: dare più valore alla mappa e alla sua
## esplorazione — «la tavola trovata in una rovina, il paradigma latino in un
## archivio» — senza un solo disegno nuovo, perché l'arte è il lavoro di Codex e
## qui non ce n'era in coda.
##
## **La soluzione non serviva costruirla: esisteva già, in due pezzi separati.**
## Ogni mondo ha già un `heroLandmark` — una struttura enorme, illustrata,
## sempre visibile, con un'area di interazione già cablata
## (`HeroLandmarkInteraction`, in `outdoor_world.gd`). E il gioco sa già
## disegnare quattordici famiglie di tavole a costo zero — `NoraFigura`, righe
## di `_draw()`, zero megabyte — finora usate solo dentro le prove. Bastava
## smettere di tenerle separate: **la stessa tavola che spiega un esercizio la
## si può trovare prima, esplorando.**
##
## **Regola di casa, rispettata qui come ovunque: dove non c'è niente da
## estrarre con certezza, non si disegna.** Fisica e scienze non hanno una
## famiglia di tavole — è una scelta già presa il 27 agosto, non una
## dimenticanza — e i loro quattro landmark (mondi 5, 10, 17, 22) restano a
## `tipo == ""`: solo la scoperta, senza un disegno inventato per l'occasione.
##
## **La voce.** `cosa` descrive quello che si vede, concreto e mai lungo più di
## due frasi — la stessa regola dei lasciti nei forzieri
## ([[TreasureCatalog]]). `scoperta` è una riga sola, e non spiega: fa notare
## un dettaglio, come fa NORA. Nessuna delle due nomina la materia scolastica.

## Una voce per mondo. `tipo`/`dati` sono nel formato di `NoraFigura.mostra()`;
## `tipo == ""` vuol dire nessuna tavola, solo il testo.
const VOCI := {
	1: {
		"cosa": "La pietra dell'obelisco è incisa a tacche. Le prime file sono fitte, una tacca alla volta; poi qualcuno ha ricominciato, raggruppandole a dieci a dieci.",
		"scoperta": "Guarda dove cambia la mano: prima contava a uno a uno, poi ha scoperto i gruppi.",
		"tipo": "griglia", "dati": {"righe": 4, "colonne": 10, "evidenzia": "riga"},
	},
	2: {
		"cosa": "Il ponte è fatto di lastre di pietra, e su ognuna è incisa mezza parola. Le prime lettere sono uguali su tutte le lastre: solo la coda cambia.",
		"scoperta": "La prima metà del ponte non cambia mai: è quella che tiene in piedi la parola.",
		"tipo": "parola", "dati": {"forma": "cantare", "radice": "cant", "desinenza": "are"},
	},
	3: {
		"cosa": "La macchina ha una fila di caselle di metallo, numerate. La prima gira sempre per prima, e sulla prima non c'è scritto «1».",
		"scoperta": "Nella prima casella non c'è il numero uno: c'è lo zero, ed è da lì che la macchina comincia a contare.",
		"tipo": "lista", "dati": {"valori": [6, 2, 9], "titolo": "i numeri della macchina"},
	},
	4: {
		"cosa": "Il faro proietta una parola italiana sulla nebbia, lettera per lettera. L'ultima lettera si spegne per prima, e quello che resta acceso è ancora leggibile da solo.",
		"scoperta": "«Importante» perde solo l'ultima lettera, e quello che resta è già una parola inglese.",
		"tipo": "parola", "dati": {"forma": "importante", "radice": "important", "desinenza": "e", "genere": "etimologia", "madre": "important"},
	},
	5: {
		"cosa": "La grande leva è appoggiata su un blocco di pietra, più vicino a un'estremità che all'altra. Quell'estremità corta è consumata da mille mani che ci si sono appoggiate.",
		"scoperta": "Tutti spingevano dal lato lungo: è lì che basta meno forza per muovere lo stesso peso.",
		"tipo": "", "dati": {},
	},
	6: {
		"cosa": "I rami dell'albero risonante sono divisi in quattro sezioni uguali, e la prima — quella più vicina al tronco — vibra sempre un po' più forte delle altre tre.",
		"scoperta": "La prima sezione si sente di più delle altre: è lì che il ritmo ricomincia ogni volta.",
		"tipo": "battuta", "dati": {"movimenti": 4, "sotto": 4},
	},
	7: {
		"cosa": "Sull'arco sono incisi sei nomi, uno sopra l'altro come una scala. Solo uno dei sei è consumato dal tocco di chi lo indica sempre.",
		"scoperta": "Il quarto nome dall'alto è il più liso di tutti: è quello che si usa per dire chi subisce l'azione.",
		"tipo": "casi", "dati": {"scelto": "accusativo"},
	},
	8: {
		"cosa": "Il nodo centrale del delta è un anello di cavo spesso, appoggiato su un basamento di pietra. In un punto, in alto, il cavo è interrotto: i due capi sono ancora lucidi.",
		"scoperta": "L'anello non si chiude in un punto solo: una corrente che gira ha bisogno di percorrere il cerchio intero.",
		"tipo": "circuito", "dati": {"forma": "aperto"},
	},
	9: {
		"cosa": "In cima alla torre c'è una carta di pietra di tutta l'Europa, consumata dal vento tranne in un punto, dove qualcuno ha inciso un piccolo cerchio.",
		"scoperta": "Il cerchio è segnato proprio sopra un pezzo di terra fatto quasi solo di isole: qualcuno lo cercava da qui.",
		"tipo": "mappa", "dati": {"carta": "europe", "bersaglio": "grecia"},
	},
	10: {
		"cosa": "Sulla cupola crescono insieme una pianta rampicante e un albero: la pianta si arrampica sul tronco, e l'albero non sembra soffrirne.",
		"scoperta": "Nessuna delle due prende niente all'altra: la pianta ha solo bisogno di un sostegno per arrivare alla luce.",
		"tipo": "", "dati": {},
	},
	11: {
		"cosa": "Sull'architrave del portale corre una fila di simboli, uno per epoca. Alcuni sono vicinissimi fra loro, altri lontanissimi.",
		"scoperta": "Il simbolo degli egizi sta più lontano dagli altri di quanto dica la lista dei nomi: sulla pietra, il tempo ha davvero una lunghezza.",
		"tipo": "tempo", "dati": {"era": "egizi"},
	},
	12: {
		"cosa": "Al centro del labirinto due cerchi di luce sono proiettati sul pavimento e si sovrappongono nel mezzo: chi cammina in quella zona attiva entrambi i meccanismi insieme.",
		"scoperta": "C'è un pezzo di pavimento che appartiene a tutti e due i cerchi insieme: non sta dentro l'uno o l'altro soltanto.",
		"tipo": "insiemi", "dati": {},
	},
	13: {
		"cosa": "Sul pavimento dell'osservatorio sono incise delle tacche che si allontanano sempre della stessa misura, come i gradini di una scala molto larga.",
		"scoperta": "Le tacche vanno a dieci a dieci — dieci, venti, trenta — e la successiva si prevede anche senza vederla.",
		"tipo": "retta", "dati": {"valori": [10, 20, 30]},
	},
	14: {
		"cosa": "Nella sala, la stessa frase è scritta tre volte su tre colonne diverse, e in ognuna un pezzo diverso è sottolineato in oro.",
		"scoperta": "Ogni voce ha sottolineato un pezzo diverso della stessa storia: nessuna delle tre ha torto.",
		"tipo": "frase", "dati": {"testo": "Luca ha aperto la porta con la chiave nuova.", "pezzo": "la chiave nuova"},
	},
	15: {
		"cosa": "La torre di controllo mostra una fila di caselle luminose in attesa, numerate, e la casella zero è sempre la prima a spegnersi.",
		"scoperta": "La fila di segnali comincia dalla casella zero, non dalla uno: è la stessa numerazione della macchina a cicli, solo più lunga.",
		"tipo": "lista", "dati": {"valori": [3, 7, 1, 9], "titolo": "segnali in coda"},
	},
	16: {
		"cosa": "Sopra la porta delle lingue le insegne dei mercanti cambiano parola ogni pochi passi, ma spesso quella dopo assomiglia moltissimo a quella prima.",
		"scoperta": "«Animale» e «animal» sono quasi la stessa insegna, scritta da due mercanti diversi.",
		"tipo": "parola", "dati": {"forma": "animale", "radice": "animal", "desinenza": "e", "genere": "etimologia", "madre": "animal"},
	},
	17: {
		"cosa": "Le vetrate della cattedrale sono sempre più spesse man mano che si scende verso il fondo, e le ultime, in basso, sono spesse come un muro.",
		"scoperta": "Più si scende nell'acqua, più l'acqua stessa preme forte: le vetrate spesse servono a reggere quella spinta.",
		"tipo": "", "dati": {},
	},
	18: {
		"cosa": "Le canne del grande organo salgono in fila, una più alta dell'altra: sette canne diverse, e poi un'ottava, identica alla prima ma più grande.",
		"scoperta": "L'ottava canna suona la stessa nota della prima, il do: solo che questo do canta più in alto.",
		"tipo": "note", "dati": {"scelta": "si"},
	},
	19: {
		"cosa": "Sull'albero delle radici sono incise parole latine, e sotto ognuna un'etichetta più piccola con la parola italiana che ne è nata.",
		"scoperta": "«Verbum» e «verbo» condividono le prime quattro lettere: la radice non si è mai mossa in duemila anni.",
		"tipo": "parola", "dati": {"forma": "verbum", "radice": "verb", "desinenza": "um", "genere": "etimologia", "madre": "verbo"},
	},
	20: {
		"cosa": "La torre di campo porta due lampade sospese sullo stesso paio di cavi, una accanto all'altra invece che in fila.",
		"scoperta": "Se stacchi una lampada l'altra resta accesa lo stesso: hanno due strade, non una sola.",
		"tipo": "circuito", "dati": {"forma": "parallelo"},
	},
	21: {
		"cosa": "Il pilastro è spaccato da una crepa che lo attraversa da cima a fondo, e nella crepa qualcuno ha incastrato una piccola carta di pietra.",
		"scoperta": "Il punto segnato sulla carta è un'isola nata proprio dove due pezzi di terra si allontanano: la crepa del pilastro le somiglia.",
		"tipo": "mappa", "dati": {"carta": "europe", "bersaglio": "islanda"},
	},
	22: {
		"cosa": "Il nucleo vivente pulsa piano, come un respiro, e la luce che emette cambia colore a ogni pulsazione: verde, poi giallo, poi di nuovo verde.",
		"scoperta": "Il nucleo non si accende e basta: trasforma l'energia che riceve, e quello che vedi è il resto che ne avanza.",
		"tipo": "", "dati": {},
	},
	23: {
		"cosa": "L'archivio ha la stessa fila di simboli del portale della Soglia del Tempo, ma qui è enorme, e sotto ogni simbolo ci sono scaffali pieni di pagine.",
		"scoperta": "Fra il simbolo di Roma e quello del Medioevo gli scaffali sono pochi: è la parte di storia su cui restano meno pagine scritte.",
		"tipo": "tempo", "dati": {"era": "medioevo"},
	},
	24: {
		"cosa": "Il cuore della nave proietta dodici cerchi di luce, uno per sistema, e ognuno tocca gli altri due vicini. Non c'è un punto della sala che stia in un cerchio solo.",
		"scoperta": "Nessun sistema funziona da solo qui: ogni cerchio vive perché tocca quello accanto.",
		"tipo": "insiemi", "dati": {},
	},
}

## La voce di un mondo, per riferimento. Vuota se il livello non è valido — non
## dovrebbe succedere sui 24 mondi del gioco, ma un chiamante fuori range non
## deve piantare per questo.
static func voce(level: int) -> Dictionary:
	return Dictionary(VOCI.get(level, {}))
