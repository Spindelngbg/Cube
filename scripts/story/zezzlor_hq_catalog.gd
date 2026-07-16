class_name ZezzlorHqCatalog
extends RefCounted

## Zezzlor HQ — utposter i Neo-Washington där man kan läsa sin dossier.

const SPAWN := Vector3(20.0, 0.0, 20.0)


static func get_placements() -> Array:
	return [
		_hq("zezzlor_hq_kapitol", Vector3(28.0, 0.0, 8.0), 0.0, "Kapitol HQ"),
		_hq("zezzlor_hq_mall", Vector3(-36.0, 0.0, 24.0), PI * 0.5, "Mall HQ"),
		_hq("zezzlor_hq_transit", Vector3(72.0, 0.0, 28.0), -PI * 0.5, "Transit HQ"),
		_hq("zezzlor_hq_federal", Vector3(-52.0, 0.0, -12.0), PI * 0.15, "Federal HQ"),
		_hq("zezzlor_hq_market", Vector3(48.0, 0.0, 56.0), PI, "Marknads HQ"),
	]


static func _hq(id: String, pos: Vector3, rotation_y: float, label: String) -> Dictionary:
	return {
		"id": id,
		"pos": pos,
		"rotation_y": rotation_y,
		"label": label,
		"distance": SPAWN.distance_to(pos),
	}