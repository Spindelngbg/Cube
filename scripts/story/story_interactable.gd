class_name StoryInteractable
extends Area3D

@export var interact_id := ""
@export var prompt_text := "Tryck [E]"

var _player_inside := false


func _ready() -> void:
	add_to_group("story_interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 1


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	return prompt_text


func trigger() -> void:
	## Låt föräldra-NPC hantera dialog (alla world_npc m.m.).
	var host := get_parent()
	if host != null and host.has_method("on_player_talk"):
		host.on_player_talk()
		return
	if interact_id == "":
		return
	QuestManager.on_interact(interact_id)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false