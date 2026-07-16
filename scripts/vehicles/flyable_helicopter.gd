class_name FlyableHelicopter
extends CharacterBody3D

const ProceduralSfxScript = preload("res://scripts/audio/procedural_sfx.gd")

const FORWARD_SPEED := 20.0
const STRAFE_SPEED := 16.0
const VERTICAL_SPEED := 11.0
const TURN_SPEED := 2.4
const GRAVITY := 6.0
const HOVER_DAMP := 4.5

var _pilot_peer_id := -1
var _main_rotor: Node3D
var _tail_rotor: Node3D
var _rotor_speed := 0.0
var _engine_player: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()


func setup_at(world_pos: Vector3, pilot_peer_id: int) -> void:
	_pilot_peer_id = pilot_peer_id
	_rng.seed = hash(str(world_pos))
	global_position = world_pos + Vector3(0.0, 2.5, 0.0)
	_build_model()
	_build_collision()
	_build_audio()
	set_physics_process(true)
	add_to_group("flyable_helicopter")


func is_piloted_by(peer_id: int) -> bool:
	return _pilot_peer_id == peer_id


func get_camera_anchor_global_position() -> Vector3:
	return global_position + Vector3(0.0, 1.75, 0.35)


func release_pilot() -> void:
	_pilot_peer_id = -1
	velocity = Vector3.ZERO
	if _engine_player:
		_engine_player.stop()


func _physics_process(delta: float) -> void:
	_rotor_speed = lerpf(_rotor_speed, 28.0 if _pilot_peer_id >= 0 else 0.0, delta * 3.5)
	if _main_rotor:
		_main_rotor.rotation.y += _rotor_speed * delta
	if _tail_rotor:
		_tail_rotor.rotation.x += _rotor_speed * delta * 1.6

	if not _is_local_pilot():
		return

	var yaw_input := Input.get_axis("move_right", "move_left")
	rotation.y += yaw_input * TURN_SPEED * delta

	var basis_flat := global_transform.basis
	var forward := Vector3(-basis_flat.z.x, 0.0, -basis_flat.z.z).normalized()
	var right := Vector3(basis_flat.x.x, 0.0, basis_flat.x.z).normalized()
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	velocity.x = (forward.x * move_input.y + right.x * move_input.x) * FORWARD_SPEED
	velocity.z = (forward.z * move_input.y + right.z * move_input.x) * FORWARD_SPEED

	var vertical := 0.0
	if Input.is_action_pressed("jump"):
		vertical += VERTICAL_SPEED
	if Input.is_action_pressed("sprint"):
		vertical -= VERTICAL_SPEED
	velocity.y = lerpf(velocity.y, vertical, HOVER_DAMP * delta)
	if vertical == 0.0:
		velocity.y = lerpf(velocity.y, 0.0, delta * 2.5)

	move_and_slide()


func _is_local_pilot() -> bool:
	if _pilot_peer_id < 0:
		return false
	if multiplayer.multiplayer_peer == null:
		return true
	return _pilot_peer_id == multiplayer.get_unique_id()


func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.2, 3.2)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.75, 0.0)
	add_child(shape_node)
	collision_layer = 4
	collision_mask = 1


func _build_model() -> void:
	var body_color := Color(0.28, 0.34, 0.42)
	var accent := Color(0.95, 0.22, 0.18)

	var body := _box("Body", Vector3(0.0, 0.72, 0.0), Vector3(1.35, 0.78, 2.35), body_color)
	body.material_override = _mat(body_color, 0.08)

	var cockpit := _box("Cockpit", Vector3(0.0, 1.05, -0.35), Vector3(0.95, 0.55, 1.05), Color(0.45, 0.72, 0.92, 0.55))
	var cockpit_mat := StandardMaterial3D.new()
	cockpit_mat.albedo_color = Color(0.45, 0.72, 0.92, 0.55)
	cockpit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cockpit_mat.roughness = 0.15
	cockpit.material_override = cockpit_mat

	var skid_l := _box("SkidL", Vector3(-0.55, 0.18, 0.15), Vector3(0.08, 0.08, 1.6), body_color.darkened(0.1))
	skid_l.material_override = _mat(body_color.darkened(0.1), 0.02)
	var skid_r := _box("SkidR", Vector3(0.55, 0.18, 0.15), Vector3(0.08, 0.08, 1.6), body_color.darkened(0.1))
	skid_r.material_override = _mat(body_color.darkened(0.1), 0.02)

	var tail := _box("Tail", Vector3(0.0, 0.95, 1.45), Vector3(0.22, 0.28, 1.35), body_color)
	tail.material_override = _mat(body_color, 0.06)

	_main_rotor = Node3D.new()
	_main_rotor.name = "MainRotor"
	_main_rotor.position = Vector3(0.0, 1.45, -0.15)
	add_child(_main_rotor)
	for i in range(4):
		var blade := _box("Blade", Vector3.ZERO, Vector3(0.12, 0.03, 2.6), accent)
		blade.rotation.y = float(i) * PI * 0.5
		blade.material_override = _glow(accent, 0.25)
		_main_rotor.add_child(blade)

	_tail_rotor = Node3D.new()
	_tail_rotor.name = "TailRotor"
	_tail_rotor.position = Vector3(0.0, 1.05, 2.35)
	add_child(_tail_rotor)
	var tail_blade := _box("TailBlade", Vector3.ZERO, Vector3(0.55, 0.04, 0.08), accent)
	tail_blade.material_override = _glow(accent, 0.2)
	_tail_rotor.add_child(tail_blade)

	var stripe := _box("Stripe", Vector3(0.0, 0.82, -0.2), Vector3(1.38, 0.08, 0.35), accent)
	stripe.material_override = _glow(accent, 0.35)


func _build_audio() -> void:
	_engine_player = AudioStreamPlayer3D.new()
	_engine_player.name = "RotorHum"
	_engine_player.bus = &"Sfx"
	_engine_player.max_distance = 48.0
	_engine_player.position = Vector3(0.0, 1.4, 0.0)
	_engine_player.stream = ProceduralSfxScript.engine_loop_stream()
	_engine_player.pitch_scale = 0.35
	_engine_player.volume_db = -16.0
	add_child(_engine_player)


func _box(name: String, pos: Vector3, scale: Vector3, _color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = BoxMesh.new()
	mesh.position = pos
	mesh.scale = scale
	add_child(mesh)
	return mesh


func _mat(color: Color, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.35
	mat.roughness = 0.62
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
