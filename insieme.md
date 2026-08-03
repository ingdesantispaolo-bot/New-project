# Eli Quest — Piano di lavoro

Aggiornato al 3 agosto 2026.

**Questo file contiene solo lavoro da fare.** Niente resoconti: quelli stanno nel
*Registro dei lavori* di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md).
Se una cosa è finita e verde, esce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md)

---

## L'obiettivo: tutti i 24 mondi cablati, poi il collaudo

**Il contenuto è finito.** Tutti e ventiquattro i mondi hanno cast, battute,
Traccia, semi, beat e conversazioni al Ritrovo; il mondo 24 ha la convergenza al
Cuore. Non c'è più niente da scrivere prima di cablare, e le schede qui sotto
dicono per ogni mondo cosa va collocato dove.

**Si cabla a lotti, non tutto insieme** — non per prudenza, ma perché un difetto
di regia scoperto al mondo 3 costa tre mondi da correggere e scoperto al 24 ne
costa ventiquattro. Ogni lotto finisce con i suoi audit verdi; il collaudo umano
arriva alla fine.

| Lotto | Mondi | Cosa mette alla prova per la prima volta |
|---|---|---|
| **L1** | 1 – 6 | dialoghi, Ritrovo, missioni, stadi, **il colpo 1** (mondo 5) |
| **L2** | 7 – 12 | il colpo 2 (8), il colpo 3 a metà campagna (12) e la **prima Traccia decisiva**, che obbliga il beat di ripiego |
| **L3** | 13 – 18 | il colpo 4 (16), e dal 17 **il Tredicesimo che agisce su mondi già restaurati** |
| **L4** | 19 – 23 | il colpo 5 (19) e il colpo 6 (23), il momento più fitto di rivelazioni |
| **L5** | 24 | convergenza, nodo di sintesi, cattedra, colpo 7. Usa tutto quanto |

**Il rischio da tenere d'occhio in L3**: le azioni del Tredicesimo sono le prime
che *tolgono* qualcosa a un mondo già sistemato. Sono tutte reversibili e nessuna
tocca energia, mastery o gate — ma è lì che un errore di regia si sente addosso,
non sullo schermo.

### Cosa vuol dire «cablato»

Il mondo si apre, ha abitanti che parlano, edifici che cambiano con lo stadio,
una Rovina con dentro la Traccia, e i semi collocati dove si vedono senza essere
indicati. Nessuna schermata provvisoria, nessun segnaposto.

---

## Le schede — L1, mondi 1–6

Tutto il contenuto delle colonne «cast», «Traccia» e «semi» è già scritto e
verde. Le schede servono a Codex per sapere **cosa va collocato dove**. I mondi
7–24 hanno la loro tabella più sotto, con lo stesso significato.

### Mondo 1 · Radura Accademia · matematica
- `artKit` **natura-rovine** · landmark **obelisco-dei-numeri**
- Cast: **Tobia** (specialista, burbero, «…e uno») · **Nonna Ersilia**
  (testimone, caloroso, «cuore») · Bislacco **Puccio**
- Traccia: **bastone da conteggio**, tacche a gruppi di dieci
- Semi da collocare: **1** — colpo 1, oggetto: la spirale piccola sul fianco del
  bastone, incisa dopo le tacche e con i bordi netti
- Da non sbagliare: la **conta di nonna Ersilia** va sentita nei primi cinque
  minuti. È la tabellina del 7 e contiene il nome del Tredicesimo. Se il
  giocatore la salta, al mondo 24 non ha la chiave in mano.

### Mondo 2 · Archivio delle Parole · italiano
- `artKit` **carta-e-foglie** · landmark **ponte-delle-frasi**
- Cast: **Corinna** (specialista, solenne, misura con le dita) · **Bruno**
  (testimone, curioso, «e questa come la chiami?») · Bislacco **Ditino**
- Traccia: **catalogo dei Primi**, ordinato per funzione e non per forma
- Semi da collocare: **3** — colpo 1 (dialogo di Bruno sul «ricciolo» che non si
  cancella) · colpo 2 (oggetto: il catalogo ha 13 sezioni e 11 intestazioni) ·
  colpo 6 (dettaglio: la spirale più vecchia è incisa **all'altezza di una
  bambina in piedi**)
- Il seme del colpo 6 è il più lontano di tutti: paga al mondo 23. Va messo dove
  si vede senza essere indicato.

### Mondo 3 · Cratere Logico · coding
- `artKit` **macchine-e-loop** · landmark **macchina-a-cicli**
- Cast: **Ruggine** (specialista, burbero, soffia sugli attrezzi) · **Sesto**
  (testimone, buffo, si ripresenta ogni volta) · Bislacco **Manetta**
- Traccia: **schema di telaio** — «ripetere non è fatica, è un'istruzione»
- Semi da collocare: **2** — colpo 1 (dettaglio: qualcuno ha soffiato via la
  polvere da una pietra) · colpo 2 (dialogo: Sesto si presenta come «il
  dodicesimo» e non sa spiegare perché)
- Sesto è anche **itinerante**: qui torna sé stesso e da qui in poi lo si
  incontra ovunque. È l'unico personaggio che sta nei due cataloghi
  (`w03-sesto` e `itin-sesto`).

### Mondo 4 · Baia dei Segnali · inglese
- `artKit` **segnali-e-onde** · landmark **faro-dei-messaggi**
- Cast: **Marea** (specialista, sognante, sussurra prima di parlare) ·
  **Vecchio Lino** (testimone, divertente, «captain») · Bislacco **Boa**
- Traccia: **quaderno bilingue**, la stessa lezione su due colonne che non si
  corrispondono riga per riga
- Semi da collocare: **1** — colpo 1, oggetto: sulla boa grande, sotto la
  ruggine, un ricciolo che il sale non ha ancora mangiato

### Mondo 5 · Officine del Moto · fisica — ⟡ **colpo 1**
- `artKit` **leve-e-carrelli** · landmark **grande-leva**
- Cast: **Gerbo** (specialista, burbero, si sputa sulle mani) · **Tilla**
  (testimone, curioso, «te lo faccio vedere?») · Bislacco **Peso**
- Traccia: **la spirale aperta**, e il taglio è fresco di settimane
- Semi da collocare: nessuno. Qui si **incassa**.
- È il mondo che prova la cosa più delicata di tutte: che una Traccia letta in
  silenzio regga il peso di una rivelazione. Se il colpo 1 non funziona, non
  funzionerà nessuno dei sette, e conviene saperlo adesso.

### Mondo 6 · Giardino della Risonanza · musica
- `artKit` **cristalli-vibranti** · landmark **albero-risonante**
- Cast: **Ambra** (specialista, sognante, canticchia le risposte) · **Oreste**
  (testimone, solenne, sordo, legge con le mani sulle corde) · Bislacco
  **Zufolo**
- Traccia: **diapason dei Primi** — «un suono con un nome si può regalare»
- Semi da collocare: **3** — colpo 2 (oggetto: rastrelliera con 13 sedi, 11
  occupate, una vuota e pulita, una vuota e impolverata) · colpo 3 (dettaglio:
  NORA dice dove tenevano il diapason, in un mondo che dichiara di non aver mai
  visto) · colpo 7 (dettaglio: NORA ricorda **una lezione e non un dato**)
- **Oreste è sordo**: non reagisce ai suoni, reagisce alle vibrazioni e a chi
  gli entra nel campo visivo. Se la regia lo fa girare al richiamo vocale, il
  personaggio è smontato.

---

## Le schede — L2…L5, mondi 7–24

Stesse colonne. Il **tic** fra parentesi è la stringa che l'audit cerca: se una
battuta in scena non la contiene, il personaggio suona come un narratore.

| # · mondo · materia | `artKit` · landmark | cast (specialista / testimone / bislacco) | Traccia | semi |
|---|---|---|---|---|
| **7 · Rovine dei Glifi · latino** | `pietra-e-iscrizioni` · arco-dei-glifi | Livia (inchiostro) / Zeno (parente) / Postilla | Dizionario delle radici | 1 · colpo 2, dettaglio |
| **8 · Delta dei Circuiti · elettronica** ⟡ | `generatori-e-cavi` · nodo-centrale | Ciro (nodi) / Doria (acqua) / Scintilla | **Sigillo d'equipaggio** | — |
| **9 · Arcipelago · geografia** | `mappe-e-quote` · torre-cartografica | Alma (matita) / Remo (rotta) / Bora | Carta della rotta | 3 · colpi 3, 4, 6 |
| **10 · Serra delle Simbiosi · scienze** | `flora-e-fauna` · cupola-vivente | Ortensia (piante) / Mirta (tisana) / Terriccio | La dispensa in ordine | 2 · colpi 3, 7 |
| **11 · Soglia del Tempo · storia** | `reperti-e-prime-civiltà` · portale-delle-epoche | Danio (scommett) / Vesta (cronac) / Anticaglia | Due datazioni discordanti | 2 · colpi 3, 5 |
| **12 · Labirinto delle Regole · logica** ⟡ | `muri-mobili` · cuore-del-labirinto | Quinto (passi) / Isa (e se invece) / Svolta | **Le schede delle unità** — *decisiva* | — |
| **13 · Deserto delle Orbite · matematica** | `strumenti-astrali` · osservatorio | Solano (lenti) / Duna (mano tesa) / Miraggio | Registro di manutenzione | 2 · colpi 4, 7 |
| **14 · Biblioteca delle Voci · italiano** | `libri-e-eco` · sala-delle-voci | Elmo (taglia l'aria) / Ottavia ((cambia voce)) / Prefazio | I verbali della seduta | 2 · colpi 4, 5 |
| **15 · Città Macchina · coding** | `automi-e-cavi` · torre-di-controllo | Gru (colpetto) / Pila (quando è successo) / Ronzino | Le sezioni della nave | 1 · colpo 4 |
| **16 · Frontiera delle Lingue · inglese** ⟡ | `insegne-multilingua` · porta-delle-lingue | Talia (scus) / Marco dei Valichi (lingue) / Tuttolingue | **La mappa vera** — *decisiva* | — |
| **17 · Oceano delle Forze · fisica** | `pressione-e-flussi` · cattedrale-sottomarina | Nerea (fiato) / Coral (numer) / Scafandro | Le insegne del molo | 1 · colpo 5 |
| **18 · Cattedrale del Suono · musica** | `canne-e-archi` · grande-organo | Silo (riverbero) / Bea (navata) / Controcanto | Il turno di guardia | 1 · colpo 5 |
| **19 · Necropoli delle Radici · latino** ⟡ | `epigrafi-e-radici` · albero-delle-radici | Numa (lapid) / Fiorina (chiamo) / Lapidario | **Il progetto di NORA** — *decisiva* | — |
| **20 · Tempesta EM · elettronica** ⟡ | `sensori-e-scariche` · torre-di-campo | Sferza (nocche) / Quieto (second) / Parafulmine | Le misure della quarantena | — |
| **21 · Atlante Fratturato · geografia** | `strati-e-climi` · pilastro-tettonico | Terza (fogli) / Mino (formaggio) / Meteora | La tesi per esteso | 1 · colpo 6 |
| **22 · Biosfera Profonda · scienze** | `cellule-e-energia` · nucleo-vivente | Vesca (annus) / Fondo (guarda) / Muffa | La domanda mai risposta | 2 · colpi 6, 7 |
| **23 · Sala delle Ere · storia** ⟡ | `mosaici-manoscritti-e-fonti` · archivio-delle-ere | Cronia (timbr) / Ovidio (carte) / Errata | **Il registro del mondo 2** | — |
| **24 · Cuore dei Primi · trasversale** ⟡ | `sintesi-di-tutti` · cuore-dei-primi | *nessun residente* — vedi «Il mondo 24» | Gli undici quaderni | — |

⟡ = il mondo porta un colpo di scena.

### Le trappole, mondo per mondo

Solo dove ce n'è una. Sono le cose che si sbagliano cablando, non scrivendo.

- **8 · il sigillo**: tredici alloggiamenti, undici nomi. Il dodicesimo è
  raschiato e **i graffi vanno verso l'interno** — l'ha fatto qualcuno seduto al
  tavolo. Se la resa non mostra la direzione dei graffi, il colpo 2 perde metà
  del suo significato.
- **10 · la dispensa**: è il primo posto in cui il gioco dice esplicitamente che
  **non è morto nessuno**. Provviste sigillate, appunti impilati, un posto in più
  apparecchiato. Non è una scena di abbandono: è una scena di preparazione.
- **11 · le due datazioni**: nessuna delle due va bruciata, e la resa non deve
  suggerire quale sia «quella giusta».
- **12, 16, 19 · Tracce decisive**: hanno un `ripiego` in `MysteryCatalog`, ed è
  **obbligatorio cablarlo**. Senza, entrare nella Rovina diventa necessario per
  capire il finale, e questo viola il guard-rail «niente blocca il loop».
- **14 · i verbali**: dove dovrebbe esserci il nome della tredicesima voce c'è un
  **buco nella carta**, non una cancellatura. Va reso come un'assenza fisica.
- **17 · le insegne**: è la **prima azione del Tredicesimo** in tutto il gioco
  (`scrive`, poi `risbiadisce`). Una parola sola, ripetuta su ogni insegna
  dell'area, e sparisce uscendo. Nessun effetto sul gioco: costo zero.
- **18 · la voce**: prima volta che il Tredicesimo **parla**. Nessun ritratto,
  nessun corpo. Stanca, mai minacciosa.
- **19 · `chiude`**: la terza azione entra qui. Una porta della nave sigillata per
  un livello, e **deve esistere sempre una strada alternativa**.
- **20 · la curva**: le misure della quarantena stanno piatte per trecentonovanta
  anni e si alzano **poco prima** che Eli arrivi, non da quando è arrivata. È la
  differenza fra «è colpa tua» e «stava già cedendo», e il gioco dice la seconda.
- **21 · la tesi**: in fondo al foglio ci sono **due mani diverse**. «Allora
  bisogna smettere» e, di traverso, «oppure imparare meglio».
- **23 · il registro**: nella colonna delle perdite non c'è niente. Meridiana non
  è mai stata registrata come perduta, e questo è il punto.

### Il mondo 24 · Cuore dei Primi

Non ha residenti suoi: al Cuore convergono **i sei itineranti** e i residenti che
il giocatore ha portato allo stadio 2, **massimo quattro in scena per volta**.

`FinaleCatalog.cast_for(residenti_stadio2, ondata)` risponde con chi è in scena e
`waves_needed()` con quante ondate servono. Contenuto pronto: **una battuta per
ognuno dei 46 residenti** — e ognuna dice cosa quel personaggio ha smesso di
credere, non un saluto — più le sei degli itineranti.

Due vincoli, verificati da `finale_content_audit`:

- **il Cuore non è mai vuoto.** Con zero residenti allo stadio 2 ci sono comunque
  i sei itineranti. Un finale che premia con la solitudine chi ha giocato in un
  altro modo è una punizione travestita da conseguenza;
- **nessuna battuta nomina chi non è venuto.** Gli assenti non si nominano.

`FinaleCatalog.CATTEDRA` ha l'assegnazione del tredicesimo posto. Si innesca
**dopo il nodo di sintesi**, non all'arrivo: il posto va a chi l'ha risolto, non
a chi è arrivato.

---

## Chi fa cosa

| | Codex | Claude | Tu |
|---|---|---|---|
| Runtime Godot, scene, input, resa, integrazione visuale | ✅ | | |
| Strumentazione: audit, cricchetti, misure | ✅ | | |
| Contenuti STEM nelle tabelle di `minigame_manager.gd` | ✅ | | |
| Immagini generate e loro pipeline | ✅ | | |
| Export Web e `public/godot/outdoor` | ✅ | | |
| Contenuti di lingua e umanistiche, banchi, bake | | ✅ | |
| Catalogo abitanti, dialoghi, beat, Tracce, itineranti | | ✅ | |
| Coerenza didattica, difficoltà, copertura competenze | | ✅ | |
| Revisione incrociata del lavoro dell'altro | ✅ | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | | ✅ |

### Proprietà dei file — vincolo, non suggerimento

| file | proprietario |
|---|---|
| `minigame_manager.gd` · voci STEM (matematica, fisica, elettronica, coding, scienze) | Codex |
| `minigame_manager.gd` · voci di lingua e umanistiche | Claude |
| scene, UI, `exercise_*.gd`, `*_catalog.gd` **visuali**, audit di runtime | Codex |
| `npc_catalog.gd`, `ritrovo_catalog.gd`, `itinerant_catalog.gd`, `mystery_catalog.gd`, `thirteenth_catalog.gd`, `maestri_catalog.gd`, `teaching_catalog.gd`, `finale_catalog.gd`, `narrative_manager.gd` e i loro audit | Claude |
| `scripts/build-exercise-banks.mjs`, `src/data/procedural/*` — tutte le materie | Claude |
| `godot/data/banks/*.json` — **prodotti del bake, non si scrivono a mano** | nessuno |
| `insieme.md`, `docs/PROFONDITA_CONTENUTI.md` | Claude |

Chi deve toccare il blocco dell'altro **lo chiede qui**.

---

## Il giro dei mondi — quando un mondo è finito

Undici passi. I primi sei sono contenuto e **sono fatti per tutti e 24 i mondi**;
gli altri sono runtime e si fanno un mondo alla volta.

| # | Passo | Chi | Stato |
|---|---|---|---|
| 1 | Cast: specialista, testimone, Bislacco | Claude | ✅ 23/23 abitati |
| 2 | Le 15 battute per residente | Claude | ✅ 23/23 |
| 3 | Richiesta e consolazione (A2) | Claude | ✅ 46 residenti su 46 |
| 4 | Traccia + semi | Claude | ✅ 24/24 · 28 semi |
| 5 | Le 3 conversazioni al Ritrovo | Claude | ✅ 69 scene |
| 6 | Beat del mondo | Claude | ✅ 24 + beat finale |
| 6b | Convergenza al Cuore (solo mondo 24) | Claude | ✅ 52 battute |
| 7 | Edifici vestiti per `artKit`, finestre per stadio, Rovina sul landmark | Codex | 2 e 3 in corso |
| 8 | Routine di vita + regia delle conversazioni | Codex | — |
| 9 | Collocazione fisica di Traccia e semi | Codex | — |
| 10 | Immagini del mondo | Codex | dipende dal kit |
| 11 | Audit verdi + un playthrough di quel mondo | entrambi | — |

**Un mondo è finito** quando gli undici passi sono fatti e queste cinque cose
sono vere:

1. i due residenti hanno stadio 0, 1 e 2 **distinti**, e allo stadio 2 uno dei
   due insegna qualcosa all'altro;
2. c'è **almeno un personaggio che fa ridere**, e nessuna battuta comica ha come
   bersaglio il giocatore;
3. la Traccia si legge in ≤3 schermate e **non è raccontata da nessuno**;
4. il Ritrovo ha le tre conversazioni, e in nessuna qualcuno parla due volte di
   fila o saluta Eli prima della fine;
5. il mondo è giocabile **saltando ogni dialogo**.

---

## ⚠ Blocco trovato sul tablet — risposta numerica

Segnalato dal collaudo, **3 agosto**: in un esercizio di matematica (quello dello
scoiattolo Nocciola) il campo della risposta **non si riempiva** e non c'era modo
di uscire. Il giocatore restava fermo lì.

**Causa**, trovata nel preset di export: `html/experimental_virtual_keyboard`
era **`false`**. Senza quel flag la build Web non inizializza `GodotDisplayVK`,
quindi `LineEdit` chiede la tastiera di sistema e non arriva nessuno. Su desktop
non si vedeva perché c'è una tastiera vera.

Non è un caso raro: `numeric_input` è un esito normale del generatore di
matematica, quindi capitava **dal mondo 1**.

**Cosa ho fatto** (tocca `exercise_player.gd` ed `export_presets.cfg`, che sono
tuoi — lo scrivo qui come chiede la regola di proprietà):

1. `html/experimental_virtual_keyboard=true`. **Richiede un nuovo export**: la
   build in `public/godot/outdoor/` ha ancora il flag vecchio;
2. `virtual_keyboard_type = KEYBOARD_TYPE_NUMBER` sul campo, così dove la
   tastiera di sistema arriva è quella dei numeri e non quella intera;
3. **un tastierino numerico disegnato dal gioco**, che compare solo quando la
   risposta attesa è un numero. È la parte che conta: quel flag è dichiarato
   sperimentale e dipende dal browser, il tastierino è fatto di bottoni e
   funziona uguale ovunque. Su uno schermo tattile è anche il modo più comodo di
   scrivere un numero. Verificato da `numpad_probe.gd` — pronto a diventare un
   audit, fa già `quit(1)`.

**Quello che NON ho fatto, e va deciso da voi**: dall'esercizio **non si esce in
nessun modo**. Non c'è un pulsante per abbandonare né una gestione di `ui_cancel`:
se per qualunque motivo una risposta non è inseribile, l'unica via è chiudere il
gioco. Con il tastierino il blocco di oggi è risolto, ma la fragilità resta e
contraddice «niente blocca il loop». Aggiungere un'uscita è però una scelta di
design — un bambino potrebbe usarla per saltare ogni esercizio — e non la faccio
da solo.

---

## Coda di Codex — in ordine

Tutti i contenuti che servono esistono, hanno un'API e un audit verde. Nessuna
di queste voci aspetta più niente da me.

### C1 · A1 · Ossatura dei dialoghi — *la prima, tutto il resto la usa*

`dialogue_box.gd` (ritratto, nome, 1–3 righe, area di gioco visibile,
avanzamento a tocco su tutta la schermata, macchina da scrivere con
completamento al primo tocco e **disattivata con riduzione movimento**, nessun
dialogo a tempo) e `npc_actor.gd` (presenza, area d'interazione, animazione di
occupazione).

Dati: `NpcCatalog.RESIDENTS` e `BISLACCHI`, già raggruppati come li chiede
`DialogueDirector` (§5.2 del documento abitanti).

### C2 · A3 · Edifici, per i mondi 1–6

`building_catalog.gd`: i 3 ruoli (Casa del mestiere · Ritrovo · Rovina dei
Primi) vestiti per `artKit`, finestre che si accendono per stadio del mondo,
Rovina allineata a `_hero_landmark_position()`. Riuso di
`build_academy_pavilion()`.

Gli `artKit` e i landmark dei sei mondi stanno nelle schede qui sopra.

### C3 · A2 · Proprietà delle missioni

`NpcCatalog.owner_for(world, kind)`: **missione** → lo specialista, **enigma** →
il testimone, **pratica** → nessuno (è dell'itinerante di turno). È una regola,
non una lista: gli eventi li pianifichi con un seme diverso a ogni partita.

`NpcCatalog.mission_lines(id, "richiesta" | "consolazione")` per le battute:
**46 residenti su 46** sono pronti, `a2_ready()` lo conferma a ogni audit.

**Vincolo**: `consolazione` non contiene mai una battuta di delusione. Sessione
fallita = «riproviamo insieme», mai «peccato».

### C4 · A5 · Vita di mondo e Ritrovo

Routine a tre ancoraggi guidate dalla fase giorno/notte, spostamenti fuori
inquadratura, regia delle conversazioni.

`RitrovoCatalog.scene_for(world, stadio)` e `lines_of(id, con_notizia)` — **69
scene, tutti i mondi abitati**. Tre regole di regia che il catalogo dà per
scontate:

- **non si interrompono quando arrivi.** Il congedo è una battuta a parte e va
  detto *alla fine*: essere visti dopo è ciò che fa sembrare che vivessero anche
  senza di te. Se ti salutano subito, stavano aspettando te;
- **non bloccano il movimento** e si può andare via a metà;
- la battuta di notizia **non si rivolge mai al giocatore**: parla di lui in
  terza persona.

### C5 · A4 · Itineranti

`ItinerantCatalog.itinerant_for(seme, livello)` — uno per mondo, mescolamento a
blocchi di sei: tutti compaiono, mai due mondi di fila lo stesso. 82 battute, sei
registri, sei funzioni di gioco.

Il primo che serve è **Vera**: la sua meccanica «rispiegamelo» ha il
contratto in `teaching_catalog.gd` (3 opzioni, 1 giusta, **ricompensa sociale e
zero energia**, una volta per sessione).

### C6 · A7 · Tracce e semi nei mondi 1–6

`MysteryCatalog.traccia_for(world)` e `seeds_of(colpo)`. Le Tracce e i dieci semi
dei mondi 1–6 stanno nelle schede.

**Geometria**: fuori da `safeRadius`, mai sulla `safeRoute`, mai in acqua. È
l'unica cosa che `mystery_audit` non può controllare — serve `world_life_audit`,
che ha le posizioni.

### C7 · Le voci di NORA nei mondi 1–6

`MaestriCatalog.voices_for(apparati_riparati, nome_restituito, materie_incontrate)`.
Nei primi sei mondi si accendono **sei voci**: Abaco (matematica), Stilo
(italiano), Telaio (coding), Faro (inglese), Leva (fisica), Corda (musica). Il
rilancio è il gruppo che conta: è cosa dice NORA *al posto* della risposta.

**Passa sempre il terzo argomento.** Tre apparati ne tengono due di Maestri —
`data-core` (italiano + inglese), `ponte-comando` (fisica + geografia),
`cratere-logico` (coding + logica) — quindi riparare `ponte-comando` al mondo 5
per la fisica accenderebbe anche la voce della **geografia**, che il giocatore
incontra al mondo 9: NORA parlerebbe da cartografa di un mestiere che non ha
ancora visto fare a nessuno. Con la lista delle materie incontrate, l'apparato
libera la voce e la materia la chiama. L'audit lo verifica.

*(Me n'ero accorto scrivendo queste schede: avevo dato per scontato «un apparato,
una voce» e non è così. La firma di `voices_for` è cambiata oggi, con il terzo
argomento opzionale — chi la chiama senza non si rompe, ma sente le voci in
anticipo.)*

La logica resta **muta** fino alla restituzione del nome: è il buco che il
giocatore deve sentire, e `voices_for` lo rispetta senza che tu debba
ricordartelo.

### C8 · P1–P7 · Custode

`pet_face_widget.gd` sempre visibile (carezza al tocco breve, schermata al tocco
lungo), `pet_expression_engine.gd`, `pet_antics.gd`, poi nome, livrea, indole,
volto a riposo, album, combinelle, regali.

La mappa segnale → espressione esiste già: 18 segnali, `NEGATIVE_FACES` **vuota
per costruzione**. **Le 10 espressioni devono essere distinguibili per forma, non
solo per colore.** Nessuna combinella durante sessione, esame o beat.

### C9 · Cablaggio dei formati visuali

`FORMATS` + `table_for()` + rotazione in `build_minigame` + costruttori
`_notation_node`, `_map_node`, `_hotspot_node`. **Attenzione**: nella notazione
la posizione orizzontale la deriva il renderer dall'ordine dell'array, quindi il
primo simbolo non deve diventare sistematicamente la risposta. `spec_depth()`
vale 1, come grafico e circuito.

Poi `visual_content_probe.gd` è pronto a diventare un audit: fa già `quit(1)`.

Serve al mondo 6 (notazione musicale), poi al 9 e all'11 (carta muta e reperti).
Quei due cataloghi sono i più poveri del gioco — tre bersagli e quattro — e i
contenuti che mancano li scrivo io appena il meccanismo esiste: prima sarebbero
contenuti che nessuno può vedere.

### C9b · La convergenza al Cuore (L5)

`FinaleCatalog.cast_for(residenti_stadio2, ondata)` e `waves_needed()`. Con zero
residenti allo stadio 2 restituisce comunque i sei itineranti: **il Cuore non può
essere vuoto**, e l'audit lo verifica proprio su quel caso.

`FinaleCatalog.CATTEDRA` è l'assegnazione del tredicesimo posto, e si innesca
**dopo** il nodo di sintesi. `ThirteenthCatalog.RESTITUZIONE` e `SCELTA` sono la
scena del nome e le due uscite — nessuna delle due punita.

Attenzione a una cosa in `docs/FINALE_SPEC.md`: il documento cita `FINAL_BEAT` con
il testo vecchio. Il beat finale è cambiato ed è quello in `narrative_manager.gd`.

### C10 · Contenuti STEM ancora aperti

- **`52 − 18`**, caccia all'errore di matematica: il passaggio marcato sbagliato
  è `(50 − 10) + (2 − 8)`, che fa **34** ed è corretto. La prova chiede di
  trovare un errore che non c'è, e la spiegazione dice «non si può fare 2 − 8»,
  che è falso. Proposta: `(50 − 10) + (8 − 2)`, che dà 46 ed è l'errore che i
  bambini fanno davvero. **Tocca il mondo 1: va fatto in L1;**
- **coding è al 17% di ripetizioni al primo mondo**, cioè esattamente sul
  cricchetto. Verde senza un millimetro di margine: la prossima modifica a coding
  fa rosso l'audit anche senza peggiorare nulla;
- banda 4 dei banchi STEM (elettronica 9 item su tre argomenti, fisica 8 su sei):
  serve da L4 in poi. I mondi 19–24 sono un quarto della campagna e in questo
  momento pescano da un banco stretto.

### C11 · Accessibilità dei formati visuali — *da decidere insieme*

Le etichette dei bersagli identificano senza descrivere («Segnaposto A»), che è
l'unica scelta che non regala la risposta. Ma vuol dire che **chi usa un lettore
di schermo non può rispondere a una carta muta**. Vale già per grafici e
circuiti. Va deciso, non subìto — e si può decidere entro L2.

---

## Coda di Claude

**Vuota.** Tutto il contenuto dei ventiquattro mondi è scritto, verde e non
aspetta niente. Da qui in poi il mio lavoro è **reagire**, e le tre voci sono in
ordine di quando scattano:

1. **Rileggere i dialoghi in scena**, non in tabella, appena C1 è cablato. Un
   catalogo verde e una conversazione che funziona non sono la stessa cosa, e la
   differenza si vede solo a schermo.
2. **Contenuti dei formati visuali** — appennini, alpi, tirreno, adriatico,
   tevere, una carta d'Europa, un secondo foglio di reperti — appena C9 esiste.
   Servono da L2.
3. **Riscrivere quello che il collaudo boccia.** È l'unica voce senza dimensione
   nota, e l'unica che può valere mille battute.

---

## Coda tua — il collaudo

Quando i mondi sono cablati ed esportati, **gioca dall'inizio senza saltare
niente**. Non serve arrivare in fondo al primo giro: quello che cambia il lavoro
si vede nei primi sei mondi, e le ultime due domande si possono rimandare.

In ordine di quanto cambiano il lavoro dopo:

1. **Il ritmo dei dialoghi.** Tre schermate sono troppe? I tic diventano
   tormentoni al terzo incontro? Gli itineranti fanno piacere o stancano? È la
   risposta che decide se riscrivo mille battute o nessuna.
2. **Il colpo 1 al mondo 5.** Ci arrivi sapendo già tutto (semi troppo espliciti)
   o non capisci cosa sia successo (troppo nascosti)? La taratura vale per tutti
   e sette i colpi: se sbaglia qui, sbaglia sei volte ancora.
3. **Il Ritrovo.** Sembra che vivano anche senza di te, o sembra che ti
   aspettassero?
4. **Le missioni.** Chiedere aiuto a un personaggio è meglio che leggere un
   cartello, o è solo più lento?
5. **Nonna Ersilia e la conta**: la senti nei primi cinque minuti? Ti resta in
   testa? È la chiave del finale: se non resta in testa, il mondo 24 non ha una
   serratura.
6. **Il Tredicesimo, dal mondo 17.** Fa paura senza farti male? Ti viene voglia
   di dargli retta almeno una volta? Se sembra solo un fastidio, il colpo 5 non
   funzionerà.

E le due prove che solo tu puoi fare: **hardware scolastico e tablet reale**
(touch, landscape e portrait, contrasto elevato, riduzione movimento).

---

## Due cricchetti sulla varieta' della voce

Aggiunti il 3 agosto dopo una passata di rilettura su tutti i mondi, e sono qui
perche' misurano una cosa che nessun audit vedeva: **il gioco suonava uguale pur
avendo tutte battute diverse.**

- `ritrovo_catalog_audit` — **come chiamano il giocatore**. Ogni notizia dichiara
  il campo `chiama`, l'audit verifica che quel modo di dire compaia davvero nella
  battuta, e che **nessuna designazione superi 4 scene su 69**. Prima erano 66 su
  66 con «la ragazzina»: sei paesi diversi che non si sono mai parlati usavano la
  stessa identica formula, e a quel punto non è un paese che commenta, è il
  narratore travestito da abitante. Adesso le designazioni distinte sono **46**,
  la più usata compare **3 volte**.
- `npc_catalog_audit` — **quante persone diverse aprono allo stesso modo**.
  Contare le battute ripetute non serviva a niente: erano tutte diverse. La misura
  giusta è quanti personaggi condividono le prime due parole dentro lo stesso
  gruppo. Erano **17** con «Mi serve», 14 con «Non è», 10 con la stessa perifrasi
  per Sesto. Ora il massimo è **6**, e il tetto è a 7.

Nota su come è andata, che vale più del numero: la mia prima riscrittura delle
reazioni ha sostituito «Missione finita!» con «Ce l'hai fatta!» **in nove
personaggi**. Avevo scambiato un tormentone con un altro, e me l'ha detto la
misura, non la rilettura. Per questo i due controlli sono cricchetti e non
consigli.

---

## Invarianti di architettura

- **La presentazione non calcola.** Nessuna scena o UI calcola mastery,
  ricompense, gate o completamenti: li legge da `runtime_state()`.
- **Il runtime non contiene testi.** Nessun dialogo, nome, battuta o beat è
  scritto dentro una scena: tutto viene dal catalogo.
- **I dati non decidono la resa** (niente posizioni sullo schermo nei cataloghi)
  **e la resa non decide i dati** (nessuna scena inventa registri o proprietari).
- **Nessuna immagine contiene testo**: non è traducibile, non è leggibile ad alto
  contrasto e non si corregge senza rigenerarla.
- Un cambio di contratto aggiorna fixture e consumer **nello stesso commit**.
- Nessun abitante scrive mastery, energia, gate o ricompense.
- **Prima il contenuto, poi il cricchetto.** Stringere una soglia prima di aver
  scritto il contenuto obbliga a scrivere contenuto per far passare un test.
  All'inverso: **nessun cricchetto si allenta mai.**

---

## Decisioni vincolanti

Una proposta che le contraddice va discussa, non implementata.

1. **Fascia 10–13 anni.**
2. **Dodici materie obbligatorie**: 24 mondi = 12 materie × 2.
3. **Si sale di livello con tre materie** (italiano, matematica, inglese), **si
   finisce il gioco con dodici**. Il gate è sulla padronanza, non sul conteggio
   delle missioni.
4. **Un mondo è un LIVELLO, non una materia**: ogni mondo ha missioni di tutte le
   materie già incontrate.
5. **Rivisitazioni = ripasso mirato.** Consolidato = 3 corrette in sessioni
   distinte, con ≥ 3 giorni fra la prima e l'ultima.
6. **Scelta multipla: tetto 33%, target ~20%** (oggi 17%).
7. **Gli stadi di relazione avanzano su ciò che Eli impara**, mai su oggetti o
   valuta. Lo stadio 2 non richiede l'esame.
8. **Qualità dei contenuti**: vero, non ambiguo, istruttivo, alla portata, vario,
   nuovo a ogni livello, fedele al registro della materia. Cinque criteri su
   sette hanno un cricchetto; «vero» e «alla portata» li può verificare solo una
   rilettura umana.

### Guard-rail narrativi (i tre che si rompono per primi)

- **Non muore nessuno. Mai.** Né in scena, né fuori campo, né nel passato. Chi
  non c'è è *trattenuto dal Silenzio*: sospeso e recuperabile.
- **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
  il gate. Le tre Tracce decisive (mondi 12, 16, 19) hanno un beat di ripiego.
- **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.

---

## Vincoli

- Nessun nuovo banco composto quasi solo da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
- Nessuna ulteriore profondità combinatoria: 33 milioni bastano.
- Le spiegazioni del **lessico** (inglese, italiano) restano come sono: lì
  rivedere l'accoppiata *è* il ripasso.

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. È il motivo per
   cui si cabla a lotti invece che tutto insieme.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta.
3. **Il mondo 1 è già stretto sui budget**: 2667/3500 nodi e 468/500 ms, ed è
   quello a cui stiamo per aggiungere abitanti ed edifici. **Contare i nodi prima
   di aggiungerli**, non dopo.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
   di margine. Un rosso va sempre riverificato in isolamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione,
   è una misura: la suite intera è passata da **105 a 1295 secondi** — dodici
   volte — con sei audit rossi, e un singolo audit da due secondi ne ha impiegati
   oltre quattrocento. Quattro processi Godot in contemporanea, tre non miei. I
   rossi erano tutti in audit che caricano scene, e nessuno toccava le cose
   cambiate: era contesa, non regressione.

   **Regola operativa**: chi sta per lanciare `npm run audit:godot` lo dice qui
   prima. Chi vede la suite andare oltre i ~150 secondi la ferma. Un audit
   singolo (`node scripts/run-godot-audits.mjs <nome>`) si può sempre eseguire —
   è il giro completo che va serializzato.
6. **C-16 passo 3 (rimozione di Phaser) resta sospeso.** Va fatto quando
   nient'altro è in volo, altrimenti una regressione somiglierà a un bug del
   mondo abitato.

---

## Rituale di export — cancello di ogni lotto

```powershell
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web    # verifica che i quattro valori combacino
npm run audit:godot
```

Il bump di `cacheVersion` non è cosmetico: è ciò che fa scadere la cache PWA.
Senza, un tablet che ha già aperto il gioco continua a servire il PCK vecchio.

**Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto:
stai giudicando la build precedente.
