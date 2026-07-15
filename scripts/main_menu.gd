extends Control

@onready var server_input: LineEdit = %ServerInput
@onready var lobby_input: LineEdit = %LobbyInput
@onready var status_label: Label = %StatusLabel
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var start_button: Button = %StartButton
@onready var lobby_label: Label = %LobbyLabel
@onready var user_label: Label = %UserLabel


func _ready() -> void:
	server_input.text = Network.signaling_url
	if Auth.is_logged_in:
		user_label.text = "Inloggad som: %s" % Auth.username
	start_button.visible = false
	lobby_label.visible = false

	Network.lobby_ready.connect(_on_lobby_ready)
	Network.connection_failed.connect(_on_connection_failed)
	Network.game_started.connect(_on_game_started)

	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	%LogoutButton.pressed.connect(_on_logout_pressed)


func _on_host_pressed() -> void:
	_set_status("Skapar lobby...")
	_set_buttons_enabled(false)
	Network.host_game(server_input.text)


func _on_join_pressed() -> void:
	var code := lobby_input.text.strip_edges()
	if code.is_empty():
		_set_status("Ange en lobby-kod för att gå med.")
		return
	_set_status("Ansluter till lobby...")
	_set_buttons_enabled(false)
	Network.join_game(server_input.text, code)


func _on_start_pressed() -> void:
	_set_status("Startar spelet...")
	start_button.disabled = true
	Network.seal_and_start()


func _on_lobby_ready(lobby: String, is_host: bool) -> void:
	lobby_label.text = "Lobby: %s" % lobby
	lobby_label.visible = true
	start_button.visible = is_host
	start_button.disabled = false
	if is_host:
		_set_status("Väntar på fler spelare. Dela lobby-koden!")
	else:
		_set_status("Ansluten! Väntar på att host startar...")
	_set_buttons_enabled(true)
	host_button.disabled = true
	join_button.disabled = true


func _on_connection_failed(reason: String) -> void:
	_set_status("Anslutning misslyckades: %s" % reason)
	_reset_ui()


func _on_game_started() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_logout_pressed() -> void:
	Auth.logout()
	Network.stop()
	get_tree().change_scene_to_file("res://scenes/login.tscn")


func _set_status(text: String) -> void:
	status_label.text = text


func _set_buttons_enabled(enabled: bool) -> void:
	host_button.disabled = not enabled
	join_button.disabled = not enabled


func _reset_ui() -> void:
	_set_buttons_enabled(true)
	start_button.visible = false
	lobby_label.visible = false