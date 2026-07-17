class_name ColonySpawnLoot
extends RefCounted

## Vapen och loot på marken nära spawn — Koloni 4.

const ItemPickupScript = preload("res://scripts/items/item_pickup.gd")
const WeaponPickupScript = preload("res://scripts/items/weapon_pickup.gd")
const LaserRiflePickupScript = preload("res://scripts/items/laser_rifle_pickup.gd")

## Offsets från play-spawn (XZ). Y sätts till golv.
const GROUND_WEAPONS := [
	{"id": "slimeshooter", "offset": Vector3(5.5, 0.0, 3.5), "label": "Slemskytt"},
	{"id": "laserrifle", "offset": Vector3(-4.5, 0.0, 6.0), "label": "Lasergevär"},
	{"id": "neon_stinger_mk2", "offset": Vector3(8.0, 0.0, -4.0), "label": "Neon Stinger MK2"},
	{"id": "corrosion_cannon_x9", "offset": Vector3(-7.5, 0.0, -5.5), "label": "Korrosionskanon X9"},
	{"id": "mountblast_3000", "offset": Vector3(3.0, 0.0, 9.5), "label": "Mountblast 3000"},
	{"id": "plasma_ripper_7", "offset": Vector3(-9.0, 0.0, 2.0), "label": "Plasma Ripper 7"},
	{"id": "redemption_blade", "offset": Vector3(6.5, 0.0, 7.0), "label": "Redemption-klinga"},
	{"id": "zezzlor_gut_knife", "offset": Vector3(-3.0, 0.0, -8.0), "label": "Zezzlor tarmkniv"},
]


static func place_near_spawn(parent: Node3D, spawn_id: String, spawn_pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "ColonySpawnLoot"
	parent.add_child(root)

	if SpawnPoints.normalize_id(spawn_id) != "satellite_right":
		return root

	var floor_y := 0.05
	for i in GROUND_WEAPONS.size():
		var entry: Dictionary = GROUND_WEAPONS[i]
		var item_id := str(entry.get("id", ""))
		if item_id == "" or ItemCatalog.get_item(item_id).is_empty():
			continue
		var pickup := _make_pickup(item_id)
		pickup.name = "SpawnWeapon_%s" % item_id
		pickup.item_id = item_id
		var nice := str(entry.get("label", ItemCatalog.get_display_name(item_id)))
		pickup.prompt_text = "Plocka upp %s [E]" % nice
		pickup.one_shot = true
		var offset: Vector3 = entry.get("offset", Vector3.ZERO)
		pickup.position = Vector3(
			spawn_pos.x + offset.x,
			floor_y,
			spawn_pos.z + offset.z
		)
		root.add_child(pickup)

	var tip := Label3D.new()
	tip.text = "VAPEN PÅ MARKEN\nPlocka upp med [E] · Zombies i närheten"
	tip.font_size = 28
	tip.modulate = Color(0.95, 0.55, 0.28)
	tip.outline_modulate = Color(0.08, 0.04, 0.02, 0.95)
	tip.outline_size = 5
	tip.position = spawn_pos + Vector3(0.0, 2.4, 5.0)
	tip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(tip)

	return root


static func _make_pickup(item_id: String) -> ItemPickup:
	if item_id == "laserrifle":
		return LaserRiflePickupScript.new() as ItemPickup
	if ItemCatalog.is_weapon(item_id):
		return WeaponPickupScript.new() as ItemPickup
	return ItemPickupScript.new()
