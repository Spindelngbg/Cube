class_name MydrilliumServiceStation
extends Area3D

@export var station_kind := "refinery"
@export var zone_id := ""
@export var display_name := "Mydrillium-station"

var _player_inside := false
var _trade_ui: MydrilliumTradeUI


func _ready() -> void:
	add_to_group("mydrillium_station")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func setup(trade_ui: MydrilliumTradeUI) -> void:
	_trade_ui = trade_ui


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	match station_kind:
		"refinery":
			return "Raffinera mineral [E]"
		"trade_post":
			return "Mineralhandel [E]"
		"colony_hub":
			return "Koloniuppdrag [E]"
		"src_contract":
			return "SRC gråzons-kontrakt [E]"
		"drill_rental":
			return "Hyr borrlicens (%d %s) [E]" % [
				MydrilliumEconomyManager.DRILL_RENTAL_COST,
				ItemCatalog.currency_symbol(),
			]
		_:
			return "%s [E]" % display_name


func try_interact() -> bool:
	match station_kind:
		"refinery":
			var payout := MydrilliumEconomyManager.refine_all_at_station("refinery")
			if payout <= 0:
				QuestManager.story_toast.emit(
					display_name,
					"Inget mineral att raffinera. Hacka malm, muddra slam eller samla skrot."
				)
				return false
			QuestManager.story_toast.emit(
				"Raffinaderi",
				"+%d %s från mineral."
				% [payout, ItemCatalog.currency_symbol()]
			)
			_notify_arrival_refine()
			return true
		"trade_post":
			if _trade_ui == null:
				return false
			_trade_ui.open(self)
			return true
		"colony_hub":
			if _trade_ui == null:
				return false
			_trade_ui.open(self)
			return true
		"src_contract":
			return MydrilliumEconomyManager.try_src_contract()
		"drill_rental":
			return MydrilliumEconomyManager.try_rent_drill(zone_id)
		_:
			return false


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false


func _notify_arrival_refine() -> void:
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_local_player"):
		return
	var player: Node3D = game.get_local_player()
	if player != null:
		ArrivalQuestManager.notify_mineral_refined(player.global_position)