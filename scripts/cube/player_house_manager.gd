extends Node

## Sparar och bygger spelarens hus på egna zoner.

signal houses_changed

const PlayerHouseBuilderScript = preload("res://scripts/cube/player_house_builder.gd")
const PlayerHouseCatalogScript = preload("res://scripts/cube/player_house_catalog.gd")
const DcZoneOwnershipCatalogScript = preload("res://scripts/cube/dc_zone_ownership_catalog.gd")
const ZoneOwnershipVisualsScript = preload("res://scripts/cube/zone_ownership_visuals.gd")

var _houses: Dictionary = {} # zone_id -> {house_id, spawn_id, extra_zones:[]}
var _save_slot := "guest"
var _houses_root: Node3D
var _active_spawn_id := ""
var _built_nodes: Dictionary = {}


func _ready() -> void:
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()


func setup_world(parent: Node3D, spawn_id: String) -> void:
	_active_spawn_id = SpawnPoints.normalize_id(spawn_id)
	if _houses_root != null and is_instance_valid(_houses_root):
		_houses_root.queue_free()
	_built_nodes.clear()
	_houses_root = Node3D.new()
	_houses_root.name = "PlayerHouses"
	parent.add_child(_houses_root)
	_rebuild_all_visuals()


func get_house_on_zone(zone_id: String) -> Dictionary:
	return _houses.get(zone_id, {})


func has_house_on_zone(zone_id: String) -> bool:
	return _houses.has(zone_id)


func get_owned_zone_ids() -> Array[String]:
	var result: Array[String] = []
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr == null:
		return result
	# Sök i sparade lokala records via CubeRegistry owned zones.
	for zone_id in CubeRegistry.zones.keys():
		var entry: Dictionary = CubeRegistry.zones[zone_id]
		if str(entry.get("ownership", "")) != "owned":
			continue
		if not Auth.is_logged_in or str(entry.get("owner_account", "")) != Auth.username:
			continue
		result.append(str(zone_id))
	return result


func can_build_house(house_id: String, anchor_zone_id: String) -> Dictionary:
	var house := PlayerHouseCatalogScript.get_house(house_id)
	if house.is_empty():
		return {"ok": false, "reason": "Okänd hustyp."}
	if not Auth.is_logged_in or Auth.is_guest:
		return {"ok": false, "reason": "Logga in för att bygga hus."}
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr == null or not zone_mgr.has_method("_player_owns_zone"):
		# Använd publik API
		pass
	if not _player_owns(anchor_zone_id):
		return {"ok": false, "reason": "Du äger inte den här zonen."}
	if _houses.has(anchor_zone_id):
		return {"ok": false, "reason": "Det finns redan ett hus här. Riv först (kommer snart)."}

	var footprint := PlayerHouseCatalogScript.get_footprint(house_id)
	var needed := _footprint_zone_ids(anchor_zone_id, footprint)
	if needed.is_empty():
		return {"ok": false, "reason": "Kunde inte beräkna tomter för huset."}
	if needed.size() < PlayerHouseCatalogScript.get_zones_required(house_id):
		return {
			"ok": false,
			"reason": "Behöver %d zoner i en kvadrat — hitta en hörnzon du äger."
			% PlayerHouseCatalogScript.get_zones_required(house_id),
		}
	for zid in needed:
		if not _player_owns(zid):
			return {
				"ok": false,
				"reason": "Du måste äga alla %d zoner i 2×2-rutan för mansion."
				% PlayerHouseCatalogScript.get_zones_required(house_id),
			}
		if _houses.has(zid) and zid != anchor_zone_id:
			return {"ok": false, "reason": "En av zonerna har redan ett hus."}

	var price := PlayerHouseCatalogScript.get_price(house_id)
	if InventoryManager.get_mydrillium() < price:
		return {
			"ok": false,
			"reason": "Du behöver %d %s." % [price, ItemCatalog.currency_symbol()],
		}
	return {"ok": true, "zones": needed, "price": price}


func try_build_house(house_id: String, anchor_zone_id: String, spawn_id: String) -> bool:
	var check := can_build_house(house_id, anchor_zone_id)
	if not bool(check.get("ok", false)):
		QuestManager.story_toast.emit("Husbygge", str(check.get("reason", "Kunde inte bygga.")))
		return false
	var price := int(check.get("price", 0))
	var zones: Array = check.get("zones", [anchor_zone_id])
	if not InventoryManager.spend_mydrillium(price):
		QuestManager.story_toast.emit("Husbygge", "Inte råd just nu.")
		return false

	_houses[anchor_zone_id] = {
		"house_id": house_id,
		"spawn_id": SpawnPoints.normalize_id(spawn_id),
		"extra_zones": zones.filter(func(z): return str(z) != anchor_zone_id),
		"built_at": Time.get_datetime_string_from_system(),
	}
	# Markera extra zoner som upptagna av samma hus.
	for zid in zones:
		if str(zid) == anchor_zone_id:
			continue
		_houses[str(zid)] = {
			"house_id": house_id,
			"spawn_id": SpawnPoints.normalize_id(spawn_id),
			"anchor": anchor_zone_id,
			"is_extension": true,
		}
	_save()
	_spawn_house_visual(anchor_zone_id)
	houses_changed.emit()
	QuestManager.story_toast.emit(
		"Hus byggt!",
		"%s står nu på din tomt." % PlayerHouseCatalogScript.get_display_name(house_id)
	)
	return true


func _spawn_house_visual(anchor_zone_id: String) -> void:
	if _houses_root == null or not is_instance_valid(_houses_root):
		return
	var data: Dictionary = _houses.get(anchor_zone_id, {})
	if data.is_empty() or bool(data.get("is_extension", false)):
		return
	var house_id := str(data.get("house_id", "tent"))
	var spawn_id := str(data.get("spawn_id", _active_spawn_id))
	if spawn_id != _active_spawn_id and _active_spawn_id != "":
		return
	if _built_nodes.has(anchor_zone_id):
		var old: Node = _built_nodes[anchor_zone_id]
		if is_instance_valid(old):
			old.queue_free()
		_built_nodes.erase(anchor_zone_id)

	var center := ZoneOwnershipVisualsScript.zone_id_to_world_position(anchor_zone_id, spawn_id)
	center.y = SpawnPoints.SPAWN_FOOT_Y
	# För 2×2 mansion: centrera i mitten av fotavtrycket.
	var footprint := PlayerHouseCatalogScript.get_footprint(house_id)
	if footprint >= 2:
		center = _footprint_center(anchor_zone_id, footprint, spawn_id)

	var node := PlayerHouseBuilderScript.build(_houses_root, house_id, center, 0.0)
	_built_nodes[anchor_zone_id] = node


func _rebuild_all_visuals() -> void:
	if _houses_root == null:
		return
	for zone_id in _houses.keys():
		var data: Dictionary = _houses[zone_id]
		if bool(data.get("is_extension", false)):
			continue
		if str(data.get("spawn_id", "")) != "" and str(data.get("spawn_id", "")) != _active_spawn_id:
			continue
		_spawn_house_visual(str(zone_id))


func _player_owns(zone_id: String) -> bool:
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr != null and zone_mgr.has_method("get_zone_record"):
		var entry: Dictionary = zone_mgr.get_zone_record(zone_id)
		return (
			str(entry.get("ownership", "")) == "owned"
			and Auth.is_logged_in
			and str(entry.get("owner_account", "")) == Auth.username
		)
	return false


func _footprint_zone_ids(anchor_zone_id: String, footprint: int) -> Array[String]:
	var result: Array[String] = []
	var parsed := CubeZoneId.parse(anchor_zone_id)
	if parsed.is_empty():
		return result
	var layer: int = int(parsed.get("layer", CubeConstants.PROTOTYPE_LAYER))
	var block: Vector2i = parsed.get("block", Vector2i.ZERO)
	var zone: Vector2i = parsed.get("zone", Vector2i.ZERO)
	if footprint <= 1:
		result.append(anchor_zone_id)
		return result
	# 2×2: använd zon som nedre-vänster hörn inom blocket om möjligt.
	var max_z := CubeConstants.PROTOTYPE_ZONES_PER_BLOCK - 1
	if zone.x > max_z - 1 or zone.y > max_z - 1:
		# Justera till hörn om spelaren står i övre kanten.
		zone = Vector2i(mini(zone.x, max_z - 1), mini(zone.y, max_z - 1))
	for dx in range(footprint):
		for dy in range(footprint):
			var z := Vector2i(zone.x + dx, zone.y + dy)
			if z.x > max_z or z.y > max_z:
				return [] as Array[String]
			result.append(CubeZoneId.make(layer, block, z))
	return result


func _footprint_center(anchor_zone_id: String, footprint: int, spawn_id: String) -> Vector3:
	var ids := _footprint_zone_ids(anchor_zone_id, footprint)
	if ids.is_empty():
		return ZoneOwnershipVisualsScript.zone_id_to_world_position(anchor_zone_id, spawn_id)
	var sum := Vector3.ZERO
	for zid in ids:
		sum += ZoneOwnershipVisualsScript.zone_id_to_world_position(str(zid), spawn_id)
	var center := sum / float(ids.size())
	center.y = SpawnPoints.SPAWN_FOOT_Y
	return center


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	if slot == _save_slot and not _houses.is_empty():
		return
	_save_slot = slot
	_load()


func _save_path() -> String:
	return "user://player_houses_%s.json" % _save_slot


func _load() -> void:
	_houses.clear()
	if not FileAccess.file_exists(_save_path()):
		return
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_houses = parsed.duplicate(true)


func _save() -> void:
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_houses, "\t"))
