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

## 5. La bottega attaccata al mondo

*Secondo lotto, stessa giornata: «bottega, valuta, gioco, missioni — come
possiamo collegare tutto in modo intelligente?».*

Misurando i legami esistenti, il gioco ne aveva già quattro chiusi e onesti:
studio → energia → prove; prove → luce del mondo e potenza di Eli; prove →
padronanza → **stadi degli NPC** (`npc_arc.gd`: Tobia cambia quando tu impari a
contare); prove → minimissioni → il mondo cambia. Mancavano quelli che
riguardavano la bottega, e ognuno mancava per una ragione diversa.

### 5.1 Le chiavi non si comprano

Torcia e falce sono le uniche due voci che **aprono il mondo** invece di
decorarlo. Con l'economia nuova costavano meno di un forziere: le due chiavi del
gioco erano diventate un acquisto automatico al primo baule.

Ribilanciare il prezzo sarebbe stato il rimedio ovvio e sbagliato — qualunque
cifra resta una riga di listino. Adesso **non sono in vendita**: le consegna chi
le usa, alla prima riparazione portata a termine in un mondo
(`field_tools.gd`, agganciato a `minimission_completed`). Le minimissioni
prendono il posto del primo evento-gate, quindi la consegna **non si può
mancare**: nessun bambino resta senza strumenti per non aver esplorato
abbastanza, che sarebbe il modo peggiore di legare l'esplorazione a sé stessa.

### 5.2 Il catalogo si scrive giocando

Tutte e 58 le voci avevano già un campo `origine` che le lega a un posto o a una
persona — *«Pigmento delle Rovine dei Glifi, l'unico colore che il tempo non ha
sbiadito»* — e nessuno lo faceva valere: si comprava il pigmento delle Rovine
senza aver mai visto le Rovine.

Ora **30 voci su 58** portano un campo `mondo`, e compaiono in vetrina quando
quella destinazione è aperta. Le altre 28 restano sempre disponibili e non è una
svista: sono la roba della nave e dei Dodici, quella degli itineranti che girano
tutti i mondi, e i moduli — che toccano il gameplay e non possono dipendere da
dove sei arrivata.

Non è un gate didattico, ed è la condizione perché possa esistere qui: **non
chiede padronanza, non chiede di aver finito niente**, solo che la rotta sia
aperta (`shop_world_link_audit` lo verifica confrontando due partite identiche,
una che sa tutto e una che non sa niente). E il rifiuto non è un rifiuto: al
posto del prezzo la scheda mostra il nome del posto — *DA TROVARE · ROVINE DEI
GLIFI* —, che è un indirizzo, non una porta chiusa. Al mondo 1 restano comunque
20 voci comprabili.

### 5.3 Niente si scusa più

`upgrade` e `decor` — 11 voci, 6.080 frammenti — dichiaravano al bambino che il
loro effetto «non è ancora attivo in questa build». Non erano morte come
sembrava: i pezzi della nave disegnano già un anello di luce addosso a Eli, e il
restauro pesava nello shader del Relitto. Ma pesava **0,06 di luce**: comprato,
non si vedeva.

Adesso il restauro porta luce, colore e bordi meno cupi, e accende sette fuochi
stabili nel ponte restaurato — sempre gli stessi, perché un luogo che cambia
forma a ogni visita non è un luogo restaurato. E il **nucleo prismatico**
(1.600 frammenti, il pezzo più caro) fa finalmente quello che la sua descrizione
prometteva da sempre: dodici luci in cerchio, una per materia, ognuna accesa
quanto la padronanza di quella materia. Nessun numero, nessuna classifica — un
ritratto, non una pagella.

### 5.4 Il Custode è uno solo

Lo slot `pet` (11 voci, 35.400 frammenti) sembrava vendere un secondo compagno
accanto al Custode. Non era vero — `outdoor_world._spawn_pet` usa lo slot per
dare **al Custode** la sua forma — ma i testi dicevano il contrario («compagno
fedele: resta vicino»), e un bambino che paga 5.200 frammenti aspettandosi un
animale in più ha ragione a sentirsi imbrogliato. Le descrizioni ora dicono la
verità: sono forme che il Custode assume.

Con un difetto vero trovato per strada: il colore comprato **non si vedeva mai**,
perché la livrea di serie vinceva sempre. Ora l'ordine è quello del significato —
una livrea scelta a mano dal bambino batte tutto, ma sopra il default silenzioso
vince l'aspetto comprato.

## 6. Cosa non è stato fatto (e resta sul tavolo)

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
