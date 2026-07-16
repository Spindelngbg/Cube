extends SceneTree
func _init():
    call_deferred('_go')
func _go():
    var paths = ["res://scripts/ui/cube_network_map.gd","res://scripts/avatar_animator.gd","res://scripts/npcs/world_npc.gd","res://scripts/cube/satellite_cube_builder.gd","res://scripts/npcs/allmakare_catalog.gd","res://scripts/monsters/zezzlor_backup_mission.gd","res://scripts/audio/player_damage_grunt_library.gd","res://scripts/city/zezzlor_pa_manager.gd","res://scripts/world/spawn_density.gd","res://scripts/npcs/pedestrian_catalog.gd","res://scripts/combat/slime_projectile.gd"]
    for p in paths:
        ResourceLoader.load(p, '', ResourceLoader.CACHE_MODE_IGNORE)
    quit()
