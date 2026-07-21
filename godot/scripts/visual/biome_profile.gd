class_name BiomeProfile
extends RefCounted

const PROFILES := {
	"academy": {"label": "Radura Accademia", "ground": Color("78945a"), "dark": Color("3f6847"), "accent": Color("f2c66d"), "density": 0.92},
	"wild": {"label": "Bosco variabile", "ground": Color("426f4a"), "dark": Color("234936"), "accent": Color("7fe0a7"), "density": 1.18},
	"geo": {"label": "Dorsale geografica", "ground": Color("548675"), "dark": Color("315d58"), "accent": Color("79d8d0"), "density": 0.86},
	"logic": {"label": "Cratere logico", "ground": Color("56658d"), "dark": Color("343f68"), "accent": Color("b4a7ff"), "density": 0.76},
	"ruins": {"label": "Rovine del Relitto", "ground": Color("755f68"), "dark": Color("493943"), "accent": Color("f0a080"), "density": 0.68},
	"crystal": {"label": "Nido cristallino", "ground": Color("686da0"), "dark": Color("414978"), "accent": Color("d6c8ff"), "density": 0.58},
}

static func get_profile(id: String) -> Dictionary:
	return PROFILES.get(id, PROFILES["academy"])

static func ids() -> Array:
	return PROFILES.keys()
