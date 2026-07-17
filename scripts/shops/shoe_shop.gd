class_name ShoeShop
extends Area3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

const BOOTS_ID := "hoppskor"
const OWNER_NAME := "Sula-Sussi"

var _player_inside := false


func _ready() -> void:
	add_to_group("shoe_shop")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 3.2, 5.5)
	shape.shape = box
	shape.position = Vector3(0.0, 1.5, 0.0)
	add_child(shape)


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	var price := ItemCatalog.get_shop_price(BOOTS_ID)
	if InventoryManager.has_item(BOOTS_ID):
		if InventoryManager.is_wearing_footwear(BOOTS_ID):
			return "Hoppskor på fötterna — prata med %s [E]" % OWNER_NAME
		return "Ta på Hoppskor [E]"
	return "Köp Hoppskor (%d %s) [E]" % [price, ItemCatalog.currency_symbol()]


func try_purchase() -> bool:
	if InventoryManager.has_item(BOOTS_ID):
		if InventoryManager.is_wearing_footwear(BOOTS_ID):
			GameSfxScript.play_3d_varied(self, global_position, RpgAudioLibraryScript.bot_greet())
			QuestManager.story_toast.emit(
				OWNER_NAME,
				"De sitter redan på dig! Hoppa högt — du tar ingen fallskada med Hoppskor."
			)
			return true
		if InventoryManager.equip_footwear(BOOTS_ID):
			GameSfxScript.play_3d_varied(self, global_position, RpgAudioLibraryScript.pickup_weapon())
			QuestManager.story_toast.emit(
				OWNER_NAME,
				"Hoppskor på! Nu hoppar du 200% högre och landar mjukt."
			)
			return true
		return false

	var price := ItemCatalog.get_shop_price(BOOTS_ID)
	if not InventoryManager.spend_mydrillium(price):
		QuestManager.story_toast.emit(
			OWNER_NAME,
			"Du behöver %d %s för Hoppskor. Kom tillbaka när sulorna har råd."
			% [price, ItemCatalog.currency_symbol()]
		)
		return false

	if not InventoryManager.add_item(BOOTS_ID):
		InventoryManager.add_mydrillium(price)
		QuestManager.story_toast.emit(OWNER_NAME, "Inventory fullt — töm en slot och försök igen.")
		return false

	InventoryManager.equip_footwear(BOOTS_ID)
	GameSfxScript.play_3d_varied(self, global_position, RpgAudioLibraryScript.shop_buy())
	QuestManager.story_toast.emit(
		OWNER_NAME,
		"Klart! Hoppskor köpta och på. 200% högre hopp, noll fallskada. Gå inte vilse i skyn."
	)
	return true


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false
