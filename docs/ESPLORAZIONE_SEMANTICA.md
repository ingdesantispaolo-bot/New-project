# Esplorazione semantica e luoghi disciplinari

## Decisione

Gli edifici generati funzionano se diventano **luoghi riconoscibili**, non
contenitori per dodici pulsanti. Ogni mondo riceve quindi una sola **Casa del
mestiere** dedicata alla materia guida; le altre discipline compaiono come siti
e strumenti nel paesaggio. La casa offre allenamento a costo ridotto, gli
oggetti preparano o ospitano applicazioni brevi, landmark e varchi sostengono le
prove più importanti.

La prima applicazione è la Radura Accademia:

- **Casa del Conto**: edificio-materia, porta e sessione restano interattive in
  Godot;
- **Stazione del Conto**: oggetto esterno che comunica raggruppamento e misura;
- **sentieri, regioni, strumenti e varchi**: diventano socket di attività che il
  Director può scegliere perché coerenti con formato e materia.

## Costellazioni, non dispersione

Ogni socket dichiara `id`, posizione, ruolo, tag di affordance, costellazione,
capacità, profondità di percorso e segnale di scoperta. Il Director assegna un
punteggio ai luoghi, penalizza il riuso dello stesso sito e della stessa
costellazione, e mantiene ogni prova entro 420 unità dal luogo che dichiara.
Solo un'emergenza tecnica può riattivare il vecchio fallback radiale.

Una buona sequenza esplorativa ha tre battute:

1. **orientamento** — una prova leggibile vicino a sentiero, casa o primo
   strumento;
2. **applicazione** — due o più tappe presso oggetti e regioni coerenti;
3. **trasformazione** — un enigma presso landmark, ponte, frana o cancello che
   modifica la percorribilità o l'aspetto del mondo.

Il segnale di scoperta dipende dal luogo: `proximity` per una deviazione sul
sentiero, `local_clue` per uno strumento, `distant_signal` per edificio,
landmark e varco. In questo modo il giocatore può prima vedere, poi capire, poi
raggiungere.

## Famiglie di oggetti generati

| Materia/funzione | Oggetti efficaci | Azione suggerita |
|---|---|---|
| Matematica | stazione di conteggio, bilancia, ruota di misura | raggruppa, stima, misura |
| Lingue | torchio, leggìo, pietre-eco, bacheca di glifi | ordina, abbina, ricostruisci |
| Scienze | terrario, vaschetta, sensore, pod biologico | osserva, classifica, completa un ciclo |
| Storia | archivio, stele, tavolo stratigrafico | confronta fonti, metti in ordine |
| Coding/logica | banco-relè, automa, rete di nodi | crea una sequenza, trova il guasto |
| Fisica/elettronica | bobina, circuito, rampa, banco ottico | misura, collega, prevedi |
| Musica | organo di cristallo, campane, tavolo ritmico | ascolta, abbina, componi |
| Geografia | tavolo cartografico, boe, stazione climatica | orienta, leggi un grafico, traccia una rotta |

Non tutti devono essere edifici: troppi interni spezzano il ritmo e trasformano
il mondo in un menu. Gli oggetti piccoli mantengono la prova dentro il paesaggio
e sono più economici da variare, spostare e sostituire.

## Regola per le immagini generate

L'immagine controlla silhouette, atmosfera e anticipazione della funzione. Non
controlla mai domanda, risposta, costo, collisione, stato o ricompensa: questi
restano dati e nodi di gioco. Numeri, testi o quantità che devono essere esatti
vanno disegnati o sovrapposti dal codice. Il pilot lo conferma: una prima
generazione della stazione non rispettava i due gruppi da cinque ed è stata
corretta, ma l'asset resta comunque un'indicazione visiva, non la fonte della
verità didattica.

Ogni asset deve avere silhouette leggibile a 900×600, fondo trasparente,
ingresso libero, nessun testo incorporato e fallback vettoriale se il file non
è disponibile.

## Criteri di collaudo

- almeno sei socket con affordance in ogni mondo;
- almeno tre costellazioni diverse per gli eventi che alimentano il gate;
- nessun evento nel fallback radiale nelle fixture dei 24 mondi;
- metadati del luogo conservati dal Director fino al payload della scena;
- edificio e oggetti non sovrapposti a residenti, HUD o trasformazioni locali;
- prova visiva a 900×600 e audit di interazione/building verdi prima di estendere
  la pipeline agli altri mondi.
