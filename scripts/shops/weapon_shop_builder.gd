class_name WeaponShopBuilder
extends RefCounted

const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WeaponShopScript = preload("res://scripts/shops/weapon_shop.gd")
const WeaponShopOwnerScript = preload("res://scripts/shops/weapon_shop_owner.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const STEEL := Color(0.62, 0.66, 0.72)
const ACCENT := Color(0.9, 0.35, 0.22)
const WOOD := Color(0.28, 0.22, 0.18)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "weapon_shop") -> Node3D:
	return build_kiosk(parent, pos, poi_id)


## Pytteliten kiosk vid spawn — full arsenal i dialog trots liten yta.
static func build_kiosk(parent: Node3D, pos: Vector3, poi_id: String = "weapon_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "WeaponShopKiosk"
	shop.position = pos
	parent.add_child(shop)

	# Liten bås-kropp (~3.4 × 2.6 × 2.8 m).
	var shell := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.4, 2.55, 2.8)
	shell.mesh = mesh
	shell.position = Vector3(0.0, 1.28, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = STEEL.darkened(0.08)
	mat.metallic = 0.62
	mat.roughness = 0.4
	shell.material_override = mat
	shop.add_child(shell)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(3.4, 2.55, 2.8), Vector3(0.0, 1.28, 0.0))

	var awning := MeshInstance3D.new()
	var awning_mesh := BoxMesh.new()
	awning_mesh.size = Vector3(3.7, 0.12, 1.4)
	awning.mesh = awning_mesh
	awning.position = Vector3(0.0, 2.65, 0.9)
	var awning_mat := StandardMaterial3D.new()
	awning_mat.albedo_color = ACCENT
	awning_mat.roughness = 0.55
	awning.material_override = awning_mat
	shop.add_child(awning)

	var sign := Label3D.new()
	sign.text = "VAPEN"
	sign.font_size = 36
	sign.modulate = ACCENT.lightened(0.1)
	sign.outline_modulate = Color(0.08, 0.08, 0.1, 0.95)
	sign.position = Vector3(0.0, 3.15, 0.55)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sign)

	var sub := Label3D.new()
	sub.text = "Stort arsenal · litet bås"
	sub.font_size = 18
	sub.modulate = Color(0.9, 0.75, 0.65)
	sub.position = Vector3(0.0, 2.85, 0.55)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sub)

	_build_kiosk_rack(shop)
	_build_kiosk_counter(shop)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 2.9, 0.4)
	light.light_color = ACCENT
	light.light_energy = 0.85
	light.omni_range = 9.0
	shop.add_child(light)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = poi_id
	marker.display_name = "Vapenbås"
	marker.category = "vapenbutik"
	marker.keywords = PackedStringArray([
		"vapen", "weapon", "butik", "bås", "kiosk", "ammo", "gevär", "kniv", "stål-sven", "arsenal"
	])
	marker.map_color = ACCENT
	shop.add_child(marker)

	var shop_area: WeaponShop = WeaponShopScript.new()
	shop_area.name = "ShopArea"
	shop_area.area_size = Vector3(4.2, 3.0, 3.6)
	shop_area.area_offset = Vector3(0.0, 1.3, 0.4)
	shop.add_child(shop_area)

	var owner: WeaponShopOwner = WeaponShopOwnerScript.new()
	owner.name = "ShopOwner"
	owner.position = Vector3(0.0, 0.0, -0.35)
	owner.compact_mode = true
	shop.add_child(owner)

	return shop


static func build_large(parent: Node3D, pos: Vector3, poi_id: String = "weapon_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "WeaponShop"
	shop.position = pos
	parent.add_child(shop)

	var shell := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(12.0, 4.5, 7.0)
	shell.mesh = mesh
	shell.position = Vector3(0.0, 2.25, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = STEEL
	mat.metallic = 0.55
	mat.roughness = 0.42
	shell.material_override = mat
	shop.add_child(shell)
	WorldCollisionBuilderScript.attach_box(shop, Vector3(12.0, 4.5, 7.0), Vector3(0.0, 2.25, 0.0))

	var sign := Label3D.new()
	sign.text = "VAPENBUTIK"
	sign.font_size = 42
	sign.modulate = ACCENT
	sign.outline_modulate = Color(0.08, 0.08, 0.1, 0.95)
	sign.position = Vector3(0.0, 5.4, -3.8)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sign)

	_build_weapon_walls(shop)
	_build_counter(shop)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 5.2, 0.0)
	light.light_color = ACCENT
	light.light_energy = 1.0
	light.omni_range = 18.0
	shop.add_child(light)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = poi_id
	marker.display_name = "Vapenbutik"
	marker.category = "vapenbutik"
	marker.keywords = PackedStringArray(["vapen", "weapon", "butik", "ammo", "gevär", "kniv", "stål-sven"])
	marker.map_color = ACCENT
	shop.add_child(marker)

	var shop_area: WeaponShop = WeaponShopScript.new()
	shop_area.name = "ShopArea"
	shop.add_child(shop_area)

	var owner: WeaponShopOwner = WeaponShopOwnerScript.new()
	owner.name = "ShopOwner"
	owner.position = Vector3(0.0, 0.0, -1.8)
	shop.add_child(owner)

	return shop


static func _build_kiosk_counter(shop: Node3D) -> void:
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(2.6, 0.85, 0.7)
	desk.mesh = desk_mesh
	desk.position = Vector3(0.0, 0.42, 0.55)
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = WOOD
	desk_mat.roughness = 0.68
	desk.material_override = desk_mat
	shop.add_child(desk)


static func _build_kiosk_rack(shop: Node3D) -> void:
	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(3.0, 1.5, 0.08)
	board.mesh = board_mesh
	board.position = Vector3(0.0, 1.7, -1.2)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.16, 0.18, 0.22)
	board.material_override = board_mat
	shop.add_child(board)

	var all_ids := WeaponCatalog.all_shop_weapon_ids()
	var cols := 6
	for i in range(all_ids.size()):
		var col := i % cols
		var row := int(i / cols)
		_mount_weapon_visual(
			shop,
			all_ids[i],
			Vector3(-1.15 + float(col) * 0.42, 1.2 + float(row) * 0.38, -1.1),
			Vector3(0.0, 0.0, 0.0),
			true
		)


static func _build_counter(shop: Node3D) -> void:
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(4.2, 1.05, 1.35)
	desk.mesh = desk_mesh
	desk.position = Vector3(0.0, 0.52, -2.2)
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = WOOD
	desk_mat.roughness = 0.68
	desk.material_override = desk_mat
	shop.add_child(desk)


static func _build_weapon_walls(shop: Node3D) -> void:
	var pegboard := MeshInstance3D.new()
	var peg_mesh := BoxMesh.new()
	peg_mesh.size = Vector3(0.08, 3.2, 5.8)
	pegboard.mesh = peg_mesh
	pegboard.position = Vector3(-5.7, 2.4, 0.0)
	var peg_mat := StandardMaterial3D.new()
	peg_mat.albedo_color = Color(0.18, 0.2, 0.24)
	pegboard.material_override = peg_mat
	shop.add_child(pegboard)

	var pegboard_right := pegboard.duplicate() as MeshInstance3D
	pegboard_right.position = Vector3(5.7, 2.4, 0.0)
	shop.add_child(pegboard_right)

	var ranged := WeaponCatalog.SHOP_RANGED
	for i in range(ranged.size()):
		_mount_weapon_visual(
			shop,
			ranged[i],
			Vector3(-5.55, 1.6 + float(i % 3) * 0.95, -2.0 + float(i) * 0.95),
			Vector3(0.0, 0.0, 90.0)
		)

	var melee := WeaponCatalog.SHOP_MELEE
	for i in range(melee.size()):
		_mount_weapon_visual(
			shop,
			melee[i],
			Vector3(5.55, 1.55 + float(i % 3) * 0.9, -2.0 + float(i) * 0.95),
			Vector3(0.0, 0.0, -90.0)
		)


static func _mount_weapon_visual(
	shop: Node3D,
	weapon_id: String,
	pos: Vector3,
	rot_deg: Vector3,
	compact: bool = false
) -> void:
	var mount := Node3D.new()
	mount.name = "Wall_%s" % weapon_id
	mount.position = pos
	mount.rotation_degrees = rot_deg
	if compact:
		mount.scale = Vector3(0.55, 0.55, 0.55)
	shop.add_child(mount)

	var style := WeaponCatalog.get_display_style(weapon_id)
	var color: Color = WeaponCatalog.get_stats(weapon_id).get("color", Color.GRAY)
	var body: MeshInstance3D

	if style.begins_with("knife") or style.begins_with("axe"):
		body = _knife_mesh(style)
	else:
		body = _gun_mesh(style)

	if body != null:
		var body_mat := StandardMaterial3D.new()
		body_mat.albedo_color = (
			color.darkened(0.35)
			if style.begins_with("knife") or style.begins_with("axe")
			else Color(0.16, 0.18, 0.22)
		)
		body_mat.metallic = 0.75
		body_mat.roughness = 0.32
		if not style.begins_with("knife") and not style.begins_with("axe"):
			var accent := MeshInstance3D.new()
			var accent_mesh := BoxMesh.new()
			accent_mesh.size = Vector3(0.08, 0.08, 0.35)
			accent.mesh = accent_mesh
			accent.position = Vector3(0.0, 0.04, -0.22)
			var accent_mat := StandardMaterial3D.new()
			accent_mat.albedo_color = color
			accent_mat.emission_enabled = true
			accent_mat.emission = color
			accent_mat.emission_energy_multiplier = 0.55
			accent.material_override = accent_mat
			mount.add_child(accent)
		body.material_override = body_mat
		mount.add_child(body)

	if not compact:
		var hook := MeshInstance3D.new()
		var hook_mesh := BoxMesh.new()
		hook_mesh.size = Vector3(0.06, 0.04, 0.12)
		hook.mesh = hook_mesh
		hook.position = Vector3(0.0, 0.22, 0.08)
		var hook_mat := StandardMaterial3D.new()
		hook_mat.albedo_color = Color(0.45, 0.48, 0.52)
		hook_mat.metallic = 0.9
		hook.material_override = hook_mat
		mount.add_child(hook)

		var label := Label3D.new()
		label.text = ItemCatalog.get_display_name(weapon_id)
		label.font_size = 16
		label.modulate = ItemCatalog.rarity_color(ItemCatalog.get_rarity(weapon_id))
		label.position = Vector3(0.0, -0.28, 0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mount.add_child(label)
	else:
		var tip := MeshInstance3D.new()
		var tip_mesh := BoxMesh.new()
		tip_mesh.size = Vector3(0.12, 0.12, 0.12)
		tip.mesh = tip_mesh
		tip.position = Vector3(0.0, -0.18, 0.0)
		var tip_mat := StandardMaterial3D.new()
		tip_mat.albedo_color = color
		tip_mat.emission_enabled = true
		tip_mat.emission = color
		tip_mat.emission_energy_multiplier = 0.4
		tip.material_override = tip_mat
		mount.add_child(tip)


static func _gun_mesh(style: String) -> MeshInstance3D:
	var gun := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	match style:
		"melt_cannon":
			mesh.size = Vector3(0.55, 0.22, 0.18)
		"corrosion_rifle":
			mesh.size = Vector3(0.62, 0.16, 0.14)
		"plasma_smg":
			mesh.size = Vector3(0.42, 0.14, 0.12)
		"volt_rifle":
			mesh.size = Vector3(0.58, 0.15, 0.13)
		"neon_pistol":
			mesh.size = Vector3(0.28, 0.12, 0.1)
		"laser_rifle":
			mesh.size = Vector3(0.5, 0.14, 0.12)
		_:
			mesh.size = Vector3(0.38, 0.14, 0.11)
	gun.mesh = mesh
	return gun


static func _knife_mesh(style: String) -> MeshInstance3D:
	var knife := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	match style:
		"axe_survival":
			mesh.size = Vector3(0.08, 0.24, 0.2)
		"knife_cleaver":
			mesh.size = Vector3(0.06, 0.22, 0.18)
		"knife_sword":
			mesh.size = Vector3(0.05, 0.28, 0.08)
		"knife_legendary":
			mesh.size = Vector3(0.05, 0.24, 0.1)
		"knife_stiletto":
			mesh.size = Vector3(0.03, 0.2, 0.05)
		_:
			mesh.size = Vector3(0.04, 0.16, 0.06)
	knife.mesh = mesh
	return knife