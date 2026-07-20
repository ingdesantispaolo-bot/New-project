# Direzione artistica Godot — Radura Accademia

## Obiettivo

Portare il mondo esterno verso un **cozy life-sim educativo**: natura ricca,
forme morbide, colori leggibili e landmark memorabili. Il riferimento emotivo è
la quotidianità accogliente di un gioco alla Animal Crossing, ma l'identità
resta originale e legata a Eli Quest, NORA e all'apprendimento.

Il concept di riferimento è [Radura Accademia — concept v1](art-direction/radura-accademia-concept-v1.png).

Il primo atlante AI sorgente è `godot/assets/radura-academia-natural-atlas.png`;
la variante operativa con alpha è `godot/assets/radura-academia-natural-atlas-v2.png`:
12 elementi naturali su griglia 4×3, integrati come atlas region soltanto nel
bioma `academy` per mantenere distinti gli altri biomi.

Il secondo atlante sorgente è `godot/assets/bosco-variabile-natural-atlas.png`;
la variante operativa con alpha è `godot/assets/bosco-variabile-natural-atlas-v2.png`, dedicato
al Bosco Variabile: usa silhouette più selvagge, muschio, radici, funghi e
bacche, con mapping separato nel visual factory.

Il terzo atlante sorgente è `godot/assets/dorsale-geografica-natural-atlas.png`;
la variante operativa con alpha è `godot/assets/dorsale-geografica-natural-atlas-v2.png`, dedicato
alla Dorsale Geografica: acqua, cascate, ponti, rocce stratificate, pozze,
segnali di sentiero e fiori alpini.

Il quarto atlante sorgente è `godot/assets/cratere-logico-natural-atlas.png`;
la variante operativa con alpha è `godot/assets/cratere-logico-natural-atlas-v2.png`, dedicato
al Cratere Logico: cristalli, cairn, fiori simmetrici, archi, pozze prismatiche
e pattern naturali che comunicano il tema della logica senza ricorrere a
macchinari o interfacce tecnologiche.

## Valutazione dello stato attuale

| Area | Stato | Valutazione |
| --- | --- | --- |
| Streaming e parità | stabile | da preservare |
| Silhouette di alberi, rocce e cristalli | buona | serve più varietà per bioma |
| Densità naturale | media | aumentare micro-dettagli senza riempire i corridoi |
| Landmark | buona base | renderli più abitabili e didattici |
| Palette e atmosfera | coerente | aggiungere stagioni e variazioni orarie |
| Identità educativa | presente | renderla visibile negli oggetti e nei segnali |
| Qualità “AAA” | vertical slice | richiede atlanti dedicati, non solo più particelle |

## Regola tecnica per gli asset AI

Gli asset generati con AI vanno usati come:

- atlanti di elementi naturali con sfondo trasparente o rimovibile;
- texture tileable per terreno, acqua, rocce e sentieri;
- landmark unici per i sei biomi;
- set stagionali e varianti giorno/notte;
- concept e paint-over di riferimento per mantenere coerenza.

Non usare un'immagine AI completa come sfondo di un chunk: perde la coerenza
con collisioni, y-sort, streaming e parità Phaser/Godot.

## Priorità per bioma

### Radura Accademia

Prati stratificati, querce tonde, siepi, margherite, panchine, cartelli,
meridiane, piccoli orti didattici e un ruscello. Colori: verde muschio, menta,
ocra e crema.

### Bosco variabile

Felci, tronchi caduti, funghi, lucciole, cespugli con bacche e sentieri umidi.
La densità deve aumentare ai bordi, lasciando il centro navigabile.

### Dorsale geografica

Rocce stratificate, ruscelli, cascate, ponticelli, canne palustri, mappe su
cartelli e punti panoramici.

### Cratere logico

Cristalli, pietre geometriche, fiori simmetrici, lanterne e percorsi a nodi.
Gli elementi naturali devono suggerire pattern e ragionamento, senza sembrare
un livello tecnologico.

### Rovine del Relitto

Radici che avvolgono metallo antico, muschio, colonne spezzate, rampicanti,
pozze e piccoli fuochi di campo.

### Nido cristallino

Cristalli traslucidi, fiori luminescenti, polline, acqua scura e riflessi
colorati. Ridurre il numero di elementi opachi per mantenere leggibilità.

## Roadmap “AAA sostenibile”

1. Creare un atlante naturale per ogni bioma: 12–16 elementi, tre scale e due
   varianti cromatiche.
2. Aggiungere micro-props decorativi non collidenti: erba alta, fiori, foglie,
   sassolini e insetti, con budget per chunk.
3. Aggiungere tre landmark abitabili per bioma, ciascuno con una funzione
   educativa o narrativa.
4. Introdurre stagioni leggere e palette alba/giorno/tramonto/notte, senza
   cambiare il seed di gioco.
5. Implementare LOD: sprite pieni nel chunk vicino, silhouette semplificate nei
   chunk periferici.
6. Solo dopo il test di giocabilità, sostituire progressivamente i fallback
   procedurali con gli asset AI approvati.

## Criteri di accettazione

- ogni elemento decorativo ha una silhouette leggibile a 100% e 50% di scala;
- nessun cluster naturale blocca il percorso o nasconde un'interazione;
- le collisioni restano indipendenti dall'immagine artistica;
- il frame-time non peggiora con 25 chunk caricati;
- la palette comunica il bioma prima ancora del testo HUD;
- tesori, incontri e portale hanno sempre un contrasto superiore allo sfondo.
