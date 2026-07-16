class_name SrcHqCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")

## SRC HQ — supermodern vit sandbyggnad vid cell (-4, -3) i Neo-Washington.
const HQ_CELL := Vector2i(-4, -3)
const HQ_RADIUS_M := 1000.0


static func get_hq_local_position() -> Vector3:
	return Vector3(
		float(HQ_CELL.x) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5,
		0.0,
		float(HQ_CELL.y) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5
	)


static func get_hq_world_position(spawn_id: String = "satellite_right") -> Vector3:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id != "satellite_right":
		return Vector3.ZERO
	return SpawnPoints.get_position(id) + get_hq_local_position()


static func is_in_hq_zone(world_pos: Vector3, spawn_id: String = "satellite_right") -> bool:
	return flat_distance(world_pos, get_hq_world_position(spawn_id)) <= HQ_RADIUS_M


static func flat_distance(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()