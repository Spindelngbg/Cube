extends Node

const PRODUCTION_SIGNAL_URL := "wss://cube-production-3d68.up.railway.app"
const LOCAL_SIGNAL_URL := "ws://localhost:9080"
const DEFAULT_SIGNAL_URL := PRODUCTION_SIGNAL_URL
const GLOBAL_LOBBY := "the-cube"

var client: WebRTCMultiplayerClient
var signaling_url: String = DEFAULT_SIGNAL_URL
var current_lobby: String = GLOBAL_LOBBY
var is_connected := false

signal world_ready()
signal connection_failed(reason: String)


func _ready() -> void:
	client = WebRTCMultiplayerClient.new()
	client.name = "WebRTCClient"
	add_child(client)
	client.lobby_joined.connect(_on_lobby_joined)
	client.connected.connect(_on_connected)
	client.disconnected.connect(_on_disconnected)


func connect_to_world(url: String = "") -> void:
	if is_connected and multiplayer.multiplayer_peer != null:
		world_ready.emit()
		return
	stop()
	signaling_url = url if url != "" else signaling_url if signaling_url != "" else DEFAULT_SIGNAL_URL
	current_lobby = GLOBAL_LOBBY
	client.lobby = GLOBAL_LOBBY
	client.mesh = true
	client.autojoin = true
	client.connect_to_url(signaling_url)


func stop() -> void:
	if client:
		client.stop()
	is_connected = false
	current_lobby = GLOBAL_LOBBY


func get_peer_count() -> int:
	return multiplayer.get_peers().size() + (1 if multiplayer.multiplayer_peer else 0)


func _on_lobby_joined(lobby: String) -> void:
	current_lobby = lobby


func _on_connected(_id: int, _use_mesh: bool) -> void:
	is_connected = true
	world_ready.emit()


func _on_disconnected() -> void:
	is_connected = false
	if not client.sealed:
		connection_failed.emit(client.reason)