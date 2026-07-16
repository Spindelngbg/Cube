class_name OnlinePlayersToast
extends Control

const SHOW_SEC := 3.2

@onready var _badge: PanelContainer = %Badge
@onready var _badge_label: Label = %BadgeLabel
@onready var _popup: PanelContainer = %Popup
@onready var _popup_label: Label = %PopupLabel

var _hide_timer := 0.0
var _last_count := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _popup:
		_popup.modulate.a = 0.0
		_popup.visible = false
	_update_badge(1)


func _process(delta: float) -> void:
	if _hide_timer <= 0.0:
		return
	_hide_timer -= delta
	if _hide_timer <= 0.0:
		_fade_popup_out()


func set_player_count(count: int) -> void:
	var safe_count := maxi(count, 1)
	_update_badge(safe_count)
	if _last_count == safe_count:
		return
	_last_count = safe_count
	if _popup_label:
		_popup_label.text = _count_text(safe_count)
	_show_popup()


func _update_badge(count: int) -> void:
	if _badge_label:
		_badge_label.text = _count_text(count)


func _count_text(count: int) -> String:
	if count == 1:
		return "1 spelare online"
	return "%d spelare online" % count


func _show_popup() -> void:
	_popup.visible = true
	_popup.modulate.a = 0.0
	_popup.scale = Vector2(0.94, 0.94)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_popup, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_popup, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	_hide_timer = SHOW_SEC


func _fade_popup_out() -> void:
	var tween := create_tween()
	tween.tween_property(_popup, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_hide_popup)


func _hide_popup() -> void:
	_popup.visible = false