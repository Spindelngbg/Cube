extends CharacterBody3D

const LASER_SCENE := preload("res://scenes/combat/laser_projectile.tscn")
const ZezzlorBuilderScript = preload("res://scripts/monsters/zezzlor_builder.gd")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")

const RANK_ID := "superman"
const TURN_SPEED := 13.0
const GROUND_SPEED := 11.5
const STRAFE_SPEED := 9.0
const GRAVITY := 20.0
const LEAP_UP := 8.8
const LEAP_BOOST := 1.45
const VISION_RANGE := 58.0
const SHOOT_RANGE := 42.0
const SHOOT_MIN_RANGE := 4.5
const FIRE_COOLDOWN := 0.24
const LEAP_COOLDOWN_MIN := 0.55
const LEAP_COOLDOWN_MAX := 0.95

var _model_pivot: Node3D
var _name_label: Label3D
var _laser_socket: Node3D
var _avatar_animator: AvatarAnimator
var _patrol_center := Vector3.ZERO
var _patrol_radius := 45.0
var _wander_dir := Vector3.FORWARD
var _wander_timer := 0.0
var _target: Node3D
var _fire_cooldown := 0.0
var _leap_cooldown := 0.0
var _strafe_dir := 1.0
var _strafe_timer := 0.0
var _rng := RandomNumberGenerator.new()


func setup(
	spawn_pos: Vector3,
	patrol_center: Vector3,
	patrol_radius: float,
	personal_name: String = "Bruce",
	seed: int = 0
) -> void:
	_model_pivot = $ModelPivot
	_name_label = $NameLabel
	_rng.seed = seed if seed != 0 else hash(str(spawn_pos))
	position = spawn_pos
	_patrol_center = patrol_center
	_patrol_radius = patrol_radius
	_name_label.text = ZezzlorLoreScript.format_name(RANK_ID, personal_name)
	_name_label.modulate = ZezzlorLoreScript.rank_color(RANK_ID)
	_mount_model()
	_attach_laser_pistol()
	_pick_patrol_direction()
	_wander_timer = _rng.randf_range(0.4, 1.2)
	_strafe_dir = 1.0 if _rng.randf() > 0.5 else -1.0


func _physics_process(delta: float) -> void:
	if not _is_simulation_authority():
		return

	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_leap_cooldown = maxf(0.0, _leap_cooldown - delta)
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = _rng.randf_range(0.35, 0.85)
		if _rng.randf() < 0.42:
			_strafe_dir *= -1.0

	_target = _find_nearest_hybrid()
	if _target != null:
		var dist := _flat_distance_to(_target.global_position)
		if dist <= SHOOT_RANGE:
			_combat(delta, dist)
		else:
			_pursue(delta, dist)
	else:
		_patrol(delta)

	move_and_slide()
	_update_animation()
	if multiplayer.multiplayer_peer != null:
		_sync_state.rpc(position, rotation.y, velocity.length() > 0.6)


func _find_nearest_hybrid() -> Node3D:
	var best: Node3D = null
	var best_dist := VISION_RANGE
	for node in get_tree().get_nodes_in_group("world_monster"):
		if not node is Node3D:
			continue
		if not node.has_meta("is_src_hybrid") or not node.get_meta("is_src_hybrid"):
			continue
		if node.has_method("is_alive") and not node.is_alive():
			continue
		var dist := _flat_distance_to((node as Node3D).global_position)
		if dist < best_dist:
			best_dist = dist
			best = node as Node3D
	return best


func _pursue(delta: float, dist: float) -> void:
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		return
	var dir := to_target.normalized()
	_face_direction(dir, delta)

	if is_on_floor():
		if _leap_cooldown <= 0.0 and dist > 3.8:
			_do_leap(dir)
		else:
			velocity.y = 0.0
			velocity.x = dir.x * GROUND_SPEED
			velocity.z = dir.z * GROUND_SPEED
	else:
		_apply_air_move(dir, delta)

	if dist <= SHOOT_RANGE:
		_try_shoot()


func _combat(delta: float, dist: float) -> void:
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		return
	var dir := to_target.normalized()
	var side := Vector3(-dir.z, 0.0, dir.x) * _strafe_dir
	_face_direction(dir, delta)

	if is_on_floor():
		if _leap_cooldown <= 0.0 and dist > SHOOT_MIN_RANGE + 1.5:
			_do_leap(dir)
		else:
			velocity.y = 0.0
			velocity.x = side.x * STRAFE_SPEED + dir.x * 2.2
			velocity.z = side.z * STRAFE_SPEED + dir.z * 2.2
	else:
		_apply_air_move(dir, delta)

	_try_shoot()


func _patrol(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_patrol_direction()
		_wander_timer = _rng.randf_range(1.0, 2.4)

	var to_center := _patrol_center - global_position
	to_center.y = 0.0
	if to_center.length() > _patrol_radius:
		_wander_dir = to_center.normalized()
		_wander_timer = _rng.randf_range(0.6, 1.4)

	_face_direction(_wander_dir, delta)
	if is_on_floor():
		if _leap_cooldown <= 0.0 and _rng.randf() < 0.18:
			_do_leap(_wander_dir)
		else:
			velocity.y = 0.0
			velocity.x = _wander_dir.x * GROUND_SPEED * 0.55
			velocity.z = _wander_dir.z * GROUND_SPEED * 0.55
	else:
		_apply_air_move(_wander_dir, delta)


func _do_leap(dir: Vector3) -> void:
	velocity.y = LEAP_UP
	velocity.x = dir.x * GROUND_SPEED * LEAP_BOOST
	velocity.z = dir.z * GROUND_SPEED * LEAP_BOOST
	_leap_cooldown = _rng.randf_range(LEAP_COOLDOWN_MIN, LEAP_COOLDOWN_MAX)
	if _avatar_animator:
		_avatar_animator.trigger_attack()


func _apply_air_move(dir: Vector3, delta: float) -> void:
	velocity.y -= GRAVITY * delta
	velocity.x = lerpf(velocity.x, dir.x * GROUND_SPEED * 0.95, 4.0 * delta)
	velocity.z = lerpf(velocity.z, dir.z * GROUND_SPEED * 0.95, 4.0 * delta)


func _try_shoot() -> void:
	if _fire_cooldown > 0.0 or _target == null:
		return
	var dist := _flat_distance_to(_target.global_position)
	if dist > SHOOT_RANGE or dist < SHOOT_MIN_RANGE:
		return

	_fire_cooldown = FIRE_COOLDOWN
	var muzzle := _get_muzzle_position()
	var aim := _target.global_position + Vector3(0.0, 1.2, 0.0)
	var direction := aim - muzzle
	if direction.length_squared() < 0.01:
		return
	_spawn_laser(muzzle, direction.normalized())
	if _avatar_animator:
		_avatar_animator.trigger_attack()


func _spawn_laser(origin: Vector3, direction: Vector3) -> void:
	var root := _get_projectiles_root()
	if root == null:
		return
	var laser := LASER_SCENE.instantiate()
	root.add_child(laser)
	if laser.has_method("launch"):
		var shooter_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 0
		laser.launch(origin, direction, shooter_id)


func _get_projectiles_root() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Projectiles")


func _get_muzzle_position() -> Vector3:
	if _laser_socket != null:
		return _laser_socket.global_position
	return global_position + Vector3(0.0, 1.35, 0.0)


func _flat_distance_to(world_pos: Vector3) -> float:
	var delta_pos := world_pos - global_position
	delta_pos.y = 0.0
	return delta_pos.length()


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)


func _pick_patrol_direction() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	_wander_dir = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _mount_model() -> void:
	var built: Dictionary = ZezzlorBuilderScript.build(_model_pivot, RANK_ID, 1.08)
	_laser_socket = built.get("baton_socket") as Node3D
	_avatar_animator = AvatarAnimator.ensure_on(_model_pivot)
	_avatar_animator.bind(_model_pivot)


func _attach_laser_pistol() -> void:
	var socket: Node3D = _laser_socket if _laser_socket != null else _model_pivot
	for child in socket.get_children():
		if child.name == "LaserPistol":
			child.queue_free()

	var gun := MeshInstance3D.new()
	gun.name = "LaserPistol"
	var body := BoxMesh.new()
	body.size = Vector3(0.14, 0.08, 0.42)
	gun.mesh = body
	gun.position = Vector3(0.04, 0.0, -0.18)
	gun.rotation_degrees = Vector3(-8.0, 0.0, -12.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.78, 0.88)
	mat.metallic = 0.85
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.95, 1.0)
	mat.emission_energy_multiplier = 0.55
	gun.material_override = mat
	socket.add_child(gun)

	var barrel := MeshInstance3D.new()
	barrel.name = "LaserBarrel"
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.018
	barrel_mesh.bottom_radius = 0.022
	barrel_mesh.height = 0.28
	barrel.mesh = barrel_mesh
	barrel.position = Vector3(0.0, 0.0, -0.34)
	barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var barrel_mat := mat.duplicate() as StandardMaterial3D
	barrel_mat.emission_energy_multiplier = 1.2
	barrel.material_override = barrel_mat
	gun.add_child(barrel)


func _update_animation() -> void:
	if _avatar_animator:
		_avatar_animator.set_moving(velocity.length() > 0.5 or not is_on_floor())


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


@rpc("any_peer", "unreliable")
func _sync_state(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	position = pos
	rotation.y = yaw
	_update_animation()
	if _avatar_animator:
		_avatar_animator.set_moving(moving)