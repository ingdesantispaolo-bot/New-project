# Triage feedback playthrough C-P6

Analisi dei 13 elementi da correggere, divisi per proprietà. **Opus** = contenuti/
didattica; **Codex** = grafica/runtime/mecccaniche; **Design** = decisione di
prodotto (utente). Aggiornato al 24 luglio 2026.

| # | Elemento | Proprietà | Stato / azione |
|---|---|---|---|
| 1 | Elementi grafici fuori contesto che distraggono | **Codex** | pulizia visuale della mappa |
| 2 | Fiumi con sorgente/cascata coerenti; attraversabili solo con ponti da costruire | **Codex** + Design | terreno/idro; il "ponte via esercizio" ha già il contratto enigma (`build_enigma`, `theme`) |
| 3 | Sfera completata → sparisce anche graficamente | **Codex** | il dato è già persistito (O-P0.4 `completedEncounterIds`/`worldProgress`); resta la resa |
| 4 | La risposta giusta non deve essere sempre la prima | **Opus** | ✅ **verificato pulito**: banchi 25.6% in prima posizione (ideale 25%), matematica mescola (Fisher-Yates). Nessun bug di contenuto; se osservato, è resa/ordinamento (Codex) |
| 5 | Elementi che sembrano importanti ma inutili (albero percorsi, nucleo antico) | **Codex** | rimuovere o dare funzione |
| 6 | Equipaggiamento realmente utile (torcia/notte buia, falce/erba alta) | **Codex** + Design | nuova meccanica; Opus può definire dove un gate di equipaggiamento è didatticamente sensato, ma non è un fix di contenuto |
| 7 | Nemici per livello che ostacolano la missione | **Codex** + Design | nuova meccanica da studiare |
| 8 | Sprite personaggio AAA (movimento/combattimento) | **Codex** | arte/animazione |
| 9 | Enigmi: nessuna ricompensa su errore, feedback negativo, cooldown fra i tentativi, energia per partecipare | **Opus** + **Codex** | no-reward-su-errore GIÀ vero (`record_mission` non premia se fallita); costo energia GIÀ (`_charge_exercise_entry`). NUOVO: cooldown anti-tentativi-casuali (policy Opus + UI Codex). NB: il cooldown è **tra** i tentativi, non un timer durante l'esercizio → il guardrail "ragionamento senza tempo" resta valido |
| 10 | Qualità delle domande cresce e tarata per livello | **Opus** | difficoltà già scala 1→4 col livello (`target_difficulty`) + mastery; da rivedere la **qualità** (distrattori, profondità) per fascia alta |
| 11 | Non solo scelta multipla: minigiochi/sfide con le competenze — *massima attenzione* | **Opus** + **Codex** | `build_varied_mission` (≤1/3 MC) esiste ma non è il default live; renderer interattivi (classificazione/hotspot/grafico/circuito/codice) hanno contratto+validatore, servono live |
| 12 | Elementi sopra la mappa integrati e coerenti col livello | **Codex** | resa |
| 13 | Gli esercizi indagano ma **non insegnano**: atlante e NORA devono insegnare le competenze — *cruciale* | **Opus** + **Codex** | fondazione già pronta: `KnowledgeCodex` (122 voci: spiegazione, esempio, errore tipico, strategia). Manca: (a) voci più **istruttive** (mini-lezione, non solo spiegazione breve); (b) NORA che **pre-insegna** al primo incontro e **ri-insegna** sull'errore; (c) UI atlante consultabile (C-P4, Codex) |

## Sintesi per Opus

- **#4**: chiuso (nessun problema di contenuto).
- **#10**: rivedere qualità/distrattori nelle fasce alte (rilevante ma incrementale).
- **#11**: portare `build_varied_mission` come default live e ampliare i formati
  non-MC (coordinato con i renderer Codex).
- **#13** (prioritario): rendere il `KnowledgeCodex` realmente istruttivo e definire
  gli agganci di NORA (pre-teach / re-teach) e le regole di consultazione atlante.

## Sintesi per Codex

1, 3, 5, 8, 12 (resa) · 2, 6, 7 (terreno/meccaniche nuove, con Design) · 9 UI
cooldown/feedback · 11 renderer interattivi · 13 UI atlante consultabile (C-P4).
