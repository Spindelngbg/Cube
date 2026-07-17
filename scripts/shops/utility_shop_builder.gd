class_name UtilityShopBuilder
extends RefCounted

const UtilityShopScript = preload("res://scripts/shops/utility_shop.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const OLIVE := Color(0.35, 0.45, 0.28)
const ACCENT := Color(0.95, 0.75, 0.2)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "utility_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "UtilityShop"
	shop.position = pos
	parent.add_child(shop)

	var shell := _box(Vector3(6.5, 3.2, 5.2), OLIVE)
	shell.position = Vector3(0.0, 1.6, 0.0)
	shop.add_child(shell)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(6.5, 3.2, 5.2), Vector3(0.0, 1.6, 0.0))

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
