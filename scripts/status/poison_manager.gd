extends Node

signal poison_changed(active: bool, severity: float)

const DOT_INTERVAL := 2.0
const DOT_DAMAGE_BASE := 5.0
const IMMUNITY_AFTER_CURE := 18.0

var _poisoned := false
var _severity := 0.0
var _dot_timer := 0.0
var _immunity_timer := 0.0


func is_poisoned() -> bool:
	return _poisoned


func get_severity() -> float:
	return _severity


func get_status_text() -> String:
	if not _poisoned:
		return ""
	return "GIFTIG (%d%%) — gå till Pharmacy!" % int(round(_severity * 100.0))


func try_apply_bite(chance: float = 0.32) -> bool:
	if _immunity_timer > 0.0:
		return false
	if randf() > clampf(chance, 0.0, 1.0):
		return false
	apply_bite()
	return true


func apply_bite() -> void:
	if _immunity_timer > 0.0:
		return
	if not _poisoned:
		_poisoned = true
		_severity = 1.0
		_dot_timer = DOT_INTERVAL * 0.5
		poison_changed.emit(true, _severity)
		QuestManager.story_toast.emit(
			"Spindelgift!",
			"En SRC-hybrid bet dig. Du är förgiftad — spring till Pharmacy och köp Hybrid-Antidot."
		)
	else:
		_severity = minf(1.0, _severity + 0.15)
		poison_changed.emit(true, _severity)


func cure() -> void:
	if not _poisoned:
		return
	_poisoned = false
	_severity = 0.0
	_dot_timer = 0.0
	_immunity_timer = IMMUNITY_AFTER_CURE
	poison_changed.emit(false, 0.0)


func tick_immunity(delta: float) -> void:
	if _immunity_timer <= 0.0:
		return
	_immunity_timer = maxf(0.0, _immunity_timer - delta)


func tick_dot(delta: float, player: Node) -> void:
	if not _poisoned or player == null:
		return
	if not player.has_method("take_damage"):
		return
	_dot_timer -= delta
	if _dot_timer > 0.0:
		return
	_dot_timer = DOT_INTERVAL
	player.take_damage(DOT_DAMAGE_BASE * _severity)


func reset() -> void:
	_poisoned = false
	_severity = 0.0
	_dot_timer = 0.0
	_immunity_timer = 0.0
	poison_changed.emit(false, 0.0)