extends SceneTree

## **L'energia si guadagna allo stesso ritmo in tutti i mondi.** (14 agosto 2026)
##
## Questo audit nasce da una voce di piano che la misura ha **smentito**, ed è il
## motivo per cui esiste invece di una modifica.
##
## G-5 diceva: «un esercizio del mondo 22 paga come una tabellina del mondo 1»,
## e proponeva di scalare la tariffa con la banda di difficoltà. La frase è vera
## per esercizio ed è **falsa per minuto giocato**, che è l'unica unità in cui la
## domanda ha senso: un mondo alto ha formati più lenti e più sessioni, e il
## conto si chiude da solo. Misurato con `economy_probe` su tutti e ventiquattro i
## mondi: da **40,6 a 45,4 energia al minuto**, cioè uno squilibrio di **1,12x**.
##
## Scalare le tariffe avrebbe *creato* lo squilibrio che voleva togliere: i mondi
## alti avrebbero pagato il doppio al minuto, e tornare indietro a ripassare —
## che il design chiama esplicitamente «ripasso mirato» — sarebbe diventato un
## modo per perdere tempo. La riparazione giusta a un difetto che non c'è è un
## cricchetto che impedisca di introdurlo.
##
## **Le due cose che tiene:**
##
## 1. **Nessun mondo paga molto più in fretta di un altro.** Se un giorno una
##    tariffa scala col livello, o un formato lento diventa velocissimo, qui si
##    vede subito.
## 2. **Nessuna sessione paga più del doppio della sua tariffa piatta.** È il
##    tetto della serie ([[Combo]]), riverificato dal lato dell'economia invece
##    che da quello della regola: due strade diverse allo stesso numero.
##
## Il totale di campagna — 53.783 energia senza errori, 42.758 sbagliandone una su
## cinque, contro le 72.600 del catalogo, cioè il **74%** e il **59%** — resta in
## `economy_probe`: richiede la simulazione del gate e sarebbe un minuto di suite
## per un numero che cambia solo quando cambia il costo dei mondi.

const OK := "ECONOMY CURVE audit VERDE"

## Durata stimata per formato. Rispecchia `time_cost_probe.DURATA` e
## `economy_probe.DURATA`: sono stime dichiarate, non un cronometro, e servono a
## confrontare i mondi fra loro — non a dire quanto dura davvero una partita.
const DURATA := {
	"multiple_choice": 12.0, "numeric_input": 20.0, "short_answer": 22.0,
	"matching": 42.0, "ordering": 34.0, "classification": 38.0, "cycle": 34.0,
	"graph": 26.0, "circuit": 28.0, "notation": 24.0, "map": 26.0,
	"hotspot": 24.0, "code_debug": 30.0, "number_line": 20.0, "balance": 26.0,
	"timeline": 26.0, "compose": 24.0, "trace": 32.0, "clue": 40.0, "swipe": 55.0,
}

## Lo squilibrio massimo ammesso fra il mondo che paga più in fretta e quello che
## paga più piano. Misurato 1,12x; la soglia lascia margine ai contenuti che
## cambiano e prende qualunque scalata deliberata delle tariffe.
const SQUILIBRIO_MASSIMO := 1.45

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _durata(nodes: Array) -> float:
	var t := 0.0
	for node in nodes:
		t += float(DURATA.get(str((node as Dictionary).get("format", "multiple_choice")), 15.0))
	return t

## L'energia di una sessione giocata senza errori, con le regole vere: la tariffa
## dichiarata, moltiplicata dalla serie, più il premio di completamento.
func _energia(session: Dictionary) -> int:
	var nodi: Array = session.get("nodes", [])
	var premi: Dictionary = session.get("rewards", {})
	var base := int(premi.get("energyPerCorrect", 10))
	var guadagno := 0
	for indice in range(nodi.size()):
		guadagno += Combo.energia(base, indice + 1)
	return guadagno + int(Dictionary(premi.get("onComplete", {})).get("energy", 0))

func _init() -> void:
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var rng := RandomNumberGenerator.new()
	var ritmi: Array = []
	var peggiore_mondo := 0
	var migliore_mondo := 0
	var lento := 99999.0
	var veloce := 0.0

	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var focus := ApparatusConfig.world_subject(livello)
		var energia := 0
		var secondi := 0.0
		var missione: Dictionary = content.build_mission(focus, livello, 3)
		energia += _energia(missione)
		secondi += _durata(missione.get("nodes", []))
		rng.seed = livello * 7919
		var pratica: Dictionary = mg.build_minigame(focus, livello, rng)
		if not Array(pratica.get("nodes", [])).is_empty():
			energia += _energia(pratica)
			secondi += _durata(pratica.get("nodes", []))
		if secondi <= 0.0:
			_controlla(false, "mondo %d: sessioni di durata nulla" % livello)
			continue
		var ritmo := float(energia) / (secondi / 60.0)
		ritmi.append(ritmo)
		if ritmo < lento:
			lento = ritmo
			peggiore_mondo = livello
		if ritmo > veloce:
			veloce = ritmo
			migliore_mondo = livello

		# **Il tetto della serie, visto dall'economia.** Una sessione perfetta non
		# può pagare più del doppio della sua tariffa piatta, premio di
		# completamento escluso: è la promessa di `Combo`, e vale la pena
		# verificarla anche di qui perché è il punto in cui una modifica alle
		# ricompense la romperebbe senza toccare `combo.gd`.
		for sessione_data in [missione, pratica]:
			var sessione: Dictionary = sessione_data
			var nodi: Array = sessione.get("nodes", [])
			if nodi.is_empty():
				continue
			var base := int(Dictionary(sessione.get("rewards", {})).get("energyPerCorrect", 10))
			var piatto := base * nodi.size()
			var con_serie := 0
			for indice in range(nodi.size()):
				con_serie += Combo.energia(base, indice + 1)
			_controlla(float(con_serie) <= float(piatto) * Combo.MASSIMO,
				"mondo %d: una sessione perfetta paga %d contro %d piatti, oltre il tetto della serie" % [
					livello, con_serie, piatto])

	_controlla(ritmi.size() == ApparatusConfig.MAX_LEVEL,
		"misurati %d mondi su %d" % [ritmi.size(), ApparatusConfig.MAX_LEVEL])
	if not ritmi.is_empty():
		var squilibrio := veloce / maxf(lento, 0.01)
		_controlla(squilibrio <= SQUILIBRIO_MASSIMO,
			"il mondo %d paga %.1f energia al minuto e il mondo %d %.1f: squilibrio %.2fx (massimo %.2fx)" % [
				migliore_mondo, veloce, peggiore_mondo, lento, squilibrio, SQUILIBRIO_MASSIMO])
		print("Ritmo dell'energia: da %.1f (mondo %d) a %.1f (mondo %d) al minuto · squilibrio %.2fx" % [
			lento, peggiore_mondo, veloce, migliore_mondo, squilibrio])

	if errori.is_empty():
		print(OK)
	else:
		printerr("ECONOMY CURVE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
