class_name SatelliteCubeBuilder
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")
const ZnoodDoorBuilderScript = preload("res://scripts/access/znood_door_builder.gd")
const ItemPickupScript = preload("res://scripts/items/item_pickup.gd")
const PharmacyBuilderScript = preload("res://scripts/shops/pharmacy_builder.gd")
const WeaponShopBuilderScript = preload("res://scripts/shops/weapon_shop_builder.gd")
const PurpleLaserTowerBuilderScript = preload("res://scripts/city/purple_laser_tower_builder.gd")
const SpawnDensityScript = preload("res://scripts/world/spawn_density.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const ARRIVAL_HUB_RADIUS_M := 140.0
const WALL_THICKNESS_M := 80.0
const FLOOR_THICKNESS_M := 2.0
const SPAWN_PAD_SIZE := Vector3(14.0, 1.0, 14.0)


static func build(parent: Node3D, spawn_id: String) -> Node3D:
	DevBuildingLabelsScript.reset()
	var id := SpawnPoints.normalize_id(spawn_id)
	if id == "":
		id = "satellite_left"

	var entry := SpawnPoints.get_entry(id)
	var size_m := SpawnPoints.get_extent_m()
	var root := Node3D.new()
	root.name = "Satellite_%s" % id
	parent.add_child(root)

	_build_cube_volume(root, size_m, id)
	_build_arrival_hub(root, entry, id)
	if id == "satellite_right":
		StoryWorldBuilder.build(root, id)
	_mount_elevator_shaft(root, size_m, id)
	_build_play_spawn_pad(root, id)

	var spawn_pos := SpawnPoints.get_position(id)
	var theme := ColonyCityTheme.for_spawn(id)
	var beacon_color: Color = theme.get("beacon_color", Color(0.9, 0.55, 0.25))
	var beacon := OmniLight3D.new()
	beacon.position = spawn_pos + Vector3(0.0, 12.0, 0.0)
	beacon.light_color = beacon_color
	beacon.light_energy = 1.65 if id == "satellite_right" else 1.4
	beacon.omni_range = 48.0 if id == "satellite_right" else 90.0
	root.add_child(beacon)

	if id == "satellite_right":
		var scan := SpotLight3D.new()
		scan.position = spawn_pos + Vector3(0.0, 22.0, 0.0)
		scan.rotation_degrees = Vector3(-90, 0, 0)
		scan.light_color = theme.get("street_light", Color(0.82, 0.9, 1.0))
		scan.light_energy = 1.35
		scan.spot_range = 36.0
		scan.spot_angle = 48.0
		scan.shadow_enabled = false
		root.add_child(scan)

	var label := Label3D.new()
	var extra := ""
	if id == "satellite_right":
		extra = "\nNeo-Washington — futuristisk huvudstads-layout"
	label.text = (
		"%s\n%s%s\nEnda vägen: hiss till huvudkuben"
		% [SpawnPoints.get_colony_label(id), SpawnPoints.get_extent_label(), extra]
	)
	label.font_size = 72
	label.modulate = Color(0.72, 0.8, 0.95) if id == "satellite_right" else Color(0.95, 0.88, 0.72)
	if id == "satellite_right":
		label.position = spawn_pos + Vector3(20.0, 14.0, 12.0)
	else:
		label.position = spawn_pos + Vector3(0.0, 8.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	var shift := SpawnPoints.get_world_origin_shift(id)
	root.position = Vector3(-shift.x, 0.0, -shift.z)

	return root


static func _build_cube_volume(root: Node3D, size_m: float, spawn_id: String) -> void:
	var half := size_m * 0.5
	var shell := StaticBody3D.new()
	shell.name = "CubeVolume"
	shell.collision_layer = 1
	shell.collision_mask = 0
	root.add_child(shell)

	var floor_mat := _surface_material(Color(0.14, 0.15, 0.18))
	var wall_mat := _surface_material(Color(0.1, 0.11, 0.14))
	var ceiling_mat := _surface_material(Color(0.08, 0.09, 0.12))

	_add_box(shell, Vector3(size_m, FLOOR_THICKNESS_M, size_m), Vector3(half, -FLOOR_THICKNESS_M * 0.5, half), floor_mat)
	_add_box(shell, Vector3(size_m, WALL_THICKNESS_M, WALL_THICKNESS_M), Vector3(half, half, WALL_THICKNESS_M * 0.5), wall_mat)
	_add_box(shell, Vector3(size_m, WALL_THICKNESS_M, WALL_THICKNESS_M), Vector3(half, half, size_m - WALL_THICKNESS_M * 0.5), wall_mat)
	_add_box(shell, Vector3(WALL_THICKNESS_M, WALL_THICKNESS_M, size_m), Vector3(WALL_THICKNESS_M * 0.5, half, half), wall_mat)
	_add_box(shell, Vector3(WALL_THICKNESS_M, WALL_THICKNESS_M, size_m), Vector3(size_m - WALL_THICKNESS_M * 0.5, half, half), wall_mat)
	_add_box(shell, Vector3(size_m, WALL_THICKNESS_M, size_m), Vector3(half, size_m - WALL_THICKNESS_M * 0.5, half), ceiling_mat)

	var markers := Node3D.new()
	markers.name = "CornerMarkers"
	root.add_child(markers)
	var corner_offsets := [
		Vector3(0.0, 0.0, 0.0),
		Vector3(size_m, 0.0, 0.0),
		Vector3(0.0, 0.0, size_m),
		Vector3(size_m, 0.0, size_m),
	]
	for offset in corner_offsets:
		_add_beacon_pillar(markers, offset + Vector3(0.0, 0.0, 0.0), size_m, spawn_id)


static func _build_arrival_hub(root: Node3D, entry: Dictionary, spawn_id: String) -> void:
	var spawn_pos := SpawnPoints.get_position(spawn_id)
	var hub := Node3D.new()
	hub.name = "ArrivalHub"
	hub.position = spawn_pos
	root.add_child(hub)

	var platform := Node3D.new()
	platform.name = "ArrivalPlatform"
	hub.add_child(platform)
	# Öppen spawn-yta i centrum — solid rum flyttat så spelaren inte fastnar i geometri.
	SpaceKitLibrary.spawn(platform, "template-floor-detail-a", Vector3(0, 0, 0))
	SpaceKitLibrary.spawn(platform, "room-small", Vector3(18.0, 0.0, -14.0))
	# Golvkollision hanteras av PlaySpawnPad (samma centrum) — undvik dubbla plattor.
	_add_arrival_pickup(platform, Vector3(-3.0, 0.0, -2.0))

	if spawn_id != "satellite_right":
		_build_district(hub, ARRIVAL_HUB_RADIUS_M, str(entry.get("kit", "commercial")))
		PharmacyBuilderScript.build(hub, Vector3(22.0, 0.0, -18.0))
		WeaponShopBuilderScript.build(hub, Vector3(-24.0, 0.0, -20.0), "weapon_shop_%s" % spawn_id)
		PurpleLaserTowerBuilderScript.build(hub, Vector3(28.0, 0.0, 14.0), spawn_id)


static func _build_district(parent: Node3D, radius_m: float, kit: String) -> void:
	var district := Node3D.new()
	district.name = "District"
	parent.add_child(district)

	var buildings := _building_pool(kit)
	var spots := [
		Vector3(-radius_m * 0.35, 0, -radius_m * 0.35),
		Vector3(radius_m * 0.3, 0, -radius_m * 0.25),
		Vector3(-radius_m * 0.2, 0, radius_m * 0.35),
		Vector3(radius_m * 0.35, 0, radius_m * 0.3),
	]
	for i in range(spots.size()):
		if not SpawnDensityScript.should_place_hub_building(spots[i], Vector3.ZERO, i):
			CityKitLibrary.spawn(district, "roads", "tile-low", spots[i] + Vector3(0, 0.02, 0))
			continue
		var model := buildings[i % buildings.size()]
		CityKitLibrary.spawn(district, kit, model, spots[i], float(i) * PI * 0.5)
		CityKitLibrary.spawn(district, "roads", "road-square", spots[i] + Vector3(0, 0.02, 0))


static func _mount_elevator_shaft(root: Node3D, size_m: float, spawn_id: String) -> void:
	var entry := SpawnPoints.get_entry(spawn_id)
	var mount := str(entry.get("elevator_mount", "left"))
	var shaft := Node3D.new()
	shaft.name = "ElevatorShaft"
	root.add_child(shaft)

	match mount:
		"left":
			SpaceKitLibrary.spawn(shaft, "corridor-wide", Vector3(80.0, 0, size_m * 0.5), PI * 0.5)
			SpaceKitLibrary.spawn(shaft, "gate-door-window", Vector3(40.0, 0, size_m * 0.5), PI * 0.5)
			_place_elevator_znood_door(
				shaft,
				Vector3(40.0, 0.0, size_m * 0.5 - 4.0),
				Vector3(2.6, 2.6, 0.35),
				spawn_id,
				PI * 0.5
			)
		"right":
			SpaceKitLibrary.spawn(shaft, "corridor-wide", Vector3(size_m - 80.0, 0, size_m * 0.5), -PI * 0.5)
			SpaceKitLibrary.spawn(shaft, "gate-door-window", Vector3(size_m - 40.0, 0, size_m * 0.5), -PI * 0.5)
			_place_elevator_znood_door(
				shaft,
				Vector3(size_m - 40.0, 0.0, size_m * 0.5 - 4.0),
				Vector3(2.6, 2.6, 0.35),
				spawn_id,
				-PI * 0.5
			)
		"top":
			var index := int(entry.get("elevator_index", 0))
			var lane_x := size_m * (0.333 if index == 0 else 0.667)
			SpaceKitLibrary.spawn(shaft, "stairs-wide", Vector3(lane_x, 0, 80.0))
			SpaceKitLibrary.spawn(shaft, "gate-door-window", Vector3(lane_x, 0, 40.0), PI)
			_place_elevator_znood_door(
				shaft,
				Vector3(lane_x, 0.0, 36.0),
				Vector3(2.6, 2.6, 0.35),
				spawn_id,
				PI
			)


static func _add_arrival_pickup(parent: Node3D, pos: Vector3) -> void:
	var pickup: ItemPickup = ItemPickupScript.new()
	pickup.item_id = "chitin_patch"
	pickup.prompt_text = "Plocka upp Kitinplåster [E]"
	pickup.position = pos
	parent.add_child(pickup)


static func _place_elevator_znood_door(
	shaft: Node3D,
	pos: Vector3,
	size: Vector3,
	spawn_id: String,
	rotation_y: float
) -> void:
	ZnoodDoorBuilderScript.place(
		shaft,
		pos,
		size,
		"elevator_%s" % SpawnPoints.normalize_id(spawn_id),
		rotation_y,
		"Stämpla Znood vid hiss [E]"
	)


static func _add_box(body: StaticBody3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.position = pos
	mesh_node.material_override = mat
	body.add_child(mesh_node)

	var shape_node := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape_node.shape = col
	shape_node.position = pos
	body.add_child(shape_node)


static func _surface_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.metallic = 0.05
	return mat


static func _build_play_spawn_pad(root: Node3D, spawn_id: String) -> void:
	var play := SpawnPoints.get_play_spawn_position(spawn_id)
	var pad := StaticBody3D.new()
	pad.name = "PlaySpawnPad"
	pad.position = Vector3(play.x, 0.0, play.z)
	pad.collision_layer = WorldCollisionBuilderScript.WORLD_COLLISION_LAYER
	pad.collision_mask = 0
	root.add_child(pad)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SPAWN_PAD_SIZE
	shape.shape = box
	shape.position = Vector3(
		0.0,
		SpawnPoints.SPAWN_PAD_SURFACE_Y - SPAWN_PAD_SIZE.y * 0.5,
		0.0
	)
	pad.add_child(shape)

	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(SPAWN_PAD_SIZE.x - 1.0, 0.16, SPAWN_PAD_SIZE.z - 1.0)
	mesh_node.mesh = mesh
	mesh_node.position = Vector3(0.0, SpawnPoints.SPAWN_PAD_SURFACE_Y - 0.08, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.78, 0.42, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.15
	mat.roughness = 0.72
	mesh_node.material_override = mat
	pad.add_child(mesh_node)


static func _add_beacon_pillar(parent: Node3D, base: Vector3, size_m: float, spawn_id: String) -> void:
	var theme := ColonyCityTheme.for_spawn(spawn_id)
	var beacon_color: Color = theme.get("beacon_color", Color(0.9, 0.25, 0.18))
	var pillar := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 25.0
	mesh.bottom_radius = 25.0
	mesh.height = minf(size_m * 0.02, 600.0)
	pillar.mesh = mesh
	pillar.position = base + Vector3(0.0, mesh.height * 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = beacon_color.darkened(0.35)
	mat.emission_enabled = true
	mat.emission = beacon_color
	mat.emission_energy_multiplier = 0.48 if spawn_id == "satellite_right" else 0.35
	pillar.material_override = mat
	parent.add_child(pillar)


static func _building_pool(kit: String) -> Array[String]:
	match kit:
		"industrial":
			return ["building-a", "building-c", "building-f", "building-d"]
		"suburban":
			return ["building-type-a", "building-type-c", "building-type-e", "building-type-b"]
		_:
			return ["building-a", "building-b", "building-d", "building-e"]
