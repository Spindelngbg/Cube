extends CanvasLayer

const GameplayHudThemeScript = preload("res://scripts/ui/gameplay_hud_theme.gd")

const GAMEPLAY_SCENES := [
	"nest_room.tscn",
	"emergence_room.tscn",
	"game.tscn",
]

var _crosshair: TextureRect
var _visible := false


func _ready() -> void:
	layer = 90
	_crosshair = TextureRect.new()
	_crosshair.name = "Crosshair"
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.texture = GameplayHudThemeScript.crosshair_texture()
	_crosshair.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crosshair.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_crosshair.custom_minimum_size = Vector2(32, 32)
	_crosshair.modulate = Color(0.55, 0.95, 1.0, 0.92)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_crosshair)
	_apply_visibility()
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_on_scene_changed")


func _on_scene_changed() -> void:
	var current := get_tree().current_scene
	var path := current.scene_file_path if current else ""
	var show := false
	for scene_name in GAMEPLAY_SCENES:
		if path.ends_with(scene_name):
			show = true
			break
	set_visible_crosshair(show)


func set_visible_crosshair(value: bool) -> void:
	_visible = value
	_apply_visibility()


func _apply_visibility() -> void:
	if _crosshair:
		_crosshair.visible = _visible