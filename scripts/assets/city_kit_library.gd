class_name CityKitLibrary
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const ThreadedLoaderScript = preload("res://scripts/loading/threaded_loader.gd")

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

static var _scene_cache: Dictionary = {}


static func model_path(kit: String, name: String) -> String:
	var base: String = KITS.get(kit, "")
	if base == "":
		return ""
	var file_name := name if name.ends_with(".glb") else "%s.glb" % name
	return base + file_name


static func load_model(kit: String, name: String) -> PackedScene:
	var cache_key := "%s/%s" % [kit, name]
	if _scene_cache.has(cache_key):
		return _scene_cache[cache_key] as PackedScene
	var path := model_path(kit, name)
	if path == "" or not ResourceLoader.exists(path):
		push_warning("City kit model not found: %s/%s" % [kit, name])
		return null
	var scene := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	if scene:
		_scene_cache[cache_key] = scene
	return scene


static func dc_warmup_paths() -> PackedStringArray:
	var models := {
		"commercial": ["building-a", "building-b", "building-c", "building-d", "building-e"],
		"suburban": ["building-type-a", "building-type-b", "building-type-c"],
		"industrial": ["building-a", "building-c", "building-f"],
		"roads": ["tile-low", "road-square", "road-straight", "road-curve", "road-bend"],
		"building": ["wall-doorway-square", "floor"],
	}
	var paths: PackedStringArray = []
	for kit in models:
		for model_name in models[kit]:
			var path := model_path(str(kit), str(model_name))
			if path != "" and ResourceLoader.exists(path):
				paths.append(path)
	return paths


static func warmup_dc_city_models() -> void:
	for path in dc_warmup_paths():
		var kit_and_name := _cache_key_from_path(path)
		if kit_and_name == "":
			continue
		var parts := kit_and_name.split("/", false, 1)
		if parts.size() < 2:
			continue
		load_model(parts[0], parts[1])


## Laddar DC-modeller i bakgrundstrådar. Kräver host med SceneTree (await).
static func warmup_dc_city_models_threaded(host: Node) -> void:
	if host == null:
		warmup_dc_city_models()
		return
	var paths := dc_warmup_paths()
	var loaded: Dictionary = await ThreadedLoaderScript.await_paths(host, paths, true)
	for path in loaded:
		var scene: PackedScene = loaded[path] as PackedScene
		if scene == null:
			continue
		var key := _cache_key_from_path(str(path))
		if key != "":
			_scene_cache[key] = scene


static func _cache_key_from_path(path: String) -> String:
	for kit in KITS:
		var base: String = str(KITS[kit])
		if path.begins_with(base):
			var file := path.substr(base.length()).get_basename()
			return "%s/%s" % [kit, file]
	return ""


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
	if WorldCollisionBuilderScript.should_collide_city_kit(kit, name):
		WorldCollisionBuilderScript.attach_city_kit_collision(instance, kit, name)
	if kit != "roads" and building_tint != Color.WHITE:
		apply_building_tint(instance, building_tint)
	## Husnummer bara på hela hus — inte på enstaka vägg/golv-bitar från building-kit.
	if kit != "roads" and kit != "building" and OS.is_debug_build():
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


static func brighten_building(
	node: Node,
	## Mild boost — undvik att Kenney-material bleks till vitt.
	albedo_boost: Color = Color(1.08, 1.06, 1.04),
	emission: Color = Color(0.35, 0.4, 0.5),
	emission_energy: float = 0.12
) -> void:
	if node is MeshInstance3D:
		_brighten_mesh_instance(node as MeshInstance3D, albedo_boost, emission, emission_energy)
	for child in node.get_children():
		brighten_building(child, albedo_boost, emission, emission_energy)


static func _brighten_mesh_instance(
	mesh_node: MeshInstance3D,
	albedo_boost: Color,
	emission: Color,
	emission_energy: float
) -> void:
	if mesh_node.material_override is StandardMaterial3D:
		var override_mat := mesh_node.material_override.duplicate() as StandardMaterial3D
		override_mat.albedo_color = (override_mat.albedo_color * albedo_boost).clamp()
		override_mat.emission_enabled = true
		override_mat.emission = emission
		override_mat.emission_energy_multiplier = emission_energy
		override_mat.roughness = minf(override_mat.roughness, 0.72)
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
		mat.albedo_color = (mat.albedo_color * albedo_boost).clamp()
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
		mat.roughness = minf(mat.roughness, 0.72)
		mesh_node.set_surface_override_material(surface_index, mat)


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