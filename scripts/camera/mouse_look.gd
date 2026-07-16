extends Node

## Musstyrning för FPS-vy. Enda ägare av musläge under spel (InputMode styr bara flaggor).

const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := 1.15

var _pivot: Node3D
var _camera: Camera3D
var _active := false
var _was_paused := false
var _want_capture := true
var _ignore_look_frames := 0
var _shake_strength := 0.0
var _shake_decay := 8.0
var _shake_offset := Vector3.ZERO
var _camera_rest_offset := Vector3.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _active and _pivot != null and _camera != null


func activate(pivot: Node3D, camera: Camera3D) -> void:
	_pivot = pivot
	_camera = camera
	_active = true
	_was_paused = false
	_want_capture = true
	if _pivot and _camera:
		_camera.rotation.x = clampf(_camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
	_capture_mouse()


func deactivate() -> void:
	_active = false
	_pivot = null
	_camera = null
	_want_capture = false
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


func request_shake(strength: float, duration_hint: float = 0.12) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = maxf(4.0, 1.0 / maxf(duration_hint, 0.04))


func get_aim_origin(fallback_position: Vector3) -> Vector3:
	if not is_active() or _camera == null:
		return fallback_position + Vector3(0.0, 1.45, 0.0)
	return _camera.global_position + get_aim_direction() * 0.65


func request_recapture() -> void:
	if is_active() and _should_auto_capture():
		_capture_mouse()


func _input(event: InputEvent) -> void:
	if not is_active() or get_tree().paused:
		return

	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			if _should_auto_capture() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				_capture_mouse()
		return

	if not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if not _want_capture or not _should_auto_capture():
		return
	if _ignore_look_frames > 0:
		return

	var motion := event as InputEventMouseMotion
	if absf(motion.relative.x) > 80.0 or absf(motion.relative.y) > 80.0:
		return
	if _pivot == null or _camera == null:
		return
	_pivot.rotation.y -= motion.relative.x * MOUSE_SENSITIVITY
	_camera.rotation.x = clampf(
		_camera.rotation.x - motion.relative.y * MOUSE_SENSITIVITY,
		-PITCH_LIMIT,
		PITCH_LIMIT
	)


func _process(delta: float) -> void:
	if _ignore_look_frames > 0:
		_ignore_look_frames -= 1
	_apply_camera_shake(delta)
	if not _active:
		return

	if _is_drag_active():
		if _want_capture:
			_release_mouse()
		return

	var paused := get_tree().paused
	if paused and not _was_paused:
		_release_mouse()
	elif not paused and _was_paused:
		request_recapture()
	_was_paused = paused
	if paused:
		return

	var want := _should_auto_capture()
	if want != _want_capture:
		_want_capture = want
		if want:
			_capture_mouse()
		else:
			_release_mouse()


func _should_auto_capture() -> bool:
	if not _active:
		return false
	if _is_drag_active():
		return false
	var input_mode := get_node_or_null("/root/InputMode")
	if input_mode and input_mode.has_method("allow_game_input") and not input_mode.allow_game_input():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var game := tree.current_scene
	if game and game.has_method("should_capture_mouse"):
		return bool(game.call("should_capture_mouse"))
	return true


func _is_drag_active() -> bool:
	var input_mode := get_node_or_null("/root/InputMode")
	return input_mode != null and input_mode.has_method("is_drag_active") and input_mode.is_drag_active()


func _capture_mouse() -> void:
	_want_capture = true
	_set_tracking_mode(true)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_ignore_look_frames = 2


func _release_mouse() -> void:
	_want_capture = false
	_set_tracking_mode(false)
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _set_tracking_mode(is_game: bool) -> void:
	var mode := get_node_or_null("/root/InputMode")
	if mode and mode.has_method("set_tracking_mode"):
		mode.set_tracking_mode(is_game)


func _apply_camera_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_strength <= 0.001:
		_camera.position = _camera_rest_offset
		return
	_shake_strength = maxf(0.0, _shake_strength - _shake_decay * delta)
	var amount := _shake_strength
	_shake_offset = Vector3(
		randf_range(-amount, amount),
		randf_range(-amount * 0.6, amount * 0.6),
		randf_range(-amount * 0.25, amount * 0.25)
	)
	_camera.position = _camera_rest_offset + _shake_offset