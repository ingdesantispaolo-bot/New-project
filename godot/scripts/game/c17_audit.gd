extends SceneTree

## Audit C-17: la catena enigma copre TUTTE le 12 materie (scope ampliato
## 2026-07-21). Guard-rail di regressione al livello dati/contratto — non tocca
## la scena: verifica che ogni materia abbia un banco giocabile, un tema enigma
## RENDERIZZABILE (non il solo fallback) e che `build_enigma` produca un contratto
## coerente (kind/theme/stages). Blocca in particolare la ricaduta silenziosa dei
## 4 temi nuovi (mappa/serra/rete/griglia) sul default "ponte".
## Uso: godot --headless --path godot --script res://scripts/game/c17_audit.gd

# Le 12 materie del full-Godot, nell'ordine dello scope.
const SUBJECTS := [
	"matematica", "italiano", "inglese", "coding", "fisica", "musica", "latino", "elettronica",
	"geografia", "scienze", "cittadinanza", "logica",
]

# I 4 temi introdotti da C-17 devono mappare esattamente questi, non "ponte".
const NEW_SUBJECT_THEMES := {
	"geografia": "mappa",
	"scienze": "serra",
	"cittadinanza": "rete",
	"logica": "griglia",
}

# Temi che il visual di Codex (enigma_structure.gd) sa rendere: nessuna materia
# deve puntare a un tema fuori da questo insieme (altrimenti resa incoerente).
const RENDERABLE_THEMES := [
	"ponte", "porta", "circuito", "cristalli", "reattore",
	"mappa", "serra", "rete", "griglia",
]

func _init() -> void:
	var content := ContentManager.new()
	assert(SUBJECTS.size() == 12, "il full-Godot copre 12 materie")

	for subject in SUBJECTS:
		# Banco presente e giocabile.
		assert(ContentManager.BANKS.has(subject), "banco mancante nel routing: %s" % subject)
		var theme := ContentManager.enigma_theme(subject)
		assert(theme != "", "tema enigma vuoto: %s" % subject)
		assert(RENDERABLE_THEMES.has(theme), "tema non renderizzabile per %s: %s" % [subject, theme])

		# Il contratto enigma deve essere coerente e giocabile a ogni difficoltà.
		var session := content.build_enigma(subject, 3, 4)
		assert(str(session.get("subject", "")) == subject, "subject errato: %s" % subject)
		assert(str(session.get("kind", "")) == "enigma", "kind!=enigma: %s" % subject)
		assert(str(session.get("theme", "")) == theme, "tema sessione != enigma_theme: %s" % subject)
		var stages := int(session.get("stages", 0))
		var nodes := session.get("nodes", []) as Array
		assert(stages == nodes.size(), "stages != numero campate: %s" % subject)
		assert(stages >= 1, "enigma senza campate giocabili: %s" % subject)
		for item in nodes:
			assert(str(item.get("answer", "")).strip_edges() != "", "risposta mancante (%s)" % subject)
			assert(str(item.get("explanation", "")).strip_edges() != "", "spiegazione mancante (%s)" % subject)
			assert(int(item.get("difficulty", 0)) in [1, 2, 3, 4], "difficolta invalida (%s)" % subject)

	# Lock esplicito sui 4 temi nuovi: non devono ricadere sul fallback "ponte".
	for subject in NEW_SUBJECT_THEMES.keys():
		var expected := str(NEW_SUBJECT_THEMES[subject])
		var actual := ContentManager.enigma_theme(subject)
		assert(actual == expected, "tema C-17 regredito per %s: atteso %s, trovato %s" % [subject, expected, actual])
		assert(actual != "ponte", "%s è ricaduto sul fallback 'ponte'" % subject)

	print("C-17 audit OK — 12 materie con enigma coerente; temi mappa/serra/rete/griglia agganciati")
	quit(0)
