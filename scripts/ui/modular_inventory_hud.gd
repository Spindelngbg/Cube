class_name ModularInventoryHud
extends Control

const HOTBAR_SCENE := preload("res://addons/modular_inventory_system/ui/ModularHotbar.tscn")
const PANEL_SCENE := preload("res://addons/modular_inventory_system/ui/ModularPanel.tscn")
const ItemTooltipScript := preload("res://addons/modular_inventory_system/ui/ItemTooltip.gd")
const GameSfxScript := preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript := preload("res://scripts/audio/rpg_audio_library.gd")

var _hotbar
var _tooltip
var _panel_open := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hotbar()
	_build_tooltip()
	_bind_inventory()
	InventoryManager.inventory_changed.connect(_bind_inventory)
	UIStateManager.panel_closed.connect(_on_panel_closed)


func is_panel_open() -> bool:
	return _panel_open or UIStateManager.has_open_ui()


func toggle() -> void:
	if is_panel_open():
		_close_panel()
	else:
		_open_panel()


func _open_panel() -> void:
	var inv = InventoryManager.get_modular_inventory()
	if inv == null:
		return
	UIStateManager.open_panel(PANEL_SCENE, inv, "Inventory", "player")
	_panel_open = true
	GameSfxScript.play_2d_varied(
		self,
		RpgAudioLibraryScript.from_pool(RpgAudioLibraryScript.PICKUP_ITEM)
	)
	MouseLook.deactivate()


func _close_panel() -> void:
	UIStateManager.close_all()
	_panel_open = false
	GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.ui_close())
	_restore_mouse_look()


func _build_hotbar() -> void:
	_hotbar = HOTBAR_SCENE.instantiate()
	_hotbar.defer_binding = true
	_hotbar.auto_bind_to_owner = false
	_hotbar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_hotbar)
	_hotbar.selection_changed.connect(_on_hotbar_selection_changed)


func _build_tooltip() -> void:
	_tooltip = ItemTooltipScript.new()
	_tooltip.tooltip_label = RichTextLabel.new()
	_tooltip.add_child(_tooltip.tooltip_label)
	_tooltip.add_to_group("item_tooltip")
	add_child(_tooltip)


func _bind_inventory() -> void:
	var inv = InventoryManager.get_modular_inventory()
	if inv and _hotbar:
		_hotbar.bind_inventory(inv)


func _on_hotbar_selection_changed(local_index: int) -> void:
	var inv = InventoryManager.get_modular_inventory()
	if inv == null or _hotbar == null:
		return
	var global_index: int = int(_hotbar.start_index) + local_index
	if global_index < 0 or global_index >= inv.capacity:
		return
	var slot = inv.get_slot(global_index)
	if slot == null or slot.is_empty() or slot.item == null:
		return
	var item_id: String = str(slot.item.id)
	if ItemCatalog.is_weapon(item_id):
		WeaponManager.equip(item_id)


func _on_panel_closed(_panel: Control) -> void:
	_panel_open = false
	_restore_mouse_look()


func _restore_mouse_look() -> void:
	if get_tree().paused:
		return
	var game := get_tree().current_scene
	if game and game.has_method("activate_gameplay_mouse"):
		game.activate_gameplay_mouse()