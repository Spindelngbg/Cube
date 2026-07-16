class_name WeaponShopBuilder
extends RefCounted

const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WeaponShopScript = preload("res://scripts/shops/weapon_shop.gd")
const WeaponPickupScript = preload("res://scripts/items/weapon_pickup.gd")

const STEEL := Color(0.62, 0.66, 0.72)
const ACCENT := Color(0.9, 0.35, 0.22)


static func build(parent: Node3D, pos: Vector3, poi_id: String = "weapon_shop") -> Node3D:
	var shop := Node3D.new()
	shop.name = "WeaponShop"
	shop.position = pos
	parent.add_child(shop)

	var shell := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(8.0, 4.0, 6.0)
	shell.mesh = mesh
	shell.position = Vector3(0.0, 2.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = STEEL
	mat.metallic = 0.55
	mat.roughness = 0.42
	shell.material_override = mat
	shop.add_child(shell)

	var sign := Label3D.new()
	sign.text = "VAPENBUTIK"
	sign.font_size = 42
	sign.modulate = ACCENT
	sign.outline_modulate = Color(0.08, 0.08, 0.1, 0.95)
	sign.position = Vector3(0.0, 5.2, -3.4)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shop.add_child(sign)

	var rifle := MeshInstance3D.new()
	var rifle_mesh := BoxMesh.new()
	rifle_mesh.size = Vector3(2.4, 0.18, 0.35)
	rifle.mesh = rifle_mesh
	rifle.position = Vector3(0.0, 3.2, -2.8)
	var rifle_mat := StandardMaterial3D.new()
	rifle_mat.albedo_color = Color(0.18, 0.2, 0.24)
	rifle_mat.metallic = 0.8
	rifle.material_override = rifle_mat
	shop.add_child(rifle)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 5.0, 0.0)
	light.light_color = ACCENT
	light.light_energy = 0.9
	light.omni_range = 16.0
	shop.add_child(light)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = poi_id
	marker.display_name = "Vapenbutik"
	marker.category = "vapenbutik"
	marker.keywords = PackedStringArray(["vapen", "weapon", "butik", "ammo", "gevär"])
	marker.map_color = ACCENT
	shop.add_child(marker)

	var shop_area: WeaponShop = WeaponShopScript.new()
	shop_area.name = "ShopArea"
	shop.add_child(shop_area)

	var pickup: WeaponPickup = WeaponPickupScript.new()
	pickup.name = "SlimeshooterPickup"
	pickup.item_id = "slimeshooter"
	pickup.prompt_text = "Plocka upp Slimeshooter [E]"
	pickup.position = Vector3(4.2, 0.0, 2.4)
	shop.add_child(pickup)

	return shop