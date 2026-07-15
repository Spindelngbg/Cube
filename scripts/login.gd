extends Control

enum Tab { LOGIN, REGISTER, GUEST }

@onready var login_panel: VBoxContainer = %LoginPanel
@onready var register_panel: VBoxContainer = %RegisterPanel
@onready var guest_panel: VBoxContainer = %GuestPanel
@onready var tab_login: Button = %TabLoginButton
@onready var tab_register: Button = %TabRegisterButton
@onready var tab_guest: Button = %TabGuestButton
@onready var login_username: LineEdit = %LoginUsername
@onready var login_password: LineEdit = %LoginPassword
@onready var login_toggle: Button = %LoginTogglePassword
@onready var register_username: LineEdit = %RegisterUsername
@onready var register_password: LineEdit = %RegisterPassword
@onready var register_toggle: Button = %RegisterTogglePassword
@onready var status_label: Label = %StatusLabel

var _active_tab := Tab.LOGIN
var _account_flow_running := false
var _auth_watchdog: SceneTreeTimer


func _ready() -> void:
	SpiderTheme.apply_to(self)
	SpiderTheme.style_title($Center/MainPanel/VBox/Title)
	SpiderTheme.style_subtitle($Center/MainPanel/VBox/Subtitle)
	SpiderTheme.style_status(status_label)

	GlobalChat.set_login_screen_active(true)
	_apply_server_url()
	_reset_auth_ui("Välkommen till The Cube.")
	_set_password_visible(login_password, login_toggle, false)
	_set_password_visible(register_password, register_toggle, false)
	_show_tab(Tab.LOGIN)

	Auth.login_succeeded.connect(_on_login_succeeded)
	Auth.login_failed.connect(_on_login_failed)

	tab_login.pressed.connect(_show_tab.bind(Tab.LOGIN))
	tab_register.pressed.connect(_show_tab.bind(Tab.REGISTER))
	tab_guest.pressed.connect(_show_tab.bind(Tab.GUEST))
	%LoginButton.pressed.connect(_on_login_pressed)
	%RegisterButton.pressed.connect(_on_register_pressed)
	%GuestButton.pressed.connect(_on_guest_pressed)
	login_toggle.pressed.connect(_on_login_toggle_pressed)
	register_toggle.pressed.connect(_on_register_toggle_pressed)
	login_password.text_submitted.connect(func(_t: String) -> void: _on_login_pressed())
	register_password.text_submitted.connect(func(_t: String) -> void: _on_register_pressed())


func _exit_tree() -> void:
	GlobalChat.set_login_screen_active(false)


func _show_tab(tab: Tab) -> void:
	_active_tab = tab
	login_panel.visible = tab == Tab.LOGIN
	register_panel.visible = tab == Tab.REGISTER
	guest_panel.visible = tab == Tab.GUEST
	SpiderTheme.style_tab_button(tab_login, tab == Tab.LOGIN)
	SpiderTheme.style_tab_button(tab_register, tab == Tab.REGISTER)
	SpiderTheme.style_tab_button(tab_guest, tab == Tab.GUEST)


func _on_login_pressed() -> void:
	var name := login_username.text.strip_edges()
	var password := login_password.text
	if name.is_empty():
		_set_status("Ange användarnamn.")
		return
	if password.is_empty():
		_set_status("Ange lösenord.")
		return
	_begin_auth("Loggar in...")
	Auth.login(name, password)


func _on_register_pressed() -> void:
	var name := register_username.text.strip_edges()
	var password := register_password.text
	if name.is_empty():
		_set_status("Ange ett användarnamn.")
		return
	if password.is_empty():
		_set_status("Ange ett lösenord.")
		return
	if name.length() < 3:
		_set_status("Användarnamn måste vara minst 3 tecken.")
		return
	if password.length() < 4:
		_set_status("Lösenord måste vara minst 4 tecken.")
		return
	_begin_auth("Skapar konto...")
	Auth.register(name, password)


func _on_guest_pressed() -> void:
	_begin_auth("Loggar in som gäst...")
	Auth.login_as_guest()


func _on_login_toggle_pressed() -> void:
	_toggle_password_visibility(login_password, login_toggle)


func _on_register_toggle_pressed() -> void:
	_toggle_password_visibility(register_password, register_toggle)


func _toggle_password_visibility(field: LineEdit, button: Button) -> void:
	_set_password_visible(field, button, field.secret)


func _set_password_visible(field: LineEdit, button: Button, currently_hidden: bool) -> void:
	field.secret = not currently_hidden
	button.text = "Dölj" if field.secret == false else "Visa"


func _apply_server_url() -> void:
	Network.signaling_url = Network.PRODUCTION_SIGNAL_URL
	Auth.set_api_url(Auth.PRODUCTION_API_URL)


func _on_login_succeeded(p_username: String, is_guest: bool) -> void:
	_stop_auth_watchdog()
	_set_status("Välkommen, %s!" % p_username)
	if is_guest:
		Profile.clear_characters()
		_go_to_scene("res://scenes/avatar_builder.tscn")
	else:
		_enter_account_flow()


func _enter_account_flow() -> void:
	if _account_flow_running:
		return
	_account_flow_running = true
	_set_status("Laddar karaktärer...")
	_set_buttons_enabled(false)
	_start_auth_watchdog()
	Profile.clear_characters()

	if not await _profile_list_characters():
		_account_flow_running = false
		_stop_auth_watchdog()
		_reset_auth_ui("Servern svarade inte – försök igen")
		return

	if Profile.characters.is_empty():
		_set_status("Skapar karaktär...")
		if not await _profile_create_character("Karaktär 1"):
			_account_flow_running = false
			_stop_auth_watchdog()
			_reset_auth_ui("Kunde inte skapa karaktär – försök igen")
			return
		if Profile.active_character_id == "":
			_account_flow_running = false
			_stop_auth_watchdog()
			_reset_auth_ui("Kunde inte skapa karaktär – försök igen")
			return
		_account_flow_running = false
		_stop_auth_watchdog()
		_go_to_scene("res://scenes/avatar_builder.tscn")
	elif Profile.characters.size() == 1:
		_account_flow_running = false
		_stop_auth_watchdog()
		_go_to_scene("res://scenes/avatar_builder.tscn")
	else:
		_account_flow_running = false
		_stop_auth_watchdog()
		_go_to_scene("res://scenes/character_select.tscn")


func _go_to_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		_reset_auth_ui("Kunde inte ladda nästa skärm (fel %d)" % err)


func _profile_list_characters() -> bool:
	return await _wait_for_profile_action(25.0, func() -> void:
		Profile.load_characters()
	)


func _profile_create_character(name: String) -> bool:
	return await _wait_for_profile_action(25.0, func() -> void:
		Profile.create_character(name)
	)


func _wait_for_profile_action(max_sec: float, start_action: Callable) -> bool:
	var state := {"done": false, "ok": false, "error": ""}
	var on_loaded := func() -> void:
		state.done = true
		state.ok = true
	var on_failed := func(message: String) -> void:
		state.done = true
		state.ok = false
		state.error = message
	Profile.characters_loaded.connect(on_loaded, CONNECT_ONE_SHOT)
	Profile.operation_failed.connect(on_failed, CONNECT_ONE_SHOT)
	start_action.call()

	var deadline := Time.get_ticks_msec() + int(max_sec * 1000.0)
	while not state.done:
		if Time.get_ticks_msec() > deadline:
			Profile.cancel_request()
			return false
		await get_tree().process_frame
	if not state.ok and state.error != "":
		_set_status(state.error)
	return state.ok


func _on_login_failed(message: String) -> void:
	_stop_auth_watchdog()
	_account_flow_running = false
	_reset_auth_ui(message)


func _begin_auth(status_text: String) -> void:
	_apply_server_url()
	_account_flow_running = false
	_set_status(status_text)
	_set_action_buttons_enabled(false)
	_start_auth_watchdog()


func _start_auth_watchdog() -> void:
	_stop_auth_watchdog()
	_auth_watchdog = get_tree().create_timer(Auth.REQUEST_TIMEOUT_SEC + 6.0)
	_auth_watchdog.timeout.connect(_on_auth_watchdog_timeout, CONNECT_ONE_SHOT)


func _stop_auth_watchdog() -> void:
	if _auth_watchdog != null and is_instance_valid(_auth_watchdog):
		if _auth_watchdog.timeout.is_connected(_on_auth_watchdog_timeout):
			_auth_watchdog.timeout.disconnect(_on_auth_watchdog_timeout)
	_auth_watchdog = null


func _on_auth_watchdog_timeout() -> void:
	var pending := status_label.text
	if pending.begins_with("Loggar in") or pending.begins_with("Skapar konto") or pending.begins_with("Laddar karaktärer") or pending.begins_with("Skapar karaktär"):
		Auth.cancel_request()
		Profile.cancel_request()
		_account_flow_running = false
		_reset_auth_ui("Servern svarade inte – kontrollera nätet och försök igen")


func _reset_auth_ui(message: String) -> void:
	_set_status(message)
	_set_action_buttons_enabled(true)


func _set_status(text: String) -> void:
	status_label.text = text


func _set_action_buttons_enabled(enabled: bool) -> void:
	%LoginButton.disabled = not enabled
	%RegisterButton.disabled = not enabled
	%GuestButton.disabled = not enabled


func _set_buttons_enabled(enabled: bool) -> void:
	_set_action_buttons_enabled(enabled)