# Evoluzione visiva di Eli

Cinque fogli 5×4, celle da 96×96 pixel, collegati direttamente ai gradi di
`WorldLight`: Scintilla, Lampada, Faro, Aurora e Meridiana.

La crescita è intenzionalmente ottenuta con equipaggiamento, postura percepita,
nucleo e luce. Eli resta la stessa giovane adolescente in ogni forma. Il design
è rivolto a ragazze di 11–15 anni: abbigliamento pratico, sportivo, modesto e
non adulto.

Gli spritesheet evolutivi sono stati generati con ImageGen integrato usando
`eli-adventure-girl-sheet-v2.png` come riferimento fisso. Il prompt ha imposto:

- identità, volto, età, capelli e proporzioni invariati;
- identica griglia di venti pose, direzioni e ordine dei fotogrammi;
- evoluzione attraverso protezioni leggere, circuiti e nucleo luminoso;
- nessun testo, scenario, arma o silhouette adulta.

I sorgenti sono stati normalizzati da
`scripts/process-eli-evolution-sheet.mjs`; gli effetti dinamici restano nativi
Godot per reagire a energia, movimento ridotto e potenza.
