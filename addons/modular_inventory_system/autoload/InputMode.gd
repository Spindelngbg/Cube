extends Node

const InventoryRuntimeScript = preload("res://addons/modular_inventory_system/inventory_runtime.gd")

## Håller koll på UI vs spel-läge för inventory/drag. Musläge i spel hanteras av MouseLook.

@export var startup_mode: bool = false
@export var prevent_game_input_in_ui: bool = true

var _is_ui_mode: bool = false
var _drag_active: bool = false


func _ready() -> void:
	var drag_drop := InventoryRuntimeScript.drag_drop()
	if drag_drop and drag_drop.has_signal("drag_started"):
		drag_drop.drag_started.connect(_on_drag_start)
	if drag_drop and drag_drop.has_signal("drag_ended"):
		drag_drop.drag_ended.connect(_on_drag_end)

	set_mode(startup_mode)


func ui() -> void:
	set_mode(false)


func game() -> void:
	set_mode(true)


func toggle() -> void:
	set_mode(not _is_ui_mode)


func is_game_mode() -> bool:
	return not _is_ui_mode


func is_drag_active() -> bool:
	return _drag_active


func allow_game_input() -> bool:
	return not _is_ui_mode and not _drag_active


## Uppdaterar bara intern flagga — MouseLook sätter inte musläge via game()/ui().
func set_tracking_mode(is_game: bool) -> void:
	_is_ui_mode = not is_game


func set_mode(is_game: bool) -> void:
	_is_ui_mode = not is_game
	if _mouse_look_handles_mouse():
		return
	_apply_mouse_mode(is_game)


func _apply_mouse_mode(is_game: bool) -> void:
	if is_game and not _game_allows_capture():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if is_game:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _game_allows_capture() -> bool:
	var scene := get_tree().current_scene
	if scene and scene.has_method("should_capture_mouse"):
		return bool(scene.call("should_capture_mouse"))
	return true


func _mouse_look_handles_mouse() -> bool:
	var mouse_look := get_node_or_null("/root/MouseLook")
	return mouse_look != null and mouse_look.has_method("is_active") and mouse_look.is_active()


func _on_drag_start(_a, _b, _c) -> void:
	_drag_active = true
	if _mouse_look_handles_mouse():
		return
	if not _is_ui_mode:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)


func _on_drag_end() -> void:
	_drag_active = false
	var has_open_ui := false
	for panel in get_tree().get_nodes_in_group("modular_inventory_panel"):
		if panel.visible:
			has_open_ui = true
			break

	if _mouse_look_handles_mouse():
		var mouse_look := get_node_or_null("/root/MouseLook")
		if mouse_look and mouse_look.has_method("request_recapture"):
			if not has_open_ui and not _is_ui_mode:
				mouse_look.request_recapture()
		return

	if not has_open_ui and not _is_ui_mode:
		set_mode(true)
	elif has_open_ui:
		set_mode(false)


func _notification(what: int) -> void:
	if _mouse_look_handles_mouse():
		# Släpp vid alt-tab — spelaren klickar för att låsa igen (MouseLook).
		if what == NOTIFICATION_WM_MOUSE_EXIT and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if what == NOTIFICATION_WM_MOUSE_EXIT and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		if not _is_ui_mode:
			_apply_mouse_mode(true)