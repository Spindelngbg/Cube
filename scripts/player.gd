extends CharacterBody3D

const MOVE_SPEED := 5.0
const SPRINT_SPEED := 8.5
const JUMP_VELOCITY := 6.5
const GRAVITY := 24.0
const TURN_SPEED := 8.0
const SLIME_PROJECTILE_SCENE := preload("res://scenes/combat/slime_projectile.tscn")
const SlimeBlasterClass = preload("res://scripts/combat/slime_blaster.gd")
const ZnoodDeviceScript = preload("res://scripts/access/znood_device.gd")
const HumanAvatarBuilderScript = preload("res://scripts/human_avatar_builder.gd")
const FirstPersonPunchViewScript = preload("res://scripts/combat/first_person_punch_view.gd")
const BoxingPunchScript = preload("res://scripts/combat/boxing_punch.gd")

const FIRST_PERSON_FALLBACK_EYE := Vector3(0.0, 1.62, 0.08)

@onready var avatar_pivot: Node3D = $AvatarPivot
@onready var znood_mount: ZnoodDevice = $AvatarPivot/ZnoodMount
@onready var name_label: Label3D = $NameLabel

signal health_changed(current: float, maximum: float)
signal died

var _player_username := ""
var _avatar_synced := false
var _slime_blaster = SlimeBlasterClass.new()
var _health := 100.0
var _max_health := 100.0
var _damage_cooldown := 0.0
var _respawn_timer := 0.0
var _is_dead := false
var _spawn_anchor := Vector3.ZERO
var _human_animator: HumanAvatarAnimator
var _avatar_model: Node3D
var _fp_punch: FirstPersonPunchView
var _punch_cooldown := 0.0
var _stuck_frames := 0
var _last_sync_pos := Vector3.ZERO


func _ready() -> void:
	_setup_name_label()
	_spawn_anchor = global_position
	if is_multiplayer_authority():
		InventoryManager.inventory_changed.connect(_on_inventory_changed)
		_refresh_max_health(true)
		_player_username = Auth.username
		var display_name := Profile.active_character_name if not Auth.is_guest else ""
		_apply_identity(_player_username, Profile.get_avatar(), display_name)
		if Auth.is_guest:
			_sync_guest_state.rpc(_player_username, Profile.get_avatar().to_dict())
		else:
			_announce_player.rpc(_player_username)
	else:
		name_label.text = "..."
	if is_multiplayer_authority():
		call_deferred("snap_to_floor")


func snap_to_floor() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var from := global_position + Vector3(0.0, 2.5, 0.0)
	var to := global_position + Vector3(0.0, -8.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		global_position.y = maxf(global_position.y, 1.0)
		return
	global_position.y = float(hit.position.y) + 1.0
	velocity.y = 0.0


func _setup_name_label() -> void:
	name_label.position = Vector3(0, 2.55, 0)
	name_label.font_size = 36
	name_label.outline_size = 10
	name_label.modulate = Color(0.95, 0.9, 0.82, 1)
	name_label.outline_modulate = Color(0.08, 0.06, 0.1, 0.95)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if _is_dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return

	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)
	_punch_cooldown = maxf(0.0, _punch_cooldown - delta)
	_slime_blaster.tick(delta)
	_handle_combat_input()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		if _stuck_frames >= 6:
			_unstuck_nudge()
		else:
			velocity.y = JUMP_VELOCITY

	var move_speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else MOVE_SPEED
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _get_flat_move_direction(input_dir)
	var pre_move_pos := global_position

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		var yaw_source := _get_camera_yaw_source()
		if yaw_source >= 0.0:
			rotation.y = yaw_source
		else:
			var target_yaw := atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()
	if direction != Vector3.ZERO and is_on_floor() and pre_move_pos.distance_to(global_position) < 0.004:
		_stuck_frames += 1
	else:
		_stuck_frames = 0
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if _human_animator:
		_human_animator.set_moving(horizontal_speed > 0.35)
	_sync_position.rpc(position, rotation.y)


@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector3, yaw: float) -> void:
	if is_multiplayer_authority():
		return
	var moved := pos.distance_to(_last_sync_pos) > 0.03
	_last_sync_pos = pos
	position = pos
	rotation.y = yaw
	if _human_animator:
		_human_animator.set_moving(moved)


@rpc("any_peer", "reliable")
func _announce_player(username: String) -> void:
	if is_multiplayer_authority():
		return
	_load_avatar_from_server(username)


@rpc("any_peer", "reliable")
func _sync_guest_state(username: String, avatar_dict: Dictionary) -> void:
	if is_multiplayer_authority():
		return
	_apply_identity(username, AvatarData.from_dict(avatar_dict))


func respond_with_active_character() -> void:
	if not is_multiplayer_authority():
		return
	if Auth.is_guest:
		_sync_guest_state.rpc(_player_username, Profile.get_avatar().to_dict())
	else:
		_announce_player.rpc(_player_username)


func _load_avatar_from_server(username: String) -> void:
	Profile.fetch_active_for_username(username, func(ok: bool, avatar: AvatarData, character_name: String) -> void:
		if not is_inside_tree():
			return
		if ok:
			_apply_identity(username, avatar, character_name)
		elif _player_username != "":
			pass
		else:
			name_label.text = username
	)


func _apply_identity(username: String, avatar: AvatarData, character_name: String = "") -> void:
	_player_username = username
	name_label.text = _format_display_name(username, character_name)
	_apply_avatar(avatar)


func _apply_avatar(data: AvatarData) -> void:
	var model := HumanAvatarBuilderScript.build(avatar_pivot, data)
	if model == null:
		return
	_avatar_model = model
	_human_animator = HumanAvatarAnimator.ensure_on(avatar_pivot)
	_human_animator.bind(model)
	if is_multiplayer_authority():
		_fp_punch = FirstPersonPunchViewScript.ensure_on(self)
		_fp_punch.apply_avatar_colors(data.body_color, data.accent_color)
	_refresh_first_person_visibility()
	_last_sync_pos = position
	_avatar_synced = true


func get_camera_anchor_global_position() -> Vector3:
	var fallback := global_position + FIRST_PERSON_FALLBACK_EYE
	if _human_animator:
		return _human_animator.get_eye_global_position(fallback)
	return fallback


func _refresh_first_person_visibility() -> void:
	var hide_body := is_multiplayer_authority()
	if _avatar_model:
		_avatar_model.visible = not hide_body
	name_label.visible = not hide_body


func _format_display_name(username: String, character_name: String) -> String:
	if character_name.strip_edges() != "":
		return character_name.strip_edges()
	if username.strip_edges() != "":
		return username.strip_edges()
	return "Kolonist"


func get_slime_status_text() -> String:
	if not WeaponManager.can_use_slimeshooter():
		if InventoryManager.has_item(WeaponManager.SLIMESHOOTER_ID):
			return "Slimeshooter i inventory — utrusta vid vapenbutik [E]"
		return "Inget vapen — hämta Slimeshooter vid vapenbutiken"
	return _slime_blaster.get_status_text()


func get_hp_status_text() -> String:
	return "HP %d/%d" % [int(round(_health)), int(round(_max_health))]


func get_health_snapshot() -> Dictionary:
	return {"current": _health, "max": _max_health}


func set_spawn_anchor(pos: Vector3) -> void:
	_spawn_anchor = pos


func take_damage(amount: float) -> void:
	if _is_dead or _damage_cooldown > 0.0 or amount <= 0.0:
		return
	_damage_cooldown = 0.85
	_health = maxf(0.0, _health - amount)
	health_changed.emit(_health, _max_health)
	_sync_health.rpc(_health, _max_health)
	if _health <= 0.0:
		_die()


func heal_to_full() -> void:
	_health = _max_health
	_is_dead = false
	health_changed.emit(_health, _max_health)
	_sync_health.rpc(_health, _max_health)


func _on_inventory_changed() -> void:
	_refresh_max_health(false)


func _refresh_max_health(fill_new_bonus: bool) -> void:
	var new_max := InventoryManager.get_max_hp()
	var bonus_delta := new_max - _max_health
	_max_health = new_max
	if fill_new_bonus:
		_health = _max_health
	elif bonus_delta > 0.0:
		_health += bonus_delta
	_health = minf(_health, _max_health)
	health_changed.emit(_health, _max_health)


func _die() -> void:
	_is_dead = true
	_respawn_timer = 3.0
	velocity = Vector3.ZERO
	died.emit()
	name_label.modulate = Color(0.55, 0.12, 0.12)


func _respawn() -> void:
	global_position = _spawn_anchor
	snap_to_floor()
	_stuck_frames = 0
	_is_dead = false
	_health = _max_health
	_damage_cooldown = 0.0
	name_label.modulate = Color(0.95, 0.9, 0.82, 1)
	health_changed.emit(_health, _max_health)
	_sync_health.rpc(_health, _max_health)


@rpc("any_peer", "unreliable")
func _sync_health(current: float, maximum: float) -> void:
	if is_multiplayer_authority():
		return
	_health = current
	_max_health = maximum
	health_changed.emit(_health, _max_health)


func get_znood() -> ZnoodDevice:
	return znood_mount


func get_facing_yaw() -> float:
	var yaw_source := _get_camera_yaw_source()
	if yaw_source >= 0.0:
		return yaw_source
	return rotation.y


func _get_flat_move_direction(input_dir: Vector2) -> Vector3:
	if input_dir == Vector2.ZERO:
		return Vector3.ZERO
	if MouseLook.is_active():
		return MouseLook.get_flat_direction(input_dir)
	var pivot := _get_camera_pivot()
	if pivot != null:
		var direction := pivot.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
		direction.y = 0.0
		if direction.length_squared() > 0.0001:
			return direction.normalized()
	return Vector3(input_dir.x, 0.0, input_dir.y).normalized()


func _get_camera_yaw_source() -> float:
	if MouseLook.is_active():
		return MouseLook.get_yaw()
	var pivot := _get_camera_pivot()
	if pivot != null:
		return pivot.rotation.y
	return -1.0


func _get_camera_pivot() -> Node3D:
	var game := get_tree().current_scene
	if game and game.has_method("get_camera_pivot"):
		return game.call("get_camera_pivot") as Node3D
	if game and game.has_node("CameraPivot"):
		return game.get_node("CameraPivot") as Node3D
	return null


func _unstuck_nudge() -> void:
	var forward := _get_flat_move_direction(Vector2(0.0, 1.0))
	if forward == Vector3.ZERO:
		forward = Vector3(-global_transform.basis.z.x, 0.0, -global_transform.basis.z.z).normalized()
	global_position += Vector3(0.0, 0.45, 0.0) + forward * 1.4
	velocity = Vector3.ZERO
	_stuck_frames = 0
	snap_to_floor()


func stamp_znood_at(door: Node) -> void:
	if not is_multiplayer_authority():
		return
	if znood_mount == null or not znood_mount.is_ready():
		return
	znood_mount.play_stamp(door.global_position)
	_sync_znood_stamp.rpc(door.global_position)
	if door.has_method("unlock_from_stamp"):
		door.unlock_from_stamp(multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func _sync_znood_stamp(target: Vector3) -> void:
	if is_multiplayer_authority():
		return
	if znood_mount != null:
		znood_mount.play_stamp(target)


func _handle_combat_input() -> void:
	if get_tree().paused or not MouseLook.is_active():
		return
	if Input.is_action_just_pressed("punch"):
		_try_punch()
	if not WeaponManager.can_use_slimeshooter():
		return
	if Input.is_action_just_pressed("reload"):
		_slime_blaster.try_reload()
	if Input.is_action_just_pressed("fire"):
		_try_fire_slime()


func _try_punch() -> void:
	if _punch_cooldown > 0.0 or _is_dead:
		return
	_punch_cooldown = BoxingPunchScript.PUNCH_COOLDOWN
	if _human_animator:
		_human_animator.trigger_punch()
	if _fp_punch:
		_fp_punch.trigger_punch()
	_sync_punch.rpc()
	get_tree().create_timer(BoxingPunchScript.HIT_DELAY_SEC).timeout.connect(
		_apply_punch_hit,
		CONNECT_ONE_SHOT
	)


func _apply_punch_hit() -> void:
	if not is_multiplayer_authority() or _is_dead:
		return
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	var target := BoxingPunchScript.resolve_target(
		get_world_3d().direct_space_state,
		origin,
		direction,
		get_rid()
	)
	BoxingPunchScript.apply_hit(target, multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func _sync_punch() -> void:
	if is_multiplayer_authority():
		return
	if _human_animator:
		_human_animator.trigger_punch()


func _try_fire_slime() -> void:
	if not _slime_blaster.try_fire():
		return
	if _human_animator:
		_human_animator.trigger_attack()
	var origin := MouseLook.get_aim_origin(global_position)
	var direction := MouseLook.get_aim_direction()
	_spawn_slime_projectile.rpc(origin, direction, multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func _spawn_slime_projectile(origin: Vector3, direction: Vector3, shooter_id: int) -> void:
	if get_multiplayer_authority() == shooter_id and _human_animator:
		_human_animator.trigger_attack()
	var projectiles_root := _get_projectiles_root()
	if projectiles_root == null:
		return
	var projectile := SLIME_PROJECTILE_SCENE.instantiate()
	projectiles_root.add_child(projectile)
	if projectile.has_method("launch"):
		projectile.launch(origin, direction, shooter_id)


func _get_projectiles_root() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Projectiles")