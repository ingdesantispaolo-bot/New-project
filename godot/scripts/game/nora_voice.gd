class_name NoraVoice
extends RefCounted

## Voce di NORA per i momenti della sessione (C-15), porting di
## src/core/NoraVoice.ts: frasi brevi, in carattere, mai giudicanti, che
## rimandano al METODO (osserva, prova, verifica) invece di dare la risposta.
##
## Non introduce una trama parallela: la storia a beat di livello resta in
## `NarrativeManager` (6 beat, 1→6). Qui sono reazioni al momento — avvio,
## esito, ripasso — non un arco narrativo.
##
## Beat del prototipo Phaser NON portati qui, di proposito: "sabotage" e
## "bossDefeat" presupponevano un sabotatore in tempo reale che non esiste nel
## loop Godot attuale (missione → gate → esame → livello); "streak" richiede
## un conteggio di serie che oggi non è tracciato in OutdoorGameplay. Meglio
## ometterli che inventare una meccanica fittizia.

const LINES := {
	"solve": [
		"Sistema stabilizzato! Hai seguito il metodo, non la fortuna.",
		"Ottima diagnosi: un altro nodo che torna a funzionare.",
		"Pulito. Hai capito la causa, non solo l'effetto.",
		"Sentito? È il rumore di qualcosa che torna a funzionare. Avanti.",
	],
	"victory": [
		"Apparato riparato! Hai rimesso in linea il sistema. Sei brava davvero.",
		"Energia stabile, livello aperto. Caso chiuso, agente.",
		"Tutte le console cantano, qui. Missione tua, a pieno titolo.",
	],
	"defeat": [
		"Pausa, non sconfitta. Ora sai dove guardare: riproviamo.",
		"Il sistema resiste, ma tu hai imparato la mappa del guasto.",
		"Capita. Cambia un solo passaggio e riprova: il resto andava bene.",
	],
	"scaffold": [
		"Ho già visto questo schema: te lo ripropongo per fissarlo bene.",
		"Conosco questo nodo: torniamo a ripassarlo insieme.",
	],
}

var _last_index: Dictionary = {}  # beat -> ultimo indice estratto (anti-ripetizione)

## Una frase per il beat, evitando la ripetizione immediata della stessa (come
## `noraVoice.line()` in TS). `rng` opzionale per determinismo nei test.
func line(beat: String, rng: RandomNumberGenerator = null) -> String:
	var pool: Array = LINES.get(beat, [])
	if pool.is_empty():
		return ""
	if pool.size() == 1:
		return str(pool[0])
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var index := generator.randi_range(0, pool.size() - 1)
	if int(_last_index.get(beat, -1)) == index:
		index = (index + 1) % pool.size()
	_last_index[beat] = index
	return str(pool[index])
