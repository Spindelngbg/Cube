class_name DeliveryBot
extends CharacterBody3D

const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")
const ProceduralSfxScript = preload("res://scripts/audio/procedural_sfx.gd")
const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

const MOVE_SPEED := 7.2
const HONK_RANGE := 9.5
const HONK_COOLDOWN := 4.5
const TURN_SPEED := 10.0
const WAYPOINT_REACH_M := 1.15
const PACKAGE_COLORS := [
	Color(0.62, 0.48, 0.32),
	Color(0.55, 0.42, 0.3),
	Color(0.68, 0.52, 0.36),
	Color(0.5, 0.38, 0.28),
]

var _rng := RandomNumberGenerator.new()
var _roam_center := Vector3.ZERO
var _roam_half := Vector3(80.0, 0.0, 80.0)
var _waypoint := Vector3.ZERO
var _accent := Color(0.35, 0.72, 0.95)
var _time := 0.0

var _chassis: Node3D
var _package: Node3D
var _wheels: Array[Node3D] = []
var _status_light: MeshInstance3D
var _trail_timer := 0.0
var _honk_cooldown := 0.0
var _was_near_player := false
var _honk_player: AudioStreamPlayer3D


func setup(config: Dictionary) -> void:
	_rng.seed = int(config.get("seed", randi()))
	_time = _rng.randf_range(0.0, TAU)
	global_position = config.get("position", Vector3.ZERO)
	_roam_center = config.get("roam_center", global_position)
	_roam_half = config.get("roam_half", Vector3(80.0, 0.0, 80.0))
	_accent = config.get("accent", Color(0.35, 0.72, 0.95))
	_build_bot(config)
	_build_collision()
	_build_honk_audio()
	_pick_waypoint()
	set_physics_process(true)
	add_to_group("delivery_bot")


func _physics_process(delta: float) -> void:
	if not _is_simulation_authority():
		return
	_time += delta
	_trail_timer -= delta
	_honk_cooldown = maxf(0.0, _honk_cooldown - delta)
	_tick_honk()

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
	_animate_bot(delta)

	if multiplayer.multiplayer_peer != null:
		_sync_motion.rpc(global_position, rotation.y, velocity.length() > 0.35)


func _pick_waypoint() -> void:
	for _attempt in range(8):
		var offset := Vector3(
			_rng.randf_range(-_roam_half.x, _roam_half.x),
			0.0,
			_rng.randf_range(-_roam_half.z, _roam_half.z)
		)
		var candidate := _roam_center + offset
		if candidate.distance_to(global_position) > 12.0:
			_waypoint = candidate
			return
	_waypoint = _roam_center + Vector3(
		_rng.randf_range(-_roam_half.x, _roam_half.x),
		0.0,
		_rng.randf_range(-_roam_half.z, _roam_half.z)
	)


func _build_honk_audio() -> void:
	_honk_player = AudioStreamPlayer3D.new()
	_honk_player.name = "Honk"
	_honk_player.bus = &"Sfx"
	_honk_player.max_distance = 22.0
	_honk_player.position = Vector3(0.0, 0.42, 0.28)
	_honk_player.stream = ProceduralSfxScript.honk_stream()
	add_child(_honk_player)


func _tick_honk() -> void:
	var player := _find_local_player()
	if player == null:
		_was_near_player = false
		return
	var dist := global_position.distance_to(player.global_position)
	var near := dist <= HONK_RANGE
	var speed := Vector2(velocity.x, velocity.z).length()
	if near and speed > 2.5 and not _was_near_player and _honk_cooldown <= 0.0:
		if _rng.randf() < 0.35:
			NpcDialogueBarkScript.play_for_npc(self, "miscellaneous", "alex")
		else:
			_play_honk()
		_honk_cooldown = HONK_COOLDOWN + _rng.randf_range(0.0, 1.5)
	_was_near_player = near


func _play_honk() -> void:
	if _honk_player == null:
		return
	_honk_player.pitch_scale = _rng.randf_range(0.94, 1.06)
	_honk_player.volume_db = _rng.randf_range(-8.0, -5.0)
	_honk_player.play()


func _find_local_player() -> Node3D:
	var local_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	for node in get_tree().get_nodes_in_group("game_director"):
		if not node.get("players") is Dictionary:
			continue
		var roster: Dictionary = node.players
		if roster.has(local_id):
			var player = roster[local_id]
			if player is Node3D and is_instance_valid(player):
				return player as Node3D
	return null


func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.72, 0.42, 0.92)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.22, 0.0)
	add_child(shape_node)
	collision_layer = 4
	collision_mask = 1


func _build_bot(config: Dictionary) -> void:
	_chassis = Node3D.new()
	_chassis.name = "Chassis"
	add_child(_chassis)

	var body_color := Color(0.22, 0.24, 0.28)
	var deck := _box("Deck", _chassis, Vector3(0.0, 0.18, 0.0), Vector3(0.68, 0.12, 0.88), body_color)
	deck.material_override = _mat(body_color, 0.08)

	var cabin := _box("Cabin", _chassis, Vector3(0.0, 0.34, -0.18), Vector3(0.42, 0.2, 0.34), body_color.lightened(0.08))
	cabin.material_override = _mat(body_color.lightened(0.08), 0.1)

	var visor := _box("Visor", _chassis, Vector3(0.0, 0.36, -0.34), Vector3(0.28, 0.1, 0.06), _accent)
	visor.material_override = _glow(_accent, 0.85)

	_status_light = _box("StatusLight", _chassis, Vector3(0.0, 0.42, 0.32), Vector3(0.08, 0.05, 0.05), _accent)
	_status_light.material_override = _glow(_accent, 1.1)

	for side in [-1.0, 1.0]:
		var wheel_root := Node3D.new()
		wheel_root.name = "Wheel_%d" % int(side)
		wheel_root.position = Vector3(0.34 * side, 0.08, 0.24)
		_chassis.add_child(wheel_root)
		var wheel := _cylinder("Tire", wheel_root, Vector3.ZERO, Vector3(0.12, 0.05, 0.12), Color(0.08, 0.09, 0.1))
		wheel.rotation.z = PI * 0.5
		wheel.material_override = _mat(Color(0.08, 0.09, 0.1), 0.02)
		_wheels.append(wheel_root)

		var wheel_back := Node3D.new()
		wheel_back.name = "WheelBack_%d" % int(side)
		wheel_back.position = Vector3(0.34 * side, 0.08, -0.24)
		_chassis.add_child(wheel_back)
		var tire_back := _cylinder("Tire", wheel_back, Vector3.ZERO, Vector3(0.12, 0.05, 0.12), Color(0.08, 0.09, 0.1))
		tire_back.rotation.z = PI * 0.5
		tire_back.material_override = _mat(Color(0.08, 0.09, 0.1), 0.02)
		_wheels.append(wheel_back)

	var stripe := _box("Stripe", _chassis, Vector3(0.0, 0.24, 0.0), Vector3(0.7, 0.03, 0.12), _accent)
	stripe.material_override = _glow(_accent, 0.45)

	_package = Node3D.new()
	_package.name = "Package"
	_package.position = Vector3(0.0, 0.42, 0.06)
	_chassis.add_child(_package)

	var package_color: Color = PACKAGE_COLORS[_rng.randi() % PACKAGE_COLORS.size()]
	var box_h := _rng.randf_range(0.34, 0.48)
	var box_w := _rng.randf_range(0.38, 0.52)
	var box_d := _rng.randf_range(0.34, 0.46)
	var carton := _box("Carton", _package, Vector3(0.0, box_h * 0.5, 0.0), Vector3(box_w, box_h, box_d), package_color)
	carton.material_override = _mat(package_color, 0.04)

	var tape_color := Color(0.78, 0.72, 0.58)
	var tape_v := _box("TapeV", _package, Vector3(0.0, box_h * 0.5, 0.0), Vector3(0.07, box_h + 0.02, box_d + 0.02), tape_color)
	tape_v.material_override = _mat(tape_color, 0.02)
	var tape_h := _box("TapeH", _package, Vector3(0.0, box_h * 0.5, 0.0), Vector3(box_w + 0.02, 0.07, box_d + 0.02), tape_color)
	tape_h.material_override = _mat(tape_color, 0.02)

	var label := Label3D.new()
	label.text = str(config.get("label", "PAKET"))
	label.font_size = 22
	label.modulate = Color(0.18, 0.14, 0.1)
	label.position = Vector3(0.0, box_h * 0.55, box_d * 0.5 + 0.02)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_package.add_child(label)


func _animate_bot(delta: float) -> void:
	if _chassis == null:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	var moving := speed > 0.4
	var bob := sin(_time * 14.0) * 0.012 if moving else 0.0
	_chassis.position.y = bob

	if _package:
		var wobble := sin(_time * 11.0) * 0.03 if moving else 0.0
		_package.rotation.x = wobble
		_package.rotation.z = sin(_time * 8.5) * 0.025 if moving else 0.0

	for wheel in _wheels:
		if wheel:
			wheel.rotation.x += speed * delta * 0.85

	if _status_light and _status_light.material_override is StandardMaterial3D:
		var mat := _status_light.material_override as StandardMaterial3D
		var pulse := 0.65 + sin(_time * 9.0) * 0.35
		mat.emission_energy_multiplier = pulse


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
	if _chassis and not moving:
		_chassis.position.y = 0.0


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
