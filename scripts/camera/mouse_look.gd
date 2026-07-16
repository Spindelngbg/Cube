extends Node

## Koordinerar mus/sikt. Spelvärlden använder FirstPersonCameraRig på lokal spelare.
## Äldre scener (emergence/nest) faller tillbaka på fri pivot i scenen.

const PITCH_LIMIT := 1.15
const MOTION_SPIKE_LIMIT := 500.0
const DEFAULT_MOUSE_SENSITIVITY := 0.0022
const RAW_MOUSE_SETTING := "controls.raw_mouse_input"

var _rig: Node3D
var _pivot: Node3D
var _camera: Camera3D
var _legacy_active := false
var _input_mode: Node
var _shake_strength := 0.0
var _shake_decay := 8.0
var _shake_offset := Vector3.ZERO
var _camera_rest_offset := Vector3.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_input_mode = get_node_or_null("/root/InputMode")
	_connect_settings()
	_apply_mouse_input_mode()


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
	if _rig != null and _rig.has_method("is_look_enabled"):
		return bool(_rig.call("is_look_enabled"))
	return _legacy_active and _pivot != null and _camera != null


func is_cursor_user_free() -> bool:
	if _rig != null and _rig.has_method("is_cursor_free"):
		return bool(_rig.call("is_cursor_free"))
	return false


func register_rig(rig: Node3D) -> void:
	_rig = rig
	_legacy_active = false
	_pivot = null
	_camera = null
	_enter_game_input_mode()
	if _rig.has_method("set_look_enabled"):
		_rig.call("set_look_enabled", true)


func unregister_rig(rig: Node3D) -> void:
	if _rig != rig:
		return
	if _rig.has_method("set_look_enabled"):
		_rig.call("set_look_enabled", false)
	_rig = null


func activate(pivot: Node3D, camera: Camera3D) -> void:
	if _try_activate_local_rig():
		return
	_activate_legacy(pivot, camera)


func deactivate() -> void:
	if _rig != null:
		if _rig.has_method("set_look_enabled"):
			_rig.call("set_look_enabled", false)
		return
	_legacy_active = false
	_pivot = null
	_camera = null
	_release_pointer()


func notify_pointer_left_window() -> void:
	if _rig != null and _rig.has_method("set_cursor_free"):
		_rig.call("set_cursor_free", true)
		return
	_release_pointer()


func get_yaw() -> float:
	if _rig != null and _rig.has_method("get_yaw"):
		return float(_rig.call("get_yaw"))
	if _pivot:
		return _pivot.rotation.y
	return 0.0


func get_flat_direction(input_dir: Vector2) -> Vector3:
	if _rig != null and _rig.has_method("get_flat_direction"):
		return _rig.call("get_flat_direction", input_dir)
	if _legacy_active and input_dir != Vector2.ZERO and _pivot:
		var basis := _pivot.global_transform.basis
		var direction := basis * Vector3(input_dir.x, 0.0, input_dir.y)
		direction.y = 0.0
		if direction.length_squared() < 0.0001:
			return Vector3.ZERO
		return direction.normalized()
	return Vector3.ZERO


func get_aim_direction() -> Vector3:
	if _rig != null and _rig.has_method("get_aim_direction"):
		return _rig.call("get_aim_direction")
	if _legacy_active and _camera:
		return -_camera.global_transform.basis.z.normalized()
	return Vector3.FORWARD


func get_aim_origin(fallback_position: Vector3) -> Vector3:
	if _rig != null and _rig.has_method("get_aim_origin"):
		return _rig.call("get_aim_origin", fallback_position)
	if _legacy_active and _camera:
		return _camera.global_position + get_aim_direction() * 0.65
	return fallback_position + Vector3(0.0, 1.45, 0.0)


func request_shake(strength: float, duration_hint: float = 0.12) -> void:
	if _rig != null and _rig.has_method("request_shake"):
		_rig.call("request_shake", strength, duration_hint)
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null and bool(settings.get_value("a11y.reduce_motion", false)):
		strength *= 0.35
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = maxf(4.0, 1.0 / maxf(duration_hint, 0.04))


func request_recapture() -> void:
	if _rig != null and _rig.has_method("set_cursor_free"):
		_rig.call("set_cursor_free", false)
		return
	if _legacy_active:
		_lock_pointer()


func _try_activate_local_rig() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var game := tree.get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_local_player"):
		return false
	var player: Node = game.get_local_player()
	if player == null:
		return false
	var rig := player.get_node_or_null("FirstPersonCameraRig")
	if rig == null:
		return false
	register_rig(rig)
	return true


func _activate_legacy(pivot: Node3D, camera: Camera3D) -> void:
	_rig = null
	_pivot = pivot
	_camera = camera
	_legacy_active = pivot != null and camera != null
	if _legacy_active:
		_camera.rotation.x = clampf(_camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
		_enter_game_input_mode()
		_lock_pointer()


func _enter_game_input_mode() -> void:
	if _input_mode and _input_mode.has_method("game"):
		_input_mode.game()
	elif _input_mode and _input_mode.has_method("set_tracking_mode"):
		_input_mode.set_tracking_mode(true)


func _input(event: InputEvent) -> void:
	if _rig != null:
		return
	if not _legacy_active or get_tree().paused:
		return

	if event.is_action_pressed("toggle_cursor"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			_lock_pointer()
		else:
			_release_pointer()
		get_viewport().set_input_as_handled()
		return

	if not (event is InputEventMouseMotion):
		return
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return
	if _pivot == null or _camera == null:
		return

	var rel := (event as InputEventMouseMotion).relative
	if absf(rel.x) > MOTION_SPIKE_LIMIT or absf(rel.y) > MOTION_SPIKE_LIMIT:
		return
	var sensitivity := _get_mouse_sensitivity()
	_pivot.rotation.y -= rel.x * sensitivity
	_camera.rotation.x = clampf(
		_camera.rotation.x - rel.y * sensitivity,
		-PITCH_LIMIT,
		PITCH_LIMIT
	)
	_warp_pointer_center()


func _process(delta: float) -> void:
	if _rig != null:
		return
	_apply_legacy_shake(delta)


func _apply_legacy_shake(delta: float) -> void:
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


func _get_mouse_sensitivity() -> float:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return DEFAULT_MOUSE_SENSITIVITY
	return clampf(
		float(settings.get_value("controls.mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY)),
		0.0005,
		0.01
	)


func _lock_pointer() -> void:
	Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	call_deferred("_warp_pointer_center")


func _release_pointer() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _warp_pointer_center() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var rect := viewport.get_visible_rect()
	Input.warp_mouse(rect.position + rect.size * 0.5)