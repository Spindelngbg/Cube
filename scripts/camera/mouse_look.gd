extends Node

## Musstyrning för FPS-vy. Siktet i mitten följer kamerans riktning.
## Roterar direkt i _input — samma bildruta, ingen ackumulering.

const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := 1.15
const MOTION_SPIKE_LIMIT := 80.0

var _pivot: Node3D
var _camera: Camera3D
var _active := false
var _was_paused := false
var _user_cursor_free := false
var _shake_strength := 0.0
var _shake_decay := 8.0
var _shake_offset := Vector3.ZERO
var _camera_rest_offset := Vector3.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_input_policy()
	_connect_settings()
	var tree := get_tree()
	if tree and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)


func _connect_settings() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return
	if settings.has_signal("settings_loaded") and not settings.settings_loaded.is_connected(_apply_input_policy):
		settings.settings_loaded.connect(_apply_input_policy)
	if settings.has_signal("setting_changed") and not settings.setting_changed.is_connected(_on_setting_changed):
		settings.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(key: String, _value) -> void:
	if key == "controls.raw_mouse_input" or key == "gameplay.competitive_mode":
		_apply_input_policy()


func _on_scene_changed() -> void:
	deactivate()


func is_active() -> bool:
	return _active and _pivot != null and _camera != null


func is_cursor_user_free() -> bool:
	return _user_cursor_free


func activate(pivot: Node3D, camera: Camera3D) -> void:
	_pivot = pivot
	_camera = camera
	_active = pivot != null and camera != null
	_was_paused = false
	_user_cursor_free = false
	if _active:
		_camera.rotation.x = clampf(_camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
		_camera.current = true
		_apply_input_policy()
		_set_input_mode_game()
		_capture_mouse()


func deactivate() -> void:
	_active = false
	_pivot = null
	_camera = null
	_user_cursor_free = false
	_release_mouse()
	_set_input_mode_ui()


func notify_pointer_left_window() -> void:
	if not is_active():
		return
	_user_cursor_free = true
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


func request_shake(strength: float, duration_hint: float = 0.12) -> void:
	if not CompetitiveMode.camera_shake_enabled():
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null and bool(settings.get_value("a11y.reduce_motion", false)):
		strength *= 0.35
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = maxf(4.0, 1.0 / maxf(duration_hint, 0.04))


func request_recapture() -> void:
	if is_active() and not _user_cursor_free and _should_auto_capture():
		_capture_mouse()


func release_for_ui() -> void:
	if not is_active():
		_release_mouse()
		return
	_user_cursor_free = false
	_release_mouse()


func _input(event: InputEvent) -> void:
	if not is_active() or get_tree().paused:
		return

	if event.is_action_pressed("toggle_cursor"):
		_toggle_user_cursor()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			if _user_cursor_free and _should_auto_capture():
				_user_cursor_free = false
				_capture_mouse()
			elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and _should_auto_capture():
				_capture_mouse()
		return

	if not (event is InputEventMouseMotion):
		return
	if _user_cursor_free:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if not _should_auto_capture():
		return
	if _pivot == null or _camera == null:
		return

	var motion := event as InputEventMouseMotion
	if absf(motion.relative.x) > MOTION_SPIKE_LIMIT or absf(motion.relative.y) > MOTION_SPIKE_LIMIT:
		return
	var sensitivity := _get_mouse_sensitivity()
	_pivot.rotation.y -= motion.relative.x * sensitivity
	_camera.rotation.x = clampf(
		_camera.rotation.x - motion.relative.y * sensitivity,
		-PITCH_LIMIT,
		PITCH_LIMIT
	)


func _process(delta: float) -> void:
	_apply_camera_shake(delta)
	if not _active:
		return

	var paused := get_tree().paused
	if paused and not _was_paused:
		_release_mouse()
	elif not paused and _was_paused and not _user_cursor_free and _should_auto_capture():
		_capture_mouse()
	_was_paused = paused


func _toggle_user_cursor() -> void:
	_user_cursor_free = not _user_cursor_free
	if _user_cursor_free:
		_release_mouse()
	elif _should_auto_capture():
		_capture_mouse()


func _should_auto_capture() -> bool:
	if not _active:
		return false
	var game := get_tree().current_scene
	if game and game.has_method("should_capture_mouse"):
		return bool(game.call("should_capture_mouse"))
	return true


func _capture_mouse() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _release_mouse() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _set_input_mode_game() -> void:
	var mode := get_node_or_null("/root/InputMode")
	if mode and mode.has_method("set_tracking_mode"):
		mode.set_tracking_mode(true)
	elif mode and mode.has_method("game"):
		mode.game()


func _set_input_mode_ui() -> void:
	var mode := get_node_or_null("/root/InputMode")
	if mode and mode.has_method("set_tracking_mode"):
		mode.set_tracking_mode(false)
	elif mode and mode.has_method("ui"):
		mode.ui()


func _apply_input_policy() -> void:
	var raw := true
	if CompetitiveMode.force_raw_mouse_input():
		raw = true
	else:
		var settings := get_node_or_null("/root/Settings")
		if settings != null:
			raw = bool(settings.get_value("controls.raw_mouse_input", true))
	Input.set_use_accumulated_input(not raw)


func _get_mouse_sensitivity() -> float:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return MOUSE_SENSITIVITY
	return clampf(
		float(settings.get_value("controls.mouse_sensitivity", MOUSE_SENSITIVITY)),
		0.0008,
		0.006
	)


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