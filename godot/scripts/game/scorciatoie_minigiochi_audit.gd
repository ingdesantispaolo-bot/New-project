extends SceneTree

## **Le due scorciatoie dei minigiochi.** (1 settembre 2026)
##
## `bank_scorciatoie_audit` misura le tre scorciatoie dei BANCHI — lunghezza,
## posizione, eco — e da agosto il suo debito è chiuso. Ma i banchi valgono ormai
## un decimo dei nodi giocati: il resto sono minigiochi, e lì nessuno guardava.
##
## Il difetto che ha aperto questo audit stava proprio lì. Nell'unico insieme di
## abbinamento della logica che porta deduzioni vere, **sei coppie su sei** si
## azzeccavano cercando la parola ripetuta fra le due colonne:
##
##     Tutti i gatti sono felini. MICIO è un gatto.  →  MICIO è un felino.
##     Nessun pesce vola. Il TONNO è un pesce.       →  Il TONNO non vola.
##
## E nello smistamento dei quantificatori, nove tessere su nove finivano nel
## bidone giusto leggendo la prima parola: «Ogni…» nel bidone «tutti», «Nessun…»
## nel bidone «nessuno». Chi aveva imparato tre vocaboli e non aveva capito
## niente prendeva nove su nove.
##
## ## Le due scorciatoie, simulate come le userebbe qualcuno
##
##   ECO      abbinamento: collega ogni voce a sinistra con quella a destra che
##            ripete una sua parola. Non serve sapere che cosa vuol dire.
##   BIDONE   smistamento: metti la tessera nel contenitore il cui nome (o una
##            sua parola) compare dentro la tessera.
##
## Le due sonde non «leggono»: confrontano stringhe. Quando pareggiano il caso,
## la prova richiede davvero la competenza; quando lo superano, una parte dei
## punti si prende senza.
##
## ## Si giudica la specifica PEGGIORE, non la media della materia
##
## La media di una materia nasconde il difetto: la logica aveva sette insiemi di
## abbinamento, sei innocui e uno risolvibile per intero cercando la parola
## ripetuta, e la media usciva mite. Ma un bambino non gioca la media: gioca un
## insieme per volta, e quello rotto è rotto. Il verdetto guarda quindi la
## specifica PEGGIORE di ogni materia; la media resta stampata perché dice se il
## difetto è isolato o diffuso.
##
## ## Il confronto è col CASO, misurato come si gioca
##
## Le prove non usano l'insieme intero: ne pescano una manciata. Quindi anche la
## sonda gioca su estrazioni vere, ripetute, della dimensione vera. Con K coppie
## da abbinare il caso azzecca 1/K; con C contenitori il caso azzecca 1/C.
##
## Uso: godot --headless --path godot --script res://scripts/game/scorciatoie_minigiochi_audit.gd

const OK := "SCORCIATOIE MINIGIOCHI audit VERDE"

## Estrazioni simulate per specifica. Duecento bastano: la misura si muove sulla
## seconda cifra decimale, e i tetti sono scritti con una cifra sola.
const ESTRAZIONI := 400

## Quanto può sporgere sopra il caso prima di essere una scorciatoia. Dieci punti
## percentuali: sotto, il vantaggio si perde nel rumore di poche estrazioni.
const MARGINE := 10.0

## Mezzo punto di tolleranza sul tetto, come in `bank_scorciatoie_audit`: una
## voce aggiunta o tolta sposta la percentuale sull'ultima cifra.
const TOLLERANZA := 0.5

## **Il debito dichiarato, materia per materia.**
##
## Il tetto è il vantaggio massimo (in punti percentuali sopra il caso) che la
## scorciatoia può ancora regalare. Come per i banchi: **scende e mai sale.**
## Chi pareggia le voci di una materia abbassa il numero qui sotto; chi aggiunge
## contenuto che sporge trova rosso subito.
##
## Tre materie stanno sopra il margine, e per una ragione che non è un difetto:
## **lì l'eco È la competenza.** In inglese il plurale irregolare e il comparativo
## si formano dalla parola di partenza (child/children, happy/happier): chi
## riconosce la radice sta facendo esattamente ciò che l'esercizio chiede. In
## latino l'etimologia e la traduzione delle frasi celebri vivono della somiglianza
## (aqua/acquedotto, «Veni, vidi, vici»/«Venni, vidi, vinsi»). In musica la glossa
## di un'indicazione ripete l'indicazione — «forte (f)» si spiega con «suonare
## forte», e non esiste un altro modo di dirlo.
##
## Queste tre restano dichiarate qui col numero misurato, non nascoste: se un
## giorno qualcuno trova glosse che non ripetono il termine, il numero scende.
const TETTO_ECO := {
	"__default__": MARGINE,
	"inglese": 25.0,
	"latino": 25.0,
	"musica": 57.0,
}
const TETTO_BIDONE := {
	"__default__": MARGINE,
}

## Parole troppo corte o troppo comuni per costituire un'eco: se contassero, ogni
## frase italiana «ripeterebbe» ogni altra frase italiana e la misura
## descriverebbe la lingua invece della scorciatoia.
const PAROLE_VUOTE := [
	"che", "chi", "con", "come", "cosa", "dei", "del", "della", "delle", "degli",
	"non", "per", "sono", "essere", "questo", "questa", "questi", "queste",
	"quello", "quella", "gli", "una", "uno", "nel", "nella", "alla", "allo",
	"dal", "dalla", "sul", "sulla", "ogni", "tutti", "tutte", "tutto", "tutta",
]

## Quante lettere iniziali bastano a far scattare l'eco morfologica. Cinque:
## «formic» → «formicaio», «pettin» → «pettinare». Sotto, parole diverse con la
## stessa radice breve verrebbero contate come eco quando non lo sono.
const RADICE := 5

var _fallimenti: Array = []


func _init() -> void:
	var eco := _misura_eco()
	var bidone := _misura_bidone()
	_stampa("ECO — abbinamento: collego alla voce che ripete una mia parola", eco, TETTO_ECO)
	print("")
	_stampa("BIDONE — smistamento: metto dove il nome del contenitore compare nella tessera", bidone, TETTO_BIDONE)
	_giudica(eco, TETTO_ECO, "eco")
	_giudica(bidone, TETTO_BIDONE, "bidone")
	if not _fallimenti.is_empty():
		printerr("SCORCIATOIE SOPRA IL TETTO — %d problemi:" % _fallimenti.size())
		for riga in _fallimenti:
			printerr("  - %s" % str(riga))
		quit(1)
		return
	print("")
	print(OK)
	quit(0)


# ---------------------------------------------------------------------------
# ECO — abbinamento
# ---------------------------------------------------------------------------

## Per ogni specifica di abbinamento: estrai K coppie come farebbe il gioco,
## mescola la colonna di destra, e collega ogni voce a sinistra con quella a
## destra che condivide più parole. A parità di punteggio la sonda tira a sorte
## fra le candidate — è quello che farebbe chi usa la scorciatoia e la trova
## ambigua — quindi il contributo di quella voce vale 1/quante sono in parità.
func _misura_eco() -> Dictionary:
	var out: Dictionary = {}
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var azzeccate := 0.0
		var totali := 0.0
		var caso := 0.0
		var peggiore := -999.0
		var peggiore_nome := "-"
		var specs: Array = Array(MinigameManager.MATCHING.get(s, []))
		for spec_index in specs.size():
			var spec: Dictionary = specs[spec_index]
			var pool := _coppie_di(spec)
			if pool.size() < 2:
				continue
			var k: int = mini(MinigameManager.matching_draw(spec, 12), pool.size())
			if k < 2:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("eco:%s:%d" % [s, spec_index])
			# Le parole si estraggono una volta per insieme, non a ogni estrazione:
			# senza questo l'audit impiega minuti invece di secondi.
			var parole_sx: Array = []
			var parole_dx: Array = []
			for coppia in pool:
				parole_sx.append(_parole(str((coppia as Array)[0])))
				parole_dx.append(_parole(str((coppia as Array)[1])))
			var spec_azzeccate := 0.0
			for _ripetizione in range(ESTRAZIONI):
				spec_azzeccate += _eco_azzeccate(_pesca_indici(pool.size(), k, rng), parole_sx, parole_dx)
			# Con K coppie da collegare, chi tira a sorte ne azzecca in media una.
			var spec_totali := float(ESTRAZIONI * k)
			var spec_caso := 100.0 / float(k)
			var vantaggio := 100.0 * spec_azzeccate / spec_totali - spec_caso
			if vantaggio > peggiore:
				peggiore = vantaggio
				peggiore_nome = "%s #%d" % [str(spec.get("topic", "?")), spec_index]
			azzeccate += spec_azzeccate
			totali += spec_totali
			caso += spec_caso * spec_totali / 100.0
		if totali <= 0.0:
			continue
		out[s] = {
			"sonda": 100.0 * azzeccate / totali,
			"caso": 100.0 * caso / totali,
			"peggiore": peggiore,
			"nome": peggiore_nome,
		}
	return out


## Quante voci indovina la sonda dell'eco su una estrazione. `estratti` sono gli
## indici pescati dall'insieme; le parole arrivano già calcolate.
func _eco_azzeccate(estratti: Array, parole_sx: Array, parole_dx: Array) -> float:
	var azzeccate := 0.0
	var k := estratti.size()
	for a in k:
		var sinistra: Array = parole_sx[estratti[a]]
		var migliori: Array = []
		var punteggio_migliore := 0
		for b in k:
			var punteggio := _condivise(sinistra, parole_dx[estratti[b]])
			if punteggio > punteggio_migliore:
				punteggio_migliore = punteggio
				migliori = [b]
			elif punteggio == punteggio_migliore and punteggio > 0:
				migliori.append(b)
		if punteggio_migliore == 0:
			# Nessuna eco: la scorciatoia non dice niente e si tira a caso.
			azzeccate += 1.0 / float(k)
		elif migliori.has(a):
			azzeccate += 1.0 / float(migliori.size())
	return azzeccate


# ---------------------------------------------------------------------------
# BIDONE — smistamento
# ---------------------------------------------------------------------------

## Per ogni specifica di smistamento: estrai le tessere come farebbe il gioco e
## metti ciascuna nel contenitore il cui nome compare dentro di lei. Se nessun
## nome compare, o se ne compaiono due, si tira a sorte fra i candidati.
func _misura_bidone() -> Dictionary:
	var out: Dictionary = {}
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		var azzeccate := 0.0
		var totali := 0.0
		var caso := 0.0
		var peggiore := -999.0
		var peggiore_nome := "-"
		var specs: Array = Array(MinigameManager.CLASSIFICATION.get(s, []))
		for spec_index in specs.size():
			var spec: Dictionary = specs[spec_index]
			var assegnazioni: Dictionary = spec.get("assignments", {})
			var categorie: Array = Array(spec.get("categories", []))
			if assegnazioni.is_empty() or categorie.size() < 2:
				continue
			var k: int = mini(MinigameManager.classification_draw(spec), assegnazioni.size())
			if k < 2:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("bidone:%s:%d" % [s, spec_index])
			var parole_categoria: Array = []
			for c in categorie:
				parole_categoria.append(_parole(str(c)))
			var parole_tessera: Dictionary = {}
			for tessera in assegnazioni.keys():
				parole_tessera[tessera] = _parole(str(tessera))
			var spec_azzeccate := 0.0
			var spec_totali := 0.0
			for _ripetizione in range(ESTRAZIONI):
				var tessere := ExercisePool.draw_covering(assegnazioni, categorie, k, rng)
				for tessera in tessere:
					var parole: Array = parole_tessera[tessera]
					var migliori: Array = []
					var punteggio_migliore := 0
					for c in categorie.size():
						var punteggio := _condivise(parole, parole_categoria[c])
						if punteggio > punteggio_migliore:
							punteggio_migliore = punteggio
							migliori = [c]
						elif punteggio == punteggio_migliore and punteggio > 0:
							migliori.append(c)
					var giusta := categorie.find(str(assegnazioni[tessera]))
					if punteggio_migliore == 0:
						spec_azzeccate += 1.0 / float(categorie.size())
					elif migliori.has(giusta):
						spec_azzeccate += 1.0 / float(migliori.size())
					spec_totali += 1.0
			if spec_totali <= 0.0:
				continue
			var spec_caso := 100.0 / float(categorie.size())
			var vantaggio := 100.0 * spec_azzeccate / spec_totali - spec_caso
			if vantaggio > peggiore:
				peggiore = vantaggio
				peggiore_nome = "%s #%d" % [str(spec.get("topic", "?")), spec_index]
			azzeccate += spec_azzeccate
			totali += spec_totali
			caso += spec_caso * spec_totali / 100.0
		if totali <= 0.0:
			continue
		out[s] = {
			"sonda": 100.0 * azzeccate / totali,
			"caso": 100.0 * caso / totali,
			"peggiore": peggiore,
			"nome": peggiore_nome,
		}
	return out


# ---------------------------------------------------------------------------
# Attrezzi
# ---------------------------------------------------------------------------

## Le coppie di una specifica di abbinamento, sia in forma `pairs` sia `pool`.
func _coppie_di(spec: Dictionary) -> Array:
	var grezze: Array = Array(spec.get("pairs", []))
	if grezze.is_empty():
		grezze = Array(spec.get("pool", []))
	var out: Array = []
	for entry in grezze:
		var coppia := entry as Array
		if coppia != null and coppia.size() >= 2:
			out.append([str(coppia[0]), str(coppia[1])])
	return out


func _pesca_indici(quanti: int, k: int, rng: RandomNumberGenerator) -> Array:
	var indici: Array = []
	for i in quanti:
		indici.append(i)
	for i in range(indici.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = indici[i]
		indici[i] = indici[j]
		indici[j] = tmp
	return indici.slice(0, k)


## Parole significative di un testo: minuscole, senza accenti, senza punteggiatura,
## almeno tre lettere e fuori dalle parole vuote. Ridotte alla radice, così
## «formica» e «formicaio» contano come la stessa eco.
func _parole(testo: String) -> Array:
	var pulito := _senza_accenti(testo.to_lower())
	var out: Array = []
	var corrente := ""
	for i in pulito.length():
		var c := pulito[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			corrente += c
		else:
			_aggiungi_parola(out, corrente)
			corrente = ""
	_aggiungi_parola(out, corrente)
	return out


func _aggiungi_parola(out: Array, parola: String) -> void:
	if parola.length() < 3 or PAROLE_VUOTE.has(parola):
		return
	var radice := parola.substr(0, mini(RADICE, parola.length()))
	if not out.has(radice):
		out.append(radice)


func _condivise(a: Array, b: Array) -> int:
	var n := 0
	for parola in a:
		if b.has(parola):
			n += 1
	return n


func _senza_accenti(testo: String) -> String:
	var out := ""
	for i in testo.length():
		var c := testo[i]
		match c:
			"à", "á", "â", "ä": out += "a"
			"è", "é", "ê", "ë": out += "e"
			"ì", "í", "î", "ï": out += "i"
			"ò", "ó", "ô", "ö": out += "o"
			"ù", "ú", "û", "ü": out += "u"
			_: out += c
	return out


# ---------------------------------------------------------------------------
# Referto
# ---------------------------------------------------------------------------

func _stampa(titolo: String, misure: Dictionary, tetti: Dictionary) -> void:
	print(titolo)
	print("MATERIA        SONDA   CASO   MEDIO  PEGGIORE  TETTO  SPECIFICA PEGGIORE")
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject)
		if not misure.has(s):
			continue
		var m: Dictionary = misure[s]
		var vantaggio := float(m["sonda"]) - float(m["caso"])
		print("%-13s %5.1f%% %5.1f%% %+6.1f  %+7.1f  %5.1f  %s" % [
			s, float(m["sonda"]), float(m["caso"]), vantaggio,
			float(m["peggiore"]), _tetto(tetti, s), str(m["nome"])])


func _tetto(tetti: Dictionary, subject: String) -> float:
	return float(tetti.get(subject, tetti["__default__"]))


func _giudica(misure: Dictionary, tetti: Dictionary, nome: String) -> void:
	for subject in misure.keys():
		var m: Dictionary = misure[subject]
		var peggiore := float(m["peggiore"])
		var tetto := _tetto(tetti, str(subject))
		if peggiore > tetto + TOLLERANZA:
			_fallimenti.append(
				"%s / %s: «%s» regala %+.1f punti sopra il caso (tetto %.1f)" % [
					str(subject), nome, str(m["nome"]), peggiore, tetto])
