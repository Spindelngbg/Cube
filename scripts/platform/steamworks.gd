extends Node

signal steam_ready
signal steam_init_failed(reason: String)

const STEAM_API_INIT_RESULT_OK := 0

var is_ready := false
var username := ""
var steam_id: int = 0
var init_result: Dictionary = {}

var _app_id := 0
var _embed_callbacks := false
var _steam_class_available := false
var _steam_api: Object


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_steam_api = _resolve_steam_api()
	_steam_class_available = _steam_api != null
	_app_id = _resolve_app_id()
	_embed_callbacks = _resolve_embed_callbacks()
	_initialize_steam()


func _process(_delta: float) -> void:
	if not is_ready or _embed_callbacks or not _steam_class_available:
		return
	_steam_call("run_callbacks")


func is_steam_available() -> bool:
	return _steam_class_available


func get_app_id() -> int:
	return _app_id


func set_achievement(api_name: String) -> bool:
	if not is_ready or api_name.strip_edges() == "":
		return false
	var granted: Variant = _steam_call("setAchievement", [api_name])
	_steam_call("storeStats")
	return granted == true


func _initialize_steam() -> void:
	if not _steam_class_available:
		push_warning("[SteamWorks] GodotSteam extension not loaded; Steam features disabled.")
		steam_init_failed.emit("GodotSteam extension not loaded")
		return

	var response: Variant = _steam_call("steamInitEx", [_app_id, _embed_callbacks])
	if typeof(response) != TYPE_DICTIONARY:
		push_warning("[SteamWorks] Unexpected steamInitEx response: %s" % str(response))
		steam_init_failed.emit("Invalid steamInitEx response")
		return

	init_result = response
	var status := int(response.get("status", 1))
	var verbal := str(response.get("verbal", "unknown"))

	if status != STEAM_API_INIT_RESULT_OK:
		push_warning("[SteamWorks] Steam init failed (%s): %s" % [status, verbal])
		is_ready = false
		steam_init_failed.emit(verbal)
		return

	is_ready = true
	username = str(_steam_call("getPersonaName"))
	steam_id = int(_steam_call("getSteamID"))
	print("[SteamWorks] Ready — user=%s id=%s app_id=%s" % [username, steam_id, _app_id])
	steam_ready.emit()


func _resolve_steam_api() -> Object:
	if Engine.has_singleton("Steam"):
		return Engine.get_singleton("Steam")
	if Engine.has_singleton("GodotSteam"):
		return Engine.get_singleton("GodotSteam")
	return null


func _steam_call(method: String, args: Array = []) -> Variant:
	if _steam_api == null:
		return null
	if not _steam_api.has_method(method):
		push_warning("[SteamWorks] Steam API missing method: %s" % method)
		return null
	return _steam_api.callv(method, args)


func _resolve_app_id() -> int:
	if ProjectSettings.has_setting("steam/initialization/app_id"):
		var configured := int(ProjectSettings.get_setting("steam/initialization/app_id"))
		if configured > 0:
			return configured
	return _read_app_id_from_file()


func _resolve_embed_callbacks() -> bool:
	if ProjectSettings.has_setting("steam/initialization/embed_callbacks"):
		return bool(ProjectSettings.get_setting("steam/initialization/embed_callbacks"))
	return false


func _read_app_id_from_file() -> int:
	const DEFAULT_APP_ID := 480
	const APP_ID_PATH := "res://steam_appid.txt"
	if not FileAccess.file_exists(APP_ID_PATH):
		return DEFAULT_APP_ID
	var file := FileAccess.open(APP_ID_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_APP_ID
	var text := file.get_as_text().strip_edges()
	if text.is_valid_int():
		return int(text)
	return DEFAULT_APP_ID