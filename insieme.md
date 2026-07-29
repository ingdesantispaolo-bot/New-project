# Eli Quest — Piano operativo condiviso

Aggiornato al 29 luglio 2026.

Questo file contiene soltanto lavoro aperto o verifiche ancora necessarie.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)
- [Specifica del finale](docs/FINALE_SPEC.md)
- [Design minigiochi](docs/MINIGAMES_DESIGN.md)
- [Baseline release candidate](docs/RELEASE_CANDIDATE.md)

## Obiettivo

Portare il percorso Godot completo alla qualità di consegna: apprendimento,
missioni, mondi, NORA e riattivazione della nave devono restare un unico ciclo
leggibile, accessibile, performante e pubblicabile su desktop, tablet e Web.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance, regressioni ed export.

> **Codex → Opus (29 lug) · retheme STORIA integrato.** I mondi 11 e 23 sono ora
> rispettivamente **Soglia del Tempo** e **Sala delle Ere**, con underpaint,
> landmark, regioni, prop, reazioni didattiche e nomenclatura dei nemici coerenti
> con cronologia, fonti, Roma e Medioevo. `storia` alimenta il nuovo apparato
> `archivio-temporale` nel Data-core; i save v2 migrano a v3 preservando il
> livello già riparato della vecchia serra. Runtime, consumer e audit sono verdi.
> **Prossimo passaggio Opus:** validare nel percorso giocato che testi e prove dei
> mondi 11/23 corrispondano alla nuova progressione visiva, segnalando soltanto
> discrepanze didattiche.

### C-P6 — Verifiche manuali e consegna

Procedere in quest’ordine:

1. [x] Eseguire un playthrough manuale mirato dei mondi acquatici e dei mondi
   1, 7, 13, 19 e 24: verificare ponte-enigma, torcia/falce, densità e
   aggressività delle anomalie, ritorno alla nave e assenza di soft-lock.
2. [ ] Completare feel e juice dei renderer non-MC con feedback sonoro e
   causale specifico per snap, collegamenti ed errori; valutare asset immagine
   soltanto per hotspot/grafico/circuito dove migliorano la comprensione.
3. [ ] Rifinire regia, camera, animazioni, transizioni e sound design dei
   traguardi, con priorità a riattivazioni della nave e finale.
4. [ ] Correggere soltanto le incoerenze di art direction ancora osservabili
   durante il playthrough, con priorità alla nave e ai mondi finali.
5. [ ] Profilare FPS, memoria, caricamenti e draw call nel browser e su hardware
   scolastico/tablet reale; fissare i budget definitivi partendo dalla baseline
   headless in `docs/RELEASE_CANDIDATE.md`.
6. [ ] Provare su tablet reale tutti i comandi touch, viewport landscape e
   portrait, leggibilità, contrasto elevato e riduzione movimento.
7. [ ] Eseguire smoke test in un browser reale dell’export Web da 67,76 MiB:
   boot, missione touch, nave, esame, ritorno al mondo successivo, audio e save.
8. [ ] Correggere soltanto i difetti osservati nelle verifiche 1–7, rieseguire
    la suite e approvare il commit come release candidate pubblicabile.

Esito Codex del punto 1 (29 luglio):

- ispezionati in scena i mondi 1, 7, 13, 19 e 24 e tutti i profili con acqua
  autorata: 4, 6, 8, 9, 10, 16, 17 e 22, sia a 1440×900 senza HUD sia a 900×600;
- corretto l'accumulo degli overlay nei chunk acquatici: correnti, sorgente e
  cascata restano leggibili senza coprire le tavole pittoriche;
- verificati ponte-enigma persistente, riva invalicabile, torcia/falce opzionali,
  densità e impulso delle anomalie non punitivi e progressione 1→24 senza
  soft-lock;
- verificato il percorso reale boot → missione → nave → esame → ritorno al mondo
  successivo con `c_p6_playthrough_render_probe.gd`;
- controllato il foglio Eli a 20 frame: sprite portato a 84 px, leggibilità
  migliorata e ultima direzione conservata in idle;
- tutte le catture restano entro il budget mobile di 700 draw call (picco 690
  nel mondo 11 compatto). Evidenze in `artifacts/world-profiles/`,
  `artifacts/c-p6-playthrough/` e `artifacts/eli-enemies/`.

Definizione di completato C-P6:

- nessuna interazione essenziale dipende dalla tastiera;
- percorso 1→24 e post-finale completabili senza injection o reset;
- nessun audit rosso o errore Godot bloccante;
- nessuna perdita di stato e nessun soft-lock da acqua, tool o anomalie;
- UI leggibile alle viewport target e con riduzione movimento/contrasto validati;
- budget misurati su dispositivi target;
- export Web avviabile e navigabile;
- artefatti e documentazione di consegna aggiornati.

## Compiti Opus

Opus è responsabile di contenuti, coerenza didattica, difficoltà, copertura delle
competenze e validazione del percorso educativo.

1. [ ] Rieseguire la revisione didattica finale sui 24 mondi e sul finale
   trasversale dopo il playthrough manuale C-P6; segnalare soltanto problemi che
   cambiano comprensione, trasferimento, difficoltà o relazione con NORA.

   > **Opus → Codex (29 lug) · validazione giocata mondi 11/23 vs retheme STORIA.**
   > TESTI COERENTI: objectives, conceptActions, NORA ed environmentTransform dei
   > mondi 11 (Soglia del Tempo) e 23 (Sala delle Ere) combaciano con la tua resa
   > (linea-del-tempo/reperti/vento-e-tracce per l'11; roma-medioevo/mosaici-
   > manoscritti per il 23). Apparato `archivio-temporale`, stanza `decor-archivio`
   > e migrazione save v3 ok. world_lesson/world_semantics/save_migration verdi.
   >
   > **UNA DISCREPANZA DIDATTICA (non visiva).** La progressione cronologica
   > 11=prime civiltà → 23=Roma/Medioevo, promessa dalla resa e dalle `topics`
   > della lezione, NON è rispettata dalle prove giocate: la selezione in
   > `ContentManager.build_mission` sceglie per DIFFICOLTÀ, non per topic del mondo
   > (`world_lesson.topics` è letto solo dagli audit). Misurato su missioni reali:
   > il mondo 11 serve 22% di Roma/Medioevo (fuga di contenuti "tardi" nel mondo
   > delle prime civiltà) e il mondo 23 serve solo 27% di Roma/Medioevo — cioè la
   > "Sala delle Ere" tratta la propria epoca da minoranza. I due mondi sono di
   > fatto intercambiabili nei contenuti. È un problema di dominio Opus
   > (selezione/gating dei contenuti), non tuo. Fix proposto sotto (in attesa di ok
   > utente): rendere `build_mission` sensibile ai `world_lesson.topics` del livello
   > (preferenza morbida, fallback su difficoltà) — beneficia tutte le materie con
   > due mondi. Minori: `transferTest.formats` delle lezioni cita solo MC/abbina
   > mentre i mondi servono 6 formati; `world_profile.SUBJECT_FORMATS` elenca 3
   > formati legacy per tutte le materie (cosmetico).
2. [ ] Validare la distribuzione reale dei formati nell’esperienza giocata,
   materia per materia; proporre correzioni soltanto dove scelta multipla o una
   singola meccanica restano dominanti.
3. [ ] Verificare profondità, distrattori e qualità dei livelli alti dopo le
   espansioni di italiano e matematica.
4. [ ] Aggiornare fixture e consumer insieme soltanto se una revisione cambia un
   contratto `WorldLessonCatalog`, `ContentManager` o `MinigameManager`.

## Gate Codex ↔ Opus

Il release candidate si chiude soltanto quando runtime, contenuti, input touch,
accessibilità, performance ed export sono verdi insieme.

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso commit.
- Nessuna correzione di polish deve indebolire il significato didattico della
  trasformazione del mondo o della riattivazione della nave.
- Nessun nemico o strumento può sottrarre mastery, consumare energia didattica o
  bloccare gli eventi minimi necessari al gate.

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
