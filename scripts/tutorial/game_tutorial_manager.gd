extends Node

signal tutorial_opened
signal tutorial_closed

const DATA_PATH := "res://data/tutorial/colony_tutorial.json"

var _tutorial_id := "colony_intro"
var _title := "Välkommen till kuben"
var _pages: Array = []
var _page_index := 0
var _completed := false
var _save_slot := "guest"
var _ui: GameTutorialUI


func _ready() -> void:
	_load_definition()
	Profile.character_selected.connect(_on_character_changed)
	Profile.character_created.connect(_on_character_created)
	_on_character_changed()


func bind_ui(ui: GameTutorialUI) -> void:
	_ui = ui
	if _ui:
		_ui.setup(self)


func get_title() -> String:
	return _title


func get_pages() -> Array:
	return _pages


func get_page_index() -> int:
	return _page_index


func get_page_count() -> int:
	return _pages.size()


func get_current_page() -> Dictionary:
	if _page_index < 0 or _page_index >= _pages.size():
		return {}
	return _pages[_page_index]


func is_completed() -> bool:
	return _completed


func should_auto_show() -> bool:
	return not _completed and not _pages.is_empty()


func show_tutorial(from_start: bool = true) -> void:
	if _pages.is_empty() or _ui == null:
		return
	if from_start:
		_page_index = 0
	_display_current()
	tutorial_opened.emit()


func toggle() -> void:
	if _ui == null:
		return
	if _ui.is_open():
		close_tutorial(false)
	else:
		show_tutorial(true)


func next_page() -> void:
	if _pages.is_empty():
		return
	_page_index += 1
	if _page_index >= _pages.size():
		finish_tutorial()
	else:
		_display_current()


func skip_tutorial() -> void:
	finish_tutorial()


func finish_tutorial() -> void:
	if not _completed:
		_completed = true
		_save_progress()
	close_tutorial(true)


func close_tutorial(mark_seen: bool) -> void:
	if mark_seen and not _completed:
		_completed = true
		_save_progress()
	if _ui:
		_ui.hide_panel()
	_restore_mouse_look()
	tutorial_closed.emit()


func _display_current() -> void:
	if _ui == null:
		return
	var page: Dictionary = get_current_page()
	_ui.show_page(
		_title,
		str(page.get("title", "")),
		str(page.get("body", "")),
		_page_index + 1,
		_pages.size(),
		not _completed
	)
	MouseLook.deactivate()


func _restore_mouse_look() -> void:
	if get_tree() == null or get_tree().paused:
		return
	var game := get_tree().current_scene
	if game and game.has_node("CameraPivot/Camera3D"):
		MouseLook.activate(
			game.get_node("CameraPivot") as Node3D,
			game.get_node("CameraPivot/Camera3D") as Camera3D
		)


func _load_definition() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_warning("Tutorial data missing: %s" % DATA_PATH)
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data := parsed as Dictionary
	_tutorial_id = str(data.get("id", "colony_intro"))
	_title = str(data.get("title", "Välkommen till kuben"))
	_pages = data.get("pages", [])


func _on_character_changed() -> void:
	_save_slot = Profile.active_character_id if Profile.active_character_id != "" else "guest"
	_load_progress()


func _on_character_created(_character_id: String) -> void:
	_save_slot = Profile.active_character_id if Profile.active_character_id != "" else "guest"
	_completed = false
	_page_index = 0
	_save_progress()


func _save_path() -> String:
	return "user://tutorial_%s.json" % _save_slot


func _load_progress() -> void:
	_completed = false
	_page_index = 0
	var path := _save_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data := parsed as Dictionary
	if str(data.get("tutorial_id", "")) != _tutorial_id:
		return
	_completed = bool(data.get("completed", false))
	_page_index = int(data.get("page_index", 0))


func _save_progress() -> void:
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"tutorial_id": _tutorial_id,
		"completed": _completed,
		"page_index": _page_index,
	}, "\t"))
	file.close()