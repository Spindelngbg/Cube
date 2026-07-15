extends Node

const PRODUCTION_API_URL := "https://cube-production-3d68.up.railway.app"
const LOCAL_API_URL := "http://localhost:9080"
const DEFAULT_API_URL := PRODUCTION_API_URL
const REQUEST_TIMEOUT_SEC := 18.0
const MAX_RETRIES := 2

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
var _request_in_flight := false
var _send_id := 0
var _inflight_send_id := 0


func _ready() -> void:
	add_child(_http)
	_http.timeout = REQUEST_TIMEOUT_SEC
	_http.use_threads = true
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
	cancel_request()
	username = ""
	is_guest = false
	is_logged_in = false
	session_token = ""
	logged_out.emit()


func cancel_request() -> void:
	if _request_in_flight:
		_http.cancel_request()
	_request_in_flight = false
	_inflight_send_id = 0
	_send_id += 1


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
	cancel_request()
	_send_id += 1
	_pending_action = action
	_pending_path = path
	_pending_body = body
	_retry_count = 0
	_dispatch_request(_send_id)


func _dispatch_request(send_id: int) -> void:
	if send_id != _send_id:
		return
	if not is_inside_tree():
		login_failed.emit("Klienten är inte redo – starta om spelet")
		return

	var json_body := JSON.stringify(_pending_body)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"User-Agent: CubeGodot/1.0",
	])
	var err := _http.request(api_url + _pending_path, headers, HTTPClient.METHOD_POST, json_body)
	if err == ERR_BUSY and _retry_count < MAX_RETRIES:
		_retry_count += 1
		get_tree().create_timer(0.2).timeout.connect(
			func() -> void: _dispatch_request(send_id),
			CONNECT_ONE_SHOT
		)
		return
	if err != OK:
		if send_id == _send_id:
			login_failed.emit("Kunde inte nå servern (fel %d)" % err)
		return

	_request_in_flight = true
	_inflight_send_id = send_id


func _retry_or_fail(send_id: int, message: String) -> void:
	if send_id != _send_id:
		return
	if _retry_count < MAX_RETRIES:
		_retry_count += 1
		_request_in_flight = false
		_inflight_send_id = 0
		get_tree().create_timer(0.25).timeout.connect(
			func() -> void: _dispatch_request(send_id),
			CONNECT_ONE_SHOT
		)
		return
	login_failed.emit(message)


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedByteArray,
	body: PackedByteArray
) -> void:
	if _inflight_send_id == 0 or _inflight_send_id != _send_id:
		return

	_request_in_flight = false
	_inflight_send_id = 0
	var send_id := _send_id

	if result == HTTPRequest.RESULT_TIMEOUT:
		_retry_or_fail(send_id, "Servern svarade inte i tid – vänta och försök igen")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_retry_or_fail(send_id, "Nätverksfel – kunde inte nå servern (kod %d)" % result)
		return
	if response_code < 200 or response_code >= 300:
		login_failed.emit("Serverfel (%d)" % response_code)
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