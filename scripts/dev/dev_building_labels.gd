class_name DevBuildingLabels
extends RefCounted

const WALL_NUDGE_M := 0.1
const LABEL_HEIGHT_M := 1.35
const VISIBILITY_BEGIN_M := 14.0
const VISIBILITY_END_M := 22.0

static var _next_id := 1


static func reset() -> void:
	_next_id = 1


static func peek_next_id() -> int:
	return _next_id


static func attach(
	parent: Node3D,
	anchor: Vector3,
	footprint_half: Vector3,
	rotation_y: float = 0.0,
	building: Node3D = null
) -> int:
	var id := _next_id
	_next_id += 1

	var marker := Node3D.new()
	marker.name = "DevBuildingMarker_%d" % id

	if building != null:
		var scale_uniform := maxf(building.scale.x, 0.001)
		var half_local := Vector3(
			footprint_half.x / scale_uniform,
			0.0,
			footprint_half.z / scale_uniform
		)
		var nudge_local := WALL_NUDGE_M / scale_uniform
		var height_local := LABEL_HEIGHT_M / scale_uniform
		marker.position = Vector3(
			half_local.x + nudge_local,
			height_local,
			half_local.z + nudge_local
		)
		building.add_child(marker)
	else:
		var corner_local := Vector3(
			footprint_half.x + WALL_NUDGE_M,
			LABEL_HEIGHT_M,
			footprint_half.z + WALL_NUDGE_M
		)
		marker.position = anchor + corner_local.rotated(Vector3.UP, rotation_y)
		parent.add_child(marker)

	var label := Label3D.new()
	label.text = str(id)
	label.font_size = 56
	label.modulate = Color(1.0, 0.88, 0.12)
	label.outline_modulate = Color(0.04, 0.05, 0.1, 1.0)
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_close_range_visibility(label)
	marker.add_child(label)

	return id


static func _apply_close_range_visibility(instance: GeometryInstance3D) -> void:
	instance.visibility_range_begin = 0.0
	instance.visibility_range_end = VISIBILITY_END_M
	instance.visibility_range_end_margin = maxf(VISIBILITY_END_M - VISIBILITY_BEGIN_M, 1.0)
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED


static func footprint_half_for_city_kit(kit: String, scale_factor: float = -1.0) -> Vector3:
	var scale := scale_factor if scale_factor > 0.0 else CityKitLibrary.kit_scale(kit)
	var half := scale * 0.42
	return Vector3(half, 0.0, half)


static func footprint_half_for_space_model(model: String) -> Vector3:
	if model.begins_with("room-large"):
		return Vector3(5.5, 0.0, 5.5)
	if model.begins_with("room-wide"):
		return Vector3(4.5, 0.0, 4.5)
	if model.begins_with("room-small"):
		return Vector3(3.2, 0.0, 3.2)
	if model.begins_with("room-"):
		return Vector3(3.8, 0.0, 3.8)
	return Vector3(2.5, 0.0, 2.5)