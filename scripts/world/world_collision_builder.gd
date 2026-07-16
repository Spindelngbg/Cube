class_name WorldCollisionBuilder
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")

const WORLD_COLLISION_LAYER := 1


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
	var scale_uniform := maxf(maxf(instance.scale.x, instance.scale.y), instance.scale.z)
	scale_uniform = maxf(scale_uniform, 0.001)
	var half := DevBuildingLabelsScript.footprint_half_for_city_kit(kit, scale_uniform)
	var height := _fallback_height(kit, model_name, scale_uniform)
	var size := Vector3(half.x * 2.0, height, half.z * 2.0)
	if kit == "building" and model_name.begins_with("wall"):
		size = Vector3(scale_uniform * 2.0, scale_uniform * 2.0, scale_uniform * 0.4)
	attach_box(instance, size, Vector3(0.0, size.y * 0.5, 0.0))


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