class_name ZezzlorCheckpointBuilder
extends RefCounted

const ZezzlorCheckpointScript = preload("res://scripts/access/zezzlor_checkpoint.gd")
const ZezzlorCheckpointCatalogScript = preload("res://scripts/story/zezzlor_checkpoint_catalog.gd")


static func place_all(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "ZezzlorCheckpoints"
	parent.add_child(root)

	for entry in ZezzlorCheckpointCatalogScript.get_placements():
		place(root, entry)

	return root


static func place(parent: Node3D, entry: Dictionary) -> ZezzlorCheckpoint:
	var checkpoint: ZezzlorCheckpoint = ZezzlorCheckpointScript.new()
	var door_id := str(entry.get("id", "zezzlor_cp"))
	checkpoint.name = "ZezzlorCheckpoint_%s" % door_id
	checkpoint.door_id = door_id
	checkpoint.position = entry.get("pos", Vector3.ZERO)
	checkpoint.rotation.y = float(entry.get("rotation_y", 0.0))
	parent.add_child(checkpoint)
	checkpoint.setup_checkpoint(entry.get("size", Vector3(8.0, 3.2, 0.35)))
	return checkpoint