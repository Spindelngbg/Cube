extends Node

const PRODUCTION_API_URL := "https://cube-production-3d68.up.railway.app"
const LOCAL_API_URL := "http://localhost:9080"
const DEFAULT_API_URL := PRODUCTION_API_URL
const REQUEST_TIMEOUT_SEC := 20.0
const MAX_RETRIES := 1

var username: String = ""
var is_guest: bool = false
var is_logged_in: bool = false
var session_token: String = ""
var api_url: String = DEFAULT_API_URL

signal login_succeeded(username: String, is_guest: bool)
signal login_failed(message: String)
signal logged_out()

var _http := HTTPRequest.new()
var _pending_action := ""
var _pending_path := ""
var _pending_body := {}
var _retry_count := 0


func _ready() -> void:
	add_child(_http)
	_http.timeout = REQUEST_TIMEOUT_SEC
	_http.request_completed.connect(_on_request_completed)


func api_url_from_signaling(signaling_url: String) -> String:
	if signaling_url.begins_with("wss://"):
		return "https://" + signaling_url.substr(6)
	if signaling_url.begins_with("ws://"):
		return "http://" + signaling_url.substr(5)
	if signaling_url.begins_with("https://") or signaling_url.begins_with("http://"):
		return signaling_url
	return DEFAULT_API_URL


func set_api_url(url: String) -> void:
	api_url = url if url != "" else DEFAULT_API_URL


func logout() -> void:
	username = ""
	is_guest = false
	is_logged_in = false
	session_token = ""
	logged_out.emit()


func register(p_username: String, password: String) -> void:
	_post("/auth/register", {
		"username": p_username.strip_edges(),
		"password": password,
	}, "register")


func login(p_username: String, password: String) -> void:
	_post("/auth/login", {
		"username": p_username.strip_edges(),
		"password": password,
	}, "login")


func login_as_guest() -> void:
	_post("/auth/guest", {}, "guest")


func _post(path: String, body: Dictionary, action: String) -> void:
	_pending_action = action
	_pending_path = path
	_pending_body = body
	_retry_count = 0
	_send_request()


func _send_request() -> void:
	var json_body := JSON.stringify(_pending_body)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(api_url + _pending_path, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		login_failed.emit("Kunde inte nå servern")


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedByteArray,
	body: PackedByteArray
) -> void:
	if result == HTTPRequest.RESULT_TIMEOUT:
		if _retry_count < MAX_RETRIES:
			_retry_count += 1
			_send_request()
			return
		login_failed.emit("Servern svarade inte i tid – vänta och försök igen")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		if _retry_count < MAX_RETRIES:
			_retry_count += 1
			_send_request()
			return
		login_failed.emit("Nätverksfel – kunde inte nå servern")
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		login_failed.emit("Ogiltigt svar från servern")
		return

	var data := parsed as Dictionary
	if not data.get("ok", false):
		login_failed.emit(str(data.get("error", "Inloggning misslyckades")))
		return

	username = str(data.get("username", ""))
	is_guest = bool(data.get("isGuest", false))
	session_token = str(data.get("sessionToken", ""))
	is_logged_in = true
	login_succeeded.emit(username, is_guest)