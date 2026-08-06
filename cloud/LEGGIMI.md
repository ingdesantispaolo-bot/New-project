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

## I tre comandi

Il pannello Cloudflare permette di scrivere il codice **solo** se il Worker è
nato come «Worker semplice»: se è nato da un template con Git, il pulsante
*Edit code* non c'è, e la finestra «Connect your Worker to KV» che il pannello
propone è **solo documentazione** — mostra un esempio, non il tuo codice.

Questa strada funziona in entrambi i casi e non dipende da come è nato il Worker.

**1.** Apri `cloud/wrangler.jsonc` e metti nel campo `id` il **Namespace ID** di
`Eli_game` (pannello → *Storage & Databases* → *KV*, la stringa lunga accanto al
nome). Non è un segreto: identifica lo spazio, non dà accesso.

**2.** Dalla cartella `cloud/`:

```bash
npx.cmd wrangler login
```

Si apre il browser e ti chiede di autorizzare. Una volta sola.

> Su Windows serve `npx.cmd`, non `npx`: PowerShell blocca gli script `.ps1`
> per impostazione predefinita, e `npx` in PowerShell passa proprio da lì
> (*L'esecuzione di script è disabilitata nel sistema in uso*). Il `.cmd`
> aggira la regola senza doverla cambiare.

**3.** Sempre da `cloud/`:

```bash
npx.cmd wrangler deploy
```

Controlla la riga `env.SAVES` che stampa: se accanto c'è l'ID del namespace, il
collegamento è fatto. È la verifica che conta.

**Fatto il 6 agosto 2026.** L'indirizzo attivo è:

```
https://eli-quest-save.ing-desantis-paolo.workers.dev
```

`wrangler deploy` fa da solo tutto quello che il pannello chiederebbe a mano:
carica il codice **e** collega lo spazio KV, perché il collegamento è scritto
nel `wrangler.jsonc`. Non serve toccare *Settings → Bindings*.

> Se il Worker `eli-quest-save` esiste già, questo comando lo **sostituisce**:
> è quello che vogliamo, il template di esempio non serve.

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
| `binding SAVES not found` | l'ID nel `wrangler.jsonc` manca o è sbagliato |
| `Impossibile caricare il file npx.ps1` | usa `npx.cmd` invece di `npx` |
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
