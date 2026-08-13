# Eli Quest - Accademia delle Missioni

Gioco educativo 2D. **Godot è l'unico runtime di gioco**: mondo esterno,
esercizi, save, economia, NORA, minigiochi-personaggio e narrazione girano
tutti in `godot/`. `npm run dev`/`vite build` non eseguono più codice di
gioco: servono solo l'export Web di Godot (`godotWebCompression`, vedi
`vite.config.mjs`).

`src/` **non è più il runtime**, ma non è nemmeno morto: contiene (a) le
ultime scene Phaser non ancora spente e (b) — questa è la parte viva — i
**generatori e i dati di contenuto** (missioni, teoria, template per materia)
che gli script di bake in `scripts/` trasformano nei banchi JSON in
`godot/data/banks/`. Finché quei generatori non vengono riscritti nativi in
GDScript (Fase 4 del piano sotto), `src/data`/`src/procedural` restano la
fonte di verità dei contenuti e si continuano a modificare — è lì che sono
finiti, ad esempio, i lavori recenti sui `distractorWhy`.

Direzione, fasi e stato di avanzamento **autoritativi** sono in
`docs/ARCHITETTURA_FULL_GODOT.md` (in particolare §7 per il piano a fasi e lo
spegnimento pianificato di Phaser in Fase 5/C-16) e in
`docs/VISIONE_DI_GIOCO.md`. Per lo stato reale dei contenuti materia per
materia vedi `docs/STATO_CONTENUTI_E_NARRATIVA.md`. Questo README descrive
solo come avviare/buildare il progetto, non lo stato del gioco.

## Avvio

```bash
npm install
npm run dev
```

Il comando completo di export è documentato in
`godot/README.md`. Senza questo passaggio `npm run dev` mostra l'ultimo `.pck`
esportato e non le modifiche correnti agli script o agli asset Godot.

Per provare da tablet sulla stessa rete Wi-Fi:

```bash
npm run dev:lan
```

Poi apri dal tablet `http://IP_DEL_PC:5173`.

Build di produzione:

```bash
npm run build
npm run preview
```

La build è già portabile per hosting gratuito statico:

```bash
npm run build
```

Guida completa: `docs/TABLET_AND_DEPLOY.md`.

## Struttura

Il gioco vero e proprio vive in `godot/` — vedi `godot/README.md` per la sua
struttura interna (autoload, scene, banchi, script di audit).

`src/` è la parte TypeScript, con due ruoli molto diversi che è importante non
confondere:

- **Pipeline di authoring dei contenuti (viva)** — `src/data/procedural/*`,
  `src/data/theoryCatalog.ts` e gli altri generatori/dataset per materia sono
  la fonte da cui gli script in `scripts/` (bake) producono i banchi JSON in
  `godot/data/banks/`. Si modificano ancora normalmente: è qui che finiscono,
  ad esempio, gli aggiornamenti a `distractorWhy` per materia.
- **Runtime Phaser (legacy, in spegnimento)** — `src/scenes`, `src/ui`,
  `src/core` (mission engine, save, audio Howler) sono il vecchio gioco
  browser. Non è più il gioco che gli studenti giocano; resta nel repo perché
  lo spegnimento è pianificato per fasi (Fase 4/5, blocco C-16 in
  `docs/ARCHITETTURA_FULL_GODOT.md`) e non ancora eseguito — l'inventario
  dettagliato di cosa è già superato da Godot e cosa no è in quel documento,
  §7ter/§7quater.

`docs/`: design, architettura, pedagogia, formato missioni e roadmap.

## Dove modificare i contenuti

Questi percorsi alimentano la pipeline di bake verso Godot (non il runtime
Phaser):

- Template/generatori per materia: `src/data/procedural/*`
- Teoria/spiegazioni NORA: `src/data/theoryCatalog.ts`
- Script di bake verso `godot/data/banks/`: `scripts/build-exercise-banks.mjs`
  (vedi anche `npm run audit:godot`)

I minigiochi-personaggio, l'apertura delle prove, il save e NORA in gioco si
modificano invece direttamente in `godot/scripts/game/` (vedi
`godot/README.md`).

## Qualita e verifica

Comandi principali:

```bash
npm run build
npm test
npm run audit:godot
```

`npm test` copre generatori/validatori TS della pipeline di authoring;
`npm run audit:godot` esegue gli audit headless Godot (contenuti, minigiochi,
narrazione — vedi `scripts/run-godot-audits.mjs`). Per modifiche lato Godot,
verificare anche a runtime nell'editor o nell'export Web:

- nessuna schermata nera in avvio o transizioni;
- console senza errori;
- screenshot desktop/tablet quando cambia il layout.
