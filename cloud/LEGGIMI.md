# Salvataggio in cloud — guida passo passo

Oggi il salvataggio vive in `user://eli-quest-save.json`, che nell'export Web è
**IndexedDB del browser**: legato a quel dispositivo e a quel browser. Svuotare i
dati del browser o cambiare tablet cancella tutto — e la campagna dura circa
venti ore.

Questo Worker aggiunge una copia in cloud identificata da un **codice**, senza
account, senza email, senza password.

---

## La cosa che confonde tutti, detta subito

Ci sono **due nomi diversi**, e non sono la stessa cosa:

| | dove sta | esempio |
|---|---|---|
| **nome dello spazio KV** | nel pannello Cloudflare | `Eli_game` |
| **nome del collegamento** (*binding*) | dentro il codice | `SAVES` |

Il codice scrive `env.SAVES`. La configurazione dice «lo spazio che nel pannello
si chiama `Eli_game`, per il codice si chiama `SAVES`». Serve un ponte fra i due,
e quel ponte è il `wrangler.jsonc` (oppure la schermata *Bindings* nel pannello).

Se un giorno leggi l'errore **`binding SAVES not found`**, vuol dire sempre e
solo questo: il ponte manca o ha l'ID sbagliato.

---

## Strada A — tutto dal pannello, senza installare niente

È la più semplice se non hai mai usato la riga di comando. Non serve `wrangler`,
non serve Node, non si scarica nulla.

1. Nel pannello Cloudflare vai su **Workers & Pages → Create → Worker**.
2. Dagli il nome `eli-quest-save` e premi **Deploy** (per ora pubblica il Worker
   di esempio: va bene, lo sostituiamo fra un attimo).
3. Premi **Edit code**. Cancella tutto quello che c'è nell'editor e incolla il
   contenuto di [`index.ts`](index.ts). Premi **Deploy**.
4. Torna alla pagina del Worker e vai su **Settings → Bindings → Add binding**:
   - tipo: **KV namespace**
   - **Variable name**: `SAVES` ← *questo è il nome che il codice si aspetta*
   - **KV namespace**: scegli `Eli_game` dall'elenco
   - **Deploy** / **Save**
5. In alto trovi l'indirizzo del Worker, del tipo
   `https://eli-quest-save.<tuo-sottodominio>.workers.dev`.
   **Quello è l'indirizzo che serve al gioco: segnalo.**

Il punto 4 è quello che non si può saltare: senza il binding il codice non trova
`env.SAVES` e ogni chiamata risponde errore.

---

## Strada B — dai file che il pannello ti ha dato

Se hai premuto **connect** sullo spazio KV, Cloudflare ti ha mostrato `index.ts`
e `wrangler.jsonc`. In quel caso:

1. Metti in quella cartella i due file di qui: [`index.ts`](index.ts) e
   [`wrangler.jsonc`](wrangler.jsonc).
2. Apri `wrangler.jsonc` e sostituisci `INCOLLA_QUI_IL_NAMESPACE_ID_DI_Eli_game`
   con il **Namespace ID** che vedi nel pannello accanto a `Eli_game`
   (è una stringa lunga di lettere e numeri).
3. Dalla riga di comando, in quella cartella:

```bash
npx wrangler login     # apre il browser, autorizzi il tuo account
npx wrangler deploy
```

Alla fine stampa l'indirizzo del Worker. **Segnalo.**

> Nella cartella ci sono anche `worker.js` e `wrangler.toml`: sono la stessa
> cosa nel formato vecchio. Serve **una coppia sola** — o `index.ts` +
> `wrangler.jsonc`, o `worker.js` + `wrangler.toml`. Non entrambe.

---

## Verifica che funzioni

Sostituisci l'indirizzo con il tuo e lancia:

```bash
curl -X PUT https://eli-quest-save.<tuo-sottodominio>.workers.dev/save/PROV-0001 \
  -H "Content-Type: application/json" -d "{\"prova\":true}"
```

Deve rispondere:

```json
{"ok":true,"codice":"PROV-0001"}
```

Poi rileggilo:

```bash
curl https://eli-quest-save.<tuo-sottodominio>.workers.dev/save/PROV-0001
```

Deve restituire `{"prova":true}`.

### Se qualcosa non va

| messaggio | che cosa significa |
|---|---|
| `binding SAVES not found` | manca il collegamento del punto 4 (strada A) o l'ID nel `wrangler.jsonc` (strada B) |
| `codice non valido` | il codice deve essere quattro lettere, trattino, quattro cifre: `PROV-0001` |
| `nessun salvataggio` | è un 404 giusto: quel codice non ha ancora niente salvato |
| errore CORS dal gioco | l'indirizzo del sito non è in `ORIGINI_AMMESSE`, in cima a `index.ts` |

---

## Costi

Il piano gratuito copre 100 000 letture e 1 000 scritture al giorno. Il gioco
scrive a fine sessione e al cambio di mondo: una classe intera resta ampiamente
dentro.

## Cosa fa e cosa non fa

- **Non fonde** due salvataggi: l'ultimo che scrive vince. Per questo il gioco
  caricherà dal cloud solo su richiesta esplicita, mai in automatico.
- **Non è un'autenticazione**: chi conosce un codice può leggere e sovrascrivere
  quel salvataggio. Va bene per il progresso di un gioco.
- **Il locale resta la verità.** Il cloud è una copia di sicurezza: si continua a
  giocare offline, e se il Worker non risponde non succede niente.
- **Un anno di inattività e il salvataggio scade.**

## Il passo dopo

Quando l'indirizzo del Worker esiste, resta il lato gioco: generazione del
codice, pannello «Codice di ripristino», caricamento su richiesta e invio a fine
sessione. È un lotto separato.
