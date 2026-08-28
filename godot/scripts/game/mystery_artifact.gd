class_name MysteryArtifact
extends Area2D

const ARTIFACT_ATLAS := preload("res://assets/mystery-artifacts-atlas-v1.png")

## **Una regione per tavola, misurata sul foglio.** (20 agosto 2026)
##
## Prima era una griglia: celle 237×241, quattro colonne. La larghezza tornava
## — 948/4 = 237 — l'altezza no: 1659/7 fa 237, non 241. Il ritaglio scendeva di
## quattro pixel a ogni riga, e alla sesta il registro del mondo 24 arrivava
## decapitato con dentro un pezzo del progetto della riga sotto; gli ultimi
## quattro ritagli uscivano di 28 px oltre il bordo del foglio.
##
## Correggere 241 in 237 non bastava: **il foglio non è su una griglia**. Il
## passo del contenuto è ~228 px, gli oggetti vanno da 94 a 262 px, i margini
## sono asimmetrici e la terza colonna sfora nella cella accanto. Queste regioni
## sono misurate una per una sui pixel del foglio, come fa
## `NpcPortrait.PORTRAIT_REGIONS` per i mezzi busti. Tenuto da
## `tavole_guard_audit`.
const REGIONI := {
	"mystery-trace-01": Rect2(35, 32, 163, 195),
	"mystery-trace-02": Rect2(239, 24, 191, 207),
	"mystery-trace-03": Rect2(450, 20, 201, 220),
	"mystery-trace-04": Rect2(675, 29, 250, 203),
	"mystery-trace-05": Rect2(27, 259, 171, 193),
	"mystery-trace-06": Rect2(232, 255, 193, 190),
	"mystery-trace-07": Rect2(453, 251, 204, 217),
	"mystery-trace-08": Rect2(690, 251, 205, 206),
	"mystery-trace-09": Rect2(10, 482, 197, 198),
	"mystery-trace-10": Rect2(212, 482, 248, 198),
	"mystery-trace-11": Rect2(467, 495, 208, 173),
	"mystery-trace-12": Rect2(694, 524, 240, 96),
	"mystery-trace-13": Rect2(12, 719, 228, 187),
	"mystery-trace-14": Rect2(263, 712, 164, 206),
	"mystery-trace-15": Rect2(450, 720, 198, 182),
	"mystery-trace-16": Rect2(666, 715, 264, 204),
	"mystery-trace-17": Rect2(21, 946, 202, 175),
	"mystery-trace-18": Rect2(233, 986, 210, 118),
	"mystery-trace-19": Rect2(456, 947, 214, 181),
	"mystery-trace-20": Rect2(695, 959, 231, 164),
	"mystery-trace-21": Rect2(18, 1169, 202, 178),
	"mystery-trace-22": Rect2(242, 1170, 197, 174),
	"mystery-trace-23": Rect2(451, 1166, 217, 194),
	"mystery-trace-24": Rect2(677, 1169, 259, 200),
	"mystery-seed-schede": Rect2(13, 1411, 234, 195),
	"mystery-seed-stanza": Rect2(249, 1378, 234, 234),
	"mystery-seed-sigillo": Rect2(496, 1396, 186, 199),
	"mystery-seed-tredicesimo": Rect2(692, 1396, 235, 212),
}

## Il lato lungo di un'illustrazione a schermo, in pixel. Le regioni sono
## aderenti all'oggetto e quindi tutte diverse — dal foglio di appunti largo e
## basso (240×96) alla cassa quadrata — e senza una normalizzazione la stessa
## traccia sarebbe grande o piccola a seconda di quanto spazio occupava sul
## foglio, che non significa niente. Si normalizza sul **lato maggiore**, non
## sull'altezza: altrimenti un oggetto basso e largo uscirebbe dal suo posto.
## Novantadue è la misura che avevano prima (241 × 0,38).
const LATO_A_SCHERMO := 92.0

var artifact_kind := "trace"
var display_label := ""
var accent := Color("f6c85f")
var tavola := ""
var _has_illustration := false

func configure(kind: String, id: String, payload: Dictionary, high_contrast: bool) -> void:
	artifact_kind = kind
	display_label = str(payload.get("oggetto", payload.get("dove", "Indizio"))).capitalize()
	tavola = str(payload.get("tavola", "")) if kind == "trace" else MysteryCatalog.tavola_per_seme(payload)
	accent = Color.WHITE if high_contrast else (
		Color("f6c85f") if kind == "trace"
		else Color("8fd8d0") if str(payload.get("dove", "")) == "oggetto"
		else Color("c9a7ff") if str(payload.get("dove", "")) == "dialogo"
		else Color("ffad91"))
	name = "%s_%s" % [kind.capitalize(), id.replace("-", "_")]
	set_meta("kind", "mystery_%s" % kind)
	set_meta("id", id)
	set_meta("payload", payload.duplicate(true))
	set_meta("tavola", tavola)
	add_to_group("world_interactable")
	add_to_group("mystery_artifact")
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 48.0
	collision.shape = circle
	add_child(collision)
	_add_illustration()
	var label := Label.new()
	label.name = "ArtifactLabel"
	label.text = "TRACCIA" if kind == "trace" else "SEME · %s" % str(payload.get("dove", "dettaglio")).to_upper()
	if high_contrast:
		# **Il nome tronca in stringa, non nel box.** (28 agosto 2026) — Trovato
		# giocando: con un oggetto dal nome lungo ("Bastone da conteggio dei
		# Primi") il testo usciva dal bordo destro dello schermo. `size`,
		# `clip_text` e `autowrap_mode` sul Label non hanno effetto qui — non è
		# dentro un Container, e verificato con una prova a schermo che nessuno
		# dei tre cambiava un pixel del render. Troncare la stringa PRIMA di
		# assegnarla a `label.text` funziona sempre, perché non dipende dal
		# layout: 22 caratteri sono già più del doppio del nome più lungo visto
		# finora senza alto contrasto ("Bastone da conteggio").
		var nome_esteso := display_label.to_upper()
		if nome_esteso.length() > 22:
			nome_esteso = "%s…" % nome_esteso.substr(0, 21)
		label.text = "TRACCIA · %s" % nome_esteso if kind == "trace" else "SEME · %s" % nome_esteso
	label.position = Vector2(-92, 43)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.96))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.accessibility_name = "%s, %s" % [label.text, display_label]
	add_child(label)
	queue_redraw()

func _add_illustration() -> void:
	if not REGIONI.has(tavola):
		return
	var regione: Rect2 = REGIONI[tavola]
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = ARTIFACT_ATLAS
	atlas_texture.region = regione
	var illustration := Sprite2D.new()
	illustration.name = "ArtifactIllustration"
	illustration.texture = atlas_texture
	var fattore := LATO_A_SCHERMO / maxf(regione.size.x, regione.size.y)
	illustration.scale = Vector2(fattore, fattore)
	illustration.position = Vector2(0, -4)
	illustration.z_index = 1
	illustration.set_meta("accessibility_name", display_label)
	add_child(illustration)
	_has_illustration = true

func _draw() -> void:
	draw_circle(Vector2(0, 18), 30.0, Color(0.02, 0.06, 0.07, 0.86))
	if _has_illustration:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 28, accent, 2.5, true)
		return
	if artifact_kind == "trace":
		draw_rect(Rect2(-24, -24, 48, 54), Color("ddd1a8"), true)
		for y in [-10, 0, 10]:
			draw_line(Vector2(-15, y), Vector2(15 if y != 0 else 10, y), accent, 3.0, true)
	else:
		var where := str(get_meta("payload", {}).get("dove", "dettaglio"))
		if where == "oggetto":
			draw_circle(Vector2.ZERO, 22.0, Color(accent, 0.62))
			draw_circle(Vector2.ZERO, 9.0, Color("10272b"))
		elif where == "dialogo":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-27, -18), Vector2(27, -18), Vector2(27, 14),
				Vector2(5, 14), Vector2(-7, 27), Vector2(-7, 14), Vector2(-27, 14)]),
				Color(accent, 0.72))
		else:
			draw_rect(Rect2(-22, -22, 44, 44), Color(accent, 0.58), true)
			draw_line(Vector2(-16, 16), Vector2(16, -16), Color("10272b"), 4.0, true)
	draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 28, accent, 2.5, true)
