extends Control

enum Tab { LOGIN, REGISTER, GUEST }

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")

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
var _detail_label: Label
var _progress_step := 0
var _progress_total := 5
var _flow_kind := ""


func _ready() -> void:
	SpiderTheme.apply_to(self)
	SpiderTheme.style_title($Center/MainPanel/VBox/Title)
	SpiderTheme.style_subtitle($Center/MainPanel/VBox/Subtitle)
	_setup_progress_labels()

	GlobalChat.set_login_screen_active(true)
	_apply_server_url()
	_reset_auth_ui("Välkommen till The Cube.")
	_set_password_visible(login_password, login_toggle, false)
	_set_password_visible(register_password, register_toggle, false)
	_show_tab(Tab.LOGIN)

	Auth.login_succeeded.connect(_on_login_succeeded)
	Auth.login_failed.connect(_on_login_failed)
	Auth.auth_progress.connect(_on_auth_progress)
	Profile.profile_progress.connect(_on_profile_progress)

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


func _setup_progress_labels() -> void:
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_override("font", GuiFontLibraryScript.semibold())
	status_label.add_theme_color_override("font_color", SpiderTheme.BONE)
	status_label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_BODY)

	_detail_label = Label.new()
	_detail_label.name = "LoginDetailLabel"
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.add_theme_font_override("font", GuiFontLibraryScript.regular())
	_detail_label.add_theme_color_override("font_color", Color(SpiderTheme.MUTED.r, SpiderTheme.MUTED.g, SpiderTheme.MUTED.b, 0.92))
	_detail_label.add_theme_font_size_override("font_size", GuiFontLibraryScript.FONT_SMALL)
	status_label.get_parent().add_child(_detail_label)
	status_label.get_parent().move_child(_detail_label, status_label.get_index() + 1)


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
		_set_login_progress(0, 5, "Ange användarnamn.", "Steg 0/5 · Saknar användarnamn")
		return
	if password.is_empty():
		_set_login_progress(0, 5, "Ange lösenord.", "Steg 0/5 · Saknar lösenord")
		return
	_begin_auth("login", "Loggar in...", 5)
	_set_login_progress(1, 5, "Loggar in...", "Steg 1/5 · Kontrollerar uppgifter för %s" % name)
	Auth.login(name, password)


func _on_register_pressed() -> void:
	var name := register_username.text.strip_edges()
	var password := register_password.text
	if name.is_empty():
		_set_login_progress(0, 5, "Ange ett användarnamn.", "Steg 0/5 · Saknar användarnamn")
		return
	if password.is_empty():
		_set_login_progress(0, 5, "Ange ett lösenord.", "Steg 0/5 · Saknar lösenord")
		return
	if name.length() < 3:
		_set_login_progress(0, 5, "Användarnamn måste vara minst 3 tecken.", "Steg 0/5 · För kort namn")
		return
	if password.length() < 4:
		_set_login_progress(0, 5, "Lösenord måste vara minst 4 tecken.", "Steg 0/5 · För kort lösenord")
		return
	_begin_auth("register", "Skapar konto...", 5)
	_set_login_progress(1, 5, "Skapar konto...", "Steg 1/5 · Registrerar %s" % name)
	Auth.register(name, password)


func _on_guest_pressed() -> void:
	_begin_auth("guest", "Loggar in som gäst...", 3)
	_set_login_progress(1, 3, "Loggar in som gäst...", "Steg 1/3 · Startar gästsession")
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


func _on_auth_progress(phase: String, detail: String) -> void:
	var step := _progress_step
	var title := status_label.text
	var lines: PackedStringArray = []
	match phase:
		"start":
			step = 2
			title = status_label.text
			lines.append("Steg %d/%d · %s" % [step, _progress_total, detail])
		"connecting":
			step = 2
			title = "Ansluter till server..."
			lines.append("Steg %d/%d · Skickar förfrågan" % [step, _progress_total])
			lines.append(detail)
		"retry":
			step = 2
			title = "Försöker igen..."
			lines.append("Steg %d/%d · %s" % [step, _progress_total, detail])
		"response":
			step = 3
			title = "Tar emot svar..."
			lines.append("Steg %d/%d · %s" % [step, _progress_total, detail])
		"success":
			step = 4 if _flow_kind != "guest" else 3
			title = "Inloggning lyckades"
			lines.append("Steg %d/%d · %s" % [step, _progress_total, detail])
			if _flow_kind == "guest":
				lines.append("Öppnar karaktärsskapare...")
		"timeout", "network_error", "failed":
			title = "Inloggning misslyckades"
			lines.append(detail)
		_:
			lines.append(detail)
	_set_login_progress(step, _progress_total, title, "\n".join(lines))


func _on_profile_progress(phase: String, detail: String) -> void:
	var lines: PackedStringArray = []
	var title := status_label.text
	match phase:
		"list_start":
			_set_login_progress(4, 6, "Laddar karaktärer...", "Steg 4/6 · %s" % detail)
			return
		"create_start":
			_set_login_progress(5, 6, "Skapar karaktär...", "Steg 5/6 · %s" % detail)
			return
		"request":
			lines.append(detail)
		"response":
			lines.append("Karaktärs-API: %s" % detail)
		"list_done":
			_set_login_progress(5, 6, "Karaktärer laddade", "Steg 5/6 · %s" % detail)
			return
		"create_done":
			_set_login_progress(6, 6, "Karaktär klar", "Steg 6/6 · %s" % detail)
			return
		"timeout", "network_error", "http_error":
			title = "Karaktärsdata misslyckades"
			lines.append(detail)
		_:
			if detail != "":
				lines.append(detail)
	if lines.is_empty():
		return
	_set_login_progress(_progress_step, _progress_total, title, "\n".join(lines))


func _on_login_succeeded(p_username: String, is_guest: bool) -> void:
	_stop_auth_watchdog()
	if is_guest:
		_set_login_progress(3, 3, "Välkommen, %s!" % p_username, "Steg 3/3 · Gäst OK — öppnar karaktärsskapare")
		Profile.clear_characters()
		_go_to_scene("res://scenes/avatar_builder.tscn")
	else:
		_set_login_progress(4, 6, "Välkommen, %s!" % p_username, "Steg 4/6 · Konto OK — hämtar karaktärer")
		_enter_account_flow()


func _enter_account_flow() -> void:
	if _account_flow_running:
		return
	_account_flow_running = true
	_progress_total = 6
	_set_action_buttons_enabled(false)
	_start_auth_watchdog()
	Profile.clear_characters()

	if not await _profile_list_characters():
		_account_flow_running = false
		_stop_auth_watchdog()
		_reset_auth_ui("Servern svarade inte – försök igen", "Karaktärslistan timeout efter 25 s")
		return

	if Profile.characters.is_empty():
		_set_login_progress(5, 6, "Skapar första karaktären...", "Steg 5/6 · Inga sparade karaktärer")
		if not await _profile_create_character("Karaktär 1"):
			_account_flow_running = false
			_stop_auth_watchdog()
			_reset_auth_ui("Kunde inte skapa karaktär – försök igen", "POST /characters/create misslyckades")
			return
		if Profile.active_character_id == "":
			_account_flow_running = false
			_stop_auth_watchdog()
			_reset_auth_ui("Kunde inte skapa karaktär – försök igen", "Servern returnerade inget karaktärs-ID")
			return
		_account_flow_running = false
		_stop_auth_watchdog()
		_set_login_progress(6, 6, "Öppnar karaktärsskapare...", "Steg 6/6 · Ny karaktär skapad")
		_go_to_scene("res://scenes/avatar_builder.tscn")
	elif Profile.characters.size() == 1:
		_account_flow_running = false
		_stop_auth_watchdog()
		_set_login_progress(6, 6, "Öppnar karaktärsskapare...", "Steg 6/6 · 1 karaktär hittad")
		_go_to_scene("res://scenes/avatar_builder.tscn")
	else:
		_account_flow_running = false
		_stop_auth_watchdog()
		_set_login_progress(6, 6, "Öppnar karaktärsval...", "Steg 6/6 · %d karaktärer" % Profile.characters.size())
		_go_to_scene("res://scenes/character_select.tscn")


func _go_to_scene(path: String) -> void:
	_set_login_progress(_progress_total, _progress_total, "Byter skärm...", "Laddar %s" % path.get_file())
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		_reset_auth_ui("Kunde inte ladda nästa skärm (fel %d)" % err, path)


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
		_set_login_progress(_progress_step, _progress_total, "Fel vid karaktärsdata", state.error)
	return state.ok


func _on_login_failed(message: String) -> void:
	_stop_auth_watchdog()
	_account_flow_running = false
	_reset_auth_ui(message, "Auth avbröts eller nekades")


func _begin_auth(flow_kind: String, status_text: String, total_steps: int) -> void:
	_apply_server_url()
	_account_flow_running = false
	_flow_kind = flow_kind
	_progress_total = total_steps
	_set_login_progress(1, total_steps, status_text, _server_detail_line(1, total_steps, "Förbereder %s" % flow_kind))
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
	if _progress_step > 0:
		Auth.cancel_request()
		Profile.cancel_request()
		_account_flow_running = false
		_reset_auth_ui(
			"Servern svarade inte – kontrollera nätet och försök igen",
			"Timeout efter %d s på steg %d/%d" % [int(Auth.REQUEST_TIMEOUT_SEC + 6.0), _progress_step, _progress_total]
		)


func _reset_auth_ui(message: String, detail: String = "") -> void:
	_flow_kind = ""
	_progress_step = 0
	_set_login_progress(0, _progress_total, message, detail)
	_set_action_buttons_enabled(true)


func _set_login_progress(step: int, total: int, title: String, detail: String = "") -> void:
	_progress_step = step
	_progress_total = maxi(total, 1)
	status_label.text = title
	if _detail_label:
		if detail.strip_edges() != "":
			_detail_label.text = detail
		elif step <= 0:
			_detail_label.text = _server_detail_line(0, _progress_total, "Redo")
		else:
			_detail_label.text = _server_detail_line(step, _progress_total, "")


func _server_detail_line(step: int, total: int, note: String) -> String:
	var host := _server_host_label()
	var prefix := "Steg %d/%d" % [step, total] if step > 0 else "Status"
	var body := note if note != "" else "Väntar..."
	if host != "":
		return "%s · %s\nServer: %s" % [prefix, body, host]
	return "%s · %s" % [prefix, body]


func _server_host_label() -> String:
	var url := Auth.api_url.strip_edges()
	if url == "":
		return ""
	if url.begins_with("https://"):
		return url.substr(8)
	if url.begins_with("http://"):
		return url.substr(7)
	return url


func _set_action_buttons_enabled(enabled: bool) -> void:
	%LoginButton.disabled = not enabled
	%RegisterButton.disabled = not enabled
	%GuestButton.disabled = not enabled