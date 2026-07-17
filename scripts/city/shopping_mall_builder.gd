class_name ShoppingMallBuilder
extends RefCounted

## Byggnad 12 (gul etikett) → shoppingcenter med Znood-dörr och jonglör.

const BUILDING_ID := 12
const ZnoodDoorBuilderScript = preload("res://scripts/access/znood_door_builder.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const FurnitureKitLibraryScript = preload("res://scripts/assets/furniture_kit_library.gd")
const CharacterKitLibraryScript = preload("res://scripts/assets/character_kit_library.gd")
const JugglerBallAnimScript = preload("res://scripts/city/juggler_ball_anim.gd")

const MARBLE := Color(0.88, 0.86, 0.82)
const GOLD := Color(0.92, 0.72, 0.28)
const GLASS := Color(0.45, 0.75, 0.95, 0.42)
const DARK := Color(0.14, 0.15, 0.18)
const NEON_PINK := Color(1.0, 0.25, 0.55)
const NEON_CYAN := Color(0.2, 0.95, 1.0)
const NEON_LIME := Color(0.45, 1.0, 0.35)
const SHOP_A := Color(0.55, 0.22, 0.35)
const SHOP_B := Color(0.2, 0.35, 0.55)
const SHOP_C := Color(0.35, 0.45, 0.22)
const SHOP_D := Color(0.5, 0.32, 0.15)


static func should_replace_next_building() -> bool:
	return DevBuildingLabelsScript.peek_next_id() == BUILDING_ID


static func build(zone_root: Node3D, center: Vector3, cell: Vector2i = Vector2i.ZERO) -> Node3D:
	var mall := Node3D.new()
	mall.name = "ShoppingMall_12"
	mall.position = center
	mall.set_meta("featured_building_id", BUILDING_ID)
	mall.set_meta("shopping_mall", true)
	zone_root.add_child(mall)

	_build_shell(mall)
	_build_entrance(mall)
	_build_interior_floor(mall)
	_build_atrium(mall)
	_build_shops(mall)
	_build_second_floor(mall)
	_build_lighting(mall)
	_build_decor(mall)
	_build_signage(mall, cell)
	_spawn_juggler(mall)

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = "shopping_mall_12"
	marker.display_name = "Neo-Mall"
	marker.category = "shopping"
	marker.keywords = PackedStringArray([
		"mall", "shopping", "köpcenter", "butik", "jonglör", "byggnad 12", "znood"
	])
	marker.map_color = NEON_PINK
	mall.add_child(marker)

	DevBuildingLabelsScript.attach(
		zone_root,
		center,
		Vector3(16.0, 0.0, 12.0),
		0.0,
		mall
	)
	return mall


static func _build_shell(mall: Node3D) -> void:
	# Ytterväggar (öppning i +Z för entré).
	var wall_h := 9.5
	var half_w := 16.0
	var half_d := 12.0
	var thick := 0.45

	# Golvplatta under hela mall
	var slab := _box(Vector3(half_w * 2.0 + 1.0, 0.35, half_d * 2.0 + 1.0), DARK)
	slab.position = Vector3(0.0, -0.15, 0.0)
	mall.add_child(slab)
	WorldCollisionBuilderScript.attach_box(
		mall, Vector3(half_w * 2.0, 0.4, half_d * 2.0), Vector3(0.0, -0.1, 0.0)
	)

	# Bakvägg -Z
	var back := _box(Vector3(half_w * 2.0, wall_h, thick), Color(0.72, 0.74, 0.78))
	back.position = Vector3(0.0, wall_h * 0.5, -half_d)
	mall.add_child(back)
	WorldCollisionBuilderScript.attach_box(
		mall, Vector3(half_w * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -half_d)
	)

	# Sidor
	for side in [-1.0, 1.0]:
		var wall := _box(Vector3(thick, wall_h, half_d * 2.0), Color(0.7, 0.72, 0.76))
		wall.position = Vector3(half_w * side, wall_h * 0.5, 0.0)
		mall.add_child(wall)
		WorldCollisionBuilderScript.attach_box(
			mall, Vector3(thick, wall_h, half_d * 2.0), Vector3(half_w * side, wall_h * 0.5, 0.0)
		)

	# Frontvägg +Z med entréöppning (två paneler + överliggare)
	var door_w := 4.2
	var door_h := 3.6
	var side_w := (half_w * 2.0 - door_w) * 0.5
	for side in [-1.0, 1.0]:
		var front := _box(Vector3(side_w, wall_h, thick), Color(0.75, 0.76, 0.8))
		front.position = Vector3(side * (door_w * 0.5 + side_w * 0.5), wall_h * 0.5, half_d)
		mall.add_child(front)
		WorldCollisionBuilderScript.attach_box(
			mall,
			Vector3(side_w, wall_h, thick),
			Vector3(side * (door_w * 0.5 + side_w * 0.5), wall_h * 0.5, half_d)
		)
	var lintel := _box(Vector3(door_w + 0.4, wall_h - door_h, thick), Color(0.78, 0.8, 0.84))
	lintel.position = Vector3(0.0, door_h + (wall_h - door_h) * 0.5, half_d)
	mall.add_child(lintel)
	WorldCollisionBuilderScript.attach_box(
		mall,
		Vector3(door_w + 0.4, wall_h - door_h, thick),
		Vector3(0.0, door_h + (wall_h - door_h) * 0.5, half_d)
	)

	# Glasfasader
	for i in 4:
		var g := _box(Vector3(2.8, 3.2, 0.08), GLASS)
		g.position = Vector3(-10.0 + float(i) * 3.2, 5.2, half_d + 0.12)
		mall.add_child(g)

	# Tak
	var roof := _box(Vector3(half_w * 2.0 + 0.8, 0.4, half_d * 2.0 + 0.8), Color(0.2, 0.22, 0.26))
	roof.position = Vector3(0.0, wall_h + 0.15, 0.0)
	mall.add_child(roof)
	WorldCollisionBuilderScript.attach_box(
		mall, Vector3(half_w * 2.0, 0.4, half_d * 2.0), Vector3(0.0, wall_h + 0.15, 0.0)
	)


static func _build_entrance(mall: Node3D) -> void:
	var door_pos := Vector3(0.0, 0.0, 12.05)
	var door := ZnoodDoorBuilderScript.place(
		mall,
		door_pos,
		Vector3(3.8, 3.4, 0.35),
		"mall_12_main",
		0.0,
		"Stämpla Znood för att öppna Neo-Mall [E]"
	)
	door.prompt_open = "Välkommen in i Neo-Mall"

	# Markis
	var awning := _box(Vector3(6.5, 0.18, 2.2), NEON_PINK.darkened(0.2))
	awning.position = Vector3(0.0, 3.8, 13.2)
	mall.add_child(awning)

	var pillars := [-2.4, 2.4]
	for x in pillars:
		var p := _box(Vector3(0.35, 3.6, 0.35), GOLD)
		p.position = Vector3(x, 1.8, 12.6)
		mall.add_child(p)

	var welcome := Label3D.new()
	welcome.text = "NEO-MALL\nStämpla Znood [E]"
	welcome.font_size = 36
	welcome.modulate = NEON_CYAN
	welcome.outline_modulate = Color(0.05, 0.08, 0.12, 0.95)
	welcome.position = Vector3(0.0, 5.6, 12.4)
	welcome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mall.add_child(welcome)


static func _build_interior_floor(mall: Node3D) -> void:
	var floor := _box(Vector3(30.5, 0.12, 22.5), MARBLE)
	floor.position = Vector3(0.0, 0.08, 0.0)
	mall.add_child(floor)

	# Mönstrad mittgång
	var aisle := _box(Vector3(6.0, 0.04, 20.0), Color(0.95, 0.9, 0.75))
	aisle.position = Vector3(0.0, 0.16, 0.0)
	mall.add_child(aisle)

	for i in 5:
		var tile := _box(Vector3(5.5, 0.03, 0.25), GOLD)
		tile.position = Vector3(0.0, 0.18, -8.0 + float(i) * 4.0)
		mall.add_child(tile)


static func _build_atrium(mall: Node3D) -> void:
	# Öppen mitt med fontän
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.8
	cyl.height = 0.45
	base.mesh = cyl
	base.position = Vector3(0.0, 0.35, -1.0)
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.55, 0.58, 0.62)
	base_mat.metallic = 0.5
	base.material_override = base_mat
	mall.add_child(base)

	var water := MeshInstance3D.new()
	var wmesh := CylinderMesh.new()
	wmesh.top_radius = 1.9
	wmesh.bottom_radius = 1.9
	wmesh.height = 0.12
	water.mesh = wmesh
	water.position = Vector3(0.0, 0.62, -1.0)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.25, 0.55, 0.85, 0.7)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.emission_enabled = true
	wmat.emission = Color(0.2, 0.5, 0.9)
	wmat.emission_energy_multiplier = 0.35
	water.material_override = wmat
	mall.add_child(water)

	var spout := _box(Vector3(0.2, 1.8, 0.2), Color(0.75, 0.78, 0.85))
	spout.position = Vector3(0.0, 1.4, -1.0)
	mall.add_child(spout)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 4.5, -1.0)
	light.light_color = Color(0.85, 0.92, 1.0)
	light.light_energy = 1.4
	light.omni_range = 18.0
	light.shadow_enabled = false
	mall.add_child(light)


static func _build_shops(mall: Node3D) -> void:
	var shop_defs := [
		{"name": "NEON STYLE", "color": SHOP_A, "x": -11.5, "z": -6.0, "neon": NEON_PINK},
		{"name": "CUBE TECH", "color": SHOP_B, "x": -11.5, "z": 2.5, "neon": NEON_CYAN},
		{"name": "VAPEN & VIBE", "color": SHOP_C, "x": 11.5, "z": -6.0, "neon": NEON_LIME},
		{"name": "SÖTSAKER", "color": SHOP_D, "x": 11.5, "z": 2.5, "neon": GOLD},
		{"name": "ZNOOD ZONE", "color": Color(0.25, 0.45, 0.35), "x": -11.5, "z": -0.0, "neon": NEON_LIME},
		{"name": "LUXURY LAB", "color": Color(0.4, 0.3, 0.5), "x": 11.5, "z": 0.0, "neon": NEON_PINK},
	]
	for s in shop_defs:
		_build_shop_unit(
			mall,
			str(s.name),
			s.color as Color,
			s.neon as Color,
			float(s.x),
			float(s.z)
		)


static func _build_shop_unit(
	mall: Node3D,
	shop_name: String,
	wall_color: Color,
	neon: Color,
	x: float,
	z: float
) -> void:
	var unit := Node3D.new()
	unit.name = "Shop_%s" % shop_name.replace(" ", "_")
	unit.position = Vector3(x, 0.0, z)
	mall.add_child(unit)

	var shell := _box(Vector3(5.5, 3.8, 5.2), wall_color)
	shell.position = Vector3(0.0, 1.9, 0.0)
	unit.add_child(shell)

	var window := _box(Vector3(3.2, 2.2, 0.1), GLASS)
	window.position = Vector3(-2.4 if x > 0.0 else 2.4, 1.8, 0.0)
	unit.add_child(window)

	var counter := _box(Vector3(3.2, 1.0, 1.0), Color(0.25, 0.22, 0.2))
	counter.position = Vector3(0.0, 0.55, 1.2)
	unit.add_child(counter)

	var sign := Label3D.new()
	sign.text = shop_name
	sign.font_size = 26
	sign.modulate = neon
	sign.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	sign.position = Vector3(0.0, 3.5, 2.4)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	unit.add_child(sign)

	var strip := _box(Vector3(4.8, 0.12, 0.12), neon)
	strip.position = Vector3(0.0, 3.25, 2.55)
	var strip_mat := strip.material_override as StandardMaterial3D
	if strip_mat:
		strip_mat.emission_enabled = true
		strip_mat.emission = neon
		strip_mat.emission_energy_multiplier = 0.9
	unit.add_child(strip)

	# Enkel inredning
	var prop_names: Array[String] = ["chair", "table", "lampRoundFloor", "plantSmall1"]
	var prop: String = prop_names[absi(hash(shop_name)) % prop_names.size()]
	var furn := FurnitureKitLibraryScript.spawn(unit, prop, Vector3(0.8, 0.0, -0.6), 0.4)
	if furn:
		furn.scale = Vector3.ONE * 1.5

	var lite := OmniLight3D.new()
	lite.position = Vector3(0.0, 3.2, 0.5)
	lite.light_color = neon.lightened(0.2)
	lite.light_energy = 0.85
	lite.omni_range = 7.0
	lite.shadow_enabled = false
	unit.add_child(lite)


static func _build_second_floor(mall: Node3D) -> void:
	# Balkonger vänster/höger
	for side in [-1.0, 1.0]:
		var deck := _box(Vector3(6.5, 0.28, 18.0), Color(0.65, 0.66, 0.7))
		deck.position = Vector3(side * 10.5, 4.5, 0.0)
		mall.add_child(deck)
		WorldCollisionBuilderScript.attach_box(
			mall, Vector3(6.5, 0.28, 18.0), Vector3(side * 10.5, 4.5, 0.0)
		)
		var rail := _box(Vector3(0.12, 0.9, 18.0), GOLD)
		rail.position = Vector3(side * 7.4, 5.1, 0.0)
		mall.add_child(rail)

	# Trappa (enkel)
	for i in 8:
		var step := _box(Vector3(2.4, 0.22, 0.55), Color(0.55, 0.5, 0.45))
		step.position = Vector3(0.0, 0.25 + float(i) * 0.48, 7.5 - float(i) * 0.45)
		mall.add_child(step)
		WorldCollisionBuilderScript.attach_box(
			mall,
			Vector3(2.4, 0.22, 0.55),
			Vector3(0.0, 0.25 + float(i) * 0.48, 7.5 - float(i) * 0.45)
		)

	var upper_sign := Label3D.new()
	upper_sign.text = "PLAN 2 — FOOD COURT & ARCADE"
	upper_sign.font_size = 28
	upper_sign.modulate = NEON_CYAN
	upper_sign.position = Vector3(0.0, 6.8, -9.5)
	upper_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mall.add_child(upper_sign)


static func _build_lighting(mall: Node3D) -> void:
	for pos in [
		Vector3(-8.0, 7.5, 4.0),
		Vector3(8.0, 7.5, 4.0),
		Vector3(-8.0, 7.5, -6.0),
		Vector3(8.0, 7.5, -6.0),
		Vector3(0.0, 8.0, 8.0),
	]:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color(1.0, 0.95, 0.88)
		light.light_energy = 1.15
		light.omni_range = 14.0
		light.shadow_enabled = false
		mall.add_child(light)

		var fixture := _box(Vector3(0.8, 0.15, 0.8), Color(0.9, 0.9, 0.85))
		fixture.position = pos + Vector3(0.0, 0.3, 0.0)
		var fmat := fixture.material_override as StandardMaterial3D
		if fmat:
			fmat.emission_enabled = true
			fmat.emission = Color(1.0, 0.95, 0.8)
			fmat.emission_energy_multiplier = 0.6
		mall.add_child(fixture)


static func _build_decor(mall: Node3D) -> void:
	# Bänkar och växter i gången
	for z in [-7.0, 3.0, 8.0]:
		for x in [-3.5, 3.5]:
			var bench := FurnitureKitLibraryScript.spawn(mall, "bench", Vector3(x, 0.1, z), 0.0)
			if bench:
				bench.scale = Vector3.ONE * 1.8
			var plant := FurnitureKitLibraryScript.spawn(
				mall, "pottedPlant", Vector3(x * 1.4, 0.1, z + 1.2), 0.2
			)
			if plant:
				plant.scale = Vector3.ONE * 1.6

	# Skärmar / reklam
	for i in 3:
		var screen := _box(Vector3(2.8, 1.6, 0.08), Color(0.05, 0.08, 0.12))
		screen.position = Vector3(-6.0 + float(i) * 6.0, 6.2, -11.4)
		var sm := screen.material_override as StandardMaterial3D
		if sm:
			sm.emission_enabled = true
			sm.emission = [NEON_PINK, NEON_CYAN, NEON_LIME][i]
			sm.emission_energy_multiplier = 0.75
		mall.add_child(screen)


static func _build_signage(mall: Node3D, cell: Vector2i) -> void:
	var title := Label3D.new()
	title.text = "NEO-MALL\nByggnad 12"
	title.font_size = 48
	title.modulate = GOLD
	title.outline_modulate = Color(0.08, 0.06, 0.1, 0.95)
	title.position = Vector3(0.0, 10.5, 0.0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mall.add_child(title)

	var sub := Label3D.new()
	sub.text = "Shopping · Mat · Arcade · Jonglörshow"
	sub.font_size = 22
	sub.modulate = NEON_CYAN
	sub.position = Vector3(0.0, 9.2, 0.0)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mall.add_child(sub)

	if cell != Vector2i.ZERO:
		var cell_l := Label3D.new()
		cell_l.text = "Rutnät %d, %d" % [cell.x, cell.y]
		cell_l.font_size = 16
		cell_l.modulate = Color(0.7, 0.75, 0.8)
		cell_l.position = Vector3(0.0, 8.5, 0.0)
		cell_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mall.add_child(cell_l)


static func _spawn_juggler(mall: Node3D) -> void:
	var juggler := Node3D.new()
	juggler.name = "Juggler"
	# Precis innanför entrén
	juggler.position = Vector3(0.0, 0.0, 8.5)
	mall.add_child(juggler)

	var pivot := Node3D.new()
	pivot.name = "Model"
	juggler.add_child(pivot)
	var model := CharacterKitLibraryScript.spawn(pivot, "character-g", Vector3.ZERO, PI, 1.05)
	if model:
		CharacterKitLibraryScript.apply_tint(model, Color(0.85, 0.15, 0.45))

	var name_l := Label3D.new()
	name_l.text = "Jonglören Jinx"
	name_l.font_size = 28
	name_l.modulate = NEON_PINK
	name_l.outline_modulate = Color(0.08, 0.04, 0.06, 0.95)
	name_l.position = Vector3(0.0, 2.25, 0.0)
	name_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	juggler.add_child(name_l)

	var bark := Label3D.new()
	bark.text = "Välkommen till Neo-Mall!\nTitta — tre bollar i luften!"
	bark.font_size = 18
	bark.modulate = Color(0.95, 0.9, 0.75)
	bark.position = Vector3(0.0, 2.7, 0.0)
	bark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	juggler.add_child(bark)

	# Jongleringsbollar (animeras billigt)
	var anim: JugglerBallAnim = JugglerBallAnimScript.new()
	anim.name = "JuggleBalls"
	juggler.add_child(anim)
	anim.setup()


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.08
		mat.metallic = 0.15
	else:
		mat.roughness = 0.62
	mi.material_override = mat
	return mi
