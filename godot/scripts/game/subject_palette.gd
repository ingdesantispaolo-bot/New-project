class_name SubjectPalette
extends RefCounted

## **I dodici colori delle materie, in un posto solo.** (21 agosto 2026)
##
## La stessa tabella viveva in due copie: `hub_scene.PRISMA_COLORI`, che accende
## il nucleo prismatico della nave, e un dizionario locale dentro
## `outdoor_world._configure_profile_palette`, che tinge la notte di un mondo.
## Due copie della stessa verità sono una verità che prima o poi diverge — e
## qui divergere significa che il mondo di latino e la scheda di latino sulla
## nave sono di due colori diversi, cioè che il **ritratto** che il nucleo
## prismatico dovrebbe dipingere smette di somigliare al viaggio.
##
## ## Perché il colore è narrativo e non decorativo
##
## Il nucleo prismatico è descritto nella bottega come «il cuore della nave, che
## scompone la luce in dodici colori: uno per sistema — è un ritratto, non una
## macchina». Perché quel ritratto sia vero, il colore di una materia deve essere
## **lo stesso ovunque quella materia compaia**: la notte del suo mondo, la sua
## scheda sul ponte, e il sito in cui la si allena. Un bambino che ha passato
## venti ore nel verde della geografia deve riconoscere il verde da lontano, senza
## leggere l'etichetta.
##
## Chi aggiunge una materia la aggiunge qui, e la trova accesa in tutti e tre i
## posti. `subject_palette_audit` pretende che le dodici materie del ciclo
## abbiano tutte un colore e che nessuno sia ripetuto: due materie dello stesso
## colore non sono un ritratto, sono una macchia.

const COLORI := {
	"matematica": "6be7d6",
	"italiano": "e9a86d",
	"coding": "8fa7ff",
	"inglese": "72c9ff",
	"fisica": "a2d8ff",
	"musica": "d7a0ff",
	"latino": "d4b17a",
	"elettronica": "79e7ff",
	"geografia": "7fd19b",
	"scienze": "91dc72",
	"storia": "f2c96d",
	"logica": "b7a2ff",
}

## Il colore di ripiego. Non è il colore di nessuna materia, di proposito: se
## comparisse in gioco vorrebbe dire che qualcuno sta chiedendo una materia che
## non esiste, e deve saltare all'occhio invece di mimetizzarsi fra le dodici.
const NEUTRO := Color("9fb7bb")

static func colore(materia: String) -> Color:
	var esadecimale := str(COLORI.get(materia, ""))
	return Color(esadecimale) if not esadecimale.is_empty() else NEUTRO

static func ha(materia: String) -> bool:
	return COLORI.has(materia)

## La tabella come la vuole chi disegna: materia -> Color, già convertita.
static func tavolozza() -> Dictionary:
	var fuori: Dictionary = {}
	for materia in COLORI.keys():
		fuori[str(materia)] = Color(str(COLORI[materia]))
	return fuori
