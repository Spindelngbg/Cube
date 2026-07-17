class_name CuteCottageBuilder
extends RefCounted

## Små söta pastellhus med trädgård, staket och skorsten.

const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const FurnitureKitLibraryScript = preload("res://scripts/assets/furniture_kit_library.gd")
const BuildingAmbianceLightsScript = preload("res://scripts/city/building_ambiance_lights.gd")
const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")

const PASTELS := [
	Color(1.0, 0.78, 0.82), # rosa
	Color(0.78, 0.9, 1.0), # babyblå
	Color(0.85, 0.95, 0.78), # mint
	Color(1.0, 0.92, 0.72), # crème
	Color(0.9, 0.82, 1.0), # lila
	Color(1.0, 0.85, 0.7), # persika
]

const ROOF_COLORS := [
	Color(0.55, 0.28, 0.32),
	Color(0.35, 0.42, 0.55),
	Color(0.4, 0.55, 0.38),
	Color(0.5, 0.38, 0.28),
]


static func should_spawn_cute(cell: Vector2i, zone_type: String, kit: String) -> bool:
	# Främst bostad / ambassad / norra grid — ibland.
	var residential := zone_type in ["BOSTADSKVARTER", "AMBASSADNÄSET", "PARKBÄLTE"]
	var suburban := kit == "suburban"
	if not residential and not suburban:
		# Lite chans även på lugna kontorshörn.
		if zone_type != "KONTORSGRID":
			return false
	var h: int = absi(hash(Vector3i(cell.x, cell.y, 912))) % 100
	if GlesPerformanceScript.is_active():
		return h < 22
	return h < 38


static func build(zone_root: Node3D, center: Vector3, cell: Vector2i, rotation_y: float = 0.0) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, 404))

	var house := Node3D.new()
	house.name = "CuteCottage"
	house.position = center
	house.rotation.y = rotation_y
	house.set_meta("cute_cottage", true)
	zone_root.add_child(house)

	var body_col: Color = PASTELS[rng.randi() % PASTELS.size()]
	var roof_col: Color = ROOF_COLORS[rng.randi() % ROOF_COLORS.size()]
	var trim := Color(1.0, 0.98, 0.94)

	var w := rng.randf_range(5.2, 7.0)
	var d := rng.randf_range(4.8, 6.2)
	var h := rng.randf_range(2.8, 3.6)

	# Grund / gräsmatta
	var lawn := _box(Vector3(w + 4.5, 0.08, d + 4.0), Color(0.42, 0.72, 0.38))
	lawn.position = Vector3(0.0, 0.04, 0.0)
	house.add_child(lawn)

	# Stig till dörr
	var path := _box(Vector3(1.1, 0.06, d * 0.55), Color(0.72, 0.65, 0.52))
	path.position = Vector3(0.0, 0.08, d * 0.35)
	house.add_child(path)

	# Hus kropp
	var body := _box(Vector3(w, h, d), body_col)
	body.position = Vector3(0.0, h * 0.5 + 0.08, 0.0)
	house.add_child(body)
	WorldCollisionBuilderScript.attach_box(house, Vector3(w, h, d), Vector3(0.0, h * 0.5 + 0.08, 0.0))

	# Tak (enkelt sadeltak-look: två snedställda paneler)
	var roof_h := 1.6
	var left_roof := _box(Vector3(w * 0.55, 0.18, d + 0.5), roof_col)
	left_roof.position = Vector3(-w * 0.22, h + 0.7, 0.0)
	left_roof.rotation_degrees = Vector3(0.0, 0.0, 28.0)
	house.add_child(left_roof)
	var right_roof := _box(Vector3(w * 0.55, 0.18, d + 0.5), roof_col.darkened(0.06))
	right_roof.position = Vector3(w * 0.22, h + 0.7, 0.0)
	right_roof.rotation_degrees = Vector3(0.0, 0.0, -28.0)
	house.add_child(right_roof)

	# Skorsten
	var chimney := _box(Vector3(0.55, 1.4, 0.55), Color(0.55, 0.32, 0.28))
	chimney.position = Vector3(w * 0.28, h + 1.35, -d * 0.15)
	house.add_child(chimney)
	var smoke := _box(Vector3(0.35, 0.25, 0.35), Color(0.85, 0.85, 0.88, 0.45))
	smoke.position = Vector3(w * 0.28, h + 2.15, -d * 0.15)
	var smoke_mat := smoke.material_override as StandardMaterial3D
	if smoke_mat:
		smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	house.add_child(smoke)

	# Dörr
	var door := _box(Vector3(1.05, 1.85, 0.12), Color(0.45, 0.28, 0.2))
	door.position = Vector3(0.0, 1.0, d * 0.5 + 0.05)
	house.add_child(door)
	var knob := _box(Vector3(0.08, 0.08, 0.08), Color(0.95, 0.8, 0.3))
	knob.position = Vector3(0.32, 0.95, d * 0.5 + 0.12)
	house.add_child(knob)

	# Fönster
	for wx in [-w * 0.28, w * 0.28]:
		var win := _box(Vector3(0.95, 0.95, 0.08), Color(0.55, 0.8, 0.95, 0.65))
		win.position = Vector3(wx, h * 0.55, d * 0.5 + 0.06)
		var wm := win.material_override as StandardMaterial3D
		if wm:
			wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wm.emission_enabled = true
			wm.emission = Color(1.0, 0.92, 0.55)
			wm.emission_energy_multiplier = 0.35
		house.add_child(win)
		var frame := _box(Vector3(1.1, 1.1, 0.06), trim)
		frame.position = Vector3(wx, h * 0.55, d * 0.5 + 0.02)
		house.add_child(frame)

	# Sido-fönster
	var side_win := _box(Vector3(0.08, 0.85, 0.85), Color(0.55, 0.8, 0.95, 0.55))
	side_win.position = Vector3(w * 0.5 + 0.05, h * 0.55, 0.0)
	house.add_child(side_win)

	# Veranda / trappa
	var step := _box(Vector3(1.6, 0.18, 0.55), Color(0.75, 0.68, 0.55))
	step.position = Vector3(0.0, 0.2, d * 0.5 + 0.45)
	house.add_child(step)

	# Staket (lågt, sött)
	_build_fence(house, w + 3.2, d + 2.8, Color(0.95, 0.9, 0.85))

	# Blommor / krukor
	if not GlesPerformanceScript.is_active() or rng.randf() > 0.4:
		var plant_ids: Array[String] = ["pottedPlant", "plantSmall1", "plantSmall2", "plantSmall3"]
		for i in 3:
			var plant_id: String = plant_ids[i % plant_ids.size()]
			var pot := FurnitureKitLibraryScript.spawn(
				house,
				plant_id,
				Vector3(-1.6 + float(i) * 1.5, 0.1, d * 0.45 + 1.1),
				rng.randf() * 0.5
			)
			if pot:
				pot.scale = Vector3.ONE * rng.randf_range(1.1, 1.5)

	# Söt skylt
	var names := ["Lilla Bo", "Mysbo", "Rosenstuga", "Solkullen", "Nallebo", "Mintstugan", "Pinkis"]
	var label := Label3D.new()
	label.text = names[rng.randi() % names.size()]
	label.font_size = 22
	label.modulate = body_col.lightened(0.15)
	label.outline_modulate = Color(0.15, 0.1, 0.12, 0.9)
	label.position = Vector3(0.0, h + 2.2, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	house.add_child(label)

	# Mysig fasadlykta
	BuildingAmbianceLightsScript.decorate_building(
		house,
		Vector3.ZERO,
		0.0,
		maxf(w, d) * 0.9,
		Color(1.0, 0.85, 0.5)
	)

	return house


static func _build_fence(parent: Node3D, width: float, depth: float, color: Color) -> void:
	var half_w := width * 0.5
	var half_d := depth * 0.5
	var h := 0.85
	# Tre sidor, öppning fram
	for side in [
		{"size": Vector3(width, h, 0.08), "pos": Vector3(0.0, h * 0.5, -half_d)},
		{"size": Vector3(0.08, h, depth), "pos": Vector3(-half_w, h * 0.5, 0.0)},
		{"size": Vector3(0.08, h, depth), "pos": Vector3(half_w, h * 0.5, 0.0)},
	]:
		var rail := _box(side.size, color)
		rail.position = side.pos
		parent.add_child(rail)
	# Fram med gap för stig
	for x_side in [-1.0, 1.0]:
		var front := _box(Vector3(width * 0.32, h, 0.08), color)
		front.position = Vector3(x_side * (width * 0.28), h * 0.5, half_d)
		parent.add_child(front)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.15
	else:
		mat.roughness = 0.72
	mi.material_override = mat
	return mi
