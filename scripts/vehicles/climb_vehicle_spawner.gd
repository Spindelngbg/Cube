class_name ClimbVehicleSpawner
extends RefCounted

const WallCrawlVehicleScript = preload("res://scripts/vehicles/wall_crawl_vehicle.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")
const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")


static func populate(parent: Node3D, spawn_id: String, owdb_bridge: Node = null) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		return null

	var root := Node3D.new()
	root.name = "ClimbVehicles"
	parent.add_child(root)

	var theme := ColonyCityTheme.for_spawn(id)
	var accent: Color = theme.get("beacon_color", Color(0.35, 0.82, 0.95))
	var placements := _get_placements(id)
	var tree := Engine.get_main_loop() as SceneTree
	var sim_peer := 1
	if tree != null and tree.get_multiplayer().multiplayer_peer != null:
		sim_peer = MultiplayerEntityAuthorityScript.simulation_peer_id()

	for i in range(placements.size()):
		var entry: Dictionary = placements[i]
		var vehicle: WallCrawlVehicle = WallCrawlVehicleScript.new()
		vehicle.name = "GripCrawler_%s_%d" % [id, i]
		if tree != null and tree.get_multiplayer().multiplayer_peer != null:
			vehicle.set_multiplayer_authority(sim_peer)
		root.add_child(vehicle)
		vehicle.setup(
			{
				"position": entry.get("position", Vector3.ZERO),
				"rotation_y": float(entry.get("rotation_y", 0.0)),
				"accent": accent,
				"seed": hash("%s_climb_%d" % [id, i]),
			}
		)
		if owdb_bridge != null and owdb_bridge.has_method("register_runtime_entity"):
			owdb_bridge.register_runtime_entity(
				vehicle,
				"res://scripts/vehicles/wall_crawl_vehicle.gd",
				1
			)

	return root


static func _get_placements(spawn_id: String) -> Array:
	var cube_origin := SpawnPoints.get_position(spawn_id)
	if spawn_id == "satellite_right":
		var plaza := cube_origin + Vector3(20.0, 0.0, 20.0)
		var block := float(DcZoneCatalogScript.BLOCK_M)
		return [
			{"position": plaza + Vector3(14.0, 0.0, -10.0), "rotation_y": PI * 0.25},
			{"position": plaza + Vector3(-18.0, 0.0, 8.0), "rotation_y": -PI * 0.5},
			{"position": plaza + Vector3(-block * 2.0, 0.0, block * 0.5), "rotation_y": PI * 0.75},
			{"position": plaza + Vector3(block * 1.5, 0.0, block * 0.35), "rotation_y": -PI * 0.15},
			{"position": plaza + Vector3(-block * 4.0, 0.0, block * 0.2), "rotation_y": PI * 0.1},
			{"position": plaza + Vector3(-block * 1.0, 0.0, -block * 1.2), "rotation_y": PI * 0.55},
		]

	return [
		{"position": cube_origin + Vector3(18.0, 0.0, -14.0), "rotation_y": PI * 0.2},
		{"position": cube_origin + Vector3(-22.0, 0.0, 16.0), "rotation_y": -PI * 0.35},
		{"position": cube_origin + Vector3(32.0, 0.0, 24.0), "rotation_y": PI * 0.6},
		{"position": cube_origin + Vector3(-16.0, 0.0, -28.0), "rotation_y": -PI * 0.1},
	]