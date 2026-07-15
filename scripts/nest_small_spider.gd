extends Node3D

const LIFETIME := 8.0
const SPEED := 2.8

var velocity := Vector3.ZERO
var _age := 0.0
var _bounds := 5.5


func setup(origin: Vector3, bounds: float) -> void:
	position = origin
	_bounds = bounds
	velocity = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * SPEED
	_build_mesh()


func _build_mesh() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.08, 0.12, 0.06)
	body_mat.roughness = 0.35
	body_mat.emission_enabled = true
	body_mat.emission = Color(0.15, 0.35, 0.08)
	body_mat.emission_energy_multiplier = 0.4

	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	body.mesh = sphere
	body.material_override = body_mat
	add_child(body)

	for i in 4:
		var leg := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.015
		cap.height = 0.14
		leg.mesh = cap
		leg.material_override = body_mat
		var side := -1.0 if i % 2 == 0 else 1.0
		leg.position = Vector3(0.06 * side, -0.02, 0.03 * (i - 1.5))
		leg.rotation_degrees = Vector3(70, 0, 35 * side)
		add_child(leg)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return

	if randf() < 0.02:
		velocity = velocity.rotated(Vector3.UP, randf_range(-0.8, 0.8))
		velocity = velocity.normalized() * SPEED

	position += velocity * delta
	position.y = 0.06

	if absf(position.x) > _bounds:
		velocity.x *= -1
		position.x = clampf(position.x, -_bounds, _bounds)
	if absf(position.z) > _bounds:
		velocity.z *= -1
		position.z = clampf(position.z, -_bounds, _bounds)

	rotation.y = atan2(velocity.x, velocity.z)