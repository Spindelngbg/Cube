extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ONLINE_TOAST_SCENE := preload("res://scenes/ui/online_players_toast.tscn")
const NETWORK_MAP_SCENE := preload("res://scenes/ui/cube_network_map.tscn")
const MENU_THEME := preload("res://addons/settings_menus/resources/default_menu_theme.tres")
const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const QuestJournalUIScript = preload("res://scripts/ui/quest_journal_ui.gd")
const StoryToastUIScript = preload("res://scripts/ui/story_toast_ui.gd")
const StoryInteractableScript = preload("res://scripts/story/story_interactable.gd")
const NpcSpawnerScript = preload("res://scripts/npcs/npc_spawner.gd")
const HealthBarUIScript = preload("res://scripts/ui/health_bar_ui.gd")
const InventoryUIScript = preload("res://scripts/ui/inventory_ui.gd")
const ZezzlorSpawnerScript = preload("res://scripts/monsters/zezzlor_spawner.gd")
const GameTutorialUIScript = preload("res://scripts/ui/game_tutorial_ui.gd")
const ZnoodUIScript = preload("res://scripts/ui/znood_ui.gd")
const NavigationArrowUIScript = preload("res://scripts/ui/navigation_arrow_ui.gd")

var players: Dictionary = {}
var _active_spawn_id := ""
var _online_toast: OnlinePlayersToast
var _pause_menu: CubePauseMenu
var _network_map: CubeNetworkMap
var _monsters: Array[Node3D] = []
var _quest_journal: PanelContainer
var _story_toast: PanelContainer
var _near_story: Area3D
var _near_znood_door: Node3D
var _near_item_pickup: Node3D
var _near_pharmacy: Node3D
var _health_bar: PanelContainer
var _inventory_ui: PanelContainer
var _hybrid_bite_cooldowns: Dictionary = {}
var _zezzlors: Array[Node3D] = []
var _tutorial_ui: PanelContainer
var _znood_ui: ZnoodUI
var _navigation_arrow: NavigationArrowUI

@onready var _minimap: MinimapPanel = %Minimap
@onready var _owdb_bridge: Node = %WorldState
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D


func _ready() -> void:
	add_to_group("game_director")
	if not GameFlow.can_enter_world():
		call_deferred("_redirect_to_play_scene")
		return

	_hide_legacy_floor()
	_resolve_spawn_context()
	_build_world()
	_style_hud()
	_setup_minimap()
	_setup_network_map()
	_setup_world_database()
	_setup_pause_menu()
	_setup_online_toast()
	_setup_story_ui()
	_setup_health_ui()
	_setup_znood_ui()
	QuestManager.on_enter_colony(_active_spawn_id)
	_update_hud_text()
	_refresh_online_count()
	MouseLook.activate(_camera_pivot, _camera)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_spawn_player(multiplayer.get_unique_id())
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id)
		_request_avatars_from_peer.rpc_id(peer_id)
	call_deferred("_maybe_show_tutorial")


func _process(delta: float) -> void:
	_follow_local_player_camera(delta)
	_update_hud_text()
	_update_minimap()
	if _znood_ui:
		_znood_ui.update_world_context(players, _monsters)
	if Input.is_action_just_pressed("toggle_map"):
		if _network_map:
			_network_map.toggle()
	if Input.is_action_just_pressed("toggle_journal") and _quest_journal:
		_quest_journal.toggle()
	if Input.is_action_just_pressed("toggle_inventory") and _inventory_ui:
		_inventory_ui.toggle()
	if Input.is_action_just_pressed("toggle_tutorial"):
		GameTutorialManager.toggle()
	if Input.is_action_just_pressed("toggle_znood") and _znood_ui:
		_znood_ui.toggle()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	_update_znood_door_interaction()
	_update_item_pickup_interaction()
	_update_story_interaction()
	_update_pharmacy_interaction()
	_tick_story_witness()
	_tick_hybrid_bites(delta)
	_tick_poison(delta)


func _resolve_spawn_context() -> void:
	if Profile.has_home_spawn():
		_active_spawn_id = SpawnPoints.normalize_id(Profile.active_home_spawn_id)
	elif Auth.is_guest:
		_active_spawn_id = "satellite_left"
	else:
		push_error("Spelare utan vald koloni hamnade i game.tscn")
		get_tree().change_scene_to_file("res://scenes/emergence_room.tscn")
		return


func _hide_legacy_floor() -> void:
	var floor_node := get_node_or_null("Floor")
	if floor_node:
		floor_node.queue_free()


func _build_world() -> void:
	if _active_spawn_id != "":
		SatelliteCubeBuilder.build(self, _active_spawn_id)
		_configure_colony_rendering()
		var monsters_root := MonsterSpawner.populate(
			self,
			_active_spawn_id,
			SpawnPoints.get_extent_m(),
			_owdb_bridge,
			SpawnPoints.get_position(_active_spawn_id)
		)
		_collect_monsters(monsters_root)
		NpcSpawnerScript.populate(
			self,
			_active_spawn_id,
			SpawnPoints.get_position(_active_spawn_id),
			_owdb_bridge
		)
		var zone_mgr := RuntimeGlobals.zone_ownership()
		if zone_mgr:
			zone_mgr.setup_world_visuals(self, _active_spawn_id)
		call_deferred("_register_znood_pois")
	else:
		CubeCityBuilder.build(self)
		var zone_mgr := RuntimeGlobals.zone_ownership()
		if zone_mgr:
			zone_mgr.setup_world_visuals(self, "")
	if SpawnPoints.normalize_id(_active_spawn_id) != "satellite_right":
		$DirectionalLight3D.rotation_degrees = Vector3(-48, 35, 0)


func _register_znood_pois() -> void:
	await get_tree().process_frame
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr:
		znood_mgr.configure_spawn(_active_spawn_id)
		znood_mgr.ingest_markers_from_tree(self)


func _configure_colony_rendering() -> void:
	_camera.far = 120_000.0
	_camera.near = 0.05
	var is_exposed_city := SpawnPoints.normalize_id(_active_spawn_id) == "satellite_right"
	var env_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		var env := env_node.environment
		env.fog_enabled = true
		if is_exposed_city:
			env.ambient_light_color = Color(0.1, 0.13, 0.22)
			env.ambient_light_energy = 0.1
			env.fog_light_color = Color(0.14, 0.18, 0.28)
			env.fog_density = 0.0032
			env.fog_depth_begin = 28.0
			env.fog_depth_end = 5200.0
			env.fog_sky_affect = 0.1
			env.tonemap_exposure = 0.84
			env.glow_intensity = 0.72
			env.glow_strength = 0.9
		else:
			env.fog_density = 0.00004
			env.fog_depth_begin = 200.0
			env.fog_depth_end = 25_000.0

	var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		if is_exposed_city:
			sun.light_color = Color(0.58, 0.68, 0.92)
			sun.light_energy = 0.58
			sun.rotation_degrees = Vector3(-78, 18, 0)
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		else:
			sun.rotation_degrees = Vector3(-48, 35, 0)

	var fill := get_node_or_null("FillLight") as OmniLight3D
	if fill and is_exposed_city:
		fill.light_color = Color(0.32, 0.42, 0.62)
		fill.light_energy = 0.06
		fill.omni_range = 14.0


func _redirect_to_play_scene() -> void:
	get_tree().change_scene_to_file(GameFlow.play_scene_path())


func _exit_tree() -> void:
	MouseLook.deactivate()


func _follow_local_player_camera(_delta: float) -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player.has_method("get_camera_anchor_global_position"):
		_camera_pivot.global_position = player.get_camera_anchor_global_position()
	else:
		_camera_pivot.global_position = player.global_position + Vector3(0.0, 1.62, 0.08)
	var fill := get_node_or_null("FillLight") as OmniLight3D
	if fill:
		fill.global_position = player.global_position + Vector3(0.0, 10.0, 0.0)


func _update_hud_text() -> void:
	var hint := get_node_or_null("UI/Hint") as Label
	if hint == null:
		return

	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		hint.text = (
			"%s | %s | Vänsterklick = slem | R = ladda om"
			% [SpawnPoints.get_colony_label(_active_spawn_id), SpawnPoints.get_extent_label()]
		)
		return

	var cube_name := SpawnPoints.get_spawn_name(_active_spawn_id)
	var cube_id := SpawnPoints.get_cube_id(_active_spawn_id)
	var home_note := ""
	if Profile.has_home_spawn():
		home_note = " | Ditt permanenta hem"
	elif Auth.is_guest:
		home_note = " | Gäst (ingen hemplats)"

	var slime_note := ""
	if players[local_id].has_method("get_slime_status_text"):
		slime_note = " | %s" % players[local_id].get_slime_status_text()
	if players[local_id].has_method("get_hp_status_text"):
		slime_note += " | %s" % players[local_id].get_hp_status_text()
	var poison_note := PoisonManager.get_status_text()
	if poison_note != "":
		slime_note += " | %s" % poison_note
	slime_note += " | %s %s" % [
		ItemCatalog.currency_symbol(),
		_format_hud_mydrillium(InventoryManager.get_mydrillium()),
	]

	var quest_note := ""
	if QuestManager.get_hud_quest_hint() != "":
		quest_note = " | %s" % QuestManager.get_hud_quest_hint()
	var zone_note := _get_dc_zone_hint(players[local_id].global_position)
	if zone_note != "":
		quest_note += " | %s" % zone_note
	var interact_note := ""
	if _near_znood_door and _near_znood_door.has_method("get_prompt"):
		interact_note = " | %s" % _near_znood_door.get_prompt()
	elif _near_item_pickup and _near_item_pickup.has_method("get_prompt"):
		interact_note = " | %s" % _near_item_pickup.get_prompt()
	elif _near_story and _near_story.has_method("get_prompt"):
		interact_note = " | %s" % _near_story.get_prompt()
	elif _near_pharmacy and _near_pharmacy.has_method("get_prompt"):
		interact_note = " | %s" % _near_pharmacy.get_prompt()
	elif players.has(local_id):
		var zone_mgr := RuntimeGlobals.zone_ownership()
		var zone_buy_hint := ""
		if zone_mgr:
			zone_buy_hint = zone_mgr.get_hud_hint(
				players[local_id].global_position,
				_active_spawn_id
			)
		if zone_buy_hint.contains("[E]"):
			interact_note = " | %s" % zone_buy_hint

	hint.text = (
		"%s (%s)%s | WASD + mus | Shift = spring | Space = hopp | Z = Znood | I = inventory | J = journal | H = guide | M = kubnätverk | Escape = paus%s%s%s"
		% [cube_name, cube_id, home_note, slime_note, quest_note, interact_note]
	)


func _maybe_show_tutorial() -> void:
	if GameTutorialManager.should_auto_show():
		GameTutorialManager.show_tutorial(true)


func _on_peer_connected(peer_id: int) -> void:
	_spawn_player(peer_id)
	_request_avatars_from_peer.rpc_id(peer_id)
	_refresh_online_count()


@rpc("any_peer", "reliable")
func _request_avatars_from_peer() -> void:
	if not players.has(multiplayer.get_unique_id()):
		return
	var local_player: Node = players[multiplayer.get_unique_id()]
	local_player.respond_with_active_character()


func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)
	_refresh_online_count()


func _setup_minimap() -> void:
	if _minimap:
		_minimap.setup(_active_spawn_id, SpawnPoints.get_extent_m())


func _setup_network_map() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_network_map = NETWORK_MAP_SCENE.instantiate() as CubeNetworkMap
	ui.add_child(_network_map)
	_network_map.set_active_spawn(_active_spawn_id)


func _setup_world_database() -> void:
	if _owdb_bridge == null:
		return
	if _owdb_bridge.has_method("configure_for_spawn"):
		_owdb_bridge.configure_for_spawn(_active_spawn_id)


func _update_minimap() -> void:
	if _minimap:
		_minimap.update_players(players, multiplayer.get_unique_id(), _monsters)


func _style_hud() -> void:
	var hint := get_node_or_null("UI/Hint") as Label
	if hint == null:
		return
	SpiderTheme.style_status(hint)
	SpiderTheme.wrap_label_in_panel(hint)
	hint.offset_right = 1180.0
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _setup_pause_menu() -> void:
	_pause_menu = CubePauseMenu.new()
	_pause_menu.theme_data = MENU_THEME.duplicate() as MenuTheme
	_pause_menu.theme_data.game_title = "The Cube"
	_pause_menu.theme_data.accent = Color(0.77, 0.12, 0.22)
	_pause_menu.theme_data.accent_hover = Color(0.95, 0.22, 0.28)
	_pause_menu.main_menu_scene_path = "res://scenes/login.tscn"
	_pause_menu.main_menu_pressed.connect(func() -> void: Network.stop())
	_pause_menu.quit_pressed.connect(func() -> void: Network.stop())
	add_child(_pause_menu)


func _setup_story_ui() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_quest_journal = QuestJournalUIScript.new()
	ui.add_child(_quest_journal)
	_story_toast = StoryToastUIScript.new()
	ui.add_child(_story_toast)
	_tutorial_ui = GameTutorialUIScript.new()
	ui.add_child(_tutorial_ui)
	GameTutorialManager.bind_ui(_tutorial_ui)


func _setup_health_ui() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_health_bar = HealthBarUIScript.new()
	ui.add_child(_health_bar)
	ui.move_child(_health_bar, -1)
	_inventory_ui = InventoryUIScript.new()
	ui.add_child(_inventory_ui)


func _setup_znood_ui() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_znood_ui = ZnoodUIScript.new()
	ui.add_child(_znood_ui)
	ui.move_child(_znood_ui, -1)
	_navigation_arrow = NavigationArrowUIScript.new()
	ui.add_child(_navigation_arrow)


func get_local_player() -> Node3D:
	var local_id := multiplayer.get_unique_id()
	if players.has(local_id):
		return players[local_id]
	return null


func get_camera_pivot() -> Node3D:
	return _camera_pivot


func get_camera() -> Camera3D:
	return _camera


func should_capture_mouse() -> bool:
	if _pause_menu and _pause_menu.visible:
		return false
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr and znood_mgr.device_open:
		return false
	if _inventory_ui and _inventory_ui.visible:
		return false
	return true


func is_inventory_open() -> bool:
	return _inventory_ui != null and _inventory_ui.visible


func broadcast_znood_zezzlor_call(world_position: Vector3) -> void:
	var peer_id := multiplayer.get_unique_id()
	var label := "%s — Zezzlor" % _znood_backup_label()
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr:
		znood_mgr.add_backup_ping(
			peer_id,
			world_position,
			label,
			["zezzlor_response"],
			RuntimeGlobals.ZnoodScript.ZEZZLOR_BACKUP_DURATION_SEC,
			"zezzlor"
		)
	_sync_znood_backup_ping.rpc(
		world_position,
		label,
		["zezzlor_response"],
		RuntimeGlobals.ZnoodScript.ZEZZLOR_BACKUP_DURATION_SEC,
		"zezzlor"
	)
	QuestManager.story_toast.emit(
		"Znood → Zezzlor",
		"Signal skickad till närmaste Zezzlor-enhet. Orange markör syns på kartan."
	)


func broadcast_znood_group_backup(world_position: Vector3, groups: Array) -> void:
	var peer_id := multiplayer.get_unique_id()
	var label := "%s — BACKUP" % _znood_backup_label()
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr:
		znood_mgr.add_backup_ping(
			peer_id,
			world_position,
			label,
			groups,
			RuntimeGlobals.ZnoodScript.BACKUP_DURATION_SEC,
			"backup"
		)
	_sync_znood_backup_ping.rpc(
		world_position,
		label,
		groups,
		RuntimeGlobals.ZnoodScript.BACKUP_DURATION_SEC,
		"backup"
	)
	QuestManager.story_toast.emit(
		"Znood → Backup",
		"Din position blinkar rött på kartan för dina grupperingar."
	)


func _znood_backup_label() -> String:
	if Profile.active_character_name != "":
		return Profile.active_character_name
	if Auth.username != "":
		return Auth.username
	return "Kolonist"


@rpc("any_peer", "reliable")
func _sync_znood_backup_ping(
	world_position: Vector3,
	label: String,
	groups: Array,
	duration_sec: float,
	kind: String
) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id == multiplayer.get_unique_id():
		return
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr:
		znood_mgr.add_backup_ping(peer_id, world_position, label, groups, duration_sec, kind)


func _try_interact() -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if _near_znood_door and _near_znood_door.has_method("try_stamp"):
		if _near_znood_door.try_stamp(player):
			return
	if _near_item_pickup and _near_item_pickup.has_method("try_collect"):
		if _near_item_pickup.try_collect():
			return
	if _near_pharmacy and _near_pharmacy.has_method("try_purchase"):
		if _near_pharmacy.try_purchase():
			return
	if _near_story and _near_story.has_method("trigger"):
		_near_story.trigger()
		return
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr and zone_mgr.try_interact_purchase(player.global_position, _active_spawn_id):
		return


func _update_item_pickup_interaction() -> void:
	_near_item_pickup = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("item_pickup"):
		if not node.has_method("is_player_nearby"):
			continue
		if not node.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_item_pickup = node as Node3D


func _tick_hybrid_bites(delta: float) -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if not player.has_method("take_damage"):
		return

	var expired: Array = []
	for monster_id in _hybrid_bite_cooldowns:
		_hybrid_bite_cooldowns[monster_id] = float(_hybrid_bite_cooldowns[monster_id]) - delta
		if _hybrid_bite_cooldowns[monster_id] <= 0.0:
			expired.append(monster_id)
	for monster_id in expired:
		_hybrid_bite_cooldowns.erase(monster_id)

	for monster in _monsters:
		if not is_instance_valid(monster):
			continue
		if not monster.has_meta("is_src_hybrid") or not monster.get_meta("is_src_hybrid"):
			continue
		var dist := monster.global_position.distance_to(player.global_position)
		if dist > 2.15:
			continue
		var mid: int = monster.get_instance_id()
		if _hybrid_bite_cooldowns.has(mid):
			continue
		_hybrid_bite_cooldowns[mid] = 4.0
		player.take_damage(8.0)
		PoisonManager.apply_bite()
		break


func _tick_poison(delta: float) -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	PoisonManager.tick_dot(delta, players[local_id])


func _update_pharmacy_interaction() -> void:
	_near_pharmacy = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("pharmacy_shop"):
		if not node.has_method("is_player_nearby"):
			continue
		if not node.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_pharmacy = node as Node3D


func _update_znood_door_interaction() -> void:
	_near_znood_door = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("znood_door"):
		if not node.has_method("is_player_nearby"):
			continue
		if not node.is_player_nearby():
			continue
		if node.has_method("is_locked") and not node.is_locked():
			continue
		var dist := player.global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_znood_door = node as Node3D


func _update_story_interaction() -> void:
	_near_story = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("story_interactable"):
		if not node is Area3D:
			continue
		var interactable: Area3D = node as Area3D
		if not interactable.has_method("is_player_nearby"):
			continue
		if not interactable.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(interactable.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_story = interactable


func _get_dc_zone_hint(player_pos: Vector3) -> String:
	var zone_mgr := RuntimeGlobals.zone_ownership()
	var ownership_hint: String = zone_mgr.get_hud_hint(player_pos, _active_spawn_id) if zone_mgr else ""
	if ownership_hint != "":
		return ownership_hint
	if SpawnPoints.normalize_id(_active_spawn_id) != "satellite_right":
		return ""
	var spawn_pos := SpawnPoints.get_position(_active_spawn_id)
	var local := player_pos - spawn_pos
	var cell := Vector2i(
		int(floor(local.x / DcZoneCatalogScript.BLOCK_M)),
		int(floor(local.z / DcZoneCatalogScript.BLOCK_M))
	)
	var spec: Dictionary = DcZoneCatalogScript.classify_cell(cell)
	return str(spec.get("tag", ""))


func _tick_story_witness() -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var hybrids: Array = []
	for monster in _monsters:
		if monster.has_meta("is_src_hybrid") and monster.get_meta("is_src_hybrid"):
			hybrids.append(monster)
	QuestManager.tick_hybrid_witness(players[local_id].global_position, hybrids)


func _setup_online_toast() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_online_toast = ONLINE_TOAST_SCENE.instantiate() as OnlinePlayersToast
	ui.add_child(_online_toast)
	var badge := _online_toast.get_node_or_null("%Badge") as PanelContainer
	if badge:
		SpiderTheme.apply_to(badge)
		SpiderTheme.wrap_label_in_panel(_online_toast.get_node("%BadgeLabel") as Label)
	var popup := _online_toast.get_node_or_null("%Popup") as PanelContainer
	if popup:
		SpiderTheme.apply_to(popup)


func _refresh_online_count() -> void:
	if _online_toast == null:
		return
	var count := players.size()
	if count <= 0:
		count = Network.get_peer_count()
	_online_toast.set_player_count(count)


func _format_hud_mydrillium(amount: int) -> String:
	var text := str(maxi(amount, 0))
	if text.length() <= 3:
		return text
	var parts: PackedStringArray = []
	while text.length() > 3:
		parts.insert(0, text.substr(text.length() - 3, 3))
		text = text.substr(0, text.length() - 3)
	if text != "":
		parts.insert(0, text)
	return ",".join(parts)


func on_npc_murdered(shooter_id: int, crime_pos: Vector3, _npc_id: String) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	ZezzlorSpawnerScript.spawn_for_crime(self, crime_pos, shooter_id, players)


func register_zezzlor(zezzlor: Node3D) -> void:
	if zezzlor not in _zezzlors:
		_zezzlors.append(zezzlor)


func _collect_monsters(root: Node) -> void:
	_monsters.clear()
	if root == null:
		return
	for child in root.get_children():
		if child is Node3D:
			_monsters.append(child)


func _spawn_player(peer_id: int) -> void:
	if players.has(peer_id):
		return

	var spawn_pos := SpawnPoints.get_position(_active_spawn_id)
	if peer_id == multiplayer.get_unique_id() and Profile.has_home_spawn():
		spawn_pos = Profile.get_home_spawn_position()

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position = spawn_pos + Vector3(
		(peer_id % 3) * 1.5 - 1.5,
		0.0,
		(peer_id % 5) * 1.2 - 2.4
	)
	player.set_multiplayer_authority(peer_id)
	players[peer_id] = player
	$Players.add_child(player, true)
	if peer_id == multiplayer.get_unique_id():
		player.set_spawn_anchor(player.position)
		if _health_bar and _health_bar.has_method("bind_player"):
			_health_bar.bind_player(player)
		if _znood_ui:
			_znood_ui.bind_world_context(players, peer_id, _monsters)
	if _owdb_bridge != null and _owdb_bridge.has_method("register_runtime_entity"):
		_owdb_bridge.register_runtime_entity(
			player,
			"res://scenes/player.tscn",
			peer_id
		)