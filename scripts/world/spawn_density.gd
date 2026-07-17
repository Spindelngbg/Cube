class_name SpawnDensity
extends RefCounted

const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")

## Glesbygd nära spawn, tätare stad längre bort.

const DC_SPAWN_CELL := Vector2i(0, 0)


static func grid_distance(cell: Vector2i, spawn_cell: Vector2i = DC_SPAWN_CELL) -> float:
	return Vector2(cell - spawn_cell).length()


static func building_chance(cell: Vector2i, spawn_cell: Vector2i = DC_SPAWN_CELL) -> float:
	var dist := grid_distance(cell, spawn_cell)
	## Helt tomt närmast spawn, sedan glesare utåt.
	if dist < 2.0:
		return 0.0
	if dist < 3.0:
		return 0.12
	if dist < 4.5:
		return 0.32
	if dist < 6.0:
		return 0.55
	if dist < 8.0:
		return 0.75
	return 0.92


static func should_place_building(cell: Vector2i, spawn_cell: Vector2i = DC_SPAWN_CELL) -> bool:
	if grid_distance(cell, spawn_cell) >= GlesPerformanceScript.max_building_grid_dist():
		return false
	var chance := building_chance(cell, spawn_cell)
	if chance <= 0.0:
		return false
	# Lättare stad = färre byggnader (FPS).
	chance *= 0.65 if GlesPerformanceScript.is_active() else 0.78
	var roll := _hash_roll(cell, spawn_cell, 41)
	return roll < chance


## 0 = ingen vegetation, 1 = full täthet. Glesare nära Kapitol/spawn.
static func greenery_scale(cell: Vector2i, spawn_cell: Vector2i = DC_SPAWN_CELL) -> float:
	if GlesPerformanceScript.skip_greenery():
		return 0.0
	var dist := grid_distance(cell, spawn_cell)
	if dist < 1.5:
		return 0.0
	if dist < 2.5:
		return 0.08
	if dist < 4.0:
		return 0.22
	if dist < 6.0:
		return 0.4
	return 0.55


static func should_scatter_cell_accent(cell: Vector2i, spawn_cell: Vector2i = DC_SPAWN_CELL) -> bool:
	return grid_distance(cell, spawn_cell) >= 3.5


static func hub_building_chance(local_offset: Vector3, spawn_pos: Vector3, index: int) -> float:
	var dist := Vector2(local_offset.x, local_offset.z).length()
	if dist < 45.0:
		return 0.22
	if dist < 75.0:
		return 0.48
	if dist < 105.0:
		return 0.72
	return 0.9 if index % 2 == 0 else 1.0


static func should_place_hub_building(
	local_offset: Vector3,
	spawn_pos: Vector3,
	index: int
) -> bool:
	return _hash_roll_vec(local_offset, index, 73) < hub_building_chance(local_offset, spawn_pos, index)


static func world_spawn_chance(
	world_pos: Vector3,
	spawn_pos: Vector3,
	seed_salt: int,
	max_radius: float = 280.0
) -> float:
	var dist := Vector2(world_pos.x - spawn_pos.x, world_pos.z - spawn_pos.z).length()
	var t := clampf(dist / max_radius, 0.0, 1.0)
	return lerpf(0.08, 0.82, t * t)


static func should_spawn_entity(
	world_pos: Vector3,
	spawn_pos: Vector3,
	seed_salt: int,
	max_radius: float = 280.0
) -> bool:
	var chance := world_spawn_chance(world_pos, spawn_pos, seed_salt, max_radius)
	var roll := _hash_roll_vec(world_pos, seed_salt, 97)
	return roll < chance


static func _hash_roll(cell: Vector2i, spawn_cell: Vector2i, salt: int) -> float:
	var h := hash(Vector3i(cell.x, cell.y, salt) + Vector3i(spawn_cell.x, spawn_cell.y, 0))
	return float(abs(h) % 10000) / 10000.0


static func _hash_roll_vec(pos: Vector3, salt: int, multiplier: int) -> float:
	var h := hash(
		Vector3i(
			int(pos.x * 10.0) + salt * multiplier,
			int(pos.z * 10.0),
			salt
		)
	)
	return float(abs(h) % 10000) / 10000.0