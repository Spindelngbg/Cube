class_name SpawnPoints
extends RefCounted

## Fyra kolonikuber (30×30×30 km). Nås via hiss från ljusrummet.
const IDS := ["satellite_left", "satellite_top_a", "satellite_top_b", "satellite_right"]

const COLONY_NUMBERS := {
	"satellite_left": 1,
	"satellite_top_a": 2,
	"satellite_top_b": 3,
	"satellite_right": 4,
}

const LEGACY_MAP := {
	"north_tower": "satellite_top_a",
	"south_hall": "satellite_top_b",
	"west_dock": "satellite_left",
	"east_gallery": "satellite_right",
}

const SATELLITE_EXTENT_KM := 30.0
const SATELLITE_EXTENT_M := 30_000.0
const EXTENT_LABEL := "30×30×30 km"
const LEFT_ELEVATOR_KM := 10.0

const DATA := {
	"satellite_left": {
		"name": "Koloni 1",
		"cube_id": "KOLONI_1_30",
		"description": "Koloni 1 — en satellitkub på 30×30×30 km. Din permanenta hemvist om du väljer den.",
		"elevator_mount": "left",
		"elevator_length_km": 10.0,
		"ride_axis": "horizontal_neg",
		"ride_duration": 6.5,
		"kit": "industrial",
		"spawn_norm": Vector2(0.027, 0.5),
	},
	"satellite_top_a": {
		"name": "Koloni 2",
		"cube_id": "KOLONI_2_30",
		"description": "Koloni 2 — en satellitkub på 30×30×30 km. Din permanenta hemvist om du väljer den.",
		"elevator_mount": "top",
		"elevator_index": 0,
		"ride_axis": "vertical",
		"ride_duration": 3.2,
		"kit": "commercial",
		"spawn_norm": Vector2(0.333, 0.027),
	},
	"satellite_top_b": {
		"name": "Koloni 3",
		"cube_id": "KOLONI_3_30",
		"description": "Koloni 3 — en satellitkub på 30×30×30 km. Din permanenta hemvist om du väljer den.",
		"elevator_mount": "top",
		"elevator_index": 1,
		"ride_axis": "vertical",
		"ride_duration": 3.2,
		"kit": "suburban",
		"spawn_norm": Vector2(0.667, 0.027),
	},
	"satellite_right": {
		"name": "Koloni 4",
		"cube_id": "KOLONI_4_30",
		"description": "Koloni 4 — Neo-Washington, en futuristisk huvudstad efter USA:s Washington. Kapitol vid spawn, Nationalmallen västerut, zontag på varje block.",
		"elevator_mount": "right",
		"ride_axis": "horizontal_pos",
		"ride_duration": 4.0,
		"kit": "commercial",
		"spawn_norm": Vector2(0.973, 0.5),
	},
}


static func normalize_id(spawn_id: String) -> String:
	if DATA.has(spawn_id):
		return spawn_id
	return str(LEGACY_MAP.get(spawn_id, ""))


static func default_colony_id() -> String:
	return "satellite_left"


static func ensure_colony_id(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return id if id != "" else default_colony_id()


static func is_valid(spawn_id: String) -> bool:
	return DATA.has(normalize_id(spawn_id))


static func get_extent_m() -> float:
	return SATELLITE_EXTENT_M


static func get_spawn_name(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return str(DATA.get(id, {}).get("name", spawn_id))


static func get_colony_number(spawn_id: String) -> int:
	var id := normalize_id(spawn_id)
	return int(COLONY_NUMBERS.get(id, 0))


static func get_colony_label(spawn_id: String) -> String:
	var num := get_colony_number(spawn_id)
	if num > 0:
		return "Koloni %d" % num
	return get_spawn_name(spawn_id)


static func get_elevator_label(spawn_id: String) -> String:
	var num := get_colony_number(spawn_id)
	if num > 0:
		return "Hiss %d Koloni %d" % [num, num]
	return get_spawn_name(spawn_id)


static func get_extent_label() -> String:
	return EXTENT_LABEL


static func get_cube_id(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return str(DATA.get(id, {}).get("cube_id", ""))


## Yta på garanterad spawn-platta (byggs i varje koloni).
const SPAWN_PAD_SURFACE_Y := 0.55
## Spelarens fötter över golvytan (världs-Y). Påverkar INTE världsgeometrins origin.
const SPAWN_FOOT_Y := SPAWN_PAD_SURFACE_Y + 0.12


static func get_position(spawn_id: String) -> Vector3:
	var id := ensure_colony_id(spawn_id)
	var entry: Dictionary = DATA.get(id, {})
	var norm_raw: Variant = entry.get("spawn_norm", Vector2(0.5, 0.5))
	var norm: Vector2 = norm_raw as Vector2 if norm_raw is Vector2 else Vector2(0.5, 0.5)
	# Y=0 = kubens golvyta. Byggnader/stad byggs relativt denna origin.
	return Vector3(
		clampf(norm.x, 0.0, 1.0) * SATELLITE_EXTENT_M,
		0.0,
		clampf(norm.y, 0.0, 1.0) * SATELLITE_EXTENT_M
	)


## Var spelaren faktiskt ska stå i kolonin (kan skilja från kub-hörnet).
## Viktigt: ska ligga på öppen yta, inte mitt i byggnads-kollision.
static func get_play_spawn_position(spawn_id: String) -> Vector3:
	var id := ensure_colony_id(spawn_id)
	var base := get_position(id)
	match id:
		"satellite_right":
			# Kapitolplaza (cell 0,0 centrum) — kapitoliet ligger norrut, ytan är fri.
			base += Vector3(20.0, 0.0, 20.0)
		_:
			# Ankomsthubbens öppna plattform (centrum), inte kubens hörnkant.
			base += Vector3(0.0, 0.0, 0.0)
	base.y = SPAWN_FOOT_Y
	return base


## Flyttar spelvärlden nära origo (XZ) så fysik och raycasts inte glappar vid ~30 km.
static func get_world_origin_shift(spawn_id: String) -> Vector3:
	var play := get_play_spawn_position(spawn_id)
	return Vector3(play.x, 0.0, play.z)


static func to_shifted_world(logical: Vector3, spawn_id: String) -> Vector3:
	var shift := get_world_origin_shift(spawn_id)
	return Vector3(logical.x - shift.x, logical.y, logical.z - shift.z)


static func to_logical_world(shifted: Vector3, spawn_id: String) -> Vector3:
	var shift := get_world_origin_shift(spawn_id)
	return Vector3(shifted.x + shift.x, shifted.y, shifted.z + shift.z)


static func get_shifted_play_spawn(spawn_id: String) -> Vector3:
	return to_shifted_world(get_play_spawn_position(spawn_id), spawn_id)


static func colony_number_to_id(colony_number: int) -> String:
	for id in IDS:
		if int(COLONY_NUMBERS.get(id, 0)) == colony_number:
			return id
	return ""


static func resolve_spawn_token(token: String) -> String:
	var t := token.strip_edges().to_lower()
	if t.is_valid_int():
		return colony_number_to_id(int(t))
	return normalize_id(t)


static func get_map_view_half_extent(spawn_id: String) -> float:
	var id := normalize_id(spawn_id)
	if id == "satellite_right":
		return 300.0
	return 170.0


static func get_map_view_center(spawn_id: String) -> Vector3:
	return get_play_spawn_position(spawn_id)


static func get_description(spawn_id: String) -> String:
	var id := normalize_id(spawn_id)
	return str(DATA.get(id, {}).get("description", ""))


static func get_entry(spawn_id: String) -> Dictionary:
	var id := normalize_id(spawn_id)
	return DATA.get(id, {})