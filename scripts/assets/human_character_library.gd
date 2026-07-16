class_name HumanCharacterLibrary
extends RefCounted

const HUMAN_SCENE_PATH := "res://assets/models/characters/reference_human.glb"
const BASE_HEIGHT_SCALE := 1.55


static func load_scene() -> PackedScene:
	if ResourceLoader.exists(HUMAN_SCENE_PATH):
		return load(HUMAN_SCENE_PATH) as PackedScene
	push_warning("Human model not found: %s" % HUMAN_SCENE_PATH)
	return null


static func spawn(
	parent: Node3D,
	position: Vector3 = Vector3.ZERO,
	rotation_y: float = 0.0,
	scale_factor: float = 1.0
) -> Node3D:
	var scene := load_scene()
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	instance.position = position
	instance.rotation.y = rotation_y
	instance.scale = Vector3.ONE * BASE_HEIGHT_SCALE * scale_factor
	parent.add_child(instance)
	return instance


static func apply_avatar_customization(root: Node, data: AvatarData) -> void:
	apply_skin_tone(root, data.body_color, 0.38)
	apply_outfit_tint(root, data.accent_color, 0.32)
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


static func apply_uniform_tint(root: Node, color: Color, strength: float = 0.55) -> void:
	_tint_meshes(root, color, clampf(strength, 0.0, 1.0), true)


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
			else:
				copy.albedo_color = copy.albedo_color.lerp(Color(0.92, 0.78, 0.62), 0.08)
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


static func get_eye_global_position(skeleton: Skeleton3D, fallback: Vector3) -> Vector3:
	if skeleton == null:
		return fallback
	var bone_idx := skeleton.find_bone("Skeleton_neck_joint_2")
	if bone_idx < 0:
		bone_idx = skeleton.find_bone("Skeleton_neck_joint_1")
	if bone_idx < 0:
		return fallback
	var head_pose := skeleton.get_bone_global_pose(bone_idx)
	var eye_local := head_pose.origin + head_pose.basis * Vector3(0.04, 0.1, -0.05)
	return skeleton.global_transform * eye_local