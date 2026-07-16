// Primo incontro con un concetto — registro prima media.
// Mentre le schede dell'Atlante sono una SINTESI densa (per ripassare), questi
// testi servono per IMPARARE il concetto la prima volta: partono da un aggancio
// concreto, spiegano le parole nuove e mostrano UN solo esempio, lentissimo.
// NORA li apre automaticamente al primo incontro (vedi maybeIntroduceConcept).
export type TopicIntro = {
  /** Cos'è, con un'immagine concreta di tutti i giorni. Frasi semplici. */
  hook: string;
  /** Le parole nuove spiegate a parole povere (una riga). */
  newWords?: string;
  /** Un micro-esempio svolto passo per passo, senza fretta. */
  guided: string;
};

export const topicIntros: Record<string, TopicIntro> = {
  // ---- Matematica: Numeri ----
  "numeri-naturali": {
    hook: "I numeri naturali sono quelli che usi per contare: 0, 1, 2, 3, 4… Con loro fai le quattro operazioni: addizione, sottrazione, moltiplicazione e divisione.",
    newWords: "Addizione (+) = mettere insieme. Sottrazione (−) = togliere. Moltiplicazione (×) = un'addizione ripetuta. Divisione (÷) = fare parti uguali.",
    guided: "Per fare 4 × 27 puoi spezzarlo: 27 è 20 + 7. Fai 4 × 20 = 80 e 4 × 7 = 28, poi somma: 80 + 28 = 108.",
  },
  "potenze-espressioni": {
    hook: "Una potenza è una moltiplicazione ripetuta scritta corta: 2³ vuol dire 2 × 2 × 2. Un'espressione è un calcolo con più operazioni insieme.",
    newWords: "Base = il numero che moltiplichi. Esponente = il numerino in alto, dice quante volte lo moltiplichi.",
    guided: "L'ordine conta: prima le parentesi, poi le potenze, poi × e ÷, infine + e −. Così (3 + 2)² fa prima 3 + 2 = 5, poi 5² = 25.",
  },
  divisibilita: {
    hook: "Un numero è divisibile per un altro quando la divisione è esatta, senza avanzi (resto 0). Per esempio 12 è divisibile per 3 perché 12 ÷ 3 = 4 preciso.",
    newWords: "Divisore = un numero che sta esatto in un altro. Numero primo = ha solo due divisori, 1 e se stesso (2, 3, 5, 7…).",
    guided: "Per sapere se un numero è divisibile per 3, somma le sue cifre: 27 → 2 + 7 = 9. Siccome 9 è divisibile per 3, lo è anche 27.",
  },
  frazioni: {
    hook: "Una frazione è una parte di un intero. Se dividi una pizza in 4 fette uguali e ne prendi 1, hai preso 1/4 di pizza.",
    newWords: "Denominatore = il numero sotto, dice in quante parti hai diviso. Numeratore = il numero sopra, dice quante parti prendi.",
    guided: "Per sommare 1/2 + 1/3 servono fette della stessa misura: le riscrivi come 3/6 e 2/6. Ora sommi solo i numeri sopra: 3/6 + 2/6 = 5/6.",
  },
  decimali: {
    hook: "I numeri decimali hanno la virgola e servono per le parti più piccole di 1: mezzo si scrive 0,5, un quarto 0,25. Sono un altro modo di scrivere le frazioni.",
    newWords: "La prima cifra dopo la virgola sono i decimi (parti su 10), la seconda i centesimi (parti su 100).",
    guided: "Per trasformare 3/4 in decimale fai semplicemente la divisione: 3 ÷ 4 = 0,75.",
  },
  "radice-quadrata": {
    hook: "La radice quadrata risponde a una domanda: 'quale numero, moltiplicato per se stesso, dà questo?'. √9 = 3 perché 3 × 3 = 9.",
    newWords: "Quadrato = il numero per se stesso (5² = 25). Radice quadrata = l'operazione opposta (√25 = 5).",
    guided: "Per √144 pensa: quale numero al quadrato fa 144? 12 × 12 = 144, quindi √144 = 12.",
  },
  "numeri-relativi": {
    hook: "I numeri relativi hanno un segno: sopra lo zero sono positivi (+3), sotto lo zero negativi (−3). Come le temperature: +5 gradi oppure −5 gradi.",
    newWords: "Sulla linea dei numeri, più vai a destra più il numero è grande. Lo zero sta nel mezzo.",
    guided: "Per −5 + 8 parti da −5 e ti sposti a destra di 8 passi: arrivi a +3.",
  },
  "rapporti-proporzioni": {
    hook: "Un rapporto confronta due quantità: '3 a 4' si scrive 3 : 4. Una proporzione dice che due rapporti sono uguali, come due ricette con le stesse dosi ma quantità diverse.",
    newWords: "Proporzione = due rapporti uguali (a : b = c : d). 'Moltiplicare in croce' = a × d deve dare lo stesso di b × c.",
    guided: "In 3 : 4 = 9 : x moltiplichi in croce: 3 × x = 4 × 9, cioè 3x = 36, quindi x = 36 ÷ 3 = 12.",
  },
  percentuali: {
    hook: "Una percentuale è una frazione con 100 sotto: 25% vuol dire 25 su 100, cioè un quarto. La trovi sugli sconti e sulla batteria carica.",
    newWords: "Il simbolo % significa 'diviso 100'. 'Per cento' vuol dire 'ogni 100'.",
    guided: "Il 20% di 50 € è 50 × 20 ÷ 100 = 10 €. Se è uno sconto, il prezzo diventa 50 − 10 = 40 €.",
  },
  proporzionalita: {
    hook: "Due grandezze sono in proporzionalità diretta se crescono insieme (più libri compri, più spendi). Sono inverse se una cresce e l'altra cala (più operai lavorano, meno giorni servono).",
    newWords: "Diretta = raddoppia una, raddoppia l'altra. Inversa = raddoppia una, l'altra si dimezza.",
    guided: "4 operai fanno un lavoro in 6 giorni. Il lavoro totale è 4 × 6 = 24. Con 8 operai: 24 ÷ 8 = 3 giorni.",
  },
  misure: {
    hook: "Le misure dicono quanto è lungo, pesante o capiente qualcosa. Prima di sommarle o confrontarle devono essere nella stessa unità: non puoi sommare metri e centimetri così come sono.",
    newWords: "Metro (m) per le lunghezze, grammo (g) per i pesi, litro (L) per i liquidi. Ogni scalino verso destra è × 10.",
    guided: "Per portare 2,5 m in cm: da metri a centimetri ci sono 2 scalini, cioè × 100. Quindi 2,5 × 100 = 250 cm.",
  },
  // ---- Matematica: Geometria ----
  "angoli-rette": {
    hook: "Un angolo misura quanto due linee sono 'aperte', come le lancette di un orologio. Si misura in gradi (°): l'angolo retto è 90°, come lo spigolo di un foglio.",
    newWords: "Angolo retto = 90°. Angolo piatto = 180° (una linea dritta). Angolo giro = 360° (un giro intero).",
    guided: "Due angoli sono supplementari se insieme fanno 180°. Il supplementare di 125° è 180° − 125° = 55°.",
  },
  triangoli: {
    hook: "Il triangolo è la figura con 3 lati. Comunque lo giri, i suoi tre angoli interni messi insieme fanno sempre 180°.",
    newWords: "Base = il lato su cui appoggia. Altezza = la linea che scende dritta (perpendicolare) sulla base.",
    guided: "L'area del triangolo è base × altezza diviso 2. Con base 8 e altezza 5: 8 × 5 = 40, poi 40 ÷ 2 = 20.",
  },
  quadrilateri: {
    hook: "I quadrilateri sono figure con 4 lati: quadrato, rettangolo, rombo, trapezio. Ognuno ha la sua formula per l'area, cioè lo spazio che occupa dentro.",
    newWords: "Area = lo spazio dentro la figura. Perimetro = il giro esterno. Diagonale = la linea tra due vertici opposti.",
    guided: "Area del rettangolo = base × altezza. Con base 10 e altezza 4: 10 × 4 = 40.",
  },
  pitagora: {
    hook: "Il teorema di Pitagora vale solo nei triangoli con un angolo di 90° (rettangoli). Collega i due lati corti con quello lungo attraverso i quadrati.",
    newWords: "Cateti = i due lati corti che formano l'angolo retto. Ipotenusa = il lato lungo, davanti all'angolo retto.",
    guided: "Con cateti 3 e 4: fai 3² + 4² = 9 + 16 = 25. L'ipotenusa è √25 = 5.",
  },
  cerchio: {
    hook: "Il cerchio è la figura tonda perfetta. Un numero speciale, π (pi greco, circa 3,14), collega il raggio con il contorno e con l'area.",
    newWords: "Raggio (r) = dal centro al bordo. Diametro (d) = da bordo a bordo passando per il centro, vale il doppio del raggio (d = 2r).",
    guided: "L'area del cerchio è π × r². Con r = 5: 3,14 × 5² = 3,14 × 25 = 78,5.",
  },
  similitudine: {
    hook: "Due figure sono simili se hanno la stessa forma ma grandezza diversa, come una foto e il suo ingrandimento. Gli angoli restano uguali, i lati crescono tutti dello stesso fattore.",
    newWords: "Fattore di scala (k) = di quante volte ingrandisci. Se k = 3, ogni lato diventa 3 volte più lungo.",
    guided: "Se ingrandisci una figura di 3 volte (k = 3), i lati fanno × 3, ma l'area fa × 3² = × 9.",
  },
  solidi: {
    hook: "I solidi occupano spazio nelle tre dimensioni, come una scatola o una palla. Il volume dice quanto spazio riempiono dentro.",
    newWords: "Volume = lo spazio dentro (si misura in cm³). Superficie = la 'pelle' esterna (in cm²). Spigolo = un lato del solido.",
    guided: "Il volume del cubo è spigolo × spigolo × spigolo. Con spigolo 4: 4³ = 4 × 4 × 4 = 64.",
  },
  "piano-cartesiano": {
    hook: "Il piano cartesiano è come una mappa a quadretti: due righe numerate ti fanno trovare ogni punto con due numeri, come dire 'seconda strada, quarto palazzo'.",
    newWords: "Asse x = orizzontale (destra/sinistra). Asse y = verticale (su/giù). Coordinate = la coppia (x; y) che indica un punto.",
    guided: "Punto medio di A(2; 4) e B(6; 8): media delle x, (2 + 6)/2 = 4; media delle y, (4 + 8)/2 = 6. Il punto medio è (4; 6).",
  },
  // ---- Matematica: Relazioni e funzioni ----
  "calcolo-letterale": {
    hook: "Nel calcolo letterale le lettere stanno al posto dei numeri: 'a' può valere qualsiasi cosa. Servono a scrivere regole valide sempre, come a + a = 2a.",
    newWords: "Termine = un pezzo del calcolo (3x, oppure 2). Termini simili = hanno la stessa lettera (3x e 2x): solo quelli si sommano.",
    guided: "In 3x + 2 + 2x − 5 sommi i simili: 3x + 2x = 5x, e 2 − 5 = −3. Risultato: 5x − 3.",
  },
  equazioni: {
    hook: "Un'equazione è come una bilancia in equilibrio: a sinistra e a destra dell'uguale c'è lo stesso valore. Risolverla vuol dire scoprire quale numero si nasconde dietro la x.",
    newWords: "Incognita = il numero sconosciuto, di solito la x. Isolare la x = riuscire a lasciarla da sola su un lato.",
    guided: "In 2x + 3 = 11 togli 3 da tutti e due i lati: 2x = 8. Poi dividi per 2: x = 4. Verifica: 2 × 4 + 3 = 11. ✓",
  },
  "funzioni-retta": {
    hook: "Una funzione è come una macchina: metti dentro un numero (x) e ne esce sempre uno solo (y), seguendo una regola. Disegnando tutti i risultati, viene una retta.",
    newWords: "Nella formula y = m x + q: m dice quanto sale la retta (pendenza), q dice dove taglia l'asse y.",
    guided: "Per y = 2x + 1: se x = 0 allora y = 1; se x = 3 allora y = 2 × 3 + 1 = 7. Bastano due punti per tracciarla.",
  },
  // ---- Matematica: Dati e previsioni ----
  statistica: {
    hook: "La statistica mette in ordine tanti dati per capirli a colpo d'occhio. La media, per esempio, è il 'valore tipico', come se dividessi tutto in parti uguali.",
    newWords: "Media = somma dei dati ÷ quanti sono. Moda = il valore che compare più volte. Mediana = quello in mezzo, mettendoli in fila.",
    guided: "Media di 4, 7, 7, 10: prima sommi, 4 + 7 + 7 + 10 = 28; poi dividi per quanti sono, 28 ÷ 4 = 7.",
  },
  probabilita: {
    hook: "La probabilità misura quanto è facile che una cosa capiti: va da 0 (impossibile) a 1 (sicuro). È il numero di possibilità buone su tutte quelle possibili.",
    newWords: "Casi favorevoli = quelli che ti interessano. Casi possibili = tutti quelli che possono capitare. P = favorevoli ÷ possibili.",
    guided: "Con un dado, probabilità di uscire pari: i pari sono 2, 4, 6 (3 favorevoli) su 6 numeri. P = 3/6 = 1/2, cioè 50%.",
  },
  // ---- Italiano: Verbi ----
  "verbi-mappa-modi-tempi": {
    hook: "Il verbo è il motore della frase: dice cosa succede (correre, essere, pensare). Cambia forma per dire CHI fa l'azione, QUANDO e in che MODO.",
    newWords: "Persona = chi fa l'azione (io, tu, egli…). Tempo = quando (presente, passato, futuro). Modo = con che valore (certezza, dubbio, comando).",
    guided: "In 'noi verifichiamo': il verbo è verificare, la persona è 'noi', il tempo è presente, il modo è indicativo (un fatto certo).",
  },
  "indicativo-tempi": {
    hook: "L'indicativo è il modo dei fatti veri e sicuri: quello che usi per raccontare e dare informazioni. Cambia tempo a seconda di quando succede la cosa.",
    newWords: "Presente = ora (controllo). Imperfetto = durava nel passato (controllavo). Passato prossimo = finito da poco (ho controllato). Futuro = deve ancora succedere (controllerò).",
    guided: "'Mentre il robot avanzava, il sensore attivò l'allarme': l'imperfetto fa da sfondo che dura, il passato è l'evento improvviso.",
  },
  "congiuntivo-condizionale": {
    hook: "Il congiuntivo è il modo del dubbio e del desiderio ('penso che sia'); il condizionale è quello del 'se… allora' e della gentilezza ('vorrei', 'sarebbe'). Spesso lavorano in coppia.",
    newWords: "Congiuntivo = dopo penso che, credo che, è possibile che. Condizionale = per qualcosa che succederebbe solo a una condizione.",
    guided: "'Se avessimo letto il log, avremmo evitato l'errore': dopo 'se' va il congiuntivo (avessimo letto), la conseguenza va al condizionale (avremmo evitato). Mai 'se avrei'.",
  },
  "imperativo-infinito-participio-gerundio": {
    hook: "L'imperativo dà ordini e istruzioni ('premi!', 'non toccare!'). Infinito, participio e gerundio invece non dicono chi fa l'azione: sono forme 'aperte'.",
    newWords: "Infinito = la forma base (-are, -ere, -ire). Participio = usato nei tempi composti (ho controllato). Gerundio = finisce in -ando / -endo.",
    guided: "'Dopo che ebbe verificato il dato' si può accorciare così: 'Dopo aver verificato il dato', tenendo lo stesso soggetto.",
  },
  "concordanza-tempi-verbali": {
    hook: "La concordanza dei tempi fa 'andare d'accordo' il verbo della frase principale con quello della frase che dipende, così si capisce cosa è successo prima e cosa dopo.",
    newWords: "Frase principale = quella che regge. Subordinata = quella che dipende. I tempi devono dire se un fatto è prima, durante o dopo un altro.",
    guided: "'Pensavo che il tecnico fosse pronto': 'pensavo' è al passato, quindi la parte che dipende va al congiuntivo imperfetto 'fosse', non 'è'.",
  },

  // ---- Inglese operativo ----
  "inglese-comandi-operativi": {
    hook: "In inglese le istruzioni delle macchine sono ordini brevi: dicono cosa fare, su cosa, e a volte cosa NON fare. Il verbo va all'inizio, senza dire 'you'.",
    newWords: "Press = premi. Open = apri. Do not (don't) = NON fare. Only = soltanto (limita l'azione permessa).",
    guided: "'Do not open the red valve. Press only the blue switch.' → Non aprire la valvola rossa; premi solo l'interruttore blu.",
  },
  "inglese-tempi-base": {
    hook: "In inglese ci sono due 'presenti': uno per le abitudini (ogni giorno) e uno per ciò che sta succedendo proprio adesso.",
    newWords: "Present simple = abitudine o regola ('it works'). Present continuous, con -ing = adesso ('it is working now').",
    guided: "'The sensor works every day' (abitudine) è diverso da 'The sensor is working now' (in questo momento).",
  },
  "inglese-sequenze-condizioni": {
    hook: "Alcune parole inglesi dicono QUANDO è permessa un'azione: prima, dopo, finché, a meno che. Cambiano l'ordine o mettono una condizione.",
    newWords: "before = prima. after = dopo. until = finché (aspetta). unless = a meno che (tranne se).",
    guided: "'Wait until the light is green, then reset.' → Aspetta finché la luce diventa verde, poi resetta: prima la condizione, poi l'azione.",
  },

  // ---- Elettronica / Circuiti ----
  "circuito-chiuso-corrente": {
    hook: "La corrente elettrica è come acqua in un tubo ad anello: scorre solo se il giro è completo, dalla pila al LED e ritorno. Se c'è un'interruzione, si ferma tutto.",
    newWords: "Circuito chiuso = giro completo, la corrente passa. Circuito aperto = c'è un'interruzione, si ferma. Interruttore = un ponte che apre o chiude il giro.",
    guided: "LED spento e il tester dice 'interrotto' tra LED e ritorno? Manca un pezzo del giro: ripara il filo mancante e la corrente torna a scorrere.",
  },
  "circuiti-polarita-protezione": {
    hook: "Il LED è un componente 'a senso unico': fa passare la corrente solo in un verso. E va protetto da una resistenza, altrimenti riceve troppa corrente.",
    newWords: "Polarità = il verso giusto (+ e −). LED invertito = montato al contrario, resta spento. Resistenza = frena la corrente e protegge il LED.",
    guided: "Il giro è chiuso ma il LED è spento? Controlla il verso: se è invertito, giralo. Se manca la resistenza, la corrente non è sicura.",
  },
  "elettronica-componenti-simboli": {
    hook: "Ogni pezzo di un circuito ha un simbolo disegnato, come le icone su una mappa. Riconoscere il simbolo vuol dire capire subito a cosa serve quel pezzo.",
    newWords: "Pila = dà energia. Resistenza = frena la corrente. LED = si accende. Interruttore = apre o chiude il giro.",
    guided: "Vedi due linee parallele, una lunga e una corta? È la pila: il lato lungo è il +, quello corto il −.",
  },

  // ---- Coding e robot ----
  "coding-tracing-variabili": {
    hook: "Una variabile è come una scatola con un'etichetta che contiene un numero. Fare 'tracing' vuol dire eseguire il codice a mano, riga per riga, aggiornando cosa c'è nella scatola.",
    newWords: "Variabile = una scatola con un nome (x). Il segno = vuol dire 'metti dentro' un nuovo valore. print = mostra cosa c'è ora nella scatola.",
    guided: "x = 3 (nella scatola x c'è 3). x = x + 2 (prendi 3, aggiungi 2, rimetti: ora x contiene 5). print(x) mostra 5.",
  },
  "robot-griglia-coordinate": {
    hook: "Il robot si muove su una griglia a caselle. Ha una direzione (dove guarda): 'avanti' dipende da dove è girato, non dallo schermo. Girare cambia solo la direzione, non la casella.",
    newWords: "Avanti = una casella nel verso in cui guarda. Gira a sinistra/destra = cambia direzione restando fermo. Checkpoint = tappe da toccare in ordine.",
    guided: "Il robot guarda a Est e deve salire di una casella (verso Nord). Prima gira a sinistra (ora guarda Nord), poi vai avanti.",
  },

  // ---- Musica ----
  "musica-pentagramma-chiavi": {
    hook: "Il pentagramma sono 5 righe: più una nota è in alto, più il suono è acuto. La chiave all'inizio è il 'punto di partenza' che ti dice il nome delle note.",
    newWords: "Pentagramma = le 5 righe. Nota = un pallino su una riga o in uno spazio. Chiave di violino = per i suoni acuti; chiave di basso = per i gravi.",
    guided: "In chiave di violino, la nota sulla seconda riga dal basso è il Sol: da lì conti su e giù per trovare le altre.",
  },

  // ---- Fisica ----
  "fisica-misure-unita": {
    hook: "Misurare vuol dire attaccare un numero a un'unità: '3 metri', '2 chili'. Il numero da solo non basta: '3' non dice se sono metri o secondi.",
    newWords: "Grandezza = ciò che misuri (lunghezza, tempo, peso). Unità = il 'righello' che usi (metro, secondo, chilogrammo).",
    guided: "Non puoi sommare 2 m e 50 cm così come sono: prima stessa unità. 2 m = 200 cm, quindi 200 + 50 = 250 cm.",
  },
  "fisica-esperimento-metodo": {
    hook: "Per capire cosa causa cosa, uno scienziato cambia UNA cosa alla volta e tiene ferme le altre. Così sa che il risultato dipende proprio da quella.",
    newWords: "Variabile = ciò che può cambiare. Esperimento controllato = cambi una sola variabile per volta e tieni uguale il resto.",
    guided: "Più luce fa crescere la pianta? Dai più luce a UNA pianta e tieni tutto il resto identico (stessa acqua, stessa terra). Se cresce di più, è la luce.",
  },

  // ---- Latino ----
  "latino-casi-declinazioni": {
    hook: "In latino il ruolo di una parola non si capisce dall'ordine, ma dalla sua FINALE (la desinenza). Cambiando la finale, la stessa parola cambia ruolo nella frase.",
    newWords: "Caso = il ruolo della parola. Desinenza = la parte finale che cambia. Nominativo = il soggetto; accusativo = il complemento oggetto.",
    guided: "'rosa' (finale -a, nominativo) è il soggetto: la rosa (agisce). 'rosam' (finale -am, accusativo) è l'oggetto: (vedo) la rosa.",
  },

  // ================= Concetti avanzati (2ª-3ª media e ponte) =================

  // ---- Matematica avanzata ----
  "matematica-equazioni-quadratiche": {
    hook: "Un'equazione di secondo grado ha la x elevata al quadrato (x²). A differenza di quelle di primo grado può avere due soluzioni, una sola o nessuna: sono i valori di x che rendono vera l'uguaglianza.",
    newWords: "Forma normale: ax² + bx + c = 0. a, b, c sono i numeri (coefficienti). Radici = le soluzioni, cioè i valori di x che annullano l'espressione.",
    guided: "x² − 5x + 6 = 0. Cerca due numeri che moltiplicati danno 6 e sommati danno 5: sono 2 e 3. Quindi x = 2 oppure x = 3. Verifica: 2² − 5·2 + 6 = 4 − 10 + 6 = 0. ✓",
  },
  "matematica-sistemi": {
    hook: "Un sistema sono due equazioni insieme: cerchi la coppia di numeri (x e y) che le rende vere entrambe nello stesso momento. Una sola equazione non basta a trovarli.",
    newWords: "Sistema = due equazioni valide insieme. Incognite = i due numeri da trovare (x e y). Soluzione = la coppia che soddisfa entrambe.",
    guided: "x + y = 5 e x − y = 1. Somma le due equazioni: 2x = 6, quindi x = 3. Poi da x + y = 5: 3 + y = 5, quindi y = 2. Soluzione: x = 3, y = 2.",
  },
  "matematica-parabole-grafici": {
    hook: "La parabola è la curva a forma di U che disegni con y = ax² + bx + c. Il numero 'a' decide se la U guarda in su o in giù; il punto di svolta si chiama vertice.",
    newWords: "Parabola = il grafico di una funzione di 2° grado. Vertice = il punto di svolta (minimo o massimo). Radici = i punti dove la curva taglia l'asse x.",
    guided: "y = x² − 4 taglia l'asse x dove y = 0: x² − 4 = 0, cioè x² = 4, quindi x = −2 e x = +2. La U guarda in su (a = 1 > 0) e il vertice sta in mezzo, in x = 0.",
  },

  // ---- Elettronica avanzata ----
  "elettronica-legge-ohm": {
    hook: "La legge di Ohm è la regola base dei circuiti: collega la tensione (la 'spinta' della pila), la corrente (quanta elettricità scorre) e la resistenza (quanto il circuito la frena).",
    newWords: "Tensione V (volt). Corrente I (ampere). Resistenza R (ohm). La regola: V = I × R, e quindi I = V ÷ R.",
    guided: "Una pila da 12 V con una resistenza da 4 ohm: quanta corrente scorre? I = V ÷ R = 12 ÷ 4 = 3 ampere.",
  },
  "elettronica-resistenza-valore": {
    hook: "La resistenza frena la corrente, e il suo valore (in ohm) va scelto giusto: troppo alto e il LED è debole o spento, troppo basso e passa troppa corrente.",
    newWords: "Ohm = l'unità della resistenza. Valore alto = frena molto (poca corrente). Valore basso = frena poco (più corrente).",
    guided: "Il LED si accende debolissimo con una resistenza molto alta? Passa troppa poca corrente: abbassa il valore della resistenza, restando dentro il limite sicuro.",
  },
  "elettronica-serie-parallelo": {
    hook: "Due modi di collegare i componenti: in SERIE sono in fila su un unico percorso (se si interrompe uno, si ferma tutto); in PARALLELO sono su rami separati (uno può spegnersi e l'altro restare acceso).",
    newWords: "Serie = uno dopo l'altro, un solo percorso. Parallelo = rami separati, la corrente si divide.",
    guided: "Due LED e uno si spegne ma l'altro resta acceso: sono in parallelo (rami indipendenti). Ripara solo il ramo spento.",
  },
  "elettronica-sensori-guasti": {
    hook: "Un sensore misura qualcosa (luce, temperatura…) e manda un segnale, ma solo se è alimentato e collegato bene. Se non risponde, si diagnostica seguendo i sintomi, non cambiando pezzi a caso.",
    newWords: "Alimentazione = l'energia che accende il sensore. Segnale = il dato che invia. Diagnosi = trovare la causa dai sintomi.",
    guided: "Il sensore non risponde e il tester non trova tensione al suo ingresso: vuol dire che non è alimentato. Ripara il filo di potenza e riprova.",
  },

  // ---- Coding avanzato ----
  "coding-cicli-condizioni": {
    hook: "Un ciclo ripete un blocco di istruzioni tante volte; una condizione (if) decide quale strada prende il programma. Insieme fanno fare al computer ripetizioni e scelte.",
    newWords: "for i in range(n) = ripeti n volte (parte da 0). if = fai solo se la condizione è vera. else = altrimenti fai l'altra.",
    guided: "for i in range(3): total = total + 2. Il blocco gira 3 volte e ogni volta aggiunge 2: 2 + 2 + 2 = 6. In totale total aumenta di 6.",
  },
  "coding-booleani-logica": {
    hook: "Un valore booleano è solo vero o falso, come un interruttore acceso/spento. Le parole AND, OR e NOT combinano più condizioni per decidere cosa fare.",
    newWords: "AND = vero solo se TUTTE sono vere. OR = vero se ALMENO una è vera. NOT = capovolge (vero ↔ falso).",
    guided: "x > 0 AND x < 5, con x = 3. È vero che 3 > 0? Sì. È vero che 3 < 5? Sì. Tutte e due vere → con AND il risultato è vero.",
  },
  "coding-debug": {
    hook: "Fare debug vuol dire trovare la riga sbagliata di un programma e correggere la CAUSA, non il sintomo. Si legge il codice come farebbe il computer, riga per riga.",
    newWords: "Bug = un errore nel codice. Debug = trovarlo e correggerlo. Sintomo = il risultato sbagliato; causa = la riga che lo produce.",
    guided: "total = 0; total = 2; print(total), ma serviva la somma di 2 e 3. La riga sbagliata è la seconda: invece di total = 2 scrivi total = total + 3, così somma davvero.",
  },
  "coding-binario": {
    hook: "Il computer conta con due sole cifre, 0 e 1 (binario). Ogni posizione, da destra a sinistra, vale il doppio della precedente: 1, 2, 4, 8, 16…",
    newWords: "Bit = una cifra binaria (0 o 1). Ogni posizione vale una potenza di due: …8, 4, 2, 1.",
    guided: "1011 in decimale: le posizioni valgono 8-4-2-1. C'è 1 negli 8, 0 nei 4, 1 nei 2, 1 negli 1 → 8 + 0 + 2 + 1 = 11.",
  },

  // ---- Fisica ----
  "fisica-moto-forze-energia": {
    hook: "La fisica descrive come si muovono le cose usando numeri e grafici. Un grafico posizione-tempo, per esempio, ti dice quanto va veloce un corpo dalla sua pendenza.",
    newWords: "Posizione = dov'è. Velocità = quanto in fretta cambia posizione. Più il grafico è ripido, più il corpo va veloce.",
    guided: "Su un grafico posizione-tempo la linea diventa più ripida: vuol dire che il corpo sta accelerando, cioè si muove sempre più veloce.",
  },
  "fisica-moto-grafici": {
    hook: "Un grafico posizione-tempo racconta un viaggio: l'inclinazione della linea è la velocità. Piatta = fermo; in salita = si allontana; ripida = veloce.",
    newWords: "Asse orizzontale = tempo. Asse verticale = posizione. Pendenza (inclinazione) = velocità.",
    guided: "Se per un tratto la linea è piatta (orizzontale), la posizione non cambia: in quel tratto il corpo è fermo.",
  },
  "fisica-forze-equilibrio": {
    hook: "Una forza è una spinta o una tirata: ha un'intensità e una direzione. Se due forze opposte si bilanciano, il corpo sta fermo — è in equilibrio.",
    newWords: "Forza = spinta o tirata (in newton). Peso = la forza che tira verso il basso. Equilibrio = le forze si annullano, niente movimento.",
    guided: "Un libro fermo sul tavolo: il peso lo tira giù, ma il tavolo lo spinge su con la stessa forza. Le due si bilanciano → resta fermo, in equilibrio.",
  },
  "fisica-energia-trasformazioni": {
    hook: "L'energia non si crea e non si distrugge: cambia solo forma. Quando qualcosa cade, l'energia 'di posizione' si trasforma in energia 'di movimento'.",
    newWords: "Energia potenziale = immagazzinata per la posizione (stare in alto). Energia cinetica = quella del movimento. Una si trasforma nell'altra.",
    guided: "Una palla cade dal tavolo: in alto aveva energia potenziale; cadendo diventa sempre più veloce, quindi quella energia si trasforma in cinetica (di movimento).",
  },
  "fisica-densita-pressione": {
    hook: "La densità dice quanto è 'stipata' la materia: quanta massa in un certo volume. La pressione dice quanta forza spinge su una certa area.",
    newWords: "Densità = massa ÷ volume (es. g/cm³). Pressione = forza ÷ area. Stessa massa in meno volume = più densa.",
    guided: "Massa 200 g in un volume di 100 cm³: densità = massa ÷ volume = 200 ÷ 100 = 2 g/cm³.",
  },
  "fisica-calore-temperatura": {
    hook: "La temperatura misura quanto è caldo un corpo. Il calore invece è energia che si sposta: passa sempre dal più caldo al più freddo, finché arrivano alla stessa temperatura.",
    newWords: "Temperatura = quanto è caldo (in gradi). Calore = energia che passa dal caldo al freddo. Equilibrio = stessa temperatura raggiunta.",
    guided: "Un cubetto di ghiaccio in acqua tiepida: il calore passa dall'acqua al ghiaccio. L'acqua si raffredda, il ghiaccio si scalda e si scioglie, fino alla stessa temperatura.",
  },
  "fisica-onde-ottica": {
    hook: "Un'onda trasporta energia senza spostare la materia, come le onde del mare. La luce si può disegnare come raggi dritti che cambiano direzione quando incontrano uno specchio o l'acqua.",
    newWords: "Lunghezza d'onda (λ) = distanza tra due creste. Frequenza (f) = quante onde al secondo (Hz). Velocità = λ × f.",
    guided: "Un'onda con lunghezza λ = 2 m e frequenza f = 3 Hz: velocità = λ × f = 2 × 3 = 6 metri al secondo.",
  },

  // ---- Inglese ----
  "inglese-present-perfect": {
    hook: "Il present perfect lega un fatto del passato al presente, quando NON dici quando è successo. Si forma con have/has + il participio passato del verbo.",
    newWords: "have/has + participio (es. 'has restarted'). Si usa con yet (ancora), already (già), just (appena).",
    guided: "'The system has not restarted yet.' → Il sistema non si è ancora riavviato: il fatto passato conta adesso ('ancora no').",
  },
  "inglese-modali": {
    hook: "I verbi modali (must, should, can, may) non dicono un'azione, ma il suo 'peso': obbligo, consiglio, permesso o possibilità. Vanno prima del verbo, alla forma base.",
    newWords: "must = devi (obbligo). should = dovresti (consiglio). can = puoi/sai (capacità). may = puoi (permesso).",
    guided: "'You must wear gloves. You may open the panel.' → I guanti sono obbligatori (must); il pannello puoi aprirlo, è permesso (may).",
  },
  "inglese-passivo": {
    hook: "Il passivo mette al centro CHI o COSA subisce l'azione, non chi la compie. Si forma con il verbo be + il participio passato.",
    newWords: "Attivo: chi agisce viene prima. Passivo: chi subisce viene prima. Formula: be + participio (+ by chi agisce).",
    guided: "Attivo: 'The robot scans the code.' Passivo: 'The code is scanned by the robot.' Il codice (che subisce) va all'inizio.",
  },
  "inglese-comparativi": {
    hook: "I comparativi confrontano due cose (più… di); i superlativi indicano il massimo in un gruppo (il più…). Per gli aggettivi corti si aggiunge -er / -est.",
    newWords: "strong → stronger (più forte) → the strongest (il più forte). 'than' = il 'di' del confronto.",
    guided: "Il segnale A è più forte di B: 'A is stronger than B.' (strong + -er = stronger, poi 'than' per il 'di').",
  },
  "inglese-reading": {
    hook: "Leggere un testo tecnico non vuol dire capire ogni parola, ma trovare l'idea principale e distinguerla dai dettagli. A volte conta anche ciò che NON è scritto.",
    newWords: "Idea principale = il messaggio centrale. Dettaglio = un'informazione in più. Inferenza = capire qualcosa che si deduce, non scritto.",
    guided: "'Battery low. Charging started at 9.' → Idea principale: la batteria è scarica. Dettaglio: la carica è iniziata alle 9.",
  },
  "inglese-registro-domande": {
    hook: "Il registro è il tono: formale o informale, secondo a chi parli. E per fare una domanda in inglese di solito serve un ausiliare (do/does) o una parola interrogativa.",
    newWords: "Registro = formale/informale. Ausiliare = do/does che apre la domanda. Wh-words = what, when, why, how…",
    guided: "Affermazione: 'The panel restarts.' Domanda: 'Does the panel restart?' — si aggiunge 'does' all'inizio e il verbo torna alla base.",
  },

  // ---- Italiano ----
  "italiano-accordo": {
    hook: "L'accordo fa 'andare d'accordo' le parole della frase: articolo, nome, aggettivo e verbo devono avere lo stesso genere (maschile/femminile) e numero (singolare/plurale).",
    newWords: "Genere = maschile o femminile. Numero = singolare o plurale. Le parole legate devono concordare tra loro.",
    guided: "'Le nuova macchine parte' è sbagliato: 'macchine' è femminile plurale, quindi 'nuove' (non nuova) e 'partono' (non parte) → 'Le nuove macchine partono'.",
  },
  "italiano-pronomi": {
    hook: "Un pronome è una parola che sostituisce qualcosa già nominato, per non ripeterlo (lo, la, gli, ne…). Il segreto è che sia sempre chiaro A CHI si riferisce.",
    newWords: "Pronome = sostituisce un nome. Riferimento = la parola che il pronome rimpiazza. Ambiguità = quando non si capisce a chi si riferisce.",
    guided: "'Il tecnico chiama il collega e lo aiuta.' Il pronome 'lo' sostituisce 'il collega': è lui a essere aiutato.",
  },
  "italiano-connettivi": {
    hook: "I connettivi sono le parole che legano le frasi e spiegano il rapporto tra loro: causa (perché), conseguenza (quindi), opposizione (ma), condizione (se).",
    newWords: "Causa: perché, poiché. Conseguenza: quindi, perciò. Opposizione: ma, però. Condizione: se.",
    guided: "'Il sensore era guasto ___ il sistema si è fermato.' Il guasto è la causa dello stop: serve una conseguenza → 'Il sensore era guasto, quindi il sistema si è fermato'.",
  },
  "italiano-punteggiatura": {
    hook: "La punteggiatura è la 'segnaletica' della frase: la virgola separa e apre le spiegazioni, il punto chiude, i due punti annunciano. Messa bene, cambia il senso.",
    newWords: "Virgola = pausa breve, separa o racchiude un inciso. Punto = fine della frase. Inciso = una spiegazione tra due virgole.",
    guided: "'Il robot, che era spento si riavvia' è incompleto: l'inciso 'che era spento' va chiuso da una virgola → 'Il robot, che era spento, si riavvia'.",
  },
  "italiano-lessico-preciso": {
    hook: "Il lessico preciso sceglie la parola tecnica esatta invece di una vaga. In un'istruzione, 'installa' o 'collega' dicono molto più di 'metti'.",
    newWords: "Lessico = l'insieme delle parole. Preciso = la parola esatta per quel contesto. Sinonimo vago = una parola troppo generica.",
    guided: "'Metti il componente nel supporto' è generico. La parola tecnica è 'installa': 'Installa il componente nel supporto'.",
  },
  "italiano-comprensione-testo": {
    hook: "Comprendere un testo vuol dire tirare fuori l'informazione che conta e lasciar perdere i dettagli di disturbo (il 'rumore'). Ti chiedi: qual è il fatto utile?",
    newWords: "Informazione utile = ciò che serve. Dettaglio di disturbo (rumore) = vero ma inutile per la decisione. Sintesi = il senso in poche parole.",
    guided: "Log: 'guasto alle 9, tecnico stanco, riavvio alle 10.' Utile: guasto alle 9, riavvio alle 10. 'Tecnico stanco' è rumore: non cambia i fatti.",
  },

  // ---- Latino avanzato ----
  "latino-funzioni-casi": {
    hook: "Ogni caso latino ha funzioni logiche precise, oltre a soggetto e oggetto. Il genitivo, per esempio, indica 'di chi' — il possesso o l'appartenenza.",
    newWords: "Genitivo = complemento di specificazione ('di…'). Dativo = a chi (termine). Ablativo = da/con/mezzo. La desinenza segnala il caso.",
    guided: "'rosa puellae': 'puellae' è genitivo (finale -ae) → 'la rosa DELLA ragazza'. Il genitivo dice a chi appartiene la rosa.",
  },
  "latino-verbi-concordanza": {
    hook: "Il verbo latino racchiude in una sola parola tante informazioni: chi fa l'azione, quanti sono, quando e come. Tutto sta nella desinenza finale.",
    newWords: "Persona e numero (io/tu/egli, singolare/plurale). Tempo (presente, passato…). La desinenza -nt = 'essi' (3ª plurale).",
    guided: "'amant': la desinenza -nt dice '3ª persona plurale' → 'essi amano'. Non serve scrivere 'loro': è già dentro il verbo.",
  },
  "latino-lessico-traduzione": {
    hook: "Tradurre dal latino non è sostituire parola per parola: si parte dai vocaboli più frequenti, si trova il verbo e il soggetto, poi si ricostruisce il senso in italiano.",
    newWords: "Vocabolo = una parola da conoscere. Il verbo è il motore; il soggetto è al nominativo; l'oggetto all'accusativo.",
    guided: "'servus dominum videt': servus (nominativo) = il servo; dominum (accusativo) = il padrone; videt = vede → 'Il servo vede il padrone'.",
  },
  "latino-sintassi-base": {
    hook: "La sintassi del periodo riconosce la frase principale (che regge da sola) e le subordinate (che dipendono). Il latino ha costrutti compatti come l'ablativo assoluto.",
    newWords: "Principale = frase autonoma. Subordinata = dipende dalla principale. Ablativo assoluto = condensa 'una volta fatta una cosa…'.",
    guided: "'urbe capta, hostes fugerunt': 'urbe capta' è un ablativo assoluto = 'presa la città'; poi la principale 'hostes fugerunt' = 'i nemici fuggirono'.",
  },

  // ---- Musica avanzata ----
  "musica-durate-tempo": {
    hook: "Ogni figura musicale dura un certo numero di battiti. Il 'tempo' (come 4/4) dice quanti battiti deve contenere ogni battuta: né più né meno.",
    newWords: "Semibreve = 4 battiti. Minima = 2. Semiminima = 1. Croma = ½. Tempo 4/4 = 4 battiti per battuta.",
    guided: "In 4/4 hai una minima (2 battiti) e una semiminima (1): totale 3. Per arrivare a 4 manca 1 battito, cioè un'altra semiminima.",
  },
  "musica-ritmo-intervalli": {
    hook: "Il ritmo organizza la DURATA dei suoni (quanto durano); l'intervallo misura la DISTANZA di altezza tra due note (quanto sono lontane come suono).",
    newWords: "Ritmo = durate e battiti. Intervallo = distanza tra due note, contata includendo entrambe. Battuta = il gruppo di battiti.",
    guided: "In 4/4 con due semiminime (1 + 1) e una minima (2): 1 + 1 + 2 = 4 battiti. La battuta è completa, non manca nessun battito.",
  },
  "musica-linee-ottava": {
    hook: "Il pentagramma ha 5 righe, ma le note possono andare più su o più giù: allora si aggiungono piccole 'linee addizionali'. Più righe sopra, più il suono è acuto (ottava alta).",
    newWords: "Linee addizionali = trattini extra sopra o sotto il pentagramma. Ottava = la stessa nota ma più acuta o più grave.",
    guided: "In chiave di violino, una nota due linee addizionali sopra il pentagramma è un La dell'ottava alta: conti le posizioni salendo oltre le 5 righe.",
  },
  "musica-intervalli-scale": {
    hook: "Un intervallo è la distanza tra due note. Si conta includendo sia la nota di partenza sia quella di arrivo, sulle note della scala Do-Re-Mi-Fa-Sol-La-Si.",
    newWords: "Intervallo = distanza tra due note. Seconda, terza, quarta, quinta… = quanti gradi ci sono, contando entrambe le note.",
    guided: "Da Do a Sol: conta Do(1)-Re(2)-Mi(3)-Fa(4)-Sol(5). Sono 5 note contando entrambe → è una quinta.",
  },
};
