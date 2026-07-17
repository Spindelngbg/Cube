class_name ShoeShopBuilder
extends RefCounted

const ShoeShopScript = preload("res://scripts/shops/shoe_shop.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const CharacterKitLibraryScript = preload("res://scripts/assets/character_kit_library.gd")

const CANVAS := Color(0.92, 0.78, 0.42)
const ACCENT := Color(0.2, 0.72, 0.55)
const WOOD := Color(0.38, 0.26, 0.16)
const WHITE := Color(0.96, 0.94, 0.9)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "shoe_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "ShoeShop"
	shop.position = pos
	parent.add_child(shop)

	_build_shell(shop)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(6.2, 3.4, 5.2), Vector3(0.0, 1.7, 0.0))
	_build_sign(shop)
	_build_counter(shop)
	_build_owner(shop)
	_build_boot_display(shop)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 3.8, 0.0)
	light.light_color = CANVAS.lightened(0.1)
	light.light_energy = 1.05
	light.omni_range = 12.0
	shop.add_child(light)

	var shop_area: ShoeShop = ShoeShopScript.new()
	shop_area.name = "ShopArea"
	shop.add_child(shop_area)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = poi_id
	marker.display_name = "Skobutik"
	marker.category = "skobutik"
	marker.keywords = PackedStringArray([
		"sko", "skor", "hoppskor", "boots", "hopp", "fallskada", "butik", "sussi"
	])
	marker.map_color = ACCENT
	shop.add_child(marker)

	var welcome := Label3D.new()
	welcome.text = "Hoppskor — 200% högre hopp"
	welcome.font_size = 26
	welcome.modulate = ACCENT.lightened(0.15)
	welcome.position = Vector3(0.0, 3.15, -2.35)
	welcome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(welcome)

	return shop


static func _build_shell(shop: Node3D) -> void:
	var floor := _box(Vector3(6.2, 0.2, 5.2), WHITE.darkened(0.06))
	floor.position = Vector3(0.0, 0.1, 0.0)
	shop.add_child(floor)

	var back := _box(Vector3(6.2, 3.3, 0.28), CANVAS.darkened(0.12))
	back.position = Vector3(0.0, 1.75, -2.45)
	shop.add_child(back)

	for side in [-1.0, 1.0]:
		var wall := _box(Vector3(0.28, 3.3, 5.2), CANVAS.darkened(0.05))
		wall.position = Vector3(2.96 * side, 1.75, 0.0)
		shop.add_child(wall)

	var roof := _box(Vector3(6.5, 0.18, 5.5), ACCENT.darkened(0.25))
	roof.position = Vector3(0.0, 3.45, 0.0)
	shop.add_child(roof)


static func _build_sign(shop: Node3D) -> void:
	var pole := _box(Vector3(0.1, 2.6, 0.1), WOOD)
	pole.position = Vector3(-2.6, 1.4, 2.2)
	shop.add_child(pole)

	var board := _box(Vector3(2.4, 0.9, 0.12), ACCENT)
	board.position = Vector3(-2.6, 2.9, 2.2)
	shop.add_child(board)

	var label := Label3D.new()
	label.text = "SKOBUTIK"
	label.font_size = 44
	label.modulate = Color(1.0, 0.98, 0.92)
	label.outline_modulate = Color(0.05, 0.18, 0.14, 0.95)
	label.position = Vector3(-2.6, 3.2, 2.05)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(label)


static func _build_counter(shop: Node3D) -> void:
	var desk := _box(Vector3(3.6, 0.95, 1.1), WOOD)
	desk.position = Vector3(0.0, 0.5, -1.4)
	shop.add_child(desk)

	var top := _box(Vector3(3.7, 0.06, 1.2), WHITE)
	top.position = Vector3(0.0, 1.0, -1.4)
	shop.add_child(top)


static func _build_boot_display(shop: Node3D) -> void:
	for i in 3:
		var boot := _box(Vector3(0.28, 0.18, 0.42), Color(0.18, 0.55, 0.42))
		boot.position = Vector3(-1.0 + float(i) * 1.0, 1.2, -1.15)
		shop.add_child(boot)
		var sole := _box(Vector3(0.3, 0.06, 0.44), Color(0.12, 0.12, 0.14))
		sole.position = Vector3(-1.0 + float(i) * 1.0, 1.08, -1.15)
		shop.add_child(sole)


static func _build_owner(shop: Node3D) -> void:
	var pivot := Node3D.new()
	pivot.name = "ShopOwner"
	pivot.position = Vector3(0.0, 0.0, -1.85)
	shop.add_child(pivot)

	var model := CharacterKitLibraryScript.spawn(pivot, "character-e", Vector3.ZERO, PI, 1.0)
	if model != null:
		CharacterKitLibraryScript.apply_tint(model, Color(0.25, 0.55, 0.42))

	var name_label := Label3D.new()
	name_label.text = "Sula-Sussi"
	name_label.font_size = 30
	name_label.modulate = ACCENT.lightened(0.2)
	name_label.outline_modulate = Color(0.05, 0.12, 0.1, 0.95)
	name_label.position = Vector3(0.0, 2.1, 0.0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pivot.add_child(name_label)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mesh.material_override = mat
	return mesh
