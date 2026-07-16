class_name PedestrianCatalog
extends RefCounted

const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const PedestrianStyleScript = preload("res://scripts/npcs/pedestrian_style.gd")

const ROUTE_REACH_M := 2.2


static func get_spawn_plan(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	match id:
		"satellite_right":
			return _neo_washington_entries()
		"satellite_left":
			return _simple_entries(id, 5)
		"satellite_top_a":
			return _simple_entries(id, 5)
		"satellite_top_b":
			return _simple_entries(id, 5)
		_:
			return []


static func _neo_washington_entries() -> Array:
	var routes: Array = [
		[Vector3(-180.0, 0.0, -6.0), Vector3(-24.0, 0.0, -6.0)],
		[Vector3(-120.0, 0.0, 34.0), Vector3(60.0, 0.0, 34.0)],
		[Vector3(12.0, 0.0, -100.0), Vector3(12.0, 0.0, 90.0)],
		[Vector3(-70.0, 0.0, -50.0), Vector3(40.0, 0.0, -50.0)],
		[Vector3(-150.0, 0.0, 10.0), Vector3(-60.0, 0.0, 10.0)],
		[Vector3(24.0, 0.0, -70.0), Vector3(24.0, 0.0, 50.0)],
		[Vector3(-40.0, 0.0, 50.0), Vector3(70.0, 0.0, 50.0)],
	]
	return _pack_routes("satellite_right", routes, 1.05, 1.25)


static func _simple_entries(spawn_id: String, count: int) -> Array:
	var routes: Array = []
	for i in range(count):
		var axis := 1.0 if i % 2 == 0 else -1.0
		var z := float(i * 18 - 36)
		routes.append([
			Vector3(-80.0 * axis, 0.0, z),
			Vector3(80.0 * axis, 0.0, z),
		])
	return _pack_routes(spawn_id, routes, 0.95, 1.15)


static func _pack_routes(spawn_id: String, routes: Array, speed_min: float, speed_max: float) -> Array:
	var out: Array = []
	for i in range(routes.size()):
		var route: Array = routes[i]
		if route.size() < 2:
			continue
		var seed := hash("%s_ped_%d" % [spawn_id, i])
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var start: Vector3 = route[0]
		var wallet := rng.randi_range(10, 15000)
		out.append({
			"id": "pedestrian_%s_%d" % [spawn_id, i],
			"pedestrian": true,
			"name": PedestrianStyleScript.pick_display_name(seed),
			"scale": 1.0,
			"style_seed": seed,
			"local_pos": start,
			"route": route,
			"wallet": wallet,
			"speed": rng.randf_range(speed_min, speed_max),
			"rotation_y": atan2(route[1].x - route[0].x, route[1].z - route[0].z),
			"wander": false,
		})
	return out