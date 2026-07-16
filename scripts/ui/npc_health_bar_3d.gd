class_name NpcHealthBar3D
extends Node3D

const BAR_WIDTH := 1.1
const BAR_HEIGHT := 0.1
const BAR_DEPTH := 0.02
const TWEEN_SEC := 0.18

var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _camera: Camera3D
var _ratio := 1.0
var _ratio_tween: Tween


func _ready() -> void:
	_build()
	visible = false
	set_process(false)
	_apply_ratio_visual(1.0, false)


func _process(_delta: float) -> void:
	if not visible:
		return
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	var to_cam := _camera.global_position - global_position
	to_cam.y = 0.0
	if to_cam.length_squared() > 0.01:
		look_at(global_position + to_cam.normalized(), Vector3.UP)


func update_health(current: float, maximum: float, dead: bool) -> void:
	maximum = maxf(maximum, 1.0)
	current = clampf(current, 0.0, maximum)
	var ratio := current / maximum
	var show := not dead and ratio < 0.995
	if show != visible:
		visible = show
		set_process(show)
	set_ratio(ratio)


func set_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if _fill == null:
		_ratio = ratio
		_apply_ratio_visual(ratio, false)
		return
	if is_equal_approx(ratio, _ratio):
		return
	_ratio = ratio
	if _ratio_tween != null and _ratio_tween.is_valid():
		_ratio_tween.kill()
	_ratio_tween = create_tween()
	_ratio_tween.set_ease(Tween.EASE_OUT)
	_ratio_tween.set_trans(Tween.TRANS_CUBIC)
	var start := _read_fill_ratio()
	_ratio_tween.tween_method(_apply_ratio_visual, start, ratio, TWEEN_SEC)


func _read_fill_ratio() -> float:
	if _fill == null:
		return _ratio
	var mesh := _fill.mesh as BoxMesh
	if mesh == null:
		return _ratio
	return mesh.size.x / BAR_WIDTH


func _apply_ratio_visual(ratio: float, _unused = null) -> void:
	if _fill == null:
		return
	ratio = clampf(ratio, 0.0, 1.0)
	var fill_width := maxf(BAR_WIDTH * ratio, 0.03)
	var mesh := _fill.mesh as BoxMesh
	if mesh != null:
		mesh.size.x = fill_width
	_fill.position.x = -BAR_WIDTH * 0.5 + fill_width * 0.5
	if _fill_mat == null:
		return
	if ratio > 0.55:
		_fill_mat.albedo_color = Color(0.28, 0.92, 0.42)
		_fill_mat.emission = Color(0.16, 0.62, 0.24)
	elif ratio > 0.25:
		_fill_mat.albedo_color = Color(0.98, 0.78, 0.18)
		_fill_mat.emission = Color(0.82, 0.58, 0.08)
	else:
		_fill_mat.albedo_color = Color(0.98, 0.24, 0.16)
		_fill_mat.emission = Color(0.82, 0.14, 0.08)


func _build() -> void:
	var shadow := _make_quad("Shadow", BAR_WIDTH + 0.14, BAR_HEIGHT + 0.12, Color(0.0, 0.0, 0.0, 0.55), 0.0)
	shadow.position.z = -0.02
	add_child(shadow)

	var frame := _make_quad("Frame", BAR_WIDTH + 0.06, BAR_HEIGHT + 0.06, Color(0.08, 0.1, 0.14), 0.12)
	frame.position.z = -0.01
	add_child(frame)

	var bg := _make_quad("Background", BAR_WIDTH, BAR_HEIGHT, Color(0.18, 0.06, 0.08), 0.0)
	add_child(bg)

	_fill = _make_quad("Fill", BAR_WIDTH, BAR_HEIGHT, Color(0.28, 0.92, 0.42), 0.45)
	_fill_mat = _fill.material_override as StandardMaterial3D
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
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_strength
	mesh_node.material_override = mat
	return mesh_node