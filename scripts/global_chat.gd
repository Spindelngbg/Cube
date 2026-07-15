extends CanvasLayer

const VISITOR_PREFIX := "Besökare_"
const RECONNECT_DELAY := 2.0

@onready var chat_panel: PanelContainer = %ChatPanel
@onready var status_label: Label = %ChatStatusLabel
@onready var messages: RichTextLabel = %ChatMessages
@onready var input_field: LineEdit = %ChatInput
@onready var send_button: Button = %ChatSendButton
@onready var chat_tab_button: Button = %ChatTabButton
@onready var friends_tab_button: Button = %FriendsTabButton
@onready var chat_view: Control = %ChatView
@onready var friends_view: Control = %FriendsView
@onready var requests_list: VBoxContainer = %RequestsList
@onready var friends_list: VBoxContainer = %FriendsList
@onready var friends_hint: Label = %FriendsHint

var ws := WebSocketPeer.new()
var _connected := false
var _identified := false
var _can_friends := false
var _visitor_name := ""
var _active_tab := "chat"
var _friends: Array = []
var _pending_in: Array = []
var _pending_out: Array = []
var _reconnect_timer := 0.0
var _connecting := false


func _ready() -> void:
	SpiderTheme.apply_to(chat_panel)
	SpiderTheme.style_section(%ChatTitle)
	SpiderTheme.style_status(status_label)
	SpiderTheme.style_tab_button(chat_tab_button, true)
	SpiderTheme.style_tab_button(friends_tab_button, false)

	messages.meta_clicked.connect(_on_message_meta_clicked)
	messages.scroll_following = true
	input_field.text_submitted.connect(_on_input_submitted)
	send_button.pressed.connect(_send_chat_message)
	chat_tab_button.pressed.connect(_show_tab.bind("chat"))
	friends_tab_button.pressed.connect(_show_tab.bind("friends"))

	Auth.login_succeeded.connect(_on_auth_changed)
	Auth.logged_out.connect(_on_auth_logged_out)

	_visitor_name = "%s%d" % [VISITOR_PREFIX, randi_range(1000, 9999)]
	_connect_chat()
	_show_tab("chat")
	_refresh_friends_ui()


func _process(delta: float) -> void:
	ws.poll()
	var state := ws.get_ready_state()

	while state == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count():
		_handle_packet(ws.get_packet().get_string_from_utf8())

	if state == WebSocketPeer.STATE_OPEN:
		_reconnect_timer = 0.0
		if _connected and not _identified:
			_identify()
	elif state == WebSocketPeer.STATE_CLOSED:
		_connected = false
		_identified = false
		_connecting = false
		if status_label.text != "Frånkopplad – försöker igen...":
			status_label.text = "Frånkopplad – försöker igen..."
		_reconnect_timer += delta
		if _reconnect_timer >= RECONNECT_DELAY:
			_reconnect_timer = 0.0
			_connect_chat()
	elif state == WebSocketPeer.STATE_CONNECTING:
		status_label.text = "Ansluter..."


func _connect_chat() -> void:
	if _connecting:
		return
	_connecting = true
	var base_url := Network.signaling_url
	if base_url == "":
		base_url = Network.PRODUCTION_SIGNAL_URL
	var chat_url := _chat_url_from_signaling(base_url)
	status_label.text = "Ansluter..."
	ws.close()
	ws = WebSocketPeer.new()
	var err := ws.connect_to_url(chat_url)
	if err != OK:
		_connecting = false
		status_label.text = "Kunde inte ansluta"


func _chat_url_from_signaling(signaling_url: String) -> String:
	if signaling_url.begins_with("wss://"):
		return signaling_url + "/chat"
	if signaling_url.begins_with("ws://"):
		return signaling_url + "/chat"
	return "wss://cube-production-3d68.up.railway.app/chat"


func _identify() -> void:
	var payload := {
		"type": "identify",
		"username": _current_username(),
		"token": Auth.session_token if Auth.is_logged_in else "",
	}
	_send_json(payload)


func _current_username() -> String:
	if Auth.is_logged_in and Auth.username != "":
		return Auth.username
	return _visitor_name


func _on_auth_changed(_username: String, _is_guest: bool) -> void:
	_identified = false
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and _connected:
		_identify()


func _on_auth_logged_out() -> void:
	_visitor_name = "%s%d" % [VISITOR_PREFIX, randi_range(1000, 9999)]
	_identified = false
	_can_friends = false
	_friends.clear()
	_pending_in.clear()
	_pending_out.clear()
	_refresh_friends_ui()
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and _connected:
		_identify()


func _handle_packet(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data := parsed as Dictionary
	var msg_type := str(data.get("type", ""))

	match msg_type:
		"welcome":
			_connected = true
			_connecting = false
			status_label.text = "Ansluten"
			_identify()
		"identified":
			_identified = true
			_can_friends = bool(data.get("canFriends", false))
			status_label.text = _current_username()
			if not _can_friends:
				friends_hint.text = "Skapa konto för att lägga till vänner. Klicka på namn i chatten."
			else:
				friends_hint.text = "Klicka på ett namn i chatten för att skicka vänförfrågan."
		"history":
			messages.clear()
			var history: Array = data.get("messages", [])
			for entry in history:
				if typeof(entry) == TYPE_DICTIONARY:
					_append_entry(entry as Dictionary)
		"message":
			_append_entry(data)
		"system":
			_append_system(str(data.get("text", "")))
		"friends":
			_friends = data.get("friends", [])
			_pending_in = data.get("pendingIn", [])
			_pending_out = data.get("pendingOut", [])
			_refresh_friends_ui()
		"friend_request":
			_send_json({ "type": "friends_refresh" })
		"friend_accepted":
			_append_system("%s accepterade din vänförfrågan" % str(data.get("username", "")))
			_send_json({ "type": "friends_refresh" })
		"error":
			_append_system(str(data.get("message", "Fel")))


func _append_entry(entry: Dictionary) -> void:
	var username := str(entry.get("username", "???"))
	var text := str(entry.get("text", ""))
	var safe_name := username.replace("[", "").replace("]", "")
	messages.append_text(
		"[color=#%s][url=user:%s]%s[/url][/color]: %s\n" % [
			SpiderTheme.BLOOD_BRIGHT.to_html(false),
			safe_name,
			safe_name,
			text,
		]
	)


func _append_system(text: String) -> void:
	messages.append_text("[color=#%s]* %s *\n[/color]" % [
		SpiderTheme.MUTED.to_html(false),
		text,
	])


func _on_message_meta_clicked(meta: Variant) -> void:
	var token := str(meta)
	if not token.begins_with("user:"):
		return
	var target := token.substr(5)
	if target == _current_username():
		_append_system("Det där är du själv.")
		return
	if not _can_friends:
		_append_system("Skapa konto för att lägga till vänner.")
		return
	send_friend_request(target)


func _on_input_submitted(_text: String) -> void:
	_send_chat_message()


func _send_chat_message() -> void:
	if not _identified:
		_append_system("Ansluter fortfarande...")
		return
	var text := input_field.text.strip_edges()
	if text.is_empty():
		return
	input_field.text = ""
	_send_json({ "type": "chat", "text": text })


func send_friend_request(username: String) -> void:
	if not _can_friends:
		_append_system("Skapa konto för att lägga till vänner.")
		return
	_send_json({ "type": "friend_request", "to": username.strip_edges() })


func accept_friend(username: String) -> void:
	_send_json({ "type": "friend_accept", "from": username })


func decline_friend(username: String) -> void:
	_send_json({ "type": "friend_decline", "from": username })


func _send_json(payload: Dictionary) -> void:
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	ws.send_text(JSON.stringify(payload))


func _show_tab(tab: String) -> void:
	_active_tab = tab
	chat_view.visible = tab == "chat"
	friends_view.visible = tab == "friends"
	SpiderTheme.style_tab_button(chat_tab_button, tab == "chat")
	SpiderTheme.style_tab_button(friends_tab_button, tab == "friends")
	if tab == "friends":
		_send_json({ "type": "friends_refresh" })


func _refresh_friends_ui() -> void:
	_clear_children(requests_list)
	_clear_children(friends_list)

	var pending_count := _pending_in.size()
	friends_tab_button.text = "Vänner (%d)" % pending_count if pending_count > 0 else "Vänner"

	if _pending_in.is_empty() and _pending_out.is_empty() and _friends.is_empty():
		var empty := Label.new()
		empty.text = "Inga vänner ännu"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		friends_list.add_child(empty)

	for entry in _pending_in:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var from_name := str((entry as Dictionary).get("from", ""))
		requests_list.add_child(_make_request_row(from_name))

	for entry in _pending_out:
		var out_name := str(entry)
		var row := Label.new()
		row.text = "Väntar på %s" % out_name
		requests_list.add_child(row)

	for entry in _friends:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var friend_data := entry as Dictionary
		var row := Label.new()
		var online := bool(friend_data.get("online", false))
		var name := str(friend_data.get("username", ""))
		row.text = "%s %s" % ["●" if online else "○", name]
		if online:
			row.add_theme_color_override("font_color", SpiderTheme.VENOM)
		friends_list.add_child(row)


func _make_request_row(from_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = from_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var accept := Button.new()
	accept.text = "Acceptera"
	accept.pressed.connect(accept_friend.bind(from_name))
	row.add_child(accept)

	var decline := Button.new()
	decline.text = "Neka"
	decline.pressed.connect(decline_friend.bind(from_name))
	row.add_child(decline)

	return row


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()