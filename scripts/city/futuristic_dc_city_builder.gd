class_name FuturisticDcCityBuilder
extends RefCounted

const DevBuildingLabelsScript = preload("res://scripts/dev/dev_building_labels.gd")
const ZezzlorCheckpointBuilderScript = preload("res://scripts/access/zezzlor_checkpoint_builder.gd")
const ZezzlorHqBuilderScript = preload("res://scripts/access/zezzlor_hq_builder.gd")
const PharmacyBuilderScript = preload("res://scripts/shops/pharmacy_builder.gd")
const WeaponShopBuilderScript = preload("res://scripts/shops/weapon_shop_builder.gd")
const PotionShopBuilderScript = preload("res://scripts/shops/potion_shop_builder.gd")
const ShoeShopBuilderScript = preload("res://scripts/shops/shoe_shop_builder.gd")
const FurnitureShopBuilderScript = preload("res://scripts/shops/furniture_shop_builder.gd")
const UtilityShopBuilderScript = preload("res://scripts/shops/utility_shop_builder.gd")
const PurpleLaserTowerBuilderScript = preload("res://scripts/city/purple_laser_tower_builder.gd")
const StreetLampScript = preload("res://scripts/city/street_lamp.gd")
const StreetLampServiceScript = preload("res://scripts/city/street_lamp_service.gd")
const ZezzlorPaBuilderScript = preload("res://scripts/city/zezzlor_pa_builder.gd")
const SpawnDensityScript = preload("res://scripts/world/spawn_density.gd")
const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")
const WaterBuilderScript = preload("res://scripts/environment/water_builder.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")
const FeaturedBuildingBuilderScript = preload("res://scripts/city/featured_building_builder.gd")
const PlaygroundParkBuilderScript = preload("res://scripts/city/playground_park_builder.gd")
const ShoppingMallBuilderScript = preload("res://scripts/city/shopping_mall_builder.gd")
const FactoryWorkBuilderScript = preload("res://scripts/city/factory_work_builder.gd")
const BuildingAmbianceLightsScript = preload("res://scripts/city/building_ambiance_lights.gd")
const CuteCottageBuilderScript = preload("res://scripts/city/cute_cottage_builder.gd")
const ColonyDecalBuilderScript = preload("res://scripts/city/colony_decal_builder.gd")

const AVENUE_NAMES := {
	0: "Nationalmallen",
	2: "Constitution Ave",
	-2: "Independence Ave",
}
const STREET_PREFIX := "Neo-Washington"
## Avstånd från vägens mittlinje till lyktstolpe (måste vara > halva vägbanan).
const STREET_LAMP_SIDE_OFFSET := 8.5
const ROAD_HALF_WIDTH_M := 2.8
## Kenney road-kit scale 4 → ~4 m per rakt stycke.
const ROAD_PIECE_M := 4.0
## Min avstånd mellan byggnadscentrum nära spawn / längre bort.
## Spawn: gles plaza — undvik hus som sitter i varandra.
const MIN_BUILDING_SEP_SPAWN_M := 72.0
const MIN_BUILDING_SEP_CITY_M := 48.0 ## > BLOCK_M (40) → inte varannan cell
const SPAWN_SPACING_RADIUS_M := 170.0
const SPAWN_CLEAR_RADIUS_M := 38.0 ## Inga zonbyggnader inne i denna radie

## Världspositioner (lokala till NeoWashington) för redan placerade byggnader.
static var _placed_building_xz: Array[Vector2] = []


static func build(parent: Node3D, spawn_pos: Vector3, spawn_id: String = "satellite_right") -> Node3D:
	DevBuildingLabelsScript.reset()
	StreetLampServiceScript.reset()
	_placed_building_xz.clear()
	var root := Node3D.new()
	root.name = "NeoWashington"
	root.position = spawn_pos
	parent.add_child(root)

	var theme := ColonyCityTheme.for_spawn(spawn_id)
	_build_city_plate(root, theme)
	_build_street_grid(root, theme)
	_build_mall_axis(root, theme)
	var building_cells: Array = _build_zoned_blocks(root)
	_hang_lights_between_neighbors(root, building_cells)
	_build_landmarks(root, theme)
	_build_spawn_plaza(root)
	WaterBuilderScript.build_city_water_features(root)
	_build_pharmacy_near_spawn(root)
	_build_weapon_shop_near_spawn(root)
	_build_potion_shop_near_spawn(root)
	_build_shoe_shop_near_spawn(root)
	_build_furniture_shop_near_spawn(root)
	_build_utility_shop_near_spawn(root)
	_build_purple_laser_tower_near_spawn(root)
	_build_story_sites(root)
	_build_zezzlor_checkpoints(root)
	_build_zezzlor_hq_sites(root)
	_place_city_sign(root)
	ZezzlorPaBuilderScript.build(root)
	ColonyDecalBuilderScript.decorate_city(root)
	StreetLampServiceScript.finalize_for_city(root, get_spawn_center())

	return root


static func _build_city_plate(root: Node3D, theme: Dictionary = {}) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var width: float = float(extent.x_max - extent.x_min + 1) * DcZoneCatalog.BLOCK_M
	var depth: float = float(extent.z_max - extent.z_min + 1) * DcZoneCatalog.BLOCK_M
	var origin: Vector3 = _cell_origin(Vector2i(extent.x_min, extent.z_min))

	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width + 80.0, 0.35, depth + 80.0)
	plate.mesh = mesh
	plate.position = origin + Vector3(width * 0.5 - DcZoneCatalog.BLOCK_M * 0.5, -0.32, depth * 0.5 - DcZoneCatalog.BLOCK_M * 0.5)
	var mat := StandardMaterial3D.new()
	## Markyta under staden — grågrön asfalt/jord, inte svart eller vit.
	mat.albedo_color = theme.get("plate_color", Color(0.28, 0.32, 0.3)) as Color
	mat.metallic = 0.08
	mat.roughness = 0.88
	plate.material_override = mat
	root.add_child(plate)

	# Under golvnivå (y≈0) så spelare inte spawnar inuti plattan.
	var plate_pos := origin + Vector3(
		width * 0.5 - DcZoneCatalog.BLOCK_M * 0.5,
		-0.28,
		depth * 0.5 - DcZoneCatalog.BLOCK_M * 0.5
	)
	WorldCollisionBuilderScript.attach_box(
		root,
		Vector3(width + 80.0, 0.35, depth + 80.0),
		plate_pos
	)


static func _build_street_grid(root: Node3D, theme: Dictionary) -> void:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var roads := Node3D.new()
	roads.name = "StreetGrid"
	root.add_child(roads)

	var x_min: int = int(extent.x_min)
	var x_max: int = int(extent.x_max)
	var z_min: int = int(extent.z_min)
	var z_max: int = int(extent.z_max)
	var block := DcZoneCatalog.BLOCK_M
	var step := ROAD_PIECE_M

	## Rakt ortogonalt rutnät (inga meandrar) — rena Kenney-bitar.
	## 1) Korsningar
	for x_i in range(x_min, x_max + 2):
		for z_i in range(z_min, z_max + 2):
			var pos := Vector3(float(x_i) * block, 0.03, float(z_i) * block)
			CityKitLibrary.spawn(roads, "roads", "road-square", pos, 0.0)

	## 2) Öst–väst (längs X) mellan korsningar — road-straight längs lokal X, yaw 0.
	for z_i in range(z_min, z_max + 2):
		var z := float(z_i) * block
		for x_i in range(x_min, x_max + 1):
			var x0 := float(x_i) * block
			var t := step
			while t < block - 0.01:
				CityKitLibrary.spawn(
					roads,
					"roads",
					"road-straight",
					Vector3(x0 + t, 0.03, z),
					0.0
				)
				t += step

	## 3) Nord–syd (längs Z) — road-straight roterad 90°.
	for x_i in range(x_min, x_max + 2):
		var x := float(x_i) * block
		for z_i in range(z_min, z_max + 1):
			var z0 := float(z_i) * block
			var t := step
			while t < block - 0.01:
				CityKitLibrary.spawn(
					roads,
					"roads",
					"road-straight",
					Vector3(x, 0.03, z0 + t),
					PI * 0.5
				)
				t += step

	# Lyktor endast på trottoar-linjer (aldrig i körbana).
	_spawn_sidewalk_lamps(roads, theme, extent)


static func _build_mall_axis(root: Node3D, theme: Dictionary = {}) -> void:
	var mall := Node3D.new()
	mall.name = "NationalMall"
	root.add_child(mall)

	for cell in DcZoneCatalog.mall_cells():
		var base := _cell_origin(cell)
		for patch_x in range(-1, 2):
			for patch_z in range(-2, 3):
				var pos := base + Vector3(
					DcZoneCatalog.BLOCK_M * 0.5 + patch_x * 6.0,
					0.04,
					DcZoneCatalog.BLOCK_M * 0.5 + patch_z * 6.0
				)
				CityKitLibrary.spawn(mall, "roads", "tile-low", pos)
		_add_zone_marker(
			mall,
			base + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5),
			DcZoneCatalog.classify_cell(cell),
			false
		)

	var obelisk_pos := _cell_origin(Vector2i(-3, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	_build_obelisk(mall, obelisk_pos, theme)


static func _build_zoned_blocks(root: Node3D) -> Array:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	var zones := Node3D.new()
	zones.name = "ZonedBlocks"
	root.add_child(zones)
	var building_cells: Array = []

	## Bygg närmast spawn först så spacing-regeln prioriterar gles plaza.
	var cells: Array[Vector2i] = []
	for x in range(extent.x_min, extent.x_max + 1):
		for z in range(extent.z_min, extent.z_max + 1):
			var cell := Vector2i(x, z)
			if cell in DcZoneCatalog.mall_cells():
				continue
			if DcZoneCatalog.is_reserved_landmark_cell(cell):
				continue
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.length_squared() < b.length_squared()
	)

	for cell in cells:
		if _build_zone_block(zones, cell):
			building_cells.append(cell)
	return building_cells


static func _hang_lights_between_neighbors(root: Node3D, building_cells: Array) -> void:
	if building_cells.is_empty():
		return
	var hang_root := Node3D.new()
	hang_root.name = "HangingStreetLights"
	root.add_child(hang_root)
	var cell_set: Dictionary = {}
	for c in building_cells:
		cell_set[c] = true
	var warm := Color(1.0, 0.8, 0.42)
	var links := 0
	var max_links := 28 if GlesPerformanceScript.is_active() else 70
	for c in building_cells:
		var cell: Vector2i = c
		# Bara +X och +Z för att undvika dubletter.
		for n in [Vector2i(cell.x + 1, cell.y), Vector2i(cell.x, cell.y + 1)]:
			if not cell_set.has(n):
				continue
			# Hoppa över varannan länk på GLES.
			if GlesPerformanceScript.is_active() and (cell.x + cell.y + n.x) % 2 == 0:
				continue
			var a := _cell_origin(cell) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
			var b := _cell_origin(n) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
			BuildingAmbianceLightsScript.hang_between_buildings(hang_root, a, b, warm)
			links += 1
			if links >= max_links:
				return


static func _build_zone_block(parent: Node3D, cell: Vector2i) -> bool:
	var spec: Dictionary = DcZoneCatalog.classify_cell(cell)
	var zone_root := Node3D.new()
	zone_root.name = "Zone_%d_%d" % [cell.x, cell.y]
	zone_root.position = _cell_origin(cell)
	parent.add_child(zone_root)

	var center: Vector3 = Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	var kit: String = str(spec.get("kit", "commercial"))
	var model: String = str(spec.get("model", "building-a"))
	var zone_type: String = str(spec.get("zone_type", ""))
	var rotation_y := float((cell.x + cell.y) % 4) * PI * 0.5

	var world_center := zone_root.position + center
	var placed_building := false
	var spawn_xz_dist := Vector2(
		world_center.x - get_spawn_center().x,
		world_center.z - get_spawn_center().z
	).length()
	## Håll Kapitolplaza fri — bara golv/park nära spawn.
	var in_spawn_clear := spawn_xz_dist < SPAWN_CLEAR_RADIUS_M
	if FactoryWorkBuilderScript.is_factory_cell(cell):
		# Alltid placera verkstadsfabriken (jobb-minigame) oavsett densitet.
		FactoryWorkBuilderScript.build(zone_root, center, cell)
		CityKitLibrary.spawn(zone_root, "roads", "road-square", center + Vector3(0.0, 0.02, 0.0))
		_register_building_world(world_center)
		placed_building = true
	elif kit == "roads":
		CityKitLibrary.spawn(zone_root, kit, model, center + Vector3(0.0, 0.02, 0.0))
		_add_park_lights(zone_root, center, ColonyCityTheme.for_spawn("satellite_right"))
	elif kit == "space" and not in_spawn_clear:
		SpaceKitLibrary.spawn(zone_root, model, center)
		_register_building_world(world_center)
		placed_building = true
	elif (
		not in_spawn_clear
		and SpawnDensityScript.should_place_building(cell)
		and _can_place_building_world(world_center)
	):
		# Hus nr 9 → lekpark | hus nr 12 → shoppingcenter.
		if PlaygroundParkBuilderScript.should_replace_next_building():
			PlaygroundParkBuilderScript.build(zone_root, center, cell)
			CityKitLibrary.spawn(zone_root, "roads", "road-square", center + Vector3(0.0, 0.02, 0.0))
			_register_building_world(world_center)
			placed_building = true
		elif ShoppingMallBuilderScript.should_replace_next_building():
			ShoppingMallBuilderScript.build(zone_root, center, cell)
			CityKitLibrary.spawn(zone_root, "roads", "road-square", center + Vector3(0.0, 0.02, 0.0))
			_register_building_world(world_center)
			placed_building = true
		elif CuteCottageBuilderScript.should_spawn_cute(cell, zone_type, kit):
			CuteCottageBuilderScript.build(zone_root, center, cell, rotation_y)
			CityKitLibrary.spawn(zone_root, "roads", "road-square", center + Vector3(0.0, 0.02, 0.0))
			_register_building_world(world_center)
			placed_building = true
		else:
			var scale := CityKitLibrary.kit_scale(kit)
			var building := CityKitLibrary.spawn(zone_root, kit, model, center, rotation_y)
			if FeaturedBuildingBuilderScript.is_building_33_cell(cell) and building != null:
				FeaturedBuildingBuilderScript.enhance(zone_root, building, center, rotation_y, scale)
			CityKitLibrary.spawn(zone_root, "roads", "road-square", center + Vector3(0.0, 0.02, 0.0))
			BuildingAmbianceLightsScript.decorate_building(
				zone_root,
				center,
				rotation_y,
				scale,
				Color(1.0, 0.84, 0.48)
			)
			_register_building_world(world_center)
			placed_building = true
	else:
		# Tomma rutor: golvplatta, ingen extra stuga om spacing/spawn-clear blockerar.
		if (
			not in_spawn_clear
			and CuteCottageBuilderScript.should_spawn_cute(cell, zone_type, kit)
			and (zone_type in ["BOSTADSKVARTER", "AMBASSADNÄSET"] or kit == "suburban")
			and _can_place_building_world(world_center)
		):
			CuteCottageBuilderScript.build(zone_root, center, cell, rotation_y)
			CityKitLibrary.spawn(zone_root, "roads", "tile-low", center + Vector3(0.0, 0.02, 0.0))
			_register_building_world(world_center)
			placed_building = true
		else:
			CityKitLibrary.spawn(zone_root, "roads", "tile-low", center + Vector3(0.0, 0.02, 0.0))
			if (
				not in_spawn_clear
				and not GlesPerformanceScript.skip_greenery()
				and SpawnDensityScript.should_scatter_cell_accent(cell)
			):
				GreeneryVegetationBuilder.scatter_cell_accent(zone_root, center, cell)

	_add_zone_marker(zone_root, center, spec, true)
	WaterBuilderScript.populate_zone_water(zone_root, center, cell, zone_type, kit, rotation_y)
	return placed_building


static func _can_place_building_world(world_center: Vector3) -> bool:
	var spawn := get_spawn_center()
	var dist_spawn := Vector2(world_center.x - spawn.x, world_center.z - spawn.z).length()
	if dist_spawn < SPAWN_CLEAR_RADIUS_M:
		return false
	var min_sep := MIN_BUILDING_SEP_SPAWN_M if dist_spawn <= SPAWN_SPACING_RADIUS_M else MIN_BUILDING_SEP_CITY_M
	for p in _placed_building_xz:
		var d := Vector2(world_center.x - p.x, world_center.z - p.y).length()
		if d < min_sep:
			return false
	return true


static func _register_building_world(world_center: Vector3) -> void:
	_placed_building_xz.append(Vector2(world_center.x, world_center.z))


static func _try_place_poi(root: Node3D, local_pos: Vector3, build_cb: Callable) -> bool:
	if not _can_place_building_world(local_pos):
		## Förskjut i ring tills spacing håller.
		for ring in range(1, 6):
			var r := float(ring) * 12.0
			for k in 8:
				var ang := float(k) * TAU / 8.0
				var cand := local_pos + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
				if _can_place_building_world(cand):
					local_pos = cand
					build_cb.call(root, local_pos)
					_register_building_world(local_pos)
					return true
		return false
	build_cb.call(root, local_pos)
	_register_building_world(local_pos)
	return true


## Butiker i en ring runt spawn — ≥24 m isär, utanför clear-radie.
static func _spawn_ring_pos(spawn_center: Vector3, angle_deg: float, radius: float) -> Vector3:
	var a := deg_to_rad(angle_deg)
	return spawn_center + Vector3(cos(a) * radius, 0.0, sin(a) * radius)


## Butiker får mildare isär-krav (26 m) än fulla zonhus.
static func _can_place_poi(world_center: Vector3, min_sep: float = 26.0) -> bool:
	var spawn := get_spawn_center()
	var dist_spawn := Vector2(world_center.x - spawn.x, world_center.z - spawn.z).length()
	if dist_spawn < SPAWN_CLEAR_RADIUS_M + 2.0:
		return false
	for p in _placed_building_xz:
		var d := Vector2(world_center.x - p.x, world_center.z - p.y).length()
		if d < min_sep:
			return false
	return true


static func _place_poi_with_space(root: Node3D, preferred: Vector3, build_cb: Callable) -> Vector3:
	var pos := preferred
	if not _can_place_poi(pos):
		for ring in range(1, 8):
			var r := float(ring) * 9.0
			var found := false
			for k in 12:
				var ang := float(k) * TAU / 12.0
				var cand := preferred + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
				if _can_place_poi(cand):
					pos = cand
					found = true
					break
			if found:
				break
	build_cb.call(root, pos)
	_register_building_world(pos)
	return pos


static func _build_pharmacy_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var pharmacy_pos := _spawn_ring_pos(spawn_center, 200.0, 48.0)
	pharmacy_pos = _place_poi_with_space(
		root,
		pharmacy_pos,
		func(r: Node3D, p: Vector3) -> void:
			PharmacyBuilderScript.build(r, p)
	)

	var arrow := Label3D.new()
	arrow.text = "PHARMACY →\nPill-Bot har antidot"
	arrow.font_size = 32
	arrow.modulate = Color(0.45, 0.92, 0.68)
	arrow.outline_modulate = Color(0.06, 0.12, 0.1, 0.95)
	arrow.position = spawn_center + Vector3(6.0, 2.5, -4.0)
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(arrow)


static func _build_weapon_shop_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var weapon_pos := _spawn_ring_pos(spawn_center, 140.0, 50.0)
	_place_poi_with_space(
		root,
		weapon_pos,
		func(r: Node3D, p: Vector3) -> void:
			WeaponShopBuilderScript.build(r, p, "weapon_shop_dc")
	)


static func _build_potion_shop_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var potion_pos := _spawn_ring_pos(spawn_center, 250.0, 52.0)
	_place_poi_with_space(
		root,
		potion_pos,
		func(r: Node3D, p: Vector3) -> void:
			PotionShopBuilderScript.build(r, p, "potion_shop_dc")
	)

	var arrow := Label3D.new()
	arrow.text = "BRYGDHÖRNAN →\nMagiska brygder"
	arrow.font_size = 30
	arrow.modulate = Color(0.78, 0.42, 0.98)
	arrow.outline_modulate = Color(0.1, 0.04, 0.16, 0.95)
	arrow.position = spawn_center + Vector3(0.0, 2.5, -8.0)
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(arrow)


static func _build_shoe_shop_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var shoe_pos := _spawn_ring_pos(spawn_center, 40.0, 49.0)
	_place_poi_with_space(
		root,
		shoe_pos,
		func(r: Node3D, p: Vector3) -> void:
			ShoeShopBuilderScript.build(r, p, "shoe_shop_dc")
	)

	var arrow := Label3D.new()
	arrow.text = "SKOBUTIK →\nHoppskor"
	arrow.font_size = 28
	arrow.modulate = Color(0.25, 0.85, 0.62)
	arrow.outline_modulate = Color(0.04, 0.12, 0.1, 0.95)
	arrow.position = spawn_center + Vector3(3.0, 2.4, 4.0)
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(arrow)


static func _build_furniture_shop_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var pos := _spawn_ring_pos(spawn_center, 100.0, 54.0)
	_place_poi_with_space(
		root,
		pos,
		func(r: Node3D, p: Vector3) -> void:
			FurnitureShopBuilderScript.build(r, p, "furniture_shop_dc")
	)


static func _build_utility_shop_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var pos := _spawn_ring_pos(spawn_center, 320.0, 51.0)
	_place_poi_with_space(
		root,
		pos,
		func(r: Node3D, p: Vector3) -> void:
			UtilityShopBuilderScript.build(r, p, "utility_shop_dc")
	)


static func _build_purple_laser_tower_near_spawn(root: Node3D) -> void:
	var spawn_center := get_spawn_center()
	var pos := _spawn_ring_pos(spawn_center, 20.0, 58.0)
	_place_poi_with_space(
		root,
		pos,
		func(r: Node3D, p: Vector3) -> void:
			PurpleLaserTowerBuilderScript.build(r, p, "dc")
	)


static func _build_landmarks(root: Node3D, theme: Dictionary = {}) -> void:
	_build_capitol(
		root,
		_cell_origin(Vector2i(0, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5),
		theme
	)
	_build_memorial_west(
		root,
		_cell_origin(Vector2i(-6, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	)
	_build_white_house(
		root,
		_cell_origin(Vector2i(-2, 3)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)
	)


static func _build_zezzlor_checkpoints(root: Node3D) -> void:
	ZezzlorCheckpointBuilderScript.place_all(root)


static func _build_zezzlor_hq_sites(root: Node3D) -> void:
	ZezzlorHqBuilderScript.place_all(root)


static func _build_story_sites(root: Node3D) -> void:
	var annex_origin := _cell_origin(Vector2i(-4, -3))
	StoryWorldBuilder.build_annex_at(root, annex_origin + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5))
	StoryWorldBuilder.build_hybrid_towers(root, _cell_origin(Vector2i(-1, 2)), _cell_origin(Vector2i(-5, 1)))
	StoryWorldBuilder.place_warning_sign(root, Vector3(-20.0, 0.0, -55.0))


static func get_spawn_center() -> Vector3:
	return _cell_origin(Vector2i(0, 0)) + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5)


static func _build_spawn_plaza(root: Node3D) -> void:
	var center := get_spawn_center()
	var plaza := StaticBody3D.new()
	plaza.name = "SpawnPlaza"
	plaza.position = center
	plaza.collision_layer = WorldCollisionBuilderScript.WORLD_COLLISION_LAYER
	plaza.collision_mask = 0
	root.add_child(plaza)

	# Öppen spawnplatta ovanför golvnivå — undvik att spelaren startar inuti kollision.
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(24.0, 0.4, 24.0)
	floor_shape.shape = floor_box
	floor_shape.position = Vector3(0.0, 0.2, 0.0)
	plaza.add_child(floor_shape)

	var floor_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(22.0, 0.14, 22.0)
	floor_mesh.mesh = mesh
	floor_mesh.position = Vector3(0.0, -0.07, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.44, 0.4)
	mat.metallic = 0.12
	mat.roughness = 0.82
	floor_mesh.material_override = mat
	plaza.add_child(floor_mesh)


static func _build_capitol(parent: Node3D, pos: Vector3, theme: Dictionary = {}) -> void:
	var capitol := Node3D.new()
	capitol.name = "FuturisticCapitol"
	# Kapitoliet norr om spawn-plazan — mittpunkten (pos) ska vara fri att stå på.
	capitol.position = pos + Vector3(0.0, 0.0, -14.0)
	parent.add_child(capitol)

	## Hela byggnader — inga lösa space-kit-väggar i luften.
	CityKitLibrary.spawn(capitol, "commercial", "building-e", Vector3(0, 0, -4), 0.0)
	CityKitLibrary.spawn(capitol, "commercial", "building-d", Vector3(0, 0, 8), PI)

	var dome := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 5.5
	mesh.height = 7.0
	dome.mesh = mesh
	dome.position = Vector3(0.0, 14.0, 2.0)
	var mat := StandardMaterial3D.new()
	## Sten/metallkupol — inte blekt vit.
	mat.albedo_color = theme.get("dome_albedo", Color(0.72, 0.74, 0.82)) as Color
	mat.metallic = 0.45
	mat.roughness = 0.42
	mat.emission_enabled = true
	mat.emission = theme.get("dome_emission", Color(0.35, 0.5, 0.78)) as Color
	mat.emission_energy_multiplier = 0.22
	dome.material_override = mat
	capitol.add_child(dome)
	WorldCollisionBuilderScript.attach_box(capitol, Vector3(11.0, 8.0, 11.0), Vector3(0.0, 14.0, 2.0))

	_add_zone_marker(capitol, Vector3(0, 0, 14.0), DcZoneCatalog.classify_cell(Vector2i(0, 0)), true)


static func _build_obelisk(parent: Node3D, pos: Vector3, theme: Dictionary = {}) -> void:
	var spire := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.8
	mesh.bottom_radius = 2.2
	mesh.height = 42.0
	spire.mesh = mesh
	spire.position = pos + Vector3(0.0, 21.0, 0.0)
	var mat := StandardMaterial3D.new()
	## Monumentsten — gråblå, inte vit metall.
	mat.albedo_color = theme.get("obelisk_albedo", Color(0.62, 0.66, 0.74)) as Color
	mat.metallic = 0.35
	mat.roughness = 0.48
	mat.emission_enabled = true
	mat.emission = theme.get("obelisk_emission", Color(0.4, 0.55, 0.82)) as Color
	mat.emission_energy_multiplier = 0.28
	spire.material_override = mat
	parent.add_child(spire)
	WorldCollisionBuilderScript.attach_box(parent, Vector3(4.4, 42.0, 4.4), pos + Vector3(0.0, 21.0, 0.0))

	var label := Label3D.new()
	label.text = str(DcZoneCatalog.classify_cell(Vector2i(-3, 0)).get("tag", ""))
	label.font_size = 40
	label.modulate = DcZoneCatalog.zone_color("MONUMENTKÄRNA")
	label.position = pos + Vector3(0.0, 46.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _build_memorial_west(parent: Node3D, pos: Vector3) -> void:
	var memorial := Node3D.new()
	memorial.name = "MemorialWest"
	memorial.position = pos
	parent.add_child(memorial)

	## En hel byggnad — inte rad av template-wall-bitar.
	CityKitLibrary.spawn(memorial, "commercial", "building-d", Vector3(0, 0, 0), 0.0)
	CityKitLibrary.spawn(memorial, "commercial", "building-a", Vector3(0, 0, 14), PI)

	_add_zone_marker(memorial, Vector3(0, 0, 0), DcZoneCatalog.classify_cell(Vector2i(-6, 0)), true)


static func _build_white_house(parent: Node3D, pos: Vector3) -> void:
	var executive := Node3D.new()
	executive.name = "ExecutiveMansion"
	executive.position = pos
	parent.add_child(executive)

	CityKitLibrary.spawn(executive, "suburban", "building-type-e", Vector3(0, 0, 0))
	_add_zone_marker(executive, Vector3(0, 0, 0), DcZoneCatalog.classify_cell(Vector2i(-2, 3)), true)


static func _place_city_sign(root: Node3D) -> void:
	var sign := Label3D.new()
	sign.text = (
		"NEO-WASHINGTON — KOLONI 4\n"
		+ "Futuristisk layout efter USA:s huvudstad\n"
		+ "Kapitol öster → Nationalmallen väster\n"
		+ "Varje block har zontag"
	)
	sign.font_size = 52
	sign.modulate = Color(0.55, 0.82, 1.0)
	sign.position = Vector3(0.0, 10.0, -30.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(sign)


static func _add_zone_marker(parent: Node3D, center: Vector3, spec: Dictionary, with_pad: bool) -> void:
	var zone_type: String = str(spec.get("zone_type", "ZON"))
	var tag: String = str(spec.get("tag", zone_type))
	var color: Color = DcZoneCatalog.zone_color(zone_type)

	if with_pad:
		var pad := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(DcZoneCatalog.BLOCK_M - 4.0, 0.08, DcZoneCatalog.BLOCK_M - 4.0)
		pad.mesh = mesh
		pad.position = center + Vector3(0.0, 0.05, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.22)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.12
		pad.material_override = mat
		parent.add_child(pad)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.18, 2.6, 0.18)
	post.mesh = post_mesh
	post.position = center + Vector3(-DcZoneCatalog.BLOCK_M * 0.5 + 3.0, 1.3, -DcZoneCatalog.BLOCK_M * 0.5 + 3.0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = color
	post_mat.emission_enabled = true
	post_mat.emission = color
	post_mat.emission_energy_multiplier = 0.4
	post.material_override = post_mat
	parent.add_child(post)

	var label := Label3D.new()
	label.text = tag
	label.font_size = 28
	label.modulate = color
	label.outline_modulate = Color(0.04, 0.05, 0.08, 0.95)
	label.position = post.position + Vector3(0.0, 1.8, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _add_park_lights(parent: Node3D, center: Vector3, theme: Dictionary) -> void:
	var park_color: Color = theme.get("park_light", Color(0.72, 0.82, 1.0))
	var accent: Color = theme.get("surveillance_accent", Color(0.95, 0.18, 0.12))
	# Inåt i parken — inte nära blockkant där organiska gator meandrar in.
	for offset in [Vector3(-6, 0, -6), Vector3(6, 0, 6), Vector3(-6, 0, 6), Vector3(6, 0, -6)]:
		var pole_pos: Vector3 = center + (offset as Vector3)
		StreetLampScript.mount(
			parent,
			{
				"position": pole_pos,
				"rotation_y": 0.0,
				"color": park_color,
				"height": 5.2,
				"spot_energy": 1.35,
				"spot_range": 13.0,
				"tilt_toward": Vector3(0.0, -1.0, 0.0),
				"broken_chance": 0.06,
				"seed": hash(str(pole_pos)),
			}
		)
		var scan := SpotLight3D.new()
		scan.position = pole_pos + Vector3(0.0, 6.8, 0.0)
		scan.rotation_degrees = Vector3(-88, 0, 0)
		scan.light_color = accent
		scan.light_energy = 0.42
		scan.spot_range = 18.0
		scan.spot_angle = 14.0
		scan.shadow_enabled = false
		parent.add_child(scan)


static func _street_lamp_side_offsets(rotation_y: float) -> Array[Vector3]:
	var along_x := absf(rotation_y) < 0.1 or absf(absf(rotation_y) - PI) < 0.1
	if along_x:
		return [
			Vector3(0.0, 0.0, STREET_LAMP_SIDE_OFFSET),
			Vector3(0.0, 0.0, -STREET_LAMP_SIDE_OFFSET),
		]
	return [
		Vector3(STREET_LAMP_SIDE_OFFSET, 0.0, 0.0),
		Vector3(-STREET_LAMP_SIDE_OFFSET, 0.0, 0.0),
	]


## Placerar lyktor i blockens hörn/trottoar — aldrig längs vägmitt.
static func _spawn_sidewalk_lamps(parent: Node3D, theme: Dictionary, extent: Dictionary) -> void:
	var step := 2 if GlesPerformanceScript.is_active() else 1
	var inset := STREET_LAMP_SIDE_OFFSET
	for x in range(int(extent.x_min), int(extent.x_max) + 1, step):
		for z in range(int(extent.z_min), int(extent.z_max) + 1, step):
			# Fyra hörn inne i varje block, bort från gatorna (som ligger på blockkanterna).
			var origin := _cell_origin(Vector2i(x, z))
			var half := DcZoneCatalog.BLOCK_M * 0.5
			# Håll avstånd från blockkant (= gata).
			var edge_clear := inset + 1.5
			if edge_clear >= half - 1.0:
				continue
			var corners := [
				Vector3(edge_clear, 0.0, edge_clear),
				Vector3(DcZoneCatalog.BLOCK_M - edge_clear, 0.0, edge_clear),
				Vector3(edge_clear, 0.0, DcZoneCatalog.BLOCK_M - edge_clear),
				Vector3(DcZoneCatalog.BLOCK_M - edge_clear, 0.0, DcZoneCatalog.BLOCK_M - edge_clear),
			]
			# Bara ett hörn per block på GLES, två annars.
			var count := 1 if GlesPerformanceScript.is_active() else 2
			for i in count:
				var idx := (x * 3 + z * 7 + i * 5) % corners.size()
				var pos: Vector3 = origin + corners[idx]
				pos.y = 0.0
				_add_street_lamp(parent, pos, theme, 0.0, Vector3(0.0, 0.0, 1.0))


static func _add_street_lamp(
	parent: Node3D,
	pos: Vector3,
	theme: Dictionary,
	rotation_y: float,
	side_offset: Vector3
) -> void:
	var street_color: Color = theme.get("street_light", Color(0.82, 0.9, 1.0))
	StreetLampScript.mount(
		parent,
		{
			"position": pos,
			"rotation_y": rotation_y,
			"color": street_color,
			"height": 4.6,
			"spot_energy": 1.9,
			"spot_range": 16.0,
			"tilt_toward": -side_offset,
			"broken_chance": StreetLampScript.BROKEN_CHANCE,
			"seed": hash(str(pos)),
		}
	)


static func _spawn_road_strip(
	parent: Node3D,
	center: Vector3,
	rotation_y: float,
	length_m: float,
	_label: String,
	theme: Dictionary
) -> void:
	# Bakåtkompatibilitet: raka strippar (används sällan nu).
	var half := length_m * 0.5
	var along := Vector3(1.0, 0.0, 0.0) if absf(rotation_y) < 0.2 else Vector3(0.0, 0.0, 1.0)
	var start := center - along * half
	var end := center + along * half
	_spawn_organic_road(parent, start, end, absf(rotation_y) < 0.2, hash(str(center)), _label, theme)


## Organisk väg: meander (sinus + mjuk brus), bitar roterar med tangenten.
static func _spawn_organic_road(
	parent: Node3D,
	start: Vector3,
	end: Vector3,
	primary_along_x: bool,
	path_seed: int,
	_label: String,
	theme: Dictionary
) -> void:
	var span := end - start
	var length_m := maxf(span.length(), 4.0)
	var step := 4.0
	var segments := maxi(int(ceil(length_m / step)), 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = path_seed

	# Meander-parametrar (olika per gata).
	var waves := rng.randf_range(0.7, 1.85)
	var waves2 := rng.randf_range(1.6, 3.4)
	var amp := rng.randf_range(5.5, 12.5)
	var amp2 := rng.randf_range(1.8, 4.5)
	var phase := rng.randf_range(0.0, TAU)
	var phase2 := rng.randf_range(0.0, TAU)
	# Håll Nationalmallen (z≈0) rakare — stilistisk axel.
	if absf(start.z) < 2.0 and absf(end.z) < 2.0 and primary_along_x:
		amp *= 0.22
		amp2 *= 0.15

	var points: Array[Vector3] = []
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var base := start.lerp(end, t)
		var meander := (
			sin(t * TAU * waves + phase) * amp
			+ sin(t * TAU * waves2 + phase2) * amp2
		)
		# Mjuk brus-liknande offset (deterministisk via seed + t).
		meander += sin(t * 17.3 + float(path_seed % 97) * 0.11) * (amp * 0.12)
		var pos := base
		if primary_along_x:
			pos.z += meander
		else:
			pos.x += meander
		pos.y = 0.03
		points.append(pos)

	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var mid := (a + b) * 0.5
		var dir := b - a
		dir.y = 0.0
		if dir.length_squared() < 0.0001:
			continue
		# road-straight i Kenney-kitet löper längs lokal X → yaw = atan2(dz, dx).
		var yaw := atan2(dir.z, dir.x)
		var turn := 0.0
		if i > 0:
			var prev: Vector3 = points[i] - points[i - 1]
			prev.y = 0.0
			if prev.length_squared() > 0.0001:
				turn = absf(angle_difference(atan2(prev.z, prev.x), yaw))

		var model := "road-straight"
		if turn > 0.38:
			model = "road-curve"
		elif turn > 0.22:
			model = "road-bend"

		CityKitLibrary.spawn(parent, "roads", model, mid, yaw)


static func _spawn_organic_connectors(
	parent: Node3D,
	theme: Dictionary,
	x0: float,
	x1: float,
	z0: float,
	z1: float
) -> void:
	# Några diagonala / S-formade boulevarder som bryter korsmönstret.
	var connectors: Array[Dictionary] = [
		{
			"a": Vector3(lerpf(x0, x1, 0.12), 0.03, lerpf(z0, z1, 0.18)),
			"b": Vector3(lerpf(x0, x1, 0.88), 0.03, lerpf(z0, z1, 0.72)),
			"seed": 701,
		},
		{
			"a": Vector3(lerpf(x0, x1, 0.2), 0.03, lerpf(z0, z1, 0.82)),
			"b": Vector3(lerpf(x0, x1, 0.78), 0.03, lerpf(z0, z1, 0.22)),
			"seed": 809,
		},
		{
			"a": Vector3(lerpf(x0, x1, 0.05), 0.03, lerpf(z0, z1, 0.45)),
			"b": Vector3(lerpf(x0, x1, 0.95), 0.03, lerpf(z0, z1, 0.55)),
			"seed": 913,
		},
	]
	if GlesPerformanceScript.is_active():
		connectors = connectors.slice(0, 2)

	for c in connectors:
		var a: Vector3 = c.a
		var b: Vector3 = c.b
		# Tvinga starkare meander på connectors.
		_spawn_organic_road_strong(parent, a, b, int(c.seed), theme)


static func _spawn_organic_road_strong(
	parent: Node3D,
	start: Vector3,
	end: Vector3,
	path_seed: int,
	theme: Dictionary
) -> void:
	var span := end - start
	var length_m := maxf(span.length(), 4.0)
	var segments := maxi(int(ceil(length_m / 4.0)), 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = path_seed
	var waves := rng.randf_range(1.1, 2.2)
	var amp := rng.randf_range(10.0, 18.0)
	var phase := rng.randf_range(0.0, TAU)
	# Lateral = vinkelrät mot huvudriktningen.
	var along := span.normalized()
	var lateral_dir := Vector3(-along.z, 0.0, along.x)

	var points: Array[Vector3] = []
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var base := start.lerp(end, t)
		var m := sin(t * TAU * waves + phase) * amp
		m += sin(t * TAU * waves * 2.1 + phase * 0.7) * (amp * 0.28)
		points.append(base + lateral_dir * m + Vector3(0.0, 0.03, 0.0))

	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var mid := (a + b) * 0.5
		var dir := b - a
		dir.y = 0.0
		if dir.length_squared() < 0.0001:
			continue
		var yaw := atan2(dir.z, dir.x)
		var model := "road-straight"
		if i > 0:
			var prev: Vector3 = points[i] - points[i - 1]
			prev.y = 0.0
			if prev.length_squared() > 0.0001:
				var turn := absf(angle_difference(atan2(prev.z, prev.x), yaw))
				if turn > 0.35:
					model = "road-curve"
				elif turn > 0.2:
					model = "road-bend"
		CityKitLibrary.spawn(parent, "roads", model, mid, yaw)
		# Inga lyktor längs connectors — undvik stolpar mitt i korsande gator.


static func _cell_origin(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalog.BLOCK_M,
		0.0,
		float(cell.y) * DcZoneCatalog.BLOCK_M
	)


static func _grid_center_x() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.x_min + extent.x_max) * 0.5 * DcZoneCatalog.BLOCK_M


static func _grid_center_z() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.z_min + extent.z_max) * 0.5 * DcZoneCatalog.BLOCK_M


static func _grid_width_m() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.x_max - extent.x_min + 2) * DcZoneCatalog.BLOCK_M


static func _grid_depth_m() -> float:
	var extent: Dictionary = DcZoneCatalog.grid_extent()
	return float(extent.z_max - extent.z_min + 2) * DcZoneCatalog.BLOCK_M