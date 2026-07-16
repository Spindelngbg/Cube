class_name ZoneOwnershipVisuals
extends RefCounted

const DcZoneOwnershipCatalogScript = preload("res://scripts/cube/dc_zone_ownership_catalog.gd")

const ZONE_SIZE := CubeConstants.PROTOTYPE_METERS_PER_ZONE
const PAD_HEIGHT := 0.07
const PAD_MARGIN := 0.35


static func build_marker(zone_entry: Dictionary, world_pos: Vector3, spawn_id: String) -> Node3D:
	var zone_id := str(zone_entry.get("zone_id", "unknown"))
	var owner := str(zone_entry.get("owner_account", ""))
	var source := str(zone_entry.get("purchase_source", "mydrillium"))
	var is_mine := Auth.is_logged_in and owner == Auth.username

	var root := Node3D.new()
	root.name = "ZoneMarker_%s" % zone_id
	root.position = world_pos
	root.set_meta("zone_id", zone_id)
	root.add_to_group("zone_ownership_marker")

	var colors := _colors_for_owner(source, is_mine)
	_add_floor_pad(root, colors)
	_add_corner_posts(root, colors)
	_add_border_frame(root, colors)
	_add_owner_label(root, zone_entry, colors, is_mine)
	_add_source_badge(root, source, colors)

	return root


static func update_marker(marker: Node3D, zone_entry: Dictionary) -> void:
	if marker == null:
		return
	var owner := str(zone_entry.get("owner_account", ""))
	var source := str(zone_entry.get("purchase_source", "mydrillium"))
	var is_mine := Auth.is_logged_in and owner == Auth.username
	var colors := _colors_for_owner(source, is_mine)

	for child in marker.get_children():
		if child is MeshInstance3D:
			child.material_override = _pad_material(colors)
		elif child is Label3D:
			if child.name == "OwnerLabel":
				child.text = _owner_label_text(zone_entry, is_mine)
				child.modulate = colors.label
			elif child.name == "SourceBadge":
				child.text = "NFT" if source == "nft" else "MYD"
				child.modulate = colors.accent


static func zone_id_to_world_position(zone_id: String, spawn_id: String) -> Vector3:
	var parsed := CubeZoneId.parse(zone_id)
	if parsed.is_empty():
		return Vector3.ZERO
	var block: Vector2i = parsed.get("block", Vector2i.ZERO)
	var zone: Vector2i = parsed.get("zone", Vector2i.ZERO)

	if SpawnPoints.normalize_id(spawn_id) == "satellite_right":
		var cell := block - CubeConstants.PROTOTYPE_BLOCK_ORIGIN + DcZoneOwnershipCatalogScript.DC_GRID_ORIGIN
		var local := Vector3(
			float(cell.x) * DcZoneCatalog.BLOCK_M + float(zone.x) * ZONE_SIZE + ZONE_SIZE * 0.5,
			PAD_HEIGHT * 0.5 + 0.02,
			float(cell.y) * DcZoneCatalog.BLOCK_M + float(zone.y) * ZONE_SIZE + ZONE_SIZE * 0.5
		)
		return SpawnPoints.get_position(spawn_id) + local

	var origin := CubeZoneId.prototype_origin_m(block, zone)
	return origin + Vector3(ZONE_SIZE * 0.5, PAD_HEIGHT * 0.5 + 0.02, ZONE_SIZE * 0.5)


static func _colors_for_owner(source: String, is_mine: bool) -> Dictionary:
	if source == "nft":
		return {
			"pad": Color(0.58, 0.28, 0.92, 0.34),
			"emission": Color(0.72, 0.38, 1.0),
			"accent": Color(0.82, 0.55, 1.0),
			"label": Color(0.9, 0.78, 1.0),
			"post": Color(0.45, 0.22, 0.78),
		}
	if is_mine:
		return {
			"pad": Color(0.95, 0.72, 0.18, 0.38),
			"emission": Color(1.0, 0.82, 0.28),
			"accent": Color(1.0, 0.9, 0.42),
			"label": Color(1.0, 0.92, 0.55),
			"post": Color(0.82, 0.58, 0.12),
		}
	return {
		"pad": Color(0.42, 0.58, 0.82, 0.3),
		"emission": Color(0.48, 0.68, 0.95),
		"accent": Color(0.62, 0.78, 0.98),
		"label": Color(0.78, 0.88, 1.0),
		"post": Color(0.28, 0.42, 0.68),
	}


static func _add_floor_pad(parent: Node3D, colors: Dictionary) -> void:
	var pad := MeshInstance3D.new()
	pad.name = "FloorPad"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(ZONE_SIZE - PAD_MARGIN, PAD_HEIGHT, ZONE_SIZE - PAD_MARGIN)
	pad.mesh = mesh
	pad.position = Vector3(0.0, 0.0, 0.0)
	pad.material_override = _pad_material(colors)
	parent.add_child(pad)


static func _pad_material(colors: Dictionary) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colors.pad
	mat.metallic = 0.22
	mat.roughness = 0.42
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = colors.emission
	mat.emission_energy_multiplier = 0.28
	return mat


static func _add_corner_posts(parent: Node3D, colors: Dictionary) -> void:
	var half := (ZONE_SIZE - PAD_MARGIN) * 0.5 - 0.2
	for offset in [
		Vector3(-half, 0.9, -half),
		Vector3(half, 0.9, -half),
		Vector3(-half, 0.9, half),
		Vector3(half, 0.9, half),
	]:
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.14, 1.8, 0.14)
		post.mesh = mesh
		post.position = offset
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors.post
		mat.emission_enabled = true
		mat.emission = colors.emission
		mat.emission_energy_multiplier = 0.35
		post.material_override = mat
		parent.add_child(post)


static func _add_border_frame(parent: Node3D, colors: Dictionary) -> void:
	var half := (ZONE_SIZE - PAD_MARGIN) * 0.5
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(colors.accent.r, colors.accent.g, colors.accent.b, 0.85)
	edge_mat.emission_enabled = true
	edge_mat.emission = colors.emission
	edge_mat.emission_energy_multiplier = 0.45

	for spec in [
		{"size": Vector3(ZONE_SIZE - PAD_MARGIN, 0.08, 0.1), "pos": Vector3(0.0, 0.12, -half)},
		{"size": Vector3(ZONE_SIZE - PAD_MARGIN, 0.08, 0.1), "pos": Vector3(0.0, 0.12, half)},
		{"size": Vector3(0.1, 0.08, ZONE_SIZE - PAD_MARGIN), "pos": Vector3(-half, 0.12, 0.0)},
		{"size": Vector3(0.1, 0.08, ZONE_SIZE - PAD_MARGIN), "pos": Vector3(half, 0.12, 0.0)},
	]:
		var edge := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = spec.size
		edge.mesh = mesh
		edge.position = spec.pos
		edge.material_override = edge_mat
		parent.add_child(edge)


static func _add_owner_label(parent: Node3D, zone_entry: Dictionary, colors: Dictionary, is_mine: bool) -> void:
	var label := Label3D.new()
	label.name = "OwnerLabel"
	label.text = _owner_label_text(zone_entry, is_mine)
	label.font_size = 22
	label.modulate = colors.label
	label.outline_modulate = Color(0.05, 0.06, 0.1, 0.95)
	label.position = Vector3(0.0, 2.15, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _owner_label_text(zone_entry: Dictionary, is_mine: bool) -> String:
	var zone_id := str(zone_entry.get("zone_id", ""))
	var display := DcZoneOwnershipCatalogScript.get_zone_display_name(zone_id, zone_entry)
	if is_mine:
		return "DIN ZON\n%s" % display
	var owner := str(zone_entry.get("owner_account", "?"))
	return "ÄGD\n%s\n%s" % [display, owner]


static func _add_source_badge(parent: Node3D, source: String, colors: Dictionary) -> void:
	var badge := Label3D.new()
	badge.name = "SourceBadge"
	badge.text = "NFT" if source == "nft" else "MYD"
	badge.font_size = 16
	badge.modulate = colors.accent
	badge.position = Vector3(0.0, 1.35, 0.0)
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(badge)