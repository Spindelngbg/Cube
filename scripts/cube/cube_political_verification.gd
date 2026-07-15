class_name CubePoliticalVerification
extends RefCounted

enum Level {
	NONE,
	ZONE_CITIZEN,
	BLOCK_GOVERNOR,
	LAYER_SOVEREIGN,
	CUBE_COUNCIL,
}

enum Status {
	UNVERIFIED,
	PENDING,
	VERIFIED,
	REVOKED,
	EXPIRED,
}

const LEVEL_NAMES := {
	Level.NONE: "none",
	Level.ZONE_CITIZEN: "zone_citizen",
	Level.BLOCK_GOVERNOR: "block_governor",
	Level.LAYER_SOVEREIGN: "layer_sovereign",
	Level.CUBE_COUNCIL: "cube_council",
}

const STATUS_NAMES := {
	Status.UNVERIFIED: "unverified",
	Status.PENDING: "pending",
	Status.VERIFIED: "verified",
	Status.REVOKED: "revoked",
	Status.EXPIRED: "expired",
}


static func level_from_string(value: String) -> Level:
	match value:
		"zone_citizen":
			return Level.ZONE_CITIZEN
		"block_governor":
			return Level.BLOCK_GOVERNOR
		"layer_sovereign":
			return Level.LAYER_SOVEREIGN
		"cube_council":
			return Level.CUBE_COUNCIL
		_:
			return Level.NONE


static func status_from_string(value: String) -> Status:
	match value:
		"pending":
			return Status.PENDING
		"verified":
			return Status.VERIFIED
		"revoked":
			return Status.REVOKED
		"expired":
			return Status.EXPIRED
		_:
			return Status.UNVERIFIED


static func is_active(record: Dictionary) -> bool:
	if record.is_empty():
		return false
	if status_from_string(str(record.get("status", ""))) != Status.VERIFIED:
		return false
	var expires_at := str(record.get("expires_at", ""))
	if expires_at != "" and expires_at < Time.get_datetime_string_from_system():
		return false
	return true


static func matches_territory(record: Dictionary, territory_id: String) -> bool:
	return str(record.get("territory_id", "")) == territory_id


static func required_level_for_territory(territory_type: String) -> Level:
	match territory_type:
		"layer":
			return Level.LAYER_SOVEREIGN
		"block":
			return Level.BLOCK_GOVERNOR
		"zone":
			return Level.ZONE_CITIZEN
		_:
			return Level.NONE