class_name IdentityPropArt
extends RefCounted

## Un mondo usa una sola famiglia alla volta: queste tavole non devono entrare
## tutte nel primo caricamento, né restare fissate in memoria fra due mondi.
const ATLAS_PATHS := {
	"archive": "res://assets/identity-archive-atlas-v1.png", "signal": "res://assets/identity-signal-atlas-v1.png",
	"motion": "res://assets/identity-motion-atlas-v1.png", "resonance": "res://assets/identity-resonance-atlas-v1.png",
	"glyph": "res://assets/identity-glyph-atlas-v1.png", "circuit": "res://assets/identity-circuit-atlas-v1.png",
	"symbiosis": "res://assets/identity-symbiosis-atlas-v1.png", "final": "res://assets/identity-final-atlas-v1.png",
}
## Solo quattro famiglie non riempiono una griglia 4×3. Compattarle evita 25
## celle trasparenti che il tablet teneva comunque in memoria.
const ATLAS_GRIDS := {
	"archive": Vector2i(5, 2), "signal": Vector2i(4, 3), "motion": Vector2i(4, 3),
	"resonance": Vector2i(4, 3), "glyph": Vector2i(4, 3), "circuit": Vector2i(4, 2),
	"symbiosis": Vector2i(2, 1), "final": Vector2i(3, 1),
}
static var _atlas_cache: Dictionary = {}
const FAMILIES := {
	"archive": ["archive_shelf","archive_pillar","archive_scriptorium","number_stone","artifact_table","voice_shelf","echo_lectern","memory_lantern","roman_archive_pod","medieval_archive_pod"],
	"signal": ["signal_buoy","radio_mast","signal_console","route_beacon","contour_plinth","dock_crane","passage_beacon","market_stall","connector_arch","pressure_buoy","current_vane","ballast_station"],
	"motion": ["sequence_pylon","loop_engine","gear_cluster","motion_piston","rail_switch","force_cart","trajectory_pylon","fraction_dial","orbit_scope","moving_wall","rule_node","logic_gate"],
	"resonance": ["resonance_crystal","tuning_pod","echo_bloom","organ_pipe","harmony_arch","timbre_resonator","aqueduct_pillar","glyph_stele","mosaic_brazier","source_stele","timeline_relay","root_obelisk"],
	"glyph": ["lineage_tablet","crypt_lantern","field_tower","sensor_probe","surge_grounder","climate_beacon","fault_marker","terrain_model","cell_pod","energy_vein","adaptation_spore","root_arch"],
	"circuit": ["coil_tower","circuit_node","conductor_bridge","data_relay","automaton_station","debug_console","system_pylon","convergence_relay"],
	"symbiosis": ["symbiosis_pod","pollinator_lamp"],
	"final": ["synthesis_anchor","causality_terminal","era_beacon"],
}

static func build(kind: String, variant: float = 0.5) -> Node2D:
	for family in FAMILIES:
		var slot := (FAMILIES[family] as Array).find(kind)
		if slot < 0: continue
		var grid: Vector2i = ATLAS_GRIDS.get(family, Vector2i(4, 3))
		var atlas := AtlasTexture.new()
		atlas.atlas = _atlas_for(str(family))
		atlas.region = Rect2(float(slot % grid.x) * 256.0, float(slot / grid.x) * 256.0, 256.0, 256.0)
		var root := Node2D.new()
		root.name = "IdentityPropArt_%s" % kind
		root.set_meta("identity_art_family", family)
		var sprite := Sprite2D.new()
		sprite.name = "IdentityPropSprite"
		sprite.texture = atlas
		sprite.position = Vector2(0, -54)
		sprite.scale = Vector2.ONE * (0.48 + variant * 0.05)
		root.add_child(sprite)
		return root
	return null


static func release_texture_cache() -> void:
	_atlas_cache.clear()


static func _atlas_for(family: String) -> Texture2D:
	if not _atlas_cache.has(family):
		_atlas_cache[family] = load(str(ATLAS_PATHS.get(family, "")))
	return _atlas_cache.get(family) as Texture2D
