# Piano di playtest e validazione didattica (O-P6)

Stato: bozza operativa. Obiettivo: verificare con persone reali che Eli Quest
insegni davvero, sia accessibile e non induca ansia o grinding. La telemetria è
**solo locale** (`ValidationReport`): nessun dato lascia il dispositivo.

## Partecipanti

- **Studenti** (target di lancio: primaria; poi secondaria-1): 8–12 per fascia,
  mix di livelli di partenza. Sessioni da 20–30 minuti.
- **Docenti**: 3–5, per giudicare correttezza didattica, linguaggio e progressione.
- **Revisori disciplinari**: almeno 1 per area (matematica/scienze, lingue,
  educazione civica), per validare contenuti e prove di trasferimento.

## Cosa misuriamo (dal report locale)

Per ogni partecipante, alla fine della sessione si esporta `ValidationReport.build`:

| Dimensione | Domanda a cui risponde | Soglia di attenzione |
|---|---|---|
| Copertura | Ha incontrato abbastanza argomenti? | < 0.4 su una materia esercitata |
| Confidenza | Abbiamo evidenza sufficiente? | < 0.3 con molte sessioni |
| Ritenzione | Ciò che ha imparato regge? | consolidati ≪ visti |
| Aiuti | Usa il Manuale quando serve? | 0 aiuti + molti errori |
| Tempo | Quanto costa in tempo un livello? | outlier molto sopra la mediana |
| Fiducia NORA | La relazione cresce con lo sforzo? | ferma nonostante perseveranza |

## Protocollo per sessione

1. Profilo nuovo (save pulito) con fascia/curriculum del gruppo (`LearningConfig`).
2. Osservazione silenziosa (think-aloud incoraggiato, mai suggerito).
3. Note su: punti di blocco, frustrazione, momenti di comprensione, uso del
   Manuale, chiarezza dei briefing/debrief di NORA.
4. Esporto il report locale e la traccia del `progressReport`.
5. Breve intervista: cosa hai imparato? cosa non era chiaro? cosa ti è piaciuto?

## Guardrail verificati automaticamente (prima del playtest umano)

`guardrails_audit` deve essere verde: ragionamento senza timer, la pratica non
farma il gate, la padronanza cambia solo con gli esercizi, i premi non aprono il
gate al posto della competenza. Questi non si "playtestano": sono invarianti.

## Revisione disciplinare dei contenuti

Per ogni materia il revisore controlla, sui banchi e sulle voci del Manuale
(`KnowledgeCodex`): correttezza, assenza di ambiguità (già filtrata da
`ExerciseInteraction.validate`), adeguatezza alla fascia, qualità delle prove di
trasferimento (`WorldLessonCatalog.transferTest`).

## Criteri di uscita

- Nessun blocco impossibile da superare senza aiuto esterno in 3 sessioni su 3.
- Copertura e ritenzione mediane accettabili sui primi 4 mondi.
- Zero errori disciplinari segnalati dai revisori sui contenuti di lancio.
- Nessun segnale ricorrente di ansia legato a tempo o punizione.

## Iterazione

Le soglie sopra sono di lavoro e vanno ritarate con i primi dati reali (incluso
il target scelta multipla ≤33% e la definizione di "topic consolidato"). Ogni
modifica di contenuto o difficoltà richiede di rieseguire gli audit didattici
prima di un nuovo giro di playtest.
