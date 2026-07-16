@tool
extends Node3D
class_name InventoryDisplayComponent

@export_group("Inventory")
@export var inventory_component: InventoryComponent

@export_group("Display Markers")
@export var marker_container: Node3D

@export_group("Options")
@export var auto_discover_markers: bool = true
@export var markers: Array[Node3D] = []

var _displayed_items: Array[Node3D] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if not inventory_component:
		_try_find_inventory_component()

	if auto_discover_markers and markers.is_empty() and marker_container:
		_discover_markers()

	if inventory_component:
		if not inventory_component.inventory_ready.is_connected(_on_inventory_ready):
			inventory_component.inventory_ready.connect(_on_inventory_ready)
		var inv = inventory_component.get_inventory()
		if inv:
			_on_inventory_ready(inv)


func _try_find_inventory_component() -> void:
	var parent = get_parent()
	if not parent:
		return
	for child in parent.get_children():
		if child is InventoryComponent:
			inventory_component = child
			return

func _discover_markers() -> void:
	markers.clear()
	if not marker_container:
		return
	for child in marker_container.get_children():
		if child is Marker3D:
			markers.append(child)

func _on_inventory_ready(inv: Inventory) -> void:
	if not inv.inventory_changed.is_connected(_on_inventory_changed):
		inv.inventory_changed.connect(_on_inventory_changed)
	refresh_display()

func _on_inventory_changed() -> void:
	refresh_display()

func refresh_display() -> void:
	_clear_display()

	if not inventory_component:
		return
	var inv = inventory_component.get_inventory()
	if not inv:
		return

	var marker_count = mini(markers.size(), inv.capacity)
	for i in marker_count:
		var slot = inv.get_slot(i)
		if not slot or slot.is_empty() or not slot.item:
			continue

		var model_node = _create_model_for_slot(slot)
		if model_node:
			markers[i].add_child(model_node)
			model_node.transform = Transform3D()

			if slot.item.preview_offset != Vector3.ZERO:
				model_node.position += slot.item.preview_offset

			_displayed_items.append(model_node)

func _clear_display() -> void:
	for item in _displayed_items:
		if is_instance_valid(item):
			item.queue_free()
	_displayed_items.clear()


func _create_model_for_slot(slot: SlotData) -> Node3D:
	var item = slot.item
	if not item:
		return null

	if item.placement_scene:
		return item.placement_scene.instantiate()
	elif item.model_scene:
		return item.model_scene.instantiate()
	else:
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.2, 0.2, 0.2)
		mesh_inst.mesh = box
		return mesh_inst
