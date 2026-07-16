class_name SciFiEssentialsLibrary
extends RefCounted

const BASE_PATH := "res://assets/models/sci-fi-essentials-kit/glTF/"

const MODELS := [
	"Enemy_EyeDrone",
	"Enemy_QuadShell",
	"Enemy_Trilobite",
	"Gun_Pistol",
	"Gun_Revolver",
	"Gun_Rifle",
	"Gun_SMG_Ammo",
	"Gun_Sniper",
	"Gun_Sniper_Ammo",
	"Prop_Ammo",
	"Prop_Ammo_Closed",
	"Prop_Ammo_Small",
	"Prop_Barrel1",
	"Prop_Barrel2_Closed",
	"Prop_Barrel2_Open",
	"Prop_Chair",
	"Prop_Chest",
	"Prop_Crate",
	"Prop_Crate_Large",
	"Prop_Crate_Tarp",
	"Prop_Crate_Tarp_Large",
	"Prop_Desk_L",
	"Prop_Desk_Medium",
	"Prop_Desk_Small",
	"Prop_Grenade",
	"Prop_HealthPack",
	"Prop_HealthPack_Tube",
	"Prop_KeyCard",
	"Prop_Locker",
	"Prop_Mine",
	"Prop_Mug",
	"Prop_SatelliteDish",
	"Prop_Shelves_ThinShort",
	"Prop_Shelves_ThinTall",
	"Prop_Shelves_WideShort",
	"Prop_Shelves_WideTall",
	"Prop_Syringe",
]


static func model_path(name: String) -> String:
	var file_name := name
	if not (file_name.ends_with(".gltf") or file_name.ends_with(".glb")):
		file_name = "%s.gltf" % name
	return BASE_PATH + file_name


static func load_model(name: String) -> PackedScene:
	var path := model_path(name)
	if ResourceLoader.exists(path):
		return load(path) as PackedScene
	push_warning("Sci-Fi Essentials model not found: %s" % path)
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