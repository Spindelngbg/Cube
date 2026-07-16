class_name SrcHqBuilder
extends RefCounted

const Lore = preload("res://scripts/story/shawshank_lore.gd")

const WHITE := Color(0.97, 0.96, 0.94)
const WHITE_COOL := Color(0.93, 0.95, 0.98)
const SAND := Color(0.90, 0.82, 0.68)
const SAND_LIGHT := Color(0.96, 0.91, 0.80)
const GLASS := Color(0.68, 0.86, 0.98)
const ACCENT_GOLD := Color(0.86, 0.76, 0.58)

const FOOTPRINT_X := 92.0
const FOOTPRINT_Z := 78.0
const MAIN_HEIGHT := 42.0
const WING_HEIGHT := 28.0
const PLAZA_PAD := 18.0
const KIT_SCALE := 22.0


static func build_shell(parent: Node3D, pos: Vector3) -> Node3D:
	var hq := Node3D.new()
	hq.name = "SRC_HQ"
	hq.position = pos
	parent.add_child(hq)

	_build_plaza(hq)
	_build_main_monolith(hq)
	_build_wings(hq)
	_build_atrium_spire(hq)
	_build_glass_curtain(hq)
	_build_skyline_accents(hq)
	_build_roof_details(hq)
	_add_hq_lighting(hq)
	_build_collision(hq)

	var spec: Dictionary = DcZoneCatalog.classify_cell(Vector2i(-4, -3))
	FuturisticDcCityBuilder._add_zone_marker(hq, Vector3.ZERO, spec, true)

	return hq


static func entrance_position() -> Vector3:
	return Vector3(0.0, 0.0, -FOOTPRINT_Z * 0.5 + 2.0)


static func lobby_center() -> Vector3:
	return Vector3(0.0, 0.0, -10.0)


static func hq_sign_position() -> Vector3:
	return Vector3(0.0, MAIN_HEIGHT + 14.0, -FOOTPRINT_Z * 0.22)


static func _build_plaza(parent: Node3D) -> void:
	var pad_x := FOOTPRINT_X + PLAZA_PAD * 2.0
	var pad_z := FOOTPRINT_Z + PLAZA_PAD * 2.0

	var plaza := MeshInstance3D.new()
	plaza.name = "SandPlaza"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(pad_x, 0.42, pad_z)
	plaza.mesh = mesh
	plaza.position = Vector3(0.0, 0.18, 0.0)
	plaza.material_override = _sand_mat()
	parent.add_child(plaza)

	var trim := MeshInstance3D.new()
	trim.name = "PlazaTrim"
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(pad_x - 6.0, 0.12, pad_z - 6.0)
	trim.mesh = trim_mesh
	trim.position = Vector3(0.0, 0.46, 0.0)
	trim.material_override = _sand_light_mat()
	parent.add_child(trim)

	for offset in [
		Vector3(-pad_x * 0.38, 0.5, -pad_z * 0.38),
		Vector3(pad_x * 0.38, 0.5, -pad_z * 0.38),
		Vector3(-pad_x * 0.38, 0.5, pad_z * 0.32),
		Vector3(pad_x * 0.38, 0.5, pad_z * 0.32),
	]:
		_add_box(parent, Vector3(4.5, 0.35, 4.5), offset, _sand_light_mat())


static func _build_main_monolith(parent: Node3D) -> void:
	_add_box(
		parent,
		Vector3(FOOTPRINT_X, MAIN_HEIGHT, FOOTPRINT_Z),
		Vector3(0.0, MAIN_HEIGHT * 0.5 + 0.42, 0.0),
		_white_mat()
	)

	var setback := MeshInstance3D.new()
	setback.name = "UpperSetback"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(FOOTPRINT_X * 0.72, 12.0, FOOTPRINT_Z * 0.62)
	setback.mesh = mesh
	setback.position = Vector3(0.0, MAIN_HEIGHT + 6.6, -4.0)
	setback.material_override = _white_cool_mat()
	parent.add_child(setback)


static func _build_wings(parent: Node3D) -> void:
	var wing_x := FOOTPRINT_X * 0.34
	var wing_z := FOOTPRINT_Z * 0.42
	for side in [-1.0, 1.0]:
		_add_box(
			parent,
			Vector3(wing_x, WING_HEIGHT, wing_z),
			Vector3(side * (FOOTPRINT_X * 0.5 + wing_x * 0.18), WING_HEIGHT * 0.5 + 0.42, 8.0),
			_white_cool_mat()
		)
		_add_glass_panel(
			parent,
			Vector3(wing_x * 0.82, WING_HEIGHT * 0.55, 0.18),
			Vector3(side * (FOOTPRINT_X * 0.5 + wing_x * 0.18), WING_HEIGHT * 0.55, -wing_z * 0.5 + 8.0)
		)


static func _build_atrium_spire(parent: Node3D) -> void:
	var spire := MeshInstance3D.new()
	spire.name = "AtriumSpire"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.2
	mesh.bottom_radius = 7.5
	mesh.height = 22.0
	spire.mesh = mesh
	spire.position = Vector3(0.0, MAIN_HEIGHT + 18.0, -6.0)
	spire.material_override = _glass_mat(0.42)
	parent.add_child(spire)

	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(10.0, 1.2, 10.0)
	cap.mesh = cap_mesh
	cap.position = Vector3(0.0, MAIN_HEIGHT + 30.0, -6.0)
	cap.material_override = _accent_mat()
	parent.add_child(cap)


static func _build_glass_curtain(parent: Node3D) -> void:
	var panel_w := 11.0
	var panel_h := MAIN_HEIGHT * 0.78
	var start_x := -FOOTPRINT_X * 0.5 + panel_w * 0.55
	var count := 7
	for i in range(count):
		_add_glass_panel(
			parent,
			Vector3(panel_w, panel_h, 0.22),
			Vector3(start_x + i * panel_w * 0.95, panel_h * 0.5 + 1.0, -FOOTPRINT_Z * 0.5 - 0.08)
		)

	var canopy := MeshInstance3D.new()
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(FOOTPRINT_X * 0.55, 0.55, 7.0)
	canopy.mesh = canopy_mesh
	canopy.position = Vector3(0.0, 7.5, -FOOTPRINT_Z * 0.5 - 3.5)
	canopy.material_override = _white_cool_mat()
	parent.add_child(canopy)


static func _build_skyline_accents(parent: Node3D) -> void:
	var accents := Node3D.new()
	accents.name = "SkylineAccents"
	parent.add_child(accents)

	var models := ["building-skyscraper-a", "building-skyscraper-c", "building-skyscraper-e"]
	var offsets := [
		Vector3(-58.0, 0.0, 26.0),
		Vector3(0.0, 0.0, 34.0),
		Vector3(58.0, 0.0, 26.0),
	]
	for i in range(models.size()):
		var inst := CityKitLibrary.spawn(accents, "commercial", models[i], offsets[i], float(i) * 0.18, KIT_SCALE)
		if inst != null:
			_apply_material_recursive(inst, _white_mat())


static func _build_roof_details(parent: Node3D) -> void:
	for offset in [Vector3(-24.0, MAIN_HEIGHT + 1.2, 10.0), Vector3(24.0, MAIN_HEIGHT + 1.2, 10.0)]:
		_add_box(parent, Vector3(8.0, 2.4, 8.0), offset, _sand_light_mat())

	SpaceKitLibrary.spawn(parent, "template-wall-detail-a", Vector3(0.0, MAIN_HEIGHT + 2.0, 14.0))


static func _add_hq_lighting(parent: Node3D) -> void:
	var entrance := entrance_position()
	var entrance_light := OmniLight3D.new()
	entrance_light.position = entrance + Vector3(0.0, 9.0, -4.0)
	entrance_light.light_color = Color(0.95, 0.92, 0.82)
	entrance_light.light_energy = 2.2
	entrance_light.omni_range = 42.0
	parent.add_child(entrance_light)

	var facade_light := OmniLight3D.new()
	facade_light.position = Vector3(0.0, MAIN_HEIGHT * 0.55, -FOOTPRINT_Z * 0.5 - 6.0)
	facade_light.light_color = Color(0.72, 0.88, 1.0)
	facade_light.light_energy = 1.4
	facade_light.omni_range = 55.0
	parent.add_child(facade_light)


static func _build_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "HQCollision"
	parent.add_child(body)

	_add_collider(body, Vector3(FOOTPRINT_X, MAIN_HEIGHT, FOOTPRINT_Z), Vector3(0.0, MAIN_HEIGHT * 0.5 + 0.42, 0.0))
	for side in [-1.0, 1.0]:
		var wing_x := FOOTPRINT_X * 0.34
		_add_collider(
			body,
			Vector3(wing_x, WING_HEIGHT, FOOTPRINT_Z * 0.42),
			Vector3(side * (FOOTPRINT_X * 0.5 + wing_x * 0.18), WING_HEIGHT * 0.5 + 0.42, 8.0)
		)


static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
	return mesh_inst


static func _add_glass_panel(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	_add_box(parent, size, pos, _glass_mat())


static func _add_collider(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape_node.shape = box
	shape_node.position = pos
	body.add_child(shape_node)


static func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)


static func _white_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WHITE
	mat.metallic = 0.14
	mat.roughness = 0.22
	return mat


static func _white_cool_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WHITE_COOL
	mat.metallic = 0.22
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = Color(0.88, 0.92, 0.98)
	mat.emission_energy_multiplier = 0.06
	return mat


static func _sand_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SAND
	mat.metallic = 0.04
	mat.roughness = 0.72
	return mat


static func _sand_light_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SAND_LIGHT
	mat.metallic = 0.06
	mat.roughness = 0.58
	return mat


static func _accent_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ACCENT_GOLD
	mat.metallic = 0.35
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = ACCENT_GOLD
	mat.emission_energy_multiplier = 0.12
	return mat


static func _glass_mat(alpha: float = 0.32) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(GLASS.r, GLASS.g, GLASS.b, alpha)
	mat.metallic = 0.88
	mat.roughness = 0.06
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.78, 1.0)
	mat.emission_energy_multiplier = 0.22
	return mat