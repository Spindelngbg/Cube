extends Node

const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")

signal debt_changed

const BASE_FEE := 120
const HP_FEE_MULT := 1.8

var _debts: Dictionary = {}


func has_debt(peer_id: int = -1) -> bool:
	return _get_debt(peer_id).size() > 0


func get_debt(peer_id: int = -1) -> Dictionary:
	return _get_debt(peer_id)


func get_creditor_id(peer_id: int = -1) -> String:
	return str(_get_debt(peer_id).get("creditor_id", ""))


func on_interact(creditor_id: String, payload: Dictionary) -> void:
	var peer_id := _local_peer_id()
	var debt := _get_debt(peer_id)
	if debt.size() > 0 and str(debt.get("creditor_id", "")) == creditor_id:
		_try_pay(peer_id, debt)
		return
	_offer_heal(creditor_id, payload)


func should_smell_follow(creditor_id: String) -> Dictionary:
	for peer_id in _debts:
		var debt: Dictionary = _debts[peer_id]
		if str(debt.get("creditor_id", "")) == creditor_id:
			return debt
	return {}


func calculate_fee(player: Node3D) -> int:
	if player == null or not player.has_method("get_health_snapshot"):
		return BASE_FEE + 80
	var snap: Dictionary = player.get_health_snapshot()
	var cur := float(snap.get("current", 0.0))
	var max_hp := float(snap.get("max", 100.0))
	var missing := maxf(0.0, max_hp - cur)
	return int(round(BASE_FEE + missing * HP_FEE_MULT))


func _offer_heal(creditor_id: String, payload: Dictionary) -> void:
	var peer_id := _local_peer_id()
	var existing := _get_debt(peer_id)
	if not existing.is_empty():
		NpcDialogueBarkScript.play_for_id(creditor_id, "refusal")
		QuestManager.story_toast.emit(
			"Allmakare — skuld",
			"Du är redan skyldig %d %s till %s. Betala först."
			% [
				int(existing.get("amount", 0)),
				ItemCatalog.currency_symbol(),
				str(existing.get("creditor_name", "Allmakare")),
			]
		)
		return

	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.get("players") is Dictionary:
		return
	if not game.players.has(peer_id):
		return
	var player: Node3D = game.players[peer_id]
	if not player.is_multiplayer_authority():
		return

	var snap: Dictionary = player.get_health_snapshot() if player.has_method("get_health_snapshot") else {}
	var cur := float(snap.get("current", 0.0))
	var max_hp := float(snap.get("max", 100.0))
	if cur >= max_hp - 0.5 and not PoisonManager.is_poisoned():
		NpcDialogueBarkScript.play_for_id(creditor_id, "miscellaneous")
		QuestManager.story_toast.emit(
			"Allmakare",
			"Du är redan frisk. Vi helar bara när det behövs — och fakturerar direkt."
		)
		return

	var fee := calculate_fee(player)
	var name := str(payload.get("allmakare_name", "Allmakare"))
	if player.has_method("heal_to_full"):
		player.heal_to_full()
	PoisonManager.cure()

	_debts[peer_id] = {
		"creditor_id": creditor_id,
		"creditor_name": name,
		"amount": fee,
	}
	_broadcast_debt(peer_id, _debts[peer_id])
	debt_changed.emit()
	NpcDialogueBarkScript.play_for_id(creditor_id, "confirmation")
	NpcDialogueBarkScript.play_for_id(creditor_id, "greeting")
	QuestManager.story_toast.emit(
		"Allmakare — %s" % name,
		"Du är helad. Luktspåret är aktivt — betala %d %s eller vi följer din doft."
		% [fee, ItemCatalog.currency_symbol()]
	)


func _try_pay(peer_id: int, debt: Dictionary) -> void:
	var amount := int(debt.get("amount", 0))
	if amount <= 0:
		_debts.erase(peer_id)
		debt_changed.emit()
		return
	if not InventoryManager.spend_mydrillium(amount):
		if MydrilliumEconomyManager.try_pay_allmakare_with_ore(str(debt.get("creditor_id", ""))):
			return
		NpcDialogueBarkScript.play_for_id(str(debt.get("creditor_id", "")), "refusal")
		QuestManager.story_toast.emit(
			"Allmakare — betalning",
			"Inte tillräckligt med %s eller malm. Vi känner din lukt — vi väntar."
			% ItemCatalog.currency_name()
		)
		return
	_debts.erase(peer_id)
	_broadcast_debt(peer_id, {})
	debt_changed.emit()
	NpcDialogueBarkScript.play_for_id(str(debt.get("creditor_id", "")), "completion")
	QuestManager.story_toast.emit(
		"Allmakare — betalt",
		"%d %s mottaget. Luktspåret släpps — tills nästa heal."
		% [amount, ItemCatalog.currency_symbol()]
	)


func _get_debt(peer_id: int = -1) -> Dictionary:
	var id := peer_id if peer_id >= 0 else _local_peer_id()
	if not _debts.has(id):
		return {}
	return _debts[id]


func get_debt_for_peer(peer_id: int) -> Dictionary:
	return _get_debt(peer_id)


func clear_debt_for_peer(peer_id: int = -1) -> void:
	var id := peer_id if peer_id >= 0 else _local_peer_id()
	if not _debts.has(id):
		return
	_debts.erase(id)
	_broadcast_debt(id, {})
	debt_changed.emit()


func _broadcast_debt(peer_id: int, entry: Dictionary) -> void:
	var tree := get_tree()
	if tree == null or tree.get_multiplayer().multiplayer_peer == null:
		return
	if tree.get_multiplayer().is_server():
		_apply_debt_sync.rpc(peer_id, entry)
	else:
		_apply_debt_sync.rpc_id(1, peer_id, entry)


@rpc("any_peer", "call_local", "reliable")
func _apply_debt_sync(peer_id: int, entry: Dictionary) -> void:
	if entry.is_empty():
		_debts.erase(peer_id)
	else:
		_debts[peer_id] = entry
	debt_changed.emit()


func _local_peer_id() -> int:
	var tree := get_tree()
	if tree == null:
		return 1
	return tree.get_multiplayer().get_unique_id()