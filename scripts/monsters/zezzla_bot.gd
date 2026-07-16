class_name ZezzlaBot
extends CharacterBody3D

const ZezzlaBotLoreScript = preload("res://scripts/monsters/zezzla_bot_lore.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")
enum State { PATROL, STARE, SPEAK, LEAVE }

const MOVE_SPEED := 2.15
const LEAVE_SPEED := 3.4
const TURN_SPEED := 6.5
const WAYPOINT_REACH_M := 1.2
const STARE_RANGE := 9.5
const STARE_MIN := 2.4
const STARE_MAX := 4.2
const SPEAK_HOLD := 1.6
const LEAVE_MIN_DIST := 18.0
const ENCOUNTER_COOLDOWN := 28.0

const BODY_COLOR := Color(0.14, 0.18, 0.24)
const ZEZZLOR_BLUE := Color(0.12, 0.34, 0.82)
const EYE_CORE := Color(0.45, 0.72, 1.0)

var _rng := RandomNumberGenerator.new()
var _state := State.PATROL
var _roam_center := Vector3.ZERO
var _roam_half := Vector3(80.0, 0.0, 80.0)
var _waypoint := Vector3.ZERO
var _time := 0.0
var _state_timer := 0.0
var _encounter_cooldown := 0.0
var _stare_target: Node3D

var _chassis: Node3D
var _eye: MeshInstance3D
var _eye_mat: StandardMaterial3D
var _name_label: Label3D
var _wheels: Array[Node3D] = []


func setup(config: Dictionary) -> void:
	_rng.seed = int(config.get("seed", randi()))
	_time = _rng.randf_range(0.0, TAU)
	global_position = config.get("position", Vector3.ZERO)
	_roam_center = config.get("roam_center", global_position)
	_roam_half = config.get("roam_half", Vector3(80.0, 0.0, 80.0))
	set_meta("npc_id", str(config.get("npc_id", "zezzla_bot_%d" % get_instance_id())))
	set_meta("dialogue_voice", "sean")
	_build_bot()
	_build_collision()
	_build_name_label()
	_pick_waypoint()
	_state = State.PATROL
	set_physics_process(true)
	add_to_group("zezzla_bot")


func _physics_process(delta: float) -> void:
	_time += delta
	_encounter_cooldown = maxf(0.0, _encounter_cooldown - delta)
	_state_timer = maxf(0.0, _state_timer - delta)
	_animate_bot(delta)

	if not _is_simulation_authority():
		return

	match _state:
		State.PATROL:
			_tick_patrol(delta)
			_try_begin_stare()
		State.STARE:
			_tick_stare(delta)
		State.SPEAK:
			_tick_speak(delta)
		State.LEAVE:
			_tick_leave(delta)

	move_and_slide()
	global_position.y = _roam_center.y

	if multiplayer.multiplayer_peer != null:
		_sync_motion.rpc(global_position, rotation.y, _state, _get_eye_yaw())


func _tick_patrol(delta: float) -> void:
	_move_toward(_waypoint, MOVE_SPEED, delta)


func _tick_stare(delta: float) -> void:
	velocity = Vector3.ZERO
	if _stare_target == null or not is_instance_valid(_stare_target):
		_begin_leave()
		return
	_face_target(_stare_target, delta)
	if _state_timer <= 0.0:
		_begin_speak()


func _tick_speak(_delta: float) -> void:
	velocity = Vector3.ZERO
	if _stare_target != null and is_instance_valid(_stare_target):
		_face_target(_stare_target, 12.0 * _delta)
	if _state_timer <= 0.0:
		_begin_leave()


func _tick_leave(delta: float) -> void:
	_move_toward(_waypoint, LEAVE_SPEED, delta)
	var dist := global_position.distance_to(_waypoint)
	if dist < WAYPOINT_REACH_M or _state_timer <= 0.0:
		_return_to_patrol()


func _try_begin_stare() -> void:
	if _encounter_cooldown > 0.0:
		return
	var target := _find_nearest_player(STARE_RANGE)
	if target == null:
		return
	_stare_target = target
	_state = State.STARE
	_state_timer = _rng.randf_range(STARE_MIN, STARE_MAX)
	velocity = Vector3.ZERO


func _begin_speak() -> void:
	_state = State.SPEAK
	_state_timer = SPEAK_HOLD
	var line := ZezzlaBotLoreScript.pick_stare_line(_rng)
	NpcDialogueBarkScript.play_for_npc(self, "miscellaneous", "sean")
	if _stare_target != null and is_instance_valid(_stare_target) and _stare_target.is_multiplayer_authority():
		QuestManager.story_toast.emit(ZezzlaBotLoreScript.BOT_NAME, line)


func _begin_leave() -> void:
	_state = State.LEAVE
	_state_timer = 9.0
	_encounter_cooldown = ENCOUNTER_COOLDOWN
	_pick_leave_waypoint()
	_stare_target = null


func _return_to_patrol() -> void:
	_state = State.PATROL
	_pick_waypoint()
	_stare_target = null


func _move_toward(target_pos: Vector3, speed: float, delta: float) -> void:
	var to_target := target_pos - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist < WAYPOINT_REACH_M:
		if _state == State.PATROL:
			_pick_waypoint()
			to_target = _waypoint - global_position
			to_target.y = 0.0
			dist = to_target.length()
		else:
			velocity = Vector3.ZERO
			return

	if dist > 0.05:
		var dir := to_target / dist
		velocity = dir * speed
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
	else:
		velocity = Vector3.ZERO


func _face_target(target: Node3D, delta: float) -> void:
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		return
	var target_yaw := atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)


func _get_eye_yaw() -> float:
	if _stare_target == null or not is_instance_valid(_stare_target):
		return 0.0
	var local := to_local(_stare_target.global_position)
	return atan2(local.x, -local.z)


func _pick_waypoint() -> void:
	for _attempt in range(10):
		var offset := Vector3(
			_rng.randf_range(-_roam_half.x, _roam_half.x),
			0.0,
			_rng.randf_range(-_roam_half.z, _roam_half.z)
		)
		var candidate: Vector3 = _roam_center + offset
		if candidate.distance_to(global_position) > 10.0:
			_waypoint = candidate
			return
	_waypoint = _roam_center + Vector3(
		_rng.randf_range(-_roam_half.x, _roam_half.x),
		0.0,
		_rng.randf_range(-_roam_half.z, _roam_half.z)
	)


func _pick_leave_waypoint() -> void:
	var away := Vector3.ZERO
	if _stare_target != null and is_instance_valid(_stare_target):
		away = global_position - _stare_target.global_position
	away.y = 0.0
	if away.length_squared() < 0.25:
		away = Vector3(cos(rotation.y), 0.0, sin(rotation.y))
	var dir := away.normalized()
	var leave_multipliers: Array[float] = [LEAVE_MIN_DIST, LEAVE_MIN_DIST * 1.35, LEAVE_MIN_DIST * 0.75]
	for mult in leave_multipliers:
		var candidate: Vector3 = global_position + dir * mult
		candidate.x = clampf(candidate.x, _roam_center.x - _roam_half.x, _roam_center.x + _roam_half.x)
		candidate.z = clampf(candidate.z, _roam_center.z - _roam_half.z, _roam_center.z + _roam_half.z)
		if candidate.distance_to(global_position) > 8.0:
			_waypoint = candidate
			return
	_pick_waypoint()


func _find_nearest_player(max_range: float) -> Node3D:
	var best: Node3D = null
	var best_dist := max_range
	for node in get_tree().get_nodes_in_group("game_director"):
		if not node.get("players") is Dictionary:
			continue
		var roster: Dictionary = node.players
		for player in roster.values():
			if not (player is Node3D) or not is_instance_valid(player):
				continue
			if player.has_method("is_zezzlor_jailed") and player.is_zezzlor_jailed():
				continue
			var dist := global_position.distance_to((player as Node3D).global_position)
			if dist < best_dist:
				best_dist = dist
				best = player as Node3D
	return best


func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.72, 0.42, 0.92)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.22, 0.0)
	add_child(shape_node)
	collision_layer = 4
	collision_mask = 1


func _build_name_label() -> void:
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.text = ZezzlaBotLoreScript.BOT_NAME
	_name_label.font_size = 22
	_name_label.outline_size = 6
	_name_label.modulate = EYE_CORE
	_name_label.position = Vector3(0.0, 0.92, 0.0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	add_child(_name_label)


func _build_bot() -> void:
	_chassis = Node3D.new()
	_chassis.name = "Chassis"
	add_child(_chassis)

	var deck := _box("Deck", _chassis, Vector3(0.0, 0.16, 0.0), Vector3(0.62, 0.1, 0.82), BODY_COLOR)
	deck.material_override = _mat(BODY_COLOR, 0.0)

	var stripe := _box("Stripe", _chassis, Vector3(0.0, 0.22, 0.0), Vector3(0.64, 0.04, 0.14), ZEZZLOR_BLUE)
	stripe.material_override = _glow(ZEZZLOR_BLUE, 0.55)

	var dome := _box("Dome", _chassis, Vector3(0.0, 0.3, -0.08), Vector3(0.36, 0.16, 0.34), BODY_COLOR.lightened(0.06))
	dome.material_override = _mat(BODY_COLOR.lightened(0.06), 0.0)

	_eye = _box("Eye", _chassis, Vector3(0.0, 0.32, -0.28), Vector3(0.2, 0.12, 0.05), EYE_CORE)
	_eye_mat = _glow(EYE_CORE, 1.2)
	_eye.material_override = _eye_mat

	var pupil := _box("Pupil", _eye, Vector3(0.0, 0.0, 0.55), Vector3(0.35, 0.55, 0.2), Color(0.04, 0.08, 0.16))
	pupil.material_override = _mat(Color(0.04, 0.08, 0.16), 0.0)

	for side in [-1.0, 1.0]:
		var wheel_root := Node3D.new()
		wheel_root.name = "Wheel_%d" % int(side)
		wheel_root.position = Vector3(0.3 * side, 0.07, 0.22)
		_chassis.add_child(wheel_root)
		var wheel := _cylinder("Tire", wheel_root, Vector3.ZERO, Vector3(0.1, 0.04, 0.1), Color(0.08, 0.09, 0.1))
		wheel.rotation.z = PI * 0.5
		wheel.material_override = _mat(Color(0.08, 0.09, 0.1), 0.0)
		_wheels.append(wheel_root)

		var wheel_back := Node3D.new()
		wheel_back.name = "WheelBack_%d" % int(side)
		wheel_back.position = Vector3(0.3 * side, 0.07, -0.22)
		_chassis.add_child(wheel_back)
		var tire_back := _cylinder("Tire", wheel_back, Vector3.ZERO, Vector3(0.1, 0.04, 0.1), Color(0.08, 0.09, 0.1))
		tire_back.rotation.z = PI * 0.5
		tire_back.material_override = _mat(Color(0.08, 0.09, 0.1), 0.0)
		_wheels.append(wheel_back)


func _animate_bot(delta: float) -> void:
	if _chassis == null:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	var moving := speed > 0.25
	var stare := _state == State.STARE or _state == State.SPEAK
	var bob := sin(_time * 8.0) * 0.008 if moving else 0.0
	_chassis.position.y = bob

	if _eye:
		var target_yaw := _get_eye_yaw() if stare else 0.0
		_eye.rotation.y = lerp_angle(_eye.rotation.y, target_yaw, delta * (10.0 if stare else 4.0))

	if _eye_mat:
		var pulse := 1.35 if stare else 0.75
		if stare:
			pulse += sin(_time * 14.0) * 0.45
		else:
			pulse += sin(_time * 5.0) * 0.15
		_eye_mat.emission_energy_multiplier = pulse

	for wheel in _wheels:
		if wheel:
			wheel.rotation.x += speed * delta * 0.9


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


@rpc("any_peer", "unreliable")
func _sync_motion(pos: Vector3, yaw: float, state: int, eye_yaw: float) -> void:
	if _is_simulation_authority():
		return
	global_position = pos
	rotation.y = yaw
	_state = state as State
	if _eye:
		_eye.rotation.y = eye_yaw


func _box(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = BoxMesh.new()
	mesh.position = pos
	mesh.scale = scale
	parent.add_child(mesh)
	return mesh


func _cylinder(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	mesh.mesh = cylinder
	mesh.position = pos
	mesh.scale = scale
	parent.add_child(mesh)
	return mesh


func _mat(color: Color, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mat.metallic = 0.05
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat


func _glow(color: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = strength
	return mat