# Eli Quest — Baseline release candidate

Rilevazione tecnica del 29 luglio 2026. Questo documento conserva le misure;
il lavoro ancora aperto resta in `insieme.md`.

## Ambiente

- Godot `4.7.1.stable`
- eseguibile locale:
  `C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`
- preset: `Web`, release

## Verifiche automatiche

- 68 audit Godot su 68 verdi, eseguiti con save locali isolati (l'isolamento non
  è un dettaglio: `roundtrip_audit` legge il save reale e un salvataggio lasciato
  da una prova precedente può far fallire il gate);
- nota di metodo: un `assert` fallito in uno script Godot headless stampa
  `SCRIPT ERROR` ma **non** cambia l'exit code — un audit va considerato verde
  solo se l'output non contiene asserzioni fallite;
- round-trip missione → nave → esame → mondo successivo verde;
- touch essenziale, contrasto elevato e riduzione movimento coperti da audit;
- streaming a raggio Web/tablet: massimo 9 chunk nei mondi campione;
- probe GPU desktop/tablet: massimo 665 draw call, sotto il budget mobile
  provvisorio di 700.

Campione headless con mondi 1, 7, 13, 19 e 24:

| Mondo | Avvio | Nodi | Chunk |
| --- | ---: | ---: | ---: |
| 1 | 256 ms | 3.322 | 9 |
| 7 | 171 ms | 2.147 | 9 |
| 13 | 210 ms | 2.403 | 9 |
| 19 | 189 ms | 2.292 | 9 |
| 24 | 114 ms | 1.600 | 9 |

Queste misure intercettano regressioni strutturali, ma non sostituiscono FPS,
memoria e draw call misurati in un browser e su tablet reale.

## Export Web

Le 44 grandi tavole pittoriche dei mondi usano import texture lossy a qualità
`0.85`; i sorgenti PNG restano invariati.

| File | Dimensione |
| --- | ---: |
| `index.pck` | 29,76 MiB |
| `index.wasm` | 37,68 MiB |
| export completo | 67,76 MiB |

Prima della compressione l’export misurava 132,17 MiB e il PCK 94,17 MiB.
La riduzione del download totale è 64,41 MiB, circa il 48,7%.

## Controllo visuale

- le tavole compresse dei mondi campione non mostrano banding, aloni o perdita
  percettibile su landmark e testo;
- Eli usa il nuovo foglio pittorico femminile a 20 frame
  `eli-adventure-girl-sheet-v2.png`, coerente con l’identità narrativa;
- i quattro tier di anomalie hanno silhouette, frammenti e intensità distinte;
- header nave, oscurità del mondo 13 e board degli esercizi non-MC sono stati
  corretti dopo le capture desktop/tablet;
- evidenze riproducibili: `artifacts/eli-enemies`,
  `artifacts/exercise-renderers` e le capture C-P6.

Comando di export:

```powershell
$env:APPDATA='D:\AppElis\New-project\.tmp\godot-appdata'
$env:LOCALAPPDATA='D:\AppElis\New-project\.tmp\godot-localappdata'
& 'C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' `
  --headless --path godot --export-release Web '..\.tmp\web-cp6\index.html'
```

L’export è tecnicamente riproducibile; smoke browser e profiling su tablet reale
restano criteri aperti in `insieme.md`.
