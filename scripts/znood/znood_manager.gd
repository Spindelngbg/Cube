class_name ZnoodManagerNode
extends Node

signal device_open_changed(open: bool)
signal waypoint_changed(active: bool, position: Vector3)
signal search_results_changed(results: Array)
signal backup_pings_changed()
signal map_picker_changed(active: bool)

const BACKUP_DURATION_SEC := 45.0
const ZEZZLOR_BACKUP_DURATION_SEC := 30.0

var device_open := false
var map_picker_active := false
var spawn_id := ""

var has_waypoint := false
var waypoint := Vector3.ZERO

var _pois: Array = []
var _search_results: Array = []
var _search_query := ""
var _joined_groups: Array = []
var _backup_pings: Array = []
var _blink_phase := 0.0


func _ready() -> void:
	for group_id in ZnoodGroupCatalog.all_ids():
		if group_id == "colony_patrol":
			_joined_groups.append(group_id)


func _process(delta: float) -> void:
	_blink_phase += delta * 5.0
	_prune_backup_pings()


func configure_spawn(active_spawn_id: String) -> void:
	spawn_id = SpawnPoints.normalize_id(active_spawn_id)
	clear_pois()
	has_waypoint = false
	waypoint = Vector3.ZERO
	_search_results.clear()
	_search_query = ""
	_backup_pings.clear()
	waypoint_changed.emit(false, Vector3.ZERO)
	search_results_changed.emit(_search_results)
	backup_pings_changed.emit()


func clear_pois() -> void:
	_pois.clear()


func register_poi(poi: Dictionary) -> void:
	var entry := poi.duplicate(true)
	entry["world_position"] = poi.get("world_position", Vector3.ZERO)
	entry["id"] = str(poi.get("id", ""))
	if entry["id"] == "":
		return
	for existing in _pois:
		if str(existing.get("id", "")) == entry["id"]:
			return
	_pois.append(entry)


func ingest_markers_from_tree(root: Node) -> void:
	if root == null:
		return
	for node in root.get_tree().get_nodes_in_group("znood_poi"):
		if node is ZnoodPoiMarker:
			var marker := node as ZnoodPoiMarker
			register_poi({
				"id": marker.poi_id if marker.poi_id != "" else marker.get_path(),
				"name": marker.display_name,
				"category": marker.category,
				"keywords": marker.keywords,
				"world_position": marker.global_transform.origin,
				"color": marker.map_color,
			})


func get_pois() -> Array:
	return _pois.duplicate(true)


func get_search_results() -> Array:
	return _search_results.duplicate(true)


func get_visible_pois() -> Array:
	if _search_results.is_empty():
		return get_pois()
	return _search_results.duplicate(true)


func search(query: String) -> Array:
	_search_query = query.strip_edges().to_lower()
	_search_results.clear()
	if _search_query == "":
		search_results_changed.emit(_search_results)
		return _search_results

	for poi in _pois:
		var name_text := str(poi.get("name", "")).to_lower()
		var category_text := str(poi.get("category", "")).to_lower()
		var keywords: Variant = poi.get("keywords", [])
		var matched := _search_query in name_text or _search_query in category_text
		if not matched and typeof(keywords) == TYPE_PACKED_STRING_ARRAY:
			for keyword in keywords:
				if _search_query in str(keyword).to_lower():
					matched = true
					break
		if matched:
			_search_results.append(poi.duplicate(true))

	search_results_changed.emit(_search_results)
	return _search_results


func clear_search() -> void:
	_search_query = ""
	_search_results.clear()
	search_results_changed.emit(_search_results)


func set_waypoint(world_position: Vector3) -> void:
	waypoint = world_position
	has_waypoint = true
	waypoint_changed.emit(true, waypoint)


func clear_waypoint() -> void:
	has_waypoint = false
	waypoint = Vector3.ZERO
	waypoint_changed.emit(false, Vector3.ZERO)


func set_map_picker_active(active: bool) -> void:
	if map_picker_active == active:
		return
	map_picker_active = active
	map_picker_changed.emit(active)


func toggle_device() -> void:
	set_device_open(not device_open)


func set_device_open(open: bool) -> void:
	if device_open == open:
		return
	device_open = open
	if not device_open:
		set_map_picker_active(false)
	device_open_changed.emit(device_open)


func get_joined_groups() -> Array:
	return _joined_groups.duplicate()


func has_joined_group(group_id: String) -> bool:
	return group_id in _joined_groups


func toggle_group(group_id: String) -> void:
	if group_id in _joined_groups:
		_joined_groups.erase(group_id)
	else:
		_joined_groups.append(group_id)


func get_backup_pings_for_local() -> Array:
	var local_id := multiplayer.get_unique_id()
	var visible: Array = []
	for ping in _backup_pings:
		var kind := str(ping.get("kind", "backup"))
		if kind == "zezzlor":
			visible.append(ping)
			continue
		var peer_id := int(ping.get("peer_id", -1))
		if peer_id == local_id:
			visible.append(ping)
			continue
		var ping_groups: Array = ping.get("groups", [])
		for group_id in _joined_groups:
			if group_id in ping_groups:
				visible.append(ping)
				break
	return visible


func add_backup_ping(
	peer_id: int,
	world_position: Vector3,
	label: String,
	groups: Array,
	duration_sec: float,
	kind: String = "backup"
) -> void:
	_backup_pings.append({
		"peer_id": peer_id,
		"position": world_position,
		"label": label,
		"groups": groups.duplicate(),
		"expires_at": Time.get_ticks_msec() + int(duration_sec * 1000.0),
		"kind": kind,
	})
	backup_pings_changed.emit()


func get_blink_alpha() -> float:
	return 0.45 + absf(sin(_blink_phase)) * 0.55


func request_zezzlor_backup(world_position: Vector3, trouble_direction: Vector3 = Vector3.ZERO) -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("broadcast_znood_zezzlor_call"):
		game.broadcast_znood_zezzlor_call(world_position, trouble_direction)


func request_group_backup(world_position: Vector3) -> void:
	if _joined_groups.is_empty():
		return
	var game := get_tree().get_first_node_in_group("game_director")
	if game and game.has_method("broadcast_znood_group_backup"):
		game.broadcast_znood_group_backup(world_position, _joined_groups.duplicate())


func _prune_backup_pings() -> void:
	var now := Time.get_ticks_msec()
	var changed := false
	var kept: Array = []
	for ping in _backup_pings:
		if int(ping.get("expires_at", 0)) > now:
			kept.append(ping)
		else:
			changed = true
	if changed:
		_backup_pings = kept
		backup_pings_changed.emit()
