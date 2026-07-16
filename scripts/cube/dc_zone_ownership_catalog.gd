class_name DcZoneOwnershipCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const PRICING_PATH := "res://data/cube/zone_pricing.json"

## DC-rutnätets minsta cell i Koloni 4 (Neo-Washington).
const DC_GRID_ORIGIN := Vector2i(-7, -4)

static var _pricing: Dictionary = {}


static func load_pricing() -> Dictionary:
	if not _pricing.is_empty():
		return _pricing
	if FileAccess.file_exists(PRICING_PATH):
		var file := FileAccess.open(PRICING_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			_pricing = parsed
			return _pricing
	_pricing = {
		"default_price": 3500,
		"non_purchasable_zones": ["KAPITOLPLAZA", "SRC_LAB"],
		"prices_by_zone_type": {},
	}
	return _pricing


static func koloni4_local_to_zone_id(local: Vector3) -> String:
	var cell := Vector2i(
		int(floor(local.x / DcZoneCatalogScript.BLOCK_M)),
		int(floor(local.z / DcZoneCatalogScript.BLOCK_M))
	)
	var block := CubeConstants.PROTOTYPE_BLOCK_ORIGIN + (cell - DC_GRID_ORIGIN)
	var subzone := Vector2i(
		clampi(int(floor(fposmod(local.x, DcZoneCatalogScript.BLOCK_M) / CubeConstants.PROTOTYPE_METERS_PER_ZONE)), 0, 3),
		clampi(int(floor(fposmod(local.z, DcZoneCatalogScript.BLOCK_M) / CubeConstants.PROTOTYPE_METERS_PER_ZONE)), 0, 3)
	)
	return CubeZoneId.make(CubeConstants.PROTOTYPE_LAYER, block, subzone)


static func world_to_zone_id(world_pos: Vector3, spawn_id: String) -> String:
	var spawn_pos := SpawnPoints.get_position(spawn_id)
	var local := world_pos - spawn_pos
	local.y = 0.0
	if SpawnPoints.normalize_id(spawn_id) == "satellite_right":
		return koloni4_local_to_zone_id(local)
	return CubeZoneId.prototype_position_to_zone(local)


static func zone_id_to_dc_cell(zone_id: String) -> Vector2i:
	var parsed := CubeZoneId.parse(zone_id)
	if parsed.is_empty():
		return Vector2i.ZERO
	var block: Vector2i = parsed.get("block", Vector2i.ZERO)
	return block - CubeConstants.PROTOTYPE_BLOCK_ORIGIN + DC_GRID_ORIGIN


static func get_dc_zone_spec(zone_id: String) -> Dictionary:
	return DcZoneCatalogScript.classify_cell(zone_id_to_dc_cell(zone_id))


static func get_zone_display_name(zone_id: String, entry: Dictionary = {}) -> String:
	if not entry.is_empty() and str(entry.get("name", "")) != "":
		return str(entry.get("name", ""))
	var spec := get_dc_zone_spec(zone_id)
	if not spec.is_empty():
		return str(spec.get("name", zone_id))
	return zone_id


static func get_purchase_price(zone_id: String) -> int:
	var pricing := load_pricing()
	var spec := get_dc_zone_spec(zone_id)
	var zone_type := str(spec.get("zone_type", ""))
	if zone_type in pricing.get("non_purchasable_zones", []):
		return -1
	var prices: Dictionary = pricing.get("prices_by_zone_type", {})
	return int(prices.get(zone_type, pricing.get("default_price", 3500)))


static func is_purchasable(zone_id: String, entry: Dictionary = {}) -> bool:
	if zone_id == "":
		return false
	var ownership := str(entry.get("ownership", "public"))
	if ownership in ["foundation", "reserved"]:
		return false
	if ownership == "owned":
		return false
	var pricing := load_pricing()
	var spec := get_dc_zone_spec(zone_id)
	var zone_type := str(spec.get("zone_type", ""))
	if zone_type in pricing.get("non_purchasable_zones", []):
		return false
	if bool(entry.get("governance_locked", false)):
		return false
	return get_purchase_price(zone_id) > 0


static func make_zone_entry(zone_id: String) -> Dictionary:
	var parsed := CubeZoneId.parse(zone_id)
	if parsed.is_empty():
		return {}
	var block: Vector2i = parsed.get("block", Vector2i.ZERO)
	var zone: Vector2i = parsed.get("zone", Vector2i.ZERO)
	var block_id := CubeTerritoryId.block_id(CubeConstants.PROTOTYPE_LAYER, block)
	var spec := get_dc_zone_spec(zone_id)
	return {
		"zone_id": zone_id,
		"layer": CubeConstants.PROTOTYPE_LAYER,
		"block": [block.x, block.y],
		"zone": [zone.x, zone.y],
		"district": "L10-CORE",
		"name": get_zone_display_name(zone_id),
		"zone_type": str(spec.get("zone_type", "")),
		"ownership": "public",
		"nft_ready": true,
		"open_build": false,
		"governed_by_block": block_id,
		"governed_by_layer": CubeTerritoryId.layer_id(CubeConstants.PROTOTYPE_LAYER),
		"governance_locked": false,
		"structures": [],
	}