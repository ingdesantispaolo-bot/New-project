class_name IdentityPropArt
extends RefCounted

const ATLASES := {
	"archive": preload("res://assets/identity-archive-atlas-v1.png"), "signal": preload("res://assets/identity-signal-atlas-v1.png"),
	"motion": preload("res://assets/identity-motion-atlas-v1.png"), "resonance": preload("res://assets/identity-resonance-atlas-v1.png"),
	"glyph": preload("res://assets/identity-glyph-atlas-v1.png"), "circuit": preload("res://assets/identity-circuit-atlas-v1.png"),
	"symbiosis": preload("res://assets/identity-symbiosis-atlas-v1.png"), "final": preload("res://assets/identity-final-atlas-v1.png"),
}
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
		var atlas := AtlasTexture.new()
		atlas.atlas = ATLASES[family]
		atlas.region = Rect2(float(slot % 4) * 256.0, float(slot / 4) * 256.0, 256.0, 256.0)
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
