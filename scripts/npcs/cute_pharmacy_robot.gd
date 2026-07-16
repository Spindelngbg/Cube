class_name CutePharmacyRobot
extends Node3D

const BODY_COLOR := Color(0.82, 0.96, 0.9)
const CHEEK_COLOR := Color(0.95, 0.55, 0.62)
const EYE_WHITE := Color(0.98, 0.99, 1.0)
const PUPIL_COLOR := Color(0.12, 0.16, 0.22)
const ACCENT := Color(0.35, 0.82, 0.62)

var _body: Node3D
var _head: Node3D
var _left_eye: MeshInstance3D
var _right_eye: MeshInstance3D
var _left_pupil: MeshInstance3D
var _right_pupil: MeshInstance3D
var _antenna: Node3D
var _heart: MeshInstance3D
var _name_label: Label3D
var _time := 0.0
var _blink_timer := 0.0
var _blinking := false
var _player_near := false
var _happy_timer := 0.0


func _ready() -> void:
	_build_robot()
	_time = randf_range(0.0, TAU)
	set_process(true)


func set_player_nearby(near: bool) -> void:
	_player_near = near
	if near:
		_happy_timer = 0.6


func play_happy_reaction() -> void:
	_happy_timer = 1.1


func _build_robot() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	var torso := _sphere("Torso", _body, Vector3(0.0, 0.72, 0.0), Vector3(0.42, 0.38, 0.36), BODY_COLOR)
	torso.material_override = _soft_mat(BODY_COLOR)

	var belly := _sphere("Belly", _body, Vector3(0.0, 0.58, 0.14), Vector3(0.28, 0.22, 0.14), BODY_COLOR.lightened(0.08))
	belly.material_override = _soft_mat(BODY_COLOR.lightened(0.06))

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 1.18, 0.0)
	_body.add_child(_head)

	var skull := _sphere("Skull", _head, Vector3.ZERO, Vector3(0.36, 0.32, 0.3), BODY_COLOR.lightened(0.04))
	skull.material_override = _soft_mat(BODY_COLOR.lightened(0.04))

	_left_eye = _sphere("LeftEye", _head, Vector3(-0.11, 0.06, -0.2), Vector3(0.11, 0.13, 0.08), EYE_WHITE)
	_left_eye.material_override = _soft_mat(EYE_WHITE, 0.15)
	_right_eye = _sphere("RightEye", _head, Vector3(0.11, 0.06, -0.2), Vector3(0.11, 0.13, 0.08), EYE_WHITE)
	_right_eye.material_override = _soft_mat(EYE_WHITE, 0.15)

	_left_pupil = _sphere("LeftPupil", _head, Vector3(-0.11, 0.04, -0.26), Vector3(0.045, 0.055, 0.03), PUPIL_COLOR)
	_left_pupil.material_override = _glow_mat(PUPIL_COLOR, 0.2)
	_right_pupil = _sphere("RightPupil", _head, Vector3(0.11, 0.04, -0.26), Vector3(0.045, 0.055, 0.03), PUPIL_COLOR)
	_right_pupil.material_override = _glow_mat(PUPIL_COLOR, 0.2)

	for side in [-1.0, 1.0]:
		var cheek := _sphere("Cheek", _head, Vector3(0.17 * side, -0.02, -0.18), Vector3(0.07, 0.05, 0.04), CHEEK_COLOR)
		cheek.material_override = _soft_mat(CHEEK_COLOR, 0.35)

	var cross := _box("Cross", _body, Vector3(0.0, 0.82, -0.28), Vector3(0.06, 0.22, 0.03), ACCENT)
	cross.material_override = _glow_mat(ACCENT, 0.55)
	var cross_h := _box("CrossH", _body, Vector3(0.0, 0.82, -0.28), Vector3(0.18, 0.06, 0.03), ACCENT)
	cross_h.material_override = _glow_mat(ACCENT, 0.55)

	for side in [-1.0, 1.0]:
		var arm := _capsule("Arm", _body, Vector3(0.34 * side, 0.78, 0.02), Vector3(0.07, 0.16, 0.07), BODY_COLOR)
		arm.rotation.z = deg_to_rad(18.0 * side)
		arm.material_override = _soft_mat(BODY_COLOR)

	_antenna = Node3D.new()
	_antenna.name = "Antenna"
	_antenna.position = Vector3(0.0, 0.22, 0.0)
	_head.add_child(_antenna)
	var stalk := _capsule("Stalk", _antenna, Vector3.ZERO, Vector3(0.025, 0.12, 0.025), ACCENT)
	stalk.material_override = _glow_mat(ACCENT, 0.4)
	_heart = _sphere("Heart", _antenna, Vector3(0.0, 0.16, 0.0), Vector3(0.06, 0.06, 0.05), CHEEK_COLOR)
	_heart.material_override = _glow_mat(CHEEK_COLOR, 0.65)

	_name_label = Label3D.new()
	_name_label.text = "Pill-Bot"
	_name_label.font_size = 42
	_name_label.modulate = ACCENT.lightened(0.15)
	_name_label.outline_modulate = Color(0.08, 0.12, 0.1, 0.95)
	_name_label.position = Vector3(0.0, 1.65, 0.0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)


func _process(delta: float) -> void:
	_time += delta
	_blink_timer -= delta
	if _blink_timer <= 0.0 and not _blinking:
		_start_blink()
	if _blinking and _blink_timer <= -0.12:
		_end_blink()
		_blink_timer = randf_range(2.4, 5.2)

	var bob := sin(_time * 2.6) * 0.035
	var sway := sin(_time * 1.3) * 0.04
	position.y = bob
	_body.rotation.z = sway

	if _head:
		var look := sin(_time * 0.85) * 0.08
		if _player_near:
			look += sin(_time * 6.0) * 0.05
		_head.rotation.x = look
		_head.rotation.y = sin(_time * 0.55) * 0.12

	if _antenna:
		_antenna.rotation.z = sin(_time * 3.2) * 0.25
	if _heart:
		var pulse := 1.0 + sin(_time * 5.5) * 0.18
		if _happy_timer > 0.0:
			_happy_timer -= delta
			pulse = 1.0 + sin(_time * 14.0) * 0.28
		_heart.scale = Vector3.ONE * pulse

	if _left_pupil and _right_pupil and not _blinking:
		var wobble := sin(_time * 2.0) * 0.012
		_left_pupil.position.x = -0.11 + wobble
		_right_pupil.position.x = 0.11 + wobble


func _start_blink() -> void:
	_blinking = true
	if _left_eye:
		_left_eye.scale.y = 0.12
	if _right_eye:
		_right_eye.scale.y = 0.12


func _end_blink() -> void:
	_blinking = false
	if _left_eye:
		_left_eye.scale.y = 0.13
	if _right_eye:
		_right_eye.scale.y = 0.13


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


func _soft_mat(color: Color, emission := 0.12) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.08
	mat.rim_enabled = true
	mat.rim = 0.55
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.35
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