extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PlayerScript = preload("res://scripts/player.gd")
const ONLINE_TOAST_SCENE := preload("res://scenes/ui/online_players_toast.tscn")
const NETWORK_MAP_SCENE := preload("res://scenes/ui/cube_network_map.tscn")
const MENU_THEME := preload("res://addons/settings_menus/resources/default_menu_theme.tres")
const DcZoneCatalogScript = preload("res://scripts/city/dc_zone_catalog.gd")
const QuestJournalUIScript = preload("res://scripts/ui/quest_journal_ui.gd")
const StoryToastUIScript = preload("res://scripts/ui/story_toast_ui.gd")
const StoryInteractableScript = preload("res://scripts/story/story_interactable.gd")
const NpcSpawnerScript = preload("res://scripts/npcs/npc_spawner.gd")
const GleazerSpawnerScript = preload("res://scripts/npcs/gleazer_spawner.gd")
const AllmakareSpawnerScript = preload("res://scripts/npcs/allmakare_spawner.gd")
const PedestrianSpawnerScript = preload("res://scripts/npcs/pedestrian_spawner.gd")
const DeliveryBotSpawnerScript = preload("res://scripts/npcs/delivery_bot_spawner.gd")
const HelpRobotSpawnerScript = preload("res://scripts/npcs/help_robot_spawner.gd")
const HelpRobotDialogUIScript = preload("res://scripts/ui/help_robot_dialog_ui.gd")
const WeaponShopDialogUIScript = preload("res://scripts/ui/weapon_shop_dialog_ui.gd")
const ZezzlorDialogUIScript = preload("res://scripts/ui/zezzlor_dialog_ui.gd")
const ZezzlorDossierUIScript = preload("res://scripts/ui/zezzlor_dossier_ui.gd")
const FlyableHelicopterScript = preload("res://scripts/vehicles/flyable_helicopter.gd")
const ClimbVehicleSpawnerScript = preload("res://scripts/vehicles/climb_vehicle_spawner.gd")

const HealthBarUIScript = preload("res://scripts/ui/health_bar_ui.gd")
const ModularInventoryHudScript = preload("res://scripts/ui/modular_inventory_hud.gd")
const MydrilliumTradeUIScript = preload("res://scripts/ui/mydrillium_trade_ui.gd")
const ZonePurchaseDialogUIScript = preload("res://scripts/ui/zone_purchase_dialog_ui.gd")
const MydrilliumEconomyBuilderScript = preload("res://scripts/economy/mydrillium_economy_builder.gd")
const ZezzlorSpawnerScript = preload("res://scripts/monsters/zezzlor_spawner.gd")
const ZezzlorPatrolSpawnerScript = preload("res://scripts/monsters/zezzlor_patrol_spawner.gd")
const ZezzlaBotSpawnerScript = preload("res://scripts/monsters/zezzla_bot_spawner.gd")
const ZezzlorBackupMissionScript = preload("res://scripts/monsters/zezzlor_backup_mission.gd")
const MultiplayerEntityAuthorityScript = preload("res://scripts/multiplayer_entity_authority.gd")
const SuperZezzlorSpawnerScript = preload("res://scripts/monsters/super_zezzlor_spawner.gd")
const GameTutorialUIScript = preload("res://scripts/ui/game_tutorial_ui.gd")
const ZnoodUIScript = preload("res://scripts/ui/znood_ui.gd")
const NavigationArrowUIScript = preload("res://scripts/ui/navigation_arrow_ui.gd")
const HudClockUIScript = preload("res://scripts/ui/hud_clock_ui.gd")
const GameplayHudThemeScript = preload("res://scripts/ui/gameplay_hud_theme.gd")
const ExteriorLadderScript = preload("res://scripts/access/exterior_ladder.gd")
const DevWeaponToolsScript = preload("res://scripts/dev/dev_weapon_tools.gd")
const DevSpawnPanelScript = preload("res://scripts/dev/dev_spawn_panel.gd")
const CriminalBossHqBuilderScript = preload("res://scripts/access/criminal_boss_hq_builder.gd")
const CriminalBossSpawnerScript = preload("res://scripts/npcs/criminal_boss_spawner.gd")
const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")
const GreeneryVegetationBuilderScript = preload("res://scripts/city/greenery_vegetation_builder.gd")
const ZezzlorDossierRuntimeScript = preload("res://scripts/monsters/zezzlor_dossier_runtime.gd")
const CityKitLibraryScript = preload("res://scripts/assets/city_kit_library.gd")
const SpaceKitLibraryScript = preload("res://scripts/assets/space_kit_library.gd")
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
var _near_weapon_shop: Node3D
var _near_weapon_shop_owner: WeaponShopOwner
var _near_help_robot: HelpRobot
var _near_climb_vehicle: WallCrawlVehicle
var _near_exterior_ladder: ExteriorLadderScript
var _near_economy_station: MydrilliumServiceStation
var _near_harvest_node: MydrilliumHarvestNode
var _health_bar: PanelContainer
var _inventory_ui: Control
var _hybrid_bite_cooldowns: Dictionary = {}
const HYBRID_BITE_RANGE := 1.2
const HYBRID_BITE_COOLDOWN := 9.0
const HYBRID_INFECTION_CHANCE := 0.32
var _zezzlors: Array[Node3D] = []
var _tutorial_ui: PanelContainer
var _znood_ui: ZnoodUI
var _navigation_arrow: NavigationArrowUI
var _helicopter: FlyableHelicopter
var _help_dialog_ui: HelpRobotDialogUI
var _weapon_shop_dialog_ui: WeaponShopDialogUI
var _mydrillium_trade_ui: MydrilliumTradeUI
var _zone_purchase_dialog_ui: ZonePurchaseDialogUI
var _zezzlor_dialog_ui: ZezzlorDialogUI
var _zezzlor_dossier_ui: ZezzlorDossierUI
var _near_zezzlor_hq: ZezzlorHq
var _hud_clock: HudClockUI
const HUD_UPDATE_INTERVAL := 0.35
const MINIMAP_UPDATE_INTERVAL := 0.25
const INTERACTION_SCAN_INTERVAL := 0.16
const WORLD_TICK_INTERVAL := 0.2
const ZNOOD_UI_UPDATE_INTERVAL := 0.3
var _hud_timer := 0.0
var _minimap_timer := 0.0
var _interaction_timer := 0.0
var _world_tick_timer := 0.0
var _znood_ui_timer := 0.0
var _mouse_capture_allowed := true

@onready var _minimap: MinimapPanel = %Minimap
@onready var _owdb_bridge: Node = %WorldState
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D


func _ready() -> void:
	add_to_group("game_director")
	if not GameFlow.can_enter_world():
		call_deferred("_redirect_to_play_scene")
		return

	SceneTransition.show_spawn_loading_briefing("Laddar", "Bygger koloni och värld...")
	await get_tree().process_frame
	call_deferred("_boot_world")


func _boot_world() -> void:
	_hide_legacy_floor()
	if not _resolve_spawn_context():
		SceneTransition.mark_spawn_loading_ready("Kunde inte ladda spawn — tryck Fortsätt.")
		await SceneTransition.wait_spawn_briefing_dismissed()
		return

	_build_world_geometry()
	_style_hud()
	_setup_minimap()
	_setup_network_map()
	_setup_world_database()
	_setup_pause_menu()
	_setup_online_toast()
	_setup_story_ui()
	_setup_hud_clock()
	_setup_health_ui()
	_setup_mydrillium_economy()
	_setup_znood_ui()
	_connect_zone_spawn_signals()
	QuestManager.on_enter_colony(_active_spawn_id)
	ArrivalQuestManager.on_enter_colony(_active_spawn_id)
	ArmamentQuestManager.on_enter_colony(_active_spawn_id)
	SpiderQuestManager.on_enter_colony(_active_spawn_id)
	_update_hud_text()
	_refresh_online_count()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_spawn_player(multiplayer.get_unique_id())
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id)
		_request_avatars_from_peer.rpc_id(peer_id)
	SceneTransition.mark_spawn_loading_ready()
	await SceneTransition.wait_spawn_briefing_dismissed()
	ArrivalQuestManager.on_briefing_dismissed()
	ArmamentQuestManager.on_briefing_dismissed()
	MouseLook.activate(_camera_pivot, _camera)
	restore_gameplay_mouse()
	call_deferred("_finish_world_bootstrap")


func _process(delta: float) -> void:
	_refresh_mouse_capture_cache()
	_follow_local_player_camera(delta)
	_hud_timer += delta
	if _hud_timer >= HUD_UPDATE_INTERVAL:
		_hud_timer = 0.0
		_update_hud_text()
	_minimap_timer += delta
	if _minimap_timer >= MINIMAP_UPDATE_INTERVAL:
		_minimap_timer = 0.0
		_update_minimap()
	if _znood_ui and _znood_ui.visible:
		_znood_ui_timer += delta
		if _znood_ui_timer >= ZNOOD_UI_UPDATE_INTERVAL:
			_znood_ui_timer = 0.0
			_znood_ui.update_world_context(players, _monsters)
	if Input.is_action_just_pressed("toggle_map"):
		if _network_map:
			_network_map.toggle()
	if Input.is_action_just_pressed("toggle_journal") and _quest_journal:
		_quest_journal.toggle()
		if _quest_journal.visible:
			ArrivalQuestManager.notify_open_journal()
	if Input.is_action_just_pressed("toggle_inventory") and _inventory_ui:
		_inventory_ui.toggle()
		if _inventory_ui.is_panel_open():
			ArrivalQuestManager.notify_open_inventory()
	if Input.is_action_just_pressed("toggle_tutorial"):
		GameTutorialManager.toggle()
	if Input.is_action_just_pressed("toggle_znood") and _znood_ui:
		_znood_ui.toggle()
	if OS.is_debug_build() and Input.is_action_just_pressed("dev_grant_weapon"):
		DevWeaponToolsScript.grant_slimeshooter()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	_interaction_timer += delta
	if _interaction_timer >= INTERACTION_SCAN_INTERVAL:
		_interaction_timer = 0.0
		_update_znood_door_interaction()
		_update_item_pickup_interaction()
		_update_story_interaction()
		_update_pharmacy_interaction()
		_update_weapon_shop_interaction()
		_update_weapon_shop_owner_interaction()
		_update_help_robot_interaction()
		_update_zezzlor_hq_interaction()
		_update_climb_vehicle_interaction()
		_update_exterior_ladder_interaction()
		_update_economy_station_interaction()
		_update_harvest_node_interaction()
		_tick_story_witness()
	_world_tick_timer += delta
	if _world_tick_timer >= WORLD_TICK_INTERVAL:
		var world_step := _world_tick_timer
		_world_tick_timer = 0.0
		MydrilliumEconomyManager.tick(world_step, get_local_player())
		_tick_gleazer_quests(world_step)
		_tick_hybrid_bites(world_step)
		_tick_poison(world_step)


func _resolve_spawn_context() -> bool:
	if GameFlow.debug_spawn_override != "" and SpawnPoints.is_valid(GameFlow.debug_spawn_override):
		_active_spawn_id = SpawnPoints.normalize_id(GameFlow.debug_spawn_override)
		return true
	if Profile.has_home_spawn():
		_active_spawn_id = SpawnPoints.ensure_colony_id(Profile.active_home_spawn_id)
	elif Auth.is_guest:
		_active_spawn_id = SpawnPoints.default_colony_id()
	else:
		push_error("Spelare utan vald koloni hamnade i game.tscn")
		get_tree().change_scene_to_file("res://scenes/emergence_room.tscn")
		return false
	return true


func _hide_legacy_floor() -> void:
	var floor_node := get_node_or_null("Floor")
	if floor_node:
		floor_node.queue_free()


func _build_world_geometry() -> void:
	CityKitLibraryScript.warmup_dc_city_models()
	SpaceKitLibraryScript.warmup_common_models()
	if _active_spawn_id != "":
		SatelliteCubeBuilder.build(self, _active_spawn_id)
		_configure_colony_rendering()
	else:
		CubeCityBuilder.build(self)


func _finish_world_bootstrap() -> void:
	GuiFontLibraryScript.fix_label3d_tree(self)
	_populate_world_entities()
	_build_deferred_greenery()
	call_deferred("_register_znood_pois")
	call_deferred("_start_poi_guide")
	# Om-spawna fötterna när all världskollision finns (undvik under mark / i hus).
	var local_id := multiplayer.get_unique_id()
	if players.has(local_id):
		_align_player_to_floor.call_deferred(players[local_id])
	call_deferred("_notify_armament_weapon_sources")


func _populate_world_entities() -> void:
	if _active_spawn_id == "":
		var zone_mgr := RuntimeGlobals.zone_ownership()
		if zone_mgr:
			zone_mgr.setup_world_visuals(self, "")
		return

	var spawn_pos := _shift_world(SpawnPoints.get_play_spawn_position(_active_spawn_id))
	var monsters_root := MonsterSpawner.populate(
		self,
		_active_spawn_id,
		SpawnPoints.get_extent_m(),
		_owdb_bridge,
		spawn_pos
	)
	_collect_monsters(monsters_root)
	SuperZezzlorSpawnerScript.populate(self, _active_spawn_id, spawn_pos, _owdb_bridge)
	ZezzlorPatrolSpawnerScript.populate(self, _active_spawn_id, _owdb_bridge)
	NpcSpawnerScript.populate(self, _active_spawn_id, spawn_pos, _owdb_bridge)
	GleazerSpawnerScript.populate(self, _active_spawn_id, spawn_pos, _owdb_bridge)
	AllmakareSpawnerScript.populate(self, _active_spawn_id, spawn_pos, _owdb_bridge)
	PedestrianSpawnerScript.populate(self, _active_spawn_id, spawn_pos, _owdb_bridge)
	DeliveryBotSpawnerScript.populate(self, _active_spawn_id, _owdb_bridge)
	HelpRobotSpawnerScript.populate(self, _active_spawn_id, _owdb_bridge)
	CriminalBossHqBuilderScript.place_all(self, _active_spawn_id, spawn_pos)
	CriminalBossSpawnerScript.populate(self, _active_spawn_id, spawn_pos, _owdb_bridge)
	ZezzlaBotSpawnerScript.populate(self, _active_spawn_id, _owdb_bridge)
	ClimbVehicleSpawnerScript.populate(self, _active_spawn_id, _owdb_bridge)
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr:
		zone_mgr.setup_world_visuals(self, _active_spawn_id)


func _build_deferred_greenery() -> void:
	if _active_spawn_id != "satellite_right":
		return
	var city := get_node_or_null("Satellite_satellite_right/NeoWashington") as Node3D
	if city:
		GreeneryVegetationBuilderScript.build(city, _active_spawn_id)


func _register_znood_pois() -> void:
	await get_tree().process_frame
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr:
		znood_mgr.configure_spawn(_active_spawn_id)
		znood_mgr.ingest_markers_from_tree(self)


func _start_poi_guide() -> void:
	PoiGuideManager.begin_colony_session(self, _active_spawn_id)


func get_active_spawn_id() -> String:
	return _active_spawn_id


func _configure_colony_rendering() -> void:
	var is_exposed_city := SpawnPoints.normalize_id(_active_spawn_id) == "satellite_right"
	DrawDistance.apply_colony(self, is_exposed_city)

	var fill := get_node_or_null("FillLight") as OmniLight3D
	if fill and is_exposed_city:
		fill.light_color = Color(0.32, 0.42, 0.62)
		fill.light_energy = 0.06
		fill.omni_range = 14.0
		fill.shadow_enabled = false


func refresh_draw_distance() -> void:
	if _active_spawn_id == "":
		return
	_configure_colony_rendering()


func _redirect_to_play_scene() -> void:
	get_tree().change_scene_to_file(GameFlow.play_scene_path())


func _exit_tree() -> void:
	PoiGuideManager.stop_guide()
	MouseLook.deactivate()


func _follow_local_player_camera(_delta: float) -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player.has_method("is_piloting_vehicle") and player.is_piloting_vehicle():
		var vehicle: Node3D = player.get_piloting_vehicle()
		player.global_position = vehicle.global_position
		if vehicle.has_method("get_camera_anchor_global_position"):
			_camera_pivot.global_position = vehicle.get_camera_anchor_global_position()
		else:
			_camera_pivot.global_position = vehicle.global_position + Vector3(0.0, 1.75, 0.35)
	elif player.has_method("get_camera_anchor_global_position"):
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
		hint.text = "%s | %s" % [
			SpawnPoints.get_colony_label(_active_spawn_id),
			SpawnPoints.get_extent_label(),
		]
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
	elif _near_weapon_shop_owner and _near_weapon_shop_owner.has_method("get_prompt"):
		interact_note = " | %s" % _near_weapon_shop_owner.get_prompt()
	elif _near_help_robot and _near_help_robot.has_method("get_prompt"):
		interact_note = " | %s" % _near_help_robot.get_prompt()
	elif _near_zezzlor_hq and _near_zezzlor_hq.is_player_nearby():
		interact_note = " | %s" % _near_zezzlor_hq.get_prompt()
	elif _near_climb_vehicle and _near_climb_vehicle.has_method("get_prompt"):
		interact_note = " | %s" % _near_climb_vehicle.get_prompt()
	elif _near_exterior_ladder and _near_exterior_ladder.has_method("get_prompt"):
		interact_note = " | %s" % _near_exterior_ladder.get_prompt()
	elif _near_harvest_node and _near_harvest_node.has_method("get_prompt"):
		interact_note = " | %s" % _near_harvest_node.get_prompt()
	elif _near_economy_station and _near_economy_station.has_method("get_prompt"):
		interact_note = " | %s" % _near_economy_station.get_prompt()
	elif players.has(local_id) and players[local_id].has_method("is_piloting_vehicle") and players[local_id].is_piloting_vehicle():
		interact_note = " | Hoppa av fordon [E]"
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

	var parts: PackedStringArray = PackedStringArray(["%s (%s)%s" % [cube_name, cube_id, home_note]])
	if slime_note.strip_edges() != "":
		parts.append(slime_note.strip_edges().trim_prefix("|").strip_edges())
	if quest_note.strip_edges() != "":
		parts.append(quest_note.strip_edges().trim_prefix("|").strip_edges())
	if interact_note.strip_edges() != "":
		parts.append(interact_note.strip_edges().trim_prefix("|").strip_edges())
	if MouseLook.is_active() and MouseLook.is_cursor_user_free():
		parts.append("Alt = lås sikt igen")
	hint.text = " | ".join(parts)


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
	GameplayHudThemeScript.style_status(hint)
	GameplayHudThemeScript.wrap_label_in_panel(hint)
	hint.offset_right = 1180.0
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _setup_pause_menu() -> void:
	_pause_menu = CubePauseMenu.new()
	_pause_menu.main_menu_scene_path = "res://scenes/login.tscn"
	_pause_menu.main_menu_pressed.connect(func() -> void: Network.stop())
	_pause_menu.quit_pressed.connect(func() -> void: Network.stop())
	_pause_menu.resumed.connect(_on_pause_resumed)
	add_child(_pause_menu)


func _setup_hud_clock() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_hud_clock = HudClockUIScript.new()
	ui.add_child(_hud_clock)


func _setup_story_ui() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	_quest_journal = QuestJournalUIScript.new()
	ui.add_child(_quest_journal)
	_story_toast = StoryToastUIScript.new()
	ui.add_child(_story_toast)
	_help_dialog_ui = HelpRobotDialogUIScript.new()
	ui.add_child(_help_dialog_ui)
	_weapon_shop_dialog_ui = WeaponShopDialogUIScript.new()
	ui.add_child(_weapon_shop_dialog_ui)
	_weapon_shop_dialog_ui.closed.connect(_on_weapon_shop_dialog_closed)
	_mydrillium_trade_ui = MydrilliumTradeUIScript.new()
	ui.add_child(_mydrillium_trade_ui)
	_mydrillium_trade_ui.closed.connect(_on_mydrillium_trade_closed)
	_zone_purchase_dialog_ui = ZonePurchaseDialogUIScript.new()
	ui.add_child(_zone_purchase_dialog_ui)
	_zone_purchase_dialog_ui.closed.connect(_on_zone_purchase_dialog_closed)
	_zezzlor_dialog_ui = ZezzlorDialogUIScript.new()
	ui.add_child(_zezzlor_dialog_ui)
	_zezzlor_dialog_ui.response_picked.connect(_on_zezzlor_response_picked)
	_zezzlor_dialog_ui.closed.connect(_on_zezzlor_dialog_closed)
	_zezzlor_dossier_ui = ZezzlorDossierUIScript.new()
	ui.add_child(_zezzlor_dossier_ui)
	_zezzlor_dossier_ui.closed.connect(_on_zezzlor_dossier_closed)
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
	var dev_panel := DevSpawnPanelScript.new()
	ui.add_child(dev_panel)
	_inventory_ui = ModularInventoryHudScript.new()
	_inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_inventory_ui)


func _setup_mydrillium_economy() -> void:
	var satellite := get_node_or_null("Satellite_%s" % _active_spawn_id)
	if satellite == null or _mydrillium_trade_ui == null:
		return
	if _active_spawn_id == "satellite_right":
		var neo := satellite.get_node_or_null("NeoWashington")
		if neo:
			MydrilliumEconomyBuilderScript.build_dc_economy(neo, _mydrillium_trade_ui)
	else:
		var hub := satellite.get_node_or_null("ArrivalHub")
		if hub:
			MydrilliumEconomyBuilderScript.build_hub_economy(hub, _mydrillium_trade_ui, _active_spawn_id)


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


func shift_world_position(logical: Vector3) -> Vector3:
	return _shift_world(logical)


func logical_world_position(shifted: Vector3) -> Vector3:
	return _logical_world(shifted)


func _shift_world(logical: Vector3) -> Vector3:
	if _active_spawn_id == "":
		return logical
	return SpawnPoints.to_shifted_world(logical, _active_spawn_id)


func _logical_world(shifted: Vector3) -> Vector3:
	if _active_spawn_id == "":
		return shifted
	return SpawnPoints.to_logical_world(shifted, _active_spawn_id)


func _is_shifted_spawn_usable(feet_pos: Vector3) -> bool:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return true
	return PlayerScript.is_shifted_spawn_usable(space, feet_pos)


func _snap_spawn_to_floor(feet_pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		feet_pos.y = maxf(feet_pos.y, SpawnPoints.SPAWN_FOOT_Y)
		return feet_pos
	var floor_y := PlayerScript.find_highest_floor_y(space, feet_pos, feet_pos.y)
	if floor_y > PlayerScript.MIN_WALKABLE_FLOOR_Y:
		feet_pos.y = PlayerScript._feet_y_on_floor(floor_y)
	else:
		feet_pos.y = SpawnPoints.SPAWN_FOOT_Y
	return feet_pos


func get_camera_pivot() -> Node3D:
	return _camera_pivot


func get_camera() -> Camera3D:
	return _camera


func _refresh_mouse_capture_cache() -> void:
	_mouse_capture_allowed = _compute_mouse_capture_allowed()


func should_capture_mouse() -> bool:
	return _mouse_capture_allowed


func _compute_mouse_capture_allowed() -> bool:
	if _pause_menu and _pause_menu.visible:
		return false
	var znood_mgr := RuntimeGlobals.znood()
	if znood_mgr and znood_mgr.device_open:
		return false
	if _inventory_ui and _inventory_ui.is_panel_open():
		return false
	if _quest_journal and _quest_journal.visible:
		return false
	if _tutorial_ui and _tutorial_ui.has_method("is_open") and _tutorial_ui.is_open():
		return false
	if _zezzlor_dialog_ui and _zezzlor_dialog_ui.is_open():
		return false
	if _help_dialog_ui and _help_dialog_ui.is_open():
		return false
	if _weapon_shop_dialog_ui and _weapon_shop_dialog_ui.is_open():
		return false
	if _mydrillium_trade_ui and _mydrillium_trade_ui.is_open():
		return false
	if _zone_purchase_dialog_ui and _zone_purchase_dialog_ui.is_open():
		return false
	if _zezzlor_dossier_ui and _zezzlor_dossier_ui.is_open():
		return false
	if SceneTransition.is_spawn_briefing_visible():
		return false
	if GlobalChat != null and GlobalChat.has_method("is_chat_open") and GlobalChat.is_chat_open():
		return false
	if _network_map != null and _network_map.visible:
		return false
	var local_player := get_local_player()
	if local_player != null and local_player.has_method("is_zezzlor_jailed") and local_player.is_zezzlor_jailed():
		return false
	return true


func _on_pause_resumed() -> void:
	if _camera_pivot and _camera:
		MouseLook.activate(_camera_pivot, _camera)


func is_inventory_open() -> bool:
	return _inventory_ui != null and _inventory_ui.is_panel_open()


func broadcast_znood_zezzlor_call(world_position: Vector3, trouble_direction: Vector3 = Vector3.ZERO) -> void:
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
		"Tung Zezzlor-APC på väg. Håll siktet åt problemet och förbered svar."
	)
	if multiplayer.multiplayer_peer == null or peer_id == MultiplayerEntityAuthorityScript.simulation_peer_id():
		_dispatch_zezzlor_backup(peer_id, world_position, trouble_direction)


func _dispatch_zezzlor_backup(caller_peer_id: int, call_pos: Vector3, trouble_direction: Vector3) -> void:
	if not players.has(caller_peer_id):
		return
	var caller: Node3D = players[caller_peer_id]
	if caller == null:
		return
	var dir := trouble_direction
	if dir.length_squared() < 0.01:
		dir = -caller.global_transform.basis.z
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
	var mission := ZezzlorBackupMissionScript.new()
	mission.name = "ZezzlorBackupMission"
	add_child(mission)
	mission.start(self, caller, call_pos, dir, _active_spawn_id)


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


func open_zezzlor_conversation(
	zezzlor: Node3D,
	question: String,
	title: String,
	context: String
) -> void:
	if _zezzlor_dialog_ui == null or zezzlor == null:
		return
	if _help_dialog_ui and _help_dialog_ui.is_open():
		_help_dialog_ui.close_panel()
	_zezzlor_dialog_ui.open(zezzlor, question, title, context)


func _on_zezzlor_response_picked(response_id: String) -> void:
	if _zezzlor_dialog_ui == null:
		return
	var zezzlor: Node3D = _zezzlor_dialog_ui.get_zezzlor()
	if zezzlor != null and zezzlor.has_method("on_player_response"):
		zezzlor.on_player_response(response_id)


func _on_zezzlor_dialog_closed(zezzlor: Node3D) -> void:
	if zezzlor != null and zezzlor.has_method("on_dialog_dismissed"):
		zezzlor.on_dialog_dismissed()
	restore_gameplay_mouse()


func _on_zezzlor_dossier_closed() -> void:
	restore_gameplay_mouse()


func restore_gameplay_mouse() -> void:
	call_deferred("_restore_gameplay_mouse_now")


func _restore_gameplay_mouse_now() -> void:
	if should_capture_mouse() and _camera_pivot and _camera:
		MouseLook.activate(_camera_pivot, _camera)


func _notify_arrival_interact() -> void:
	var player := get_local_player()
	if player == null:
		return
	ArrivalQuestManager.notify_nearby_interact(player.global_position)
	_notify_armament_weapon_sources()
	SpiderQuestManager.notify_spider_rumor()


func _notify_armament_weapon_sources() -> void:
	if _has_weapon_in_inventory() or _near_weapon_shop_owner != null or _near_weapon_shop != null:
		ArmamentQuestManager.notify_weapon_source()
	if WeaponManager.can_use_equipped_weapon():
		ArmamentQuestManager.notify_equipped()


func _has_weapon_in_inventory() -> bool:
	for weapon_id in ChatCheatCommands.WEAPON_IDS:
		if InventoryManager.has_item(weapon_id):
			return true
	return (
		InventoryManager.has_item(WeaponManager.SLIMESHOOTER_ID)
		or InventoryManager.has_item(WeaponManager.LASERRIFLE_ID)
	)


func _try_interact() -> void:
	if _zezzlor_dossier_ui and _zezzlor_dossier_ui.is_open():
		_zezzlor_dossier_ui.close_panel()
		return
	if _zezzlor_dialog_ui and _zezzlor_dialog_ui.is_open():
		_zezzlor_dialog_ui.close_panel()
		return
	if _help_dialog_ui and _help_dialog_ui.is_open():
		_help_dialog_ui.close_panel()
		return
	if _weapon_shop_dialog_ui and _weapon_shop_dialog_ui.is_open():
		_weapon_shop_dialog_ui.close_panel()
		return
	if _mydrillium_trade_ui and _mydrillium_trade_ui.is_open():
		_mydrillium_trade_ui.close_panel()
		return
	if _zone_purchase_dialog_ui and _zone_purchase_dialog_ui.is_open():
		_zone_purchase_dialog_ui.close_panel()
		return
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player.has_method("is_piloting_vehicle") and player.is_piloting_vehicle():
		var vehicle: Node3D = player.get_piloting_vehicle()
		if vehicle and vehicle.has_method("dismount_pilot"):
			vehicle.dismount_pilot(player)
		return
	if _near_climb_vehicle and _near_climb_vehicle.has_method("try_mount"):
		if _near_climb_vehicle.try_mount(player):
			return
	if _near_znood_door and _near_znood_door.has_method("try_stamp"):
		if _near_znood_door.try_stamp(player):
			return
	if _near_item_pickup and _near_item_pickup.has_method("try_collect"):
		if _near_item_pickup.try_collect():
			_notify_arrival_interact()
			return
	if _near_harvest_node and _near_harvest_node.has_method("try_harvest"):
		if _near_harvest_node.try_harvest():
			return
	if _near_economy_station and _near_economy_station.has_method("try_interact"):
		if _near_economy_station.try_interact():
			_notify_arrival_interact()
			return
	if _near_pharmacy and _near_pharmacy.has_method("try_purchase"):
		if _near_pharmacy.try_purchase():
			_notify_arrival_interact()
			return
	if _near_weapon_shop_owner and _near_weapon_shop_owner.has_method("try_open_dialog"):
		if _help_dialog_ui and _help_dialog_ui.is_open():
			_help_dialog_ui.close_panel()
		if _near_weapon_shop_owner.try_open_dialog(_weapon_shop_dialog_ui):
			_notify_arrival_interact()
			return
	if _near_help_robot and _near_help_robot.has_method("try_open_dialog"):
		if _near_help_robot.try_open_dialog(_help_dialog_ui):
			_notify_arrival_interact()
			return
	if _near_zezzlor_hq and _near_zezzlor_hq.is_player_nearby():
		_open_zezzlor_dossier(_near_zezzlor_hq)
		return
	if _near_story and _near_story.has_method("trigger"):
		_near_story.trigger()
		_notify_arrival_interact()
		return
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr:
		var zone_action := zone_mgr.get_zone_interact_action(player.global_position, _active_spawn_id)
		match zone_action:
			"spawn":
				zone_mgr.try_interact_building_spawn(player.global_position, _active_spawn_id)
				return
			"dialog":
				var context := zone_mgr.build_zone_dialog_context(
					player.global_position,
					_active_spawn_id
				)
				if not context.is_empty() and _zone_purchase_dialog_ui:
					_zone_purchase_dialog_ui.open(zone_mgr, context)
				return


func _update_climb_vehicle_interaction() -> void:
	_near_climb_vehicle = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player.has_method("is_piloting_vehicle") and player.is_piloting_vehicle():
		return
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("climb_vehicle"):
		if not node is WallCrawlVehicle:
			continue
		var vehicle := node as WallCrawlVehicle
		if not vehicle.can_mount(player):
			continue
		var dist := player.global_position.distance_to(vehicle.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_climb_vehicle = vehicle


func _update_exterior_ladder_interaction() -> void:
	_near_exterior_ladder = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player.has_method("is_piloting_vehicle") and player.is_piloting_vehicle():
		return
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("exterior_ladder"):
		if not node is ExteriorLadderScript:
			continue
		var ladder := node as ExteriorLadderScript
		if not ladder.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(ladder.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_exterior_ladder = ladder


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
		if dist > HYBRID_BITE_RANGE:
			continue
		var mid: int = monster.get_instance_id()
		if _hybrid_bite_cooldowns.has(mid):
			continue
		_hybrid_bite_cooldowns[mid] = HYBRID_BITE_COOLDOWN
		player.take_damage(6.0)
		PoisonManager.try_apply_bite(HYBRID_INFECTION_CHANCE)
		break


func _tick_poison(delta: float) -> void:
	PoisonManager.tick_immunity(delta)
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	PoisonManager.tick_dot(delta, players[local_id])


func _update_help_robot_interaction() -> void:
	_near_help_robot = null
	if _help_dialog_ui and _help_dialog_ui.is_open():
		return
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("help_robot"):
		if not node is HelpRobot:
			continue
		var robot := node as HelpRobot
		if not robot.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(robot.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_help_robot = robot


func _update_zezzlor_hq_interaction() -> void:
	_near_zezzlor_hq = null
	if _zezzlor_dossier_ui and _zezzlor_dossier_ui.is_open():
		return
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("zezzlor_hq"):
		if not node is ZezzlorHq:
			continue
		var hq := node as ZezzlorHq
		if not hq.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(hq.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_zezzlor_hq = hq


func _open_zezzlor_dossier(hq: ZezzlorHq) -> void:
	if _zezzlor_dossier_ui == null or hq == null:
		return
	var local_id := multiplayer.get_unique_id()
	var report: String = ZezzlorDossierRuntimeScript.get_report_text(local_id)
	_zezzlor_dossier_ui.open(report, hq.hq_label)
	QuestManager.story_toast.emit("Zezzlor HQ", "Dossier utlämnat enligt ordningsprotokoll.")


func _on_local_player_died() -> void:
	ZezzlorDossierRuntimeScript.reset_for_player(multiplayer.get_unique_id())
	var local_id := multiplayer.get_unique_id()
	if players.has(local_id):
		ZezzlorHuntManager.end_hunt(players[local_id])


func _update_weapon_shop_interaction() -> void:
	_near_weapon_shop = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("weapon_shop"):
		if not node.has_method("is_player_nearby"):
			continue
		if not node.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_weapon_shop = node as Node3D


func _update_weapon_shop_owner_interaction() -> void:
	_near_weapon_shop_owner = null
	if _weapon_shop_dialog_ui and _weapon_shop_dialog_ui.is_open():
		return
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("weapon_shop_owner"):
		if not node is WeaponShopOwner:
			continue
		var owner := node as WeaponShopOwner
		if not owner.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(owner.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_weapon_shop_owner = owner


func _on_weapon_shop_dialog_closed() -> void:
	_notify_armament_weapon_sources()
	restore_gameplay_mouse()


func _on_mydrillium_trade_closed() -> void:
	restore_gameplay_mouse()


func _on_zone_purchase_dialog_closed() -> void:
	restore_gameplay_mouse()


func _update_economy_station_interaction() -> void:
	_near_economy_station = null
	if _mydrillium_trade_ui and _mydrillium_trade_ui.is_open():
		return
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("mydrillium_station"):
		if not node is MydrilliumServiceStation:
			continue
		var station := node as MydrilliumServiceStation
		if not station.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(station.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_economy_station = station


func _update_harvest_node_interaction() -> void:
	_near_harvest_node = null
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("mydrillium_harvest"):
		if not node is MydrilliumHarvestNode:
			continue
		var harvest := node as MydrilliumHarvestNode
		if not harvest.is_player_nearby():
			continue
		var dist := player.global_position.distance_to(harvest.global_position)
		if dist < best_dist:
			best_dist = dist
			_near_harvest_node = harvest


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
	var logical_player := _logical_world(player_pos)
	var spawn_pos := SpawnPoints.get_position(_active_spawn_id)
	var local := logical_player - spawn_pos
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


func _tick_gleazer_quests(delta: float) -> void:
	if not GleazerQuestManager.has_active_quest():
		return
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player != null and player.is_multiplayer_authority():
		GleazerQuestManager.tick(player, delta)


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


func on_npc_murdered(shooter_id: int, crime_pos: Vector3, npc_id: String) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	ZezzlorDossierRuntimeScript.record_crime(shooter_id, crime_pos, _active_spawn_id, npc_id)
	ZezzlorDossierRuntimeScript.record_hunt_started(shooter_id)
	if players.has(shooter_id):
		ZezzlorHuntManager.begin_hunt(players[shooter_id], crime_pos)
	ZezzlorSpawnerScript.spawn_for_crime(self, crime_pos, shooter_id, players)


func register_zezzlor(zezzlor: Node3D) -> void:
	if zezzlor not in _zezzlors:
		_zezzlors.append(zezzlor)


func unregister_monster(monster: Node3D) -> void:
	var idx := _monsters.find(monster)
	if idx >= 0:
		_monsters.remove_at(idx)


func _collect_monsters(root: Node) -> void:
	_monsters.clear()
	if root == null:
		return
	for child in root.get_children():
		if child is Node3D:
			_monsters.append(child)


func _connect_zone_spawn_signals() -> void:
	var zone_mgr := RuntimeGlobals.zone_ownership()
	if zone_mgr == null:
		return
	if not zone_mgr.building_spawn_set.is_connected(_on_building_spawn_set):
		zone_mgr.building_spawn_set.connect(_on_building_spawn_set)


func _resolve_player_spawn_position(peer_id: int) -> Vector3:
	var colony_id := SpawnPoints.ensure_colony_id(_active_spawn_id)
	var spawn_pos := SpawnPoints.get_play_spawn_position(colony_id)
	if peer_id == multiplayer.get_unique_id():
		var zone_mgr := RuntimeGlobals.zone_ownership()
		if zone_mgr:
			var building_pos := zone_mgr.get_preferred_building_spawn_position(colony_id)
			if building_pos != Vector3.ZERO and _is_logical_spawn_usable(building_pos):
				spawn_pos = building_pos
	return _shift_world(spawn_pos)


func _is_logical_spawn_usable(logical_feet_pos: Vector3) -> bool:
	return _is_shifted_spawn_usable(_shift_world(logical_feet_pos))


func _on_building_spawn_set(world_pos: Vector3) -> void:
	var local_id := multiplayer.get_unique_id()
	if not players.has(local_id):
		return
	var player: Node3D = players[local_id]
	if player.has_method("set_spawn_anchor"):
		player.set_spawn_anchor(_shift_world(world_pos))


func _align_player_to_floor(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	# Vänta tills statisk kollision från världen finns i physics-servern.
	for _i in range(24):
		await get_tree().physics_frame
	if not is_instance_valid(player):
		return
	for _pass in range(3):
		if not is_instance_valid(player):
			return
		if player.has_method("ensure_safe_ground"):
			player.ensure_safe_ground()
		elif player.has_method("snap_to_floor"):
			player.snap_to_floor()
		for _i in range(4):
			await get_tree().physics_frame


func _spawn_player(peer_id: int) -> void:
	if players.has(peer_id):
		return

	var colony_id := SpawnPoints.ensure_colony_id(_active_spawn_id)
	var spawn_pos := _resolve_player_spawn_position(peer_id)
	if not _is_shifted_spawn_usable(spawn_pos):
		spawn_pos = SpawnPoints.get_shifted_play_spawn(colony_id)
	spawn_pos = _snap_spawn_to_floor(spawn_pos)

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
		player.set_spawn_anchor(spawn_pos)
		_align_player_to_floor.call_deferred(player)
		if player.has_signal("died") and not player.died.is_connected(_on_local_player_died):
			player.died.connect(_on_local_player_died)
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