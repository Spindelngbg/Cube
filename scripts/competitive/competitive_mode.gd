extends Node

## Tävlingsinriktade defaults för input och multiplayer-synk.

const SETTING := "gameplay.competitive_mode"


func is_enabled() -> bool:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return false
	return bool(settings.get_value(SETTING, false))


func player_sync_interval_sec() -> float:
	return 1.0 / 30.0 if is_enabled() else 1.0 / 20.0


func max_draw_distance_m() -> float:
	return 400.0 if is_enabled() else -1.0


func player_sync_move_threshold() -> float:
	return 0.02 if is_enabled() else 0.04


func player_sync_turn_threshold() -> float:
	return 0.02 if is_enabled() else 0.05


func remote_interp_rate() -> float:
	return 28.0 if is_enabled() else 14.0


func camera_shake_enabled() -> bool:
	return not is_enabled()


func force_raw_mouse_input() -> bool:
	return is_enabled()