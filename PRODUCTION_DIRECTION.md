# Direzione production-ready

La versione HTML/canvas e utile come prototipo interattivo, ma non e la tecnologia finale consigliata per un gioco con resa visiva forte.

## Scelta consigliata

Usare Godot 4 per la produzione.

Motivi:

- gestione naturale di scene 2D/2.5D;
- layer separati per fondali, luci, particelle, riflessi e hotspot;
- transizioni tra stanze piu solide;
- audio ambientale e animazioni integrati;
- esportazione PC, web e mobile;
- pipeline piu adatta a fondali illustrati o renderizzati.

## Pipeline visiva consigliata

Ogni location dovrebbe essere costruita come pacchetto di asset:

- `background`: fondale principale illustrato/renderizzato;
- `foreground`: elementi davanti alla camera;
- `light_masks`: neon, finestre, schermi, insegne;
- `particles`: polvere interna, vapore, fumo, traffico/luci esterne;
- `hotspots`: aree interattive non visibili o appena suggerite;
- `ambient_audio`: loop della stanza;
- `state_layers`: varianti accesa/spenta, aperta/chiusa, prima/dopo.

## Regola importante

La pioggia non deve essere un overlay procedurale generico. Se serve, deve comparire solo come parte dell'asset o come layer esterno molto specifico:

- dietro il vetro delle finestre, integrata nel fondale o in un layer dedicato;
- come riflesso luminoso sul pavimento;
- come suono ambientale;
- eventualmente come gocce sul cappotto o sul davanzale, non come overlay davanti alla stanza.

## Vertical slice ideale

Prima di espandere la citta, produrre una sola stanza a qualita alta:

1. soggiorno con finestra sulla citta;
2. fondale bitmap 16:9 o 21:9;
3. layer animati separati;
4. 5 hotspot ben integrati;
5. audio ambientale;
6. una transizione verso la vista citta.

Questa stanza diventa il riferimento qualitativo per tutte le altre.

## Quality target creato

Il prototipo ora include i primi fondali bitmap:

- `assets/living-room-quality-target.png`
- `assets/entry-quality-target.png`
- `assets/bedroom-quality-target.png`
- `assets/kitchen-quality-target.png`
- `assets/city-view-quality-target.png`

Questi asset sostituiscono le scene procedurali quando sono disponibili e servono come riferimento per il resto del progetto. La logica HTML/canvas resta utile per hotspot, stato, interazioni e layer atmosferici.

## Animazione vista citta

La vista esterna deve sembrare viva tramite layer indipendenti, non tramite un overlay unico:

- drift lentissimo del fondale per evitare immobilita assoluta;
- finestre e insegne con pulsazioni non sincronizzate;
- traffico aereo a profondita diverse;
- flussi luminosi lungo le strade;
- foschia che attraversa la scena;
- coni di luce/searchlight molto sottili.

Questa grammatica visiva e adatta al prototipo web e puo essere tradotta in Godot con `CanvasLayer`, particelle leggere, shader 2D e piccoli sprite animati.
