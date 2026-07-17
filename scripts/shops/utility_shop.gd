class_name UtilityShop
extends Area3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

const STOCK: Array[String] = [
	"forsta_hjalpen",
	"energi_dryck",
	"pansarväst",
	"kartfyr",
	"hoppskor",
]

var _player_inside := false
var _selected := 0


func _ready() -> void:
	add_to_group("utility_shop")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.5, 3.2, 5.5)
	shape.shape = box
	shape.position = Vector3(0.0, 1.5, 0.0)
	add_child(shape)


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	return "Överlevnadsbod — nyttiga grejer [E]"


func try_open_dialog(dialog_ui) -> bool:
	if dialog_ui == null:
		return false
	dialog_ui.open(STOCK)
	return true


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false
