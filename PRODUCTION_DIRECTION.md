# Direzione production-ready (superato)

Questo documento descriveva un piano "prototipo Phaser prima, Godot poi" che
non riflette più la direzione del progetto. Il 2026-07-20 la direzione è
cambiata: **Godot è l'unico runtime di produzione**, non un'opzione futura.

La documentazione autoritativa e aggiornata è:

- `docs/ARCHITETTURA_FULL_GODOT.md` — architettura target, piano a fasi con
  criteri d'uscita, e (§7ter/§7quater) l'inventario di cosa in `src/` è già
  superato da Godot, cosa resta come pipeline di authoring dei contenuti, e il
  piano di spegnimento pianificato di Phaser (Fase 5 / blocco C-16, non ancora
  eseguito).
- `docs/VISIONE_DI_GIOCO.md` — visione di prodotto.
- `docs/STATO_CONTENUTI_E_NARRATIVA.md` — stato reale dei contenuti, materia
  per materia, misurato dagli audit (non un elenco a mano).
- `README.md` — come avviare/buildare il progetto oggi.

Non aggiungere qui nuove decisioni: vanno nei documenti sopra, per evitare che
tornino a divergere come è successo con questo file.
