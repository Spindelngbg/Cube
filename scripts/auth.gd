## Account login over HTTPS JSON API to the official Cube server. No local script execution.
extends Node

const PRODUCTION_API_URL := AppIdentity.PRODUCTION_API_URL
const LOCAL_API_URL := AppIdentity.LOCAL_API_URL
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
	var send_id := _send_id
	_pending_action = action
	_pending_path = path
	_pending_body = body
	_retry_count = 0
	call_deferred("_dispatch_request", send_id)


func _dispatch_request(send_id: int) -> void:
	if send_id != _send_id:
		return
	if not is_inside_tree():
		_emit_failed("Klienten är inte redo – starta om spelet")
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
			_emit_failed("Kunde inte nå servern (fel %d)" % err)
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
	_emit_failed(message)


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var send_id := _inflight_send_id
	if send_id == 0 or send_id != _send_id:
		return

	_request_in_flight = false
	_inflight_send_id = 0

	if result == HTTPRequest.RESULT_TIMEOUT:
		_retry_or_fail(send_id, "Servern svarade inte i tid – vänta och försök igen")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_retry_or_fail(send_id, "Nätverksfel – kunde inte nå servern (kod %d)" % result)
		return
	if response_code < 200 or response_code >= 300:
		_emit_failed("Serverfel (%d)" % response_code)
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_failed("Ogiltigt svar från servern")
		return

	var data := parsed as Dictionary
	if not data.get("ok", false):
		_emit_failed(str(data.get("error", "Inloggning misslyckades")))
		return

	call_deferred("_emit_success", data)


func _emit_success(data: Dictionary) -> void:
	username = str(data.get("username", ""))
	is_guest = bool(data.get("isGuest", false))
	session_token = str(data.get("sessionToken", ""))
	is_logged_in = true
	login_succeeded.emit(username, is_guest)


func _emit_failed(message: String) -> void:
	call_deferred("_emit_failed_deferred", message)


func _emit_failed_deferred(message: String) -> void:
	login_failed.emit(message)