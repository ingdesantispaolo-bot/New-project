extends SceneTree

## **Le tre scorciatoie che fanno rispondere giusto senza sapere niente.**
## (21 agosto 2026)
##
## Domanda del committente dopo il difetto del duello dei verbi: *«possono
## esserci casi simili in altre materie o in altri minigiochi?»*. Misurato: sì.
##
## Nel duello la scorciatoia era «la domanda e la risposta usano le stesse
## parole». In una banca a scelta multipla le scorciatoie possibili sono tre, e
## nessuna delle tre richiede di aver capito la domanda:
##
##   LUNGHEZZA   si tocca l'opzione più lunga. È la più forte, perché la
##               risposta giusta tende a essere la più precisa, e la più precisa
##               tende a essere la più lunga;
##   POSIZIONE   la risposta giusta sta sempre nella stessa casella;
##   ECO         la risposta giusta ripete le parole della domanda.
##
## ## Come si legge lo scarto
##
## Non conta la percentuale nuda: con quattro opzioni, «la più lunga» azzecca il
## 25% per puro caso, e se in una materia le opzioni hanno spesso la stessa
## lunghezza il caso sale. Conta lo **scarto** fra quanto la scorciatoia vince e
## quanto vincerebbe il caso in **quella** banca. Zero significa che la
## scorciatoia non insegna niente a chi la usa; trentacinque significa che
## risponde giusto sei volte su dieci contro le tre del caso.
##
## ## Il debito dichiarato, e perché sta scritto qui
##
## Il 21 agosto 2026 nove materie su dodici erano sopra la banda. Sistemare quei
## quesiti è lavoro di **contenuto** — si pareggiano i distrattori, uno per uno,
## e non lo si fa con una sostituzione automatica senza peggiorarli. Quindi
## questo audit nasce con il debito **scritto per esteso**: ogni materia ha il
## suo tetto, e il tetto è quello che aveva quel giorno.
##
## Serve a due cose, e la seconda vale più della prima:
##
##   1. **non si può peggiorare.** Un blocco di quesiti nuovi che sposta una
##      materia oltre il suo tetto diventa rosso subito;
##   2. **il debito è visibile e si accorcia.** Ogni volta che qualcuno pareggia
##      i distrattori di una materia, abbassa il numero qui sotto. Un debito che
##      non sta scritto da nessuna parte non viene mai pagato.
##
## Le tre materie già in banda — logica, matematica, inglese — hanno il tetto
## della banda e non un tetto su misura: non devono poter scivolare.
##
## Uso: godot --headless --path godot --script res://scripts/game/bank_scorciatoie_audit.gd

const OK := "BANK SCORCIATOIE audit VERDE"
const CARTELLA := "res://data/banks"

## Quanto una scorciatoia può battere il caso senza che sia un difetto. Cinque
## punti: sotto, è rumore statistico su banche da un centinaio di quesiti.
const BANDA := 5.0

## Il debito del 21 agosto 2026, materia per materia, in punti di scarto sulla
## scorciatoia della LUNGHEZZA. Si abbassa, non si alza.
const DEBITO_LUNGHEZZA := {
	"scienze": 35.0,
	"storia": 21.1,
	"musica": 19.7,
	"fisica": 15.9,
	"coding": 15.3,
	"elettronica": 14.4,
	"geografia": 11.0,
	"latino": 7.9,
	"italiano": 7.4,
}

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	var banche := _banche()
	_controlla(banche.size() >= 12,
		"trovate %d banche invece delle dodici materie" % banche.size())
	print("")
	print("MATERIA        quesiti  lunghezza  atteso  scarto  tetto")
	for percorso in banche:
		_misura(percorso)
	print("")
	if errori.is_empty():
		print(OK)
	else:
		printerr("BANK SCORCIATOIE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _banche() -> Array:
	var fuori: Array = []
	var d := DirAccess.open(CARTELLA)
	if d == null:
		return fuori
	d.list_dir_begin()
	var nome := d.get_next()
	while nome != "":
		if not d.current_is_dir() and nome.ends_with(".json"):
			fuori.append("%s/%s" % [CARTELLA, nome])
		nome = d.get_next()
	d.list_dir_end()
	fuori.sort()
	return fuori

func _misura(percorso: String) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(percorso))
	if typeof(parsed) != TYPE_DICTIONARY:
		errori.append("banca illeggibile: %s" % percorso)
		return
	var banca: Dictionary = parsed
	var materia := str(banca.get("subject", percorso.get_file()))
	var quesiti: Array = []
	for voce_data in Array(banca.get("items", [])):
		var voce: Dictionary = voce_data
		if str(voce.get("format", "")) != "multiple_choice":
			continue
		var opzioni: Array = voce.get("options", [])
		if opzioni.size() < 2 or not opzioni.has(voce.get("answer")):
			continue
		quesiti.append(voce)
	if quesiti.is_empty():
		return

	var lunga := 0
	var attesa := 0.0
	var caselle: Dictionary = {}
	var eco := 0
	var eco_attesa := 0.0
	for voce_data in quesiti:
		var voce: Dictionary = voce_data
		var opzioni: Array = voce["options"]
		var giusta := str(voce["answer"])
		var quante := float(opzioni.size())

		# LUNGHEZZA
		var massima := 0
		for o in opzioni:
			massima = maxi(massima, str(o).length())
		var quante_massime := 0
		for o in opzioni:
			if str(o).length() == massima:
				quante_massime += 1
		if giusta.length() == massima:
			lunga += 1
		attesa += float(quante_massime) / quante

		# POSIZIONE
		var casella := opzioni.find(voce["answer"])
		caselle[casella] = int(caselle.get(casella, 0)) + 1

		# ECO
		var dalla_domanda := _parole(str(voce.get("prompt", "")))
		var punteggi: Array = []
		var migliore := 0
		for o in opzioni:
			var comuni := 0
			for parola in _parole(str(o)):
				if dalla_domanda.has(parola):
					comuni += 1
			punteggi.append(comuni)
			migliore = maxi(migliore, comuni)
		if migliore > 0:
			var quante_migliori := 0
			for p in punteggi:
				if int(p) == migliore:
					quante_migliori += 1
			if int(punteggi[casella]) == migliore:
				eco += 1
			eco_attesa += float(quante_migliori) / quante
		else:
			eco_attesa += 1.0 / quante

	var n := float(quesiti.size())
	var scarto_lunghezza := 100.0 * float(lunga) / n - 100.0 * attesa / n
	var tetto := maxf(BANDA, float(DEBITO_LUNGHEZZA.get(materia, BANDA)))
	print("%-14s %7d  %8.1f%% %6.1f%% %6.1f  %5.1f" % [
		materia, quesiti.size(), 100.0 * float(lunga) / n, 100.0 * attesa / n,
		scarto_lunghezza, tetto])
	# Mezzo punto di tolleranza: il debito e' scritto con un decimale, e un
	# quesito aggiunto o tolto sposta la percentuale dell'ultima cifra.
	_controlla(scarto_lunghezza <= tetto + 0.5,
		"%s: «tocca la piu' lunga» batte il caso di %.1f punti (tetto %.1f). Si pareggiano i distrattori, non si alza il tetto." % [
			materia, scarto_lunghezza, tetto])

	var scarto_eco := 100.0 * float(eco) / n - 100.0 * eco_attesa / n
	_controlla(scarto_eco <= BANDA,
		"%s: la risposta giusta ripete le parole della domanda %.1f punti piu' del caso: si vince rileggendo, non capendo" % [
			materia, scarto_eco])

	# La POSIZIONE deve restare uniforme: nessuna casella oltre la sua quota piu'
	# la banda. E' l'unica delle tre che al 21 agosto 2026 era gia' sana ovunque,
	# e va tenuta tale — «e' sempre la seconda» si impara in una sessione.
	var quote := int(Array(Dictionary(quesiti[0])["options"]).size())
	for casella in caselle.keys():
		var quota := 100.0 * float(caselle[casella]) / n
		_controlla(quota <= 100.0 / float(maxi(quote, 1)) + BANDA * 2.0,
			"%s: la risposta giusta sta nella casella %d nel %.1f%% dei quesiti" % [
				materia, int(casella), quota])

## Le parole di una stringa, minuscole e senza le troppo corte: «che», «una» e
## «per» stanno ovunque e non distinguono niente.
func _parole(testo: String) -> Dictionary:
	var fuori: Dictionary = {}
	var pulito := testo.to_lower()
	for segno in ["\n", ".", ",", ";", ":", "?", "!", "(", ")", "«", "»", "\"", "'", "/", "-", "="]:
		pulito = pulito.replace(segno, " ")
	for parola in pulito.split(" ", false):
		var p := str(parola).strip_edges()
		if p.length() > 3:
			fuori[p] = true
	return fuori
