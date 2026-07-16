class_name GleazerBuilder
extends RefCounted

const HumanCharacterLibraryScript = preload("res://scripts/assets/human_character_library.gd")
const GleazerLoreScript = preload("res://scripts/story/gleazer_lore.gd")

const SKIN := Color(0.94, 0.9, 0.86)
const SLIME_GREEN := Color(0.22, 0.92, 0.28)
const SLIME_TANK := Color(0.14, 0.48, 0.2)
const ANTENNA_BLUE := Color(0.28, 0.55, 0.98)
const BULGE_BROWN := Color(0.42, 0.28, 0.16)


static func build(parent: Node3D, role_id: String = "recruit", scale_factor: float = 1.0) -> Dictionary:
	for child in parent.get_children():
		if child.name in ["HumanAvatarAnimator", "AvatarAnimator", "ZnoodMount"]:
			continue
		child.queue_free()

	var model := HumanCharacterLibraryScript.spawn(parent, Vector3.ZERO, 0.0, scale_factor)
	if model == null:
		return {"root": null}

	var avatar := AvatarData.new()
	avatar.body_scale = scale_factor
	avatar.body_color = SKIN
	avatar.accent_color = GleazerLoreScript.role_color(role_id)
	avatar.glow_color = ANTENNA_BLUE
	avatar.glow_strength = 0.12
	HumanCharacterLibraryScript.apply_avatar_customization(model, avatar)

	var skeleton := HumanCharacterLibraryScript.find_skeleton(model)
	if skeleton != null:
		_attach_slime_blaster(skeleton)
		_attach_extra_arms(skeleton, scale_factor)
		_attach_head_antenna(skeleton, scale_factor)
		_attach_back_bulges(skeleton, scale_factor)

	return {"root": model, "skeleton": skeleton}


static func _attach_slime_blaster(skeleton: Skeleton3D) -> void:
	var socket := _bone_socket(skeleton, "Skeleton_arm_joint_R__2_")
	if socket == null:
		return
	var gun_root := Node3D.new()
	gun_root.name = "SlimeBlaster"
	gun_root.position = Vector3(0.08, -0.04, -0.18)
	gun_root.rotation_degrees = Vector3(-8.0, -90.0, 12.0)
	socket.add_child(gun_root)

	var body := _box(Vector3(0.0, 0.0, -0.22), Vector3(0.1, 0.14, 0.52), SLIME_TANK, 0.15)
	gun_root.add_child(body)
	var barrel := _box(Vector3(0.0, 0.02, -0.52), Vector3(0.07, 0.07, 0.34), SLIME_GREEN, 0.55)
	gun_root.add_child(barrel)
	var tank := _cyl(Vector3(0.12, -0.02, 0.02), Vector3(0.11, 0.2, 0.11), SLIME_GREEN, 0.4)
	gun_root.add_child(tank)
	var nozzle := _cyl(Vector3(0.0, 0.02, -0.72), Vector3(0.05, 0.08, 0.05), SLIME_GREEN, 0.85)
	gun_root.add_child(nozzle)


static func _attach_extra_arms(skeleton: Skeleton3D, scale: float) -> void:
	var torso := _bone_socket(skeleton, "Skeleton_torso_joint_2")
	if torso == null:
		torso = _bone_socket(skeleton, "Skeleton_torso_joint_1")
	if torso == null:
		return

	for side in [-1.0, 1.0]:
		var arm_root := Node3D.new()
		arm_root.name = "ExtraArm_%d" % int(side)
		arm_root.position = Vector3(0.34 * side * scale, -0.22 * scale, 0.06 * scale)
		arm_root.rotation_degrees = Vector3(18.0, 12.0 * side, 28.0 * side)
		torso.add_child(arm_root)

		var upper := _cyl(Vector3(0.0, -0.12, -0.04), Vector3(0.07, 0.24, 0.07), SKIN.darkened(0.08), 0.0)
		arm_root.add_child(upper)
		var lower := _cyl(Vector3(0.05 * side, -0.28, -0.1), Vector3(0.06, 0.22, 0.06), SKIN.darkened(0.12), 0.0)
		lower.rotation_degrees = Vector3(-24.0, 0.0, 18.0 * side)
		arm_root.add_child(lower)
		var hand := _box(Vector3(0.08 * side, -0.38, -0.16), Vector3(0.08, 0.06, 0.1), SKIN.darkened(0.15), 0.0)
		arm_root.add_child(hand)


static func _attach_head_antenna(skeleton: Skeleton3D, scale: float) -> void:
	var head := _bone_socket(skeleton, "Skeleton_neck_joint_2")
	if head == null:
		head = _bone_socket(skeleton, "Skeleton_neck_joint_1")
	if head == null:
		return

	var rig := Node3D.new()
	rig.name = "AntennaRig"
	rig.position = Vector3(0.0, 0.18 * scale, 0.02 * scale)
	head.add_child(rig)

	var base_plate := _box(Vector3.ZERO, Vector3(0.2, 0.05, 0.16), ANTENNA_BLUE.darkened(0.2), 0.25)
	rig.add_child(base_plate)

	var mast := _cyl(Vector3(0.0, 0.22, 0.0), Vector3(0.04, 0.42, 0.04), ANTENNA_BLUE, 0.9)
	rig.add_child(mast)

	var tip := _box(Vector3(0.0, 0.48, 0.0), Vector3(0.08, 0.08, 0.08), ANTENNA_BLUE.lightened(0.15), 1.2)
	rig.add_child(tip)

	for side in [-1.0, 1.0]:
		var fin_root := Node3D.new()
		fin_root.position = Vector3(0.1 * side * scale, 0.08 * scale, 0.0)
		fin_root.rotation_degrees = Vector3(0.0, 0.0, 32.0 * side)
		rig.add_child(fin_root)
		var fin := _box(Vector3(0.06 * side, 0.0, 0.0), Vector3(0.14, 0.04, 0.08), ANTENNA_BLUE.darkened(0.15), 0.45)
		fin_root.add_child(fin)
		var graft := _cyl(Vector3(0.1 * side, -0.02, 0.02), Vector3(0.05, 0.1, 0.05), SKIN.darkened(0.18), 0.0)
		rig.add_child(graft)


static func _attach_back_bulges(skeleton: Skeleton3D, scale: float) -> void:
	var torso := _bone_socket(skeleton, "torso_joint_3")
	if torso == null:
		torso = _bone_socket(skeleton, "Skeleton_torso_joint_1")
	if torso == null:
		return

	var back := Node3D.new()
	back.name = "BackBulges"
	back.position = Vector3(0.0, 0.05 * scale, 0.14 * scale)
	torso.add_child(back)

	var bulge_specs := [
		{"pos": Vector3(-0.14, 0.08, 0.0), "scale": Vector3(0.16, 0.2, 0.14)},
		{"pos": Vector3(0.1, 0.14, 0.02), "scale": Vector3(0.2, 0.24, 0.16)},
		{"pos": Vector3(0.0, -0.06, 0.04), "scale": Vector3(0.22, 0.18, 0.15)},
		{"pos": Vector3(0.16, -0.02, -0.02), "scale": Vector3(0.12, 0.14, 0.12)},
	]
	for i in range(bulge_specs.size()):
		var spec: Dictionary = bulge_specs[i]
		var bulge := _cyl(spec.pos, spec.scale, BULGE_BROWN, 0.08)
		bulge.name = "Bulge_%d" % i
		back.add_child(bulge)


static func _bone_socket(skeleton: Skeleton3D, bone_name: String) -> BoneAttachment3D:
	var idx := skeleton.find_bone(bone_name)
	if idx < 0:
		return null
	var att := BoneAttachment3D.new()
	att.name = "Gleazer_%s" % bone_name
	att.bone_name = bone_name
	att.bone_idx = idx
	skeleton.add_child(att)
	return att


static func _box(pos: Vector3, size: Vector3, color: Color, emission: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = _mat(color, emission)
	return mesh


static func _cyl(pos: Vector3, size: Vector3, color: Color, emission: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	mesh.mesh = cyl
	mesh.position = pos
	mesh.scale = size
	mesh.material_override = _mat(color, emission)
	return mesh


static func _mat(color: Color, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.42
	mat.metallic = 0.18
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat