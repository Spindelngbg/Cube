class_name CityKitLibrary
extends RefCounted

const KITS := {
	"commercial": "res://assets/models/city-kit-commercial/Models/GLB format/",
	"suburban": "res://assets/models/city-kit-suburban/Models/GLB format/",
	"industrial": "res://assets/models/city-kit-industrial/Models/GLB format/",
	"roads": "res://assets/models/city-kit-roads/Models/GLB format/",
	"building": "res://assets/models/building-kit/Models/GLB format/",
}


static func model_path(kit: String, name: String) -> String:
	var base: String = KITS.get(kit, "")
	if base == "":
		return ""
	var file_name := name if name.ends_with(".glb") else "%s.glb" % name
	return base + file_name


static func load_model(kit: String, name: String) -> PackedScene:
	var path := model_path(kit, name)
	if path != "" and ResourceLoader.exists(path):
		return load(path) as PackedScene
	push_warning("City kit model not found: %s/%s" % [kit, name])
	return null


static func spawn(
	parent: Node3D,
	kit: String,
	name: String,
	position: Vector3 = Vector3.ZERO,
	rotation_y: float = 0.0
) -> Node3D:
	var scene := load_model(kit, name)
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	instance.position = position
	instance.rotation.y = rotation_y
	parent.add_child(instance)
	return instance


static func list_models(kit: String) -> PackedStringArray:
	var base: String = KITS.get(kit, "")
	if base == "":
		return PackedStringArray()
	var dir := DirAccess.open(base)
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