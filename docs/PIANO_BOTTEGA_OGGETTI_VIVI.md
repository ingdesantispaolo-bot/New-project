# Eli Quest — Piano della bottega e degli oggetti vivi

> Piano autoritativo per integrare gli 87 oggetti del catalogo con esplorazione,
> nave e trama. Il principio non negoziabile resta quello del progetto: nessun
> acquisto modifica domande, padronanza, copertura, ritenzione, esami, gate o
> storia principale.

## 1. Tesi

Il Silenzio separa una cosa dal suo significato. La bottega deve compiere il
gesto contrario: ricostruire il legame fra **provenienza, funzione e memoria**.

Per questo i frammenti non comprano merce nuova. Restaurano ciò che Eli ha già
incontrato nei mondi. Un oggetto è completo soltanto quando:

1. viene incontrato nel luogo da cui proviene;
2. viene catalogato a bordo;
3. viene restaurato con i frammenti;
4. viene preparato, esposto o indossato;
5. viene usato in un contesto coerente;
6. conserva una traccia permanente di quell'uso.

Il ciclo attuale si ferma quasi sempre al punto 4. Questo piano implementa i
punti 5 e 6 senza trasformare 87 oggetti in 87 bonus numerici.

## 2. Contratti vincolanti

1. **La competenza non si vende.** Lo stato degli oggetti non scrive mai
   `mastery`, `masteryByTopic`, `coverageThisLevel`, `gateClearedLevel`, energia,
   apparati o completamenti obbligatori.
2. **La storia portante resta intera.** Le risonanze aggiungono testimonianze e
   collegamenti; nessun beat dei 24 mondi richiede un acquisto.
3. **Ogni promessa deve avere una resa.** Ogni voce del catalogo dichiara un
   verbo, un metodo, gli eventi che la usano e la traccia che lascia.
4. **Uso leggibile prima della spesa.** La scheda della bottega mostra cosa farà
   l'oggetto e non una descrizione vaga.
5. **Niente manutenzione punitiva.** Oggetti permanenti, nessuna rottura, fame,
   decadimento, consumo o costo per cambiare configurazione.
6. **Una sola fonte di verità.** Possesso ed equipaggiamento restano in
   `cosmetics`; la memoria d'uso vive in `artifactJourney` nel save canonico.
7. **Bit non è un terzo compagno.** NORA parla e Bit agisce: Bit è il suo
   attuatore nelle riparazioni e negli esperimenti. La livrea condivisa rende
   leggibile il collegamento senza confondere Bit con il Custode.

## 3. Modello dati

Ogni oggetto riceve a runtime un profilo semantico:

```gdscript
{
    "id": "accessory-compass",
    "family": "accessory",
    "verb": "segnare",
    "method": "orientare",
    "use": "Lascia un segnavia personale durante una spedizione.",
    "events": ["expedition", "treasure", "mystery"],
    "sourceWorld": 0,
    "resonanceWorld": 0,
    "trace": "Rotte ricordate"
}
```

Il salvataggio conserva soltanto fatti compatti, mai testi:

```gdscript
"artifactJourney": {
    "items": {
        "accessory-compass": {
			"acquired": true,
			"acquiredWorld": 1,
            "uses": 4,
            "worlds": [1, 4, 13],
            "events": ["expedition:1", "treasure:..."],
            "resonances": [],
            "lastWorld": 13
        }
    },
    "resonances": ["accessory-scarf:13"]
}
```

Gli eventi sono idempotenti: ricaricare una scena o riaprire lo stesso forziere
non fa crescere artificialmente la storia dell'oggetto.

## 4. Famiglie meccaniche

### 4.1 Ricordi — dodici ponti fra i due cicli

I mondi `1…12` risuonano con `13…24`. Il Ricordo nato nel mondo `n` trova una
seconda funzione nel mondo `n + 12`; quello del secondo ciclo, riportato nel
primo, compie il percorso inverso. Sono 24 attivazioni su un solo sistema.

La prima vertical slice è Radura Accademia ↔ Deserto delle Orbite:

- la Sciarpa fotonica, Ricordo del mondo 1, risuona nel mondo 13;
- l'Anello di rapporto, Ricordo del mondo 13, risuona nel mondo 1;
- la risonanza viene registrata una volta, lascia una traccia e produce una
  breve osservazione non necessaria alla trama principale.

La vertical slice è ora estesa a tutti i Ricordi. Le dodici coppie condividono
una firma visiva ma hanno direzioni opposte: un Ricordo del primo ciclo porta
il metodo alla scala più complessa del secondo; quello del secondo ciclo lo
riporta alle fondamenta. Ognuno dei 24 contratti possiede un comando, una
consegna, una lettura di NORA e una traccia propri. Non esiste più un testo di
fallback per una voce del catalogo.

### 4.2 Outfit — ruolo e patina

Gli outfit non danno statistiche. Accumulano mondi visitati e tre stadi di
patina (`1`, `3`, `6` mondi distinti). Le uniformi nominate dichiarano un ruolo;
le livree cromatiche reagiscono soprattutto al mondo d'origine. La bottega rende
leggibile la biografia della tuta. Gli undici outfit hanno inoltre un'identità
sociale distinta: nel dialogo ordinario ogni abitante può riconoscerli una sola
volta. La battuta cambia sia con lo stadio di patina sia con il registro della
persona (burbero, caloroso, sognante e così via), ma viene incorporata nella
pagina già prevista e non interrompe richieste, ritorni di missione o contenuti
didattici. Cambiare outfit permette una nuova osservazione, non una reputazione.

### 4.3 Accessori — verbi da campo

Ogni accessorio dichiara un verbo diverso: osservare, sincronizzare, segnare,
conservare, ricostruire, ascoltare, stabilizzare, superare, collegare. Oltre agli
eventi reali già esistenti, l'accessorio equipaggiato genera in ogni mondo una
rotta facoltativa di tre tappe fisiche. La grammatica è comune, ma cambiano
geometria, consegne e significato del gesto: il Visore triangola osservazioni,
la Sciarpa ripete un ritmo, la Bussola rileva una rotta, lo Zaino cataloga un
campione, la Corona ricostruisce causa-gesto-esito, l'Antenna sintonizza tre
bande, le Ali compensano una deriva, il Jetpack collega vettori e l'Aureola
ricostruisce una relazione. Completare la rotta lascia una traccia per quella
coppia accessorio-mondo e non concede premi o scorciatoie.

### 4.4 Custode — forme equivalenti, azioni diverse

Le undici forme conservano identica economia e identico accesso ai contenuti.
Cambiano il modo in cui il Custode affronta tane, tracce e reperti. Nelle tane
ognuna percorre davvero tre punti secondo un metodo proprio: fiuto radente,
bordo alto, prova delle fessure, scintilla di soglia, traiettoria interrotta,
perimetro orbitale, parallasse breve, rifrazione doppia, luce di ritorno, veglia
della soglia o lettura delle incisioni. Impronte, verbo e osservazione di NORA
rendono il metodo leggibile, mentre durata interna, probabilità ed esito della
tana restano identici. Ogni forma reagisce inoltre a una selezione coerente di
spedizioni, tesori, reperti o campi; la biografia non cresce per semplice
inerzia.

### 4.5 Emblemi — promesse di metodo

Gli emblemi osservano un comportamento esplorativo coerente (costanza,
precisione, coordinamento, curiosità, attenzione alle fonti). Non pagano premi:
la loro traccia e la loro evoluzione visiva sono il riconoscimento. Ogni
emblema formula una promessa esplicita e chiede tre testimonianze idempotenti:
tre mondi per la Stella, tre gesti precisi per il Fulmine, tre riparazioni per
la Corona, tre osservazioni per l'Atomo e tracce provenienti da tre mondi per la
Pergamena. Sul corpo di Eli compaiono tre sigilli; al completamento un anello li
unisce. La promessa completa non concede valuta, statistiche o certificazioni.

### 4.6 Moduli e strumenti — preparazione e gesti

I sei moduli mantengono la bardatura limitata. La memoria d'uso registra quando
una scelta è entrata davvero in gioco. I cinque strumenti gratuiti registrano i
varchi su cui Eli li ha usati: possederli continua ad aprire automaticamente,
ma il gesto non resta più un booleano invisibile.

Il Taccuino del cambio va ritarato in un lotto separato: il moltiplicatore
globale rende l'investimento dominante per chi punta al catalogo completo.

### 4.7 NORA e restauri — sette laboratori di interpretazione

Ogni restauro apre il laboratorio della propria stanza: Ponte Centrale,
Giardino Biologico, Reattore, Sala Comando, Camera di Risonanza, Nucleo Dati e
Archivio dei Glifi. Il laboratorio propone tre decisioni interpretative, ognuna
con due letture entrambe valide. Le scelte compongono una sintesi personale
persistente: non esiste soluzione corretta, non si assegnano premi e non si
alterano esercizi, padronanza o gate.

La sintesi resta leggibile nella stanza e può essere ricomposta. Una nuova
sessione sostituisce consapevolmente quella precedente senza moltiplicare gli
usi dell'oggetto: il primo completamento entra nella biografia del restauro,
le riletture trasformano soltanto la sua memoria riflessiva. I quattro apparati
NORA continuano inoltre a registrare riparazioni, indagini e visite al Ponte
Centrale.

## 5. Sequenza d'implementazione

### Lotto A — fondazione (implementato)

- `ArtifactJourney`: profilo completo per ogni voce, registrazione idempotente,
  patina, risonanze `1↔13 … 12↔24` e riepilogo UI;
- schema save e migrazione non distruttiva;
- fatti: acquisto; eventi di spedizione, forziere, riparazione, tana, uso di uno strumento
  e visita a una stanza restaurata;
- bottega: verbo, uso promesso, metodo, mondi attraversati e traccia;
- Sciarpa utilizzabile sia come accessorio sia come primo Ricordo;
- chiarimento diegetico del rapporto NORA/Bit;
- audit su tutti gli 87 oggetti e sui divieti didattici.

### Lotto B — vertical slice giocata (implementato)

- punto di risonanza visibile nei mondi 1 e 13;
- gesto ambientale della Sciarpa e dell'Anello di rapporto;
- una reazione di NORA, una del Custode e una traccia persistente condivisa;
- banco fisico nel Ponte Centrale che mostra le due risonanze;
- resa visiva dei tre stadi di patina.

### Lotto C — estensione data-driven (implementato)

- undici coppie di mondi restanti (gia' abilitate dal sistema generico);
- profili di evento distinti per outfit, accessori, forme, emblemi, moduli e NORA
  (gia' implementati);
- verbi bespoke dei nove accessori, con rotte fisiche persistenti (implementato);
- comportamenti delle undici forme nelle tane, con traiettorie e letture
  distinte ma risultati equivalenti (implementato);
- promesse dei cinque emblemi, tre testimonianze e resa visiva (implementato);
- reazioni sociali degli undici outfit, sensibili a patina e registro NPC
  (implementato);
- sette laboratori della nave, tre decisioni e sintesi ricomponibile
  (implementato).

### Lotto D — risonanze autoriali (implementato)

- ventiquattro gesti distinti, uno per Ricordo;
- dodici firme geometriche reciproche, orientate secondo il viaggio `1↔13 … 12↔24`;
- letture specifiche che nominano ciò che il metodo conserva e come cambia scala;
- traccia fisica persistente sul punto di risonanza;
- audit senza fallback, con copertura `24/24` e confine didattico invariato.

## 6. Criteri di accettazione

- 87/87 oggetti hanno `verb`, `method`, `use`, `events` e `trace` non vuoti.
- I 24 Ricordi, inclusa la Sciarpa, formano dodici coppie reciproche.
- I 24 Ricordi hanno gesto, consegna, lettura e traccia unici; ogni coppia
  condivide una firma visiva e inverte la direzione, senza fallback generici.
- Un evento ripetuto con lo stesso id non aumenta due volte il contatore.
- Un oggetto non posseduto o non attivo non ottiene usi di campo.
- Ogni acquisto registra il punto di inizio della biografia dell'oggetto.
- La scheda della bottega mostra uso e traccia anche prima dell'acquisto.
- Nessun evento di oggetto modifica energia, padronanza, gate, esami o livello.
- I vecchi salvataggi ricevono `artifactJourney` senza perdere campi esistenti.
- La risonanza 1↔13 funziona in entrambe le direzioni ed è persistente.
- I nove accessori hanno una rotta in tre tappe, richiedono spostamento e
  registrano una sola conclusione per mondo senza modificare i campi protetti.
- Le undici forme hanno metodi e traiettorie distinti nelle tane; nessuna forma
  modifica esito, probabilità, durata interna o accesso al contenuto.
- I cinque emblemi dichiarano promesse distinte, contano tre testimonianze
  coerenti e le mostrano sul personaggio senza concedere ricompense.
- Gli undici outfit ricevono riconoscimenti sociali distinti e idempotenti, mai
  durante richieste o ritorni di missione e senza alterare l'arco degli NPC.
- I sette restauri aprono il proprio laboratorio esatto, con tre decisioni a
  due letture; ricomporre la sintesi sostituisce la precedente senza aumentare
  gli usi né modificare campi di progressione o ricompensa.
