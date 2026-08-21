# Eli Quest — Piano di lavoro

Aggiornato al 20 agosto 2026.

**Questo file contiene solo lavoro da fare.** Niente resoconti: quelli stanno nel
*Registro dei lavori* di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md).
Se una cosa è finita e verde, esce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md) ·
[Custode avanzato](docs/CUSTODE_LIVELLO_AVANZATO.md) ·
[Minigiochi personaggi](docs/MINIGIOCHI_PERSONAGGI.md)

> **Snellito il 13 agosto 2026, ripulito il 14.** I lotti chiusi escono da qui e
> stanno nel registro del file di rilascio, con le loro misure e i loro audit.
> Qui resta solo ciò che non è fatto.

---

## Dove ci orientiamo — 14 agosto 2026

Le tre direzioni misurate il 5 agosto erano: la profondità degli esercizi (non era
il collo di bottiglia), le spiegazioni (lo era, ed è chiusa) e il divertimento
(non misurabile senza far giocare qualcuno).

La terza si è mossa, e non nel modo previsto. **Una parte del divertimento non
richiedeva un bambino per essere misurata**: bastava leggere che cosa fa il gioco
mentre si gioca, invece di che cosa contiene. Fatta quella lettura, il collo di
bottiglia si è spostato dai contenuti allo **strato di gioco**.

La misura, in una riga: il verbo del gioco oggi è *cammino fino a un'icona e si
apre un pannello*. Tutto il resto — 24 mondi autorati, dieci meccaniche di
minigioco, 46 residenti con un arco, sette colpi di scena — poggia su un ciclo
motorio che non chiede mai una decisione. Le cose che una decisione la chiedono
esistono e sono **tre**: l'enigma che si costruisce mentre rispondi, la
minimissione che cambia la mappa, il duello dei guardiani.

Le voci di questo piano sono lì per aggiungere la quarta, la quinta e la sesta.
Otto sono state chiuse fra il 13 e il 14 agosto — la serie, l'impulso che si
guadagna, la curva della potenza, la nave camminabile, la matematica del primo
livello, i moduli di spedizione, l'audio dei mondi e il Custode nella nave — e
**nessuna ha aggiunto un esercizio**: la
campagna resta a 21,1 ore misurate. È un vincolo del piano, non una speranza: il
collaudo l'ha già definita faticosa, e rispondere a «è noioso» con «è più lungo»
è l'errore che ha prodotto quel verdetto.

### L'ordine, e perché questo

L'ordine residuo è per **resa su costo**. Le voci Codex del lotto di agosto sono
uscite dal piano e stanno nel registro; le **C-ART-7…14** che le sostituiscono
nascono dalla lettura dell'arte del 20 agosto, più sotto.

| | voce | impatto | costo | chi |
|---|---|---|---|---|
| **G-4** | Collegare i due moduli alla resa C-G4 | basso | basso | Claude |
| **C-ART-9** | Coda: i pannelli del mondo hanno perso la trasparenza | basso | basso | tua decisione |
| **C-ART-10** | Coda: celle vuote, peso in memoria, un bagliore su tutto | medio | basso | Codex |
| **C-ART-12** | Cinque shader per tutto il gioco (1/5 condiviso) | medio | medio | Codex |
| **C-ART-13** | Conseguenze dei residenti (6/46) | medio | medio | Codex |
| **G-10** | Camminare è una scelta | ? | medio | dopo il collaudo |

---

## G-4 · Radar e torcia — ritirata il 21 agosto 2026

*Decisione del committente.*

I due moduli restavano in attesa del loro contratto semantico, con le
illustrazioni gia' riservate nel foglio premi. Sono usciti per la stessa
ragione per cui e' uscito l'impulso: **chiedono una resa che non esiste** — un
segnale sulla cassa entro il raggio, un cono luminoso orientato con Eli — e
venderli prima sarebbe stato il difetto del 6 agosto ripetuto, quattro
potenziamenti che costavano fino a 1600 frammenti e non facevano nulla.

La sezione spedizione non ne ha bisogno: ha gia' tre moduli che si vedono
(Passo lungo, Andatura felpata, Zavorra da campo), tutti e tre su numeri che il
grado di Eli non azzera.

Tolte anche le due illustrazioni riservate da `build-reward-assets.mjs`: il
foglio premi si genera dal solo catalogo, che e' la sola fonte di verita'. Se un
giorno la resa esistera', il modulo entra allora — con la sua resa, non prima.

---

## G-10 · Camminare non è una scelta

**Oggi.** `player_controller.gd` sono settantacinque righe: velocità, uno scatto
il cui moltiplicatore ora viene dai moduli (1,65× o 1,95×),
bob. L'unica cosa che il terreno fa è l'acqua che blocca. L'unica prova d'abilità
di tutto il gioco è il duello dei guardiani.

**La cautela che viene prima della proposta**, ed è del lotto del 6 agosto: *ogni
cosa che costa energia sulla mappa toglie prove fatte*, e la campagna è già lunga.
Quindi non pedaggi. Una **scelta**: lo scatto consuma una risorsa che si ricarica
stando fermi, e apre scorciatoie che non aprono mai niente di obbligatorio.

**Perché è ultimo, dichiarato.** È l'unica voce del piano che si può sbagliare
senza accorgersene, perché il suo unico giudice è il tatto — e il tatto arriva dal
tuo collaudo, non da una misura. Farla adesso significherebbe indovinare.

**Chi.** **Decisione tua dopo il collaudo**, poi Codex.

---

## Arte generativa — la lettura del 20 agosto 2026

Stessa lettura fatta il 14 agosto sullo strato di gioco, applicata ai disegni:
non che cosa il gioco **contiene** in fatto d'arte, ma che cosa un bambino
**guarda** mentre gioca.

Il gioco ha molta arte, e la parte grande è coperta: 23 tavole di terreno (una
per mondo), 22 landmark illustrati, 69 residenti più cinque itineranti, 24
guardiani, 11 Custodi, 9 tavole di Eli, 5 presenze di NORA, 60 riquadri di
ricompensa.

La misura, in una riga: **è illustrato ciò che sta sullo sfondo o si guarda da
lontano, ed è un poligono piatto quasi tutto ciò che si tocca.** Il terreno della
Necropoli delle Radici è dipinto; le tre pietre della sua Rovina dei Primi sono
le stesse tre pietre grigie degli altri ventitré mondi.

Le voci **C-** che seguono sono di Codex — sono resa, mai regola — e sono
ordinate per resa su costo: il numero segue la priorità. L'unica **G-** del
blocco, G-11, è la guardia che le tiene, ed è di Claude. Nessuna aggiunge un
esercizio, un nodo di regola o un minuto alla campagna, e nessuna è un
prerequisito: ogni cosa che nominano **è già giocabile oggi** con forme piene e
colori piatti. Si sostituisce un segnaposto, non si sblocca un lotto.

Tre vincoli valgono per tutte, e non si negoziano:

- **nessuna immagine contiene testo.** Le iscrizioni descritte nei cataloghi —
  «contare in gruppi non è pigrizia» sul bastone del mondo 1 — restano righe di
  catalogo, lette dal pannello e dal lettore di schermo;
- **il conto dei nodi si fa prima.** Il mondo 1 sta a 2.789/3.500 nodi e 311/500
  ms. Una tavola che sostituisce trenta poligoni **restituisce** nodi; un
  effetto che ne aggiunge va misurato con `performance_budget_audit` in
  isolamento, perché quell'audit è fragile al carico;
- **il peso arriva su un tablet scolastico.** Il PCK esportato è passato da
  34,33 a **52,27 MiB** in una giornata di tavole, e il pacchetto completo sta a
  89,96 MiB. Ogni atlante nuovo si dichiara in MB prima di essere generato, e da
  qui in avanti la domanda non è più «quanto pesa questo» ma «quanto pesa il
  primo caricamento su una rete di scuola».

> **Stato alla sera del 20 agosto.** Otto voci aperte la mattina, **sei chiuse**
> e nel registro: C-ART-7, 8, 10, 11, 14 e la guardia G-11. Restano due code
> misurate (C-ART-10 e la trasparenza di C-ART-9) e due voci a metà per scelta,
> C-ART-12 e C-ART-13, che avanzano a lotti.
>
> Un fatto va scritto perché è tornato tre volte su tre: **i tre audit scritti
> insieme alle tavole erano verdi, e nessuno dei tre difetti li ha fatti
> arrossire.** Verificavano la dichiarazione — che la tavola sia dichiarata, che
> il nodo esista, che il tipo sia quello giusto — non il disegno. È la stessa
> forma della decisione 14.
>
> Da lì è nata **G-11**, `tavole_guard_audit`, che misura il disegno: i ritagli,
> il contrasto del testo sulla superficie che ha sotto, i nodi contati
> sull'oggetto che il mondo costruisce. È nata rossa su dieci punti e li ha
> chiusi tutti; copre anche le tavole arrivate dopo — 72 edifici e sei atlanti
> naturali — che passano senza correzioni.
>
> **Un quarto difetto l'ha preso un audit che c'era già.** La sagoma di ruolo di
> C-ART-8 copriva il guardiano illustrato, e `generated_character_art_audit`
> vieta da prima di questo lotto che qualcosa gli si disegni sopra. Ora la sagoma
> sta dietro e sporge — corona sopra la testa, lame di lato — ma **la resa è
> geometria, non un occhio**: è la prima cosa da guardare giocando.
>
> **Il peso è la cosa da tenere d'occhio.** Il PCK esportato è passato da
> **34,33 a 52,27 MiB** (+52%), il pacchetto completo a 89,96 MiB. Ogni tavola
> di oggi è dentro quel numero, e quel numero arriva su un tablet scolastico.
>
> E una correzione mia, perché il numero era in questo file: gli oggetti
> identitari non sono 46 ma **71**. Contavo i `match` a un nome per riga e ce ne
> sono a tre.

---

### C-ART-9 · Coda: i pannelli del mondo hanno perso la trasparenza

Le tre superfici ci sono e le due cose che le rompevano sono chiuse: i due testi
della pergamena stanno adesso a **5,8:1** sulla carta e 16:1 sul ripiego, e
l'esame torna a distinguersi dal banco ordinario — non con un bordo, che una
`StyleBoxTexture` non ha, ma con una velatura del materiale. Le tiene
`tavole_guard_audit`, che stampa il rapporto di ogni etichetta: la prossima
correzione si misura invece di guardarla.

**Resta una cosa, ed è una tua decisione, non un difetto.** I sei pannelli del
mondo erano `alpha 0,72` sopra la mappa e adesso sono opachi, perché nessuna
delle tre texture ha canale alfa. Il mondo non si intravede più dietro l'HUD.
Si ripara in una riga — un alfa nel materiale o un `modulate` sul pannello — ma
è resa: va decisa guardando, non misurata.

---

### C-ART-10 · La coda (chiusa nel registro, non nel gioco)

Il lotto sta nel registro e le tavole sono buone: 71 kind su otto atlanti 4×3,
mappatura verificata a campione — la libreria è una libreria, il leggio è un
leggio, la caravana è una caravana. Restano quattro cose piccole.

- **La misura non è stata scritta, e intanto si è mossa.**
  `performance_budget_audit` è verde, ma il numero non è più quello:
  mondo 1 a **2.918/3.500 nodi e 403/500 ms**, contro i 2.789 e 311 dell'ultima
  misura scritta — l'81% del budget d'avvio. Non è tutto di questo lotto, in
  mezzo sono passati il cielo e i fuochi; ma la voce prometteva di
  **restituire** nodi, e nella misura non si vede. Va preso prima e dopo sullo
  stesso commit, e scritto nel registro accanto al «verde».
- **In scena ogni prop porta cinque nodi, non tre.** `IdentityPropArt.build()`
  ne restituisce due — radice e tavola — e `build_identity_prop` aggiunge ombra,
  bagliore e l'animazione del bagliore: cinque, uno dei quali gira in `_process`
  a ogni fotogramma. L'audit misura il primo oggetto e non il secondo:
  `get_child_count() <= 3` passa su una cosa che nel gioco non esiste.
- **Un alone che pulsa su tutto.** Prima ce l'avevano alcuni prop, e per un
  motivo; adesso ce l'hanno tutti e settantuno, un colore per famiglia. Un alone
  che pulsa è il segno con cui questo gioco dice «qui c'è qualcosa»: metterlo
  sulla scenografia insegna a non fidarsene. Va tenuto dove significa e tolto
  dove decora.
- **Venticinque celle vuote, otto atlanti sempre in memoria, 850 righe morte.**
  Le famiglie simbiosi (2 kind) e sintesi (3) hanno fogli da dodici celle: dieci
  e nove disegni fatti e mai raggiungibili, circa 2 MB su 8,1. I `preload`
  tengono tutti e otto gli atlanti in memoria per l'intera sessione, mentre
  landmark e atlanti naturali si caricano pigri e si liberano con
  `release_world_texture_caches()` — qui quella cura non c'è. E poiché nessun
  kind resta fuori dalle famiglie, i poligoni di `build_identity_prop` non sono
  più raggiungibili: o tornano a essere un ripiego vero quando una tavola manca,
  o vanno via.

---

### C-ART-12 · Cinque shader per tutto il gioco

**Oggi.** Due file — `painterly_ground` e `painterly_water` — e tre stringhe
inline: la stanza della nave, l'atmosfera, la vignetta. Tutto il resto
dell'atmosfera è CPU: `OutdoorAtmosphere` è un `ColorRect` più due
`CPUParticles2D`, e ogni chioma che ondeggia porta un nodo `OutdoorAmbientAnim`
che gira in `_process` a ogni fotogramma — 91 punti di aggancio nel codice.

**Progresso (20 agosto).** La foschia del mondo è uscita dalla stringa inline:
`world_atmosphere.gdshader` è una risorsa condivisa, con tinta per bioma e
movimento congelato da `reducedMotion`. Restano il vento vertex sugli atlanti,
la migrazione delle altre due stringhe e il cono della torcia.

**Perché adesso.** Il tempo ha ricominciato a passare il 20 agosto. La luce
cambia e **non cambia nient'altro**: niente vento che cala la sera, niente
foschia che si alza, nessuna ombra che si allunga. Un ciclo giorno/notte che
muove solo un `CanvasModulate` si legge come un filtro, non come un'ora.

**Cosa, in ordine di resa.**

- **Il vento sull'atlante naturale**, in vertex shader: zero nodi, e restituisce
  quelli di `OutdoorAmbientAnim` insieme al loro `_process`.
- **La foschia per bioma**, oggi un velo di colore uniforme sull'intera
  schermata.
- **Il cono di luce della torcia.** G-4 lo dichiara già come consumer dormiente
  a valore zero — «scala il cono luminoso orientato con Eli» — e le
  illustrazioni sono riservate nel `reward-items-sheet`. È la metà Codex di una
  voce già aperta, non una voce nuova.

**Il vincolo.** Movimento ridotto spegne il vento e la foschia mobile; il
pavimento di leggibilità di `WorldSky` (0,20) non si tocca da nessuna direzione.
Giudici: `world_light_audit`, `world_sky_audit`, `accessibility_release_audit` e
una misura isolata di `performance_budget_audit`.

---

### C-ART-13 · Le conseguenze dei residenti sono due su quarantasei

**Oggi.** `ResidentConsequenceVisual.supports()` risponde vero per `w01-tobia` e
`w01-ersilia`, e basta. Il commento lo dichiara: pilot del mondo 1, gli altri
«solo dopo aver misurato nodi e tempo di avvio». Nel frattempo
`resident_portrait_stage_audit` verifica 46 × 3 pose **nel ritratto**: la persona
cambia quando ci parli, il posto in cui vive no.

**Progresso (20 agosto).** Il primo lotto ha portato la copertura a **6/46**:
Corinna, Bruno, Ruggine e Sesto hanno tre conseguenze leggibili nei loro luoghi
dei mondi 2–3, sempre come un solo nodo procedurale. `resident_consequence_batch_audit`
verifica il montaggio nel `BuildingActor`, i tre stadi e il budget di nodi.
Restano quaranta residenti, da estendere a lotti misurati.

**Perché.** È l'unica cosa in tutto il gioco che dice, senza una parola e senza
un numero, che quello che il bambino ha imparato è arrivato a qualcuno. Due
mucchi di cristalli nel mondo 1 su quarantasei persone è un pilot rimasto pilot.

**Cosa.** Un lotto per volta, non tutti insieme: i sei residenti dei mondi 2–3,
misurati nodi e millisecondi prima e dopo, e si prosegue solo se il conto regge.
La misura che quel commento aspettava adesso esiste — 2.789/3.500 e 311/500 ms —
quindi il cancello si può aprire, un mondo alla volta.

**L'audit.** `resident_consequence_render_probe.gd` esiste già e produce catture
riproducibili: la regola resta quella del lotto del 13 agosto — i tre stadi
devono restare distinguibili **senza dialogo**.

---

### Le due che aspettano

Non sono voci: sono cose viste in questa lettura che non conviene aprire adesso.

- **Il formato che mostra l'oggetto vero vive in una materia sola.** `HOTSPOT`
  esiste per `storia`, con un atlante (`roman_artifacts`) e quattro bersagli;
  `ArtifactAtlasCatalog` ha una voce sola. È l'unico formato in cui un bambino
  riconosce una cosa vera invece di leggerne il nome, e delle dodici materie ne
  serve una. Non sostituisce il minigioco di montaggio già in piano per i
  ventidue quesiti sui componenti elettronici: semmai gli prepara il materiale.
  Aspetta perché il **secondo foglio di reperti** è già una voce aperta, e i due
  fogli conviene deciderli insieme.
- **I quindici minigiochi dei personaggi hanno un asset in tutto**
  (`assets/minigames/tobia-crystal-v1.png`). Le tavole vettoriali sono leggibili
  e funzionano. Aspetta il collaudo per la ragione già scritta nel piano: finché
  non si misura quali meccaniche restano nel giro, illustrarle tutte e quindici
  è lavoro su un'ipotesi.

---

## I residui dei lotti chiusi

Nessuno di questi è un lotto: sono code dichiarate, tenute qui perché non si
perdano.

**Contenuti e didattica (Claude)**

- **N-1 · Le spiegazioni degli item.** Il livello per argomento copre il perché
  generale, ma «Roma è la capitale della Repubblica Italiana» resta una
  riformulazione. Vanno riscritte **per argomento**, partendo da quelli allo 0% di
  nesso: parole di casa, lessico inglese, declinazioni, geografia fisica.
- **Quindici ricette al mondo 1.** Oggi sono dieci per materia. Deciso, e da fare
  **dopo** il collaudo: sei materie del mondo 1 sono cambiate molto e conviene
  sapere se la differenza si sente prima di scriverne altre sessanta.
- **Il banco di matematica è ancora al 78% tabelline.** Il 14 agosto è passato da
  1 a 6 argomenti (284 → 364 voci), ma le 284 tabelline restano la maggioranza e
  gli argomenti nuovi hanno il minimo sindacale di sedici item ciascuno. Il
  prossimo giro li porta al livello delle altre materie — venti-trenta per
  argomento — e aggiunge i due che mancano per la fascia alta: proporzioni ed
  equazioni, che NORA sa già spiegare e il banco non chiede mai.
- **Il pavimento della matematica ai mondi 1–3.** Chi fatica non ha un gradino
  sotto il nominale, perché il livello efficace non scende sotto 1 e lì il
  nominale *è* il pavimento. Si ripara solo portando l'adattività della
  matematica dal canale «livello» a quello «complessità», che oggi sono due
  meccanismi sovrapposti (`effective_difficulty` per il banco,
  `math_effective_level` per il generatore). Vale la pena farlo se il collaudo
  segnala il difetto opposto — qualcuno che al mondo 1 fatica.
- **I vocabolari di banco e minigiochi non coincidono.** La copertura del gate
  conta gli argomenti toccati e il bersaglio si calcola sul **banco**, ma la
  pratica marca anche i 104 argomenti che vivono solo nel catalogo interattivo. In
  inglese, coding, scienze, fisica ed elettronica un bambino può soddisfare la
  copertura toccando argomenti che l'esame non verificherà mai. Delle due
  riparazioni, quella giusta è **allineare i vocabolari**: se un argomento vale per
  la copertura, deve poter comparire in un esame.
- **La scala dei formati per livello.** I singoli esercizi sono graduati
  (`minLevel`), i formati no. La scala proposta segue la difficoltà cognitiva:
  1–4 riconoscere e appaiare · 5–10 mettere in processo · 11–17 leggere una
  rappresentazione · 18–24 manipolare rispettando vincoli.
- **Elettronica alle altre undici.** La scelta multipla a zero fuori dall'esame
  regge in elettronica perché lì la tavolozza dei minigiochi è profonda (ventuno
  argomenti, sette formati). Dove è più magra lascerebbe buchi: si estende materia
  per materia, misurando la tavolozza prima.
- **I ventidue quesiti sui componenti elettronici** (relè, condensatore): il
  problema non è la forma della domanda ma il fatto che un decenne non ha mai visto
  l'oggetto. La risposta giusta è un minigioco che glielo faccia montare.
- **Le leve del nucleo studiate e non attivate**: due luoghi invece di uno per le
  tre materie quando non sono ospiti (tocca il direttore degli eventi e va
  rimisurato il tempo per mondo); ripasso più stretto sui loro argomenti; il
  registro che mostra il nucleo a parte.
- **Gli epiloghi non nominano le minimissioni**: oggi le contano soltanto.

**Minigiochi dei personaggi**

- **C-MG-3 · La lingua della radio.** Marea sta al mondo 4, la cui materia è
  inglese, e i suoi nove messaggi sono in italiano: la meccanica è giusta, il
  materiale no. Passarli all'inglese cambia la difficoltà in modo serio, con cinque
  secondi di segnale e un bambino al quarto mondo. **Decisione tua.**

## Il pacchetto differito — che cosa contiene, adesso

**Decisione del 21 agosto: l'arte parte con il gioco, sempre.** I 74 ritratti,
le 24 tavole dei guardiani, gli 11 Custodi e i 5 itineranti sono nel pacchetto
d'avvio. Nel differito resta **solo l'audio**, che degrada in silenzio e non ha
una faccia.

Prima quelle tavole viaggiavano col pacchetto chiesto in sottofondo, e chi
entrava nel mondo nei primi venti secondi vedeva i gusci vettoriali. Il
rimontaggio all'arrivo aveva chiuso il difetto, ma la finestra restava: una
finestra in cui il gioco si mostra peggio di com'è non è un compromesso che
questo progetto fa.

Il prezzo, dichiarato: **PCK da 52,27 a 63,51 MiB**, pacchetto completo a 101,19
MiB; il differito scende da 25,8 a 14,6 MiB. Il primo caricamento è più pesante
di undici mega e il primo mondo è quello giusto da subito.

Misura sulla build esportata, entrando nel mondo appena parte:
**`montato-e-riapplicato:0`** — nessun nodo in attesa, nessun ripiego mostrato.
Prima erano dodici.

Due guardie, e servono tutt'e due perché il difetto è vissuto un mese senza che
nessuno lo vedesse: `boot_art_audit` non lascia rimettere l'arte nel differito —
è una riga di un `.cfg` che nessun test esegue e rimetterla costa un secondo — e
`content_pack_refresh_audit` tiene in piedi il rimontaggio, che resta come rete
di sicurezza per l'audio e per qualunque cosa venga differita domani.

**Il disegno vettoriale resta nel codice, e non è una contraddizione.** Nel
guscio delle sacche di Silenzio quelle forme non sono un ripiego: sono il corpo,
e l'illustrazione ci sta sopra per costruzione. Toglierle cambierebbe la resa
voluta, non semplificherebbe niente. Quello che è stato eliminato è la
*condizione* in cui il ripiego si vede.

---

## Le cose da guardare giocando

Sono i punti in cui una resa sbagliata non rompe niente e toglie tutto il
significato.

- **La durata dei minigiochi dei personaggi.** Misurare su tablet almeno un gioco
  per ciascuna delle quindici meccaniche, insieme agli errori prima della scoperta
  e alla capacità di spiegare la strategia. Solo quei numeri possono decidere se
  un gioco debba aggiungersi al giro o sostituire una tappa di missione, senza
  allungare alla cieca la campagna da 21,1 ore.

- **1 · la conta di nonna Ersilia** va sentita nei primi cinque minuti. È la
  tabellina del 7 e contiene il nome del Tredicesimo. Se il giocatore la salta,
  al mondo 24 non ha la chiave in mano.
- **8 · il sigillo**: tredici alloggiamenti, undici nomi. Il dodicesimo è
  raschiato e **i graffi vanno verso l'interno** — l'ha fatto qualcuno seduto al
  tavolo. Se la resa non mostra la direzione dei graffi, il colpo 2 perde metà
  del suo significato.
- **10 · la dispensa**: è il primo posto in cui il gioco dice esplicitamente che
  **non è morto nessuno**. Provviste sigillate, appunti impilati, un posto in più
  apparecchiato. Non è una scena di abbandono: è una scena di preparazione.
- **11 · le due datazioni**: nessuna delle due va bruciata, e la resa non deve
  suggerire quale sia «quella giusta».
- **12, 16, 19 · Tracce decisive**: hanno un `ripiego` in `MysteryCatalog`, ed è
  **obbligatorio cablarlo**. Senza, entrare nella Rovina diventa necessario per
  capire il finale, e questo viola il guard-rail «niente blocca il loop».
- **14 · i verbali**: dove dovrebbe esserci il nome della tredicesima voce c'è un
  **buco nella carta**, non una cancellatura. Va reso come un'assenza fisica.
- **17 · le insegne**: è la **prima azione del Tredicesimo** in tutto il gioco
  (`scrive`, poi `risbiadisce`). Una parola sola, ripetuta su ogni insegna
  dell'area, e sparisce uscendo. Nessun effetto sul gioco: costo zero.
- **18 · la voce**: prima volta che il Tredicesimo **parla**. Nessun ritratto,
  nessun corpo. Stanca, mai minacciosa.
- **19 · `chiude`**: la terza azione entra qui. Una porta della nave sigillata per
  un livello, e **deve esistere sempre una strada alternativa**.
- **20 · la curva**: le misure della quarantena stanno piatte per trecentonovanta
  anni e si alzano **poco prima** che Eli arrivi, non da quando è arrivata. È la
  differenza fra «è colpa tua» e «stava già cedendo», e il gioco dice la seconda.
- **21 · la tesi**: in fondo al foglio ci sono **due mani diverse**. «Allora
  bisogna smettere» e, di traverso, «oppure imparare meglio».
- **23 · il registro**: nella colonna delle perdite non c'è niente. Meridiana non
  è mai stata registrata come perduta, e questo è il punto.

### Il mondo 24 · Cuore dei Primi

Non ha residenti suoi: al Cuore convergono **i sei itineranti** e i residenti che
il giocatore ha portato allo stadio 2, **massimo quattro in scena per volta**.

`FinaleCatalog.cast_for(residenti_stadio2, ondata)` risponde con chi è in scena e
`waves_needed()` con quante ondate servono. Contenuto pronto: **una battuta per
ognuno dei 46 residenti** — e ognuna dice cosa quel personaggio ha smesso di
credere, non un saluto — più le sei degli itineranti.

Due vincoli, verificati da `finale_content_audit`:

- **il Cuore non è mai vuoto.** Con zero residenti allo stadio 2 ci sono comunque
  i sei itineranti. Un finale che premia con la solitudine chi ha giocato in un
  altro modo è una punizione travestita da conseguenza;
- **nessuna battuta nomina chi non è venuto.** Gli assenti non si nominano.

`FinaleCatalog.CATTEDRA` ha l'assegnazione del tredicesimo posto. Si innesca
**dopo il nodo di sintesi**, non all'arrivo: il posto va a chi l'ha risolto, non
a chi è arrivato.

---

## Gli allenamenti: dove si fanno, e con che faccia — 21 agosto 2026

*Segnalazione di gioco: «dobbiamo gestire meglio come e dove fare allenamenti.
Ora gli ingressi sono in icone sparse a caso anche brutte con 2605 come logo».*

Tre difetti distinti dietro una frase sola. Il primo è chiuso, gli altri due sono
qui sotto divisi fra chi li deve fare.

### Che cos'era «2605» — chiuso

Non era un logo: è il **codice esadecimale di ★**, U+2605. Il progetto non
imbarca nessun font e usa `Open Sans SemiBold`, che quel glifo non ce l'ha. Su
Windows Godot ripiega sui font di sistema e la stella si vede; **nel Web e su
tablet quel ripiego non esiste** e resta il rettangolo col codice dentro. È il
motivo per cui nessuna cattura di sviluppo aveva mai mostrato il difetto: è
invisibile esattamente sulla macchina di chi scrive il codice.

Misurato da `glifi_probe`: **58 simboli su 63** usati nel codice non hanno glifo
nel font imbarcato, e nella bottega **0 articoli su 44** si disegnano interi.

Chiuso oggi: l'insegna delle palestre è **disegnata** — nessun glifo, nessun
ripiego possibile — e porta il **colore della materia** da `SubjectPalette`, che
da oggi è una tabella sola per il mondo, la nave e le palestre (prima erano due
copie divergenti). Resta aperta la bottega, qui sotto.

### C-G-12 · Le insegne della bottega — chiusa il 21 agosto 2026

Ogni articolo del catalogo aveva un campo `glyph` con un carattere Unicode, e
**nessuno dei quarantaquattro si disegnava** fuori da Windows: chi giocava nel
browser comprava rettangoli con dentro `25C9`, `1F436`, `2726`.

Chiusa per una strada migliore di quella che avevo proposto. Non sono servite
quarantaquattro forme nuove: **l'atlante illustrato esisteva gia'**
(`reward-items-sheet`), e alla bottega mancava solo di usarlo sempre. Tolto il
ripiego `_tool_fallback_texture` da `outdoor_shop_panel`, rigenerato il foglio
premi dal catalogo — 63 icone, e i tre strumenti che stavano fuori dall'atlante
(`tool-lever`, `tool-lens`, `tool-bellows`) adesso ci sono davvero.

`glifi_audit` tiene le due condizioni: **ogni articolo del catalogo ha una
regione nell'atlante**, e la bottega **non puo' tornare al glifo di sistema**.
`glifi_probe` resta come censimento del repertorio Unicode nel codice, che e' il
posto da cui il difetto e' arrivato.

Nota per chi tocca il catalogo: aggiungere o togliere una voce **richiede
`npm run assets:reward`**. Il 21 agosto due moduli nuovi hanno fatto diventare
rosso `shop_presentation_audit` proprio per questo, e le illustrazioni riservate
ai moduli ritirati vanno tolte anche da `build-reward-assets.mjs`.

### G-12 · Il quartiere degli allenamenti — chiusa il 21 agosto 2026

**Il difetto.** Le undici palestre nascevano nella banda esterna, una per
materia, e c'era una riga che le allontanava **di proposito**:

    score -= float(cluster_usage.get(cluster_id, 0)) * 18.0

con il commento «formano costellazioni, non un unico mucchio». Giusta per gli
eventi del gate — che devono offrire una scelta di rotta — e sbagliata per gli
allenamenti, che non sono un percorso: sono un **servizio**, e un servizio
sparso su duemila unità di mappa non si usa.

**La forma.** Per le palestre quella riga si rovescia: il quartiere ripetuto
diventa un pregio, e la vicinanza alla stazione precedente pesa più di ogni
altra cosa (`ancora` in `_semantic_placement`). L'ordine lungo il filo è quello
del ciclo delle materie, quindi è **stabile fra i mondi**: chi ha imparato che il
latino viene dopo l'inglese lo ritrova al mondo dopo.

**Che cosa ho creduto e che cosa dice la misura.** Avevo scritto «una catena
leggibile». Non si ottiene, e alzare il premio di vicinanza non la produce: il
collo di bottiglia è la **capienza dei luoghi**, non il punteggio — undici
palestre più otto eventi di gate non entrano nei socket di un quartiere solo.
Misurato: col premio a 340 il passo fra due stazioni consecutive resta anche di
2400 unità, e alzarlo ancora peggiora.

Quello che l'ancora ottiene davvero, e che è ciò che serviva:

| | prima | dopo |
|---|---|---|
| quartieri per mondo (media) | 4,2 | **2,9** |
| quartieri nel mondo peggiore | 11 | **5** |
| raggio del gruppo (media) | 1452 | **1319** |

Non è una collana: è un **quartiere degli allenamenti**, che è la cosa che si
impara a memoria e si torna a cercare. `semantic_placement_audit` tiene i due
tetti — sei quartieri, raggio 2300 — misurati sul caso peggiore. Si abbassano,
non si alzano.

**E il «come», non solo il «dove».** Il quadro degli obiettivi elencava già le
dodici materie con quanto manca a ciascuna, e poi lasciava il bambino a cercarle
camminando. Adesso ogni materia aperta ha il suo **PORTAMI**: chiude il quadro e
punta la bussola alla sua stazione. Il filo risolve il *dove*, il pulsante il
*come ci arrivo*.

Trovato per strada: quel quadro usava `✔` (U+2714) per le materie chiuse — un
altro «2605», stesso font, stesso rettangolo col codice su Web e tablet.

### C-G-13 · La faccia di una stazione — Codex, dopo G-12

Quando il filo esiste, una stazione non è più un disco con una stella: è un
**ripetitore dei Primi**, e le undici insieme sono il circuito che il nucleo
prismatico della nave rimette in fila. Serve la resa: la pietra, il filo che
collega una stazione alla successiva quando le hai visitate tutte e due, e la
luce che si accende del colore della materia quando la stazione è stata usata in
questo mondo.

Il colore lo dà già `SubjectPalette` ed è lo stesso della notte di quel mondo e
della scheda sul ponte: non va reinventato, va letto.

### Perché il filo è coerente con la storia, e la spirale no

I Primi hanno lasciato un **circuito**, e `BuildingCatalog` lo dice già: la
*first_ruin* di ogni mondo «è un pezzo del circuito, e messe in fila raccontano
che qualcuno è passato di qui prima, dodici volte». Il nucleo prismatico che si
compra in bottega è descritto come «il cuore della nave, che scompone la luce in
dodici colori: uno per sistema — è un ritratto, non una macchina».

Undici pietre in fila, ognuna del colore del suo sistema, che partono dalla
piazza degli abitanti e si allontanano nel mondo, **sono** quel circuito visto da
terra invece che dal ponte. Undici dischi identici sparsi a caso non sono niente:
sono interfaccia travestita da mondo, ed è esattamente quello che la segnalazione
ha visto.

C'è anche una conseguenza narrativa che il filo si porta dietro gratis: gli
abitanti allenano **quello che sanno fare**, e il ritrovo è dove si parlano. Una
stazione accanto alla piazza è un posto in cui qualcuno può stare; una stazione a
duemila unità nel nulla no. Il gancio con `TeachingCatalog` e con i maestri
esiste già e non è mai stato usato per la pratica.

---

## G-13 · La risposta più lunga è quella giusta — 21 agosto 2026

*Domanda del committente dopo il difetto dell'italiano: «possono esserci casi
simili in altre materie o in altri minigiochi?». Misurato: **sì**, in nove
materie su dodici, e in una forma diversa.*

Il difetto dell'italiano era «la domanda e la risposta usano le stesse parole».
Nelle banche a scelta multipla la scorciatoia è un'altra e non richiede di saper
leggere: **si tocca l'opzione più lunga**.

Misura su 2.672 quesiti a scelta multipla, tutte e dodici le materie:

| materia | quesiti | «la più lunga» vince | atteso dal caso |
|---|---|---|---|
| scienze | 122 | **62,3%** | 27,3% |
| storia | 133 | **48,1%** | 27,1% |
| musica | 104 | **54,8%** | 35,1% |
| coding | 137 | 46,0% | 30,7% |
| fisica | 121 | 44,6% | 28,7% |
| elettronica | 127 | 42,5% | 28,1% |
| geografia | 159 | 40,3% | 29,2% |
| latino | 168 | 44,6% | 36,8% |
| italiano | 527 | 45,2% | 37,8% |
| inglese, matematica, logica | — | in linea col caso | ✅ |

In scienze **la scorciatoia risponde giusto sei volte su dieci** senza sapere
niente, contro le tre del caso. Non è un sospetto: è la stessa famiglia di
difetto del duello delle voci, e si scopre solo contandolo.

**Due cose che invece sono sane**, e vale la pena scriverle perché non vadano
perse:

- la **posizione** della risposta giusta è uniforme (667 / 676 / 653 / 676 sulle
  quattro caselle): nessuno può imparare «è sempre la seconda»;
- l'**eco della domanda** non aiuta: la risposta giusta ripete le parole del
  quesito **meno** del caso (11,2% contro ~30%). I distrattori sono scritti bene:
  sono loro a somigliare alla domanda, ed è giusto così.

**Il lavoro.** Non è riscrivere 2.672 quesiti: è pareggiare la lunghezza dei
distrattori dove la differenza è grossa, materia per materia, partendo da scienze
e storia. Poi un `bank_scorciatoie_audit` che tiene le tre misure — lunghezza,
posizione, eco — e diventa rosso quando una materia esce dalla banda del caso.
Senza l'audit il difetto torna al primo blocco di quesiti nuovi, perché scrivere
la risposta giusta più esplicita delle altre è la cosa naturale da fare.

### G-14 · Quali minigiochi si vincono a caso — misurato il 21 agosto 2026

Quindici archetipi, quarantasei personaggi, tutti con un pannello e tutti con un
audit. Ma nessuno di quegli audit chiedeva la cosa che conta: **si vincono senza
capirli?** `minigiochi_cieco_probe` gioca ogni pannello con tocchi casuali,
sessanta partite per archetipo, e conta.

| archetipo | vinti a caso | tocchi medi | |
|---|---|---|---|
| **mucchio** | **100,0%** | 6 | *il primo che un bambino incontra, mondo 1* |
| **prova** | **68,3%** | 5 | *«una causa si isola, non si indovina»* |
| scaffale | 43,3% | 8 | |
| vibrazione | 36,7% | 62 | |
| leva | 35,0% | 77 | |
| mercato | 25,0% | 5 | |
| glifi | 21,7% | 7 | |
| parentela | 20,0% | 78 | |
| stima | 8,3% | 87 | |
| altalena | 3,3% | 54 | |
| traccia | 1,7% | 14 | |
| ciclo · radio · circuito · ritmo | **0,0%** | | *sani* |

**I due da guardare.**

Il **mucchio** è il minigioco di Tobia, mondo 1: il primo che un bambino
incontra, e si vince **sempre** toccando a caso in sei tocchi. Un fallimento
c'è — il cronometro — ma non stringe mai. La lezione dichiarata è «raggruppare
batte contare», e raggruppare non serve: si tocca tutto.

La **prova** dice di sé «una causa si isola, non si indovina», e si indovina due
volte su tre.

Gli altri tredici stanno sotto il 45%, e quattro sono a zero. La colonna dei
tocchi medi separa due famiglie: chi si chiude in cinque-otto tocchi (mucchio,
prova, scaffale, mercato, glifi) e chi ne chiede decine. Nei primi il caso ha
poche occasioni di sbagliare, ed è lì che il numero sale.

**Che cosa NON è questo numero.** Non è un verdetto: alcuni archetipi sono giochi
di velocità, dove sbagliare costa tempo e non la partita, e un CIECO paziente li
finisce comunque. È il numero da guardare **prima** di dire che un minigioco
funziona — e prima di aggiungere il sedicesimo archetipo.

**Da decidere insieme:** se e come stringere mucchio e prova. La sonda resta e
misura di nuovo dopo ogni taratura.

---


## Chi fa cosa

| | Claude | Codex | Tu |
|---|---|---|---|
| Codice, contenuti, regole di gioco e audit | ✅ | | |
| **Arte generativa, scena e resa visiva** (voci **C-**) | | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | | ✅ |
| Decisioni di prodotto (G-4, G-8, G-10, C-MG-3) | | | ✅ |

Le voci **G-** sono di Claude tranne dove è nominata una **C-G**: quella riga è di
Codex, ed è sempre la parte che si vede — mai la regola.

Le richieste a Codex passano da questo file e vanno tenute **separate dalla
meccanica**: una cosa deve essere giocabile con forme piene e colori piatti prima
che esista un disegno, altrimenti l'arte diventa un prerequisito e il lotto si
ferma ad aspettarla.

Con un solo esecutore per parte la revisione incrociata sparisce, e la sostituisce
una regola sola: **niente entra senza un audit che lo tenga.** Vale soprattutto per
il runtime, dove un errore non si vede rileggendo — il 3 agosto una sostituzione in
blocco ha invaso due costruttori che non c'entravano, e non me ne sono accorto
rileggendo il diff: me l'ha detto `minigame_audit`.

---

## Le altre voci aperte

Nessuna si scrive: vogliono un **asset** o una **tua decisione**.

- **Secondo foglio di reperti** — serve un'immagine nuova: gli atlanti dei
  reperti sono `.webp` (`artifact_atlas_catalog.gd`), e senza un disegno il
  formato non si estende.
- **Carta d'Europa** — **non serve un disegno.** La carta d'Italia è geometria
  vettoriale derivata da Natural Earth, dominio pubblico
  (`map_geometry_catalog.gd`), non un'immagine. Per l'Europa servono le coordinate
  dei poligoni dallo stesso dataset — un lavoro di dati, non d'arte, e quindi
  qualcosa che posso fare io se mi dai il via.
- **Accessibilità dei formati visuali** — le etichette identificano senza
  descrivere («Segnaposto A»), che è l'unica scelta che non regala la risposta.
  Ma chi usa un lettore di schermo **non può rispondere a una carta muta**. Vale
  già per grafici e circuiti. Va deciso, non subìto.

---

## Coda tua — il collaudo

I mondi sono cablati, verdi ed esportati: **gioca dall'inizio senza saltare
niente**. Non serve arrivare in fondo al primo giro: quello che cambia il lavoro
si vede nei primi sei mondi, e le ultime due domande si possono rimandare.

È anche l'unico modo per giudicare le voci di questo piano che una misura non
raggiunge — G-10 per prima, e il ritmo di tutte le altre.

In ordine di quanto cambiano il lavoro dopo:

1. **Il ritmo dei dialoghi.** Tre schermate sono troppe? I tic diventano
   tormentoni al terzo incontro? Gli itineranti fanno piacere o stancano? È la
   risposta che decide se riscrivo mille battute o nessuna.
2. **Il colpo 1 al mondo 5.** Ci arrivi sapendo già tutto (semi troppo espliciti)
   o non capisci cosa sia successo (troppo nascosti)? La taratura vale per tutti
   e sette i colpi: se sbaglia qui, sbaglia sei volte ancora.
3. **Il Ritrovo.** Sembra che vivano anche senza di te, o sembra che ti
   aspettassero?
4. **Le missioni.** Chiedere aiuto a un personaggio è meglio che leggere un
   cartello, o è solo più lento?
5. **Nonna Ersilia e la conta**: la senti nei primi cinque minuti? Ti resta in
   testa? È la chiave del finale: se non resta in testa, il mondo 24 non ha una
   serratura.
6. **Il Tredicesimo, dal mondo 17.** Fa paura senza farti male? Ti viene voglia
   di dargli retta almeno una volta? Se sembra solo un fastidio, il colpo 5 non
   funzionerà.

E le due prove che solo tu puoi fare: **hardware scolastico e tablet reale**
(touch, landscape e portrait, contrasto elevato, riduzione movimento).

---

## Invarianti di architettura

- **La presentazione non calcola.** Nessuna scena o UI calcola mastery,
  ricompense, gate o completamenti: li legge da `runtime_state()`.
- **Il runtime non contiene testi.** Nessun dialogo, nome, battuta o beat è
  scritto dentro una scena: tutto viene dal catalogo.
- **I dati non decidono la resa** (niente posizioni sullo schermo nei cataloghi)
  **e la resa non decide i dati** (nessuna scena inventa registri o proprietari).
- **Nessuna immagine contiene testo**: non è traducibile, non è leggibile ad alto
  contrasto e non si corregge senza rigenerarla.
- Un cambio di contratto aggiorna fixture e consumer **nello stesso commit**.
- Nessun abitante scrive mastery, energia, gate o ricompense.
- **Prima il contenuto, poi il cricchetto.** Stringere una soglia prima di aver
  scritto il contenuto obbliga a scrivere contenuto per far passare un test.
  All'inverso: **nessun cricchetto si allenta mai.**

---

## Decisioni vincolanti

Una proposta che le contraddice va discussa, non implementata.

1. **Fascia 10–13 anni.**
2. **Dodici materie obbligatorie**: 24 mondi = 12 materie × 2.
3. **Si sale di livello con tre materie** (italiano, matematica, inglese), **si
   finisce il gioco con dodici**. Il gate è sulla padronanza, non sul conteggio
   delle missioni.
4. **Un mondo è un LIVELLO, non una materia**: ogni mondo ha missioni di tutte le
   materie già incontrate.
5. **Rivisitazioni = ripasso mirato.** Consolidato = 3 corrette in sessioni
   distinte, con ≥ 3 giorni fra la prima e l'ultima.
6. **Scelta multipla: tetto 33%, target ~20%** (oggi 17%).
7. **Gli stadi di relazione avanzano su ciò che Eli impara**, mai su oggetti o
   valuta. Lo stadio 2 non richiede l'esame.
8. **Qualità dei contenuti**: vero, non ambiguo, istruttivo, alla portata, vario,
   nuovo a ogni livello, fedele al registro della materia. Cinque criteri su
   sette hanno un cricchetto; «vero» e «alla portata» li può verificare solo una
   rilettura umana.
9. **Almeno 15 item per argomento** (3 agosto 2026). Sotto quella soglia il
   ripasso spaziato dichiara consolidato ciò che è solo memoria di una schermata.
   Tenuto da `topic_density_audit`.
10. **Ogni banco al 20–30% di risposta non a scelta multipla** (4 agosto 2026).
   Una domanda a quattro opzioni si risolve per esclusione senza sapere niente;
   scrivere «rifrazione» in un campo vuoto no. Due formati liberi: `numeric_input`
   per i numeri, `short_answer` per le parole — quest'ultimo accetta le varianti
   dichiarate in `accept`, perché segnare sbagliata una risposta giusta è il modo
   più veloce per far smettere di provare. Il tetto del 30% dice l'altra metà:
   oltre, il banco diventa un dettato, e le domande di ragionamento — dove la
   risposta è una frase — restano giustamente a scelta multipla.
   Tenuto da `free_answer_audit`.

11. **Da una prova si esce sempre, e uscire costa** (4 agosto 2026). Un difetto
   di input non deve poter diventare un blocco totale: su tablet è già successo.
   La porta chiede conferma a due tocchi e costa 3 energie — quanto l'ingresso —
   e l'energia della prova non consegnata non arriva: senza prezzo, uscire e
   rientrare sarebbe il modo più veloce di ripescare domande finché non capitano
   le facili. Con zero energia si esce lo stesso. Gli argomenti visti restano nel
   Codex: il gioco non toglie a nessuno quello che ha imparato.
   Tenuto da `exercise_exit_audit`.

12. **Il Custode avanza in carattere, mai in potere** (4 agosto 2026). Nessun
   aiuto, nessun indizio, nessuna energia, nessuno sconto sul gate. Nel momento
   in cui il compagno diventa utile il bambino comincia a ottimizzarlo, e un
   compagno ottimizzato non è più un compagno. Tenuto da `pet_advanced_audit`.
   Include il terzo errore: al terzo errore sullo stesso argomento nella
   sessione corrente il Custode starnutisce — non aiuta, e NORA non lo commenta,
   perché lei non commenta mai un errore. Tenuto da `pet_struggle_relief_audit`,
   che ha già preso un doppio difetto: `sneeze` mancava dal catalogo, e
   `set_blocked()` interrompeva qualunque combinella a ogni fotogramma in cui un
   pannello restava aperto, non solo alla transizione — quindi anche uno
   starnuto avviato durante una prova sarebbe morto un fotogramma dopo.
   Include la lettura del mondo: *curioso* su un incontro non esplorato,
   *attento* vicino a uno Sbiadito — atmosfera, non informazione: entrambi già
   visibili a schermo. `near_unexplored`/`near_faded` erano dichiarati dal
   primo giorno e mai emessi finché non sono stati agganciati. Tenuto da
   `pet_world_awareness_audit`.

13. **Il diario racconta, non giudica** (5 agosto 2026). Mostra giorni giocati,
   prove superate e cosa sai adesso; non mostra percentuali di errore, non mette
   le materie in classifica e non dà obiettivi. **I giorni giocati sono
   cumulativi e non scendono mai**, come il legame del Custode: una serie che si
   azzera è una minaccia sul domani, non un resoconto di ieri, e questo progetto
   ha già deciso che non punisce chi torna dopo tre giorni. `streak` resta nello
   schema e non si mostra. Tenuto da `diary_audit` e `diary_panel_audit`.

14. **Una chiave del salvataggio senza lettori è un errore** (5 agosto 2026).
   Lo stesso difetto si è ripetuto quattro volte: `gifts`, `daily`, `modules` e
   (fuori dal salvataggio) i segnali `near_unexplored`/`near_faded` erano
   dichiarati insieme al progetto e costruiti solo a metà. Sembravano vivi
   perché stavano nello schema, e tutto ciò che li nominava era coerente con se
   stesso. Ora `save_schema_audit` pretende che ogni chiave compaia in almeno un
   file di produzione fuori dalla dichiarazione: le fixture degli audit non
   contano — `modules` stava in sette audit e in zero righe di gioco.

15. **La potenza vale contro il Silenzio, mai contro una domanda** (13 agosto
   2026). È la regola che tiene insieme G-1, G-2 e G-4: serie e moduli
   moltiplicano o aiutano sulla **mappa**, e non toccano mai mastery,
   copertura, ritenzione, gate o esami.
   *(Le cariche d'impulso stavano in questo elenco fino al 21 agosto 2026:
   l'impulso è stato tolto perché non aveva lavoro — vedi
   [FORZIERI_E_FRAMMENTI §9.2.1](docs/FORZIERI_E_FRAMMENTI.md). La regola non
   cambia, cambia l'elenco di chi la deve rispettare.)* Nel momento in cui una di queste tre
   sfiorasse una prova, il gioco comincerebbe a vendere l'apprendimento.
   Per la serie la tiene già `combo_audit`, e non con una rilettura del codice:
   registra due volte gli stessi esiti con energie diversissime e pretende la
   **stessa** padronanza e lo **stesso** conteggio di gate. Chi domani leggesse
   l'energia dentro il calcolo della padronanza lo troverebbe rosso lo stesso
   giorno.

### Guard-rail narrativi (i tre che si rompono per primi)

- **Non muore nessuno. Mai.** Né in scena, né fuori campo, né nel passato. Chi
  non c'è è *trattenuto dal Silenzio*: sospeso e recuperabile.
- **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
  il gate. Le tre Tracce decisive (mondi 12, 16, 19) hanno un beat di ripiego.
- **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.

---

## Vincoli

- Nessun nuovo banco composto quasi solo da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
- Nessuna ulteriore profondità combinatoria: 33 milioni bastano.
- Le spiegazioni del **lessico** (inglese, italiano) restano come sono: lì
  rivedere l'accoppiata *è* il ripasso.
- **Nessuna voce di questo piano allunga la campagna.** 21,1 ore misurate: chi
  aggiunge qualcosa che costa tempo lo misura con `time_cost_probe` prima e dopo.

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. La build è
   esportata e giocabile: da qui in poi questo rischio si chiude solo giocando,
   e ogni giorno che passa senza collaudo è lavoro fatto su un'ipotesi.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta.
3. **Il mondo 1 è già stretto sui budget**: 2789/3500 nodi e 311/500 ms. **Contare
   i nodi prima di aggiungerli**, non dopo. Vale in modo particolare per G-6: un
   ponte camminabile è una scena nuova, non un pannello.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
   di margine. Un rosso va sempre riverificato in isolamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione,
   è una misura: la suite intera è passata da **105 a 1295 secondi** — dodici
   volte — con sei audit rossi, e un singolo audit da due secondi ne ha impiegati
   oltre quattrocento. Quattro processi Godot in contemporanea, tre non miei. I
   rossi erano tutti in audit che caricano scene, e nessuno toccava le cose
   cambiate: era contesa, non regressione.

   **Regola operativa**: chi sta per lanciare `npm run audit:godot` lo dice qui
   prima. Chi vede la suite andare oltre i ~150 secondi la ferma. Un audit
   singolo (`node scripts/run-godot-audits.mjs <nome>`) si può sempre eseguire —
   è il giro completo che va serializzato.
6. **C-16 passo 3 (rimozione di Phaser) resta sospeso.** Va fatto quando
   nient'altro è in volo, altrimenti una regressione somiglierà a un bug del
   mondo abitato.

---

## Rituale di export — cancello di ogni lotto

```powershell
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web    # verifica che i quattro valori combacino
npm run audit:godot
```

Il bump di `cacheVersion` non è cosmetico: è ciò che fa scadere la cache PWA.
Senza, un tablet che ha già aperto il gioco continua a servire il PCK vecchio.

**Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto:
stai giudicando la build precedente.
