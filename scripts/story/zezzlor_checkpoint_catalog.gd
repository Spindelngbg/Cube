class_name ZezzlorCheckpointCatalog
extends RefCounted

## Zezzlor-kontrollpunkter runt spawn i Koloni 4.
## Ju närmare spawn (0,0,0) desto fler grindar.
## Grindarna ligger tvärs över vägstråk (40 m-rutnät) så man måste stämpla Znood.

const SPAWN := Vector3.ZERO

const GATE_STANDARD := Vector3(18.0, 4.8, 1.2)
const GATE_TIGHT := Vector3(16.0, 4.8, 1.2)
const GATE_WIDE := Vector3(22.0, 5.0, 1.4)


static func get_placements() -> Array:
	return [
		# Ring 1 — tätast runt spawn, ~20 m ut på vägarna
		_gate("zezzlor_cp_spawn_w", Vector3(-20.0, 0.0, 0.0), PI * 0.5, GATE_STANDARD),
		_gate("zezzlor_cp_spawn_e", Vector3(20.0, 0.0, 0.0), -PI * 0.5, GATE_STANDARD),
		_gate("zezzlor_cp_spawn_n", Vector3(0.0, 0.0, -20.0), 0.0, GATE_TIGHT),
		_gate("zezzlor_cp_spawn_s", Vector3(0.0, 0.0, 20.0), PI, GATE_TIGHT),
		_gate("zezzlor_cp_spawn_nw", Vector3(-20.0, 0.0, -20.0), 0.0, GATE_TIGHT),
		# Ring 2 — runt Kapitolplazan, ~40 m
		_gate("zezzlor_cp_kapitol_w", Vector3(-40.0, 0.0, 20.0), PI * 0.5, GATE_WIDE),
		_gate("zezzlor_cp_kapitol_n", Vector3(20.0, 0.0, -40.0), 0.0, GATE_STANDARD),
		_gate("zezzlor_cp_kapitol_s", Vector3(20.0, 0.0, 40.0), PI, GATE_STANDARD),
		# Ring 3 — ytterligare ut längs Mallen och transit
		_gate("zezzlor_cp_mall", Vector3(-60.0, 0.0, 0.0), PI * 0.5, GATE_WIDE),
		_gate("zezzlor_cp_transit", Vector3(60.0, 0.0, 0.0), -PI * 0.5, GATE_WIDE),
		# Ring 4 — enstaka långt ut
		_gate("zezzlor_cp_federal", Vector3(-80.0, 0.0, -40.0), 0.0, GATE_WIDE),
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