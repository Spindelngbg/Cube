class_name StoryWorldBuilder
extends RefCounted

const Lore = preload("res://scripts/story/shawshank_lore.gd")
const ZnoodDoorBuilderScript = preload("res://scripts/access/znood_door_builder.gd")
const ItemPickupScript = preload("res://scripts/items/item_pickup.gd")
const SrcHqBuilderScript = preload("res://scripts/story/src_hq_builder.gd")

const TOWER_FLOORS := 6
const BUILDING_KIT_SCALE := 2.0


static func build(parent: Node3D, spawn_id: String) -> Node3D:
	var id := SpawnPoints.normalize_id(spawn_id)
	if id != "satellite_right":
		return null
	return FuturisticDcCityBuilder.build(parent, SpawnPoints.get_position(id), id)


static func build_annex_at(parent: Node3D, pos: Vector3) -> void:
	var hq := SrcHqBuilderScript.build_shell(parent, pos)
	var entrance := SrcHqBuilderScript.entrance_position()
	var lobby := SrcHqBuilderScript.lobby_center()

	ZnoodDoorBuilderScript.place(
		hq,
		entrance,
		Vector3(5.5, 3.4, 0.35),
		"src_annex_door",
		0.0,
		"Stämpla Znood vid SRC HQ [E]"
	)

	var spec: Dictionary = DcZoneCatalog.classify_cell(Vector2i(-4, -3))
	var sign := Label3D.new()
	sign.text = "%s\n%s" % [spec.get("tag", ""), Lore.hq_sign()]
	sign.font_size = 64
	sign.modulate = Color(0.94, 0.90, 0.82)
	sign.outline_modulate = Color(0.12, 0.14, 0.18, 0.95)
	sign.position = SrcHqBuilderScript.hq_sign_position()
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hq.add_child(sign)

	SpaceKitLibrary.spawn(hq, "room-large", lobby + Vector3(0.0, 0.0, 8.0))
	SpaceKitLibrary.spawn(hq, "corridor-wide", lobby + Vector3(0.0, 0.0, 18.0))

	_add_interactable(
		hq,
		"src_annex_entry",
		entrance + Vector3(0.0, 1.4, 4.0),
		Vector3(6.0, 3.0, 5.0),
		"Granska SRC HQ [E]"
	)
	_add_terminal(hq, "src_terminal_a", lobby + Vector3(-20.0, 0.0, 6.0), "Terminal A [E]")
	_add_terminal(hq, "src_terminal_b", lobby + Vector3(20.0, 0.0, 6.0), "Terminal B [E]")
	_add_terminal(hq, "src_terminal_c", lobby + Vector3(0.0, 0.0, 14.0), "Terminal C [E]")
	_add_console(hq, lobby + Vector3(0.0, 0.0, 24.0))
	_add_item_pickup(
		hq,
		"psyxxrum_serum",
		lobby + Vector3(24.0, 0.0, 10.0),
		"Plocka upp Psyxxrum-Serumet [E]"
	)
	_add_item_pickup(
		hq,
		"redemption_tonic",
		lobby + Vector3(-24.0, 0.0, 10.0),
		"Plocka upp Redemption-tonic [E]"
	)


static func build_hybrid_towers(parent: Node3D, tower_a_origin: Vector3, tower_b_origin: Vector3) -> void:
	_build_highrise(parent, tower_a_origin, 0.0, "Tower_A", "SRC BOSTADSTORNET A")
	_build_highrise(
		parent,
		tower_b_origin + Vector3(DcZoneCatalog.BLOCK_M * 0.5, 0.0, DcZoneCatalog.BLOCK_M * 0.5),
		PI * 0.5,
		"Tower_B",
		"SRC BOSTADSTORNET B"
	)


static func place_warning_sign(parent: Node3D, pos: Vector3) -> void:
	var sign := Label3D.new()
	sign.text = (
		"VARNING — FÖRETAGSZON\n%s\nRapporter om hybridzombies i området"
		% Lore.COMPANY_NAME
	)
	sign.font_size = 48
	sign.modulate = Color(0.98, 0.82, 0.35)
	sign.position = pos + Vector3(0.0, 4.0, 0.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(sign)


static func _build_highrise(
	parent: Node3D,
	origin: Vector3,
	rotation_y: float,
	tower_name: String,
	label_text: String
) -> void:
	var tower := Node3D.new()
	tower.name = tower_name
	tower.position = origin
	tower.rotation.y = rotation_y
	parent.add_child(tower)

	for floor_index in range(TOWER_FLOORS):
		var y := float(floor_index) * 2.0 * BUILDING_KIT_SCALE
		_stack_floor(tower, y, BUILDING_KIT_SCALE)
		if floor_index == 0:
			CityKitLibrary.spawn(
				tower, "building", "wall-doorway-square",
				Vector3(0, y, 5.5 * BUILDING_KIT_SCALE), 0.0, BUILDING_KIT_SCALE
			)
			ZnoodDoorBuilderScript.place(
				tower,
				Vector3(0.0, y, 5.2 * BUILDING_KIT_SCALE),
				Vector3(2.2, 2.3, 0.35),
				"%s_entrance" % tower_name.to_lower(),
				rotation_y,
				"Stämpla Znood vid torn [E]"
			)
		else:
			CityKitLibrary.spawn(
				tower, "building", "stairs-open",
				Vector3(-2.0 * BUILDING_KIT_SCALE, y, 2.0 * BUILDING_KIT_SCALE), 0.0, BUILDING_KIT_SCALE
			)

	var roof_label := Label3D.new()
	roof_label.text = "%s\n(gå in och vandra mellan våningarna)" % label_text
	roof_label.font_size = 36
	roof_label.modulate = Color(0.95, 0.35, 0.32)
	roof_label.position = Vector3(0.0, float(TOWER_FLOORS) * 2.0 * BUILDING_KIT_SCALE + 2.0, 0.0)
	roof_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tower.add_child(roof_label)

	var spec := {
		"zone_type": "KONTORSGRID",
		"tag": "[KONTORSGRID] %s" % label_text,
	}
	FuturisticDcCityBuilder._add_zone_marker(tower, Vector3(2.0, 0.0, 2.0), spec, true)


static func _stack_floor(parent: Node3D, y: float, kit_scale: float) -> void:
	var tile := 2.0 * kit_scale
	var offsets := [
		Vector3(0, 0, 0),
		Vector3(tile, 0, 0),
		Vector3(0, 0, tile),
		Vector3(tile, 0, tile),
	]
	for offset in offsets:
		CityKitLibrary.spawn(parent, "building", "floor", Vector3(offset.x, y, offset.z), 0.0, kit_scale)
	for x in range(5):
		CityKitLibrary.spawn(parent, "building", "wall", Vector3(x * tile, y, -0.5 * kit_scale), 0.0, kit_scale)
		CityKitLibrary.spawn(parent, "building", "wall", Vector3(x * tile, y, 4.5 * kit_scale), 0.0, kit_scale)
	for z in range(5):
		CityKitLibrary.spawn(parent, "building", "wall", Vector3(-0.5 * kit_scale, y, z * tile), 0.0, kit_scale)
		CityKitLibrary.spawn(parent, "building", "wall", Vector3(4.5 * kit_scale, y, z * tile), 0.0, kit_scale)


static func _add_terminal(parent: Node3D, interact_id: String, pos: Vector3, label_text: String) -> void:
	SciFiEssentialsLibrary.spawn(parent, "Prop_Desk_Small", pos)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 36
	label.modulate = Color(0.55, 0.95, 0.45)
	label.position = pos + Vector3(0.0, 1.8, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	_add_interactable(parent, interact_id, pos + Vector3(0.0, 1.0, 0.0), Vector3(2.0, 2.0, 2.0), label_text)


static func _add_console(parent: Node3D, pos: Vector3) -> void:
	SciFiEssentialsLibrary.spawn(parent, "Prop_Desk_Medium", pos)
	var screen := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.2, 0.8, 0.08)
	screen.mesh = mesh
	screen.position = pos + Vector3(0.0, 1.1, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.05, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.15, 0.1)
	mat.emission_energy_multiplier = 0.8
	screen.material_override = mat
	parent.add_child(screen)

	var label := Label3D.new()
	label.text = "REDEMPTION SYNC — HUVUDKONSOL [E]"
	label.font_size = 34
	label.modulate = Color(1.0, 0.25, 0.2)
	label.position = pos + Vector3(0.0, 2.2, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	_add_interactable(
		parent,
		"src_main_console",
		pos + Vector3(0.0, 1.2, 0.0),
		Vector3(2.4, 2.2, 2.0),
		"Sabotera huvudkonsol [E]"
	)


static func _add_item_pickup(
	parent: Node3D,
	item_id: String,
	pos: Vector3,
	prompt: String
) -> ItemPickup:
	var pickup: ItemPickup = ItemPickupScript.new()
	pickup.item_id = item_id
	pickup.prompt_text = prompt
	pickup.position = pos
	parent.add_child(pickup)
	return pickup


static func _add_interactable(
	parent: Node3D,
	interact_id: String,
	pos: Vector3,
	size: Vector3,
	prompt: String
) -> StoryInteractable:
	var area := StoryInteractable.new()
	area.interact_id = interact_id
	area.prompt_text = prompt
	area.position = pos
	parent.add_child(area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	return area