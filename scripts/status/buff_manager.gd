extends Node

## Temporära strids- och livskraftsbuffar från magiska brygder.

signal buffs_changed

const DEFAULT_DAMAGE_MULT := 1.5
const DEFAULT_DAMAGE_DURATION := 90.0
const DEFAULT_MAX_HP_BONUS := 50.0
const DEFAULT_MAX_HP_DURATION := 120.0

var _damage_timer := 0.0
var _damage_multiplier := 1.0
var _max_hp_timer := 0.0
var _max_hp_bonus := 0.0


func get_weapon_damage_multiplier() -> float:
	if _damage_timer <= 0.0:
		return 1.0
	return maxf(_damage_multiplier, 1.0)


func get_max_hp_bonus() -> float:
	if _max_hp_timer <= 0.0:
		return 0.0
	return maxf(_max_hp_bonus, 0.0)


func has_damage_buff() -> bool:
	return _damage_timer > 0.0


func has_max_hp_buff() -> bool:
	return _max_hp_timer > 0.0


func get_status_text() -> String:
	var parts: PackedStringArray = []
	if has_damage_buff():
		parts.append(
			"STRID +%d%% (%ds)"
			% [int(round((get_weapon_damage_multiplier() - 1.0) * 100.0)), int(ceil(_damage_timer))]
		)
	if has_max_hp_buff():
		parts.append("LIV +%d HP (%ds)" % [int(round(get_max_hp_bonus())), int(ceil(_max_hp_timer))])
	return " | ".join(parts)


func apply_damage_buff(multiplier: float = DEFAULT_DAMAGE_MULT, duration: float = DEFAULT_DAMAGE_DURATION) -> void:
	var mult := maxf(multiplier, 1.0)
	var dur := maxf(duration, 1.0)
	# Starkare eller längre buff vinner; samma styrka förlänger.
	if mult > _damage_multiplier + 0.001 or _damage_timer <= 0.0:
		_damage_multiplier = mult
		_damage_timer = dur
	else:
		_damage_timer = maxf(_damage_timer, dur)
	buffs_changed.emit()


func apply_max_hp_buff(bonus: float = DEFAULT_MAX_HP_BONUS, duration: float = DEFAULT_MAX_HP_DURATION) -> void:
	var amount := maxf(bonus, 0.0)
	var dur := maxf(duration, 1.0)
	if amount > _max_hp_bonus + 0.001 or _max_hp_timer <= 0.0:
		_max_hp_bonus = amount
		_max_hp_timer = dur
	else:
		_max_hp_timer = maxf(_max_hp_timer, dur)
	buffs_changed.emit()


func tick(delta: float) -> void:
	var changed := false
	if _damage_timer > 0.0:
		_damage_timer = maxf(0.0, _damage_timer - delta)
		if _damage_timer <= 0.0:
			_damage_multiplier = 1.0
			changed = true
	if _max_hp_timer > 0.0:
		_max_hp_timer = maxf(0.0, _max_hp_timer - delta)
		if _max_hp_timer <= 0.0:
			_max_hp_bonus = 0.0
			changed = true
	if changed:
		buffs_changed.emit()


func reset() -> void:
	_damage_timer = 0.0
	_damage_multiplier = 1.0
	_max_hp_timer = 0.0
	_max_hp_bonus = 0.0
	buffs_changed.emit()
