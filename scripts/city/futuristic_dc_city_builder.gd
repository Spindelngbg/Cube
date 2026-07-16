class_name FuturisticDcCityBuilder
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")
const ZezzlorCheckpointBuilderScript = preload("res://scripts/access/zezzlor_checkpoint_builder.gd")
const PharmacyBuilderScript = preload("res://scripts/shops/pharmacy_builder.gd")
const WeaponShopBuilderScript = preload("res://scripts/shops/weapon_shop_builder.gd")

const AVENUE_NAMES := {
	0: "Nationalmallen",
	2: "Constitution Ave",
	-2: "Independence Ave",
}
const STREET_PREFIX := "Neo-Washington"
const STREET_LAMP_SIDE_OFFSET := 3.25


static func build(parent: Node3D, spawn_pos: Vector3, spawn_id: String = "satellite_right") -> Node3D:
	DevBuildingLabelsScript.reset()
	var root := Node3D.new()
	root.name = "NeoWashington"
	root.position = spawn_pos
	parent.add_child(root)

	var theme := ColonyCityTheme.for_spawn(spawn_id)
	_build_city_plate(root)
	_build_street_grid(root, theme)
	_build_mall_axis(root)
	_build_zoned_blocks(root)
	_build_landmarks(root)
	GreeneryVegetationBuilder.build(root, spawn_id)
	_build_pharmacy_near_spawn(root)
	_build_weapon_shop_near_spawn(root)
	_build_story_sites(root)
	_build_zezzlor_checkpoints(root)
	_place_city_sign(root)

	return root


static func _build_city_plate(root: Node3D) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var width: float = float(extent.x_max - extent.x_min + 1) * DcZoneCatalog.BLOCK_M
	var depth: float = float(extent.z_max - extent.z_min + 1) * DcZoneCatalog.BLOCK_M
	var origin: Vector3 = _cell_origin(Vector2i(extent.x_min, extent.z_min))

	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width + 80.0, 0.35, depth + 80.0)
	plate.mesh = mesh
	plate.position = origin + Vector3(width * 0.5 - DcZoneCatalog.BLOCK_M * 0.5, -0.18, depth * 0.5 - DcZoneCatalog.BLOCK_M * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.11, 0.14)
	mat.metallic = 0.25
	mat.roughness = 0.82
	plate.material_override = mat
	root.add_child(plate)


static func _build_street_grid(root: Node3D, theme: Dictionary) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var roads := Node3D.new()
	roads.name = "StreetGrid"
	root.add_child(roads)

	for z in range(extent.z_min, extent.z_max + 2):
		var lane_z: float = float(z) * DcZoneCatalog.BLOCK_M
		var avenue: String = str(AVENUE_NAMES.get(z, "Avenue Z%d" % abs(z)))
		_spawn_road_strip(
			roads,
			Vector3(_grid_center_x(), 0.03, lane_z),
			0.0,
			_grid_width_m(),
			avenue,
			theme
		)

	for x in range(extent.x_min, extent.x_max + 2):
		var lane_x: float = float(x) * DcZoneCatalog.BLOCK_M
		_spawn_road_strip(
			roads,
			Vector3(lane_x, 0.03, _grid_center_z()),
			PI * 0.5,
			_grid_depth_m(),
			"%s Gata %d" % [STREET_PREFIX, x - extent.x_min + 1],
			theme
		)


static func _build_mall_axis(root: Node3D) -> void:
	var mall := Node3D.new()
	mall.name = "NationalMall"
	root.add_child(mall)

	for cell in DcZoneCatalog.mall_cells():
		var base := _cell_origin(cell)
		for patch_x in range(-1, 2):
			for patch_z in range(-2, 3):
				var pos := base + Vector3(
					DcZoneCatalog.BLOCK_M * 0.5 + patch_x * 6.0,
					0.04,
					DcZoneCatalog.BLOCK_M * 0.5 + patch_z * 6.0
				)
				CityKitLibrary.spawn(mall, "roads", "tile-low", pos)
		_add_zone_marker(
			mall,
			base + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5),
			DcZoneCatalog.classify_cell(cell),
			false
		)

	var obelisk_pos := _cell_origin(Vector2i(-3, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	_build_obelisk(mall, obelisk_pos)


static func _build_zoned_blocks(root: Node3D) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var zones := Node3D.new()
	zones.name = "ZonedBlocks"
	root.add_child(zones)

	for x in range(extent.x_min, extent.x_max + 1):
		for z in range(extent.z_min, extent.z_max + 1):
			var cell := Vector2i(x, z)
			if cell in DcZoneCatalog.mall_cells():
				continue
			if cell == Vector2i(-3, 0) or cell == Vector2i(0, 0) or cell == Vector2i(-6, 0):
				continue
			if cell == Vector2i(-4, -3):
				continue
			_build_zone_block(zones, cell)


static func _build_zone_block(parent: Node3D, cell: Vector2i) -> void:
	var spec: Dictionary = DcZoneCatalog.classify_cell(cell)
	var zone_root := Node3D.new()
	zone_root.name = "Zone_%d_%d" % [cell.x, cell.y]
	zone_root.position = _cell_origin(cell)
	parent.add_child(zone_root)

	var center: Vector3 = Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	var kit: String = str(spec.get("kit", "commercial"))
	var model: String = str(spec.get("model", "building-a"))

	if kit == "roads":
		CityKitLibrary.spawn(zone_root, kit, model, center + Vector3(0.0, 0.02, 0.0))
		_add_park_lights(zone_root, center, ColonyCityTheme.for_spawn("satellite_right"))
	elif kit == "space":
		SpaceKitLibrary.spawn(zone_root, model, center)
	else:
		CityKitLibrary.spawn(zone_root, kit, model, center, float((cell.x + cell.y) % 4) * PI * 0.5)
		CityKitLibrary.spawn(zone_root, "roads", "road-square", center + Vector3(0.0, 0.02, 0.0))

	_add_zone_marker(zone_root, center, spec, true)


static func _build_pharmacy_near_spawn(root: Node3D) -> void:
	var spawn_center := _cell_origin(Vector2i(0, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	var pharmacy_pos := spawn_center + Vector3(14.0, 0.0, -16.0)
	PharmacyBuilderScript.build(root, pharmacy_pos)

	var arrow := Label3D.new()
	arrow.text = "PHARMACY →\nPill-Bot har antidot"
	arrow.font_size = 32
	arrow.modulate = Color(0.45, 0.92, 0.68)
	arrow.outline_modulate = Color(0.06, 0.12, 0.1, 0.95)
	arrow.position = spawn_center + Vector3(6.0, 2.5, -4.0)
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(arrow)


static func _build_weapon_shop_near_spawn(root: Node3D) -> void:
	var spawn_center := _cell_origin(Vector2i(0, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	var weapon_pos := spawn_center + Vector3(-18.0, 0.0, -14.0)
	WeaponShopBuilderScript.build(root, weapon_pos, "weapon_shop_dc")


static func _build_landmarks(root: Node3D) -> void:
	_build_capitol(root, _cell_origin(Vector2i(0, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5))
	_build_memorial_west(
		root,
		_cell_origin(Vector2i(-6, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	)
	_build_white_house(
		root,
		_cell_origin(Vector2i(-2, 3)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	)


static func _build_zezzlor_checkpoints(root: Node3D) -> void:
	ZezzlorCheckpointBuilderScript.place_all(root)


static func _build_story_sites(root: Node3D) -> void:
	var annex_origin := _cell_origin(Vector2i(-4, -3))
	StoryWorldBuilder.build_annex_at(root, annex_origin + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5))
	StoryWorldBuilder.build_hybrid_towers(root, _cell_origin(Vector2i(-1, 2)), _cell_origin(Vector2i(-5, 1)))
	StoryWorldBuilder.place_warning_sign(root, Vector3(-20.0, 0.0, -55.0))


static func _build_capitol(parent: Node3D, pos: Vector3) -> void:
	var capitol := Node3D.new()
	capitol.name = "FuturisticCapitol"
	capitol.position = pos
	parent.add_child(capitol)

	SpaceKitLibrary.spawn(capitol, "template-floor-detail-a", Vector3(0, 0, 0))
	SpaceKitLibrary.spawn(capitol, "room-large", Vector3(0, 0, 0))
	SpaceKitLibrary.spawn(capitol, "room-large-variation", Vector3(0, 0, 6), PI)
	for i in range(4):
		SpaceKitLibrary.spawn(capitol, "template-wall-detail-a", Vector3(-8 + i * 5.0, 0, -8), 0.0)

	var dome := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 5.5
	mesh.height = 7.0
	dome.mesh = mesh
	dome.position = Vector3(0.0, 8.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.9, 0.95)
	mat.metallic = 0.65
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.62, 0.95)
	mat.emission_energy_multiplier = 0.35
	dome.material_override = mat
	capitol.add_child(dome)

	_add_zone_marker(capitol, Vector3(0, 0, 0), DcZoneCatalog.classify_cell(Vector2i(0, 0)), true)


static func _build_obelisk(parent: Node3D, pos: Vector3) -> void:
	var spire := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.8
	mesh.bottom_radius = 2.2
	mesh.height = 42.0
	spire.mesh = mesh
	spire.position = pos + Vector3(0.0, 21.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.82, 0.9)
	mat.metallic = 0.55
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.72, 1.0)
	mat.emission_energy_multiplier = 0.45
	spire.material_override = mat
	parent.add_child(spire)

	var label := Label3D.new()
	label.text = str(DcZoneCatalog.classify_cell(Vector2i(-3, 0)).get("tag", ""))
	label.font_size = 40
	label.modulate = DcZoneCatalog.zone_color("MONUMENTKÄRNA")
	label.position = pos + Vector3(0.0, 46.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _build_memorial_west(parent: Node3D, pos: Vector3) -> void:
	var memorial := Node3D.new()
	memorial.name = "MemorialWest"
	memorial.position = pos
	parent.add_child(memorial)

	for i in range(6):
		SpaceKitLibrary.spawn(memorial, "template-wall", Vector3(-10 + i * 4.0, 0, 0), PI * 0.5)
	SpaceKitLibrary.spawn(memorial, "template-floor-big", Vector3(0, 0, 0))
	CityKitLibrary.spawn(memorial, "commercial", "building-d", Vector3(0, 0, 8), PI)

	_add_zone_marker(memorial, Vector3(0, 0, 0), DcZoneCatalog.classify_cell(Vector2i(-6, 0)), true)


static func _build_white_house(parent: Node3D, pos: Vector3) -> void:
	var executive := Node3D.new()
	executive.name = "ExecutiveMansion"
	executive.position = pos
	parent.add_child(executive)

	CityKitLibrary.spawn(executive, "suburban", "building-type-e", Vector3(0, 0, 0))
	SpaceKitLibrary.spawn(executive, "gate-door-window", Vector3(0, 0, 6))
	_add_zone_marker(executive, Vector3(0, 0, 0), DcZoneCatalog.classify_cell(Vector2i(-2, 3)), true)


static func _place_city_sign(root: Node3D) -> void:
	var sign := Label3D.new()
	sign.text = (
		"NEO-WASHINGTON — KOLONI 4\n"
		+ "Futuristisk layout efter USA:s huvudstad\n"
		+ "Kapitol öster → Nationalmallen väster\n"
		+ "Varje block har zontag"
	)
	sign.font_size = 52
	sign.modulate = Color(0.55, 0.82, 1.0)
	sign.position = Vector3(0.0, 10.0, -30.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(sign)


static func _add_zone_marker(parent: Node3D, center: Vector3, spec: Dictionary, with_pad: bool) -> void:
	var zone_type: String = str(spec.get("zone_type", "ZON"))
	var tag: String = str(spec.get("tag", zone_type))
	var color: Color = DcZoneCatalog.zone_color(zone_type)

	if with_pad:
		var pad := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(DcZoneCatalog.BLOCK_M - 4.0, 0.08, DcZoneCatalog.BLOCK_M - 4.0)
		pad.mesh = mesh
		pad.position = center + Vector3(0.0, 0.05, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.22)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.12
		pad.material_override = mat
		parent.add_child(pad)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.18, 2.6, 0.18)
	post.mesh = post_mesh
	post.position = center + Vector3(-DcZoneCatalog.BLOCK_M * 0.5 + 3.0, 1.3, -DcZoneCatalog.BLOCK_M * 0.5 + 3.0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = color
	post_mat.emission_enabled = true
	post_mat.emission = color
	post_mat.emission_energy_multiplier = 0.4
	post.material_override = post_mat
	parent.add_child(post)

	var label := Label3D.new()
	label.text = tag
	label.font_size = 28
	label.modulate = color
	label.outline_modulate = Color(0.04, 0.05, 0.08, 0.95)
	label.position = post.position + Vector3(0.0, 1.8, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _add_park_lights(parent: Node3D, center: Vector3, theme: Dictionary) -> void:
	var park_color: Color = theme.get("park_light", Color(0.72, 0.82, 1.0))
	var accent: Color = theme.get("surveillance_accent", Color(0.95, 0.18, 0.12))
	for offset in [Vector3(-12, 0, -12), Vector3(12, 0, 12), Vector3(-12, 0, 12), Vector3(12, 0, -12)]:
		var pole_pos: Vector3 = center + (offset as Vector3)
		_add_light_pole(parent, pole_pos, park_color, 5.2, 0.95, 11.0)
		var scan := SpotLight3D.new()
		scan.position = pole_pos + Vector3(0.0, 6.8, 0.0)
		scan.rotation_degrees = Vector3(-88, 0, 0)
		scan.light_color = accent
		scan.light_energy = 0.42
		scan.spot_range = 18.0
		scan.spot_angle = 14.0
		scan.shadow_enabled = false
		parent.add_child(scan)


static func _add_light_pole(
	parent: Node3D,
	base: Vector3,
	color: Color,
	height: float,
	energy: float,
	range_m: float,
	tilt_toward: Vector3 = Vector3.ZERO
) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.14, height, 0.14)
	pole.mesh = pole_mesh
	pole.position = base + Vector3(0.0, height * 0.5, 0.0)
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.16, 0.18, 0.22)
	pole_mat.metallic = 0.55
	pole.material_override = pole_mat
	parent.add_child(pole)

	var head_pos := base + Vector3(0.0, height + 0.08, 0.0)
	var fixture := MeshInstance3D.new()
	var fixture_mesh := BoxMesh.new()
	fixture_mesh.size = Vector3(0.42, 0.14, 0.28)
	fixture.mesh = fixture_mesh
	fixture.position = head_pos
	var fixture_mat := StandardMaterial3D.new()
	fixture_mat.albedo_color = Color(0.2, 0.22, 0.26)
	fixture_mat.metallic = 0.62
	fixture_mat.emission_enabled = true
	fixture_mat.emission = color
	fixture_mat.emission_energy_multiplier = 0.55
	fixture.material_override = fixture_mat
	parent.add_child(fixture)

	var shade := MeshInstance3D.new()
	var shade_mesh := BoxMesh.new()
	shade_mesh.size = Vector3(0.36, 0.06, 0.34)
	shade.mesh = shade_mesh
	shade.position = head_pos + Vector3(0.0, 0.1, 0.0)
	var shade_mat := StandardMaterial3D.new()
	shade_mat.albedo_color = Color(0.12, 0.13, 0.16)
	shade_mat.metallic = 0.48
	shade.material_override = shade_mat
	parent.add_child(shade)

	var lamp := SpotLight3D.new()
	lamp.position = head_pos + Vector3(0.0, 0.04, 0.0)
	if tilt_toward.length_squared() > 0.001:
		lamp.look_at(head_pos + tilt_toward.normalized(), Vector3.UP)
	else:
		lamp.rotation_degrees = Vector3(-90, 0, 0)
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.spot_range = range_m
	lamp.spot_angle = 32.0
	lamp.shadow_enabled = false
	parent.add_child(lamp)


static func _street_lamp_side_offsets(rotation_y: float) -> Array[Vector3]:
	var along_x := absf(rotation_y) < 0.1 or absf(absf(rotation_y) - PI) < 0.1
	if along_x:
		return [
			Vector3(0.0, 0.0, STREET_LAMP_SIDE_OFFSET),
			Vector3(0.0, 0.0, -STREET_LAMP_SIDE_OFFSET),
		]
	return [
		Vector3(STREET_LAMP_SIDE_OFFSET, 0.0, 0.0),
		Vector3(-STREET_LAMP_SIDE_OFFSET, 0.0, 0.0),
	]


static func _add_street_lamp(
	parent: Node3D,
	pos: Vector3,
	theme: Dictionary,
	rotation_y: float,
	side_offset: Vector3
) -> void:
	var street_color: Color = theme.get("street_light", Color(0.82, 0.9, 1.0))
	var lamp_root := Node3D.new()
	lamp_root.position = pos
	lamp_root.rotation.y = rotation_y
	parent.add_child(lamp_root)
	_add_light_pole(
		lamp_root,
		Vector3.ZERO,
		street_color,
		4.6,
		1.05,
		13.0,
		-side_offset
	)


static func _spawn_road_strip(
	parent: Node3D,
	center: Vector3,
	rotation_y: float,
	length_m: float,
	_label: String,
	theme: Dictionary
) -> void:
	var segments := int(ceil(length_m / 4.0))
	for i in range(segments):
		var offset := (i - segments * 0.5) * 4.0
		var pos := center
		if abs(rotation_y) < 0.1:
			pos.x += offset
		else:
			pos.z += offset
		CityKitLibrary.spawn(parent, "roads", "road-straight", pos, rotation_y)
		if i % 2 == 0:
			for side_offset in _street_lamp_side_offsets(rotation_y):
				_add_street_lamp(parent, pos + side_offset, theme, rotation_y, side_offset)


static func _cell_origin(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalog.BLOCK_M,
		0.0,
		float(cell.y) * DcZoneCatalog.BLOCK_M
	)


static func _grid_center_x() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.x_min + extent.x_max) * 0.5 * DcZoneCatalog.BLOCK_M


static func _grid_center_z() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.z_min + extent.z_max) * 0.5 * DcZoneCatalog.BLOCK_M


static func _grid_width_m() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.x_max - extent.x_min + 2) * DcZoneCatalog.BLOCK_M


static func _grid_depth_m() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.z_max - extent.z_min + 2) * DcZoneCatalog.BLOCK_M