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