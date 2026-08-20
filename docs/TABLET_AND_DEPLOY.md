# Tablet E Pubblicazione Web

## Obiettivo

Eli Quest usa il runtime Godot esportato sul Web, senza backend. Vite serve la
shell e l'export presente in `public/godot/outdoor`. Per tablet usiamo:

- viewport Godot responsivo;
- uso consigliato in landscape;
- overlay se il tablet è in verticale;
- aree touch più grandi di bottoni e hotspot;
- unlock audio al primo tap;
- schermo intero al primo tocco (vedi sotto);
- manifest PWA e service worker leggero.

## Prova Su Tablet Nella Stessa Rete

1. Avvia il server esposto sulla rete locale:

```powershell
& "C:\percorso\Godot_v4.7.1-stable_win64_console.exe" --headless --path godot `
  --export-release Web public/godot/outdoor/index.html
npm run dev:lan
```

2. Trova l'indirizzo IP del PC Windows:

```powershell
ipconfig
```

Cerca l'IPv4 della scheda Wi-Fi, per esempio `192.168.1.45`.

3. Sul tablet, collegato allo stesso Wi-Fi, apri:

```text
http://192.168.1.45:5173
```

Se Windows chiede il permesso firewall per Node.js, autorizza sulle reti private.

Il pulsante **COMANDI TOUCH** permette di scegliere lato destro/sinistro,
dimensione standard/grande e visibilità piena/leggera. Movimento, azione,
impulso, missione/nave, Bottega, Manuale e conferma delle risposte dispongono
di un bersaglio touch: la tastiera è soltanto una scorciatoia.

Il launcher confronta `build.json` con il service worker attivo e, quando trova
una versione nuova, attende il passaggio al worker aggiornato prima di aprire
Godot. Questo evita che una vecchia cache fornisca il PCK precedente durante il
primo accesso dopo la pubblicazione.

Se il tablet mostra comunque una build precedente, chiudi tutte le schede di Eli
Quest e riapri l'indirizzo. La cache `v9-web-loader` elimina le versioni
precedenti durante l'attivazione; il primo accesso scarica il pacchetto, quelli
successivi lo riusano dalla cache.

## Schermo Intero

Aperto dal browser di un tablet, il gioco perde fra il 15% e il 25% dell'altezza
fra barra degli indirizzi e barra di navigazione. Non è un problema estetico: il
mondo viene scalato con `stretch/aspect="expand"`, quindi meno altezza significa
meno mondo visibile e bersagli touch più piccoli.

Come funziona:

- **il primo tocco sul gioco porta a schermo intero.** Nessuna istruzione da
  dare al bambino: il tocco che serve al browser è lo stesso con cui inizia a
  giocare;
- finché si è in finestra, in alto al centro compare **SCHERMO INTERO** — sbiadisce
  dopo otto secondi ma resta toccabile. È l'unico punto libero: i quattro angoli
  sono occupati da missione, opzioni, NORA ed energia;
- dentro lo schermo intero il pulsante sparisce, per non rubare tocchi al gioco;
- **uscire è una scelta che viene ricordata.** Chi esce (gesto di sistema o Esc)
  riapre in finestra anche ai lanci successivi, e il pulsante lo riporta dentro
  con un tocco.

Per preparare un parco tablet senza toccare il gioco: `?schermo=finestra`
disattiva tutto e `?schermo=pieno` riattiva. Una visita sola basta — la scelta
resta salvata nel browser, l'indirizzo torna pulito.

Su Safari iPhone (e su alcune versioni di iPadOS) la Fullscreen API non esiste
per elementi diversi dai video: lì compare invece il suggerimento di installare
l'app dalla schermata Home, che è l'unica strada davvero senza cornice.

Dove vive il codice — importante prima di metterci le mani:

| | |
|---|---|
| `public/tablet-fullscreen.js` | tutta la logica |
| `godot/export_presets.cfg` | `html/head_include` lo aggancia al guscio |
| `scripts/audit-web-release.mjs` | verifica che l'aggancio esista ancora |

Il guscio `public/godot/outdoor/index.html` **lo riscrive Godot a ogni export**:
una modifica fatta lì sparisce al primo `npm run export:web`, senza rompere
niente e senza dirlo. `html/head_include` è l'unico punto in cui un aggancio
sopravvive, ed è per questo che l'audit lo controlla.

## Budget Asset Tablet

L'export Web ottimizzato misura **61,86 MiB** complessivi:

- `index.wasm`: 37,68 MiB, runtime Godot;
- `index.pck`: 23,85 MiB, gioco e asset;
- shell e icone: circa 0,33 MiB.

Rispetto al precedente export da 68,79 MiB il trasferimento è diminuito di
6,93 MiB (circa il 10%). Landmark, atlanti naturali ed enigmi vengono importati
alla risoluzione massima utile a schermo. Le tavole dei mondi, i landmark e gli
atlanti dei biomi non correnti vengono caricati su richiesta e mantenuti in una
cache runtime condivisa, evitando di decodificare all'avvio gli asset dei 24
mondi.

Con `npm run dev:lan` e `npm run preview:lan`, Vite invia il WASM in Brotli
quando il browser lo supporta: il trasferimento del file scende da 37,68 MiB a
circa 7,92 MiB. Il PCK resta a 23,85 MiB perché comprimerlo nuovamente offre un
risparmio ridotto; il download freddo del nucleo passa così da circa 61,54 MiB
a circa 31,83 MiB, oltre alla piccola shell. La dimensione occupata nella cache
e in memoria non cambia. In pubblicazione la compressione dipende dal server
che ospita i file.

Quando si aggiunge un asset:

1. confrontare la risoluzione sorgente con la dimensione massima a schermo;
2. impostare `process/size_limit` nel relativo `.import` con margine 2×;
3. usare `ResourceLoader.load()` al momento d'uso per contenuti specifici di un
   mondo; riservare `preload()` agli asset comuni della prima scena;
4. rigenerare l'export Web e incrementare `CACHE_VERSION` in `public/sw.js`.

Prima della build eseguire:

```bash
npm run audit:web
```

L'audit blocca la release se `build.json`, versione della cache, dimensioni
PCK/WASM e configurazione dell'export Godot non coincidono. `npm run build`
esegue automaticamente lo stesso controllo.

## Prova Build Di Produzione Su Tablet

```bash
npm run build
npm run preview:lan
```

Poi apri dal tablet:

```text
http://IP_DEL_PC:4173
```

Questa prova è più vicina al comportamento del sito pubblicato.

## Pubblicazione Gratis Consigliata: GitHub Pages

GitHub Pages è adatto perché il progetto genera un sito statico nella cartella `dist`.

Passi:

1. Crea un repository GitHub.
2. Carica il progetto nel repository.
3. In GitHub vai in `Settings > Pages`.
4. Imposta `Source: GitHub Actions`.
5. Fai push sul branch `main`.

Il workflow già incluso in `.github/workflows/deploy-github-pages.yml` esegue:

```bash
npm ci
npm run build
```

e pubblica `dist`.

L'indirizzo finale sarà simile a:

```text
https://TUO-UTENTE.github.io/NOME-REPOSITORY/
```

## Alternative Gratis

- **Netlify Drop:** esegui `npm run build`, poi trascina la cartella `dist` su Netlify Drop.
- **Cloudflare Pages:** collega il repository, build command `npm run build`, output `dist`.
- **Vercel:** collega il repository, framework Vite, output `dist`.

Per un progetto senza backend, tutte queste soluzioni sono compatibili. GitHub Pages è la più lineare se il codice sta già su GitHub.

## Note PWA

Il manifest permette l'installazione su home screen. Su iPad/iPhone:

1. apri il sito in Safari;
2. usa `Condividi`;
3. scegli `Aggiungi alla schermata Home`.

Il manifest dichiara `display: fullscreen` (con `standalone` come ripiego per i
browser che non lo sostengono): aperta dalla schermata Home l'app non ha nessuna
cornice, e il pulsante dello schermo intero non compare perché non serve.

L'audio partirà solo dopo il primo tap, come richiesto dai browser mobile.
