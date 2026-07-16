class_name WaterBuilder
extends RefCounted

const WaterVolumeScript = preload("res://scripts/environment/water_volume.gd")

const DEFAULT_WATER_COLOR := Color(0.1, 0.42, 0.72, 0.78)
const POOL_WATER_COLOR := Color(0.14, 0.58, 0.82, 0.74)
const TIDAL_WATER_COLOR := Color(0.08, 0.34, 0.62, 0.82)


static func build_city_water_features(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "WaterFeatures"
	parent.add_child(root)

	_populate_waterfront_cells(root)
	_add_mall_reflecting_pool(root)
	_add_spawn_plaza_fountain(root)
	_add_scattered_ponds(root)
	return root


static func populate_zone_water(
	parent: Node3D,
	center: Vector3,
	cell: Vector2i,
	zone_type: String,
	kit: String,
	rotation_y: float
) -> void:
	if zone_type == "VATTENFRONT":
		create_pond(
			parent,
			center,
			Vector2(30.0, 30.0),
			2.35,
			"tidal",
			0.0
		)
		return

	if _should_zone_have_pool(zone_type, kit, cell):
		place_house_pool(parent, center, rotation_y, cell)


static func place_house_pool(
	parent: Node3D,
	building_center: Vector3,
	rotation_y: float,
	seed_cell: Vector2i
) -> WaterVolume:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pool_%d_%d" % [seed_cell.x, seed_cell.y])
	var offset := Vector3(
		rng.randf_range(8.5, 12.5),
		0.0,
		rng.randf_range(-11.0, -6.5)
	).rotated(Vector3.UP, rotation_y)
	var size := Vector2(
		rng.randf_range(5.5, 8.0),
		rng.randf_range(4.5, 6.5)
	)
	var depth := rng.randf_range(0.95, 1.35)
	return create_pool(parent, building_center + offset, size, depth, "residential", rotation_y)


static func create_pool(
	parent: Node3D,
	position: Vector3,
	size: Vector2,
	depth: float,
	style: String = "pool",
	rotation_y: float = 0.0
) -> WaterVolume:
	return _spawn_volume(
		parent,
		{
			"position": position,
			"size": Vector3(size.x, depth, size.y),
			"depth": depth,
			"color": POOL_WATER_COLOR,
			"style": style,
			"rotation_y": rotation_y,
		}
	)


static func create_pond(
	parent: Node3D,
	position: Vector3,
	size: Vector2,
	depth: float,
	style: String = "pond",
	rotation_y: float = 0.0
) -> WaterVolume:
	return _spawn_volume(
		parent,
		{
			"position": position,
			"size": Vector3(size.x, depth, size.y),
			"depth": depth,
			"color": TIDAL_WATER_COLOR if style == "tidal" else DEFAULT_WATER_COLOR,
			"style": style,
			"rotation_y": rotation_y,
		}
	)


static func scatter_hub_pools(parent: Node3D, building_positions: Array, spawn_id: String) -> void:
	for i in range(building_positions.size()):
		if abs(hash("%s_pool_%d" % [spawn_id, i])) % 3 == 0:
			continue
		var pos: Vector3 = building_positions[i]
		var rot := float(i) * PI * 0.5
		place_house_pool(parent, pos, rot, Vector2i(i, hash(spawn_id) % 97))


static func scatter_suburban_pool(
	parent: Node3D,
	building_pos: Vector3,
	rotation_y: float,
	zone: Vector2i
) -> void:
	if (zone.x + zone.y + abs(zone.x * 3 - zone.y)) % 3 != 0:
		return
	place_house_pool(parent, building_pos, rotation_y, zone)


static func _populate_waterfront_cells(parent: Node3D) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	for x in range(extent.x_min, extent.x_max + 1):
		for z in range(extent.z_min, extent.z_max + 1):
			var cell := Vector2i(x, z)
			var spec: Dictionary = DcZoneCatalog.classify_cell(cell)
			if str(spec.get("zone_type", "")) != "VATTENFRONT":
				continue
			var origin := _dc_cell_origin(cell)
			var center := origin + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
			create_pond(parent, center, Vector2(32.0, 32.0), 2.4, "tidal", 0.0)


static func _add_mall_reflecting_pool(parent: Node3D) -> void:
	var center := _dc_cell_origin(Vector2i(-3, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	create_pond(parent, center + Vector3(8.0, 0.0, -6.0), Vector2(14.0, 9.0), 1.05, "reflecting", 0.0)
	create_pond(parent, center + Vector3(-10.0, 0.0, 8.0), Vector2(10.0, 7.0), 0.85, "reflecting", 0.2)


static func _add_spawn_plaza_fountain(parent: Node3D) -> void:
	var center := _dc_cell_origin(Vector2i(0, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	create_pool(parent, center + Vector3(10.0, 0.0, 10.0), Vector2(5.0, 5.0), 0.75, "plaza", 0.0)


static func _add_scattered_ponds(parent: Node3D) -> void:
	var spots := [
		{"cell": Vector2i(-5, 2), "offset": Vector3(6.0, 0.0, -8.0), "size": Vector2(11.0, 8.0)},
		{"cell": Vector2i(-1, 4), "offset": Vector3(-9.0, 0.0, 5.0), "size": Vector2(9.0, 12.0)},
		{"cell": Vector2i(2, -3), "offset": Vector3(4.0, 0.0, -6.0), "size": Vector2(13.0, 10.0)},
		{"cell": Vector2i(-4, -2), "offset": Vector3(0.0, 0.0, 0.0), "size": Vector2(16.0, 14.0)},
	]
	for entry in spots:
		var cell: Vector2i = entry.cell
		var origin := _dc_cell_origin(cell)
		var center := origin + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
		create_pond(parent, center + entry.offset, entry.size, 1.45, "pond", 0.0)


static func _should_zone_have_pool(zone_type: String, kit: String, cell: Vector2i) -> bool:
	if kit == "suburban":
		return abs(hash(Vector2i(cell.x, cell.y))) % 4 != 0
	if zone_type in ["BOSTADSKVARTER", "AMBASSADNÄSET", "PRESIDENTKORRIDOR"]:
		return abs(hash(Vector2i(cell.x + 11, cell.y * 3))) % 3 != 0
	return false


static func _spawn_volume(parent: Node3D, config: Dictionary) -> WaterVolume:
	var volume: WaterVolume = WaterVolumeScript.new()
	volume.name = str(config.get("name", "Water"))
	parent.add_child(volume)
	volume.configure(config)
	return volume


static func _dc_cell_origin(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * DcZoneCatalog.BLOCK_M, 0.0, float(cell.y) * DcZoneCatalog.BLOCK_M)