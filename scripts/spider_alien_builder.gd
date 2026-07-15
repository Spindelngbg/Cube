class_name SpiderAlienBuilder
extends Node3D

const SEGMENTS := 12


static func build(parent: Node3D, data: AvatarData) -> void:
	for child in parent.get_children():
		child.queue_free()
	_build_skeleton(parent, data)


static func _build_skeleton(root: Node3D, data: AvatarData) -> void:
	var body_mat := _chitin_material(data.body_color, data.chitin_roughness, data.chitin_metallic)
	var accent_mat := _chitin_material(data.accent_color, data.chitin_roughness * 0.8, data.chitin_metallic + 0.1)
	var glow_mat := _glow_material(data.eye_color, data.glow_color, data.glow_strength)

	var hips := _part("Hips", root, Vector3.ZERO)
	var torso := _capsule_part("Torso", hips, Vector3(0, 1.05 * data.body_scale, 0), Vector3(0.55, 0.75, 0.42) * data.body_scale, body_mat)
	_spikes_on(torso, data, accent_mat)

	var abdomen := _sphere_part("Abdomen", hips, Vector3(0, 0.75 * data.body_scale, -0.42 * data.abdomen_scale), Vector3(0.62, 0.72, 0.82) * data.abdomen_scale, accent_mat)
	_spikes_on(abdomen, data, body_mat)

	var head_pivot := _part("HeadPivot", hips, Vector3(0, 1.55 * data.body_scale, 0.08))
	var head := _sphere_part("Head", head_pivot, Vector3.ZERO, Vector3(0.34, 0.3, 0.34) * data.head_scale, body_mat)
	_build_eyes(head, data, glow_mat)
	_build_mandibles(head_pivot, data, accent_mat)

	_build_biped_leg(hips, data, body_mat, true)
	_build_biped_leg(hips, data, body_mat, false)
	_build_spider_legs(hips, data, body_mat)


static func _build_eyes(head: Node3D, data: AvatarData, glow_mat: StandardMaterial3D) -> void:
	var eye_root := _part("Eyes", head, Vector3(0, 0.04, -0.18 * data.head_scale))
	var count := clampi(data.eye_count, 2, 8)
	for i in count:
		var t := float(i) / float(count)
		var angle := t * TAU
		var ring := 0.14 if i % 2 == 0 else 0.08
		var offset := Vector3(cos(angle) * ring, sin(angle * 2.0) * 0.05, sin(angle) * ring * 0.35)
		_sphere_part("Eye%d" % i, eye_root, offset, Vector3.ONE * 0.07 * data.eye_size, glow_mat)


static func _build_mandibles(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.mandible_length <= 0.05:
		return
	for side in [-1, 1]:
		var base := _part("MandibleBase%d" % side, head_pivot, Vector3(0.08 * side, -0.08, -0.18))
		base.rotation_degrees = Vector3(10, 0, 18 * side)
		var seg := _capsule_part("Mandible", base, Vector3(0, -0.12 * data.mandible_length, -0.08), Vector3(0.04, 0.16, 0.04) * data.mandible_length, mat)
		seg.rotation_degrees = Vector3(25, 0, 0)


static func _build_biped_leg(hips: Node3D, data: AvatarData, mat: StandardMaterial3D, left: bool) -> void:
	var side := -1.0 if left else 1.0
	var hip := _part("Hip%d" % int(left), hips, Vector3(0.22 * side * data.stance_width, 0.95 * data.body_scale, 0))
	var thigh := _capsule_part("Thigh", hip, Vector3(0, -0.34 * data.leg_length, 0), Vector3(0.11, 0.34, 0.11) * data.leg_length, mat)
	var knee := _part("Knee", thigh, Vector3(0, -0.34 * data.leg_length, 0))
	var shin := _capsule_part("Shin", knee, Vector3(0, -0.34 * data.leg_length, 0), Vector3(0.09, 0.34, 0.09) * data.leg_length, mat)
	var foot := _capsule_part("Foot", shin, Vector3(0, -0.34 * data.leg_length, 0.08), Vector3(0.1, 0.06, 0.18), mat)
	foot.rotation_degrees = Vector3(12, 0, 0)


static func _build_spider_legs(hips: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	var count := clampi(data.spider_leg_count, 4, 8)
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := float(i >> 1) / maxf(float(count) * 0.5 - 1.0, 1.0)
		var socket := _part("SpiderLeg%d" % i, hips, Vector3(0.34 * side * data.stance_width, 0.55 - row * 0.18, -0.12 - row * 0.2))
		socket.rotation_degrees = Vector3(-30 + row * 18, 25 * side, 35 * side)
		var upper := _capsule_part("Upper", socket, Vector3(0.24 * side, -0.02, 0), Vector3(0.05, 0.24, 0.05) * data.arm_length, mat)
		upper.rotation_degrees = Vector3(0, 0, 65 * side)
		var lower := _capsule_part("Lower", upper, Vector3(0.28 * side, -0.08, 0.04), Vector3(0.035, 0.22, 0.035) * data.arm_length, mat)
		lower.rotation_degrees = Vector3(0, 0, -40 * side)


static func _spikes_on(node: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.spike_amount <= 0.02:
		return
	var spike_count := int(lerp(0, SEGMENTS, data.spike_amount))
	for i in spike_count:
		var spike := _part("Spike%d" % i, node, Vector3.ZERO)
		spike.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360), randf_range(-25, 25))
		_capsule_part("SpikeMesh", spike, Vector3(0, 0.12, 0), Vector3(0.025, 0.12, 0.025), mat)


static func _part(name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.position = pos
	parent.add_child(node)
	return node


static func _sphere_part(name: String, parent: Node3D, pos: Vector3, scale: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = SphereMesh.new()
	(mesh.mesh as SphereMesh).radius = 0.5
	(mesh.mesh as SphereMesh).height = 1.0
	mesh.position = pos
	mesh.scale = scale
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


static func _capsule_part(name: String, parent: Node3D, pos: Vector3, scale: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = CapsuleMesh.new()
	(mesh.mesh as CapsuleMesh).radius = 0.5
	(mesh.mesh as CapsuleMesh).height = 1.0
	mesh.position = pos
	mesh.scale = scale
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


static func _chitin_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.rim_enabled = true
	mat.rim = 0.35
	mat.rim_tint = 0.4
	return mat


static func _glow_material(eye: Color, glow: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = eye
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 1.5 + strength * 2.5
	return mat