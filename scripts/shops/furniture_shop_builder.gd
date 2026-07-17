class_name FurnitureShopBuilder
extends RefCounted

const FurnitureShopScript = preload("res://scripts/shops/furniture_shop.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const FurnitureKitLibraryScript = preload("res://scripts/assets/furniture_kit_library.gd")

const WOOD := Color(0.45, 0.32, 0.2)
const CREAM := Color(0.92, 0.88, 0.78)
const ACCENT := Color(0.85, 0.55, 0.25)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "furniture_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "FurnitureShop"
	shop.position = pos
	parent.add_child(shop)

	var shell := _box(Vector3(7.5, 3.6, 6.0), CREAM.darkened(0.05))
	shell.position = Vector3(0.0, 1.8, 0.0)
	shop.add_child(shell)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(7.5, 3.6, 6.0), Vector3(0.0, 1.8, 0.0))

	var sign := Label3D.new()
	sign.text = "MÖBELBUTIK"
	sign.font_size = 40
	sign.modulate = ACCENT
	sign.position = Vector3(0.0, 4.0, 2.8)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sign)

	var sub := Label3D.new()
	sub.text = "Köp & placera var du vill"
	sub.font_size = 22
	sub.modulate = Color(0.9, 0.8, 0.65)
	sub.position = Vector3(0.0, 3.55, 2.8)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sub)

	var desk := _box(Vector3(4.0, 1.0, 1.2), WOOD)
	desk.position = Vector3(0.0, 0.5, -1.6)
	shop.add_child(desk)

	# Utställda möbler
	for entry in [
		{"model": "chair", "pos": Vector3(-2.2, 0.0, 0.5)},
		{"model": "tableCoffee", "pos": Vector3(0.0, 0.0, 0.8)},
		{"model": "lampRoundFloor", "pos": Vector3(2.2, 0.0, 0.4)},
	]:
		var piece := FurnitureKitLibraryScript.spawn(shop, str(entry.model), entry.pos, 0.0)
		if piece:
			piece.scale = Vector3.ONE * 1.4

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 3.8, 0.0)
	light.light_color = Color(1.0, 0.92, 0.75)
	light.light_energy = 1.0
	light.omni_range = 12.0
	shop.add_child(light)

	var area: FurnitureShop = FurnitureShopScript.new()
	area.name = "ShopArea"
	shop.add_child(area)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.poi_id = poi_id
	marker.display_name = "Möbelbutik"
	marker.category = "möbler"
	marker.keywords = PackedStringArray(["möbel", "furniture", "stol", "bord", "säng", "butik"])
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
	mat.roughness = 0.7
	m.material_override = mat
	return m
