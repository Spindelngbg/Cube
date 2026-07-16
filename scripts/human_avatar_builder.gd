class_name HumanAvatarBuilder
extends RefCounted

const RESERVED_CHILDREN := ["ZnoodMount", "AvatarAnimator", "HumanAvatarAnimator"]


static func build(parent: Node3D, data: AvatarData) -> Node3D:
	_clear_model_children(parent)
	var model := HumanCharacterLibrary.spawn(parent, Vector3.ZERO, 0.0, data.body_scale)
	if model == null:
		return null
	HumanCharacterLibrary.apply_avatar_customization(model, data)
	return model


static func _clear_model_children(parent: Node3D) -> void:
	for child in parent.get_children():
		if child.name in RESERVED_CHILDREN:
			continue
		child.queue_free()