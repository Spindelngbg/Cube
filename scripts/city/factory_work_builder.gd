class_name FactoryWorkBuilder
extends RefCounted

## Industrikajens verkstadsfabrik — arbetsminigame med stationer.

const FACTORY_CELL := Vector2i(2, -3)

const StoryInteractableScript = preload("res://scripts/story/story_interactable.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")

const STEEL := Color(0.48, 0.52, 0.58)
const DARK := Color(0.16, 0.18, 0.22)
const RUST := Color(0.55, 0.32, 0.18)
const SAFETY := Color(0.95, 0.72, 0.12)
const GREEN_BTN := Color(0.25, 0.85, 0.38)
const RED_BTN := Color(0.92, 0.28, 0.22)
const BLUE_BTN := Color(0.28, 0.55, 0.95)
const ORANGE_BTN := Color(0.95, 0.48, 0.15)
const PURPLE_BTN := Color(0.68, 0.35, 0.92)
const WHITE := Color(0.9, 0.92, 0.95)


static func is_factory_cell(cell: Vector2i) -> bool:
	return cell == FACTORY_CELL


static func build(zone_root: Node3D, center: Vector3, cell: Vector2i = FACTORY_CELL) -> Node3D:
	FactoryWorkManager.clear_stations()

	var factory := Node3D.new()
	factory.name = "WorkFactory"
	factory.position = center
	factory.set_meta("work_factory", true)
	factory.set_meta("factory_cell", cell)
	zone_root.add_child(factory)

	_build_shell(factory)
	_build_signage(factory)
	_build_floor_markings(factory)
	_build_station(factory, "clock", Vector3(0.0, 0.0, 10.5), SAFETY, "STÄMPEL")
	_build_station(factory, "intake", Vector3(-10.0, 0.0, 4.0), ORANGE_BTN, "RÅGODS")
	_build_station(factory, "console", Vector3(-4.0, 0.0, -2.0), GREEN_BTN, "BAND")
	_build_station(factory, "press", Vector3(4.0, 0.0, -2.0), RED_BTN, "PRESS")
	_build_station(factory, "pack", Vector3(10.0, 0.0, 3.0), BLUE_BTN, "PACK")
	_build_station(factory, "load", Vector3(0.0, 0.0, -9.5), PURPLE_BTN, "LAST")
	_build_props(factory)
	_build_lighting(factory)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = "work_factory"
	marker.display_name = "Verkstadsfabrik"
	marker.category = "work"
	marker.keywords = PackedStringArray([
		"fabrik", "jobb", "arbete", "industrikaj", "verkstad", "lön", "skift"
	])
	marker.map_color = SAFETY
	factory.add_child(marker)

	DevBuildingLabelsScript.attach(
		zone_root,
		center,
		Vector3(14.0, 0.0, 12.0),
		0.0,
		factory
	)
	return factory


static func _build_shell(factory: Node3D) -> void:
	var half_w := 14.0
	var half_d := 12.0
	var wall_h := 7.5
	var thick := 0.4

	var slab := _box(Vector3(half_w * 2.0 + 2.0, 0.3, half_d * 2.0 + 2.0), DARK)
	slab.position = Vector3(0.0, -0.12, 0.0)
	factory.add_child(slab)
	WorldCollisionBuilderScript.attach_box(
		factory, Vector3(half_w * 2.0, 0.35, half_d * 2.0), Vector3(0.0, -0.08, 0.0)
	)

	# Bakvägg (-Z)
	var back := _box(Vector3(half_w * 2.0, wall_h, thick), STEEL)
	back.position = Vector3(0.0, wall_h * 0.5, -half_d)
	factory.add_child(back)
	WorldCollisionBuilderScript.attach_box(
		factory, Vector3(half_w * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -half_d)
	)

	# Sidor
	for side in [-1.0, 1.0]:
		var wall := _box(Vector3(thick, wall_h, half_d * 2.0), Color(0.42, 0.45, 0.5))
		wall.position = Vector3(half_w * side, wall_h * 0.5, 0.0)
		factory.add_child(wall)
		WorldCollisionBuilderScript.attach_box(
			factory,
			Vector3(thick, wall_h, half_d * 2.0),
			Vector3(half_w * side, wall_h * 0.5, 0.0)
		)

	# Front med entréöppning (+Z)
	var door_w := 5.0
	var door_h := 3.8
	var side_w := (half_w * 2.0 - door_w) * 0.5
	for side in [-1.0, 1.0]:
		var front := _box(Vector3(side_w, wall_h, thick), Color(0.5, 0.52, 0.56))
		front.position = Vector3(side * (door_w * 0.5 + side_w * 0.5), wall_h * 0.5, half_d)
		factory.add_child(front)
		WorldCollisionBuilderScript.attach_box(
			factory,
			Vector3(side_w, wall_h, thick),
			Vector3(side * (door_w * 0.5 + side_w * 0.5), wall_h * 0.5, half_d)
		)
	var lintel := _box(Vector3(door_w + 0.5, wall_h - door_h, thick), Color(0.55, 0.58, 0.62))
	lintel.position = Vector3(0.0, door_h + (wall_h - door_h) * 0.5, half_d)
	factory.add_child(lintel)
	WorldCollisionBuilderScript.attach_box(
		factory,
		Vector3(door_w + 0.5, wall_h - door_h, thick),
		Vector3(0.0, door_h + (wall_h - door_h) * 0.5, half_d)
	)

	# Takplåt (visuell)
	var roof := _box(Vector3(half_w * 2.0 + 1.2, 0.35, half_d * 2.0 + 1.2), Color(0.35, 0.38, 0.42))
	roof.position = Vector3(0.0, wall_h + 0.1, 0.0)
	factory.add_child(roof)

	# Skorsten
	var chimney := _box(Vector3(1.6, 4.5, 1.6), RUST)
	chimney.position = Vector3(-8.0, wall_h + 2.2, -6.0)
	factory.add_child(chimney)


static func _build_signage(factory: Node3D) -> void:
	var title := Label3D.new()
	title.text = "KOLONI 4 — VERKSTADS FABRIK"
	title.font_size = 42
	title.modulate = SAFETY
	title.outline_modulate = Color(0.05, 0.06, 0.08, 0.95)
	title.outline_size = 10
	title.position = Vector3(0.0, 6.2, 12.2)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	factory.add_child(title)

	var sub := Label3D.new()
	sub.text = "Skiftjobb • Lön i Mydrillium • Mänskliga kollegor"
	sub.font_size = 22
	sub.modulate = WHITE
	sub.outline_modulate = Color(0.05, 0.06, 0.08, 0.9)
	sub.outline_size = 6
	sub.position = Vector3(0.0, 5.5, 12.2)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	factory.add_child(sub)

	var flow := Label3D.new()
	flow.text = "FLÖDE:  STÄMPEL → RÅGODS → BAND → PRESS → PACK → LAST"
	flow.font_size = 18
	flow.modulate = Color(0.75, 0.9, 1.0)
	flow.position = Vector3(0.0, 3.8, 0.0)
	flow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	factory.add_child(flow)


static func _build_floor_markings(factory: Node3D) -> void:
	# Gula säkerhetslinjer som visar ungefärligt flöde.
	var path_pts: Array[Vector3] = [
		Vector3(0.0, 0.02, 9.0),
		Vector3(-10.0, 0.02, 4.0),
		Vector3(-4.0, 0.02, -2.0),
		Vector3(4.0, 0.02, -2.0),
		Vector3(10.0, 0.02, 3.0),
		Vector3(0.0, 0.02, -9.0),
	]
	for i in range(path_pts.size() - 1):
		var a: Vector3 = path_pts[i]
		var b: Vector3 = path_pts[i + 1]
		var mid := (a + b) * 0.5
		var dir := b - a
		var length := dir.length()
		var stripe := _box(Vector3(0.35, 0.04, length), SAFETY)
		stripe.position = mid
		stripe.rotation.y = atan2(dir.x, dir.z)
		factory.add_child(stripe)


static func _build_station(
	factory: Node3D,
	station_id: String,
	pos: Vector3,
	btn_color: Color,
	short_label: String
) -> void:
	var root := Node3D.new()
	root.name = "Station_%s" % station_id
	root.position = pos
	factory.add_child(root)

	# Sockel / maskinram
	var base := _box(Vector3(2.4, 0.9, 2.0), Color(0.28, 0.3, 0.34))
	base.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(base)
	WorldCollisionBuilderScript.attach_box(
		root, Vector3(2.4, 0.9, 2.0), Vector3(0.0, 0.45, 0.0)
	)

	var panel := _box(Vector3(1.6, 1.4, 0.25), Color(0.22, 0.24, 0.28))
	panel.position = Vector3(0.0, 1.5, -0.6)
	root.add_child(panel)

	# Stor knapphuvud
	var btn := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.32
	cyl.height = 0.22
	btn.mesh = cyl
	btn.position = Vector3(0.0, 1.55, -0.35)
	btn.rotation_degrees.x = 90.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = btn_color
	mat.emission_enabled = true
	mat.emission = btn_color
	mat.emission_energy_multiplier = 0.55
	btn.material_override = mat
	root.add_child(btn)

	# Extra detalj per station
	match station_id:
		"intake":
			var crate := _box(Vector3(1.1, 0.7, 0.9), RUST)
			crate.position = Vector3(0.0, 1.25, 0.55)
			root.add_child(crate)
		"console":
			var belt := _box(Vector3(3.5, 0.25, 0.9), Color(0.35, 0.38, 0.42))
			belt.position = Vector3(2.2, 0.9, 0.0)
			root.add_child(belt)
		"press":
			var ram := _box(Vector3(0.9, 1.2, 0.9), Color(0.55, 0.2, 0.18))
			ram.position = Vector3(0.0, 2.2, 0.2)
			root.add_child(ram)
		"pack":
			var table := _box(Vector3(2.0, 0.15, 1.2), Color(0.4, 0.32, 0.22))
			table.position = Vector3(0.0, 1.05, 0.7)
			root.add_child(table)
		"load":
			var pallet := _box(Vector3(2.2, 0.2, 1.6), Color(0.45, 0.35, 0.2))
			pallet.position = Vector3(0.0, 0.2, 1.2)
			root.add_child(pallet)
			var box_stack := _box(Vector3(1.0, 0.9, 0.9), Color(0.55, 0.5, 0.35))
			box_stack.position = Vector3(0.0, 0.75, 1.2)
			root.add_child(box_stack)
		"clock":
			var screen := _box(Vector3(1.0, 0.7, 0.08), Color(0.15, 0.55, 0.45))
			screen.position = Vector3(0.0, 1.7, -0.4)
			root.add_child(screen)

	var label := Label3D.new()
	label.text = short_label
	label.font_size = 28
	label.modulate = btn_color.lightened(0.25)
	label.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	label.outline_size = 6
	label.position = Vector3(0.0, 2.55, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	var area: StoryInteractable = StoryInteractableScript.new()
	area.name = "Interact"
	area.interact_id = "factory_%s" % station_id
	area.prompt_text = FactoryWorkManager.get_station_prompt(station_id)
	area.position = Vector3(0.0, 1.0, 0.4)
	root.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 2.4, 2.6)
	shape.shape = box
	area.add_child(shape)

	FactoryWorkManager.register_station(station_id, area)


static func _build_props(factory: Node3D) -> void:
	# Vilostolar / kaffebord för kollegor
	var break_table := _box(Vector3(1.8, 0.75, 1.0), Color(0.38, 0.28, 0.18))
	break_table.position = Vector3(-11.0, 0.4, -8.0)
	factory.add_child(break_table)
	for i in 3:
		var stool := _box(Vector3(0.45, 0.55, 0.45), Color(0.3, 0.32, 0.36))
		stool.position = Vector3(-10.0 + float(i) * 0.9, 0.3, -6.8)
		factory.add_child(stool)

	var locker := _box(Vector3(0.8, 2.2, 0.5), Color(0.35, 0.42, 0.55))
	locker.position = Vector3(12.0, 1.1, -8.0)
	factory.add_child(locker)

	var poster := Label3D.new()
	poster.text = "SÄKERHET FÖRST\n(sen kaffe)"
	poster.font_size = 18
	poster.modulate = SAFETY
	poster.position = Vector3(-13.2, 3.2, 0.0)
	poster.rotation_degrees.y = 90.0
	factory.add_child(poster)


static func _build_lighting(factory: Node3D) -> void:
	for x in [-6.0, 0.0, 6.0]:
		for z in [-4.0, 4.0]:
			var light := OmniLight3D.new()
			light.position = Vector3(x, 5.5, z)
			light.light_color = Color(1.0, 0.92, 0.75)
			light.light_energy = 1.15
			light.omni_range = 14.0
			light.shadow_enabled = false
			factory.add_child(light)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mi.material_override = mat
	return mi
