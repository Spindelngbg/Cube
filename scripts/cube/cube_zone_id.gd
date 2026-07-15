class_name CubeZoneId
extends RefCounted


static func make(layer: int, block: Vector2i, zone: Vector2i) -> String:
	return CubeConstants.ZONE_ID_PATTERN % [layer, block.x, block.y, zone.x, zone.y]


static func parse(zone_id: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("^L(\\d{2})-B(\\d{2})(\\d{2})-Z(\\d)(\\d)$")
	var result := regex.search(zone_id)
	if result == null:
		return {}
	return {
		"zone_id": zone_id,
		"layer": int(result.get_string(1)),
		"block": Vector2i(int(result.get_string(2)), int(result.get_string(3))),
		"zone": Vector2i(int(result.get_string(4)), int(result.get_string(5))),
	}


static func logical_origin_m(layer: int, block: Vector2i, zone: Vector2i) -> Vector3:
	return Vector3(
		block.x * CubeConstants.BLOCK_SIZE_M + zone.x * CubeConstants.ZONE_SIZE_M,
		(layer - 1) * CubeConstants.LAYER_HEIGHT_M,
		block.y * CubeConstants.BLOCK_SIZE_M + zone.y * CubeConstants.ZONE_SIZE_M
	)


static func prototype_origin_m(block: Vector2i, zone: Vector2i) -> Vector3:
	var local_block := block - CubeConstants.PROTOTYPE_BLOCK_ORIGIN
	return Vector3(
		local_block.x * CubeConstants.PROTOTYPE_METERS_PER_BLOCK + zone.x * CubeConstants.PROTOTYPE_METERS_PER_ZONE,
		0.0,
		local_block.y * CubeConstants.PROTOTYPE_METERS_PER_BLOCK + zone.y * CubeConstants.PROTOTYPE_METERS_PER_ZONE
	)


static func prototype_position_to_zone(world_pos: Vector3) -> String:
	var local_block_x := clampi(
		int(floor(world_pos.x / CubeConstants.PROTOTYPE_METERS_PER_BLOCK)),
		0,
		CubeConstants.PROTOTYPE_BLOCK_COUNT - 1
	)
	var local_block_z := clampi(
		int(floor(world_pos.z / CubeConstants.PROTOTYPE_METERS_PER_BLOCK)),
		0,
		CubeConstants.PROTOTYPE_BLOCK_COUNT - 1
	)
	var block := CubeConstants.PROTOTYPE_BLOCK_ORIGIN + Vector2i(local_block_x, local_block_z)

	var in_block_x := fposmod(world_pos.x, CubeConstants.PROTOTYPE_METERS_PER_BLOCK)
	var in_block_z := fposmod(world_pos.z, CubeConstants.PROTOTYPE_METERS_PER_BLOCK)
	var zone := Vector2i(
		clampi(int(floor(in_block_x / CubeConstants.PROTOTYPE_METERS_PER_ZONE)), 0, CubeConstants.PROTOTYPE_ZONES_PER_BLOCK - 1),
		clampi(int(floor(in_block_z / CubeConstants.PROTOTYPE_METERS_PER_ZONE)), 0, CubeConstants.PROTOTYPE_ZONES_PER_BLOCK - 1)
	)
	return make(CubeConstants.PROTOTYPE_LAYER, block, zone)


static func prototype_spawn_position() -> Vector3:
	var center_block := CubeConstants.PROTOTYPE_BLOCK_ORIGIN + Vector2i(
		CubeConstants.PROTOTYPE_BLOCK_COUNT / 2,
		CubeConstants.PROTOTYPE_BLOCK_COUNT / 2
	)
	var origin := prototype_origin_m(center_block, Vector2i(2, 2))
	return origin + Vector3(
		CubeConstants.PROTOTYPE_METERS_PER_ZONE * 0.5,
		0.5,
		CubeConstants.PROTOTYPE_METERS_PER_ZONE * 0.5
	)