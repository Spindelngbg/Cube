class_name LaserBlaster
extends RefCounted

signal ammo_changed(current: int, capacity: int, reloading: bool)
signal reloaded()

const MAGAZINE_SIZE := 12
const RELOAD_TIME := 1.05
const FIRE_COOLDOWN := 0.18

var ammo_in_magazine := MAGAZINE_SIZE
var _reload_timer := 0.0
var _fire_cooldown := 0.0
var _is_reloading := false


func tick(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	if not _is_reloading:
		return
	_reload_timer -= delta
	if _reload_timer <= 0.0:
		_finish_reload()


func can_fire() -> bool:
	return not _is_reloading and _fire_cooldown <= 0.0 and ammo_in_magazine > 0


func try_fire() -> bool:
	if not can_fire():
		return false
	ammo_in_magazine -= 1
	_fire_cooldown = FIRE_COOLDOWN
	_emit_ammo()
	return true


func try_reload() -> bool:
	if _is_reloading or ammo_in_magazine >= MAGAZINE_SIZE:
		return false
	_is_reloading = true
	_reload_timer = RELOAD_TIME
	_emit_ammo()
	return true


func get_status_text() -> String:
	if _is_reloading:
		return "Laser: laddar om..."
	return "Lasergevär: %d/%d | Vänsterklick skjut | R ladda om" % [ammo_in_magazine, MAGAZINE_SIZE]


func _finish_reload() -> void:
	_is_reloading = false
	_reload_timer = 0.0
	ammo_in_magazine = MAGAZINE_SIZE
	_emit_ammo()
	reloaded.emit()


func _emit_ammo() -> void:
	ammo_changed.emit(ammo_in_magazine, MAGAZINE_SIZE, _is_reloading)