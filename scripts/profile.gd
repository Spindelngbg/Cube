extends Node

signal characters_loaded()
signal character_selected()
signal character_saved()
signal nest_intro_completed()
signal operation_failed(message: String)

const REQUEST_TIMEOUT_SEC := 12.0

var avatar: AvatarData = AvatarData.new()
var avatar_ready := false
var characters: Array = []
var active_character_id: String = ""
var active_character_name: String = ""
var active_nest_visited := true
var character_limit: int = 6
var unlimited_slots := false

var _http := HTTPRequest.new()
var _pending_action := ""
var _busy := false


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
	characters.clear()
	active_character_id = ""
	active_character_name = ""
	avatar = AvatarData.new()
	avatar_ready = false
	_busy = false


func load_characters() -> void:
	_post("/characters/list", {}, "list")


func create_character(name: String = "") -> void:
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


func complete_nest_intro() -> void:
	if active_character_id == "":
		operation_failed.emit("Ingen karaktär vald")
		return
	_post("/characters/nest_complete", { "id": active_character_id }, "nest_complete")


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
		var data := parsed as Dictionary
		var avatar_dict: Dictionary = data.get("avatar", {})
		if typeof(avatar_dict) != TYPE_DICTIONARY or avatar_dict.is_empty():
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


func _post(path: String, body: Dictionary, action: String) -> void:
	if _busy:
		operation_failed.emit("Vänta på förra serveranropet...")
		return
	_busy = true
	_pending_action = action
	body["token"] = Auth.session_token
	var json_body := JSON.stringify(body)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(Auth.api_url + path, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		_busy = false
		operation_failed.emit("Kunde inte nå servern")


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_busy = false

	if result == HTTPRequest.RESULT_TIMEOUT:
		operation_failed.emit("Servern svarade inte i tid – försök igen")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		operation_failed.emit("Nätverksfel – kunde inte nå servern")
		return
	if response_code != 200:
		operation_failed.emit("Serverfel (%d) – karaktärer kanske inte är deployade ännu" % response_code)
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		operation_failed.emit("Ogiltigt svar från servern")
		return

	var data := parsed as Dictionary
	if not data.get("ok", false):
		operation_failed.emit(str(data.get("error", "Något gick fel")))
		return

	match _pending_action:
		"list":
			_apply_character_list(data)
			characters_loaded.emit()
		"create":
			var created: Dictionary = data.get("character", {})
			if not created.is_empty():
				characters.append(created)
				active_character_id = str(data.get("activeId", created.get("id", "")))
				_apply_active_character(created)
			characters_loaded.emit()
		"select":
			var selected: Dictionary = data.get("character", {})
			if not selected.is_empty():
				_apply_active_character(selected)
			character_selected.emit()
		"save":
			var saved: Dictionary = data.get("character", {})
			if not saved.is_empty():
				_apply_active_character(saved)
			character_saved.emit()
		"delete":
			characters = data.get("characters", [])
			active_character_id = str(data.get("activeId", ""))
			if active_character_id != "":
				for entry in characters:
					if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == active_character_id:
						_apply_active_character(entry as Dictionary)
						break
			else:
				avatar_ready = false
			characters_loaded.emit()
		"nest_complete":
			var completed: Dictionary = data.get("character", {})
			if not completed.is_empty():
				_apply_active_character(completed)
				for i in characters.size():
					if typeof(characters[i]) == TYPE_DICTIONARY and str((characters[i] as Dictionary).get("id", "")) == active_character_id:
						characters[i] = completed
						break
			nest_intro_completed.emit()


func _apply_character_list(data: Dictionary) -> void:
	characters = data.get("characters", [])
	active_character_id = str(data.get("activeId", ""))
	unlimited_slots = bool(data.get("unlimited", false))
	var limit_value: Variant = data.get("limit")
	character_limit = int(limit_value) if limit_value != null else 6

	if active_character_id != "":
		for entry in characters:
			if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == active_character_id:
				_apply_active_character(entry as Dictionary)
				return

	if not characters.is_empty() and typeof(characters[0]) == TYPE_DICTIONARY:
		_apply_active_character(characters[0] as Dictionary)


func _apply_active_character(entry: Dictionary) -> void:
	active_character_id = str(entry.get("id", ""))
	active_character_name = str(entry.get("name", "Karaktär"))
	active_nest_visited = bool(entry.get("nestVisited", true))
	var avatar_dict: Dictionary = entry.get("avatar", {})
	if typeof(avatar_dict) == TYPE_DICTIONARY and not avatar_dict.is_empty():
		set_avatar(AvatarData.from_dict(avatar_dict))