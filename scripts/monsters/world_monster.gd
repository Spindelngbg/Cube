extends CharacterBody3D

const WANDER_SPEED_MULT := 1.0
const TURN_SPEED := 4.5
const HYBRID_HP := 48.0
const DEFAULT_HP := 28.0

var _model_pivot: Node3D
var _name_label: Label3D
var _display_name := "Monster"
var _move_speed := 2.0
var _wander_dir := Vector3.FORWARD
var _wander_timer := 0.0
var _bounds_center := Vector3.ZERO
var _bounds_radius := 10.0
var _anim_player: AnimationPlayer
var _avatar_animator: AvatarAnimator
var _moving := false
var _rng := RandomNumberGenerator.new()
var _hp := DEFAULT_HP
var _alive := true


func _ready() -> void:
	add_to_group("world_monster")


func setup(entry: Dictionary, spawn_pos: Vector3, bounds_center: Vector3, bounds_radius: float, seed: int) -> void:
	_model_pivot = $ModelPivot
	_name_label = $NameLabel
	_rng.seed = seed
	_bounds_center = bounds_center
	_bounds_radius = bounds_radius
	_display_name = str(entry.get("name", "Monster"))
	_move_speed = float(entry.get("speed", 2.0)) * WANDER_SPEED_MULT
	_name_label.text = _display_name
	position = spawn_pos
	_pick_new_direction()

	match str(entry.get("kind", "")):
		"scifi":
			_mount_scifi_model(str(entry.get("model", "")), float(entry.get("scale", 1.0)), float(entry.get("y_offset", 0.0)))
		"spider":
			_mount_spider_model(entry, seed)
		"hybrid":
			_mount_hybrid_model(entry, seed)
			set_meta("is_src_hybrid", true)
		_:
			push_warning("WorldMonster: okänd typ %s" % entry.get("kind", ""))

	_wander_timer = _rng.randf_range(0.5, 2.0)
	_hp = HYBRID_HP if has_meta("is_src_hybrid") else DEFAULT_HP


func is_alive() -> bool:
	return _alive


func take_damage(amount: float) -> void:
	if not _alive or amount <= 0.0:
		return
	if multiplayer.multiplayer_peer == null:
		_apply_damage_local(amount)
		return
	_apply_damage.rpc(amount)


@rpc("any_peer", "call_local", "reliable")
func _apply_damage(amount: float) -> void:
	if not _is_simulation_authority():
		return
	_apply_damage_local(amount)


func _apply_damage_local(amount: float) -> void:
	if not _alive or amount <= 0.0:
		return
	_hp -= amount
	_flash_hit()
	if _hp <= 0.0:
		_die()


func _flash_hit() -> void:
	if _model_pivot == null:
		return
	var original := _model_pivot.scale
	var tween := create_tween()
	tween.tween_property(_model_pivot, "scale", original * 1.1, 0.05)
	tween.tween_property(_model_pivot, "scale", original, 0.08)


func _die() -> void:
	if not _alive:
		return
	_alive = false
	velocity = Vector3.ZERO
	set_collision_layer_value(4, false)
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("unregister_monster"):
		game.unregister_monster(self)
	queue_free()


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if not _is_simulation_authority():
		return
	_simulate(delta)
	if multiplayer.multiplayer_peer != null:
		_sync_state.rpc(position, rotation.y, _moving)


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


func _simulate(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_new_direction()
		_wander_timer = _rng.randf_range(1.2, 3.5)

	var to_center := _bounds_center - global_position
	to_center.y = 0.0
	if to_center.length() > _bounds_radius:
		_wander_dir = to_center.normalized()
		_wander_timer = _rng.randf_range(0.8, 1.6)

	velocity = _wander_dir * _move_speed
	_moving = velocity.length() > 0.1
	if _moving:
		var target_yaw := atan2(_wander_dir.x, _wander_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)

	move_and_slide()
	_update_animation()


func _pick_new_direction() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	_wander_dir = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _mount_scifi_model(model_name: String, scale_factor: float, y_offset: float) -> void:
	for child in _model_pivot.get_children():
		child.queue_free()
	var model := SciFiEssentialsLibrary.spawn(_model_pivot, model_name)
	if model == null:
		return
	model.position.y = y_offset
	model.scale = Vector3.ONE * scale_factor
	_anim_player = _find_anim_player(model)
	_play_idle_or_walk()


func _mount_spider_model(entry: Dictionary, seed: int) -> void:
	for child in _model_pivot.get_children():
		child.queue_free()
	var avatar := MonsterCatalog.build_spider_avatar(entry, seed)
	SpiderAlienBuilder.build(_model_pivot, avatar)
	_model_pivot.scale = Vector3.ONE * float(entry.get("scale", 1.0))
	_anim_player = null
	_avatar_animator = AvatarAnimator.ensure_on(_model_pivot)
	_avatar_animator.bind(_model_pivot)


func _mount_hybrid_model(entry: Dictionary, seed: int) -> void:
	for child in _model_pivot.get_children():
		child.queue_free()
	var avatar := MonsterCatalog.build_hybrid_avatar(entry, seed)
	SpiderAlienBuilder.build(_model_pivot, avatar)
	_model_pivot.scale = Vector3.ONE * float(entry.get("scale", 1.0))
	_avatar_animator = AvatarAnimator.ensure_on(_model_pivot)
	_avatar_animator.bind(_model_pivot)
	var drone := SciFiEssentialsLibrary.spawn(_model_pivot, str(entry.get("drone", "Enemy_EyeDrone")))
	if drone:
		drone.position = Vector3(0.0, 1.55, 0.35)
		drone.scale = Vector3.ONE * 0.55
		_anim_player = _find_anim_player(drone)
		_play_idle_or_walk()
	else:
		_anim_player = null


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


func _update_animation() -> void:
	if _avatar_animator:
		_avatar_animator.set_moving(_moving)
		return
	if _anim_player == null:
		return
	if _moving:
		_play_anim(["Walk", "Run", "Move"])
	else:
		_play_anim(["Idle", "Look", "Hanging"])


func _play_idle_or_walk() -> void:
	if _anim_player == null:
		return
	_play_anim(["Idle", "Look"])


func _play_anim(preferred: Array) -> void:
	if _anim_player == null:
		return
	for anim_name in preferred:
		if _anim_player.has_animation(anim_name):
			if _anim_player.current_animation != anim_name:
				_anim_player.play(anim_name)
			return
	if _anim_player.get_animation_list().size() > 0 and _anim_player.current_animation == "":
		_anim_player.play(_anim_player.get_animation_list()[0])


@rpc("any_peer", "unreliable")
func _sync_state(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	position = pos
	rotation.y = yaw
	if moving != _moving:
		_moving = moving
		_update_animation()