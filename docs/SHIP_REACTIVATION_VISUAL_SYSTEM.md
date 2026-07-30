# Riattivazione visiva della nave

La nave traduce la progressione didattica persistita in un cambiamento visivo
continuo. Energia e cosmetici non alimentano i ponti: ogni nodo si completa
soltanto superando l'esame finale del livello associato.

## Materie, apparati e ponti

| Ponte | Materie che lo alimentano | Nodi sui 24 livelli |
|---|---|---:|
| Ponte Centrale | matematica, coding, logica | 6 |
| Bio-ponte | scienze | 2 |
| Reattore | elettronica | 2 |
| Ponte di Comando | fisica, geografia | 4 |
| Motore a Risonanza | musica | 2 |
| Data-core | italiano, inglese, storia | 6 |
| Sala dei Glifi | latino | 2 |

La tabella è derivata dalla stessa `ApparatusConfig` che governa i gate, quindi
interfaccia e progressione non mantengono due conteggi indipendenti.

## Cinque fasi leggibili

1. **Sistema inerte** — ambiente freddo, desaturato, rete quasi spenta.
2. **Riaccensione** — primo segnale, circuiti e nucleo iniziano a pulsare.
3. **Rete parziale** — più nodi trasmettono energia e ritorna il colore.
4. **Sincronizzato** — luce stabile, impulsi più frequenti e apparato attivo.
5. **Piena potenza** — tutti i nodi del ponte completati, resa luminosa piena.

Missioni e padronanza producono un'anteprima parziale fino all'85% del nodo
corrente. L'ultimo impulso è riservato all'esame: al superamento, flash, scintille,
onda radiale, suono e pannello traguardo rendono evidente la riattivazione.

La regia del traguardo usa tre tempi causali:

1. **Messa a fuoco** — barre cinematografiche, lieve avvicinamento allo scenario
   e terminale in primo piano preparano l'accensione.
2. **Accensione** — il terminale reagisce per primo; rete, flash e firma sonora
   `circuit.on` propagano l'energia al ponte.
3. **Rivelazione** — il pannello nomina fase, potenza e nodo appena completato,
   poi camera simulata e interfaccia tornano allo stato di gioco.

Al livello 24 non viene aperto un secondo popup: lo stesso movimento diventa la
convergenza dei dodici sistemi, cambia in **ROTTA APERTA**, porta NORA al beat
conclusivo e chiude con stinger di completamento e apertura del portale.

La rail laterale espone percentuale e simbolo di fase per tutti i sette ponti;
il pannello corrente mostra potenza, segmenti completati e totale nodi. Dopo il
livello 24 la campagna entra nello stato conclusivo e nessun gate può ripetersi.

## Implementazione e verifiche

- `ship_activation_model.gd`: modello deterministico derivato dal save.
- `ship_power_overlay.gd`: rete energetica, impulsi, nucleo e burst code-native.
- `hub_scene.gd`: shader multi-fase, HUD e sequenza celebrativa.
- `ship_activation_audit.gd`: 24 gate, 7 ponti e monotonia delle cinque fasi.
- `ship_reactivation_sequence_audit.gd`: esame → focus → accensione → reveal →
  ripristino di camera e overlay.
- `ship_presentation_audit.gd`: asset, rete e indicatori presenti nel viewport.

Le catture di riferimento sono in `artifacts/ship/`: stato inerte, riattivazione
intermedia, regia d'accensione, piena potenza e finale **Rotta aperta**.
