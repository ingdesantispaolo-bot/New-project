# Runtime outdoor nativo Godot

Stato al 22 luglio 2026: la migrazione runtime è conclusa. Questo documento
sostituisce il vecchio contratto Phaser → Godot.

## Flusso scene

`boot_menu.tscn → outdoor_world.tscn ⇄ hub.tscn`

- `GIOCA` apre il mondo;
- il portale entra nella nave;
- `TORNA AL MONDO` dalla nave riapre il mondo;
- `PAUSA` (o `Esc`) apre il menu di pausa, da mondo e da nave;
- non esistono redirect, ricariche pagina, `returnUrl` o result file esterni.

## Il menu di pausa (21 agosto 2026)

`PauseMenuPanel` e' un solo pannello condiviso da `outdoor_world.gd` e
`hub_scene.gd`: stessi comandi, stesso ordine, in tutte e due le scene. Fino al
20 agosto il ritorno al menu principale esisteva **solo nella nave**, e riavviare
o cambiare giocatore non esistevano da nessuna parte.

| Comando | Che cosa fa | Che cosa NON tocca |
|---|---|---|
| `RIPRENDI` | toglie `get_tree().paused` e chiude | — |
| `RIAVVIA IL MONDO` | `clear_world_resume` + rientro in `outdoor_world.tscn` | incontri risolti, tesori, maestria, frammenti |
| `CAMBIA GIOCATORE` | `ProfilePanel` -> `set_active` -> entra nel mondo di quel bambino | il salvataggio di chi esce, gia' scritto all'apertura |
| `MENU PRINCIPALE` | `boot_menu.tscn` | niente: la partita e' gia' salvata |

Tre regole che il pannello non negozia:

- **aprirlo salva.** Da qui si esce in tre modi e tutti e tre cambiano scena:
  farlo una volta sola all'apertura e' l'unico modo per non doverlo ricordare
  tre volte, e per poter scrivere sul pannello che la partita e' al sicuro;
- **riavviare e' rifare il giro, non rifare la scuola.** Si cancella solo la
  posizione e l'ora (`resume`). Restituire i tesori renderebbe il riavvio il
  modo piu' veloce di guadagnare frammenti che il gioco abbia;
- **il cambio di giocatore non passa dal menu d'avvio.** Due fratelli che si
  alternano lo fanno dieci volte in un pomeriggio, e ogni passaggio in piu' e'
  un motivo per non farlo e giocare sopra la partita dell'altro.

Il pannello non si apre sopra una prova, un dialogo o un minigioco: quelli hanno
gia' la loro uscita, e due tasti «esci» sovrapposti insegnano che uno dei due
perde il lavoro. Le viste reali stanno in `artifacts/pausa/`
(`pause_menu_render_probe.gd`).

## Stato

- `GameSaveManager` è la sola fonte persistente e salva in
  `user://eli-quest-save.json`;
- `NativeWorldState` crea seed, avatar fallback e collezioni transitorie della
  sessione;
- `OutdoorGameplay` possiede economia, missioni, mastery, progressione,
  bottega, NORA e report;
- `OutdoorRuntimeState` è una vista read-only consumata dall'HUD.

La migrazione dei vecchi JSON resta idempotente dentro `GameSaveManager`, ma
non è un bridge e non viene eseguita tramite JavaScript.

## Contenuti e mondo

Il mondo conserva 64 chunk logici (`-4..3`), streaming visivo 3×3, sei biomi,
giorno/notte, incontri, enigmi, tesori e apparato. Gli esercizi si aprono
direttamente con `ExercisePlayer`; gli esiti aggiornano immediatamente il save.

La parità storica del generatore è verificabile offline con
`data/parity-fixtures.json` e `fixture_audit.gd`. Fixture, audit e render probe
sono esclusi dal PCK di release.

## Export

Il preset Web usa Godot 4.7.1 Compatibility senza thread. Il comando canonico è:

```powershell
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web "..\public\godot\outdoor\index.html"
```

La root Web reindirizza a questo export e non carica bundle Phaser.
