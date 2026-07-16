class_name GreeneryVegetationBuilder
extends RefCounted

const SpawnDensityScript = preload("res://scripts/world/spawn_density.gd")

## Stora träd och jättestora svampar i alla gröna zoner runt stadsrutnätet.

const TREE_LARGE_SCALE := 24.0
const TREE_SMALL_SCALE := 18.0
const MUSHROOM_HEIGHT_M := 22.0
const BLOCK_M := DcZoneCatalog.BLOCK_M
const BUILDING_CLEAR_RADIUS_M := 13.0

const MUSHROOM_CAP_COLORS := [
	Color(0.82, 0.28, 0.38),
	Color(0.58, 0.32, 0.82),
	Color(0.92, 0.62, 0.22),
	Color(0.35, 0.78, 0.48),
	Color(0.95, 0.42, 0.68),
]


static func build(parent: Node3D, spawn_id: String = "satellite_right") -> Node3D:
	var root := Node3D.new()
	root.name = "Greenery"
	parent.add_child(root)

	var theme := ColonyCityTheme.for_spawn(spawn_id)
	var extent: Dictionary = DcZoneCatalog.grid_extent()

	for x in range(extent.x_min, extent.x_max + 1):
		for z in range(extent.z_min, extent.z_max + 1):
			var cell := Vector2i(x, z)
			if DcZoneCatalog.is_reserved_landmark_cell(cell):
				continue
			var spec: Dictionary = DcZoneCatalog.classify_cell(cell)
			var zone_type: String = str(spec.get("zone_type", ""))
			if not DcZoneCatalog.is_greenery_zone(zone_type):
				continue
			_populate_cell(
				root,
				cell,
				zone_type,
				str(spec.get("kit", "")),
				theme,
				spec
			)

	return root


static func _populate_cell(
	parent: Node3D,
	cell: Vector2i,
	zone_type: String,
	kit: String,
	theme: Dictionary,
	spec: Dictionary = {}
) -> void:
	if _cell_has_primary_building(cell, spec):
		return

	var density_scale := SpawnDensityScript.greenery_scale(cell)
	if density_scale <= 0.001:
		return

	var density: Dictionary = DcZoneCatalog.greenery_density(zone_type)
	var tree_count: int = _scaled_count(int(density.get("trees", 0)), density_scale)
	var mushroom_count: int = _scaled_count(int(density.get("mushrooms", 0)), density_scale)
	if tree_count <= 0 and mushroom_count <= 0:
		return

	var cell_root := Node3D.new()
	cell_root.name = "Greenery_%d_%d" % [cell.x, cell.y]
	cell_root.position = _cell_origin(cell)
	parent.add_child(cell_root)

	var edge_bias := kit != "roads"
	var spread := BLOCK_M * 0.42 if edge_bias else BLOCK_M * 0.38

	var avoid_center := _cell_has_primary_building(cell, spec) or kit != "roads"
	for i in range(tree_count):
		var offset := _scatter_offset(cell, i, spread, edge_bias, avoid_center)
		var use_large: bool = int(hash(Vector3i(cell.x, cell.y, i * 17)) % 100) > 28
		var tree_scale := TREE_LARGE_SCALE if use_large else TREE_SMALL_SCALE
		var model := "tree-large" if use_large else "tree-small"
		var rotation_y := float(hash(Vector3i(cell.x, cell.y, i * 31)) % 628) / 100.0
		CityKitLibrary.spawn(
			cell_root,
			"suburban",
			model,
			offset,
			rotation_y,
			tree_scale
		)

	for i in range(mushroom_count):
		var offset := _scatter_offset(cell, i + 900, spread * 0.92, edge_bias, avoid_center)
		var palette_index: int = int(hash(Vector3i(cell.x, cell.y, i * 53)) % MUSHROOM_CAP_COLORS.size())
		var cap_color := _tinted_cap_color(palette_index, theme)
		_build_giant_mushroom(cell_root, offset, cap_color, i, cell)


static func _build_giant_mushroom(
	parent: Node3D,
	pos: Vector3,
	cap_color: Color,
	index: int,
	cell: Vector2i
) -> Node3D:
	var mushroom := Node3D.new()
	mushroom.name = "GiantMushroom_%d_%d_%d" % [cell.x, cell.y, index]
	mushroom.position = pos
	mushroom.rotation.y = float(hash(Vector3i(cell.x, cell.y, index * 71)) % 628) / 100.0
	parent.add_child(mushroom)

	var height_var := 0.88 + float(hash(Vector3i(cell.x, cell.y, index * 19)) % 24) / 100.0
	var height := MUSHROOM_HEIGHT_M * height_var
	var stem_radius := height * 0.055
	var cap_radius := height * 0.34

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = stem_radius * 0.82
	stem_mesh.bottom_radius = stem_radius
	stem_mesh.height = height * 0.58
	stem.mesh = stem_mesh
	stem.position = Vector3(0.0, stem_mesh.height * 0.5, 0.0)
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.92, 0.9, 0.82)
	stem_mat.roughness = 0.88
	stem.material_override = stem_mat
	mushroom.add_child(stem)

	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = cap_radius
	cap_mesh.height = cap_radius * 1.15
	cap.mesh = cap_mesh
	cap.position = Vector3(0.0, height * 0.72, 0.0)
	cap.scale = Vector3(1.15, 0.55, 1.15)
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = cap_color
	cap_mat.roughness = 0.72
	cap_mat.emission_enabled = true
	cap_mat.emission = cap_color * 0.35
	cap_mat.emission_energy_multiplier = 0.28
	cap.material_override = cap_mat
	mushroom.add_child(cap)

	for spot_index in range(4):
		var spot := MeshInstance3D.new()
		var spot_mesh := SphereMesh.new()
		spot_mesh.radius = cap_radius * 0.11
		spot_mesh.height = spot_mesh.radius * 2.0
		spot.mesh = spot_mesh
		var angle := float(spot_index) * TAU * 0.25 + float(index) * 0.6
		spot.position = Vector3(
			cos(angle) * cap_radius * 0.45,
			height * 0.78,
			sin(angle) * cap_radius * 0.45
		)
		var spot_mat := StandardMaterial3D.new()
		spot_mat.albedo_color = Color(0.98, 0.95, 0.72)
		spot_mat.emission_enabled = true
		spot_mat.emission = Color(0.98, 0.92, 0.55)
		spot_mat.emission_energy_multiplier = 0.65
		spot.material_override = spot_mat
		mushroom.add_child(spot)

	return mushroom


static func _scatter_offset(
	cell: Vector2i,
	index: int,
	spread: float,
	edge_bias: bool,
	avoid_center: bool = false
) -> Vector3:
	var hx := float(hash(Vector3i(cell.x, cell.y, index * 13)) % 10000) / 10000.0
	var hz := float(hash(Vector3i(cell.x, cell.y, index * 29)) % 10000) / 10000.0
	var x := (hx - 0.5) * spread * 2.0
	var z := (hz - 0.5) * spread * 2.0

	var center := Vector3(BLOCK_M * 0.5, 0.0, BLOCK_M * 0.5)
	var pos := center + Vector3(x, 0.0, z)
	if edge_bias or avoid_center:
		var to_edge := pos - center
		var min_radius := BLOCK_M * 0.22
		if avoid_center:
			min_radius = maxf(min_radius, BUILDING_CLEAR_RADIUS_M)
		if to_edge.length() < min_radius:
			if to_edge.length() < 0.1:
				var angle := float(hash(Vector3i(cell.x, cell.y, index * 37)) % 628) / 100.0
				to_edge = Vector3(cos(angle), 0.0, sin(angle))
			to_edge = to_edge.normalized() * min_radius
			pos = center + to_edge
		return pos

	return Vector3(BLOCK_M * 0.5 + x, 0.0, BLOCK_M * 0.5 + z)


static func _scaled_count(base_count: int, scale: float) -> int:
	if base_count <= 0 or scale <= 0.001:
		return 0
	if scale >= 0.95:
		return base_count
	return clampi(int(floor(float(base_count) * scale + 0.2)), 0, base_count)


static func _cell_has_primary_building(cell: Vector2i, spec: Dictionary) -> bool:
	if spec.is_empty():
		spec = DcZoneCatalog.classify_cell(cell)
	var kit := str(spec.get("kit", ""))
	if kit == "roads" or kit == "space":
		return false
	return SpawnDensityScript.should_place_building(cell)


static func scatter_cell_accent(parent: Node3D, center: Vector3, cell: Vector2i) -> void:
	if not SpawnDensityScript.should_scatter_cell_accent(cell):
		return
	var accent_seed: int = int(hash(Vector3i(cell.x, cell.y, 19)))
	var tree_count: int = 1 if (accent_seed & 1) == 1 else 0
	for i in range(tree_count):
		var offset := _scatter_offset(cell, i + 300, BLOCK_M * 0.34, true, true)
		CityKitLibrary.spawn(
			parent,
			"suburban",
			"tree-small",
			offset,
			float(hash(Vector3i(cell.x, cell.y, i * 11)) % 628) / 100.0,
			TREE_SMALL_SCALE * 0.82
		)


static func scatter_in_radius(
	parent: Node3D,
	center: Vector3,
	radius_m: float,
	tree_count: int = 6,
	mushroom_count: int = 4,
	spawn_id: String = "satellite_right"
) -> void:
	var theme := ColonyCityTheme.for_spawn(spawn_id)
	var patch := Node3D.new()
	patch.name = "GreeneryPatch"
	patch.position = center
	parent.add_child(patch)

	for i in range(tree_count):
		var angle := float(i) / maxf(float(tree_count), 1.0) * TAU + 0.4
		var dist := radius_m * (0.35 + float(hash(i * 97) % 55) / 100.0)
		var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var use_large: bool = int(hash(i * 41) % 100) > 35
		CityKitLibrary.spawn(
			patch,
			"suburban",
			"tree-large" if use_large else "tree-small",
			offset,
			angle + PI * 0.5,
			TREE_LARGE_SCALE if use_large else TREE_SMALL_SCALE
		)

	for i in range(mushroom_count):
		var angle := float(i) / maxf(float(mushroom_count), 1.0) * TAU + 1.2
		var dist := radius_m * (0.42 + float(hash(i * 63) % 48) / 100.0)
		var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		_build_giant_mushroom(
			patch,
			offset,
			_tinted_cap_color(i, theme),
			i,
			Vector2i(int(center.x), int(center.z))
		)


static func _tinted_cap_color(index: int, theme: Dictionary) -> Color:
	var palette: Color = MUSHROOM_CAP_COLORS[index % MUSHROOM_CAP_COLORS.size()]
	var zone_tint: Color = theme.get("zone_tint", Color.WHITE)
	return (palette * zone_tint).clamp()


static func _cell_origin(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * BLOCK_M, 0.0, float(cell.y) * BLOCK_M)