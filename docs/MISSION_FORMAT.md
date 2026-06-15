# Mission Format

Le missioni sono definite in `src/data/missions.ts` con il tipo `MissionDefinition`.

## Campi Principali

- `id`: identificativo stabile.
- `title`: titolo mostrato nel gioco.
- `description`: descrizione breve.
- `openingDialogueId`: dialogo iniziale.
- `objectives`: obiettivi della missione.
- `requiredItems`: oggetti richiesti.
- `puzzles`: ID dei puzzle collegati.
- `dialogues`: ID dialoghi disponibili.
- `competencies`: competenze allenate.
- `rewards`: badge narrativi.
- `nextMissionId`: missione successiva opzionale.

## Obiettivi

Ogni obiettivo puo avere:

- `id`
- `label`
- `description`
- `requiredFlags`
- `unlocksFlag`
- `competencies`

Le scene completano un passaggio chiamando:

```ts
missionEngine.completeObjective("nomeFlag", ["competenza.id"], 14);
```

## Aggiungere Una Missione

1. Aggiungere una voce in `missions`.
2. Creare puzzle in `src/data/puzzles.ts`.
3. Aggiungere dialoghi in `src/data/dialogues.ts`.
4. Creare o riusare scene Phaser.
5. Collegare gli hotspot della nuova area al `MissionEngine`.

Per missioni ambientali complesse si puo creare un file dati dedicato, come `src/data/greenhouse.ts`, `src/data/numberFactory.ts` o `src/data/wordArchive.ts`, lasciando al `MissionEngine` solo progressione, competenze, salvataggio e diario.

## Regola Di Design

Un puzzle dovrebbe aggiornare almeno una competenza e almeno un flag narrativo. In questo modo progressione, diario e gameplay restano sincronizzati.
