class_name PoiGuideArrow3D
extends Node3D

const ARROW_HEIGHT := 9.5
const BOB_AMPLITUDE := 0.55
const BOB_SPEED := 2.2

var _anchor := Vector3.ZERO
var _color := Color(1.0, 0.85, 0.2)
var _mesh: MeshInstance3D
var _phase := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_phase = _rng.randf_range(0.0, TAU)
	_build_mesh()


func setup(world_pos: Vector3, tint: Color = Color(0.95, 0.82, 0.2)) -> void:
	_anchor = world_pos
	_color = tint
	global_position = world_pos + Vector3(0.0, ARROW_HEIGHT, 0.0)


func set_world_anchor(world_pos: Vector3) -> void:
	_anchor = world_pos


func _process(delta: float) -> void:
	if _anchor == Vector3.ZERO:
		return
	_phase += delta * BOB_SPEED
	var bob := sin(_phase) * BOB_AMPLITUDE
	global_position = _anchor + Vector3(0.0, ARROW_HEIGHT + bob, 0.0)
	rotation.y += delta * 0.35


func _build_mesh() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "ArrowMesh"
	add_child(_mesh)

	var body := BoxMesh.new()
	body.size = Vector3(0.55, 3.8, 0.55)
	var head := CylinderMesh.new()
	head.top_radius = 0.02
	head.bottom_radius = 0.95
	head.height = 1.5

	var body_inst := MeshInstance3D.new()
	body_inst.mesh = body
	body_inst.position = Vector3(0.0, -0.9, 0.0)
	_mesh.add_child(body_inst)

	var head_inst := MeshInstance3D.new()
	head_inst.mesh = head
	head_inst.position = Vector3(0.0, 1.35, 0.0)
	head_inst.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	_mesh.add_child(head_inst)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = _color
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 2.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.92
	body_inst.material_override = mat
	head_inst.material_override = mat