# Eli Quest — mondo esterno Godot

Questo è il runtime nativo Godot di Eli Quest. La root Web e la scena principale
avviano Godot; Phaser non ha più un entrypoint nella build di produzione.

## Scope

- **sei biomi** (academy, ruins, geo, logic, wild, crystal) con ancore fisse e
  selezione procedurale per i chunk lontani;
- mondo logico 8×8 chunk (`x/y = -4..3`), 896 unità per chunk;
- streaming grafico 3×3 attorno al giocatore;
- movimento tastiera, touch e mouse (click/drag);
- generatore procedurale a **parità esatta** con Phaser
  (`src/procedural/OutdoorChunkGenerator.ts`): ostacoli tipizzati per bioma,
  prop, landmark, incontri (tabelline/mentale/capitali/geografia/guardiano),
  tesori con ricompense variabili e sentieri;
- ciclo giorno/notte con indicatore di fase e modulazione della luce;
- interazioni via `Area2D` + segnali (nessuna scansione per-frame), con feedback
  contestuale per tesoro, incontro e portale;
- depth ordering y-sort tra player e oggetti; terreno/bioma/sentieri su strato
  di sfondo;
- HUD responsivo (ancore `Control`) adatto a risoluzioni e aspect ratio diversi;
- portale di uscita nel mondo, più pulsante di uscita nell'HUD;
- save canonico Godot con migrazione idempotente dei vecchi file locali;
- renderer procedurale per bioma ad alto dettaglio (`visual_factory.gd`):
  ombre, glow additivi, alberi a chioma stratificata con ondeggiamento,
  cristalli luminosi, 12 tipi di prop, 6 landmark animati, portale con
  vortice e rune, player con camminata animata;
- atmosfera: palette giorno/notte a tre fasi (notte blu → alba calda →
  giorno), bagliori che si accendono al tramonto (gruppo `night_glow`),
  lucciole notturne, vignetta ai bordi, ping sul punto toccato;
- micro-animazioni senza Tween (`ambient_anim.gd`) e dettagli deterministici
  da RNG decorativo separato: la parità del generatore non è toccata;
- **bottega nativa Godot da 53 premi**: catalogo a sette categorie, acquisto,
  gating livello, equip/rimozione e persistenza nel save canonico. Outfit,
  accessorio, pet, livrea Bit ed emblema equipaggiato aggiornano subito la resa
  nel mondo; `avatarVisual` è il fallback visivo della sessione nativa.
- **HUD economia + obiettivo pinnato**: pannello con energia e frammenti della
  sessione (aggiornati in tempo reale, con popup "+N" fluttuante alla raccolta)
  e barra di avvicinamento al **prossimo cosmetico** della bottega
  ("Ti manca X energia / Puoi comprarlo!"). I campi `energy` e `nextReward`
  sono calcolati dal catalogo e dal save Godot.
- **nave nativa a sette ponti** con sfondi WebP e [riattivazione visiva in cinque
  fasi](../docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md): i 24 livelli accendono nodi,
  rete energetica, shader, impulsi e sequenze traguardo; restauri della bottega,
  NORA e diario di progresso restano integrati;
- **audio nativo** con musica/ambiente giorno-notte, focus esercizi e SFX UI.

## Avvio

Aprire la cartella `godot/` con Godot 4.x e avviare il progetto. La main scene è
`scenes/boot_menu.tscn`; il pulsante **GIOCA** entra nel mondo. Il progetto usa
il renderer Compatibility per mantenere una base adatta a Web e Windows.

Per vedere immediatamente le modifiche locali, avviare il progetto Godot, non
il vecchio runtime TypeScript:

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64.exe" --path godot
```

`npm run dev` serve invece l'ultimo export già presente in
`public/godot/outdoor`. Dopo modifiche Godot bisogna prima rigenerarlo:

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64_console.exe" --headless --path godot `
  --export-release Web public/godot/outdoor/index.html
npm run dev:lan
```

Per un controllo senza aprire la finestra:

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --quit-after 3
```

## Stato e persistenza

La persistenza economica, didattica, narrativa e cosmetica è autoritativa nel
save `user://eli-quest-save.json`. `NativeWorldState` contiene soltanto seed e
delta transitori della sessione. Non esistono più request/result file, bridge
JavaScript o ritorni a una shell esterna.

Missioni, enigmi ed esami applicano il costo normale di 3 energia quando il
saldo lo consente. Sotto soglia diventano ingressi di recupero gratuiti: il
giocatore non può restare bloccato fuori dall'unico loop che genera energia.

## Parità del generatore

`data/parity-fixtures.json` è una fixture **congelata**: descrive chunk per chunk
il mondo prodotto dal generatore, e `scripts/fixture_audit.gd` verifica che
`scripts/outdoor_generator.gd` continui a riprodurlo identico.

```powershell
godot --headless --path godot --script res://scripts/fixture_audit.gd
```

Nasceva come confronto fra due generatori — quello GDScript e quello TypeScript
di Phaser — rigenerabile con `scripts/build-outdoor-fixtures.mjs`. Il lato
TypeScript non esiste più: il generatore Godot è l'unica autorità, e la fixture
ha cambiato ruolo. Ora è una **regressione sul mondo**: garantisce che una
modifica al generatore non sposti un albero, un tesoro o un incontro nelle
partite già salvate.

Va rigenerata soltanto quando si vuole cambiare il mondo di proposito — e in quel
caso il diff del JSON è la lista esatta di cosa si sta spostando, da guardare
prima di accettarla.

Smoke test del gameplay Godot (tesoro → missione → esame finale):

```powershell
godot --headless --path . --script res://scripts/roundtrip_audit.gd
```

Smoke test della navigazione completa (`menu → mondo → nave → mondo`):

```powershell
godot --headless --path . --script res://scripts/game/boot_navigation_audit.gd
```

## Comandi della slice

- touch sul terreno o trascinamento: movimento;
- pulsante **AZIONE**: raccoglie, affronta o attraversa il portale;
- pulsante **IMPULSO**: stabilizza temporaneamente le anomalie;
- pulsanti dedicati: rotta missione/nave, Bottega e Manuale NORA;
- **COMANDI TOUCH**: lato, dimensione e visibilità dei comandi persistenti.

Tastiera e gamepad restano scorciatoie opzionali; nessuna interazione essenziale
su tablet dipende da `E`, `F`, `Invio` o `Esc`.

## Export

I preset `Windows` e `Web` sono già presenti in `export_presets.cfg`.
I template Web `4.7.1.stable` sono installati nella postazione documentata in
`insieme.md`; per altre macchine usare `Editor > Manage Export Templates`.

Sulla postazione documentata sono installati **solo i template Web**: l'export
`Windows` richiede prima `Editor > Manage Export Templates`.

```powershell
godot --headless --path . --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # dalla root: allinea build.json + sw.js e bumpa la cache
npm run audit:web
```

L'export Web va direttamente in `public/godot/outdoor`; la root Vite reindirizza
direttamente a `/godot/outdoor/index.html` senza caricare codice Phaser.

**L'export da solo non basta.** `audit:web` pretende che quattro valori
combacino: `buildId` e `cacheVersion` fra `public/build.json` e `public/sw.js`, e
le dimensioni di `index.pck`/`index.wasm` fra file reale, manifest e HTML
generato da Godot. Un export cambia le dimensioni e lascia indietro gli altri
due file, quindi l'audit diventa rosso: `npm run web:sync` risincronizza e
**bumpa la versione di cache**, che è ciò che fa scadere la PWA. Senza bump un
tablet che ha già aperto il gioco continua a servire il PCK vecchio.
