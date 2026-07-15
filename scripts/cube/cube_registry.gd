extends Node

signal zone_registered(zone_id: String)
signal build_log_updated()

const GRID_PATH := "res://data/cube/grid_definition.json"
const SEED_PATH := "res://data/cube/seed_district_l10.json"
const EXPORT_PATH := "user://cube_build_registry.json"

var grid_definition: Dictionary = {}
var zones: Dictionary = {}
var build_log: Array[Dictionary] = []
var prototype_bounds: Dictionary = {}


func _ready() -> void:
	_load_grid_definition()
	_load_seed_district()
	CubeGovernance.governance_loaded.connect(_on_governance_loaded)
	if CubeGovernance.layers.size() > 0:
		_on_governance_loaded()


func _on_governance_loaded() -> void:
	for zone_id in zones.keys():
		_attach_governance_to_zone(zone_id)


func _load_grid_definition() -> void:
	if not FileAccess.file_exists(GRID_PATH):
		push_warning("Cube grid definition missing: %s" % GRID_PATH)
		return
	var file := FileAccess.open(GRID_PATH, FileAccess.READ)
	grid_definition = JSON.parse_string(file.get_as_text())
	file.close()


func _load_seed_district() -> void:
	if not FileAccess.file_exists(SEED_PATH):
		push_warning("Cube seed district missing: %s" % SEED_PATH)
		return
	var file := FileAccess.open(SEED_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return

	prototype_bounds = data.get("prototype_bounds", {})
	for entry in data.get("zones", []):
		_register_zone(entry)


func register_prototype_zone(entry: Dictionary) -> void:
	_register_zone(entry)


func _register_zone(entry: Dictionary) -> void:
	var zone_id := str(entry.get("zone_id", ""))
	if zone_id == "":
		return
	_attach_governance_to_zone_entry(entry)
	zones[zone_id] = entry
	zone_registered.emit(zone_id)


func _attach_governance_to_zone(zone_id: String) -> void:
	if not zones.has(zone_id):
		return
	var entry: Dictionary = zones[zone_id]
	_attach_governance_to_zone_entry(entry)
	zones[zone_id] = entry


func _attach_governance_to_zone_entry(entry: Dictionary) -> void:
	var zone_id := str(entry.get("zone_id", ""))
	if zone_id == "":
		return
	entry["block_id"] = CubeTerritoryId.zone_to_block_id(zone_id)
	entry["layer_id"] = CubeTerritoryId.zone_to_layer_id(zone_id)
	if CubeGovernance.layers.size() > 0:
		entry["governance_chain"] = CubeGovernance.resolve_governance_chain(zone_id)


func register_build_event(
	zone_id: String,
	structure_type: String,
	model: String,
	world_position: Vector3,
	rotation_y: float = 0.0,
	source: String = "cube_city_builder"
) -> void:
	var event := {
		"timestamp": Time.get_datetime_string_from_system(),
		"zone_id": zone_id,
		"block_id": CubeTerritoryId.zone_to_block_id(zone_id),
		"layer_id": CubeTerritoryId.zone_to_layer_id(zone_id),
		"structure_type": structure_type,
		"model": model,
		"world_position": [world_position.x, world_position.y, world_position.z],
		"rotation_y": rotation_y,
		"source": source,
	}
	build_log.append(event)
	build_log_updated.emit()


func get_zone(zone_id: String) -> Dictionary:
	return zones.get(zone_id, {})


func get_layer_record(layer_id: String) -> Dictionary:
	return CubeGovernance.get_layer(layer_id)


func get_block_record(block_id: String) -> Dictionary:
	return CubeGovernance.get_block(block_id)


func get_zone_governance(zone_id: String) -> Dictionary:
	return CubeGovernance.resolve_governance_chain(zone_id)


func can_player_build_in_zone(zone_id: String) -> bool:
	var zone := get_zone(zone_id)
	if zone.is_empty():
		return false

	if bool(zone.get("governance_locked", false)):
		return false

	var ownership := str(zone.get("ownership", "public"))
	if ownership == "foundation":
		return false
	if ownership == "reserved":
		return false
	if ownership == "owned":
		var owner := str(zone.get("owner_account", ""))
		return Auth.is_logged_in and Auth.username == owner

	if bool(zone.get("open_build", false)):
		return true

	var block_id := CubeTerritoryId.zone_to_block_id(zone_id)
	return CubeGovernance.can_current_player_exercise_power(block_id, CubeGovernance.POWER_ISSUE_BUILD_PERMIT)


func build_permit_status(zone_id: String) -> String:
	if can_player_build_in_zone(zone_id):
		return "Bygglov: beviljat"
	var zone := get_zone(zone_id)
	if zone.is_empty():
		return "Bygglov: okänd zon"
	if bool(zone.get("governance_locked", false)):
		return "Bygglov: block låst politiskt"
	match str(zone.get("ownership", "")):
		"foundation":
			return "Bygglov: foundationszon"
		"reserved":
			return "Bygglov: reserverad för NFT"
		"owned":
			return "Bygglov: privat ägd zon"
		_:
			return "Bygglov: kräver guvernörs tillstånd"


func get_zones_in_layer(layer: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for zone_id in zones.keys():
		var zone: Dictionary = zones[zone_id]
		if int(zone.get("layer", -1)) == layer:
			result.append(zone)
	return result


func get_zones_in_block(layer: int, block: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for zone_id in zones.keys():
		var zone: Dictionary = zones[zone_id]
		var zone_block: Array = zone.get("block", [])
		if int(zone.get("layer", -1)) == layer and zone_block.size() >= 2:
			if int(zone_block[0]) == block.x and int(zone_block[1]) == block.y:
				result.append(zone)
	return result


func ownership_status_name(status: String) -> String:
	match status:
		"foundation":
			return "FOUNDATION"
		"public":
			return "PUBLIC"
		"reserved":
			return "RESERVED"
		"owned":
			return "OWNED"
		_:
			return "UNKNOWN"


func export_registry() -> bool:
	var payload := {
		"exported_at": Time.get_datetime_string_from_system(),
		"grid": grid_definition,
		"prototype_bounds": prototype_bounds,
		"zone_count": zones.size(),
		"zones": zones,
		"layers": CubeGovernance.layers,
		"blocks": CubeGovernance.blocks,
		"verifications": CubeGovernance.verifications,
		"build_log": build_log,
	}
	var file := FileAccess.open(EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func full_summary() -> String:
	return "%s %s" % [zone_summary(), CubeGovernance.governance_summary()]


func zone_summary() -> String:
	return "Kuben: %d lager, %d×%d block/lager, %d×%d zoner/block. Spårade zoner: %d." % [
		CubeConstants.LAYER_COUNT,
		CubeConstants.BLOCKS_PER_AXIS,
		CubeConstants.BLOCKS_PER_AXIS,
		CubeConstants.ZONES_PER_BLOCK_AXIS,
		CubeConstants.ZONES_PER_BLOCK_AXIS,
		zones.size(),
	]