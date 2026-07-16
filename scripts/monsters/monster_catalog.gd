class_name MonsterCatalog
extends RefCounted

## Spawn definitions per satellitkub. Sci-Fi-modeller från Quaternius Essentials,
## plus procedurella spindlar som kompletterar bestiariet.

const SCI_FI_MODELS := {
	"trilobite": {
		"model": "Enemy_Trilobite",
		"name": "Trilobitjägare",
		"scale": 1.15,
		"speed": 2.4,
		"y_offset": 0.0,
	},
	"eye_drone": {
		"model": "Enemy_EyeDrone",
		"name": "Ögondrone",
		"scale": 0.95,
		"speed": 3.2,
		"y_offset": 0.6,
	},
	"quad_shell": {
		"model": "Enemy_QuadShell",
		"name": "Pansarskal",
		"scale": 1.05,
		"speed": 1.8,
		"y_offset": 0.0,
	},
}

const HYBRID_ARCHETYPES := {
	"crawler": {
		"name": "SRC-Zombie MK.I",
		"scale": 1.0,
		"speed": 1.4,
		"body_scale": 1.1,
		"leg_length": 1.2,
		"spider_leg_count": 8,
		"eye_count": 4,
		"drone": "Enemy_EyeDrone",
	},
	"stalker": {
		"name": "Mekspindel-Hybrid",
		"scale": 1.05,
		"speed": 2.0,
		"body_scale": 1.0,
		"leg_length": 1.45,
		"spider_leg_count": 8,
		"eye_count": 6,
		"drone": "Enemy_EyeDrone",
	},
	"drone_host": {
		"name": "Ögondrone-Värd",
		"scale": 0.95,
		"speed": 2.6,
		"body_scale": 0.9,
		"leg_length": 1.15,
		"spider_leg_count": 6,
		"eye_count": 8,
		"drone": "Enemy_QuadShell",
	},
}

const SPIDER_ARCHETYPES := {
	"stalker": {
		"name": "Stalkerspindel",
		"scale": 0.9,
		"speed": 3.0,
		"body_scale": 0.85,
		"leg_length": 1.35,
		"spider_leg_count": 8,
		"eye_count": 8,
	},
	"brute": {
		"name": "Kolossspindel",
		"scale": 1.25,
		"speed": 1.6,
		"body_scale": 1.35,
		"leg_length": 1.1,
		"spider_leg_count": 10,
		"eye_count": 6,
	},
	"swarm": {
		"name": "Svärmunge",
		"scale": 0.55,
		"speed": 4.0,
		"body_scale": 0.65,
		"leg_length": 1.2,
		"spider_leg_count": 6,
		"eye_count": 10,
	},
}


static func get_spawn_plan(spawn_id: String) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	match id:
		"satellite_left":
			return _entries([
				["scifi", "trilobite", 2],
				["scifi", "eye_drone", 2],
				["spider", "stalker", 2],
				["spider", "swarm", 3],
			])
		"satellite_top_a":
			return _entries([
				["scifi", "quad_shell", 2],
				["scifi", "eye_drone", 1],
				["spider", "brute", 2],
				["spider", "stalker", 2],
			])
		"satellite_top_b":
			return _entries([
				["scifi", "trilobite", 1],
				["scifi", "quad_shell", 2],
				["spider", "swarm", 4],
				["spider", "brute", 1],
			])
		"satellite_right":
			return _entries([
				["hybrid", "crawler", 3],
				["hybrid", "stalker", 2],
				["hybrid", "drone_host", 2],
			])
		_:
			return _entries([
				["scifi", "trilobite", 1],
				["scifi", "eye_drone", 1],
				["spider", "stalker", 1],
			])


static func resolve_entry(kind: String, key: String) -> Dictionary:
	if kind == "scifi":
		var data: Dictionary = SCI_FI_MODELS.get(key, {})
		if data.is_empty():
			return {}
		return {
			"kind": "scifi",
			"key": key,
			"name": str(data.get("name", key)),
			"model": str(data.get("model", "")),
			"scale": float(data.get("scale", 1.0)),
			"speed": float(data.get("speed", 2.0)),
			"y_offset": float(data.get("y_offset", 0.0)),
		}
	if kind == "spider":
		var spider: Dictionary = SPIDER_ARCHETYPES.get(key, {})
		if spider.is_empty():
			return {}
		return {
			"kind": "spider",
			"key": key,
			"name": str(spider.get("name", key)),
			"scale": float(spider.get("scale", 1.0)),
			"speed": float(spider.get("speed", 2.0)),
			"body_scale": float(spider.get("body_scale", 1.0)),
			"leg_length": float(spider.get("leg_length", 1.0)),
			"spider_leg_count": int(spider.get("spider_leg_count", 8)),
			"eye_count": int(spider.get("eye_count", 6)),
		}
	if kind == "hybrid":
		var hybrid: Dictionary = HYBRID_ARCHETYPES.get(key, {})
		if hybrid.is_empty():
			return {}
		return {
			"kind": "hybrid",
			"key": key,
			"name": str(hybrid.get("name", key)),
			"scale": float(hybrid.get("scale", 1.0)),
			"speed": float(hybrid.get("speed", 1.8)),
			"body_scale": float(hybrid.get("body_scale", 1.0)),
			"leg_length": float(hybrid.get("leg_length", 1.0)),
			"spider_leg_count": int(hybrid.get("spider_leg_count", 8)),
			"eye_count": int(hybrid.get("eye_count", 6)),
			"drone": str(hybrid.get("drone", "Enemy_EyeDrone")),
		}
	return {}


static func build_spider_avatar(entry: Dictionary, seed: int) -> AvatarData:
	var data := AvatarData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	data.body_scale = float(entry.get("body_scale", 1.0)) * rng.randf_range(0.92, 1.08)
	data.abdomen_scale = rng.randf_range(0.9, 1.35)
	data.head_scale = rng.randf_range(0.9, 1.2)
	data.leg_length = float(entry.get("leg_length", 1.0))
	data.arm_length = rng.randf_range(0.95, 1.25)
	data.spider_leg_count = int(entry.get("spider_leg_count", 8))
	data.eye_count = int(entry.get("eye_count", 6))
	data.eye_size = rng.randf_range(1.0, 1.8)
	data.mandible_length = rng.randf_range(0.8, 1.5)
	data.glow_strength = rng.randf_range(0.4, 1.2)
	var hue := rng.randf_range(0.0, 1.0)
	data.body_color = Color.from_hsv(hue, rng.randf_range(0.2, 0.5), rng.randf_range(0.05, 0.18))
	data.accent_color = Color.from_hsv(fmod(hue + 0.08, 1.0), rng.randf_range(0.5, 0.95), rng.randf_range(0.15, 0.38))
	data.eye_color = Color.from_hsv(rng.randf_range(0.0, 0.12), 0.9, 1.0)
	data.glow_color = data.eye_color.lightened(0.2)
	return data


static func build_hybrid_avatar(entry: Dictionary, seed: int) -> AvatarData:
	var data := build_spider_avatar(entry, seed)
	data.body_color = Color(0.18, 0.32, 0.14)
	data.accent_color = Color(0.35, 0.42, 0.38)
	data.eye_color = Color(0.85, 0.15, 0.12)
	data.glow_color = Color(0.45, 0.95, 0.22)
	data.glow_strength = 0.25
	data.mandible_length *= 1.2
	return data


static func get_spawn_batches(spawn_id: String, spawn_center: Vector3) -> Array:
	var id := SpawnPoints.normalize_id(spawn_id)
	var plan := get_spawn_plan(id)
	if plan.is_empty():
		return []

	if id != "satellite_right":
		return [{
			"center": spawn_center + Vector3(
				SpawnPoints.get_extent_m() * 0.14,
				0.0,
				SpawnPoints.get_extent_m() * 0.1
			),
			"radius": SpawnPoints.get_extent_m() * 0.16,
			"entries": plan,
		}]

	var block := float(DcZoneCatalog.BLOCK_M)
	return [
		{
			"center": spawn_center + Vector3(72.0, 0.0, 58.0),
			"radius": 52.0,
			"entries": _entries([
				["hybrid", "crawler", 1],
				["hybrid", "stalker", 1],
			]),
		},
		{
			"center": spawn_center + Vector3(-block * 1.0, 0.0, block * 2.0),
			"radius": 72.0,
			"entries": _entries([
				["hybrid", "crawler", 1],
				["hybrid", "stalker", 1],
			]),
		},
		{
			"center": spawn_center + Vector3(-block * 4.5, 0.0, block * 1.5),
			"radius": 78.0,
			"entries": _entries([
				["hybrid", "crawler", 1],
				["hybrid", "drone_host", 1],
			]),
		},
		{
			"center": spawn_center + Vector3(-block * 3.0, 0.0, block * 0.25),
			"radius": 58.0,
			"entries": _entries([
				["hybrid", "crawler", 1],
			]),
		},
		{
			"center": spawn_center + Vector3(-block * 2.0, 0.0, -block * 1.25),
			"radius": 64.0,
			"entries": _entries([
				["hybrid", "stalker", 1],
			]),
		},
		{
			"center": spawn_center + Vector3(-block * 6.0, 0.0, block * 3.5),
			"radius": SpawnPoints.get_extent_m() * 0.14,
			"entries": plan,
		},
	]


static func _entries(rows: Array) -> Array:
	var out: Array = []
	for row in rows:
		if typeof(row) != TYPE_ARRAY or row.size() < 3:
			continue
		var resolved := resolve_entry(str(row[0]), str(row[1]))
		if resolved.is_empty():
			continue
		resolved["count"] = int(row[2])
		out.append(resolved)
	return out