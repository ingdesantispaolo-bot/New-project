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

### C-P6 — Verifiche manuali e consegna

Procedere in quest’ordine:

1. [ ] Eseguire un playthrough manuale mirato dei mondi acquatici e dei mondi
   1, 7, 13, 19 e 24: verificare ponte-enigma, torcia/falce, densità e
   aggressività delle anomalie, ritorno alla nave e assenza di soft-lock.
2. [ ] Catturare Eli fermo/in movimento/in impulso su desktop e tablet; decidere
   severamente se il foglio a 20 frame regge l’art direction finale o richiede
   un nuovo asset. Verificare anche silhouette dei quattro tier di anomalie.
3. [ ] Verificare nelle capture che la compressione lossy delle 44 tavole mondo
   non produca banding, aloni o perdita percettibile su testo e landmark.
4. [ ] Rifinire feel e juice dei renderer non-MC: snap, luce, suono, feedback
   causale e board tematizzata per materia. Valutare asset immagine soltanto per
   hotspot/grafico/circuito dove migliorano davvero la comprensione.
5. [ ] Rifinire regia, camera, animazioni, transizioni e sound design dei
   traguardi, con priorità a riattivazioni della nave e finale.
6. [ ] Verificare coerenza di art direction tra Eli, 24 mondi, nave, NORA e UI;
   correggere soltanto incoerenze osservabili nelle capture o nel playthrough.
7. [ ] Profilare FPS, memoria, caricamenti e draw call nel browser e su hardware
   scolastico/tablet reale; fissare i budget definitivi partendo dalla baseline
   headless in `docs/RELEASE_CANDIDATE.md`.
8. [ ] Provare su tablet reale tutti i comandi touch, viewport landscape e
   portrait, leggibilità, contrasto elevato e riduzione movimento.
9. [ ] Eseguire smoke test in un browser reale dell’export Web da 67,62 MiB:
   boot, missione touch, nave, esame, ritorno al mondo successivo, audio e save.
10. [ ] Correggere soltanto i difetti osservati nelle verifiche 1–9, rieseguire
    la suite e approvare il commit come release candidate pubblicabile.

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
