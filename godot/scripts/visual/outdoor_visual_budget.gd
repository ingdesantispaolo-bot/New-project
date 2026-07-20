class_name OutdoorVisualBudget
extends RefCounted

## Budget render-only per chunk periferici. Il chiamante decide il tier in base
## a distanza/viewport; non altera il seed né la lista degli oggetti logici.

enum Tier { HERO, NEAR, FAR, MINIMAL }

static func tier_for_distance(distance: float) -> Tier:
	if distance < 520.0:
		return Tier.HERO
	if distance < 1100.0:
		return Tier.NEAR
	if distance < 1900.0:
		return Tier.FAR
	return Tier.MINIMAL

static func max_particles(tier: Tier) -> int:
	return [42, 24, 10, 0][int(tier)]

static func allow_detail(tier: Tier) -> bool:
	return tier == Tier.HERO or tier == Tier.NEAR

static func scale_for_tier(tier: Tier) -> float:
	return [1.0, 0.82, 0.58, 0.34][int(tier)]
