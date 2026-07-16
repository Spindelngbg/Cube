extends CharacterBody3D

const SlimeDamageScript = preload("res://scripts/combat/slime_damage.gd")
const ZezzlorBuilderScript = preload("res://scripts/monsters/zezzlor_builder.gd")
const ZezzlorLoreScript = preload("res://scripts/story/zezzlor_lore.gd")

const TURN_SPEED := 7.0
const BATON_COLOR := Color(0.18, 0.2, 0.24)

var _model_pivot: Node3D
var _name_label: Label3D
var _target: Node3D
var _attack_cooldown := 0.0
var _avatar_animator: AvatarAnimator
var _model_root: Node3D
var _baton_socket: Node3D
var _rank_id := "patrol"
var _display_name := ""
var _deflect_flash := false


func setup(
	target: Node3D,
	spawn_pos: Vector3,
	rank_id: String = "patrol",
	personal_name: String = ""
) -> void:
	_model_pivot = $ModelPivot
	_name_label = $NameLabel
	_target = target
	_rank_id = rank_id
	position = spawn_pos
	_display_name = ZezzlorLoreScript.format_name(rank_id, personal_name)
	_name_label.text = _display_name
	_name_label.modulate = ZezzlorLoreScript.rank_color(rank_id)
	_mount_model()
	_attach_baton()


func get_rank_id() -> String:
	return _rank_id


func take_corrosive_slime(_amount: float, _shooter_id: int) -> void:
	_flash_deflect()


func take_damage(_amount: float) -> void:
	_flash_deflect()


func _physics_process(delta: float) -> void:
	if not _is_simulation_authority():
		return
	if _target == null or not is_instance_valid(_target):
		velocity = Vector3.ZERO
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist < 1.85:
		velocity = Vector3.ZERO
		_try_baton_strike()
	else:
		var dir := to_target.normalized()
		velocity = dir * SlimeDamageScript.ZEZZLOR_SPEED
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)

	move_and_slide()
	_update_animation(dist > 1.85)
	if multiplayer.multiplayer_peer != null:
		_sync_state.rpc(position, rotation.y, velocity.length() > 0.1)


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


func _try_baton_strike() -> void:
	if _attack_cooldown > 0.0 or _target == null:
		return
	if not _target.has_method("take_damage"):
		return
	if _target.global_position.distance_to(global_position) > 2.2:
		return
	_attack_cooldown = SlimeDamageScript.BATON_COOLDOWN
	_target.take_damage(SlimeDamageScript.BATON_DAMAGE)
	if _target.is_multiplayer_authority():
		QuestManager.story_toast.emit(
			"Zezzlor-batong",
			ZezzlorLoreScript.baton_strike_body(_rank_id)
		)
	if _avatar_animator:
		_avatar_animator.trigger_attack()


func _mount_model() -> void:
	var built: Dictionary = ZezzlorBuilderScript.build(_model_pivot, _rank_id, 1.05)
	_model_root = built.get("root") as Node3D
	_baton_socket = built.get("baton_socket") as Node3D
	_avatar_animator = AvatarAnimator.ensure_on(_model_pivot)
	_avatar_animator.bind(_model_pivot)


func _attach_baton() -> void:
	var socket: Node3D = _baton_socket if _baton_socket != null else _model_pivot

	var baton := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.045
	mesh.height = 0.72
	baton.mesh = mesh
	baton.name = "Baton"
	baton.position = Vector3(0.0, 0.0, -0.08)
	baton.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BATON_COLOR
	mat.metallic = 0.55
	mat.roughness = 0.35
	baton.material_override = mat
	socket.add_child(baton)


func _update_animation(moving: bool) -> void:
	if _avatar_animator:
		_avatar_animator.set_moving(moving)


func _flash_deflect() -> void:
	if _deflect_flash or _model_pivot == null:
		return
	_deflect_flash = true
	var tween := create_tween()
	tween.tween_property(_model_pivot, "scale", Vector3(1.04, 0.96, 1.04), 0.06)
	tween.tween_property(_model_pivot, "scale", Vector3.ONE, 0.1)
	tween.tween_callback(func() -> void:
		_deflect_flash = false
	)


@rpc("any_peer", "unreliable")
func _sync_state(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	position = pos
	rotation.y = yaw
	_update_animation(moving)