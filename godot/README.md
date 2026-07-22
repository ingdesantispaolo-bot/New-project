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

Il generatore GDScript (`scripts/outdoor_generator.gd`) è speculare a quello
TypeScript. Il contratto condiviso è la fixture `data/parity-fixtures.json`:

```powershell
# 1) genera la fixture dal generatore reale Phaser (lato Node)
node scripts/build-outdoor-fixtures.mjs
# 2) verifica il lato Godot
godot --headless --path godot --script res://scripts/fixture_audit.gd
```

Il test Vitest `src/integration/__tests__/outdoorGeneratorFixture.test.ts`
verifica lo stesso file sul lato TypeScript. Qualsiasi modifica al generatore
richiede di rigenerare la fixture e rieseguire entrambi i controlli.

Smoke test del gameplay Godot (tesoro → missione → esame finale):

```powershell
godot --headless --path . --script res://scripts/roundtrip_audit.gd
```

Smoke test della navigazione completa (`menu → mondo → nave → mondo`):

```powershell
godot --headless --path . --script res://scripts/game/boot_navigation_audit.gd
```

## Comandi della slice

- `WASD`/frecce: movimento;
- touch: destinazione del personaggio;
- `E`: raccoglie, affronta o attraversa il portale quando Eli è vicino;
- `ESC`: chiude un pannello oppure torna alla scena precedente salvando.

## Export

I preset `Windows` e `Web` sono già presenti in `export_presets.cfg`.
I template Web `4.7.1.stable` sono installati nella postazione documentata in
`insieme.md`; per altre macchine usare `Editor > Manage Export Templates`.

```powershell
godot --headless --path . --export-release Windows build/eli-quest-outdoor.exe
godot --headless --path . --export-release Web ../public/godot/outdoor/index.html
```

L'export Web va direttamente in `public/godot/outdoor`; la root Vite reindirizza
direttamente a `/godot/outdoor/index.html` senza caricare codice Phaser.
