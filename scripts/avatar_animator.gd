class_name AvatarAnimator
extends Node

## Procedural idle / walk / attack animation for SpiderAlienBuilder skeletons.

var showcase_mode := false

var _root: Node3D
var _hips: Node3D
var _torso: Node3D
var _abdomen: Node3D
var _head_pivot: Node3D

var _biped_hips: Array[Node3D] = []
var _spider_sockets: Array[Node3D] = []
var _eye_stalks: Array[Node3D] = []
var _mandibles: Array[Node3D] = []
var _fangs: Array[Node3D] = []
var _pedipalps: Array[Node3D] = []
var _tendrils: Array[Node3D] = []
var _glow_meshes: Array[MeshInstance3D] = []

var _base_rotations: Dictionary = {}
var _base_positions: Dictionary = {}
var _glow_base_energy: Dictionary = {}

var _time := 0.0
var _move_blend := 0.0
var _attack_blend := 0.0
var _attack_timer := 0.0
var _moving := false
var _bound := false


static func ensure_on(pivot: Node3D, showcase := false) -> AvatarAnimator:
	var existing := pivot.get_node_or_null("AvatarAnimator") as AvatarAnimator
	if existing:
		existing.showcase_mode = showcase
		return existing
	var animator := AvatarAnimator.new()
	animator.name = "AvatarAnimator"
	animator.showcase_mode = showcase
	pivot.add_child(animator)
	return animator


func bind(root: Node3D) -> void:
	_reset_references()
	_root = root
	_hips = root.get_node_or_null("Hips") as Node3D
	if _hips == null:
		_bound = false
		return

	_torso = _hips.get_node_or_null("Torso") as Node3D
	_abdomen = _hips.get_node_or_null("Abdomen") as Node3D
	_head_pivot = _hips.get_node_or_null("HeadPivot") as Node3D

	for child in _hips.get_children():
		if child.name.begins_with("Hip") and child is Node3D:
			_biped_hips.append(child)
		elif child.name.begins_with("SpiderLeg") and child is Node3D:
			_spider_sockets.append(child)

	_collect_head_parts()
	_collect_glow_meshes(_hips)
	_cache_base_transforms()
	_bound = true
	_time = randf_range(0.0, TAU)


func set_moving(moving: bool) -> void:
	_moving = moving


func trigger_attack() -> void:
	_attack_timer = 0.58


func _reset_references() -> void:
	_biped_hips.clear()
	_spider_sockets.clear()
	_eye_stalks.clear()
	_mandibles.clear()
	_fangs.clear()
	_pedipalps.clear()
	_tendrils.clear()
	_glow_meshes.clear()
	_base_rotations.clear()
	_base_positions.clear()
	_glow_base_energy.clear()


func _collect_head_parts() -> void:
	if _head_pivot == null:
		return

	for child in _head_pivot.get_children():
		if child.name.begins_with("MandibleBase"):
			_mandibles.append(child)
		elif child.name.begins_with("FangBase"):
			_fangs.append(child)
		elif child.name.begins_with("Pedipalp"):
			_pedipalps.append(child)

	var head := _head_pivot.get_node_or_null("Head") as Node3D
	if head == null:
		return

	var eyes := head.get_node_or_null("Eyes") as Node3D
	if eyes:
		for stalk in eyes.get_children():
			if stalk.name.begins_with("EyeStalk"):
				_eye_stalks.append(stalk)

	for child in head.get_children():
		if child.name.begins_with("Tendril"):
			_tendrils.append(child)


func _collect_glow_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var mat := mesh.material_override as StandardMaterial3D
		if mat != null and mat.emission_enabled:
			_glow_meshes.append(mesh)
			_glow_base_energy[mesh] = mat.emission_energy_multiplier
	for child in node.get_children():
		_collect_glow_meshes(child)


func _cache_base_transforms() -> void:
	for node in _animated_nodes():
		if node == null or not is_instance_valid(node):
			continue
		_base_rotations[node] = node.rotation
		_base_positions[node] = node.position


func _animated_nodes() -> Array:
	var nodes: Array = [_hips, _torso, _abdomen, _head_pivot]
	nodes.append_array(_biped_hips)
	nodes.append_array(_spider_sockets)
	nodes.append_array(_eye_stalks)
	nodes.append_array(_mandibles)
	nodes.append_array(_fangs)
	nodes.append_array(_pedipalps)
	nodes.append_array(_tendrils)
	for hip in _biped_hips:
		if hip == null:
			continue
		var thigh := hip.get_node_or_null("Thigh") as Node3D
		if thigh == null:
			continue
		nodes.append(thigh)
		var knee := thigh.get_node_or_null("Knee") as Node3D
		if knee:
			nodes.append(knee)
			var shin := knee.get_node_or_null("Shin") as Node3D
			if shin:
				nodes.append(shin)
				var foot := shin.get_node_or_null("Foot") as Node3D
				if foot:
					nodes.append(foot)
	for socket in _spider_sockets:
		if socket == null:
			continue
		for part_name in ["Upper", "Mid", "Lower"]:
			var part := socket.get_node_or_null(part_name) as Node3D
			if part:
				nodes.append(part)
	return nodes


func _process(delta: float) -> void:
	if not _bound or _hips == null:
		return

	_time += delta

	var target_move := 0.0
	if showcase_mode:
		target_move = 0.42 + 0.58 * (0.5 + 0.5 * sin(_time * 0.62))
	elif _moving:
		target_move = 1.0
	_move_blend = lerpf(_move_blend, target_move, 8.5 * delta)

	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
		var t := 1.0 - (_attack_timer / 0.58)
		_attack_blend = sin(t * PI)
	else:
		_attack_blend = lerpf(_attack_blend, 0.0, 12.0 * delta)

	_apply_body_motion()
	_apply_head_motion()
	_apply_biped_legs()
	_apply_spider_legs()
	_apply_mouth()
	_apply_eyes()
	_apply_pedipalps()
	_apply_tendrils()
	_apply_glow_pulse()


func _apply_body_motion() -> void:
	var breath := sin(_time * 1.85) * 0.025
	var sway := sin(_time * 0.88) * 0.02 * (1.0 - _move_blend * 0.45)
	var bob := absf(sin(_time * 9.2)) * 0.06 * _move_blend

	if _hips:
		var hip_base: Vector3 = _base_positions.get(_hips, Vector3.ZERO)
		_hips.position = hip_base + Vector3(sway, breath * 0.55 - bob, 0.0)
		var hip_rot: Vector3 = _base_rotations.get(_hips, Vector3.ZERO)
		_hips.rotation = hip_rot + Vector3(
			deg_to_rad(sin(_time * 1.15) * 2.8 * (1.0 + _move_blend * 0.6)),
			0.0,
			deg_to_rad(sin(_time * 0.72) * 2.2)
		)

	if _torso:
		var base: Vector3 = _base_rotations.get(_torso, Vector3.ZERO)
		_torso.rotation = base + Vector3(
			deg_to_rad(3.2 * sin(_time * 2.05) + _move_blend * sin(_time * 9.0) * 5.0),
			0.0,
			deg_to_rad(2.4 * sin(_time * 1.35))
		)
		_torso.scale = Vector3.ONE * (1.0 + breath * 0.45)

	if _abdomen:
		var base: Vector3 = _base_rotations.get(_abdomen, Vector3.ZERO)
		_abdomen.rotation = base + Vector3(
			deg_to_rad(4.5 * sin(_time * 1.55 + 0.4)),
			deg_to_rad(3.5 * sin(_time * 0.82)),
			deg_to_rad(2.8 * sin(_time * 1.08))
		)


func _apply_head_motion() -> void:
	if _head_pivot == null:
		return

	var base: Vector3 = _base_rotations.get(_head_pivot, Vector3.ZERO)
	var look_x := sin(_time * 0.52) * 9.0
	var look_y := sin(_time * 0.36 + 1.1) * 13.0
	var attack_pitch := -26.0 * _attack_blend
	_head_pivot.rotation = base + Vector3(
		deg_to_rad(look_x + attack_pitch),
		deg_to_rad(look_y),
		deg_to_rad(sin(_time * 0.9) * 4.5)
	)


func _apply_biped_legs() -> void:
	for i in _biped_hips.size():
		var hip := _biped_hips[i]
		if hip == null:
			continue

		var side := -1.0 if i == 0 else 1.0
		var phase := _time * 9.8
		var swing := sin(phase + (0.0 if side < 0.0 else PI)) * 30.0 * _move_blend
		var hip_base: Vector3 = _base_rotations.get(hip, Vector3.ZERO)
		hip.rotation = hip_base + Vector3(
			deg_to_rad(swing * 0.38),
			0.0,
			deg_to_rad(swing * 0.14 * side)
		)

		var thigh := hip.get_node_or_null("Thigh") as Node3D
		if thigh:
			var tb: Vector3 = _base_rotations.get(thigh, Vector3.ZERO)
			thigh.rotation = tb + Vector3(deg_to_rad(swing), 0.0, 0.0)

		var knee := thigh.get_node_or_null("Knee") as Node3D if thigh else null
		if knee:
			var kb: Vector3 = _base_rotations.get(knee, Vector3.ZERO)
			var bend := maxf(0.0, sin(phase + (0.0 if side < 0.0 else PI))) * 38.0 * _move_blend
			knee.rotation = kb + Vector3(deg_to_rad(-bend + 10.0 * _move_blend), 0.0, 0.0)
			var shin := knee.get_node_or_null("Shin") as Node3D
			if shin:
				var sb: Vector3 = _base_rotations.get(shin, Vector3.ZERO)
				shin.rotation = sb + Vector3(deg_to_rad(bend * 0.45), 0.0, 0.0)


func _apply_spider_legs() -> void:
	for i in _spider_sockets.size():
		var socket := _spider_sockets[i]
		if socket == null:
			continue

		var side := -1.0 if i % 2 == 0 else 1.0
		var row := float(i >> 1)
		var phase := _time * 11.5 + row * 0.75 + (0.0 if side < 0.0 else PI * 0.45)
		var idle_wiggle := sin(_time * 2.35 + i * 0.42) * 7.0
		var walk_swing := sin(phase) * 24.0 * _move_blend
		var socket_base: Vector3 = _base_rotations.get(socket, Vector3.ZERO)
		socket.rotation = socket_base + Vector3(
			deg_to_rad(idle_wiggle + walk_swing * 0.65),
			deg_to_rad(walk_swing * 0.28 * side),
			deg_to_rad(idle_wiggle * 0.55 * side + walk_swing * 0.42 * side)
		)

		var upper := socket.get_node_or_null("Upper") as Node3D
		if upper:
			var ub: Vector3 = _base_rotations.get(upper, Vector3.ZERO)
			upper.rotation = ub + Vector3(0.0, 0.0, deg_to_rad(sin(phase) * 20.0 * _move_blend * side))

		var mid := upper.get_node_or_null("Mid") as Node3D if upper else null
		if mid:
			var mb: Vector3 = _base_rotations.get(mid, Vector3.ZERO)
			mid.rotation = mb + Vector3(0.0, 0.0, deg_to_rad(sin(phase + 0.5) * 14.0 * _move_blend * side))


func _apply_mouth() -> void:
	var chew := (0.5 + 0.5 * sin(_time * 4.8)) * 14.0
	var attack_open := 42.0 * _attack_blend

	for mand in _mandibles:
		var base: Vector3 = _base_rotations.get(mand, Vector3.ZERO)
		var side := 1.0 if mand.position.x >= 0.0 else -1.0
		var open := chew + attack_open
		mand.rotation = base + Vector3(deg_to_rad(open), 0.0, deg_to_rad(open * 0.45 * side))

	for fang in _fangs:
		var base: Vector3 = _base_rotations.get(fang, Vector3.ZERO)
		fang.rotation = base + Vector3(deg_to_rad(attack_open * 0.7), 0.0, 0.0)


func _apply_eyes() -> void:
	for i in _eye_stalks.size():
		var stalk := _eye_stalks[i]
		var base: Vector3 = _base_rotations.get(stalk, Vector3.ZERO)
		var wobble := sin(_time * 2.9 + i * 0.68) * 11.0
		var scan := sin(_time * 0.44 + i * 0.32) * 7.0
		stalk.rotation = base + Vector3(
			deg_to_rad(wobble + scan),
			deg_to_rad(scan * 0.75),
			deg_to_rad(wobble * 0.35)
		)


func _apply_pedipalps() -> void:
	for palp in _pedipalps:
		var base: Vector3 = _base_rotations.get(palp, Vector3.ZERO)
		var side := 1.0 if palp.position.x >= 0.0 else -1.0
		var threat := sin(_time * 1.45) * 9.0 + _attack_blend * 28.0
		palp.rotation = base + Vector3(deg_to_rad(threat), 0.0, deg_to_rad(threat * 0.55 * side))


func _apply_tendrils() -> void:
	for i in _tendrils.size():
		var tendril := _tendrils[i]
		var base: Vector3 = _base_rotations.get(tendril, Vector3.ZERO)
		tendril.rotation = base + Vector3(
			deg_to_rad(sin(_time * 3.1 + i) * 15.0),
			deg_to_rad(sin(_time * 2.2 + i * 0.55) * 11.0),
			deg_to_rad(cos(_time * 2.8 + i) * 9.0)
		)


func _apply_glow_pulse() -> void:
	for mesh in _glow_meshes:
		if mesh == null or not is_instance_valid(mesh):
			continue
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			continue
		var base_energy: float = _glow_base_energy.get(mesh, mat.emission_energy_multiplier)
		var pulse := 0.82 + 0.18 * sin(_time * 3.6 + float(mesh.get_instance_id()) * 0.003)
		mat.emission_energy_multiplier = base_energy * pulse * (1.0 + _attack_blend * 0.65 + _move_blend * 0.12)