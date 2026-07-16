class_name AvatarData
extends Resource

@export var mesh_id := "reference_human"
@export var body_color := Color(0.82, 0.66, 0.52)
@export var accent_color := Color(0.18, 0.22, 0.34)
@export var eye_color := Color(0.22, 0.16, 0.12)
@export var glow_color := Color(0.45, 0.62, 0.95)

@export_range(0.75, 1.5, 0.01) var body_scale := 1.0
@export_range(0.6, 1.6, 0.01) var abdomen_scale := 1.18
@export_range(0.8, 1.4, 0.01) var head_scale := 1.1
@export_range(0.7, 1.5, 0.01) var leg_length := 1.12
@export_range(0.6, 1.4, 0.01) var arm_length := 1.14

@export_range(4, 12, 1) var spider_leg_count := 8
@export_range(2, 12, 1) var eye_count := 8
@export_range(0.4, 3.0, 0.01) var eye_size := 1.45
@export_range(0.4, 2.0, 0.01) var eye_spread := 1.28
@export_range(0.0, 1.5, 0.01) var eye_stalk_length := 0.72
@export_range(0.0, 2.0, 0.01) var mandible_length := 1.38
@export_range(0.0, 2.5, 0.01) var fang_length := 1.25
@export_range(0.0, 2.0, 0.01) var claw_size := 1.05
@export_range(0.0, 1.0, 0.01) var abdomen_segments := 0.72
@export_range(0.0, 1.0, 0.01) var crest_size := 0.55
@export_range(0.0, 1.0, 0.01) var chitin_roughness := 0.38
@export_range(0.0, 1.0, 0.01) var chitin_metallic := 0.32
@export_range(0.0, 2.0, 0.01) var glow_strength := 1.15
@export_range(0.0, 1.0, 0.01) var spike_amount := 0.68
@export_range(0.5, 1.5, 0.01) var stance_width := 1.16


func duplicate_data() -> AvatarData:
	var copy := AvatarData.new()
	copy.mesh_id = mesh_id
	copy.body_color = body_color
	copy.accent_color = accent_color
	copy.eye_color = eye_color
	copy.glow_color = glow_color
	copy.body_scale = body_scale
	copy.abdomen_scale = abdomen_scale
	copy.head_scale = head_scale
	copy.leg_length = leg_length
	copy.arm_length = arm_length
	copy.spider_leg_count = spider_leg_count
	copy.eye_count = eye_count
	copy.eye_size = eye_size
	copy.eye_spread = eye_spread
	copy.eye_stalk_length = eye_stalk_length
	copy.mandible_length = mandible_length
	copy.fang_length = fang_length
	copy.claw_size = claw_size
	copy.abdomen_segments = abdomen_segments
	copy.crest_size = crest_size
	copy.chitin_roughness = chitin_roughness
	copy.chitin_metallic = chitin_metallic
	copy.glow_strength = glow_strength
	copy.spike_amount = spike_amount
	copy.stance_width = stance_width
	return copy


func to_dict() -> Dictionary:
	return {
		"mesh_id": mesh_id,
		"body_color": body_color.to_html(false),
		"accent_color": accent_color.to_html(false),
		"eye_color": eye_color.to_html(false),
		"glow_color": glow_color.to_html(false),
		"body_scale": body_scale,
		"abdomen_scale": abdomen_scale,
		"head_scale": head_scale,
		"leg_length": leg_length,
		"arm_length": arm_length,
		"spider_leg_count": spider_leg_count,
		"eye_count": eye_count,
		"eye_size": eye_size,
		"eye_spread": eye_spread,
		"eye_stalk_length": eye_stalk_length,
		"mandible_length": mandible_length,
		"fang_length": fang_length,
		"claw_size": claw_size,
		"abdomen_segments": abdomen_segments,
		"crest_size": crest_size,
		"chitin_roughness": chitin_roughness,
		"chitin_metallic": chitin_metallic,
		"glow_strength": glow_strength,
		"spike_amount": spike_amount,
		"stance_width": stance_width,
	}


static func from_dict(data: Dictionary) -> AvatarData:
	var avatar := AvatarData.new()
	if data.is_empty():
		return avatar
	avatar.mesh_id = str(data.get("mesh_id", "reference_human"))
	avatar.body_color = Color.html(data.get("body_color", "#d1a885"))
	avatar.accent_color = Color.html(data.get("accent_color", "#2e3857"))
	avatar.eye_color = Color.html(data.get("eye_color", "#38281f"))
	avatar.glow_color = Color.html(data.get("glow_color", "#739ef2"))
	avatar.body_scale = float(data.get("body_scale", 1.0))
	avatar.abdomen_scale = float(data.get("abdomen_scale", 1.12))
	avatar.head_scale = float(data.get("head_scale", 1.05))
	avatar.leg_length = float(data.get("leg_length", 1.05))
	avatar.arm_length = float(data.get("arm_length", 1.08))
	avatar.spider_leg_count = int(data.get("spider_leg_count", 8))
	avatar.eye_count = int(data.get("eye_count", 8))
	avatar.eye_size = float(data.get("eye_size", 1.2))
	avatar.eye_spread = float(data.get("eye_spread", 1.15))
	avatar.eye_stalk_length = float(data.get("eye_stalk_length", 0.55))
	avatar.mandible_length = float(data.get("mandible_length", 1.25))
	avatar.fang_length = float(data.get("fang_length", 1.1))
	avatar.claw_size = float(data.get("claw_size", 0.85))
	avatar.abdomen_segments = float(data.get("abdomen_segments", 0.62))
	avatar.crest_size = float(data.get("crest_size", 0.42))
	avatar.chitin_roughness = float(data.get("chitin_roughness", 0.48))
	avatar.chitin_metallic = float(data.get("chitin_metallic", 0.22))
	avatar.glow_strength = float(data.get("glow_strength", 0.85))
	avatar.spike_amount = float(data.get("spike_amount", 0.58))
	avatar.stance_width = float(data.get("stance_width", 1.08))
	return avatar