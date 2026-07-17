class_name AllmakareCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")

const NAMES: Array[String] = [
	"Lumen",
	"Välvilja",
	"Dofta",
	"Skuldros",
	"Faktura",
]


static func get_spawn_plan(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	match id:
		"satellite_right":
			return _neo_plan()
		"satellite_left", "satellite_top_a", "satellite_top_b":
			return _generic_plan(id)
		_:
			return []


static func _neo_plan() -> Array:
	var spots: Array = [
		_cell(Vector2i(0, 0)) + Vector3(-6.0, 0.0, 14.0),
		_cell(Vector2i(-2, 0)) + Vector3(4.0, 0.0, -10.0),
		_cell(Vector2i(1, 0)) + Vector3(18.0, 0.0, 6.0),
		_cell(Vector2i(-3, -1)) + Vector3(-12.0, 0.0, 22.0),
	]
	return _entries(spots, "satellite_right")


static func _generic_plan(spawn_id: String) -> Array:
	var hub := SpawnPoints.get_play_spawn_position(spawn_id)
	var offsets := [
		Vector3(18.0, 0.0, 10.0),
		Vector3(-16.0, 0.0, -8.0),
	]
	var spots: Array = []
	for off in offsets:
		spots.append(off)
	return _entries(spots, spawn_id)


static func _entries(local_spots: Array, spawn_id: String = "satellite_right") -> Array:
	var out: Array = []
	for i in range(local_spots.size()):
		var personal := NAMES[i % NAMES.size()]
		out.append({
			"id": "allmakare_%s_%d" % [spawn_id, i],
			"zezzlor": true,
			"zezzlor_rank": "allmakare",
			"zezzlor_name": personal,
			"allmakare": true,
			"allmakare_name": personal,
			"name": ZezzlorLoreScript.format_name("allmakare", personal),
			"scale": 1.08,
			"local_pos": local_spots[i],
			"rotation_y": float(i) * 1.1,
			"wander": false,
			"speed": 0.0,
			"prompt": "Allmakare · Zezzlor — heal / betala [E]",
		})
	return out


static func _cell(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5
	)
