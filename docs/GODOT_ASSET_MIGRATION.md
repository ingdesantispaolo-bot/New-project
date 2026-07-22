# Manifesto asset Phaser → Godot

Stato verificato il 22 luglio 2026. Il file macchina completo è
`docs/GODOT_ASSET_MANIFEST.json`; viene rigenerato con
`node scripts/build-godot-asset-manifest.mjs` e contiene una riga per ogni
immagine legacy ancora presente.

## Esito

Gli asset non vanno copiati tutti alla cieca. Il runtime Godot usa già 43 asset
visivi propri e 36 tracce WAV. I sette ambienti della nave sono migrati come
WebP ottimizzati; i loro PNG master restano sorgenti artistiche, non risorse da
impacchettare. Gli asset outdoor equivalenti sono stati ricostruiti con atlanti,
shader e strutture native.

La parte ancora intenzionalmente non traslata è soprattutto narrativa: immagini
`story`, `chapter` e `nora` restano sorgenti da conservare finché le relative
cutscene Godot non saranno implementate. Non sono una dipendenza del runtime
attuale e non devono gonfiare il PCK.

## Stati del manifest

| Stato | Azione |
| --- | --- |
| `reuse-native` | Già presente e usato/richiamabile da Godot. |
| `replace-optimized` | Master legacy sostituito da un equivalente WebP Godot. |
| `replaced-by-native-world` | Coperto dal mondo, atlanti o enigmi nativi; non copiare. |
| `retain-story-source` | Conservare fuori dal runtime per la futura narrazione. |
| `review` | Nessuna equivalenza automatica affidabile; decisione artistica esplicita. |

## Regola di qualità

Per la nave il WebP è il formato runtime canonico: preserva la resa pittorica a
una frazione del peso dei PNG master. Il livello “AAA” non è certificabile con
un'etichetta: viene controllato con screenshot GPU in `artifacts/ship`, layout
responsive e audit di leggibilità/cliccabilità. Le schermate attuali superano
questi controlli, ma il polish finale richiede comunque art direction e test su
hardware target.
