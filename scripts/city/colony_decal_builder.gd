class_name ColonyDecalBuilder
extends RefCounted

## Placerar speltrelaterade billboards, väggaffischer och golvdekaler i staden.

const ColonyDecalCatalogScript = preload("res://scripts/city/colony_decal_catalog.gd")
const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const POLE := Color(0.35, 0.38, 0.42)
const FRAME := Color(0.18, 0.2, 0.24)


static func decorate_city(city_root: Node3D) -> void:
	if city_root == null:
		return
	var root := Node3D.new()
	root.name = "ColonyDecals"
	city_root.add_child(root)

	_place_landmark_billboards(root)
	_place_zone_decals(root)
	_place_mall_banners(root)
	_place_spawn_plaza_set(root)


static func _place_landmark_billboards(root: Node3D) -> void:
	## Stora freestanding-skyltar vid kända punkter.
	var spots: Array = [
		{"cell": Vector2i(0, 0), "off": Vector3(10.0, 0.0, 14.0), "yaw": -0.4, "id": "neo_welcome", "kind": "billboard"},
		{"cell": Vector2i(0, 0), "off": Vector3(-12.0, 0.0, 8.0), "yaw": 0.9, "id": "znood_stamp", "kind": "billboard"},
		{"cell": Vector2i(-3, 0), "off": Vector3(8.0, 0.0, 10.0), "yaw": PI * 0.15, "id": "zezzlor_order", "kind": "billboard"},
		{"cell": Vector2i(-6, 0), "off": Vector3(6.0, 0.0, -8.0), "yaw": PI * 0.6, "id": "mydrillium", "kind": "billboard"},
		{"cell": Vector2i(-4, -3), "off": Vector3(16.0, 0.0, 18.0), "yaw": -0.7, "id": "src_redemption", "kind": "billboard"},
		{"cell": Vector2i(-4, -3), "off": Vector3(-10.0, 0.0, 20.0), "yaw": 1.1, "id": "src_warning", "kind": "poster_wall"},
		{"cell": Vector2i(2, -3), "off": Vector3(0.0, 0.0, 16.0), "yaw": PI, "id": "factory_job", "kind": "billboard"},
		{"cell": Vector2i(2, -3), "off": Vector3(-12.0, 0.0, 6.0), "yaw": 0.5, "id": "mydrillium", "kind": "poster_wall"},
		{"cell": Vector2i(-2, 3), "off": Vector3(4.0, 0.0, 4.0), "yaw": 0.2, "id": "playground", "kind": "billboard"},
		{"cell": Vector2i(1, 0), "off": Vector3(-6.0, 0.0, 12.0), "yaw": -1.2, "id": "mall_neon", "kind": "billboard"},
		{"cell": Vector2i(-1, 2), "off": Vector3(8.0, 0.0, -6.0), "yaw": 0.8, "id": "allmakare", "kind": "poster_wall"},
		{"cell": Vector2i(-5, 1), "off": Vector3(0.0, 0.0, 10.0), "yaw": PI * 0.3, "id": "zezzlor_checkpoint", "kind": "billboard"},
		{"cell": Vector2i(2, 2), "off": Vector3(5.0, 0.0, -5.0), "yaw": -0.5, "id": "criminal", "kind": "poster_wall"},
		{"cell": Vector2i(-2, -2), "off": Vector3(-8.0, 0.0, 8.0), "yaw": 1.4, "id": "slime_caution", "kind": "billboard"},
		{"cell": Vector2i(1, -2), "off": Vector3(10.0, 0.0, 0.0), "yaw": -PI * 0.5, "id": "gleazer", "kind": "poster_wall"},
		{"cell": Vector2i(-7, 4), "off": Vector3(0.0, 0.0, 0.0), "yaw": 0.0, "id": "playground", "kind": "billboard"},
	]
	for spot in spots:
		var cell: Vector2i = spot.cell
		var pos := _cell_center(cell) + (spot.off as Vector3)
		var decal := _decal_by_id(str(spot.id))
		if decal.is_empty():
			continue
		match str(spot.kind):
			"billboard":
				_spawn_billboard(root, pos, float(spot.yaw), decal, 1.0)
			"poster_wall":
				_spawn_wall_poster(root, pos, float(spot.yaw), decal, 1.05)
			_:
				_spawn_billboard(root, pos, float(spot.yaw), decal, 1.0)


static func _place_zone_decals(root: Node3D) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var count := 0
	var max_count := 28 if GlesPerformanceScript.is_active() else 55
	for x in range(extent.x_min, extent.x_max + 1):
		for z in range(extent.z_min, extent.z_max + 1):
			if count >= max_count:
				return
			var cell := Vector2i(x, z)
			if cell in DcZoneCatalog.mall_cells():
				continue
			var seed_v := hash("decal_%d_%d" % [x, z])
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_v
			## Inte varje block — glesare på GLES.
			var chance := 0.38 if GlesPerformanceScript.is_active() else 0.62
			if rng.randf() > chance:
				continue
			var spec: Dictionary = DcZoneCatalog.classify_cell(cell)
			var zone_type := str(spec.get("zone_type", ""))
			var kit := str(spec.get("kit", ""))
			if kit == "roads":
				continue
			var decal: Dictionary = ColonyDecalCatalogScript.pick_for_zone(zone_type, seed_v)
			var center := _cell_center(cell)
			var side := 1.0 if (x + z) % 2 == 0 else -1.0
			var yaw := float((x * 3 + z * 5) % 8) * PI * 0.25
			var kind_roll := rng.randf()
			if kind_roll < 0.35:
				var bb_pos := center + Vector3(side * 14.0, 0.0, rng.randf_range(-10.0, 10.0))
				_spawn_billboard(root, bb_pos, yaw, decal, rng.randf_range(0.85, 1.15))
			elif kind_roll < 0.75:
				var wall_pos := center + Vector3(
					rng.randf_range(-12.0, 12.0),
					0.0,
					side * 13.5
				)
				_spawn_wall_poster(root, wall_pos, yaw + PI * 0.5, decal, rng.randf_range(0.9, 1.2))
			else:
				var floor_pos := center + Vector3(rng.randf_range(-6.0, 6.0), 0.0, rng.randf_range(-6.0, 6.0))
				_spawn_floor_decal(root, floor_pos, yaw, decal, rng.randf_range(0.9, 1.3))
			count += 1


static func _place_mall_banners(root: Node3D) -> void:
	for cell in DcZoneCatalog.mall_cells():
		var center := _cell_center(cell)
		var seed_v := hash("mall_banner_%d" % cell.x)
		var decal: Dictionary = ColonyDecalCatalogScript.pick(seed_v + 17)
		## Banners längs mallens nordsida.
		_spawn_billboard(
			root,
			center + Vector3(-10.0, 0.0, 16.0),
			0.0,
			decal,
			1.2
		)
		var decal2: Dictionary = ColonyDecalCatalogScript.pick(seed_v + 91)
		_spawn_wall_poster(
			root,
			center + Vector3(12.0, 0.0, -14.0),
			PI,
			decal2,
			1.1
		)


static func _place_spawn_plaza_set(root: Node3D) -> void:
	var plaza := _cell_center(Vector2i(0, 0))
	var set_ids := ["neo_welcome", "znood_stamp", "zezzlor_order", "pharmacy", "spider_cube"]
	for i in set_ids.size():
		var decal := _decal_by_id(str(set_ids[i]))
		if decal.is_empty():
			continue
		var angle := float(i) / float(set_ids.size()) * TAU
		var pos := plaza + Vector3(cos(angle) * 18.0, 0.0, sin(angle) * 18.0)
		_spawn_billboard(root, pos, angle + PI, decal, 1.15)
	## Golvdekal mitt på plazan.
	var floor_decal := _decal_by_id("spider_cube")
	_spawn_floor_decal(root, plaza + Vector3(0.0, 0.0, 6.0), 0.0, floor_decal, 1.6)


static func _spawn_billboard(parent: Node3D, pos: Vector3, yaw: float, decal: Dictionary, scale: float) -> void:
	var root := Node3D.new()
	root.name = "Billboard_%s" % str(decal.get("id", "ad"))
	root.position = pos
	root.rotation.y = yaw
	parent.add_child(root)

	var post_h := 5.2 * scale
	var post := _box(Vector3(0.28 * scale, post_h, 0.28 * scale), POLE)
	post.position = Vector3(0.0, post_h * 0.5, 0.0)
	root.add_child(post)
	WorldCollisionBuilderScript.attach_box(
		root,
		Vector3(0.35 * scale, post_h, 0.35 * scale),
		Vector3(0.0, post_h * 0.5, 0.0)
	)

	var panel_w := 4.6 * scale
	var panel_h := 2.8 * scale
	var panel_y := post_h + panel_h * 0.35
	var frame := _box(Vector3(panel_w + 0.25, panel_h + 0.25, 0.18 * scale), FRAME)
	frame.position = Vector3(0.0, panel_y, 0.0)
	root.add_child(frame)

	var face := _make_face_mesh(panel_w, panel_h, decal)
	face.position = Vector3(0.0, panel_y, 0.1 * scale)
	root.add_child(face)

	_attach_labels(root, Vector3(0.0, panel_y, 0.14 * scale), decal, panel_w, panel_h, scale)

	## Svag neonlysning.
	if not GlesPerformanceScript.is_active():
		var lite := OmniLight3D.new()
		lite.position = Vector3(0.0, panel_y, 0.6 * scale)
		lite.light_color = (decal.get("accent", Color.WHITE) as Color)
		lite.light_energy = 0.55
		lite.omni_range = 8.0 * scale
		lite.shadow_enabled = false
		root.add_child(lite)


static func _spawn_wall_poster(parent: Node3D, pos: Vector3, yaw: float, decal: Dictionary, scale: float) -> void:
	var root := Node3D.new()
	root.name = "Poster_%s" % str(decal.get("id", "ad"))
	root.position = pos + Vector3(0.0, 2.4 * scale, 0.0)
	root.rotation.y = yaw
	parent.add_child(root)

	var w := 2.8 * scale
	var h := 3.4 * scale
	var back := _box(Vector3(w + 0.12, h + 0.12, 0.08), FRAME)
	root.add_child(back)
	var face := _make_face_mesh(w, h, decal)
	face.position = Vector3(0.0, 0.0, 0.05)
	root.add_child(face)
	_attach_labels(root, Vector3(0.0, 0.0, 0.08), decal, w, h, scale * 0.92)


static func _spawn_floor_decal(parent: Node3D, pos: Vector3, yaw: float, decal: Dictionary, scale: float) -> void:
	var root := Node3D.new()
	root.name = "FloorDecal_%s" % str(decal.get("id", "ad"))
	root.position = pos + Vector3(0.0, 0.04, 0.0)
	root.rotation.y = yaw
	parent.add_child(root)

	var size := 3.2 * scale
	var face := _make_face_mesh(size, size, decal)
	face.rotation_degrees.x = -90.0
	root.add_child(face)
	var stamp := Label3D.new()
	stamp.text = str(decal.get("title", ""))
	stamp.font_size = int(42 * scale)
	stamp.modulate = decal.get("accent", Color.WHITE) as Color
	stamp.outline_modulate = Color(0.02, 0.02, 0.04, 0.9)
	stamp.outline_size = 6
	stamp.position = Vector3(0.0, 0.06, 0.0)
	stamp.rotation_degrees.x = -90.0
	root.add_child(stamp)


static func _make_face_mesh(width: float, height: float, decal: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, 0.04)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	var bg: Color = decal.get("bg", Color(0.1, 0.1, 0.12)) as Color
	var accent: Color = decal.get("accent", Color(0.5, 0.7, 1.0)) as Color
	mat.albedo_color = bg
	mat.emission_enabled = true
	mat.emission = accent * 0.35
	mat.emission_energy_multiplier = 0.45
	mat.roughness = 0.55
	## Enkel “decal”-look med procedural gradient via albedo.
	mat.albedo_texture = _make_poster_texture(decal)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mi.material_override = mat
	return mi


static func _make_poster_texture(decal: Dictionary) -> ImageTexture:
	var img := Image.create(128, 160, false, Image.FORMAT_RGBA8)
	var bg: Color = decal.get("bg", Color(0.1, 0.1, 0.14)) as Color
	var accent: Color = decal.get("accent", Color(0.5, 0.8, 1.0)) as Color
	img.fill(bg)
	## Ram
	for x in 128:
		for y in 6:
			img.set_pixel(x, y, accent)
			img.set_pixel(x, 159 - y, accent)
	for y in 160:
		for x in 6:
			img.set_pixel(x, y, accent)
			img.set_pixel(127 - x, y, accent)
	## Övre band
	for y in range(18, 42):
		for x in range(10, 118):
			var t := float(y - 18) / 24.0
			img.set_pixel(x, y, accent.lerp(bg, t * 0.55))
	## Diagonal stripe
	for i in 90:
		var x := 20 + i
		var y := 70 + int(i * 0.55)
		if x >= 0 and x < 128 and y >= 0 and y < 160:
			img.set_pixel(x, y, accent.darkened(0.15))
			if x + 1 < 128:
				img.set_pixel(x + 1, y, accent.darkened(0.25))
	## Nedre block
	for y in range(120, 150):
		for x in range(14, 114):
			if (x + y) % 5 == 0:
				img.set_pixel(x, y, accent.darkened(0.4))
	var tex := ImageTexture.create_from_image(img)
	return tex


static func _attach_labels(
	parent: Node3D,
	center: Vector3,
	decal: Dictionary,
	panel_w: float,
	panel_h: float,
	scale: float
) -> void:
	var title := Label3D.new()
	title.text = str(decal.get("title", ""))
	title.font_size = int(clampi(int(52 * scale), 28, 72))
	title.modulate = decal.get("accent", Color.WHITE) as Color
	title.outline_modulate = Color(0.02, 0.03, 0.05, 0.95)
	title.outline_size = 8
	title.position = center + Vector3(0.0, panel_h * 0.22, 0.02)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(title)

	var body := Label3D.new()
	body.text = str(decal.get("body", ""))
	body.font_size = int(clampi(int(28 * scale), 16, 40))
	body.modulate = decal.get("text", Color.WHITE) as Color
	body.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	body.outline_size = 5
	body.position = center + Vector3(0.0, -panel_h * 0.05, 0.02)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(body)

	var tag := Label3D.new()
	tag.text = str(decal.get("tag", ""))
	tag.font_size = int(clampi(int(18 * scale), 12, 26))
	tag.modulate = (decal.get("accent", Color.WHITE) as Color).lightened(0.25)
	tag.outline_modulate = Color(0.02, 0.03, 0.05, 0.85)
	tag.outline_size = 4
	tag.position = center + Vector3(0.0, -panel_h * 0.32, 0.02)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(tag)


static func _decal_by_id(id: String) -> Dictionary:
	for d in ColonyDecalCatalogScript.DECALS:
		if str(d.get("id", "")) == id:
			return (d as Dictionary).duplicate(true)
	return {}


static func _cell_center(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalog.BLOCK_M + DcZoneCatalog.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalog.BLOCK_M + DcZoneCatalog.BLOCK_M * 0.5
	)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mi.material_override = mat
	return mi
