# Eli Quest — Piano operativo condiviso

Aggiornato al 24 luglio 2026.

Questo file contiene soltanto lavoro aperto o decisioni ancora da prendere.
L’ordine P5 → P6 è vincolante.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)

## Obiettivo

Completare un gioco Godot in cui apprendimento, missioni, mondi, NORA e
riattivazione della nave costituiscono un unico ciclo. Ogni livello apre un
mondo distinto; le prove esterne preparano l’esame nella nave; gli esiti
didattici trasformano visivamente mondo e nave.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance ed export.

### C-P5 — Strategia per completare i mondi 17–24

Restano due ondate da quattro mondi. Una nuova ondata parte soltanto dopo audit,
render, correzione visiva e revisione semantica della precedente.

#### Gate D1 — revisione Opus prima dell’Ondata D2

- [ ] **Opus:** verificare trasferimento, testi NORA e coerenza disciplinare dei
  mondi 13–16; confermare che orbite, prospettive narrative, reti/debug e
  scambi linguistici rappresentino i rispettivi contratti didattici.
- [ ] **Codex:** applicare eventuali correzioni semantiche richieste da Opus
  senza indebolire leggibilità notturna, input touch o budget prestazionale.

#### Ondata D2 — Mondi 17–20

È l’ondata tecnicamente più rischiosa per acqua profonda, grandi interni,
penombra ed effetti atmosferici. Va affrontata soltanto dopo D1.

- [ ] **17 · Oceano delle Forze** — correnti, piattaforme e abissi con
  Cattedrale Sottomarina; l’equilibrio stabilizza una corrente e apre un varco.
- [ ] **18 · Cattedrale del Suono** — navate, archi e Grande Organo; le canne si
  accendono per gruppi e la luce delle vetrate reagisce all’armonia.
- [ ] **19 · Necropoli delle Radici** — cripte, epigrafi astratte e Albero delle
  Radici; ogni relazione etimologica illumina una cripta ed estende un ramo.
- [ ] **20 · Tempesta Elettromagnetica** — torri, sensori e campi instabili; le
  diagnosi corrette stabilizzano una torre e dissipano una zona di tempesta.
- [ ] Creare asset, kit, reazioni, `world_wave_d2_audit.gd` e cinque capture per
  mondo; rieseguire le regressioni A–D2.
- [ ] Gate D2: particelle, acqua e lampi devono restare sotto budget anche su
  mobile; nessun effetto può nascondere POI o ingresso nave.

#### Ondata E — Mondi 21–24 e finale

- [ ] **21 · Atlante Fratturato** — placche e biomi separati da faglie,
  Pilastro Tettonico; le faglie si ricompongono e stabilizzano i biomi.
- [ ] **22 · Biosfera Profonda** — caverne vive e catena energetica, Nucleo
  Vivente; la bioluminescenza si propaga lungo il flusso dell’energia.
- [ ] **23 · Concilio delle Colonie** — moduli orbitali, cupole e assemblee,
  Sala del Concilio; gli accordi illuminano una cupola e rendono disponibile una
  risorsa condivisa.
- [ ] **24 · Cuore dei Primi** — dodici settori riconoscibili che convergono nel
  Cuore; ogni prova finale accende un sistema e la conclusione apre la rotta.
- [ ] Creare asset, kit, reazioni, `world_wave_e_audit.gd` e cinque capture per
  mondo; rieseguire l’intera progressione 1→24.
- [ ] Gate E1: i mondi 21–23 devono essere completi prima di iniziare il finale.
- [ ] Gate E2 speciale mondo 24: convergenza dei dodici sistemi, beat conclusivo
  NORA, riattivazione completa della nave e ritorno al mondo devono formare una
  sola sequenza verificabile e non una serie di menu scollegati.

#### Procedura obbligatoria di ogni ondata

1. Congelare nomi, palette, topologia, landmark e trasformazione didattica.
2. Implementare composizione, corridoio nave, regioni e prop prima degli asset
   finali.
3. Creare underpaint e landmark; verificare trasparenza, scala e assenza di
   testo spurio.
4. Collegare palette, meteo, soundscape e reazione ambientale a cinque stadi.
5. Controllare interazione touch: tap sul POI, avvicinamento automatico e
   pulsante contestuale, senza dipendenza da `E`.
6. Eseguire audit semantico, audit di scena e regressioni delle ondate concluse.
7. Renderizzare desktop e tablet, ispezionare le immagini e fare almeno un
   passaggio correttivo su leggibilità, densità e coerenza.
8. Verificare HLOD, streaming, draw call e assenza di sovrapposizioni tra nave,
   landmark, acqua, muri e missioni.
9. Aggiornare questo file eliminando l’ondata conclusa e creare un commit
   autonomo prima di iniziare la successiva.

Definizione di completato per un mondo:

- topologia e silhouette riconoscibili senza leggere il titolo;
- landmark dominante e ingresso nave chiaramente individuabile;
- almeno tre famiglie di prop coerenti e nessun clutter legacy incongruo;
- trasformazione didattica visibile in cinque passi e persistente nel save;
- POI leggibili in ogni fase di luce e su viewport tablet;
- audit verdi e cinque capture approvate;
- budget Web e mobile rispettati.

### C-P6 — Pass AAA e consegna

- [ ] Riallineare `enigma_scene_audit.gd` al runtime per profili: non deve
  presumere dodici enigmi caricati nella stessa scena e deve verificare tap,
  avvicinamento e pulsante contestuale oltre alla tastiera.
- [ ] Regia, camera, animazioni, transizioni e sound design dei traguardi.
- [ ] Coerenza di art direction tra Eli, mondi, nave, NORA e UI.
- [ ] Compressione audio e texture senza perdita percettibile.
- [ ] Profili prestazionali per desktop, mobile e hardware scolastico.
- [ ] Test input, aspect ratio, leggibilità e accessibilità.
- [ ] Export Web riproducibile con smoke test della build pubblicabile.

## Compiti Opus

I contenuti base 9–24 sono già disponibili. Opus esegue un controllo mirato alla
fine di ogni ondata, senza modificare posizionamento o resa visuale.

> **Pronto per Codex.** Il lato CONTENUTI di ogni ondata è già pre-verificato:
> `world_semantics_audit` (trasformazioni non decorative e distinte, trigger di
> apprendimento, trasferimento con novità segnalata, NORA distinti, finale
> trasversale), `world_lesson_audit` (24 mondi) e `mission_event_director_audit`
> (raggiungibilità/non-blocco) sono **verdi**. Alla chiusura di ogni ondata basta
> rieseguirli sui mondi consegnati: il controllo semantico Opus si riduce a
> confermare che la resa di Codex rispetti questi contratti già validati.

- [ ] dopo D2, verificare che le trasformazioni 17–20 comunichino davvero il
  concetto appreso e non siano soltanto effetti decorativi;
- [ ] prima del Gate E2, validare prova trasversale, beat conclusivo NORA e
  semantica della convergenza dei dodici sistemi;
- [ ] aggiornare fixture e consumer insieme soltanto se una revisione cambia un
  contratto `WorldLessonCatalog`.

## Gate Codex ↔ Opus

Ogni ondata si chiude soltanto quando mondo visuale, contratto didattico,
trasformazione ambientale, input touch, capture e budget prestazionale sono
verdi insieme e Opus ha completato il controllo semantico previsto. Nessuna
ondata successiva parte con audit rossi.

Vincoli di responsabilità:

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso gate.

## Decisioni ancora da prendere

- [ ] Congelare nomi e temi dell’ondata corrente prima di produrre gli asset.
- [ ] Decidere quali mondi restano liberamente rivisitabili e come scala la
  difficoltà dopo il completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤ 33%.
- [ ] Definire quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Approvare struttura del finale trasversale prima del Gate E2.
- [ ] Fissare budget misurabili per FPS, memoria, download e caricamento sui
  dispositivi scolastici target.
- [ ] Stabilire prima di ogni ondata quali elementi richiedono asset originali
  e quali possono riusare componenti modulari senza perdere identità.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna produzione contemporanea di tutti i 24 mondi.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
