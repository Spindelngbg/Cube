class_name PotionShopBuilder
extends RefCounted

const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const PotionShopScript = preload("res://scripts/shops/potion_shop.gd")
const PotionShopOwnerScript = preload("res://scripts/shops/potion_shop_owner.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const STONE := Color(0.28, 0.2, 0.38)
const ACCENT := Color(0.72, 0.35, 0.95)
const WOOD := Color(0.2, 0.14, 0.28)
const GLASS := Color(0.55, 0.35, 0.85, 0.55)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "potion_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "PotionShop"
	shop.position = pos
	parent.add_child(shop)

	_build_shell(shop)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(8.0, 4.0, 6.5), Vector3(0.0, 2.0, 0.0))
	_build_sign(shop)
	_build_shelves(shop)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 4.6, 0.0)
	light.light_color = ACCENT
	light.light_energy = 1.15
	light.omni_range = 16.0
	shop.add_child(light)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = poi_id
	marker.display_name = "Brygdhörnan"
	marker.category = "brygdaffär"
	marker.keywords = PackedStringArray([
		"brygd", "potion", "magi", "elixir", "strid", "hälsa", "butik", "mira", "mystika"
	])
	marker.map_color = ACCENT
	shop.add_child(marker)

	var shop_area: PotionShop = PotionShopScript.new()
	shop_area.name = "ShopArea"
	shop.add_child(shop_area)

	var owner: PotionShopOwner = PotionShopOwnerScript.new()
	owner.name = "ShopOwner"
	owner.position = Vector3(0.0, 0.0, -1.5)
	shop.add_child(owner)

	var welcome := Label3D.new()
	welcome.text = "Magiska brygder — skada & livskraft"
	welcome.font_size = 26
	welcome.modulate = ACCENT.lightened(0.2)
	welcome.position = Vector3(0.0, 3.55, -2.9)
	welcome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(welcome)

	return shop


static func _build_shell(shop: Node3D) -> void:
	var floor := _box(Vector3(8.0, 0.22, 6.5), STONE.lightened(0.08))
	floor.position = Vector3(0.0, 0.11, 0.0)
	shop.add_child(floor)

	var back := _box(Vector3(8.0, 3.9, 0.32), STONE)
	back.position = Vector3(0.0, 2.05, -3.1)
	shop.add_child(back)

	for side in [-1.0, 1.0]:
		var wall := _box(Vector3(0.32, 3.9, 6.5), STONE.lightened(0.04))
		wall.position = Vector3(3.85 * side, 2.05, 0.0)
		shop.add_child(wall)

	var roof := _box(Vector3(8.3, 0.22, 6.8), ACCENT.darkened(0.35))
	roof.position = Vector3(0.0, 4.05, 0.0)
	shop.add_child(roof)

	var window := _box(Vector3(4.2, 1.7, 0.08), GLASS)
	window.position = Vector3(0.0, 2.15, 3.2)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = GLASS
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = ACCENT
	glass_mat.emission_energy_multiplier = 0.2
	window.material_override = glass_mat
	shop.add_child(window)


static func _build_sign(shop: Node3D) -> void:
	var pole := _box(Vector3(0.12, 3.0, 0.12), ACCENT.darkened(0.2))
	pole.position = Vector3(-3.4, 1.7, 2.7)
	shop.add_child(pole)

	var board := _box(Vector3(2.9, 1.05, 0.12), ACCENT.darkened(0.15))
	board.position = Vector3(-3.4, 3.35, 2.7)
	shop.add_child(board)

	var label := Label3D.new()
	label.text = "BRYGDHÖRNAN"
	label.font_size = 48
	label.modulate = Color(0.95, 0.88, 1.0)
	label.outline_modulate = Color(0.12, 0.05, 0.2, 0.95)
	label.position = Vector3(-3.4, 3.7, 2.55)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(label)


static func _build_shelves(shop: Node3D) -> void:
	var desk := _box(Vector3(4.0, 1.0, 1.2), WOOD)
	desk.position = Vector3(0.0, 0.52, -1.8)
	shop.add_child(desk)

	var shelf := _box(Vector3(5.5, 0.12, 0.55), WOOD.lightened(0.08))
	shelf.position = Vector3(0.0, 2.2, -2.7)
	shop.add_child(shelf)

	var colors := [
		Color(0.9, 0.25, 0.28),
		Color(0.35, 0.75, 0.45),
		Color(0.55, 0.35, 0.95),
		Color(0.95, 0.7, 0.2),
		Color(0.3, 0.55, 0.95),
	]
	for i in colors.size():
		var bottle := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.07
		mesh.bottom_radius = 0.09
		mesh.height = 0.32
		bottle.mesh = mesh
		bottle.position = Vector3(-1.6 + float(i) * 0.8, 2.45, -2.65)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mat.emission_enabled = true
		mat.emission = colors[i]
		mat.emission_energy_multiplier = 0.45
		mat.roughness = 0.25
		bottle.material_override = mat
		shop.add_child(bottle)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.68
	mesh.material_override = mat
	return mesh
