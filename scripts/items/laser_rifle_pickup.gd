class_name LaserRiflePickup
extends WeaponPickup


func _build_visual() -> void:
	if ItemCatalog.get_item(item_id).is_empty():
		return

	var rarity := ItemCatalog.get_rarity(item_id)
	var color := ItemCatalog.rarity_color(rarity)
	var laser_cyan := Color(0.35, 0.92, 1.0)

	var pedestal := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.26
	mesh.height = 0.08
	pedestal.mesh = mesh
	pedestal.position = Vector3(0.0, 0.04, 0.0)
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.42, 0.22, 0.62)
	pedestal.material_override = ped_mat
	add_child(pedestal)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.52, 0.14, 0.18)
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.2, 0.0)
	body.rotation_degrees = Vector3(0.0, -25.0, 0.0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.22, 0.28)
	body_mat.metallic = 0.82
	body_mat.roughness = 0.25
	body.material_override = body_mat
	add_child(body)

	var stock := MeshInstance3D.new()
	var stock_mesh := BoxMesh.new()
	stock_mesh.size = Vector3(0.16, 0.1, 0.28)
	stock.mesh = stock_mesh
	stock.position = Vector3(0.18, 0.2, 0.08)
	stock.rotation_degrees = Vector3(0.0, -25.0, 0.0)
	stock.material_override = body_mat
	add_child(stock)

	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.03
	barrel_mesh.bottom_radius = 0.035
	barrel_mesh.height = 0.62
	barrel.mesh = barrel_mesh
	barrel.position = Vector3(-0.28, 0.22, -0.02)
	barrel.rotation_degrees = Vector3(0.0, -25.0, 90.0)
	var barrel_mat := StandardMaterial3D.new()
	barrel_mat.albedo_color = laser_cyan
	barrel_mat.emission_enabled = true
	barrel_mat.emission = laser_cyan
	barrel_mat.emission_energy_multiplier = 1.1
	barrel.material_override = barrel_mat
	add_child(barrel)

	var glow := MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(0.08, 0.05, 0.12)
	glow.mesh = glow_mesh
	glow.position = Vector3(-0.56, 0.22, -0.02)
	glow.rotation_degrees = Vector3(0.0, -25.0, 0.0)
	glow.material_override = barrel_mat
	add_child(glow)

	var label := Label3D.new()
	label.text = ItemCatalog.get_display_name(item_id)
	label.font_size = 24
	label.modulate = color
	label.position = Vector3(0.0, 0.62, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 1.2, 1.4)
	shape.shape = box
	shape.position = Vector3(0.0, 0.55, 0.0)
	add_child(shape)