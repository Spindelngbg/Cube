class_name AvatarData
extends Resource

@export var body_color := Color(0.12, 0.14, 0.1)
@export var accent_color := Color(0.45, 0.08, 0.12)
@export var eye_color := Color(0.95, 0.2, 0.15)
@export var glow_color := Color(0.8, 0.15, 0.25)

@export_range(0.75, 1.5, 0.01) var body_scale := 1.0
@export_range(0.6, 1.6, 0.01) var abdomen_scale := 1.0
@export_range(0.8, 1.4, 0.01) var head_scale := 1.0
@export_range(0.7, 1.5, 0.01) var leg_length := 1.0
@export_range(0.6, 1.4, 0.01) var arm_length := 1.0

@export_range(4, 8, 1) var spider_leg_count := 6
@export_range(2, 8, 1) var eye_count := 6
@export_range(0.4, 2.0, 0.01) var eye_size := 1.0
@export_range(0.0, 2.0, 0.01) var mandible_length := 1.0
@export_range(0.0, 1.0, 0.01) var chitin_roughness := 0.55
@export_range(0.0, 1.0, 0.01) var chitin_metallic := 0.15
@export_range(0.0, 2.0, 0.01) var glow_strength := 0.6
@export_range(0.0, 1.0, 0.01) var spike_amount := 0.35
@export_range(0.5, 1.5, 0.01) var stance_width := 1.0


func duplicate_data() -> AvatarData:
	var copy := AvatarData.new()
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
	copy.mandible_length = mandible_length
	copy.chitin_roughness = chitin_roughness
	copy.chitin_metallic = chitin_metallic
	copy.glow_strength = glow_strength
	copy.spike_amount = spike_amount
	copy.stance_width = stance_width
	return copy


func to_dict() -> Dictionary:
	return {
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
		"mandible_length": mandible_length,
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
	avatar.body_color = Color.html(data.get("body_color", "#1f2420"))
	avatar.accent_color = Color.html(data.get("accent_color", "#730c1e"))
	avatar.eye_color = Color.html(data.get("eye_color", "#f23326"))
	avatar.glow_color = Color.html(data.get("glow_color", "#cc2640"))
	avatar.body_scale = float(data.get("body_scale", 1.0))
	avatar.abdomen_scale = float(data.get("abdomen_scale", 1.0))
	avatar.head_scale = float(data.get("head_scale", 1.0))
	avatar.leg_length = float(data.get("leg_length", 1.0))
	avatar.arm_length = float(data.get("arm_length", 1.0))
	avatar.spider_leg_count = int(data.get("spider_leg_count", 6))
	avatar.eye_count = int(data.get("eye_count", 6))
	avatar.eye_size = float(data.get("eye_size", 1.0))
	avatar.mandible_length = float(data.get("mandible_length", 1.0))
	avatar.chitin_roughness = float(data.get("chitin_roughness", 0.55))
	avatar.chitin_metallic = float(data.get("chitin_metallic", 0.15))
	avatar.glow_strength = float(data.get("glow_strength", 0.6))
	avatar.spike_amount = float(data.get("spike_amount", 0.35))
	avatar.stance_width = float(data.get("stance_width", 1.0))
	return avatar