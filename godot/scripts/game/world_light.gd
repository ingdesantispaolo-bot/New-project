class_name WorldLight
extends RefCounted

## **La luce che torna, e la potenza che cresce.** (7 agosto 2026)
##
## Nasce dal verdetto di un collaudo vero: «il gioco è noioso e poco stimolante,
## per non dire faticoso». Misurando, il difetto era strutturale e non di
## contenuto: **il ciclo di ricompensa durava dai 27 ai 72 minuti**. Per aprire
## il mondo 1 servivano 41 esercizi, per il mondo 3 centotredici, e in mezzo non
## succedeva niente — l'esame era l'unico momento in cui il gioco cambiava. Per
## un bambino di undici anni quel ciclo deve chiudersi ogni due o tre minuti.
##
## L'idea è del committente, ed è migliore di quella che avevo proposto io: non
## una minaccia che avanza, ma **una luce che torna**. Il mondo comincia coperto
## e ogni prova superata ne scopre un pezzo. Stessa pressione, segno opposto —
## e per un gioco che si studia il segno conta: la nebbia che si dirada premia,
## il fronte che avanza rimprovera.
##
## Due misure, con due ritmi diversi, perché servono a due cose:
##
##   LUCE      0..1 dentro UN mondo, e riparte a ogni mondo. È la ricompensa
##             immediata: un esercizio, un pezzo di mondo in più. Si vede subito.
##   POTENZA   cumulativa sul personaggio, non si azzera mai. È il traguardo di
##             medio periodo: riempita una soglia, Eli cambia aspetto. È anche
##             la ragione per cui i nemici contano — si vuole essere più forti
##             perché là fuori c'è qualcosa.

## Quante prove superate scoprono tutto un mondo. Dodici: circa un terzo di
## quelle che il mondo 1 chiede, così la mappa è tutta visibile molto prima
## dell'esame — la luce è una ricompensa, non un secondo cancello.
const PROVE_PER_MONDO := 12

## Le soglie della potenza, cumulative sull'intera partita. I nomi sono quelli
## che il gioco mostra: un bambino deve poter dire a voce a che punto è.
const SOGLIE := [
	{"tier": 0, "prove": 0, "nome": "Scintilla", "colore": "9fb7bb"},
	{"tier": 1, "prove": 15, "nome": "Lampada", "colore": "8ff6d2"},
	{"tier": 2, "prove": 40, "nome": "Faro", "colore": "7ad7ff"},
	{"tier": 3, "prove": 80, "nome": "Aurora", "colore": "9f8cff"},
	{"tier": 4, "prove": 140, "nome": "Meridiana", "colore": "ffd75e"},
]

# ---------------------------------------------------------------- luce

## Quante prove sono state superate in questo mondo.
static func prove_nel_mondo(save, world_id: String) -> int:
	return int(Dictionary(save.data.get("worldLight", {})).get(world_id, 0))

## Quanta parte del mondo è scoperta, 0..1.
static func luce(save, world_id: String) -> float:
	return clampf(float(prove_nel_mondo(save, world_id)) / float(PROVE_PER_MONDO), 0.0, 1.0)

## Registra una prova superata. Ritorna quanta luce c'è ADESSO, così chi chiama
## può mostrarla senza rileggere.
##
## La luce non scende mai: un mondo scoperto resta scoperto anche se si sbaglia
## dopo. Toglierla sarebbe la stessa minaccia che abbiamo scelto di non fare.
static func accendi(save, world_id: String) -> float:
	var tutti: Dictionary = save.data.get("worldLight", {})
	tutti[world_id] = mini(int(tutti.get(world_id, 0)) + 1, PROVE_PER_MONDO)
	save.data["worldLight"] = tutti
	return luce(save, world_id)

# ---------------------------------------------------------------- potenza

static func prove_totali(save) -> int:
	return int(save.data.get("powerRuns", 0))

## Una prova superata conta anche per la potenza, che è cumulativa e non si
## azzera cambiando mondo. Ritorna vero se questa prova ha fatto salire di grado
## — il momento che vale la pena celebrare.
static func avanza_potenza(save) -> bool:
	var prima := grado(save)
	save.data["powerRuns"] = prove_totali(save) + 1
	return grado(save) > prima

static func grado(save) -> int:
	var n := prove_totali(save)
	var g := 0
	for voce in SOGLIE:
		if n >= int(Dictionary(voce)["prove"]):
			g = int(Dictionary(voce)["tier"])
	return g

static func scheda_grado(save) -> Dictionary:
	var g := grado(save)
	for voce in SOGLIE:
		if int(Dictionary(voce)["tier"]) == g:
			return voce
	return SOGLIE[0]

## Quante prove mancano al grado successivo, e quante ne serviranno in tutto.
## Serve alla barra: una barra che non dice quanto manca è una decorazione.
static func verso_il_prossimo(save) -> Dictionary:
	var n := prove_totali(save)
	var g := grado(save)
	if g >= SOGLIE.size() - 1:
		return {"completo": true, "fatte": n, "servono": n, "mancano": 0}
	var da := int(Dictionary(SOGLIE[g])["prove"])
	var a := int(Dictionary(SOGLIE[g + 1])["prove"])
	return {
		"completo": false,
		"fatte": n - da,
		"servono": a - da,
		"mancano": a - n,
		"prossimo": str(Dictionary(SOGLIE[g + 1])["nome"]),
	}
