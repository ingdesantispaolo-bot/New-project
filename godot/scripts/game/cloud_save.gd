class_name CloudSave
extends Node

## Copia di sicurezza in cloud, una per profilo. (6 agosto 2026)
##
## Nell'export Web il salvataggio vive in IndexedDB: legato a QUEL browser su
## QUEL dispositivo. Svuotare i dati del browser o cambiare tablet cancella una
## campagna da venti ore, e il bambino non ha fatto niente di sbagliato.
##
## Il Worker che risponde è in `cloud/` (vedi `cloud/LEGGIMI.md`). Non c'è
## account, né email, né password: la chiave è il **codice di ripristino** del
## profilo. Un gioco per bambini di 10-13 anni che chiedesse un dato personale
## si porterebbe dietro un obbligo di consenso; un codice casuale non identifica
## nessuno.
##
## TRE REGOLE, e sono tutte per lo stesso motivo — non perdere il lavoro di un
## bambino:
##
##   1. **Il locale è la verità.** Il cloud è una copia. Se il Worker non
##      risponde non succede niente: si continua a giocare offline.
##   2. **Non si scarica mai da soli.** Il Worker non fonde due salvataggi:
##      l'ultimo che scrive vince. Un caricamento automatico all'avvio potrebbe
##      sostituire la partita buona con una vecchia. Si scarica solo quando un
##      umano lo chiede, vedendo prima che cosa sta per arrivare.
##   3. **Un codice si occupa solo se è libero.** Prima di assegnarlo si chiede
##      al cloud se esiste già: senza questo controllo due bambini potrebbero
##      finire sullo stesso salvataggio, l'unico incidente davvero grave qui.

const ENDPOINT := "https://eli-quest-save.ing-desantis-paolo.workers.dev"
const TIMEOUT_SECONDI := 12.0

## Quanti codici provare prima di arrendersi. Con 3,3 miliardi di combinazioni
## una collisione è già improbabile al primo colpo; cinque tentativi coprono
## anche il caso in cui il cloud risponda male.
const TENTATIVI_CODICE := 5

const ENVELOPE_GIOCO := "eli-quest"
const ENVELOPE_VERSIONE := 1

## Esito: {"ok": bool, "azione": String, "codice": String, "dati": Dictionary,
##         "meta": Dictionary, "errore": String}
signal finished(esito: Dictionary)

var _http: HTTPRequest
var _azione := ""
var _codice := ""
var _corpo := ""
var _tentativi_rimasti := 0
var _rng: RandomNumberGenerator

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SECONDI
	add_child(_http)
	_http.request_completed.connect(_on_risposta)

# ---------------------------------------------------------------- parte pura

## Il salvataggio non va in cloud nudo: attorno c'è una busta con il nome del
## gioco e quando è stata scritta. Serve a due cose concrete — riconoscere che
## un codice contiene ALTRO (un errore di battitura può portare su dati di un
## altro gioco o di un altro bambino) e poter mostrare «livello 7, salvato tre
## giorni fa» PRIMA di sostituire la partita sul tablet.
static func incarta(dati: Dictionary, nome: String) -> String:
	return JSON.stringify({
		"gioco": ENVELOPE_GIOCO,
		"versione": ENVELOPE_VERSIONE,
		"salvatoIl": int(Time.get_unix_time_from_system()),
		"nome": nome,
		"dati": dati,
	})

## Apre la busta. Tollera un salvataggio scritto senza busta — non per gentilezza
## verso un formato che non è mai esistito, ma perché il Worker accetta qualunque
## JSON e una versione futura potrebbe scrivere diversamente: meglio riconoscere
## un salvataggio valido che rifiutarlo per la carta che ha attorno.
##
## Restituisce {} se non è un salvataggio di questo gioco.
static func scarta(testo: String) -> Dictionary:
	var parsed = JSON.parse_string(testo)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	if str(d.get("gioco", "")) == ENVELOPE_GIOCO:
		var dentro = d.get("dati", {})
		if typeof(dentro) != TYPE_DICTIONARY or Dictionary(dentro).is_empty():
			return {}
		return {
			"dati": dentro,
			"nome": str(d.get("nome", "")),
			"salvatoIl": int(d.get("salvatoIl", 0)),
		}
	# Senza busta: è un salvataggio solo se ne ha la forma. `schemaVersion` c'è
	# in ogni save di Eli Quest fin dal primo, `level` è obbligatorio.
	if d.has("schemaVersion") and d.has("level"):
		return {"dati": d, "nome": "", "salvatoIl": 0}
	return {}

## Il messaggio che legge un bambino. Un codice di stato HTTP non dice niente a
## nessuno, e «errore 404» somiglia a un guasto del gioco invece che a «quel
## codice non ha ancora niente».
static func messaggio_errore(stato: int, azione: String) -> String:
	match stato:
		0:
			return "Non riesco a raggiungere il cloud. Controlla la connessione: intanto si gioca lo stesso, la partita resta su questo tablet."
		400:
			return "Il codice non è scritto bene. Sono quattro lettere, un trattino e quattro numeri."
		404:
			if azione == "scarica":
				return "Nessuna partita salvata con questo codice. Controlla di averlo ricopiato bene."
			return "Il cloud non ha trovato l'indirizzo. Riprova più tardi."
		413:
			return "Il salvataggio è troppo grande per il cloud."
		_:
			return "Il cloud ha risposto male (%d). La partita su questo tablet è al sicuro." % stato

# ---------------------------------------------------------------- rete

func occupato() -> bool:
	return not _azione.is_empty()

## Scarica la partita di un codice. Non tocca niente: consegna i dati a chi ha
## chiesto, che deciderà se sostituire il salvataggio locale.
func scarica(codice: String) -> void:
	if not _inizia("scarica", codice):
		return
	_richiedi(HTTPClient.METHOD_GET, codice, "")

## Manda la partita in cloud, sovrascrivendo quella del codice.
func carica(codice: String, dati: Dictionary, nome: String) -> void:
	if not _inizia("carica", codice):
		return
	_corpo = incarta(dati, nome)
	_richiedi(HTTPClient.METHOD_PUT, codice, _corpo)

## Trova un codice LIBERO e lo restituisce. Non lo scrive nel profilo: quello lo
## fa chi ha chiamato, così un codice non risulta assegnato se poi il caricamento
## fallisce.
func riserva_codice(rng: RandomNumberGenerator = null) -> void:
	if not _inizia("riserva", "SENZ-0000"):
		return
	_rng = rng
	_tentativi_rimasti = TENTATIVI_CODICE
	_prova_un_codice()

func _prova_un_codice() -> void:
	var codice := PlayerProfiles.generate_code(_rng)
	if codice.is_empty():
		_concludi({"ok": false, "azione": "riserva", "codice": "",
			"errore": "Non riesco a creare un codice nuovo."})
		return
	_codice = codice
	_richiedi(HTTPClient.METHOD_GET, codice, "")

func _inizia(azione: String, codice: String) -> bool:
	if occupato():
		# Una richiesta alla volta: HTTPRequest ne regge una sola, e due tocchi
		# rapidi sullo stesso pulsante non devono produrre due caricamenti.
		return false
	if azione != "riserva" and not PlayerProfiles.is_valid_code(codice):
		call_deferred("_concludi", {"ok": false, "azione": azione, "codice": codice,
			"errore": messaggio_errore(400, azione)})
		return false
	_azione = azione
	_codice = codice.to_upper().strip_edges()
	return true

func _richiedi(metodo: int, codice: String, corpo: String) -> void:
	var errore := _http.request(
		"%s/save/%s" % [ENDPOINT, codice],
		["Content-Type: application/json"],
		metodo,
		corpo)
	if errore != OK:
		_concludi({"ok": false, "azione": _azione, "codice": codice,
			"errore": messaggio_errore(0, _azione)})

func _on_risposta(risultato: int, stato: int, _headers: PackedStringArray, corpo: PackedByteArray) -> void:
	var azione := _azione
	var testo := corpo.get_string_from_utf8()

	# La rete non è arrivata al Worker: nessun codice di stato da interpretare.
	if risultato != HTTPRequest.RESULT_SUCCESS:
		_concludi({"ok": false, "azione": azione, "codice": _codice,
			"errore": messaggio_errore(0, azione)})
		return

	match azione:
		"riserva":
			# 404 è la risposta BUONA: quel codice non è di nessuno.
			if stato == 404:
				_concludi({"ok": true, "azione": azione, "codice": _codice})
				return
			if stato == 200:
				_tentativi_rimasti -= 1
				if _tentativi_rimasti > 0:
					_prova_un_codice()
					return
				_concludi({"ok": false, "azione": azione, "codice": "",
					"errore": "Non riesco a trovare un codice libero. Riprova."})
				return
			_concludi({"ok": false, "azione": azione, "codice": "",
				"errore": messaggio_errore(stato, azione)})
		"scarica":
			if stato != 200:
				_concludi({"ok": false, "azione": azione, "codice": _codice,
					"errore": messaggio_errore(stato, azione)})
				return
			var busta := scarta(testo)
			if busta.is_empty():
				_concludi({"ok": false, "azione": azione, "codice": _codice,
					"errore": "Quel codice contiene qualcosa che non è una partita di Eli Quest."})
				return
			_concludi({"ok": true, "azione": azione, "codice": _codice,
				"dati": busta["dati"],
				"meta": {"nome": busta["nome"], "salvatoIl": busta["salvatoIl"]}})
		_:
			if stato != 200:
				_concludi({"ok": false, "azione": azione, "codice": _codice,
					"errore": messaggio_errore(stato, azione)})
				return
			_concludi({"ok": true, "azione": azione, "codice": _codice})

func _concludi(esito: Dictionary) -> void:
	_azione = ""
	_corpo = ""
	if not esito.has("dati"):
		esito["dati"] = {}
	if not esito.has("meta"):
		esito["meta"] = {}
	if not esito.has("errore"):
		esito["errore"] = ""
	finished.emit(esito)
