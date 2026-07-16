class_name WeaponCatalog
extends RefCounted

## Stridsstatistik för alla köpbara vapen (gevär + knivar).

const MELEE_KIND := "melee"

const SHOP_RANGED: Array[String] = [
	"slimeshooter",
	"mountblast_3000",
	"neon_stinger_mk2",
	"corrosion_cannon_x9",
	"plasma_ripper_7",
	"voltthrower_ultra",
]

const SHOP_MELEE: Array[String] = [
	"shadow_fang",
	"chitin_cleaver",
	"hsg_survival_axe",
	"src_stiletto",
	"redemption_blade",
	"zezzlor_gut_knife",
]

const WEAPONS := {
	"slimeshooter": {
		"combat_kind": "slime",
		"display_style": "slime_pistol",
		"damage": 50.0,
		"magazine_size": 8,
		"reload_time": 1.25,
		"fire_cooldown": 0.32,
		"projectile_speed": 30.0,
		"color": Color(0.18, 0.92, 0.28),
	},
	"laserrifle": {
		"combat_kind": "laser",
		"display_style": "laser_rifle",
		"damage": 24.0,
		"magazine_size": 12,
		"reload_time": 1.05,
		"fire_cooldown": 0.18,
		"projectile_speed": 52.0,
		"color": Color(0.35, 0.95, 1.0),
	},
	"mountblast_3000": {
		"combat_kind": "melt",
		"display_style": "melt_cannon",
		"damage": 78.0,
		"magazine_size": 5,
		"reload_time": 1.65,
		"fire_cooldown": 0.58,
		"projectile_speed": 26.0,
		"color": Color(1.0, 0.42, 0.12),
	},
	"neon_stinger_mk2": {
		"combat_kind": "laser",
		"display_style": "neon_pistol",
		"damage": 22.0,
		"magazine_size": 16,
		"reload_time": 0.95,
		"fire_cooldown": 0.11,
		"projectile_speed": 58.0,
		"color": Color(0.95, 0.2, 0.95),
	},
	"corrosion_cannon_x9": {
		"combat_kind": "slime",
		"display_style": "corrosion_rifle",
		"damage": 62.0,
		"magazine_size": 6,
		"reload_time": 1.45,
		"fire_cooldown": 0.42,
		"projectile_speed": 28.0,
		"color": Color(0.55, 0.95, 0.18),
	},
	"plasma_ripper_7": {
		"combat_kind": "energy",
		"display_style": "plasma_smg",
		"damage": 45.0,
		"magazine_size": 10,
		"reload_time": 1.15,
		"fire_cooldown": 0.24,
		"projectile_speed": 44.0,
		"color": Color(0.2, 0.82, 1.0),
	},
	"voltthrower_ultra": {
		"combat_kind": "volt",
		"display_style": "volt_rifle",
		"damage": 34.0,
		"magazine_size": 14,
		"reload_time": 1.0,
		"fire_cooldown": 0.14,
		"projectile_speed": 50.0,
		"color": Color(0.72, 0.95, 1.0),
	},
	"shadow_fang": {
		"combat_kind": MELEE_KIND,
		"display_style": "knife_dagger",
		"damage": 18.0,
		"melee_range": 2.1,
		"fire_cooldown": 0.28,
		"color": Color(0.22, 0.24, 0.3),
	},
	"chitin_cleaver": {
		"combat_kind": MELEE_KIND,
		"display_style": "knife_cleaver",
		"damage": 28.0,
		"melee_range": 2.35,
		"fire_cooldown": 0.42,
		"color": Color(0.45, 0.62, 0.48),
	},
	"hsg_survival_axe": {
		"combat_kind": MELEE_KIND,
		"display_style": "axe_survival",
		"damage": 36.0,
		"melee_range": 2.75,
		"fire_cooldown": 0.52,
		"color": Color(0.55, 0.42, 0.28),
	},
	"src_stiletto": {
		"combat_kind": MELEE_KIND,
		"display_style": "knife_stiletto",
		"damage": 24.0,
		"melee_range": 2.15,
		"fire_cooldown": 0.22,
		"color": Color(0.78, 0.18, 0.22),
	},
	"redemption_blade": {
		"combat_kind": MELEE_KIND,
		"display_style": "knife_sword",
		"damage": 42.0,
		"melee_range": 2.55,
		"fire_cooldown": 0.58,
		"color": Color(0.82, 0.72, 0.28),
	},
	"zezzlor_gut_knife": {
		"combat_kind": MELEE_KIND,
		"display_style": "knife_legendary",
		"damage": 55.0,
		"melee_range": 2.45,
		"fire_cooldown": 0.65,
		"color": Color(0.45, 0.72, 1.0),
	},
}


static func has_weapon(weapon_id: String) -> bool:
	return WEAPONS.has(weapon_id)


static func get_stats(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, {})


static func is_melee(weapon_id: String) -> bool:
	return str(get_stats(weapon_id).get("combat_kind", "")) == MELEE_KIND


static func is_ranged(weapon_id: String) -> bool:
	var kind := str(get_stats(weapon_id).get("combat_kind", ""))
	return kind != "" and kind != MELEE_KIND


static func get_damage(weapon_id: String) -> float:
	return float(get_stats(weapon_id).get("damage", 0.0))


static func get_melee_range(weapon_id: String) -> float:
	return float(get_stats(weapon_id).get("melee_range", 2.2))


static func get_melee_cooldown(weapon_id: String) -> float:
	return float(get_stats(weapon_id).get("fire_cooldown", 0.38))


static func get_display_style(weapon_id: String) -> String:
	return str(get_stats(weapon_id).get("display_style", "slime_pistol"))


static func all_shop_weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(SHOP_RANGED)
	ids.append_array(SHOP_MELEE)
	return ids