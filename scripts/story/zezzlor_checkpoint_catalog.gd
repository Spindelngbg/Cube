class_name ZezzlorCheckpointCatalog
extends RefCounted

## Zezzlor-kontrollpunkter runt spawn i Koloni 4.
## Ju närmare spawn (0,0,0) desto fler grindar.

const SPAWN := Vector3.ZERO


static func get_placements() -> Array:
	return [
		# Ring 1 — tätast, 10–22 m från spawn
		_gate("zezzlor_cp_spawn_w", Vector3(-10.0, 0.0, 0.0), -PI * 0.5, Vector3(10.0, 3.2, 0.35)),
		_gate("zezzlor_cp_spawn_n", Vector3(0.0, 0.0, -18.0), 0.0, Vector3(8.0, 3.2, 0.35)),
		_gate("zezzlor_cp_spawn_s", Vector3(0.0, 0.0, 22.0), PI, Vector3(8.0, 3.2, 0.35)),
		_gate("zezzlor_cp_spawn_sw", Vector3(-18.0, 0.0, 14.0), -PI * 0.5, Vector3(8.0, 3.2, 0.35)),
		_gate("zezzlor_cp_spawn_ne", Vector3(14.0, 0.0, -10.0), 0.0, Vector3(6.0, 3.2, 0.35)),
		# Ring 2 — runt Kapitolplazan, ~35–50 m
		_gate("zezzlor_cp_kapitol_w", Vector3(-5.0, 0.0, 20.0), -PI * 0.5, Vector3(12.0, 3.2, 0.35)),
		_gate("zezzlor_cp_kapitol_n", Vector3(20.0, 0.0, -5.0), 0.0, Vector3(10.0, 3.2, 0.35)),
		_gate("zezzlor_cp_kapitol_s", Vector3(20.0, 0.0, 45.0), PI, Vector3(10.0, 3.2, 0.35)),
		# Ring 3 — ytterligare ut, ~60–80 m
		_gate("zezzlor_cp_mall", Vector3(-55.0, 0.0, 20.0), -PI * 0.5, Vector3(14.0, 3.2, 0.35)),
		_gate("zezzlor_cp_transit", Vector3(65.0, 0.0, 20.0), PI * 0.5, Vector3(12.0, 3.2, 0.35)),
		# Ring 4 — enstaka långt ut
		_gate("zezzlor_cp_federal", Vector3(-100.0, 0.0, -60.0), 0.0, Vector3(10.0, 3.2, 0.35)),
	]


static func count_near_spawn(radius_m: float) -> int:
	var count := 0
	for entry in get_placements():
		if SPAWN.distance_to(entry.get("pos", Vector3.ZERO)) <= radius_m:
			count += 1
	return count


static func _gate(id: String, pos: Vector3, rotation_y: float, size: Vector3) -> Dictionary:
	return {
		"id": id,
		"pos": pos,
		"rotation_y": rotation_y,
		"size": size,
		"distance": SPAWN.distance_to(pos),
	}