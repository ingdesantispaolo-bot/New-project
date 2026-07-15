# Direzione production-ready

Il progetto oggi ha due piani distinti:

1. **prototipo prodotto in Phaser/Vite**, usato per validare gameplay, pedagogia, flusso missione, teoria NORA, salvataggi e loop energia;
2. **possibile produzione visuale in Godot 4**, consigliata quando l'obiettivo diventa resa artistica forte, asset multilayer e distribuzione piu ampia.

La priorita immediata resta il piano 1: rendere il gioco coerente, stabile e divertente prima di migrare tecnologia. La migrazione ha senso solo quando il vertical slice e davvero definito.

## Pilastri del prodotto

- **Missione come asse centrale**: il giocatore deve sempre percepire un obiettivo narrativo, non una lista di esercizi.
- **Teoria breve ma densa**: NORA deve spiegare concetti con capsule, esempi, trappole e visualizzazioni, sempre agganciata agli errori.
- **Esercizi come sistemi**: ogni prova deve avere metodo, feedback, competenze e conseguenze sul salvataggio.
- **Palestra come energia**: i giochi rapidi non sono extra separati, ma possono diventare eventi bonus dentro la missione.
- **Nessuna penalita inutile**: gli eventi bonus devono premiare il rischio, non bloccare la progressione.
- **Qualita visiva controllata**: ogni nuova scena deve essere leggibile, coerente, senza sovrapposizioni e senza pagine nere.

## Stato produttivo attuale

Il prototipo Phaser e diventato il riferimento per:

- missioni procedurali con timer, vite, score e ripresa;
- capitoli con fase Esplora e fase Prova;
- catalogo teoria NORA;
- Palestra della Mente autonoma;
- quattro giochi multidisciplinari: Tabelline, Calcolo Mentale, Geo Atlante, Geo Rilievi;
- eventi random "Frattura energetica" che lanciano giochi brevi per bonus energia;
- profili locali, report, classifiche, daily loop e Bottega.

Questo va trattato come vertical slice di design, non solo come prototipo tecnico.

## Direzione Phaser a breve termine

Prima di espandere contenuti, stabilizzare:

1. flusso missione -> evento bonus -> ritorno missione;
2. teoria NORA -> scheda -> esercizio -> ripasso in base all'errore;
3. Palestra -> record autonomi -> uso come evento missione;
4. runtime senza pagina nera per tutte le console;
5. screenshot audit desktop/tablet per scene modificate;
6. coerenza tra competenze, `theoryCatalog.ts`, generatori e feedback NORA.

Ogni nuova feature dovrebbe rispondere a una domanda semplice: rende piu chiara, piu sfidante o piu memorabile la missione?

## Palestra ed eventi bonus

La Palestra deve restare giocabile da menu come riscaldamento, ma la sua funzione piu forte e integrata nella missione:

- eventi brevi, 4-6 round;
- scelta del gioco pesata sul contesto;
- massimo 2 eventi per missione normale;
- massimo 1 evento nelle Prove Capitolo;
- ricompensa in energia e possibile stabilita timer;
- nessuna penalita se ignorati o falliti.

Questa regola evita che i giochi sembrino arcade separati. Devono essere scariche di attenzione dentro il ritmo narrativo.

## Scelta consigliata per produzione visuale

Godot 4 resta la scelta consigliata se il progetto passa a produzione artistica completa.

Motivi:

- gestione naturale di scene 2D/2.5D;
- layer separati per fondali, luci, particelle, riflessi e hotspot;
- transizioni tra stanze piu solide;
- audio ambientale e animazioni integrati;
- esportazione PC, web e mobile;
- pipeline piu adatta a fondali illustrati o renderizzati.

La migrazione non deve iniziare finche il vertical slice Phaser non ha:

- una missione completa rifinita;
- una stanza esplorabile di qualita;
- un set stabile di esercizi;
- una schermata teoria NORA convincente;
- un evento bonus integrato e verificato;
- una direzione artistica chiara.

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

1. soggiorno o stanza Accademia con finestra sulla citta;
2. fondale bitmap 16:9 o 21:9;
3. layer animati separati;
4. 5 hotspot ben integrati;
5. audio ambientale;
6. una console esercizio;
7. una scheda teoria NORA;
8. un evento bonus energia;
9. una transizione verso la vista citta o verso la missione successiva.

Questa stanza diventa il riferimento qualitativo per tutte le altre.

## Quality target creato

Il prototipo include o ha previsto fondali bitmap e riferimenti visuali per:

- academy/action room;
- laboratorio;
- archivio;
- serra;
- fabbrica;
- vista citta;
- scene narrative di capitolo.

Gli asset bitmap devono sostituire le scene procedurali quando sono disponibili e servire come riferimento per il resto del progetto. La logica HTML/canvas resta utile per hotspot, stato, interazioni, UI e layer atmosferici.

## Animazione vista citta

La vista esterna deve sembrare viva tramite layer indipendenti, non tramite un overlay unico:

- drift lentissimo del fondale per evitare immobilita assoluta;
- finestre e insegne con pulsazioni non sincronizzate;
- traffico aereo a profondita diverse;
- flussi luminosi lungo le strade;
- foschia che attraversa la scena;
- coni di luce/searchlight molto sottili.

Questa grammatica visiva e adatta al prototipo web e puo essere tradotta in Godot con `CanvasLayer`, particelle leggere, shader 2D e piccoli sprite animati.

## Checklist prima di chiudere una feature

- `npm run build` passa.
- `npm test` passa quando la modifica tocca logica condivisa.
- La scena e stata aperta a runtime.
- Nessun errore JavaScript in console.
- Screenshot desktop e, se cambia layout, tablet/mobile.
- Timer, salvataggio e ritorno scena verificati.
- Il worktree sporco preesistente non viene revertito.
