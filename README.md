# Eli Quest - Accademia delle Missioni

Gioco educativo 2D per tablet. **Godot è l'unico runtime**: mondo esterno,
esercizi, salvataggi, economia, NORA, minigiochi e narrazione girano tutti in
`godot/`. Vite serve soltanto il guscio Web (`index.html`, service worker,
manifest PWA) che carica l'export.

Direzione e stato dei contenuti restano in
[docs/ARCHITETTURA_FULL_GODOT.md](docs/ARCHITETTURA_FULL_GODOT.md),
[docs/VISIONE_DI_GIOCO.md](docs/VISIONE_DI_GIOCO.md) e
[docs/STATO_CONTENUTI_E_NARRATIVA.md](docs/STATO_CONTENUTI_E_NARRATIVA.md).
Questo README dice solo come si avvia, si costruisce e dove si mettono le mani.

## Avvio

```bash
npm install
npm run release:web   # stamp versione → export Godot → sync manifest → build
npm run preview
```

`npm run dev` serve il guscio ma mostra **l'ultimo export**: le modifiche agli
script o agli asset Godot si vedono solo dopo `npm run export:web`.

Per provare da tablet sulla stessa rete Wi-Fi: `npm run dev:lan`, poi apri
`http://IP_DEL_PC:5173` dal tablet. Guida completa in
[docs/TABLET_AND_DEPLOY.md](docs/TABLET_AND_DEPLOY.md).

## Struttura

| | |
|---|---|
| `godot/` | il gioco. Struttura interna in [godot/README.md](godot/README.md) |
| `godot/data/banks` | banchi esercizi per materia — **prodotti dal bake**, non scritti a mano |
| `content-sources` | fonte di verità di sei banchi (vedi sotto) |
| `art-sources` | sorgenti d'arte fuori dal codice, con il proprio README |
| `scripts` | pipeline Node: export, versione, bake dei banchi, audit di release |
| `public` | guscio Web, service worker, destinazione dell'export |

### content-sources

Il runtime TypeScript/Phaser è stato rimosso il 18 agosto 2026: non veniva più
eseguito da nessuno, ma restava in ogni ricerca e i suoi 38 test davano un verde
che non riguardava il gioco.

Di quelle 75.000 righe **otto file erano ancora vivi**, ed è la cosa importante
da sapere: `scripts/build-exercise-banks.mjs` li importa a runtime per generare
sei dei dodici banchi.

```
content-sources/data/procedural/   italiano, inglese, latino, elettronica, coding
content-sources/data/greenhouse.ts scienze
content-sources/procedural/ types/ tipi condivisi dai precedenti
```

Modificare quei contenuti significa modificare **questi** file e rieseguire
`npm run banks:build`. Non si edita il JSON in `godot/data/banks/`: il bake lo
sovrascrive.

Le altre materie non passano di qui — matematica ha il generatore nativo
`godot/scripts/game/math_exercise_generator.gd`, e geografia, storia, logica,
fisica e musica sono curate dentro lo script di bake stesso (la teoria di
`theoryCatalog.ts` è trascritta lì dentro da tempo, perché Node non ne risolveva
gli import).

Il resto delle 75.000 righe è recuperabile dalla storia git.

## Verifica

```bash
npm run audit:godot          # tutti gli audit headless (lunghi)
npm run audit:godot mystery  # solo quelli che combaciano col nome
npm run audit:web            # coerenza del manifest di release
npm run smoke:web:godot      # smoke test dell'export Web
```

Gli audit sono la rete di sicurezza principale: girano headless, con un save
isolato e un verde onesto — un `assert` fallito in Godot non cambia l'exit code,
ed è esattamente per questo che esiste `scripts/run-godot-audits.mjs`.

Se un audit fallisce con «Identifier ... not declared», la cache delle classi è
vecchia: `godot --headless --path godot --import` e si riparte.

Per modifiche lato Godot serve comunque una verifica a occhio: nessuna schermata
nera in avvio o nelle transizioni, console senza errori, screenshot quando cambia
il layout.

## Deploy

`.github/workflows/deploy-github-pages.yml` esporta da Godot, riallinea il
manifest e pubblica su GitHub Pages a ogni push su `main`. L'export **non è
tracciato da git**: `public/godot/outdoor/` viene ricostruito, mai committato.

## Dove si modificano i contenuti

- Esercizi: `content-sources/` → `npm run banks:build` → `godot/data/banks/*.json`
- Minigiochi e coppie da abbinare: `godot/scripts/game/minigame_manager.gd`
- NPC, dialoghi, maestri, ritrovi: i cataloghi in `godot/scripts/game/*_catalog.gd`
- Cosmetici: `godot/scripts/game/reward_catalog.gd` → `npm run assets:reward`
- Voce e reazioni di NORA: `godot/scripts/game/nora_voice.gd`
- Progressione e mastery: `godot/scripts/game/progression_manager.gd`
- Salvataggi e profili: `godot/scripts/game/save_manager.gd`, `player_profiles.gd`
