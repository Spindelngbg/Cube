class_name FirstPersonCameraRig
extends Node3D

## Första-person-kamera på spelaren. Musen hanteras här — inte via fri flytande pivot i världen.
## Windows-vänligt läge: CONFINED_HIDDEN + warp till mitten (undviker CAPTURED-glapp).

const PITCH_LIMIT := 1.15
const MOTION_SPIKE_LIMIT := 500.0
const DEFAULT_SENSITIVITY := 0.0022
const EYE_OFFSET := Vector3(0.0, 1.62, 0.08)

var _camera: Camera3D
var _yaw := 0.0
var _pitch := 0.0
var _look_enabled := false
var _cursor_free := false
var _shake_strength := 0.0
var _shake_decay := 8.0
var _shake_offset := Vector3.ZERO
var _camera_rest_offset := Vector3.ZERO


func _ready() -> void:
	Input.set_use_accumulated_input(false)
	_build_camera()
	_apply_eye_offset()
	call_deferred("_grab_camera_current")


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "FirstPersonCamera"
	_camera.fov = 75.0
	_camera.position = Vector3.ZERO
	add_child(_camera)


func _grab_camera_current() -> void:
	if _camera:
		_camera.current = true


func get_camera() -> Camera3D:
	return _camera


func get_yaw() -> float:
	return _yaw


func get_pitch() -> float:
	return _pitch


func get_flat_direction(input_dir: Vector2) -> Vector3:
	if input_dir == Vector2.ZERO:
		return Vector3.ZERO
	var basis := global_transform.basis
	var direction := basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return Vector3.ZERO
	return direction.normalized()


func get_aim_direction() -> Vector3:
	if _camera == null:
		return Vector3.FORWARD
	return -_camera.global_transform.basis.z.normalized()


func get_aim_origin(fallback_position: Vector3) -> Vector3:
	if _camera == null:
		return fallback_position + Vector3(0.0, 1.45, 0.0)
	return _camera.global_position + get_aim_direction() * 0.65


func set_look_enabled(enabled: bool) -> void:
	_look_enabled = enabled
	if enabled and not _cursor_free:
		_lock_pointer()
	else:
		_unlock_pointer()


func is_look_enabled() -> bool:
	return _look_enabled


func is_cursor_free() -> bool:
	return _cursor_free


func set_cursor_free(free: bool) -> void:
	_cursor_free = free
	if free:
		_unlock_pointer()
	elif _look_enabled:
		_lock_pointer()


func request_shake(strength: float, duration_hint: float = 0.12) -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings != null and bool(settings.get_value("a11y.reduce_motion", false)):
		strength *= 0.35
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = maxf(4.0, 1.0 / maxf(duration_hint, 0.04))


func import_look_state(yaw: float, pitch: float) -> void:
	_yaw = yaw
	_pitch = clampf(pitch, -PITCH_LIMIT, PITCH_LIMIT)
	_apply_body_yaw()
	if _camera:
		_camera.rotation.x = _pitch


func _physics_process(_delta: float) -> void:
	_apply_eye_offset()
	_apply_camera_shake(_delta)


func _input(event: InputEvent) -> void:
	if not _look_enabled or get_tree().paused:
		return

	if event.is_action_pressed("toggle_cursor"):
		set_cursor_free(not _cursor_free)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT and _cursor_free:
			set_cursor_free(false)
		return

	if not (event is InputEventMouseMotion):
		return
	if _cursor_free:
		return
	if not _pointer_locked():
		_lock_pointer()
		return

	_apply_look_delta((event as InputEventMouseMotion).relative)
	_warp_pointer_center()
	get_viewport().set_input_as_handled()


func _apply_eye_offset() -> void:
	var player := get_parent() as Node3D
	if player == null:
		position = EYE_OFFSET
		return
	if player.has_method("get_camera_anchor_global_position"):
		global_position = player.get_camera_anchor_global_position()
	else:
		position = EYE_OFFSET


func _apply_look_delta(rel: Vector2) -> void:
	if rel == Vector2.ZERO:
		return
	if absf(rel.x) > MOTION_SPIKE_LIMIT or absf(rel.y) > MOTION_SPIKE_LIMIT:
		return
	var sensitivity := _get_mouse_sensitivity()
	_yaw -= rel.x * sensitivity
	_pitch = clampf(_pitch - rel.y * sensitivity, -PITCH_LIMIT, PITCH_LIMIT)
	_apply_body_yaw()
	if _camera:
		_camera.rotation.x = _pitch


func _apply_body_yaw() -> void:
	var player := get_parent() as Node3D
	if player:
		player.rotation.y = _yaw


func _get_mouse_sensitivity() -> float:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return DEFAULT_SENSITIVITY
	return clampf(
		float(settings.get_value("controls.mouse_sensitivity", DEFAULT_SENSITIVITY)),
		0.0005,
		0.01
	)


func _pointer_locked() -> bool:
	var mode := Input.get_mouse_mode()
	return mode == Input.MOUSE_MODE_CAPTURED or mode == Input.MOUSE_MODE_CONFINED_HIDDEN


func _lock_pointer() -> void:
	Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	call_deferred("_warp_pointer_center")


func _unlock_pointer() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _warp_pointer_center() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var rect := viewport.get_visible_rect()
	Input.warp_mouse(rect.position + rect.size * 0.5)


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