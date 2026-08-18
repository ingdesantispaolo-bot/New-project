class_name MinigamePanelLayout
extends RefCounted

## Adattamento condiviso delle carte dei minigiochi in portrait.
##
## La scala resta una scelta della singola carta: questa funzione possiede solo
## la regola di layout (attendere il primo layout, riconoscere il portrait e
## scalare attorno al centro). In landscape non altera la resa autorata.
static func adapt_vertical(owner: Node, card: Control, portrait_scale: float = 2.0) -> void:
	if owner == null or owner.get_tree() == null:
		return
	await owner.get_tree().process_frame
	if not is_instance_valid(card):
		return
	var viewport_size := owner.get_viewport().get_visible_rect().size
	if viewport_size.y <= viewport_size.x:
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE * portrait_scale
