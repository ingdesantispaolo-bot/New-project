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

## Come lo vede un bambino

Dal menu di avvio, riga **«Giochi come: …»** → *CAMBIA*.

- **Le caselle dei giocatori.** Ognuna ha nome e livello, e un salvataggio tutto
  suo: due fratelli sullo stesso tablet non si sovrascrivono più. Sei caselle al
  massimo. Non si cancellano — si rinominano, e la partita dentro resta.
- **☁ Codice di ripristino.** *CREA IL CODICE* trova un codice libero (chiede al
  Worker se è già occupato, e ne prova un altro se lo è) e manda subito la
  partita: un codice scritto su un foglio che non contiene niente sarebbe
  peggio di nessun codice.
- **RIPRISTINA.** Si scrive il codice di un altro tablet. Prima di sostituire
  qualcosa il gioco mostra **che cosa arriva e che cosa se ne va** — nome,
  livello e data da una parte, nome e livello di qui dall'altra. Poi decide un
  umano.

Durante la partita la copia si rinfresca da sola, al massimo ogni tre minuti, e
subito quando si sale di livello. In silenzio: se il cloud non risponde non
succede niente e si continua a giocare.

## Il registro dei giocatori (6 agosto 2026)

Rotte nuove, accanto a quelle dei salvataggi:

```
GET /group/ABC-123           -> { "membri": [scheda, ...] }
PUT /group/ABC-123/AB12CD34  -> aggiorna la scheda di UN membro
```

Il codice del gruppo è **più corto** di quello di ripristino — tre lettere e tre
cifre invece di quattro e quattro — e non per risparmiare caratteri: i due campi
di testo stanno nella stessa schermata e fanno l'opposto. Uno **sovrascrive** un
salvataggio, l'altro apre una tabella. Con forme diverse, un codice scambiato non
passa nemmeno il controllo.

Nel gruppo viaggia un **riepilogo**: nome, livello, mondi, giorni, prove della
settimana, argomenti consolidati, padronanza per materia. Mai il salvataggio,
mai il codice di ripristino. La sigla di otto caratteri nell'URL identifica una
riga: chi conosce il codice del gruppo vede tutti, ma può riscrivere solo la
propria — e non essendo la sigla il codice di ripristino, nessuno può toccare la
partita di un altro bambino.

Un limite dichiarato: **un gruppo intero vive in una chiave sola**, quindi due
tablet che scrivono nello stesso istante si sovrascrivono e una scheda resta
indietro fino al rinfresco successivo. Per un registro che si riaggiorna a ogni
apertura è un difetto che si ripara da sé; per un dato che non si può perdere non
basterebbe, ed è il motivo per cui i salvataggi veri stanno altrove, una chiave
per ciascuno.

**Serve un `npx.cmd wrangler deploy`** perché queste rotte esistano: finché non
si fa, la scheda GRUPPO risponde «rotta sconosciuta» e quella CASA funziona lo
stesso, perché non passa dalla rete.

## Il passo dopo


Il lato gioco è fatto. Restano due cose che solo il collaudo può dire:

- se tre minuti fra una copia e l'altra siano troppi o troppo pochi. Il limite
  vero è il piano gratuito (mille scritture al giorno), non la tecnica;
- se `ORIGINI_AMMESSE`, in cima a `index.ts`, contenga davvero l'indirizzo da
  cui giocano i bambini. Un'origine mancante non dà errore visibile: il
  salvataggio in cloud smette di funzionare e basta.
