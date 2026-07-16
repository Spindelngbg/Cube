class_name StreetLampService
extends RefCounted

const StreetLampRepairBotScript = preload("res://scripts/npcs/street_lamp_repair_bot.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")

static var _lamps: Array[StreetLamp] = []
static var _bots: Array[StreetLampRepairBot] = []


static func reset() -> void:
	_lamps.clear()
	_bots.clear()


static func register(lamp: StreetLamp) -> void:
	if lamp == null or lamp in _lamps:
		return
	_lamps.append(lamp)
	lamp.add_to_group("street_lamp")


static func get_broken_lamps() -> Array[StreetLamp]:
	var broken: Array[StreetLamp] = []
	for lamp in _lamps:
		if is_instance_valid(lamp) and lamp.is_broken():
			broken.append(lamp)
	return broken


static func get_nearest_broken(from: Vector3) -> StreetLamp:
	var best: StreetLamp = null
	var best_dist := 999999.0
	for lamp in get_broken_lamps():
		var dist := from.distance_to(lamp.global_position)
		if dist < best_dist:
			best_dist = dist
			best = lamp
	return best


static func finalize_for_city(city_root: Node3D, spawn_center: Vector3) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var broken := get_broken_lamps()
	if broken.is_empty():
		return

	var bot_count := mini(2, maxi(1, broken.size() / 4))
	var spawn_offsets := [
		spawn_center + Vector3(8.0, 0.0, 14.0),
		spawn_center + Vector3(-10.0, 0.0, 18.0),
		spawn_center + Vector3(16.0, 0.0, -6.0),
	]
	for i in range(bot_count):
		var bot: StreetLampRepairBot = StreetLampRepairBotScript.new()
		bot.name = "LuxBot_%d" % i
		if tree.get_multiplayer().multiplayer_peer != null:
			bot.set_multiplayer_authority(MultiplayerEntityAuthorityScript.simulation_peer_id())
		city_root.add_child(bot)
		bot.setup(spawn_offsets[i % spawn_offsets.size()], hash("lux_bot_%d" % i))
		_bots.append(bot)


static func lamp_count() -> int:
	return _lamps.size()