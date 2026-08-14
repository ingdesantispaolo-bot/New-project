# Catalogo visuale degli abitanti

Il catalogo contiene 69 personaggi illustrati, tre per ciascuno dei mondi 1–23. Ogni asset è un PNG 384×384 con alpha reale, usato sia nel mondo sia come sorgente del ritratto dialogo.

Convenzione deterministica:

```text
w08-doria → res://assets/npcs/world08/doria-v1.png
```

`NpcPortrait.art_for()` risolve il percorso dall'ID narrativo. Questo evita un manifest duplicato e mantiene il caricamento lazy: il runtime carica soltanto il cast del mondo corrente. Dal 14 agosto 2026 anche i sei itineranti usano illustrazioni generative; soltanto un ID sconosciuto continua a usare la grafica vettoriale di sicurezza.

## Generazione

Modalità: ImageGen integrato, una chiamata distinta per personaggio. Tobia, Nonna Ersilia e Puccio sono stati usati come riferimenti stilistici fissi per tutte le generazioni successive.

Prompt comune:

> Production-ready full-body NPC sprite for Eli Quest. Match the fixed reference rendering language, compact proportions, elevated three-quarter game camera, detail density and lighting without copying identities or props. Create the named character from their narrative role, personality register, signature behavior, world palette and exactly one readable role prop. Premium hand-painted 2D game art with a painterly pixel-art-adjacent finish, crisp child-friendly silhouette, fully visible feet and generous padding, readable at 80–100 pixels. Soft upper-left ambient light and subtle warm rim light. One character on a perfectly flat `#ff00ff` chroma-key background. No text, watermark, extra poses, extra props, cast shadow or reflection.

Nome, ruolo, registro e tic sono stati letti direttamente da `NpcCatalog`; palette, abiti e oggetto di ruolo sono stati specificati individualmente per ogni personaggio.

## Post-produzione e QA

`scripts/process-chroma-character.mjs` campiona il colore ai bordi, applica matte morbido e despill, ritaglia, ridimensiona e valida angoli trasparenti e copertura del soggetto. `npc_visual_art_audit.gd` controlla i 69 residenti e i 6 itineranti, le dimensioni, l'alpha, l'uso in `NpcActor`, il ritratto e il fallback.
