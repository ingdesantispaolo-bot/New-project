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
	# Con lo stretch del progetto il rettangolo logico del Viewport può restare
	# landscape anche quando la finestra fisica è portrait. La Window è la fonte
	# affidabile per l'orientamento; il fallback copre i viewport incorporati.
	var viewport_size := Vector2(owner.get_tree().root.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = owner.get_viewport().get_visible_rect().size
	var physical_size := Vector2(DisplayServer.window_get_size())
	var portrait := viewport_size.y > viewport_size.x
	if physical_size.x > 0.0 and physical_size.y > 0.0:
		portrait = portrait or physical_size.y > physical_size.x
	if not portrait:
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE * portrait_scale
