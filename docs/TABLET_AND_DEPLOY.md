# Tablet E Pubblicazione Web

## Obiettivo

Eli Quest resta un'app web Phaser/Vite senza backend. Per tablet usiamo:

- canvas 1280x720 scalato con `Phaser.Scale.FIT`;
- uso consigliato in landscape;
- overlay se il tablet è in verticale;
- aree touch più grandi di bottoni e hotspot;
- unlock audio al primo tap;
- manifest PWA e service worker leggero.

## Prova Su Tablet Nella Stessa Rete

1. Avvia il server esposto sulla rete locale:

```bash
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

L'app si aprirà quasi a schermo intero. L'audio partirà solo dopo il primo tap, come richiesto dai browser mobile.
