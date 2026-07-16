class_name DevSpawnPanel
extends PanelContainer

const ChatCheatCommandsScript = preload("res://scripts/chat_cheat_commands.gd")
const GameplayHudThemeScript = preload("res://scripts/ui/gameplay_hud_theme.gd")

var _body: Label
var _visible_for_cheater := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 12.0
	offset_top = 92.0
	offset_right = 360.0
	offset_bottom = 248.0
	_build()
	GameplayHudThemeScript.apply_panel(self)
	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	var allowed := ChatCheatCommandsScript.is_cheater()
	if not allowed:
		visible = false
		return
	if Input.is_action_just_pressed("dev_panel_toggle"):
		_visible_for_cheater = not _visible_for_cheater
	visible = _visible_for_cheater
	if visible:
		_refresh()


func _build() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)

	var title := Label.new()
	title.text = "Dev — Test"
	GameplayHudThemeScript.style_title(title, 14)
	col.add_child(title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameplayHudThemeScript.style_muted(_body)
	col.add_child(_body)


func _refresh() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null:
		_body.text = "Ingen aktiv koloni."
		return
	var player: Node3D = null
	if game.has_method("get_local_player"):
		player = game.get_local_player()
	var spawn_id := ""
	if game.has_method("get_active_spawn_id"):
		spawn_id = str(game.get_active_spawn_id())

	var lines: PackedStringArray = []
	lines.append("Koloni: %s" % SpawnPoints.get_colony_label(spawn_id))
	if player == null:
		lines.append("Spelare: saknas")
		_body.text = "\n".join(lines)
		return

	var pos := player.global_position
	var logical := pos
	if game.has_method("logical_world_position"):
		logical = game.logical_world_position(pos)

	var on_floor := "?"
	if player is CharacterBody3D:
		on_floor = "ja" if (player as CharacterBody3D).is_on_floor() else "nej"

	var anchor := Vector3.ZERO
	if player.has_method("get_spawn_anchor"):
		anchor = player.get_spawn_anchor()

	lines.append("Pos (värld): %.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z])
	lines.append("Pos (logisk): %.2f, %.2f, %.2f" % [logical.x, logical.y, logical.z])
	lines.append("På golvet: %s" % on_floor)
	lines.append("Spawn-anchor: %.2f, %.2f, %.2f" % [anchor.x, anchor.y, anchor.z])
	lines.append("F3 = dölj/visa panel")
	_body.text = "\n".join(lines)