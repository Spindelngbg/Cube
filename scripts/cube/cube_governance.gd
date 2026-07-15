extends Node

signal governance_loaded()
signal verification_checked(account: String, territory_id: String, power: String, allowed: bool)

const GOVERNANCE_PATH := "res://data/cube/governance_seed.json"
const EXPORT_PATH := "user://cube_governance_state.json"

const POWER_APPOINT_BLOCK_GOVERNOR := "appoint_block_governor"
const POWER_SET_BUILDING_CODES := "set_building_codes"
const POWER_ISSUE_BUILD_PERMIT := "issue_build_permit"
const POWER_SET_ZONE_ZONING := "set_zone_zoning"
const POWER_COLLECT_TAX := "collect_tax"
const POWER_DECLARE_ORDINANCE := "declare_ordinance"
const POWER_DELEGATE_BLOCK := "delegate_block"

const LAYER_POWERS := [
	POWER_APPOINT_BLOCK_GOVERNOR,
	POWER_SET_BUILDING_CODES,
	POWER_SET_ZONE_ZONING,
	POWER_COLLECT_TAX,
	POWER_DECLARE_ORDINANCE,
	POWER_DELEGATE_BLOCK,
]

const BLOCK_POWERS := [
	POWER_SET_BUILDING_CODES,
	POWER_ISSUE_BUILD_PERMIT,
	POWER_SET_ZONE_ZONING,
	POWER_COLLECT_TAX,
	POWER_DECLARE_ORDINANCE,
]

var layers: Dictionary = {}
var blocks: Dictionary = {}
var verifications: Dictionary = {}
var hierarchy_rules: Dictionary = {}


func _ready() -> void:
	_load_governance_seed()


func _load_governance_seed() -> void:
	if not FileAccess.file_exists(GOVERNANCE_PATH):
		push_warning("Cube governance seed missing: %s" % GOVERNANCE_PATH)
		return

	var file := FileAccess.open(GOVERNANCE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return

	hierarchy_rules = data.get("hierarchy_rules", {})
	for entry in data.get("layers", []):
		_register_layer(entry)
	for entry in data.get("blocks", []):
		_register_block(entry)
	for entry in data.get("verifications", []):
		_register_verification(entry)

	governance_loaded.emit()


func _register_layer(entry: Dictionary) -> void:
	var layer_id := str(entry.get("layer_id", ""))
	if layer_id == "":
		return
	layers[layer_id] = entry


func _register_block(entry: Dictionary) -> void:
	var block_id := str(entry.get("block_id", ""))
	if block_id == "":
		return
	blocks[block_id] = entry


func _register_verification(entry: Dictionary) -> void:
	var verification_id := str(entry.get("verification_id", ""))
	if verification_id == "":
		return
	verifications[verification_id] = entry


func get_layer(layer_id: String) -> Dictionary:
	return layers.get(layer_id, {})


func get_block(block_id: String) -> Dictionary:
	return blocks.get(block_id, {})


func get_verification(verification_id: String) -> Dictionary:
	return verifications.get(verification_id, {})


func get_verifications_for_account(account: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for verification_id in verifications.keys():
		var record: Dictionary = verifications[verification_id]
		if str(record.get("account", "")) == account and CubePoliticalVerification.is_active(record):
			result.append(record)
	return result


func get_effective_block_governor(block_id: String) -> Dictionary:
	var block := get_block(block_id)
	if block.is_empty():
		return {}

	if str(block.get("governance_status", "")) == "elected":
		return {
			"territory_id": block_id,
			"territory_type": "block",
			"account": str(block.get("governor_account", "")),
			"verification_id": str(block.get("political_verification_id", "")),
			"source": "block_election",
		}

	var layer_id := str(block.get("parent_layer_id", ""))
	var layer := get_layer(layer_id)
	if layer.is_empty():
		return {}

	if str(layer.get("governance_status", "")) in ["elected", "interim"] and bool(block.get("delegated_by_layer", true)):
		return {
			"territory_id": layer_id,
			"territory_type": "layer",
			"account": str(layer.get("governor_account", "")),
			"verification_id": str(layer.get("political_verification_id", "")),
			"source": "layer_delegation",
		}

	return {}


func get_effective_layer_governor(layer_id: String) -> Dictionary:
	var layer := get_layer(layer_id)
	if layer.is_empty():
		return {}
	if str(layer.get("governance_status", "")) in ["elected", "interim"]:
		return {
			"territory_id": layer_id,
			"territory_type": "layer",
			"account": str(layer.get("governor_account", "")),
			"verification_id": str(layer.get("political_verification_id", "")),
			"source": "layer_election",
		}
	return {}


func resolve_governance_chain(zone_id: String) -> Dictionary:
	var block_id := CubeTerritoryId.zone_to_block_id(zone_id)
	var layer_id := CubeTerritoryId.zone_to_layer_id(zone_id)
	return {
		"zone_id": zone_id,
		"block_id": block_id,
		"layer_id": layer_id,
		"layer_governor": get_effective_layer_governor(layer_id),
		"block_governor": get_effective_block_governor(block_id),
	}


func can_exercise_power(account: String, territory_id: String, power: String) -> bool:
	var allowed := _check_power_internal(account, territory_id, power)
	verification_checked.emit(account, territory_id, power, allowed)
	return allowed


func can_current_player_exercise_power(territory_id: String, power: String) -> bool:
	if not Auth.is_logged_in or Auth.is_guest:
		return false
	return can_exercise_power(Auth.username, territory_id, power)


func _check_power_internal(account: String, territory_id: String, power: String) -> bool:
	if account == "":
		return false

	var territory_type := CubeTerritoryId.territory_type(territory_id)
	match territory_type:
		"layer":
			return _can_govern_layer(account, territory_id, power)
		"block":
			return _can_govern_block(account, territory_id, power)
		"zone":
			return _can_govern_zone(account, territory_id, power)
		_:
			return false


func _can_govern_layer(account: String, layer_id: String, power: String) -> bool:
	if power not in LAYER_POWERS:
		return false
	var layer := get_layer(layer_id)
	if layer.is_empty():
		return false
	if str(layer.get("governance_status", "")) == "foundation":
		return false
	if str(layer.get("governor_account", "")) != account:
		return false
	return _has_active_verification(
		account,
		layer_id,
		CubePoliticalVerification.Level.LAYER_SOVEREIGN
	)


func _can_govern_block(account: String, block_id: String, power: String) -> bool:
	if power not in BLOCK_POWERS:
		return false

	var block := get_block(block_id)
	if block.is_empty():
		return false
	if str(block.get("governance_status", "")) == "foundation":
		return false

	var block_governor := get_effective_block_governor(block_id)
	if not block_governor.is_empty() and str(block_governor.get("account", "")) == account:
		if str(block_governor.get("source", "")) == "block_election":
			return _has_active_verification(
				account,
				block_id,
				CubePoliticalVerification.Level.BLOCK_GOVERNOR
			)
		if str(block_governor.get("source", "")) == "layer_delegation":
			return _has_active_verification(
				account,
				str(block.get("parent_layer_id", "")),
				CubePoliticalVerification.Level.LAYER_SOVEREIGN
			)

	return false


func _can_govern_zone(account: String, zone_id: String, power: String) -> bool:
	var block_id := CubeTerritoryId.zone_to_block_id(zone_id)
	var layer_id := CubeTerritoryId.zone_to_layer_id(zone_id)

	match power:
		POWER_ISSUE_BUILD_PERMIT, POWER_SET_ZONE_ZONING:
			if _can_govern_block(account, block_id, power):
				return true
			return _can_govern_layer(account, layer_id, power)
		_:
			return false


func _has_active_verification(account: String, territory_id: String, required_level: CubePoliticalVerification.Level) -> bool:
	for verification_id in verifications.keys():
		var record: Dictionary = verifications[verification_id]
		if str(record.get("account", "")) != account:
			continue
		if not CubePoliticalVerification.is_active(record):
			continue
		if not CubePoliticalVerification.matches_territory(record, territory_id):
			continue
		var level := CubePoliticalVerification.level_from_string(str(record.get("level", "")))
		if level == required_level or level == CubePoliticalVerification.Level.CUBE_COUNCIL:
			return true
	return false


func governance_summary() -> String:
	return "Styrning: %d lager, %d block, %d politiska verifieringar." % [
		layers.size(),
		blocks.size(),
		verifications.size(),
	]


func export_state() -> bool:
	var payload := {
		"exported_at": Time.get_datetime_string_from_system(),
		"hierarchy_rules": hierarchy_rules,
		"layers": layers,
		"blocks": blocks,
		"verifications": verifications,
	}
	var file := FileAccess.open(EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true