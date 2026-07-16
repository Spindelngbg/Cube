class_name CubeCityBuilder
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")

const DISTRICT_SIZE_M := (
	CubeConstants.PROTOTYPE_BLOCK_COUNT * CubeConstants.PROTOTYPE_METERS_PER_BLOCK
)
const SHELL_HEIGHT_M := 18.0
const FLOOR_TILE_M := 4.0
const WALL_TILE_M := 4.0

const COMMERCIAL_BUILDINGS := ["building-a", "building-b", "building-c", "building-d", "building-e"]
const SUBURBAN_BUILDINGS := ["building-type-a", "building-type-b", "building-type-c", "building-type-d"]
const INDUSTRIAL_BUILDINGS := ["building-a", "building-b", "building-c", "building-d"]


static func build(parent: Node3D) -> Node3D:
	DevBuildingLabelsScript.reset()
	var root := Node3D.new()
	root.name = "CubeCity"
	parent.add_child(root)

	_build_collision_floor(root)
	_build_shell(root)
	_build_block_roads(root)
	_build_district_zones(root)

	CubeRegistry.export_registry()
	return root


static func _build_collision_floor(root: Node3D) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "DistrictFloor"
	root.add_child(floor_body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(DISTRICT_SIZE_M, 0.4, DISTRICT_SIZE_M)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(DISTRICT_SIZE_M * 0.5, -0.2, DISTRICT_SIZE_M * 0.5)
	floor_body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(DISTRICT_SIZE_M, 0.4, DISTRICT_SIZE_M)
	collision.shape = shape
	collision.position = mesh_instance.position
	floor_body.add_child(collision)


static func _build_shell(root: Node3D) -> void:
	var shell := Node3D.new()
	shell.name = "CubeShell"
	root.add_child(shell)

	var tiles_x := int(ceil(DISTRICT_SIZE_M / FLOOR_TILE_M))
	var tiles_z := int(ceil(DISTRICT_SIZE_M / FLOOR_TILE_M))
	for x in range(tiles_x):
		for z in range(tiles_z):
			SpaceKitLibrary.spawn(
				shell,
				"template-floor-big",
				Vector3(x * FLOOR_TILE_M + FLOOR_TILE_M * 0.5, 0.0, z * FLOOR_TILE_M + FLOOR_TILE_M * 0.5)
			)

	_build_wall_row(shell, Vector3(0, 0, 0), Vector3(0, 0, DISTRICT_SIZE_M), true)
	_build_wall_row(shell, Vector3(DISTRICT_SIZE_M, 0, 0), Vector3(DISTRICT_SIZE_M, 0, DISTRICT_SIZE_M), true)
	_build_wall_row(shell, Vector3(0, 0, 0), Vector3(DISTRICT_SIZE_M, 0, 0), false)
	_build_wall_row(shell, Vector3(0, 0, DISTRICT_SIZE_M), Vector3(DISTRICT_SIZE_M, 0, DISTRICT_SIZE_M), false)

	for x in range(tiles_x):
		for z in range(tiles_z):
			SpaceKitLibrary.spawn(
				shell,
				"template-floor-big",
				Vector3(
					x * FLOOR_TILE_M + FLOOR_TILE_M * 0.5,
					SHELL_HEIGHT_M,
					z * FLOOR_TILE_M + FLOOR_TILE_M * 0.5
				)
			)

	SpaceKitLibrary.spawn(
		shell,
		"gate-door-window",
		Vector3(DISTRICT_SIZE_M * 0.5, 0.0, 0.5),
		PI
	)
	SpaceKitLibrary.spawn(
		shell,
		"room-large",
		Vector3(DISTRICT_SIZE_M * 0.5, 0.0, DISTRICT_SIZE_M * 0.5),
		0.0
	)


static func _build_wall_row(shell: Node3D, start: Vector3, end: Vector3, along_z: bool) -> void:
	var direction := (end - start).normalized()
	var length := start.distance_to(end)
	var steps := int(ceil(length / WALL_TILE_M))
	for i in range(steps):
		var base := start + direction * (i * WALL_TILE_M + WALL_TILE_M * 0.5)
		for level in range(int(SHELL_HEIGHT_M / 3.0)):
			var pos := Vector3(base.x, level * 3.0, base.z)
			var rotation_y := PI * 0.5 if along_z else 0.0
			SpaceKitLibrary.spawn(shell, "template-wall", pos, rotation_y)


static func _build_block_roads(root: Node3D) -> void:
	var roads := Node3D.new()
	roads.name = "BlockRoads"
	root.add_child(roads)

	for block_index in range(CubeConstants.PROTOTYPE_BLOCK_COUNT + 1):
		var offset := block_index * CubeConstants.PROTOTYPE_METERS_PER_BLOCK
		_spawn_road_strip(roads, Vector3(offset, 0.02, DISTRICT_SIZE_M * 0.5), 0.0, DISTRICT_SIZE_M)
		_spawn_road_strip(roads, Vector3(DISTRICT_SIZE_M * 0.5, 0.02, offset), PI * 0.5, DISTRICT_SIZE_M)

	for bx in range(CubeConstants.PROTOTYPE_BLOCK_COUNT):
		for bz in range(CubeConstants.PROTOTYPE_BLOCK_COUNT):
			var center := Vector3(
				bx * CubeConstants.PROTOTYPE_METERS_PER_BLOCK + CubeConstants.PROTOTYPE_METERS_PER_BLOCK * 0.5,
				0.03,
				bz * CubeConstants.PROTOTYPE_METERS_PER_BLOCK + CubeConstants.PROTOTYPE_METERS_PER_BLOCK * 0.5
			)
			CityKitLibrary.spawn(roads, "roads", "road-intersection", center)


static func _spawn_road_strip(parent: Node3D, center: Vector3, rotation_y: float, length_m: float) -> void:
	var segments := int(ceil(length_m / 4.0))
	for i in range(segments):
		var offset := (i - segments * 0.5) * 4.0
		var pos := center
		if abs(rotation_y) < 0.1:
			pos.x += offset
		else:
			pos.z += offset
		CityKitLibrary.spawn(parent, "roads", "road-straight", pos, rotation_y)


static func _build_district_zones(root: Node3D) -> void:
	var zones_root := Node3D.new()
	zones_root.name = "DistrictZones"
	root.add_child(zones_root)

	for bx in range(CubeConstants.PROTOTYPE_BLOCK_COUNT):
		for bz in range(CubeConstants.PROTOTYPE_BLOCK_COUNT):
			var block := CubeConstants.PROTOTYPE_BLOCK_ORIGIN + Vector2i(bx, bz)
			_build_block(zones_root, block)


static func _build_block(parent: Node3D, block: Vector2i) -> void:
	var block_root := Node3D.new()
	block_root.name = "Block_%s" % CubeTerritoryId.block_id(CubeConstants.PROTOTYPE_LAYER, block)
	parent.add_child(block_root)

	var kit := _kit_for_block(block)
	for zx in range(CubeConstants.PROTOTYPE_ZONES_PER_BLOCK):
		for zz in range(CubeConstants.PROTOTYPE_ZONES_PER_BLOCK):
			var zone := Vector2i(zx, zz)
			var zone_id := CubeZoneId.make(CubeConstants.PROTOTYPE_LAYER, block, zone)
			var zone_entry := _ensure_zone_entry(zone_id, block, zone)
			_build_zone(block_root, zone_entry, kit)


static func _ensure_zone_entry(zone_id: String, block: Vector2i, zone: Vector2i) -> Dictionary:
	var existing := CubeRegistry.get_zone(zone_id)
	if not existing.is_empty():
		return existing

	var block_id := CubeTerritoryId.block_id(CubeConstants.PROTOTYPE_LAYER, block)
	var governance_locked := false
	var block_record := CubeRegistry.get_block_record(block_id)
	if not block_record.is_empty():
		governance_locked = str(block_record.get("governance_status", "")) == "locked"

	var entry := {
		"zone_id": zone_id,
		"layer": CubeConstants.PROTOTYPE_LAYER,
		"block": [block.x, block.y],
		"zone": [zone.x, zone.y],
		"district": "L10-CORE",
		"name": "Zon %d-%d" % [zone.x, zone.y],
		"ownership": "public",
		"nft_ready": true,
		"open_build": false,
		"governed_by_block": block_id,
		"governed_by_layer": CubeTerritoryId.layer_id(CubeConstants.PROTOTYPE_LAYER),
		"governance_locked": governance_locked,
		"structures": [],
	}
	CubeRegistry.register_prototype_zone(entry)
	return entry


static func _build_zone(parent: Node3D, zone_entry: Dictionary, kit: String) -> void:
	var zone_id := str(zone_entry.get("zone_id", ""))
	var block_arr: Array = zone_entry.get("block", [0, 0])
	var zone_arr: Array = zone_entry.get("zone", [0, 0])
	var block := Vector2i(int(block_arr[0]), int(block_arr[1]))
	var zone := Vector2i(int(zone_arr[0]), int(zone_arr[1]))

	var zone_root := Node3D.new()
	zone_root.name = zone_id
	parent.add_child(zone_root)

	var origin := CubeZoneId.prototype_origin_m(block, zone)
	zone_root.position = origin

	var ownership := str(zone_entry.get("ownership", "public"))
	if ownership == "foundation":
		_place_structure(zone_root, zone_id, "space", "room-large", Vector3(5, 0, 5), 0.0)
		return
	if ownership == "reserved":
		SpaceKitLibrary.spawn(zone_root, "gate-lasers", Vector3(5, 0, 5), 0.0)
		CityKitLibrary.spawn(zone_root, "roads", "tile-low", Vector3(5, 0.01, 5))
		return

	var structures: Array = zone_entry.get("structures", [])
	if structures.is_empty():
		structures = [_default_structure_for_zone(zone_entry, kit)]

	for structure in structures:
		if typeof(structure) != TYPE_DICTIONARY:
			continue
		var offset_arr: Array = structure.get("offset", [4, 0, 4])
		var pos := Vector3(float(offset_arr[0]), float(offset_arr[1]), float(offset_arr[2]))
		_place_structure(
			zone_root,
			zone_id,
			str(structure.get("kit", kit)),
			str(structure.get("model", _pick_building(kit, zone))),
			pos,
			float(structure.get("rotation_y", 0.0))
		)

	CityKitLibrary.spawn(zone_root, "roads", "tile-low", Vector3(5, 0.01, 5))


static func _default_structure_for_zone(zone_entry: Dictionary, kit: String) -> Dictionary:
	var zone_arr: Array = zone_entry.get("zone", [0, 0])
	var zone := Vector2i(int(zone_arr[0]), int(zone_arr[1]))
	return {
		"kit": kit,
		"model": _pick_building(kit, zone),
		"offset": [4, 0, 4],
		"rotation_y": float((zone.x + zone.y) % 4) * PI * 0.5,
	}


static func _place_structure(
	parent: Node3D,
	zone_id: String,
	kit: String,
	model: String,
	position: Vector3,
	rotation_y: float
) -> Node3D:
	var node: Node3D = null
	if kit == "space":
		node = SpaceKitLibrary.spawn(parent, model, position, rotation_y)
	else:
		node = CityKitLibrary.spawn(parent, kit, model, position, rotation_y)

	if node == null:
		return null

	node.set_meta("zone_id", zone_id)
	node.set_meta("structure_kit", kit)
	node.set_meta("structure_model", model)
	CubeRegistry.register_build_event(zone_id, kit, model, parent.position + position, rotation_y)
	return node


static func _kit_for_block(block: Vector2i) -> String:
	var local := block - CubeConstants.PROTOTYPE_BLOCK_ORIGIN
	var center := Vector2i(
		CubeConstants.PROTOTYPE_BLOCK_COUNT / 2,
		CubeConstants.PROTOTYPE_BLOCK_COUNT / 2
	)
	var dist := maxi(abs(local.x - center.x), abs(local.y - center.y))
	if dist <= 0:
		return "commercial"
	if dist == 1:
		return "suburban"
	return "industrial"


static func _pick_building(kit: String, zone: Vector2i) -> String:
	var pool: Array[String] = []
	match kit:
		"commercial":
			pool = COMMERCIAL_BUILDINGS
		"suburban":
			pool = SUBURBAN_BUILDINGS
		"industrial":
			pool = INDUSTRIAL_BUILDINGS
		_:
			pool = COMMERCIAL_BUILDINGS
	var index := (zone.x * 11 + zone.y * 7) % pool.size()
	return pool[index]