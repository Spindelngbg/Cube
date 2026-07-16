class_name GleazerCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const GleazerLoreScript = preload("res://scripts/story/gleazer_lore.gd")

const MEMBERS: Array = [
	{"id": "gleazer_bloop", "name": "Bloop", "role": "boss"},
	{"id": "gleazer_splat", "name": "Splat", "role": "gunner"},
	{"id": "gleazer_gurgle", "name": "Gurgle", "role": "scout"},
	{"id": "gleazer_drizzle", "name": "Drizzle", "role": "diplomat"},
	{"id": "gleazer_oozbert", "name": "Oozbert", "role": "tech"},
	{"id": "gleazer_muck", "name": "Muck", "role": "recruit"},
	{"id": "gleazer_slorp", "name": "Slorp", "role": "logistics"},
	{"id": "gleazer_puddle", "name": "Puddle", "role": "pr"},
	{"id": "gleazer_drip", "name": "Drip", "role": "recruit"},
	{"id": "gleazer_glop", "name": "Glop", "role": "gunner"},
	{"id": "gleazer_squelch", "name": "Squelch", "role": "scout"},
	{"id": "gleazer_blub", "name": "Blub", "role": "tech"},
]


static func get_spawn_plan(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	match id:
		"satellite_right":
			return _neo_washington_plan()
		"satellite_left":
			return _generic_plan(id, 4, Vector3(0.0, 0.0, 0.0))
		"satellite_top_a":
			return _generic_plan(id, 4, Vector3(12.0, 0.0, -18.0))
		"satellite_top_b":
			return _generic_plan(id, 4, Vector3(-16.0, 0.0, 22.0))
		_:
			return []


static func get_entry(npc_id: String) -> Dictionary:
	for spawn_id in SpawnPoints.IDS:
		for entry in get_spawn_plan(spawn_id):
			if str(entry.get("id", "")) == npc_id:
				return entry
	return {}


static func _neo_washington_plan() -> Array:
	var spots: Array = [
		_cell_pos(Vector2i(2, 0)) + Vector3(6.0, 0.0, -10.0),
		_cell_pos(Vector2i(0, 0)) + Vector3(10.0, 0.0, 18.0),
		_cell_pos(Vector2i(-2, 0)) + Vector3(-8.0, 0.0, 4.0),
		_cell_pos(Vector2i(1, 1)) + Vector3(14.0, 0.0, -22.0),
		_cell_pos(Vector2i(-3, -1)) + Vector3(-20.0, 0.0, 12.0),
		_cell_pos(Vector2i(-4, -3)) + Vector3(18.0, 0.0, 42.0),
		_cell_pos(Vector2i(-5, 1)) + Vector3(-14.0, 0.0, -18.0),
		_cell_pos(Vector2i(0, -2)) + Vector3(4.0, 0.0, -38.0),
		Vector3(-32.0, 0.0, -48.0),
		Vector3(48.0, 0.0, 28.0),
	]
	return _entries_from_spots(spots, true)


static func _generic_plan(_spawn_id: String, count: int, origin: Vector3) -> Array:
	var spots: Array = []
	var offsets := [
		Vector3(24.0, 0.0, -16.0),
		Vector3(-28.0, 0.0, 20.0),
		Vector3(36.0, 0.0, 32.0),
		Vector3(-18.0, 0.0, -34.0),
		Vector3(8.0, 0.0, 44.0),
		Vector3(-42.0, 0.0, -8.0),
	]
	for i in range(mini(count, offsets.size())):
		spots.append(origin + offsets[i])
	return _entries_from_spots(spots, false)


static func _entries_from_spots(spots: Array, use_dc_yaw: bool) -> Array:
	var out: Array = []
	for i in range(spots.size()):
		var member: Dictionary = MEMBERS[i % MEMBERS.size()]
		var role_id := str(member.get("role", "recruit"))
		var personal := str(member.get("name", "Gleazer"))
		var local_pos: Vector3 = spots[i]
		var yaw := atan2(local_pos.x, local_pos.z) + PI if use_dc_yaw else float(i) * 0.9
		out.append({
			"id": "%s_%d" % [str(member.get("id", "gleazer")), i],
			"gleazer": true,
			"gleazer_role": role_id,
			"gleazer_name": personal,
			"name": GleazerLoreScript.format_name(role_id, personal),
			"scale": 1.0,
			"local_pos": local_pos,
			"rotation_y": yaw,
			"wander": role_id != "boss",
			"wander_radius": 9.0 if role_id == "scout" else 6.5,
			"speed": 0.85 if role_id == "recruit" else 1.05,
			"prompt": "Prata med %s [E]" % personal,
		})
	return out


static func _cell_pos(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalogScript.BLOCK_M + DcZoneCatalogScript.BLOCK_M * 0.5
	)