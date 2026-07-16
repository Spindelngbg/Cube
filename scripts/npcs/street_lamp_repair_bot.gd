class_name StreetLampRepairBot
extends CharacterBody3D

const StreetLampServiceScript = preload("res://scripts/city/street_lamp_service.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

const BODY_COLOR := Color(0.92, 0.78, 0.28)
const ACCENT := Color(0.35, 0.72, 0.95)
const TOOL_COLOR := Color(0.72, 0.74, 0.78)

const MOVE_SPEED := 1.65
const REPAIR_TIME := 6.5
const TURN_SPEED := 7.0

enum State { SEEKING, REPAIRING, IDLE }

var _state := State.SEEKING
var _target_lamp: StreetLamp
var _repair_timer := 0.0
var _idle_timer := 0.0
var _rng := RandomNumberGenerator.new()

var _body: Node3D
var _head: Node3D
var _tool_arm: Node3D
var _antenna: MeshInstance3D
var _name_label: Label3D
var _status_label: Label3D
var _time := 0.0


func setup(local_pos: Vector3, seed: int) -> void:
	_rng.seed = seed
	_time = _rng.randf_range(0.0, TAU)
	position = local_pos
	_build_robot()
	_build_collision()
	_pick_next_target()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _is_simulation_authority():
		return
	_time += delta
	match _state:
		State.SEEKING:
			_tick_seeking(delta)
		State.REPAIRING:
			_tick_repairing(delta)
		State.IDLE:
			_tick_idle(delta)
	_animate_robot(delta)


func _tick_seeking(delta: float) -> void:
	if _target_lamp == null or not is_instance_valid(_target_lamp) or not _target_lamp.is_broken():
		_pick_next_target()
		if _target_lamp == null:
			_enter_idle(2.0)
		return

	var stand := _target_lamp.get_repair_stand_position()
	var to_stand := stand - global_position
	to_stand.y = 0.0
	var dist := to_stand.length()
	if dist < 0.55:
		_begin_repair()
		return

	var dir := to_stand / maxf(dist, 0.001)
	velocity = dir * MOVE_SPEED
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
	move_and_slide()
	_set_status("På väg till trasig gatlampa…")


func _tick_repairing(delta: float) -> void:
	velocity = Vector3.ZERO
	_repair_timer -= delta
	if _target_lamp and is_instance_valid(_target_lamp):
		var to_lamp := _target_lamp.global_position - global_position
		to_lamp.y = 0.0
		if to_lamp.length() > 0.2:
			var stare_yaw := atan2(to_lamp.x, to_lamp.z)
			rotation.y = lerp_angle(rotation.y, stare_yaw, TURN_SPEED * delta * 1.4)
	if _repair_timer <= 0.0:
		if _target_lamp and is_instance_valid(_target_lamp):
			_target_lamp.request_repair()
			NpcDialogueBarkScript.play_for_npc(self, "completion", "sean")
		_set_status("Klar! Nästa lampa…")
		_state = State.SEEKING
		_pick_next_target()
		if _target_lamp == null:
			_enter_idle(_rng.randf_range(4.0, 9.0))
	else:
		var pct := 1.0 - (_repair_timer / REPAIR_TIME)
		_set_status("Lagrar gatlampa… %d%%" % int(round(pct * 100.0)))


func _tick_idle(delta: float) -> void:
	velocity = Vector3.ZERO
	_idle_timer -= delta
	_set_status("Söker trasiga lampor…")
	if _idle_timer <= 0.0:
		_state = State.SEEKING
		_pick_next_target()


func _begin_repair() -> void:
	_state = State.REPAIRING
	_repair_timer = REPAIR_TIME
	velocity = Vector3.ZERO
	_set_status("Lagrar gatlampa…")


func _enter_idle(duration: float) -> void:
	_state = State.IDLE
	_idle_timer = duration
	_target_lamp = null


func _pick_next_target() -> void:
	_target_lamp = StreetLampServiceScript.get_nearest_broken(global_position)


func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.35
	shape_node.shape = capsule
	shape_node.position = Vector3(0.0, 0.78, 0.0)
	add_child(shape_node)
	collision_layer = 4
	collision_mask = 1


func _build_robot() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	var torso := _box("Torso", _body, Vector3(0.0, 0.72, 0.0), Vector3(0.34, 0.42, 0.28), BODY_COLOR)
	torso.material_override = _mat(BODY_COLOR, 0.18)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 1.12, 0.0)
	_body.add_child(_head)

	var skull := _box("HeadMesh", _head, Vector3.ZERO, Vector3(0.3, 0.24, 0.26), BODY_COLOR.lightened(0.06))
	skull.material_override = _mat(BODY_COLOR.lightened(0.06), 0.12)

	var visor := _box("Visor", _head, Vector3(0.0, 0.02, -0.16), Vector3(0.22, 0.1, 0.05), ACCENT)
	visor.material_override = _glow(ACCENT, 0.75)

	_antenna = _box("Antenna", _head, Vector3(0.0, 0.18, 0.0), Vector3(0.04, 0.16, 0.04), ACCENT)
	_antenna.material_override = _glow(ACCENT, 0.5)

	_tool_arm = Node3D.new()
	_tool_arm.name = "ToolArm"
	_tool_arm.position = Vector3(0.38, 0.82, 0.05)
	_body.add_child(_tool_arm)
	var upper := _capsule("UpperArm", _tool_arm, Vector3(0.08, 0.0, 0.0), Vector3(0.07, 0.18, 0.07), BODY_COLOR)
	upper.rotation.z = deg_to_rad(-28.0)
	upper.material_override = _mat(BODY_COLOR, 0.1)
	var wrench := _box("Wrench", _tool_arm, Vector3(0.22, 0.08, -0.12), Vector3(0.05, 0.05, 0.22), TOOL_COLOR)
	wrench.material_override = _mat(TOOL_COLOR, 0.05)
	var wrench_head := _box("WrenchHead", _tool_arm, Vector3(0.22, 0.08, -0.26), Vector3(0.12, 0.04, 0.05), TOOL_COLOR)
	wrench_head.material_override = _mat(TOOL_COLOR, 0.08)

	var left_leg := _capsule("LeftLeg", _body, Vector3(-0.12, 0.22, 0.0), Vector3(0.08, 0.22, 0.08), BODY_COLOR.darkened(0.08))
	left_leg.material_override = _mat(BODY_COLOR.darkened(0.08), 0.08)
	var right_leg := _capsule("RightLeg", _body, Vector3(0.12, 0.22, 0.0), Vector3(0.08, 0.22, 0.08), BODY_COLOR.darkened(0.08))
	right_leg.material_override = _mat(BODY_COLOR.darkened(0.08), 0.08)

	_name_label = Label3D.new()
	_name_label.text = "Lux-Bot"
	_name_label.font_size = 34
	_name_label.modulate = BODY_COLOR.lightened(0.12)
	_name_label.outline_modulate = Color(0.08, 0.1, 0.12, 0.95)
	_name_label.position = Vector3(0.0, 1.55, 0.0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)

	_status_label = Label3D.new()
	_status_label.text = "Söker trasiga lampor…"
	_status_label.font_size = 22
	_status_label.modulate = ACCENT
	_status_label.outline_modulate = Color(0.05, 0.08, 0.12, 0.9)
	_status_label.position = Vector3(0.0, 1.25, 0.0)
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_status_label)


func _animate_robot(delta: float) -> void:
	if _body == null:
		return
	var bob := sin(_time * 2.2) * 0.02
	if _state == State.REPAIRING:
		bob += sin(_time * 11.0) * 0.04
	_body.position.y = bob
	if _head:
		_head.rotation.x = sin(_time * 1.1) * 0.06
	if _tool_arm:
		var wiggle := sin(_time * 8.0) * 0.35
		if _state == State.REPAIRING:
			wiggle = sin(_time * 16.0) * 0.65
		_tool_arm.rotation.x = deg_to_rad(-20.0 + wiggle * 35.0)
		_tool_arm.rotation.z = deg_to_rad(12.0 + wiggle * 18.0)
	if _antenna:
		_antenna.rotation.z = sin(_time * 4.5) * 0.22


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


func _box(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = BoxMesh.new()
	mesh.position = pos
	mesh.scale = scale
	parent.add_child(mesh)
	return mesh


func _capsule(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 1.0
	mesh.mesh = cap
	mesh.position = pos
	mesh.scale = scale
	parent.add_child(mesh)
	return mesh


func _mat(color: Color, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.58
	mat.metallic = 0.22
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