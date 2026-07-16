class_name CityKitLibrary
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")

const KITS := {
	"commercial": "res://assets/models/city-kit-commercial/Models/GLB format/",
	"suburban": "res://assets/models/city-kit-suburban/Models/GLB format/",
	"industrial": "res://assets/models/city-kit-industrial/Models/GLB format/",
	"roads": "res://assets/models/city-kit-roads/Models/GLB format/",
	"building": "res://assets/models/building-kit/Models/GLB format/",
}

## Kenney city/suburban/industrial/road GLB är ~1 m — vår spelvärld och DC-block är i meter.
## building-kit använder redan ~2 m-rutnät och behöver inte uppskalas.
const KIT_SCALES := {
	"commercial": 18.0,
	"suburban": 16.0,
	"industrial": 14.0,
	"roads": 4.0,
	"building": 1.0,
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


static func kit_scale(kit: String) -> float:
	return float(KIT_SCALES.get(kit, 1.0))


static func spawn(
	parent: Node3D,
	kit: String,
	name: String,
	position: Vector3 = Vector3.ZERO,
	rotation_y: float = 0.0,
	scale_factor: float = -1.0,
	building_tint: Color = Color.WHITE
) -> Node3D:
	var scene := load_model(kit, name)
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	var scale := scale_factor if scale_factor > 0.0 else kit_scale(kit)
	if absf(scale - 1.0) > 0.001:
		instance.scale = Vector3.ONE * scale
	instance.position = position
	instance.rotation.y = rotation_y
	parent.add_child(instance)
	if kit != "roads" and building_tint != Color.WHITE:
		apply_building_tint(instance, building_tint)
	if kit != "roads":
		DevBuildingLabelsScript.attach(
			parent,
			position,
			DevBuildingLabelsScript.footprint_half_for_city_kit(kit, scale),
			rotation_y,
			instance
		)
	return instance


static func apply_building_tint(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		_tint_mesh_instance(node as MeshInstance3D, tint)
	for child in node.get_children():
		apply_building_tint(child, tint)


static func _tint_mesh_instance(mesh_node: MeshInstance3D, tint: Color) -> void:
	if mesh_node.material_override is StandardMaterial3D:
		var override_mat := mesh_node.material_override.duplicate() as StandardMaterial3D
		override_mat.albedo_color = (override_mat.albedo_color * tint).clamp()
		mesh_node.material_override = override_mat

	if mesh_node.mesh == null:
		return
	for surface_index in range(mesh_node.mesh.get_surface_count()):
		var src := mesh_node.get_surface_override_material(surface_index)
		if src == null:
			src = mesh_node.mesh.surface_get_material(surface_index)
		if src == null or not (src is StandardMaterial3D):
			continue
		var mat := src.duplicate() as StandardMaterial3D
		mat.albedo_color = (mat.albedo_color * tint).clamp()
		mesh_node.set_surface_override_material(surface_index, mat)


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