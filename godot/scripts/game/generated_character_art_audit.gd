extends SceneTree

const FACTORY := preload("res://scripts/visual_factory.gd")
const GUARDIANS := preload("res://scripts/game/guardian_visual_catalog.gd")
const ENEMY := preload("res://scripts/world_enemy.gd")
const PET_KINDS := [
	"dog", "cat", "rabbit", "spark", "comet", "orbit",
	"satellite", "prisma", "luma", "guardiano", "codex",
]

func _init() -> void:
	call_deferred("_run")

func _assert_alpha_texture(texture: Texture2D, label: String) -> void:
	assert(texture != null, "%s: texture assente" % label)
	assert(texture.get_size() == Vector2(384, 384), "%s: atteso 384x384" % label)
	var image := texture.get_image()
	assert(image != null, "%s: immagine non leggibile" % label)
	for point in [Vector2i(0, 0), Vector2i(383, 0), Vector2i(0, 383), Vector2i(383, 383)]:
		assert(image.get_pixelv(point).a < 0.02, "%s: angolo senza alpha" % label)

func _run() -> void:
	for kind in PET_KINDS:
		var texture := FACTORY.pet_art_for(kind)
		_assert_alpha_texture(texture, "Custode %s" % kind)
		var visual := FACTORY.build_pet(kind, Color("f6c85f"))
		assert(bool(visual.get_meta("usesGeneratedArt", false)), "%s usa ancora il fallback" % kind)
		assert(visual.get_node_or_null("PetGeneratedArt") != null, "%s senza sprite" % kind)
		visual.free()

	assert(GUARDIANS.NAMES.size() == 24, "servono 24 nomi guardiano distinti")
	assert(GUARDIANS.FAMILIES.size() == 24, "servono 24 famiglie visuali")
	var names := {}
	var paths := {}
	for level in range(1, 25):
		var guardian_name := GUARDIANS.name_for(level)
		var path := GUARDIANS.path_for(level)
		assert(not names.has(guardian_name), "nome guardiano duplicato: %s" % guardian_name)
		assert(not paths.has(path), "asset guardiano duplicato: %s" % path)
		names[guardian_name] = true
		paths[path] = true
		assert(GUARDIANS.family_for(level) in ["fantasy", "fantascienza"],
			"mondo %d senza famiglia fantasy/fantascienza" % level)
		_assert_alpha_texture(GUARDIANS.texture_for(level), "Guardiano L%d" % level)
		var enemy := ENEMY.new() as WorldEnemy
		root.add_child(enemy)
		enemy.setup(null, Vector2.ZERO, level, "logica", Color("ff6b7a"), 0)
		var sprite := enemy.find_child("GuardianGeneratedArt", true, false) as Sprite2D
		assert(sprite != null and sprite.texture.resource_path == path,
			"mondo %d non monta il proprio guardiano" % level)
		assert(sprite.get_index() == sprite.get_parent().get_child_count() - 1,
			"mondo %d: il fallback copre l'illustrazione" % level)
		enemy.free()

	print("GENERATED CHARACTER ART audit OK - 11 Custodi e 24 Guardiani unici")
	quit(0)
