extends Node
class_name EquipmentManager

const InventoryRuntimeScript = preload("res://addons/modular_inventory_system/inventory_runtime.gd")

signal item_equipped(item: ItemDefinition, slot_index: int)
signal active_item_changed(item: ItemDefinition, slot_index: int)

@export_group("References")
@export var player: Node3D
@export var main_inventory: InventoryComponent
@export var hotbar: ModularHotbar
@export var item_socket: Marker3D

@export_group("Animation")	
@export var animations_enabled: bool = true
@export_enum("scale", "slide", "rotate", "fade", "none") var default_equip_animation: String = "scale"
@export_enum("scale", "slide", "rotate", "fade", "none") var default_unequip_animation: String = "scale"

@export var default_equip_duration: float = 0.25
@export var default_unequip_duration: float = 0.2
@export var default_unequip_drop: Vector3 = Vector3(0, -0.5, 0)

var active_logic: ItemLogic = null
var active_slot_index: int = -1
var active_item: ItemDefinition = null

var _equipped_weapon_model: Node3D = null

func _ready() -> void:
	if not main_inventory or not main_inventory.inventory:
		return
		
	if not hotbar:
		var found = player.find_child("ModularHotbar", true, false)
		if found and found is ModularHotbar:
			hotbar = found
			
	_bind_hotbar(hotbar)
	hotbar.bind_inventory(main_inventory.inventory)

func _bind_hotbar(hb: ModularHotbar) -> void:
	if hotbar and hotbar.selection_changed.is_connected(_on_hotbar_selection_changed):
		return
		
	hotbar = hb
	
	if hotbar:
		hotbar.selection_changed.connect(_on_hotbar_selection_changed)
		_on_hotbar_selection_changed(hotbar.selected_index)

func _on_ui_panel_spawned(panel: Control, scene: PackedScene, role: String) -> void:
	if role == "player":
		var hb = panel.find_child("ModularHotbar", true, false)
		if hb and hb is ModularHotbar:
			_bind_hotbar(hb)

func _unhandled_input(event: InputEvent) -> void:
	if active_logic and active_logic.can_use():
		active_logic.on_input(event)

func _process(delta: float) -> void:
	if active_logic:
		active_logic.update(delta)

func _on_hotbar_selection_changed(new_index: int) -> void:
	if not main_inventory or not main_inventory.inventory:
		return
		
	var global_idx = hotbar.get_selected_global_index()
	var inv = main_inventory.inventory
	var slot_data = inv.get_slot(global_idx)
	
	if active_slot_index >= 0 and inv.slot_changed.is_connected(_on_active_slot_changed):
		inv.slot_changed.disconnect(_on_active_slot_changed)
		
	if not slot_data or slot_data.is_empty():
		_cleanup_active_item()
		return
	
	_animate_unequip()
	_cleanup_active_item()
	
	active_slot_index = global_idx
	active_item = slot_data.item
	
	if not inv.slot_changed.is_connected(_on_active_slot_changed):
		inv.slot_changed.connect(_on_active_slot_changed)
		
	if active_item.model_scene:
		_equipped_weapon_model = active_item.model_scene.instantiate()
		if item_socket:
			item_socket.add_child(_equipped_weapon_model)
		else:
			player.add_child(_equipped_weapon_model)
		
		_animate_equip(_equipped_weapon_model)
		
	if active_item.logic_script:
		active_logic = active_item.logic_script.new()
		active_logic.setup(active_item, player, active_slot_index, _equipped_weapon_model, main_inventory.inventory)
		
	active_item_changed.emit(active_item, active_slot_index)

func _on_active_slot_changed(idx: int) -> void:
	if idx == active_slot_index:
		var inv = main_inventory.inventory
		var slot_data = inv.get_slot(active_slot_index)
		if not slot_data or slot_data.is_empty() or slot_data.item != active_item:
			_cleanup_active_item()

func _animate_equip(model: Node3D) -> void:
	if not animations_enabled or not model:
		return

	var anim_type = _get_item_meta(active_item, "equip_animation", default_equip_animation)
	var duration = _get_item_meta(active_item, "equip_duration", default_equip_duration)
	var socket_pos = Vector3.ZERO
	
	match anim_type:
		"scale":
			model.scale = Vector3.ZERO
			model.rotation = Vector3.ZERO
		"slide":
			model.position = socket_pos + Vector3(0, -0.4, 0)
			model.modulate.a = 0.0
		"rotate":
			model.scale = Vector3.ZERO
			model.rotation.y = -PI
		"fade":
			model.modulate.a = 0.0
		"none":
			return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK if anim_type == "scale" else Tween.TRANS_CUBIC)

	match anim_type:
		"scale":
			tween.tween_property(model, "scale", Vector3.ONE, duration)
		"slide":
			tween.set_parallel(true)
			tween.tween_property(model, "position", socket_pos, duration)
			tween.tween_property(model, "modulate:a", 1.0, duration)
		"rotate":
			tween.set_parallel(true)
			tween.tween_property(model, "scale", Vector3.ONE, duration)
			tween.tween_property(model, "rotation:y", 0.0, duration)
		"fade":
			tween.tween_property(model, "modulate:a", 1.0, duration)

func _animate_unequip() -> void:
	if not animations_enabled or not _equipped_weapon_model:
		_force_cleanup()
		return

	var model = _equipped_weapon_model
	
	var anim_type = _get_item_meta(active_item, "unequip_animation", default_unequip_animation)
	var duration = _get_item_meta(active_item, "unequip_duration", default_unequip_duration)

	_equipped_weapon_model = null

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	match anim_type:
		"scale":
			tween.tween_property(model, "scale", Vector3.ZERO, duration)
		"slide":
			tween.set_parallel(true)
			tween.tween_property(model, "position", default_unequip_drop, duration)
			tween.tween_property(model, "modulate:a", 0.0, duration)
		"rotate":
			tween.set_parallel(true)
			tween.tween_property(model, "scale", Vector3.ZERO, duration)
			tween.tween_property(model, "rotation:y", PI, duration)
		"fade":
			tween.tween_property(model, "modulate:a", 0.0, duration)
		"none":
			_force_cleanup()
			return

	tween.tween_callback(model.queue_free)

func _get_item_meta(item: ItemDefinition, key: String, default_value) -> Variant:
	if not item:
		return default_value
	if item.custom_metadata.has(key):
		return item.custom_metadata[key]
	return default_value
	
func _cleanup_active_item() -> void:
	if main_inventory and main_inventory.inventory and active_slot_index >= 0:
		if main_inventory.inventory.slot_changed.is_connected(_on_active_slot_changed):
			main_inventory.inventory.slot_changed.disconnect(_on_active_slot_changed)
			
	if active_logic:
		active_logic.on_release()
		active_logic.cleanup()
		active_logic = null
		
	if _equipped_weapon_model:
		_equipped_weapon_model.queue_free()
		_equipped_weapon_model = null
		
	active_item = null
	
func _force_cleanup() -> void:
	if _equipped_weapon_model:
		_equipped_weapon_model.queue_free()
		_equipped_weapon_model = null
		
func drop_active_item(amount: int = 1) -> void:
	if not main_inventory or not main_inventory.inventory:
		return
	if active_slot_index < 0:
		return
		
	var inv = main_inventory.inventory
	var slot = inv.get_slot(active_slot_index)
	if not slot or slot.is_empty():
		return
		
	var item_to_drop = slot.item
	var drop_count = mini(amount, slot.count)
	var durability = slot.get_effective_durability()
	
	slot.count -= drop_count
	if slot.count <= 0:
		slot.clear()
		
	inv.slot_changed.emit(active_slot_index)
	inv.inventory_changed.emit()
	
	if not player:
		push_error("EquipmentManager: 'player' reference is not assigned in Inspector!")
		return
		
	var forward = -player.global_transform.basis.z.normalized()
	var drop_pos = player.global_position + (forward * 1.5) + Vector3(0, 1.0, 0)
	
	var drag_drop := InventoryRuntimeScript.drag_drop()
	if drag_drop:
		drag_drop.spawn_world_item(item_to_drop, drop_count, durability, drop_pos)
