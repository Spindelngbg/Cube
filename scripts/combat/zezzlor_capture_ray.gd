extends Area3D

const SPEED := 44.0
const MAX_LIFETIME := 2.0

var _velocity := Vector3.ZERO
var _shooter: Node3D
var _alive := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	_mesh = get_node_or_null("Mesh") as MeshInstance3D


func launch(origin: Vector3, direction: Vector3, shooter: Node3D) -> void:
	global_position = origin
	_velocity = direction.normalized() * SPEED
	_shooter = shooter
	_alive = 0.0
	if _velocity.length_squared() > 0.01:
		look_at(origin + _velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= MAX_LIFETIME:
		queue_free()
		return
	global_position += _velocity * delta
	if _mesh:
		var pulse := 1.0 + sin(_alive * 36.0) * 0.18
		_mesh.scale = Vector3(0.22 * pulse, 0.22 * pulse, 1.2 * pulse)


func _on_body_entered(body: Node) -> void:
	if body == _shooter:
		return
	if body.has_method("capture_by_zezzlor_jailer"):
		if body.is_multiplayer_authority():
			body.capture_by_zezzlor_jailer(_shooter)
		queue_free()
		return
	if body.has_method("take_damage") and body.is_in_group("player_character"):
		if body.is_multiplayer_authority():
			body.capture_by_zezzlor_jailer(_shooter)
		queue_free()