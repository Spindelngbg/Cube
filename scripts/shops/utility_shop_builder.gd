class_name UtilityShopBuilder
extends RefCounted

const UtilityShopScript = preload("res://scripts/shops/utility_shop.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const ShopDoorBuilderScript = preload("res://scripts/shops/shop_door_builder.gd")

const OLIVE := Color(0.35, 0.45, 0.28)
const ACCENT := Color(0.95, 0.75, 0.2)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "utility_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "UtilityShop"
	shop.position = pos
	parent.add_child(shop)

	var floor := _box(Vector3(6.5, 0.2, 5.2), OLIVE.darkened(0.15))
	floor.position = Vector3(0.0, 0.1, 0.0)
	shop.add_child(floor)
	var back := _box(Vector3(6.5, 3.1, 0.28), OLIVE)
	back.position = Vector3(0.0, 1.65, -2.46)
	shop.add_child(back)
	for side in [-1.0, 1.0]:
		var wall := _box(Vector3(0.28, 3.1, 5.2), OLIVE.lightened(0.04))
		wall.position = Vector3(3.11 * side, 1.65, 0.0)
		shop.add_child(wall)
	var roof := _box(Vector3(6.8, 0.18, 5.5), ACCENT.darkened(0.4))
	roof.position = Vector3(0.0, 3.25, 0.0)
	shop.add_child(roof)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(6.5, 3.1, 0.35), Vector3(0.0, 1.65, -2.46))
	WorldCollisionBuilderScript.attach_box(shop, Vector3(0.35, 3.1, 5.2), Vector3(-3.11, 1.65, 0.0))
	WorldCollisionBuilderScript.attach_box(shop, Vector3(0.35, 3.1, 5.2), Vector3(3.11, 1.65, 0.0))
	WorldCollisionBuilderScript.attach_box(shop, Vector3(6.5, 0.25, 5.2), Vector3(0.0, 0.1, 0.0))
	ShopDoorBuilderScript.add_entrance(
		shop, 2.55, 3.25, 1.9, 2.35, 3.1, OLIVE.darkened(0.15), Color(0.28, 0.24, 0.18), ACCENT, 22.0
	)

	var sign := Label3D.new()
	sign.text = "ÖVERLEVNAD"
	sign.font_size = 38
	sign.modulate = ACCENT
	sign.position = Vector3(0.0, 3.7, 2.5)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sign)

	var sub := Label3D.new()
	sub.text = "Första hjälpen · Pansar · Energi"
	sub.font_size = 20
	sub.modulate = Color(0.9, 0.85, 0.6)
	sub.position = Vector3(0.0, 3.25, 2.5)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sub)

	var counter := _box(Vector3(3.8, 1.0, 1.1), Color(0.25, 0.22, 0.18))
	counter.position = Vector3(0.0, 0.5, -1.4)
	shop.add_child(counter)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 3.5, 0.0)
	light.light_color = ACCENT
	light.light_energy = 0.9
	light.omni_range = 11.0
	shop.add_child(light)

	var area: UtilityShop = UtilityShopScript.new()
	area.name = "ShopArea"
	shop.add_child(area)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.poi_id = poi_id
	marker.display_name = "Överlevnadsbod"
	marker.category = "utility"
	marker.keywords = PackedStringArray([
		"överlevnad", "medicin", "första hjälpen", "pansar", "energi", "butik"
	])
	marker.map_color = ACCENT
	shop.add_child(marker)

	return shop


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	m.material_override = mat
	return m
