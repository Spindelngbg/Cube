class_name DevBuildingLabels
extends RefCounted

static var _next_id := 1


static func reset() -> void:
	_next_id = 1


static func attach(
	parent: Node3D,
	anchor: Vector3,
	footprint_half: Vector3,
	rotation_y: float = 0.0
) -> int:
	var id := _next_id
	_next_id += 1

	var corner_local := Vector3(footprint_half.x, footprint_half.y, footprint_half.z)
	var corner_offset: Vector3 = corner_local.rotated(Vector3.UP, rotation_y)

	var marker := Node3D.new()
	marker.name = "DevBuildingMarker_%d" % id
	marker.position = anchor + corner_offset
	parent.add_child(marker)

	var label := Label3D.new()
	label.text = str(id)
	label.font_size = 72
	label.modulate = Color(1.0, 0.88, 0.12)
	label.outline_modulate = Color(0.04, 0.05, 0.1, 1.0)
	label.outline_size = 9
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector3(0.0, 0.6, 0.0)
	marker.add_child(label)

	var tile := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.1, 0.08, 1.1)
	tile.mesh = mesh
	tile.position = Vector3(0.0, 0.04, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.08)
	mat.emission_energy_multiplier = 0.95
	tile.material_override = mat
	marker.add_child(tile)

	return id


static func footprint_half_for_city_kit(kit: String, scale_factor: float = -1.0) -> Vector3:
	var scale := scale_factor if scale_factor > 0.0 else CityKitLibrary.kit_scale(kit)
	var half := scale * 0.42
	return Vector3(half, 1.6, half)


static func footprint_half_for_space_model(model: String) -> Vector3:
	if model.begins_with("room-large"):
		return Vector3(5.5, 1.4, 5.5)
	if model.begins_with("room-wide"):
		return Vector3(4.5, 1.3, 4.5)
	if model.begins_with("room-small"):
		return Vector3(3.2, 1.2, 3.2)
	if model.begins_with("room-"):
		return Vector3(3.8, 1.2, 3.8)
	return Vector3(2.5, 1.0, 2.5)