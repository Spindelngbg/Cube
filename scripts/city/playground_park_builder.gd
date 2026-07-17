class_name PlaygroundParkBuilder
extends RefCounted

## Ersätter hus nr 9 på Koloni 4 (Neo-Washington) med en jättestor lekpark.
const BUILDING_ID := 9
const BUILDING_9_CELL := Vector2i(-7, 4)

const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")

const GRASS := Color(0.28, 0.72, 0.32)
const SAND := Color(0.92, 0.82, 0.48)
const RUBBER := Color(0.18, 0.55, 0.42)
const STEEL := Color(0.55, 0.58, 0.62)
const WOOD := Color(0.55, 0.38, 0.22)
const RED := Color(0.92, 0.28, 0.22)
const BLUE := Color(0.22, 0.48, 0.95)
const YELLOW := Color(0.98, 0.82, 0.18)
const ORANGE := Color(0.98, 0.52, 0.12)
const PURPLE := Color(0.68, 0.32, 0.92)


static func is_building_9_cell(cell: Vector2i) -> bool:
	return cell == BUILDING_9_CELL


static func should_replace_next_building() -> bool:
	return DevBuildingLabelsScript.peek_next_id() == BUILDING_ID


static func build(zone_root: Node3D, center: Vector3, cell: Vector2i = BUILDING_9_CELL) -> Node3D:
	var park := Node3D.new()
	park.name = "PlaygroundPark_9"
	park.position = center
	park.set_meta("featured_building_id", BUILDING_ID)
	park.set_meta("playground_park", true)
	zone_root.add_child(park)

	_build_ground(park)
	_build_fence(park)
	_build_swing_set(park, Vector3(-10.0, 0.0, -8.0))
	_build_swing_set(park, Vector3(10.0, 0.0, -10.0))
	_build_slide_tower(park, Vector3(-8.0, 0.0, 6.0), RED)
	_build_slide_tower(park, Vector3(12.0, 0.0, 4.0), BLUE)
	_build_climbing_frame(park, Vector3(0.0, 0.0, -2.0))
	_build_carousel(park, Vector3(6.0, 0.0, 10.0))
	_build_sandbox(park, Vector3(-12.0, 0.0, 12.0))
	_build_seesaw(park, Vector3(2.0, 0.0, 14.0))
	_build_seesaw(park, Vector3(-4.0, 0.0, -14.0))
	_build_benches(park)
	_build_lights(park)
	_build_signage(park, cell)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = "playground_park_9"
	marker.display_name = "Jättelekpark"
	marker.category = "park"
	marker.keywords = PackedStringArray([
		"lekpark", "park", "lek", "playground", "gunga", "rutschkana", "hus 9",
		"barn", "väktare", "parkvakt", "vakt"
	])
	marker.map_color = Color(0.35, 0.9, 0.45)
	park.add_child(marker)

	# Behåll gul hus-etikett "9" så spelare hittar den.
	DevBuildingLabelsScript.attach(
		zone_root,
		center,
		Vector3(18.0, 0.0, 18.0),
		0.0,
		park
	)

	return park


static func _build_ground(park: Node3D) -> void:
	# Jättestor gräsmatta — nästan hela 40 m-blocket.
	var grass := _box(Vector3(36.0, 0.12, 36.0), GRASS)
	grass.position = Vector3(0.0, 0.06, 0.0)
	park.add_child(grass)

	var rubber_pad := _box(Vector3(22.0, 0.08, 18.0), RUBBER)
	rubber_pad.position = Vector3(0.0, 0.14, -1.0)
	park.add_child(rubber_pad)

	var path := _box(Vector3(4.0, 0.06, 34.0), Color(0.72, 0.7, 0.65))
	path.position = Vector3(0.0, 0.1, 0.0)
	park.add_child(path)

	var path_cross := _box(Vector3(34.0, 0.06, 3.5), Color(0.72, 0.7, 0.65))
	path_cross.position = Vector3(0.0, 0.1, 8.0)
	park.add_child(path_cross)


static func _build_fence(park: Node3D) -> void:
	var half := 17.5
	var posts := [
		Vector3(-half, 0.7, -half), Vector3(half, 0.7, -half),
		Vector3(-half, 0.7, half), Vector3(half, 0.7, half),
	]
	for p in posts:
		var post := _box(Vector3(0.18, 1.4, 0.18), STEEL)
		post.position = p
		park.add_child(post)

	for edge in [
		{"size": Vector3(half * 2.0, 0.08, 0.08), "pos": Vector3(0.0, 1.15, -half)},
		{"size": Vector3(half * 2.0, 0.08, 0.08), "pos": Vector3(0.0, 1.15, half)},
		{"size": Vector3(0.08, 0.08, half * 2.0), "pos": Vector3(-half, 1.15, 0.0)},
		{"size": Vector3(0.08, 0.08, half * 2.0), "pos": Vector3(half, 1.15, 0.0)},
		{"size": Vector3(half * 2.0, 0.08, 0.08), "pos": Vector3(0.0, 0.55, -half)},
		{"size": Vector3(half * 2.0, 0.08, 0.08), "pos": Vector3(0.0, 0.55, half)},
		{"size": Vector3(0.08, 0.08, half * 2.0), "pos": Vector3(-half, 0.55, 0.0)},
		{"size": Vector3(0.08, 0.08, half * 2.0), "pos": Vector3(half, 0.55, 0.0)},
	]:
		var rail := _box(edge.size, STEEL.lightened(0.1))
		rail.position = edge.pos
		park.add_child(rail)

	# Öppen entré söderut
	var gate_l := _box(Vector3(0.2, 1.5, 0.2), YELLOW)
	gate_l.position = Vector3(-2.2, 0.75, half)
	park.add_child(gate_l)
	var gate_r := _box(Vector3(0.2, 1.5, 0.2), YELLOW)
	gate_r.position = Vector3(2.2, 0.75, half)
	park.add_child(gate_r)


static func _build_swing_set(park: Node3D, origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "SwingSet"
	root.position = origin
	park.add_child(root)

	for side in [-1.0, 1.0]:
		var leg_a := _box(Vector3(0.12, 3.2, 0.12), STEEL)
		leg_a.position = Vector3(side * 2.4, 1.6, -0.9)
		leg_a.rotation_degrees = Vector3(12.0, 0.0, side * -8.0)
		root.add_child(leg_a)
		var leg_b := _box(Vector3(0.12, 3.2, 0.12), STEEL)
		leg_b.position = Vector3(side * 2.4, 1.6, 0.9)
		leg_b.rotation_degrees = Vector3(-12.0, 0.0, side * -8.0)
		root.add_child(leg_b)

	var top := _box(Vector3(5.2, 0.14, 0.14), STEEL)
	top.position = Vector3(0.0, 3.15, 0.0)
	root.add_child(top)

	for i in 3:
		var x := -1.5 + float(i) * 1.5
		var rope_l := _box(Vector3(0.04, 1.8, 0.04), Color(0.2, 0.2, 0.22))
		rope_l.position = Vector3(x - 0.2, 2.1, 0.0)
		root.add_child(rope_l)
		var rope_r := _box(Vector3(0.04, 1.8, 0.04), Color(0.2, 0.2, 0.22))
		rope_r.position = Vector3(x + 0.2, 2.1, 0.0)
		root.add_child(rope_r)
		var seat := _box(Vector3(0.55, 0.08, 0.28), [RED, BLUE, YELLOW][i])
		seat.position = Vector3(x, 1.15, 0.0)
		root.add_child(seat)

	WorldCollisionBuilderScript.attach_box(root, Vector3(5.5, 3.3, 2.2), Vector3(0.0, 1.65, 0.0))


static func _build_slide_tower(park: Node3D, origin: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.name = "SlideTower"
	root.position = origin
	park.add_child(root)

	var tower := _box(Vector3(2.4, 3.6, 2.4), color.darkened(0.15))
	tower.position = Vector3(0.0, 1.8, 0.0)
	root.add_child(tower)

	var platform := _box(Vector3(2.8, 0.18, 2.8), color.lightened(0.1))
	platform.position = Vector3(0.0, 3.65, 0.0)
	root.add_child(platform)

	var rail := _box(Vector3(2.6, 0.5, 0.1), STEEL)
	rail.position = Vector3(0.0, 4.0, -1.3)
	root.add_child(rail)

	# Rutschkana
	var chute := _box(Vector3(1.1, 0.2, 5.2), color)
	chute.position = Vector3(0.0, 2.0, 3.2)
	chute.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	root.add_child(chute)

	var side_l := _box(Vector3(0.12, 0.45, 5.0), color.darkened(0.25))
	side_l.position = Vector3(-0.55, 2.15, 3.2)
	side_l.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	root.add_child(side_l)
	var side_r := side_l.duplicate() as MeshInstance3D
	side_r.position.x = 0.55
	root.add_child(side_r)

	# Stege
	for i in 5:
		var step := _box(Vector3(0.9, 0.08, 0.25), WOOD)
		step.position = Vector3(0.0, 0.4 + float(i) * 0.55, -1.5)
		root.add_child(step)

	WorldCollisionBuilderScript.attach_box(root, Vector3(3.2, 4.2, 6.5), Vector3(0.0, 2.1, 1.5))


static func _build_climbing_frame(park: Node3D, origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "ClimbingFrame"
	root.position = origin
	park.add_child(root)

	for x in [-2.0, 0.0, 2.0]:
		for z in [-2.0, 0.0, 2.0]:
			var post := _box(Vector3(0.16, 3.0, 0.16), STEEL)
			post.position = Vector3(x, 1.5, z)
			root.add_child(post)

	for y in [1.0, 2.0, 2.9]:
		var bar_x := _box(Vector3(4.4, 0.1, 0.1), YELLOW)
		bar_x.position = Vector3(0.0, y, -2.0)
		root.add_child(bar_x)
		var bar_x2 := bar_x.duplicate() as MeshInstance3D
		bar_x2.position.z = 2.0
		root.add_child(bar_x2)
		var bar_z := _box(Vector3(0.1, 0.1, 4.4), ORANGE)
		bar_z.position = Vector3(-2.0, y, 0.0)
		root.add_child(bar_z)
		var bar_z2 := bar_z.duplicate() as MeshInstance3D
		bar_z2.position.x = 2.0
		root.add_child(bar_z2)

	# Hängande ringar
	for i in 4:
		var rope := _box(Vector3(0.05, 1.2, 0.05), Color(0.15, 0.15, 0.18))
		rope.position = Vector3(-1.2 + float(i) * 0.8, 2.2, 0.0)
		root.add_child(rope)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.12
		torus.outer_radius = 0.2
		ring.mesh = torus
		ring.position = Vector3(-1.2 + float(i) * 0.8, 1.55, 0.0)
		ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = PURPLE
		ring_mat.emission_enabled = true
		ring_mat.emission = PURPLE
		ring_mat.emission_energy_multiplier = 0.25
		ring.material_override = ring_mat
		root.add_child(ring)

	WorldCollisionBuilderScript.attach_box(root, Vector3(4.8, 3.2, 4.8), Vector3(0.0, 1.6, 0.0))


static func _build_carousel(park: Node3D, origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Carousel"
	root.position = origin
	park.add_child(root)

	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.6
	cyl.bottom_radius = 2.8
	cyl.height = 0.35
	base.mesh = cyl
	base.position = Vector3(0.0, 0.2, 0.0)
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = ORANGE
	base_mat.metallic = 0.3
	base.material_override = base_mat
	root.add_child(base)

	var pole := _box(Vector3(0.25, 1.8, 0.25), STEEL)
	pole.position = Vector3(0.0, 1.1, 0.0)
	root.add_child(pole)

	for i in 6:
		var angle := float(i) * TAU / 6.0
		var seat := _box(Vector3(0.55, 0.2, 0.45), Color.from_hsv(float(i) / 6.0, 0.75, 0.95))
		seat.position = Vector3(cos(angle) * 1.8, 0.55, sin(angle) * 1.8)
		root.add_child(seat)
		var handle := _box(Vector3(0.08, 0.7, 0.08), STEEL)
		handle.position = Vector3(cos(angle) * 1.5, 0.9, sin(angle) * 1.5)
		root.add_child(handle)

	WorldCollisionBuilderScript.attach_box(root, Vector3(5.6, 1.5, 5.6), Vector3(0.0, 0.75, 0.0))


static func _build_sandbox(park: Node3D, origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Sandbox"
	root.position = origin
	park.add_child(root)

	var frame := _box(Vector3(6.5, 0.45, 6.5), WOOD)
	frame.position = Vector3(0.0, 0.22, 0.0)
	root.add_child(frame)
	var sand := _box(Vector3(5.8, 0.35, 5.8), SAND)
	sand.position = Vector3(0.0, 0.28, 0.0)
	root.add_child(sand)

	var bucket := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.28
	bmesh.bottom_radius = 0.32
	bmesh.height = 0.4
	bucket.mesh = bmesh
	bucket.position = Vector3(1.2, 0.55, 0.8)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = RED
	bucket.material_override = bmat
	root.add_child(bucket)

	var shovel := _box(Vector3(0.08, 0.7, 0.12), YELLOW)
	shovel.position = Vector3(-1.0, 0.55, -0.6)
	shovel.rotation_degrees = Vector3(0.0, 0.0, 25.0)
	root.add_child(shovel)


static func _build_seesaw(park: Node3D, origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Seesaw"
	root.position = origin
	park.add_child(root)

	var fulcrum := _box(Vector3(0.5, 0.7, 0.5), STEEL)
	fulcrum.position = Vector3(0.0, 0.35, 0.0)
	root.add_child(fulcrum)

	var plank := _box(Vector3(5.5, 0.14, 0.45), WOOD)
	plank.position = Vector3(0.0, 0.85, 0.0)
	plank.rotation_degrees = Vector3(0.0, 0.0, -8.0)
	root.add_child(plank)

	for side in [-1.0, 1.0]:
		var seat := _box(Vector3(0.7, 0.12, 0.5), BLUE if side < 0.0 else RED)
		seat.position = Vector3(side * 2.3, 0.95 + side * 0.25, 0.0)
		root.add_child(seat)


static func _build_benches(park: Node3D) -> void:
	for pos in [
		Vector3(-15.0, 0.0, 0.0),
		Vector3(15.0, 0.0, 2.0),
		Vector3(-6.0, 0.0, 16.0),
		Vector3(8.0, 0.0, -15.0),
	]:
		var bench := Node3D.new()
		bench.position = pos
		park.add_child(bench)
		var seat := _box(Vector3(2.2, 0.12, 0.55), WOOD)
		seat.position = Vector3(0.0, 0.5, 0.0)
		bench.add_child(seat)
		var back := _box(Vector3(2.2, 0.55, 0.1), WOOD.darkened(0.1))
		back.position = Vector3(0.0, 0.85, -0.25)
		bench.add_child(back)
		for side in [-0.9, 0.9]:
			var leg := _box(Vector3(0.12, 0.5, 0.12), STEEL)
			leg.position = Vector3(side, 0.25, 0.15)
			bench.add_child(leg)


static func _build_lights(park: Node3D) -> void:
	for pos in [
		Vector3(-14.0, 0.0, -14.0),
		Vector3(14.0, 0.0, -14.0),
		Vector3(-14.0, 0.0, 14.0),
		Vector3(14.0, 0.0, 14.0),
		Vector3(0.0, 0.0, 0.0),
	]:
		var pole := _box(Vector3(0.15, 5.0, 0.15), STEEL)
		pole.position = pos + Vector3(0.0, 2.5, 0.0)
		park.add_child(pole)
		var light := OmniLight3D.new()
		light.position = pos + Vector3(0.0, 5.2, 0.0)
		light.light_color = Color(1.0, 0.95, 0.8)
		light.light_energy = 1.1
		light.omni_range = 16.0
		park.add_child(light)
		var lamp := _box(Vector3(0.4, 0.3, 0.4), YELLOW.lightened(0.2))
		lamp.position = pos + Vector3(0.0, 5.1, 0.0)
		var lamp_mat := lamp.material_override as StandardMaterial3D
		if lamp_mat:
			lamp_mat.emission_enabled = true
			lamp_mat.emission = YELLOW
			lamp_mat.emission_energy_multiplier = 0.6
		park.add_child(lamp)


static func _build_signage(park: Node3D, cell: Vector2i) -> void:
	var title := Label3D.new()
	title.text = "JÄTTELEKPARK\nHus 9 — Koloni 4"
	title.font_size = 42
	title.modulate = Color(0.95, 0.95, 0.55)
	title.outline_modulate = Color(0.08, 0.12, 0.08, 0.95)
	title.position = Vector3(0.0, 6.5, 16.5)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	park.add_child(title)

	var rules := Label3D.new()
	rules.text = "Gungor · Rutschkanor · Klätterställning\nKarusell · Sandlåda · Gungbräda"
	rules.font_size = 22
	rules.modulate = Color(0.85, 0.95, 0.8)
	rules.position = Vector3(0.0, 4.8, 16.5)
	rules.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	park.add_child(rules)

	var cell_note := Label3D.new()
	cell_note.text = "Rutnät %d, %d" % [cell.x, cell.y]
	cell_note.font_size = 18
	cell_note.modulate = Color(0.7, 0.85, 0.7)
	cell_note.position = Vector3(0.0, 3.8, 16.5)
	cell_note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	park.add_child(cell_note)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mesh_i.material_override = mat
	return mesh_i
