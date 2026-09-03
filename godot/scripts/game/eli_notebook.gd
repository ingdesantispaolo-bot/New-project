class_name EliNotebook
extends RefCounted

## **Il taccuino di Eli.** (2 settembre 2026)
##
## Il difetto, misurato: Eli ha una voce in **sessantasette punti** del gioco —
## una riga sopra ogni forziere di qualcuno (`TreasureCatalog`), una sopra i semi
## che la riguardano (`MysteryCatalog`), una sopra ognuna delle undici sorelle
## (`SistersThread`) — e ognuna di quelle righe **compare per tre secondi e
## sparisce per sempre**. Sono i soli pensieri della protagonista in
## ventiquattro mondi, e il gioco non ne conserva neanche uno.
##
## Il taccuino è dove finiscono. Non è un collezionabile e non è un inventario:
## è il posto in cui una ragazzina rilegge quello che ha pensato mesi prima e si
## accorge di essere cambiata. Per questo le voci **non si possono cancellare,
## non scadono e non si contano per niente**: se il taccuino desse un premio,
## smetterebbe di essere suo e diventerebbe una lista di raccolta.
##
## **E serve una seconda volta, alla fine.** Il finale del mondo 24 deve
## accorgersi di come hai giocato senza aprire rami e senza dare voti: legge di
## qui. `ritratto()` non restituisce un punteggio — restituisce **cose fatte**,
## contate e basta, da cui la scena finale sceglie due o tre righe che nominano
## qualcosa di preciso. La differenza fra «sei stata brava» e «ti sei fermata
## trentun volte a guardare la roba di qualcuno» è tutta la distanza fra una
## pagella e un ritratto.
##
## GUARD-RAIL, gli stessi del resto del progetto:
##
## - nessuna voce del taccuino apre, chiude o modifica qualcosa: non tocca gate,
##   energia, padronanza, frammenti;
## - non esiste un taccuino incompleto. Chi non si è fermato a guardare niente
##   ha un taccuino corto, e il finale gli parla lo stesso e senza rimproveri;
## - non c'è una voce «giusta» da trovare, quindi non c'è niente da farmare.

## Vive dentro `narrative`, che è già la casa di tutto ciò che la storia ricorda.
const SAVE_KEY := "taccuino"

## Quante voci si tengono. Centoventi copre una campagna intera con margine —
## sessantasette righe d'autore più le posizioni prese — e mette un tetto alla
## dimensione del salvataggio. Oltre il tetto si smette di aggiungere invece di
## buttare via le vecchie: le prime pagine sono quelle che al mondo 24 fanno
## effetto, e sarebbero le prime a saltare.
const MAX_VOCI := 120

## Le fonti, dichiarate. Servono al ritratto finale per dire *dove* si è fermata,
## e all'audit per accorgersi se un canale smette di scrivere.
const FONTE_LASCITO := "lascito"     # il forziere di qualcuno
const FONTE_SEME := "seme"           # un indizio che la riguarda
const FONTE_SORELLA := "sorella"     # una delle undici prima di lei
const FONTE_POSIZIONE := "posizione" # una posizione presa davanti a qualcuno
const FONTI := [FONTE_LASCITO, FONTE_SEME, FONTE_SORELLA, FONTE_POSIZIONE]

static func _narrative(save) -> Dictionary:
	if save == null:
		return {}
	if not save.data.has("narrative"):
		save.data["narrative"] = {}
	return save.data["narrative"]

static func voci(save) -> Array:
	if save == null:
		return []
	return Array(_narrative(save).get(SAVE_KEY, [])).duplicate(true)

static func conta(save) -> int:
	return voci(save).size()

## Scrive una voce. `id` la rende unica: rileggere lo stesso forziere o rientrare
## nello stesso mondo non riempie il taccuino di doppioni. Torna vero solo se ha
## scritto davvero, così il chiamante può decidere se dirlo o tacere.
static func registra(save, id: String, fonte: String, world: int, testo: String) -> bool:
	if save == null or id.strip_edges() == "" or testo.strip_edges() == "":
		return false
	if not FONTI.has(fonte):
		return false
	var narrative := _narrative(save)
	var lista: Array = Array(narrative.get(SAVE_KEY, []))
	for voce_data in lista:
		if str((voce_data as Dictionary).get("id", "")) == id:
			return false
	if lista.size() >= MAX_VOCI:
		return false
	lista.append({
		"id": id,
		"fonte": fonte,
		"world": maxi(0, world),
		"testo": testo.strip_edges(),
	})
	narrative[SAVE_KEY] = lista
	return true

## Le ultime `quante` voci, dalla più recente. È l'ordine in cui si rilegge un
## taccuino vero: si parte da dove si è arrivati.
static func ultime(save, quante: int = 8) -> Array:
	var lista := voci(save)
	var out: Array = []
	var i := lista.size() - 1
	while i >= 0 and out.size() < quante:
		out.append(lista[i])
		i -= 1
	return out

## **Il ritratto che legge il finale.** Conta e basta: nessuna soglia, nessun
## giudizio, nessun confronto con un ideale. Le chiavi sono cose fatte, e la
## scena finale ne sceglie due o tre da nominare.
##
## `sorelleTrovate` sta a parte dalle altre fonti perché è la sola che il mondo
## 24 nomina per forza: la confessione di NORA parla di loro, e sapere quante ne
## ha davvero incontrate cambia che cosa ha senso dirle.
static func ritratto(save) -> Dictionary:
	var per_fonte: Dictionary = {}
	for fonte in FONTI:
		per_fonte[fonte] = 0
	var mondi: Array = []
	for voce_data in voci(save):
		var voce: Dictionary = voce_data
		var fonte := str(voce.get("fonte", ""))
		if per_fonte.has(fonte):
			per_fonte[fonte] = int(per_fonte[fonte]) + 1
		var world := int(voce.get("world", 0))
		if world > 0 and not mondi.has(world):
			mondi.append(world)
	mondi.sort()
	return {
		"voci": conta(save),
		"mondi": mondi.size(),
		"lasciti": int(per_fonte[FONTE_LASCITO]),
		"semi": int(per_fonte[FONTE_SEME]),
		"sorelleTrovate": int(per_fonte[FONTE_SORELLA]),
		"posizioni": int(per_fonte[FONTE_POSIZIONE]),
	}
