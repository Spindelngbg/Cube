extends Node

const InventoryRuntimeScript = preload("res://addons/modular_inventory_system/inventory_runtime.gd")

## Simple mouse toggle for 3D games.
## Call InputMode.ui() / InputMode.game() / InputMode.toggle()

@export var startup_mode: bool = false
@export var prevent_game_input_in_ui: bool = true

var _is_ui_mode: bool = false
var _drag_active: bool = false

func _ready():
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

func allow_game_input() -> bool:
	return not _is_ui_mode and not _drag_active

func set_mode(is_game: bool) -> void:
	_is_ui_mode = not is_game
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

func _on_drag_start(_a, _b, _c):
	_drag_active = true
	if _is_ui_mode == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _on_drag_end():
	_drag_active = false
	var has_open_ui = false
	for panel in get_tree().get_nodes_in_group("modular_inventory_panel"):
		if panel.visible:
			has_open_ui = true
			break
			
	if not has_open_ui and _is_ui_mode == false:
		set_mode(true)
	elif has_open_ui:
		set_mode(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		if _is_ui_mode:
			return
		var mouse_look := get_node_or_null("/root/MouseLook")
		if mouse_look and mouse_look.has_method("request_recapture"):
			mouse_look.request_recapture()
		else:
			_apply_mouse_mode(true)
