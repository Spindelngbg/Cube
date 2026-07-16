class_name HumanAvatarBuilder
extends RefCounted

const RESERVED_CHILDREN := ["ZnoodMount", "AvatarAnimator", "HumanAvatarAnimator"]


static func build(parent: Node3D, data: AvatarData) -> Node3D:
	_clear_model_children(parent)
	var mesh_id := HumanCharacterLibrary.normalize_mesh_id(data.mesh_id)
	var model := HumanCharacterLibrary.spawn(
		parent,
		Vector3.ZERO,
		0.0,
		data.body_scale,
		mesh_id
	)
	if model == null:
		return null
	HumanCharacterLibrary.apply_avatar_customization(model, data)
	model.set_meta("mesh_id", mesh_id)
	return model


static func _clear_model_children(parent: Node3D) -> void:
	var to_remove: Array[Node] = []
	for child in parent.get_children():
		if child.name in RESERVED_CHILDREN:
			continue
		to_remove.append(child)
	for child in to_remove:
		parent.remove_child(child)
		child.queue_free()