class_name SpiderAlienBuilder
extends Node3D

const SEGMENTS := 20

static var _pupil_material: StandardMaterial3D
static var _sclera_material: StandardMaterial3D
static var _mouth_material: StandardMaterial3D


static func build(parent: Node3D, data: AvatarData) -> void:
	for child in parent.get_children():
		child.queue_free()
	_ensure_materials()
	_build_skeleton(parent, data)


static func _ensure_materials() -> void:
	if _pupil_material == null:
		_pupil_material = StandardMaterial3D.new()
		_pupil_material.albedo_color = Color(0.01, 0.0, 0.0)
		_pupil_material.emission_enabled = true
		_pupil_material.emission = Color(0.12, 0.0, 0.04)
		_pupil_material.emission_energy_multiplier = 0.6
	if _sclera_material == null:
		_sclera_material = StandardMaterial3D.new()
		_sclera_material.albedo_color = Color(0.06, 0.02, 0.03)
		_sclera_material.roughness = 0.28
		_sclera_material.metallic = 0.18
		_sclera_material.rim_enabled = true
		_sclera_material.rim = 0.65
	if _mouth_material == null:
		_mouth_material = StandardMaterial3D.new()
		_mouth_material.albedo_color = Color(0.02, 0.0, 0.01)
		_mouth_material.emission_enabled = true
		_mouth_material.emission = Color(0.25, 0.02, 0.05)
		_mouth_material.emission_energy_multiplier = 0.35


static func _build_skeleton(root: Node3D, data: AvatarData) -> void:
	var body_mat := _chitin_material(data.body_color, data.chitin_roughness, data.chitin_metallic)
	var accent_mat := _chitin_material(data.accent_color, data.chitin_roughness * 0.7, data.chitin_metallic + 0.15)
	var wet_mat := _wet_chitin_material(data.accent_color.darkened(0.35))
	var glow_mat := _glow_material(data.eye_color, data.glow_color, data.glow_strength)
	var vein_mat := _vein_material(data.glow_color, data.glow_strength)
	var spike_rng := _spike_rng(data)

	var hips := _part("Hips", root, Vector3.ZERO)
	var torso := _capsule_part(
		"Torso",
		hips,
		Vector3(0, 1.05 * data.body_scale, 0),
		Vector3(0.58, 0.82, 0.48) * data.body_scale,
		body_mat
	)
	_exoskeleton_plates(torso, data, accent_mat, spike_rng, Vector3(0, 0.1, 0))
	_spikes_on(torso, data, accent_mat, spike_rng)

	var abdomen := _sphere_part(
		"Abdomen",
		hips,
		Vector3(0, 0.68 * data.body_scale, -0.48 * data.abdomen_scale),
		Vector3(0.7, 0.8, 0.95) * data.abdomen_scale,
		accent_mat
	)
	_abdomen_segments(abdomen, data, body_mat)
	_exoskeleton_plates(abdomen, data, body_mat, spike_rng, Vector3(0, 0, 0.08))
	_spikes_on(abdomen, data, body_mat, spike_rng)
	_dorsal_spine(hips, data, accent_mat, spike_rng)

	var head_pivot := _part("HeadPivot", hips, Vector3(0, 1.58 * data.body_scale, 0.08))
	var head := _sphere_part(
		"Head",
		head_pivot,
		Vector3.ZERO,
		Vector3(0.4, 0.36, 0.38) * data.head_scale,
		body_mat
	)
	_carapace_shell(head_pivot, head, data, accent_mat)
	_build_crest(head, data, accent_mat, spike_rng)
	_sensory_tendrils(head, data, accent_mat, spike_rng)
	_build_eyes(head, data, glow_mat)
	_build_mouth_cavity(head_pivot, data, wet_mat)
	_build_mandibles(head_pivot, data, accent_mat)
	_build_fangs(head_pivot, data, accent_mat, wet_mat)
	_build_pedipalps(head_pivot, data, body_mat)
	_throat_sac(head_pivot, data, accent_mat)

	_bioluminescent_markings(hips, torso, abdomen, data, vein_mat)
	_build_biped_leg(hips, data, body_mat, true)
	_build_biped_leg(hips, data, body_mat, false)
	_build_spider_legs(hips, data, body_mat, accent_mat)


static func _build_eyes(head: Node3D, data: AvatarData, glow_mat: StandardMaterial3D) -> void:
	var eye_root := _part("Eyes", head, Vector3(0, 0.05 * data.head_scale, -0.32 * data.head_scale))
	var count := clampi(data.eye_count, 2, 12)
	var rows := clampi(int(ceil(count / 3.0)), 1, 4)

	for i in count:
		var row := i % rows
		var col := int(i / rows)
		var cols_in_row := int(ceil(float(count) / float(rows)))
		var t := float(col) / maxf(float(cols_in_row - 1), 1.0)
		var angle := lerpf(-0.95, 0.95, t) * data.eye_spread
		var height := lerpf(0.18, -0.12, float(row) / maxf(float(rows - 1), 1.0))
		var depth := 0.05 + absf(angle) * 0.08
		var offset := Vector3(sin(angle) * 0.22 * data.eye_spread, height, -depth)

		var stalk_pivot := _part("EyeStalk%d" % i, eye_root, offset)
		var stalk_h := data.eye_stalk_length * 0.28
		if stalk_h > 0.03:
			stalk_pivot.rotation_degrees = Vector3(-16 + row * 10, rad_to_deg(angle) * 0.4, randf_range(-4.0, 4.0))
			_capsule_part(
				"Stalk",
				stalk_pivot,
				Vector3(0, stalk_h * 0.5, 0),
				Vector3(0.045, stalk_h, 0.045),
				_sclera_material
			)

		var eye_center := Vector3(0, stalk_h, 0)
		var eye_radius := 0.12 * data.eye_size
		_sphere_part("Sclera%d" % i, stalk_pivot, eye_center, Vector3.ONE * eye_radius, _sclera_material)
		_sphere_part(
			"Iris%d" % i,
			stalk_pivot,
			eye_center + Vector3(0, 0, -eye_radius * 0.44),
			Vector3(0.88, 0.88, 0.32) * eye_radius,
			glow_mat
		)
		_box_part(
			"Pupil%d" % i,
			stalk_pivot,
			eye_center + Vector3(0, 0, -eye_radius * 0.56),
			Vector3(0.12, 0.72, 0.08) * eye_radius,
			_pupil_material
		)

		if count >= 6:
			for micro in 3:
				var micro_angle := angle + lerpf(-0.35, 0.35, float(micro) / 2.0)
				var micro_pos := eye_center + Vector3(
					sin(micro_angle) * eye_radius * 0.55,
					cos(micro_angle) * eye_radius * 0.25,
					-eye_radius * 0.35
				)
				_sphere_part(
					"MicroEye%d_%d" % [i, micro],
					stalk_pivot,
					micro_pos,
					Vector3.ONE * eye_radius * 0.22,
					glow_mat
				)


static func _build_mouth_cavity(head_pivot: Node3D, data: AvatarData, wet_mat: StandardMaterial3D) -> void:
	if data.mandible_length <= 0.08:
		return

	_sphere_part(
		"MouthCavity",
		head_pivot,
		Vector3(0, -0.1, -0.24),
		Vector3(0.16, 0.11, 0.14) * data.head_scale,
		_mouth_material
	)

	var tooth_count := int(lerp(4, 10, clampf(data.mandible_length / 2.0, 0.0, 1.0)))
	for i in tooth_count:
		var t := float(i) / maxf(float(tooth_count - 1), 1.0)
		var angle := lerpf(-0.75, 0.75, t)
		var tooth := _part("Tooth%d" % i, head_pivot, Vector3.ZERO)
		tooth.position = Vector3(sin(angle) * 0.1, -0.12, -0.28)
		tooth.rotation_degrees = Vector3(18, rad_to_deg(angle) * 18, 0)
		_capsule_part("ToothMesh", tooth, Vector3(0, 0, -0.03), Vector3(0.018, 0.05, 0.018), wet_mat)


static func _carapace_shell(head_pivot: Node3D, head: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	var shell := _sphere_part(
		"Carapace",
		head_pivot,
		Vector3(0, 0.14 * data.head_scale, 0.04),
		Vector3(0.52, 0.3, 0.5) * data.head_scale,
		mat
	)
	shell.rotation_degrees = Vector3(-12, 0, 0)

	for i in 3:
		var ridge := _part("CarapaceRidge%d" % i, head, Vector3(0, 0.08 + i * 0.04, 0.06 - i * 0.02))
		ridge.rotation_degrees = Vector3(-20 - i * 8, 0, 0)
		_capsule_part(
			"RidgeMesh",
			ridge,
			Vector3(0, 0.06, 0),
			Vector3(0.035, 0.1 + data.crest_size * 0.06, 0.03),
			mat
		)


static func _sensory_tendrils(head: Node3D, data: AvatarData, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	if data.crest_size <= 0.05:
		return

	var tendril_count := int(lerp(2, 6, data.crest_size))
	for i in tendril_count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var tendril := _part("Tendril%d" % i, head, Vector3(0.18 * side, 0.1, -0.08))
		tendril.rotation_degrees = Vector3(
			rng.randf_range(-25, 25),
			35 * side,
			rng.randf_range(-20, 20)
		)
		var seg_a := _capsule_part("SegA", tendril, Vector3(0, 0.08, -0.06), Vector3(0.02, 0.14, 0.02), mat)
		seg_a.rotation_degrees = Vector3(12, 0, 8 * side)
		var seg_b := _capsule_part("SegB", seg_a, Vector3(0, 0.12, -0.08), Vector3(0.015, 0.12, 0.015), mat)
		seg_b.rotation_degrees = Vector3(-18, 0, -12 * side)
		_sphere_part("TendrilBulb", seg_b, Vector3(0, 0.1, -0.04), Vector3.ONE * 0.04, mat)


static func _throat_sac(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.abdomen_scale <= 0.7:
		return
	_sphere_part(
		"ThroatSac",
		head_pivot,
		Vector3(0, -0.18, -0.08),
		Vector3(0.12, 0.16, 0.14) * data.abdomen_scale,
		mat
	)


static func _dorsal_spine(hips: Node3D, data: AvatarData, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	if data.spike_amount <= 0.25:
		return

	var spine_count := int(lerp(3, 8, data.spike_amount))
	for i in spine_count:
		var t := float(i) / maxf(float(spine_count - 1), 1.0)
		var spine := _part("Spine%d" % i, hips, Vector3(0, 1.15 - t * 0.55, -0.2 - t * 0.35))
		spine.rotation_degrees = Vector3(-35 + rng.randf_range(-8, 8), rng.randf_range(-6, 6), 0)
		_capsule_part(
			"SpineMesh",
			spine,
			Vector3(0, 0.12 + data.spike_amount * 0.1, 0),
			Vector3(0.04, 0.18 + data.spike_amount * 0.14, 0.04),
			mat
		)


static func _exoskeleton_plates(
	parent: Node3D,
	data: AvatarData,
	mat: StandardMaterial3D,
	rng: RandomNumberGenerator,
	bias: Vector3
) -> void:
	if data.spike_amount <= 0.12:
		return

	var plate_count := int(lerp(3, 12, data.spike_amount))
	for i in plate_count:
		var plate := _part("Plate%d" % i, parent, bias)
		plate.rotation_degrees = Vector3(
			rng.randf_range(-55, 55),
			rng.randf_range(0, 360),
			rng.randf_range(-40, 40)
		)
		_box_part(
			"PlateMesh",
			plate,
			Vector3(0, 0.08, 0),
			Vector3(0.12 + data.spike_amount * 0.08, 0.04, 0.16),
			mat
		)


static func _bioluminescent_markings(
	hips: Node3D,
	torso: Node3D,
	abdomen: Node3D,
	data: AvatarData,
	vein_mat: StandardMaterial3D
) -> void:
	if data.glow_strength <= 0.15:
		return

	var vein_count := int(lerp(5, 18, data.glow_strength / 2.0))
	for i in vein_count:
		var host := [hips, torso, abdomen][i % 3]
		var vein := _part("Vein%d" % i, host, Vector3.ZERO)
		vein.rotation_degrees = Vector3(
			randf_range(-40, 40),
			randf_range(0, 360),
			randf_range(-30, 30)
		)
		_capsule_part(
			"VeinMesh",
			vein,
			Vector3(0, 0.1, 0),
			Vector3(0.012, 0.16 + data.glow_strength * 0.08, 0.012),
			vein_mat
		)

	var glow_nodes := int(lerp(2, 6, data.glow_strength / 2.0))
	for i in glow_nodes:
		var node := _part("GlowNode%d" % i, abdomen, Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-0.1, 0.2),
			randf_range(-0.15, 0.2)
		))
		_sphere_part("GlowBulb", node, Vector3.ZERO, Vector3.ONE * randf_range(0.04, 0.08), vein_mat)


static func _build_crest(head: Node3D, data: AvatarData, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	if data.crest_size <= 0.03:
		return
	var crest_count := int(lerp(2, 9, data.crest_size))
	for i in crest_count:
		var crest := _part("Crest%d" % i, head, Vector3.ZERO)
		crest.rotation_degrees = Vector3(
			rng.randf_range(-28, 28),
			rng.randf_range(-85, 85),
			rng.randf_range(-18, 18)
		)
		_capsule_part(
			"CrestMesh",
			crest,
			Vector3(0, 0.16 + data.crest_size * 0.1, 0),
			Vector3(0.035, 0.16 + data.crest_size * 0.14, 0.035),
			mat
		)


static func _abdomen_segments(abdomen: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.abdomen_segments <= 0.04:
		return
	var ring_count := int(lerp(3, 8, data.abdomen_segments))
	for i in ring_count:
		var t := float(i + 1) / float(ring_count + 1)
		var ring := _part("AbdomenRing%d" % i, abdomen, Vector3(0, lerpf(0.22, -0.28, t), lerpf(-0.08, 0.16, t)))
		ring.rotation_degrees = Vector3(90, 0, 0)
		_torus_part("RingMesh", ring, Vector3.ZERO, 0.36 + t * 0.1, 0.03, mat)
		if data.abdomen_segments > 0.45 and i % 2 == 0:
			_sphere_part(
				"SegmentNode",
				ring,
				Vector3(0, 0.05, 0.12),
				Vector3.ONE * 0.05,
				mat
			)


static func _build_fangs(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D, wet_mat: StandardMaterial3D) -> void:
	if data.fang_length <= 0.05:
		return
	for side in [-1, 1]:
		var base := _part("FangBase%d" % side, head_pivot, Vector3(0.06 * side, -0.05, -0.26))
		base.rotation_degrees = Vector3(42, 10 * side, 16 * side)
		var fang := _capsule_part(
			"Fang",
			base,
			Vector3(0, -0.12 * data.fang_length, -0.08 * data.fang_length),
			Vector3(0.04, 0.22, 0.04) * data.fang_length,
			mat
		)
		fang.rotation_degrees = Vector3(8, 0, 0)
		_capsule_part(
			"FangTip",
			fang,
			Vector3(0, -0.14 * data.fang_length, -0.04),
			Vector3(0.025, 0.08, 0.025) * data.fang_length,
			wet_mat
		)
		if data.fang_length > 0.6:
			_capsule_part(
				"SlimeDrip",
				fang,
				Vector3(0, -0.2 * data.fang_length, -0.02),
				Vector3(0.015, 0.1, 0.015),
				wet_mat
			)


static func _build_pedipalps(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	for side in [-1, 1]:
		var base := _part("Pedipalp%d" % side, head_pivot, Vector3(0.18 * side * data.stance_width, 0.02, -0.15))
		base.rotation_degrees = Vector3(-12, 22 * side, 32 * side)
		var upper := _capsule_part("Upper", base, Vector3(0.1 * side, 0, -0.05), Vector3(0.055, 0.24, 0.055), mat)
		upper.rotation_degrees = Vector3(12, 0, 38 * side)
		_joint_bulge(upper, Vector3(0.04 * side, -0.02, -0.02), 0.07, mat)
		var lower := _capsule_part("Lower", upper, Vector3(0.14 * side, -0.02, -0.1), Vector3(0.045, 0.2, 0.045), mat)
		lower.rotation_degrees = Vector3(0, 0, -28 * side)
		if data.claw_size > 0.05:
			_capsule_part(
				"PedipalpClaw",
				lower,
				Vector3(0.06 * side, -0.14, -0.04),
				Vector3(0.03, 0.1, 0.03) * data.claw_size,
				mat
			)


static func _build_mandibles(head_pivot: Node3D, data: AvatarData, mat: StandardMaterial3D) -> void:
	if data.mandible_length <= 0.05:
		return
	for side in [-1, 1]:
		var base := _part("MandibleBase%d" % side, head_pivot, Vector3(0.12 * side, -0.12, -0.22))
		base.rotation_degrees = Vector3(16, 0, 26 * side)
		var seg := _capsule_part(
			"Mandible",
			base,
			Vector3(0, -0.16 * data.mandible_length, -0.12 * data.mandible_length),
			Vector3(0.055, 0.24, 0.055) * data.mandible_length,
			mat
		)
		seg.rotation_degrees = Vector3(32, 0, 0)
		if data.claw_size > 0.05:
			for claw_i in 2:
				var claw := _part("MandibleClaw%d" % claw_i, seg, Vector3(0.03 * side, -0.18 * data.mandible_length, -0.05 - claw_i * 0.03))
				claw.rotation_degrees = Vector3(20, 0, (18 + claw_i * 14) * side)
				_capsule_part(
					"ClawMesh",
					claw,
					Vector3(0, -0.04 * data.claw_size, 0),
					Vector3(0.03, 0.1, 0.03) * data.claw_size,
					mat
				)


static func _build_biped_leg(hips: Node3D, data: AvatarData, mat: StandardMaterial3D, left: bool) -> void:
	var side := -1.0 if left else 1.0
	var hip := _part("Hip%d" % int(left), hips, Vector3(0.26 * side * data.stance_width, 0.95 * data.body_scale, 0))
	var thigh := _capsule_part("Thigh", hip, Vector3(0, -0.36 * data.leg_length, 0), Vector3(0.13, 0.38, 0.13) * data.leg_length, mat)
	_joint_bulge(thigh, Vector3(0, -0.18 * data.leg_length, 0), 0.1, mat)
	var knee := _part("Knee", thigh, Vector3(0, -0.36 * data.leg_length, 0))
	var shin := _capsule_part("Shin", knee, Vector3(0, -0.36 * data.leg_length, 0), Vector3(0.11, 0.38, 0.11) * data.leg_length, mat)
	_joint_bulge(shin, Vector3(0, -0.18 * data.leg_length, 0), 0.08, mat)
	var foot := _capsule_part("Foot", shin, Vector3(0, -0.36 * data.leg_length, 0.12), Vector3(0.12, 0.08, 0.22), mat)
	foot.rotation_degrees = Vector3(16, 0, 0)
	if data.claw_size > 0.2:
		for claw_i in 2:
			_capsule_part(
				"FootClaw%d" % claw_i,
				foot,
				Vector3(0.04 * side * claw_i, -0.04, 0.14),
				Vector3(0.025, 0.06, 0.025) * data.claw_size,
				mat
			)


static func _build_spider_legs(hips: Node3D, data: AvatarData, mat: StandardMaterial3D, claw_mat: StandardMaterial3D) -> void:
	var count := clampi(data.spider_leg_count, 4, 12)
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := float(i >> 1) / maxf(float(count) * 0.5 - 1.0, 1.0)
		var socket := _part(
			"SpiderLeg%d" % i,
			hips,
			Vector3(0.38 * side * data.stance_width, 0.5 - row * 0.18, -0.16 - row * 0.24)
		)
		socket.rotation_degrees = Vector3(-38 + row * 18, 32 * side, 42 * side)
		var upper := _capsule_part("Upper", socket, Vector3(0.28 * side, -0.02, 0), Vector3(0.06, 0.28, 0.06) * data.arm_length, mat)
		upper.rotation_degrees = Vector3(0, 0, 72 * side)
		_joint_bulge(upper, Vector3(0.14 * side, -0.05, 0), 0.07, mat)
		var mid := _capsule_part("Mid", upper, Vector3(0.32 * side, -0.12, 0.04), Vector3(0.05, 0.22, 0.05) * data.arm_length, mat)
		mid.rotation_degrees = Vector3(0, 0, -36 * side)
		var lower := _capsule_part("Lower", mid, Vector3(0.28 * side, -0.12, 0.06), Vector3(0.042, 0.26, 0.042) * data.arm_length, mat)
		lower.rotation_degrees = Vector3(0, 0, -48 * side)
		if data.claw_size > 0.05:
			for claw_i in 3:
				var claw := _part("Claw%d" % claw_i, lower, Vector3(0.16 * side, -0.22 * data.arm_length, 0.02 * (claw_i - 1)))
				claw.rotation_degrees = Vector3(0, 0, (24 + claw_i * 16) * side)
				_capsule_part("ClawMesh", claw, Vector3(0, -0.06 * data.claw_size, 0), Vector3(0.022, 0.1, 0.022) * data.claw_size, claw_mat)


static func _joint_bulge(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	_sphere_part("Joint", parent, pos, Vector3.ONE * radius, mat)


static func _spikes_on(node: Node3D, data: AvatarData, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	if data.spike_amount <= 0.02:
		return
	var spike_count := int(lerp(3, SEGMENTS, data.spike_amount))
	for i in spike_count:
		var spike := _part("Spike%d" % i, node, Vector3.ZERO)
		spike.rotation_degrees = Vector3(
			rng.randf_range(-45, 45),
			rng.randf_range(0, 360),
			rng.randf_range(-45, 45)
		)
		_capsule_part(
			"SpikeMesh",
			spike,
			Vector3(0, 0.16 + data.spike_amount * 0.1, 0),
			Vector3(0.03, 0.16 + data.spike_amount * 0.12, 0.03),
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


static func _box_part(name: String, parent: Node3D, pos: Vector3, scale: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = Vector3.ONE
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
	mat.rim = 0.62
	mat.rim_tint = 0.45
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.35
	mat.clearcoat_roughness = 0.4
	return mat


static func _wet_chitin_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.12
	mat.metallic = 0.25
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.85
	mat.emission_enabled = true
	mat.emission = color.lightened(0.15)
	mat.emission_energy_multiplier = 0.2
	return mat


static func _vein_material(glow: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glow.darkened(0.25)
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 1.2 + strength * 3.5
	mat.roughness = 0.2
	return mat


static func _glow_material(eye: Color, glow: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = eye
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 2.5 + strength * 5.0
	mat.roughness = 0.15
	return mat