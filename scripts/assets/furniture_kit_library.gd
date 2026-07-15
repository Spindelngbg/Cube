class_name FurnitureKitLibrary
extends RefCounted

const BASE_PATH := "res://assets/models/furniture-kit/Models/GLTF format/"


static func model_path(name: String) -> String:
	var file_name := name if name.ends_with(".glb") else "%s.glb" % name
	return BASE_PATH + file_name


static func load_model(name: String) -> PackedScene:
	var path := model_path(name)
	if ResourceLoader.exists(path):
		return load(path) as PackedScene
	push_warning("Furniture kit model not found: %s" % path)
	return null


static func spawn(parent: Node3D, name: String, position: Vector3 = Vector3.ZERO, rotation_y: float = 0.0) -> Node3D:
	var scene := load_model(name)
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	instance.position = position
	instance.rotation.y = rotation_y
	parent.add_child(instance)
	return instance


static func list_models() -> PackedStringArray:
	var dir := DirAccess.open(BASE_PATH)
	if dir == null:
		return PackedStringArray()
	var names: PackedStringArray = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".glb"):
			names.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names