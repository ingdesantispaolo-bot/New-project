# Pipeline biomi AAA adattata a Godot 2D

## Decisione architetturale

I chunk sono celle di streaming, non unità artistiche. Nessun chunk decide da
solo il proprio paesaggio. Tutti i renderer campionano una composizione globale
continua in coordinate mondo; il bordo di una cella non deve produrre una
variazione visiva.

Il fondale della Radura è concept art e riferimento di grammatica: palette,
forme, densità, gerarchia e luce. Non viene ripetuto né esteso come texture.

## Strati della composizione globale

1. **Macro-layout persistente**
   - regioni organiche definite da campi di influenza e noise a bassa frequenza;
   - radure, aree dense, bordi naturali, acqua e landmark in coordinate mondo;
   - seed stabile e dati serializzabili indipendenti dallo streaming.

2. **Rete strutturale**
   - spline globali per sentieri, corsi d'acqua, ponti e collegamenti;
   - corridoi di gameplay e coni visuali protetti dal dressing;
   - raccordi curvi, mai linee terminate sul bordo del chunk.

3. **Superficie continua**
   - terreno composto da terrain tiles/decal modulari e maschere globali;
   - transizioni determinate dai vicini o da pesi continui, non da rettangoli;
   - variazioni di colore leggere e condivise dall'intero bioma.

4. **Assemblies naturali**
   - gruppi authored: quercia + cespugli + fiori + rocce + ombra;
   - distribuzione blue-noise/Poisson, vincolata da habitat e distanze;
   - varianti per silhouette, età, stagione e orientamento;
   - gli oggetti singoli casuali sono limitati ai dettagli minuti.

5. **Hero pockets**
   - piccole scene curate inserite nella composizione procedurale tramite
     maschere morbide: portale, piazza, laghetto, casa, punto didattico;
   - ogni pocket modifica densità, percorsi e quinte circostanti;
   - nessun fondale rettangolare a pieno chunk.

6. **Atmosfera per bioma**
   - luce, foschia, particelle, acqua e vento derivati da un profilo unico;
   - transizione interpolata tra profili nelle zone di confine;
   - reduced motion e contrasto accessibile come policy globali.

7. **Streaming e HLOD 2D**
   - HERO: assemblies completi, animazioni e particelle;
   - NEAR: sprites completi con animazioni ridotte;
   - FAR: cluster prerenderizzati/proxy e niente particelle;
   - MINIMAL: silhouette e macro-colore;
   - pooling per props, marker e VFX ricorrenti.

## Grammatica “Animal Crossing” della Radura Accademia

- percorso principale sinuoso e leggibile;
- centro respirabile, bordi densi e morbidi;
- grandi alberi come quinte, arbusti medi come raccordo, fiori come accento;
- un landmark dominante per schermata e massimo due secondari;
- oggetti in famiglie, non distribuiti uniformemente;
- acqua e rocce seguono curve coerenti e creano piccoli punti di sosta;
- palette calda con verdi differenziati per profondità;
- interattivi evidenti, spazio libero attorno e fondale meno contrastato.

## Componenti da introdurre

### `WorldCompositionData`

Risorsa globale generata dal seed con regioni, spline, clearings, landmark,
habitat masks e profili atmosferici.

### `BiomeProfile`

Risorsa dati con palette, terrain set, assemblies, densità, scale, atmosfera,
LOD e regole di transizione.

### `WorldCompositionGenerator`

Genera il macro-layout una volta. Usa coordinate mondo e produce dati stabili;
non crea Node2D e non dipende dai chunk caricati.

### `ChunkCompositionSampler`

Interseca la composizione globale con la cella richiesta. Il risultato è un
ritaglio della stessa scena continua, non una nuova generazione indipendente.

### `BiomeSurfaceRenderer`

Disegna terreno, sentieri, acqua, rive e decal mediante maschere continue o
TileMapLayer terrain transitions.

### `BiomeAssemblySpawner`

Colloca assemblies con blue-noise e regole di habitat; mantiene clear zone,
collisioni e leggibilità degli obiettivi.

## Sequenza di implementazione

### A1 · Separare streaming e composizione

- introdurre `WorldCompositionData` e campionamento in coordinate globali;
- mantenere invariati save, collisioni e interazioni;
- audit: lo stesso punto mondo restituisce gli stessi pesi da chunk diversi.

### A2 · Radura procedurale completa

- ricostruire il linguaggio del fondale hero con terrain modulari e assemblies;
- rimuovere il fondale rettangolare dal runtime;
- creare tre hero pockets: Portale, Laghetto, Casa/Accademia.

### A3 · Sentieri e acqua continui

- spline globali con rive, ponti e clear zone;
- test automatico di continuità sui quattro bordi di ogni cella.

### A4 · Dressing gerarchico

- canopy, medium props e ground cover in passaggi separati;
- densità guidata da habitat, distanza e composizione;
- niente oggetti isolati senza funzione visiva.

### A5 · Profili degli altri biomi

- Bosco, Dorsale, Cratere, Rovine e Cristallo riusano la stessa pipeline;
- cambiano profilo, assemblies, superficie e atmosfera;
- transizioni larghe almeno metà viewport, mai coincidenti con un bordo chunk.

### A6 · HLOD, pooling e QA

- misurazione nodi, draw call, memoria texture e streaming hitch;
- proxy per cluster lontani e budget per Web/touch;
- screenshot suite con camera sui bordi e nelle transizioni.

## Criteri di accettazione

- nessun bordo chunk riconoscibile fermando la camera o muovendosi;
- nessuna texture hero rettangolare visibile;
- sentieri e acqua attraversano le celle senza discontinuità;
- almeno tre scale di vegetazione e cinque assemblies per bioma;
- ogni schermata contiene gerarchia chiara: landmark, percorso, quinte;
- interattivi leggibili senza sovraccaricare il paesaggio;
- 60 FPS target desktop/Web e modalità ridotta per touch.

## Stato implementazione · 2026-07-21

- A1 completato: `WorldCompositionData`, generator e sampler globali;
- A2 completato: fondale hero rimosso dal runtime e sostituito da superficie continua;
- A3 completato: spline, acqua e feature con ownership globale oltre i bordi;
- A4 completato: assemblies deterministici con clear zone e distribuzione globale;
- A5 completato: sei `BiomeProfile` sovrapposti tramite pesi continui;
- A6 completato: LOD 0/1/2, riduzione cluster e audit di budget/continuità;
- fixture, round-trip, C-10, build, export Web e Windows verdi.

Resta QA percettiva manuale: screenshot comparativi su movimento reale, aspect
ratio diversi e attraversamento delle zone di transizione.

## Revisione materiale world-space · 2026-07-21

Il confronto percettivo ha mostrato che macro-layout e assemblies non bastano
quando la superficie resta piatta. La pipeline ora usa cinque underpainting
pittorici (`academy`, `wild`, `mineral`, `magic`, `water`) e una texture terra
per i sentieri. Non sono fondali-scena: sono materiali uniformi senza landmark,
ricombinati dal renderer.

- `painterly_ground.gdshader` campiona coordinate mondo, interpola i pesi di
  bioma agli angoli e miscela due frequenze ruotate con rumore macro;
- il `mirror-repeat` rende continue anche immagini AI i cui bordi non sono
  pixel-perfect, eliminando le linee di ripetizione sugli assi mondo;
- tutti i LOD usano lo stesso campionamento: il LOD riduce nodi/assemblies, mai
  il materiale al bordo;
- i sentieri sono `Line2D` curvi, texturizzati e deterministici, con fascia di
  sponda e highlight; non vengono più disegnati come segmenti piatti per chunk;
- acqua e laghetti usano maschere organiche, materiale animato world-space e
  sponda separata;
- il fondale hero rettangolare e gli splat circolari legacy sono esclusi dal
  runtime procedurale;
- gli assemblies adottano tre altezze percettive (silhouette, massa media,
  gonna bassa) e coordinate globali, così i boschetti attraversano lo streaming.

Lo script `terrain_render_probe.gd` produce screenshot diurni stabili per la QA
visiva automatizzabile; il probe non modifica seed, collisioni, save o gameplay.

## Pass habitat e varieta compositiva · 2026-07-21

La seconda revisione elimina la distribuzione puramente decorativa e introduce
relazioni ecologiche leggibili:

- il corso della Dorsale e una spline Catmull-Rom a larghezza continua, con
  sagoma di riva, materiale world-space e tangente usata dai ponti;
- `BiomeDetailSpawner` usa un reticolo globale deterministico: ninfee e fiori
  d'acqua stanno nell'alveo, canneti/cattail sulla fascia umida, felci, foglie,
  ceppi, pietre e rune dipendono dal bioma;
- un atlante RGBA dedicato contiene sedici micro-dettagli pittorici; il crop e
  indipendente dalla risoluzione sorgente e puo essere rigenerato senza toccare
  il codice;
- gli assemblies non condividono piu un solo schema: boschetto, isola fiorita,
  sottobosco morto e affioramento usano silhouette e footprint distinti;
- le prop d'acqua prefabbricate non vengono sovrapposte al fiume; i ponti sono
  orientati ortogonalmente alla tangente locale;
- il terreno alterna tappeto ricco e radure calme tramite maschere macro globali;
  i sentieri sono spline uniche, piu sottili e fuse cromaticamente nel prato;
- il render probe produce quattro immagini (`academy`, `geo`, `wild`, `logic`)
  per confronti percettivi ripetibili.

## Confine diegetico e contenuti progressivi · 2026-07-21

Il mondo utile resta una matrice 8×8 da 896 px per cella (7168×7168), ma la
camera non espone più il clear grigio del viewport. Oltre il perimetro viene
disegnata una fascia di underpainting world-space coerente con i pesi dei biomi;
quattro collisioni continue sono mascherate da una cintura di alberi, rocce e
cristalli. Un resume legacy fuori mappa viene ricondotto entro il margine sicuro.
L'aspect `expand` elimina inoltre le bande nere nelle viewport Web non 16:9.

Il probe comprende ora `ruins`, `north-edge` ed `east-edge`: verifica insieme
la sostituzione delle primitive provvisorie di Rovine/Cristallo e la copertura
visiva dei bordi.

Gli incontri non ereditano più sempre Matematica. La coppia bioma/archetipo
instrada le sessioni verso Matematica, Italiano, Inglese, Coding, Fisica,
Musica, Latino ed Elettronica; la materia è esplicitata nel titolo della prova.
La materia-focus dell'apparato resta indipendente: le altre missioni allenano
la relativa mastery, mentre il gate corrente richiede la sua materia prevista.

Per Matematica il piccolo banco statico è stato sostituito da un generatore
parametrico cumulativo. I livelli 1–24 attraversano otto complessità (una ogni
tre livelli), da calcolo, tabelline e sequenze fino a frazioni, geometria,
percentuali, equazioni, coordinate e statistica. Le ultime 28 firme vengono
ricordate per evitare ripetizioni ravvicinate; gli argomenti dovuti dal ripasso
spaziato hanno priorità senza congelare i valori numerici.

`c11_world_content_audit.gd` rende questi requisiti bloccanti: perimetro e
barriere, recupero posizione, otto materie, assenza di firme duplicate fra due
missioni consecutive, complessità 8 e presenza delle famiglie avanzate.
