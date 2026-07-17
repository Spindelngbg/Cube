class_name RuntimeVisibilityBudget
extends RefCounted

const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")
const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")


static func apply_to_root(root: Node3D, end_distance: float) -> void:
	if root == null or end_distance <= 1.0:
		return
	# Lite kortare än camera.far så geometry cullas tidigare.
	var end := end_distance * 0.88
	_apply_node(root, end, false)


static func clear_from_root(root: Node3D) -> void:
	if root == null:
		return
	_apply_node(root, 0.0, true)


static func apply_zone_culling(city: Node3D, viewer_pos: Vector3, radius_m: float) -> void:
	if city == null or radius_m <= 1.0:
		return
	var zones := city.get_node_or_null("ZonedBlocks")
	if zones == null:
		return
	var radius_sq := radius_m * radius_m
	var half_block := DcZoneCatalogScript.BLOCK_M * 0.5
	for child in zones.get_children():
		if not child is Node3D:
			continue
		var zone := child as Node3D
		var center := zone.global_position + Vector3(half_block, 0.0, half_block)
		var offset := center - viewer_pos
		zone.visible = offset.x * offset.x + offset.z * offset.z <= radius_sq


static func _apply_node(node: Node, end_distance: float, clear: bool) -> void:
	if node is GeometryInstance3D:
		var geo := node as GeometryInstance3D
		if clear:
			geo.visibility_range_begin = 0.0
			geo.visibility_range_end = 0.0
			geo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		else:
			geo.visibility_range_begin = 0.0
			geo.visibility_range_end = end_distance
			geo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for child in node.get_children():
		_apply_node(child, end_distance, clear)