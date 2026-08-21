extends Node

## Scarica il pacchetto di contenuti dopo l'avvio, invece di farlo aspettare.
##
## Il `.pck` di boot conteneva anche i 60 file audio e i 109 ritratti: 26 MB che
## il giocatore doveva scaricare PRIMA di vedere il primo fotogramma, pur non
## servendo nessuno dei due per entrare nel mondo. Qui vengono spostati in un
## secondo pacchetto, chiesto in sottofondo a gioco gia' interattivo.
##
## Il presupposto che rende sicura la cosa e' che entrambi i consumatori
## degradino gia' da soli: `NativeAudio._stream_for()` verifica
## `ResourceLoader.exists()` e restituisce null (silenzio), e `NpcPortrait.art_for()`
## fa lo stesso e ripiega sul volto disegnato. Finche' il pacchetto non arriva il
## gioco e' completo e muto, non rotto. Il terreno NON sta qui proprio perche'
## non ha un ripiego: senza il suo underpaint il mondo sarebbe nero.

const PACK_NAME := "content.pck"
## La copia locale porta il commit nel nome. Senza, `user://content.pck`
## sopravviverebbe ai deploy e `_load_local()` continuerebbe a montare l'audio e
## i ritratti della build precedente: il gioco si aggiorna, i contenuti no.
static var LOCAL_PACK: String:
	get: return "user://content-%s.pck" % BuildVersion.COMMIT.strip_edges()
## Una risorsa qualsiasi del pacchetto: se risponde, i contenuti ci sono gia'
## (editor, export desktop, o pacchetto caricato in una sessione precedente).
const PROBE := "res://assets/audio/ambience-day.wav"

signal content_ready()

var _request: HTTPRequest = null
var _state := "init"

## Lo stato finisce su `window.__eliContentPack` perche' un pacchetto che non si
## monta e' altrimenti invisibile: il gioco resta giocabile e muto, e nulla dice
## a che punto si e' fermato. Lo smoke test lo legge quando l'attesa scade.
func _publish(step: String) -> void:
	_state = step
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__eliContentPack = %s;" % JSON.stringify(_state), true)

func _ready() -> void:
	_publish("start")
	if ResourceLoader.exists(PROBE):
		_publish("gia-presente")
		return
	if not OS.has_feature("web"):
		# Fuori dal Web il pacchetto non viene nemmeno prodotto: se la sonda
		# fallisce qui, e' un export incompleto e va detto, non nascosto.
		push_warning("Contenuti assenti e non siamo su Web: export incompleto?")
		return
	_purge_stale_packs()
	if _load_local():
		return
	_start_download()

## Le copie delle build precedenti non servono piu' a nessuno e costano 25 MB
## l'una nello spazio del tablet.
func _purge_stale_packs() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	var keep := LOCAL_PACK.get_file()
	for name in dir.get_files():
		if name.begins_with("content-") and name.ends_with(".pck") and name != keep:
			dir.remove(name)

## Il pacchetto scaricato resta su `user://`, quindi dal secondo avvio non passa
## piu' dalla rete nemmeno se il service worker ha perso la sua copia.
func _load_local() -> bool:
	if not FileAccess.file_exists(LOCAL_PACK):
		return false
	if not ProjectSettings.load_resource_pack(LOCAL_PACK):
		DirAccess.remove_absolute(LOCAL_PACK)
		return false
	_announce()
	return true

func _start_download() -> void:
	_request = HTTPRequest.new()
	# Il corpo viene tenuto in memoria e scritto a mano invece di usare
	# `download_file`: cosi' la chiusura del file avviene prima del mount, e in
	# caso di guasto si puo' dire QUANTI byte sono arrivati invece del solo esito.
	_request.request_completed.connect(_on_completed)
	add_child(_request)
	var url := _pack_url()
	var error := _request.request(url)
	if error != OK:
		push_warning("Richiesta del pacchetto contenuti fallita: %d" % error)
		_publish("richiesta-fallita:%d:%s" % [error, url])
		return
	_publish("in-scaricamento:%s" % url)

## L'export vive in `godot/outdoor/`, ma la pagina puo' essere servita da una
## sottocartella (GitHub Pages lo fa sempre). L'indirizzo va quindi costruito da
## quello del documento, non dalla radice del dominio.
func _pack_url() -> String:
	var base := str(JavaScriptBridge.eval("location.href.split('?')[0].replace(/[^/]*$/, '')", true))
	if base == "":
		return PACK_NAME
	return base + PACK_NAME

func _on_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("Pacchetto contenuti non scaricato (result %d, http %d)" % [result, response_code])
		_publish("scarico-fallito:%d:%d" % [result, response_code])
		return
	# «GDPC» in testa: se manca, quello che e' arrivato non e' un pacchetto e il
	# mount fallirebbe senza dire perche'.
	var magic := ""
	if body.size() >= 4:
		magic = body.slice(0, 4).get_string_from_ascii()
	if magic != "GDPC":
		push_warning("Il corpo scaricato non e' un pacchetto Godot: %s" % magic)
		_publish("corpo-non-pck:%d:%s" % [body.size(), magic])
		return
	var file := FileAccess.open(LOCAL_PACK, FileAccess.WRITE)
	if file == null:
		_publish("scrittura-fallita:%d" % FileAccess.get_open_error())
		return
	file.store_buffer(body)
	file.close()
	var written := 0
	var check := FileAccess.open(LOCAL_PACK, FileAccess.READ)
	if check != null:
		written = check.get_length()
		check.close()
	if not ProjectSettings.load_resource_pack(LOCAL_PACK):
		push_warning("Pacchetto contenuti scaricato ma non montabile")
		_publish("mount-fallito:scaricati=%d:scritti=%d" % [body.size(), written])
		return
	_publish("montato:%d" % written)
	_announce()

func _announce() -> void:
	# L'audio del mondo era gia' partito in silenzio: senza questa spinta
	# resterebbe muto fino al cambio di mondo o di fase giorno/notte.
	var audio := get_node_or_null("/root/NativeAudio")
	if audio != null and audio.has_method("refresh_after_content_load"):
		audio.call("refresh_after_content_load")
	# **E la stessa cosa vale per l'arte.** (20 agosto 2026)
	#
	# Il difetto era simmetrico a quello dell'audio e per un mese non l'ha visto
	# nessuno, perche' in editor e nell'export desktop il pacchetto c'e' sempre:
	# la sonda risponde, `_ready` esce subito e la strada del ripiego non viene
	# mai percorsa. Sul Web invece i personaggi e i guardiani nascono mentre i
	# 27 MB sono in volo, ripiegano sul disegno vettoriale — che e' la cosa
	# giusta da fare — e **non tornavano piu' indietro**: il segnale
	# `content_ready` non aveva un solo ascoltatore in tutto il progetto.
	#
	# Chi ha ripiegato si mette nel gruppo `arte_differita` e se ne esce da solo
	# appena rimonta la propria tavola. Il gruppo e' vuoto in tutte le sessioni
	# in cui il pacchetto era gia' li', quindi questa chiamata di solito non
	# tocca nessuno.
	#
	# Il conteggio finisce nello stato pubblicato per la stessa ragione per cui
	# c'e' lo stato: un rimontaggio che non avviene e' invisibile. Se un giorno
	# qualcuno rivedra' i gusci vettoriali, questo numero dira' subito se il
	# problema e' che nessuno aspettava o che nessuno ha risposto.
	var in_attesa := get_tree().get_nodes_in_group("arte_differita").size()
	get_tree().call_group("arte_differita", "riapplica_arte_differita")
	_publish("montato-e-riapplicato:%d" % in_attesa)
	content_ready.emit()
