extends SceneTree

const ACTOR := preload("res://scripts/game/npc_actor.gd")
const PORTRAIT := preload("res://scripts/ui/npc_portrait.gd")
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog: Dictionary = NpcCatalog.RESIDENTS.duplicate()
	catalog.merge(NpcCatalog.BISLACCHI)
	catalog.merge(ItinerantCatalog.ITINERANTI)
	assert(catalog.size() == 75, "catalogo visuale inatteso: %d" % catalog.size())
	for npc_id in catalog:
		var texture := PORTRAIT.art_for(str(npc_id))
		var asset_path := texture.resource_path if texture != null else ""
		assert(ResourceLoader.exists(asset_path), "asset illustrato assente: %s" % asset_path)
		assert(texture != null and texture.get_width() == 384 and texture.get_height() == 384,
			"asset %s non normalizzato a 384x384" % npc_id)
		var image := texture.get_image()
		assert(image != null and image.get_pixel(0, 0).a < 0.02 and image.get_pixel(383, 383).a < 0.02,
			"asset %s senza alpha pulito agli angoli" % npc_id)

		var actor := ACTOR.new() as Area2D
		root.add_child(actor)
		actor.call("configure", npc_id, {"nome": npc_id, "ruolo": "audit"}, true)
		var art := actor.get_node_or_null("NpcArt") as Sprite2D
		assert(art != null and art.texture.resource_path == asset_path,
			"NpcActor non usa correttamente l'illustrazione di %s" % npc_id)
		actor.call("set_stream_active", true)
		assert(not actor.is_processing(), "riduzione movimento ignorata per %s" % npc_id)
		assert(PORTRAIT.portrait_art_for(npc_id) != null,
			"ritratto illustrato assente per %s" % npc_id)
		actor.queue_free()

	assert(PORTRAIT.art_for("npc-inesistente") == null,
		"un ID sconosciuto deve mantenere il fallback")
	print("NPC VISUAL ART audit OK - 75 personaggi alpha, mondo e ritratti con fallback")
	quit(0)
