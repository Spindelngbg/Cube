class_name HumanCharacterLibrary
extends RefCounted

const CharacterKitLibraryScript = preload("res://scripts/assets/character_kit_library.gd")

const KENNEY_LABELS := {
	"character-a": "Kolonist A",
	"character-b": "Kolonist B",
	"character-c": "Kolonist C",
	"character-d": "Kolonist D",
	"character-e": "Kolonist E",
	"character-f": "Kolonist F",
	"character-g": "Kolonist G",
	"character-h": "Kolonist H",
	"character-i": "Kolonist I",
	"character-j": "Kolonist J",
	"character-k": "Kolonist K",
	"character-l": "Kolonist L",
	"character-m": "Kolonist M",
	"character-n": "Kolonist N",
	"character-o": "Kolonist O",
	"character-p": "Kolonist P",
	"character-q": "Kolonist Q",
	"character-r": "Kolonist R",
}

const OPTIONAL_MESH_DEFS := {
	"reference_human": {
		"path": "res://assets/models/characters/reference_human.glb",
		"base_scale": 1.55,
		"label": "Referens (realistisk)",
		"locomotion_anim": "Animation",
		"uses_humanoid_punch": true,
		"kind": "gltf",
	},
	"quaternius_alien": {
		"path": "res://assets/models/characters/quaternius-alien/alien.fbx",
		"base_scale": 1.35,
		"label": "Alien",
		"locomotion_anim": "",
		"uses_humanoid_punch": false,
		"kind": "gltf",
	},
	"quaternius_universal": {
		"path": "res://assets/models/characters/quaternius-universal/Superhero_Male_FullBody.gltf",
		"base_scale": 1.55,
		"label": "Superhjälte (man)",
		"locomotion_anim": "",
		"uses_humanoid_punch": false,
		"kind": "gltf",
	},
	"quaternius_universal_female": {
		"path": "res://assets/models/characters/quaternius-universal/Superhero_Female_FullBody.gltf",
		"base_scale": 1.55,
		"label": "Superhjälte (kvinna)",
		"locomotion_anim": "",
		"uses_humanoid_punch": false,
		"kind": "gltf",
	},
}

static var _mesh_order: PackedStringArray = PackedStringArray()
static var _mesh_defs: Dictionary = {}


static func _ensure_catalog() -> void:
	if not _mesh_defs.is_empty():
		return
	for model_name in CharacterKitLibraryScript.list_models():
		_mesh_defs[model_name] = {
			"kind": "kenney",
			"model": model_name,
			"base_scale": 1.0,
			"label": KENNEY_LABELS.get(model_name, model_name.capitalize()),
			"locomotion_anim": "",
			"uses_humanoid_punch": false,
		}
		_mesh_order.append(model_name)
	for mesh_id in OPTIONAL_MESH_DEFS:
		var def: Dictionary = OPTIONAL_MESH_DEFS[mesh_id]
		if str(def.get("path", "")) != "" and ResourceLoader.exists(str(def.get("path"))):
			_mesh_defs[mesh_id] = def
			_mesh_order.append(mesh_id)


static func normalize_mesh_id(mesh_id: String) -> String:
	_ensure_catalog()
	var id := mesh_id.strip_edges()
	if id == "":
		return _default_mesh_id()
	if id in _mesh_defs:
		return id
	if id.begins_with("kenney_"):
		var mapped := "character-%s" % id.substr(7, 1)
		if mapped in _mesh_defs:
			return mapped
	return _default_mesh_id()


static func _default_mesh_id() -> String:
	_ensure_catalog()
	if _mesh_order.is_empty():
		return "reference_human"
	return _mesh_order[0]


static func get_mesh_def(mesh_id: String) -> Dictionary:
	_ensure_catalog()
	return _mesh_defs.get(normalize_mesh_id(mesh_id), {})


static func get_mesh_label(mesh_id: String) -> String:
	return str(get_mesh_def(mesh_id).get("label", mesh_id))


static func list_mesh_ids() -> PackedStringArray:
	_ensure_catalog()
	return _mesh_order.duplicate()


static func load_scene(mesh_id: String = "") -> PackedScene:
	_ensure_catalog()
	var id := normalize_mesh_id(mesh_id)
	var def: Dictionary = _mesh_defs.get(id, {})
	if str(def.get("kind", "")) == "kenney":
		return CharacterKitLibraryScript.load_model(str(def.get("model", id)))
	var path := str(def.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Character model not found for %s" % id)
		return CharacterKitLibraryScript.load_model(_default_mesh_id())
	return load(path) as PackedScene


static func spawn(
	parent: Node3D,
	position: Vector3 = Vector3.ZERO,
	rotation_y: float = 0.0,
	scale_factor: float = 1.0,
	mesh_id: String = ""
) -> Node3D:
	_ensure_catalog()
	var id := normalize_mesh_id(mesh_id)
	var def: Dictionary = _mesh_defs.get(id, {})
	if str(def.get("kind", "")) == "kenney":
		var base_scale: float = float(def.get("base_scale", 1.0))
		return CharacterKitLibraryScript.spawn(
			parent,
			str(def.get("model", id)),
			position,
			rotation_y,
			base_scale * scale_factor
		)
	var scene := load_scene(id)
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	var base: float = float(def.get("base_scale", 1.55))
	instance.position = position
	instance.rotation.y = rotation_y
	instance.scale = Vector3.ONE * base * scale_factor
	parent.add_child(instance)
	return instance


static func apply_avatar_customization(root: Node, data: AvatarData) -> void:
	var mesh_id := normalize_mesh_id(data.mesh_id)
	var def: Dictionary = get_mesh_def(mesh_id)
	if str(def.get("kind", "")) == "kenney":
		CharacterKitLibraryScript.apply_tint(root, data.body_color, 0.58)
		CharacterKitLibraryScript.apply_tint(root, data.accent_color, 0.28)
		if data.glow_strength > 0.05:
			CharacterKitLibraryScript.apply_tint(root, data.glow_color, data.glow_strength * 0.22)
		return
	apply_skin_tone(root, data.body_color, 0.52)
	apply_outfit_tint(root, data.accent_color, 0.42)
	if data.glow_strength > 0.05:
		apply_accent_glow(root, data.glow_color, data.glow_strength)


static func apply_skin_tone(root: Node, color: Color, strength: float = 0.38) -> void:
	_tint_meshes(root, color, clampf(strength, 0.0, 1.0), false)


static func apply_outfit_tint(root: Node, color: Color, strength: float = 0.32) -> void:
	_tint_meshes(root, color, clampf(strength, 0.0, 1.0), true)


static func apply_accent_glow(root: Node, color: Color, strength: float) -> void:
	if root is MeshInstance3D:
		var mesh := root as MeshInstance3D
		var mat := mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			copy.emission_enabled = true
			copy.emission = color
			copy.emission_energy_multiplier = 0.15 + strength * 0.45
			mesh.material_override = copy
	for child in root.get_children():
		apply_accent_glow(child, color, strength)


static func _tint_meshes(root: Node, color: Color, strength: float, outfit_pass: bool) -> void:
	if root is MeshInstance3D:
		var mesh := root as MeshInstance3D
		var mat := mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			var tint_strength := strength * (0.85 if outfit_pass else 1.0)
			copy.albedo_color = copy.albedo_color.lerp(color, tint_strength)
			if outfit_pass:
				copy.roughness = clampf(copy.roughness + 0.08, 0.0, 1.0)
			mesh.material_override = copy
	for child in root.get_children():
		_tint_meshes(child, color, strength, outfit_pass)


static func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null:
			return found
	return null


static func find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := find_anim_player(child)
		if found != null:
			return found
	return null


static func resolve_locomotion_anim(anim_player: AnimationPlayer, mesh_id: String) -> String:
	var def := get_mesh_def(mesh_id)
	var preferred := str(def.get("locomotion_anim", ""))
	if preferred != "" and anim_player.has_animation(preferred):
		return preferred
	for candidate in ["Walk", "Walking", "Run", "Animation", "Idle"]:
		if anim_player.has_animation(candidate):
			return candidate
	var names := anim_player.get_animation_list()
	return names[0] if not names.is_empty() else ""


static func uses_humanoid_punch(mesh_id: String) -> bool:
	return bool(get_mesh_def(mesh_id).get("uses_humanoid_punch", false))


static func get_eye_global_position(skeleton: Skeleton3D, fallback: Vector3) -> Vector3:
	if skeleton == null:
		return fallback
	for bone_name in ["Skeleton_neck_joint_2", "Skeleton_neck_joint_1", "Head", "head", "neck"]:
		var bone_idx := skeleton.find_bone(bone_name)
		if bone_idx >= 0:
			var head_pose := skeleton.get_bone_global_pose(bone_idx)
			var eye_local := head_pose.origin + head_pose.basis * Vector3(0.04, 0.1, -0.05)
			return skeleton.global_transform * eye_local
	return fallback