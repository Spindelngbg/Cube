class_name SpawnPoints
extends RefCounted

## Fyra satellitkuber (30×30×30 km). Endast nåbara via hiss från ljusrummet.
const IDS := ["satellite_left", "satellite_top_a", "satellite_top_b", "satellite_right"]

const LEGACY_MAP := {
	"north_tower": "satellite_top_a",
	"south_hall": "satellite_top_b",
	"west_dock": "satellite_left",
	"east_gallery": "satellite_right",
}

const SATELLITE_EXTENT_KM := 30.0
const SATELLITE_EXTENT_M := 30_000.0
const PROTOTYPE_SIZE_M := 30.0
const LEFT_ELEVATOR_KM := 10.0

const DATA := {
	"satellite_left": {
		"name": "Vänsterkuben",
		"cube_id": "SAT_LEFT_30",
		"description": "En 30×30×30 km satellitkub. Nås via 10 km hiss på huvudkubens vänstra sida.",
		"elevator_mount": "left",
		"elevator_length_km": 10.0,
		"ride_axis": "horizontal_neg",
		"ride_duration": 6.5,
		"kit": "industrial",
		"position": Vector3(15.0, 0.5, 15.0),
	},
	"satellite_top_a": {
		"name": "Toppkuben Alfa",
		"cube_id": "SAT_TOP_A_30",
		"description": "En 30×30×30 km satellitkub ovanpå huvudkuben. Hiss port A.",
		"elevator_mount": "top",
		"elevator_index": 0,
		"ride_axis": "vertical",
		"ride_duration": 3.2,
		"kit": "commercial",
		"position": Vector3(10.0, 0.5, 15.0),
	},
	"satellite_top_b": {
		"name": "Toppkuben Beta",
		"cube_id": "SAT_TOP_B_30",
		"description": "En 30×30×30 km satellitkub ovanpå huvudkuben. Hiss port B.",
		"elevator_mount": "top",
		"elevator_index": 1,
		"ride_axis": "vertical",
		"ride_duration": 3.2,
		"kit": "suburban",
		"position": Vector3(20.0, 0.5, 15.0),
	},
	"satellite_right": {
		"name": "Högerkuben",
		"cube_id": "SAT_RIGHT_30",
		"description": "En 30×30×30 km satellitkub. Nås via hiss på huvudkubens högra sida.",
		"elevator_mount": "right",
		"ride_axis": "horizontal_pos",
		"ride_duration": 4.0,
		"kit": "commercial",
		"position": Vector3(15.0, 0.5, 10.0),
	},
}


static func normalize_id(spawn_id: String) -> String:
	if DATA.has(spawn_id):
		return spawn_id
	return str(LEGACY_MAP.get(spawn_id, ""))


static func is_valid(spawn_id: String) -> bool:
	return DATA.has(normalize_id(spawn_id))


static func get_name(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return str(DATA.get(id, {}).get("name", spawn_id))


static func get_cube_id(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return str(DATA.get(id, {}).get("cube_id", ""))


static func get_position(spawn_id: String) -> Vector3:
	var id := normalize_id(spawn_id)
	var entry: Dictionary = DATA.get(id, {})
	if entry.has("position") and entry.position is Vector3:
		return entry.position
	var pos: Array = entry.get("position", [15.0, 0.5, 15.0])
	return Vector3(float(pos[0]), float(pos[1]), float(pos[2]))


static func get_description(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return str(DATA.get(id, {}).get("description", ""))


static func get_entry(spawn_id: String) -> Dictionary:
	var id := normalize_id(spawn_id)
	return DATA.get(id, {})