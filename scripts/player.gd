extends CharacterBody3D

const MOVE_SPEED := 5.0
const PLAYER_COLORS := [
	Color(0.9, 0.3, 0.3),
	Color(0.3, 0.6, 0.95),
	Color(0.4, 0.85, 0.4),
	Color(0.95, 0.8, 0.2),
	Color(0.8, 0.4, 0.9),
	Color(0.3, 0.9, 0.85),
	Color(0.95, 0.5, 0.2),
	Color(0.6, 0.6, 0.6),
]


func _ready() -> void:
	var mesh := $MeshInstance3D
	if mesh:
		var material := StandardMaterial3D.new()
		material.albedo_color = PLAYER_COLORS[get_multiplayer_authority() % PLAYER_COLORS.size()]
		mesh.material_override = material


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED)

	move_and_slide()
	_sync_position.rpc(position)


@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector3) -> void:
	if is_multiplayer_authority():
		return
	position = pos