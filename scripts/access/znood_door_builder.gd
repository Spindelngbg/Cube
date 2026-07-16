class_name ZnoodDoorBuilder
extends RefCounted

const ZnoodAccessDoorScript = preload("res://scripts/access/znood_access_door.gd")


static func place(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	door_id: String,
	rotation_y: float = 0.0,
	prompt: String = "Stämpla Znood [E]"
) -> ZnoodAccessDoor:
	var door: ZnoodAccessDoor = ZnoodAccessDoorScript.new()
	door.name = "ZnoodDoor_%s" % door_id
	door.door_id = door_id
	door.prompt_locked = prompt
	door.position = pos
	door.rotation.y = rotation_y
	parent.add_child(door)
	door.setup(size)
	return door