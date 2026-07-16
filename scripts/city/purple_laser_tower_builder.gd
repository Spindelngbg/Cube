class_name PurpleLaserTowerBuilder
extends RefCounted

const LaserRiflePickupScript = preload("res://scripts/items/laser_rifle_pickup.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")

const PURPLE_TINT := Color(0.72, 0.34, 0.95)
const PURPLE_GLOW := Color(0.55, 0.22, 0.88)
const LASER_WEAPON_ID := "laserrifle"

const FLOOR_HEIGHTS := [1.2, 4.2, 7.4, 10.6, 13.8]
const PICKUP_OFFSETS := [
	Vector3(-3.5, 0.0, 2.0),
	Vector3(3.0, 0.0, -1.5),
	Vector3(-1.5, 0.0, -3.0),
	Vector3(2.5, 0.0, 2.8),
	Vector3(0.0, 0.0, 0.5),
]


static func build(parent: Node3D, anchor: Vector3, poi_suffix: String = "dc") -> Node3D:
	var tower := Node3D.new()
	tower.name = "PurpleLaserTower"
	tower.position = anchor
	parent.add_child(tower)

	var facade := CityKitLibrary.spawn(
		tower,
		"commercial",
		"building-skyscraper-b",
		Vector3.ZERO,
		PI * 0.15,
		-1.0,
		PURPLE_TINT
	)
	if facade != null:
		_disable_collision(facade)

	var shell := StaticBody3D.new()
	shell.name = "InteriorShell"
	tower.add_child(shell)

	for floor_y in FLOOR_HEIGHTS:
		_add_floor(shell, floor_y)

	var pickups := Node3D.new()
	pickups.name = "LaserPickups"
	tower.add_child(pickups)

	for i in range(PICKUP_OFFSETS.size()):
		var floor_idx := i % FLOOR_HEIGHTS.size()
		var pickup := LaserRiflePickupScript.new()
		pickup.name = "LaserRiflePickup_%d" % i
		pickup.item_id = LASER_WEAPON_ID
		pickup.prompt_text = "Plocka upp Lasergevär [E]"
		pickup.one_shot = true
		pickup.position = PICKUP_OFFSETS[i] + Vector3(0.0, FLOOR_HEIGHTS[floor_idx], 0.0)
		pickups.add_child(pickup)

	var lobby_light := OmniLight3D.new()
	lobby_light.position = Vector3(0.0, 3.0, 0.0)
	lobby_light.light_color = PURPLE_GLOW
	lobby_light.light_energy = 1.1
	lobby_light.omni_range = 18.0
	tower.add_child(lobby_light)

	var upper_light := OmniLight3D.new()
	upper_light.position = Vector3(0.0, 12.0, 0.0)
	upper_light.light_color = Color(0.45, 0.85, 1.0)
	upper_light.light_energy = 0.85
	upper_light.omni_range = 14.0
	tower.add_child(upper_light)

	var sign := Label3D.new()
	sign.text = "LILA LASERTORN\nLasergevär inuti"
	sign.font_size = 38
	sign.modulate = PURPLE_TINT.lightened(0.15)
	sign.outline_modulate = Color(0.08, 0.04, 0.12, 0.95)
	sign.position = Vector3(0.0, 16.5, 5.5)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tower.add_child(sign)

	var arrow := Label3D.new()
	arrow.text = "LASER →"
	arrow.font_size = 30
	arrow.modulate = Color(0.55, 0.95, 1.0)
	arrow.position = Vector3(-5.0, 2.2, 4.0)
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tower.add_child(arrow)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = "purple_laser_tower_%s" % poi_suffix
	marker.display_name = "Lila Lasertorn"
	marker.category = "vapen"
	marker.keywords = PackedStringArray(["laser", "lasertorn", "gevär", "lila", "vapen"])
	marker.map_color = PURPLE_TINT
	tower.add_child(marker)

	return tower


static func _disable_collision(node: Node) -> void:
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
	for child in node.get_children():
		_disable_collision(child)


static func _add_floor(shell: StaticBody3D, floor_y: float) -> void:
	var floor_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 0.35, 10.0)
	floor_node.shape = box
	floor_node.position = Vector3(0.0, floor_y, 0.0)
	shell.add_child(floor_node)

	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(9.6, 0.12, 9.6)
	visual.mesh = mesh
	visual.position = Vector3(0.0, floor_y - 0.04, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.1, 0.24)
	mat.emission_enabled = true
	mat.emission = PURPLE_GLOW
	mat.emission_energy_multiplier = 0.12
	visual.material_override = mat
	shell.add_child(visual)