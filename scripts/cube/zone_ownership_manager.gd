class_name ZoneOwnershipManagerNode
extends Node

signal zone_purchased(zone_id: String, owner_account: String, price: int)
signal zone_transferred(zone_id: String, from_account: String, to_account: String, reason: String)
signal ownership_changed(zone_id: String)

const DcZoneOwnershipCatalogScript = preload("res://scripts/cube/dc_zone_ownership_catalog.gd")
const ZoneOwnershipVisualsScript = preload("res://scripts/cube/zone_ownership_visuals.gd")
const SAVE_PATH_TEMPLATE := "user://zone_ownership_%s.json"
const NFT_POLL_INTERVAL_SEC := 45.0

var _character_id := ""
var _local_records: Dictionary = {}
var _nft_poll_timer := 0.0
var _http: HTTPRequest
var _pending_nft_zone_id := ""
var _markers_root: Node3D
var _active_spawn_id := ""
var _marker_nodes: Dictionary = {}


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 18.0
	add_child(_http)
	_http.request_completed.connect(_on_nft_request_completed)
	Profile.character_selected.connect(_on_character_selected)
	Profile.character_created.connect(_on_character_created)
	ownership_changed.connect(_on_ownership_changed)
	CubeRegistry.zone_registered.connect(_on_zone_registered)
	_on_character_selected()


func setup_world_visuals(parent: Node3D, spawn_id: String) -> void:
	_active_spawn_id = spawn_id
	if _markers_root != null and is_instance_valid(_markers_root):
		_markers_root.queue_free()
	_marker_nodes.clear()

	_markers_root = Node3D.new()
	_markers_root.name = "ZoneOwnershipMarkers"
	parent.add_child(_markers_root)
	refresh_all_markers()


func refresh_all_markers() -> void:
	if _markers_root == null or not is_instance_valid(_markers_root):
		return
	for zone_id in _marker_nodes.keys():
		var marker: Node3D = _marker_nodes[zone_id]
		if is_instance_valid(marker):
			marker.queue_free()
	_marker_nodes.clear()

	for zone_id in CubeRegistry.zones.keys():
		var entry: Dictionary = CubeRegistry.zones[zone_id]
		if str(entry.get("ownership", "")) == "owned":
			_upsert_marker(str(zone_id), entry)


func _upsert_marker(zone_id: String, entry: Dictionary) -> void:
	if _markers_root == null or not is_instance_valid(_markers_root):
		return
	if str(entry.get("ownership", "")) != "owned":
		_remove_marker(zone_id)
		return

	var world_pos := ZoneOwnershipVisualsScript.zone_id_to_world_position(zone_id, _active_spawn_id)
	if _marker_nodes.has(zone_id):
		var existing: Node3D = _marker_nodes[zone_id]
		if is_instance_valid(existing):
			ZoneOwnershipVisualsScript.update_marker(existing, entry)
			return

	var marker := ZoneOwnershipVisualsScript.build_marker(entry, world_pos, _active_spawn_id)
	_markers_root.add_child(marker)
	_marker_nodes[zone_id] = marker


func _remove_marker(zone_id: String) -> void:
	if not _marker_nodes.has(zone_id):
		return
	var marker: Node3D = _marker_nodes[zone_id]
	if is_instance_valid(marker):
		marker.queue_free()
	_marker_nodes.erase(zone_id)


func _on_ownership_changed(zone_id: String) -> void:
	var entry := get_zone_record(zone_id)
	_upsert_marker(zone_id, entry)


func _on_zone_registered(zone_id: String) -> void:
	var entry := CubeRegistry.get_zone(zone_id)
	if str(entry.get("ownership", "")) == "owned":
		_upsert_marker(zone_id, entry)


func _process(delta: float) -> void:
	if _character_id == "" or Auth.is_guest:
		return
	_nft_poll_timer += delta
	if _nft_poll_timer >= NFT_POLL_INTERVAL_SEC:
		_nft_poll_timer = 0.0
		_poll_visible_nft_claims()


func get_zone_at(world_pos: Vector3, spawn_id: String) -> Dictionary:
	var zone_id := DcZoneOwnershipCatalogScript.world_to_zone_id(world_pos, spawn_id)
	return get_zone_record(zone_id)


func get_zone_record(zone_id: String) -> Dictionary:
	if zone_id == "":
		return {}
	var entry := CubeRegistry.get_zone(zone_id)
	if entry.is_empty():
		entry = DcZoneOwnershipCatalogScript.make_zone_entry(zone_id)
		if not entry.is_empty():
			CubeRegistry.register_prototype_zone(entry)
	_apply_local_record(entry)
	return entry


func get_hud_hint(world_pos: Vector3, spawn_id: String) -> String:
	var entry := get_zone_at(world_pos, spawn_id)
	if entry.is_empty():
		return ""
	var zone_id := str(entry.get("zone_id", ""))
	var name := DcZoneOwnershipCatalogScript.get_zone_display_name(zone_id, entry)
	var ownership := str(entry.get("ownership", "public"))
	match ownership:
		"owned":
			var owner := str(entry.get("owner_account", "?"))
			var source := str(entry.get("purchase_source", "mydrillium"))
			var source_label := "NFT" if source == "nft" else "Mydrillium"
			if Auth.is_logged_in and owner == Auth.username:
				return "Din zon: %s [%s]" % [name, source_label]
			return "Ägd zon: %s (%s)" % [name, owner]
		"foundation", "reserved":
			return "%s — ej till salu" % name
		_:
			if not DcZoneOwnershipCatalogScript.is_purchasable(zone_id, entry):
				return "%s" % name
			var price := DcZoneOwnershipCatalogScript.get_purchase_price(zone_id)
			return "%s — köp [%d Mydrillium] [E]" % [name, price]


func try_interact_purchase(world_pos: Vector3, spawn_id: String) -> bool:
	var entry := get_zone_at(world_pos, spawn_id)
	if entry.is_empty():
		return false
	var zone_id := str(entry.get("zone_id", ""))
	if not DcZoneOwnershipCatalogScript.is_purchasable(zone_id, entry):
		return false
	if not Auth.is_logged_in or Auth.is_guest:
		QuestManager.story_toast.emit("Zonköp", "Logga in med konto för att köpa zoner.")
		return true
	var price := DcZoneOwnershipCatalogScript.get_purchase_price(zone_id)
	if price <= 0:
		return false
	if not InventoryManager.spend_mydrillium(price):
		QuestManager.story_toast.emit(
			"Zonköp",
			"Inte tillräckligt med %s. Behöver %d." % [ItemCatalog.currency_name(), price]
		)
		return true
	_apply_purchase(zone_id, Auth.username, "mydrillium", price)
	var display := DcZoneOwnershipCatalogScript.get_zone_display_name(zone_id, entry)
	QuestManager.story_toast.emit(
		"Zon köpt",
		"%s är din för %d %s.\nOm någon claimar zonen som NFT överförs äganderätten till dem."
		% [display, price, ItemCatalog.currency_name()]
	)
	zone_purchased.emit(zone_id, Auth.username, price)
	ownership_changed.emit(zone_id)
	return true


func try_nft_claim(zone_id: String, claimant_account: String, token_id: String = "") -> bool:
	if zone_id == "" or claimant_account.strip_edges() == "":
		return false
	var entry := get_zone_record(zone_id)
	if entry.is_empty():
		return false
	var previous_owner := str(entry.get("owner_account", ""))
	var previous_source := str(entry.get("purchase_source", ""))
	entry["ownership"] = "owned"
	entry["owner_account"] = claimant_account
	entry["purchase_source"] = "nft"
	entry["nft_token_id"] = token_id
	entry["nft_claimed_at"] = Time.get_datetime_string_from_system()
	if previous_owner != "" and previous_owner != claimant_account:
		entry["transferred_from"] = previous_owner
		entry["transferred_from_source"] = previous_source
		_save_local_record(zone_id, entry)
		CubeRegistry.register_prototype_zone(entry)
		_notify_nft_transfer(zone_id, previous_owner, claimant_account, entry)
		zone_transferred.emit(zone_id, previous_owner, claimant_account, "nft_claim")
	else:
		_save_local_record(zone_id, entry)
		CubeRegistry.register_prototype_zone(entry)
		QuestManager.story_toast.emit(
			"NFT-claim",
			"%s claimad som NFT av %s."
			% [DcZoneOwnershipCatalogScript.get_zone_display_name(zone_id, entry), claimant_account]
		)
	ownership_changed.emit(zone_id)
	return true


func request_nft_claim_check(zone_id: String) -> void:
	if zone_id == "" or Auth.is_guest or not Auth.is_logged_in:
		return
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_pending_nft_zone_id = zone_id
	var pricing := DcZoneOwnershipCatalogScript.load_pricing()
	var nft_cfg: Dictionary = pricing.get("nft", {})
	var template := str(nft_cfg.get("status_endpoint", "/zones/{zone_id}"))
	var path := template.replace("{zone_id}", zone_id.uri_encode())
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"User-Agent: CubeGodot/1.0",
	])
	var body := JSON.stringify({
		"token": Auth.session_token,
		"zone_id": zone_id,
		"character_id": _character_id,
	})
	_http.request(Auth.api_url + path, headers, HTTPClient.METHOD_POST, body)


func _apply_purchase(zone_id: String, owner_account: String, source: String, price: int) -> void:
	var entry := get_zone_record(zone_id)
	entry["ownership"] = "owned"
	entry["owner_account"] = owner_account
	entry["owner_character_id"] = _character_id
	entry["purchase_source"] = source
	entry["purchase_price"] = price
	entry["purchased_at"] = Time.get_datetime_string_from_system()
	_save_local_record(zone_id, entry)
	CubeRegistry.register_prototype_zone(entry)
	CubeRegistry.export_registry()


func _notify_nft_transfer(
	zone_id: String,
	previous_owner: String,
	claimant: String,
	entry: Dictionary
) -> void:
	var display := DcZoneOwnershipCatalogScript.get_zone_display_name(zone_id, entry)
	if Auth.is_logged_in and Auth.username == previous_owner:
		QuestManager.story_toast.emit(
			"NFT tog över din zon",
			"%s claimades som NFT av %s. Äganderätten har överförts."
			% [display, claimant]
		)
	elif Auth.is_logged_in and Auth.username == claimant:
		QuestManager.story_toast.emit(
			"NFT-claim lyckades",
			"Du äger nu %s via NFT-claim (överfört från %s)."
			% [display, previous_owner]
		)


func _poll_visible_nft_claims() -> void:
	if not get_tree():
		return
	for node in get_tree().get_nodes_in_group("game_director"):
		if not node.get("players") is Dictionary:
			continue
		var players: Dictionary = node.players
		var local_id := multiplayer.get_unique_id()
		if not players.has(local_id):
			continue
		var player: Node3D = players[local_id]
		var spawn_val = node.get("_active_spawn_id")
		var spawn_id: String = str(spawn_val) if spawn_val != null else ""
		if spawn_id == "":
			continue
		var entry := get_zone_at(player.global_position, spawn_id)
		var zone_id := str(entry.get("zone_id", ""))
		if zone_id == "":
			continue
		request_nft_claim_check(zone_id)


func _on_nft_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var zone_id := _pending_nft_zone_id
	_pending_nft_zone_id = ""
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data := parsed as Dictionary
	if not data.get("ok", false):
		return
	if not bool(data.get("nft_claim_pending", false)):
		return
	var claimant := str(data.get("nft_owner_account", ""))
	if claimant == "":
		return
	var token_id := str(data.get("nft_token_id", ""))
	try_nft_claim(zone_id, claimant, token_id)


func _on_character_selected() -> void:
	_load_for_character(Profile.active_character_id)


func _on_character_created(_character_id: String) -> void:
	_load_for_character(Profile.active_character_id)


func _load_for_character(character_id: String) -> void:
	_character_id = character_id.strip_edges()
	_local_records.clear()
	if _character_id == "":
		return
	var path := SAVE_PATH_TEMPLATE % _character_id
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_local_records = parsed.get("zones", {})
	for zone_id in _local_records.keys():
		var record: Dictionary = _local_records[zone_id]
		var entry := get_zone_record(str(zone_id))
		if str(record.get("owner_account", "")) == Auth.username:
			entry.merge(record, true)
			CubeRegistry.register_prototype_zone(entry)
	refresh_all_markers()


func _save_local_record(zone_id: String, entry: Dictionary) -> void:
	if _character_id == "":
		return
	_local_records[zone_id] = {
		"ownership": entry.get("ownership", "owned"),
		"owner_account": entry.get("owner_account", ""),
		"owner_character_id": entry.get("owner_character_id", _character_id),
		"purchase_source": entry.get("purchase_source", "mydrillium"),
		"purchase_price": entry.get("purchase_price", 0),
		"purchased_at": entry.get("purchased_at", ""),
		"nft_token_id": entry.get("nft_token_id", ""),
	}
	var path := SAVE_PATH_TEMPLATE % _character_id
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"character_id": _character_id,
		"zones": _local_records,
	}, "\t"))
	file.close()


func _apply_local_record(entry: Dictionary) -> void:
	var zone_id := str(entry.get("zone_id", ""))
	if zone_id == "" or not _local_records.has(zone_id):
		return
	var record: Dictionary = _local_records[zone_id]
	if str(record.get("owner_account", "")) != Auth.username:
		return
	entry.merge(record, true)