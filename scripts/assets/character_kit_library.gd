class_name CharacterKitLibrary
extends RefCounted

const KENNEY_BLOCKY_PATH := "res://assets/models/characters/kenney-blocky/Models/GLB format/"
const DEFAULT_SCALE := 1.0


static func model_path(name: String) -> String:
	var file_name := name if name.ends_with(".glb") else "%s.glb" % name
	return KENNEY_BLOCKY_PATH + file_name


static func load_model(name: String) -> PackedScene:
	var path := model_path(name)
	if ResourceLoader.exists(path):
		return load(path) as PackedScene
	push_warning("Character model not found: %s" % name)
	return null


static func spawn(
	parent: Node3D,
	name: String,
	position: Vector3 = Vector3.ZERO,
	rotation_y: float = 0.0,
	scale_factor: float = DEFAULT_SCALE
) -> Node3D:
	var scene := load_model(name)
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	if absf(scale_factor - 1.0) > 0.001:
		instance.scale = Vector3.ONE * scale_factor
	instance.position = position
	instance.rotation.y = rotation_y
	parent.add_child(instance)
	return instance


static func apply_tint(root: Node, color: Color, strength: float = 0.45) -> void:
	if root is MeshInstance3D:
		var mesh := root as MeshInstance3D
		var mat := mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			copy.albedo_color = copy.albedo_color.lerp(color, clampf(strength, 0.0, 1.0))
			if strength > 0.55:
				copy.emission_enabled = true
				copy.emission = color
				copy.emission_energy_multiplier = strength * 0.35
			mesh.material_override = copy
	for child in root.get_children():
		apply_tint(child, color, strength)


static func list_models() -> PackedStringArray:
	var dir := DirAccess.open(KENNEY_BLOCKY_PATH)
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