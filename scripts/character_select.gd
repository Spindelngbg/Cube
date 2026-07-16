extends Control

@onready var status_label: Label = %StatusLabel
@onready var slots_label: Label = %SlotsLabel
@onready var character_list: VBoxContainer = %CharacterList
@onready var create_button: Button = %CreateButton
@onready var play_button: Button = %PlayButton
@onready var edit_button: Button = %EditButton

var _selected_id := ""
var _navigate_after_create := false
var _entering := false


func _ready() -> void:
	InputMode.ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SpiderTheme.apply_to(self)
	SpiderTheme.style_title($Center/Panel/VBox/Title)
	SpiderTheme.style_subtitle($Center/Panel/VBox/Subtitle)
	SpiderTheme.style_status(status_label)

	Profile.characters_loaded.connect(_refresh_ui)
	Profile.character_selected.connect(_refresh_ui)
	Profile.operation_failed.connect(_on_operation_failed)

	create_button.pressed.connect(_on_create_pressed)
	play_button.pressed.connect(_on_play_pressed)
	edit_button.pressed.connect(_on_edit_pressed)
	%LogoutButton.pressed.connect(_on_logout_pressed)

	if Profile.characters_list_ready():
		_refresh_ui()
		_set_status("Välj en karaktär eller skapa en ny.")
	else:
		_set_status("Laddar karaktärer...")
		Profile.load_characters()


func _refresh_ui() -> void:
	if _navigate_after_create and not Profile.characters.is_empty():
		_navigate_after_create = false
		get_tree().change_scene_to_file("res://scenes/avatar_builder.tscn")
		return
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
	play_button.disabled = _selected_id == "" or _entering
	edit_button.disabled = _selected_id == "" or _entering
	play_button.text = _play_label_for(_selected_id)
	_set_status("Välj en sparad karaktär och tryck Spela — eller skapa en ny.")


func _make_character_row(character_id: String, character_name: String, is_active: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", FantasyBorderLibrary.row_style(is_active))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_col)

	var name_label := Label.new()
	name_label.text = "%s%s" % [character_name, "  ★" if is_active else ""]
	name_col.add_child(name_label)

	var status := CharacterFlow.character_status(_character_entry(character_id))
	if status != "":
		var status_label := Label.new()
		SpiderTheme.style_subtitle(status_label)
		status_label.text = status
		name_col.add_child(status_label)

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
	_navigate_after_create = true
	Profile.create_character("Karaktär %d" % (Profile.characters.size() + 1))


func _on_play_pressed() -> void:
	if _selected_id == "" or _entering:
		return
	_entering = true
	play_button.disabled = true
	edit_button.disabled = true
	create_button.disabled = true
	if _selected_id != Profile.active_character_id:
		_set_status("Väljer karaktär...")
		Profile.select_character(_selected_id)
		await Profile.character_selected
	if needs_avatar_setup_for_selected():
		_entering = false
		_refresh_ui()
		CharacterFlow.open_avatar_editor(self)
		return
	if CharacterFlow.destination_scene_path() == CharacterFlow.GAME_SCENE:
		_set_status("Ansluter till din koloni...")
	var result: Dictionary = await CharacterFlow.continue_as(self)
	_entering = false
	if not result.ok:
		_refresh_ui()
		_set_status(str(result.get("error", "Kunde inte gå vidare")))
		return


func _on_edit_pressed() -> void:
	if _selected_id == "" or _entering:
		return
	if _selected_id != Profile.active_character_id:
		_set_status("Väljer karaktär...")
		Profile.select_character(_selected_id)
		await Profile.character_selected
	CharacterFlow.open_avatar_editor(self)


func needs_avatar_setup_for_selected() -> bool:
	if _selected_id == "":
		return true
	return not Profile.character_avatar_configured(_character_entry(_selected_id))


func _play_label_for(character_id: String) -> String:
	if character_id == "":
		return "Spela"
	var entry := _character_entry(character_id)
	if not Profile.character_avatar_configured(entry):
		return "Skapa utseende"
	if bool(entry.get("homeSpawnLocked", false)):
		return "Spela"
	if not bool(entry.get("nestVisited", false)):
		return "Till nästet"
	return "Till ljusrummet"


func _character_entry(character_id: String) -> Dictionary:
	for entry in Profile.characters:
		if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == character_id:
			return entry as Dictionary
	return {}


func _on_delete_pressed(character_id: String) -> void:
	_set_status("Tar bort karaktär...")
	Profile.delete_character(character_id)


func _on_logout_pressed() -> void:
	Profile.clear_characters()
	Auth.logout()
	get_tree().change_scene_to_file("res://scenes/login.tscn")


func _on_operation_failed(message: String) -> void:
	_navigate_after_create = false
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