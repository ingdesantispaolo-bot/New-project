extends SceneTree

const DIRECTOR := preload("res://scripts/game/thirteenth.gd")

func _init() -> void:
	var before = DIRECTOR.new()
	before.setup(16, "audit")
	assert(not before.is_present(), "il Tredicesimo appare prima del mondo 17")
	assert(before.ambient_action() == "", "azione ambientale prima dell'ingresso")
	assert(before.next_voice().is_empty(), "voce prima del mondo 18")

	var memory = DIRECTOR.new()
	memory.setup(18, "audit", ["gia-usato"], "proprietario")
	var first := memory.choose_forgotten_resident(
		["proprietario", "gia-usato", "libero-a", "libero-b"])
	assert(first in ["libero-a", "libero-b"], "smemora non sceglie un residente libero")
	var second := memory.choose_forgotten_resident(
		["proprietario", "gia-usato", "libero-a", "libero-b"])
	assert(second in ["libero-a", "libero-b"] and second != first,
		"smemora ripete lo stesso residente")
	assert(memory.choose_forgotten_resident(
		["proprietario", "gia-usato", "libero-a", "libero-b"]) == "",
		"smemora usa il proprietario della missione o ripete un residente")

	var routes = DIRECTOR.new()
	routes.setup(19, "audit")
	assert(routes.choose_closed_route([
		{"id": "unica", "open": true}], "apparato") == "",
		"chiude ha sigillato l'unica strada")
	assert(routes.choose_closed_route([
		{"id": "apparato", "open": true}, {"id": "alternativa", "open": true}
	], "apparato") == "alternativa", "chiude non preserva la sala apparati")
	assert(routes.choose_closed_route([
		{"id": "solo-segnato", "open": true, "onlyPath": true},
		{"id": "apparato", "open": true}
	], "apparato") == "", "chiude ignora il marcatore di percorso unico")

	var voice = DIRECTOR.new()
	voice.setup(20, "audit")
	assert(not voice.next_voice().is_empty(), "nessuna voce nel mondo 20")
	assert(voice.debug_state().get("ambientAction") == "chiude",
		"sequenza ambientale non deterministica")

	print("Thirteenth runtime audit OK - memoria e percorsi protetti")
	quit(0)
