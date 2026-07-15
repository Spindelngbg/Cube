extends Node

var _world_arrival_pending := false


func mark_world_arrival() -> void:
	_world_arrival_pending = true


func consume_world_arrival() -> bool:
	var pending := _world_arrival_pending
	_world_arrival_pending = false
	return pending