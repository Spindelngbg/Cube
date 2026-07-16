class_name RangedWeaponBlaster
extends RefCounted

signal ammo_changed(current: int, capacity: int, reloading: bool)
signal reloaded()

var ammo_in_magazine := 0
var _magazine_size := 8
var _reload_time := 1.2
var _fire_cooldown_sec := 0.3
var _reload_timer := 0.0
var _fire_cooldown := 0.0
var _is_reloading := false
var _weapon_id := ""


func configure(weapon_id: String) -> void:
	_weapon_id = weapon_id
	var stats := WeaponCatalog.get_stats(weapon_id)
	_magazine_size = int(stats.get("magazine_size", 8))
	_reload_time = float(stats.get("reload_time", 1.2))
	_fire_cooldown_sec = float(stats.get("fire_cooldown", 0.3))
	if ammo_in_magazine <= 0:
		ammo_in_magazine = _magazine_size
	_emit_ammo()


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
	_fire_cooldown = _fire_cooldown_sec
	_emit_ammo()
	return true


func try_reload() -> bool:
	if _is_reloading or ammo_in_magazine >= _magazine_size:
		return false
	_is_reloading = true
	_reload_timer = _reload_time
	_emit_ammo()
	return true


func get_status_text(weapon_id: String) -> String:
	var weapon_name := ItemCatalog.get_display_name(weapon_id)
	if _is_reloading:
		return "%s: laddar om..." % weapon_name
	return "%s: %d/%d | Vänsterklick skjut | R ladda om" % [
		weapon_name,
		ammo_in_magazine,
		_magazine_size,
	]


func _finish_reload() -> void:
	_is_reloading = false
	_reload_timer = 0.0
	ammo_in_magazine = _magazine_size
	_emit_ammo()
	reloaded.emit()


func _emit_ammo() -> void:
	ammo_changed.emit(ammo_in_magazine, _magazine_size, _is_reloading)