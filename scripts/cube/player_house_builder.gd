class_name PlayerHouseBuilder
extends RefCounted

const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const PlayerHouseCatalogScript = preload("res://scripts/cube/player_house_catalog.gd")

const TENT := Color(0.72, 0.55, 0.28)
const STEEL := Color(0.45, 0.5, 0.55)
const WHITE := Color(0.92, 0.93, 0.95)
const LUXURY := Color(0.85, 0.88, 0.95)
const MANSION := Color(0.78, 0.72, 0.58)
const GLASS := Color(0.55, 0.75, 0.95, 0.45)
const ACCENT := Color(0.25, 0.85, 0.55)


static func build(parent: Node3D, house_id: String, center: Vector3, yaw: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "PlayerHouse_%s" % house_id
	root.position = center
	root.rotation.y = yaw
	root.set_meta("player_house_id", house_id)
	parent.add_child(root)

	match house_id:
		"tent":
			_build_tent(root)
		"container":
			_build_container(root)
		"square":
			_build_square(root)
		"luxury":
			_build_luxury(root)
		"mansion":
			_build_mansion(root)
		_:
			_build_tent(root)

	var label := Label3D.new()
	label.text = PlayerHouseCatalogScript.get_display_name(house_id)
	label.font_size = 28
	label.modulate = ACCENT.lightened(0.2)
	label.outline_modulate = Color(0.05, 0.1, 0.08, 0.95)
	label.position = Vector3(0.0, _label_height(house_id), 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	return root


static func _label_height(house_id: String) -> float:
	match house_id:
		"tent":
			return 3.2
		"container":
			return 4.0
		"square":
			return 5.5
		"luxury":
			return 8.5
		"mansion":
			return 14.0
		_:
			return 3.5


static func _build_tent(root: Node3D) -> void:
	var floor := _box(Vector3(5.5, 0.12, 5.5), Color(0.35, 0.28, 0.18))
	floor.position = Vector3(0.0, 0.06, 0.0)
	root.add_child(floor)
	# Enkelt tält: två sluttande paneler
	var left := _box(Vector3(0.12, 2.4, 5.2), TENT)
	left.position = Vector3(-1.4, 1.1, 0.0)
	left.rotation_degrees = Vector3(0.0, 0.0, 35.0)
	root.add_child(left)
	var right := _box(Vector3(0.12, 2.4, 5.2), TENT.darkened(0.08))
	right.position = Vector3(1.4, 1.1, 0.0)
	right.rotation_degrees = Vector3(0.0, 0.0, -35.0)
	root.add_child(right)
	var back := _box(Vector3(3.2, 1.8, 0.1), TENT.darkened(0.12))
	back.position = Vector3(0.0, 0.9, -2.4)
	root.add_child(back)
	WorldCollisionBuilderScript.attach_box(root, Vector3(5.5, 2.4, 5.5), Vector3(0.0, 1.2, 0.0))


static func _build_container(root: Node3D) -> void:
	var body := _box(Vector3(7.0, 3.0, 3.2), STEEL)
	body.position = Vector3(0.0, 1.5, 0.0)
	root.add_child(body)
	var ribs := _box(Vector3(7.1, 0.15, 3.3), STEEL.lightened(0.15))
	ribs.position = Vector3(0.0, 2.9, 0.0)
	root.add_child(ribs)
	var door := _box(Vector3(1.4, 2.2, 0.12), Color(0.25, 0.28, 0.32))
	door.position = Vector3(0.0, 1.2, 1.65)
	root.add_child(door)
	var window := _box(Vector3(1.2, 0.7, 0.08), GLASS)
	window.position = Vector3(2.0, 1.8, 1.62)
	root.add_child(window)
	WorldCollisionBuilderScript.attach_box(root, Vector3(7.0, 3.0, 3.2), Vector3(0.0, 1.5, 0.0))


static func _build_square(root: Node3D) -> void:
	var body := _box(Vector3(9.0, 4.2, 9.0), WHITE.darkened(0.08))
	body.position = Vector3(0.0, 2.1, 0.0)
	root.add_child(body)
	var roof := _box(Vector3(9.6, 0.35, 9.6), Color(0.35, 0.4, 0.45))
	roof.position = Vector3(0.0, 4.35, 0.0)
	root.add_child(roof)
	var door := _box(Vector3(1.6, 2.4, 0.15), Color(0.4, 0.28, 0.18))
	door.position = Vector3(0.0, 1.2, 4.55)
	root.add_child(door)
	for x in [-2.5, 2.5]:
		var win := _box(Vector3(1.4, 1.1, 0.1), GLASS)
		win.position = Vector3(x, 2.4, 4.52)
		root.add_child(win)
	WorldCollisionBuilderScript.attach_box(root, Vector3(9.0, 4.2, 9.0), Vector3(0.0, 2.1, 0.0))


static func _build_luxury(root: Node3D) -> void:
	var base := _box(Vector3(11.0, 3.6, 9.5), LUXURY)
	base.position = Vector3(0.0, 1.8, 0.0)
	root.add_child(base)
	var upper := _box(Vector3(8.5, 3.2, 7.5), LUXURY.lightened(0.05))
	upper.position = Vector3(0.0, 5.2, -0.5)
	root.add_child(upper)
	var roof := _box(Vector3(9.2, 0.3, 8.2), Color(0.2, 0.22, 0.28))
	roof.position = Vector3(0.0, 6.95, -0.5)
	root.add_child(roof)
	var glass_front := _box(Vector3(6.0, 2.4, 0.12), GLASS)
	glass_front.position = Vector3(0.0, 2.2, 4.8)
	root.add_child(glass_front)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 5.5, 3.0)
	light.light_color = Color(0.7, 0.9, 1.0)
	light.light_energy = 1.2
	light.omni_range = 14.0
	root.add_child(light)
	WorldCollisionBuilderScript.attach_box(root, Vector3(11.0, 7.0, 9.5), Vector3(0.0, 3.5, 0.0))


static func _build_mansion(root: Node3D) -> void:
	# Stor 2×2-zon-byggnad (~18 m bred).
	var wing := _box(Vector3(18.0, 4.5, 16.0), MANSION)
	wing.position = Vector3(0.0, 2.25, 0.0)
	root.add_child(wing)
	var mid := _box(Vector3(14.0, 4.0, 12.0), MANSION.lightened(0.06))
	mid.position = Vector3(0.0, 6.4, 0.0)
	root.add_child(mid)
	var top := _box(Vector3(10.0, 3.5, 9.0), MANSION.darkened(0.05))
	top.position = Vector3(0.0, 10.2, 0.0)
	root.add_child(top)
	var roof := _box(Vector3(11.0, 0.4, 10.0), Color(0.25, 0.22, 0.2))
	roof.position = Vector3(0.0, 12.1, 0.0)
	root.add_child(roof)
	var columns := [-6.0, -2.0, 2.0, 6.0]
	for x in columns:
		var col := _box(Vector3(0.55, 4.2, 0.55), WHITE)
		col.position = Vector3(x, 2.1, 8.2)
		root.add_child(col)
	var door := _box(Vector3(2.4, 3.2, 0.2), Color(0.35, 0.22, 0.12))
	door.position = Vector3(0.0, 1.6, 8.15)
	root.add_child(door)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 8.0, 6.0)
	light.light_color = Color(1.0, 0.92, 0.7)
	light.light_energy = 1.5
	light.omni_range = 22.0
	root.add_child(light)
	WorldCollisionBuilderScript.attach_box(root, Vector3(18.0, 12.5, 16.0), Vector3(0.0, 6.25, 0.0))


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.12
		mat.metallic = 0.2
	else:
		mat.roughness = 0.68
	mesh_i.material_override = mat
	return mesh_i
