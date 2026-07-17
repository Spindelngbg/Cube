class_name FeaturedBuildingBuilder
extends RefCounted

const ExteriorLadderScript = preload("res://scripts/access/exterior_ladder.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

## Dev-byggnad 33 i Neo-Washington: Ambassadnäset vid rutnät (-4, 5).
const BUILDING_33_CELL := Vector2i(-4, 5)
const BUILDING_HEIGHT_M := 17.2
const LADDER_HEIGHT_M := 17.55
const ROOF_DECK_Y := 17.65
const FACADE_LIGHT_COLOR := Color(0.95, 0.92, 0.82)


static func is_building_33_cell(cell: Vector2i) -> bool:
	return cell == BUILDING_33_CELL


static func enhance(
	zone_root: Node3D,
	building: Node3D,
	center: Vector3,
	rotation_y: float,
	scale_factor: float
) -> void:
	## Stege/takdäck borttaget — såg ut som lösa bitar i luften.
	## Behåll bara mild ljusboost på huset.
	if building == null:
		return

	building.set_meta("featured_building_id", 33)
	building.name = "AmbassadorBuilding_33"

	CityKitLibrary.brighten_building(
		building,
		Color(1.08, 1.06, 1.04),
		Color(0.45, 0.52, 0.68),
		0.12
	)
	_add_facade_light(zone_root, center, rotation_y, scale_factor)


static func _facade_offset(rotation_y: float, scale_factor: float) -> Vector3:
	var half := scale_factor * 0.42
	return Vector3(half + 0.55, 0.0, 0.0).rotated(Vector3.UP, rotation_y)


static func _add_facade_light(
	zone_root: Node3D,
	center: Vector3,
	rotation_y: float,
	scale_factor: float
) -> void:
	var mount := Node3D.new()
	mount.name = "Building33Lights"
	mount.position = center
	zone_root.add_child(mount)

	var wall_offset := _facade_offset(rotation_y, scale_factor)
	var wall_light := SpotLight3D.new()
	wall_light.position = wall_offset + Vector3(0.0, BUILDING_HEIGHT_M * 0.55, 0.0)
	wall_light.rotation_degrees = Vector3(-12.0, rad_to_deg(rotation_y + PI), 0.0)
	wall_light.light_color = FACADE_LIGHT_COLOR
	wall_light.light_energy = 2.4
	wall_light.spot_range = 28.0
	wall_light.spot_angle = 42.0
	wall_light.shadow_enabled = false
	mount.add_child(wall_light)

	var fill := OmniLight3D.new()
	fill.position = center + Vector3(0.0, BUILDING_HEIGHT_M * 0.45, 0.0)
	fill.light_color = Color(0.88, 0.9, 0.98)
	fill.light_energy = 1.35
	fill.omni_range = 22.0
	fill.shadow_enabled = false
	mount.add_child(fill)


static func _add_exterior_ladder(
	zone_root: Node3D,
	center: Vector3,
	rotation_y: float,
	scale_factor: float
) -> void:
	var mount := Node3D.new()
	mount.name = "Building33Ladder"
	mount.position = center + _facade_offset(rotation_y, scale_factor)
	mount.rotation.y = rotation_y
	zone_root.add_child(mount)

	ExteriorLadderScript.build_visual(mount, LADDER_HEIGHT_M)


static func _add_roof_deck(
	zone_root: Node3D,
	center: Vector3,
	rotation_y: float,
	scale_factor: float
) -> void:
	var deck_y := ROOF_DECK_Y
	var deck := StaticBody3D.new()
	deck.name = "Building33RoofDeck"
	deck.position = center + Vector3(0.0, deck_y, 0.0)
	deck.rotation.y = rotation_y
	deck.collision_layer = WorldCollisionBuilderScript.WORLD_COLLISION_LAYER
	deck.collision_mask = 0
	zone_root.add_child(deck)

	var deck_size := Vector3(scale_factor * 0.78, 0.28, scale_factor * 0.78)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = deck_size
	shape.shape = box
	shape.position = Vector3(0.0, deck_size.y * 0.5, 0.0)
	deck.add_child(shape)

	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = deck_size
	mesh_node.mesh = mesh
	mesh_node.position = shape.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.66, 0.74)
	mat.metallic = 0.42
	mat.roughness = 0.58
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.42, 0.55)
	mat.emission_energy_multiplier = 0.12
	mesh_node.material_override = mat
	deck.add_child(mesh_node)


static func _add_roof_sign(
	zone_root: Node3D,
	center: Vector3,
	rotation_y: float,
	_scale_factor: float
) -> void:
	var sign := Label3D.new()
	sign.text = "Ambassadnäset 4-5\nTak via stege"
	sign.font_size = 28
	sign.modulate = Color(0.92, 0.88, 0.72)
	sign.outline_modulate = Color(0.08, 0.1, 0.14, 0.95)
	sign.position = center + Vector3(0.0, BUILDING_HEIGHT_M + 1.8, 0.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	zone_root.add_child(sign)