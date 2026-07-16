class_name NpcHealthBar3D
extends Node3D

const BAR_WIDTH := 1.35
const BAR_HEIGHT := 0.16
const BAR_DEPTH := 0.04

var _fill: MeshInstance3D
var _camera: Camera3D


func _ready() -> void:
	_build()
	set_ratio(1.0)


func _process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	var to_cam := _camera.global_position - global_position
	to_cam.y = 0.0
	if to_cam.length_squared() > 0.01:
		look_at(global_position + to_cam.normalized(), Vector3.UP)


func set_ratio(ratio: float) -> void:
	if _fill == null:
		return
	ratio = clampf(ratio, 0.0, 1.0)
	_fill.scale.x = maxf(ratio, 0.02)
	_fill.position.x = -BAR_WIDTH * 0.5 + (_fill.scale.x * BAR_WIDTH * 0.5)
	var mat := _fill.material_override as StandardMaterial3D
	if mat == null:
		return
	if ratio > 0.55:
		mat.albedo_color = Color(0.22, 0.88, 0.28)
		mat.emission = Color(0.18, 0.72, 0.22)
	elif ratio > 0.25:
		mat.albedo_color = Color(0.92, 0.78, 0.12)
		mat.emission = Color(0.82, 0.62, 0.08)
	else:
		mat.albedo_color = Color(0.92, 0.18, 0.12)
		mat.emission = Color(0.82, 0.12, 0.08)


func _build() -> void:
	var frame := _make_quad("Frame", BAR_WIDTH + 0.08, BAR_HEIGHT + 0.08, Color(0.04, 0.04, 0.05), 0.0)
	add_child(frame)

	var bg := _make_quad("Background", BAR_WIDTH, BAR_HEIGHT, Color(0.45, 0.08, 0.08), -0.01)
	add_child(bg)

	_fill = _make_quad("Fill", BAR_WIDTH, BAR_HEIGHT, Color(0.22, 0.88, 0.28), 0.35)
	_fill.scale.x = 1.0
	add_child(_fill)


func _make_quad(
	quad_name: String,
	width: float,
	height: float,
	color: Color,
	emission_strength: float
) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = quad_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, BAR_DEPTH)
	mesh_node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_strength
	mesh_node.material_override = mat
	return mesh_node