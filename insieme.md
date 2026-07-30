# Eli Quest — Piano operativo condiviso

Aggiornato al 30 luglio 2026.

Questo file contiene **soltanto** lavoro aperto, decisioni e regole condivise.
I resoconti dei lavori chiusi stanno nel *Registro dei lavori C-P6* in
[docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md), insieme alle misure:
qui non si archivia, qui si lavora.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Trama, mistero e colpi di scena](docs/TRAMA_E_MISTERO.md)
- [Abitanti e luoghi](docs/ABITANTI_E_LUOGHI.md)
- [Il Custode (pet)](docs/PET_CUSTODE.md)
- [Il Secondo Viaggio (gioco sbloccato)](docs/SECONDO_VIAGGIO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)
- [Specifica del finale](docs/FINALE_SPEC.md)
- [Design minigiochi](docs/MINIGAMES_DESIGN.md)
- [Baseline release candidate + registro](docs/RELEASE_CANDIDATE.md)

## Obiettivo

Portare il percorso Godot completo alla qualità di consegna: apprendimento,
missioni, mondi, NORA e riattivazione della nave devono restare un unico ciclo
leggibile, accessibile, performante e pubblicabile su desktop, tablet e Web.

## Chi fa cosa mentre Codex è fermo (dal 30 luglio)

Codex non è disponibile per un periodo non definito. Fino al suo ritorno **il
lavoro lo facciamo in due**: io scrivo runtime, resa e contenuti; a te resta
l'unica cosa che non è delegabile a nessuno — **giocare e giudicare**.

Le due sezioni «Compiti Codex» e «Compiti Opus» qui sotto restano come
**tassonomia del lavoro**, non come assegnazione: servono a ridividere i compiti
quando Codex torna, e i loro identificatori (C-P7, O-P6) restano validi come
etichette. L'assegnazione corrente è questa tabella.

| | Io (Claude) | Tu |
|---|---|---|
| GDScript, scene, UI, dati, cataloghi, testi | ✅ | |
| Audit headless (`npm run audit:godot`) | ✅ | |
| Export Web e aggiornamento di `public/godot/outdoor` | ✅ | |
| Test Node (`npm test`) e bake contenuti | ✅ | |
| **Giudizio su feel, juice, leggibilità, art direction** | | ✅ |
| **Prova su tablet reale**: touch, viewport, contrasto, movimento | | ✅ |
| **Profiling su hardware scolastico reale** | | ✅ |
| **Decidere se una cosa è divertente** | | ✅ |

### Cosa posso verificare da qui (verificato il 30 luglio)

- **Godot gira in locale**:
  `C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`.
  Il progetto apre headless senza parse error.
- **Gli audit girano onesti**: `npm run audit:godot` usa
  `scripts/run-godot-audits.mjs`, che già gestisce i tre gotcha che hanno fatto
  perdere settimane — l'exit code bugiardo (un `assert` fallito non lo cambia),
  il save reale letto da `roundtrip_audit` (usa una APPDATA isolata) e il
  processo che resta appeso (timeout per audit).
- **L'export Web è possibile**: i template `4.7.1.stable` sono installati
  (`web_release.zip`, `web_nothreads_release.zip`). Quindi **puoi giocare quello
  che scrivo**, ed è il fatto che rende praticabile tutto questo piano.
  I template *Windows desktop* non sono installati: niente `.exe`, e non serve —
  il target è Web.
- **Il menu nativo esiste già**: `run/main_scene="res://scenes/boot_menu.tscn"`,
  e `boot_menu.gd` costruisce la UI a codice. La voce di menu della tappa 1 è
  davvero piccola.

### Cosa non posso verificare, mai

Io non vedo il gioco. Esporto e tu guardi. Quindi ogni giudizio su bellezza,
ritmo, comicità e piacevolezza è tuo, e nessun audit lo sostituisce: gli audit
dicono che una cosa è *corretta, varia e onesta*, non che è *bella*.

### Regola operativa: l'export è un cancello di ogni tappa

`public/godot/outdoor/` invecchia più in fretta del codice. Con un solo
sviluppatore questo è il modo numero uno in cui questa collaborazione può fallire
in silenzio: **tu provi la build vecchia e giudichi lavoro che non esiste.**

Non serve inventare un processo, esiste già: il launcher confronta il **build ID**
e attende l'attivazione del nuovo service worker prima di aprire Godot, e
`npm run audit:web` verifica build ID, versione della cache e dimensioni
PCK/WASM. Quindi ogni tappa si chiude così:

```powershell
& "C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web    # verifica che i quattro valori combacino
npm run audit:godot
```

Il passo `web:sync` non è cosmetico: **il bump di `cacheVersion` è ciò che fa
scadere la cache PWA.** Senza, un tablet che ha già aperto il gioco continua a
servire il PCK vecchio e non vedrà mai il nuovo export. È il difetto scoperto
alla prima esecuzione reale di questo rituale (tappa 1): l'export cambia le
dimensioni del PCK e lascia indietro manifest e service worker, e correggere
quattro valori a mano nove volte di fila sarebbe andato storto almeno una.
`npm run web:sync:check` dice se serve, senza scrivere.

E io **te lo dico esplicitamente** quando l'ho fatto. Se non lo dico, non l'ho
fatto: stai provando la build precedente, non fidarti di quello che vedi.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance, regressioni ed export. **Sospeso: li faccio io.**

### C-P6 — Verifiche manuali e consegna

1. [x] Playthrough manuale dei mondi acquatici e dei mondi 1, 7, 13, 19 e 24.
2. [x] Feel e juice dei renderer non-MC (snap, collegamenti, errori).
3. [x] Regia, camera, animazioni, transizioni e sound design dei traguardi.
4. [x] Incoerenze di art direction osservabili durante il playthrough.
5. [ ] **Profilare su hardware scolastico/tablet REALE** e confermare i budget
   già fissati e misurati in browser (`docs/RELEASE_CANDIDATE.md`).
6. [ ] **Provare su tablet REALE** comandi touch, viewport landscape e portrait,
   leggibilità, contrasto elevato e riduzione movimento.
7. [x] Smoke test in un browser reale dell'export Web.
8. [ ] Correggere i difetti osservati in 1–7, rieseguire la suite e approvare il
   commit come release candidate pubblicabile.

I punti 5 e 6 richiedono un dispositivo fisico: **sono tuoi**, e non dipendono da
me — puoi farli in qualunque momento, anche mentre lavoro ad altro. Il punto 8
ora è mio per la parte di correzione, tuo per l'approvazione. Gli esiti dei punti
chiusi sono nel registro.

**Nota di sequenza**: C-P6 non blocca il mondo abitato e il mondo abitato non
blocca C-P6. Sono due binari paralleli — tu sul tablet, io sul codice.

Definizione di completato C-P6:

- nessuna interazione essenziale dipende dalla tastiera;
- percorso 1→24 e post-finale completabili senza injection o reset;
- nessun audit rosso o errore Godot bloccante — verificato con
  `npm run audit:godot`, che considera verde un audit solo se non stampa
  asserzioni fallite (l'exit code di Godot non le riflette);
- nessuna perdita di stato e nessun soft-lock da acqua, tool o anomalie;
- UI leggibile alle viewport target e con riduzione movimento/contrasto validati;
- budget misurati su dispositivi target;
- export Web avviabile e navigabile;
- artefatti e documentazione di consegna aggiornati.

### C-P7 — Il mondo abitato

Nuovo asse deciso il 30 luglio (vedi *Nuovo asse di lavoro* più sotto). Progetto
in [Trama](docs/TRAMA_E_MISTERO.md), [Abitanti](docs/ABITANTI_E_LUOGHI.md),
[Custode](docs/PET_CUSTODE.md), [Secondo Viaggio](docs/SECONDO_VIAGGIO.md).

Elenco di **tutto il lavoro di runtime e resa**, per riferimento e per poterlo
ridividere quando Codex torna. L'ordine in cui lo affronto ora è quello delle
tappe più sotto, non questo.

1. [x] **S0 · Voce di menu bloccata.** `boot_menu.gd`: «IL SECONDO VIAGGIO —
   Rotta chiusa · N/24», contatore letto da `ProgressionManager.campaign_progress()`
   (fatto prodotto nell'autorità, non derivato dalla UI). Nessuna logica di gate
   nuova, nessuna migrazione di save: lo sblocco è **derivato** da
   `is_complete()`, quindi non falsificabile. Audit
   `second_journey_unlock_audit.gd`. Animazione di sblocco **rinviata** alla
   tappa 9: appartiene alla celebrazione del finale, non a un segnaposto.
2. [ ] **A1 · Ossatura dei dialoghi.** `dialogue_box.gd` (ritratto, nome, 1–3
   righe, area di gioco ancora visibile, avanzamento a tocco su tutta la
   schermata, macchina da scrivere con completamento al primo tocco e
   **disattivata con riduzione movimento**, nessun dialogo a tempo) e
   `npc_actor.gd` (presenza, area d'interazione, animazione di occupazione).
3. [ ] **A2 · Proprietà delle missioni.** Legge `ownerNpc` dagli eventi già
   pianificati e monta il flusso richiesta → evidenziazione in bussola →
   svolgimento (invariato) → ritorno. Codex non decide chi possiede cosa.
4. [ ] **A3 · Edifici.** `building_catalog.gd`: i 3 ruoli (Casa del mestiere ·
   Ritrovo · Rovina dei Primi) vestiti per `artKit`, finestre che si accendono
   per stadio del mondo, Rovina allineata al landmark eroe già calcolato da
   `_hero_landmark_position()`. Riuso di `build_academy_pavilion()`.
5. [ ] **A5 · Vita di mondo.** Routine a tre ancoraggi guidate dalla fase
   giorno/notte, spostamenti fuori inquadratura, e **regia delle conversazioni al
   Ritrovo**: non bloccano il movimento, si può andare via, i personaggi si
   accorgono di Eli alla fine e non si interrompono subito.
6. [ ] **P1–P3 · Custode.** `pet_face_widget.gd` sempre visibile (carezza al
   tocco breve, schermata al tocco lungo), `pet_expression_engine.gd`,
   `pet_antics.gd`. Le 10 espressioni devono essere distinguibili **per forma**,
   non solo per colore. Nessuna combinella durante sessione, esame o beat, con la
   sola eccezione dello starnuto autorato.
7. [ ] **P4–P7 · Schermata del Custode** (nome, livrea, indole, volto a riposo,
   album, combinelle, regali) e indole applicata al corpo in
   `pet_companion.gd`.
8. [ ] **A7a · Il Tredicesimo e la Cattedra Vuota.** Resa delle 5 azioni (scrive
   *FERMATI* sulle insegne, ri-sbiadisce un'area, smemora un abitante per una
   scena, sigilla una porta con percorso alternativo garantito, parla); la
   **stanza senza porta** in `ship_room_catalog.gd`; il **posto apparecchiato**
   visibile dal mondo 10 e la sua assegnazione nella regia del finale.
9. [ ] **A7b · Sbiaditi.** Re-theme di `world_enemy.gd`: comportamento
   invariato, effetto locale di svuotamento delle etichette, zero leve
   meccaniche.
10. [ ] **Budget e accessibilità.** Max 4 abitanti istanziati, streaming come i
    POI, nessun `_process` fuori dallo `streamRadius`; riverifica di
    `performance_budget` **con abitanti ed edifici in scena**; ogni interazione
    raggiungibile a tocco; contrasto elevato e riduzione movimento validati.
11. [ ] **Audit di resa.** `world_life_audit`, `building_audit`,
    `pet_expression_audit` (lato presentazione) ed estensione di
    `outdoor_presentation_audit`.

Definizione di completato C-P7:

- **degradazione pulita**: con catalogo abitanti vuoto il gioco è quello di oggi,
  e il percorso 1→24 si completa senza parlare con nessuno;
- nessun abitante ed edificio in acqua, dentro `shipEntrance.safeRadius`, sulla
  `safeRoute` o sopra un POI del gate;
- max 4 abitanti in scena e budget confermati con abitanti ed edifici attivi;
- ogni dialogo avanzabile a tocco, nessuno a tempo, macchina da scrivere
  disattivata con riduzione movimento;
- le 10 espressioni del Custode leggibili in contrasto elevato e per forma;
- nessuna azione del Tredicesimo tocca energia, mastery, gate o salvataggio;
- voce di menu bloccata non aggirabile;
- nessun audit rosso (`npm run audit:godot`).

## Compiti Opus

Opus è responsabile di contenuti, coerenza didattica, difficoltà, copertura delle
competenze e validazione del percorso educativo.

1. [x] Revisione didattica finale sui 24 mondi e sul finale trasversale.
2. [x] Distribuzione reale dei formati nell'esperienza giocata, materia per
   materia.
3. [x] Profondità, distrattori e qualità dei livelli alti.
4. [x] Fixture e consumer aggiornati insieme ai contratti toccati.
5. [x] Rivisitazioni come ripasso mirato (decisione 3).
6. [x] Criterio di consolidamento a tempo reale (decisione 4).

C-P6 lato Opus è chiuso: misure ed esiti sono nel registro, i guard-rail vivono
negli audit (`format_mix`, `content_depth`, `revisit`, `topic_evidence`).

### O-P6 — Contenuti del mondo abitato

Contropartita di C-P7: tutto il lavoro di contenuto. Con un solo sviluppatore la
dipendenza «prima il catalogo, poi il runtime che lo legge» **non è più un
handoff fra due agenti**: catalogo e scena che lo consuma nascono nello stesso
commit, ed è l'unico vantaggio reale di aver perso Codex. Vale ancora la regola
architetturale: il catalogo si scrive prima, e la scena non contiene testi.

1. [ ] **Catalogo abitanti** — 48 residenti (2 per mondo) + 24 Bislacchi + 6
   itineranti, ognuno con `registro`, `tic`, `convinzione`, `bisogno`, arco a 3
   stadi e **≥12 battute** (≥4 per un Bislacco). **Mondo 1 per primo**, come
   fixture di A1.
2. [ ] **I 24 beat riscritti** + beat finale in `narrative_manager.gd`.
3. [ ] **Semi dei sette colpi di scena**: almeno 3 per colpo, collocati nei mondi
   precedenti — compresa la filastrocca di nonna Ersilia nel mondo 1, che
   contiene il nome cancellato del Tredicesimo.
4. [ ] **Le 12 inflessioni dei Maestri** come tabella in `nora_context_engine.gd`,
   più i quattro stadi di registro di NORA.
5. [ ] **Le 24 Tracce** e la sezione «Tracce dei Primi» nel Codex, distinta dalle
   voci didattiche.
6. [ ] **Le 72 conversazioni al Ritrovo** (24 mondi × 3 stadi), 4–6 battute
   ciascuna, almeno una che riferisce qualcosa che il giocatore ha fatto.
7. [ ] **Assegnazione `ownerNpc`** agli eventi già pianificati, più i testi di
   richiesta e di ritorno — compreso il ritorno **dopo una sessione fallita**,
   che non può mai essere deluso.
8. [ ] **Mappa segnale → espressione** del Custode (nessun segnale negativo
   mappato a una faccia negativa, perché non ne esistono) e le battute deadpan di
   NORA sul Custode.
9. [ ] **«Rispiegamelo» di Vera**: terne di spiegazioni per topic (mirata /
   corretta-ma-fuori-bersaglio / errore tipico), attinte da `error` e `why` del
   Codex.
10. [ ] **Il Secondo Viaggio**: contratto dei ragionamenti a passi con **posizione
    dell'errore ruotata**, le 11 sorelle e il capitolo di Meridiana.
11. [ ] **Audit di contenuto**: `npc_catalog`, `register_mix`, `dialogue`,
    `mystery`, `second_journey`, più l'estensione di `giveaway_audit` alle
    battute dei dialoghi.

Definizione di completato O-P6:

- ogni residente e ogni Bislacco passa `npc_catalog_audit` e `register_mix_audit`;
- ogni colpo di scena ha ≥3 semi verificati;
- **nessun testo contiene formule di morte** applicate a un personaggio;
- nessuna battuta contiene la risposta di un esercizio (`giveaway_audit`);
- ogni mondo ha almeno un personaggio che fa ridere;
- lingua e lessico entro la fascia 10–13.

## Invarianti di architettura (ex Gate Codex ↔ Opus)

Queste regole nascevano come confini **fra due agenti**. Con un solo sviluppatore
un confine di persone non esiste più — ma il confine di *codice* sì, ed è quello
che valeva davvero. Riscritte come invarianti verificabili sopravvivono al
ritorno di Codex, e valgono soprattutto adesso: **quando dato e consumer li
scrive la stessa mano è il momento in cui è più facile violarli.**

- **La presentazione non calcola.** Nessuna scena o UI calcola mastery,
  ricompense, gate o completamenti: li legge da `runtime_state()`. Un fatto, un
  solo posto che lo produce.
- **Il runtime non contiene testi.** Nessun dialogo, nome, battuta, beat o
  Traccia è scritto dentro una scena o un nodo UI: tutto viene dal catalogo. Un
  segnaposto è ammesso solo se marcato `TODO-TESTO` e tracciato qui sotto.
- **I dati non decidono la resa.** Un catalogo non contiene posizioni sullo
  schermo, budget o priorità di rendering.
- **La resa non decide i dati.** Una scena non inventa registro, proprietario di
  una missione, stadio di relazione o mappa segnale → espressione.
- Un cambio di contratto aggiorna fixture e consumer **nello stesso commit**.
- Nessun polish indebolisce il significato didattico della trasformazione del
  mondo o della riattivazione della nave.
- Nessun nemico o strumento sottrae mastery, consuma energia didattica o blocca
  gli eventi minimi necessari al gate.

Il release candidate si chiude soltanto quando runtime, contenuti, input touch,
accessibilità, performance ed export sono verdi insieme.

### Rischio nuovo: nessuno rilegge il mio codice

Con Codex fermo salta la revisione incrociata, che era un controllo reale. Tre
mitigazioni, in ordine di forza:

1. **Gli audit restano il vincolo duro** — e ne aggiungo uno per ogni tappa, non
   dopo. Un audit scritto dopo è un audit scritto per passare.
2. **Tu giochi ogni tappa.** È il controllo più forte che resta, ed è il motivo
   per cui le tappe sono piccole.
3. `/code-review` sul diff prima di chiudere una tappa, quando il cambiamento
   tocca salvataggio, gate o economia. Lo lanci tu quando te lo segnalo.

## Decisioni prese (29 luglio)

Sono vincoli per entrambi: una proposta che le contraddice va discussa, non
implementata.

1. **Fascia di lancio: 10–13 anni** (fine primaria + medie). È l'arco che i
   contenuti coprono davvero, quindi la rampa resta com'è: mondi 1–12
   introduzione (difficoltà 1→3), mondi 13–24 approfondimento (3→4). Nel save è
   `config.schoolBand = "primaria-secondaria-1"`.
2. **Tutte e 12 le materie sono obbligatorie**: 24 mondi = 12 materie × 2
   comparse e il finale accende i dodici sistemi. `LearningConfig.activeSubjects`
   resta un aggancio per sperimentazioni in classe, non una configurazione
   supportata dal gate di consegna.
3. **Rivisitazioni = ripasso mirato**: nel mondo che si torna a visitare le prove
   sono quelle di quel mondo, con priorità agli argomenti deboli e in scadenza.
   Nessuna banda di difficoltà 5. L'esame dell'apparato resta al rango.
4. **Consolidato = 3 corrette in sessioni distinte, con ≥ 3 giorni tra la prima e
   l'ultima.** Non è un requisito del gate: un mondo resta completabile in un
   pomeriggio. È lo stato dichiarato nel Manuale e nel report.
5. **Scelta multipla: tetto 33%, target ~20%** (misurato: 17%). La validazione
   con i docenti resta un riscontro sul campo, non un blocco.
6. **Budget prestazionali confermati** ai valori di `performance_budget`. Resta
   solo la verifica su tablet fisico (punto C-P6 #5).

## Nuovo asse di lavoro: il mondo abitato (30 luglio)

Decisione dell'utente: il gioco integra tre caratteristiche nuove — **abitanti
parlanti**, **Custode sempre visibile**, **NORA ridefinita** — dentro una trama
riscritta. Progetto completo nei tre documenti nuovi; qui solo il lavoro aperto.

Perno della riscrittura: la nave era una **nave-scuola**, il Silenzio scioglie il
legame tra le cose e il loro significato, i Dodici Maestri si sono chiusi negli
apparati. Ma i posti dell'equipaggio erano **tredici**: il Tredicesimo (**Scala**)
propose la chiusura, si escluse, e da quattrocento anni tiene fuori il Silenzio
da solo, in una stanza che non è su nessuna mappa. NORA non è la mente della
nave: è **la prima allieva** — e ha costruito **undici sorelle prima di Eli**,
perdendole tutte allo stesso modo: dicendogli tutto.

Da qui la risposta emotiva alla domanda che il gioco non aveva: *perché NORA non
ti dà mai la risposta?* Perché l'ha già data undici volte. L'ultimo colpo di
scena riscrive all'indietro **la meccanica**, non solo la storia.

Sette colpi di scena concatenati (mondi 5, 8, 12, 16, 19–20, 23, 24), un
antagonista con motivo e azioni, e un finale che apre un secondo gioco.

**Lo scopo finale è filosofico.** I posti dell'equipaggio erano tredici: undici
nomi, uno raschiato e **uno mai inciso**. La cattedra vuota era apparecchiata per
ciò che i Primi stavano cercando — un sapere sotto tutti gli altri. Tre
personaggi danno tre risposte diverse (i Dodici: è una cosa da trovare; Scala:
non esiste ed è pericoloso cercarlo; Meridiana: si trova solo andandoci), e la
quarta la produce il giocatore **con le mani**: risolvendo il nodo di sintesi
del mondo 24, che nessuno gli ha spiegato. La nave assegna a Eli il tredicesimo
posto. Il Fondo non era una cosa da trovare: era qualcuno da diventare — ed è
supremo perché è l'unico sapere che si regala senza perderlo.

Vincoli che questo asse non può violare (valgono come le decisioni del 29):

1. **Nessuna seconda progressione.** Gli abitanti danno volto e motivo agli
   eventi che `MissionEventDirector` pianifica già: niente missioni nuove,
   niente mastery, niente energia, nessun effetto sul gate.
2. **Nessun contenuto narrativo obbligatorio.** 1→24 resta completabile senza
   parlare con nessuno e senza leggere una Traccia.
3. **Il Custode non è mai punitivo**: nessun accudimento a decadimento, nessuna
   espressione negativa, e all'errore fa la faccia *incoraggiante*. È anche il
   comico del gioco: si accarezza, fa combinelle, porta regali inutili e NORA lo
   commenta in deadpan. **Nessuna battuta è mai su Eli o su un errore.**
4. **Non muore nessuno**, né in scena né nel passato. Chi manca è **trattenuto
   dal Silenzio** — sospeso e recuperabile. Vale per Meridiana e per le undici
   sorelle. `mystery_audit` tiene una lista di termini vietati.
5. **Varietà di tono obbligatoria**: ogni personaggio ha un `registro` fra otto
   (curioso, misterioso, buffo, divertente, caloroso, burbero, solenne,
   sognante); i due residenti di un mondo non possono averlo uguale, e ogni mondo
   ha **almeno un personaggio che fa ridere** (i 24 Bislacchi). Il registro
   cambia *come* si dice, mai *cosa* si insegna.
6. **Nessun personaggio regala risposte.** Metodo, contesto e incoraggiamento
   sì; soluzioni no — sarebbe Silenzio in miniatura. Estende `giveaway_audit`.
7. **Budget invariato**: max 4 abitanti in scena, streaming come i POI.
8. **Il Tredicesimo non ha leve meccaniche.** Scrive, ri-sbiadisce, smemora un
   abitante per una scena, chiude una porta: tutto narrativo e reversibile.
   Zero effetti su energia, mastery, gate o salvataggio.
9. **Ogni colpo di scena ha ≥3 semi** nei mondi precedenti, verificati da
   `mystery_audit`. Una rivelazione senza semi è un trucco, non un colpo di scena.
10. **Il Secondo Viaggio si sblocca solo a 24/24** e non è aggirabile con energia,
    cosmetici o moduli. Legge il save campagna, non lo scrive mai.

### Le tappe

Con un solo sviluppatore non si parallelizza: si **serializza scegliendo l'ordine
che ti fa vedere qualcosa il più spesso possibile.** Ogni tappa è un incremento
esportabile e giocabile, e ognuna chiude con tre cose fisse:

1. gli audit verdi (`npm run audit:godot`, più quello nuovo della tappa);
2. il **re-export** di `public/godot/outdoor/`, dichiarato esplicitamente;
3. una **lista di cosa guardare** — perché «gioca e dimmi» senza checklist ti fa
   perdere tempo e non produce le informazioni che mi servono.

| # | Tappa | Cosa vedi tu | Etichette |
|---|---|---|---|
| **1** ✅ | **La voce bloccata in menu** | Al primo avvio: «IL SECONDO VIAGGIO — Rotta chiusa · 0/24». I 24 mondi diventano un percorso verso qualcosa | S0 |
| **2** | **Il Custode** | Un cucciolo a cui dai un nome, con la faccia sempre in un angolo, che si accarezza, reagisce e ogni tanto fa una figura barbina mentre NORA prende appunti | P1–P3 |
| **3** | **Parlare con qualcuno** | Tobia, nonna Ersilia e Puccio nella Radura. Si parla, e rispondono in carattere | A1 + O-P6.1 |
| **4** | **Missioni con un volto** | La stessa missione di prima, ma chiesta da Tobia, con la bussola che punta e una battuta al ritorno — anche se hai fallito | A2 + O-P6.7 |
| **5** | **Gli edifici del mondo 1** | Casa del Conto, Fontana dei Filari, Obelisco dei Numeri. Le finestre si accendono man mano | A3 |
| **6** | **Il mondo che vive** | Gli abitanti si spostano, e al Ritrovo Tobia ed Ersilia **parlano tra loro** di quello che hai fatto | A5 |
| — | **PUNTO DI VERIFICA — vincolante** | Giochi il mondo 1 e decidi se continuare così | — |
| **7** | **I 24 mondi** | 48 residenti, 24 Bislacchi, 6 itineranti, 72 conversazioni, 24 Tracce | O-P6.1/6 |
| **8** | **Il mistero** | I 24 beat, i semi dei sette colpi, il Tredicesimo, la stanza senza porta, la Cattedra Vuota | A7 + O-P6.2/3/5 |
| **9** | **Il Secondo Viaggio** | Il gioco che si sblocca | S1–S5 |

**Perché la tappa 1 è così piccola.** Non serve il contatore: serve fare il giro
completo — scrivo, audit, export, tu giochi — su un cambiamento a rischio zero.
Se il giro si rompe (export vecchio, cache PWA, audit bugiardo) si rompe lì,
invece che dopo tremila righe di abitanti.

**Perché il Custode viene prima dei personaggi, contro l'ordine che avevi dato.**
Tre ragioni, e se non ti convincono si scambia:

- è **l'unica feature con zero dipendenze di contenuto**: i personaggi sono per
  l'80% scrittura, e mentre tu giochi con il Custode io scrivo il cast;
- valida l'integrazione più rischiosa di tutte — una UI che deve sopravvivere a
  mondo, nave ed esercizi senza mai coprire un pulsante. Meglio scoprirlo su un
  widget che su una finestra di dialogo;
- è il massimo ritorno emotivo per riga di codice, ed è il richiamo che hai
  indicato come il più forte per il pubblico vero.

**Il punto di verifica alla 6 è vincolante.** 78 schede personaggio e 72
conversazioni si scrivono **dopo** averti visto giocare il mondo 1. Se parlare
con Tobia non cambia la sensazione del gioco, si risolve lì — non lo si
moltiplica per ventiquattro.

### Segnaposti aperti

Ogni segnaposto introdotto va elencato qui e chiuso entro la tappa dichiarata.

- **`boot_menu.gd` · `_on_second_journey_pressed()`** — a rotta aperta il pulsante
  scrive «Rotta aperta · in arrivo» invece di caricare la modalità, che non esiste
  ancora. Scelta deliberata: meglio un messaggio onesto di un pulsante che porta a
  una scena vuota, e meglio un pulsante attivo di uno disabilitato a 24/24, che
  subito dopo la celebrazione del finale somiglierebbe a un difetto.
  **Si chiude alla tappa 9.** Oggi è raggiungibile solo con la fixture di collaudo.

## Difetto corretto dopo segnalazione (30 luglio) — argomento fuori registro

Segnalato giocando, con uno screenshot: nell'enigma di matematica del mondo 1,
esercizio 2/4, «Metti i numeri in ordine decrescente: **5, 6, 2**». Una radice
sola, quattro sintomi, tutti in `_numeric_ordering_node` — **l'unico generatore
della famiglia senza contenuto autorato**, perché matematica e logica erano le
sole due materie senza specifiche in `ORDERING`.

- **Sotto la fascia.** `count = 3 + level/6`, `span = 5 + level*2`: al livello 1
  tre interi sotto il 7, al livello 24 cinque interi sotto il 53. Per la fascia
  10–13 non è difficoltà 1: è un compito di prima elementare.
- **Fuori dalla lezione.** Dichiarava `topic: "sequenze"` per qualunque materia,
  ma i mondi di matematica dichiarano `tabelline/problemi` (1) e
  `proporzioni/frazioni/geometria` (13). Accumulava padronanza su un argomento
  che quei mondi non insegnano — e quella padronanza conta nella dimensione
  COPERTURA del gate e verso lo stato "consolidato". È il sintomo più grave.
- **Mal etichettato anche per logica**, dove `sequenze` è dichiarato (mondi 12 e
  24): il Codex la definisce «cerchi la regola che genera i termini successivi»,
  e ordinare interi estratti a caso non ha nessuna regola da trovare.
- **Invisibile agli audit.** `topics_for()` si costruisce dalle tabelle: un
  generatore procedurale non dichiarato non compare, quindi nessun controllo
  poteva vedere l'argomento emesso a runtime. `world_lesson_audit` verificava
  solo la direzione opposta (una lezione non promette argomenti inesistenti).

Correzioni:

- **matematica** resta procedurale — serve varietà infinita, i banchi piccoli sono
  già un rischio — ma gli elementi diventano **operazioni da calcolare**: ordinare
  `4 × 7`, `6 × 5`, `3 × 9` richiede davvero i prodotti. Argomento onesto:
  `tabelline` fino al 12, `frazioni` dal 13. Vincolo aggiunto: mai tutte le carte
  con lo stesso primo fattore, altrimenti si ordina guardando l'altro senza
  calcolare — la stessa famiglia di scorciatoie ripulita il 29 luglio;
- **logica** esce da `NUMERIC_ORDERING_SUBJECTS` e riceve **sei specifiche
  autorate** su `sequenze/deduzioni/analogie`, incluse una sequenza la cui regola
  alterna ×2 e −1 (i termini salgono e scendono, quindi **non si risolve
  ordinando per grandezza**) e una gerarchia di analogie;
- `NUMERIC_ORDERING_TOPICS` dichiara gli argomenti del generatore procedurale, che
  così rientra in `topics_for()` e sotto gli audit.

Guard-rail: **`minigame_topic_scope_audit.gd`**, il controllo che mancava. Per
tutte le 12 materie e tutti i 24 livelli verifica che ogni nodo dichiari un
argomento non vuoto e appartenente al registro della materia (banco + tabelle, più
i concetti del generatore per matematica), più una regressione mirata: gli
elementi dell'ordinamento di matematica non possono essere interi nudi e la
spiegazione deve mostrare il calcolo. Misura: nessun'altra materia emetteva
argomenti fuori registro — il difetto era isolato all'unico generatore non
dichiarato.

**Osservazione lasciata aperta** (decisione tua, non l'ho forzata): gli argomenti
dei minigiochi possono cadere fuori dalle `topics` della lezione del mondo anche
per le materie autorate — es. `ORDERING["scienze"]` serve `materia`, `ciclo-acqua`,
`catena`, `organizzazione`, mentre il mondo 10 dichiara `viventi/ecosistema/metodo`.
Per un evento di *pratica* è difendibile come ampliamento, ma diluisce il «ripasso
mirato» della decisione 3 del 29 luglio. Il nuovo audit **non** lo vieta.

## Difetto corretto dopo segnalazione (30 luglio) — caccia all'errore poco chiara

Segnalato giocando, **sull'esame finale di matematica**, esercizio 4/4: «Controlla
il calcolo passo per passo: quale riga sbaglia?» con righe `7 + 5` / `= 13` /
`# quanto fa davvero?`. Il difetto peggiore nel posto peggiore.

Difetto **sistemico**, non di una specifica: `_build_code_debug` creava un pulsante
numerato per **ogni** riga di `codeLines`, compresa quella che inizia con `#`. Ma
quella riga è la **consegna** (porta l'intento: «atteso: 1, 2, 3»), e il generatore
lo sa già — `_code_debug_node` la tiene in coda perché «è la consegna». Modello e
vista erano in disaccordo: chi la selezionava riceveva «Quella riga è valida: segui
i valori passo per passo», che per un commento non significa nulla. Su tre righe
mostrate, una non era nemmeno un candidato.

Aggravante nella specifica segnalata: togliendo la consegna restavano **due** righe
candidate (quasi testa o croce), e non erano passaggi — `7 + 5` e `= 13` sono i due
pezzi di **una sola uguaglianza**, quindi «quale riga sbaglia» era ambiguo: l'errore
stava nella relazione fra le due, non dentro una delle due.

Correzioni:

- **la consegna diventa una nota in grigio**, leggibile e non selezionabile, e la
  numerazione delle righe candidate resta contigua (`answerLine` non cambia
  significato). L'istruzione non dice più «Il numero di riga è parte dell'indizio»,
  che era opaca, ma «Tocca la riga sbagliata. Le righe numerate sono i passaggi;
  in grigio la consegna»;
- **sei specifiche riscritte** con almeno tre righe candidate e passaggi veri
  (censimento sotto): due di matematica, quattro di coding;
- **contratto rafforzato** in `ExerciseInteraction._validate_code_debug`:
  `answerLine` non può puntare a una consegna — prima un nodo poteva dichiarare
  come soluzione una riga che il giocatore non può nemmeno scegliere, prova
  impossibile che nessun audit vedeva.

Guard-rail: **`code_debug_clarity_audit.gd`**. Censimento su tutte le materie:
`answerLine` mai su una consegna, almeno 3 righe candidate, massimo una consegna e
sempre in ultima posizione, e — solo dove l'ordine è fisso — la posizione
dell'errore che varia.

Due cose imparate, che valgono oltre questo difetto:

- **il mio primo audit ha prodotto un falso positivo** e l'ho scoperto prima di
  riportarlo: segnalava «l'errore è sempre alla riga 3» per scienze, geografia,
  storia, musica e latino. Ma quelle specifiche hanno `shuffleLines: true`: il
  runtime rimescola il corpo e ricalcola `answerLine`, quindi la posizione autorata
  è irrilevante. La regola ora si applica solo alle specifiche a ordine fisso.
  Morale: un audit che non conosce le trasformazioni a runtime misura il dato
  sbagliato;
- **gli audit che falliscono con `assert` si appendono** e perdono lo stdout
  bufferizzato — cioè l'output proprio quando serve. `code_debug_clarity_audit`
  stampa l'elenco completo dei problemi e poi esce con `quit(1)`: il runner lo
  considera rosso comunque (controlla anche l'exit code), non spreca il timeout di
  240 s e si legge. Modello preferibile per i prossimi audit.

## Difetti corretti dopo segnalazione (29 luglio)

Un ordinamento dell'esame di matematica è arrivato **già risolto**: gli elementi
erano presentati nell'ordine giusto e bastava premerli in fila. Cercandone altri
della stessa famiglia — la presentazione che regala la risposta — ne sono emersi
tre, tutti misurati sull'esperienza giocata:

- **ordinamenti già risolti**: 355 su 7.532 (4,7%), esami compresi. Ora il
  rimescolamento non può restituire la soluzione e il contratto
  (`ExerciseInteraction.validate`) rifiuta un ordinamento presentato ordinato;
- **caccia all'errore prevedibile**: la riga sbagliata era la terza nel 56% dei
  casi e in sei materie *sempre* la terza. Dove le righe sono affermazioni
  indipendenti ora vengono rimescolate a ogni partita (con la spiegazione
  rinumerata); dove l'ordine è il ragionamento — codice, passaggi di un calcolo,
  premesse di un sillogismo — sono stati autorati sei spec con l'errore in
  posizioni diverse;
- **posizione della risposta nei banchi piccoli**: logica al 45% in terza
  posizione, scienze al 42% in seconda. Al bake la posizione ora ruota per
  materia: tutte tra il 23% e il 28%.

Guard-rail: `giveaway_audit.gd`. La colonna destra degli abbinamenti non può più
risultare allineata alla sinistra (si risolveva riga per riga).

## Ottimizzazione asset tablet

- export Web ridotto da **68,79 MiB** a **61,86 MiB**: `index.pck` da 30,79 a
  23,85 MiB, −6,93 MiB complessivi (circa −10%);
- landmark 1254–1536 px importati con limite 512 px, adeguato alla resa massima
  di circa 260 px; sorgenti originali conservati;
- atlanti naturali importati a 1024 px con crop calcolato dalla dimensione
  effettiva, non da coordinate rigide;
- tavole identitarie, landmark, atlanti di bioma ed enigmi caricati soltanto per
  il mondo/tema corrente e riusati tramite cache condivise;
- cache PWA aggiornata a `v9-web-loader`; il launcher confronta il build ID,
  attende l'attivazione del nuovo service worker e poi apre Godot, così il
  tablet non riceve il vecchio PCK al primo accesso dopo una pubblicazione;
- compressione selettiva Brotli/Gzip per WASM e JavaScript nei server Vite
  sviluppo/anteprima: il WASM trasferito scende da 37,68 a circa 7,92 MiB con
  Brotli; il PCK resta non ricompresso perché il guadagno è marginale;
- `npm run audit:web` verifica build ID, versione cache e dimensioni PCK/WASM
  prima di ogni build;
- verifica: export Godot riuscito, 184/184 test TypeScript verdi, audit diretti
  dei mondi 21–23 e del mondo/finale 24 verdi. Lo smoke Chrome automatizzato è
  attualmente bloccato dal canale DevTools locale prima della navigazione e va
  ripetuto sul dispositivo fisico.

## Rischi noti

- **L'export in `public/godot/outdoor/` invecchia più in fretta dei contenuti.**
  Dopo ogni cambio di banchi, selezione o formati va rigenerato il PCK, altrimenti
  lo smoke in browser verifica l'esperienza precedente.
- **Banchi piccoli in cinque materie** (musica 29 item, storia 30, scienze e
  logica 38, coding 42): la varietà giocata regge perché la maggior parte dei nodi
  viene dai minigiochi, ma alla seconda o terza rigiocata di un mondo la
  ripetizione si farà sentire.
- **Nessuna prova con bambini o docenti.** Tutte le misure sono strutturali:
  dicono che l'esperienza è varia, progressiva e onesta, non che è piacevole.
- **Il mondo 1 è già il più stretto su entrambi i budget**, ed è esattamente quello
  a cui sto per aggiungere abitanti ed edifici: **2667/3500 nodi** e **468/500 ms**
  di istanziazione (misurato il 30 luglio, `performance_budget_audit`). Restano
  circa 830 nodi e 32 ms di margine per 2 residenti, 1 Bislacco e 3 edifici. Le
  tappe 3–6 devono contare i nodi, non aggiungerli e vedere che succede.
- **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
  di margine. Nella suite intera sotto contesa ha dato 598 ms (rosso), da solo
  468 ms (verde). Il runner è sequenziale, quindi la contesa è esterna
  (probabilmente l'antivirus sul PCK appena esportato). Un rosso di questo audit
  va **sempre riverificato in isolamento** prima di trattarlo come regressione.
- **Nessuna revisione incrociata del codice** finché Codex è fermo. Mitigazioni
  negli *Invarianti di architettura*; la più forte sei tu che giochi ogni tappa.
- **Io non vedo il gioco.** Ogni giudizio estetico e di ritmo passa da te: se una
  tappa ti sembra brutta e non me lo dici, resta brutta e ci costruisco sopra.
- **C-16 passo 3 (rimozione di Phaser) resta sospeso.** La scena menu nativa che
  era il prerequisito ora esiste (`boot_menu.tscn` è la main scene) e `index.html`
  reindirizza già all'export Godot: manca la rimozione guidata da
  `docs/PHASER_GODOT_MIGRATION_MATRIX.md`. **Non lo tocco durante il mondo
  abitato**: è un lavoro di pulizia che va fatto quando nient'altro è in volo,
  altrimenti una regressione qui somiglierà a un bug degli abitanti.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
