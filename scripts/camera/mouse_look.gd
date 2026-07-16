extends Node

## Musstyrning för FPS-vy. Siktet i mitten följer kamerans riktning.

const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := 1.15

var _pivot: Node3D
var _camera: Camera3D
var _active := false
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _active and _pivot != null and _camera != null


func activate(pivot: Node3D, camera: Camera3D) -> void:
	_pivot = pivot
	_camera = camera
	_active = true
	_was_paused = false
	if _pivot and _camera:
		_camera.rotation.x = clampf(_camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
	_capture_mouse()


func deactivate() -> void:
	_active = false
	_pivot = null
	_camera = null
	_release_mouse()


func get_yaw() -> float:
	if _pivot:
		return _pivot.rotation.y
	return 0.0


func get_flat_direction(input_dir: Vector2) -> Vector3:
	if not is_active() or input_dir == Vector2.ZERO:
		return Vector3.ZERO
	var basis := _pivot.global_transform.basis
	var direction := basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return Vector3.ZERO
	return direction.normalized()


func get_aim_direction() -> Vector3:
	if not is_active() or _camera == null:
		return Vector3.FORWARD
	return -_camera.global_transform.basis.z.normalized()


func get_aim_origin(fallback_position: Vector3) -> Vector3:
	if not is_active() or _camera == null:
		return fallback_position + Vector3(0.0, 1.45, 0.0)
	return _camera.global_position + get_aim_direction() * 0.65


func _input(event: InputEvent) -> void:
	if not is_active() or get_tree().paused:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_pivot.rotation.y -= motion.relative.x * MOUSE_SENSITIVITY
		_camera.rotation.x = clampf(
			_camera.rotation.x - motion.relative.y * MOUSE_SENSITIVITY,
			-PITCH_LIMIT,
			PITCH_LIMIT
		)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				_capture_mouse()


func _process(_delta: float) -> void:
	if not _active:
		return
	var paused := get_tree().paused
	if paused and not _was_paused:
		_release_mouse()
	elif not paused and _was_paused:
		_capture_mouse()
	_was_paused = paused


func _capture_mouse() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _release_mouse() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE