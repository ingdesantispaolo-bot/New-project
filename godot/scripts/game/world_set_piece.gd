class_name WorldSetPiece
extends RefCounted

## **I SEI MOMENTI.** (19 agosto 2026)
##
## Il difetto, misurato leggendo il direttore degli eventi: la ricetta di un
## mondo è **identica ventiquattro volte**. Sette eventi che contano per il gate,
## undici palestre, un enigma, un incarico, qualche forziere, da una a quattro
## sacche. La composizione semantica cambia *dove* le cose stanno; non cambia mai
## *che cosa* succede. Al quarto mondo un bambino ha già capito la forma di tutti
## i venti che restano, e da lì in poi il gioco non lo sorprende più.
##
## La risposta non è aggiungere un diciannovesimo punto d'interesse: sarebbe
## rispondere a «è ripetitivo» con «ce n'è di più». È un **momento autorato** che
## non si può giocare, non si può mancare e non si ripete — una cosa che succede
## mentre stai facendo altro.
##
## ## Perché sei e non ventiquattro
##
## Perché sei bastano a dare un ritmo a ventuno ore, e perché ventiquattro
## sarebbero ventiquattro pezzi d'autore da scrivere e mantenere. E soprattutto
## perché sei **si agganciano a qualcosa che esiste già**: i colpi di scena della
## trama stanno ai mondi 5, 8, 12, 16, 19 e 23 ([[MysteryCatalog]]). Il momento
## non è un ospite in casa d'altri: è la stessa cosa vista dalla parte del mondo
## invece che dalla parte del testo.
##
## Tre dei sei chiudono buchi che `STATO_CONTENUTI_E_NARRATIVA` §3.3 aveva
## misurato e lasciato aperti:
##
##   - **il Tredicesimo entra prima.** «Per sedici mondi non c'è nessuno che
##     ostacoli, solo cose da capire»; il rimedio proposto era *un «FERMATI» su
##     un'insegna, costa zero e cambia il ritmo di otto mondi*. È il momento del
##     mondo 12;
##   - **una sorella ha un volto.** «Le undici sorelle sono un numero»; il
##     rimedio era *rendere uno Sbiadito riconoscibile — che ripete una frase che
##     NORA ha detto*. È il momento del mondo 16;
##   - **il Custode entra nella storia.** «È il compagno costante del giocatore
##     ed è narrativamente muto». Il buio del mondo 8 è il primo momento in cui
##     la sua presenza cambia che cosa si vede.
##
## ## Le regole, che valgono per tutti e sei
##
## **Non tolgono niente.** Nessun momento costa energia, padronanza, frammenti o
## tempo di gate. Il branco insegue ma morde con le stesse regole di sempre; il
## buio nasconde ma non chiude nessuna strada. Un momento che punisse sarebbe una
## trappola, e questo gioco non ne ha.
##
## **Non si possono mancare e non si ripetono.** Scattano quando il mondo è
## scoperto a metà — cioè a lavoro cominciato, non sulla soglia — e restano
## segnati nel salvataggio. Un momento d'autore che ricompare è una cutscene
## saltata la seconda volta.
##
## **Durano poco.** Il più lungo è quaranta secondi. Sono un respiro dentro una
## sessione, non un capitolo.

## Quanto dev'essere scoperto il mondo perché il momento scatti. Metà: a lavoro
## cominciato, quando il posto è già familiare — sulla soglia sarebbe una
## presentazione, e a fine mondo arriverebbe quando si sta già uscendo.
const LUCE_DI_INNESCO := 0.5

const BRANCO := "branco"
const BUIO := "buio"
const SCRITTA := "scritta"
const ECO := "eco"
const MAREA := "marea"
const CONVERGENZA := "convergenza"

const MOMENTI := [
	{
		"mondo": 5, "id": "set-05-branco", "forma": BRANCO, "durata": 16.0,
		"apertura": "Si sono voltate tutte insieme. Tutte, nello stesso istante.",
		"chiusura": "Hanno smesso come avevano cominciato: insieme, e senza una ragione.",
	},
	{
		"mondo": 8, "id": "set-08-buio", "forma": BUIO, "durata": 34.0,
		"apertura": "La luce se ne va come se qualcuno l'avesse richiamata indietro.",
		"chiusura": "Torna. Piano, e da sotto, come se fosse sempre stata lì.",
	},
	{
		# Il «FERMATI» chiesto da STATO_CONTENUTI §3.3a. Una parola sola, senza
		# spiegazione: il Tredicesimo non minaccia mai, e questa non è una
		# minaccia — è la prima volta che qualcuno si rivolge a Eli.
		"mondo": 12, "id": "set-12-scritta", "forma": SCRITTA, "durata": 22.0,
		"parola": "FERMATI",
		"apertura": "Su un'insegna che ieri era vuota c'è una parola sola, scritta di fresco.",
		"chiusura": "",
	},
	{
		# La sorella riconoscibile chiesta da STATO_CONTENUTI §3.3c. Nessuna
		# spiegazione adesso: al colpo di scena, quel ricordo torna.
		"mondo": 16, "id": "set-16-eco", "forma": ECO, "durata": 20.0,
		"eco": "«Non te la do io la risposta. La rifai tu».",
		"apertura": "Una delle sacche si è fermata. E ha detto una cosa, con una voce che conosci.",
		"chiusura": "",
	},
	{
		"mondo": 19, "id": "set-19-marea", "forma": MAREA, "durata": 30.0,
		"apertura": "Il velo si alza e si riabbassa, come un respiro che non è tuo.",
		"chiusura": "Poi resta alzato. Il respiro era di qualcosa che adesso è fermo.",
	},
	{
		"mondo": 23, "id": "set-23-convergenza", "forma": CONVERGENZA, "durata": 18.0,
		"apertura": "Hanno smesso di lavorare. Tutti, e nessuno si è detto niente.",
		"chiusura": "Riprendono. Ma da adesso sanno che tu lo sai.",
	},
]

## I mondi che hanno un momento. Serve agli audit e a chi si chiede se questo
## mondo ne abbia uno senza costruire la scena.
static func mondi() -> Array:
	var out: Array = []
	for voce in MOMENTI:
		out.append(int(Dictionary(voce)["mondo"]))
	return out

static func ha(world_level: int) -> bool:
	return mondi().has(world_level)

## Il momento di questo mondo, vuoto se non ne ha uno.
static func momento(world_level: int) -> Dictionary:
	for voce in MOMENTI:
		if int(Dictionary(voce)["mondo"]) == world_level:
			return voce
	return {}
