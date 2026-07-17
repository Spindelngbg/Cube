class_name FurnitureShop
extends Area3D

var _player_inside := false


func _ready() -> void:
	add_to_group("furniture_shop")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.0, 3.5, 6.0)
	shape.shape = box
	shape.position = Vector3(0.0, 1.6, 0.0)
	add_child(shape)


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	return "Möbelbutik — handla & placera [E]"


func try_open_dialog(dialog_ui) -> bool:
	if dialog_ui == null:
		return false
	dialog_ui.open()
	return true


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false
