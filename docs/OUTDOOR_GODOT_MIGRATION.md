# Migrazione del mondo esterno a Godot

> **Contesto strategico**: la direzione confermata del progetto è **full Godot**
> (motore unico, niente Phaser). Questo documento descrive il modulo del mondo
> esterno, che è la testa di ponte di quella migrazione. Visione e piano
> complessivo: [VISIONE_DI_GIOCO.md](VISIONE_DI_GIOCO.md) ·
> [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md) ·
> [ARCHITETTURA_FULL_GODOT.md](ARCHITETTURA_FULL_GODOT.md).

## Confine del modulo

Il modulo Godot contiene rendering, movimento, camera, chunk streaming e
interazioni ambientali. Phaser resta responsabile di missioni, teoria NORA,
energia, frammenti, cosmetici e salvataggio canonico.

## World request (Phaser → Godot)

```json
{
  "schemaVersion": 1,
  "playerId": "local",
  "worldSeed": "outdoor-YYYY-MM-DD-level",
  "playerLevel": 1,
  "avatar": {"outfit": "avatar-base", "accessory": "", "pet": ""},
  "outdoorState": {
    "completedEncounterIds": [],
    "collectedTreasureIds": [],
    "clearedHazardIds": [],
    "fragments": 0
  }
}
```

## World result (Godot → Phaser)

```json
{
  "schemaVersion": 1,
  "energyEarned": 0,
  "fragmentsEarned": 0,
  "completedEncounterIds": [],
  "collectedTreasureIds": [],
  "guardianWins": 0,
  "unlockedRewards": []
}
```

## Streaming

Il mondo logico è composto da 64 chunk, con coordinate `-4..3` su entrambi gli
assi. Il `OutdoorChunkManager` mantiene graficamente caricata una finestra 3×3
centrata sul giocatore e scarica i nodi lontani. I dati dei chunk sono sempre
rigenerabili dal seed e dalle coordinate.

## Parità del generatore

Il generatore Phaser reale (`src/procedural/OutdoorChunkGenerator.ts`,
`generateOutdoorChunk`) è la fonte di verità; il seed dei chunk ha formato
`<seed>:chunk:<chunkX>:<chunkY>` e quello dei biomi non ancorati
`<seed>:biome:<floor(chunkX/2)>:<floor(chunkY/2)>`. Il generatore GDScript
(`godot/scripts/outdoor_generator.gd`) lo riproduce **estrazione per
estrazione**: stesso PRNG (mulberry32 + FNV-1a), stesso ordine di consumo,
stesso arrotondamento (`Math.round` ↔ `floor(x+0.5)`).

Nota di portabilità: la selezione degli incontri usava
`Array.sort(() => random() - 0.5)`, il cui numero di confronti dipende dal
motore JS e non è riproducibile. È stata sostituita da uno shuffle
Fisher–Yates seedato (`shuffle()`), portabile e identico nei due linguaggi.

Il contratto di parità è la fixture ricca `godot/data/parity-fixtures.json`:

1. `node scripts/build-outdoor-fixtures.mjs` la genera dal generatore reale;
2. il test Vitest `outdoorGeneratorFixture.test.ts` verifica il lato
   TypeScript (confronto profondo del chunk completo);
3. `godot --headless --script res://scripts/fixture_audit.gd` verifica il lato
   GDScript.

I casi coprono origine, vicini positivi/negativi (`0_0`, `1_0`, `0_1`,
`-1_-1`, `1_1`, `-1_0`) e chunk lontani per i biomi non ancorati.

## Integrazione Web

Durante il prototipo desktop il bridge usa file `user://`. Nell’export Web,
`OutdoorSaveBridge` andrà collegato a `JavaScriptBridge` o a una pagina shell
che passa il JSON prima dell’avvio e riceve il risultato all’uscita. Il formato
non deve cambiare tra Web e Windows.

## Stato dei checkpoint

- **Punto 2:** attivo. Tesori e incontri vengono cercati tra tutti i chunk
  caricati, assegnano ricompense una sola volta e mostrano un feedback contestuale.
- **Punto 3:** attivo. Il ciclo dura 120 secondi, modifica la luce del mondo e
  aggiorna l'indicatore `Giorno`/`Alba`/`Notte` nell'HUD.
- **Punto 4:** attivo. Il portale scrive il risultato JSON e chiude il modulo
  Godot; l'HUD ha un pulsante di uscita. Gli **incontri rimbalzano a Phaser**:
  Godot esce salvando `pendingEncounter` (id, tipo, difficoltà, nemico,
  ricompensa) e `resume` (posizione, ora); Phaser gioca il minigioco NORA
  esistente (`startEncounter`) e al termine **rientra automaticamente in Godot**
  ripristinando lo stato, con l'incontro ormai completato.

- **Punto 5:** esteso alla parità del **generatore ricco reale**. Il generatore
  GDScript ora replica biomi, patch, ostacoli tipizzati, prop, landmark,
  incontri, tesori e sentieri di `OutdoorChunkGenerator.ts`. Il contratto è la
  fixture `godot/data/parity-fixtures.json` (schema 2), verificata dal test
  Vitest e dall'audit Godot su un confronto profondo del chunk completo.
  Il vecchio harness semplificato (`outdoorAcademyGenerator.ts`,
  `generated-fixtures.json`) è stato dismesso.
- **Punto 6:** attivo per il trasporto. `save_bridge.gd` usa
  `JavaScriptBridge` sull'export Web e file `user://` su Windows; il modulo
  `src/integration/outdoorGodotBridge.ts` prepara la richiesta e legge il
  risultato nella shell Phaser.
- **Punto 7:** seconda passata. Il rendering è ora **procedurale e per bioma**:
  il terreno usa la texture SVG con tinta del bioma e i sentieri; ostacoli,
  prop e landmark sono forme vettoriali colorate dai campi `color` del
  generatore; tesori e incontri restano su SVG sostituibili. Il player e gli
  oggetti sono ordinati in profondità (y-sort), mentre terreno/bioma/sentieri
  stanno su uno strato di sfondo. Le interazioni sono su `Area2D` con segnali
  (nessuna scansione per-frame) e l'HUD è responsivo (ancore `Control`).
  L'input accetta tastiera, touch e mouse (click/drag).

Il round-trip Web è cablato: il pulsante "Godot" della scena Phaser chiama
`openOutdoorGodot`, e `consumeOutdoorWorldResult` applica l'esito al rientro.

## Giocabilità senza export Godot

Il gioco è **sempre giocabile senza compilare Godot**. All'avvio la scena
Phaser sonda `index.wasm` dell'export; se il bundle non esiste, il pulsante
"Godot" resta nel mondo Phaser nativo (completo) mostrando un avviso, invece di
navigare verso una pagina inesistente. Appena l'export Web è presente in
`public/godot/outdoor/`, il pulsante e il rimbalzo incontri si attivano da soli,
senza modifiche al codice.

## Export

I preset Windows e Web sono presenti nel progetto. L'export richiede però gli
Export Templates Godot della stessa versione dell'editor. Senza i template,
Godot carica e avvia la scena ma rifiuta correttamente la produzione del
binario/Web bundle.

Quando i template sono installati, l'export Web va in
`public/godot/outdoor/index.html`, già predisposto per l'URL `/godot/outdoor/`
usato dal bridge Phaser.
