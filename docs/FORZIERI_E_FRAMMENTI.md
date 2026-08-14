# Forzieri e frammenti

*14 agosto 2026 — nasce da una segnalazione del committente: forzieri e frammenti
«sono solo una distrazione che non apporta nulla».*

Era vero, e misurandolo era vero in tre modi diversi. Questo documento tiene le
decisioni; il codice che le esegue è `godot/scripts/game/fragment_economy.gd`,
`godot/scripts/game/treasure_catalog.gd` e la regia in `outdoor_world.gd`.

## 1. Il difetto, misurato

| Cosa | Prima |
|---|---|
| Scarico della valuta | **nessuno**: `spend_fragments` non esisteva, la bottega chiamava `spend_energy` |
| Forzieri per mondo | **42** (1018 in campagna, `fragment_economy_probe`) |
| Etichette | tre stringhe a sorte, di cui una — «cassa energia» — prometteva un'energia che nessuno pagava (`rewardEnergy` generato e mai letto) |
| Contenuto | nessuno |

Un numero che sale per ventiquattro mondi e non compra niente, prodotto da
quarantadue oggetti identici per mondo.

## 2. Le due valute, separate

    ENERGIA     la fa lo studio, la spendono le prove. Non compra più niente.
    FRAMMENTI   li fa l'esplorazione, li spende la bottega.

Prima l'energia faceva due mestieri in conflitto: `economy_probe` misura che il
catalogo costa il 59–74% di **tutta** l'energia di una campagna, cioè comprarsi
un cappello competeva con l'allenarsi. Adesso chi esplora si compra la bellezza e
chi non esplora non perde niente di didattico — nessun cosmetico tocca una
domanda (decisione vincolante 15).

**Il Lascito continua a non pesare i frammenti** (`legacy_score.gd`): il finale
resta l'unica cosa che non si compra.

### Taratura

Le tariffe stanno tutte in `FragmentEconomy` e non sono a occhio:
`fragment_economy_probe` conta i forzieri dei 24 mondi con gli stessi vincoli del
gioco. Alle tariffe vecchie il catalogo costava **17,6 campagne**; alle nuove una
campagna intera al 100% ne compra il **59%** — dentro la fascia in cui stava
l'energia prima della separazione, e mai il catalogo intero: un catalogo
comprabile per intero è un catalogo senza scelte.

| Fonte | Prima | Adesso |
|---|---|---|
| Incontro risolto | 3 | 35 |
| Missione | 2 | 25 |
| Riparazione apparato | 4 | 50 |
| Camera del mondo | 12 | 150 |
| Varco (duello) | 4–11 | 45–125 |
| Forziere | 2–13 | 130–320 secondo il tipo |

## 3. Il forziere ha dentro qualcosa

**Regola di confine: il generatore fa la geometria, il catalogo fa il
significato.** `OutdoorGenerator` non è stato toccato — fixture di parità e
determinismo dei semi restano quelli che erano. `TreasureCatalog` legge l'id già
generato e decide che cosa quel forziere è, con lo stesso `posmod(hash(id), 100)`
che il progetto usa già per gli attrezzi richiesti.

**Un terzo dei forzieri resta** (34%): quarantadue per mondo diventano circa
dodici, uno ogni due chunk. Una cosa che si trova quaranta volte per mondo non è
un ritrovamento.

Tre tipi, e il rapporto fra loro è ciò che li fa funzionare — se ogni forziere si
fermasse a raccontare qualcosa, fermarsi smetterebbe di essere un avvenimento:

| Tipo | Quota | Cosa succede |
|---|---|---|
| **Lascito** | 26% | la roba di qualcuno che abita il mondo. Si apre un riquadro: l'oggetto, e una riga di Eli. Verbo `APRI`, e da fuori si legge «forziere chiuso con cura» |
| **Custode** | 14% | il Custode fruga e tiene per sé una cosa inutile, che finisce nella lista dei regali (`PetGifts`) — a fine campagna quella lista è il diario del viaggio, e adesso si riempie esplorando |
| **Resto** | 60% | cianfrusaglie: una riga di feedback e si cammina |

Gli **oggetti sono della materia del mondo** (cinque per materia, sessanta in
tutto) e i **proprietari sono del suo cast** (`NpcCatalog.for_world`). Nessun
testo dice mai chi era quella persona o come sta: dice che cosa ha lasciato e in
che stato. Un mazzo di stecche rilegato a gruppi di dieci racconta Tobia meglio
di una frase su Tobia — è la stessa regola delle Tracce (`mystery_catalog.gd`):
si leggono, non si recitano.

**Si incassa prima e si racconta dopo.** Chi chiude il riquadro senza leggere ha
già preso tutto: nessun testo di questo gioco può stare fra un bambino e una cosa
che ha guadagnato.

## 4. Guard-rail

- niente qui è obbligatorio: un forziere mancato non costa nulla, ed è la
  condizione perché possa valere qualcosa trovarlo;
- il contenuto guarda l'id e il mondo, **mai il giocatore**: livello, padronanza
  e cosmetici non cambiano cosa c'è dentro. Un forziere che paga di più a chi va
  meglio sarebbe una ricompensa nascosta al rendimento;
- un forziere saltato dalla densità resta saltato anche dopo un reload, e uno
  aperto non ricompare;
- comprare non muove nessuna delle cinque misure del Lascito.

Li verifica `treasure_audit.gd`, sul comportamento e non a parole.

## 5. Cosa non è stato fatto (e resta sul tavolo)

- **Tenere o restituire.** Un lascito è la roba di una persona viva: la scelta
  naturale è restituirla. L'impianto esiste già (`stance_choices.gd`, cinque
  momenti di cui uno solo cablato) e il meccanismo sarebbe quello dichiarato lì —
  nessuna opzione punita, cambia solo che qualcuno se ne ricorda. **Attenzione**:
  se restituire valesse per il Lascito e tenere no, la scelta avrebbe una
  risposta giusta e il gioco starebbe punendo di nascosto (§10.6). La
  restituzione non deve dare punteggio, solo memoria — la stessa logica dei
  regali del Custode, che non valgono niente apposta.
- **Mecenatismo**: spendere frammenti per riparare pezzi visibili di un mondo
  invece che per comprare cosmetici. Tematicamente è la cosa più forte in un
  gioco che parla di riparare; costa contenuto e arte per mondo.
