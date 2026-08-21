extends SceneTree

## **Le tre scorciatoie che fanno rispondere giusto senza sapere niente.**
## (21 agosto 2026)
##
## Domanda del committente dopo il difetto del duello dei verbi: *«possono
## esserci casi simili in altre materie?»*. Misurato: sì.
##
## Nel duello la scorciatoia era «la domanda e la risposta usano le stesse
## parole». In una banca a scelta multipla le scorciatoie sono tre, e nessuna
## richiede di aver capito la domanda:
##
##   LUNGHEZZA   si tocca l'opzione più lunga. È la più forte, perché la risposta
##               giusta tende a essere la più precisa, e la più precisa tende a
##               essere la più lunga;
##   POSIZIONE   la risposta giusta sta sempre nella stessa casella;
##   ECO         la risposta giusta ripete le parole della domanda.
##
## ## Il margine, e perché la prima misura era troppo severa
##
## La prima stesura contava «la risposta è la più lunga» e basta. Contava quindi
## anche «Mercurio (8) contro Saturno (7)», che nessun bambino può sfruttare:
## un carattere non si vede. Il numero che ne usciva descriveva la prosa italiana,
## non una scorciatoia giocabile.
##
## Adesso la scorciatoia è simulata come la userebbe qualcuno: **tocco la più
## lunga se il divario si vede, altrimenti tiro a caso**. `MARGINE_VISIBILE` è
## cinque caratteri, cioè circa una parola. Il confronto è col **caso**: con
## quattro opzioni si azzecca il 25%, e tutto ciò che sta sopra è quello che la
## scorciatoia regala.
##
## ## Il debito dichiarato
##
## Il 21 agosto 2026 scienze e storia sono state pareggiate a mano — 68 distrattori
## allungati, mai accorciando la risposta giusta, perché la sua precisione è
## contenuto didattico mentre la lunghezza di un distrattore non lo è. Sono
## scese sotto il caso: la scorciatoia lì adesso **fa perdere**.
##
## Le altre nove restano sopra, e il loro tetto è quello che avevano quel giorno.
## Serve a due cose, e la seconda vale più della prima:
##
##   1. **non si può peggiorare**: un blocco di quesiti nuovi che sposta una
##      materia oltre il suo tetto diventa rosso subito;
##   2. **il debito è visibile e si accorcia**. Ogni volta che qualcuno pareggia
##      i distrattori di una materia, abbassa il numero qui sotto. Un debito che
##      non sta scritto da nessuna parte non viene mai pagato.
##
## Uso: godot --headless --path godot --script res://scripts/game/bank_scorciatoie_audit.gd

const OK := "BANK SCORCIATOIE audit VERDE"
const CARTELLA := "res://data/banks"

## Quanti caratteri di differenza si vedono a colpo d'occhio. Cinque: circa una
## parola. Sotto, due opzioni sembrano lunghe uguale e la scelta torna fortuna.
const MARGINE_VISIBILE := 5

## Mezzo punto di tolleranza sul tetto: i tetti sono scritti con un decimale, e
## un quesito aggiunto o tolto sposta la percentuale sull'ultima cifra.
const TOLLERANZA := 0.5

## Quanto la scorciatoia può battere il caso in una materia già sana.
const BANDA := 5.0

## Il tetto per materia, misurato il 21 agosto 2026. Si abbassa, non si alza.
## Scienze e storia sono **sotto il caso**: là la scorciatoia fa perdere.
const TETTO := {
	"coding": 32.7,
	"elettronica": 38.2,
	"fisica": 39.3,
	"geografia": 35.2,
	"inglese": 26.5,
	"italiano": 33.4,
	"latino": 31.5,
	"logica": 25.8,
	"matematica": 25.9,
	"musica": 38.0,
	"scienze": 22.1,
	"storia": 22.2,
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
	print("MATERIA        quesiti  scorciatoia  caso  tetto")
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

	# **La scorciatoia della LUNGHEZZA, giocata come la giocherebbe qualcuno.**
	var vittorie := 0.0
	var caso := 0.0
	var caselle: Dictionary = {}
	var eco := 0.0
	var eco_caso := 0.0
	for voce_data in quesiti:
		var voce: Dictionary = voce_data
		var opzioni: Array = voce["options"]
		var giusta := str(voce["answer"])
		var quante := float(opzioni.size())
		caso += 1.0 / quante

		var prima := 0
		var seconda := 0
		for o in opzioni:
			var quanto := str(o).length()
			if quanto > prima:
				seconda = prima
				prima = quanto
			elif quanto > seconda:
				seconda = quanto
		if prima - seconda >= MARGINE_VISIBILE:
			vittorie += 1.0 if giusta.length() == prima else 0.0
		else:
			vittorie += 1.0 / quante

		var casella := opzioni.find(voce["answer"])
		caselle[casella] = int(caselle.get(casella, 0)) + 1

		# **L'ECO**: la risposta giusta ripete le parole della domanda?
		var dalla_domanda := _parole(str(voce.get("prompt", "")))
		var migliore := 0
		var quanti_migliori := 0
		var punteggio_giusta := 0
		for o in opzioni:
			var comuni := 0
			for parola in _parole(str(o)):
				if dalla_domanda.has(parola):
					comuni += 1
			if str(o) == giusta:
				punteggio_giusta = comuni
			if comuni > migliore:
				migliore = comuni
				quanti_migliori = 1
			elif comuni == migliore:
				quanti_migliori += 1
		if migliore > 0 and punteggio_giusta == migliore:
			eco += 1.0 / float(maxi(quanti_migliori, 1))
		eco_caso += 1.0 / quante

	var n := float(quesiti.size())
	var quota := 100.0 * vittorie / n
	var quota_caso := 100.0 * caso / n
	var tetto := float(TETTO.get(materia, quota_caso + BANDA))
	print("%-14s %7d  %10.1f%% %5.1f%% %6.1f" % [
		materia, quesiti.size(), quota, quota_caso, tetto])
	_controlla(quota <= tetto + TOLLERANZA,
		"%s: «tocca la più lunga» vince il %.1f%% contro il %.1f%% del caso (tetto %.1f). Si pareggiano i distrattori, non si alza il tetto." % [
			materia, quota, quota_caso, tetto])

	_controlla(100.0 * eco / n <= 100.0 * eco_caso / n + BANDA,
		"%s: la risposta giusta ripete le parole della domanda più del caso: si vince rileggendo, non capendo" % materia)

	# La POSIZIONE era già sana ovunque il 21 agosto 2026, e va tenuta tale:
	# «è sempre la seconda» si impara in una sessione.
	var quote := int(Array(Dictionary(quesiti[0])["options"]).size())
	for casella in caselle.keys():
		var percentuale := 100.0 * float(caselle[casella]) / n
		_controlla(percentuale <= 100.0 / float(maxi(quote, 1)) + BANDA * 2.0,
			"%s: la risposta giusta sta nella casella %d nel %.1f%% dei quesiti" % [
				materia, int(casella), percentuale])

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
