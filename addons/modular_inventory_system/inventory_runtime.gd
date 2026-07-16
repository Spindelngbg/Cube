extends RefCounted


static func drag_drop() -> Node:
	return _root_singleton("DragDropSystem")


static func ui_state() -> Node:
	return _root_singleton("UIStateManager")


static func is_dragging() -> bool:
	var drag_drop := drag_drop()
	return drag_drop != null and drag_drop.is_dragging


static func _root_singleton(name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)