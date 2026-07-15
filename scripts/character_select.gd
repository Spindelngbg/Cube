extends Control

@onready var status_label: Label = %StatusLabel
@onready var slots_label: Label = %SlotsLabel
@onready var character_list: VBoxContainer = %CharacterList
@onready var create_button: Button = %CreateButton
@onready var play_button: Button = %PlayButton

var _selected_id := ""


func _ready() -> void:
	SpiderTheme.apply_to(self)
	SpiderTheme.style_title($Center/Panel/VBox/Title)
	SpiderTheme.style_subtitle($Center/Panel/VBox/Subtitle)
	SpiderTheme.style_status(status_label)

	Profile.characters_loaded.connect(_refresh_ui)
	Profile.character_selected.connect(_refresh_ui)
	Profile.operation_failed.connect(_on_operation_failed)

	create_button.pressed.connect(_on_create_pressed)
	play_button.pressed.connect(_on_play_pressed)
	%LogoutButton.pressed.connect(_on_logout_pressed)

	_set_status("Laddar karaktärer...")
	Profile.load_characters()


func _refresh_ui() -> void:
	slots_label.text = "Karaktärer: %s" % Profile.slots_label()
	create_button.disabled = not Profile.can_create_more()
	_clear_children(character_list)

	if Profile.characters.is_empty():
		var empty := Label.new()
		empty.text = "Inga karaktärer ännu.\nKlicka på + Ny karaktär för att börja."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		character_list.add_child(empty)
		_selected_id = ""
		play_button.disabled = true
		_set_status("Skapa din första karaktär.")
		return

	for entry in Profile.characters:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data := entry as Dictionary
		var character_id := str(data.get("id", ""))
		var row := _make_character_row(
			character_id,
			str(data.get("name", "Karaktär")),
			character_id == Profile.active_character_id
		)
		character_list.add_child(row)

	if _selected_id == "" or not _has_character(_selected_id):
		_selected_id = Profile.active_character_id
	play_button.disabled = _selected_id == ""
	_set_status("Välj en karaktär eller skapa en ny.")


func _make_character_row(character_id: String, character_name: String, is_active: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var name_label := Label.new()
	name_label.text = "%s%s" % [character_name, "  ★" if is_active else ""]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var select_button := Button.new()
	select_button.text = "Välj"
	select_button.pressed.connect(_on_select_pressed.bind(character_id))
	row.add_child(select_button)

	var delete_button := Button.new()
	delete_button.text = "Ta bort"
	delete_button.pressed.connect(_on_delete_pressed.bind(character_id))
	row.add_child(delete_button)

	if character_id == _selected_id:
		name_label.add_theme_color_override("font_color", SpiderTheme.BLOOD_BRIGHT)

	return panel


func _on_select_pressed(character_id: String) -> void:
	_selected_id = character_id
	_set_status("Väljer karaktär...")
	Profile.select_character(character_id)


func _on_create_pressed() -> void:
	if Profile.is_busy():
		return
	if not Profile.can_create_more():
		_set_status("Du har nått maxgränsen på 6 karaktärer.")
		return
	_set_status("Skapar karaktär...")
	create_button.disabled = true
	play_button.disabled = true
	Profile.create_character("Karaktär %d" % (Profile.characters.size() + 1))


func _on_play_pressed() -> void:
	if _selected_id == "":
		return
	if _selected_id != Profile.active_character_id:
		Profile.select_character(_selected_id)
		await Profile.character_selected
	get_tree().change_scene_to_file("res://scenes/avatar_builder.tscn")


func _on_delete_pressed(character_id: String) -> void:
	_set_status("Tar bort karaktär...")
	Profile.delete_character(character_id)


func _on_logout_pressed() -> void:
	Profile.clear_characters()
	Auth.logout()
	get_tree().change_scene_to_file("res://scenes/login.tscn")


func _on_operation_failed(message: String) -> void:
	create_button.disabled = not Profile.can_create_more() or Profile.is_busy()
	play_button.disabled = Profile.characters.is_empty() or Profile.is_busy()
	_set_status(message)


func _has_character(character_id: String) -> bool:
	for entry in Profile.characters:
		if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == character_id:
			return true
	return false


func _set_status(text: String) -> void:
	status_label.text = text


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()