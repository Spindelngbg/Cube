class_name SpaceKitLibrary
extends RefCounted

const BASE_PATH := "res://assets/models/modular-space-kit/Models/GLB format/"

const MODELS := [
	"cables",
	"corridor",
	"corridor-corner",
	"corridor-end",
	"corridor-intersection",
	"corridor-junction",
	"corridor-transition",
	"corridor-wide",
	"corridor-wide-corner",
	"corridor-wide-end",
	"corridor-wide-intersection",
	"corridor-wide-junction",
	"gate",
	"gate-door",
	"gate-door-window",
	"gate-lasers",
	"room-corner",
	"room-large",
	"room-large-variation",
	"room-small",
	"room-small-variation",
	"room-wide",
	"room-wide-variation",
	"stairs",
	"stairs-wide",
	"template-corner",
	"template-detail",
	"template-floor",
	"template-floor-big",
	"template-floor-detail",
	"template-floor-detail-a",
	"template-floor-layer",
	"template-floor-layer-hole",
	"template-floor-layer-raised",
	"template-wall",
	"template-wall-corner",
	"template-wall-detail-a",
	"template-wall-half",
	"template-wall-stairs",
	"template-wall-top",
]


static func model_path(name: String) -> String:
	var file_name := name if name.ends_with(".glb") else "%s.glb" % name
	return BASE_PATH + file_name


static func load_model(name: String) -> PackedScene:
	var path := model_path(name)
	if ResourceLoader.exists(path):
		return load(path) as PackedScene
	push_warning("Space kit model not found: %s" % path)
	return null


static func spawn(parent: Node3D, name: String, position: Vector3 = Vector3.ZERO, rotation_y: float = 0.0) -> Node3D:
	var scene := load_model(name)
	if scene == null or parent == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	instance.position = position
	instance.rotation.y = rotation_y
	parent.add_child(instance)
	return instance


static func get_model_names() -> PackedStringArray:
	return PackedStringArray(MODELS)