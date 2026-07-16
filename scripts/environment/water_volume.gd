class_name WaterVolume
extends Area3D

var _depth := 1.2
var _surface_offset := 0.04
var _mesh: MeshInstance3D
var _water_mat: StandardMaterial3D
var _time := 0.0


func configure(config: Dictionary) -> void:
	_depth = float(config.get("depth", 1.2))
	_surface_offset = float(config.get("surface_offset", 0.04))
	var size: Vector3 = config.get("size", Vector3(6.0, _depth, 5.0))
	var color: Color = config.get("color", Color(0.1, 0.42, 0.72, 0.78))
	var style: String = str(config.get("style", "pool"))

	position = config.get("position", Vector3.ZERO)
	rotation.y = float(config.get("rotation_y", 0.0))
	_build_collision(size)
	_build_visual(size, color, style)
	set_physics_process(true)


func get_surface_y() -> float:
	return global_position.y + _surface_offset


func get_floor_y() -> float:
	return get_surface_y() - _depth


func get_depth() -> float:
	return _depth


func _ready() -> void:
	add_to_group("water_volume")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_time += delta
	if _water_mat == null:
		return
	var pulse := 0.82 + sin(_time * 1.8) * 0.08
	_water_mat.albedo_color.a = pulse
	if _mesh:
		_mesh.position.y = -_depth * 0.5 + sin(_time * 2.2) * 0.02


func _build_collision(size: Vector3) -> void:
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, _depth + 0.35, size.z)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, -_depth * 0.5 + 0.12, 0.0)
	add_child(shape_node)


func _build_visual(size: Vector3, color: Color, style: String) -> void:
	var rim := MeshInstance3D.new()
	var rim_mesh := BoxMesh.new()
	rim_mesh.size = Vector3(size.x + 0.35, 0.08, size.z + 0.35)
	rim.mesh = rim_mesh
	rim.position = Vector3(0.0, 0.02, 0.0)
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.72, 0.74, 0.78) if style == "pool" else Color(0.42, 0.44, 0.48)
	rim_mat.roughness = 0.55
	rim.material_override = rim_mat
	add_child(rim)

	_mesh = MeshInstance3D.new()
	var water_mesh := BoxMesh.new()
	water_mesh.size = Vector3(size.x, _depth, size.z)
	_mesh.mesh = water_mesh
	_mesh.position = Vector3(0.0, -_depth * 0.5, 0.0)
	_water_mat = StandardMaterial3D.new()
	_water_mat.albedo_color = color
	_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_water_mat.roughness = 0.08
	_water_mat.metallic = 0.05
	_water_mat.emission_enabled = true
	_water_mat.emission = color.lightened(0.25)
	_water_mat.emission_energy_multiplier = 0.35
	_mesh.material_override = _water_mat
	add_child(_mesh)

	if style == "pool":
		var ladder := MeshInstance3D.new()
		var ladder_mesh := BoxMesh.new()
		ladder_mesh.size = Vector3(0.12, 0.55, 0.42)
		ladder.mesh = ladder_mesh
		ladder.position = Vector3(size.x * 0.42, -_depth * 0.25, size.z * 0.38)
		var ladder_mat := StandardMaterial3D.new()
		ladder_mat.albedo_color = Color(0.55, 0.58, 0.62)
		ladder_mat.metallic = 0.7
		ladder.material_override = ladder_mat
		add_child(ladder)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.has_method("enter_water"):
		body.enter_water(self)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.has_method("exit_water"):
		body.exit_water(self)