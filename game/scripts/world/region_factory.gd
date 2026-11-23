class_name RegionFactory
extends RefCounted
## Keeps region construction out of the director. Important story regions are
## handcrafted; optional caves are generated with a stable per-save seed.

static func create(id: String) -> RegionBase:
	match id:
		"reedwater":
			return ReedwaterRegion.new()
		"sunken_choir":
			return SunkenChoirRegion.new()
		"undercave":
			return UndercaveRegion.new()
		_:
			return BellhollowRegion.new()
