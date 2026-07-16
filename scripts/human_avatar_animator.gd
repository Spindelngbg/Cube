class_name HumanAvatarAnimator
extends Node

const WALK_ANIM := "Animation"

var showcase_mode := false

var _model_root: Node3D
var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _moving := false
var _attack_timer := 0.0
var _idle_time := 0.0
var _bound := false

var _rest_poses: Dictionary = {}


static func ensure_on(pivot: Node3D, showcase := false) -> HumanAvatarAnimator:
	var existing := pivot.get_node_or_null("HumanAvatarAnimator") as HumanAvatarAnimator
	if existing:
		existing.showcase_mode = showcase
		return existing
	var animator := HumanAvatarAnimator.new()
	animator.name = "HumanAvatarAnimator"
	animator.showcase_mode = showcase
	pivot.add_child(animator)
	return animator


func bind(model_root: Node3D) -> void:
	_model_root = model_root
	_skeleton = HumanCharacterLibrary.find_skeleton(model_root)
	_anim_player = HumanCharacterLibrary.find_anim_player(model_root)
	_cache_rest_poses()
	_bound = _anim_player != null
	_idle_time = randf_range(0.0, TAU)


func set_moving(moving: bool) -> void:
	_moving = moving


func trigger_attack() -> void:
	_attack_timer = 0.52


func get_eye_global_position(fallback: Vector3) -> Vector3:
	if _skeleton == null:
		return fallback
	return HumanCharacterLibrary.get_eye_global_position(_skeleton, fallback)


func _cache_rest_poses() -> void:
	_rest_poses.clear()
	if _skeleton == null:
		return
	for i in _skeleton.get_bone_count():
		_rest_poses[i] = _skeleton.get_bone_pose(i)


func _process(delta: float) -> void:
	if not _bound or _anim_player == null:
		return

	_idle_time += delta
	var locomoting := _moving or showcase_mode

	if locomoting:
		if _anim_player.current_animation != WALK_ANIM:
			_anim_player.play(WALK_ANIM)
		_anim_player.speed_scale = 1.05 if _moving else 0.9
	else:
		if _anim_player.current_animation != WALK_ANIM:
			_anim_player.play(WALK_ANIM)
		_anim_player.speed_scale = 0.0
		_anim_player.seek(0.0, true)
		_apply_idle_breathing()

	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
		_apply_attack_pose(1.0 - (_attack_timer / 0.52))


func _apply_idle_breathing() -> void:
	if _skeleton == null:
		return
	_apply_bone_delta("Skeleton_torso_joint_1", Vector3(deg_to_rad(sin(_idle_time * 1.7) * 1.8), 0.0, 0.0))
	_apply_bone_delta("Skeleton_torso_joint_2", Vector3(deg_to_rad(sin(_idle_time * 2.1 + 0.4) * 1.2), 0.0, 0.0))
	_apply_bone_delta("Skeleton_neck_joint_1", Vector3(0.0, deg_to_rad(sin(_idle_time * 0.9) * 3.5), 0.0))


func _apply_attack_pose(strength: float) -> void:
	if _skeleton == null:
		return
	var swing := sin(strength * PI) * 55.0
	_apply_bone_delta("Skeleton_arm_joint_R", Vector3(deg_to_rad(-swing), 0.0, deg_to_rad(swing * 0.35)))
	_apply_bone_delta("Skeleton_arm_joint_R__2_", Vector3(deg_to_rad(-swing * 0.65), 0.0, 0.0))
	_apply_bone_delta("torso_joint_3", Vector3(0.0, deg_to_rad(swing * 0.18), 0.0))


func _apply_bone_delta(bone_name: String, rot_delta: Vector3) -> void:
	var idx := _skeleton.find_bone(bone_name)
	if idx < 0:
		return
	var rest: Transform3D = _rest_poses.get(idx, _skeleton.get_bone_rest(idx))
	var pose := rest
	pose.basis = pose.basis * Basis.from_euler(rot_delta)
	_skeleton.set_bone_pose(idx, pose)