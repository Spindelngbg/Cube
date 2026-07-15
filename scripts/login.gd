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


func _ready() -> void:
	LuxuryTheme.apply_to(self)
	LuxuryTheme.style_title($Center/MainPanel/VBox/Title)
	LuxuryTheme.style_subtitle($Center/MainPanel/VBox/Subtitle)
	LuxuryTheme.style_status(status_label)

	_apply_server_url()
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


func _show_tab(tab: Tab) -> void:
	_active_tab = tab
	login_panel.visible = tab == Tab.LOGIN
	register_panel.visible = tab == Tab.REGISTER
	guest_panel.visible = tab == Tab.GUEST
	LuxuryTheme.style_tab_button(tab_login, tab == Tab.LOGIN)
	LuxuryTheme.style_tab_button(tab_register, tab == Tab.REGISTER)
	LuxuryTheme.style_tab_button(tab_guest, tab == Tab.GUEST)


func _on_login_pressed() -> void:
	_set_status("Loggar in...")
	_set_buttons_enabled(false)
	_apply_server_url()
	Auth.login(login_username.text, login_password.text)


func _on_register_pressed() -> void:
	var name := register_username.text.strip_edges()
	var password := register_password.text
	if name.is_empty():
		_set_status("Ange ett användarnamn.")
		return
	if password.is_empty():
		_set_status("Ange ett lösenord.")
		return
	_set_status("Skapar konto...")
	_set_buttons_enabled(false)
	_apply_server_url()
	Auth.register(name, password)


func _on_guest_pressed() -> void:
	_set_status("Loggar in som gäst...")
	_set_buttons_enabled(false)
	_apply_server_url()
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


func _on_login_succeeded(p_username: String, _is_guest: bool) -> void:
	_set_status("Välkommen, %s!" % p_username)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_login_failed(message: String) -> void:
	_set_status(message)
	_set_buttons_enabled(true)


func _set_status(text: String) -> void:
	status_label.text = text


func _set_buttons_enabled(enabled: bool) -> void:
	%LoginButton.disabled = not enabled
	%RegisterButton.disabled = not enabled
	%GuestButton.disabled = not enabled