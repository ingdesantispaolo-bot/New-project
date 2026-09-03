extends SceneTree

## **Ventiquattro letture di uscita, e nessuna criptica.** (2 settembre 2026)
##
## Richiesta del committente, in due metà: *pagine con una piccola lettura di
## introduzione e di uscita da ogni mondo*, e *dialoghi e parti che spiegano la
## storia non criptiche o oscure, ma adatte a un ragazzo di undici anni*.
##
## L'ingresso esisteva (`WorldIntroPanel`). L'uscita no, e il `debrief` di tutti e
## ventiquattro i mondi era dichiarato «senza lettore».
##
## **Sulla seconda metà ho misurato prima di riscrivere**, e il risultato ha
## cambiato il lavoro: i testi non sono lunghi. I beat di NORA stanno a **7,9
## parole per frase** e una frase su ottantasette supera le venti parole. Il
## problema non è la lunghezza — è che la storia è raccontata per **allusioni**.
## Accorciare non avrebbe aiutato nessuno; affiancare una versione detta in
## chiaro sì. È la parte `storia` di ogni lettura, e questo audit la difende.
##
## Le sei cose che verifica:
##
## 1. **Ci sono tutte e ventiquattro**, con tutte e quattro le parti piene.
## 2. **Si leggono a undici anni**: frasi corte e nessuna parola da pagella.
## 3. **La parte `storia` non anticipa mai.** La lettura del mondo N può dire
##    solo quello che si sa alla fine del mondo N: cercare qui i nomi e i fatti
##    dei colpi successivi è il modo più diretto di accorgersene.
## 4. **Nessuno muore**, mai, in nessuna lettura (§10.1).
## 5. **Nessuna lettura rimprovera.** È la pagina che si legge dopo aver
##    finito: dire lì che cosa non hai fatto sarebbe il peggior momento possibile.
## 6. **Qualcuno le legge davvero.** Il difetto ricorrente di questo progetto è
##    il contenuto scritto e mai collegato — ed è esattamente com'era finito il
##    `debrief`.

## **Il tetto sulla lunghezza delle frasi è stato tolto.** (2 settembre 2026)
##
## La prima stesura ne aveva uno a diciotto parole, ed era sbagliato per una
## ragione che questo stesso audit aveva già misurato: il difetto **non era la
## lunghezza**. I beat di NORA stanno a 7,9 parole per frase, i debrief a 6,6, e
## la storia risultava comunque oscura — perché è raccontata per allusioni.
## Mettere un tetto sulle parole voleva dire mettere un cricchetto su una cosa
## che i numeri avevano appena scagionato.
##
## E si è visto: per rispettarlo ho spezzato diciotto frasi, e diverse stavano
## meglio intere. *«Uno è stato raschiato via con una lama, da dentro la nave,
## dopo che si era chiusa: qualcuno voleva che quella persona sparisse»* sono
## ventitré parole ed è una frase buona; tagliata in due diventa scattosa. Un
## ragazzo di undici anni legge romanzi con frasi il doppio più lunghe. Quello
## che non regge non è la frase lunga: è la frase oscura.
##
## Resta un solo controllo sulla misura, e non è una regola di stile: **la
## guardia contro l'incidente**. Oltre le quaranta parole una frase, a
## quest'età, si legge perdendo per strada da dove era partita — e di solito
## vuol dire che chi scriveva ha unito due pensieri per sbaglio. La media resta
## stampata come informazione, e non fa fallire niente.
const PAROLE_LIMITE_INCIDENTE := 40

## Le parole che un undicenne non usa e che qui sarebbero etichette da scuola.
## L'elenco viene da `docs/VOCE_11_ANNI.md` («da evitare come etichette
## generiche») più i termini da pagella.
const PAROLE_DA_SCUOLA := [
	"padronanza", "lessico", "istanza", "unità operativa", "acquisizione",
	"consolidamento", "competenza", "sistemico", "parametro", "cognitivo",
	"semantico", "algoritmico", "convergenza", "protocollo",
]

## Le formule che trasformano una pagina di chiusura in un rimprovero.
const RIMPROVERI := [
	"non hai", "avresti", "purtroppo", "peccato", "hai sbagliato",
	"non sei riuscita", "ti manca", "dovevi",
]

## Le parole della morte e le negazioni che le rendono lecite. **Sono le stesse
## liste di `mystery_audit`**, e non una seconda copia con altre parole: due
## regole diverse sullo stesso divieto sono due regole che prima o poi
## divergono. «Non è morta» resta dicibile — è la frase con cui il documento
## stesso dice il guard-rail (§10.1: chi non c'è è trattenuto, non perduto).
const MORTE := [
	"è morto", "e morto", "è morta", "e morta", "sono morti", "sono morte",
	"morire", "ucciso", "uccisa", "uccidere", "defunt", "cadavere",
	"perduto per sempre", "perduta per sempre",
]
const NEGAZIONI := ["non ", "nessuno ", "nessuna ", "né ", "ne ", "mai "]

## Che cosa NON si può dire prima del mondo in cui si scopre.
##
## **Le chiavi vanno scelte con precisione, e questa lista me l'ha insegnato
## sbagliandola due volte.** «tredicesimo» sembrava una buona chiave e non lo è:
## al mondo 8 il *tredicesimo posto* è proprio ciò che si scopre, mentre *il
## Tredicesimo* — la persona — arriva al 19. Allo stesso modo «undici prima di
## te» è canonico dal mondo 13, dove NORA dice «non ho il file»: quello che si
## scopre al 24 è che le ha costruite lei. Una chiave troppo larga non protegge
## la storia, obbliga solo a riscrivere testi giusti.
const NON_PRIMA := {
	"tredici posti": 8,
	"sei la dodicesima": 12,
	"la tua è la dodici": 12,
	"stanza senza porta": 15,
	"volume senza porta": 15,
	"ha costruito nora": 19,
	"il tredicesimo. la chiusura": 19,
	"meridiana": 23,
	"le ha costruite nora": 24,
	"le undici prima di te non le ha": 24,
}

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _frasi(testo: String) -> Array:
	var out: Array = []
	for pezzo in testo.replace("!", ".").replace("?", ".").replace("…", ".").split("."):
		var pulita := str(pezzo).strip_edges()
		if pulita != "":
			out.append(pulita)
	return out

func _init() -> void:
	_ci_sono_tutte()
	_si_leggono_a_undici_anni()
	_non_anticipano()
	_nessuna_rimprovera()
	_qualcuno_le_legge()
	if errori.is_empty():
		print("WORLD READINGS audit VERDE — 24 letture di uscita, %.1f parole per frase" % _media())
	else:
		printerr("WORLD READINGS audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _media() -> float:
	var parole := 0
	var frasi := 0
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		for frase in _frasi(WorldReadings.testo_intero(level)):
			frasi += 1
			parole += str(frase).split(" ").size()
	return float(parole) / maxf(float(frasi), 1.0)

func _ci_sono_tutte() -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if not WorldReadings.ha(level):
			_fallisci("il mondo %d non ha una lettura di uscita" % level)
			continue
		var lettura := WorldReadings.lettura(level)
		if str(lettura.get("titolo", "")).strip_edges() == "":
			_fallisci("la lettura del mondo %d non ha titolo" % level)
		for parte_data in WorldReadings.PARTI:
			var chiave := str((parte_data as Dictionary)["chiave"])
			var testo := str(lettura.get(chiave, "")).strip_edges()
			if testo == "":
				_fallisci("mondo %d: manca la parte «%s»" % [level, chiave])
			elif testo.length() < 40:
				_fallisci("mondo %d: la parte «%s» è troppo corta per essere una lettura" % [level, chiave])
	# E il `debrief` che la pagina mostra sopra deve esistere per tutti: era la
	# sua unica ragione di essere senza lettore.
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		if WorldLessonCatalog.debrief(level).strip_edges() == "":
			_fallisci("il mondo %d non ha il debrief che la pagina di uscita mostra" % level)
	# **La tavola dipinta esiste davvero.** Un percorso scritto a mano che punta
	# a un file inesistente lascia la pagina senza immagine e non fa rumore: è il
	# genere di rottura che si scopre soltanto giocando.
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var percorso := WorldReadings.tavola(level)
		if percorso == "":
			_fallisci("il mondo %d non ha una tavola per la sua lettura" % level)
		elif not ResourceLoader.exists(percorso):
			_fallisci("la tavola del mondo %d non esiste: %s" % [level, percorso])

func _si_leggono_a_undici_anni() -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var testo := WorldReadings.testo_intero(level)
		for frase in _frasi(testo):
			var quante := str(frase).split(" ").size()
			if quante > PAROLE_LIMITE_INCIDENTE:
				_fallisci("mondo %d: frase di %d parole — a quest'età si perde per strada da dove era partita: «%s…»" % [
					level, quante, str(frase).substr(0, 70)])
		var minuscolo := testo.to_lower()
		# **Parola intera, non sottostringa.** «distanza» contiene «istanza», e la
		# prima stesura di questo audit ha bocciato una frase giusta per questo.
		var parole: Array = []
		for grezza in minuscolo.replace(",", " ").replace(".", " ").replace(":", " ").split(" "):
			var pulita := str(grezza).strip_edges()
			if pulita != "":
				parole.append(pulita)
		for parola in PAROLE_DA_SCUOLA:
			var cercata := str(parola)
			var trovata := parole.has(cercata) if not cercata.contains(" ") else minuscolo.contains(cercata)
			if trovata:
				_fallisci("mondo %d: «%s» è una parola da scuola, non da undici anni" % [
					level, cercata])
		_controlla_morte(level, minuscolo)

## Stessa logica di `mystery_audit._check_morte`: una parola della morte è lecita
## solo se poco prima c'è una negazione.
func _controlla_morte(level: int, minuscolo: String) -> void:
	for term in MORTE:
		var from := 0
		while true:
			var at := minuscolo.find(str(term), from)
			if at < 0:
				break
			from = at + 1
			var before := minuscolo.substr(maxi(0, at - 20), mini(20, at))
			var negato := false
			for negazione in NEGAZIONI:
				if before.contains(str(negazione)):
					negato = true
					break
			if not negato:
				_fallisci("mondo %d: dice che qualcuno è morto («%s») — vietato da §10.1" % [
					level, str(term)])

## **Non si anticipa.** La lettura del mondo N dice quello che si sa alla fine
## del mondo N e nient'altro: una pagina che nomina il Tredicesimo al mondo 9
## brucerebbe cinque mondi di indagine.
func _non_anticipano() -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var testo := WorldReadings.testo_intero(level).to_lower()
		for chiave in NON_PRIMA.keys():
			var da := int(NON_PRIMA[chiave])
			if level < da and testo.contains(str(chiave)):
				_fallisci("mondo %d: nomina «%s», che si scopre al mondo %d" % [
					level, str(chiave), da])

func _nessuna_rimprovera() -> void:
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var testo := WorldReadings.testo_intero(level).to_lower()
		for formula in RIMPROVERI:
			if testo.contains(str(formula)):
				_fallisci("mondo %d: «%s» rimprovera chi ha appena finito il mondo" % [
					level, str(formula)])

## Il difetto ricorrente: contenuto scritto per intero e mai collegato. È
## esattamente com'era finito il `debrief`, ed è la ragione per cui questa riga
## esiste.
func _qualcuno_le_legge() -> void:
	var pannello := FileAccess.get_file_as_string("res://scripts/ui/world_outro_panel.gd")
	if not pannello.contains("WorldReadings"):
		_fallisci("il pannello di uscita non legge le letture")
	if not pannello.contains("WorldLessonCatalog.debrief"):
		_fallisci("il pannello di uscita non mostra il debrief, che era il testo senza lettore")
	var hub := FileAccess.get_file_as_string("res://scripts/hub_scene.gd")
	if not hub.contains("WorldOutroPanel"):
		_fallisci("nessuno apre la pagina di uscita: le 24 letture non le vedrebbe nessuno")
	if not hub.contains("_mostra_lettura_di_uscita"):
		_fallisci("la pagina di uscita non è agganciata alla riparazione dell'apparato")
