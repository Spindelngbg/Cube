class_name PharmacyShop
extends Area3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

const REMEDY_ID := "hybrid_antidote"

var prompt_text := "Prata med Pill-Bot [E]"
var _player_inside := false
var _robot: CutePharmacyRobot


func _ready() -> void:
	add_to_group("pharmacy_shop")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func setup(robot: CutePharmacyRobot) -> void:
	_robot = robot


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	var price := ItemCatalog.get_shop_price(REMEDY_ID)
	if PoisonManager.is_poisoned():
		return "Köp Hybrid-Antidot (%d %s) [E]" % [price, ItemCatalog.currency_symbol()]
	return "Prata med Pill-Bot [E]"


func try_purchase() -> bool:
	if _robot:
		_robot.play_happy_reaction()

	var price := ItemCatalog.get_shop_price(REMEDY_ID)
	if not PoisonManager.is_poisoned():
		GameSfxScript.play_3d_varied(self, global_position, RpgAudioLibraryScript.bot_greet())
		QuestManager.story_toast.emit(
			"Pill-Bot",
			"Hej hej! Du ser frisk ut idag. Om en SRC-zombie biter dig kom tillbaka — jag har antidot!"
		)
		return true

	if not InventoryManager.spend_mydrillium(price):
		QuestManager.story_toast.emit(
			"Pill-Bot",
			"Oj då... du behöver %d %s för Hybrid-Antidot. Kom tillbaka när du har råd!"
			% [price, ItemCatalog.currency_symbol()]
		)
		return false

	PoisonManager.cure()
	InventoryManager.add_item(REMEDY_ID)
	GameSfxScript.play_3d_varied(self, global_position, RpgAudioLibraryScript.shop_buy())
	QuestManager.story_toast.emit(
		"Pill-Bot",
		"Yay! Giftet är borta nu. Ta det lugnt där ute bland hybridzombies!"
	)
	return true


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true
		if _robot:
			_robot.set_player_nearby(true)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false
		if _robot:
			_robot.set_player_nearby(false)