extends Node

const InventoryRuntimeScript = preload("res://addons/modular_inventory_system/inventory_runtime.gd")

enum UIType {
	BLOCK_INPUT,
	PAUSE_GAME
}

signal panel_spawned(panel: Control, scene: PackedScene, role: String)
signal panel_closed(panel: Control)

var _ui_stack: Array[Dictionary] = []
var _background_overlay: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS 

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _ui_stack.is_empty():
		close_all()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not _ui_stack.is_empty() and not InventoryRuntimeScript.is_dragging():
			close_all()
			get_viewport().set_input_as_handled()
			
func open_panel(scene: PackedScene, inv: Inventory, title: String = "", role: String = "default", type: UIType = UIType.BLOCK_INPUT) -> Control:
	if not scene: return null
		
	var ui_layer = _get_ui_layer()
	var panel = scene.instantiate()
	ui_layer.add_child(panel)
	
	if panel.has_method("bind_inventory") and inv:
		panel.bind_inventory(inv)
		
	var title_label = panel.find_child("TitleLabel", true, false)
	if title_label and title_label is Label: 
		title_label.text = title
		
	panel.set_meta("ui_role", role)
	if inv: panel.set_meta("ui_inventory", inv)

	_ui_stack.append({"control": panel, "type": type, "role": role})
	
	_update_game_state()
	panel_spawned.emit(panel, scene, role)
	InputMode.ui()
	
	return panel

func close_top_ui() -> void:
	if _ui_stack.is_empty(): return
	var data = _ui_stack.pop_back()
	if is_instance_valid(data["control"]):
		data["control"].queue_free()
		panel_closed.emit(data["control"])
	_update_game_state()
	
func close_panel(panel: Control) -> void:
	for i in range(_ui_stack.size() - 1, -1, -1):
		if _ui_stack[i]["control"] == panel:
			_ui_stack.remove_at(i)
			if is_instance_valid(panel):
				panel_closed.emit(panel)
				panel.queue_free()
			break
	_update_game_state()

func close_all() -> void:
	for data in _ui_stack:
		if is_instance_valid(data["control"]):
			data["control"].queue_free()
			panel_closed.emit(data["control"])
	_ui_stack.clear()
	
	var tooltips = get_tree().get_nodes_in_group("item_tooltip")
	for t in tooltips:
		if t is ItemTooltip:
			t.hide_tooltip()
			
	_update_game_state()

func _update_game_state() -> void:
	if _ui_stack.is_empty():
		get_tree().paused = false
		InputMode.game()
		_remove_background()
		return
		
	InputMode.ui()
	_ensure_background()
	
	var should_pause = false
	for data in _ui_stack:
		if data["type"] == UIType.PAUSE_GAME:
			should_pause = true
			break
			
	get_tree().paused = should_pause
	
	var panels: Array[Control] = []
	for data in _ui_stack:
		if is_instance_valid(data["control"]):
			panels.append(data["control"])
			
	UICoordinator.arrange_panels(panels)
	
func _ensure_background() -> void:
	if _background_overlay and is_instance_valid(_background_overlay):
		return
		
	var ui_layer = _get_ui_layer()
	_background_overlay = ColorRect.new()
	_background_overlay.name = "UIBackgroundOverlay"
	_background_overlay.color = Color(0, 0, 0, 0.5) # Semi-transparent black background
	_background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignore mouse clicks so they pass through to panels
	_background_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_overlay.z_index = -1 # Ensure it's behind all panels
	
	# Add it at the beginning of the UILayer so panels are on top
	if ui_layer.get_child_count() > 0:
		ui_layer.add_child(_background_overlay)
		ui_layer.move_child(_background_overlay, 0)
	else:
		ui_layer.add_child(_background_overlay)

func _remove_background() -> void:
	if _background_overlay and is_instance_valid(_background_overlay):
		_background_overlay.queue_free()
		_background_overlay = null
		
func _get_ui_layer() -> CanvasLayer:
	var layer = get_tree().root.get_node_or_null("UILayer")
	if not layer:
		layer = CanvasLayer.new()
		layer.name = "UILayer"
		layer.layer = 10
		get_tree().root.add_child(layer)
	return layer
	
func get_other_inventory(current_inv: Inventory) -> Inventory:
	for data in _ui_stack:
		var panel = data["control"]
		if panel.has_meta("ui_inventory"):
			var other = panel.get_meta("ui_inventory")
			if other and other != current_inv:
				return other
	return null

func get_panel_by_role(role: String) -> Control:
	for data in _ui_stack:
		if data["role"] == role:
			return data["control"]
	return null
	
func has_open_ui() -> bool:
	return not _ui_stack.is_empty()

# debug
func get_stack_size() -> int:
	return _ui_stack.size()
