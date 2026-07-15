extends Node

const PRODUCTION_SIGNAL_URL := "wss://cube-production-3d68.up.railway.app"
const LOCAL_SIGNAL_URL := "ws://localhost:9080"
const DEFAULT_SIGNAL_URL := PRODUCTION_SIGNAL_URL
const GLOBAL_LOBBY := "the-cube"

var client: WebRTCMultiplayerClient
var signaling_url: String = DEFAULT_SIGNAL_URL
var current_lobby: String = GLOBAL_LOBBY
var is_connected := false
var _is_host := false

signal world_ready()
signal lobby_ready(lobby: String, is_host: bool)
signal connection_failed(reason: String)
signal game_started()


func _ready() -> void:
	client = WebRTCMultiplayerClient.new()
	client.name = "WebRTCClient"
	add_child(client)
	client.lobby_joined.connect(_on_lobby_joined)
	client.connected.connect(_on_connected)
	client.disconnected.connect(_on_disconnected)
	client.lobby_sealed.connect(_on_lobby_sealed)


func connect_to_world(url: String = "") -> void:
	if is_connected and multiplayer.multiplayer_peer != null:
		world_ready.emit()
		return
	_start(url, GLOBAL_LOBBY)


func host_game(url: String = "") -> void:
	_start(url, "")


func join_game(url: String, lobby_code: String) -> void:
	_start(url, lobby_code.strip_edges())


func seal_and_start() -> void:
	if client.lobby.is_empty():
		return
	client.seal_lobby()


func _start(url: String, lobby_code: String) -> void:
	stop()
	signaling_url = url if url != "" else signaling_url if signaling_url != "" else DEFAULT_SIGNAL_URL
	current_lobby = lobby_code
	client.lobby = lobby_code
	client.mesh = true
	client.autojoin = true
	client.connect_to_url(signaling_url)


func stop() -> void:
	if client:
		client.stop()
	is_connected = false
	_is_host = false
	current_lobby = GLOBAL_LOBBY


func get_peer_count() -> int:
	return multiplayer.get_peers().size() + (1 if multiplayer.multiplayer_peer else 0)


func _on_lobby_joined(lobby: String) -> void:
	current_lobby = lobby


func _on_connected(id: int, _use_mesh: bool) -> void:
	is_connected = true
	_is_host = id == 1
	if current_lobby == GLOBAL_LOBBY or current_lobby.is_empty():
		world_ready.emit()
	else:
		lobby_ready.emit(current_lobby, _is_host)


func _on_lobby_sealed() -> void:
	game_started.emit()


func _on_disconnected() -> void:
	is_connected = false
	_is_host = false
	if not client.sealed:
		connection_failed.emit(client.reason)