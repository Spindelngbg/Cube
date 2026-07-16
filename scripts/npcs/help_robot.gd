class_name HelpRobot
extends CharacterBody3D

const HelpRobotCatalogScript = preload("res://scripts/npcs/help_robot_catalog.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")


const BODY_COLOR := Color(0.78, 0.9, 0.98)
const CHEEK_COLOR := Color(0.45, 0.78, 0.95)
const EYE_WHITE := Color(0.98, 0.99, 1.0)
const PUPIL_COLOR := Color(0.1, 0.2, 0.35)
const ACCENT := Color(0.28, 0.62, 0.95)

const MOVE_SPEED := 4.8
const TURN_SPEED := 8.0
const WAYPOINT_REACH_M := 1.1
const GREET_RANGE := 7.5
const GREET_COOLDOWN := 18.0
const PROMPT := "Fråga Guide-Bot [E]"

var _spawn_id := ""
var _robot_label := "Guide-Bot"
var _rng := RandomNumberGenerator.new()
var _roam_center := Vector3.ZERO
var _roam_half := Vector3(28.0, 0.0, 28.0)
var _waypoint := Vector3.ZERO
var _time := 0.0
var _greet_cooldown := 0.0
var _was_near_player := false
var _player_inside := false

var _body: Node3D
var _head: Node3D
var _antenna: Node3D
var _name_label: Label3D
var _voice_player: AudioStreamPlayer3D
var _interact_area: Area3D


func setup(config: Dictionary) -> void:
	_spawn_id = str(config.get("spawn_id", ""))
	_robot_label = str(config.get("label", HelpRobotCatalogScript.get_robot_label(_spawn_id)))
	_rng.seed = int(config.get("seed", randi()))
	_time = _rng.randf_range(0.0, TAU)
	global_position = config.get("position", Vector3.ZERO)
	_roam_center = config.get("roam_center", global_position)
	_roam_half = config.get("roam_half", Vector3(28.0, 0.0, 28.0))
	_build_robot()
	_build_collision()
	_build_interact_area()
	_build_voice()
	_pick_waypoint()
	set_physics_process(true)
	add_to_group("help_robot")


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	return PROMPT


func try_open_dialog(dialog_ui: HelpRobotDialogUI) -> bool:
	if dialog_ui == null:
		return false
	dialog_ui.open(_spawn_id, _robot_label)
	_pulse_antenna()
	return true


func _physics_process(delta: float) -> void:
	_time += delta
	_greet_cooldown = maxf(0.0, _greet_cooldown - delta)
	_animate_robot(delta)

	if not _is_simulation_authority():
		return

	_tick_greeting()

	var to_waypoint := _waypoint - global_position
	to_waypoint.y = 0.0
	var dist := to_waypoint.length()
	if dist < WAYPOINT_REACH_M:
		_pick_waypoint()
		to_waypoint = _waypoint - global_position
		to_waypoint.y = 0.0
		dist = to_waypoint.length()

	if dist > 0.05:
		var dir := to_waypoint / dist
		velocity = dir * MOVE_SPEED
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
	else:
		velocity = Vector3.ZERO

	move_and_slide()
	global_position.y = _roam_center.y

	if multiplayer.multiplayer_peer != null:
		_sync_motion.rpc(global_position, rotation.y, velocity.length() > 0.2)


func _tick_greeting() -> void:
	var player := _find_local_player()
	if player == null:
		_was_near_player = false
		return

	var near := global_position.distance_to(player.global_position) <= GREET_RANGE
	if near and not _was_near_player and _greet_cooldown <= 0.0:
		_greet_cooldown = GREET_COOLDOWN
		var greet_text := "Behöver du hjälp? Tryck E för att ställa en fråga!"
		NpcDialogueBarkScript.play_for_npc(self, "greeting", "sean")
		QuestManager.story_toast.emit(_robot_label, greet_text)
	_was_near_player = near


func _find_local_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("game_director"):
		if node.has_method("get_local_player"):
			return node.get_local_player()
	return null


func _pick_waypoint() -> void:
	for _attempt in range(8):
		var offset := Vector3(
			_rng.randf_range(-_roam_half.x, _roam_half.x),
			0.0,
			_rng.randf_range(-_roam_half.z, _roam_half.z)
		)
		var candidate := _roam_center + offset
		if candidate.distance_to(global_position) > 6.0:
			_waypoint = candidate
			return
	_waypoint = _roam_center + Vector3(
		_rng.randf_range(-_roam_half.x, _roam_half.x),
		0.0,
		_rng.randf_range(-_roam_half.z, _roam_half.z)
	)


func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.35
	shape_node.shape = capsule
	shape_node.position = Vector3(0.0, 0.72, 0.0)
	add_child(shape_node)
	collision_layer = 4
	collision_mask = 1


func _build_interact_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.position = Vector3(0.0, 0.9, 0.0)
	add_child(_interact_area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 2.4, 2.6)
	shape.shape = box
	_interact_area.add_child(shape)

	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _build_voice() -> void:
	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "Voice"
	_voice_player.bus = &"Sfx"
	_voice_player.max_distance = 24.0
	_voice_player.position = Vector3(0.0, 1.2, 0.0)
	add_child(_voice_player)


func _pulse_antenna() -> void:
	if _antenna:
		_antenna.scale = Vector3(1.15, 1.15, 1.15)


func _animate_robot(delta: float) -> void:
	if _body:
		_body.position.y = sin(_time * 2.4) * 0.03
		_body.rotation.z = sin(_time * 1.1) * 0.05
	if _head:
		_head.rotation.y = sin(_time * 0.7) * 0.1
	if _antenna:
		_antenna.rotation.z = sin(_time * 3.0) * 0.22
		_antenna.scale = _antenna.scale.lerp(Vector3.ONE, delta * 6.0)


func _build_robot() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	var torso := _sphere("Torso", _body, Vector3(0.0, 0.72, 0.0), Vector3(0.4, 0.36, 0.34), BODY_COLOR)
	torso.material_override = _soft_mat(BODY_COLOR)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 1.16, 0.0)
	_body.add_child(_head)

	var skull := _sphere("Skull", _head, Vector3.ZERO, Vector3(0.34, 0.3, 0.28), BODY_COLOR.lightened(0.05))
	skull.material_override = _soft_mat(BODY_COLOR.lightened(0.05))

	for side in [-1.0, 1.0]:
		var eye := _sphere("Eye", _head, Vector3(0.1 * side, 0.05, -0.18), Vector3(0.1, 0.12, 0.07), EYE_WHITE)
		eye.material_override = _soft_mat(EYE_WHITE, 0.12)
		var pupil := _sphere("Pupil", _head, Vector3(0.1 * side, 0.03, -0.23), Vector3(0.04, 0.05, 0.03), PUPIL_COLOR)
		pupil.material_override = _glow_mat(PUPIL_COLOR, 0.25)
		var cheek := _sphere("Cheek", _head, Vector3(0.16 * side, -0.03, -0.16), Vector3(0.06, 0.05, 0.04), CHEEK_COLOR)
		cheek.material_override = _soft_mat(CHEEK_COLOR, 0.3)

	var badge := _box("HelpBadge", _body, Vector3(0.0, 0.84, -0.26), Vector3(0.22, 0.22, 0.04), ACCENT)
	badge.material_override = _glow_mat(ACCENT, 0.5)
	var q_mark := _box("QMark", _body, Vector3(0.0, 0.9, -0.28), Vector3(0.06, 0.1, 0.03), Color(0.95, 0.98, 1.0))
	q_mark.material_override = _glow_mat(Color(0.95, 0.98, 1.0), 0.35)

	_antenna = Node3D.new()
	_antenna.name = "Antenna"
	_antenna.position = Vector3(0.0, 0.2, 0.0)
	_head.add_child(_antenna)
	var stalk := _capsule("Stalk", _antenna, Vector3.ZERO, Vector3(0.025, 0.1, 0.025), ACCENT)
	stalk.material_override = _glow_mat(ACCENT, 0.4)
	var tip := _sphere("Tip", _antenna, Vector3(0.0, 0.14, 0.0), Vector3(0.05, 0.05, 0.05), CHEEK_COLOR)
	tip.material_override = _glow_mat(CHEEK_COLOR, 0.55)

	_name_label = Label3D.new()
	_name_label.text = _robot_label
	_name_label.font_size = 40
	_name_label.modulate = ACCENT.lightened(0.2)
	_name_label.outline_modulate = Color(0.06, 0.1, 0.16, 0.95)
	_name_label.position = Vector3(0.0, 1.62, 0.0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false


func _is_simulation_authority() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return is_multiplayer_authority()


@rpc("any_peer", "unreliable")
func _sync_motion(pos: Vector3, yaw: float, moving: bool) -> void:
	if _is_simulation_authority():
		return
	global_position = pos
	rotation.y = yaw
	if not moving:
		velocity = Vector3.ZERO


func _sphere(name: String, parent: Node3D, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh.mesh = sphere
	mesh.position = pos
	mesh.scale = scale
	parent.add_child(mesh)
	return mesh


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


func _soft_mat(color: Color, emission := 0.1) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.08
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat


func _glow_mat(color: Color, strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = strength
	mat.roughness = 0.25
	return mat