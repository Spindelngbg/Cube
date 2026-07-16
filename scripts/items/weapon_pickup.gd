class_name WeaponPickup
extends ItemPickup


func _build_visual() -> void:
	if ItemCatalog.get_item(item_id).is_empty():
		return

	var rarity := ItemCatalog.get_rarity(item_id)
	var color := ItemCatalog.rarity_color(rarity)
	var slime_green := Color(0.18, 0.92, 0.28)

	var pedestal := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.26
	mesh.height = 0.08
	pedestal.mesh = mesh
	pedestal.position = Vector3(0.0, 0.04, 0.0)
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.14, 0.15, 0.18)
	pedestal.material_override = ped_mat
	add_child(pedestal)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.42, 0.16, 0.72)
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.22, 0.0)
	body.rotation_degrees = Vector3(0.0, 35.0, -8.0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.16, 0.2, 0.24)
	body_mat.metallic = 0.72
	body_mat.roughness = 0.28
	body.material_override = body_mat
	add_child(body)

	var tank := MeshInstance3D.new()
	var tank_mesh := CylinderMesh.new()
	tank_mesh.top_radius = 0.07
	tank_mesh.bottom_radius = 0.07
	tank_mesh.height = 0.34
	tank.mesh = tank_mesh
	tank.position = Vector3(-0.08, 0.28, -0.12)
	tank.rotation_degrees = Vector3(0.0, 35.0, 90.0)
	var tank_mat := StandardMaterial3D.new()
	tank_mat.albedo_color = slime_green
	tank_mat.emission_enabled = true
	tank_mat.emission = Color(0.3, 1.0, 0.36)
	tank_mat.emission_energy_multiplier = 0.85
	tank_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tank_mat.albedo_color.a = 0.88
	tank.material_override = tank_mat
	add_child(tank)

	var nozzle := MeshInstance3D.new()
	var nozzle_mesh := CylinderMesh.new()
	nozzle_mesh.top_radius = 0.04
	nozzle_mesh.bottom_radius = 0.05
	nozzle_mesh.height = 0.18
	nozzle.mesh = nozzle_mesh
	nozzle.position = Vector3(0.24, 0.24, 0.28)
	nozzle.rotation_degrees = Vector3(90.0, 35.0, 0.0)
	nozzle.material_override = body_mat
	add_child(nozzle)

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


func _on_collected() -> void:
	var item_name := ItemCatalog.get_display_name(item_id)
	WeaponManager.on_weapon_acquired(item_id, true)
	QuestManager.story_toast.emit(
		"Vapen upplockat",
		"%s utrustad.\nVänsterklick skjut | R ladda om" % item_name
	)
	if one_shot:
		visible = false
		monitoring = false
		monitorable = false