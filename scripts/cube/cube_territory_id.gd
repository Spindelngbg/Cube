class_name CubeTerritoryId
extends RefCounted

const LAYER_PATTERN := "L%02d"
const BLOCK_PATTERN := "L%02d-B%02d%02d"


static func layer_id(layer: int) -> String:
	return LAYER_PATTERN % layer


static func block_id(layer: int, block: Vector2i) -> String:
	return BLOCK_PATTERN % [layer, block.x, block.y]


static func territory_type(territory_id: String) -> String:
	if territory_id.contains("-Z"):
		return "zone"
	if territory_id.contains("-B"):
		return "block"
	if territory_id.begins_with("L") and territory_id.length() == 3:
		return "layer"
	return "unknown"


static func parse_layer(layer_territory_id: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("^L(\\d{2})$")
	var result := regex.search(layer_territory_id)
	if result == null:
		return {}
	return {
		"territory_id": layer_territory_id,
		"territory_type": "layer",
		"layer": int(result.get_string(1)),
	}


static func parse_block(block_territory_id: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("^L(\\d{2})-B(\\d{2})(\\d{2})$")
	var result := regex.search(block_territory_id)
	if result == null:
		return {}
	return {
		"territory_id": block_territory_id,
		"territory_type": "block",
		"layer": int(result.get_string(1)),
		"block": Vector2i(int(result.get_string(2)), int(result.get_string(3))),
	}


static func zone_to_block_id(zone_id: String) -> String:
	var parsed: Dictionary = CubeZoneId.parse(zone_id)
	if parsed.is_empty():
		return ""
	return block_id(int(parsed.get("layer", 0)), parsed.get("block", Vector2i.ZERO))


static func zone_to_layer_id(zone_id: String) -> String:
	var parsed: Dictionary = CubeZoneId.parse(zone_id)
	if parsed.is_empty():
		return ""
	return layer_id(int(parsed.get("layer", 0)))