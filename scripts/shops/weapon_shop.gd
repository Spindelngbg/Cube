class_name WeaponShop
extends Area3D

const WEAPON_ID := "slimeshooter"

var _player_inside := false


func _ready() -> void:
	add_to_group("weapon_shop")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(9.0, 4.5, 7.0)
	shape.shape = box
	shape.position = Vector3(0.0, 2.0, 0.0)
	add_child(shape)


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	if InventoryManager.has_item(WEAPON_ID):
		if WeaponManager.can_use_slimeshooter():
			return "Slimeshooter utrustad"
		return "Utrusta Slimeshooter [E]"
	var price := ItemCatalog.get_shop_price(WEAPON_ID)
	return "Köp Slimeshooter (%d %s) [E]" % [price, ItemCatalog.currency_symbol()]


func try_purchase() -> bool:
	if InventoryManager.has_item(WEAPON_ID):
		if WeaponManager.equip(WEAPON_ID):
			QuestManager.story_toast.emit(
				"Vapenbutik",
				"%s utrustad." % ItemCatalog.get_display_name(WEAPON_ID)
			)
			return true
		return false

	var price := ItemCatalog.get_shop_price(WEAPON_ID)
	if not InventoryManager.spend_mydrillium(price):
		QuestManager.story_toast.emit(
			"Vapenbutik",
			"Du behöver %d %s för %s."
			% [price, ItemCatalog.currency_symbol(), ItemCatalog.get_display_name(WEAPON_ID)]
		)
		return false

	if not InventoryManager.add_item(WEAPON_ID):
		InventoryManager.add_mydrillium(price)
		QuestManager.story_toast.emit(
			"Vapenbutik",
			"Du äger redan %s." % ItemCatalog.get_display_name(WEAPON_ID)
		)
		return false

	WeaponManager.on_weapon_acquired(WEAPON_ID, true)
	QuestManager.story_toast.emit(
		"Vapenbutik",
		"%s köpt och utrustad.\nVänsterklick skjut | R ladda om"
		% ItemCatalog.get_display_name(WEAPON_ID)
	)
	return true


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false