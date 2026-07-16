class_name PedestrianStyle
extends RefCounted

const LOOKS: Array[Dictionary] = [
	{"body": Color(0.18, 0.2, 0.24), "accent": Color(0.95, 0.22, 0.55), "glow": Color(0.9, 0.35, 0.6), "scale": 1.04},
	{"body": Color(0.92, 0.86, 0.78), "accent": Color(0.12, 0.72, 0.88), "glow": Color(0.2, 0.8, 1.0), "scale": 1.0},
	{"body": Color(0.14, 0.16, 0.2), "accent": Color(0.98, 0.78, 0.18), "glow": Color(1.0, 0.85, 0.3), "scale": 1.06},
	{"body": Color(0.78, 0.72, 0.68), "accent": Color(0.42, 0.18, 0.62), "glow": Color(0.55, 0.3, 0.85), "scale": 0.98},
	{"body": Color(0.22, 0.24, 0.28), "accent": Color(0.28, 0.95, 0.42), "glow": Color(0.35, 1.0, 0.5), "scale": 1.02},
	{"body": Color(0.88, 0.9, 0.92), "accent": Color(0.95, 0.35, 0.12), "glow": Color(1.0, 0.45, 0.2), "scale": 1.05},
	{"body": Color(0.16, 0.18, 0.22), "accent": Color(0.55, 0.82, 0.95), "glow": Color(0.6, 0.9, 1.0), "scale": 1.03},
	{"body": Color(0.72, 0.55, 0.42), "accent": Color(0.12, 0.12, 0.14), "glow": Color(0.25, 0.25, 0.3), "scale": 1.01},
]


static func build_avatar(seed: int) -> AvatarData:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var look: Dictionary = LOOKS[rng.randi() % LOOKS.size()]
	var data := AvatarData.new()
	data.body_scale = float(look.get("scale", 1.0)) * rng.randf_range(0.97, 1.03)
	data.body_color = look.get("body", Color.WHITE)
	data.accent_color = look.get("accent", Color.GRAY)
	data.glow_color = look.get("glow", data.accent_color)
	data.glow_strength = rng.randf_range(0.18, 0.42)
	return data


static func pick_display_name(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var first: Array[String] = ["Nova", "Kai", "Mira", "Zed", "Lux", "Rin", "Sol", "Vex", "Iris", "Juno"]
	var last: Array[String] = ["Stride", "Volt", "Mall", "Flux", "Chrome", "Drift", "Pulse", "Axis"]
	return "%s %s" % [first[rng.randi() % first.size()], last[rng.randi() % last.size()]]