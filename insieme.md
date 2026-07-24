# Eli Quest — Piano operativo condiviso

Aggiornato al 24 luglio 2026.

Questo file contiene soltanto lavoro aperto o decisioni ancora da prendere.
Il lavoro operativo parte dal pass C-P6.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)
- [Specifica del finale](docs/FINALE_SPEC.md)

## Obiettivo

Portare il percorso Godot completo alla qualità di consegna: apprendimento,
missioni, mondi, NORA e riattivazione della nave devono restare un unico ciclo
leggibile, accessibile, performante e pubblicabile su desktop, tablet e Web.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance, regressioni ed export.

### C-P6 — Pass AAA e consegna

Il playthrough integrato è verde su desktop e viewport tablet: boot → mondo →
missione touch → nave → esame → mondo successivo. Sono verdi anche progressione
naturale 1→24, finale trasversale e rivisitazione del mondo 24. Opus può quindi
procedere con la revisione didattica finale senza attendere altri gate.

Procedere in quest’ordine:

1. [ ] Rifinire regia, camera, animazioni, transizioni e sound design dei
   traguardi, con priorità a riattivazioni della nave e finale.
2. [ ] Verificare coerenza di art direction tra Eli, 24 mondi, nave, NORA e UI;
   correggere soltanto incoerenze visibili nelle capture o nel playthrough.
3. [ ] Comprimere audio e texture senza perdita percettibile e misurare peso
   finale del download.
4. [ ] Profilare FPS, memoria, caricamenti, streaming e draw call su desktop,
   Web e hardware scolastico/tablet reale.
5. [ ] Completare test di input touch, aspect ratio, leggibilità, contrasto,
   riduzione movimento e accessibilità.
6. [ ] Produrre export Web riproducibile ed eseguire smoke test della build
   pubblicabile.
7. [ ] Eseguire la suite finale completa, aggiornare i documenti di consegna e
   creare il commit/release candidate.

Definizione di completato C-P6:

- nessuna interazione essenziale dipende dalla tastiera;
- percorso 1→24 e post-finale completabili senza injection o reset;
- nessun audit rosso;
- nessun errore Godot bloccante o perdita di stato;
- UI leggibile alle viewport target;
- budget misurati su dispositivi target;
- export Web avviabile e navigabile;
- artefatti e documentazione di consegna aggiornati.

## Compiti Opus

Opus è responsabile di contenuti, coerenza didattica, difficoltà, copertura delle
competenze e validazione del percorso educativo.

> **Gate E2 · finale verificato.** Il mondo 24 e il finale trasversale funzionano
> come un solo flusso: prova dei 12 sistemi + sintesi → Cuore a 5 fasi →
> riattivazione completa della nave (`is_complete`, integrità NORA 1.0, memoria 24)
> → beat finale NORA → ritorno giocabile. Verdi: `world_wave_e2_audit`,
> `finale_transversal_audit`, `nora_arc_audit`, e l'intero percorso
> (`world_semantics_audit`, `world_lesson_audit`, `progression_1to24_audit`).
> Nessuna correzione richiesta. La revisione didattica del punto 1 qui sotto è la
> ripassata **dopo** il playthrough manuale C-P6.

1. [ ] Rieseguire la revisione didattica finale sui 24 mondi e sul finale
   trasversale dopo il playthrough C-P6; segnalare soltanto problemi che cambiano
   comprensione, trasferimento, difficoltà o relazione con NORA.
2. [~] Validare la distribuzione reale dei formati di esercizio e proporre
   correzioni dove la scelta multipla resta dominante nell’esperienza giocata.
   > **Italiano (24 lug):** era il caso peggiore (banco 100% scelta multipla di
   > vocabolario). Approfondito con 21 gruppi interattivi su 5 formati —
   > abbina (sinonimi, definizioni, modi di dire, figure retoriche), ordina
   > (costruzione frase, sequenza narrativa), classifica (tempi verbali,
   > concreto/astratto), **grafico "arco narrativo"** (curva della tensione:
   > esposizione→climax→scioglimento) e **"caccia all'errore"** (code_debug
   > riusato: individua la frase con l'errore di ortografia/accordo/tempo). Il
   > nodo specialista ora ruota, così le missioni alternano arco e caccia.
   > Meccaniche nuove, zero asset immagine (resa procedurale). Prossime materie
   > da approfondire con lo stesso metodo su richiesta.
3. [x] Matrice livello → competenze → evidenze → apparato consegnata e GENERATA
   dai contratti in [docs/COMPETENCY_MATRIX.md](docs/COMPETENCY_MATRIX.md)
   (`competency_matrix.gd`, nessun drift), utilizzabile da docenti e pilota.
4. [ ] Aggiornare fixture e consumer insieme soltanto se una revisione cambia un
   contratto `WorldLessonCatalog` o `ContentManager`.

## Rilievi del playthrough C-P6

I 13 rilievi divisi per competenza. Dettaglio e motivazioni in
[docs/PLAYTHROUGH_TRIAGE.md](docs/PLAYTHROUGH_TRIAGE.md).

### Rilievi → Codex (resa, runtime, meccaniche)

- [ ] **#1** Rimuovere gli elementi grafici fuori contesto che distraggono.
- [ ] **#5** Dare funzione o rimuovere elementi che sembrano importanti ma inutili
  (albero dei percorsi, nucleo antico…).
- [ ] **#12** Integrare gli elementi sopra la mappa, coerenti con mappa e livello.
- [ ] **#3** Sfera/incontro completato: sparisce anche graficamente (il dato è già
  persistito, `completedEncounterIds`/`worldProgress`; manca solo la resa).
- [ ] **#8** Sprite del personaggio di qualità AAA (movimento e combattimento).
- [ ] **#2** Fiumi con sorgente/cascata coerenti, attraversabili solo con ponti da
  costruire (il "ponte via esercizio" ha già il contratto `build_enigma`). *(con Design)*
- [ ] **#6** Equipaggiamento realmente utile: torcia con notte molto più buia,
  falce per l'erba alta invalicabile; situazioni che rendono l'equipaggiamento
  indispensabile per certe sfere/tesori. *(meccanica nuova, con Design)*
  > **Opus → Codex (24 lug):** il WIP "13 punti half" ha già acceso il gate
  > (`_equipment_requirement_met` su tesori/incontri/minigiochi in
  > `outdoor_world.gd:1967`, tool `tool-torch`/falce). Ma `roundtrip_audit.gd:45`
  > è ora **rosso**: pesca il primo tesoro e lo raccoglie senza equipaggiare
  > nulla; se quel tesoro è gated l'early-return blocca la raccolta e l'assert
  > `collectedTreasureIds.has(id)` fallisce. Da sistemare **lato Codex**: o
  > l'audit equipaggia il tool prima di raccogliere un tesoro gated, o sceglie un
  > tesoro senza `requiredTool`. Nessun altro audit Opus tocca i tesori. Il resto
  > della suite di contenuti (#11) resta verde.
- [ ] **#7** Nemici per livello che ostacolano la missione. *(meccanica nuova, con Design)*
- [ ] **#9** Enigmi: feedback negativo visibile e **cooldown fra i tentativi**
  sull'errore (l'esito no-ricompensa e il costo-energia esistono già lato Opus;
  qui serve la UI del cooldown/feedback). Il cooldown è **tra** i tentativi, non
  un timer durante l'esercizio.
- [ ] **#11** Feel & juice dei renderer non-MC (snap, luce, suono, board che si
  anima) tematizzati per materia; **asset immagine** per hotspot/grafico/circuito
  (mappa, corpo/cellula, pentagramma, schema); attivare `build_varied_mission`
  come default del percorso live. Guida completa in
  [docs/MINIGAMES_DESIGN.md](docs/MINIGAMES_DESIGN.md). *(insieme a Opus)*
- [ ] **#13** UI **atlante consultabile** e aggancio nel flusso dei momenti
  d'insegnamento di NORA (`KnowledgeCodex.mini_lesson`/`teaching_moment` pronti). *(insieme a Opus)*

### Rilievi → Opus (contenuti, didattica)

- [x] **#4** Risposta corretta non sempre prima — **verificato pulito**: banchi
  uniformi (25,6% in prima posizione) e matematica mescolata (Fisher-Yates).
- [x] **#13** *(lato contenuti)* `KnowledgeCodex` ora **insegna**: `mini_lesson`
  (unità istruttiva per 122 topic) + `teaching_moment` (NORA pre-insegna al primo
  incontro, ri-insegna sull'errore). `codex_teaching_audit` verde. Resta il wiring
  UI a Codex.
- [x] **#11** *(lato Opus, autonomo)* Design + handoff grafico in
  [docs/MINIGAMES_DESIGN.md](docs/MINIGAMES_DESIGN.md). Le missioni live usano
  GIÀ `build_varied_mission` (≤⅓ scelta multipla). **Sei formati interattivi**
  live e play-testati (c01 li gioca dal player reale): abbina, ordina,
  classifica, **grafico, circuito, code-debug** — tutti **senza asset immagine**
  (resa procedurale di `exercise_diagram`). Varietà ampliata (2° gruppo
  classificazione per i primi mondi). Resta a **Codex**: juice/feel dei renderer
  e (opzionale) immagini reali per hotspot.
- [x] **#10** Taratura difficoltà per livello — diagnosi (`difficulty_calibration_audit`)
  e fix: l'unica materia tappata (italiano ≤d2) è stata arricchita con 36 voci
  avanzate (lessico astratto/figurato, mondo 14) → ora **tutte le 12 materie
  salgono fino a d4**. Distrattori più fini è polish incrementale futuro.

## Gate Codex ↔ Opus

Il release candidate si chiude soltanto quando runtime, contenuti, input touch,
accessibilità, performance ed export sono verdi insieme.

Vincoli di responsabilità:

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso commit.
- Nessuna correzione di polish deve indebolire il significato didattico della
  trasformazione del mondo o della riattivazione della nave.

## Decisioni ancora da prendere

- [ ] Decidere come scala la difficoltà nelle rivisitazioni dopo il
  completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤ 33%.
- [ ] Definire quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Fissare budget misurabili per FPS, memoria, download e caricamento sui
  dispositivi scolastici target.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
