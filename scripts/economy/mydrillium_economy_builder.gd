class_name MydrilliumEconomyBuilder
extends RefCounted

const HarvestNodeScript = preload("res://scripts/economy/mydrillium_harvest_node.gd")
const ServiceStationScript = preload("res://scripts/economy/mydrillium_service_station.gd")
const ZnoodPoiMarkerScript = preload("res://scripts/znood/znood_poi_marker.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const MINERAL_GREEN := Color(0.22, 0.88, 0.42)
const TRADE_AMBER := Color(0.95, 0.72, 0.28)
const SRC_PURPLE := Color(0.68, 0.28, 0.92)


static func build_dc_economy(parent: Node3D, trade_ui: MydrilliumTradeUI) -> Node3D:
	var root := Node3D.new()
	root.name = "MydrilliumEconomy"
	parent.add_child(root)

	var spawn := FuturisticDcCityBuilder.get_spawn_center()
	_place_station(root, spawn + Vector3(8.0, 0.0, 18.0), "colony_hub", "Koloni-mineralhub", trade_ui)
	_place_station(root, spawn + Vector3(-28.0, 0.0, 22.0), "refinery", "Neo-Washington Raffinaderi", trade_ui)
	_place_station(root, _dc_cell_center(Vector2i(-3, 0)) + Vector3(12.0, 0.0, -8.0), "trade_post", "Mineralhandel — Nationalmallen", trade_ui)
	_place_station(root, _dc_cell_center(Vector2i(-4, -3)) + Vector3(6.0, 0.0, -4.0), "src_contract", "SRC Gråzons-kontrakt", trade_ui, "dc_annex")
	_place_station(root, _dc_cell_center(Vector2i(-1, 2)) + Vector3(-10.0, 0.0, 8.0), "drill_rental", "Borrlicens — Industrikaj", trade_ui, "dc_industrial")

	_scatter_harvest_nodes(root)
	_add_sign(root, spawn + Vector3(4.0, 2.8, 8.0), "MYDRILLIUM →\nHacka malm, raffinera, tjäna Md")
	return root


static func build_hub_economy(parent: Node3D, trade_ui: MydrilliumTradeUI, spawn_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "MydrilliumEconomy"
	parent.add_child(root)

	_place_station(root, Vector3(14.0, 0.0, 16.0), "refinery", "Ankomst-raffinaderi", trade_ui)
	_place_station(root, Vector3(-10.0, 0.0, 12.0), "colony_hub", "Koloni-mineralpost", trade_ui)
	_place_harvest(
		root,
		Vector3(18.0, 0.0, -8.0),
		"raw_mydrillium_ore",
		"Hacka väggmalm [E]"
	)
	_place_harvest(
		root,
		Vector3(-16.0, 0.0, -6.0),
		"tech_scrap",
		"Samla skrot [E]"
	)
	_add_sign(root, Vector3(0.0, 2.5, 6.0), "Mineralstation — tjäna %s" % ItemCatalog.currency_symbol())
	return root


static func _scatter_harvest_nodes(parent: Node3D) -> void:
	var spots := [
		{"pos": _dc_cell_center(Vector2i(0, 0)) + Vector3(-12.0, 0.0, 14.0), "material": "raw_mydrillium_ore", "prompt": "Hacka spawn-malm [E]"},
		{"pos": _dc_cell_center(Vector2i(-5, 1)) + Vector3(4.0, 0.0, -6.0), "material": "raw_mydrillium_ore", "prompt": "Hacka kub-malm [E]"},
		{"pos": _dc_cell_center(Vector2i(2, -2)) + Vector3(-8.0, 0.0, 5.0), "material": "tech_scrap", "prompt": "Samla tech-skrot [E]"},
		{"pos": _dc_cell_center(Vector2i(-2, 4)) + Vector3(10.0, 0.0, -4.0), "material": "tech_scrap", "prompt": "Industriskrot [E]"},
		{"pos": _dc_cell_center(Vector2i(-4, -3)) + Vector3(-6.0, 0.0, 8.0), "material": "contaminated_ore", "prompt": "Gräv kontaminerad malm [E]"},
		{"pos": _dc_cell_center(Vector2i(-6, 0)) + Vector3(8.0, 0.0, -10.0), "material": "raw_mydrillium_ore", "prompt": "Memorial-malm [E]"},
	]
	for entry in spots:
		_place_harvest(
			parent,
			entry.pos,
			str(entry.material),
			str(entry.prompt)
		)


static func _place_station(
	parent: Node3D,
	pos: Vector3,
	kind: String,
	title: String,
	trade_ui: MydrilliumTradeUI,
	zone_id: String = ""
) -> MydrilliumServiceStation:
	var station: MydrilliumServiceStation = ServiceStationScript.new()
	station.name = title.replace(" ", "")
	station.position = pos
	station.station_kind = kind
	station.zone_id = zone_id
	station.display_name = title
	station.setup(trade_ui)
	parent.add_child(station)
	_build_station_shell(station, kind, title)
	WorldCollisionBuilderScript.attach_box(station, Vector3(3.2, 2.6, 2.4), Vector3(0.0, 1.4, 0.0))

	var marker: ZnoodPoiMarker = ZnoodPoiMarkerScript.new()
	marker.name = "PoiMarker"
	marker.poi_id = "mydrillium_%s" % kind
	marker.display_name = title
	marker.category = "economy"
	marker.keywords = PackedStringArray(["mydrillium", "mineral", "malm", kind])
	marker.map_color = _station_color(kind)
	station.add_child(marker)
	return station


static func _place_harvest(parent: Node3D, pos: Vector3, material_id: String, prompt: String) -> void:
	var node: MydrilliumHarvestNode = HarvestNodeScript.new()
	node.material_id = material_id
	node.prompt_text = prompt
	node.position = pos
	parent.add_child(node)


static func _build_station_shell(station: MydrilliumServiceStation, kind: String, title: String) -> void:
	var color := _station_color(kind)
	var platform := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.4
	mesh.bottom_radius = 2.6
	mesh.height = 0.2
	platform.mesh = mesh
	platform.position = Vector3(0.0, 0.1, 0.0)
	var platform_mat := StandardMaterial3D.new()
	platform_mat.albedo_color = Color(0.12, 0.13, 0.16)
	platform.material_override = platform_mat
	station.add_child(platform)

	var kiosk := MeshInstance3D.new()
	var kiosk_mesh := BoxMesh.new()
	kiosk_mesh.size = Vector3(3.2, 2.6, 2.4)
	kiosk.mesh = kiosk_mesh
	kiosk.position = Vector3(0.0, 1.4, 0.0)
	var kiosk_mat := StandardMaterial3D.new()
	kiosk_mat.albedo_color = color.darkened(0.35)
	kiosk_mat.emission_enabled = true
	kiosk_mat.emission = color
	kiosk_mat.emission_energy_multiplier = 0.4
	kiosk.material_override = kiosk_mat
	station.add_child(kiosk)

	var sign := Label3D.new()
	sign.text = title
	sign.font_size = 24
	sign.modulate = color.lightened(0.1)
	sign.position = Vector3(0.0, 3.2, 0.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.add_child(sign)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 3.2, 4.0)
	shape.shape = box
	shape.position = Vector3(0.0, 1.6, 0.0)
	station.add_child(shape)


static func _station_color(kind: String) -> Color:
	match kind:
		"refinery":
			return MINERAL_GREEN
		"trade_post", "colony_hub":
			return TRADE_AMBER
		"src_contract":
			return SRC_PURPLE
		"drill_rental":
			return Color(0.45, 0.72, 0.95)
		_:
			return MINERAL_GREEN


static func _add_sign(parent: Node3D, pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 26
	label.modulate = MINERAL_GREEN.lightened(0.15)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _dc_cell_center(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalog.BLOCK_M + DcZoneCatalog.BLOCK_M * 0.5,
		0.0,
		float(cell.y) * DcZoneCatalog.BLOCK_M + DcZoneCatalog.BLOCK_M * 0.5
	)