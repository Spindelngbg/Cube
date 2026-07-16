extends Node

## Musstyrning för FPS-vy. Yaw på spelaren, pitch på kameran. Alt = fri pekare.

const DEFAULT_MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := 1.15
const MOTION_SPIKE_LIMIT := 120.0
const RAW_MOUSE_SETTING := "controls.raw_mouse_input"

var _pivot: Node3D
var _camera: Camera3D
var _active := false
var _was_paused := false
var _user_cursor_free := false
var _shake_strength := 0.0
var _shake_decay := 8.0
var _shake_offset := Vector3.ZERO
var _camera_rest_offset := Vector3.ZERO
var _input_mode: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_input_mode = get_node_or_null("/root/InputMode")
	_connect_settings()
	_apply_mouse_input_mode()
	var tree := get_tree()
	if tree and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
	deactivate()
	_release_pointer()
	if _input_mode and _input_mode.has_method("ui"):
		_input_mode.ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _connect_settings() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return
	if settings.has_signal("settings_loaded") and not settings.settings_loaded.is_connected(_apply_mouse_input_mode):
		settings.settings_loaded.connect(_apply_mouse_input_mode)
	if settings.has_signal("setting_changed") and not settings.setting_changed.is_connected(_on_settings_changed):
		settings.setting_changed.connect(_on_settings_changed)


func _on_settings_changed(key: String, _value) -> void:
	if key == RAW_MOUSE_SETTING:
		_apply_mouse_input_mode()


func _apply_mouse_input_mode() -> void:
	var raw := true
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		raw = bool(settings.get_value(RAW_MOUSE_SETTING, true))
	Input.set_use_accumulated_input(not raw)


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
		_enter_game_input_mode()
		_apply_mouse_input_mode()
		_capture_mouse()


func deactivate() -> void:
	_active = false
	_pivot = null
	_camera = null
	_user_cursor_free = false
	_release_pointer()


func notify_pointer_left_window() -> void:
	if not is_active():
		return
	_user_cursor_free = true
	_release_pointer()


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
	var settings := get_node_or_null("/root/Settings")
	if settings != null and bool(settings.get_value("a11y.reduce_motion", false)):
		strength *= 0.35
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = maxf(4.0, 1.0 / maxf(duration_hint, 0.04))


func request_recapture() -> void:
	if is_active() and not _user_cursor_free:
		_capture_mouse()


func release_for_ui() -> void:
	if not is_active():
		_release_pointer()
		return
	_user_cursor_free = false
	_release_pointer()


func _input(event: InputEvent) -> void:
	if not is_active() or get_tree().paused:
		return

	if event.is_action_pressed("toggle_cursor"):
		_toggle_user_cursor()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT and _user_cursor_free:
			_user_cursor_free = false
			_capture_mouse()
		return

	if not (event is InputEventMouseMotion):
		return
	if _user_cursor_free or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if _pivot == null or _camera == null:
		return

	var rel := (event as InputEventMouseMotion).relative
	_apply_look_delta(rel)


func _process(delta: float) -> void:
	_apply_camera_shake(delta)
	if not _active:
		return

	if _is_drag_active():
		_release_mouse()
		return

	var tree := get_tree()
	var paused := tree.paused if tree else false
	if paused and not _was_paused:
		_release_mouse()
	elif not paused and _was_paused and not _user_cursor_free:
		_capture_mouse()
	_was_paused = paused
	if paused:
		return

	if not _user_cursor_free and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if _game_allows_capture():
			_capture_mouse()


func _apply_look_delta(rel: Vector2) -> void:
	if rel == Vector2.ZERO:
		return
	if absf(rel.x) > MOTION_SPIKE_LIMIT or absf(rel.y) > MOTION_SPIKE_LIMIT:
		return
	var sensitivity := _get_mouse_sensitivity()
	_pivot.rotation.y -= rel.x * sensitivity
	_camera.rotation.x = clampf(
		_camera.rotation.x - rel.y * sensitivity,
		-PITCH_LIMIT,
		PITCH_LIMIT
	)


func _toggle_user_cursor() -> void:
	_user_cursor_free = not _user_cursor_free
	if _user_cursor_free:
		_release_mouse()
	elif _game_allows_capture():
		_capture_mouse()


func _game_allows_capture() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var game := tree.current_scene
	if game and game.has_method("should_capture_mouse"):
		return bool(game.call("should_capture_mouse"))
	return true


func _is_drag_active() -> bool:
	return _input_mode != null and _input_mode.has_method("is_drag_active") and _input_mode.is_drag_active()


func _capture_mouse() -> void:
	_apply_mouse_input_mode()
	_set_tracking_mode(true)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _release_mouse() -> void:
	_set_tracking_mode(false)
	_release_pointer()


func _release_pointer() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _set_tracking_mode(is_game: bool) -> void:
	if _input_mode and _input_mode.has_method("set_tracking_mode"):
		_input_mode.set_tracking_mode(is_game)


func _enter_game_input_mode() -> void:
	if _input_mode and _input_mode.has_method("game"):
		_input_mode.game()


func _get_mouse_sensitivity() -> float:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return DEFAULT_MOUSE_SENSITIVITY
	return clampf(
		float(settings.get_value("controls.mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY)),
		0.0005,
		0.01
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