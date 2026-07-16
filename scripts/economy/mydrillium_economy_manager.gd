extends Node

signal colony_quest_changed
signal trade_completed

const NpcDialogueBarkScript = preload("res://scripts/audio/npc_dialogue_bark.gd")
const MydrilliumColonyQuestCatalogScript = preload(
	"res://scripts/economy/mydrillium_colony_quest_catalog.gd"
)
const MydrilliumMaterialCatalogScript = preload(
	"res://scripts/economy/mydrillium_material_catalog.gd"
)

const TRADE_PLAYER_DISCOUNT := 0.92
const SRC_CONTRACT_BONUS_MULT := 1.35
const DRILL_RENTAL_COST := 180
const DRILL_RENTAL_DURATION := 120.0
const ORE_PER_DEBT_UNIT := 3
const ZONE_OWNER_CUT := 0.18

var _active_colony_quest: Dictionary = {}
var _drill_rental_timer := 0.0
var _drill_rental_zone := ""
var _dredge_cooldown := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_roll_colony_quest()


func has_active_colony_quest() -> bool:
	return not _active_colony_quest.is_empty()


func get_active_colony_quest() -> Dictionary:
	return _active_colony_quest.duplicate(true)


func is_drill_rental_active() -> bool:
	return _drill_rental_timer > 0.0


func tick(delta: float, local_player: Node3D) -> void:
	_drill_rental_timer = maxf(0.0, _drill_rental_timer - delta)
	_dredge_cooldown = maxf(0.0, _dredge_cooldown - delta)
	if local_player != null and local_player.has_method("is_swimming") and local_player.is_swimming():
		_try_passive_dredge(local_player)


func refine_material(material_id: String, amount: int, station_kind: String = "refinery") -> int:
	if amount <= 0 or not MydrilliumMaterialCatalogScript.is_material(material_id):
		return 0
	var have := InventoryManager.get_material_count(material_id)
	var take := mini(amount, have)
	if take <= 0:
		return 0
	if not InventoryManager.remove_material(material_id, take):
		return 0
	var unit := MydrilliumMaterialCatalogScript.get_refine_value(material_id)
	var payout := unit * take
	if station_kind == "trade_post":
		payout = int(round(float(payout) * TRADE_PLAYER_DISCOUNT))
	_pay_zone_owner_if_rented(payout)
	InventoryManager.add_mydrillium(payout)
	trade_completed.emit()
	return payout


func refine_all_at_station(station_kind: String = "refinery") -> int:
	var total := 0
	for material_id in MydrilliumMaterialCatalogScript.all_material_ids():
		total += refine_material(material_id, InventoryManager.get_material_count(material_id), station_kind)
	return total


func try_complete_colony_quest() -> bool:
	if _active_colony_quest.is_empty():
		return false
	var material := str(_active_colony_quest.get("material", ""))
	var need := int(_active_colony_quest.get("amount", 0))
	var bonus := int(_active_colony_quest.get("bonus_md", 0))
	if not InventoryManager.remove_material(material, need):
		QuestManager.story_toast.emit(
			"Koloniuppdrag",
			"Du behÃ¶ver %d %s fÃ¶r att slutfÃ¶ra uppdraget."
			% [need, MydrilliumMaterialCatalogScript.get_display_name(material)]
		)
		return false
	InventoryManager.add_mydrillium(bonus)
	QuestManager.story_toast.emit(
		"Koloniuppdrag klart",
		"%s\n+%d %s bonus frÃ¥n kolonin."
		% [str(_active_colony_quest.get("title", "")), bonus, ItemCatalog.currency_symbol()]
	)
	_roll_colony_quest()
	colony_quest_changed.emit()
	return true


func try_src_contract() -> bool:
	var need := 2
	if not InventoryManager.remove_material("contaminated_ore", need):
		if InventoryManager.get_material_count("raw_mydrillium_ore") >= 4:
			if not InventoryManager.remove_material("raw_mydrillium_ore", 4):
				return false
			QuestManager.story_toast.emit(
				"SRC-kontrakt",
				"SRC accepterar vanlig malm som ersÃ¤ttning â€” lÃ¤gre risk, lÃ¤gre betalning."
			)
			var payout := int(45 * 4 * SRC_CONTRACT_BONUS_MULT)
			InventoryManager.add_mydrillium(payout)
			if _rng.randf() < 0.22:
				PoisonManager.try_apply_bite(0.55)
			return true
		QuestManager.story_toast.emit(
			"SRC-kontrakt",
			"Leverera 2 kontaminerad malm eller 4 rÃ¥ malm fÃ¶r grÃ¥zons-betalning."
		)
		return false
	var pay := int(MydrilliumMaterialCatalogScript.get_refine_value("contaminated_ore") * need * SRC_CONTRACT_BONUS_MULT)
	InventoryManager.add_mydrillium(pay)
	QuestManager.story_toast.emit(
		"SRC-kontrakt",
		"GrÃ¥ leverans mottagen. +%d %s. SRC loggar inte det hÃ¤r â€” officiellt."
		% [pay, ItemCatalog.currency_symbol()]
	)
	if _rng.randf() < 0.38:
		PoisonManager.try_apply_bite(0.7)
	return true


func try_rent_drill(zone_id: String = "") -> bool:
	if is_drill_rental_active():
		QuestManager.story_toast.emit(
			"Borrhyra",
			"Du har redan aktiv borrlicens (%ds kvar)." % int(ceil(_drill_rental_timer))
		)
		return false
	if not InventoryManager.spend_mydrillium(DRILL_RENTAL_COST):
		QuestManager.story_toast.emit(
			"Borrhyra",
			"Borrlicens kostar %d %s." % [DRILL_RENTAL_COST, ItemCatalog.currency_symbol()]
		)
		return false
	_drill_rental_timer = DRILL_RENTAL_DURATION
	_drill_rental_zone = zone_id
	_pay_zone_owner_if_rented(DRILL_RENTAL_COST, true)
	QuestManager.story_toast.emit(
		"Borrhyra aktiv",
		"+%d sek snabbare malmhack i %d %s. ZonÃ¤gare fÃ¥r andel."
		% [int(DRILL_RENTAL_DURATION), DRILL_RENTAL_COST, ItemCatalog.currency_symbol()]
	)
	return true


func try_pay_allmakare_with_ore(creditor_id: String) -> bool:
	var peer_id := _local_peer_id()
	var debt: Dictionary = AllmakareDebtManager.get_debt(peer_id)
	if debt.is_empty():
		return false
	var amount_md := int(debt.get("amount", 0))
	var ore_unit := MydrilliumMaterialCatalogScript.get_refine_value("raw_mydrillium_ore")
	var ore_need := maxi(1, ceili(float(amount_md) / float(ore_unit)))
	ore_need = mini(ore_need, ORE_PER_DEBT_UNIT * 4)
	if not InventoryManager.remove_material("raw_mydrillium_ore", ore_need):
		QuestManager.story_toast.emit(
			"Allmakare â€” malmbetalning",
			"Du behÃ¶ver %d rÃ¥ malm fÃ¶r att betala skulden med mineral."
			% ore_need
		)
		return false
	AllmakareDebtManager.clear_debt_for_peer(peer_id)
	NpcDialogueBarkScript.play_for_id(creditor_id, "completion")
	QuestManager.story_toast.emit(
		"Allmakare â€” malm mottagen",
		"%d malm ersatte %d %s skuld. LuktspÃ¥ret slÃ¤ppt."
		% [ore_need, amount_md, ItemCatalog.currency_symbol()]
	)
	return true


func try_gift_material_to_player(target_peer_id: int, material_id: String, amount: int) -> bool:
	if amount <= 0 or not MydrilliumMaterialCatalogScript.is_material(material_id):
		return false
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.get("players") is Dictionary:
		return false
	if not game.players.has(target_peer_id):
		return false
	var target: Node = game.players[target_peer_id]
	if target == null or not target.is_multiplayer_authority():
		QuestManager.story_toast.emit("Handel", "Kan bara handla med spelare i nÃ¤rheten.")
		return false
	if not InventoryManager.remove_material(material_id, amount):
		return false
	_gift_material.rpc_id(target_peer_id, material_id, amount, Auth.username)
	return true


func harvest_from_node(material_id: String, base_amount: int = 1) -> int:
	var amount := base_amount
	if is_drill_rental_active():
		amount += 1
	if not InventoryManager.add_material(material_id, amount):
		return 0
	return amount


func rob_pedestrian_wallet(npc: Node, robber_id: int) -> int:
	if npc == null or not npc.is_in_group("pedestrian_npc"):
		return 0
	var wallet: int = int(npc.get("_wallet")) if npc.get("_wallet") != null else 0
	if wallet <= 0:
		return 0
	var steal := mini(wallet, _rng.randi_range(40, 220))
	npc.set("_wallet", wallet - steal)
	if robber_id < 0:
		return 0
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.players.has(robber_id):
		return 0
	var player: Node = game.players[robber_id]
	if player == null or not player.is_multiplayer_authority():
		return 0
	InventoryManager.add_mydrillium(steal)
	QuestManager.story_toast.emit(
		"PlÃ¥nbok rÃ¥nad",
		"Du tog %d %s frÃ¥n %s."
		% [steal, ItemCatalog.currency_symbol(), str(npc.get("_display_name"))]
	)
	return steal


@rpc("any_peer", "call_local", "reliable")
func _gift_material(material_id: String, amount: int, from_name: String) -> void:
	InventoryManager.add_material(material_id, amount)
	QuestManager.story_toast.emit(
		"Mineral mottagen",
		"%s skickade %d %s till dig."
		% [from_name, amount, MydrilliumMaterialCatalogScript.get_display_name(material_id)]
	)


func _try_passive_dredge(player: Node3D) -> void:
	if _dredge_cooldown > 0.0:
		return
	if _rng.randf() > 0.18:
		return
	_dredge_cooldown = 2.8
	if InventoryManager.add_material("mydrillium_sludge", 1):
		QuestManager.story_toast.emit(
			"Muddring",
			"+1 Mydrillium-slam filtrerat ur vattnet."
		)


func _roll_colony_quest() -> void:
	var quests: Array = MydrilliumColonyQuestCatalogScript.QUESTS
	if quests.is_empty():
		_active_colony_quest = {}
		return
	_active_colony_quest = (quests[_rng.randi() % quests.size()] as Dictionary).duplicate(true)
	colony_quest_changed.emit()


func _pay_zone_owner_if_rented(gross: int, is_rental_fee: bool = false) -> void:
	if _drill_rental_zone == "" or gross <= 0:
		return
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr == null:
		return
	var entry: Dictionary = zone_mgr.get_zone_record(_drill_rental_zone) if zone_mgr.has_method("get_zone_record") else {}
	var owner := str(entry.get("owner_account", ""))
	if owner == "" or owner == Auth.username:
		return
	var cut := int(round(float(gross) * ZONE_OWNER_CUT))
	if cut <= 0:
		return
	# Zone owner payout is simulated as colony credit toast for local renter feedback.
	var label := "borrhyra" if is_rental_fee else "raffinaderiavgift"
	QuestManager.story_toast.emit(
		"ZonintÃ¤kt",
		"%d %s gick till zonÃ¤gare %s (%s)."
		% [cut, ItemCatalog.currency_symbol(), owner, label]
	)


func _local_peer_id() -> int:
	var tree := get_tree()
	if tree == null:
		return 1
	return tree.get_multiplayer().get_unique_id()
