export type MathArea = "Numeri" | "Geometria" | "Relazioni e funzioni" | "Dati e previsioni";

export type MathStudyPage = {
  id: string;
  title: string;
  area: MathArea;
  /** Difficulty range (1-8) used to launch a fitting training session. */
  levelRange: [number, number];
  tags: string[];
  /** One precise sentence: what the concept IS. */
  definition: string;
  /** The schematic core: key formulas / rules, one per line. */
  formulas: string[];
  /** Short, precise operating steps. */
  rules: string[];
  example: {
    prompt: string;
    steps: string[];
    answer: string;
  };
  watchOut: string[];
};

// Atlante matematico — programma completo della scuola secondaria di primo
// grado (scuola media), organizzato per aree. Contenuti essenziali e precisi:
// definizione, formule chiave, regole operative, esempio guidato, errori tipici.
export const mathStudyPages: MathStudyPage[] = [
  {
    id: "numeri-naturali",
    title: "Numeri naturali e operazioni",
    area: "Numeri",
    levelRange: [1, 3],
    tags: ["operazioni", "proprietà"],
    definition: "I numeri naturali (0, 1, 2, 3, …) con addizione, sottrazione, moltiplicazione e divisione.",
    formulas: [
      "a + b = b + a   (commutativa)",
      "a × (b + c) = a×b + a×c   (distributiva)",
      "a + 0 = a   ;   a × 1 = a",
      "dividendo = divisore × quoziente + resto",
    ],
    rules: [
      "Usa le proprietà per calcolare a mente.",
      "Sottrazione e divisione NON sono commutative.",
      "Scomponi i numeri grandi per semplificare.",
    ],
    example: {
      prompt: "Calcola 4 × 27 con la proprietà distributiva.",
      steps: ["27 = 20 + 7", "4 × 20 = 80", "4 × 7 = 28", "80 + 28 = 108"],
      answer: "108",
    },
    watchOut: ["12 − 5 ≠ 5 − 12", "La divisione per 0 non esiste"],
  },
  {
    id: "potenze-espressioni",
    title: "Potenze ed espressioni",
    area: "Numeri",
    levelRange: [2, 5],
    tags: ["potenze", "priorità"],
    definition: "Una potenza aⁿ è il prodotto di n fattori uguali ad a; le espressioni si risolvono per priorità.",
    formulas: [
      "aⁿ = a × a × … × a   (n volte)",
      "aᵐ × aⁿ = aᵐ⁺ⁿ   ;   aᵐ ÷ aⁿ = aᵐ⁻ⁿ",
      "(aᵐ)ⁿ = aᵐˣⁿ",
      "a⁰ = 1   ;   a¹ = a",
    ],
    rules: [
      "Priorità: 1) parentesi 2) potenze 3) × e ÷ 4) + e −",
      "A pari priorità si procede da sinistra a destra.",
    ],
    example: {
      prompt: "Calcola (3 + 2)² − 4 × 3.",
      steps: ["(3 + 2) = 5", "5² = 25", "4 × 3 = 12", "25 − 12 = 13"],
      answer: "13",
    },
    watchOut: ["2³ = 8, non 6", "(2 + 3)² ≠ 2² + 3²"],
  },
  {
    id: "divisibilita",
    title: "Divisibilità, MCD e mcm",
    area: "Numeri",
    levelRange: [3, 6],
    tags: ["primi", "MCD", "mcm"],
    definition: "Un numero è divisibile per un altro se il resto è 0; i numeri primi hanno solo 1 e sé stessi come divisori.",
    formulas: [
      "÷2: cifra finale pari   ;   ÷5: finisce 0 o 5",
      "÷3: somma delle cifre divisibile per 3",
      "MCD = fattori comuni col minimo esponente",
      "mcm = fattori comuni e non comuni col massimo esponente",
    ],
    rules: [
      "Scomponi i numeri in fattori primi.",
      "MCD per semplificare e fare gruppi uguali.",
      "mcm per sincronizzare e per il denominatore comune.",
    ],
    example: {
      prompt: "MCD e mcm di 12 e 18.",
      steps: ["12 = 2² × 3", "18 = 2 × 3²", "MCD = 2 × 3 = 6", "mcm = 2² × 3² = 36"],
      answer: "MCD = 6 ; mcm = 36",
    },
    watchOut: ["1 non è un numero primo", "MCD ≤ dei numeri ; mcm ≥ dei numeri"],
  },
  {
    id: "frazioni",
    title: "Frazioni",
    area: "Numeri",
    levelRange: [3, 6],
    tags: ["frazioni"],
    definition: "Una frazione a/b indica a parti di un intero diviso in b parti uguali.",
    formulas: [
      "a/b + c/d → stesso denominatore (mcm)",
      "a/b × c/d = (a×c)/(b×d)",
      "a/b ÷ c/d = a/b × d/c   (reciproca)",
      "semplificare: dividi sopra e sotto per il MCD",
    ],
    rules: [
      "Per sommare/sottrarre: denominatore comune.",
      "Per moltiplicare: numeratori tra loro e denominatori tra loro.",
      "Per dividere: moltiplica per la frazione reciproca.",
    ],
    example: {
      prompt: "Calcola 1/2 + 1/3.",
      steps: ["mcm(2, 3) = 6", "1/2 = 3/6 ; 1/3 = 2/6", "3/6 + 2/6 = 5/6"],
      answer: "5/6",
    },
    watchOut: ["Non si sommano i denominatori", "Propria < 1, impropria ≥ 1"],
  },
  {
    id: "decimali",
    title: "Numeri decimali",
    area: "Numeri",
    levelRange: [2, 5],
    tags: ["decimali", "arrotondamento"],
    definition: "I numeri con la virgola estendono i naturali con decimi, centesimi, millesimi…",
    formulas: [
      "× 10 → virgola di 1 posto a destra",
      "÷ 10 → virgola di 1 posto a sinistra",
      "frazione → decimale: numeratore ÷ denominatore",
    ],
    rules: [
      "In colonna incolonna le virgole.",
      "Nella moltiplicazione conta le cifre decimali totali.",
      "Arrotonda guardando la prima cifra da tagliare: ≥5 su, <5 giù.",
    ],
    example: {
      prompt: "Trasforma 3/4 in numero decimale.",
      steps: ["3 ÷ 4 = 0,75"],
      answer: "0,75",
    },
    watchOut: ["0,5 = 1/2", "Allinea le virgole nelle addizioni"],
  },
  {
    id: "radice-quadrata",
    title: "Radice quadrata",
    area: "Numeri",
    levelRange: [4, 7],
    tags: ["radice", "quadrati"],
    definition: "La radice quadrata di n (√n) è il numero non negativo che elevato al quadrato dà n.",
    formulas: [
      "√n = a  ⟺  a² = n   (a ≥ 0)",
      "√(a × b) = √a × √b",
      "√(a²) = a",
    ],
    rules: [
      "Ricorda i quadrati: 1, 4, 9, 16, 25, 36, 49, 64, 81, 100…",
      "Se non è un quadrato perfetto, stima tra due quadrati vicini.",
    ],
    example: {
      prompt: "Calcola √144.",
      steps: ["12² = 144"],
      answer: "12",
    },
    watchOut: ["√(a + b) ≠ √a + √b", "√0 = 0 ; √1 = 1"],
  },
  {
    id: "numeri-relativi",
    title: "Numeri relativi (interi)",
    area: "Numeri",
    levelRange: [4, 7],
    tags: ["segni", "interi"],
    definition: "I numeri relativi hanno un segno: positivi (+) e negativi (−), con lo zero al centro.",
    formulas: [
      "stesso segno: somma i valori, tieni il segno",
      "segni diversi: sottrai, tieni il segno del maggiore",
      "− (− a) = + a",
      "(+)×(+) = + ; (−)×(−) = + ; (+)×(−) = −",
    ],
    rules: [
      "Immagina la retta dei numeri: destra cresce, sinistra cala.",
      "Togliere un negativo equivale ad aggiungere.",
    ],
    example: {
      prompt: "Calcola −5 + 8 − 3.",
      steps: ["−5 + 8 = +3", "+3 − 3 = 0"],
      answer: "0",
    },
    watchOut: ["−2 × −3 = +6", "−3 < −1 (più a sinistra = minore)"],
  },
  {
    id: "rapporti-proporzioni",
    title: "Rapporti e proporzioni",
    area: "Numeri",
    levelRange: [4, 7],
    tags: ["rapporti", "proporzioni"],
    definition: "Un rapporto a:b confronta due quantità; una proporzione è l'uguaglianza di due rapporti a:b = c:d.",
    formulas: [
      "a : b = c : d  ⟺  a × d = b × c",
      "prodotto dei medi = prodotto degli estremi",
      "incognito: x = (prodotto dei noti) ÷ termine opposto",
    ],
    rules: [
      "Scrivi la proporzione mantenendo l'ordine.",
      "Moltiplica in croce per trovare l'incognita.",
    ],
    example: {
      prompt: "Trova x in 3 : 4 = 9 : x.",
      steps: ["3 × x = 4 × 9", "3x = 36", "x = 12"],
      answer: "x = 12",
    },
    watchOut: ["Usa le stesse unità", "Rispetta l'ordine dei termini"],
  },
  {
    id: "percentuali",
    title: "Percentuali",
    area: "Numeri",
    levelRange: [3, 7],
    tags: ["percentuale", "sconti"],
    definition: "Una percentuale è una frazione con denominatore 100: 25% = 25/100.",
    formulas: [
      "parte = (percento × totale) ÷ 100",
      "percento = (parte ÷ totale) × 100",
      "aumento del p%: × (1 + p/100)",
      "sconto del p%: × (1 − p/100)",
    ],
    rules: [
      "Riconosci totale, parte e percentuale.",
      "Per il prezzo iniziale dopo uno sconto, dividi (non sommare il %).",
    ],
    example: {
      prompt: "Sconto del 20% su 50 €.",
      steps: ["20% di 50 = 50 × 20 ÷ 100 = 10", "50 − 10 = 40"],
      answer: "40 €",
    },
    watchOut: ["+20% e poi −20% non torna al valore iniziale", "Il % si riferisce sempre a un totale"],
  },
  {
    id: "proporzionalita",
    title: "Proporzionalità diretta e inversa",
    area: "Numeri",
    levelRange: [4, 8],
    tags: ["diretta", "inversa"],
    definition: "Diretta: due grandezze crescono insieme (rapporto costante). Inversa: una cresce e l'altra cala (prodotto costante).",
    formulas: [
      "diretta: y / x = k  →  y = k · x",
      "inversa: x · y = k  →  y = k / x",
    ],
    rules: [
      "Diretta: raddoppia una, raddoppia anche l'altra.",
      "Inversa: raddoppia una, l'altra si dimezza.",
    ],
    example: {
      prompt: "4 operai in 6 giorni; con 8 operai? (inversa)",
      steps: ["4 × 6 = 24 (costante)", "24 ÷ 8 = 3"],
      answer: "3 giorni",
    },
    watchOut: ["Distingui diretta e inversa dal contesto", "La diretta ha per grafico una retta dall'origine"],
  },
  {
    id: "misure",
    title: "Misure e unità",
    area: "Numeri",
    levelRange: [1, 5],
    tags: ["unità", "equivalenze"],
    definition: "Le misure usano le unità del Sistema Internazionale; prima di calcolare servono le stesse unità.",
    formulas: [
      "lunghezza: km hm dam m dm cm mm  (×10 a scalino)",
      "massa: kg hg dag g …  ;  capacità: L dL cL mL",
      "aree: scalino × 100   ;   volumi: scalino × 1000",
    ],
    rules: [
      "Converti tutto nella stessa unità.",
      "Verso destra si moltiplica, verso sinistra si divide.",
    ],
    example: {
      prompt: "Converti 2,5 m in cm.",
      steps: ["da m a cm: 2 scalini ×10 = ×100", "2,5 × 100 = 250"],
      answer: "250 cm",
    },
    watchOut: ["Le aree scalano ×100, i volumi ×1000", "Stessa unità prima di sommare"],
  },
  {
    id: "angoli-rette",
    title: "Angoli e rette",
    area: "Geometria",
    levelRange: [1, 4],
    tags: ["angoli", "rette"],
    definition: "Un angolo misura una rotazione; le rette possono essere parallele, incidenti o perpendicolari.",
    formulas: [
      "retto = 90°  ;  piatto = 180°  ;  giro = 360°",
      "complementari: somma = 90°",
      "supplementari: somma = 180°",
      "opposti al vertice: uguali",
    ],
    rules: [
      "Gli angoli si misurano in gradi (°).",
      "Rette parallele tagliate da una trasversale: alterni interni uguali.",
    ],
    example: {
      prompt: "Angolo supplementare di 125°.",
      steps: ["180° − 125° = 55°"],
      answer: "55°",
    },
    watchOut: ["Acuto < 90°, ottuso > 90°", "Non confondere 90° (complementari) e 180° (supplementari)"],
  },
  {
    id: "triangoli",
    title: "Triangoli",
    area: "Geometria",
    levelRange: [2, 6],
    tags: ["triangolo", "area"],
    definition: "Poligono con 3 lati; si classifica per lati (equilatero, isoscele, scaleno) e per angoli.",
    formulas: [
      "somma angoli interni = 180°",
      "perimetro = a + b + c",
      "area = (base × altezza) ÷ 2",
    ],
    rules: [
      "L'altezza è perpendicolare alla base.",
      "Ogni lato è minore della somma degli altri due.",
    ],
    example: {
      prompt: "Area con base 8 e altezza 5.",
      steps: ["8 × 5 = 40", "40 ÷ 2 = 20"],
      answer: "20",
    },
    watchOut: ["Gli angoli interni sommano sempre 180°", "Usa l'altezza, non un lato qualsiasi"],
  },
  {
    id: "quadrilateri",
    title: "Quadrilateri e poligoni",
    area: "Geometria",
    levelRange: [2, 6],
    tags: ["aree", "poligoni"],
    definition: "Poligoni con 4 lati (quadrilateri) o più; ciascuno ha la propria formula di area.",
    formulas: [
      "quadrato: P = 4ℓ ; A = ℓ²",
      "rettangolo: P = 2(b + h) ; A = b × h",
      "rombo: A = (d₁ × d₂) ÷ 2",
      "parallelogramma: A = b × h",
      "trapezio: A = ((B + b) × h) ÷ 2",
      "angoli interni = (n − 2) × 180°",
    ],
    rules: [
      "Riconosci la figura, poi applica la formula giusta.",
      "Poligono regolare: A = (perimetro × apotema) ÷ 2.",
    ],
    example: {
      prompt: "Area del trapezio: B = 10, b = 6, h = 4.",
      steps: ["(10 + 6) = 16", "16 × 4 = 64", "64 ÷ 2 = 32"],
      answer: "32",
    },
    watchOut: ["Il rombo usa le diagonali", "Nel trapezio distingui base maggiore e minore"],
  },
  {
    id: "pitagora",
    title: "Teorema di Pitagora",
    area: "Geometria",
    levelRange: [5, 8],
    tags: ["pitagora", "triangolo rettangolo"],
    definition: "In un triangolo rettangolo il quadrato dell'ipotenusa è uguale alla somma dei quadrati dei cateti.",
    formulas: [
      "i² = c₁² + c₂²",
      "ipotenusa  i = √(c₁² + c₂²)",
      "cateto  c = √(i² − c²)",
    ],
    rules: [
      "Vale solo nel triangolo rettangolo (un angolo di 90°).",
      "L'ipotenusa è il lato opposto all'angolo retto (il più lungo).",
    ],
    example: {
      prompt: "Cateti 3 e 4: quanto vale l'ipotenusa?",
      steps: ["3² + 4² = 9 + 16 = 25", "√25 = 5"],
      answer: "5",
    },
    watchOut: ["Usa i quadrati, non i lati direttamente", "Solo con l'angolo di 90°"],
  },
  {
    id: "cerchio",
    title: "Circonferenza e cerchio",
    area: "Geometria",
    levelRange: [4, 8],
    tags: ["cerchio", "pi greco"],
    definition: "La circonferenza è la linea curva chiusa; il cerchio è la superficie racchiusa. π ≈ 3,14.",
    formulas: [
      "diametro  d = 2r",
      "circonferenza  C = 2πr = πd",
      "area del cerchio  A = πr²",
    ],
    rules: [
      "r = raggio, d = diametro = 2r.",
      "Usa π ≈ 3,14 (oppure 3,14159).",
    ],
    example: {
      prompt: "Area del cerchio con r = 5 (π ≈ 3,14).",
      steps: ["A = 3,14 × 5²", "= 3,14 × 25", "= 78,5"],
      answer: "78,5",
    },
    watchOut: ["L'area usa r², la circonferenza usa r", "Non confondere raggio e diametro"],
  },
  {
    id: "similitudine",
    title: "Similitudine e teorema di Talete",
    area: "Geometria",
    levelRange: [5, 8],
    tags: ["similitudine", "scala"],
    definition: "Due figure simili hanno la stessa forma: angoli uguali e lati in proporzione (rapporto di scala k).",
    formulas: [
      "lati corrispondenti: a'/a = b'/b = k",
      "perimetri nel rapporto k",
      "aree nel rapporto k²",
      "Talete: rette parallele tagliano trasversali in parti proporzionali",
    ],
    rules: [
      "Trova il rapporto di scala k tra due lati corrispondenti.",
      "Per il lato incognito imposta una proporzione.",
    ],
    example: {
      prompt: "Ingrandisci una figura di 3 volte: l'area?",
      steps: ["k = 3", "area × k² = × 9"],
      answer: "diventa 9 volte",
    },
    watchOut: ["Le aree crescono con k², non con k", "Gli angoli restano uguali"],
  },
  {
    id: "solidi",
    title: "Solidi: superfici e volumi",
    area: "Geometria",
    levelRange: [5, 8],
    tags: ["volumi", "solidi"],
    definition: "I solidi occupano spazio: si misurano la superficie (cm²) e il volume (cm³).",
    formulas: [
      "cubo: V = ℓ³ ; Stot = 6ℓ²",
      "parallelepipedo: V = a × b × c",
      "prisma / cilindro: V = area di base × altezza",
      "cilindro: V = πr²h",
      "piramide / cono: V = (area di base × h) ÷ 3",
      "sfera: V = (4/3) π r³",
    ],
    rules: [
      "Il volume si misura in unità cubiche (cm³).",
      "Trova l'area di base, poi moltiplica per l'altezza (prismi e cilindri).",
    ],
    example: {
      prompt: "Volume del cubo di spigolo 4.",
      steps: ["V = 4³", "= 64"],
      answer: "64",
    },
    watchOut: ["Piramide e cono: ricorda il ÷ 3", "cm³ per i volumi, cm² per le superfici"],
  },
  {
    id: "piano-cartesiano",
    title: "Piano cartesiano",
    area: "Geometria",
    levelRange: [3, 7],
    tags: ["coordinate", "punti"],
    definition: "Due assi perpendicolari (x orizzontale, y verticale) individuano i punti con coppie ordinate (x; y).",
    formulas: [
      "punto  P(x; y)   ;   origine  O(0; 0)",
      "distanza su un asse = |x₂ − x₁|",
      "punto medio = ((x₁+x₂)/2 ; (y₁+y₂)/2)",
    ],
    rules: [
      "Prima la x (destra/sinistra), poi la y (su/giù).",
      "Coordinate negative: a sinistra e in basso.",
    ],
    example: {
      prompt: "Punto medio di A(2; 4) e B(6; 8).",
      steps: ["x: (2 + 6)/2 = 4", "y: (4 + 8)/2 = 6"],
      answer: "M(4; 6)",
    },
    watchOut: ["Ordine: prima x poi y", "Non invertire gli assi"],
  },
  {
    id: "calcolo-letterale",
    title: "Calcolo letterale",
    area: "Relazioni e funzioni",
    levelRange: [5, 8],
    tags: ["lettere", "termini simili"],
    definition: "Le lettere rappresentano numeri: si calcola con le regole, riducendo i termini simili.",
    formulas: [
      "termini simili = stessa parte letterale → somma i coefficienti",
      "a + a = 2a   ;   3x − x = 2x",
      "a × a = a²   ;   aᵐ × aⁿ = aᵐ⁺ⁿ",
      "a(b + c) = ab + ac   (distributiva)",
    ],
    rules: [
      "Somma o sottrai solo i termini simili.",
      "Moltiplica i coefficienti tra loro e le lettere tra loro.",
    ],
    example: {
      prompt: "Semplifica 3x + 2 + 2x − 5.",
      steps: ["3x + 2x = 5x", "2 − 5 = −3", "= 5x − 3"],
      answer: "5x − 3",
    },
    watchOut: ["2x e 2x² non sono simili", "3 + 2x non si somma (resta 3 + 2x)"],
  },
  {
    id: "equazioni",
    title: "Equazioni di primo grado",
    area: "Relazioni e funzioni",
    levelRange: [5, 8],
    tags: ["equazioni", "incognita"],
    definition: "Un'equazione è un'uguaglianza con un'incognita x; risolverla significa trovare il valore che la rende vera.",
    formulas: [
      "puoi aggiungere/togliere lo stesso numero ai due membri",
      "puoi moltiplicare/dividere i due membri per lo stesso numero (≠ 0)",
      "un termine cambia membro cambiando segno",
    ],
    rules: [
      "Porta le x da una parte e i numeri dall'altra.",
      "Riduci i termini simili e dividi per il coefficiente di x.",
      "Verifica sostituendo il valore trovato.",
    ],
    example: {
      prompt: "Risolvi 2x + 3 = 11.",
      steps: ["2x = 11 − 3", "2x = 8", "x = 8 ÷ 2 = 4"],
      answer: "x = 4",
    },
    watchOut: ["Cambiando membro si cambia segno", "Verifica sempre la soluzione"],
  },
  {
    id: "funzioni-retta",
    title: "Funzioni e la retta",
    area: "Relazioni e funzioni",
    levelRange: [5, 8],
    tags: ["funzioni", "retta"],
    definition: "Una funzione associa a ogni x un solo y; la proporzionalità diretta e la retta sono funzioni.",
    formulas: [
      "retta:  y = m x + q",
      "m = pendenza (coefficiente angolare)",
      "q = punto in cui taglia l'asse y",
      "proporzionalità diretta: y = m x  (q = 0)",
    ],
    rules: [
      "Per disegnare: calcola y per due valori di x e unisci i punti.",
      "m > 0 la retta sale, m < 0 scende.",
    ],
    example: {
      prompt: "Per y = 2x + 1, trova y in x = 0 e x = 3.",
      steps: ["x = 0 → y = 1", "x = 3 → y = 7"],
      answer: "(0; 1) e (3; 7)",
    },
    watchOut: ["q è il valore di y quando x = 0", "Se q = 0 la retta passa per l'origine"],
  },
  {
    id: "statistica",
    title: "Statistica e grafici",
    area: "Dati e previsioni",
    levelRange: [3, 7],
    tags: ["media", "grafici"],
    definition: "La statistica raccoglie e descrive i dati con frequenze, indici e grafici.",
    formulas: [
      "media = somma dei dati ÷ numero dei dati",
      "moda = valore più frequente",
      "mediana = valore centrale dei dati ordinati",
      "frequenza relativa = frequenza ÷ totale",
    ],
    rules: [
      "Ordina i dati per trovare la mediana.",
      "Scegli il grafico adatto: barre, torta o linee.",
    ],
    example: {
      prompt: "Media di 4, 7, 7, 10.",
      steps: ["4 + 7 + 7 + 10 = 28", "28 ÷ 4 = 7"],
      answer: "7",
    },
    watchOut: ["La moda può non essere unica", "Con n pari la mediana è la media dei due centrali"],
  },
  {
    id: "probabilita",
    title: "Probabilità",
    area: "Dati e previsioni",
    levelRange: [4, 8],
    tags: ["probabilità", "eventi"],
    definition: "La probabilità misura quanto è probabile un evento, da 0 (impossibile) a 1 (certo).",
    formulas: [
      "P = casi favorevoli ÷ casi possibili",
      "0 ≤ P ≤ 1",
      "P in percentuale = P × 100",
    ],
    rules: [
      "Conta i casi possibili (equiprobabili) e quelli favorevoli.",
      "Evento certo P = 1, impossibile P = 0.",
    ],
    example: {
      prompt: "Lancio di un dado: probabilità di un numero pari.",
      steps: ["pari: 2, 4, 6 → 3 favorevoli", "possibili: 6", "P = 3/6 = 1/2"],
      answer: "1/2  (50%)",
    },
    watchOut: ["I casi devono essere equiprobabili", "P non può superare 1"],
  },
];
