# NPC illustrati · Mondo 1

Primo gruppo del catalogo grafico generato con lo strumento ImageGen integrato e rifinito localmente con rimozione chroma-key, despill, trim e ridimensionamento a 384×384 pixel. La stessa pipeline è stata poi applicata ai 69 abitanti dei mondi 1–23.

Asset finali:

- `tobia-v1.png`
- `ersilia-v1.png`
- `puccio-v1.png`

I PNG hanno alpha reale e sono usati sia nel mondo sia nei ritratti di dialogo. `NpcActor` e `NpcPortrait` risolvono automaticamente il percorso dall'ID del catalogo e mantengono il rendering geometrico precedente come fallback per itineranti o asset eventualmente mancanti.

## Prompt finali

Base comune:

> Personaggio NPC full-body pronto per la produzione in un’avventura educativa fantasy 2D top-down. Illustrazione 2D dipinta di qualità, finitura vicina alla pixel art pittorica, silhouette compatta e nitida, adatta ai bambini e leggibile a 80–100 pixel. Vista frontale a tre quarti da una camera leggermente rialzata, corpo intero centrato, piedi visibili, illuminazione ambientale dall’alto a sinistra, nessuna ombra proiettata. Un solo personaggio su fondo chroma-key perfettamente uniforme, senza testo, watermark, pose aggiuntive o riflessi.

Tobia:

> Adulto un po’ burbero ma amabile, contatore dei cristalli. Abiti da lavoro ocra e marrone, stivali robusti, piccola borsa per il conteggio e bastone corto di legno con tacche incise. Espressione concentrata e lievemente sospettosa, mai minacciosa. Fondo `#ff00ff`.

Nonna Ersilia:

> Anziana fornaia calorosa e custode di una filastrocca numerica. Abito rosa polvere, grembiule crema, fazzoletto bordeaux sui capelli argento raccolti, scarpe pratiche; tiene con entrambe le mani una piccola focaccia rotonda con semi di girasole. Volto gentile, vivace e saggio. Fondo `#00ff00`.

Puccio:

> Abitante adulto amichevole e bislacco che saluta per nome tutti i quaranta cristalli. Abiti da campo verde oliva con toppe color cuoio, borsa a tracolla e un piccolo cristallo ambrato sollevato in segno di saluto. Baffi scuri ordinati e capelli ricci compatti; espressione sincera, divertita e leggermente eccentrica. Fondo `#ff00ff`.

## Processo

I sorgenti chroma sono intermedi in `tmp/imagegen/world01-npcs/`. Lo script `scripts/process-chroma-character.mjs` campiona il bordo, calcola un matte morbido, elimina la dominanza verde/magenta, applica il despill, ritaglia e valida angoli trasparenti e copertura del soggetto.
