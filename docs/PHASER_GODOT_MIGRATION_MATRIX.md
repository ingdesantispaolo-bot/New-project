# Matrice C-09 · Phaser → Godot

| Funzione | Sostituto Godot | Stato | Audit |
|---|---|---:|---|
| Generazione chunk outdoor | `outdoor_generator.gd` + parity fixtures | migrata | fixture audit |
| Streaming 8×8 | `chunk_manager.gd` | migrata | editor scan |
| Missioni | `OutdoorGameplay` + `ContentManager` | migrata | C-02/C-04 |
| Esame finale | `OutdoorGameplay` + `ProgressionManager` | migrata | round-trip |
| Save e stato sessione | `GameSaveManager` + `NativeWorldState` | nativo; bridge rimosso | C-03/C-16 |
| Progressione livelli | `ApparatusConfig` + `ProgressionManager` | migrata | C-05 |
| HUD/marker | `OutdoorHud` + `OutdoorInteractionMarker` | componente pronto | gate integrazione |
| Nave/apparati | `HubScene` + `HubController` + 7 ponti WebP | migrata | C-06 + ship presentation/render probe |
| Narrazione NORA | `NarrativeManager`, HUD e diario nave | migrata e collegata | C-07 |
| Report locale | `LocalProgressReport` persistito nel save | migrato e collegato | C-08 |
| Redirect missioni verso Phaser | nessun redirect nel loop Godot | eliminata | round-trip |
| Contenuto esercizi (12 materie) | banchi JSON Godot + generatore matematica nativo | migrato e incluso nella scala | validazione bake + C-04/C-05 |
| Bottega/cosmetici (`RewardCatalog`/`RewardSystem`) | `RewardCatalog.gd` (53 item) + `RewardManager.gd` + `OutdoorShopPanel`, integrati in `OutdoorGameplay` | migrata (C-14) | `reward_audit.gd`, `shop_presentation_audit.gd`, `outdoor_presentation_audit.gd`; outfit/accessori/pet/Bit/emblemi hanno resa live, hook gameplay NORA e scene restauri restano esplicitamente successivi |

Regola di rimozione: una voce può essere eliminata dal fallback Phaser solo dopo
fixture parity, round-trip e smoke test Web verdi.

## C-16 · Spegnimento runtime Phaser

Decisione utente (2026-07-22): **ribaltare il boot su Godot root**. Sequenza:

| Passo | Cosa | Stato |
|---|---|---|
| 1 | Godot autosufficiente: save nativo autoritativo, boot standalone che non azzera l'economia, uscita senza rimbalzo a Phaser | ✅ editor e audit (`c16_audit`, round-trip) verdi |
| 2 | Root del deploy = export Godot + menu title nativo | ✅ `boot_menu.tscn` è `run/main_scene`; `GIOCA` apre il mondo |
| 3 | Rimozione runtime Phaser dalla produzione | ✅ eliminati `phaser.html`, input/chunk Vite e escape `?shell=phaser`; la build non compila né distribuisce Phaser |
| 4 | Navigazione nativa completa | ✅ `boot → mondo → hub/nave → mondo`, coperta da `boot_navigation_audit.gd` |

I sorgenti TypeScript storici e le dipendenze Phaser/Howler sono un archivio
offline per fixture, bake e regressioni: non hanno entrypoint Web, non entrano
nel deploy e non sono referenziati dal runtime Godot. Non vengono cancellati
finché il manifest conserva asset narrativi e generatori sorgente non coperti.

Il bridge runtime `OutdoorSaveBridge`, i redirect e il ramo `returnUrl` sono
stati rimossi. Gli audit/probe e le fixture di parità sono esclusi dal PCK di
release tramite `export_presets.cfg`.

Precondizione risolta al passo 1: il gap del round-trip `godotSave` (Phaser non
rilegge la progressione ricca, solo delta energia/frammenti) diventa **irrilevante**
perché Godot possiede e persiste il proprio save canonico; l'economia non è più
sovrascritta da un handshake Phaser assente in modalità standalone.
