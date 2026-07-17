class_name WeaponShop
extends Area3D

var area_size := Vector3(13.0, 5.0, 8.0)
var area_offset := Vector3(0.0, 2.25, 0.0)
var _player_inside := false


func _ready() -> void:
	add_to_group("weapon_shop")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = area_size
	shape.shape = box
	shape.position = area_offset
	add_child(shape)


func is_player_nearby() -> bool:
	return _player_inside


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false
