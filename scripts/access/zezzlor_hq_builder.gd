class_name ZezzlorHqBuilder
extends RefCounted

const ZezzlorHqScript = preload("res://scripts/access/zezzlor_hq.gd")
const ZezzlorHqCatalogScript = preload("res://scripts/story/zezzlor_hq_catalog.gd")


static func place_all(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "ZezzlorHqSites"
	parent.add_child(root)
	for entry in ZezzlorHqCatalogScript.get_placements():
		place(root, entry)
	return root


static func place(parent: Node3D, entry: Dictionary) -> ZezzlorHq:
	var hq: ZezzlorHq = ZezzlorHqScript.new()
	hq.name = str(entry.get("id", "ZezzlorHq"))
	hq.setup(entry)
	parent.add_child(hq)
	return hq