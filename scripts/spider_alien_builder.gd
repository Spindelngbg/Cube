class_name SpiderAlienBuilder
extends Node3D

const SEGMENTS := 16

static var _pupil_material: StandardMaterial3D
static var _sclera_material: StandardMaterial3D


static func build(parent: Node3D, data: AvatarData) -> void:
	for child in parent.get_children():
		child.queue_free()
	_ensure_materials()
	_build_skeleton(parent, data)


static func _ensure_materials() -> void:
	if _pupil_material == null:
		_pupil_material = StandardMaterial3D.new()
		_pupil_material.albedo_color = Color(0.02, 0.0, 0.0)
		_pupil_material.emission_enabled = true
		_pupil_material.emission = Color(0.08, 0.0, 0.02)
		_pupil_material.emission_energy_multiplier = 0.4
	if _sclera_material == null:
		_sclera_material = StandardMaterial3D.new()
		_sclera_material.albedo_color = Color(0.08, 0.03, 0.04)
		_sclera_material.roughness = 0.35
		_sclera_material.metallic = 0.1
		_sclera_material.rim_enabled = true
		_sclera_material.rim = 0.5


static func _build_skeleton(root: Node3D, data: AvatarData) -> void:
	var body_mat := _chitin_material(data.body_color, data.chitin_roughness, data.chitin_metallic)
	var accent_mat := _chitin_material(data.accent_color, data.chitin_roughness * 0.75, data.chitin_metallic + 0.12)
	var glow_mat := _glow_material(data.eye_color, data.glow_color, data.glow_strength)
	var spike_rng := _spike_rng(data)

	var hips := _part("Hips", root, Vector3.ZERO)
	var torso := _capsule_part(
		"Torso",
		hips,
		Vector3(0, 1.05 * data.body_scale, 0),
		Vector3(0.58, 0.78, 0.45) * data.body_scale,
		body_mat
	)
	_spikes_on(torso, data, accent_mat, spike_rng)

	var abdomen := _sphere_part(
		"Abdomen",
		hips,
		Vector3(0, 0.72 * data.body_scale, -0.44 * data.abdomen_scale),
		Vector3(0.66, 0.76, 0.88) * data.abdomen_scale,
		accent_mat
	)
	_abdomen_segments(abdomen, data, body_mat)
	_spikes_on(abdomen, data, body_mat, spike_rng)

	var head_pivot := _part("HeadPivot", hips, Vector3(0, 1.58 * data.body_scale, 0.1))
	var head := _sphere_part(
		"Head",
		head_pivot,
		Vector3.ZERO,
		Vector3(0.38, 0.34, 0.36) * data.head_scale,
		body_mat
	)
	_build_crest(head, data, accent_mat, spike_rng)
	_build_eyes(head, data, glow_mat)
	_build_mandibles(head_pivot, data, accent_mat)
	_build_fangs(head_pivot, data, accent_mat)
	_build_pedipalps(head_pivot, data, body_mat)

	_build_biped_leg(hips, data, body_mat, true)
	_build_biped_leg(hips, data, body_mat, false)
	_build_spider_legs(hips, data, body_mat, accent_mat)


static func _build_eyes(head: Node3D, data: AvatarData, glow_mat: StandardMaterial3D) -> void:
	var eye_root := _part("Eyes", head, Vector3(0, 0.06 * data.head_scale, -0.3 * data.head_scale))
	var count := clampi(data.eye_count, 2, 12)
	var rows := clampi(int(ceil(count / 3.0)), 1, 4)

	for i in count:
		var row := i % rows
		var col := i // rows
		var cols_in_row := int(ceil(float(count) / float(rows)))
		var t := float(col) / maxf(float(cols_in_row - 1), 1.0)
		var angle := lerpf(-0.85, 0.85, t) * data.eye_spread
		var height := lerpf(0.16, -0.1, float(row) / maxf(float(rows - 1), 1.0))
		var depth := 0.04 + absf(angle) * 0.06
		var offset := Vector3(sin(angle) * 0.2 * data.eye_spread, height, -depth)

		var stalk_pivot := _part("EyeStalk%d" % i, eye_root, offset)
		var stalk_h := data.eye_stalk_length * 0.22
		if stalk_h > 0.03:
			stalk_pivot.rotation_degrees = Vector3(-12 + row * 8, rad_to_deg(angle) * 0.35, 0)
			_capsule_part(
				"Stalk",
				stalk_pivot,
				Vector3(0, stalk_h * 0.5, 0),
				Vector3(0.05, stalk_h, 0.05),
				_sclera_material
			)

		var eye_center := Vector3(0, stalk_h, 0)
		var eye_radius := 0.11 * data.eye_size
		_sphere_part("Sclera%d" % i, stalk_pivot, eye_center, Vector3.ONE * eye_radius, _sclera_material)
		_sphere_part(
			"Iris%d" % i,
			stalk_pivot,
			eye_center + Vector3(0, 0, -eye_radius * 0.42),
			Vector3(0.82, 0.82, 0.28) * eye_radius,
			glow_mat
		)
		_sphere_part(
			"Pupil%d" % i,
			stalk_pivot,
			eye_center + Vector3(0, 0, -eye_radius * 0.52),
			Vector3(0.38, 0.55, 0.18) * eye_radius,
			_pupil_material
		)


static func _build_crest(head: Node3D, data: AvatarData, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	if data.crest_size <= 0.03:
		return
	var crest_count := int(lerp(2, 7, data.crest_size))
	for i in crest_count:
		var crest := _part("Crest%d" % i, head, Vector3.ZERO)
		crest.rotation_degrees = Vector3(
			rng.randf_range(-18, 18),
			rng.randf_range(-70, 70),
			rng.randf_range(-12, 12)
		)
		_capsule_part(
			"CrestMesh",
			crest,
			Vector3(0, 0.14 + data.crest_size * 0.08, 0),
			Vector3(0.03, 0.14 + data.crest_size * 0.12, 0.03),
			mat
		)


static func _abdomen_segments(abdomen: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.abdomen_segments <= 0.04:
		return
	var ring_count := int(lerp(2, 6, data.abdomen_segments))
	for i in ring_count:
		var t := float(i + 1) / float(ring_count + 1)
		var ring := _part("AbdomenRing%d" % i, abdomen, Vector3(0, lerpf(0.18, -0.22, t), lerpf(-0.05, 0.12, t)))
		ring.rotation_degrees = Vector3(90, 0, 0)
		_torus_part("RingMesh", ring, Vector3.ZERO, 0.34 + t * 0.08, 0.025, mat)


static func _build_fangs(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.fang_length <= 0.05:
		return
	for side in [-1, 1]:
		var base := _part("FangBase%d" % side, head_pivot, Vector3(0.05 * side, -0.04, -0.24))
		base.rotation_degrees = Vector3(35, 8 * side, 12 * side)
		_capsule_part(
			"Fang",
			base,
			Vector3(0, -0.1 * data.fang_length, -0.06 * data.fang_length),
			Vector3(0.035, 0.18, 0.035) * data.fang_length,
			mat
		)


static func _build_pedipalps(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	for side in [-1, 1]:
		var base := _part("Pedipalp%d" % side, head_pivot, Vector3(0.16 * side * data.stance_width, 0.02, -0.14))
		base.rotation_degrees = Vector3(-8, 18 * side, 28 * side)
		var upper := _capsule_part("Upper", base, Vector3(0.08 * side, 0, -0.04), Vector3(0.05, 0.2, 0.05), mat)
		upper.rotation_degrees = Vector3(10, 0, 35 * side)
		var lower := _capsule_part("Lower", upper, Vector3(0.12 * side, -0.02, -0.08), Vector3(0.04, 0.18, 0.04), mat)
		lower.rotation_degrees = Vector3(0, 0, -25 * side)


static func _build_mandibles(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.mandible_length <= 0.05:
		return
	for side in [-1, 1]:
		var base := _part("MandibleBase%d" % side, head_pivot, Vector3(0.1 * side, -0.1, -0.2))
		base.rotation_degrees = Vector3(12, 0, 22 * side)
		var seg := _capsule_part(
			"Mandible",
			base,
			Vector3(0, -0.14 * data.mandible_length, -0.1 * data.mandible_length),
			Vector3(0.05, 0.2, 0.05) * data.mandible_length,
			mat
		)
		seg.rotation_degrees = Vector3(28, 0, 0)
		if data.claw_size > 0.05:
			_capsule_part(
				"MandibleClaw",
				seg,
				Vector3(0, -0.16 * data.mandible_length, -0.04),
				Vector3(0.03, 0.08, 0.03) * data.claw_size,
				mat
			)


static func _build_biped_leg(hips: Node3D, data: AvatarData, mat: StandardMaterial3D, left: bool) -> void:
	var side := -1.0 if left else 1.0
	var hip := _part("Hip%d" % int(left), hips, Vector3(0.24 * side * data.stance_width, 0.95 * data.body_scale, 0))
	var thigh := _capsule_part("Thigh", hip, Vector3(0, -0.34 * data.leg_length, 0), Vector3(0.12, 0.36, 0.12) * data.leg_length, mat)
	_joint_bulge(thigh, Vector3(0, -0.18 * data.leg_length, 0), 0.09, mat)
	var knee := _part("Knee", thigh, Vector3(0, -0.34 * data.leg_length, 0))
	var shin := _capsule_part("Shin", knee, Vector3(0, -0.34 * data.leg_length, 0), Vector3(0.1, 0.36, 0.1) * data.leg_length, mat)
	var foot := _capsule_part("Foot", shin, Vector3(0, -0.34 * data.leg_length, 0.1), Vector3(0.11, 0.07, 0.2), mat)
	foot.rotation_degrees = Vector3(14, 0, 0)


static func _build_spider_legs(hips: Node3D, data: AvatarData, mat: StandardMaterial3D, claw_mat: StandardMaterial3D) -> void:
	var count := clampi(data.spider_leg_count, 4, 12)
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := float(i >> 1) / maxf(float(count) * 0.5 - 1.0, 1.0)
		var socket := _part(
			"SpiderLeg%d" % i,
			hips,
			Vector3(0.36 * side * data.stance_width, 0.52 - row * 0.17, -0.14 - row * 0.22)
		)
		socket.rotation_degrees = Vector3(-34 + row * 16, 28 * side, 38 * side)
		var upper := _capsule_part("Upper", socket, Vector3(0.26 * side, -0.02, 0), Vector3(0.055, 0.26, 0.055) * data.arm_length, mat)
		upper.rotation_degrees = Vector3(0, 0, 68 * side)
		_joint_bulge(upper, Vector3(0.12 * side, -0.04, 0), 0.06, mat)
		var lower := _capsule_part("Lower", upper, Vector3(0.3 * side, -0.1, 0.05), Vector3(0.04, 0.24, 0.04) * data.arm_length, mat)
		lower.rotation_degrees = Vector3(0, 0, -42 * side)
		if data.claw_size > 0.05:
			for claw_i in 2:
				var claw := _part("Claw%d" % claw_i, lower, Vector3(0.14 * side, -0.2 * data.arm_length, 0.02 * claw_i))
				claw.rotation_degrees = Vector3(0, 0, (30 + claw_i * 18) * side)
				_capsule_part("ClawMesh", claw, Vector3(0, -0.05 * data.claw_size, 0), Vector3(0.02, 0.08, 0.02) * data.claw_size, claw_mat)


static func _joint_bulge(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	_sphere_part("Joint", parent, pos, Vector3.ONE * radius, mat)


static func _spikes_on(node: Node3D, data: AvatarData, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	if data.spike_amount <= 0.02:
		return
	var spike_count := int(lerp(2, SEGMENTS, data.spike_amount))
	for i in spike_count:
		var spike := _part("Spike%d" % i, node, Vector3.ZERO)
		spike.rotation_degrees = Vector3(
			rng.randf_range(-35, 35),
			rng.randf_range(0, 360),
			rng.randf_range(-35, 35)
		)
		_capsule_part(
			"SpikeMesh",
			spike,
			Vector3(0, 0.14 + data.spike_amount * 0.08, 0),
			Vector3(0.028, 0.14 + data.spike_amount * 0.1, 0.028),
			mat
		)


static func _spike_rng(data: AvatarData) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(JSON.stringify(data.to_dict()))
	return rng


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


static func _torus_part(name: String, parent: Node3D, pos: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - thickness, 0.01)
	torus.outer_radius = radius + thickness
	mesh.mesh = torus
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


static func _chitin_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.rim_enabled = true
	mat.rim = 0.55
	mat.rim_tint = 0.55
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.25
	return mat


static func _glow_material(eye: Color, glow: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = eye
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 2.0 + strength * 4.0
	return mat