class_name WorldCollisionBuilder
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")

const WORLD_COLLISION_LAYER := 1

## Labels/lights still use footprint ~scale*0.42. Collision is built from mesh AABB and
## shrunk on XZ so exterior pillars / porticos / roof overhangs stay walkable.
const MESH_XZ_SHRINK_DEFAULT := 0.82
const MESH_XZ_SHRINK_PORTICO := 0.70
const MESH_XZ_SHRINK_SOLID := 0.92
## Fallback half-extent ratios when mesh AABB is missing (world units / scale).
const FALLBACK_HALF_RATIO := 0.32
const FALLBACK_HALF_RATIO_PORTICO := 0.28


static func should_collide_city_kit(kit: String, model_name: String = "") -> bool:
	if kit == "roads":
		return false
	if kit == "suburban" and model_name.begins_with("tree-"):
		return false
	if kit == "building":
		if model_name == "floor" or model_name.begins_with("floor-"):
			return false
		return true
	return true


static func should_collide_space_model(model_name: String) -> bool:
	if model_name == "cables":
		return false
	if model_name.begins_with("template-floor"):
		return false
	return true


static func attach_from_meshes(root: Node3D, min_height: float = 0.8) -> StaticBody3D:
	if root == null:
		return null
	var aabb := _mesh_aabb_in_root_space(root)
	if aabb.size.length_squared() < 0.04:
		return null
	if aabb.size.y < min_height:
		var bottom := aabb.position.y
		aabb.size.y = min_height
		aabb.position.y = bottom
	var body := _make_box_body(aabb.size, aabb.get_center())
	body.name = "WorldCollision"
	root.add_child(body)
	return body


static func attach_box(root: Node3D, size: Vector3, position: Vector3) -> StaticBody3D:
	if root == null or size.length_squared() < 0.04:
		return null
	var body := _make_box_body(size, position)
	body.name = "WorldCollision"
	root.add_child(body)
	return body


static func attach_city_kit_collision(instance: Node3D, kit: String, model_name: String = "") -> void:
	if instance == null or not should_collide_city_kit(kit, model_name):
		return
	var scale_uniform := _uniform_scale(instance)
	if kit == "building" and model_name.begins_with("wall"):
		var wall_world := Vector3(scale_uniform * 2.0, scale_uniform * 2.0, scale_uniform * 0.4)
		var wall_local := _local_size_for_scaled_parent(wall_world, instance)
		attach_box(instance, wall_local, Vector3(0.0, wall_local.y * 0.5, 0.0))
		return

	var xz_shrink := _city_kit_xz_shrink(kit, model_name)
	var aabb := _mesh_aabb_in_root_space(instance)
	if aabb.size.x > 0.05 and aabb.size.z > 0.05:
		var height := maxf(aabb.size.y, _min_collision_height(kit, model_name))
		## Keep full height so roofs/upper floors still block; only inset the floor plan.
		var size := Vector3(aabb.size.x * xz_shrink, height, aabb.size.z * xz_shrink)
		var center := aabb.get_center()
		var pos := Vector3(center.x, aabb.position.y + height * 0.5, center.z)
		attach_box(instance, size, pos)
		return

	## Fallback: ratio of scale (tighter than the old 0.42 visual footprint).
	var half_ratio := (
		FALLBACK_HALF_RATIO_PORTICO if _has_exterior_portico(kit, model_name) else FALLBACK_HALF_RATIO
	)
	if kit == "industrial":
		half_ratio = 0.36
	var half := scale_uniform * half_ratio
	var height := _fallback_height(kit, model_name, scale_uniform)
	var world_size := Vector3(half * 2.0, height, half * 2.0)
	var local_size := _local_size_for_scaled_parent(world_size, instance)
	attach_box(instance, local_size, Vector3(0.0, local_size.y * 0.5, 0.0))


static func _city_kit_xz_shrink(kit: String, model_name: String) -> float:
	if _has_exterior_portico(kit, model_name):
		return MESH_XZ_SHRINK_PORTICO
	if kit == "industrial" or kit == "building":
		return MESH_XZ_SHRINK_SOLID
	return MESH_XZ_SHRINK_DEFAULT


static func _has_exterior_portico(kit: String, model_name: String) -> bool:
	## Kenney commercial/suburban façades with free-standing columns or deep overhangs.
	if kit == "commercial":
		return model_name in [
			"building-a",
			"building-b",
			"building-d",
			"building-e",
			"building-f",
			"building-g",
			"building-h",
			"building-i",
			"building-j",
			"building-k",
			"building-l",
			"building-m",
			"building-n",
		]
	if kit == "suburban":
		return model_name in [
			"building-type-c",
			"building-type-e",
			"building-type-f",
			"building-type-g",
			"building-type-h",
			"building-type-i",
			"building-type-j",
			"building-type-k",
			"building-type-l",
			"building-type-m",
			"building-type-n",
			"building-type-o",
			"building-type-p",
			"building-type-q",
			"building-type-r",
			"building-type-s",
			"building-type-t",
		]
	return false


static func attach_space_kit_collision(instance: Node3D, model_name: String) -> void:
	if instance == null or not should_collide_space_model(model_name):
		return
	var half := DevBuildingLabelsScript.footprint_half_for_space_model(model_name)
	if model_name.begins_with("template-wall"):
		var wall_height := 3.2
		attach_box(
			instance,
			Vector3(half.x * 2.0, wall_height, maxf(half.z * 2.0, 0.5)),
			Vector3(0.0, wall_height * 0.5, 0.0)
		)
		return
	var height := 3.6 if model_name.begins_with("room-") else 3.0
	attach_box(instance, Vector3(half.x * 2.0, height, half.z * 2.0), Vector3(0.0, height * 0.5, 0.0))


static func _uniform_scale(node: Node3D) -> float:
	if node == null:
		return 1.0
	return maxf(maxf(node.scale.x, node.scale.y), node.scale.z)


static func _local_size_for_scaled_parent(world_size: Vector3, parent: Node3D) -> Vector3:
	var scale := _uniform_scale(parent)
	if scale <= 0.001:
		return world_size
	return world_size / scale


static func _min_collision_height(kit: String, model_name: String) -> float:
	if kit == "building" and model_name.begins_with("wall"):
		return 1.6
	return 0.8


static func _fallback_height(kit: String, model_name: String, scale_uniform: float) -> float:
	if kit == "building" and model_name.begins_with("wall"):
		return maxf(scale_uniform * 2.0, 3.0)
	return maxf(scale_uniform * 1.15, 4.0)


static func _make_box_body(size: Vector3, position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WORLD_COLLISION_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = position
	body.add_child(shape)
	return body


static func _collect_mesh_instances(root: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		meshes.append(root as MeshInstance3D)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node != null and mesh_node not in meshes:
			meshes.append(mesh_node)
	return meshes


static func _mesh_aabb_in_root_space(root: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for mesh_node in _collect_mesh_instances(root):
		if mesh_node.mesh == null:
			continue
		var mesh_aabb := mesh_node.mesh.get_aabb()
		if mesh_aabb.size.length_squared() < 0.001:
			continue
		var to_root := _relative_transform(mesh_node, root)
		var transformed := _transform_aabb(to_root, mesh_aabb)
		if not found:
			result = transformed
			found = true
		else:
			result = result.merge(transformed)
	return result


static func _relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node3D = node
	while current != null and current != root:
		xf = current.transform * xf
		current = current.get_parent() as Node3D
	return xf


static func _transform_aabb(xform: Transform3D, aabb: AABB) -> AABB:
	var end := aabb.position + aabb.size
	var corners: Array[Vector3] = [
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
		Vector3(end.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x, end.y, aabb.position.z),
		Vector3(end.x, end.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y, end.z),
		Vector3(end.x, aabb.position.y, end.z),
		Vector3(aabb.position.x, end.y, end.z),
		Vector3(end.x, end.y, end.z),
	]
	var first: Vector3 = xform * corners[0]
	var min_v: Vector3 = first
	var max_v: Vector3 = first
	for i in range(1, corners.size()):
		var point: Vector3 = xform * corners[i]
		min_v = min_v.min(point)
		max_v = max_v.max(point)
	return AABB(min_v, max_v - min_v)