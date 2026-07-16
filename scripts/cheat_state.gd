class_name CheatState
extends RefCounted

static var god_mode := false


static func toggle_god_mode() -> bool:
	god_mode = not god_mode
	return god_mode


static func set_god_mode(enabled: bool) -> void:
	god_mode = enabled