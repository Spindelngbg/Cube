class_name RuntimeGlobals
extends RefCounted

const ZnoodScript = preload("res://scripts/znood/znood_manager.gd")
const ZoneOwnershipScript = preload("res://scripts/cube/zone_ownership_manager.gd")


static func znood() -> ZnoodManagerNode:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).root.get_node_or_null("/root/ZnoodManager") as ZnoodManagerNode
	return null


static func zone_ownership() -> ZoneOwnershipManagerNode:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).root.get_node_or_null("/root/ZoneOwnershipManager") as ZoneOwnershipManagerNode
	return null