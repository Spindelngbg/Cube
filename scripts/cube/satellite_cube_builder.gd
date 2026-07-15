class_name SatelliteCubeBuilder
extends RefCounted


static func build(parent: Node3D, spawn_id: String) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		id = "satellite_left"

	var entry := SpawnPoints.get_entry(id)
	var size_m := SpawnPoints.PROTOTYPE_SIZE_M
	var root := Node3D.new()
	root.name = "Satellite_%s" % id
	parent.add_child(root)

	_build_shell(root, size_m, id)
	_build_arrival_platform(root, size_m, entry)
	_build_district(root, size_m, str(entry.get("kit", "commercial")))

	var label := Label3D.new()
	label.text = "%s\n30×30×30 km\nEnda vägen: hiss till huvudkuben" % SpawnPoints.get_name(id)
	label.font_size = 36
	label.modulate = Color(0.85, 0.8, 0.7)
	label.position = Vector3(size_m * 0.5, 3.0, size_m * 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	return root


static func _build_shell(root: Node3D, size_m: float, spawn_id: String) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	root.add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(size_m, 0.35, size_m)
	floor_mesh.mesh = floor_box
	floor_mesh.position = Vector3(size_m * 0.5, -0.17, size_m * 0.5)
	floor_body.add_child(floor_mesh)

	var floor_shape := CollisionShape3D.new()
	var floor_col := BoxShape3D.new()
	floor_col.size = Vector3(size_m, 0.35, size_m)
	floor_shape.shape = floor_col
	floor_shape.position = floor_mesh.position
	floor_body.add_child(floor_shape)

	var tile := 4.0
	var tiles := int(ceil(size_m / tile))
	for x in range(tiles):
		for z in range(tiles):
			SpaceKitLibrary.spawn(
				root,
				"template-floor-big",
				Vector3(x * tile + tile * 0.5, 0.0, z * tile + tile * 0.5)
			)

	var wall_h := 14.0
	_build_wall_plane(root, Vector3(0, wall_h * 0.5, size_m * 0.5), Vector3(0.3, wall_h, size_m), true)
	_build_wall_plane(root, Vector3(size_m, wall_h * 0.5, size_m * 0.5), Vector3(0.3, wall_h, size_m), true)
	_build_wall_plane(root, Vector3(size_m * 0.5, wall_h * 0.5, 0), Vector3(size_m, wall_h, 0.3), false)
	_build_wall_plane(root, Vector3(size_m * 0.5, wall_h * 0.5, size_m), Vector3(size_m, wall_h, 0.3), false)

	for x in range(tiles):
		for z in range(tiles):
			SpaceKitLibrary.spawn(
				root,
				"template-floor-big",
				Vector3(x * tile + tile * 0.5, wall_h, z * tile + tile * 0.5)
			)

	_mount_elevator_shaft(root, size_m, spawn_id)


static func _build_wall_plane(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	along_z: bool
) -> void:
	var steps := int(ceil(max(size.x, size.z) / 4.0))
	for i in range(steps):
		var offset := i * 4.0 + 2.0
		var p := pos
		if along_z:
			p.x = offset if size.x > size.z else pos.x
			p.z = pos.z + (i - steps * 0.5) * 0.0
		else:
			p.z = offset if size.z > size.x else pos.z
		SpaceKitLibrary.spawn(parent, "template-wall", p, PI * 0.5 if along_z else 0.0)


static func _mount_elevator_shaft(root: Node3D, size_m: float, spawn_id: String) -> void:
	var entry := SpawnPoints.get_entry(spawn_id)
	var mount := str(entry.get("elevator_mount", "left"))
	var shaft := Node3D.new()
	shaft.name = "ElevatorShaft"
	root.add_child(shaft)

	match mount:
		"left":
			SpaceKitLibrary.spawn(shaft, "corridor-wide", Vector3(1.5, 0, size_m * 0.5), PI * 0.5)
			SpaceKitLibrary.spawn(shaft, "gate-door-window", Vector3(0.8, 0, size_m * 0.5), PI * 0.5)
		"right":
			SpaceKitLibrary.spawn(shaft, "corridor-wide", Vector3(size_m - 1.5, 0, size_m * 0.5), -PI * 0.5)
			SpaceKitLibrary.spawn(shaft, "gate-door-window", Vector3(size_m - 0.8, 0, size_m * 0.5), -PI * 0.5)
		"top":
			SpaceKitLibrary.spawn(shaft, "stairs-wide", Vector3(size_m * 0.5, 0, 1.5))
			SpaceKitLibrary.spawn(shaft, "gate-door-window", Vector3(size_m * 0.5, 0, 0.8), PI)


static func _build_arrival_platform(root: Node3D, size_m: float, entry: Dictionary) -> void:
	var spawn_pos: Vector3 = entry.get("position", Vector3(size_m * 0.5, 0.5, size_m * 0.5))
	if spawn_pos == Vector3.ZERO:
		spawn_pos = Vector3(size_m * 0.5, 0.5, size_m * 0.5)

	var platform := Node3D.new()
	platform.name = "ArrivalPlatform"
	platform.position = spawn_pos
	root.add_child(platform)
	SpaceKitLibrary.spawn(platform, "template-floor-detail-a", Vector3(0, 0, 0))
	SpaceKitLibrary.spawn(platform, "room-small", Vector3(0, 0, 2))


static func _build_district(root: Node3D, size_m: float, kit: String) -> void:
	var district := Node3D.new()
	district.name = "District"
	root.add_child(district)

	var buildings := _building_pool(kit)
	var spots := [
		Vector3(size_m * 0.35, 0, size_m * 0.35),
		Vector3(size_m * 0.65, 0, size_m * 0.4),
		Vector3(size_m * 0.4, 0, size_m * 0.7),
		Vector3(size_m * 0.7, 0, size_m * 0.65),
	]
	for i in range(spots.size()):
		var model := buildings[i % buildings.size()]
		CityKitLibrary.spawn(district, kit, model, spots[i], float(i) * PI * 0.5)
		CityKitLibrary.spawn(district, "roads", "road-square", spots[i] + Vector3(0, 0.02, 0))


static func _building_pool(kit: String) -> Array[String]:
	match kit:
		"industrial":
			return ["building-a", "building-c", "building-f", "building-d"]
		"suburban":
			return ["building-type-a", "building-type-c", "building-type-e", "building-type-b"]
		_:
			return ["building-a", "building-b", "building-d", "building-e"]