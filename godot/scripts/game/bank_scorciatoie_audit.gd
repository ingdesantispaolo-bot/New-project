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
## Il 24 agosto 2026 è toccato a **fisica**, che era la peggiore delle dodici:
## 39,3% contro il 25% del caso. Ventinove distrattori allungati con lo stesso
## criterio, e adesso non resta **nessun** quesito in cui la più lunga sia la
## giusta con un divario visibile. Controllata anche la scorciatoia speculare,
## «tocca la più corta»: sta al 26,0%, dentro il rumore.
##
## Lo stesso giorno **elettronica**, da 38,2 a 21,9. Lì una parte del difetto non
## stava nelle stringhe ma nella struttura: le funzioni dei componenti sono a
## turno risposta e distrattore, e quella del ramo parallelo è la più lunga delle
## undici. Allungare le altre sarebbe stata imbottitura, quindi il sorteggio dei
## distrattori adesso può **legare il più vicino per lunghezza** (`pickDistractors`,
## spento di default: nessun'altra materia cambia).
##
## E **musica**, da 38,0 a 23,7. Lì il pareggio ha fatto emergere un difetto che
## non c'entrava con la lunghezza: due dei cinque argomenti dichiaravano la stessa
## avvertenza sulla croma, una con «Una» e l'altra con «La», e ogni volta che il
## sorteggio le metteva insieme l'`-attenzione` aveva due risposte giuste.
##
## E **geografia**, da 35,2 a 24,7. Qui il difetto era in buona parte nei nomi
## propri: i continenti vanno da «Asia» (4 caratteri) a «America del Nord» (16),
## e ogni Paese americano aveva la risposta più lunga di dieci caratteri. Un nome
## proprio non si allunga, quindi anche lì si lega il più vicino. Resta **un**
## quesito sopra soglia, «Qual è la capitale del Messico?»: «Città del Messico»
## batte di cinque caratteri la capitale più lunga rimasta, e l'unico modo di
## chiuderlo sarebbe aggiungere uno Stato al solo scopo di allungare il pool.
##
## E **italiano**, da 33,4 a 24,8: cinquantasei distrattori più tre riscritti voce
## per voce, perché comparivano in quesiti diversi e allungarli tutti insieme
## avrebbe sbilanciato gli altri. Anche qui restano **due** quesiti sopra soglia,
## e sono voci del vocabolario: «interrogazione» e «contraddittorio» sporgono
## rispetto a tutte le parole della loro classe e area, e il pool da cui pescano
## i distrattori non ne contiene di più lunghe.
##
## E **coding**, da 32,7 a 22,9. Lì il banco era la fusione di tre insiemi che si
## sovrapponevano — i «principi» curati, la serie numerata e un blocco compatto —
## e tredici fatti finivano chiesti due volte, spesso a difficoltà diverse.
##
## E **latino**, da 31,5 a 23,8, con lo stesso difetto di coding: tre insiemi
## sovrapposti e diciotto fatti chiesti due volte.
##
## E **inglese**, da 26,5 a 25,3, praticamente sul caso. Lì non si scende oltre
## senza fare danno: le glosse italiane sono doppie («conservare / archiviare»,
## «guasto / fallimento») perché una parola sola non distinguerebbe il senso, e
## il pool da cui si pescano i distrattori è fatto delle stesse glosse. Allungare
## quella di un'altra voce sposta il difetto su di lei. Restano quattro quesiti
## sopra soglia, dichiarati.
##
## E **matematica**, da 25,9 a 24,3. Lì il controllo è stato di altro tipo: le
## 299 domande di calcolo sono state verificate a macchina una per una (tutte
## giuste), e il difetto trovato non era la lunghezza ma la direzione — la
## tabellina si esercitava solo come «a × b», mai come divisione né come fattore
## mancante, e centootto fatti erano ripetuti identici su bande diverse. Adesso
## il primo incontro è il prodotto, il secondo il fattore mancante, il terzo la
## divisione: stesso numero di esercizi, tre direzioni invece di una.
##
## E **logica**, l'ultima, da 25,8 a 21,0. Lì il difetto non era solo la
## lunghezza: le parti astratte erano ottime, ma «sequenze» ed «esclusioni»
## erano numeri nudi con cinque gruppi ripetuti identici e tredici sequenze su
## trentuno costruite sulla stessa regola «+n». Le copie sono diventate i tipi
## che mancavano — periodicità, due serie intrecciate, cicli, orari che
## scavalcano l'ora — e le esclusioni hanno una formula sola invece di tre.
##
## **Il debito è chiuso: tutte e dodici le materie sono al caso o sotto.**
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
## **Undici materie su dodici sono sotto il caso**, e la dodicesima (inglese) è
## esattamente sul caso: la scorciatoia non fa più guadagnare niente da nessuna
## parte. Il tetto adesso serve solo a impedire che si torni indietro.
const TETTO := {
	"coding": 22.9,
	"elettronica": 21.9,
	"fisica": 21.9,
	"geografia": 24.7,
	"inglese": 25.3,
	"italiano": 24.8,
	"latino": 23.8,
	# Scesa a 20,1 il 1 settembre 2026 riscrivendo le sequenze aritmetiche: dieci
	# volte «quale numero continua» sono diventate quattro «continua», tre «quale
	# sta al decimo posto» e tre «a che posto sta questo numero». Erano aritmetica
	# con l'etichetta della logica: si rispondeva sommando la differenza all'ultimo
	# termine, senza mai formulare una regola.
	"logica": 20.1,
	"matematica": 24.3,
	"musica": 23.7,
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
