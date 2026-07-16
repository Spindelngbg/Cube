class_name QuestJournalUI
extends PanelContainer

const Lore = preload("res://scripts/story/shawshank_lore.gd")

var _title: Label
var _company: Label
var _objective: Label
var _briefing: Label
var _tagline: Label
var _visible := false


func _ready() -> void:
	visible = false
	_build()
	SpiderTheme.apply_to(self)
	QuestManager.quest_step_changed.connect(_refresh)
	QuestManager.quest_started.connect(func(_id: String) -> void: _refresh())
	QuestManager.quest_completed.connect(func(_id: String) -> void: _refresh())


func toggle() -> void:
	_visible = not _visible
	visible = _visible
	if _visible:
		_refresh()
		MouseLook.deactivate()
	else:
		if not get_tree().paused:
			var game := get_tree().current_scene
			if game and game.has_node("CameraPivot/Camera3D"):
				MouseLook.activate(
					game.get_node("CameraPivot") as Node3D,
					game.get_node("CameraPivot/Camera3D") as Camera3D
				)


func _build() -> void:
	custom_minimum_size = Vector2(420, 0)
	offset_left = 16.0
	offset_top = 250.0
	offset_right = 460.0
	offset_bottom = 520.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	var header := Label.new()
	header.text = "Questjournal"
	SpiderTheme.style_title(header, 22)
	col.add_child(header)

	_title = Label.new()
	SpiderTheme.style_section(_title)
	col.add_child(_title)

	_company = Label.new()
	SpiderTheme.style_status(_company)
	col.add_child(_company)

	_objective = Label.new()
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_objective)

	_briefing = Label.new()
	_briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SpiderTheme.style_subtitle(_briefing)
	col.add_child(_briefing)

	_tagline = Label.new()
	_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_tagline)

	var hint := Label.new()
	hint.text = "J = stäng journal"
	SpiderTheme.style_subtitle(hint)
	col.add_child(hint)


func _refresh() -> void:
	var entries: Array = QuestManager.get_journal_entries()
	if entries.is_empty():
		_title.text = "Inga uppdrag ännu"
		_company.text = Lore.COMPANY_NAME
		_objective.text = "Leta efter det läckta memot i ljusrummet."
		_briefing.text = ""
		_tagline.text = Lore.SLOGAN
		return

	var entry: Dictionary = entries[0]
	_title.text = str(entry.get("title", ""))
	_company.text = str(entry.get("company", ""))
	if bool(entry.get("completed", false)):
		_objective.text = "AVSLUTAD — Shawshank Redemption Corp. avslöjad."
		_briefing.text = Lore.SABOTAGE_SUCCESS
	else:
		_objective.text = str(entry.get("current_objective", ""))
		_briefing.text = str(entry.get("current_briefing", ""))
	_tagline.text = str(entry.get("tagline", ""))