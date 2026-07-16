class_name QuestJournalUI
extends PanelContainer

const Lore = preload("res://scripts/story/shawshank_lore.gd")
const GleazerLoreScript = preload("res://scripts/story/gleazer_lore.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

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
	ArrivalQuestManager.quest_step_changed.connect(func(_idx: int) -> void: _refresh())
	ArrivalQuestManager.quest_started.connect(func() -> void: _refresh())
	ArrivalQuestManager.quest_completed.connect(func() -> void: _refresh())
	ArmamentQuestManager.quest_step_changed.connect(func(_idx: int) -> void: _refresh())
	ArmamentQuestManager.quest_started.connect(func() -> void: _refresh())
	ArmamentQuestManager.quest_completed.connect(func() -> void: _refresh())
	SpiderQuestManager.quest_step_changed.connect(func(_idx: int) -> void: _refresh())
	SpiderQuestManager.quest_started.connect(func() -> void: _refresh())
	SpiderQuestManager.quest_completed.connect(func() -> void: _refresh())
	GleazerQuestManager.gleazer_quest_changed.connect(_refresh)


func toggle() -> void:
	_visible = not _visible
	visible = _visible
	if _visible:
		GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.ui_open())
	else:
		GameSfxScript.play_2d_varied(self, RpgAudioLibraryScript.ui_close())
	if _visible:
		_refresh()
		MouseLook.deactivate()
	else:
		if not get_tree().paused:
			var game := get_tree().current_scene
			if game and game.has_method("activate_gameplay_mouse"):
				game.activate_gameplay_mouse()


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
	if ArmamentQuestManager.is_active():
		var armament: Dictionary = ArmamentQuestManager.get_journal_entry()
		_title.text = str(armament.get("title", ""))
		_company.text = str(armament.get("company", ""))
		if bool(armament.get("completed", false)):
			_objective.text = "AVSLUTAD — du är beväpnad."
			_briefing.text = "Kolonisäkerhet har registrerat ditt vapen."
		else:
			_objective.text = str(armament.get("current_objective", ""))
			_briefing.text = str(armament.get("current_briefing", ""))
		_tagline.text = "%s\n\nDelmål:\n%s" % [
			str(armament.get("tagline", "")),
			str(armament.get("milestones", "")),
		]
		_append_side_quests()
		return

	if SpiderQuestManager.is_active():
		var spider: Dictionary = SpiderQuestManager.get_journal_entry()
		_title.text = str(spider.get("title", ""))
		_company.text = str(spider.get("company", ""))
		if bool(spider.get("completed", false)):
			_objective.text = "AVSLUTAD — Spindeln har vaknat."
			_briefing.text = "Du kan ibland kallas Spindeln i kolonin."
		else:
			_objective.text = str(spider.get("current_objective", ""))
			_briefing.text = str(spider.get("current_briefing", ""))
		_tagline.text = "%s\n\nDelmål:\n%s" % [
			str(spider.get("tagline", "")),
			str(spider.get("milestones", "")),
		]
		_append_side_quests()
		return

	if ArrivalQuestManager.is_active() or ArrivalQuestManager.is_completed():
		var arrival: Dictionary = ArrivalQuestManager.get_journal_entry()
		_title.text = str(arrival.get("title", ""))
		_company.text = str(arrival.get("company", ""))
		if bool(arrival.get("completed", false)):
			_objective.text = "AVSLUTAD — alla delmål i Ankomstprotokoll klara."
			_briefing.text = "Steam-achievements låses upp när du spelar via Steam."
		else:
			_objective.text = str(arrival.get("current_objective", ""))
			_briefing.text = str(arrival.get("current_briefing", ""))
		_tagline.text = "%s\n\nDelmål:\n%s" % [
			str(arrival.get("tagline", "")),
			str(arrival.get("milestones", "")),
		]
		_append_side_quests()
		return

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
	_append_side_quests()


func _append_side_quests() -> void:
	if GleazerQuestManager.has_active_quest():
		var gq: Dictionary = GleazerQuestManager.get_active_summary()
		_objective.text += "\n\n[Gleazers] %s\n%s" % [
			str(gq.get("title", "")),
			str(gq.get("objective", "")),
		]
		_briefing.text += "\n\n%s" % str(gq.get("briefing", ""))
		_tagline.text += "\n%s" % GleazerLoreScript.CLAN_MOTTO