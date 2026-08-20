class_name SurfaceStyles
extends RefCounted

## Tre superfici condivise, piccole e ripetibili. Il contrasto elevato non
## "colora" il materiale: lo disattiva e torna a un pannello pieno verificabile.
const SHIP_GLASS := preload("res://assets/surface-ship-glass-v1.webp")
const PARCHMENT := preload("res://assets/surface-parchment-v1.webp")
const DESK := preload("res://assets/surface-desk-v1.webp")

static func ship(high_contrast: bool) -> StyleBox:
	return _surface(SHIP_GLASS, high_contrast, Color("021217"), Color("6be7d6"), 10, 12)

static func parchment(high_contrast: bool) -> StyleBox:
	return _surface(PARCHMENT, high_contrast, Color("f3dfb1"), Color("4d351d"), 10, 26)

static func desk(high_contrast: bool, accent: Color, is_exam: bool) -> StyleBox:
	var border := Color("f6c85f") if is_exam else accent
	return _surface(DESK, high_contrast, Color("07171b"), border, 18, 24)

## **La tinta è l'unico posto dove `border` può ancora parlare.** (20 agosto 2026)
##
## `StyleBoxTexture` non ha un bordo, e il colore che i chiamanti calcolavano —
## oro per l'esame, accento della materia altrimenti — arrivava qui e non veniva
## usato da nessuna riga: `is_exam` non cambiava un pixel, in nessuna delle due
## modalità, e dodici materie più un esame guardavano lo stesso banco. Prima
## della superficie condivisa l'esame aveva fondo suo, bordo oro e tre pixel di
## spessore. Adesso quella differenza torna come una velatura sul materiale:
## leggera, perché il banco resta il banco, ma visibile quando cambia.
## Tenuto da `tavole_guard_audit`.
static func _surface(texture: Texture2D, high_contrast: bool, fallback: Color,
		border: Color, radius: int, margin: int) -> StyleBox:
	if high_contrast:
		var flat := StyleBoxFlat.new()
		flat.bg_color = fallback
		# Il bordo resta bianco: ad alto contrasto la cornice deve essere la
		# stessa ovunque, ed è `accessibility_release_audit` a pretenderlo.
		flat.border_color = Color.WHITE
		flat.set_border_width_all(4)
		flat.set_corner_radius_all(radius)
		flat.set_content_margin_all(margin)
		return flat
	var styled := StyleBoxTexture.new()
	styled.texture = texture
	styled.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	styled.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	styled.modulate_color = Color.WHITE.lerp(border, 0.18)
	styled.set_content_margin_all(margin)
	styled.set_expand_margin_all(2)
	return styled
