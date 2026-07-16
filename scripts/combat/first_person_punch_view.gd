class_name FirstPersonPunchView
extends Node3D

const PUNCH_DURATION := 0.42

var _punch_timer := 0.0
var _skin_color := Color(0.86, 0.72, 0.58)
var _sleeve_color := Color(0.28, 0.32, 0.4)

var _pivot: Node3D
var _upper_arm: Node3D
var _forearm_pivot: Node3D
var _fist_pivot: Node3D


static func ensure_on(player: Node3D) -> FirstPersonPunchView:
	var existing := player.get_node_or_null("FirstPersonPunchView") as FirstPersonPunchView
	if existing:
		return existing
	var view := FirstPersonPunchView.new()
	view.name = "FirstPersonPunchView"
	player.add_child(view)
	return view


func _ready() -> void:
	_build_arm()
	top_level = true


func apply_avatar_colors(skin: Color, sleeve: Color = Color(0.28, 0.32, 0.4)) -> void:
	_skin_color = skin
	_sleeve_color = sleeve
	_recolor_arm()


func trigger_punch() -> void:
	_punch_timer = PUNCH_DURATION


func is_punching() -> bool:
	return _punch_timer > 0.0


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		visible = false
		return
	visible = true
	global_transform = camera.global_transform

	if _punch_timer > 0.0:
		_punch_timer = maxf(0.0, _punch_timer - delta)
		_apply_pose(1.0 - (_punch_timer / PUNCH_DURATION))
	else:
		_apply_idle_pose()


func _apply_idle_pose() -> void:
	if _pivot == null:
		return
	_pivot.position = Vector3(0.34, -0.28, -0.48)
	_pivot.rotation_degrees = Vector3(8.0, -18.0, 4.0)
	_upper_arm.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	_forearm_pivot.rotation_degrees = Vector3(-32.0, 0.0, 0.0)
	_fist_pivot.rotation_degrees = Vector3(-8.0, 0.0, 0.0)


func _apply_pose(phase: float) -> void:
	if _pivot == null:
		return

	var windup := 1.0 - smoothstep(0.0, 0.2, phase)
	var strike := smoothstep(0.16, 0.3, phase) * (1.0 - smoothstep(0.36, 0.52, phase))
	var recover := smoothstep(0.5, 1.0, phase)

	var base_pos := Vector3(0.34, -0.28, -0.48)
	var strike_forward := Vector3(0.0, 0.03, 0.24) * strike
	var windup_back := Vector3(-0.05, 0.02, -0.1) * windup
	_pivot.position = base_pos + strike_forward + windup_back
	_pivot.rotation_degrees = Vector3(
		lerpf(8.0, -6.0, strike),
		lerpf(-18.0, -8.0, strike),
		lerpf(4.0, -10.0, strike)
	)

	_upper_arm.rotation_degrees = Vector3(
		lerpf(-18.0, -88.0, windup) + lerpf(0.0, 42.0, strike) + lerpf(0.0, -16.0, recover),
		lerpf(0.0, -8.0, strike),
		lerpf(0.0, 6.0, strike)
	)
	_forearm_pivot.rotation_degrees = Vector3(
		lerpf(-32.0, -92.0, windup) + lerpf(0.0, 58.0, strike) + lerpf(0.0, -24.0, recover),
		0.0,
		lerpf(0.0, 4.0, strike)
	)
	_fist_pivot.rotation_degrees = Vector3(
		lerpf(-8.0, -18.0, windup) + lerpf(0.0, 24.0, strike),
		lerpf(0.0, -6.0, strike),
		0.0
	)


func _build_arm() -> void:
	_pivot = Node3D.new()
	_pivot.name = "PunchPivot"
	add_child(_pivot)

	_upper_arm = Node3D.new()
	_upper_arm.name = "UpperArm"
	_pivot.add_child(_upper_arm)
	_add_limb_mesh(
		_upper_arm,
		Vector3(0.11, 0.24, 0.11),
		Vector3(0.0, -0.12, 0.0),
		_sleeve_color,
		0.18
	)

	_forearm_pivot = Node3D.new()
	_forearm_pivot.name = "ForearmPivot"
	_forearm_pivot.position = Vector3(0.0, -0.24, 0.02)
	_upper_arm.add_child(_forearm_pivot)
	_add_limb_mesh(
		_forearm_pivot,
		Vector3(0.1, 0.22, 0.1),
		Vector3(0.0, -0.11, 0.0),
		_skin_color,
		0.12
	)

	_fist_pivot = Node3D.new()
	_fist_pivot.name = "FistPivot"
	_fist_pivot.position = Vector3(0.0, -0.22, 0.0)
	_forearm_pivot.add_child(_fist_pivot)
	_add_limb_mesh(
		_fist_pivot,
		Vector3(0.13, 0.11, 0.12),
		Vector3(0.0, -0.04, 0.02),
		_skin_color,
		0.1
	)
	_add_knuckle_row(_fist_pivot, Vector3(0.0, 0.02, -0.07))

	_apply_idle_pose()


func _add_limb_mesh(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	color: Color,
	roughness: float
) -> void:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _limb_material(color, roughness)
	parent.add_child(mesh_inst)


func _add_knuckle_row(parent: Node3D, pos: Vector3) -> void:
	for i in range(4):
		var knuckle := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.022
		mesh.height = 0.044
		knuckle.mesh = mesh
		knuckle.position = pos + Vector3(-0.045 + float(i) * 0.03, 0.0, 0.0)
		knuckle.material_override = _limb_material(_skin_color.lightened(0.08), 0.28)
		parent.add_child(knuckle)


func _limb_material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.05
	return mat


func _recolor_arm() -> void:
	if _pivot == null:
		return
	for node in _pivot.get_children():
		_recolor_node(node, _sleeve_color, _skin_color)


func _recolor_node(node: Node, sleeve: Color, skin: Color) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh is SphereMesh:
			mesh.material_override = _limb_material(skin.lightened(0.08), 0.28)
		elif node.get_parent() == _upper_arm:
			mesh.material_override = _limb_material(sleeve, 0.18)
		else:
			mesh.material_override = _limb_material(skin, 0.12)
	for child in node.get_children():
		_recolor_node(child, sleeve, skin)