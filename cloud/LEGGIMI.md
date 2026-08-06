# Salvataggio in cloud — configurazione passo passo

Oggi il salvataggio vive in `user://eli-quest-save.json`, che nell'export Web è
**IndexedDB del browser**: legato a quel dispositivo e a quel browser. Svuotare i
dati del browser o cambiare tablet cancella tutto — e la campagna dura circa
venti ore.

Questo Worker aggiunge una copia in cloud identificata da un **codice**, senza
account, senza email, senza password.

---

## 1. Crea lo spazio KV

Nella cartella `cloud/`:

```bash
npm install -g wrangler      # se non ce l'hai
wrangler login               # apre il browser, autorizzi il tuo account
wrangler kv namespace create SAVES
wrangler kv namespace create SAVES --preview
```

Ogni comando stampa una riga come questa:

```
{ binding = "SAVES", id = "a1b2c3d4e5f6..." }
```

Copia i due `id` dentro `wrangler.toml`, al posto dei segnaposto:
il primo in `id`, quello con `--preview` in `preview_id`.

> **Se hai già creato lo spazio KV dal pannello web**: apri
> *Workers & Pages → KV*, e l'ID è la stringa lunga accanto al nome. Va bene
> uguale, non serve ricrearlo.

## 2. Controlla le origini ammesse

In `worker.js`, in cima, c'è `ORIGINI_AMMESSE`. Deve contenere l'indirizzo da
cui il gioco viene servito:

```js
const ORIGINI_AMMESSE = [
  "https://ingdesantispaolo-bot.github.io",
  "http://localhost:5173",
  "http://localhost:4173",
];
```

Se pubblichi altrove, aggiungi quell'indirizzo. **Non mettere `"*"`**: con
l'asterisco qualunque pagina del web potrebbe leggere un salvataggio conoscendo
il codice.

## 3. Prova in locale

```bash
wrangler dev
```

In un altro terminale:

```bash
curl -X PUT http://localhost:8787/save/TEST-0001 \
  -H "Content-Type: application/json" -d '{"level":3}'

curl http://localhost:8787/save/TEST-0001
```

Il secondo comando deve restituire `{"level":3}`. Se dice
`binding SAVES not found`, gli ID nel `wrangler.toml` non sono a posto.

## 4. Pubblica

```bash
wrangler deploy
```

Alla fine stampa l'indirizzo, del tipo:

```
https://eli-quest-save.<tuo-sottodominio>.workers.dev
```

**Quello è l'indirizzo che serve al gioco.** Segnalo.

## 5. Verifica che sia vivo

```bash
curl -X PUT https://eli-quest-save.<tuo-sottodominio>.workers.dev/save/PROV-0001 \
  -H "Content-Type: application/json" -d '{"prova":true}'
```

Deve rispondere `{"ok":true,"codice":"PROV-0001"}`.

---

## Costi

Il piano gratuito di Cloudflare copre 100 000 letture e 1 000 scritture al
giorno. Il gioco scrive a fine sessione e al cambio di mondo: una classe intera
resta ampiamente dentro.

## Cosa fa e cosa non fa

- **Non fonde** due salvataggi: l'ultimo che scrive vince. Per questo il gioco
  caricherà dal cloud solo su richiesta esplicita, mai in automatico.
- **Non è un'autenticazione**: chi conosce un codice può leggere e sovrascrivere
  quel salvataggio. Va bene per il progresso di un gioco.
- **Il locale resta la verità.** Il cloud è una copia di sicurezza: si continua a
  giocare offline, e se il Worker non risponde non succede niente.
- **Un anno di inattività e il salvataggio scade.** Nessuno ricorda un codice
  dopo un anno, e i dati abbandonati non devono restare per sempre.

## Il passo dopo

Il Worker da solo non basta: serve il lato gioco — generazione del codice,
pannello «Codice di ripristino», caricamento su richiesta e invio a fine
sessione. È un lotto separato, da fare quando l'indirizzo del punto 4 esiste.
