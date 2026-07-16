extends CharacterBody3D

const CharacterKitLibraryScript = preload("res://scripts/assets/character_kit_library.gd")
const SlimeDamageScript = preload("res://scripts/combat/slime_damage.gd")

const TURN_SPEED := 7.0
const BLUE_UNIFORM := Color(0.12, 0.34, 0.82)
const BATON_COLOR := Color(0.18, 0.2, 0.24)

var _model_pivot: Node3D
var _name_label: Label3D
var _target: Node3D
var _attack_cooldown := 0.0
var _anim_player: AnimationPlayer


func setup(target: Node3D, spawn_pos: Vector3) -> void:
	_model_pivot = $ModelPivot
	_name_label = $NameLabel
	_target = target
	position = spawn_pos
	_name_label.text = "Ordningsvakt"
	_name_label.modulate = Color(0.45, 0.72, 1.0)
	_mount_model()
	_attach_baton()


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
		velocity = dir * SlimeDamageScript.ENFORCER_SPEED
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
			"Batonghugg",
			"Ordningen i kolonin svarar hårt på ditt slemangrepp."
		)


func _mount_model() -> void:
	for child in _model_pivot.get_children():
		child.queue_free()
	var model := CharacterKitLibraryScript.spawn(_model_pivot, "character-h", Vector3.ZERO, 0.0, 1.05)
	if model == null:
		return
	CharacterKitLibraryScript.apply_tint(model, BLUE_UNIFORM)
	_anim_player = _find_anim_player(model)
	_play_anim(["idle", "Idle"])


func _attach_baton() -> void:
	var baton := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.045
	mesh.height = 0.72
	baton.mesh = mesh
	baton.name = "Baton"
	baton.position = Vector3(0.42, 1.05, 0.18)
	baton.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BATON_COLOR
	mat.metallic = 0.55
	mat.roughness = 0.35
	baton.material_override = mat
	_model_pivot.add_child(baton)


func _update_animation(moving: bool) -> void:
	if _anim_player == null:
		return
	if moving:
		_play_anim(["walk", "Walk", "run", "Run"])
	else:
		_play_anim(["idle", "Idle"])


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


func _play_anim(preferred: Array) -> void:
	if _anim_player == null:
		return
	for anim_name in preferred:
		if _anim_player.has_animation(anim_name):
			if _anim_player.current_animation != anim_name:
				_anim_player.play(anim_name)
			return


@rpc("any_peer", "unreliable")
func _sync_state(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	position = pos
	rotation.y = yaw
	_update_animation(moving)