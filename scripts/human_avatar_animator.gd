class_name HumanAvatarAnimator
extends Node

var showcase_mode := false

var _model_root: Node3D
var _mesh_id := "reference_human"
var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _walk_anim := ""
var _uses_humanoid_punch := true
var _moving := false
var _attack_timer := 0.0
var _punch_timer := 0.0
const PUNCH_DURATION := 0.42
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
	_mesh_id = str(model_root.get_meta("mesh_id", "reference_human"))
	_skeleton = HumanCharacterLibrary.find_skeleton(model_root)
	_anim_player = HumanCharacterLibrary.find_anim_player(model_root)
	_walk_anim = ""
	_uses_humanoid_punch = HumanCharacterLibrary.uses_humanoid_punch(_mesh_id)
	if _anim_player != null:
		_walk_anim = HumanCharacterLibrary.resolve_locomotion_anim(_anim_player, _mesh_id)
	_cache_rest_poses()
	_bound = _anim_player != null and _walk_anim != ""
	_idle_time = randf_range(0.0, TAU)


func set_moving(moving: bool) -> void:
	_moving = moving


func trigger_attack() -> void:
	if _uses_humanoid_punch:
		_attack_timer = 0.52


func trigger_punch() -> void:
	if _uses_humanoid_punch:
		_punch_timer = PUNCH_DURATION


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
		if _anim_player.current_animation != _walk_anim:
			_anim_player.play(_walk_anim)
		_anim_player.speed_scale = 1.05 if _moving else 0.9
	else:
		if _anim_player.current_animation != _walk_anim:
			_anim_player.play(_walk_anim)
		_anim_player.speed_scale = 0.0
		_anim_player.seek(0.0, true)
		if _uses_humanoid_punch:
			_apply_idle_breathing()

	if not _uses_humanoid_punch:
		return

	if _punch_timer > 0.0:
		_punch_timer = maxf(0.0, _punch_timer - delta)
		_apply_punch_pose(1.0 - (_punch_timer / PUNCH_DURATION))
	elif _attack_timer > 0.0:
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


func _apply_punch_pose(phase: float) -> void:
	if _skeleton == null:
		return

	var windup := 1.0 - smoothstep(0.0, 0.2, phase)
	var strike := smoothstep(0.16, 0.3, phase) * (1.0 - smoothstep(0.36, 0.52, phase))
	var recover := smoothstep(0.5, 1.0, phase)

	var right_shoulder_pitch := lerpf(-12.0, -82.0, windup) + lerpf(0.0, 48.0, strike) + lerpf(0.0, -14.0, recover)
	var right_elbow_pitch := lerpf(-18.0, -96.0, windup) + lerpf(0.0, 72.0, strike) + lerpf(0.0, -20.0, recover)
	var left_guard_pitch := lerpf(0.0, -34.0, strike) * (1.0 - recover * 0.6)
	var torso_twist := lerpf(0.0, -22.0, strike) + lerpf(0.0, 6.0, recover)

	_apply_bone_delta(
		"Skeleton_arm_joint_R",
		Vector3(
			deg_to_rad(right_shoulder_pitch),
			deg_to_rad(-14.0 * strike),
			deg_to_rad(10.0 * strike)
		)
	)
	_apply_bone_delta(
		"Skeleton_arm_joint_R__2_",
		Vector3(deg_to_rad(right_elbow_pitch), 0.0, deg_to_rad(8.0 * strike))
	)
	_apply_bone_delta(
		"Skeleton_arm_joint_L",
		Vector3(deg_to_rad(left_guard_pitch), deg_to_rad(10.0 * strike), deg_to_rad(-8.0 * strike))
	)
	_apply_bone_delta(
		"Skeleton_arm_joint_L__2_",
		Vector3(deg_to_rad(-24.0 * strike), 0.0, 0.0)
	)
	_apply_bone_delta("torso_joint_3", Vector3(0.0, deg_to_rad(torso_twist), deg_to_rad(4.0 * strike)))
	_apply_bone_delta("Skeleton_torso_joint_1", Vector3(deg_to_rad(6.0 * strike), 0.0, 0.0))


func _apply_bone_delta(bone_name: String, rot_delta: Vector3) -> void:
	var idx := _skeleton.find_bone(bone_name)
	if idx < 0:
		return
	var rest: Transform3D = _rest_poses.get(idx, _skeleton.get_bone_rest(idx))
	var pose := rest
	pose.basis = pose.basis * Basis.from_euler(rot_delta)
	_skeleton.set_bone_pose(idx, pose)