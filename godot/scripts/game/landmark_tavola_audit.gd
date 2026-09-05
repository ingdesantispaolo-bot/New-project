extends SceneTree

## **Ogni mondo ha una tavola da trovare esplorando, o dichiara di non averne.**
## (5 settembre 2026)
##
## Guardia di [[LandmarkTavolaCatalog]]. Non gioca il mondo — lo fa
## `pannelli_modali_audit`, che copre l'apertura, la chiusura e il non
## sovrapporsi ad altre schermate — misura il **contenuto**: che ci sia per
## tutti e 24 i mondi, che ogni figura dichiarata sia una delle famiglie che
## `NoraFigura` sa disegnare con i dati che le servono, e che fisica e scienze
## restino intenzionalmente senza figura, com'è già per il resto del gioco.

const CATALOGO := preload("res://scripts/game/landmark_tavola_catalog.gd")
const NORA_FIGURA := preload("res://scripts/game/nora_figura.gd")

## Le materie senza una famiglia di tavole. Decisione del 27 agosto 2026,
## motivata in `nora_figura.gd`: nei loro testi non c'è niente che si estragga
## con certezza in un diagramma, e disegnare comunque vorrebbe dire decorare.
const MATERIE_SENZA_FIGURA := ["fisica", "scienze"]

## Le chiavi che ogni tipo di figura legge da `dati`, tolte quelle opzionali.
## Serve a scoprire un refuso — una chiave scritta male non fa fallire il
## disegno, lo fa apparire vuoto, e un pannello vuoto è un difetto muto.
const CHIAVI_RICHIESTE := {
	"griglia": ["righe", "colonne"],
	"parola": ["radice", "desinenza"],
	"lista": ["valori"],
	"battuta": ["movimenti", "sotto"],
	"casi": ["scelto"],
	"circuito": ["forma"],
	"mappa": ["carta", "bersaglio"],
	"tempo": ["era"],
	"insiemi": [],
	"retta": ["valori"],
	"frase": ["testo", "pezzo"],
	"note": ["scelta"],
	"torta": ["parti"],
	"contorno": ["cosa"],
}

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	var visti_testi: Dictionary = {}
	for livello in range(1, 25):
		var voce := CATALOGO.voce(livello)
		if voce.is_empty():
			_fallisci("mondo %d: nessuna voce nel catalogo" % livello)
			continue

		var cosa := str(voce.get("cosa", "")).strip_edges()
		var scoperta := str(voce.get("scoperta", "")).strip_edges()
		if cosa == "":
			_fallisci("mondo %d: «cosa» è vuoto" % livello)
		if scoperta == "":
			_fallisci("mondo %d: «scoperta» è vuota" % livello)
		# Una sola idea per riga, e la scoperta non è un saggio: se supera due
		# frasi ha smesso di notare un dettaglio e ha cominciato a spiegare.
		if scoperta.count(".") + scoperta.count("!") + scoperta.count("?") > 1 \
				and not scoperta.ends_with("…"):
			_fallisci("mondo %d: «scoperta» ha più di una frase (%s)" % [livello, scoperta])

		var tipo := str(voce.get("tipo", ""))
		var subject := ApparatusConfig.world_subject(livello)
		if MATERIE_SENZA_FIGURA.has(subject):
			if tipo != "":
				_fallisci("mondo %d: %s non ha una famiglia di tavole, ma la voce dichiara «%s»" % [
					livello, subject, tipo])
			continue
		if tipo == "":
			_fallisci("mondo %d (%s): nessuna figura dichiarata, e la materia ne avrebbe una disponibile" % [
				livello, subject])
			continue
		if not CHIAVI_RICHIESTE.has(tipo):
			_fallisci("mondo %d: tipo di figura sconosciuto «%s»" % [livello, tipo])
			continue
		var dati: Dictionary = voce.get("dati", {})
		for chiave in Array(CHIAVI_RICHIESTE[tipo]):
			if not dati.has(chiave):
				_fallisci("mondo %d: la figura «%s» non ha la chiave «%s»" % [
					livello, tipo, str(chiave)])

		# **Il disegno vero, non solo le chiavi.** Chiamare `mostra()` per davvero
		# è l'unico modo di scoprire un valore fuori dominio — un caso latino
		# scritto male, un'era che non esiste — che una chiave presente non
		# esclude.
		var figura := NORA_FIGURA.new()
		figura.size = Vector2(320, 160)
		figura.mostra(tipo, dati)
		if figura.tipo != tipo:
			_fallisci("mondo %d: la figura non si è impostata (%s atteso, %s letto)" % [
				livello, tipo, figura.tipo])
		var descrizione := str(figura.descrizione())
		if descrizione.strip_edges() == "":
			_fallisci("mondo %d: la figura «%s» non ha una descrizione per chi non la vede" % [
				livello, tipo])

		# Nessuna riga di scoperta si ripete: sono ventiquattro incontri, uno per
		# mondo, e ripetere la stessa frase due volte insegna a smettere di
		# leggerla — la stessa regola che vale per NORA nelle prove.
		if visti_testi.has(scoperta):
			_fallisci("mondo %d: «scoperta» ripete parola per parola il mondo %s" % [
				livello, str(visti_testi[scoperta])])
		visti_testi[scoperta] = livello

	if errori.is_empty():
		print("LANDMARK TAVOLA audit VERDE — 24 mondi, ogni figura disegna davvero")
	else:
		printerr("LANDMARK TAVOLA audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
