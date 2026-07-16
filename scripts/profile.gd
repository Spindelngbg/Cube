@warning_ignore("inference_on_variant", "untyped_declaration")
extends Node

const FALLBACK_MESH_IDS: PackedStringArray = [
	"character-a", "character-b", "character-c",
	"character-d", "character-e", "character-f",
]

signal characters_loaded()
signal character_selected()
signal character_created(character_id: String)
signal character_saved()
signal nest_intro_completed()
signal home_spawn_set(spawn_id: String)
signal operation_failed(message: String)
signal profile_progress(phase: String, detail: String)

const REQUEST_TIMEOUT_SEC := 20.0

var avatar: AvatarData = AvatarData.new()
var avatar_ready := false
var active_avatar_configured := false
var characters: Array = []
var active_character_id: String = ""
var active_character_name: String = ""
var active_nest_visited := true
var active_home_spawn_id := ""
var active_home_spawn_locked := false
var character_limit: int = 6
var unlimited_slots := false

var _http := HTTPRequest.new()
var _pending_action := ""
var _busy := false
var _list_synced := false
var _send_id := 0
var _inflight_send_id := 0


func _ready() -> void:
	add_child(_http)
	_http.timeout = REQUEST_TIMEOUT_SEC
	_http.request_completed.connect(_on_request_completed)


func set_avatar(data: AvatarData) -> void:
	avatar = data.duplicate_data()
	avatar_ready = true


func get_avatar() -> AvatarData:
	return avatar.duplicate_data()


func clear_characters() -> void:
	cancel_request()
	characters.clear()
	active_character_id = ""
	active_character_name = ""
	active_nest_visited = false
	active_home_spawn_id = ""
	active_home_spawn_locked = false
	avatar = AvatarData.new()
	avatar_ready = false
	active_avatar_configured = false
	_busy = false
	_list_synced = false


func cancel_request() -> void:
	if _busy:
		_http.cancel_request()
	_busy = false
	_inflight_send_id = 0
	_send_id += 1


func characters_list_ready() -> bool:
	return _list_synced


func load_characters() -> void:
	if _busy:
		cancel_request()
	_emit_progress("list_start", "Hämtar karaktärslista")
	_post("/characters/list", {}, "list")


func create_character(name: String = "") -> void:
	_emit_progress("create_start", "Skapar karaktär \"%s\"" % name.strip_edges())
	_post("/characters/create", { "name": name.strip_edges() }, "create")


func save_active_character(data: AvatarData) -> void:
	if active_character_id == "":
		operation_failed.emit("Ingen karaktär vald")
		return
	_post("/characters/save", {
		"id": active_character_id,
		"avatar": data.to_dict(),
	}, "save")


func select_character(character_id: String) -> void:
	_post("/characters/select", { "id": character_id }, "select")


func delete_character(character_id: String) -> void:
	_post("/characters/delete", { "id": character_id }, "delete")


func needs_nest_intro() -> bool:
	return not Auth.is_guest and not active_nest_visited


func needs_home_selection() -> bool:
	return not Auth.is_guest and active_nest_visited and not has_home_spawn()


func has_home_spawn() -> bool:
	return active_home_spawn_locked and active_home_spawn_id != ""


func get_home_spawn_position() -> Vector3:
	if has_home_spawn():
		return SpawnPoints.get_play_spawn_position(
			SpawnPoints.ensure_colony_id(active_home_spawn_id)
		)
	return SpawnPoints.get_play_spawn_position(SpawnPoints.default_colony_id())


func complete_nest_intro() -> void:
	if active_character_id == "":
		operation_failed.emit("Ingen karaktär vald")
		return
	_post("/characters/nest_complete", { "id": active_character_id }, "nest_complete")


func mark_nest_intro_completed_local() -> void:
	active_nest_visited = true


func set_home_spawn(spawn_id: String, method: String = "elevator") -> void:
	if active_character_id == "":
		operation_failed.emit("Ingen karaktär vald")
		return
	_post("/characters/set_home_spawn", {
		"id": active_character_id,
		"spawnId": spawn_id,
		"method": method,
	}, "set_home_spawn")


func redeem_secret_code(code: String) -> void:
	if active_character_id == "":
		operation_failed.emit("Ingen karaktär vald")
		return
	_post("/characters/redeem_secret_code", {
		"id": active_character_id,
		"code": code.strip_edges(),
	}, "redeem_secret_code")


func fetch_active_for_username(username: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT_SEC
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			callback.call(false, AvatarData.new(), "")
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).get("ok", false):
			callback.call(false, AvatarData.new(), "")
			return
		var data: Dictionary = parsed as Dictionary
		var avatar_dict: Dictionary = _as_dict(data, "avatar")
		if avatar_dict.is_empty():
			callback.call(false, AvatarData.new(), "")
			return
		callback.call(true, AvatarData.from_dict(avatar_dict), str(data.get("characterName", "")))
	)
	var json_body := JSON.stringify({ "username": username })
	var headers := PackedStringArray(["Content-Type: application/json"])
	http.request(Auth.api_url + "/characters/get", headers, HTTPClient.METHOD_POST, json_body)


func can_create_more() -> bool:
	if unlimited_slots:
		return true
	return characters.size() < character_limit


func slots_label() -> String:
	if unlimited_slots:
		return "%d / ∞" % characters.size()
	return "%d / %d" % [characters.size(), character_limit]


func is_busy() -> bool:
	return _busy


func _emit_progress(phase: String, detail: String = "") -> void:
	profile_progress.emit(phase, detail)


func _post(path: String, body: Dictionary, action: String) -> void:
	_send_id += 1
	var send_id := _send_id
	_pending_action = action
	_emit_progress("request", "%s%s" % [Auth.api_url, path])
	body["token"] = Auth.session_token
	var json_body := JSON.stringify(body)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"User-Agent: CubeGodot/1.0",
	])
	_busy = true
	_dispatch_request(send_id, path, json_body, headers)


func _dispatch_request(send_id: int, path: String, json_body: String, headers: PackedStringArray) -> void:
	if send_id != _send_id or not _busy:
		return
	if not is_inside_tree():
		_busy = false
		operation_failed.emit("Klienten är inte redo – starta om spelet")
		return
	var err := _http.request(Auth.api_url + path, headers, HTTPClient.METHOD_POST, json_body)
	if err == ERR_BUSY:
		get_tree().create_timer(0.2).timeout.connect(
			func() -> void: _dispatch_request(send_id, path, json_body, headers),
			CONNECT_ONE_SHOT
		)
		return
	if err != OK:
		if send_id == _send_id:
			_busy = false
			operation_failed.emit("Kunde inte nå servern (fel %d)" % err)
		return
	_inflight_send_id = send_id


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if _inflight_send_id == 0 or _inflight_send_id != _send_id:
		return

	_busy = false
	_inflight_send_id = 0

	_emit_progress("response", "HTTP %d · %d byte" % [response_code, body.size()])
	if result == HTTPRequest.RESULT_TIMEOUT:
		_emit_progress("timeout", "Karaktärs-API timeout")
		operation_failed.emit("Servern svarade inte i tid – försök igen")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_progress("network_error", "HTTP-resultat %d" % result)
		operation_failed.emit("Nätverksfel – kunde inte nå servern")
		return
	if response_code != 200:
		_emit_progress("http_error", "Status %d" % response_code)
		operation_failed.emit("Serverfel (%d) – karaktärer kanske inte är deployade ännu" % response_code)
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		operation_failed.emit("Ogiltigt svar från servern")
		return

	var data: Dictionary = parsed as Dictionary
	if not data.get("ok", false):
		operation_failed.emit(str(data.get("error", "Något gick fel")))
		return

	match _pending_action:
		"list":
			_apply_character_list(data)
			_emit_progress("list_done", "%d karaktärer hittades" % characters.size())
			characters_loaded.emit()
		"create":
			var created: Dictionary = _as_dict(data, "character")
			if not created.is_empty():
				characters.append(created)
				active_character_id = str(data.get("activeId", created.get("id", "")))
				_apply_active_character(created)
				character_created.emit(active_character_id)
				character_selected.emit()
			_list_synced = true
			_emit_progress("create_done", "Karaktär skapad: %s" % active_character_name)
			characters_loaded.emit()
		"select":
			var selected: Dictionary = _as_dict(data, "character")
			if not selected.is_empty():
				_apply_active_character(selected)
			character_selected.emit()
		"save":
			var saved: Dictionary = _as_dict(data, "character")
			if not saved.is_empty():
				_apply_active_character(saved)
			character_saved.emit()
		"delete":
			characters = _as_array(data, "characters")
			active_character_id = str(data.get("activeId", ""))
			if active_character_id != "":
				for entry in characters:
					if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == active_character_id:
						_apply_active_character(entry as Dictionary)
						break
			else:
				avatar_ready = false
				active_avatar_configured = false
			_list_synced = true
			characters_loaded.emit()
		"nest_complete":
			var completed: Dictionary = _as_dict(data, "character")
			if not completed.is_empty():
				_apply_active_character(completed)
				for i in characters.size():
					if typeof(characters[i]) == TYPE_DICTIONARY and str((characters[i] as Dictionary).get("id", "")) == active_character_id:
						characters[i] = completed
						break
			nest_intro_completed.emit()
		"set_home_spawn", "redeem_secret_code":
			var home_character: Dictionary = _as_dict(data, "character")
			if not home_character.is_empty():
				_apply_active_character(home_character)
				for i in characters.size():
					if typeof(characters[i]) == TYPE_DICTIONARY and str((characters[i] as Dictionary).get("id", "")) == active_character_id:
						characters[i] = home_character
						break
			home_spawn_set.emit(active_home_spawn_id)


func _apply_character_list(data: Dictionary) -> void:
	characters = _as_array(data, "characters")
	active_character_id = str(data.get("activeId", ""))
	unlimited_slots = bool(data.get("unlimited", false))
	var limit_value: Variant = data.get("limit")
	character_limit = int(limit_value) if limit_value != null else 6
	_list_synced = true

	if active_character_id != "":
		for entry in characters:
			if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == active_character_id:
				_apply_active_character(entry as Dictionary)
				character_selected.emit()
				return

	if not characters.is_empty() and typeof(characters[0]) == TYPE_DICTIONARY:
		_apply_active_character(characters[0] as Dictionary)
		character_selected.emit()


func character_avatar_configured(entry: Dictionary) -> bool:
	if typeof(entry) != TYPE_DICTIONARY or entry.is_empty():
		return false
	if bool(entry.get("avatarConfigured", false)):
		return true
	if bool(entry.get("homeSpawnLocked", false)) or bool(entry.get("nestVisited", false)):
		return true
	var created_at: String = str(entry.get("createdAt", ""))
	var updated_at: String = str(entry.get("updatedAt", ""))
	if created_at != "" and updated_at != "" and updated_at != created_at:
		return true
	return false


func active_needs_avatar_setup() -> bool:
	if Auth.is_guest:
		return true
	return not active_avatar_configured


func _pick_mesh_id(character_id: String) -> String:
	var seed: int = absi(hash("%s_%s" % [character_id, Auth.username]))
	return FALLBACK_MESH_IDS[seed % FALLBACK_MESH_IDS.size()]


func _fallback_avatar_for_character(character_id: String) -> AvatarData:
	var data: AvatarData = AvatarData.new()
	data.mesh_id = _pick_mesh_id(character_id)
	return data


func _as_dict(source: Dictionary, key: String) -> Dictionary:
	var raw: Variant = source.get(key)
	if typeof(raw) == TYPE_DICTIONARY:
		return raw as Dictionary
	return {}


func _as_array(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key)
	if typeof(raw) == TYPE_ARRAY:
		return raw as Array
	return []


func _apply_active_character(entry: Dictionary) -> void:
	active_character_id = str(entry.get("id", ""))
	active_character_name = str(entry.get("name", "Karaktär"))
	active_home_spawn_locked = bool(entry.get("homeSpawnLocked", false))
	active_home_spawn_id = str(entry.get("homeSpawnId", ""))
	if not active_home_spawn_locked:
		active_home_spawn_id = ""
	active_nest_visited = bool(entry.get("nestVisited", false))
	active_avatar_configured = character_avatar_configured(entry)

	var avatar_dict: Dictionary = _as_dict(entry, "avatar")

	if not avatar_dict.is_empty():
		var avatar_data: AvatarData = AvatarData.from_dict(avatar_dict)
		if not avatar_dict.has("mesh_id") or str(avatar_dict.get("mesh_id", "")).strip_edges() == "":
			avatar_data.mesh_id = _pick_mesh_id(active_character_id)
		set_avatar(avatar_data)
	elif active_avatar_configured:
		set_avatar(_fallback_avatar_for_character(active_character_id))
	else:
		avatar_ready = false