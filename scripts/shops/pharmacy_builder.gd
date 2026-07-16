class_name PharmacyBuilder
extends RefCounted

const PharmacyShopScript = preload("res://scripts/shops/pharmacy_shop.gd")
const CutePharmacyRobotScript = preload("res://scripts/npcs/cute_pharmacy_robot.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const MINT := Color(0.42, 0.88, 0.72)
const GLASS := Color(0.72, 0.92, 0.98, 0.55)
const WHITE := Color(0.96, 0.98, 0.97)


static func build(parent: Node3D, pos: Vector3) -> Node3D:
	var pharmacy := Node3D.new()
	pharmacy.name = "Pharmacy"
	pharmacy.position = pos
	parent.add_child(pharmacy)

	_build_shell(pharmacy)
	WorldCollisionBuilderScript.attach_box(pharmacy, Vector3(7.0, 3.9, 6.0), Vector3(0.0, 2.0, 0.0))
	_build_sign(pharmacy)
	_build_counter(pharmacy)

	var robot: CutePharmacyRobot = CutePharmacyRobotScript.new()
	robot.name = "PillBot"
	robot.position = Vector3(0.0, 0.0, -1.2)
	pharmacy.add_child(robot)

	var shop: PharmacyShop = PharmacyShopScript.new()
	shop.name = "PharmacyShop"
	shop.position = Vector3(0.0, 1.2, 0.0)
	shop.setup(robot)
	pharmacy.add_child(shop)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5.5, 3.0, 5.0)
	shape.shape = box
	shop.add_child(shape)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 4.5, 0.0)
	light.light_color = Color(0.55, 0.95, 0.78)
	light.light_energy = 1.1
	light.omni_range = 14.0
	pharmacy.add_child(light)

	var welcome := Label3D.new()
	welcome.text = "Hybrid-Antidot mot zombiebett"
	welcome.font_size = 28
	welcome.modulate = MINT.lightened(0.1)
	welcome.position = Vector3(0.0, 3.6, -2.8)
	welcome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pharmacy.add_child(welcome)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = "pharmacy"
	marker.display_name = "Pharmacy"
	marker.category = "pharmacy"
	marker.keywords = PackedStringArray(["pharmacy", "medicin", "antidot", "gift", "butik"])
	marker.map_color = MINT
	pharmacy.add_child(marker)

	return pharmacy


static func _build_shell(parent: Node3D) -> void:
	var floor := _box(Vector3(7.0, 0.25, 6.0), WHITE.darkened(0.08))
	floor.position = Vector3(0.0, 0.12, 0.0)
	parent.add_child(floor)

	var back := _box(Vector3(7.0, 3.8, 0.35), WHITE)
	back.position = Vector3(0.0, 2.0, -2.85)
	parent.add_child(back)

	for side in [-1.0, 1.0]:
		var wall := _box(Vector3(0.35, 3.8, 6.0), WHITE.lightened(0.02))
		wall.position = Vector3(3.35 * side, 2.0, 0.0)
		parent.add_child(wall)

	var roof := _box(Vector3(7.2, 0.2, 6.2), MINT.darkened(0.15))
	roof.position = Vector3(0.0, 3.95, 0.0)
	parent.add_child(roof)

	var window := _box(Vector3(4.5, 1.8, 0.08), GLASS)
	window.position = Vector3(0.0, 2.2, 2.92)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = GLASS
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.08
	glass_mat.metallic = 0.2
	window.material_override = glass_mat
	parent.add_child(window)


static func _build_sign(parent: Node3D) -> void:
	var pole := _box(Vector3(0.12, 3.2, 0.12), MINT)
	pole.position = Vector3(-3.0, 1.8, 2.5)
	parent.add_child(pole)

	var board := _box(Vector3(2.8, 1.0, 0.12), MINT.lightened(0.05))
	board.position = Vector3(-3.0, 3.5, 2.5)
	parent.add_child(board)

	var label := Label3D.new()
	label.text = "PHARMACY"
	label.font_size = 56
	label.modulate = Color(1.0, 1.0, 0.98)
	label.outline_modulate = Color(0.1, 0.35, 0.28, 0.95)
	label.position = Vector3(-3.0, 3.85, 2.35)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _build_counter(parent: Node3D) -> void:
	var counter := _box(Vector3(4.8, 1.0, 1.2), Color(0.88, 0.94, 0.92))
	counter.position = Vector3(0.0, 0.62, -1.0)
	parent.add_child(counter)

	var top := _box(Vector3(4.9, 0.06, 1.3), WHITE)
	top.position = Vector3(0.0, 1.14, -1.0)
	parent.add_child(top)

	for i in 3:
		var bottle := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.08
		mesh.bottom_radius = 0.1
		mesh.height = 0.28
		bottle.mesh = mesh
		bottle.position = Vector3(-1.2 + i * 1.2, 1.35, -0.7)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(0.35 + i * 0.08, 0.45, 0.85)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.25
		bottle.material_override = mat
		parent.add_child(bottle)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mesh.material_override = mat
	return mesh